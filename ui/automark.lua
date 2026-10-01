--------------------------------------------------
-- WeintCodex :: Komfort - Automark (6.8.1.0)
--------------------------------------------------
-- Beta-Test: "Wenn eine Instanz betreten wird, soll der Tank und Heiler
-- einen Mark ueber den Kopf bekommen. Einstellbar, welches Mark."
--
-- WER TANK IST, SAGT DAS SPIEL - ODER NIEMAND. Gelesen wird nur die Rolle,
-- die das Spiel vergeben hat (UnitGroupRolesAssigned: Suche nach Gruppe,
-- Rollenwahl). In einer Gruppe ohne Rollen wird NICHT markiert und nicht
-- geraten - weder aus der Ausruestung noch aus dem Talentbaum: was der
-- Client nicht beantwortet, wird nicht hergeleitet. Die Einstellungen und
-- der Chat sagen dann, warum nichts geschah.
--
-- WER MARKIERT. SetRaidTarget mit derselben Markierung auf demselben Ziel
-- nimmt sie WIEDER AB - und der Forever-Client haelt den Index geheim (siehe
-- ui/kit.lua, "Markierung geheim"), Lua kann also nicht nachsehen, ob die
-- Markierung schon sitzt. Deshalb:
--   * nur der Gruppenleiter markiert (abschaltbar) - zwei Spieler mit
--     WeintCodex nehmen sich sonst gegenseitig die Markierung ab;
--   * je Instanz und Spieler einmal: wer schon markiert wurde, wird nicht
--     noch einmal markiert, bis die Rolle oder die gewaehlte Markierung
--     wechselt oder die Instanz neu betreten wird - auch nicht, wenn eine
--     andere Einstellung geaendert wird (das nahm im Test die Markierung ab);
--   * ist der Index doch lesbar und stimmt schon, bleibt es dabei.
--   * nie im Kampf: erst danach (PLAYER_REGEN_ENABLED).
--
-- UNGEMESSEN: ob der Forever-Client Addons ueberhaupt markieren laesst.
-- Lehnt er ab, steht das in den Einstellungen ("vom Spiel abgelehnt").
--
-- WO. Eine Seite des Komforts ("Automark"), kein eigenes Modul: ein
-- weiterer Eintrag haette der Seitenleiste der Einstellungen die Luft fuer
-- einen naechsten genommen (load_test.lua, "Nichts muss scrollen").
-- Gespeichert unter "comfort"; wie jeder Komfort-Helfer von Haus aus AUS.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIAutoMark = {}

local AM = WeintCodex.UIAutoMark
local K = WeintCodex.UIKit
local KEY = "comfort"

-- Markierungen des Spiels, Index 1 bis 8.
AM.MARKS = { "Stern", "Kreis", "Diamant", "Dreieck", "Mond", "Quadrat", "Kreuz", "Totenkopf" }
AM.ROLES = { "TANK", "HEALER" }
AM.ROLE_LABEL = { TANK = "Tank", HEALER = "Heiler" }
AM.SETTING = { TANK = "markTank", HEALER = "markHealer" }

-- Einstellungen im Komfort (Namen mit "mark", damit sie dort nicht mit
-- anderen Helfern zusammenstossen).
AM.DEFAULTS = {
    autoMark       = false,
    markTank       = 6,      -- Quadrat
    markHealer     = 4,      -- Dreieck
    markDungeons   = true,
    markRaids      = true,
    markOnlyLeader = true,
    markChat       = true,
}

local function Say(text)
    print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " " .. text)
end

function AM.Icon(index, size)
    size = size or 14
    return string.format("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_%d:%d:%d|t", index, size, size)
end

local function Call(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b = pcall(fn, ...)
    if not ok then return nil end
    return K.Plain(a), K.Plain(b)
end

-- Zustand dieser Sitzung (nichts davon wird gespeichert).
AM.state = { instance = nil, done = {}, last = nil, refused = false, pending = false }
local state = AM.state

-- In welcher Instanz sind wir, und soll dort markiert werden?
function AM.Instance()
    local inside, kind = Call(_G.IsInInstance)
    if not inside then return nil end
    if kind == "party" and not K.Get(KEY, "markDungeons") then return nil end
    if kind == "raid" and not K.Get(KEY, "markRaids") then return nil end
    if kind ~= "party" and kind ~= "raid" then return nil end
    -- Kennung der Instanz: Name und Nummer, soweit der Client sie nennt.
    local id = kind
    if type(_G.GetInstanceInfo) == "function" then
        local ok, name, _, _, _, _, _, _, instanceID = pcall(_G.GetInstanceInfo)
        name, instanceID = ok and K.Plain(name) or nil, ok and K.Plain(instanceID) or nil
        id = tostring(instanceID or name or kind)
    end
    return id, kind
end

-- Darf dieser Spieler markieren?
function AM.MayMark(kind)
    local leader = Call(_G.UnitIsGroupLeader, "player")
    if leader then return true end
    if K.Get(KEY, "markOnlyLeader") then return false, "nur der Gruppenleiter markiert" end
    if kind == "raid" then
        local assist = Call(_G.UnitIsGroupAssistant, "player")
        if not assist then return false, "im Schlachtzug markieren nur Leiter und Assistenten" end
    end
    return true
end

-- Einheiten der Gruppe in fester Reihenfolge.
local PARTY = { "player", "party1", "party2", "party3", "party4" }
local RAID = {}
for i = 1, 40 do RAID[i] = "raid" .. i end

local function Exists(unit)
    return Call(_G.UnitExists, unit) and true or false
end

-- Der erste Spieler je Rolle (nur die Rolle, die das Spiel vergeben hat).
function AM.Holders(kind)
    local list = (kind == "raid") and RAID or PARTY
    local out = {}
    for _, unit in ipairs(list) do
        if Exists(unit) then
            local role = Call(_G.UnitGroupRolesAssigned, unit)
            if (role == "TANK" or role == "HEALER") and not out[role] then out[role] = unit end
        end
    end
    return out
end

local function Who(unit)
    local guid = Call(_G.UnitGUID, unit)
    if type(guid) == "string" then return guid end
    local name = Call(_G.UnitName, unit)
    return type(name) == "string" and name or unit
end

local function NameOf(unit)
    local name = Call(_G.UnitName, unit)
    return type(name) == "string" and name or unit
end

-- Schon richtig markiert? Nur wenn der Client den Index offen nennt.
local function Already(unit, index)
    if type(_G.GetRaidTargetIndex) ~= "function" then return false end
    local ok, v = pcall(_G.GetRaidTargetIndex, unit)
    if not ok or K.IsSecret(v) then return false end
    return K.Plain(v) == index
end

-- Ein Durchlauf: markiert, was noch nicht markiert ist. Gibt eine Zeile
-- fuer die Einstellungen zurueck (und merkt sie sich).
function AM.On()
    return K.IsActive(KEY) and K.Get(KEY, "autoMark") and true or false
end

function AM.Run()
    if not AM.On() then return nil end
    local id, kind = AM.Instance()
    if not id then
        state.instance, state.done = nil, {}
        state.last = "Nicht in einer Instanz, in der markiert wird."
        return state.last
    end
    if state.instance ~= id then
        state.instance, state.done, state.told = id, {}, false
    end
    if Call(_G.InCombatLockdown) then
        state.pending = true
        state.last = "Im Kampf – markiert wird danach."
        return state.last
    end
    state.pending = false
    local may, why = AM.MayMark(kind)
    if not may then
        state.last = "Nicht markiert: " .. why .. "."
        return state.last
    end
    local holders = AM.Holders(kind)
    local parts, changed, used = {}, false, {}
    for _, role in ipairs(AM.ROLES) do
        local index = tonumber(K.Get(KEY, AM.SETTING[role])) or 0
        local unit = holders[role]
        local label = AM.ROLE_LABEL[role]
        if index < 1 or index > 8 then
            parts[#parts + 1] = label .. ": keine Markierung gewählt"
        elseif used[index] then
            parts[#parts + 1] = label .. ": dieselbe Markierung wie oben – ausgelassen"
        elseif not unit then
            parts[#parts + 1] = label .. ": keine Rolle vergeben"
        else
            used[index] = true
            -- Spieler UND Markierung: neu gesetzt wird nur, wenn sich eines
            -- davon aendert - dieselbe noch einmal naehme sie ab.
            local who = Who(unit) .. "#" .. index
            if state.done[role] ~= who then
                if Already(unit, index) then
                    state.done[role] = who
                else
                    local ok = pcall(_G.SetRaidTarget, unit, index)
                    if ok and type(_G.SetRaidTarget) == "function" then
                        state.done[role] = who
                        changed = true
                    else
                        state.refused = true
                    end
                end
            end
            parts[#parts + 1] = string.format("%s: %s %s", label, NameOf(unit),
                state.done[role] == who and AM.Icon(index) or "(vom Spiel abgelehnt)")
        end
    end
    state.last = table.concat(parts, " · ")
    if K.Get(KEY, "markChat") and (changed or not state.told) then
        state.told = true
        Say("Automark: " .. state.last)
    end
    return state.last
end

--------------------------------------------------
-- Ereignisse
--------------------------------------------------

AM.EVENTS = { "PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA", "GROUP_ROSTER_UPDATE",
              "PLAYER_ROLES_ASSIGNED", "PARTY_LEADER_CHANGED", "PLAYER_REGEN_ENABLED" }

local events = CreateFrame("Frame")
events:SetScript("OnEvent", K.Measured("Automark", function(_, event)
    if event == "PLAYER_REGEN_ENABLED" and not state.pending then return end
    AM.Run()
end))

local function Apply()
    events:UnregisterAllEvents()
    if not AM.On() then
        state.last = nil
        return
    end
    for _, e in ipairs(AM.EVENTS) do pcall(events.RegisterEvent, events, e) end
    AM.Run()
end

--------------------------------------------------
-- Seite im Komfort
--------------------------------------------------

local function MarkItems()
    local items = { { value = 0, text = "Keine" } }
    for i, name in ipairs(AM.MARKS) do
        items[#items + 1] = { value = i, text = AM.Icon(i) .. "  " .. name }
    end
    return items
end

function AM.Status()
    if not AM.On() then return "Aus." end
    return state.last or "Noch nichts zu tun."
end

local function Build(B)
    local off = function() return not K.Get(KEY, "autoMark") end
    B:Section("Automark")
    B:Row({ type = "toggle", label = "Tank und Heiler markieren", key = "autoMark",
            description = "Beim Betreten einer Instanz, mit der Rolle, die das Spiel vergeben hat." },
          { type = "toggle", label = "Im Chat melden", key = "markChat", disabled = off })
    B:Section("Wer bekommt welche Markierung")
    B:Row({ type = "dropdown", label = "Tank", key = "markTank", items = MarkItems(), disabled = off },
          { type = "dropdown", label = "Heiler", key = "markHealer", items = MarkItems(), disabled = off })
    B:Section("Wann")
    B:Row({ type = "toggle", label = "In Dungeons", key = "markDungeons", disabled = off },
          { type = "toggle", label = "In Schlachtzügen", key = "markRaids", disabled = off })
    B:Row({ type = "toggle", label = "Nur als Gruppenleiter", key = "markOnlyLeader", disabled = off,
            description = "Empfohlen. Markieren zwei Spieler mit WeintCodex, nimmt der zweite die Markierung wieder ab." },
          { type = "empty" })
    B:Note("Markiert wird nur, wer vom Spiel eine Rolle bekommen hat (Suche nach Gruppe, Rollenwahl). "
        .. "Ohne Rolle wird nichts geraten – weder aus Ausrüstung noch aus Talenten. "
        .. "Je Instanz einmal; neu, wenn eine Rolle oder die Markierung wechselt. Nie im Kampf.")
    B:Note("Zuletzt: " .. AM.Status())
end

-- An den Komfort haengen: Standardwerte und eine Seite.
local mod = K.Module(KEY)
if mod then
    for k, v in pairs(AM.DEFAULTS) do
        if mod.defaults[k] == nil then mod.defaults[k] = v end
    end
    mod.pages[#mod.pages + 1] = { key = "automark", label = "Automark", build = Build }
end

-- Kein Zuruecksetzen bei einer Einstellung: eine neu gewaehlte Markierung
-- erkennt Run selbst (Spieler#Markierung); jede andere Einstellung setzt
-- nichts neu.
K.Listen(function(kind, key)
    if (kind == "active" or kind == "setting") and key == KEY then Apply() end
end)
