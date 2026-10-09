# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working
with code in this repository. It is a **router**, not a knowledge base:
detailed system documentation lives under `docs/` and is loaded on demand
via the task-routing table below, not kept permanently in context.

## What this is

**WeintCodex — Forever Edition** is a World of Warcraft **Forever** addon:
a raid guide & guild intelligence system (raids and dungeons with
per-role information, raid roster/calendar, character management, group
check, materials tracking, Companion bridge).

Comments and in-game UI text are in German; Lua identifiers are in
English/mixed. There is no build step, package manager, or runtime test
suite — pure WoW addon Lua, loaded directly by the game client per
`WeintCodex.toc`. Two offline Lua 5.1 checks live under `.github/tests/`.

It grew out of the Mists of Pandaria addon (`daddler/WeintCodex`) **by
removal, not by rewrite** — the same way `Companion-Forever` grew out of
`WeintCompanion`. The old addon keeps its own repository and its own
release channel.

## Role in the ecosystem

WeintCodex is one of three sibling repos that together form the Weint
ecosystem:

```
Codex-Forever (this repo, in-game Lua)
    ↕ SavedVariables file (no network)     ↔  Companion-Forever (desktop app)
                                                    ↕ HTTP :8765
    ← clipboard (WCIMPORT string)           ←  WeintCodex Bot (Discord bot)
```

- **Codex-Forever** (this repo) — the in-game addon.
- **Companion-Forever** — installs/updates this addon, bridges it to
  Discord, and is the **authoritative host for every cross-repo data
  contract** (see routing table — most "how does X sync" answers live in
  `../Companion-Forever/docs/*.md`, a sibling checkout).
- **WeintCodex Bot** — Discord bot backend; talks to this addon only
  indirectly, via a `WCIMPORT:` string a player pastes in, or via the
  Companion relaying it.

**This addon never talks to the bot or the network directly.** Everything
arrives either through `WeintCodex_SavedData`/`WeintCompanionDB`/
`WeintCompanionInboxDB` (the SavedVariables files the Companion also
reads/writes), through `data/companion_live.lua` (which the Companion
rewrites), or through a copy-pasted `WCIMPORT:` string.
**One exception inside the game, since 6.18.0.0 and only on request:**
auction prices (`ui/auctionshare.lua`, two switches – off by default until
6.26.11.1, on by default with `ahPrices` since 6.26.12.0 at the owner's request).
With „Mit der Gilde teilen“ WeintCodex sends and receives prices as addon
messages to the guild (prefix `WCAH`); with „Preise aus ForeverGuide
übernehmen“ it joins ForeverGuide's hidden channel and **only listens** –
it never sends there. Nothing else leaves the client, nothing goes to the
internet; any further outward message needs the same explicit request.

## Critical invariants (always relevant, keep in mind for any change)

- **`unknown` ≠ `0` ≠ `false` ≠ provisional.** This is the single most
  important rule in this repository, and for this edition it is not
  theoretical: most boss lists are empty on purpose, the material
  watchlist is empty on purpose, and Forever's client API is
  unverified. A missing item level, an unanswered client call, an empty
  boss list, a material without a target — none of these may be
  rendered as a measured zero, a red dot, or a progress bar at 0 %.
  Since 5.1.0.0 there is a fourth state, **provisional**: data that is
  in the game but was never announced. Since 5.2.0.0 there are two
  more, and they are not decoration: **counted but unnamed**
  (`bossCount` set, `bosses` empty — City of Dalaran until 6.9.0.6, when
  all nine names arrived; no current case, `load_test.lua` borrows a
  table to keep the page honest) and **contested** (Blackmaw Hold, and
  Excavation Site until 6.9.0.6 — sources contradict each other:
  `conflict` set, everything else empty). Neither may be rendered as an
  empty list or as silence.
  Details: `docs/invariants/data-integrity.md`.
- **Kein Bestand ohne Herkunft.** Nothing may appear in a data table
  whose source cannot be named — that, not emptiness, was always the
  rule. `data/raids.lua` therefore **must never be backfilled from
  Mists of Pandaria** (that would accuse players of shortfalls their
  game does not have), but since the beta client shipped (17.09.2026)
  it *does* carry the encounter lists for Barrow Deeps and Hyjal
  Summit. Since 5.2.0.0 `data/sources.lua` is the **one** place that
  defines what a source is, for raids and dungeons alike, with five
  kinds in decreasing firmness: `release`, `announced`, `beta`,
  `community`, `classic`. **Only `release` counts as confirmed**;
  every other kind carries a visible prefix *and* a `Why()` sentence
  on every surface. A filled boss list without a valid source fails
  `data_test.lua`; so does an empty one *with* one. Onyxias Hort,
  Blackmaw Hold, four more dungeons and the material watchlist stay
  empty — no source, no entry. **Since 6.21.0.0 the source is named
  only for maintainers:** no text a player sees names a third-party
  addon (ForeverGuide, Questie, Leatrix Maps, …) as its source – it says
  „Wissensstand aus der Beta“ / „aus Classic“, the *kind* stays
  (`community` is still „Unbestätigt“, never `beta`); scripts, generated
  files and docs keep the real origin. `load_test.lua` scans every string
  literal (`docs/systems/ui.md`, *Herkunft im Spiel ohne fremde Namen*).
  Same reasoning as
  `../Companion-Forever/docs/systems/forever-data.md`; details in
  `docs/systems/raids-and-progress.md`, section *Herkunft ist Pflicht*,
  and `docs/systems/dungeons.md`, section *Fünf Arten von Herkunft*.
- **Nobody here has read the Forever client.** Dungeon boss names come
  from *reports about* the client, not from the client — they are
  `community`, never `beta`. Claiming `beta` claims a check that never
  happened. The same applies to level ranges, encounter counts and
  summon instructions.
- **`order` only where the order is known.** `orderKnown = false` means
  **no** boss in that list may carry `order`, and the page prints no
  pull number. "3 von 7" over an unordered list is a number nobody
  knows. `data_test.lua` enforces both directions.
- **A wing may not lose a boss.** The sub-nav shows one wing at a time;
  a boss without a `wing` in an instance that has wings would be
  visible **nowhere**, silently. `data_test.lua` checks that the wings
  together cover every boss.
- **Rollen: drei Bestände, nie zusammengezogen.** Which talent tree
  carries which role is known (`data/specs.lua`); how many slots a role
  has is known for 5-player groups and **`nil` for 10/20/40**; what a
  role does at a given boss is known for **no** fight in Forever and
  comes only from the Discord bot (`WCIMPORT:BOSS`). Never write
  generic tactics — they fit every game and no fight in Forever.
  Details: `docs/systems/dungeons.md`.
- **Nichts muss scrollen — und das ist nachgerechnet, nicht
  geschätzt.** The nav column and the sub-nav list can both overflow
  the window silently: an entry below the account row looks like a
  feature that does not exist, not like a bug. `NavColumnHeight()`,
  `SubNavHeight()` and `MeasureSidebar()` compute what each occupies,
  `load_test.lua` holds them against the smallest allowed window
  (780 px) and additionally demands headroom for one more entry. Page
  content that grows from bot-supplied data is capped (raids, see
  `RolePanel.BossCards`) or goes into the one surface built to scroll
  (the detail column; on the dungeon page its detail card). Text
  heights are **estimated** with `WeintCodex.Paragraph`, never read
  from the stubbed client, so test and game build the same page.
  Details:
  `docs/architecture/overview.md`, section *Nichts muss scrollen*.
- **Eine Liste steht an einer Stelle, und die beantwortet „wo bin
  ich".** Raids: instances on level one in the sub-nav, the bosses of
  the **selected** raid indented below (`indent = true`), never the
  boss list back in the content area — that is what made it scroll.
  Dungeons (since the redesign after 5.2.0.0, re-laid out in
  5.2.0.5): the sub-nav carries **only dungeons**; the page carries
  the bosses as a **grid of cards** whose column count is computed
  from the real width and the longest name (`GridLayout`), never
  fixed — a boss list the page shows never appears left as well, and
  nothing on the page grows unbounded except the one context card
  that is built to scroll. The right detail column is shown only
  when it has content *and* does not cost the grid its shape
  (`DrawDungeon` draws, measures, and redraws full-width).
  Details: `docs/systems/dungeons.md`, section *Die Seite: drei
  Ebenen, zwei Zustände*.
  `status` on a sub-nav item takes a string **or** `{ text, color }`;
  it silently rendered an empty line for years when given the wrong
  one.
- **What the client can answer is never derived or guessed.** Equipment
  slots come from `GetInventorySlotInfo`, not a hard-coded list; the
  specialization comes from the client or stays `nil`. Five releases of
  bugs in the MoP addon came from breaking this rule.
- **UTF-8 vs. Lua byte-wise string functions.** Never use `string.upper`,
  `#`, or `:sub` on German display text — use `Spaced`/`WeintCodex.Upper`/
  `WeintCodex.Truncate`/`Utf8Len`/`Utf8Sub` from `core/ui.lua`.
- **One accent, and it carries meaning only.** `accent`, `purple`,
  `violet` and `brandA` are the same colour on purpose, and
  `.github/tests/load_test.lua` holds them to it. A second meaning-bearing
  colour is how the previous edition ended up with "amber carries meaning,
  purple carries light". Since 6.6.3.1 the accent **is the player's class
  colour**, everywhere: `WeintCodex.SetAccent` (core/ui.lua) rewrites every
  token derived from the violet in place (base/bright/dim/deep/card, alpha
  kept), in `Colors` and `GameColors`, at load; `general.highlight =
  "accent"` restores the exact violet. Still one accent – the load test
  holds accent = purple = violet = brandA. Never hard-code `|cff7C6CFF` in
  a text: use `WeintCodex.AC` (the changelog data keeps it and is recoloured
  on display). Status colours (green/red/gold/blue) never follow the class.
  **One exception since 6.7.0.0**, for restyled Blizzard windows only:
  `GameColors.frameAccent` (muted gold) is the accent of windows that do
  not belong to the class (style `S.CALM`; since 6.7.5.0 the professions
  window `ProfessionsFrame`, since 6.7.8.0 guild & communities
  `CommunitiesFrame`, since 6.7.9.0 the game menu, the game's dialogs and
  the world map with the quest log, since 6.8.0.0 the group finder
  `LFGParentFrame`, since 6.8.0.2 the collections `CollectionsJournal`, since 6.8.0.4 the
  conversation windows `GossipFrame`, `QuestFrame`, `ItemTextFrame`, since
  6.8.0.6 the merchant `MerchantFrame`, since 6.9.0.0 loot `LootFrame`
  and the game options `SettingsPanel` and macros `MacroFrame`, since
  6.9.0.2 trade `TradeFrame`, since 6.9.0.4 the auction house
  `AuctionHouseFrame`, since 6.9.1.1 the bank `BankFrame` and the guild
  bank `GuildBankFrame`, since 6.9.1.2 the mail `MailFrame` and
  `OpenMailFrame`, since 6.10.1.0 the contacts `FriendsFrame` and the trainer `ClassTrainerFrame`, since 6.10.3.1 the loot roll `GroupLootFrame1..4` –
  the tabs of the character frame, the spellbook and the talents
  carry the class colour via `S.CHARACTER_INFO`). A region carries exactly
  one of the two accents – its style (`ui/style.lua`, `S.SCOPES`) says
  which, down to the selected side tab and tab of the window, and a gold window
  never carries the class glow at the top (`W.HoldGlow`); `SetAccent`
  never touches the gold. Never use it in the addon's
  own pages, never next to the class colour in the same region.
- **The UI (`ui/`) is opt-in again since 6.9.0.0, and switching it on
  never overwrites the player's own setup – and since 6.26.8.0 it is chosen per character** (`ui.chars[Name-Realm]` via `K.CharState`, also the remembered layout and CVars). `K.OPT_IN = true` in
  `ui/kit.lua` (6.0.0.3–6.8.1.0 it was `false`: the beta client did not
  persist SavedVariables); flipping it back to `false` makes the UI on for
  everyone again, and `load_test.lua` tests both states. The first login
  shows a welcome wizard once per account (`ui/welcome.lua`; since 6.26.7.0 eight steps – every comfort function, grouped by theme like the comfort pages, all preselected with the UI:
  UI yes/no with own illustrations, then comfort choices either way;
  nothing changes before "Übernehmen"). **Profile rule
  (`ui/profile.lua`):** the UI gets its own Edit Mode layout "WeintCodex"
  and never writes into the player's; the active layout is remembered
  **before** switching (`ui.before`, once), every CVar change goes through
  `PF.SetCVar(name, value, owner)` (first value remembered in `ui.cvars`),
  and switching off restores both – the layout only if "WeintCodex" is
  still active, a CVar only if *our* value still stands. Chat tabs are
  never reset any more (they exist once per character; resetting meant
  deleting). **Two groups:** `group = "ui"` modules replace or dress a
  game frame and run only with the master switch (reload to change);
  `group = "qol"` adds what the game lacks and runs without it –
  quest arrow, damage meter, reminders, comfort (with Automark, click
  casting + dispel, macro helper as pages; `store =` keeps their saved
  settings at their old module). `defaultEnabled = "ui"`: on by default
  only with the UI (the full package), off otherwise. Layout and defaults
  follow EllesmereUI, but **no code or media from it** — its licence is
  "all rights reserved". The same holds for MoveAny (window moving since
  6.10.4.0 copies its behaviour, not its code). Game-world colours live in `core/ui.lua` as
  `WeintCodex.GameColors`. Values from the 12.x client may be *secret*:
  `type(x) == "nil"` instead of `x == nil`, no `a or b` on client values;
  every text line in `ui/` comes from `UIKit.NewText` (font set at
  creation – "Font not set" broke two releases; `load_test.lua` bans
  `CreateFontString` outside `ui/kit.lua`); every bar from
  `UIKit.NewBar`, every default position from `ui/layout.lua`
  (`UIKit.Layout`) – one style, one grid (UI 2.0);
  auras go through `ui/auras.lua` (engine AuraContainer where available),
  damage numbers through `C_DamageMeter` (no combat log for addons),
  chat messages are never rewritten (since 6.19.1.0 the messenger *hides* whispers it has itself captured, on request – hiding, never rewriting). Anything that runs repeatedly
  (tickers, OnUpdate) allocates no table or closure per frame or region –
  the window pass leaked ~12 MB per 20 runs until 6.6.2.6; walk with
  `W.Regions`/`W.Children`. Details: `docs/systems/ui.md`.
- **Reloading is protected on Forever.** `ReloadUI()`/`C_UI.Reload()`
  from addon code is blocked (`ADDON_ACTION_BLOCKED`, measured on the
  beta client). Every reload button goes through
  `WeintCodex.AttachReload` (a `/reload` macro on an
  `InsecureActionButton`, triggered by the click itself);
  `load_test.lua` fails on any direct call. **Raid markers likewise**
  (`SetRaidTarget` → `ADDON_ACTION_FORBIDDEN`, measured 6.9.0.1; `pcall`
  does *not* catch it – the call is blocked and `pcall` reports success):
  Automark asks on entering an instance and marks through a secure macro
  button (`/tm [@unit] n`) since 6.9.0.2 – the same restriction holds in
  Retail since 12.0.0,
  and `load_test.lua` fails on any reference to `SetRaidTarget`.
- **Every colour value lives in `core/ui.lua`.** It is the translation of
  the Companion's `gui/theme/tokens.py`. A hex value anywhere else is a
  surface that gets missed when the palette changes.
- **Never write to a freshly created fallback table instead of
  `WeintCodex_SavedData`.** WoW only persists variables declared in the
  `.toc`; a silent fallback loses data with no error.
- **`WeintCodex.toc` load order is the only dependency mechanism.** A
  module can only reference `WeintCodex.Other` if `other.lua` loads
  earlier; a new file must be added to the `.toc` (libraries → core →
  data → modules → ui) or it silently won't load. `load_test.lua` catches
  both mistakes.
- **The addon folder must be named `WeintCodex` and the TOC
  `WeintCodex.toc`.** The Companion's installer looks for exactly that
  (`core/installer.py` over there), and the media paths in `core/ui.lua`
  are absolute.
- **Bump the version in three places together** — `## Version` in
  `.toc`, `WeintCodex.Version` in `core/main.lua`, and the top entry in
  `data/changelog.lua` — plus a `CHANGELOG.md` section, and the release
  tag must be exactly `v` + that version. See
  `docs/development/releases.md`.

## Development workflow

No build step. Before pushing:

```bash
luac5.1 -p $(find core data modules ui -name '*.lua')   # Syntax
lua5.1 .github/tests/load_test.lua .                 # lädt das Addon?
lua5.1 .github/tests/data_test.lua .                 # Daten + Fassungen
```

**There is no game to verify against** — Forever has not been released.
The load test against a stubbed client is therefore not a nicety but the
main safety net; it catches missing/misordered `.toc` entries and calls
into modules that no longer exist. A green run means "it loads", never
"it works".

## Task routing — read only what the task needs

| Task touches… | Read |
|---|---|
| UI-Struktur, Theme, `core/ui.lua`, Navigationsspalte (seit 6.13.0.0 als Informationsarchitektur: Leveln/Gruppe/Gilde/System, Import als Reiter unter Companion über `Navigation.SUBTABS`; seit 6.14.0.0 „Berufe“ unter Leveln, seit 6.25.0.0 „Taschen“ dahinter, `modules/bags.lua`), PageHead, Detailbereich, Startseite (`modules/home.lua`, seit 6.11.0.2 nach dem Entwurf des Spielers: „Als Nächstes“ mit Erfahrung, „Außerdem“, „Dein Weg“ über acht Stufen; seit 6.11.0.3 die lernbaren Zauber mit Namen und Tooltips im Weg) | `docs/architecture/overview.md` |
| Leere Tabellen, `unknown ≠ 0`, Leerzustände | `docs/invariants/data-integrity.md` |
| Schlachtzüge, Bosslisten, Lockouts, Fortschritt, Herkunft einer Liste | `docs/systems/raids-and-progress.md` |
| Dungeons (Forever **und** Classic), Stufenbereiche, Bosslisten, Flügel, beschwörbare Zusatzbosse, Rollen, Beute und Quests (`data/dungeon_journal.lua`, Queststatus aus dem Client seit 6.9.0.7), Questgeber auf der Weltkarte (`modules/questmap.lua`), Abgleich mit dem Client (`/wc abgleich`, `modules/clientcheck.lua`, 6.10.3.0: liest Gruppensuche und Kompendium, schreibt nichts), Abgleich mit dem Addon ForeverGuide (6.14.0.0: `data/dungeon_journal_fg.lua` **erzeugt** von `.github/scripts/import_foreverguide.py` – Quests mit Ketten ohne Texte, Eingänge, Beute der alten Dungeons als `classic`; `J.MergeForeverGuide` ersetzt nie Handgepflegtes) | `docs/systems/dungeons.md` |
| Artwork, `data/artwork.lua`, `WeintCodex.Artwork`, `media/dungeons/` | `docs/systems/dungeons.md`, Abschnitt *Bilder: kein Spielmaterial, eigenes schon* |
| Herkunft eines Eintrags, `data/sources.lua`, `release`/`announced`/`beta`/`community`/`classic` | `docs/systems/dungeons.md`, Abschnitt *Fünf Arten von Herkunft* |
| Charakterseite, Twinks, Ausrüstungsstand, Lehrer (`modules/trainer.lua`, `data/trainer.lua`; seit 6.15.0.0 Reiter „Klassenquests“, `modules/classquests.lua`, `data/classquests.lua` **erzeugt**, Stand vom Client, Belohnungen `classic`), Berufe (6.14.0.0: `modules/professions.lua`, `data/professions.lua` **erzeugt** von `.github/scripts/import_foreverguide.py`; Gelerntes aus dem Berufsfenster je Charakter) | `docs/systems/character.md` |
| Gruppencheck | `docs/systems/groupcheck.md` |
| Companion-Sync allgemein (Inbox/Outbound, `ProcessInbox`) | `docs/systems/companion-bridge.md` |
| Onboarding-Tour, Update-Changelog-Popup | `docs/systems/onboarding-changelog.md` |
| Release schneiden, Changelog, Patchnote-Stil, Builder | `docs/development/releases.md`, vor jedem Release die Prüfliste im Spiel `docs/development/release-checklist.md` |
| Kopflose Prüfläufe, Client-Attrappe | `.github/tests/README.md` |
| Zugriffsprofile / `core/access.lua` | `../Companion-Forever/docs/access-profile-bridge.md` |
| Ausrüstungsstand an die Companion (`character_sheet`) | `../Companion-Forever/docs/character-sheet-bridge.md` |
| Live-Brücke (`data/companion_live.lua`) | `../Companion-Forever/docs/live-bridge.md` |
| Raid-Termin, Countdown, Zusagen | `../Companion-Forever/docs/raid-schedule-bridge.md` |
| WCIMPORT-Import (`/wc import`, Bot-Slash-Commands) | `../Companion-Forever/docs/wcimport-protocol.md` |
| Raid-Anmeldeliste, `source`/`status`/`lineup` | `../Companion-Forever/docs/wcimport-protocol.md` |
| Charakterzuordnung, WeintAdmin-Backup | `../Companion-Forever/docs/character-links-and-admin-bridge.md` |
| Companion-Authentifizierung/Token | `../Companion-Forever/docs/companion-auth.md` |
| Welche Spieldaten fehlen und warum | `../Companion-Forever/docs/systems/forever-data.md` |
| Neugestaltung der Oberfläche (UI 2.0): Cockpit, Raster, Kachel, Ruhe/Kampf, Gestaltungsmodus, Phasen | `docs/design/ui-2.0.md` |
| Oberfläche (`ui/`): Plaketten (auch Farben je NPC, `ui/npccolors.lua`), Einheiten-/Gruppenrahmen (eigene und die des Spiels, `ui/gamegroup.lua`), Einrichtung beim ersten Mal (`ui/setup.lua`, Layout im Bearbeitungsmodus), Aktionsleisten, Erfahrungsbalken, Charakterfenster (`ui/character.lua`, Klassen-Themen `data/classthemes.lua`), Designsprache der Fenster des Spiels (`ui/style.lua`: Akzente, Stile je Bereich, Bausteine), Register – Liste des Spiels mit Detailkarte (`ui/register.lua`) – mit Ruf (`ui/reputation.lua`), Fertigkeiten (`ui/skills.lua`), Abzeichen/Währungen (`ui/currency.lua`) Statistiken (`ui/statistics.lua`, ohne Detailansicht) und Berufe (`ui/professions.lua`, Rezeptseite, Gold; Register außerhalb des Charakterfensters über `W.HOSTED`; Übersicht mit Karten je Beruf `ui/profbook.lua`), Zauberbuch (`ui/spellbook.lua`, Klassenfarbe; Schein der Klasse `W.HoldGlow`; Linie hinter Überschriften auf ganzen Bildpunkten, `S.PixelY`, 6.10.4.3 – gemessen: Kanten auf halben Bildpunkten werden nicht gezeichnet), Talente (`ui/talents.lua`, Klassenfarbe, Animation bleibt; Namen der Bäume notfalls aus `data/specs.lua`), Namensplaketten-Bewegung (6.8.1.0: Schadensspur, weiche Balken, Ziel atmet), Automark (`ui/automark.lua`, Seite im Komfort), Makro-Helfer (`ui/macros.lua`, seit 6.9.0.0 Seite im Komfort), Entfluchen auf Klick (`ui/dispel.lua`, an den Klickzaubern, die seit 6.9.0.0 im Komfort stehen), Hauptschalter und Profil (`ui/profile.lua`: eigenes Layout, Layout und Spieleinstellungen von vorher zurück; Komfort ohne Oberfläche), Profile je Charakter (`ui/profiles.lua`, seit 6.12.0.0: `ui.profiles`/`ui.profileOf`, Zugriff nur über `UIKit.Profile()`, fest bis zum Neuladen, „Standard“ immer da; seit 6.12.0.1 einmal je Charakter die Frage beim Einloggen), Willkommens-Assistent (`ui/welcome.lua`: seit 6.26.7.0 acht Schritte – je Thema alle Komfortfunktionen, `WL.GROUPS`/`WL.HELPERS`; Komfortseiten nach Thema `QoL.PAGE_ORDER`/`O.SortPages`; Bilder aus `media/welcome/`, gebaut mit `.github/scripts/make_welcome.py`), Gespräche in Gold (`ui/gossip.lua`: Gespräch, Questtext, Bücher), Händler in Gold (`ui/merchant.lua`: Waren auf Fläche, Reiter unten über `W.SkinTab`), Beute in Gold (`ui/loot.lua`, 6.9.0.0), Optionen des Spiels in Gold (`SettingsPanel`, `ui/calm.lua`, Kategorien als Abschnitte), Makrofenster in Gold (`ui/macroframe.lua`), Handel in Gold (`ui/trade.lua`, 6.9.0.2), Auktionshaus in Gold (`ui/auction.lua`, 6.9.0.4), Bank in Gold (`ui/bank.lua`, 6.9.1.1; Gildenbank seit 6.10.4.2 aus Bausteinen: Reiter, Geld, seit 6.10.4.3 ohne Wappen; Innenflächen nie über das Fenster, `CP.Clamp`), Post in Gold (`ui/mail.lua`, 6.9.1.2; geöffneter Brief nur Hülle), Kontakte in Gold (`ui/friends.lua`, 6.10.1.0, erstes Fenster nur aus Bausteinen; seit 6.20.0.0 auch das neue `SocialUIFrame`), Lehrer in Gold (`ui/classtrainer.lua`, 6.10.1.0: ein Bild in vier Rollen, sortiert nach Rolle; Leiste der Fertigkeit beim Berufslehrer flach ohne Rahmen, seit 6.10.4.8 wieder im Blau des Spiels – Gold und Dunkel waren schlecht zu erkennen), Fenster verschieben (`ui/movewindows.lua`, 6.10.4.0: wie MoveAny, eigener Code – MoveAny ist „All Rights Reserved“; immer an, ohne Schalter, auch ohne Hauptschalter; seit 6.10.4.1 gilt der Platz nur, solange das Fenster offen ist – beim Schließen zurück an den Platz des Spiels; geschützte Fenster nicht im Kampf; MoveAny/BlizzMove haben Vorrang), Markieren per Mouseover (`ui/hovermark.lua`, 6.10.4.1, Seite Automark: Maus über den Gegner **und eine Taste** – nur Drüberfahren verbietet das Spiel; Vorrang-Belegung nur in Instanzen, nächste freie Markierung, nicht doppelt, nie im Kampf), Würfeln um Beute in Gold (`ui/lootroll.lua`, 6.10.3.1: kein Fenster aus `W.WINDOWS`, aus `W.Apply`; Zeit über die Kachel gehoben), Bausteine für Fenster in Gold (`ui/calmparts.lua`, 6.10.0.0: ein Fenster beschreibt nur seine gemessenen Bilder), Einstellungen zweistufig und Suche (`Builder:Advanced`, `O.Search`, 6.10.0.0; seit 6.10.1.0 höchstens 15 sichtbare Einstellungen je Seite), Symbol der Oberfläche an der Minikarte (`ui/launcher.lua`, nur mit Oberfläche; WCUI-Logo seit 6.9.0.3, `media/ui/logo_*.tga` aus `.github/scripts/make_logo.py`), Messen im Spiel (6.10.2.0: Bericht zum Kopieren `ui/report.lua`, `/wcui fenster` je Fundort, Selbstprüfung `/wcui prüfen` in `ui/selfcheck.lua`), Brücke zum Bearbeitungsmodus des Spiels (`ui/editmode.lua`, 6.9.0.5: Knopf hinüber aus Gestaltungsmodus und Einstellungsseiten, `Builder:GameEditMode`, und zurück; `/editmode` als Makro auf sicherem Knopf), Gilde & Communitys (`ui/community.lua`, Gold, drei Spalten; Mitgliederliste seit 6.10.4.3 ohne Rand und Bänder, nicht verdunkelt; seit 6.10.4.4 auch die Spaltenköpfe der großen Ansicht; Reiter „Info“ seit 6.10.4.5 ohne Pergament, `CO.SkinDetails`), Spielmenü (`ui/gamemenu.lua`, Gold) und Dialoge (`W.SkinPopup`), Questlog an der Karte (`ui/questlog.lua`, Gold; weicher Rand der Karte bleibt), Fenster in Gold mit Innenflächen – Suche nach Gruppe, Sammlung (`ui/calm.lua`, Innenflächen über `W.Insets`), PvP-Profil (`ui/pvp.lua`), Weltkarte & Questlog, Gesprächsfenster (Questgeber, Gastwirte, Händler), Seltene Gegner melden (`ui/rares.lua`, 6.16.0.0, Seite im Komfort, `data/rares.lua` **erzeugt**; selten ist, was der Client sagt oder der Bestand kennt; `/wcui selten`), Auktionspreise (`ui/auctionprices.lua`, 6.17.0.0, Seite im Komfort: Vollscan, sonst Suche, nebenbei die eigene Suche; günstigstes Angebot je Stück im Tooltip, eine Zahl je Gegenstand je Realm und Seite; `/wcui auktion`; seit 6.18.0.0 Preise von anderen Spielern, `ui/auctionshare.lua`: Gilde senden/empfangen, ForeverGuide nur zuhören, „von Spielern“ im Tooltip), Flüstern als Messenger (`ui/messenger.lua`, 6.19.0.0, Seite im Komfort, nach WIM ohne Code: Verlauf nur die Sitzung – nie gespeichert, Antwort über die Chatzeile, direkt senden schaltet sich bei Sperre ab; `/wcui flüstern`; seit 6.19.1.0 nur im Fenster – Chatfilter verbirgt nur, was das Fenster lesen kann, nie umgeschrieben; im Kampf eingeklappt; „/w Name“ öffnet, Chatzeile nur gelesen; Symbol; ziehbar; seit 6.19.1.2 öffnet die Taste R das Fenster beim zuletzt Flüsternden, Chatzeile notfalls neu mit „/w Name“), Instanzeingänge auf der Weltkarte (`ui/mapentrances.lua`, 6.20.0.0, Seite „Karte“ im Komfort: eigene Symbole aus `J.ENTRANCES`, auch auf dem Kontinent, nie in die Karte des Spiels geschrieben; Karte aufdecken `ui/mapreveal.lua` mit `data/mapreveal.lua` **erzeugt** von `.github/scripts/import_mapreveal.py` aus Leatrix Maps – nur Daten, im Spiel gegen das Erkundete geprüft, nur Unerkundetes abgedunkelt gezeichnet; seit 6.21.0.0 Geistheiler und Übergänge `ui/mapmarks.lua`, `data/mapmarks.lua` **erzeugt** von `.github/scripts/import_mapmarks.py`, Name des Ziels vom Client), Kräuter- und Mineraliensuche im Wechsel (`ui/gathertrack.lua`, 6.22.0.0, Seite „Sammeln“: nie unter 1,5 s, gemessen erlaubt 6.22.0.1 – schaltet sich bei Sperre ab; seit 6.22.0.2 liegen die eigenen Kartensymbole über den erkundeten Gebieten, `ME.BaseLevel`), Bestand aller Charaktere (`ui/inventory.lua`, 6.24.0.0: Taschen/Ausrüstung/Bank je Charakter in `SavedData.inventory`, Tooltip, `/wcui bestand`; Bank nur bei offener Bank gelesen; seit 6.25.0.0 kein Komfort mehr, gezeigt auf der Codex-Seite „Taschen“ `modules/bags.lua`, Fenster `ui/bagswin.lua` entfernt), eigene Alarmtöne für „Raus da“ (6.25.0.0, `media/sounds/` aus `.github/scripts/make_sounds.py`), Haken im Aufspürmenü (6.25.0.0, `GT.HookMenu`), Gespräche im Codex-Stil (`ui/dialogue.lua`, 6.23.0.0, Seite „Gespräche“: nach dem Verhalten von DialogueUI ohne Code – keine Lizenz; nimmt `GossipFrame`/`QuestFrame` die Ereignisse, gibt genau diese zurück beim Ausschalten oder Scheitern; Gold), Erläuterungen unter Schaltern (6.21.0.0: nur oben links verankert, nie „…“), Erinnerungen (seit 6.13.1.0 auch die Laune des Jägerbegleiters, `UIKit.PetHappiness`, mit Punkt am Begleiterrahmen – `GetPetHappiness` gibt es auf Forever nicht, seit 6.13.3.0 `C_PetInfo.GetPetHappiness` mit Gegenprobe über den Schaden – gemessen offen „3, 125, 20“ wie in Classic, Messung in `/wcui prüfen`; seit 6.13.2.0 Regelliste nur des Charakters, `R.ListedRules`), Klickzauber (`ui/clickcast.lua`), In den Chat melden (Schadensanzeige: selbst nur in die Gruppe – Gilde gemessen gesperrt, `ADDON_ACTION_BLOCKED`; Gilde/Sagen/Flüstern seit 6.10.4.6 als Zeile in die Eingabezeile, Enter sendet), Bedrohung (Messart der Schadensanzeige und Leiste/„Aggro: Name“ an den Plaketten, 6.9.0.8; seit 6.10.3.2 zeigt die Leiste dem Tank den Nächsten und fehlt allein ohne Begleiter; seit 6.10.3.3 eine Farbe der Lage für Leiste und Lebensbalken, `NP.ThreatTint`, Bedrohungsfarben ab Werk an; seit 6.10.3.4 einstellbar: Warnen ab, auch allein, Tank: den Nächsten, Farbe „weit weg“), Abklingzeitmanager, Minikarte, Chat, Tooltip, Taschen, Schadensanzeige, Questliste, Auren, Questpfeil, Komfort, `/wcui`, `OPT_IN`, `WeintCodex.GameColors`, geheime Werte (12.x), `UIKit.NewText`, `UIKit.NewBar`/`Glow`/`Kachel`, Layout-Tabelle, Ruhe/Kampf, Testmodus | `docs/systems/ui.md` |

Cross-repo tasks (something touches Codex **and** Companion **and/or**
Bot): read this table's Companion-doc pointers first — they are the
authoritative contract for the wire format, and the Codex-local docs
above only add what's specific to this repo's implementation.

## What this edition deliberately does not have

Do not add these back without a stated reason that survives the question
"what number is this built on, and where does that number come from?":

| Nicht vorhanden | Warum |
|---|---|
| Simmen, Statgewichte, Zielausrüstung | Es gibt keinen Sim für Forever. |
| Sockelsteine, Verzauberungen, Umschmieden, Tempo-Schwellen | Hingen an `data/spec_profiles.lua`, `gems.lua`, `enchants.lua`, `breakpoints.lua` aus MoP. Keine davon sagt über Forever etwas aus. |
| BiS-Listen | Setzen Bosslisten und Beute voraus — beides unveröffentlicht. |
| WeakAuras (das Addon, Import von Strings) | Für Forever nicht unterstützt – WeakAuras selbst ist für 12.x eingestellt. Was davon noch geht, bauen die **Erinnerungen** nach (`ui/reminders.lua`, seit 6.4.0.0): fehlende Buffs, Waffe, Begleiter und seine Laune, Munition und Vorrat außerhalb des Kampfes, eigene Procs und Abklingzeiten als Symbole. Nur vom Spieler genannte Zauber, keine eingebaute Zauberliste; im Kampf nur Anzeige, keine Bedingungen auf geheimen Werten. |
| Karten- und Bossbilder **aus dem Spiel** | Blizzard hat für Forever keine Dungeonkarten veröffentlicht (im Beta-Client liegt für vier der neun Instanzen überhaupt Material), und das Material gehört Blizzard. Ein geratener Texturpfad zeichnet im Spiel ein grünes Rechteck. **Eigenes** Artwork fällt unter keinen der beiden Gründe: seit 5.2.0.7 trägt die Hall of Thanes fünf eigene Bilder; Ragefire Chasm ist der zweite, Ruins of Lordaeron der dritte, Wailing Caverns der vierte und The Deadmines der fünfte und Shadowfang Keep der sechste bebilderte Dungeon (`media/dungeons/`, `data/artwork.lua`) — sie behaupten nichts über das Spiel, und ein bebilderter Dungeon ist kein besser belegter. `boss.position` sagt weiter in Worten, wo einer steht. |
| Aurenleisten (Restzeit als Leiste über Spieler- oder Zielrahmen, „wie ElvUI“) | Im Kampf gibt der Client Addons weder die Auren des Ziels noch die eigenen heraus („Auras cannot be accessed when secret while tainted“), und der Aurenbehälter des Spiels füllt eigene Leisten nicht einmal außerhalb des Kampfes – gemessen in 6.6.0.1 bis 6.6.0.3, ausgebaut in 6.6.0.4. Im Kampf: verfolgte Leisten des Abklingzeitmanagers. Details: `docs/systems/ui.md`. |
| Academy, WeintTV, Rotationshelfer | Brauchen ein auswertbares Kampflog. Ob Forever eines hergibt, ist nicht bestätigt — siehe `../Companion-Forever/docs/systems/forever-data.md`, letzter Abschnitt. |
| Ausrüstungs-Alarm, Einkaufsliste, Sockelfenster-Hilfe | Hätten ohne Verzauberungen und Sockel nichts zu melden. |
