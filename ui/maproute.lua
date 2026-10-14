--------------------------------------------------
-- WeintCodex :: Komfort - Route und Linien auf der Weltkarte (6.32.1.0)
--------------------------------------------------
-- Auf der Weltkarte:
--   * die Route des Questpfeils (ui/route.lua): zu Fuss dem Gelaende nach
--     (ui/navmesh.lua), wo der Weg berechnet ist, sonst gerade; Fluege
--     von Flugmeister zu Flugmeister, Schiffe und Zeppeline auf ihrer Bahn;
--   * die Schiffs-, Zeppelin- und Bahnlinien (data/travel.lua, Bahn der
--     Fahrt), die der eigenen Fraktion offenstehen.
-- Eigene Linien in einer eigenen Ebene ueber den Kartenbildern - nie in die
-- Karte des Spiels geschrieben. Umgerechnet wird nur, wenn sich Karte oder
-- Route aendern (C_Map.GetMapPosFromWorldPos legt je Punkt eine Tabelle an).
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIMapRoute = {}

local MP = WeintCodex.UIMapRoute
local K  = WeintCodex.UIKit
local C  = WeintCodex.Colors
local KEY = "questarrow"

MP.TICK = 0.5
MP.ROUTE_WIDTH, MP.LINE_WIDTH = 4, 2.5

local layer
local lines, used = {}, 0
local drawn = {}
MP._drawn = drawn

local function Get(k) return K.Get(KEY, k) end
function MP.WantsRoute() return K.IsActive(KEY) and Get("mapRoute") ~= false end
function MP.WantsLines() return K.IsActive(KEY) and Get("mapLines") ~= false end

--------------------------------------------------
-- Umrechnen: Welt -> Karte (0..1), oder nil
--------------------------------------------------

local vec
function MP.ToMap(mapID, c, n, w)
    local cm = _G.C_Map
    if not (cm and cm.GetMapPosFromWorldPos and _G.CreateVector2D) then return nil end
    if vec and vec.SetXY then vec:SetXY(n, w) else vec = _G.CreateVector2D(n, w) end
    local ok, id, pos = pcall(cm.GetMapPosFromWorldPos, c, vec, mapID)
    if not ok or not pos then return nil end
    local x, y = pos.x, pos.y
    if pos.GetXY then x, y = pos:GetXY() end
    x, y = K.Plain(x), K.Plain(y)
    if type(x) ~= "number" or type(y) ~= "number" then return nil end
    return x, y
end

local function Inside(x, y) return x >= -0.02 and x <= 1.02 and y >= -0.02 and y <= 1.02 end

--------------------------------------------------
-- Linien (Vorrat, wiederverwendet)
--------------------------------------------------

local function Layer(canvas)
    if not layer then
        layer = CreateFrame("Frame", nil, canvas)
        MP.layer = layer
    elseif layer:GetParent() ~= canvas then
        layer:SetParent(canvas)
    end
    layer:ClearAllPoints()
    layer:SetAllPoints(canvas)
    local lvl = K.Plain(canvas.GetFrameLevel and canvas:GetFrameLevel())
    layer:SetFrameLevel((type(lvl) == "number" and lvl or 0) + 3)
    return layer
end

function MP.NewLine(parent) return parent:CreateLine(nil, "OVERLAY") end

local function Line(x1, y1, x2, y2, width, col, alpha)
    if not (Inside(x1, y1) or Inside(x2, y2)) then return end
    used = used + 1
    local l = lines[used]
    if not l then
        l = MP.NewLine(layer)
        lines[used] = l
    end
    local W, H = layer:GetWidth(), layer:GetHeight()
    l:SetThickness(width)
    l:SetColorTexture(col[1], col[2], col[3], alpha)
    l:SetStartPoint("TOPLEFT", layer, x1 * W, -y1 * H)
    l:SetEndPoint("TOPLEFT", layer, x2 * W, -y2 * H)
    l:Show()
end

local function HideFrom(i)
    for k = i, #lines do lines[k]:Hide() end
end

-- Eine Polylinie aus Weltpunkten (c, n, w je Punkt ueber Zugriffsfunktion).
local function Poly(mapID, count, at, width, col, alpha)
    local px, py
    for i = 1, count do
        local c, n, w = at(i)
        local x, y
        if c then x, y = MP.ToMap(mapID, c, n, w) end
        if x and px then Line(px, py, x, y, width, col, alpha) end
        px, py = x, y
    end
end

--------------------------------------------------
-- Was gezeichnet wird
--------------------------------------------------

local function Faction()
    local f = _G.UnitFactionGroup and K.Plain(_G.UnitFactionGroup("player"))
    return (f == "Alliance" and 1) or (f == "Horde" and 2) or nil
end

-- Bahn einer Linie, Abschnitte zwischen zwei Zeiten (ms im Umlauf).
local function RoutePath(mapID, route, from, to, width, col, alpha)
    local f = route.frames or {}
    local px, py, pc
    for k = 1, #f - 4, 5 do
        local t, c, n, w = f[k], f[k + 2], f[k + 3], f[k + 4]
        local inRange = not from or (from <= to and t >= from and t <= to) or (from > to and (t >= from or t <= to))
        if inRange then
            local x, y = MP.ToMap(mapID, c, n, w)
            if x and px and pc == c then Line(px, py, x, y, width, col, alpha) end
            px, py, pc = x, y, c
        else
            px = nil
        end
    end
end

function MP.DrawLines(mapID)
    local RT = WeintCodex.UIRoute
    if not (RT and RT.Routes) then return end
    local mine = Faction()
    local col = C.blue
    for _, route in ipairs(RT.Routes()) do
        if route.kind ~= "lift" and (route.faction == 0 or route.faction == mine) then
            RoutePath(mapID, route, nil, nil, MP.LINE_WIDTH, col, 0.55)
        end
    end
end

-- Die Route: vom Spieler ueber alle Etappen bis zum Ziel.
function MP.DrawRoute(mapID, route, navPath)
    local col = C.accent
    local s, g = route.start, route.goal
    if not (s and g) then return end
    local pc, pn, pw = s[1], s[2], s[3]
    for idx, leg in ipairs(route.legs) do
        local node = leg.node
        local tc, tn, tw
        if node then tc, tn, tw = node.c, node.n, node.w else tc, tn, tw = g[1], g[2], g[3] end
        if leg.mode == "walk" then
            if idx == 1 and navPath and #navPath >= 4 then
                Poly(mapID, #navPath / 2, function(i) return pc, navPath[i * 2 - 1], navPath[i * 2] end,
                    MP.ROUTE_WIDTH, col, 0.95)
            elseif pc == tc then
                local x1, y1 = MP.ToMap(mapID, pc, pn, pw)
                local x2, y2 = MP.ToMap(mapID, tc, tn, tw)
                if x1 and x2 then Line(x1, y1, x2, y2, MP.ROUTE_WIDTH, col, 0.95) end
            end
        elseif leg.mode == "flight" or leg.mode == "portal" then
            if pc == tc then
                local x1, y1 = MP.ToMap(mapID, pc, pn, pw)
                local x2, y2 = MP.ToMap(mapID, tc, tn, tw)
                if x1 and x2 then Line(x1, y1, x2, y2, MP.ROUTE_WIDTH - 1, col, 0.8) end
            end
        elseif leg.info and leg.info.stops then
            -- Schiff, Zeppelin, Bahn: auf ihrer Bahn vom Anleger bis zum Anleger.
            local stops, from, to = leg.info.stops, nil, nil
            for k = 1, #stops, 3 do
                if leg.from and stops[k] == leg.from.id then from = stops[k + 2] end
                if node and stops[k] == node.id then to = stops[k + 1] end
            end
            if from and to then RoutePath(mapID, leg.info, from, to, MP.ROUTE_WIDTH, col, 0.95) end
        end
        if node then pc, pn, pw = node.c, node.n, node.w end
    end
end

--------------------------------------------------
-- Takt: nur neu zeichnen, wenn sich etwas geaendert hat
--------------------------------------------------

function MP.Update()
    local QM = WeintCodex.QuestMap
    local wm = _G.WorldMapFrame
    local QA = WeintCodex.UIQuestArrow
    local wantR, wantL = MP.WantsRoute(), MP.WantsLines()
    if not ((wantR or wantL) and QM and type(wm) == "table" and wm.IsShown and wm:IsShown()) then
        if used > 0 then HideFrom(1) used = 0 end
        drawn.map = nil
        return 0
    end
    local mapID, canvas = QM.CurrentMap(), QM.Canvas()
    if not (mapID and canvas) then return 0 end
    local route = wantR and QA and QA.route or nil
    local navPath = wantR and QA and QA.navPath or nil
    if drawn.map == mapID and drawn.canvas == canvas and drawn.route == route and drawn.nav == navPath
       and drawn.lines == wantL then
        return used
    end
    drawn.map, drawn.canvas, drawn.route, drawn.nav, drawn.lines = mapID, canvas, route, navPath, wantL
    Layer(canvas)
    used = 0
    if wantL then MP.DrawLines(mapID) end
    if route then MP.DrawRoute(mapID, route, navPath) end
    HideFrom(used + 1)
    layer:Show()
    return used
end

function MP.Forget() drawn.map = nil end

local driver
function MP.EnsureDriver()
    if driver then return driver end
    local wm = _G.WorldMapFrame
    if type(wm) ~= "table" then return nil end
    driver = CreateFrame("Frame", nil, wm)
    local acc = 0
    driver:SetScript("OnUpdate", K.Measured("Karte: Route", function(_, el)
        acc = acc + (el or 0)
        if acc < MP.TICK then return end
        acc = 0
        MP.Update()
    end))
    MP.driver = driver
    return driver
end

local ev = CreateFrame("Frame")
ev:SetScript("OnEvent", function(_, event, name)
    if event == "ADDON_LOADED" and name == "Blizzard_WorldMap" then MP.EnsureDriver() end
end)
pcall(ev.RegisterEvent, ev, "ADDON_LOADED")
-- Schon geladen (Weltkarte gehoert bei manchen Clients zum Grundbestand).
if _G.WorldMapFrame then MP.EnsureDriver() end
