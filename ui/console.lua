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

CO.BARS = { "MainActionBar", "MainMenuBar", "MultiBarBottomLeft", "MultiBarBottomRight", "MultiBar5" }
CO.PAD = 8            -- Luft ueber der hoechsten Leiste
CO.MIN_H = 60
CO.RING = 1.28        -- Ring im Verhaeltnis zur Karte

function CO.Active()
    if not (K.UIEnabled and K.UIEnabled()) then return false end
    return K.LookKey and K.LookKey() == "konsole" or false
end

local frame, strip, ringTex
local function Build()
    if frame then return end
    frame = CreateFrame("Frame", "WeintCodexConsole", UIParent)
    frame:SetFrameStrata("BACKGROUND")
    frame:SetFrameLevel(1)
    frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, 0)
    frame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, 0)
    frame:SetHeight(CO.MIN_H)
    frame:EnableMouse(false)
    strip = frame:CreateTexture(nil, "BACKGROUND")
    strip:SetAllPoints(frame)
    strip:SetTexture(K.MEDIA .. "console_plate")
    local ring = CreateFrame("Frame", "WeintCodexConsoleRing", UIParent)
    ring:SetFrameStrata("BACKGROUND")
    ring:SetFrameLevel(5)
    ring:EnableMouse(false)
    ringTex = ring:CreateTexture(nil, "ARTWORK")
    ringTex:SetAllPoints(ring)
    CO.ring = ring
end

-- Oberkante der hoechsten Leiste unten (Einheiten von UIParent), oder nil.
function CO.BarTop()
    local top
    for _, n in ipairs(CO.BARS) do
        local b = _G[n]
        if type(b) == "table" and b.IsVisible and K.Bool(b:IsVisible(), false) and b.GetTop then
            local t = K.Plain(b:GetTop())
            local s = b.GetEffectiveScale and K.Plain(b:GetEffectiveScale())
            local us = UIParent.GetEffectiveScale and K.Plain(UIParent:GetEffectiveScale())
            if type(t) == "number" and type(s) == "number" and type(us) == "number" and us > 0 then
                t = t * s / us
                -- nur, was unten liegt (eine Leiste ganz oben zaehlt nicht)
                if t < 300 and (not top or t > top) then top = t end
            end
        end
    end
    return top
end

function CO.Update()
    if not CO.Active() then
        if frame then frame:Hide() CO.ring:Hide() end
        return false
    end
    Build()
    local top = CO.BarTop()
    frame:SetHeight(math.max(CO.MIN_H, (top or 0) + CO.PAD))
    frame:Show()
    local mm = _G.Minimap
    local w = type(mm) == "table" and mm.GetWidth and K.Plain(mm:GetWidth())
    if type(w) == "number" and w > 0 then
        local square = K.Get and K.Get("minimap", "square")
        ringTex:SetTexture(K.MEDIA .. (square and "console_square" or "console_ring"))
        local ring = CO.ring
        ring:ClearAllPoints()
        ring:SetPoint("CENTER", mm, "CENTER", 0, 0)
        ring:SetSize(w * CO.RING, w * CO.RING)
        ring:Show()
    else
        CO.ring:Hide()
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
