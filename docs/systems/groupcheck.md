# Gruppencheck

Die Ausrüstung der ganzen Gruppe vor dem Pull — die Frage, die man sonst
vierundzwanzig Mal einzeln stellt.

## Was geprüft wird

| | |
|---|---|
| **Plätze** | Trägt jeder etwas auf jedem Platz? |
| **Zustand** | Ist etwas zerbrochen? |
| **Stufe** | Wie weit liegen die Gegenstandsstufen auseinander? |

**Diese Seite bewertet nicht, sie zählt.** Ob eine Ausrüstung „gut" ist,
sagt sie nicht — dafür bräuchte es Wertungen, die es für Forever nicht
gibt. „Platz leer" ist unstrittig; alles darüber hinaus wäre ein
Vorwurf.

In der MoP-Fassung zählte diese Seite fehlende Verzauberungen und leere
Sockel. Beides gibt es hier nicht, und beides hätte, aus Mists of
Pandaria übernommen, jedem Spieler Mängel vorgeworfen, die sein Spiel
gar nicht kennt.

## Drei Regeln, die nicht Geschmack sind

### Nicht erreichbar ist kein Befund

Wer zu weit weg, offline oder in einer anderen Phase ist, lässt sich
nicht inspizieren. Diese Zeilen bleiben **leer und sagen warum**, statt
als „0 Mängel" in die Zusammenfassung zu wandern.

Eine Übersicht, die Ungeprüftes als geprüft zählt, ist schlimmer als gar
keine: sie behauptet eine Kontrolle, die nicht stattgefunden hat.

Die Zusammenfassung führt deshalb vier Zahlen: *Mitglieder*, *ohne
Befund*, *mit Befund* und **`nicht geprüft`**.

### Eine unbekannte Gegenstandsstufe ist keine Null

Der Client beantwortet die Frage nach einem fremden Gegenstand nicht
immer. `AverageItemLevel()` liefert dann `nil`, und der Gegenstand
**fällt aus dem Durchschnitt heraus**, statt ihn nach unten zu ziehen.

In der Zeile steht ein Gedankenstrich. Wie viele Gegenstände nicht
gelesen werden konnten, steht im Detailbereich.

### Die Schlange läuft einzeln

Der Server beantwortet immer nur **eine** Inspektion, und zu schnelles
Nachfassen liefert die Daten des vorigen Spielers. Deshalb ein Eintrag
nach dem anderen, mit Zeitüberschreitung (2 s) und Pause (0,7 s)
dazwischen.

## Die Bausteine

Die Ausrüstungsplätze kommen aus `modules/charakter.lua`
(`EquipSlots()`) und damit vom Client. Eine zweite, fest verdrahtete
Liste wäre genau die Doppelpflege, an der solche Seiten auseinanderlaufen.

Kein Tooltip-Scan: sechzehn Plätze mal vierundzwanzig Spieler wären eine
Zumutung für den Client. Alles, was diese Seite liest, steckt im
Item-Link und in der Haltbarkeitsabfrage.

## Bedienung

| | |
|---|---|
| `/wc gruppe` | Seite öffnen |
| `/wc gruppe prüfen` | öffnen und sofort durchlaufen |
| Knopf *Prüfen* | in der Titelleiste, zeigt während des Laufs den Fortschritt |
| Filter *Nur Befunde* | blendet fehlerfreie Zeilen aus |

Ein Klick auf eine Zeile bringt den Spieler in den Detailbereich rechts;
die Spalte *Befund* ist gekürzt, die ganze Liste hängt am Tooltip und
dort.
