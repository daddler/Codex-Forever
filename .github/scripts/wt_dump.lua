-- Liest die Forever-Klassendaten von "What's Training?" (Classes/Camelot,
-- MIT) in einer leeren Umgebung und gibt je Klasse die Zauber als Zeilen
-- aus: KLASSE<TAB>stufe<TAB>id<TAB>kosten<TAB>felder. Nur Daten.
--   lua5.1 .github/scripts/wt_dump.lua <WhatsTraining-Ordner>
local dir = assert(arg[1], "Ordner fehlt") .. "/Classes/Camelot/"
local classes = {}
local wt = {}
function wt.forClass(c) classes[c] = classes[c] or {} return classes[c] end
local function run(name)
    local f = loadfile(dir .. name)
    if not f then return end
    setfenv(f, {})
    pcall(f, "WhatsTraining", wt)
end
for _, n in ipairs({ "Druid", "Hunter", "Mage", "Paladin", "Priest", "Rogue", "Shaman", "Warlock", "Warrior", "HunterPets" }) do
    run(n .. ".lua")
end
local function list(t)
    if type(t) ~= "table" then return "" end
    local o = {}
    for _, v in ipairs(t) do o[#o + 1] = tostring(v) end
    return table.concat(o, ",")
end
local cls = {}
for c in pairs(classes) do cls[#cls + 1] = c end
table.sort(cls)
for _, c in ipairs(cls) do
    local t = classes[c]
    for _, key in ipairs({ "spellsByLevel", "petSpellsByLevel" }) do
        local byL = t[key]
        if type(byL) == "table" then
            for lvl, sp in pairs(byL) do
                for _, s in ipairs(sp) do
                    io.write(c, "\t", lvl, "\t", s.id, "\t", s.cost or "", "\t",
                        list(s.requiredIds), "\t", tostring(s.requiredTalentId or ""), "\t",
                        tostring(s.race or s.races and list(s.races) or ""), "\t", tostring(s.faction or ""), "\t",
                        key == "petSpellsByLevel" and "pet" or "", "\n")
                end
            end
        end
    end
end
