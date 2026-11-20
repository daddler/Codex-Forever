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
W("-- Herkunft (nur fuer Betreuer): OneForAll 6.2.12 (GPL-3.0, nur Daten) -")
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
W("-- Herkunft (nur fuer Betreuer): OneForAll 6.2.12 (GPL-3.0, nur Daten) -")
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
