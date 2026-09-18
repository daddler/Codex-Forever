# Einführung und Update-Popup

`core/onboarding.lua` trägt beides — sie teilen sich dasselbe Fenster.

| | wann | Quelle |
|---|---|---|
| **Einführung** | beim ersten Login, und auf `/wc tour` | `TOUR_STEPS` in derselben Datei |
| **Update-Popup** | nach einem Versionswechsel | `data/changelog.lua` |

## Die Einführung

Elf Seiten in fünf Kapiteln: *Erste Schritte*, *Der Abend*, *Dein
Charakter*, *Die Gilde*, *System*.

`TOUR_EDITION` steht auf `1`. Wird die Tour neu geschrieben, steigt die
Zahl — und alle bekommen sie noch einmal, auch wer das Addon seit
Jahren benutzt.

**Eine Seite mit `feature` wird ausgelassen**, wenn das Zugriffsprofil
den Bereich nicht freigibt. Sonst bewirbt die Tour Bereiche, die der
Spieler gar nicht öffnen kann. `TOUR_STEPS` bleibt dabei unangetastet:
ein später eintreffendes Profil blendet die Seiten beim nächsten Aufruf
wieder ein.

### Zwei Hervorhebungen, zwei Bedeutungen

| | Farbe | heisst |
|---|---|---|
| `A(text)` | Akzent | **das kann man anklicken oder tippen** (Seiten, Reiter, Knöpfe, Slash-Befehle) |
| `E(text)` | Weiss | betont einen Satz |

Beides in einer Farbe zu führen wäre das Ende dieser Auskunft — eine
Farbe, die auch Fliesstext trifft, sagt nichts mehr darüber, worauf man
zeigen kann.

### Die Regeln für jeden Text

Dieselben wie für die Patchnotes (`docs/development/releases.md`):

1. Kein Dateiname, kein Funktionsname, kein SavedVariables-Schlüssel.
   Seitennamen und Slash-Befehle sind ausdrücklich erlaubt.
2. Wirkung vor Ursache. Was bringt mir das, was sehe ich, was muss ich
   tun.
3. Hervorgehoben wird nur, worauf man klicken kann.

### Was diese Tour zusätzlich sagt

Eine Seite der Tour (*Was WeintCodex noch nicht weiss*) erklärt
ausdrücklich, dass die Bosslisten leer sind und warum, und dass es kein
Simmen, keine WeakAuras, keine Sockel und keine
Verzauberungsempfehlungen gibt.

Das ist keine Entschuldigung, sondern Bedienung: ohne diesen Satz hält
ein neuer Spieler den Leerzustand für einen Fehler und meldet ihn.

## Das Update-Popup

`Check()` vergleicht `WeintCodex.Version` mit dem zuletzt gesehenen
Stand und zeigt **alle** Changelog-Einträge dazwischen — wer zwei
Versionen übersprungen hat, bekommt beide.

Der Text ist beliebig lang. Deshalb hat das Fenster zwei Höhen: eine
Grundhöhe, die jede Tourseite trägt, und eine Grenze, ab der stattdessen
gescrollt wird. Die Grenze liegt **unter** der kleinsten zulässigen Höhe
des Hauptfensters, damit das Popup auch dort vollständig hineinpasst.

Die Bildlaufleiste erscheint nur, wenn es wirklich etwas zu rollen gibt.
Eine Leiste ohne Bildlauf ist ein Bedienelement, das nichts tut.

## Beim Release

`data/changelog.lua` braucht bei **jedem** Release einen neuen Eintrag,
ganz oben, mit derselben Fassung wie `.toc` und `core/main.lua`. Fehlt
er, bleibt das Popup leer — unsichtbar in jedem Test, sichtbar bei jedem
Nutzer.

`.github/scripts/release_notes.py` prüft das und bricht sonst ab.
