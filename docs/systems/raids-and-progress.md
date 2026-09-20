# Schlachtzüge, Bosse und Fortschritt

## Der Bestand

`data/raids.lua` führt drei Schlachtzüge. Name, Gruppengrösse und
Öffnungstermin sind angekündigt; die Bosslisten sind es nicht — für
zwei der drei stehen sie im Beta-Client (siehe nächster Abschnitt).

Die Dungeons stehen daneben in `data/dungeons.lua` und haben eine
eigene Seite: `docs/systems/dungeons.md`.

| Kennung | Name | Grösse | Öffnet |
|---|---|---|---|
| `barrow_deeps` | Barrow Deeps | 10 | 09.12.2026 |
| `hyjal_summit` | Hyjal Summit | 20 | 09.12.2026 |
| `onyxias_hort` | Onyxias Hort | 40 | 09.12.2026 |

## Die Bosslisten: zwei vorläufig, eine leer

| Schlachtzug | Bosse | Zustand |
|---|---|---|
| Barrow Deeps | 8 | **vorläufig**, Beta-Client 1.60.1.69876 |
| Hyjal Summit | 13 | **vorläufig**, Beta-Client 1.60.1.69876 |
| Onyxias Hort | — | nicht bekannt |

Bis 5.0.0.0 war die Tabelle leer, weil über die Bosse von Forever
nichts veröffentlicht war. Seit dem Beta-Start am 17.09.2026 liegen
die Encounter-Listen für zwei der drei Schlachtzüge **im Client**.

**Das ist kein Bruch der alten Regel, sondern ihr Ergebnis.** Die
Regel lautete nie „hier darf nichts stehen", sondern: es darf nichts
dastehen, dessen Herkunft sich nicht benennen lässt. Genau deshalb
durften die Listen aus Mists of Pandaria nicht hierher — sie hätten
über Forever nichts ausgesagt. Der Beta-Client sagt etwas über
Forever aus, nur eben nichts Endgültiges.

### Herkunft ist Pflicht

Jede gefüllte Bossliste trägt ein `bossSource`:

```lua
bossSource = { kind = "beta", build = "1.60.1.69876",
               date = "17.09.2026", label = "Beta-Client 1.60.1.69876" }
```

| `kind` | Heisst | Folge in der Oberfläche |
|---|---|---|
| `"beta"` | aus den Clientdateien, nicht angekündigt | überall „Vorläufig · …" daneben |
| `"release"` | von Blizzard bestätigt | kein Zusatz |
| fehlt | — | **`data_test.lua` schlägt fehl** |

`BossesConfirmed()` liefert nur bei `"release"` `true`. Eine
vergessene, unbekannte oder kaputte Quelle gilt als **nicht**
bestätigt — die Richtung, in die ein Irrtum harmlos ist.

`BossListState()` fasst den Bestand für Übersicht und Diagnose
zusammen: `none`, `provisional`, `partial`, `confirmed`. Er entscheidet
dort über Ton **und** Text; „Bosslisten hinterlegt" in Grün über einem
Bestand aus dem Beta-Client wäre zu viel versprochen.

### Onyxias Hort bleibt leer

Dass Onyxia die einzige Bossin ihres Horts ist, weiss jeder aus zwanzig
Jahren Azeroth. Im Beta-Client steht für diese Instanz trotzdem keine
Encounter-Liste, und Blizzard hat zu Änderungen am Kampf nichts gesagt.
**„Weiss man doch" ist keine Quelle.** Sobald der Client eine Liste
führt, steht sie da, mit ihrer Herkunft daneben.

Dieselbe Grundentscheidung, dieselbe Begründung wie drüben:
`../Companion-Forever/docs/systems/forever-data.md`.

### Nachtragen

```lua
bossSource = BETA_CLIENT,   -- oder { kind = "release", label = "..." }
bosses = {
    { id = "...", name = "...", order = 1 },
}
```

`id` ist der stabile Schlüssel (Fortschritt und Notizen hängen daran),
`name` der Anzeigename, `order` die Pullreihenfolge — und `order` muss
mit der Position übereinstimmen, sonst schlägt `data_test.lua` fehl.

**Die Namen bleiben englisch.** Forever hat keine deutsche
Lokalisierung veröffentlicht; ein selbst übersetzter Bossname stünde
später anders im Client als hier, und die Zuordnung der Bossnotizen des
Bots liefe daneben.

**Am Code ist sonst nichts zu ändern.** Seite, Übersicht, Suche und
Fortschritt greifen den Bestand von selbst auf.

`journalId` bleibt vorerst `nil`: welche Encounter-Journal-Kennungen
Forever vergibt, ist unbekannt, und eine geratene Kennung liest sich im
Code wie eine belegte.

## Die vier Bestände der Seite

`modules/raidpages.lua` hält vier **unabhängige** Quellen
auseinander. Das ist der eigentliche Entwurf dieser Seite:

1. **Die Bossliste** (`data/raids.lua`). Fehlt sie → „noch nicht
   bekannt", kein Fortschrittsbalken, keine Bosszahl im Seitenkopf.
   Eine `0` wäre keine leere Auskunft, sondern eine falsche. Ist sie
   da, steht ihre **Herkunft** in derselben Zeile wie die Bosszahl —
   wer die Zahl liest, liest den Vorbehalt im selben Blick.
2. **Der Lockout** (Server). Eine echte Auskunft, **unabhängig von der
   Bossliste**: „du hast diese Woche schon eine ID" lässt sich sagen,
   ohne einen einzigen Bossnamen zu kennen. Er steht deshalb auch dann
   da, wenn sonst nichts da ist.
3. **Der Fortschritt** (`modules/encounter_tracking.lua`). Gelegt oder
   offen, je Boss.
4. **Die Rollen-Tipps des Bots** (`SavedData.bossData`, über
   `WCIMPORT:BOSS`). Was Tank, Heiler und Schadensausteiler an einem
   Boss zu tun haben, weiss dieses Addon aus genau einer Quelle — dem
   Discord-Bot. Ein Klick auf einen Boss schlägt sie im Detailbereich
   auf. Siehe `docs/systems/dungeons.md`, Abschnitt *Die Rollen*.

Notizen zu Namen, die in **keiner** Liste stehen (ein Dungeonboss, ein
Boss aus einem neueren Build), stehen weiterhin gesammelt und ohne
Zuordnung im Detailbereich — statt sie einem Schlachtzug zuzuschlagen,
zu dem sie vielleicht nicht gehören.

### Die Bossliste steht links, nicht in der Seite

Hyjal Summit hat dreizehn Bosse; in eine Karte im Inhaltsbereich
passen sie nicht. Der erste Anlauf gab der Liste ein Bildlauffeld —
und das war zweimal falsch: eine Liste, die man ohnehin zur
Orientierung braucht, gehört in die **Navigation**, nicht in den
Inhalt; und ausgerechnet die Mitte scrollen zu lassen ist die
unangenehmste Stelle dafür.

Die Unternavigation ist deshalb ein **Baum**: die drei Schlachtzüge auf
der ersten Ebene, die Bosse des **ausgewählten** eingerückt auf der
zweiten. Damit stehen beide Antworten auf *wo bin ich* gleichzeitig und
dauerhaft da — in welcher Instanz, an welchem Boss —, und der
Inhaltsbereich wird frei für das, wofür links kein Platz ist: den
ausgewählten Boss mit seinen drei Rollen.

Nur die Bosse des ausgewählten Schlachtzugs: alle einundzwanzig
gleichzeitig wären wieder eine Spalte, die scrollen müsste, und Bosse
eines Schlachtzugs, in dem man gerade nicht steckt, beantworten keine
Frage.

Je Bosseintrag stehen links ein Statuspunkt (gelegt / offen) und
rechts das Kennzeichen `TIPPS`, wo Rollen-Tipps des Bots vorliegen —
und nur dort. Ein Zeichen an jeder Zeile wäre keine Auskunft.

Dass nichts davon scrollen muss, ist **nachgerechnet und geprüft**,
nicht geschätzt: siehe `docs/architecture/overview.md`, Abschnitt
*Nichts muss scrollen*.

### Von aussen auf einen Boss zeigen

`RaidPages.Select(raidId, bossId)` setzt die Auswahl; der Aufruf danach
(`GoToTab`) öffnet die Seite damit. Die globale Suche benutzt das: wer
„Sonya Darkhallow" eingibt, landet bei Sonya Darkhallow — nicht auf
einer Schlachtzugseite, die gerade etwas anderes aufgeschlagen hat.

Eine unbekannte Kennung wählt nichts aus (`false`), eine Bosskennung
aus dem falschen Schlachtzug wählt die Instanz und keinen Boss.
`DungeonPages.Select` ist dasselbe für die Dungeons.

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
