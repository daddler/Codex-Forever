# Changelog

Alle nennenswerten Änderungen an **WeintCodex — Forever Edition** werden hier
festgehalten. Format lose an [Keep a Changelog](https://keepachangelog.com/)
angelehnt; Versionsnummern folgen dem 4-teiligen Schema
(`MAJOR.MINOR.PATCH.BUILD`), nicht SemVer.

Die Fassung für *Mists of Pandaria Classic* (`daddler/WeintCodex`) hat ihren
eigenen Changelog und ihren eigenen Update-Kanal. Die beiden Zweige laufen
nicht zusammen.

## [5.2.0.1] – 2026-09-21

**Die Dungeonseite ist eine Seite, keine vier Spalten.** Bis hierher
teilten sich Navigation, ein Baum aus Stufen, Instanzen *und* Bossen,
ein 212 px schmaler Inhalt und ein Detailbereich rechts die
Aufmerksamkeit — und die Bosskarte in der Mitte sagte, dass die Bosse
links stehen. Jetzt führt die Spalte links nur noch Dungeons, nach
Stufe; die Seite selbst hat die volle Breite und liest sich von oben
nach unten: Kopf (Name, Stufe, Gruppe, Bosse, und ob die eigene Stufe
passt), die **Bosse als nummerierte Pillen** in einer Zeile (bei
Flügeln ein Reiter je Flügel), darunter **eine** Karte — die
Aufstellung, oder nach einem Klick auf eine Pille der Boss: wo er
steht, wie er kommt, was die Rollen tun. Der Detailbereich rechts
bleibt auf dieser Seite zu.

Die Aufstellung nennt zu jeder Rolle die Plätze und die Talentbäume
**nach Klasse gruppiert** statt als Liste von zwanzig Zeilen. Zu einem
Boss ohne Rollenhinweise steht das **einmal** da, nicht dreimal; mit
Hinweisen bekommt jede Rolle ihre Zeile, ungekürzt — die Karte rollt,
wenn der Bot mehr schickt, als das Fenster zeigt.

Woher eine Bossliste stammt, steht als Vorsatz an der Bosszeile; die
Begründung erscheint, wenn man ihn überfährt. Neun berichtete Kämpfe
ohne Namen (City of Dalaran) sind **neun leere Pillen**, nicht eine
leere Liste. Die neun Dungeons von Forever tragen in der Spalte das
Kennzeichen *Forever*.

### Technisch

Texthöhen werden mit `WeintCodex.Paragraph` aus Zeichen je Zeile
geschätzt statt vom Client gemessen, damit Prüflauf und Spiel dieselbe
Seite bauen. `load_test.lua` misst die Seite bei der Breite des
kleinsten Fensters (`Navigation.ContentBudgetWidth()`), zeichnet jeden
Dungeon-Boss (auch mit dreissig Tipps und mit gesperrtem
Zugriffsprofil) und prüft, dass eine Bosskarte mit zu vielen Tipps das
Fenster genau füllt. Die Client-Attrappe misst Textbreiten jetzt
proportional zur Zeichenzahl. `modules/rolepanel.lua` hat zwei neue
Bausteine (`Roster`, `BossRoleRows`); die alten bleiben für die
Schlachtzugseite.

## [5.2.0.0] – 2026-09-21

**Die zwanzig klassischen Dungeons stehen jetzt mit im Bestand.** Forever
ersetzt sie nicht, es stellt neun daneben — wer mit Stufe 32 einen Dungeon
suchte, bekam von einer Neunerliste die falsche Antwort. Die Liste links
führt jetzt **neunundzwanzig** Instanzen, sortiert nach Stufe, und die
Suche findet sie alle.

Ihre Herkunft ist eine andere als alles andere hier, und das steht dran:
dass es *Darkmaster Gandling* in der Scholomance gibt, ist seit zwanzig
Jahren nachprüfbar — dass Forever ihn unverändert übernimmt, ist es
**nicht**. Blizzard hat angekündigt, die Beute jedes Bosses überarbeitet zu
haben, und über die Kämpfe selbst nichts gesagt.

**Bosslisten für Hall of Thanes und Ruins of Lordaeron**, dazu die zwei
Bosse der *Drowned City*, die auf der BlizzCon spielbar waren. Sie stammen
**nicht aus dem Client**, sondern aus Beta-Berichten — niemand in diesem
Projekt hat den Forever-Client gelesen. Genau das steht an jeder Liste, und
es ist eine schwächere Aussage als die „vorläufig" der Schlachtzüge.

Dafür gibt es seit dieser Fassung fünf Arten von Herkunft statt zwei
(`data/sources.lua`): `release`, `announced`, `beta`, `community`,
`classic`. Nur `release` gilt als bestätigt — alles andere trägt auf der
Oberfläche einen Zusatz **und** eine Begründung, warum es nicht feststeht.

**Zu jedem Boss steht, wo er steht.** Witherfang patrouilliert den ersten
langen Gang, Durgen Dirgehammer wartet mit zwei Steingolems, Ambassador
Flamelash steht allein in der Kammer der Verzauberung.

**Bilder gibt es keine, und das bleibt so.** Blizzard hat für Forever keine
Dungeonkarten veröffentlicht; im Beta-Client liegt für vier der neun
Instanzen überhaupt Kartenmaterial. Unabhängig davon gehört es Blizzard.
Auf Texturpfade des Clients zu zeigen wäre möglich — welche Forever
vergibt, weiss hier aber niemand, und ein geratener Pfad zeichnet im Spiel
ein grünes Rechteck. Wo ein Boss steht, lässt sich **sagen**; das ist der
Teil, der geht.

**Elf beschwörbare Zusatzbosse, mit eigener Übersicht.** Viktor the Vile
hinter dem Kohlenbecken in Lordaeron, Kirtonos the Herald, der Avatar von
Hakkar, Atal'alarion, Urok Doomhowl, Lord Valthalak, Gahz'rilla, Postmaster
Malown, Jarien und Sothos, Lord Hel'nurath, Mutanus. An jedem steht, wie er
kommt. Dazu die Unterscheidung, die ständig verwechselt wird: **Spieler**
beschwört in Forever nur der Hexenmeister — Rufsteine sind nicht
freigeschaltet.

**Wo Quellen sich widersprechen, steht der Widerspruch da.** Für
*Excavation Site* kursieren vier Bossnamen, die eine andere Darstellung
bestreitet. Für *Blackmaw Hold* kursiert eine Liste, die nachweislich die
der Drowned City ist. Für *City of Dalaran* sind neun Kämpfe berichtet und
fünf Namen — die Seite nennt deshalb die **Anzahl** und weist die Namen als
Ausschnitt aus, statt eine Fünferliste zu zeigen, wo neun Kämpfe stehen.

**Die Liste links läuft trotzdem nicht über.** Neunundzwanzig Instanzen mit
Stufenzeile wären 1334 px in einer Spalte von 716. Sie öffnet deshalb einen
Stufenabschnitt nach dem anderen, und grosse Instanzen (Blackrock Depths,
Dire Maul, Stratholme, Scarlet Monastery) einen Flügel nach dem anderen.
Der Prüflauf rechnet **jede** Instanz in **jedem** Flügel gegen das Budget
und klickt den Aufklappweg einmal komplett durch.

### Zum Client-Build 1.60.1.69913

Danach war gefragt, und die ehrliche Antwort ist: er bringt für die
Bosslisten nichts. Er ist vom 18.09.2026, das erste Update nach dem
Beta-Start, und hat nach allem, was berichtet wird, Starter,
Absturzmeldung und ein paar Grafikdateien angefasst — Talente, Zauber und
Gegenstände nicht. Die Schlachtzugslisten behalten deshalb ihren Bezug auf
1.60.1.69876: eine hochgezählte Buildnummer wäre eine Prüfung, die nie
stattgefunden hat.

## [5.1.0.0] – 2026-09-20

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

**Man sieht jederzeit, wo man ist — und nichts muss dafür scrollen.**
Die Spalte links zeigt jetzt zwei Ebenen: die Instanzen, und darunter
eingerückt die Bosse der Instanz, in der man gerade steckt. Beide
Antworten auf *wo bin ich* stehen damit gleichzeitig und dauerhaft da,
statt nacheinander in einer Brotkrume. Je Boss ein Punkt für „gelegt"
und, wo Taktik vorliegt, ein `TIPPS` daneben.

Der Inhaltsbereich zeigt dafür den **ausgewählten Boss** mit seinen drei
Rollen — also das, wofür links kein Platz ist. Eine Liste, die man ohnehin
zur Orientierung braucht, ein zweites Mal in der Mitte zu zeigen und dann
ausgerechnet die Mitte scrollen zu lassen, war der falsche Weg herum.

**Die Suche landet auf dem Treffer.** Wer „Sonya Darkhallow" eingibt,
kommt bei Sonya Darkhallow heraus und nicht auf einer Schlachtzugseite,
die gerade etwas anderes aufgeschlagen hat.

**Die Stufenbereiche der Dungeons stehen endlich da.** Die zweite Zeile
eines Eintrags in der Spalte erwartete bisher eine andere Form, als die
Schlachtzugseite lieferte — die Zeile wurde gebaut und blieb leer. Kein
Fehler, keine Meldung, nur eine Auskunft, die nie ankam. Jetzt steht bei
jedem Dungeon sein Stufenbereich und bei jedem Schlachtzug seine Grösse.

**Ausserdem:** die Einführung hat ein Kapitel über Instanzen und Rollen
bekommen, `/wc dungeons` führt direkt hin, und die Diagnose unter
*Einstellungen* zählt Dungeons und Dungeonbosse getrennt — weil sie einen
anderen Zustand haben als die Schlachtzugsbosse.

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
