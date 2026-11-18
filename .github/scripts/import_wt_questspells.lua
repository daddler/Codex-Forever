-- Welche Klassenquest welchen Zauber lehrt - aus "What's Training?"
-- (Classes/Camelot/QuestSpells.lua, MIT, Copyright (c) 2019). Nur Daten.
--   lua5.1 .github/scripts/import_wt_questspells.lua <WhatsTraining-Ordner>
-- Schreibt data/questspell_map.lua: [Quest] = gelernter Zauber.
local dir = assert(arg[1], "Ordner fehlt")
local f = assert(loadfile(dir .. "/Classes/Camelot/QuestSpells.lua"))
local wt = {}
setfenv(f, {})
f("WhatsTraining", wt)
local src = wt.QuestSpells
if not src then
    -- die Datei legt die Tabelle lokal an und haengt sie an wt
    for k, v in pairs(wt) do if type(v) == "table" and v.WARLOCK then src = v end end
end
assert(src, "QuestSpells nicht gefunden")
local map, n = {}, 0
for _, spells in pairs(src) do
    for spell, list in pairs(spells) do
        for _, e in ipairs(list) do
            for _, q in ipairs(e.quests or {}) do
                if not map[q] then map[q] = spell n = n + 1 end
            end
        end
    end
end
local ids = {}
for q in pairs(map) do ids[#ids + 1] = q end
table.sort(ids)
local out = {
    "--------------------------------------------------",
    "-- WeintCodex :: Welche Klassenquest welchen Zauber lehrt",
    "--------------------------------------------------",
    "-- ERZEUGT von .github/scripts/import_wt_questspells.lua aus What's Training?",
    "-- (Classes/Camelot/QuestSpells.lua; MIT License, Copyright (c) 2019",
    "-- What's Training?, Sveng - siehe data/trainer.lua). Nur Daten.",
    "-- [Quest] = Zauber, den sie lehrt. Gelesen von modules/classquests.lua:",
    "-- kennt der Charakter den Zauber schon, ist jede Quest dafuer erledigt.",
    "--------------------------------------------------",
    "WeintCodex = WeintCodex or {}",
    "WeintCodex.QuestSpellMap = {",
}
for _, q in ipairs(ids) do out[#out + 1] = string.format("    [%d] = %d,", q, map[q]) end
out[#out + 1] = "}"
local h = assert(io.open("data/questspell_map.lua", "w"))
h:write(table.concat(out, "\n"), "\n")
h:close()
print(n .. " Quests")
