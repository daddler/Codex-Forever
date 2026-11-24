local root = arg[1]
WeintCodex = {}
for _, f in ipairs({ "data/boss_npcs.lua", "data/boss_npcs_forever.lua", "data/boss_npcs_ofa.lua" }) do pcall(dofile, root .. "/" .. f) end
for npc, e in pairs(WeintCodex.BossNpcs or {}) do print("N\t" .. npc .. "\t" .. e[1] .. "\t" .. e[2]) end
for npc, e in pairs(WeintCodex.ForeverBossNpcs or {}) do print("F\t" .. npc .. "\t" .. e[1] .. "\t" .. e[2]) end
