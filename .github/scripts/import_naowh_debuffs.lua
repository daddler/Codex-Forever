-- Zaubernummern der Raid-Debuffs auf Forever aus Naowh Forever (nur Daten,
-- dort erzeugt aus dem Client-Build). Schreibt data/debuffids_nf.lua.
--   lua5.1 .github/scripts/import_naowh_debuffs.lua <NaowhForever_Combat-Ordner>
local dir = assert(arg[1])
_G.NaowhForever = {}
assert(loadfile(dir .. "/RaidDebuffs/Data/Spells.lua"))()
local out = {
    "--------------------------------------------------",
    "-- WeintCodex :: Debuffs - alle Nummern je Zauber auf Forever",
    "--------------------------------------------------",
    "-- ERZEUGT von .github/scripts/import_naowh_debuffs.lua aus Naowh Forever 1.2.33",
    "-- (Raid Debuffs, aus dem Client-Build 1.60.1.70790) - nicht von Hand aendern.",
    "-- [Grundzauber] = { Nummern aller Raenge und Fassungen }",
    "--------------------------------------------------",
    "",
    "WeintCodex = WeintCodex or {}",
    "WeintCodex.DebuffIDs = {",
}
for _, e in ipairs(NaowhForever.RaidDebuffSpells) do
    local ids = {}
    for id in pairs(e.ids) do ids[#ids + 1] = id end
    table.sort(ids)
    out[#out + 1] = string.format("    [%d] = { %s }, -- %s", e.spell, table.concat(ids, ", "), e.label)
end
out[#out + 1] = "}"
local f = assert(io.open("data/debuffids_nf.lua", "w")) f:write(table.concat(out, "\n") .. "\n") f:close()
print(#NaowhForever.RaidDebuffSpells)
