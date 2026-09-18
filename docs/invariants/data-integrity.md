# Datenintegrität: `unknown` ist nicht `0`

Die eine Regel, die in diesem Repo über allen anderen steht. Sie ist
hier keine Theorie, sondern der Normalfall: **die meisten Zahlen, die
dieses Addon anzeigen könnte, kennt es noch nicht.**

## Die Regel

> Eine fehlende Angabe ist `nil`. Sie ist nie `0`, nie `false`, nie ein
> leerer Balken und nie ein roter Punkt.

Drei Zustände, die nirgends zusammenfallen dürfen:

| Zustand | Heisst | Darstellung |
|---|---|---|
| `nil` | „nicht gemessen / nicht bekannt" | Gedankenstrich, Kontur statt Punkt, Text „noch nicht bekannt" |
| `0` | „gemessen, und das Ergebnis ist null" | Zahl, Punkt in der passenden Farbe |
| gesperrt | „es gibt Daten, du darfst sie nicht sehen" | „Gesperrt", nie eine Zahl |

Wer die drei zusammenzieht, macht aus einer Datenlücke einen Befund.
Genau dieselbe Konvention gilt drüben in der Companion (`stars == 0`
heisst „keine Daten", `at == -1` heisst „kein Zeitpunkt bekannt") — sie
ist der Grund, warum die beiden Programme dieselbe Sprache sprechen.

## Wo sie in diesem Addon greift

### Die Bosslisten (`data/raids.lua`)

`WeintCodex.RaidData.KnownBossCount()` liefert **`nil`**, solange keine
einzige Bossliste gefüllt ist — nicht `0`. Die Übersicht schreibt
deshalb „bosse offen" statt „0 bosse", und die Schlachtzugsseite zeigt
keinen Fortschrittsbalken bei null Prozent.

`WeintCodex.RaidData.HasBosses(raid)` ist der Weg, nach dem zu fragen.
Wer stattdessen `#raid.bosses` zählt, bekommt `0` und weiss nicht, was
die `0` bedeutet.

`.github/tests/data_test.lua` hält das fest — und zwar in beide
Richtungen: solange nichts eingetragen ist, muss `KnownBossCount()`
`nil` liefern; sobald der erste Boss eingetragen wird, muss es die
Summe sein. An der Prüfung ist dafür nichts zu ändern.

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

## Wie man das prüft, wenn nichts drinsteht

Ein Test, der über eine leere Tabelle läuft, wird grün, weil nichts
passiert — lautlos und wertlos. Deshalb prüft `data_test.lua` den
**Mechanismus** statt den Bestand:

* Liefert `KnownBossCount()` `nil` statt `0`, solange nichts da ist?
* Stimmt `HasBosses()` mit dem tatsächlichen Bestand überein?
* Liefert eine unbekannte Kennung `nil` statt eines leeren Eintrags?
* Liefert eine unbekannte Klasse eine leere **Liste** (nicht `nil`) —
  weil der Aufrufer darüber iteriert?

Diese Prüfungen bleiben gültig, egal was später in den Tabellen steht.

## Die Client-Aufrufe

Es gibt **keine laufende Forever-Instanz**, an der sich Signatur oder
Verhalten eines API-Aufrufs prüfen liessen. Jeder Aufruf geht deshalb
durch eine defensive Hülle (`Safe()` in `charakter.lua`, `SafeCall()` in
`encounter_tracking.lua`, `Safe()` in `groupcheck.lua`) und liefert bei
einem Fehlschlag `nil`.

Im Zweifel stirbt der Aufruf und nicht das Addon — und der Zustand
bleibt „nicht beantwortet", nie „nichts da".
