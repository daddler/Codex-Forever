# Changelog

Alle nennenswerten Änderungen an **WeintCodex — Forever Edition** werden hier
festgehalten. Format lose an [Keep a Changelog](https://keepachangelog.com/)
angelehnt; Versionsnummern folgen dem 4-teiligen Schema
(`MAJOR.MINOR.PATCH.BUILD`), nicht SemVer.

Die Fassung für *Mists of Pandaria Classic* (`daddler/WeintCodex`) hat ihren
eigenen Changelog und ihren eigenen Update-Kanal. Die beiden Zweige laufen
nicht zusammen.

## [6.8.1.0] – 2026-10-01

**Namensplaketten mit Leben.** Was ein Treffer nimmt, bleibt einen Moment hell stehen und schmilzt dann weg; das Leben gleitet, statt zu springen. Dein Ziel atmet: das Leuchten pulsiert, eine feine Kante trägt deine Klassenfarbe, ab und zu läuft ein Glanz über den Balken, jeder Treffer blitzt kurz auf und die Zielmarken bewegen sich. Jeder Effekt lässt sich einzeln abschalten.

**Automark.** Betrittst du als Gruppenleiter einen Dungeon oder Schlachtzug, bekommen Tank und Heiler ihre Markierung – welche, wählst du. Markiert wird nur, wer vom Spiel eine Rolle hat; geraten wird nichts. Zu finden unter Komfort, von Haus aus aus.

**Makro-Helfer.** Statt Makrosprache drei Fragen: was, auf wen, welcher Zauber. Der Text entsteht Zeile für Zeile erklärt, ein Klick legt das Makro an, ein zweiter legt es auf den Mauszeiger. Unter Aktionsleisten, Seite „Makros“.

**Entfluchen auf Klick.** Ein Schalter bei den Klickzaubern legt die Zauber deiner Klasse gegen Flüche, Gifte, Krankheiten und Magie auf Strg + Links und Rechts – ein Klick auf den Gruppenrahmen entflucht. Deine eigene Belegung bleibt, wie sie ist.

### Technisch

- `ui/nameplates.lua` (Entwurf „8 · Namensplaketten 3.0“, Varianten B + C): Schadensspur `p.trail` (zweiter Balken hinter dem Leben, derselbe Wert `NP.TRAIL_DELAY` = 0,35 s später; der erste Treffer startet die Uhr), Gleiten über `Enum.StatusBarInterpolation` mit Rückfall (`NP.smoothBroken`), am Ziel Alpha-/Translation-Animationen des Spiels (`NP.Anim`, `NP.Motion`): Leuchten atmet, Kante in Klassenfarbe, Glanz (`SetClipsChildren`), Aufblitzen bei `UNIT_HEALTH`, Zielmarken ±3 px. Grund `p.bg` jetzt am Plakettenrahmen. Sieben Schalter (Abschnitt „Bewegung“). Neu in `core/ui.lua`: `damageTrail`, `hitFlash`, `plateSheen`. Auch eine Heilung blitzt – ob das Leben sank, ist geheim.
- Neu `ui/automark.lua` (Seite im Komfort): Rolle nur aus `UnitGroupRolesAssigned`, nur als Gruppenleiter (abschaltbar), je Instanz einmal je Spieler und Markierung – dieselbe Markierung noch einmal nähme sie ab, der Index ist geheim –, nie im Kampf.
- Neu `ui/macros.lua` (Seite der Aktionsleisten): `MH.Build` erzeugt `/cast`, `/cast [mod:…]`, `/castsequence reset=…` mit Zielbedingungen (`@mouseover`, `@focus`, `@player`, `@cursor`), `#showtooltip`, `/stopcasting`, `/startattack`; Zähler in Bytes gegen 255; `CreateMacro`/`EditMacro`/`PickupMacro`, nie im Kampf; Name mit `Utf8Sub`.
- Neu `ui/dispel.lua`: Entfluch-Zauber je Klasse als Classic-IDs (Herkunft „classic“), angeboten nur, wenn der Client einen Namen nennt und er im Zauberbuch steht; `CC.Effective()` in `ui/clickcast.lua` legt sie nur auf freie Tasten.
- Automark und Makro-Helfer sind Seiten bestehender Module, weil die Seitenleiste der Einstellungen sonst keinen Platz mehr hätte („Nichts muss scrollen“).
- Testattrappe: `SetBlendMode`/`GetBlendMode`. `load_test.lua`: je Feature eine Prüfung mit Gegenproben (Spur-Uhr, Kante, Blitz nur am Ziel, Markieren ohne Leiter/Rolle/im Kampf, Makrotext und Grenzen, Entfluchen mit eigener Belegung).

## [6.8.0.9] – 2026-09-29

**Quests an der Karte ohne Pergament.** Öffnest du eine Quest, liegt ihr Text auf derselben ruhigen Fläche mit feiner Kante in Gold wie der Questlog – ohne Pergament, ohne braunen Balken, ohne Metallstriche zwischen den Knöpfen, in heller Schrift. Farben, die etwas sagen, bleiben.

**Die Karte läuft jetzt wirklich weich vor der Quest aus.** Der weiche Rand endet vor der geöffneten Quest statt unter ihr.

### Technisch

- 6.8.0.8 suchte die Details unter `QuestMapFrame.DetailsFrame` (Quelltext des Spiels); gemessen (`/wcui fenster`) liegen sie unter `QuestMapFrame.QuestsFrame.DetailsFrame` – gefunden wurde nichts, der Rand blieb hart. `W.MAP_COVERS` sind jetzt Pfade (`{ "QuestsFrame", "DetailsFrame" }`, `{ "DetailsFrame" }`); eine Tafel, die mehr als die halbe Karte deckt, zählt nicht. Der Bericht nennt ohne Überdeckung beide Kanten („Karte rechts …, Tafel links …“).
- `W.HIDE_ATLAS`: `QuestDetailsBackgrounds` (Pergament), `QuestLog-reward-*` (Balken mit „Zurück“, Rahmen der Belohnungen), `UI-Frame-BtnDiv*` (Metallstriche zwischen den Knöpfen) – gemessen.
- `ui/questlog.lua`: `QL.Details(f)`; Fläche mit Schatten und Kante in Gold unter `QuestMapDetailsScrollFrame` bis zur Bildlaufleiste, aus mit den Details; `W.LightenText` auf die Details (nur dunkle Schrift, ohne Farbcodes). Bericht: „Details auf Fläche, Schrift hell“.
- `W.SkinMap` baute je Durchlauf eine Liste seiner Teile – jetzt eine für alle.
- `load_test.lua`: Details wie gemessen (Pergament, Balken, Striche weg; Titel hell, Grün bleibt; Fläche, kein Müll; zu → Fläche weg); Überdeckung unter dem gemessenen Pfad.

## [6.8.0.8] – 2026-09-29

**Die Karte bleibt weich, auch neben einer Quest.** Öffnest du eine Quest auf der Karte, legt sich die Beschreibung über den rechten Teil der Karte – der weiche Rand lief bisher darunter aus, zu sehen war eine harte Kante. Jetzt läuft die Karte vor der Beschreibung weich aus.

### Technisch

- Beta-Test 6.8.0.6 (Karte mit Questdetails, „wieder abgehackt“): `QuestMapFrame.DetailsFrame` liegt über dem rechten Teil des Kartenausschnitts; die Maske (`W.SoftMap`, am ganzen Ausschnitt) lief unter ihm aus.
- `ui/windows.lua`: `W.MapCut(map, sc)` misst, wie weit die Tafel rechts (sichtbare `W.MAP_COVERS` – `DetailsFrame` –, sonst `QuestMapFrame`) in den Ausschnitt ragt; die Masken enden um so viel früher (`PlaceMask`, neu verankert nur bei Änderung, auch für später angelegte Masken). Bericht: „rechts … px früher (Tafel über der Karte)“.
- `load_test.lua`: Details über der Karte → Maske endet 120 px früher; Details zu → wieder am Rand; kein Neuverankern im Takt.

## [6.8.0.7] – 2026-09-29

**Der dunkle Grund unter den Bäumen bleibt beim Baum.** Er ist so breit wie ein Baum, beginnt am Symbol und läuft nach rechts weich aus, statt als Balken weit über den Baum hinaus zu reichen; die Linie hinter dem Namen endet vor ihm.

### Technisch

- Beta-Test 6.8.0.6: der Grund (6.8.0.5) reichte vom Symbol bis zum Ende der 200-px-Linie – rund 330 px, weit rechts über den Baum (etwa 200 px) hinaus, dazu als harter Balken (die weiche Maske als Neunteiler bei 40 px Höhe).
- `ui/talents.lua`: Grund aus zwei Verläufen – 18 px von null auf 55 % Schwarz, dann auf null – mit **fester** Breite `TL.ROW` (220 px ab 64 px links vom Namen), nur links verankert; Linie `TL.LineWidth(tw)` füllt, was der Name übrig lässt, und endet 24 px vor dem Ende (mindestens 24 px).
- `load_test.lua`: Grund so breit wie `TL.ROW` (≤ 240), Linie endet vor dem Grund, Linie bei langem Namen begrenzt.

## [6.8.0.6] – 2026-09-29

**Der Händler in der ruhigen Oberfläche.** Kein brauner Schein deiner Klasse mehr über den Waren; sie liegen auf einer Fläche mit weichem Schatten und feiner Kante in Gold, das Geld unten auf einer ruhigen Innenfläche statt auf Leder, und die Reiter „Händler“ und „Rückkauf“ sind flach, der gewählte in Gold. Plätze, Preise, Reparieren und Müll verkaufen bleiben, wie das Spiel sie zeigt – auch das Rot an Waren, die du nicht benutzen kannst.

### Technisch

- Neu `ui/merchant.lua` (`WeintCodex.UIMerchant`), **gemessen** (6.8.0.4, `/wcui fenster`): `MerchantFrame` in `S.CALM` (Schein der Klasse aus), neutrales Licht und Kante in Gold; Fläche von `MerchantItem1` bis zur letzten sichtbaren Ware (Händler 10, Rückkauf 12 – neu verankert nur beim Wechsel), Kante in Gold an der Fläche; `MerchantMoneyInset` (Leder, Bild 374154) über `W.OwnBackground` zur Innenfläche, `MerchantMoneyBg` (Bild 525911) ohne eigene Bilder; `MerchantFrameTab1/2` über `W.SkinTab` flach, gewählt = `MerchantFrame.selectedTab`, in Gold. Namen der Plätze und Reiter einmal gebaut.
- `ui/windows.lua`: `SkinTab(tab, accent, sel)` – gewählt vom Aufrufer, wenn der Reiter es nicht selbst sagt (PanelTabButton); `W.SkinTab`, `W.HideOwnTextures`.
- **Speicher:** `K.Border(...):SetColor/SetShown/SetAlpha` legten bei jedem Aufruf eine Liste an – `SkinTab` setzt die Randfarbe in jedem Durchlauf, also an jedem Reiter jedes offenen Fensters. Jetzt einmal gebaut (`o.parts`). Gefunden vom Speichertest des Händlers (5 KB je 20 Durchläufe).
- `load_test.lua`: Händler wie gemessen – Gold, kein Schein, Fläche bis Ware 10 bzw. 12, Geld als Innenfläche, gewählter Reiter in Gold (auch nach dem Wechsel), Plätze unberührt, kein Müll.

## [6.8.0.5] – 2026-09-29

**Die Bäume stehen sichtbar auf dem Nebel.** Symbol, Name und Linie jedes Baums liegen auf einem dunklen, weichen Grund, die Linie in deiner Klassenfarbe ist kräftiger, und das Licht deiner Klasse oben leuchtet jetzt durch den Nebel, statt in ihm zu verschwinden. Wolken, Funken und Talente bleiben, wie sie sind.

### Technisch

- Beta-Test 6.8.0.4: die Namen werden gefunden (`/wcui fenster`: „Bäume „Furor“, „Waffen“, „Schutz““), zu sehen war aber nur die Raute – Linie (55 %) und Licht (16 %) gingen im hellgrauen Nebel unter.
- `ui/talents.lua`: Linie 90 %, 200 px; unter jeder Zeile eines Baums ein dunkler weicher Grund (`GC.shadowSoft`, 60 %, `ARTWORK` −8 am Rahmen des Namens, vom Symbol bis zum Ende der Linie); Licht oben additiv (`SetBlendMode("ADD")`). Bericht nennt den Rahmen, an dem die Zeilen hängen.
- Testattrappe: `SetBlendMode`/`GetBlendMode`. `load_test.lua`: dunkler Grund unter der Raute, Linie ≥ 85 %, Licht additiv.

## [6.8.0.4] – 2026-09-29

**Die Talente zeigen jetzt, was versprochen war.** Die Namen der Bäume – etwa Waffen, Furor, Schutz – tragen jetzt wirklich Raute und Linie in deiner Klassenfarbe, und das Licht deiner Klasse liegt über dem Nebel statt unsichtbar darunter. Wolken, Funken und Talente bleiben, wie sie sind.

**Gespräche in der ruhigen Oberfläche.** Kein brauner Schein deiner Klasse mehr über Stadtwachen, Gastwirten und Lehrern; Begrüßung und Optionen liegen auf einer Fläche mit weichem Schatten und feiner Kante in Gold, oben am Fenster ebenfalls Gold – wie Spielmenü und Dialoge. Auch Questtexte, Bücher und Briefe tragen Gold statt deiner Klasse.

### Technisch

- Talente, **gemessen** (6.8.0.3, `/wcui fenster`): „Bäume keine gefunden“ – der Forever-Client nennt die Bäume über `GetTalentTabInfo` nicht. `TL.Names()` fragt jetzt `GetTalentTabInfo`, `GetSpecializationInfo` und, für die eigene Klasse, `data/specs.lua` (`WeintCodex.Specs.ForClass`); Suche bis Tiefe 6. Findet sie keinen Namen, nennt der Bericht, was gesucht wurde und woher, und bis zu sechs Schriftzeilen des Fensters – die nächste Messung sagt dann, wie die Bäume dort heißen.
- Talente: Licht und Kante auf `OVERLAY` 6/7 des Talentfensters (über Wolken und Landschaften, unter den Talenten im Kindrahmen), Licht 16 % über 220 px statt `GC.classLight` (7 %) – im Spiel war davon nichts zu sehen.
- Neu `ui/gossip.lua` (`WeintCodex.UIGossip`): `GossipFrame`, `QuestFrame`, `ItemTextFrame` in `S.CALM` (Schein der Klasse aus über `W.HoldGlow`), neutrales Licht und Kante in Gold; **gemessen** `GossipFrame.GreetingPanel.ScrollBox` auf der angehobenen Fläche mit Schatten und Kante in Gold, `.ScrollBar` als Ecke. Questtext und Bücher ungemessen: keine Fläche.
- Testattrappe: `SetDrawLayer` merkt sich die Ebene. `load_test.lua`: Talente ohne `GetTalentTabInfo` (Namen aus `data/specs.lua`, fremde Klasse: Bericht mit Hinweis), Licht/Kante auf `OVERLAY`; Gespräche in Gold, Fläche, kein Schein, kein Müll.

## [6.8.0.3] – 2026-09-29

**Die Talente passen zum Zauberbuch.** Statt des großen Scheins in deiner Klassenfarbe fällt ein Hauch Licht in deiner Klasse von oben, oben liegt eine feine Kante in deiner Klasse, und die Namen der Bäume – etwa Waffen, Furor, Schutz – tragen Raute und Linie wie die Überschriften im Zauberbuch.

**Die Animation bleibt.** Wolken, Funken und die Landschaften hinter den Bäumen sind unverändert, ebenso die Talente mit ihren farbigen Rahmen, die Punkte je Baum und „Änderungen anwenden“.

### Technisch

- Neu `ui/talents.lua` (`WeintCodex.UITalents`): `PlayerSpellsFrame.TalentsFrame` in `S.CHARACTER_INFO`, in `W.HOSTED.PlayerSpellsFrame` neben dem Zauberbuch. Licht in der Klassenfarbe (`GC.classLight`, 180 px) und Kante (50 %) **auf** dem Talentfenster (`BORDER`/`ARTWORK` 7 – darunter läge es hinter den Landschaften); Schein der Klasse aus, solange die Talente offen sind (`GlowOff`). Namen der Bäume: Schriftzeilen, deren Text ein Name aus `GetTalentTabInfo` ist (beide Fassungen: `name, …` und `id, name, …`), gesucht bis alle da sind, höchstens 30 Durchläufe; Raute und Linie (140 px, nur links verankert) am Rahmen der Zeile.
- Animation (`talents-animations-*`) und Landschaften (`talent-background-*`) unberührt.
- `load_test.lua`: Talente wie gemessen – Licht und Kante in der Klassenfarbe auf dem Talentfenster, drei Namen gefunden (kein Rang eines Talents), Animation unberührt, Suche endet, Schein zurück bei geschlossenen Talenten.

## [6.8.0.2] – 2026-09-29

**Die Sammlung in der ruhigen Oberfläche.** Kein Schein in deiner Klassenfarbe mehr oben im Fenster; die Vorlagen liegen auf einer Fläche mit weichem Schatten und feiner Kante in Gold, gewählte Reiter tragen Gold – wie Suche nach Gruppe, Gilde und Karte. Plätze, Klassenauswahl, Suche, Filter und Blättern bleiben, wie das Spiel sie zeigt.

### Technisch

- `ui/lfg.lua` heißt jetzt `ui/calm.lua` (`WeintCodex.UICalm`): „Fenster in Gold mit Innenflächen“, allgemein – Suche nach Gruppe und neu `CollectionsJournal` (gemessen: Vorlagen in `WardrobeCollectionFrame.ItemsCollectionFrame`, seit 6.6.3.3 Innenfläche). Bericht je Fenster („Sammlung (Stil ruhig): …“).
- `SkinTabSystems`/`SkinTab`: der gewählte Reiter eines Reitersystems trägt den Akzent seines Fensters (Gold in einem Fenster in Gold) statt immer die Klassenfarbe – wie die Seitenreiter seit 6.7.5.0.
- `load_test.lua`: Sammlung wie gemessen (Innenfläche mit Kante, kein Schein, Bericht), Reiter oben in Gold.

## [6.8.0.1] – 2026-09-29

**„Gruppen durchsuchen“ und „Spielersuche“ ohne Stein.** Der graue Stein, der Marmor und die goldenen Linien über und unter der Liste sind weg; beide Reiter liegen auf derselben ruhigen Fläche mit weichem Schatten und feiner Kante in Gold wie der erste Reiter. Texte, Filter, Suche und Knöpfe bleiben, wie das Spiel sie zeigt.

### Technisch

- Gemessen (`/wcui fenster` auf beiden Reitern): `LFGBrowseFrame` und `LFGWhoListFrame` tragen Marmor (Bild 374155), `groupfinder-Stat-StoneBG` und zwei `groupfinder-ScrollLine`; der Bericht nannte auf der Spielersuche „0 Innenflächen“. Beide stehen jetzt in `W.OWN_BG_PATHS` (eigene Bilder weg, Innenfläche wie die Sammlung) – damit findet `ui/lfg.lua` sie über `W.Insets` und gibt Schatten und Kante in Gold. Die beiden Atlanten zusätzlich in `W.HIDE_ATLAS`.
- `load_test.lua`: beide Reiter wie gemessen – Bilder weg, Texte bleiben, Innenfläche mit Kante.

## [6.8.0.0] – 2026-09-29

**„Suche nach Gruppe“ in der ruhigen Oberfläche.** Kein Schein in deiner Klassenfarbe mehr oben im Fenster, sondern ein Hauch neutrales Licht; die Flächen im Fenster tragen einen weichen Schatten und oben eine feine Kante in Gold, der gewählte Seitenreiter ebenfalls Gold – wie Spielmenü, Gilde und Karte.

**Rollen und Hinweise unverändert.** Rollensymbole, die Fahne für neue Spieler, die Auswahl der Rolle, Texte und Knöpfe bleiben, wie das Spiel sie zeigt.

### Technisch

- Neu `ui/lfg.lua` (`WeintCodex.UILFG`): `LFGParentFrame` (gemessen) und `PVEFrame` (Quelltext des Spiels) in `S.CALM`, in `W.HOSTED`. Schein der Klasse aus (`W.HoldGlow`), neutrales Licht (120 px). Jede Innenfläche des Fensters (`W.Insets`, von `W.SkinInsets` seit 6.6.2.2 gestaltet; nur die, die unter dem Fenster hängen) bekommt Schatten und Kante in Gold, aus mit ihr – gefunden ohne Namen, die Messung zeigte keinen.
- Version 6.8.0.0 statt 6.7.10.0: ob irgendwo Fassungen als Text verglichen werden („6.7.10.0“ < „6.7.9.0“), ist ungeprüft.
- `load_test.lua`: Innenfläche mit Kante und Schatten, die eines anderen Fensters nicht, aus mit ihr, kein Schein, Gold.

## [6.7.9.0] – 2026-09-29

**Das Spielmenü in der ruhigen Oberfläche.** Statt des Scheins in deiner Klassenfarbe ein Hauch Licht von oben und eine feine Kante in Gold; unter „Spielmenü“ eine Linie mit Raute, und zwischen den Gruppen – Optionen, Addons bis Makros, Ausloggen und Spiel verlassen, Zurück zum Spiel – je eine zarte Trennlinie.

**Dialoge wie „20 Sekunden bis zum Verlassen“ passen dazu.** Kein Schein in der Klassenfarbe mehr über dem ganzen Dialog, sondern dasselbe ruhige Licht und dieselbe Kante in Gold. Texte, Knöpfe und was sie tun bleiben unverändert.

**Karte & Questlog im selben Stil.** Der Questlog liegt auf einer ruhigen, leicht angehobenen Fläche mit feiner Kante in Gold; Zonen wie „Die Todesminen“ stehen links als Abschnitte mit Raute und Linie, wie im Ruf. Der weiche Rand um die Karte bleibt genau so, wie er ist, und die Farben der Quests zeigen weiter ihre Schwierigkeit.

### Technisch

- Neu `ui/gamemenu.lua` (`WeintCodex.UIGameMenu`): `GameMenuFrame` in `S.CALM`, in `W.HOSTED`. Neutrales Licht (110 px), Kante oben in Gold, Linie mit Raute unter dem Titel (`.Header.Text`, sonst oberste Zeile des Kopfes), Haarlinie in jeder Lücke > 6 px zwischen sichtbaren Knöpfen – je Durchlauf an deren Lage gemessen, ohne Anlage, höchstens sechs. Schein der Klasse aus (`W.HoldGlow`). Nichts bewegt.
- `W.SkinPopup` (`StaticPopup1..4`): statt des Scheins in der Klassenfarbe neutrales Licht (60 px) und Kante in Gold, Stil `S.CALM`.
- `load_test.lua`: Menü mit drei Gruppen (Linien in den Lücken, eine weniger ohne Knopf), Dialog ohne Klassenfarbe.
- Neu `ui/questlog.lua` (`WeintCodex.UIQuestLog`): `WorldMapFrame` in `S.CALM`; `QuestScrollFrame` auf der angehobenen Fläche (Schatten klein, 8 px – links liegt die Karte), Kante in Gold, aus mit der Seitenleiste. `W.SkinMap` gestaltet die Kopfzeilen mit dem Stil des Fensters (Zonen als Abschnitte wie im Ruf); `W.Inner` ruft für die Karte `W.HOSTED.WorldMapFrame` und `W.HoldGlow`. Die Karte selbst (weicher Rand, `W.SoftMap`) wird nicht berührt.
- `load_test.lua`: Karte & Questlog – Zone als Abschnitt in Gold, Fläche an der Karte (nicht auf ihr), weicher Rand unverändert, nichts Neues auf der Karte.

## [6.7.8.0] – 2026-09-29

**Ein bisschen Klassenfarbe im Zauberbuch.** Von oben fällt ein Hauch Licht in deiner Klassenfarbe, die Fläche mit deinen Zaubern trägt oben eine feine Kante in deiner Klasse – wie die Karten in Ruf und Fertigkeiten. Nicht mehr der große Schein über der halben Seite.

**Die Linie hinter „Allgemein“ ist da.** Hinter Überschriften im Zauberbuch und hinter Schmiedekunst und Bergbau in der Berufsübersicht fehlte die feine Linie nach der Raute – sie war falsch befestigt und wurde nicht gezeichnet.

**Gilde & Communitys in der ruhigen Oberfläche.** Liste, Chat und Mitglieder liegen auf eigenen, leicht angehobenen Flächen mit weichem Schatten und feiner Kante in Gold; dezente Randabdunklung und ein Hauch Licht. Die Gilde gehört nicht zu deiner Klasse – deshalb Gold statt Klassenfarbe, auch am gewählten Eintrag links und am Seitenreiter, und kein Schein in der Klassenfarbe mehr.

**Namen und Farben bleiben.** Chat, Mitgliederliste, Wappen, Kronen und „online“ zeigen alles, wie das Spiel es zeigt; die Mitgliederliste behält innen ihren gewohnten Grund.

### Technisch

- `ui/spellbook.lua`: Licht von oben in der Klassenfarbe (`GC.classLight`, 7 %, 180 px statt neutral 3,5 %/140 px), Kante über der Fläche in der Klassenfarbe (50 %) statt weiß.
- `ui/spellbook.lua`, `ui/profbook.lua`: die Linie hinter einer Überschrift war links an der Raute und rechts an `"RIGHT"` der Seite bzw. Karte verankert – das ist deren **halbe Höhe**, nicht die Höhe der Zeile; im Spiel wurde sie nicht gezeichnet (Screenshot: nur die Raute). Jetzt nur links verankert, Breite gerechnet (Rand minus Einzug minus Text), neu bei geänderter Lage.
- `load_test.lua`: Breite der Linie, nur ein Anker (links), Licht und Kante in der Klassenfarbe.
- Neu `ui/community.lua` (`WeintCodex.UICommunity`): `CommunitiesFrame` in `S.CALM` (Gold), in `W.HOSTED`. Vignette und neutrales Licht; je Spalte (Liste `CommunitiesFrameCommunitiesList`, Chat `.Chat` samt `.ChatEditBox`, `.MemberList`) die angehobene Fläche mit Schatten und Kante in Gold, sichtbar nur mit ihrer Spalte. Schein der Klasse aus (`W.HoldGlow`, Fenster in Gold).
- `W.NavEntry` (Einträge links): der gewählte trägt den Akzent des Bereichs (Gilde: Gold) statt immer die Klassenfarbe.
- `load_test.lua`: Gilde wie gemessen – Gold, drei Spalten, Spalte zu = Fläche weg, Eintrag in Gold, kein Schein.

## [6.7.7.0] – 2026-09-29

**Das Zauberbuch in der ruhigen Oberfläche.** Statt des großen Scheins in deiner Klassenfarbe über der halben Seite liegen deine Zauber auf derselben ruhigen, leicht angehobenen Fläche wie Ruf und Fertigkeiten, mit dezenter Randabdunklung und einem Hauch Licht. Überschriften wie „Allgemein“ tragen Raute und Linie in deiner Klassenfarbe.

**Zauber unverändert.** Symbole, Namen, „Passiv“, der Schein an Zaubern, die noch auf keiner Leiste liegen, Reiter, Suche und Blättern bleiben, wie das Spiel sie zeigt. Die Talente behalten ihr Aussehen.

**Im Berufsfenster kein Schein in der Klassenfarbe mehr.** Es trägt nur noch sein Gold.

### Technisch

- Neu `ui/spellbook.lua` (`WeintCodex.UISpellBook`): `PlayerSpellsFrame.SpellBookFrame` (gemessen), in `W.HOSTED.PlayerSpellsFrame`, Stil `S.CHARACTER_INFO` nur für das Zauberbuch (nicht die Talente). Fläche unter `PagedSpellsFrame`, Vignette und neutrales Licht, Überschrift = Eintrag in `View1`/`View2` ohne `.Button` → Raute und Linie hinter dem Text (Schrift und Lage bleiben).
- `ui/windows.lua`: `W.HoldGlow` – der Schein der Klasse (`W.AddGlow`) ist in Fenstern in Gold (`S.CALM`) immer aus, sonst aus, solange ein gestalteter Teil es will (`GlowOff`, Zauberbuch); versteckt und je Durchlauf gehalten. Behebt die Klassenfarbe im Berufsfenster seit 6.7.5.0.
- `load_test.lua`: Zauberbuch wie gemessen, Schein im Zauberbuch aus und bei den Talenten zurück, im Berufsfenster nie.

## [6.7.6.0] – 2026-09-29

**Die Berufsübersicht passt zur Rezeptseite.** Jeder Beruf liegt auf einer ruhigen, leicht angehobenen Karte mit weichem Schatten statt der braunen Fläche; der Name des Berufs ist die Überschrift der Karte, mit Raute und Linie in Gold. Die Bilder hinter den Nebenberufen sind weg – hinter Text steht nichts mehr.

**Fortschrittsbalken mit Tiefe, Farbe unverändert.** Wie bei den Fertigkeiten: Schatten und Lichtkante an der Füllung; Farbe, Glanz und Werte wie „Kochkunst 8/75“ bleiben, wie das Spiel sie zeigt. Symbole, Rang, Zauber und der Knopf zum Verlernen sind unverändert.

### Technisch

- Neu `ui/profbook.lua` (`WeintCodex.UIProfessionBook`): Übersicht des Berufsfensters (`BookPage.ProfessionsContentFrame`, gemessen), in `W.HOSTED.ProfessionsFrame` neben der Rezeptseite. Je Karte (`PrimaryProfession1/2`, `SecondaryProfession1..3`): Fläche des Registers, Titel (oberste Zeile) als Abschnitt – links mit Raute und Linie, mittig mit Linie darunter –, `S.BarFinish` am `.StatusBar`, Rahmen der Karte (`NineSlice`/`Border`) weg.
- `ui/windows.lua`: `Profession-overview-Card` und `Profession-overview-card-generic-*` ausgeblendet statt gedämpft (standen hinter Text); `W.TONE_ATLAS` nur noch der Dungeonbrowser.
- `load_test.lua`: Übersicht wie gemessen, Gold statt Klassenfarbe, nichts bewegt.

## [6.7.5.0] – 2026-09-29

**Die Rezepte deiner Berufe im neuen Stil.** Die Rezeptliste liegt wie Ruf und Fertigkeiten auf einer ruhigen, leicht angehobenen Fläche, Kategorien wie „Alltägliche Mahlzeiten“ stehen als eigene Abschnitte mit Raute und Linie, Rezepte sind fein voneinander abgesetzt, das gewählte trägt einen schmalen Streifen. Rechts ist das Rezept eine Karte: Name oben größer in seiner Farbe, Beschreibung, darunter abgesetzt Reagenzien und was es braucht.

**Berufe tragen Gold statt deiner Klassenfarbe.** Sie gehören nicht zu deiner Klasse – deshalb ein ruhiges Gold für Abschnitte, Linien und den gewählten Seitenreiter. Das große Bild hinter dem Rezept und die Hintergründe der Seite sind weg, hinter Text steht nichts mehr. Rangbalken, Symbole, Reagenzien und Knöpfe bleiben, wie das Spiel sie zeigt.

### Technisch

- Neu `ui/professions.lua` (`WeintCodex.UIProfessions`): `ProfessionsFrame.CraftingPage` als Register, gemessen (`/wcui fenster` auf der Kochkunst): Liste `RecipeList.ScrollBox`, Zeilen mit `Professions_Recipe_Hover/_Active`, Rezept `SchematicForm`. Stil `S.CALM` für das ganze Berufsfenster – das erste Fenster in Gold.
- `ui/register.lua`: `host` (Register außerhalb des Charakterfensters, über `W.HOSTED` in `W.Inner` und `/wcui fenster`), Pfade in `listKeys`/`scrollBarKeys`, `highlightAtlas`, `titleColor = false`.
- `ui/style.lua`: `S.CALM` mit Band und 14 pt wie `S.CHARACTER_INFO` – nur der Akzent unterscheidet sich.
- `ui/windows.lua`: der gewählte Seitenreiter trägt den Akzent seines Fensters (Gold in den Berufen); ausgeblendet `Profession-Background-Template*`, `Professions-background-summarylist`, `Profession-background-card-*`.

## [6.7.4.0] – 2026-09-29

**Die Statistiken im neuen Stil.** Die lange Liste liegt wie Ruf, Fertigkeiten und Abzeichen auf einer ruhigen, leicht angehobenen Fläche; „Charakter“ steht als Abschnitt mit Raute und Linie in deiner Klassenfarbe links, wo das Spiel ihn hinsetzt, die Einträge sind fein voneinander abgesetzt und leuchten unter der Maus in deiner Klasse auf. Werte, Gruppen wie „Vermögen“ und ihre Knöpfe zum Auf- und Zuklappen bleiben, wie das Spiel sie zeigt.

### Technisch

- Neu `ui/statistics.lua` (`WeintCodex.UIStatistics`): `StatisticsFrame` als viertes Register, gemessen (`/wcui fenster`): Zeilen unter `ScrollBox.ScrollTarget` mit `.Content.BackgroundHighlight` wie im Ruf, Gruppen mit `.ToggleCollapseButton`.
- `ui/register.lua`: `listOnly` – Register ohne Detailansicht (keine Suche, keine Auswahl, Bericht „nur die Liste“).
- `load_test.lua`: Statistiken wie gemessen.

## [6.7.3.0] – 2026-09-29

**Die Abzeichen im neuen Stil.** Deine Währungen liegen wie Ruf und Fertigkeiten auf einer ruhigen, leicht angehobenen Fläche; Gruppen stehen als eigene Abschnitte mit Raute und Linie in deiner Klassenfarbe, die Einträge sind fein voneinander abgesetzt, die gewählte Währung trägt einen schmalen Streifen. Symbol, Name und Anzahl bleiben, wie das Spiel sie zeigt.

**Die Detailansicht der Abzeichen ist eine Karte.** Name oben, darunter die Beschreibung, was folgt in einem eigenen, abgesetzten Bereich; die Karte endet unter ihrem Inhalt. Ist noch keine Währung gewählt, bleibt es bei der ruhigen Fläche mit dem Hinweis des Spiels.

### Technisch

- Neu `ui/currency.lua` (`WeintCodex.UICurrency`): `TokenFrame` als drittes Register. Gemessen nur der Leerzustand (Liste leer, Hinweis rechts); Liste, Zeilen und Detailansicht über mehrere Schlüssel, dann Suche.
- `ui/register.lua`, allgemein: **Leerzustand** – zeigt die Detailansicht nur eine Schriftzeile (Hinweis), werden Titel und Beschreibung noch nicht bestimmt (sonst wäre der Hinweis für immer Titel in 16 pt); `listKeys`; Beschreibung und Titel nur aus sichtbaren Zeilen; gefundene Detailansicht nur gemerkt, solange sichtbar; `R.Options` legt ohne Häkchen keine Tabelle mehr an (traf auch die Fertigkeiten: eine leere Tabelle je Durchlauf).
- `load_test.lua`: Abzeichen leer und mit Währung, mit Fallen (Hinweis über dem Titel und länger als die Beschreibung).

## [6.7.2.2] – 2026-09-29

**Das PvP-Fenster ist jetzt wirklich im neuen Stil.** Bisher erkannte WeintCodex den Reiter „Spieler gegen Spieler“ nicht und ließ ihn, wie er war. Jetzt steht dein Wappen als Mittelpunkt vor einem weichen dunklen Hof, Rang, Medaillon und Rangpunkte liegen gemeinsam auf einer ruhigen, leicht angehobenen Fläche.

**Rang und Belohnung rechts als Karte wie bei Ruf und Fertigkeiten.** Der Rang oben größer, darunter eine feine Linie und die Beschreibung; „Nächste Belohnungen auf Rang …“ steht als Abschnitt mit Raute und Linie in deiner Klassenfarbe, die Belohnung auf einer eigenen, leicht vertieften Fläche. Farben und Texte des Spiels bleiben unverändert.

### Technisch

- `ui/pvp.lua` auf den gemessenen Aufbau gestellt (`/wcui fenster` nach 6.7.2.0): Fenster `PVPRankFrame` (fehlte – 6.7.2.0 griff im Spiel nicht), Detailansicht `.DetailFrame`, Rangsymbol über den Atlas `UI-Character-Info-Honor-Icon…` (das größte Bild ist der Schein des Medaillons), Medaillon = Rahmen des Symbols im Fenster (in den Rangbereich), Rang nur eine Zeile mit Wort (die „0“ im Ring ist die nächste Belohnungsstufe), Belohnung auch als Rahmen ohne Knopf. Ist die Überschrift eine Kopfzeile des Spiels, gestaltet sie `W.ListHeader` wie bei den Fertigkeiten; dann kein zweites Ornament.
- `W.Resolve` ohne `gmatch`: legte in jedem Durchlauf eine Closure an, sobald ein Fenster über einen Pfad gesucht wurde (PvP, Fertigkeiten).
- `load_test.lua`: der gemessene Aufbau als zweiter PvP-Fall mit den drei Fallen (Schein, „0“, Rahmen statt Knopf); Medaillon außerhalb des Fensters.

## [6.7.2.1] – 2026-09-29

**Die Detailansicht im Ruf ist gegliedert wie die Fertigkeiten.** Fraktionsname, Rufstufe und Rufbalken bilden gemeinsam den Kopf der Karte, die feine Linie in deiner Klassenfarbe steht jetzt unter dem Balken, darunter beginnt die Beschreibung. Die Farben der Rufstufen bleiben, wie das Spiel sie zeigt.

**Die Karte im Ruf endet immer unter ihrem Inhalt.** Auch wenn „Im Krieg“, „Inaktiv“ und „Als Erfahrungsleiste anzeigen“ an ihrem gewohnten Platz bleiben, reicht die Fläche nur bis knapp unter die Optionen.

### Technisch

- `ui/reputation.lua`: `barLine = "below"` und `compact = true` – dieselben Einstellungen des Registers wie `ui/skills.lua`. Kein neuer Baustein, keine Änderung an `ui/register.lua` oder `ui/style.lua`. Ruf behält als Eigenheit nur das Codex-Zeichen und das Rücken der Häkchen.
- `load_test.lua`: Linie unter dem Balken (−89), Karte endet unter den Häkchen – gerückt (−252) und ungerückt (−362).

## [6.7.2.0] – 2026-09-29

**Das PvP-Fenster ist ein PvP-Profil.** Dein Rangsymbol steht als Mittelpunkt vor einem weichen dunklen Hof mit einem Hauch Licht; Symbol, Rang, Rangpunkte und Fortschritt liegen gemeinsam auf einer ruhigen, leicht angehobenen Fläche unter einer feinen Linie mit Raute. Die Rangpunkte sind etwas größer, ihre Farbe bleibt, wie das Spiel sie zeigt.

**Rang und Belohnung rechts als Karte.** Der Rang oben groß in seiner Farbe, darunter eine feine Linie und die Beschreibung; vor „Nächste Belohnungen“ eine Linie mit Raute, die Belohnung – Symbol, Name in ihrer Qualitätsfarbe, Beschreibung – auf einer eigenen, leicht vertieften Fläche. Die Karte endet unter ihrem Inhalt.

**Etwas mehr Atmosphäre im PvP.** Eine kräftigere Randabdunklung und unten am Rand zwei kaum sichtbare, entfernte Fackeln – kein Bild, nichts hinter Text.

### Technisch

- Neu `ui/pvp.lua` (`WeintCodex.UIPvP`): PvP-Reiter als Profil. Ungemessen – alles über Lage und Form gefunden (Detailansicht = Kind mit dem längsten Text, Rangsymbol = größtes etwa quadratisches Bild außerhalb, Rangpunkte = „Zahl / Zahl“, Rang = Zeile nächst dem Symbol, Belohnung = Knopf mit Symbol, Überschrift = Zeile direkt darüber). Nichts bewegt, keine Farbe des Spiels überschrieben; `/wcui fenster` nennt, was gefunden wurde.
- `ui/style.lua`, generisch: `S.Stage`/`S.FitStage` (Mittelpunkt), `S.Ornament`/`S.PlaceOrnament` (Linie mit Raute), `S.PlaceRect` (Fläche nach Zahlen), `S.Title(fs, size, false)` behält die Farbe des Spiels. `core/ui.lua`: `stageShade`, `stageLight`, `torchGlow`.
- `W.TABS` in `ui/windows.lua`: gestaltete Reiter des Charakterfensters tragen sich selbst ein (Register und PvP); `RG.FindBar`/`RG.BarFill` und weitere Werkzeuge aus dem Register herausgelöst.

## [6.7.1.0] – 2026-09-29

**Die Fertigkeiten im neuen Stil.** Berufe, Sekundäre Fertigkeiten und Waffenfertigkeiten stehen als eigene Abschnitte mit Raute und Linie in deiner Klassenfarbe, die Einträge sind fein voneinander abgesetzt, die gewählte Fertigkeit trägt einen schmalen Streifen in deiner Klasse. Die Liste liegt auf einer ruhigen, leicht angehobenen Fläche wie im Ruf.

**Fortschrittsbalken mit Tiefe, Farbe unverändert.** Dunklere Bahn, Schatten und Lichtkante an der Füllung – die Farbe und die Werte wie „32 / 75“ bleiben genau so, wie das Spiel sie zeigt.

**Die Detailansicht der Fertigkeiten ist eine Karte.** Name und Fortschritt oben, darunter eine feine Linie, dann die Beschreibung; was darunter folgt, steht in einem eigenen, abgesetzten Bereich, und die Karte endet unter ihrem Inhalt.

### Technisch

- Neuer Baustein `ui/register.lua` (`WeintCodex.UIRegister.New(cfg)`): Liste des Spiels + Detailkarte, entstanden aus dem Ruf. `ui/reputation.lua` ist jetzt ein Einstellungssatz davon (Verhalten und Test unverändert), `ui/skills.lua` der zweite. `W.Inner` und `/wcui fenster` bedienen alle Register (`UIRegister.all`).
- Fenster tragen ihren Stil selbst in `S.SCOPES` ein; `S.Register` löst auch Pfade auf (`CharacterFrame.SkillsFrame`). `ui/style.lua` kennt keinen Fensternamen mehr.
- Neu im Register (allgemein, per Einstellung): Detailansicht per Suche (`detailSearch`), Titel als oberste Schriftzeile (`titleTop`), Titel im Balken bleibt unverändert, Linie unter dem Balken (`barLine = "below"`), abgesetzter Bereich für das, was unter der Beschreibung folgt (`tail`, nichts wird bewegt), Karte endet unter dem Inhalt (`compact`), Zeilenbalken auch ohne bekannten Schlüssel.
- `SkillsFrame` in `W.PANELS`. Kein Codex-Zeichen bei den Fertigkeiten: kein passendes Motiv unter den Grafiken, keines erzwungen.

## [6.7.0.3] – 2026-09-29

**Die Detailansicht im Ruf ist jetzt eine kompakte Karte.** Name, Rufstufe, Fortschritt und Beschreibung stehen oben; „Im Krieg“, „Inaktiv“ und „Als Erfahrungsleiste anzeigen“ rücken direkt unter die Beschreibung in ihren eigenen, abgesetzten Bereich, und die Karte endet kurz darunter – kein leerer schwarzer Raum mehr bis zum unteren Rand. Ist eine Beschreibung lang, bleiben die Optionen an ihrem gewohnten Platz; sie funktionieren unverändert.

### Technisch

- `ui/reputation.lua`, „Die Karte“: die Häkchen der Detailansicht rücken per `SetPoint` gemeinsam unter den Text der Beschreibung (`RP.DetailDescription`: Schlüssel oder längster Text; Ende = Oberkante − `GetStringHeight`), nur nach oben, nie tiefer als das Spiel sie setzt, mit den Abständen des Spiels (`RP.Options` misst einmal vor jeder Bewegung). Nicht gerückt, wenn eine Beschriftung nicht am Häkchen hängt oder ein weiterer Knopf sichtbar ist (`d.why`). Schiebt das Spiel sie zurück, rückt der nächste Durchlauf sie wieder hin.
- Fläche und Schatten der Karte enden unter den Optionen (`RP.PlaceCard`); die Beschreibungsfläche aus 6.7.0.2 ist weg (im Spiel nicht zu sehen).
- `/wcui fenster`: „Ruf, Karte: …“ und „Ruf, Optionen: um N px nach oben gerückt / nicht gerückt (Grund)“.

## [6.7.0.2] – 2026-09-29

**Die Detailansicht im Ruf ist eine Codex-Tafel.** Der Fraktionsname steht größer als Hauptinformation, darunter die Rufstufe. Eine feine Linie in deiner Klassenfarbe trennt sie vom Rufbalken, der mit weichem Schatten deutlicher hervortritt. Die Beschreibung liegt auf einer eigenen, leicht vertieften Fläche; „Im Krieg“, „Inaktiv“ und „Als Erfahrungsleiste anzeigen“ stehen unter einer Linie mit Raute in einem eigenen, ruhigen Optionsbereich.

**Gruppen im Ruf sind eigene Abschnitte.** Jede Gruppe beginnt mit einer feinen Linie und einem Hauch Licht von links; die Überschrift ist etwas größer. Zwischen den Fraktionen liegen zarte Trennlinien, die Einrückung des Spiels bleibt.

**Die gewählte Fraktion leuchtet dezenter, aber klar.** Schmaler Streifen und ein kurzer Schein in deiner Klassenfarbe, die Zeile eine Spur heller – kein farbiger Block mehr. Die Farben der Rufstufen (Neutral gelb, Freundlich grün …) bleiben, wie das Spiel sie zeigt.

**Mehr Tiefe im Ruf.** Liste und Detailansicht liegen auf unterschiedlich dichten Flächen mit weichem Schatten; unten rechts in der Liste liegt, kaum sichtbar, ein Astrolab als Zeichen des Codex.

### Technisch

- `ui/style.lua`: `S.Band` (Kopfzeile als Sektion), `S.Hairline`, `S.Under`, `S.Shadow`, `S.PlaceBand`; `S.PlaceTop` mit Höhe und Kante; Auswahl mit `lift` und schmalem Schein (`S.SELECT_SPREAD`). `S.CHARACTER_INFO` mit `band`/`headerSize`.
- `core/ui.lua`: `surfaceDetail`, `surfaceSunken`, `shadowSoft`, `sectionBand`, `hairline`, `selectLift`, `codexSigil` – alles neutral, keine Farbe.
- `ui/reputation.lua`: Tafel der Detailansicht (`RP.DetailBar`, `RP.OptionTop`, `RP.DetailLayout`): Grenzen nach Oberkante des Balkens und des obersten Häkchens, neu gelegt nur bei Änderung; kein Rahmen des Spiels wird verschoben. Hervorhebung des Spiels 30 % statt 55 %.
- `media/ui/sigil.tga` (256×256, erzeugt von `make_ui_media.py`): eigenes Astrolab.
- Nicht umgesetzt: echter Abstand zwischen Gruppen – dafür müsste die Liste des Spiels anders angeordnet werden.

## [6.7.0.1] – 2026-09-29

**Der Ruf trägt deine Klassenfarbe.** Er gehört zum Charakterfenster – Rauten und Linien der Gruppen, die gewählte Fraktion und die Zeile unter der Maus stehen jetzt in deiner Klasse statt in Gold. Rot beim Krieger, Grün beim Jäger, Weiß beim Priester.

**Mehr Tiefe statt Schwarz.** Liste und Detailansicht liegen auf einer leicht helleren, weich auslaufenden Fläche mit einer feinen Lichtkante oben; darum herum sehr dunkles Anthrazit, eine dezente Randabdunklung und neutrales Licht von oben. Keine harten schwarzen Kästen mehr nebeneinander.

**Die Detailansicht gehört zur selben Oberfläche.** Kein eigener schwarzer Kasten mehr: dieselbe Fläche wie die Liste, oben eine feine Kante in deiner Klassenfarbe.

**Rufbalken mit Tiefe, jetzt wirklich.** Schatten und Lichtkante an der Füllung, eine weichere Kante um die Bahn – Farbe und Text der Rufstufe bleiben, wie das Spiel sie zeigt.

### Technisch

- Neuer Stil `S.CHARACTER_INFO` (Klassenfarbe, Kopfzeilen als Listenzeile) für die Informations-Reiter des Charakterfensters; `S.SCOPES.ReputationFrame` nutzt ihn. `S.CALM` (Gold) bleibt für Fenster außerhalb des Charakters, zurzeit in keinem Gebrauch.
- Flächen: `GameColors.surfaceRaised` (heller als die Basis) statt `panelWell` (dunkler), `atmosLight` (neutral), `barTrack` dunkler, Rand der Balken weich (`barEdge`).
- Balken gemessen: `Content.ReputationBar` ist in diesem Client kein Statusbalken, die Füllung ist das Bild `common-stat-bar-white` – 6.7.0.0 fand deshalb 0 Balken. `RP.BarFill`, `S.BarFinish(bar, fill)`.
- Hervorhebung des Spiels (`Content.BackgroundHighlight`, `charactercreate-customize-dropdown-linemouseover-*`) entsättigt und in der Klassenfarbe getönt (`S.Tint`); eigene Mausfläche nur ohne sie.
- Detailansicht im Fenster: `RP.Surface` statt Tafel, Kante oben in der Klassenfarbe (`S.PlaceTop`) statt Trennlinie unter dem Titel.

## [6.7.0.0] – 2026-09-29

**Der Ruf im neuen Stil der Fenster.** Dunkle, ruhige Fläche wie im Charakterfenster, die Liste liegt auf einem weich auslaufenden dunklen Grund, oben ein Hauch warmes Gold. Gruppen tragen eine Raute und eine feine goldene Linie und bleiben so eingerückt wie im Spiel – Gruppen in Gruppen sind wieder als solche zu erkennen.

**Die gewählte Fraktion ist auf einen Blick zu sehen.** Links ein goldener Strich, dahinter ein Hauch Gold – es ist die, die rechts in der Detailansicht steht. Unter der Maus wird jede Zeile heller.

**Rufbalken mit mehr Tiefe.** Dunklere Bahn, Schatten und Lichtkante an der Füllung; Farbe und Text der Rufstufe bleiben, wie das Spiel sie zeigt.

**Detailansicht als eigene dunkle Tafel.** Statt des Dialograhmens, mit größerem Fraktionsnamen und einer goldenen Trennlinie darunter. Beschreibung, Häkchen und Knöpfe bleiben unverändert.

### Technisch

- Neue Stil-Schicht `ui/style.lua` (`WeintCodex.UIStyle`): Akzente, Stile je Bereich (`S.SCOPES`), Verlauf, Raute, Trennlinie, weiche Fläche, Vignette, Licht von oben, Tafel, Maus, Auswahl, Balken-Veredelung, Schrift. `W.Diamond`, `W.Fade`, `W.own` und `UICharacter.Gradient` sind jetzt diese Bausteine.
- Zweiter Akzent `GameColors.frameAccent` (gedämpftes Gold) für Fenster, die nicht der Klasse gehören; nie in derselben Fläche wie die Klassenfarbe, nicht von `SetAccent` umgerechnet.
- `W.HideByAtlas` reicht den Stil eines Rahmens an alles darunter weiter; im Stil `S.CALM` werden Kopfzeilen `W.ListHeader` (Text bleibt stehen) und Balkenbahnen `barTrack`.
- `ui/reputation.lua` (`WeintCodex.UIReputation`): Atmosphäre, Zeilen, Auswahl, Detailansicht, Bericht in `/wcui fenster`. Charakter, Fertigkeiten und alle anderen Fenster bleiben unverändert.

## [6.6.4.5] – 2026-09-29

**Alle Klassen haben jetzt ihre Szene im Charakterfenster.** Krieger stehen in einer Waffenkammer mit Thron und Esse, Druiden in einem Hain mit Geweihtor, Magier in einer arkanen Halle unter einer Armillarsphäre, Schurken in einem nächtlichen Versteck mit Laternen, Hexenmeister vor einem grünen Portal, Paladine in einer Lichthalle vor dem Altar, Schamanen in einem Steinkreis unter dem Sturm. Jede Figur nimmt das Licht ihrer Szene an; Aufbau, Werte und deine Klassenfarbe als Akzent bleiben dieselben.

## [6.6.4.4] – 2026-09-29

**Jäger bekommen ihre eigene Szene im Charakterfenster.** Hinter deiner Figur steht ein Jägerlager im Wald – Tor mit Hirschbanner, zwei Wölfe, Wasserfall und Fackeln –, weich auslaufend wie beim Priester. Die Figur nimmt das Licht der Szene an: warme Sonne, ein Hauch Grün vom Laub, Schatten und Dunst am Boden. Aufbau und Werte bleiben dieselben; dein Grün erscheint nur in Linien, Rauten, belegten Plätzen und unter der Maus.

## [6.6.4.3] – 2026-09-29

**Die Kopfzeile im Charakterfenster zeigt immer deinen Namen.** Nach einem Wechsel vom Reiter PvP stand dort „SPIELER GEGEN SPIELER“ – sie las den Fenstertitel statt deines Namens.

**Andere Reiter bleiben, wie sie waren.** Beim Wechsel auf Ruf, Währung oder PvP kommen nur die Zeilen zurück, die die Kopfzeile ersetzt hat, und zwar so, wie sie vorher waren.

## [6.6.4.2] – 2026-09-29

**Dein Name steht nur noch einmal im Charakterfenster.** Der kleine Titel des Spiels über dem Fenster ist ausgeblendet, solange die große Kopfzeile zu sehen ist; auf Ruf, Währung usw. steht er wie gewohnt.

**Keine graue Fläche mehr oben rechts.** Der helle Schein oben im Fenster ist aus, und die Werte liegen durchgehend von oben bis unten auf der dunklen Fläche, die weich in die Szene übergeht.

## [6.6.4.1] – 2026-09-29

**Der rechte Bereich des Charakterfensters beginnt mit „Allgemein“.** Die doppelte Zeile mit Stufe und Klasse samt ihrer grauen Fläche ist weg – Name, Klasse und Stufe stehen nur noch einmal oben über der Figur.

**Weicher Übergang statt Kante.** Kein heller Schein mehr oben im Fenster; die Werte liegen auf einer leichteren, dunklen Fläche, und zwischen Figur und Werten verläuft eine breitere dunkle Zone. Deine Klassenfarbe bleibt nur in Linien, Rauten und aktiven Zuständen.

## [6.6.4.0] – 2026-09-29

**Das Charakterfenster ist neu aufgebaut.** Deine Figur steht im Mittelpunkt einer Szene statt vor einem grauen Fenster: sehr dunkle, ruhige Basis, die Szene deiner Klasse läuft zu den Rändern dunkel aus und ist hinter der Figur ruhiger, ein Schatten unter den Füßen und Dunst am Boden stellen sie hinein. Die Werte liegen rechts auf einer dunklen Glasebene über der Szene.

**Name, Klasse und Stufe einmal, oben.** Dein Name steht groß über der Figur, darunter z. B. „PRIESTERIN · STUFE 13“ und eine feine Linie in deiner Klassenfarbe – nicht mehr zusätzlich rechts.

**Deine Klassenfarbe als Akzent, nicht als Anstrich.** Belegte Ausrüstungsplätze tragen einen feinen Rand in deiner Klassenfarbe, unter der Maus voll; leere Plätze bleiben neutral und gedämpft. Die Namen der Werte sind ruhig grau statt gold.

## [6.6.3.6] – 2026-09-29

**Deine Figur steht im Bild statt davor.** Im Charakterfenster nimmt die Figur das Licht des Hintergrunds an: gedämpftes, warmes Umgebungslicht und goldenes Hauptlicht statt neutraler Studiobeleuchtung, dazu ein warmer Schein hinter ihr, ein Schatten unter den Füßen und leichter Dunst am Boden. Nur bei Klassen mit eigenem Bild.

**Die Zeile unter deinem Namen bleibt lesbar.** Klasse und Stufe liegen jetzt über der Figur – vorher konnte eine Waffe auf dem Rücken einen Buchstaben verdecken.

## [6.6.3.5] – 2026-09-29

**Das Charakterfenster bekommt Atmosphäre.** Hinter deiner Figur steht ein eigenes Bild deiner Klasse – für Priester eine Kathedrale mit Lichtkreuz und Kerzen –, das zu den Rändern weich ausläuft. Klassen ohne eigenes Bild behalten den Hintergrund des Spiels; weitere folgen.

**Name, Klasse und Stufe als Kopfzeile.** Dein Name steht größer über dem Fenster, darunter in deiner Klassenfarbe z. B. „PRIESTERIN · STUFE 13“ mit einer Zierlinie – nur auf dem Reiter Charakter.

## [6.6.3.4] – 2026-09-29

**Die Questliste reicht nicht mehr bis zum Boden.** Die Einrichtung gibt ihr jetzt eine Höchsthöhe – von unter der Minikarte bis über den Tooltip unten rechts; was nicht passt, blendet das Spiel aus. Sofort, ohne neue Einrichtung: Bearbeitungsmodus → Zielverfolgung → „Höhe“.

**Dialoge des Spiels im Stil von WeintCodex.** Rückfragen wie „19 Sekunden bis zum Verlassen“, Einladungen oder „Gegenstand zerstören?“ stehen auf der dunklen Kachel mit dem Schein deiner Klassenfarbe statt im Diamantrahmen, die roten Knöpfe sind flach. Was die Dialoge tun, bleibt unberührt.

## [6.6.3.3] – 2026-09-29

**Die Sammlung im Stil von WeintCodex.** Das Fenster der Vorlagen trägt die dunkle Kachel mit dem Schein deiner Klassenfarbe; Metallrahmen, Porträt, Marmor und das Leder mit den Eckverzierungen hinter den Vorlagen sind weg, innen liegt eine ruhige Innenfläche.

**Das Spielmenü (Esc) im Stil von WeintCodex.** Statt Diamantmetall-Rahmen und roten Knöpfen dieselbe dunkle Kachel wie jedes andere Fenster, mit dem Schein deiner Klassenfarbe oben; die Knöpfe sind flach und werden unter der Maus heller.

**Mitgliederliste wieder wie im Spiel.** In Gilde & Communitys trägt die Mitgliederliste wieder ihren eigenen Hintergrund statt der dunkleren Fläche von WeintCodex.

## [6.6.3.2] – 2026-09-28

**Die Karte läuft jetzt wirklich weich aus.** Der Rand war dunkel – neben dem hellen Kopf des Fensters wirkte das wieder wie eine Kante. Jetzt blendet die Karte selbst an allen vier Seiten aus, genau wie das Charakterbild, und geht in den Grund des Fensters samt Schein über. Questmarken bleiben scharf.

## [6.6.3.1] – 2026-09-28

**Die Karte läuft weich in den Rahmen aus.** Wie beim Charakterbild endet die Weltkarte (M) nicht mehr mit harter Kante: an allen vier Seiten geht sie in einem weichen Verlauf in das Fenster über. Die Knöpfe auf der Karte bleiben klar, die Karte selbst bleibt unverändert.

**Alles in deiner Klassenfarbe.** Die Farbe von WeintCodex ist jetzt überall die deiner Klasse: das WeintCodex-Fenster und die Einstellungen, Knöpfe, gewählte Reiter und Einträge, Überschriften, Zauber- und Erfahrungsbalken, Zielleuchten, Chatmeldungen, sogar diese Hervorhebung hier. Grün, Rot, Gold und Blau bleiben, weil sie etwas bedeuten. Unter Allgemein → „Farbe der Oberfläche“ gibt es das Lila zurück.

## [6.6.3.0] – 2026-09-28

**Überschriften in Charakter, Ruf und Fertigkeiten fallen auf.** Größerer Titel mit Schatten, dahinter ein weicher Lichthof in deiner Klassenfarbe, links und rechts eine Raute mit dunklem Kern, ein kleiner Punkt und eine leuchtende Linie. Zu lange Titel werden etwas kleiner, damit nichts über die Spalte ragt.

## [6.6.2.9] – 2026-09-28

**Ruf und Fertigkeiten mit derselben Zierlinie.** Die Überschriften der Ruf- und Fertigkeitenliste tragen jetzt dasselbe Design wie die Werte im Charakterfenster: Titel mittig, feine Linien mit Rauten in deiner Klassenfarbe. Das Zeichen zum Auf- und Zuklappen bleibt rechts, unter der Maus wird die Zeile heller.

## [6.6.2.8] – 2026-09-28

**Kategorien im Charakterfenster als Zierlinie.** Statt eines dunklen Balkens steht der Titel wieder mittig, links und rechts läuft je eine feine Linie in deiner Klassenfarbe nach außen aus, am Titel sitzt eine kleine Raute – gegliedert, ohne Löcher ins Fenster zu schneiden.

## [6.6.2.7] – 2026-09-28

**Der Questpfeil plant selbst.** Statt stur der Quest zu folgen, die das Spiel gerade verfolgt – oft am anderen Ende des Gebiets –, zeigt er auf das nächste lohnende Ziel aus deinem ganzen Questlog: offene Quests an ihrem Zielgebiet, erfüllte an der Abgabe. Quests weit über deiner Stufe und Gruppenquests zählen weiter weg, und er springt nicht wegen ein paar Metern hin und her. Klickst du selbst eine Quest an, gilt sie bis zur Abgabe. /wcui pfeil weiter überspringt ein Ziel; unter Komfort → Questpfeil → „Welches Ziel“ gibt es das alte Verhalten zurück.

**Kategorien im Charakterfenster heben sich ab.** „Allgemein“, „Primäre Eigenschaften“, „Waffen“ und die anderen Überschriften der Werte stehen jetzt auf einem eigenen Band mit einem Streifen in deiner Klassenfarbe, links ausgerichtet und etwas größer – die Werte darunter lesen sich als Gruppe.

## [6.6.2.6] – 2026-09-28

**Offene Fenster fressen keinen Speicher mehr.** Solange ein Spielfenster offen war, wuchs der Speicher schnell an, und das Spiel ruckelte kurz, wenn es aufräumte. Das ist behoben: Nachgesehen wird nur noch in offenen Fenstern, dicht nach dem Öffnen und nach einem Klick, sonst alle zwei Sekunden.

## [6.6.2.5] – 2026-09-28

**Weicher Rand ums Charaktermodell, dritter Anlauf.** Das Hintergrundbild ist an seinen Rändern selbst fast schwarz, ein dunkler Übergang darüber änderte nichts. Jetzt läuft das Bild selbst an allen vier Seiten aus, und darunter erscheint der Grund des Fensters samt Schein. Deine Figur bleibt scharf.

## [6.6.2.4] – 2026-09-28

**Weicher Rand ums Charaktermodell, jetzt sichtbar.** Der Übergang saß an der richtigen Stelle, war im Spiel aber nicht zu sehen. Er liegt jetzt auf der obersten Ebene über dem Hintergrundbild, sodass das Bild an allen vier Seiten in den Rahmen ausläuft.

## [6.6.2.3] – 2026-09-28

**Rahmen in deiner Klassenfarbe.** Gewählte Reiter, das Zielleuchten der Plaketten, deine Zeile in der Schadensanzeige und die Rahmen im Gestaltungsmodus tragen jetzt die Farbe deiner Klasse statt Lila. Unter Allgemein → „Rahmen und Hervorhebungen“ lässt sich das Lila zurückholen.

**Verlauf der Schadensanzeige zeigt den ganzen Kampf.** Das Spiel nennt die Zahlen im Kampf nur verdeckt – deshalb stand bisher nur eine Säule am Ende. Jetzt zeigt der Verlauf die Summe über den Kampf: steil heißt viel Schaden, flach heißt keiner.

**Gilde & Communitys: Wappen zurück, Liste links neu.** Das Gildenwappen oben links ist wieder da. Die Einträge links sind schlichte Kacheln, der gewählte im Akzent; das Wappen im Eintrag bleibt.

**Weicherer Rand ums Charaktermodell.** Der Übergang sitzt jetzt an den Kanten des Hintergrundbilds selbst und ist breiter – auch oben und rechts.

## [6.6.2.2] – 2026-09-28

**Plaketten nach NPC.** Neuer Reiter „NPCs“ bei den Namensplaketten. Gegner, die zaubern, sind jetzt blau – was unterbrochen werden muss, fällt sofort auf. Erkannt am NPC selbst oder daran, dass er schon einmal einen Zauber begonnen hat. Dazu eigene Farben: Namen eingeben, WeintCodex findet den NPC unter denen, die du schon gesehen hast, oder du übernimmst dein Ziel.

**Seitenreiter zeigen die richtige Wahl.** Bei den Berufen standen alle Reiter im Akzent. Jetzt ist nur der gewählte markiert – und wenn das Spiel nicht eindeutig sagt, welcher es ist, keiner statt aller.

**Suche nach Gruppe im neuen Stil.** Der Dungeonbrowser als Kachel statt Metall und Marmor, die Kategorien mit schlichtem Rand und gedämpften Bildern, die Reiter rechts wie bei den Berufen.

**Feinschliff an Questlog und Gilde.** Suchfeld flach, braune Pfeilknöpfe und die goldenen Bildlaufleisten grau, das Wappen oben links an Gilde & Communitys weg.

## [6.6.2.1] – 2026-09-28

**WeintCodex auf Forever-Niveau.** Die Navigation ist neu geordnet: oben steht, was beim Leveln hilft – Übersicht, Charakter, Lehrer, Dungeons, Gruppencheck. Schlachtzüge, Anmeldung und Kalender stehen darunter in einer eigenen Gruppe – weg ist nichts.

**Neue Übersicht fürs Leveln.** Oben deine Stufe, Erfahrung, Erholung und die Quests, die zur Abgabe bereit sind. Darunter: was du beim Lehrer noch nicht gelernt hast, deine Ausrüstung und die Dungeons, die zu deiner Stufe passen. Die Zahl lernbarer Zauber steht auch links am Lehrer.

**Lehrer rechnet mit.** Oben in der Zauberliste steht die Rechnung: was jetzt lernbar ist, dein Gold, und was danach bleibt oder fehlt – dazu, für wie viele Zauber es reicht und was die nächsten zwei Stufen zusammen kosten. Preise werden rot, sobald dein Gold der Reihe nach nicht mehr reicht.

**Weltkarte im neuen Stil.** Karte & Questlog (M) als Kachel statt Metall und Pergament, die Leiste „Welt › …“ mit flachen Knöpfen. Die Karte selbst bleibt, wie sie ist. Einzeln abschaltbar unter Tooltip & Fenster.

**Berufe und Gilde & Communitys im neuen Stil.** Beide Fenster als Kachel statt Metall und Holz: Fortschrittsbalken flach, Berufssymbole mit schlichtem Rand, die Reiter am rechten Rand als kleine Kacheln – der gewählte im Akzent. Die Bilder der Berufe bleiben gedämpft sichtbar, fehlende Reagenzien bleiben rot.

**Aufschlüsselung der Schadensanzeige ausgebaut.** Frei verschiebbar (Rechtsklick setzt sie zurück), dazu drei Ansichten: Zauber, Verlauf – Schaden oder Heilung je Sekunde über den Kampf als Säulen – und Auren: alle Buffs samt Essen und Fläschchen, so wie sie vor dem Kampf waren. Mit „Vergleich“ stehen zwei Spieler nebeneinander: Kennzahlen, Zauber, Verlauf und Auren.

**Weicher Rand ums Charaktermodell.** Der Hintergrund hinter deinem Charakter läuft an den Kanten weich in das Fenster aus, statt hart abzubrechen.

**Ränge direkt am Zauber.** Klickst du in der Zaubertafel der Klickzauber auf einen Zauber mit mehreren Rängen, klappt am Symbol die Liste der Ränge auf – „Höchster Rang“ steigt mit, jeder andere bleibt fest. Zauber mit nur einem Rang liegen wie bisher sofort auf der Taste.

## [6.6.2.0] – 2026-09-28

**Klickzauber mit Rang.** Unter der Zaubertafel wählst du für die belegte Taste einen Rang – zum Beispiel einen kleinen Heilzauber, der Mana spart. Ohne Wahl wirkt die Taste wie bisher den höchsten Rang und steigt mit, wenn du einen neuen lernst.

## [6.6.1.9] – 2026-09-28

**Deutlich weniger Speicher.** Die Messung hat es gezeigt: fast neun Zehntel des Wegwerf-Speichers kamen vom Einblenden der Aktionsleisten bei Maus darüber – bei jedem Bild. Das ist behoben, und der Questpfeil rechnet nur noch fünfmal je Sekunde alles neu; dazwischen dreht er sich nur.

## [6.6.1.8] – 2026-09-28

**Weniger Speicher im Kampf.** Erinnerungen, Schadensanzeige und Aktionsleisten fassen Ereignisse zusammen, die im Kampf dutzendfach je Sekunde kommen, statt jedes einzeln auszuwerten. /wcui speicher misst 30 Sekunden lang, welcher Teil wie viel Speicher belegt.

## [6.6.1.7] – 2026-09-28

**Nur deine ausgewählten Buffs am Spielerrahmen.** Über dem Spielerrahmen stehen klein die Buffs, die du im Abklingzeitmanager des Spiels auswählst (z. B. Schild, Inneres Feuer) – auch im Kampf. Alle Buffs, auch die von anderen, stehen wieder oben rechts. Einmal /wcui einrichten, dann neu laden.

**Treffer und Heilung im Rahmen.** Spieler- und Zielrahmen zeigen kurz, was gerade ankam: erlittener Schaden in kleinen roten Zahlen mit Minus, erhaltene Heilung grün mit Plus. Abschaltbar unter Einheitenrahmen → Allgemein.

## [6.6.1.6] – 2026-09-28

**Buffs am Spielerrahmen.** Deine Buffs stehen direkt über deinem Spielerrahmen – auch im Kampf. Einmal /wcui einrichten, dann neu laden. Der Fokusrahmen rückt dafür nach links.

**Schilde sichtbar, auch bei vollem Leben.** Ein Schild liegt als blaue Fläche vom rechten Rand her über dem Lebensbalken von Spieler und Ziel.

## [6.6.1.5] – 2026-09-28

**Abklingzeiten wie eine WeakAura.** Unter dem Charakter nur noch deine Fähigkeiten und wie lange ihre Wirkung läuft – kleiner, ohne doppelte Symbole und ohne lange Buffs wie Ausdauer. Einmal /wcui einrichten, dann neu laden; die Buff-Anzeigen des Spiels lassen sich im Bearbeitungsmodus wieder einschalten.

## [6.6.1.4] – 2026-09-28

**Gespräche im WeintCodex-Stil.** Questgeber, Gastwirte, Questtexte und Bücher stehen auf der dunklen Kachel statt auf Pergament, mit heller Schrift.

**Einrichtung lässt deine Plätze in Ruhe.** Deine WeintCodex-Rahmen bleiben, wo du sie hingezogen hast, und der Abklingzeitmanager behält die Plätze aus deinem bisherigen Layout. /wcui einrichten pruefen funktioniert jetzt, und die Questliste rutscht unter den Knopf „Issue Reporter“. Der eigene Zauberbalken passt zwischen Spieler- und Zielrahmen, und die Schadensanzeige steht wieder oben links. Die Questliste schließt rechts bündig mit der Minikarte ab (nach /wcui einrichten). Das Blinken bei automatischem Angriff und Schießen ist ein flaches Leuchten statt eines schiefen roten Rahmens.

## [6.6.1.3] – 2026-09-27

**Einrichtung stellt jetzt alles.** Jeder Rahmen des Spiels bekommt seinen festen Platz – Aktionsleisten, Chat, Minikarte, Buffs, Questliste, Taschen, Menü, Gruppe –, egal was ein früheres Addon eingestellt hatte. Dazu Chatfenster zurück auf Allgemein und Kampflog, einige Spieleinstellungen und die eigenen Rahmen auf ihre Plätze. Einmal /wcui einrichten, neu laden, und /wcui einrichten pruefen zeigt, ob alles sitzt.

## [6.6.1.2] – 2026-09-27

**Einrichtung behält deine Leisten.** Das Layout „WeintCodex“ baut jetzt auf deinem bisherigen Layout auf – Aktionsleisten, Questliste und alles andere bleiben, wo sie waren; nur Gruppe und Schlachtzug ändern sich. Wer schon eingerichtet hat: /wcui einrichten noch einmal ausführen.

## [6.6.1.1] – 2026-09-27

**Einrichtung mit einem Klick.** Beim ersten Einloggen stellt WeintCodex die Oberfläche für dich ein – wie EllesmereUI: ein eigenes Layout „WeintCodex“ im Bearbeitungsmodus mit schlachtzugsartigen Gruppenrahmen an den richtigen Plätzen, dann einmal neu laden. Verschieben geht danach wie gewohnt. Jederzeit wieder mit /wcui einrichten oder unter Gruppenrahmen → Allgemein.

## [6.6.1.0] – 2026-09-27

**Gruppenrahmen wie die eigenen Kacheln.** Die Rahmen des Spiels tragen jetzt Klassenfarbe statt Grün, den Namen oben mittig, den Zustand in der Mitte, Grund, Rand und Schatten der Kacheln – die Überschrift „Gruppe“ und Blizzards Linien sind weg. HoTs, Buffs und Schilde zeigt weiter das Spiel. Tote und Getrennte bleiben grau.

## [6.6.0.9] – 2026-09-27

**Gruppenrahmen mit HoTs, Buffs und Schilden.** Die Gruppe und der Schlachtzug nutzen jetzt die Rahmen des Spiels im WeintCodex-Stil – nur sie zeigen HoTs, Buffs, Schilde und bannbare Debuffs auch im Kampf. Lage und Größe im Bearbeitungsmodus des Spiels; in der Gruppe dort „Schlachtzugsartige Gruppenrahmen“ einschalten. Die eigenen Kacheln gibt es weiter unter Gruppenrahmen → Rahmen.

**Klickzauber auch auf den Rahmen des Spiels.** Deine Belegung wirkt auf die neuen Gruppen- und Schlachtzugsrahmen genauso.

## [6.6.0.8] – 2026-09-27

**Questpfeil: höher oder tiefer.** Nennt das Spiel deine eigene Höhe, erkennt der Pfeil beim Bergauf- oder Bergabgehen, ob das Ziel über oder unter dir liegt – „Ziel ≈ 25 m höher“ und ein kleiner Pfeil nach oben oder unten. Ob dein Spiel die Höhe nennt, sagt /wcui pfeil.

## [6.6.0.7] – 2026-09-27

**Klickzauber.** Zauber auf Maustasten legen und mit einem Klick auf einen Rahmen wirken – Gruppe, Schlachtzug, Spieler, Ziel –, ohne die Einheit erst anzuwählen. Taste wählen, Zauber aus deinem Zauberbuch anklicken – nichts tippen. Einstellen unter Gruppenrahmen → Klickzauber; die Belegung gilt je Klasse, und die Maus über einem Rahmen zeigt, was welche Taste tut.

## [6.6.0.6] – 2026-09-27

**Eingehende Heilung an Spieler und Ziel.** Wie in den Gruppenrahmen zeigt ein heller grüner Balken hinter dem Leben, wie weit gerade gewirkte Heilungen reichen, ein weißer dahinter die Schilde. Beides abschaltbar unter Einheitenrahmen → Allgemein.

**Erinnerung bei knapper Munition.** Neue Regel „Munition knapp“: WeintCodex liest, was im Munitionsplatz steckt, und erinnert unter einer Menge, die du festlegst (ohne Angabe 200) – und wenn sie ganz verschossen ist. „Für meine Klasse“ legt sie beim Jäger gleich mit an.

**Erinnerung bei knappem Vorrat.** Neue Regel „Vorrat knapp“ für jeden Gegenstand, den du nennst (Name oder ID): Tränke, Reagenzien, Essen – mit eigener Mindestmenge.

## [6.6.0.5] – 2026-09-27

**Erinnerungen gelten je Klasse.** Eine Regel gilt jetzt für die Klasse, auf der du sie anlegst – der Schlachtruf deines Kriegers erinnert deinen Jäger nicht mehr. Für Buffs, die andere geben, wählst du „Alle Klassen“. Regeln aus der Zeit davor gelten dort, wo der Charakter den Zauber kennt; fremde stehen blass mit „(hier aus)“ in der Liste.

## [6.6.0.4] – 2026-09-27

**Aurenleisten wieder entfernt.** Im Kampf gibt das Spiel Addons weder die Auren des Ziels noch deine eigenen heraus – die Leisten verschwanden genau dann, wenn du sie brauchst. Leisten mit Restzeit im Kampf bekommst du über die verfolgten Leisten des Abklingzeitmanagers; am Zielrahmen zeigen weiter die Symbole des Spiels deine Debuffs.

## [6.6.0.3] – 2026-09-27

**Aurenleisten nur noch über deinem Spielerrahmen.** Die Auren des Ziels hält das Spiel im Kampf vor Addons geheim – Leisten über dem Ziel blieben genau dann leer. Dort zeigen weiter die Symbole des Spiels deine Debuffs.

**Aurenleisten zeigen zuerst deine Buffs.** Umschaltbar auf die Debuffs auf dir.

## [6.6.0.2] – 2026-09-27

**Aurenleisten zeigen sich.** Über Spieler- und Zielrahmen stehen die Leisten jetzt wirklich – mit Zaubername, Restzeit und einer Leiste, die mit der Zeit leerläuft. Die Einstellung „Weg“ bei den Auren spielt dafür keine Rolle mehr.

## [6.6.0.1] – 2026-09-27

**Neue Marke auf der Weltkarte.** Eine Stecknadel mit pulsierendem Schein und Namensschild statt der kleinen Raute – auf Pergament und Gelände schnell zu finden.

**Zurück zum Codex, aufgeräumt.** Oben in der Mitte der Karte steht eine Leiste im Stil des Codex: wer markiert ist, wo, und der Knopf zurück. Sie verdeckt keinen Knopf des Spiels mehr.

**Lehrer: Waffenkarte repariert.** Stand, Kosten und „Karte“ stehen wieder in der Waffenkarte statt daneben.

**Erfahrung aus Quests im Balken.** Ein grünes Stück zeigt, wie weit der Erfahrungsbalken käme, wenn du jetzt alle fertigen Quests abgibst; die Maus darüber nennt die Summe, deinen Stand danach – oder die nächste Stufe – und was alle Quests im Log zusammen bringen.

**Dein Name steht wieder auf dem Spielerrahmen.** Beim Einloggen blieb er manchmal leer – jetzt zeichnet der Rahmen nach, bis das Spiel ihn kennt.

**Aurenleisten über Spieler- und Zielrahmen (Test).** Leisten mit Restzeit wie bei ElvUI. Im Kampf gibt das Spiel Addons vermutlich keine Auren heraus – dann bleiben sie dort leer; bitte prüfen und /wcui auren schicken.

**Der Questpfeil kennt die Höhe.** In der Nähe nennt er den Höhenunterschied zum Ziel und ob es verdeckt ist – in einer Höhle, einem Gebäude oder hinter einem Hang. Eine Nadel steht genau am Ziel im Raum, oben am Berg oder unten am Höhleneingang.

**Kein Fehler mehr beim Umstellen der Questpriorität im Kampf.** WeintCodex stellt die Weltkarte nicht mehr selbst ein und wählt keine Quest mehr für das Spiel aus – der Questpfeil merkt sich seine Wahl selbst. „Zurück zum Codex“ legt den Codex über die Karte; sie schließt du wie gewohnt mit Esc oder M. Im Kampf öffnet der Kartenknopf die Weltkarte nicht.

### Technisch

- Neu: `media/ui/pin.tga`, `dot.tga`, `halo.tga` – eigene Grafiken
  (Stecknadel, Kreis, weicher Schein), kein Spielmaterial.
- `modules/questmap.lua`: Nadel mit Spitze auf dem Ort (`BOTTOM`),
  Rand/Verlauf/Kern, pulsierender Schein (AnimationGroup, ADD),
  Namensschild; Leiste `WeintCodexQuestMapBar` oben mittig mit
  Markenzeichen, Zone, Name und Knopf „Zurück zum Codex“.
- `ui/unitframes.lua`: Name ohne Wert („Unbekannt“) → Wiederholversuch
  (höchstens zehnmal, je Sekunde); nach `PLAYER_ENTERING_WORLD`
  `UF.RedrawTexts` nach 1 und 4 s. Aurenleisten `player_auraBars`/
  `target_auraBars` (Filter, Anzahl, Höhe), am Ziel über zwei Symbolreihen.
- `ui/auras.lua`: Leistenform (`opts.bar`), `StyleBar`, `BindBar`
  (Dauerleiste des Aurenknopfs, Name der Methode wird probiert und in
  `/wcui auren` genannt), alter Weg mit Name und Restzeit.
  `GameColors.auraBarDebuff`/`auraBarBuff`.
- `ui/questarrow.lua`: `QA.Nav()` (C_Navigation: Luftlinie, Occluded,
  Bildschirmpunkt), `QA.Height()`, Zeile `height` unter dem Pfeil,
  Zielmarke `QA.marker` am Navigationspunkt; nur bei gleichem Ziel wie die
  Navigation des Spiels. Schalter `showHeight`, `worldMarker`.
- `ui/xpbar.lua`: `XB.QuestXP()` (je Quest `GetQuestLogRewardXP`,
  abgabebereit über `C_QuestLog.ReadyForTurnIn`/`IsComplete`), dritte
  Balkenschicht `frame.quest` in `GameColors.xpQuest`, Tooltipzeilen,
  Schalter `xpQuests`. Ohne Funktion des Clients keine Auskunft.
- ADDON_ACTION_BLOCKED `Button:SetPassThroughButtons()` (Beta-Test, im
  Kampf beim Umstellen der Questpriorität): `QuestDataProvider:RefreshAllData`
  liest die Kartennummer der Weltkarte, und die hatte WeintCodex seit
  6.5.1.0 selbst geschrieben (`WorldMapFrame:SetMapID`, Lua-`OpenWorldMap`,
  `HideUIPanel`). Jetzt nur `C_Map.OpenWorldMap` (die Karte stellt ihre
  Zone im eigenen Ereignis `WORLD_MAP_OPEN` ein), nicht im Kampf, und kein
  Schließen durch das Addon. Der Questpfeil wählt die nächste Quest nur
  noch für sich (`QA.Chosen`) statt über `C_SuperTrack.SetSuperTrackedQuestID`.
  `load_test.lua` sucht in `core/`, `modules/`, `ui/` nach solchen Aufrufen.
- `modules/trainer.lua`: Detailbereich vor dem Messen setzen (er macht die
  Fläche schmaler – vorher lag alles Rechtsbündige der Waffenkarte im
  Detailbereich); bei Größenänderung neu zeichnen.

## [6.6.0.0] – 2026-09-27

**Neu: Lehrer.** Was dir dein Klassenlehrer jetzt beibringt, was dafür noch fehlt, was in den nächsten Stufen kommt – und was das alles kostet. Unter Charakter in der Seitenleiste.

**Waffenfertigkeiten mit Weg dorthin.** Welche Waffen du lernen kannst und welcher Waffenmeister sie lehrt – ein Klick zeigt ihn auf der Weltkarte.

**Was du kannst, sagt dein Spiel.** Stufen und Kosten stammen aus Beta-Berichten und sind als unbestätigt gekennzeichnet; ob ein Zauber schon gelernt ist, fragt WeintCodex deinen Client.

### Technisch

- Neu: `data/trainer.lua` (`WeintCodex.TrainerData`): 1406 Lehrereinträge
  der neun Klassen, Rangketten, 14 Waffenfertigkeiten, 8 Waffenmeister.
  Herkunft `community`, übernommen aus *What's Training?* (Forever-Fassung,
  MIT-Lizenz, Lizenztext im Dateikopf); nur Daten.
- Neu: `modules/trainer.lua` (`WeintCodex.Trainer`): Einordnung über den
  Client (`C_SpellBook`, `IsPlayerSpell`), ersetzte Ränge zählen als
  gelernt; Seite mit zwei rollenden Karten (Zauber, Waffen) und
  Zusammenfassung im Detailbereich. Tierausbildung ohne Zustand.
- Navigation: Eintrag „Lehrer“ (Symbol `media/icons/nav_lehrer.tga`,
  eigenes Buch), Suche, `/wc lehrer`. Die Spalte ist damit voll
  (644/684 px, 40 px Luft).
- `modules/questmap.lua`: `QM.Show(place, quest, line)` – `line` ersetzt
  die Tooltipzeile der Marke (Waffenmeister: „Lehrt: …“).
- Nicht übernommen: Grimoires, Rufrabatte, Ignorierliste, Einbindung ins
  Zauberbuch.
- **Im Spiel ungeprüft.**

## [6.5.1.2] – 2026-09-27

**Die Weltkarte liegt vorn.** Zeigst du einen Questgeber auf der Karte, geht der Codex so lange zu – die Karte liegt nicht mehr dahinter.

**Zurück zum Codex mit einem Klick.** Oben links auf der Karte bringt dich ein Knopf auf dieselbe Seite zurück, zum nächsten Questgeber.

### Technisch

- `modules/questmap.lua`: `QM.Show` schließt den offenen Codex
  (`WeintCodex.MainFrame:Hide()`, Seite bleibt) und zeigt auf der
  Weltkarte „Zurück zum Codex“ (`WeintCodex.CreateButton`, primär).
  `QM.Back` schließt die Karte (`HideUIPanel`) und öffnet den Codex.
  Wird die Karte anders geschlossen, verschwindet der Knopf
  (`OnHide` des Taktgebers).

## [6.5.1.1] – 2026-09-27

**Jede Quest in ihrer eigenen Kachel.** Im Dungeonkompendium ist auf einen Blick zu sehen, wo eine Quest endet und die nächste beginnt.

**Der Kartenknopf fällt auf.** „Questgeber auf der Karte zeigen“ ist jetzt ein Knopf mit Fläche und Rand statt einer kleinen Textzeile.

### Technisch

- `modules/dungeonpages.lua`: `DrawQuest` zeichnet in eine Kachel
  (`surface2`, Rand `borderStrong`, 10 px Innenabstand, 10 px Luft
  dazwischen); der Inhalt steht in `DrawQuestBody`. `MapLink` ist ein
  24 px hoher Knopf (`surface3`, Rand `accentDim`, unter der Maus
  `accentDim`-Fläche). Titel 14 statt 13.
- Rückmeldung aus dem Beta-Test: Link „sehr unscheinbar“, Quests „nacheinander weg“.

## [6.5.1.0] – 2026-09-27

**Questgeber auf der Weltkarte.** Unter einer Quest im Dungeonkompendium öffnet ein Klick die Weltkarte auf der richtigen Zone und markiert, wo die Quest beginnt – bei 33 Quests. Rechtsklick auf die Marke entfernt sie.

**Die Lage ist unbestätigt.** Sie stammt aus Beta-Berichten und folgt den bekannten Orten aus Classic; der Tooltip der Marke sagt das.

### Technisch

- `data/dungeon_journal.lua`: `J.PLACES[questId] = { map, x, y, who, item }`
  (33 Orte, Classic-Kartennummern), `J.Place`.
- Neu: `modules/questmap.lua` (`WeintCodex.QuestMap`): Weltkarte öffnen
  (`OpenWorldMap`, dann einige Takte `SetMapID`), eigene Marke auf
  `WorldMapFrame:GetCanvas()`, Zoom ausgeglichen, nur auf ihrer Zone,
  Rechtsklick entfernt sie. Kein `C_Map.SetUserWaypoint`.
- `modules/dungeonpages.lua`: Link „Questgeber auf der Karte zeigen“
  bzw. „Fundort auf der Karte“ je Quest mit bekanntem Ort.
- `data_test.lua`: jeder Ort an einer Quest des Journals, Lage 0..1.
- **Im Spiel ungeprüft.**

## [6.5.0.0] – 2026-09-27

**Beute im Dungeonkompendium.** Für Hall of Thanes, Ragefire Chasm, Wailing Caverns, Ruins of Lordaeron, The Deadmines, Shadowfang Keep und Blackfathom Deeps zeigt jeder Boss, was er fallen lässt – mit dem Tooltip des Spiels und Umschalt+Klick in den Chat.

**Quests zu jedem dieser Dungeons.** Wo sie beginnen, was zu tun ist, wo man sie abgibt und was sie bringen – nur für deine Fraktion, die andere wird gezählt.

**Unbestätigt, und so gekennzeichnet.** Die Angaben stammen aus Beta-Berichten, nicht aus dem Client. Die Erfahrung ist ein beobachteter Wert; Namen und Werte der Gegenstände nennt dein Spiel selbst.

**Mehr Addon-Knöpfe im Sammelknopf der Minikarte.** Auch Addons mit eigenem Kartenknopf kommen hinein, und Knöpfe, die ein Addon erst spät anlegt, ebenfalls. Fehlt trotzdem eines, zeigt `/wcui addons`, was gefunden wurde und was nur im Addon-Menü des Spiels steht.

**Die Reiter Primär und Sekundär im Talentfenster sehen wieder aus wie Reiter.** Sie trugen einen Rand mitten auf der Schrift statt ihrer Kachel.

### Technisch

- `ui/minimap.lua`: `MM.AddonButtons` nimmt neben LibDBIcon auch Kinder
  von `Minimap`, `MinimapBackdrop` und `MinimapCluster`, deren Name wie
  ein Kartenknopf aussieht (`MM.LooksLikeAddonButton`: `…MinimapButton`,
  Knöpfe des Spiels über ihren Anfang ausgeschlossen). Gefundene Knöpfe
  bleiben gemerkt, auch wenn sie in der Kachel keine Kinder der Karte mehr
  sind. `LibDBIcon_IconCreated` ordnet neu, statt nur in der ersten Minute
  nachzusehen.
- `/wcui addons` (`MM.InspectAddons`): gefundene Knöpfe, im Addon
  ausgeblendete, übrige Rahmen an der Karte, Einträge im Addon-Menü des
  Spiels (`AddonCompartmentFrame`).
- Minikarte: Es gab keine Grenze von zwei Knöpfen; die Liste kannte
  bisher nur LibDBIcon.
- `ui/windows.lua`: Ein Reiter ist nur dann ein Bildreiter, wenn er keine
  sichtbare Beschriftung hat (`W.HasLabel`) und sein Bild sichtbar ist
  und etwas zeigt (`W.ShowsPicture`). Die Textreiter im Talentfenster
  tragen ein leeres, verstecktes `.Icon`; 6.4.1.7 hatte jedes `.Icon`
  genommen.
- Neu: `data/dungeon_journal.lua` (`WeintCodex.DungeonJournal`): 153
  Gegenstände an 52 Gegnern, 50 Quests, Herkunft `community`.
  Zugriff `Loot/Others/Quests/Has`.
- `data/dungeons.lua`: *The Butcher* trägt `nameAlt = "The Baron"`
  (so heißt er in den Berichten zu Beute und Quests).
- `modules/dungeonpages.lua`: Abschnitt „Beute“ in der Bosskarte,
  „Quests“ und „Weitere Beute“ in der Dungeonkarte; Name, Farbe und Bild
  vom Client (`C_Item`, `GET_ITEM_INFO_RECEIVED`), Rückfall englisch.
- `data_test.lua`: jede Beute an einem vorhandenen Boss, jede Nummer
  eine ganze Zahl, jede Quest mit Geber, Ziel, Abgabe, Fraktion.
- Bilder der Vorlage (Porträts, Dungeonbilder, Wappen) sind
  Blizzard-Material und nicht übernommen.
- **Im Spiel ungeprüft.**

## [6.4.1.8] – 2026-09-27

**Keine wandernden Balken mehr im Zauberbuch.** Die dunkle Fläche hinter den Kategorie-Bildern ist weg – sie schaute seitlich heraus, wo ein Reiter breiter war als sein Bild.

### Technisch

- Gemessen mit `/wcui maus` (Beta-Test 6.4.1.7): der Kategorie-Reiter
  trägt sein Bild als `.Icon` und dahinter eine Farbfläche
  (`FileData ID 0`, BACKGROUND), die den ganzen Reiter füllt. Die Breite
  folgt der (leeren) Beschriftung, und der gewählte Reiter hat eine andere
  Schrift – daher „wanderte“ der Balken. `ui/windows.lua`: am Bildreiter
  wird jede Textur außer dem Bild und unseren eigenen ausgeblendet; das
  Bild wird bevorzugt über `.Icon` gefunden.
- **Im Spiel ungeprüft.**

## [6.4.1.7] – 2026-09-27

**Klassenbild im Zauberbuch ohne Balken.** Die dunklen Streifen links und rechts am Klassen-Reiter sind weg; alle Kategorie-Bilder sind gleich zugeschnitten.

### Technisch

- `ui/windows.lua`, `W.CropRelative`: Reiter-Bilder werden relativ zum
  Ausschnitt des Spiels geschnitten (10 % je Seite) statt absolut
  (0,08..0,92). Das Klassenbild kommt aus einem Bogen bzw. Atlas, dessen
  Ausschnitt das Spiel bei jeder Auffrischung neu setzt – der absolute
  Schnitt ging verloren, die dunklen Ränder des Bildes blieben. Geschnitten
  wird neu, sobald das Spiel den Ausschnitt ändert.
- **Im Spiel ungeprüft.**

## [6.4.1.6] – 2026-09-27

**Kategorien im Zauberbuch aufgeräumt.** Die Bilder oben stoßen nicht mehr aneinander, der goldene Schein ist weg; die gewählte Kategorie trägt einen Rand im Akzent.

### Technisch

- `ui/windows.lua`: Reiter mit Bild statt Text (größte Textur ohne
  Atlas, `W.TabIcon`) bekommen keine Kachel, sondern einen Rand innen am
  Bild – 1 px schwarz, gewählt 2 px im Akzent; `spellbook-Tab-Frame-*`
  (Rahmen und Schein) weg, bei jedem Takt neu, weil das Spiel den Schein
  beim Wechsel wieder zeigt. `IsSelected` ohne Antwort lässt das Feld
  `isSelected` gelten.
- **Im Spiel ungeprüft.**

## [6.4.1.5] – 2026-09-27

**Klassenschein deutlicher.** Oben in Charakterfenster, Zauberbuch und Talenten jetzt gut zu sehen statt nur zu ahnen.

**Reiter und Knöpfe ohne Gold.** „Primär/Sekundär“ und „Änderungen anwenden“ als Kachel, der gewählte Reiter mit Rand im Akzent; Schließen- und Pfeilknöpfe grau statt rot und gelb. Das runde Symbol oben links im Talentfenster ist weg.

**Werte lesbar.** Im Charakterfenster läuft ein langer Name wie „Bewegungsgeschwindigkeit“ nicht mehr in die Zahl, er wird davor gekürzt.

### Technisch

- `GameColors.windowGlow` 0,22 → 0,40.
- `ui/windows.lua`, dritte Stufe: Reiter des `TabSystem` (Teile
  Left/Middle/Right, *Active, *Highlight ausgeblendet, Kachel, Rand im
  Akzent nach `IsSelected`), Knöpfe der Vorlage `UIPanelButtonTemplate`
  (Left/Middle/Right und Glanz weg, Kachel), Atlanten `RedButton-*` und
  `common-dropdown-a-button` entsättigt, Porträt-Rahmen als Ganzes
  ausgeblendet (`PortraitContainer`/`PortraitFrame`/`PortraitButton`).
- Werte im Charakterfenster: `Label` rechts an `Value` verankert, ohne
  Umbruch.
- **Im Spiel ungeprüft.**

## [6.4.1.4] – 2026-09-27

**Stimmung statt Schwarz.** Oben in Charakterfenster, Zauberbuch und Talenten ein Schein in deiner Klassenfarbe; die Landschaften hinter den Talentbäumen bleiben – gedämpft, damit Symbole und Schrift vorne stehen. Abschaltbar: /wcui → Tooltip & Fenster.

**Kein Goldschmuck mehr.** Goldrahmen der Zauberbuch-Reiter, Ringe um die Spezialisierungen, Goldlinien und der Goldkasten der Talentpunkte sind weg. Was etwas anzeigt – gewählter Reiter, verfügbare und volle Talente – bleibt.

### Technisch

- `ui/windows.lua`: `windowArt` (Standard an). Große Bilder unter
  `PlayerSpellsFrame.TalentsFrame` (bzw. einem Fenster mit „Talent“ im
  Namen) werden gedämpft statt ausgeblendet (`Tone`: Entsättigung 0,6,
  Farbe und Deckkraft aus `GameColors.artTone`, Haken auf `SetAlpha`);
  das Pergament des Zauberbuchs bleibt weg. `W.AddGlow`: Verlauf in der
  Klassenfarbe (`RAID_CLASS_COLORS`), 260 px, Deckkraft
  `GameColors.windowGlow`; ohne Antwort des Spiels kein Schein.
- Gemessen mit `/wcui fenster` (Beta-Test 6.4.1.3) und ausgeblendet:
  `spellbook-Tab-Frame-C60`, `Talents-Main-Ring-*`, `Talents-divider-*`,
  `Talents-small-divider-*`, `Talents-Square-Box-*`. Bleiben: Schein des
  gewählten Reiters, `talents-node-square-*` (Zustand), Schatten, Glanz.
- **Im Spiel ungeprüft.**

## [6.4.1.3] – 2026-09-27

**Zauberbuch ohne Pergament, Talente ohne Landschaften.** Große Hintergrundbilder beider Fenster verschwinden, darunter liegt die WeintCodex-Kachel. Symbole, Pfeile, Reiter und die farbigen Rahmen der Talente bleiben.

### Technisch

- `ui/windows.lua`: Im Beta-Test blieb das Pergament – der Forever-Client
  nennt es anders als der Quelltext des Spiels. In Fenstern, deren Name
  „Spell“ oder „Talent“ enthält, verschwinden zusätzlich Texturen ab
  15 % der Fensterfläche (`W.HideLarge`); eigene Flächen (Kachel,
  Schatten, Innenflächen) sind in `W.own` ausgenommen.
- Fenster über den Namen finden (`W.Adopt`, Haken auf `ShowUIPanel`),
  dazu `PlayerTalentFrame`, `TalentFrame`, `ClassTalentFrame` in der
  Liste.
- **Im Spiel ungeprüft.**

## [6.4.1.2] – 2026-09-27

**Zauberbuch im WeintCodex-Stil.** Kachel statt Pergament, Titel und Schrift hell, Zaubersymbole eckig mit dem Rand der Aktionsleisten statt der runden und goldenen Zierrahmen.

### Technisch

- `ui/windows.lua`: `PlayerSpellsFrame` und `SpellBookFrame` in
  `W.WINDOWS`; Atlanten `spellbook-background*`, `-corner*`, `-divider`,
  `-list-backplate`, `-item-backplate` und der Trenner der Rotationshilfe
  ausgeblendet (Lehrer-Schatten, Glyphen, Hervorhebungen bleiben).
  Zauber erkannt an `Button.Icon`/`Border`/`IconMask`: Rahmen weg, Maske
  ab, 1-px-Rand am Bild. Dunkle Schrift (Helligkeit < 0,4) wird
  `textNormal`, ein Haken auf `SetTextColor` hält sie hell; farbige
  Schrift bleibt.
- Fenster werden jetzt auch nach dem Nachladen eines Teils des Spiels
  (`ADDON_LOADED`, das Zauberbuch lädt beim ersten Öffnen) gestaltet, je
  Fenster mit eigenem Takt, solange es offen ist.
- **Im Spiel ungeprüft** – der Screenshot aus dem Forever-Client sieht
  anders aus als das Zauberbuch im Quelltext des Spiels.

## [6.4.1.1] – 2026-09-27

**Abklingzeitmanager mit Luft.** Die eckigen Symbole überlappten sich; jetzt bleiben 2 px zwischen ihnen, auch wenn du den Abstand im Bearbeitungsmodus änderst.

**Neu-laden-Knöpfe ohne Fehlermeldung.** Ein Klick auf „Neu laden“ meldete „hat versucht die geschützte Funktion RunMacroText() aufzurufen“ und lud nicht neu.

### Technisch

- `ui/cooldowns.lua`: das Spiel setzt die Symbole 4 px enger als
  eingestellt (`GetAdditionalPaddingOffset`), weil die runde Maske Luft
  lässt. Bild, Abdeckung und Reichweiten-Schatten rücken um
  `CD.Inset(viewer) = ceil((8 - iconPadding) / 2)` ein, Grund und Rand
  sitzen am eingerückten Bild; neu gesetzt bei jedem Holen aus dem Vorrat.
- `core/ui.lua`, `AttachReload`: `SecureActionButtonTemplate` statt
  `InsecureActionButtonTemplate` (ADDON_ACTION_FORBIDDEN auf
  `RunMacroText`, gemeldet aus dem Beta-Client). Im Kampf erst danach
  angelegt; kein Feld am geschützten Knopf (`WeintCodex.ReloadArmed`).

## [6.4.1.0] – 2026-09-27

**Abklingzeitmanager im WeintCodex-Stil.** Eckige Symbole mit Rand wie auf den Aktionsleisten, ohne den runden Rahmen des Spiels, Abklingzahlen und Stapel in der WeintCodex-Schrift, flache Buff-Balken. Einstellungen: /wcui abklingzeiten (Reiter der Erinnerungen).

**Zählwerk und Zauberauswahl bleiben die des Spiels.** Im Kampf nennt der Client Abklingzeiten und Buffs nur seinem eigenen Manager – ein nachgebauter bliebe dort leer.

### Technisch

- Neu: `ui/cooldowns.lua` (`WeintCodex.UICooldowns`), Reiter
  „Abklingzeitmanager“ des Moduls `reminders` (die Seitenleiste ist voll).
  Gestaltet die vier Anzeigen des Spiels (`Essential`/`Utility`/
  `BuffIcon`/`BuffBarCooldownViewer`): Maske vom Symbol
  (`RemoveMaskTexture`), Schmuck-Atlanten ausgeblendet (Außer-Reichweite-
  Schatten bleibt), eckige Abdeckung, `SetCountdownFont`, Balkentextur.
  Neue Symbole per `hooksecurefunc` auf `OnAcquireItemFrame`; kein Feld
  am Rahmen des Spiels geschrieben.
- Schalter für die CVar `cooldownViewerEnabled`, Knopf auf
  `CooldownViewerSettings:TogglePanel()`.
- `/wcui abklingzeiten`. Farbe `cooldownBar` in `core/ui.lua`.
- Attrappe: `CreateFont`.
- **Im Spiel ungeprüft.**

## [6.4.0.4] – 2026-09-27

**Symbole am Zielrahmen einstellbar.** Links- oder rechtsbündig, Abstand zum Rahmen und Größe – die Größe jetzt scharf statt hochskaliert. Einheitenrahmen → Ziel.

### Technisch

- `ui/unitframes.lua`: `targetAuraAlign` (left/right) und `targetAuraGap`
  (px) für beide Wege. Symbole des Spiels: rechtsbündig über
  `SetFlowLayoutAnchorPoint("BOTTOMRIGHT")` und
  `SetFlowLayoutGrowthDirection(Left, Up)` nach
  `SetFlowLayoutMirroredVertically` (das setzt den Anker auf BOTTOMLEFT
  zurück). Größe über `SetSmall/LargeAuraSize` (Ausgangswerte des Spiels
  gemerkt), `SetScale` nur als Rückfall.
- `UF.AuraBaseY`: Abstand plus Kombopunkte, nur wenn sie über dem Rahmen
  stehen und eingeschaltet sind.

## [6.4.0.3] – 2026-09-27

**Debuffs über dem Zielrahmen – auch im Kampf.** Der Zielrahmen zeigt jetzt die Symbole des Spiels, dieselben wie auf der Namensplakette. Die eigenen Symbole blieben im Kampf leer, weil der Client Auren dort nur an seine eigenen Symbole herausgibt. Umschalten und Größe: Einheitenrahmen → Ziel.

### Technisch

- `ui/unitframes.lua`: `targetAuraSource = "game"` (neu, Standard) lässt
  den Zielrahmen des Spiels am Leben und blendet alles an ihm aus außer
  `TargetFrameContent.TargetFrameContentContextual.Auras` (Aurenbehälter
  laut 12.x-Quelltext); keine Maus, kein Feld am Blizzard-Rahmen
  geschrieben. `hooksecurefunc` auf `ConfigureAuraContainer`
  (nach oben wachsen, keine verkürzten Reihen, Reihenbreite = unser
  Rahmen) und `AnchorAuraContainer` (über unserem Zielrahmen). Geschützt
  im Kampf → nach dem Kampf. Fehlt der Behälter: wie bisher versteckt,
  eigene Symbole. `targetGameScale` für die Größe.
- `/wcui auren` nennt den Stand (`UF.gameAuraState`).
- **Im Spiel ungeprüft**, ob der Forever-Client den Behälter so nennt.

## [6.4.0.2] – 2026-09-27

**„Für meine Klasse“ ergänzt nur noch.** Selbst angelegte Regeln bleiben stehen; gibt es für deine Klasse keine Vorschläge, sagt der Knopf das, statt die Liste zu leeren.

**Kalender neben der Karte.** Der Kalenderknopf verdeckt die Uhrzeit nicht mehr, er steht jetzt links in der Knopfspalte unter der Verfolgung.

### Technisch

- `ui/reminders.lua`: `R.AddSuggestions` ergänzt fehlende Vorschläge
  (gleiche Art, Hand, Zauber zählt als vorhanden) statt `R.SetRules`
  mit der Vorschlagsliste – beim Krieger (keine Vorschläge) war die
  Liste danach leer. Rückmeldung im Chat.
- `ui/minimap.lua`: `GameTimeFrame` in `ColumnButtons` (nach der
  Verfolgung), außer bei „Kalenderknopf ausblenden“ oder wenn er selbst
  die Tageszeit ist.

## [6.4.0.1] – 2026-09-27

**Erinnerungen direkt öffnen.** /wcui erinnerungen springt sofort zu den Erinnerungen; läuft noch eine ältere Fassung, sagt der Befehl das.

**Vorschläge für deine Klasse repariert.** „Für meine Klasse“ erkannte die Klasse nicht und schlug deshalb für niemanden etwas vor.

### Technisch

- `ui/reminders.lua`: `local _, class = _G.UnitClass and _G.UnitClass("player")`
  – das `and` kappt auf einen Rückgabewert, die Klasse (der zweite) kam
  nie an. Jetzt erst prüfen, dann rufen.
- `/wcui erinnerungen` (`O.Show("reminders")`), mit Hinweis auf die
  Fassung, falls das Modul fehlt.

## [6.4.0.0] – 2026-09-27

**Neu: Erinnerungen.** Was früher WeakAuras konnte, soweit das Spiel es heute noch erlaubt: WeintCodex erinnert dich vor dem Kampf an fehlende Buffs, an Waffen ohne (oder mit bald ablaufender) Verzauberung und an einen fehlenden Begleiter.

**Procs und Abklingzeiten als Symbole.** Eigene Buffs und Procs erscheinen groß über dem Cockpit, solange sie laufen; wichtige Fähigkeiten stehen darunter als Leiste mit Abklingzeit. Verschiebbar im Gestaltungsmodus.

**Deine Regeln.** Unter Erinnerungen → Regeln legst du selbst an, was beobachtet wird – Zauber mit Namen oder ID. „Für meine Klasse“ schlägt vor, was ohne Zauber geht (Waffe, Begleiter).

**Was nicht geht, ehrlich:** Im Kampf verschlüsselt das Spiel viele Werte. Symbole und Uhren zeigen, was es herausgibt; Erinnerungen ruhen dort, statt zu raten.

### Technisch

- Neu `ui/reminders.lua` (`WeintCodex.UIReminders`, Modul „Erinnerungen“):
  Regeln `buff`, `weapon`, `pet`, `proc`, `cooldown` in den Einstellungen
  des Moduls (`rules`; nil = Vorschläge der Klasse). Auren über
  `C_UnitAuras.GetPlayerAuraBySpellID` bzw. `GetAuraDataBySpellName`
  (Rückfall `AuraUtil.FindAuraByName`), alles in `pcall`; geheim oder ohne
  Auskunft = „weiß nicht“. Abklingzeit über
  `C_Spell.GetSpellCooldownDuration` (Dauerobjekt), sonst
  `C_Spell.GetSpellCooldown` unverändert an `SetCooldown`.
- Plätze `reminders`, `procs`, `cooldowns` in `ui/layout.lua`.
- Einstellungs-Baukasten: Zellen `input` und `custom`; Seitenleiste 36
  statt 40 px je Eintrag (zwölf Module, Luft für eins mehr).
- CLAUDE.md: Zeile „WeakAuras“ neu gefasst – das Addon bleibt
  unerreichbar, die Erinnerungen bauen nach, was 12.x zulässt.

## [6.3.2.9] – 2026-09-26

**Rollensymbole gut lesbar.** Schild, Kreuz, Schwert und Krone in den Gruppenrahmen stehen jetzt größer auf einer kleinen dunklen Plakette, statt auf der Klassenfarbe unterzugehen; das Schwert ist kräftiger gezeichnet.

### Technisch

- Gruppenrahmen: `Badge` (15 px, Grund `kachelFill` 90 %, 1 px Rand,
  Symbol 13 px statt 11 px) für Rolle und Krone; verhält sich nach außen
  wie eine Textur (`SetTexture`/`SetVertexColor`).
- `icon_dps` mit breiterer Klinge, Parierstange und Griff
  (`make_ui_media.py`).

## [6.3.2.8] – 2026-09-26

**Im Dungeon nur seine Quests.** Betrittst du einen Dungeon, zeigt die Questliste nur noch die Quests dieses Dungeons; beim Verlassen ist alles wieder wie vorher. Abschaltbar unter Questliste → „Nur Quests des Dungeons“.

**Questpfeil in Dungeons aus.** In Dungeons, Schlachtzügen, auf Schlachtfeldern und in Arenen verschwindet der Pfeil – dort nennt das Spiel ohnehin keine Position. Draußen ist er sofort wieder da. Abschaltbar unter Questpfeil → „In Dungeons ausblenden“.

### Technisch

- `ui/questarrow.lua`: `hideInInstance` (Standard an), `QA.InInstance()`
  aus `IsInInstance()` (Art ≠ „none“; geheim → Wahrheitswert, sonst
  „nicht in einer Instanz“). Geprüft in `QA.Update`, das bei
  `PLAYER_ENTERING_WORLD` und Gebietswechseln ohnehin läuft. Als Geist
  steht man draußen – der Weg zur Leiche bleibt.
- `ui/questtracker.lua`: `dungeonOnly` (Standard an). Beim Betreten
  einer Instanz (party/raid/scenario, `PLAYER_ENTERING_WORLD`,
  `ZONE_CHANGED_NEW_AREA`, 2 s später, nach dem Kampf) werden alle
  verfolgten Quests, die nicht zum Dungeon gehören, aus der Verfolgung
  genommen (`C_QuestLog.RemoveQuestWatch`) und die des Dungeons
  aufgenommen. Zum Dungeon gehört, was im Questlog unter der Kopfzeile
  mit dem Namen der Instanz (`GetInstanceInfo`) steht oder `isOnMap`
  trägt. Beim Verlassen wird genau das Geänderte zurückgenommen.
  Gemerkt in `WeintCodex_SavedData.ui.questWatch` – solange die Beta
  nichts speichert, geht es bei einem Neuladen im Dungeon verloren.

## [6.3.2.7] – 2026-09-26

**Markierungen wirklich sichtbar.** Totenkopf, Kreuz und Co. erscheinen jetzt an Namensplaketten, am Ziel-, Fokus- und Spielerrahmen und in der Gruppe – auch wenn der Client verschlüsselt, welche Markierung ein Gegner trägt.

### Technisch

- `/wcui auren` im Beta-Test: „Markierung geheim“. `GetRaidTargetIndex`
  ist im 12.x-Client geheim; `SetRaidTargetIconTexture` rechnet mit dem
  Index (Kachel der Sammeldatei) und darf das nicht. Die Ausweichlösung
  aus 6.3.2.6 (Markierung des Spiels stehen lassen) blieb ebenfalls
  unsichtbar und ist entfernt.
- Neu `UIKit.NewRaidIcon`/`ShowRaidIcon`/`ShowRaidIndex`: eine
  Schriftzeile mit `|TInterface\TargetingFrame\UI-RaidTargetingIcon_%d:n:n|t`
  über `SetFormattedText` – der Client setzt die (geheime) Zahl ein,
  Lua sieht sie nie; die Einzeldateien sind dieselben wie `{rt8}` im
  Chat. Genutzt von Plaketten, Einheiten- und Gruppenrahmen.

## [6.3.2.6] – 2026-09-26

**Markierungen an der Namensplakette.** Totenkopf, Kreuz und die übrigen Zielmarkierungen stehen oben rechts an der Plakette (Größe und Lage unter Namensplaketten → Texte). Verschlüsselt der Client die Markierung, zeigt WeintCodex an derselben Stelle die Markierung des Spiels.

**Deine Bedrohung an der Namensplakette.** Rechts neben dem Balken steht in Prozent, wie viel Bedrohung du auf diesem Gegner hast – 100 % heißt: du hast die Aggro. Gelb kurz davor, rot mit Aggro; als Tank grün, solange du sie hältst. Nur im Kampf und solange du auf seiner Liste stehst. Einstellbar unter Namensplaketten → Farben → Bedrohung.

### Technisch

- Plaketten: `threatText` (right | topleft | none), Wert aus
  `UnitDetailedThreatSituation("player", unit)` (skalierter Anteil) in
  `pcall`; geheim geht er nur an `SetFormattedText`. Kein Wert (nicht auf
  der Liste) oder offen 0 → nichts angezeigt. Farbe aus dem Status wie die
  Bedrohungsfarben des Balkens (Rolle aus `UnitGroupRolesAssigned`), bei
  geheimem Status weiß. Aktualisiert bei `UNIT_THREAT_LIST_UPDATE` und
  `UNIT_THREAT_SITUATION_UPDATE`.
- Markierungen: Das eigene Symbol gab es seit 6.0; es braucht den Index
  offen (`SetRaidTargetIconTexture` rechnet mit ihm). Ist
  `GetRaidTargetIndex` geheim, wird die Markierung des Spiels
  (`UnitFrame.RaidTargetFrame`) nicht mehr mit ausgeblendet und per
  `NP.RaidAnchor` an unsere Stelle gesetzt (gesetzt, nie gelesen, in
  `pcall`). Das geht, solange die Plakette des Spiels Teil für Teil
  ausgeblendet ist (Debuffs „die des Spiels“, Standard). `/wcui auren`
  nennt, welcher Weg griff.

## [6.3.2.5] – 2026-09-26

**Auf wen der Gegner zaubert.** Der Zauberbalken auf Namensplaketten, am Ziel- und am Fokusrahmen nennt rechts das Ziel des Zaubers: „» Dich“ in Rot, wenn er auf dich geht, andere Spieler in ihrer Klassenfarbe. Wechselt der Gegner mitten im Zauber das Ziel, wechselt die Anzeige mit. Abschaltbar bei den Zauberbalken der Plaketten und Rahmen.

### Technisch

- `ui/castbar.lua`: `style.target`, `Bar:UpdateTarget` (Ziel der
  zaubernden Einheit, `<unit>target`), `Bar:AnchorText` (der Zaubername
  endet vor dem Ziel). Das Spiel nennt kein eigenes Zauberziel – das
  Ziel der Einheit ist bei Gegnern fast immer dasselbe; Plater und ElvUI
  zeigen dasselbe. Der Name kann geheim sein und geht nur an
  `SetFormattedText`; „Dich“ über `UnitIsUnit`. Höchstens 38 % der
  Balkenbreite. Bei „Unterbrochen“ verschwindet es.
- Plaketten: `castTarget` (Standard an), `UNIT_TARGET` zieht das Ziel
  während des Zaubers nach. Einheitenrahmen: `castTarget` für Ziel und
  Fokus (beim eigenen Zauber nicht – das Ziel steht im Zielrahmen).
  Farbe `castTargetMe` in `core/ui.lua`.

## [6.3.2.4] – 2026-09-26

**Gruppenrahmen mit mehr Einblick.** Eingehende Heilung als heller grüner Balken hinter dem Leben, Schilde als weißer Balken, ein Rollensymbol (Schild, Kreuz, Schwert) und eine Krone beim Gruppenleiter.

**Bereitschaftscheck im Rahmen.** Haken, Kreuz oder „?“ mitten im Knopf; das Ergebnis bleibt ein paar Sekunden stehen.

**Treffer und Wiederbelebung.** Wer getroffen wird, blitzt kurz rot auf; wer gerade wiederbelebt oder beschworen wird, steht unter dem Namen. Alles einzeln abschaltbar unter Gruppenrahmen → Allgemein.

### Technisch

- Heilung/Schild: zwei Balken (`UIKit.NewBar`) so breit wie der
  Lebensbalken, links an der Kante seiner Füllung bzw. der Heilfüllung,
  in einer Klammer (`SetClipsChildren`) über dem Lebensbalken. Wert und
  Höchstwert gehen unverändert an den Client (`UnitGetIncomingHeals`,
  `UnitGetTotalAbsorbs`, `UnitHealthMax`) – Lua rechnet nie mit
  geheimen Zahlen. Ohne Wert kein Balken.
- Rolle aus `UnitGroupRolesAssigned` (ohne zugewiesene Rolle kein
  Symbol), Krone aus `UnitIsGroupLeader`, Bereitschaft aus
  `GetReadyCheckStatus`; Zielmarkierung wandert nach oben rechts.
- Status: `UnitHasIncomingResurrection` → „Wird belebt“,
  `C_IncomingSummon.HasIncomingSummon` → „Beschwörung“, vor „Tot“.
- Treffer: `UNIT_COMBAT` mit Aktion `WOUND` (die Zahl wird nicht
  gelesen) lässt eine rote Fläche 0,35 s ausklingen. Ob der Beta-Client
  `UNIT_COMBAT` an Addons gibt, ist nicht gemessen.
- Eigene Grafiken `icon_tank`, `icon_dps`, `icon_leader`, `icon_check`
  (`make_ui_media.py`); Heiler nutzt `icon_plus`, „nicht bereit“
  `icon_close`. Farben in `core/ui.lua`. `K.Border` kann jetzt `SetAlpha`.

## [6.3.2.3] – 2026-09-26

**Kein Lua-Fehler mehr in der Gruppe.** Wechselte ein Gruppenmitglied oder dessen Begleiter die Fraktion, meldeten die Namensplaketten einen Fehler („unit tokens are not allowed“). Behoben.

### Technisch

- `UNIT_FACTION` kommt für jede Einheit; der Behandler fragte
  `C_NamePlate.GetNamePlateForUnit` auch mit `partypet4`, und der
  Beta-Client wirft bei Gruppen-/Schlachtzugskennungen („Raid<n>/Party<n>
  unit tokens are not allowed“, 14× in BugSack). Jetzt nur für
  `nameplateN` (`NP.IsPlateToken`), und der Aufruf steht in `pcall` –
  auch in `Attach`.

## [6.3.2.2] – 2026-09-26

**„zZ“ statt Mond.** Beim Ausruhen im Gasthaus oder in der Stadt zeigt der Spielerrahmen jetzt ein schlichtes „zZ“.

### Technisch

- Ruhe als Text (`UIKit.NewText`, 13 px, Farbe `stateRest`) statt der
  Grafik `icon_rest.tga`; die Grafik und ihre Form in `make_ui_media.py`
  sind entfernt. Kampf bleibt `icon_combat.tga`.

## [6.3.2.1] – 2026-09-26

**Kampf und Ruhe am Spielerrahmen.** Oben links am Rahmen: gekreuzte Schwerter im Kampf (leicht pulsierend), eine Mondsichel beim Ausruhen im Gasthaus oder in der Stadt. Abschaltbar unter Einheitenrahmen → Spieler.

**Deine Stufe im Spielerrahmen.** Vor dem Namen, wie beim Ziel.

**Eingabezeile wirklich erst mit Enter.** Die halbdurchsichtige Leiste unter dem Chat ist weg, solange du nicht schreibst; dort steht die Infozeile.

### Technisch

- Chat: 6.3.2.0 stellte die CVar `chatStyle` auf `im` – im Beta-Client
  ohne Wirkung, die inaktive Zeile stand weiter mit 0,35 Deckkraft da.
  Jetzt nur Deckkraft (`CH.UpdateEditState`, `CH.HookEdit`): nicht
  geschrieben = 0 (ein Haken auf `SetAlpha` hält das gegen das Spiel),
  beim Schreiben = 1; die Infozeile umgekehrt. Gezeigt und verborgen
  wird die Zeile weiter vom Spiel, die CVar wird nicht mehr angefasst.
- Spielerrahmen: Standardtext links `levelname`; `player_stateIcon` mit
  eigenen Grafiken `icon_combat`/`icon_rest` (`make_ui_media.py`),
  Farben `stateCombat`/`stateRest` in `core/ui.lua`. Kampf
  (`UnitAffectingCombat`) geht vor Ruhe (`IsResting`); Ereignisse
  `PLAYER_REGEN_*`, `PLAYER_UPDATE_RESTING`.

## [6.3.2.0] – 2026-09-26

**Debuffs mittig und rechts über der Plakette.** Bei „mittig“ standen die Symbole des Spiels unter der Namensplakette; jetzt stehen sie darüber, über dem Namen.

**Eingabezeile erst mit Enter.** Die Zeile zum Schreiben erscheint erst, wenn du Enter drückst, und verschwindet danach wieder; darunter bleibt die Infozeile frei. Abschaltbar unter Chat → Eingabezeile.

**Haltungsleiste passt sich an.** Sie ist so breit wie die Haltungen deiner Klasse und wächst mit, wenn du eine neue lernst – keine leere Fläche mehr neben zwei Knöpfen. Größe, Abstand, Anordnung, Fläche und „nur bei Maus“ stellst du wie bei jeder Leiste unter Aktionsleisten → Leisten → „Haltungen“ ein.

### Technisch

- `LayoutBar`: für `StanceButton` begrenzt `GetNumShapeshiftForms()` die
  Zahl der Plätze (nur, wenn der Client eine Zahl > 0 nennt; sonst gilt
  die Einstellung). `UPDATE_SHAPESHIFT_FORMS` ordnet nach dem Kampf neu.
- Plaketten: `AlignGameAuras` setzt `DebuffListFrame` an die
  WeintCodex-Plakette (`BOTTOM` → `TOP`, rechts `BOTTOMRIGHT` →
  `TOPRIGHT`), über dem Namen, Versatz im Maßstab der Symbole des
  Spiels. 6.3.1.9 setzte sie an die Unterkante des Aurenrahmens des
  Spiels – der reicht bis unter die Plakette.
- Chat: `editOnEnter` (Standard an) setzt die CVar `chatStyle` auf `im`
  – die Einstellung „Chatstil“ des Spiels, kein eigenes Verstecken der
  Eingabezeile (sie trägt geschützte Befehle). Außerhalb des Kampfes;
  ausgeschaltet stellt sie nur zurück, was WeintCodex in dieser Sitzung
  selbst geändert hat. Die CVar steht in der Konfiguration des Spiels und
  übersteht deshalb auch in der Beta das Neuladen.

## [6.3.1.9] – 2026-09-26

**Name in der Namensplakette.** Unter Namensplaketten → Texte → „Name steht“: über der Plakette, im Balken links mit Stufe davor oder im Balken mittig. Die Textplätze darunter lassen sich weiter einzeln belegen, neu auch mit „Stufe und Name“.

**Debuffs links, mittig oder rechts.** Unter Namensplaketten → Auren → Ausrichtung. Bei den Symbolen des Spiels ist das ein Versuch – /wcui auren sagt, ob das Spiel es annimmt.

**Leere Aktionsplätze sichtbar.** Die Plätze einer Leiste stehen jetzt auch leer dezent da, nicht erst beim Ziehen eines Zaubers. Wie bisher einstellbar unter Aktionsleisten → Leere Plätze.

### Technisch

- Plaketten: Textart `levelName` (Stufe in ihrer Farbe vor dem Namen,
  `SetFormattedText`, der Name darf geheim sein). „Name steht“ ist eine
  Voreinstellung über `textTop/Left/Center/Right` (`NP.NamePlace`,
  `NP.SetNamePlace`), kein eigener gespeicherter Wert. Steht ein Name
  links oder rechts im Balken, bekommt diese Seite 70 % der Breite; die
  Mitte schrumpft auf 55 %, wenn links oder rechts Text steht. Das
  Aufhellen bei Ziel/Maus gilt jedem Platz mit Namen, nicht nur oben.
- `auraAlign` (left | center | right). Eigene Symbole: Anker und
  Wachstumsrichtung; mittig steht der Block, weniger Symbole als Plätze
  beginnen links in ihm. Symbole des Spiels: links unverändert; sonst
  wird `AurasFrame.DebuffListFrame` an Mitte bzw. rechte Kante gesetzt
  (nur gesetzt, nie gelesen, in `pcall`) – ob die Liste so heißt und mit
  dem Inhalt wächst, ist nicht gemessen; `/wcui auren` nennt das Ergebnis.
- Aktionsleisten: `emptySlots` Standard `faint` statt `hide`; leere
  Plätze deutlicher (Rand 60 %, Grund 35 %).

## [6.3.1.8] – 2026-09-26

**Reiter rechts am Charakterfenster im neuen Stil.** Kleine Kacheln statt Goldrahmen, der gewählte mit Rand im Akzent, unter der Maus heller.

**Ruf und Fertigkeiten ohne Holz.** Die Balken sind flach mit feinem Rand, die Trennlinien zwischen den Spalten und über den Listen sind weg.

**/wcui fenster sagt mehr.** Die Ausgabe nennt jetzt die Fassung von WeintCodex, wie oft das Fenster gestaltet wurde, und markiert Bilder, die eigentlich weg sein sollten.

### Technisch

- Im Beta-Test zeigte 6.3.1.7 im Charakterfenster keine Wirkung. Ob die
  Fassung nicht ankam, die zweite Stufe nicht lief oder das Spiel die
  Deckkraft zurücksetzt, ist aus dem Bild nicht zu sagen. `W.stats`
  (Läufe, ausgeblendet, „ohne Wirkung“ = Alpha nach dem Setzen nicht 0,
  letzter Fehler) und `W.Status()` stehen jetzt in `/wcui fenster`,
  dazu die Fassung und je Atlas „SOLLTE WEG SEIN“, wenn `W.HidesAtlas`
  ihn trifft und er trotzdem sichtbar ist.
- Neue Muster aus `/wcui fenster` auf Ruf und Fertigkeiten:
  `common-sidetab*`, `common-stat-bar-BG`, `common-framedivider`,
  `UI-Character-Info-ScrollLine*`. Balken bekommen einen flachen Grund
  (`plateBg`) und 1 px Rand; `CharacterFrameModeTab1..` eine Kachel,
  deren Rand dem `SelectedTexture` folgt.

## [6.3.1.7] – 2026-09-26

**Charakterfenster auch innen im neuen Stil.** Holz- und Steinhintergründe, der Klassenhintergrund hinter den Werten, die Holzbalken der Kopfzeilen, die Streifen hinter den Werten und die Metallrahmen der Ausrüstungsplätze sind weg; die Plätze sind flach mit feinem Rand wie die Aktionsknöpfe. Die Bühne des Modells bleibt.

### Technisch

- `ui/windows.lua`: `W.HIDE_ATLAS` – Atlasmuster aus `/wcui fenster`
  im Beta-Test (`UI-Character-Info-General-BG`, `-Stat-BG`,
  `-Stat-StoneBG`, `-<Klasse>-BG`, `-Title`, `-Line-Bounce*`,
  `-GearSlot`, `-Divider`, `common-insideframe`); `RaceBG` bleibt.
  `HideByAtlas` läuft bei jedem Zeigen und, solange das Fenster offen
  ist, zweimal je Sekunde über einen eigenen Kindrahmen (neue
  Listenzeilen beim Blättern und Reiterwechsel), kein Skript am Fenster
  des Spiels.
- Ausrüstungsplätze (`Character…Slot`, am Namen erkannt): Normaltextur
  unsichtbar, 1 px schwarzer Rand.

## [6.3.1.6] – 2026-09-26

**Charakterfenster im neuen Stil.** Das Fenster hinter Taste C – mit Ruf, Fertigkeiten, PvP und Abzeichen – steht auf einer Kachel statt auf Holz und Metall, ohne das runde Porträt, der Titel in der Schrift der Oberfläche. Erste Stufe: die Hülle; das Innere folgt.

**Tageszeit in jeder Ecke.** Unter Minikarte wählst du, ob die Tageszeit unten rechts, unten links, oben rechts oder oben links in der Karte sitzt.

**Addon-Knöpfe hell, zweiter Anlauf.** Die Knöpfe anderer Addons froren ihre Zeichenebene ein und blieben so unter der dunklen Kachel; jetzt liegen sie darüber.

**Neu: /wcui fenster.** Maus über ein Fenster halten und abschicken: Der Chat nennt die größten Bilder darin.

### Technisch

- Neu `ui/windows.lua` (`WeintCodex.UIWindows`), Einstellung
  `windowSkin` beim Modul „general“ (Seite „Tooltip & Fenster“).
  `W.Skin` macht nur Schmuck der Fenstervorlage durchsichtig
  (`NineSlice`, `Bg`, `Inset`, Porträt, eigene Texturen des obersten
  Rahmens; `KeepHidden`) und legt eine Kachel darunter; Teilfenster
  (`ReputationFrame`, `SkillFrame`, `TokenFrame`, PvP …) verlieren nur
  ihren Schmuck. Inhalte (Plätze, Balken, Listen, Modell) bleiben
  unberührt. Die Namen der Teilfenster auf Forever sind nicht gemessen.
- Minikarte: `dayCorner` (vier Ecken); oben rückt die Tageszeit unter
  Uhrzeit bzw. Koordinaten.
- Sammelknopf: LibDBIcon setzt `SetFixedFrameStrata`/`-Level` (MEDIUM/8);
  `SetFrameStrata` wirkte deshalb nicht, und die Liste in `DIALOG` lag
  über den Knöpfen. Die Liste steht jetzt in `MEDIUM` auf Stufe 1, die
  Knöpfe werden vor dem Setzen gelöst.
- `K.InspectWindow` (`/wcui fenster`): oberstes Fenster unter der Maus,
  sichtbare Texturen bis Tiefe 6, nach Bild zusammengefasst, größte
  Fläche zuerst.

## [6.3.1.5] – 2026-09-26

**Neuer Erfahrungsbalken.** Schmal, im Stil der Oberfläche, mit erholter Erfahrung als blasser Verlängerung. Auf Höchststufe zeigt er den beobachteten Ruf. Die goldene Leiste des Spiels ist weg.

**Nur bei Maus darüber.** Der Balken kann unsichtbar bleiben, bis die Maus darauf zeigt; die Zahlen stehen wahlweise immer, bei Maus darüber oder nie im Balken.

**Tempo je Stunde.** Die Maus über dem Balken zeigt Werte, was bis zur nächsten Stufe fehlt, erholte Erfahrung und – sobald in dieser Sitzung Erfahrung dazukam – Erfahrung je Stunde samt Schätzung bis zum Aufstieg. Einstellbar unter Aktionsleisten → Erfahrung.

### Technisch

- Neu `ui/xpbar.lua` (`WeintCodex.UIXPBar`), geladen nach
  `ui/actionbars.lua`: hängt Standardwerte (`xp*`), den Reiter
  „Erfahrung“, das Einschalten und die Einstellungen an das Modul
  „Aktionsleisten“. Ein eigener Eintrag hätte die Seitenleiste des
  Einstellungsfensters überfüllt (`load_test.lua`: 664 von 680 px).
- Balken aus `UIKit.NewBar` auf einer Kachel, Farben `xpBar`/`xpRested`
  (= Akzent: Fortschritt, wie `cast`) in `core/ui.lua`, Platz `xpbar` in
  `ui/layout.lua`, verschiebbar im Gestaltungsmodus.
- Erfahrung nur, wenn der Client sie nennt und es welche gibt; auf
  Höchststufe oder bei gesperrter Erfahrung der beobachtete Ruf
  (`C_Reputation.GetWatchedFactionData`, sonst `GetWatchedFactionInfo`),
  ohne ihn kein Balken. Tempo erst nach gemessener Erfahrung und einer
  Minute Sitzung; ein Aufstieg zählt den Rest der alten Stufe mit.
- Die Leiste des Spiels (`MainStatusTrackingBarContainer` u. a.) wird
  nur unsichtbar (`KeepHidden`) und nimmt keine Maus mehr; verschoben
  oder umgehängt wird sie nicht (Bearbeitungsmodus, vgl. 6.3.0.6).

## [6.3.1.4] – 2026-09-26

**Keine Namensplakette mehr am falschen Gegner.** Manchmal blieb eine Plakette eingefroren stehen – mit Namen, Leben und Zielleuchten eines anderen Gegners – und wanderte an den nächsten. Das ist behoben.

**Tageszeit unten rechts in der Minikarte.** Die Sonne heißt in diesem Client anders als in allen bisherigen; jetzt wird sie gefunden und sitzt über dem Gebietsstreifen.

**Questliste ganz ohne Fläche.** Deckkraft 0 % unter Questliste blendet die Fläche samt Rand und Schatten aus.

**Addon-Knöpfe und Chat-Reiter.** Addon-Knöpfe in der Kachel des Sammelknopfs bleiben voll deckend, und die Reiterzeile des Chats liegt eine Schicht über dem Chatfenster. /wcui maus nennt jetzt auch Texte, Farbflächen und die Deckkraft unter dem Zeiger.

### Technisch

- Minikarte: Die Tageszeit ist im Beta-Client `MinimapCluster.DielFrame`
  (Atlas `UI-HUD-Minimap-DayCycle`, keine Mausannahme – deshalb nannte
  `GetMouseFoci` nur `Minimap`). `MM.TimeButton` prüft ihn zuerst, die
  Namenssuche kennt zusätzlich „Diel“.
- Addon-Knöpfe in der Liste: `KeepOpaque` hält sie auf Alpha 1 (Haken
  auf `SetAlpha`, nur solange die Liste ihr Elternrahmen ist). Verdacht:
  LibDBIcon blendet Knöpfe ab, wenn die Maus nicht über der Karte steht.
  Nicht gemessen.
- Chat: `RaiseDock` setzt `GeneralDockManager` in die Schicht `MEDIUM`
  (Haken auf `SetFrameStrata`). Die Reiter blieben mit der Fläche in
  `BACKGROUND` unsichtbar; das Chatfenster steht in `LOW` drei Stufen über
  ihnen. Ebenfalls ein Verdacht, keine Messung.
- `K.UnderCursor`: auch `FontString`s (mit Text), Farbflächen, Zeichenebene
  und Deckkraft; Regionen mit Alpha 0 fallen weg; bis zu 18 Zeilen.
- Questliste: `bgAlpha = 0` blendet `WeintCodexQuestPanel` ganz aus.
- Plaketten: `Attach` löst vorher ab, was schon an derselben Einheit
  (`plates[unit]`) oder an derselben Plakette des Spiels (`byPlate`) hängt.
  Bisher überschrieb ein zweites `NAME_PLATE_UNIT_ADDED` (Neuladen: die
  Schleife in `Enable` und das Ereignis) den Eintrag, und die alte
  Plakette blieb sichtbar, ohne Updates, an der Plakette des Spiels – die
  das Spiel dem nächsten Gegner gibt.

## [6.3.1.3] – 2026-09-26

**Die Chat-Reiter sind wieder zu sehen.** Die dunkle Fläche des Chats lag über „Allgemein“ und „Kampflog“ und hat sie fast ganz verdeckt; jetzt liegt sie darunter.

**/wcui maus sieht mehr.** Neben den Rahmen, die auf die Maus reagieren, nennt der Befehl jetzt auch Bilder und Rahmen ohne Mausklick unter dem Zeiger, samt Bilddatei.

### Technisch

- Chat: Die eigene Fläche (`d.back`, Kind des Chatrahmens) stand seit
  6.3.0.9 in `LOW` eine Stufe unter den Reitern. `/wcui chat` im
  Beta-Test zeigte sie auf `LOW/5` (Stufe des Chatrahmens), die Reiter auf
  `LOW/2`: Das Spiel hebt die Stufe, und die Reiterzeile (`d.strip`, Alpha
  bis 0,75) lag über den Reitern. `CH.PinBack` setzt sie jetzt in die
  Schicht `BACKGROUND`, hält sie mit `SetFixedFrameStrata`/
  `SetFixedFrameLevel` und setzt sie nach jedem `SetFrameStrata` des
  Chatrahmens neu.
- `K.UnderCursor`: alle sichtbaren Rahmen aus `EnumerateFrames` und deren
  Texturen, die die Mausposition überdecken, nach Fläche sortiert (die
  kleinsten zuerst), mit Atlas oder Bilddatei. `/wcui maus` zeigt die
  ersten zehn. Anlass: Über der Tageszeit-Sonne meldete `GetMouseFoci`
  nur `Minimap`.

## [6.3.1.2] – 2026-09-26

**Addon-Knöpfe in voller Helligkeit.** In der aufgeklappten Kachel des Sammelknopfs lagen die Knöpfe hinter deren dunkler Fläche; jetzt liegen sie darüber.

**Tageszeit wird breiter gesucht.** Heißt sie in diesem Client anders als erwartet, findet WeintCodex sie jetzt auch über die Rahmen an der Minikarte.

**Neu: /wcui maus.** Maus über ein Ding am Bildschirm halten und /wcui maus abschicken: Der Chat nennt Name, Elternrahmen und Anker aller Rahmen darunter.

### Technisch

- Minikarte: Addon-Knöpfe setzen ihre Schicht selbst (LibDBIcon: `MEDIUM`);
  unter der Liste (`DIALOG`) lag deren Kachel über ihnen. `MM.LayoutBag`
  gibt ihnen Schicht und Stufe + 2 der Liste. Ist `addonBag` aus, hängt
  `ColumnButtons` sie von der versteckten Liste zurück an die Karte.
- `MM.TimeButton` sucht nach den drei Namen zusätzlich die Kinder von
  `Minimap` und `MinimapCluster` nach „GameTime“/„DayNight“ im Namen
  (`GetDebugName`).
- `K.Describe` (aus `ui/chat.lua` nach `ui/kit.lua` gezogen, nennt
  Elternrahmen jetzt per `GetDebugName`) und `K.InspectMouse` für
  `/wcui maus`: alle Rahmen aus `GetMouseFoci` mit Elternkette und Ankern,
  alles in `pcall`.

## [6.3.1.1] – 2026-09-26

**Ein Knopf für alle Addons an der Minikarte.** Unten links neben der Minikarte sitzt ein Knopf mit neun Punkten; ein Klick klappt alle Addon-Knöpfe in einer Kachel auf, ein zweiter klappt sie wieder zu. Kartenmarkierungen anderer Addons (Wegpunkte, Fundorte) bleiben auf der Karte. Abschaltbar unter Minikarte → „Addon-Knöpfe sammeln“.

**Tageszeit unten rechts.** Die Tageszeit-Sonne (zugleich der Kalender) steht unten rechts in der Karte, über dem Gebietsstreifen.

**Genauere Chat-Prüfung.** /wcui chat nennt jetzt auch Textfarbe, laufende Blendanimationen und ob die Andockleiste ihre Reiter abschneidet.

### Technisch

- Minikarte: `addonBag` – `MM.AddonButtons` sammelt nur LibDBIcon-Knöpfe
  (`LibStub("LibDBIcon-1.0").objects` und Kinder der Karte namens
  `LibDBIcon10_*`), gezeigte, nach Namen sortiert, und hängt sie in eine
  Kachel über dem Sammelknopf (vier je Reihe). Die breite Suche aus
  6.3.1.0 (jeder kleine Knopf) ist zurückgenommen: sie hätte
  Kartenmarkierungen anderer Addons eingesammelt. `MM.TimeButton`
  (`GameTimeFrame`, sonst `MinimapCluster.GameTimeFrame`) unten rechts in
  der Karte, nicht mehr in der Spalte.
- `/wcui chat`: Textfarbe von Reiter 1, Animationsgruppen (laufend?) von
  Reiter und Text, `DoesClipChildren` von Andockleiste, Chatfenster und
  Elternrahmen, Unterkanten.
- `load_test.lua`: Sammelknopf (Addon-Knopf hinein, Wegpunkt nicht, Klick
  klappt auf), Tageszeit unten rechts, Spalte ohne beides.

## [6.3.1.0] – 2026-09-26

**Minikarte: alle Knöpfe neben die Karte.** Die Tageszeit-Sonne und Knöpfe anderer Addons lagen mitten auf der Karte, weil sie auf keiner festen Liste standen. Jetzt kommt jeder kleine Knopf auf oder an der Karte in die Spalte links daneben – reicht die Höhe nicht, in eine zweite Spalte.

**Chat-Prüfung.** /wcui chat schreibt in den Chat, was WeintCodex über Chatfenster, Reiter, Knöpfe und Eingabezeile sieht. Die Reiter blieben im Beta-Test unsichtbar, und ohne diese Auskunft wäre jeder weitere Versuch geraten.

### Technisch

- Minikarte: `ColumnButtons` nimmt außer der festen Liste jeden
  gezeigten `Button` von 10–48 px unter `Minimap`, `MinimapCluster`,
  `MinimapBackdrop` und `MinimapCluster.MinimapContainer` auf (ohne
  Zoomknöpfe und eigene Rahmen). Mehrspaltig, wenn die Kartenhöhe nicht
  reicht. In der ersten Minute alle fünf Sekunden neu (Addons legen
  Knöpfe spät an).
- Chat: `UIChat.Inspect` / `/wcui chat` – Zustand von Chatfenster 1,
  eigener Fläche, Reitern 1–4, Andockleiste, Knöpfen, Knopfleiste,
  Eingabezeile und Infozeile (gezeigt, sichtbar, Alpha, wirksames Alpha,
  Schicht/Stufe, Lage, Elternrahmen).
- `load_test.lua`: Addon-Knopf in der Spalte, großer Rahmen nicht;
  `/wcui chat` antwortet.

## [6.3.0.9] – 2026-09-25

**Chat: Reiter sichtbar, keine Bildlaufleiste.** Die Reiter sind wieder zu sehen – die WeintCodex-Fläche lag über ihnen statt darunter. Die halbdurchsichtige Bildlaufleiste und der Pfeil nach unten am rechten Rand sind weg; blättern geht mit dem Mausrad (abschaltbar).

**Tooltip im neuen Design.** Die Hinweisfenster sind eine Kachel wie der Rest der Oberfläche. Spielernamen stehen in Klassenfarbe, der Rand leuchtet in Klassenfarbe bzw. bei Gegenständen ab „selten“ in ihrer Qualität, der Lebensbalken ist flach und angedockt. Einstellbar unter Allgemein → Tooltip.

**Minikarte ohne leeren Platz.** Die Karte rückt nach oben, wo die ausgeblendete Kopfleiste des Spiels stand. Eine zweite Koordinatenzeile, die nicht von WeintCodex stammt, wird ausgeblendet.

### Technisch

- Chat: die Kachel liegt auf einem eigenen Kindrahmen eine Stufe unter
  Chatrahmen und Reiter (`SetFrameLevel(min(cf, tab) - 1)`). Auf dem
  Chatrahmen selbst deckte sie die Reiter, die eine Stufe tiefer stehen.
  `hideScrollBar`: `ScrollBar`, `ScrollToBottomButton` auf Alpha 0 per
  `SetAlpha`-Haken, keine Maus.
- Neu: `ui/tooltip.lua` (`WeintCodex.UITooltip`), Einstellungen beim
  Modul „general“ (Seite „Tooltip“) – ein eigenes Modul hätte die
  Seitenleiste überfüllt. Kachel als Kindrahmen unter dem Tooltip,
  `NineSlice` auf Alpha 0, `TooltipDataProcessor.AddTooltipPostCall` für
  Einheit (Klassenfarbe, nur bei offenem `unit`/`class`) und Gegenstand
  (Qualität ≥ 2). `GameTooltipStatusBar` flach, 5 px, mit Rand. Kein
  Text wird gelesen.
- Minikarte: `atTop` setzt `Minimap` an `MinimapCluster` TOPRIGHT
  (Haken auf `SetPoint` holt sie zurück). `hideOtherCoords`: sucht im
  Kartenbereich (drei Ebenen) Schriften, die wie Koordinaten aussehen und
  nicht von WeintCodex sind, und blendet sie aus; in der ersten Minute
  alle fünf Sekunden.
- `load_test.lua`: Bildlaufleiste, Tooltip, Minikarte oben, fremde
  Koordinaten.

## [6.3.0.8] – 2026-09-25

**Der Zauberbalken im neuen Kleid.** Der Zaubername steht wieder da (das Spiel lieferte einen leeren Anzeigetext). Der eigene Zauberbalken in der Mitte ist größer (20 px hoch, 240 breit, einstellbar), das Symbol steht abgesetzt mit eigenem Rand, eine helle Kante läuft am Ende der Füllung mit, und rot am Ende zeigt die Latenz: ab da darfst du den nächsten Zauber schon drücken.

**Mikromenü und Taschenleiste nur bei Maus darüber.** Unter Aktionsleisten → Anordnung stellst du beide auf „Nur bei Maus darüber“: unsichtbar, bis die Maus in die Nähe kommt, dann blenden sie weich ein. Anklicken geht auch unsichtbar.

### Technisch

- Aktionsleisten: `microShow`, `bagsShow` (`always` | `mouseover`) über
  dieselbe Blende wie die Leisten (`Faded()` sammelt Leisten, Mikromenü,
  Taschenleiste samt Fläche). Mausprüfung mit 6 px Luft
  (`IsMouseOver(6, -6, -6, 6)`). Zurück auf „Immer“: Mikromenü und
  Taschen bekommen Alpha 1 von hier (sie hängen nicht an „Ruhe und
  Kampf“).
- Zauberbalken (`ui/castbar.lua`): Text = Zaubername (`UnitCastingInfo`
  Wert 1), nicht der Anzeigetext (Wert 2 kam im Beta-Client leer).
  Symbol auf eigenem Rahmen mit Rand, 3 px abgesetzt; Grund und Rand nur
  am Balken. Kante (`castSpark`) an der Füllung verankert, läuft also
  auch mit `SetTimerDuration`. Latenz (`castLatency`, `style.latency`):
  Weltlatenz aus `GetNetStats` im Verhältnis zur Zauberdauer, nur mit
  offenen Zeiten, nicht bei Kanalzaubern. Einheitenrahmen:
  `playerCastHeight` 20, `playerCastWidth` 240, `playerCastLatency`.
- `load_test.lua`: Mikromenü/Taschen aus, Maus darüber, zurück auf
  „Immer“; Zauberbalken mit Name, Kante, Latenz.

## [6.3.0.7] – 2026-09-25

**Schadensanzeige: Aufschlüsselung wie bei Details.** Klick auf einen Namen in der Schadensanzeige öffnet daneben ein eigenes Fenster: Gesamt, je Sekunde, Anteil und Rang, darunter jeder Zauber mit Balken, Summe, Wert je Sekunde und Anteil. Oben schaltest du zwischen Schaden, Heilung und erlittenem Schaden desselben Spielers um, die Pfeile blättern zum nächsten. Es läuft im Kampf live mit; Esc oder ein zweiter Klick schließt.

**Der Chat im neuen Kleid.** Die Reiter bleiben sichtbar – das Spiel hatte sie trotz Einstellung ausgeblendet. Unter dem Chat steht eine Infozeile wie bei ElvUI: Uhrzeit, Gold, freie Taschenplätze, Haltbarkeit, Bildrate und Latenz; beim Schreiben liegt die Eingabezeile darüber. Klick auf die Uhrzeit öffnet den Kalender, auf Gold oder Taschen die Taschen.

**Taschenleiste im Stil der Aktionsleisten.** Die Taschenplätze unten rechts sind flach mit feinem Rand und stehen auf einer Fläche, wie die Aktionsleisten – die goldenen Rahmen sind weg.

### Technisch

- Schadensanzeige: `DM.OpenBreakdown(w, src)` (Zeile `OnMouseUp`),
  `DM.RefreshBreakdown` im Takt von `DM.Refresh`, `DM.StepBreakdown`.
  Spieler über GUID, sonst Namen wiedergefunden (`SameSource`), damit der
  Wechsel der Messart denselben Spieler zeigt. Zauber über
  `DM.Spells`; je Sekunde aus `amountPerSecond` des Zaubers, sonst aus
  der Kampfdauer (nur offene Werte). `UISpecialFrames` für Esc.
  Beispielzauber `DM.TEST_SPELLS` für den Testmodus.
- Chat: Haken auf `SetAlpha` jedes Reiters (die `CHAT_FRAME_TAB_*_NOMOUSE_ALPHA`-
  Werte wirkten im Beta-Client nicht). Infozeile `WeintCodexChatInfo`
  (`infoBar`): `GetMoney`, `C_Container.GetContainerNumFreeSlots`,
  `GetInventoryItemDurability`, `GetFramerate`, `GetNetStats` – geheim
  oder fehlend → „–“. Die Eingabezeile von Fenster 1 liegt darüber und
  blendet sie beim Schreiben aus.
- Aktionsleisten: `bagsSkin` – die Taschenknöpfe durch dieselbe
  Umgestaltung wie die Aktionsknöpfe, `IconBorder` aus, offene Tasche
  flach im Akzent, Kachel hinter `BagsBar`.
- `load_test.lua`: Aufschlüsselung, Infozeile, Taschenleiste.

## [6.3.0.6] – 2026-09-25

**Aktionsleisten verschiebst du wieder im Bearbeitungsmodus des Spiels.** Das Spiel stapelt Leiste 2, Haltungs- und Begleiterleiste auch im Kampf selbst neu, etwa wenn dein Begleiter verschwindet – nachdem WeintCodex die Leisten verschoben hatte, blockierte das Spiel diesen eigenen Schritt und meldete einen Fehler. Verschieben geht jetzt nur noch im Bearbeitungsmodus des Spiels (Esc → Bearbeitungsmodus); dort verschobene Leisten lässt das Spiel an ihrem Platz. Größe, Abstand, Reihen und Anzahl der Knöpfe stellst du weiter unter Aktionsleisten → Leisten ein.

### Technisch

- Beta-Test: `ADDON_ACTION_BLOCKED` in `SetPointBase`, aufgerufen aus
  `EditModeManager:UpdateBottomActionBarPositions` ← `PetActionBar:Update`
  (Begleiterleiste verschwindet im Kampf). Das Spiel stapelt die unteren
  Leisten in Standardlage selbst, auch im Kampf; nach dem Verschieben
  durch WeintCodex (6.3.0.4) und dem Anker-Haken (6.3.0.5) lief dieser
  Aufruf verunreinigt.
- Zurückgenommen: Aktionsleisten im Gestaltungsmodus (`ab_<n>`), der
  `SetPoint`/`SetPointBase`-Haken und `RegisterMover`-Option `external`.
  `ui/kit.lua` steht wieder wie in 6.3.0.0.
- Bleibt: die Anordnung der Knöpfe je Leiste (`layout = "wc"`) – ob auch
  sie im Kampf etwas blockieren lässt, ist nicht geprüft; `layout =
  "game"` schaltet sie ab.
- `load_test.lua`: keine Aktionsleiste im Gestaltungsmodus.

## [6.3.0.5] – 2026-09-25

**Verschobene Aktionsleisten bleiben, wo du sie hinstellst.** Leiste 2 und 3 stehen im Spiel in einem Bereich, den das Spiel selbst ordnet, sobald sich unten etwas ändert – etwa die Erfahrungsleiste. Dabei rückte es eine verschobene Leiste alle paar Minuten ein Stück zur Seite. Jetzt kommt sie jedes Mal sofort an ihren Platz zurück.

### Technisch

- `UIKit.RegisterMover(…, { external = true })`: Haken auf `SetPoint` und
  `SetPointBase` des fremden Rahmens. Setzt das Spiel einen Rahmen mit
  eigenem Platz neu (verwalteter Bereich unten, `UIParent_ManageFramePositions`),
  setzt WeintCodex ihn einen Augenblick später zurück (`C_Timer.After(0)`,
  nie im Kampf). `m.applying` verhindert, dass der eigene Anker den Haken
  auslöst. Vorher kam er nur nach `ApplySystemAnchor` zurück.
- `load_test.lua`: ein fremder Anker bringt die Leiste zurück.

## [6.3.0.4] – 2026-09-25

**Aktionsleisten einstellen wie bei EllesmereUI.** Unter Oberfläche → Aktionsleisten → Leisten stellst du für jede Leiste Symbolgröße, Abstand, Knöpfe je Reihe und Anzahl ein, dazu die Fläche und „Nur bei Maus darüber“. Verschieben geht im Gestaltungsmodus, ein Doppelklick auf eine Leiste öffnet ihre Einstellungen, Rechtsklick gibt sie dem Bearbeitungsmodus des Spiels zurück. Leisten ohne belegten Knopf bekommen keine leere Fläche mehr.

### Technisch

- `ui/actionbars.lua`: `layout` (`wc` Standard, `game`). Je Leiste flach
  `b<n>_size|spacing|perRow|count|backdrop|show`. `AB.LayoutAll` setzt
  außerhalb des Kampfes Größe und Anker der Knöpfe (an ihrer eigenen
  Leiste) und schneidet die Leiste auf ihre Knöpfe zu; Knöpfe jenseits der
  Anzahl: Alpha 0, keine Maus (`AB.cut`). Haken auf `UpdateGridLayout`/
  `Layout` ordnen nach dem Spiel neu. „Nur bei Maus darüber“: eigene
  Blende, solche Leisten nimmt `UIPresence` aus. Fläche: bei eigener
  Anordnung auf der Leiste, sonst gemessen; ohne belegten Knopf keine.
- `UIKit.RegisterMover(…, { external = true, onReset })`: Rahmen, die sonst
  der Bearbeitungsmodus stellt – kein Standardplatz, Position als linke
  untere Ecke zu UIParent, Rechtsklick → `onReset`
  (`ApplySystemAnchor`). Leisten als `ab_<n>` im Gestaltungsmodus,
  Doppelklick öffnet ihre Seite.
- **Ungeprüft im Spiel**, vor allem: ob das Anordnen der Knöpfe des Spiels
  Taint im Kampf erzeugt.
- `load_test.lua`: Anordnung, Zuschnitt, ausgeblendete Knöpfe, Maus
  darüber, fremde Rahmen im Gestaltungsmodus, Seite „Leisten“.

## [6.3.0.3] – 2026-09-25

**Jede Aktionsleiste steht auf einer eigenen Fläche.** Eine dunkle Kachel mit feinem Rand hinter den Knöpfen, die jeder Anordnung aus dem Bearbeitungsmodus folgt. Tastenkürzel oben rechts, Stapelzahl unten rechts, die Blätterpfeile neben Leiste 1 sind weg (Umblättern weiter mit Umschalt+Mausrad). Beides unter Aktionsleisten → Leisten abschaltbar.

**Keine Auren-Prüfung mehr im Chat.** Die Debuffs auf den Plaketten sind bestätigt; /wcui auren gibt die Auskunft weiter auf Wunsch und sagt ehrlich „nicht messbar“, wo das Spiel die Symbole geheim hält.

### Technisch

- Aktionsleisten: `barBackdrop` – `UIKit.Kachel` auf einem Rahmen, der
  Kind der Leiste ist (blendet mit Ruhe/Kampf ab) und an der linken
  oberen und rechten unteren sichtbaren Taste verankert wird
  (`AB.UpdateBackdrops`, nur außerhalb des Kampfes, bei Weltbetreten und
  nach dem Bearbeitungsmodus). Unmessbare Knöpfe → keine Fläche.
  `hidePaging` (`AB.HidePaging`, über `AB.KeepHidden`). HotKey/Count/Name
  an festen Plätzen.
- Auren: Beta-Test zeigt, dass `C_UnitAuras.GetAuraDataByIndex` im Kampf
  für Addon-Code gesperrt ist („Auras cannot be accessed when secret“) –
  der alte Weg (eigenes Lesen) kann im Kampf nichts. `Visible` gibt `nil`
  statt „0 sichtbar“, wenn der Client die Container-Knöpfe nicht messen
  lässt; die Selbstprüfung urteilt dann nicht (vorher hätte sie auf den
  alten Weg umschalten können). `UIAuras.AUTO_REPORT = false`.
- `load_test.lua`: Fläche, Schalter, unmessbare Knöpfe, Blätterpfeile.

## [6.3.0.2] – 2026-09-25

**Aktionsleisten mit einem Rahmen.** Der innere Rahmen des Spiels um jedes Symbol bleibt weg – das Spiel hatte ihn bei jedem Aktualisieren neu gesetzt. Das Symbol füllt den Knopf, darum liegt nur noch eine feine Kante.

**/wcui auren funktioniert wieder.** Die Auren-Prüfung brach an Werten ab, die das Spiel geheim hält, und schrieb dabei Lua-Fehler – jetzt steht dort „?“.

### Technisch

- Aktionsleisten: `NormalTexture` (und `SlotArt`, `SlotBackground`,
  `IconMask`, `Border` …) über `AB.KeepHidden` – ein
  `hooksecurefunc`-Haken auf `SetAlpha` und auf `SetNormalAtlas`/
  `SetNormalTexture` des Knopfs hält sie auf Alpha 0. Symbol und
  Abklingspirale auf die ganze Knopffläche (nur außerhalb des Kampfes).
- Auren-Prüfung: die Knöpfe des AuraContainers sind im Beta-Client
  verboten oder haben geheime Breiten („secret number“, „forbidden
  object“) – `IsForbidden`, `pcall`, `UIKit.Plain`; je Objekt eine Zeile,
  auch wenn sie nicht lesbar ist. `/wcui auren` brach daran ab.
- `load_test.lua`: beide Fälle.

## [6.3.0.1] – 2026-09-25

**Debuffs stehen an ihrem Platz, ohne Lua-Fehler.** Die Debuff-Symbole der Plakette des Spiels bleiben, wo das Spiel sie hinsetzt – WeintCodex blendet nur den Rest der Spielplakette aus. Der weiße Balken über dem Namen und der Fehler „Can't measure restricted regions“ sind weg.

### Technisch

- Plaketten, `auraSource = "game"`: kein Umhängen mehr. 6.3.0.0 las die
  Anker des Aurenrahmens (`GetPoint`) – im Beta-Client verboten
  („Can't measure restricted regions“, Taint), und umgehängt zeichnete er
  einen weißen Balken. Jetzt bleibt der Blizzard-UnitFrame sichtbar
  (Alpha 1), alle Kinder und Regionen außer dem Aurenrahmen gehen auf
  Alpha 0; setzt das Spiel eine Deckkraft zurück, blendet ein
  `hooksecurefunc`-Haken wieder aus und merkt sich den neuen Wert fürs
  Zurückgeben. Kein Anker wird gelesen oder gesetzt. Beantwortet der
  Client `GetChildren`/`GetRegions` nicht, bleibt es beim Ausblenden der
  ganzen Plakette (wie `own`).
- `load_test.lua`: kein Ankerlesen, Symbole bleiben am UnitFrame, Rest
  ausgeblendet, Rückgabe beim Freigeben und beim Wechsel auf `own`.

## [6.3.0.0] – 2026-09-25

Antworten auf den vierten Beta-Test.

**Der Zielrahmen ist beim Anklicken sofort gefüllt.** Manchmal erschien er als weißer Balken ohne Namen – er wurde sichtbar, bevor er seine Werte bekam.

**Debuffs auf den Namensplaketten kommen jetzt vom Spiel selbst.** WeintCodex hängt die Debuff-Symbole der Plakette des Spiels an die eigene Plakette. Die eigenen Symbole bleiben unter Namensplaketten → Auren wählbar. Beim ersten Kampf mit einem Ziel schreibt WeintCodex einmal eine kurze Auren-Prüfung in den Chat – ein Screenshot davon hilft bei der Fehlersuche.

**Der Chat ist eine ruhige Fläche.** Reiterzeile oben mit feiner Linie, die Reiter bleiben sichtbar, die Knöpfe des Spiels stehen klein rechts in der Reiterzeile, die Eingabezeile sitzt bündig darunter.

**Die Schadensanzeige kann mehr.** Klassensymbole, Anteil in Prozent, deine eigene Zeile immer sichtbar und markiert, Maus über einer Zeile zeigt die Zauber dieses Spielers, und der Zeitraum schaltet auch auf frühere Kämpfe. Die unsinnige Kampfdauer („70889:57“) ist weg.

**Rahmen verschieben im Gestaltungsmodus.** Das Einstellungsfenster schließt sich von selbst, oben erscheint eine Leiste mit Testdaten, Raster, Einrasten, Zurücksetzen und „Fertig“. Rahmen anklicken, mit den Pfeiltasten genau schieben (Umschalt: 8), Doppelklick öffnet seine Einstellungen, Esc beendet – und das Fenster ist wieder da.

**Aktionsleisten ohne leere Kästen.** Leere Plätze sind weg und erscheinen nur, wenn du einen Zauber ziehst. Flache Hervorhebung, ein leichter Schatten am Symbol, die Abklingzahl in der WeintCodex-Schrift, kein Reichweitenpunkt mehr.

### Technisch

- Einheitenrahmen: `RefreshUnit` zeichnet, sobald die Einheit existiert
  (nicht erst, wenn der Rahmen sichtbar ist), und `OnShow` zeichnet noch
  einmal. Ursache des weißen Zielrahmens: UnitWatch zeigt den Rahmen erst
  nach `PLAYER_TARGET_CHANGED`.
- Plaketten: `auraSource` (`game` Standard, `own`). `game` hängt
  `UnitFrame.AurasFrame` (bzw. `BuffFrame`) der Plakette des Spiels an
  unsere, meldet am UnitFrame nur `UNIT_AURA` wieder an, holt den Rahmen
  per Haken zurück, wenn das Spiel Anker oder Elternrahmen neu setzt, und
  gibt ihn beim Freigeben mit den ursprünglichen Ankern zurück.
  `gameAuraScale`. `UIAuras.AUTO_REPORT`: einmal je Sitzung vier
  Sekunden nach Kampfbeginn mit Ziel die Zeilen von `/wcui auren`
  (solange der Container-Weg nicht bestätigt ist); jetzt mit der
  Plakette des Ziels. **Im Spiel ungeprüft.**
- Chat: Kachel über Reiter und Text (Grund, Reiterzeile, Linie, Rand,
  Schatten), `buttons = "tabrow"`, `tabsVisible` setzt
  `CHAT_FRAME_TAB_*_NOMOUSE_ALPHA`, Eingabezeile bündig.
- Schadensanzeige: `classIcons` (`CLASS_ICON_TCOORDS`), `showPercent`
  (nur offene Zahlen; Summe vom Client oder selbst gezählt), `pinSelf`
  (`isLocalPlayer`/GUID), Tooltip mit `GetCombatSessionSourceFromType/
  FromID` → `combatSpells`, Zeitraum über `GetAvailableCombatSessions`
  (`GetCombatSessionFromID`), Kampfdauer nur unter sechs Stunden.
- Gestaltungsmodus (`ui/editmode.lua`): Leiste, Raster, Einrasten
  (`UIKit.SnapOffset`), Auswahl, `UIKit.NudgeMover`, Doppelklick →
  Einstellungsseite, Esc; Fenster zu und wieder auf.
- Aktionsleisten: `emptySlots` (ausblenden, beim Ziehen über
  `ACTIONBAR_SHOWGRID` sichtbar), `iconShade`, Hervorhebung/gedrückt/
  aktiv flach, `cooldownFont` (`SetCountdownFont`), `hideRangeDot`.
- `load_test.lua`: alle sechs Punkte.

## [6.2.0.0] – 2026-09-24

UI 2.0, Phase 2: das Cockpit – und ein neuer Anlauf bei den Debuffs.

**Debuffs: WeintCodex hilft sich jetzt selbst.** Nennt das Spiel Auren am Gegner und die Symbole erscheinen trotzdem nicht, liest WeintCodex sie selbst und sagt es einmal im Chat. /wcui auren zeigt mit einem Gegner als Ziel, was das Spiel meldet und was davon zu sehen ist; unter Namensplaketten → Auren lässt sich der Weg auch von Hand wählen.

**Spieler- und Zielrahmen reagieren wie die Plaketten.** Die Maus hellt sie auf, fehlendes Leben ist dunkel in der Balkenfarbe, und die Stufe des Ziels steht in der Farbe ihrer Schwierigkeit, Elite mit „+“. Ein Porträt ohne Modell zeigt das Bild statt eines schwarzen Kästchens.

**Kombopunkte als fünf einzelne Segmente** mittig unter der Figur.

**Kurze Tastenkürzel auf den Aktionsknöpfen:** „M4“ statt „Maustaste 4“, „S1“ statt „s-1“.

**Die Schadensanzeige ist so hoch wie ihr Inhalt.** Keine leere schwarze Fläche mehr unter einer einzigen Zeile.

**Hinrichtungsmarke auf Wunsch:** ein fester Strich im Plakettenbalken zeigt, ab wann Hinrichten wirkt (Namensplaketten → Allgemein).

### Technisch

- Auren: Der Container war 1 × 1 groß – ordnet oder beschneidet er seine
  Symbole innerhalb seiner Fläche, blieb kein Platz. Jetzt so groß wie
  alle Symbole zusammen, `SetClipsChildren(false)`. Weg umschaltbar im
  laufenden Spiel (`UIAuras.SetMode`: auto / engine / legacy).
  Selbstheilung in „Automatisch“: nennt `GetAuraDataByIndex` Auren (nur
  gezählt, kein Feld gelesen) und der Container zeigt 0,6 s später keine,
  wird für alle Objekte auf den alten Weg umgebaut und einmal gemeldet.
  `/wcui auren`: Weg, Zustand, was das Spiel am Ziel nennt, und je
  Objekt angelegte/gezeigte Symbole und Rahmengröße. **Im Spiel
  ungeprüft.**
- Kombopunkte: fünf Balken mit Bereich i-1..i, alle mit demselben Stand –
  kein Vergleich mit einem geheimen Wert.
- Einheitenrahmen: `tintedBg`, `hover`, Stufe über `LevelParts`
  (Schwierigkeitsfarbe, `+` für Elite, `??` unbekannt); 3D-Porträt setzt
  die Kamera bei `OnModelLoaded` und fällt ohne Modelldatei auf das Bild
  zurück.
- Aktionsleisten: `AB.ShortHotkey`, Haken an `UpdateHotkeys`.
- Schadensanzeige: `fitRows`.
- Plaketten: `executeMark`/`executeAt` (fester Strich, keine Rechnung mit
  dem Leben).
- `load_test.lua`: Kombosegmente, Stufe, Tastenkürzel, Höhe der
  Schadensanzeige, Hinrichtungsmarke, Auren-Weg und Selbstheilung. Die
  Attrappe merkt sich Bereich und Stand von Balken.

## [6.1.0.0] – 2026-09-24

UI 2.0, erster Teil: das Fundament aus dem neuen Konzept
(`docs/design/ui-2.0.md`) und die neuen Namensplaketten.

**Die Oberfläche hat ein neues Gesicht.** Balken mit leichtem Glanz,
weiche Schatten statt harter Kanten und eine schmale Schrift, die Namen
und Zahlen mehr Platz lässt.

**Namensplaketten, die auf dich reagieren.** Die Maus hellt eine
Plakette auf, dein Ziel leuchtet und trägt Marken links und rechts, alle
anderen treten zurück. Fehlendes Leben ist dunkel in der Farbe des
Gegners statt schwarz.

**Spieler und Ziel stehen spiegelbildlich um die Bildschirmmitte.**
Kombopunkte und dein Zauberbalken liegen mittig darunter, die Gruppe
links neben dir, die Schadensanzeige unten rechts.

**Außerhalb des Kampfes wird es ruhig.** Ohne Ziel und bei vollem Leben
treten Spielerrahmen und Leisten zurück. Ein Ziel, ein Treffer oder die
Maus holen sie sofort zurück – einstellbar unter /wcui, Reiter „Ruhe und
Kampf“.

**Testmodus: alles auf einen Blick.** /wcui test zeigt Ziel, Fokus, eine
Beispielgruppe, Zauberbalken und Schadensanzeige mit Beispielwerten –
ohne Gruppe und ohne Kampf.

### Technisch

- Konzept und Entwurf der Neugestaltung: `docs/design/ui-2.0.md`.
- Stil: `UIKit.NewBar` (Glanztextur `media/ui/bar`, Lichtkante,
  Stilwechsel erreicht alle Balken), `UIKit.Glow` (Neunteiler aus
  `media/ui/glow`/`glow_wide`, ohne `SetTextureSliceMargins` aus),
  `UIKit.Kachel`; Schalter „Weiche Schatten“. Neue Farbwerte nur in
  `core/ui.lua` (`GameColors.shadow`, `targetGlow`, `hoverFill` …).
- Schrift: IBM Plex Sans Condensed (OFL) als `Fonts.hud*`, Standard der
  Spielwelt; die breite Plex bleibt wählbar.
- Plaketten: 150 × 14, `targetStyle` (Leuchten und Marken / Rand /
  beides / nichts) statt `targetRing`, `hover` über
  `UPDATE_MOUSEOVER_UNIT` mit Takt nur während einer Hervorhebung,
  `tintedBg`, `shadow`; `nonTargetAlpha` 70, `targetScale` 110.
- `ui/layout.lua`: alle Standardpositionen an einer Stelle
  (`UIKit.Layout`); Einheitenrahmen 200 × 31, eigene Plätze für
  Kombopunkte und eigenen Zauberbalken.
- `ui/presence.lua`: Ruhe/Bereit/Kampf, nur `SetAlpha`; Spieler,
  Aktionsleisten, Schadensanzeige angemeldet.
- `ui/testmode.lua`: Beispieldaten mit Band und „Beispiel“ in der
  Schadensanzeige; endet bei Kampfbeginn.
- `load_test.lua`: Cockpit spiegelbildlich, Stil 2.0, Plaketten 2.0
  (Ziel, Maus, 70 %), Ruhe/Kampf, Testmodus. Die Attrappe merkt sich
  `SetAlpha`. **Nichts davon ist im Spiel geprüft.**

## [6.0.0.6] – 2026-09-24

Dritter Test im Beta-Client.

**Debuffs auf Namensplaketten und am Zielrahmen sollten jetzt
erscheinen.** Bisher blieben sie unsichtbar. Klappt es noch nicht,
meldet WeintCodex im Chat einmal, woran es scheitert – unter /wcui →
Namensplaketten → Auren steht dasselbe.

**Die Questliste ohne goldenes Banner.** Kopfzeilen hell in der Schrift
von WeintCodex, dahinter die dunkle Fläche.

**Chatreiter lesbar.** Die Namen werden nicht mehr abgeschnitten, der
aktive Reiter ist hell und unterstrichen.

**Der Questpfeil steht ganz oben.** Er lag mitten in den roten
Fehlermeldungen des Spiels.

**Aufgeräumte Minikarte.** Tageszeit-Symbol und WeintCodex-Knopf stehen
mit den anderen Knöpfen in der Spalte links, statt auf der Karte zu
liegen.

**Energie ist gelb.** Die Kraftleiste nahm bei manchen Klassen die
falsche Farbe. Leere Aktionsplätze sind nur noch angedeutet.

### Technisch

- Auren: Im Spiel erschienen weder auf Plaketten noch am Zielrahmen
  Symbole; die Ursache war von außen nicht zu sehen, weil jeder Schritt
  in `pcall` lief. Wahrscheinlichster Grund (nach EllesmereUI): der
  Container bekam seinen Anker erst nach `AddAuraGroup`, das Spiel
  arbeitet Auren aber nur für einen zeichenbaren Rahmen ab. Jetzt
  `SetPoint` vor der ersten Gruppe; scheitert `AddAuraGroup`, folgt ein
  vereinfachter Versuch; jeder erste Fehlschlag je Schritt geht einmal
  in den Chat und steht in `UIAuras.StatusText()` (Seite „Auren“).
  Plaketten filtern mit `INCLUDE_NAME_PLATE_ONLY` wie Blizzard.
  `load_test.lua` stellt den Container jetzt nach: `initializeFrame`
  läuft, Anker vor der Gruppe, Fehlschlag gemeldet. **Im Spiel ungeprüft.**
- Questliste: alle Texturen der Kopfzeilen über `GetRegions()` statt
  einer mit geratenem Namen; Kopfzeilen in der WeintCodex-Schrift.
- Chat: Reiterschrift bleibt die des Spiels (es misst die Breite daran).
- Minikarte: Knöpfe der Spalte melden fremdes `SetPoint` (Haken), dann
  wird neu geordnet; `LibDBIcon10_WeintCodex` gehört dazu.
- Questpfeil: Standardplatz oben (`y = -8`) statt in `UIErrorsFrame`.
- Kraftfarbe über den Namen **und** die Nummer der Kraftart
  (Einheiten- und Gruppenrahmen). Leere Aktionsplätze mit 35 % Rand und
  15 % Grund (`HasAction`).

## [6.0.0.5] – 2026-09-24

Zweiter Test im Beta-Client, und der Abgleich mit EllesmereUI.

**Keine Fehlermeldung „Font not set“ mehr beim Angreifen.** Sie kam, wenn
ein Gegner schon zauberte, während seine Namensplakette erschien.

**Der Questpfeil ist dreidimensional und zeigt mit der Farbe, wie gut du
liegst.** Grün geradeaus, gelb quer, rot in die falsche Richtung. Als
Geist zeigt er von selbst zu deiner Leiche, und nach dem Abgeben wählt
er die nächstgelegene Quest aus deinem Questlog – wenn du willst, schon
sobald die Ziele erfüllt sind.

**Die Schadensanzeige kann bis zu vier Fenster.** Jedes mit eigener
Messart und eigenem Zeitraum, dazu Kampfdauer in der Kopfzeile und
Knöpfe für neues Fenster, Leeren und Einstellungen. Pro Sekunde steht
jetzt eine runde Zahl statt vieler Nachkommastellen.

**Namensplaketten zeigen deinen Questfortschritt und die Restzeit deiner
Debuffs.** Gehört ein Gegner zu einer deiner Quests, steht links vom
Namen, wie weit du bist, etwa „8/10“. Über jedem Debuff-Symbol stehen
die verbleibenden Sekunden.

**Spieler, Ziel und Fokus zeigen ein Porträt.** Als 3D-Modell oder Bild,
einstellbar je Rahmen; beim Ziel rechts, gespiegelt zum Spieler.

**Minikarte und Chat aufgeräumt.** Koordinaten und Uhrzeit oben in der
Karte, das Gebiet unten; die Knöpfe des Spiels stehen bei Karte und Chat
in einer Spalte am Rand. Der aktive Chatreiter ist hell und
unterstrichen.

**Mikromenü unten links, Taschenleiste unten rechts, die Questliste auf
eigener Fläche.** Jeweils abschaltbar, wenn du die Anordnung des Spiels
behalten willst.

### Technisch

- „Font not set“ (7x, BugGrabber mit geheimem Stack): `ui/nameplates.lua`
  verband in `Attach` den Zauberbalken (`p.cast:SetUnit`) vor `Layout`;
  zaubert der Gegner schon, schrieb der Balken Text ohne Schrift. Die
  Klasse ist geschlossen: `UIKit.NewText` setzt die Schrift beim
  Anlegen, `load_test.lua` verbietet `CreateFontString` außerhalb von
  `ui/kit.lua`, und `UIKit.SetFont` fällt bei `false` auf die Schrift
  des Spiels zurück.
- Questpfeil: `media/ui/arrow3d.tga` (8×8 Ansichten, 512×512, erzeugt
  von `.github/scripts/make_ui_media.py` – kleiner Rasterer ohne
  Bibliothek), `QA.Frame`, `QA.CourseColor`, `QA.NearestQuest`;
  Leiche über `C_DeathInfo.GetCorpseMapPosition` (eigene Karte und
  Elternkarten), nächste Quest über `C_SuperTrack.SetSuperTrackedQuestID`
  nach `QUEST_TURNED_IN`/`QUEST_REMOVED`.
- Schadensanzeige neu geschrieben: bis zu vier Fenster, flach
  gespeichert (`w1mode` … `w4session`), `CreateAbbreviateConfig` für
  runde Zahlen, `GetSessionDurationSeconds` für die Kampfdauer, eigene
  Symbole `media/ui/icon_*.tga`.
- Plaketten: Questfortschritt aus `C_TooltipInfo.GetUnit` (Zeilen
  `QuestTitle`/`QuestObjective`, nur Quests aus dem eigenen Log über
  `C_QuestLog.IsOnQuest`, geheime Werte = unbekannt, ohne lesbaren Stand
  ein „!“ statt einer geratenen Zahl, nicht in Instanzen, je Einheit
  zwischengespeichert bis `QUEST_LOG_UPDATE`). Symbole 24 px mit
  Restzeit: `ui/auras.lua` registriert im Engine-Weg
  `SetDurationText` (das Spiel zählt, auch geheime Werte), im alten Weg
  ein Takt je Objekt.
- Neu: `ui/questtracker.lua` (Fläche hinter `ObjectiveTrackerFrame`,
  Höhe aus der untersten sichtbaren Zeile). Einheitenrahmen mit Porträt
  (`PlayerModel` bzw. `SetPortraitTexture`), Spieler- und Zielrahmen
  220 px breit. Mikromenü/Taschenleiste in `ui/actionbars.lua`, gesetzt
  nach `ApplySystemAnchor`/`ExitEditMode`, nie im Kampf – auf Forever
  ungeprüft, ob das den Bearbeitungsmodus unberührt lässt.

## [6.0.0.4] – 2026-09-24

Erster Test der Oberfläche im Beta-Client, und was dabei zerbrach.

**Gruppen- und Schlachtzugsrahmen erscheinen.** Beim Einloggen brach ihr
Aufbau mit einer Fehlermeldung ab.

**Die Schadensanzeige öffnet sich.** Ihr Fenster brach beim Aufbau ab,
und im Chat stand eine Fehlermeldung.

**Die Taschen zeigen ihre Gegenstände.** Die Plätze standen da, aber
leer. Unten im Fenster steht jetzt, wie viele Plätze belegt sind.

**Der Chat bekommt seinen Stil wirklich.** Sein Umbau brach beim Start
ab; die Knöpfe am Rand und die Rahmen der Reiter blieben stehen.

**Über der Minikarte stehen Gebiet und Uhrzeit nur noch einmal.** Die
Kopfleiste des Spiels verschwindet, solange die eigenen Texte an sind.

### Technisch

Drei Fehlerklassen, die die Client-Attrappe durchgelassen hat und die
sie jetzt ablehnt wie der Client:

- `SetText`/`SetFormattedText` auf einem FontString ohne Schrift
  („Font not set“). Daran scheiterte der Aufbau der Schadensanzeige
  (`ui/damagemeter.lua`); dieselbe Lücke hatten die Gruppenknöpfe.
- `Show()` eines `SecureGroupHeaderTemplate` ohne Attribut `point`
  (`SecureGroupHeaders.lua:79`, gemeldet aus dem Beta-Client).
  `ui/groupframes.lua` setzt die Anordnung jetzt vor dem ersten `Show()`.
- `CreateTexture`/`CreateFontString` auf einer Textur. `ui/chat.lua`
  hängte den Rand der Eingabezeile an eine Textur.

Taschen: Die Symbolmaske der Vorlage wird abgenommen und das Symbol auf
den ganzen Knopf gezogen, Knopf und Symbol werden ausdrücklich gezeigt
(wie in EllesmereUI). Ob das die leeren Plätze behebt, ist im Spiel
nicht geprüft; die Zeile „X von Y Plätzen belegt“ zeigt beim nächsten
Test, ob der Client die Gegenstände liefert. Chat: Knöpfe am Rand und
Knopfleiste werden über `UIKit.HideBlizzard` versteckt statt
durchsichtig gemacht (das Spiel blendet sie selbst wieder ein);
Reiter-Texturen werden über `GetRegions()` gefunden statt über Namen.
Gruppenrahmen: Nach jeder Gruppenänderung werden noch nicht
eingerichtete Knöpfe außerhalb des Kampfes nachgezogen – ob der
Kopfrahmen allein beim Anmelden wirklich alle Knöpfe auf Vorrat anlegt,
ist nicht geprüft. `p.friendly` auf Plaketten heißt jetzt `p._friendly` (Attrappen-Regel
für eigene Felder).

## [6.0.0.3] – 2026-09-24

**Die WeintCodex-Oberfläche ist jetzt für alle eingeschaltet.** Der
Forever-Client speichert Addon-Einstellungen derzeit nicht über ein
Neuladen hinweg – eine Wahl „an“ oder „aus“ wäre danach vergessen.
Sobald er wieder speichert, wird sie wieder freiwillig. Einzelne Teile
schaltest du mit `/wcui` ab.

**Gruppen- und Schlachtzugsrahmen im Stil von WeintCodex.** Klassenfarbe,
Name, Leben in Prozent oder fehlendes Leben, abgeblendet außer
Reichweite, roter Rand bei Aggro und die Debuffs, die du bannen kannst.

**Debuffs über gegnerischen Plaketten, und freundliche Plaketten.** Deine
Debuffs stehen über dem Gegner; Freunde zeigen ihren Namen in
Klassenfarbe. In Dungeons und Schlachtzügen bleiben die freundlichen
Plaketten die des Spiels – das Spiel sperrt sie dort für Addons.

**Aktionsleisten, Minikarte und Chat im Stil von WeintCodex.** Flache
Knöpfe mit feinem Rand und roter Schicht außer Reichweite; eine eckige
Minikarte mit Mausrad-Zoom, Koordinaten und Uhrzeit; Chatfenster mit
eigener Schrift, ruhigem Hintergrund und schlichter Eingabezeile.

**Alle Taschen in einem Fenster.** Suche, Sortieren, Gold,
Gegenstandsstufe auf Ausrüstung und Rand in Qualitätsfarbe. Benutzen,
Anlegen und Verkaufen funktionieren wie gewohnt.

**Eine Schadensanzeige.** Schaden, Heilung, erlittener Schaden,
Unterbrechungen, Bannungen und Tode, für den laufenden Kampf oder die
ganze Sitzung – gemessen vom Spiel selbst.

**Optionen, die von Haus aus an sind, lassen sich jetzt ausschalten.**
Vorher sprangen sie beim nächsten Lesen wieder auf „an“.

### Technisch

`UIKit.OPT_IN = false` (`ui/kit.lua`): `UIEnabled()` ist immer wahr, die
Frage beim Einloggen ruht, der Hauptschalter wird zum Hinweis; eine
Zeile zurück auf `true` stellt alles wieder her (`load_test.lua` prüft
beide Zustände). Neue Module: `ui/auras.lua` (Auren-Container des
Spiels, sonst `GetAuraDataByIndex`), `ui/groupframes.lua`
(`SecureGroupHeaderTemplate` ohne Secure Snippets: alle Knöpfe per
`startingIndex` beim Anmelden angelegt, außerhalb des Kampfes
eingerichtet), `ui/actionbars.lua` (Blizzard-Knöpfe umgestaltet, keine
eigenen Leisten), `ui/minimap.lua`, `ui/chat.lua` (keine veränderten
Nachrichten – geheime Chatzeilen), `ui/bags.lua`
(`ContainerFrameItemButtonTemplate`, Vorrat von 180 außerhalb des
Kampfes, Öffnen über Haken an `Show`/`Hide` der Blizzard-Taschen),
`ui/damagemeter.lua` (`C_DamageMeter`, `damageMeterEnabled = 0`).
Nameplates: freundliche Plaketten (nicht in gesperrten Instanzen) und
Debuffs; Zielauren im Einheitenrahmen laufen über `ui/auras.lua`;
`UIKit.HideBlizzard` ist jetzt gemeinsam. Fehler behoben:
`UIKit.Set` speicherte `false` nie (`x and false or nil`),
`UIKit.SetFont` stürzte an einem Feld ab, das keine Schriftzeile ist.
Nichts davon ist im echten Client geprüft.

## [6.0.0.2] – 2026-09-24

**Die Frage zur WeintCodex-Oberfläche kommt nach einem Neuladen nicht
mehr wieder.** Sie erscheint nur noch beim Einloggen. Vorher konnte sie
nach „Ja, verwenden“ und „Jetzt neu laden“ in einer Schleife
wiederkehren.

**WeintCodex sagt dir, wenn der Client nicht gespeichert hat.** Die
Forever-Beta speichert Addon-Einstellungen beim Neuladen nicht immer.
Passiert das, steht es im Chat – und unter Einstellungen → Diagnose
steht, ob das letzte Neuladen gespeichert hat.

### Technisch

Ursache der Schleife: Der Beta-Client hatte `WeintCodex_SavedData`
beim Neuladen nicht geschrieben (Antwort und Hauptschalter fehlten
danach beide); im Addon selbst verwirft nichts diese Werte.
`ui/welcome.lua` fragt nach `PLAYER_ENTERING_WORLD` mit
`isReloadingUi` nicht mehr automatisch. Der erste Versuch dieser Sperre
war wirkungslos (ein `local` unterhalb der Funktion, die ihn liest – dort
eine immer leere globale Variable); `load_test.lua` prüft jetzt per
`luac -l` jede Datei unter `ui/` auf versehentliche Globale.
`core/main.lua`: `WeintCodex.SaveHealth()` aus einem Zeitstempel, den
`PLAYER_LOGOUT` schreibt (`ok`/`failed`/`unknown`).

## [6.0.0.1] – 2026-09-24

**„Jetzt neu laden“ funktioniert auf Forever.** Der Knopf nach der Frage
zur WeintCodex-Oberfläche und der im Einstellungsfenster meldeten
vorher nur, dass eine geschützte Funktion blockiert wurde – jetzt laden
sie neu.

**Auch „Synchronisation starten“ und „Anmeldungen abrufen“ laden wieder
neu.** Beide Knöpfe hatten denselben Fehler.

### Technisch

Neuladen ist auf Forever für Addons geschützt: `ReloadUI()` bzw.
`C_UI.Reload()` aus Lua endet in `ADDON_ACTION_BLOCKED` (im Beta-Client
gemeldet). Alle fünf Neuladeknöpfe gehen jetzt über
`WeintCodex.AttachReload` (`core/ui.lua`): ein unsichtbarer
`InsecureActionButton` über dem sichtbaren Knopf führt das Makro
`/reload` aus, ausgelöst vom Klick selbst; im Kampf wird er erst danach
scharf und verweist bis dahin auf `/reload`. `UIOptions.ReloadNow`
entfällt. `load_test.lua` schlägt bei jedem direkten Aufruf von
`ReloadUI`/`C_UI.Reload` in `core/`, `modules/` und `ui/` an.

## [6.0.0.0] – 2026-09-24

**WeintCodex bringt jetzt ein eigenes Interface mit – ganz freiwillig.**
Namensplaketten und Einheitenrahmen im Stil von WeintCodex,
einstellbar in einem eigenen Fenster (`/wcui`, oder `/wc ui`). Beim
ersten Einloggen fragt WeintCodex, ob du es verwenden möchtest. Bei
„Nein“ bleibt alles, wie das Spiel es zeigt, und du kannst es jederzeit
in den Einstellungen von WeintCodex unter „Oberfläche“ nachholen.

**Gegnerische Namensplaketten zeigen auf einen Blick, woran du bist.**
Farbe nach Lage (im Kampf, noch nicht im Kampf, neutral, von anderen
markiert, Boss, Elite), die Stufe links, das Leben rechts, dazu ein
Zauberbalken, der zeigt, ob sich der Zauber unterbrechen lässt, und ein
Rahmen um dein Ziel. Jeder Textplatz ist frei belegbar; eine Vorschau im
Einstellungsfenster zeigt jede Änderung sofort.

**Spieler, Ziel, Ziel des Ziels, Fokus und Begleiter bekommen schlichte
Rahmen.** Mit Zauberbalken, den Buffs und Debuffs deines Ziels und
Kombopunkten für Schurken und Druiden in Katzengestalt. Mit „Rahmen
entsperren“ ziehst du alles an seinen Platz; Rechtsklick setzt zurück.

**Ein Questpfeil zeigt dir den Weg zur ausgewählten Quest.** Wähle eine
Quest im Questlog oder setze eine Kartenmarkierung – der Pfeil zeigt die
Richtung, darunter stehen Entfernung und ungefähre Ankunftszeit. „m“ ist
dabei dieselbe Einheit, die das Spiel bei Zauberreichweiten „Meter“
nennt; echte Meter oder Yards lassen sich einstellen. In Dungeons steht
„Position unbekannt“, weil das Spiel dort keine Position nennt. Der Pfeil
funktioniert auch ohne das neue Interface (`/wc pfeil`).

**Kleine Helfer für den Alltag, jeder einzeln zuschaltbar.** Automatisch
reparieren (wahlweise aus der Gildenbank), graue Gegenstände verkaufen,
schneller plündern, Löschbestätigung ausfüllen, Filmsequenzen
überspringen, Fehlermeldungen im Kampf ausblenden, Kampfhinweis,
Bildrate, Haltbarkeitswarnung und Koordinaten auf der Weltkarte. Alle
sind von Haus aus aus, und keiner hängt am neuen Interface.

**WeintCodex erkennt den Forever-Client unter einer weiteren Kennung.**
Damit sollte das Addon in der Addon-Liste nicht mehr als „veraltet“
erscheinen.

### Technisch

Neuer Ordner `ui/` (lädt nach `modules/`): `kit.lua` (Speicher unter
`WeintCodex_SavedData.ui`, nur Abweichungen vom Standard; Modulregister;
Hauptschalter; Kampfsperre; Verschieben), `castbar.lua`, `nameplates.lua`,
`unitframes.lua`, `questarrow.lua`, `comfort.lua`, `options.lua`,
`welcome.lua`. Aufbau, Optionsnamen und Voreinstellungen folgen
EllesmereUI 9.2.6 – **kein Code und keine Grafik daraus** (Lizenz „all
rights reserved“); der Questpfeil entsteht aus
`.github/scripts/make_ui_media.py`. Werte des 12.x-Clients werden als
möglicherweise geheim behandelt (`type(x) == "nil"`, kein `a or b`,
`SetFormattedText`, Dauerobjekte für Zauberbalken). Neu in
`core/ui.lua`: `CreateDropdown`, `CreateColorSwatch`,
`WeintCodex.GameColors`. `## Interface` nennt zusätzlich `16001`.
`load_test.lua` baut jede Einstellungsseite, lässt Plaketten,
Einheitenrahmen und Komfortfunktionen gegen die Attrappe laufen, rechnet
die Geometrie des Questpfeils nach und spielt die Frage beim Einloggen
in beiden Antworten durch. Nichts davon ist im echten Client geprüft.
Details: `docs/systems/ui.md`.

## [5.2.1.1] – 2026-09-23

**Das Update ist jetzt kleiner.** Die Dungeon-Bilder sparen sich
unnötige, nie angezeigte Zusatzstufen für Distanzansichten, die eine
UI-Kachel fester Größe ohnehin nie anfordert. An der Darstellung
ändert sich nichts.

### Technisch

`.github/scripts/make_artwork.py` schreibt BLP2/DXT1 jetzt ohne
Mipmap-Kette (nur Stufe 0, `hasMips = 0`); die 49 bestehenden Dateien
unter `media/dungeons/` und `media/logo.blp` wurden entsprechend neu
gepackt, Stufe 0 bytegleich zum Original. Ausserdem schliessen beide
Release-Workflows `graphify-out/` (generierte Wissensgraph-Reports)
und die ungenutzten `media/logo.png`/`media/logo.blp` vom Addon-ZIP
aus – zusammen gut 10 MB, die nie zum Client gehörten.

## [5.2.1.0] – 2026-09-23

**Vier weitere klassische Dungeons bekommen ihr eigenes Gesicht.** Ruins of
Lordaeron, Wailing Caverns, The Deadmines und Shadowfang Keep zeigen jeweils
ein eigenes Header-Artwork und individuell bebilderte Bosskarten.

**Das Artwork-System wächst weiter.** Neue Dungeons werden über dieselbe
zentrale Struktur eingebunden, ohne eigene UI-Sonderlogik pro Dungeon.

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
