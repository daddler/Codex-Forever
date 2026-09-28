# Die WeintCodex-Oberfläche (`ui/`)

> Die Neugestaltung (UI 2.0: Cockpit, Raster, Kachel, Ruhe/Kampf,
> Gestaltungsmodus) ist in `docs/design/ui-2.0.md` geplant. Dieses
> Dokument beschreibt den **gebauten** Stand.

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
| `ui` | Namensplaketten, Einheitenrahmen, Gruppenrahmen, Aktionsleisten, Minikarte, Chat, Taschen, Schadensanzeige, Questliste | **ja** (derzeit immer an) | nach dem Neuladen |
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
Font) und sein Code gehören nicht in dieses Repository. Eigene Grafiken
– Questpfeil, Balkenglanz (`bar`), weicher Schein (`glow`,
`glow_wide`), Zielmarke (`targetmark`), Symbole – entstehen aus
`.github/scripts/make_ui_media.py`, alle weiß bzw. grau und im Spiel
eingefärbt. Die schmale Schrift der Spielwelt ist **IBM Plex Sans
Condensed** (OFL, dieselbe Familie wie der Rest; `WeintCodex.Fonts.hud*`)
– sie übernimmt die Rolle, die Expressway bei der Vorlage hat.

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
| `ui/kit.lua` | Speicher, Modulregister, Hauptschalter, Kampfsperre, Schrift, **Stil 2.0** (`NewBar`, `Glow`, `Kachel`), Rahmen, **Verschieben** |
| `ui/layout.lua` | **wo alles steht**: die Standardpositionen aller beweglichen Rahmen (`UIKit.LAYOUT`, `UIKit.Layout`) |
| `ui/presence.lua` | **Ruhe, Bereit, Kampf**: Deckkraft außerhalb des Kampfes |
| `ui/testmode.lua` | **Testmodus**: Beispieldaten für Ziel, Fokus, Gruppe, Zauberbalken, Schadensanzeige |
| `ui/editmode.lua` | **Gestaltungsmodus**: Leiste, Raster, Einrasten, Pfeiltasten, Doppelklick zu den Einstellungen |
| `ui/castbar.lua` | **ein** Zauberbalken für Plaketten und Einheitenrahmen |
| `ui/nameplates.lua` | Gegnerplaketten |
| `ui/unitframes.lua` | Spieler, Ziel, Ziel des Ziels, Fokus, Begleiter; Porträt als 3D-Modell oder Bild |
| `ui/setup.lua` | **Einrichtung beim ersten Mal**: stellt alles – Layout „WeintCodex“ im Bearbeitungsmodus mit jedem Rahmen des Spiels an festem Platz (`K.GAME_LAYOUT`), Chatfenster, einige Spieleinstellungen, eigene Rahmen –, danach neu laden (`/wcui einrichten`, prüfen: `/wcui einrichten pruefen`) |
| `ui/gamegroup.lua` | **Gruppenrahmen des Spiels im WeintCodex-Stil** (Standard seit 6.6.0.9): nur sie zeigen HoTs, Buffs, Schilde und Debuffs im Kampf |
| `ui/clickcast.lua` | **Klickzauber**: Maustaste + Zusatztaste wirkt einen Zauber auf die Einheit des Rahmens (Reiter der Gruppenrahmen) |
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
`SecureActionButton` (bis 6.4.1.0 `InsecureActionButton` – der darf im
Beta-Client kein Makro mehr ausführen, `ADDON_ACTION_FORBIDDEN`) über dem sichtbaren Knopf führt das Makro
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
| Questfortschritt auf Plaketten | „8/10“ links vom Namen, wenn der Gegner zu einer eigenen Quest gehört | Aus den Tooltipdaten (`C_TooltipInfo.GetUnit`), nur Quests aus dem eigenen Log (`C_QuestLog.IsOnQuest`). Geheim = unbekannt: ohne lesbaren Stand steht „!“, nie eine geratene Zahl. Nicht in Instanzen. |
| Auren-Zustand | `UIAuras.StatusText()`: welcher Weg, wie viele Container, erster Fehlschlag je Schritt; steht auf der Seite „Auren“ und geht einmal in den Chat | In 6.0.0.5 zeigte das Spiel keine Auren, und niemand sah warum (alles in `pcall`). Seit 6.0.0.6 wird der Container **vor** der ersten Gruppe verankert; scheitert `AddAuraGroup`, folgt ein vereinfachter Versuch. |
| Restzeit auf Auren-Symbolen | Sekunden oben links am Symbol | Engine-Weg: `SetDurationText` – das Spiel zählt selbst, auch geheime Werte. Alter Weg: ein Takt je Objekt, nur solange etwas abläuft. |
| Freundliche Plaketten | Name in Klassenfarbe, wahlweise mit Balken | In Instanzen sind sie für Addons gesperrt (`IsForbidden`) – dort bleiben die des Spiels. |
| Gruppen-/Schlachtzugsrahmen (`ui/groupframes.lua`) | zwei `SecureGroupHeader`, Klassenfarbe, Leben, Reichweite, Aggro, bannbare Debuffs | Ohne Secure Snippets gebaut (fehlen laut Vorlage im Beta-Client): kein `initialConfigFunction`, alle Knöpfe beim Anmelden per `startingIndex` angelegt und außerhalb des Kampfes eingerichtet. Die Seitenleiste des Spiels (Markierungen, Bereitschaftscheck) verschwindet mit den Schlachtzugsrahmen. **Auf Forever ungeprüft.** |
| Aktionsleisten (`ui/actionbars.lua`) | die Knöpfe des Spiels umgestaltet: flach, Rand, Schrift, rote Schicht außer Reichweite, Greifen weg; seit 6.0.0.5 Mikromenü klein unten links, Taschenleiste unten rechts | **Keine eigenen Leisten**: Umblättern bei Haltung/Gestalt/Fahrzeug braucht Secure Snippets. Lage und Größe der Leisten: Bearbeitungsmodus des Spiels. Reichweite als eigene Schicht, damit die Färbung des Spiels (keine Kraft, nicht benutzbar) erhalten bleibt. Mikromenü und Taschenleiste sind nicht geschützt und werden nach jedem Anordnen des Bearbeitungsmodus (`ApplySystemAnchor`, `ExitEditMode`) und nie im Kampf gesetzt – ob das den Bearbeitungsmodus auf Forever unberührt lässt, ist **ungeprüft**; „Wie im Spiel“ schaltet es ab. |
| Minikarte (`ui/minimap.lua`) | eckig, Rand, Mausrad-Zoom; Koordinaten oben links, Uhr oben rechts, Gebiet unten auf einem Streifen; Knöpfe des Spiels (Verfolgung, Kalender, Post, Schwierigkeit) in einer Spalte links | Knopfnamen wechseln zwischen den Clients – was fehlt, fällt heraus. Die Spalte wird nach `MinimapCluster:Layout` neu gesetzt. | Lage: Bearbeitungsmodus. Die Kompass-*Textur* wird versteckt, nie ihr Elternrahmen (Kampfhilfen lesen daraus die Blickrichtung). `GetMinimapShape` meldet `SQUARE` für Addon-Knöpfe. |
| Chat (`ui/chat.lua`) | Schrift, Hintergrund über Reiter und Text, flache Reiter (aktiver hell mit Strich), Eingabezeile, Knöpfe des Spiels in einer Spalte links (oder weg) | **Keine veränderten Nachrichten** (Kanalnamen, Links, Zeitstempel): Nachrichten können im Kampf geheim sein, ein `gsub` darauf ist ein Fehler, und ein Fehler in `AddMessage` verschluckt die Nachricht. |
| Taschen (`ui/bags.lua`) | alle Taschen in einem Raster, Suche, Sortieren, Gold, Gegenstandsstufe, Qualitätsrand | Knöpfe sind `ContainerFrameItemButtonTemplate` (Benutzen/Verkaufen macht das Spiel); **nie im Kampf angelegt** (sonst „tainted“), deshalb 180 auf Vorrat beim Anmelden. Öffnen folgt den Taschen des Spiels (Haken an `Show`/`Hide`, nicht an `OnShow` – die feuern im versteckten Elternrahmen nie). Die Bank bleibt die des Spiels. |
| Schadensanzeige (`ui/damagemeter.lua`) | bis zu vier Fenster, je mit eigener Messart (Schaden, Heilung, erlittener Schaden, Unterbrechungen, Bannungen, Tode) und eigenem Zeitraum; Kopfzeile mit Kampfdauer und Symbolknöpfen | Addons bekommen ab 12.0 kein Kampflog: die Zahlen kommen aus `C_DamageMeter` (die Messung des Spiels), Blizzards Fenster geht aus (`damageMeterEnabled = 0`). Fehlt die Messung, steht das im Fenster – keine Nullen. Zahlen über `CreateAbbreviateConfig` (K/M/B, darunter ganze Zahlen): ohne sie gibt `AbbreviateNumbers` Werte unter 1000 ungerundet heraus („16.826086956522“, 6.0.0.4). Fenster flach gespeichert (`w1mode` …), weil `UIKit.Set` Tabellen nur eine Ebene tief vergleicht. |
| Questliste (`ui/questtracker.lua`) | eigene Fläche hinter der Zielverfolgung des Spiels, goldenes Banner weg, Höhe folgt dem Inhalt | Die Liste bleibt Blizzards (taint-empfindlich: Questgegenstände im Kampf); nur ein eigener Rahmen dahinter und durchsichtige Hintergrundtexturen. |
| Questpfeil (`ui/questarrow.lua`) | 3D-Pfeil aus 64 vorgerechneten Ansichten (`media/ui/arrow3d.tga`, erzeugt von `make_ui_media.py`), Farbe grün → gelb → rot nach Abweichung; als Geist zur Leiche (`C_DeathInfo`); nach dem Abgeben die nächstgelegene Quest – seit 6.6.0.1 nur für den Pfeil (`QA.Chosen`), nicht mehr über `C_SuperTrack.SetSuperTrackedQuestID` (das berührte Blizzards Questverfolgung, im Kampf blockierte das Spiel dann `SetPassThroughButtons`); wählt der Spieler selbst, gilt seine Wahl –, wahlweise schon bei erfüllten Zielen | Kein Modell im Spiel, sondern Bilder: ein `PlayerModel` ließe sich nicht zuverlässig drehen und färben. Leiche und nächste Quest nur, wo das Spiel einen Ort nennt – sonst „Ort unbekannt“, nie 0 m. |

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

## UI 2.0, Phase 1 (seit 6.1.0.0)

Das Konzept steht in `docs/design/ui-2.0.md` (mit Entwurf). Gebaut ist
Phase 1 – **im Spiel ungeprüft**.

**Stil.** Jeder Balken entsteht über `UIKit.NewBar` (Glanztextur,
Lichtkante oben, gemerkt für den Wechsel des Balkenstils); `Allgemein →
Balken` hat „Mit Glanz“ (Standard), „Flach“ und „Mit leichtem Verlauf“.
`UIKit.Glow` legt einen weichen Schein um einen Rahmen – schwarz als
Schatten, im Akzent als Leuchten des Ziels, weiß unter der Maus. Er ist
ein Neunteiler aus **einer** Textur (`SetTextureSliceMargins`); fehlt
das im Client, bleibt er aus (`UIKit.canSlice`), statt als gestrecktes
Rechteck zu erscheinen. Der Schein ist innen voll deckend und muss
deshalb **unter** seinem Rahmen liegen (unterste Ebene des Rahmens oder
`opts.host` darunter – bei der Minikarte ein eigener Rahmen unter der
Karte). Schatten hängen am Schalter „Weiche Schatten“ (Allgemein).
`UIKit.Kachel` ist die eine Fläche aus dem Konzept (Graphit 88 %, Rand,
Lichtkante, Schatten); in Phase 1 trägt sie nur das Band des
Testmodus, die übrigen Flächen bekommen Schatten und Glanz.

**Plaketten 2.0.** 150 × 14, weicher Schatten statt harter Kante, Grund
im dunklen Ton der Balkenfarbe (`tintedBg`). Die Maus hellt eine
Plakette auf (additive Fläche + weißer Schein, volle Deckkraft, nach
vorn). Erkannt über `UPDATE_MOUSEOVER_UNIT`; das Verlassen meldet das
Spiel nicht, deshalb fragt ein Takt zehnmal je Sekunde nach, **nur**
solange eine Plakette hervorgehoben ist. Das Ziel: 110 %, Leuchten
(`targetGlow` = Akzent) und zwei Zielmarken (`targetmark`, rechts
gespiegelt); wahlweise weißer Rand, beides oder nichts
(`targetStyle`). Mit Ziel treten alle anderen auf 70 % zurück.

**Layout.** `ui/layout.lua` hält jede Standardposition; Module fragen
`UIKit.Layout(schlüssel)`, ein unbekannter Schlüssel ist ein Fehler
(fällt im Prüflauf auf). Gerechnet im Grundmaß des Spiels (UIParent
768 hoch). Spieler und Ziel (200 × 31) spiegelbildlich 100 Einheiten
neben der Mittelachse; Kombopunkte und eigener Zauberbalken haben
eigene Plätze mittig darunter (`uf_combo`, `uf_playercast`, abschaltbar:
„Kombopunkte mittig“, „Mittig über den Leisten“). Die Gruppe steht
links neben dem Spielerrahmen, die Schadensanzeige unten rechts.

**Ruhe, Bereit, Kampf.** `ui/presence.lua` bestimmt den Zustand
(Kampf; Bereit = Ziel, laufender Zauber oder Leben nicht voll; sonst
Ruhe nach einem Nachlauf von 4 s). Unbekanntes Leben (geheim) zählt als
„nicht voll“. Module melden Rahmen an (`UIPresence.Register`): Spieler
und Begleiter, Aktionsleiste 1, alle weiteren Leisten, Schadensanzeige.
**Nur Deckkraft** – im Kampf auch an geschützten Rahmen erlaubt; eine
Leiste auf 0 % bleibt klickbar, Tastenkürzel wirken. Die Maus holt ein
Element zurück (Haken an `OnEnter`/`OnLeave` der Knöpfe). Testmodus und
Entsperren erzwingen volle Deckkraft (`UIPresence.Force(grund, an)`).
Einstellungen: Modul „Allgemein“, Reiter „Ruhe und Kampf“.

**Testmodus** (`/wcui test`, oder Allgemein → Testmodus). Ziel, Ziel des
Ziels, Fokus und Begleiter mit Beispielwerten (UnitWatch aus, danach
wieder an), laufende Zauberbalken, drei Kombopunkte (nur Schurke und
Druide), fünf ungeschützte Beispielknöpfe am Platz der Gruppe (nur
allein – eine echte Gruppe zeigt sich selbst), fünf Zeilen in der
Schadensanzeige mit „Beispiel“ in der Kopfzeile. Oben mittig steht ein
Band „Testmodus – Beispieldaten“ mit „Beenden“. Beginnt ein Kampf,
endet er. Auren zeigt er **nicht**: die liest das Spiel selbst,
Beispielauren ließen sich nur vortäuschen.

## UI 2.0, Phase 2 (seit 6.2.0.0): Cockpit

**Im Spiel ungeprüft.** Einheitenrahmen wie die Plaketten: Maus hellt
den Lebensbalken auf (`hover`), Grund in der dunklen Balkenfarbe
(`tintedBg`), Stufe über `UIUnitFrames.LevelParts` (Farbe der
Schwierigkeit, `+` für Elite, `??` wenn unbekannt). Das 3D-Porträt
setzt die Kamera bei `OnModelLoaded`; hat das Modell 0,4 s nach
`SetUnit` keine Datei (`GetModelFileID`), steht das Bild da – im
Beta-Test war es beim Ziel ein schwarzes Kästchen.

Eingehende Heilung und Schilde (6.6.0.6, `healPrediction`, `absorbs`,
Reiter Allgemein): wie in den Gruppenrahmen zwei Balken in einer
Klammer (`_predClip`) über dem Lebensbalken, links an der Kante seiner
Füllung, so breit wie er (`Frame:UpdatePrediction`,
`UNIT_HEAL_PREDICTION`/`UNIT_ABSORB_AMOUNT_CHANGED`). Werte gehen
ungeprüft an `SetValue` – auch geheime; keine Antwort heißt kein Balken.

Kombopunkte sind fünf Balken, Segment *i* mit dem Bereich *i-1 … i*; alle
bekommen denselben Stand. Voll ist, was erreicht ist – ohne dass Lua
den (womöglich geheimen) Stand je vergleicht.

Plaketten: Hinrichtungsmarke (`executeMark`, `executeAt`) als fester
Strich. Aktionsleisten: kurze Tastenkürzel (`UIActionBars.ShortHotkey`,
Haken an `UpdateHotkeys`). Schadensanzeige: Höhe nach den gezeigten
Zeilen (`fitRows`).

### Auren: Größe, Weg, Selbstheilung, Auskunft

Bis 6.1.0.0 blieben Debuffs im Beta-Client unsichtbar, ohne Fehler.
Seit 6.2.0.0:

* Der Container ist so groß wie alle Symbole (`Obj:Extent`), nicht
  1 × 1, und beschneidet nicht (`SetClipsChildren(false)`).
* Der Weg ist im laufenden Spiel umschaltbar (`UIAuras.SetMode`,
  Namensplaketten → Auren → Weg): Automatisch, Container, selbst lesen.
  Jedes Objekt baut sich dabei neu (`Obj:Build`) und behält Anker,
  Sichtbarkeit und Einheit.
* **Selbstheilung** in „Automatisch“: 0,6 s nach `SetUnit`/`Refresh`
  zählt `GetAuraDataByIndex`, wie viele Auren das Spiel nennt (nur
  gezählt, kein Feld gelesen). Nennt es welche und der Container zeigt
  keine (sichtbare Rahmen in Symbolgröße unter ihm), liest WeintCodex ab
  da selbst – für alle Objekte, einmal im Chat gemeldet. Zeigt er
  welche, ist der Weg bestätigt.
* `/wcui auren` (mit Ziel): Weg, Zustand, was das Spiel am Ziel nennt,
  und je Objekt angelegte und gezeigte Symbole mit Rahmengröße.
* `/wcui chat`: Chatfenster, eigene Fläche, Reiter, Knöpfe, Eingabe- und
  Infozeile in je einer Zeile (`K.Describe`).
* `/wcui addons` (seit 6.5.0.0): was der Sammelknopf der Minikarte
  gefunden hat, im Addon ausgeblendete Knöpfe, übrige benannte Rahmen an
  der Karte und die Einträge im Addon-Menü des Spiels. Der Sammelknopf
  nimmt LibDBIcon-Knöpfe und eigene Knöpfe mit einem Namen wie
  `<Addon>MinimapButton` (`MM.LooksLikeAddonButton`), nie „jeden kleinen
  Knopf“ – das wären auch Wegpunkte. Ein Addon, das nur im Addon-Menü
  steht, hat keinen Kartenknopf und fehlt deshalb zu Recht.
* `/wcui maus` (seit 6.3.1.2): Maus über ein Ding halten und abschicken –
  jeder Rahmen aus `GetMouseFoci` mit `GetDebugName`, Elternkette und
  Ankern. Für Rahmen, die im Beta-Client anders heißen als angenommen
  (die Tageszeit an der Minikarte blieb drei Fassungen lang unauffindbar).
  Seit 6.3.1.3 zusätzlich `K.UnderCursor`: alles Sichtbare unter dem
  Zeiger, auch Texturen und Rahmen ohne Mausannahme, die kleinsten zuerst.
* **Abklingzeitmanager** (6.4.1.0, `ui/cooldowns.lua`, Reiter der
  Erinnerungen, `/wcui abklingzeiten`): gestaltet die Anzeigen des
  Spiels um, zählt nicht selbst. Im Kampf gibt der Client Abklingzeiten
  und Auren nur dem geschützten Manager heraus; ein eigener bliebe leer
  (wie die eigenen Zielrahmen-Symbole). Maske ab, Schmuck-Atlanten
  weg, eckige Abdeckung, WeintCodex-Schrift, Balkentextur; neue Symbole
  über `hooksecurefunc(viewer, "OnAcquireItemFrame")`. Auswahl der
  Zauber und Lage bleiben beim Spiel (Auswahlfenster, Bearbeitungsmodus):
  dort werden sie gespeichert, und Einstellungen des Bearbeitungsmodus
  aus Addon-Code machen ihn unsicher. Kein eigener Eintrag in der
  Seitenleiste – sie ist voll (Test „Nichts muss scrollen“).
* **Debuffs am Zielrahmen: die Symbole des Spiels** (6.4.0.3,
  `targetAuraSource`). Eigene Symbole bleiben im Kampf leer (siehe
  6.3.0.2). Der Zielrahmen des Spiels bleibt deshalb am Leben, alles an
  ihm auf Alpha 0 und ohne Maus außer seinem Aurenbehälter
  (`TargetFrameContent.TargetFrameContentContextual.Auras`); der hängt
  über unserem Zielrahmen. Eingestellt wird nur über Methoden des
  Behälters in `hooksecurefunc`-Haken hinter `ConfigureAuraContainer`
  und `AnchorAuraContainer` – nie ein Feld am Rahmen des Spiels (dessen
  Code liefe sonst unsicher und scheiterte an geheimen Werten). Stand:
  `/wcui auren`. Im Spiel ungeprüft.
* **Aurenleisten (Restzeit als Leiste, „wie bei ElvUI“) – nicht machbar,
  ausgebaut in 6.6.0.4.** Drei Fassungen lang im Beta-Client gemessen:
  - 6.6.0.1, Container des Spiels (`AuraContainer`, Dauerleiste über
    `SetDurationBar`): Knöpfe angelegt, Leiste gebunden, aber auch
    außerhalb des Kampfes **keine** Leiste gezeigt.
  - 6.6.0.2, selbst lesen (`GetAuraDataByIndex`): außerhalb des Kampfes
    einwandfrei (Name, Restzeit, Leiste). Am **Ziel** im Kampf: „Auras
    cannot be accessed when secret“.
  - 6.6.0.3, nur am Spieler: auch die **eigenen** Auren im Kampf
    gesperrt – „Auras cannot be accessed when secret while tainted by
    'WeintCodex'“.
  Leisten wären also genau dann leer, wenn man sie braucht. Die Symbole
  des Spiels am Zielrahmen funktionieren, weil der Code des Spiels
  untainted liest. Leisten mit Restzeit im Kampf gibt es nur über die
  verfolgten Leisten des Abklingzeitmanagers (eigene Buffs und DoTs, im
  Bearbeitungsmodus platzierbar). `ui/auras.lua` ist wieder auf dem Stand
  von 6.4.0.3.
* **Questpfeil: Höhe** (6.6.0.1, `showHeight`, `worldMarker`). Die Karte
  ist flach; die einzige Höhe, die der Client nennt, steckt in der
  Navigation des Spiels (`C_Navigation`): Luftlinie im Raum
  (`GetDistance`), ein Bildschirmpunkt genau am Ziel (`GetFrame`) und
  `Occluded`. Daraus der Höhenunterschied √(Luftlinie² − Kartenabstand²) –
  nur seine Größe, die Richtung nennt der Client nicht, und erst ab 8 m
  und bis 300 m Kartenabstand –, „verdeckt – Höhle, Gebäude oder Hang?“
  bis 150 m, und eine Zielmarke im Raum (`QA.marker`, eigene Nadel aus
  `media/ui/pin`) am Bildschirmpunkt des Ziels: sie steht auf dem Berg
  oder am Höhleneingang. Nur, wenn der Pfeil dasselbe Ziel hat wie die
  Navigation (Kartenmarkierung oder vom Spiel verfolgte Quest, nicht
  `QA.Chosen`); zeigt das Spiel seine eigene Marke (`SuperTrackedFrame`),
  bleibt unsere weg.
  **Höher oder tiefer** (6.6.0.8, Beta-Test: „sagt nicht, ob nach oben
  oder unten; der Pfeil bewegt sich nur links/rechts“): die Richtung
  steckt weder in der Navigation noch auf der Karte. Einziger Weg: die
  eigene Höhe (`UnitPosition`, dritter Wert). Im normalen Spiel ist sie
  immer 0 – `QA.PlayerZ` nimmt sie deshalb erst, wenn sie sich einmal von
  0 bewegt hat. Dann `QA.TrackHeight`: steigt man um dz und der
  Unterschied fällt um ≈ dz, liegt das Ziel höher, wächst er, tiefer
  (erst ab 3 Einheiten, Verhältnis 0,5–1,5, sonst Rauschen). Mit Richtung
  „Ziel ≈ 25 m höher“ und ein kleiner Pfeil (`QA.updown`) neben dem
  großen, nach oben oder unten; ohne bleibt es bei „Höhenunterschied ≈
  25 m“. Der große Pfeil kippt nicht: seine 64 Ansichten sind nur
  Himmelsrichtungen, und ohne sichere Richtung wäre ein Kippen geraten.
  `/wcui pfeil` nennt, was der Client hergibt. **Gemessen (6.6.1.1,
  Beta):** `UnitPosition` liefert auf Forever Höhe 0.0 – die Richtung
  bleibt also unbekannt, der Pfeil nennt nur die Größe. Der Code bleibt
  und greift von selbst, falls ein späterer Client die Höhe nennt.
* **Name beim Einloggen** (6.6.0.1): ohne Namen („Unbekannt“) zeichnet
  der Rahmen bis zu zehnmal je Sekunde nach; nach `PLAYER_ENTERING_WORLD`
  setzen alle Rahmen ihre Texte nach 1 und 4 s geleert neu
  (`UF.RedrawTexts`) – eine beim ersten Setzen noch nicht geladene
  Schrift zeichnete sonst nichts.
* **Einrichtung beim ersten Mal** (6.6.1.1, `ui/setup.lua`, Beta-Test:
  „Fenster direkt voreingestellt wie bei Ellesmere, ein Reload packt alles
  an seinen Platz“; seit 6.6.1.3: „WeintCodex soll erstmal ALLES komplett
  einstellen“ – der Chat blieb, wo das vorherige UI ihn hatte). `ES.Apply`
  macht vier Dinge:
  1. **Layout „WeintCodex“** über `C_EditMode`, als Kopie der **Vorlage**
     des Spiels (`ES.Base`: erste aus
     `EditModePresetLayoutManager:GetCopyOfPresetLayouts`; nur ohne Vorlage
     das aktive eigene Layout, nie „WeintCodex“ selbst). Darauf setzt
     `ES.Adjust` **jeden** Eintrag aus `K.GAME_LAYOUT` (`ui/layout.lua`) an
     einen festen Platz (`isInDefaultPosition = false`): Aktionsleisten
     1–5, Haltungs-/Besessenheits-/Begleiterleiste, Fahrzeug verlassen,
     Zusatzfähigkeit, Abklingzeitmanager (Wichtig, Hilfreich, Buffs),
     Begegnungsleiste, Minikarte, Buffs, Debuffs, Questliste, Boss- und
     Arenarahmen, Tooltip, Taschenleiste, Mikromenü, Chat (samt Größe
     `K.CHAT_SIZE` über `WidthHundreds`/`WidthTensAndOnes`/…), Gruppe
     (schlachtzugsartig, ohne Rand) und Schlachtzug. Einstellungen nur
     nach Namen aus dem Setting-Enum des Systems und nur rohe Werte
     (Schalter, Richtung, Chatmaße) – Schieberegler speichert das Spiel
     umgerechnet, die bleiben auf der Vorlage. Geschichte: 6.6.1.1
     kopierte „Modern“ ohne feste Plätze (Leisten sprangen nach unten
     links), 6.6.1.2 das aktive Layout (Chat blieb bei EllesmereUI).
     Systeme, die im Layout fehlen, nennt das Fenster.
  2. **Chatfenster** zurück auf Allgemein + Kampflog
     (`FCF_ResetChatWindows`).
  3. **Spieleinstellungen** `ES.CVARS` (Chatstil `im` für die Infozeile,
     Flüstern im Chat, Klassenfarben im Chat, Leisten sperren, keine
     Tutorials) – nur, wenn `GetCVar` sie kennt; unbekannte nennt das
     Fenster. Die UI-Skalierung bleibt unberührt.
  Was der Spieler selbst gebaut hat, bleibt (6.6.1.4, Beta-Test: „die
  DPS- und HPS-Meter sind von oben links nach unten rechts gewandert, der
  Abklingzeitmanager hat Sachen neu bewegt“): 6.6.1.3 setzte auch die
  eigenen Rahmen zurück (`K.ResetAllPositions`) – das ist raus. Die
  Systeme des Abklingzeitmanagers (`personal` in `K.GAME_LAYOUT`) kopiert
  `ES.KeepPersonal` samt Einstellungen aus `ES.PersonalSource`: dem
  aktiven Layout; ist das „WeintCodex“ und stehen dort noch dessen Plätze
  (nie verschoben), aus dem ersten anderen eigenen Layout. Die Prüfung
  misst sie nicht (kein Soll). Die Questliste steht seit 6.6.1.4 bei
  −305 statt −262: darüber hängt im Beta-Client der Knopf „Issue
  Reporter“.
  Dafür rückte das Cockpit (6.6.1.3): unten Mitte Leiste 1 (18), 2 (66),
  3 (110), darüber die Reihe Haltungen links/Begleiter rechts (154);
  Zauberbalken und Kombopunkte zwischen Spieler und Ziel, der
  Begleiterrahmen links neben den Spieler, die Gruppe höher (440), die
  Schadensanzeige neben Leiste 4/5. Alles gerechnet, nicht gesehen.
  6.6.1.4 nach dem Beta-Test: der Zauberbalken war 240 breit und lag auf
  Spieler und Ziel – jetzt `K.LAYOUT_METRICS.castWidth` = 2 × Achse − 12
  (188); die Schadensanzeige steht wieder oben links (12/−36), weitere
  Fenster reihen sich vom Rand weg an (links verankert nach rechts).
  Die Questliste schließt rechts bündig mit der Minikarte ab („zu weit
  eingerückt“): `TRACK_X` = Kartenbereich (−12) − Einzug der Karte (6)
  − Fläche der Liste (8). Leiste 4 und 5 liegen dann unter einer langen
  Questliste, wenn beide an sind.
  Danach **Neu laden** (`K.ReloadButton`). `/wcui einrichten pruefen`
  (`ES.Check`; in 6.6.1.3 brach sie ab – `local fx, fy = f and
  PointXY(…)` schneidet den zweiten Wert ab; der Prüflauf gibt dem Chat
  jetzt eine Lage) misst danach je Rahmen den Ankerpunkt in dessen eigenen
  Einheiten gegen `K.GAME_LAYOUT` (±3), nennt das aktive Layout, die
  Chatgröße und abweichende Einstellungen. Gefragt wird beim ersten
  echten Einloggen (nie nach `/reload`, nie über der Einführung, nie im
  Kampf), solange es kein Layout „WeintCodex“ gibt – das liegt auf dem
  Server und überlebt vergessene SavedVariables. Auch als Knopf unter
  Gruppenrahmen → Allgemein und mit `/wcui einrichten`. Im Spiel
  ungeprüft.
* **Gruppenrahmen des Spiels** (6.6.0.9, `ui/gamegroup.lua`, Einstellung
  `groupframes.source` = `game` | `own`, Standard `game`). Beta-Test:
  „Schilde, Buffs, HoTs werden im Gruppenframe nicht angezeigt“. Die
  eigenen Kacheln hatten nie Buffs/HoTs, und Debuffs laufen über
  `ui/auras.lua` – im Kampf von Forever gesperrt (siehe Aurenleisten).
  Eigene Rahmen können das grundsätzlich nicht; die des Spiels schon.
  Deshalb bleiben `CompactPartyFrame`/`CompactRaidFrameContainer` an, und
  `GG.Style` zeichnet jeden Rahmen neu (Balkentextur, dunkler Grund,
  Blizzards Linien weg, 1-px-Rand, WeintCodex-Schrift, Aurensymbole
  beschnitten) – nur Methoden, keine Felder; neue Rahmen über
  `hooksecurefunc` auf `DefaultCompactUnitFrameSetup`/
  `DefaultCompactMiniFrameSetup`/`CompactUnitFrame_SetUpFrame`, dazu nach
  `GROUP_ROSTER_UPDATE`. Lage und Größe: Bearbeitungsmodus des Spiels.
  In der Gruppe braucht es „Schlachtzugsartige Gruppenrahmen“ – WeintCodex
  schaltet das nicht selbst um (Einstellungen des Bearbeitungsmodus aus
  einem Addon machen ihn unsicher), sondern sagt es einmal im Chat
  (`EditModeManagerFrame:UseRaidStylePartyFrames`). Der Klickzauber legt
  seine Attribute auch auf diese Rahmen (`CC.Frames`). `/wcui gruppe`
  nennt, was gefunden und gestaltet ist (dazu die Zahl der Haken und den
  Namen des ersten Rahmens). **Seit 6.6.1.0** (Beta-Test: „sieht nicht so
  aus wie bei meinem Krieger“ – alles grün): `GG.Color` färbt Spieler in
  Klassenfarbe (`classColor`, sonst `healthColor`), nur über
  `healthBar:SetStatusBarColor` – die Zwischenwerte des Spiels
  (`healthBar.r/g/b`) bleiben unberührt, Tote und Getrennte behält das
  Spiel grau. Haken auf `CompactUnitFrame_UpdateHealthColor` und
  `CompactUnitFrame_UpdateAll`. Heißen die Rahmen anders, sucht
  `GG.Frames` in `CompactPartyFrame`/`CompactRaidFrameContainer` nach
  Kindern mit `healthBar`. Außerdem (gemessen: 10 Rahmen gefunden und
  gestaltet, aber „sieht aus wie Blizzard“) wie die Kacheln: Name oben
  mittig (16 px Einzug links/rechts wegen des Rollensymbols), Zustand in
  der Mitte, Grund `bgColor`, Rand `borderColor`, Schatten, Trenner
  `horizDivider` weg; `GG.StyleContainers` blendet Überschrift
  (`title`) und Rahmen (`borderFrame`) der Behälter aus. Der Prüflauf stellt vor dem
  Einloggen auf `own`, damit die Prüfungen der eigenen Kacheln bleiben.
  Im Spiel ungeprüft.
* **Klickzauber** (6.6.0.7, `ui/clickcast.lua`, Beta-Test „wie VuhDo,
  Clique, Healbot – einfach“): eine Belegung ist Maustaste (1–5) +
  Zusatztaste (ohne/Umschalt/Strg/Alt) → Zauber, Ziel wählen oder Menü.
  **Nichts wird eingetippt** (Beta-Test: „einfach die Zauber auswählen“):
  die **Zaubertafel** (`CC.BuildPicker`) zeigt „Ziel wählen“, „Menü“ und
  die Symbole aus dem Zauberbuch als Raster; ein Klick legt sie auf die
  oben gewählte Taste, die aktuelle Belegung ist im Akzent umrandet.
  `CC.Spellbook` liest `C_SpellBook` (Rückfall: `GetSpellTabInfo`), je
  Name einmal (der Name wirkt den höchsten Rang), ohne passive Zauber,
  Gilden-, versteckte und Nebenspezialisierungs-Reiter; „Nur hilfreiche
  Zauber“ (`clickHelpfulOnly`) fragt `C_Spell.IsSpellHelpful` – ohne
  Antwort bleibt der Zauber drin. Feste Höhe, sechs Reihen; was nicht
  passt, wird gezählt.
  Umgesetzt **nur** über Klick-Attribute der geschützten Knöpfe
  (`shift-type1` = `spell`, `shift-spell1` = Name); der Client zaubert
  beim Klick, Lua ist nicht beteiligt. Gilt für jeden Knopf aus
  `UIGroupFrames.buttons` und – abschaltbar (`clickUnitFrames`) –
  `UIUnitFrames.frames`. `CC.ApplyTo` merkt sich, was es gesetzt hat,
  und löscht genau das beim nächsten Mal; dann greifen wieder `*type1`
  (Ziel) und `*type2` (Menü) der Rahmen. Attribute nur außerhalb des
  Kampfes (`K.AfterCombat`). Gespeichert **je Klasse** unter dem eigenen
  Speicher `clickcast.bindings` – nicht im Modul der Gruppenrahmen, damit
  „Standard“ dort nicht alle Zauber löscht; die Schalter
  (`clickUnitFrames`, `clickTooltip`) und der Reiter „Klickzauber“ hängen
  an den Gruppenrahmen, weil die Seitenleiste des Einstellungsfensters
  keinen Eintrag mehr fasst. Der Tooltip eines Rahmens nennt die
  Belegung (`HookScript("OnEnter")`). **Nicht möglich:** Tastatur-Tasten
  beim Drüberfahren (brauchen Snippets, die dem Forever-Client fehlen,
  oder Tastenbelegungen, die im Kampf gesperrt sind) und Kombinationen
  mehrerer Zusatztasten. Keine eingebaute Zauberliste – die Tafel zeigt, was das Zauberbuch nennt. Im Spiel ungeprüft.
* **Erinnerungen** (6.4.0.0, `ui/reminders.lua`, eigenes Modul): ein
  Regelwerk aus kleinen Tabellen – `buff` (Buff fehlt), `weapon` (Waffe
  ohne/mit ablaufender Verzauberung, `GetWeaponEnchantInfo`), `pet`
  (Begleiter war da und ist weg), `proc` (Symbol, solange ein eigener
  Buff läuft), `cooldown` (Symbol mit Abklingzeit). Zauber nennt der
  Spieler (Name oder ID, `R.Resolve`); Vorschläge je Klasse nur ohne
  Zauber-ID (Waffe, Begleiter). Erinnerungen ruhen im Kampf (einstellbar):
  dort nennt der Client Auren oft geheim, und eine geheime Aura ist
  „weiß nicht“, nie „fehlt“. Procs und Abklingzeiten bekommen Werte
  durchgereicht (Dauerobjekt, sonst `SetCooldown` mit dem Wert, wie er
  kommt); entschieden wird im Kampf nichts. Der Regel-Editor nutzt zwei
  neue Zellen im Einstellungs-Baukasten: `input` (Eingabefeld) und
  `custom` (frei gebaut, feste Höhe). Die Seitenleiste wurde dafür von
  40 auf 36 px je Eintrag verdichtet.
  **Regeln gelten je Klasse** (6.6.0.5, Beta-Test: Schlachtruf-Erinnerung
  auf dem Jäger – die Einstellungen sind accountweit). Neue Regeln tragen
  `class` (die Klasse, auf der sie angelegt wurden) oder `R.ALL` („Alle
  Klassen“, Auswahl „Gilt für“ im Editor); Vorschläge tragen ihre Klasse.
  `R.Applies`/`R.Here` filtern Erinnerungen, Procs und Abklingzeiten.
  Regeln von vorher (ohne `class`) entscheidet der Client: ein Zauber
  gilt, wenn der Charakter ihn kennt (`WeintCodex.Trainer.Known`); einer,
  den er nicht kennt oder nicht auflösen kann, gilt nicht – außer der
  Client kann gar nicht fragen („weiß nicht“ ≠ „gilt nicht“). Waffe gilt
  nur, wo sie Vorschlag der Klasse ist, Begleiter überall. Die Liste
  zeigt alle Regeln, fremde blass mit „(hier aus)“.
  **Munition und Vorrat** (6.6.0.6, Beta-Test „Erinnerung bei zu wenig
  Munition“): `ammo` liest den Munitionsplatz (Platz 0,
  `GetInventoryItemID`/`GetInventoryItemCount`); ist er leer, nachdem
  Munition drin war, zählt dieselbe Sorte in den Taschen („Munition
  leer“). Nie gesehen oder keine Antwort: keine Erinnerung – „weiß
  nicht“ ist nicht „0 übrig“. `item` nennt einen Gegenstand (Name oder
  ID, `R.ResolveItem`; Namen löst der Client nur für schon gesehene
  Gegenstände auf) und zählt mit `C_Item.GetItemCount`. Mindestmenge
  `min`, ohne Angabe 200 (Munition) bzw. 1 (Vorrat). Vorschlag für
  Jäger: Begleiter und Munition. Ob der Forever-Client den
  Munitionsplatz so führt, ist im Spiel ungeprüft.
* **Fenster des Spiels** (6.3.1.6, `ui/windows.lua`): Charakterfenster
  und Teilfenster, erste Stufe nur die Hülle (Schmuck der Vorlage weg,
  Kachel darunter). Inhalte werden nie angefasst. Was innen noch nach
  Holz aussieht, nennt `/wcui fenster`. Seit 6.3.1.7 zweite Stufe:
  `W.HIDE_ATLAS` blendet die dort gemessenen Atlanten aus (Muster, nie
  Inhalte; `RaceBG` bleibt), die Plätze bekommen einen 1-px-Rand.
* **Gespräche** (6.6.1.4, Beta-Test: „die normale Interaktion von
  Questgebern, Gastwirten etc. muss angeglichen werden“): `GossipFrame`,
  `QuestFrame`, `ItemTextFrame` (`W.DIALOGS`) bekommen die Fensterhülle,
  das Pergament geht über `W.HideLarge`, dunkle Schrift wird hell – und
  zusätzlich dunkle **Farbcodes im Text** (`W.LightCodes`: nur Codes mit
  jedem Kanal < 0x50, damit Rot und Grün bleiben): die Gesprächsoptionen
  setzen Questnamen als `|cff000000…|r` in den Text. Nachgezogen beim
  Zeigen jedes Quest-Teilfensters (`W.SHOW_HOOKS`), nach
  `GossipFrame:Update`/`Refresh` und im Takt des offenen Fensters.
  `MerchantFrame` nur Hülle und Knöpfe. Im Spiel ungeprüft.
* **Zauberbuch** (6.4.1.2): dieselbe Fensterhülle wie das
  Charakterfenster (`PlayerSpellsFrame`/`SpellBookFrame`), Pergament-
  Atlanten weg, Zaubersymbole eckig (erkannt an `Button.Icon`/`Border`/
  `IconMask`), dunkle Schrift hell (`W.IsDark`, Haken auf
  `SetTextColor`). Der Forever-Client sieht anders aus als der Quelltext
  des Spiels – was bleibt, nennt `/wcui fenster`. Seit 6.4.1.3 zusätzlich
  große Bilder nach Fläche (≥ 15 % des Fensters, `W.HideLarge`) in
  Fenstern mit „Spell“/„Talent“ im Namen, gefunden auch über
  `ShowUIPanel` (`W.Adopt`); eigene Flächen stehen in `W.own`.
  6.4.1.4 („nur schwarz ist langweilig“): `windowArt` – Talent-
  Landschaften gedämpft statt weg, Schein in der Klassenfarbe oben in
  jedem gestalteten Fenster; Goldschmuck nach den gemessenen Atlanten
  weg, Zustandsrahmen der Talente bleiben.
  6.4.1.5, dritte Stufe: Bedienelemente – Reiter (`TabSystem`) und
  `UIPanelButtonTemplate`-Knöpfe als Kachel, `RedButton-*`/
  `common-dropdown-a-button` entsättigt, Porträt-Rahmen ganz aus, Werte
  im Charakterfenster (`Label` vor `Value`) ohne Überlappung.
  6.5.0.0: Bildreiter nur ohne sichtbare Beschriftung und mit einem
  Bild, das sichtbar ist und etwas zeigt (`W.HasLabel`,
  `W.ShowsPicture`). Die Textreiter „Primär“/„Sekundär“ im Talentfenster
  haben dieselbe Vorlage mit leerem, verstecktem `.Icon` – als Bildreiter
  genommen, trugen sie einen Rand mitten auf der Schrift.
* **Tageszeit-Ecke** (6.3.1.6): `dayCorner` der Minikarte.
* **LibDBIcon friert Schichten ein** (6.3.1.6): vor `SetFrameStrata`
  erst `SetFixedFrameStrata(false)`, sonst wirkt es nicht.
* **Erfahrungsbalken** (6.3.1.5, `ui/xpbar.lua`): Reiter „Erfahrung“ der
  Aktionsleisten, keine eigene Zeile in der Seitenleiste. Erfahrung mit
  erholter Verlängerung; auf Höchststufe der beobachtete Ruf, ohne ihn
  kein Balken (kein gemessenes Nichts). Tempo je Stunde nur aus in dieser
  Sitzung gemessener Erfahrung, als Schätzung benannt. Die Leiste des
  Spiels bleibt, wo sie ist, nur unsichtbar und ohne Maus.
  Seit 6.6.0.1 (`xpQuests`): ein grünes Stück (`GameColors.xpQuest`) vom
  Stand bis dorthin, wo man nach Abgabe aller abgabebereiten Quests
  stünde (höchstens bis zum Ende der Stufe); der Tooltip nennt die Summe,
  den Stand danach oder „Stufe N+1 · +Rest“ und die Summe aller Quests im
  Log. Werte je Quest von `GetQuestLogRewardXP(questID)`, abgabebereit
  über `C_QuestLog.ReadyForTurnIn`/`IsComplete`. Fehlt die Funktion, gibt
  es kein Stück und keine Zeile – nie eine 0.
* **Tageszeit = `MinimapCluster.DielFrame`** (6.3.1.4, gemessen mit
  `/wcui maus`): kein Knopf, nimmt keine Maus an.
* **Reiterleiste in `MEDIUM`** (6.3.1.4, Verdacht): `GeneralDockManager`
  eine Schicht über dem Chatfenster.
* **Chatfläche in `BACKGROUND`** (6.3.1.3): als Kind des Chatrahmens in
  `LOW` hob das Spiel sie auf dessen Stufe, über die Reiter. Eine Schicht
  tiefer liegt sie unabhängig von jeder Stufe darunter.

## 6.3.0.0: Antworten auf den vierten Beta-Test

**Im Spiel ungeprüft.**

* **Weißer Zielrahmen.** UnitWatch zeigt den Rahmen erst *nach*
  `PLAYER_TARGET_CHANGED`; `RefreshUnit` zeichnete nur sichtbare Rahmen.
  Jetzt: zeichnen, sobald die Einheit existiert, und bei `OnShow`.
* **Debuffs auf Plaketten: die Symbole des Spiels.** `auraSource =
  "game"` lässt den Aurenrahmen der Plakette des Spiels
  (`UnitFrame.AurasFrame`/`BuffFrame`) **an seinem Platz**: der
  Blizzard-UnitFrame bleibt sichtbar, alle seine anderen Kinder und
  Regionen gehen auf Alpha 0 (ein `hooksecurefunc`-Haken auf `SetAlpha`
  hält sie dort); am UnitFrame bleibt nur `UNIT_AURA` angemeldet.
  **Nie Anker lesen:** 6.3.0.0 hängte den Rahmen an unsere Plakette und
  merkte sich dafür `GetPoint` – im Beta-Client ein Fehler („Can't
  measure restricted regions“), und umgehängt zeichnete er einen weißen
  Balken über den Namen (6.3.0.1). Die eigenen
  Symbole (`own`) bleiben wählbar, bis klar ist, warum sie im Beta-Client
  nicht erschienen. Einmal je Sitzung (`UIAuras.AUTO_REPORT`) schreibt
  WeintCodex die Auren-Prüfung in den Chat.
* **Chat** als eine Kachel: Reiterzeile mit Linie, Reiter bleiben
  sichtbar (`CHAT_FRAME_TAB_*_NOMOUSE_ALPHA`), Knöpfe klein in der
  Reiterzeile, Eingabe bündig.
* **Schadensanzeige** wie Details, soweit die Messung des Spiels es
  hergibt: Klassensymbol, Anteil (nur mit offenen Zahlen), eigene Zeile
  angeheftet und markiert, Tooltip mit Zaubern, frühere Kämpfe.
* **Gestaltungsmodus** (`ui/editmode.lua`) statt „Rahmen entsperren“:
  siehe `docs/design/ui-2.0.md`, Phase 3.
* **Aktionsleisten**: leere Plätze aus (beim Ziehen sichtbar), flache
  Zustände, Schatten am Symbol, Abklingzahl in eigener Schrift.
  6.6.1.4: das Blinken bei automatischem Angriff/Schießen (`Flash`, ein
  roter Rahmen für den eingerückten Knopf des Spiels, saß schief) ist
  eine flache Fläche im Akzent über dem Symbol (0,3); ein Haken auf
  `SetAtlas`/`SetTexture` hält es so. Rot bleibt der Reichweite.

**6.3.0.1–6.3.0.3 (Beta-Test):** Plaketten-Auren an ihrem Platz statt
umgehängt (kein `GetPoint` auf eingeschränkte Rahmen); Aktionsleisten mit
einem Rahmen (`NormalTexture` per Haken unsichtbar), Fläche hinter jeder
Leiste (`barBackdrop`), Blätterpfeile weg. **Gemessen im Beta-Client:**
`C_UnitAuras.GetAuraDataByIndex` ist im Kampf für Addon-Code gesperrt –
ein eigenes Lesen der Auren (der „alte Weg“) kann im Kampf nichts; die
Knöpfe des AuraContainers sind verboten oder haben geheime Breiten.

**6.3.0.4–6.3.0.6: Leisten wie EllesmereUI, soweit es geht.** WeintCodex
ordnet die Knöpfe des Spiels je Leiste (Größe, Abstand, je Reihe, Anzahl,
Fläche, Maus darüber) – nur außerhalb des Kampfes, Knöpfe an ihrer
eigenen Leiste verankert; `layout = "game"` schaltet das ab. **Leisten
verschiebt WeintCodex nicht:** das Spiel stapelt die unteren Leisten in
Standardlage auch im Kampf selbst (`UpdateBottomActionBarPositions`), und
nach einem fremden Verschieben wurde genau dieser Aufruf blockiert
(`ADDON_ACTION_BLOCKED`, Beta-Test 6.3.0.5). Verschieben: Bearbeitungsmodus
des Spiels.

**6.3.0.7:** Schadensanzeige mit Aufschlüsselung per Klick (Kennzahlen,
Zauber mit Balken, Messart-Reiter, Blättern; nur was `C_DamageMeter`
offen herausgibt – Ziele und Treffer nennt es nicht). Chat: Reiter per
`SetAlpha`-Haken sichtbar, Infozeile darunter (ElvUI-Datenleiste,
Eingabezeile legt sich darüber). Taschenleiste im Stil der Aktionsknöpfe.

**6.3.0.9:** Chat-Kachel auf eigenem Rahmen unter den Reitern (sie lag
darüber), Bildlaufleiste aus. Tooltip (`ui/tooltip.lua`, Einstellungen
beim Modul „general“): Kachel, Klassen-/Qualitätsfarbe, flacher
Lebensbalken, kein Text gelesen. Minikarte oben im Bereich, fremde
Koordinaten ausgeblendet.

**Was noch fehlt (Phase 3 ff.):** Kachel auf allen Flächen (Chat,
Minikarte, Taschen), Schadensanzeige in Ruhe auf die Kopfzeile
zusammenklappen (jetzt: nur leiser), Chat-Hintergrund in Ruhe,
Gestaltungsmodus mit Einstellkarte, Infoleiste, Levelhilfe.

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

Der erste Test im Beta-Client (6.0.0.3) brach drei Module ab, obwohl
der Lauf grün war: Text vor Schrift (Schadensanzeige), Gruppenkopf ohne
`point` vor `Show()` (Gruppenrahmen), Rand an einer Textur (Chat). Die
Attrappe lehnt alle drei seit 6.0.0.4 ab – siehe
`.github/tests/README.md`. Für neuen Code in `ui/` heißt das: **Schrift
direkt nach `CreateFontString`**, Attribute eines Kopfrahmens vor dem
ersten `Show()`, `UIKit.Border` nur an Rahmen.

Im zweiten Test (6.0.0.4) kam „Font not set“ siebenfach beim Angreifen:
eine frische Plakette verband ihren Zauberbalken mit dem Gegner, bevor
dessen Schrift stand. Seit 6.0.0.5 entsteht **jede** Textzeile in `ui/`
über `UIKit.NewText`, das die Schrift sofort setzt; `load_test.lua`
verbietet `CreateFontString` außerhalb von `ui/kit.lua`. `UIKit.SetFont`
lässt eine Zeile nie ohne Schrift zurück (meldet der Client `false`,
folgt die Schrift des Spiels).

Die Taschen zeigten im selben Test leere Plätze. Behoben ist das nach
dem Vorbild von EllesmereUI (Symbolmaske ab, Symbol auf den ganzen
Knopf, Knopf und Symbol ausdrücklich zeigen), **im Spiel geprüft ist
es nicht**. Die Zeile „X von Y Plätzen belegt“ unten im Fenster trennt
beim nächsten Test die beiden möglichen Ursachen: steht dort eine Zahl
über null und die Plätze sind leer, liefert der Client die Gegenstände
und nur das Zeichnen scheitert.
