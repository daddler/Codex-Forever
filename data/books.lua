--------------------------------------------------
-- WeintCodex :: Buecher der Bibliothek
--------------------------------------------------
-- ERZEUGT von .github/scripts/import_foreverguide.py - nicht von Hand
-- aendern; neu erzeugen.
--
-- HERKUNFT `community`: das Addon ForeverGuide 1.36.0 (Quest- und
-- Gegenstandsnummern aus der Questie-Datenbank, abgeglichen mit der Beta).
-- Nur Fakten: Abgabequest, Gegenstand, Fraktion, englischer Name (im Spiel
-- nennt der Client seinen), Fundort; Belohnungsquests ab 10/20/25 Buechern.
-- OB ein Buch abgegeben ist, fragt WeintCodex den Client - nie der Bestand.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.BooksData = {
    source = { kind = "community", date = "17.10.2026" },
    -- { Abgabequest, Gegenstand, Fraktion (0 beide, 1 Allianz, 2 Horde), Name, Karte, x, y }
    books = {
        { 79095, 208185, 2, "The Apothecary's Metaphysical Primer", 1420, 59.4, 52.3 },
        { 78127, 209844, 0, "The Dalaran Digest, Vol. 23", 1421, 63.5, 63.1 },
        { 79094, 207972, 2, "The Lessons of Ta'zo", 1454, 38.7, 78.4 },
        { 78145, 209847, 0, "Arcanic Systems Manual", 1413, 56.3, 8.8 },
        { 79097, 208800, 0, "Baxtan: On Destructive Magics", 1413, 62.7, 36.3 },
        { 78143, 209846, 0, "Secrets of the Dreamers", 1413, 46, 36.5 },
        { 78149, 209851, 0, "Fury of the Land", 1442, 74.4, 85.7 },
        { 79947, 215683, 0, "Geomancy: The Stone-Cold Truth", 1441, 34.4, 40.1 },
        { 79952, 215822, 0, "RwlRwlRwlRwl!", 1445, 57.2, 20.8 },
        { 78124, 209843, 0, "Nar'thalas Almanac, Vol. 74", 1439, 59.6, 22.2 },
        { 79535, 213165, 0, "Basilisks: Should Petrification be Feared?", 1434, 41.4, 50.9 },
        { 78147, 209849, 0, "Crimes Against Anatomy", 1431, 16.6, 28.5 },
        { 78142, 209845, 0, "Bewitchments and Glamours", 1436, 45.4, 70.4 },
        { 79948, 215815, 0, "Defensive Magics 101", 1416, 48.4, 57.6 },
        { 79949, 215816, 0, "A Web of Lies: Debunking Myths and Legends", 1417, 73.6, 65.2 },
        { 78146, 209848, 0, "Goaz Scrolls", 1437, 33.6, 47.9 },
        { 78148, 209850, 0, "Runes of the Sorcerer-Kings", 1432, 77.4, 14 },
        { 81947, 220345, 0, "Sanguine Sorcery", 1435, 70, 51 },
        { 79951, 215820, 0, "Mummies: A Guide to the Unsavory Undead", 1418, 56.7, 39.9 },
        { 79950, 215817, 0, "Demons and You", 1443, 55.1, 26.2 },
        { 81953, 220349, 0, "Stonewrought Design", 1428, 29, 28.9 },
        { 81949, 220346, 0, "Legends of the Tidesages", 1446, 72.7, 47.8 },
        { 81952, 220348, 0, "Everyday Etiquette", 1447, 20.7, 62 },
        { 81954, 220350, 0, "Venomous Journeys", 1425, 36, 72.8 },
        { 81955, 220352, 0, "A Mind of Metal", 1427, 37.8, 49.3 },
        { 81956, 220353, 0, "Conjurer's Codex", 1419, 55.4, 32.2 },
        { 79092, 203755, 1, "Archmage Theocritus' Research Journal", 1429, 65.4, 70.1 },
        { 79091, 203754, 1, "Archmage Antonidas: The Unabridged Autobiography", 1455, 75.7, 10.5 },
        { 79093, 208860, 1, "Rumi of Gnomeregan: The Collected Works", 1432, 35.6, 48.9 },
        { 84395, 228132, 0, "Undead Potatoes", 1422, 38.2, 54.6 },
        { 84396, 228133, 0, "Magma or Lava?", 1428, 26.4, 24.5 },
        { 84397, 228134, 0, "Northern Kalimdor - A Comprehensive Guide", 1448, 65.2, 3.3 },
        { 84398, 228135, 0, "A Study of the Light", 1423, 71.9, 48.3 },
        { 84399, 228136, 0, "Ka-Boom!", 1452, 60.7, 37.7 },
        { 84400, 228138, 0, "The Knight and the Lady", 1423, 47.3, 42.2 },
        { 84401, 228140, 0, "Scourge: Undead Menace or Misunderstood?", 1423, 26.4, 15.1 },
        { 84402, 228141, 0, "Necromancy 101", 1422, 69.4, 72.8 },
    },
    rewards = {
        { key = "neck", goal = 10, quest = 78150, minLevel = 0, items = { 277203, 277204 } },
        { key = "ring", goal = 20, quest = 79536, minLevel = 0, items = { 281634, 281635 } },
        { key = "library25", goal = 25, quest = 82208, minLevel = 30, items = { 277254, 277258, 277260 } },
    },
    librarians = {
        Alliance = { npc = 211033, name = "Garion Wendell", map = 1453, x = 49, y = 86.4 },
        Horde = { npc = 211022, name = "Owen Thadd", map = 1458, x = 74, y = 32.4 },
    },
}
