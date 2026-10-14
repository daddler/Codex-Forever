--------------------------------------------------
-- WeintCodex :: Komfort - Routenplaner des Questpfeils (6.31.1.0, neu 6.31.2.0)
--------------------------------------------------
-- Der Questpfeil zeigt Luftlinie. Der Routenplaner sucht den schnellsten
-- Weg zum selben Ziel: zu Fuss, mit Flugmeister, Schiff, Zeppelin,
-- Tiefenbahn, Aufzug, Portal, Ruhestein oder Teleport. Der Pfeil zeigt dann
-- auf den naechsten Wegpunkt, die Minikarte zeichnet die Linie dorthin.
-- Eigener Code; kein anderes Addon noetig.
--
-- WORAUF ER BAUT, UND WOHER ES KOMMT:
--   * data/travel.lua (erzeugt von .github/scripts/import_travel.py, Art
--     "classic"): Flugpunkte mit Kennung, Flugzeiten je Strecke, Fahrplaene
--     (Umlauf, Halte, Bahn), Portale, Teleports, Inseln. Weltkoordinaten
--     wie C_Map.GetWorldPosFromMapPos (Kontinent = Instanzkarte).
--   * Welche Flugpunkte DIESER Charakter kennt: nur vom Client, wenn der
--     Spieler eine Flugkarte oeffnet (C_TaxiMap.GetAllTaxiNodes, nodeID).
--     Nie angenommen: ohne geoeffnete Flugkarte fliegt die Route nicht -
--     und der Pfeil sagt das.
--   * Abfahrtszeiten: der Umlauf steht im Bestand, WANN er auf diesem Realm
--     beginnt, nicht. Faehrt der Spieler mit, misst der Planer die Lage auf
--     der Bahn und merkt sich den Takt (sechs Stunden gueltig, wie Server-
--     neustarts es erlauben). Ohne Messung: mittlere Wartezeit, halber
--     Umlauf - und "Fahrplan unbekannt" statt einer Abfahrtszeit.
--   * Ruhestein: wohin er fuehrt, nennt der Client nur als Namen
--     (GetBindLocation). Die Lage merkt sich der Planer beim Binden
--     (HEARTHSTONE_BOUND) oder bei der Ankunft nach dem Ruhestein. Stimmt der
--     Name nicht mehr, gilt der Ruhestein nicht. Er wird nur genommen, wenn er
--     mindestens HEARTH_SAVE Sekunden spart - er hat eine Stunde Abklingzeit.
--   * Laufen: zwischen Flugmeistern, Anlegern, Portalen und Teleportzielen
--     die echte Laufstrecke aus der Gelaendekarte (places/walks im Bestand,
--     vorberechnet). Vom Spieler und zum Ziel: Luftlinie, mindestens aber
--     die echte Strecke ab dem naechsten festen Ort abzueglich dessen
--     Luftlinie (NEAR) - so laeuft niemand von Thorium Point ueber die Berge
--     nach Dun Morogh. Inseln sind zu Fuss nicht erreichbar. Die Linie auf
--     der Minikarte ist gerade, kein Pfad (kein Gelaende im Addon).
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIRoute = {}

local RT = WeintCodex.UIRoute
local K  = WeintCodex.UIKit
local C  = WeintCodex.Colors

RT.WALK_SPEED  = 7     -- ohne Antwort vom Client
RT.FLY_SPEED   = 32    -- ungemessene Strecke (wie der Bestand selbst)
RT.FLY_EXTRA   = 5     -- Aufsteigen beim Flugmeister (s)
RT.LOADING     = 5     -- Ladebildschirm nach Teleport/Portal (s)
RT.MIN_GAIN    = 30    -- s: so viel schneller muss ein Umweg sein
RT.HEARTH_SAVE = 120   -- s: so viel muss der Ruhestein sparen
RT.ANCHOR_AGE  = 6 * 3600
RT.REPLAN_EVERY, RT.REPLAN_MOVE = 3, 20
RT.HEARTH_ITEM = 6948

local KIND_LEG = { flight = "Flug nach", boat = "Schiff nach", zeppelin = "Zeppelin nach",
    tram = "Tiefenbahn nach", lift = "Aufzug nach", portal = "Portal nach", teleport = "Teleport nach" }
local KIND_WAYPOINT = { flight = "Flugmeister", boat = "Anleger", zeppelin = "Zeppelinturm",
    tram = "Tiefenbahn", lift = "Aufzug", portal = "Portal" }
RT.KIND_WAYPOINT = KIND_WAYPOINT

--------------------------------------------------
-- Gespeichertes
--------------------------------------------------
-- WeintCodex.SavedData.route = { chars = { [Name-Realm] = { taxi, names,
--   times, bind } }, anchors = { [Realm] = { [Linie] = { epoch, seen } } } }

function RT.Root()
    local sd = WeintCodex.SavedData
    if type(sd) ~= "table" then return nil end
    sd.route = sd.route or {}
    sd.route.chars = sd.route.chars or {}
    sd.route.anchors = sd.route.anchors or {}
    return sd.route
end

function RT.Store()
    local root = RT.Root()
    local key = root and K.CharKey()
    if not key then return nil end
    local st = root.chars[key]
    if not st then
        st = {}
        root.chars[key] = st
    end
    st.taxi = st.taxi or {}     -- [nodeID] = true
    st.names = st.names or {}   -- [nodeID] = Name in der Sprache des Clients
    st.times = st.times or {}   -- ["a>b"] = gemessene Sekunden
    return st
end

function RT.Anchors()
    local root = RT.Root()
    local okR, realm = pcall(_G.GetRealmName)
    if not (root and okR and type(realm) == "string") then return nil end
    root.anchors[realm] = root.anchors[realm] or {}
    return root.anchors[realm]
end

-- Serverzeit in ms (GetServerTime ganzzahlig, dazwischen GetTime).
local serverBase
function RT.ServerMs()
    local gt = _G.GetTime and _G.GetTime() or 0
    if not serverBase and _G.GetServerTime then
        local st = K.Plain(_G.GetServerTime())
        if type(st) == "number" then serverBase = st - gt end
    end
    return ((serverBase or 0) + gt) * 1000
end

--------------------------------------------------
-- Knoten (einmal gebaut)
--------------------------------------------------
-- node = { kind = "taxi"|"dock"|"portal"|"land", id, c, n, w, mass, faction }

local nodes, taxiNode, dockNode, flightsFrom, routeList, portalTo, places, walkTo
RT.NEAR = 3000     -- so nah muss ein fester Ort am Spieler/Ziel liegen
RT._nodes = function() return nodes end

local function Data() return WeintCodex.TravelData or {} end

function RT.Landmass(c, n, w)
    for i, l in ipairs(Data().landmasses or {}) do
        if l[1] == c and n >= l[2] and n <= l[3] and w >= l[4] and w <= l[5] then return i end
    end
    return 0
end

local function Node(kind, id, c, n, w, faction)
    local node = { kind = kind, id = id, c = c, n = n, w = w, faction = faction or 0,
        mass = RT.Landmass(c, n, w) }
    nodes[#nodes + 1] = node
    return node
end

function RT.Build(force)
    if nodes and not force then return nodes end
    nodes, taxiNode, dockNode, flightsFrom, routeList, portalTo = {}, {}, {}, {}, {}, {}
    local d = Data()
    local ids = {}
    for id in pairs(d.taxi or {}) do ids[#ids + 1] = id end
    table.sort(ids)
    for _, id in ipairs(ids) do
        local t = d.taxi[id]
        taxiNode[id] = Node("taxi", id, t[1], t[2], t[3], t[4])
        taxiNode[id].name = t[5]
    end
    local f = d.flights or {}
    for i = 1, #f, 3 do
        local a = f[i]
        flightsFrom[a] = flightsFrom[a] or {}
        local list = flightsFrom[a]
        list[#list + 1] = f[i + 1]
        list[#list + 1] = f[i + 2]
    end
    ids = {}
    for id in pairs(d.docks or {}) do ids[#ids + 1] = id end
    table.sort(ids)
    for _, id in ipairs(ids) do
        local p = d.docks[id]
        dockNode[id] = Node("dock", id, p[1], p[2], p[3])
    end
    ids = {}
    for id in pairs(d.routes or {}) do ids[#ids + 1] = id end
    table.sort(ids)
    for _, id in ipairs(ids) do
        local r = d.routes[id]
        local route = { id = id, kind = r[1], faction = r[2], period = r[3], stops = r[4], frames = r[5] }
        routeList[#routeList + 1] = route
        -- Je Anleger: welche Linien dort halten.
        for i = 1, #route.stops, 3 do
            local dn = dockNode[route.stops[i]]
            if dn then
                dn.routes = dn.routes or {}
                dn.routes[#dn.routes + 1] = route
                dn.kind2 = dn.kind2 or route.kind
                if route.faction ~= 0 then dn.faction = route.faction end
            end
        end
    end
    for _, p in ipairs(d.portals or {}) do
        local a = Node("portal", nil, p[1], p[2], p[3])
        local b = Node("land", nil, p[4], p[5], p[6])
        a.to, a.seconds = b, p[7]
        portalTo[#portalTo + 1] = a
    end
    -- Echte Laufstrecken: walkTo[a][b] = Spieleinheiten oder false.
    places, walkTo = d.places or {}, {}
    local wk = d.walks or {}
    for i = 1, #wk, 4 do
        local a, b, dry, rev = wk[i], wk[i + 1], wk[i + 2], wk[i + 3]
        walkTo[a] = walkTo[a] or {}
        walkTo[b] = walkTo[b] or {}
        walkTo[a][b] = dry
        if rev == 0 then walkTo[b][a] = dry else walkTo[b][a] = rev end
    end
    for _, node in ipairs(nodes) do node.place = RT.NearestPlace(node, 40) end
    return nodes
end

-- Der naechste feste Ort (Index in places) und sein Abstand, oder nil.
function RT.NearestPlace(node, within)
    local best, bestD
    for i = 1, #(places or {}) do
        local p = places[i]
        if p[1] == node.c then
            local d = (p[2] - node.n) ^ 2 + (p[3] - node.w) ^ 2
            if not bestD or d < bestD then best, bestD = i, d end
        end
    end
    if best and bestD <= within * within then return best, math.sqrt(bestD) end
end
function RT.Routes() RT.Build() return routeList end

local function Faction()
    local f = _G.UnitFactionGroup and K.Plain(_G.UnitFactionGroup("player"))
    return (f == "Alliance" and 1) or (f == "Horde" and 2) or nil
end

local function Usable(faction, mine)
    return faction == 0 or faction == 3 or (mine ~= nil and faction == mine)
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

local function Walkable(a, b)
    return a.c == b.c and a.mass == b.mass
end

-- Laufstrecke in Spieleinheiten, oder nil, wenn es keinen Weg gibt.
-- Feste Orte: aus dem Bestand. Spieler/Ziel (near, nearD): Luftlinie, aber
-- mindestens die echte Strecke ab ihrem festen Ort minus dessen Abstand.
function RT.WalkYards(a, b)
    if not Walkable(a, b) then return nil end
    local straight = Dist(a, b)
    local pa, pb = a.place or a.near, b.place or b.near
    if pa and pb and pa ~= pb then
        local y = walkTo[pa] and walkTo[pa][pb]
        if y == false then return nil end
        if y then
            if a.place and b.place then return y end
            return math.max(straight, y - (a.place and 0 or a.nearD) - (b.place and 0 or b.nearD))
        end
    end
    return straight
end

--------------------------------------------------
-- Fahrplan
--------------------------------------------------

function RT.Anchor(route)
    local anchors = RT.Anchors()
    local a = anchors and anchors[route.id]
    if not a then return nil end
    local now = RT.ServerMs() / 1000
    if now - (a.seen or 0) > RT.ANCHOR_AGE then return nil end
    return a
end

-- Wartezeit und Fahrt (s) von Halt i nach Halt j, ankommend `at` s ab
-- jetzt; timed = true, wenn ein gemessener Takt dahintersteht.
function RT.Ride(route, i, j, at)
    local s = route.stops
    local depart, arrive = s[i * 3], s[j * 3 - 1]
    local period = route.period
    local ride = ((arrive - depart) % period) / 1000
    local anchor = RT.Anchor(route)
    if anchor then
        local phase = (RT.ServerMs() + at * 1000 - anchor.epoch) % period
        return ((depart - phase) % period) / 1000, ride, true
    end
    return period / 2000, ride, false
end

--------------------------------------------------
-- Teleports und Ruhestein
--------------------------------------------------

local function ItemCount(item)
    local ci = _G.C_Item
    local f = (ci and ci.GetItemCount) or _G.GetItemCount
    if not f then return 0 end
    local ok, n = pcall(f, item)
    n = ok and K.Plain(n)
    return type(n) == "number" and n or 0
end

local function SpellKnown(spell)
    local sb = _G.C_SpellBook
    local f = (sb and sb.IsSpellKnown) or _G.IsSpellKnown or _G.IsPlayerSpell
    if not f then return false end
    local ok, known = pcall(f, spell)
    return ok and K.Bool(known, false)
end

-- Restliche Abklingzeit in s, oder nil, wenn der Client sie verschweigt.
local function Cooldown(t)
    local start, duration
    if t.item then
        local ci = _G.C_Item
        local f = (ci and ci.GetItemCooldown) or _G.GetItemCooldown
        if not f then return nil end
        local ok, s, d = pcall(f, t.item)
        if not ok then return nil end
        start, duration = K.Plain(s), K.Plain(d)
    else
        local cs = _G.C_Spell
        if cs and cs.GetSpellCooldown then
            local ok, info = pcall(cs.GetSpellCooldown, t.spell)
            if not ok or type(info) ~= "table" then return nil end
            start, duration = K.Plain(info.startTime), K.Plain(info.duration)
        elseif _G.GetSpellCooldown then
            local ok, s, d = pcall(_G.GetSpellCooldown, t.spell)
            if not ok then return nil end
            start, duration = K.Plain(s), K.Plain(d)
        else
            return nil
        end
    end
    if type(start) ~= "number" or type(duration) ~= "number" then return nil end
    if start <= 0 then return 0 end
    return math.max(0, start + duration - (_G.GetTime and _G.GetTime() or 0))
end
RT.Cooldown = Cooldown

local function BindPoint()
    local st = RT.Store()
    local b = st and st.bind
    local name = _G.GetBindLocation and K.Plain(_G.GetBindLocation())
    if b and type(name) == "string" and b.name == name then return b end
end
RT.BindPoint = BindPoint

-- Was man jetzt von hier aus wirken kann: { t, c, n, w, wait, name }.
local usable = {}
function RT.Teleports()
    for i = #usable, 1, -1 do usable[i] = nil end
    local bind = BindPoint()
    for _, t in ipairs(Data().teleports or {}) do
        local known = t.item and ItemCount(t.item) > 0 or (not t.item and SpellKnown(t.spell))
        local to = t.to or (t.bind and bind and { bind.c, bind.n, bind.w })
        local stocked = true
        for item, count in pairs(t.reagents or {}) do
            if ItemCount(item) < count then stocked = false end
        end
        local cd = known and to and stocked and Cooldown(t)
        if cd then
            usable[#usable + 1] = { t = t, c = to[1], n = to[2], w = to[3], wait = cd + (t.cast or 10000) / 1000
                + RT.LOADING, name = t.bind and bind and bind.name or nil, hearth = t.bind }
        end
    end
    return usable
end

--------------------------------------------------
-- Planen: Dijkstra, Zeit ab jetzt
--------------------------------------------------

local cost, prev, how, via, wait, done = {}, {}, {}, {}, {}, {}
local START, GOAL = { kind = "start", faction = 0 }, { kind = "goal", faction = 0 }
local TELE = {}   -- Teleportziele als Knoten, je Plan neu belegt

function RT.Solve(pc, pN, pW, gc, gN, gW)
    local list = RT.Build()
    local store = RT.Store()
    local known = store and store.taxi or {}
    local mine = Faction()
    local speed = RT.WalkSpeed()
    START.c, START.n, START.w = pc, pN, pW
    START.mass = RT.Landmass(pc, pN, pW)
    GOAL.c, GOAL.n, GOAL.w = gc, gN, gW
    GOAL.mass = RT.Landmass(gc, gN, gW)
    START.near, START.nearD = RT.NearestPlace(START, RT.NEAR)
    GOAL.near, GOAL.nearD = RT.NearestPlace(GOAL, RT.NEAR)
    local tps = RT.Teleports()
    local count = #list
    -- Indizes: 1..count Bestand, dann Teleportziele, dann Start und Ziel.
    for i = 1, #tps do
        local tn = TELE[i] or {}
        TELE[i] = tn
        tn.kind, tn.faction = "land", 0
        tn.c, tn.n, tn.w = tps[i].c, tps[i].n, tps[i].w
        tn.mass = RT.Landmass(tn.c, tn.n, tn.w)
        tn.place = RT.NearestPlace(tn, 40)
        tn.near, tn.nearD = RT.NearestPlace(tn, RT.NEAR)
    end
    local T0 = count
    local S, G = count + #tps + 1, count + #tps + 2
    local function At(i)
        if i == S then return START elseif i == G then return GOAL elseif i > T0 then return TELE[i - T0] end
        return list[i]
    end
    local index = {}
    for i = 1, count do index[list[i]] = i end
    for i = 1, G do cost[i], prev[i], how[i], via[i], wait[i], done[i] = math.huge, nil, nil, nil, nil, false end
    cost[S] = 0
    -- Teleports nur vom Start aus: gewirkt wird, wo man steht.
    for k = 1, #tps do
        local penalty = tps[k].hearth and RT.HEARTH_SAVE or 0
        cost[T0 + k], prev[T0 + k], how[T0 + k], via[T0 + k] = tps[k].wait + penalty, S, "teleport", tps[k]
    end
    local function Relax(v, c, mode, info, w)
        if not done[v] and c < cost[v] then cost[v], prev[v], how[v], via[v], wait[v] = c, nil, mode, info, w return true end
    end
    while true do
        local u, best = nil, math.huge
        for i = 1, G do
            if not done[i] and cost[i] < best then u, best = i, cost[i] end
        end
        if not u or u == G then break end
        done[u] = true
        local a = At(u)
        -- Laufen: zu allem auf derselben Landmasse.
        for v = 1, G do
            if not done[v] and v ~= S then
                local b = At(v)
                if Walkable(a, b) and (b.kind ~= "taxi" or (known[b.id] and Usable(b.faction, mine)))
                   and (b.kind ~= "dock" or Usable(b.faction, mine)) then
                    local y = RT.WalkYards(a, b)
                    if y and Relax(v, best + y / speed, "walk") then prev[v] = u end
                end
            end
        end
        if a.kind == "taxi" and known[a.id] then
            local out = flightsFrom[a.id]
            local extra = (how[u] == "flight") and 0 or RT.FLY_EXTRA
            for k = 1, out and #out or 0, 2 do
                local b = taxiNode[out[k]]
                if b and known[b.id] and Usable(b.faction, mine) then
                    local v = index[b]
                    local measured = store and store.times[a.id .. ">" .. b.id]
                    local secs = type(measured) == "number" and measured or out[k + 1]
                    if Relax(v, best + secs + extra, "flight") then prev[v] = u end
                end
            end
        elseif a.kind == "dock" and a.routes then
            for _, route in ipairs(a.routes) do
                if Usable(route.faction, mine) then
                    local s = route.stops
                    local i
                    for k = 1, #s, 3 do if dockNode[s[k]] == a then i = (k + 2) / 3 break end end
                    for j = 1, #s / 3 do
                        local b = dockNode[s[j * 3 - 2]]
                        if j ~= i and b then
                            local w, ride, timed = RT.Ride(route, i, j, best)
                            if Relax(index[b], best + w + ride, route.kind, route, timed and w or false) then
                                prev[index[b]] = u
                            end
                        end
                    end
                end
            end
        elseif a.kind == "portal" then
            local v = index[a.to]
            if Relax(v, best + a.seconds + RT.LOADING, "portal") then prev[v] = u end
        end
    end
    if cost[G] == math.huge then return nil end
    -- Weg rueckwaerts einsammeln.
    local legs, i = {}, G
    while prev[i] do
        local node = At(i)
        table.insert(legs, 1, { mode = how[i], node = (i ~= G) and node or nil, info = via[i], wait = wait[i],
            at = cost[prev[i]] })
        i = prev[i]
    end
    local seconds = cost[G]
    for _, leg in ipairs(legs) do
        if leg.mode == "teleport" and leg.info.hearth then seconds = seconds - RT.HEARTH_SAVE end
    end
    local dy = RT.WalkYards(START, GOAL)
    local direct = dy and dy / speed or nil
    if #legs <= 1 or (direct and direct - seconds < RT.MIN_GAIN) then
        if not direct then return nil end
        return { seconds = direct, legs = { { mode = "walk" } }, direct = true }
    end
    return { seconds = seconds, legs = legs }
end

--------------------------------------------------
-- Fuer den Pfeil
--------------------------------------------------

function RT.NodeName(node)
    if not node then return nil end
    if node.kind == "taxi" then
        local st = RT.Store()
        local n = st and st.names[node.id]
        if type(n) == "string" and n ~= "" then return n end
        return node.name
    end
    -- Anleger, Portalziel: der naechste Flugpunkt in der Naehe, ohne Gebiet.
    local best, bestD
    for _, t in pairs(taxiNode or {}) do
        if t.c == node.c then
            local d = Dist(t, node)
            if d < 900 and (not bestD or d < bestD) then best, bestD = t, d end
        end
    end
    if not best then return nil end
    local name = RT.NodeName(best)
    return name and (name:match("^([^,]+)") or name)
end

-- Was der Pfeil jetzt sagt. { node = Wegpunkt oder nil, mode, waypoint, leg,
-- departIn = s bis zur Abfahrt (gemessen) oder nil, untimed = true }.
function RT.Next(route)
    if not route or route.direct then return nil end
    local legs = route.legs
    local first = legs[1]
    if first.mode == "teleport" then
        local t = first.info
        local name = t.name or RT.NodeName(first.node)
        return { mode = "teleport", hearth = t.hearth, item = t.t.item, spell = t.t.spell,
            leg = (t.hearth and "Ruhestein" or "Teleport") .. (name and (" nach " .. name) or ""),
            waitCd = t.wait - (t.t.cast or 10000) / 1000 - RT.LOADING }
    end
    local second = legs[2]
    if first.mode ~= "walk" or not second or second.mode == "walk" then return nil end
    -- Mehrere Fluege hintereinander: das Ziel ist die letzte Landung.
    local last = second
    for k = 3, #legs do
        if legs[k].mode == second.mode and second.mode == "flight" then last = legs[k] else break end
    end
    local name = RT.NodeName(last.node)
    local hop = { node = first.node, mode = second.mode,
        waypoint = KIND_WAYPOINT[second.mode] or "Wegpunkt",
        leg = (KIND_LEG[second.mode] or "weiter nach") .. (name and (" " .. name) or "") }
    if second.mode ~= "flight" and second.mode ~= "portal" then
        if second.wait then
            hop.departIn = second.at + second.wait
        else
            hop.untimed = true
        end
    end
    return hop
end

function RT.FormatTime(secs)
    secs = math.max(0, math.floor(secs + 0.5))
    if secs >= 3600 then
        return string.format("%d:%02d:%02d", math.floor(secs / 3600), math.floor(secs / 60) % 60, secs % 60)
    end
    return string.format("%d:%02d", math.floor(secs / 60), secs % 60)
end

-- Zeile unter dem Pfeil. Mit gemessenem Takt die Abfahrt, sonst ehrlich.
function RT.Line(route, hop)
    if not route or route.direct then return nil end
    local s = "Route ca. " .. RT.FormatTime(route.seconds)
    if hop then
        s = s .. " · " .. hop.leg
        if hop.departIn then
            local now = _G.GetTime and _G.GetTime() or 0
            local left = hop.departIn - (now - (route.at or now))
            s = s .. ", Abfahrt in " .. RT.FormatTime(left)
        elseif hop.untimed then
            s = s .. ", Fahrplan unbekannt"
        elseif hop.mode == "teleport" and hop.waitCd and hop.waitCd > 1 then
            s = s .. ", bereit in " .. RT.FormatTime(hop.waitCd)
        end
    end
    return s
end

-- Kein Flugpunkt bekannt und weit weg: der Pfeil sagt, warum er laeuft.
function RT.NoTaxiHint(route, pc, gc, yards)
    local st = RT.Store()
    if not st then return nil end
    for _ in pairs(st.taxi) do return nil end
    if pc ~= gc or (yards or 0) > 800 then
        return "Flugpunkte unbekannt – öffne beim Flugmeister die Flugkarte"
    end
end

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
    if last.route then last.route.at = now end
    return last.route
end
function RT.Invalidate() last.at = -100 last.gc = nil end

--------------------------------------------------
-- Minikarte: gerade Linie zum naechsten Wegpunkt
--------------------------------------------------

RT.DOTS, RT.DOT_GAP = 24, 9
local dots, pin
RT._dots = function() return dots end

local function BuildDots()
    local mm = _G.Minimap
    if dots or type(mm) ~= "table" or not mm.CreateTexture then return dots ~= nil end
    dots = {}
    local col = C.accent
    for i = 1, RT.DOTS do
        local t = mm:CreateTexture(nil, "OVERLAY")
        t:SetTexture("Interface\\AddOns\\WeintCodex\\media\\ui\\dot")
        t:SetSize(4, 4)
        t:SetVertexColor(col[1], col[2], col[3], 0.9)
        t:Hide()
        dots[i] = t
    end
    pin = mm:CreateTexture(nil, "OVERLAY")
    pin:SetTexture("Interface\\AddOns\\WeintCodex\\media\\ui\\dot")
    pin:SetSize(9, 9)
    pin:SetVertexColor(col[1], col[2], col[3], 1)
    pin:Hide()
    return true
end

function RT.HideMinimap()
    if not dots then return end
    for i = 1, #dots do dots[i]:Hide() end
    pin:Hide()
end

-- pc/pN/pW: Spieler; tc/tN/tW: Wegpunkt oder Ziel.
function RT.DrawMinimap(pc, pN, pW, tc, tN, tW)
    local QH = WeintCodex.UIQuestHelper
    local mm = _G.Minimap
    if pc ~= tc or not (QH and QH.MinimapYards) or type(mm) ~= "table" or not (mm.IsShown and mm:IsShown())
       or not BuildDots() then
        RT.HideMinimap()
        return 0
    end
    local yards = QH.MinimapYards()
    local half = K.Plain(mm:GetWidth())
    if not yards or type(half) ~= "number" or half < 2 then RT.HideMinimap() return 0 end
    half = half / 2
    local east, north = pW - tW, tN - pN
    if _G.GetCVar and K.Plain(_G.GetCVar("rotateMinimap")) == "1" and _G.GetPlayerFacing then
        local facing = K.Plain(_G.GetPlayerFacing())
        if type(facing) == "number" then
            local cs, sn = math.cos(-facing), math.sin(-facing)
            east, north = east * cs - north * sn, east * sn + north * cs
        end
    end
    local len = math.sqrt(east * east + north * north)
    if len < 0.01 then RT.HideMinimap() return 0 end
    local px = len * half / yards
    local ux, uy = east / len, north / len
    local reach = math.min(px, half - 6)
    local shown = 0
    for i = 1, #dots do
        local d = 6 + i * RT.DOT_GAP
        if d < reach then
            dots[i]:ClearAllPoints()
            dots[i]:SetPoint("CENTER", mm, "CENTER", ux * d, uy * d)
            dots[i]:Show()
            shown = shown + 1
        else
            dots[i]:Hide()
        end
    end
    if px <= half - 6 then
        pin:ClearAllPoints()
        pin:SetPoint("CENTER", mm, "CENTER", ux * px, uy * px)
        pin:Show()
    else
        pin:Hide()
    end
    return shown
end

--------------------------------------------------
-- Vom Client lernen
--------------------------------------------------

function RT.LearnTaxi()
    local tm = _G.C_TaxiMap
    local st = RT.Store()
    if not (tm and tm.GetAllTaxiNodes and st) then return 0 end
    local mapID = _G.GetTaxiMapID and K.Plain(_G.GetTaxiMapID())
    if type(mapID) ~= "number" then return 0 end
    local ok, list = pcall(tm.GetAllTaxiNodes, mapID)
    if not ok or type(list) ~= "table" then return 0 end
    RT.Build()
    local E = _G.Enum and _G.Enum.FlightPathState
    local unreachable = E and E.Unreachable or 2
    local current = E and E.Current or 0
    local learned = 0
    RT.flying = nil
    for _, info in ipairs(list) do
        local id, state, name = K.Plain(info.nodeID), K.Plain(info.state), K.Plain(info.name)
        if type(id) == "number" and taxiNode[id] and type(state) == "number" and state ~= unreachable then
            if not st.taxi[id] then learned = learned + 1 end
            st.taxi[id] = true
            if type(name) == "string" and name ~= "" then st.names[id] = name end
            if state == current then RT.flying = { from = id } end
        end
    end
    RT.Invalidate()
    return learned
end

function RT.OnControlLost()
    local f = RT.flying
    if f and _G.UnitOnTaxi and K.Bool(_G.UnitOnTaxi("player"), false) then
        f.at = _G.GetTime and _G.GetTime() or nil
    end
end

local function NearestTaxi(c, n, w)
    local best, bestD
    for id, t in pairs(taxiNode or {}) do
        if t.c == c then
            local d = math.sqrt((t.n - n) ^ 2 + (t.w - w) ^ 2)
            if not bestD or d < bestD then best, bestD = id, d end
        end
    end
    if bestD and bestD <= 150 then return best end
end

function RT.OnControlGained()
    local f = RT.flying
    RT.flying = nil
    if not (f and f.at and _G.GetTime) then return end
    local c, n, w = K.PlayerWorld()
    local to = c and NearestTaxi(c, n, w)
    local st = RT.Store()
    local secs = _G.GetTime() - f.at
    if to and st and to ~= f.from and secs > 5 then
        st.times[f.from .. ">" .. to] = math.floor(secs + 0.5)
        RT.Invalidate()
    end
end

-- Ruhestein: Lage beim Binden, oder bei der Ankunft danach.
function RT.RecordBind()
    local st = RT.Store()
    local name = _G.GetBindLocation and K.Plain(_G.GetBindLocation())
    local c, n, w = K.PlayerWorld()
    if st and type(name) == "string" and c then
        st.bind = { name = name, c = c, n = n, w = w }
        RT.Invalidate()
        return true
    end
    return false
end

-- Abfahrtszeiten messen: faehrt der Spieler auf einer Bahn mit, liegt er
-- auf einem Abschnitt, bewegt sich in dessen Richtung und mit dessen Tempo.
-- Dann ist (Serverzeit - Zeit auf der Bahn) der Beginn des Umlaufs.
RT.RIDE_TOLERANCE, RT.RIDE_SAMPLES = 25, 5
local ride = { route = nil, epochs = {}, n = 0 }
RT._ride = ride
local prevSample = {}

function RT.MatchRide(c, n, w, dn, dw, dt)
    local speed = math.sqrt(dn * dn + dw * dw) / dt
    if speed < 12 then return nil end
    for _, route in ipairs(RT.Routes()) do
        local f = route.frames
        for k = 1, #f - 5, 5 do
            -- Abschnitt von Abfahrt (k+1) bis Ankunft (k+5), gleicher Kontinent.
            if f[k + 2] == c and f[k + 7] == c then
                local t0, t1 = f[k + 1], f[k + 5]
                local an, aw, bn, bw = f[k + 3], f[k + 4], f[k + 8], f[k + 9]
                local sn, sw = bn - an, bw - aw
                local seg2 = sn * sn + sw * sw
                if seg2 > 1 and t1 > t0 then
                    local u = ((n - an) * sn + (w - aw) * sw) / seg2
                    if u >= 0 and u <= 1 then
                        local qn, qw = an + u * sn - n, aw + u * sw - w
                        if qn * qn + qw * qw <= RT.RIDE_TOLERANCE ^ 2 then
                            local seg = math.sqrt(seg2)
                            local segSpeed = seg / ((t1 - t0) / 1000)
                            local cos = (dn * sn + dw * sw) / (math.sqrt(dn * dn + dw * dw) * seg)
                            if cos > 0.9 and math.abs(speed - segSpeed) <= segSpeed * 0.3 then
                                return route, t0 + u * (t1 - t0)
                            end
                        end
                    end
                end
            end
        end
    end
end

function RT.Sample(c, n, w, ms)
    if not c then prevSample.c = nil return end
    if prevSample.c == c and ms > prevSample.ms then
        local dt = (ms - prevSample.ms) / 1000
        local route, tau = RT.MatchRide(c, n, w, n - prevSample.n, w - prevSample.w, dt)
        if route then
            if ride.route ~= route then ride.route, ride.n = route, 0 end
            ride.n = ride.n + 1
            ride.epochs[ride.n] = (ms - tau) % route.period
            ride.lastAt = ms
            if ride.n >= RT.RIDE_SAMPLES then
                -- Alle Messungen nahe beieinander (zyklisch): Takt merken.
                local ref = ride.epochs[ride.n]
                local sum, ok = 0, true
                for i = ride.n - RT.RIDE_SAMPLES + 1, ride.n do
                    local d = (ride.epochs[i] - ref + route.period / 2) % route.period - route.period / 2
                    if math.abs(d) > 3000 then ok = false break end
                    sum = sum + d
                end
                local anchors = ok and RT.Anchors()
                if anchors then
                    anchors[route.id] = { epoch = (ref + sum / RT.RIDE_SAMPLES) % route.period,
                        seen = math.floor(ms / 1000) }
                    RT.Invalidate()
                end
            end
        end
    end
    prevSample.c, prevSample.n, prevSample.w, prevSample.ms = c, n, w, ms
end

-- An Bord (vor weniger als 30 s auf einer Bahn gemessen)?
function RT.Riding()
    return ride.lastAt ~= nil and RT.ServerMs() - ride.lastAt < 30000
end

local events = CreateFrame("Frame")
local acc = 0
local function OnUpdate(_, elapsed)
    acc = acc + (elapsed or 0)
    if acc < 1 then return end
    acc = 0
    local c, n, w = K.PlayerWorld()
    RT.Sample(c, n, w, RT.ServerMs())
end
events:SetScript("OnEvent", function(_, event, unit, _, spell)
    if event == "TAXIMAP_OPENED" then RT.LearnTaxi()
    elseif event == "PLAYER_CONTROL_LOST" then RT.OnControlLost()
    elseif event == "PLAYER_CONTROL_GAINED" then RT.OnControlGained()
    elseif event == "HEARTHSTONE_BOUND" then RT.RecordBind()
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" and unit == "player" then
        -- Nach dem Ruhestein: hier ist der gebundene Ort.
        if spell == 8690 or spell == 556 then
            RT.pendingBind = true
            if _G.C_Timer and _G.C_Timer.After then
                _G.C_Timer.After(3, function() if RT.pendingBind then RT.pendingBind = nil RT.RecordBind() end end)
            end
        end
    elseif event == "PLAYER_ENTERING_WORLD" and RT.pendingBind then
        RT.pendingBind = nil
        RT.RecordBind()
    end
end)

RT.ON = true
function RT.Start()
    for _, e in ipairs({ "TAXIMAP_OPENED", "PLAYER_CONTROL_LOST", "PLAYER_CONTROL_GAINED", "HEARTHSTONE_BOUND",
                         "UNIT_SPELLCAST_SUCCEEDED", "PLAYER_ENTERING_WORLD" }) do
        pcall(events.RegisterEvent, events, e)
    end
    events:SetScript("OnUpdate", K.Measured and K.Measured("Routenplaner", OnUpdate) or OnUpdate)
end

function RT.Stop()
    events:UnregisterAllEvents()
    events:SetScript("OnUpdate", nil)
    RT.flying = nil
    RT.HideMinimap()
end

-- /wcui pfeil: was der Planer weiss.
function RT.Inspect(out)
    local st = RT.Store()
    local n, m = 0, 0
    for _ in pairs(st and st.taxi or {}) do n = n + 1 end
    for _ in pairs(st and st.times or {}) do m = m + 1 end
    local a = 0
    for _ in pairs(RT.Anchors() or {}) do a = a + 1 end
    local bind = BindPoint()
    out[#out + 1] = string.format("Routenplaner: %d Flugpunkte bekannt, %d Flugzeiten gemessen, %d Fahrpläne gemessen, Ruhestein %s",
        n, m, a, bind and ("→ " .. bind.name) or "unbekannt (einmal benutzen oder neu binden)")
    if n == 0 then
        out[#out + 1] = "   Flugpunkte lernt er, wenn du beim Flugmeister die Flugkarte öffnest."
    end
end
