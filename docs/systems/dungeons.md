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

### Die Seite ist gedeckelt, der Detailbereich nicht

`RolePanel.BossCards` zeigt je Rolle höchstens **zwei** Tipps und kürzt
jeden auf 120 Zeichen. Beides ist eine Deckelung gegen dieselbe Gefahr:
wie lang ein Tipp ist, entscheidet der Bot, und beim kleinsten
zulässigen Fenster ist der Inhaltsbereich keine Seite, sondern eine
212 px schmale Spalte — drei ungekürzte Tipps je Rolle könnten dort
neun Zeilen ergeben und die dritte Karte aus dem Fenster schieben.

Gekürzt wird mit `WeintCodex.Truncate`, also **zeichenweise**: ein
Umlaut, den man in der Mitte zerschneidet, wird im Spiel zu einem
leeren Kästchen.

Verloren geht dabei nichts, und die Karte sagt auch, was fehlt
(„gekürzt", „*n* weitere", oder beides). Der Detailbereich zeigt alle
Tipps ungekürzt und rollt, weil er dafür gebaut ist.

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
| `core/navigation.lua` | Navigationseintrag `dungeons`, zweistufige Listenspalte |
| `core/search.lua` | Dungeons und ihre Stufen im Suchindex |

Die Unternavigation ist derselbe **Baum** wie bei den Schlachtzügen:
Instanzen auf der ersten Ebene, die Bosse der ausgewählten eingerückt
auf der zweiten. Heute bleibt die zweite Ebene leer — sobald
`data/dungeons.lua` Bosslisten trägt, füllt sie sich, ohne dass an
`modules/dungeonpages.lua` etwas zu ändern wäre.

Die zweite Zeile eines Dungeoneintrags ist sein **Stufenbereich**. Das
ist es, wonach man in einer Liste von neun Dungeons sucht.

Die Navigationsspalte ist mit den Dungeons bei **elf** Einträgen
angekommen: 604 von 684 px beim kleinsten Fenster. Die Rechnung steht
nicht mehr als Kommentar da, sondern als Funktion, und der Prüflauf
hält sie gegen das Budget — samt der Forderung, dass noch Luft für
einen weiteren Eintrag bleibt. Siehe `docs/architecture/overview.md`,
Abschnitt *Nichts muss scrollen*.
