--------------------------------------------------
-- WeintCodex :: Gemütlicher Schlafsack - die versteckte Questreihe
--------------------------------------------------
-- Seit 1.4.0.0, auf Wunsch (nach dem Discovery-Bereich von Naowh Forever,
-- dort "all rights reserved" - übernommen sind nur Fakten: Objektnamen,
-- Questnummern, Karten und Koordinaten; die Hinweise sind eigene Sätze).
-- Die Daten dort stammen von Wowhead Forever (Quests, Objekte, Fundorte)
-- und dessen Leitfaden (Kletterwege), Stand 04.10.2026.
--
-- HERKUNFT `community`. OB ein Schritt erledigt ist, sagt der Client: jeder
-- Klick auf ein Objekt gibt eine versteckte Quest ab
-- (C_QuestLog.IsQuestFlaggedCompleted). Der erste Schritt beginnt die Reihe
-- (`started`: erledigt, sobald die Quest angenommen oder abgeschlossen ist).
--
-- Schritt: { object = englischer Name (der Client nennt keinen), map, x, y
--            (Prozent), place = Ort, tip = wie man hinkommt, done/started }
--------------------------------------------------

WeintCodex = WeintCodex or {}

local LITTER = { object = "Pocket Litter", map = 1442, x = 40.8, y = 52.6, done = 79192,
    place = "Verlassenes Lager",
    tip = "Den Pfad nordöstlich von Sun Rock Retreat hinauf; es liegt oben auf einer Kiste." }
local DIRT = { object = "Mound of Dirt", map = 1442, x = 39.6, y = 49.9, done = 79980,
    place = "Felsvorsprung nördlich des Lagers",
    tip = "Vom Lager gerade nach Norden den Hügel hoch und von der Kante hinüberspringen." }
local FIGURINE = { object = "Carved Figurine", map = 1432, x = 49.5, y = 12.8, done = 79974,
    place = "Stonewrought Dam",
    tip = "Auf die gemeißelten Köpfe springen, die zum Sumpfland schauen." }
local MESSENGER = { object = "Messenger Bag", map = 1417, x = 22.5, y = 24.2, done = 79975,
    place = "In Thoradins Wall",
    tip = "Von der Karre auf der Seite des Vorgebirges (Hillsbrad 87,3; 49,6) in die Mauer klettern; "
       .. "die Tasche hängt außen, rechts." }
local SATCHEL = { object = "Hastily Rolled-Up Satchel", map = 1417, x = 22.5, y = 24.2, done = 79976,
    place = "Unter der Messenger Bag",
    tip = "Direkt unter der Tasche. Darin liegt der Schlafsack." }

WeintCodex.SleepingBagData = {
    source = { kind = "community", date = "04.10.2026" },
    level = 14,
    item  = 211527,
    steps = {
        Alliance = {
            { object = "Burned-Out Remains", map = 1436, x = 37.5, y = 50.7, started = 79008,
              place = "Alexston-Hof", tip = "Die Reste einer Karre im Schutt." },
            { object = "Burned-Out Remains", map = 1413, x = 46.4, y = 73.9, done = 79008,
              place = "Abgebrannter Turm südlich von Camp Taurajo", tip = "Der Straße südlich von Camp Taurajo folgen." },
            LITTER, DIRT, FIGURINE, MESSENGER, SATCHEL,
        },
        Horde = {
            { object = "Burned-Out Remains", map = 1413, x = 46.4, y = 73.9, started = 79007,
              place = "Abgebrannter Turm südlich von Camp Taurajo", tip = "Der Straße südlich von Camp Taurajo folgen." },
            { object = "Burned-Out Remains", map = 1436, x = 37.5, y = 50.7, done = 79007,
              place = "Alexston-Hof", tip = "Die Reste einer Karre im Schutt." },
            LITTER, DIRT, FIGURINE, MESSENGER, SATCHEL,
        },
    },
    -- Nebenbei, für den Schlafsack nicht nötig.
    optional = { object = "Firepit", map = 1442, x = 40.6, y = 52.4, done = 80001, quest = "Rekindle",
        place = "Verlassenes Lager",
        tip = "Mit Simple Wood und Flint and Tinder aus dem Pocket Litter anzünden. Für den Schlafsack nicht nötig." },
}
