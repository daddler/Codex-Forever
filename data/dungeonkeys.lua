--------------------------------------------------
-- WeintCodex :: Schluessel der Dungeons (1.0.8.0)
--------------------------------------------------
-- Was ein Dungeon zum Betreten braucht (need = true) oder welche
-- Abkuerzung ein Schluessel oeffnet. Gegenstandsnummern und Fakten aus
-- OneForAll 6.2.13 (Data/DungeonKeys.lua, GPL-3.0 - nur Daten; dort aus
-- QuestieDB Forever und den Gegenstandsdaten, Stand Oktober 2026), die Saetze
-- hier selbst geschrieben. Art `community`: von Spielern gesammelt.
-- Namen der Gegenstaende nennt der Client - kein Name wird hier geraten.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.DungeonKeys = {
    scarlet_monastery = {
        { item = 7146, need = true, text = "Öffnet Waffenkammer und Kathedrale. Liegt in der Truhe hinter Arkanist Doan am Ende der Bibliothek; einer in der Gruppe reicht." },
    },
    scholomance = {
        { item = 13704, need = true, text = "Öffnet das Tor in Caer Darrow. Eine Questreihe ab Stufe 50 – Allianz in den Westlichen Pestländern, Horde in Tirisfal – bis zum Schmied in Gadgetzan." },
    },
    upper_blackrock_spire = {
        { item = 12344, need = true, text = "Ein schmuckloses Siegel und drei Edelsteine aus der Unteren Schwarzfelsspitze, geschmiedet beim Drachen in den Düstermarschen." },
    },
    dire_maul = {
        { item = 18249, need = true, text = "Öffnet West und Nord, auch die Seitentür der Gordok. Einer in der Gruppe reicht." },
    },
    blackrock_depths = {
        { item = 11000, need = false, text = "Öffnet die Tore der Schattenschmiede – ohne ihn braucht es einen Schurken." },
        { item = 11140, need = false, text = "Öffnet die Zellen im Gefängnistrakt." },
    },
    stratholme = {
        { item = 12382, need = false, text = "Öffnet die Tore zwischen beiden Hälften der Stadt. Beide Eingänge gehen auch ohne ihn." },
    },
    gnomeregan = {
        { item = 6893, need = false, text = "Öffnet den Seiteneingang der Werkstatt und Türen im Inneren." },
    },
    maraudon = {
        { item = 17191, need = false, text = "Öffnet das Portal vom Eingang direkt zu den Fällen von Prinzessin Theradras." },
    },
    kroldok_stronghold = {
        { item = 267089, need = false, text = "Zum Betreten nicht nötig. Tunk lässt eine Gussform fallen; ein Schmied in Farholde Keep (Allianz) oder Rog'mar (Horde) macht daraus den Schlüssel – für 4 Dickes Leder und 12 Eisenbarren." },
    },
    city_of_dalaran = {
        { item = 277507, need = true, text = "Öffnet den Eingang durch die Kanalisation am Lordamere-See. Es gibt ihn über eine Quest beim Abbild der Erzmagierin Modera; die Allianz kommt mit einer Vorquest hin, die Horde über die Quests von Magus Wordeen Voidglare in Tarrens Mühle." },
    },
}
