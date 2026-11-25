-- Stadt-NPCs, Briefkaesten, Daemonenbuecher, Schliesskassetten aus Naowh Forever.
--   lua5.1 .github/scripts/import_naowh_qol.lua <Ordner mit den NaowhForever_*-Ordnern>
-- Nur Fakten (Lagen, Kategorien, Nummern, Stufen, Preise), keine Texte, kein Code.
-- Schreibt data/towns.lua, data/grimoires.lua, data/lockboxes.lua.
local root = assert(arg[1], "Ordner fehlt")
_G.NaowhForever = {}
assert(loadfile(root .. "/NaowhForever/Shared/Game/Towns.lua"))()
assert(loadfile(root .. "/NaowhForever_QoL/Interface/TownMailboxes.lua"))()
assert(loadfile(root .. "/NaowhForever_Training/Data/TrainingGrimoires.lua"))()
assert(loadfile(root .. "/NaowhForever_QoL/Loot/LockboxData.lua"))()
local ns = NaowhForever
local HEAD = function(title, what)
    return {
        "--------------------------------------------------",
        "-- WeintCodex :: " .. title,
        "--------------------------------------------------",
        "-- ERZEUGT von .github/scripts/import_naowh_qol.lua aus Naowh Forever 1.2.33",
        "-- - nicht von Hand aendern. Herkunft `community`. " .. what,
        "--------------------------------------------------",
        "",
        "WeintCodex = WeintCodex or {}",
    }
end
local function write(path, lines) local f = assert(io.open(path, "w")) f:write(table.concat(lines, "\n") .. "\n") f:close() end
local function q(s) return s and string.format("%q", s) or "nil" end

-- Staedte: je Karte { x, y, Art, Fraktion } - Namen der NPCs nicht (Englisch).
local KEEP = { vendor = 1, repair = 1, profession = 1, class = 1, trade = 1, food = 1, flight = 1,
    stable = 1, inn = 1, bank = 1, auction = 1, reagents = 1, ammo = 1 }
local maps = {}
for m in pairs(ns.TownNPCs) do maps[#maps + 1] = m end
for m in pairs(ns.TownMailboxes) do if not ns.TownNPCs[m] then maps[#maps + 1] = m end end
table.sort(maps)
local out = HEAD("Stadt-Pins: Dienste und Briefkaesten", "{ x, y, Art, Fraktion (A/H/AH), Klasse }")
out[#out + 1] = "WeintCodex.TownData = {"
out[#out + 1] = "    capitals = { " .. (function() local t = {} for m in pairs(ns.TownCapitals) do t[#t + 1] = "[" .. m .. "] = true" end table.sort(t) return table.concat(t, ", ") end)() .. " },"
out[#out + 1] = "    maps = {"
local n = 0
for _, m in ipairs(maps) do
    out[#out + 1] = "        [" .. m .. "] = {"
    for _, e in ipairs(ns.TownNPCs[m] or {}) do
        -- Naowh fuehrt "Master Smith Burninate" (Thoriumbruderschaft, Sengende
        -- Schlucht) als Auktionator - dort gibt es keins (Spieler mit Bild,
        -- 1.0.9.1). Auktionshaus nur, wenn Name oder Titel "Auctioneer" sagt.
        local fake = e[3] == "auction" and not (tostring(e[4] or ""):find("Auctioneer", 1, true)
            or tostring(e[5] or ""):find("Auctioneer", 1, true))
        if KEEP[e[3]] and not fake then
            n = n + 1
            out[#out + 1] = string.format("            { %.1f, %.1f, %q, %s%s },", e[1], e[2], e[3], q(e[7]), e[6] and (", " .. q(e[6])) or "")
        end
    end
    for _, e in ipairs(ns.TownMailboxes[m] or {}) do
        n = n + 1
        out[#out + 1] = string.format("            { %.1f, %.1f, \"mail\", %s },", e[1], e[2], q(e[7]))
    end
    out[#out + 1] = "        },"
end
out[#out + 1] = "    },"
out[#out + 1] = "}"
write("data/towns.lua", out)

out = HEAD("Daemonenbuecher des Hexenmeisters", "{ Stufe, Zauber, Kupfer, item = Buch, needs = Vorstufe }")
out[#out + 1] = "WeintCodex.GrimoireData = {"
for _, d in ipairs(ns.TrainingGrimoires) do
    out[#out + 1] = string.format("    { line = %d, name = %q, families = { %s }, books = {", d.line, d.name, table.concat(d.families, ", "))
    for _, b in ipairs(d.books) do
        out[#out + 1] = string.format("        { %d, %d, %d, item = %d%s },", b[1], b[2], b[3], b.item, b.needs and (", needs = " .. b.needs) or "")
    end
    out[#out + 1] = "    } },"
end
out[#out + 1] = "}"
write("data/grimoires.lua", out)

out = HEAD("Schliesskassetten", "[Gegenstand] = noetige Fertigkeit Schlossknacken")
out[#out + 1] = "WeintCodex.LockboxData = {"
local ids = {}
for id in pairs(ns.LockboxSkills) do ids[#ids + 1] = id end
table.sort(ids)
for _, id in ipairs(ids) do out[#out + 1] = string.format("    [%d] = %d,", id, ns.LockboxSkills[id]) end
out[#out + 1] = "}"
write("data/lockboxes.lua", out)
print(n .. " Stadt-Pins, " .. #ns.TrainingGrimoires .. " Dämonen, " .. #ids .. " Kassetten")
