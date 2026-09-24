--------------------------------------------------
-- WeintCodex :: Oberflaeche - Questliste
--------------------------------------------------
-- Die Zielverfolgung des Spiels (Quests, Erfolge, Berufe) bekommt eine
-- eigene, abgesetzte Flaeche: dunkler Grund, feiner Rand, ohne das
-- goldene Banner "Alle Ziele". So steht die Questliste in EllesmereUI
-- vom Rest des Bildschirms getrennt.
--
-- DIE LISTE SELBST BLEIBT DIE DES SPIELS. Ihre Zeilen, Klicks und
-- Questgegenstaende laufen ueber Blizzards Code - der ist empfindlich
-- gegen Taint (Questgegenstaende im Kampf). Diese Datei legt nur einen
-- EIGENEN Rahmen dahinter und macht Hintergrundtexturen durchsichtig;
-- an die Liste selbst fasst sie nichts an.
--
-- Die Flaeche waechst mit dem Inhalt: die Hoehe des Rahmens stellt der
-- Bearbeitungsmodus ein, gefuellt ist oft nur ein Teil davon. Gemessen
-- wird nach jedem Aktualisieren der Liste die Unterkante der untersten
-- sichtbaren Zeile.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIQuestTracker = {}

local QT = WeintCodex.UIQuestTracker
local K  = WeintCodex.UIKit
local C  = WeintCodex.Colors
local KEY = "questtracker"

local defaults = {
    bgAlpha     = 75,
    border      = true,
    hideBanner  = true,
    padding     = 8,
}

local function Opt(k) return K.Get(KEY, k) end

local panel, border

local function Tracker()
    local t = _G.ObjectiveTrackerFrame
    if type(t) == "table" and t.GetTop and not (t.IsForbidden and t:IsForbidden()) then return t end
    return nil
end

-- Hintergrundtexturen des Spiels durchsichtig machen: das Banner oben
-- und die Kopfzeilen der einzelnen Abschnitte (Quests, Erfolge ...).
-- ALLE Texturen der Kopfzeile, nicht eine mit Namen: in 6.0.0.5 hiess
-- das Banner auf Forever anders als erwartet und blieb stehen. Knoepfe
-- (Einklappen) sind Rahmen, keine Texturen, und bleiben; Text ebenso.
local function FadeTextures(frame)
    if type(frame) ~= "table" or not frame.GetRegions then return end
    for _, r in ipairs({ frame:GetRegions() }) do
        if type(r) == "table" and r.GetObjectType and r:GetObjectType() == "Texture" and r.SetAlpha then
            r:SetAlpha(0)
        end
    end
end

local function HideArt(t)
    if not Opt("hideBanner") then return end
    FadeTextures(t.Header)
    FadeTextures(t)
    for _, child in ipairs({ t:GetChildren() }) do
        if type(child) == "table" then FadeTextures(child.Header) end
    end
    -- Kopfzeilen in der Schrift von WeintCodex, hell statt gold.
    local function title(h)
        local fs = type(h) == "table" and (h.Text or h.Title)
        if type(fs) == "table" and fs.SetTextColor then
            K.SetFont(fs, 13)
            fs:SetTextColor(unpack(C.textBright))
        end
    end
    title(t.Header)
    for _, child in ipairs({ t:GetChildren() }) do
        if type(child) == "table" then title(child.Header) end
    end
    -- Der Hintergrund des ganzen Rahmens (Bearbeitungsmodus-Rahmen).
    local ns = t.NineSlice
    if type(ns) == "table" and ns.SetAlpha then ns:SetAlpha(0) end
end

-- Die Unterkante des untersten sichtbaren Teils (Bildschirmkoordinaten).
local function ContentBottom(t)
    local bottom
    for _, child in ipairs({ t:GetChildren() }) do
        if type(child) == "table" and child ~= panel and child.IsVisible and child:IsVisible() then
            local b = child.GetBottom and child:GetBottom()
            if type(b) == "number" and (not bottom or b < bottom) then bottom = b end
        end
    end
    return bottom
end

function QT.Apply()
    local t = Tracker()
    if not t or not panel then return end
    local bg = C.bgDark
    panel.bg:SetColorTexture(bg[1], bg[2], bg[3], (Opt("bgAlpha") or 75) / 100)
    border:SetShown(Opt("border"))
    local b = C.border
    border:SetColor(b[1], b[2], b[3], 1)
    HideArt(t)

    local pad = Opt("padding") or 8
    panel:ClearAllPoints()
    panel:SetPoint("TOPLEFT", t, "TOPLEFT", -pad, pad)
    panel:SetPoint("TOPRIGHT", t, "TOPRIGHT", pad, pad)
    local top, bottom = t:GetTop(), ContentBottom(t)
    if type(top) == "number" and type(bottom) == "number" and top > bottom then
        panel:SetHeight(top - bottom + 2 * pad)
        panel:SetShown(t:IsVisible())
    else
        -- Nichts zu verfolgen (oder die Groesse unbekannt): keine leere
        -- Flaeche.
        panel:Hide()
    end
end

local Setup

local function Enable()
    if Tracker() then return Setup() end
    -- Die Zielverfolgung laedt das Spiel womoeglich erst spaeter nach.
    local wait = CreateFrame("Frame")
    wait:RegisterEvent("ADDON_LOADED")
    wait:SetScript("OnEvent", function(self, _, name)
        if name == "Blizzard_ObjectiveTracker" and Tracker() and not panel then
            self:UnregisterAllEvents()
            Setup()
        end
    end)
end

function Setup()
    local t = Tracker()
    if not t or panel then return end
    panel = CreateFrame("Frame", "WeintCodexQuestPanel", UIParent)
    panel:SetFrameStrata("BACKGROUND")
    panel.bg = panel:CreateTexture(nil, "BACKGROUND")
    panel.bg:SetAllPoints(panel)
    border = K.Border(panel, 1, 0, 0, 0, 1, "BORDER")
    K.Glow(panel, { spread = 7, shadow = true })
    panel:Hide()

    if _G.hooksecurefunc then
        for _, m in ipairs({ "Update", "UpdateHeight", "Layout" }) do
            if type(t[m]) == "function" then _G.hooksecurefunc(t, m, function() QT.Apply() end) end
        end
    end
    if t.HookScript then
        t:HookScript("OnShow", function() QT.Apply() end)
        t:HookScript("OnHide", function() if panel then panel:Hide() end end)
    end
    local ev = CreateFrame("Frame")
    for _, e in ipairs({ "PLAYER_ENTERING_WORLD", "QUEST_LOG_UPDATE", "QUEST_WATCH_LIST_CHANGED" }) do
        pcall(ev.RegisterEvent, ev, e)
    end
    -- Einen Takt spaeter: das Spiel ordnet seine Liste auf dasselbe
    -- Ereignis hin erst an.
    ev:SetScript("OnEvent", function()
        if _G.C_Timer and _G.C_Timer.After then _G.C_Timer.After(0, QT.Apply) else QT.Apply() end
    end)
    QT.Apply()
end

function QT.Panel() return panel end

local function px(v) return string.format("%d px", v) end

K.Register({
    key = KEY, group = "ui", order = 60,
    title = "Questliste",
    description = "Die Zielverfolgung des Spiels auf einer eigenen, abgesetzten Fläche – ohne das goldene Banner.",
    defaults = defaults,
    Enable = Enable,
    OnSetting = function() QT.Apply() end,
    pages = {
        { key = "allgemein", label = "Allgemein", build = function(B)
            B:Section("Fläche")
            B:Row({ type = "slider", label = "Deckkraft", key = "bgAlpha", min = 0, max = 100, step = 5,
                    format = function(v) return string.format("%d %%", v) end },
                  { type = "slider", label = "Innenabstand", key = "padding", min = 0, max = 20, step = 1, format = px })
            B:Row({ type = "toggle", label = "Rand", key = "border" },
                  { type = "toggle", label = "Goldenes Banner ausblenden", key = "hideBanner", reload = true })
            B:Note("Die Liste selbst bleibt die des Spiels: Quests anklicken, verfolgen und Questgegenstände benutzen funktionieren wie gewohnt. Wo sie steht und wie hoch sie sein darf, stellst du im Bearbeitungsmodus ein.")
        end },
    },
})
