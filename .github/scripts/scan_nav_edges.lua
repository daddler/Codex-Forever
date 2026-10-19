-- Gesperrte Kanten der Gelaendekarte -> data/nav_blocked.lua (6.81.1.0).
--
--   lua5.1 .github/scripts/scan_nav_edges.lua .
--
-- Liest data/nav/*.lua (nur Daten) und rechnet mit ui/navmesh.lua selbst.
-- Gesperrt wird eine Kante innerhalb eines Abschnitts, wenn
--   * der Hoehenunterschied ihrer Knoten groesser ist als ihre Kosten
--     (steiler als 45 Grad - kein Weg, eine Kletterei) UND
--   * das Gitter des Abschnitts (Grund und Ebenen) keinen Weg zwischen
--     beiden Knoten kennt.
-- Anlass: Ironforge, Abschnitt 471, Knoten 52 -> 26: vom Boden der Stadt
-- (Hoehe 498) auf den Berg (692) bei Kosten 8 - die Route lief ueber den Berg.
-- Entpacken (zlib) ueber python3 (Lua 5.1 hat kein zlib).
local root = arg[1] or "."
local tmp = os.tmpname()

WeintCodex = { UIKit = {} }
CreateFrame = function() return { SetScript = function() end } end
local files = {}
for f in io.popen('ls "' .. root .. '/data/nav"'):lines() do
    if f:match("^nav%d+_%d+%.lua$") then files[#files + 1] = f end
end
for _, f in ipairs(files) do dofile(root .. "/data/nav/" .. f) end

-- Rohe Felder je Kontinent entpacken.
local function Unpack(D)
    local out = io.open(tmp, "wb")
    for _, field in ipairs({ "graph", "grid", "fcell", "floor", "height" }) do
        for k, b in pairs(D[field] or {}) do
            if type(b) == "string" then b = { b } end
            for i, s in ipairs(b) do out:write(field, " ", k, " ", i, " ", #s, "\n", s) end
        end
    end
    out:close()
    local py = [[
import sys, zlib
d = open(sys.argv[1], "rb").read(); p = 0; out = {}
while p < len(d):
    e = d.index(b"\n", p); f, k, i, n = d[p:e].decode().split(); n = int(n)
    out.setdefault((f, int(k)), {})[int(i)] = zlib.decompress(d[e + 1:e + 1 + n]); p = e + 1 + n
w = open(sys.argv[1] + ".lua", "w")
w.write("return function(R)\n")
for (f, k), parts in out.items():
    r = b"".join(parts[i] for i in sorted(parts))
    w.write('R["%s"][%d]="%s"\n' % (f, k, "".join("\\%d" % c for c in r)))
w.write("end\n")
]]
    local pf = io.open(tmp .. ".py", "w") pf:write(py) pf:close()
    assert(os.execute('python3 -I "' .. tmp .. '.py" "' .. tmp .. '"') == 0, "python3")
    local R = { graph = {}, grid = {}, fcell = {}, floor = {}, height = {} }
    dofile(tmp .. ".lua")(R)
    os.remove(tmp .. ".lua") os.remove(tmp .. ".py")
    return R
end

-- navmesh.lua mit Zugriff auf die Hoehen der Ebenen (nur hier).
local src = io.open(root .. "/ui/navmesh.lua"):read("*a")
src = src:gsub("    cl%.surf = sf\n    return sf\nend", "    cl.surf = sf sf.zb = zb sf.fz = fz\n    return sf\nend", 1)
assert(src:find("sf.zb = zb", 1, true), "navmesh.lua: Stelle fuer die Hoehen nicht gefunden")
assert(loadstring(src, "navmesh"))()
local NV = WeintCodex.UINav
NV.NavBlockedOff = true

local conts = {}
for c in pairs(WeintCodex.NavData) do conts[#conts + 1] = c end
table.sort(conts)
local result = {}
for _, c in ipairs(conts) do
    local D = WeintCodex.NavData[c]
    D.raw = Unpack(D)
    local st = NV.State(c)
    local CC = st.C * st.C
    local into = { dist = {}, prev = {}, heap = { n = 0, key = {}, val = {} } }
    local list = {}
    for k = 0, st.nx * st.ny - 1 do
        local cl = NV.Cluster(st, k)
        if cl and NV.Cells(st, cl) then
            local sf = NV.Surf(st, cl)
            local function Z(ln)
                if not sf then return nil end
                if ln < CC then return sf.zb and sf.zb[ln] end
                return sf.fz and sf.fz[ln]
            end
            local s = cl.s
            for iu = 0, cl.n - 1 do
                local pos = cl.edge[iu]
                local _, la = NV.NodeLocal(st, k * 4096 + iu)
                for _ = 1, NV.Num(s, 3 + iu * 7 + 6, 1) do
                    local off = NV.Num(s, pos, 1)
                    local kt = k + (math.floor(off / 3) - 1) * st.ny + off % 3 - 1
                    local iv, cost = NV.Num(s, pos + 1, 2), NV.Num(s, pos + 3, 2)
                    if kt == k then
                        local _, lb = NV.NodeLocal(st, k * 4096 + iv)
                        local za, zb = la and Z(la), lb and Z(lb)
                        if za and zb and math.abs(za - zb) > cost then
                            local d = NV.Grid(st, cl, la, into, lb)
                            if not d[lb] then list[#list + 1] = { k, iu, iv } end
                        end
                    end
                    pos = pos + 7
                end
            end
            cl.cells, cl.surf = nil, nil
        end
        st.clusters[k] = nil
    end
    D.raw = nil
    result[c] = list
    io.stderr:write(string.format("Kontinent %d: %d Kanten gesperrt\n", c, #list))
end

local out = io.open(root .. "/data/nav_blocked.lua", "w")
out:write("-- ERZEUGT von .github/scripts/scan_nav_edges.lua - nicht von Hand aendern.\n")
out:write("-- Gesperrte Kanten der Gelaendekarte (6.81.1.0): innerhalb eines Abschnitts,\n")
out:write("-- Hoehenunterschied groesser als die Kosten und kein Weg ueber das Gitter.\n")
out:write("-- Herkunft: gerechnet aus data/nav/*.lua (Art beta). Gelesen von ui/navmesh.lua.\n")
out:write("-- Schluessel: Abschnitt * 16777216 + von * 4096 + nach.\n")
out:write("WeintCodex = WeintCodex or {}\nWeintCodex.NavBlocked = {\n")
for _, c in ipairs(conts) do
    out:write(string.format("    [%d] = {", c))
    for i, e in ipairs(result[c]) do
        out:write(string.format("%s[%d]=true,", (i - 1) % 8 == 0 and "\n        " or " ", e[1] * 16777216 + e[2] * 4096 + e[3]))
    end
    out:write(#result[c] > 0 and "\n    },\n" or " },\n")
end
out:write("}\n")
out:close()
