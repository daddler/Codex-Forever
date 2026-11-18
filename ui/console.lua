--------------------------------------------------
-- WeintCodex :: Oberflaeche - Design "Konsole"
--------------------------------------------------
-- 1.0.7.44, Wunsch: "als viertes Design so, wie Spartan UI es macht"
-- (Bild: unten eine durchgehende Konsole, die Leisten links und rechts
-- darin, die Minikarte in einem Ring in der Mitte). Nur das Verhalten ist
-- angelehnt - kein Code und kein Bild von SpartanUI. Die Bilder rechnet
-- .github/scripts/make_console_media.py.
--
-- Die Plaetze stehen in ui/layout.lua (K.LOOK_LAYOUT.konsole). Hier wird
-- nur gezeichnet, und zwar um das, was wirklich steht: die Leiste ist so
-- hoch wie die hoechste Aktionsleiste unten, der Ring liegt um die Karte -
-- wer etwas verschiebt, bekommt die Konsole mit. Nur eigene Rahmen, nichts
-- Geschuetztes; im Kampf wird nur gelesen und eigenes gesetzt.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIConsole = {}

local CO = WeintCodex.UIConsole
local K  = WeintCodex.UIKit

CO.H = 208            -- Hoehe der Bilder (256 px Bild = 208 Einheiten)
CO.CENTER_W = 416     -- Mittelstueck (512 px)
-- Leisten, hinter die ein Schacht kommt (Rahmen des Spiels).
CO.SLOT_BARS = { { "MainActionBar", "MainMenuBar" }, { "MultiBarBottomLeft" }, { "MultiBarBottomRight" },
                 { "MultiBar5" }, { "MultiBarLeft" }, { "MultiBarRight" } }
CO.SLOT_PAD = 5

function CO.Active()
    if not (K.UIEnabled and K.UIEnabled()) then return false end
    return K.LookKey and K.LookKey() == "konsole" or false
end

local frame, slots = nil, {}
local function Tex(parent, file, layer, sub)
    local t = parent:CreateTexture(nil, layer, nil, sub)
    t:SetTexture(K.MEDIA .. file)
    return t
end
local function Build()
    if frame then return end
    frame = CreateFrame("Frame", "WeintCodexConsole", UIParent)
    frame:SetFrameStrata("BACKGROUND")
    frame:SetFrameLevel(3)
    frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, 0)
    frame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, 0)
    frame:SetHeight(CO.H)
    frame:EnableMouse(false)
    local half = CO.CENTER_W / 2 - 6
    local left = Tex(frame, "console_side", "BACKGROUND", 0)
    left:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    left:SetPoint("TOPRIGHT", frame, "TOP", -half, 0)
    local right = Tex(frame, "console_side", "BACKGROUND", 0)
    right:SetTexCoord(1, 0, 0, 1)             -- gespiegelt
    right:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    right:SetPoint("TOPLEFT", frame, "TOP", half, 0)
    local mid = Tex(frame, "console_center", "BORDER", 0)
    mid:SetSize(CO.CENTER_W, CO.H)
    mid:SetPoint("BOTTOM", frame, "BOTTOM", 0, 0)
    CO.parts = { left = left, right = right, mid = mid }
end

-- Schacht hinter einer Leiste: eigener Rahmen, an der Leiste verankert
-- (eigenes an Geschuetztem ist erlaubt, nicht umgekehrt).
local function Slot(i, bar)
    local s = slots[i]
    if not s then
        s = CreateFrame("Frame", nil, frame)
        s:SetFrameStrata("BACKGROUND")
        s:SetFrameLevel(5)
        local t = Tex(s, "console_slot", "ARTWORK", 0)
        t:SetAllPoints(s)
        slots[i] = s
    end
    s:ClearAllPoints()
    s:SetPoint("TOPLEFT", bar, "TOPLEFT", -CO.SLOT_PAD, CO.SLOT_PAD)
    s:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", CO.SLOT_PAD, -CO.SLOT_PAD)
    return s
end

-- 1.0.7.49-1.0.7.53 standen hier Zierplatten/Schultern hinter Spieler und
-- Ziel. 1.0.7.54 (Wunsch mit Bild: "genau so, alles andere ist zu dick"):
-- keine - die Rahmen sitzen selbst auf der Oberkante, das Portraet innen am
-- Ring (Plaetze in ui/layout.lua).

function CO.Update()
    if not CO.Active() then
        if frame then frame:Hide() end
        return false
    end
    Build()
    frame:Show()
    for i, names in ipairs(CO.SLOT_BARS) do
        local bar
        for _, n in ipairs(names) do
            local f = _G[n]
            if type(f) == "table" and f.GetTop then bar = f break end
        end
        local shown = bar and bar.IsVisible and K.Bool(bar:IsVisible(), false)
        if shown then
            Slot(i, bar):Show()
        elseif slots[i] then
            slots[i]:Hide()
        end
    end
    return true
end

do
    local ev = CreateFrame("Frame")
    for _, e in ipairs({ "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_ENABLED", "EDIT_MODE_LAYOUTS_UPDATED", "UI_SCALE_CHANGED" }) do
        pcall(ev.RegisterEvent, ev, e)
    end
    ev:SetScript("OnEvent", function()
        if _G.C_Timer and _G.C_Timer.After then
            _G.C_Timer.After(0.5, CO.Update)
            _G.C_Timer.After(3, CO.Update)
        else
            CO.Update()
        end
    end)
end
