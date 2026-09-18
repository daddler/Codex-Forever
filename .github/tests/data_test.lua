--------------------------------------------------
-- Die Datentabellen und die Fassungsangaben.
--
--   lua5.1 .github/tests/data_test.lua .
--
-- Zwei Sorten Pruefung stehen hier nebeneinander, und sie haben
-- denselben Grund: beide finden Fehler, die NICHTS ausloesen.
--
--   1. DIE FASSUNG STEHT AN DREI STELLEN. Laufen sie auseinander,
--      laedt das Addon einwandfrei - aber WeintCompanion vergleicht
--      danach zwei verschiedene Zahlen und meldet nach jeder
--      Aktualisierung erneut dasselbe Update. Dieselbe Pruefung
--      macht .github/scripts/release_notes.py fuer die CI; hier steht
--      sie, damit sie schon vor dem Tag laeuft.
--
--   2. DIE LEEREN TABELLEN MUESSEN LEER BLEIBEN DUERFEN. Ein Test,
--      der ueber eine leere Liste laeuft, wird gruen, weil nichts
--      passiert - lautlos und wertlos. Geprueft wird deshalb der
--      MECHANISMUS: dass "unbekannt" nirgends als Null herauskommt.
--      Diese Pruefungen bleiben gueltig, egal was spaeter in den
--      Tabellen steht.
--------------------------------------------------

local ROOT = ... or "."

package.path = ROOT .. "/.github/tests/?.lua;" .. package.path

local stub = require("wow_stub")
stub.Install()
stub.LoadToc(ROOT)

--------------------------------------------------

local failures = 0

local function Check(condition, message)
    if condition then
        print("  ok    " .. message)
    else
        failures = failures + 1
        print("  FEHL  " .. message)
    end
end

local function Section(title)
    print("")
    print("== " .. title)
end

local function ReadFile(relative)
    local file = io.open(ROOT .. "/" .. relative, "r")
    if not file then return nil end
    local body = file:read("*a")
    file:close()
    return body
end

--------------------------------------------------
-- 1. Die Fassung an drei Stellen
--------------------------------------------------

Section("Die Fassung steht ueberall gleich")

local toc = ReadFile("WeintCodex.toc")
local tocVersion = toc and toc:match("##%s*Version:%s*([%d%.]+)")

Check(tocVersion ~= nil, "WeintCodex.toc nennt eine Fassung")
Check(WeintCodex.Version == tocVersion,
    "core/main.lua (" .. tostring(WeintCodex.Version) .. ") == .toc ("
    .. tostring(tocVersion) .. ")")

local newest = WeintCodex_ChangelogData and WeintCodex_ChangelogData[1]
Check(newest ~= nil, "data/changelog.lua hat einen Eintrag")
Check(newest and newest.version == tocVersion,
    "data/changelog.lua (" .. tostring(newest and newest.version)
    .. ") == .toc (" .. tostring(tocVersion) .. ")")

-- Vier Stellen: sonst haette die Fassung 5.0.0 im Dateinamen des ZIPs
-- und 5.0.0.0 im Addon.
Check(tocVersion and tocVersion:match("^%d+%.%d+%.%d+%.%d+$") ~= nil,
    "Die Fassung hat vier Stellen")

--------------------------------------------------
-- 2. Die Schlachtzuege
--------------------------------------------------

Section("Schlachtzuege")

Check(type(WeintCodex_Raids) == "table", "data/raids.lua ist geladen")
Check(#WeintCodex_Raids > 0, "es sind Schlachtzuege eingetragen")

local ids = {}
for _, raid in ipairs(WeintCodex_Raids) do
    Check(type(raid.id) == "string" and raid.id ~= "",
        "Schlachtzug hat eine Kennung")
    Check(ids[raid.id] == nil, "Kennung " .. tostring(raid.id) .. " ist eindeutig")
    ids[raid.id] = true

    Check(type(raid.name) == "string" and raid.name ~= "",
        raid.id .. " hat einen Namen")
    Check(type(raid.size) == "number" and raid.size > 0,
        raid.id .. " hat eine Gruppengroesse")
    Check(type(raid.bosses) == "table",
        raid.id .. " hat eine Bossliste (leer ist erlaubt)")
end

-- DIE ENTSCHEIDENDE PRUEFUNG DIESES ABSCHNITTS. Solange keine
-- Bossliste gefuellt ist, MUSS KnownBossCount nil liefern und nicht 0 -
-- sonst stuende auf der Uebersicht eine gemessene Null ueber etwas,
-- das nie gemessen wurde. Sobald jemand den ersten Boss eintraegt,
-- kippt die Pruefung auf den anderen Zweig, ohne dass hier etwas zu
-- aendern waere.
local total = 0
for _, raid in ipairs(WeintCodex_Raids) do
    total = total + #raid.bosses
end

local counted = WeintCodex.RaidData.KnownBossCount()

if total == 0 then
    Check(counted == nil,
        "ohne Bosslisten liefert KnownBossCount nil, nicht 0")
else
    Check(counted == total,
        "mit Bosslisten liefert KnownBossCount die Summe (" .. total .. ")")
end

for _, raid in ipairs(WeintCodex_Raids) do
    Check(WeintCodex.RaidData.HasBosses(raid) == (#raid.bosses > 0),
        "HasBosses(" .. raid.id .. ") stimmt mit dem Bestand ueberein")
end

Check(WeintCodex.RaidData.Get("gibtesnicht") == nil,
    "eine unbekannte Kennung liefert nil")

--------------------------------------------------
-- 3. Die Spezialisierungen
--------------------------------------------------

Section("Spezialisierungen")

Check(type(WeintCodex_Specs) == "table", "data/specs.lua ist geladen")

-- Neun Klassen, je drei Baeume. Das ist keine Vermutung, sondern die
-- Aufstellung, die das Spiel seit seiner ersten Fassung hat - und sie
-- muss mit analyzer/data/specs.py der Companion uebereinstimmen.
local perClass = {}
for _, spec in ipairs(WeintCodex_Specs) do
    perClass[spec.class] = (perClass[spec.class] or 0) + 1
end

local classCount = 0
for classFile, count in pairs(perClass) do
    classCount = classCount + 1
    Check(count == 3, classFile .. " hat drei Talentbaeume")
end

Check(classCount == 9, "neun Klassen")
Check(#WeintCodex_Specs == 27, "siebenundzwanzig Spezialisierungen")

-- Die Schluessel muessen eindeutig sein: ueber sie laeuft die
-- Zuordnung zur Companion.
local keys = {}
for _, spec in ipairs(WeintCodex_Specs) do
    local key = WeintCodex.Specs.Key(spec)
    Check(keys[key] == nil, "Schluessel " .. key .. " ist eindeutig")
    keys[key] = true
end

-- DER EINE BAUM OHNE ROLLE. "Wilder Kampf" traegt Katze und Baer;
-- welche davon jemand gerade ist, entscheidet die Gestalt und nicht
-- der Baum. Ihn als Schadensausteiler zu fuehren waere ein Vorwurf an
-- jeden Baertank.
local feral
for _, spec in ipairs(WeintCodex_Specs) do
    if spec.class == "DRUID" and spec.english == "Feral" then feral = spec end
end
Check(feral ~= nil, "Wilder Kampf ist eingetragen")
Check(feral and feral.role == nil,
    "Wilder Kampf traegt keine Rolle, und das ist die richtige Antwort")

-- Jede andere Spezialisierung MUSS eine Rolle haben: eine fehlende
-- waere hier keine Aussage, sondern eine Luecke.
for _, spec in ipairs(WeintCodex_Specs) do
    if not (spec.class == "DRUID" and spec.english == "Feral") then
        Check(spec.role == "dps" or spec.role == "tank" or spec.role == "healer",
            spec.class .. "/" .. spec.english .. " hat eine Rolle")
    end
end

Check(WeintCodex.Specs.ByIndex("WARRIOR", 99) == nil,
    "ein unbekannter Baumindex liefert nil")
Check(#WeintCodex.Specs.ForClass("GIBTESNICHT") == 0,
    "eine unbekannte Klasse liefert eine leere Liste")

--------------------------------------------------
-- 4. Die Beobachtungsliste der Materialien
--------------------------------------------------

Section("Materialien")

-- Sie ist absichtlich leer (siehe modules/materials.lua). Geprueft
-- wird deshalb nicht der Bestand, sondern dass die Seite mit einem
-- leeren Bestand umgehen kann, ohne eine Null zu behaupten.
local items = WeintCodex.Materials.GetItems()
Check(type(items) == "table", "GetItems liefert immer eine Tabelle")

for _, item in ipairs(items) do
    Check(item.target == nil or type(item.target) == "number",
        "ein Sollbestand ist eine Zahl oder gar nicht da")
end

--------------------------------------------------
-- 5. Die Zugriffsfreigaben
--------------------------------------------------

Section("Zugriffsprofil")

-- Die neun Freigaben muessen mit core/access_roles.py der Companion
-- uebereinstimmen. Laufen sie auseinander, ist das Symptom ein
-- Bereich, der gesperrt bleibt, obwohl der Bot ihn freigegeben hat.
local EXPECTED_FEATURES = {
    "raids.view", "raids.edit",
    "calendar.view", "calendar.invite",
    "materials.view", "materials.scan",
    "bossguides.tips", "weinttv.raid", "loot.report",
}

local source = ReadFile("core/access.lua")
for _, key in ipairs(EXPECTED_FEATURES) do
    Check(source and source:find('"' .. key .. '"', 1, true) ~= nil,
        "core/access.lua kennt " .. key)
end

--------------------------------------------------

print("")
if failures == 0 then
    print("BESTANDEN")
    os.exit(0)
end

print(failures .. " Pruefung(en) fehlgeschlagen.")
os.exit(1)
