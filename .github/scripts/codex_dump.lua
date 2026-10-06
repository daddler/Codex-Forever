-- Schreibt den Bestand des Codex, gegen den ein Abgleich laeuft, als JSON:
-- Dungeons mit Bossen, das handgepflegte Journal (Quests, Beute, Orte).
-- Aufruf (im Wurzelordner): lua5.1 .github/scripts/codex_dump.lua > codex.json
-- Benutzt von .github/scripts/import_foreverguide.py.

WeintCodex = {}
for _, f in ipairs({ "data/sources.lua", "data/dungeons.lua", "data/dungeons_classic.lua",
                     "data/dungeon_journal.lua" }) do
    dofile(f)
end

local D, J = WeintCodex.DungeonData, WeintCodex.DungeonJournal
local dungeons = {}
for _, d in ipairs(D.AllInstances()) do
    local bosses = {}
    for _, b in ipairs(d.bosses or {}) do bosses[#bosses + 1] = { id = b.id, name = b.name, wing = b.wing } end
    dungeons[#dungeons + 1] = { id = d.id, name = d.name, bosses = bosses }
end
local journal = {}
for id, e in pairs(J.DATA) do
    local quests, loot = {}, {}
    for _, q in ipairs(e.quests or {}) do quests[#quests + 1] = q.id end
    for bossId, list in pairs(e.loot or {}) do loot[bossId] = #list end
    journal[id] = { quests = quests, loot = loot, others = #(e.others or {}) }
end
local places = {}
for id in pairs(J.PLACES) do places[#places + 1] = id end

local function esc(s) return '"' .. tostring(s):gsub('[%c"\\]', function(c) return string.format("\\u%04x", c:byte()) end) .. '"' end
local function dump(v)
    if type(v) == "table" then
        local n, count = #v, 0
        for _ in pairs(v) do count = count + 1 end
        local parts = {}
        if count == n then
            for i = 1, n do parts[i] = dump(v[i]) end
            return "[" .. table.concat(parts, ",") .. "]"
        end
        for k, val in pairs(v) do parts[#parts + 1] = esc(k) .. ":" .. dump(val) end
        return "{" .. table.concat(parts, ",") .. "}"
    elseif type(v) == "string" then return esc(v)
    elseif type(v) == "nil" then return "null"
    else return tostring(v) end
end
io.write(dump({ dungeons = dungeons, journal = journal, places = places }))
