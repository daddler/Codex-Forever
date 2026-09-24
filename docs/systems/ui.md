# Die WeintCodex-Oberfläche (`ui/`)

## Was sie ist

Ein eigenes, schlichtes Interface zusätzlich zu WeintCodex:
Namensplaketten (Gegner und Freunde, mit Debuffs), Einheitenrahmen,
Gruppen- und Schlachtzugsrahmen, Aktionsleisten, Minikarte, Chat,
Taschen, Schadensanzeige, ein Questpfeil und eine Handvoll
Komfortfunktionen – eingestellt in einem eigenen Fenster (`/wcui`,
`/wc ui`, oder in den Einstellungen des Hauptfensters unter
„Oberfläche“).

## Freiwillig – und seit 6.0.0.3 vorübergehend nicht (`UIKit.OPT_IN`)

Gebaut ist sie **freiwillig**: Hauptschalter, Frage beim Einloggen
(`ui/welcome.lua`), und solange der Schalter aus ist, fasst WeintCodex
keinen Blizzard-Rahmen an.

Das setzt voraus, dass der Client die Wahl speichert. Der
Forever-Beta-Client tut das nicht (6.0.0.1 gemeldet, 6.0.0.2 bestätigt:
auch „Mit Esc schließen“ überlebt kein `/reload`). Eine Wahl, die nach
jedem Neuladen vergessen ist, ist keine. **Seit 6.0.0.3 ist die
Oberfläche deshalb für alle an.**

Die Rückkehr ist **eine Zeile**: `K.OPT_IN = false` in `ui/kit.lua` auf
`true`. Dann gilt ohne jede weitere Änderung wieder:

| Stelle | mit `OPT_IN = true` | mit `OPT_IN = false` (jetzt) |
|---|---|---|
| `UIKit.UIEnabled()` | liest den gespeicherten Hauptschalter | immer `true` |
| Frage beim Einloggen | nach der Einführung, einmal je Konto | kommt nie |
| Hauptschalter in `/wcui` | Schalter oben rechts und auf „Allgemein“ | Hinweis „derzeit für alle an“ |
| Einstellungen → Oberfläche | Schalter | derselbe Hinweis |
| Einführung, Kapitel „Oberfläche & Komfort“ | „ganz freiwillig“ | „derzeit für alle eingeschaltet“ |

Alle Stellen fragen `K.OPT_IN` zur Laufzeit; `load_test.lua` prüft beide
Zustände (die Frage und ihre Antworten laufen mit `OPT_IN = true` durch).
**Wann umschalten:** sobald Einstellungen → Diagnose → „Speichern“ nach
einem `/reload` „gespeichert“ meldet (`WeintCodex.SaveHealth()`).

Einzelne Module lassen sich in `/wcui` weiterhin abschalten – das gilt,
solange der Client nicht speichert, ebenfalls nur bis zum Neuladen.

## Zwei Arten von Modulen

| Gruppe | Module | Hängt am Hauptschalter? | Umschalten |
|---|---|---|---|
| `ui` | Namensplaketten, Einheitenrahmen, Gruppenrahmen, Aktionsleisten, Minikarte, Chat, Taschen, Schadensanzeige | **ja** (derzeit immer an) | nach dem Neuladen |
| `qol` | Questpfeil, Komfort | **nein** | sofort |

Der Unterschied ist Absicht: wer die Oberfläche nicht will, soll den
Questpfeil und das automatische Reparieren trotzdem haben können.

`ui`-Module **ersetzen** Blizzard-Rahmen. Einen ersetzten Rahmen im
laufenden Spiel sauber zurückzugeben, ist ohne Taint-Risiko nicht zu
haben – deshalb gilt jede Änderung an ihnen erst nach dem Neuladen, und
das Fenster sagt das (Fußleiste: „Wirkt nach dem Neuladen“ mit Knopf).

## Vorbild und Grenze

Aufbau, Funktionsumfang und Voreinstellungen folgen **EllesmereUI 9.2.6**
– Seitenleiste mit Gruppen, Kopf mit Modulschalter, Reiter,
zweispaltige Zeilen, Entsperrmodus; die Zahlen der Voreinstellungen
(Plakettenhöhe 17, Zielrahmen 181 breit, Stufe links auf der Plakette
usw.) stehen jeweils mit „Vorlage:“ am Wert.

**Übernommen sind Ideen, Optionsnamen und Zahlen – kein Code und keine
Grafik.** EllesmereUI steht unter einer eigenen Lizenz mit „all rights
reserved“. Seine Texturen, seine Schrift (Expressway, ein kommerzieller
Font) und sein Code gehören nicht in dieses Repository. Die einzige
neue Grafik, der Questpfeil, entsteht aus
`.github/scripts/make_ui_media.py`.

Farben und Schriften sind die von WeintCodex („Graphit“). Die
Spielweltfarben (feindlich, neutral, Boss …) stehen als
`WeintCodex.GameColors` in `core/ui.lua` – neben der Palette, nicht in
ihr. Boss und Elite sind ausdrücklich **nicht** violett (die Vorlage
färbt sie so): eine violette Plakette läse sich als „ausgewählt“.
`cast` (Fortschritt) und `targetRing` (Fokusrahmen) tragen den Akzent,
weil sie genau das sind, wofür er steht.

## Dateien

| Datei | Aufgabe |
|---|---|
| `ui/kit.lua` | Speicher, Modulregister, Hauptschalter, Kampfsperre, Schrift, Balken, Rahmen, **Verschieben** |
| `ui/castbar.lua` | **ein** Zauberbalken für Plaketten und Einheitenrahmen |
| `ui/nameplates.lua` | Gegnerplaketten |
| `ui/unitframes.lua` | Spieler, Ziel, Ziel des Ziels, Fokus, Begleiter |
| `ui/questarrow.lua` | Questpfeil |
| `ui/comfort.lua` | Komfortfunktionen |
| `ui/options.lua` | das Einstellungsfenster und das Modul „Allgemein“ |

Neue Bausteine in `core/ui.lua`: `CreateDropdown` (Auswahlliste, eine
Liste für alle Felder) und `CreateColorSwatch` (Farbfeld, öffnet den
Farbwähler des Spiels).

## Speicher

Ausschließlich `WeintCodex_SavedData.ui` – keine neue SavedVariable.

```
ui = {
  enabled   = true|false,          -- Hauptschalter
  modules   = { [modul] = { enabled = , <nur Abweichungen vom Standard> } },
  positions = { [rahmen] = { point, relPoint, x, y } },
}
```

`UIKit.Set` speichert **nur, was vom Standard abweicht**. Ändert sich
eine Voreinstellung, zieht sie bei allen nach, die den Wert nie
angefasst haben. `load_test.lua` prüft beides.

## Geheime Werte (Client 12.x)

Forever läuft nach allem, was bekannt ist, auf dem 12.x-Unterbau. Dort
sind im Kampf Lebenspunkte, Stufe, Zauberzeiten, „unterbrechbar“ und
anderes **secret**: man darf sie an `StatusBar:SetValue`,
`FontString:SetText`/`SetFormattedText` weiterreichen, aber nicht
vergleichen, nicht rechnen, nicht auf Wahrheit prüfen.

Die Regeln im Code:

* **`type(x) == "nil"`** statt `x == nil` – ein Vergleich mit einem
  geheimen Wert ist ein Fehler, `type` nicht.
* **kein `a or b`** auf Werten vom Client – `or` prüft `a` auf Wahrheit.
* **`SetFormattedText`** statt `..` zum Zusammensetzen.
* `UIKit.Plain(x)` liefert `nil` für einen geheimen Wert, `UIKit.Bool(x, fallback)`
  einen Wahrheitswert mit ausdrücklichem Rückfall.
* Zauberbalken: `UnitCastingDuration` + `StatusBar:SetTimerDuration`,
  Farbe über `C_CurveUtil.EvaluateColorValueFromBoolean`, Rahmen über
  `SetAlphaFromBoolean`. Fehlt das, wird mit Millisekunden gerechnet –
  **nur wenn sie nicht geheim sind**. Fehlt beides, steht der Name ohne
  Fortschritt da.

## Was der Client verschweigt, bleibt verschwiegen

Dieselbe Regel wie im ganzen Addon (`docs/invariants/data-integrity.md`):

* Eine Stufe, die der Client nicht nennt → `??`, nie `0`.
* Questpfeil in einer Instanz → „Position unbekannt“, nie „0 m“.
* Quest ohne Ort auf der Karte → „Ort unbekannt“.
* Haltbarkeit ohne Auskunft → keine Warnung (`LowestDurability()` ist
  `nil`, nicht 100 und nicht 0).

## Forever-Wissen aus der Vorlage

EllesmereUI ist gegen den Forever-Beta-Client (1.60.x) gelaufen. Was
dort im Code steht, ist ein **Bericht über** den Client, kein Blick
hinein – dieselbe Einordnung wie `community` in `data/sources.lua`:

* **Kombopunkte gehören dem Ziel** (wie in Classic). `UnitPower` meldet
  beim Zielwechsel noch den alten Stand; gelesen wird
  `GetComboPoints("player", "target")`. Nur Schurke und Druide
  (Katzengestalt) haben eine Klassenressource.
* **Secure-Snippets fehlen** im Beta-Client (`loadstring_untainted`) –
  die Vorlage schaltet deshalb Schlachtzugsrahmen ab. Die Einheitenrahmen
  hier brauchen keine Snippets (nur `SecureUnitButtonTemplate` und
  `RegisterUnitWatch`).
* **SavedVariables speichern im Beta-Client nur manchmal.** Das betrifft
  jedes Addon, auch WeintCodex – eine Einstellung, die nach dem
  Neuladen „weg“ ist, ist dann kein Fehler dieses Addons.
* Die Vorlage erkennt Forever an der Schnittstellennummer **16001**
  („1.60+“) und führt sie in ihrer `.toc` neben 120000. Seit 6.0.0.0
  steht sie auch in `WeintCodex.toc` – neben 120000, für den Fall, dass
  der Bericht nicht stimmt.

## Neuladen ist geschützt

Auf Forever ist `Reload()` für Addons gesperrt: `ReloadUI()` oder
`C_UI.Reload()` aus Lua endet in `ADDON_ACTION_BLOCKED` (im Beta-Client
gemeldet mit 6.0.0.0, behoben in 6.0.0.1). Erlaubt ist nur, was der Spieler selbst auslöst.
Jeder „Neu laden“-Knopf – hier, in den Einstellungen, bei den
Materialien und auf der Anmeldeseite – geht deshalb über
`WeintCodex.AttachReload` (`core/ui.lua`): ein unsichtbarer
`InsecureActionButton` über dem sichtbaren Knopf führt das Makro
`/reload` aus. Im Kampf wird er erst danach scharf und sagt bis dahin im
Chat, dass `/reload` zu tippen ist.

**Es gibt keine Funktion, die „jetzt neu lädt“.** Jeder Aufruf ohne
Klick wäre genau der blockierte Fall. `load_test.lua` sucht in `core/`,
`modules/` und `ui/` nach `ReloadUI(` und `C_UI.Reload` und schlägt an.

## Die Module seit 6.0.0.3 – und ihre Grenzen

Jedes Modul ist so gebaut, wie der 12.x-Unterbau es Addons erlaubt. Wo
das weniger ist als bei der Vorlage, steht es hier und auf der
Einstellungsseite des Moduls.

| Modul | Was es tut | Grenze, und warum |
|---|---|---|
| Auren (`ui/auras.lua`) | **ein** Baustein für Plaketten, Zielrahmen, Gruppenrahmen | 12.1: Addons lesen Auren nicht mehr selbst. Wo es den **Auren-Container** des Spiels gibt (`CreateFrame("AuraContainer", …)`), füllt das Spiel die Symbole – ohne geheime Werte in Lua. Sonst `GetAuraDataByIndex` in `pcall`. Keine Liste einzelner Zauber zum Filtern: das Spiel zeigt Lua die Auren nicht. |
| Freundliche Plaketten | Name in Klassenfarbe, wahlweise mit Balken | In Instanzen sind sie für Addons gesperrt (`IsForbidden`) – dort bleiben die des Spiels. |
| Gruppen-/Schlachtzugsrahmen (`ui/groupframes.lua`) | zwei `SecureGroupHeader`, Klassenfarbe, Leben, Reichweite, Aggro, bannbare Debuffs | Ohne Secure Snippets gebaut (fehlen laut Vorlage im Beta-Client): kein `initialConfigFunction`, alle Knöpfe beim Anmelden per `startingIndex` angelegt und außerhalb des Kampfes eingerichtet. Die Seitenleiste des Spiels (Markierungen, Bereitschaftscheck) verschwindet mit den Schlachtzugsrahmen. **Auf Forever ungeprüft.** |
| Aktionsleisten (`ui/actionbars.lua`) | die Knöpfe des Spiels umgestaltet: flach, Rand, Schrift, rote Schicht außer Reichweite, Greifen weg | **Keine eigenen Leisten**: Umblättern bei Haltung/Gestalt/Fahrzeug braucht Secure Snippets. Lage und Größe: Bearbeitungsmodus des Spiels. Reichweite als eigene Schicht, damit die Färbung des Spiels (keine Kraft, nicht benutzbar) erhalten bleibt. |
| Minikarte (`ui/minimap.lua`) | eckig, Rand, Mausrad-Zoom, Gebiet, Koordinaten, Uhrzeit | Lage: Bearbeitungsmodus. Die Kompass-*Textur* wird versteckt, nie ihr Elternrahmen (Kampfhilfen lesen daraus die Blickrichtung). `GetMinimapShape` meldet `SQUARE` für Addon-Knöpfe. |
| Chat (`ui/chat.lua`) | Schrift, Hintergrund, flache Reiter, Eingabezeile, Randknöpfe weg | **Keine veränderten Nachrichten** (Kanalnamen, Links, Zeitstempel): Nachrichten können im Kampf geheim sein, ein `gsub` darauf ist ein Fehler, und ein Fehler in `AddMessage` verschluckt die Nachricht. |
| Taschen (`ui/bags.lua`) | alle Taschen in einem Raster, Suche, Sortieren, Gold, Gegenstandsstufe, Qualitätsrand | Knöpfe sind `ContainerFrameItemButtonTemplate` (Benutzen/Verkaufen macht das Spiel); **nie im Kampf angelegt** (sonst „tainted“), deshalb 180 auf Vorrat beim Anmelden. Öffnen folgt den Taschen des Spiels (Haken an `Show`/`Hide`, nicht an `OnShow` – die feuern im versteckten Elternrahmen nie). Die Bank bleibt die des Spiels. |
| Schadensanzeige (`ui/damagemeter.lua`) | Schaden, Heilung, erlittener Schaden, Unterbrechungen, Bannungen, Tode; aktuell/gesamt | Addons bekommen ab 12.0 kein Kampflog: die Zahlen kommen aus `C_DamageMeter` (die Messung des Spiels), Blizzards Fenster geht aus (`damageMeterEnabled = 0`). Fehlt die Messung, steht das im Fenster – keine Nullen. |

## Die Frage beim Einloggen (`ui/welcome.lua`)

**Ruht seit 6.0.0.3** (siehe oben, `OPT_IN`). Beschrieben ist, wie sie
arbeitet, wenn `OPT_IN` wieder `true` ist.

Einmal je Konto fragt WeintCodex, ob die Oberfläche verwendet werden
soll – **nach** der Einführung bzw. dem Changelog-Popup, nie darüber
(`Onboarding.OnClosed`, `Onboarding.IsShowing`), und nie im Kampf.

* **Ja** → Hauptschalter an, Angebot „Jetzt neu laden“ / „Später“.
* **Nein** → nichts wird angefasst, und der Hinweis, wo man es später
  einschaltet (Einstellungen → „Oberfläche“, `/wcui`), im Fenster und im
  Chat. Ein „Nein“ ohne diesen Satz wirkte endgültig, obwohl es das nicht
  ist.
* ESC ist **keine** Antwort: die Frage kommt beim nächsten Einloggen
  wieder.

Gemerkt wird `ui.asked`. Wer die Oberfläche vorher schon über `/wcui`
eingeschaltet hat, wird nicht gefragt.

**Nach einem `/reload` wird nie automatisch gefragt, nur beim echten
Einloggen** (`PLAYER_ENTERING_WORLD` mit `isReloadingUi`). Mit 6.0.0.1
gemeldet: „Ja“ → „Jetzt neu laden“ → dieselbe Frage, in einer Schleife.
Der Beta-Client hatte die Antwort nicht gespeichert. Erzwingen kann das
Addon das Speichern nicht – aber wer gerade neu geladen hat, hat die
Frage fast immer eben beantwortet. Beim nächsten echten Einloggen kommt
sie wieder, falls die Antwort verloren ging.

### Hat der Client gespeichert? (`WeintCodex.SaveHealth`)

`core/main.lua` schreibt bei `PLAYER_LOGOUT` (kommt vor dem Schreiben,
auch beim Neuladen) die Uhrzeit nach `saveProbe`. Nach einem Neuladen
muss sie Sekunden alt sein; ist sie älter als fünf Minuten, stammt die
Datei aus einer früheren Sitzung – der Client hat nicht geschrieben. Dann
steht im Chat, dass die Änderungen verloren sind und dass das ein Fehler
der Beta ist. Fehlt der Stempel ganz (erste Sitzung mit dieser Fassung),
heißt das „unbekannt“, nicht „in Ordnung“. Die Einstellungsseite zeigt
den Zustand unter *Diagnose → Speichern*.

Grenze: Schreibt der Client **nie**, entsteht auch nie ein Stempel, und
der Zustand bleibt „unbekannt“. Dann bleibt nur der Hinweis im
Fragefenster, dass eine Einstellung, die nach dem Neuladen fehlt, nicht
gespeichert wurde.

`load_test.lua` prüft zusätzlich per `luac -l`, dass keine Datei unter
`ui/` versehentlich eine globale Variable liest oder schreibt – genau
so war die Sperre gegen die Schleife beim ersten Versuch wirkungslos.

## Die Falle `x and false or nil`

Bis 6.0.0.2 stand in `UIKit.Set`: `store[key] = (not same) and CopyValue(value) or nil`.
Für `value == false` ist das `nil` – ein Schalter, der standardmäßig an
ist, ließ sich **nie** abschalten, in keinem Modul. Gefunden hat es der
Test der Minikarte („eckig“ aus). `load_test.lua` prüft seitdem
ausdrücklich, dass `false` gespeichert wird.

## Prüfen

`load_test.lua`, Abschnitt „Optionale Oberflaeche“: jede
Einstellungsseite wird gebaut, jede Auswahlliste geöffnet, Plaketten und
Einheitenrahmen laufen gegen die Attrappe durch (Plakette anlegen,
Treffer, Zauber, Zielwechsel, freigeben), jede Komfortfunktion bekommt
ihre Ereignisse, und die Geometrie des Questpfeils wird nachgerechnet.

**Ein grüner Lauf heißt „es lädt und rechnet“, nicht „es sieht richtig
aus“.** Wie die Plakette im Spiel wirkt, sagt er nicht.
