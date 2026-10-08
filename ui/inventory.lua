--------------------------------------------------
-- WeintCodex :: Bestand aller Charaktere (Komfort, Seite "Bestand")
--------------------------------------------------
-- Seit 6.24.0.0 (Beta-Test: "accountweite Taschen - mit einem Char sehen,
-- ob ein anderer Char meines Accounts das Item auch hat").
--
-- Jeder Charakter merkt sich, was er hat: Taschen beim Einloggen und bei
-- jeder Aenderung, angelegte Ausruestung, die Bank, solange sie offen ist
-- (anders liest der Client sie nicht). Gespeichert in WeintCodex_SavedData
-- (gilt fuer den ganzen Account), je Charakter nur Gegenstandsnummer und
-- Anzahl. Gezeigt im Tooltip jedes Gegenstands und mit /wcui bestand <Name>.
--
-- STAND, NICHT LIVE: was ein anderer Charakter hat, ist der Stand seines
-- letzten Einloggens - die Bank der Stand ihres letzten Besuchs. Ein
-- Charakter, dessen Bank nie offen war, hat "Bank: unbekannt", nicht 0.
-- Post und Auktionen kennt der Bestand nicht.
--------------------------------------------------

local K = WeintCodex.UIKit
local C = WeintCodex.Colors
local KEY = "comfort"

WeintCodex.UIInventory = {}
local IV = WeintCodex.UIInventory

IV.DEFAULTS = {
    invOn = true,            -- Bestand merken und im Tooltip zeigen
    invAllRealms = false,    -- auch Charaktere anderer Realms
}
IV.MAX_RESULTS = 40

function IV.Active() return K.IsActive(KEY) and K.Get(KEY, "invOn") and true or false end

local function Plain(v) return K.Plain(v) end
local function Str(v) v = Plain(v) return type(v) == "string" and v or nil end

function IV.Me()
    local name = _G.UnitName and Str(_G.UnitName("player"))
    local realm = _G.GetRealmName and Str(_G.GetRealmName())
    if not (name and realm) then return nil end
    return realm .. "|" .. name, name, realm
end

function IV.Store(create)
    local sd = WeintCodex.SavedData
    if type(sd) ~= "table" then return nil end
    if not sd.inventory then
        if not create then return nil end
        sd.inventory = { chars = {}, names = {} }
    end
    sd.inventory.chars = sd.inventory.chars or {}
    sd.inventory.names = sd.inventory.names or {}
    return sd.inventory
end

local function Char(create)
    local key, name, realm = IV.Me()
    local st = IV.Store(create)
    if not (key and st) then return nil end
    local c = st.chars[key]
    if not c and create then
        c = { name = name, realm = realm }
        st.chars[key] = c
    end
    if c then
        local _, class = _G.UnitClass and _G.UnitClass("player")
        c.class = Str(class) or c.class
        c.faction = _G.UnitFactionGroup and Str(_G.UnitFactionGroup("player")) or c.faction
    end
    return c, key
end
IV.Char = Char

--------------------------------------------------
-- Lesen
--------------------------------------------------

local function Container()
    local cc = _G.C_Container
    if type(cc) == "table" and cc.GetContainerNumSlots and cc.GetContainerItemInfo then return cc end
end

local function ReadBags(list, into)
    local cc = Container()
    if not cc then return false end
    local st = IV.Store(true)
    for _, bag in ipairs(list) do
        local ok, n = pcall(cc.GetContainerNumSlots, bag)
        n = ok and Plain(n)
        for slot = 1, type(n) == "number" and n or 0 do
            local ok2, info = pcall(cc.GetContainerItemInfo, bag, slot)
            if ok2 and type(info) == "table" then
                local id, count = Plain(info.itemID), Plain(info.stackCount)
                if type(id) == "number" then
                    into[id] = (into[id] or 0) + (type(count) == "number" and count or 1)
                    local link = Str(info.hyperlink)
                    local nm = link and link:match("%[(.-)%]")
                    if nm and st then st.names[id] = nm end
                end
            end
        end
    end
    return true
end

-- Taschen: 0..NUM_BAG_SLOTS, dazu die Reagenzientasche, wenn es sie gibt.
function IV.BagList()
    local n = tonumber(_G.NUM_BAG_SLOTS) or 4
    local list = {}
    for b = 0, n do list[#list + 1] = b end
    local bi = _G.Enum and _G.Enum.BagIndex
    local rb = bi and Plain(bi.ReagentBag)
    if type(rb) == "number" and rb > n then list[#list + 1] = rb end
    return list
end

-- Bank: das Fach der Bank und ihre Taschen.
function IV.BankList()
    local bank = tonumber(_G.BANK_CONTAINER) or -1
    local n = tonumber(_G.NUM_BAG_SLOTS) or 4
    local m = tonumber(_G.NUM_BANKBAGSLOTS) or 7
    local list = { bank }
    for b = n + 1, n + m do list[#list + 1] = b end
    return list
end

function IV.ScanBags()
    if not IV.Active() then return false end
    local c = Char(true)
    if not c then return false end
    local bags = {}
    if not ReadBags(IV.BagList(), bags) then return false end
    c.bags = bags
    local worn = {}
    if _G.GetInventoryItemID then
        for slot = 1, 19 do
            local id = Plain(_G.GetInventoryItemID("player", slot))
            if type(id) == "number" then worn[id] = (worn[id] or 0) + 1 end
        end
    end
    c.worn = worn
    c.at = _G.time and _G.time() or 0
    return true
end

IV.bankOpen = false
function IV.ScanBank()
    if not (IV.Active() and IV.bankOpen) then return false end
    local c = Char(true)
    if not c then return false end
    local bank = {}
    if not ReadBags(IV.BankList(), bank) then return false end
    c.bank = bank
    c.bankAt = _G.time and _G.time() or 0
    return true
end

--------------------------------------------------
-- Auskunft
--------------------------------------------------

-- { { key, name, realm, class, bags, bank, worn, total, bankKnown }, ... }
-- fuer einen Gegenstand; der eigene Charakter zuerst.
function IV.Holders(id)
    local st = IV.Store(false)
    if not (st and type(id) == "number") then return {} end
    local me, _, myRealm = IV.Me()
    local all = K.Get(KEY, "invAllRealms")
    local out = {}
    for key, c in pairs(st.chars) do
        if all or c.realm == myRealm then
            local b = c.bags and c.bags[id] or 0
            local k = c.bank and c.bank[id] or 0
            local w = c.worn and c.worn[id] or 0
            if b + k + w > 0 then
                out[#out + 1] = { key = key, name = c.name, realm = c.realm, class = c.class,
                    bags = b, bank = k, worn = w, total = b + k + w, me = key == me }
            end
        end
    end
    table.sort(out, function(a, b)
        if a.me ~= b.me then return a.me end
        if a.total ~= b.total then return a.total > b.total end
        return tostring(a.name) < tostring(b.name)
    end)
    return out
end

function IV.Where(h)
    local parts = {}
    if h.bags > 0 then parts[#parts + 1] = "Taschen " .. h.bags end
    if h.bank > 0 then parts[#parts + 1] = "Bank " .. h.bank end
    if h.worn > 0 then parts[#parts + 1] = "angelegt" end
    return table.concat(parts, " · ")
end

local function ClassColor(class)
    local rc = _G.RAID_CLASS_COLORS
    local c = rc and class and rc[class]
    if type(c) == "table" and type(c.r) == "number" then return c.r, c.g, c.b end
    local t = C.textBright
    return t[1], t[2], t[3]
end
IV.ClassColor = ClassColor

local function Label(h, myRealm)
    local n = h.name or "?"
    if h.realm and myRealm and h.realm ~= myRealm then n = n .. "-" .. h.realm end
    return n
end

-- Zeilen fuer den Tooltip, oder nil (keiner hat ihn).
function IV.TooltipLines(id)
    local hs = IV.Holders(id)
    if #hs == 0 then return nil end
    local _, _, myRealm = IV.Me()
    local lines, total = {}, 0
    for _, h in ipairs(hs) do
        total = total + h.total
        local r, g, b = ClassColor(h.class)
        lines[#lines + 1] = { Label(h, myRealm), h.total .. "  (" .. IV.Where(h) .. ")", r, g, b }
    end
    if #hs > 1 then lines[#lines + 1] = { "Alle Charaktere", tostring(total) } end
    return lines
end

local function ItemIdOf(tt, data)
    local AP = WeintCodex.UIAuctionPrices
    if AP and AP.ItemIdOf then return AP.ItemIdOf(tt, data) end
    local id = type(data) == "table" and Plain(data.id)
    return type(id) == "number" and id or nil
end

local function OnItem(tt, data)
    if not IV.Active() then return end
    if tt ~= _G.GameTooltip and tt ~= _G.ItemRefTooltip then return end
    if tt.IsForbidden and tt:IsForbidden() then return end
    local id = ItemIdOf(tt, data)
    local lines = id and IV.TooltipLines(id)
    if not lines then return end
    local m = C.textMuted
    for _, l in ipairs(lines) do
        local r, g, b = l[3] or m[1], l[4] or m[2], l[5] or m[3]
        tt:AddDoubleLine(l[1], l[2], r, g, b, m[1], m[2], m[3])
    end
end
IV.OnItem = OnItem

function IV.HookTooltips()
    if IV._hooked then return end
    IV._hooked = true
    local tdp, e = _G.TooltipDataProcessor, _G.Enum and _G.Enum.TooltipDataType
    if tdp and tdp.AddTooltipPostCall and e and e.Item then
        pcall(tdp.AddTooltipPostCall, e.Item, K.Measured("Bestand", OnItem))
        IV.hookedVia = "TooltipDataProcessor"
    else
        for _, n in ipairs({ "GameTooltip", "ItemRefTooltip" }) do
            local tt = _G[n]
            if type(tt) == "table" and tt.HookScript then
                tt:HookScript("OnTooltipSetItem", function(self) OnItem(self) end)
            end
        end
        IV.hookedVia = "OnTooltipSetItem"
    end
end

-- Suche ueber alle Charaktere: Teil des Namens, gross/klein egal.
function IV.Search(text)
    local st = IV.Store(false)
    local out = {}
    if not (st and type(text) == "string" and text ~= "") then return out end
    local want = text:lower()
    local ids = {}
    for id, nm in pairs(st.names) do
        if type(nm) == "string" and nm:lower():find(want, 1, true) then ids[#ids + 1] = id end
    end
    table.sort(ids, function(a, b) return st.names[a] < st.names[b] end)
    for _, id in ipairs(ids) do
        local hs = IV.Holders(id)
        if #hs > 0 then out[#out + 1] = { id = id, name = st.names[id], holders = hs } end
        if #out >= IV.MAX_RESULTS then break end
    end
    return out
end

function IV.SearchReport(text)
    local res = IV.Search(text)
    local lines = { "Suche: „" .. tostring(text) .. "“" }
    if #res == 0 then
        lines[#lines + 1] = "Keiner deiner Charaktere hat etwas mit diesem Namen – soweit sie es beim letzten Einloggen hatten."
        return lines
    end
    local _, _, myRealm = IV.Me()
    for _, r in ipairs(res) do
        local parts = {}
        for _, h in ipairs(r.holders) do parts[#parts + 1] = Label(h, myRealm) .. " " .. h.total .. " (" .. IV.Where(h) .. ")" end
        lines[#lines + 1] = r.name .. ": " .. table.concat(parts, ", ")
    end
    if #res >= IV.MAX_RESULTS then lines[#lines + 1] = "… und mehr – genauer suchen." end
    return lines
end

--------------------------------------------------
-- Ereignisse
--------------------------------------------------

local ev = CreateFrame("Frame")
ev:SetScript("OnEvent", function(_, event)
    if event == "BANKFRAME_OPENED" then
        IV.bankOpen = true
        IV.ScanBank()
    elseif event == "BANKFRAME_CLOSED" then
        IV.ScanBank()
        IV.bankOpen = false
    elseif event == "PLAYERBANKSLOTS_CHANGED" then
        IV.ScanBank()
    else                                  -- BAG_UPDATE_DELAYED, PLAYER_EQUIPMENT_CHANGED, PLAYER_ENTERING_WORLD
        IV.ScanBags()
        if IV.bankOpen then IV.ScanBank() end
    end
end)
IV.events = ev

local EVENTS = { "BAG_UPDATE_DELAYED", "PLAYER_EQUIPMENT_CHANGED", "PLAYER_ENTERING_WORLD",
    "BANKFRAME_OPENED", "BANKFRAME_CLOSED", "PLAYERBANKSLOTS_CHANGED" }

local function Apply()
    for _, e in ipairs(EVENTS) do
        if IV.Active() then pcall(ev.RegisterEvent, ev, e) else pcall(ev.UnregisterEvent, ev, e) end
    end
    if IV.Active() then
        IV.HookTooltips()
        IV.ScanBags()
    end
end
IV.Apply = Apply

--------------------------------------------------
-- Bericht und Seite
--------------------------------------------------

function IV.StatusLines()
    local st = IV.Store(false)
    local out = {}
    local n, items = 0, 0
    local _, _, myRealm = IV.Me()
    local here = {}
    for _, c in pairs(st and st.chars or {}) do
        n = n + 1
        if c.realm == myRealm then
            here[#here + 1] = (c.name or "?") .. (c.bank and "" or " (Bank unbekannt)")
        end
    end
    for _ in pairs(st and st.names or {}) do items = items + 1 end
    out[#out + 1] = "Charaktere gemerkt: " .. n .. " · Namen von Gegenständen: " .. items
        .. " · Taschen lesen (C_Container): " .. (Container() and "ja" or "nein")
    if #here > 0 then
        table.sort(here)
        out[#out + 1] = "Auf diesem Realm: " .. table.concat(here, ", ")
    end
    out[#out + 1] = "Tooltip über " .. tostring(IV.hookedVia or "–")
    return out
end

-- Charakter vergessen (umbenannt, geloescht).
function IV.Forget(key)
    local st = IV.Store(false)
    if st and st.chars[key] then st.chars[key] = nil return true end
    return false
end

local function Build(B)
    local off = function() return not K.Get(KEY, "invOn") end
    B:Section("Bestand aller Charaktere", "Jeder Charakter merkt sich Taschen, Ausrüstung und Bank. Im Tooltip jedes Gegenstands steht, wer von deinen Charakteren ihn wie oft hat – Stand ihres letzten Einloggens, die Bank Stand ihres letzten Besuchs.")
    B:Row({ type = "toggle", label = "Bestand merken und zeigen", key = "invOn",
            description = "Suchen: /wcui bestand <Name>." },
          { type = "toggle", label = "Auch andere Realms", key = "invAllRealms", disabled = off,
            description = "Sonst nur Charaktere auf diesem Realm." })
    B:Note("Post und Auktionen zählen nicht mit. Wer seine Bank seit dieser Version nie geöffnet hat, zeigt nur Taschen und Ausrüstung.")
end

local mod = K.Module(KEY)
if mod then
    for k, v in pairs(IV.DEFAULTS) do
        if mod.defaults[k] == nil then mod.defaults[k] = v end
    end
    mod.pages[#mod.pages + 1] = { key = "bestand", label = "Bestand", build = Build }
end

K.Listen(function(kind, key)
    if (kind == "active" or kind == "setting") and key == KEY then Apply() end
end)

local boot = CreateFrame("Frame")
boot:RegisterEvent("PLAYER_LOGIN")
boot:SetScript("OnEvent", function() Apply() end)
