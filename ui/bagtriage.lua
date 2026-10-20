--------------------------------------------------
-- WeintCodex :: Ausmisten - was in den Taschen am wenigsten wert ist
--------------------------------------------------
-- Wunsch des Spielers: "Trash visualisieren und sehen, was vielleicht mehr
-- wert ist als das, was ich gerade loote". Verhalten nach dem Addon
-- LootTriage, eigener Code und ohne seine Daten (es hat keine Lizenz).
--
-- Wie ui/inventory.lua: Teil des Codex, laeuft ohne Oberflaeche und ohne
-- das Komfortmodul; der Schalter liegt im Speicher des Komforts
-- ("triageOn", ab Werk an), bedient auf der Codex-Seite "Taschen", Reiter
-- Fenster "Löschen & looten" bei vollen Taschen.
--
--   Bewertung   je Taschenplatz Haendlerpreis x Anzahl (GetItemInfo). Steht
--               im eigenen Auktionspreis-Bestand (ui/auctionprices.lua) ein
--               hoeherer Preis und ist der Gegenstand nicht gebunden, zaehlt
--               der - mit Herkunft "Auktion". Kein Preis vom Client: "Wert
--               unbekannt", NIE 0 und nie ein Vorschlag.
--   Vorschlag   Grau immer (auch mit Haendlerpreis 0 - das ist gemessen),
--               dazu Weiss (auf Wunsch Gruen) mit Haendlerpreis. Geschuetzt:
--               Questgegenstaende (was der Client sagt, Klasse Quest, und
--               was ein Ziel im Questlog verlangt), Verbrauchbares,
--               Behaelter, Reagenzien, Munition, Handwerkswaren, Rezepte,
--               Koecher, Schluessel, alles ohne Haendlerpreis (Ruhestein,
--               Seelengebundenes ohne Wert), Ausruestungssets, die
--               "Behalten"-Liste des Charakters.
--   Beute       Beutefenster offen und die Taschen zu voll fuer alles: die
--               wertvollste Beute bekommt die freien Plaetze, jede weitere
--               wird dem billigsten noch nicht vergebenen Platz
--               gegenuebergestellt. Ist sie mehr wert, bekommt sie eine
--               Muenze im Beutefenster, und der Platz leuchtet in den
--               Taschen. GELOESCHT WIRD NIE - das bleibt die Hand des
--               Spielers.
--
-- Keine Allokation je Bild: gerechnet wird bei Ereignissen (Beute, Taschen
-- geaendert) und beim Zeigen, die Eintraege kommen aus einem Vorrat.
--------------------------------------------------

local K = WeintCodex.UIKit
local C = WeintCodex.Colors
local KEY = "comfort"

WeintCodex.UIBagTriage = {}
local BT = WeintCodex.UIBagTriage

BT.DEFAULTS = {
    triageOn = true,        -- Ausmisten: Bewertung, Beute-Muenze, Leuchten
    triageGreens = false,   -- auch Gruenes vorschlagen
    triageAuction = true,   -- Auktionspreis zaehlen, wenn hoeher
    triagePopup = true,     -- Fenster "Löschen & looten" bei vollen Taschen
}
BT.NEAR_FULL = 2            -- "fast voll": so wenige freie Plaetze

-- Klassen des Clients (Enum.ItemClass), die nie vorgeschlagen werden.
BT.CLASS_WEAPON, BT.CLASS_ARMOR, BT.CLASS_QUEST = 2, 4, 12
BT.PROTECTED_CLASS = {
    [0] = "Verbrauchbar", [1] = "Behälter", [5] = "Reagenz", [6] = "Munition",
    [7] = "Handwerkswaren", [9] = "Rezept", [11] = "Köcher", [12] = "Questgegenstand",
    [13] = "Schlüssel",
}
BT.QUALITY = { [0] = "Grau", [1] = "Weiß", [2] = "Grün" }

-- Werkzeuge der Berufe (6.94.0.0, Wunsch: "Kuerschnermesser, Spitzhacke,
-- Angel ... duerfen NIE betroffen sein"). Nummern aus Classic; Angeln
-- zusaetzlich ueber ihre Unterklasse (Waffe, Angelrute = 20).
BT.TOOLS = {
    [7005] = true,  -- Kuerschnermesser
    [2901] = true,  -- Spitzhacke
    [5956] = true,  -- Schmiedehammer
    [6219] = true,  -- Bogenlichtschraubenschluessel
    [10498] = true, -- Gyromatischer Mikroregulator
    [6218] = true, [6339] = true, [11130] = true, [11145] = true, [16207] = true, -- Runenverzierte Ruten
    [4471] = true,  -- Zunderkasten
    [9149] = true,  -- Stein der Philosophen
    [20815] = true, -- Juwelierwerkzeug
    [6256] = true, [6365] = true, [6366] = true, [6367] = true, [12225] = true,
    [19022] = true, [19970] = true, -- Angelruten
    [12709] = true, [19901] = true, [20723] = true, -- Hammer/Messer mit Werkzeugwirkung
}
BT.SUB_FISHING_POLE = 20

local function Plain(v) return K.Plain(v) end
local function Num(v) v = Plain(v) return type(v) == "number" and v or nil end
local function Str(v) v = Plain(v) return type(v) == "string" and v or nil end

function BT.Active() return K.Get(KEY, "triageOn") and true or false end
local function Opt(k) return K.Get(KEY, k) end

--------------------------------------------------
-- Behalten-Liste (je Charakter, WeintCodex_SavedData)
--------------------------------------------------

function BT.KeepStore(create)
    local sd = WeintCodex.SavedData
    if type(sd) ~= "table" then return nil end
    local IV = WeintCodex.UIInventory
    local me = IV and IV.Me and IV.Me()
    if not me then return nil end
    if not sd.triage then
        if not create then return nil end
        sd.triage = { keep = {} }
    end
    sd.triage.keep = sd.triage.keep or {}
    local k = sd.triage.keep[me]
    if not k and create then k = {} sd.triage.keep[me] = k end
    return k
end

function BT.IsKept(id)
    local k = BT.KeepStore(false)
    return k and k[id] and true or false
end

function BT.SetKept(id, on)
    if type(id) ~= "number" then return end
    local k = BT.KeepStore(true)
    if not k then return end
    k[id] = on and true or nil
    BT.dirty = true
    BT.Refresh()
end

--------------------------------------------------
-- Was der Client ueber einen Gegenstand sagt
--------------------------------------------------

-- name, quality, maxStack, sellPrice, classID, subclassID, isCraftingReagent
-- - oder nil, solange der Client ihn noch nicht kennt.
function BT.ItemInfo(item)
    local gi = _G.GetItemInfo or (_G.C_Item and _G.C_Item.GetItemInfo)
    if not gi or item == nil then return nil end
    local ok, name, _, quality, _, _, _, _, maxStack, _, _, sell, classID, subID, _, _, _, craft = pcall(gi, item)
    if not ok or not Str(name) then return nil end
    return Str(name), Num(quality), Num(maxStack), Num(sell), Num(classID), Num(subID), Plain(craft) == true
end

-- Wert eines Stapels: total, Herkunft ("Händler"/"Auktion") - oder nil,
-- wenn der Client keinen Haendlerpreis nennt (unbekannt, nicht 0).
function BT.Worth(id, count, sell, quality, bound)
    if type(sell) ~= "number" then return nil end
    count = count or 1
    local unit, src = sell, "Händler"
    if Opt("triageAuction") and not bound and (quality or 0) >= 1 then
        local AP = WeintCodex.UIAuctionPrices
        local e = AP and AP.Lookup and AP.Lookup(id)
        local p = e and Num(e.price)
        if p and p > unit then unit, src = p, "Auktion" end
    end
    return unit * count, src
end

-- Namen, die ein Ziel im Questlog verlangt ("Wolfsfleisch: 2/8").
BT.questNeeds = {}
function BT.ScanQuestLog()
    local need = BT.questNeeds
    for k in _G.next, need do need[k] = nil end
    local num = _G.GetNumQuestLogEntries
    local lb, nlb = _G.GetQuestLogLeaderBoard, _G.GetNumQuestLeaderBoards
    if not (num and lb and nlb) then return need end
    local ok, n = pcall(num)
    n = ok and Num(n) or 0
    for i = 1, n do
        local ok2, m = pcall(nlb, i)
        for j = 1, (ok2 and Num(m) or 0) do
            local ok3, text, kind, done = pcall(lb, j, i)
            text = ok3 and Str(text)
            if text and Str(kind) == "item" and not Plain(done) then
                local nm = text:match("^(.-):%s*%d+%s*/%s*%d+") or text
                need[nm] = true
            end
        end
    end
    return need
end

--------------------------------------------------
-- Taschen lesen und bewerten
--------------------------------------------------

local function CC()
    local cc = _G.C_Container
    if type(cc) == "table" and cc.GetContainerNumSlots and cc.GetContainerItemInfo then return cc end
end

-- Normale Taschen (keine Spezialtaschen: Koecher, Kraeuter ...).
function BT.Bags(out)
    out = out or {}
    for i = #out, 1, -1 do out[i] = nil end
    local cc = CC()
    local n = tonumber(_G.NUM_BAG_SLOTS) or 4
    for b = 0, n do
        local fam = 0
        if b > 0 and cc and cc.GetContainerNumFreeSlots then
            local ok, _, f = pcall(cc.GetContainerNumFreeSlots, b)
            fam = ok and Num(f) or 0
        end
        if fam == 0 then out[#out + 1] = b end
    end
    return out
end

BT.candidates = {}      -- sortiert, billigster zuerst
BT.stats = { used = 0, total = 0, free = 0, unknown = 0, known = false }
BT.dirty = true
local pool = {}
local bagList = {}

local function Release()
    local cand = BT.candidates
    for i = #cand, 1, -1 do pool[#pool + 1] = cand[i] cand[i] = nil end
end

-- Ein Platz: Eintrag, wenn er vorgeschlagen werden darf; sonst nil und
-- ein Wort, warum nicht ("unknown" zaehlt fuer den Hinweis).
function BT.Evaluate(info, bag, slot, quest)
    local id = Num(info.itemID)
    if not id then return nil end
    if BT.IsKept(id) then return nil, "kept" end
    if quest and (Plain(quest.isQuestItem) or Num(quest.questID)) then return nil, "quest" end
    local name, quality, _, sell, classID, subID, craft = BT.ItemInfo(Str(info.hyperlink) or id)
    quality = Num(info.quality) or quality
    if not name or type(sell) ~= "number" or type(quality) ~= "number" then return nil, "unknown" end
    if classID == BT.CLASS_QUEST or BT.questNeeds[name] then return nil, "quest" end
    if BT.TOOLS[id] then return nil, "tool" end
    if classID == BT.CLASS_WEAPON and subID == BT.SUB_FISHING_POLE then return nil, "tool" end
    if craft or BT.PROTECTED_CLASS[classID] then return nil, "class" end
    local maxQ = Opt("triageGreens") and 2 or 1
    if quality > maxQ then return nil, "quality" end
    if quality > 0 then
        if Plain(info.hasNoValue) or sell == 0 then return nil, "novalue" end
        if craft or BT.PROTECTED_CLASS[classID] then return nil, "class" end
        -- Spell-Reagenz (Verschiedenes, Unterklasse 1)
        if classID == 15 and subID == 1 then return nil, "class" end
    end
    if classID == BT.CLASS_WEAPON or classID == BT.CLASS_ARMOR then
        local cc = CC()
        local inSet = cc and cc.GetContainerItemEquipmentSetInfo
        if inSet then
            local ok, r = pcall(inSet, bag, slot)
            if ok and Plain(r) then return nil, "set" end
        end
    end
    local count = Num(info.stackCount) or 1
    local value, src = BT.Worth(id, count, sell, quality, Plain(info.isBound) and true or false)
    if not value then return nil, "unknown" end
    local e = pool[#pool]
    if e then pool[#pool] = nil else e = {} end
    e.bag, e.slot, e.id, e.name, e.quality = bag, slot, id, name, quality
    e.count, e.value, e.src, e.icon = count, value, src, Num(info.iconFileID) or Str(info.iconFileID)
    e.link = Str(info.hyperlink)
    e.reason = BT.QUALITY[quality] .. (src == "Auktion" and ", Auktionspreis" or (sell == 0 and ", ohne Händlerpreis" or ", Händlerpreis"))
    return e
end

local function Cheaper(a, b)
    if a.value ~= b.value then return a.value < b.value end
    if a.quality ~= b.quality then return a.quality < b.quality end
    if a.id ~= b.id then return a.id < b.id end
    if a.count ~= b.count then return a.count < b.count end
    if a.bag ~= b.bag then return a.bag < b.bag end
    return a.slot < b.slot
end

function BT.Scan()
    Release()
    local st = BT.stats
    st.used, st.total, st.free, st.unknown, st.known = 0, 0, 0, 0, false
    BT.dirty = false
    local cc = CC()
    if not cc then return BT.candidates end
    BT.ScanQuestLog()
    local cand = BT.candidates
    for _, bag in ipairs(BT.Bags(bagList)) do
        local ok, n = pcall(cc.GetContainerNumSlots, bag)
        n = ok and Num(n) or 0
        for slot = 1, n do
            st.total = st.total + 1
            local ok2, info = pcall(cc.GetContainerItemInfo, bag, slot)
            if ok2 and type(info) == "table" and Num(info.itemID) then
                st.used = st.used + 1
                local q
                if cc.GetContainerItemQuestInfo then
                    local ok3, qi = pcall(cc.GetContainerItemQuestInfo, bag, slot)
                    q = ok3 and type(qi) == "table" and qi or nil
                end
                local e, why = BT.Evaluate(info, bag, slot, q)
                if e then cand[#cand + 1] = e
                elseif why == "unknown" then st.unknown = st.unknown + 1 end
            end
        end
    end
    st.free = st.total - st.used
    st.known = st.total > 0
    table.sort(cand, Cheaper)
    return cand
end

function BT.Candidates()
    if BT.dirty then BT.Scan() end
    return BT.candidates
end

function BT.TotalValue()
    local s = 0
    for _, e in ipairs(BT.Candidates()) do s = s + e.value end
    return s
end

function BT.Money(copper)
    local AP = WeintCodex.UIAuctionPrices
    if AP and AP.Money then return AP.Money(copper) end
    return tostring(copper)
end

--------------------------------------------------
-- Beute gegen Taschen
--------------------------------------------------
-- BT.pairs[lootSlot] = Eintrag des Taschenplatzes, der weichen koennte.
BT.pairs = {}
BT.lootInfo = {}        -- [lootSlot] = { id, value } (wiederverwendet)
BT.glow = {}            -- [bag * 1000 + slot] = Rang
BT.offer = {}           -- [lootSlot] = billigster Platz oder false (keiner)
BT.lootOpen = false
local order = {}

local function Wipe(t) for k in _G.next, t do t[k] = nil end end

-- Passt die Beute auf einen angefangenen Stapel?
local function Stacks(id, qty, maxStack)
    if not (maxStack and maxStack > 1) then return false end
    local cc = CC()
    for _, bag in ipairs(bagList) do
        local ok, n = pcall(cc.GetContainerNumSlots, bag)
        for slot = 1, ok and Num(n) or 0 do
            local ok2, info = pcall(cc.GetContainerItemInfo, bag, slot)
            if ok2 and type(info) == "table" and Num(info.itemID) == id
               and (Num(info.stackCount) or 1) + (qty or 1) <= maxStack then
                return true
            end
        end
    end
    return false
end

function BT.PairLoot()
    Wipe(BT.pairs)
    Wipe(BT.glow)
    for i = #order, 1, -1 do order[i] = nil end
    if not (BT.Active() and BT.lootOpen) then return BT.pairs end
    local num = _G.GetNumLootItems
    if not num then return BT.pairs end
    local cand = BT.Scan()
    local st = BT.stats
    if not st.known or st.free > BT.NEAR_FULL then return BT.pairs end
    local ok, n = pcall(num)
    n = ok and Num(n) or 0
    local items = 1
    if _G.Enum and _G.Enum.LootSlotType then items = Num(_G.Enum.LootSlotType.Item) or 1 end
    for i = 1, n do
        local li = BT.lootInfo[i] or {}
        BT.lootInfo[i] = li
        li.id, li.value, li.quest, li.fits = nil, nil, false, false
        local kind = _G.GetLootSlotType and Num(_G.GetLootSlotType(i))
        local link = _G.GetLootSlotLink and Str(_G.GetLootSlotLink(i))
        if kind == items and link then
            local _, _, qty, _, quality, _, isQuest
            if _G.GetLootSlotInfo then _, _, qty, _, quality, _, isQuest = _G.GetLootSlotInfo(i) end
            local id = tonumber(link:match("item:(%d+)"))
            local _, q2, maxStack, sell = BT.ItemInfo(link)
            li.id = id
            li.quest = Plain(isQuest) and true or false
            li.fits = id and Stacks(id, Num(qty), maxStack) or false
            li.value = id and BT.Worth(id, Num(qty) or 1, sell, Num(quality) or q2, false) or nil
            if not li.fits then order[#order + 1] = i end
        end
    end
    -- Wertvollstes zuerst; Questbeute immer vorn, Unbekanntes hinten.
    table.sort(order, function(a, b)
        local la, lb = BT.lootInfo[a], BT.lootInfo[b]
        if la.quest ~= lb.quest then return la.quest end
        local va, vb = la.value or -1, lb.value or -1
        if va ~= vb then return va > vb end
        return a < b
    end)
    -- BT.offer: jede Beute ohne Platz bekommt ihren Vergleich, auch wenn
    -- der Tausch nicht lohnt (6.97.1.0, Beta-Test: "Inventar voll und keine
    -- Information kommt") - das Fenster sagt dann ehrlich "lohnt nicht".
    Wipe(BT.offer)
    local c = 1
    for k, slot in ipairs(order) do
        if k > st.free then
            local li, e = BT.lootInfo[slot], cand[c]
            BT.offer[slot] = e or false
            if e and (li.quest or (li.value and li.value > e.value)) then
                BT.pairs[slot] = e
                BT.glow[e.bag * 1000 + e.slot] = c
                c = c + 1
            end
        end
    end
    return BT.pairs
end

-- Zu welchem Platz im Beutefenster gehoert ein Rahmen?
function BT.LootSlotOf(frame)
    if type(frame) ~= "table" then return nil end
    if frame.GetSlotIndex then
        local ok, s = pcall(frame.GetSlotIndex, frame)
        if ok and Num(s) then return Num(s) end
    end
    return Num(frame.slot)
end

--------------------------------------------------
-- Markierungen: Muenze im Beutefenster, Leuchten in den Taschen
--------------------------------------------------

local coins = setmetatable({}, { __mode = "k" })
local overlays = setmetatable({}, { __mode = "k" })
BT.coins, BT.overlays = coins, overlays

local function Coin(frame)
    local t = coins[frame]
    if t then return t end
    t = frame:CreateTexture(nil, "OVERLAY", nil, 7)
    t:SetSize(14, 14)
    t:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)
    t:SetTexture("Interface\\MoneyFrame\\UI-GoldIcon")
    t:Hide()
    coins[frame] = t
    return t
end

local function MarkFrame(frame)
    local slot = BT.LootSlotOf(frame)
    if not slot then return end
    local want = BT.pairs[slot] ~= nil
    local t = coins[frame]
    if want then Coin(frame):Show() elseif t then t:Hide() end
end

function BT.MarkLoot()
    local lf = _G.LootFrame
    if type(lf) ~= "table" then return end
    local sb = lf.ScrollBox
    if type(sb) == "table" and sb.ForEachFrame then
        pcall(sb.ForEachFrame, sb, MarkFrame)
    elseif type(sb) == "table" and sb.ScrollTarget and sb.ScrollTarget.GetChildren then
        for _, ch in ipairs({ sb.ScrollTarget:GetChildren() }) do MarkFrame(ch) end
    end
    for i = 1, (tonumber(_G.LOOTFRAME_NUMBUTTONS) or 4) do
        local b = _G["LootButton" .. i]
        if type(b) == "table" then MarkFrame(b) end
    end
end

local function Overlay(btn)
    local o = overlays[btn]
    if o then return o end
    local g = C.gold
    o = {}
    o.fill = btn:CreateTexture(nil, "OVERLAY", nil, 6)
    o.fill:SetAllPoints(btn)
    o.fill:SetColorTexture(g[1], g[2], g[3], 0.18)
    local edges = { { "TOPLEFT", "TOPRIGHT", true }, { "BOTTOMLEFT", "BOTTOMRIGHT", true },
                    { "TOPLEFT", "BOTTOMLEFT", false }, { "TOPRIGHT", "BOTTOMRIGHT", false } }
    for i, e in ipairs(edges) do
        local t = btn:CreateTexture(nil, "OVERLAY", nil, 7)
        t:SetColorTexture(g[1], g[2], g[3], 0.95)
        t:SetPoint(e[1], btn, e[1], 0, 0)
        t:SetPoint(e[2], btn, e[2], 0, 0)
        if e[3] then t:SetHeight(2) else t:SetWidth(2) end
        o[i] = t
    end
    o.on = true
    overlays[btn] = o
    return o
end

local function ShowOverlay(o, on)
    if o.on == on then return end
    o.on = on
    o.fill:SetShown(on)
    for i = 1, 4 do o[i]:SetShown(on) end
end

-- Tasche und Platz eines Taschenknopfs (Spiel oder eigene Taschen).
function BT.BagSlotOf(btn)
    local bag
    if btn.GetBagID then
        local ok, b = pcall(btn.GetBagID, btn)
        bag = ok and Num(b) or nil
    end
    if not bag then
        local p = btn.GetParent and btn:GetParent()
        bag = p and p.GetID and Num(p:GetID())
    end
    local slot = btn.GetID and Num(btn:GetID())
    return bag, slot
end

-- Vorschlaege im Taschenfenster zeigen (6.92.1.0, Beta-Test: "In der
-- Tasche steht nichts von Ausmisten"): Knopf "Ausmisten" schaltet die
-- billigsten Plaetze gold, auch ohne Beute.
BT.SUGGEST_MAX = 8
BT.showSuggest = false
BT.suggest = {}
function BT.SetShowSuggest(on)
    BT.showSuggest = on and true or false
    Wipe(BT.suggest)
    if BT.showSuggest then
        for i, e in ipairs(BT.Candidates()) do
            if i > BT.SUGGEST_MAX then break end
            BT.suggest[e.bag * 1000 + e.slot] = i
        end
    end
    BT.PaintBags()
end

function BT.SuggestText()
    if not BT.Active() then return nil end
    local list = BT.Candidates()
    if #list == 0 then return nil end
    local n, v = math.min(#list, BT.SUGGEST_MAX), 0
    for i = 1, n do v = v + list[i].value end
    return string.format("%d zum Ausmisten · %s", n, BT.Money(v))
end

local function PaintButton(btn)
    if type(btn) ~= "table" or not btn.CreateTexture then return end
    local bag, slot = BT.BagSlotOf(btn)
    local k = bag and slot and bag * 1000 + slot
    local on = k and (BT.glow[k] ~= nil or (BT.showSuggest and BT.suggest[k] ~= nil)) or false
    local o = overlays[btn]
    if on then ShowOverlay(Overlay(btn), true) elseif o then ShowOverlay(o, false) end
end

function BT.EachBagButton(fn)
    local UB = WeintCodex.UIBags
    if UB and UB.slotsForTest then
        for _, s in ipairs(UB.slotsForTest() or {}) do if s.button then fn(s.button) end end
    end
    for i = 1, (tonumber(_G.NUM_CONTAINER_FRAMES) or 13) do
        local f = _G["ContainerFrame" .. i]
        if type(f) == "table" then
            if type(f.Items) == "table" then for _, b in ipairs(f.Items) do fn(b) end end
            for j = 1, 36 do
                local b = _G["ContainerFrame" .. i .. "Item" .. j]
                if not b then break end
                fn(b)
            end
        end
    end
    local cb = _G.ContainerFrameCombinedBags
    if type(cb) == "table" and type(cb.Items) == "table" then
        for _, b in ipairs(cb.Items) do fn(b) end
    end
end

function BT.PaintBags() BT.EachBagButton(PaintButton) end

--------------------------------------------------
-- Fenster beim Looten mit vollen Taschen (6.94.0.0, Wunsch: "dann sollte
-- das aufploppen und die Moeglichkeit bestehen das wenig wert Item im
-- Inventar zu loeschen, damit man das andere looten kann")
--------------------------------------------------
-- Je lohnender Beute eine Zeile: Beute (Wert) gegen den billigsten
-- Taschenplatz (Wert), Knopf "Löschen und looten". Geloescht wird nur auf
-- diesen Klick (Hardware-Ereignis) - nie von selbst.
BT.POP_ROWS = 3
local pop

local function PopRow(i)
    local r = CreateFrame("Frame", nil, pop)
    r:SetSize(380, 44)
    r:SetPoint("TOPLEFT", pop, "TOPLEFT", 12, -34 - (i - 1) * 48)
    r.loot = r:CreateTexture(nil, "ARTWORK")
    r.loot:SetSize(28, 28)
    r.loot:SetPoint("LEFT", r, "LEFT", 0, 0)
    r.lootText = K.NewText(r, 11)
    r.lootText:SetPoint("TOPLEFT", r.loot, "TOPRIGHT", 6, 0)
    r.lootText:SetWidth(120)
    r.lootText:SetJustifyH("LEFT")
    r.bag = r:CreateTexture(nil, "ARTWORK")
    r.bag:SetSize(28, 28)
    r.bag:SetPoint("LEFT", r, "LEFT", 160, 0)
    r.bagText = K.NewText(r, 11)
    r.bagText:SetPoint("TOPLEFT", r.bag, "TOPRIGHT", 6, 0)
    r.bagText:SetWidth(90)
    r.bagText:SetJustifyH("LEFT")
    r.btn = WeintCodex.CreateButton(r, { text = "Löschen & looten", kind = "primary", height = 24, size = 11,
        onClick = function() BT.Swap(r.lootSlot, r.entry) end })
    r.btn:SetWidth(110)
    r.btn:SetPoint("RIGHT", r, "RIGHT", 0, 0)
    return r
end

local function BuildPop()
    if pop then return pop end
    pop = CreateFrame("Frame", "WeintCodexLootSwap", UIParent)
    pop:SetSize(404, 40 + BT.POP_ROWS * 48)
    pop:SetFrameStrata("DIALOG")
    pop:SetClampedToScreen(true)
    pop:SetMovable(true)
    pop:EnableMouse(true)
    pop:RegisterForDrag("LeftButton")
    pop:SetScript("OnDragStart", pop.StartMoving)
    pop:SetScript("OnDragStop", pop.StopMovingOrSizing)
    K.Kachel(pop, { shadow = 6, alpha = 1 })
    pop.title = K.NewText(pop, 13, "OVERLAY")
    pop.title:SetPoint("TOPLEFT", pop, "TOPLEFT", 12, -10)
    pop.title:SetText("Taschen voll – Beute gegen Taschenplatz")
    local close = WeintCodex.CreateButton(pop, { text = "×", kind = "ghost", height = 20, size = 14,
        onClick = function() pop:Hide() end })
    close:SetWidth(24)
    close:SetPoint("TOPRIGHT", pop, "TOPRIGHT", -6, -6)
    pop.rows = {}
    for i = 1, BT.POP_ROWS do pop.rows[i] = PopRow(i) end
    pop:Hide()
    return pop
end

local function Icon(link)
    local f = _G.C_Item and _G.C_Item.GetItemIconByID or _G.GetItemIcon
    local id = type(link) == "string" and tonumber(link:match("item:(%d+)")) or link
    if f and id then
        local ok, t = pcall(f, id)
        if ok and Plain(t) then return Plain(t) end
    end
    return 134400
end

function BT.ShowPopup()
    if not (BT.Active() and BT.lootOpen) then
        if pop then pop:Hide() end
        return
    end
    local n = 0
    for slot, e in pairs(BT.offer) do
        local li = BT.lootInfo[slot]
        if li and li.id and n < BT.POP_ROWS then
            BuildPop()
            n = n + 1
            local r = pop.rows[n]
            local worth = e and BT.pairs[slot] ~= nil
            r.lootSlot, r.entry = slot, e or nil
            local link = _G.GetLootSlotLink and Str(_G.GetLootSlotLink(slot))
            r.loot:SetTexture(Icon(link or li.id))
            r.lootText:SetText((link or "Beute") .. "\n" .. (li.quest and "Questgegenstand" or (li.value and BT.Money(li.value) or "Wert unbekannt")))
            if e then
                r.bag:SetTexture(e.icon or Icon(e.id))
                r.bagText:SetText((e.link or e.name or "?") .. "\n" .. BT.Money(e.value))
                r.bag:Show()
                r.btn:SetText(worth and "Löschen & looten" or "Trotzdem tauschen")
                r.btn:Show()
            else
                r.bag:Hide()
                r.bagText:SetText("Nichts zum Tauschen – alles\nin den Taschen ist geschützt")
                r.btn:Hide()
            end
            r:Show()
        end
    end
    if n == 0 then
        if pop then pop:Hide() end
        return
    end
    for i = n + 1, BT.POP_ROWS do pop.rows[i]:Hide() end
    pop:SetHeight(40 + n * 48)
    if not pop:IsShown() then
        pop:ClearAllPoints()
        local lf = _G.LootFrame
        if lf and lf.IsShown and lf:IsShown() then pop:SetPoint("TOPLEFT", lf, "TOPRIGHT", 8, 0)
        else pop:SetPoint("CENTER", UIParent, "CENTER", 0, 120) end
        pop:Show()
    end
end

-- Den Taschenplatz loeschen und die Beute nehmen - nur auf den Klick.
function BT.Swap(lootSlot, e)
    if not (e and lootSlot) then return end
    local cc = _G.C_Container
    local pick = cc and cc.PickupContainerItem or _G.PickupContainerItem
    if not (pick and _G.DeleteCursorItem) then return end
    -- Steht dort noch derselbe Gegenstand?
    local info = cc and cc.GetContainerItemInfo and select(2, pcall(cc.GetContainerItemInfo, e.bag, e.slot))
    if type(info) ~= "table" or Num(info.itemID) ~= e.id then BT.dirty = true BT.Refresh() return end
    if _G.ClearCursor then _G.ClearCursor() end
    pick(e.bag, e.slot)
    _G.DeleteCursorItem()
    BT.pendingLoot = lootSlot
    local function Take()
        if BT.lootOpen and BT.pendingLoot and _G.LootSlot then pcall(_G.LootSlot, BT.pendingLoot) end
        BT.pendingLoot = nil
    end
    if _G.C_Timer and _G.C_Timer.After then _G.C_Timer.After(0.2, Take) else Take() end
end

function BT.Refresh()
    if BT.lootOpen then BT.PairLoot() BT.MarkLoot() end
    BT.ShowPopup()
    BT.PaintBags()
end

--------------------------------------------------
-- Tooltip: "Wert im Vergleich"
--------------------------------------------------

-- Zeilen fuer einen Gegenstand (Beute oder Tasche) - oder nil.
function BT.TooltipLines(id)
    if not BT.Active() or type(id) ~= "number" then return nil end
    if BT.lootOpen then
        for slot, e in pairs(BT.pairs) do
            local li = BT.lootInfo[slot]
            if li and li.id == id then
                return { { "Lohnt sich: Platz von", e.name .. (e.count > 1 and (" ×" .. e.count) or "") },
                         { "  dessen Wert", BT.Money(e.value) } }
            end
        end
    end
    local cand = BT.Candidates()
    local cheapest = cand[1]
    if not cheapest then return nil end
    for i, e in ipairs(cand) do
        if e.id == id then
            return { { "Ausmisten: Platz " .. i .. " von " .. #cand, BT.Money(e.value) .. " (" .. e.src .. ")" } }
        end
    end
    local _, quality, _, sell = BT.ItemInfo(id)
    local v = BT.Worth(id, 1, sell, quality, false)
    if not v then return { { "Wert im Vergleich", "unbekannt" } } end
    return { { "Wert im Vergleich", v > cheapest.value and "mehr als der billigste Platz" or "nicht mehr als der billigste Platz" } }
end

local function OnItem(tt, data)
    if not BT.Active() then return end
    if tt ~= _G.GameTooltip then return end
    if tt.IsForbidden and tt:IsForbidden() then return end
    local AP = WeintCodex.UIAuctionPrices
    local id = AP and AP.ItemIdOf and AP.ItemIdOf(tt, data)
    if not id and type(data) == "table" then id = Num(data.id) end
    local lines = id and BT.TooltipLines(id)
    if not lines then return end
    local m, g = C.textMuted, C.gold
    for _, l in ipairs(lines) do tt:AddDoubleLine(l[1], l[2], g[1], g[2], g[3], m[1], m[2], m[3]) end
end
BT.OnItem = OnItem

function BT.HookTooltips()
    if BT._hooked then return end
    BT._hooked = true
    local tdp, e = _G.TooltipDataProcessor, _G.Enum and _G.Enum.TooltipDataType
    if tdp and tdp.AddTooltipPostCall and e and e.Item then
        pcall(tdp.AddTooltipPostCall, e.Item, K.Measured("Ausmisten", OnItem))
    else
        local tt = _G.GameTooltip
        if type(tt) == "table" and tt.HookScript then
            tt:HookScript("OnTooltipSetItem", function(self) OnItem(self) end)
        end
    end
end

--------------------------------------------------
-- Ereignisse
--------------------------------------------------

local hookedFrames = {}
local function HookBagFrames()
    local function Hook(f)
        if type(f) == "table" and f.HookScript and not hookedFrames[f] then
            hookedFrames[f] = true
            f:HookScript("OnShow", function() if BT.lootOpen then BT.PaintBags() end end)
        end
    end
    for i = 1, (tonumber(_G.NUM_CONTAINER_FRAMES) or 13) do Hook(_G["ContainerFrame" .. i]) end
    Hook(_G.ContainerFrameCombinedBags)
    local UB = WeintCodex.UIBags
    if UB and UB.Refresh and _G.hooksecurefunc and not BT._ubHooked then
        BT._ubHooked = true
        _G.hooksecurefunc(UB, "Refresh", function() if BT.lootOpen then BT.PaintBags() end end)
    end
end

local ev = CreateFrame("Frame")
BT.events = ev
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function(_, event, a1)
    if event == "PLAYER_LOGIN" then
        BT.HookTooltips()
        HookBagFrames()
        ev:RegisterEvent("LOOT_OPENED")
        ev:RegisterEvent("LOOT_CLOSED")
        ev:RegisterEvent("LOOT_SLOT_CLEARED")
        ev:RegisterEvent("BAG_UPDATE_DELAYED")
        ev:RegisterEvent("QUEST_LOG_UPDATE")
        return
    end
    if event == "LOOT_OPENED" then
        BT.lootOpen = BT.Active()
        if not BT.lootOpen then return end
        BT.PairLoot()
        if _G.C_Timer and _G.C_Timer.After then _G.C_Timer.After(0, BT.Refresh) else BT.Refresh() end
    elseif event == "LOOT_CLOSED" then
        BT.lootOpen = false
        if pop then pop:Hide() end
        Wipe(BT.pairs)
        Wipe(BT.glow)
        Wipe(BT.offer)
        BT.MarkLoot()
        BT.PaintBags()
    elseif event == "LOOT_SLOT_CLEARED" then
        if BT.lootOpen then
            local li = BT.lootInfo[a1]
            if li then li.id = nil end
            BT.pairs[a1] = nil
            BT.offer[a1] = nil
            BT.ShowPopup()
        end
    else
        BT.dirty = true
        if BT.lootOpen then BT.Refresh() end
    end
end)

-- Standardwerte gleich beim Laden; Schalter auf der Komfortseite "Sammeln".
do
    local mod = K.Module(KEY)
    if mod then
        for k, v in pairs(BT.DEFAULTS) do if mod.defaults[k] == nil then mod.defaults[k] = v end end
        for _, page in ipairs(mod.pages or {}) do
            if page.key == "sammeln" then
                local orig = page.build
                page.build = function(B, ...)
                    if orig then orig(B, ...) end
                    B:Section("Volle Taschen beim Looten", "Passt Beute nicht mehr in die Taschen und ist sie mehr wert als dein billigster Platz, fragt ein Fenster, ob du diesen Platz löschen und die Beute nehmen willst. Gelöscht wird nur auf deinen Klick. Werkzeuge der Berufe, Handwerksmaterial, Questgegenstände, Verbrauchbares und alles ohne Preis werden nie vorgeschlagen.")
                    B:Row({ type = "toggle", label = "Fenster „Löschen & looten“", key = "triageOn" },
                          { type = "empty" })
                    B:Advanced()
                    B:Row({ type = "toggle", label = "Auch Grünes vorschlagen", key = "triageGreens" },
                          { type = "toggle", label = "Auktionspreis zählen", key = "triageAuction" })
                    B:EndAdvanced()
                end
            end
        end
    end
end
