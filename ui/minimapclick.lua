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
    if K.MapTaintNote then K.MapTaintNote("Rechtsklick auf die Minikarte (direkt geöffnet)") end
    MC.clicks = (MC.clicks or 0) + 1
    return true
end

-- 1.0.6.7 (Fehlerberichte "Blockiert: SetPassThroughButtons" /
-- "SetPropagateMouseClicks" aus der Weltkarte): ToggleWorldMap aus einem
-- Addon verunreinigt die Weltkarte bis zum Neuladen. Wo es geht, liegt
-- deshalb ein geschuetzter Makroknopf ueber der Minikarte, der NUR den
-- Rechtsklick nimmt und den Kartenknopf des Spiels klickt
-- (WeintCodex.AttachMapToggle). Links-/Mittelklick und Mausbewegung gehen
-- an die Minikarte darunter (Ping, Tooltips der Punkte). Im Kampf ist der
-- Knopf abgehaengt - Rechtsklick pingt dann wie im Spiel. Fehlt ein Teil
-- davon (Kartenknopf, Durchreichen), bleibt der alte Weg unten.
MC.PASS = { "LeftButton", "MiddleButton", "Button4", "Button5" }
function MC.Overlay()
    if MC.overlay then return MC.overlay end
    if MC.overlayTried then return nil end
    local mm = _G.Minimap
    if type(mm) ~= "table" or not WeintCodex.AttachMapToggle then return nil end
    if K.InCombat() then return nil end
    MC.overlayTried = true
    local probe = mm
    if type(probe.SetPassThroughButtons) ~= "function" or type(probe.SetMouseMotionEnabled) ~= "function" then return nil end
    local ok, ov = pcall(WeintCodex.AttachMapToggle, mm, "RightButtonUp", 1)
    if not ok or not ov then return nil end
    -- Nur Klicks, keine Bewegung: die Minikarte bleibt unter der Maus.
    local fine = pcall(ov.SetMouseMotionEnabled, ov, false)
    fine = fine and pcall(ov.SetPassThroughButtons, ov, unpack(MC.PASS))
    if not fine then
        pcall(ov.Hide, ov)
        return nil
    end
    ov:SetScript("OnEnter", nil)
    ov:SetScript("OnLeave", nil)
    ov:HookScript("OnClick", function() MC.clicks = (MC.clicks or 0) + 1 end)
    MC.overlay = ov
    return ov
end

-- Schalter an/aus: den Knopf zeigen oder verbergen (nie im Kampf).
function MC.Sync()
    local ov = MC.overlay
    if not ov then return end
    local want = MC.Active()
    if MC.overlayOn == want then return end
    if K.InCombat() then K.AfterCombat(MC.Sync) return end
    MC.overlayOn = want
    if want then ov:Show() else ov:Hide() end
end

local hooked     -- die Minikarte, an der der Klick schon haengt
function MC.Hook()
    local mm = _G.Minimap
    if type(mm) ~= "table" or hooked == mm or not (mm.GetScript and mm.SetScript) then return false end
    -- Sauberer Weg zuerst; dann bleibt der Klick der Minikarte unberuehrt.
    if MC.Overlay() then
        hooked = mm
        MC.Sync()
        return true
    end
    if K.InCombat() then K.AfterCombat(MC.Hook) return false end
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
boot:SetScript("OnEvent", WeintCodex.Measured("Minikarte: Klick", function() MC.Hook() end))
MC.boot = boot
if K.Listen then K.Listen(function() MC.Sync() end) end
