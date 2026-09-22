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
ehrliche Antwort steht als Kommentar *Warum hier keine Bilder stehen*
in `modules/dungeonpages.lua` und hat zwei voneinander unabhängige
Teile:

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
schaut, und sie lässt sich belegen — und sie steht auf der Bosskarte an
erster Stelle.

## Die Seite: drei Flächen, eine Leserichtung

Bis 5.2.0.0 teilten sich **vier** Flächen die Aufmerksamkeit:
Navigation, ein Baum aus Stufen, Instanzen *und* Bossen, ein
Inhaltsbereich von 212 px und rechts ein Detailbereich, der alles
trug, was auf der Seite keinen Platz hatte. Die Seite selbst war die
schmalste der vier, und ihre Bosskarte sagte, dass die Bosse links
stehen.

Seither sind es **drei** Flächen, und die Seite liest sich von oben
nach unten:

| Fläche | Trägt |
|---|---|
| Spalte links | **nur Dungeons**, nach Stufenabschnitt; unten die Übersicht der beschwörbaren Bosse |
| Kopf | Name (das Zentrum), Stufenbereich · Gruppengrösse, der Themensatz in der Serife; rechts die **Bosszahl als Kennzahl**, wo sie hinpasst, darunter, ob die eigene Stufe passt |
| Bosszeile | eine **Pille je Boss**: Nummer (nur bei bekannter Reihenfolge), Name, Kennzeichen (`BESCHWÖREN` > `OPTIONAL` > `TIPPS`); rechts der Vorsatz der Herkunft mit Begründung im Tooltip; bei Flügeln Reiter darüber, **ein Flügel zur Zeit** |
| Detailkarte | ohne Boss die **Aufstellung**, mit Boss das Berichtete: *So kommt er*, *Wo er steht*, *Dazu*, *Rollen* |

Ein Klick auf eine Pille öffnet den Boss in der Karte, ein zweiter
Klick (oder das `×`) schliesst ihn; ein zweiter Klick auf den offenen
Dungeon in der Spalte führt ebenfalls zur Aufstellung zurück.

**Dieselben Bausteine wie die Schlachtzugseite, nicht ähnliche.** Der
Kopf ist `WeintCodex.PageHead` mit derselben Kennzahl rechts wie in
`modules/raidpages.lua`; der Detailbereich ist
`Navigation.SetInspector`; die Spalte ist `Navigation.BuildSidebar`
mit derselben zweiten Zeile; der Rand der Pillen kommt aus
`WeintCodex.DrawBorder` (`core/ui.lua`), mit dem auch `Chip` und
`CreateButton` umrandet sind. Wo der Dungeonbereich etwas anders macht
— keine gespeicherte ID, keine Bosse in der Spalte, eine rollende
Karte statt einer Liste —, steht der Grund daneben.

### Die Bosszahl steht an genau einer Stelle

Sie ist dreimal verfügbar — als Kennzahl im Kopf, als Zeile *Bosse* im
Detailbereich, als Rubrik `BOSSE · 7` über den Pillen — und **dreimal
dasselbe ist keine Betonung, sondern Lärm**. Welche Stelle es wird,
entscheidet der Platz, gerechnet und nicht gehofft (`HeadStatFits()`
in `modules/dungeonpages.lua`):

| Lage | Wo die Zahl steht |
|---|---|
| Titel lässt rechts `64 + 16` px frei | **Kennzahl** im Kopf, wie beim Schlachtzug |
| passt nicht, Detailbereich offen | dessen Zeile *Bosse* — die Faktenzeile trägt sie **nicht** |
| passt nicht, kein Detailbereich | zurück in die **Faktenzeile** |

Warum überhaupt gerechnet wird: mit offenem Detailbereich bleiben dem
Inhalt 296 px, dem Kopf also 232. Ein Kennzahlenblock ist 64 px breit
und rechtsbündig; ein Titel wie *Temple of Atal'Hakkar* in 30 px liefe
ihm ungebremst darunter. Geschätzt wird mit derselben Kennzahl wie
überall (0,60 em je Zeichen, `WeintCodex.Paragraph`), damit Spiel und
Prüflauf dieselbe Seite bauen. Denselben Test macht `HintFits()` für
den Wegweiser im Kopf der Aufstellungskarte (*„Ein Klick auf einen
Boss zeigt ihn hier"*): in einer 192 px schmalen Karte steht lieber
kein Satz als einer im Titel.

### Der Detailbereich rechts, wo er passt

Bis 5.2.0.2 blieb der Detailbereich rechts auf dieser Seite immer zu.
Seit 5.2.0.3 zeigt sie ihn, für dasselbe einheitliche Bild wie die
Schlachtzugseite (`WeintCodex.Navigation.SetInspector`): Kennzahlen
(Gebiet, Stufe, Gruppengrösse, Bosszahl) und, wo eine Quelle vorliegt,
eine dauerhaft sichtbare *Woher die Bossliste stammt*-Karte mit
Begründung — vorher stand die Begründung nur im Tooltip des Vorsatzes
an der Bosszeile.

**Das ist kein bedingungsloser Rückbau auf das Vier-Flächen-Layout vor
5.2.0.0.** Der Detailbereich beansprucht 420 px (`DETAIL_W` 372 +
`DETAIL_GAP` 16 + `PAD_X` 32); von den 716 px Inhaltsbreite beim
kleinsten Fenster bleiben dann 296 px für die Bosszeile. Bei den
meisten der 29 Dungeons reicht das. Bei den wenigen mit vielen Bossen
in einem Flügel (Stratholme, Blackrock Depths, Scholomance, Lower
Blackrock Spire) bräuchte die Bosszeile bei 296 px so viele Zeilen,
dass für die Detailkarte darunter nicht einmal die Mindesthöhe von
160 px übrig bliebe — genau der Fall, für den `DetailCard` schon
immer absichtlich überlaufen lässt, statt eine Karte zu zeigen, die
keine mehr ist (siehe unten, *Die Detailkarte rollt*).

`DrawDungeon` (`modules/dungeonpages.lua`) zeichnet deshalb zunächst
mit Detailbereich (`DrawDungeonAt(f, dungeon, true)`), misst sich
selbst gegen dasselbe Budget, das `load_test.lua` prüft
(`PageHeight()` gegen `PageBudget()`), und zeichnet bei Überlauf
sofort noch einmal in voller Breite ohne Detailbereich
(`DrawDungeonAt(f, dungeon, false)`) — dieselbe Messung, keine
separate Schätzung, die vom Prüflauf abweichen könnte. Welche
Dungeons zurückfallen, ist damit kein fester Name im Code, sondern
eine Folge des tatsächlichen Bestands: kommt ein Boss dazu oder ändert
sich ein Flügel, entscheidet die nächste Zeichnung neu.

Damit die Seite bei offenem Detailbereich mit der richtigen (schmalen)
Breite rechnet, bevor irgendetwas Pixel zählt, liest `MinContentWidth`
ein `inspectorShown`-Flag, das `DrawDungeonAt` vor jeder Zeichnung
setzt. Die Client-Attrappe kennt `SetPoint` nicht und kann die
Schmälerung des Inhaltsbereichs deshalb nicht selbst nachvollziehen
(anders als im Spiel, wo `WeintCodex.SetDetailShown` sie sofort
anwendet) — `load_test.lua` setzt die Breite der Attrappe deshalb
direkt auf die detailbereich-bewusste Zahl.

Vier Zustände der Bosszeile, keiner davon eine leere Liste:

| Bestand | Bosszeile |
|---|---|
| Namen liegen vor | Pillen; darunter ggf. „7 Kämpfe sind bekannt, ihre Reihenfolge nicht" |
| nur die Anzahl (City of Dalaran) | neun **leere Pillen** mit `?`, darunter die bisher benannten |
| Widerspruch (Excavation Site, Blackmaw Hold) | kein Bestand, der Widerspruch als Absatz, Vorsatz „Quellen widersprechen sich" |
| nichts | ein Absatz, der sagt, dass nichts veröffentlicht ist |

### Die Spalte läuft nicht über, und die Seite auch nicht

Neunundzwanzig Instanzen mit Stufenzeile wären **1334 px** in einer
Spalte von **716** (kleinstes zulässiges Fenster). **Stufenabschnitte**
(`DungeonData.Brackets()`) lösen das: genau einer ist offen, fünf
Abschnitte, 4 – 7 Instanzen je Abschnitt. Gemessener schlimmster
Fall: **642 von 716 px**, 74 px frei — seit die Bosse nicht mehr in
der Spalte stehen, für jeden Dungeon gleich.

Die Seite hat ihr eigenes Budget (`DungeonPages.PageBudget()`), und
drei Dinge halten sie darunter:

* **Flügel** (`DungeonData.Wings()`) fassen die Kämpfe grosser
  Instanzen; die Bosszeile zeigt einen zur Zeit. Sie sind **keine
  Erfindung des Addons**: Scarlet Monastery, Dire Maul und Stratholme
  haben im Spiel getrennte Eingänge, Blackrock Depths läuft jede Gruppe
  in Abschnitten.
* **Texthöhen werden geschätzt, nicht gemessen** (`WeintCodex.Paragraph`
  in `core/ui.lua`): Zeichen je Zeile bei der schmalsten Breite, im
  Spiel und im Prüflauf gleich. Der Client der Attrappe misst jede
  Zeile mit 12 px — eine Seite, die damit rechnete, wäre im Prüflauf
  kürzer als im Spiel.
* **Die Detailkarte rollt**, wenn ihr Inhalt nicht passt. Sie ist die
  eine Fläche der Seite, die das darf, und sie tut es nur, wenn der Bot
  mehr geschickt hat, als das Fenster zeigt. Gekürzt wird nichts.

`load_test.lua` setzt den Inhaltsbereich auf die Breite des kleinsten
Fensters **mit offenem Detailbereich** (716 px `ContentBudgetWidth()`
minus die 420 px, die der Detailbereich braucht — siehe oben), zeichnet
**jede** Instanz in **jedem** Flügel und **jeden** Boss, misst die
Seite gegen das Budget, klickt den Aufklappweg der Spalte durch und
prüft, dass eine Bosskarte mit dreissig Tipps das Fenster genau füllt
und keinen Pixel darüber hinausläuft. Gemessener schlimmster Fall
seit 5.2.0.3: mehrere Dungeons mit Detailbereich landen exakt bei
**716 von 716 px** (die Detailkarte füllt bis zum Rand und rollt —
das ist der vorgesehene, keine Fehlerfall); unter den vier Dungeons,
die auf die volle Breite zurückfallen, bleibt Stratholme mit
**646 von 716 px** der schlimmste — unverändert zur Messung vor
5.2.0.3, weil `DrawDungeonAt(f, dungeon, false)` exakt denselben Weg
zeichnet wie vor dieser Version.

### Ein Flügel darf keinen Boss verlieren

Die Bosszeile zeigt immer nur **einen** Flügel. Ein Boss ohne
Flügelangabe in einer Instanz, die Flügel hat, wäre in der Oberfläche
**nirgends** zu sehen — lautlos. `data_test.lua` prüft deshalb, dass die
Flügel zusammen jeden Boss der Instanz fassen.

### Die eigene Stufe

`DungeonData.FitsLevel(dungeon, level)` beantwortet „passt das zu
mir?" — und liefert **`nil`**, wenn der Client keine Stufe genannt
hat. `nil` ist nicht `false`: „passt nicht" wäre eine Behauptung über
eine Stufe, die niemand kennt. Im Kopf stehen deshalb drei Zustände
(`passt`, `zu niedrig`, `darüber`) — und ohne Stufe vom Client steht
dort **nichts**, nicht „Stufe 0".

## Die Rollen

`data/roles.lua` ist die gemeinsame Quelle für Tank, Heiler und
Schadensausteiler; `modules/rolepanel.lua` ist die gemeinsame
Darstellung, von Dungeon- und Schlachtzugseite benutzt. Die
Schlachtzugseite zeichnet Karten (`Card`, `BossCards`) und
Detailblöcke (`InstanceBlocks`, `BossBlocks`); die Dungeonseite
zeichnet Zeilen in ihre Detailkarte (`Roster`, `BossRoleRows`). Beide
lesen dieselben drei Bestände.

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

### Schlachtzug: die Seite ist gedeckelt, der Detailbereich nicht

`RolePanel.BossCards` (Schlachtzugseite) zeigt je Rolle höchstens
**zwei** Tipps und kürzt jeden auf 120 Zeichen. Beides ist eine
Deckelung gegen dieselbe Gefahr: wie lang ein Tipp ist, entscheidet der
Bot, und neben dem Detailbereich ist der Inhaltsbereich beim kleinsten
Fenster eine 212 px schmale Spalte.

Gekürzt wird mit `WeintCodex.Truncate`, also **zeichenweise**: ein
Umlaut, den man in der Mitte zerschneidet, wird im Spiel zu einem
leeren Kästchen. Verloren geht dabei nichts, und die Karte sagt auch,
was fehlt. Der Detailbereich zeigt alle Tipps ungekürzt und rollt.

### Dungeon: die Detailkarte rollt, gekürzt wird nichts

`RolePanel.BossRoleRows` (Dungeonseite) zeigt **alle** Tipps
ungekürzt — die Detailkarte ist ein Bildlauffeld und nimmt bei Bedarf
den Platz bis zum Fensterrand. Liegt zu einem Boss **nichts** vor,
steht das **einmal** da (mit der Auskunft, woher etwas käme), nicht
dreimal untereinander; erst wenn der Bot etwas geliefert hat, bekommt
jede Rolle ihre Zeile — auch die, zu der er nichts gesagt hat.

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
| `modules/rolepanel.lua` | Darstellung: `Card`/`BossCards`/`InstanceBlocks`/`BossBlocks` (Schlachtzug), `Roster`/`BossRoleRows` (Dungeon) |
| `modules/dungeonpages.lua` | Die Seite: Kopf, Bosszeile, Detailkarte, Spalte, Übersicht der beschwörbaren Bosse |
| `core/ui.lua` | `Paragraph`/`EstimateLines`: Fliesstext mit geschätzter Höhe |
| `core/navigation.lua` | Navigationseintrag `dungeons`, Listenspalte, anklickbare Gruppenköpfe, `Fits`/`SubNavHeadroom`/`SidebarButtons`/`ContentBudgetWidth` |
| `core/search.lua` | Alle 29 Instanzen und ihre Bosse im Suchindex |

`data/dungeons_classic.lua` lädt **nach** `data/dungeons.lua` (siehe
`WeintCodex.toc`): es hängt sich an dieselben Zugriffsfunktionen und
überschreibt `DungeonData.Get()`, damit eine klassische Kennung auch
gefunden wird. `data/sources.lua` lädt **vor** beiden und vor
`data/raids.lua`.

### Die Spalte links

Die Unternavigation führt **Stufenabschnitte** als anklickbare
Gruppenköpfe und darunter die Dungeons des offenen Abschnitts. Bosse
stehen **nicht** in ihr — anders als bei den Schlachtzügen, wo die
zweistufige Liste bleibt. Der Grund ist die Seite: sie hat ohne
Detailbereich die Breite für eine Bosszeile, und eine Liste, die man
ohnehin auf der Seite sieht, noch einmal links zu zeigen, war der
Grund für vier konkurrierende Flächen.

Ein anklickbarer Gruppenkopf ist **kein Eintrag**: er landet in
`sidebarGroups` und nicht in `sidebarItems`. Sonst verschöbe er jeden
Index, mit dem eine Seite ihren aktiven Eintrag markiert
(`ActivateIndex`), und die Markierung sässe eine Zeile daneben.

Die zweite Zeile eines Dungeoneintrags trägt **beides**: aus welchem
Spiel er ist und für welche Stufen er gedacht ist — *Forever · Stufe
13 – 18*, *Classic · Stufe 17 – 26*. Bis 5.2.0.3 stand die Herkunft
als gesperrtes Kennzeichen `FOREVER` rechts in der Zeile und nahm der
Beschriftung rund **70 der 176 px**; sichtbar war das als
abgeschnittener Name („Temple of Atal'Hakk…"). Der Name ist aber das,
wonach man in einer Liste von neunundzwanzig Dungeons sucht, und er
bekommt deshalb die ganze Breite. Siehe
`docs/architecture/overview.md`, Abschnitt *Die Unternavigation*.

Das Kennzeichen an einer Boss-Pille sagt, was für einer es ist:
**BESCHWÖREN** schlägt **OPTIONAL** schlägt **TIPPS**, weil „steht ohne
Zutun gar nicht da" die dringendere Auskunft ist.

### Die Navigationsspalte selbst

Sie ist unverändert bei **elf** Einträgen: 604 von 684 px beim
kleinsten Fenster, 80 px frei. Die klassischen Dungeons haben **keinen**
eigenen Navigationspunkt bekommen — sie sind Dungeons, und ein zweiter
Punkt hätte die Luft für den nächsten Bereich aufgebraucht. Siehe
`docs/architecture/overview.md`, Abschnitt *Nichts muss scrollen*.
