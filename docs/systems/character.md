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

## Lehrer *(seit 6.6.0.0)*

Eigener Eintrag „Lehrer“ in der Navigation (Gruppe Leveln,
`modules/trainer.lua`, `WeintCodex.Trainer`), nach dem Vorbild des Addons
*What's Training?*: welche Zauber der Klassenlehrer jetzt lehrt, was fehlt,
was in den nächsten Stufen kommt, was es kostet – und wo man welche
Waffenfertigkeit lernt.

**Zwei Bestände, nie vermischt.**

* **Was es gibt** steht in `data/trainer.lua` (`WeintCodex.TrainerData`):
  je Klasse Zauber mit Stufe, Kosten (Kupfer), `requiredIds` (Vorstufe),
  `requiredTalentId`, `race`/`faction`-Beschränkung und `pet` (Tier-
  ausbildung des Jägers); `ranks` für Fähigkeiten, deren höherer Rang den
  niedrigeren ersetzt; `WEAPONS` und `MASTERS` (Waffenmeister mit Karte
  und Lage). Herkunft **`community`**: übernommen aus *What's Training?*
  (Forever-Fassung 11.0.0-beta7, MIT-Lizenz – der Lizenztext steht im Kopf
  der Datei, wie die Lizenz es verlangt). Nur Daten, kein Code, keine
  Bilder. 6.9.0.6: gegen Fassung 11.0.0-beta10 abgeglichen (Zauber aller neun
  Klassen, Ränge, Tierausbildung, Waffenfertigkeiten, Waffenmeister) –
  keine Abweichung; neu dort sind nur Rufrabatte, die WeintCodex
  weiterhin nicht einrechnet. Seit 6.14.0.2 ist jede Klasse eine
  Funktion, gebaut beim ersten Zugriff auf `T.CLASSES[klasse]` (Metatabelle;
  `pairs(T.CLASSES)` geht deshalb nicht) – gebraucht wird nur die eigene,
  die acht anderen kosteten als Tabellen gut 270 KB.
* **Ob etwas gelernt ist**, fragt die Seite den Client
  (`C_SpellBook.IsSpellKnown/IsSpellInSpellBook`, `IsPlayerSpell`). Ein
  ersetzter niedrigerer Rang zählt als gelernt (`ranks`), weil der Client
  ihn nicht mehr meldet.

**Fächer** (`TR.SECTIONS`): Jetzt lernbar · Vorstufe fehlt · Nächste
Stufen (bis zwei über der eigenen) · Später · Braucht ein Talent ·
Tierausbildung · Gelernt (standardmäßig eingeklappt, Knopf „Gelernte
zeigen“).

**Die Rechnung** *(seit 6.6.2.1, Beta-Test: „Kosten sind aufgelistet,
aber eine Rechnung, ob man überhaupt so viel Gold besitzt“)*. Oben in der
Zauberkarte drei Zellen: *Jetzt lernbar* (Anzahl · Kosten), *Dein Gold*,
*Danach* bzw. *Es fehlen*; darunter eine Zeile: „Reicht für n von m“ (die
Liste der Reihe nach gekauft – sie steht nach Stufe, wie der Lehrer sie
anbietet), was die nächsten zwei Stufen zusammen kosten und ob das Gold
dafür reicht, und was Waffenfertigkeiten extra kosten. In *Jetzt lernbar*
steht ein Preis rot, sobald die **laufende Summe** das Gold übersteigt –
nicht erst, wenn ein einzelner Zauber zu teuer ist. Der Detailbereich
wiederholt die Rechnung mit Waffen. `TR.Budget(state, cat, weapons)`
rechnet, `TR.Verdict(rest)` formuliert („bleiben …“/„fehlen …“), die
Startseite nutzt beide. Meldet der Client kein Gold (`money = nil`), gibt
es **kein Urteil** – „unbekannt“ ist nicht 0 (`unknown ≠ 0`).

**Tierausbildung ohne Zustand.** Ob der Begleiter eine Fähigkeit kennt,
sagt nur der Tierausbilder; die Seite behauptet weder „gelernt“ noch
„fehlt“ (`unknown ≠ false`).

**Waffenfertigkeiten**: gelernt / lernbar / ab Stufe N, darunter die
Waffenmeister der eigenen Fraktion mit Knopf „Karte“ – derselbe Weg wie
die Questgeber im Dungeonkompendium (`WeintCodex.QuestMap.Show`, dritter
Parameter ersetzt die Tooltipzeile: „Lehrt: Dolche“).

**Nicht übernommen:** Hexenmeister-Grimoires (der Client sagt nicht, ob
der Begleiter sie kann), Rufrabatte beim Lehrer, die Ignorierliste (der
Beta-Client speichert nichts über ein Neuladen), die Einbindung ins
Zauberbuch des Spiels (Taint-Risiko an geschützten Reitern).

**Die Navigationsspalte ist damit voll**: 644 von 684 px, genau die
40 px Luft, die `load_test.lua` verlangt. Ein weiterer Eintrag braucht
vorher eine Entscheidung, was zusammengelegt wird. Seit 6.6.2.1 steht
der Lehrer in der Gruppe **Leveln** (Übersicht, Charakter, Lehrer,
Dungeons, Gruppencheck); Schlachtzüge, Anmeldung und Kalender stehen in
**Schlachtzug** darunter – gleich viele Gruppen, gleich viele Einträge,
kein Pixel mehr.

## Berufe *(seit 6.14.0.0)*

`modules/professions.lua` (`WeintCodex.Professions`), Navigation „Berufe“
unter Leveln, `/wc berufe`. Je Beruf: was du bei deiner Fertigkeit jetzt
lernen kannst, was dir noch Punkte bringt, was neu in Forever ist – und wo
der nächste Berufslehrer steht.

**Zwei Bestände, nie vermischt** (wie beim Klassenlehrer):

* **Was es gibt** – `data/professions.lua`, **erzeugt** von
  `.github/scripts/import_foreverguide.py` aus dem Addon ForeverGuide
  1.25.6: 2.216 Rezepte in zwölf Berufen (Zauber, Gegenstand, Lernstufe,
  Schwellen gelb/grün/grau, Reagenzien, Lehrer oder Rezeptgegenstand,
  Händlergunst, Stand *neu/geändert/wie Classic*), 223 Lehrer mit Lage,
  Fraktion und Rang (1 bis 75 … 4 bis 300). ForeverGuide hat die Rezepte
  aus dem Forever-Client gelesen (Build 1.60.1, über wowforevertalents.com),
  die Lehrer aus der Questie-Datenbank für Forever – Herkunft `community`.
  Händler für Rezepte stammen aus Classic (`classic`). **Weggelassen:** der
  Abschnitt „Season of Discovery“ (280 Rezepte, im Client, ob in Forever
  lernbar, ist nicht belegt). Nur Fakten übernommen, keine Texte; die Namen
  nennt der Client (englisch nur als Rückfall, `P.NAMES`).
  Die Rezepte stehen als Zeilen je Beruf und werden erst beim Aufschlagen
  gelesen (`PRO.Recipes`) – als Tabellen kosteten 2.216 Rezepte ein
  Vielfaches.
* **Wie weit du bist** – der Client: Fertigkeit über
  `GetProfessions`/`GetProfessionInfo` (sechs Plätze *mit Lücken* – kein
  `ipairs`), sonst `GetNumSkillLines`/`GetSkillLineInfo` (Name des
  Berufszaubers). **Was du schon kannst**, liest die Seite aus deinem
  Berufsfenster, wenn es offen ist (`C_TradeSkillUI.GetAllRecipeIDs`/
  `GetRecipeInfo().learned`, sonst `GetTradeSkillRecipeLink` und
  `GetCraftRecipeLink`), und merkt es je Charakter
  (`SavedData.professions["Name-Realm"]`); neu Gelerntes trägt
  `NEW_RECIPE_LEARNED` nach. Vorher sagt nur ein „ja“ des Clients
  (`Trainer.Known`) etwas – „lernbar“ heißt dann „ab deiner Fertigkeit,
  vielleicht schon gelernt“, und die Seite sagt das. Welche dieser
  Abfragen Forever beantwortet, misst `/wcui prüfen` („Berufe“).
  **Gemessen** (6.14.0.1, Client 1.60.1 Build 70235, Jäger Stufe 16):
  Fertigkeit über `GetProfessions` (`GetSkillLineInfo` gibt es nicht);
  Gelerntes über `C_TradeSkillUI` (`GetTradeSkillRecipeLink` und
  `GetCraftRecipeLink` gibt es nicht) – `TRADE_SKILL_SHOW` 1,
  `TRADE_SKILL_LIST_UPDATE` 3; Lederverarbeitung: 592 Nummern vom Client,
  505 davon im Bestand, 6 gelernt. Die übrigen 87 stehen nicht im Bestand
  (vermutlich der weggelassene Abschnitt „Season of Discovery“ – nicht
  nachgeprüft). Ortsnamen der Lehrer nennt der Client: auf Forever teils
  englisch („Ironforge“, „Stormwind“, „Ashenvale“), teils deutsch
  („Wald von Elwynn“, „Das Brachland“) – so angezeigt, nicht übersetzt.

**Fächer** mit Fertigkeit: Beim Lehrer lernbar · Als Rezept lernbar ·
Bringt noch Fertigkeit (gelernt, unter Grau) · Bald (bis 25 Punkte über
dir) · Später · Lernstufe unbekannt · Gelernt, bringt nichts mehr – die
letzten drei zugeklappt („Alle zeigen“). Ohne Fertigkeit nach Rängen
(Lehrling … Fachmann), der erste offen. Die Schwierigkeit färbt wie im
Berufsfenster (`PRO.Difficulty`; Farben `skillOrange`… in `core/ui.lua`).
Die Lernstufe kann über der gelben Schwelle liegen (ein Rezept ist ab 75
lernbar und ab 55 schon grau) – kein Fehler der Daten. Lernstufe 0: mit
dem Beruf gelernt.

**Lehrer** (rechts): deine Fraktion; wer deinen **nächsten Rang** lehrt,
zuerst (aus der Obergrenze deiner Fertigkeit: 75 → Geselle …). Darin seit
6.14.0.1 der **nächste** zuerst: Entfernung aus der Weltlage, die der
Client rechnet (`C_Map.GetWorldPosFromMapPos` für Lehrer und Spieler,
nur auf demselben Kontinent); ohne Weltlage (in Instanzen) die eigene
Karte, dann der **niedrigere** Rang – die Fachleute stehen meist weit
draußen (gemeldet: ein Fachmann im Hinterland stand vor dem Gesellen in
Eisenschmiede). Die Zeile nennt Ort und „bis 150“, der Rangname steht im
Tooltip (vorher schnitt er den Ort ab). „Karte“ setzt die Marke
(`QuestMap.Show`). Annora (Verzauberkunst, Fachmann, in Uldaman) steht
ohne Lage – ohne Karte.

**Grenzen statt Zahlen** (6.14.0.1): Ohne Blick ins Berufsfenster nennt
der Detailbereich „Jetzt lernbar: bis zu 4“ (manches kannst du vielleicht
schon) und „Bringt Fertigkeit: mind. 6“ (was der Client als gelernt
bestätigt); erst danach feste Zahlen. Über der Liste erklärt eine Zeile
die vier Zahlen je Rezept (lernbar ab · gelb · grün · grau ab).
`/wcui prüfen` zählt die Ereignisse des Berufsfensters seit dem Laden und
beim letzten Lesen, wie viele Rezeptnummern der Client nannte und wie
viele davon im Bestand stehen – passen sie nicht, ist das ein Befund.

Zeilen werden wiederverwendet (500 Rezepte der Lederverarbeitung wären
sonst bei jedem Aufschlagen 500 neue Rahmen). Die Startseite bekommt den
Schritt „Beruf“ nur mit bekanntem Gelernten (`HM.Professions`).
