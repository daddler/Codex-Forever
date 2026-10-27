-- Schreibt das Dungeon-Journal des Codex, wie es VOR dem Naowh-Abgleich
-- dasteht, als JSON: Bosse je Dungeon, Beute je Boss mit ihrer Art
-- (Journal oder Classic), weitere Beute, Eingaenge und ein Verzeichnis
-- der Gegenstaende (Name, Platz, Qualitaet), die irgendwo im Journal stehen.
-- Aufruf (im Wurzelordner): lua5.1 .github/scripts/journal_dump.lua > cx.json
-- Benutzt von .github/scripts/import_naowh.py.

WeintCodex = {}
for _, f in ipairs({ "data/sources.lua", "data/dungeons.lua", "data/dungeons_classic.lua",
                     "data/dungeon_journal.lua", "data/dungeon_journal_fg.lua" }) do
    dofile(f)
end

local D, J = WeintCodex.DungeonData, WeintCodex.DungeonJournal
J.EnsureAllClassic()

local items = {}
local function note(e)
    if type(e) ~= "table" or type(e[1]) ~= "number" then return end
    local have = items[e[1]]
    if not have then items[e[1]] = { e[2], e[3], e[4] } return end
    have[2] = have[2] or e[3]
    have[3] = have[3] or e[4]
end

local dungeons = {}
for _, d in ipairs(D.AllInstances()) do
    local bosses = {}
    for _, b in ipairs(d.bosses or {}) do
        bosses[#bosses + 1] = { id = b.id, name = b.name, alt = b.nameAlt }
    end
    local e = J.DATA[d.id] or {}
    local loot = {}
    for bid, list in pairs(e.loot or {}) do
        local ids = {}
        for _, it in ipairs(list) do ids[#ids + 1] = it[1]; note(it) end
        loot[bid] = { ids = ids, kind = (J.LOOT_KIND[d.id] or {})[bid] or "journal" }
    end
    local others = {}
    for _, g in ipairs(e.others or {}) do
        local ids = {}
        for _, it in ipairs(g.items or {}) do ids[#ids + 1] = it[1]; note(it) end
        others[#others + 1] = { name = g.name, kind = g.kind or "journal", ids = ids }
    end
    for _, q in ipairs(e.quests or {}) do
        for _, r in ipairs(q.rewards or {}) do note({ r[1], r[2], nil, r[3] }) end
    end
    dungeons[#dungeons + 1] = { id = d.id, bosses = bosses, loot = loot, others = others,
                                entrance = J.ENTRANCES[d.id] ~= nil or (J.HAND_ENTRANCES or {})[d.id] ~= nil }
end
local list = {}
for id, v in pairs(items) do list[#list + 1] = { id = id, n = v[1], s = v[2], q = v[3] } end

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
io.write(dump({ dungeons = dungeons, items = list }))
