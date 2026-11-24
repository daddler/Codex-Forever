-- WeintCodex :: Belohnungen der Klassenquests aus Forever (1.0.8.23)
--
--   lua5.1 .github/scripts/import_classquest_rewards.lua <OneForAll-Ordner> <Codex-Ordner>
--
-- Wunsch: "die Belohnungen der Klassenquests anzeigen, um zu sehen, ob sich
-- eine Klassenquest lohnt". Der Bestand (data/classquests.lua) hat die
-- Belohnungen aus Classic. OneForAll 6.2.13 (GPL-3.0, nur DATEN) fuehrt in
-- Data/QuestRewards.lua die Ausruestung, die Quests in Forever geben - dort
-- aus QuestieDB Forever. Uebernommen wird nur, was dem Bestand bei einer
-- Klassenquest FEHLT (z. B. die neuen Totems und Goetzen); fest oder zur
-- Wahl sagt die Quelle nicht.
--
-- Schreibt data/classquests_rewards.lua: Q.FOREVER_REWARDS[Quest] = { Gegenstand, ... }

local OFA, CDX = arg[1], arg[2]
assert(OFA and CDX, "Aufruf: import_classquest_rewards.lua <OneForAll> <Codex>")

local FLT = {}
assert(loadfile(OFA .. "/Data/QuestRewards.lua"))("OneForAll", FLT)
local src = assert(FLT.QUEST_REWARDS and FLT.QUEST_REWARDS.items, "QUEST_REWARDS.items fehlt")
local byQuest = {}
for line in src:gmatch("[^\n]+") do
    local it, qs = line:match("^(%d+),%d+,([%d/]+),")
    if it then
        for q in qs:gmatch("%d+") do
            q = tonumber(q)
            byQuest[q] = byQuest[q] or {}
            byQuest[q][#byQuest[q] + 1] = tonumber(it)
        end
    end
end

WeintCodex = {}
dofile(CDX .. "/data/classquests.lua")
dofile(CDX .. "/data/classquests_ofa.lua")
local Q = WeintCodex.ClassQuestData
local out, n = {}, 0
for _, cls in ipairs({ "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID" }) do
    for _, q in ipairs(Q.CLASSES[cls] or {}) do
        local have = {}
        for _, i in ipairs(q.items or {}) do have[i] = true end
        for _, i in ipairs(q.choice or {}) do have[i] = true end
        local add = {}
        for _, i in ipairs(byQuest[q.id] or {}) do
            if not have[i] then have[i] = true add[#add + 1] = i end
        end
        if #add > 0 and not out[q.id] then
            table.sort(add)
            out[q.id] = add
            n = n + 1
        end
    end
end
local ids = {}
for q in pairs(out) do ids[#ids + 1] = q end
table.sort(ids)
local L = {
    "--------------------------------------------------",
    "-- WeintCodex :: Klassenquests - Belohnungen in Forever (1.0.8.23)",
    "--------------------------------------------------",
    "-- ERZEUGT von .github/scripts/import_classquest_rewards.lua - nicht von Hand.",
    "-- Herkunft (nur fuer Betreuer): OneForAll 6.2.13 (GPL-3.0, nur Daten),",
    "-- Data/QuestRewards.lua, dort aus QuestieDB Forever. Nur Ausruestung, die",
    "-- dem Bestand (Belohnungen aus Classic) fehlt; fest/zur Wahl unbekannt.",
    "-- Art `community`.",
    "--------------------------------------------------",
    "",
    "local Q = WeintCodex and WeintCodex.ClassQuestData",
    "if not Q then return end",
    "Q.FOREVER_REWARDS = {",
}
for _, q in ipairs(ids) do
    local t = {}
    for _, i in ipairs(out[q]) do t[#t + 1] = tostring(i) end
    L[#L + 1] = string.format("    [%d] = { %s },", q, table.concat(t, ", "))
end
L[#L + 1] = "}"
local fh = assert(io.open(CDX .. "/data/classquests_rewards.lua", "w"))
fh:write(table.concat(L, "\n"), "\n")
fh:close()
print(string.format("Klassenquests mit Belohnungen aus Forever: %d", n))
