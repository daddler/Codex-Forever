--------------------------------------------------
-- WeintCodex :: Oberflaeche - Einrichtung beim ersten Mal
--------------------------------------------------
-- Beta-Test 6.6.1.0: "Wenn man das UI das erste Mal nutzt, sollen die
-- Fenster direkt voreingestellt sein wie bei Ellesmere. Ein Reload danach
-- packt alle Fenster auf die richtige Position. Danach kann man immer noch
-- im Bearbeitungs- oder Gestaltungsmodus verschieben."
-- Beta-Test 6.6.1.2: "wcui einrichten nimmt nicht alle Sachen mit.
-- Chatfenster bleibt zB so, wie das vorherige UI es eingestellt hatte.
-- WeintCodex soll erstmal ALLES komplett einstellen."
--
-- WAS DIE EINRICHTUNG STELLT (seit 6.6.1.3):
--   1. Die Rahmen des Spiels. Die stellt der Bearbeitungsmodus, und seine
--      Layouts gehoeren dem Spiel. WeintCodex legt EIN eigenes Layout
--      "WeintCodex" an: Grundlage ist die Vorlage des Spiels ("Modern"),
--      nie mehr das Layout eines anderen Addons - 6.6.1.2 kopierte das
--      aktive Layout, und damit blieb der Chat, wo EllesmereUI ihn hatte.
--      Darauf setzt es JEDEN Rahmen aus K.GAME_LAYOUT (ui/layout.lua) an
--      einen festen Platz - fest heisst: nie "Standardplatz", denn den
--      rechnet das Spiel (6.6.1.1: die Vorlage stellte die Aktionsleisten
--      unten links). Gruppe schlachtzugsartig, ohne Blizzards Linien.
--   2. Wenige Spieleinstellungen, die die Oberflaeche voraussetzt (CVARS).
--      Jede wird nur gesetzt, wenn der Client sie kennt, und ueber
--      ui/profile.lua: der Wert von vorher kommt zurueck, wenn die
--      Oberflaeche aus ist.
--   NICHT MEHR (seit 6.9.0.0): die Chatfenster. 6.6.1.3 setzte sie zurueck
--   (FCF_ResetChatWindows) - damit verschwanden eigene Reiter und Kanaele
--   unwiederbringlich, und die speichert das Spiel nur einmal je
--   Charakter. Beta-Test: "damit nichts geloescht oder ueberschrieben
--   wird". Wo der Chat steht, stellt weiter das Layout.
--   Was der Spieler selbst gebaut hat, bleibt (seit 6.6.1.4): die Plaetze
--   des Abklingzeitmanagers (ES.KeepPersonal) und die eigenen Rahmen von
--   WeintCodex, die er im Gestaltungsmodus verschoben hat.
-- Die Skalierung der Oberflaeche bleibt, wie sie ist: das ist eine Frage
-- von Bildschirm und Augen, nicht vom Aussehen.
-- Danach NEU LADEN - erst dann stellt das Spiel alles nach dem neuen
-- Layout und liest es frisch vom Server. Bis dahin gilt es als "von
-- WeintCodex beruehrt", und das Spiel koennte im Kampf Aktionen sperren.
--
-- WOHER WEISS WEINTCODEX, DASS ES SCHON EINGERICHTET IST? Am Layout
-- selbst: gibt es eins namens "WeintCodex", fragt nichts mehr. Das liegt
-- auf dem Server und kommt auch dann mit, wenn der Beta-Client die
-- SavedVariables vergisst.
--
-- Ob C_EditMode im Forever-Client genauso heisst und funktioniert, ist
-- ungeprueft. Fehlt etwas, sagt das Fenster es - nie ein stilles "fertig".
-- Was nach dem Neuladen wirklich wo steht, sagt /wcui einrichten pruefen.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UISetup = {}

local ES = WeintCodex.UISetup
local K  = WeintCodex.UIKit
local C  = WeintCodex.Colors
local F  = WeintCodex.Fonts

-- Der Name lebt in ui/profile.lua: dort wird das Layout gemerkt und
-- zurueckgegeben.
ES.LAYOUT_NAME = WeintCodex.UIProfile.LAYOUT_NAME

local function Say(text)
    print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " " .. text)
end

local function Copy(t)
    if type(t) ~= "table" then return t end
    local out = {}
    for k, v in pairs(t) do out[k] = Copy(v) end
    return out
end

--------------------------------------------------
-- Das Layout
--------------------------------------------------

-- Die Layouts des Spiels oder nil, Grund.
local function Layouts()
    local em = _G.C_EditMode
    if not (em and em.GetLayouts and em.SaveLayouts) then return nil, "C_EditMode fehlt" end
    local ok, info = pcall(em.GetLayouts)
    if not ok or type(info) ~= "table" or type(info.layouts) ~= "table" then
        return nil, "GetLayouts antwortet nicht"
    end
    return info
end

-- Gibt es das Layout schon? true / false / nil (der Client sagt es nicht).
function ES.HasLayout()
    local info = Layouts()
    if not info then return nil end
    for _, l in ipairs(info.layouts) do
        if l.layoutName == ES.LAYOUT_NAME then return true end
    end
    return false
end

-- Die Vorlagen des Spiels ("Modern", "Klassisch") - nur ihre Zahl zaehlt
-- fuer den Index des aktiven Layouts, und "Modern" ist die Grundlage.
local function Presets()
    local pm = _G.EditModePresetLayoutManager
    if type(pm) == "table" and type(pm.GetCopyOfPresetLayouts) == "function" then
        local ok, list = pcall(pm.GetCopyOfPresetLayouts, pm)
        if ok and type(list) == "table" and #list > 0 then return list end
    end
    return nil
end

-- Ist das Layout bei DIESEM Charakter aktiv? true / false / nil.
-- 6.26.17.0 (Beta-Test: "nach der Installation ist alles durcheinander"):
-- Layouts gelten fuer den Account, welches aktiv ist, je Charakter. Bis
-- dahin richtete der Assistent nur ein, wenn es das Layout noch nicht gab -
-- ein zweiter Charakter blieb auf der Vorlage des Spiels, waehrend die
-- Rahmen von WeintCodex schon auf ihren Plaetzen standen.
function ES.LayoutActive()
    local info = Layouts()
    if not info then return nil end
    local presets = Presets()
    local n = presets and #presets or 2
    for i, l in ipairs(info.layouts) do
        if l.layoutName == ES.LAYOUT_NAME then return K.Plain(info.activeLayout) == n + i end
    end
    return false
end

local function SetSetting(sys, setting, value)
    if type(setting) ~= "number" then return false end
    sys.settings = sys.settings or {}
    for _, st in ipairs(sys.settings) do
        if st.setting == setting then st.value = value return true end
    end
    sys.settings[#sys.settings + 1] = { setting = setting, value = value }
    return true
end

-- Der Platz eines Eintrags aus K.GAME_LAYOUT (oder, mit `from`, der Platz
-- eines eigenen Rahmens aus K.LAYOUT).
local function Target(e)
    local p = e.from and K.LAYOUT[e.from] or e
    return { point = p.point, relPoint = p.relPoint or p.point, x = p.x, y = p.y }
end
ES.Target = Target

-- Welche Enums zu welchem System gehoeren (Indizes und Einstellungen).
local INDICES = {
    ActionBar = "EditModeActionBarSystemIndices", UnitFrame = "EditModeUnitFrameSystemIndices",
    AuraFrame = "EditModeAuraFrameSystemIndices", CooldownViewer = "EditModeCooldownViewerSystemIndices",
}
local SETTINGS = {
    ActionBar = "EditModeActionBarSetting", UnitFrame = "EditModeUnitFrameSetting",
    ChatFrame = "EditModeChatFrameSetting", CooldownViewer = "EditModeCooldownViewerSetting",
    AuraFrame = "EditModeAuraFrameSetting", ObjectiveTracker = "EditModeObjectiveTrackerSetting",
}

local function EnumTable(name)
    local E = _G.Enum
    local t = type(E) == "table" and name and E[name]
    return type(t) == "table" and t or nil
end

-- Das System eines Eintrags im Layout, oder nil.
local function Find(systems, e)
    local S = EnumTable("EditModeSystem")
    local sysId = S and S[e.sys]
    if type(sysId) ~= "number" then return nil end
    local idx
    if e.idx then
        local I = EnumTable(INDICES[e.sys])
        idx = I and I[e.idx]
        if type(idx) ~= "number" then return nil end
    end
    for _, sys in ipairs(systems or {}) do
        if sys.system == sysId and (not e.idx or sys.systemIndex == idx) then return sys end
    end
    return nil
end

-- Schieberegler speichert der Bearbeitungsmodus nicht als angezeigten
-- Wert (80 %), sondern umgerechnet. Die Umrechnung steht in seiner
-- eigenen Beschreibung des Reglers (EditModeSettingDisplayInfoManager):
-- erst seine Funktion, sonst (Wert - Minimum) / Schritt. Nur ein Wert im
-- Bereich des Reglers zaehlt; sonst nil - dann bleibt die Vorlage.
-- clamp: ein Wert ausserhalb des Reglers wird auf dessen Rand gesetzt
-- (Hoehe der Questliste haengt an der Bildschirmhoehe, 6.6.3.4).
function ES.RawValue(sysId, setting, display, clamp)
    local M = _G.EditModeSettingDisplayInfoManager
    if type(M) ~= "table" or type(setting) ~= "number" then return nil end
    local list = type(M.systemSettingDisplayInfo) == "table" and M.systemSettingDisplayInfo[sysId] or nil
    if type(list) ~= "table" and type(M.GetSystemSettingDisplayInfo) == "function" then
        local ok, l = pcall(M.GetSystemSettingDisplayInfo, M, sysId)
        list = ok and l or nil
    end
    for _, info in ipairs(type(list) == "table" and list or {}) do
        if type(info) == "table" and info.setting == setting then
            local lo, hi, step = info.minValue, info.maxValue, info.stepSize
            local maxRaw = (type(lo) == "number" and type(hi) == "number" and type(step) == "number" and step > 0)
                and (hi - lo) / step or nil
            local function InRange(v)
                return type(v) == "number" and v >= 0 and (not maxRaw or v <= maxRaw)
            end
            if type(info.ConvertValue) == "function" then
                local ok, v = pcall(info.ConvertValue, info, display, false)
                if ok and InRange(v) then return v end
            end
            if maxRaw then
                local v = (display - lo) / step
                if InRange(v) then return v end
                if clamp then return math.max(0, math.min(maxRaw, math.floor(v + 0.5))) end
            end
            return nil
        end
    end
    return nil
end

-- Alle Rahmen aus K.GAME_LAYOUT ins Layout schreiben. Gibt zurueck, was
-- gesetzt wurde ({ [key] = true }) und was im Layout fehlt (Namen).
function ES.Adjust(systems)
    local done, missing = {}, {}
    for _, e in ipairs(K.GAME_LAYOUT) do
        local sys = Find(systems, e)
        if sys then
            local t = Target(e)
            sys.anchorInfo = { point = t.point, relativeTo = "UIParent", relativePoint = t.relPoint,
                               offsetX = t.x, offsetY = t.y }
            sys.isInDefaultPosition = false
            local SE = EnumTable(SETTINGS[e.sys])
            for name, value in pairs(e.set or {}) do
                if SetSetting(sys, SE and SE[name], value) then done[e.key .. "." .. name] = true end
            end
            for name, value in pairs(e.display or {}) do
                if type(value) == "function" then value = value() end
                local raw = type(value) == "number" and ES.RawValue(sys.system, SE and SE[name], value, e.clamp) or nil
                if type(raw) == "number" and SetSetting(sys, SE[name], raw) then done[e.key .. "." .. name] = true end
            end
            for name, pair in pairs(e.enum or {}) do
                local EN = EnumTable(pair[1])
                local v = EN and EN[pair[2]]
                if type(v) == "number" and SetSetting(sys, SE and SE[name], v) then done[e.key .. "." .. name] = true end
            end
            done[e.key] = true
        else
            missing[#missing + 1] = e.label
        end
    end
    return done, missing
end

-- WORAUF WIRD AUFGEBAUT? Auf der Vorlage des Spiels ("Modern", die erste)
-- - sie traegt jedes System mit gueltigen Einstellungen, und was WeintCodex
-- nicht stellt, steht dann dort, wo das Spiel es hinstellt, nicht dort,
-- wo ein frueheres Addon es liess. Nur wenn der Client keine Vorlage
-- nennt, das aktive eigene Layout (nie "WeintCodex" selbst).
-- Gibt das Layout und seinen Namen zurueck.
function ES.Base(info, presets)
    local p = presets and presets[1]
    if type(p) == "table" and type(p.systems) == "table" then return p, p.layoutName end
    local nPre = presets and #presets or 2
    local active = tonumber(info.activeLayout) or 0
    local l = info.layouts[active - nPre]
    if l and l.layoutName ~= ES.LAYOUT_NAME and type(l.systems) == "table" then return l, l.layoutName end
    for _, o in ipairs(info.layouts) do
        if o.layoutName ~= ES.LAYOUT_NAME and type(o.systems) == "table" then return o, o.layoutName end
    end
    return nil
end

function ES.BaseName()
    local info = Layouts()
    if not info then return nil end
    local _, name = ES.Base(info, Presets())
    return name
end

-- WAS DER SPIELER SELBST GEBAUT HAT, BLEIBT. Der Abklingzeitmanager ist
-- keine Frage des Aussehens: welche Zauber er zeigt und wo, stellt jeder
-- selbst ein (Beta-Test 6.6.1.3: "Der Abklingzeitmanager hat auch einige
-- Sachen neu bewegt"). Seine Plaetze kommen deshalb aus dem aktiven
-- Layout. Ist das schon "WeintCodex" und stehen dort noch die Plaetze
-- von WeintCodex (nie verschoben), aus dem ersten anderen eigenen Layout -
-- so kommt zurueck, was vor der ersten Einrichtung dort stand.
local function IsPersonal(e) return e.personal == true end

local function Untouched(layout)
    for _, e in ipairs(K.GAME_LAYOUT) do
        if IsPersonal(e) then
            local sys = Find(layout.systems, e)
            local a = sys and sys.anchorInfo
            if a and not (a.offsetX == e.x and a.offsetY == e.y and a.point == e.point) then return false end
        end
    end
    return true
end

function ES.PersonalSource(info, presets)
    local nPre = presets and #presets or 2
    local active = info.layouts[(tonumber(info.activeLayout) or 0) - nPre]
    if not (active and type(active.systems) == "table") then return nil end
    if active.layoutName ~= ES.LAYOUT_NAME or not Untouched(active) then return active end
    for _, o in ipairs(info.layouts) do
        if o.layoutName ~= ES.LAYOUT_NAME and type(o.systems) == "table" then return o end
    end
    return nil
end

-- Die PLAETZE aller Systeme des Abklingzeitmanagers aus `source`
-- uebernehmen - Groesse und Sichtbarkeit stellt WeintCodex (seit
-- 6.6.1.5; vorher kam alles mit, auch die doppelte Buff-Anzeige).
-- Gibt die Zahl und den Namen der Quelle zurueck.
function ES.KeepPersonal(systems, source)
    if not source then return 0, nil end
    local S = EnumTable("EditModeSystem")
    local cdm = S and S.CooldownViewer
    if type(cdm) ~= "number" then return 0, nil end
    -- Nur Systeme, die K.GAME_LAYOUT `personal` nennt - die Buff-Symbole
    -- stellt WeintCodex selbst an den Spielerrahmen (6.6.1.7).
    local I = EnumTable(INDICES.CooldownViewer)
    local mine = {}
    for _, e in ipairs(K.GAME_LAYOUT) do
        if e.sys == "CooldownViewer" and IsPersonal(e) and I and type(I[e.idx]) == "number" then mine[I[e.idx]] = true end
    end
    local n = 0
    for _, from in ipairs(source.systems) do
        if from.system == cdm and mine[from.systemIndex] then
            for _, to in ipairs(systems) do
                if to.system == cdm and to.systemIndex == from.systemIndex and type(from.anchorInfo) == "table" then
                    to.anchorInfo = Copy(from.anchorInfo)
                    to.isInDefaultPosition = from.isInDefaultPosition
                    n = n + 1
                end
            end
        end
    end
    return n, source.layoutName
end

-- Das Layout anlegen und aktiv setzen. true oder false, Grund.
local function ApplyLayout(report)
    local info, why = Layouts()
    if not info then return false, why end
    local presets = Presets()
    local base = ES.Base(info, presets)
    if not (base and type(base.systems) == "table") then return false, "keine Grundlage (kein Layout lesbar)" end

    local layout = Copy(base)
    layout.layoutName = ES.LAYOUT_NAME
    local LT = EnumTable("EditModeLayoutType")
    layout.layoutType = LT and LT.Account or layout.layoutType
    local done, missing = ES.Adjust(layout.systems)
    if not done.party then return false, "Gruppenrahmen im Layout nicht gefunden" end
    report.kept, report.keptFrom = ES.KeepPersonal(layout.systems, ES.PersonalSource(info, presets))
    local n = 0
    for _, e in ipairs(K.GAME_LAYOUT) do if done[e.key] then n = n + 1 end end
    report.frames, report.missing = n, missing

    -- Ein altes "WeintCodex" (von einem frueheren Einrichten) ersetzen.
    local slot
    for i, l in ipairs(info.layouts) do
        if l.layoutName == ES.LAYOUT_NAME then slot = i end
    end
    slot = slot or (#info.layouts + 1)
    info.layouts[slot] = layout
    info.activeLayout = (presets and #presets or 2) + slot

    local em = _G.C_EditMode
    local ok, err = pcall(em.SaveLayouts, info)
    if not ok then return false, "SaveLayouts: " .. tostring(err) end
    if em.SetActiveLayout then pcall(em.SetActiveLayout, info.activeLayout) end
    ES.done = done
    return true
end

-- Spieleinstellungen, die die Oberflaeche voraussetzt - jede mit Grund.
ES.CVARS = {
    -- Eingabezeile nur beim Schreiben: darunter liegt die Infozeile.
    { name = "chatStyle", value = "im" },
    -- Gefluestertes im Chat, statt dass Reiter aufspringen.
    { name = "whisperMode", value = "inline" },
    -- Namen im Chat in Klassenfarbe (0 = Farbe NICHT abschalten).
    { name = "chatClassColorOverride", value = "0" },
    -- Knoepfe nicht versehentlich aus der Leiste ziehen (Umschalt zieht).
    { name = "lockActionBars", value = "1" },
    -- Keine Tutorial-Fenster ueber den Rahmen.
    { name = "showTutorials", value = "0" },
    -- AUFLOESUNG (6.26.14.0, Beta-Test auf 2560x1440: "alles verschoben").
    -- Jeder Platz in ui/layout.lua ist in Einheiten einer Oberflaeche von
    -- 768 Einheiten Hoehe gerechnet. Die Hoehe in Einheiten haengt nicht an
    -- der Aufloesung, sondern an der Skalierung: 768 / uiScale - und ohne
    -- "UI-Skalierung verwenden" rechnet das Spiel sie selbst aus der
    -- Bildschirmhoehe (auf 1440p und 4K eine viel hoehere Oberflaeche). Mit
    -- Skalierung 1 ist sie auf 1080p, 1440p und 4K gleich hoch, und alles
    -- steht im selben Verhaeltnis zum Bildschirm. Zurueck beim Ausschalten
    -- wie jede Einstellung hier (ui/profile.lua).
    { name = "uiScale", value = "1" },
    { name = "useUiScale", value = "1" },
}
ES.DESIGN_HEIGHT = 768

-- Bildschirm und Oberflaeche, fuer den Bericht.
function ES.ScreenLine()
    local pw, ph
    if _G.GetPhysicalScreenSize then
        local ok, a, b = pcall(_G.GetPhysicalScreenSize)
        if ok then pw, ph = K.Plain(a), K.Plain(b) end
    end
    local uh = K.Plain(UIParent.GetHeight and UIParent:GetHeight())
    local uw = K.Plain(UIParent.GetWidth and UIParent:GetWidth())
    if type(uh) ~= "number" then return nil end
    local line = string.format("Oberfläche: %d × %d Einheiten", math.floor((uw or 0) + 0.5), math.floor(uh + 0.5))
    if type(pw) == "number" and type(ph) == "number" then
        line = line .. string.format(" auf %d × %d Bildpunkten", pw, ph)
    end
    if math.abs(uh - ES.DESIGN_HEIGHT) > 2 then
        line = line .. string.format(" – entworfen für %d hoch: /wcui einrichten stellt die Skalierung ein", ES.DESIGN_HEIGHT)
    end
    return line
end

local function GetCVarValue(name)
    local cv = _G.C_CVar
    local fn = (cv and cv.GetCVar) or _G.GetCVar
    if type(fn) ~= "function" then return nil end
    local ok, v = pcall(fn, name)
    return ok and v or nil
end

-- Gibt zurueck, wie viele gesetzt wurden, und die unbekannten. Jeder
-- Wert von vorher wird gemerkt (ui/profile.lua, Besitzer "ui").
local function ApplyCVars()
    local PF = WeintCodex.UIProfile
    local n, unknown = 0, {}
    for _, c in ipairs(ES.CVARS) do
        if PF.SetCVar(c.name, c.value, "ui") then
            n = n + 1
        else
            unknown[#unknown + 1] = c.name
        end
    end
    return n, unknown
end

-- Alles einrichten. true oder false, Grund; ES.report sagt, was geschah.
function ES.Apply()
    if K.InCombat() then return false, "im Kampf" end
    local report = {}
    ES.report = report
    -- Erst merken, was vorher galt - dann erst umstellen.
    WeintCodex.UIProfile.Remember()
    local ok, why = ApplyLayout(report)
    if not ok then return false, why end
    report.cvars, report.unknownCVars = ApplyCVars()
    -- Nach dem Neuladen selbst nachsehen (6.26.18.0).
    local root = K.Root()
    if root then root.setupVerify = true end
    -- Die eigenen Rahmen bleiben, wo der Spieler sie im Gestaltungsmodus
    -- hingezogen hat (6.6.1.3 setzte sie zurueck - Beta-Test: die
    -- Schadensanzeige wanderte von oben links nach unten rechts). Ohne
    -- gespeicherte Plaetze stehen sie ohnehin an ihrem Standardplatz.
    return true
end

--------------------------------------------------
-- Pruefen: steht alles, wo es stehen soll?
--------------------------------------------------
-- Nach dem Neuladen: /wcui einrichten pruefen. Misst je Rahmen den Punkt,
-- an dem er haengen soll, in seinen eigenen Einheiten (so rechnet auch
-- SetPoint) und vergleicht mit dem Platz aus K.GAME_LAYOUT.

local function Num(f, m)
    if type(f) ~= "table" or type(f[m]) ~= "function" then return nil end
    local ok, v = pcall(f[m], f)
    v = ok and K.Plain(v) or nil
    return type(v) == "number" and v or nil
end

local function PointXY(f, point)
    local l, r, t, b = Num(f, "GetLeft"), Num(f, "GetRight"), Num(f, "GetTop"), Num(f, "GetBottom")
    if not (l and r and t and b) then return nil end
    local x = point:find("LEFT") and l or (point:find("RIGHT") and r or (l + r) / 2)
    local y = point:find("TOP") and t or (point:find("BOTTOM") and b or (t + b) / 2)
    return x, y
end

local function FrameOf(e)
    for _, n in ipairs(e.frames or {}) do
        local f = _G[n]
        if type(f) == "table" and type(f.GetLeft) == "function" then return f end
    end
    return nil
end

-- Zeilen fuer den Chat: je Rahmen "passt", "weicht ab (Ist ...)" oder
-- "nicht messbar"; zuerst, welches Layout aktiv ist.
function ES.Check()
    local out = {}
    local info = Layouts()
    if info then
        local presets = Presets()
        local nPre = presets and #presets or 2
        local active = tonumber(info.activeLayout) or 0
        local l = active > nPre and info.layouts[active - nPre]
        local name = l and l.layoutName or (presets and presets[active] and presets[active].layoutName)
        out[#out + 1] = "Aktives Layout: " .. tostring(name or "?")
            .. (name == ES.LAYOUT_NAME and "" or " – nicht „WeintCodex“, /wcui einrichten")
    else
        out[#out + 1] = "Layouts nicht lesbar."
    end
    local ui = _G.UIParent
    local good, bad, unknown = 0, {}, {}
    for _, e in ipairs(K.GAME_LAYOUT) do
      -- Der Abklingzeitmanager steht, wo der Spieler ihn hatte - kein Soll.
      if not IsPersonal(e) then
        local f = FrameOf(e)
        local t = Target(e)
        -- Nie "f and PointXY(...)": das `and` schneidet den zweiten
        -- Rueckgabewert ab (6.6.1.3: fy blieb nil, die Pruefung brach ab).
        local fx, fy
        if f then fx, fy = PointXY(f, t.point) end
        local ux, uy = PointXY(ui, t.relPoint)
        local fs, us = Num(f, "GetEffectiveScale"), Num(ui, "GetEffectiveScale")
        local shown = f and Num(f, "GetWidth")
        if not (fx and fy and ux and uy and fs and us and fs > 0) or not shown or shown <= 0 then
            unknown[#unknown + 1] = e.label
        else
            local dx = fx - ux * us / fs
            local dy = fy - uy * us / fs
            if math.abs(dx - t.x) <= 3 and math.abs(dy - t.y) <= 3 then
                good = good + 1
            else
                bad[#bad + 1] = string.format("%s: soll %s %d/%d, ist %d/%d", e.label, t.point, t.x, t.y,
                    math.floor(dx + 0.5), math.floor(dy + 0.5))
            end
        end
      end
    end
    out[#out + 1] = string.format("%d Rahmen am Platz, %d daneben, %d nicht messbar (versteckt oder nicht da).",
        good, #bad, #unknown)
    local activeOk = ES.LayoutActive() == true
    local uh = K.Plain(UIParent.GetHeight and UIParent:GetHeight())
    ES.lastCheck = { layoutRead = info and true or false, active = activeOk, good = good, bad = #bad,
                     unknown = #unknown, scaleOk = type(uh) ~= "number" or math.abs(uh - ES.DESIGN_HEIGHT) <= 2 }
    for _, line in ipairs(bad) do out[#out + 1] = line end
    if #unknown > 0 then out[#out + 1] = "Nicht messbar: " .. table.concat(unknown, ", ") end
    local cf = _G.ChatFrame1
    local w, h = Num(cf, "GetWidth"), Num(cf, "GetHeight")
    if w and h then
        out[#out + 1] = string.format("Chatgröße: soll %d × %d, ist %d × %d", K.CHAT_SIZE.w, K.CHAT_SIZE.h,
            math.floor(w + 0.5), math.floor(h + 0.5))
    end
    local sl = ES.ScreenLine()
    if sl then out[#out + 1] = sl end
    for _, c in ipairs(ES.CVARS) do
        local v = GetCVarValue(c.name)
        if type(v) == "string" and v ~= c.value and not (tonumber(v) and tonumber(v) == tonumber(c.value)) then
            out[#out + 1] = "Einstellung " .. c.name .. ": soll " .. c.value .. ", ist " .. v
        end
    end
    -- Welcher Weg in den Bearbeitungsmodus fuehrt (Bruecke, ui/editmode.lua).
    local E = WeintCodex.UIEditMode
    if E and E.Report then out[#out + 1] = E.Report() end
    return out
end

--------------------------------------------------
-- Das Fenster (dieselbe Form wie die Frage beim Einloggen)
--------------------------------------------------

local WIN_W, WIN_H = 520, 300
local dimmer, win, eyebrow, title, body
local buttons, byKey = {}, {}

local function Close() if dimmer then dimmer:Hide() end end

local function Build()
    if dimmer then return end
    dimmer = CreateFrame("Frame", "WeintCodexUISetup", UIParent)
    dimmer:SetAllPoints(UIParent)
    dimmer:SetFrameStrata("DIALOG")
    dimmer:EnableMouse(true)
    local shade = dimmer:CreateTexture(nil, "BACKGROUND")
    shade:SetAllPoints(dimmer)
    shade:SetColorTexture(0, 0, 0, 0.6)
    dimmer:Hide()

    win = CreateFrame("Frame", nil, dimmer)
    win:SetSize(WIN_W, WIN_H)
    win:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
    win:SetFrameLevel(dimmer:GetFrameLevel() + 10)
    local bg = win:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(win)
    bg:SetColorTexture(unpack(C.surface2))
    WeintCodex.DrawBorder(win, C.borderStrong[1], C.borderStrong[2], C.borderStrong[3], 1, 1)
    local top = win:CreateTexture(nil, "ARTWORK")
    top:SetHeight(1)
    top:SetPoint("TOPLEFT", win, "TOPLEFT", 8, 0)
    top:SetPoint("TOPRIGHT", win, "TOPRIGHT", -8, 0)
    top:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.34)

    eyebrow = K.NewText(win)
    eyebrow:SetFont(F.mono, 10, "")
    eyebrow:SetTextColor(unpack(C.accent))
    eyebrow:SetPoint("TOPLEFT", win, "TOPLEFT", 28, -26)
    title = K.NewText(win)
    title:SetFont(F.sansBold, 20, "")
    title:SetTextColor(unpack(C.textBright))
    title:SetPoint("TOPLEFT", eyebrow, "BOTTOMLEFT", 0, -8)
    title:SetWidth(WIN_W - 56)
    title:SetJustifyH("LEFT")
    body = K.NewText(win)
    body:SetFont(F.sans, 13, "")
    body:SetTextColor(unpack(C.textNormal))
    body:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -14)
    body:SetWidth(WIN_W - 56)
    body:SetJustifyH("LEFT")
    body:SetJustifyV("TOP")
    body:SetSpacing(4)
end

local function SetButtons(defs)
    for _, b in ipairs(buttons) do b:Hide() end
    wipe(buttons)
    local anchor
    for i = #defs, 1, -1 do
        local d = defs[i]
        local b = byKey[d.key]
        if not b then
            if d.reload then
                b = K.ReloadButton(win, { text = d.text, height = 34, size = 12, backdrop = "surface2",
                    onClick = d.onClick })
            else
                b = WeintCodex.CreateButton(win, { text = d.text, kind = d.kind or "secondary", height = 34,
                    size = 12, backdrop = "surface2", onClick = d.onClick })
            end
            byKey[d.key] = b
        end
        b:ClearAllPoints()
        b:Show()
        if anchor then b:SetPoint("RIGHT", anchor, "LEFT", -10, 0)
        else b:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", -28, 24) end
        anchor = b
        b._key = d.key
        buttons[#buttons + 1] = b
    end
end

local function SetText(eb, t, text)
    eyebrow:SetText(WeintCodex.Spaced(WeintCodex.Upper(eb)))
    title:SetText(t)
    body:SetText(text)
    local ok, h = pcall(body.GetStringHeight, body)
    if not ok or type(h) ~= "number" then h = 0 end
    win:SetHeight(math.max(WIN_H, math.ceil(h) + 176))
end

local ShowDone, ShowFailed

-- 6.26.18.0 (Beta-Test: "Das Einrichten der UI muss einfacher gemacht
-- werden, der Nutzer mehr an die Hand genommen"). Drei Saetze statt einer
-- Seite, zwei Klicks (Einrichten, Neu laden), und nach dem Neuladen sieht
-- WeintCodex selbst nach (ES.Verify) und sagt in einem Satz, was zu tun ist.
local function ShowQuestion()
    SetText("Schritt 1 von 2",
        "Oberfläche einrichten",
        "WeintCodex stellt Aktionsleisten, Chat, Minikarte, Questliste und Gruppe an feste Plätze"
        .. " und passt die Größe an deinen Bildschirm an.\n\n"
        .. "Dein eigenes Layout und deine Chatreiter bleiben – schaltest du die Oberfläche aus, ist alles wieder wie vorher.")
    SetButtons({
        { key = "later", text = "Später", kind = "secondary", onClick = function()
            Close()
            Say("Einrichten geht jederzeit mit /wcui einrichten.")
        end },
        { key = "apply", text = "Einrichten", kind = "primary", onClick = function()
            local ok, why = ES.Apply()
            if ok then ShowDone() else ShowFailed(why) end
        end },
    })
end

ShowDone = function()
    local r = ES.report or {}
    local miss = (r.missing and #r.missing > 0)
        and ("\n\nNicht im Layout des Spiels gefunden: " .. table.concat(r.missing, ", ") .. ".") or ""
    SetText("Schritt 2 von 2",
        "Eingerichtet – jetzt neu laden",
        "Erst nach dem Neuladen steht alles an seinem Platz. Danach prüft WeintCodex selbst, ob jeder Rahmen"
        .. " richtig steht, und sagt dir Bescheid." .. miss)
    SetButtons({
        { key = "reload", text = "Jetzt neu laden", reload = true },
    })
end

-- Nach dem Neuladen: das Ergebnis in einem Satz, mit dem naechsten Schritt.
function ES.ResultText(c)
    c = c or ES.lastCheck or {}
    if c.layoutRead == false then
        return "Nicht prüfbar", "Das Spiel gibt seine Layouts nicht heraus. Sieh dich kurz um – steht etwas schief,"
            .. " verschiebst du es im Gestaltungsmodus.", "unknown"
    end
    if not c.active then
        return "Noch nicht eingerichtet", "Das Layout „WeintCodex“ ist bei diesem Charakter nicht aktiv."
            .. " Ein Klick auf „Noch einmal einrichten“ behebt das.", "redo"
    end
    if not c.scaleOk then
        return "Größe passt nicht", "Die Skalierung der Oberfläche wurde verändert. „Noch einmal einrichten“"
            .. " stellt sie zurück.", "redo"
    end
    if (c.bad or 0) > 0 then
        return "Fast fertig", string.format("%d Rahmen stehen nicht an ihrem Platz. „Noch einmal einrichten“ setzt"
            .. " sie zurück; was du selbst verschieben willst, verschiebst du im Gestaltungsmodus.", c.bad), "redo"
    end
    return "Alles steht", "Die Oberfläche ist eingerichtet. Verschieben kannst du jeden Rahmen im Gestaltungsmodus"
        .. " (ziehen, Rechtsklick: Einstellungen).", "ok"
end

function ES.ShowResult()
    Build()
    ES.Check()
    local head, text, kind = ES.ResultText()
    SetText("Einrichtung", head, text)
    local defs = {}
    if kind == "redo" then
        defs[#defs + 1] = { key = "close", text = "Schließen", kind = "secondary", onClick = Close }
        defs[#defs + 1] = { key = "redo", text = "Noch einmal einrichten", kind = "primary", onClick = function()
            local ok, why = ES.Apply()
            if ok then ShowDone() else ShowFailed(why) end
        end }
    else
        defs[#defs + 1] = { key = "design", text = "Gestaltungsmodus", kind = "secondary", onClick = function()
            Close()
            K.SetUnlocked(true)
        end }
        defs[#defs + 1] = { key = "done", text = "Fertig", kind = "primary", onClick = Close }
    end
    SetButtons(defs)
    dimmer:Show()
    return kind
end

-- Einmal nach dem Neuladen, das auf "Einrichten" folgt.
function ES.Verify()
    local root = K.Root()
    if not (root and root.setupVerify) then return false end
    if K.InCombat() then K.AfterCombat(ES.Verify) return false end
    root.setupVerify = nil
    ES.ShowResult()
    return true
end

ShowFailed = function(why)
    SetText("Einrichtung",
        "Das Layout ließ sich nicht anlegen",
        "Grund: " .. tostring(why) .. ".\n\nDeine eigenen WeintCodex-Rahmen stehen trotzdem richtig. Für die Gruppe"
        .. " bitte von Hand: Esc → Bearbeitungsmodus → Gruppenrahmen anklicken → „Schlachtzugsartige"
        .. " Gruppenrahmen verwenden“ an, „Rahmen anzeigen“ aus, speichern.")
    SetButtons({
        { key = "close", text = "Schließen", kind = "secondary", onClick = Close },
    })
end

function ES.Show()
    if K.InCombat() then
        Say("Nach dem Kampf – im Kampf lässt sich die Oberfläche nicht einrichten.")
        K.AfterCombat(ES.Show)
        return
    end
    Build()
    ShowQuestion()
    dimmer:Show()
end

function ES.IsShown() return dimmer ~= nil and dimmer:IsShown() end
function ES.Button(key)
    for _, b in ipairs(buttons) do if b._key == key then return b end end
    return nil
end
function ES.BodyText() return body and body:GetText() or "" end

-- Beim ersten echten Einloggen fragen, wenn es noch kein Layout gibt -
-- nie nach einem /reload (sonst stuende die Frage nach "Später" bei jedem
-- Neuladen wieder da), nie ueber der Einfuehrung, nie im Kampf.
local asked = false
function ES.MaybeAsk()
    if asked or ES.LayoutActive() ~= false then return end
    if WeintCodex.Onboarding and WeintCodex.Onboarding.IsShowing and WeintCodex.Onboarding.IsShowing() then
        return   -- kommt ueber OnClosed wieder
    end
    local WL = WeintCodex.UIWelcome
    if WL and WL.IsShown and WL.IsShown() then return end
    asked = true
    K.AfterCombat(ES.Show)
end
ES._ResetAsked = function() asked = false end

if WeintCodex.Onboarding and WeintCodex.Onboarding.OnClosed then
    WeintCodex.Onboarding.OnClosed(function() if not ES._reload then ES.MaybeAsk() end end)
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:SetScript("OnEvent", function(_, _, isInitialLogin, isReloadingUi)
    if not (isInitialLogin or isReloadingUi) then return end
    ES._reload = isReloadingUi and true or false
    if not K.UIEnabled() then return end
    -- Nach dem Einrichten: nachsehen, wenn alles steht (3 s).
    if _G.C_Timer and _G.C_Timer.After then _G.C_Timer.After(3, ES.Verify) end
    if isReloadingUi then return end
    if _G.C_Timer and _G.C_Timer.After then _G.C_Timer.After(2, ES.MaybeAsk) end
end)
