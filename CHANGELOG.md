# Changelog

Alle nennenswerten Änderungen an **WeintCodex — Forever Edition** werden hier
festgehalten. Format lose an [Keep a Changelog](https://keepachangelog.com/)
angelehnt; Versionsnummern folgen dem 4-teiligen Schema
(`MAJOR.MINOR.PATCH.BUILD`), nicht SemVer.

Die Fassung für *Mists of Pandaria Classic* (`daddler/WeintCodex`) hat ihren
eigenen Changelog und ihren eigenen Update-Kanal. Die beiden Zweige laufen
nicht zusammen.

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
