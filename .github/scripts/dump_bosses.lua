local root = arg[1]
WeintCodex = {}
setmetatable(_G, { __index = function(_, k) return nil end })
local function try(f) local ok, e = pcall(dofile, root .. "/" .. f) if not ok then io.stderr:write(f .. ": " .. tostring(e) .. "\n") end end
for _, f in ipairs({ "data/sources.lua", "data/raids.lua", "data/dungeons.lua", "data/dungeons_classic.lua" }) do try(f) end
local D = WeintCodex.DungeonData
for _, d in ipairs(D.AllInstances()) do
    print("D\t" .. d.id .. "\t" .. d.name)
    for _, b in ipairs(d.bosses or {}) do
        print("B\t" .. d.id .. "\t" .. b.id .. "\t" .. b.name .. "\t" .. tostring(b.wing or ""))
    end
end
