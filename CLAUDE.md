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
  more, and they are not decoration: **counted but unnamed** (City of
  Dalaran — nine encounters reported, names unknown: `bossCount` set,
  `bosses` empty) and **contested** (Excavation Site, Blackmaw Hold —
  sources contradict each other: `conflict` set, everything else
  empty). Neither may be rendered as an empty list or as silence.
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
  Excavation Site, Blackmaw Hold, four more dungeons and the material
  watchlist stay empty — no source, no entry. Same reasoning as
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
  purple carries light".
- **Every colour value lives in `core/ui.lua`.** It is the translation of
  the Companion's `gui/theme/tokens.py`. A hex value anywhere else is a
  surface that gets missed when the palette changes.
- **Never write to a freshly created fallback table instead of
  `WeintCodex_SavedData`.** WoW only persists variables declared in the
  `.toc`; a silent fallback loses data with no error.
- **`WeintCodex.toc` load order is the only dependency mechanism.** A
  module can only reference `WeintCodex.Other` if `other.lua` loads
  earlier; a new file must be added to the `.toc` (libraries → core →
  data → modules) or it silently won't load. `load_test.lua` catches
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
luac5.1 -p $(find core data modules -name '*.lua')   # Syntax
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
| UI-Struktur, Theme, `core/ui.lua`, Navigationsspalte, PageHead, Detailbereich | `docs/architecture/overview.md` |
| Leere Tabellen, `unknown ≠ 0`, Leerzustände | `docs/invariants/data-integrity.md` |
| Schlachtzüge, Bosslisten, Lockouts, Fortschritt, Herkunft einer Liste | `docs/systems/raids-and-progress.md` |
| Dungeons (Forever **und** Classic), Stufenbereiche, Bosslisten, Flügel, beschwörbare Zusatzbosse, Rollen | `docs/systems/dungeons.md` |
| Artwork, `data/artwork.lua`, `WeintCodex.Artwork`, `media/dungeons/` | `docs/systems/dungeons.md`, Abschnitt *Bilder: kein Spielmaterial, eigenes schon* |
| Herkunft eines Eintrags, `data/sources.lua`, `release`/`announced`/`beta`/`community`/`classic` | `docs/systems/dungeons.md`, Abschnitt *Fünf Arten von Herkunft* |
| Charakterseite, Twinks, Ausrüstungsstand | `docs/systems/character.md` |
| Gruppencheck | `docs/systems/groupcheck.md` |
| Companion-Sync allgemein (Inbox/Outbound, `ProcessInbox`) | `docs/systems/companion-bridge.md` |
| Onboarding-Tour, Update-Changelog-Popup | `docs/systems/onboarding-changelog.md` |
| Release schneiden, Changelog, Patchnote-Stil, Builder | `docs/development/releases.md` |
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
| WeakAuras | Für Forever zunächst nicht unterstützt. |
| Karten- und Bossbilder **aus dem Spiel** | Blizzard hat für Forever keine Dungeonkarten veröffentlicht (im Beta-Client liegt für vier der neun Instanzen überhaupt Material), und das Material gehört Blizzard. Ein geratener Texturpfad zeichnet im Spiel ein grünes Rechteck. **Eigenes** Artwork fällt unter keinen der beiden Gründe: seit 5.2.0.7 trägt die Hall of Thanes fünf eigene Bilder (`media/dungeons/`, `data/artwork.lua`) — sie behaupten nichts über das Spiel, und ein bebilderter Dungeon ist kein besser belegter. `boss.position` sagt weiter in Worten, wo einer steht. |
| Academy, WeintTV, Rotationshelfer | Brauchen ein auswertbares Kampflog. Ob Forever eines hergibt, ist nicht bestätigt — siehe `../Companion-Forever/docs/systems/forever-data.md`, letzter Abschnitt. |
| Ausrüstungs-Alarm, Einkaufsliste, Sockelfenster-Hilfe | Hätten ohne Verzauberungen und Sockel nichts zu melden. |
