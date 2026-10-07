--------------------------------------------------
-- WeintCodex :: Auktionspreise - Scan und Preis im Tooltip
--------------------------------------------------
-- Seit 6.17.0.0 (Wunsch des Spielers, nach dem Verhalten des Addons
-- ForeverGuide - kein Code daraus, es hat keine Lizenz): ein Knopf am
-- Auktionshaus liest die Angebote, und danach nennt jeder Tooltip eines
-- Gegenstands das guenstigste Angebot je Stueck. Eine Seite im Komfort,
-- gespeichert unter "comfort", wie jeder Komfort-Helfer von Haus aus AUS;
-- geht ohne Oberflaeche.
--
-- WAS DIE ZAHL IST: das guenstigste Sofortkauf-Angebot je Stueck, als du
-- zuletzt hingeschaut hast - kein "Wert", kein Durchschnitt. Ein einzelnes
-- billiges Angebot macht sie klein; darum stehen Menge und Tag daneben.
-- Herkunft: dein eigener Blick ins Auktionshaus. Kein Eintrag heisst "weiss
-- nicht" - dann schweigt der Tooltip, statt einen Preis zu erfinden.
--
-- DREI WEGE ZU DEN PREISEN, der Reihe nach:
--   1. Vollscan (C_AuctionHouse.ReplicateItems): alle Angebote auf einmal,
--      hoechstens alle 15 Minuten. Laut ForeverGuide antwortet der Server
--      von Forever darauf nicht immer - nach AP.REPLICATE_WAIT s ohne
--      Antwort geht es mit 2. weiter, und drei Tage lang gleich mit 2.
--   2. Suche (SendBrowseQuery mit leerem Text, Seite um Seite, jede erst,
--      wenn das Auktionshaus wieder Anfragen nimmt). Schickt der Server
--      AP.STALL s keine Seite mehr, gilt der Scan als unvollstaendig.
--   3. Nebenbei: was deine eigene Suche im Auktionshaus ohnehin zeigt.
-- GEMESSEN (6.18.0.1, Beta-Test): der Vollscan antwortet auf Forever mit
-- REPLICATE_ITEM_LIST_UPDATE - 66.155 Angebote, 2.982 Gegenstaende, ohne
-- Fehler. Die Suche als Rueckfall ist ungemessen. /wcui prüfen und
-- /wcui auktion sagen, welcher lief und was er brachte.
--
-- Gespeichert je Realm und Seite (Allianz, Horde, neutral: Gadgetzan,
-- Beutebucht, Ewige Warte) in WeintCodex_SavedData.auction - EINE Zahl je
-- Gegenstand: Preis, Menge, Tag und "von Spielern" zusammen (AP.Pack); eine
-- Tabelle je Gegenstand haette das Dreifache gekostet. Was AP.KEEP_DAYS Tage
-- nicht gesehen wurde, faellt heraus.
--
-- Seit 6.18.0.0 kommen Preise auch von anderen Spielern (ui/auctionshare.lua:
-- Gilde, ForeverGuide) - im Tooltip "von Spielern", dein Scan geht vor.
--------------------------------------------------

local K = WeintCodex.UIKit
local C = WeintCodex.Colors
local KEY = "comfort"

WeintCodex.UIAuctionPrices = {}
local AP = WeintCodex.UIAuctionPrices

AP.DEFAULTS = {
    ahPrices  = false,   -- der Helfer: Knopf am Auktionshaus, Preise im Tooltip
    ahStack   = true,    -- in den Taschen auch der Preis des ganzen Stapels
    ahPassive = true,    -- auch merken, was deine eigene Suche zeigt
    -- 6.18.0.0 (ui/auctionshare.lua): Preise von anderen Spielern.
    ahShareGuild = false, -- mit der Gilde teilen (senden und empfangen)
    ahListenFG   = false, -- aus dem Kanal von ForeverGuide nur empfangen
}

AP.REPLICATE_WAIT  = 35          -- so lange auf den Vollscan warten (s)
AP.REPLICATE_EVERY = 15 * 60     -- das Spiel erlaubt ihn hoechstens so oft
AP.NO_REPLICATE    = 3 * 86400   -- ohne Antwort: so lange gleich die Suche
AP.STALL           = 15          -- Suche: so lange ohne neue Seite, dann Schluss
AP.BATCH           = 1000        -- Vollscan: Angebote je Bild
AP.KEEP_DAYS       = 30
-- Preis * 1e7 + Menge * 1e4 + Tag muss unter 2^53 bleiben: hoechstens
-- ~90.000 Gold je Stueck (mehr wird gekappt), 999 Stueck. Der Tag (bis
-- AP.DAY_MAX, also bis 2039) traegt + AP.SHARED, wenn der Preis von anderen
-- Spielern kam.
AP.PRICE_MAX = 899999999
AP.QTY_MAX   = 999
AP.DAY_MAX   = 4999
AP.SHARED    = 5000

-- Die neutralen Auktionshaeuser: Tanaris (Gadgetzan), Schlingendorntal
-- (Beutebucht), Winterquell (Ewige Warte) - Kartennummern wie in data/.
AP.NEUTRAL_MAPS = { [1446] = true, [1434] = true, [1452] = true }

local SETTING = { stack = "ahStack", passive = "ahPassive" }
local function Get(k) return K.Get(KEY, SETTING[k] or k) end
function AP.Active() return K.IsActive(KEY) and K.Get(KEY, "ahPrices") and true or false end

local function Clock() return (_G.GetTime and K.Plain(_G.GetTime())) or 0 end
local function Time() return (_G.time and _G.time()) or 0 end

local function Say(text)
    print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " " .. text)
end

-- "12.345"
local function Thousands(n)
    local s = tostring(math.floor(n))
    local out = s:reverse():gsub("(%d%d%d)", "%1."):reverse()
    return (out:gsub("^%.", ""))
end
AP.Thousands = Thousands

--------------------------------------------------
-- Eine Zahl je Gegenstand
--------------------------------------------------

-- Tagesnummer nach Kalender (Ortszeit), gezaehlt ab dem 1.1.2026.
local function JDN(y, m, d)
    local a = math.floor((14 - m) / 12)
    local yy, mm = y + 4800 - a, m + 12 * a - 3
    return d + math.floor((153 * mm + 2) / 5) + 365 * yy + math.floor(yy / 4)
        - math.floor(yy / 100) + math.floor(yy / 400) - 32045
end
local BASE = JDN(2026, 1, 1)

function AP.Day(t)
    local d = _G.date and _G.date("*t", t or Time())
    if type(d) ~= "table" then return 0 end
    local n = JDN(d.year, d.month, d.day) - BASE
    if n < 0 then return 0 end
    return n > AP.DAY_MAX and AP.DAY_MAX or n
end

function AP.Pack(price, qty, day, shared)
    price = math.floor(price)
    if price > AP.PRICE_MAX then price = AP.PRICE_MAX end
    qty = math.floor(qty or 0)
    if qty > AP.QTY_MAX then qty = AP.QTY_MAX elseif qty < 0 then qty = 0 end
    day = math.floor(day or 0)
    if day > AP.DAY_MAX then day = AP.DAY_MAX elseif day < 0 then day = 0 end
    return price * 1e7 + qty * 1e4 + day + (shared and AP.SHARED or 0)
end

-- Preis, Menge, Tag. v / 1e7 rundet nie auf die naechste ganze Zahl: der
-- Abstand dorthin ist mindestens 1e-7, ein halber Schritt der Gleitkommazahl
-- unter 2^30 (> AP.PRICE_MAX) nur 6e-8. Viertens: von anderen Spielern.
function AP.Unpack(v)
    local price = math.floor(v / 1e7)
    local rest = v - price * 1e7
    local qty = math.floor(rest / 1e4)
    local day = rest - qty * 1e4
    if day >= AP.SHARED then return price, qty, day - AP.SHARED, true end
    return price, qty, day, false
end

--------------------------------------------------
-- Ablage je Realm und Seite
--------------------------------------------------

function AP.Realm()
    local r = _G.GetNormalizedRealmName and K.Plain(_G.GetNormalizedRealmName())
    if type(r) ~= "string" or r == "" then r = _G.GetRealmName and K.Plain(_G.GetRealmName()) end
    return (type(r) == "string" and r ~= "") and r or "?"
end

function AP.Faction()
    local f = _G.UnitFactionGroup and K.Plain(_G.UnitFactionGroup("player"))
    return (f == "Alliance" or f == "Horde") and f or "Neutral"
end

-- Die Seite des Auktionshauses, an dem du stehst.
function AP.SideHere()
    local map = K.BestMap and K.BestMap()
    if map and AP.NEUTRAL_MAPS[map] then return "Neutral" end
    return AP.Faction()
end

function AP.Store(side, create)
    local sd = WeintCodex.SavedData
    if type(sd) ~= "table" then return nil end
    local key = AP.Realm() .. "|" .. (side or AP.Faction())
    if not create then return sd.auction and sd.auction[key] end
    sd.auction = sd.auction or {}
    local s = sd.auction[key]
    if not s then
        s = { items = {} }
        sd.auction[key] = s
    end
    return s
end

-- Was AP.KEEP_DAYS Tage nicht gesehen wurde, faellt heraus.
function AP.Prune(store, today)
    today = today or AP.Day()
    local n = 0
    for id, v in pairs(store.items) do
        local _, _, day = AP.Unpack(v)
        if today - day > AP.KEEP_DAYS then store.items[id] = nil else n = n + 1 end
    end
    return n
end

-- Gesammeltes in die Ablage: price[id] = Stueckpreis, qty[id] = Menge.
function AP.Merge(store, price, qty, day)
    day = day or AP.Day()
    local n = 0
    for id, p in pairs(price) do
        store.items[id] = AP.Pack(p, qty[id], day)
        n = n + 1
    end
    return n
end

-- Preis eines Gegenstands: zuerst das Auktionshaus, an dem du stehst (sonst
-- das deiner Fraktion), dann das neutrale. Nichts gefunden: nil.
-- { price, qty, day, shared, neutral, missing } - missing: beim letzten
-- vollstaendigen Scan nicht im Angebot (der Preis ist der zuletzt gesehene).
local found = {}
function AP.Lookup(id)
    if type(id) ~= "number" then return nil end
    local side = AP.side or AP.Faction()
    local store = AP.Store(side)
    local v = store and store.items[id]
    local neutral = side == "Neutral"
    if not v and side ~= "Neutral" then
        store = AP.Store("Neutral")
        v = store and store.items[id]
        neutral = true
    end
    if not v then return nil end
    found.price, found.qty, found.day, found.shared = AP.Unpack(v)
    found.neutral = neutral
    found.missing = store.full ~= nil and found.day < AP.Day(store.full)
    return found
end

--------------------------------------------------
-- Geld und Alter als Text
--------------------------------------------------

function AP.Money(copper)
    if type(copper) ~= "number" then return "—" end
    if _G.GetCoinTextureString then
        local ok, s = pcall(_G.GetCoinTextureString, copper)
        if ok and type(s) == "string" then return s end
    end
    local g = math.floor(copper / 10000)
    local s = math.floor((copper % 10000) / 100)
    local c = copper % 100
    local parts = {}
    if g > 0 then parts[#parts + 1] = Thousands(g) .. " G" end
    if s > 0 then parts[#parts + 1] = s .. " S" end
    if c > 0 or #parts == 0 then parts[#parts + 1] = c .. " K" end
    return table.concat(parts, " ")
end

function AP.AgeText(day, today)
    local d = (today or AP.Day()) - day
    if d <= 0 then return "heute" end
    if d == 1 then return "gestern" end
    return "vor " .. d .. " Tagen"
end

function AP.QtyText(qty)
    if qty >= AP.QTY_MAX then return Thousands(AP.QTY_MAX) .. "+ Stück im Angebot" end
    if qty <= 0 then return nil end
    return qty .. " Stück im Angebot"
end

--------------------------------------------------
-- Tooltip
--------------------------------------------------

-- Wie viele in dem Taschenplatz liegen, auf den der Tooltip zeigt - oder nil.
function AP.StackCount(tt)
    local bag, slot
    if tt.GetPrimaryTooltipInfo then
        local ok, info = pcall(tt.GetPrimaryTooltipInfo, tt)
        if ok and type(info) == "table" and info.getterName == "GetBagItem" and type(info.getterArgs) == "table" then
            bag, slot = K.Plain(info.getterArgs[1]), K.Plain(info.getterArgs[2])
        end
    end
    if type(bag) ~= "number" then
        local owner = tt.GetOwner and tt:GetOwner()
        if type(owner) == "table" and owner.GetBagID and owner.GetID then
            local ok, b = pcall(owner.GetBagID, owner)
            bag, slot = ok and K.Plain(b) or nil, K.Plain(owner:GetID())
        end
    end
    if type(bag) ~= "number" or type(slot) ~= "number" then return nil end
    local cc = _G.C_Container
    if not (cc and cc.GetContainerItemInfo) then return nil end
    local ok, info = pcall(cc.GetContainerItemInfo, bag, slot)
    local n = ok and type(info) == "table" and K.Plain(info.stackCount)
    return type(n) == "number" and n or nil
end

local function ItemIdOf(tt, data)
    local id = type(data) == "table" and K.Plain(data.id)
    if type(id) == "number" then return id end
    if not tt.GetItem then return nil end
    local ok, _, link = pcall(tt.GetItem, tt)
    link = ok and K.Plain(link) or nil
    if type(link) ~= "string" then return nil end
    return tonumber(link:match("item:(%d+)"))
end
AP.ItemIdOf = ItemIdOf

-- Zeilen fuer einen Gegenstand: { links, rechts } oder { text } - oder nil.
function AP.TooltipLines(id, stack)
    local e = AP.Lookup(id)
    if not e then return nil end
    local lines = {}
    lines[1] = { e.neutral and "Auktionshaus (neutral)" or "Auktionshaus", "ab " .. AP.Money(e.price) }
    if stack and stack > 1 then
        lines[#lines + 1] = { "Stapel (" .. stack .. ")", AP.Money(e.price * stack) }
    end
    local info
    if e.missing then
        info = "zuletzt " .. AP.AgeText(e.day) .. " · beim letzten Scan nicht im Angebot"
    else
        info = (e.shared and "von Spielern, " or "") .. AP.AgeText(e.day)
        local q = AP.QtyText(e.qty)
        if q then info = info .. " · " .. q end
    end
    lines[#lines + 1] = { info }
    return lines
end

local function OnItem(tt, data)
    if not AP.Active() then return end
    if tt ~= _G.GameTooltip and tt ~= _G.ItemRefTooltip then return end
    if tt.IsForbidden and tt:IsForbidden() then return end
    local id = ItemIdOf(tt, data)
    if not id then return end
    local stack = Get("stack") and AP.StackCount(tt) or nil
    local lines = AP.TooltipLines(id, stack)
    if not lines then return end
    local m, b = C.textMuted, C.textBright
    for _, l in ipairs(lines) do
        if l[2] then
            tt:AddDoubleLine(l[1], l[2], m[1], m[2], m[3], b[1], b[2], b[3])
        else
            tt:AddLine(l[1], m[1], m[2], m[3])
        end
    end
    AP.lastTooltip = id
end
AP.OnItem = OnItem

function AP.HookTooltips()
    if AP._hooked then return end
    AP._hooked = true
    local tdp, e = _G.TooltipDataProcessor, _G.Enum and _G.Enum.TooltipDataType
    if tdp and tdp.AddTooltipPostCall and e and e.Item then
        pcall(tdp.AddTooltipPostCall, e.Item, K.Measured("Auktionspreise", OnItem))
        AP.hookedVia = "TooltipDataProcessor"
    else
        for _, n in ipairs({ "GameTooltip", "ItemRefTooltip" }) do
            local tt = _G[n]
            if type(tt) == "table" and tt.HookScript then
                tt:HookScript("OnTooltipSetItem", function(self) OnItem(self) end)
            end
        end
        AP.hookedVia = "OnTooltipSetItem"
    end
end

--------------------------------------------------
-- Scan
--------------------------------------------------

AP.log = {}
local function Log(msg)
    local log = AP.log
    if #log >= 10 then table.remove(log, 1) end
    log[#log + 1] = msg
end

local scan            -- nil, oder der laufende Scan
local drv = CreateFrame("Frame")
drv:Hide()
AP.driver = drv

function AP.Scanning() return scan ~= nil end
function AP.Phase() return scan and scan.phase or nil end

local function NumReplicate()
    local ah = _G.C_AuctionHouse
    if not (ah and ah.GetNumReplicateItems) then return 0 end
    local ok, n = pcall(ah.GetNumReplicateItems)
    n = ok and K.Plain(n)
    return type(n) == "number" and n or 0
end

local function ThrottleReady()
    local ah = _G.C_AuctionHouse
    if not (ah and ah.IsThrottledMessageSystemReady) then return true end
    local ok, r = pcall(ah.IsThrottledMessageSystemReady)
    return not ok or K.Bool(r, true)
end

local function Record(s, id, unit, qty)
    local p = s.price[id]
    if not p or unit < p then s.price[id] = unit end
    s.qty[id] = (s.qty[id] or 0) + qty
end

local function Count(t)
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    return n
end

local function Progress()
    local b = AP.button
    if not b then return end
    local text
    if not scan then text = "Preise scannen"
    elseif scan.phase == "replicate" then text = "Wartet auf den Server …"
    elseif scan.phase == "read" then
        text = "Liest … " .. (scan.n > 0 and math.floor(scan.i * 100 / scan.n) or 0) .. " %"
    else text = "Sucht … Seite " .. (scan.pages + 1) end
    if b._text ~= text then
        b._text = text
        b:SetText(text)
    end
end
AP.Progress = Progress

local function Stop()
    scan = nil
    drv:Hide()
    Progress()
end

local function Finish(full)
    local s = scan
    if not s then return end
    Stop()
    local n = Count(s.price)
    if n == 0 then
        Log(s.via .. ": nichts erhalten")
        AP.last = { ok = false, via = s.via, at = Time() }
        Say("Auktionshaus: keine Preise erhalten. Versuch es gleich noch einmal; /wcui auktion zeigt, was passiert ist.")
        return
    end
    local store = s.store
    AP.Merge(store, s.price, s.qty)
    if full then store.full, store.via, store.lots, store.n = Time(), s.via, s.lots, n end
    local kept = AP.Prune(store)
    if full and AP.OnOwnScanHook then AP.OnOwnScanHook(s.side) end
    AP.last = { ok = true, full = full, via = s.via, lots = s.lots, n = n, kept = kept, at = Time(), side = s.side }
    Log(s.via .. ": " .. s.lots .. " Angebote, " .. n .. " Gegenstände" .. (full and "" or ", unvollständig"))
    Say("Auktionshaus gelesen: " .. Thousands(s.lots) .. " Angebote, " .. Thousands(n) .. " Gegenstände"
        .. (full and "." or " – unvollständig, der Server hat nicht alles geschickt."))
end
AP.Finish = Finish

local function Fail(why)
    Log(why)
    if scan and Count(scan.price) > 0 then return Finish(false) end
    local via = scan and scan.via or "?"
    Stop()
    AP.last = { ok = false, via = via, at = Time(), why = why }
    Say("Auktionshaus: kein Scan möglich – " .. why .. ".")
end

-- Suche: leerer Text; zwei Formen der Anfrage, falls der Client die erste
-- nicht annimmt.
function AP.Query(variant)
    if variant == 1 then
        local E = _G.Enum and _G.Enum.AuctionHouseSortOrder
        local sorts = {}
        if E and E.Price then sorts[1] = { sortOrder = E.Price, reverseSort = false } end
        return { searchString = "", sorts = sorts, filters = {}, itemClassFilters = {} }
    end
    return { searchString = "", sorts = {} }
end

local function TrySend()
    local s = scan
    if not (s and s.pending) or not ThrottleReady() then return end
    local ah = _G.C_AuctionHouse
    local what = s.pending
    s.pending, s.wait = nil, 0
    if what == "query" then
        local ok, err = pcall(ah.SendBrowseQuery, AP.Query(s.variant))
        if ok then Log("Suche angefragt (Form " .. s.variant .. ")") return end
        Log("Suche, Form " .. s.variant .. ": " .. tostring(err))
        if s.variant < 2 then
            s.variant, s.pending = s.variant + 1, "query"
            return TrySend()
        end
        return Fail("die Suche nimmt der Client nicht an")
    end
    if not (ah.RequestMoreBrowseResults and pcall(ah.RequestMoreBrowseResults)) then
        Log("Suche: weitere Seiten gibt es nicht")
        return Finish(false)
    end
end
AP.TrySend = TrySend

function AP.StartBrowse()
    local ah = _G.C_AuctionHouse
    if not (ah and ah.SendBrowseQuery and ah.GetBrowseResults) then
        return Fail("weder Vollscan noch Suche stehen zur Verfügung")
    end
    scan.phase, scan.via, scan.wait = "browse", "Suche", 0
    scan.variant, scan.seen, scan.pages, scan.pending = 1, 0, 0, "query"
    drv:Show()
    TrySend()
    Progress()
    return true
end

-- Eine Seite der Suche ist da (Ereignis). Jede Zeile nur einmal.
local function CollectBrowse()
    local s = scan
    local ah = _G.C_AuctionHouse
    local ok, results = pcall(ah.GetBrowseResults)
    if not ok or type(results) ~= "table" then return end
    if #results < s.seen then s.seen = 0 end
    for k = s.seen + 1, #results do
        local r = results[k]
        local key = type(r) == "table" and r.itemKey
        local id = type(key) == "table" and K.Plain(key.itemID)
        local price, qty = type(r) == "table" and K.Plain(r.minPrice), type(r) == "table" and K.Plain(r.totalQuantity)
        if type(id) == "number" and type(price) == "number" and price > 0 then
            qty = type(qty) == "number" and qty or 0
            Record(s, id, price, qty)
            s.lots = s.lots + 1
        end
    end
    s.seen, s.wait = #results, 0
    s.pages = s.pages + 1
    local okf, full = pcall(ah.HasFullBrowseResults)
    if okf and K.Bool(full, false) then
        Log("Suche: " .. s.pages .. " Seiten, vollständig")
        return Finish(true)
    end
    s.pending = "more"
    TrySend()
    Progress()
end

local function BeginRead(how)
    scan.phase, scan.i, scan.n = "read", 0, NumReplicate()
    Log("Vollscan: " .. scan.n .. " Angebote (" .. how .. ")")
    Progress()
end

-- Ein Stueck des Vollscans lesen (je Bild AP.BATCH Angebote).
local function ReadBatch()
    local s = scan
    local f = _G.C_AuctionHouse and _G.C_AuctionHouse.GetReplicateItemInfo
    if not f then return Fail("Vollscan nicht lesbar") end
    local last = math.min(s.i + AP.BATCH, s.n) - 1
    for i = s.i, last do
        local ok, _, _, count, _, _, _, _, _, _, buyout, _, _, _, _, _, _, itemID = pcall(f, i)
        if ok then
            count, buyout, itemID = K.Plain(count), K.Plain(buyout), K.Plain(itemID)
            if type(itemID) == "number" and type(buyout) == "number" and buyout > 0 then
                count = (type(count) == "number" and count > 0) and count or 1
                Record(s, itemID, math.floor(buyout / count), count)
                s.lots = s.lots + 1
            end
        end
    end
    s.i = last + 1
    if s.i >= s.n then return Finish(true) end
    Progress()
end

-- Der Taktgeber, solange ein Scan laeuft. `el` in Sekunden.
function AP.Step(el)
    local s = scan
    if not s then return end
    el = el or 0
    if s.phase == "read" then return ReadBatch() end
    s.wait = s.wait + el
    if s.phase == "replicate" then
        s.poll = s.poll + el
        if s.poll >= 1 then
            s.poll = 0
            -- Ohne Ereignis: die Angebote kommen trotzdem an. Zweimal
            -- dieselbe Zahl hintereinander heisst: fertig.
            local n = NumReplicate()
            if n > 0 and n == s.lastN then s.stable = s.stable + 1 else s.stable = 0 end
            s.lastN = n
            if s.stable >= 2 then return BeginRead("ohne Ereignis") end
        end
        if s.wait >= AP.REPLICATE_WAIT then
            if (s.lastN or 0) > 0 then return BeginRead("nach Wartezeit") end
            s.store.noReplicate = Time() + AP.NO_REPLICATE
            Log("Vollscan: keine Antwort nach " .. AP.REPLICATE_WAIT .. " s – weiter mit der Suche")
            return AP.StartBrowse()
        end
        return
    end
    -- Suche: auch das Warten auf "bereit" zaehlt mit.
    if s.wait >= AP.STALL then
        Log("Suche: " .. AP.STALL .. " s keine neue Seite")
        return Finish(false)
    end
    if s.pending then return TrySend() end
end
drv:SetScript("OnUpdate", K.Measured("Auktionspreise", function(_, el) AP.Step(el) end))

-- Scan starten (Knopf, /wcui auktion scan).
function AP.Start()
    if not AP.Active() then
        Say("Auktionspreise sind aus (Komfort → Auktionshaus).")
        return false
    end
    if not AP.open then
        Say("Erst das Auktionshaus öffnen.")
        return false
    end
    if scan then return false end
    local ah = _G.C_AuctionHouse
    if type(ah) ~= "table" then
        Say("Dieser Client hat kein Auktionshaus, das Addons lesen dürfen.")
        return false
    end
    local store = AP.Store(AP.side, true)
    scan = { store = store, side = AP.side, price = {}, qty = {}, lots = 0, wait = 0, poll = 0, stable = 0, pages = 0 }
    AP.log = {}
    local now = Time()
    if not ah.ReplicateItems then
        Log("Vollscan gibt es nicht")
    elseif (store.noReplicate or 0) > now then
        Log("Vollscan: der Server antwortete zuletzt nicht – gleich die Suche")
    elseif now - (store.replicateAt or 0) < AP.REPLICATE_EVERY then
        Log("Vollscan: keine 15 Minuten seit dem letzten – die Suche")
    else
        store.replicateAt = now
        local ok, err = pcall(ah.ReplicateItems)
        if ok then
            scan.phase, scan.via = "replicate", "Vollscan"
            Log("Vollscan angefragt")
            drv:Show()
            Progress()
            return true
        end
        Log("Vollscan: " .. tostring(err))
    end
    return AP.StartBrowse()
end

--------------------------------------------------
-- Nebenbei: was deine Suche zeigt
--------------------------------------------------

local passive = { price = {}, qty = {}, seen = 0 }
function AP.CollectPassive(reset)
    local ah = _G.C_AuctionHouse
    if not (ah and ah.GetBrowseResults) then return 0 end
    local ok, results = pcall(ah.GetBrowseResults)
    if not ok or type(results) ~= "table" then return 0 end
    if reset or #results < passive.seen then passive.seen = 0 end
    local price, qty = passive.price, passive.qty
    for id in pairs(price) do price[id], qty[id] = nil, nil end
    for k = passive.seen + 1, #results do
        local r = results[k]
        local key = type(r) == "table" and r.itemKey
        local id = type(key) == "table" and K.Plain(key.itemID)
        local p = type(r) == "table" and K.Plain(r.minPrice)
        if type(id) == "number" and type(p) == "number" and p > 0 then
            local q = K.Plain(r.totalQuantity)
            Record(passive, id, p, type(q) == "number" and q or 0)
        end
    end
    passive.seen = #results
    local store = AP.Store(AP.side, true)
    return store and AP.Merge(store, price, qty) or 0
end

--------------------------------------------------
-- Knopf am Auktionshaus
--------------------------------------------------

local function ButtonTooltip(self)
    local gt = _G.GameTooltip
    if not gt then return end
    gt:SetOwner(self, "ANCHOR_BOTTOM")
    gt:AddLine("Preise scannen")
    for _, line in ipairs(AP.StatusLines()) do gt:AddLine(line, 1, 1, 1, true) end
    gt:Show()
end

function AP.EnsureButton()
    local host = _G.AuctionHouseFrame
    if AP.button or type(host) ~= "table" then return AP.button end
    local b = CreateFrame("Button", "WeintCodexAuctionScan", host, "UIPanelButtonTemplate")
    b:SetSize(140, 20)
    -- UNGEMESSEN: in der Titelzeile links vom Schliessen-Knopf.
    b:SetPoint("TOPRIGHT", host, "TOPRIGHT", -28, -1)
    b:SetScript("OnClick", function() AP.Start() end)
    b:SetScript("OnEnter", ButtonTooltip)
    b:SetScript("OnLeave", function() if _G.GameTooltip then _G.GameTooltip:Hide() end end)
    AP.button = b
    Progress()
    return b
end

--------------------------------------------------
-- Bericht: /wcui auktion, Knopf, Selbstpruefung
--------------------------------------------------

local SIDE_LABEL = { Alliance = "Allianz", Horde = "Horde", Neutral = "neutral" }

function AP.StatusLines(side)
    side = side or AP.side or AP.Faction()
    local out = {}
    local store = AP.Store(side)
    local label = "Auktionshaus " .. (SIDE_LABEL[side] or side)
    if not store then
        out[1] = label .. ": noch nie gelesen."
        return out
    end
    local n = Count(store.items)
    if store.full and _G.date then
        out[1] = label .. ": " .. Thousands(n) .. " Gegenstände, zuletzt vollständig "
            .. _G.date("%d.%m. %H:%M", store.full) .. " (" .. (store.via or "?") .. ", "
            .. Thousands(store.lots or 0) .. " Angebote)"
    else
        out[1] = label .. ": " .. Thousands(n) .. " Gegenstände, noch kein vollständiger Scan"
    end
    local sh = store.shared
    if type(sh) == "table" and sh.at and _G.date then
        out[#out + 1] = "Zuletzt von Spielern: " .. Thousands(sh.n or 0) .. " Gegenstände von " .. (sh.from or "?")
            .. " (" .. (sh.via or "?") .. "), Scan vom " .. _G.date("%d.%m. %H:%M", sh.at)
    end
    if (store.noReplicate or 0) > Time() then
        out[#out + 1] = "Der Vollscan blieb zuletzt ohne Antwort – bis " .. (_G.date and _G.date("%d.%m.", store.noReplicate) or "?")
            .. " gleich die Suche."
    end
    return out
end

function AP.Report()
    local out = {}
    local sides = { AP.Faction() }
    if sides[1] ~= "Neutral" then sides[2] = "Neutral" end
    for _, side in ipairs(sides) do
        for _, l in ipairs(AP.StatusLines(side)) do out[#out + 1] = l end
    end
    if AP.last then
        local l = AP.last
        out[#out + 1] = "Letzter Scan: " .. (l.ok and ((l.full and "vollständig" or "unvollständig") .. " über " .. l.via
            .. ", " .. Thousands(l.lots) .. " Angebote, " .. Thousands(l.n) .. " Gegenstände")
            or ("ohne Ergebnis (" .. (l.why or l.via) .. ")"))
    end
    if #AP.log > 0 then
        out[#out + 1] = "Schritte:"
        for _, m in ipairs(AP.log) do out[#out + 1] = "  " .. m end
    end
    if AP.ShareLines then
        for _, l in ipairs(AP.ShareLines()) do out[#out + 1] = l end
    end
    out[#out + 1] = "Der Preis ist das günstigste Sofortkauf-Angebot je Stück, als du zuletzt hingeschaut hast – kein Durchschnitt."
    return out
end

--------------------------------------------------
-- Modul
--------------------------------------------------

local ev = CreateFrame("Frame")
AP.events = ev
local AH_EVENTS = { "REPLICATE_ITEM_LIST_UPDATE", "AUCTION_HOUSE_BROWSE_RESULTS_UPDATED",
                    "AUCTION_HOUSE_BROWSE_RESULTS_ADDED", "AUCTION_HOUSE_THROTTLED_SYSTEM_READY" }

local function SetAHEvents(on)
    for _, e in ipairs(AH_EVENTS) do
        if on then pcall(ev.RegisterEvent, ev, e) else pcall(ev.UnregisterEvent, ev, e) end
    end
end

local function OnEvent(_, event)
    if event == "AUCTION_HOUSE_SHOW" then
        AP.open, AP.side = true, AP.SideHere()
        passive.seen = 0
        SetAHEvents(true)
        -- Das Fenster laedt das Spiel erst beim Ansprechen - womoeglich
        -- erst nach diesem Ereignis.
        if not AP.EnsureButton() and _G.C_Timer and _G.C_Timer.After then
            _G.C_Timer.After(0, function()
                if AP.open and AP.Active() then AP.EnsureButton() end
            end)
        end
        if AP.button then AP.button:Show() end
    elseif event == "AUCTION_HOUSE_CLOSED" then
        AP.open = nil
        if scan then
            Log("Auktionshaus geschlossen")
            Finish(false)
        end
        AP.side = nil
        SetAHEvents(false)
    elseif event == "REPLICATE_ITEM_LIST_UPDATE" then
        if scan and scan.phase == "replicate" then BeginRead("Ereignis") end
    elseif event == "AUCTION_HOUSE_THROTTLED_SYSTEM_READY" then
        if scan then TrySend() end
    elseif scan and scan.phase == "browse" then
        CollectBrowse()
    elseif Get("passive") and AP.open then
        AP.CollectPassive(event == "AUCTION_HOUSE_BROWSE_RESULTS_UPDATED")
    end
end
ev:SetScript("OnEvent", K.Measured("Auktionspreise", OnEvent))
AP.OnEvent = OnEvent

local function Apply()
    local on = AP.Active()
    for _, e in ipairs({ "AUCTION_HOUSE_SHOW", "AUCTION_HOUSE_CLOSED" }) do
        if on then pcall(ev.RegisterEvent, ev, e) else pcall(ev.UnregisterEvent, ev, e) end
    end
    if on then AP.HookTooltips() end
    if not on then
        if scan then Stop() end
        SetAHEvents(false)
        AP.open, AP.side = nil, nil
    end
    if AP.button then AP.button:SetShown(on) end
end
AP.Apply = Apply

local function Build(B)
    local off = function() return not K.Get(KEY, "ahPrices") end
    B:Section("Auktionshaus", "Ein Knopf oben am Auktionshaus liest alle Angebote. Danach steht in jedem Tooltip das günstigste Angebot je Stück – mit dem Tag, an dem du es gesehen hast.")
    B:Row({ type = "toggle", label = "Auktionspreise", key = "ahPrices",
            description = "Knopf „Preise scannen“ am Auktionshaus, Preis im Tooltip." },
          { type = "toggle", label = "Preis des Stapels", key = "ahStack", disabled = off,
            description = "In den Taschen: was der ganze Stapel kostet." })
    B:Row({ type = "toggle", label = "Auch beim Stöbern merken", key = "ahPassive", disabled = off,
            description = "Was deine eigene Suche im Auktionshaus zeigt, ohne Scan." })
    B:Section("Preise von anderen Spielern", "Dein eigener Scan geht immer vor. Fremde Preise stehen im Tooltip als „von Spielern“; einer, der mehr als dreimal so hoch oder niedrig ist wie der bekannte, zählt erst, wenn ein zweiter Spieler ihn bestätigt.")
    B:Row({ type = "toggle", label = "Mit der Gilde teilen", key = "ahShareGuild", disabled = off,
            description = "Hat ein Gildenmitglied mit WeintCodex frischere Preise, kommen sie zu dir – und deine zu ihm." },
          { type = "toggle", label = "Preise aus ForeverGuide übernehmen", key = "ahListenFG", disabled = off,
            description = "Nur zuhören: tritt dem versteckten Kanal von ForeverGuide bei und sendet nie etwas." })
    B:Note("Gemerkt wird je Realm und Auktionshaus (Allianz, Horde, neutral), höchstens 30 Tage. Was zuletzt passiert ist: /wcui auktion.")
end

-- An den Komfort haengen: Standardwerte und eine Seite.
local mod = K.Module(KEY)
if mod then
    for k, v in pairs(AP.DEFAULTS) do
        if mod.defaults[k] == nil then mod.defaults[k] = v end
    end
    mod.pages[#mod.pages + 1] = { key = "auktion", label = "Auktionshaus", build = Build }
end

K.Listen(function(kind, key)
    if (kind == "active" or kind == "setting") and key == KEY then Apply() end
end)
