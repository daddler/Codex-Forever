# Fremde Daten und Medien in WeintCodex

WeintCodex enthält **keinen Code** anderer Addons. Wo ein Addon als Vorbild
diente (BigWigs, DBM, ElvUI/EllesmereUI, MoveAny, WIM, DialogueUI, OPie,
LootTriage, SkillUp, SKTools, Gladius, Healers Have To Die, LayerSwap …),
ist nur das *Verhalten* nachgebaut, mit eigenem Code.

Übernommen wurden an einigen Stellen **Daten** (Zahlen, IDs, Koordinaten,
Namen aus dem Spiel) – erzeugt von Skripten unter `.github/scripts/`, nie von
Hand. Diese Liste nennt jede Quelle und ihren Lizenzstand, so ehrlich, wie er
bekannt ist. Im Spiel werden fremde Addons nie als Quelle genannt
(CLAUDE.md, *Kein Bestand ohne Herkunft*).

| Datei | Quelle | Lizenz der Quelle | Stand |
|---|---|---|---|
| `data/loot.lua` | AtlasLootClassic (Forever) | GPL-2.0 | Lizenz bekannt; nur Datentabellen übernommen |
| `data/questdb.lua` | QuestieDB für Forever | GPL-3.0 (Questie) – für die DB nicht eigens geprüft | zu bestätigen |
| `data/dungeonmaps.lua` | OpenMap | MIT | geklärt |
| `data/beasts.lua` | Datendateien eines Jäger-Addons (Code „All rights reserved“, Daten ausdrücklich nicht); darin cMaNGOS classic-db (GPL-3.0), pfQuest (MIT), warcraft.wiki.gg (CC BY-SA) | gemischt, siehe Skript | geklärt laut Quelle |
| Reisezeiten (`import_travel.py`) | Shortest Path Forever; darin cMaNGOS (GPL-3.0), InFlight (MIT) | Shortest Path: **keine Lizenz gefunden** | **offen** |
| Geländedaten (`import_nav.py`) | Shortest Path Forever (eigenes Backen des Clients) | **keine Lizenz gefunden** | **offen** |
| `data/mapreveal.lua`, `data/mapmarks.lua` | Leatrix Maps | **nicht freigegeben bekannt** – Leatrix-Addons tragen nach unserem Wissen keine freie Lizenz | **offen – Erlaubnis einholen oder ersetzen** |
| `data/dungeon_journal_fg.lua`, `data/professions.lua` | ForeverGuide | **nennt keine Lizenz** | **offen – Erlaubnis einholen** |
| `data/dungeon_journal_nf.lua` | Naowh Forever: Dungeon Journal | **nennt keine Lizenz** | **offen – Erlaubnis einholen** |
| `data/professions_su.lua` | SkillUp Forever | GPL-3.0 (Code); übernommen nur Zahlen aus Clienttabellen | geklärt laut Skript |
| `data/boss_npcs.lua` | eigene Zuordnung aus den Beutedaten oben | – | eigen |

## Medien

| Datei | Herkunft | Stand |
|---|---|---|
| `media/sounds/count_1..5.ogg` | eigene Aufnahme des Besitzers mit ElevenLabs | Weitergabe nur mit bezahltem ElevenLabs-Plan erlaubt – **vom Besitzer zu bestätigen** |
| `media/sounds/meme_*.ogg` | Ausschnitte aus Memes/Videos (`make_meme_sounds.py`) | Rechte Dritter – **offen** |
| übrige `media/` (Artwork, Logo, Töne aus `make_sounds.py`) | eigen erzeugt | eigen |
| Töne und Karten des Spiels | nur über Datei-/Bildnummern des Clients angesprochen, nicht mitgeliefert | Blizzard, nicht weitergegeben |

## Lizenzhinweis

WeintCodex selbst steht unter MIT (`LICENSE`). Für die oben als GPL
gekennzeichneten Datentabellen gilt deren Lizenz, soweit reine Faktendaten
überhaupt geschützt sind – das ist umstritten. Wer WeintCodex weitergibt,
gibt diese Tabellen unter ihrer jeweiligen Lizenz weiter.
