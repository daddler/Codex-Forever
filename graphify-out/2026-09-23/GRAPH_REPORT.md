# Graph Report - Codex-Forever  (2026-09-23)

## Corpus Check
- 12 files · ~168,000 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 1021 nodes · 1954 edges · 64 communities (49 shown, 15 thin omitted)
- Extraction: 79% EXTRACTED · 21% INFERRED · 0% AMBIGUOUS · INFERRED: 413 edges (avg confidence: 0.86)
- Token cost: 62,000 input · 14,000 output

## Community Hubs (Navigation)
- UI-Kern und Bausteine
- Navigation und Seitenwechsel
- Namen und Einführungstour
- Zugriffsprofile
- Schlachtzugdaten und Rollen
- Companion-Brücke
- Minimap und Bedienelemente
- Spezialisierungen und Client-Antworten
- Designsprache Graphit und Ökosystem
- Lockouts und Encounter-Tracking
- Höhenbudget und Unternavigation
- Gruppencheck
- Dungeonsystem (Doku)
- Bossraster und Kartengeometrie
- Changelog-Einträge
- Herkunft der Bosslisten
- DungeonData-Zugriffe (Forever)
- CI, Fassungsprüfung, Patchnotes
- Hauptfenster und Suche
- Artwork-Pipeline (BLP-Bau)
- release_notes.py
- Artwork-Baustein und Bildpolitik
- Gruppencheck (Doku)
- Ladeprüfung load_test.lua
- Klassische Dungeons
- README und Entwicklungsdoku
- Datenbestand und Belegbarkeit
- Datenintegrität: unknown ≠ 0
- Kopflose Prüfläufe
- Kopfkarte und Tatsachenband
- Oberflächenaufbau (Doku)
- Release-Workflows
- Schlachtzüge und Fortschritt
- ZIP-Bau und Installation
- Markenbild WeintCodex-Logo
- Ladeprüfung: was sie misst
- Sources-Zugriffe
- Einführung und Update-Popup
- Datenprüfung data_test.lua
- LibDBIcon-Schaltfläche
- CLAUDE.md (Router)
- Charakter, Twinks, Versionssperren
- Charakterseite und Ausrüstung
- Client-Attrappe (Objektbau)
- Markenbild Button-Icon
- Defensive Client-Aufrufe
- Inbox, Live-Brücke, Warteschlange
- Tag-Schreibweise und vier Fassungsstellen
- Minimap-Anker und Hover
- Vierteiliges Versionsschema
- Schriftlizenzen
- Client-Antworten nie ableiten
- SavedVariables-Ersatztabelle
- specs.lua spiegelt specs.py
- RaidPages.Select

## God Nodes (most connected - your core abstractions)
1. `WeintCodex.ColorText()` - 32 edges
2. `WeintCodex.Navigation.SetInspector()` - 25 edges
3. `WeintCodex.ShowHome()` - 24 edges
4. `CreateCalendarFrame()` - 20 edges
5. `WeintCodex.Access.Can()` - 19 edges
6. `WeintCodex.Eyebrow()` - 19 edges
7. `Col()` - 17 edges
8. `WeintCodex.CreateSurface()` - 17 edges
9. `WeintCodex.Access.Print()` - 16 edges
10. `Datenintegrität: `unknown` ist nicht `0`` - 16 edges

## Surprising Connections (you probably didn't know these)
- `Technisch` --references--> `BuildColumn()`  [INFERRED]
  CHANGELOG.md → core/navigation.lua
- `Der Gruppencheck (`modules/groupcheck.lua`)` --references--> `AverageItemLevel()`  [INFERRED]
  docs/invariants/data-integrity.md → modules/groupcheck.lua
- `Eine unbekannte Gegenstandsstufe ist keine Null` --references--> `AverageItemLevel()`  [INFERRED]
  docs/systems/groupcheck.md → modules/groupcheck.lua
- `Die Spezialisierung` --references--> `CurrentSpec()`  [INFERRED]
  docs/systems/character.md → modules/charakter.lua
- `Die Spaltenzahl ist gerechnet, nicht gesetzt` --references--> `PlaceGrid()`  [INFERRED]
  docs/systems/dungeons.md → modules/dungeonpages.lua

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Die Fassung steht an vier Stellen und wird vor jedem Release geprüft** — docs_development_releases_vier_stellen, docs_development_releases_versionspruefung, docs_systems_onboarding_changelog_update_popup, _github_workflows_ci_fassungsangaben [EXTRACTED 1.00]
- **Brand mark composition: crest, props, frame, wordmark, tagline** — media_logo_alliance_lion_crest, media_logo_codex_props_tome_scroll_lantern, media_logo_ornate_frame_banner, media_logo_wordmark_weintcodex, media_logo_tagline_raid_guide_intelligence_system [EXTRACTED 1.00]
- **Design constraints the artwork satisfies** — media_logo_purple_gold_accent_palette, media_logo_transparent_wide_banner_format, media_logo_brand_identity_weint_ecosystem, media_logo_weintcodex_logo [INFERRED 0.75]
- **Markenzeichen des Addons: Monogramm, Farbpaar, Icon-Lesbarkeit** — media_button_icon, media_button_wc_monogram, media_button_purple_accent, media_button_green_secondary, media_button_small_size_legibility [INFERRED 0.85]
- **Dungeonseite: drei Ebenen und der weichende Detailbereich** — docs_systems_dungeons_headcard, docs_systems_dungeons_boss_grid, docs_systems_dungeons_context_card, docs_systems_dungeons_inspector_fallback, docs_systems_dungeons_die_seite_drei_ebenen_zwei_zustände [EXTRACTED 1.00]
- **Herkunftsmodell: keine Zeile ohne benennbare Quelle** — claude_kein_bestand_ohne_herkunft, docs_systems_dungeons_sources, docs_systems_dungeons_beta_vs_community, docs_systems_dungeons_boss_list_states, docs_systems_dungeons_die_herkunft_steht_in_jedem_zustand_genau_einmal_sichtbar, claude_nobody_read_the_client [EXTRACTED 1.00]
- **Höhenbudget: gerechnet statt geschätzt, in Spiel und Prüflauf gleich** — claude_nothing_must_scroll, docs_architecture_overview_measuresidebar, docs_architecture_overview_paragraph, docs_systems_dungeons_page_budget, docs_systems_dungeons_gridcardheight, docs_systems_dungeons_layoutwidth, claude_offline_test_harness [EXTRACTED 1.00]

## Communities (64 total, 15 thin omitted)

### Community 0 - "UI-Kern und Bausteine"
Cohesion: 0.05
Nodes (84): Technisch, Critical invariants (always relevant, keep in mind for any change), ApplyHorizontalGradient(), ApplySavedWindow(), ApplyVerticalGradient(), Col(), DrawBorder(), DrawHLine() (+76 more)

### Community 1 - "Navigation und Seitenwechsel"
Cohesion: 0.05
Nodes (65): ApplyItemDisplay(), BuildColumn(), BuildStrip(), Can(), ClearContentPanel(), CreateItemRow(), DateKey(), Ellipsis() (+57 more)

### Community 2 - "Namen und Einführungstour"
Cohesion: 0.07
Nodes (57): WeintCodex.Names.Equal(), WeintCodex.Names.Match(), WeintCodex.Names.Normalize(), WeintCodex.Names.Split(), A(), AddButton(), BuildVisibleSteps(), ClearButtons() (+49 more)

### Community 3 - "Zugriffsprofile"
Cohesion: 0.10
Nodes (50): CopyFeatures(), CopyStrings(), EnsureBadge(), Mark(), NormalizeId(), Row(), Say(), Stamp() (+42 more)

### Community 4 - "Schlachtzugdaten und Rollen"
Cohesion: 0.11
Nodes (41): WeintCodex.Names.ClassLabel(), WeintCodex.Navigation.ActivateIndex(), WeintCodex.Label(), WeintCodex.RaidData.All(), WeintCodex.RaidData.BossesConfirmed(), WeintCodex.RaidData.BossListState(), WeintCodex.RaidData.BossSource(), WeintCodex.RaidData.BossSourceLabel() (+33 more)

### Community 5 - "Companion-Brücke"
Cohesion: 0.08
Nodes (39): WeintCodex.Names.Me(), `character_sheet` — was leer bleibt, und warum, Die Companion-Brücke, Die Reihenfolge in `ProcessQueue`, Die Seite *Companion*, Versionssperren, Was hereinkommt, Was hinausgeht (+31 more)

### Community 7 - "Minimap und Bedienelemente"
Cohesion: 0.10
Nodes (32): GetDB(), ToggleAddon(), WeintCodex.Minimap.IsShown(), WeintCodex.Minimap.SetShown(), InspectorInput(), WeintCodex.Navigation.CurrentTab(), WeintCodex.CreateButton(), WeintCodex.CreateSlider() (+24 more)

### Community 8 - "Spezialisierungen und Client-Antworten"
Cohesion: 0.11
Nodes (32): WeintCodex.Specs.ByIndex(), WeintCodex.Specs.ByName(), WeintCodex.Specs.ForClass(), WeintCodex.Specs.Key(), Der Ausrüstungsstand an die Companion (`modules/companion.lua`), Der Gruppencheck (`modules/groupcheck.lua`), Die Ausrüstung (`modules/charakter.lua`), Die Bosslisten (`data/raids.lua`, `data/dungeons.lua`) (+24 more)

### Community 10 - "Designsprache Graphit und Ökosystem"
Cohesion: 0.10
Nodes (25): 5.0.0.0 — WeintCodex für Forever, Verlaufs-Token washNone/washAccent/washAccentUp/washDark, Ordner und TOC müssen WeintCodex heissen, Jeder Farbwert lebt in core/ui.lua, Companion-Forever (Desktop-Brücke), Ein Akzent, und er trägt nur Bedeutung, Task-Routing-Tabelle (Router statt Wissensbasis), UTF-8 vs. byteweise Lua-Stringfunktionen (+17 more)

### Community 11 - "Lockouts und Encounter-Tracking"
Cohesion: 0.16
Nodes (18): Die Client-Aufrufe, CharacterKey(), CurrentResetStamp(), EnsureFreshReset(), ForEachSavedInstance(), GetCharacterProgress(), GetInstanceStore(), IsLFR() (+10 more)

### Community 12 - "Höhenbudget und Unternavigation"
Cohesion: 0.13
Nodes (22): 5.2.0.1 — Eine Seite, keine vier Spalten, 5.2.0.2 — Stufenabschnitte als Knöpfe erkennbar, 5.2.0.3 — Detailbereich auf der Dungeonseite, Nichts muss scrollen — nachgerechnet, nicht geschätzt, Eine Liste steht an einer Stelle, Ein Flügel darf keinen Boss verlieren, BuildSidebar (Unternavigation), core/navigation.lua (Spalte, SwitchTo, ShowHome, SetInspector) (+14 more)

### Community 13 - "Gruppencheck"
Cohesion: 0.21
Nodes (18): WeintCodex.Navigation.ActivateFirst(), After(), AverageItemLevel(), BuildInspector(), ClassColorText(), CompleteCurrent(), DrawTable(), GroupUnits() (+10 more)

### Community 14 - "Dungeonsystem (Doku)"
Cohesion: 0.10
Nodes (19): Beschwörbare Zusatzbosse, Bilder: keine, und warum, Der Bestand, Die Navigationsspalte selbst, Die neun von Forever, Die Rollen, Die Spalte links, Die Tipps kommen vom Bot, oder gar nicht (+11 more)

### Community 15 - "Bossraster und Kartengeometrie"
Cohesion: 0.17
Nodes (16): 5.2.0.4 — Vollständige Dungeonnamen in der Spalte, 5.2.0.5 — Dungeonseite neu geordnet (drei Ebenen), mark kostet der Beschriftung Breite, Bossraster aus Karten statt Pillen, Kontextkarte (zwei Spalten, rollend), Der Dungeonkontext steht in einer Zeile, Die eigene Stufe, Die Herkunft steht in jedem Zustand genau einmal sichtbar (+8 more)

### Community 16 - "Changelog-Einträge"
Cohesion: 0.13
Nodes (14): [5.0.0.0] – 2026-09-18, [5.1.0.0] – 2026-09-20, [5.2.0.0] – 2026-09-21, [5.2.0.1] – 2026-09-21, [5.2.0.2] – 2026-09-21, [5.2.0.3] – 2026-09-21, [5.2.0.4] – 2026-09-22, [5.2.0.5] – 2026-09-22 (+6 more)

### Community 17 - "Herkunft der Bosslisten"
Cohesion: 0.20
Nodes (15): 5.1.0.0 — Die Dungeons sind da (alle neun), 5.2.0.0 — Zwanzig klassische Dungeons, fünf Herkunftsarten, Client-Build 1.60.1.69913, Kein Bestand ohne Herkunft, Niemand hier hat den Forever-Client gelesen, Rollen: drei Bestände, nie zusammengezogen, Spalte BESONDERHEITEN — abgeleitet, nicht erfunden, beta vs. community — der wichtigste Unterschied (+7 more)

### Community 18 - "DungeonData-Zugriffe (Forever)"
Cohesion: 0.20
Nodes (7): D.BossCount(), D.BossesComplete(), D.BossesConfirmed(), D.BossSource(), D.BossSourceLabel(), D.HasBosses(), D.OrderKnown()

### Community 19 - "CI, Fassungsprüfung, Patchnotes"
Cohesion: 0.18
Nodes (14): data_test.lua — Datentabellen und Fassungsangaben, CI-Schritt Fassungsangaben (Version aus der .toc gegen release_notes.py), CI-Workflow „Prüfen" (Job pruefen), Erste Stufe: luac5.1 -p über core/data/modules/.github/tests, Leeren Release-Text aus dem Changelog nachtragen, Der Patchnote-Stil — drei Regeln, Die Schreibweise des Tags zählt buchstäblich (v.2.6.0.3-Fall), Abschnitt „### Technisch" — für Entwickler, vom Popup nicht gelesen (+6 more)

### Community 20 - "Hauptfenster und Suche"
Cohesion: 0.23
Nodes (11): OnEvent(), Open(), BuildIndex(), Filter(), GetRow(), GoTo(), RenderMatches(), WeintCodex.Search.CloseDropdown() (+3 more)

### Community 21 - "Artwork-Pipeline (BLP-Bau)"
Cohesion: 0.18
Nodes (13): dxt1_blocks(), main(), mip_chain(), Aus einem Original-Artwork die Addon-Fassung machen: zuschneiden, skalieren,…, Eine Stufe als rohe DXT1-Bloecke. ImageMagick komprimiert, der 128 Byte grosse…, Die Kette, die media/logo.blp auch hat: halbieren, bis die Breite 4 erreicht…, BLP2, Typ 1, Kodierung 2 (DXT), ohne Alpha, mit Mipmaps. Kopf: 148 Byte, danach…, write_blp() (+5 more)

### Community 22 - "release_notes.py"
Cohesion: 0.22
Nodes (13): changelog_lua_version(), lua_version(), main(), normalize(), problems_for(), Den Changelog-Abschnitt eines Tags als Release-Text ausgeben - und nebenbei…, "v1.3.3.1", "1.3.3.1" und "1.3.3" sind vergleichbar; fehlende Stellen zaehlen…, Der oberste Eintrag in `data/changelog.lua`. Er ist das, was der Spieler nach… (+5 more)

### Community 23 - "Artwork-Baustein und Bildpolitik"
Cohesion: 0.21
Nodes (12): Was diese Fassung absichtlich nicht hat, Zwei kopflose Prüfläufe als einziges Sicherheitsnetz, order nur, wo die Reihenfolge bekannt ist, WeintCodex.toc-Ladereihenfolge als einziger Abhängigkeitsmechanismus, WeintCodex.Artwork (Bild und Schleier), WeintCodex.CoverCoords, data/artwork.lua (die einzige Stelle mit Bildpfaden), Den Mechanismus prüfen, nicht den Bestand (+4 more)

### Community 24 - "Gruppencheck (Doku)"
Cohesion: 0.18
Nodes (11): Achttausend Zeilen MoP-Bewertung entfallen — kein Satz davon ist übertragbar, AverageItemLevel() — unbekannte Stufe fällt aus dem Durchschnitt, Bedienung, Die Schlange läuft einzeln, Drei Regeln, die nicht Geschmack sind, Eine unbekannte Gegenstandsstufe ist keine Null, Gruppencheck, Die Schlange läuft einzeln (2 s Zeitüberschreitung, 0,7 s Pause) (+3 more)

### Community 25 - "Ladeprüfung load_test.lua"
Cohesion: 0.20
Nodes (6): Check(), Known(), Measure(), ScanFolder(), WeintCodex.DungeonPages.PageHeight(), WeintCodex.DungeonPages.Select()

### Community 26 - "Klassische Dungeons"
Cohesion: 0.24
Nodes (4): D.AllInstances(), D.AllSummonable(), D.BracketIndexOf(), D.Brackets()

### Community 27 - "README und Entwicklungsdoku"
Cohesion: 0.18
Nodes (8): Befehle, Entwicklung, Funktionen, Installation, Verwandte Projekte, Was diese Fassung ist, WeintCodex — Forever Edition, Übersicht

### Community 28 - "Datenbestand und Belegbarkeit"
Cohesion: 0.18
Nodes (11): ## Interface: 120000 — eine benannte Vermutung an genau einer Stelle, BossesConfirmed() — nur kind == "release" gilt als bestätigt, Kein Bestand ohne Herkunft (Datenintegrität), Sources.Weaker — im Zweifel die schwächere Quelle, BossListState() — none/provisional/partial/confirmed, Ton und Text, bossSource — Herkunft ist Pflicht (Beta-Client 1.60.1.69876), Bossnamen bleiben englisch — keine deutsche Lokalisierung veröffentlicht, data/raids.lua — drei Schlachtzüge (Barrow Deeps, Hyjal Summit, Onyxias Hort) (+3 more)

### Community 29 - "Datenintegrität: unknown ≠ 0"
Cohesion: 0.18
Nodes (10): Datenintegrität: `unknown` ist nicht `0`, Der vierte Zustand ist mit 5.1.0.0 dazugekommen, Die Regel, Im Zweifel die schwächere Quelle, Ein Posten ohne Sollbestand bekommt keinen Punkt und keinen Balken, Sechs Zustände: bestätigt, vorläufig, unvollständig, gezählt-unbenannt, umstritten, unbekannt, Sechs Zustände, nicht zwei, Wie man das prüft, wenn nichts drinsteht (+2 more)

### Community 30 - "Kopflose Prüfläufe"
Cohesion: 0.20
Nodes (10): Ein grüner Lauf heisst „es lädt", nicht „es funktioniert", `data_test.lua`, Die Attrappe klickt jetzt wirklich (seit 5.2.0.0), Kopflose Prüfläufe, `load_test.lua`, Warum es sie gibt, Was der Lauf seit 5.2.0.0 zusätzlich misst, Was diese Läufe **nicht** leisten (+2 more)

### Community 31 - "Kopfkarte und Tatsachenband"
Cohesion: 0.31
Nodes (10): 5.2.0.6 — Die Gestalt zur Ordnung, 5.2.0.7 — Dieselbe Seite, anders gewichtet, PackCells (eine Packung für Band und Höhe), unknown ≠ 0 ≠ false ≠ vorläufig, WeintCodex.PageHead, Fünf Formulierungen der Bosszahl, Vier Zustände einer Bossliste, DungeonData.FitsLevel() gibt nil zurück (+2 more)

### Community 32 - "Oberflächenaufbau (Doku)"
Cohesion: 0.20
Nodes (9): Das Bild, Der Detailbereich, Der Fensteraufbau, Der Seitenkopf, Die Unternavigation, Farben ansprechen, Oberfläche: Aufbau und Designsprache „Graphit", UTF-8 (+1 more)

### Community 33 - "Release-Workflows"
Cohesion: 0.20
Nodes (10): `ci.yml` — bei jedem Push, Der Patchnote-Stil, Die Kurzfassung, Die Schnittstellennummer, Ein Release schneiden, `manual-release.yml` — der übliche Weg, `release.yml` — wenn ein Release von Hand angelegt wird, Vor dem Commit (+2 more)

### Community 34 - "Schlachtzüge und Fortschritt"
Cohesion: 0.20
Nodes (9): Alle Client-Aufrufe sind defensiv, Der Bestand, Die Bossliste steht links, nicht in der Seite, Die Bosslisten: zwei vorläufig, eine leer, Die vier Bestände der Seite, Herkunft ist Pflicht, Nachtragen, Onyxias Hort bleibt leer (+1 more)

### Community 35 - "ZIP-Bau und Installation"
Cohesion: 0.28
Nodes (9): Addon-Ordner bauen (rsync mit Ausschlussliste), Workflow „Release auf Knopfdruck" (Job release), tag/notes nur über env — keine direkte ${{ inputs }}-Interpolation, Ein vom GITHUB_TOKEN erstelltes Release löst release.yml nicht aus, Workflow „Addon packen und ans Release hängen" (Job build), Der Ordner im ZIP muss WeintCodex heissen (Installer der Companion), sha256-Prüfsumme neben dem ZIP, Was im ZIP landet — und warum CHANGELOG.md drinbleibt (+1 more)

### Community 36 - "Markenbild WeintCodex-Logo"
Cohesion: 0.42
Nodes (9): Alliance Lion Crest Emblem, Weint Brand Identity (shared across Codex, Companion, Bot), Codex Props: Tome, Scroll, Lantern, Quill, Ornate Gold Banner Frame with Gem Finials, Purple/Gold/Green Accent Palette, Tagline: RAID GUIDE & INTELLIGENCE SYSTEM, Wide Transparent PNG Banner Format, WeintCodex Logo (Banner Artwork) (+1 more)

### Community 37 - "Ladeprüfung: was sie misst"
Cohesion: 0.25
Nodes (8): Methods:Click in der Attrappe — ein Klick zeichnet wirklich, load_test.lua — Ladeprüfung gegen die Client-Attrappe, Kein Zugriff auf ein Modul, das es nicht gibt, Budgetprüfung: nichts muss scrollen (780 px), WeintCodex.SavedData zeigt auf dieselbe Tabelle, nie auf eine Ersatztabelle, wow_stub.lua — bewusst dumme Client-Attrappe, Nichts muss scrollen, Die Bossliste steht links, nicht in der Seite — zweistufiger Baum

### Community 38 - "Sources-Zugriffe"
Cohesion: 0.46
Nodes (7): S.IsConfirmed(), S.IsValid(), S.Label(), S.Prefix(), S.Rank(), S.Weaker(), S.Why()

### Community 39 - "Einführung und Update-Popup"
Cohesion: 0.25
Nodes (7): Beim Release, Das Update-Popup, Die Einführung, Die Regeln für jeden Text, Einführung und Update-Popup, Was diese Tour zusätzlich sagt, Zwei Hervorhebungen, zwei Bedeutungen

### Community 40 - "Datenprüfung data_test.lua"
Cohesion: 0.32
Nodes (4): Check(), CheckArt(), CheckBossList(), home_fabi_claude_projekte_codex_forever_github_tests_wow_stub_lua

### Community 41 - "LibDBIcon-Schaltfläche"
Cohesion: 0.25
Nodes (8): createButton(), lib:Refresh(), lib:Register(), lib:SetButtonRadius(), lib:SetButtonToPosition(), lib:Show(), onUpdate(), updatePosition()

### Community 42 - "CLAUDE.md (Router)"
Cohesion: 0.29
Nodes (5): Development workflow, Role in the ecosystem, Task routing — read only what the task needs, What this edition deliberately does not have, What this is

### Community 43 - "Charakter, Twinks, Versionssperren"
Cohesion: 0.29
Nodes (7): „Wilder Kampf" trägt absichtlich keine Rolle, CurrentSpec() — drei Wege, am Ende ein ehrliches nil, GetProfileKey() — CLASSFILE_ENGLISCHERBAUM für die Brücke, Twinks, CompanionAtLeast() — Versionssperren gegen companionVersion, Die Companion-Brücke — Bot → HTTP → Companion → Datei → Addon, STATE_MESSAGES liegen höchstens einmal in der Warteschlange

### Community 44 - "Charakterseite und Ausrüstung"
Cohesion: 0.29
Nodes (6): Charakter: Ausrüstung und Twinks, Die Spezialisierung, EquipSlots() / SLOT_DEFS — Ausrüstungsplätze kommen vom Client, `Snapshot()`, Was hier nicht mehr steht, character_sheet — ZÄHLER und BIS bleiben leer, score/grade/quality unbesetzt

### Community 45 - "Client-Attrappe (Objektbau)"
Cohesion: 0.29
Nodes (7): M.Install(), Methods:CreateAnimation(), Methods:CreateAnimationGroup(), Methods:CreateFontString(), Methods:CreateTexture(), Methods:GetThumbTexture(), NewObject()

### Community 47 - "Markenbild Button-Icon"
Cohesion: 0.43
Nodes (7): Absoluter Medienpfad Interface/AddOns/WeintCodex/media, Grüner Sekundärton des W, WeintCodex Button Icon (button.png), Minimap-/Einstiegsschaltfläche des Addons, Violetter Akzent als einzige bedeutungstragende Farbe, Lesbarkeit auf Icon-Größe (dunkler Rahmen, hoher Kontrast), WC-Monogramm (Markenzeichen)

### Community 48 - "Defensive Client-Aufrufe"
Cohesion: 0.33
Nodes (6): Defensive Client-Aufrufe (Safe/SafeCall, pcall) — im Zweifel stirbt der Aufruf, Der Fortschritt, modules/encounter_tracking.lua — Lockout-API plus eigenes ENCOUNTER_END, Der Fortschritt gehört dem Charakter, nicht dem Konto (bestTries neben bosses), `SavedLockouts()`, Die vier unabhängigen Bestände der Schlachtzugseite

### Community 49 - "Inbox, Live-Brücke, Warteschlange"
Cohesion: 0.40
Nodes (5): SavedVariables-Rückschreiben vernichtet, was die Companion dazwischen schrieb, Live-Brücke data/companion_live.lua und lastStamp, ProcessInbox() — Inbox und Live-Datei zusammengeführt, ProcessQueue — access_profile zuerst, dann alles andere mit Herkunftsprüfung, TOUR_STEPS und das feature-Feld (gesperrte Bereiche werden ausgelassen)

### Community 50 - "Tag-Schreibweise und vier Fassungsstellen"
Cohesion: 0.50
Nodes (4): Die Schreibweise des Tags zählt buchstäblich, Die vier Stellen, und warum sie geprüft werden, Die Zahlen stimmen - aber schreibt der Tag sie so, wie das `.toc` sie schreibt?…, spelling_problem()

### Community 53 - "Minimap-Anker und Hover"
Cohesion: 0.67
Nodes (3): getAnchors(), onEnter(), onEnterCompartment()

## Ambiguous Edges - Review These
- `Purple/Gold/Green Accent Palette` → `Wide Transparent PNG Banner Format`  [AMBIGUOUS]
  media/logo.png · relation: conceptually_related_to

## Knowledge Gaps
- **96 isolated node(s):** ``ci.yml` — bei jedem Push`, `Der Patchnote-Stil`, `Die Kurzfassung`, `Die Schnittstellennummer`, ``manual-release.yml` — der übliche Weg` (+91 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 296 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **15 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What is the exact relationship between `Purple/Gold/Green Accent Palette` and `Wide Transparent PNG Banner Format`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **Why does `WeintCodex.ColorText()` connect `Namen und Einführungstour` to `UI-Kern und Bausteine`, `Navigation und Seitenwechsel`, `Zugriffsprofile`, `Schlachtzugdaten und Rollen`, `Companion-Brücke`, `Minimap und Bedienelemente`, `Spezialisierungen und Client-Antworten`, `Gruppencheck`, `Hauptfenster und Suche`?**
  _High betweenness centrality (0.137) - this node is a cross-community bridge._
- **Why does `Kopflose Prüfläufe` connect `Kopflose Prüfläufe` to `README und Entwicklungsdoku`, `CI, Fassungsprüfung, Patchnotes`, `Ladeprüfung: was sie misst`?**
  _High betweenness centrality (0.109) - this node is a cross-community bridge._
- **Why does `Die Seite: drei Ebenen, zwei Zustände` connect `Bossraster und Kartengeometrie` to `UI-Kern und Bausteine`, `Kopfkarte und Tatsachenband`, `Dungeonsystem (Doku)`, `Artwork-Baustein und Bildpolitik`?**
  _High betweenness centrality (0.098) - this node is a cross-community bridge._
- **Are the 31 inferred relationships involving `WeintCodex.ColorText()` (e.g. with `Row()` and `Warn()`) actually correct?**
  _`WeintCodex.ColorText()` has 31 INFERRED edges - model-reasoned connections that need verification._
- **Are the 10 inferred relationships involving `WeintCodex.Navigation.SetInspector()` (e.g. with `WeintCodex.SetDetailShown()` and `CreateCalendarFrame()`) actually correct?**
  _`WeintCodex.Navigation.SetInspector()` has 10 INFERRED edges - model-reasoned connections that need verification._
- **Are the 8 inferred relationships involving `WeintCodex.ShowHome()` (e.g. with `WeintCodex.CreateButton()` and `WeintCodex.CreateMeter()`) actually correct?**
  _`WeintCodex.ShowHome()` has 8 INFERRED edges - model-reasoned connections that need verification._