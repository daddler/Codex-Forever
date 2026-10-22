--------------------------------------------------
-- WeintCodex :: Oberflaeche - Taschen
--------------------------------------------------
-- Alle Taschen in einem Fenster, als ein Raster: Rucksack zuerst, dann
-- Tasche 1 bis 4 (und die Reagenzientasche, wo es sie gibt). Suche,
-- Sortieren, Gold, Gegenstandsstufe auf Ausruestung.
--
-- DIE KNOEPFE SIND DIE DES SPIELS (ContainerFrameItemButtonTemplate).
-- Benutzen, Anlegen, Verkaufen, Ziehen und der Tooltip laufen dadurch
-- ueber den geschuetzten Code des Spiels, nicht ueber dieses Addon. Die
-- Tasche eines Knopfs ist die ID seines Elternrahmens, der Platz seine
-- eigene ID - so erwartet es die Vorlage (dasselbe Verfahren wie in
-- EllesmereUI; der Code ist eigener).
--
-- NIE IM KAMPF ANLEGEN. Ein Gegenstandsknopf, der im Kampf entsteht, ist
-- "tainted": ein Klick darauf endet in ADDON_ACTION_FORBIDDEN. Alle
-- Knoepfe werden deshalb beim Anmelden auf Vorrat angelegt, ausserhalb
-- des Kampfes. Reicht der Vorrat (bei sehr grossen Taschen) einmal nicht,
-- fehlen die letzten Plaetze bis nach dem Kampf - sichtbar, mit Hinweis.
--
-- Die Bank bleibt die des Spiels.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIBags = {}

local BG = WeintCodex.UIBags
local K  = WeintCodex.UIKit
local C  = WeintCodex.Colors
local F  = WeintCodex.Fonts
local KEY = "bags"

local defaults = {
    columns    = 12,
    slotSize   = 36,
    spacing    = 4,
    itemLevel  = true,
    qualityBorder = true,
    dimJunk    = true,
    scale      = 100,
    -- 6.26.19.0 (Beta-Test: "Taschen als einzelne anzeigen, mit Abstaenden
    -- und eigener Slotzahl - Koecher, Splitter, Reagenzien: ich muss immer
    -- zaehlen, was noch frei ist"). Ein Fenster bleibt; jede Tasche ein
    -- eigener Block mit Name und "frei / Plaetze".
    split      = false,
    -- 6.123.0.0 (Beta-Test: "Kategorien einstellen wie Baganator, neu
    -- Gepluendertes setzt sich von selbst hin"): Gegenstaende nach Art
    -- gruppiert statt nach Tasche. Nach dem Verhalten von Baganator, ohne
    -- dessen Code.
    -- 6.125.1.0 (Wunsch: "fuer jetzt optional einschaltbar - nach der
    -- Beta wird alles aktiviert"): ab Werk aus.
    categories = false,
}
-- Die Kategorien in Reihenfolge. `classes`: Gegenstandsklassen des Spiels
-- (C_Item.GetItemInfoInstant). Abgeschaltete fallen in "Verschiedenes".
BG.CATEGORIES = {
    { key = "new",        label = "Neu" },
    { key = "quest",      label = "Quest",         classes = { [12] = true } },
    { key = "equipment",  label = "Ausrüstung",    classes = { [2] = true, [4] = true } },
    { key = "consumable", label = "Verbrauchbar",  classes = { [0] = true } },
    { key = "trade",      label = "Handwerk",      classes = { [7] = true, [5] = true, [3] = true } },
    { key = "recipe",     label = "Rezepte",       classes = { [9] = true } },
    { key = "ammo",       label = "Munition",      classes = { [6] = true } },
    { key = "container",  label = "Taschen",       classes = { [1] = true, [11] = true } },
    { key = "misc",       label = "Verschiedenes" },
    { key = "junk",       label = "Schrott" },
    { key = "empty",      label = "Leer" },
}
for _, c in ipairs(BG.CATEGORIES) do defaults["cat_" .. c.key] = true end
-- 6.124.0.0 (Wunsch: "eigene Kategorien einstellen"): Namen in
-- Reihenfolge, und welcher Gegenstand wohin gehoert ([itemID] = Schluessel,
-- eigene als "c:Name", sonst der einer eingebauten Kategorie). Zugeordnet
-- wird, indem man einen Gegenstand auf die Ueberschrift zieht.
defaults.customCats = {}
defaults.assign = {}
-- 6.125.0.0 (Wunsch: "Kategorien sollen sich umsortieren lassen"):
-- Reihenfolge als Liste von Schluesseln; was fehlt, kommt an seinen
-- gewohnten Platz dahinter.
defaults.catOrder = {}
-- 6.126.0.0: die persoenliche Bank nach Kategorien (ui/bankcats.lua);
-- die Gildenbank-Ansicht von 6.125.0.0 ist auf Wunsch wieder weg.
defaults.bankCats = false
BG.CAT_GAP = 12
BG.HEAD_H, BG.BAG_GAP = 16, 10

local function Opt(k) return K.Get(KEY, k) end

local POOL = 180   -- Vorrat an Knoepfen; vier 36er-Taschen plus Rucksack sind 160

local win, grid, gold, search, note
local heads = {}   -- Kopfzeile je Tasche (nur "einzeln")
local slots = {}   -- { holder, button } je Platz im Vorrat
local used = 0

--------------------------------------------------
-- Welche Taschen?
--------------------------------------------------

local function BagIDs()
    local ids = {}
    local first = _G.BACKPACK_CONTAINER or 0
    local last = _G.NUM_BAG_SLOTS or 4
    for b = first, last do ids[#ids + 1] = b end
    -- Reagenzientasche (moderner Client). Auf Forever unbekannt - fehlt
    -- sie, meldet der Client 0 Plaetze, und sie faellt von selbst weg.
    if _G.Enum and _G.Enum.BagIndex and _G.Enum.BagIndex.ReagentBag then
        ids[#ids + 1] = _G.Enum.BagIndex.ReagentBag
    end
    return ids
end

local function NumSlots(bag)
    local cc = _G.C_Container
    if cc and cc.GetContainerNumSlots then return cc.GetContainerNumSlots(bag) or 0 end
    return 0
end

local function Info(bag, slot)
    local cc = _G.C_Container
    return cc and cc.GetContainerItemInfo and cc.GetContainerItemInfo(bag, slot) or nil
end

--------------------------------------------------
-- Knoepfe
--------------------------------------------------

-- 6.54.3.0 (Fehlerbericht, dreimal: "Verboten: UseContainerItem()" beim
-- Zauberoel - Gegenstaende, die einen Zauber wirken). Der Klick der
-- Vorlage laeuft durch Code, den dieses Addon beim Anlegen beruehrt hat;
-- fuer solche Gegenstaende sperrt das Spiel ihn. Der Rechtsklick (benutzen)
-- geht deshalb ueber einen geschuetzten Knopf des Spiels darueber (Art
-- "item", "Tasche Platz" - wie das Makro /use), Linksklick und Maus gehen
-- durch ihn hindurch an die Vorlage (ziehen, verlinken, Tooltip).
-- Kann der Client das Durchreichen nicht, bleibt alles wie bisher.
-- 6.61.6.0 AUSGEBAUT (Beta-Test: "ich moechte einfach nur meine Tasche im
-- Kampf oeffnen"): jeder geschuetzte Knopf in der Tasche macht sie zum
-- geschuetzten Rahmen, den das Spiel im Kampf weder zeigt noch verbirgt -
-- auch ausgehaengt blieb er verankert (6.61.5.0 half nicht). Vier Releases
-- Folgefehler fuer einen Rechtsklick auf Zauberoel. Der Rechtsklick ist
-- wieder der des Spiels; Zauberoel geht notfalls ueber die Taschen des
-- Spiels oder eine Aktionsleiste.
BG.SECURE_USE = false
function BG.SecureUse(btn)
    if not BG.SECURE_USE then return nil end
    if _G.InCombatLockdown and _G.InCombatLockdown() then return nil end
    local ok, sec = pcall(CreateFrame, "Button", nil, btn, "SecureActionButtonTemplate")
    if not (ok and sec) then return nil end
    if not (sec.SetPassThroughButtons and pcall(sec.SetPassThroughButtons, sec, "LeftButton")) then
        sec:Hide()
        return nil
    end
    if sec.SetPropagateMouseMotion then pcall(sec.SetPropagateMouseMotion, sec, true) end
    sec:SetAllPoints(btn)
    sec:SetFrameLevel((btn:GetFrameLevel() or 1) + 2)
    if sec.RegisterForClicks then sec:RegisterForClicks("RightButtonUp") end
    sec:SetAttribute("useOnKeyDown", false)
    sec:SetAttribute("type2", (not BG.busy) and "item" or nil)
    if BG.busy then sec:Hide() end
    return sec
end

-- 6.60.3.0 (Beta-Test: "Rechtsklick beim Haendler verkauft nicht, sondern
-- tauscht mit dem angelegten Gegenstand"): der geschuetzte Knopf wirkt wie
-- /use - beim Haendler, an der Bank, Post, Handel, Auktionshaus heisst
-- Rechtsklick aber verkaufen bzw. hineinlegen, und das macht nur die
-- Vorlage. Solange eines dieser Fenster offen ist, ruht der Knopf (kein
-- type2), der Klick geht wie frueher an die Vorlage.
BG.INTERACT = {
    MERCHANT_SHOW = true, BANKFRAME_OPENED = true, MAIL_SHOW = true, TRADE_SHOW = true,
    AUCTION_HOUSE_SHOW = true, GUILDBANKFRAME_OPENED = true,
    MERCHANT_CLOSED = false, BANKFRAME_CLOSED = false, MAIL_CLOSED = false, TRADE_CLOSED = false,
    AUCTION_HOUSE_CLOSED = false, GUILDBANKFRAME_CLOSED = false,
    PLAYER_INTERACTION_MANAGER_FRAME_SHOW = "check", PLAYER_INTERACTION_MANAGER_FRAME_HIDE = "check",
}
-- 6.60.4.0 (Beta-Test: "kann immer noch nicht mit Rechtsklick verkaufen"):
-- ein Knopf ohne type2 faengt den Rechtsklick trotzdem ab und tut nichts.
-- Er muss deshalb VERSTECKT werden, nicht nur leer. Und ob ein Fenster offen
-- ist, sagt das Fenster selbst - die alten Ereignisse kommen im neuen Client
-- nicht immer (PLAYER_INTERACTION_MANAGER_FRAME_SHOW).
BG.FRAMES = { "MerchantFrame", "BankFrame", "MailFrame", "TradeFrame", "AuctionHouseFrame", "GuildBankFrame" }
function BG.AnyOpen()
    for _, n in ipairs(BG.FRAMES) do
        local f = _G[n]
        if type(f) == "table" and f.IsShown and f:IsShown() then return true end
    end
    return false
end
BG.busy = false
function BG.SetUseMode(on)
    if _G.InCombatLockdown and _G.InCombatLockdown() then return false end
    for _, s in ipairs(slots) do
        if s.use then
            s.use:SetAttribute("type2", on and "item" or nil)
            s.use:SetShown(on and true or false)
        end
    end
    return true
end
local interactEv = CreateFrame("Frame")
for e in pairs(BG.INTERACT) do pcall(interactEv.RegisterEvent, interactEv, e) end
pcall(interactEv.RegisterEvent, interactEv, "PLAYER_REGEN_ENABLED")
function BG.Recheck(event)
    BG.busy = BG.INTERACT[event] == true or BG.AnyOpen()
    BG.SetUseMode(not BG.busy)
end
interactEv:SetScript("OnEvent", function(_, event)
    BG.Recheck(event)
    -- Fenster oeffnen/schliessen sich oft erst nach dem Ereignis: nachsehen.
    if _G.C_Timer and _G.C_Timer.After then
        _G.C_Timer.After(0.2, function() BG.Recheck(event) end)
    end
end)
BG.interactEv = interactEv

-- 6.61.5.0 (Fehlerbericht: "Blockiert: WeintCodexBags:Show()/Hide()" beim
-- Oeffnen der Tasche im Kampf): ein geschuetzter Knopf macht die ganze
-- Tasche zum geschuetzten Rahmen, und den darf im Kampf niemand zeigen
-- oder verbergen. Vor dem Kampf (PLAYER_REGEN_DISABLED, letzter erlaubter
-- Augenblick) haengen die Knoepfe deshalb aus der Tasche aus und danach
-- wieder ein. Im Kampf gilt der Rechtsklick der Vorlage wie frueher.
local park = CreateFrame("Frame", nil, UIParent)
park:Hide()
BG.park = park
function BG.slotsForTest() return slots end
function BG.Unhook()
    for _, s in ipairs(slots) do
        if s.use then s.use:Hide() s.use:SetParent(park) end
    end
end
function BG.Rehook()
    if _G.InCombatLockdown and _G.InCombatLockdown() then return false end
    for _, s in ipairs(slots) do
        local sec, btn = s.use, s.button
        -- Im Kampf angelegte Plaetze bekommen ihren Knopf jetzt.
        if not sec and btn and BG.SECURE_USE then
            sec = BG.SecureUse(btn)
            s.use, s._useBag, s._useSlot = sec, nil, nil
        end
        if sec and btn then
            sec:SetParent(btn)
            sec:ClearAllPoints()
            sec:SetAllPoints(btn)
            sec:SetFrameLevel((btn:GetFrameLevel() or 1) + 2)
        end
    end
    BG.SetUseMode(not BG.busy)
    return true
end
local combatEv = CreateFrame("Frame")
pcall(combatEv.RegisterEvent, combatEv, "PLAYER_REGEN_DISABLED")
pcall(combatEv.RegisterEvent, combatEv, "PLAYER_REGEN_ENABLED")
combatEv:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_REGEN_DISABLED" then BG.Unhook() else BG.Rehook() end
end)
BG.combatEv = combatEv

-- Platz des geschuetzten Knopfs setzen - nur ausserhalb des Kampfes.
function BG.ArmUse(s, bag, slot)
    local sec = s.use
    if not sec or (_G.InCombatLockdown and _G.InCombatLockdown()) then return false end
    if s._useBag == bag and s._useSlot == slot then return true end
    sec:SetAttribute("item", bag .. " " .. slot)
    s._useBag, s._useSlot = bag, slot
    return true
end

local function CreateSlot()
    local holder = CreateFrame("Frame", nil, grid)
    local ok, btn = pcall(CreateFrame, "ItemButton", nil, holder, "ContainerFrameItemButtonTemplate")
    if not ok or type(btn) ~= "table" then
        -- Aeltere Clients kennen den Objekttyp "ItemButton" nicht.
        ok, btn = pcall(CreateFrame, "Button", nil, holder, "ContainerFrameItemButtonTemplate")
    end
    if not ok or type(btn) ~= "table" then return nil end
    btn:SetAllPoints(holder)
    if btn.RegisterForClicks then btn:RegisterForClicks("LeftButtonUp", "RightButtonUp") end
    if btn.RegisterForDrag then btn:RegisterForDrag("LeftButton") end

    local d = {}
    d.bg = holder:CreateTexture(nil, "BACKGROUND")
    d.bg:SetAllPoints(holder)
    local s = C.surface1
    d.bg:SetColorTexture(s[1], s[2], s[3], 1)
    d.border = K.Border(holder, 1, 0, 0, 0, 1, "OVERLAY")
    local top = CreateFrame("Frame", nil, btn)
    top:SetAllPoints(btn)
    top:SetFrameLevel((btn:GetFrameLevel() or 1) + 3)
    top:EnableMouse(false)
    d.ilvl = K.NewText(top)
    d.ilvl:SetPoint("TOPLEFT", btn, "TOPLEFT", 2, -2)
    d.quality = K.Border(top, 1, 1, 1, 1, 1, "OVERLAY")
    d.quality:SetShown(false)
    -- Der Steinrahmen des Knopfs weg; das Symbol beschnitten und auf die
    -- volle Flaeche gezogen. Die Maske der Vorlage ist fuer 37 px gebaut;
    -- auf einem anders grossen Knopf blieb das Symbol in 6.0.0.3 im Spiel
    -- unsichtbar - EllesmereUI nimmt sie aus demselben Grund ab.
    local normal = btn.GetNormalTexture and btn:GetNormalTexture()
    if normal then normal:SetAlpha(0) end
    local icon = btn.icon or btn.Icon
    if type(icon) ~= "table" or not icon.SetTexture then icon = nil end
    if icon then
        if icon.SetTexCoord then icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) end
        icon:ClearAllPoints()
        icon:SetAllPoints(btn)
        local mask = btn.IconMask
        if type(mask) == "table" and icon.RemoveMaskTexture then
            pcall(icon.RemoveMaskTexture, icon, mask)
            if mask.Hide then mask:Hide() end
        end
    end
    if type(btn.IconBorder) == "table" then btn.IconBorder:SetAlpha(0) end
    for _, k in ipairs({ "NewItemTexture", "BattlepayItemTexture", "flash" }) do
        local r = btn[k]
        if type(r) == "table" and r.SetAlpha then r:SetAlpha(0) end
    end
    holder:Hide()
    return { holder = holder, button = btn, d = d, icon = icon, use = BG.SecureUse(btn) }
end

local function EnsurePool()
    if K.InCombat() then return end
    while #slots < POOL do
        local s = CreateSlot()
        if not s then break end
        slots[#slots + 1] = s
    end
end

local function ItemLevel(bag, slot, info)
    if not (info and info.hyperlink) then return nil end
    local equip
    if _G.C_Item and _G.C_Item.GetItemInventoryTypeByID and info.itemID then
        equip = _G.C_Item.GetItemInventoryTypeByID(info.itemID)
        -- 0 = kein Ausruestungsteil (Enum.InventoryType.IndexNonEquipType)
        if type(equip) ~= "number" or equip == 0 then return nil end
    else
        local loc = _G.GetItemInfo and select(9, _G.GetItemInfo(info.hyperlink))
        if type(loc) ~= "string" or loc == "" or loc == "INVTYPE_NON_EQUIP_IGNORE" then return nil end
    end
    local lvl
    if _G.C_Item and _G.C_Item.GetCurrentItemLevel and _G.ItemLocation and _G.ItemLocation.CreateFromBagAndSlot then
        local ok, v = pcall(_G.C_Item.GetCurrentItemLevel, _G.ItemLocation:CreateFromBagAndSlot(bag, slot))
        if ok then lvl = v end
    end
    if type(lvl) ~= "number" and _G.GetDetailedItemLevelInfo then
        lvl = _G.GetDetailedItemLevelInfo(info.hyperlink)
    end
    -- Keine Stufe gemeldet ist keine Stufe 0.
    if type(lvl) ~= "number" or lvl <= 1 then return nil end
    return lvl
end

-- /wcui taschen: welche Felder der Knoepfe sind "tainted"? (issecurevariable)
BG.WATCH_FIELDS = { "count", "hasItem", "bagID", "readable", "isBag", "icon", "Count", "itemLink", "BattlepayItemTexture" }
-- Letzte Sperren gegen WeintCodex (Ereignis und Funktion), fuer den Bericht.
BG.lockLog = {}
local blockEv = CreateFrame("Frame")
blockEv:RegisterEvent("ADDON_ACTION_FORBIDDEN")
blockEv:RegisterEvent("ADDON_ACTION_BLOCKED")
blockEv:SetScript("OnEvent", function(_, event, addon, func)
    if K.Plain(addon) ~= "WeintCodex" then return end
    local b = BG.lockLog
    b[#b + 1] = string.format("%s %s: %s", _G.date and _G.date("%H:%M:%S") or "", event, tostring(K.Plain(func)))
    while #b > 10 do table.remove(b, 1) end
end)

-- 6.103.0.0 (Fehlerbericht: BankFrame.currentBankPage, MailFrame.selectedTab
-- und .activeSubFrame "tainted (WeintCodex)" - Ursache unbekannt): ein
-- Waechter merkt sich den ERSTEN Moment, in dem eines dieser Felder
-- beschmutzt ist, samt den letzten Ereignissen davor. Nur lesen
-- (issecurevariable), nie schreiben; halbsekuendlich, ohne Tabelle je Takt.
BG.TAINT_WATCH = { { "MailFrame", "selectedTab" }, { "MailFrame", "activeSubFrame" },
                   { "BankFrame", "currentBankPage" }, { "MerchantFrame", "selectedTab" } }
BG.taintFirst, BG.recentEv = {}, {}
local watchEv = CreateFrame("Frame")
for _, e in ipairs({ "MAIL_SHOW", "MAIL_CLOSED", "BANKFRAME_OPENED", "BANKFRAME_CLOSED", "MERCHANT_SHOW",
                      "MERCHANT_CLOSED", "PLAYER_INTERACTION_MANAGER_FRAME_SHOW",
                      "PLAYER_INTERACTION_MANAGER_FRAME_HIDE", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED" }) do
    pcall(watchEv.RegisterEvent, watchEv, e)
end
local function Stamp() return _G.date and _G.date("%H:%M:%S") or "" end
function BG.TaintScan(why)
    local isv = _G.issecurevariable
    if type(isv) ~= "function" then return end
    for _, w in ipairs(BG.TAINT_WATCH) do
        local key = w[1] .. "." .. w[2]
        local t = _G[w[1]]
        if not BG.taintFirst[key] and type(t) == "table" then
            local ok, sec, who = pcall(isv, t, w[2])
            if ok and not sec then
                BG.taintFirst[key] = string.format("%s %s (%s) – vorher: %s", Stamp(), key, tostring(who),
                    table.concat(BG.recentEv, ", "))
            end
        end
    end
end
watchEv:SetScript("OnEvent", function(_, event, kind)
    local r = BG.recentEv
    r[#r + 1] = Stamp() .. " " .. event .. (type(K.Plain(kind)) == "number" and ("/" .. K.Plain(kind)) or "")
    while #r > 6 do table.remove(r, 1) end
    BG.TaintScan(event)
end)
local watchT = 0
watchEv:SetScript("OnUpdate", function(_, el)
    watchT = watchT + (el or 0)
    if watchT < 0.5 then return end
    watchT = 0
    BG.TaintScan("takt")
end)

local function TaintedKeys(t, label, out, limit)
    local isv = _G.issecurevariable
    local n = 0
    for k in pairs(t) do
        if type(k) == "string" then
            local ok, sec, who = pcall(isv, t, k)
            if ok and not sec then
                n = n + 1
                if n <= limit then out[#out + 1] = "   " .. label .. "." .. k .. "  (" .. tostring(who) .. ")" end
            end
        end
    end
    if n > limit then out[#out + 1] = "   … und " .. (n - limit) .. " weitere" end
    return n
end

-- Bericht (6.30.52.0, Wunsch: "/wcui taschen als Fenster zum Kopieren").
-- Sucht, was an den Taschenknoepfen und im Spiel von WeintCodex angefasst
-- (tainted) ist - genau das macht einen Klick des Spiels zu einem Klick
-- des Addons.
BG.CLICK_FRAMES = { "MerchantFrame", "BankFrame", "MailFrame", "TradeFrame", "AuctionHouseFrame",
                    "GuildBankFrame", "StackSplitFrame" }
BG.CLICK_GLOBALS = { "MerchantFrame_ResetRefundItem", "MerchantFrame_SetRefundItem", "ContainerFrame_GetExtendedPriceString",
                     "MERCHANT_ITEMS_PER_PAGE", "SpellCanTargetItem", "GetCursorInfo", "CursorHasItem", "ItemLocation" }
function BG.TaintReport()
    local out = { "WeintCodex " .. tostring(WeintCodex.Version) .. " · Taschen, Taint-Bericht" }
    local isv = _G.issecurevariable
    if type(isv) ~= "function" then out[#out + 1] = "issecurevariable fehlt." return out end
    -- 6.67.1.0 (Fehlerbericht einer Spielerin, abgeschnitten nach den
    -- Tooltipzeilen): ZUERST, was der Klick des Spiels liest
    -- (ContainerFrameItemButton_OnClick: Haendler, Bank, Post, Handel,
    -- Auktionshaus, Stapel teilen) - das ist der Verdacht, der Rest danach.
    out[#out + 1] = "Vom Klick gelesen, tainted:"
    local hits = 0
    for _, name in ipairs(BG.CLICK_FRAMES) do
        local t = _G[name]
        if type(t) == "table" then hits = hits + TaintedKeys(t, name, out, 8) end
    end
    for _, g in ipairs(BG.CLICK_GLOBALS) do
        local ok, sec, who = pcall(isv, g)
        if ok and not sec then hits = hits + 1 out[#out + 1] = "   " .. g .. "  (" .. tostring(who) .. ")" end
    end
    if hits == 0 then out[#out + 1] = "   nichts" end
    out[#out + 1] = "Erstmals tainted (Wächter seit dem Laden):"
    local any = false
    for _, w in ipairs(BG.TAINT_WATCH) do
        local l = BG.taintFirst[w[1] .. "." .. w[2]]
        if l then any = true out[#out + 1] = "   " .. l end
    end
    if not any then out[#out + 1] = "   nichts" end
    out[#out + 1] = "Sperren gegen WeintCodex (zuletzt):"
    if #BG.lockLog == 0 then out[#out + 1] = "   keine seit dem Laden" end
    for _, l in ipairs(BG.lockLog) do out[#out + 1] = "   " .. l end
    local s = slots[1]
    if not s then out[#out + 1] = "Noch keine Taschenknöpfe angelegt." return out end
    local btn = s.button
    out[#out + 1] = "Knopf: " .. tostring(btn.GetObjectType and btn:GetObjectType()) .. ", geschützt: "
        .. tostring(btn.IsProtected and btn:IsProtected())
    out[#out + 1] = "Felder am Knopf, tainted:"
    if TaintedKeys(btn, "Knopf", out, 40) == 0 then out[#out + 1] = "   keine" end
    out[#out + 1] = "Felder am Halter, tainted:"
    if TaintedKeys(s.holder, "Halter", out, 20) == 0 then out[#out + 1] = "   keine" end
    out[#out + 1] = "Globale Namen des Spiels, von WeintCodex angefasst:"
    local n = 0
    for k in pairs(_G) do
        -- Textzeilen der Tooltips (GameTooltipTextLeft7 ...) legt das Spiel
        -- erst an, wenn ein Addon eine Zeile mehr braucht - harmlos und
        -- lang; sie verdraengten das Wichtige aus dem Bericht.
        if type(k) == "string" and not k:find("^WeintCodex") and not k:find("^SLASH_WEINT")
           and not k:find("Text[LR][ei][fg]h?t?%d+$") and not k:find("^LibDBIcon") then
            local ok, sec, who = pcall(isv, k)
            if ok and not sec and who == "WeintCodex" then
                n = n + 1
                if n <= 80 then out[#out + 1] = "   " .. k end
            end
        end
    end
    if n == 0 then out[#out + 1] = "   keine" elseif n > 80 then out[#out + 1] = "   … und " .. (n - 80) .. " weitere" end
    return out
end

local function PaintSlot(s, bag, slot)
    local btn, d = s.button, s.d
    s.holder:SetID(bag)
    btn:SetID(slot)
    BG.ArmUse(s, bag, slot)
    local info = Info(bag, slot)

    -- 6.30.51.0 (Beta-Test: "Fackel des Nachtwaechters" aus der Tasche
    -- benutzt -> "WeintCodex wurde geblockt", ADDON_ACTION_FORBIDDEN): die
    -- Helfer der Vorlage (SetItemButtonTexture/Count/Desaturated) schreiben
    -- FELDER in den Knopf (count, hasItem ...). Aus Addon-Code geschrieben
    -- sind diese Felder "tainted"; der Klick des Spiels liest sie und laeuft
    -- dann selbst tainted - Gegenstaende, die einen Zauber wirken, sperrt
    -- das Spiel dann. Deshalb nur noch Bilder und Texte setzen, nie Felder.
    local tex = info and info.iconFileID or nil
    if s.icon then
        s.icon:SetTexture(tex)
        s.icon:SetShown(tex ~= nil)
    end
    local count = info and info.stackCount or 0
    local ct = btn.Count or _G[(btn:GetName() or "") .. "Count"]
    if type(ct) == "table" and ct.SetText then
        ct:SetText(count > 1 and tostring(count) or "")
        ct:SetShown(count > 1)
    end

    local junk = info and info.quality == 0 and Opt("dimJunk")
    if s.icon and s.icon.SetDesaturated then
        s.icon:SetDesaturated(info and (info.isLocked or junk) and true or false)
    end
    btn:SetAlpha(info and info.isFiltered and 0.2 or 1)

    -- Abklingzeit (Traenke, Steine): gelesen, nicht gerechnet.
    local cdFrame = btn.Cooldown or _G[(btn:GetName() or "") .. "Cooldown"]
    local cc = _G.C_Container
    if type(cdFrame) == "table" and info and cc and cc.GetContainerItemCooldown and _G.CooldownFrame_Set then
        local start, duration, enable = cc.GetContainerItemCooldown(bag, slot)
        _G.CooldownFrame_Set(cdFrame, start, duration, enable)
    elseif type(cdFrame) == "table" and cdFrame.Clear then
        cdFrame:Clear()
    end

    local q = info and info.quality
    if Opt("qualityBorder") and type(q) == "number" and q >= 2 and _G.C_Item and _G.C_Item.GetItemQualityColor then
        local r, g, b = _G.C_Item.GetItemQualityColor(q)
        if type(r) == "number" then
            d.quality:SetColor(r, g, b, 1)
            d.quality:SetShown(true)
        else
            d.quality:SetShown(false)
        end
    else
        d.quality:SetShown(false)
    end

    local lvl = Opt("itemLevel") and info and ItemLevel(bag, slot, info)
    d.ilvl:SetText(lvl and tostring(lvl) or "")
    if lvl and type(q) == "number" and _G.C_Item and _G.C_Item.GetItemQualityColor then
        local r, g, b = _G.C_Item.GetItemQualityColor(q)
        if type(r) == "number" then d.ilvl:SetTextColor(r, g, b, 1) end
    end
    s.holder:Show()
    btn:Show()
    return info ~= nil
end

--------------------------------------------------
-- Fenster
--------------------------------------------------

--------------------------------------------------
-- Kategorien (6.123.0.0)
--------------------------------------------------

-- Was beim letzten Schliessen in den Taschen lag: [bag*1000+slot] = itemID.
-- Was danach dazukommt, ist "Neu" - bis das Fenster wieder zugeht.
BG.seen = nil

function BG.Snapshot()
    local t = {}
    for _, bag in ipairs(BagIDs()) do
        for slot = 1, NumSlots(bag) do
            local info = Info(bag, slot)
            local id = info and K.Plain(info.itemID)
            if type(id) == "number" then t[bag * 1000 + slot] = id end
        end
    end
    BG.seen = t
end

local function ItemClass(id)
    local ci = _G.C_Item
    local f = (ci and ci.GetItemInfoInstant) or _G.GetItemInfoInstant
    if not f then return nil end
    local ok, _, _, _, _, _, classID = pcall(f, id)
    classID = ok and K.Plain(classID) or nil
    return type(classID) == "number" and classID or nil
end

local function QuestItem(bag, slot)
    local cc = _G.C_Container
    if not (cc and cc.GetContainerItemQuestInfo) then return false end
    local ok, q = pcall(cc.GetContainerItemQuestInfo, bag, slot)
    return ok and type(q) == "table" and (K.Plain(q.isQuestItem) == true or type(K.Plain(q.questID)) == "number")
end

-- Kategorie eines Platzes (Schluessel aus BG.CATEGORIES).
function BG.CategoryOf(bag, slot, info)
    local function On(k) return Opt("cat_" .. k) ~= false end
    local id = info and K.Plain(info.itemID)
    if type(id) ~= "number" then return On("empty") and "empty" or nil end
    if On("new") and BG.seen and BG.seen[bag * 1000 + slot] ~= id then return "new" end
    local a = Opt("assign")
    local mine = type(a) == "table" and a[id]
    if mine then
        if mine:sub(1, 2) == "c:" then
            for _, n in ipairs(BG.CustomList()) do if "c:" .. n == mine then return mine end end
        elseif On(mine) then
            return mine
        end
    end
    return BG.CategoryOfItem(id, K.Plain(info.quality), QuestItem(bag, slot), true)
end

-- Kategorie nach Gegenstand allein (auch fuer die Gildenbank).
function BG.CategoryOfItem(id, q, quest, assigned)
    local function On(k) return Opt("cat_" .. k) ~= false end
    if not assigned then
        local a = Opt("assign")
        local mine = type(a) == "table" and a[id]
        if mine then
            if mine:sub(1, 2) == "c:" then
                for _, n in ipairs(BG.CustomList()) do if "c:" .. n == mine then return mine end end
            elseif On(mine) then
                return mine
            end
        end
    end
    if On("junk") and q == 0 then return "junk" end
    if On("quest") and quest then return "quest" end
    local class = ItemClass(id)
    for _, c in ipairs(BG.CATEGORIES) do
        if c.classes and class and c.classes[class] and On(c.key) then return c.key end
    end
    return "misc"
end

local catHeads = {}
BG.catHeads = catHeads

function BG.CustomList()
    local t = Opt("customCats")
    return type(t) == "table" and t or {}
end

-- Alle Kategorien in der Reihenfolge des Spielers (catOrder); ohne Wahl:
-- Neu, die eigenen, dann die eingebauten.
function BG.AllCategories()
    local base = { BG.CATEGORIES[1] }
    for _, name in ipairs(BG.CustomList()) do
        base[#base + 1] = { key = "c:" .. name, label = name, custom = true }
    end
    for i = 2, #BG.CATEGORIES do base[#base + 1] = BG.CATEGORIES[i] end
    local byKey = {}
    for _, c in ipairs(base) do byKey[c.key] = c end
    local out, used = {}, {}
    local order = Opt("catOrder")
    for _, k in ipairs(type(order) == "table" and order or {}) do
        if byKey[k] and not used[k] then out[#out + 1] = byKey[k] used[k] = true end
    end
    for _, c in ipairs(base) do
        if not used[c.key] then out[#out + 1] = c end
    end
    return out
end

-- Eine Kategorie um einen Platz verschieben (-1 hoch, +1 runter).
function BG.MoveCategory(key, dir)
    local list = BG.AllCategories()
    local keys = {}
    for i, c in ipairs(list) do keys[i] = c.key end
    for i, k in ipairs(keys) do
        if k == key then
            local j = i + dir
            if j < 1 or j > #keys then return false end
            keys[i], keys[j] = keys[j], keys[i]
            K.Set(KEY, "catOrder", keys)
            if BG.Refresh then BG.Refresh() end
            return true
        end
    end
    return false
end

function BG.AddCustom(name)
    name = type(name) == "string" and name:gsub("^%s+", ""):gsub("%s+$", "") or ""
    if name == "" then return false, "Bitte einen Namen eingeben." end
    local list = {}
    for _, n in ipairs(BG.CustomList()) do
        if n == name then return false, "„" .. name .. "“ gibt es schon." end
        list[#list + 1] = n
    end
    list[#list + 1] = name
    K.Set(KEY, "customCats", list)
    return true
end

function BG.RemoveCustom(name)
    local list = {}
    for _, n in ipairs(BG.CustomList()) do if n ~= name then list[#list + 1] = n end end
    K.Set(KEY, "customCats", list)
    local a, keep = Opt("assign"), {}
    for id, k in pairs(type(a) == "table" and a or {}) do if k ~= "c:" .. name then keep[id] = k end end
    K.Set(KEY, "assign", keep)
end

function BG.Assign(itemID, key)
    if type(itemID) ~= "number" then return false end
    local a, out = Opt("assign"), {}
    for id, k in pairs(type(a) == "table" and a or {}) do out[id] = k end
    out[itemID] = key
    K.Set(KEY, "assign", out)
    if BG.Refresh then BG.Refresh() end
    return true
end

-- Gegenstand vom Mauszeiger auf eine Ueberschrift.
function BG.DropOn(head)
    local GetCursorInfo = _G.GetCursorInfo
    if not (GetCursorInfo and head and head.cat) then return false end
    local kind, id = GetCursorInfo()
    if kind ~= "item" or type(K.Plain(id)) ~= "number" then return false end
    if head.cat.key == "new" or head.cat.key == "empty" then return false end
    if _G.ClearCursor then _G.ClearCursor() end
    return BG.Assign(K.Plain(id), head.cat.key)
end

-- 6.123.2.0 (Beta-Test mit Video, wie in Baganator: "Rechtsklick zum
-- Transferieren"): ist die Bank offen, legt ein Rechtsklick auf die
-- Ueberschrift alles aus der Kategorie in die Bank - ueber das Benutzen
-- des Spiels (UseContainerItem bei offener Bank), im Klick selbst, nie im
-- Kampf. Gegenstaende, die einen Zauber wirken, laesst das Spiel so
-- nicht zu - die bleiben, wo sie sind.
BG.bankOpen = false

-- 6.126.1.0 (Beta-Test: "ich muss mehrmals rechtsklicken, manchmal geht's
-- gar nicht"): alles auf einmal geschickt, sperrt das Spiel jeden Platz,
-- solange es ihn bewegt, und verwirft die Bewegungen dazwischen still.
-- Jetzt eine Warteschlange: ein Gegenstand je Schritt, gesperrte Plaetze
-- werden spaeter noch einmal versucht. Bricht im Kampf und bei
-- geschlossener Bank ab.
BG.STEP = 0.12
BG.RETRIES = 25
local queue, qTicker = {}, nil
BG.queue = queue

local function Movable(e)
    local info = Info(e.bag, e.slot)
    local id = info and K.Plain(info.itemID)
    if type(id) ~= "number" then return "gone" end
    if e.id and id ~= e.id then return "gone" end
    if K.Plain(info.isLocked) then return "locked" end
    local ci = _G.C_Item
    local spell = ci and ci.GetItemSpell and select(2, pcall(ci.GetItemSpell, id))
    if spell then return "gone" end   -- wuerde benutzt statt bewegt
    return "ok"
end

function BG.Step()
    local cc = _G.C_Container
    if K.InCombat() or not BG.bankOpen or not (cc and cc.UseContainerItem) then
        for i = #queue, 1, -1 do queue[i] = nil end
    end
    local e = queue[1]
    if not e then
        if qTicker then if qTicker.Cancel then qTicker:Cancel() end qTicker = nil end
        return false
    end
    local st = Movable(e)
    if st == "ok" then
        table.remove(queue, 1)
        pcall(cc.UseContainerItem, e.bag, e.slot)
    elseif st == "locked" then
        e.tries = (e.tries or 0) + 1
        table.remove(queue, 1)
        if e.tries < BG.RETRIES then queue[#queue + 1] = e end
    else
        table.remove(queue, 1)
    end
    return true
end

-- Gibt die Zahl der eingereihten Gegenstaende zurueck.
function BG.Transfer(items)
    if K.InCombat() or not BG.bankOpen then return 0 end
    local n = 0
    for _, e in ipairs(items or {}) do
        if e.bag and e.slot and e.cat ~= "empty" then
            local info = Info(e.bag, e.slot)
            local id = info and K.Plain(info.itemID)
            if type(id) == "number" then
                queue[#queue + 1] = { bag = e.bag, slot = e.slot, id = id }
                n = n + 1
            end
        end
    end
    if n > 0 and not qTicker then
        BG.Step()
        if _G.C_Timer and _G.C_Timer.NewTicker and #queue > 0 then qTicker = _G.C_Timer.NewTicker(BG.STEP, BG.Step) end
    end
    return n
end

function BG.NewCatHead()
    local b = CreateFrame("Button", nil, grid)
    b.text = K.NewText(b)
    b.text:SetFont(F.sans, 11, "")
    b.text:SetPoint("LEFT", b, "LEFT", 0, 0)
    if b.RegisterForClicks then b:RegisterForClicks("LeftButtonUp", "RightButtonUp") end
    b:SetScript("OnClick", function(self, button)
        if BG.DropOn(self) then return end
        if button == "RightButton" then BG.Transfer(self.items) end
    end)
    b:SetScript("OnReceiveDrag", function(self) BG.DropOn(self) end)
    b:SetScript("OnEnter", function(self)
        if self.cat.key == "empty" or self.cat.key == "new" then return end
        local tt = _G.GameTooltip
        tt:SetOwner(self, "ANCHOR_TOP")
        tt:SetText(self.cat.label, 1, 1, 1)
        tt:AddLine("Gegenstand hierher ziehen: gehört ab jetzt in diese Kategorie", 0.8, 0.8, 0.8, true)
        if BG.bankOpen then tt:AddLine("Rechtsklick: alles in die Bank", 0.4, 1, 0.4) end
        tt:Show()
    end)
    b:SetScript("OnLeave", function() if _G.GameTooltip then _G.GameTooltip:Hide() end end)
    return b
end
-- Bloecke nebeneinander, solange sie in die Breite passen (wie Baganator).
function BG.LayoutCategories(list, size, sp, cols)
    local cell = size + sp
    local byCat = {}
    for _, e in ipairs(list) do
        local k = e.cat
        if k then
            byCat[k] = byCat[k] or {}
            table.insert(byCat[k], e)
        else
            e.s.holder:Hide()
        end
    end
    local x, y, rowH = 0, 0, 0
    local maxW = cols
    local hi = 0
    BG.catBlocks = {}
    for _, c in ipairs(BG.AllCategories()) do
        local items = byCat[c.key] or (c.custom and {}) or nil
        if items and (#items > 0 or c.custom) then
            local w = math.max(math.min(#items, cols), c.custom and math.min(4, cols) or 1)
            local rows = math.max(1, math.ceil(#items / w))
            if x > 0 and x + w > maxW then
                x, y, rowH = 0, y + rowH, 0
            end
            hi = hi + 1
            local hd = catHeads[hi]
            if not hd then
                hd = BG.NewCatHead()
                catHeads[hi] = hd
            end
            local px, py = x * cell, y
            hd:ClearAllPoints()
            hd:SetPoint("TOPLEFT", grid, "TOPLEFT", px, -py)
            hd:SetSize(math.max(w * cell - sp, 40), BG.HEAD_H)
            hd.cat, hd.items = c, items
            hd.text:SetText(c.label .. (c.key == "empty" and ("  " .. #items) or "")
                .. ((c.custom and #items == 0) and "  ·  hierher ziehen" or ""))
            hd.text:SetTextColor(unpack(c.key == "new" and C.accent or C.textMuted))
            hd:Show()
            for i, e in ipairs(items) do
                local col, row = (i - 1) % w, math.floor((i - 1) / w)
                e.s.holder:ClearAllPoints()
                e.s.holder:SetPoint("TOPLEFT", grid, "TOPLEFT", px + col * cell, -(py + BG.HEAD_H + row * cell))
                e.s.holder:Show()
            end
            BG.catBlocks[#BG.catBlocks + 1] = { key = c.key, n = #items }
            rowH = math.max(rowH, BG.HEAD_H + rows * cell - sp + BG.CAT_GAP)
            x = x + w + 1   -- eine Spalte Luft zum Nachbarn
            if x >= maxW then x, y, rowH = 0, y + rowH, 0 end
        end
    end
    for i = hi + 1, #catHeads do catHeads[i]:Hide() end
    return math.max(size, y + rowH - BG.CAT_GAP)
end

function BG.Refresh()
    if not win or not win:IsShown() then return end
    if Opt("categories") then return BG.RefreshCategories() end
    for _, hd in ipairs(catHeads) do hd:Hide() end
    EnsurePool()
    local size, sp, cols = Opt("slotSize"), Opt("spacing"), Opt("columns")
    local split = Opt("split") and true or false
    local n = 0
    local missing = 0
    local filled = 0
    local y = 0          -- Oberkante des naechsten Blocks (einzeln)
    local h = 0
    BG.blocks = {}
    for _, bag in ipairs(BagIDs()) do
        local count = NumSlots(bag)
        local first = n
        local bagFilled = 0
        if split and count > 0 then y = y + BG.HEAD_H end
        for slot = 1, count do
            n = n + 1
            local s = slots[n]
            if s then
                s.holder:SetSize(size, size)
                s.holder:ClearAllPoints()
                local i = split and (n - first - 1) or (n - 1)
                local col = i % cols
                local row = math.floor(i / cols)
                s.holder:SetPoint("TOPLEFT", grid, "TOPLEFT", col * (size + sp), -(split and y or 0) - row * (size + sp))
                K.SetFont(s.d.ilvl, math.max(8, math.floor(size * 0.3)))
                if PaintSlot(s, bag, slot) then filled = filled + 1 bagFilled = bagFilled + 1 end
            else
                missing = missing + 1
            end
        end
        if split and count > 0 then
            local rows = math.ceil(count / cols)
            local hd = heads[#BG.blocks + 1]
            if not hd then
                hd = K.NewText(grid)
                hd:SetFont(F.sans, 11, "")
                heads[#BG.blocks + 1] = hd
            end
            local free = count - bagFilled
            BG.blocks[#BG.blocks + 1] = { bag = bag, slots = count, free = free }
            hd:ClearAllPoints()
            hd:SetPoint("BOTTOMLEFT", grid, "TOPLEFT", 0, -y + 3)
            hd:SetText(BG.BagLabel(bag) .. "  ·  " .. free .. " frei von " .. count)
            hd:SetTextColor(unpack(free == 0 and C.warningBright or C.textMuted))
            hd:Show()
            y = y + rows * (size + sp) - sp + BG.BAG_GAP
        end
    end
    for i = n + 1, #slots do slots[i].holder:Hide() end
    for i = (split and #BG.blocks or 0) + 1, #heads do heads[i]:Hide() end
    used = n

    if split then
        h = math.max(size, y - BG.BAG_GAP)
    else
        h = math.max(1, math.ceil(n / cols)) * (size + sp) - sp
    end
    grid:SetSize(cols * (size + sp) - sp, h)
    win:SetSize(cols * (size + sp) - sp + 24, h + 92)

    local money = _G.GetMoney and _G.GetMoney() or 0
    if _G.GetMoneyString then gold:SetText(_G.GetMoneyString(money, true))
    elseif _G.GetCoinTextureString then gold:SetText(_G.GetCoinTextureString(money)) end

    if missing > 0 then
        note:SetText(missing .. " Plätze erscheinen nach dem Kampf.")
        note:SetTextColor(unpack(C.warningBright))
    else
        -- Belegt laut Client. Steht hier eine Zahl, aber die Plaetze sind
        -- leer, liefert das Spiel die Gegenstaende und nur das Zeichnen
        -- scheitert - fuer eine Fehlermeldung aus dem Spiel Gold wert.
        note:SetFormattedText("%d von %d Plätzen belegt", filled, n)
        note:SetTextColor(unpack(C.textMuted))
    end
    note:Show()
    BG._filled = filled
end

local function Footer(filled, n, missing)
    local money = _G.GetMoney and _G.GetMoney() or 0
    if _G.GetMoneyString then gold:SetText(_G.GetMoneyString(money, true))
    elseif _G.GetCoinTextureString then gold:SetText(_G.GetCoinTextureString(money)) end
    if missing > 0 then
        note:SetText(missing .. " Plätze erscheinen nach dem Kampf.")
        note:SetTextColor(unpack(C.warningBright))
    else
        note:SetFormattedText("%d von %d Plätzen belegt", filled, n)
        note:SetTextColor(unpack(C.textMuted))
    end
    note:Show()
    BG._filled = filled
end

function BG.RefreshCategories()
    EnsurePool()
    if not BG.seen then BG.Snapshot() end
    local size, sp, cols = Opt("slotSize"), Opt("spacing"), Opt("columns")
    local n, missing, filled = 0, 0, 0
    local list = {}
    for _, bag in ipairs(BagIDs()) do
        for slot = 1, NumSlots(bag) do
            n = n + 1
            local s = slots[n]
            if s then
                s.holder:SetSize(size, size)
                K.SetFont(s.d.ilvl, math.max(8, math.floor(size * 0.3)))
                if PaintSlot(s, bag, slot) then filled = filled + 1 end
                list[#list + 1] = { s = s, bag = bag, slot = slot, cat = BG.CategoryOf(bag, slot, Info(bag, slot)) }
            else
                missing = missing + 1
            end
        end
    end
    for i = n + 1, #slots do slots[i].holder:Hide() end
    for _, hd in ipairs(heads) do hd:Hide() end
    used = n
    local h = BG.LayoutCategories(list, size, sp, cols)
    grid:SetSize(cols * (size + sp) - sp, h)
    win:SetSize(cols * (size + sp) - sp + 24, h + 92)
    Footer(filled, n, missing)
end

-- Name einer Tasche fuer die Kopfzeile: vom Client, sonst "Tasche n".
function BG.BagLabel(bag)
    if bag == (_G.BACKPACK_CONTAINER or 0) then return "Rucksack" end
    local cc = _G.C_Container
    local f = (cc and cc.GetBagName) or _G.GetBagName
    if f then
        local ok, name = pcall(f, bag)
        name = ok and K.Plain(name)
        if type(name) == "string" and name ~= "" then return name end
    end
    return "Tasche " .. tostring(bag)
end

local function Build()
    win = CreateFrame("Frame", "WeintCodexBags", UIParent)
    win:SetSize(400, 300)
    win:SetFrameStrata("HIGH")
    win:SetToplevel(true)
    win:SetClampedToScreen(true)
    win:EnableMouse(true)
    win:Hide()
    local bg = win:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(win)
    -- 6.122.3.0 (Beta-Test: "Taschen auch Holzoptik, aber nicht so krass"):
    -- Holz gedaempft (shade), Rand wie das Aussehen.
    local edge = K.Border(win, 1, C.border[1], C.border[2], C.border[3], 1, "BORDER")
    K.LookFill(bg, C.bgDark[4] or 1, edge, { C.border[1], C.border[2], C.border[3], 1 }, 0.55)
    K.Glow(win, { spread = 10, shadow = true })
    if type(_G.UISpecialFrames) == "table" then table.insert(_G.UISpecialFrames, "WeintCodexBags") end

    local title = K.NewText(win)
    title:SetFont(F.display, 16, "")
    title:SetTextColor(unpack(C.textBright))
    title:SetPoint("TOPLEFT", win, "TOPLEFT", 12, -12)
    title:SetText("Taschen")

    local close = CreateFrame("Button", nil, win)
    close:SetSize(24, 22)
    close:SetPoint("TOPRIGHT", win, "TOPRIGHT", -6, -8)
    local x = K.NewText(close)
    x:SetFont(F.sans, 14, "")
    x:SetPoint("CENTER", close, "CENTER", 0, 0)
    x:SetTextColor(unpack(C.textMuted))
    x:SetText("\195\151")
    close:SetScript("OnClick", function() win:Hide() end)

    local sort = WeintCodex.CreateButton(win, {
        text = "Sortieren", kind = "ghost", height = 22, size = 11, backdrop = "bgDark",
        tooltip = "Sortiert alle Taschen, wie es das Spiel selbst tut.",
        onClick = function()
            local cc = _G.C_Container
            if cc and cc.SortBags then cc.SortBags() elseif _G.SortBags then _G.SortBags() end
        end,
    })
    sort:SetPoint("RIGHT", close, "LEFT", -6, 0)

    search = CreateFrame("EditBox", nil, win)
    search:SetSize(160, 22)
    search:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    search:SetAutoFocus(false)
    search:SetFont(F.sans, 12, "")
    search:SetTextInsets(6, 6, 0, 0)
    local sbg = search:CreateTexture(nil, "BACKGROUND")
    sbg:SetAllPoints(search)
    sbg:SetColorTexture(unpack(C.surface1))
    search:SetScript("OnTextChanged", function(self)
        local cc = _G.C_Container
        if cc and cc.SetItemSearch then cc.SetItemSearch(self:GetText() or "") end
    end)
    search:SetScript("OnEscapePressed", function(self) self:SetText("") self:ClearFocus() end)

    gold = K.NewText(win)
    gold:SetFont(F.monoMedium, 11, "")
    gold:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", -12, 10)
    gold:SetTextColor(unpack(C.textNormal))

    note = K.NewText(win)
    note:SetFont(F.sans, 10, "")
    note:SetPoint("BOTTOMLEFT", win, "BOTTOMLEFT", 12, 10)
    note:SetTextColor(unpack(C.warningBright))
    note:Hide()

    grid = CreateFrame("Frame", nil, win)
    grid:SetPoint("TOPLEFT", win, "TOPLEFT", 12, -68)
    grid:SetSize(100, 100)

    win:SetScript("OnShow", function() BG.Refresh() end)
    win:SetScript("OnHide", function()
        -- Was jetzt drin ist, ist beim naechsten Oeffnen nicht mehr "Neu".
        BG.Snapshot()
        local cc = _G.C_Container
        if search and search:GetText() ~= "" then
            search:SetText("")
            if cc and cc.SetItemSearch then cc.SetItemSearch("") end
        end
    end)
    win.WCShowForUnlock = function(self, on) if on then self:Show() end end
    K.RegisterMover(win, "bags", "Taschen", K.Layout("bags"))
    -- Frei ziehen ohne Gestaltungsmodus (6.29.21.0, Spielerbericht): die
    -- Flaeche des Fensters (nicht die Faecher - die ziehen Gegenstaende)
    -- mit links ziehen; der Platz wird wie im Gestaltungsmodus gespeichert.
    win:SetMovable(true)
    win:RegisterForDrag("LeftButton")
    win:SetScript("OnDragStart", function(self)
        if K.IsUnlocked() then return end
        self:StartMoving()
    end)
    win:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        BG.SavePlace()
    end)
end

-- Den Platz nach dem Ziehen speichern (Profil, wie der Gestaltungsmodus).
function BG.SavePlace()
    if not win then return false end
    local point, _, relPoint, x, y = win:GetPoint(1)
    local ui = K.Profile()
    if not (point and ui) then return false end
    ui.positions.bags = { point = point, relPoint = relPoint or point,
        x = math.floor((x or 0) + 0.5), y = math.floor((y or 0) + 0.5) }
    K.ApplyPosition("bags")
    return true
end

function BG.Toggle()
    if not win then return end
    if win:IsShown() then win:Hide() else win:Show() end
end
function BG.Open() if win then win:Show() end end
function BG.Close() if win then win:Hide() end end
function BG.UsedSlots() return used end

--------------------------------------------------
-- Modul
--------------------------------------------------

local function Enable()
    Build()
    win:SetScale((Opt("scale") or 100) / 100)
    K.AfterCombat(EnsurePool)

    -- Die Taschen des Spiels verstecken (Ereignisse behalten: andere
    -- Teile des Spiels fragen sie nach ihrem Zustand).
    K.HideBlizzard("ContainerFrameCombinedBags", true)
    for i = 1, (_G.NUM_CONTAINER_FRAMES or 13) do
        K.HideBlizzard("ContainerFrame" .. i, true)
    end

    -- OEFFNEN SPIEGELT DIE TASCHEN DES SPIELS. Deren Fenster gehen weiter
    -- auf und zu (nur unsichtbar, im versteckten Elternrahmen) - dieses
    -- folgt ihnen. Die Funktionen selbst (ToggleAllBags & Co.) mit Haken zu
    -- versehen geht schief: sie rufen sich gegenseitig auf, und ein
    -- "Umschalten" nach einem inneren "Oeffnen" machte die Tasche sofort
    -- wieder zu.
    local watched = {}
    local function AnyBlizzardOpen()
        for _, f in ipairs(watched) do
            if f:IsShown() then return true end
        end
        return false
    end
    -- An die METHODEN Show/Hide/SetShown, nicht an OnShow/OnHide: die
    -- Rahmen des Spiels stehen im versteckten Elternrahmen, und dort feuert
    -- OnShow nie - sie werden ja nie sichtbar. Show() wird trotzdem
    -- aufgerufen, und IsShown() sagt, was das Spiel meint.
    local function Mirror()
        if AnyBlizzardOpen() then BG.Open() else BG.Close() end
    end
    local function Watch(f)
        if type(f) ~= "table" or not _G.hooksecurefunc then return end
        watched[#watched + 1] = f
        for _, m in ipairs({ "Show", "Hide", "SetShown" }) do
            if type(f[m]) == "function" then _G.hooksecurefunc(f, m, Mirror) end
        end
    end
    Watch(_G.ContainerFrameCombinedBags)
    for i = 1, (_G.NUM_CONTAINER_FRAMES or 13) do Watch(_G["ContainerFrame" .. i]) end

    -- Schliesst man dieses Fenster (Kreuz, Esc), gehen auch die des Spiels
    -- zu - sonst oeffnete die Taschentaste beim naechsten Mal nichts, weil
    -- das Spiel sie noch fuer offen haelt.
    win:HookScript("OnHide", function()
        if AnyBlizzardOpen() and _G.CloseAllBags then _G.CloseAllBags() end
    end)

    local ev = CreateFrame("Frame")
    for _, e in ipairs({ "BAG_UPDATE_DELAYED", "ITEM_LOCK_CHANGED", "BAG_UPDATE_COOLDOWN",
        "PLAYER_MONEY", "INVENTORY_SEARCH_UPDATE", "PLAYER_REGEN_ENABLED",
        "BANKFRAME_OPENED", "BANKFRAME_CLOSED" }) do
        pcall(ev.RegisterEvent, ev, e)
    end
    ev:SetScript("OnEvent", K.Measured("Taschen", function(_, event)
        if event == "PLAYER_REGEN_ENABLED" then EnsurePool() end
        if event == "BANKFRAME_OPENED" then BG.bankOpen = true
        elseif event == "BANKFRAME_CLOSED" then BG.bankOpen = false end
        BG.Refresh()
    end))
end

local function px(v) return string.format("%d px", v) end

K.Register({
    key = KEY, group = "ui", order = 50,
    title = "Taschen",
    description = "Alle Taschen in einem Fenster: Suche, Sortieren, Gold, Gegenstandsstufe und Qualitätsrand. Benutzen und Verkaufen erledigt weiter das Spiel.",
    defaults = defaults,
    Enable = Enable,
    OnSetting = function()
        if win then
            win:SetScale((Opt("scale") or 100) / 100)
            BG.Refresh()
        end
    end,
    pages = {
        { key = "allgemein", label = "Allgemein", build = function(B)
            B:Section("Raster")
            B:Row({ type = "slider", label = "Spalten", key = "columns", min = 6, max = 24, step = 1,
                    format = function(v) return tostring(v) end },
                  { type = "slider", label = "Platzgröße", key = "slotSize", min = 24, max = 52, step = 1, format = px })
            B:Row({ type = "slider", label = "Abstand", key = "spacing", min = 0, max = 10, step = 1, format = px },
                  { type = "slider", label = "Fenstergröße", key = "scale", min = 60, max = 150, step = 5,
                    format = function(v) return string.format("%d %%", v) end })
            B:Row({ type = "toggle", label = "Nach Kategorien", key = "categories",
                    description = "Gegenstände nach Art gruppiert (Quest, Ausrüstung, Verbrauchbar …) statt nach Tasche. Neu Geplündertes steht oben unter „Neu“, bis du die Taschen schließt." },
                  { type = "empty" })
            B:Row({ type = "toggle", label = "Taschen einzeln", key = "split",
                    disabled = function() return Opt("categories") end,
                    description = "Jede Tasche ein eigener Block mit Namen und „frei von Plätze“ – Köcher, Munitions- und Seelentaschen auf einen Blick." },
                  { type = "empty" })
            B:Section("Anzeigen")
            B:Row({ type = "toggle", label = "Gegenstandsstufe auf Ausrüstung", key = "itemLevel",
                    description = "Nennt das Spiel keine Stufe, bleibt das Feld leer – nie 0." },
                  { type = "toggle", label = "Rand in Qualitätsfarbe", key = "qualityBorder" })
            B:Row({ type = "toggle", label = "Graue Gegenstände abdunkeln", key = "dimJunk" },
                  { type = "empty" })
            B:Note("Die Bank bleibt die des Spiels. Öffnen mit der Taschentaste (B) oder einem Klick auf den Rucksack.")
        end },
        -- 6.125.0.0: Kategorien auf eigener Seite (eigene, Reihenfolge, Gildenbank).
        { key = "kategorien", label = "Kategorien", build = function(B)
            B:Section("Eigene Kategorien", "Anlegen, dann im Taschenfenster einen Gegenstand auf ihre Überschrift ziehen – er bleibt dort. Das geht auch mit den eingebauten Kategorien.")
            local catDraft = ""
            B:Row({ type = "input", label = "Name der Kategorie",
                    get = function() return catDraft end, set = function(v) catDraft = v or "" end,
                    disabled = function() return not Opt("categories") end },
                  { type = "button", label = " ", text = "Kategorie hinzufügen",
                    disabled = function() return not Opt("categories") end,
                    onClick = function()
                        local ok, why = BG.AddCustom(catDraft)
                        if ok then catDraft = "" BG.Refresh() if WeintCodex.UIOptions.Rebuild then WeintCodex.UIOptions.Rebuild() end
                        elseif why then print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " " .. why) end
                    end })
            for _, name in ipairs(BG.CustomList()) do
                B:Row({ type = "button", label = name, text = "Löschen",
                        tooltip = "Die Kategorie und ihre Zuordnungen löschen – die Gegenstände fallen zurück in ihre Art.",
                        onClick = function() BG.RemoveCustom(name) BG.Refresh() if WeintCodex.UIOptions.Rebuild then WeintCodex.UIOptions.Rebuild() end end },
                      { type = "empty" })
            end
            B:Row({ type = "toggle", label = "Bank nach Kategorien", key = "bankCats",
                    disabled = function() return not Opt("categories") end,
                    description = "Neben der Bank ein Fenster mit allem, was in der Bank liegt, nach denselben Kategorien. Rechtsklick nimmt in die Taschen, Rechtsklick auf eine Überschrift die ganze Kategorie." },
                  { type = "empty" })
            B:Advanced()
            B:Section("Reihenfolge", "So stehen die Kategorien im Taschenfenster – und neben der Bank.")
            for i, c in ipairs(BG.AllCategories()) do
                local function Move(d)
                    BG.MoveCategory(c.key, d)
                    if WeintCodex.UIOptions.Rebuild then WeintCodex.UIOptions.Rebuild() end
                end
                B:Row({ type = "button", label = i .. ". " .. c.label, text = "Nach oben",
                        disabled = function() return not Opt("categories") or i == 1 end, onClick = function() Move(-1) end },
                      { type = "button", label = " ", text = "Nach unten",
                        disabled = function() return not Opt("categories") end, onClick = function() Move(1) end })
            end
            B:Section("Kategorien", "Abgeschaltete Kategorien landen unter „Verschiedenes“.")
            local cats = {}
            for _, c in ipairs(BG.CATEGORIES) do
                if c.key ~= "misc" then
                    cats[#cats + 1] = { type = "toggle", label = c.label, key = "cat_" .. c.key,
                                        disabled = function() return not Opt("categories") end }
                end
            end
            for i = 1, #cats, 2 do B:Row(cats[i], cats[i + 1] or { type = "empty" }) end
        end },
    },
})
