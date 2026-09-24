# WeintCodex UI 2.0 – Konzept

Stand: Entwurf zur Abstimmung (nach 6.0.0.6). Bildlicher Entwurf:
Design-Canvas „WeintCodex UI 2.0“ (sechs Ansichten: Kampf, Unterwegs,
Gestaltungsmodus, Einstellungen, Taschen/Tooltip/Mitteilungen,
Bausteine). Nichts hiervon ist gebaut, bis die jeweilige Phase unten
abgehakt ist.

## Warum neu und nicht weiter flicken

Die Oberfläche von 6.0.0.0 bis 6.0.0.6 ist Modul für Modul entstanden,
jedes mit eigenen Maßen, eigener Position und eigener Vorstellung davon,
wie eine Fläche aussieht – nach Zahlen aus EllesmereUI, ohne dass je
jemand das Ergebnis vor dem Test gesehen hat. Deshalb wirkt sie wie
eine Baustelle, auch wo sie funktioniert:

* **Kein gemeinsames Raster.** Kanten fluchten nicht, Abstände sind
  zufällig, Spieler- und Zielrahmen stehen nicht spiegelbildlich.
* **Keine gemeinsame Formensprache.** Flache Farbflächen mit einem
  Pixel Rand, jede Datei zeichnet ihre eigene.
* **Alles ist immer da.** Außerhalb des Kampfes liegen Leisten,
  Rahmen und Anzeige genauso schwer auf dem Bild wie im Kampf.
* **Einstellen heißt suchen.** Regler in einer Liste, Rahmen irgendwo
  auf dem Bildschirm, oft erst nach dem Neuladen sichtbar.
* **Kein Blick vor dem Test.** Gruppenrahmen, Zauberbalken oder
  Bossrahmen sieht man nur mit Gruppe oder im Kampf – also erst im
  nächsten Beta-Test.

## Grundsätze

1. **Ein Cockpit um die Bildschirmmitte.** Was im Kampf zählt (Spieler,
   Ziel, Zauber, Ressourcen, Leisten), liegt im mittleren Drittel,
   Spieler und Ziel als Spiegelbild um die Mittelachse. Was man nur
   nachschlägt (Karte, Quests, Chat, Schaden, Taschen), liegt am Rand.
2. **Ein Raster.** 8-px-Raster, alle Positionen als Abstand zur Mitte
   bzw. zum Rand in *einer* Layout-Tabelle, nicht verteilt über die
   Module.
3. **Eine Kachel.** Jede Fläche: Graphit 88 %, 1 px Schwarz, Lichtkante
   oben 5 % Weiß, weicher Schatten. Eine eigene Balkentextur mit
   leichtem Glanz (erzeugt von `make_ui_media.py`, wie der Questpfeil).
4. **Eine Schriftfamilie, zwei Schnitte.** Im Spiel IBM Plex Sans
   Condensed (schmal, klare Ziffern – übernimmt die Rolle, die
   Expressway bei EllesmereUI hat, aber frei lizenziert, OFL), in
   Fenstern IBM Plex Sans wie bisher.
5. **Die Oberfläche atmet: Ruhe – Bereit – Kampf.** Ohne Ziel, bei
   vollem Leben und außerhalb des Kampfes treten Spielerrahmen und
   Leisten 2–3 zurück, die Schadensanzeige klappt auf ihre Kopfzeile
   zusammen. Ziel oder Kampf holt alles in 0,2 s zurück. Nur `SetAlpha`
   – im Kampf erlaubt, ohne Taint.
6. **Einstellen am Objekt.** Gestaltungsmodus mit Testdaten, Raster,
   Einrasten und einer Einstellkarte direkt am angeklickten Rahmen.
   Das große Fenster bleibt für alles Weitere – mit Suche.
7. **Violett heißt „ausgewählt“ oder „läuft“.** Wie bisher; keine
   zweite Bedeutungsfarbe.

## Was EllesmereUI gut macht – und wo es besser geht

| EllesmereUI | Übernehmen | Besser machen |
|---|---|---|
| Ruhige, dunkle Flächen, Klassenfarben | ja | eigene Balkentextur statt flacher Farbe |
| Minikarte eckig, Texte in der Karte | ja | Zone als Streifen, Knöpfe sammeln statt verteilen |
| Mikromenü klein, Taschen daneben | Idee | beides in eine Infoleiste (EP, Gold, Taschenplätze, Haltbarkeit, Latenz, Uhr) |
| Questbereich abgesetzt | ja | in Instanzen eingeklappt auf „2 hier · 11 gesamt“ |
| Viele Einstellungen, Entsperrmodus | ja | Einstellkarte am Rahmen, Suche, Profile, sofortige Wirkung |
| Schadensanzeige mehrfach | ja (schon da) | klappt in Ruhe zusammen |
| — | — | Testdaten: alles auf einem Screenshot prüfbar |
| — | — | Levelhilfe: „noch ≈ 5 Quests · ≈ 48 min“ |

## Grenzen, die bleiben (12.x-Unterbau, Beta)

Ehrlich vorweg, damit niemand etwas erwartet, das der Client verbietet:

* **Kein Kampflog für Addons.** Keine eigene Schadensmessung, keine
  Ansage „X unterbrochen von Y“, keine Auswertung wer was bannte.
* **Geheime Werte.** Leben, Zauberzeiten u. a. dürfen angezeigt, aber
  nicht verglichen oder verrechnet werden. Deshalb: Hinrichtungsmarke
  als **fester Strich** im Balken, nicht als Farbwechsel.
* **Auren nur über den Auren-Container.** Keine Filterlisten einzelner
  Zauber.
* **Keine Secure Snippets (laut Vorlage).** Keine eigenen
  Aktionsleisten mit Umblättern; Blizzards Knöpfe werden umgestaltet.
* **Die Beta speichert Einstellungen nicht zuverlässig.** Darum zählen
  **Voreinstellungen und Profile** mehr als jeder einzelne Regler:
  Profil „Ausgewogen / Heiler / Tank / Minimal“ mit einem Klick, dazu
  ein **Profil-Code** zum Kopieren und Einfügen.

## Die Bereiche

Maße beziehen sich auf 1920 × 1080 bei Skalierung 1; verankert wird
relativ zur Mitte bzw. zum Rand, nicht absolut.

| Bereich | Ziel |
|---|---|
| Spieler / Ziel | 272 × 42 (Porträt 41 + Leben 32 + Kraft 8), je 140 px links/rechts der Mitte, Unterkante 266 px über dem Rand; Ziel gespiegelt, Stufe + Elite-Marke am Namen |
| Ziel des Ziels, Fokus | 124 × 24 rechts neben dem Ziel; Fokus 180 × 26 über dem Ziel |
| Auren am Ziel | über dem Zielrahmen, eigene 26 px mit Restzeit, fremde 20 px entsättigt |
| Zauberbalken | Ziel: angedockt unter dem Zielrahmen; eigener: mittig über den Leisten, nur beim Wirken |
| Kombopunkte | fünf Segmente mittig unter der Figur; Blizzards Schlagtimer darunter, 4 px |
| Namensplaketten | 150 × 14, Name über dem Balken, Auren darüber, Zauberbalken darunter; Ziel: weißer Rand, Leuchten, Pfeile, 110 %; „greift dich an“ als oranger Ring; Questgegner mit Fahne und „6/10“ |
| Gruppe | 140 × 44 senkrecht links neben dem Spielerrahmen; Rahmenfarbe = Handlung (Aggro, bannbar nach Art), Transparenz = außer Reichweite |
| Aktionsleisten | 3 × 12 zu 40 px mittig unten, Tastenbelegung klein oben rechts; Leisten 2–3 in Ruhe ausgeblendet |
| Minikarte | 200 px, oben rechts, Zonenstreifen darüber, Koordinaten unten links (in Instanzen keine), Post-Symbol; Knöpfe gesammelt |
| Questliste | unter der Karte, gleiche Breite; verfolgte Quest mit Entfernung; in Instanzen eingeklappt |
| Chat | unten links, Reiter flach, Hintergrund blendet in Ruhe auf 25 % ab; Nachrichten bleiben unverändert |
| Schadensanzeige | unten rechts; in Ruhe nur Kopfzeile |
| Infoleiste | ganz unten, volle Breite: Mikromenü als Symbole, EP-Balken (in Ruhe mit Prognose), Taschenplätze, Gold, Haltbarkeit, Latenz, Uhr |
| Taschen | ein Fenster mit Bereichen: Neu, Ausrüstung (Stufe, Qualität, Verbesserung), Verbrauchbar, Quest, Handwerk, Plunder (mit „Verkaufen“), Frei |
| Tooltip | Kachel mit Qualitätsrand, zusätzlich „Im Besitz: Taschen · Bank“ |
| Mitteilungen | **eine** Stelle oben mittig für Stufe, Quest, Taschen fast voll, Post, Bereitschaftscheck – statt verstreuter Meldungen |

## Komfort – kuratiert, nicht „ohne Ende“

Jede Funktion ist ungeprüfter Code im Beta-Client. Deshalb eine Liste,
die gut gemacht wird, statt einer langen, die halb geht.

| Welle | Funktion | Machbar? |
|---|---|---|
| 1 | Reparieren (Gilde zuerst), Plunder verkaufen, schnell plündern, Löschbestätigung, Filmsequenzen | schon da |
| 1 | Quests automatisch annehmen/abgeben (Umschalt hält an) | ja, Ereignisse `QUEST_DETAIL`/`QUEST_COMPLETE` |
| 1 | Levelhilfe: EP-Prognose in Quests und Zeit | ja, aus `PLAYER_XP_UPDATE` um `QUEST_TURNED_IN`, immer mit „≈“ |
| 1 | Mitteilungen | ja |
| 2 | Rollencheck annehmen, Einladungen von Freunden/Gilde annehmen | ja |
| 2 | Post: alles nehmen | ja, außerhalb des Kampfes |
| 2 | Händler: Stapel kaufen mit Umschalt-Klick | ja |
| 2 | Tooltip: Besitz über Taschen und Bank, Gegenstandsstufe | ja, Besitz nur soweit die Bank einmal geöffnet war |
| 3 | AFK-Bildschirm (Figur, Uhr, Gilde, langsame Kamera) | vermutlich; Kamera-Aufrufe auf Forever ungeprüft |
| 3 | Lehrer-Erinnerung beim Stufenaufstieg | nur wenn der Client künftige Zauber mit Stufe nennt – prüfen |
| – | Unterbrechen ansagen, Buff-Erinnerung | **nein**: Kampflog bzw. Auren sind für Addons gesperrt |

## Phasen

Jede Phase ist ein Release, das im Spiel mit **einem** Screenshot im
Testmodus geprüft werden kann.

1. **Fundament.** Kachel, Balkentextur, Plex Sans Condensed, zentrale
   Layout-Tabelle, Testdaten (Solo/Gruppe/Schlachtzug), Ruhe/Bereit/Kampf.
2. **Cockpit.** Spieler, Ziel, ZdZ, Fokus, Zauberbalken, Kombopunkte,
   Plaketten, Aktionsleisten nach dem Entwurf.
3. **Bedienung.** Gestaltungsmodus mit Einstellkarte, Einstellungsfenster
   mit Suche, Profile und Profil-Code.
4. **Rand.** Minikarte, Questliste, Chat, Infoleiste mit Levelhilfe,
   Taschen mit Bereichen, Tooltip, Mitteilungen.
5. **Komfort.** Wellen 1–3 oben.

**Abnahme einer Phase:** Screenshot im Testmodus gegen die passende
Ansicht des Entwurfs; keine Lua-Fehler bei `/reload`, Zielwechsel und
Kampf; `load_test.lua` grün.
