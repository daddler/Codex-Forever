--------------------------------------------------
-- WeintCodex :: Oberflaeche - dein Profil bleibt deins
--------------------------------------------------
-- Beta-Test (nach 6.8.1.0, die SavedVariables speichern wieder): "Wenn
-- nicht, dann soll das vorherige Profil genutzt werden, was der Nutzer
-- angelegt und eingestellt hat. Wichtig: wenn man die WeintCodexUI nutzen
-- will, dann muss ein neues Profil angelegt werden, damit nichts geloescht
-- oder ueberschrieben wird!"
--
-- WAS "PROFIL" HIER HEISST. Was die Oberflaeche ausserhalb ihres eigenen
-- Speichers anfasst, sind genau zwei Dinge des Spiels:
--   1. das Layout des Bearbeitungsmodus (wo die Rahmen des Spiels stehen),
--   2. einige Spieleinstellungen (CVars: Chatstil, Leisten sperren, ...).
-- Fuer 1 legt die Einrichtung ein EIGENES Layout "WeintCodex" an
-- (ui/setup.lua) und schreibt nie in eines des Spielers. Fuer 2 merkt sich
-- diese Datei den Wert von vorher, bevor sie ihn aendert.
-- Chatreiter und Kanaele fasst seit 6.9.0.0 nichts mehr an: die speichert
-- das Spiel nur einmal je Charakter, ein zweites Profil davon gibt es nicht
-- - zuruecksetzen hiesse loeschen.
--
-- EINSCHALTEN (Hauptschalter an): merken, welches Layout gerade aktiv ist
-- (nur, wenn noch nichts gemerkt ist - ein zweites Einschalten darf das
-- Original nicht mit "WeintCodex" ueberschreiben), dann das Layout
-- "WeintCodex" aktiv setzen, wenn es das schon gibt. Sonst legt es die
-- Einrichtung nach dem Neuladen an.
-- AUSSCHALTEN: das gemerkte Layout wieder aktiv setzen - aber nur, wenn
-- gerade "WeintCodex" aktiv ist (wer selbst umgestellt hat, behaelt seine
-- Wahl) -, die Spieleinstellungen zurueckgeben, die Merkliste leeren. Das
-- Layout "WeintCodex" bleibt im Bearbeitungsmodus stehen: wer wieder
-- einschaltet, muss nicht neu einrichten.
--
-- SPIELEINSTELLUNGEN. Jede Aenderung laeuft ueber PF.SetCVar(name, wert,
-- besitzer). Besitzer ist "ui" (die ganze Oberflaeche) oder ein Modul.
-- Laeuft der Besitzer nicht mehr (PF.Sweep, beim Anmelden und nach jedem
-- Schalter), kommt der alte Wert zurueck - und nur, wenn noch UNSER Wert
-- steht. Hat der Spieler die Einstellung inzwischen selbst geaendert,
-- gilt seine.
--
-- UNBEKANNT IST NICHT "MODERN". Wer die Oberflaeche vor 6.9.0.0 hatte,
-- hat kein gemerktes Layout. Dann nimmt das Ausschalten das erste eigene
-- Layout des Spielers, sonst die erste Vorlage des Spiels - und sagt im
-- Chat, welches, statt so zu tun, als waere es das von vorher.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIProfile = {}

local PF = WeintCodex.UIProfile
local K  = WeintCodex.UIKit

PF.LAYOUT_NAME = "WeintCodex"

local function Say(text)
    print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " " .. text)
end

local function Root() return K.Root() end

--------------------------------------------------
-- Layouts des Bearbeitungsmodus
--------------------------------------------------

-- Wie viele Vorlagen des Spiels vor den eigenen Layouts stehen ("Modern",
-- "Klassisch"). Der aktive Index zaehlt sie mit.
function PF.PresetCount()
    local pm = _G.EditModePresetLayoutManager
    if type(pm) == "table" and type(pm.GetCopyOfPresetLayouts) == "function" then
        local ok, list = pcall(pm.GetCopyOfPresetLayouts, pm)
        if ok and type(list) == "table" and #list > 0 then return #list end
    end
    return 2
end

-- Die Layouts des Spiels oder nil, Grund.
function PF.Layouts()
    local em = _G.C_EditMode
    if not (em and em.GetLayouts) then return nil, "C_EditMode fehlt" end
    local ok, info = pcall(em.GetLayouts)
    if not ok or type(info) ~= "table" or type(info.layouts) ~= "table" then
        return nil, "GetLayouts antwortet nicht"
    end
    return info
end

-- Das aktive Layout als { preset = n } oder { name = "..." }, oder nil.
function PF.Active(info)
    info = info or PF.Layouts()
    if not info then return nil end
    local a = tonumber(info.activeLayout)
    if not a then return nil end
    local nPre = PF.PresetCount()
    if a >= 1 and a <= nPre then return { preset = a } end
    local l = info.layouts[a - nPre]
    if type(l) == "table" and type(l.layoutName) == "string" then return { name = l.layoutName } end
    return nil
end

-- Der Index (mit Vorlagen) eines gemerkten Layouts, oder nil.
function PF.IndexOf(want, info)
    info = info or PF.Layouts()
    if not (info and type(want) == "table") then return nil end
    local nPre = PF.PresetCount()
    if type(want.preset) == "number" then
        return (want.preset >= 1 and want.preset <= nPre) and want.preset or nil
    end
    for i, l in ipairs(info.layouts) do
        if l.layoutName == want.name then return nPre + i end
    end
    return nil
end

function PF.IsOurs(active) return type(active) == "table" and active.name == PF.LAYOUT_NAME end

-- Name zum Anzeigen.
function PF.LayoutLabel(want)
    if type(want) ~= "table" then return "unbekannt" end
    if want.name then return "„" .. want.name .. "“" end
    local pm = _G.EditModePresetLayoutManager
    if type(pm) == "table" and type(pm.GetCopyOfPresetLayouts) == "function" then
        local ok, list = pcall(pm.GetCopyOfPresetLayouts, pm)
        local p = ok and type(list) == "table" and list[want.preset]
        if type(p) == "table" and type(p.layoutName) == "string" then
            return "„" .. p.layoutName .. "“ (Vorlage des Spiels)"
        end
    end
    return "Vorlage " .. tostring(want.preset) .. " des Spiels"
end

local function SetActive(index)
    local em = _G.C_EditMode
    if not (em and em.SetActiveLayout) then return false end
    return (pcall(em.SetActiveLayout, index))
end

--------------------------------------------------
-- Merken und zurueckgeben
--------------------------------------------------

-- Was vor dem Einschalten aktiv war, oder nil.
function PF.Before()
    local ui = Root()
    return ui and ui.before or nil
end

-- Das aktive Layout merken - nur einmal, bis es zurueckgegeben ist.
-- Ist schon "WeintCodex" aktiv, gibt es nichts zu merken (layout = nil).
-- true, wenn jetzt gemerkt wurde.
function PF.Remember()
    local ui = Root()
    if not ui or ui.before then return false end
    -- Sagt der Client nichts, wird auch nichts gemerkt - sonst stuende ein
    -- leeres "vorher" da und versperrte das echte (die Einrichtung merkt
    -- nach dem Neuladen noch einmal).
    local info = PF.Layouts()
    if not info then return false end
    local a = PF.Active(info)
    if PF.IsOurs(a) then a = nil end
    ui.before = { layout = a }
    return true
end

-- "WeintCodex" aktiv setzen, wenn es das gibt. true / false (gibt es
-- nicht oder ging nicht) / nil (der Client sagt nichts).
function PF.Enter()
    local info = PF.Layouts()
    if not info then return nil end
    if PF.IsOurs(PF.Active(info)) then return true end
    local idx = PF.IndexOf({ name = PF.LAYOUT_NAME }, info)
    if not idx then return false end
    return SetActive(idx)
end

-- Das Layout von vorher zurueck. Gibt zurueck, was geschah:
--   "kept"     - es war gar nicht "WeintCodex" aktiv, nichts angefasst
--   "restored" - das gemerkte Layout ist wieder aktiv
--   "fallback" - nichts gemerkt (oder geloescht): Ersatz aktiv
--   nil        - der Client sagt nichts oder es ging nicht
-- und das Layout, das jetzt aktiv ist.
function PF.Leave()
    local ui = Root()
    local info = PF.Layouts()
    if not info then return nil end
    local before = ui and ui.before
    if not PF.IsOurs(PF.Active(info)) then
        if ui then ui.before = nil end
        return "kept", PF.Active(info)
    end
    local want = before and before.layout
    local idx = want and PF.IndexOf(want, info)
    local how = "restored"
    if not idx then
        how = "fallback"
        want = nil
        for _, l in ipairs(info.layouts) do
            if l.layoutName ~= PF.LAYOUT_NAME then want = { name = l.layoutName } break end
        end
        want = want or { preset = 1 }
        idx = PF.IndexOf(want, info)
    end
    if not (idx and SetActive(idx)) then return nil end
    if ui then ui.before = nil end
    return how, want
end

--------------------------------------------------
-- Spieleinstellungen
--------------------------------------------------

function PF.GetCVar(name)
    local cv = _G.C_CVar
    local fn = (cv and cv.GetCVar) or _G.GetCVar
    if type(fn) ~= "function" then return nil end
    local ok, v = pcall(fn, name)
    return (ok and type(v) == "string") and v or nil
end

local function RawSet(name, value)
    local cv = _G.C_CVar
    local fn = (cv and cv.SetCVar) or _G.SetCVar
    if type(fn) ~= "function" then return false end
    return (pcall(fn, name, value))
end

-- Eine Spieleinstellung setzen und den Wert von vorher merken (nur den
-- allerersten - eine zweite Aenderung ueberschreibt das Original nicht).
-- false, wenn der Client sie nicht kennt oder ablehnt.
function PF.SetCVar(name, value, owner)
    value = tostring(value)
    local old = PF.GetCVar(name)
    if old == nil then return false end
    if not RawSet(name, value) then return false end
    local ui = Root()
    if ui then
        ui.cvars = ui.cvars or {}
        local rec = ui.cvars[name]
        if rec then
            rec.set, rec.owner = value, owner or rec.owner
        elseif old ~= value then
            ui.cvars[name] = { orig = old, set = value, owner = owner or "ui" }
        end
    end
    return true
end

-- Laeuft der Besitzer (nach dem naechsten Laden)?
function PF.OwnerWants(owner)
    if owner == "ui" or owner == nil then return K.UIEnabled() end
    return K.WantsActive(owner)
end

-- Eine gemerkte Einstellung zurueckgeben: den alten Wert, wenn noch
-- UNSER Wert steht; sonst gilt, was der Spieler inzwischen gewaehlt hat.
-- true, wenn zurueckgestellt.
function PF.Release(name)
    local ui = Root()
    local rec = ui and ui.cvars and ui.cvars[name]
    if not rec then return false end
    ui.cvars[name] = nil
    return PF.GetCVar(name) == rec.set and RawSet(name, rec.orig) or false
end

-- Gibt zurueck, was kein laufender Teil mehr braucht. Zahl der
-- zurueckgestellten Werte.
function PF.Sweep()
    local ui = Root()
    if not (ui and ui.cvars) then return 0 end
    local names = {}
    for name, rec in pairs(ui.cvars) do
        if not PF.OwnerWants(rec.owner) then names[#names + 1] = name end
    end
    local n = 0
    for _, name in ipairs(names) do
        if PF.Release(name) then n = n + 1 end
    end
    return n
end

--------------------------------------------------
-- Der Hauptschalter (aus K.SetUIEnabled)
--------------------------------------------------

local function Switch(on)
    if on then
        PF.Remember()
        PF.Enter()
        return
    end
    local how, now = PF.Leave()
    if how == "restored" then
        Say("Dein Layout " .. PF.LayoutLabel(now) .. " ist wieder aktiv.")
    elseif how == "fallback" then
        Say("Welches Layout du vorher hattest, weiß WeintCodex nicht – aktiv ist jetzt "
            .. PF.LayoutLabel(now) .. ". Wählen kannst du im Bearbeitungsmodus (Esc → Bearbeitungsmodus).")
    end
    local n = PF.Sweep()
    if n > 0 then Say(n .. (n == 1 and " Spieleinstellung" or " Spieleinstellungen") .. " wie vorher.") end
end

-- Im Kampf laesst sich kein Layout wechseln: danach.
function PF.OnSwitch(on)
    if K.InCombat() then
        K.AfterCombat(function() Switch(K.UIEnabled()) end)
        return
    end
    Switch(on)
end
