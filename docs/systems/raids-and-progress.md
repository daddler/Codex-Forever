# Schlachtzüge, Bosse und Fortschritt

## Der Bestand

`data/raids.lua` führt drei Schlachtzüge. Bekannt sind je drei Dinge:
Name, Gruppengrösse und dass sie zum Erscheinungsinhalt gehören.

| Kennung | Name | Grösse | Öffnet |
|---|---|---|---|
| `barrow_deeps` | Barrow Deeps | 10 | 09.12.2026 |
| `hyjal_summit` | Hyjal Summit | 20 | 09.12.2026 |
| `onyxias_hort` | Onyxias Hort | 40 | 09.12.2026 |

**Die Bosslisten sind leer, und das ist ein Zustand, kein Rückstand.**
Sie sind nicht veröffentlicht. Die Listen aus Mists of Pandaria zu
übernehmen wäre der schlechteste der drei möglichen Zustände gewesen:
eine gefüllte Liste schweigt nicht, sie sagt etwas Falsches — „noch
8 Bosse offen" über einen Schlachtzug, dessen Bosse niemand kennt.

Dieselbe Entscheidung, dieselbe Begründung wie drüben:
`../Companion-Forever/docs/systems/forever-data.md`.

### Nachtragen

```lua
bosses = {
    { id = "...", name = "...", order = 1 },
}
```

`id` ist der stabile Schlüssel (Fortschritt und Notizen hängen daran),
`name` der deutsche Anzeigename, `order` die Pullreihenfolge.

**Am Code ist dafür nichts zu ändern.** Seite, Übersicht, Suche und
Fortschritt greifen den Bestand von selbst auf, und `data_test.lua`
kippt automatisch auf den anderen Prüfzweig.

`journalId` bleibt vorerst `nil`: welche Encounter-Journal-Kennungen
Forever vergibt, ist unbekannt, und eine geratene Kennung liest sich im
Code wie eine belegte.

## Die drei Bestände der Seite

`modules/raidpages.lua` hält drei **unabhängige** Quellen auseinander.
Das ist der eigentliche Entwurf dieser Seite:

1. **Die Bossliste** (`data/raids.lua`). Leer → „noch nicht bekannt",
   kein Fortschrittsbalken, keine Bosszahl im Seitenkopf. Eine `0` wäre
   keine leere Auskunft, sondern eine falsche.
2. **Der Lockout** (Server). Eine echte Auskunft, **unabhängig von der
   Bossliste**: „du hast diese Woche schon eine ID" lässt sich sagen,
   ohne einen einzigen Bossnamen zu kennen. Er steht deshalb auch dann
   da, wenn sonst nichts da ist.
3. **Bossnotizen des Bots** (`SavedData.bossData`, über
   `WCIMPORT:BOSS`). Ein dritter Bestand, der erscheint, sobald etwas
   importiert wurde — auch wenn die Bosslisten noch fehlen. Die Gilde
   weiss unter Umständen früher, was sie pullt, als diese Datei es
   weiss.

Weil ohne Bosslisten keine Zuordnung Notiz → Schlachtzug möglich ist,
steht genau das im Detailbereich, statt eine zu erfinden.

## Der Fortschritt

`modules/encounter_tracking.lua` kombiniert zwei Quellen:

| Quelle | Liefert | Liefert nicht |
|---|---|---|
| Blizzards Lockout-API (`GetSavedInstanceInfo`) | den echten Kill-Status, auch für Kills vor dieser Sitzung | Wipe-Zahlen |
| Eigenes `ENCOUNTER_END`-Tracking | selbst gezählte Wipes und den besten Versuch | nichts Rückwirkendes |

**Der Fortschritt gehört dem Charakter, nicht dem Konto.** Ein
Schlachtzugs-Lockout ist an den einzelnen Charakter gebunden: der Main
hat gelegt, der Twink steht am Mittwoch trotzdem vor einem vollen Raid.
Ablage:

```
SavedData.encounterProgress.characters["Name-Realm"][instanz]
```

`bestTries` liegt bewusst **neben** `bosses`: der Wochenreset leert
`bosses`, der beste Versuch soll ihn überleben.

### `SavedLockouts()`

Die Frage „habe ich diese Woche schon eine ID?" beantwortet der Server,
nicht unser Zähler. `SavedLockouts()` geht deshalb direkt an die
Lockout-API und ordnet über den **Namen** aus `data/raids.lua` zu.

Zwei Dinge daran sind nicht Geschmack:

* **Was nicht passt, fällt still heraus.** Eine falsche Zuordnung wäre
  schlimmer als keine: sie zeigte eine ID auf einem Schlachtzug an, den
  man nie betreten hat.
* **Eine leere Antwort heisst „keine ID", eine fehlende API heisst
  gar nichts.** Beide Fälle liefern eine leere Tabelle; die Oberfläche
  sagt dann „Keine gespeicherte ID" nur dort, wo der Server tatsächlich
  geantwortet hat.

Mehrere IDs derselben Instanz (Grössen, Schwierigkeiten) werden
zusammengefasst — die mit der längsten Restzeit gewinnt, weil sie die
ist, die noch bindet. LFR-Lockouts zählen nicht mit.

## Alle Client-Aufrufe sind defensiv

`pcall` plus Typprüfung, durchgängig. Es gibt keine laufende
Forever-Instanz, an der sich Signatur oder Verhalten prüfen liessen — im
Zweifel wird der Status **nicht gesetzt** (bleibt „offen"), niemals
geraten.
