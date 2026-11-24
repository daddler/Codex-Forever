-- WeintCodex :: Questgeber der Dungeonquests auf der Karte (1.0.8.23)
--
--   lua5.1 .github/scripts/import_questgivers.lua <Codex-Ordner>
--
-- Wunsch: "alle Questgeber, die fuer Dungeons relevant sind, und deren
-- Standort durchsuchen und das Dungeonjournal aktualisieren, damit man die
-- Questgeber besser findet".
--
-- Liest nur eigene, schon erzeugte Bestaende: das Journal (mit den Abgleichen
-- fg/nf/ofa) und den Questbestand data/questdb.lua (QuestieDB Forever: Geber
-- je Quest, Lagen der NPCs und Objekte auf den Karten des Spiels).
-- Schreibt data/dungeon_questgivers.lua:
--   NEW   Quests ohne Kartenpunkt, deren Geber in der Welt steht
--   MOVED Kartenpunkte aus Classic-Berichten, deren Geber in Forever woanders
--         steht (anderes Gebiet oder > MOVE_DIST der Kartenbreite weg)
-- Geber in Instanzen, Quests aus Beute und Geber ohne Lage bleiben ohne Punkt.

local CDX = arg[1] or "."
local MOVE_DIST = 0.05

WeintCodex = {}
for _, f in ipairs({ "zoneinfo.lua", "dungeon_journal.lua", "dungeon_journal_fg.lua", "dungeon_journal_nf.lua",
                     "dungeon_journal_ofa.lua", "questdb.lua" }) do
    dofile(CDX .. "/data/" .. f)
end
local J = WeintCodex.DungeonJournal
local D = WeintCodex.QuestDBData
local WORLD = {}
for map in pairs(WeintCodex.ZoneInfoData) do WORLD[map] = true end

local function Field(raw, n)
    local i = 0
    for f in (raw .. "\t"):gmatch("([^\t]*)\t") do
        i = i + 1
        if i == n then return f end
    end
end
local function Ids(s)
    local out = {}
    for x in tostring(s or ""):gmatch("%d+") do out[#out + 1] = tonumber(x) end
    return out
end
-- Lagen eines NPC/Objekts: Name, { { map, x, y } } (nur Gebiete der Welt).
local function Spots(raw)
    if type(raw) ~= "string" then return nil, {} end
    local name, rest = raw:match("^([^\t]*)\t(.*)$")
    local out = {}
    for seg in (rest or ""):gmatch("[^;]+") do
        local map, pts = seg:match("^(%d+):(.*)$")
        map = tonumber(map)
        if map and WORLD[map] then
            local x, y = pts:match("^([%d.]+),([%d.]+)")
            if x then out[#out + 1] = { map, tonumber(x), tonumber(y) } end
        end
    end
    return name, out
end

-- Fraktion einer Quest aus dem Journal: Geber dieser Seite zuerst (Karten
-- der Hauptstaedte und Gebiete sind nicht getrennt - nur die Reihenfolge).
local ALLY = { [1453] = true, [1455] = true, [1457] = true, [1429] = true, [1426] = true, [1438] = true }
local HORDE = { [1454] = true, [1456] = true, [1458] = true, [1411] = true, [1412] = true, [1420] = true }

local new, moved, nNew, nMoved, nSame, nNone = {}, {}, 0, 0, 0, 0
local seen = {}
for did, d in pairs(J.DATA) do
    for _, q in ipairs(d.quests or {}) do
        if not seen[q.id] then
            seen[q.id] = true
            local raw = D.q[q.id]
            local cands = {}
            if raw then
                for _, id in ipairs(Ids(Field(raw, 6))) do
                    local name, sp = Spots(D.n[id])
                    for _, s in ipairs(sp) do cands[#cands + 1] = { s[1], s[2], s[3], name } end
                end
                for _, id in ipairs(Ids(Field(raw, 7))) do
                    local name, sp = Spots(D.o[id])
                    for _, s in ipairs(sp) do cands[#cands + 1] = { s[1], s[2], s[3], name } end
                end
            end
            local side = q.faction == "alliance" and ALLY or q.faction == "horde" and HORDE or nil
            if side then
                table.sort(cands, function(a, b)
                    local sa, sb = side[a[1]] and 0 or 1, side[b[1]] and 0 or 1
                    return sa < sb
                end)
            end
            local p = J.PLACES[q.id]
            if p and p.item then
                -- Fundort eines Gegenstands: nicht anfassen.
            elseif p then
                local near = false
                for _, c in ipairs(cands) do
                    if c[1] == p.map and math.abs(c[2] - p.x) <= MOVE_DIST and math.abs(c[3] - p.y) <= MOVE_DIST then near = true end
                end
                if #cands == 0 then nNone = nNone + 1
                elseif near then nSame = nSame + 1
                else
                    moved[#moved + 1] = { q.id, cands[1], p, did, q.name }
                    nMoved = nMoved + 1
                end
            elseif cands[1] and not (q.giverNpc and q.giverNpc.inside) then
                new[#new + 1] = { q.id, cands[1], did, q.name }
                nNew = nNew + 1
            end
        end
    end
end
table.sort(new, function(a, b) return a[1] < b[1] end)
table.sort(moved, function(a, b) return a[1] < b[1] end)

local function Num(v) return (string.format("%.4f", v):gsub("0+$", ""):gsub("%.$", "")) end
local L = {
    "--------------------------------------------------",
    "-- WeintCodex :: Questgeber der Dungeonquests (1.0.8.23)",
    "--------------------------------------------------",
    "-- ERZEUGT von .github/scripts/import_questgivers.lua - nicht von Hand.",
    "-- Herkunft (nur fuer Betreuer): data/questdb.lua (QuestieDB Forever) -",
    "-- Geber je Quest und ihre Lagen in Forever. NEW: Quests des Journals ohne",
    "-- Kartenpunkt. MOVED: Punkte aus Classic-Berichten, deren Geber in Forever",
    "-- woanders steht (anderes Gebiet oder mehr als 5 % der Kartenbreite).",
    "-- Art `community`. Geber in Instanzen und Quests aus Beute bleiben ohne.",
    "--------------------------------------------------",
    "",
    "local J = WeintCodex and WeintCodex.DungeonJournal",
    "if not (J and J.PLACES and J.DATA) then return end",
    "local NEW = {",
}
for _, e in ipairs(new) do
    local c = e[2]
    L[#L + 1] = string.format("    [%d] = { map = %d, x = %s, y = %s, who = %q }, -- %s: %s",
        e[1], c[1], Num(c[2]), Num(c[3]), c[4] or "?", e[3], e[4] or "")
end
L[#L + 1] = "}"
L[#L + 1] = "local MOVED = {"
for _, e in ipairs(moved) do
    local c, p = e[2], e[3]
    L[#L + 1] = string.format("    [%d] = { map = %d, x = %s, y = %s, who = %q }, -- %s: vorher %d %s,%s",
        e[1], c[1], Num(c[2]), Num(c[3]), c[4] or p.who or "?", e[4], p.map, Num(p.x), Num(p.y))
end
L[#L + 1] = "}"
L[#L + 1] = "for id, p in pairs(NEW) do if not J.PLACES[id] then p.forever = true J.PLACES[id] = p end end"
L[#L + 1] = "for id, p in pairs(MOVED) do p.forever = true J.PLACES[id] = p end"
-- Ohne Geber im Text: "Beginnt: Name, Gebiet" aus demselben Punkt.
L[#L + 1] = "for _, d in pairs(J.DATA) do for _, q in ipairs(d.quests or {}) do"
L[#L + 1] = "    local p = NEW[q.id] or MOVED[q.id]"
L[#L + 1] = "    if p and not q.giver and not q.giverNpc then q.giverNpc = { name = p.who, map = p.map, x = p.x, y = p.y } end"
L[#L + 1] = "end end"
L[#L + 1] = string.format("J.GIVERS_NEW, J.GIVERS_MOVED = %d, %d", nNew, nMoved)
local fh = assert(io.open(CDX .. "/data/dungeon_questgivers.lua", "w"))
fh:write(table.concat(L, "\n"), "\n")
fh:close()
print(string.format("neu %d, versetzt %d, bestaetigt %d, ohne Forever-Lage %d", nNew, nMoved, nSame, nNone))
