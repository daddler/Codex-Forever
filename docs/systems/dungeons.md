# Dungeons und Rollen

## Der Bestand

`data/dungeons.lua` führt die **neun** Dungeons von Forever. Bekannt
sind je vier Dinge: Name, Gebiet, Stufenbereich und Gruppengrösse.
Blizzard hat sie auf der BlizzCon mit genau diesen Angaben
vorgestellt — das sind belegte Angaben, keine Vermutungen.

| Kennung | Name | Gebiet | Stufen |
|---|---|---|---|
| `hall_of_thanes` | Hall of Thanes | Eisenschmiede | 13 – 18 |
| `ruins_of_lordaeron` | Ruins of Lordaeron | Tirisfal-Wälder | 15 – 20 |
| `excavation_site` | Excavation Site | Sumpfland | 24 – 29 |
| `city_of_dalaran` | City of Dalaran | Alteracgebirge | 28 – 33 |
| `drowned_city` | The Drowned City | Schlingendorntal | 35 – 40 |
| `kroldok_stronghold` | Krol'dok Stronghold | Riverglades | 40 – 45 |
| `alcaz_island_prison` | Alcaz Island Prison | Düstermarschen | 48 – 53 |
| `blackmaw_hold` | Blackmaw Hold | Azshara | 55 – 60 |
| `shapers_terrace` | Shaper's Terrace | Krater von Un'Goro | 58 – 60 |

Alle neun sind **Fünfergruppen** und gehören zum Erscheinungsinhalt
(04.11.2026).

**Die Bosslisten sind leer, und das ist ein Zustand, kein Rückstand.**
Im Beta-Client stehen Bossnamen für einen Teil der Dungeons, für
andere keine — und die vorhandenen ändern sich zwischen den Builds
und widersprechen sich untereinander (dasselbe Encounter einmal als
„Magmatus", einmal als „Infurnus"). Eine Liste, die vier Dungeons
stillschweigend als bosslos führt, wäre schlechter als gar keine.

### Drei Dinge, die hier bewusst nicht stehen

* **Deutsche Dungeonnamen.** Forever hat keine deutsche Lokalisierung
  veröffentlicht. „Ruins of Lordaeron" als „Ruinen von Lordaeron" zu
  führen hiesse, einen Namen zu erfinden, den der Client später anders
  schreibt — und die Zuordnung über den Namen liefe daneben.
* **Ein deutscher Gebietsname für Riverglades.** Das Gebiet ist neu; es
  gibt keinen etablierten deutschen Namen. `zoneDe` ist dort `nil`, und
  die Oberfläche zeigt den englischen. Für die acht bestehenden Gebiete
  steht der deutsche Name da — „Eisenschmiede" und „Schlingendorntal"
  heissen seit zwanzig Jahren so.
* **`journalId`.** Welche Encounter-Journal-Kennungen Forever vergibt,
  ist unbekannt. Eine geratene Kennung liest sich im Code wie eine
  belegte.

### Keine gespeicherte ID

Die Dungeonseite zeigt **keinen Lockout**. Fünfergruppen haben in
dieser Fassung des Spiels keinen Wochenreset; eine Zeile „keine ID"
wäre die Antwort auf eine Frage, die niemand gestellt hat. Das ist der
eine sichtbare Unterschied zur Schlachtzugseite.

### Die eigene Stufe

`DungeonData.FitsLevel(dungeon, level)` beantwortet „passt das zu
mir?" — und liefert **`nil`**, wenn der Client keine Stufe genannt
hat. `nil` ist nicht `false`: „passt nicht" wäre eine Behauptung über
eine Stufe, die niemand kennt. Im Detailbereich stehen deshalb drei
Zustände (`passt`, `zu niedrig`, `darüber`) und ein vierter
(`noch nicht bekannt`).

## Die Rollen

`data/roles.lua` ist die gemeinsame Quelle für Tank, Heiler und
Schadensausteiler; `modules/rolepanel.lua` ist die gemeinsame
Darstellung, von Dungeon- und Schlachtzugseite benutzt.

**Der ganze Zweck ist, drei Bestände auseinanderzuhalten.** Sie
beantworten drei verschiedene Fragen und sind unterschiedlich
gesichert:

| Frage | Antwort | Quelle |
|---|---|---|
| Welcher Baum trägt welche Rolle? | vollständig bekannt | `data/specs.lua` |
| Wie viele Plätze hat eine Rolle? | Fünfergruppe: 1/1/3. Schlachtzug: **nicht bekannt** | `Roles.Frame(size)` |
| Was tut die Rolle an diesem Boss? | für **keinen** Kampf bekannt | nur `WCIMPORT:BOSS` |

`Roles.Frame(10)` liefert `nil`. Wie viele Tanks Barrow Deeps braucht,
entscheiden seine Bosse — und deren Mechaniken sind nicht
veröffentlicht. „2 Tanks, 3 Heiler" wäre eine Zahl aus einem anderen
Spiel.

### „Wilder Kampf" steht unter beiden Rollen

Der Feral-Baum trägt in `data/specs.lua` absichtlich **keine** Rolle:
dieselben Talente tragen Katze und Bär, und welche davon jemand gerade
ist, entscheidet die Gestalt. `Roles.Specs("tank")` und
`Roles.Specs("dps")` führen ihn deshalb **beide** auf, mit dem Zusatz
„je nach Gestalt". Ihn nur bei den Schadensausteilern zu führen wäre
ein Vorwurf an jeden Bärtank; ihn wegzulassen wäre eine Lücke.

### Die Tipps kommen vom Bot, oder gar nicht

`SavedData.bossData[<Bossname>]` trägt je Boss bis zu drei Listen —
`tank`, `healer`, `dps`. Das ist der **einzige** Bestand an
Rollenhinweisen, den dieses Addon hat; das Format gibt es seit jeher
(`ParseBossImport` in `modules/sync.lua`), sichtbar wird es mit den
Bosslisten.

Vier Zustände, vier Texte:

| Zustand | Was dasteht |
|---|---|
| `bossguides.tips` fehlt | „gildeninterne Taktiknotizen … gesperrt" |
| nie etwas importiert | „Zu *Boss* liegt nichts vor" + woher etwas käme |
| Boss bekannt, Rolle leer | „Der Bot hat zu dieser Rolle nichts geliefert" |
| Tipps vorhanden | die Tipps |

Allgemeinplätze stehen hier nicht. „Tank: dreh den Boss vom Raid weg"
wäre billig zu haben, passte zu jedem Spiel und zu keinem Kampf in
Forever.

### Farben

Tank ist blau, Heiler grün, Schaden rot — das sind **keine neuen**
Bedeutungsfarben. `modules/signup.lua` färbt die Anmeldeliste seit
jeher so; `Roles.Tone()` ist nur die eine Stelle, an der es jetzt
steht, damit es nicht an zweien halb steht. Der violette Akzent bleibt
unangetastet (siehe `core/ui.lua`).

## Was wo sitzt

| Datei | Aufgabe |
|---|---|
| `data/dungeons.lua` | Bestand + `All/Get/HasBosses/KnownBossCount/LevelRange/ZoneLabel/FitsLevel` |
| `data/roles.lua` | Rollenmodell: Labels, Farben, `Frame`, `Specs`, `Tips`, `HasTips` |
| `modules/rolepanel.lua` | Darstellung: Karte „Aufstellung", Detailblöcke je Instanz und je Boss |
| `modules/dungeonpages.lua` | Die Seite |
| `core/navigation.lua` | Navigationseintrag `dungeons` |
| `core/search.lua` | Dungeons und ihre Stufen im Suchindex |

Die Navigationsspalte ist mit den Dungeons bei **elf** Einträgen
angekommen. Nachgerechnet: 12 Innenabstand + 4×40 Gruppenkopf + 11×42
Eintrag = 634 px, verfügbar sind beim kleinsten Fenster 684. **Der
nächste Eintrag passt nicht mehr** — wer einen ergänzt, gibt der
Spalte vorher einen Bildlauf.
