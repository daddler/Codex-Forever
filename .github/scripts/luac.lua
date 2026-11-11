-- Ersatz fuer luac5.1 in den Prueflaeufen (siehe install_lua.sh).
--   luac5.1 -p Datei...      Syntax pruefen (loadfile, ohne Ausfuehren)
--   luac5.1 -l -p Datei...   dazu je Zugriff auf eine globale Variable eine
--                            Zeile "GETGLOBAL ; Name" bzw. "SETGLOBAL ; Name"
--                            - das, was .github/tests/load_test.lua aus der
--                            Liste von luac liest. Gelesen aus string.dump
--                            (Bytecode von Lua 5.1), nicht geraten.
local list, files = false, {}
for _, a in ipairs(arg) do
    if a == "-l" then list = true
    elseif a == "-p" then -- immer nur pruefen
    else files[#files + 1] = a end
end

local function Reader(s)
    local pos, intSize, sizeT = 13, s:byte(8), s:byte(9)
    local r = {}
    local function int(n)
        local v, mul = 0, 1
        for i = 0, n - 1 do v = v + s:byte(pos + i) * mul mul = mul * 256 end
        pos = pos + n
        return v
    end
    function r.int() return int(intSize) end
    function r.byte() pos = pos + 1 return s:byte(pos - 1) end
    function r.str()
        local n = int(sizeT)
        local v = n > 0 and s:sub(pos, pos + n - 2) or nil
        pos = pos + n
        return v
    end
    function r.skip(n) pos = pos + n end
    r.numSize = s:byte(11)
    return r
end

local function Walk(r, out)
    r.str()                      -- Quelle
    r.int() r.int()              -- Zeilen
    r.skip(4)                    -- Upvalues, Parameter, Vararg, Stapel
    local code = {}
    for i = 1, r.int() do code[i] = r.int() end
    local consts = {}
    for i = 1, r.int() do
        local t = r.byte()
        if t == 1 then r.skip(1)
        elseif t == 3 then r.skip(r.numSize)
        elseif t == 4 then consts[i - 1] = r.str() end
    end
    for _, ins in ipairs(code) do
        local op = ins % 64
        if op == 5 or op == 7 then
            local bx = math.floor(ins / 16384)
            out[#out + 1] = (op == 5 and "GETGLOBAL" or "SETGLOBAL") .. "\t; " .. tostring(consts[bx])
        end
    end
    for _ = 1, r.int() do Walk(r, out) end
    r.skip(r.int() * 4)                                   -- Zeileninfo
    for _ = 1, r.int() do r.str() r.int() r.int() end     -- lokale Variablen
    for _ = 1, r.int() do r.str() end                     -- Upvalue-Namen
end

local rc = 0
for _, f in ipairs(files) do
    local fn, err = loadfile(f)
    if not fn then
        io.stderr:write("luac5.1: ", tostring(err), "\n")
        rc = 1
    elseif list then
        local out = {}
        Walk(Reader(string.dump(fn)), out)
        io.write(table.concat(out, "\n"), "\n")
    end
end
os.exit(rc)
