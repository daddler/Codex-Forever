--------------------------------------------------
-- WeintCodex :: Einstimmungen und Schluessel
--------------------------------------------------
-- 1.0.7.0 (Wunsch nach dem Vergleich mit Naowh Forever "Attunements").
-- Je Zugang die Quest, die ihn gibt (Schluessel oder Einstimmung), je
-- Fraktion. Die Kette davor liest ui/attunements.lua aus der
-- Questdatenbank (data/questdb.lua: "alle vorher" / "eine vorher").
-- HERKUNFT `community`: Zugaenge und Quests wie in Classic, von Naowh
-- Forever 1.2.33 fuer Forever gefuehrt - nicht im Spiel gegengeprueft.
--   key   = Gegenstand (Schluessel), falls es einen gibt
--   quest = Nummer, oder { A = Allianz, H = Horde }
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.AttunementData = {
    SOURCE = { kind = "community", label = "Zugänge wie in Classic" },
    list = {
        { id = "maraudon",        name = "Maraudon",               key = 17191, quest = 7046 },
        { id = "brd",             name = "Schwarzfelstiefen",      key = 11000, quest = 3802 },
        { id = "scholomance",     name = "Scholomance",            key = 13704, quest = { A = 5505, H = 5511 } },
        { id = "ubrs",            name = "Obere Schwarzfelsspitze", key = 12344, quest = 4743 },
        { id = "molten_core",     name = "Geschmolzener Kern",     quest = 7848 },
        { id = "onyxia",          name = "Onyxias Hort",           key = 16309, quest = { A = 6502, H = 6602 } },
    },
}
