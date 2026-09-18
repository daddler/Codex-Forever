# Die Companion-Brücke

**Das Addon geht nie ins Netz.** Alles, was hereinkommt und hinausgeht,
läuft über Dateien im Spielordner oder über einen eingefügten Text.

```
Bot ──HTTP──► Companion ──Datei──► Addon
                        ◄──Datei──
```

Der verbindliche Vertrag für jedes Format steht **drüben**:
`../Companion-Forever/docs/*.md`. Diese Datei beschreibt nur, was auf
dieser Seite damit geschieht.

## Zwei Wege hinein, und warum es zwei sind

| Weg | Datei | Kommt an |
|---|---|---|
| Inbox | `WeintCompanionInboxDB` (SavedVariable) | beim nächsten Laden |
| Live-Brücke | `data/companion_live.lua` (Addon-Datei) | bei jedem `/reload` |

Die Inbox hat einen Konstruktionsfehler, der erst im laufenden Spiel
auffällt: WoW hält SavedVariables im Arbeitsspeicher, schreibt sie bei
`/reload` und beim Abmelden **aus dem Speicher zurück** und liest sie
erst danach wieder ein. Alles, was die Companion in der Zwischenzeit
hineingeschrieben hat, wird von diesem Rückschreiben vernichtet — bevor
das Addon es je zu sehen bekommt.

Eine Lua-Datei im Addon-Ordner hat das Problem nicht: WoW führt sie bei
jedem `/reload` neu aus und schreibt sie niemals zurück.

**Zusammengeführt, nicht gegeneinander ausgespielt.** `ProcessInbox()`
liest beide. Die Live-Datei kann fehlschlagen (Ordner verschoben,
Rechte), während die Inbox geschrieben wurde; sie dann ungelesen zu
leeren wäre der Datenverlust, gegen den beide Wege existieren.

Das Addon kann die Live-Datei nicht leeren — es schreibt keine Dateien.
Es merkt sich deshalb in `SavedData.companionLive.lastStamp`, welchen
Stand es zuletzt eingearbeitet hat, und lässt eine unveränderte
Zustellung beim nächsten `/reload` still liegen.

## Die Reihenfolge in `ProcessQueue`

1. **Erster Durchgang: nur `access_profile`.** Muss vor allem anderen
   laufen. Sonst rutschte beim erstmaligen Verknüpfen genau der Schwung
   Daten noch durch, den das gelieferte Profil eigentlich sperrt.
2. **Zweiter Durchgang: alles andere, mit Herkunftsprüfung.** Trägt eine
   Nachricht eine fremde Community-ID, wird sie verworfen statt
   eingearbeitet — und *eine* gesammelte Warnung ausgegeben, nicht eine
   pro Nachricht.

Eine fehlerhafte Nachricht darf die restliche Warteschlange nicht
mitreissen: jeder Behandler läuft in `pcall`.

## Was hereinkommt

| Typ | Landet in |
|---|---|
| `access_profile` | `core/access.lua` |
| `raid_import` | `modules/sync.lua` (`QuickImport`) |

**Mehr nicht.** `academy_catalog`, `academy_state`, `weinttv_report`,
`weakaura_library`, `stat_weights` und `target_gear` gibt es in dieser
Fassung nicht (siehe `CLAUDE.md`, Abschnitt *What this edition
deliberately does not have*).

Sie werden **nicht abgewiesen, sondern schlicht nicht behandelt**:
`ProcessQueue` läuft nur über Typen, für die es einen Behandler gibt.
Eine Companion, die solche Nachrichten schickt, bekommt dadurch keinen
Fehler.

## Was hinausgeht

| Typ | Ziel | Freigabe |
|---|---|---|
| `character` | Bot (Kalender-Invite) | — |
| `character_report` | nur Companion, lokal | — |
| `character_sheet` | nur Companion, lokal | — |
| `calendar` | Bot | `calendar.view` über die Seite |
| `materials` | Bot | `materials.scan` |
| `loot` | Bot (#loot) | `loot.report` |

`STATE_MESSAGES` (`materials`, `character`, `calendar`,
`character_report`, `character_sheet`) liegen **höchstens einmal** in der
Warteschlange: es zählt nur der letzte Stand, ältere werden ersetzt
statt angehängt.

Jede ausgehende Nachricht trägt die gebundene Community-ID, damit die
Desktop-Seite Verkehr einer anderen Community verwerfen kann.

## `character_sheet` — was leer bleibt, und warum

Die Nachricht wird weiterhin gesendet, aber:

* Die Abschnitte **ZÄHLER** (Verzauberungen/Sockel) und **BIS** bleiben
  leer.
* Die Felder `score`, `grade` und `quality` bleiben **unbesetzt**.
* `completeness` wird gesendet — belegte durch mahnbare Plätze. Das ist
  messbar.

Der Vertrag sieht das ausdrücklich vor
(`../Companion-Forever/docs/character-sheet-bridge.md`, Abschnitt
*Toleranzregeln*): fehlende Abschnitte und Felder sind kein Fehler, und
`readiness()` drüben liefert dann `None` statt `0.0` — ein **leerer**
Ring statt eines roten.

Eine `0` in diese Felder zu schreiben wäre die teuerste Variante: sie
sähe aus wie eine Messung, und der Spieler bekäme einen dauerhaft roten
Vorbereitungsring für etwas, das er nicht abstellen kann.

Die beiden Statusfelder je Platz tragen durchgängig `-`: „dieser Platz
kennt so etwas nicht".

## Versionssperren

`CompanionAtLeast(major, minor, patch)` prüft
`WeintCompanionInboxDB.companionVersion`. Eine zu alte Companion kennt
einen Nachrichtentyp nicht, gäbe ihn in ihren generischen Zweig, POSTete
ihn an den Bot, scheiterte, liesse die Nachricht liegen und
protokollierte im Sync-Takt einen Fehler.

## Die Seite *Companion*

`modules/companionpage.lua` beantwortet die Frage, die vor jeder leeren
Seite steht: **liegt es an der Verbindung, an der Freigabe oder daran,
dass es wirklich nichts gibt?**

Drei Zustände, die dort niemals zusammenfallen:

1. „Noch keine Lieferung" — die Companion hat nie geschrieben.
2. „Lieferung von <Datum>" — sie hat geschrieben, es kam nur nichts
   Neues.
3. „Für dich gesperrt" — es kam etwas, du darfst es nicht sehen.

Und ein Satz, der überall dabeisteht: **die Inbox wird nur beim Laden
gelesen.** Was dort steht, ist der Stand der letzten Lieferung und nie
eine laufende Verbindung. Eine Zeile „verbunden" wäre eine Behauptung
über etwas, das es technisch gar nicht gibt.
