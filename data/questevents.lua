--------------------------------------------------
-- WeintCodex :: Questhilfe - Quests der Feste und des Jahrmarkts (6.37.0.0)
--------------------------------------------------
-- Welche Quest zu welchem Fest gehoert. Die Zuordnung ist Wissen aus
-- Classic (Art `classic`): Kennungen der Quests wie im Bestand
-- data/questdb.lua, nur die, die dort stehen. Ob ein Fest gerade laeuft,
-- sagt der Kalender des Spiels (ui/questhelper.lua, QH.ActiveEvents) -
-- `words` sind Teile seines Namens dort (deutsch und englisch).
-- Erzeugt einmal aus der Liste in der Beschreibung von 6.37.0.0; von Hand
-- gepflegt.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.QuestEvents = {
    { key = "lunar", name = "Mondfest", words = { "mondfest", "lunar festival" },
      quests = { 8619, 8635, 8636, 8642, 8643, 8644, 8645, 8646, 8647, 8648, 8649, 8650, 8651, 8652, 8653, 8654, 8672, 8673, 8674, 8678, 8679, 8681, 8682, 8684, 8686, 8688, 8715, 8716, 8717, 8718, 8720, 8723, 8727, 8866, 8860, 8861, 8862, 8863, 8864, 8865, 8866, 8867, 8868, 8869, 8870, 8871, 8872, 8873, 8874, 8875, 8876, 8877, 8878, 8879, 8880, 8881, 8882, 8883 } },
    { key = "love", name = "Liebe liegt in der Luft", words = { "liebe liegt in der luft", "love is in the air" },
      quests = { 8897, 8898, 8899, 8900, 8901, 8902, 8903, 8904 } },
    { key = "children", name = "Kinderwoche", words = { "kinderwoche", "children's week" },
      quests = { 171, 172, 1468, 5502, 1479, 1558, 1687, 1800, 910, 911, 915, 925, 4822 } },
    { key = "midsummer", name = "Sonnenwendfest", words = { "sonnenwend", "midsummer" },
      quests = { 9322, 9323, 9324, 9325, 9326, 9330, 9331, 9332, 9339, 9365, 9367, 9368, 9388, 9389 } },
    { key = "harvest", name = "Erntedankfest", words = { "erntedank", "harvest festival" },
      quests = { 8149, 8150 } },
    { key = "hallow", name = "Schlotternächte", words = { "schlotternächte", "schlotternacht", "hallow's end" },
      quests = { 1657, 1658, 8311, 8312, 8322, 8353, 8354, 8355, 8356, 8357, 8358, 8359, 8360, 8373, 8409 } },
    { key = "winterveil", name = "Winterhauchfest", words = { "winterhauch", "winter veil" },
      quests = { 6961, 6962, 6963, 6964, 6983, 6984, 7021, 7022, 7023, 7024, 7025, 7042, 7043, 7045, 7061, 7062, 7063, 8744, 8746, 8762, 8763, 8767, 8768, 8769, 8788, 8799, 8803 } },
    { key = "darkmoon", name = "Dunkelmond-Jahrmarkt", words = { "dunkelmond", "darkmoon" },
      quests = { 7881, 7882, 7883, 7884, 7885, 7886, 7887, 7888, 7889, 7890, 7891, 7892, 7893, 7894, 7895, 7896, 7897, 7898, 7899, 7900, 7901, 7902, 7903, 7905, 7907, 7921, 7922, 7923, 7924, 7925, 7926, 7927, 7928, 7929, 7930, 7931, 7932, 7933, 7934, 7935, 7936, 7937, 7938, 7939, 7940, 7941, 7942, 7943, 7944, 7945, 7946 } },
}
