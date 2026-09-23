# Changelog

Alle nennenswerten Änderungen an **WeintCodex — Forever Edition** werden hier
festgehalten. Format lose an [Keep a Changelog](https://keepachangelog.com/)
angelehnt; Versionsnummern folgen dem 4-teiligen Schema
(`MAJOR.MINOR.PATCH.BUILD`), nicht SemVer.

Die Fassung für *Mists of Pandaria Classic* (`daddler/WeintCodex`) hat ihren
eigenen Changelog und ihren eigenen Update-Kanal. Die beiden Zweige laufen
nicht zusammen.

## [5.2.0.9] – 2026-09-23

**Ragefire Chasm bekommt ein eigenes Gesicht.** Der Dungeon-Header verwendet
nun ein eigenes Artwork und auch die vier Bosskarten sind individuell
bebildert.

**Das Artwork-System wächst mit.** Ragefire Chasm ist der zweite bebilderte
Dungeon und verwendet dieselbe zentrale Artwork-Struktur wie Hall of Thanes.
Weitere Dungeons können damit ergänzt werden, ohne die Dungeon-UI selbst
anzupassen.

## [5.2.0.8] – 2026-09-23

**Hall of Thanes bekommt ein eigenes Gesicht.** Der Dungeon-Header verwendet
nun ein eigenes Artwork und auch die vier Bosskarten sind individuell
bebildert. Die Bilder werden über die neue Artwork-Struktur des Addons
eingebunden und können damit künftig auch für weitere Dungeons verwendet
werden.

**Die Darstellung bleibt funktional.** Artwork liegt hinter einer dunklen
Überlagerung, sodass Namen, Nummern und Dungeoninformationen weiterhin
lesbar bleiben. Dungeons ohne eigenes Artwork fallen sauber auf die bisherige
Darstellung zurück.

## [5.2.0.7] – 2026-09-22

**Dieselbe Seite, anders gewichtet.** Die Informationsarchitektur aus
5.2.0.5/5.2.0.6 bleibt unverändert — Kopfkarte, Bossraster, Kontextkarte,
rechter Detailbereich, gerechnetes Raster. Was sich ändert, ist, wie schwer
die drei Ebenen *aussehen*: in 5.2.0.6 war die Struktur geordnet, aber alle
drei Flächen lasen sich noch gleich laut, und die unterste war die
grösste — für die nachrangigste Auskunft.

**Die Bosskarte ist ein Eintrag geworden, kein breiter Knopf.** Eine Zeile
Text in einem Rahmen bleibt eine Zeile Text in einem Rahmen, egal wie sie
gefüllt ist. Drei Dinge ändern das, und keines davon ist ein Bild: die
Karte ist höher und in zwei Zonen geteilt (Nummer oben, Name unten,
dazwischen Luft); die untere Zone läuft nach unten hin dunkler aus, sodass
der Name **auf** etwas steht statt in einem Kasten zu schweben; und der
Name steht in der Serife — der Überschriftenschrift des Addons, dieselbe
wie der Dungeonname darüber. Auf der ausgewählten Karte ist derselbe Sockel
akzentfarben: der Zustand färbt die Fläche, auf der der Name steht, nicht
nur seinen Rahmen.

Wie hoch eine Karte wird, ist **gerechnet wie die Spaltenzahl**: die hohe
Karte, solange unter dem Raster noch eine Kontextkarte steht und kein
Schlitz; im breiten Fenster wächst sie mit der Breite mit (gedeckelt, denn
was darüber hinausginge, wäre Fläche ohne Inhalt); bei Instanzen mit sehr
vielen Bossen fällt sie im kleinsten Fenster auf die enge Fassung zurück —
dieselbe Karte, nur gedrängter, **keine verlorene Auskunft**.

**Die Kopfkarte hat zwei Zonen.** Der Name steht grösser, der Themensatz
steht als Spalte (62 % der Breite) statt über die ganze Fläche, und rechts
daneben läuft die Fläche in den Akzent aus — so schwach, dass sich der Ton
nicht als Farbe lesen lässt. Das ist die Stelle, an der in jedem Entwurf
ein Dungeonbild steht; es gibt keines, und Licht ist das, was dieses Addon
dort ehrlich zeichnen kann (siehe *Bilder: keine, und warum*). Das
Tatsachenband darunter steht auf eigenem, dunklerem Grund — ein Band auf
eigenem Grund wird überflogen, dieselben Werte auf derselben Fläche wie der
Titel wären die vierte Textzeile. Die Stufenzelle steht dabei **rechts
aussen für sich**: sie ist die einzige Auskunft des Bandes, die nicht vom
Dungeon kommt, sondern von der eigenen Figur.

**Der Bossabschnitt führt die Seite an.** Die Rubrik ist eine Graustufe
heller als die Rubriken der Kontextkarte und zieht eine Haarlinie bis zum
Herkunftsvorsatz — aus einer Zeile Text wird damit ein Abschnitt.

**Und die Fläche darunter ist nur noch so gross wie ihr Inhalt.** Drei
Ursachen, alle drei behoben:

* Die Kontextkarte hatte eine **Mindesthöhe** von 160 px. Eine Karte mit
  drei kurzen Zeilen war damit eine halbleere Fläche.
* Texthöhen wurden gegen die Breite des **kleinsten** Fensters geschätzt.
  Ein Absatz, der bei 652 px vier Zeilen braucht, braucht bei 1036 px zwei
  — die Karte wurde für vier gebaut und zeichnete zwei. Das war der grösste
  Anteil am leeren Raum. Geschätzt wird weiterhin gerechnet und nie aus der
  Schriftmetrik des Clients gelesen, nur eben gegen die Breite, in der der
  Text wirklich steht.
* Besonderheiten, Aufstellung und Herkunft sind enger gesetzt: kleinere
  Abstände, ein knapperer Innenrand, und die Herkunft steht in **zwei**
  Zeilen statt in vier — die Rubrik neben der Quelle statt darüber.
  Vollständig bleibt alles: welche Bäume eine Rolle tragen, steht weiter
  ungekürzt da.

Bei einem Fenster von 1702 × 1001 mit offenem Detailbereich belegt Maraudon
damit 800 von 937 px — die Karte ist inhaltsgross, statt bis zum Rand
gestreckt zu werden.

### Technisch

* `BOSS_H_TALL` (66) / `BOSS_H_MED` (46) / `BOSS_H_FLAT` (34) plus die
  mitwachsende Fassung (`cardW × BOSS_ASPECT`, gedeckelt bei
  `BOSS_H_WIDE` = 80). `GridCardHeight(top, rowCount, headline, reserve,
  cardW)` wählt absteigend; „passt" heisst: unter dem Raster bleiben noch
  `CARD_ROOM` (168 px). Das ist bewusst **nicht** `MIN_DETAIL_H` (120 px),
  die Grenze, unter der die Seite sich im Prüflauf selbst anzeigt — wären
  es zwei Namen für eine Zahl, müsste jede Kartenhöhe am schlimmsten Fall
  gemessen werden. `reserve` zählt die Vollständigkeitszeile mit, die bei
  geöffnetem Boss unter dem Raster steht.
* `LayoutWidth()` ersetzt `MinContentWidth()` als Schätzbreite für
  Absätze. Wo der Rahmen die Verschmälerung durch den Detailbereich in
  derselben Runde noch nicht kennt (`SetInspector` läuft vor dem
  Zeichnen), erkennt die Funktion das am Abstand zum Wirtsrahmen und
  rechnet die 420 px selbst heraus — eine zu grosse Breite hiesse
  abgeschnittener Text, und das ist die teurere Richtung.
* `GridLayout` rechnet die Spaltenzahl weiter mit `BOSS_FIT` (12) und
  nicht mit dem grösseren Schriftgrad der hohen Karte; dort darf der Name
  stattdessen in eine zweite Zeile umbrechen. Eine Spalte weniger kostet
  eine Rasterzeile mehr, und die kostet die Kontextkarte ihre Höhe.
* `PackCells` ist die eine Packung des Tatsachenbandes, die `DrawMetaStrip`
  und `MetaStripHeight` gemeinsam lesen — zwei Rechnungen für dieselbe
  Packung waren zwei Gelegenheiten für ein Band, das tiefer endet als
  seine Karte. Die Zelle mit `tail = true` wird rechts aussen gesetzt.
* Vier neue Verlaufs-Token in `core/ui.lua` (`washNone`, `washAccent`,
  `washAccentUp`, `washDark`) und `ApplyHorizontalGradient`. Sie sind keine
  zweite Bedeutungsfarbe: `washAccent` **ist** der Akzent, bei 8 %
  Deckung, und sie werden ausschliesslich mit einem Verlauf gebraucht.
* `RolePanel.Roster(..., { compact = true })` zieht dieselben drei Zeilen
  enger, ohne eine wegzulassen.
* `load_test.lua` und `data_test.lua` unverändert grün; schlimmster Fall
  im kleinsten Fenster ist Hall of Thanes mit 716 von 716 px.

## [5.2.0.6] – 2026-09-22

**Die Dungeonseite bekommt die Gestalt, die 5.2.0.5 ihr geordnet hat.**
Die Informationsarchitektur aus 5.2.0.5 bleibt unverändert — Kopf, Bosse,
Kontextkarte, rechter Detailbereich, gerechnetes Raster. Was sich ändert,
ist die *Gewichtung*: die drei Ebenen sahen bis hierher gleich schwer aus,
weil alle drei auf demselben Grund standen und nur Abstand sie trennte.

**Der Dungeonkontext steht auf einer eigenen Fläche.** Eine Kopfkarte mit
dem Kartenverlauf des Addons (`CreateSurface`, `tone = "plain"`), einem
Akzentstreifen an der linken Kante und, in ihr, dem gewohnten Seitenkopf:
Kennzeichnung, Name in der Serife, Themensatz in der ruhigen Kursiven. Sie
ist die eine Fläche der Seite, die eine *Überschrift* trägt statt eines
Bestands — dass sie einen eigenen Grund hat, sagt genau das. Der
Akzentstreifen ist dasselbe Zeichen, das in der Spalte links am
ausgewählten Dungeon steht und auf der ausgewählten Bosskarte: drei
Stellen, ein Zeichen.

**Aus der Tatsachenzeile ist ein Tatsachenband geworden.** Bis 5.2.0.5
stand *„Desolace · Stufe 46 – 55 · 5 Spieler · 9 Bosse · Deine Stufe 10 ·
zu niedrig"* als umbrechender Absatz da. Das ist ein **Satz**, und ein Satz
wird gelesen, nicht überflogen — wer wissen will, ob seine Stufe passt,
sucht die Auskunft zwischen vier anderen heraus. Jetzt trägt jede Tatsache
eine eigene Spalte: oben der Wert in Lesegrösse, darunter die Rubrik als
gesperrte Versalie (`GEBIET`, `STUFEN`, `SPIELER`, `BOSSE`). Das ist
dieselbe Form wie die Kennzahlen im Seitenkopf der anderen Seiten
(`WeintCodex.PageHead`, `stats`) — nur von links nach rechts gelesen statt
von rechts nach links gesetzt, weil es hier fünf sind und keine zwei.

Wie viele Zellen in eine Zeile des Bandes passen, ist **gerechnet wie die
Spaltenzahl des Bossrasters**: jede Zelle ist so breit wie ihr breiterer
der beiden Texte, was nicht mehr in die Zeile passt, fällt in die nächste.
Eine feste Spaltenzahl gibt es nicht, und abgeschnitten wird nichts.

Die fünf Formulierungen der Bosszahl bleiben, sie stehen nur anders:
`9 · BOSSE`, `4 / 9 · BOSSE BENANNT`, `9 · KÄMPFE · NAMEN OFFEN`,
`— · QUELLEN WIDERSPRECHEN SICH`, `— · BOSSE UNBEKANNT`. Keine davon ist
eine `0`. Die Stufenzelle ist die einzige, die von der eigenen Figur
abhängt, und sie färbt beide Zeilen; nennt der Client keine Stufe, **fehlt
sie ganz**.

**Die Bosskarten sehen aus wie Karten.** Bis 5.2.0.5 waren sie eine flache
Fläche (`surface2`) mit dünnem Rahmen und blassem Namen — genau das Bild,
das in jeder Oberfläche ein *Textfeld* ist. Sie tragen jetzt denselben
Kartenverlauf mit 1-px-Oberkante wie jede andere Fläche des Addons, und der
Name steht in Lesefarbe statt in Beschriftungsfarbe: was hier zählt, ist
der Boss, nicht die Karte. Das Kennzeichen (`BESCHWÖREN`, `OPTIONAL`,
`TIPPS`) ist eine Pille (`WeintCodex.Chip`) statt einer frei schwebenden
Versalie; ihre Breite wird gerechnet und nicht gemessen, damit sie im
Prüflauf und im Spiel dieselbe ist.

Der **ausgewählte** Boss trägt den Akzentton der Seite (`tone = "accent"`:
violett getönter Verlauf, Akzent-Oberkante, Akzentrand) und nicht mehr nur
einen Balken. Er ist damit die eine Akzentfläche der Ansicht, wie der
Entwurf es vorsieht — die Kopfkarte trägt ihren Akzent als Kantenstreifen,
nicht als Fläche.

**Die Kontextkarte hat zwei Spalten.** Links `BESONDERHEITEN`, rechts
`AUFSTELLUNG`, getrennt durch eine Haarlinie. Bis 5.2.0.5 war das eine
schmale Säule Text in einer breiten Karte, mit viel Fläche rechts daneben,
die nichts tat.

Was unter *Besonderheiten* steht, ist **abgeleitet und nicht erfunden**:
wie viele Flügel die Instanz hat, wie viele Bosse nur auf Beschwörung
erscheinen, wie viele neben dem Hauptweg stehen, ob die Reihenfolge bekannt
ist, ob die Liste vollständig ist, ob der Dungeon aus Classic stammt. Ein
Satz über „viel Laufweg" oder „schwierige Trashpacks" wäre zu jedem Dungeon
dieser Welt zu schreiben und zu keinem belegt; hier steht er nicht. Liegt
zu einem Dungeon keine einzige dieser Auskünfte vor, **fällt die Spalte
weg** und die Aufstellung nimmt die volle Breite.

Die Karte trägt deshalb keinen eigenen Titel mehr: ein Titel „Aufstellung"
über einer Spalte „Aufstellung" wäre dasselbe Wort zweimal, und die Zeile
dafür wäre Luft.

**Die Herkunft ist eine Fusszeile geworden.** Bis 5.2.0.5 standen dort zwei
Zwischentitel und zwei Absätze — die grösste zusammenhängende Textfläche
der Seite für die nachrangigste Auskunft, die sie hat. Jetzt sind es drei
Zeilen unter einer Haarlinie: Rubrik, Vorsatz mit Quelle, Begründung.
Verloren geht nichts, und die Regel bleibt dieselbe wie seit 5.2.0.3: ist
der Detailbereich rechts offen, steht sie dort; steht die Seite in voller
Breite, steht sie hier. **In jedem Zustand genau einmal sichtbar.**

Dieselbe Regel gilt seit dieser Fassung für die Vollständigkeitszeile
(*„14 Kämpfe sind bekannt, ihre Reihenfolge nicht"*): ohne ausgewählten
Boss trägt sie die Spalte *Besonderheiten*, mit ausgewähltem Boss gibt es
die Spalte nicht — dann steht sie unter dem Raster.

**Der geöffnete Boss trägt seinen Namen in der Überschriftenschrift.** Bis
5.2.0.5 stand er in der Grotesk — derselben Schrift wie auf den
Bosskarten, den Rollenzeilen und den Knöpfen; der Name des geöffneten
Bosses sah damit aus wie eine weitere Beschriftung und nicht wie der Titel
dessen, was darunter steht. Seine Notiz ist vom Abschnitt *„Dazu"* zum
**Aufschlag** geworden: der eine Satz, der sagt, *was* dieser Boss ist,
steht direkt unter seinem Namen, in derselben ruhigen Kursiven wie der
Themensatz des Dungeons oben.

**Der rechte Detailbereich führt die Herkunft als Kennzahl.** `HERKUNFT ·
Aus Classic` in der Kennzahlenliste (neu: `S.Prefix()` in
`data/sources.lua`), die Quelle und der Warum-Satz darunter — statt Vorsatz
und Quelle zusammengezogen in einem Absatz und die Art nirgends auf einen
Blick. Kennzahlenzeilen brechen nicht um (`InspectorRows`), deshalb steht
dort der kurze Vorsatz und nicht das ganze `S.Label()`.

**Keine Bilder, und der Grund ist unverändert.** Die Referenzentwürfe zu
dieser Fassung zeigen Dungeon- und Bossbilder. Es gibt sie nicht: Blizzard
hat für Forever kein Kartenmaterial veröffentlicht, im Beta-Client liegt
für vier der neun Instanzen überhaupt welches, und es gehört Blizzard. Ein
geratener Texturpfad zeichnet im Spiel ein grünes Rechteck. Die Atmosphäre
kommt deshalb aus Fläche, Kante, Schrift und dem einen Akzent — und `wo`
ein Boss steht, sagt weiterhin `boss.position` in Worten.

**Gemessen:** schlimmster Fall der Seite unverändert **716 von 716 px**
(die Kontextkarte füllt bis zum Rand und rollt — der vorgesehene Fall), die
Spalte links unverändert **642 von 716 px**.

## [5.2.0.5] – 2026-09-22

**Die Dungeonseite ist neu geordnet — drei Ebenen statt acht
gleichberechtigter Einzelteile.** Titel, Metadaten, Bosszahl,
Stufenhinweis, Herkunftsvorsatz, Bosszeile, Aufstellung und eine
leere Detailkarte standen bis 5.2.0.4 nebeneinander, ohne dass eines
davon wichtiger aussah als das andere. Jetzt liest sich die Seite in
drei Stufen: **Dungeonkontext**, **Bosse**, **ergänzende Auskünfte**.

**Die Bosse sind ein Raster aus Karten, keine Kette aus Pillen.** Eine
Reihe schmaler, gerundeter Schaltflächen ist das Bild, mit dem jede
Oberfläche „hier wechselst du die Ansicht" sagt — was der Dungeon
*enthält*, sah damit aus wie ein Bedienelement. Eine Karte trägt die
Nummer oben links (nur wo die Reihenfolge bekannt ist), das
Kennzeichen oben rechts (`BESCHWÖREN` > `OPTIONAL` > `TIPPS`) und den
Namen darunter in Lesegrösse.

Wie viele Spalten das Raster bekommt, ist **gerechnet, nicht gesetzt**
(`GridLayout()`): drei, solange eine Karte darin noch 150 px breit ist
*und* der längste Name der gezeigten Liste ganz hineinpasst — sonst
zwei, sonst eine. *Blackrock Depths* hat Bosse mit 26 Zeichen; in
210 px stünden die nicht, sondern endeten in einem abgeschnittenen
Wort. Gerechnet wird mit derselben Kennzahl wie überall (0,60 em je
Zeichen), damit Spiel und Prüflauf dasselbe Raster bauen. Beim
Vergrössern des Fensters rücken die Karten still nach; neu gezeichnet
wird die Seite nur, wenn die Spaltenzahl wirklich kippt.

**Der Dungeonkontext steht in einer Zeile, nicht an vier Stellen.**
Gebiet, Stufenbereich, Gruppengrösse, Bosszahl und — wenn der Client
eine Stufe nennt — ob sie passt. Die Kennzahl rechts oben (*BOSSE 9*)
ist damit weg: sie stand so weit von allem anderen entfernt, dass sie
zu keiner Auskunft mehr gehörte, und weil ihr Platz je nach Titel
wechselte, gab es drei Rechnungen dafür, wo eine Zahl hingehört. Die
Zeile ist ein umbrechender Absatz und keine freilaufende Zeile — bei
offenem Detailbereich bleiben dem Kopf 232 px. Die Kennzeichnung
darüber ist auf ein Wort zusammengezogen (*CLASSIC* / *FOREVER*); das
Gebiet stand dort gesperrt und versal mit drin und lief aus dem Kopf
heraus.

**Die Aufstellung dominiert nicht mehr.** Sie steht als dritte Ebene
unter den Bossen — und wo die Seite in voller Breite steht, trägt
dieselbe Karte darunter, **woher die Bossliste stammt**, im Klartext
statt nur im Tooltip. Ist der Detailbereich rechts offen, steht es
dort; zweimal derselbe Absatz nebeneinander wäre keine Betonung. So
steht die Herkunft in **jedem** Zustand der Seite genau einmal
sichtbar.

**Der ausgewählte Boss ersetzt die Übersicht nicht.** Das Raster
bleibt stehen, die angeklickte Karte trägt einen Akzentbalken an der
linken Kante, und der Kartenkopf darunter trägt die Einordnung
(*BOSS 03 · SCARLET · OPTIONAL*), den Namen und rechts den Weg
zurück — beschriftet, wo er danebenpasst, sonst als Kreuz an
derselben Stelle.

**Weggefallen: „Ein Klick auf einen Boss zeigt ihn hier".** Der
Wegweiser aus 5.2.0.4 stand im Kopf einer Karte, die ohne Boss nichts
anderes zu sagen hatte, und beschrieb damit vor allem ihre eigene
Leere. Eine Karte, die Aufstellung *und* Herkunft trägt, braucht
keine Bedienungsanleitung.

**Der Detailbereich rechts hat einen zweiten Grund bekommen, zu
weichen.** Bis 5.2.0.4 wich er nur, wenn die Seite sonst nicht ins
Budget passte. Jetzt weicht er auch, wenn das Raster dadurch auf
**eine** Spalte fiele, in voller Breite aber mehr bekäme: 232 px
tragen eine Karte je Zeile, und eine Spalte ist keine Übersicht,
sondern eine Liste. Im voreingestellten Fenster (1500 px) greift das
nicht — dort bleiben dem Inhalt auch mit Bereich 552 px, und das sind
drei Spalten. Ein Detailbereich **ohne Inhalt** nimmt ausserdem keine
Breite mehr: für die Dungeons ohne Bestand und ohne Herkunft reservierte
die Seite bisher 420 px für einen Bereich, der nichts zeigte.

Gemessen (kleinstes zulässiges Fenster, 1180 × 780): schlimmster Fall
**716 von 716 px** — die Kontextkarte füllt bis zum Rand und rollt,
der vorgesehene Fall. Die Spalte links ist unverändert bei **642 von
716 px**.

## [5.2.0.4] – 2026-09-22

**Die Dungeonnamen in der Spalte stehen wieder vollständig da.** Das
gesperrte Kennzeichen *FOREVER* am rechten Rand nahm der Beschriftung
rund **70 der 176 px**, die eine Zeile hat — sichtbar war das als
abgeschnittener Name („Temple of Atal'Hakk…", „Alcaz Island Priso…").
Der Name ist aber das, wonach man in einer Liste von neunundzwanzig
Dungeons sucht; er bekommt die ganze Breite, und die zweite Zeile
trägt beides: *Forever · Stufe 13 – 18* oder *Classic · Stufe 17 – 26*.

**Die zweite Zeile ist nicht mehr gesperrt geschrieben.** Gesperrte
Versalien sind in dieser Oberfläche die Form einer **Rubrik** —
Eyebrow, Abschnittstitel, Gruppenkopf. Ein Stufenbereich ist keine
Rubrik, sondern ein Wert: „S T U F E   1 3   –   1 8" liest sich als
Muster und ist doppelt so breit wie nötig, und eine lange zweite Zeile
lief rechts aus der Spalte heraus, ohne dass etwas fehlschlug. Die
Zeile ist jetzt auf die Spaltenbreite beschnitten, bricht nicht um und
hellt beim ausgewählten Eintrag mit auf. Das ist derselbe Fehler, den
5.2.0.2 am **Gruppenkopf** behoben hat — er stand nur an zwei Stellen.

**Die Stufenabschnitte haben Luft bekommen**, und zwar oben mehr als
unten: ein Zwischentitel gehört zu dem, was unter ihm steht. Kosten:
6 px je Abschnitt, gemessen **642 statt 612 von 716 px**, 74 px frei
(gefordert sind 60).

**Die Bosszahl steht als Kennzahl rechts im Kopf**, wie im Kopf der
Schlachtzugseite — aber an genau *einer* Stelle, und welche das ist,
entscheidet der Platz. Mit offenem Detailbereich bleiben dem Kopf
232 px; ein Kennzahlenblock ist 64 px breit und rechtsbündig, ein
Titel wie „Temple of Atal'Hakkar" in 30 px liefe ihm darunter. Passt
sie daneben, steht sie dort (4 Dungeons in voller Breite, dazu die
kurznamigen); passt sie nicht, trägt sie der Detailbereich als Zeile
*Bosse* — und die Faktenzeile trägt sie dann **nicht** noch einmal.
Dreimal dieselbe Zahl auf einer Seite ist keine Betonung, sondern
Lärm.

Dazu: die Aufstellungskarte sagt im Kopf, was als Nächstes zu tun ist
(*„Ein Klick auf einen Boss zeigt ihn hier"*) — dort, wo Platz dafür
ist und wo es etwas anzuklicken gibt.

### Technisch

`core/navigation.lua`: `SUBNAV_GROUP_TOP`/`SUBNAV_GROUP_BOT` lösen die
an vier Stellen eingetragene `8` ab; `MeasureSidebar` rechnet mit
denselben Konstanten, und `load_test.lua` hält beide gegeneinander.
Die Statuszeile bekommt eine gesetzte Breite und `SetWordWrap(false)`
statt sich auf ihre Textlänge zu verlassen, und merkt sich ihren
Grundton (`_statusTone`/`_statusHot`), damit ein eigener Farbton
(Warnung, Erfolg) beim Aktivieren **nicht** überschrieben wird.
`modules/dungeonpages.lua`: `HeadStatFits()` und `HintFits()`
entscheiden mit derselben Schätzung wie `WeintCodex.Paragraph`
(0,60 em je Zeichen), ob Kennzahl bzw. Wegweiser hinpassen — gerechnet
gegen die **schmalste** mögliche Breite, damit Spiel und Prüflauf
dieselbe Seite bauen. `PillEdge()` ruft jetzt
`WeintCodex.DrawBorder()` aus `core/ui.lua` auf, statt dessen vier
Kanten selbst nachzubauen; die Akzentlinie der aktiven Pille liegt
dafür auf `OVERLAY`/3 statt `ARTWORK`, damit die Unterkante des
Rahmens sie nicht zudeckt (unter den Eckmasken auf Unterebene 6 bleibt
sie).

## [5.2.0.3] – 2026-09-21

**Die Dungeonseite zeigt jetzt denselben rechten Detailbereich wie die
Schlachtzugseite** (`WeintCodex.Navigation.SetInspector`) — für ein
einheitliches Bild zwischen beiden Seiten. Der Bereich trägt
Kennzahlen (Gebiet, Stufe, Gruppengröße, Bosszahl) und, wo eine Quelle
vorliegt, eine dauerhaft sichtbare "Woher die Bossliste stammt"-Karte
mit Begründung — vorher stand die Begründung nur im Tooltip des
Vorsatzes an der Bosszeile.

**Das ist kein bedingungsloser Rückbau auf das Vier-Flächen-Layout vor
5.2.0.0.** Der Detailbereich beansprucht 420 px (372 px Karte + 16 px
Abstand + 32 px Innenrand); von den 716 px Inhaltsbreite beim
kleinsten Fenster bleiben dann 296 px für die Bosszeile. Bei den
meisten der 29 Dungeons passt das — bei den wenigen mit vielen Bossen
in einem Flügel (Stratholme, Blackrock Depths, Scholomance, Lower
Blackrock Spire) würde die Bosszeile bei dieser Breite so viele Zeilen
brauchen, dass für die Detailkarte darunter nicht einmal die
Mindesthöhe von 160 px übrig bliebe. Die Seite zeichnet sich deshalb
zunächst mit Detailbereich, misst sich selbst gegen dasselbe Budget,
das `load_test.lua` prüft (`PageHeight()` gegen `PageBudget()`), und
zeichnet bei Überlauf sofort noch einmal in voller Breite ohne
Detailbereich — dieselbe Messung, keine separate Schätzung, die davon
abweichen könnte.

### Technisch

`core/navigation.lua`: `BuildColumn` unverändert seit 5.2.0.2, aber
`core/ui.lua`s `WeintCodex.Metrics` trägt jetzt zusätzlich
`DETAIL_GAP`. `modules/dungeonpages.lua`: `MinContentWidth()` liest ein
neues `inspectorShown`-Flag und zieht bei offenem Detailbereich
`DETAIL_W + DETAIL_GAP + PAD_X` von der Budgetbreite ab; `DrawDungeon`
probiert über die neue `DrawDungeonAt(f, dungeon, withInspector)`
zunächst den schmalen Entwurf und wiederholt bei Überlauf mit
`withInspector = false`. `.github/tests/load_test.lua` setzt die
Breite der Client-Attrappe jetzt auf die schmalere, detailbereich-
bewusste Zahl (die Attrappe kennt `SetPoint` nicht und würde sonst mit
mehr Platz rechnen, als im Spiel tatsächlich da ist).

## [5.2.0.2] – 2026-09-21

**Die Stufenabschnitte links sind jetzt als Knöpfe zu erkennen, nicht
als blasse Zwischenüberschrift.** Ein Aufklapp-Pfeil (`>` geschlossen,
`v` geöffnet) und ein Hover-Schimmer — derselbe wie bei jeder anderen
anklickbaren Zeile — sagen es, bevor man es zufällig herausfindet.
Geschlossene Abschnitte stehen zudem in einem lesbaren Grauton statt im
fast unsichtbaren vorherigen.

Der Stufenbereich selbst ("Stufe 13 – 22") lief in der 232 px schmalen
Spalte vorher in die rechts stehende Anzahl der Dungeons hinein: die
gesamte Zeile war komplett buchstabengesperrt geschrieben, und das
machte aus einer kurzen Zahl eine zu breite. Jetzt ist nur noch der
kurze Vorsatz *Stufe* gesperrt, die Zahlen selbst stehen eng und ohne
Kollision daneben.

Die Boss-Pillen auf der Dungeonseite haben jetzt eine dünne Kontur —
unausgewählt verschwammen sie zuvor mit dem dunklen Seitenhintergrund
und sahen aus wie Fliesstext, nicht wie ein Knopf. Die Kontur färbt sich
beim Überfahren und bei Auswahl mit, in derselben Zustandssprache wie
die Fläche dahinter.

### Technisch

`core/navigation.lua`: `BuildColumn` nimmt für Gruppenköpfe optional
`rangeLo`/`rangeHi` entgegen und rendert dann Vorsatz und Zahlenbereich
getrennt statt eines einzigen, komplett gesperrten Strings; ohne die
beiden Felder bleibt die alte Darstellung (z. B. für den Testfall in
`load_test.lua`) unverändert. `modules/dungeonpages.lua` übergibt
`bucket.min`/`bucket.max` aus `DungeonData.Brackets()` und zeichnet mit
dem neuen `PillEdge`-Helfer eine Kontur um jede Boss- und Ghost-Pille,
die von den bestehenden Eckmasken (`WeintCodex.CutCorners`) automatisch
mitgerundet wird.

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
