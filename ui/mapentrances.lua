--------------------------------------------------
-- WeintCodex :: Instanzeingaenge auf der Weltkarte
--------------------------------------------------
-- Seit 6.20.0.0 (Wunsch des Spielers: "wenn ich die Karte normal aufmache,
-- schon auch sehen, wo die Instanz ist, mit einem Instanzsymbol"). Die
-- Marke aus dem Codex ("Eingang auf der Karte", modules/questmap.lua)
-- bleibt, wie sie ist; dies ist das Zweite: jede Karte zeigt von selbst
-- ein Symbol an jedem bekannten Eingang. Eine Seite im Komfort ("Karte"),
-- gespeichert unter "comfort", wie jeder Komfort-Helfer von Haus aus AUS;
-- geht ohne Oberflaeche.
--
-- WOHER: J.ENTRANCES (data/dungeon_journal_fg.lua, erzeugt aus dem Abgleich
-- mit ForeverGuide, 6.14.0.0) - `community`, der Tooltip sagt das. Was
-- dort nicht steht, bekommt kein Symbol; geraten wird keins.
--
-- WIE (dieselbe Regel wie die Marke, 6.6.0.1): eigene Rahmen auf der
-- Flaeche der Weltkarte, nie AddDataProvider, nie etwas in Rahmen des
-- Spiels geschrieben - was ein Addon dort schreibt, lesen Blizzards
-- Questmarken spaeter, und im Kampf blockiert das Spiel dann. Ein
-- Taktgeber als Kind der Karte laeuft nur, solange sie offen ist; die
-- Liste der Symbole entsteht nur beim Wechsel der Karte, im Takt wird nur
-- gestellt (keine Tabelle, keine Closure je Bild).
--
-- AUF DER KONTINENTKARTE: ueber C_Map.GetMapRectOnMap (wo die Zone auf
-- dem Kontinent liegt) - nur, wenn der Client das Rechteck nennt.
--
-- ZEIGT DAS SPIEL SELBST EINGAENGE (C_EncounterJournal.
-- GetDungeonEntrancesForMap liefert etwas), bleiben unsere auf dieser
-- Karte weg - zwei Symbole an einer Stelle waeren eins zu viel.
--------------------------------------------------

local K = WeintCodex.UIKit
local C = WeintCodex.Colors
local KEY = "comfort"

WeintCodex.UIMapEntrances = {}
local ME = WeintCodex.UIMapEntrances

ME.DEFAULTS = {
    mapEntrances  = false,   -- Symbole an den Eingaengen
    mapContinent  = true,    -- auch auf der Kontinentkarte
}

ME.PIN = 24          -- Groesse des Symbols in Bildpunkten, bei jedem Zoom
ME.TICK = 0.05       -- so oft stellt der Taktgeber die Symbole (s)
ME.CONTINENT = 2     -- Enum.UIMapType.Continent

local SETTING = { continent = "mapContinent" }
local function Get(k) return K.Get(KEY, SETTING[k] or k) end
function ME.Active() return K.IsActive(KEY) and K.Get(KEY, "mapEntrances") and true or false end

local function QM() return WeintCodex.QuestMap end
local function J() return WeintCodex.DungeonJournal end
local function D() return WeintCodex.DungeonData end

--------------------------------------------------
-- Bestand: Eingaenge, je Stelle zusammengefasst
--------------------------------------------------
-- Blackrock-Tiefen und die Spitze teilen sich einen Eingang - ein Symbol,
-- im Tooltip alle drei.

local spots

function ME.Spots()
    if spots then return spots end
    spots = {}
    local j, d = J(), D()
    local list = j and j.ENTRANCES or {}
    local at = {}
    local ids = {}
    for id in pairs(list) do ids[#ids + 1] = id end
    table.sort(ids)
    for _, id in ipairs(ids) do
        local dungeon = d and d.Get and d.Get(id)
        if dungeon then
            for _, e in ipairs(list[id]) do
                if type(e.map) == "number" and type(e.x) == "number" and type(e.y) == "number" then
                    local key = string.format("%d:%.3f:%.3f", e.map, e.x, e.y)
                    local s = at[key]
                    if not s then
                        s = { map = e.map, x = e.x, y = e.y, entries = {} }
                        at[key] = s
                        spots[#spots + 1] = s
                    end
                    s.entries[#s.entries + 1] = { dungeon = dungeon, label = e.label }
                end
            end
        end
    end
    -- Im Tooltip nach Stufe, wie jede Dungeonliste im Codex.
    for _, s in ipairs(spots) do
        table.sort(s.entries, function(a, b)
            local la, lb = a.dungeon.minLevel or 0, b.dungeon.minLevel or 0
            if la ~= lb then return la < lb end
            return a.dungeon.name < b.dungeon.name
        end)
    end
    return spots
end

--------------------------------------------------
-- Welche Symbole auf welcher Karte, und wo
--------------------------------------------------

local function MapInfo(mapID)
    local cm = _G.C_Map
    if not (cm and cm.GetMapInfo) then return nil end
    local ok, info = pcall(cm.GetMapInfo, mapID)
    return ok and type(info) == "table" and info or nil
end

-- Liegt `mapID` (Zone) unter `top` (Kontinent)?
local function Under(mapID, top)
    local seen = 0
    local id = mapID
    while type(id) == "number" and id > 0 and seen < 8 do
        if id == top then return true end
        local info = MapInfo(id)
        id = info and K.Plain(info.parentMapID)
        seen = seen + 1
    end
    return false
end

-- Wo liegt die Zone auf dem Kontinent? minX, maxX, minY, maxY oder nil.
local function Rect(zone, top)
    local cm = _G.C_Map
    if not (cm and cm.GetMapRectOnMap) then return nil end
    local ok, a, b, c, d = pcall(cm.GetMapRectOnMap, zone, top)
    if not ok then return nil end
    a, b, c, d = K.Plain(a), K.Plain(b), K.Plain(c), K.Plain(d)
    if type(a) ~= "number" or type(b) ~= "number" or type(c) ~= "number" or type(d) ~= "number" then return nil end
    if b <= a or d <= c then return nil end
    return a, b, c, d
end

-- Zeigt das Spiel auf dieser Karte selbst Eingaenge?
function ME.GameShows(mapID)
    local ej = _G.C_EncounterJournal
    if not (ej and type(ej.GetDungeonEntrancesForMap) == "function") then return false end
    local ok, list = pcall(ej.GetDungeonEntrancesForMap, mapID)
    return ok and type(list) == "table" and #list > 0 or false
end

-- { { spot, x, y }, ... } fuer diese Karte; gemerkt je Karte.
local forMap = {}

function ME.ForMap(mapID)
    if type(mapID) ~= "number" then return {} end
    local cached = forMap[mapID]
    if cached then return cached end
    local out = {}
    if not ME.GameShows(mapID) then
        local info = MapInfo(mapID)
        local continent = Get("continent") and info and K.Plain(info.mapType) == ME.CONTINENT
        for _, s in ipairs(ME.Spots()) do
            if s.map == mapID then
                out[#out + 1] = { spot = s, x = s.x, y = s.y }
            elseif continent and Under(s.map, mapID) then
                local x0, x1, y0, y1 = Rect(s.map, mapID)
                if x0 then
                    out[#out + 1] = { spot = s, x = x0 + s.x * (x1 - x0), y = y0 + s.y * (y1 - y0) }
                end
            end
        end
    end
    forMap[mapID] = out
    return out
end

function ME.Forget()
    for k in pairs(forMap) do forMap[k] = nil end
end

--------------------------------------------------
-- Symbole
--------------------------------------------------
-- Eigene Bilder (media/ui: disc, icon_gate - "Ein Tor mit Rundbogen:
-- Eingang zum Dungeon"), in neutralen Farben: die Karte ist mit der
-- Oberflaeche ein Fenster in Gold, und der Akzent der Klasse gehoert
-- nicht daneben.

local pins = {}
ME.pins = pins

local function Tooltip(self)
    local gt = _G.GameTooltip
    local s = self.spot
    if not (gt and s) then return end
    gt:SetOwner(self, "ANCHOR_RIGHT")
    local d = D()
    for i, e in ipairs(s.entries) do
        local name = e.dungeon.name .. (e.label and (" – " .. e.label) or "")
        local range = d and d.LevelRange and d.LevelRange(e.dungeon)
        if i == 1 then
            gt:SetText(name, C.textBright[1], C.textBright[2], C.textBright[3])
        else
            gt:AddLine(name, C.textBright[1], C.textBright[2], C.textBright[3])
        end
        if range then gt:AddLine("Stufe " .. range, C.textNormal[1], C.textNormal[2], C.textNormal[3]) end
    end
    gt:AddLine("Eingang aus Beta-Berichten (ForeverGuide) – unbestätigt.", C.textMuted[1], C.textMuted[2], C.textMuted[3], true)
    gt:AddLine("Klick: im Codex öffnen", C.textMuted[1], C.textMuted[2], C.textMuted[3])
    gt:Show()
end

-- Klick: den Dungeon im Codex aufschlagen (bei mehreren den ersten).
function ME.Open(spot)
    local e = spot and spot.entries and spot.entries[1]
    if not e then return false end
    local main = WeintCodex.MainFrame
    if type(main) ~= "table" then return false end
    main:Show()
    local DP = WeintCodex.DungeonPages
    if DP and DP.Select then DP.Select(e.dungeon.id) end
    local nav = WeintCodex.Navigation
    if nav and nav.GoToTab then nav.GoToTab("dungeons") end
    return true
end

local function NewPin(canvas)
    local p = CreateFrame("Button", nil, canvas)
    p:SetSize(ME.PIN, ME.PIN)
    p:EnableMouse(true)
    if p.RegisterForClicks then p:RegisterForClicks("LeftButtonUp") end
    local rim = p:CreateTexture(nil, "ARTWORK", nil, 1)
    rim:SetTexture(K.MEDIA .. "disc")
    rim:SetAllPoints(p)
    local b = C.borderStrong or C.textMuted
    rim:SetVertexColor(b[1], b[2], b[3], 1)
    local bg = p:CreateTexture(nil, "ARTWORK", nil, 2)
    bg:SetTexture(K.MEDIA .. "disc")
    bg:SetPoint("TOPLEFT", p, "TOPLEFT", 2, -2)
    bg:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", -2, 2)
    p.bg = bg
    local icon = p:CreateTexture(nil, "ARTWORK", nil, 3)
    icon:SetTexture(K.MEDIA .. "icon_gate")
    icon:SetSize(ME.PIN - 10, ME.PIN - 10)
    icon:SetPoint("CENTER", p, "CENTER", 0, 0)
    icon:SetVertexColor(C.textBright[1], C.textBright[2], C.textBright[3], 1)
    local function Paint(hover)
        local c = hover and (C.surface3 or C.bgPanel) or C.bgPanel
        bg:SetVertexColor(c[1], c[2], c[3], 0.95)
    end
    Paint(false)
    p:SetScript("OnEnter", function(self) Paint(true) Tooltip(self) end)
    p:SetScript("OnLeave", function()
        Paint(false)
        if _G.GameTooltip then _G.GameTooltip:Hide() end
    end)
    p:SetScript("OnClick", function(self) ME.Open(self.spot) end)
    p:Hide()
    return p
end

local shownMap, shownCount = nil, 0

local function HideAll(from)
    for i = from or 1, #pins do pins[i]:Hide() end
end

-- Symbole stellen: auf die Karte, die gerade offen ist.
function ME.Place()
    local qm = QM()
    local wm = _G.WorldMapFrame
    if not (ME.Active() and qm and type(wm) == "table" and wm.IsShown and wm:IsShown()) then
        HideAll()
        shownMap, shownCount = nil, 0
        return 0
    end
    local mapID = qm.CurrentMap and qm.CurrentMap()
    local canvas = qm.Canvas and qm.Canvas()
    if not (mapID and canvas) then
        HideAll()
        return 0
    end
    local list = ME.ForMap(mapID)
    local w, h = K.Plain(canvas:GetWidth()), K.Plain(canvas:GetHeight())
    if type(w) ~= "number" or type(h) ~= "number" or w <= 1 or h <= 1 then return 0 end
    -- Wie die Marke (modules/questmap.lua): die Flaeche ist beim Zoomen
    -- skaliert, das Symbol nimmt den Kehrwert und bleibt gleich gross.
    local s = 1
    local cs = K.Plain(canvas.GetEffectiveScale and canvas:GetEffectiveScale())
    local ms = K.Plain(wm.GetEffectiveScale and wm:GetEffectiveScale())
    if type(cs) == "number" and type(ms) == "number" and cs > 0 and ms > 0 then s = cs / ms end
    local lvl = K.Plain(canvas.GetFrameLevel and canvas:GetFrameLevel())
    lvl = math.min(8000, (type(lvl) == "number" and lvl or 0) + 1500)
    for i, e in ipairs(list) do
        local p = pins[i]
        if not p then
            p = NewPin(canvas)
            pins[i] = p
        end
        if p:GetParent() ~= canvas then p:SetParent(canvas) end
        p.spot = e.spot
        p:SetScale(1 / s)
        p:SetFrameLevel(lvl)
        p:ClearAllPoints()
        p:SetPoint("CENTER", canvas, "TOPLEFT", w * e.x * s, -h * e.y * s)
        p:Show()
    end
    HideAll(#list + 1)
    shownMap, shownCount = mapID, #list
    return #list
end

--------------------------------------------------
-- Taktgeber (Kind der Weltkarte: laeuft nur, solange sie offen ist)
--------------------------------------------------

local driver
local function EnsureDriver()
    if driver then return driver end
    local wm = _G.WorldMapFrame
    if type(wm) ~= "table" then return nil end
    driver = CreateFrame("Frame", nil, wm)
    local acc = 0
    driver:SetScript("OnUpdate", K.Measured("Karte: Eingänge", function(_, el)
        acc = acc + (el or 0)
        if acc < ME.TICK then return end
        acc = 0
        ME.Place()
    end))
    driver:SetScript("OnHide", function() HideAll() end)
    ME.driver = driver
    return driver
end
ME.EnsureDriver = EnsureDriver

-- Die Weltkarte kann spaeter geladen werden (Blizzard_WorldMap).
local ev = CreateFrame("Frame")
ev:SetScript("OnEvent", function(_, event, name)
    if event == "ADDON_LOADED" and name ~= "Blizzard_WorldMap" then return end
    if ME.Active() then EnsureDriver() end
end)

local function Apply()
    ME.Forget()
    if ME.Active() then
        pcall(ev.RegisterEvent, ev, "ADDON_LOADED")
        EnsureDriver()
        ME.Place()
    else
        pcall(ev.UnregisterEvent, ev, "ADDON_LOADED")
        HideAll()
        shownMap, shownCount = nil, 0
    end
end
ME.Apply = Apply

--------------------------------------------------
-- Bericht (/wcui prüfen)
--------------------------------------------------

function ME.StatusLines()
    local out = {}
    local n, places = 0, #ME.Spots()
    for _, s in ipairs(ME.Spots()) do n = n + #s.entries end
    out[#out + 1] = "Eingänge im Bestand: " .. n .. " an " .. places .. " Stellen"
    local cm = _G.C_Map
    local ej = _G.C_EncounterJournal
    out[#out + 1] = "Kontinent (GetMapRectOnMap): " .. ((cm and type(cm.GetMapRectOnMap) == "function") and "ja" or "nein")
        .. " · Eingänge des Spiels (GetDungeonEntrancesForMap): "
        .. ((ej and type(ej.GetDungeonEntrancesForMap) == "function") and "ja" or "nein")
    if shownMap then
        out[#out + 1] = "Zuletzt gezeigt: " .. shownCount .. " auf Karte " .. shownMap
            .. (ME.GameShows(shownMap) and " (das Spiel zeigt hier eigene)" or "")
    end
    return out
end

--------------------------------------------------
-- Seite im Komfort
--------------------------------------------------

local function BuildPage(B)
    local off = function() return not K.Get(KEY, "mapEntrances") end
    B:Section("Karte", "Instanzeingänge als Symbol auf der Weltkarte – ohne den Codex aufzuschlagen. Die Marke aus dem Codex („Eingang auf der Karte“) bleibt, wie sie ist.")
    B:Row({ type = "toggle", label = "Instanzeingänge auf der Karte", key = "mapEntrances",
            description = "Ein Symbol an jedem Eingang, den der Codex kennt. Maus darauf: welcher Dungeon, welche Stufe. Klick: im Codex öffnen." },
          { type = "toggle", label = "Auch auf der Kontinentkarte", key = "mapContinent", disabled = off,
            description = "Kalimdor und die Östlichen Königreiche im Ganzen." })
    B:Note("Die Lagen stammen aus Beta-Berichten (ForeverGuide) und sind unbestätigt. Wo der Codex keinen Eingang kennt, steht kein Symbol.")
end
ME.BuildPage = BuildPage

local mod = K.Module(KEY)
if mod then
    for k, v in pairs(ME.DEFAULTS) do
        if mod.defaults[k] == nil then mod.defaults[k] = v end
    end
    mod.pages[#mod.pages + 1] = { key = "karte", label = "Karte", build = BuildPage }
end

K.Listen(function(kind, key)
    if (kind == "active" or kind == "setting") and key == KEY then Apply() end
end)
