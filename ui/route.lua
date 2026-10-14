--------------------------------------------------
-- WeintCodex :: Komfort - Routenplaner des Questpfeils (6.31.0.0)
--------------------------------------------------
-- Der Questpfeil zeigt Luftlinie. Der Routenplaner sucht den schnellsten
-- Weg zum selben Ziel: zu Fuss, mit dem Greifen/Windreiter, mit Schiff,
-- Zeppelin, Tiefenbahn oder Portal. Der Pfeil zeigt dann auf den
-- naechsten Wegpunkt (Flugmeister, Anleger), nicht auf das Ziel.
-- Eigener Code; kein anderes Addon noetig.
--
-- WORAUF ER BAUT, UND WOHER ES KOMMT:
--   * Orte der Flugmeister und Anleger: data/mapmarks.lua (erzeugt, Art
--     "classic" - die Lagen aus Classic, auf Forever ungeprueft). Kein
--     weiterer Bestand.
--   * Welche Flugpunkte DIESER Charakter kennt: nur vom Client, wenn der
--     Spieler eine Flugkarte oeffnet (C_TaxiMap.GetAllTaxiNodes). Nie
--     angenommen: ohne geoeffnete Flugkarte fliegt die Route nicht.
--   * Flugzeiten: gemessen bei jedem eigenen Flug (Start bis Landung).
--     Ungemessen geschaetzt aus der Luftlinie (FLY_SPEED, FLY_DETOUR) -
--     deshalb steht vor jeder Reisezeit "ca.".
--   * Schiffe, Zeppeline, Tram, Portal: kein Fahrplan bekannt. Feste
--     Annahme je Art (WAIT) fuer Warten und Ueberfahrt - geschaetzt.
--   * Laufen: Luftlinie mit der eigenen Laufgeschwindigkeit
--     (GetUnitSpeed, mit Reittier schneller). Berge und Wasser kennt er
--     nicht.
-- Ein Umweg ueber Flug oder Schiff wird nur gewaehlt, wenn er deutlich
-- schneller ist (MIN_GAIN) - sonst bleibt es bei der Luftlinie.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIRoute = {}

local RT = WeintCodex.UIRoute
local K  = WeintCodex.UIKit

RT.FLY_SPEED  = 30    -- Spieleinheiten je Sekunde auf dem Flug (Annahme)
RT.FLY_DETOUR = 1.3   -- Flugrouten sind laenger als die Luftlinie (Annahme)
RT.FLY_EXTRA  = 15    -- Aufsteigen, Landen, Flugkarte (s)
RT.WALK_SPEED = 7     -- ohne Antwort vom Client
RT.MIN_GAIN   = 30    -- s: so viel schneller muss ein Umweg sein
RT.MATCH      = 150   -- Spieleinheiten: Flugpunkt des Clients <-> Bestand
-- Warten und Ueberfahrt je Art (1 Schiff, 2 Zeppelin, 3 Tram, 4 Portal), s.
RT.WAIT = { 150, 150, 90, 10 }
RT.VEHICLE = { "boat", "zeppelin", "tram", "portal" }
RT.REPLAN_EVERY = 3

local LEG = { flight = "Flug nach", boat = "Schiff nach", zeppelin = "Zeppelin nach",
    tram = "Tiefenbahn nach", portal = "Portal nach" }
local WAYPOINT = { flight = "Flugmeister", boat = "Anleger", zeppelin = "Zeppelinturm",
    tram = "Tiefenbahn", portal = "Portal" }

--------------------------------------------------
-- Gespeichertes je Charakter
--------------------------------------------------

function RT.Store()
    local st = K.CharState and K.CharState()
    if not st then return nil end
    st.route = st.route or {}
    st.route.taxi = st.route.taxi or {}     -- [Knoten] = Name aus dem Client
    st.route.times = st.route.times or {}   -- ["a>b"] = gemessene Sekunden
    return st.route
end

--------------------------------------------------
-- Knoten aus dem Bestand (einmal, beim ersten Planen)
--------------------------------------------------
-- nodes[i] = { key, kind = "flight"|"dock", zone, x, y, c, n, w,
--              faction, vehicle, pair }

local nodes, built
RT._nodes = function() return nodes end

local function World(mapID, x, y)
    local cm = _G.C_Map
    if not (cm and cm.GetWorldPosFromMapPos and _G.CreateVector2D) then return nil end
    local ok, c, pos = pcall(cm.GetWorldPosFromMapPos, mapID, _G.CreateVector2D(x, y))
    if not ok or not pos then return nil end
    local n, w = pos.x, pos.y
    if pos.GetXY then n, w = pos:GetXY() end
    c, n, w = K.Plain(c), K.Plain(n), K.Plain(w)
    if type(c) ~= "number" or type(n) ~= "number" or type(w) ~= "number" then return nil end
    return c, n, w
end
RT.World = World

function RT.Build(force)
    if built and not force then return nodes end
    built, nodes = true, {}
    local d = WeintCodex.MapMarksData or {}
    local zones = {}
    for zone in pairs(d.flights or {}) do zones[#zones + 1] = zone end
    table.sort(zones)
    for _, zone in ipairs(zones) do
        local list = d.flights[zone]
        for i = 1, #list, 3 do
            local c, n, w = World(zone, list[i], list[i + 1])
            if c then
                nodes[#nodes + 1] = { key = string.format("f%d:%.3f:%.3f", zone, list[i], list[i + 1]),
                    kind = "flight", zone = zone, x = list[i], y = list[i + 1], c = c, n = n, w = w,
                    faction = list[i + 2] }
            end
        end
    end
    zones = {}
    for zone in pairs(d.travel or {}) do zones[#zones + 1] = zone end
    table.sort(zones)
    local docks = {}
    for _, zone in ipairs(zones) do
        local list = d.travel[zone]
        for i = 1, #list, 5 do
            local c, n, w = World(zone, list[i], list[i + 1])
            if c then
                local node = { key = string.format("d%d:%.3f:%.3f", zone, list[i], list[i + 1]),
                    kind = "dock", zone = zone, x = list[i], y = list[i + 1], c = c, n = n, w = w,
                    vehicle = list[i + 2], faction = list[i + 3], to = list[i + 4] }
                nodes[#nodes + 1] = node
                docks[#docks + 1] = node
            end
        end
    end
    -- Gegenstueck: in der Zielzone derselbe Verkehr zurueck in diese Zone.
    for _, a in ipairs(docks) do
        local best, bestD
        for _, b in ipairs(docks) do
            if b ~= a and b.zone == a.to and b.to == a.zone and b.vehicle == a.vehicle then
                local dd = (b.x - a.x) ^ 2 + (b.y - a.y) ^ 2
                if a.zone ~= b.zone or dd > 0.0004 then
                    if not bestD or (a.zone == b.zone and dd > bestD) or (a.zone ~= b.zone and dd < bestD) then
                        best, bestD = b, dd
                    end
                end
            end
        end
        a.pair = best
    end
    return nodes
end

local function Faction()
    local f = _G.UnitFactionGroup and K.Plain(_G.UnitFactionGroup("player"))
    return (f == "Alliance" and 1) or (f == "Horde" and 2) or nil
end

local function Usable(node, mine)
    return node.faction == 3 or (mine ~= nil and node.faction == mine)
end

function RT.WalkSpeed()
    if _G.GetUnitSpeed then
        local ok, _, run = pcall(_G.GetUnitSpeed, "player")
        run = ok and K.Plain(run)
        if type(run) == "number" and run > 0.5 then return math.max(run, RT.WALK_SPEED) end
    end
    return RT.WALK_SPEED
end

local function Dist(a, b)
    return math.sqrt((a.n - b.n) ^ 2 + (a.w - b.w) ^ 2)
end

function RT.FlightTime(a, b, store)
    local t = store and store.times[a.key .. ">" .. b.key]
    if type(t) == "number" then return t, true end
    return Dist(a, b) * RT.FLY_DETOUR / RT.FLY_SPEED + RT.FLY_EXTRA, false
end

--------------------------------------------------
-- Planen: Dijkstra ueber Start, Ziel und die Knoten
--------------------------------------------------
-- Wiederverwendete Felder: ein Plan legt nur die Wegliste neu an, und
-- geplant wird hoechstens alle REPLAN_EVERY Sekunden oder bei neuem Ziel.

local cost, prev, how, done = {}, {}, {}, {}
local START, GOAL = { key = "start" }, { key = "goal" }
local list, S, G
local function At(i) return (i == S and START) or (i == G and GOAL) or list[i] end

-- p/g: { c, n, w }. Liefert { seconds, direct, legs = { {mode, node} ... } }
-- oder nil, wenn nichts dorthin fuehrt (anderer Kontinent ohne Verkehr).
function RT.Solve(pc, pN, pW, gc, gN, gW)
    list = RT.Build()
    local store = RT.Store()
    local mine = Faction()
    local speed = RT.WalkSpeed()
    START.c, START.n, START.w = pc, pN, pW
    GOAL.c, GOAL.n, GOAL.w = gc, gN, gW
    local count = #list
    S, G = count + 1, count + 2
    for i = 1, G do cost[i], prev[i], how[i], done[i] = math.huge, nil, nil, false end
    cost[S] = 0
    local taxi = store and store.taxi or {}
    while true do
        local u, best = nil, math.huge
        for i = 1, G do
            if not done[i] and cost[i] < best then u, best = i, cost[i] end
        end
        if not u or u == G then break end
        done[u] = true
        local a = At(u)
        -- Laufen: zu allem auf demselben Kontinent.
        for v = 1, G do
            if not done[v] and v ~= S then
                local b = At(v)
                if b.c == a.c and (v == G or Usable(b, mine)) then
                    local c = best + Dist(a, b) / speed
                    if c < cost[v] then cost[v], prev[v], how[v] = c, u, "walk" end
                end
            end
        end
        if a.kind == "flight" and taxi[a.key] then
            for v = 1, count do
                local b = list[v]
                if not done[v] and b.kind == "flight" and b.c == a.c and taxi[b.key] and Usable(b, mine) then
                    local c = best + RT.FlightTime(a, b, store)
                    if c < cost[v] then cost[v], prev[v], how[v] = c, u, "flight" end
                end
            end
        elseif a.kind == "dock" and a.pair and Usable(a.pair, mine) then
            local v
            for i = 1, count do if list[i] == a.pair then v = i break end end
            if v and not done[v] then
                local c = best + (RT.WAIT[a.vehicle] or 150)
                if c < cost[v] then cost[v], prev[v], how[v] = c, u, RT.VEHICLE[a.vehicle] or "boat" end
            end
        end
    end
    if cost[G] == math.huge then return nil end
    -- Weg rueckwaerts einsammeln.
    local legs, i = {}, G
    while prev[i] do
        table.insert(legs, 1, { mode = how[i], node = (i ~= G) and list[i] or nil })
        i = prev[i]
    end
    local route = { seconds = cost[G], legs = legs }
    local walk = (pc == gc) and math.sqrt((pN - gN) ^ 2 + (pW - gW) ^ 2) / speed or nil
    -- Nur laufen, oder der Umweg bringt zu wenig: Luftlinie.
    if #legs <= 1 or (walk and walk - route.seconds < RT.MIN_GAIN) then
        if not walk then return nil end
        return { seconds = walk, legs = { { mode = "walk" } }, direct = true }
    end
    return route
end

--------------------------------------------------
-- Fuer den Pfeil: naechster Wegpunkt und Texte
--------------------------------------------------

function RT.NodeName(node)
    if not node then return nil end
    local store = RT.Store()
    local name = store and store.taxi[node.key]
    if type(name) == "string" and name ~= "" then return name end
    local cm = _G.C_Map
    local info = cm and cm.GetMapInfo and cm.GetMapInfo(node.zone)
    local zn = info and K.Plain(info.name)
    return type(zn) == "string" and zn or nil
end

-- Der erste Wegpunkt (wohin der Pfeil jetzt zeigt) und was dort kommt.
-- legs[1] ist immer Laufen zum ersten Knoten; legs[2] das Verkehrsmittel.
function RT.Next(route)
    if not route or route.direct then return nil end
    local first, second = route.legs[1], route.legs[2]
    if not (first and first.node and second) then return nil end
    local dest = second.node
    local destName = dest and RT.NodeName(dest)
    if second.mode == "walk" then return nil end
    return {
        node = first.node,
        mode = second.mode,
        waypoint = WAYPOINT[second.mode] or "Wegpunkt",
        leg = (LEG[second.mode] or "weiter nach") .. " " .. (destName or "?"),
    }
end

function RT.FormatTime(secs)
    secs = math.floor(secs + 0.5)
    if secs >= 3600 then
        return string.format("%d:%02d:%02d", math.floor(secs / 3600), math.floor(secs / 60) % 60, secs % 60)
    end
    return string.format("%d:%02d", math.floor(secs / 60), secs % 60)
end

-- Gedrosselt fuer den Takt des Pfeils: neu bei neuem Ziel, sonst
-- hoechstens alle REPLAN_EVERY Sekunden und nur, wenn man sich bewegt hat
-- (stehen bleiben legt nichts an).
RT.REPLAN_MOVE = 20
local last = { at = -100 }
RT._last = last
function RT.Plan(pc, pN, pW, gc, gN, gW)
    local now = _G.GetTime and _G.GetTime() or 0
    if last.gc == gc and last.gN == gN and last.gW == gW and last.pc == pc
       and (now - last.at < RT.REPLAN_EVERY
            or (pN - last.pN) ^ 2 + (pW - last.pW) ^ 2 < RT.REPLAN_MOVE ^ 2) then
        return last.route
    end
    last.at, last.gc, last.gN, last.gW = now, gc, gN, gW
    last.pc, last.pN, last.pW = pc, pN, pW
    local ok, route = pcall(RT.Solve, pc, pN, pW, gc, gN, gW)
    last.route = ok and route or nil
    return last.route
end
function RT.Invalidate() last.at = -100 end

--------------------------------------------------
-- Vom Client lernen: bekannte Flugpunkte, gemessene Flugzeiten
--------------------------------------------------

local function Nearest(c, n, w, kind)
    local best, bestD
    for _, node in ipairs(RT.Build()) do
        if node.kind == kind and node.c == c then
            local d = math.sqrt((node.n - n) ^ 2 + (node.w - w) ^ 2)
            if not bestD or d < bestD then best, bestD = node, d end
        end
    end
    if best and bestD <= RT.MATCH then return best end
end
RT.Nearest = Nearest

local flying -- { from = node, at = GetTime() }

function RT.LearnTaxi()
    local tm = _G.C_TaxiMap
    local store = RT.Store()
    if not (tm and tm.GetAllTaxiNodes and store) then return 0 end
    local mapID = _G.GetTaxiMapID and K.Plain(_G.GetTaxiMapID())
    if type(mapID) ~= "number" then return 0 end
    local ok, list = pcall(tm.GetAllTaxiNodes, mapID)
    if not ok or type(list) ~= "table" then return 0 end
    local learned, unreachable = 0, (_G.Enum and _G.Enum.FlightPathState and _G.Enum.FlightPathState.Unreachable) or 2
    local current = (_G.Enum and _G.Enum.FlightPathState and _G.Enum.FlightPathState.Current) or 0
    flying = nil
    for _, info in ipairs(list) do
        local state, pos, name = K.Plain(info.state), info.position, K.Plain(info.name)
        if type(state) == "number" and state ~= unreachable and pos then
            local x, y = pos.x, pos.y
            if pos.GetXY then x, y = pos:GetXY() end
            local c, n, w = World(mapID, x, y)
            local node = c and Nearest(c, n, w, "flight")
            if node then
                if store.taxi[node.key] == nil then learned = learned + 1 end
                store.taxi[node.key] = type(name) == "string" and name or ""
                if state == current then flying = { from = node } end
            end
        end
    end
    RT.Invalidate()
    return learned
end

local function PlayerWorld()
    if K.PlayerWorld then return K.PlayerWorld() end
end

function RT.OnControlLost()
    if flying and _G.UnitOnTaxi and K.Bool(_G.UnitOnTaxi("player"), false) then
        flying.at = _G.GetTime and _G.GetTime() or nil
    end
end

function RT.OnControlGained()
    local f = flying
    flying = nil
    if not (f and f.at and _G.GetTime) then return end
    local c, n, w = PlayerWorld()
    local to = c and Nearest(c, n, w, "flight")
    local store = RT.Store()
    local secs = _G.GetTime() - f.at
    if to and store and to ~= f.from and secs > 5 then
        store.times[f.from.key .. ">" .. to.key] = math.floor(secs + 0.5)
        RT.Invalidate()
    end
end

local events = CreateFrame("Frame")
events:SetScript("OnEvent", function(_, event)
    if event == "TAXIMAP_OPENED" then RT.LearnTaxi()
    elseif event == "PLAYER_CONTROL_LOST" then RT.OnControlLost()
    elseif event == "PLAYER_CONTROL_GAINED" then RT.OnControlGained() end
end)

function RT.Start()
    for _, e in ipairs({ "TAXIMAP_OPENED", "PLAYER_CONTROL_LOST", "PLAYER_CONTROL_GAINED" }) do
        pcall(events.RegisterEvent, events, e)
    end
end

function RT.Stop()
    events:UnregisterAllEvents()
    flying = nil
end

-- /wcui pfeil: was der Planer weiss.
function RT.Inspect(out)
    local store = RT.Store()
    local n = 0
    for _ in pairs(store and store.taxi or {}) do n = n + 1 end
    local m = 0
    for _ in pairs(store and store.times or {}) do m = m + 1 end
    out[#out + 1] = string.format("Routenplaner: %d Knoten im Bestand, %d Flugpunkte bekannt, %d Flugzeiten gemessen",
        #RT.Build(), n, m)
    if n == 0 then
        out[#out + 1] = "   Flugpunkte lernt er, wenn du beim Flugmeister die Flugkarte öffnest."
    end
end
