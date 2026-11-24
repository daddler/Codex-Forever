--------------------------------------------------
-- WeintCodex :: Klassenquests - Belohnungen in Forever (1.0.8.23)
--------------------------------------------------
-- ERZEUGT von .github/scripts/import_classquest_rewards.lua - nicht von Hand.
-- Herkunft (nur fuer Betreuer): OneForAll 6.2.13 (GPL-3.0, nur Daten),
-- Data/QuestRewards.lua, dort aus QuestieDB Forever. Nur Ausruestung, die
-- dem Bestand (Belohnungen aus Classic) fehlt; fest/zur Wahl unbekannt.
-- Art `community`.
--------------------------------------------------

local Q = WeintCodex and WeintCodex.ClassQuestData
if not Q then return end
Q.FOREVER_REWARDS = {
    [31] = { 263411 },
    [1527] = { 263412 },
    [5061] = { 263411 },
    [79442] = { 280604 },
    [96016] = { 280604 },
}
