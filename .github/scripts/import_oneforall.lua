-- WeintCodex :: Abgleich mit OneForAll (1.0.8.0)
--
--   lua5.1 .github/scripts/import_oneforall.lua <OneForAll-Ordner> <Codex-Ordner>
--
-- OneForAll 6.2.13 ist GPL-3.0 - uebernommen werden nur DATEN (Nummern,
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
W("-- Nur Daten aus OneForAll 6.2.13 (GPL-3.0): Forever-Client Build 1.60.1,")
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
W("-- Anteil am Fang) und Fundorte aus OneForAll 6.2.13 (QuestieDB Forever,")
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

--------------------------------------------------
-- Zaehmbare Tiere (Wildtierkunde)
--------------------------------------------------
-- OneForAll: Familien und Tiere nach wow-petopia.com/forever (gelesen
-- 07.11.2026), Lagen aus QuestieDB Forever. Neue Tiere und andere Familie
-- als im Bestand (data/beasts.lua) - geschrieben nach data/beasts_ofa.lua,
-- das beim Laden in WeintCodex.BeastData eintraegt.
local FLTP = {}
assert(loadfile(OFA .. "/Data/HunterPets.lua"))("OneForAll", FLTP)
assert(loadfile(OFA .. "/Data/HunterPetTames.lua"))("OneForAll", FLTP)
dofile(CDX .. "/data/beasts.lua")
local B = WeintCodex.BeastData
local famIdx, zoneIdx = {}, {}
for i, f in ipairs(B.F) do famIdx[f[1]] = i end
for i, z in ipairs(B.Z) do
    if type(z[2]) == "number" then zoneIdx[z[2]] = zoneIdx[z[2]] or i end
    zoneIdx[z[1]] = zoneIdx[z[1]] or i   -- gleicher Name in beiden Sprachen (Desolace)
end
-- Gebiete ohne Karte (Dungeons) ueber den englischen Namen der Instanz.
local DUNGEON_ZONE = { ["Ruins of Lordaeron"] = "Ruinen von Lordaeron" }
for i, z in ipairs(B.Z) do
    for en, de in pairs(DUNGEON_ZONE) do if z[1] == de then zoneIdx[en] = i end end
end
local tames, fam = {}, {}
for _, f in ipairs(FLTP.PET_FAMILIES) do for _, t in ipairs(f.tames or {}) do tames[t.npcID] = t fam[t.npcID] = f.name end end
for fname, list in pairs(FLTP.PET_TAMES_EXTRA or {}) do for _, t in ipairs(list) do tames[t.npcID] = t fam[t.npcID] = fname end end
local addB, addS, fixF = {}, {}, {}
local ids = {}
for id in pairs(tames) do ids[#ids + 1] = id end
table.sort(ids)
for _, id in ipairs(ids) do
    local t, fi = tames[id], famIdx[fam[id]]
    if fi then
        if not B.b[id] then
            local zi = (t.mapID and zoneIdx[t.mapID]) or zoneIdx[t.zone]
            local lvl, tag = tostring(t.level or ""):match("^([%d%-]*)%s*(%a*)$")
            local marks = (tag == "Elite" and "e" or tag == "Rare" and "r" or "") .. (id > 200000 and "n" or "")
            addB[#addB + 1] = string.format("        [%d] = %q,", id,
                table.concat({ fi, t.name, lvl or "", marks, "", zi and tostring(zi) or "", "" }, "\t"))
            if zi and t.x and t.y then
                addS[#addS + 1] = string.format("        [%d] = %q,", id,
                    string.format("%d:%03d%03d", zi, math.floor(t.x * 10 + 0.5), math.floor(t.y * 10 + 0.5)))
            end
        else
            local mine = tonumber(B.b[id]:match("^(%d+)"))
            if mine and mine ~= fi then fixF[#fixF + 1] = string.format("        [%d] = %d,   -- %s statt %s", id, fi, fam[id], B.F[mine][1]) end
        end
    end
end
out = {}
W("--------------------------------------------------")
W("-- WeintCodex :: Wildtierkunde - Abgleich mit OneForAll (1.0.8.0)")
W("--------------------------------------------------")
W("-- ERZEUGT von .github/scripts/import_oneforall.lua - nicht von Hand aendern.")
W("-- Herkunft (nur fuer Betreuer): OneForAll 6.2.13 (GPL-3.0, nur Daten) -")
W("-- Familien nach wow-petopia.com/forever (07.11.2026), Lagen QuestieDB Forever.")
W("-- Traegt beim Laden in WeintCodex.BeastData ein: neue Tiere (b, s) und")
W("-- die Familie, wo die neuere Quelle anders sagt. Art `community`.")
W("--------------------------------------------------")
W("")
W("local B = WeintCodex and WeintCodex.BeastData")
W("if not B then return end")
W("local add = {")
for _, l in ipairs(addB) do W(l) end
W("}")
W("local spots = {")
for _, l in ipairs(addS) do W(l) end
W("}")
W("local family = {")
for _, l in ipairs(fixF) do W(l) end
W("}")
W("for id, v in pairs(add) do if not B.b[id] then B.b[id] = v end end")
W("for id, v in pairs(spots) do if not B.s[id] then B.s[id] = v end end")
W("for id, f in pairs(family) do")
W("    local v = B.b[id]")
W("    if v then B.b[id] = v:gsub(\"^%d+\", tostring(f), 1) end")
W("end")
W("B.OFA = { added = add, family = family }")
fh = assert(io.open(CDX .. "/data/beasts_ofa.lua", "w"))
fh:write(table.concat(out, "\n"), "\n")
fh:close()
print(string.format("Tiere: %d neu, %d mit anderer Familie", #addB, #fixF))

--------------------------------------------------
-- Dungeons: Dropchancen und Quests
--------------------------------------------------
-- Dropchancen: in Forever gemessen (DUNGEON_DROP_FOREVER, Wowhead Forever,
-- Bosse mit 100+ Kills) gelten vor dem Bestand; Classic-Chancen fuellen nur,
-- wo der Bestand keine Zahl hat. Nur fuer Gegenstaende, die der Bestand im
-- Dungeon fuehrt - die Liste der Beute bleibt, wie sie ist.
-- Quests: nur die, die dem Dungeon fehlen (Nummer, Name, Stufen, Seite,
-- Klasse) - keine Texte. Was nur der Bestand kennt, bleibt.
local FLTD = { DUNGEON_REGISTRY = {} }
assert(loadfile(OFA .. "/Data/DungeonDropChance.lua"))("OneForAll", FLTD)
for f in io.popen('ls "' .. OFA .. '/Data/Dungeons"'):lines() do
    assert(loadfile(OFA .. "/Data/Dungeons/" .. f))("OneForAll", FLTD)
end
WeintCodex.Sources = WeintCodex.Sources or setmetatable({}, { __index = function() return function() return true end end })
for _, f in ipairs({ "sources.lua", "dungeons.lua", "dungeons_classic.lua", "dungeon_journal.lua", "dungeon_journal_fg.lua", "dungeon_journal_nf.lua" }) do
    dofile(CDX .. "/data/" .. f)
end
local J = WeintCodex.DungeonJournal
if J.EnsureAllClassic then J.EnsureAllClassic() end
local byName = {}
for _, d in ipairs(WeintCodex_Dungeons or {}) do byName[d.name] = d.id end
for _, d in ipairs(WeintCodex_ClassicDungeons or {}) do byName[d.name] = d.id end
local ALIAS = { ["Alcaz Prison"] = "alcaz_island_prison", ["Dire Maul: East"] = "dire_maul", ["Dire Maul: North"] = "dire_maul",
    ["Dire Maul: West"] = "dire_maul", ["Scarlet Monastery: Armory"] = "scarlet_monastery",
    ["Scarlet Monastery: Cathedral"] = "scarlet_monastery", ["Scarlet Monastery: Graveyard"] = "scarlet_monastery",
    ["Scarlet Monastery: Library"] = "scarlet_monastery", ["Drowned City"] = "drowned_city",
    ["Excavation Site: Wetlands"] = "excavation_site", ["The Temple of Atal'Hakkar"] = "sunken_temple" }
local function DId(n) return byName[n] or ALIAS[n] end
-- Was der Bestand je Dungeon fuehrt, mit Chance (nil = ohne Zahl).
local listed = {}
for did, d in pairs(J.DATA or {}) do
    listed[did] = listed[did] or {}
    for _, list in pairs(d.loot or {}) do
        for _, e in ipairs(list) do if type(e) == "table" and e[1] then listed[did][e[1]] = e.chance or false end end
    end
    for _, g in ipairs(d.others or {}) do
        for _, e in ipairs(g.items or {}) do if type(e) == "table" and e[1] then listed[did][e[1]] = e.chance or false end end
    end
end
local forever = {}
for _, e in ipairs(FLTD.DUNGEON_DROP_FOREVER or {}) do forever[e[3]] = true end
local drops, dstat = {}, { set = 0, fill = 0 }
for dname, bosses in pairs(FLTD.DUNGEON_DROP_CHANCE) do
    local did = DId(dname)
    if did and listed[did] then
        for _, items in pairs(bosses) do
            for item, ch in pairs(items) do
                local mine = listed[did][item]
                -- Ganze Prozent, mindestens 1 (der Bestand kennt keine Bruchteile).
                ch = type(ch) == "number" and math.floor(ch + 0.5) or nil
                if mine ~= nil and ch and ch >= 1 and ch <= 100 then
                    if forever[item] and mine ~= ch then
                        drops[did] = drops[did] or {}
                        drops[did][item] = { ch, true }
                        dstat.set = dstat.set + 1
                    elseif mine == false then
                        drops[did] = drops[did] or {}
                        drops[did][item] = { ch, forever[item] or false }
                        dstat.fill = dstat.fill + 1
                    end
                end
            end
        end
    end
end
local have = {}
for did, d in pairs(J.DATA or {}) do
    have[did] = {}
    for _, q in ipairs(d.quests or {}) do have[did][q.id] = true end
end
local quests, qn = {}, 0
local dnames = {}
for n in pairs(FLTD.DUNGEON_REGISTRY) do dnames[#dnames + 1] = n end
table.sort(dnames)
for _, dname in ipairs(dnames) do
    local did = DId(dname)
    if did then
        for _, q in ipairs(FLTD.DUNGEON_REGISTRY[dname].quests or {}) do
            if type(q.id) == "number" and not (have[did] and have[did][q.id]) then
                have[did] = have[did] or {}
                have[did][q.id] = true
                local fac = q.faction == "Alliance" and "alliance" or q.faction == "Horde" and "horde" or "both"
                quests[did] = quests[did] or {}
                quests[did][#quests[did] + 1] = string.format("        { id = %d, name = %q, level = %s, requires = %s, faction = %q%s },",
                    q.id, q.name, tostring(q.level or "nil"), tostring(q.requires or "nil"), fac,
                    q.class and string.format(", classes = { %q }", q.class) or "")
                qn = qn + 1
            end
        end
    end
end
out = {}
W("--------------------------------------------------")
W("-- WeintCodex :: Dungeon-Journal, Abgleich mit OneForAll (1.0.8.0)")
W("--------------------------------------------------")
W("-- ERZEUGT von .github/scripts/import_oneforall.lua - nicht von Hand aendern.")
W("-- Herkunft (nur fuer Betreuer): OneForAll 6.2.13 (GPL-3.0, nur Daten) -")
W("-- Dropchancen von Wowhead Forever (Bosse mit 100+ Kills, Stand 08.-13.11.2026),")
W("-- Classic-Chancen von foreverchanges.pro; Quests aus QuestieDB Forever.")
W("--   OFA_DROP[Dungeon][Gegenstand] = { Chance %, in Forever gemessen }")
W("--     gemessen: gilt vor dem Bestand; sonst nur, wo der Bestand keine Zahl hat.")
W("--   OFA_QUESTS[Dungeon]  Quests, die dem Dungeon fehlten (keine Texte).")
W("-- Art `community`.")
W("--------------------------------------------------")
W("")
W("local J = WeintCodex.DungeonJournal")
W("")
W("J.OFA_DROP = {")
local dids = {}
for did in pairs(drops) do dids[#dids + 1] = did end
table.sort(dids)
for _, did in ipairs(dids) do
    local items = {}
    for item in pairs(drops[did]) do items[#items + 1] = item end
    table.sort(items)
    local parts = {}
    for _, item in ipairs(items) do
        local v = drops[did][item]
        parts[#parts + 1] = string.format("[%d] = { %g, %s }", item, v[1], v[2] and "true" or "false")
    end
    W(string.format("    %s = { %s },", did, table.concat(parts, ", ")))
end
W("}")
W("")
W("J.OFA_QUESTS = {")
dids = {}
for did in pairs(quests) do dids[#dids + 1] = did end
table.sort(dids)
for _, did in ipairs(dids) do
    W("    " .. did .. " = {")
    for _, l in ipairs(quests[did]) do W(l) end
    W("    },")
end
W("}")
W("")
W("J.MergeOneForAll()")
fh = assert(io.open(CDX .. "/data/dungeon_journal_ofa.lua", "w"))
fh:write(table.concat(out, "\n"), "\n")
fh:close()
print(string.format("Dungeons: %d Chancen gemessen gesetzt, %d Chancen gefuellt, %d Quests neu", dstat.set, dstat.fill, qn))

--------------------------------------------------
-- Berufe: Lehrer, Gebuehren, Raenge, Haendler fuer Reagenzien
--------------------------------------------------
-- Haengt an data/professions_ofa.lua an (traegt beim Laden in die Tabellen
-- des Naowh-Abgleichs ein, nur was dort fehlt - Gemessenes bleibt):
--   Lehrer, die der Bestand nicht kennt (QuestieDB Forever)
--   Lerngebuehr eines Rezepts, wo keine bekannt ist (CMaNGOS classic-db)
--   Kosten eines Rangs, wo keine bekannt sind
--   Haendler fuer Reagenzien, wo keiner bekannt ist (QuestieDB Forever)
local FP = {}
for _, f in ipairs({ "ProfessionTrainers", "ProfessionFees", "VendorReagents", "ReagentSources" }) do
    assert(loadfile(OFA .. "/Data/" .. f .. ".lua"))("OneForAll", FP)
end
local MAPALL = { Alchemy = "alchemy", Blacksmithing = "blacksmithing", Cooking = "cooking", Enchanting = "enchanting",
    Engineering = "engineering", ["First Aid"] = "first-aid", Leatherworking = "leatherworking", Tailoring = "tailoring",
    Mining = "mining", Herbalism = "herbalism", Skinning = "skinning", Fishing = "fishing" }
out = {}
W("")
W("-- Berufe: Lehrer, Gebuehren, Raenge, Haendler (Abgleich 1.0.8.0, nur Luecken)")
W("local SIDE = { A = \"Alliance\", H = \"Horde\" }")
W("P.OFA_TRAINERS = {")
local tnames = {}
for n in pairs(FP.PROFESSION_TRAINERS) do tnames[#tnames + 1] = n end
table.sort(tnames)
local tn = 0
for _, name in ipairs(tnames) do
    local key = MAPALL[name]
    local have = {}
    for _, t in ipairs((P.TRAINERS or {})[key] or {}) do have[t[1]] = true end
    for _, t in ipairs((P.NF_TRAINERS or {})[key] or {}) do have[t[1]] = true end
    local rows = {}
    for _, t in ipairs(FP.PROFESSION_TRAINERS[name]) do
        if key and not have[t[1]] and t[5] then
            local side = (t[4] == "A" or t[4] == "H") and string.format("SIDE.%s", t[4]) or "false"
            rows[#rows + 1] = string.format("{ %d, %q, %s, %d, %g, %g }", t[1], t[2], side, t[5], t[6], t[7])
            have[t[1]] = true
            tn = tn + 1
        end
    end
    if #rows > 0 then W(string.format("    [%q] = { %s },", key, table.concat(rows, ", "))) end
end
W("}")
W("P.OFA_FEES = {")
local fn = 0
local fees = {}
for _, d in pairs(FP.PROFESSION_FEES) do
    for spell, f in pairs(d.fees or {}) do
        local src = (P.NF_SRC or {})[spell]
        if not (type(src) == "string" and src:find("^k\t") or (type(src) == "string" and src:find("\nk\t"))) and type(f[1]) == "number" and f[1] > 0 then
            fees[#fees + 1] = { spell, f[1] }
        end
    end
end
table.sort(fees, function(a, b) return a[1] < b[1] end)
for _, e in ipairs(fees) do W(string.format("    [%d] = %d,", e[1], e[2])) fn = fn + 1 end
W("}")
W("P.OFA_RANK_COST = {")
local rn = 0
for name, d in pairs(FP.PROFESSION_FEES) do
    local key = MAPALL[name]
    for _, r in ipairs(d.ranks or {}) do
        for _, x in ipairs((P.NF_RANKS or {})[key] or {}) do
            if x.cap == r[3] and x.cost == nil and type(r[4]) == "number" and r[4] > 0 then
                W(string.format("    { %q, %d, %d },", key, r[3], r[4]))
                rn = rn + 1
            end
        end
    end
end
W("}")
W("P.OFA_REAGENT_VENDORS = {")
local vn = 0
local vitems = {}
for item in pairs(FP.VENDOR_REAGENTS) do vitems[#vitems + 1] = item end
table.sort(vitems)
for _, item in ipairs(vitems) do
    if not (P.NF_REAGENT_VENDORS or {})[item] then
        local names, seen = {}, {}
        for _, npc in ipairs(FP.VENDOR_REAGENTS[item]) do
            local v = FP.REAGENT_VENDORS and FP.REAGENT_VENDORS[npc]
            local nm = v and v[1]
            if type(nm) == "string" and not seen[nm] and #names < 40 then seen[nm] = true names[#names + 1] = string.format("%q", nm) end
        end
        if #names > 0 then
            table.sort(names)
            W(string.format("    [%d] = { false, %s },", item, table.concat(names, ", ")))
            vn = vn + 1
        end
    end
end
W("}")
W("for key, list in pairs(P.OFA_TRAINERS) do")
W("    P.NF_TRAINERS = P.NF_TRAINERS or {}")
W("    P.NF_TRAINERS[key] = P.NF_TRAINERS[key] or {}")
W("    for _, t in ipairs(list) do table.insert(P.NF_TRAINERS[key], t) end")
W("end")
W("P.NF_SRC = P.NF_SRC or {}")
W("for spell, copper in pairs(P.OFA_FEES) do")
W("    local s = P.NF_SRC[spell]")
W("    P.NF_SRC[spell] = (type(s) == \"string\" and (s .. \"\\n\") or \"\") .. \"k\\t\" .. copper")
W("end")
W("for _, e in ipairs(P.OFA_RANK_COST) do")
W("    for _, r in ipairs(P.NF_RANKS and P.NF_RANKS[e[1]] or {}) do")
W("        if r.cap == e[2] and r.cost == nil then r.cost = e[3] end")
W("    end")
W("end")
W("P.NF_REAGENT_VENDORS = P.NF_REAGENT_VENDORS or {}")
W("for item, v in pairs(P.OFA_REAGENT_VENDORS) do")
W("    if not P.NF_REAGENT_VENDORS[item] then P.NF_REAGENT_VENDORS[item] = v end")
W("end")
fh = assert(io.open(CDX .. "/data/professions_ofa.lua", "a"))
fh:write(table.concat(out, "\n"), "\n")
fh:close()
print(string.format("Berufe: %d Lehrer, %d Gebuehren, %d Rangkosten, %d Reagenzien mit Haendler", tn, fn, rn, vn))

--------------------------------------------------
-- Klassenquests: was dem Bestand fehlt
--------------------------------------------------
-- Klasse aus den Meilensteinen von OneForAll (welche Kette zu welcher
-- Klasse gehoert); Geber mit Name und Lage (keine NPC-Nummer bekannt -
-- eigener Schluessel, negativ, damit er nie eine echte Nummer trifft).
local FC = {}
assert(loadfile(OFA .. "/Data/ClassQuests.lua"))("OneForAll", FC)
dofile(CDX .. "/data/classquests.lua")
local Q = WeintCodex.ClassQuestData
local CLS = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID" }
local known = {}
for _, c in ipairs(CLS) do for _, q in ipairs(Q.CLASSES[c] or {}) do known[q.id] = true end end
local classOf = {}
for c, list in pairs(FC.CLASS_QUESTS.milestones or {}) do
    for _, m in ipairs(list) do
        for id in tostring(m[4]):gmatch("%d+") do classOf[tonumber(id)] = classOf[tonumber(id)] or c end
    end
end
local function Side(mask)
    mask = tonumber(mask) or 0
    if mask == 0 then return "AH" end
    local a, h = mask % 2 == 1 or math.floor(mask / 4) % 2 == 1 or math.floor(mask / 8) % 2 == 1 or math.floor(mask / 64) % 2 == 1,
        math.floor(mask / 2) % 2 == 1 or math.floor(mask / 16) % 2 == 1 or math.floor(mask / 32) % 2 == 1 or math.floor(mask / 128) % 2 == 1
    return (a and not h) and "A" or (h and not a) and "H" or "AH"
end
local cadd, cn = {}, 0
local qids = {}
for id in pairs(FC.CLASS_QUESTS.quests or {}) do qids[#qids + 1] = id end
table.sort(qids)
for _, id in ipairs(qids) do
    local c = classOf[id]
    if c and not known[id] then
        local s = FC.CLASS_QUESTS.quests[id]
        local f = {}
        for part in (s .. "|"):gmatch("([^|]*)|") do f[#f + 1] = part end
        local pre = {}
        for p in (f[4] or ""):gmatch("%d+") do pre[#pre + 1] = p end
        for p in (f[5] or ""):gmatch("%d+") do pre[#pre + 1] = p end
        local map, x, y = tonumber(f[7]), tonumber(f[8]), tonumber(f[9])
        -- Geber, den der Bestand schon kennt: seine echte Nummer.
        local gid = -id
        for nid, n in pairs(Q.NPCS) do if n[1] == f[6] then gid = nid break end end
        cadd[c] = cadd[c] or {}
        cadd[c][#cadd[c] + 1] = string.format(
            "        { id = %d, name = %q, lv = %s, rl = %s,%s giver = %d, pre = { %s }, ofa = true },",
            id, f[1], f[2] ~= "" and f[2] or "nil", f[2] ~= "" and f[2] or "nil",
            (tonumber(f[3]) or 0) > 0 and (" ra = " .. f[3] .. ",") or "", gid, table.concat(pre, ", "))
        cadd[c].npcs = cadd[c].npcs or {}
        if gid < 0 then cadd[c].npcs[#cadd[c].npcs + 1] = string.format("Q.OFA_NPCS[%d] = { %q, %s, %s, %s, %q }", -id, f[6] or "?",
            map and tostring(map) or "nil", x and tostring(x) or "nil", y and tostring(y) or "nil", Side(f[3])) end
        cn = cn + 1
    end
end
out = {}
W("--------------------------------------------------")
W("-- WeintCodex :: Klassenquests - Abgleich mit OneForAll (1.0.8.0)")
W("--------------------------------------------------")
W("-- ERZEUGT von .github/scripts/import_oneforall.lua - nicht von Hand aendern.")
W("-- Herkunft (nur fuer Betreuer): OneForAll 6.2.13 (GPL-3.0, nur Daten),")
W("-- dort aus QuestieDB Forever (18.11.2026). Nur Quests, die dem Bestand")
W("-- fehlen; Geber unter eigenem, negativem Schluessel. Art `community`.")
W("--------------------------------------------------")
W("")
W("local Q = WeintCodex and WeintCodex.ClassQuestData")
W("if not Q then return end")
W("-- Geber ohne bekannte NPC-Nummer: eigener, negativer Schluessel (CQ.Npc).")
W("Q.OFA_NPCS = Q.OFA_NPCS or {}")
W("local ADD = {")
local cs = {}
for c in pairs(cadd) do cs[#cs + 1] = c end
table.sort(cs)
for _, c in ipairs(cs) do
    W("    " .. c .. " = {")
    for _, l in ipairs(cadd[c]) do W(l) end
    W("    },")
end
W("}")
for _, c in ipairs(cs) do
    for _, l in ipairs(cadd[c].npcs) do W(l) end
end
W("local mt = getmetatable(Q.CLASSES)")
W("local build = mt and mt.__index")
W("if type(build) == \"function\" then")
W("    mt.__index = function(t, class)")
W("        local list = build(t, class)")
W("        if type(list) == \"table\" and ADD[class] then")
W("            for _, q in ipairs(ADD[class]) do list[#list + 1] = q end")
W("            ADD[class] = nil")
W("        end")
W("        return list")
W("    end")
W("end")
W("Q.OFA_ADDED = " .. cn)
fh = assert(io.open(CDX .. "/data/classquests_ofa.lua", "w"))
fh:write(table.concat(out, "\n"), "\n")
fh:close()
print(string.format("Klassenquests: %d neu", cn))

--------------------------------------------------
-- Questketten der Dungeons
--------------------------------------------------
-- Ganze Kette vor einer Dungeonquest, mit freiwilligen Vorquests
-- (optional = true: Brotkrumen, zaehlen nicht als Voraussetzung). Nur fuer
-- Quests des Journals, und nur wo der Bestand keine oder eine kuerzere hat.
local FQ = {}
assert(loadfile(OFA .. "/Data/DungeonQuestChains.lua"))("OneForAll", FQ)
dofile(CDX .. "/data/dungeon_journal_ofa.lua")
local inJ = {}
for _, d in pairs(J.DATA) do for _, q in ipairs(d.quests or {}) do inJ[q.id] = true end end
local chains, chn = {}, 0
for qid, steps in pairs(FQ.QUEST_PREREQ_CHAINS) do
    local c = J.CHAIN and J.CHAIN[qid]
    local mine = c and c.prev and #c.prev or 0
    if inJ[qid] and #steps > mine then
        local parts = {}
        for _, st in ipairs(steps) do
            if type(st.id) == "number" then
                parts[#parts + 1] = string.format("{ %d, %q%s }", st.id, st.name or "", st.optional and ", true" or "")
            end
        end
        if #parts > 0 then chains[#chains + 1] = { qid, table.concat(parts, ", ") } chn = chn + 1 end
    end
end
table.sort(chains, function(a, b) return a[1] < b[1] end)
out = {}
W("")
W("-- Ganze Kette vor einer Dungeonquest (QuestieDB Forever, auf Wowhead geprueft):")
W("-- { Nummer, englischer Name, freiwillig } - Name nur als Rueckfall, gezeigt wird der des Clients.")
W("J.OFA_CHAIN = {")
for _, e in ipairs(chains) do W(string.format("    [%d] = { %s },", e[1], e[2])) end
W("}")
fh = assert(io.open(CDX .. "/data/dungeon_journal_ofa.lua", "a"))
fh:write(table.concat(out, "\n"), "\n")
fh:close()
print(string.format("Questketten: %d", chn))

--------------------------------------------------
-- Karte: fehlende Flugmeister und Uebergaenge
--------------------------------------------------
-- Flugmeister (QuestieDB Forever) und Uebergaenge zwischen Gebieten
-- (Carbonite, GPL-3.0 - nur Lagen), die der Bestand nicht kennt. Die
-- Richtung des Pfeils zeigt vom Kartenmittelpunkt zum Uebergang (Bogenmass,
-- gegen den Uhrzeigersinn, 0 = oben - wie data/mapmarks.lua).
local FM = {}
assert(loadfile(OFA .. "/Data/MapLandmarks.lua"))("OneForAll", FM)
assert(loadfile(OFA .. "/Data/ZoneTransitions.lua"))("OneForAll", FM)
dofile(CDX .. "/data/towns.lua")
dofile(CDX .. "/data/mapmarks.lua")
local TD, MD = WeintCodex.TownData, WeintCodex.MapMarksData
-- Nur fuer Druiden (Mondlichtung).
local DRUID_ONLY = { ["Bunthen Plainswind"] = true, ["Silva Fil'naveth"] = true }
local flights, crossings = {}, {}
for _, f in ipairs(FM.MAP_LANDMARKS.flight) do
    local found = false
    for _, h in ipairs(TD.maps[f[1]] or {}) do
        if h[3] == "flight" and math.abs(h[1] - f[2]) < 2 and math.abs(h[2] - f[3]) < 2 then found = true end
    end
    if not found then
        flights[#flights + 1] = string.format("    { %d, %g, %g, %q%s },   -- %s", f[1], f[2], f[3], f[4],
            DRUID_ONLY[f[5]] and ", \"DRUID\"" or "", f[5])
    end
end
local haveC = {}
for map, l in pairs(MD.crossings) do for i = 1, #l, 4 do haveC[map .. ">" .. l[i + 3]] = true end end
for _, t in ipairs(FM.ZONE_TRANSITIONS) do
    local k = t[1] .. ">" .. t[4]
    if not haveC[k] then
        haveC[k] = true
        local x, y = t[2] / 100, t[3] / 100
        local ang = math.atan2(-(x - 0.5), -(y - 0.5))
        crossings[#crossings + 1] = string.format("    { %d, %.3f, %.3f, %.3f, %d },", t[1], x, y, ang, t[4])
    end
end
out = {}
W("--------------------------------------------------")
W("-- WeintCodex :: Karte - Abgleich mit OneForAll (1.0.8.0)")
W("--------------------------------------------------")
W("-- ERZEUGT von .github/scripts/import_oneforall.lua - nicht von Hand aendern.")
W("-- Herkunft (nur fuer Betreuer): Flugmeister aus QuestieDB Forever, Uebergaenge")
W("-- aus Carbonite (beides ueber OneForAll 6.2.13, GPL-3.0 - nur Lagen).")
W("-- Traegt beim Laden in WeintCodex.TownData und WeintCodex.MapMarksData ein,")
W("-- nur was dort fehlt. Art `community`.")
W("--------------------------------------------------")
W("")
W("local TD, MD = WeintCodex and WeintCodex.TownData, WeintCodex and WeintCodex.MapMarksData")
W("local FLIGHT = {   -- { Karte, x, y, Fraktion, Klasse }")
for _, l in ipairs(flights) do W(l) end
W("}")
W("local CROSS = {    -- { Karte, x, y, Richtung, Zielkarte }")
for _, l in ipairs(crossings) do W(l) end
W("}")
W("if TD and TD.maps then")
W("    for _, f in ipairs(FLIGHT) do")
W("        TD.maps[f[1]] = TD.maps[f[1]] or {}")
W("        table.insert(TD.maps[f[1]], { f[2], f[3], \"flight\", f[4], f[5] })")
W("    end")
W("end")
W("if MD and MD.crossings then")
W("    for _, c in ipairs(CROSS) do")
W("        local l = MD.crossings[c[1]] or {}")
W("        MD.crossings[c[1]] = l")
W("        l[#l + 1], l[#l + 2], l[#l + 3], l[#l + 4] = c[2], c[3], c[4], c[5]")
W("    end")
W("end")
fh = assert(io.open(CDX .. "/data/maps_ofa.lua", "w"))
fh:write(table.concat(out, "\n"), "\n")
fh:close()
print(string.format("Karte: %d Flugmeister, %d Uebergaenge", #flights, #crossings))

--------------------------------------------------
-- Sets (Beute -> Sets)
--------------------------------------------------
-- Aus der Armory von OneForAll (Forever-Client ueber wago.tools, Wowhead
-- Forever): je Set, ob es in Forever zu bekommen ist (st 1), die Quelle noch
-- unbekannt ist (st 2) oder es Forever noch nicht gibt (st 0). Neue Sets
-- (nicht in data/loot.lua, st 1/2) als eigener Bereich "Sets aus Forever".
local FA = {}
assert(loadfile(OFA .. "/Data/Armory.lua"))("OneForAll", FA)
dofile(CDX .. "/data/loot.lua")
local LD = WeintCodex.LootData
local haveSet = {}
for _, list in pairs(LD.b) do
    for _, s in ipairs(list) do
        local id = s:match("\ts(%d+)\t")
        if id then haveSet[tonumber(id)] = true end
    end
end
local status, rows = {}, {}
local GROUP = { raid = 1, dungeon = 2, crafted = 3, pvp = 4, world = 5 }
local sets = {}
for _, s in ipairs(FA.ARMORY_SETS) do
    status[#status + 1] = string.format("[%d] = %d", s.id, s.st)
    if not haveSet[s.id] and s.st ~= 0 then sets[#sets + 1] = s end
end
table.sort(sets, function(a, b)
    if (GROUP[a.g] or 9) ~= (GROUP[b.g] or 9) then return (GROUP[a.g] or 9) < (GROUP[b.g] or 9) end
    if (a.lv or 0) ~= (b.lv or 0) then return (a.lv or 0) < (b.lv or 0) end
    return a.n < b.n
end)
for _, s in ipairs(sets) do
    local only = s.side == "A" and "a" or s.side == "H" and "h" or ""
    local items = {}
    for _, it in ipairs(s.i or {}) do items[#items + 1] = tostring(it[1]) .. only end
    rows[#rows + 1] = string.format("        %q,", table.concat({ s.n, "s" .. s.id, table.concat(items, ",") }, "\t"))
end
out = {}
W("--------------------------------------------------")
W("-- WeintCodex :: Beute - Sets, Abgleich mit OneForAll (1.0.8.0)")
W("--------------------------------------------------")
W("-- ERZEUGT von .github/scripts/import_oneforall.lua - nicht von Hand aendern.")
W("-- Herkunft (nur fuer Betreuer): Armory von OneForAll 6.2.13 (GPL-3.0, nur")
W("-- Daten; dort aus dem Forever-Client ueber wago.tools und Wowhead Forever).")
W("--   SET_STATUS[Set] = 1 in Forever zu bekommen, 2 Quelle noch unbekannt,")
W("--                     0 in Forever noch nicht da; fehlt: unbekannt")
W("--   Bereich \"Sets aus Forever\": Sets, die data/loot.lua nicht kennt (1 und 2).")
W("-- Art `community`. Namen der Sets und Teile nennt der Client; der englische")
W("-- Name ist nur Rueckfall.")
W("--------------------------------------------------")
W("")
W("local D = WeintCodex and WeintCodex.LootData")
W("if not D then return end")
W("D.SET_STATUS = { " .. table.concat(status, ", ") .. " }")
W("local n = #D.i + 1")
W("D.i[n] = \"ForeverSets\\ts\\tcommunity\\t0\\tSets aus Forever\\t\"")
W("D.b[n] = {")
for _, r in ipairs(rows) do W(r) end
W("}")
fh = assert(io.open(CDX .. "/data/loot_ofa.lua", "w"))
fh:write(table.concat(out, "\n"), "\n")
fh:close()
print(string.format("Sets: %d neu, Stand fuer %d", #rows, #status))

--------------------------------------------------
-- Bosse: NPC-Nummern (Bosskaempfe, Namensplaketten)
--------------------------------------------------
-- Der Bosskampf erkennt Bosse alter Dungeons ueber die NPC-Nummer
-- (data/boss_npcs.lua, ueber gleiche Beute zugeordnet). Ohne Nummer bleibt
-- nur der englische Name - auf einem deutschen Client trifft der nie.
-- OneForAll fuehrt je Boss die Nummer (QuestieDB Forever). Uebernommen wird
-- eine Nummer nur, wenn sie data/boss_npcs.lua fehlt UND der Boss im selben
-- Dungeon des Kompendiums denselben englischen Namen traegt - oder Teil
-- eines Kampfes ist, den das Kompendium als einen Boss fuehrt (TEIL unten).
-- Dazu die Nummern aus data/boss_npcs_forever.lua, die dort fehlen.
-- Geschrieben nach data/boss_npcs_ofa.lua: fuellt WeintCodex.BossNpcs nur
-- dort, wo keine Nummer steht.
dofile(CDX .. "/data/boss_npcs.lua")
dofile(CDX .. "/data/boss_npcs_forever.lua")
local BN = WeintCodex.BossNpcs
-- Teile eines Kampfes: [Dungeon/Boss des Kompendiums] = { englische Namen in OneForAll }
local TEIL = {
    ["blackrock_depths/the_seven"] = { "Anger'rel", "Doom'rel" },
    ["stratholme/balnazzar"] = { "Balnazzar" },
}
local bossOf, deOf = {}, {}      -- [Dungeon][englisch, klein] = Boss; [Dungeon/Boss] = deutscher Name
for _, list in ipairs({ WeintCodex_Dungeons or {}, WeintCodex_ClassicDungeons or {} }) do
    for _, d in ipairs(list) do
        bossOf[d.id] = bossOf[d.id] or {}
        for _, b in ipairs(type(d.bosses) == "table" and d.bosses or {}) do
            if type(b.name) == "string" then bossOf[d.id][b.name:lower()] = b end
        end
    end
end
for _, e in pairs(BN) do deOf[e[1] .. "/" .. e[2]] = deOf[e[1] .. "/" .. e[2]] or e[3] end
for key, names in pairs(TEIL) do
    local did, bid = key:match("^([^/]+)/(.+)$")
    for _, n in ipairs(names) do
        bossOf[did] = bossOf[did] or {}
        bossOf[did][n:lower()] = bossOf[did][n:lower()] or { id = bid, name = n }
    end
end
-- Ein Boss hat in BossNpcs genau eine Nummer mit seinem Namen (data_test).
-- Jede weitere Nummer desselben Kampfes (Teil, anderer Name, oder der Boss
-- hat schon eine) geht nach BossNpcParts.
local add, part, nAdd, nPart = {}, {}, 0, 0
local numbered = {}
for _, e in pairs(BN) do numbered[e[1] .. "/" .. e[2]] = true end
local fullName = {}
for _, list in ipairs({ WeintCodex_Dungeons or {}, WeintCodex_ClassicDungeons or {} }) do
    for _, d in ipairs(list) do
        for _, b in ipairs(type(d.bosses) == "table" and d.bosses or {}) do fullName[d.id .. "/" .. b.id] = b.name end
    end
end
local function Add(npc, did, b, how)
    if BN[npc] or add[npc] or part[npc] then return end
    local k = did .. "/" .. b.id
    if not numbered[k] and fullName[k] == b.name then
        add[npc] = { did, b.id, deOf[k] or b.name, b.name, how }
        numbered[k] = true
        nAdd = nAdd + 1
    else
        part[npc] = { did, b.id, b.name, how }
        nPart = nPart + 1
    end
end
for dname, reg in pairs(FLTD.DUNGEON_REGISTRY) do
    local did = DId(dname)
    for _, b in ipairs(did and reg.bosses or {}) do
        if type(b.npcID) == "number" then
            for _, n in ipairs({ b.name, unpack(b.aliases or {}) }) do
                local hit = type(n) == "string" and bossOf[did] and bossOf[did][n:lower()]
                if hit then Add(b.npcID, did, hit, "OneForAll") break end
            end
        end
    end
end
for npc, e in pairs(WeintCodex.ForeverBossNpcs or {}) do
    local hit = bossOf[e[1]] and bossOf[e[1]][e[2]:lower()]
    if hit then Add(npc, e[1], hit, "boss_npcs_forever") end
end
local npcs = {}
for npc in pairs(add) do npcs[#npcs + 1] = npc end
table.sort(npcs, function(a, b)
    if add[a][1] ~= add[b][1] then return add[a][1] < add[b][1] end
    return a < b
end)
out = {}
W("--------------------------------------------------")
W("-- WeintCodex :: NPC-Nummern der Bosse, Abgleich mit OneForAll (1.0.8.0)")
W("--------------------------------------------------")
W("-- ERZEUGT von .github/scripts/import_oneforall.lua - nicht von Hand aendern.")
W("-- Herkunft (nur fuer Betreuer): OneForAll 6.2.13 (GPL-3.0, nur Daten; dort")
W("-- aus QuestieDB Forever) und data/boss_npcs_forever.lua. Nur Nummern, die")
W("-- data/boss_npcs.lua fehlen, nur bei gleichem englischem Namen im selben")
W("-- Dungeon oder als Teil eines Kampfes. Art `community`.")
W("-- Gleiche Form wie data/boss_npcs.lua; fuellt nur, was dort fehlt.")
W("--------------------------------------------------")
W("")
W("local B = WeintCodex and WeintCodex.BossNpcs")
W("if not B then return end")
W("for npc, e in pairs({")
for _, npc in ipairs(npcs) do
    local e = add[npc]
    W(string.format("    [%d] = { %q, %q, %q, %q },   -- %s", npc, e[1], e[2], e[3], e[4], e[5]))
end
W("}) do")
W("    if B[npc] == nil then B[npc] = e end")
W("end")
W("")
W("-- Weitere Gegner desselben Kampfes: [npc] = { Dungeon, Boss, englischer Name }.")
W("-- Gelesen von ui/bossmod.lua (Kampf erkennen, Zauber zaehlen) und")
W("-- ui/nameplates.lua (Bossfarbe).")
W("WeintCodex.BossNpcParts = WeintCodex.BossNpcParts or {}")
W("for npc, e in pairs({")
local pn = {}
for npc in pairs(part) do pn[#pn + 1] = npc end
table.sort(pn)
for _, npc in ipairs(pn) do
    local e = part[npc]
    W(string.format("    [%d] = { %q, %q, %q },   -- %s", npc, e[1], e[2], e[3], e[4]))
end
W("}) do")
W("    if B[npc] == nil and WeintCodex.BossNpcParts[npc] == nil then WeintCodex.BossNpcParts[npc] = e end")
W("end")
fh = assert(io.open(CDX .. "/data/boss_npcs_ofa.lua", "w"))
fh:write(table.concat(out, "\n"), "\n")
fh:close()
print(string.format("Bosse: %d Nummern ergaenzt, %d Teile von Kaempfen", nAdd, nPart))
