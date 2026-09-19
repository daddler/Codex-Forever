# Changelog

Alle nennenswerten Änderungen an **WeintCodex — Forever Edition** werden hier
festgehalten. Format lose an [Keep a Changelog](https://keepachangelog.com/)
angelehnt; Versionsnummern folgen dem 4-teiligen Schema
(`MAJOR.MINOR.PATCH.BUILD`), nicht SemVer.

Die Fassung für *Mists of Pandaria Classic* (`daddler/WeintCodex`) hat ihren
eigenen Changelog und ihren eigenen Update-Kanal. Die beiden Zweige laufen
nicht zusammen.

## [5.1.0.0] – 2026-09-19

**Die Dungeons sind da — alle neun.** Ein eigener Punkt in der
Navigation, mit Gebiet und Stufenbereich zu jeder Instanz: von *Hall of
Thanes* unter Eisenschmiede (13–18) bis *Shaper's Terrace* im Krater
von Un'Goro (58–60). Ob die eigene Stufe passt, steht im Detailbereich —
und wenn der Client keine Stufe nennt, steht dort „noch nicht bekannt"
und nicht „passt nicht". Die Suche findet Dungeons über Namen **und**
Stufenbereich.

**Tank, Heiler und Schaden haben einen eigenen Bereich bekommen.** Zu
jeder Instanz steht, wie viele Plätze jede Rolle hat und welche
Talentbäume sie tragen können; zu jedem Boss, was der Discord-Bot an
Taktik geliefert hat. Das Format dafür gibt es seit jeher
(`WCIMPORT:BOSS` trägt genau diese drei Rollenfelder) — sichtbar wird es
mit den Bosslisten.

Drei Bestände, die dabei **nicht** zusammenfallen: welcher Baum welche
Rolle trägt (bekannt), wie viele Plätze eine Rolle hat (für Fünfergruppen
bekannt, für Schlachtzüge nicht) und was eine Rolle an einem Boss tut
(für keinen Kampf in Forever bekannt). *„Tank: dreh den Boss weg"* wäre
billig zu haben, passte zu jedem Spiel und zu keinem Kampf in Forever.
Steht nicht drin.

**Barrow Deeps und Hyjal Summit haben Bosslisten — vorläufig.**
Einundzwanzig Bosse, anklickbar, mit Fortschritt und Rollen-Tipps. Sie
stammen aus dem Beta-Client (Build 1.60.1.69876 vom 17.09.2026) und sind
von Blizzard nicht bestätigt; Namen und Reihenfolge können sich bis zum
Erscheinen ändern.

Das ist **kein Bruch** der Regel, die diese Fassung ausmacht, sondern ihr
Ergebnis. Die Regel lautete nie „hier darf nichts stehen", sondern: es
darf nichts dastehen, dessen Herkunft sich nicht benennen lässt. Genau
deshalb durften die Listen aus Mists of Pandaria nicht hierher. Jede
gefüllte Bossliste trägt jetzt ihre Quelle mit sich, und eine
vorläufige wird überall als vorläufig ausgewiesen — im Seitenkopf, im
Detailbereich, auf der Übersicht und in der Diagnose. Eine Bossliste
ohne Herkunft lässt den Prüflauf durchfallen.

**Onyxias Hort bleibt leer, die Dungeonbosse auch.** Dass Onyxia die
einzige Bossin ihres Horts ist, weiss jeder aus zwanzig Jahren Azeroth —
im Beta-Client steht dazu trotzdem keine Liste, und Blizzard hat nichts
gesagt. „Weiss man doch" ist keine Quelle. Bei den Dungeons liegen Namen
für einen Teil vor, für andere keine, und die vorhandenen widersprechen
sich zwischen den Builds; eine Liste, die vier Dungeons stillschweigend
als bosslos führte, wäre schlechter als gar keine.

**Die Bossliste rollt.** Dreizehn Bosse passen nicht in eine Karte. Ohne
Bildlauf verschwände der Rest unten aus dem Fenster — unsichtbar und
unerreichbar, ausgerechnet dann, wenn am meisten dasteht.

**Ausserdem:** die Einführung hat ein Kapitel über Instanzen und Rollen
bekommen, `/wc dungeons` führt direkt hin, und die Diagnose unter
*Einstellungen* zählt Dungeons und Dungeonbosse getrennt — weil sie einen
anderen Zustand haben als die Schlachtzugsbosse.

> **Hinweis zur Navigationsspalte:** mit den Dungeons steht sie bei elf
> Einträgen (634 px von 684 verfügbaren). Der nächste Eintrag passt nicht
> mehr, ohne dass die Spalte einen Bildlauf bekommt.

## [5.0.0.0] – 2026-09-18

**WeintCodex gibt es jetzt für World of Warcraft: Forever.**

Eigenes Addon, eigenes Repository, eigener Update-Kanal. Die Fassung für
Mists of Pandaria Classic läuft unverändert weiter.

Diese Fassung ist aus der MoP-Fassung hervorgegangen — durch **Wegnehmen,
nicht durch Neubau**, genau wie WeintCompanion 5. Die Oberfläche, die
Companion-Brücke, das Zugriffsprofil, die Anmeldeliste, der Kalender, die
Materialien und der Gruppencheck sind dieselben, erprobten Teile. Was an
Zahlen aus Mists of Pandaria hing, ist weg.

**Neues Aussehen („Graphit").** Ruhiger, neutraler und eine Spur kühler
Grund, eine Serifenschrift (Newsreader) für Überschriften, IBM Plex für
alles Bedienbare und Zahlen — und genau **ein** Akzent, der ausschliesslich
Bedeutung trägt. Dasselbe Bild wie in WeintCompanion; die Farbwerte sind
die Übersetzung von dessen `gui/theme/tokens.py`.

**Was wegfällt, und warum.** Simmen, WeakAuras, Sockelsteine,
Verzauberungsempfehlungen, Umschmieden, Tempo-Schwellen, BiS-Listen, der
Rotationshelfer, die Academy und WeintTV sind **nicht** dabei. Sie hingen
alle an Zahlen aus Mists of Pandaria — Spec-Profile, Statgewichte, Caps,
Sockelboni, Bossmechaniken. Für Forever sagt keine davon etwas aus, und
eine übernommene Bewertung hätte nicht geschwiegen, sondern jedem Spieler
Mängel vorgeworfen, die es in seinem Spiel gar nicht gibt.

**Die Bosslisten sind leer, und das mit Absicht.** Benannt sind die drei
Schlachtzüge des Erscheinungsinhalts — Barrow Deeps (10), Hyjal Summit (20),
Onyxias Hort (40) — und ihre Gruppengrösse, sonst nichts. Die Seite
*Schlachtzüge* sagt deshalb „noch nicht bekannt" statt „0 Bosse", und es
gibt dort keinen Fortschrittsbalken bei null Prozent. Was der Server
wirklich beantwortet — ob dieser Charakter eine gespeicherte ID trägt —
steht trotzdem da.

**Was bleibt:**

* *Übersicht* — was heute Abend zu tun ist, in drei Spalten.
* *Schlachtzüge* — Instanzen, gespeicherte IDs, Bossnotizen des Bots.
* *Anmeldung* — wer sich für Mittwoch und Donnerstag eingetragen hat.
* *Kalender* — Termin und Ingame-Einladung.
* *Gruppencheck* — Ausrüstung der ganzen Gruppe vor dem Pull.
* *Charakter* — was angelegt ist, und welche Twinks der Bot kennen soll.
* *Materialien* — Gildenbank-Bestand.
* *Import* — der `WCIMPORT:`-Weg aus Discord.
* *Companion* — Zustand der Brücke, in Klartext.
* *Einstellungen* — Fenster, Diagnose, Zugriffsprofil.

### Technisch

**Neue Dateien.** `data/raids.lua` (drei Schlachtzüge, leere Bosslisten mit
Zugriffsfunktionen, die „unbekannt" von „keine" trennen), `data/specs.lua`
(neun Klassen mal drei Talentbäume, Spiegelung von
`analyzer/data/specs.py` der Companion), `modules/raidpages.lua`,
`modules/companionpage.lua`.

**`modules/charakter.lua`** ist vollständig neu und von rund 7 900 auf gut
400 Zeilen geschrumpft. Die Ausrüstungsplätze werden über
`GetInventorySlotInfo` beim Client erfragt statt fest verdrahtet — ob es in
Forever einen Distanzplatz gibt, weiss der Client und nicht diese Datei.
`Snapshot()` liefert `nil`, wenn der Client nicht antwortet; das ist etwas
anderes als eine leere Ausrüstung, und die Übersicht unterscheidet das.

**`modules/groupcheck.lua`** zählt statt Verzauberungen und Sockeln jetzt
leere Plätze, zerbrochene Gegenstände und die durchschnittliche
Gegenstandsstufe. Eine unbekannte Stufe fällt aus dem Durchschnitt heraus,
statt ihn nach unten zu ziehen.

**`modules/companion.lua`** sendet `character_sheet` weiterhin, lässt aber
die Abschnitte ZÄHLER und BIS leer und die Felder `score`, `grade` und
`quality` unbesetzt. Der Vertrag sieht das ausdrücklich vor: `readiness()`
auf der Companion-Seite liefert dann `None` statt `0.0` — ein leerer Ring
statt eines roten.

**`modules/materials.lua`** führt keine Beobachtungsliste mehr. Ohne sie
nimmt der Gildenbankscan auf, was wirklich in den Fächern liegt, und setzt
**kein** Soll. Ein Posten ohne Soll bekommt keinen Statuspunkt und keinen
Balken — bis 3.x rechnete diese Stelle `pct = 0` und stellte jeden solchen
Posten rot als Engpass dar.

**Zwei kopflose Prüfläufe** unter `.github/tests/`, beide in der CI:
`load_test.lua` lädt das ganze Addon gegen eine Attrappe des Clients in der
Reihenfolge der `.toc`, `data_test.lua` prüft die Datentabellen und die
Fassungsangaben. Sie sind für dieses Repo wichtiger als für die
MoP-Fassung: es gibt kein Spiel, in dem sich etwas ausprobieren liesse.

**Die Schnittstellennummer `120000` in der `.toc` ist eine benannte
Vermutung.** Forever ist nicht erschienen. Stimmt sie nicht, gilt das Addon
als veraltet und lädt nur mit gesetztem Haken — eine Zeile, die dann zu
ändern ist.
