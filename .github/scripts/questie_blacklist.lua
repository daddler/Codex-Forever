-- Wertet die Sperrliste der Quests von Questie aus (Database/Corrections/
-- QuestieQuestBlacklist.lua) wie Questie auf Forever: Expansions.Current =
-- Era. Schreibt die gesperrten Quest-IDs durch Komma. Nur Daten, kein Code
-- von Questie laeuft ausser dieser einen Tabellendatei.
-- Aufruf: lua5.1 .github/scripts/questie_blacklist.lua <Datei>
-- Benutzt von .github/scripts/import_questdb.py.
local path = arg[1]
local mods = {}
QuestieLoader = { CreateModule = function(_, n) mods[n] = mods[n] or {} return mods[n] end,
                  ImportModule = function(_, n) mods[n] = mods[n] or {} return mods[n] end }
local E = QuestieLoader:ImportModule("Expansions")
E.Era, E.Tbc, E.Wotlk, E.Cata, E.MoP, E.Current = 1, 2, 3, 4, 5, 1
local CP = QuestieLoader:ImportModule("ContentPhases")
CP.activePhases = setmetatable({}, { __index = function() return {} end })
Questie = { Debug = function() end, IsForever = true }
dofile(path)
local t = mods.QuestieQuestBlacklist:Load()
local ids = {}
for id, v in pairs(t) do if v then ids[#ids + 1] = id end end
-- 1.0.0.8: Questie blendet ausserdem ab Werk aus: Kriegsanstrengung von
-- Ahn'Qiraj (showAQWarEffortQuests = false) und Invasionen ausserhalb
-- ihrer Phase. Beide gibt es auf Forever nicht.
for _, list in ipairs({ mods.QuestieQuestBlacklist.AQWarEffortQuests or {}, mods.QuestieQuestBlacklist.InvasionQuests or {} }) do
    for id, v in pairs(list) do if v and not t[id] then ids[#ids + 1] = id end end
end
table.sort(ids)
io.write(table.concat(ids, ","), "\n")
