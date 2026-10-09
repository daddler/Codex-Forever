--------------------------------------------------
-- WeintCodex :: Oberflaeche - Gestaltungsmodus
--------------------------------------------------
-- Das "Rahmen entsperren" von bis 6.2.0.0, zu Ende gedacht
-- (docs/design/ui-2.0.md, Grundsatz 6). Im Beta-Test hiess Entsperren:
-- Fenster schliessen, um etwas zu sehen, ziehen, /wcui tippen, um wieder
-- sperren zu koennen. Jetzt:
--
--   * Das Einstellungsfenster geht beim Betreten von selbst zu und bei
--     "Fertig" von selbst wieder auf.
--   * Oben mittig eine Leiste: Testdaten, Raster, Einrasten,
--     Zuruecksetzen, Fertig - und darunter, welcher Rahmen angewaehlt ist
--     und wo er steht.
--   * Testdaten zeigen Ziel, Fokus, Gruppe und Zauberbalken, damit jeder
--     Rahmen eine Flaeche hat (ui/testmode.lua).
--   * Raster (16er-Linien, Mittelachsen im Akzent) und Einrasten (linke
--     untere Ecke aufs 8er-Raster, die Mitte auf die Mittelachse, wenn sie
--     nahe ist).
--   * Anklicken waehlt einen Rahmen, Pfeiltasten schieben ihn um 1
--     (Umschalt: 8), Doppelklick oeffnet seine Einstellungen, Esc beendet.
--   * Bruecke (6.9.0.5): was das Spiel stellt, verschiebt nur dessen
--     Bearbeitungsmodus - ein Knopf fuehrt hinueber und beim Schliessen
--     zurueck (Abschnitt "Bruecke" unten).
--
-- Die Schalter gelten fuer die Sitzung: der Beta-Client speichert ohnehin
-- nicht, und beim naechsten Mal sollen sie wieder an sein.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIEditMode = {}

local E = WeintCodex.UIEditMode
local K = WeintCodex.UIKit
local C = WeintCodex.Colors

local GRID, GRID_LINE, AXIS_SNAP = 8, 16, 6
E.state = { test = true, grid = true, snap = true }
local state = E.state

local bar, info, grid
local buttons = {}
E.buttons = buttons     -- fuer den Prueflauf
local reopen, startedTest = false, false
local armedReset = false

--------------------------------------------------
-- Einrasten
--------------------------------------------------

local function Round(v, step) return math.floor(v / step + 0.5) * step end

-- Verschiebung nach dem Ziehen, in den Einheiten des Rahmens (SetPoint).
function E.SnapOffset(frame)
    if not (K.IsUnlocked() and state.snap) then return 0, 0 end
    local l, b = frame:GetLeft(), frame:GetBottom()
    local w, h = frame:GetWidth(), frame:GetHeight()
    if type(l) ~= "number" or type(b) ~= "number" then return 0, 0 end
    local es = 1
    if frame.GetEffectiveScale and UIParent.GetEffectiveScale then
        local a, u = frame:GetEffectiveScale(), UIParent:GetEffectiveScale()
        if type(a) == "number" and type(u) == "number" and u > 0 then es = a / u end
    end
    l, b, w = l * es, b * es, (w or 0) * es
    local uw = UIParent:GetWidth()
    local dx
    local cx = l + w / 2
    if type(uw) == "number" and math.abs(cx - uw / 2) <= AXIS_SNAP then
        dx = uw / 2 - cx
    else
        dx = Round(l, GRID) - l
    end
    local dy = Round(b, GRID) - b
    return dx / es, dy / es
end
K.SnapOffset = E.SnapOffset

--------------------------------------------------
-- Raster
--------------------------------------------------

local function BuildGrid()
    if grid then return grid end
    grid = CreateFrame("Frame", "WeintCodexDesignGrid", UIParent)
    grid:SetAllPoints(UIParent)
    grid:SetFrameStrata("BACKGROUND")
    grid:EnableMouse(false)
    local w, h = UIParent:GetWidth() or 1365, UIParent:GetHeight() or 768
    if type(w) ~= "number" or w <= 0 then w = 1365 end
    if type(h) ~= "number" or h <= 0 then h = 768 end
    local faint, strong = C.border, C.borderStrong
    local function Line(vertical, pos, col, a)
        local t = grid:CreateTexture(nil, "BACKGROUND")
        t:SetColorTexture(col[1], col[2], col[3], a)
        if vertical then
            t:SetPoint("TOPLEFT", grid, "TOPLEFT", pos, 0)
            t:SetPoint("BOTTOMLEFT", grid, "BOTTOMLEFT", pos, 0)
            t:SetWidth(1)
        else
            t:SetPoint("BOTTOMLEFT", grid, "BOTTOMLEFT", 0, pos)
            t:SetPoint("BOTTOMRIGHT", grid, "BOTTOMRIGHT", 0, pos)
            t:SetHeight(1)
        end
    end
    -- Linien von der Mitte aus, damit die Mittelachse eine Linie ist.
    local cx, cy = math.floor(w / 2), math.floor(h / 2)
    for x = cx % GRID_LINE, w, GRID_LINE do
        local major = ((x - cx) % (GRID_LINE * 4)) == 0
        Line(true, x, major and strong or faint, major and 0.5 or 0.28)
    end
    for y = cy % GRID_LINE, h, GRID_LINE do
        local major = ((y - cy) % (GRID_LINE * 4)) == 0
        Line(false, y, major and strong or faint, major and 0.5 or 0.28)
    end
    local a = K.Highlight()
    Line(true, cx, a, 0.6)
    Line(false, cy, a, 0.35)
    grid:Hide()
    return grid
end

--------------------------------------------------
-- Leiste
--------------------------------------------------

local function ToggleText(label, on) return label .. (on and ": an" or ": aus") end

-- Von rechts nach links, mit dem Abstand zum rechten Nachbarn.
local ORDER = { { "done", 8 }, { "reset", 10 }, { "snap", 6 }, { "grid", 6 }, { "test", 6 }, { "game", 10 } }
E.BAR_MIN = 790

-- Die Leiste so breit wie Titel und Knoepfe - die Beschriftungen wechseln.
local function FitBar()
    local w = 9 + E.LOGO_SMALL + 7 + 20
    local tw = bar.title.GetStringWidth and bar.title:GetStringWidth()
    w = w + ((type(tw) == "number" and tw > 0) and tw or 120)
    for _, o in ipairs(ORDER) do
        local bw = buttons[o[1]]:GetWidth()
        w = w + o[2] + ((type(bw) == "number") and bw or 0)
    end
    bar:SetWidth(math.max(E.BAR_MIN, math.ceil(w)))
end

local function Sync()
    if not bar then return end
    buttons.test:SetText(ToggleText("Testdaten", state.test))
    buttons.grid:SetText(ToggleText("Raster", state.grid))
    buttons.snap:SetText(ToggleText("Einrasten", state.snap))
    buttons.reset:SetText(armedReset and "Wirklich alles?" or "Alles zurücksetzen")
    FitBar()
    if grid then grid:SetShown(state.grid and K.IsUnlocked()) end
    E.UpdateInfo()
end

function E.UpdateInfo()
    if not info then return end
    local key = K.SelectedMover()
    if not key then
        info:SetText("Rahmen anklicken zum Auswählen · ziehen verschiebt · Pfeiltasten schieben genau (Umschalt: 8) · Doppelklick: Einstellungen · Esc: fertig")
        return
    end
    local pos, label = K.MoverPosition(key)
    if pos then
        info:SetFormattedText("%s  ·  %s %d, %d  ·  Pfeiltasten schieben, Umschalt: 8, Rechtsklick: Standardplatz",
            label or key, pos.point or "", pos.x or 0, pos.y or 0)
    end
end

local function Button(text, kind, onClick, tooltip)
    local b = WeintCodex.CreateButton(bar, { text = text, kind = kind or "secondary", height = 24, size = 11, tooltip = tooltip })
    if onClick then b:SetScript("OnClick", onClick) end
    return b
end

local function BuildBar()
    if bar then return bar end
    bar = CreateFrame("Frame", "WeintCodexDesignBar", UIParent)
    bar:SetFrameStrata("FULLSCREEN_DIALOG")
    bar:SetSize(E.BAR_MIN, 38)
    bar:SetPoint("TOP", UIParent, "TOP", 0, -14)
    bar:EnableMouse(true)
    K.Kachel(bar)

    -- Das Logo am Anfang der Leiste (6.26.9.0): hier landet das grosse
    -- Logo vom Auftritt (E.Intro).
    bar.logo = bar:CreateTexture(nil, "ARTWORK")
    bar.logo:SetSize(E.LOGO_SMALL, E.LOGO_SMALL)
    bar.logo:SetPoint("LEFT", bar, "LEFT", 9, 0)
    bar.logo:SetTexture(K.MEDIA .. "logo_64")

    local title = K.NewText(bar, 13)
    title:SetPoint("LEFT", bar.logo, "RIGHT", 7, 0)
    title:SetTextColor(unpack(C.textBright))
    title:SetText("Gestaltungsmodus")
    bar.title = title

    buttons.test = Button("", "secondary", function()
        state.test = not state.test
        local T = WeintCodex.UITestMode
        if state.test and not T.IsOn() then
            T.Set(true)
            startedTest = true
        elseif not state.test and T.IsOn() then
            T.Set(false)
            startedTest = false
        end
        Sync()
    end)
    buttons.grid = Button("", "secondary", function()
        state.grid = not state.grid
        if state.grid then BuildGrid() end
        Sync()
    end)
    buttons.snap = Button("", "secondary", function()
        state.snap = not state.snap
        Sync()
    end)
    -- Zuruecksetzen braucht einen zweiten Klick: ein Fehlklick waere sonst
    -- eine halbe Stunde Arbeit.
    buttons.reset = Button("", "ghost", function()
        if armedReset then
            armedReset = false
            K.ResetAllPositions()
        else
            armedReset = true
            if _G.C_Timer and _G.C_Timer.After then
                _G.C_Timer.After(3, function() armedReset = false Sync() end)
            end
        end
        Sync()
    end)
    buttons.done = Button("Fertig", "primary", function() K.SetUnlocked(false) end)
    -- Hinueber in den Bearbeitungsmodus des Spiels (Bruecke, unten).
    buttons.game = Button(E.GAME_LABEL, "secondary", nil, E.GAME_TOOLTIP)
    E.AttachGame(buttons.game)

    for i, o in ipairs(ORDER) do
        local right = i == 1 and bar or buttons[ORDER[i - 1][1]]
        buttons[o[1]]:SetPoint("RIGHT", right, i == 1 and "RIGHT" or "LEFT", -o[2], 0)
    end

    info = K.NewText(bar, 11)
    info:SetPoint("TOP", bar, "BOTTOM", 0, -6)
    info:SetTextColor(unpack(C.textMuted))

    -- Tastatur: Pfeile schieben, Esc beendet; alles andere geht ans Spiel.
    if bar.EnableKeyboard then bar:EnableKeyboard(true) end
    bar:SetScript("OnKeyDown", function(self, key)
        local step = (_G.IsShiftKeyDown and _G.IsShiftKeyDown()) and GRID or 1
        local handled = false
        if key == "ESCAPE" then
            K.SetUnlocked(false)
            handled = true
        elseif key == "UP" then handled = K.NudgeMover(0, step)
        elseif key == "DOWN" then handled = K.NudgeMover(0, -step)
        elseif key == "LEFT" then handled = K.NudgeMover(-step, 0)
        elseif key == "RIGHT" then handled = K.NudgeMover(step, 0)
        end
        if self.SetPropagateKeyboardInput and not K.InCombat() then
            self:SetPropagateKeyboardInput(not handled)
        end
    end)
    bar:Hide()
    return bar
end

--------------------------------------------------
-- Betreten und Verlassen
--------------------------------------------------

--------------------------------------------------
-- Auftritt (6.26.9.0)
--------------------------------------------------
-- Beta-Test: "beim Betreten des Gestaltungsbereichs soll es sich schoen
-- animieren: Reiter oben langsam einblenden, das Menuefenster langsam
-- ausblenden, das Logo erst gross einblenden, dann nach oben links an den
-- Reiter schweben und sich dort festmachen". Ablauf (Sekunden):
--   0    - FADE   Einstellungsfenster blendet aus, Logo blendet gross ein
--   FADE - HOLD   Logo steht in der Mitte
--   HOLD - FLY    Logo schwebt an seinen Platz in der Leiste und wird
--                 kleiner, die Leiste blendet ein und gleitet herab
-- Ein Rahmen mit einem OnUpdate, nur waehrend des Auftritts; je Bild keine
-- Tabelle, keine Funktion. "Fertig", Esc oder ein Kampf brechen ab - dann
-- steht alles sofort am Ziel. Beim Verlassen blendet die Leiste aus und
-- das Fenster wieder ein (OUT).
E.LOGO_SMALL = 22
E.LOGO_BIG = 160
E.FADE, E.HOLD, E.FLY, E.OUT = 0.3, 0.75, 1.3, 0.25
E.SLIDE = 14             -- so weit gleitet die Leiste herab

local anim, floater
local fadeFrameRef
local A = { t = 0, phase = nil, opt = nil, x0 = 0, y0 = 0, x1 = 0, y1 = 0 }
E.anim = A

local function Ease(p)  -- weich an, weich aus
    if p <= 0 then return 0 elseif p >= 1 then return 1 end
    return p * p * (3 - 2 * p)
end

local function BarAt(off) bar:ClearAllPoints() bar:SetPoint("TOP", UIParent, "TOP", 0, -14 + off) end

local function Settle()
    -- Alles an seinen Platz: Ende des Auftritts oder Abbruch.
    if anim then anim:Hide() end
    if floater then floater:Hide() end
    if A.phase == "in" then
        BarAt(0)
        bar:SetAlpha(1)
        bar.logo:SetAlpha(1)
        if A.opt then A.opt:Hide() A.opt:SetAlpha(1) end
    elseif A.phase == "out" then
        bar:Hide()
        bar:SetAlpha(1)
        BarAt(0)
    end
    A.opt, A.phase = nil, nil
end
E.Settle = Settle

local function Step(_, el)
    A.t = A.t + (el or 0)
    local t = A.t
    if A.phase == "out" then
        local p = Ease(t / E.OUT)
        bar:SetAlpha(1 - p)
        BarAt(p * E.SLIDE)
        if t >= E.OUT then
            local cb = A.after
            A.after = nil
            Settle()
            if cb then cb() end
        end
        return
    end
    -- Fenster aus, Logo gross ein.
    local f = Ease(t / E.FADE)
    if A.opt then A.opt:SetAlpha(1 - f) end
    if A.opt and t >= E.FADE then A.opt:Hide() A.opt:SetAlpha(1) A.opt = nil end
    if t < E.HOLD then
        floater:SetSize(E.LOGO_BIG * (0.7 + 0.3 * f), E.LOGO_BIG * (0.7 + 0.3 * f))
        floater:SetAlpha(f)
        floater:ClearAllPoints()
        floater:SetPoint("CENTER", UIParent, "BOTTOMLEFT", A.x0, A.y0)
        return
    end
    -- Schweben an den Platz, Leiste ein.
    local p = Ease((t - E.HOLD) / (E.FLY - E.HOLD))
    local size = E.LOGO_BIG + (E.LOGO_SMALL - E.LOGO_BIG) * p
    floater:SetSize(size, size)
    floater:SetAlpha(1)
    floater:ClearAllPoints()
    floater:SetPoint("CENTER", UIParent, "BOTTOMLEFT", A.x0 + (A.x1 - A.x0) * p, A.y0 + (A.y1 - A.y0) * p)
    bar:SetAlpha(p)
    BarAt((1 - p) * E.SLIDE)
    if t >= E.FLY then Settle() end
end

E.Step = Step

local function Animator()
    if anim then return end
    anim = CreateFrame("Frame", nil, UIParent)
    anim:Hide()
    anim:SetScript("OnUpdate", Step)
    floater = UIParent:CreateTexture(nil, "OVERLAY")
    floater:SetTexture(K.MEDIA .. "logo_256")
    floater:Hide()
    E.floater = floater
end

-- Den Auftritt starten (Leiste steht schon, unsichtbar). Ohne Bildschirm-
-- groesse oder Ziel (Attrappe, sehr frueher Aufruf): sofort am Ziel.
function E.Intro(opt)
    Animator()
    A.t, A.phase, A.opt = 0, "in", opt
    local w, h = UIParent:GetWidth(), UIParent:GetHeight()
    BarAt(0)
    local lx, ly = bar.logo:GetCenter()
    if type(w) ~= "number" or type(h) ~= "number" or w <= 0 or type(lx) ~= "number" or type(ly) ~= "number" then
        Settle()
        return false
    end
    A.x0, A.y0, A.x1, A.y1 = w / 2, h * 0.55, lx, ly
    bar:SetAlpha(0)
    bar.logo:SetAlpha(0)
    floater:SetAlpha(0)
    floater:Show()
    anim:Show()
    return true
end

-- Laufenden Auftritt sofort beenden (Prueflauf; dort laeuft kein Bild).
function E.FinishAnim()
    if anim and anim:IsShown() then Step(nil, 999) end
    if fadeFrameRef and fadeFrameRef:IsShown() then fadeFrameRef:GetScript("OnUpdate")(fadeFrameRef, 999) end
end

-- Ausblenden der Leiste; `after` laeuft danach (Fenster wieder auf).
function E.Outro(after)
    if not (bar and bar:IsShown()) or K.InCombat() then
        if anim and A.phase then Settle() end
        if bar then bar:Hide() end
        if after then after() end
        return false
    end
    Animator()
    if A.phase == "in" then Settle() end
    A.t, A.phase, A.after = 0, "out", after
    floater:Hide()
    anim:Show()
    return true
end

function E.Enter()
    BuildBar()
    local O = WeintCodex.UIOptions
    local opt
    if O and O.frame and O.frame:IsShown() then
        reopen = true
        E.reopenWhere = O.Where and O.Where() or nil
        opt = O.frame
    end
    local T = WeintCodex.UITestMode
    if state.test and T and not T.IsOn() then
        T.Set(true)
        startedTest = T.IsOn()
    end
    if state.grid then BuildGrid() end
    armedReset = false
    bar:Show()
    Sync()
    -- Im Kampf kein Auftritt: dort zaehlt nur, dass es sofort steht.
    if K.InCombat() then
        if opt then opt:Hide() end
    else
        E.Intro(opt)
    end
end

function E.Leave()
    -- Hinueber ins Spiel: das Einstellungsfenster wartet bis zur Rueckkehr.
    if E.bridge.leaving then
        E.bridge.reopen = reopen
        reopen = false
    end
    if grid then grid:Hide() end
    local T = WeintCodex.UITestMode
    if startedTest and T and T.IsOn() then T.Set(false) end
    startedTest = false
    -- Zurueck ins Fenster - nicht, wenn ein Kampf den Modus beendet hat.
    -- Erst blendet die Leiste aus, dann blendet das Fenster ein.
    local back = reopen and not K.InCombat() and not E.bridge.leaving
    reopen = false
    local where = E.reopenWhere
    E.Outro(function()
        if not back then return end
        local O = WeintCodex.UIOptions
        if O and O.Return then O.Return(where) elseif O and O.Show then O.Show() end
        local f = O and O.frame
        if f and f.SetAlpha and f:IsShown() and not K.InCombat() then E.FadeIn(f) end
    end)
end

-- Ein Fenster weich einblenden (eigener kleiner Takt, einmal gebaut).
local fadeFrame, fadeTarget, fadeT = nil, nil, 0
function E.FadeIn(f)
    if not fadeFrame then
        fadeFrame = CreateFrame("Frame", nil, UIParent)
        fadeFrame:Hide()
        fadeFrameRef = fadeFrame
        fadeFrame:SetScript("OnUpdate", function(self, el)
            fadeT = fadeT + (el or 0)
            local p = Ease(fadeT / E.OUT)
            if fadeTarget then fadeTarget:SetAlpha(p) end
            if p >= 1 then self:Hide() fadeTarget = nil end
        end)
    end
    fadeTarget, fadeT = f, 0
    f:SetAlpha(0)
    fadeFrame:Show()
end

-- Welche Einstellungsseite zu welchem Rahmen gehoert.
local MODULE_OF = {
    uf_ = "unitframes", gf_ = "groupframes", damagemeter = "damagemeter", bags = "bags",
    questarrow = "questarrow", combatalert = "comfort", fps = "comfort", durability = "comfort",
    rarealert = "comfort", messenger = "comfort", messengerIcon = "comfort",
    hud_ = "actionbars",
}
function E.ModuleFor(key)
    for prefix, mod in pairs(MODULE_OF) do
        if key:sub(1, #prefix) == prefix then return mod end
    end
    return nil
end

function E.OpenSettings(key)
    local mod = E.ModuleFor(key or "")
    reopen = false
    K.SetUnlocked(false)
    local O = WeintCodex.UIOptions
    if O and O.Show then O.Show(mod) end
end

function E.IsShown() return bar ~= nil and bar:IsShown() end

--------------------------------------------------
-- Bruecke zum Bearbeitungsmodus des Spiels (6.9.0.5)
--------------------------------------------------
-- Was das Spiel stellt - Aktionsleisten, Minikarte, Buffs, Questliste,
-- Abklingzeitmanager, Chat, seine Gruppenrahmen -, verschiebt nur sein
-- Bearbeitungsmodus: WeintCodex schreibt dessen Einstellungen nicht
-- (ui/setup.lua, ui/actionbars.lua). Bis 6.9.0.4 stand das nur als Satz
-- da ("Esc -> Bearbeitungsmodus"). Jetzt fuehrt ein Knopf hinueber - in
-- der Leiste des Gestaltungsmodus, auf "Allgemein" und auf jeder Seite,
-- deren Rahmen das Spiel stellt (Builder:GameEditMode, ui/options.lua) -,
-- und wer von hier kam, kommt beim Schliessen dorthin zurueck: in den
-- Gestaltungsmodus oder ins Einstellungsfenster. Solange der des Spiels
-- offen ist, sagt eine kleine Leiste darunter, wohin es danach geht, und
-- ihr Knopf "Zum Gestaltungsmodus" fuehrt sofort hinueber (E.AttachBack).
--
-- GEOEFFNET wird ueber den Befehl des Spiels (SLASH_EDITMODE1, "/editmode")
-- als Makro auf einem sicheren Knopf, ausgeloest vom Klick: so oeffnet das
-- Spiel den Modus selbst, und kein Addon-Code ruft ihn auf. Ein Addon, das
-- EditModeManagerFrame selbst oeffnet, kann ihn verunreinigen (Taint) -
-- und ueber ihn ordnet das Spiel geschuetzte Leisten. Kennt der Client den
-- Befehl nicht, oeffnet WeintCodex ihn doch direkt (ShowUIPanel); welcher
-- Weg gilt, sagt /wcui einrichten pruefen.
-- UNGEPRUEFT auf Forever: ob es den Befehl gibt und ob der direkte Weg
-- Folgen hat. Geht der Modus nicht auf (Kampf, kein Befehl), kommt man
-- sofort dorthin zurueck, wo man war, mit einem Satz im Chat.
--------------------------------------------------

E.GAME_FRAME = "EditModeManagerFrame"
E.GAME_LABEL = "Bearbeitungsmodus des Spiels"
E.GAME_OWNS = "Aktionsleisten, Minikarte, Buffs, Questliste, Abklingzeitmanager, Chat und die Gruppenrahmen des Spiels"
E.GAME_TOOLTIP = E.GAME_OWNS .. " stellt das Spiel – Platz und Größe dort. "
    .. "Öffnet seinen Bearbeitungsmodus; schließt du ihn, bist du wieder hier."
E.CHECK_DELAY = 0.3

-- from: wohin es nach dem Schliessen geht ("design", "options" oder nil);
-- reopen: nach dem Gestaltungsmodus noch ins Einstellungsfenster.
E.bridge = { from = nil, reopen = false, leaving = false, pending = false }
local bridge = E.bridge
local strip
local SyncStrip     -- unten bei der Leiste

local function Say(text)
    print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " " .. text)
end

function E.GameFrame()
    local f = _G[E.GAME_FRAME]
    return (type(f) == "table" and type(f.IsShown) == "function") and f or nil
end

function E.GameShown()
    local f = E.GameFrame()
    return f ~= nil and f:IsShown() == true
end

-- Der Befehl des Spiels, wenn es ihn gibt.
function E.GameSlash()
    local cmd, list = _G.SLASH_EDITMODE1, _G.SlashCmdList
    if type(cmd) == "string" and cmd ~= "" and type(list) == "table" and type(list.EDITMODE) == "function" then
        return cmd
    end
    return nil
end

-- "slash" (Befehl des Spiels), "direct" (WeintCodex oeffnet) oder "none".
function E.GamePath()
    if not E.GameFrame() then return "none" end
    return E.GameSlash() and "slash" or "direct"
end

function E.Report()
    local path = E.GamePath()
    if path == "slash" then
        return "Bearbeitungsmodus des Spiels: über " .. E.GameSlash() .. " (das Spiel öffnet selbst)"
    elseif path == "direct" then
        return "Bearbeitungsmodus des Spiels: kein Befehl /editmode – WeintCodex öffnet ihn direkt"
    end
    return "Bearbeitungsmodus des Spiels: nicht gefunden (EditModeManagerFrame fehlt)"
end

-- Vor dem Oeffnen: merken, woher man kommt, und Platz machen.
-- 6.9.0.7: ZWEI SCHRITTE, und der erste VOR dem Klick. Das Spiel schliesst
-- beim Oeffnen seines Bearbeitungsmodus selbst Fenster - auch das
-- Einstellungsfenster (es steht in UISpecialFrames, damit Esc es
-- schliesst). Bis 6.9.0.6 wurde erst NACH dem Klick nachgesehen, woher man
-- kam: das Fenster war dann schon zu, der Rueckweg leer (Beta-Test).
-- Jetzt merkt NoteOrigin den Ausgangsort vorher (PreClick, samt Seite und
-- Bildlauf des Fensters), MakeRoom raeumt danach auf (PostClick).
local function Options() return WeintCodex.UIOptions end

function E.NoteOrigin()
    bridge.from, bridge.reopen, bridge.pending, bridge.where = nil, false, false, nil
    if K.InCombat() then
        Say("Im Kampf öffnet das Spiel seinen Bearbeitungsmodus nicht.")
        return false
    end
    if not E.GameFrame() then
        Say("Dieser Client hat keinen Bearbeitungsmodus.")
        return false
    end
    local O = Options()
    if K.IsUnlocked() then
        bridge.from = "design"
    elseif O and O.frame and O.frame:IsShown() then
        bridge.from = "options"
        bridge.where = O.Where and O.Where() or nil
    end
    bridge.pending = true
    return true
end

function E.MakeRoom()
    if bridge.from == "design" and K.IsUnlocked() then
        bridge.leaving = true     -- E.Leave merkt sich das Einstellungsfenster
        K.SetUnlocked(false)
        bridge.leaving = false
    end
    local O = Options()
    if bridge.from == "options" and O and O.frame and O.frame:IsShown() then
        O.frame:Hide()
    end
end

function E.LeaveForGame()
    if not E.NoteOrigin() then return false end
    E.MakeRoom()
    return true
end

-- Dorthin zurueck, woher man kam - nie im Kampf.
function E.BackFromGame()
    local from, again = bridge.from, bridge.reopen
    bridge.from, bridge.reopen = nil, false
    if not from or K.InCombat() then return false end
    if from == "design" then
        if not K.SetUnlocked(true) then return false end
        reopen = again
    elseif from == "options" then
        local O = Options()
        if O and O.Return then O.Return(bridge.where) elseif O and O.Show then O.Show() end
    end
    bridge.where = nil
    return true
end

-- Ist er aufgegangen? Wenn nicht: zurueck, mit einem Satz.
function E.CheckOpened()
    if not bridge.pending then return true end
    bridge.pending = false
    if E.GameShown() then return true end
    Say("Der Bearbeitungsmodus des Spiels ist nicht aufgegangen. Von Hand: Esc → Bearbeitungsmodus.")
    E.BackFromGame()
    return false
end

local function CheckLater()
    if _G.C_Timer and _G.C_Timer.After then
        _G.C_Timer.After(E.CHECK_DELAY, E.CheckOpened)
    else
        E.CheckOpened()
    end
end

-- Nach dem Klick auf den sicheren Knopf: das Spiel hat (vielleicht) schon
-- geoeffnet, die Leiste darunter steht schon - sie erfaehrt jetzt, woher
-- man kam.
function E.AfterGameClick()
    if not bridge.pending then return end
    E.MakeRoom()
    SyncStrip()
    CheckLater()
end

-- Der direkte Weg, nur ohne Befehl des Spiels.
function E.OpenGame()
    if not E.LeaveForGame() then return false end
    local f = E.GameFrame()
    local show = _G.ShowUIPanel
    local ok, err = pcall(function()
        if type(show) == "function" then show(f) else f:Show() end
    end)
    if not ok then K.Report("bearbeitungsmodus", err) end
    CheckLater()
    return ok
end

-- Macht aus einem Knopf den Weg hinueber. Mit Befehl: ein sicherer Knopf
-- darueber fuehrt ihn als Makro aus (wie WeintCodex.AttachReload);
-- angelegt wird der nur ausserhalb des Kampfes.
function E.AttachGame(button)
    E.HookGame()
    local slash = E.GameSlash()
    if slash and K.InCombat() then
        button:SetScript("OnClick", function() E.LeaveForGame() end)
        K.AfterCombat(function() E.AttachGame(button) end)
        return nil
    end
    if slash then
        local ok, ov = pcall(CreateFrame, "Button", nil, button, "SecureActionButtonTemplate")
        if ok and ov then
            ov:SetAllPoints(button)
            ov:SetFrameLevel((button:GetFrameLevel() or 1) + 5)
            if ov.RegisterForClicks then ov:RegisterForClicks("AnyUp") end
            ov:SetAttribute("useOnKeyDown", false)
            ov:SetAttribute("type", "macro")
            ov:SetAttribute("macrotext", slash)
            -- Erst NACH dem Makro Platz machen: der Knopf liegt in der
            -- Leiste, die dabei zugeht, und ein Klick soll nicht davon
            -- abhaengen, ob ein versteckter Knopf ihn noch ausfuehrt.
            ov:SetScript("PreClick", E.NoteOrigin)
            ov:SetScript("PostClick", E.AfterGameClick)
            ov:SetScript("OnEnter", function()
                local f = button:GetScript("OnEnter")
                if f then f(button) end
            end)
            ov:SetScript("OnLeave", function()
                local f = button:GetScript("OnLeave")
                if f then f(button) end
            end)
            button._gameEditMode = ov
            return ov
        end
    end
    button:SetScript("OnClick", function() E.OpenGame() end)
    return nil
end

--------------------------------------------------
-- Die Leiste unter dem Bearbeitungsmodus des Spiels
--------------------------------------------------

local function StripText()
    if bridge.from == "design" then return "Schließen bringt dich zurück in den Gestaltungsmodus." end
    if bridge.from == "options" then return "Schließen bringt dich zurück in die Einstellungen von WeintCodex." end
    return "Die Rahmen von WeintCodex verschiebst du im Gestaltungsmodus."
end

function SyncStrip()
    if not strip then return end
    strip.text:SetText(StripText())
    local tw = strip.text.GetStringWidth and strip.text:GetStringWidth()
    local bw = strip.back:GetWidth()
    tw = (type(tw) == "number" and tw > 0) and tw or 280
    strip:SetWidth(math.ceil(14 + tw + 16 + ((type(bw) == "number") and bw or 0) + 8))
end

-- Der Knopf zurueck: danach in den Gestaltungsmodus (und war man aus dem
-- Einstellungsfenster gekommen, nach "Fertig" wieder dorthin).
function E.PrepareBack()
    if bridge.from == "options" then E.reopenWhere = bridge.where end
    bridge.reopen = bridge.reopen or bridge.from == "options"
    bridge.from = "design"
    SyncStrip()
end

-- Das Schliessen des Spiels: sein eigener Knopf (das X oben rechts).
function E.GameClose()
    local f = E.GameFrame()
    local c = f and f.CloseButton
    return (type(c) == "table" and type(c.Click) == "function") and c or nil
end

E.BACK_HINT = "Schließe den Bearbeitungsmodus des Spiels (Esc oder X) – danach geht der Gestaltungsmodus auf."

-- Macht aus einem Knopf den Weg zurueck. WeintCodex schliesst den Modus
-- des Spiels NICHT selbst (HideUIPanel aus Addon-Code: Taint, und die
-- Frage nach ungespeicherten Aenderungen kaeme vielleicht nie). Ein
-- sicherer Knopf klickt das X des Spiels (type "click"): das Spiel
-- schliesst, wie wenn man es selbst anklickt, samt seiner Rueckfrage -
-- und erst wenn es wirklich zu ist, geht der Gestaltungsmodus auf (OnHide).
-- Ohne X: der Rueckweg wird gemerkt, und ein Satz sagt, was zu tun ist.
function E.AttachBack(button)
    local close = E.GameClose()
    if close and not K.InCombat() then
        local ok, ov = pcall(CreateFrame, "Button", nil, button, "SecureActionButtonTemplate")
        if ok and ov then
            ov:SetAllPoints(button)
            ov:SetFrameLevel((button:GetFrameLevel() or 1) + 5)
            if ov.RegisterForClicks then ov:RegisterForClicks("AnyUp") end
            ov:SetAttribute("useOnKeyDown", false)
            ov:SetAttribute("type", "click")
            ov:SetAttribute("clickbutton", close)
            ov:SetScript("PreClick", E.PrepareBack)
            ov:SetScript("OnEnter", function()
                local f = button:GetScript("OnEnter")
                if f then f(button) end
            end)
            ov:SetScript("OnLeave", function()
                local f = button:GetScript("OnLeave")
                if f then f(button) end
            end)
            button._gameBack = ov
            return ov
        end
    end
    button:SetScript("OnClick", function()
        E.PrepareBack()
        Say(E.BACK_HINT)
    end)
    return nil
end

-- Unter das Fenster des Spiels, als Zahlen (nicht daran verankert: ein
-- Rahmen, der an einem des Spiels haengt, erbt dessen Schutz). Passt es
-- unten nicht, darueber.
local function PlaceStrip()
    strip:ClearAllPoints()
    local f = E.GameFrame()
    local l, b, t, w = f:GetLeft(), f:GetBottom(), f:GetTop(), f:GetWidth()
    if type(l) ~= "number" or type(b) ~= "number" or type(t) ~= "number" or type(w) ~= "number" then
        strip:SetPoint("TOP", UIParent, "TOP", 0, -14)
        return
    end
    local es = 1
    if f.GetEffectiveScale and UIParent.GetEffectiveScale then
        local a, u = f:GetEffectiveScale(), UIParent:GetEffectiveScale()
        if type(a) == "number" and type(u) == "number" and u > 0 then es = a / u end
    end
    local cx, h = (l + w / 2) * es, strip:GetHeight() or 34
    if b * es - 8 - h >= 0 then
        strip:SetPoint("TOP", UIParent, "BOTTOMLEFT", cx, b * es - 8)
    else
        strip:SetPoint("BOTTOM", UIParent, "BOTTOMLEFT", cx, t * es + 8)
    end
end

function E.ShowStrip()
    if not (K.UIEnabled and K.UIEnabled()) or not E.GameFrame() then return end
    if not strip then
        strip = CreateFrame("Frame", "WeintCodexGameEditBar", UIParent)
        strip:SetFrameStrata("FULLSCREEN_DIALOG")
        strip:SetSize(480, 34)
        strip:EnableMouse(true)
        if strip.SetClampedToScreen then strip:SetClampedToScreen(true) end
        K.Kachel(strip)
        strip.text = K.NewText(strip, 11)
        strip.text:SetPoint("LEFT", strip, "LEFT", 14, 0)
        strip.text:SetTextColor(unpack(C.textMuted))
        strip.back = WeintCodex.CreateButton(strip, { text = "Zum Gestaltungsmodus", kind = "primary", height = 22, size = 11,
            tooltip = "Schließt den Bearbeitungsmodus des Spiels – wie sein X, samt Rückfrage bei ungespeicherten Änderungen – und öffnet den Gestaltungsmodus von WeintCodex: Einheitenrahmen, Gruppe, Schadensanzeige und die übrigen Rahmen von WeintCodex." })
        strip.back:SetPoint("RIGHT", strip, "RIGHT", -8, 0)
        E.AttachBack(strip.back)
    end
    SyncStrip()
    PlaceStrip()
    strip:Show()
end

-- Die Leiste traegt einen geschuetzten Knopf: im Kampf darf ein Addon sie
-- nicht ausblenden. Daher schon beim Kampfbeginn (PLAYER_REGEN_DISABLED
-- kommt, bevor die Sperre greift) und sonst nach dem Kampf.
function E.HideStrip()
    if not strip then return end
    if K.InCombat() then K.AfterCombat(E.HideStrip) return end
    strip:Hide()
end

local combatEvents = CreateFrame("Frame")
combatEvents:RegisterEvent("PLAYER_REGEN_DISABLED")
combatEvents:SetScript("OnEvent", function()
    if strip and strip:IsShown() then strip:Hide() end
end)

function E.StripShown() return strip ~= nil and strip:IsShown() end
function E.StripButton() return strip and strip.back end   -- fuer den Prueflauf

-- Auf- und Zugehen des Bearbeitungsmodus mitbekommen. HookScript
-- veraendert das Fenster des Spiels nicht.
local hooked = false
function E.HookGame()
    if hooked then return true end
    local f = E.GameFrame()
    if not (f and f.HookScript) then return false end
    hooked = true
    f:HookScript("OnShow", E.ShowStrip)
    f:HookScript("OnHide", function()
        E.HideStrip()
        bridge.pending = false
        -- Erst wenn das Spiel fertig ist (es speichert beim Schliessen).
        if _G.C_Timer and _G.C_Timer.After then
            _G.C_Timer.After(0, E.BackFromGame)
        else
            E.BackFromGame()
        end
    end)
    return true
end

local hookEvents = CreateFrame("Frame")
hookEvents:RegisterEvent("PLAYER_LOGIN")
hookEvents:RegisterEvent("ADDON_LOADED")
hookEvents:SetScript("OnEvent", function(self, event, name)
    if event == "ADDON_LOADED" and name ~= "Blizzard_EditMode" then return end
    if E.HookGame() then self:UnregisterAllEvents() end
end)

K.Listen(function(kind, a)
    if kind == "unlock" then
        if a then E.Enter() else E.Leave() end
    elseif kind == "moverSelect" then
        E.UpdateInfo()
    elseif kind == "moverOpen" then
        E.OpenSettings(a)
    end
end)
