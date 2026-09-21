# Datenintegrität: `unknown` ist nicht `0`

Die eine Regel, die in diesem Repo über allen anderen steht. Sie ist
hier keine Theorie, sondern der Normalfall: **die meisten Zahlen, die
dieses Addon anzeigen könnte, kennt es noch nicht.**

## Die Regel

> Eine fehlende Angabe ist `nil`. Sie ist nie `0`, nie `false`, nie ein
> leerer Balken und nie ein roter Punkt.

Vier Zustände, die nirgends zusammenfallen dürfen:

| Zustand | Heisst | Darstellung |
|---|---|---|
| `nil` | „nicht gemessen / nicht bekannt" | Gedankenstrich, Kontur statt Punkt, Text „noch nicht bekannt" |
| `0` | „gemessen, und das Ergebnis ist null" | Zahl, Punkt in der passenden Farbe |
| **vorläufig** | „es steht etwas da, aber es steht nicht fest" | Zahl **plus Herkunft**, nie das Grün einer gesicherten Angabe |
| gesperrt | „es gibt Daten, du darfst sie nicht sehen" | „Gesperrt", nie eine Zahl |

Wer die vier zusammenzieht, macht aus einer Datenlücke einen Befund —
oder aus einer Vermutung eine Messung.

Genau dieselbe Konvention gilt drüben in der Companion (`stars == 0`
heisst „keine Daten", `at == -1` heisst „kein Zeitpunkt bekannt") — sie
ist der Grund, warum die beiden Programme dieselbe Sprache sprechen.

### Der vierte Zustand ist mit 5.1.0.0 dazugekommen

Bis dahin gab es ihn nicht, weil es ihn nicht geben musste: über
Forever war entweder etwas veröffentlicht oder gar nichts. Seit dem
Beta-Start liegt ein dritter Fall vor — Angaben, die **im Spiel
stehen**, aber **nicht angekündigt** sind (die Encounter-Listen im
Client). Sie wegzulassen hiesse, etwas zu verschweigen, das da ist;
sie ohne Hinweis zu zeigen hiesse, etwas zu behaupten, das sich noch
ändert.

Die Regel dafür ist knapp:

> **Kein Bestand ohne Herkunft.** Was nicht aus einer Ankündigung
> stammt, trägt seine Quelle mit sich und wird überall, wo es
> erscheint, als vorläufig ausgewiesen.

Und die Gegenrichtung, damit die Regel nicht zur Floskel wird:
`BossesConfirmed()` liefert nur bei `kind == "release"` `true`. Alles
andere — auch eine vergessene, unbekannte oder kaputte Quelle — gilt
als **nicht** bestätigt. Das ist die Richtung, in die ein Irrtum
harmlos ist.

## Wo sie in diesem Addon greift

### Die Bosslisten (`data/raids.lua`, `data/dungeons.lua`)

Hier stehen inzwischen **alle vier Zustände nebeneinander**, und das
macht diese Stelle zum besten Beispiel der ganzen Regel:

| Instanz | Zustand | Was dasteht |
|---|---|---|
| Barrow Deeps, Hyjal Summit | vorläufig | 8 bzw. 13 Bosse, überall mit „Vorläufig · Beta-Client 1.60.1.69876" |
| Onyxias Hort | `nil` | „Bosse noch nicht bekannt" |
| alle neun Dungeons | `nil` | „noch nicht bekannt", mit Begründung |

`WeintCodex.RaidData.KnownBossCount()` liefert **`nil`**, solange keine
einzige Bossliste gefüllt ist — nicht `0`. Solange das so war, schrieb
die Übersicht „bosse offen" statt „0 bosse". Dieselbe Funktion gibt es
für die Dungeons (`WeintCodex.DungeonData.KnownBossCount()`), und dort
liefert sie heute noch `nil`.

`HasBosses(instanz)` ist der Weg, nach dem Bestand zu fragen. Wer
stattdessen `#instanz.bosses` zählt, bekommt `0` oder `8` und weiss in
beiden Fällen nicht, was die Zahl bedeutet.

`BossSourceLabel(raid)` ist der Weg, nach der **Herkunft** zu fragen.
Er liefert `nil` für eine bestätigte Liste (da ist nichts
einzuschränken) und einen Text für jede andere. Jede Stelle, die eine
Bosszahl zeigt, zeigt diesen Text mit — Seitenkopf, Detailbereich,
Übersicht, Diagnose.

`.github/tests/data_test.lua` hält beides fest:

* solange nichts eingetragen ist, muss `KnownBossCount()` `nil`
  liefern; sobald der erste Boss eingetragen wird, die Summe. An der
  Prüfung war dafür nichts zu ändern — sie ist von selbst auf den
  anderen Zweig gekippt, als die Listen kamen.
* **keine Bossliste ohne Herkunft.** Eine gefüllte Liste ohne
  `bossSource` lässt den Lauf durchfallen, eine leere Liste **mit**
  `bossSource` ebenso. Eine unbelegte Liste ist der eine Zustand, den
  es hier nie geben soll.

### Die Rollen (`data/roles.lua`)

Dieselbe Regel, auf eine Frage angewandt, bei der sie besonders leicht
zu brechen wäre: **was macht der Tank an diesem Boss?**

Drei Bestände, die nicht zusammenfallen dürfen:

| Bestand | Zustand | Quelle |
|---|---|---|
| Welcher Baum welche Rolle trägt | bekannt | `data/specs.lua` |
| Wie viele Plätze eine Rolle hat | bekannt für Fünfergruppen, `nil` für 10/20/40 | `Roles.Frame(size)` |
| Was eine Rolle an einem Boss tut | für **keinen** Kampf in Forever bekannt | nur der Discord-Bot (`WCIMPORT:BOSS`) |

`Roles.Frame(10)` liefert ausdrücklich `nil` und nicht „2 Tanks, 3
Heiler". Wie viele Tanks ein Schlachtzug braucht, entscheiden seine
Bosse; deren Mechaniken sind nicht veröffentlicht. Eine Verteilung aus
einem anderen Spiel wäre genau der Fehler, den die leeren Bosslisten
vermieden haben.

`Roles.Tips(boss, rolle)` unterscheidet drei Antworten, und alle drei
stehen so in der Oberfläche:

* `nil` → gesperrt (`bossguides.tips`) **oder** zu diesem Boss wurde
  nie etwas importiert
* leere Tabelle → der Bot kennt den Boss, hat zu **dieser** Rolle aber
  nichts gesagt
* gefüllte Tabelle → es steht etwas da

Allgemeinplätze („Tank: dreh den Boss weg") wären hier billig zu haben
und würden zu jedem Spiel passen — und zu keinem Kampf in Forever.

### Die Ausrüstung (`modules/charakter.lua`)

`Snapshot()` liefert **`nil`**, wenn der Client die Frage nicht
beantwortet hat. Das ist etwas anderes als „nichts angelegt", und die
Übersicht unterscheidet es:

* `nil` → „Ausrüstung konnte nicht gelesen werden", Überschrift
  „Willkommen zurück" statt einer Mängelzahl.
* Snapshot mit leeren Plätzen → „3 Dinge sind noch offen".

Je Platz gilt dasselbe: eine unbekannte Gegenstandsstufe ist ein
Gedankenstrich, keine Null. `GetAverageItemLevel()` liefert `0`, solange
der Client die Gegenstände nicht geladen hat — deshalb wird die `0` dort
ausdrücklich verworfen und nicht angezeigt.

**Die Ausrüstungsplätze kommen vom Client.** `GetInventorySlotInfo` sagt,
welche es gibt; was der Client nicht kennt, fällt aus der Liste. Ein fest
verdrahteter Platz 18 stünde auf jedem Charakter als „leer" da, wenn der
moderne Client den Distanzplatz nicht mehr führt.

**Nebenhand und Distanz dürfen leer sein.** Ein Zweihandkämpfer trägt
keine Nebenhand; das ist kein Mangel und wird nicht angemahnt.

### Der Gruppencheck (`modules/groupcheck.lua`)

* Eine unbekannte Gegenstandsstufe **fällt aus dem Durchschnitt heraus**,
  statt ihn nach unten zu ziehen. `AverageItemLevel()` liefert `nil`,
  wenn kein einziger Gegenstand eine Stufe genannt hat.
* **Nicht erreichbar ist kein Befund.** Wer zu weit weg, offline oder in
  einer anderen Phase ist, zählt als *ungeprüft* und nicht als
  fehlerfrei. Eine Übersicht, die Ungeprüftes als geprüft zählt, ist
  schlimmer als gar keine.

### Die Materialien (`modules/materials.lua`)

Ein Posten **ohne Sollbestand** bekommt keinen Statuspunkt, keinen Balken
und zählt in keiner der drei Kennzahlen mit. Bis 3.x rechnete diese
Stelle `pct = 0`, wenn kein Soll hinterlegt war — und stellte jeden
solchen Posten rot als Engpass dar. Für Forever ist das der Normalfall
und nicht die Ausnahme.

### Der Ausrüstungsstand an die Companion (`modules/companion.lua`)

Die Nachricht `character_sheet` lässt die Abschnitte ZÄHLER und BIS
**leer** und die Felder `score`, `grade` und `quality` **unbesetzt**. Der
Vertrag sieht das ausdrücklich vor
(`../Companion-Forever/docs/character-sheet-bridge.md`, Abschnitt
*Toleranzregeln*): `readiness()` drüben liefert dann `None` statt `0.0`
— ein leerer Ring statt eines roten.

Eine `0` in diese Felder zu schreiben wäre die teuerste Variante: sie
sähe aus wie eine Messung, und der Spieler bekäme einen dauerhaft roten
Vorbereitungsring für etwas, das er nicht abstellen kann.

### Die Spezialisierung (`data/specs.lua`, `modules/charakter.lua`)

`CurrentSpec()` probiert drei Wege und liefert am Ende **`nil`**, wenn
keiner davon antwortet. Geraten wird nichts: eine falsche
Spezialisierung wandert über die Companion-Brücke bis in den Bot und
ordnet den Spieler dort der falschen Rolle zu.

**„Wilder Kampf" trägt absichtlich keine Rolle.** Dieselben Talente
tragen Katze und Bär; welche davon jemand gerade ist, entscheidet die
Gestalt und nicht der Baum. Ein als Schadensausteiler geführter Bär wird
gegen die Schadensrangliste gemessen und bekommt dauerhaft einen Stern,
obwohl er seine Aufgabe einwandfrei erfüllt. Das ist keine Lücke,
sondern die richtige Antwort — und `data_test.lua` hält sie fest.

## Sechs Zustände, nicht zwei

Bis 5.0.0.0 war ein Bestand entweder da oder nicht. Das reicht nicht.
Seit 5.2.0.0 hält das Addon sechs Zustände auseinander, und jeder hat
auf der Oberfläche einen eigenen Text:

| Zustand | Im Bestand | Was dastehen muss |
|---|---|---|
| **bestätigt** | Liste + `bossSource.kind == "release"` | die Liste, ohne Zusatz |
| **vorläufig** | Liste + `kind` ist `announced`/`beta`/`community`/`classic` | die Liste **plus** Herkunft **plus** Begründung |
| **unvollständig** | Liste + `bossesComplete = false` | wie viele von wie vielen |
| **gezählt, unbenannt** | `bossCount` gesetzt, `bosses` leer | die **Anzahl** — „neun Kämpfe, Namen unbekannt" |
| **umstritten** | `conflict` gesetzt, sonst leer | der Widerspruch selbst |
| **unbekannt** | alles leer | warum nichts da ist |

Die letzten drei sind die neuen, und sie sind der eigentliche Gewinn:

* **Gezählt, unbenannt** ist mehr als Schweigen. Für die City of
  Dalaran sind neun Kämpfe berichtet und fünf Namen. Fünf Namen als
  Liste einzutragen hiesse, einen Dungeon mit neun Kämpfen als Dungeon
  mit fünf zu führen; gar nichts zu sagen verschweigt eine Auskunft,
  die man hat. „Neun Kämpfe" beantwortet *„wie lang wird das?"* bereits.
* **Umstritten** ist mehr als Schweigen. Für Excavation Site kursieren
  vier Bossnamen, die eine andere Darstellung bestreitet; für Blackmaw
  Hold kursiert eine Liste, die nachweislich die der Drowned City ist.
  Wer die kursierende Liste anderswo gesehen hat, soll hier erfahren,
  **warum** sie fehlt — sonst sieht das Addon einfach veraltet aus.
* **Vorläufig** ist seit 5.2.0.0 abgestuft. `data/sources.lua` kennt
  fünf Arten von Herkunft, und nur `release` gilt als bestätigt. Die
  Abstufung ist nicht Kosmetik: eine Liste aus dem Client (`beta`) und
  eine aus einem Forenbericht (`community`) sind verschieden fest, und
  eine Oberfläche, die beide gleich darstellt, behauptet etwas.

### Im Zweifel die schwächere Quelle

`Sources.Weaker(a, b)` liefert von zweien die schwächere, und
`IsConfirmed()` ist `false` für alles ausser `release` — auch für `nil`.
Beides zeigt in dieselbe Richtung: die Gesamtangabe einer Instanz darf
nie fester klingen als ihr schwächster Teil, und ein Irrtum soll nach
unten gehen.

## Wie man das prüft, wenn nichts drinsteht

Ein Test, der über eine leere Tabelle läuft, wird grün, weil nichts
passiert — lautlos und wertlos. Deshalb prüft `data_test.lua` den
**Mechanismus** statt den Bestand:

* Liefert `KnownBossCount()` `nil` statt `0`, solange nichts da ist?
* Stimmt `HasBosses()` mit dem tatsächlichen Bestand überein?
* Trägt **jede** gefüllte Bossliste eine Herkunft — und **keine** leere
  eine?
* Liefert `FitsLevel()` `nil` statt `false`, wenn der Client keine
  Stufe genannt hat?
* Liefert eine unbekannte Kennung `nil` statt eines leeren Eintrags?
* Liefert eine unbekannte Klasse eine leere **Liste** (nicht `nil`) —
  weil der Aufrufer darüber iteriert?
* Trägt **jeder** Boss eine `order`, wenn `orderKnown = true` — und
  **keiner** eine, wenn `orderKnown = false`?
* Fassen die Flügel einer Instanz zusammen **jeden** ihrer Bosse? Einer
  ohne Flügel wäre in der Oberfläche nirgends zu sehen, lautlos.
* Nennt **jede** Beschwörungsanleitung ihre Herkunft?
* Ist `bossCount` nie kleiner als die Zahl der benannten Bosse?
* Sind die Kennungen über **beide** Dungeontabellen eindeutig? Eine
  Kollision lieferte still den falschen Dungeon.

Diese Prüfungen bleiben gültig, egal was später in den Tabellen steht.

## Die Client-Aufrufe

Es gibt **keine laufende Forever-Instanz**, an der sich Signatur oder
Verhalten eines API-Aufrufs prüfen liessen. Jeder Aufruf geht deshalb
durch eine defensive Hülle (`Safe()` in `charakter.lua`, `SafeCall()` in
`encounter_tracking.lua`, `Safe()` in `groupcheck.lua`) und liefert bei
einem Fehlschlag `nil`.

Im Zweifel stirbt der Aufruf und nicht das Addon — und der Zustand
bleibt „nicht beantwortet", nie „nichts da".
