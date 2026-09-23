# Graph Report - Codex-Forever  (2026-09-22)

## Corpus Check
- 4 files · ~162,137 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 1006 nodes · 1897 edges · 56 communities (42 shown, 14 thin omitted)
- Extraction: 79% EXTRACTED · 21% INFERRED · 0% AMBIGUOUS · INFERRED: 401 edges (avg confidence: 0.86)
- Token cost: 92,036 input · 0 output

## Community Hubs (Navigation)
- Navigationsspalte und Seitenwechsel
- Gruppencheck und Datenintegrität
- UI-Bausteine und Fensterrahmen
- Schlachtzüge und Bosslisten
- Kalender, Anmeldung, Namen
- Client-Attrappe wow_stub
- LibDBIcon (Minimap-Knopf)
- Fassungsgeschichte der Edition
- Companion-Brücke
- Start, Einführung, Suche
- Release und Patchnotes
- Zugriffsprofile (access.lua)
- Gerechnete Seitenmaße
- Einstellungen und Minimap
- Charakterseite und Spezialisierungen
- Rollen, Tipps, Bot-Daten
- Dungeonseite (dungeonpages.lua)
- CI-Workflows und Prüfschritte
- Dungeonseite in drei Ebenen
- Rollenrahmen (roles.lua)
- Kartenflächen und Textbausteine
- Dungeonbestand Forever
- CHANGELOG-Abschnitte
- Detailbereich und Herkunftsvorsatz
- Kein Bestand ohne Herkunft
- Fensteraufbau und Unternavigation
- Ökosystem der drei Repos
- Datenverträge und Routing
- Dungeonbestand Classic
- Kopflose Prüfläufe
- Was ein grüner Lauf heisst
- Kontextkarte und zwei Zustände
- Designsprache Graphit
- Markenzeichen (logo.png)
- Bosskarten und Textmaße
- Herkunftsarten (sources.lua)
- Einführung und Update-Popup
- CLAUDE.md als Router
- Button-Icon (button.png)
- Vier Zustände einer Bossliste
- Lockouts und Fortschritt
- Beschwörbare Zusatzbosse
- Rollenfarben
- UTF-8 gegen Lua-Bytefunktionen
- Fassung 5.2.0.1
- Fassung 5.2.0.3
- Dungeonbosse sind community
- specs.lua spiegelt specs.py
- RaidPages.Select

## God Nodes (most connected - your core abstractions)
1. `WeintCodex.ColorText()` - 32 edges
2. `WeintCodex.Navigation.SetInspector()` - 25 edges
3. `WeintCodex.ShowHome()` - 24 edges
4. `CreateCalendarFrame()` - 20 edges
5. `WeintCodex.Access.Can()` - 19 edges
6. `WeintCodex.Eyebrow()` - 19 edges
7. `Datenintegrität: `unknown` ist nicht `0`` - 18 edges
8. `Col()` - 17 edges
9. `WeintCodex.CreateSurface()` - 17 edges
10. `DrawBosses()` - 17 edges

## Surprising Connections (you probably didn't know these)
- `Tatsachenband (Wert über Rubrik)` --semantically_similar_to--> `GridLayout()`  [INFERRED] [semantically similar]
  docs/systems/dungeons.md → modules/dungeonpages.lua
- `Technisch` --references--> `BuildColumn()`  [INFERRED]
  CHANGELOG.md → core/navigation.lua
- `[5.2.0.5] – 2026-09-22` --references--> `GridLayout()`  [INFERRED]
  CHANGELOG.md → modules/dungeonpages.lua
- `Technisch` --references--> `HintFits()`  [INFERRED]
  CHANGELOG.md → modules/dungeonpages.lua
- `Technisch` --references--> `BuildColumn()`  [INFERRED]
  CHANGELOG.md → core/navigation.lua

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Die Fassung steht an vier Stellen und wird vor jedem Release geprüft** — docs_development_releases_vier_stellen, docs_development_releases_versionspruefung, claude_version_in_three_places, docs_systems_onboarding_changelog_update_popup, _github_workflows_ci_fassungsangaben, changelog_keep_a_changelog_format [EXTRACTED 1.00]
- **Brand mark composition: crest, props, frame, wordmark, tagline** — media_logo_alliance_lion_crest, media_logo_codex_props_tome_scroll_lantern, media_logo_ornate_frame_banner, media_logo_wordmark_weintcodex, media_logo_tagline_raid_guide_intelligence_system [EXTRACTED 1.00]
- **Nichts muss scrollen — Budgets, Messfunktionen und die Seiten, die sie einhalten** — docs_architecture_overview_nichts_muss_scrollen, docs_architecture_overview_measuresidebar, _github_tests_readme_nichts_muss_scrollen, docs_systems_raids_and_progress_bossliste_links [EXTRACTED 1.00]
- **Design constraints the artwork satisfies** — media_logo_purple_gold_accent_palette, media_logo_transparent_wide_banner_format, media_logo_brand_identity_weint_ecosystem, media_logo_weintcodex_logo [INFERRED 0.75]
- **Markenzeichen des Addons: Monogramm, Farbpaar, Icon-Lesbarkeit** — media_button_icon, media_button_wc_monogram, media_button_purple_accent, media_button_green_secondary, media_button_small_size_legibility [INFERRED 0.85]
- **Die Dungeonseite: drei Ebenen in fester Reihenfolge** — docs_systems_dungeons_die_seite_drei_ebenen_zwei_zustände, docs_systems_dungeons_kopfkarte, docs_systems_dungeons_tatsachenband, docs_systems_dungeons_bossraster, docs_systems_dungeons_kontextkarte, docs_systems_dungeons_gewichtung [EXTRACTED 1.00]
- **Herkunftsmodell: fünf Arten, ein Vorsatz, eine Begründung** — docs_systems_dungeons_fünf_arten_von_herkunft, docs_systems_dungeons_beta_vs_community, docs_systems_dungeons_herkunft_einmal_sichtbar, data_sources_kinds, data_sources_why, data_sources_prefix, data_sources_label [EXTRACTED 1.00]
- **Gerechnetes Layoutbudget statt gemessener Pixel** — docs_systems_dungeons_die_spalte_läuft_nicht_über_und_die_seite_auch_nicht, docs_systems_dungeons_texthoehen_geschaetzt, core_ui_paragraph, modules_dungeonpages_pagebudget, modules_dungeonpages_pageheight, modules_dungeonpages_gridlayout, modules_dungeonpages_gridcardheight, github_tests_load_test [EXTRACTED 1.00]

## Communities (56 total, 14 thin omitted)

### Community 0 - "Navigationsspalte und Seitenwechsel"
Cohesion: 0.06
Nodes (54): ApplyItemDisplay(), BuildColumn(), BuildStrip(), Can(), ClearContentPanel(), CreateItemRow(), DateKey(), EnsureSubNavColumn() (+46 more)

### Community 1 - "Gruppencheck und Datenintegrität"
Cohesion: 0.05
Nodes (52): Fassung 5.2.0.0 — sechs Zustände, data/sources.lua, 29 Instanzen, unknown ≠ 0 ≠ false ≠ provisional (Invariante), WeintCodex.Navigation.ActivateFirst(), WeintCodex.CreateCard(), Datenintegrität: `unknown` ist nicht `0`, Der Ausrüstungsstand an die Companion (`modules/companion.lua`), Der Gruppencheck (`modules/groupcheck.lua`), Der vierte Zustand ist mit 5.1.0.0 dazugekommen (+44 more)

### Community 2 - "UI-Bausteine und Fensterrahmen"
Cohesion: 0.07
Nodes (40): Ellipsis(), WeintCodex.Navigation.RefreshAccount(), ApplyHorizontalGradient(), ApplySavedWindow(), ApplyVerticalGradient(), Col(), DrawBorder(), DrawHLine() (+32 more)

### Community 3 - "Schlachtzüge und Bosslisten"
Cohesion: 0.08
Nodes (43): WeintCodex.RaidData.All(), WeintCodex.RaidData.BossesConfirmed(), WeintCodex.RaidData.BossListState(), WeintCodex.RaidData.BossSource(), WeintCodex.RaidData.BossSourceLabel(), WeintCodex.RaidData.Get(), WeintCodex.RaidData.HasBosses(), WeintCodex.RaidData.KnownBossCount() (+35 more)

### Community 4 - "Kalender, Anmeldung, Namen"
Cohesion: 0.09
Nodes (42): WeintCodex.Names.Equal(), WeintCodex.Names.Match(), WeintCodex.Names.Normalize(), WeintCodex.Names.Split(), WeintCodex.Icon(), AddPlayers(), AlternateInviteName(), CreateCalendarFrame() (+34 more)

### Community 5 - "Client-Attrappe wow_stub"
Cohesion: 0.05
Nodes (7): M.Install(), Methods:CreateAnimation(), Methods:CreateAnimationGroup(), Methods:CreateFontString(), Methods:CreateTexture(), Methods:GetThumbTexture(), NewObject()

### Community 6 - "LibDBIcon (Minimap-Knopf)"
Cohesion: 0.05
Nodes (11): createButton(), getAnchors(), lib:Refresh(), lib:Register(), lib:SetButtonRadius(), lib:SetButtonToPosition(), lib:Show(), onEnter() (+3 more)

### Community 7 - "Fassungsgeschichte der Edition"
Cohesion: 0.05
Nodes (40): Fassung 5.0.0.0 — Forever Edition, entstanden durch Wegnehmen, Fassung 5.2.0.6 — Kopfkarte, Tatsachenband, Bosskarten mit Kartenverlauf, Durch Wegnehmen entstanden, nicht durch Neubau, Was diese Fassung bewusst nicht hat (Sims, Sockel, WeakAuras, BiS, Bilder), CreateSurface, WeintCodex.PageHead, DungeonData.AllInstances, DungeonData.FitsLevel (+32 more)

### Community 8 - "Companion-Brücke"
Cohesion: 0.08
Nodes (37): WeintCodex.Access.Init(), OnEvent(), WeintCodex.Names.Me(), `character_sheet` — was leer bleibt, und warum, Die Companion-Brücke, Die Reihenfolge in `ProcessQueue`, Die Seite *Companion*, Versionssperren (+29 more)

### Community 9 - "Start, Einführung, Suche"
Cohesion: 0.11
Nodes (34): Open(), A(), AddButton(), BuildVisibleSteps(), ClearButtons(), CollectChangelogSince(), CreateButton(), Dismiss() (+26 more)

### Community 10 - "Release und Patchnotes"
Cohesion: 0.06
Nodes (35): `ci.yml` — bei jedem Push, Der Patchnote-Stil, Die Kurzfassung, Die Schnittstellennummer, Die Schreibweise des Tags zählt buchstäblich, Die vier Stellen, und warum sie geprüft werden, Ein Release schneiden, `manual-release.yml` — der übliche Weg (+27 more)

### Community 11 - "Zugriffsprofile (access.lua)"
Cohesion: 0.18
Nodes (32): CopyFeatures(), CopyStrings(), EnsureBadge(), Mark(), NormalizeId(), Row(), Say(), Stamp() (+24 more)

### Community 12 - "Gerechnete Seitenmaße"
Cohesion: 0.07
Nodes (26): ActivateIndex, Navigation.BuildSidebar, ContentBudgetWidth, WeintCodex.EstimateLines, WeintCodex.Paragraph, DungeonData.Brackets, Das Bild, Der Detailbereich (+18 more)

### Community 13 - "Einstellungen und Minimap"
Cohesion: 0.14
Nodes (26): GetDB(), ToggleAddon(), WeintCodex.Minimap.IsShown(), WeintCodex.Minimap.SetShown(), WeintCodex.Navigation.ActivateIndex(), WeintCodex.Navigation.CurrentTab(), WeintCodex.SetBreadcrumb(), Buttons() (+18 more)

### Community 14 - "Charakterseite und Spezialisierungen"
Cohesion: 0.12
Nodes (28): WeintCodex.CreateToggle(), WeintCodex.Specs.ByIndex(), WeintCodex.Specs.ByName(), WeintCodex.Specs.ForClass(), WeintCodex.Specs.Key(), Die Spezialisierung (`data/specs.lua`, `modules/charakter.lua`), Charakter: Ausrüstung und Twinks, Die Ausrüstungsplätze kommen vom Client (+20 more)

### Community 15 - "Rollen, Tipps, Bot-Daten"
Cohesion: 0.13
Nodes (23): WeintCodex.Truncate, Roles.Frame, Roles.Specs, Die Rollen, Die Tipps kommen vom Bot, oder gar nicht, Dungeon: die Detailkarte rollt, gekürzt wird nichts, Farben, Rollen: drei Bestände, nie zusammengezogen (+15 more)

### Community 16 - "Dungeonseite (dungeonpages.lua)"
Cohesion: 0.14
Nodes (21): Measure(), AvailableHeight(), BuildPage(), CellRule(), CellWidth(), ContentBudget(), DrawCell(), DrawHead() (+13 more)

### Community 17 - "CI-Workflows und Prüfschritte"
Cohesion: 0.14
Nodes (21): data_test.lua — Datentabellen und Fassungsangaben, CI-Schritt Fassungsangaben (Version aus der .toc gegen release_notes.py), CI-Workflow „Prüfen" (Job pruefen), Erste Stufe: luac5.1 -p über core/data/modules/.github/tests, Addon-Ordner bauen (rsync mit Ausschlussliste), Workflow „Release auf Knopfdruck" (Job release), tag/notes nur über env — keine direkte ${{ inputs }}-Interpolation, Ein vom GITHUB_TOKEN erstelltes Release löst release.yml nicht aus (+13 more)

### Community 18 - "Dungeonseite in drei Ebenen"
Cohesion: 0.12
Nodes (21): Fassung 5.2.0.5 — Dungeonseite in drei Ebenen neu gelegt, WeintCodex.Chip, DungeonData.Wings, Den Mechanismus prüfen, nicht den Bestand, Bossraster aus Karten (Ebene 2), Der Dungeonkontext steht in einer Zeile, Die eigene Stufe, Die Herkunft steht in jedem Zustand genau einmal sichtbar (+13 more)

### Community 19 - "Rollenrahmen (roles.lua)"
Cohesion: 0.16
Nodes (12): TipsAllowed(), WeintCodex.Roles.Frame(), WeintCodex.Roles.FrameLabel(), WeintCodex.Roles.HasTips(), WeintCodex.Roles.Short(), WeintCodex.Roles.SpecCount(), WeintCodex.Roles.Specs(), WeintCodex.Roles.TippedBossCount() (+4 more)

### Community 20 - "Kartenflächen und Textbausteine"
Cohesion: 0.21
Nodes (17): WeintCodex.CreateSurface(), WeintCodex.Eyebrow(), WeintCodex.Label(), WeintCodex.Paragraph(), WeintCodex.ShowExportDialog(), BodyHeading(), BodyText(), ClearRows() (+9 more)

### Community 21 - "Dungeonbestand Forever"
Cohesion: 0.20
Nodes (7): D.BossCount(), D.BossesComplete(), D.BossesConfirmed(), D.BossSource(), D.BossSourceLabel(), D.HasBosses(), D.OrderKnown()

### Community 22 - "CHANGELOG-Abschnitte"
Cohesion: 0.14
Nodes (13): [5.0.0.0] – 2026-09-18, [5.1.0.0] – 2026-09-20, [5.2.0.0] – 2026-09-21, [5.2.0.1] – 2026-09-21, [5.2.0.2] – 2026-09-21, [5.2.0.4] – 2026-09-22, [5.2.0.5] – 2026-09-22, Changelog (+5 more)

### Community 23 - "Detailbereich und Herkunftsvorsatz"
Cohesion: 0.21
Nodes (13): [5.2.0.3] – 2026-09-21, Technisch, Critical invariants (always relevant, keep in mind for any change), InspectorRows(), Navigation.SetInspector, Sources.Label, Sources.Prefix, Der Detailbereich rechts, wo er passt (+5 more)

### Community 24 - "Kein Bestand ohne Herkunft"
Cohesion: 0.17
Nodes (11): Kein Bestand ohne Herkunft (Invariante), Kein Bestand ohne Herkunft (Datenintegrität), Alle Client-Aufrufe sind defensiv, Der Bestand, Die Bossliste steht links, nicht in der Seite, Die Bosslisten: zwei vorläufig, eine leer, Die vier Bestände der Seite, Herkunft ist Pflicht (+3 more)

### Community 25 - "Fensteraufbau und Unternavigation"
Cohesion: 0.18
Nodes (11): Fassung 5.2.0.2 — Gruppenkopf der Unternavigation, Fassung 5.2.0.4 — zweite Zeile der Unternavigation nicht mehr gesperrt, Der Detailbereich (Navigation.SetInspector, Blocktypen), Fensteraufbau: Titelleiste, Navigation 232, ContentPanel, Detailbereich 372, status nimmt String oder { text, color } — die stille leere Zeile, Die Unternavigation (BuildSidebar, Reiterleiste oder Listenspalte), Die zweite Zeile ist ein Wert, keine Rubrik — seit 5.2.0.4 nicht gesperrt, Die Bossliste steht links, nicht in der Seite — zweistufiger Baum (+3 more)

### Community 26 - "Ökosystem der drei Repos"
Cohesion: 0.18
Nodes (11): Das Addon spricht nie direkt mit Netz, Bot oder Companion, Companion-Forever (Desktop, verbindlicher Ort jedes Datenvertrags), WeintCodex Bot (Discord), WeintCodex — Forever Edition (das Ingame-Addon), „Wilder Kampf" trägt absichtlich keine Rolle, CurrentSpec() — drei Wege, am Ende ein ehrliches nil, GetProfileKey() — CLASSFILE_ENGLISCHERBAUM für die Brücke, Twinks (+3 more)

### Community 27 - "Datenverträge und Routing"
Cohesion: 0.22
Nodes (11): Task-Routing-Tabelle — CLAUDE.md ist ein Router, keine Wissensbasis, Der Patchnote-Stil — drei Regeln, Abschnitt „### Technisch" — für Entwickler, vom Popup nicht gelesen, SavedVariables-Rückschreiben vernichtet, was die Companion dazwischen schrieb, Live-Brücke data/companion_live.lua und lastStamp, ProcessInbox() — Inbox und Live-Datei zusammengeführt, ProcessQueue — access_profile zuerst, dann alles andere mit Herkunftsprüfung, Die Einführung — elf Seiten in fünf Kapiteln, TOUR_EDITION (+3 more)

### Community 28 - "Dungeonbestand Classic"
Cohesion: 0.24
Nodes (4): D.AllInstances(), D.AllSummonable(), D.BracketIndexOf(), D.Brackets()

### Community 29 - "Kopflose Prüfläufe"
Cohesion: 0.22
Nodes (10): Methods:Click in der Attrappe — ein Klick zeichnet wirklich, load_test.lua — Ladeprüfung gegen die Client-Attrappe, Kein Zugriff auf ein Modul, das es nicht gibt, Budgetprüfung: nichts muss scrollen (780 px), WeintCodex.SavedData zeigt auf dieselbe Tabelle, nie auf eine Ersatztabelle, wow_stub.lua — bewusst dumme Client-Attrappe, WeintCodex.toc-Ladereihenfolge ist der einzige Abhängigkeitsmechanismus, MeasureSidebar / NavColumnHeight / SubNavHeight / Budgets (+2 more)

### Community 30 - "Was ein grüner Lauf heisst"
Cohesion: 0.20
Nodes (10): Ein grüner Lauf heisst „es lädt", nicht „es funktioniert", `data_test.lua`, Die Attrappe klickt jetzt wirklich (seit 5.2.0.0), Kopflose Prüfläufe, `load_test.lua`, Warum es sie gibt, Was der Lauf seit 5.2.0.0 zusätzlich misst, Was diese Läufe **nicht** leisten (+2 more)

### Community 31 - "Kontextkarte und zwei Zustände"
Cohesion: 0.22
Nodes (10): DungeonData.IsLegacy, BESONDERHEITEN ist abgeleitet, nicht erfunden, Kontextkarte (Ebene 3), Zwei Zustände, eine Struktur (Raster bleibt stehen), Zwei Zustände, eine Struktur, CompletenessLine(), DetailCard(), FactEntries() (+2 more)

### Community 32 - "Designsprache Graphit"
Cohesion: 0.22
Nodes (10): ApplyVerticalGradient — SetGradient läuft von unten nach oben, ColorText und unbekannte Farbnamen — alte Namen bleiben bestehen, CutCorners — Viertelkreis-Masken statt border-radius, Ein Akzent (#7C6CFF), und er trägt ausschliesslich Bedeutung, Jeder Farbwert lebt in core/ui.lua (Übersetzung von tokens.py), Designsprache „Graphit", Tiefe durch Schichtung: sunken < base < card < raised, Zwei Hervorhebungen, zwei Bedeutungen (A = anklickbar, E = betont) (+2 more)

### Community 33 - "Markenzeichen (logo.png)"
Cohesion: 0.42
Nodes (9): Alliance Lion Crest Emblem, Weint Brand Identity (shared across Codex, Companion, Bot), Codex Props: Tome, Scroll, Lantern, Quill, Ornate Gold Banner Frame with Gem Finials, Purple/Gold/Green Accent Palette, Tagline: RAID GUIDE & INTELLIGENCE SYSTEM, Wide Transparent PNG Banner Format, WeintCodex Logo (Banner Artwork) (+1 more)

### Community 34 - "Bosskarten und Textmaße"
Cohesion: 0.39
Nodes (8): PlainText(), WeintCodex.EstimateLines(), WeintCodex.Utf8Len(), BossCard(), BossTag(), CardEdge(), DrawBosses(), GhostCard()

### Community 35 - "Herkunftsarten (sources.lua)"
Cohesion: 0.46
Nodes (7): S.IsConfirmed(), S.IsValid(), S.Label(), S.Prefix(), S.Rank(), S.Weaker(), S.Why()

### Community 36 - "Einführung und Update-Popup"
Cohesion: 0.25
Nodes (7): Beim Release, Das Update-Popup, Die Einführung, Die Regeln für jeden Text, Einführung und Update-Popup, Was diese Tour zusätzlich sagt, Zwei Hervorhebungen, zwei Bedeutungen

### Community 37 - "CLAUDE.md als Router"
Cohesion: 0.29
Nodes (5): Development workflow, Role in the ecosystem, Task routing — read only what the task needs, What this edition deliberately does not have, What this is

### Community 39 - "Button-Icon (button.png)"
Cohesion: 0.43
Nodes (7): Absoluter Medienpfad Interface/AddOns/WeintCodex/media, Grüner Sekundärton des W, WeintCodex Button Icon (button.png), Minimap-/Einstiegsschaltfläche des Addons, Violetter Akzent als einzige bedeutungstragende Farbe, Lesbarkeit auf Icon-Größe (dunkler Rahmen, hoher Kontrast), WC-Monogramm (Markenzeichen)

### Community 40 - "Vier Zustände einer Bossliste"
Cohesion: 0.33
Nodes (6): Fassung 5.1.0.0 — vierter Zustand „vorläufig", Beta-Client-Bosslisten, ## Interface: 120000 — eine benannte Vermutung an genau einer Stelle, BossesConfirmed() — nur kind == "release" gilt als bestätigt, Sources.Weaker — im Zweifel die schwächere Quelle, BossListState() — none/provisional/partial/confirmed, Ton und Text, bossSource — Herkunft ist Pflicht (Beta-Client 1.60.1.69876)

### Community 41 - "Lockouts und Fortschritt"
Cohesion: 0.33
Nodes (6): Defensive Client-Aufrufe (Safe/SafeCall, pcall) — im Zweifel stirbt der Aufruf, Der Fortschritt, modules/encounter_tracking.lua — Lockout-API plus eigenes ENCOUNTER_END, Der Fortschritt gehört dem Charakter, nicht dem Konto (bestTries neben bosses), `SavedLockouts()`, Die vier unabhängigen Bestände der Schlachtzugseite

### Community 42 - "Beschwörbare Zusatzbosse"
Cohesion: 0.40
Nodes (5): DungeonData.AllSummonable, DungeonData.SummonableBosses, DungeonData.SUMMONING, Beschwörbare Zusatzbosse (elf im ganzen Spiel), Spieler beschwören (Hexenmeister, keine Rufsteine)

## Ambiguous Edges - Review These
- `Purple/Gold/Green Accent Palette` → `Wide Transparent PNG Banner Format`  [AMBIGUOUS]
  media/logo.png · relation: conceptually_related_to

## Knowledge Gaps
- **115 isolated node(s):** `Beschwörbare Zusatzbosse`, `Bilder: keine, und warum`, `Die Navigationsspalte selbst`, `Die neun von Forever`, `Die Spalte links` (+110 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 304 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **14 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What is the exact relationship between `Purple/Gold/Green Accent Palette` and `Wide Transparent PNG Banner Format`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **Why does `Kopflose Prüfläufe` connect `Was ein grüner Lauf heisst` to `CI-Workflows und Prüfschritte`, `Release und Patchnotes`, `Datenverträge und Routing`, `Kopflose Prüfläufe`?**
  _High betweenness centrality (0.114) - this node is a cross-community bridge._
- **Why does `Die Seite: drei Ebenen, zwei Zustände` connect `Dungeonseite in drei Ebenen` to `Fassungsgeschichte der Edition`, `Gerechnete Seitenmaße`, `Kontextkarte und zwei Zustände`, `Detailbereich und Herkunftsvorsatz`?**
  _High betweenness centrality (0.112) - this node is a cross-community bridge._
- **Why does `load_test.lua — Ladeprüfung gegen die Client-Attrappe` connect `Kopflose Prüfläufe` to `Designsprache Graphit`, `CI-Workflows und Prüfschritte`, `Dungeonseite in drei Ebenen`, `Was ein grüner Lauf heisst`?**
  _High betweenness centrality (0.102) - this node is a cross-community bridge._
- **Are the 31 inferred relationships involving `WeintCodex.ColorText()` (e.g. with `Row()` and `Warn()`) actually correct?**
  _`WeintCodex.ColorText()` has 31 INFERRED edges - model-reasoned connections that need verification._
- **Are the 10 inferred relationships involving `WeintCodex.Navigation.SetInspector()` (e.g. with `WeintCodex.SetDetailShown()` and `CreateCalendarFrame()`) actually correct?**
  _`WeintCodex.Navigation.SetInspector()` has 10 INFERRED edges - model-reasoned connections that need verification._
- **Are the 8 inferred relationships involving `WeintCodex.ShowHome()` (e.g. with `WeintCodex.CreateButton()` and `WeintCodex.CreateMeter()`) actually correct?**
  _`WeintCodex.ShowHome()` has 8 INFERRED edges - model-reasoned connections that need verification._