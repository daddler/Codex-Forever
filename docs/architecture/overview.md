# Oberfläche: Aufbau und Designsprache „Graphit"

## Das Bild

Die Designsprache ist **dieselbe wie in WeintCompanion 5**, und das ist
kein Zufall, sondern eine Anforderung: wer zwischen Spiel und Desktop
wechselt, soll nicht zwei Programme sehen.

Die Werte in `core/ui.lua` sind die Übersetzung von
`../Companion-Forever/gui/theme/tokens.py` in WoW-Gleitkommafarben.
Läuft die Palette dort weiter, wird hier nachgezogen — **und sonst
nirgends.** Ein Hex-Wert ausserhalb von `core/ui.lua` ist eine Fläche,
die beim nächsten Palettenwechsel übersehen wird.

Die Leitideen:

* **Tiefe entsteht durch Schichtung, nicht durch Rahmen.** Eine Karte
  hat keinen umlaufenden Rahmen, sondern einen senkrechten Verlauf und
  eine 1-px-Oberkante. `sunken < base < card < raised` ist die
  Staffelung.
* **Ein Akzent, und er trägt ausschliesslich Bedeutung.** Violett
  (`#7C6CFF`). Er färbt den aktiven Navigationseintrag, den Hauptknopf,
  Fortschritt und Fokusrahmen — sonst nichts. Deshalb bleibt die
  Oberfläche grau.
  `accent`, `purple`, `violet` und `brandA` zeigen alle auf denselben
  Ton; `load_test.lua` hält sie darauf fest.
* **Drei Schriften, drei Aufgaben.** Newsreader (Serife) für
  Überschriften, IBM Plex Sans für alles Bedienbare, IBM Plex Mono für
  Zahlen und Rubriken.
* **Bedeutungsfarben sind vom Akzent unabhängig.** Grün, Gelb, Rot,
  Blau bedeuten immer dasselbe.

## Drei Dinge, die in WoW anders gelöst werden müssen

| Entwurf | In WoW |
|---|---|
| `border-radius` | Frames können keinen haben. Vier Viertelkreis-Masken **in der Farbe dahinter** stanzen die Ecken aus (`CutCorners`). Jede Fläche nimmt deshalb ein `backdrop` — der Aufrufer muss wissen, worauf sie liegt. |
| `linear-gradient(180deg, a, b)` | `SetGradient("VERTICAL", min, max)` läuft von **unten nach oben**. Die beiden Farben werden vertauscht übergeben (`ApplyVerticalGradient`). |
| `letter-spacing` | Gibt es nicht. Die Sperrung der Rubriklabels wird durch eingefügte Haarspatien nachgebildet (`Spaced`) — **je Zeichen, nicht je Byte** (siehe unten). |

## UTF-8

Der Client liefert und erwartet UTF-8, Lua 5.1 kennt aber nur Bytes.
Jede Stelle, die Text **zeichenweise** anfasst — sperren, kürzen,
versalisieren — muss selbst wissen, wo ein Zeichen anfängt.

Tut sie das nicht, zerfällt ein Umlaut in seine zwei Bytes, und der
Client zeichnet für jedes ein leeres Kästchen. So wurde in der
Vorgängerfassung aus „ÜBERSICHT" ein „<>BERSICHT".

**Nie** `string.upper`, `#` oder `:sub` auf Anzeigetext. Stattdessen:

| statt | nimm |
|---|---|
| `string.upper(s)` | `WeintCodex.Upper(s)` |
| `#s` | `WeintCodex.Utf8Len(s)` |
| `s:sub(a, b)` | `WeintCodex.Utf8Sub(s, a, b)` |
| Kürzen | `WeintCodex.Truncate(s, n)` |
| Sperren | `WeintCodex.Spaced(s)` |

`FormatGrouped` hat denselben Grund für einen kleinen Umweg: `string.reverse`
dreht Bytes. Ein direkt eingefügtes schmales Leerzeichen käme verdreht und
damit als ungültige UTF-8-Folge wieder heraus.

## Der Fensteraufbau

```
┌──────────────────────────────────────────────────────────┐
│ Titelleiste 40   [Marke] WeintCodex · Pfad   Suche   v…×│
├────────────┬─────────────────────────────────────────────┤
│            │                                             │
│ Navigation │   ContentPanel          │  Detailbereich    │
│    232     │   (die Seite)           │      372          │
│            │                         │                   │
│ ┌────────┐ │                         │                   │
│ │ Konto  │ │                         │                   │
│ └────────┘ │                         │                   │
└────────────┴─────────────────────────────────────────────┘
```

* **`core/ui.lua`** baut die Flächen und die Bausteine (Karte, Knopf,
  Schalter, Regler, Chip, Statuspunkt, Seitenkopf, Bildlauf).
* **`core/navigation.lua`** füllt die Navigationsspalte, verteilt die
  Klicks auf die Module (`SwitchTo`), zeichnet die Startseite
  (`ShowHome`) und stellt den Detailbereich bereit (`SetInspector`).
* Die Module zeichnen ausschliesslich in `WeintCodex.ContentPanel` und
  rechnen gegen dessen Grösse. Ob rechts ein Detailbereich steht oder
  links eine Unternavigation, verändert nur die Grösse dieser Fläche —
  die Module merken davon nichts.

### Der Detailbereich

`WeintCodex.Navigation.SetInspector(blocks)` nimmt eine Liste von
Blöcken und zeichnet sie rechts. Er erscheint nur, wenn es etwas zu
zeigen gibt.

| `type` | wofür |
|---|---|
| `header` | Zwischenüberschrift |
| `rows` | Beschriftung ↔ Wert, das Arbeitspferd |
| `card` | ein Kasten mit Fliesstext (`lines`) |
| `text` | eine Zeile Fliesstext |
| `list` / `checklist` | Karten bzw. Hakenzeilen (`items`) |
| `itemlist` | Gegenstandszeilen mit Tooltip |
| `input` | Eingabefeld (ein- oder mehrzeilig) |
| `notes` | Notizfeld mit eigenem Bildlauf |
| `button` | Schaltfläche (`label`, `onClick`) |
| `divider` / `spacer` | Trenner |

**Der Detailbereich trägt Tatsachen und Begründungen, keine
Bedienung.** Was man umstellen kann, steht dort, wo man es sieht — die
einzige Ausnahme sind Knöpfe, die woanders hinführen.

### Die Unternavigation

`BuildSidebar(titel, items)` entscheidet die Form selbst: bis sieben
reine Beschriftungen wird es eine Reiterleiste über dem Inhalt, alles
darüber (oder sobald ein Eintrag mehr trägt als eine Beschriftung) eine
Listenspalte links.

**Die Listenspalte ist zweistufig.** Ein Eintrag mit `indent = true`
sitzt eingerückt unter dem vorangehenden und gehört zu ihm — so stehen
die Bosse eines Schlachtzugs unter ihrem Schlachtzug. Der Grund ist
nicht Platz, sondern Orientierung: *wo bin ich* ist auf zwei Ebenen zu
beantworten (in welcher Instanz, an welchem Boss), und beide Antworten
stehen damit gleichzeitig und dauerhaft da statt nacheinander in einer
Brotkrume.

| Feld | Wirkung |
|---|---|
| `label` | Beschriftung (Pflicht) |
| `status` | zweite Zeile — **Text oder** `{ text = , color = }` |
| `indent` | zweite Ebene: kleiner, eingerückt, mit Führungslinie |
| `dot` | Statuspunkt links (nur mit `indent`) |
| `mark` / `markColor` | Kennzeichen rechts, mono und gesperrt |
| `portrait` | Bild links |
| `accentColor` | dauerhafter Streifen am linken Rand |
| `isGroup` | nicht anklickbare Zwischenüberschrift |

`status` nahm bis 5.1.0.0 ausschliesslich die Tabellenform. Die
Schlachtzugseite übergab seit jeher einen nackten String (`"10er"`) —
Lua indiziert einen String ohne Fehler, `("10er").text` ist `nil`, die
Zeile wurde also 44 px hoch gebaut und blieb **leer**. Kein Fehler,
keine Meldung, nur eine Auskunft, die nie ankam. Beide Formen sind
jetzt erlaubt.

### Nichts muss scrollen

Zwei Spalten können über den Fensterrand hinauslaufen, und beide tun es
lautlos: ein Navigationseintrag unter der Kontozeile und ein
Bosseintrag unter dem Fensterrand sehen nicht aus wie ein Fehler,
sondern wie eine Funktion, die es nicht gibt.

Die Rechnung dafür stand bis 5.1.0.0 als Kommentar („wer hier etwas
ergänzt, rechnet nach"). Ein Kommentar prüft nichts. Jetzt rechnen vier
Funktionen sie nach, und `.github/tests/load_test.lua` hält sie
gegeneinander:

| Funktion | Antwortet |
|---|---|
| `Navigation.NavColumnHeight()` | was die Navigationsspalte belegt |
| `Navigation.NavColumnBudget()` | was ihr beim kleinsten Fenster zusteht |
| `Navigation.SubNavHeight()` | was die zuletzt gebaute Listenspalte belegt |
| `Navigation.SubNavBudget()` | was ihr zusteht |
| `Navigation.MeasureSidebar(items)` | wie hoch eine Liste **würde**, ohne sie zu bauen |

Stand heute: Navigationsspalte 604 von 684 px, Unternavigation im
schlimmsten Fall (Hyjal Summit mit dreizehn Bossen) 602 von 716 px. Der
Prüflauf verlangt zusätzlich **Luft für einen weiteren Eintrag** — ohne
das fällt erst der Eintrag auf, der schon nicht mehr passt, und dann
ist die Frage nicht mehr „passt er?", sondern „was werfen wir raus?".

## Der Seitenkopf

`WeintCodex.PageHead(parent, opts)` ist der **einzige** Ort, an dem ein
Seitenkopf entsteht. Vorher baute ihn jede Seite selbst, und im selben
Stand standen drei Titelformen nebeneinander.

```lua
local head = WeintCodex.PageHead(f, {
    eyebrow = "Schlachtzug",
    title   = raid.name,
    sub     = "Bosse noch nicht bekannt",
    height  = 92,
    stats   = { { key = "size", label = "Gruppe", value = raid.size } },
})
```

Die Bausteine hängen **aneinander** (Titel unter dem Eyebrow,
Unterzeile unter dem Titel) statt an gerechneten Y-Werten — eine
Ankerkette braucht keine geschätzten Schriftmetriken.

## Farben ansprechen

```lua
local C = WeintCodex.Colors
tex:SetColorTexture(unpack(C.accent))
WeintCodex.ColorText("textMuted", "Text")     -- für Chat und FontStrings
```

Ein Name, den es nicht gibt, färbt still auf Normaltext zurück.
`ColorText` gibt den Text dann **ungefärbt** zurück — genau die Sorte
Fehler, die man erst im Spiel sieht. Deshalb bleiben in `core/ui.lua`
auch alte Namen bestehen und zeigen auf die neuen Werte, statt entfernt
zu werden.
