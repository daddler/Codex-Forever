# Graph Report - Codex-Forever  (2026-09-22)

## Corpus Check
- 54 files · ~152,961 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 30 file(s) not represented in the graph (top: .tga 12, .ttf 10, (none) 3)

## Summary
- 806 nodes · 1677 edges · 34 communities (25 shown, 9 thin omitted)
- Extraction: 75% EXTRACTED · 25% INFERRED · 0% AMBIGUOUS · INFERRED: 418 edges (avg confidence: 0.86)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `8fe727fe`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- navigation.lua
- dungeonpages.lua
- access.lua
- BuildTree
- calendar.lua
- encounter_tracking.lua
- WeintCodex.ColorText
- ui.lua
- charakter.lua
- companion.lua
- groupcheck.lua
- release_notes.py
- RefreshMatDisplay
- load_test.lua
- loot.lua
- NewObject
- data_test.lua
- Dungeons und Rollen
- Schlachtzüge, Bosse und Fortschritt
- Changelog
- Die Einführung
- updatePosition
- getAnchors
- CLAUDE.md
- Der Fensteraufbau

## God Nodes (most connected - your core abstractions)
1. `WeintCodex.ColorText()` - 33 edges
2. `WeintCodex.ShowHome()` - 31 edges
3. `WeintCodex.Navigation.SetInspector()` - 26 edges
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
- `[5.2.0.5] – 2026-09-22` --references--> `GridLayout()`  [INFERRED]
  CHANGELOG.md → modules/dungeonpages.lua
- `Technisch` --references--> `HintFits()`  [INFERRED]
  CHANGELOG.md → modules/dungeonpages.lua
- `Technisch` --references--> `BuildColumn()`  [INFERRED]
  CHANGELOG.md → core/navigation.lua
- `Von aussen auf einen Boss zeigen` --references--> `GoToTab()`  [INFERRED]
  docs/systems/raids-and-progress.md → core/navigation.lua

## Import Cycles
- None detected.

## Communities (34 total, 9 thin omitted)

### Community 0 - "navigation.lua"
Cohesion: 0.05
Nodes (65): ApplyItemDisplay(), BuildColumn(), Can(), ClearContentPanel(), CreateItemRow(), DateKey(), Ellipsis(), EnsureSubNavColumn() (+57 more)

### Community 1 - "dungeonpages.lua"
Cohesion: 0.05
Nodes (81): Technisch, Critical invariants (always relevant, keep in mind for any change), Spaced(), Utf8CharLen(), WeintCodex.CreateSurface(), WeintCodex.EstimateLines(), WeintCodex.Eyebrow(), WeintCodex.Paragraph() (+73 more)

### Community 3 - "access.lua"
Cohesion: 0.12
Nodes (43): CopyFeatures(), CopyStrings(), EnsureBadge(), Mark(), NormalizeId(), Row(), Say(), Stamp() (+35 more)

### Community 4 - "BuildTree"
Cohesion: 0.11
Nodes (41): WeintCodex.Names.ClassLabel(), WeintCodex.RaidData.All(), WeintCodex.RaidData.BossesConfirmed(), WeintCodex.RaidData.BossListState(), WeintCodex.RaidData.BossSource(), WeintCodex.RaidData.BossSourceLabel(), WeintCodex.RaidData.Get(), WeintCodex.RaidData.HasBosses() (+33 more)

### Community 5 - "calendar.lua"
Cohesion: 0.09
Nodes (43): WeintCodex.Names.Equal(), WeintCodex.Names.Match(), WeintCodex.Names.Me(), WeintCodex.Names.Normalize(), WeintCodex.Names.Split(), WeintCodex.Icon(), AddPlayers(), AlternateInviteName() (+35 more)

### Community 7 - "encounter_tracking.lua"
Cohesion: 0.08
Nodes (30): Datenintegrität: `unknown` ist nicht `0`, Der Ausrüstungsstand an die Companion (`modules/companion.lua`), Der vierte Zustand ist mit 5.1.0.0 dazugekommen, Die Ausrüstung (`modules/charakter.lua`), Die Bosslisten (`data/raids.lua`, `data/dungeons.lua`), Die Client-Aufrufe, Die Materialien (`modules/materials.lua`), Die Regel (+22 more)

### Community 8 - "WeintCodex.ColorText"
Cohesion: 0.10
Nodes (40): GetDB(), ToggleAddon(), WeintCodex.Minimap.IsShown(), WeintCodex.Minimap.SetShown(), WeintCodex.Navigation.CurrentTab(), A(), AddButton(), BuildVisibleSteps() (+32 more)

### Community 9 - "ui.lua"
Cohesion: 0.07
Nodes (32): BuildStrip(), ApplySavedWindow(), ApplyVerticalGradient(), Col(), DrawHLine(), PlainText(), SetEscapeClose(), SetSolidBg() (+24 more)

### Community 10 - "charakter.lua"
Cohesion: 0.11
Nodes (31): WeintCodex.Label(), WeintCodex.Specs.ByIndex(), WeintCodex.Specs.ByName(), WeintCodex.Specs.ForClass(), WeintCodex.Specs.Key(), Die Spezialisierung (`data/specs.lua`, `modules/charakter.lua`), Charakter: Ausrüstung und Twinks, Die Ausrüstungsplätze kommen vom Client (+23 more)

### Community 12 - "companion.lua"
Cohesion: 0.11
Nodes (30): WeintCodex.Access.Init(), OnEvent(), `character_sheet` — was leer bleibt, und warum, Die Companion-Brücke, Die Reihenfolge in `ProcessQueue`, Die Seite *Companion*, Versionssperren, Was hereinkommt (+22 more)

### Community 13 - "groupcheck.lua"
Cohesion: 0.10
Nodes (30): WeintCodex.Navigation.ActivateFirst(), WeintCodex.CreateScrollArea(), WeintCodex.Truncate(), WeintCodex.Utf8Sub(), Der Gruppencheck (`modules/groupcheck.lua`), Bedienung, Die Schlange läuft einzeln, Drei Regeln, die nicht Geschmack sind (+22 more)

### Community 14 - "release_notes.py"
Cohesion: 0.05
Nodes (44): `ci.yml` — bei jedem Push, Der Patchnote-Stil, Die Kurzfassung, Die Schnittstellennummer, Die Schreibweise des Tags zählt buchstäblich, Die vier Stellen, und warum sie geprüft werden, Ein Release schneiden, `manual-release.yml` — der übliche Weg (+36 more)

### Community 15 - "RefreshMatDisplay"
Cohesion: 0.13
Nodes (21): Open(), BuildIndex(), Filter(), GetRow(), GoTo(), RenderMatches(), WeintCodex.Search.CloseDropdown(), WeintCodex.Search.OnFocusGained() (+13 more)

### Community 16 - "load_test.lua"
Cohesion: 0.20
Nodes (7): Check(), DrawEach(), Known(), Measure(), ScanFolder(), WeintCodex.DungeonPages.PageHeight(), WeintCodex.DungeonPages.Select()

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
Cohesion: 0.11
Nodes (17): Beschwörbare Zusatzbosse, Bilder: keine, und warum, Der Bestand, Die Navigationsspalte selbst, Die neun von Forever, Die Rollen, Die Spalte links, Die zwanzig aus Classic (+9 more)

### Community 28 - "Schlachtzüge, Bosse und Fortschritt"
Cohesion: 0.15
Nodes (12): Alle Client-Aufrufe sind defensiv, Der Bestand, Der Fortschritt, Die Bossliste steht links, nicht in der Seite, Die Bosslisten: zwei vorläufig, eine leer, Die vier Bestände der Seite, Herkunft ist Pflicht, Nachtragen (+4 more)

### Community 30 - "Changelog"
Cohesion: 0.13
Nodes (14): [5.0.0.0] – 2026-09-18, [5.1.0.0] – 2026-09-20, [5.2.0.0] – 2026-09-21, [5.2.0.1] – 2026-09-21, [5.2.0.2] – 2026-09-21, [5.2.0.3] – 2026-09-21, [5.2.0.4] – 2026-09-22, [5.2.0.5] – 2026-09-22 (+6 more)

### Community 31 - "Die Einführung"
Cohesion: 0.25
Nodes (7): Beim Release, Das Update-Popup, Die Einführung, Die Regeln für jeden Text, Einführung und Update-Popup, Was diese Tour zusätzlich sagt, Zwei Hervorhebungen, zwei Bedeutungen

### Community 32 - "updatePosition"
Cohesion: 0.25
Nodes (8): createButton(), lib:Refresh(), lib:Register(), lib:SetButtonRadius(), lib:SetButtonToPosition(), lib:Show(), onUpdate(), updatePosition()

### Community 33 - "getAnchors"
Cohesion: 0.67
Nodes (3): getAnchors(), onEnter(), onEnterCompartment()

### Community 34 - "CLAUDE.md"
Cohesion: 0.29
Nodes (5): Development workflow, Role in the ecosystem, Task routing — read only what the task needs, What this edition deliberately does not have, What this is

### Community 38 - "Der Fensteraufbau"
Cohesion: 0.40
Nodes (5): Der Detailbereich, Der Fensteraufbau, Die Unternavigation, Nichts muss scrollen, onClick()

## Knowledge Gaps
- **85 isolated node(s):** `Warum es sie gibt`, ``load_test.lua``, ``data_test.lua``, ``wow_stub.lua``, `Was diese Läufe **nicht** leisten` (+80 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 232 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **9 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `WeintCodex.Navigation.SwitchTo()` connect `navigation.lua` to `dungeonpages.lua`, `access.lua`, `BuildTree`, `calendar.lua`, `charakter.lua`, `groupcheck.lua`, `RefreshMatDisplay`, `load_test.lua`?**
  _High betweenness centrality (0.157) - this node is a cross-community bridge._
- **Why does `WeintCodex.ColorText()` connect `WeintCodex.ColorText` to `navigation.lua`, `dungeonpages.lua`, `access.lua`, `BuildTree`, `calendar.lua`, `ui.lua`, `charakter.lua`, `companion.lua`, `groupcheck.lua`, `RefreshMatDisplay`?**
  _High betweenness centrality (0.141) - this node is a cross-community bridge._
- **Why does `Drei Dinge, die in WoW anders gelöst werden müssen` connect `ui.lua` to `dungeonpages.lua`?**
  _High betweenness centrality (0.125) - this node is a cross-community bridge._
- **Are the 32 inferred relationships involving `WeintCodex.ColorText()` (e.g. with `Row()` and `Warn()`) actually correct?**
  _`WeintCodex.ColorText()` has 32 INFERRED edges - model-reasoned connections that need verification._
- **Are the 15 inferred relationships involving `WeintCodex.ShowHome()` (e.g. with `WeintCodex.CreateButton()` and `WeintCodex.CreateMeter()`) actually correct?**
  _`WeintCodex.ShowHome()` has 15 INFERRED edges - model-reasoned connections that need verification._
- **Are the 11 inferred relationships involving `WeintCodex.Navigation.SetInspector()` (e.g. with `WeintCodex.SetDetailShown()` and `CreateCalendarFrame()`) actually correct?**
  _`WeintCodex.Navigation.SetInspector()` has 11 INFERRED edges - model-reasoned connections that need verification._
- **Are the 13 inferred relationships involving `WeintCodex.Access.Can()` (e.g. with `Can()` and `BuildVisibleSteps()`) actually correct?**
  _`WeintCodex.Access.Can()` has 13 INFERRED edges - model-reasoned connections that need verification._