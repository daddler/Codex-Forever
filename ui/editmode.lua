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
    local a = C.accent
    Line(true, cx, a, 0.6)
    Line(false, cy, a, 0.35)
    grid:Hide()
    return grid
end

--------------------------------------------------
-- Leiste
--------------------------------------------------

local function ToggleText(label, on) return label .. (on and ": an" or ": aus") end

local function Sync()
    if not bar then return end
    buttons.test:SetText(ToggleText("Testdaten", state.test))
    buttons.grid:SetText(ToggleText("Raster", state.grid))
    buttons.snap:SetText(ToggleText("Einrasten", state.snap))
    buttons.reset:SetText(armedReset and "Wirklich alles?" or "Alles zurücksetzen")
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

local function Button(text, kind, onClick)
    local b = WeintCodex.CreateButton(bar, { text = text, kind = kind or "secondary", height = 24, size = 11 })
    b:SetScript("OnClick", onClick)
    return b
end

local function BuildBar()
    if bar then return bar end
    bar = CreateFrame("Frame", "WeintCodexDesignBar", UIParent)
    bar:SetFrameStrata("FULLSCREEN_DIALOG")
    bar:SetSize(760, 38)
    bar:SetPoint("TOP", UIParent, "TOP", 0, -14)
    bar:EnableMouse(true)
    K.Kachel(bar)

    local title = K.NewText(bar, 13)
    title:SetPoint("LEFT", bar, "LEFT", 14, 0)
    title:SetTextColor(unpack(C.textBright))
    title:SetText("Gestaltungsmodus")

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

    buttons.done:SetPoint("RIGHT", bar, "RIGHT", -8, 0)
    buttons.reset:SetPoint("RIGHT", buttons.done, "LEFT", -10, 0)
    buttons.snap:SetPoint("RIGHT", buttons.reset, "LEFT", -6, 0)
    buttons.grid:SetPoint("RIGHT", buttons.snap, "LEFT", -6, 0)
    buttons.test:SetPoint("RIGHT", buttons.grid, "LEFT", -6, 0)

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

function E.Enter()
    BuildBar()
    local O = WeintCodex.UIOptions
    if O and O.frame and O.frame:IsShown() then
        reopen = true
        O.frame:Hide()
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
end

function E.Leave()
    if bar then bar:Hide() end
    if grid then grid:Hide() end
    local T = WeintCodex.UITestMode
    if startedTest and T and T.IsOn() then T.Set(false) end
    startedTest = false
    -- Zurueck ins Fenster - nicht, wenn ein Kampf den Modus beendet hat.
    if reopen and not K.InCombat() then
        local O = WeintCodex.UIOptions
        if O and O.Show then O.Show() end
    end
    reopen = false
end

-- Welche Einstellungsseite zu welchem Rahmen gehoert.
local MODULE_OF = {
    uf_ = "unitframes", gf_ = "groupframes", damagemeter = "damagemeter", bags = "bags",
    questarrow = "questarrow", combatalert = "comfort", fps = "comfort", durability = "comfort",
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

K.Listen(function(kind, a)
    if kind == "unlock" then
        if a then E.Enter() else E.Leave() end
    elseif kind == "moverSelect" then
        E.UpdateInfo()
    elseif kind == "moverOpen" then
        E.OpenSettings(a)
    end
end)
