# Kopflose Prüfläufe

Zwei Läufe, beide mit einem gewöhnlichen Lua 5.1 und ohne Spiel:

```bash
lua5.1 .github/tests/load_test.lua .
lua5.1 .github/tests/data_test.lua .
```

Rückgabewert 0 heisst bestanden. Beide laufen in der CI bei jedem Push
und vor jedem Release.

Der Ordner liegt unter `.github/`, weil die Release-Workflows genau den
aus dem Addon-ZIP heraushalten — ein Testlauf gehört nicht in den
Addon-Ordner eines Spielers.

---

## Warum es sie gibt

**World of Warcraft: Forever ist nicht erschienen.** Es gibt kein Spiel,
in dem sich dieses Addon ausprobieren liesse. Bis dahin wäre `luac -p`
alles, was bliebe — und `luac -p` findet ausschliesslich Syntaxfehler.

Die drei Fehler, die im Spiel am teuersten sind, sind syntaktisch
tadellos:

* eine Datei, die in `WeintCodex.toc` **fehlt** (sie lädt nicht — ohne
  Fehler, ohne Hinweis),
* eine Datei, die dort **zu früh** steht
  (`attempt to index a nil value (field 'Colors')`),
* ein Zugriff auf ein Modul, das es **nicht mehr gibt** — in dieser
  Fassung besonders naheliegend, weil ein gutes Dutzend Module aus der
  MoP-Fassung entfallen ist.

---

## `load_test.lua`

Lädt das ganze Addon gegen `wow_stub.lua` in der Reihenfolge der `.toc`,
stellt `ADDON_LOADED` und `PLAYER_LOGIN` zu und prüft danach sechs Dinge:

1. **Es lädt.** Jede Datei und jede von einer `.xml` eingebundene
   Bibliothek läuft durch.
2. **`ADDON_LOADED` legt `WeintCodex_SavedData` an** — und
   `WeintCodex.SavedData` zeigt auf **dieselbe** Tabelle, nicht auf eine
   Kopie. Das ist die Prüfung hinter der Regel „niemals in eine frisch
   angelegte Ersatztabelle schreiben": WoW speichert nur, was in der
   `.toc` steht, und eine Ersatztabelle verlöre die Daten beim Abmelden,
   ohne dass irgendetwas fehlschlägt. `PLAYER_LOGIN` läuft gleich mit —
   dort melden sich Charakter und Twinkliste an die Companion.
3. **Jede `.lua` unter `core/`, `data/` und `modules/` steht in der
   `.toc`.** Die Gegenrichtung (eine `.toc`-Zeile ohne Datei) fällt
   schon beim Laden auf.
4. **Jeder Navigationseintrag findet sein Modul.** Gelesen wird dafür
   `core/navigation.lua` selbst — eine zweite Liste hier wäre eine
   zweite Wahrheit.
5. **Kein Zugriff auf ein Modul, das es nicht gibt.** Jeder Ausdruck
   `WeintCodex.<Name>` in `core/` und `modules/` wird gegen das
   geprüft, was nach dem Laden tatsächlich dasteht (Kommentare zählen
   nicht mit — dort stehen Verweise auf entfallene Module absichtlich).

   **Diese Prüfung hat einen echten Fall gefunden:**
   `modules/calendar.lua` rief nach der Umbenennung der Anmeldeliste
   weiterhin `WeintCodex.Raids.HasLineup()` — ungeschützt, also ein
   Lua-Fehler beim ersten Öffnen des Kalenders. Aus der MoP-Fassung ist
   ein gutes Dutzend Module entfallen; das ist die naheliegendste
   Fehlerklasse dieser Fassung.
6. **Jede Seite lässt sich zeichnen.** `SwitchTo` wird für alle elf
   Navigationseinträge aufgerufen. Laden und Zeichnen sind zwei
   verschiedene Zeitpunkte — ein Modul kann tadellos laden und beim
   ersten Klick auf einen `nil`-Wert laufen. Es entsteht dabei kein
   Bild; geprüft ist ausschliesslich, dass der Aufbau durchläuft.
7. **Jede *Instanz* lässt sich zeichnen**, nicht nur die erste.
   `SwitchTo` schlägt je Seite den zuletzt gewählten Eintrag auf — im
   kopflosen Lauf also immer den ersten. Genau die interessanten Fälle
   blieben damit ungeprüft: Onyxias Hort **ohne** Bossliste nimmt einen
   anderen Zweig als die beiden mit, und Hyjal Summits dreizehn Bosse
   bauen ein Bildlauffeld, das Barrow Deeps' acht nicht brauchen. Dazu
   der Klick auf eine Bosszeile, der den Detailbereich mit den
   Rollen-Tipps neu aufbaut — ein dritter Zeitpunkt, an dem etwas
   brechen kann.
8. **Der eine Akzent ist einer.** `accent`, `purple`, `violet` und
   `brandA` müssen denselben Ton tragen. Laufen sie auseinander, stehen
   wieder zwei Bedeutungsfarben nebeneinander — genau der Zustand, den
   „Graphit" abgelöst hat.

---

## `data_test.lua`

Prüft die Datentabellen und die Fassungsangaben.

**Die Fassung steht an vier Stellen** (`.toc`, `core/main.lua`,
`data/changelog.lua`, `CHANGELOG.md`). Laufen sie auseinander, lädt das
Addon einwandfrei — und WeintCompanion meldet danach nach jeder
Aktualisierung erneut dasselbe Update. Dieselbe Prüfung macht
`.github/scripts/release_notes.py` für die CI; hier steht sie, damit sie
schon vor dem Tag läuft.

**Die leeren Tabellen müssen leer bleiben dürfen.** Ein Test, der über
eine leere Liste läuft, wird grün, weil nichts passiert — lautlos und
wertlos. Geprüft wird deshalb der *Mechanismus*:

| Prüfung | Hält fest |
|---|---|
| `KnownBossCount()` liefert `nil`, nicht `0` | solange keine Bossliste gefüllt ist |
| `KnownBossCount()` liefert die Summe | sobald eine gefüllt ist — ohne Änderung an der Prüfung |
| `HasBosses()` stimmt mit dem Bestand überein | in beide Richtungen |
| **keine Bossliste ohne Herkunft** | eine gefüllte Liste ohne `bossSource` fällt durch — und eine leere **mit** ebenso |
| `order` stimmt mit der Position überein | sonst zeigt die Seite eine andere Pullreihenfolge an, als die Liste meint |
| neun Dungeons, je mit beiden Stufen und einem Gebiet | ein halber Stufenbereich ist kein Bereich |
| `FitsLevel()` ohne Stufe liefert `nil`, nicht `false` | „passt nicht" wäre eine Behauptung über eine Stufe, die niemand kennt |
| `Roles.Frame(10/20/40)` liefert `nil` | wie viele Tanks ein Schlachtzug braucht, entscheiden seine Bosse |
| „Wilder Kampf" steht unter Tank **und** Schaden | und nicht bei den Heilern |
| `Roles.Tips()` unterscheidet vier Zustände | gesperrt ≠ nie importiert ≠ Rolle leer ≠ Tipps |
| neun Klassen mal drei Bäume | gegen `analyzer/data/specs.py` der Companion |
| „Wilder Kampf" trägt **keine** Rolle | er ist beide, und das ist die richtige Antwort |
| jede andere Spezialisierung trägt eine | eine fehlende wäre hier eine Lücke |
| ein Sollbestand ist eine Zahl **oder gar nicht da** | nie eine 0 |
| die neun Freigaben stehen in `core/access.lua` | gegen `core/access_roles.py` drüben |

Diese Prüfungen bleiben gültig, egal was später in den Tabellen steht.

---

## `wow_stub.lua`

Ein World of Warcraft, so weit es zum **Laden** reicht.

Es ist bewusst **dumm**: es bildet kein Verhalten nach und beantwortet
keine Spielfrage. Jede Methode eines Frames, die nicht ausdrücklich
aufgeführt ist, ist eine Funktion, die nichts tut und nichts liefert.
Ausdrücklich aufgeführt sind nur die, deren *Rückgabewert* das Addon
weiterverwendet — gäben sie `nil` zurück, bräche der Aufrufer an einer
Stelle, die mit dem echten Fehler nichts zu tun hat, und der Lauf
meldete etwas anderes, als er gefunden hat.

`C_Timer.After` feuert **nie**. Das ist Absicht: dieser Lauf prüft das
Laden, nicht das Verhalten — ein sofort ausgeführter Rückruf liefe in
einer Umgebung, die es so nie gibt.

Die `.xml`-Dateien der Bibliotheken werden **nicht übersprungen**: die
eine `<Script file="…"/>`-Zeile darin wird herausgelesen und die Datei
geladen. LibDataBroker bricht ab, wenn CallbackHandler fehlt — und genau
diese Reihenfolge soll der Lauf ja prüfen.

---

## Was diese Läufe **nicht** leisten

Sie sagen nichts darüber, ob eine Seite richtig aussieht, ob eine
Rechnung stimmt oder ob der echte Client dieselben Antworten gibt.

**Ein grüner Lauf heisst „es lädt", nicht „es funktioniert".**
