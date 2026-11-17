-- Questgebiete aus Naowh Forever "JourneysData" (QuestSpots.lua, nur Daten):
-- je Quest die Lager ihrer Ziele (Karte, x, y). Naowh traegt keine Lizenz
-- ("All Rights Reserved") - uebernommen sind nur Lagen, kein Code, keine
-- Texte, keine Wegenetze. Die Abgabe kennt der Codex selbst (questdb).
--   lua5.1 .github/scripts/import_naowh_journeys.lua <NaowhForever_JourneysData-Ordner>
-- Schreibt data/questspots_nf.lua.
local dir = assert(arg[1], "Ordner fehlt")
local f = assert(loadfile(dir .. "/QuestSpots.lua"))
local ns = {}
setfenv(f, { _G = { NaowhForever = ns } })
f()
local spots = assert(ns.JourneyQuestSpots, "keine Questgebiete")
local ids = {}
for id in pairs(spots) do ids[#ids + 1] = id end
table.sort(ids)
local out = {
    "--------------------------------------------------",
    "-- WeintCodex :: Questgebiete (Ziele ohne Lage im Questbestand)",
    "--------------------------------------------------",
    "-- ERZEUGT von .github/scripts/import_naowh_journeys.lua - nicht von Hand.",
    "-- Je Quest die Lager ihrer Ziele als \"Karte,x,y;...\" (x/y in Prozent).",
    "-- Herkunft: von Spielern gesammelt (`community`). Gelesen von",
    "-- ui/questhelper.lua - nur wenn der Questbestand fuer die Quest keine",
    "-- Ziellage kennt.",
    "--------------------------------------------------",
    "WeintCodex = WeintCodex or {}",
    "WeintCodex.QuestSpotsNF = {",
}
local n = 0
for _, id in ipairs(ids) do
    local camps = spots[id][2]
    if type(camps) == "table" and #camps > 0 then
        local parts = {}
        for _, c in ipairs(camps) do
            if type(c[1]) == "number" and type(c[2]) == "number" and type(c[3]) == "number" then
                parts[#parts + 1] = string.format("%d,%.1f,%.1f", c[1], c[2], c[3])
            end
        end
        if #parts > 0 then
            out[#out + 1] = string.format('    [%d] = "%s",', id, table.concat(parts, ";"))
            n = n + 1
        end
    end
end
out[#out + 1] = "}"
local h = assert(io.open("data/questspots_nf.lua", "w"))
h:write(table.concat(out, "\n"), "\n")
h:close()
print(n .. " Quests mit Zielgebieten")
