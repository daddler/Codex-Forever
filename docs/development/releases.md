# Ein Release schneiden

## Die Kurzfassung

1. `data/changelog.lua` — neuen Eintrag **ganz oben** einfügen.
2. `CHANGELOG.md` — denselben Stand als Abschnitt.
3. `WeintCodex.toc` — `## Version` erhöhen.
4. `core/main.lua` — `WeintCodex.Version` auf dieselbe Zahl.
5. Prüfen, commiten, pushen.
6. Unter **Actions → „Release auf Knopfdruck"** den Tag `v<Fassung>`
   eintragen und starten.

Das war es. Der Rest passiert von selbst.

## Die vier Stellen, und warum sie geprüft werden

| Datei | Wofür |
|---|---|
| `WeintCodex.toc` (`## Version`) | Was WeintCompanion als *installierte* Fassung liest |
| `core/main.lua` (`WeintCodex.Version`) | Die Zeile im Chat beim Laden, die Marke in der Titelleiste |
| `data/changelog.lua` (oberster Eintrag) | Das Popup im Spiel nach einem Update |
| `CHANGELOG.md` (oberster Abschnitt) | Der Release-Text auf GitHub **und** die Änderungsansicht der Companion |

Laufen sie auseinander, **schlägt nichts fehl**. Das Addon lädt, das ZIP
entsteht, die Installation läuft — und die Update-Prüfung der Companion
vergleicht danach für immer eine Fassung, die sich selbst anders nennt.

`.github/scripts/release_notes.py` prüft alle vier gegen den Tag und
bricht sonst ab. Er läuft in beiden Release-Workflows **vor** dem Bauen
und zusätzlich bei jedem Push (ohne Tag, also nur die Dateien
gegeneinander).

### Die Schreibweise des Tags zählt buchstäblich

Der Tag muss **genau** `v` plus die Fassung aus der `.toc` sein.

In der MoP-Fassung lag das Release 2.6.0.3 einmal als `v.2.6.0.3` vor —
ein Punkt zuviel. Alles lief durch; die Companion vergleicht an dieser
Stelle aber *Zeichenketten* (führendes `v` ab, Rest gegen die `.toc`).
Aus `.2.6.0.3` wird nie `2.6.0.3`, und die Update-Prüfung meldete nach
jeder Aktualisierung erneut dasselbe Update. Genau dagegen prüft
`spelling_problem()` im Skript.

## Was die Workflows tun

### `ci.yml` — bei jedem Push

1. Syntax jeder Lua-Datei (`luac5.1 -p`).
2. `load_test.lua` — lädt das Addon gegen eine Attrappe des Clients.
3. `data_test.lua` — Datentabellen und Fassungsangaben.
4. Die vier Fassungsstellen gegeneinander.

**Punkt 2 ist der wichtige.** Forever ist nicht erschienen; es gibt kein
Spiel, in dem sich etwas ausprobieren liesse. `luac -p` findet
ausschliesslich Syntaxfehler — eine Datei, die in der `.toc` fehlt oder
zu früh steht, ist syntaktisch tadellos und bricht trotzdem beim Laden.

### `manual-release.yml` — der übliche Weg

Legt Tag, Release, ZIP und Prüfsumme in einem Zug an. Ohne eigenen Text
nimmt es den passenden Abschnitt aus `CHANGELOG.md`.

Warum es diesen Workflow zusätzlich gibt: ein vom `GITHUB_TOKEN`
erstelltes Release löst den Workflow `release.yml` aus
Sicherheitsgründen **nicht** aus. Wer das Release von Hand über die
Oberfläche anlegt, bekommt `release.yml`; wer den Knopf drückt, bekommt
diesen hier. Beide bauen dasselbe ZIP.

### `release.yml` — wenn ein Release von Hand angelegt wird

Baut das ZIP nach, hängt es samt Prüfsumme an und trägt einen leeren
Release-Text aus `CHANGELOG.md` nach.

## Was im ZIP landet

Der Ordner im ZIP **muss** `WeintCodex` heissen und eine
`WeintCodex.toc` enthalten — danach sucht der Installer der Companion
(`core/installer.py` drüben). Der Workflow prüft das mit einem
`test -f`, bevor er packt.

Draussen bleiben: `.git`, `.github`, `.gitignore`, `docs`, `graphify-out`,
`CLAUDE.md`, `README.md`, `LICENSE`, `media/logo.png`, `media/logo.blp`.
Ein Testlauf, eine Entwicklerdokumentation und generierte Wissensgraph-
Reports gehören nicht in den Addon-Ordner eines Spielers; die beiden
Logo-Dateien laedt ohnehin nichts im Addon (nur README.md fuers
GitHub-Vorschaubild, unabhaengig vom ZIP).

**`CHANGELOG.md` bleibt ausdrücklich drin.** WeintCompanion liest sie
aus dem *installierten* Addon-Ordner (`core/changelog_source.py` drüben,
`addon_entries()`). Fehlt sie, fällt die Änderungsansicht auf den Text
des GitHub-Releases zurück — und zeigt damit nur die jeweils letzte
Fassung statt der ganzen Reihe. Der Workflow prüft das mit einem
`test -f`, damit es nicht noch einmal still verlorengeht.

Neben dem ZIP wird eine `.sha256` veröffentlicht. Die Companion prüft
sie, wenn sie da ist, und **warnt nur**, wenn sie fehlt — sie blockiert
den Download nicht (`core/installer_workflow.py` drüben).

## Der Patchnote-Stil

Gilt für `CHANGELOG.md`, `data/changelog.lua`, die Tour und jeden
anderen Text, den ein Spieler zu sehen bekommt.

**Drei Regeln:**

1. **Was der Spieler merkt, nicht was umgebaut wurde.** „Auf einem Twink
   verlangt WeintCodex keine Verzauberungen mehr" — nicht „OptIn.Scope()
   entscheidet jetzt auch Active()".
2. **Kein Dateiname, kein Funktionsname, kein SavedVariables-Schlüssel.**
   Seitennamen und Slash-Befehle sind ausdrücklich erlaubt: sie sind
   Bedienung, nicht Innenleben.
3. **Hervorgehoben wird nur das Erste.** Der erste Halbsatz in
   Akzentfarbe (`|cff7C6CFF…|r`), der Rest in Ruhe. Eine Farbe, die auch
   Fliesstext trifft, sagt nichts mehr.

Kein „wir", kein „Bugfix", keine Versionsnummern im Fliesstext.

In `CHANGELOG.md` darf ein Abschnitt **`### Technisch`** ans Ende. Dort
gelten die Regeln 1 und 2 nicht — dieser Teil ist für Entwickler, und
das Popup im Spiel liest ihn nicht.

## Vor dem Commit

```bash
luac5.1 -p $(find core data modules ui -name '*.lua')
lua5.1 .github/tests/load_test.lua .
lua5.1 .github/tests/data_test.lua .
```

Ein grüner Lauf heisst **„es lädt"**, nie „es funktioniert". Was eine
Seite anzeigt, ob eine Rechnung stimmt und ob der echte Client dieselben
Antworten gibt, sagt keiner dieser Läufe.

## Die Schnittstellennummer

`## Interface: 120000, 16001` in der `.toc` ist eine **benannte Vermutung**
(16001 seit 6.0.0.0, aus einem Bericht über den Beta-Client, siehe
Kommentar in der `.toc`):
Forever ist nicht erschienen, und die Nummer des Clients ist nicht
belegt. Stimmt sie nicht, erscheint das Addon in der Liste als
„veraltet" und lädt nur mit gesetztem Haken bei *Veraltete AddOns
laden*.

Es ist **eine Zeile**, die dann zu ändern ist, und keine Datei darunter
hängt daran. Dieselbe Entscheidung hat die Companion für den Ordnernamen
des Spiels getroffen (`_forever_` in `core/wow_clients.py`): eine
benannte Vermutung an genau einer Stelle ist besser als eine stille an
vielen.
