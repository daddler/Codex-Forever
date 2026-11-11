-- Liest die Datendateien des Addons "Naowh Forever: Professions" in einer
-- leeren Umgebung und schreibt sie als JSON. Kein Code des Addons laeuft
-- ausser den Datendateien selbst (Tabellen).
-- Aufruf: lua5.1 .github/scripts/nf_prof_dump.lua <Ordner>/Data > nfp.json
-- Benutzt von .github/scripts/import_naowh_prof.py.

local dir = arg[1]
local NF = { Professions = {} }

local function load(path)
    local fn, err = loadfile(path)
    if not fn then error(err) end
    setfenv(fn, { _G = { NaowhForever = NF } })
    fn()
end

for _, f in ipairs({ "RecipeData.lua", "RecipeReagents.lua", "VendorReagents.lua", "VendorSellers.lua",
                     "VendorPrices.lua", "GatherNodes.lua", "CooldownRecipes.lua" }) do
    load(dir .. "/" .. f)
end

local function esc(s) return '"' .. tostring(s):gsub('[%c"\\]', function(c) return string.format("\\u%04x", c:byte()) end) .. '"' end
local function dump(v)
    if type(v) == "table" then
        local n, count = #v, 0
        for _ in pairs(v) do count = count + 1 end
        local parts = {}
        if count == n and n > 0 then
            for i = 1, n do parts[i] = dump(v[i]) end
            return "[" .. table.concat(parts, ",") .. "]"
        end
        for k, val in pairs(v) do parts[#parts + 1] = esc(k) .. ":" .. dump(val) end
        return "{" .. table.concat(parts, ",") .. "}"
    elseif type(v) == "string" then return esc(v)
    elseif type(v) == "nil" or type(v) == "function" then return "null"
    else return tostring(v) end
end
local P = NF.Professions
local keep = {}
for k, v in pairs(P) do if type(v) == "table" then keep[k] = v end end
io.write(dump({ recipes = NF.RecipeData, prof = keep }))
