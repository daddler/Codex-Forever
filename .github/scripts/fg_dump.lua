-- Liest Datendateien des Addons ForeverGuide und schreibt sie als JSON.
-- Aufruf: lua5.1 fg_dump.lua <ForeverGuide-Ordner> > fg.json
--
-- Jede Datei wird in einer eigenen, leeren Umgebung geladen (setfenv):
-- kein os, kein io, kein require - die Dateien sind Tabellen, und mehr
-- als Tabellen bauen duerfen sie hier nicht. Gelesen werden nur Daten;
-- nichts davon wird in WeintCodex ausgefuehrt.
-- Benutzt von .github/scripts/import_foreverguide.py.

local dir = assert(arg[1], "Ordner fehlt")
local FILES = { "DungeonData.lua", "DungeonLoot.lua", "ProfessionData.lua", "ItemCatalogData.lua", "ClassData.lua", "RareData.lua" }

local ns = {}
for _, name in ipairs(FILES) do
    local chunk = assert(loadfile(dir .. "/" .. name))
    setfenv(chunk, {})
    chunk("ForeverGuide", ns)
end

local function esc(s)
    return '"' .. s:gsub('[%c"\\]', function(c)
        if c == '"' then return '\\"' elseif c == "\\" then return "\\\\"
        elseif c == "\n" then return "\\n" elseif c == "\t" then return "\\t" end
        return string.format("\\u%04x", c:byte())
    end) .. '"'
end

local out = {}
local function emit(s) out[#out + 1] = s end

local function dump(v)
    local t = type(v)
    if t == "table" then
        -- Liste, wenn die Schluessel genau 1..n sind.
        local n, count = #v, 0
        for _ in pairs(v) do count = count + 1 end
        if count == n then
            emit("[")
            for i = 1, n do if i > 1 then emit(",") end dump(v[i]) end
            emit("]")
        else
            emit("{")
            local first = true
            for k, val in pairs(v) do
                if not first then emit(",") end
                first = false
                emit(esc(tostring(k)))
                emit(":")
                dump(val)
            end
            emit("}")
        end
    elseif t == "string" then emit(esc(v))
    elseif t == "number" then emit(string.format("%.17g", v))
    elseif t == "boolean" then emit(tostring(v))
    else emit("null") end
end

local keep = { "DUNGEONS", "DQ", "DNPC", "DOBJ", "DRITEM", "DITEM", "LOOT",
               "PROFS", "PREC", "PTRAIN", "PVEND", "PVNPC", "PNAME", "CAT_DATA",
               "CLASS_Q", "CLASS_NPC", "CLASS_TRAINERS", "RARE" }
local sel = {}
for _, k in ipairs(keep) do sel[k] = ns[k] end
dump(sel)
io.write(table.concat(out))
