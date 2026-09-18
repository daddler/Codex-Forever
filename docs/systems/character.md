# Charakter: Ausrüstung und Twinks

`modules/charakter.lua` beantwortet zwei Fragen, und nur diese zwei:

1. Was hat dieser Charakter an — und fehlt oder zerbricht davon gerade
   etwas?
2. Welche Charaktere dieses Kontos sollen dem Bot als „meine" gemeldet
   werden?

## Was hier nicht mehr steht

In der Fassung für Mists of Pandaria standen in dieser Datei die
Bewertung von Verzauberungen, Sockelsteinen, Umschmieden,
Tempo-Schwellen und BiS-Listen — knapp achttausend Zeilen. Übrig sind
gut vierhundert.

**Kein Satz davon ist übertragbar.** Welche Verzauberungen es in Forever
gibt, welche Werte etwas bringen und ob es überhaupt Sockel gibt, ist
nicht veröffentlicht. Eine übernommene Bewertung hätte nicht
geschwiegen, sondern jedem Spieler Mängel vorgeworfen, die es in seinem
Spiel gar nicht gibt.

Was bleibt, ist, was der Client selbst beantwortet: belegt oder leer,
heil oder zerbrochen, welche Gegenstandsstufe. Das ist wenig — aber es
ist wahr, und es wird nicht mit der Zeit falsch.

## Die Ausrüstungsplätze kommen vom Client

`SLOT_DEFS` nennt Plätze bei ihrem **Namen** (`HeadSlot`, `RangedSlot`,
…), und `EquipSlots()` löst sie über `GetInventorySlotInfo` auf. Was der
Client nicht kennt, fällt aus der Liste.

Der Grund: Forever läuft auf der modernen Client-API, und ob es dort
einen Distanzplatz gibt, wissen wir nicht. Ein fest verdrahteter Platz
18 stünde sonst auf jedem Charakter als „leer" da.

Aufgelöst wird **beim ersten Zugriff**, nicht zur Ladezeit — und nur
zwischengespeichert, wenn etwas herauskam. Sonst fröre ein zu früher
Aufruf die leere Antwort für die ganze Sitzung ein.

**Nebenhand und Distanz dürfen leer sein.** Ein Zweihandkämpfer trägt
keine Nebenhand; das ist kein Mangel und wird nicht angemahnt. Sie
stehen trotzdem in der Liste.

## `Snapshot()`

```lua
{
    classFile, specDisplay, specKey, role,
    itemLevel, itemLevelAll,     -- oder nil, NIE 0
    slots  = { { id, name, link, itemLevel, broken }, ... },
    empty  = { "<Platzname>", ... },   -- nur mahnbare Plätze
    broken = { "<Platzname>", ... },
}
```

**`Snapshot()` liefert `nil`, wenn der Client nicht geantwortet hat.**
Das ist etwas anderes als eine leere Ausrüstung, und die Übersicht
unterscheidet es: ohne Snapshot steht dort „Willkommen zurück" und
„Ausrüstung konnte nicht gelesen werden", nicht „0 Dinge offen".

`GetAverageItemLevel()` liefert `0`, solange die Gegenstände nicht
geladen sind. Die `0` wird ausdrücklich verworfen — eine ausgebliebene
Antwort ist keine Messung.

## Die Spezialisierung

`CurrentSpec()` probiert drei Wege in dieser Reihenfolge und liefert am
Ende ein ehrliches `nil`:

1. `GetSpecialization()` (moderner Client) → Index in `data/specs.lua`.
2. Kennt der Client einen Baum, den unsere Tabelle nicht führt: seinen
   **Namen** nehmen — aber die Tabelle nicht danach biegen.
3. `GetPrimaryTalentTree()` (Classic-Weg).

**Geraten wird nichts.** Eine falsche Spezialisierung wandert über die
Companion-Brücke bis in den Bot und ordnet den Spieler dort der falschen
Rolle zu.

`GetProfileKey()` liefert den Schlüssel in der Form, die die Brücke
führt: `CLASSFILE_ENGLISCHERBAUM`, versal und ohne Leerzeichen
(`HUNTER_BEASTMASTERY`). Die Gegenseite nimmt ein leeres Feld hin, eine
geratene Spezialisierung nicht.

`data/specs.lua` ist die Spiegelung von `analyzer/data/specs.py` der
Companion — dieselben Schreibweisen, dieselbe Reihenfolge, dieselben
Rollen. Laufen die beiden auseinander, ist das Symptom eine Zeile, die
leer bleibt, ohne dass irgendwo etwas fehlschlägt.

## Twinks

```
SavedData.twinks[<Name>] = { class, level, realm, selected }
```

Gefüllt wird die Tabelle bei jedem Login durch
`Companion.ReportCharacter()`; auf der Seite steht nur, was der Spieler
daran ändern kann — ob ein Charakter dem Bot gemeldet wird.

Ein Umlegen meldet **sofort** neu. Wer einen Twink abwählt, erwartet,
dass der nächste Kalender-Invite ihn nicht mehr kennt, und nicht erst
der übernächste Login.

Sortiert wird alphabetisch: `pairs()` über eine Tabelle hat keine
Reihenfolge, und eine Liste, die zwischen zwei Aufrufen springt, liest
sich wie ein Fehler.
