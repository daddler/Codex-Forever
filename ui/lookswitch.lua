--------------------------------------------------
-- WeintCodex :: Oberflaeche - Designwechsel mit Fuehrung
--------------------------------------------------
-- 1.0.7.61 (Wunsch: "fuer Nutzer, die Codex schon so genutzt haben, ein
-- tolles Switching fuer die Konsole - eine Spielerin hat es versucht, es
-- klappte wenig bis gar nichts: EP-Balken des Spiels an, Spielerrahmen zu
-- klein, keine Minikarte, nur die Zierleiste"). Was dabei schiefgeht, wenn
-- jemand nur "Design: Konsole" waehlt und neu laedt:
--   * gespeicherte Plaetze (Gestaltungsmodus) schlagen die der Konsole -
--     Rahmen bleiben, wo sie im alten Design standen;
--   * eigene Groessen von Spieler/Ziel schlagen die der Konsole;
--   * ein ausgeschaltetes Modul (Minikarte, Aktionsleisten mit dem
--     Erfahrungsbalken, Einheitenrahmen) laesst Luecken - der Ring der
--     Karte ist dann leer, der Balken des Spiels bleibt;
--   * das Layout des Bearbeitungsmodus stellte nur um, wenn vorher schon
--     ein Layout von WeintCodex aktiv war.
-- Darum fuehrt der Wechsel jetzt in EINEM Klick durch alles: auf Wunsch
-- ein eigenes Profil (das bisherige bleibt unberuehrt und ist der Weg
-- zurueck), Plaetze und Groessen, die das Design vorgibt, freigeben, die
-- noetigen Teile einschalten, das Layout des Bearbeitungsmodus fuer das
-- Design einrichten, neu laden - und danach nachsehen, ob alles steht, mit
-- einem Knopf, der es noch einmal richtet.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UILookSwitch = {}

local LS = WeintCodex.UILookSwitch
local K  = WeintCodex.UIKit
local C  = WeintCodex.Colors

LS.W, LS.H = 520, 300
-- Was ein Design mit eigener Anordnung braucht (Module, die laufen muessen).
LS.NEEDS = { "unitframes", "actionbars", "minimap" }
-- Einstellungen, die die Konsole selbst setzt, solange sie ab Werk sind -
-- beim Wechsel zurueck auf ab Werk.
LS.UNIT_KEYS = { "player_width", "player_height", "player_powerHeight", "player_portraitRight",
                 "target_width", "target_height", "target_powerHeight", "target_portraitRight" }

local LOOK_NAMES = { schwarz = "Schwarz", transparent = "Transparent", klassisch = "Holz", konsole = "Konsole" }
function LS.LookName(v) return LOOK_NAMES[v or "schwarz"] or tostring(v) end

-- Hat das Design eine eigene Anordnung (Plaetze/Layout)?
local function Arranged(look) return K.LOOK_LAYOUT and K.LOOK_LAYOUT[look or ""] ~= nil end

-- Schluessel der Plaetze, die ein Design vorgibt (eigene und versetzte).
function LS.PlaceKeys(look)
    local out = {}
    local t = K.LOOK_LAYOUT and K.LOOK_LAYOUT[look or ""]
    for k in pairs(t or {}) do out[#out + 1] = k end
    local sh = K.LOOK_SHIFT and K.LOOK_SHIFT[look or ""]
    for k in pairs(sh and sh.keys or {}) do out[#out + 1] = k end
    table.sort(out)
    return out
end

local function Say(text)
    print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " " .. text)
end

--------------------------------------------------
-- Vorbereiten (in einem Profil, ohne es zu laden)
--------------------------------------------------
-- p: Profiltabelle; from/to: Designs. Plaetze, die eines der beiden
-- Designs vorgibt, werden frei; die noetigen Module laufen.
function LS.Prepare(p, from, to)
    if type(p) ~= "table" then return false end
    p.modules = p.modules or {}
    p.positions = p.positions or {}
    local function M(key) p.modules[key] = p.modules[key] or {} return p.modules[key] end
    M("general").look = to
    local freed = 0
    for _, look in ipairs({ from, to }) do
        if Arranged(look) then
            for _, key in ipairs(LS.PlaceKeys(look)) do
                if p.positions[key] ~= nil then p.positions[key] = nil freed = freed + 1 end
            end
        end
    end
    if Arranged(to) or Arranged(from) then
        for _, mod in ipairs(LS.NEEDS) do M(mod).enabled = true end
        local ab = M("actionbars")
        ab.xpEnabled, ab.xpHideGame = true, true
        -- 1.0.8.0: Groesse und Reihen der Konsole setzt nur die Anordnung
        -- von WeintCodex - mit "Bearbeitungsmodus des Spiels" ragten die
        -- Leisten in den Ring.
        if Arranged(to) then ab.layout = "wc" end
        local uf = M("unitframes")
        for _, k in ipairs(LS.UNIT_KEYS) do uf[k] = nil end
    end
    return true, freed
end

--------------------------------------------------
-- Ablauf
--------------------------------------------------
-- Gemerkt bis nach dem Neuladen (je Charakter): wohin gewechselt wurde,
-- welches Profil vorher galt (der Weg zurueck).
local function State()
    local root, key = K.Root(), K.CharKey()
    if not (root and key) then return nil end
    root.lookSwitch = root.lookSwitch or {}
    return root.lookSwitch, key
end

-- Die Wahl im Dialog: "profile" (neues Profil), "here" (dieses Profil),
-- "back" (zurueck zum vorherigen Profil), "layout" (nur das Layout). Laeuft im Klick VOR dem
-- Neuladen (K.ReloadButton).
function LS.Run(mode, from, to)
    local PR = WeintCodex.UIProfiles
    local root = K.Root()
    if not (root and PR) then return false end
    local st, key = State()
    local before = PR.Active()
    local target = before
    if mode == "back" then
        target = st and st[key] and st[key].back
        if not (target and root.profiles[target]) then return false end
        -- Das Konsolen-Profil behaelt sein Design fuer den naechsten Wechsel.
        local cur = root.profiles[before]
        if cur and cur.modules and cur.modules.general then cur.modules.general.look = from end
        PR.Choose(target)
    elseif mode == "profile" then
        -- Das laufende Profil behaelt sein Design - die Wahl im Dropdown
        -- galt schon ihm.
        local cur = root.profiles[before]
        if cur and cur.modules and cur.modules.general then cur.modules.general.look = from end
        local made = PR.New(PR.FreeName(LS.LookName(to)))
        if not made then return false end
        target = made
        LS.Prepare(root.profiles[target], from, to)
    elseif mode == "here" then
        LS.Prepare(root.profiles[before], from, to)
    end
    -- "layout" (1.0.8.0): nur das Layout dieses Charakters - das Profil
    -- (Plaetze, die ein anderer Charakter darin gezogen hat) bleibt.
    if st and key then
        local back = (mode == "profile") and before or (mode == "back" and from == "konsole" and before)
            or (st[key] and st[key].back)
        st[key] = { to = to, look = to, from = from, profile = target, back = back, verify = true }
    end
    -- Das Layout des Bearbeitungsmodus fuer das neue Design einrichten -
    -- schon jetzt im Namen des Zielprofils (die Sitzung endet gleich).
    -- Zurueck zu einem Profil: dessen Layout steht schon - nur aktiv
    -- schalten, nie neu bauen (eigene Aenderungen darin bleiben).
    K._SetActiveProfile(target)
    local ES = WeintCodex.UISetup
    if mode == "back" and ES and ES.HasLayout and ES.HasLayout() == true then
        if ES.ActivateExisting then pcall(ES.ActivateExisting) end
    elseif ES and ES.Apply then
        local ok, res = pcall(ES.Apply)
        if st and key and st[key] then st[key].applied = (ok and res == true) and true or false end
        -- Nachgesehen wird hier (LS.ShowResult) - nicht doppelt.
        root.setupVerify = nil
    end
    return true
end

--------------------------------------------------
-- Pruefen nach dem Neuladen
--------------------------------------------------
local function Visible(f)
    return type(f) == "table" and f.IsVisible and K.Bool(f:IsVisible(), false) or false
end

-- Zeilen { ok, text } - was steht, was nicht.
function LS.Check(look)
    local out = {}
    local function Add(ok, text) out[#out + 1] = { ok = ok and true or false, text = text } end
    local ES = WeintCodex.UISetup
    local active = ES and ES.LayoutActive and ES.LayoutActive()
    Add(active == true, "Layout „" .. ((ES and ES.LayoutName and ES.LayoutName()) or "WeintCodex")
        .. "“ im Bearbeitungsmodus aktiv")
    for _, mod in ipairs(LS.NEEDS) do
        local m = K.modules and K.modules[mod]
        local title = m and m.title or mod
        Add(K.IsActive(mod), title .. " läuft")
    end
    local mm = _G.Minimap
    local mmOk = Visible(mm)
    if mmOk and look == "konsole" and mm.GetCenter and _G.UIParent then
        local x, y = mm:GetCenter()
        local ux = _G.UIParent:GetCenter()
        x, y, ux = K.Plain(x), K.Plain(y), K.Plain(ux)
        local s = (K.Plain(mm:GetEffectiveScale()) or 1) / (K.Plain(_G.UIParent:GetEffectiveScale()) or 1)
        mmOk = type(x) == "number" and type(ux) == "number" and math.abs(x * s - ux) < 40 and y * s < 260
    end
    Add(mmOk, look == "konsole" and "Minikarte in der Mitte unten" or "Minikarte sichtbar")
    local game = false
    for _, n in ipairs({ "MainStatusTrackingBarContainer", "StatusTrackingBarManager", "MainMenuExpBar" }) do
        if Visible(_G[n]) then game = true end
    end
    Add(not game, "Erfahrungsbalken des Spiels ausgeblendet")
    Add(Visible(_G.WeintCodexUF_player), "Spielerrahmen sichtbar")
    if Arranged(look) then
        Add(K.Get("actionbars", "layout") == "wc", "Aktionsleisten von WeintCodex angeordnet")
    end
    return out
end

--------------------------------------------------
-- Dialog
--------------------------------------------------
local dlg
local function Label(parent, size, color)
    local fs = K.NewText(parent, size)
    fs:SetJustifyH("LEFT")
    fs:SetTextColor(unpack(C[color]))
    if fs.SetWordWrap then fs:SetWordWrap(true) end
    return fs
end

local function Build()
    if dlg then return dlg end
    local f = CreateFrame("Frame", "WeintCodexLookSwitch", UIParent)
    f:SetSize(LS.W, LS.H)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 80)
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetToplevel(true)
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetClampedToScreen(true)
    K.Kachel(f, { shadow = 8, solid = true })
    f.title = Label(f, 16, "textBright")
    f.title:SetPoint("TOPLEFT", f, "TOPLEFT", 22, -20)
    f.title:SetPoint("RIGHT", f, "RIGHT", -22, 0)
    f.body = Label(f, 12, "textMuted")
    f.body:SetPoint("TOPLEFT", f.title, "BOTTOMLEFT", 0, -10)
    f.body:SetPoint("RIGHT", f, "RIGHT", -22, 0)
    if f.body.SetSpacing then f.body:SetSpacing(3) end
    f:Hide()
    dlg = f
    return f
end

-- Knoepfe des Dialogs (eigene Tabelle: Felder der Attrappe sind Funktionen).
LS.buttons = {}
local function Clear()
    for _, b in ipairs(LS.buttons) do b:Hide() end
    LS.buttons = {}
end
local function Place(f)
    local prev
    for _, b in ipairs(LS.buttons) do
        b:ClearAllPoints()
        if prev then b:SetPoint("LEFT", prev, "RIGHT", 10, 0)
        else b:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 22, 20) end
        b:Show()
        prev = b
    end
end
local function Reload(f, text, kind, fn)
    local b = K.ReloadButton(f, { text = text, kind = kind, height = 32, size = 12, backdrop = "surface2",
        onClick = function() fn() end })
    LS.buttons[#LS.buttons + 1] = b
end
local function Plain(f, text, kind, fn)
    local b = WeintCodex.CreateButton(f, { text = text, kind = kind, height = 32, size = 12,
        backdrop = "surface2", onClick = fn })
    LS.buttons[#LS.buttons + 1] = b
end

-- Gewaehlt, noch nicht geladen: was jetzt geschieht.
function LS.Busy() return (dlg and dlg:IsShown()) and true or false end

-- afterReload: schon mit dem neuen Design geladen (ohne den Dialog) -
-- "Abbrechen" heisst dann "so lassen".
-- hereOnly (1.0.8.0): das Profil traegt das Design schon fuer andere
-- Charaktere - nur hier einrichten, das Profil nie zuruecksetzen.
function LS.Ask(from, to, afterReload, hereOnly)
    local f = Build()
    Clear()
    local PR = WeintCodex.UIProfiles
    local cur = PR and PR.Active() or "Standard"
    local st, key = State()
    local back = st and key and st[key] and st[key].back
    local root = K.Root()
    if not (back and root and root.profiles[back]) or back == cur or hereOnly then back = nil end
    f.title:SetText("Design „" .. LS.LookName(to) .. "“ einrichten")
    local lines = {}
    if Arranged(to) then
        lines[#lines + 1] = "„" .. LS.LookName(to) .. "“ ordnet die Oberfläche neu an: Leisten, Karte, Spieler und Ziel."
            .. " WeintCodex richtet dafür alles in einem Schritt ein – Plätze und Größen des Designs,"
            .. " Minikarte, Aktionsleisten und Erfahrungsbalken, das Layout im Bearbeitungsmodus – und lädt neu."
            .. " Danach prüft es, ob alles steht."
    else
        lines[#lines + 1] = "Zurück zu „" .. LS.LookName(to) .. "“: WeintCodex stellt Plätze, Leisten und das Layout"
            .. " im Bearbeitungsmodus für dieses Design ein und lädt neu. Danach prüft es, ob alles steht."
    end
    lines[#lines + 1] = ""
    if hereOnly then
        lines[#lines + 1] = "Dein Profil „" .. cur .. "“ nutzt dieses Design schon – auf einem anderen Charakter eingestellt."
            .. " Für diesen Charakter fehlt nur noch das Layout im Bearbeitungsmodus."
    elseif back then
        lines[#lines + 1] = "Empfohlen: zurück zu deinem Profil „" .. back .. "“ – dort ist alles noch so, wie es vorher war."
    elseif Arranged(to) then
        lines[#lines + 1] = "Empfohlen: ein eigenes Profil „" .. PR.FreeName(LS.LookName(to)) .. "“. Dein Profil „" .. cur
            .. "“ bleibt unverändert – zurück geht es jederzeit mit dem Design von vorher."
    else
        lines[#lines + 1] = "Plätze, die das bisherige Design vorgab, stehen danach wieder an ihrem Standardplatz."
    end
    f.body:SetText(table.concat(lines, "\n"))
    if hereOnly then
        Reload(f, "Einrichten & neu laden", "primary", function() LS.Run("layout", to, to) end)
    elseif back then
        Reload(f, "Zurück zu „" .. back .. "“", "primary", function() LS.Run("back", from, to) end)
        Reload(f, "In „" .. cur .. "“ umstellen", "secondary", function() LS.Run("here", from, to) end)
    elseif Arranged(to) then
        Reload(f, "Eigenes Profil & einrichten", "primary", function() LS.Run("profile", from, to) end)
        Reload(f, "In „" .. cur .. "“ einrichten", "secondary", function() LS.Run("here", from, to) end)
    else
        Reload(f, "Einrichten & neu laden", "primary", function() LS.Run("here", from, to) end)
    end
    if afterReload then
        Plain(f, "So lassen", "ghost", function()
            local st2, key2 = State()
            if st2 and key2 then st2[key2] = st2[key2] or {} st2[key2].look = to end
            f:Hide()
        end)
    else
        Plain(f, "Abbrechen", "ghost", function() LS.Cancel(from) end)
    end
    Place(f)
    f:Show()
    return f
end

-- Abbrechen: das Design von vorher gilt wieder.
function LS.Cancel(from)
    LS.skip = true
    K.Set("general", "look", from)
    LS.skip = false
    LS.last = from
    if dlg then dlg:Hide() end
end

-- Nach dem Neuladen: was steht?
function LS.ShowResult(look)
    local f = Build()
    Clear()
    local rows = LS.Check(look)
    local bad = 0
    local lines = {}
    for _, r in ipairs(rows) do
        if not r.ok then bad = bad + 1 end
        lines[#lines + 1] = (r.ok and WeintCodex.ColorText("green", "✓") or WeintCodex.ColorText("red", "✗")) .. "  " .. r.text
    end
    local PR = WeintCodex.UIProfiles
    if bad == 0 then
        f.title:SetText("Design „" .. LS.LookName(look) .. "“ ist eingerichtet")
        lines[#lines + 1] = "\nProfil: „" .. tostring(PR and PR.Active()) .. "“. Zurück geht es über Allgemein → Design."
        Plain(f, "Fertig", "primary", function() f:Hide() end)
    else
        f.title:SetText("Fast fertig – " .. bad .. (bad == 1 and " Punkt fehlt" or " Punkte fehlen"))
        lines[#lines + 1] = "\n„Noch einmal einrichten“ stellt alles erneut ein und lädt neu."
            .. " Bleibt danach etwas offen, hilft /wcui prüfen beim Finden."
        Reload(f, "Noch einmal einrichten", "primary", function() LS.Run("here", look, look) end)
        Plain(f, "Später", "ghost", function() f:Hide() end)
    end
    f.body:SetText(table.concat(lines, "\n"))
    Place(f)
    f:Show()
    return bad
end

--------------------------------------------------
-- Ausloeser
--------------------------------------------------
-- Die Wahl im Dropdown (Allgemein → Design der Oberflaeche).
K.Listen(function(kind, module, key)
    if kind ~= "setting" or module ~= "general" or key ~= "look" or LS.skip then return end
    local to = K.Get("general", "look") or "schwarz"
    local from = LS.last or "schwarz"
    if to == from then return end
    LS.last = to
    if not K.UIEnabled() then return end
    -- Nur wenn eine Anordnung wechselt; reine Farbe bleibt beim Neuladen.
    if not (Arranged(to) or Arranged(from)) then return end
    if K.InCombat() then K.AfterCombat(function() LS.Ask(from, to) end) return end
    LS.Ask(from, to)
end)

do
    local ev = CreateFrame("Frame")
    ev:RegisterEvent("PLAYER_ENTERING_WORLD")
    ev:SetScript("OnEvent", WeintCodex.Measured("Designwechsel", function()
        local look = K.Get("general", "look") or "schwarz"
        LS.last = look
        local st, key = State()
        local rec = st and key and st[key]
        if not (rec and rec.verify) then
            -- Ohne den Dialog neu geladen (Knopf im Einstellungsfenster,
            -- /reload): steht ein anderes Design als zuletzt eingerichtet,
            -- jetzt durch den Wechsel fuehren - einmal, ausserhalb des Kampfes.
            if not (st and key) or not K.UIEnabled() then return end
            if not rec then
                st[key] = { look = look }
                -- 1.0.8.0: ein Charakter, der das Design mit dem Profil
                -- geerbt hat (ein anderer hat umgestellt): das Layout des
                -- Designs ist hier nicht aktiv - einmal anbieten.
                local ES = WeintCodex.UISetup
                if Arranged(look) and ES and ES.LayoutActive and ES.LayoutActive() == false then
                    K.AfterCombat(function() LS.Ask(look, look, true, true) end)
                end
                return
            end
            local was = rec.look or "schwarz"
            if was ~= look and (Arranged(was) or Arranged(look)) then
                K.AfterCombat(function() LS.Ask(was, look, true) end)
            end
            return
        end
        rec.verify = false
        local function run()
            if K.InCombat() then K.AfterCombat(run) return end
            LS.ShowResult(K.Get("general", "look") or "schwarz")
        end
        if _G.C_Timer and _G.C_Timer.After then _G.C_Timer.After(8, run) else run() end
    end))
    LS.events = ev
end
