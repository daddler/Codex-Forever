-- Tier-0.5-Questreihe (Dungeon-Set 2) aus Naowh Forever (Discovery, seit 1.4.11 veroeffentlicht).
--   lua5.1 .github/scripts/import_naowh_tier05.lua <NaowhForever_Discovery-Ordner>
-- Nur Fakten: Reihenfolge der Schritte, Wahl je Fraktion, "einer von", die
-- Quests je Klasse. Namen, Stufen und Geber liest WeintCodex aus seiner
-- Questdatenbank (data/questdb.lua) und vom Client - keine Texte von Naowh.
-- Schreibt data/tier05.lua.
local dir = assert(arg[1], "Ordner fehlt")
_G.NaowhForever = {}
assert(loadfile(dir .. "/Data/Attunements.lua"))()
local A = _G.NaowhForever.Attunements
local steps
for _, e in ipairs(A.list) do if e.class and e.steps then steps = e.steps end end
assert(steps, "keine Tier-0.5-Schritte")

local function List(t)
    local out = {}
    for _, v in ipairs(t) do out[#out + 1] = tostring(v) end
    return "{ " .. table.concat(out, ", ") .. " }"
end
local function Step(s)
    if type(s) == "string" then return string.format("%q", s) end
    if type(s) == "number" then return tostring(s) end
    if s.A or s.H then return string.format("{ A = %d, H = %d }", s.A, s.H) end
    return "{ any = " .. List(s) .. " }"
end

local out = {
    "--------------------------------------------------",
    "-- WeintCodex :: Tier-0.5-Questreihe (Dungeon-Set 2)",
    "--------------------------------------------------",
    "-- ERZEUGT von .github/scripts/import_naowh_tier05.lua aus Naowh Forever",
    "-- 1.4.11 (Discovery) - nicht von Hand aendern. Herkunft `community`.",
    "--   steps: Schritte in Reihenfolge. Zahl = Quest; { A, H } = je Fraktion;",
    "--          { any = {..} } = einer davon (Bodleys Wahl); Text = Quest der",
    "--          Klasse (class[Fraktion][Klasse][Text] = Nummern, die erste",
    "--          die von Forever).",
    "-- Namen, Stufen, Geber: data/questdb.lua und der Client.",
    "--------------------------------------------------",
    "",
    "WeintCodex = WeintCodex or {}",
    "WeintCodex.Tier05Data = {",
    "    SOURCE = { kind = \"community\", label = \"Von Spielern gesammelt\" },",
    "    steps = {",
}
for _, s in ipairs(steps) do out[#out + 1] = "        " .. Step(s) .. "," end
out[#out + 1] = "    },"
out[#out + 1] = "    class = {"
for _, side in ipairs({ "A", "H" }) do
    out[#out + 1] = "        " .. side .. " = {"
    local classes = {}
    for c in pairs(A.classQuests[side]) do classes[#classes + 1] = c end
    table.sort(classes)
    for _, c in ipairs(classes) do
        local q = A.classQuests[side][c]
        local keys = {}
        for k in pairs(q) do keys[#keys + 1] = k end
        table.sort(keys)
        local parts = {}
        for _, k in ipairs(keys) do parts[#parts + 1] = k .. " = " .. List(q[k]) end
        out[#out + 1] = "            " .. c .. " = { " .. table.concat(parts, ", ") .. " },"
    end
    out[#out + 1] = "        },"
end
out[#out + 1] = "    },"
out[#out + 1] = "}"
local f = assert(io.open("data/tier05.lua", "w"))
f:write(table.concat(out, "\n") .. "\n")
f:close()
print(#steps .. " Schritte -> data/tier05.lua")
