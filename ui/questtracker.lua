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
    -- Im Dungeon nur die Quests dieses Dungeons verfolgen (Beta-Test
    -- 6.3.2.8: "nur noch die fuer den Dungeon, nicht alle").
    dungeonOnly = true,
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
    -- 6.122.2.0: folgt dem Aussehen (Holz, Transparent).
    local b = C.border
    K.LookFill(panel.bg, (Opt("bgAlpha") or 75) / 100, border, { b[1], b[2], b[3], 1 })
    border:SetShown(Opt("border"))
    HideArt(t)

    local pad = Opt("padding") or 8
    panel:ClearAllPoints()
    panel:SetPoint("TOPLEFT", t, "TOPLEFT", -pad, pad)
    panel:SetPoint("TOPRIGHT", t, "TOPRIGHT", pad, pad)
    local top, bottom = t:GetTop(), ContentBottom(t)
    if type(top) == "number" and type(bottom) == "number" and top > bottom then
        panel:SetHeight(top - bottom + 2 * pad)
        -- 0 % heisst: gar keine Flaeche, auch kein Rand und kein Schatten
        -- (Beta-Test: "komplett transparent").
        panel:SetShown(t:IsVisible() and (Opt("bgAlpha") or 75) > 0)
    else
        -- Nichts zu verfolgen (oder die Groesse unbekannt): keine leere
        -- Flaeche.
        panel:Hide()
    end
end

local Setup
local StartDungeonFilter   -- unten, "Im Dungeon: nur seine Quests"

local function Enable()
    StartDungeonFilter()
    if Tracker() then return Setup() end
    -- Die Zielverfolgung laedt das Spiel womoeglich erst spaeter nach.
    local wait = CreateFrame("Frame")
    wait:RegisterEvent("ADDON_LOADED")
    wait:SetScript("OnEvent", WeintCodex.Measured("questtracker", function(self, _, name)
        if name == "Blizzard_ObjectiveTracker" and Tracker() and not panel then
            self:UnregisterAllEvents()
            Setup()
        end
    end))
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
    ev:SetScript("OnEvent", K.Measured("Questliste", function()
        if _G.C_Timer and _G.C_Timer.After then _G.C_Timer.After(0, QT.Apply) else QT.Apply() end
    end))
    QT.Apply()
end

function QT.Panel() return panel end

--------------------------------------------------
-- Im Dungeon: nur seine Quests
--------------------------------------------------
-- Die Liste gehoert dem Spiel; gefiltert wird ueber das, was das Spiel
-- dafuer anbietet: welche Quests VERFOLGT werden. Beim Betreten einer
-- Instanz nimmt WeintCodex alle anderen aus der Verfolgung und nimmt die
-- des Dungeons auf; beim Verlassen stellt es genau das wieder her, was es
-- geaendert hat - nichts sonst.
--
-- Welche Quest zum Dungeon gehoert, sagt der Client auf zwei Wegen:
--   * das Questlog gruppiert nach Gebiet - Dungeonquests stehen unter
--     einer Kopfzeile mit dem Namen des Dungeons (GetInstanceInfo);
--   * isOnMap: die Quest hat Ziele auf der Karte, auf der man steht.
-- Nennt der Client keins von beidem, bleibt die Liste, wie sie ist.
--
-- Gemerkt wird in WeintCodex_SavedData.ui.questWatch. Solange der
-- Beta-Client nichts speichert, geht das Gemerkte bei einem Neuladen IM
-- Dungeon verloren - die herausgenommenen Quests muessen dann von Hand
-- wieder verfolgt werden.

local function QL() return _G.C_QuestLog end

-- 1.0.3.6 (Spieler: "beim Druiden ist die Questliste weg, bei den anderen
-- nicht"): das Gemerkte lag fuer das ganze Konto in ui.questWatch. Wer im
-- Dungeon ausloggte, bekam die herausgenommenen Quests nie zurueck - der
-- naechste Charakter draussen "stellte" sie bei sich wieder her (fremde
-- questIDs) und loeschte das Gemerkte. Jetzt je Charakter; das alte
-- gemeinsame Gemerkte gehoert keinem sicher und wird verworfen.
local function Memory()
    local ui = K.Root()
    local who = K.CharKey()
    if not (ui and who) then return nil end
    ui.questWatch = nil
    ui.questWatchChars = ui.questWatchChars or {}
    local m = ui.questWatchChars[who]
    if not m then
        m = { removed = {}, added = {}, active = false }
        ui.questWatchChars[who] = m
    end
    return m
end
QT.Memory = Memory

-- Instanz, in der man steht: Name, oder nil draussen.
local function InstanceName()
    if not _G.IsInInstance then return nil end
    local inside, kind = _G.IsInInstance()
    kind = K.Plain(kind)
    if not (kind == "party" or kind == "raid" or kind == "scenario") then return nil end
    if not K.Bool(inside, true) then return nil end
    local name = _G.GetInstanceInfo and K.Plain((_G.GetInstanceInfo()))
    return type(name) == "string" and name or nil
end
QT.InstanceName = InstanceName

-- Die Quests des Dungeons (Menge der questIDs) - oder nil, wenn der Client
-- keine Auskunft gibt.
function QT.DungeonQuests(instance)
    local ql = QL()
    if not (ql and ql.GetNumQuestLogEntries and ql.GetInfo) then return nil end
    local n = K.Plain(ql.GetNumQuestLogEntries())
    if type(n) ~= "number" then return nil end
    local set, header = {}, nil
    for i = 1, n do
        local ok, info = pcall(ql.GetInfo, i)
        if ok and type(info) == "table" then
            if info.isHeader then
                header = K.Plain(info.title)
            elseif not info.isHidden and info.questID then
                local id = K.Plain(info.questID)
                if id and (header == instance or K.Bool(info.isOnMap, false)) then set[id] = true end
            end
        end
    end
    return set
end

local function Watched()
    local ql = QL()
    local out = {}
    if not (ql and ql.GetNumQuestWatches and ql.GetQuestIDForQuestWatchIndex) then return out end
    local n = K.Plain(ql.GetNumQuestWatches()) or 0
    for i = 1, n do
        local id = K.Plain(ql.GetQuestIDForQuestWatchIndex(i))
        if id then out[#out + 1] = id end
    end
    return out
end

function QT.EnterDungeon(instance)
    local mem, ql = Memory(), QL()
    if not mem or mem.active or not (ql and ql.AddQuestWatch and ql.RemoveQuestWatch) then return end
    local wanted = QT.DungeonQuests(instance)
    if not wanted then return end
    mem.active, mem.removed, mem.added = instance, {}, {}
    local watched = {}
    for _, id in ipairs(Watched()) do
        watched[id] = true
        if not wanted[id] then
            pcall(ql.RemoveQuestWatch, id)
            mem.removed[#mem.removed + 1] = id
        end
    end
    for id in pairs(wanted) do
        if not watched[id] then
            pcall(ql.AddQuestWatch, id)
            mem.added[#mem.added + 1] = id
        end
    end
end

function QT.LeaveDungeon()
    local mem, ql = Memory(), QL()
    if not mem or not mem.active or not ql then return end
    for _, id in ipairs(mem.added or {}) do pcall(ql.RemoveQuestWatch, id) end
    for _, id in ipairs(mem.removed or {}) do pcall(ql.AddQuestWatch, id) end
    mem.active, mem.removed, mem.added = false, {}, {}
end

-- Einmal je Charakter (1.0.3.6): wer draussen ohne eine einzige verfolgte
-- Quest steht, aber Quests im Log hat, war sehr wahrscheinlich vom Fehler
-- oben betroffen - alle Quests wieder verfolgen (soweit das Spiel laesst).
function QT.RepairWatches()
    local mem, ql = Memory(), QL()
    if not mem or mem.repaired or mem.active or InstanceName() then return end
    if not (ql and ql.AddQuestWatch and ql.GetNumQuestLogEntries and ql.GetInfo) then return end
    mem.repaired = true
    if #Watched() > 0 then return end
    local n = K.Plain(ql.GetNumQuestLogEntries())
    if type(n) ~= "number" then return end
    local added = 0
    for i = 1, n do
        local ok, info = pcall(ql.GetInfo, i)
        if ok and type(info) == "table" and not info.isHeader and not info.isHidden and info.questID then
            local id = K.Plain(info.questID)
            if id and pcall(ql.AddQuestWatch, id) then added = added + 1 end
        end
    end
    return added
end

function QT.CheckDungeon()
    local instance = InstanceName()
    local mem = Memory()
    if not instance then QT.RepairWatches() end
    if instance and K.Get(KEY, "dungeonOnly") then
        -- In einen anderen Dungeon gewechselt: erst zurueck, dann neu.
        if mem and mem.active and mem.active ~= instance then QT.LeaveDungeon() end
        QT.EnterDungeon(instance)
    elseif mem and mem.active then
        QT.LeaveDungeon()
    end
end

local dungeonEvents = CreateFrame("Frame")
function StartDungeonFilter()
    for _, e in ipairs({ "PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA" }) do
        pcall(dungeonEvents.RegisterEvent, dungeonEvents, e)
    end
    dungeonEvents:SetScript("OnEvent", K.Measured("Questliste", function()
        -- Das Questlog steht beim Betreten erst einen Moment spaeter; und
        -- die Verfolgung aendert sich nicht im Kampf.
        local function run() K.AfterCombat(QT.CheckDungeon) end
        if _G.C_Timer and _G.C_Timer.After then _G.C_Timer.After(2, run) else run() end
    end))
end

-- 1.0.3.6: /wcui questliste - was mit der Liste des Spiels los ist
-- (Spieler: "beim Druiden weg, bei anderen da").
function QT.Report()
    local out = {}
    local function add(k, v) out[#out + 1] = k .. ": " .. tostring(v) end
    local function call(o, m, ...)
        if type(o) ~= "table" or type(o[m]) ~= "function" then return "?" end
        local ok, a, b, c, d, e = pcall(o[m], o, ...)
        if not ok then return "Fehler" end
        if m == "GetPoint" then
            local rel = type(b) == "table" and b.GetName and b:GetName() or tostring(b)
            return tostring(a) .. " " .. tostring(rel) .. " " .. tostring(c) .. " " .. tostring(K.Plain(d)) .. " " .. tostring(K.Plain(e))
        end
        return tostring(K.Plain(a))
    end
    add("Charakter", K.CharKey())
    add("Modul an", K.IsActive and K.IsActive(KEY))
    local t = _G.ObjectiveTrackerFrame
    add("Rahmen", type(t) == "table" and "da" or "fehlt")
    if type(t) == "table" then
        for _, m in ipairs({ "IsShown", "IsVisible", "GetAlpha", "GetEffectiveScale", "GetLeft", "GetTop",
                             "GetWidth", "GetHeight", "GetPoint", "IsForbidden" }) do
            add(m, call(t, m))
        end
        local p = t.GetParent and t:GetParent()
        add("Eltern", type(p) == "table" and ((p.GetName and p:GetName()) or "?") .. " sichtbar=" .. call(p, "IsVisible") or "keine")
        add("eingeklappt", tostring(t.isCollapsed) .. " / Kopf " .. tostring(type(t.Header) == "table" and t.Header.isCollapsed))
        local n = 0
        for _, c in ipairs({ t:GetChildren() }) do
            if type(c) == "table" and c ~= panel then
                n = n + 1
                if n <= 12 then
                    add("  Teil " .. ((c.GetName and c:GetName()) or "?"), "sichtbar=" .. call(c, "IsVisible") .. " h=" .. call(c, "GetHeight"))
                end
            end
        end
    end
    local ql = QL()
    add("Verfolgte Quests", ql and ql.GetNumQuestWatches and K.Plain(ql.GetNumQuestWatches()) or "?")
    add("Einträge im Log", ql and ql.GetNumQuestLogEntries and K.Plain(ql.GetNumQuestLogEntries()) or "?")
    add("Fläche", panel and (call(panel, "IsShown") .. " h=" .. call(panel, "GetHeight")) or "keine")
    local mem = Memory()
    add("Dungeonfilter", mem and tostring(mem.active) or "?")
    add("Instanz", tostring(InstanceName()))
    return out
end

local function px(v) return string.format("%d px", v) end

K.Register({
    key = KEY, group = "ui", order = 60,
    title = "Questliste",
    description = "Die Zielverfolgung des Spiels auf einer eigenen, abgesetzten Fläche – ohne das goldene Banner.",
    defaults = defaults,
    Enable = Enable,
    OnSetting = function(key)
        QT.Apply()
        if key == "dungeonOnly" then K.AfterCombat(QT.CheckDungeon) end
    end,
    pages = {
        { key = "allgemein", label = "Allgemein", build = function(B)
            B:Section("Fläche")
            B:Row({ type = "slider", label = "Deckkraft", key = "bgAlpha", min = 0, max = 100, step = 5,
                    format = function(v) return string.format("%d %%", v) end },
                  { type = "slider", label = "Innenabstand", key = "padding", min = 0, max = 20, step = 1, format = px })
            B:Row({ type = "toggle", label = "Rand", key = "border" },
                  { type = "toggle", label = "Goldenes Banner ausblenden", key = "hideBanner", reload = true })
            B:Section("Im Dungeon")
            B:Row({ type = "toggle", label = "Nur Quests des Dungeons", key = "dungeonOnly",
                    description = "Beim Betreten verfolgt die Liste nur die Quests dieses Dungeons; beim Verlassen kommt alles zurück." },
                  { type = "empty" })
            B:Note("Deckkraft 0 % blendet die Fläche ganz aus, samt Rand und Schatten. Die Liste selbst bleibt die des Spiels: Quests anklicken, verfolgen und Questgegenstände benutzen funktionieren wie gewohnt.")
            B:GameEditMode("Wo die Liste steht und wie hoch sie sein darf: Bearbeitungsmodus des Spiels → Zielverfolgung anklicken → „Höhe“. Was nicht passt, blendet das Spiel aus; mit dem Minus an einer Überschrift klappst du Abschnitte zu. Scrollen kann die Liste nicht – sie trägt die Knöpfe der Questgegenstände, und die darf ein Addon im Kampf nicht verschieben. Die Einrichtung (/wcui einrichten) stellt eine Höhe ein, die bis über den Tooltip unten rechts reicht.")
        end },
    },
})
