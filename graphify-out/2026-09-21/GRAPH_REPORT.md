# Graph Report - Codex-Forever  (2026-09-21)

## Corpus Check
- 54 files · ~145,892 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 30 file(s) not represented in the graph (top: .tga 12, .ttf 10, (none) 3)

## Summary
- 788 nodes · 1616 edges · 34 communities (25 shown, 9 thin omitted)
- Extraction: 76% EXTRACTED · 24% INFERRED · 0% AMBIGUOUS · INFERRED: 388 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `a6f1e040`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- navigation.lua
- dungeonpages.lua
- access.lua
- ui.lua
- calendar.lua
- encounter_tracking.lua
- settings.lua
- WeintCodex.ColorText
- charakter.lua
- BuildTree
- companion.lua
- groupcheck.lua
- release_notes.py
- search.lua
- load_test.lua
- loot.lua
- NewObject
- data_test.lua
- Dungeons und Rollen
- Schlachtzüge, Bosse und Fortschritt
- Oberfläche: Aufbau und Designsprache „Graphit"
- Changelog
- Die Einführung
- updatePosition
- getAnchors

## God Nodes (most connected - your core abstractions)
1. `WeintCodex.ColorText()` - 32 edges
2. `WeintCodex.ShowHome()` - 31 edges
3. `WeintCodex.Navigation.SetInspector()` - 25 edges
4. `WeintCodex.Access.Can()` - 20 edges
5. `WeintCodex.Navigation.SwitchTo()` - 20 edges
6. `CreateCalendarFrame()` - 20 edges
7. `WeintCodex.Eyebrow()` - 17 edges
8. `BuildTree()` - 17 edges
9. `WeintCodex.Access.Print()` - 16 edges
10. `Col()` - 16 edges

## Surprising Connections (you probably didn't know these)
- `Technisch` --references--> `BuildColumn()`  [INFERRED]
  CHANGELOG.md → core/navigation.lua
- `Critical invariants (always relevant, keep in mind for any change)` --references--> `Spaced()`  [INFERRED]
  CLAUDE.md → core/ui.lua
- `Die Ausrüstungsplätze kommen vom Client` --references--> `EquipSlots()`  [INFERRED]
  docs/systems/character.md → modules/charakter.lua
- `Die Bausteine` --references--> `EquipSlots()`  [INFERRED]
  docs/systems/groupcheck.md → modules/charakter.lua
- `Die Spezialisierung (`data/specs.lua`, `modules/charakter.lua`)` --references--> `CurrentSpec()`  [INFERRED]
  docs/invariants/data-integrity.md → modules/charakter.lua

## Import Cycles
- None detected.

## Communities (34 total, 9 thin omitted)

### Community 0 - "navigation.lua"
Cohesion: 0.05
Nodes (70): ApplyItemDisplay(), BuildColumn(), BuildStrip(), Can(), ClearContentPanel(), CreateItemRow(), DateKey(), Ellipsis() (+62 more)

### Community 1 - "dungeonpages.lua"
Cohesion: 0.06
Nodes (60): WeintCodex.CreateSurface(), WeintCodex.Eyebrow(), WeintCodex.PageHead(), WeintCodex.Paragraph(), WeintCodex.ShowExportDialog(), D.AllInstances(), D.AllSummonable(), D.BossesInWing() (+52 more)

### Community 3 - "access.lua"
Cohesion: 0.12
Nodes (44): CopyFeatures(), CopyStrings(), EnsureBadge(), Mark(), NormalizeId(), Row(), Say(), Stamp() (+36 more)

### Community 4 - "ui.lua"
Cohesion: 0.07
Nodes (38): Critical invariants (always relevant, keep in mind for any change), Development workflow, Role in the ecosystem, Task routing — read only what the task needs, What this edition deliberately does not have, What this is, ApplySavedWindow(), ApplyVerticalGradient() (+30 more)

### Community 5 - "calendar.lua"
Cohesion: 0.09
Nodes (42): WeintCodex.Names.Equal(), WeintCodex.Names.Match(), WeintCodex.Names.Normalize(), WeintCodex.Names.Split(), WeintCodex.Navigation.ActivateFirst(), AddPlayers(), AlternateInviteName(), CreateCalendarFrame() (+34 more)

### Community 7 - "encounter_tracking.lua"
Cohesion: 0.08
Nodes (31): Datenintegrität: `unknown` ist nicht `0`, Der Ausrüstungsstand an die Companion (`modules/companion.lua`), Der vierte Zustand ist mit 5.1.0.0 dazugekommen, Die Ausrüstung (`modules/charakter.lua`), Die Bosslisten (`data/raids.lua`, `data/dungeons.lua`), Die Client-Aufrufe, Die Materialien (`modules/materials.lua`), Die Regel (+23 more)

### Community 8 - "settings.lua"
Cohesion: 0.14
Nodes (26): GetDB(), ToggleAddon(), WeintCodex.Minimap.IsShown(), WeintCodex.Minimap.SetShown(), WeintCodex.Navigation.CurrentTab(), WeintCodex.CreateScrollArea(), WeintCodex.CreateSlider(), Buttons() (+18 more)

### Community 9 - "WeintCodex.ColorText"
Cohesion: 0.13
Nodes (29): A(), AddButton(), BuildVisibleSteps(), ClearButtons(), CollectChangelogSince(), CreateButton(), Dismiss(), E() (+21 more)

### Community 10 - "charakter.lua"
Cohesion: 0.11
Nodes (32): WeintCodex.CreateToggle(), WeintCodex.Label(), WeintCodex.Specs.ByIndex(), WeintCodex.Specs.ByName(), WeintCodex.Specs.ForClass(), WeintCodex.Specs.Key(), Die Spezialisierung (`data/specs.lua`, `modules/charakter.lua`), Charakter: Ausrüstung und Twinks (+24 more)

### Community 11 - "BuildTree"
Cohesion: 0.13
Nodes (33): WeintCodex.Names.ClassLabel(), WeintCodex.RaidData.BossSourceLabel(), WeintCodex.RaidData.Get(), TipsAllowed(), WeintCodex.Roles.Frame(), WeintCodex.Roles.FrameLabel(), WeintCodex.Roles.HasTips(), WeintCodex.Roles.Label() (+25 more)

### Community 12 - "companion.lua"
Cohesion: 0.11
Nodes (31): WeintCodex.Access.Init(), OnEvent(), WeintCodex.Names.Me(), `character_sheet` — was leer bleibt, und warum, Die Companion-Brücke, Die Reihenfolge in `ProcessQueue`, Die Seite *Companion*, Versionssperren (+23 more)

### Community 13 - "groupcheck.lua"
Cohesion: 0.12
Nodes (26): Der Gruppencheck (`modules/groupcheck.lua`), Bedienung, Die Schlange läuft einzeln, Drei Regeln, die nicht Geschmack sind, Eine unbekannte Gegenstandsstufe ist keine Null, Gruppencheck, Nicht erreichbar ist kein Befund, Was geprüft wird (+18 more)

### Community 14 - "release_notes.py"
Cohesion: 0.05
Nodes (44): `ci.yml` — bei jedem Push, Der Patchnote-Stil, Die Kurzfassung, Die Schnittstellennummer, Die Schreibweise des Tags zählt buchstäblich, Die vier Stellen, und warum sie geprüft werden, Ein Release schneiden, `manual-release.yml` — der übliche Weg (+36 more)

### Community 15 - "search.lua"
Cohesion: 0.26
Nodes (10): Open(), BuildIndex(), Filter(), GetRow(), GoTo(), RenderMatches(), WeintCodex.Search.CloseDropdown(), WeintCodex.Search.OnFocusGained() (+2 more)

### Community 16 - "load_test.lua"
Cohesion: 0.24
Nodes (5): Check(), DrawEach(), EveryBoss(), Known(), ScanFolder()

### Community 17 - "loot.lua"
Cohesion: 0.39
Nodes (6): BuildPattern(), EscapeMagic(), GetLootMethodSafe(), ReportIfEpic(), WeintCodex.Loot.IsTrackingActive(), WeintCodex.Loot.Report()

### Community 18 - "NewObject"
Cohesion: 0.29
Nodes (7): M.Install(), Methods:CreateAnimation(), Methods:CreateAnimationGroup(), Methods:CreateFontString(), Methods:CreateTexture(), Methods:GetThumbTexture(), NewObject()

### Community 20 - "data_test.lua"
Cohesion: 0.40
Nodes (3): Check(), CheckBossList(), FeralIn()

### Community 27 - "Dungeons und Rollen"
Cohesion: 0.09
Nodes (21): Beschwörbare Zusatzbosse, Bilder: keine, und warum, Der Bestand, Die eigene Stufe, Die Navigationsspalte selbst, Die neun von Forever, Die Rollen, Die Seite: drei Flächen, eine Leserichtung (+13 more)

### Community 28 - "Schlachtzüge, Bosse und Fortschritt"
Cohesion: 0.17
Nodes (11): Alle Client-Aufrufe sind defensiv, Der Bestand, Der Fortschritt, Die Bossliste steht links, nicht in der Seite, Die Bosslisten: zwei vorläufig, eine leer, Die vier Bestände der Seite, Herkunft ist Pflicht, Nachtragen (+3 more)

### Community 29 - "Oberfläche: Aufbau und Designsprache „Graphit""
Cohesion: 0.18
Nodes (10): Das Bild, Der Detailbereich, Der Fensteraufbau, Der Seitenkopf, Die Unternavigation, Farben ansprechen, Nichts muss scrollen, Oberfläche: Aufbau und Designsprache „Graphit" (+2 more)

### Community 30 - "Changelog"
Cohesion: 0.18
Nodes (10): [5.0.0.0] – 2026-09-18, [5.1.0.0] – 2026-09-20, [5.2.0.0] – 2026-09-21, [5.2.0.1] – 2026-09-21, [5.2.0.2] – 2026-09-21, Changelog, Technisch, Technisch (+2 more)

### Community 31 - "Die Einführung"
Cohesion: 0.25
Nodes (7): Beim Release, Das Update-Popup, Die Einführung, Die Regeln für jeden Text, Einführung und Update-Popup, Was diese Tour zusätzlich sagt, Zwei Hervorhebungen, zwei Bedeutungen

### Community 32 - "updatePosition"
Cohesion: 0.25
Nodes (8): createButton(), lib:Refresh(), lib:Register(), lib:SetButtonRadius(), lib:SetButtonToPosition(), lib:Show(), onUpdate(), updatePosition()

### Community 33 - "getAnchors"
Cohesion: 0.67
Nodes (3): getAnchors(), onEnter(), onEnterCompartment()

## Knowledge Gaps
- **83 isolated node(s):** `Warum es sie gibt`, ``load_test.lua``, ``data_test.lua``, ``wow_stub.lua``, `Was diese Läufe **nicht** leisten` (+78 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 230 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **9 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `WeintCodex.Navigation.SwitchTo()` connect `navigation.lua` to `dungeonpages.lua`, `access.lua`, `ui.lua`, `calendar.lua`, `WeintCodex.ColorText`, `charakter.lua`, `BuildTree`, `groupcheck.lua`, `load_test.lua`?**
  _High betweenness centrality (0.173) - this node is a cross-community bridge._
- **Why does `Drei Dinge, die in WoW anders gelöst werden müssen` connect `ui.lua` to `Oberfläche: Aufbau und Designsprache „Graphit"`?**
  _High betweenness centrality (0.128) - this node is a cross-community bridge._
- **Why does `Oberfläche: Aufbau und Designsprache „Graphit"` connect `Oberfläche: Aufbau und Designsprache „Graphit"` to `ui.lua`?**
  _High betweenness centrality (0.126) - this node is a cross-community bridge._
- **Are the 31 inferred relationships involving `WeintCodex.ColorText()` (e.g. with `Row()` and `Warn()`) actually correct?**
  _`WeintCodex.ColorText()` has 31 INFERRED edges - model-reasoned connections that need verification._
- **Are the 15 inferred relationships involving `WeintCodex.ShowHome()` (e.g. with `WeintCodex.CreateButton()` and `WeintCodex.CreateMeter()`) actually correct?**
  _`WeintCodex.ShowHome()` has 15 INFERRED edges - model-reasoned connections that need verification._
- **Are the 10 inferred relationships involving `WeintCodex.Navigation.SetInspector()` (e.g. with `WeintCodex.SetDetailShown()` and `CreateCalendarFrame()`) actually correct?**
  _`WeintCodex.Navigation.SetInspector()` has 10 INFERRED edges - model-reasoned connections that need verification._
- **Are the 13 inferred relationships involving `WeintCodex.Access.Can()` (e.g. with `Can()` and `BuildVisibleSteps()`) actually correct?**
  _`WeintCodex.Access.Can()` has 13 INFERRED edges - model-reasoned connections that need verification._