--------------------------------------------------
-- WeintCodex :: Oberflaeche - Symbol an der Minikarte (6.9.0.0)
--------------------------------------------------
-- Beta-Test 6.9.0.0: "Wenn man sich fuer die UI entscheidet, muss auch ein
-- Minimap-Icon fuer WeintCodexUI zu sehen sein."
--
-- Ein zweites Symbol neben dem von WeintCodex (core/minimap.lua), ueber
-- dieselbe Bibliothek (LibDataBroker + LibDBIcon) - es landet damit auch in
-- der Knopfspalte der Minikarte (ui/minimap.lua), wie jedes Addon-Symbol.
--
--   Linksklick    Einstellungen der Oberflaeche (/wcui) auf/zu
--   Rechtsklick   Gestaltungsmodus: Rahmen verschieben (nie im Kampf)
--
-- NUR MIT OBERFLAECHE. Ohne sie gibt es nichts, was das Symbol oeffnen
-- muesste, das nicht auch /wcui oder das Symbol von WeintCodex kann -
-- also kein zweiter Knopf fuer jemanden, der "Nein" gesagt hat. Schaltet
-- jemand die Oberflaeche im Spiel ein oder aus, kommt bzw. geht es sofort.
-- Abschalten laesst es sich in /wcui -> Allgemein; gespeichert in
-- WeintCodex_SavedData.ui.launcher (LibDBIcon fuehrt dort auch den Platz).
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UILauncher = {}

local LN = WeintCodex.UILauncher
local K = WeintCodex.UIKit

LN.NAME = "WeintCodexUI"
LN.ICON = K.MEDIA .. "icon_gear"

local function Libs()
    local ls = _G.LibStub
    if type(ls) ~= "table" then return nil end
    local okA, ldb = pcall(ls.GetLibrary, ls, "LibDataBroker-1.1", true)
    local okB, icon = pcall(ls.GetLibrary, ls, "LibDBIcon-1.0", true)
    if not (okA and ldb and okB and icon) then return nil end
    return ldb, icon
end

-- Gespeicherter Zustand (hide, Platz an der Karte). Nie eine Ersatztabelle:
-- ohne Speicher gibt es nichts zu merken.
function LN.DB()
    local ui = K.Root()
    if not ui then return nil end
    ui.launcher = ui.launcher or { hide = false }
    return ui.launcher
end

-- Soll das Symbol zu sehen sein?
function LN.Wanted()
    local db = LN.DB()
    return K.UIEnabled() and db ~= nil and not db.hide
end

local function Say(text)
    print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " " .. text)
end

function LN.Click(button)
    if button == "RightButton" then
        if K.InCombat() then
            Say("Im Kampf lassen sich keine Rahmen verschieben.")
            return
        end
        K.SetUnlocked(not K.IsUnlocked())
        return
    end
    local O = WeintCodex.UIOptions
    if O and O.Toggle then O.Toggle() end
end

function LN.Tooltip(tt)
    tt:AddLine(WeintCodex.AC .. "WeintCodex-Oberfläche|r")
    tt:AddLine("|cffA0A0ACPlaketten, Rahmen, Leisten, Fenster|r")
    tt:AddLine(" ")
    tt:AddDoubleLine("|cff34C77BLinksklick|r", "Einstellungen (/wcui)", 1, 1, 1, 0.85, 0.85, 0.85)
    tt:AddDoubleLine(WeintCodex.AC .. "Rechtsklick|r",
        K.IsUnlocked() and "Gestaltung beenden" or "Rahmen verschieben", 1, 1, 1, 0.85, 0.85, 0.85)
end

local launcher
function LN.Object()
    if launcher then return launcher end
    local ldb = Libs()
    if not ldb then return nil end
    launcher = ldb:NewDataObject(LN.NAME, {
        type = "launcher",
        icon = LN.ICON,
        label = "WeintCodex-Oberfläche",
        OnClick = function(_, button) LN.Click(button) end,
        OnTooltipShow = function(tt) LN.Tooltip(tt) end,
    })
    return launcher
end

-- Anmelden (einmal) und zeigen oder verstecken, wie gewuenscht.
-- Gibt zurueck, ob das Symbol jetzt zu sehen sein soll.
function LN.Sync()
    local _, icon = Libs()
    local db = LN.DB()
    if not (icon and db) then return false end
    local want = LN.Wanted()
    local registered = icon.IsRegistered and icon:IsRegistered(LN.NAME)
    if want and not registered then
        local obj = LN.Object()
        if obj then pcall(icon.Register, icon, LN.NAME, obj, db) end
        registered = icon.IsRegistered and icon:IsRegistered(LN.NAME)
    end
    if registered then
        if want then pcall(icon.Show, icon, LN.NAME) else pcall(icon.Hide, icon, LN.NAME) end
    end
    return want
end

-- Schalter in /wcui: das Feld UND der Knopf (LibDBIcon liest das Feld
-- sonst erst beim naechsten Laden).
function LN.SetShown(on)
    local db = LN.DB()
    if not db then return end
    db.hide = not on
    LN.Sync()
end
function LN.IsShown() return LN.Wanted() end

-- Hauptschalter umgelegt: sofort folgen.
K.Listen(function(kind, module, key)
    if kind == "setting" and module == "general" and key == "enabled" then LN.Sync() end
end)

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function()
    local ok, err = pcall(LN.Sync)
    if not ok then K.Report("symbol", err) end
end)
