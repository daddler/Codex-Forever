# Graph Report - Codex-Forever  (2026-09-23)

## Corpus Check
- 56 files · ~168,139 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 35 file(s) not represented in the graph (top: .tga 12, .ttf 10, .blp 7)

## Summary
- 1021 nodes · 2011 edges · 58 communities (43 shown, 15 thin omitted)
- Extraction: 77% EXTRACTED · 23% INFERRED · 0% AMBIGUOUS · INFERRED: 470 edges (avg confidence: 0.86)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `5d35967b`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- dungeonpages.lua
- navigation.lua
- calendar.lua
- access.lua
- encounter_tracking.lua
- companion.lua
- settings.lua
- charakter.lua
- core/ui.lua (Flächen und Bausteine)
- ui.lua
- WeintCodex.Paragraph / EstimateLines (geschätzte Texthöhen)
- groupcheck.lua
- Dungeons und Rollen
- Die Seite: drei Ebenen, zwei Zustände
- Changelog
- 5.2.0.0 — Zwanzig klassische Dungeons, fünf Herkunftsarten
- Rollen: drei Bestände, nie zusammengezogen
- data_test.lua — Datentabellen und Fassungsangaben
- search.lua
- make_artwork.py
- release_notes.py
- 5.0.0.0 — WeintCodex für Forever
- BuildSidebar (Unternavigation)
- load_test.lua
- WeintCodex — Forever Edition
- bossSource — Herkunft ist Pflicht (Beta-Client 1.60.1.69876)
- Kopflose Prüfläufe
- 5.2.0.6 — Die Gestalt zur Ordnung
- Oberfläche: Aufbau und Designsprache „Graphit"
- Ein Release schneiden
- Schlachtzüge, Bosse und Fortschritt
- Workflow „Addon packen und ans Release hängen" (Job build)
- WeintCodex Logo (Banner Artwork)
- load_test.lua — Ladeprüfung gegen die Client-Attrappe
- Die Einführung
- data_test.lua
- updatePosition
- CLAUDE.md
- NewObject
- WeintCodex Button Icon (button.png)
- Live-Brücke data/companion_live.lua und lastStamp
- spelling_problem
- getAnchors
- Vierteiliges Versionsschema MAJOR.MINOR.PATCH.BUILD
- IBM Plex unter SIL Open Font License 1.1
- Was der Client beantworten kann, wird nie abgeleitet
- Nie in eine frische Ersatztabelle statt WeintCodex_SavedData schreiben
- data/specs.lua ist die Spiegelung von analyzer/data/specs.py
- RaidPages.Select(raidId, bossId) — von aussen auf einen Boss zeigen

## God Nodes (most connected - your core abstractions)
1. `WeintCodex.ColorText()` - 32 edges
2. `WeintCodex.Navigation.SetInspector()` - 26 edges
3. `WeintCodex.ShowHome()` - 24 edges
4. `DrawBosses()` - 21 edges
5. `CreateCalendarFrame()` - 20 edges
6. `WeintCodex.Eyebrow()` - 19 edges
7. `WeintCodex.Access.Can()` - 19 edges
8. `Col()` - 17 edges
9. `WeintCodex.CreateSurface()` - 17 edges
10. `WeintCodex.Access.Print()` - 16 edges

## Surprising Connections (you probably didn't know these)
- `[5.2.0.5] – 2026-09-22` --references--> `GridLayout()`  [INFERRED]
  CHANGELOG.md → modules/dungeonpages.lua
- `Die Spaltenzahl ist gerechnet, nicht gesetzt` --references--> `PlaceGrid()`  [INFERRED]
  docs/systems/dungeons.md → modules/dungeonpages.lua
- `Technisch` --references--> `HintFits()`  [INFERRED]
  CHANGELOG.md → modules/dungeonpages.lua
- `Zwei Zustände, eine Struktur` --references--> `HintFits()`  [INFERRED]
  docs/systems/dungeons.md → modules/dungeonpages.lua
- `Technisch` --references--> `BuildColumn()`  [INFERRED]
  CHANGELOG.md → core/navigation.lua

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Dungeonseite: drei Ebenen und der weichende Detailbereich** — docs_systems_dungeons_headcard, docs_systems_dungeons_boss_grid, docs_systems_dungeons_context_card, docs_systems_dungeons_inspector_fallback, docs_systems_dungeons_die_seite_drei_ebenen_zwei_zustände [EXTRACTED 1.00]
- **Die Fassung steht an vier Stellen und wird vor jedem Release geprüft** — docs_development_releases_vier_stellen, docs_development_releases_versionspruefung, docs_systems_onboarding_changelog_update_popup, _github_workflows_ci_fassungsangaben [EXTRACTED 1.00]
- **Brand mark composition: crest, props, frame, wordmark, tagline** — media_logo_alliance_lion_crest, media_logo_codex_props_tome_scroll_lantern, media_logo_ornate_frame_banner, media_logo_wordmark_weintcodex, media_logo_tagline_raid_guide_intelligence_system [EXTRACTED 1.00]
- **Höhenbudget: gerechnet statt geschätzt, in Spiel und Prüflauf gleich** — claude_nothing_must_scroll, docs_architecture_overview_measuresidebar, docs_architecture_overview_paragraph, docs_systems_dungeons_page_budget, docs_systems_dungeons_gridcardheight, docs_systems_dungeons_layoutwidth, claude_offline_test_harness [EXTRACTED 1.00]
- **Herkunftsmodell: keine Zeile ohne benennbare Quelle** — claude_kein_bestand_ohne_herkunft, docs_systems_dungeons_sources, docs_systems_dungeons_beta_vs_community, docs_systems_dungeons_boss_list_states, docs_systems_dungeons_die_herkunft_steht_in_jedem_zustand_genau_einmal_sichtbar, claude_nobody_read_the_client [EXTRACTED 1.00]
- **Design constraints the artwork satisfies** — media_logo_purple_gold_accent_palette, media_logo_transparent_wide_banner_format, media_logo_brand_identity_weint_ecosystem, media_logo_weintcodex_logo [INFERRED 0.75]
- **Markenzeichen des Addons: Monogramm, Farbpaar, Icon-Lesbarkeit** — media_button_icon, media_button_wc_monogram, media_button_purple_accent, media_button_green_secondary, media_button_small_size_legibility [INFERRED 0.85]

## Communities (58 total, 15 thin omitted)

### Community 0 - "dungeonpages.lua"
Cohesion: 0.05
Nodes (89): Technisch, Critical invariants (always relevant, keep in mind for any change), ApplyVerticalGradient(), Spaced(), Utf8CharLen(), WeintCodex.Artwork(), WeintCodex.CreateSurface(), WeintCodex.EstimateLines() (+81 more)

### Community 1 - "navigation.lua"
Cohesion: 0.05
Nodes (63): ApplyItemDisplay(), BuildColumn(), BuildStrip(), Can(), ClearContentPanel(), CreateItemRow(), DateKey(), Ellipsis() (+55 more)

### Community 2 - "calendar.lua"
Cohesion: 0.10
Nodes (38): WeintCodex.Names.Equal(), WeintCodex.Names.Match(), WeintCodex.Names.Normalize(), WeintCodex.Names.Split(), AddPlayers(), AlternateInviteName(), CreateCalendarFrame(), DiscardDraft() (+30 more)

### Community 3 - "access.lua"
Cohesion: 0.12
Nodes (44): CopyFeatures(), CopyStrings(), EnsureBadge(), Mark(), NormalizeId(), Row(), Say(), Stamp() (+36 more)

### Community 4 - "encounter_tracking.lua"
Cohesion: 0.07
Nodes (58): WeintCodex.Names.ClassLabel(), WeintCodex.RaidData.All(), WeintCodex.RaidData.BossesConfirmed(), WeintCodex.RaidData.BossListState(), WeintCodex.RaidData.BossSource(), WeintCodex.RaidData.BossSourceLabel(), WeintCodex.RaidData.Get(), WeintCodex.RaidData.HasBosses() (+50 more)

### Community 5 - "companion.lua"
Cohesion: 0.07
Nodes (42): WeintCodex.Access.Init(), OnEvent(), WeintCodex.Names.Me(), `character_sheet` — was leer bleibt, und warum, Die Companion-Brücke, Die Reihenfolge in `ProcessQueue`, Die Seite *Companion*, Versionssperren (+34 more)

### Community 7 - "settings.lua"
Cohesion: 0.13
Nodes (27): GetDB(), ToggleAddon(), WeintCodex.Minimap.IsShown(), WeintCodex.Minimap.SetShown(), WeintCodex.Navigation.ActivateIndex(), WeintCodex.Navigation.CurrentTab(), WeintCodex.CreateScrollArea(), Buttons() (+19 more)

### Community 8 - "charakter.lua"
Cohesion: 0.13
Nodes (28): WeintCodex.Label(), WeintCodex.Specs.ByIndex(), WeintCodex.Specs.ByName(), WeintCodex.Specs.ForClass(), WeintCodex.Specs.Key(), Charakter: Ausrüstung und Twinks, Die Ausrüstungsplätze kommen vom Client, Die Spezialisierung (+20 more)

### Community 10 - "core/ui.lua (Flächen und Bausteine)"
Cohesion: 0.14
Nodes (17): Verlaufs-Token washNone/washAccent/washAccentUp/washDark, Ordner und TOC müssen WeintCodex heissen, Jeder Farbwert lebt in core/ui.lua, Companion-Forever (Desktop-Brücke), Ein Akzent, und er trägt nur Bedeutung, Task-Routing-Tabelle (Router statt Wissensbasis), Weint-Ökosystem (drei Repos), WeintCodex Discord-Bot (+9 more)

### Community 11 - "ui.lua"
Cohesion: 0.06
Nodes (56): InspectorButton(), A(), AddButton(), BuildVisibleSteps(), ClearButtons(), CollectChangelogSince(), CreateButton(), Dismiss() (+48 more)

### Community 12 - "WeintCodex.Paragraph / EstimateLines (geschätzte Texthöhen)"
Cohesion: 0.17
Nodes (15): 5.2.0.1 — Eine Seite, keine vier Spalten, 5.2.0.3 — Detailbereich auf der Dungeonseite, Nichts muss scrollen — nachgerechnet, nicht geschätzt, Ein Flügel darf keinen Boss verlieren, core/navigation.lua (Spalte, SwitchTo, ShowHome, SetInspector), MeasureSidebar / NavColumnHeight / SubNavHeight / Budgets, WeintCodex.Paragraph / EstimateLines (geschätzte Texthöhen), Navigation.SetInspector (Detailbereich) (+7 more)

### Community 13 - "groupcheck.lua"
Cohesion: 0.06
Nodes (50): WeintCodex.Navigation.ActivateFirst(), Datenintegrität: `unknown` ist nicht `0`, Der Ausrüstungsstand an die Companion (`modules/companion.lua`), Der Gruppencheck (`modules/groupcheck.lua`), Der vierte Zustand ist mit 5.1.0.0 dazugekommen, Die Ausrüstung (`modules/charakter.lua`), Die Bosslisten (`data/raids.lua`, `data/dungeons.lua`), Die Materialien (`modules/materials.lua`) (+42 more)

### Community 14 - "Dungeons und Rollen"
Cohesion: 0.12
Nodes (16): Beschwörbare Zusatzbosse, Bilder: keine, und warum, Der Bestand, Die Navigationsspalte selbst, Die neun von Forever, Die Rollen, Die Spalte links, Die zwanzig aus Classic (+8 more)

### Community 15 - "Die Seite: drei Ebenen, zwei Zustände"
Cohesion: 0.17
Nodes (16): 5.2.0.4 — Vollständige Dungeonnamen in der Spalte, 5.2.0.5 — Dungeonseite neu geordnet (drei Ebenen), mark kostet der Beschriftung Breite, Bossraster aus Karten statt Pillen, Kontextkarte (zwei Spalten, rollend), Der Dungeonkontext steht in einer Zeile, Die eigene Stufe, Die Herkunft steht in jedem Zustand genau einmal sichtbar (+8 more)

### Community 16 - "Changelog"
Cohesion: 0.13
Nodes (14): [5.0.0.0] – 2026-09-18, [5.1.0.0] – 2026-09-20, [5.2.0.0] – 2026-09-21, [5.2.0.1] – 2026-09-21, [5.2.0.2] – 2026-09-21, [5.2.0.3] – 2026-09-21, [5.2.0.4] – 2026-09-22, [5.2.0.5] – 2026-09-22 (+6 more)

### Community 17 - "5.2.0.0 — Zwanzig klassische Dungeons, fünf Herkunftsarten"
Cohesion: 0.21
Nodes (14): 5.1.0.0 — Die Dungeons sind da (alle neun), 5.2.0.0 — Zwanzig klassische Dungeons, fünf Herkunftsarten, Client-Build 1.60.1.69913, Kein Bestand ohne Herkunft, Niemand hier hat den Forever-Client gelesen, Spalte BESONDERHEITEN — abgeleitet, nicht erfunden, beta vs. community — der wichtigste Unterschied, data/dungeons.lua (die neun von Forever) (+6 more)

### Community 18 - "Rollen: drei Bestände, nie zusammengezogen"
Cohesion: 0.25
Nodes (9): Rollen: drei Bestände, nie zusammengezogen, UTF-8 vs. byteweise Lua-Stringfunktionen, FormatGrouped, Spaced (Sperrung durch Haarspatien), UTF-8-Helfer (Upper/Utf8Len/Utf8Sub/Truncate), SavedData.bossData — Tipps kommen vom Bot, oder gar nicht, modules/rolepanel.lua (gemeinsame Darstellung), data/roles.lua — drei Bestände auseinanderhalten (+1 more)

### Community 19 - "data_test.lua — Datentabellen und Fassungsangaben"
Cohesion: 0.18
Nodes (14): data_test.lua — Datentabellen und Fassungsangaben, CI-Schritt Fassungsangaben (Version aus der .toc gegen release_notes.py), CI-Workflow „Prüfen" (Job pruefen), Erste Stufe: luac5.1 -p über core/data/modules/.github/tests, Leeren Release-Text aus dem Changelog nachtragen, Der Patchnote-Stil — drei Regeln, Die Schreibweise des Tags zählt buchstäblich (v.2.6.0.3-Fall), Abschnitt „### Technisch" — für Entwickler, vom Popup nicht gelesen (+6 more)

### Community 20 - "search.lua"
Cohesion: 0.26
Nodes (10): Open(), BuildIndex(), Filter(), GetRow(), GoTo(), RenderMatches(), WeintCodex.Search.CloseDropdown(), WeintCodex.Search.OnFocusGained() (+2 more)

### Community 21 - "make_artwork.py"
Cohesion: 0.18
Nodes (13): dxt1_blocks(), main(), mip_chain(), Aus einem Original-Artwork die Addon-Fassung machen: zuschneiden, skalieren,…, Eine Stufe als rohe DXT1-Bloecke. ImageMagick komprimiert, der 128 Byte grosse…, Die Kette, die media/logo.blp auch hat: halbieren, bis die Breite 4 erreicht…, BLP2, Typ 1, Kodierung 2 (DXT), ohne Alpha, mit Mipmaps. Kopf: 148 Byte, danach…, write_blp() (+5 more)

### Community 22 - "release_notes.py"
Cohesion: 0.22
Nodes (13): changelog_lua_version(), lua_version(), main(), normalize(), problems_for(), Den Changelog-Abschnitt eines Tags als Release-Text ausgeben - und nebenbei…, "v1.3.3.1", "1.3.3.1" und "1.3.3" sind vergleichbar; fehlende Stellen zaehlen…, Der oberste Eintrag in `data/changelog.lua`. Er ist das, was der Spieler nach… (+5 more)

### Community 23 - "5.0.0.0 — WeintCodex für Forever"
Cohesion: 0.21
Nodes (13): 5.0.0.0 — WeintCodex für Forever, Was diese Fassung absichtlich nicht hat, Zwei kopflose Prüfläufe als einziges Sicherheitsnetz, order nur, wo die Reihenfolge bekannt ist, WeintCodex.toc-Ladereihenfolge als einziger Abhängigkeitsmechanismus, WeintCodex.Artwork (Bild und Schleier), WeintCodex.CoverCoords, data/artwork.lua (die einzige Stelle mit Bildpfaden) (+5 more)

### Community 24 - "BuildSidebar (Unternavigation)"
Cohesion: 0.43
Nodes (7): 5.2.0.2 — Stufenabschnitte als Knöpfe erkennbar, Eine Liste steht an einer Stelle, BuildSidebar (Unternavigation), Zweite Zeile ist ein Wert, keine Rubrik, status: Text oder { text, color }, DungeonData.Brackets() (Stufenabschnitte), Anklickbarer Gruppenkopf ist kein Eintrag

### Community 25 - "load_test.lua"
Cohesion: 0.20
Nodes (6): Check(), Known(), Measure(), ScanFolder(), WeintCodex.DungeonPages.PageHeight(), WeintCodex.DungeonPages.Select()

### Community 27 - "WeintCodex — Forever Edition"
Cohesion: 0.18
Nodes (8): Befehle, Entwicklung, Funktionen, Installation, Verwandte Projekte, Was diese Fassung ist, WeintCodex — Forever Edition, Übersicht

### Community 28 - "bossSource — Herkunft ist Pflicht (Beta-Client 1.60.1.69876)"
Cohesion: 0.18
Nodes (11): ## Interface: 120000 — eine benannte Vermutung an genau einer Stelle, BossesConfirmed() — nur kind == "release" gilt als bestätigt, Kein Bestand ohne Herkunft (Datenintegrität), Sources.Weaker — im Zweifel die schwächere Quelle, BossListState() — none/provisional/partial/confirmed, Ton und Text, bossSource — Herkunft ist Pflicht (Beta-Client 1.60.1.69876), Bossnamen bleiben englisch — keine deutsche Lokalisierung veröffentlicht, data/raids.lua — drei Schlachtzüge (Barrow Deeps, Hyjal Summit, Onyxias Hort) (+3 more)

### Community 30 - "Kopflose Prüfläufe"
Cohesion: 0.20
Nodes (10): Ein grüner Lauf heisst „es lädt", nicht „es funktioniert", `data_test.lua`, Die Attrappe klickt jetzt wirklich (seit 5.2.0.0), Kopflose Prüfläufe, `load_test.lua`, Warum es sie gibt, Was der Lauf seit 5.2.0.0 zusätzlich misst, Was diese Läufe **nicht** leisten (+2 more)

### Community 31 - "5.2.0.6 — Die Gestalt zur Ordnung"
Cohesion: 0.31
Nodes (10): 5.2.0.6 — Die Gestalt zur Ordnung, 5.2.0.7 — Dieselbe Seite, anders gewichtet, PackCells (eine Packung für Band und Höhe), unknown ≠ 0 ≠ false ≠ vorläufig, WeintCodex.PageHead, Fünf Formulierungen der Bosszahl, Vier Zustände einer Bossliste, DungeonData.FitsLevel() gibt nil zurück (+2 more)

### Community 32 - "Oberfläche: Aufbau und Designsprache „Graphit""
Cohesion: 0.20
Nodes (9): Das Bild, Der Detailbereich, Der Fensteraufbau, Der Seitenkopf, Die Unternavigation, Farben ansprechen, Oberfläche: Aufbau und Designsprache „Graphit", UTF-8 (+1 more)

### Community 33 - "Ein Release schneiden"
Cohesion: 0.20
Nodes (10): `ci.yml` — bei jedem Push, Der Patchnote-Stil, Die Kurzfassung, Die Schnittstellennummer, Ein Release schneiden, `manual-release.yml` — der übliche Weg, `release.yml` — wenn ein Release von Hand angelegt wird, Vor dem Commit (+2 more)

### Community 34 - "Schlachtzüge, Bosse und Fortschritt"
Cohesion: 0.09
Nodes (22): Defensive Client-Aufrufe (Safe/SafeCall, pcall) — im Zweifel stirbt der Aufruf, „Wilder Kampf" trägt absichtlich keine Rolle, CurrentSpec() — drei Wege, am Ende ein ehrliches nil, GetProfileKey() — CLASSFILE_ENGLISCHERBAUM für die Brücke, Twinks, CompanionAtLeast() — Versionssperren gegen companionVersion, Die Companion-Brücke — Bot → HTTP → Companion → Datei → Addon, STATE_MESSAGES liegen höchstens einmal in der Warteschlange (+14 more)

### Community 35 - "Workflow „Addon packen und ans Release hängen" (Job build)"
Cohesion: 0.28
Nodes (9): Addon-Ordner bauen (rsync mit Ausschlussliste), Workflow „Release auf Knopfdruck" (Job release), tag/notes nur über env — keine direkte ${{ inputs }}-Interpolation, Ein vom GITHUB_TOKEN erstelltes Release löst release.yml nicht aus, Workflow „Addon packen und ans Release hängen" (Job build), Der Ordner im ZIP muss WeintCodex heissen (Installer der Companion), sha256-Prüfsumme neben dem ZIP, Was im ZIP landet — und warum CHANGELOG.md drinbleibt (+1 more)

### Community 36 - "WeintCodex Logo (Banner Artwork)"
Cohesion: 0.42
Nodes (9): Alliance Lion Crest Emblem, Weint Brand Identity (shared across Codex, Companion, Bot), Codex Props: Tome, Scroll, Lantern, Quill, Ornate Gold Banner Frame with Gem Finials, Purple/Gold/Green Accent Palette, Tagline: RAID GUIDE & INTELLIGENCE SYSTEM, Wide Transparent PNG Banner Format, WeintCodex Logo (Banner Artwork) (+1 more)

### Community 37 - "load_test.lua — Ladeprüfung gegen die Client-Attrappe"
Cohesion: 0.25
Nodes (8): Methods:Click in der Attrappe — ein Klick zeichnet wirklich, load_test.lua — Ladeprüfung gegen die Client-Attrappe, Kein Zugriff auf ein Modul, das es nicht gibt, Budgetprüfung: nichts muss scrollen (780 px), WeintCodex.SavedData zeigt auf dieselbe Tabelle, nie auf eine Ersatztabelle, wow_stub.lua — bewusst dumme Client-Attrappe, Nichts muss scrollen, Die Bossliste steht links, nicht in der Seite — zweistufiger Baum

### Community 39 - "Die Einführung"
Cohesion: 0.25
Nodes (7): Beim Release, Das Update-Popup, Die Einführung, Die Regeln für jeden Text, Einführung und Update-Popup, Was diese Tour zusätzlich sagt, Zwei Hervorhebungen, zwei Bedeutungen

### Community 40 - "data_test.lua"
Cohesion: 0.32
Nodes (5): Check(), CheckArt(), CheckBossList(), FeralIn(), home_fabi_claude_projekte_codex_forever_github_tests_wow_stub_lua

### Community 41 - "updatePosition"
Cohesion: 0.25
Nodes (8): createButton(), lib:Refresh(), lib:Register(), lib:SetButtonRadius(), lib:SetButtonToPosition(), lib:Show(), onUpdate(), updatePosition()

### Community 42 - "CLAUDE.md"
Cohesion: 0.29
Nodes (5): Development workflow, Role in the ecosystem, Task routing — read only what the task needs, What this edition deliberately does not have, What this is

### Community 45 - "NewObject"
Cohesion: 0.29
Nodes (7): M.Install(), Methods:CreateAnimation(), Methods:CreateAnimationGroup(), Methods:CreateFontString(), Methods:CreateTexture(), Methods:GetThumbTexture(), NewObject()

### Community 47 - "WeintCodex Button Icon (button.png)"
Cohesion: 0.43
Nodes (7): Absoluter Medienpfad Interface/AddOns/WeintCodex/media, Grüner Sekundärton des W, WeintCodex Button Icon (button.png), Minimap-/Einstiegsschaltfläche des Addons, Violetter Akzent als einzige bedeutungstragende Farbe, Lesbarkeit auf Icon-Größe (dunkler Rahmen, hoher Kontrast), WC-Monogramm (Markenzeichen)

### Community 49 - "Live-Brücke data/companion_live.lua und lastStamp"
Cohesion: 0.40
Nodes (5): SavedVariables-Rückschreiben vernichtet, was die Companion dazwischen schrieb, Live-Brücke data/companion_live.lua und lastStamp, ProcessInbox() — Inbox und Live-Datei zusammengeführt, ProcessQueue — access_profile zuerst, dann alles andere mit Herkunftsprüfung, TOUR_STEPS und das feature-Feld (gesperrte Bereiche werden ausgelassen)

### Community 50 - "spelling_problem"
Cohesion: 0.50
Nodes (4): Die Schreibweise des Tags zählt buchstäblich, Die vier Stellen, und warum sie geprüft werden, Die Zahlen stimmen - aber schreibt der Tag sie so, wie das `.toc` sie schreibt?…, spelling_problem()

### Community 53 - "getAnchors"
Cohesion: 0.67
Nodes (3): getAnchors(), onEnter(), onEnterCompartment()

## Ambiguous Edges - Review These
- `Purple/Gold/Green Accent Palette` → `Wide Transparent PNG Banner Format`  [AMBIGUOUS]
  media/logo.png · relation: conceptually_related_to

## Knowledge Gaps
- **96 isolated node(s):** `Beschwörbare Zusatzbosse`, `Bilder: keine, und warum`, `Die Navigationsspalte selbst`, `Die neun von Forever`, `Die Spalte links` (+91 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 284 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **15 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What is the exact relationship between `Purple/Gold/Green Accent Palette` and `Wide Transparent PNG Banner Format`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **Why does `Die Seite: drei Ebenen, zwei Zustände` connect `Die Seite: drei Ebenen, zwei Zustände` to `dungeonpages.lua`, `5.2.0.6 — Die Gestalt zur Ordnung`, `Dungeons und Rollen`, `5.0.0.0 — WeintCodex für Forever`?**
  _High betweenness centrality (0.132) - this node is a cross-community bridge._
- **Why does `load_test.lua — Ladeprüfung gegen die Client-Attrappe` connect `load_test.lua — Ladeprüfung gegen die Client-Attrappe` to `Workflow „Addon packen und ans Release hängen" (Job build)`, `WeintCodex.Paragraph / EstimateLines (geschätzte Texthöhen)`, `data_test.lua — Datentabellen und Fassungsangaben`, `5.0.0.0 — WeintCodex für Forever`, `Kopflose Prüfläufe`?**
  _High betweenness centrality (0.115) - this node is a cross-community bridge._
- **Why does `Kopflose Prüfläufe` connect `Kopflose Prüfläufe` to `WeintCodex — Forever Edition`, `data_test.lua — Datentabellen und Fassungsangaben`, `load_test.lua — Ladeprüfung gegen die Client-Attrappe`?**
  _High betweenness centrality (0.114) - this node is a cross-community bridge._
- **Are the 31 inferred relationships involving `WeintCodex.ColorText()` (e.g. with `Row()` and `Warn()`) actually correct?**
  _`WeintCodex.ColorText()` has 31 INFERRED edges - model-reasoned connections that need verification._
- **Are the 11 inferred relationships involving `WeintCodex.Navigation.SetInspector()` (e.g. with `WeintCodex.SetDetailShown()` and `CreateCalendarFrame()`) actually correct?**
  _`WeintCodex.Navigation.SetInspector()` has 11 INFERRED edges - model-reasoned connections that need verification._
- **Are the 8 inferred relationships involving `WeintCodex.ShowHome()` (e.g. with `WeintCodex.CreateButton()` and `WeintCodex.CreateMeter()`) actually correct?**
  _`WeintCodex.ShowHome()` has 8 INFERRED edges - model-reasoned connections that need verification._