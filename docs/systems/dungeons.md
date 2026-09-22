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

## Die Seite: drei Ebenen, zwei Zustände

Bis 5.2.0.0 teilten sich **vier Flächen** die Aufmerksamkeit:
Navigation, ein Baum aus Stufen, Instanzen *und* Bossen, ein
Inhaltsbereich von 212 px und rechts ein Detailbereich, der alles
trug, was auf der Seite keinen Platz hatte. Die Seite selbst war die
schmalste der vier, und ihre Bosskarte sagte, dass die Bosse links
stehen.

Bis 5.2.0.4 war das gelöst, aber nicht geordnet: Titel, Gebiet,
Stufenbereich, Gruppengrösse, eine Bosszahl als Kennzahl rechts oben,
ein Stufenchip darunter, der Themensatz, eine Zeile aus Boss-Pillen,
der Herkunftsvorsatz und eine Karte, die ohne Boss vor allem ihre
eigene Leere beschrieb — **acht Einzelteile auf einer Ebene**, von
denen keines wichtiger aussah als das andere.

Seit 5.2.0.5 hat die Seite **drei Ebenen**, und sie stehen immer in
derselben Reihenfolge. Weder 5.2.0.6 noch 5.2.0.7 haben an dieser
Reihenfolge etwas geändert — nur daran, wie schwer die drei *aussehen*:

| Ebene | Trägt |
|---|---|
| 1 · Kopfkarte | eine **eigene Fläche in zwei Zonen** mit Akzentstreifen an der linken Kante. Oben: Kennzeichnung (`CLASSIC` / `FOREVER`), der Name in der Serife (34 px), der Themensatz in der ruhigen Kursiven — als **Spalte** (62 % der Breite), nicht über die ganze Fläche; rechts daneben ein Verlauf, der nach hinten hin violett anläuft. Unten, auf einem **dunkleren Sockel** unter der Haarlinie: das **Tatsachenband**, in dem jede Auskunft eine eigene Spalte hat (Wert oben, Rubrik darunter) und die Stufenzelle **rechts aussen für sich** steht |
| 2 · Bosse | ein **Raster aus Karten**, angeführt von einer Rubrik mit **Abschnittslinie**: Nummer oben links (nur bei bekannter Reihenfolge), Kennzeichen als Pille oben rechts (`BESCHWÖREN` > `OPTIONAL` > `TIPPS`), der Name unten auf einem dunkleren **Sockel**, in der Serife; rechts über dem Raster der Vorsatz der Herkunft mit Begründung im Tooltip; bei Flügeln Reiter darüber, **ein Flügel zur Zeit**. Der schwerste Abschnitt der Seite, und zwar absichtlich |
| 3 · Kontextkarte | **nie höher als ihr Inhalt.** Ohne Boss zwei Spalten — `BESONDERHEITEN` und `AUFSTELLUNG`, beide eng gesetzt — und, wo die Seite in voller Breite steht, die Herkunft als **zweizeilige** Fusszeile (Rubrik *neben* der Quelle, nicht darüber); **mit Boss** das Berichtete: die Notiz als Aufschlag, *So kommt er*, *Wo er steht*, *Rollen* |

#### Die Gewichtung ist der Punkt *(seit 5.2.0.7)*

Die drei Ebenen sind nicht gleich schwer, und man soll es sehen:

```
KOPFKARTE      ████████████
BOSSE          ██████████████████████████
KONTEXTKARTE   ████████████
QUELLE         ███
```

Drei Rechnungen tragen das, und keine davon ist ein fester Wert:

* **Die Kartenhöhe wächst mit dem Platz** (`GridCardHeight`, siehe
  unten). Wo die Seite es hergibt, ist die Bosskarte 66 bis 80 px hoch
  statt 44 — das Raster bekommt damit rund die Hälfte der Seite.
* **Die Kontextkarte hat keine Mindesthöhe mehr.** Bis 5.2.0.6 stand
  dort `MIN_DETAIL_H = 160`; eine Karte mit drei kurzen Zeilen war
  damit eine halbleere Fläche. Jetzt ist sie so hoch wie ihr Inhalt.
* **Texthöhen werden gegen die wirkliche Breite geschätzt**
  (`LayoutWidth`). Vorher rechnete die Seite jeden Absatz gegen die
  Breite des *kleinsten* Fensters: ein Absatz, der bei 652 px vier
  Zeilen braucht, braucht bei 1036 px zwei — die Karte wurde für vier
  gebaut und zeichnete zwei. Das war der grösste Teil des leeren
  Raums unten.

### Warum eine Fläche und nicht nur Abstand

Bis 5.2.0.5 stand der Seitenkopf auf demselben Grund wie alles andere;
was ihn vom Rest trennte, war **Abstand**. Abstand trennt aber auch den
Bossabschnitt von der Kontextkarte — und so las sich die Seite als eine
Folge gleichrangiger Abschnitte, obwohl sie drei Ebenen hat.

Die Kopfkarte ist die **eine** Fläche der Seite, die eine *Überschrift*
trägt statt eines Bestands. Dass sie einen eigenen Grund hat, sagt
genau das. Sie benutzt dafür keinen neuen Baustein: `CreateSurface` mit
`tone = "plain"` ist derselbe Kartenverlauf mit 1-px-Oberkante wie jede
andere Fläche des Addons, und der Kopf darin ist `WeintCodex.PageHead`
wie überall — er hängt sich nur in die Karte statt in den
Inhaltsbereich.

Der **Akzentstreifen** an ihrer linken Kante ist dasselbe Zeichen, das
in der Spalte links am ausgewählten Dungeon steht und auf der
ausgewählten Bosskarte: drei Stellen, ein Zeichen, eine Bedeutung
(*hier bist du*). Die Karte selbst trägt **nicht** `tone = "accent"` —
das ist die ausgewählte Bosskarte, und im Entwurf gibt es genau eine
Akzentfläche je Ansicht.

Die Spalte links führt **nur Dungeons**, nach Stufenabschnitt; unten
die Übersicht der beschwörbaren Bosse.

### Zwei Zustände, eine Struktur

Ein Klick auf eine Bosskarte ersetzt die Übersicht **nicht**: das
Raster bleibt stehen, die angeklickte Karte trägt den Akzentton und
einen Balken an der linken Kante, und nur die Kontextkarte darunter
wechselt ihren Inhalt. Wer wissen will, wo er ist, muss dafür nichts
zuklappen. Im Kopf der Karte steht die Einordnung (*BOSS 03 · SCARLET
· OPTIONAL*), der Name und rechts der Weg zurück — beschriftet, wo er
danebenpasst (`HintFits()`), sonst als `×` an derselben Stelle. Ein
zweiter Klick auf dieselbe Karte schliesst den Boss ebenfalls, und ein
zweiter Klick auf den offenen Dungeon in der Spalte führt zur
Übersicht zurück.

**Der Name steht in der Überschriftenschrift** (`Fonts.display`, 22
px), seit 5.2.0.6. Bis dahin stand er in der Grotesk — derselben
Schrift wie auf den Bosskarten, den Rollenzeilen und den Knöpfen; der
Name des geöffneten Bosses sah damit aus wie eine weitere
Beschriftung und nicht wie der Titel dessen, was darunter steht. Es
ist dieselbe Schrift wie der Dungeonname oben, nur kleiner: beides
sind Überschriften eines Bestands.

**`boss.note` ist vom Abschnitt zum Aufschlag geworden.** Bis 5.2.0.5
stand sie unter dem Zwischentitel *„Dazu"*, zwischen *„Wo er steht"*
und *„Rollen"* — also so, als wäre sie eine vierte Auskunft derselben
Art. Sie ist aber der eine Satz, der sagt, **was** dieser Boss ist,
und steht deshalb direkt unter seinem Namen, in derselben ruhigen
Kursiven wie der Themensatz des Dungeons oben.

**Weggefallen ist der Wegweiser** *„Ein Klick auf einen Boss zeigt ihn
hier"* aus 5.2.0.4. Er stand im Kopf einer Karte, die ohne Boss nichts
anderes zu sagen hatte, und beschrieb damit vor allem ihre eigene
Leere. Eine Karte, die Besonderheiten, Aufstellung *und* Herkunft
trägt, braucht keine Bedienungsanleitung.

### Die Kontextkarte hat zwei Spalten

Ohne ausgewählten Boss trägt sie seit 5.2.0.6 `BESONDERHEITEN` links
und `AUFSTELLUNG` rechts, getrennt durch eine Haarlinie, und darunter
die Herkunft als Fusszeile. Bis 5.2.0.5 war das eine schmale Säule
Text in einer breiten Karte, mit viel Fläche rechts daneben, die
nichts tat.

**Die Karte trägt deshalb keinen eigenen Titel mehr.** Ein Titel
*„Aufstellung"* über einer Spalte *„Aufstellung"* wäre dasselbe Wort
zweimal, und die Zeile dafür wäre Luft. `DetailCard` nimmt `title`
seither als optional.

**Zwei Spalten, wo zwei Spalten passen** — gerechnet wie das
Bossraster darüber: `(w - 24) / 2` muss mindestens 210 px ergeben.
Beim kleinsten Fenster mit offenem Detailbereich bleiben der Karte
192 px; zwei Spalten daraus wären zwei Textsäulen von 84 px. Dann
stehen sie untereinander.

**Was unter `BESONDERHEITEN` steht, ist abgeleitet und nicht
erfunden.** Jede Zeile kommt aus dem Bestand:

| Zeile | Woraus |
|---|---|
| *„3 Bereiche"* | `DungeonData.Wings()` |
| *„Ein Boss nur auf Beschwörung"* | `DungeonData.SummonableBosses()` |
| *„2 Bosse neben dem Hauptweg"* | `boss.optional` ohne `boss.summon` |
| *„Reihenfolge nicht bekannt"* / *„Liste unvollständig"* | `CompletenessLine()` |
| *„Klassischer Dungeon"* | `DungeonData.IsLegacy()` |

Ein Satz über „viel Laufweg" oder „schwierige Trashpacks" wäre zu
jedem Dungeon dieser Welt zu schreiben und zu keinem belegt; hier
steht er nicht. **Liegt keine einzige dieser Auskünfte vor, fällt die
Spalte weg** und die Aufstellung nimmt die volle Breite — eine Rubrik
über einer leeren Fläche ist die Sorte Leerraum, die wie ein Fehler
aussieht.

**Dieselben Bausteine wie die Schlachtzugseite, nicht ähnliche.** Der
Kopf ist `WeintCodex.PageHead` wie in `modules/raidpages.lua`; der
Detailbereich ist `Navigation.SetInspector`; die Spalte ist
`Navigation.BuildSidebar` mit derselben zweiten Zeile; der Rand der
Bosskarten kommt aus `WeintCodex.DrawBorder` (`core/ui.lua`), mit dem
auch `Chip` und `CreateButton` umrandet sind; die Kennzeichen auf den
Bosskarten **sind** `WeintCodex.Chip`. Wo der Dungeonbereich
etwas anders macht — keine gespeicherte ID, keine Bosse in der Spalte,
eine rollende Karte statt einer Liste —, steht der Grund daneben.

### Karten statt Pillen, und warum

Eine Reihe schmaler, gerundeter Schaltflächen ist das Bild, mit dem
jede Oberfläche *„hier wechselst du die Ansicht"* sagt. Was der
Dungeon **enthält**, sah damit aus wie ein Bedienelement — und stand
zugleich in Konkurrenz zur Spalte links, die genau das tut.

Eine Karte sieht aus wie ein Gegenstand:

```
+---------------------------+  +---------------------------+
| 03              (OPTIONAL)|  | 04                        |
| Commander Springvale      |  | Odo the Blindwatcher      |
+---------------------------+  +---------------------------+
```

Die **Kopfzeile** gibt es nur, wo sie etwas trägt. Trägt in der ganzen
gezeigten Liste keine Karte eine Nummer (`orderKnown = false`) und
kein Kennzeichen, sind alle Karten flach (34 px statt 66) — und zwar
**alle**, damit das Raster eine Zeilenhöhe hat und nicht zwei. Eine
reservierte Zeile, die nirgends etwas enthält, ist Luft, die wie ein
Fehler aussieht.

#### Und seit 5.2.0.6 sieht sie auch nicht mehr aus wie ein Eingabefeld

Eine Karte war es zwar, aber gezeichnet war sie als **flache Fläche**
(`surface2`) mit dünnem Rahmen und einem Namen in Beschriftungsfarbe
(`textMuted`) — genau das Bild, das in jeder Oberfläche ein *Textfeld*
ist. Drei Dinge ändern das, alle mit vorhandenen Bausteinen:

* **Der Kartenverlauf.** `tone = "plain"` statt `tone = "flat"`: der
  Verlauf `cardTop → cardBottom` mit der 1-px-Oberkante, mit dem jede
  andere Fläche des Addons gezeichnet ist.
* **Der Name in Lesefarbe.** `textNormal` statt `textMuted`, und
  `sansMedium` statt `sans`. Was hier zählt, ist der Boss, nicht die
  Karte.
* **Das Kennzeichen als Pille** (`WeintCodex.Chip`) statt als frei
  schwebende Versalie. Ihre Breite wird **gerechnet** und nicht
  gemessen (rund 1,15 em je Zeichen, weil gesperrter Text hinter jedem
  Zeichen ein Leerzeichen trägt) — eine Pille, die im Spiel breiter
  wäre als im Prüflauf, hinge über der Karte.

Der **ausgewählte** Boss trägt seit 5.2.0.6 `tone = "accent"`: den
violett getönten Verlauf mit Akzent-Oberkante und Akzentrand, dazu
weiterhin den Balken an der linken Kante. Er ist damit die **eine**
Akzentfläche der Ansicht, wie der Entwurf es vorsieht.

#### Und seit 5.2.0.7 auch nicht mehr wie ein breiter Knopf

Eine Zeile Text in einem Rahmen bleibt eine Zeile Text in einem
Rahmen, egal wie sie gefüllt ist. Drei Dinge machen daraus einen
Eintrag — und keines davon ist ein Bild:

* **Höhe und Zonen.** Die Nummer steht oben, der Name unten,
  dazwischen ist Luft. Ein Knopf hat keine Luft, ein Eintrag schon.
* **Der Sockel.** Die untere Zone läuft nach unten hin dunkler aus
  (`C.washDark`, 22 %). Der Name steht damit *auf* etwas, statt in
  einem Kasten zu schweben — das ist, in den Mitteln dieses Addons,
  was in den Vorlagen der dunkle Verlauf über dem Bossbild tut. Auf
  der ausgewählten Karte ist derselbe Sockel akzentfarben
  (`C.washAccentUp`): der Zustand färbt die Fläche, auf der der Name
  steht, nicht nur seinen Rahmen.
* **Der Name in der Serife** (`Fonts.display`, 14 px). Bosskarten
  tragen Namen, und Namen sind in diesem Addon Überschriften —
  dieselbe Schrift wie der Dungeonname darüber und der Bossname in
  der Detailkarte darunter. Die Grotesk daneben war die Schrift der
  Knöpfe. Auf der hohen Karte darf er in eine **zweite Zeile**
  umbrechen; die Spaltenrechnung bleibt trotzdem bei der Größe der
  engen Karte (`BOSS_FIT`), sonst kostete ein grösserer Name eine
  Rasterspalte.

Dazugekommen ist damit **kein** zweiter Rahmen, kein Schein und keine
zweite Akzentfarbe.

#### Die Kartenhöhe ist gerechnet wie die Spaltenzahl *(seit 5.2.0.7)*

`GridCardHeight(top, rowCount, headline, reserve, cardW)` wählt
absteigend, und der erste Wert, der passt, gewinnt:

| Höhe | Wann |
|---|---|
| `cardW × 0,26`, höchstens **80 px** | im breiten Fenster: eine Karte, die fünfmal so breit wie hoch ist, wäre wieder ein Band |
| **66 px** (`BOSS_H_TALL`) | der Regelfall |
| **46 px** (`BOSS_H_MED`) | wo die hohe Karte der Kontextkarte darunter nur noch einen Schlitz liesse — im kleinsten Fenster trifft das Scholomance (14 Bosse), Stratholme und Blackrock Depths |
| **34 px** (`BOSS_H_FLAT`) | Listen ohne Nummer *und* ohne Kennzeichen; die Karte hat dann gar keine Kopfzeile |

„Passt" heisst: unter dem Raster bleiben noch `CARD_ROOM` (168 px) für
die Kontextkarte. Das ist **nicht** dieselbe Zahl wie `MIN_DETAIL_H`
(120 px), unter der die Seite sich im Prüflauf selbst anzeigt — wären
es zwei Namen für eine Zahl, müsste jede Kartenhöhe am schlimmsten
Fall gemessen werden, und der schlimmste Fall ist Scholomance.

### Die Spaltenzahl ist gerechnet, nicht gesetzt

`GridLayout(width, longest)` in `modules/dungeonpages.lua` entscheidet
sie aus der **wirklichen** Breite und dem **längsten Namen der
gezeigten Liste**:

| Bedingung | Spalten |
|---|---|
| Karte ≥ 150 px **und** der längste Name passt ganz hinein | **3** |
| dasselbe, eine Stufe schmaler | **2** |
| sonst | **1**, volle Breite |

Drei Spalten sind das Ziel, aber eine Folge, keine Vorgabe: *Blackrock
Depths* hat Bosse mit 26 Zeichen; in 210 px stünden die nicht, sondern
endeten in einem abgeschnittenen Wort. Gerechnet wird mit derselben
Kennzahl wie überall in diesem Repository (0,60 em je Zeichen, siehe
`WeintCodex.Paragraph`), damit Spiel und Prüflauf dasselbe Raster
bauen.

Wächst das Fenster, rücken die Karten still nach (`PlaceGrid` →
`f._relayout`); **neu gezeichnet** wird die Seite nur, wenn die
Spaltenzahl wirklich kippt — denn nur dann ändert sich die Höhe des
Rasters und alles darunter.

### Der Dungeonkontext steht als Band, nicht als Satz

Bis 5.2.0.4 verteilte sich, was dieser Dungeon *ist*, auf vier
Flächen: eine Kennzahl rechts oben (*BOSSE 9*), ein Stufenchip
darunter, eine Faktenzeile links und der Themensatz. Die Kennzahl
stand dabei so weit von allem anderen entfernt, dass sie zu keiner
Auskunft mehr gehörte — und weil ihr Platz je nach Titelbreite
wechselte, gab es **drei** Rechnungen dafür, wo eine Zahl hingehört
(`HeadStatFits()`, seither entfallen).

5.2.0.5 zog das auf **eine Zeile** zusammen:

```
Tirisfal Glades  ·  Stufe 22 – 30  ·  5 Spieler  ·  9 Bosse  ·  Deine Stufe 30 · passt
```

Das war eine Ebene statt vier, aber es war ein **Satz**. Und ein Satz
wird gelesen, nicht überflogen: wer wissen will, ob seine Stufe passt,
sucht die Auskunft zwischen vier anderen heraus. Seit 5.2.0.6 trägt
jede Tatsache eine eigene Spalte — oben der **Wert** in Lesegrösse,
darunter die **Rubrik** als gesperrte Versalie:

```
Tirisfal Glades │ 22 – 30 │ 5       │ 9     │ Stufe 30
GEBIET          │ STUFEN  │ SPIELER │ BOSSE │ PASST
```

Das ist dieselbe Form wie die Kennzahlen im Seitenkopf der anderen
Seiten (`WeintCodex.PageHead`, `stats`) — nur von links nach rechts
gelesen statt von rechts nach links gesetzt, weil es hier fünf sind
und keine zwei. Getrennt wird mit einer Haarlinie und nicht mit einem
Kasten: fünf umrandete Kacheln wären fünf Bedienelemente, und bedienen
lässt sich hier nichts.

**Wie viele Zellen in eine Zeile passen, ist gerechnet** — dieselbe
Regel wie beim Bossraster darüber. Jede Zelle ist so breit wie ihr
breiterer der beiden Texte (Wert bei 0,60 em je Zeichen, die gesperrte
Rubrik bei rund 1,15 em); was nicht mehr in die Zeile passt, fällt in
die nächste. Eine feste Spaltenzahl gibt es nicht, und abgeschnitten
wird nichts. Beim kleinsten Fenster mit offenem Detailbereich bleiben
dem Band 188 px — dort stehen zwei Zellen je Zeile.

Die Kennzeichnung darüber ist auf **ein Wort** zusammengezogen
(`CLASSIC` / `FOREVER`). Das Gebiet stand dort bis 5.2.0.4 gesperrt und
versal mit drin; *„D U N G E O N · T I R I S F A L  G L A D E S"* ist
rund 300 px breit und lief bei offenem Detailbereich aus dem Kopf
heraus. Als Tatsache steht es jetzt im Band.

Die Bosszahl kennt dort fünf Formulierungen, und keine davon ist eine
`0`:

| Bestand | Im Band |
|---|---|
| Liste vollständig | `9` / `BOSSE` |
| Liste unvollständig | `4 / 9` / `BOSSE BENANNT` |
| nur die Anzahl | `9` / `KÄMPFE · NAMEN OFFEN` |
| Widerspruch | `—` / `QUELLEN WIDERSPRECHEN SICH` |
| nichts | `—` / `BOSSE UNBEKANNT` |

Der Geviertstrich ist dabei **keine gemessene Null**: er steht für
„nicht bekannt", und die Rubrik darunter sagt, warum.

Die Stufenzelle ist die einzige, die von der eigenen Figur abhängt,
und sie färbt **beide** Zeilen (`Stufe 30` über `PASST` in Grün, über
`ZU NIEDRIG` in Warnfarbe). Nennt der Client keine Stufe, **fehlt die
Zelle ganz** — nicht „passt nicht", und nicht „Stufe 0".

Die Rubrik über dem Raster heisst deshalb schlicht `BOSSE` — *„BOSSE ·
9"* wäre dieselbe Zahl ein zweites Mal auf derselben Seite.

### Der Detailbereich rechts, wo er passt

Bis 5.2.0.2 blieb der Detailbereich rechts auf dieser Seite immer zu.
Seit 5.2.0.3 zeigt sie ihn, für dasselbe einheitliche Bild wie die
Schlachtzugseite (`WeintCodex.Navigation.SetInspector`): Kennzahlen
(Gebiet, Stufe, Spieler, Bosse, **Herkunft**) und, wo eine Quelle
vorliegt, eine dauerhaft sichtbare *Woher die Bossliste stammt*-Karte
mit Begründung.

**Die Herkunft steht seit 5.2.0.6 als Kennzahl**, nicht nur als
Absatz: `HERKUNFT · Aus Classic` in der Kennzahlenliste, die Quelle
und der `Why()`-Satz darunter. Dort steht der **Vorsatz allein**
(`Sources.Prefix()`, neu) und nicht das ganze `Sources.Label()` —
Kennzahlenzeilen brechen nicht um (`InspectorRows` in
`core/navigation.lua`), und eine lange Quellenangabe liefe über die
Beschriftung daneben. Dass der Absatz darunter die Quelle nennt und
die Kennzahl die Art, ist keine Wiederholung, sondern die Trennung von
*was für eine Art Beleg* und *welcher Beleg*.

**Die Kennzahlen sind dieselben wie im Tatsachenband der Kopfkarte,
und das ist Absicht.** Das Band beantwortet *„was ist das hier"*,
während man liest; der Detailbereich bleibt stehen, während man durch
die Bosse klickt. Die Herkunft führt nur er — sie ist keine Tatsache
über den Dungeon, sondern eine über die Liste.

**Das ist kein bedingungsloser Rückbau auf das Vier-Flächen-Layout vor
5.2.0.0.** Der Detailbereich beansprucht 420 px (`DETAIL_W` 372 +
`DETAIL_GAP` 16 + `PAD_X` 32); von den 716 px Inhaltsbreite beim
kleinsten Fenster bleiben dann 296 px. `DrawDungeon` zeichnet deshalb
zuerst **mit** Bereich, misst sich selbst und zeichnet bei Bedarf noch
einmal in voller Breite. **Drei** Dinge entscheiden das, alle
gerechnet:

1. **Sie passt nicht.** Viele Bosse, viele Flügelreiter — dann bliebe
   der Kontextkarte nicht einmal `MIN_DETAIL_H` (120 px). Gemessen
   wird mit derselben Rechnung, mit der `load_test.lua` das Budget
   prüft (`PageHeight()` gegen `PageBudget()`), damit hier kein Fall
   entsteht, den der Prüflauf nicht ohnehin durchspielt.
2. **Das Raster wäre keines mehr** *(seit 5.2.0.5)*. In 232 px steht
   eine Karte je Zeile, und eine Spalte ist keine Übersicht, sondern
   eine Liste. Käme die Seite in voller Breite auf mehr als eine
   Spalte, ist die Übersicht den Bereich wert — seine Auskünfte trägt
   dann die Kontextkarte im Seitenkörper (`SourceBody`), es geht also
   keine verloren. Im voreingestellten Fenster (1500 px) greift das
   nicht: dort bleiben dem Inhalt auch mit Bereich 552 px, und das
   sind drei Spalten.
3. **Er hätte nichts zu zeigen** *(seit 5.2.0.5)*. `SetInspector`
   zeigt nichts, wenn die Blockliste leer ist — die Seite räumte ihm
   die 420 px aber trotzdem ein. Für die Dungeons ohne Bestand und
   ohne Herkunft war das die halbe Seite für nichts.

Welche Dungeons zurückfallen, ist damit kein fester Name im Code,
sondern eine Folge des tatsächlichen Bestands: kommt ein Boss dazu
oder ändert sich ein Flügel, entscheidet die nächste Zeichnung neu.

Damit die Seite bei offenem Detailbereich mit der richtigen (schmalen)
Breite rechnet, bevor irgendetwas Pixel zählt, liest `MinContentWidth`
ein `inspectorShown`-Flag, das `DrawDungeonAt` vor jeder Zeichnung
setzt. Die Client-Attrappe kennt `SetPoint` nicht und kann die
Schmälerung des Inhaltsbereichs deshalb nicht selbst nachvollziehen
(anders als im Spiel, wo `WeintCodex.SetDetailShown` sie sofort
anwendet) — `load_test.lua` setzt die Breite der Attrappe deshalb
direkt auf die detailbereich-bewusste Zahl.

### Die Herkunft steht in jedem Zustand genau einmal sichtbar

Ist der Detailbereich offen, steht sie dort. Steht die Seite in voller
Breite, trägt sie die Kontextkarte als **Fusszeile** unter beiden
Spalten (`SourceFooter` in `modules/dungeonpages.lua`) — die Rubrik
`QUELLE` **neben** der Quelle und der `Why()`-Satz darunter, zwei
Zeilen unter einer Haarlinie.
Zweimal derselbe Absatz nebeneinander wäre keine Betonung; keinmal
wäre der Zustand vor 5.2.0.3, in dem die Begründung nur im Tooltip
eines Vorsatzes stand, den niemand findet, der nicht ohnehin vermutet,
dass da einer ist.

Bis 5.2.0.5 waren es dort zwei Zwischentitel und zwei Absätze — die
grösste zusammenhängende Textfläche der Seite für die **nachrangigste**
Auskunft, die sie hat. Der Hinweis auf den klassischen Dungeon ist
dabei in die Spalte *Besonderheiten* gewandert, wo er als eine Zeile
unter anderen steht statt als eigener Abschnitt.

**Dieselbe Regel gilt seit 5.2.0.6 für die Vollständigkeitszeile**
(*„14 Kämpfe sind bekannt, ihre Reihenfolge nicht"*): ohne
ausgewählten Boss trägt sie die Spalte *Besonderheiten*, mit
ausgewähltem Boss gibt es diese Spalte nicht — dann steht sie unter
dem Raster (`DrawBosses`, `bossOpen`). In jedem Zustand genau einmal.

Vier Zustände des Bossabschnitts, keiner davon eine leere Liste:

| Bestand | Bossabschnitt |
|---|---|
| Namen liegen vor | das Kartenraster; darunter ggf. „7 Kämpfe sind bekannt, ihre Reihenfolge nicht" |
| nur die Anzahl (City of Dalaran) | neun **leere Karten** mit `?`, darunter die bisher benannten |
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
* **Die Kontextkarte rollt**, wenn ihr Inhalt nicht passt. Sie ist die
  eine Fläche der Seite, die das darf, und sie tut es nur, wenn der Bot
  mehr geschickt hat, als das Fenster zeigt. Gekürzt wird nichts.
* **Das Raster ist gedeckelt, ohne gekürzt zu werden.** Seine Höhe
  hängt an der Spaltenzahl, und die hängt an der Breite — fällt sie,
  fällt die Seite in die volle Breite zurück (siehe oben), wo drei
  Spalten aus vierzehn Bossen fünf Zeilen machen statt vierzehn.

`load_test.lua` setzt den Inhaltsbereich auf die Breite des kleinsten
Fensters **mit offenem Detailbereich** (716 px `ContentBudgetWidth()`
minus die 420 px, die der Detailbereich braucht — siehe oben), zeichnet
**jede** Instanz in **jedem** Flügel und **jeden** Boss, misst die
Seite gegen das Budget, klickt den Aufklappweg der Spalte durch und
prüft, dass eine Bosskarte mit dreissig Tipps das Fenster genau füllt
und keinen Pixel darüber hinausläuft. Gemessener schlimmster Fall,
unverändert seit 5.2.0.5 und auch nach dem Umbau von 5.2.0.6:
**716 von 716 px** — die Kontextkarte füllt bis zum Rand und rollt,
das ist der vorgesehene und kein Fehlerfall. Beim kleinsten zulässigen
Fenster fällt dabei **jeder** Dungeon mit Bossliste in die volle
Breite (Grund 2 oben) und bekommt dort drei Spalten.

**Welche Dungeons beim voreingestellten Fenster (1500 px) den
Detailbereich behalten, sagt dieser Lauf nicht.** Er setzt nur die
Breite des Inhaltsbereichs; die Attrappe kennt `SetPoint` nicht und
schmälert ihn nicht selbst, und seine Höhe bleibt die des kleinsten
Fensters. Eine Liste von Namen an dieser Stelle wäre also eine
Behauptung über einen Fall, den der Prüflauf gar nicht durchspielt —
bis 5.2.0.5 stand hier eine. Die Regel steht im Code und ist
gerechnet: je mehr Bosse, Flügel und Zeilen im Tatsachenband, desto
eher fällt die Seite in die volle Breite, und die Kopfkarte von
5.2.0.6 verschiebt diese Grenze nach oben. Welche Dungeons es trifft,
entscheidet die nächste Zeichnung neu.

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
ungekürzt — die Kontextkarte ist ein Bildlauffeld und nimmt bei Bedarf
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
| `data/sources.lua` | Herkunftsmodell: `KINDS`, `IsValid/IsConfirmed/Label/Prefix/Why/Weaker` |
| `data/dungeons.lua` | Die neun von Forever + `All/Get/HasBosses/BossesComplete/OrderKnown/BossSource/BossCount/SummonableBosses/LevelRange/ZoneLabel/FitsLevel` |
| `data/dungeons_classic.lua` | Die zwanzig aus Classic + `AllClassic/AllInstances/IsLegacy/AllSummonable/Brackets/BracketIndexOf/Wings/BossesInWing` |
| `data/roles.lua` | Rollenmodell: Labels, Farben, `Frame`, `Specs`, `Tips`, `HasTips` |
| `modules/rolepanel.lua` | Darstellung: `Card`/`BossCards`/`InstanceBlocks`/`BossBlocks` (Schlachtzug), `Roster`/`BossRoleRows` (Dungeon) |
| `modules/dungeonpages.lua` | Die Seite: Kopfkarte mit Tatsachenband, Bossraster, Kontextkarte, Spalte, Übersicht der beschwörbaren Bosse |
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

Das Kennzeichen oben rechts auf einer Bosskarte sagt, was für
einer es ist:
**BESCHWÖREN** schlägt **OPTIONAL** schlägt **TIPPS**, weil „steht ohne
Zutun gar nicht da" die dringendere Auskunft ist.

### Die Navigationsspalte selbst

Sie ist unverändert bei **elf** Einträgen: 604 von 684 px beim
kleinsten Fenster, 80 px frei. Die klassischen Dungeons haben **keinen**
eigenen Navigationspunkt bekommen — sie sind Dungeons, und ein zweiter
Punkt hätte die Luft für den nächsten Bereich aufgebraucht. Siehe
`docs/architecture/overview.md`, Abschnitt *Nichts muss scrollen*.
