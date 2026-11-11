--------------------------------------------------
-- WeintCodex :: Angel-Logbuch
--------------------------------------------------
-- Seit 1.3.0.0, auf Wunsch (nach dem "Fishing Log" von SKTools,
-- eigener Code). Merkt sich je Gebiet, wie oft geworfen wurde und was
-- dabei herauskam. Gezeigt auf der Seite "Berufe" als Werkzeug "Angeln"
-- (modules/proftools.lua).
--
-- Nur was der Client sagt: ein Wurf ist ein Angel-Kanal des Spielers
-- (UNIT_SPELLCAST_CHANNEL_START, Angeln), ein Fang ist ein Beutefenster,
-- das der Client als Angelbeute meldet (IsFishingLoot). Ein Gebiet ohne
-- Fang steht mit seinen Wuerfen da, nicht mit einer erfundenen 0 %-Quote
-- - die Quote gibt es erst ab einem Fang.
--
-- Gespeichert in WeintCodex_SavedData.fishLog (kontoweit):
--   zones[Gebiet] = { casts = n, catches = n, last = Zeit,
--                     items = { [itemID] = Anzahl } }
-- Was dieselbe Beute einmal zaehlt: ein Beutefenster wird einmal gezaehlt,
-- auch wenn es (Auto-Pluendern aus) mehrmals LOOT_OPENED sendet.
--------------------------------------------------

WeintCodex.FishLog = {}
local FL = WeintCodex.FishLog

FL.SPELL = 7620
FL.CHANNELS = { [7620] = true, [7731] = true, [7732] = true, [18248] = true }
FL.MAX_ROWS = 8        -- Gegenstaende je Gebiet auf der Seite

local function Plain(v)
    local K = WeintCodex.UIKit
    return (K and K.Plain) and K.Plain(v) or v
end

local function Now()
    local t = _G.time and _G.time()
    return type(t) == "number" and t or 0
end

function FL.Store()
    local sd = WeintCodex.SavedData
    if type(sd) ~= "table" then return nil end
    sd.fishLog = sd.fishLog or { zones = {} }
    sd.fishLog.zones = sd.fishLog.zones or {}
    return sd.fishLog
end

function FL.Zone()
    local z = _G.GetRealZoneText and Plain(_G.GetRealZoneText())
    if type(z) ~= "string" or z == "" then z = _G.GetZoneText and Plain(_G.GetZoneText()) end
    return (type(z) == "string" and z ~= "") and z or nil
end

local function ZoneEntry(name)
    local s = FL.Store()
    if not (s and name) then return nil end
    local e = s.zones[name]
    if not e then
        e = { casts = 0, catches = 0, items = {} }
        s.zones[name] = e
    end
    return e
end

local function SpellName()
    local cs = _G.C_Spell
    local n = cs and cs.GetSpellName and Plain(cs.GetSpellName(FL.SPELL))
    return type(n) == "string" and n or nil
end

function FL.IsFishing(spellID)
    spellID = Plain(spellID)
    if type(spellID) ~= "number" then return false end
    if FL.CHANNELS[spellID] then return true end
    local cs = _G.C_Spell
    local n = cs and cs.GetSpellName and Plain(cs.GetSpellName(spellID))
    if type(n) ~= "string" then return false end
    -- 1.0.5.51 (Bericht: "Fertigkeit 34/75, aber kein Fisch drin"): kennt
    -- der Client 7620 nicht (neue Nummern in Forever), zaehlt der Name.
    return n == SpellName() or FL.NAMES[n] == true
end
FL.NAMES = { ["Angeln"] = true, ["Fishing"] = true }

FL.lastCast = 0
FL.CAST_WINDOW = 35    -- so lange nach dem Auswerfen gilt ein Beutefenster als Fang
function FL.NoteCast(zone)
    FL.lastCast = Now()
    local e = ZoneEntry(zone or FL.Zone())
    if e then e.casts = e.casts + 1 end
end

-- Angelbeute? Erst, was der Client sagt (IsFishingLoot); fehlt die
-- Funktion oder sagt sie nichts Brauchbares, zaehlt ein Beutefenster kurz
-- nach dem eigenen Auswerfen (1.0.5.51 - vorher fiel so jeder Fang weg).
function FL.IsFishingLoot()
    if type(_G.IsFishingLoot) == "function" then
        local ok, v = pcall(_G.IsFishingLoot)
        v = ok and Plain(v)
        if v == true then return true end
    end
    return FL.lastCast > 0 and Now() - FL.lastCast <= FL.CAST_WINDOW
end

-- Ein Fang: Liste aus { id, qty }. Muenzen (ohne Gegenstand) zaehlen nicht.
function FL.NoteCatch(items, zone)
    local e = ZoneEntry(zone or FL.Zone())
    if not e then return end
    e.catches = e.catches + 1
    e.last = Now()
    for _, it in ipairs(items) do
        e.items[it.id] = (e.items[it.id] or 0) + (it.qty or 1)
    end
end

function FL.ReadLoot()
    local out = {}
    local n = _G.GetNumLootItems and Plain(_G.GetNumLootItems()) or 0
    for i = 1, (type(n) == "number" and n or 0) do
        local link = _G.GetLootSlotLink and Plain(_G.GetLootSlotLink(i))
        local id = type(link) == "string" and tonumber(link:match("item:(%d+)"))
        if id then
            local qty = 1
            if _G.GetLootSlotInfo then
                local _, _, q = _G.GetLootSlotInfo(i)
                q = Plain(q)
                if type(q) == "number" and q > 0 then qty = q end
            end
            out[#out + 1] = { id = id, qty = qty }
        end
    end
    return out
end

-- Gebiete, zuletzt beangelte zuerst; je Gebiet die Gegenstaende nach Menge.
function FL.Zones()
    local s = FL.Store()
    local list = {}
    if not s then return list end
    for name, e in pairs(s.zones) do
        local items, total = {}, 0
        for id, qty in pairs(e.items or {}) do
            items[#items + 1] = { id = id, qty = qty }
            total = total + qty
        end
        table.sort(items, function(a, b) if a.qty ~= b.qty then return a.qty > b.qty end return a.id < b.id end)
        list[#list + 1] = { name = name, casts = e.casts or 0, catches = e.catches or 0, last = e.last or 0,
                            items = items, total = total }
    end
    table.sort(list, function(a, b) if a.last ~= b.last then return a.last > b.last end return a.name < b.name end)
    return list
end

-- "42 Würfe · 31 Fänge (74 %)" - Quote nur mit Wuerfen UND Faengen.
function FL.ZoneLine(z)
    local parts = { z.casts .. (z.casts == 1 and " Wurf" or " Würfe") }
    if z.catches > 0 then
        local share = (z.casts >= z.catches and z.casts > 0) and string.format(" (%d %%)", math.floor(z.catches / z.casts * 100 + 0.5)) or ""
        parts[#parts + 1] = z.catches .. (z.catches == 1 and " Fang" or " Fänge") .. share
    end
    return table.concat(parts, " · ")
end

function FL.Clear()
    local sd = WeintCodex.SavedData
    if type(sd) == "table" then sd.fishLog = { zones = {} } end
end

--------------------------------------------------
-- Ereignisse
--------------------------------------------------

local lootCounted = false
local ev = CreateFrame("Frame")
FL.events = ev
for _, e in ipairs({ "UNIT_SPELLCAST_CHANNEL_START", "LOOT_READY", "LOOT_OPENED", "LOOT_CLOSED" }) do
    pcall(ev.RegisterEvent, ev, e)
end
function FL.OnEvent(_, event, ...)
    if event == "UNIT_SPELLCAST_CHANNEL_START" then
        local unit, _, spellID = ...
        if Plain(unit) == "player" and FL.IsFishing(spellID) then FL.NoteCast() end
    elseif event == "LOOT_READY" or event == "LOOT_OPENED" then
        -- LOOT_READY kommt auch mit automatischem Pluendern, bevor die
        -- Plaetze leer sind; einmal je Beutefenster.
        if lootCounted or not FL.IsFishingLoot() then return end
        local items = FL.ReadLoot()
        if #items == 0 then return end
        lootCounted = true
        FL.lastCast = 0
        FL.NoteCatch(items)
    elseif event == "LOOT_CLOSED" then
        lootCounted = false
    end
end
ev:SetScript("OnEvent", WeintCodex.Measured("fishlog", FL.OnEvent))
