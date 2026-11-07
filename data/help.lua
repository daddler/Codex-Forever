--------------------------------------------------
-- WeintCodex :: Hilfe je Seite und Schlagwoerter (1.0.5.5)
--------------------------------------------------
-- Wunsch (Spieler): "Die Tour beschreibt alles, beim 3. oder 4. Punkt habe
-- ich den ersten nicht mehr am Schirm. Informationen bei den Reitern
-- direkt aufrufen, oder eine Hilfesuche mit Schlagwoertern."
--
-- PAGES: je Seite zwei, drei Saetze - was sie tut, womit man anfaengt.
--   Schluessel "nav:<Reiter>" fuer das Codex-Fenster, "<Modul>/<Seite>"
--   fuer die Einstellungen der Oberflaeche (/wcui). words: weitere
--   Suchwoerter, die im Text nicht stehen.
-- SYNONYMS: Wort, das Spieler tippen -> Woerter, die in WeintCodex stehen.
--   Klein geschrieben; Umlaute so, wie sie im Spiel stehen.
--
-- Nur Verhalten von WeintCodex - nie Taktiken, nie fremde Addon-Namen.
--------------------------------------------------

WeintCodex = WeintCodex or {}

local P = {}

-- Codex-Fenster (/wc)
P["nav:uebersicht"] = { title = "Übersicht",
    text = "Was als Nächstes ansteht: Erfahrung bis zur nächsten Stufe, lernbare Zauber, offene Dinge. Darunter „Dein Weg“ über die Stufen.",
    words = "start home anfang startseite" }
P["nav:charakter"] = { title = "Charakter",
    text = "Ausrüstung und Gegenstandsstufe deiner Charaktere, auch der Twinks. Was der Client nicht verrät, bleibt leer statt 0.",
    words = "ausrüstung gear twink itemlevel ilvl" }
P["nav:lehrer"] = { title = "Lehrer",
    text = "Welche Zauber du beim Lehrer lernen kannst und was sie kosten. Reiter „Klassenquests“, für Jäger auch „Wildtierkunde“.",
    words = "trainer zauber lernen klassenquest wildtier jäger begleiter fähigkeiten" }
P["nav:berufe"] = { title = "Berufe",
    text = "Deine Berufe und Rezepte, auch die der Twinks, und wo man fehlende Rezepte bekommt. Gelernt zählt erst, wenn du das Berufsfenster einmal geöffnet hast.",
    words = "rezept rezepte handwerk crafting skill skillen profession" }
P["nav:taschen"] = { title = "Taschen",
    text = "Was alle deine Charaktere in Taschen, Bank und Ausrüstung haben. Die Bank zählt erst, wenn du sie einmal geöffnet hast.",
    words = "bestand inventar bank lager twink gegenstände" }
P["nav:buecher"] = { title = "Entdecken",
    text = "Bücher der Bibliothek und der Gemütliche Schlafsack: was du schon hast und welcher Schritt fehlt.",
    words = "bücher bibliothek schlafsack sammeln" }
P["nav:dungeons"] = { title = "Dungeons",
    text = "Alle Dungeons mit Stufenbereich, Bossen, Beute und Quests. Links den Dungeon wählen, auf der Seite den Boss.",
    words = "instanz ini boss bosse dungeon quests" }
P["nav:beute"] = { title = "Beute",
    text = "Beute aus Dungeons und Schlachtzügen zum Nachschlagen, mit Wunschliste. Keine Wertung, was besser ist.",
    words = "loot drop wunschliste items" }
P["nav:gruppe"] = { title = "Gruppencheck",
    text = "Prüft vor dem Pull, ob in der Gruppe alle da sind und was fehlt. Mit /wc gruppe prüfen sofort.",
    words = "gruppe check ready bereit" }
P["nav:raids"] = { title = "Schlachtzüge",
    text = "Die Schlachtzüge mit Bossen, soweit bekannt, und dein Fortschritt. Leere Listen sind Absicht: es gibt noch keine Quelle.",
    words = "raid raids schlachtzug lockout" }
P["nav:anmeldung"] = { title = "Raidplanung",
    text = "Anmeldung und Kalender der Gilde, aus dem Discord über die Companion.",
    words = "anmeldung kalender termin raid discord" }
P["nav:materialien"] = { title = "Materialien",
    text = "Was die Gilde an Material sammelt. Die Liste füllt sich erst, wenn die Gilde Ziele setzt.",
    words = "material farm gildenbank" }
P["nav:companion"] = { title = "Companion",
    text = "Verbindung zur WeintCompanion auf dem Rechner und zum Discord. Reiter „Import“ nimmt einen WCIMPORT-Text an.",
    words = "discord import companion bot sync" }

P["nav:settings"] = { title = "Einstellungen",
    text = "Wie sich das Codex-Fenster verhält (Esc, Größe, Symbol an der Minikarte) und die Diagnose. Die Oberfläche selbst stellst du mit /wcui ein.",
    words = "einstellung optionen diagnose fenster esc" }

-- Oberflaeche (/wcui)
P["general/allgemein"] = { title = "Oberfläche · Allgemein",
    text = "Hauptschalter der Oberfläche und Aussehen. Neu laden ist nötig, damit der Hauptschalter wirkt.",
    words = "hauptschalter aussehen look design neuladen" }
P["general/glanz"] = { title = "Oberfläche · Glanz",
    text = "Leuchten an Einheitenrahmen, Gruppenrahmen, Zauberleiste und Erfahrungsbalken – an oder aus, und wo.",
    words = "animation leuchten effekte" }
P["general/ruhe"] = { title = "Oberfläche · Ruhe und Kampf",
    text = "Was außerhalb des Kampfes ausgeblendet oder abgedunkelt wird. Im Kampf ist alles da.",
    words = "ausblenden verstecken kampf transparenz fade" }
P["general/profile"] = { title = "Oberfläche · Profile",
    text = "Einstellungen je Charakter oder geteilt. Ein Profil wechselt erst nach dem Neuladen.",
    words = "profil kopieren teilen charakter" }
P["general/tooltip"] = { title = "Oberfläche · Tooltip & Fenster",
    text = "Tooltip und die Fenster des Spiels im WeintCodex-Stil, Rand in Klassen- oder Qualitätsfarbe.",
    words = "tooltip fenster verschieben skin" }
P["nameplates/allgemein"] = { title = "Namensplaketten · Allgemein",
    text = "Größe und Grundform der Plaketten über den Köpfen. Hier anfangen.",
    words = "nameplates plaketten namensplakette größe" }
P["nameplates/farben"] = { title = "Namensplaketten · Bedrohung & Farben",
    text = "Farbe nach Bedrohung: wer Aggro hat, wer gleich übernimmt. Für Tanks und Schadensklassen getrennt.",
    words = "aggro threat tank farbe" }
P["nameplates/texte"] = { title = "Namensplaketten · Texte", text = "Name, Stufe und Lebenszahl an den Plaketten.", words = "name stufe leben prozent" }
P["nameplates/auren"] = { title = "Namensplaketten · Auren", text = "Welche Debuffs und Buffs an den Plaketten stehen.", words = "debuff buff dots" }
P["nameplates/freundlich"] = { title = "Namensplaketten · Freundlich", text = "Plaketten für Verbündete, in Instanzen nur Namen.", words = "freund verbündete gruppe" }
P["nameplates/kombo"] = { title = "Namensplaketten · Kombopunkte", text = "Kombopunkte an der Plakette des Ziels.", words = "schurke combo kombo" }
P["nameplates/zauber"] = { title = "Namensplaketten · Zauberbalken", text = "Zauberbalken der Gegner, unterbrechbare hervorgehoben.", words = "cast castbar kick unterbrechen" }
P["nameplates/npcs"] = { title = "Namensplaketten · NPCs", text = "Eigene Farben für bestimmte Gegner.", words = "gegner farbe mob" }
P["unitframes/allgemein"] = { title = "Einheitenrahmen · Allgemein",
    text = "Rahmen für Spieler, Ziel, Fokus und Begleiter. Hier Größe und Stil für alle, auf den Reitern je Rahmen.",
    words = "unitframes rahmen spielerrahmen zielrahmen" }
P["unitframes/player"] = { title = "Einheitenrahmen · Spieler", text = "Dein eigener Rahmen.", words = "spieler" }
P["unitframes/target"] = { title = "Einheitenrahmen · Ziel", text = "Rahmen deines Ziels.", words = "target" }
P["unitframes/targettarget"] = { title = "Einheitenrahmen · Ziel des Ziels", text = "Wen dein Ziel gerade angreift.", words = "tot" }
P["unitframes/focus"] = { title = "Einheitenrahmen · Fokus", text = "Rahmen des Fokusziels.", words = "fokus focus" }
P["unitframes/pet"] = { title = "Einheitenrahmen · Begleiter", text = "Rahmen deines Begleiters.", words = "pet tier" }
P["groupframes/allgemein"] = { title = "Gruppenrahmen · Allgemein",
    text = "Rahmen für Gruppe und Schlachtzug. Für Heiler: Klickzauber stellst du unter Komfort → Klickzauber ein.",
    words = "raidframes partyframes heiler heilen" }
P["groupframes/gruppe"] = { title = "Gruppenrahmen · Gruppe", text = "Rahmen der Fünfergruppe.", words = "party" }
P["groupframes/raid"] = { title = "Gruppenrahmen · Schlachtzug", text = "Rahmen im Schlachtzug.", words = "raid" }
P["groupframes/gruppenwerkzeuge"] = { title = "Gruppenrahmen · Gruppenwerkzeuge", text = "Die Leiste der Gruppenwerkzeuge: eingeklappt, erst bei Mausberührung, Menü des Spiels ausblenden.", words = "marker ready pull" }
P["actionbars/allgemein"] = { title = "Aktionsleisten · Allgemein",
    text = "Aussehen der Aktionsleisten. Welche Leisten es gibt, schaltet das Spiel ein (Optionen → Aktionsleisten).",
    words = "leiste leisten actionbar tasten hotkey" }
P["actionbars/leisten"] = { title = "Aktionsleisten · Leisten", text = "Jede Leiste einzeln: Größe, Abstand, Ausblenden.", words = "leiste" }
P["actionbars/erfahrung"] = { title = "Aktionsleisten · Erfahrung", text = "Erfahrungs- und Rufbalken.", words = "xp exp ruf erfahrungsbalken" }
P["minimap/allgemein"] = { title = "Minikarte · Allgemein", text = "Form, Größe und Knöpfe der Minikarte.", words = "minimap karte" }
P["minimap/layer"] = { title = "Minikarte · Layer", text = "Layer anzeigen und auf Klick um einen anderen Layer bitten.", words = "layer phase wechseln" }
P["chat/allgemein"] = { title = "Chat · Allgemein", text = "Schriftgröße, Hintergrund, flache Reiter, Eingabezeile erst mit Enter.", words = "chat kopieren" }
P["chat/info"] = { title = "Chat · Infozeile", text = "Zeile mit Zeit, Gold, Taschenplätzen, Haltbarkeit, Bildrate – unter dem Chat, unter oder über der Minikarte. Die Werte in Ampelfarben.", words = "info uhr gold koordinaten" }
P["questarrow/allgemein"] = { title = "Questpfeil",
    text = "Pfeil zum nächsten Questziel, Zielmarke im Raum, Kompass.",
    words = "pfeil wegpunkt navi navigation route weg" }
P["bags/allgemein"] = { title = "Taschen · Allgemein", text = "Eine große Tasche statt vieler kleiner.", words = "tasche bag inventar" }
P["bags/kategorien"] = { title = "Taschen · Kategorien",
    text = "Gegenstände nach Art gruppiert (Ausrüstung, Material, Quest …), Spezialtaschen als eigener Block.",
    words = "sortieren ordnen kategorie munition köcher" }
P["damagemeter/allgemein"] = { title = "Schadensanzeige · Allgemein", text = "Schaden, Heilung und Bedrohung der Gruppe.", words = "dps meter damage heilung" }
P["damagemeter/fenster"] = { title = "Schadensanzeige · Je Fenster", text = "Mehrere Fenster mit eigener Messart.", words = "fenster" }
P["reminders/regeln"] = { title = "Erinnerungen · Regeln",
    text = "Was fehlen darf, bevor WeintCodex erinnert: Buffs, Essen, Waffe, Begleiter, Munition, Talentpunkte. Jede Regel einzeln an und aus.",
    words = "buff fehlt essen food erinnern talent munition" }
P["reminders/essen"] = { title = "Erinnerungen · Essen",
    text = "Erinnert, wenn Buff-Essen in der Tasche liegt und du nicht satt bist – mit eigenen Schaltern: wo, auch in Stadt und Gasthaus, erst mit Gegner. Ab Werk an.",
    words = "essen food satt wohlgenährt buff essensbuff erfahrung" }
P["reminders/buffzeiten"] = { title = "Erinnerungen · Buffzeiten", text = "Restzeit eigener Buffs.", words = "buff zeit dauer" }
P["reminders/anzeige"] = { title = "Erinnerungen · Anzeige", text = "Wo und wie groß die Symbole stehen.", words = "symbol" }
P["reminders/abklingzeitmanager"] = { title = "Erinnerungen · Abklingzeitmanager", text = "Abklingzeiten und Procs als Leisten.", words = "cooldown cd proc" }
P["comfort/automatik"] = { title = "Komfort · Automatik",
    text = "Kleine Arbeiten von selbst: reparieren (auch aus der Gildenbank), graue Gegenstände verkaufen, schneller plündern, Filmsequenzen überspringen. Jeder Schalter einzeln.",
    words = "reparieren verkaufen grau schrott automatisch auto" }
P["comfort/anzeigen"] = { title = "Komfort · Anzeigen", text = "Zusätzliche Hinweise: Kampfbeginn, Bildrate und Latenz, Haltbarkeit, Würfe in der Gruppe, Neues beim Lehrer.", words = "anzeige" }
P["comfort/zeiger"] = { title = "Komfort · Maus & Pfeil",
    text = "Ring oder Schein um den Mauszeiger (Farbe, Größe, nur im Kampf), Größe des Zeigers selbst, und ein eigener großer, farbiger Spielerpfeil auf der Minikarte.",
    words = "maus mauszeiger cursor zeiger finden spielerpfeil minikarte pfeil kreis ring" }
P["comfort/rausda"] = { title = "Komfort · Raus da", text = "Warnton, wenn du in etwas Schädlichem stehst.", words = "boden ton warnung sound" }
P["comfort/automark"] = { title = "Komfort · Automark", text = "Markierungen auf Gegner per Taste über dem Gegner.", words = "markieren marker totenkopf" }
P["comfort/klickzauber"] = { title = "Komfort · Klickzauber",
    text = "Zauber per Klick auf Gruppenrahmen, auch Makros. Erst Taste und Maustaste wählen, dann den Zauber.",
    words = "clickcast heilen klick maus" }
P["comfort/entfluchen"] = { title = "Komfort · Entfluchen", text = "Fluch, Gift, Krankheit per Klick entfernen.", words = "dispel fluch gift krankheit magie" }
P["comfort/makros"] = { title = "Komfort · Makros", text = "Makros zusammenklicken, auch mit Haltung je Zeile.", words = "makro macro haltung" }
P["comfort/ringe"] = { title = "Komfort · Ringe", text = "Ringmenü für Zauber und Gegenstände.", words = "ring menü" }
P["comfort/pvp"] = { title = "Komfort · PvP", text = "Gegnerrahmen in der Arena, Liste im Schlachtfeld, Heiler erkennen.", words = "arena schlachtfeld bg" }
P["comfort/boss"] = { title = "Bosskämpfe · Allgemein",
    text = "Timer und Warnungen im Bosskampf, /pull und /break.",
    words = "bossmod pull timer warnung boss" }
P["comfort/boss_bars"] = { title = "Bosskämpfe · Leisten", text = "Aussehen und Platz der Timerleisten.", words = "leiste timer" }
P["comfort/boss_sounds"] = { title = "Bosskämpfe · Töne", text = "Ton je Anlass: Pull, Warnung, Sieg.", words = "ton sound" }
P["comfort/boss_bosses"] = { title = "Bosskämpfe · Bosse", text = "Je Boss und Fähigkeit: Ton, Warnung, Auslöser.", words = "fähigkeit" }
P["comfort/karte"] = { title = "Komfort · Karte", text = "Auf der Weltkarte: Instanzeingänge, Geistheiler, Flugmeister, Übergänge in andere Gebiete.", words = "weltkarte map aufdecken eingang" }
P["comfort/questhilfe"] = { title = "Komfort · Questhilfe", text = "Questgeber und Ziele auf der Karte.", words = "quest questgeber ausrufezeichen" }
P["comfort/sammeln"] = { title = "Komfort · Sammeln",
    text = "Kräuter- und Erzsuche im Wechsel, Sammel-Atlas, Angeln mit einer Taste, volle Taschen beim Looten.",
    words = "kräuter erz bergbau kräuterkunde angeln fishing farm" }
P["comfort/glitzern"] = { title = "Komfort · Glitzern", text = "Questgegenstände sowie Kräuter und Erz glitzern lassen, damit man sie sieht.", words = "glitzern" }
P["comfort/selten"] = { title = "Komfort · Seltene Gegner", text = "Meldung, wenn ein seltener Gegner in der Nähe ist.", words = "rare elite selten" }
P["comfort/flugspiele"] = { title = "Komfort · Flugspiele", text = "Kleine Spiele auf Flugrouten, mit Bestenliste der Gilde.", words = "flug spiel" }
P["comfort/auktion"] = { title = "Komfort · Auktionshaus", text = "Preise scannen und im Tooltip zeigen.", words = "ah preis preise scan" }
P["comfort/fluestern"] = { title = "Komfort · Flüstern", text = "Flüstern als eigenes Fenster wie ein Messenger.", words = "whisper flüstern nachricht" }
P["comfort/danke"] = { title = "Komfort · Danke", text = "Fremden per Flüstern für Buffs danken – wann, wem und wie schnell.", words = "danke" }
P["comfort/gespraeche"] = { title = "Komfort · Gespräche", text = "Gespräche mit NPCs und Questtexte im eigenen Stil.", words = "gossip dialog npc" }
P["questtracker/allgemein"] = { title = "Questliste", text = "Die Questliste am Bildschirmrand: Deckkraft, Rand, Banner. Im Dungeon auf Wunsch nur dessen Quests.", words = "tracker questliste" }

-- Woerter, die Spieler tippen, und was in WeintCodex dasteht.
local S = {
    aggro = { "bedrohung" }, threat = { "bedrohung" },
    pfeil = { "questpfeil", "spielerpfeil" }, cursor = { "mauszeiger" }, maus = { "mauszeiger" }, navi = { "questpfeil" }, wegpunkt = { "questpfeil" },
    sortieren = { "kategorie" }, ordnen = { "kategorie" },
    tasche = { "taschen" }, bag = { "taschen" }, bags = { "taschen" },
    nameplate = { "plakette" }, nameplates = { "plakette" }, plate = { "plakette" },
    loot = { "beute" }, drop = { "beute" },
    dps = { "schaden" }, meter = { "schadensanzeige" },
    cooldown = { "abklingzeit" }, cd = { "abklingzeit" },
    buff = { "buff", "segen" }, essen = { "essen", "satt" }, food = { "essen" },
    makro = { "makro" }, macro = { "makro" },
    heilen = { "klickzauber", "gruppenrahmen" }, heiler = { "klickzauber", "gruppenrahmen" },
    clickcast = { "klickzauber" },
    dispel = { "entfluchen" }, fluch = { "entfluchen" },
    reparieren = { "reparatur", "reparieren" }, verkaufen = { "händler", "verkauf" },
    grau = { "schrott" }, ["müll"] = { "schrott" },
    minimap = { "minikarte" }, map = { "karte" },
    angeln = { "angel" }, fishing = { "angel" },
    ["kräuter"] = { "sammeln", "kräuter" }, erz = { "sammeln", "erz" },
    rare = { "selten" }, ah = { "auktion" },
    whisper = { "flüstern" }, tooltip = { "tooltip" },
    xp = { "erfahrung" }, exp = { "erfahrung" },
    ausblenden = { "ruhe", "ausblenden" }, verstecken = { "ruhe", "ausblenden" },
    raid = { "schlachtzug" }, party = { "gruppe" },
    boss = { "boss" }, pull = { "pull" }, timer = { "timer", "leiste" },
    markieren = { "markier", "automark" }, marker = { "markier" },
    rezept = { "beruf", "rezept" }, crafting = { "beruf" },
    talent = { "talent" }, munition = { "munition", "köcher" },
}

WeintCodex.HelpData = { PAGES = P, SYNONYMS = S }
