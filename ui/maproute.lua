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

local layer, canvasRef
local lines, used = {}, 0
MP.DASH, MP.GAP = 10, 7
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
    canvasRef = canvas
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

local function Line(x1, y1, x2, y2, width, col, alpha, sub)
    if not (Inside(x1, y1) or Inside(x2, y2)) then return end
    used = used + 1
    local l = lines[used]
    if not l then
        l = MP.NewLine(layer)
        lines[used] = l
    end
    -- Groesse der Karte selbst: die eigene Ebene hat direkt nach dem Anlegen
    -- noch keine (6.32.2.0 - die Route lag dadurch unsichtbar in der Ecke).
    local W, H = K.Plain(canvasRef:GetWidth()), K.Plain(canvasRef:GetHeight())
    if type(W) ~= "number" or W < 1 then return end
    if l.SetDrawLayer then l:SetDrawLayer("OVERLAY", sub or 0) end
    l:SetThickness(width)
    l:SetColorTexture(col[1], col[2], col[3], alpha)
    l:SetStartPoint("TOPLEFT", layer, x1 * W, -y1 * H)
    l:SetEndPoint("TOPLEFT", layer, x2 * W, -y2 * H)
    l:Show()
end

-- Route: gelb (oder Ausweichfarbe) auf dunkler Kontur - sichtbar auf
-- jedem Grund, auch auf gelbem (6.32.3.0).
MP.OUTLINE = 3
local routeCol = C.routeYellow
local function RouteLine(x1, y1, x2, y2, width, _, alpha)
    Line(x1, y1, x2, y2, width + MP.OUTLINE, C.routeOutline, C.routeOutline[4], 1)
    Line(x1, y1, x2, y2, width, routeCol, alpha, 3)
end
MP.RouteLine = RouteLine

-- Welche Farbe die Route auf dieser Karte traegt. Die Farbe der Karte an
-- einer Stelle verraet der Client nicht; bekannt ist ihre Art: Welt- und
-- Kontinentkarten sind durchgehend gelb-orange, dort Tuerkis. Einstellbar.
MP.CONTINENT = 2   -- Enum.UIMapType.Continent: alles bis dahin ist gelb
function MP.RouteColor(mapID)
    local pick = Get("routeColor") or "auto"
    if pick == "yellow" then return C.routeYellow end
    if pick == "alt" then return C.routeAlt end
    local cm = _G.C_Map
    local ok, info = false, nil
    if cm and cm.GetMapInfo then ok, info = pcall(cm.GetMapInfo, mapID) end
    local kind = ok and type(info) == "table" and K.Plain(info.mapType)
    if type(kind) == "number" and kind <= MP.CONTINENT then return C.routeAlt end
    return C.routeYellow
end

-- Gestrichelt: Striche von MP.DASH Bildpunkten mit Luecken.
local function Dashed(x1, y1, x2, y2, width, col, alpha)
    local W, H = K.Plain(canvasRef:GetWidth()), K.Plain(canvasRef:GetHeight())
    if type(W) ~= "number" or W < 1 then return end
    local dx, dy = (x2 - x1) * W, (y2 - y1) * H
    local len = math.sqrt(dx * dx + dy * dy)
    if len < 1 then return end
    local step = MP.DASH + MP.GAP
    local d = 0
    while d < len do
        local e = math.min(d + MP.DASH, len)
        Line(x1 + (x2 - x1) * d / len, y1 + (y2 - y1) * d / len, x1 + (x2 - x1) * e / len, y1 + (y2 - y1) * e / len,
            width, col, alpha)
        d = d + step
    end
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
        if x and px then RouteLine(px, py, x, y, width, col, alpha) end
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

-- Verbindung zweier Anleger einer Linie: gerade von Anleger zu Anleger.
-- Liegt das Gegenueber auf einem anderen Kontinent, faehrt das Schiff aus
-- der Karte hinaus: bis zu dem Punkt der Fahrt, an dem es den Kontinent
-- wechselt (Bahn im Bestand), und vom ersten Punkt danach zum Ziel.
-- Die Bahn selbst (Anlegemanoever) sah auf der Karte wie Gekritzel aus.
function MP.Connect(mapID, route, a, b, draw, width, col, alpha)
    if not (a and b) then return end
    if a.c == b.c then
        local x1, y1 = MP.ToMap(mapID, a.c, a.n, a.w)
        local x2, y2 = MP.ToMap(mapID, b.c, b.n, b.w)
        if x1 and x2 then draw(x1, y1, x2, y2, width, col, alpha) end
        return
    end
    -- Auf jeder Karte, die beide zeigt (Weltkarte): ganz durch.
    local x1, y1 = MP.ToMap(mapID, a.c, a.n, a.w)
    local x2, y2 = MP.ToMap(mapID, b.c, b.n, b.w)
    if x1 and x2 then draw(x1, y1, x2, y2, width, col, alpha) return end
    local f = route.frames or {}
    for k = 1, #f - 9, 5 do
        if f[k + 2] == a.c and f[k + 7] == b.c then
            if x1 then
                local ex, ey = MP.ToMap(mapID, a.c, f[k + 3], f[k + 4])
                if ex then draw(x1, y1, ex, ey, width, col, alpha) end
            end
            if x2 then
                local sx, sy = MP.ToMap(mapID, b.c, f[k + 8], f[k + 9])
                if sx then draw(sx, sy, x2, y2, width, col, alpha) end
            end
            return
        end
    end
end

function MP.DrawLines(mapID)
    local RT = WeintCodex.UIRoute
    if not (RT and RT.Routes and RT.DockNode) then return end
    local mine = Faction()
    local col = C.blue
    for _, route in ipairs(RT.Routes()) do
        if (route.kind == "boat" or route.kind == "zeppelin") and (route.faction == 0 or route.faction == mine) then
            local s = route.stops
            -- Zwei Halte: eine Verbindung; mehr: jeder zum naechsten, im Kreis.
            local count = #s / 3
            for i = 1, (count == 2) and 1 or count do
                local j = i % count + 1
                MP.Connect(mapID, route, RT.DockNode(s[i * 3 - 2]), RT.DockNode(s[j * 3 - 2]), Dashed,
                    MP.LINE_WIDTH, col, 0.75)
            end
        end
    end
end

-- Die Route: vom Spieler ueber alle Etappen bis zum Ziel.
function MP.DrawRoute(mapID, route, navPath)
    routeCol = MP.RouteColor(mapID)
    local col = routeCol
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
                if x1 and x2 then RouteLine(x1, y1, x2, y2, MP.ROUTE_WIDTH, col, 0.95) end
            end
        elseif leg.mode == "flight" or leg.mode == "portal" then
            if pc == tc then
                local x1, y1 = MP.ToMap(mapID, pc, pn, pw)
                local x2, y2 = MP.ToMap(mapID, tc, tn, tw)
                if x1 and x2 then RouteLine(x1, y1, x2, y2, MP.ROUTE_WIDTH - 1, col, 0.9) end
            end
        elseif leg.info and leg.info.stops then
            -- Schiff, Zeppelin, Bahn: von Anleger zu Anleger.
            MP.Connect(mapID, leg.info, leg.from, node, RouteLine, MP.ROUTE_WIDTH, col, 0.95)
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
    local colorPick = Get("routeColor")
    if drawn.map == mapID and drawn.canvas == canvas and drawn.route == route and drawn.nav == navPath
       and drawn.lines == wantL and drawn.color == colorPick then
        return used
    end
    drawn.map, drawn.canvas, drawn.route, drawn.nav, drawn.lines = mapID, canvas, route, navPath, wantL
    drawn.color = colorPick
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
