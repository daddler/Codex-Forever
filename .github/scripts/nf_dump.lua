-- Liest die Datendateien des Addons "Naowh Forever: Dungeon Journal" in
-- einer leeren Umgebung und schreibt sie als JSON. Kein Code des Addons
-- laeuft ausser den Datendateien selbst (Tabellen, ein AddDungeon-Aufruf
-- je Datei, den dieses Skript stellt).
-- Aufruf: lua5.1 .github/scripts/nf_dump.lua <Ordner>/Data > nf.json
-- Benutzt von .github/scripts/import_naowh.py.

local dir = arg[1]
local J = { dungeons = {} }
local NF = { Journal = J, Shared = { ItemFacts = {} } }
function J.AddDungeon(key, t) t.key = key; J.dungeons[#J.dungeons + 1] = t end

local function load(path)
    local fn, err = loadfile(path)
    if not fn then error(err) end
    setfenv(fn, { _G = { NaowhForever = NF } })
    fn()
end

for _, f in ipairs({ "Build.lua", "Items.lua", "BossInfo.lua", "Abilities.lua" }) do load(dir .. "/" .. f) end
local p = io.popen('ls "' .. dir .. '/Dungeons"')
for f in p:lines() do load(dir .. "/Dungeons/" .. f) end
p:close()

local function esc(s) return '"' .. tostring(s):gsub('[%c"\\]', function(c) return string.format("\\u%04x", c:byte()) end) .. '"' end
local function dump(v)
    if type(v) == "table" then
        local n, count = #v, 0
        for _ in pairs(v) do count = count + 1 end
        local parts = {}
        if count == n then
            for i = 1, n do parts[i] = dump(v[i]) end
            return "[" .. table.concat(parts, ",") .. "]"
        end
        for k, val in pairs(v) do parts[#parts + 1] = esc(k) .. ":" .. dump(val) end
        return "{" .. table.concat(parts, ",") .. "}"
    elseif type(v) == "string" then return esc(v)
    elseif type(v) == "nil" or type(v) == "function" then return "null"
    else return tostring(v) end
end
io.write(dump({ build = J.DATA_BUILD, date = J.DATA_DATE, dungeons = J.dungeons,
                notYet = J.NotYet, bossInfo = J.BossInfo, abilities = J.Abilities }))
