# Graph Report - Codex-Forever  (2026-09-22)

## Corpus Check
- 30 files · ~158,377 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 968 nodes · 1836 edges · 49 communities (39 shown, 10 thin omitted)
- Extraction: 78% EXTRACTED · 22% INFERRED · 0% AMBIGUOUS · INFERRED: 407 edges (avg confidence: 0.86)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- Navigation und Inhaltsspalte
- Zugriffsprofile und Rechte
- Herkunftsmodell und Datenwahrheit
- Schlachtzugsdaten
- Ökosystem und Talentbäume
- Companion-Brücke
- Invariante: unknown ist nicht 0
- Einführungstour und Update-Popup
- Release-Schneiden
- Dungeonseite
- Minimap-Knopf
- Fensteraufbau und Listenspalte
- Namen und Kalender
- Dungeon-Dokumentation
- CI-Workflows
- Rollenmodell
- Gruppencheck
- Fliesstext und Bossdetail
- UI-Grundbausteine
- Changelog-Fassungen
- Forever-Dungeondaten
- Unternavigation im Detail
- Seitenkopf und Bossraster
- Hauptfenster und Suche
- Ladeprüfung
- Quellen und Dungeon-Inspector
- Patchnoten und Datenverträge
- Classic-Dungeondaten
- Designsprache Graphit
- Kopflose Prüfläufe
- Architekturübersicht
- Ladereihenfolge und Budgets
- Logo-Bildmarke
- Onboarding-Dokumentation
- LibDBIcon-Positionierung
- CLAUDE.md als Router
- Attrappen-Objektmodell
- Button-Bildmarke
- Minimap-Tooltips
- Fassung 5.2.0.1

## God Nodes (most connected - your core abstractions)
1. `WeintCodex.ColorText()` - 32 edges
2. `WeintCodex.Navigation.SetInspector()` - 26 edges
3. `WeintCodex.ShowHome()` - 24 edges
4. `CreateCalendarFrame()` - 20 edges
5. `WeintCodex.Access.Can()` - 19 edges
6. `WeintCodex.Eyebrow()` - 19 edges
7. `Datenintegrität: `unknown` ist nicht `0`` - 18 edges
8. `WeintCodex.CreateSurface()` - 17 edges
9. `WeintCodex.Access.Print()` - 16 edges
10. `Col()` - 16 edges

## Surprising Connections (you probably didn't know these)
- `Die Spezialisierung (`data/specs.lua`, `modules/charakter.lua`)` --references--> `CurrentSpec()`  [INFERRED]
  docs/invariants/data-integrity.md → modules/charakter.lua
- `Die Spaltenzahl ist gerechnet, nicht gesetzt` --references--> `PlaceGrid()`  [INFERRED]
  docs/systems/dungeons.md → modules/dungeonpages.lua
- `Zwei Zustände, eine Struktur` --references--> `HintFits()`  [INFERRED]
  docs/systems/dungeons.md → modules/dungeonpages.lua
- `[5.2.0.5] – 2026-09-22` --references--> `GridLayout()`  [INFERRED]
  CHANGELOG.md → modules/dungeonpages.lua
- `Technisch` --references--> `HintFits()`  [INFERRED]
  CHANGELOG.md → modules/dungeonpages.lua

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Die Fassung steht an vier Stellen und wird vor jedem Release geprüft** — docs_development_releases_vier_stellen, docs_development_releases_versionspruefung, claude_version_in_three_places, docs_systems_onboarding_changelog_update_popup, _github_workflows_ci_fassungsangaben, changelog_keep_a_changelog_format [EXTRACTED 1.00]
- **Kein Bestand ohne Herkunft — das gemeinsame Herkunftsmodell** — docs_systems_dungeons_fuenf_arten_von_herkunft, docs_systems_dungeons_sources_why, docs_systems_dungeons_beta_gegen_community, docs_invariants_data_integrity_kein_bestand_ohne_herkunft, docs_invariants_data_integrity_bossesconfirmed, docs_invariants_data_integrity_sources_weaker, docs_systems_raids_and_progress_bosssource, claude_kein_bestand_ohne_herkunft [EXTRACTED 1.00]
- **Nichts muss scrollen — Budgets, Messfunktionen und die Seiten, die sie einhalten** — docs_architecture_overview_nichts_muss_scrollen, docs_architecture_overview_measuresidebar, _github_tests_readme_nichts_muss_scrollen, docs_systems_dungeons_stufenabschnitte, docs_systems_dungeons_gridlayout, docs_systems_dungeons_detailbereich_wo_er_passt, docs_systems_raids_and_progress_bossliste_links [EXTRACTED 1.00]
- **Markenzeichen des Addons: Monogramm, Farbpaar, Icon-Lesbarkeit** — media_button_icon, media_button_wc_monogram, media_button_purple_accent, media_button_green_secondary, media_button_small_size_legibility [INFERRED 0.85]
- **Brand mark composition: crest, props, frame, wordmark, tagline** — media_logo_alliance_lion_crest, media_logo_codex_props_tome_scroll_lantern, media_logo_ornate_frame_banner, media_logo_wordmark_weintcodex, media_logo_tagline_raid_guide_intelligence_system [EXTRACTED 1.00]
- **Design constraints the artwork satisfies** — media_logo_purple_gold_accent_palette, media_logo_transparent_wide_banner_format, media_logo_brand_identity_weint_ecosystem, media_logo_weintcodex_logo [INFERRED 0.75]

## Communities (49 total, 10 thin omitted)

### Community 0 - "Navigation und Inhaltsspalte"
Cohesion: 0.05
Nodes (64): ApplyItemDisplay(), BuildStrip(), Can(), ClearContentPanel(), CreateItemRow(), DateKey(), EnsureSubNavColumn(), GetMaterialShortageCount() (+56 more)

### Community 1 - "Zugriffsprofile und Rechte"
Cohesion: 0.10
Nodes (52): CopyFeatures(), CopyStrings(), EnsureBadge(), Mark(), NormalizeId(), Row(), Say(), Stamp() (+44 more)

### Community 2 - "Herkunftsmodell und Datenwahrheit"
Cohesion: 0.05
Nodes (46): Fassung 5.1.0.0 — vierter Zustand „vorläufig", Beta-Client-Bosslisten, Fassung 5.2.0.0 — sechs Zustände, data/sources.lua, 29 Instanzen, Kein Bestand ohne Herkunft (Invariante), Nobody here has read the Forever client — Dungeonbosse sind community, nie beta, Spaced — Sperrung durch eingefügte Haarspatien, je Zeichen, UTF-8 gegen Lua-Bytefunktionen (Upper/Utf8Len/Utf8Sub/Truncate), ## Interface: 120000 — eine benannte Vermutung an genau einer Stelle, BossesConfirmed() — nur kind == "release" gilt als bestätigt (+38 more)

### Community 3 - "Schlachtzugsdaten"
Cohesion: 0.09
Nodes (37): WeintCodex.RaidData.All(), WeintCodex.RaidData.BossesConfirmed(), WeintCodex.RaidData.BossListState(), WeintCodex.RaidData.BossSource(), WeintCodex.RaidData.BossSourceLabel(), WeintCodex.RaidData.Get(), WeintCodex.RaidData.HasBosses(), WeintCodex.RaidData.KnownBossCount() (+29 more)

### Community 4 - "Ökosystem und Talentbäume"
Cohesion: 0.08
Nodes (39): Das Addon spricht nie direkt mit Netz, Bot oder Companion, Companion-Forever (Desktop, verbindlicher Ort jedes Datenvertrags), WeintCodex Bot (Discord), WeintCodex — Forever Edition (das Ingame-Addon), WeintCodex.CreateToggle(), WeintCodex.Specs.ByIndex(), WeintCodex.Specs.ByName(), WeintCodex.Specs.ForClass() (+31 more)

### Community 5 - "Companion-Brücke"
Cohesion: 0.08
Nodes (37): `character_sheet` — was leer bleibt, und warum, Die Companion-Brücke, Die Reihenfolge in `ProcessQueue`, Die Seite *Companion*, Versionssperren, Was hereinkommt, Was hinausgeht, Zwei Wege hinein, und warum es zwei sind (+29 more)

### Community 6 - "Invariante: unknown ist nicht 0"
Cohesion: 0.06
Nodes (38): Fassung 5.0.0.0 — Forever Edition, entstanden durch Wegnehmen, Durch Wegnehmen entstanden, nicht durch Neubau, unknown ≠ 0 ≠ false ≠ provisional (Invariante), Was diese Fassung bewusst nicht hat (Sims, Sockel, WeakAuras, BiS, Bilder), Datenintegrität: `unknown` ist nicht `0`, Der Ausrüstungsstand an die Companion (`modules/companion.lua`), Der Gruppencheck (`modules/groupcheck.lua`), Der vierte Zustand ist mit 5.1.0.0 dazugekommen (+30 more)

### Community 7 - "Einführungstour und Update-Popup"
Cohesion: 0.11
Nodes (35): A(), AddButton(), BuildVisibleSteps(), ClearButtons(), CollectChangelogSince(), CreateButton(), Dismiss(), E() (+27 more)

### Community 9 - "Release-Schneiden"
Cohesion: 0.06
Nodes (35): `ci.yml` — bei jedem Push, Der Patchnote-Stil, Die Kurzfassung, Die Schnittstellennummer, Die Schreibweise des Tags zählt buchstäblich, Die vier Stellen, und warum sie geprüft werden, Ein Release schneiden, `manual-release.yml` — der übliche Weg (+27 more)

### Community 10 - "Dungeonseite"
Cohesion: 0.12
Nodes (34): Critical invariants (always relevant, keep in mind for any change), WeintCodex.Utf8Len(), Der Detailbereich rechts, wo er passt, AvailableHeight(), BodyWidthMin(), BossCard(), BossTag(), BuildPage() (+26 more)

### Community 11 - "Minimap-Knopf"
Cohesion: 0.12
Nodes (29): GetDB(), ToggleAddon(), WeintCodex.Minimap.IsShown(), WeintCodex.Minimap.SetShown(), WeintCodex.Navigation.ActivateIndex(), WeintCodex.Navigation.CurrentTab(), SetEscapeClose(), WeintCodex.ApplyWindowBehaviour() (+21 more)

### Community 13 - "Fensteraufbau und Listenspalte"
Cohesion: 0.11
Nodes (20): Technisch, BuildColumn(), ApplySavedWindow(), ApplyVerticalGradient(), Col(), PlainText(), SetSolidBg(), Spaced() (+12 more)

### Community 14 - "Namen und Kalender"
Cohesion: 0.14
Nodes (25): WeintCodex.Names.Equal(), WeintCodex.Names.Match(), WeintCodex.Names.Me(), WeintCodex.Names.Normalize(), WeintCodex.Names.Split(), AddPlayers(), AlternateInviteName(), CreateCalendarFrame() (+17 more)

### Community 15 - "Dungeon-Dokumentation"
Cohesion: 0.07
Nodes (26): Beschwörbare Zusatzbosse, Bilder: keine, und warum, Der Bestand, Der Dungeonkontext steht in einer Zeile, Die eigene Stufe, Die Herkunft steht in jedem Zustand genau einmal sichtbar, Die Navigationsspalte selbst, Die neun von Forever (+18 more)

### Community 16 - "CI-Workflows"
Cohesion: 0.14
Nodes (20): data_test.lua — Datentabellen und Fassungsangaben, CI-Schritt Fassungsangaben (Version aus der .toc gegen release_notes.py), CI-Workflow „Prüfen" (Job pruefen), Erste Stufe: luac5.1 -p über core/data/modules/.github/tests, Addon-Ordner bauen (rsync mit Ausschlussliste), Workflow „Release auf Knopfdruck" (Job release), tag/notes nur über env — keine direkte ${{ inputs }}-Interpolation, Ein vom GITHUB_TOKEN erstelltes Release löst release.yml nicht aus (+12 more)

### Community 17 - "Rollenmodell"
Cohesion: 0.16
Nodes (12): TipsAllowed(), WeintCodex.Roles.Frame(), WeintCodex.Roles.FrameLabel(), WeintCodex.Roles.HasTips(), WeintCodex.Roles.Short(), WeintCodex.Roles.SpecCount(), WeintCodex.Roles.Specs(), WeintCodex.Roles.TippedBossCount() (+4 more)

### Community 18 - "Gruppencheck"
Cohesion: 0.24
Nodes (15): After(), BuildInspector(), ClassColorText(), CompleteCurrent(), GroupUnits(), MakeRunButton(), RefreshIfVisible(), Safe() (+7 more)

### Community 19 - "Fliesstext und Bossdetail"
Cohesion: 0.17
Nodes (15): Ellipsis(), WeintCodex.Paragraph(), WeintCodex.Truncate(), BodyText(), DrawBossDetail(), DrawFacts(), DrawRoster(), JoinList() (+7 more)

### Community 20 - "UI-Grundbausteine"
Cohesion: 0.26
Nodes (16): DrawHLine(), WeintCodex.CreateScrollArea(), WeintCodex.CreateSurface(), WeintCodex.Eyebrow(), WeintCodex.Label(), WeintCodex.PageHead(), WeintCodex.RowLine(), WeintCodex.ShowExportDialog() (+8 more)

### Community 21 - "Changelog-Fassungen"
Cohesion: 0.13
Nodes (14): [5.0.0.0] – 2026-09-18, [5.1.0.0] – 2026-09-20, [5.2.0.0] – 2026-09-21, [5.2.0.1] – 2026-09-21, [5.2.0.2] – 2026-09-21, [5.2.0.3] – 2026-09-21, [5.2.0.4] – 2026-09-22, [5.2.0.5] – 2026-09-22 (+6 more)

### Community 22 - "Forever-Dungeondaten"
Cohesion: 0.20
Nodes (7): D.BossCount(), D.BossesComplete(), D.BossesConfirmed(), D.BossSource(), D.BossSourceLabel(), D.HasBosses(), D.OrderKnown()

### Community 23 - "Unternavigation im Detail"
Cohesion: 0.15
Nodes (14): Fassung 5.2.0.2 — Gruppenkopf der Unternavigation, Fassung 5.2.0.4 — zweite Zeile der Unternavigation nicht mehr gesperrt, Der Detailbereich (Navigation.SetInspector, Blocktypen), Fensteraufbau: Titelleiste, Navigation 232, ContentPanel, Detailbereich 372, mark kostet der Beschriftung Breite (FOREVER: ~70 von 176 px), status nimmt String oder { text, color } — die stille leere Zeile, Die Unternavigation (BuildSidebar, Reiterleiste oder Listenspalte), Die zweite Zeile ist ein Wert, keine Rubrik — seit 5.2.0.4 nicht gesperrt (+6 more)

### Community 24 - "Seitenkopf und Bossraster"
Cohesion: 0.21
Nodes (14): Fassung 5.2.0.3 — Detailbereich auf der Dungeonseite, Fassung 5.2.0.5 — Dungeonseite in drei Ebenen neu gelegt, Fassung 5.2.0.6 — Kopfkarte, Tatsachenband, Bosskarten mit Kartenverlauf, Ankerkette statt gerechneter Y-Werte (keine geschätzten Schriftmetriken), WeintCodex.PageHead — der einzige Ort, an dem ein Seitenkopf entsteht, Den Mechanismus prüfen, nicht den Bestand, Das Bossraster — Karten statt Pillen, Der Detailbereich rechts, wo er passt — DrawDungeon zeichnet, misst, zeichnet neu (+6 more)

### Community 25 - "Hauptfenster und Suche"
Cohesion: 0.23
Nodes (11): OnEvent(), Open(), BuildIndex(), Filter(), GetRow(), GoTo(), RenderMatches(), WeintCodex.Search.CloseDropdown() (+3 more)

### Community 26 - "Ladeprüfung"
Cohesion: 0.18
Nodes (7): Check(), DrawEach(), Known(), Measure(), ScanFolder(), WeintCodex.DungeonPages.PageHeight(), WeintCodex.DungeonPages.Select()

### Community 27 - "Quellen und Dungeon-Inspector"
Cohesion: 0.30
Nodes (11): S.IsConfirmed(), S.IsValid(), S.Label(), S.Prefix(), S.Rank(), S.Weaker(), S.Why(), DungeonInspector() (+3 more)

### Community 28 - "Patchnoten und Datenverträge"
Cohesion: 0.24
Nodes (11): Changelog-Format: vierteiliges Schema MAJOR.MINOR.PATCH.BUILD, kein SemVer, Task-Routing-Tabelle — CLAUDE.md ist ein Router, keine Wissensbasis, Der Patchnote-Stil — drei Regeln, Abschnitt „### Technisch" — für Entwickler, vom Popup nicht gelesen, SavedVariables-Rückschreiben vernichtet, was die Companion dazwischen schrieb, Live-Brücke data/companion_live.lua und lastStamp, ProcessInbox() — Inbox und Live-Datei zusammengeführt, ProcessQueue — access_profile zuerst, dann alles andere mit Herkunftsprüfung (+3 more)

### Community 29 - "Classic-Dungeondaten"
Cohesion: 0.24
Nodes (4): D.AllInstances(), D.AllSummonable(), D.BracketIndexOf(), D.Brackets()

### Community 30 - "Designsprache Graphit"
Cohesion: 0.20
Nodes (11): ApplyVerticalGradient — SetGradient läuft von unten nach oben, ColorText und unbekannte Farbnamen — alte Namen bleiben bestehen, CutCorners — Viertelkreis-Masken statt border-radius, Ein Akzent (#7C6CFF), und er trägt ausschliesslich Bedeutung, Jeder Farbwert lebt in core/ui.lua (Übersetzung von tokens.py), Designsprache „Graphit", Tiefe durch Schichtung: sunken < base < card < raised, Rollenfarben (Tank blau, Heiler grün, Schaden rot) — Roles.Tone (+3 more)

### Community 31 - "Kopflose Prüfläufe"
Cohesion: 0.20
Nodes (10): Ein grüner Lauf heisst „es lädt", nicht „es funktioniert", `data_test.lua`, Die Attrappe klickt jetzt wirklich (seit 5.2.0.0), Kopflose Prüfläufe, `load_test.lua`, Warum es sie gibt, Was der Lauf seit 5.2.0.0 zusätzlich misst, Was diese Läufe **nicht** leisten (+2 more)

### Community 32 - "Architekturübersicht"
Cohesion: 0.20
Nodes (9): Das Bild, Der Detailbereich, Der Fensteraufbau, Der Seitenkopf, Die Unternavigation, Farben ansprechen, Oberfläche: Aufbau und Designsprache „Graphit", UTF-8 (+1 more)

### Community 33 - "Ladereihenfolge und Budgets"
Cohesion: 0.25
Nodes (9): Methods:Click in der Attrappe — ein Klick zeichnet wirklich, load_test.lua — Ladeprüfung gegen die Client-Attrappe, Kein Zugriff auf ein Modul, das es nicht gibt, Budgetprüfung: nichts muss scrollen (780 px), WeintCodex.SavedData zeigt auf dieselbe Tabelle, nie auf eine Ersatztabelle, wow_stub.lua — bewusst dumme Client-Attrappe, WeintCodex.toc-Ladereihenfolge ist der einzige Abhängigkeitsmechanismus, MeasureSidebar / NavColumnHeight / SubNavHeight / Budgets (+1 more)

### Community 34 - "Logo-Bildmarke"
Cohesion: 0.42
Nodes (9): Alliance Lion Crest Emblem, Weint Brand Identity (shared across Codex, Companion, Bot), Codex Props: Tome, Scroll, Lantern, Quill, Ornate Gold Banner Frame with Gem Finials, Purple/Gold/Green Accent Palette, Tagline: RAID GUIDE & INTELLIGENCE SYSTEM, Wide Transparent PNG Banner Format, WeintCodex Logo (Banner Artwork) (+1 more)

### Community 35 - "Onboarding-Dokumentation"
Cohesion: 0.25
Nodes (7): Beim Release, Das Update-Popup, Die Einführung, Die Regeln für jeden Text, Einführung und Update-Popup, Was diese Tour zusätzlich sagt, Zwei Hervorhebungen, zwei Bedeutungen

### Community 36 - "LibDBIcon-Positionierung"
Cohesion: 0.25
Nodes (8): createButton(), lib:Refresh(), lib:Register(), lib:SetButtonRadius(), lib:SetButtonToPosition(), lib:Show(), onUpdate(), updatePosition()

### Community 37 - "CLAUDE.md als Router"
Cohesion: 0.29
Nodes (5): Development workflow, Role in the ecosystem, Task routing — read only what the task needs, What this edition deliberately does not have, What this is

### Community 38 - "Attrappen-Objektmodell"
Cohesion: 0.29
Nodes (7): M.Install(), Methods:CreateAnimation(), Methods:CreateAnimationGroup(), Methods:CreateFontString(), Methods:CreateTexture(), Methods:GetThumbTexture(), NewObject()

### Community 40 - "Button-Bildmarke"
Cohesion: 0.43
Nodes (7): Absoluter Medienpfad Interface/AddOns/WeintCodex/media, Grüner Sekundärton des W, WeintCodex Button Icon (button.png), Minimap-/Einstiegsschaltfläche des Addons, Violetter Akzent als einzige bedeutungstragende Farbe, Lesbarkeit auf Icon-Größe (dunkler Rahmen, hoher Kontrast), WC-Monogramm (Markenzeichen)

### Community 43 - "Minimap-Tooltips"
Cohesion: 0.67
Nodes (3): getAnchors(), onEnter(), onEnterCompartment()

## Ambiguous Edges - Review These
- `Purple/Gold/Green Accent Palette` → `Wide Transparent PNG Banner Format`  [AMBIGUOUS]
  media/logo.png · relation: conceptually_related_to

## Knowledge Gaps
- **103 isolated node(s):** `Der Dungeonkontext steht in einer Zeile`, `Die eigene Stufe`, `Die Herkunft steht in jedem Zustand genau einmal sichtbar`, `Die Spalte läuft nicht über, und die Seite auch nicht`, `Ein Flügel darf keinen Boss verlieren` (+98 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 289 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **10 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What is the exact relationship between `Purple/Gold/Green Accent Palette` and `Wide Transparent PNG Banner Format`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **Why does `Kopflose Prüfläufe` connect `Kopflose Prüfläufe` to `CI-Workflows`, `Release-Schneiden`, `Patchnoten und Datenverträge`, `Ladereihenfolge und Budgets`?**
  _High betweenness centrality (0.139) - this node is a cross-community bridge._
- **Why does `Der Fensteraufbau` connect `Architekturübersicht` to `Ladereihenfolge und Budgets`?**
  _High betweenness centrality (0.135) - this node is a cross-community bridge._
- **Why does `Task-Routing-Tabelle — CLAUDE.md ist ein Router, keine Wissensbasis` connect `Patchnoten und Datenverträge` to `Herkunftsmodell und Datenwahrheit`, `Kopflose Prüfläufe`, `Designsprache Graphit`, `Invariante: unknown ist nicht 0`?**
  _High betweenness centrality (0.125) - this node is a cross-community bridge._
- **Are the 31 inferred relationships involving `WeintCodex.ColorText()` (e.g. with `Row()` and `Warn()`) actually correct?**
  _`WeintCodex.ColorText()` has 31 INFERRED edges - model-reasoned connections that need verification._
- **Are the 11 inferred relationships involving `WeintCodex.Navigation.SetInspector()` (e.g. with `WeintCodex.SetDetailShown()` and `CreateCalendarFrame()`) actually correct?**
  _`WeintCodex.Navigation.SetInspector()` has 11 INFERRED edges - model-reasoned connections that need verification._
- **Are the 8 inferred relationships involving `WeintCodex.ShowHome()` (e.g. with `WeintCodex.CreateButton()` and `WeintCodex.CreateMeter()`) actually correct?**
  _`WeintCodex.ShowHome()` has 8 INFERRED edges - model-reasoned connections that need verification._