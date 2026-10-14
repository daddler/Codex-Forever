--------------------------------------------------
-- WeintCodex :: Komfort - Gelaendekarte des Routenplaners (6.32.0.0)
--------------------------------------------------
-- Ein Laufweg ueber das Gelaende statt der Luftlinie: der Pfeil folgt ihm,
-- die Minikarte zeichnet ihn. Eigener Code. Daten: data/nav/*.lua (erzeugt
-- von .github/scripts/import_nav.py, Art "beta": aus dem Beta-Client
-- gebacken, nicht von uns).
--
-- AUFBAU DER DATEN. Ein Kontinent ist in Abschnitte von 1600/3 Einheiten
-- zerlegt (Abschnitt k: x-Index k // ny, y-Index k % ny), jeder Abschnitt in
-- cells x cells Zellen (rund 8 Einheiten). Je Abschnitt:
--   graph  die Eingaenge (Knoten) und ihre Kanten mit Laufkosten - innerhalb
--          des Abschnitts und zu den acht Nachbarn;
--   grid   die begehbaren Zellen der Grundflaeche;
--   fcell  zu jeder weiteren Ebene (Stadt unter dem Berg, Hoehle) die Zelle.
-- Alles gepackt (zlib + Base64); entpackt erst, wenn ein Abschnitt gebraucht
-- wird, mit C_EncodingUtil des Clients.
--
-- SUCHE. Vom Spieler bis zu den Eingaengen seines Abschnitts genau ueber die
-- Zellen (Dijkstra), ebenso vom Ziel; dazwischen A* ueber die Eingaenge. Die
-- Rechnung laeuft verteilt ueber mehrere Bilder (NV.BUDGET ms je Bild), nie
-- im Kampf neu. Bis sie fertig ist, zeigt der Pfeil die Luftlinie.
-- Der gezeichnete Weg ist im eigenen Abschnitt zellgenau, weiter weg von
-- Eingang zu Eingang (Abschnittsgrenzen) - die Kosten stimmen, die Linie
-- dazwischen ist gerade.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UINav = {}

local NV = WeintCodex.UINav
local K  = WeintCodex.UIKit

NV.TILE = 1600 / 3
NV.BUDGET = 2          -- ms Rechenzeit je Bild
NV.MAX_EXPAND = 80000  -- Eingaenge je Suche, dann aufgeben
NV.SNAP = 6            -- Zellen Umkreis, wenn man nicht auf einer Zelle steht
NV.REPATH_MOVE = 40    -- so weit weg vom Weg: neu suchen
NV.LOOKAHEAD = 30      -- der Pfeil zeigt so weit voraus auf den Weg
NV.CACHE = 32          -- entpackte Abschnitte im Speicher

local byte, floor, sqrt, huge = string.byte, math.floor, math.sqrt, math.huge
local coroutine, os = _G.coroutine, _G.os

local B64 = {}
do
    local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    for i = 1, 64 do B64[byte(alphabet, i)] = i - 1 end
end
local function Num(s, i, width)
    local v = 0
    for k = 0, width - 1 do v = v * 64 + B64[byte(s, i + k)] end
    return v
end
NV.Num = Num

--------------------------------------------------
-- Entpacken (je Abschnitt einmal, begrenzt)
--------------------------------------------------

local states = {}
local cached, cachedCount = {}, 0

function NV.Available(c)
    local D = WeintCodex.NavData and WeintCodex.NavData[c]
    if not D then return false end
    if D.raw then return true end
    local eu = _G.C_EncodingUtil
    return eu ~= nil and eu.DecodeBase64 ~= nil and eu.DecompressString ~= nil
end

-- Roher Text eines Feldes, oder nil. D.raw (Pruefung) liefert ihn ungepackt.
local function Field(D, field, k)
    if D.raw then return D.raw[field] and D.raw[field][k] end
    local blocks = D[field][k]
    if blocks == nil then return nil end
    if type(blocks) == "string" then blocks = { blocks } end
    local eu = _G.C_EncodingUtil
    local method = _G.Enum and _G.Enum.CompressionMethod and _G.Enum.CompressionMethod.Zlib
    local parts = {}
    for i, b in ipairs(blocks) do
        local ok, bin = pcall(eu.DecodeBase64, b)
        local ok2, raw = false, nil
        if ok and bin then ok2, raw = pcall(eu.DecompressString, bin, method) end
        if not (ok2 and type(raw) == "string") then return nil end
        parts[i] = raw
    end
    return table.concat(parts)
end

local function State(c)
    local st = states[c]
    if st then return st end
    local D = WeintCodex.NavData and WeintCodex.NavData[c]
    if not D then return nil end
    st = { D = D, C = D.cells, cs = NV.TILE / D.cells, nx = D.nx, ny = D.ny, cx0 = D.cx0, cy0 = D.cy0,
        swim = D.swim or 3, clusters = {} }
    states[c] = st
    return st
end
NV.State = State

-- Abschnitt k (0-basiert): Knoten und Gitter, entpackt.
-- cl = { s = Wegenetz, n, edge = { [i] = Lage der Kanten }, val, flg, fs }
function NV.Cluster(st, k)
    local cl = st.clusters[k]
    if cl ~= nil then return cl or nil end
    if cachedCount >= NV.CACHE then
        for _, s in pairs(states) do s.clusters = {} end
        cached, cachedCount = {}, 0
    end
    local s = Field(st.D, "graph", k + 1)
    if not s then st.clusters[k] = false return nil end
    cl = { s = s, n = Num(s, 1, 2), edge = {} }
    local pos = 3 + cl.n * 7
    for i = 0, cl.n - 1 do
        cl.edge[i] = pos
        pos = pos + B64[byte(s, 3 + i * 7 + 6)] * 7
    end
    -- Gitter: Wert * 16 + Schalter; ab 48 Wiederholung des vorigen.
    -- Gehalten als Zeichenkette, ein Byte je Zelle (6.32.2.0): zwei Tabellen
    -- mit je 4489 Zahlen kosteten rund 140 KB je Abschnitt, so 4,5 KB.
    local g = Field(st.D, "grid", k + 1)
    if g then
        local parts, n, last = {}, 0, 0
        local char = string.char
        for p = 1, #g do
            local sym = B64[byte(g, p)]
            if sym >= 48 then
                n = n + 1
                parts[n] = string.rep(char(last), sym - 47)
            else
                last = sym
                n = n + 1
                parts[n] = char(sym)
            end
        end
        cl.cells = table.concat(parts)
    end
    cl.fs = Field(st.D, "fcell", k + 1)
    st.clusters[k] = cl
    cachedCount = cachedCount + 1
    return cl
end

-- Lage einer Zelle (0-basiert) im Abschnitt k: Norden, Westen.
function NV.CellPos(st, k, cell)
    local ix, iy = floor(k / st.ny), k % st.ny
    local cx, cy = floor(cell / st.C), cell % st.C
    return (st.cx0 + ix) * NV.TILE + (cx + 0.5) * st.cs, (st.cy0 + iy) * NV.TILE + (cy + 0.5) * st.cs
end

-- Abschnitt und Zelle zu einer Lage, oder nil ausserhalb.
function NV.Locate(st, n, w)
    local ix, iy = floor(n / NV.TILE) - st.cx0, floor(w / NV.TILE) - st.cy0
    if ix < 0 or iy < 0 or ix >= st.nx or iy >= st.ny then return nil end
    local k = ix * st.ny + iy
    local cx = floor((n - (st.cx0 + ix) * NV.TILE) / st.cs)
    local cy = floor((w - (st.cy0 + iy) * NV.TILE) / st.cs)
    cx = math.max(0, math.min(st.C - 1, cx))
    cy = math.max(0, math.min(st.C - 1, cy))
    return k, cx * st.C + cy
end

-- Knoten id = k * 4096 + i: Zelle (auch einer Ebene), Ebene.
function NV.NodeCell(st, id)
    local k, i = floor(id / 4096), id % 4096
    local cl = NV.Cluster(st, k)
    if not cl or i >= cl.n then return nil end
    local cell = Num(cl.s, 3 + i * 7, 3)
    local layer = B64[byte(cl.s, 3 + i * 7 + 3)]
    local CC = st.C * st.C
    if cell >= CC then
        local f = cell - CC
        if not (cl.fs and #cl.fs >= f * 3 + 3) then return nil end
        cell = Num(cl.fs, 1 + f * 3, 3)
    end
    return k, cell, layer
end

function NV.NodePos(st, id)
    local k, cell = NV.NodeCell(st, id)
    if not k then return nil end
    return NV.CellPos(st, k, cell)
end

--------------------------------------------------
-- Haufen (Paare aus Kosten und Wert, ohne Tabellen je Eintrag)
--------------------------------------------------

local function HeapNew() return { n = 0, key = {}, val = {} } end
local function HeapClear(h) h.n = 0 end
local function HeapPush(h, key, val)
    local n = h.n + 1
    h.n = n
    local K_, V = h.key, h.val
    while n > 1 do
        local p = floor(n / 2)
        if K_[p] <= key then break end
        K_[n], V[n] = K_[p], V[p]
        n = p
    end
    K_[n], V[n] = key, val
end
local function HeapPop(h)
    local K_, V = h.key, h.val
    local topK, topV = K_[1], V[1]
    local lastK, lastV = K_[h.n], V[h.n]
    h.n = h.n - 1
    local n, size = 1, h.n
    while true do
        local c = n * 2
        if c > size then break end
        if c < size and K_[c + 1] < K_[c] then c = c + 1 end
        if lastK <= K_[c] then break end
        K_[n], V[n] = K_[c], V[c]
        n = c
    end
    if size > 0 then K_[n], V[n] = lastK, lastV end
    return topK, topV
end
NV.HeapNew, NV.HeapPush, NV.HeapPop = HeapNew, HeapPush, HeapPop

--------------------------------------------------
-- Zeit verteilen
--------------------------------------------------

local deadline = huge
local function Clock()
    local f = _G.debugprofilestop
    if f then return f() end
    return os.clock() * 1000
end
local ops = 0
local function Slice()
    ops = ops + 1
    if ops < 64 then return end
    ops = 0
    if deadline < huge and Clock() > deadline and coroutine.running() then coroutine.yield() end
end

--------------------------------------------------
-- Gitter im Abschnitt
--------------------------------------------------

local function Walk(cl, cell)
    local b = cl.cells and byte(cl.cells, cell + 1)
    return b and floor(b / 16) or 0
end
local function Flag(cl, cell) return byte(cl.cells, cell + 1) % 16 end

-- Schritt von a nach b (Nachbarn) offen? dir: 1 +x, 2 -x, 3 +y, 4 -y,
-- 5 +x+y, 6 +x-y, 7 -x+y, 8 -x-y.
local function StepOpen(cl, C, a, dir)
    if dir == 1 then return Flag(cl, a) % 2 == 0
    elseif dir == 2 then return Flag(cl, a - C) % 2 == 0
    elseif dir == 3 then return floor(Flag(cl, a) / 2) % 2 == 0
    elseif dir == 4 then return floor(Flag(cl, a - 1) / 2) % 2 == 0 end
end

local DX = { 1, -1, 0, 0, 1, 1, -1, -1 }
local DY = { 0, 0, 1, -1, 1, -1, 1, -1 }
local ORTH_X = { [5] = 1, [6] = 1, [7] = 2, [8] = 2 }
local ORTH_Y = { [5] = 3, [6] = 4, [7] = 3, [8] = 4 }

-- Kosten (Zellen) von einer Zelle aus, im Abschnitt. Liefert dist und
-- prev (Tabellen, wiederverwendbar ueber `into`).
function NV.Grid(st, cl, start, into)
    local C = st.C
    local dist, prev = into.dist, into.prev
    for i in pairs(dist) do dist[i] = nil end
    for i in pairs(prev) do prev[i] = nil end
    if not cl.cells then return dist, prev end
    local h = into.heap
    HeapClear(h)
    dist[start] = 0
    HeapPush(h, 0, start)
    while h.n > 0 do
        local d, a = HeapPop(h)
        if d <= dist[a] then
            Slice()
            local ax, ay = floor(a / C), a % C
            for dir = 1, 8 do
                local bx, by = ax + DX[dir], ay + DY[dir]
                if bx >= 0 and by >= 0 and bx < C and by < C then
                    local b = bx * C + by
                    local v = Walk(cl, b)
                    if v ~= 0 then
                        local open
                        if dir <= 4 then
                            open = StepOpen(cl, C, a, dir)
                        else
                            -- Schraeg: offen, wenn einer der beiden Winkel offen ist.
                            local ox, oy = ORTH_X[dir], ORTH_Y[dir]
                            local mx, my = (ax + DX[ox]) * C + ay, ax * C + ay + DY[oy]
                            open = (Walk(cl, mx) ~= 0 and StepOpen(cl, C, a, ox) and StepOpen(cl, C, mx, oy))
                                or (Walk(cl, my) ~= 0 and StepOpen(cl, C, a, oy) and StepOpen(cl, C, my, ox))
                        end
                        if open then
                            local step = (dir <= 4 and 1 or 1.4142) * (v == 2 and st.swim or 1)
                            local nd = d + step
                            if not dist[b] or nd < dist[b] then
                                dist[b], prev[b] = nd, a
                                HeapPush(h, nd, b)
                            end
                        end
                    end
                end
            end
        end
    end
    return dist, prev
end

-- Die naechste begehbare Zelle im Umkreis NV.SNAP, oder nil.
function NV.Snap(st, cl, cell)
    if not cl.cells then return nil end
    if Walk(cl, cell) ~= 0 then return cell end
    local C = st.C
    local cx, cy = floor(cell / C), cell % C
    for r = 1, NV.SNAP do
        for dx = -r, r do
            for dy = -r, r do
                if math.abs(dx) == r or math.abs(dy) == r then
                    local x, y = cx + dx, cy + dy
                    if x >= 0 and y >= 0 and x < C and y < C and Walk(cl, x * C + y) ~= 0 then return x * C + y end
                end
            end
        end
    end
end

--------------------------------------------------
-- Suche
--------------------------------------------------

local scratchA = { dist = {}, prev = {}, heap = HeapNew() }
local scratchB = { dist = {}, prev = {}, heap = HeapNew() }

-- Polylinie (flach n, w, n, w ...) im Abschnitt von Zelle a rueckwaerts
-- ueber prev bis zum Start; jede vierte Zelle reicht fuer die Linie.
local function GridChain(st, k, prev, from, out, reverse)
    local cells, c = {}, from
    while c do cells[#cells + 1] = c c = prev[c] end
    local list = {}
    for i = 1, #cells do
        if i == 1 or i == #cells or i % 4 == 0 then list[#list + 1] = cells[i] end
    end
    if not reverse then
        -- prev zeigt zum Start: umdrehen, damit die Linie vom Start kommt.
        for i = #list, 1, -1 do
            local n, w = NV.CellPos(st, k, list[i])
            out[#out + 1], out[#out + 2] = n, w
        end
    else
        for i = 1, #list do
            local n, w = NV.CellPos(st, k, list[i])
            out[#out + 1], out[#out + 2] = n, w
        end
    end
end

-- Laeuft in einer Coroutine. Liefert { n, w, ... } von Start bis Ziel und die
-- Laenge in Einheiten, oder nil.
function NV.Search(c, sN, sW, gN, gW)
    local st = State(c)
    if not st then return nil end
    local ks, cs0 = NV.Locate(st, sN, sW)
    local kg, cg0 = NV.Locate(st, gN, gW)
    if not (ks and kg) then return nil end
    local cls, clg = NV.Cluster(st, ks), NV.Cluster(st, kg)
    if not (cls and clg) then return nil end
    local cs, cg = NV.Snap(st, cls, cs0), NV.Snap(st, clg, cg0)
    local size = st.cs
    -- Vom Start: Zellen im eigenen Abschnitt.
    local distS, prevS = {}, {}
    local ds, ps = {}, {}
    if cs then
        local d, p = NV.Grid(st, cls, cs, scratchA)
        for key, v in pairs(d) do ds[key] = v end
        for key, v in pairs(p) do ps[key] = v end
    end
    distS, prevS = ds, ps
    local dg, pg = {}, {}
    if cg then
        local d, p = NV.Grid(st, clg, cg, scratchB)
        for key, v in pairs(d) do dg[key] = v end
        for key, v in pairs(p) do pg[key] = v end
    end
    -- Im selben Abschnitt und auf dem Gitter verbunden: fertig.
    local best, bestNode = huge, nil
    if ks == kg and cs and cg and distS[cg] then best = distS[cg] * size end
    -- Ziel-Eingaenge mit ihren Kosten bis zum Ziel.
    local goalCost = {}
    for i = 0, clg.n - 1 do
        local id = kg * 4096 + i
        local _, cell, layer = NV.NodeCell(st, id)
        if cell then
            if layer == 0 and cg and dg[cell] then
                goalCost[id] = dg[cell] * size
            elseif not cg or layer ~= 0 then
                local n, w = NV.CellPos(st, kg, cell)
                goalCost[id] = sqrt((n - gN) ^ 2 + (w - gW) ^ 2) * 1.5
            end
        end
    end
    -- A* ueber die Eingaenge.
    local g, from = {}, {}
    local heap = HeapNew()
    for i = 0, cls.n - 1 do
        local id = ks * 4096 + i
        local _, cell, layer = NV.NodeCell(st, id)
        local cost
        if cell then
            if layer == 0 and cs and distS[cell] then
                cost = distS[cell] * size
            elseif not cs or layer ~= 0 then
                local n, w = NV.CellPos(st, ks, cell)
                cost = sqrt((n - sN) ^ 2 + (w - sW) ^ 2) * 1.5
            end
        end
        if cost then
            g[id] = cost
            local n, w = NV.CellPos(st, ks, cell)
            HeapPush(heap, cost + sqrt((n - gN) ^ 2 + (w - gW) ^ 2), id)
        end
    end
    local expanded = 0
    while heap.n > 0 do
        local f, u = HeapPop(heap)
        if f >= best then break end
        local gu = g[u]
        local ku, iu = floor(u / 4096), u % 4096
        local cl = NV.Cluster(st, ku)
        if cl and f - 0.01 <= gu + 1e9 then
            expanded = expanded + 1
            if expanded > NV.MAX_EXPAND then return nil end
            Slice()
            local gc = goalCost[u]
            if gc and gu + gc < best then best, bestNode = gu + gc, u end
            local s, pos = cl.s, cl.edge[iu]
            for _ = 1, B64[byte(s, 3 + iu * 7 + 6)] do
                local off = B64[byte(s, pos)]
                local kt = ku + (floor(off / 3) - 1) * st.ny + off % 3 - 1
                local v = kt * 4096 + Num(s, pos + 1, 2)
                local nd = gu + Num(s, pos + 3, 2)
                if not g[v] or nd < g[v] then
                    local n, w = NV.NodePos(st, v)
                    if n then
                        g[v], from[v] = nd, u
                        HeapPush(heap, nd + sqrt((n - gN) ^ 2 + (w - gW) ^ 2), v)
                    end
                end
                pos = pos + 7
            end
        end
    end
    if best == huge then return nil end
    local out = {}
    if not bestNode then
        -- Ganz im eigenen Abschnitt.
        GridChain(st, ks, prevS, cg, out, false)
        return out, best
    end
    -- Eingaenge rueckwaerts sammeln.
    local chain, u = {}, bestNode
    while u do chain[#chain + 1] = u u = from[u] end
    out[1], out[2] = sN, sW
    local first = chain[#chain]
    local _, c1, l1 = NV.NodeCell(st, first)
    if l1 == 0 and cs and distS[c1] then
        GridChain(st, ks, prevS, c1, out, false)
    end
    for i = #chain, 1, -1 do
        local n, w = NV.NodePos(st, chain[i])
        out[#out + 1], out[#out + 2] = n, w
    end
    local _, c2, l2 = NV.NodeCell(st, bestNode)
    if l2 == 0 and cg and dg[c2] then
        GridChain(st, kg, pg, c2, out, true)
    end
    out[#out + 1], out[#out + 2] = gN, gW
    return out, best
end

--------------------------------------------------
-- Auftraege: eine Suche zur Zeit, verteilt ueber Bilder
--------------------------------------------------

local job = { co = nil }
local result = { path = nil }
NV._job, NV._result = job, result
local pump = CreateFrame("Frame")

local function Pump()
    if not job.co then pump:SetScript("OnUpdate", nil) return end
    deadline = Clock() + NV.BUDGET
    local ok, path, len = coroutine.resume(job.co)
    deadline = huge
    if not ok then
        job.co = nil
        result.failed = true
        pump:SetScript("OnUpdate", nil)
        return
    end
    if coroutine.status(job.co) == "dead" then
        job.co = nil
        result.path, result.len, result.c, result.gN, result.gW = path, len, job.c, job.gN, job.gW
        result.sN, result.sW, result.failed = job.sN, job.sW, path == nil
        pump:SetScript("OnUpdate", nil)
    end
end
NV.Pump = Pump

local function Start(c, sN, sW, gN, gW)
    job.c, job.sN, job.sW, job.gN, job.gW = c, sN, sW, gN, gW
    job.co = coroutine.create(function() return NV.Search(c, sN, sW, gN, gW) end)
    pump:SetScript("OnUpdate", Pump)
end

-- Weg zur Lage (gN, gW), oder nil (noch nicht da, keine Karte, kein Weg).
-- Neu gesucht bei neuem Ziel oder wenn man sich vom Weg entfernt hat.
function NV.Path(c, sN, sW, gN, gW)
    if not NV.Available(c) then return nil end
    local sameGoal = result.c == c and result.gN and math.abs(result.gN - gN) < 2 and math.abs(result.gW - gW) < 2
    local jobGoal = job.co and job.c == c and math.abs(job.gN - gN) < 2 and math.abs(job.gW - gW) < 2
    if sameGoal and result.path then
        local off = NV.OffPath(result.path, sN, sW)
        if off <= NV.REPATH_MOVE then return result.path, result.len end
    end
    if jobGoal then return sameGoal and result.path or nil end
    if sameGoal and result.failed and job.lastFail and (sN - job.lastFail[1]) ^ 2 + (sW - job.lastFail[2]) ^ 2 < 900 then
        return nil
    end
    if K.InCombat and K.InCombat() then return sameGoal and result.path or nil end
    if sameGoal and result.failed then job.lastFail = { sN, sW } end
    Start(c, sN, sW, gN, gW)
    return sameGoal and result.path or nil
end

function NV.Reset()
    job.co = nil
    result.path, result.c, result.failed = nil, nil, nil
    pump:SetScript("OnUpdate", nil)
end

-- Abstand zur Linie (naechster Abschnitt).
local function SegDist(aN, aW, bN, bW, pN, pW)
    local sn, sw = bN - aN, bW - aW
    local len2 = sn * sn + sw * sw
    local u = len2 > 0 and ((pN - aN) * sn + (pW - aW) * sw) / len2 or 0
    if u < 0 then u = 0 elseif u > 1 then u = 1 end
    local qn, qw = aN + u * sn - pN, aW + u * sw - pW
    return sqrt(qn * qn + qw * qw), u
end

function NV.OffPath(path, pN, pW)
    local best = huge
    for i = 1, #path - 3, 2 do
        local d = SegDist(path[i], path[i + 1], path[i + 2], path[i + 3], pN, pW)
        if d < best then best = d end
    end
    return best
end

-- Wohin der Pfeil zeigt: NV.LOOKAHEAD voraus auf dem Weg ab dem naechsten
-- Punkt, und der Rest des Weges. Ohne Tabellen.
function NV.Steer(path, pN, pW)
    local bestD, bestI, bestU = huge, 1, 0
    for i = 1, #path - 3, 2 do
        local d, u = SegDist(path[i], path[i + 1], path[i + 2], path[i + 3], pN, pW)
        if d < bestD then bestD, bestI, bestU = d, i, u end
    end
    if #path < 4 then return path[1], path[2], 0, 1 end
    local aN, aW = path[bestI], path[bestI + 1]
    local bN, bW = path[bestI + 2], path[bestI + 3]
    local seg = sqrt((bN - aN) ^ 2 + (bW - aW) ^ 2)
    local left = seg * (1 - bestU)
    local rest = left
    for i = bestI + 2, #path - 3, 2 do
        rest = rest + sqrt((path[i + 2] - path[i]) ^ 2 + (path[i + 3] - path[i + 1]) ^ 2)
    end
    rest = rest + bestD
    -- Voraus schauen.
    local need = NV.LOOKAHEAD
    if left >= need then
        local t = bestU + need / math.max(seg, 0.01)
        return aN + (bN - aN) * t, aW + (bW - aW) * t, rest, bestI
    end
    need = need - left
    for i = bestI + 2, #path - 3, 2 do
        local l = sqrt((path[i + 2] - path[i]) ^ 2 + (path[i + 3] - path[i + 1]) ^ 2)
        if l >= need then
            local t = need / l
            return path[i] + (path[i + 2] - path[i]) * t, path[i + 1] + (path[i + 3] - path[i + 1]) * t, rest, bestI
        end
        need = need - l
    end
    return path[#path - 1], path[#path], rest, bestI
end
