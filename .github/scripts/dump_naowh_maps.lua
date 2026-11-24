-- Liest Naowhs Maps.lua (nur Daten) und gibt TSV aus.
NaowhForever = { Journal = {} }
local f = assert(loadfile(arg[1]))
setfenv(f, setmetatable({ _G = { NaowhForever = NaowhForever } }, { __index = _G }))
f()
local M = NaowhForever.Journal.Maps
local keys = {}
for k in pairs(M) do keys[#keys + 1] = k end
table.sort(keys)
for _, k in ipairs(keys) do
  local m = M[k]
  print(table.concat({ "M", k, tostring(m.image), tostring(m.floors), tostring(m.imageBottom or ""), tostring(m.imageRight or "") }, "\t"))
  for i, img in pairs(m.images or {}) do print(table.concat({ "I", k, i, img }, "\t")) end
  for npc, p in pairs(m.pins or {}) do
    print(table.concat({ "P", k, npc, p[1], p[2], p[3] }, "\t"))
  end
end
