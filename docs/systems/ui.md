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
`glow_wide`), Zielmarke (`targetmark`), Maske ums Charaktermodell
(`softmask`), Symbole – entstehen aus
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
| Questpfeil (`ui/questarrow.lua`) | 3D-Pfeil aus 64 vorgerechneten Ansichten (`media/ui/arrow3d.tga`, erzeugt von `make_ui_media.py`), Farbe grün → gelb → rot nach Abweichung; plant seit 6.6.2.7 selbst (nächstes lohnendes Ziel aus dem Questlog, siehe *Questpfeil: Planen*); als Geist zur Leiche (`C_DeathInfo`); nach dem Abgeben die nächstgelegene Quest – seit 6.6.0.1 nur für den Pfeil (`QA.Chosen`), nicht mehr über `C_SuperTrack.SetSuperTrackedQuestID` (das berührte Blizzards Questverfolgung, im Kampf blockierte das Spiel dann `SetPassThroughButtons`); wählt der Spieler selbst, gilt seine Wahl –, wahlweise schon bei erfüllten Zielen | Kein Modell im Spiel, sondern Bilder: ein `PlayerModel` ließe sich nicht zuverlässig drehen und färben. Leiche und nächste Quest nur, wo das Spiel einen Ort nennt – sonst „Ort unbekannt“, nie 0 m. |

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
* **Questpfeil: Planen** (6.6.2.7, `plan = "smart"`, Standard). Beta-Test:
  „nicht intelligent, schickt mich immer durch die Weltgeschichte“. Bis
  dahin folgte der Pfeil der Quest, die das **Spiel** verfolgt – und das
  wählt sie selbst (beim Annehmen, nach dem Abgeben), ohne auf die
  Entfernung zu schauen. Jetzt plant `QA.Plan`: jede Quest im Questlog ist
  ein Ziel (offene am Zielgebiet, erfüllte an der Abgabe; für den
  Vergleich der Ort der Quest selbst, nicht der Wegpunkt am
  Gebietsausgang). Kosten = Luftlinie × `QA.Weight` (4 für 5+ Stufen über
  dir, 1,5 für 3–4, × 3 für Gruppenquests). Weil Abgaben und Ziele gleich
  zählen, sammelt das von selbst. Gegen Hin und Her löst ein neues Ziel
  das alte nur ab, wenn es unter 70 % seiner Kosten **und** 40 m
  günstiger liegt (`QA.KEEP_SHARE`, `QA.KEEP_MIN`). Neu geplant wird nach
  Questereignissen (gesammelt, eine Abfrage je Karte) und unterwegs alle
  5 s (`QA.PLAN_EVERY`). **Eigene Wahl** (`QA.manual`): Das Spiel meldet
  sie genauso wie seine eigene (`SUPER_TRACKING_CHANGED`); unterschieden
  wird an der Zeit – bis 2 s nach Annehmen, Abgeben, Abbrechen oder Laden
  war es das Spiel (`QA.AUTO_WINDOW`), sonst der Spieler. Sie gilt bis zur
  Abgabe; `/wcui pfeil planen` gibt sie ab, `/wcui pfeil weiter` lässt das
  jetzige Ziel 10 Minuten aus, `/wcui pfeil` nennt die fünf günstigsten
  Ziele mit Entfernung und Gewicht. Grenzen: Luftlinie (Wege um Berge und
  Wasser kennt ein Addon nicht); die Höhe aus der Navigation gibt es nur,
  wenn das geplante Ziel zufällig die Quest ist, die das Spiel verfolgt.
  `plan = "tracked"` stellt das alte Verhalten her.
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
  6.6.1.5, Abklingzeitmanager „wie eine WeakAura unter dem Charakter,
  aber kleiner, nichts doppelt, keine Buffs wie Ausdauer – nur die
  Fähigkeiten oder deren Laufzeiten“: „Wichtig“ und „Hilfreich“ bekommen
  `display = { IconSize = 80 }` – Prozent, wie der Bearbeitungsmodus sie
  zeigt; `ES.RawValue` rechnet über dessen eigene Reglerbeschreibung
  (`EditModeSettingDisplayInfoManager`: `ConvertValue`, sonst (Wert −
  Minimum) / Schritt, nur im Bereich des Reglers, sonst bleibt die
  Vorlage und das Fenster sagt es). Die Buff-Anzeigen des Spiels
  („Buffs“, „Buffleisten“) stehen auf `VisibleSetting` =
  `CooldownViewerVisibleSetting.Hidden` (`enum` in `K.GAME_LAYOUT`) –
  sie zeigten die Laufzeiten, die die Symbole von „Wichtig“ schon
  tragen, ein zweites Mal. `ES.KeepPersonal` übernimmt seitdem nur noch
  den **Platz** (`anchorInfo`), nicht Größe und Sichtbarkeit.
  6.6.1.6 („ich sehe an meinem Spielerfenster nicht, ob ich gebufft bin
  oder ein Schild habe“): eigene Buff-Symbole am Spieler kann WeintCodex
  nicht füllen (im Kampf keine Auren für Addons, siehe *Aurenleisten*).
  Die Buff-Anzeige des Spiels (`BuffFrame`) kann es – 6.6.1.6 stellte
  sie über den Spielerrahmen; Beta-Test: „sieht scheiße aus, sämtliche
  Buffs von anderen – unnötig“. Seit 6.6.1.7 steht sie wieder oben
  rechts, und über dem Spieler stehen die **Buff-Symbole des
  Abklingzeitmanagers** (`bufficon`: sichtbar, `IconSize` 60 %,
  `IconDirection` Left, rechts bündig mit dem Spieler, nicht `personal`
  – `ES.KeepPersonal` übernimmt nur Systeme, die `personal` tragen).
  Welche Buffs dort erscheinen, wählt der Spieler im Abklingzeitmanager
  des Spiels; das Spiel füllt sie auch im Kampf. Die Buffleisten bleiben
  aus. Der Fokus weicht nach links über den Begleiter. Schild am Spieler- und
  Zielrahmen: `_absorb` liegt seit 6.6.1.6 **über** dem Leben, vom
  rechten Rand her (`SetReverseFill`, Farbe `GameColors.absorbOver`,
  blau – der Lebensbalken eines Priesters ist weiß). Hinter der Füllung
  war er bei vollem Leben ganz abgeschnitten.
* **Treffer und Heilung als Zahl** (6.6.1.7, `combatFeedback`, Beta-Test:
  „in kleinen roten Zahlen mit einem Minus, Heilung grün mit einem
  Plus“): Spieler- und Zielrahmen hören auf `UNIT_COMBAT`;
  `Frame:CombatFeedback` zeigt nur `WOUND` (rot, `-`) und `HEAL` (grün,
  `+`), kritisch zwei Punkt größer, über dem Porträt (ohne Porträt mitten
  im Lebensbalken), 1 s stehen, 0,6 s ausblenden. Ist die Art geheim,
  keine Zahl (Lua kann sie nicht unterscheiden); die Menge darf geheim
  sein – gekürzt über `UIDamageMeter.Format`, gesetzt mit
  `SetFormattedText`. Ob Forever `UNIT_COMBAT` an Addons gibt, ist
  ungeprüft (die Gruppenkacheln blitzen damit seit 6.2).
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
  Name einmal, die Ränge darunter (`ranks`, aus `subName`, Rückfall
  `C_Spell.GetSpellSubtext`; nur Untertitel mit Zahl am Ende), ohne passive Zauber,
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
  **Ränge** (6.6.2.0, seit 6.6.2.1 als Liste am Symbol; Beta-Test:
  „die einzelnen Ränge auswählen und nicht immer den höchsten“, dann
  „ein Dropdown mit den Rängen, wenn ich den Zauber wähle“): hat ein
  Zauber mehrere Ränge, öffnet der Klick in der Tafel
  (`CC.PickSpell`) die Liste von `WeintCodex.OpenDropMenu` am Symbol –
  „Höchster Rang – steigt mit“ legt ihn **ohne** Rang (der Client wirkt
  den höchsten, ein neu gelernter greift von selbst), jeder andere
  Eintrag genau diesen Rang. Ein Zauber mit einem Rang wird sofort
  gelegt. Gespeichert wird der Text des Zauberbuchs
  (`rank = "Rang 3"`), das Attribut heißt dann `Erneuerung(Rang 3)`
  (`CC.SpellAttr`) – die Makro-Schreibweise. Ob der Forever-Client
  herausgibt und `Name(Rang N)` im Attribut annimmt: ungeprüft.
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
* **Speicher** (6.6.1.8, Beta-Test: „zwischen 10 und 30–40 MB, dann ein
  Reset, ab 8 MB von vorn“). Das ist kein Leck, sondern Wegwerf-Speicher,
  den die Bereinigung des Spiels einsammelt; die 8 MB Sockel sind Code
  und Daten (gut 2 MB Quelltext). Was geändert wurde:
  **Erinnerungen** sammeln Ereignisse (`R.Schedule`, ausgewertet höchstens
  alle 0,1 s – `SPELL_UPDATE_COOLDOWN` und `UNIT_AURA` kamen im Kampf
  mehrfach je Zauber) und merken sich aufgelöste Zauber (`R.Resolve`,
  geleert bei `SPELLS_CHANGED`, beim Laden und bei Einstellungen);
  **Schadensanzeige** zeichnet auf ihre Mess-Ereignisse höchstens alle
  0,25 s neu (`DM.RefreshSoon`); **Aktionsleisten** fassen
  `ACTIONBAR_SLOT_CHANGED` zusammen (0,2 s). Messen: `K.Measured(name,
  fn)` legt sich um Takte und Ereignisse der oft laufenden Teile und
  zählt nur während `/wcui speicher` (30 s): Aufrufe, neu belegter
  Speicher (`collectgarbage("count")` davor/danach, nach unten ungenau,
  wenn die Bereinigung mittendrin läuft) und Zeit; der Bericht nennt das
  Wachstum des Addons und die acht größten Erzeuger je Sekunde.
  Erste Messung im Beta-Test (6.6.1.8, im Kampf): 402 KB/s gemessen,
  davon **Aktionsleisten 354 KB/s** bei 89 Aufrufen/s – das Einblenden
  „nur bei Maus darüber“ baute jedes Bild eine frische Liste aus ~14
  Tabellen (`Faded`). Seit 6.6.1.9 gemerkt (neu nur in
  `UpdateMouseover`, die Flächen werden beim Prüfen nachgeschlagen);
  `load_test.lua` misst mit dem echten Speicherzähler, dass 300 Bilder
  unter 30 KB bleiben (vorher 141 KB im Prüflauf). Zweiter: **Questpfeil**
  28 KB/s – seitdem fünfmal je Sekunde ein ganzer Durchlauf, dazwischen
  dreht `QA.Turn` nur den Pfeil aus den gemerkten Punkten (`QA._aim`).
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
  **Aufschlüsselung seit 6.6.2.1** (Beta-Test: „frei verschieben, mehr
  Informationen, Vergleich, Graphen, Auren – auch Bufffood,
  Fläschchen“):
  * *Verschiebbar*: Ziehen verschiebt das Fenster, die Stelle bleibt
    (`bdX`/`bdY`); Rechtsklick setzt es wieder neben die Anzeige
    (`DM.PlaceBreakdown`).
  * *Drei Ansichten* unter den Messarten: **Zauber**, **Verlauf**,
    **Auren**.
  * *Vergleich* (`DM.SetCompare`, Liste `DM.CompareItems`: offene Namen
    derselben Liste): Kennzahlen mit „vs …“ und Unterschied in Prozent
    (`DM.Diff`, nur offene Zahlen), Zauber über die Zauber-ID
    zugeordnet mit schmalem zweitem Balken in der Klassenfarbe des
    anderen, gemeinsamer Maßstab nur mit offenen Zahlen – sonst je
    Spieler für sich skaliert, und das steht darunter.
  * *Verlauf*: `C_DamageMeter` nennt nur Summen. WeintCodex liest im
    Kampf einmal je Sekunde die Summen von Schaden und Heilung
    (`DM.Sample`, nur der letzte Kampf, höchstens 30 Minuten) und zeigt
    den Zuwachs je Abschnitt als 48 Säulen (`DM.Rates`, zwischen Proben
    linear), den Verglichenen als Linie. **Geheime Zahlen lassen sich
    nicht aufzeichnen** (Lua darf mit ihnen nicht rechnen) – gibt der
    Client sie im Kampf verdeckt heraus, steht genau das da. Ob er es
    auf Forever tut, ist ungeprüft.
  * *Auren*: im Kampf gibt der Client Addons die Auren anderer nicht
    heraus. Außerhalb liest WeintCodex die Buffs der Gruppe mit
    (`UNIT_AURA` gesammelt, höchstens alle zwei Sekunden;
    `DM.SnapAuras`, `DM.SnapAll` bei Gruppenwechsel und Kampfende) –
    die Ansicht zeigt den **Stand vor dem Kampf** mit Symbol, Restzeit
    und Tooltip, für beide Spieler im Vergleich. Welche Buffs Essen oder
    Fläschchen sind, sagt der Client nicht, und eine Liste der
    Verbrauchsgüter von Forever gibt es nicht – es stehen alle Buffs
    da, keine erfundene Einordnung.
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

## Weltkarte und weicher Rand ums Modell *(6.6.2.1)*

**Weltkarte & Questlog (M)** im Stil der Oberfläche (`W.SkinMap`,
Schalter `mapSkin` unter Tooltip & Fenster, eigens abschaltbar). Die
Karte selbst – Kacheln, Symbole, Questmarken – ist Inhalt und bleibt:
**keine** Suche nach großen Bildern (die Kartenkacheln sind groß), nur
nach Namen. Weg sind: die Hülle am `BorderFrame` (Metallkante
`_UI-Frame-Metal-Edge*`, Portrait), das Pergament außerhalb der Karte
(`gamepad-mapquestlog-bg*` im `OverscrollBG`), Grund und Rahmen der
Questliste (`QuestLog-main-background`, `QuestLog-frame`) – alle
gemessen mit `/wcui fenster` im Beta-Client. Die Leiste „Welt › …“
(`NavBar`) bekommt flache Knöpfe. Darunter eine Kachel mit Schein in
der Klassenfarbe. Die Karte war schon einmal empfindlich (6.6.0.1:
Questmarken im Kampf blockiert, weil Addon-Code die Karte umgestellt
hatte) – hier ändert sich nur Aussehen (Deckkraft, eigene Flächen),
nichts wird umgestellt, geöffnet oder verschoben. `/wcui fenster` lässt
seit 6.6.2.1 die Kartenkacheln aus und geht tiefer (zehn Ebenen, 24
Zeilen) – die nächste Messung nennt, was in der Questliste noch nach
Holz aussieht (Kopfzeilen der Zonen, Suchfeld). Im Spiel ungeprüft.

**Weicher Rand ums Modell** (`W.SoftenModel`, mit „Stimmung statt
Schwarz“): der Hintergrund des Modells (`RaceBG`, bleibt als Bühne)
endete mit harter Kante an der Kachel (Beta-Test: „zu abgehackt“). An
seinen vier Kanten liegt ein Verlauf in der Kachelfarbe, 44 px, der
nach innen ausblendet (`SetGradient`). Echte Unschärfe kann der Client
nicht; ein Verlauf ist, was ein Weichzeichner an einer Kante zeigt.
Gesucht wird einmal je Fenster, danach nicht mehr.

## Berufe, Gilde & Communitys *(6.6.2.1)*

Beide Fenster lädt das Spiel erst beim ersten Öffnen
(`Blizzard_Professions`, `Blizzard_Communities`); sie stehen jetzt in
`W.WINDOWS` – das Berufefenster war vorher gar nicht dabei, deshalb
meldete `/wcui fenster` „common-sidetab · SOLLTE WEG SEIN“.

* **Gemessen** (Berufe, `/wcui fenster` im Beta-Client): Metallrahmen
  in allen Schreibweisen (`!UI-Frame-Metal-*`, `_UI-Frame-Metal-*`,
  `UI-Frame-Metal-Corner*`), `Profession-ProgressBar-*` (flacher
  Balken wie Ruf und Fertigkeiten), `Profession-square-frame`
  (Goldrahmen ums Berufssymbol → 1 px Rand, `W.EdgeBorder`),
  `Profession-Background-Overview`. Die Karten der Übersicht
  (`Profession-overview-card*`) werden **gedämpft** statt ausgeblendet
  (`W.TONE_ATLAS`) – ihr Bild zeigt, welcher Beruf es ist; ohne
  „Stimmung“ sind sie weg. Große Bilder (Werkbank hinter dem Rezept)
  werden wie die Talent-Landschaften gedämpft (`LARGE_PATTERNS` um
  „Profession“ erweitert).
* **Seitenreiter** (`W.SkinSideTabs`): Reiter mit dem Goldrahmen
  `common-sidetab` (ein Reiter je Beruf) und die Reiter der Communitys
  (`ChatTab`, `RosterTab`, `GuildBenefitsTab`, `GuildInfoTab`, Bild
  `.Background` – Namen aus dem Quelltext des Spiels, nicht gemessen)
  werden kleine Kacheln wie am Charakterfenster; gewählt (`GetChecked`,
  `SelectedTexture`, ein „select“-Atlas) = Rand im Akzent.
* **Innenflächen** tiefer im Fenster (`W.SkinInsets`, Schlüssel
  `InsetFrame`/`Inset`: Liste, Chat, Mitglieder der Communitys) – nur in
  diesen beiden Fenstern, die schon gestalteten bleiben unberührt.
* **Schrift**: `W.IsDark` verlangt seit 6.6.2.1 zusätzlich, dass kein
  Farbkanal hell ist – reines Rot (fehlende Reagenzien) blieb sonst
  nicht rot.

Für die Communitys lag keine Messung vor: Liste links (grüne Auswahl,
Wappen), Mitgliederliste und Bildlaufleisten tragen Bilder, deren Namen
erst `/wcui fenster` über dem Fenster nennt. Im Spiel ungeprüft.

## Seitenreiter, Dungeonbrowser, Nachträge *(6.6.2.2)*

**Welcher Seitenreiter gewählt ist** (`W.SideSignals`,
`W.PickSelected`): 6.6.2.1 nahm das erste Zeichen, das ein Reiter trug –
im Berufefenster trugen es alle vier, alle vier standen im Akzent
(Beta-Test). Jetzt wird jedes Zeichen für die ganze Reihe (Reiter mit
demselben Elternrahmen) gelesen, und es zählt nur eines, das die Reihe
**trennt**: `GetChecked`, `SelectedTexture`, ein „select“-Atlas,
gesperrt (`IsEnabled`), dann eindeutig hellster Goldrahmen
(`GetVertexColor`, entsättigt zählt dunkel) oder hellstes Bild. Trennt
keines, ist **keiner** markiert. `/wcui fenster` nennt die Zeichen je
Reiter (`W.SideTabReport`) – so ist beim nächsten Test zu sehen, woran
der Forever-Client den gewählten erkennt, falls keines trennt.

**Suche nach Gruppe** (Dungeonbrowser; im Forever-Client
`LFGParentFrame`, gemessen, im Quelltext des Spiels `PVEFrame` – beide
in `W.WINDOWS`). Gemessen und umgesetzt: Metallrahmen und
`UI-Frame-PortraitMetal-*`, `_UI-Frame-TopTileStreaks`, der Marmor der
Liste (Bild 374155 am `LFGListingFrame`, `W.OWN_BG`),
`common-insideframe`, `groupfinder-background`,
`groupfinder-roles-background`, die Goldrahmen der Kategorien
(`groupfinder-button-cover*` → 1 px Rand); die Kategoriebilder
(`groupfinder-button-questing/-battlegrounds/-custom-pve`) gedämpft
statt weg; die Reiter rechts (`common-sidetab`) wie bei den Berufen.
Rollensymbole bleiben.

**Nachträge Questlog** (Messung über der Questliste): Goldrand des
Suchfelds (`common-search-border-*` → flach), Schatten am Knopf der
Seitenleiste (`MapCornerShadow-*`) weg, braune Pfeilknöpfe
(`QuestCollapse-*`) und die Pfeile/Bahnen der schmalen
Bildlaufleisten (`minimal-scrollbar-*`, überall) grau. Questmarken,
Häkchen und Symbole bleiben.

**Gilde & Communitys**: das Wappen oben links (`PortraitOverlay`) ist
weg. Liste links (grüne Auswahl) und Chat-Eingabe sind ungemessen.

## Plaketten nach NPC *(6.6.2.2, `ui/npccolors.lua`)*

Beta-Test: „wie bei Plater einen NPC per Namen finden und ihm eine Farbe
geben; Voreinstellung: Caster anders als normal angreifende Gegner,
damit man sieht, was unterbrochen werden muss.“ Reiter **NPCs** der
Namensplaketten.

* **Voreinstellung „Zaubernde“** (`casterColoring`, Farbe `caster`,
  Standard an): erkannt an dem, was der Client sagt – NPC-Klasse Magier
  oder Paladin (die NPC-Klassen mit Mana), Energieart Mana mit
  Höchstwert über 0 – oder daran, dass WeintCodex ihn einen Zauber mit
  Zauberzeit beginnen sah (`UNIT_SPELLCAST_START`/`CHANNEL_START` an
  der Plakette, `NC.SawCast`); das merkt es sich je NPC. Sofortzauber
  zählen nicht (die sieht nur das Kampflog).
* **Eigene Regeln** (`npccolors.rules`, getrennt vom Modul wie die
  Klickzauber – „Standard“ löscht sie nicht): je NPC-Kennung (aus der
  GUID, `NC.NpcID`) oder je Name (gilt für jeden mit genau diesem
  Namen). Gefunden wird unter den **gesehenen** NPCs (`npccolors.seen`,
  Kennung → Name, Gebiet, zaubert; höchstens 600, die ältesten gehen;
  ergänzt an Ort und Stelle, ohne Einstellungsereignis). Suche: Anfang
  des Namens zuerst, dann mitten im Namen. „Ziel übernehmen“ legt das
  aktuelle Ziel an, „Als Namen anlegen“ den getippten Namen.
* **Rangfolge im Balken:** markiert → Ziel/Fokus (wenn eingeschaltet) →
  **eigene Regel** → Bedrohung → neutral → Boss → **Zaubernde** → Elite
  → Kampf/außer Kampf.
* **Keine eingebaute NPC-Liste** (Kein Bestand ohne Herkunft): niemand
  hier hat die NPCs von Forever gelesen.
* Kennung, Name, Klasse und Energieart werden einmal beim Erscheinen der
  Plakette gelesen (`NC.Identify`) und an **unserer** Plakette gemerkt
  (`_npcID`, `_npcName`, `_caster`) – die Farbabfrage im Kampf zerlegt
  keine GUID. Geheime Werte zählen als „unbekannt“: keine Regel, kein
  Zaubernder.

## Nachträge *(6.6.2.3)*

**Verlauf mit geheimen Zahlen – gemessen.** Im Beta-Client kamen die
Summen von `C_DamageMeter` im Kampf **geheim**; lesbar war erst die
Probe nach dem Kampf. 6.6.2.1 zeichnete deshalb nur eine Säule am Ende
(Beta-Test: „ich habe die ganze Zeit gekämpft“). Den Zuwachs je Sekunde
kann Lua mit geheimen Werten nicht rechnen. Seit 6.6.2.3 merkt
`DM.Sample` den Wert **so, wie er kommt** (auch geheim, Schlüssel: die
offene GUID, sonst bei `isLocalPlayer` die eigene), und `DM.Cumulative`
zeichnet die **Summe über den Kampf** als senkrechte Balken des Spiels
(`SetMinMaxValues(0, letzte Summe)` / `SetValue` nehmen geheime Werte,
wie beim Lebensbalken) – steil heißt viel, flach heißt nichts; im
Vergleich eine zweite, schmale Säule je Abschnitt im selben Maßstab.
Sind alle Proben offen (anderer Client, nach einem Patch), bleibt es bei
Schaden je Sekunde (`DM.Rates`). Nebenbei: in der Aufschlüsselung
stehen geheime Werte nirgends mehr in `a and b or c` – ausdrücklich
verzweigt. Hinweis: „Aktuell“ und der Verlauf gelten dem **letzten**
Kampf; wer zwischen zwei Gegnern kurz aus dem Kampf ist, beginnt einen
neuen.

**Gilde & Communitys, Liste links** (gemessen): die Einträge
(`communities-nav-button-*`, grün/blau) werden kleine Kacheln, der
gewählte (Bild „pressed“/„select“ gezeigt, je Durchlauf neu bestimmt,
`W.NavEntry`) mit Rand im Akzent; das Wappen im Eintrag
(`communities-guildbanner-*`) bleibt. Grund der Liste (Bild 593918) und
Goldranken (`FilligreeOverlay`) weg. Das **Gildenwappen oben links**
(`PortraitOverlay`) ist wieder da – 6.6.2.2 hatte es ausgeblendet, der
Beta-Test wollte es zurück.

**Weicher Rand ums Modell, zweite Fassung:** 6.6.2.1 legte den Verlauf
an die Kanten des Trägers; das Bild endet oben und rechts aber vorher
(Beta-Test: „oben und rechts abgehakt“). Jetzt sitzt er an den Kanten
des **Bildes** – die Vereinigung aller `RaceBG`-Teile (`W.Bounds`),
gemessen bei jedem Durchlauf, solange das Fenster offen ist –, 60 px
breit. `/wcui fenster` über dem Charakterfenster nennt, wo er sitzt
(„am Bild …“ oder „am Träger“, wenn der Client die Lage nicht kennt).

**Dritte Fassung (6.6.2.4):** Der Bericht sagte „am Bild 0:0:397:464“ –
das ganze Modellfeld, also die richtige Stelle –, und im Spiel war
trotzdem keine Änderung zu sehen. Der Verlauf lag auf `BORDER/7`; die
Hintergrundbilder des Modellfelds liegen auf Ebenen darüber. Jetzt liegt
er auf `OVERLAY/7` (`W.SOFT_LAYER`, `W.SOFT_SUBLEVEL`), der obersten
Ebene des Modellfelds; das 3D-Modell zeichnet der Client über alle
Flächen seines Rahmens, es läuft also nicht mit aus. `/wcui fenster`
nennt zusätzlich die Ebene des Randes, ob er sichtbar ist und seine
Deckkraft („Rand-Ebene …“) sowie Bild und Ebene jeder Fläche am
Modellfeld („Darunter: …“) – bleibt der Rand unsichtbar, steht dort,
warum.

**Vierte Fassung (6.6.2.5) – Maske statt Verlauf:** Auch auf
`OVERLAY/7`, sichtbar, Deckkraft 1 (gemessen) änderte sich nichts. Die
Pixel der Screenshots erklären es: das Bild ist an seinen Rändern selbst
fast schwarz (Himmel), ein Verlauf nach `kachelFill` (fast schwarz)
ändert dort nichts. Hart wirkt die Kante gegen das, was daneben **heller**
ist – den Schein in der Klassenfarbe (`W.AddGlow`, 260 px über die ganze
Fensterbreite, also auch unter dem Modell) und die Werte rechts. Jetzt
laufen die Bilder selbst aus: eine eigene Maske (`media/ui/softmask.tga`,
128 × 128, innen voll, 22 px weich auf null, erzeugt von
`make_ui_media.py`) hängt per `AddMaskTexture` an jedem Bild des
Modellfelds (`W.SOFT_MASK`, `MaskAll`), gestreckt auf die Kanten des
Bildes (`W.Bounds`) – rund 70 px Auslauf. Darunter erscheint der Grund
des Fensters samt Schein. Bilder, die das Spiel später anlegt, bekommen
sie beim nächsten Durchlauf, jedes genau einmal. Das 3D-Modell ist keine
Textur und bleibt scharf. `/wcui fenster` nennt „Maske an N Bildern“
oder, wenn der Client keine Maske anlegt, genau das.

**Kategorien (6.6.2.7).** Beta-Test: „Allgemein, Primäre Eigenschaften
etc. stehen einfach nur in weiß da“. Die Kopfzeilen der Werte trugen den
Holzbalken des Spiels (`UI-Character-Info-Title`, ausgeblendet seit 6.4);
übrig blieb blanker Text. 6.6.2.7 legte ein dunkles Band mit Streifen
links darunter – im Beta-Test „sieht richtig scheiße aus“: ein Block, der
wie ein Loch im Fenster wirkt. Seit 6.6.2.8 eine **Zierlinie**
(`W.Header(f, beam)`): der Titel (`.Title` oder die einzige
Schriftzeile) mittig am Balken, 12 pt, `textBright`, so breit wie sein
Text; links und rechts je eine 1-px-Linie, die vom Titel nach außen
ausläuft (`UIKit.Highlight()`, 70 % am Titel, 0 am Rand, 10 px Abstand
zum Balkenende), am Titel je eine 5-px-Raute (`W.HEADER_GAP`,
`W.HEADER_INSET`, `W.HEADER_ALPHA`). Kein Grund, kein Block.
**Dritte Fassung (6.6.3.0**, Beta-Test: „noch etwas auffälliger, das ist
noch zu wenig“): Titel 14 pt mit Schatten; dahinter ein Lichthof
(`glow_wide`, gedehnt, Hervorhebung, 28 %, `W.HEADER_HALO`); je Seite
eine 7-px-Raute mit dunklem Kern, ein 3-px-Punkt und die Linie (95 % am
Titel) über einem 3-px-Schein (30 %). `W.FitHeader` prüft bei jedem
Durchlauf, ob Titel und Verzierung in den Balken passen: sonst 12 pt
(`W.HEADER_SIZE_SMALL`), und passt es dann noch nicht, gehen die Punkte –
„Primäre Eigenschaften“ ragte im Nachbau sonst bis in die Bildlaufleiste.
Erkannt in `HideByAtlas` am Atlas (`W.HEADER_ATLAS`) – jede Kopfzeile, die
ihn trägt, in jedem gestalteten Fenster. Der Text des Spiels bleibt (kein
`SetText` auf fremde Zeilen). `/wcui fenster` nennt „Kategorien: N (…)“.
**Ruf und Fertigkeiten** (6.6.2.9, gemessen mit `/wcui fenster`): ihre
Kopfzeilen sind Zeilen der Liste (`ReputationFrame.ScrollBox…`,
`SkillsFrame.ScrollBox…`) mit zweimal `common-button-list-collapseExpand`
als Grund und rechts `common-button-list-minus`/`-plus` zum Auf- und
Zuklappen. Der Grund geht (`W.HIDE_ATLAS`), dieselbe Zierlinie kommt
(`W.HEADER_ATLAS`), am **breitesten** der beiden Gründe; die rechte Linie
endet 6 px vor dem Zeichen (`W.HEADER_ICON`), das bleibt und grau wird
(`DESAT_ATLAS`). Unter der Maus eine helle Fläche (`HIGHLIGHT`), weil der
Grund, der das zeigte, weg ist. Die Währungsliste war beim Messen leer –
dieselbe Vorlage ist wahrscheinlich, aber ungeprüft. Unterüberschriften
(verschachtelte Ruf-Gruppen) stehen ebenfalls mittig; die Einrückung des
Spiels geht dabei verloren.

**Speicher und Takt der Fenster (6.6.2.6).** Beta-Test: „egal welches
Fenster ich öffne, der Speicher geht super schnell Richtung 40 MB, kleine
Ruckler, FPS von 90 auf 75“. Zwei Ursachen, beide in `W.Inner`:

- Der Takt lief alle 0,5 s **je offenem Fenster** und darin über **jedes
  je gestaltete Fenster**, auch geschlossene.
- Jeder Durchlauf legte für jeden Rahmen zwei Tabellen und für jede
  Fläche eine Funktion an (`pcall(function() return { f:GetRegions() }
  end)`). Gemessen im Prüflauf (85 Rahmen, 595 Flächen, 20 Durchläufe):
  **11 978 KB** Müll – der Sammler räumt ihn in Rucken weg.

Jetzt:

- `W.Regions(f, key, depth)` / `W.Children(f, key, depth)` liefern eine
  **wiederverwendete** Liste je Durchlauf (`key`) und Tiefe; Prüfungen
  sind feste Funktionen (`pcall(IsTexture, r)` legt nichts an). Derselbe
  Prüflauf: **5,4 KB**. `load_test.lua` hält die Grenze (64 KB).
- `W.Inner` fasst nur **offene** Fenster an (`W.Open`).
- **Ein** Takt für alle (`W.Tick`): alle 0,3 s für 1,5 s nach dem Öffnen
  und nach jedem Klick (`GLOBAL_MOUSE_UP`, `W.Wake`), sonst alle 2 s
  (`W.TICK_FAST`, `W.TICK_SLOW`, `W.FAST_FOR`).

Regel für jeden Durchlauf, der wiederholt läuft: keine Tabelle und keine
Funktion je Rahmen oder Fläche. Wer eine Liste braucht, nimmt
`W.Regions`/`W.Children` mit eigenem `key`; wer eine Liste über einen
Aufruf hinaus behalten will, kopiert sie.

**Charakterfenster, Neukonzept (6.6.4.0).** Beta-Test: kein graues
Standardfenster über einem Bild mehr, sondern *ein* System – dunkle
neutrale Basis + Szene der Klasse + Klassenfarbe als einziger Akzent +
3D-Figur als Mittelpunkt + klare Hierarchie (Figur > Szene > Identität >
Werte/Ausrüstung > Schmuck). Eigenes Modul `ui/character.lua`
(`WeintCodex.UICharacter`, `CS.Update` aus `W.Inner`), getrennt in sieben
Teile:

| Teil | Funktion | was es tut |
|---|---|---|
| Layout | `CS.Layout` | Kachel → `GameColors.showcaseBase` (sehr dunkles Anthrazit); graue Innenflächen (`Inset*`) Deckkraft 0; Schein der Klasse oben auf 30 %; rechts eine Glasebene (`showcaseGlass`, Deckkraft aus dem Thema) über dem rechten Bereich (`InsetRight`, sonst Bildlauf der Werte, sonst `CharacterStatsPane`) mit 44 px weicher linker Kante über dem Auslauf der Szene und einer feinen Linie im Akzent. Folgt dem Ein-/Ausklappen. |
| Szene | `CS.Scene`, `CS.KeepScene` | im Kasten des Modellbildes (`W.SoftenModel`, Maske von dort): Bild der Klasse `BACKGROUND/7`; Abdunklung des Spiels (RaceBG-Overlay) aus, wenn das Thema es sagt; Vignette `BORDER/1` (vier Verläufe); Ruhe hinter der Figur `BORDER/2` (dunkler Hof, **kein** Leuchten). |
| Thema | `CS.Theme` → `WeintCodex.ClassTheme` | `data/classthemes.lua`: `DEFAULT` + Eintrag je Klasse. Anleitung für neue Klassen im Kopf der Datei. |
| Akzent | `CS.Accent` | = `K.Highlight()` = Klassenfarbe (seit 6.6.3.1 der Akzent überall). Steht bewusst **nicht** im Thema: zweite Quelle derselben Farbe. |
| Ausrüstung | `CS.Slots` | Plätze aus `W.SkinSlots` (`W.SlotList`, `W.SlotBorder`): leer = schwarzer Rand, Symbol grau und gedämpft; belegt = Rand im Akzent 45 %, Qualitätsrand des Spiels bleibt; Maus = Akzent voll (`HookScript`). |
| Information | `CS.Header`, `CS.Info` | Kopf „HOLY LARENA / PRIESTERIN · STUFE 13 / Linie im Akzent“ über dem Modell, über der Figur (Ebene); Titel und `CharacterLevelText` des Spiels Deckkraft 0, solange er zu sehen ist (auf anderen Reitern zurück). Namen der Werte `textMuted` statt Gold; Zahlen, Kategorien (`W.Header`) und Bildlauf bleiben. |
| Licht | `CS.Light`, `CS.KeepLight` | Licht der ModelScene in den Farben des Bildes (nur nach Zurücksetzen neu), Schatten unter den Füßen, darüber Dunst und Lichthauch – nur solange die Plätze höher liegen. Der warme Schein hinter der Figur aus 6.6.3.6 ist weg („keine künstlichen Glows“). |

Nicht angefasst: Figur/Kamera, Plätze und ihre Funktion, die Werte des
Spiels (keine eigene Werteanzeige, keine Reiter „Allgemein/Attribute/
Waffen“), Reiter rechts, Knöpfe. Aus `ui/windows.lua` herausgezogen: Kopf-
zeile, Klassenbild und Einbettung (6.6.3.5/6.6.3.6, jetzt Teile oben);
dort bleibt der allgemeine weiche Rand (`W.SoftenModel`). Der Durchlauf
legt nichts an (`load_test.lua`: 20 Läufe < 1 KB). `/wcui fenster` nennt
Thema, Szene, Basis/Glas, Kopfzeile, Plätze, Licht und Ebenen.

**Polishing (6.6.4.1).** Beta-Test: graue Fläche oben rechts, Name/Stufe
doppelt. Der Schein der Klasse oben ist aus (`CS.TOP_GLOW = 0` – weiß beim
Priester = grau); Glas leichter (0.62) mit 80 px Kante; rechte Vignette der
Szene breiter (34 %); Akzentlinie am Glas 22 %. Die Stufenzeile des Spiels
wird am **Inhalt** gefunden (`CS.FindDuplicate`: Schriftzeile im Reiter
Charakter mit Stufe und Klasse, höchstens 20 Durchläufe lang gesucht), sie
und die großen Bilder ihres Trägers (≥ 60×14) gehen auf Deckkraft 0, solange
der Kopfbereich zu sehen ist. `/wcui fenster`: „Doppelte Stufenzeile: …“.

**Review nach Screenshot (6.6.4.2).** Gemessen an Screenshot und
`/wcui fenster` von 6.6.4.1: (1) „Holy Larena“ stand doppelt – der Titel
wurde nur unter `TitleContainer.TitleText` gesucht; `CS.Title` sucht jetzt
wie `StyleTitle` (auch `.TitleText`, `<Name>TitleText`), und `CS.KeepHeader`
hält alles Ersetzte in jedem Durchlauf auf Deckkraft 0, solange der Kopf zu
sehen ist. (2) Die graue Fläche oben rechts war der Schein der Klasse
(Pixel: neutralgrau 99 oben, bis 260 px auslaufend = `windowGlow` weiß 40 %
über 260 px) – trotz Deckkraft 0; jetzt versteckt und je Durchlauf
nachgezogen, `/wcui fenster` nennt „Schein oben“. (3) Das Glas hing am
unsichtbaren `CharacterStatsPane` („eingeklappt“) und wurde nie gezeichnet;
`CS.RIGHT_PANES` nimmt den ersten sichtbaren Kandidaten
(`CharacterStatsPaneScrollBox`) und reicht von unter dem Titelbalken
(`CS.GLASS_TOP`) bis unter die Werte. Kopfzeile 3 px höher/enger (lag in der
Reihe der Zoomknöpfe).

**Diagnose „SPIELER GEGEN SPIELER“ (6.6.4.3).** Die Kopfzeile
(`CS.head.name`, unsere Zeile) las den Namen aus dem **Fenstertitel** des
Spiels (`CS.Title(CharacterFrame)`). Den setzt das Spiel je Reiter; vom
PvP-Reiter zurück stand beim `OnShow` der Kopfzeile noch „Spieler gegen
Spieler“ darin. Jetzt: `UnitPVPName("player")` (was der Reiter Charakter
selbst zeigt), sonst `UnitName`; der Fenstertitel wird nur noch
ausgeblendet, nie gelesen. Dazu zwei zu breite Stellen: `CS.FindDuplicate`
blendete neben der Stufenzeile alle Bilder ab 60×14 ihres Trägers aus
(geraten, entfernt), und beim Verlassen des Reiters ging alles Ersetzte
pauschal auf Deckkraft 1 – jetzt auf die Deckkraft von vorher (`h.orig`),
damit vom Fensterstil Ausgeblendetes aus bleibt. `/wcui fenster` nennt
„Ersetzt: <Name> „<Text>“, …“.

**Jäger (6.6.4.4).** Zweite Klasse über dasselbe Gerüst, ohne eine Zeile
in `ui/character.lua`: Bild `media/classes/hunter.blp` (`make_artwork.py
classes`, Original 1496×1051 **quer**, Datei 1024×1024) und
`ClassArtworks.HUNTER` (`focusX = 0.44`: das Modellfeld zeigt ~60 % der
Breite, volle Höhe – Tor, Banner, beide Wölfe), Thema `ClassThemes.HUNTER`
mit denselben Tiefenwerten wie der Priester und eigenem Licht (Umgebung
leicht grün, Hauptlicht warmes Sonnenlicht, Hauch 3,5 % grünlich). Das
Grün des Akzents kommt aus dem Spiel (`RAID_CLASS_COLORS.HUNTER`) wie
jede Klassenfarbe; `load_test.lua` prüft, dass Basis und Glas mit dem
Jäger-Akzent neutral bleiben und das Priester-Thema unverändert ist.

**Krieger, Druide, Magier, Schurke, Hexenmeister, Paladin, Schamane (6.6.4.5).** Wie der
Jäger: je ein Bild (Querformat 1496×1051 → `media/classes/<klasse>.blp`,
1024×1024, 512 KB; geladen wird nur das der eigenen Klasse), ein Eintrag
in `ClassArtworks` mit `focusX` auf das Motiv der Mitte (Thron 0.54,
Geweihtor 0.56, Sphäre 0.55, Treppe 0.55, Portal 0.60, Altar 0.60,
Steintor 0.59) und ein Thema mit
den Tiefenwerten des Priesters und Licht nach dem Bild. Keine Zeile in
`ui/character.lua`. Damit haben alle neun Klassen eine Szene
(`data_test.lua` prüft das); DEFAULT bleibt der Rückfall für eine Klasse,
die das Spiel neu bringt. Bekannte Reibung: die Klassenfarben von Druide
(Orange, Szene grün) und Paladin (Rosa, Szene gold/blau) kommen aus dem
Spiel – der Akzent bleibt trotzdem die Klassenfarbe.

Die beiden folgenden Abschnitte sind die Vorgeschichte (6.6.3.5/6.6.3.6).

**Klassenbild und Kopfzeile im Charakterfenster (6.6.3.5).** Beta-Test
mit einem gemalten Entwurf: „atmosphärischer als das, was ich bisher
habe“. Übernommen sind die zwei Teile, die zur Linie der übrigen Fenster
passen; der goldene Metallrahmen und Reiter statt Kategorien bewusst
nicht (zweite Zierfarbe neben dem Akzent, eigene Werteanzeige).

- *Klassenbild*: eigenes Material wie die Dungeonbilder, ein Eintrag je
  Klasse in `WeintCodex.ClassArtworks` (`data/artwork.lua`, Zugriff
  `WeintCodex.Art.Class(token)`; `data_test.lua` prüft Klasse und
  Datei). `W.SoftenModel` legt es einmal je Modellfeld an: Ebene
  `BACKGROUND/7` über den vier Hintergrundteilen des Spiels
  (`BACKGROUND/0`, gemessen), unter dessen Abdunklung
  (`UI-Character-Info-RaceBG-Overlay`, `BORDER/0`), im Kasten des
  Bildes und mit **derselben Maske** – es läuft also genauso weich aus.
  Ausschnitt über `WeintCodex.CoverCoords` mit den Maßen des Originals,
  nur wenn sich die Lage ändert. Die Datei ist 1024x1024 (senkrecht
  gestaucht, Zweierpotenz), 512 KB, geladen nur die eigene Klasse
  (`make_artwork.py classes <ordner>`). Ohne Eintrag: nichts, wie
  bisher; `/wcui fenster` nennt „Klassenbild: …“ oder „keines für …“.
  Hängt an „Stimmung statt Schwarz“.
- *Kopfzeile* (`W.CharacterHeader`): der Titel des Spiels (Name) in
  16 pt; darunter unsere Zeile „PRIESTERIN · STUFE 13“ (`W.CharacterLine`,
  versal, gesperrt, Akzent) mit Raute und zwei auslaufenden Linien. Sie
  hängt an `PaperDollFrame`, verschwindet also auf den anderen Reitern,
  und fragt Klasse und Stufe beim Zeigen und bei `PLAYER_LEVEL_UP` –
  nicht im Durchlauf. Unbekanntes bleibt weg (nur „STUFE 13“, oder gar
  keine Zeile).

**Einbettung der Figur (6.6.3.6).** Beta-Test (Screenshot mit dem
Priesterbild): die Figur hell und neutral von vorn beleuchtet vor einem
dunklen, warmen Raum – „wie auf das Bild gesetzt“. Vorgabe: Bild
unverändert, keine neuen Dateien, Aufbau des Fensters bleibt.
`W.EmbedModel` (einmal je Modellfeld, nur mit `light` am Klassenbild in
`data/artwork.lua` – die Werte gehören zum Bild, nicht zur Palette):

- *Licht der Szene*: `SetLightAmbientColor`/`SetLightDiffuseColor` an der
  ModelScene (der Träger selbst oder `CharacterModelScene`). Richtung
  bleibt die des Spiels – echtes Randlicht kann der Client nicht.
  `W.KeepEmbed` vergleicht in jedem Durchlauf mit `GetLightAmbientColor`
  und setzt nur nach einem Zurücksetzen (ohne Getter: jedes Mal, billig
  und ohne Tabellen).
- *Gegenlicht*: `halo` additiv, warm, `BORDER/2` (über der Abdunklung des
  Spiels), auf 40 % Höhe hinter der Figur. *Kontaktschatten*: `halo`
  schwarz, `BORDER/3`, auf Höhe der Füße (9 % über der Unterkante,
  gemessen bei Standardkamera). Beide mit der Maske des Bildes.
- *Über der Figur*: ein eigener Rahmen eine Ebene über dem Modell mit
  eigener Maske – Dunst am Boden (unterstes Sechstel) und ein additiver
  Hauch der Lichtfarbe. Nur solange die Ausrüstungsplätze
  (`W.SLOT_NAMES`) höher liegen, sonst weggelassen – der Dunst dürfte die
  Waffenplätze nicht verdunkeln.
- `/wcui fenster`: „Einbettung: Licht an der Szene (N× gesetzt), Schicht
  über der Figur auf L (Modell M, Plätze P)“. Wächst N bei offenem
  Fenster ständig, fehlt der Getter oder das Spiel setzt zurück.
- Kopfzeile: die Figur lag über ihr (ein Stab verdeckte das zweite E von
  „PRIESTERIN“); `W.KeepHeaderLevel` hält sie über `CharacterModelScene`.

**Höhe der Questliste (6.6.3.4).** Beta-Test: „der Questbereich ragt bis
ganz nach unten – kann man den nicht auf eine Höchstgröße einstellen und
ggf. darin scrollen?“. Die Liste ist die des Spiels; ihre Höhe ist die
Einstellung „Höhe“ der Zielverfolgung im Bearbeitungsmodus, und was nicht
passt, blendet das Spiel aus. Die Einrichtung setzt sie jetzt
(`K.GAME_LAYOUT` „tracker“, `display = { Height = K.TrackerHeight }`):
Bildschirmhöhe − 305 (Platz unter der Karte) − `K.TRACKER_BOTTOM` (300,
über dem Tooltip-Platz), auf den Regler begrenzt (`clamp`,
`ES.RawValue(..., clamp)`; `display`-Werte dürfen Funktionen sein).
**Scrollen: nein.** Die Liste trägt die Knöpfe der Questgegenstände –
geschützte Knöpfe, die ein Addon im Kampf nicht verschieben darf; eine
Liste in einem Bildlauf verschöbe sie. Wer die Höhe sofort will, ohne neue
Einrichtung (die setzt auch Chat und Einstellungen neu): Bearbeitungsmodus
→ Zielverfolgung → „Höhe“.

**Dialoge (6.6.3.4).** Beta-Test: „19 Sekunden bis zum Verlassen“ soll
auch gestaltet werden. Gemessen: Rahmen und Grund in `StaticPopup1.BG`
(`UI-DiamondDialogBox-Border`, `UI-DialogBox-Background-Dark`), rote
Knöpfe als Bilddateien an `StaticPopup1Button1/2`. `W.SkinPopup` für
`W.POPUPS` (`StaticPopup1`–`4`), einmal je Dialog beim Anwenden: `.BG`
weg (nicht die eigenen Bilder des Dialogs – das Warnzeichen bleibt),
Kachel ohne Schatten, der Schein der Klasse **über die ganze Höhe** (die
260 px des Fensterscheins ragten unten hinaus), Knöpfe über
`SkinPanelButton(b, true)` – mit `true` gehen auch die Zustandsbilder
(normal, gedrückt, gesperrt). Über diese Dialoge laufen geschützte
Bestätigungen (Gegenstand zerstören, Einladung, Geist freilassen,
Verlassen): geändert werden nur Bilder – kein Skript, kein Feld am
Dialog, nichts an `StaticPopupDialogs`.

**Sammlung (6.6.3.3).** Beta-Test: „auch Accountsammlung soll ein
Redesign bekommen“. Gemessen: außen Metallrahmen (`NineSlice`), Porträt,
`TopTileStreaks`, Marmor am Fenster (Bild 374155) – `CollectionsJournal`
in `W.WINDOWS` nimmt das mit der Kachel. Innen, unter den Vorlagen
(`WardrobeCollectionFrame.ItemsCollectionFrame`): Leder (Bild 374154),
Kachelmuster, Schatten und Ecken (`collections-background-*`, in
`W.HIDE_ATLAS`). Teilfenster ohne globalen Namen stehen als Pfad in
`W.OWN_BG_PATHS` (`W.Resolve`); `W.OwnBackground` blendet ihre eigenen
Bilder aus und legt eine Innenfläche darunter (`SkinInset`), einmal je
Fläche. Reiter („Gegenstände“) und der Reiter rechts sind nicht gemessen.

**Spielmenü (6.6.3.3).** Beta-Test: „Redesign soll auch im Optionsmenü
Einheit finden“. Gemessen mit `/wcui fenster`: rote Knöpfe
(`128-RedButton-Left/Right/Highlight`, `_128-RedButton-Center` – mit
Unterstrich), Rahmen und Kopf aus `UI-Frame-DiamondMetal-*`, ein Grund am
Rahmen (Bild 131071). `GameMenuFrame` steht in `W.WINDOWS`; `Border` und
`Header` gehen über `W.EXTRA_DECOR`, die Atlanten über `W.HIDE_ATLAS`.
Die Kachel hat **keinen** Schatten nach außen (`W.NO_SHADOW`): das Menü
ordnet seine Knöpfe selbst an und richtet seine Größe danach – ein Bild
über dem Rand soll dabei nicht mitgerechnet werden können. Aus demselben
Grund liegt der Taktgeber jedes Fensters seit 6.6.3.3 genau auf dem
Fenster und trägt `ignoreInLayout`. Der Titel (`Header.Text`) rückt in
die Kachel (`StyleTitle`). Knöpfe: wo `HideByAtlas` einen roten Knopf
findet, macht `W.SkinPanelButton` ihn flach. Über das Menü laufen
Ausloggen, Beenden und der Bearbeitungsmodus – geändert werden nur
Bilder, kein Skript und kein Feld am Menü.

**Mitgliederliste bleibt (6.6.3.3).** Beta-Test: „die Mitgliederliste ist
etwas verdunkelt, das kann gern wieder im Normalzustand sein“.
`SkinInsets` ersetzte auch dort den Grund der Innenfläche des Spiels
(`Bg`, `NineSlice`) durch eine eigene Fläche (`surface1`, 45 %).
`W.INSET_KEEP = { "MemberList" }` nimmt sie aus; Liste und Chat bleiben
gestaltet. Grau stehen weiterhin die Mitglieder, die nicht online sind –
das färbt das Spiel so.

**Weicher Rand um die Karte (6.6.3.1).** Beta-Test: „Alles, was das
Spiel mitbringt und nicht geändert wird, soll genauso weich gezeichnet
werden wie beim Charakterfenster“. Die Karte ist – anders als das
Modellbild – hell; deshalb keine Maske auf ihren Kacheln, sondern
`W.SoftOverlay(window, area, level)`: ein eigener Rahmen über dem
Kartenausschnitt (`ScrollContainer`) mit vier Verläufen in `bgDark`
(48 px, `W.SOFT_OVERLAY`), die nach innen ausblenden. An den Kartenbildern
ändert sich nichts (die Weltkarte ist empfindlich, 6.6.0.1), neue Kacheln
beim Zoomen sind von selbst mit drin, die Maus geht durch. Ebene
(`W.MapOverlayLevel`): direkt unter dem niedrigsten Knopf der Karte
(`overlayFrames` des Spiels), wenn der über der Karte liegt, sonst 100
über ihr – `/wcui fenster` nennt „Weicher Rand (Karte): Ebene …, Karte …,
Knöpfe ab …“. Marken am Rand verblassen mit. Nebenbei: der Knopf der
Seitenleiste (`SidePanelToggle`) trug noch `MapCornerShadow-Right`.

**Zweite Fassung (6.6.3.2), Maske statt Verlauf.** Beta-Test: „immer
noch nicht nach außen weichgezeichnet“. Gemessen am Screenshot: rechts
und unten lief der Verlauf, oben aber liegt über dem Fenster der helle
Schein der Klassenfarbe – dunkler Kartenrand neben hellem Kopf ist
wieder eine Kante (dieselbe Falle wie 6.6.2.4 beim Modellbild). Jetzt
wie dort: die großen Bilder der Karte (≥ 128 × 128, `W.MAP_TILE_MIN`:
Kacheln, erkundete Gebiete) am Inhalt (`ScrollContainer.Child`) und in
seinen Ebenen bekommen `media/ui/softmask` (`W.SoftMap`, `MaskTiles`),
eine Maske je Rahmen, die am **Ausschnitt** sitzt – beim Ziehen und
Zoomen läuft die Karte unter ihr durch; neue Kacheln bekommen sie beim
nächsten Durchlauf, jede einmal. Marken sind kleiner und bleiben scharf.
Der dunkle Verlauf geht aus; er bleibt nur, wo der Client keine Masken
anlegt. `/wcui fenster`: „Maske an N Bildern, darunter M Bilder am
Ausschnitt“ – steht bei M etwas, liegt unter der Karte noch eine Fläche
des Spiels, in die sie ausläuft.

**Alles in Klassenfarbe (6.6.3.1).** Beta-Test: „das komplette Design
immer auf die Klasse basierend – teils ist das ja schon, aber das sollte
überall komplett sein“. Der Akzent **ist** jetzt die Klassenfarbe:
`WeintCodex.SetAccent(r, g, b)` in `core/ui.lua` schreibt jeden Ton, der
aus dem Violett abgeleitet ist, an Ort und Stelle um – gefunden nach
**Wert** beim Laden (`WeintCodex.AccentSlots`: Grund, hell, gedämpft,
tief, Kartenkopf; in `Colors` **und** `GameColors`, Deckkraft bleibt).
Weil die Tabellen dieselben bleiben, sieht jede Stelle die neue Farbe:
WeintCodex-Fenster, Einstellungen, Knöpfe (primär mit dunkler Schrift –
lesbar auch auf Weiß oder Gelb), Reiter, Überschriften, Zauber- und
Erfahrungsbalken (`cast`, `xpBar`), Zielring und -leuchten, Texte.
Gesetzt beim Laden der Datei (`WeintCodex.ApplyClassAccent`, die Klasse
kennt der Client dann schon) und noch einmal bei `PLAYER_LOGIN`
(`UIKit.ResetHighlight`), dann mit der Einstellung
(`general.highlight = "accent"` → exakt das alte Violett). Farbcodes in
Texten: `WeintCodex.AC` statt `|cff7C6CFF`; die Changelog-Daten behalten
`|cff7C6CFF` (Stilregel, `release_notes.py`) und werden beim Zeigen
umgefärbt. `UIKit.Highlight()` ist seitdem schlicht der Akzent.
Bleibt, wie es ist: Grün, Rot, Gold, Blau (Bedeutung) und die Farben der
Spielwelt, die nicht aus dem Akzent kommen. Bekannte Kosten: bei Jäger
und Mönch liegt der Akzent nahe am Erfolgsgrün, beim Todesritter nahe am
Fehlerrot, beim Druiden nahe am Warn-Gold, beim Schamanen nahe am
Hinweis-Blau; bei Priestern ist er weiß und hebt sich von normalem Text
kaum ab.

**Rahmen in Klassenfarbe** (6.6.2.3, Beta-Test: „statt der lila Rahmen
überall lieber Rahmen in der Farbe der Klasse“): `UIKit.Highlight()`
liefert die Klassenfarbe des Charakters (`RAID_CLASS_COLORS`, vom
Spiel) oder – mit `general.highlight = "accent"` („Rahmen und
Hervorhebungen“ unter Allgemein) – den Akzent. Es gilt für Rahmen und
Hervorhebungen, die „gewählt“ oder „das bist du“ sagen: gewählte Reiter
und Einträge in den Fenstern des Spiels, Zielleuchten und Zielrahmen der
Plaketten, der gedrückte/blinkende Aktionsknopf, die offene Tasche, der
Strich unter dem aktiven Chatreiter, die eigene Zeile und die Reiter der
Schadensanzeige, die Belegung in der Zaubertafel der Klickzauber, Rahmen
und Mittellinien im Gestaltungsmodus. **Nicht**: das WeintCodex-Fenster
und das Einstellungsfenster, Texte, Fortschritt (Zauber- und
Erfahrungsbalken), der Questpfeil – dort bleibt der Akzent. Die Farbe
wird beim Bauen gesetzt, ein Wechsel gilt nach dem Neuladen. Priester:
die Klassenfarbe ist Weiß – das Zielleuchten ähnelt dann dem (schwächeren)
Leuchten unter der Maus.

## Designsprache der Fenster *(6.7.0.0, `ui/style.lua`)*

Beta-Test: alle von WeintCodex gestalteten Fenster des Spiels sollen
„eindeutig nach WeintCodex aussehen“, das Charakterfenster ist die
Referenz für Qualität, aber **nicht** die Vorlage für jedes Layout.
Blizzard-Komponenten bleiben (Listen, Bildlauf, Knöpfe, Tooltips,
Navigation); gestaltet wird, was sie umgibt.

**Rangfolge** (jede Entscheidung wird daran gemessen): 1. Information –
2. Interaktion – 3. Orientierung – 4. Atmosphäre – 5. Dekoration.
Keine Information verschwindet, weil sie nicht ins Design passt; nichts
Dekoratives liegt hinter Text.

### Bestand vor dem Umbau

Gemeinsam war schon da, aber verstreut: die Kachel (`K.Kachel`),
Zierlinie der Kopfzeilen (`W.Header` mit `W.Diamond`/`W.Fade`), flache
Balken (`FlatBar`), weiche Ränder (`W.SoftOverlay`), Zustände (Rand im
Akzent an Reitern und Einträgen), die Basis des Charakterfensters
(`GameColors.showcaseBase`/`showcaseGlass`) und derselbe Verlauf dreimal
(`CS.Gradient`, `W.Fade`, `OverlayEdge`). Der Ruf lief bis 6.6.4.5 durch
genau diese allgemeinen Schritte: Kopfzeilen mittig mit Lichthof in der
Klassenfarbe (Einrückung verloren), Bahn `plateBg`, keine sichtbare
Auswahl (die Streifen des Spiels hinter Zeilen sind seit 6.4 weg), die
Detailansicht ungestaltet.

### Bausteine (`WeintCodex.UIStyle`, `ui/style.lua`)

Geladen direkt nach `ui/kit.lua`. `S.own` ist die Tabelle der eigenen
Flächen (`W.own` ist dieselbe); `W.Diamond`, `W.Fade` und
`UICharacter.Gradient` sind seit 6.7.0.0 `S.Diamond`, `S.Fade`,
`S.Gradient`.

| Baustein | Was |
|---|---|
| `S.Accent(kind)` | `"class"` → Klassenfarbe (`K.Highlight`), `"frame"` → `GameColors.frameAccent` |
| `S.SCOPES`, `S.Scope`, `S.ScopeOf`, `S.Register` | Stil je Rahmen des Spiels (globaler Name → Stil) |
| `S.Gradient`, `S.Fade`, `S.Diamond` | Verlauf, auslaufende Linie, Raute |
| `S.Divider` / `S.PlaceDivider` | Trennlinie, in der Mitte voll, zu beiden Enden auslaufend |
| `S.SoftPanel` | dunkle Fläche mit weichem Rand (`media/ui/softmask` als Neunteiler, 22 px) |
| `S.Vignette` | Randabdunklung, vier Verläufe nach innen |
| `S.TopLight` | Hauch des Akzents von oben |
| `S.Panel` | eigenständige Tafel (Kachel in `showcaseBase`) |
| `S.Hover` | hellere Fläche unter der Maus (Ebene `HIGHLIGHT`) |
| `S.Selection` / `S.SetSelected` | Auswahl: 2-px-Strich links + Hauch, malt nur bei Wechsel |
| `S.BarFinish` | Schatten und Lichtkante an der Füllung eines Balkens des Spiels |
| `S.Title` | Größe, Farbe, Schatten einer fremden Zeile (kein `SetText`) |

**Stile.** Ein Stil gilt für einen Rahmen und alles darunter:
`W.HideByAtlas(f, depth, sc)` reicht ihn beim Abstieg weiter, ein Kind
mit eigenem Stil überschreibt ihn. Ohne Stil verhält sich alles wie bis
6.6.4.5.

- `S.SHOWCASE` – Charakter: Klassenfarbe, Kopfzeilen mittig mit Lichthof
  (`W.Header`). Unverändert.
- `S.CALM` – informationslastige Fenster, die **nicht** der Klasse gehören:
  Gold, Kopfzeilen als Zeile der Liste (`W.ListHeader`), Balkenbahn
  `barTrack`, weicher Balkenrand (`barEdge`). Zurzeit in keinem Gebrauch.
- `S.CHARACTER_INFO` *(6.7.0.1)* – dasselbe für die Informations-Reiter
  des Charakterfensters (Ruf): **Klassenfarbe** statt Gold.

**Zwei Akzente – eine Ausnahme von „ein Akzent“.** Der Beta-Test will
für allgemeine Fenster ein gedämpftes warmes Gold und die Klassenfarbe
für alles, was zum Charakter gehört. `GameColors.frameAccent` (C1A470)
ist deshalb ein zweiter Akzent. Regel, damit daraus nicht wird, was die
MoP-Fassung beendet hat („Bernstein trägt Bedeutung, Lila trägt
Licht“): **ein Bereich trägt genau einen der beiden**, und welcher,
sagt sein Stil. Gold ist keine Ableitung des Violetts – `SetAccent`
rechnet es nicht um (`load_test.lua` prüft das mit der Jägerfarbe).
Status­farben (grün/rot/gold/blau) bleiben, was sie sind; `C.gold`
(F0A63A) ist eine Zustandsfarbe und nicht dieser Akzent.
6.7.0.0 gab dem Ruf Gold; der Screenshot zeigte die erwartete Reibung
(Reiter und Titel in Klassenfarbe, Inhalt gold), und der Beta-Test
entschied: **Ruf gehört zum Charakterfenster → Klassenfarbe**. Gold
bleibt Blizzard-eigenen Teilen (gelbe Häkchen-Beschriftungen, Pfeil am
Ausklappknopf, gelbe Füllung „Neutral“) – die sind Darstellung des
Spiels und bleiben.

### Der Ruf (`ui/reputation.lua`, Stil `S.CHARACTER_INFO`)

Aufgerufen aus `W.Inner` im Zweig des Charakterfensters, nach
`CS.Update`. Nur wenn `ReputationFrame` sichtbar ist. Leitbild
(Beta-Test 6.7.0.1): *Character = Szene + Figur + Klassenfarbe; Ruf =
Information + dezente Atmosphäre + Klassenfarbe* – kein kleines
Charakterfenster.

**Gemessen (6.7.0.0, `/wcui fenster` im Beta-Client):** Zeilen unter
`ReputationFrame.ScrollBox.ScrollTarget` mit `.Content` (11 Zeilen,
3 Kopfzeilen, 11 Namen gefunden); Auswahl über die Detailansicht
funktioniert; Detailansicht `ReputationFrame.ReputationDetailFrame`,
im Fenster, Titel `.Title`, vom Dialograhmen nichts mehr sichtbar.
**0 Balken** gefunden: `Content.ReputationBar` ist in diesem Client
**kein Statusbalken**, seine Füllung ist das Bild
`common-stat-bar-white`. Und an jeder Zeile liegt die Hervorhebung des
Spiels, `Content.BackgroundHighlight` mit
`charactercreate-customize-dropdown-linemouseover-side/-middle`
(braun-gold, bei Maus und Auswahl).

- **Flächen** *(6.7.0.1, „zu schwarz und flach“)*: 6.7.0.0 legte unter
  die Liste einen **dunkleren** Grund – Schwarz neben Schwarz, harte
  Kästen. Jetzt sind Bereiche eine Stufe **heller** als die Basis:
  `GameColors.surfaceRaised` (0.068/0.070/0.082 zu 75 % über
  `showcaseBase`), weicher Rand (`S.SoftPanel`, Neunteiler, 22 px) und
  oben eine Lichtkante (weiß 7 %, zu beiden Seiten auslaufend,
  `S.PlaceTop`) – `RP.Surface`. Unter Liste **und** Bildlaufleiste
  (`ScrollBox` bis `ScrollBar`, 8 px darüber hinaus).
- **Atmosphäre**: auf dem **Charakterfenster selbst**
  (`BACKGROUND -6/-5/-4`) – unter allem, was das Spiel zeichnet, also nie
  über Titel, Knöpfen oder Text. Vignette 35 % / 48 px, Licht von oben
  **neutral** (`atmosLight`, weiß 3,5 % / 140 px – keine Farbe, die
  Klassenfarbe gehört nur Akzenten). Ein- und ausgeblendet mit dem
  Reiter (`HookScript` `OnShow`/`OnHide`, dazu jeder Durchlauf).
- **Gruppen**: `W.ListHeader` statt `W.Header`. Der Text bleibt, **wo
  das Spiel ihn hinsetzt** (kein `ClearAllPoints`, nur linksbündig,
  13 pt, `textBright`, Schatten) – die Einrückung verschachtelter
  Gruppen bleibt. Hinter dem Text Raute und Linie in der Klassenfarbe
  (55 %), bis vor das Zeichen zum Auf- und Zuklappen. Kein Lichthof.
- **Balken**: gefunden über den Schlüssel (`Content.ReputationBar`, jede
  Art Rahmen), Füllung `RP.BarFill` (Textur eines Statusbalkens, sonst
  das Bild `common-stat-bar-white`). Bahn `barTrack` (dunkler als die
  Fläche), Rand schwarz 50 % statt 100 %, an der Füllung
  (`S.BarFinish(bar, fill)`) unten Schatten 30 %, oben die Lichtkante
  aller Balken. Farbe, Textur und Text der Stufe bleiben die des Spiels.
- **Maus**: die Hervorhebung **des Spiels** wird entsättigt und in der
  Klassenfarbe getönt (`S.Tint`, 55 %) – wann sie erscheint, bestimmt
  weiter das Spiel. Geprüft wird jeden Durchlauf, gesetzt nur bei
  Abweichung. Eine eigene Mausfläche (`S.Hover`) nur an Zeilen ohne
  sie; Kopfzeilen haben ihre eigene.
- **Auswahl** – der stärkste Akzent: gewählt ist die Zeile, deren Name
  rechts in der Detailansicht steht; ist sie zu, ist **keine** markiert.
  2-px-Strich in der Klassenfarbe links, dahinter ein Schein (16 % →
  0), dazu die getönte Hervorhebung des Spiels.
- **Detailansicht**: der Dialograhmen (`Border`, `NineSlice`, `Bg`,
  `Background`) weg. **Im Fenster** dieselbe Fläche wie die Liste
  (`RP.Surface`, 4 px über den Rand) – ein Bereich derselben Oberfläche,
  kein zweiter schwarzer Kasten –, oben eine feine Kante in der
  Klassenfarbe (55 %, 10 px vom Rand). Frei am Bildschirm (anderer
  Client) eine deckende Tafel (`S.Panel`) samt `HideByAtlas`/`Grey`.
  Titel 14 pt. Die Trennlinie unter dem Titel (6.7.0.0) ist weg – sie
  lag zu nah an der Stufe darunter. Beschreibung, Häkchen, Knöpfe
  unverändert.
- **`/wcui fenster`** über dem Ruf: „Ruf (Stil ruhig, Klasse): Liste
  gefunden, N Zeilen (K Kopfzeilen, B mit Balken, M mit Namen)“, „Ruf,
  Balken: ‹Art›, Füllung Bild/Statusbalken/keine · Hervorhebungen des
  Spiels getönt: n“, „Ruf, gewählt: …“, „Ruf, Detailansicht: Fläche im
  Fenster / Tafel, frei, Titel …, Rahmen des Spiels: n Bilder noch
  sichtbar“.
- **Geprüft** (`load_test.lua`): Stil der Klasse, **kein Verlauf in
  Gold** im ganzen Ruf, Balken ohne Statusbalken gefunden und veredelt,
  Hervorhebung getönt und nicht verdoppelt, Auswahl folgt der
  Detailansicht, nichts ausgeblendet, kein `SetText`, Titel nicht
  verschoben, 20 Durchläufe unter 1 KB (gemessen 0,0 KB).

Im Spiel ungeprüft (6.7.0.1): wie hell die Flächen wirken, ob die
getönte Hervorhebung bei Weiß (Priester) noch von der Auswahl zu
unterscheiden ist.

### Codex-Tafel und Sektionen *(6.7.0.2)*

Beta-Test: „technisch sauber, lesbar – aber zu eintönig und flach“. Ziel:
ein **Fraktionsregister / Welt-Codex** statt einer schwarzen Liste. Kein
Neubau: dieselbe Liste des Spiels, dieselbe Detailansicht, nur neue
eigene Flächen und Linien daneben und darunter.

**Linke Seite (Register).**
- **Gruppen als Abschnitte**: `S.Band` an jeder Kopfzeile – Licht von
  links (`sectionBand`, weiß 5 %, nach rechts auslaufend) und oben eine
  Haarlinie (`hairline`, weiß 5,5 %); Überschrift 14 pt
  (`S.CHARACTER_INFO.headerSize`), Raute und Linie in der Klassenfarbe
  wie gehabt. Einrückung des Spiels bleibt (Text nicht verschoben).
- **Kein echter zusätzlicher Abstand zwischen Gruppen.** Die Liste
  (`WowScrollBoxList`) ordnet ihre Zeilen selbst nach der Höhe ihrer
  Vorlagen; mehr Abstand hieße, ihre Anordnung zu ersetzen
  (Höhenrechner der Ansicht) – das ist Blizzard-Funktionalität und
  bleibt. Band und Haarlinie trennen die Gruppen optisch.
- **Fraktionen**: Haarlinie unten an jeder Zeile (10 px vom Rand), nicht
  an Kopfzeilen.
- **Auswahl** (der stärkste Akzent, aber kein Block): 2-px-Strich,
  Schein 22 % → 0 nur übers erste Drittel der Zeile
  (`S.SELECT_SPREAD`), die Zeile eine Spur heller (`selectLift`). Die
  getönte Hervorhebung des Spiels nur noch 30 %.
- **Rufstufen-Farben** (Neutral gelb, Freundlich grün …) bleiben die des
  Spiels – Füllung wird nie umgefärbt, nur Schatten und Lichtkante
  darüber.

**Tiefe.** Mehrere leise Ebenen, keine davon farbig: Basis
(`showcaseBase`) → Vignette → neutrales Licht → Schatten
(`shadowSoft`, 16 px über die Fläche hinaus) → Liste (`surfaceRaised`,
75 %) bzw. Detailansicht (`surfaceDetail`, eine Spur heller und
dichter, 88 %) → vertiefte Bereiche (`surfaceSunken`). Lichtkante oben
an Liste und Detailansicht.

**Codex-Zeichen**: `media/ui/sigil.tga` (256×256, eigenes Astrolab aus
Ringen, Teilstrichen und Kompassstern, erzeugt von
`make_ui_media.py`), weiß mit `codexSigil` = 4,5 %, unten rechts in der
Ecke der Liste angeschnitten (60 % gezeigt). Liegt auf dem
Charakterfenster, unter allem, was das Spiel zeichnet.

**Rechte Seite (Tafel).** Reihenfolge des Spiels, WeintCodex zieht nur
Grenzen:

```
Fraktionsname (16 pt)
Rufstufe
──── Linie in der Klassenfarbe (9 px über dem Balken)
Rufbalken (weicher Schatten, Tiefe an der Füllung)
Beschreibung (leicht vertiefte Fläche)
──── Linie mit Raute (14 px über dem obersten Häkchen)
Optionen (vertiefte Fläche bis unten)
```

- Balken der Tafel: `RP.DetailBar` – Schlüssel (`ReputationBar`, `Bar`,
  `StatusBar`), sonst der erste Rahmen bis zwei Ebenen tief, der die
  Füllung `common-stat-bar-white` trägt oder ein Statusbalken ist.
- Optionen: `RP.OptionTop` – Oberkante des obersten sichtbaren
  Häkchens (`CheckButton`, gemessen: `AtWarCheckbox`).
- `RP.DetailLayout` misst jeden Durchlauf (`GetTop`/`GetBottom`,
  relativ zur Oberkante der Tafel) und legt nur bei Änderung neu; die
  Beschreibungsfläche nur bei mehr als 30 px Platz. **Kein Rahmen des
  Spiels wird verschoben oder in der Größe geändert** (`load_test.lua`
  prüft es) – der Balken wird nicht größer, er tritt durch Schatten
  hervor.
- Die Rufstufe unter dem Namen ist nicht angefasst: ihr Schlüssel ist
  ungemessen, und sie ist schon zurückgenommen.
- `/wcui fenster`: „Ruf, Tafel: Balken ‹Art›, Optionen n Häkchen,
  Bereiche: Balken y, Beschreibung ja/nein, Optionen y“ – fehlt ein Teil,
  steht dort „FEHLT“ bzw. „–“.

Im Spiel ungeprüft: alle Werte (Dichte der Flächen, Sichtbarkeit des
Zeichens, Lage der Grenzen).

### Die Karte *(6.7.0.3)*

Screenshot 6.7.0.2: unter Balken und Beschreibung viel leerer Raum,
die drei Häkchen am unteren Rand – dort verankert sie das Spiel, und
Linie und Optionsbereich richteten sich nur nach ihnen. Leer blieb der
Raum, solange nichts rückt; deshalb rücken jetzt die Häkchen (der
einzige Eingriff in die Lage eines Rahmens des Spiels in diesem
Fenster):

```
Fraktionsname / Rufstufe
──── Linie ────
Rufbalken
Beschreibung
   30 px
──── Linie mit Raute ────
Optionen (vertiefte Fläche)
   12 px
Ende der Karte (Fläche + Schatten)
```

- **Beschreibung finden** (`RP.DetailDescription`): Schlüssel
  `Description`, `DescriptionText`, `ScrollingDescription`, `Text`
  (Schriftzeile oder Rahmen mit `GetFontString`), sonst die Schriftzeile
  mit dem längsten Text in der Detailansicht bis zwei Ebenen tief, ohne
  Titel und ohne Häkchen, mindestens 40 Bytes. Ende = Oberkante −
  `GetStringHeight` – der **Text**, nicht der Rahmen, der größer sein
  kann.
- **Häkchen vermessen** (`RP.Options`, einmal, bevor etwas bewegt wird):
  sichtbare `CheckButton` der Detailansicht mit Lage relativ zu ihr.
  Gesperrt (`d.movable = false`, Grund in `d.why`), wenn eine
  Beschriftung nicht am Häkchen hängt (Schriftzeile als eigene Fläche
  oder `.Text`) – sie liefe sonst nicht mit – oder ein weiterer Knopf
  (außer `CloseButton`) sichtbar ist.
- **Rücken** (`RP.PlaceOptions`): alle gemeinsam um dieselbe Strecke,
  `SetPoint("TOPLEFT", Detailansicht, …)` mit den gemessenen Abständen.
  Nur nach oben (Ziel = Ende der Beschreibung − 30 px); weniger als
  8 px lohnt nicht; ist die Beschreibung so lang, dass das Ziel tiefer
  läge als der Platz des Spiels, kommen sie genau dorthin zurück.
  Geprüft in jedem Durchlauf: stehen sie woanders (vom Spiel
  zurückgesetzt), werden sie neu gelegt. Nie bewegt → nie angefasst.
- **Karte** (`RP.PlaceCard`): Fläche und Schatten der Detailansicht
  enden 12 px unter dem letzten Häkchen, wenn sie gerückt sind, sonst
  am Rand. Die vertiefte Beschreibungsfläche von 6.7.0.2 ist weg (im
  Screenshot nicht zu sehen, nur ein Kasten mehr).
- Skripte, Zustand, Größe, Text der Häkchen: unverändert.
- `/wcui fenster`: „Ruf, Karte: Balken …, Beschreibung gefunden/FEHLT,
  Optionen n Häkchen, Bereiche: …“ und „Ruf, Optionen: um N px nach
  oben gerückt, Karte endet darunter“ bzw. „nicht gerückt (Grund)“.

Im Spiel ungeprüft: ob die Beschriftungen der Häkchen an ihnen hängen
(sonst meldet der Bericht den Grund und nichts rückt) und ob
`GetStringHeight` die Höhe des umbrochenen Textes liefert.

### Register und Fertigkeiten *(6.7.1.0)*

Beta-Test: das Fähigkeitenfenster (Reiter „Fertigkeiten“) auf das Niveau
des Rufs bringen – dasselbe System, keine Kopie. Die Liste der
Fertigkeiten ist dieselbe Vorlage wie die des Rufs (gemessen 6.6.2.9:
`SkillsFrame.ScrollBox`, `common-button-list-collapseExpand`,
`common-stat-bar-BG`). Statt `ui/reputation.lua` zu kopieren, ist seine
Logik ein Baustein geworden.

**`ui/register.lua`** (`WeintCodex.UIRegister`): `New(cfg)` liefert ein
Register mit `Update(f)`/`Report(f, out)` und denselben Feldern wie
vorher der Ruf (`atmos`, `rows`, `bars`, `details`, `state`, `Options`,
…). Jedes Register trägt sich in `UIRegister.all` ein (W.Inner ruft
alle, `/wcui fenster` fragt alle) und seinen Stil für seine Fenster in
`S.SCOPES` – `ui/style.lua` enthält keinen Fensternamen mehr;
`S.Register` löst dort auch Pfade auf. Einstellungen (Kopf von
`ui/register.lua`): `label`, `frames`, `style`, `detailKeys`,
`detailGlobals`, `detailSearch`, `titleKeys`, `titleGlobals`,
`titleTop`, `barKeys`, `detailBarKeys`, `sigil`, `barLine`, `tail`,
`compact`.

| | Ruf | Fertigkeiten |
|---|---|---|
| Fenster | `ReputationFrame` | `SkillsFrame`, `SkillFrame`, `CharacterFrame.SkillsFrame`/`.SkillFrame` |
| Detailansicht | `ReputationDetailFrame` (gemessen) | Schlüssel aus älteren Fassungen, sonst **Suche**: Kind des Fensters mit dem längsten Text |
| Titel | `.Title` (gemessen) | Schlüssel, sonst die **oberste Schriftzeile**; steht er **im Balken**, bleibt er unverändert |
| Linie am Balken | darunter (seit 6.7.2.1; vorher darüber) | **darunter** (Name/Fortschritt gehören zusammen) |
| Unter der Beschreibung | Häkchen, rücken nach oben | was folgt (Zeilen, Knöpfe) → abgesetzter Bereich, **nichts bewegt** |
| Karte | endet immer unter dem Inhalt (seit 6.7.2.1; vorher nur unter gerückten Häkchen) | endet immer unter dem Inhalt (`compact`) |
| Codex-Zeichen | ja | **nein** – kein passendes Motiv, keins erzwungen |

**Fortschrittsbalken**: gefunden über Schlüssel oder – neu, für alle
Register – als erster Statusbalken bzw. Rahmen mit der Füllung
`common-stat-bar-white` bis zwei Ebenen tief. Bahn `barTrack`, Rand 50 %,
Schatten und Lichtkante an der Füllung. **Farbe und Text bleiben die des
Spiels** (Blau = Fortschritt); `load_test.lua` prüft, dass weder
`SetStatusBarColor` noch die Farbe der Füllung angefasst wird.

**Was unter der Beschreibung folgt** (`tail`): sichtbare Schriftzeilen
mit Text und Knöpfe in der Detailansicht (bis zwei Ebenen), deren
Oberkante unter dem Text der Beschreibung liegt – nicht Titel, nicht
Beschreibung, nicht der Balken und was in ihm steht. Die Linie mit Raute
steht mittig zwischen Beschreibung und diesem Bereich.

**Wiederverwendet** aus `ui/style.lua`: `S.CHARACTER_INFO`, `S.Band`
(über `W.ListHeader`), `S.Hairline`, `S.Selection`/`S.SetSelected`,
`S.Tint`, `S.Hover`, `S.BarFinish`, `S.SoftPanel`, `S.Shadow`,
`S.Vignette`, `S.TopLight`, `S.Divider`/`S.PlaceTop`/`S.Under`,
`S.PlaceBand`, `S.Diamond`, `S.Title`, `S.Panel`. **Neu in
`ui/style.lua`**: nichts Fertigkeiten-Spezifisches – nur `S.SCOPES` leer
und `S.Register` mit Pfaden. **Unverändert** bleiben alle Blizzard-Teile:
Liste und Bildlauf (`ScrollBox`, `ScrollBar`), Zeilen, Kopfzeilen samt
Auf-/Zuklappen, Balken (Farbe, Text, Größe), Detailansicht, Texte,
Knöpfe; kein Rahmen der Fertigkeiten wird bewegt.

`/wcui fenster` über den Fertigkeiten: dieselben Zeilen wie beim Ruf,
mit „Fertigkeiten, …“; neu der Name der gefundenen Detailansicht
(`GetDebugName`) und „(im Balken)“ am Titel, und „Fertigkeiten,
Optionen: darunter abgesetzt ab y“ bzw. „nichts unter der
Beschreibung“.

Im Spiel **ungeprüft**: der Name des Fensters, die Schlüssel der
Zeilen und – vor allem – die Detailansicht. Steht dort „nicht
gefunden“, sind Liste, Balken und Atmosphäre trotzdem gestaltet, nur die
Karte fehlt; der nächste Schritt ist dann die Messung.

### PvP-Profil *(6.7.2.0, `ui/pvp.lua`)*

Beta-Test: der Reiter „Spieler gegen Spieler“ als hochwertiges
PvP-Profil – Rang, Rangsymbol, Rangpunkte, nächste Belohnung; weniger
schwarze Fläche. Kein Register (keine Liste), sondern ein Profil mit
Mittelpunkt. Trägt sich in `W.TABS` ein, Stil `S.CHARACTER_INFO`
(Klassenfarbe als Akzent, wie Ruf und Fertigkeiten – derselbe Reiterstreifen;
Gold daneben wäre ein zweiter Akzent in einem Bereich).

**Ungemessen.** Wie der Forever-Client den Reiter baut, hat niemand
gelesen (kein Screenshot dazu, kein `/wcui fenster`). Gefunden wird über
Lage und Form (`PV.Scan`, wiederholt, bis etwas gefunden ist):

| Teil | Wie |
|---|---|
| Fenster | `PVPFrame`, `HonorFrame`, `CharacterFrame.PVPFrame`/`.HonorFrame` – der erste sichtbare |
| Detailansicht | Kind des Fensters mit dem längsten Text (≥ 40 Bytes) |
| Rangsymbol | größtes sichtbares, etwa quadratisches Bild (≥ 40 px, Seiten 0,75–1,33) außerhalb der Detailansicht, höchstens 30 % der Fensterfläche (sonst Hintergrund) |
| Rangpunkte | Schriftzeile außerhalb mit „Zahl / Zahl“ (Form, kein Wort) |
| Rang | Schriftzeile außerhalb, deren Mitte der des Symbols am nächsten ist |
| Balken | `RG.FindBar` außerhalb der Detailansicht |
| Titel | oberste Schriftzeile der Detailansicht |
| Belohnung | Knopf mit `.Icon` oder etwa quadratischem Bild in der Detailansicht |
| Überschrift | Schriftzeile höchstens 40 px über der Belohnung, die ihr am nächsten ist |

**Links / Mitte:** `S.Stage` am Rangsymbol (dunkler Hof `stageShade`
2,4 × Symbol, Hauch Licht `stageLight` 1,5 ×, auf dem Charakterfenster,
also unter dem Symbol). Um Symbol, Rang, Rangpunkte und Balken (je
Durchlauf vermessen, `PV.PlaceArea`) eine angehobene Fläche mit Schatten
und Lichtkante, darüber `S.Ornament`. Rangpunkte 13 pt, **Farbe des
Spiels** (`S.Title(fs, 13, false)`); Balken mit Tiefe, Farbe des Spiels.

**Rechts:** Rahmen der Detailansicht weg, Karte (`surfaceDetail`,
Schatten, Kante in der Klassenfarbe), Titel 16 pt **in seiner Farbe**,
Linie darunter; Ornament über „Nächste Belohnungen“; die Belohnung von
ihrer Oberkante bis zur tiefsten Zeile darunter auf `surfaceSunken`;
Karte endet 12 px unter dem Inhalt. Symbol, Name (Qualitätsfarbe) und
Text der Belohnung unverändert.

**Atmosphäre:** Vignette 45 % / 56 px (Ruf 35 %), neutrales Licht,
zwei entfernte Fackeln (`torchGlow`, warm, 5,5 %, `halo` 220 px) unten
am linken Rand und vor der Detailansicht. Keine Arena-Silhouette: kein
passendes Motiv unter den Grafiken, keins erzwungen.

**Neue generische Bausteine** (`ui/style.lua`): `S.Stage`/`S.FitStage`,
`S.Ornament`/`S.PlaceOrnament`, `S.PlaceRect`, `S.Title(…, false)`. Im
Register ist dasselbe Ornament noch von Hand gebaut (Linie + Raute) –
umstellen, wenn es dort ohnehin angefasst wird. **Blizzard-Teile:**
Rangsymbol, Rang, Rangpunkte, Balken, Detailansicht, Titel, Texte,
Belohnungsknopf samt Symbol und Name – alle unverändert in Lage, Text und
Farbe; nur Schriftgröße von Rangpunkten und Titel.

`/wcui fenster` über dem Reiter: „PvP (Stil …): Fenster …“, „PvP, Rang:
Symbol … · Rang … · Punkte … · Balken …“, „PvP, Rangbereich: …“, „PvP,
Detail: … · Titel … · Belohnung … · Überschrift … · Karte endet …“ –
fehlt etwas, steht dort „FEHLT“.

**Gemessen nach 6.7.2.0 (Screenshot und `/wcui fenster`):** der Reiter
heißt im Forever-Client `PVPRankFrame` (Teile `MainInfoFrame`,
`MainInfoFrame.RankProgressBarDisplay` mit `NextRewardLevel`,
`DetailFrame.Content`). Der Name fehlte in `PV.FRAMES` – 6.7.2.0 griff im
Spiel **nicht**; die Überschrift „Nächste Belohnungen …“ bekam nur den
allgemeinen Stil des Charakterfensters.

**6.7.2.2, auf den gemessenen Aufbau gestellt.** Sichtbare Bilder nach
Fläche (`/wcui fenster`): der Schein `…-Honor-Bar-BG-Glow` ist das
**größte** – die Suche nach dem größten quadratischen Bild hätte ihn als
Rangsymbol genommen. Deshalb Schlüssel und Atlas zuerst:

| Teil | 6.7.2.2 |
|---|---|
| Fenster | `PVPRankFrame` zuerst (danach die alten Namen) |
| Detailansicht | `.DetailFrame`, sonst Suche |
| Rangsymbol | Bild mit Atlas `UI-Character-Info-Honor-Icon…` (Wappen), sonst das größte |
| Medaillon | Rahmen des Symbols (`RankProgressBarDisplay`), wenn er im Fenster hängt und höchstens 30 % groß ist – gehört in den Rangbereich (Ring und Flügel ragten sonst hinaus) |
| Rang | nächste Zeile **mit Wort** – die „0“ in `NextRewardLevel` ist die nächste Belohnungsstufe, stand dem Wappen näher als „Zivilist“ |
| Belohnung | Knopf mit Symbol **oder** Rahmen mit `.Icon` oder bis 80 px hoch mit Symbol und Text (das Symbol liegt in einem namenlosen Kind von `Content`, die Art ist ungemessen) |
| Überschrift | Kopfzeile des Spiels → `W.ListHeader` (Stil des Bereichs, wie „Gegner auf gleicher Stufe“ bei den Fertigkeiten); dann **kein** zweites Ornament darüber |

Nebenbei: `W.Resolve` legte mit `gmatch` in jedem Durchlauf eine Closure
an, sobald ein Fenster über einen Pfad gesucht wurde – bei PvP immer, wenn
der Reiter zu ist, bei den Fertigkeiten, wenn `SkillsFrame` nicht global
ist. Jetzt mit `find`/`sub`, ohne Anlage.

### Ruf wie Fertigkeiten *(6.7.2.1)*

Beta-Test: Ruf und Fertigkeiten sind gemeinsam die Vorlage der ruhigen
Informationsoberfläche; Ruf soll nicht „besonders“ aussehen, sondern
dieselbe Hierarchie tragen. Seit 6.7.1.0 sind beide **ein** Baustein
(`ui/register.lua`) – verschieden waren nur drei Einstellungen. Zwei
davon folgen jetzt den Fertigkeiten:

- `barLine = "below"`: Fraktionsname, Rufstufe und Rufbalken bilden den
  Kopf der Karte (Haupttitel → sekundäre Information → Fortschritt), die
  Linie in der Klassenfarbe steht darunter, dann die Beschreibung.
- `compact = true`: die Karte endet auch dann unter den Häkchen, wenn sie
  nicht rücken dürfen (Beschreibung zu lang, Beschriftung nicht am
  Häkchen, weiterer Knopf) – vorher reichte sie dann bis zum Rand.

Bleibt Ruf-eigen: das Rücken der Häkchen unter die Beschreibung (nur der
Ruf hat Häkchen) und das Codex-Zeichen (Astrolab, 4,5 %, unten rechts in
der Liste). Kein neuer Baustein, keine Änderung an `ui/style.lua` oder
`ui/register.lua`; Liste, Kopfzeilen, Auswahl, Balken und Atmosphäre sind
seit 6.7.1.0 derselbe Code wie bei den Fertigkeiten.

### Abzeichen *(6.7.3.0, `ui/currency.lua`)*

Beta-Test: das Währungsfenster (Reiter „Abzeichen“) im selben System.
Das dritte Register nach Ruf und Fertigkeiten, Stil `S.CHARACTER_INFO`.

**Gemessen** (`/wcui fenster`, Stufe 19 ohne Währungen): `TokenFrame`,
Bildlauf `TokenFrame.ScrollBar` (`minimal-scrollbar-*`), rechts nur der
Hinweis „Wählt eine Währung, um ihre Details anzuzeigen.“ **Ungemessen:**
Schlüssel der Liste (`listKeys`: `ScrollBox`, `Container`,
`ScrollFrame`), der Zeilen (wie im Ruf erwartet: `.Content`, `.Name`) und
der Detailansicht (Schlüssel, globale Namen, sonst Suche nach dem Kind mit
dem längsten Text). Kopfzeilen vermutlich dieselbe Vorlage wie im Ruf.

| | Abzeichen |
|---|---|
| Liste | angehobene Fläche, Abschnitte (Band, Raute, Linie), Haarlinien, Auswahl – wie Ruf |
| Zeile | Symbol, Name, Anzahl unverändert; kein Balken (keiner erfunden) |
| Karte | Titel = oberste Zeile, Beschreibung, `tail` (was folgt; Häkchen rücken wie im Ruf, falls es welche gibt), `compact` |
| Codex-Zeichen | nein |

**Leerzustand** (neu im Register, gilt für alle): hat die Detailansicht
höchstens **eine** sichtbare Schriftzeile (ohne Häkchen), ist nichts
gewählt. Dann nur Fläche und Kante; Titel, Beschreibung, Balken-Linie und
Bereiche werden erst bestimmt, wenn Inhalt da ist – vorher wäre der
Hinweis für immer Titel (16 pt) und Beschreibung geworden. `/wcui fenster`:
„Abzeichen, Detailansicht: Leerzustand …“. Dazu: `Longest`/`Topmost`
zählen nur sichtbare Zeilen (ein ausgeblendeter Hinweis ist weder Titel
noch Beschreibung); die per Suche gefundene Detailansicht gilt nur, solange
sie sichtbar ist; `R.Options` legt erst mit dem ersten Häkchen eine
Tabelle an (vorher: `{}` je Durchlauf in jeder Detailansicht ohne Häkchen,
also auch bei den Fertigkeiten).

**Grenze:** Kehrt eine schon gestaltete Detailansicht in den Leerzustand
zurück (Auswahl aufgehoben), bleiben Titel und Beschreibung die zuletzt
bestimmten; ihre Lage wird weiter je Durchlauf vermessen.

### Statistiken *(6.7.4.0, `ui/statistics.lua`)*

Beta-Test: das Statistikfenster im selben System. **Gemessen**
(`/wcui fenster`): `StatisticsFrame`, Zeilen unter
`StatisticsFrame.ScrollBox.ScrollTarget` mit
`.Content.BackgroundHighlight` (`charactercreate-customize-dropdown-
linemouseover-*`, dieselben Bilder wie im Ruf), Gruppenzeilen („Vermögen“)
mit `.ToggleCollapseButton` (`Campaign_HeaderIcon_Open`), Bildlauf
`minimal-scrollbar-*`. Die Kategorie „Charakter“ ist eine Kopfzeile des
Spiels; ohne Stil des Bereichs stand sie bis 6.7.3.0 mittig mit Lichthof
(`W.Header`), jetzt links als Abschnitt (`W.ListHeader`, Band).

Das vierte Register und das erste **ohne Detailansicht** (`listOnly`):
keine Suche nach einer, keine Auswahl, `/wcui fenster` sagt „nur die
Liste“. Stil `S.CHARACTER_INFO` – ein Reiter des Charakterfensters wie
Ruf, Fertigkeiten, PvP und Abzeichen, also Klassenfarbe, nicht das Gold
(`S.CALM`), das hier früher vorgesehen war. **Unverändert:** Werte
(„--“, Zahlen), Namen, Einrückung, die roten Knöpfe der Gruppen (ein
Grauton wie beim Minus der Kopfzeilen träfe auch das Questlog, das
dieselbe Grafik nutzt – nicht ohne Messung dort). Gruppenzeilen sind
Zeilen wie alle anderen (Haarlinie, Maus); eine eigene Stufe als
Unterabschnitt hätte eine neue Regel gebraucht, die nichts Gemessenes
trägt.

### Berufe *(6.7.5.0, `ui/professions.lua`)*

Beta-Test: das Berufsfenster im selben System („Einheit“). **Gemessen**
(`/wcui fenster` auf der Seite der Kochkunst):

| Teil | Weg | Bilder |
|---|---|---|
| Seite | `ProfessionsFrame.CraftingPage` | `Profession-Background-Template2` → weg |
| Rezeptliste | `.RecipeList` | `Professions-background-summarylist` → weg |
| Zeilen | `.RecipeList.ScrollBox.ScrollTarget.<Zeile>` | `Professions_Recipe_Hover` / `_Active` → in Gold getönt |
| Bildlauf | `.RecipeList.ScrollBar` | `minimal-scrollbar-*` |
| Rezept | `.CraftingPage.SchematicForm` | `Profession-background-card-Cooking` → weg (Bild hinter Text) |
| Rang | `.CraftingPage.RankBar` | `Professions-skillbar-frame/-bg`, `Skillbar_Fill_Flipbook_Cooking` – unverändert |
| Kategorien | Kopfzeilen des Spiels | bis 6.7.4.0 mittig (`W.Header`), jetzt Abschnitte |

**Gold.** Berufe gehören nicht zur Klasse – der Fall, für den
`frameAccent` seit 6.7.0.0 bereitliegt. `S.SCOPES.ProfessionsFrame =
S.CALM` gilt für das ganze Fenster (Übersicht und Rezeptseite), und
`S.CALM` hat seit 6.7.5.0 Band und 14 pt wie `S.CHARACTER_INFO`: dieselbe
Sprache, nur der Akzent ist ein anderer. Damit im Fenster keine
Klassenfarbe neben dem Gold steht, trägt auch der **gewählte
Seitenreiter** den Akzent seines Fensters (`SkinSideTabs`, sonst
weiterhin die Klassenfarbe).

**Register außerhalb des Charakterfensters.** `cfg.host = "ProfessionsFrame"`
trägt das Register in `W.HOSTED.ProfessionsFrame` ein statt in `W.TABS`;
`W.Inner` ruft es, wenn das Berufsfenster offen ist, `/wcui fenster`
darüber fragt es („Berufe, …“). Neu dafür: Pfade in `listKeys`/
`scrollBarKeys` (`RecipeList.ScrollBox`, ohne Anlage aufgelöst),
`highlightAtlas` (`^Professions_Recipe_`), `titleColor = false` (der
Rezeptname behält seine Farbe – er kann die Qualität tragen).

**Karte:** Titel `OutputText` (Schlüssel aus dem Quelltext des Spiels,
ungemessen; sonst oberste Zeile), Beschreibung `Description` oder die
längste Zeile, darunter `tail`: Reagenzien, „Benötigt: …“ als
abgesetzter Bereich; `compact`. Nichts wird bewegt – Reagenzien sind
Knöpfe, damit ist das Rücken ohnehin gesperrt. **Unverändert:**
Rangbalken, Ergebnissymbol samt Qualitätsrahmen, Plätze der Reagenzien,
Filter, Suchfeld, Knöpfe, Seitenreiter (außer der Farbe des Rahmens).

**Die Übersicht** (erster Seitenreiter) seit 6.7.6.0: `ui/profbook.lua`,
siehe unten.

### Berufsübersicht *(6.7.6.0, `ui/profbook.lua`)*

Beta-Test: die Rezeptseite „prinzipiell okay“, die Übersicht angleichen.
**Gemessen** (`/wcui fenster`): `ProfessionsFrame.BookPage.
ProfessionsContentFrame` mit `PrimaryProfession1/2` (braune Fläche
`Profession-overview-Card`) und `SecondaryProfession1..3` (Bilder
`Profession-overview-card-generic-Cooking/Fishing/FirstAid`), je Karte
`.StatusBar` (`Skillbar_Fill_Flipbook_<Beruf>`, `Skillbar_Flare_<Beruf>`),
`.SpellButton1/2`, `.UnlearnButton` (`Profession-button-red-crossmark`).

Kein Register (keine Liste, keine Detailansicht), aber dieselben
Bausteine, in `W.HOSTED.ProfessionsFrame` neben der Rezeptseite, Stil
`S.CALM`:

| Teil | 6.7.6.0 |
|---|---|
| Fläche der Karte | braune Fläche und Bild weg (`W.HIDE_ATLAS`, bis 6.7.5.0 waren die Bilder nur gedämpft – sie standen hinter Text); `surfaceRaised` 2 px innerhalb, weicher Schatten, Lichtkante oben; `NineSlice`/`Border`/`Bg`/`Background` der Karte weg, falls vorhanden |
| Titel | oberste Zeile der Karte (ungemessen), hell, 14 pt; `GetJustifyH` „LEFT“ → Raute und Linie hinter dem Text (wie die Kopfzeilen im Ruf), „CENTER“ → Linie mit Raute 7 px darunter |
| Balken | `S.BarFinish` am `.StatusBar`: Tiefe an der Füllung; Farbe, Glanz, Text bleiben |
| Grund | Vignette 35 % / 48 px und neutrales Licht wie im Register, auf dem Berufsfenster, aus mit der Seite |

**Unverändert:** Symbole, Namen und Rang, Zauberknöpfe, Knopf zum
Verlernen, Texte und Lage aller Teile.

### Zauberbuch *(6.7.7.0, `ui/spellbook.lua`)*

Beta-Test: das Zauberbuch nach dem neuen Prinzip. **Gemessen**
(`/wcui fenster`): `PlayerSpellsFrame.SpellBookFrame` mit
`.PagedSpellsFrame.View1.<Eintrag>.Button` (Zauber; Schein
`talents-sheen-node`, `spellbook-item-unassigned-glow`),
`.PagingControls`, `.CategoryTabSystem`, `.SettingsDropdown`. Kein großes
Bild des Spiels – der braune Verlauf über der halben Seite war **unser**
Schein der Klasse (`W.AddGlow`, Krieger: 0.78/0.61/0.43, 40 %).

Kein Register (Raster, keine Detailansicht), aber dieselben Bausteine,
in `W.HOSTED.PlayerSpellsFrame`, Stil `S.CHARACTER_INFO` – **nur** für
`PlayerSpellsFrame.SpellBookFrame`, die Talente daneben bleiben, wie sie
sind:

- **Grund:** Vignette 35 % / 48 px, neutrales Licht; angehobene Fläche
  (`surfaceRaised`, Schatten, Lichtkante) unter `PagedSpellsFrame`.
- **Schein der Klasse aus**, solange das Zauberbuch offen ist
  (`SB.GlowOff` → `W.HoldGlow`), zurück bei den Talenten.
- **Überschrift** („Allgemein“, Name eines Talentbaums): ein Eintrag in
  `View1`/`View2` **ohne** `.Button` (die Zauber haben alle einen;
  ungemessen, der Bericht nennt, was gefunden wurde). Raute und Linie in
  der Klassenfarbe hinter dem Text, Linie bis 16 px vor den Rand der
  Seite; Schrift, Größe und Lage bleiben (Seitentitel). Neu gelegt, wenn
  Text oder Breite sich ändern – die Seite verwendet ihre Einträge beim
  Blättern weiter.

**6.7.8.0, Beta-Test „ein bisschen Klassenfarbe“:** Licht von oben in
der Klassenfarbe (`GC.classLight`, 7 %, 180 px) statt des neutralen
`atmosLight`, Kante über der Fläche in der Klassenfarbe (50 %) wie oben an
den Detailkarten. Der große Schein (40 %, 260 px) bleibt aus. **Fehler
behoben:** die Linie hinter der Überschrift war rechts an `"RIGHT"` der
Seite verankert – der **halben Höhe** der Seite, nicht der Zeile; im Spiel
wurde sie nicht gezeichnet (nur die Raute stand da). Jetzt nur links
verankert, Breite gerechnet. Derselbe Fehler in `ui/profbook.lua` (Titel
links, an der Karte). Regel: eine Linie hinter Text nie an einen Rahmen
anderer Höhe hängen – nur an Teile derselben Zeile (so macht es
`W.ListHeader`) oder links verankert mit gerechneter Breite.

**`W.HoldGlow`** (allgemein): Fenster in Gold (`S.CALM`) tragen den Schein
der Klasse nie – im Berufsfenster lag er seit 6.7.5.0 über dem Gold, ein
zweiter Akzent in einem Bereich, den der Test nicht sah (er entsteht in
`W.Skin`, nicht über `S.Gradient`). Versteckt statt durchsichtig und je
Durchlauf gehalten, wie im Charakterfenster.

**Unverändert:** Zauber (Symbol mit eckigem Rand seit 6.4.1.2, Name,
Untertitel), Schein an nicht zugewiesenen Zaubern, Reiter, Suche,
Blättern, Talente.

### Gilde & Communitys *(6.7.8.0, `ui/community.lua`)*

Beta-Test: „Gilde und Community fertig machen“. **Gemessen**
(`/wcui fenster`, Chat der Gilde): `CommunitiesFrame` mit `.MemberList`
(`.InsetFrame.NineSlice`: `!UI-Frame-InnerRightTile`/`-InnerLeftTile`,
Zeilen mit Bild 131128, Kronen 132061), `.ChatEditBox`, `.StreamDropdown`,
`.ChatTab`, `.PortraitOverlay`, `.VoiceChatHeadset`; die Liste links
`CommunitiesFrameCommunitiesList` (Einträge mit
`communities-guildbanner-*`).

**Gold** (`S.SCOPES.CommunitiesFrame = S.CALM`): die Gilde gehört nicht
zur Klasse. Damit folgen der gewählte Seitenreiter (`SkinSideTabs`, seit
6.7.5.0) und – neu – der gewählte Eintrag links (`W.NavEntry` bekommt den
Stil aus `HideByAtlas`) dem Gold; der Schein der Klasse oben ist aus
(`W.HoldGlow`, Fenster in Gold).

Kein Register, drei Spalten; je Spalte die angehobene Fläche des Registers
(`surfaceRaised`, Schatten, Kante in Gold 45 %), 6 px über die Spalte
hinaus, auf dem Fenster unter allem: Liste (`.CommunitiesList`, sonst der
globale Name), Chat (`.Chat`, `.ChatFrame`, `.MessageFrame` – ungemessen;
bis zur Unterkante von `.ChatEditBox`), Mitglieder (`.MemberList`).
Angelegt, sobald die Spalte da ist, gezeigt nur mit ihr (andere Ansicht:
Mitglieder groß, Gildeninfo). Vignette 35 %/48 px, neutrales Licht.

**Unverändert:** Namen in Chat und Mitgliederliste in den Farben des
Spiels (Klasse, Kanal), Zeiten, Wappen, Kronen, „8/22 online“, Kanalwahl,
Knöpfe, und innen die Mitgliederliste (`W.INSET_KEEP`, 6.6.3.3: „im
Normalzustand“) – ihre Fläche liegt darunter, zu sehen sind Schatten und
Kante.

### Spielmenü und Dialoge *(6.7.9.0, `ui/gamemenu.lua`, `W.SkinPopup`)*

Beta-Test: „die beiden Fenster auch noch machen“. **Gemessen**
(`/wcui fenster`): `GameMenuFrame` und `StaticPopup1` zeigen nur noch
unsere Flächen („FileData ID 0“) – Rahmen, rote Knöpfe und Grund sind
seit 6.6.3.3/6.6.3.4 weg. Übrig war der Schein in der Klassenfarbe (im
Menü 260 px oben, im Dialog über die ganze Fläche) – die alte Sprache.

Beide gehören nicht zur Klasse: **Gold** (`S.CALM`).

- **Spielmenü** (`W.HOSTED.GameMenuFrame`): Schein der Klasse aus
  (`W.HoldGlow`), neutrales Licht (110 px), oben eine Kante in Gold (50 %);
  unter dem Titel eine Linie mit Raute (`S.Ornament`, 6 px darunter); in
  jeder Lücke > 6 px zwischen zwei sichtbaren Knöpfen eine Haarlinie
  (`GC.hairline`, doppelte Deckkraft) – gemessen an der Lage, nicht an
  Namen: das Menü baut seine Knöpfe selbst, und ein Addon kann einen
  dazulegen. Höchstens sechs Linien, vorab angelegt; die überzähligen aus.
- **Dialoge** (`W.SkinPopup`): statt des Scheins neutrales Licht (60 px)
  und Kante in Gold; Stil `S.CALM` am Dialog.

**Unverändert:** Knöpfe (Text, Reihenfolge, Lage, Skript), Texte der
Dialoge, das Warnzeichen, der Countdown. Die gelbe Schrift der
Dialogknöpfe („Jetzt verlassen“) ist die des Spiels und bleibt – anders
als die weiße im Menü, aber umfärben hieße, eine Schrift des Spiels zu
überschreiben, die bei jedem Dialog neu gesetzt wird.

### Karte & Questlog *(6.7.9.0, `ui/questlog.lua`)*

Beta-Test: „mit der Map bitte auch. Unbedingt beibehalten werden muss
das Weichzeichnen um die Karte herum.“ **Gemessen** (`/wcui fenster`):
`WorldMapFrame`, `QuestScrollFrame` (`.Contents` mit Zeilen `.Display`/
`.Checkbox`, Kopfzeilen mit `.CollapseButton` `common-button-list-minus/
-plus`; `.ScrollBar`, `.BorderFrame` mit `QuestLog-Frame-Gradient-bottom`,
`.SettingsDropdown`), „Weicher Rand (Karte): Maske an 27 Bildern“.

**Die Karte bleibt unberührt:** keine Fläche, kein Licht, keine Vignette
über oder unter ihr; `W.SoftMap` (Maske an den Kartenbildern, 6.6.3.2)
unverändert. Der Test hält das fest: nach Questlog und `W.SkinMap` hat die
Kachel der Karte weiter genau eine Maske, und auf dem Ausschnitt entsteht
kein neues Bild.

**Gold** (`S.SCOPES.WorldMapFrame = S.CALM`): `W.SkinMap` gibt den Stil
an `HideByAtlas` weiter (bis 6.7.8.0 ohne) – die Zonen des Questlogs
werden `W.ListHeader`-Abschnitte (Text links, Raute, Linie, Band, Gold)
statt mittig mit Lichthof. Die Karte läuft nicht durch die allgemeine
Schleife von `W.Inner`; der Zweig für `W.MAP` ruft jetzt auch
`W.HOSTED.WorldMapFrame` und `W.HoldGlow` (Schein der Klasse aus).

**Questlog-Spalte:** angehobene Fläche (`surfaceRaised`) unter
`QuestScrollFrame` bis zur Bildlaufleiste, Schatten nur 8 px (links liegt
die Karte mit ihrem weichen Rand), Kante in Gold; auf dem Fenster, nicht
auf der Karte; aus, wenn die Seitenleiste zu ist.

**Unverändert:** Farben der Quests (Schwierigkeit), Ziele, Symbole,
Häkchen zum Verfolgen, Suche, Zähler, Filter, Markierungen auf der Karte.

### Suche nach Gruppe *(6.8.0.0, `ui/lfg.lua`)*

Beta-Test: „das Fenster bitte auch noch“. **Gemessen** (`/wcui fenster`):
`LFGParentFrame` mit `WhoListingTab`, `ListingTab`, `BrowsingTab`
(Seitenreiter), `LFGListingFrameGroupRoleButtonsRole` (Symbol 337499,
Ring 340817), `…RoleDropdown`, `LFGListingFrameNewPlayerFriendlyButton`.
Kein Bild des Spiels mehr übrig – der braune Verlauf oben war der Schein
der Klasse.

**Gold** (`S.CALM`, für `LFGParentFrame` und `PVEFrame`): Schein der Klasse
aus (`W.HoldGlow`), neutrales Licht (120 px), gewählter Seitenreiter in
Gold. **Innenflächen:** welcher Rahmen der dunkle Bereich („Nur der
Gruppenführer kann die Gruppe anmelden.“) ist, zeigte die Messung nicht.
Er ist eine Innenfläche, die `W.SkinInsets` seit 6.6.2.2 gestaltet und in
`W.Insets` merkt – das Modul nimmt jede davon, die unter dem Fenster hängt
(`InTree`), und gibt ihr Schatten und Kante in Gold wie den Flächen der
Register; aus mit ihr. `/wcui fenster`: „Suche nach Gruppe (Stil ruhig):
n Innenflächen …“ – bei 0 ist es ein anderer Rahmen.

**Unverändert:** Rollensymbole samt Ringen, Fahne, Auswahl der Rolle,
Texte (gelb, wie das Spiel sie setzt), Knöpfe.

**6.8.0.1, gemessen auf den Reitern „Gruppen durchsuchen“
(`LFGBrowseFrame`) und „Spielersuche“ (`LFGWhoListFrame`):** Marmor (Bild
374155), Stein (`groupfinder-Stat-StoneBG`), zwei Goldlinien
(`groupfinder-ScrollLine`); „0 Innenflächen“ auf der Spielersuche. Beide
in `W.OWN_BG_PATHS` (eigene Bilder weg, `SkinInset`) – danach findet das
Modul sie über `W.Insets`. Die zwei Atlanten auch in `W.HIDE_ATLAS`, falls
sie in einem Unterrahmen liegen.

Fassung 6.8.0.0 statt 6.7.10.0: ob die Companion oder ein anderes Werkzeug
Fassungen als Text vergleicht, ist ungeprüft – „6.7.10.0“ käme dort vor
„6.7.9.0“.

### Nächste Fenster

Vorgesehen: Berufsübersicht (nach Messung), Gilde (mittlere Atmosphäre), Talente
(Klassenfarbe). Migrieren heißt: Name in
`S.SCOPES`, ein Modul nach dem Muster von `ui/reputation.lua` nur dort,
wo das Fenster mehr braucht als die Bausteine.
