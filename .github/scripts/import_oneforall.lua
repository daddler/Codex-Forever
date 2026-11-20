-- WeintCodex :: Abgleich mit OneForAll (1.0.8.0)
--
--   lua5.1 .github/scripts/import_oneforall.lua <OneForAll-Ordner> <Codex-Ordner>
--
-- OneForAll 6.2.12 ist GPL-3.0 - uebernommen werden nur DATEN (Nummern,
-- Stufen, Mengen, Gebiete), kein Code. Dort stammen sie aus dem Forever-Client
-- (Build 1.60.1, wago.tools), taeglich gegen wowtbc.gg geprueft, und aus
-- QuestieDB Forever (Stand 18.11.2026).
--
-- Schreibt:
--   data/professions_ofa.lua  P.OFA_ADD[Beruf]  Rezepte, die der Bestand nicht kennt (Zeilen wie P.RAW)
--                             P.OFA_FIX[Zauber] "Lernen Gelb Gruen Grau" - nur wo OneForAll anders sagt
--                             P.OFA_REAG[Zauber] "Nummer:Anzahl,..." - nur wo anders
--   data/zonegather.lua       WeintCodex.ZoneGather[Karte] = { herbs = {...}, ore = {...}, fish = {...} }
--                             aus dem Feldbuch (data/fieldjournal.lua) und den Fundorten
--                             in OneForAll (Data/ReagentSources.lua, o/oz und f).

local OFA, CDX = arg[1], arg[2]
assert(OFA and CDX, "Aufruf: import_oneforall.lua <OneForAll> <Codex>")

local FLT = {}
for _, f in ipairs({ "Alchemy", "Blacksmithing", "Cooking", "Enchanting", "Engineering", "FirstAid", "Leatherworking", "Tailoring" }) do
    assert(loadfile(OFA .. "/Data/Professions/" .. f .. ".lua"))("OneForAll", FLT)
end
assert(loadfile(OFA .. "/Data/ReagentSources.lua"))("OneForAll", FLT)

WeintCodex = {}
for _, f in ipairs({ "professions.lua", "professions_su.lua", "professions_nf.lua", "fieldjournal.lua", "zoneinfo.lua" }) do
    dofile(CDX .. "/data/" .. f)
end
local P = WeintCodex.ProfessionData
local MAP = { Alchemy = "alchemy", Blacksmithing = "blacksmithing", Cooking = "cooking", Enchanting = "enchanting",
    Engineering = "engineering", ["First Aid"] = "first-aid", Leatherworking = "leatherworking", Tailoring = "tailoring" }

local function ReagStr(list)
    local parts = {}
    for _, x in ipairs(list or {}) do parts[#parts + 1] = x[1] .. ":" .. x[2] end
    return table.concat(parts, ",")
end
local function Sorted(s)
    local t = {}
    for p in s:gmatch("[^,]+") do t[#t + 1] = p end
    table.sort(t)
    return table.concat(t, ",")
end

--------------------------------------------------
-- Rezepte
--------------------------------------------------
local add, fix, reag = {}, {}, {}
local stats = { add = 0, fix = 0, reag = 0 }
local profNames = {}
for name in pairs(FLT.PROFESSION_RECIPES) do profNames[#profNames + 1] = name end
table.sort(profNames)
for _, ofaName in ipairs(profNames) do
    local key = assert(MAP[ofaName], ofaName)
    local raw = (P.RAW[key] or "") .. "\n" .. ((P.SU_RAW or {})[key] or "") .. "\n" .. ((P.NF_ADD or {})[key] or "")
    local have = {}
    for line in raw:gmatch("[^\n]+") do
        local head, rg = line:match("^([^|]*)|([^|]*)|")
        if head then
            local f = {}
            for w in head:gmatch("%S+") do f[#f + 1] = w end
            local sp = tonumber(f[1])
            local l, y, g, gr = tonumber(f[3]), tonumber(f[4]), tonumber(f[5]), tonumber(f[6])
            local su = P.SU_THRESH and P.SU_THRESH[sp]
            if su then
                local a, b, c, d = su:match("^(%S+) (%d+) (%d+) (%d+)$")
                l, y, g, gr = tonumber(a), tonumber(b), tonumber(c), tonumber(d)
            end
            have[sp] = { l = l, y = y, g = g, gr = gr, reag = rg }
        end
    end
    for _, r in ipairs(FLT.PROFESSION_RECIPES[ofaName]) do
        local h = have[r.s]
        -- Stufen nur, wenn OneForAll alle drei Farben kennt (0 = unbekannt dort).
        local colors = r.y and r.g and r.gr and r.y > 0
        if not h then
            if colors and r.i and r.n then
                add[key] = add[key] or {}
                add[key][#add[key] + 1] = string.format("%d %d %s %d %d %d s %s %s -|%s|%s", r.s, r.i,
                    r.req and tostring(r.req) or "-", r.y, r.g, r.gr, r.start and "t" or "-",
                    r.ri and tostring(r.ri) or "-", ReagStr(r.r), r.n)
                stats.add = stats.add + 1
            end
        else
            local l = r.req or h.l
            local y, g, gr = h.y, h.g, h.gr
            if colors then y, g, gr = r.y, r.g, r.gr end
            -- Ohne Farben auf keiner Seite: keine Zeile (nie "0 0 0").
            if y and g and gr and (l ~= h.l or y ~= h.y or g ~= h.g or gr ~= h.gr) then
                fix[#fix + 1] = { r.s, string.format("%s %d %d %d", l and tostring(l) or "-", y or 0, g or 0, gr or 0) }
                stats.fix = stats.fix + 1
            end
            local mine, theirs = Sorted(h.reag or ""), Sorted(ReagStr(r.r))
            if theirs ~= "" and mine ~= theirs then
                reag[#reag + 1] = { r.s, ReagStr(r.r) }
                stats.reag = stats.reag + 1
            end
        end
    end
end
table.sort(fix, function(a, b) return a[1] < b[1] end)
table.sort(reag, function(a, b) return a[1] < b[1] end)

local out = {}
local function W(s) out[#out + 1] = s end
W("--------------------------------------------------")
W("-- WeintCodex :: Berufe - Abgleich mit OneForAll (1.0.8.0)")
W("--------------------------------------------------")
W("-- ERZEUGT von .github/scripts/import_oneforall.lua - nicht von Hand aendern.")
W("-- Nur Daten aus OneForAll 6.2.12 (GPL-3.0): Forever-Client Build 1.60.1,")
W("-- taeglich gegen wowtbc.gg geprueft. Art `community`. Gelesen von")
W("-- modules/professions.lua nach SU_THRESH und NF_FIX - der neueste Stand gilt.")
W("-- OFA_FIX[Zauber] \"Lernen Gelb Gruen Grau\" (\"-\" = Lernstufe unbekannt)")
W("--------------------------------------------------")
W("")
W("WeintCodex = WeintCodex or {}")
W("WeintCodex.ProfessionData = WeintCodex.ProfessionData or {}")
W("local P = WeintCodex.ProfessionData")
W("")
W("P.OFA_SOURCE = { kind = \"community\", label = \"Lernstufen und Farben: Forever-Client, im Spiel geprüft\" }")
W("")
W("P.OFA_ADD = {")
local keys = {}
for k in pairs(add) do keys[#keys + 1] = k end
table.sort(keys)
for _, k in ipairs(keys) do W(string.format("    [%q] = [[\n%s\n]],", k, table.concat(add[k], "\n"))) end
W("}")
W("")
W("P.OFA_FIX = {")
for _, e in ipairs(fix) do W(string.format("    [%d] = %q,", e[1], e[2])) end
W("}")
W("")
W("P.OFA_REAG = {")
for _, e in ipairs(reag) do W(string.format("    [%d] = %q,", e[1], e[2])) end
W("}")
local fh = assert(io.open(CDX .. "/data/professions_ofa.lua", "w"))
fh:write(table.concat(out, "\n"), "\n")
fh:close()
print(string.format("Rezepte: %d neu, %d Stufen, %d Reagenzien", stats.add, stats.fix, stats.reag))

--------------------------------------------------
-- Gebiete: Kraeuter, Erz, Fische
--------------------------------------------------
local HERB_NODES = {}
for _, n in ipairs({ "Peacebloom", "Silverleaf", "Earthroot", "Mageroyal", "Briarthorn", "Bruiseweed", "Stranglekelp",
    "Wild Steelbloom", "Grave Moss", "Kingsblood", "Liferoot", "Fadeleaf", "Goldthorn", "Khadgar's Whisker", "Wintersbite",
    "Firebloom", "Purple Lotus", "Arthas' Tears", "Sungrass", "Blindweed", "Ghost Mushroom", "Gromsblood", "Golden Sansam",
    "Dreamfoil", "Mountain Silversage", "Plaguebloom", "Icecap", "Black Lotus", "Swiftthistle" }) do HERB_NODES[n] = true end
local ORE = {}
for _, id in ipairs({ 2770, 2771, 2775, 2772, 2776, 3858, 7911, 10620, 11370, 3340, 249391 }) do ORE[id] = true end

local zones = {}
local function Put(map, kind, item, share)
    if type(map) ~= "number" then return end
    local z = zones[map] or { herbs = {}, ore = {}, fish = {}, seen = {} }
    zones[map] = z
    local k = kind .. ":" .. item
    if z.seen[k] then
        if share and (z.seen[k].share or 0) < share then z.seen[k].share = share end
        return
    end
    local e = { item = item, share = share }
    z.seen[k] = e
    z[kind][#z[kind] + 1] = e
end
-- Feldbuch (Forever, gesammelt): Fische mit Anteil, Kraeuter
local FJ = WeintCodex.FieldJournalData
for _, f in ipairs(FJ.fish or {}) do
    local zs = f.zones or {}
    for i = 1, #zs, 2 do Put(zs[i], "fish", f.item, zs[i + 1]) end
end
for _, h in ipairs(FJ.herbs or {}) do
    for _, m in ipairs(h.zones or {}) do Put(m, "herbs", h.item) end
end
-- OneForAll: Fundorte (QuestieDB Forever), Fische (f: Gebietsnamen - nicht verwendet, keine Kartennummern)
for item, s in pairs(FLT.REAGENT_SOURCES) do
    if s.o and s.oz then
        local kind = (s.o:find("Vein") or s.o:find("Deposit")) and (ORE[item] and "ore" or nil)
            or (HERB_NODES[s.o] and "herbs" or nil)
        if kind then
            for _, e in ipairs(s.oz) do
                if not e[5] then Put(e[1], kind, item) end   -- e[5]: in einer Instanz
            end
        end
    end
end

out = {}
W("--------------------------------------------------")
W("-- WeintCodex :: Im Spiel gemeldete Vorkommen je Gebiet (1.0.8.0)")
W("--------------------------------------------------")
W("-- ERZEUGT von .github/scripts/import_oneforall.lua - nicht von Hand aendern.")
W("-- Herkunft (nur fuer Betreuer): Feldbuch (Naowh Forever 1.2.33, Fische mit")
W("-- Anteil am Fang) und Fundorte aus OneForAll 6.2.12 (QuestieDB Forever,")
W("-- 18.11.2026; GPL-3.0, nur Daten). Beide nennen je Sorte nur die ergiebigsten")
W("-- Gebiete - die Liste ist ein Zusatz zu data/zoneinfo.lua, kein Ersatz.")
W("-- Art `community`. Namen der Gegenstaende nennt der Client.")
W("-- [Karte] = { herbs = { Gegenstand, ... }, ore = { ... }, fish = { Gegenstand, Anteil %, ... } }")
W("--------------------------------------------------")
W("")
W("WeintCodex = WeintCodex or {}")
W("WeintCodex.ZoneGather = {")
local maps = {}
for m in pairs(zones) do maps[#maps + 1] = m end
table.sort(maps)
local nz = 0
for _, m in ipairs(maps) do
    local z = zones[m]
    local function Ids(list, withShare)
        table.sort(list, function(a, b)
            if (a.share or 0) ~= (b.share or 0) then return (a.share or 0) > (b.share or 0) end
            return a.item < b.item
        end)
        local t = {}
        for _, e in ipairs(list) do
            t[#t + 1] = tostring(e.item)
            if withShare then t[#t + 1] = string.format("%g", e.share or 0) end
        end
        return table.concat(t, ", ")
    end
    local parts = {}
    if #z.herbs > 0 then parts[#parts + 1] = "herbs = { " .. Ids(z.herbs) .. " }" end
    if #z.ore > 0 then parts[#parts + 1] = "ore = { " .. Ids(z.ore) .. " }" end
    if #z.fish > 0 then parts[#parts + 1] = "fish = { " .. Ids(z.fish, true) .. " }" end
    if #parts > 0 then
        W(string.format("    [%d] = { %s },", m, table.concat(parts, ", ")))
        nz = nz + 1
    end
end
W("}")
fh = assert(io.open(CDX .. "/data/zonegather.lua", "w"))
fh:write(table.concat(out, "\n"), "\n")
fh:close()
print(string.format("Gebiete mit Meldungen: %d", nz))
