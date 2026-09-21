# Graph Report - Codex-Forever  (2026-09-21)

## Corpus Check
- cluster-only mode — file stats not available

## Summary
- 624 nodes · 1423 edges · 27 communities (19 shown, 8 thin omitted)
- Extraction: 74% EXTRACTED · 26% INFERRED · 0% AMBIGUOUS · INFERRED: 363 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `68009b51`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- navigation.lua
- dungeonpages.lua
- LibDBIcon-1.0.lua
- access.lua
- ui.lua
- calendar.lua
- encounter_tracking.lua
- settings.lua
- WeintCodex.ColorText
- charakter.lua
- WeintCodex.RolePanel.Card
- companion.lua
- groupcheck.lua
- release_notes.py
- search.lua
- load_test.lua
- loot.lua
- NewObject
- data_test.lua

## God Nodes (most connected - your core abstractions)
1. `WeintCodex.ShowHome()` - 31 edges
2. `WeintCodex.ColorText()` - 31 edges
3. `WeintCodex.Navigation.SetInspector()` - 28 edges
4. `WeintCodex.Navigation.SwitchTo()` - 21 edges
5. `DrawInstance()` - 21 edges
6. `BuildTree()` - 20 edges
7. `WeintCodex.Access.Can()` - 20 edges
8. `CreateCalendarFrame()` - 20 edges
9. `WeintCodex.Access.Print()` - 16 edges
10. `WeintCodex.PageHead()` - 15 edges

## Surprising Connections (you probably didn't know these)
- `DrawEach()` --calls--> `WeintCodex.Navigation.SwitchTo()`  [INFERRED]
  .github/tests/load_test.lua → core/navigation.lua
- `BuildTree()` --calls--> `WeintCodex.Navigation.ActivateIndex()`  [INFERRED]
  modules/raidpages.lua → core/navigation.lua
- `WeintCodex.Calendar.Show()` --calls--> `WeintCodex.Navigation.BuildSidebar()`  [INFERRED]
  modules/calendar.lua → core/navigation.lua
- `WeintCodex.GroupCheck.Show()` --calls--> `WeintCodex.Navigation.BuildSidebar()`  [INFERRED]
  modules/groupcheck.lua → core/navigation.lua
- `WeintCodex.Materials.Show()` --calls--> `WeintCodex.Navigation.BuildSidebar()`  [INFERRED]
  modules/materials.lua → core/navigation.lua

## Import Cycles
- None detected.

## Communities (27 total, 8 thin omitted)

### Community 0 - "navigation.lua"
Cohesion: 0.06
Nodes (64): ApplyItemDisplay(), BuildColumn(), BuildStrip(), Can(), ClearContentPanel(), CreateItemRow(), DateKey(), EnsureSubNavColumn() (+56 more)

### Community 1 - "dungeonpages.lua"
Cohesion: 0.07
Nodes (55): Spaced(), WeintCodex.Eyebrow(), WeintCodex.PageHead(), WeintCodex.SetBreadcrumb(), D.AllInstances(), D.AllSummonable(), D.BossesInWing(), D.BracketIndexOf() (+47 more)

### Community 2 - "LibDBIcon-1.0.lua"
Cohesion: 0.05
Nodes (11): createButton(), getAnchors(), lib:Refresh(), lib:Register(), lib:SetButtonRadius(), lib:SetButtonToPosition(), lib:Show(), onEnter() (+3 more)

### Community 3 - "access.lua"
Cohesion: 0.12
Nodes (43): CopyFeatures(), CopyStrings(), EnsureBadge(), Mark(), NormalizeId(), Row(), Say(), Stamp() (+35 more)

### Community 4 - "ui.lua"
Cohesion: 0.08
Nodes (33): Ellipsis(), InspectorInput(), WeintCodex.Navigation.RefreshAccount(), ApplySavedWindow(), ApplyVerticalGradient(), Col(), DrawBorder(), DrawHLine() (+25 more)

### Community 5 - "calendar.lua"
Cohesion: 0.10
Nodes (38): WeintCodex.Icon(), AddPlayers(), AlternateInviteName(), CreateCalendarFrame(), DiscardDraft(), DraftConfirmed(), DraftInviteCount(), DraftInviteName() (+30 more)

### Community 7 - "encounter_tracking.lua"
Cohesion: 0.09
Nodes (33): WeintCodex.RaidData.All(), WeintCodex.RaidData.BossesConfirmed(), WeintCodex.RaidData.BossListState(), WeintCodex.RaidData.BossSource(), WeintCodex.RaidData.BossSourceLabel(), WeintCodex.RaidData.Get(), WeintCodex.RaidData.HasBosses(), EveryBoss() (+25 more)

### Community 8 - "settings.lua"
Cohesion: 0.14
Nodes (25): GetDB(), ToggleAddon(), WeintCodex.Minimap.IsShown(), WeintCodex.Minimap.SetShown(), WeintCodex.Navigation.CurrentTab(), WeintCodex.CreateScrollArea(), Buttons(), ClearBody() (+17 more)

### Community 9 - "WeintCodex.ColorText"
Cohesion: 0.18
Nodes (24): A(), AddButton(), BuildVisibleSteps(), ClearButtons(), CollectChangelogSince(), CreateButton(), Dismiss(), E() (+16 more)

### Community 10 - "charakter.lua"
Cohesion: 0.17
Nodes (24): WeintCodex.CreateToggle(), WeintCodex.Label(), WeintCodex.Specs.ByIndex(), WeintCodex.Specs.ByName(), WeintCodex.Specs.ForClass(), WeintCodex.Specs.Key(), BuildPage(), ClassColor() (+16 more)

### Community 11 - "WeintCodex.RolePanel.Card"
Cohesion: 0.16
Nodes (22): WeintCodex.Names.ClassLabel(), WeintCodex.Names.Equal(), WeintCodex.Names.Match(), WeintCodex.Names.Normalize(), WeintCodex.Names.Split(), TipsAllowed(), WeintCodex.Roles.Frame(), WeintCodex.Roles.FrameLabel() (+14 more)

### Community 12 - "companion.lua"
Cohesion: 0.17
Nodes (22): WeintCodex.Access.Init(), OnEvent(), WeintCodex.Names.Me(), BoundCommunityId(), BuildCharacterSheet(), CleanField(), CompanionAtLeast(), Dispatch() (+14 more)

### Community 13 - "groupcheck.lua"
Cohesion: 0.21
Nodes (18): WeintCodex.Navigation.ActivateFirst(), After(), AverageItemLevel(), BuildInspector(), ClassColorText(), CompleteCurrent(), DrawTable(), GroupUnits() (+10 more)

### Community 14 - "release_notes.py"
Cohesion: 0.19
Nodes (15): changelog_lua_version(), lua_version(), main(), normalize(), problems_for(), Den Changelog-Abschnitt eines Tags als Release-Text ausgeben - und nebenbei…, Die Zahlen stimmen - aber schreibt der Tag sie so, wie das `.toc` sie schreibt?…, "v1.3.3.1", "1.3.3.1" und "1.3.3" sind vergleichbar; fehlende Stellen zaehlen… (+7 more)

### Community 15 - "search.lua"
Cohesion: 0.26
Nodes (10): Open(), BuildIndex(), Filter(), GetRow(), GoTo(), RenderMatches(), WeintCodex.Search.CloseDropdown(), WeintCodex.Search.OnFocusGained() (+2 more)

### Community 16 - "load_test.lua"
Cohesion: 0.28
Nodes (4): Check(), DrawEach(), Known(), ScanFolder()

### Community 17 - "loot.lua"
Cohesion: 0.39
Nodes (6): BuildPattern(), EscapeMagic(), GetLootMethodSafe(), ReportIfEpic(), WeintCodex.Loot.IsTrackingActive(), WeintCodex.Loot.Report()

### Community 18 - "NewObject"
Cohesion: 0.29
Nodes (7): M.Install(), Methods:CreateAnimation(), Methods:CreateAnimationGroup(), Methods:CreateFontString(), Methods:CreateTexture(), Methods:GetThumbTexture(), NewObject()

### Community 20 - "data_test.lua"
Cohesion: 0.40
Nodes (3): Check(), CheckBossList(), FeralIn()

## Knowledge Gaps
- **8 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `WeintCodex.Navigation.SwitchTo()` connect `navigation.lua` to `dungeonpages.lua`, `access.lua`, `calendar.lua`, `encounter_tracking.lua`, `WeintCodex.ColorText`, `charakter.lua`, `groupcheck.lua`, `load_test.lua`?**
  _High betweenness centrality (0.130) - this node is a cross-community bridge._
- **Why does `WeintCodex.ColorText()` connect `WeintCodex.ColorText` to `navigation.lua`, `access.lua`, `ui.lua`, `calendar.lua`, `settings.lua`, `charakter.lua`, `companion.lua`, `groupcheck.lua`, `search.lua`?**
  _High betweenness centrality (0.098) - this node is a cross-community bridge._
- **Why does `WeintCodex.Navigation.SetInspector()` connect `navigation.lua` to `dungeonpages.lua`, `access.lua`, `ui.lua`, `calendar.lua`, `encounter_tracking.lua`, `WeintCodex.ColorText`, `charakter.lua`, `groupcheck.lua`?**
  _High betweenness centrality (0.082) - this node is a cross-community bridge._
- **Are the 15 inferred relationships involving `WeintCodex.ShowHome()` (e.g. with `WeintCodex.CreateButton()` and `WeintCodex.CreateMeter()`) actually correct?**
  _`WeintCodex.ShowHome()` has 15 INFERRED edges - model-reasoned connections that need verification._
- **Are the 30 inferred relationships involving `WeintCodex.ColorText()` (e.g. with `Row()` and `Warn()`) actually correct?**
  _`WeintCodex.ColorText()` has 30 INFERRED edges - model-reasoned connections that need verification._
- **Are the 13 inferred relationships involving `WeintCodex.Navigation.SetInspector()` (e.g. with `WeintCodex.SetDetailShown()` and `CreateCalendarFrame()`) actually correct?**
  _`WeintCodex.Navigation.SetInspector()` has 13 INFERRED edges - model-reasoned connections that need verification._
- **Are the 13 inferred relationships involving `WeintCodex.Navigation.SwitchTo()` (e.g. with `WeintCodex.Calendar.Show()` and `WeintCodex.Charakter.Show()`) actually correct?**
  _`WeintCodex.Navigation.SwitchTo()` has 13 INFERRED edges - model-reasoned connections that need verification._