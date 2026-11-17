-- Feldbuch und Ruf-Belohnungen aus Naowh Forever (nur Daten).
--   lua5.1 .github/scripts/import_naowh_extra.lua <Ordner mit den NaowhForever_*-Ordnern>
-- Schreibt data/fieldjournal.lua und data/reprewards.lua. Naowh traegt keine
-- Lizenz ("All Rights Reserved") - uebernommen sind Fakten (Gegenstaende,
-- Gebiete, Anteile, Rufstufen, Preise, Lagen), keine Texte, kein Code.
local root = assert(arg[1], "Ordner fehlt")
local NF_VERSION = "1.2.33"
_G.NaowhForever = { Journal = {} }
local factions = {}
NaowhForever.Journal.AddFaction = function(key, t) t.key = key factions[#factions + 1] = t end
assert(loadfile(root .. "/NaowhForever_Discovery/Data/FieldJournal.lua"))()
local p = io.popen('ls "' .. root .. '/NaowhForever_DungeonJournal/Data/Factions"')
for f in p:lines() do assert(loadfile(root .. "/NaowhForever_DungeonJournal/Data/Factions/" .. f))() end
p:close()

local function ser(v)
    local t = type(v)
    if t == "number" then return (v == math.floor(v)) and string.format("%d", v) or string.format("%.1f", v) end
    if t == "string" then return string.format("%q", v) end
    if t == "boolean" then return tostring(v) end
    local parts, n = {}, #v
    for i = 1, n do parts[#parts + 1] = ser(v[i]) end
    local keys = {}
    for k in pairs(v) do if not (type(k) == "number" and k >= 1 and k <= n) then keys[#keys + 1] = k end end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    for _, k in ipairs(keys) do
        local kk = type(k) == "string" and k:match("^[%a_][%w_]*$") and k or ("[" .. ser(k) .. "]")
        parts[#parts + 1] = kk .. " = " .. ser(v[k])
    end
    return "{ " .. table.concat(parts, ", ") .. " }"
end

local FJ = NaowhForever.FieldJournal
local out = {
    "--------------------------------------------------",
    "-- WeintCodex :: Feldbuch - Fische, Kraeuter, Gerichte",
    "--------------------------------------------------",
    "-- ERZEUGT von .github/scripts/import_naowh_extra.lua aus Naowh Forever " .. NF_VERSION,
    "-- (Discovery, Feldbuch) - nicht von Hand aendern. Herkunft `community`.",
    "-- fish:   { item, skill, zones = { Karte, Anteil %, ... }, schools }",
    "-- herbs:  { item, skill, zones = { Karte, ... }, nodes = { Objekt, ... } }",
    "-- dishes: { spell, item, skill, how, A/H/B = { Name, Karte, x, y } }",
    "--------------------------------------------------",
    "",
    "WeintCodex = WeintCodex or {}",
    "WeintCodex.FieldJournalData = {",
    '    SOURCE = { kind = "community", label = "von Spielern gesammelt" },',
}
for _, part in ipairs({ "fish", "herbs", "dishes" }) do
    out[#out + 1] = "    " .. part .. " = {"
    for _, e in ipairs(FJ[part] or {}) do out[#out + 1] = "        " .. ser(e) .. "," end
    out[#out + 1] = "    },"
end
out[#out + 1] = "}"
local f = assert(io.open("data/fieldjournal.lua", "w")) f:write(table.concat(out, "\n") .. "\n") f:close()

table.sort(factions, function(a, b) return a.id < b.id end)
out = {
    "--------------------------------------------------",
    "-- WeintCodex :: Ruf-Belohnungen beim Ruestmeister",
    "--------------------------------------------------",
    "-- ERZEUGT von .github/scripts/import_naowh_extra.lua aus Naowh Forever " .. NF_VERSION,
    "-- (Dungeon Journal, Ruf) - nicht von Hand aendern. Herkunft `community`.",
    "-- [Fraktion] = { name, qm = { Name, Karte, x, y }, tiers = { { Rufstufe, { Gegenstand, ... } } },",
    "--               prices = { [Gegenstand] = Kupfer } }",
    "--------------------------------------------------",
    "",
    "WeintCodex = WeintCodex or {}",
    "WeintCodex.RepRewardsData = {",
    '    SOURCE = { kind = "community", label = "von Spielern gesammelt" },',
    "    factions = {",
}
local n = 0
for _, fa in ipairs(factions) do
    if fa.tiers and #fa.tiers > 0 then
        n = n + 1
        local q = fa.quartermaster
        local t = { name = fa.name, tiers = {}, prices = fa.prices or {} }
        if q then t.qm = { q.name, q.map, q.x, q.y } end
        for _, tier in ipairs(fa.tiers) do t.tiers[#t.tiers + 1] = { tier.standing, tier.items } end
        out[#out + 1] = "        [" .. fa.id .. "] = " .. ser(t) .. ","
    end
end
out[#out + 1] = "    },"
out[#out + 1] = "}"
f = assert(io.open("data/reprewards.lua", "w")) f:write(table.concat(out, "\n") .. "\n") f:close()
print(#FJ.fish .. " Fische, " .. #FJ.herbs .. " Kräuter, " .. #FJ.dishes .. " Gerichte, " .. n .. " Fraktionen")
