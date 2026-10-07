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

## Freiwillig – wieder seit 6.9.0.0 (`UIKit.OPT_IN`)

Gebaut ist sie **freiwillig**: Hauptschalter, Frage beim Einloggen
(`ui/welcome.lua`), und solange der Schalter aus ist, fasst WeintCodex
keinen Blizzard-Rahmen an.

Von 6.0.0.3 bis 6.8.1.0 war sie **für alle an** (`K.OPT_IN = false`):
der Forever-Beta-Client speicherte die SavedVariables nicht, und eine Wahl,
die nach jedem Neuladen vergessen ist, ist keine. Seit der Client wieder
speichert (Beta-Test nach 6.8.1.0), steht `K.OPT_IN = true`:

| Stelle | mit `OPT_IN = true` (jetzt) | mit `OPT_IN = false` |
|---|---|---|
| `UIKit.UIEnabled()` | liest den gespeicherten Hauptschalter | immer `true` |
| Frage beim Einloggen | nach der Einführung, einmal je Konto | kommt nie |
| Hauptschalter in `/wcui` | Schalter oben rechts und auf „Allgemein“ | Hinweis „derzeit für alle an“ |
| Einstellungen → Oberfläche | Schalter | derselbe Hinweis |
| Einführung, Kapitel „Oberfläche & Komfort“ | „ganz freiwillig“, eigenes Layout | „derzeit für alle eingeschaltet“ |

Alle Stellen fragen `K.OPT_IN` zur Laufzeit; `load_test.lua` prüft beide
Zustände. Der Prüflauf spielt einen Spieler, der „Ja“ gesagt hat
(`ui.enabled = true` vor `PLAYER_LOGIN`), und prüft den Weg ohne
Oberfläche in einem eigenen Abschnitt.

**Wer die Oberfläche vor 6.9.0.0 hatte**, hat nie geantwortet (gespeichert
wurde nichts): er wird einmal gefragt, und bis dahin ist sie in dieser
Sitzung aus – das Layout „WeintCodex“ des Bearbeitungsmodus ist dann noch
aktiv. „Ja“ lädt neu, „Nein“ gibt ihm sein eigenes Layout zurück (siehe
*Dein Profil bleibt deins*).

## Dein Profil bleibt deins *(6.9.0.0, `ui/profile.lua`)*

Beta-Test: „Wenn man die WeintCodexUI nutzen will, dann muss ein neues
Profil angelegt werden, damit nichts gelöscht oder überschrieben wird!“

Außerhalb ihres eigenen Speichers fasst die Oberfläche genau zwei Dinge
des Spiels an:

1. **Das Layout des Bearbeitungsmodus.** Die Einrichtung legt ein
   eigenes Layout „WeintCodex“ an (Grundlage: die Vorlage des Spiels) und
   schreibt nie in eines des Spielers. Neu: **vorher** merkt sich
   `PF.Remember()` in `ui.before`, welches Layout aktiv war – nur einmal,
   bis es zurückgegeben ist (ein zweites Einschalten darf das Original
   nicht mit „WeintCodex“ überschreiben), und nur, wenn der Client
   antwortet (ein leeres „vorher“ versperrte sonst das echte).
2. **Spieleinstellungen (CVars).** Jede Änderung läuft über
   `PF.SetCVar(name, wert, besitzer)` und merkt den **allerersten** Wert
   in `ui.cvars`. Besitzer ist `"ui"` (die Einrichtung) oder ein Modul
   (die Schadensanzeige blendet die des Spiels aus). Läuft der Besitzer
   nicht mehr, gibt `PF.Sweep()` den alten Wert zurück – beim Anmelden,
   nach jedem Modulschalter und beim Ausschalten –, **aber nur, wenn noch
   unser Wert steht**. Hat der Spieler die Einstellung inzwischen selbst
   geändert, gilt seine (`PF.Release`).

**Ausschalten** (Hauptschalter, „Nein“ bei der Frage): `PF.Leave()` setzt
das gemerkte Layout wieder aktiv – nur, wenn gerade „WeintCodex“ aktiv
ist; wer selbst umgestellt hat, behält seine Wahl. Ist nichts gemerkt
(Oberfläche vor 6.9.0.0) oder das gemerkte gelöscht, nimmt es das erste
eigene Layout, sonst die erste Vorlage – und sagt im Chat, dass es ein
Ersatz ist. Das Layout „WeintCodex“ bleibt stehen; wer wieder einschaltet,
muss nicht neu einrichten (`PF.Enter()` setzt es aktiv). Im Kampf wartet
der Wechsel bis nach dem Kampf.

**Nicht mehr:** die Chatfenster zurücksetzen (`FCF_ResetChatWindows`,
6.6.1.3 bis 6.8.1.0). Reiter und Kanäle speichert das Spiel nur einmal
je Charakter – ein zweites Profil davon gibt es nicht, zurücksetzen hieß
löschen. Wo der Chat steht, stellt weiter das Layout.

Bewusst **nicht** über das Profil: die Spieleinstellungen, die die Seiten
„Namensplaketten“ und „Abklingzeitmanager“ als Schalter zeigen. Das sind
die Schalter des Spiels selbst, nur an anderer Stelle – wie im Spielmenü
gelten sie auch ohne Oberfläche.

## Zwei Arten von Modulen

| Gruppe | Module | Hängt am Hauptschalter? | Umschalten |
|---|---|---|---|
| `ui` | Namensplaketten, Einheitenrahmen, Gruppenrahmen, Aktionsleisten, Minikarte, Chat, Taschen, Questliste; Tooltip und Fenster des Spiels (`general`) | **ja** | nach dem Neuladen |
| `qol` | Questpfeil, Schadensanzeige, Erinnerungen, Komfort (mit Automark, Klickzauber samt Entfluchen, Makro-Helfer) | **nein** | sofort; Schadensanzeige und Erinnerungen nach dem Neuladen (`reload = true`) |

Die Regel seit 6.9.0.0: **ersetzt oder kleidet** ein Teil etwas des
Spiels, ist es Oberfläche; **fügt** es etwas hinzu, das dem Spiel fehlt,
ist es Komfort. Wer die Oberfläche nicht will, soll Schadensanzeige,
Questpfeil, Klickzauber und das automatische Reparieren trotzdem haben
können – das Komplettpaket gibt es mit der Oberfläche.

`defaultEnabled = "ui"` (Schadensanzeige, Erinnerungen): von Haus aus an,
wenn die Oberfläche an ist, sonst aus. Wer „Nein“ zur Oberfläche sagt,
bekommt kein Fenster, das er nicht gewählt hat – und die Anzeige des
Spiels wird nicht ausgeblendet. Eine ausdrückliche Wahl gilt in beiden
Fällen.

Klickzauber und Makro-Helfer sind seit 6.9.0.0 **Seiten im Komfort**; ihre
Einstellungen bleiben, wo sie immer lagen (Seiteneintrag `store =
"groupframes"` bzw. `"actionbars"`, `NewBuilder(def.store or key)`), nichts
Gespeichertes geht beim Umzug verloren. Ohne die Gruppenrahmen von
WeintCodex gelten die Klickzauber auf den Rahmen des Spiels
(`CC.GameFrames()`; neu angewendet bei `GROUP_ROSTER_UPDATE`), mit eigenen
Kacheln nicht – die des Spiels sind dann versteckt. Ist der Komfort aus,
gilt keine Belegung.

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
| `ui/profile.lua` | *(6.9.0.0)* Layout des Bearbeitungsmodus und Spieleinstellungen von vorher merken, beim Ausschalten zurückgeben |
| `ui/layout.lua` | **wo alles steht**: die Standardpositionen aller beweglichen Rahmen (`UIKit.LAYOUT`, `UIKit.Layout`) |
| `ui/presence.lua` | **Ruhe, Bereit, Kampf**: Deckkraft außerhalb des Kampfes |
| `ui/testmode.lua` | **Testmodus**: Beispieldaten für Ziel, Fokus, Gruppe, Zauberbalken, Schadensanzeige |
| `ui/editmode.lua` | **Gestaltungsmodus**: Leiste, Raster, Einrasten, Pfeiltasten, Doppelklick zu den Einstellungen; Brücke zum Bearbeitungsmodus des Spiels (6.9.0.5) |
| `ui/castbar.lua` | **ein** Zauberbalken für Plaketten und Einheitenrahmen |
| `ui/nameplates.lua` | Gegnerplaketten |
| `ui/unitframes.lua` | Spieler, Ziel, Ziel des Ziels, Fokus, Begleiter; Porträt als 3D-Modell oder Bild, bei Spieler und Ziel auch animiert im Balken (6.20.0.0) |
| `ui/setup.lua` | **Einrichtung beim ersten Mal**: stellt alles – Layout „WeintCodex“ im Bearbeitungsmodus mit jedem Rahmen des Spiels an festem Platz (`K.GAME_LAYOUT`), Chatfenster, einige Spieleinstellungen, eigene Rahmen –, danach neu laden (`/wcui einrichten`, prüfen: `/wcui einrichten pruefen`) |
| `ui/gamegroup.lua` | **Gruppenrahmen des Spiels im WeintCodex-Stil** (Standard seit 6.6.0.9): nur sie zeigen HoTs, Buffs, Schilde und Debuffs im Kampf |
| `ui/clickcast.lua` | **Klickzauber**: Maustaste + Zusatztaste wirkt einen Zauber auf die Einheit des Rahmens (Reiter der Gruppenrahmen) |
| `ui/questarrow.lua` | Questpfeil |
| `ui/comfort.lua` | Komfortfunktionen |
| `ui/automark.lua` | Automark (6.8.1.0): Tank und Heiler beim Betreten einer Instanz markieren – seit 6.9.0.2 über einen Knopf (Markieren ist geschützt) – Seite im Komfort |
| `ui/macros.lua` | Makro-Helfer (6.8.1.0): was, auf wen, welcher Zauber → Makrotext mit Erklärung, anlegen/ersetzen/aufnehmen – Seite der Aktionsleisten |
| `ui/dispel.lua` | Entfluchen auf Klick (6.8.1.0): Zauber der Klasse gegen Flüche, Gifte, Krankheiten, Magie auf Zusatztaste + Links/Rechts der Klickzauber |
| `ui/options.lua` | das Einstellungsfenster und das Modul „Allgemein“ |

Neue Bausteine in `core/ui.lua`: `CreateDropdown` (Auswahlliste, eine
Liste für alle Felder) und `CreateColorSwatch` (Farbfeld, öffnet den
Farbwähler des Spiels).

## Speicher

Ausschließlich `WeintCodex_SavedData.ui` – keine neue SavedVariable.

```
ui = {
  enabled   = true|false,          -- Hauptschalter (ganzes Konto)
  asked     = true,                -- Frage beim Einloggen beantwortet
  profiles  = {                    -- seit 6.12.0.0, ui/profiles.lua
    [name] = {
      modules   = { [modul] = { enabled = , <nur Abweichungen vom Standard> } },
      positions = { [rahmen] = { point, relPoint, x, y } },
    },
  },
  profileOf = { ["Name-Realm"] = name },  -- ohne Eintrag: "Standard"
  before    = { layout = { name = } | { preset = n } | nil },  -- 6.9.0.0, ui/profile.lua
  cvars     = { [name] = { orig, set, owner } },               -- 6.9.0.0, ui/profile.lua
}
```

**Profile (seit 6.12.0.0, Beta-Test: „ein großer Vorteil, wenn man
mehrere Charaktere hat“).** Einstellungen der Module und Plätze der
Rahmen stehen je Profil; jeder Charakter nutzt eins, mehrere können eins
teilen. Beim ersten Laden zieht, was bis 6.11.0.4 unter `ui.modules`/
`ui.positions` für alle galt, nach „Standard“. Regeln:

- `UIKit.Profile()` liefert das Profil der **Sitzung** – beim ersten
  Zugriff gewählt (`ui.profileOf[CharKey]`, sonst „Standard“), danach
  fest bis zum Neuladen. Laufende Module lesen nie mitten im Spiel aus
  einem anderen. Wählen, Kopie anlegen, Übernehmen und Zurücksetzen des
  laufenden Profils verlangen ein Neuladen (`K.MarkReload`).
- „Standard“ gibt es immer (`Root` legt es notfalls an), es lässt sich
  weder umbenennen noch löschen; wessen Profil gelöscht wird, landet dort.
  Gelöscht wird nur, was weder läuft noch gewählt ist.
- Nicht im Profil (ganzes Konto): Hauptschalter, Willkommen, `before`/
  `cvars` (`ui/profile.lua`), Minikartensymbol (`launcher`), verfolgte
  Quests (`questWatch`), Fensterplätze (`windowPos`), `migrated`.
- Wer direkt in den Speicher greift, nimmt `UIKit.Profile().modules`/
  `.positions` – nie `Root().modules` (gibt es nicht mehr).
- Seite: Allgemein → Profile, auch `/wcui profil`. Wählen, „Als Kopie
  anlegen“ (Name des Charakters), Name ändern (bei jeder Eingabe; leer
  oder vergeben ändert nichts), Einstellungen übernehmen von, Profil
  zurücksetzen, Profil löschen (beide mit Rückfrage), dazu wer es nutzt
  und ob ein Neuladen aussteht.
- **Frage beim Einloggen (seit 6.12.0.1):** einmal je Charakter ohne
  eigene Wahl und ohne Antwort (`ui.profileAsked["Name-Realm"]`), nur mit
  Oberfläche, nie vor oder neben dem Willkommen, nicht neben dem Hinweis
  auf ein Update, nach `/reload` nur, wenn der Client speichert, nie im
  Kampf (`PR.ShouldAsk`/`PR.MaybeAsk`). Antworten: eigenes Profil anlegen
  (dann „Jetzt neu laden“), Profil wählen (nur mit Auswahl), „Standard“
  behalten; „×“/Esc heißt später, bis zum nächsten Einloggen.
- Rückweg: Eine Version vor 6.12.0.0 findet `ui.modules` nicht mehr und
  startet mit den Voreinstellungen (die Daten bleiben unter
  `profiles.Standard`).

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
| Aktionsleisten (`ui/actionbars.lua`) | die Knöpfe des Spiels umgestaltet: flach, Rand, Schrift, rote Schicht außer Reichweite, Greifen weg; seit 6.0.0.5 Mikromenü klein unten links, Taschenleiste unten rechts | **Keine eigenen Leisten**: Umblättern bei Haltung/Gestalt/Fahrzeug braucht Secure Snippets. Lage und Größe der Leisten: Bearbeitungsmodus des Spiels. Reichweite als eigene Schicht, damit die Färbung des Spiels (keine Kraft, nicht benutzbar) erhalten bleibt. Mikromenü und Taschenleiste werden nach jedem Anordnen des Bearbeitungsmodus (`ApplySystemAnchor`, `ExitEditMode`) und nie im Kampf gesetzt – seit 6.9.1.0 an ihren Platz aus dem **Gestaltungsmodus** (`hud_micro`, `hud_bags`, Standard in `K.LAYOUT`); bis dahin fest unten links/rechts, verschieben ging nicht (Beta-Test). Ob das Setzen den Bearbeitungsmodus auf Forever unberührt lässt, ist **ungeprüft**; „Wie im Spiel“ schaltet es ab. **Gemessen (04.10.2026, Client 1.60.1, Build 70205, `/wcui prüfen`):** `MicroMenuContainer` und `MicroMenu` sind nicht geschützt (`IsProtected` false) – nicht setzen im Kampf ist Vorsicht, keine Pflicht. |
| Minikarte (`ui/minimap.lua`) | eckig, Rand, Mausrad-Zoom; Koordinaten oben links, Uhr oben rechts, Gebiet unten auf einem Streifen; Knöpfe des Spiels (Verfolgung, Kalender, Post, Schwierigkeit) in einer Spalte links | Knopfnamen wechseln zwischen den Clients – was fehlt, fällt heraus. Die Spalte wird nach `MinimapCluster:Layout` neu gesetzt. | Lage: Bearbeitungsmodus. Die Kompass-*Textur* wird versteckt, nie ihr Elternrahmen (Kampfhilfen lesen daraus die Blickrichtung). `GetMinimapShape` meldet `SQUARE` für Addon-Knöpfe. |
| Chat (`ui/chat.lua`) | Schrift, Hintergrund über Reiter und Text, flache Reiter (aktiver hell mit Strich), Eingabezeile, Knöpfe des Spiels in einer Spalte links (oder weg) | **Keine veränderten Nachrichten** (Kanalnamen, Links, Zeitstempel): Nachrichten können im Kampf geheim sein, ein `gsub` darauf ist ein Fehler, und ein Fehler in `AddMessage` verschluckt die Nachricht. |
| Taschen (`ui/bags.lua`) | alle Taschen in einem Raster, Suche, Sortieren, Gold, Gegenstandsstufe, Qualitätsrand | Knöpfe sind `ContainerFrameItemButtonTemplate` (Benutzen/Verkaufen macht das Spiel); **nie im Kampf angelegt** (sonst „tainted“), deshalb 180 auf Vorrat beim Anmelden. Öffnen folgt den Taschen des Spiels (Haken an `Show`/`Hide`, nicht an `OnShow` – die feuern im versteckten Elternrahmen nie). Die Bank bleibt die des Spiels. |
| Schadensanzeige (`ui/damagemeter.lua`) | bis zu vier Fenster, je mit eigener Messart (Schaden, Heilung, erlittener Schaden, Unterbrechungen, Bannungen, Tode; seit 6.9.0.8 auch pro Sekunde, Absorption, vermeidbarer Schaden, Schaden an Gegnern und **Bedrohung**) und eigenem Zeitraum; Kopfzeile mit Kampfdauer und Symbolknöpfen (seit 6.9.0.8 mit „In den Chat melden“) | Addons bekommen ab 12.0 kein Kampflog: die Zahlen kommen aus `C_DamageMeter` (die Messung des Spiels), Blizzards Fenster geht aus (`damageMeterEnabled = 0`). Fehlt die Messung, steht das im Fenster – keine Nullen. Zahlen über `CreateAbbreviateConfig` (K/M/B, darunter ganze Zahlen): ohne sie gibt `AbbreviateNumbers` Werte unter 1000 ungerundet heraus („16.826086956522“, 6.0.0.4). Fenster flach gespeichert (`w1mode` …), weil `UIKit.Set` Tabellen nur eine Ebene tief vergleicht. |
| Questliste (`ui/questtracker.lua`) | eigene Fläche hinter der Zielverfolgung des Spiels, goldenes Banner weg, Höhe folgt dem Inhalt | Die Liste bleibt Blizzards (taint-empfindlich: Questgegenstände im Kampf); nur ein eigener Rahmen dahinter und durchsichtige Hintergrundtexturen. |
| Questpfeil (`ui/questarrow.lua`) | 3D-Pfeil aus 64 vorgerechneten Ansichten (`media/ui/arrow3d.tga`, erzeugt von `make_ui_media.py`), Farbe grün → gelb → rot nach Abweichung; plant seit 6.6.2.7 selbst (nächstes lohnendes Ziel aus dem Questlog, siehe *Questpfeil: Planen*); als Geist zur Leiche (`C_DeathInfo`); nach dem Abgeben die nächstgelegene Quest – seit 6.6.0.1 nur für den Pfeil (`QA.Chosen`), nicht mehr über `C_SuperTrack.SetSuperTrackedQuestID` (das berührte Blizzards Questverfolgung, im Kampf blockierte das Spiel dann `SetPassThroughButtons`); wählt der Spieler selbst, gilt seine Wahl –, wahlweise schon bei erfüllten Zielen | Kein Modell im Spiel, sondern Bilder: ein `PlayerModel` ließe sich nicht zuverlässig drehen und färben. Leiche und nächste Quest nur, wo das Spiel einen Ort nennt – sonst „Ort unbekannt“, nie 0 m. |

## Der Willkommens-Assistent (`ui/welcome.lua`, seit 6.9.0.0)

Beta-Test: „Ein Willkommensbildschirm, wo dem Nutzer alles erklärt wird,
ggf. mit kleinen Screenshots … Wenn man sich gegen das UI entscheidet,
soll dennoch eine Abfrage kommen, ob man die Komfortfunktionen haben
möchte. Ein komplettes An-die-Hand-Nehmen.“ Er ersetzt die frühere
Ja/Nein-Frage – einmal je Konto, **nach** der Einführung bzw. dem
Changelog-Popup (`Onboarding.OnClosed`, `Onboarding.IsShowing`), nie im
Kampf. Nach einem `/reload` nur, wenn die Speicherprüfung „ok“ meldet
(`WL.ReloadBlocks`, `WeintCodex.SaveHealth`, seit 6.9.0.1): Beta-Test zu 6.9.0.0 – wer
das Addon in der Sitzung aktualisiert und neu lädt, sah ihn bis dahin
nie (Sperre aus 6.0.0.1 gegen die Frageschleife eines Clients, der nicht
speicherte). Bei „verloren“ oder „unbekannt“ weiter erst beim nächsten
Einloggen – dort wäre die Schleife. Wieder zeigen: `/wcui willkommen` oder
der Knopf „Assistenten zeigen“ auf `/wcui` → Allgemein.

| Schritt | Inhalt |
|---|---|
| 1 Willkommen | was WeintCodex ist, dass zwei Pakete zur Wahl stehen, dass nichts vor „Übernehmen“ geschieht |
| 2 Oberfläche | Vorteile, „Dein Profil bleibt deins“, Galerie mit vier Bildern → „Ohne Oberfläche“ / „Oberfläche verwenden“ |
| 3 Anzeigen | Schadensanzeige, Erinnerungen, Questpfeil – Schalter mit Erklärung, Bild wechselt mit der Zeile |
| 4 Helfer | reparieren, Graues verkaufen, schneller plündern, Automark, Entfluchen (nur wenn `DP.SPELLS` die Klasse kennt); Hinweis auf Klickzauber und Makro-Helfer |
| 5 Bereit | Zusammenfassung → „Übernehmen“ → Bericht und „Jetzt neu laden“ |

**Mit Oberfläche** sind die Anzeigen vorgewählt (Komplettpaket), **ohne**
stehen sie, wie sie sind (`defaultEnabled = "ui"` → aus). Eine frühere
ausdrückliche Wahl gilt in beiden Fällen. Zurückblättern behält die Haken
(`WL.Decide` setzt das Paket nur, wenn sich die Antwort ändert).

**Nichts geschieht vor „Übernehmen“** (`WL.Apply`): erst dann
Hauptschalter (zuerst – davon hängt ab, was Standard ist), Module nur, wo
die Wahl vom Standard abweicht (das Paket bleibt Standard und folgt der
Oberfläche, wenn sie später ausgeht), Helfer, und mit Oberfläche
**gleich die Einrichtung** (`ES.Apply`, falls es das Layout noch nicht
gibt) – ein Neuladen statt zwei. „Später“, das Kreuz und Abbrechen
entscheiden nichts; „Später“ merkt sich nur `ui.later` (gelöscht beim
Einloggen), damit ein `/reload` nicht gleich wieder fragt – der Assistent
kommt beim nächsten Einloggen wieder.
ESC ist keine Antwort.

**Die Bilder** sind eigene Zeichnungen, keine Bildschirmfotos (Spielwelt
und Symbole gehören Blizzard): `.github/scripts/welcome/shots.html`, je
Szene ein Bild aus einem kopflosen Chromium, verkleinert auf 512×256,
BLP2/DXT1 ohne Mipmaps nach `media/welcome/` (rund 64 KB je Bild, acht
Bilder). Neu bauen: `python3 .github/scripts/make_welcome.py
[png-vorschau]`. Der Akzent der Bilder ist ein Beispiel (Magier) – die
Unterschrift sagt das.

**Platz:** `load_test.lua` schätzt jeden Schritt mit
`WeintCodex.EstimateLines` gegen die Spalte (`WL.COL_W`) und die Höhe
zwischen Kopf und Knopfzeile, und prüft, dass jedes Bild als Datei
existiert.

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

**Porträt im Balken** (6.20.0.0, Spieler und Ziel, `<einheit>_portrait =
"bar"`, Wunsch des Spielers „wie bei ElvUI“ – nur das Verhalten, kein Code):
ein zweites `PlayerModel` (`_barModel`) über der ganzen Fläche des
Lebensbalkens, Ebene Balken + 1 – über der Füllung, unter Heilung/Schild
(Klammer + 1) und Text (+ 3). Kamera wie beim Porträt (`SetPortraitZoom(1)`),
die Bewegung (Leerlauf) zeichnet der Client. Deckkraft
`<einheit>_barAlpha` (ab Werk 35 %, Feinheiten). Die Balken nehmen die
ganze Breite (kein Platz für ein Porträt). Außer Sichtweite oder ohne
Modelldatei nach 0,4 s: kein Kopf – ein Bild im Balken sähe aus wie ein
Fehler. Im Testmodus des Ziels: kein Kopf. **Ungemessen:** wie das Modell in
einem breiten, flachen Rahmen sitzt (Kopf mittig, Größe) und ob
`SetAlpha` am Modell auf Forever wirkt (zusätzlich `SetModelAlpha`).

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
  **Sein Zauberbalken nicht** (6.9.0.3, Beta-Test: beim Unterbrechen
  stand über dem Zielrahmen der Balken des Spiels in Rot): „Unterbrochen“
  blendet über eine Animation ein, und die setzt die Deckkraft an
  `SetAlpha` vorbei. `UF.HideGameCastBar` legt `TargetFrameSpellBar` und
  `FocusFrameSpellBar` (sonst `.spellbar` am Rahmen) für jeden ersetzten
  Rahmen still: keine Ereignisse, versteckt, Haken hinter `Show`/`SetShown`.
  **Nie umhängen** (6.9.0.4): `TargetSpellBarMixin:AdjustPosition` fragt
  den Elternrahmen (`ShouldAnchorSpellBarToAuraContainer`) – 6.9.0.3 hing
  ihn mit `K.HideBlizzard` an einen leeren Rahmen, und beim Anvisieren kam
  „TargetFrame.lua:829: attempt to call a nil value“. Allgemein:
  `K.HideBlizzard` nur für Rahmen, deren Kinder und Code nicht über
  `GetParent()` zurück zum Spiel greifen.
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
  nur, wo sie Vorschlag der Klasse ist, Begleiter bis 6.13.1.0 überall
  (seitdem wie die Waffe). Die Liste zeigte bis 6.13.1.0 alle Regeln,
  fremde blass mit „(hier aus)“ – seitdem nur die dieses Charakters.
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
  **Laune des Begleiters** (6.13.1.0, Beta-Test als Jäger: „sehen, wie
  glücklich mein Pet ist … am besten als Reminder“): `happy` erinnert,
  solange die Laune unter `below` liegt (3 „nicht glücklich“, Standard;
  2 „unglücklich“). Gelesen über `UIKit.PetHappiness()`
  (`GetPetHappiness`, 1–3; fehlt die Funktion, keine Laune wie beim
  Wichtel, oder geheim: `nil` – keine Erinnerung, nie „unglücklich“).
  Derselbe Wert zeichnet am eigenen Begleiterrahmen einen Punkt in
  `success`/`warning`/`danger` (`Frame:UpdateHappiness`, Tooltip
  „Laune: …“), weil die Oberfläche den Rahmen des Spiels mit seinem
  Gesicht versteckt. Vorschlag für Jäger: Begleiter, Munition, Laune.
  Gemessen ist nur, dass der Client die Laune kennt (Charakterfenster,
  `PetPaperDollPetHappinessInfo`). **Gemessen mit 6.13.1.0:** kein Punkt –
  `GetPetHappiness` antwortet auf Forever nicht. Seit 6.13.2.0 sammelt
  `/wcui prüfen` („Begleiter“), wo der Client die Laune führt; erst mit
  diesem Bericht kommt eine zweite Quelle, keine geratene.
  **Gemessen mit 6.13.2.0:** kein `GetPetHappiness`, aber
  `C_PetInfo.GetPetHappiness`; Energieart Happiness (27, max. 1000)
  geheim auch außer Kampf. Seit 6.13.3.0 fragt `K.PetHappinessSource()`
  diese Funktion (ohne Argument, dann mit `"pet"`) mit Gegenprobe über den
  Schaden in Prozent (`K.HAPPY_DAMAGE`, 75/100/125). **Gemessen mit
  6.13.3.0** (Client 1.60.1, Build 70235, außer Kampf): `3, 125, 20` –
  Laune, Schaden, Treuerate wie in Classic, offen, mit und ohne `"pet"`;
  der Punkt am Begleiterrahmen erscheint. Ungemessen: ob der Wert im Kampf
  geheim wird (dann geht der Punkt im Kampf aus – „weiß nicht“).
  **Liste je Charakter** (6.13.2.0): die Regeln bleiben accountweit, die
  Liste zeigt, was hier gilt (`R.ListedRules`, Stelle der Regel in
  `index`, Entfernen über sie), den Rest als Zählzeile; „Alle zeigen“
  (`R.listAll`) holt ihn blass dazu. Alte Regeln ohne Klasse der Arten
  `R.CLASS_KINDS` (Waffe, Begleiter, Laune, Munition) gelten nur, wo die
  Klasse sie vorschlägt.
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
  **6.14.0.2** (Beta-Test, gelaufen und geplündert: 17,5 MB, 62,6 KB/s,
  Questpfeil 26,2 KB/s, Plaketten 11, Minikarte 3,6):
  * **Eigene Lage ohne Vektoren** (`ui/kit.lua`: `K.BestMap`,
    `K.PlayerWorld`, `K.PlayerMapXY`, `K.ToWorld`). `GetPlayerMapPosition`
    und `GetWorldPosFromMapPos` legen je Aufruf eine Tabelle mit allen
    Methoden des Mixins an; `UnitPosition` nennt Zahlen. Genommen wird es
    nur nach **Abgleich** mit dem Weg über die Karte (gleicher Kontinent,
    auf 2 Einheiten genau, nicht auf der Diagonale – dort sähen vertauschte
    Achsen gleich aus), wiederholt alle `K.POS_CHECK_EVERY` = 10 s. Stimmt
    es nicht oder schweigt der Client, bleibt der alte Weg – die
    Zuordnung der Achsen ist also gemessen, nicht angenommen.
    Kartenkoordinaten (Minikarte, Weltkarte im Komfort) aus der Lage und
    den Ecken der Karte (je Karte einmal gerechnet).
  * **Questpfeil plant aus dem Zwischenspeicher**: Ort, Stufe, Gruppe,
    erfüllt je Quest liest `FillPlanCache` nur nach einem Ereignis des
    Questlogs (`QA.PlanDirty`) oder beim Kartenwechsel; der Lauf alle 5 s
    rechnet nur Entfernungen, Kandidaten und Sortierung ohne neue
    Tabellen. Das Ziel wird ohne Ereignis alle `QA.RESOLVE_EVERY` = 3 s
    statt jede Sekunde neu gesucht (Questlog, Wegpunkt, Leiche und Gebiet
    erzwingen es sofort), seine Weltlage nur, wenn sich der Ort ändert;
    `QA.Nav` nutzt eine Tabelle.
  * **Plaketten**: `FillTexts` (läuft bei jedem `UNIT_HEALTH`) ohne
    Tabelle je Aufruf (`TEXT_KEYS`), `BarColor` ohne Closure; der
    Questfortschritt (`C_TooltipInfo.GetUnit` – eine große Tabelle je
    Plakette) wird je Schub `QUEST_LOG_UPDATE` einmal gelesen
    (`NP.QueueQuestRefresh`, `NP.QUEST_DELAY` = 0,5 s) statt je Ereignis.
  * Im Prüflauf (Attrappe mit Vektoren wie im Spiel): Questpfeil
    48,7 → 6,0 KB/s, Plaketten 107,5 → 33,7 KB/s; `load_test.lua` hält
    100 Läufe des Pfeils unter 6 KB und 100 Treffer an einer Plakette
    unter 2 KB.
  * **Ruhender Bestand**: Lehrerdaten je Klasse und Classic-Beute je
    Dungeon werden erst beim ersten Zugriff gebaut (gut 450 KB weniger
    beim Laden, siehe `docs/systems/character.md` und
    `docs/systems/dungeons.md`).
  * **`/wcui speicher`** nennt zusätzlich den Wert **nach dem
    Aufräumen** (`collectgarbage("collect")`, dann neu gemessen) – „Speicher
    jetzt“ zählt Abfall mit, bis die Bereinigung des Spiels ihn holt.
* **Gespräche** (6.6.1.4, Beta-Test: „die normale Interaktion von
  Questgebern, Gastwirten etc. muss angeglichen werden“): `GossipFrame`,
  `QuestFrame`, `ItemTextFrame` (`W.DIALOGS`) bekommen die Fensterhülle,
  das Pergament geht über `W.HideLarge`, dunkle Schrift wird hell – und
  zusätzlich dunkle **Farbcodes im Text** (`W.LightCodes`: nur Codes mit
  jedem Kanal < 0x50, damit Rot und Grün bleiben): die Gesprächsoptionen
  setzen Questnamen als `|cff000000…|r` in den Text. Nachgezogen beim
  Zeigen jedes Quest-Teilfensters (`W.SHOW_HOOKS`), nach
  `GossipFrame:Update`/`Refresh` und im Takt des offenen Fensters.
  `MerchantFrame` nur Hülle und Knöpfe. Im Spiel ungeprüft. Seit 6.8.0.4
  in Gold (`ui/gossip.lua`, siehe *Gespräche in Gold*).
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
  **Seit 6.9.0.8** (Beta-Test: „es fehlt noch ein bisschen im Vergleich
  zu Details, gerade ein Threatmeter“):
  * *Pro Sekunde als Rangliste* (`Dps`, `Hps`; Messart mit `perSecond`):
    Balken nach `amountPerSecond` (`DM.BarField`), sonst stünde ein
    kürzerer Balken über einem längeren. Aufschlüsselung und Zauber
    über `base` (Schaden/Heilung). Dazu `Absorbs`,
    `AvoidableDamageTaken`, `EnemyDamageTaken` – alle nur, wenn
    `Enum.DamageMeterType` sie nennt (`DM.Modes`); ohne Enum die sechs
    Grundarten, damit das Fenster selbst sagt, dass die Messung fehlt.
    Die Enum-Namen sind aus der Retail-Dokumentation – was fehlt,
    erscheint nicht. **Gemessen (04.10.2026, Client 1.60.1, Build 70205, `/wcui prüfen`): alle elf
    Messarten kennt der Client.**
  * *Bedrohung* (`threat`, wie Tiny Threat): kommt nicht aus
    `C_DamageMeter`, sondern aus `UnitDetailedThreatSituation` je
    Gruppenmitglied und Begleiter auf dem Ziel (freundliches Ziel:
    dessen Ziel, `DM.ThreatMob`). Balken = `scaledPercentage` bis 100:
    das Spiel rechnet die 110 %/130 % von Classic schon ein. Sortiert
    nur mit offenen Werten (`ThreatOrder`: Tank, Prozent, roher Anteil);
    mit geheimen bleibt die Reihenfolge der Gruppe **ohne
    Platznummern**. Offen 0 ohne Aggro fällt heraus, geheim bleibt drin.
    **Gemessen (04.10.2026, Client 1.60.1, Build 70205, `/wcui prüfen`):** die **eigene**
    Bedrohung kommt im Kampf **offen**, alle fünf Werte (Krieger Stufe 21,
    allein: `isTanking` true, `status` 3, `scaledPercent` 100,
    `rawPercent` 255, `threatValue` 145), und die **anderer Spieler**
    ebenso (Gruppe zu zweit: `party1` `scaledPercent` 78,18 bei
    `rawPercent` 86 = 86 / 1,10 – das Spiel rechnet die Grenze im
    Nahkampf wirklich ein). Das Bedrohungsfenster sortiert also mit
    Zahlen und Platznummern. Schlachtzug ungemessen, dieselbe Abfrage.
    Kein Zeitraum, keine Aufschlüsselung. Läuft im Takt ohne neue
    Tabellen (feste Einheitenlisten, Einträge aus einem Vorrat).
  * *Breite der Aufschlüsselung* (6.9.0.9): so breit wie die Reiter der
    Messarten (`ApplyWidth` in `BuildTabs`), mindestens 360 px – mit den
    neuen Arten lief „Bannungen“ aus dem festen Fenster.
  * *Melden* (Sprechblase, `DM.ReportMenu` → `DM.Report`): nur nach dem
    Kampf und mit offenen Zahlen, nie Beispielzahlen; was nicht geht,
    sagt ein Hinweis im eigenen Chat. Kanäle nach Lage
    (`DM.ReportChannels`). **Gemessen (04.10.2026, Client 1.60.1, Build 70205, `/wcui prüfen`):**
    `C_ChatInfo.InChatMessagingLockdown()` ist `false` (allein, im Kampf,
    offene Welt), und eine Meldung an die **Gruppe kommt an** (Gruppe zu
    zweit, nach dem Kampf). **Gemessen 05.10.2026: an die Gilde →
    `ADDON_ACTION_BLOCKED`** („geschützte Funktion UNKNOWN()“), obwohl der
    Klick ein Tastendruck war; `pcall` fängt es nicht, der Spieler sieht
    einen Lua-Fehler. Seit 6.10.4.6 schreibt WeintCodex selbst nur in
    Gruppe, Schlachtzug und Instanz (`DM.DIRECT`; Schlachtzug und Instanz
    ungemessen, dieselbe Sorte wie die Gruppe). Gilde, Sagen und Flüstern
    (`DM.SLASH`, „/w Name“) legen **eine** Zeile in die Eingabezeile des
    Chats (`DM.OneLine`: ganze Plätze, höchstens 255 Bytes;
    `ChatFrame_OpenChat`) – Enter sendet, dann schreibt das Spiel selbst.
    Das Menü sagt es („Gilde (Enter sendet)“). Ungemessen: ob die
    Eingabezeile auf Forever so aufgeht.
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

## Seltene Gegner *(6.16.0.0, `ui/rares.lua`, Seite im Komfort)*

Meldet einen seltenen Gegner, sobald er als Plakette
(`NAME_PLATE_UNIT_ADDED`), im Ziel, unter der Maus oder als Symbol auf
der Minikarte (`C_VignetteInfo`, `VIGNETTES_UPDATED`) auftaucht: Ton
(`SOUNDKIT.RAID_WARNING` – fehlt die Tabelle, kein Ton, keine geratene
Nummer), Zeile im Chat, Hinweis oben (Kachel, `rarealert` im
Gestaltungsmodus, Klick schließt, nach `RA.TOAST_TIME` = 12 s weg).
Derselbe höchstens alle `RA.REALERT` = 5 min; tot nur auf Wunsch; in
Instanzen nur auf Wunsch; Spieler nie. Gespeichert unter `comfort`
(`rareAlert` … `rareDead`), wie jeder Komfort-Helfer ab Werk **aus** –
ein eigenes Modul hätte die Seitenleiste des Einstellungsfensters über
ihr Maß gehoben (`load_test.lua`, 648 von 680 px).

**Selten ist, was gemessen ist:** der Client sagt es
(`UnitClassification` „rare“/„rareelite“ – auch für Gegner, die nicht im
Bestand stehen; die Zeile sagt dann „nicht im Bestand“), oder der
Bestand kennt die NPC-Nummer aus der GUID (`RA.NpcId`, nur `Creature`/
`Vehicle`). Geheime GUID oder geheimer Name: keine Meldung.
**Bestand:** `data/rares.lua`, **erzeugt** von
`.github/scripts/import_foreverguide.py` – 404 Gegner aus ForeverGuide
1.25.6 (Questie-Datenbank für Forever, `community`), je eine Zeile, gelesen
bei Bedarf (`RA.Info`): Name, Stufen, Merkmale (Elite, Platzhalter,
zähmbar, nachts, beschworen), Wiederkehr (aus Classic, `classic`, im
Hinweis „Wiederkehr in Classic 1:30–2:30 h“), Lagen. Nicht übernommen:
Fähigkeiten (Texte), Beute (Classic-Chancen), Modelle.
**Gedächtnis:** je Realm (`SavedData.rares[Realm][NPC oder Name]`), wann
und wo (deine Lage) zuletzt gesehen, ob tot – nie eine geschätzte
Wiederkehr. **`/wcui selten`**: Bericht der seltenen Gegner deines
Gebiets mit Wiederkehr und zuletzt gesehen. **`/wcui prüfen`**:
„Seltene Gegner“ (an/aus, Abfragen da, GUID des Ziels offen oder geheim,
Vignetten, zuletzt gemeldet).

## Auktionspreise *(6.17.0.0, `ui/auctionprices.lua`, Seite im Komfort)*

Wunsch des Spielers nach dem Vorbild von ForeverGuide (Verhalten, kein
Code – das Addon hat keine Lizenz). Ein Knopf „Preise scannen“ in der
Titelzeile des Auktionshauses (Lage **ungemessen**) liest die Angebote;
danach nennt jeder Tooltip eines Gegenstands (`TooltipDataProcessor`,
nur `GameTooltip`/`ItemRefTooltip`) das günstigste Angebot je Stück,
Menge, Tag – in den Taschen auch den Stapel (`GetPrimaryTooltipInfo` →
`GetBagItem`, sonst `GetBagID` des Besitzers). Gespeichert unter
`comfort` (`ahPrices`, `ahStack`, `ahPassive`), der Helfer ab Werk
**aus**; geht ohne Oberfläche.

**Die Zahl ist kein „Wert“:** das günstigste Sofortkauf-Angebot je
Stück beim letzten Blick, kein Durchschnitt – ein einzelnes billiges
Angebot macht sie klein, darum stehen Menge und Tag daneben. Herkunft
ist dein eigener Blick ins Auktionshaus. Kein Eintrag: **keine Zeile**,
nie „0“. Beim letzten vollständigen Scan nicht dabei: „zuletzt vor N
Tagen · beim letzten Scan nicht im Angebot“ (abgeleitet aus dem Tag des
Eintrags und `store.full`, ohne eigenes Feld).

**Drei Wege, alle ungemessen auf Forever:**

1. **Vollscan** (`C_AuctionHouse.ReplicateItems`), höchstens alle
   `AP.REPLICATE_EVERY` = 15 min. Gelesen werden `GetReplicateItemInfo`
   mit **0-basierten** Nummern, `AP.BATCH` = 1000 je Bild über einen
   Taktgeber, der nur während eines Scans läuft (`AP.Step`). Fertig mit
   `REPLICATE_ITEM_LIST_UPDATE` – oder ohne Ereignis, wenn
   `GetNumReplicateItems` zweimal dieselbe Zahl nennt.
2. **Suche**, wenn der Server nach `AP.REPLICATE_WAIT` = 35 s schweigt
   (laut ForeverGuide tut er das auf Forever manchmal); dann drei Tage
   lang gleich die Suche (`store.noReplicate`). `SendBrowseQuery` mit
   leerem Text (zwei Formen, `AP.Query`), weitere Seiten
   (`RequestMoreBrowseResults`) erst, wenn das Auktionshaus Anfragen
   nimmt; fertig mit `HasFullBrowseResults`, sonst nach `AP.STALL` =
   15 s ohne Seite **unvollständig** (dann setzt der Scan kein `full`).
   Nebenwirkung: die Liste im Auktionshaus zeigt dabei, was die Suche
   bringt.
3. **Nebenbei** die eigene Suche des Spielers (`ahPassive`).

**Gemessen (6.18.0.1, Beta-Test):** der Vollscan antwortet auf Forever,
mit Ereignis – 66.155 Angebote, 2.982 Gegenstände, ohne Fehler. Die
Suche als Rückfall ist damit ungemessen geblieben.

**Ablage:** `SavedData.auction["Realm|Seite"]` mit Seite `Alliance`,
`Horde` oder `Neutral` (Karten 1446 Tanaris, 1434 Schlingendorntal, 1452
Winterquell – bestimmt beim Öffnen). Je Gegenstand **eine Zahl**
(`AP.Pack`/`AP.Unpack`: Preis · 10⁷ + Menge · 10⁴ + Tag seit 1.1.2026 in
Ortszeit; gekappt bei `AP.PRICE_MAX` ≈ 90.000 Gold und 999 Stück) – eine
Tabelle je Gegenstand hätte das Dreifache gekostet. Nach
`AP.KEEP_DAYS` = 30 Tagen fällt ein Eintrag heraus. Im Tooltip zuerst das
Auktionshaus, an dem du stehst (sonst deiner Fraktion), dann das neutrale
(„Auktionshaus (neutral)“).

**Nicht gebaut:** Durchschnitt über mehrere Scans, Gewinn je Rezept.
Preise von anderen Spielern seit 6.18.0.0, siehe unten. **`/wcui auktion`**:
Bericht beider Ablagen mit den letzten Schritten; **`/wcui auktion
scan`** startet bei offenem Auktionshaus; **`/wcui prüfen`**:
„Auktionspreise“ (an/aus, welche Wege der Client anbietet, Tooltip über
welchen Weg, letzter Scan).

### Preise von anderen Spielern *(6.18.0.0, `ui/auctionshare.lua`)*

Anlass (Beta-Test): ForeverGuide zeigte Preise „vor 6 Minuten“ ohne
Besuch im Auktionshaus – das Spielernetz von ForeverGuide 1.25
(`Net.lua`: versteckter Kanal `FGLayers`, Kennung `FGD`, ab Werk an). Die
**einzige Ausnahme** vom Grundsatz „nichts verlässt den Client“ (CLAUDE.md),
nur auf Wunsch: zwei Schalter unter `comfort`, ab Werk aus, nur mit
`ahPrices`.

- **Gilde** (`ahShareGuild`, Kennung `AS.PREFIX` = `WCAH`, an `GUILD`):
  Nachrichten `Art:1:Seite:Zeit36[:…]` mit der Zeit des Servers
  (`GetServerTime`). Eigener vollständiger Scan → Angebot `O` (5 s
  später). Alle `AS.QUERY_EVERY` = 20 min Frage `Q`, wenn die eigenen
  Preise älter als `AS.FRESH_GAP` = 20 min sind. Wer mindestens so viel
  frischer ist, bietet nach 1–4 s an, außer jemand kam mit einem gleich
  guten zuvor. Der Fragende wählt nach `AS.WANT_WAIT` = 4 s den
  frischesten (`W:…:Name`), der schickt seinen Scan in Stücken `B`
  (`id,preis,menge` in Basis 36, ≤ 255 Zeichen) an die ganze Gilde – je
  Seite höchstens alle `AS.BROADCAST_GAP` = 30 min, **nur Eigenes aus dem
  letzten vollständigen Scan**, nie Weitergereichtes, nie Scans älter als
  6 h. Schlange: eine Nachricht je `AS.SEND_GAP` = 1 s, nicht im Kampf;
  nimmt das Spiel nicht an (Rückgabe ≠ 0), `AS.BUSY_GAP` = 5 s Pause.
- **ForeverGuide nur zuhören** (`ahListenFG`): Beitritt zu `FGLayers`
  `AS.JOIN_DELAY` = 12 s nach dem Einloggen (`JoinTemporaryChannel`),
  Kennung `FGD` angemeldet; gelesen werden nur `B:1:Seite:Zeit:Nr:…`
  im Kanal (`CHANNEL`). **WeintCodex sendet dort nie** – der Prüflauf hält
  jede gesendete Nachricht an `WCAH`/`GUILD`. Das Format steht im Kopf von
  `ForeverGuide/Net.lua`; übernommen ist das Format, kein Code. Ändert es
  sich, kommt still nichts mehr an – `/wcui auktion` zeigt „empfangen 0“.
  Ausschalten verlässt den Kanal nur, wenn ForeverGuide nicht läuft. Aus
  den Chatfenstern wird der Kanal nicht entfernt (Eingriff in Fenster des
  Spiels; der Kanal trägt nur Addon-Nachrichten).
- **Regeln für fremde Preise** (`AS.OnBulk`, `AS.ApplyPrice`): eigener
  Realm (Name-Realm des Absenders), nie von dir selbst, ganzer Scan nicht
  älter als deiner (−60 s), Zeit nicht mehr als 5 min in der Zukunft. Je
  Gegenstand gilt ein neuerer Tag; dein eigener Preis vom selben Tag geht
  vor. Mehr als `AS.OUTLIER` = 3× abweichend: zurückgehalten, bis ein
  **anderer** Absender etwas innerhalb von 2× meldet (`AS.held`, höchstens
  `AS.MAX_HELD`). Empfang je Absender und Scan; nach `AS.IDLE` = 12 s Stille
  fertig → `store.shared` (Zeit, Absender, Weg, Anzahl).
- **In derselben Zahl:** „von Spielern“ ist `AP.SHARED` = 5000 auf dem Tag
  (`AP.Pack(…, shared)`, viertes Ergebnis von `AP.Unpack`); Tage gehen
  dadurch bis `AP.DAY_MAX` = 4999 (2039). Tooltip: „von Spielern, heute ·
  3 Stück im Angebot“.
- Taktgeber `AS.Step` alle `AS.TICK` = 0,25 s, nur solange einer der
  Schalter an ist. Keine Zeile im Chat beim Empfang – bei vielen
  ForeverGuide-Nutzern käme alle 20 Minuten eine.

**Gemessen (6.18.0.1, Beta-Test):** der Kanal von ForeverGuide antwortet –
3.750 Preise von zwei Spielern in einer Sitzung, 10 Ausreißer
zurückgehalten, Empfänge sauber abgeschlossen; Namen in kyrillischer
Schrift kommen durch. Der erste Versuch (6.18.0.0) brach ab: das fünfte
Argument von `CHAT_MSG_ADDON` ist das Ziel, im Kanal dessen Name.
**Ungemessen:** die Gilde (niemand sonst mit WeintCodex), die Drosselung
beim Senden, ob der Beitritt eine Zeile im Chat zeigt.

## Flüstern als Messenger *(6.19.0.0, `ui/messenger.lua`, Seite im Komfort)*

Wunsch des Spielers nach dem Verhalten von WIM (WoW Instant Messenger
3.18.1 – „All Rights Reserved“: kein Code, keine Bilder, keine Töne).
Wird dir etwas zugeflüstert, geht ein Fenster auf: links die Gespräche
(neuestes oben, Ungelesene als Zahl, × schließt eins), rechts der
Verlauf (Uhrzeit, Name in Klassenfarbe aus der GUID, du im Akzent,
Links klickbar), unten die Antwortzeile. Gespeichert unter `comfort`
(`msgOn` … `msgDirect`), der Helfer ab Werk **aus**; geht ohne
Oberfläche. `/wcui flüstern` öffnet und schließt.

**Mit dem Spieler entschieden (07.10.2026), nicht verhandelbar ohne ihn:**

- ~~**Der Chat bleibt.**~~ Bis 6.19.0.1 stand jedes Flüstern auch im
  Chat. **Neu entschieden in 6.19.1.0** (Beta-Test: „Whisper sollen nicht
  parallel auch im Chat zu sehen sein. Dafür ist dann wirklich dieses
  Messenger Fenster.“) – siehe *Nur im Fenster* unten.
- **Verlauf nur diese Sitzung** (`MS.conv`, `MS.MAX_LINES` = 200 je
  Gespräch, `MS.MAX_CONV` = 8). **Nie** in `WeintCodex_SavedData`: die
  Datei liest die Companion-App, und private Nachrichten gehören dort
  nicht hin. `load_test.lua` durchsucht die gespeicherten Daten nach dem
  Text der Prüfnachrichten.
- **Nur Flüstern und Battle.net-Flüstern**, nicht Gilde oder Gruppe.

**Antworten.** An die Gilde ist eigenes Senden gemessen gesperrt
(6.10.4.6, `ADDON_ACTION_BLOCKED`, `pcall` fängt es nicht). Darum öffnet
ab Werk ein Klick in die Antwortzeile die **Chatzeile des Spiels** mit
„/w Name “ (`ChatFrame_OpenChat`; Battle.net `ChatFrame_SendBNetTell`) –
Enter sendet, das Spiel sendet selbst. „Direkt aus dem Fenster senden“
(`msgDirect`, ab Werk aus, **ungemessen**) sendet über
`C_ChatInfo.SendChatMessage` bzw. `BNSendWhisper`. Meldet das Spiel
binnen `MS.BLOCK_WINDOW` = 1 s `ADDON_ACTION_BLOCKED`/`FORBIDDEN` für
WeintCodex, schaltet WeintCodex `msgDirect` ab, merkt die Messung
(`ui.msgDirectBlocked`, steht in `/wcui prüfen`) und gibt den Text an die
Chatzeile weiter – der Spieler sieht dabei einmal den Fehler des Spiels.

**Aufgehen.** Ist das Fenster zu, geht es beim nächsten Flüstern auf
(auch beim eigenen, `msgOutgoing`); ist es offen, bleibt das gewählte
Gespräch, das neue zählt als ungelesen. Im Kampf erst nach
`PLAYER_REGEN_ENABLED` (`msgCombat` schaltet das ab). Seit 6.19.1.0
klappt ein offenes Fenster bei `PLAYER_REGEN_DISABLED` ein (versteckt,
`MS.folded`) und geht danach wieder auf – mit dem Gespräch, das im Kampf
dazukam (`MS.pending`), sonst mit dem von vorher (`MS.OnCombat`).

**Nur im Fenster** (6.19.1.0, `msgHideChat`, ab Werk an, sobald der
Helfer an ist). Ein Chatfilter des Spiels (`ChatFrameUtil.AddMessageEventFilter`,
sonst `ChatFrame_AddMessageEventFilter`; welcher, steht in `/wcui prüfen`)
für Flüstern, Battle.net-Flüstern, Abwesend/Beschäftigt und „nicht
online“. Er gibt nur `true` zurück (verbergen), **nie** veränderte Angaben –
Chatzeilen werden weiter nie umgeschrieben. Und nur, was das Fenster
selbst lesen kann: Filter und Fenster fragen dieselbe Stelle
(`MS.Capturable`, für die Systemzeilen `MS.SystemTarget`). Geheimes
(Sperre des Spiels) bleibt im Chat – sonst stünde es nirgends.
Was der Chat dann nicht mehr tut, weil er die Zeile nie sieht: Ton und
blinkendes Symbol der Taskleiste (macht jetzt `MS.Ping`, höchstens alle
`MS.PING_GAP` = 3 s) und **die Taste „Antworten“ (R)**: das Spiel merkt
sich den Absender nur für Zeilen, die der Chat zeigt. Den Absender selbst
eintragen (`ChatEdit_SetLastTellTarget`) hieße, die Chatzeile des Spiels
zu verunreinigen (taint) – danach blockiert das Spiel geschützte Befehle
aus ihr (`/cast`, `/target`). Darum hängt sich WeintCodex seit 6.19.1.2 **hinter** die Taste
(`hooksecurefunc` auf `ChatFrame_ReplyTell`/`ChatFrameUtil.ReplyTell`,
`MS.OnReply`): das Fenster geht beim zuletzt Flüsternden auf (`MS.lastIn`,
ausdrücklich – auch im Kampf, als gelesen), und zielt die offene
Chatzeile auf jemand anderen (`MS.EditAimsAt`, Attribute nur gelesen),
öffnet WeintCodex sie neu mit „/w Name“ – derselbe Weg wie der Klick in
die Antwortzeile (`OpenGameReply`). Mit „Direkt senden“: Fokus in die
Antwortzeile des Fensters. Gemessen (Beta-Test 6.19.1.2): die Taste läuft
darüber, das Fenster geht auf. Seit 6.19.1.3 kommen Chatzeile bzw. Fokus
erst im nächsten Bild (`C_Timer.After(0, …)`): sofort geöffnet, fing die
Zeile das Zeichen der Taste („r“) auf – „/w Name“ ersetzt jetzt, was darin
steht. Ungemessen: ob ein Bild reicht.

**„/w Name“ und Klick auf einen Namen** (6.19.1.0). WeintCodex hängt sich
an die Eingabezeilen des Spiels (`HookScript` auf `OnShow`/`OnTextChanged`,
dazu `hooksecurefunc("ChatEdit_UpdateHeader")`) und **liest nur** deren
Attribute `chatType`/`tellTarget`. Steht dort `WHISPER` oder
`BN_WHISPER` mit Ziel, geht das Gespräch im Fenster auf (`MS.OnChatEdit`,
einmal je Ziel, bis die Zeile wieder zu ist; Battle.net über ein offenes
Gespräch gleichen Namens oder `BNet_GetBNetIDAccount`). Geschrieben wird
weiter in der Chatzeile – sie wird nie angefasst (kein `SetText`,
`Hide`, `ClearFocus`; `load_test.lua` hält das fest). Hängt an
`msgOutgoing`.

**Symbol** (6.19.1.0, `msgIcon`, ab Werk an): eine Kachel 32 × 32 mit der
Sprechblase aus `media/ui/icon_report.tga` (eigenes Bild), oben rechts
die Zahl der Ungelesenen (`MS.Unread`) – seit 6.19.1.1 auf einem Punkt im
Akzent (`disc.tga`) über der Ecke, ab 100 „99+“; hell, solange etwas
ungelesen oder das Fenster offen ist. Klick: auf/zu. Platz `messengerIcon`
in `ui/layout.lua`.

**Gelesen** (6.19.1.1, Beta-Test: „Da muss noch ne Zahl hin“): bis dahin
setzte das Aufgehen selbst das Gespräch auf gelesen – am Symbol stand nie
eine Zahl. `MS.Show(key, auto)`: von selbst aufgegangen (Flüstern, nach dem
Kampf) bleibt es ungelesen, bis du hinsiehst (`MS.MarkRead`): Maus über dem
Fenster (`OnUpdate` nur bei Ungelesenem, alle `MS.SEEN_EVERY` = 0,2 s),
Klick in die Antwortzeile, „Markieren“, Gespräch wählen, Öffnen über
Symbol oder `/wcui flüstern`. Hat das offene Gespräch Ungesehenes, zählt
jede weitere Nachricht dazu.

**Ziehen** (6.19.1.0, Beta-Test: „das Fenster ist nicht verschiebbar“):
Fenster und Symbol lassen sich direkt mit der Maus ziehen
(`K.DragToMove`), nicht nur im Gestaltungsmodus; die Stelle landet in
`ui.positions` wie dort.

**Sperre des Spiels.** Ist der Text geheim (`issecretvalue`, z. B. im
Bosskampf), wird er nie gelesen; das Fenster zählt nur („N während einer
Sperre nur im Chat“). WIM baut solche Nachrichten nachher nach – das geht
bei geheimen Werten nicht, und wir raten nicht.

**Dazu:** Abwesend/Beschäftigt (`CHAT_MSG_AFK`/`DND`) und „nicht online“
(Muster aus `ERR_CHAT_PLAYER_NOT_FOUND_S`) als graue Zeile in ein offenes
Gespräch – nie ein neues Gespräch für Fremde.

**Markieren** (6.19.0.1, Beta-Test „Sätze markieren und kopieren“): das
Nachrichtenfeld des Spiels kann keinen Text markieren. Der Knopf
„Markieren“ oben tauscht es gegen ein Textfeld nur zum Lesen an derselben
Stelle (`MS.SetCopyMode`), mit `MS.PlainHistory` – ohne Farben, Bilder und
Link-Kodes (`[Donnerzorn]` statt `|Hitem:…|h`). Mit der Maus markieren,
Strg+C kopiert; Tippen stellt den Text wieder her; Esc oder der Knopf führt
zurück zum Verlauf mit Farben und klickbaren Links.

**Ungemessen:** ob `msgDirect` erlaubt ist, ob Battle.net-Namen (`|K…|k`)
im Fenster richtig erscheinen; seit 6.19.1.0 auch, welcher Chatfilter auf
Forever da ist, ob das Spiel ohne gezeigte Zeile selbst noch einen Ton
spielt (dann zwei), ob ein Klick auf einen Namen im Chat wirklich über
die Eingabezeile läuft. Gemessen (Beta-Test 6.19.0.1): Fenster geht auf,
Markieren und Kopieren gehen.

## Instanzeingänge auf der Karte *(6.20.0.0, `ui/mapentrances.lua`, Seite im Komfort)*

Wunsch des Spielers: „wenn ich die Karte normal aufmache, schon auch sehen,
wo die Instanz ist, mit einem Instanzsymbol“ – zusätzlich zur Marke aus dem
Codex („Eingang auf der Karte“, `modules/questmap.lua`), die bleibt. Seite
„Karte“ im Komfort, `mapEntrances` ab Werk aus, `mapContinent` an.

- **Woher:** `J.ENTRANCES` (aus dem Abgleich mit ForeverGuide, 6.14.0.0,
  `community`) – 22 Eingänge an 20 Stellen. Kein Eintrag, kein Symbol.
  Gleiche Stelle → ein Symbol, im Tooltip alle Dungeons nach Stufe
  (`ME.Spots`; Schwarzfels: drei). Tooltip sagt „aus Beta-Berichten
  (ForeverGuide) – unbestätigt“; Klick schlägt den ersten im Codex auf.
- **Wie:** dieselbe Regel wie die Marke (6.6.0.1) – eigene Rahmen auf der
  Fläche (`QM.Canvas`), Kehrwert des Zooms, Ebene über der Karte; nie
  `AddDataProvider`, nie in Rahmen des Spiels geschrieben. Taktgeber
  (`ME.TICK` = 0,05 s) als Kind der Weltkarte; die Liste je Karte
  entsteht nur beim Wechsel (`ME.ForMap`, gemerkt, `ME.Forget` bei jeder
  Einstellung), im Takt wird nur gestellt.
- **Kontinent:** Zonen, deren Eltern (`parentMapID`) zum gezeigten
  Kontinent führen (`mapType` 2), über `C_Map.GetMapRectOnMap`; ohne
  Rechteck kein Symbol. Die Welt als Ganzes bleibt leer.
- **Nicht doppelt:** liefert `C_EncounterJournal.GetDungeonEntrancesForMap`
  für die Karte etwas, zeigt das Spiel selbst Eingänge – unsere bleiben
  dort weg.
- **Bild:** eigene `disc`/`icon_gate` (media/ui), neutral (dunkel, hell),
  kein Akzent – die Weltkarte ist mit der Oberfläche ein Fenster in Gold.
- **Ungemessen:** die Ebene über den Symbolen des Spiels, ob
  `GetMapRectOnMap` auf Forever Rechtecke nennt, ob das Spiel selbst
  Eingänge kennt (`/wcui prüfen` → „Karte“).

## Karte aufdecken *(6.20.0.0, `ui/mapreveal.lua`, Seite „Karte“)*

Wunsch des Spielers: „optional die Karte komplett aufgedeckt; wo ich noch
nicht war, etwas abgedunkelt“. `mapReveal` ab Werk aus, `mapRevealTint` an.

- **Daten:** der Client gibt nur die **erkundeten** Kartenteile heraus
  (`C_MapExplorationInfo.GetExploredMapTextures`), nicht die ganze Liste.
  Die steht in `data/mapreveal.lua`, **erzeugt** von
  `.github/scripts/import_mapreveal.py` aus der Tabelle „Reveal Data for
  Forever“ des Addons Leatrix Maps (1.60.15, vom Spieler hochgeladen) –
  nur Bildnummern, Größe, Lage je Teil, kein Code; dem Addon liegt keine
  Lizenzdatei bei, übernommen sind nur Tatsachen aus den Spieldaten (wie
  bei ForeverGuide). Schlüssel: `C_Map.GetMapArtID`. 44 Zonen, 569 Teile,
  erst bei Bedarf gebaut (`build()`). Neue Fassung: Skript mit der neuen
  `Leatrix_Maps_Reveal.lua` laufen lassen.
- **Gegenprobe** (`MR.Check`): die erkundeten Teile des Clients gegen die
  Tabelle. Fehlt eines dort oder trägt es andere Bilder → „passt nicht“,
  die Zone bleibt, wie sie ist (ein falsches Bild zeichnet das Spiel als
  grüne Fläche). Nichts erkundet → „ungeprüft“, aufgedeckt.
- **Zeichnen** (`MR.Draw`): nur die unerkundeten Teile, eigene Bilder in
  einem eigenen Rahmen auf der Fläche der Karte, auf der Ebene der
  erkundeten Teile des Spiels (das Kind der Fläche mit
  `pinTemplate == "MapExplorationPinTemplate"`, nur gelesen; sonst Fläche
  + 1, `/wcui prüfen` sagt „geschätzt“). Kacheln zu 256, Zeile für Zeile,
  die letzte zugeschnitten auf die nächste Zweierpotenz (`SetTexCoord`).
  Abgedunkelt: `MR.TINT` = 0,45. Neu nur bei Zonen-/Flächenwechsel und
  `MAP_EXPLORATION_UPDATED` (`dirty`).
- **Leatrix Maps geladen:** es deckt auf, WeintCodex nicht.
- **Ungemessen:** die Ebene auf Forever, ob die Lage auf der Fläche in
  deren Einheiten stimmt (die Fläche hat die Größe des Kartenbilds).

## Automark *(6.8.1.0, auf Klick seit 6.9.0.2, `ui/automark.lua`)*

Beta-Test: „Wenn eine Instanz betreten wird, soll der Tank und Heiler
einen Mark über den Kopf bekommen. Einstellbar, welches Mark.“

- **Rolle nur vom Spiel.** `UnitGroupRolesAssigned` – gesetzt von der
  Suche nach Gruppe oder der Rollenwahl. Ohne Rolle wird **nicht**
  markiert und nichts hergeleitet (weder Ausrüstung noch Talentbaum);
  die Seite sagt „keine Rolle vergeben“. Je Rolle der erste Spieler in
  fester Reihenfolge (`player`, `party1…4` bzw. `raid1…40`) – eine
  Markierung kann nur einer tragen.
- **Die Falle: dieselbe Markierung noch einmal nimmt sie ab**
  (`SetRaidTarget`), und der Forever-Client hält den Index geheim
  (`ui/kit.lua`, „Markierung geheim“). Deshalb: nur der Gruppenleiter
  markiert (`markOnlyLeader`, abschaltbar; im Schlachtzug sonst Leiter
  oder Assistent); je Instanz einmal je **Spieler und Markierung**
  (`state.done[role] = GUID#Index`) – neu nur, wenn die Rolle, die
  gewählte Markierung oder die Instanz wechselt. Eine andere Einstellung
  setzt nichts neu (der Test fand genau das: „Im Chat melden“
  umschalten nahm die Markierungen ab). Ist der Index offen lesbar und
  stimmt schon, bleibt es dabei.
- **Nur auf Klick (6.9.0.2, gemessen).** Beta-Test 6.9.0.1 beim Betreten
  eines Dungeons: `ADDON_ACTION_FORBIDDEN … UNKNOWN()` aus
  `pcall(SetRaidTarget)` – Markieren ist für Addons **geschützt**, wie
  das Neuladen. `pcall` fängt das nicht ab: das Spiel blockiert, `pcall`
  meldet Erfolg, die Seite zeigte „markiert“. Seit 12.0.0 gilt das auch
  in Retail (`SetRaidTarget` geschützt, `GetRaidTargetIndex` geheim) –
  kein Addon markiert dort mehr ohne Klick. Jetzt **fragt** Automark beim
  Betreten (Beta-Test: „Abfrage, ich bestätige, dann werden die Marks
  gesetzt“): ein Fenster an `K.LAYOUT.automark` unter den Erinnerungen
  mit Namen und Markierungen, „Markieren“ und „Nicht jetzt“. Über
  „Markieren“ liegt der geschützte Knopf `WeintCodexAutoMarkButton`
  (`SecureActionButtonTemplate`, `type1 = "macro"`): je Rolle eine Zeile
  `/tm [@einheit] n` (Einheiten, nie Namen). **Markieren** merkt
  `state.done`; **Nicht jetzt** (oder Rechtsklick, kein `type2`) lässt
  bis zum nächsten Betreten Ruhe. Ob das Spiel
  wirklich markiert hat, sagt es nicht (Index geheim) – nach dem Klick
  gilt es als markiert. Mit `/click WeintCodexAutoMarkButton` in einem
  Makro auch auf eine Taste. `load_test.lua` verbietet `SetRaidTarget`
  im ganzen Code (wie `ReloadUI`). **Gemessen (05.10.2026, Client 1.60.1):**
  `/tm` aus dem Makro markiert auf Forever (Automark und Markieren per
  Mouseover, Rückmeldung aus dem Spiel).
- **Nie im Kampf:** der Knopf ist geschützt – gezeigt, belegt und
  versteckt wird er nur außerhalb (`pending`, `PLAYER_REGEN_ENABLED`;
  ein Klick im Kampf wirkt, der Knopf geht danach).
- **Wo:** Seite „Automark“ im Komfort, kein eigenes Modul – ein weiterer
  Eintrag hätte der Seitenleiste der Einstellungen die Luft für einen
  nächsten genommen. Einstellungen unter `comfort` (`autoMark`,
  `markTank`, `markHealer`, `markDungeons`, `markRaids`,
  `markOnlyLeader`, `markChat`); wie jeder Komfort-Helfer von Haus aus
  **aus**. Standard: Tank Quadrat, Heiler Dreieck.
- **Status:** „(wartet auf Klick)“ hinter jedem Namen, der noch nicht
  markiert ist – nie „markiert“ ohne Klick.

## 6.10.0.0: Antworten auf die eigene Einschätzung

Selbsteinschätzung der Oberfläche (Gesamt 6,5 von 10) mit fünf Punkten,
alle umgesetzt:

1. **Fenster in Gold aus Bausteinen** (`ui/calmparts.lua`, `CP.New`).
   Handel, Bank und Post waren dreimal derselbe Ablauf. Jetzt beschreibt
   ein Fenster nur noch seine gemessenen Bilder: `files` (Bild → Art),
   `atlases` (Muster → Art), `money`, `moneyOf`, `tabs`, `after`,
   `report`. Arten: `slot` (weg, Rahmen flach), `field` (weg, Leiste mit
   Rand), `strip` (weg, Leiste ohne Rand), `bg` (weg, Innenfläche),
   `decor` (weg). Die Regeln gelten an einer Stelle: Symbol, Qualität und
   Überlagerung bleiben; ausgeblendet nur, solange das Bild ein gemessenes
   ist; nichts wird im Takt neu gesetzt; `InsetFrameTemplate` wird
   Innenfläche. Eine unbekannte Art lehnt `CP.New` ab. Das Auktionshaus
   (Navigation, Spaltenköpfe ohne Wiederzeigen) und die älteren Fenster
   (Händler, Beute, Makros, Gespräche) sind **noch nicht** umgestellt.
   Der Ladetest fand dabei einen Fehler: `spec.money or {}` legte im Takt
   je Aufruf eine Tabelle an.
2. **Einstellungen in zwei Stufen** (`ui/options.lua`). Was nach
   `B:Advanced()` steht (bis `B:EndAdvanced()` oder zum Seitenende), ist
   zugeklappt. Der Knopf nennt die Zahl („Erweitert: 12 Einstellungen
   einblenden“), ein Klick klappt auf **jeder** Seite auf
   (`general.showAdvanced`, `O.SetAdvanced` verwirft die gebauten Seiten
   und baut die aktuelle an derselben Stelle neu). Markiert: Plaketten
   (alle sechs Seiten), Einheitenrahmen (Schrift, Zauberbalken),
   Schadensanzeige (Melden). Die Werte gelten auch zugeklappt.
   **Suche** oben rechts: `O.SearchIndex` liest jede Seite einmal mit
   einem Mitschreiber (`Recorder`: dieselben Methoden wie der
   Seitenbauer, baut nichts; unbekannte Methoden, also Großbuchstabe vorn,
   tun nichts, Felder bleiben `nil`). `O.Search` vergleicht klein, auch
   Umlaute (`O.Fold`), als Text statt als Lua-Muster („in %“). Ein Klick
   öffnet die Seite und klappt „Erweitert“ auf, wenn der Treffer dort
   steht. Eine Seite links ersetzt die Treffer.
3. **Prüfliste im Spiel** vor jedem Release:
   `docs/development/release-checklist.md`, etwa zehn Minuten.
4. **Plaketten: Bewegung „Ruhig“ als Standard** (`motion`: `calm` |
   `lively` | `custom`). Die Stufe schaltet die vier lauten Bewegungen
   (`NP.MOTION_KEYS`: Atmen, Glanz, Trefferblitz, bewegte Marken) beim
   Einlesen (`Resolve`), ohne die eigenen Schalter zu überschreiben. Wer
   auf „Eigene“ zurückwechselt, findet seine Wahl wieder. Schadensspur,
   weiche Balken und Kante bleiben eigene Schalter: Sie sind leise und
   sagen etwas.
5. **Breiten gerechnet** in der Schadensanzeige. Die Kopfzeile teilt sich
   nach `DM.HeaderWidths` (Zeitraum gibt bis 44 nach, Titel mindestens 50).
   Das geht erst ab **220 px** auf (`DM.MIN_WIDTH`), ältere schmalere
   Einstellungen werden gehoben. Der Name einer Zeile bekommt, was die
   gemessene Zahl rechts übrig lässt (`Win:FitName`); ist die Breite
   geheim, bleibt es bei 55 %. Andere Module sind darauf **nicht**
   durchgesehen.

## 6.10.1.0: die offenen Punkte der zweiten Einschätzung

Zweite Einschätzung: 7 von 10. Umgesetzt:

1. **„Erweitert“ überall, wo es Feinheiten gibt.** Neu sortiert:
   Gruppenrahmen, Aktionsleisten, Questpfeil (mit `B:EndAdvanced()` vor
   der Gebrauchsanleitung), Minikarte, Chat und jede Einheitenseite
   (`UnitPage`: Porträt rechts, Höhe der Kraftleiste, beim Ziel die
   Feinheiten der Auren). **Bewusst ohne:** Erinnerungen, Komfort, Taschen,
   Questliste – jede Einstellung dort schaltet eine Funktion. Regel im
   Ladetest: Zugeklappt zeigt keine Seite mehr als 15 Einstellungen; wer
   eine Seite füllt, sortiert Feinheiten hinter `B:Advanced()`.
   Korrektur: Der Knopf erscheint nur dort, wo eine Seite einen Bereich
   hat – ein Schalter ohne Wirkung war er nie.
2. **Übernahme der Plaketten-Bewegung** (`NP.MigrateMotion`, beim
   Einschalten, einmal je Konto über `ui.migrated.npMotion`). Gespeichert
   ist nur, was vom Standard abweicht – bis 6.9 also nur ein `false`.
   Eine Mischung (manche aus, nicht alle) ohne gespeicherte Stufe wird
   `custom`; alle aus ist ohnehin „Ruhig“; nichts gespeichert folgt dem
   neuen Standard. Einmal, damit niemand zurückgestellt wird, der in
   6.10 selbst von „Eigene“ auf „Ruhig“ gegangen ist.
3. **Kontakte** aus Bausteinen (siehe unten).

Unverändert offen: Händler, Beute, Makros, Gespräche und das
Auktionshaus sind nicht auf Bausteine umgestellt – umgestellt wird ein
Fenster, wenn es ohnehin angefasst wird. Die Schadensanzeige bekommt
vorerst nichts Neues, bis im Spiel geprüft ist, was sie heute kann.


## 6.10.2.0: Messen im Spiel – Bericht zum Kopieren und Selbstprüfung

Zweite Einschätzung: „im Spiel abgesichert“ 4 von 10. Jede Messung kam
als Bildschirmfoto vom Chat, nach 24 Bildern abgeschnitten.

**Bericht zum Kopieren** (`ui/report.lua`): `K.ShowReport(titel, zeilen)`
öffnet ein eigenes Fenster an `UIParent` (`WeintCodexReport`, verschiebbar,
Esc schließt) mit einem Textfeld ohne Grenze – alles markiert, Strg+C.
Nur lesen: Getipptes wird durch den Bericht ersetzt. `K.PlainText` nimmt
Farbcodes und Symbole heraus.

**`/wcui fenster`** (`K.InspectWindow`, `ui/kit.lua`) schreibt in dieses
Fenster und nennt je Bild **jeden Fundort** mit Anzahl – als Name des
Bildes selbst, also mit seinem Schlüssel am Rahmen (`.BG`,
`.NormalTexture`, `.selectedTex`). Adressen namenloser Rahmen werden `*`
(`K.PatternName`): die Zeilen einer Liste, die das Spiel wiederverwendet,
stehen als eine Zeile da. Keine Grenze bei 24 Bildern. Unsichtbare Bilder
(Deckkraft 0, auch die von WeintCodex ausgeblendeten) werden gezählt,
nicht gelistet. Kennt der Baustein des Fensters (`CP.hosts[name].Kind`)
ein Bild, das noch sichtbar ist, steht seine Art daneben – entweder ein
Symbol (gewollt) oder ein Fehler.

Anlass: beim Lehrer klang „404984 · 10× · in ClassTrainerFrame“ nach zehn
Bildern am Fenster. Es waren Pergament, Grund jeder Zeile und die
Markierung der gewählten Zeile, verteilt über das Fenster.

**`/wcui prüfen`** (auch `/wcui check`, `ui/selfcheck.lua`, Knopf unter
Einstellungen → Tooltip & Fenster): fragt den Client, was nur er beantworten
kann, und ändert nichts. Kopf: Fassung, Client (`GetBuildInfo`), Klasse,
Stufe, Gruppe, Kampf, Oberfläche. Dann je Prüfung Zeilen mit Stand:

| Stand | Bedeutung |
|---|---|
| `[ok]` | der Client antwortet, wie WeintCodex es erwartet |
| `[!]` | Befund: der Client antwortet anders |
| `[?]` | gerade nicht zu beantworten – die Zeile sagt, was zu tun ist |

| Prüfung | Was |
|---|---|
| Speichern | `WeintCodex.SaveHealth()` |
| Fehler | `K.errors` – jede Meldung von `K.Report` seit dem Laden |
| Geheime Werte | gibt es `issecretvalue`? |
| Bedrohung | `UnitDetailedThreatSituation("player", "target")`: jedes der fünf Felder offen, geheim oder leer; ohne angreifbares Ziel `[?]` |
| Messarten | jede Messart aus `DM.MODES` in `Enum.DamageMeterType` – fehlende als `[!]`, **neue** des Clients als `[?]` |
| Chat | Senden vorhanden, `C_ChatInfo.InChatMessagingLockdown`; ob eine Meldung ankommt, zeigt nur ein Versuch – es wird **nichts** gesendet |
| Mikromenü | `MicroMenuContainer`/`MicroMenu`: `IsProtected` |
| Fenster in Gold | je Name in `W.WINDOWS`: gestaltet, vorhanden (noch nicht geöffnet), nicht im Client (manche lädt das Spiel erst beim Öffnen) |
| Speicherbedarf | `K.AddonKB` |

Jede Prüfung läuft für sich (`pcall`); eine, die scheitert, steht als
`[!]` im Bericht. Eine neue Prüfung: `Check(name, function(add) … end)` in
`ui/selfcheck.lua`, `add(stand, text)` beliebig oft, `add("", text)` für
eingerückte Folgezeilen.


### 6.10.2.1: genauer nach dem ersten Lauf

Der erste Lauf (04.10.2026, Client 1.60.1, Build 70205, `/wcui prüfen`) meldete 14 Fenster als „nicht im
Client“ – fast alles Lärm:

* **Alternativen** (`SC.ALTERNATIVES`): von `PlayerSpellsFrame`/
  `SpellBookFrame`, den drei Talentfenstern, `PVPFrame`/`HonorFrame` und
  `LFGParentFrame`/`PVEFrame` hat ein Client immer nur eines. Ist eines
  da, zählt die Gruppe als vorhanden.
* **Pakete des Spiels** (`SC.ADDON_OF`, `SC.AddonState` über
  `C_AddOns.GetAddOnInfo`/`IsAddOnLoaded`): ein Fenster, dessen Paket es
  gibt, aber noch nicht geladen ist, „lädt beim ersten Öffnen“ – kein
  Befund. Ist das Paket **geladen** und das Fenster fehlt trotzdem, ist
  das ein `[!]`: es heißt im Client anders. Nur was weder da ist noch ein
  bekanntes Paket hat, bleibt `[?]`. Ein falscher Paketname in der
  Tabelle fällt dort auf, nicht als gefundenes Fenster.
* **Bedrohung in der Gruppe** (`SC.GroupMate`, `SC.ThreatOf`): neben
  deiner eigenen die eines Mitspielers (der erste aus `party1–4` bzw.
  `raid1–40`, der nicht du bist) am selben Ziel – der Client kann die
  Werte anderer anders behandeln als deine. Allein steht ein `[?]` mit
  dem Hinweis auf die Gruppe.

### Messprotokoll

Was der Client geantwortet hat – mit Datum und Build, damit eine spätere
Fassung des Clients eine Antwort nicht stillschweigend überholt.

| Frage | Antwort | Gemessen |
|---|---|---|
| Eigene Bedrohung im Kampf geheim? | nein, alle fünf Werte offen | 04.10.2026, 1.60.1 (70205), Krieger 21, allein |
| Bedrohung anderer Spieler geheim? | nein, alle fünf Werte offen (`party1`: `scaledPercent` 78,18 bei `rawPercent` 86 – genau 86 / 1,10, die Nahkampfgrenze von Classic) | 04.10.2026, 1.60.1 (70205), Gruppe zu zweit, im Kampf |
| Messarten in `Enum.DamageMeterType` | alle elf aus `DM.MODES` | 04.10.2026, 1.60.1 (70205) |
| Chat für Addons gesperrt (`InChatMessagingLockdown`)? | nein | 04.10.2026, 1.60.1 (70205), offene Welt, im Kampf |
| Meldung in den Chat kommt an? | ja, Kanal Gruppe | 04.10.2026, 1.60.1 (70205), Gruppe zu zweit, nach dem Kampf |
| Mikromenü geschützt? | nein (`MicroMenuContainer`, `MicroMenu`) | 04.10.2026, 1.60.1 (70205) |
| Einstellungen werden gespeichert? | ja | 04.10.2026, 1.60.1 (70205) |
| `issecretvalue` vorhanden? | ja | 04.10.2026, 1.60.1 (70205) |
| TOC des Clients | 16001 (steht in `## Interface`) | 04.10.2026 |
| Talentfenster | kein `PlayerTalentFrame`/`TalentFrame`/`ClassTalentFrame` und kein `Blizzard_TalentUI` – die Talente stehen im `PlayerSpellsFrame` (`ui/talents.lua`) | 04.10.2026, 1.60.1 (70205) |
| PvP-Fenster | kein eigenes `PVPFrame`/`HonorFrame` – PvP ist ein Reiter des Charakterfensters (`ui/pvp.lua`) | 04.10.2026, 1.60.1 (70205) |

## Namensplaketten 3.0: Bewegung *(6.8.1.0, `ui/nameplates.lua`)*

Beta-Test: „insgesamt wirklich schon gut, aber es fehlt noch etwas
Cooles, ein Wow-Effekt“. Entwurf auf der Zeichenfläche „8 ·
Namensplaketten 3.0“ (drei Varianten), gewählt: **B + C** – „Lebendig“
mit den Zielmarken von „Vertraut“. Der Name bleibt, wo die Einstellung ihn
hinstellt (im Balken, darüber, darunter).

| Effekt | Schalter | Wie |
|---|---|---|
| Schadensspur | `damageTrail` | zweiter Balken `p.trail` **hinter** dem Leben (Grund `p.bg` seither am Plakettenrahmen, Ebene `BACKGROUND` 7; Spur Rahmenebene +1, Leben +2), Farbe `GC.damageTrail` |
| Weiche Balken | `smoothBars` | `SetValue(wert, Enum.StatusBarInterpolation.ExponentialEaseOut)` – der Client gleitet, auch mit geheimem Wert |
| Leuchten atmet | `targetPulse` | Alpha-Animation 100 % ↔ 45 %, 1,2 s je Richtung, an beiden Scheinen |
| Kante in Klassenfarbe | `targetEdge` | der 1-px-Rand des Ziels im Akzent (`K.Highlight`) |
| Glanz | `targetSheen` | heller Streifen (`GC.plateSheen`, additiv) läuft in 0,9 s über den Balken, dann 3,6 s Ruhe; abgeschnitten an einem Rahmen mit `SetClipsChildren` |
| Treffer blitzt | `hitFlash` | additiv Weiß (`GC.hitFlash`) 0,25 s, nur am Ziel, nur bei `UNIT_HEALTH` (nicht bei `UNIT_MAXHEALTH`) |
| Zielmarken bewegen sich | `markMotion` | Translation ±3 px nach außen, 0,8 s, hin und zurück |

**Geheime Werte.** Nichts davon rechnet oder vergleicht mit dem Leben: die
Spur bekommt **denselben** Wert wie das Leben, nur `NP.TRAIL_DELAY`
(0,35 s) später. Der erste Treffer startet die Uhr, weitere schreiben nur
den neuesten Wert – sonst schmölze die Spur in einem langen Kampf nie
(der Test hält genau das fest). Ob das Leben sank oder stieg, darf Lua
nicht fragen: **auch eine Heilung blitzt** (bei Gegnern selten; abschaltbar).

**Kein Lua je Bild.** Atmen, Glanz, Blitz und Marken sind Animationen des
Spiels (`NP.Anim`, AnimationGroup), gestartet und gestoppt nur bei einem
Wechsel (`NP.Motion`, `p._fx*`). Der einzige Takt ist die wartende Spur
(`NP.TrailTick`), er läuft nur, solange eine wartet; keine Closure, keine
Tabelle je Treffer (`load_test.lua` misst es).

**Gemessen (05.10.2026, Client 1.60.1):** Forever kennt
`Enum.StatusBarInterpolation`, die Balken gleiten. Fehlt es in einer
späteren Fassung oder lehnt der Client das Argument ab, springt der Balken
wie bisher (`NP.smoothBroken`, einmal gemerkt) – die Spur wirkt trotzdem,
nur ohne Gleiten. Ob `SetClipsChildren` den Glanz im Forever-Client sauber
abschneidet, zeigt erst das Spiel.

## Entfluchen auf Klick *(6.8.1.0, `ui/dispel.lua`)*

Beta-Test: „ein Feature wie Decursive – so haben Spieler, die sonst nicht
mit Klickzaubern zu tun haben, direkt eine Möglichkeit zu entfluchen.“

**Die Grundlage, nicht Decursive.** Ein Schalter im Reiter „Klickzauber“
der Gruppenrahmen (`clickDispel`, von Haus aus aus) legt die Zauber der
Klasse auf Zusatztaste (`clickDispelMod`, Standard Strg; „ohne“ gibt es
nicht – Links wählt sonst nicht mehr an) + Links (erste Gruppe) und
Rechts (zweite). Decursive liest die Debuffs der Gruppe und ordnet sie –
im Kampf gibt der 12.x-Client Addons fremde Auren nicht heraus (gemessen
6.6.0.1–6.6.0.3). Bannbare Debuffs zeigen die Gruppenrahmen des Spiels
(„Nur bannbare“). Was Forever zu Debuffs der Gruppe herausgibt: zu messen.

**Eine kleine Liste mit Herkunft** (`DP.SPELLS`, `DP.SOURCE = "classic"`):
der Client sagt nicht, welcher Zauber bannt. Zauber-IDs aus WoW Classic
1.12, je Klasse Gruppen mit Alternativen, die bessere zuerst:

| Klasse | Links | Rechts |
|---|---|---|
| Priester | Magiebannung (527/988) | Krankheit aufheben (552), sonst heilen (528) |
| Paladin | Reinigung des Glaubens (4987), sonst Läutern (1152) | – |
| Druide | Fluch aufheben (2782) | Vergiftung aufheben (2893), sonst heilen (8946) |
| Magier | Geringen Fluch aufheben (475) | – |
| Schamane | Gift heilen (526) | Krankheit heilen (2870) |

Angeboten wird ein Zauber nur, wenn der Client unter der ID einen Namen
nennt (`C_Spell.GetSpellName`/`GetSpellInfo`) **und** der Name im
Zauberbuch steht (oder `IsPlayerSpell`). Eine in Forever geänderte ID
führt zu nichts, nie zu einem falschen Zauber. Gewirkt wird über den
Namen (höchster Rang). Die Namen in der Tabelle sind nur Kommentar.

**Deine Belegung gewinnt.** `CC.Effective()` = deine Belegung, dazu
`CC.ExtraBindings()` nur auf freien Tasten; Rahmen und Tooltip nutzen
`CC.Effective`. Die Seite sagt, was wo liegt, was besetzt ist und was noch
nicht gelernt ist. Neu gelernt (`SPELLS_CHANGED`, `LEARNED_SPELL_IN_TAB`):
neu angewendet.

## Makro-Helfer *(6.8.1.0, `ui/macros.lua`)*

Beta-Test: „Viele wissen nicht, wie man ein Makro schreiben kann. Der
Nutzer kann auswählen, was das Makro machen soll, und es wird geschrieben.“

**Drei Fragen statt Makrosprache** (Seite „Makros“ der Aktionsleisten):

| Frage | Auswahl | Text |
|---|---|---|
| Was | Einen Zauber wirken · Mit Zusatztaste einen zweiten · Zauber nacheinander | `/cast` · `/cast [mod:…] B; A` · `/castsequence reset=… A, B, C` |
| Auf wen | Dein Ziel · Maus-Ziel, sonst Ziel · Maus-Ziel, sonst du selbst · Fokus, sonst Ziel · Du selbst · Am Mauszeiger | – · `[@mouseover,exists,nodead][]` · `[@mouseover,help,nodead][@player]` · `[@focus,exists,nodead][]` · `[@player]` · `[@cursor]` |
| Welcher Zauber | Tafel aus dem Zauberbuch (`UIClickCast.Spellbook`) oder eingetippt | Name, höchster Rang |

Mit Zusatztaste steht die Bedingung in **jeder** Klammer des zweiten
Zaubers (`[mod:ctrl,@mouseover,exists,nodead][mod:ctrl] B; […][] A`) –
sonst griffe der Rückfall `[]` ohne Taste. Extras: `#showtooltip` (Standard
an), `/stopcasting`, `/startattack`. Jede Zeile wird darunter in Worten
erklärt.

- **255 sind Bytes.** Der Zähler zählt mit `#` – hier mit Absicht, nicht
  Zeichen: ein Umlaut kostet zwei. Zu lang: Hinweis, Anlegen gesperrt.
- **Name** höchstens 16 Zeichen, gekürzt mit `Utf8Sub` (nie `:sub`);
  leer = erster Zauber.
- **Anlegen** (`CreateMacro`, Symbol Fragezeichen – `#showtooltip` zeigt
  das Zaubersymbol): gibt es den Namen schon, `EditMacro` (ersetzt);
  Plätze voll (`MAX_ACCOUNT_MACROS`/`MAX_CHARACTER_MACROS`) → Meldung.
  **Aufnehmen** (`PickupMacro`) legt es auf den Mauszeiger. Beides nie im
  Kampf.
- **Keine eingebaute Zauberliste** – wie bei den Klickzaubern. Ein
  eingetippter Name, den das Zauberbuch nicht kennt, wird nicht abgelehnt
  (Gegenstände), aber benannt.
- **Wo:** Seite der Aktionsleisten statt eigenes Modul (Seitenleiste
  der Einstellungen, „Nichts muss scrollen“). Der Entwurf lebt nur in der
  Sitzung.
- **Ungemessen:** ob der Forever-Client einzelne Befehle oder Bedingungen
  für Makros sperrt. Gemessen ist nur `/tm [@mouseover,harm,nodead]`
  (05.10.2026, Markieren per Mouseover): geht.

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

**Gilde & Communitys**: das Wappen oben links (`PortraitOverlay`) bleibt
(6.6.2.2 ausgeblendet, der Beta-Test wollte es zurück). Gemessen
05.10.2026: die Liste links ist gestaltet; die Chat-Eingabe trug den
hellen runden Rahmen des Spiels (`.ChatEditBox` Left/Mid/Right) – seit
6.10.4.2 flach (`CP.Flat`). Mitgliederliste seit 6.10.4.3 eingearbeitet
(`CO.SkinMembers`, Beta-Test „etwas besser einarbeiten“): grauer Rand
(`InsetFrame.NineSlice`), Leder hinter dem Bildlauf (374154) und die zwei
Bänder je Zeile (410251, 131128) weg – ohne Innenfläche darüber, denn
6.6.3.3 wollte sie nicht verdunkelt (`W.INSET_KEEP` bleibt). Seit
6.10.4.4 auch in der Ansicht „Mitglieder groß“ (gemessen): die
Spaltenköpfe (`MemberList.ColumnDisplay`) trugen einen zweiten grauen
Rahmen (`InsetBorder*`) und Marmor (`Background`, 374155) – weg
(`CO.COLUMN_PARTS`); der Rahmen der Liste Bild für Bild. Reiter „Info“
seit 6.10.4.5 (`CO.SkinDetails`, gemessen): `CommunitiesFrameGuildDetailsFrame`
mit den Flächen `Info` und `News` (Pergament und Kopfbalken 410251,
Holzleiste 130968) → Innenflächen über `W.OwnBackground`; graue Ränder am
Rahmen (`InsetBorder*`, auch „…2“) je Durchlauf nach Atlas weg, Leder am
Bildlauf der News weg.

## Bedrohung an den Plaketten *(6.9.0.8, `ui/nameplates.lua`)*

Beta-Test: „besser an den Namensplaketten anzeigen, nicht nur die
Prozentzahl rechts neben der Plakette“. Gewählt (aus drei Entwürfen):
Leiste unter dem Leben **und** wer die Aggro hat.

* **Leiste** (`threatBar`, Höhe `threatBarHeight`, Standard 3 px):
  direkt unter dem Leben, `scaledPercentage` bis 100 (nur `SetValue`,
  darf geheim sein). Farbe wie die Bedrohungsfarben: grau
  (`threatLow`) weit weg, orange kurz davor, rot mit Aggro; als Tank
  grün, solange du hältst, orange, wenn jemand darüber liegt. Nur auf
  der Liste des Gegners – nicht darauf oder offen 0: keine Leiste. Der
  Zauberbalken rückt **immer** um ihre Höhe nach unten, nicht nur im
  Kampf: ein springender Zauberbalken liest sich schlechter.
* **„Aggro: Name“** (`aggroName`): rechts unter der Plakette, bei
  laufendem Zauber unter dem Zauberbalken (`PlaceAggro`, neu gesetzt bei
  Zauber-Ereignissen). Halter (`NP.AggroHolder`): du, wenn du tankst;
  sonst das Ziel des Gegners – in Classic der, der ihn hält. Während
  eines Zaubers kann der Gegner kurz jemand anderen anvisieren, dann
  steht kurz ein anderer Name da; das Spiel sagt es nicht genauer. Nur
  Freunde unter Spielerkontrolle (eine Wache ist kein Aggroverlust),
  nur in einer Gruppe. `problem` (Standard): nur wenn der Halter keine
  Tankrolle hat – ohne zugewiesene Rollen also immer; `always`; `none`.
  Name in der Klassenfarbe, „Du“ rot (als Tank grün).
* Die Prozentzahl (`threatText`) bleibt wählbar.

**6.10.3.2 – die Leiste sagt etwas** (Beta-Test: „noch nicht richtig gut
wegen der Aggro“). Die eigene Bedrohung war in zwei Lagen ohne Aussage:

* **Allein ohne Begleiter** immer 100 % – an jedem Gegner voll rot. Die
  Leiste erscheint nur noch, wenn jemand die Aggro abnehmen kann
  (`NP.Contested`: Gruppe oder Begleiter). Die Prozentzahl folgt ihrer
  eigenen Einstellung.
* **Als Tank** (Rolle `TANK`, du hältst ihn) immer voll grün. Jetzt der
  **Nächste** (`NP.RunnerUp`): höchste `scaledPercentage` eines anderen
  auf diesem Gegner (Gruppe: `pet`, `party1..4`, `partypet1..4`;
  Schlachtzug: `pet`, `raid1..40`, ohne dich). Grün, ab
  `NP.WARN` (80 %, bis 6.10.3.2 `NP.LEAD_WARN`) oder bei Status 2 orange. Niemand sonst auf der
  Liste: 0. Ein geheimer Wert: zurück zur eigenen Bedrohung – nie eine
  geratene Zahl. Ohne Tankrolle bleibt es bei der eigenen (DD mit Aggro
  sieht Rot).
* 1 px Rand um die Leiste (`threatBar.edge`).

**6.10.3.3 – an der Farbe erkennen** (Beta-Test: „schön wäre es, wenn es
auch farblich erkannt werden kann“). `threatColors` (Lebensbalken) ist
ab Werk **an**. Eine Farbe der Lage, `NP.ThreatTint`, berechnet in
`UpdateThreatText`, gemerkt als `p._threatTint` und von Leiste,
Prozentzahl und `BarColor` gelesen – darum bei den Ereignissen und in
`FullUpdate` erst die Lage, dann die Farbe.

| Lage | Farbe |
|---|---|
| Tank hält sicher, Nächster unter 80 % | `tankAggro` (grün) |
| Tank, Status 2 oder Nächster ab 80 % (`NP.WARN`) | `tankLosing` (orange) |
| Tank ohne Aggro | `dpsAggro` (rot) |
| DD mit Aggro (Status ≥ 2) | `dpsAggro` (rot) |
| DD Status 1 oder ab 80 % | `dpsNear` (orange) – vorher nur Status 1, den es in Classic kaum gibt |
| sonst | keine: Leiste grau (`threatLow`), Leben in seiner Farbe |

Allein ohne Begleiter (`NP.Contested` falsch) gibt es keine Lage.

**6.10.3.4 – einstellbar** (Beta-Test: „Farbe, Prozent etc.“). Seite
„Bedrohung & Farben“, alles sichtbar:

| Abschnitt | Einstellungen |
|---|---|
| Bedrohung | Bedrohungsfarben (Leben), Bedrohung in %, Wer die Aggro hat |
| Bedrohungsleiste | an/aus, Höhe, **Warnen ab** (`threatWarn`, 50–100 %, Standard 80), **Auch allein zeigen** (`threatSolo`, aus), **Als Tank: den Nächsten zeigen** (`tankLead`, an) |
| Farben der Bedrohung | Aggro gezogen, Kurz davor, Tank: hält, Tank: der Nächste ist nah, **Weit weg** (`threatLow`, nur Leiste) |

`NP.Warn()` liest die Schwelle, `NP.WARN` (80) ist nur Rückfall. Die
Vorschau färbt ihr Beispiel (84 %) über `NP.ThreatTint` – die Schwelle
ist dort sofort zu sehen. Unter „Erweitert“ nur Gegner, Ziel und Fokus.

**Gemessen (04.10.2026, Client 1.60.1, Build 70205, `/wcui prüfen`):** die eigene Bedrohung am
Ziel kommt im Kampf offen – Leiste und Farben haben echte Werte. Für
andere Spieler (die Leiste zeigt immer **deine** Bedrohung, „Aggro: Name“
liest nur das Ziel des Gegners) ist das ohne Belang; das Bedrohungsfenster
der Schadensanzeige dagegen liest alle aus der Gruppe – dort ist offen,
was ein Gruppenlauf von `/wcui prüfen` zeigt.

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
Fläche. Gemessen 05.10.2026 (`/wcui fenster` auf „Vorlagen“): der
Seitenreiter rechts ist gestaltet; der Reiter „Gegenstände“
(`WardrobeCollectionFrameTab1`) trug noch `uiframe-activetab-*` – seit
6.10.4.2 flach über `W.SkinTab` (`LF.TABS` in `ui/calm.lua`, gewählt nach
`WardrobeCollectionFrame.selectedTab`).

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
- **Die Linie hängt an einem Punkt** *(6.9.0.0)*. Bis dahin lief sie
  von der Raute (`LEFT`) bis an den Balken des Spiels bzw. vor das
  Zeichen zum Auf- und Zuklappen (`RIGHT`). „RIGHT“ ist die halbe Höhe
  *der jeweiligen Region* – liegen Raute und Balken nicht genau auf
  einer Zeile, widersprechen sich die Punkte und das Spiel zeichnet die
  1-px-Linie gar nicht (Beta-Test: im Questlog fehlte sie bei
  „Brachland“, „Dunkelküste“, „Stormwind“, je nach Lage der Zeile).
  Jetzt nur links verankert, Breite aus `GetLeft`/`GetRight` gerechnet
  (`W.SizeLine`), neu, sobald eine Kante wandert; ohne gemessene Kante
  keine Linie. Gilt für jeden `W.ListHeader` (Questlog, Ruf,
  Fertigkeiten, Abzeichen, Berufe, Gilde, Gruppensuche, Sammlung, PvP,
  Optionen) und die rechte Linie der mittigen Kopfzeilen vor dem
  Zeichen. Zauberbuch, Talente und Berufsübersicht tun das seit
  6.7.8.0. **Regel:** eine Linie von 1 px nie an zwei Regionen
  verschiedener Höhe verankern. `/wcui fenster` zählt „Abschnitte: N,
  mit Linie M · ohne: …“.
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
Hinweis „Wählt eine Währung, um ihre Details anzuzeigen.“ **Ungemessen**
(05.10.2026 noch nicht messbar – der Charakter hat außer Gold keine Währung):
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

**Karte:** Titel `OutputText` (Schlüssel aus dem Quelltext des Spiels;
gemessen 05.10.2026: Titel „Kupferarmschienen“ gefunden, kein Bild des
Spiels mehr sichtbar; sonst oberste Zeile), Beschreibung `Description` oder die
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
  gemessen 05.10.2026: „Allgemein“ gefunden). Raute und Linie in
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
wurde sie nicht gezeichnet (nur die Raute stand da). *(Nachtrag 6.10.4.2:
auch danach nicht – siehe unten, Höhe der Linie.)* Jetzt nur links
verankert, Breite gerechnet. Derselbe Fehler in `ui/profbook.lua` (Titel
links, an der Karte). Regel: eine Linie hinter Text nie an einen Rahmen
anderer Höhe hängen – nur an Teile derselben Zeile (so macht es
`W.ListHeader`) oder links verankert mit gerechneter Breite.

**Höhe der Linie (6.10.4.2).** Messrunde 05.10.2026: im Zauberbuch und an
den Talentbäumen weiter nur die Raute – im Bildschirmfoto Bildpunkt für
Bildpunkt nachgeprüft, auch nach 6.7.8.0 (Anker) und 6.8.0.4 (Deckkraft
0.9). Dunkler Grund und Raute am selben Rahmen sind zu sehen; übrig bleibt
die Höhe von 1 Einheit. Bei kleiner Skalierung ist eine Einheit weniger
als ein Bildpunkt, und das Spiel rundet Ober- und Unterkante je nach Lage
auf dieselbe Zeile – Höhe 0. `S.PixelLine(t)` (`ui/style.lua`) setzt die
Höhe auf einen Bildpunkt (`768 / Bildschirmhöhe / GetEffectiveScale`), nie
unter 1 Einheit, in jedem Durchlauf (nur bei Änderung). **Vermutung, nicht
gemessen:** `/wcui fenster` nennt deshalb an beiden Stellen die Linie
(`S.LineReport`: Breite, Höhe in Einheiten und Bildpunkten, Oberkante in
Bildpunkten, sichtbar). Stimmt die Vermutung, betrifft sie jede Linie von
1 Einheit (`S.Divider`, `W.ListHeader`, `K.Border`) – die trafen bisher
zufällig; umgestellt wird erst nach der Messung.

**Gemessen mit 6.10.4.2 – die Vermutung war falsch (6.10.4.3).** „Linie:
614 breit, 1.00 hoch = 1.00 Bildpunkte, Oberkante bei Bildpunkt 866.50,
sichtbar ja“ – und im Bild nichts. Die Höhe war schon ein Bildpunkt; die
**Lage** war es: die Linie hängt mit ihrer Mitte an der Mitte der Raute.
Liegt die auf einem ganzen Bildpunkt, liegen beide Kanten auf halben, und
das Spiel rundet sie auf dieselbe Zeile. `S.PixelY(t, y)` liefert den
Versatz, mit dem die Oberkante ganz wird (je Durchlauf, gesetzt nur bei
Änderung, unter einem Bildpunkt); Zauberbuch (`h.lineY`) und Talente
nutzen ihn. Gemessen mit 6.10.4.4: „Oberkante bei Bildpunkt 918.00“ – die
Verschiebung wirkt; mit 6.10.4.5 im Bildschirmfoto bestätigt: die Linie
steht im Zauberbuch und an allen drei Talentbäumen (Beta-Test: „alles
korrekt so“). Erledigt nach drei Anläufen (Anker, Deckkraft, Höhe) – erst
die Messzeile im Bericht hat die Ursache gezeigt. **Regel:** eine Linie von einem Bildpunkt nie nur an ihrer
Mitte auf eine ganze Koordinate hängen – an einer Kante verankern oder
`S.PixelY`. Andere Linien dieser Art sind (noch) nicht umgestellt; fällt
eine aus, ist das der erste Verdacht.

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

**Weicher Rand neben den Questdetails (6.8.0.8).** Beta-Test: mit einer
geöffneten Quest war der rechte Rand der Karte wieder hart. Die Details
(`QuestMapFrame.DetailsFrame`) liegen **über** dem rechten Teil des
Ausschnitts; die Maske lief unter ihnen aus. `W.MapCut` misst, wie weit
die sichtbare Tafel (`W.MAP_COVERS`, sonst `QuestMapFrame`) in den
Ausschnitt ragt (rechter Rand des Ausschnitts minus linker Rand der
Tafel), und alle Masken enden um so viel früher – neu verankert nur,
wenn sich das ändert. `/wcui fenster` nennt „rechts … px früher“.
**Nachgemessen (6.8.0.9):** gesucht wurde unter
`QuestMapFrame.DetailsFrame`, die Details liegen im Forever-Client unter
`QuestMapFrame.QuestsFrame.DetailsFrame` – der Rand blieb hart.
`W.MAP_COVERS` sind seitdem Pfade; eine Tafel, die mehr als die halbe
Karte deckt, zählt nicht. Ohne Überdeckung nennt der Bericht beide Kanten.

**Questdetails in der ruhigen Oberfläche (6.8.0.9).** Gemessen: Pergament
`QuestDetailsBackgrounds`, Balken mit „Zurück“ `QuestLog-reward-top-frame`
(`.BackFrame`), Rahmen der Belohnungen `QuestLog-reward-bottom/-header-top/
-tile-vertical` (`.RewardsFrameContainer.RewardsFrame`), Metallstriche
`UI-Frame-BtnDivMiddle` zwischen Abbrechen | Teilen | Ausblenden, Text in
`QuestMapDetailsScrollFrame` (`.ScrollBar` minimal). Alle vier Atlanten in
`W.HIDE_ATLAS`; `ui/questlog.lua` legt unter den Text dieselbe Fläche wie
unter die Spalte (Schatten, Kante in Gold, Bildlaufleiste als Ecke) und
macht dunkle Schrift hell (`W.LightenText`, ohne Farbcodes). Farbige
Schrift (Belohnungen, Ziele erfüllt) bleibt. Titel und „Beschreibung“
behalten die Schrift des Spiels; Raute und Linie dort erst nach Messung
(die Schriftzeilen wandern zwischen Questfenster und Karte).

### Suche nach Gruppe *(6.8.0.0, `ui/lfg.lua`, seit 6.8.0.2 `ui/calm.lua`)*

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

### Sammlung *(6.8.0.2, `ui/calm.lua`)*

Beta-Test: „Accountsammlungen bitte auch anpassen“. **Gemessen**
(`/wcui fenster`, Reiter „Vorlagen“): `CollectionsJournal`, die Vorlagen
in `WardrobeCollectionFrame.ItemsCollectionFrame` (Plätze
`transmog-nav-slot-*`, der gewählte mit `transmog-nav-slot-selected`,
`bags-roundhighlight`), `.ClassDropdown`, `.FilterButton`,
`.PagingFrame`; kein Bild des Spiels mehr groß – der braune Verlauf war
der Schein der Klasse.

Derselbe Bedarf wie bei der Suche nach Gruppe – Fenster in Gold, Inhalt
auf Innenflächen –, deshalb ist `ui/lfg.lua` zu **`ui/calm.lua`**
(`WeintCodex.UICalm`) geworden: `LF.WINDOWS` nennt die Fenster und ihren
Namen im Bericht (`LFGParentFrame`, `PVEFrame`, `CollectionsJournal`).
Die Vorlagen sind seit 6.6.3.3 eine Innenfläche (`W.OWN_BG_PATHS`) und
bekommen damit Schatten und Kante in Gold; der Schein der Klasse ist aus.

**Reiter oben:** `SkinTab` färbte den gewählten Reiter eines
Reitersystems immer in der Klassenfarbe; jetzt trägt er den Akzent des
Fensters (`SkinTabSystems` holt ihn aus dem Stil) – wie die Seitenreiter.
Ob „Gegenstände“ in der Sammlung ein solches Reitersystem ist, zeigte die
Messung nicht; ist es eine eigene Vorlage des Spiels, bleibt sie, wie sie
ist.

**Unverändert:** Plätze samt Goldring am gewählten (Auswahl des Spiels),
Klassenauswahl, Suche, Filter, Blättern, Seitenreiter-Symbol.

### Talente *(6.8.0.3, `ui/talents.lua`)*

Beta-Test: „Die Animation bei dem Talentbaum soll so bleiben, nur der Rest
angepasst an das neue Design.“ **Gemessen** (`/wcui fenster`):
`PlayerSpellsFrame.TalentsFrame` mit `talents-animations-clouds` (2×),
`talent-background-warrior` (3×, seit 6.4.1.2 gedämpft),
`talents-animations-particles` (2×), `Talents-Background-c60`,
`Talents-inner-frame-c60`; `.ButtonsParent` mit den Talenten
(`talents-node-square-*`, `talents-sheen-node`, `talents-arrow-head-*`).

Klassenfarbe (`S.CHARACTER_INFO`, nur für `…TalentsFrame`), in
`W.HOSTED.PlayerSpellsFrame` neben dem Zauberbuch:

- **Animation und Landschaften bleiben** – nichts davon wird angefasst
  (der Test hält Deckkraft und Sichtbarkeit fest).
- **Licht und Kante:** ein Hauch Licht in der Klassenfarbe
  (`GC.classLight`, 180 px) und oben eine Kante (50 %) – wie im
  Zauberbuch. Sie liegen **auf** dem Talentfenster (`BORDER` 7, `ARTWORK`
  7): auf dem äußeren Fenster lägen sie unter den Landschaften und wären
  unsichtbar. Gemessen 05.10.2026 (Bildschirmfoto): Wolken und Funken
  liegen richtig; das Licht ist ein Hauch (7 %).
- **Schein der Klasse aus**, solange die Talente offen sind
  (`TL.GlowOff`; beim Zauberbuch schon seit 6.7.7.0).
- **Namen der Bäume:** welche Zeile ein Name ist, sagt das Spiel –
  `GetTalentTabInfo(i)` für `i = 1 … GetNumTalentTabs()`; beide ersten
  Rückgaben, wenn sie Text sind (Classic: `name, …`; spätere Fassungen:
  `id, name, …`). Gesucht bis alle gefunden sind, höchstens 30
  Durchläufe. Raute und Linie in der Klassenfarbe hinter dem Text (Linie
  140 px, läuft aus, nur links verankert), am Rahmen der Zeile.

**Unverändert:** Talente samt Rahmenfarben (grün, gelb, grau, gesperrt –
sie sagen etwas), Pfeile, Symbole und Punkte je Baum, „Unverteilte
Talentpunkte“, Primär/Sekundär, Suche, „Änderungen anwenden“.

**Nachgemessen (6.8.0.4).** Im Spiel war von 6.8.0.3 nichts zu sehen:
`/wcui fenster` meldete „Bäume keine gefunden“, und das Licht (7 %,
`BORDER` 7) lag unter Wolken und Landschaften. Seitdem:

- **Namen aus drei Quellen:** `GetTalentTabInfo`, `GetSpecializationInfo`
  (beide ersten Rückgaben, wenn Text) und – der Forever-Client nennt die
  Bäume über keine der beiden – die Bäume der **eigenen Klasse** aus
  `data/specs.lua` (`WeintCodex.Specs.ForClass`, `UnitClass("player")`).
  Die Namen dort stehen fest (siehe Kopf der Datei); geraten wird keine
  Lage. Suche bis Tiefe 6.
- **Bericht mit Hinweis:** findet die Suche nicht alle, nennt
  `/wcui fenster` darunter „gesucht: … (aus …)“ und bis zu sechs
  Schriftzeilen des Fensters samt Rahmen – dann sagt die nächste Messung,
  wie die Bäume dort heißen.
- **Licht und Kante über den Wolken:** `OVERLAY` 6/7 des Talentfensters.
  Die Talente liegen in `.ButtonsParent` (Kindrahmen) und damit darüber.
  Licht 16 % über 220 px (`TL.LIGHT_ALPHA`) – über hellgrauem Nebel färbt
  `GC.classLight` (7 %) sichtbar nichts.

**Nachgemessen (6.8.0.5).** Die Namen wurden gefunden („Bäume „Furor“,
„Waffen“, „Schutz““), im Spiel zu sehen war aber nur die Raute: eine
Linie mit 55 % und ein deckender Hauch von 16 % gehen im hellgrauen,
bewegten Nebel unter. Seitdem liegt jede Zeile eines Baums (Symbol, Name,
Linie) auf einem **dunklen weichen Grund** (`GC.shadowSoft` × `TL.BACK`
= 60 %, `ARTWORK` −8 am Rahmen des Namens – über dem Nebel, unter Raute
und Text), die Linie hat 90 % und 200 px, und das Licht oben wird
**additiv** gezeichnet (`ADD`): es hellt den Nebel in der Klassenfarbe auf,
statt ihn nur zu tönen. Die Animation selbst bleibt unberührt – der Grund
deckt nur die Zeile ab, nicht die Bäume. `/wcui fenster` nennt den Rahmen,
an dem die Zeilen hängen.

**Nachgemessen (6.8.0.7).** Der Grund von 6.8.0.5 reichte vom Symbol
bis zum Ende einer 200-px-Linie – rund 330 px, weit rechts über den Baum
hinaus, als harter Balken (Beta-Test: „verrückt nach rechts“). Seitdem:
zwei Verläufe in Schwarz (18 px von null auf 55 %, dann auf null), **feste
Breite** `TL.ROW` = 220 px ab 64 px links vom Namen (das Symbol liegt
darauf) – etwa die Breite eines Baums –, nur links verankert. Die Linie
füllt, was der Name übrig lässt (`TL.LineWidth`), und endet 24 px vor dem
Ende des Grunds. Ob ein Baum breiter oder schmaler ist, weiß das Modul
nicht; es rechnet mit vier Talenten nebeneinander.

### Gespräche in Gold *(6.8.0.4, `ui/gossip.lua`)*

Beta-Test (6.8.0.3, Krieger): über dem Gespräch mit einer Stadtwache lag
ein brauner Verlauf – der **Schein der Klasse** (`W.AddGlow`, 260 px). Ein
Gespräch gehört nicht zur Klasse. **Gemessen** (`/wcui fenster`):
`GossipFrame` mit `.GreetingPanel` (`.ScrollBox.ScrollTarget` mit den
Optionen, Sprechblase Bild 136810; `.ScrollBar` mit
`minimal-scrollbar-*`), `GossipFrameCloseButton`.

`GossipFrame`, `QuestFrame`, `ItemTextFrame` stehen in `S.SCOPES` als
`S.CALM` und in `W.HOSTED` (`WeintCodex.UIGossip`):

- **Grund:** Schein der Klasse aus (`W.HoldGlow` – Stil in Gold), statt
  dessen neutrales Licht (`GC.atmosLight`, 90 px) und oben eine Kante in
  Gold – wie Spielmenü und Dialoge.
- **Gespräch auf Fläche:** Begrüßung und Optionen
  (`GreetingPanel.ScrollBox`) auf der angehobenen Fläche der Register
  (`GC.surfaceRaised`) mit weichem Schatten und Kante in Gold; die
  Bildlaufleiste ist die untere rechte Ecke. Aus, wenn die Liste zu ist.
- **Questtext:** gemessen 05.10.2026 (Quest annehmen) – nichts mehr vom
  Spiel zu sehen außer Bildlauf, Knöpfen und Geld; lesbar. **Bücher,
  Briefe:** ungemessen – nur Grund und Kante, keine geratene Fläche.

**Unverändert:** Texte, Symbole der Optionen, Farben der Quests (samt
`W.LightCodes`), Bildlaufleiste, „Lebt wohl“.

### Händler in Gold *(6.8.0.6, `ui/merchant.lua`)*

Beta-Test (6.8.0.4): „wenn ich beim NPC kaufe oder verkaufe, ist da noch
das alte Design“. **Gemessen** (`/wcui fenster`): `MerchantFrame`,
`MerchantItem1…` mit `…ItemButton`, `MerchantFrameTab1/2`
(`uiframe-tab-left/-right`, `uiframe-activetab-left/-right`),
`MerchantMoneyInset` (Leder, Bild 374154), `MerchantMoneyBg` (Bild
525911, dreiteilig), `MerchantBuyBackItemItemButton`, Reparieren und
„Müll verkaufen“ als Zaubersymbole.

- **Grund:** `S.CALM` – Schein der Klasse aus, neutrales Licht, oben
  Kante in Gold (wie das Gespräch, aus dem man meist kommt).
- **Waren:** eine Fläche (`GC.surfaceRaised`, Schatten, Kante in Gold)
  von `MerchantItem1` bis zur **letzten sichtbaren** Ware – Händler 10,
  Rückkauf 12. Neu verankert nur, wenn die letzte wechselt.
- **Geld:** `MerchantMoneyInset` wird über `W.OwnBackground` eine
  Innenfläche, `MerchantMoneyBg` verliert seine Bilder.
- **Reiter unten:** `W.SkinTab(tab, accent, sel)` – flach wie die Reiter
  oben, gewählt in Gold. Ein PanelTabButton sagt nicht, ob er gewählt
  ist; das Fenster merkt es sich (`selectedTab`, verglichen mit
  `tab:GetID()`). Kein Feld am Reiter wird geschrieben.

**Unverändert:** die Plätze selbst – samt Rot an Waren, die man nicht
benutzen kann (das färbt das Spiel am Platz, es trägt Bedeutung) –,
Symbole, Namen, Preise, Währungen, Reparieren, Müll verkaufen,
Blättern, Rückkauf-Platz.

**Speicher (6.8.0.6):** `K.Border` baute in `SetColor`/`SetShown`/
`SetAlpha` bei jedem Aufruf eine Liste seiner vier Kanten. `SkinTab`
setzt die Randfarbe in jedem Durchlauf – an jedem Reiter jedes offenen
Fensters lief also Müll an. Die Liste wird jetzt einmal gebaut.

### Beute und Optionen *(6.9.0.0, `ui/loot.lua`, `ui/calm.lua`)*

Beta-Test mit `/wcui fenster`: das Beutefenster (`LootFrame`) mit
Metallrahmen, Sand (`UIFrameBackground-NineSlice-*`) und je Gegenstand
einer Karte mit Grund, Rahmen und Etikettrahmen; die Optionen des Spiels
(`SettingsPanel`) mit Metallrahmen, braunem Innenrahmen
(`Options_InnerFrame`) und braunen Kategorie-Balken
(`Options_CategoryHeader_1..3`). Beide stehen jetzt in `W.WINDOWS` und
tragen Gold (`S.CALM`):

* **Beute** (`ui/loot.lua`): Kachel, Titel hell, Licht und Kante in Gold,
  die Liste (`LootFrame.ScrollBox`) auf `surfaceRaised` mit Schatten und
  Kante. Die Karten verlieren Grund, Rahmen **„Normal“** und
  Etikettrahmen – ein anderer Rahmen (Qualität, Maus) und das Etikett
  selbst („Schlecht“) bleiben, ebenso Namen in Qualitätsfarbe.
* **Optionen** (`ui/calm.lua`, `LF.INSETS`): Kategorien links und
  Einstellungen rechts werden Innenflächen mit Kante in Gold; die
  Kategorien sind Abschnitte mit Raute und Linie (`W.HEADER_ATLAS`), der
  Titel „Optionen“ (`NineSlice.Text`) hell. Schalter, Haken, Regler,
  Auswahl, Tastenbelegung, Suche und die Wahl links (`Options_List_Active`)
  bleiben, wie das Spiel sie zeichnet. Geändert werden nur Bilder – kein
  Skript und kein Feld am Fenster (die Optionen tragen geschützte
  Tastenbelegungen).
* Das rote Kreuz zum Schließen bleibt wie in allen anderen Fenstern.

### Makrofenster *(6.9.0.0, `ui/macroframe.lua`)*

Gemessen mit `/wcui fenster`: `MacroFrame` (Marmor, Bild 374155),
`MacroFrameInset` (Leder, 374154), Metallrahmen, Streifen, Portrait,
Steinplätze (Bilder 130764 und 130718, je 18 Plätze plus das gewählte
Makro), das Textfeld im Rahmen des Tooltips, Reiter des Spiels. Gold
(`S.CALM`): Hülle wie jedes Fenster, Liste und Textfeld als Innenflächen
(`LF.INSETS`, Kante in Gold), Plätze flach mit 1 px Rand (Symbol und
Goldrahmen der Wahl bleiben), Reiter flach, der gewählte in Gold. Die
Knöpfe flacht der allgemeine Durchlauf ab. Nur Bilder – Makros anlegen
ist geschützt.

### Handel *(6.9.0.2, `ui/trade.lua`)*

Gemessen mit `/wcui fenster` (Beta-Test 6.9.0.1): `TradeFrame` (Marmor
374155, Trennleiste „!UI-Frame-LeftTile“, Metallrahmen, Streifen, zwei
Porträts RTPortrait1), sechs Innenflächen (Leder 374154, NineSlice
„_UI-Frame-InnerTopTile/BotTile“), je Seite sieben Plätze mit Bildern
136796 und 130766 am Platz, 130841 und 130718 am Knopf (je 14×), 137072
am siebten Platz („Wird nicht gehandelt“), Grund des Gelds beim
Gegenüber (`TradeRecipientMoneyBg`, 525911), Knöpfe mit 130826/130828.
Gold (`S.CALM`): Hülle wie jedes Fenster (`W.WINDOWS`), Kante oben in Gold,
die beiden Namen hell; Innenflächen über `.Bg` + `.NineSlice` erkannt
(`W.OwnBackground`, Kante und Schatten aus `ui/calm.lua`), das Geld
ebenso. Plätze (`TR.SLOT_FILES`) aus, der Knopf (130718) flach mit 1 px
Rand; das Namensfeld (136796) wird eine flache Leiste.
**Das Symbol eines Gegenstands bleibt immer:** Symbolregionen (`.icon`,
`.Icon`, „…IconTexture“) werden nie angefasst, und eine ausgeblendete
Region, die später ein anderes Bild zeigt, wird wieder sichtbar
(`TR.hidden`, je Durchlauf geprüft). Ungemessen: welches der drei Bilder
Rand, Stein oder leerer Platz ist (alle gehen), und ob „Handeln“ und
„Abbrechen“ Left/Middle/Right tragen (dann flach).

### Auktionshaus *(6.9.0.4, `ui/auction.lua`)*

Gemessen mit `/wcui fenster` (Beta-Test 6.9.0.3, Reiter „Kaufen“):
`AuctionHouseFrame` (Marmor 374155, Metallrahmen, Streifen, Porträt), die
Kategorien links („auctionhouse-nav-button“, 9×) auf
„auctionhouse-background-categories“, die Ergebnisliste auf
„auctionhouse-background-index“, Spaltenköpfe aus Holz (Bild 131139, 9×)
mit Sortierpfeil (136580), Reiter „uiframe-tab-*“, Geld unten links
(`MoneyFrameBorder` 525911, `MoneyFrameInset` 374154), „Suchen“
(130828). Gold (`S.CALM`, Gast in `ui/calm.lua`): Hülle wie jedes
Fenster; Kategorien als kleine Kacheln wie an Gilde & Communitys
(`W.NavEntry`, die gewählte mit Rand in Gold); jeder Grund
„auctionhouse-background-*“ weg, an seiner Stelle eine Innenfläche mit
Schatten und Kante in Gold; Spaltenköpfe flach mit 1 px Rand, der
Sortierpfeil bleibt; Geld als Innenflächen; Reiter flach, der gewählte in
Gold. Nur Bilder – Bieten und Kaufen sind geschützt. Gemessen 05.10.2026:
„Kaufen“ mit leerer Liste ohne Rest des Spiels (die feinen Innenränder
der Listen bleiben). Ungemessen: „Verkaufen“, „Auktionen“ und die Zeilen
einer gefüllten Liste.

### Bank *(6.9.1.1, `ui/bank.lua`)*

Gemessen mit `/wcui fenster` (Beta-Test 6.9.1.0): `BankFrame` (Marmor
374155, Metallrahmen, Porträt, Streifen, „bank-frame-background“,
„bank-divider“), `BankPanel.EdgeShadows` („_bank-frame-horiz-shadow“,
„!bank-frame-vert-shadow“), 48 Plätze („bags-item-bankslot64“,
„bank-frame-item-slotframe“, Rand Bild 130718), acht Taschenplätze
(„bank-frame-bag-slot-bg“, „bank-frame-bag-slotframe“, Schloss
„bankslot-icon-lock“), Geld (`BankPanel.MoneyFrame.Border`, 525911),
Seitenreiter („common-sidetab“). Gold (`S.CALM`, Gast in `ui/calm.lua`):
Hülle wie jedes Fenster; der Grund weg, an seiner Stelle eine Innenfläche
mit Schatten und Kante in Gold; Trennleiste und Randschatten weg; Plätze
und Taschenplätze flach mit 1 px Rand wie im Handel – Symbol, Rand der
Qualität, Überlagerung und das Schloss eines ungekauften Platzes bleiben,
und was später ein anderes Bild zeigt, wird wieder sichtbar; Geld als
Innenfläche; Seitenreiter als Kacheln, der gewählte in Gold. Nur Bilder.

**Gildenbank** (`GuildBankFrame`, erst beim Öffnen geladen): Hülle und
Gold über `W.WINDOWS`/`ui/calm.lua`, seit 6.10.4.2 dazu aus Bausteinen
(`WeintCodex.UIGuildBank` in `ui/bank.lua`). Gemessen 05.10.2026 (ohne
Befugnis für die Fächer): Reiter unten `GuildBankFrameTab1–4`
(„uiframe-tab-*“) → flach, gewählt nach `selectedTab`; Goldrahmen um
„Verfügbarer Betrag“ (525911, `GuildBankFrameLeft/Middle/Right`) → Leiste
ohne Rand; goldene Flügel am Wappen (132069, `Emblem.Left/Right`) → weg.
Seit 6.10.4.3 auch das Wappen selbst (`GuildBankEmblemBackground*`,
`GuildBankEmblem*`, `GuildBankEmblemBorder*`, je Ecke) – Beta-Test: ohne
Flügel ragte es allein über die Kachel und „sieht oben in der Mitte
ziemlich blöd aus“. In Gilde & Communitys bleibt es (dort im Fenster).
**Ungemessen:** Fächer und Plätze – `/wcui fenster` mit Befugnis.

### Post *(6.9.1.2, `ui/mail.lua`)*

Gemessen mit `/wcui fenster` (Beta-Test 6.9.1.1, beide Reiter):
`MailFrame` (Marmor, Metallrahmen, Streifen, Symbol des Briefkastens
`PortraitContainer` 136382), `MailFrameInset` (Leder 374154), Pergament
im Posteingang (`InboxFrame`, 530419) und hinter dem Brief
(`SendMailScrollFrame`, 136859/136860), Rahmen der Zeilen (`MailItem1`,
136383), Anhänge (`SendMailAttachment1`: Stein 130862, Rand 130718),
Eingabefelder mit Goldrand (130975, An/Betreff/Geld), Trennleisten
(`SendMailFrame`, 130968), Geld (`SendMailMoneyBg`, 525911), Reiter
(`MailFrameTab1/2`, „uiframe-tab-*“). Gold (`S.CALM`, Gast in
`ui/calm.lua`): Pergament weg, an seiner Stelle Innenflächen – die Schrift
des Briefs (`SendMailBodyEditBox`) war auf Pergament dunkelbraun und wird
hell, aber erst, wenn das Pergament wirklich weg ist; Zeilen- und
Anhangknöpfe flach mit 1 px Rand, Symbole bleiben; Felder als flache
Leisten; Trennleisten und Briefkasten weg; Geld und Innenfläche wie
überall; Reiter flach, der gewählte in Gold. Nur Bilder und Schriftfarben.

**Fläche nie über das Fenster (6.10.4.2).** Beta-Test: „ein
transparenter Rahmen, der neben dem Fenster liegt“. Das Pergament des
Posteingangs ist ein Bild von 512 × 512 und ragt über das Fenster; der
Rest war durchsichtig, unsere Innenfläche an seiner Stelle nicht.
`CP.Clamp` (`ui/calmparts.lua`) schneidet jede Innenfläche der Art `bg`
am Fenster ab: am Bild verankert, mit Abständen, wo es übersteht – beim
Ziehen gleich, gesetzt nur bei Änderung. Gilt für jedes Fenster aus
Bausteinen.

**Geöffneter Brief** (`OpenMailFrame`): nur Hülle und Gold – ungemessen;
sein Pergament sagt `/wcui fenster` bei offenem Brief.

### Kontakte *(6.10.1.0, `ui/friends.lua`)*

Das erste Fenster, das von Anfang an aus Bausteinen besteht
(`ui/calmparts.lua`). Gemessen mit `/wcui fenster` (Beta-Test 6.10.0.0,
Reiter „Freunde“): `FriendsFrame` (Marmor 374155, Metallrahmen
„UI-Frame-Metal-*“, Porträtring, Streifen, Symbol 526421),
`FriendsFrameInset` (374154), Zeilen der Liste (Schein 136809),
`FriendsFrameAddFriendButton` (rot, 130828/130826),
`FriendsFrameBattlenetFrame` (blauer Kasten 632259),
`FriendsTabHeader.TabSystem` („uiframe-tab-*“),
`FriendsFrameStatusDropdown` („common-dropdown-textholder“).

| Teil | Wer | Was |
|---|---|---|
| Metall, Ring, Streifen, rote Knöpfe, Reiter oben | `W.WINDOWS` | weg bzw. flach, der gewählte Reiter in Gold |
| Symbol oben links (526421) | `decor` | weg |
| BattleTag (632259) | `field` | flache Leiste mit 1 px Rand |
| Status („common-dropdown-textholder“) | `field` | flache Leiste |
| Innenfläche der Liste | Bausteine | Innenfläche (`InsetFrameTemplate`) |
| Zeilen | – | bleiben: Farbe (BattleTag, Charakter, offline) und Schein unter der Maus sagen etwas |
| Reiter unten (`FriendsFrameTab1–4`) | `tabs` | flach, der gewählte in Gold; fehlende fallen heraus |

**Gemessen 05.10.2026:** „Kürzliche Verbündete“ und „Schlachtzug“ ohne
Rest des Spiels – was dort an Bildern bleibt, ist Inhalt (Einladen-Knopf
je Zeile, Trennlinien zwischen Name und Stufe, Häkchen „Alle Assistent“).
**Ungemessen:** Ignorierliste – Hülle und Gold; was dort alt aussieht,
sagt `/wcui fenster` auf dem Reiter.

**Das neue Kontaktfenster (6.20.0.0).** Blizzard hat die Kontakte neu
gebaut: `SocialUIFrame`, Reiter rechts statt unten, eine Karte je Freund,
Suche und Filter. Beta-Test: „Blizzard hat das Kontaktfenster neu gemacht.
Daher muss das angeglichen werden.“ – `/wcui fenster` fand es, aber in
keiner Liste: Metall, Porträt, roter Knopf und goldene Seitenreiter standen
alle als „SOLLTE WEG SEIN“ da. `FriendsFrame` bleibt eingetragen; was der
Client nicht hat, fällt heraus. Gemessen 07.10.2026 am Reiter „Freunde“:

| Teil | Wer | Was |
|---|---|---|
| Metall, Porträtring, `SocialUIFrameBg`, roter Knopf, Seitenreiter („common-sidetab*“), Kopfzeile der Liste | `W.WINDOWS` | Kachel, Knopf flach, Reiter als Kachel – der gewählte in Gold (über `selTex`, gemessen eindeutig) |
| Symbol oben links (526421) | `decor` | weg |
| Verlauf oben/unten („friends-frame-topTexBG“/„-bottomTexBG“) | `decor` | weg |
| Band hinter der BattleTag („friends-frame-infoBG“) | `decor` | weg |
| Blauer Kasten der BattleTag (632259) | `strip` | Leiste ohne Rand an seiner Stelle – nicht `field`: der Kasten liegt am Rahmen der ganzen Zeile (Status, BattleTag, Menü), die wäre mit Rand umzogen worden |
| Status („common-dropdown-textholder“), Suchfeld („common-searchbar-a“) | `field` | flache Leiste |
| Linien über/unter der Liste („perks-divider-short“) | `decor` | weg |
| Filterknopf („common-dropdown-b-button“) | – | bleibt: der Pfeil ist Teil des Bildes |
| Karten je Freund („friends-card-*“), Knopf zum Einladen | – | bleiben: grau heißt offline, die Wahl ist zu sehen; Tiefe 3, die Karten werden im Takt gar nicht abgelaufen |

Verschiebbar wie das alte (`MW.WINDOWS`), Licht und Kante in Gold über
`ui/calm.lua`. Eine Innenfläche hat das neue Fenster nicht (die Liste liegt
auf der Kachel) – `/wcui fenster` sagt dort „keine gefunden“, das ist
richtig. **Ungemessen:** die Reiter „Kürzliche Verbündete“, „Schlachtzug“,
„Anfragen“, und wie die Karten auf der Kachel wirken.

### Lehrer *(6.10.1.0, `ui/classtrainer.lua`)*

Gemessen mit `/wcui fenster` (Beta-Test 6.10.0.0, Magierlehrer), die
Dateinummern aufgelöst mit der Dateiliste der Community
(`wowdev/wow-listfile`), der Aufbau aus dem Quelltext des Spiels
(`Blizzard_TrainerUI.xml`, Mainline).

**Ein Bild, vier Rollen.** 404984 (`classtrainerframe/trainertextures`)
ist Pergament (`ClassTrainerFrame.BG`), Grund jeder Zeile
(`NormalTexture`), Schein unter der Maus (`HighlightTexture`) und
Markierung der gewählten Zeile (`selectedTex`) – nur andere Ausschnitte.
`/wcui fenster` zählt gleiche Bilder fensterweit zusammen („10×“) und
nennt den ersten Besitzer; nach Bildnummer zu sortieren wie an der Post
hätte die Markierung mitgenommen. Deshalb im `after` nach Rolle:

| Rolle | Was |
|---|---|
| Pergament (`BG`) | weg, darunter die Innenfläche |
| Grund der Zeile (`NormalTexture`) | weg, die Zeile flach mit 1 px Rand – Zeilen der `ScrollBox` (wiederverwendet: zeigt eine Zeile ein anderes Bild, wird es wieder sichtbar) und `skillStepButton` |
| Markierung, Schein, Grau (`disabledBG`), Symbol, Schloss | bleiben |
| Geldrahmen (`ClassTrainerFrameMoneyBg`, 237619) | weg, eine Leiste auf Ebene −6 am Fenster – eine Leiste der Bausteine (−8) läge unter der Kachel (−7) |

Metall, Ring, Porträt (`PortraitContainer`, ganz), Streifen, Knopf
„Ausbilden“: `W.WINDOWS`. Der Knopf „Optionen“ (Filter) bleibt wie in den
anderen Fenstern. **Berufslehrer** (gemessen 05.10.2026, Schmiedekunst):
oben die Leiste der Fertigkeit `ClassTrainerStatusBar` – Rahmen
`…Left/Middle/Right` (410251), Füllung UI-StatusBar (136570) in Blau. Seit
6.10.4.6 Rahmen weg, Füllung flach (`K.BAR_TEXTURE`) in Gold
(`frameAccent`, je Durchlauf nachgefärbt – das Spiel färbt beim
Aktualisieren neu), dunkle Rinne, 1 px Rand. Der Rest wie beim
Klassenlehrer; die gewählte Zeile trägt den goldenen Schein. 6.10.4.7
nahm auch `ClassTrainerStatusBarBackground` weg (gemessen mit 6.10.4.6,
Angeln 1/75: eine blaue Farbfläche des Spiels auf `BACKGROUND` 0, über
unserer Rinne). **Seit 6.10.4.8 wieder Blau** (Beta-Test: dunkel schlecht
zu erkennen, kein Wiedererkennungswert): Farbe der Füllung und blaue
Fläche bleiben die des Spiels, kein Nachfärben; weg bleibt nur der
Rahmen, flach bleibt die Füllung. Blau ist hier keine zweite Akzentfarbe,
sondern das Erkennungszeichen der Leiste – darum aus dem Spiel und nicht
als Ton in `core/ui.lua`.

### Fenster verschieben *(6.10.4.0, `ui/movewindows.lua`)*

Beta-Test: wie MoveAny, „nur Fenster, die man öffnet“, **ohne
Einstellung**, von vornherein an – auch ohne Hauptschalter der
Oberfläche (verschoben wird nur, was jemand zieht). MoveAny ist „All
Rights Reserved“: Verhalten übernommen, kein Code.

| Was | Wie |
|---|---|
| ziehen | linke Maustaste auf freier Stelle (Titel, Rand); am Bildschirm gehalten; danach `SetUserPlaced(false)` und Anker `TOPLEFT` an `UIParent BOTTOMLEFT` |
| solange offen | `MW.open[f] = { x, y }` (obere linke Ecke, nicht gespeichert); gesetzt bei `OnShow` und nach `UpdateUIPanelPositions` (ein zweites Fenster geht auf); nicht beim Ziehen, nicht bei vergrößerter Karte |
| zu (6.10.4.1) | an den Platz des Spiels (`MW.default`, erster Anker, gemerkt solange er nicht unserer ist) – nur wenn verschoben; geschützt im Kampf: danach. Beta-Test: „wieder dort, wo es eigentlich sein sollte“. Die dauerhaften Plätze von 6.10.4.0 (`ui.windowPos`) löscht `MW.Forget` beim Start |
| Kampf | geschützte Fenster weder ziehen, setzen noch einrichten; `PLAYER_REGEN_ENABLED` holt nach |
| zurück | Umschalt + Rechtsklick; `/wcui fenster zurück` alle offenen |
| welche | `MW.WINDOWS`, nur oberste (Eltern `UIParent`); `ADDON_LOADED` nimmt nachgeladene dazu |
| Vorrang | MoveAny oder BlizzMove geladen: WeintCodex tut nichts |

**Gemessen (05.10.2026, Client 1.60.1):** Ziehen, Schließen, Zurück an den
Platz des Spiels – außerhalb des Kampfes blockiert nichts. Im Kampf
ungemessen (geschützte Fenster warten ohnehin bis danach).

### Markieren per Mouseover *(6.10.4.1, `ui/hovermark.lua`)*

Beta-Test: „in einer Instanz per Mouseover über die Namensplakette die
NPCs markieren, einstellbar in WCui“. Seite **Automark** im Komfort.

**Nur Drüberfahren geht nicht:** Markieren ist für Addons geschützt
(gemessen 6.9.0.1, siehe Automark). Deshalb Maus über den Gegner **und
eine Taste**:

| Teil | Wie |
|---|---|
| Taste | `markHoverKey` (Standard `BUTTON3`, mittlere Maustaste), `SetOverrideBindingClick(…, true, …)` auf `WeintCodexHoverMarkButton` – nur wo markiert wird (`markHoverWhere`: Dungeons und Schlachtzüge / nur Dungeons / überall), nur außerhalb des Kampfes gesetzt und entfernt |
| Makro | `/tm [@mouseover,harm,nodead] n`, vorbereitet bei `UPDATE_MOUSEOVER_UNIT` |
| welche | erste freie in Totenkopf → Stern (`markHoverUse1..8`, unter „Erweitert“), ohne Tank/Heiler von Automark (nur wenn Automark an) |
| doppelt | je GUID gemerkt; schon von uns markiert → leeres Makro (dieselbe nähme sie ab). Von anderen gesetzte kennt Lua nicht (Index geheim) |
| Kampf | `PLAYER_REGEN_DISABLED` leert das Makro – im Kampf darf es sich nicht ändern, die Markierung wanderte sonst; ein Druck sagt es einmal |
| frei | nach dem Kampf: wer tot ist oder keine Plakette hat; Gebietswechsel: alle |

**Gemessen (05.10.2026, Client 1.60.1):** `/tm` aus dem Makro markiert, und
die Vorrang-Belegung auf der mittleren Maustaste greift.

### Würfeln um Beute *(6.10.3.1, `ui/lootroll.lua`)*

`GroupLootFrame1..4` (Bedarf/Gier/Passen) sind kein Fenster aus
`W.WINDOWS`: ein Toast, den das Spiel über `GroupLootContainer`
stapelt. Gestaltet einmal je Rahmen aus `W.Apply` (wie die Dialoge,
`W.SkinPopup`), Gold (`S.CALM`).

| Teil | Was |
|---|---|
| `.Background`, `.Border` (`Interface\LootFrame\LootToast`) | weg; Kachel, Licht und Kante in Gold |
| Symbol, `IconFrame.Border` (`loottoast-itemborder-*`) | beschnitten; Rand des Spiels weg, 1 px in der Qualität ab „Selten“, sonst schwarz – wie in den Taschen |
| `.Name` | Schrift der Oberfläche, 134 px; die Farbe der Qualität setzt das Spiel |
| `.Timer` | flach in Gold, dunkle Rinne, 1 px Rand; **bei jedem Zeigen über die Kachel** – das Spiel setzt sie in `GroupLootFrame_OnShow` eine Ebene unter das Fenster, wo der Toast ein Loch hatte |
| Bedarf, Gier, Passen, Transmog, Würfel-Animation | unverändert |

**Ungemessen.** Gebaut nach `Blizzard_UIPanels_Game/Mainline/GroupLootFrame.xml`
und einem Bildschirmfoto; `/wcui fenster` im Beta-Test kam zu spät (nur
`BottomManagedFrameContainer`, kein Bild). Über einem laufenden Wurf nennt
`/wcui fenster` jetzt auch die Zeile „Würfeln um Beute“. `BonusRollFrame`
(Bonuswurf) ist nicht gestaltet – ob Forever ihn hat, ist offen.

### Symbol an der Minikarte *(6.9.0.0, `ui/launcher.lua`)*

Mit Oberfläche ein zweites Symbol („WeintCodexUI“, seit 6.9.0.3 das
WCUI-Logo, vorher ein Zahnrad) neben dem von WeintCodex: Linksklick `/wcui`, Rechtsklick Gestaltungsmodus (nie im
Kampf). Ohne Oberfläche gibt es keins; der Hauptschalter blendet es
sofort ein oder aus (`K.Listen`, `general.enabled`). Abschaltbar auf
`/wcui` → Allgemein, gespeichert in `ui.launcher` (dort führt LibDBIcon
auch den Platz). Über LibDBIcon landet es auch in der Knopfspalte der
Minikarte.

**Das Logo** *(6.9.0.3)* – vom Projektinhaber vorgegeben, Quelle
`.github/scripts/logo/wcui.png`, gebaut mit `.github/scripts/make_logo.py`:
`media/ui/logo_32.tga` (Minikarte, ganz gezeigt über `iconCoords =
{0,1,0,1}`, und im Tooltip) und `logo_64.tga` (oben links im
Willkommens-Assistenten, 64 px; vor „WeintCodex“ in der Seitenleiste von
`/wcui`, 40 px). Sparsam eingesetzt, mit Absicht: ein Wappen mit Grün,
Violett und rissigem Gold ist ein Markenzeichen, keine Fläche – auf
Hintergründen oder in Fenstern des Spiels widerspräche es der ruhigen
Oberfläche. `load_test.lua` prüft, dass jede Grafik, die `ui/` über
`K.MEDIA` anfordert, in `media/ui` liegt.

### Brücke zum Bearbeitungsmodus des Spiels *(6.9.0.5, `ui/editmode.lua`)*

Zwei Modi, zwei Zuständigkeiten: der **Gestaltungsmodus** verschiebt, was
WeintCodex baut (Einheiten- und Gruppenrahmen, Schadensanzeige,
Questpfeil, Taschen …); der **Bearbeitungsmodus des Spiels**, was das Spiel
stellt – Aktionsleisten, Minikarte, Buffs, Questliste,
Abklingzeitmanager, Chat, die Gruppenrahmen des Spiels. WeintCodex
schreibt dessen Einstellungen nicht (ein Addon, das sie schreibt, macht
den Modus kaputt, siehe Einrichtung). Bis 6.9.0.4 stand dafür nur ein Satz
„Esc → Bearbeitungsmodus“ da; jetzt führt ein Knopf hinüber:

* in der Leiste des Gestaltungsmodus („Bearbeitungsmodus des Spiels“,
  die Leiste wird so breit wie ihre Knöpfe),
* auf `/wcui` → Allgemein neben „Gestaltungsmodus“,
* auf jeder Seite, deren Rahmen das Spiel stellt: Aktionsleisten (zwei
  Seiten), Minikarte, Questliste, Abklingzeitmanager, Gruppenrahmen –
  `Builder:GameEditMode(note)` (Satz + Knopf) bzw. `gameEditMode = true`
  an einer Knopfzelle.

**Zurück:** Wer aus dem Gestaltungsmodus oder dem Einstellungsfenster
kam, ist nach dem Schließen wieder dort (`E.bridge.from`), aus dem Fenster
auf derselben Seite; kam man über Fenster → Gestaltungsmodus, geht nach
„Fertig“ auch das Fenster wieder auf (`reopen`). Solange der Modus des
Spiels offen ist, steht darunter eine kleine Leiste
(`WeintCodexGameEditBar`, nur mit Oberfläche): wohin Schließen führt, und
der **Knopf zurück** „Zum Gestaltungsmodus“ – auch für den, der über Esc
hineinkam. Gesetzt als Zahlen unter dem Fenster des Spiels, nicht daran
verankert (ein Rahmen, der an einem des Spiels hängt, erbt dessen Schutz).
Geht der Modus nicht auf (Kampf, kein Befehl), ist man nach 0,3 s wieder,
wo man war, mit einem Satz im Chat.

**6.9.0.7, Beta-Test – Rückweg ins Fenster ging verloren.** Das Spiel
schließt beim Öffnen seines Bearbeitungsmodus selbst Fenster, auch das
Einstellungsfenster (es steht in `UISpecialFrames`, damit Esc es
schließt). Bis 6.9.0.6 sah der Knopf erst *nach* dem Klick nach, woher man
kam – da war das Fenster schon zu und der Rückweg leer. Jetzt zwei
Schritte: `E.NoteOrigin` im `PreClick` merkt den Ausgangsort samt Modul,
Seite und Bildlauf des Fensters (`O.Where`), `E.MakeRoom` im `PostClick`
räumt auf. Zurück geht es mit `O.Return` genau auf diese Seite und
Bildlaufposition – auch über den Umweg Gestaltungsmodus → „Fertig“
(`E.reopenWhere`). `load_test.lua` bildet das Schließen durch das Spiel
nach.

**Wie zurück:** WeintCodex schließt den Modus des Spiels nie selbst
(`HideUIPanel` aus Addon-Code: Taint, und die Rückfrage bei
ungespeicherten Änderungen käme womöglich nicht). Über dem Knopf liegt ein
`SecureActionButtonTemplate` mit `type = "click"` und `clickbutton =
EditModeManagerFrame.CloseButton` – das Spiel schließt, als hätte man sein
X angeklickt, samt Rückfrage. `PreClick` merkt den Rückweg (`design`, aus
dem Fenster gekommen: `reopen`), aufgehen tut der Gestaltungsmodus erst in
`OnHide` – bricht man die Rückfrage ab, bleibt alles, wie es war, bis man
schließt. Ohne `CloseButton` merkt der Knopf nur den Rückweg und sagt im
Chat, was zu tun ist. Weil die Leiste damit einen geschützten Knopf trägt,
blendet WeintCodex sie beim Kampfbeginn aus (`PLAYER_REGEN_DISABLED`, vor
der Sperre), sonst erst nach dem Kampf.

**Wie geöffnet wird:** Gibt es den Befehl des Spiels (`SLASH_EDITMODE1`
samt `SlashCmdList.EDITMODE`), liegt über dem Knopf ein
`SecureActionButtonTemplate` mit `type = "macro"`,
`macrotext = "/editmode"` – das Spiel öffnet seinen Modus selbst, kein
Addon-Code ruft `EditModeManagerFrame` auf (Taint: über ihn ordnet das
Spiel geschützte Leisten). Platz gemacht wird erst in `PostClick`, weil
der Knopf in der Leiste liegt, die dabei zugeht. Ohne Befehl öffnet
WeintCodex direkt (`ShowUIPanel`). Welcher Weg gilt, sagt `/wcui
einrichten prüfen` (letzte Zeile). **Ungeprüft auf Forever:** ob es
`/editmode` gibt, ob der direkte Weg Folgen hat und ob das Fenster des
Spiels sein X als `CloseButton` führt.

### Nächste Fenster

Vorgesehen: Berufsübersicht (nach Messung), Gilde (mittlere Atmosphäre), Talente
(Klassenfarbe). Migrieren heißt: Name in
`S.SCOPES`, ein Modul nach dem Muster von `ui/reputation.lua` nur dort,
wo das Fenster mehr braucht als die Bausteine.
