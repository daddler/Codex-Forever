# Dungeons und Rollen

## Der Bestand

`data/dungeons.lua` führt die **neun** Dungeons von Forever,
`data/dungeons_classic.lua` die **zwanzig** klassischen. Zusammen sind
das **neunundzwanzig** Instanzen, und sie hängen an denselben
Zugriffsfunktionen (`WeintCodex.DungeonData`) — die Seite, der Prüflauf
und die Suche sollen nicht zwei Sorten Dungeon kennen müssen, sondern
einen Bestand mit einem Herkunftsfeld.

`DungeonData.AllInstances()` liefert beide, nach Mindeststufe sortiert.
Das ist die Frage, mit der man auf eine Dungeonliste schaut: *„was passt
zu Stufe 32?"* — und die beantwortet eine Neunerliste falsch.

### Die neun von Forever

| Kennung | Name | Gebiet | Stufen | Bosse |
|---|---|---|---|---|
| `hall_of_thanes` | Hall of Thanes | Eisenschmiede | 13 – 18 | 4, vollständig |
| `ruins_of_lordaeron` | Ruins of Lordaeron | Tirisfal-Wälder | 15 – 20 | 7, unvollständig |
| `excavation_site` | Excavation Site | Sumpfland | 24 – 29 | — (Quellen widersprechen sich) |
| `city_of_dalaran` | City of Dalaran | Alteracgebirge | 28 – 33 | 9 Kämpfe, Namen unbekannt |
| `drowned_city` | The Drowned City | Schlingendorntal | 35 – 40 | 2, unvollständig |
| `kroldok_stronghold` | Krol'dok Stronghold | Riverglades | 40 – 45 | — |
| `alcaz_island_prison` | Alcaz Island Prison | Düstermarschen | 48 – 53 | — |
| `blackmaw_hold` | Blackmaw Hold | Azshara | 55 – 60 | — |
| `shapers_terrace` | Shaper's Terrace | Krater von Un'Goro | 58 – 60 | — |

Alle neun sind **Fünfergruppen** und gehören zum Erscheinungsinhalt
(04.11.2026).

### Die zwanzig aus Classic

Forever ersetzt sie nicht. Blizzard hat die Beute jedes Bosses
überarbeitet, die Legacy-Aufgaben führen weiter durch sie hindurch, und
sie decken die Stufenbereiche ab, in denen die neun neuen Lücken lassen.
`Upper Blackrock Spire` ist dabei der eine Dungeon, der **keine
Fünfergruppe** ist (`size = 10`) — wer `size == 5` als Invariante in
eine Oberfläche schreibt, baut einen Fehler ein, und `data_test.lua`
prüft genau das.

`raresListed = false` steht an jedem: eingetragen ist der Hauptweg plus
die beschwörbaren Zusatzbosse, nicht jeder seltene Spawn.

## Fünf Arten von Herkunft

`data/sources.lua` ist seit 5.2.0.0 die gemeinsame Stelle für die Frage,
worauf sich ein Eintrag stützt — vorher stand sie als lokale Tabelle in
`data/raids.lua` und galt nur für Schlachtzüge.

| `kind` | Heisst | Zusatz auf der Oberfläche |
|---|---|---|
| `release` | Blizzard hat es veröffentlicht | keiner — das ist der einzige bestätigte Zustand |
| `announced` | Blizzard hat es öffentlich gezeigt (BlizzCon) | „Angekündigt · …" |
| `beta` | aus dem Beta-Client gelesen | „Vorläufig · …" |
| `community` | aus Beta-Berichten zusammengetragen | „Unbestätigt · …" |
| `classic` | aus WoW Classic Era | „Aus Classic · …" |

**Der Unterschied zwischen `beta` und `community` ist der wichtigste
hier.** Die Schlachtzugslisten tragen `beta`: sie stammen aus dem
Client. Die Dungeonlisten tragen `community`: sie stammen aus Berichten
**über** den Client. Niemand in diesem Projekt hat den Forever-Client
gelesen, und eine Liste, die `beta` behauptet, behauptet eine Prüfung,
die nie stattgefunden hat.

`Sources.Why(source)` liefert zu jeder unbestätigten Art einen Satz, der
sagt **warum** — ein Hinweis „vorläufig" ohne Begründung ist eine
Fussnote, die niemand liest.

## Drei Zustände statt zwei

Früher war eine Bossliste entweder da oder nicht. Das reicht nicht mehr:

| Zustand | Bedeutet | Beispiel |
|---|---|---|
| `bosses` gefüllt, `bossesComplete = true` | so vollständig, wie die Quelle sie hergibt | Hall of Thanes |
| `bosses` gefüllt, `bossesComplete = false` | Kämpfe bekannt, aber nicht alle | Ruins of Lordaeron, Drowned City |
| `bosses` leer, `bossCount` gesetzt | die **Anzahl** ist berichtet, die Namen nicht | City of Dalaran (9) |
| alles leer, `conflict` gesetzt | die Quellen widersprechen sich | Excavation Site, Blackmaw Hold |

Der dritte Zustand ist der interessante: *„neun Kämpfe, Namen
unbekannt"* ist mehr als „nichts bekannt" und weniger als eine Liste.
Fünf von neun Namen als Liste einzutragen hiesse, einen Dungeon mit neun
Kämpfen als Dungeon mit fünf zu führen.

Der vierte auch. Für Excavation Site kursieren vier Bossnamen, die eine
andere Darstellung ausdrücklich bestreitet; für Blackmaw Hold kursiert
eine Liste, die nachweislich die der Drowned City ist. Beides steht als
Widerspruch da — wer die kursierende Liste anderswo gesehen hat, erfährt
hier, warum sie fehlt.

### `order` steht nur da, wo die Reihenfolge bekannt ist

In der Hall of Thanes decken sich mehrere Berichte über die
Pullreihenfolge; in den Ruins of Lordaeron liegen sieben Namen vor und
keine Folge. `orderKnown = false` heisst: **kein** Boss trägt `order`,
und die Seite schreibt keine Pullnummer hin. „3 von 7" wäre eine Zahl,
die niemand kennt.

`data_test.lua` erzwingt beides: bei `orderKnown = true` müssen die
Nummern lückenlos bei 1 anfangen (optionale Bosse dürfen sie auslassen),
bei `false` darf keine dastehen.

## Beschwörbare Zusatzbosse

Elf Gegner im ganzen Spiel erscheinen erst, wenn die Gruppe etwas dafür
tut. `DungeonData.AllSummonable()` sammelt sie; die Seite gibt ihnen eine
eigene Übersicht, weil die Auskunft verstreut über neunundzwanzig
Dungeons keine wäre.

| Boss | Instanz |
|---|---|
| Viktor the Vile | Ruins of Lordaeron |
| Mutanus the Devourer | Wailing Caverns |
| Gahz'rilla | Zul'Farrak |
| Atal'alarion | Temple of Atal'Hakkar |
| Avatar of Hakkar | Temple of Atal'Hakkar |
| Urok Doomhowl | Lower Blackrock Spire |
| Lord Valthalak | Upper Blackrock Spire |
| Lord Hel'nurath | Dire Maul West |
| Postmaster Malown | Stratholme |
| Jarien and Sothos | Stratholme |
| Kirtonos the Herald | Scholomance |

Jede `summon`-Angabe trägt `text` **und** `source`. Eine
Beschwörungsanleitung ohne Herkunft wäre dieselbe Behauptung wie eine
Bossliste ohne.

**Spieler beschwören ist etwas anderes** und wird ständig damit
verwechselt: Forever hat keine Rufsteine freigeschaltet und keinen
automatischen Gruppenfinder — Spieler beschwört nur der Hexenmeister, mit
zwei Helfern vor Ort. Das steht in `DungeonData.SUMMONING`.

## Bilder: keine, und warum

Nach einem Kompendium mit Bildern wurde ausdrücklich gefragt. Die
ehrliche Antwort steht als Kommentar über `MapNote()` in
`modules/dungeonpages.lua` und hat zwei voneinander unabhängige Teile:

1. **Es gibt sie nicht.** Blizzard hat für Forever keine Dungeonkarten
   veröffentlicht. Im Beta-Client liegt für **vier** der neun Instanzen
   überhaupt Kartenmaterial (Hall of Thanes, Ruins of Lordaeron,
   Excavation Site, City of Dalaran), für fünf nicht. Ein Kompendium mit
   fünf leeren Rahmen ist keines.
2. **Sie gehören nicht uns.** Das Material ist Blizzards Eigentum. Es in
   ein öffentliches Repository zu legen, wäre unabhängig von 1. keine
   Option.

Auf Texturpfade des Clients zu zeigen wäre einem Addon erlaubt — hier
aber verboten: welche Pfade Forever vergibt, weiss niemand in diesem
Projekt, und ein geratener Pfad zeichnet im Spiel ein grünes Rechteck.
Eine Fehlermeldung, die wie ein Bild aussieht, ist schlimmer als kein
Bild.

**Was stattdessen geht:** `boss.position` sagt, **wo** ein Boss steht.
„Patrouilliert den ersten langen Gang auf einer sehr weiten Route",
„allein in der Kammer der Verzauberung", „Endkammer, zusammen mit zwei
Steingolems". Das ist die Auskunft, für die man sonst auf ein Bild
schaut, und sie lässt sich belegen.

## Die Liste links läuft nicht über

Neunundzwanzig Instanzen mit Stufenzeile wären **1334 px** in einer
Spalte von **716** (kleinstes zulässiges Fenster). Die zweiundzwanzig
Kämpfe von Blackrock Depths sind allein 660 px. Beides zusammen ist
nicht eng, sondern unmöglich.

Zwei Staffelungen lösen das, und keine versteckt etwas:

* **Stufenabschnitte** (`DungeonData.Brackets()`) fassen die Instanzen.
  Genau einer ist offen. Fünf Abschnitte, 4 – 7 Instanzen je Abschnitt.
* **Flügel** (`DungeonData.Wings()`) fassen die Kämpfe grosser
  Instanzen. Sie sind **keine Erfindung des Addons**: Scarlet Monastery,
  Dire Maul und Stratholme haben im Spiel getrennte Eingänge, Blackrock
  Depths läuft jede Gruppe in Abschnitten. Eine Instanz ohne Flügel
  zeigt ihre Kämpfe am Stück.

Dazu rechnet die Seite ihren Baum **vor dem Bauen** durch
(`Navigation.Fits`, neu in 5.2.0.0, teilt sich die 60 px Luft mit dem
Prüflauf): passt er mit Bossen, zeigt sie ihn mit; sonst vertieft sie
(Rücksprungzeile, gewählte Instanz, deren Flügel und Kämpfe). Das ist
genau der Zweck, für den `MeasureSidebar` gebaut wurde.

Gemessener schlimmster Fall: **612 von 716 px**, 104 px frei.

`load_test.lua` rechnet **jede** der 29 Instanzen in **jedem** Flügel
gegen das Budget und klickt den Aufklappweg einmal komplett durch —
Gruppenköpfe stehen nicht in `sidebarItems`, `ActivateIndex` löst sie
also nie aus, und ein Fehler darin fiele sonst erst im Spiel auf.

### Ein Flügel darf keinen Boss verlieren

Die Spalte zeigt immer nur **einen** Flügel. Ein Boss ohne
Flügelangabe in einer Instanz, die Flügel hat, wäre in der Oberfläche
**nirgends** zu sehen — lautlos. `data_test.lua` prüft deshalb, dass die
Flügel zusammen jeden Boss der Instanz fassen.

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
| `data/sources.lua` | Herkunftsmodell: `KINDS`, `IsValid/IsConfirmed/Label/Why/Weaker` |
| `data/dungeons.lua` | Die neun von Forever + `All/Get/HasBosses/BossesComplete/OrderKnown/BossSource/BossCount/SummonableBosses/LevelRange/ZoneLabel/FitsLevel` |
| `data/dungeons_classic.lua` | Die zwanzig aus Classic + `AllClassic/AllInstances/IsLegacy/AllSummonable/Brackets/BracketIndexOf/Wings/BossesInWing` |
| `data/roles.lua` | Rollenmodell: Labels, Farben, `Frame`, `Specs`, `Tips`, `HasTips` |
| `modules/rolepanel.lua` | Darstellung: Karte „Aufstellung", Detailblöcke je Instanz und je Boss |
| `modules/dungeonpages.lua` | Die Seite, die Staffelung, `MapNote()` |
| `core/navigation.lua` | Navigationseintrag `dungeons`, Listenspalte, anklickbare Gruppenköpfe, `Fits`/`SubNavHeadroom`/`SidebarButtons` |
| `core/search.lua` | Alle 29 Instanzen und ihre Bosse im Suchindex |

`data/dungeons_classic.lua` lädt **nach** `data/dungeons.lua` (siehe
`WeintCodex.toc`): es hängt sich an dieselben Zugriffsfunktionen und
überschreibt `DungeonData.Get()`, damit eine klassische Kennung auch
gefunden wird. `data/sources.lua` lädt **vor** beiden und vor
`data/raids.lua`.

### Der Baum links

Die Unternavigation ist weiterhin ein **Baum** — Instanzen auf der
ersten Ebene, die Bosse der ausgewählten eingerückt auf der zweiten.
Dazu gekommen ist eine Ebene **darüber**: Stufenabschnitte, und bei
grossen Instanzen Flügel. Beides sind Gruppenköpfe, und die sind seit
5.2.0.0 anklickbar.

Ein anklickbarer Gruppenkopf ist trotzdem **kein Eintrag**: er landet in
`sidebarGroups` und nicht in `sidebarItems`. Sonst verschöbe er jeden
Index, mit dem eine Seite ihren aktiven Eintrag markiert
(`ActivateIndex`), und die Markierung sässe eine Zeile daneben.

Die zweite Zeile eines Dungeoneintrags ist sein **Stufenbereich** — das
ist es, wonach man in einer Liste von neunundzwanzig Dungeons sucht. Das
Kennzeichen rechts an einem Boss sagt, was für einer es ist:
**BESCHWÖREN** schlägt **OPTIONAL** schlägt **TIPPS**, weil „steht ohne
Zutun gar nicht da" die dringendere Auskunft ist.

### Die Navigationsspalte selbst

Sie ist unverändert bei **elf** Einträgen: 604 von 684 px beim
kleinsten Fenster, 80 px frei. Die klassischen Dungeons haben **keinen**
eigenen Navigationspunkt bekommen — sie sind Dungeons, und ein zweiter
Punkt hätte die Luft für den nächsten Bereich aufgebraucht. Siehe
`docs/architecture/overview.md`, Abschnitt *Nichts muss scrollen*.
