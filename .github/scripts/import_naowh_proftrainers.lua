-- Welcher Berufslehrer bis zu welchem Rang lehrt - aus Naowh Forever
-- "Professions" (RecipeData: je Rang die Lehrer `t`, laut Naowh von Hand aus
-- Wowhead Forever). Nur Fakten (Lehrer, Lage, Rang), kein Code.
--   lua5.1 .github/scripts/import_naowh_proftrainers.lua <NaowhForever_Professions-Ordner>
-- Schreibt data/proftrainers_nf.lua.
local dir = assert(arg[1], "Ordner fehlt")
_G.NaowhForever = {}
assert(loadfile(dir .. "/Data/RecipeData.lua"))()
WeintCodex = {}
assert(loadfile("data/professions.lua"))()
local P = WeintCodex.ProfessionData
local byLine = {}
for _, p in ipairs(P.PROFS) do byLine[p.line] = p.key end
local FAC = { A = '"Alliance"', H = '"Horde"' }

local out = {
    "--------------------------------------------------",
    "-- WeintCodex :: Berufslehrer und ihre Raenge (Forever)",
    "--------------------------------------------------",
    "-- ERZEUGT von .github/scripts/import_naowh_proftrainers.lua aus Naowh Forever",
    "-- 1.2.33 (Professions, je Rang die Lehrer, die ihn lehren - laut Naowh von Hand",
    "-- aus Wowhead Forever) - nicht von Hand aendern. Herkunft `community`.",
    "-- { npc, Name, Karte, x, y, Fraktion, Rang 1-4 oder nil }",
    "--   Rang: bis wohin er lehrt (1 bis 75, 2 bis 150, 3 bis 225, 4 bis 300).",
    "--   nil: ueber Rang `known` hinaus unbekannt - die Quelle nennt fuer den",
    "--   naechsten Rang keine Lehrer; dann gilt die Angabe aus Classic, wenn es",
    "--   den Lehrer dort gibt (`classic = true`), sonst kein Rang.",
    "--------------------------------------------------",
    "",
    "local P = WeintCodex.ProfessionData",
    "P.NF_TRAINER_RANK = {",
}
local lines = {}
for line in pairs(NaowhForever.RecipeData) do lines[#lines + 1] = line end
table.sort(lines)
local stats = {}
for _, line in ipairs(lines) do
    local d = NaowhForever.RecipeData[line]
    local key = byLine[line]
    if key and d.trainers and #d.trainers > 0 then
        local classic = {}
        for _, t in ipairs(P.TRAINERS[key] or {}) do classic[t[1]] = t[7] end
        out[#out + 1] = string.format("    [%q] = {", key)
        for i, t in ipairs(d.trainers) do
            local rank, sure, fromClassic = 1, true, false
            for ri, r in ipairs(d.ranks or {}) do
                if r.t then
                    local hit = false
                    for _, x in ipairs(r.t) do if x == i then hit = true end end
                    if hit then rank = ri + 1 else break end
                elseif r.item or r.quest then
                    break   -- Buch oder Quest: kein Lehrer lehrt diesen Rang
                else
                    -- Rang beim Lehrer, aber die Quelle nennt keine Lehrer.
                    local c = classic[t[1]]
                    if c and c >= ri + 1 then rank, fromClassic = ri + 1, true
                    elseif c then break
                    else sure = false break end
                end
            end
            local fac = FAC[t[3]] or "nil"
            out[#out + 1] = string.format("        { %d, %q, %d, %s, %s, %s, %s%s },", t[1], t[2], t[4],
                tostring(t[5]), tostring(t[6]), fac, sure and tostring(rank) or "nil",
                (not sure and (", known = " .. rank) or "") .. (fromClassic and ", classic = true" or ""))
            stats[key] = (stats[key] or 0) + 1
        end
        out[#out + 1] = "    },"
    end
end
out[#out + 1] = "}"
local f = assert(io.open("data/proftrainers_nf.lua", "w")) f:write(table.concat(out, "\n") .. "\n") f:close()
for k, n in pairs(stats) do io.write(k, "=", n, " ") end print()
