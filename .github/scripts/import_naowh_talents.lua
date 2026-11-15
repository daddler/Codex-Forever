-- Talentbaeume aus Naowh Forever "Training" (nur Daten aus dem Client-Build).
--   lua5.1 .github/scripts/import_naowh_talents.lua <NaowhForever_Training-Ordner>
-- Schreibt data/talenttrees.lua. Naowhs eigene Builds werden NICHT uebernommen.
local dir = assert(arg[1], "Ordner fehlt")
_G.NaowhForever = {}
assert(loadfile(dir .. "/Data/TrainingBuilds.lua"))()
local CLASSES = { [1] = "WARRIOR", [2] = "PALADIN", [3] = "HUNTER", [4] = "ROGUE", [5] = "PRIEST",
    [7] = "SHAMAN", [8] = "MAGE", [9] = "WARLOCK", [11] = "DRUID" }
local out = {
    "--------------------------------------------------",
    "-- WeintCodex :: Talentbaeume (fuer den Talentplaner)",
    "--------------------------------------------------",
    "-- ERZEUGT von .github/scripts/import_naowh_talents.lua aus Naowh Forever",
    "-- 1.2.33 (Training, Talentbaeume aus dem Client-Build 1.60.1.70790) - nicht",
    "-- von Hand aendern. Nur der Aufbau der Baeume, keine Builds. `community`.",
    "-- [Klasse] = { [Talent] = { Zauber, Raenge, Reihe, Baum, Spalte, Vorbedingung } }",
    "--------------------------------------------------",
    "",
    "WeintCodex = WeintCodex or {}",
    "WeintCodex.TalentTrees = {",
}
local ids = {}
for k in pairs(CLASSES) do ids[#ids + 1] = k end
table.sort(ids)
for _, ci in ipairs(ids) do
    local t = NaowhForever.TrainingBuilds[ci]
    if t then
        out[#out + 1] = "    " .. CLASSES[ci] .. " = {"
        local nodes = {}
        for id in pairs(t.talents) do nodes[#nodes + 1] = id end
        table.sort(nodes)
        for _, id in ipairs(nodes) do
            local e = t.talents[id]
            out[#out + 1] = string.format("        [%d] = { %d, %d, %d, %d, %d%s },", id, e[1], e[2], e[3], e[4], e[5], e[6] and (", " .. e[6]) or "")
        end
        out[#out + 1] = "    },"
    end
end
out[#out + 1] = "}"
local f = assert(io.open("data/talenttrees.lua", "w")) f:write(table.concat(out, "\n") .. "\n") f:close()
print("ok")
