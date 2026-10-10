--------------------------------------------------
-- WeintCodex :: Rechtsklick auf die Minikarte oeffnet die Weltkarte
--------------------------------------------------
-- Seit 6.27.0.0 (Beta-Test: "Rechtsklick auf die Minikarte duerfte gerne
-- die Map oeffnen"). Komfort, geht ohne Oberflaeche; Schalter auf der
-- Seite "Karte". Seit 6.27.0.3 (Beta-Test: "er macht dennoch einen Ping")
-- ersetzt WeintCodex den Klick der Minikarte, statt sich nur anzuhaengen:
-- rechts oeffnet die Karte und geht NICHT an das Spiel weiter (kein Ping),
-- alles andere ruft den Klick des Spiels wie bisher. Ist der Schalter aus,
-- geht auch rechts unveraendert an das Spiel.
--
-- Im Kampf nicht: die Weltkarte ist ein geschuetztes Fenster, und ein
-- Aufruf aus einem Addon wird dann gesperrt (ADDON_ACTION_BLOCKED faengt
-- kein pcall). Dann bleibt der Klick ohne Wirkung, statt einen Fehler zu
-- zeigen.
--------------------------------------------------

local K = WeintCodex.UIKit
local KEY = "comfort"

WeintCodex.UIMinimapClick = {}
local MC = WeintCodex.UIMinimapClick

MC.DEFAULTS = { minimapRightMap = true }

function MC.Active() return K.IsActive(KEY) and K.Get(KEY, "minimapRightMap") and true or false end

-- Ein Klick: true, wenn die Karte auf- oder zugeklappt wurde.
function MC.OnClick(button)
    if button ~= "RightButton" or not MC.Active() then return false end
    if K.InCombat() then return false end
    local toggle = _G.ToggleWorldMap
    if type(toggle) ~= "function" then return false end
    pcall(toggle)
    MC.clicks = (MC.clicks or 0) + 1
    return true
end

local hooked     -- die Minikarte, an der der Klick schon haengt
function MC.Hook()
    local mm = _G.Minimap
    if type(mm) ~= "table" or hooked == mm or not (mm.GetScript and mm.SetScript) then return false end
    hooked = mm
    local orig = mm:GetScript("OnMouseUp")
    MC.orig = orig
    mm:SetScript("OnMouseUp", function(self, button, ...)
        if button == "RightButton" and MC.Active() then
            MC.OnClick(button)   -- im Kampf ohne Wirkung, aber auch ohne Ping
            return
        end
        if orig then return orig(self, button, ...) end
    end)
    return true
end

function MC.BuildRows(B)
    B:Row({ type = "toggle", label = "Rechtsklick auf die Minikarte: Weltkarte", key = "minimapRightMap",
            description = "Öffnet und schließt die große Karte. Im Kampf nicht – das lässt das Spiel nicht zu." }, nil)
end

local mod = K.Module(KEY)
if mod then
    for k, v in pairs(MC.DEFAULTS) do
        if mod.defaults[k] == nil then mod.defaults[k] = v end
    end
end

local boot = CreateFrame("Frame")
boot:RegisterEvent("PLAYER_LOGIN")
boot:SetScript("OnEvent", function() MC.Hook() end)
MC.boot = boot
