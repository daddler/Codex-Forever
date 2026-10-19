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
NV.MAX_EXPAND = 30000  -- Eingaenge je Suche, dann aufgeben
NV.SNAP = 6            -- Zellen Umkreis, wenn man nicht auf einer Zelle steht
NV.REPATH_MOVE = 40    -- so weit weg vom Weg: neu suchen
NV.LOOKAHEAD = 30      -- der Pfeil zeigt so weit voraus auf den Weg
NV.CORNER = 6          -- so nah an einer Ecke: schon um sie herum zeigen
NV.CACHE = 600         -- entpackte Wegenetze im Speicher (je rund 1 KB)
NV.CELLS = 32          -- entpackte Gitter im Speicher (je rund 4,5 KB)

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
local cachedCount, useTick = 0, 0

function NV.Available(c)
    local D = WeintCodex.NavData and WeintCodex.NavData[c]
    if not D then return false end
    if D.raw then return true end
    local eu = _G.C_EncodingUtil
    return eu ~= nil and (D.bin or eu.DecodeBase64 ~= nil) and eu.DecompressString ~= nil
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
        -- 6.41.3.0: D.bin - die rohen zlib-Bytes stehen direkt in der Datei
        -- (ein Viertel weniger Speicher als Base64).
        local ok, bin
        if D.bin then ok, bin = true, b else ok, bin = pcall(eu.DecodeBase64, b) end
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
    if cl ~= nil then
        if cl then useTick = useTick + 1 cl.used = useTick end
        return cl or nil
    end
    -- 6.35.2.0 (/wcui speicher: 600 KB/s beim Laufen): voll heisst nicht
    -- mehr "alles weg" - eine lange Suche brauchte mehr als NV.CACHE
    -- Abschnitte und entpackte dann bei jeder Suche alles neu. Jetzt geht
    -- nur der am laengsten nicht gebrauchte.
    if cachedCount >= NV.CACHE then NV.Evict() end
    local s = Field(st.D, "graph", k + 1)
    if not s then st.clusters[k] = false return nil end
    cl = { s = s, n = Num(s, 1, 2), edge = {} }
    local pos = 3 + cl.n * 7
    for i = 0, cl.n - 1 do
        cl.edge[i] = pos
        pos = pos + B64[byte(s, 3 + i * 7 + 6)] * 7
    end
    -- Das Gitter wird erst entpackt, wenn eine Suche es braucht (NV.Cells):
    -- die Suche ueber die Eingaenge liest nur das Wegenetz.
    cl.k = k
    cl.fs = Field(st.D, "fcell", k + 1)
    st.clusters[k] = cl
    cachedCount = cachedCount + 1
    useTick = useTick + 1
    cl.used = useTick
    return cl
end

-- Gitter eines Abschnitts (Wert * 16 + Schalter; ab 48 Wiederholung des
-- vorigen), ein Byte je Zelle (6.32.2.0: Tabellen kosteten 140 KB, so 4,5 KB).
-- 6.35.3.1 (/wcui speicher: Gelaendekarte 4,4 MB/s): getrennt vom Wegenetz
-- gehalten - hoechstens NV.CELLS Gitter, der am laengsten ungenutzte geht.
-- Das Wegenetz (im Mittel rund 1 KB je Abschnitt) bleibt fuer NV.CACHE
-- Abschnitte; vorher flog es mit dem Gitter und wurde bei einer langen Suche
-- immer wieder entpackt - die Suche wurde dadurch nie fertig.
local cellsCount = 0
function NV.Cells(st, cl)
    if cl.cells ~= nil then
        useTick = useTick + 1
        cl.cellsUsed = useTick
        return cl.cells or nil
    end
    if cellsCount >= NV.CELLS then
        local victim, vu
        for _, s2 in pairs(states) do
            for _, c2 in pairs(s2.clusters) do
                if c2 and c2.cells and (not vu or c2.cellsUsed < vu) then victim, vu = c2, c2.cellsUsed end
            end
        end
        if victim then victim.cells, victim.surf = nil, nil cellsCount = cellsCount - 1 else cellsCount = 0 end
    end
    local g = Field(st.D, "grid", cl.k + 1)
    if not g then cl.cells = false return nil end
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
    cellsCount = cellsCount + 1
    useTick = useTick + 1
    cl.cellsUsed = useTick
    return cl.cells
end

-- Den am laengsten nicht gebrauchten Abschnitt freigeben.
function NV.Evict()
    local bestSt, bestK, bestUsed
    for _, st in pairs(states) do
        for k, cl in pairs(st.clusters) do
            if cl and (not bestUsed or cl.used < bestUsed) then bestSt, bestK, bestUsed = st, k, cl.used end
        end
    end
    if bestSt then
        if bestSt.clusters[bestK].cells then cellsCount = cellsCount - 1 end
        bestSt.clusters[bestK] = nil
        cachedCount = cachedCount - 1
    else
        cachedCount = 0
    end
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

--------------------------------------------------
-- Ebenen (6.40.1.0)
--------------------------------------------------
-- Eine Zelle hat ihre Grundflaeche und, wo Flaechen uebereinander liegen
-- (Wurzeln und Aeste in Teldrassil, Stadt unter dem Berg, Rampen, Bruecken),
-- weitere Ebenen. Knoten im Abschnitt: 0 .. C*C-1 die Grundflaeche, ab C*C
-- die Ebenen in der Reihenfolge der Daten. Uebergaenge:
--   * Grundflaeche zu Grundflaeche: die acht Nachbarn, Waende aus dem Gitter;
--   * eine Ebene: je Richtung (Bit) zur Flaeche der Nachbarzelle, die ihrer
--     Hoehe am naechsten liegt; dazu ausdrueckliche Uebergaenge;
--   * Grundflaeche zu einer Ebene: die Umkehrung der Uebergaenge der Ebenen.
-- Ohne die Ebenen (bis 6.40.0.0) lief die Linie quer durch Fels.

-- Hoehen der Grundflaeche (in Schritten zstep, je gegen den -y-Nachbarn,
-- sonst den -x-Nachbarn, sonst die vorige Zelle).
local function Heights(st, cl, hs)
    local C, z = st.C, {}
    local step = st.D.zstep or 2
    local pos, rep, delta, last = 1, 0, 0, 0
    local n = #hs
    for i = 0, C * C - 1 do
        if floor(byte(cl.cells, i + 1) / 16) ~= 0 then
            local pred = (i % C > 0 and z[i - 1]) or (i >= C and z[i - C]) or last
            local v
            if rep > 0 then
                rep, v = rep - 1, pred + delta
            else
                local sym = B64[byte(hs, pos)]
                if sym == 47 then
                    v, pos = Num(hs, pos + 1, 2) - 2048, pos + 3
                else
                    delta, pos = sym - 23, pos + 1
                    while pos <= n and B64[byte(hs, pos)] >= 48 do
                        rep, pos = rep + B64[byte(hs, pos)] - 47, pos + 1
                    end
                    v = pred + delta
                end
            end
            last, z[i] = v, v
        end
    end
    for i, v in pairs(z) do z[i] = v * step end
    return z
end

local function AddLink(lk, a, b, dir)
    local l = lk[a]
    if not l then l = {} lk[a] = l end
    l[#l + 1] = b
    l[#l + 1] = dir
end

-- Ebenen eines Abschnitts: cl.surf = { fat, fval, first, lk } oder false.
function NV.Surf(st, cl)
    if cl.surf ~= nil then return cl.surf end
    if not NV.Cells(st, cl) then cl.surf = false return false end
    local fs = Field(st.D, "floor", cl.k + 1)
    local C = st.C
    local CC = C * C
    local sf = { fat = {}, fval = {}, first = {}, lk = {} }
    if not fs or fs == "" then cl.surf = sf return sf end
    local hs = Field(st.D, "height", cl.k + 1)
    local zb = hs and Heights(st, cl, hs) or {}
    local fz, steps = {}, {}
    local node, pos = CC, 4
    for _ = 1, Num(fs, 1, 3) do
        local lc, count = Num(fs, pos, 3), B64[byte(fs, pos + 3)]
        pos = pos + 4
        sf.first[lc] = node
        for _ = 1, count do
            sf.fval[node] = B64[byte(fs, pos)]
            fz[node] = Num(fs, pos + 1, 2) - 2048
            sf.fat[node] = lc
            steps[node] = Num(fs, pos + 3, 2)
            pos, node = pos + 5, node + 1
        end
    end
    local last = node
    -- Flaeche in Zelle lc: Schicht (0 Grund, i i-te Ebene) oder die der
    -- Hoehe h naechste.
    local function Surface(lc, layer, h)
        if layer == 0 then return floor(byte(cl.cells, lc + 1) / 16) ~= 0 and lc or nil end
        local f0 = sf.first[lc]
        if layer and layer > 0 then
            local f = f0 and f0 + layer - 1
            return f and sf.fat[f] == lc and f or nil
        end
        local best, gap
        if floor(byte(cl.cells, lc + 1) / 16) ~= 0 then
            -- Ohne Hoehe der Grundflaeche: nur, wenn keine Ebene passt.
            best, gap = lc, zb[lc] and math.abs(zb[lc] - h) or 1e9
        end
        local f = f0
        while f and sf.fat[f] == lc do
            local d = math.abs(fz[f] - h)
            if not gap or d < gap then best, gap = f, d end
            f = f + 1
        end
        return best
    end
    local function Neighbour(lc, d)
        local x, y = floor(lc / C) + DX[d], lc % C + DY[d]
        if x < 0 or y < 0 or x >= C or y >= C then return nil end
        return x * C + y
    end
    local REV = { 2, 1, 4, 3, 8, 7, 6, 5 }
    local own = {}
    for f = CC, last - 1 do
        local bits, lc = steps[f], sf.fat[f]
        for d = 1, 8 do
            if bits % 2 == 1 then
                local nc = Neighbour(lc, d)
                local t = nc and Surface(nc, nil, fz[f])
                if t and t ~= f then AddLink(sf.lk, f, t, d) own[#own + 1] = { f, t, d } end
            end
            bits = floor(bits / 2)
        end
    end
    -- Ausdrueckliche Uebergaenge: Knoten(3) Richtung(1) Schicht(1).
    local m = Num(fs, pos, 3)
    for _ = 1, m do
        local nd, d, layer = Num(fs, pos + 3, 3), B64[byte(fs, pos + 6)] + 1, B64[byte(fs, pos + 7)]
        pos = pos + 5
        local lc = nd < CC and nd or sf.fat[nd]
        local nc = lc and DX[d] and Neighbour(lc, d)
        local t = nc and Surface(nc, layer)
        if t then
            AddLink(sf.lk, nd, t, d)
            if nd >= CC then own[#own + 1] = { nd, t, d } end
        end
    end
    -- Grundflaeche zu den Ebenen: die Umkehrung.
    for _, o in ipairs(own) do
        if o[2] < CC then AddLink(sf.lk, o[2], o[1], REV[o[3]]) end
    end
    cl.surf = sf
    return sf
end

-- Zelle und Wert eines Knotens.
local function NodeCellOf(sf, CC, node)
    if node < CC then return node end
    return sf.fat[node]
end
local function NodeWalk(cl, sf, CC, node)
    if node < CC then return Walk(cl, node) end
    return sf.fval[node] or 0
end
NV.NodeCellOf = NodeCellOf

-- Kosten (Zellen) von Knoten aus, im Abschnitt, ueber alle Ebenen. start:
-- ein Knoten oder eine Liste. Liefert dist und prev (wiederverwendbar ueber
-- `into`). Mit `target`: A* bis zu diesem Knoten.
function NV.Grid(st, cl, start, into, target)
    local C = st.C
    local CC = C * C
    local dist, prev = into.dist, into.prev
    for i in pairs(dist) do dist[i] = nil end
    for i in pairs(prev) do prev[i] = nil end
    local sf = NV.Surf(st, cl)
    if not (cl.cells and sf) then return dist, prev end
    local h = into.heap
    HeapClear(h)
    if type(start) == "table" then
        for _, s0 in ipairs(start) do dist[s0] = 0 HeapPush(h, 0, s0) end
    else
        dist[start] = 0
        HeapPush(h, 0, start)
    end
    local tc = target and NodeCellOf(sf, CC, target)
    local tx, ty = tc and floor(tc / C), tc and tc % C
    local lk = sf.lk
    local function Relax(a, b, dir, d)
        local v = NodeWalk(cl, sf, CC, b)
        if v == 0 then return end
        local nd = d + (dir <= 4 and 1 or 1.4142) * (v == 2 and st.swim or 1)
        if not dist[b] or nd < dist[b] then
            dist[b], prev[b] = nd, a
            local hb = 0
            if tc then
                local bc = NodeCellOf(sf, CC, b)
                hb = math.sqrt((floor(bc / C) - tx) ^ 2 + (bc % C - ty) ^ 2)
            end
            HeapPush(h, nd + hb, b)
        end
    end
    while h.n > 0 do
        local f, a = HeapPop(h)
        if a == target then break end
        local d = dist[a]
        local ac = NodeCellOf(sf, CC, a)
        local hA = tc and math.sqrt((floor(ac / C) - tx) ^ 2 + (ac % C - ty) ^ 2) or 0
        if f <= d + hA + 1e-6 then
            Slice()
            if a < CC then
                local ax, ay = floor(a / C), a % C
                for dir = 1, 8 do
                    local bx, by = ax + DX[dir], ay + DY[dir]
                    if bx >= 0 and by >= 0 and bx < C and by < C then
                        local b = bx * C + by
                        if Walk(cl, b) ~= 0 then
                            local open
                            if dir <= 4 then
                                open = StepOpen(cl, C, a, dir)
                            else
                                local ox, oy = ORTH_X[dir], ORTH_Y[dir]
                                local mx, my = (ax + DX[ox]) * C + ay, ax * C + ay + DY[oy]
                                open = (Walk(cl, mx) ~= 0 and StepOpen(cl, C, a, ox) and StepOpen(cl, C, mx, oy))
                                    or (Walk(cl, my) ~= 0 and StepOpen(cl, C, a, oy) and StepOpen(cl, C, my, ox))
                                -- Ausdruecklich offene Schraegen (Schalter 4/8).
                                if not open then
                                    if dir == 5 then open = Flag(cl, a) >= 4 and floor(Flag(cl, a) / 4) % 2 == 1
                                    elseif dir == 6 then open = Flag(cl, a) >= 8
                                    elseif dir == 7 then open = Flag(cl, b) >= 8
                                    elseif dir == 8 then open = floor(Flag(cl, b) / 4) % 2 == 1 end
                                end
                            end
                            if open then Relax(a, b, dir, d) end
                        end
                    end
                end
            end
            local l = lk[a]
            if l then
                for j = 1, #l, 2 do Relax(a, l[j], l[j + 1], d) end
            end
        end
    end
    return dist, prev
end

-- 6.40.1.0 (Beta-Test Nachtelf, Shadowglen: "erst nach Norden an den
-- Kartenrand, dann nach Sueden"): die naechste begehbare Zelle lag in einer
-- abgeschlossenen Tasche (sieben Zellen, ringsum Waende). Von dort war kein
-- Eingang erreichbar, die Suche nahm die Luftlinie zu einem fernen Eingang
-- und lief dorthin und zurueck. Jetzt zaehlt nur eine Zelle, von der aus
-- mindestens ein Eingang der Grundflaeche erreichbar ist - die naechste
-- solche im Umkreis NV.SNAP_FAR, sonst wie vorher die naechste ueberhaupt.
NV.SNAP_FAR = 12
NV.SNAP_TRIES = 10

-- Zellen um `cell` mit irgendeiner begehbaren Flaeche, nach Abstand.
local function Around(st, cl, sf, cell, radius, out)
    local C = st.C
    local cx, cy = floor(cell / C), cell % C
    local function Has(c) return Walk(cl, c) ~= 0 or (sf and sf.first[c] ~= nil) end
    if Has(cell) then out[#out + 1] = cell end
    for r = 1, radius do
        for dx = -r, r do
            for dy = -r, r do
                if math.abs(dx) == r or math.abs(dy) == r then
                    local x, y = cx + dx, cy + dy
                    if x >= 0 and y >= 0 and x < C and y < C and Has(x * C + y) then out[#out + 1] = x * C + y end
                end
            end
        end
    end
    return out
end

-- Alle Flaechen einer Zelle: Grund (wenn begehbar) und ihre Ebenen. Wie
-- hoch der Spieler steht, sagt der Client nicht (UnitPosition: Hoehe 0) -
-- die Suche geht von allen aus und nimmt den kuerzesten Weg.
function NV.Surfaces(st, cl, sf, cell, out)
    out = out or {}
    if Walk(cl, cell) ~= 0 then out[#out + 1] = cell end
    local f = sf and sf.first[cell]
    while f and sf.fat[f] == cell do
        if (sf.fval[f] or 0) ~= 0 then out[#out + 1] = f end
        f = f + 1
    end
    return out
end

-- Knoten eines Eingangs im Abschnitt (Grund: Zelle, Ebene: C*C + Nummer).
function NV.NodeLocal(st, id)
    local k, i = floor(id / 4096), id % 4096
    local cl = NV.Cluster(st, k)
    if not cl or i >= cl.n then return nil end
    return k, Num(cl.s, 3 + i * 7, 3)
end

-- Flaechen nahe `cell`, die mit dem Wegenetz verbunden sind, und ihr
-- Gitter (into). Liefert die Liste der Startknoten oder nil.
function NV.Anchor(st, cl, k, cell, into, extra)
    if not NV.Cells(st, cl) then return nil end
    local sf = NV.Surf(st, cl)
    local list = Around(st, cl, sf, cell, NV.SNAP_FAR, {})
    if #list == 0 then return nil end
    local tries, bad = 0, {}
    local fallback
    for _, c in ipairs(list) do
        if not bad[c] then
            tries = tries + 1
            if tries > NV.SNAP_TRIES then break end
            local src = NV.Surfaces(st, cl, sf, c)
            if #src > 0 then
                fallback = fallback or src
                local dist = NV.Grid(st, cl, src, into)
                if extra then
                    for x in pairs(extra) do if dist[x] then return src end end
                end
                for i = 0, cl.n - 1 do
                    local _, ln = NV.NodeLocal(st, k * 4096 + i)
                    if ln and dist[ln] then return src end
                end
                for x in pairs(dist) do
                    local xc = x < st.C * st.C and x or (sf and sf.fat[x])
                    if xc then bad[xc] = true end
                end
            end
        end
    end
    -- Nichts verbunden (Insel, Hoehle ohne Eingang): die naechste, wie bisher.
    if fallback then NV.Grid(st, cl, fallback, into) end
    return fallback
end

-- Die naechste begehbare Zelle im Umkreis NV.SNAP, oder nil.
function NV.Snap(st, cl, cell)
    if not NV.Cells(st, cl) then return nil end
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

-- Feste Arbeitstabellen (6.35.2.0): jede Suche kopierte vorher die Gitter
-- von Start und Ziel in neue Tabellen (je einige tausend Eintraege) und
-- legte Kosten, Herkunft und Haufen neu an - rund ein halbes MB Abfall je
-- Suche. Jetzt werden sie geleert und wiederverwendet.
local scratchA = { dist = {}, prev = {}, heap = HeapNew() }
local scratchB = { dist = {}, prev = {}, heap = HeapNew() }
local scratchR = { dist = {}, prev = {}, heap = HeapNew() }
local work = { g = {}, from = {}, goalCost = {}, heap = HeapNew() }
local function Wipe(t) for key in pairs(t) do t[key] = nil end end

-- Sicht ueber das Gitter (6.37.1.0): von Zelle a geradeaus nach Zelle b,
-- ohne eine Wand (geschlossene Kante), eine gesperrte Zelle oder - wenn man
-- nicht schon schwimmt - Wasser zu kreuzen. Schritt fuer Schritt durch die
-- Zellen, die die Linie zwischen den Mitten beruehrt; trifft sie genau eine
-- Ecke, reicht einer der beiden Umwege (wie in der Suche).
local function Sees(cl, C, a, b)
    local x, y = floor(a / C), a % C
    local x1, y1 = floor(b / C), b % C
    local nx, ny = math.abs(x1 - x), math.abs(y1 - y)
    local sx, sy = x1 > x and 1 or -1, y1 > y and 1 or -1
    local dirX, dirY = sx > 0 and 1 or 2, sy > 0 and 3 or 4
    local water = Walk(cl, a) == 2
    local function Ok(c) local v = Walk(cl, c) return v == 1 or (v == 2 and water) end
    local ix, iy = 0, 0
    local cur = a
    while ix < nx or iy < ny do
        local tx, ty = (ix + 0.5) * ny, (iy + 0.5) * nx
        if ix < nx and (iy >= ny or tx < ty) then
            local nb = cur + sx * C
            if not (Ok(nb) and StepOpen(cl, C, cur, dirX)) then return false end
            cur, ix = nb, ix + 1
        elseif iy < ny and (ix >= nx or ty < tx) then
            local nb = cur + sy
            if not (Ok(nb) and StepOpen(cl, C, cur, dirY)) then return false end
            cur, iy = nb, iy + 1
        else
            -- Genau ueber die Ecke.
            local mx, my, d = cur + sx * C, cur + sy, cur + sx * C + sy
            local open = (Ok(mx) and StepOpen(cl, C, cur, dirX) and StepOpen(cl, C, mx, dirY))
                or (Ok(my) and StepOpen(cl, C, cur, dirY) and StepOpen(cl, C, my, dirX))
            if not (open and Ok(d)) then return false end
            cur, ix, iy = d, ix + 1, iy + 1
        end
    end
    return true
end
NV.Sees = Sees

NV.PULL = 24   -- so viele Zellen weit schaut das Glaetten hoechstens

-- Polylinie (flach n, w, n, w ...) im Abschnitt von Zelle a rueckwaerts
-- ueber prev bis zum Start. 6.37.1.0 (Beta-Test Ironforge: "durch einen
-- Raum ohne Tuer"): vorher blieb jede vierte Zelle stehen, die Linie
-- dazwischen schnitt Ecken durch Waende. Jetzt bleibt nur, wo die Sicht
-- endet - die Linie knickt an den Ecken und kreuzt nie eine Wand.
-- Aus einer Kette von Zellen (vom Start aus) nur die behalten, an denen die
-- Sicht endet.
local function Pull(cl, C, cells, list)
    local n = #cells
    if n == 0 then return list end
    list[#list + 1] = cells[1]
    if not (cl and cl.cells) then
        for i = 2, n do list[#list + 1] = cells[i] end
        return list
    end
    local anchor, i = 1, 2
    while i <= n do
        Slice()
        if i < n and i - anchor < NV.PULL and Sees(cl, C, cells[anchor], cells[i + 1]) then
            i = i + 1
        else
            list[#list + 1] = cells[i]
            anchor, i = i, i + 1
        end
    end
    return list
end

local function GridChain(st, k, prev, from, out, reverse)
    local nodes, c = {}, from
    while c do nodes[#nodes + 1] = c c = prev[c] end
    if not reverse then
        -- prev zeigt zum Start: umdrehen, damit die Linie vom Start kommt.
        local i, j = 1, #nodes
        while i < j do nodes[i], nodes[j] = nodes[j], nodes[i] i, j = i + 1, j - 1 end
    end
    local cl = NV.Cluster(st, k)
    local sf = cl and NV.Surf(st, cl)
    local CC = st.C * st.C
    -- Laeufe auf der Grundflaeche glaetten; Ebenen bleiben Punkt fuer Punkt
    -- (die Sicht ueber das Gitter gilt nur am Boden).
    local list, run = {}, {}
    local function Flush()
        if #run > 0 then Pull(cl, st.C, run, list) end
        run = {}
    end
    for _, n in ipairs(nodes) do
        if n < CC then run[#run + 1] = n
        else
            Flush()
            local lc = sf and sf.fat[n]
            if lc then list[#list + 1] = lc end
        end
    end
    Flush()
    local lastCell
    for i = 1, #list do
        if list[i] ~= lastCell then
            local pn, pw = NV.CellPos(st, k, list[i])
            out[#out + 1], out[#out + 2] = pn, pw
            lastCell = list[i]
        end
    end
end

-- 6.40.1.0: eine Kante des Wegenetzes kann von einem Eingang quer durch den
-- Nachbarabschnitt zum naechsten fuehren - gezeichnet war das eine gerade
-- Linie ueber Fels und Wasser (Beta-Test Teldrassil). Jetzt: A* ueber die
-- Zellen beider Abschnitte zusammen (Gitter ueber den ganzen Kontinent
-- gedacht: gx = Abschnitt-x * C + Zelle-x).
local function GKey(gx, gy) return gx * 65536 + gy end
local bridge = { dist = {}, prev = {}, heap = HeapNew() }
function NV.Bridge(st, ka, ca, kb, cb, out, limit)
    local C = st.C
    local cla, clb = NV.Cluster(st, ka), NV.Cluster(st, kb)
    if not (cla and clb and NV.Cells(st, cla) and NV.Cells(st, clb)) then return false end
    local allowed = { [ka] = cla, [kb] = clb }
    local function Split(gx, gy)
        local ix, iy = floor(gx / C), floor(gy / C)
        local k = ix * st.ny + iy
        local cl = allowed[k]
        if not cl or iy < 0 or iy >= st.ny then return nil end
        return k, cl, (gx - ix * C) * C + (gy - iy * C)
    end
    local function GW(gx, gy)
        local _, cl, c = Split(gx, gy)
        return cl and Walk(cl, c) or 0
    end
    local function Open(gx, gy, dir)
        -- +x/+y: Schalter der eigenen Zelle; -x/-y: der des Nachbarn.
        if dir == 1 or dir == 3 then
            local _, cl, c = Split(gx, gy)
            return cl and (dir == 1 and Flag(cl, c) % 2 == 0 or dir == 3 and floor(Flag(cl, c) / 2) % 2 == 0)
        end
        local nx, ny = gx + DX[dir], gy + DY[dir]
        local _, cl, c = Split(nx, ny)
        return cl and (dir == 2 and Flag(cl, c) % 2 == 0 or dir == 4 and floor(Flag(cl, c) / 2) % 2 == 0)
    end
    local ax0, ay0 = floor(ka / st.ny) * C + floor(ca / C), (ka % st.ny) * C + ca % C
    local bx0, by0 = floor(kb / st.ny) * C + floor(cb / C), (kb % st.ny) * C + cb % C
    local dist, prev, h = bridge.dist, bridge.prev, bridge.heap
    Wipe(dist) Wipe(prev) HeapClear(h)
    local s0, t0 = GKey(ax0, ay0), GKey(bx0, by0)
    dist[s0] = 0
    HeapPush(h, 0, s0)
    local found = false
    while h.n > 0 do
        local f, a = HeapPop(h)
        if a == t0 then found = true break end
        local ax, ay = floor(a / 65536), a % 65536
        local d = dist[a]
        if f <= d + sqrt((ax - bx0) ^ 2 + (ay - by0) ^ 2) + 1e-6 then
            Slice()
            for dir = 1, 8 do
                local bx, by = ax + DX[dir], ay + DY[dir]
                local v = GW(bx, by)
                if v ~= 0 then
                    local open
                    if dir <= 4 then open = Open(ax, ay, dir)
                    else
                        local ox, oy = ORTH_X[dir], ORTH_Y[dir]
                        open = (GW(ax + DX[ox], ay) ~= 0 and Open(ax, ay, ox) and Open(ax + DX[ox], ay, oy))
                            or (GW(ax, ay + DY[oy]) ~= 0 and Open(ax, ay, oy) and Open(ax, ay + DY[oy], ox))
                    end
                    if open then
                        local nd = d + (dir <= 4 and 1 or 1.4142) * (v == 2 and st.swim or 1)
                        local b = GKey(bx, by)
                        if (not dist[b] or nd < dist[b]) and (not limit or nd <= limit) then
                            dist[b], prev[b] = nd, a
                            HeapPush(h, nd + sqrt((bx - bx0) ^ 2 + (by - by0) ^ 2), b)
                        end
                    end
                end
            end
        end
    end
    if not found then return false end
    -- Kette vom Start, je Abschnitt geglaettet.
    local keys, c = {}, t0
    while c do keys[#keys + 1] = c c = prev[c] end
    local runK, run = nil, {}
    local function Flush()
        if runK then
            local list = Pull(allowed[runK], C, run, {})
            for i = 1, #list do
                local pn, pw = NV.CellPos(st, runK, list[i])
                out[#out + 1], out[#out + 2] = pn, pw
            end
        end
        run = {}
    end
    for i = #keys, 1, -1 do
        local key = keys[i]
        local k, _, cell = Split(floor(key / 65536), key % 65536)
        if k ~= runK then Flush() runK = k end
        run[#run + 1] = cell
    end
    Flush()
    return true
end

NV.GridChain = GridChain

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
    local size = st.cs
    -- Vom Start und zum Ziel: alle Flaechen der Zelle (feste Tabellen),
    -- verankert an Flaechen, die mit dem Wegenetz verbunden sind.
    Wipe(scratchA.dist) Wipe(scratchA.prev) Wipe(scratchB.dist) Wipe(scratchB.prev)
    local gsrc = NV.Anchor(st, clg, kg, cg0, scratchB)
    local goalSet
    if gsrc and ks == kg then
        goalSet = {}
        for _, x in ipairs(gsrc) do goalSet[x] = true end
    end
    local ssrc = NV.Anchor(st, cls, ks, cs0, scratchA, goalSet)
    local distS, prevS = scratchA.dist, scratchA.prev
    local dg, pg = scratchB.dist, scratchB.prev
    -- Im selben Abschnitt und verbunden: fertig (das beste Ziel).
    local best, bestNode, bestGoal = huge, nil, nil
    if goalSet and ssrc then
        for x in pairs(goalSet) do
            if distS[x] and distS[x] * size < best then best, bestGoal = distS[x] * size, x end
        end
    end
    -- Ziel-Eingaenge mit ihren Kosten bis zum Ziel.
    local goalCost = work.goalCost
    Wipe(goalCost)
    for i = 0, clg.n - 1 do
        local id = kg * 4096 + i
        local _, ln = NV.NodeLocal(st, id)
        if ln then
            if gsrc and dg[ln] then
                goalCost[id] = dg[ln] * size
            elseif not gsrc then
                local n, w = NV.NodePos(st, id)
                if n then goalCost[id] = sqrt((n - gN) ^ 2 + (w - gW) ^ 2) * 1.5 end
            end
        end
    end
    -- A* ueber die Eingaenge.
    local g, from = work.g, work.from
    Wipe(g) Wipe(from)
    local heap = work.heap
    HeapClear(heap)
    for i = 0, cls.n - 1 do
        local id = ks * 4096 + i
        local _, ln = NV.NodeLocal(st, id)
        local cost
        if ln then
            if ssrc and distS[ln] then
                cost = distS[ln] * size
            elseif not ssrc then
                local n, w = NV.NodePos(st, id)
                if n then cost = sqrt((n - sN) ^ 2 + (w - sW) ^ 2) * 1.5 end
            end
        end
        if cost then
            g[id] = cost
            local n, w = NV.NodePos(st, id)
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
            -- 6.81.1.0 (Ironforge: Kante vom Boden auf den Berg, 194 hoch bei
            -- Kosten 8 - die Route lief ueber den Berg statt durchs Tor):
            -- gesperrte Kanten im Abschnitt (data/nav_blocked.lua, Schluessel
            -- u * 4096 + Knoten), ohne Tabelle oder Text je Kante.
            local blocked = not NV.NavBlockedOff and WeintCodex.NavBlocked and WeintCodex.NavBlocked[c] or nil
            for _ = 1, B64[byte(s, 3 + iu * 7 + 6)] do
                local off = B64[byte(s, pos)]
                local kt = ku + (floor(off / 3) - 1) * st.ny + off % 3 - 1
                local iv = Num(s, pos + 1, 2)
                local v = kt * 4096 + iv
                local nd = gu + Num(s, pos + 3, 2)
                if blocked and kt == ku and blocked[u * 4096 + iv] then
                    -- gesperrt
                elseif not g[v] or nd < g[v] then
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
        out[1], out[2] = sN, sW
        GridChain(st, ks, prevS, bestGoal, out, false)
        out[#out + 1], out[#out + 2] = gN, gW
        return out, best
    end
    -- Eingaenge rueckwaerts sammeln.
    local chain, u = {}, bestNode
    while u do chain[#chain + 1] = u u = from[u] end
    out[1], out[2] = sN, sW
    local _, l1 = NV.NodeLocal(st, chain[#chain])
    if ssrc and l1 and distS[l1] then GridChain(st, ks, prevS, l1, out, false) end
    -- Eingaenge der Reihe nach, dazwischen ueber die Zellen und Ebenen
    -- (6.32.4.0 im Abschnitt, 6.40.1.0 auch ueber die Grenze und Ebenen).
    for i = #chain, 1, -1 do
        local id = chain[i]
        if i < #chain then
            local prevId = chain[i + 1]
            local ka, la = NV.NodeLocal(st, prevId)
            local kb, lb = NV.NodeLocal(st, id)
            local edge = (g[id] or 0) - (g[prevId] or 0)
            if ka and kb and ka ~= kb then
                local _, ca = NV.NodeCell(st, prevId)
                local _, cb = NV.NodeCell(st, id)
                if ca and cb then NV.Bridge(st, ka, ca, kb, cb, out, (edge * 1.3 + 16) / size) end
            elseif ka and ka == kb and la ~= lb then
                local cl = NV.Cluster(st, ka)
                if cl and NV.Cells(st, cl) then
                    local d, p = NV.Grid(st, cl, la, scratchR, lb)
                    if p[lb] and d[lb] * size <= edge * 1.3 + 16 then
                        GridChain(st, ka, p, lb, out, false)
                    end
                end
            end
        end
        local n, w = NV.NodePos(st, id)
        out[#out + 1], out[#out + 2] = n, w
    end
    local _, l2 = NV.NodeLocal(st, bestNode)
    if gsrc and l2 and dg[l2] then GridChain(st, kg, pg, l2, out, true) end
    out[#out + 1], out[#out + 2] = gN, gW
    return out, best
end

--------------------------------------------------
-- Auftraege: eine Suche zur Zeit, verteilt ueber Bilder
--------------------------------------------------

local job = { co = nil }
local result = { path = nil }       -- das zuletzt fertige Ergebnis (Pruefung)
NV._job, NV._result = job, result
local pump = CreateFrame("Frame")

-- 6.35.3.2 (/wcui speicher: Gelaendekarte lief 30 s ohne Pause): der Pfeil
-- wechselt sein Ziel mit dem Planer (Wegpunkt, Flugmeister, Quest), und
-- jede neue Suche brach die laufende ab - fertig wurde keine. Jetzt:
--   * Ergebnisse je Ziel gemerkt (NV.MEMO Stueck), auch Fehlschlaege;
--   * eine laufende Suche wird erst nach NV.MIN_RUN ms ersetzt;
--   * Zaehler fuer /wcui pfeil.
NV.MEMO, NV.MIN_RUN = 6, 3000
local memo = {}
NV._memo = memo
NV.stats = { started = 0, done = 0, failed = 0, replaced = 0, reused = 0 }

local function Same(e, c, gN, gW)
    return e.c == c and math.abs(e.gN - gN) < 2 and math.abs(e.gW - gW) < 2
end
local function Find(c, gN, gW)
    for _, e in ipairs(memo) do if Same(e, c, gN, gW) then return e end end
end
local function Remember(c, gN, gW, path, len, sN, sW)
    local e = Find(c, gN, gW)
    if not e then
        if #memo >= NV.MEMO then table.remove(memo, 1) end
        e = {}
        memo[#memo + 1] = e
    end
    e.c, e.gN, e.gW, e.path, e.len, e.failed = c, gN, gW, path, len, path == nil
    e.fN, e.fW = sN, sW
    result.path, result.len, result.c, result.gN, result.gW = path, len, c, gN, gW
    result.sN, result.sW, result.failed = sN, sW, path == nil
end

local Pump
Pump = function()
    if not job.co then pump:SetScript("OnUpdate", nil) return end
    deadline = Clock() + NV.BUDGET
    local ok, path, len = coroutine.resume(job.co)
    deadline = huge
    if not ok then
        job.co = nil
        NV.stats.failed = NV.stats.failed + 1
        Remember(job.c, job.gN, job.gW, nil, nil, job.sN, job.sW)
        pump:SetScript("OnUpdate", nil)
        return
    end
    if coroutine.status(job.co) == "dead" then
        job.co = nil
        if path then NV.stats.done = NV.stats.done + 1 else NV.stats.failed = NV.stats.failed + 1 end
        Remember(job.c, job.gN, job.gW, path, len, job.sN, job.sW)
        pump:SetScript("OnUpdate", nil)
    end
end
Pump = K.Measured and K.Measured("Geländekarte", Pump) or Pump
NV.Pump = Pump

local function Start(c, sN, sW, gN, gW)
    if job.co then NV.stats.replaced = NV.stats.replaced + 1 end
    job.c, job.sN, job.sW, job.gN, job.gW, job.t0 = c, sN, sW, gN, gW, Clock()
    job.co = coroutine.create(function() return NV.Search(c, sN, sW, gN, gW) end)
    NV.stats.started = NV.stats.started + 1
    pump:SetScript("OnUpdate", Pump)
end

-- Weg zur Lage (gN, gW), oder nil (noch nicht da, keine Karte, kein Weg).
-- Neu gesucht bei neuem Ziel oder wenn man sich vom Weg entfernt hat.
function NV.Path(c, sN, sW, gN, gW)
    if not NV.Available(c) then return nil end
    local e = Find(c, gN, gW)
    local have = e and e.path or nil
    if have and NV.OffPath(have, sN, sW) <= NV.REPATH_MOVE then
        NV.stats.reused = NV.stats.reused + 1
        return have, e.len
    end
    if job.co then
        -- Dieselbe Suche laeuft schon - oder eine andere, die noch nicht
        -- lange genug lief, um sie aufzugeben.
        if Same(job, c, gN, gW) or Clock() - (job.t0 or 0) < NV.MIN_RUN then return have end
    end
    -- Kein Weg zu diesem Ziel von hier: erst nach 30 Einheiten neu versuchen.
    if e and e.failed and e.fN and (sN - e.fN) ^ 2 + (sW - e.fW) ^ 2 < 900 then return nil end
    if K.InCombat and K.InCombat() then return have end
    Start(c, sN, sW, gN, gW)
    return have
end

function NV.Reset()
    job.co = nil
    result.path, result.c, result.failed = nil, nil, nil
    for i = #memo, 1, -1 do memo[i] = nil end
    pump:SetScript("OnUpdate", nil)
end

function NV.StatusLine()
    local s2 = NV.stats
    return string.format("Geländekarte: Suchen %d · fertig %d · ohne Weg %d · abgebrochen %d · wiederverwendet %d · läuft %s",
        s2.started, s2.done, s2.failed, s2.replaced, s2.reused, job.co and "ja" or "nein")
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
    -- Voraus schauen - aber nie ueber eine Ecke hinweg (6.37.1.0): der
    -- Weg knickt dort, wo die Sicht endet; ein Punkt hinter der Ecke laege
    -- hinter der Wand. Erst kurz vor der Ecke (NV.CORNER) zeigt der Pfeil
    -- schon den naechsten Abschnitt entlang.
    local need = NV.LOOKAHEAD
    if left >= NV.CORNER then
        local t = bestU + math.min(need, left) / math.max(seg, 0.01)
        return aN + (bN - aN) * t, aW + (bW - aW) * t, rest, bestI
    end
    for i = bestI + 2, #path - 3, 2 do
        local l = sqrt((path[i + 2] - path[i]) ^ 2 + (path[i + 3] - path[i + 1]) ^ 2)
        if l >= NV.CORNER or i + 4 > #path - 1 then
            local t = math.min(need, l) / math.max(l, 0.01)
            return path[i] + (path[i + 2] - path[i]) * t, path[i + 1] + (path[i + 3] - path[i + 1]) * t, rest, bestI
        end
    end
    return path[#path - 1], path[#path], rest, bestI
end
