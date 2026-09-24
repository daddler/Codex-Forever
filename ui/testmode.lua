--------------------------------------------------
-- WeintCodex :: Oberflaeche - Testmodus
--------------------------------------------------
-- Alles auf einem Bildschirm, ohne Gruppe und ohne Kampf: Ziel, Ziel des
-- Ziels, Fokus, Begleiter, eine Beispielgruppe, laufende Zauberbalken,
-- Kombopunkte und Zeilen in der Schadensanzeige (docs/design/ui-2.0.md,
-- Phase 1). Bis 6.0.0.6 sah man Gruppenrahmen oder Zauberbalken erst im
-- naechsten Beta-Test - und jede Runde kostete einen.
--
-- EHRLICH BLEIBEN. Die Namen und Zahlen sind erfunden. Solange der
-- Testmodus laeuft, steht oben mittig ein Band "Testmodus - Beispieldaten"
-- mit einem Knopf zum Beenden, und die Schadensanzeige schreibt
-- "Beispiel" in ihre Kopfzeile. Auren zeigt er nicht: die liest das Spiel
-- selbst (ui/auras.lua), Beispielauren liessen sich nur vortaeuschen.
--
-- Nur ausserhalb des Kampfes. Beginnt ein Kampf, endet der Testmodus;
-- die geschuetzten Rahmen bekommen ihre Einheit danach zurueck.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UITestMode = {}

local T = WeintCodex.UITestMode
local K = WeintCodex.UIKit
local C = WeintCodex.Colors

local on = false
local banner

function T.IsOn() return on end

local function Banner()
    if banner then return banner end
    local f = CreateFrame("Frame", "WeintCodexTestBanner", UIParent)
    f:SetFrameStrata("DIALOG")
    f:SetSize(360, 30)
    f:SetPoint("TOP", UIParent, "TOP", 0, -64)
    K.Kachel(f)
    local t = K.NewText(f, 12)
    t:SetPoint("LEFT", f, "LEFT", 12, 0)
    t:SetTextColor(unpack(C.textBright))
    t:SetText("Testmodus – Beispieldaten")
    local b = WeintCodex.CreateButton(f, { text = "Beenden", kind = "primary", height = 22 })
    b:SetPoint("RIGHT", f, "RIGHT", -4, 0)
    b:SetScript("OnClick", function() T.Set(false) end)
    f:Hide()
    banner = f
    return f
end

local function Each(fn)
    for _, name in ipairs({ "UIUnitFrames", "UIGroupFrames", "UIDamageMeter" }) do
        local mod = WeintCodex[name]
        if mod and mod.ShowTest then
            local ok, err = pcall(fn, mod)
            if not ok then K.Report("testmodus", err) end
        end
    end
end

function T.Set(want)
    want = want and true or false
    if want and K.InCombat() then
        print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " Den Testmodus gibt es nur außerhalb des Kampfes.")
        return
    end
    if want == on then return end
    on = want
    -- Nur Module, die laufen: ein abgeschaltetes Modul hat keine Rahmen.
    Each(function(mod)
        local key = (mod == WeintCodex.UIUnitFrames and "unitframes")
            or (mod == WeintCodex.UIGroupFrames and "groupframes") or "damagemeter"
        if K.IsActive(key) then mod.ShowTest(on) end
    end)
    WeintCodex.UIPresence.Force("test", on)
    if on then Banner():Show() elseif banner then banner:Hide() end
    K.Fire("test", on)
end

function T.Toggle() T.Set(not on) end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_REGEN_DISABLED")
ev:SetScript("OnEvent", function()
    if on then T.Set(false) end
end)
