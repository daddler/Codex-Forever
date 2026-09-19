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
-- aendern waere. Genau das ist mit dem Beta-Client passiert.
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
-- 2a. KEINE BOSSLISTE OHNE HERKUNFT
--------------------------------------------------
-- DIE WICHTIGSTE NEUE PRUEFUNG DIESER FASSUNG. Die Bosslisten stammen
-- aus dem Beta-Client und sind von Blizzard nicht bestaetigt. Das
-- darf im Bestand stehen - aber nur, solange jede Liste sagt, woher
-- sie kommt. Eine Liste ohne `bossSource` waere wieder genau der
-- Zustand, den die leere Tabelle vermieden hat: etwas, das dasteht,
-- ohne dass jemand sagen koennte, worauf es sich stuetzt.

Section("Keine Bossliste ohne Herkunft")

for _, raid in ipairs(WeintCodex_Raids) do
    if #raid.bosses > 0 then
        local source = WeintCodex.RaidData.BossSource(raid)
        Check(type(source) == "table",
            raid.id .. ": die Bossliste nennt ihre Herkunft")
        Check(source and (source.kind == "beta" or source.kind == "release"),
            raid.id .. ": die Herkunft ist beta oder release")
        Check(source and type(source.label) == "string" and source.label ~= "",
            raid.id .. ": die Herkunft hat einen Anzeigetext")

        -- Eine vorlaeufige Liste MUSS einen Hinweistext liefern, eine
        -- bestaetigte MUSS keinen liefern. Faellt der Hinweis weg,
        -- stuende die Liste da, als stuende sie fest.
        local label = WeintCodex.RaidData.BossSourceLabel(raid)
        if source and source.kind == "release" then
            Check(label == nil,
                raid.id .. ": eine bestaetigte Liste braucht keinen Zusatz")
            Check(WeintCodex.RaidData.BossesConfirmed(raid) == true,
                raid.id .. ": bestaetigt heisst bestaetigt")
        else
            Check(type(label) == "string" and label:find("Vorl") ~= nil,
                raid.id .. ": eine vorlaeufige Liste wird als vorlaeufig ausgewiesen")
            Check(WeintCodex.RaidData.BossesConfirmed(raid) == false,
                raid.id .. ": im Zweifel NICHT bestaetigt")
        end

        -- Die Bosse selbst: Kennung, Name, Reihenfolge. Die
        -- Reihenfolge muss der Position entsprechen - laeuft sie
        -- auseinander, zeigt die Seite eine andere Pullreihenfolge
        -- an, als die Liste meint.
        local bossIds = {}
        for index, boss in ipairs(raid.bosses) do
            Check(type(boss.id) == "string" and boss.id ~= "",
                raid.id .. "/" .. index .. " hat eine Kennung")
            Check(bossIds[boss.id] == nil,
                raid.id .. ": Bosskennung " .. tostring(boss.id) .. " ist eindeutig")
            bossIds[boss.id] = true
            Check(type(boss.name) == "string" and boss.name ~= "",
                raid.id .. "/" .. index .. " hat einen Namen")
            Check(boss.order == index,
                raid.id .. "/" .. index .. ": order stimmt mit der Position ueberein")
        end
    else
        -- Eine leere Liste darf KEINE Herkunft tragen: sonst stuende
        -- eine Quelle da, die nichts geliefert hat.
        Check(WeintCodex.RaidData.BossSource(raid) == nil,
            raid.id .. ": ohne Bosse auch keine Herkunft")
    end
end

-- Der Gesamtzustand muss zum Bestand passen. Er steuert, was auf der
-- Uebersicht steht - "Bosslisten hinterlegt" ueber einem Bestand aus
-- dem Beta-Client waere zu viel versprochen.
local state = WeintCodex.RaidData.BossListState()
Check(state == "none" or state == "provisional" or state == "partial"
    or state == "confirmed", "BossListState liefert einen der vier Zustaende")

if total == 0 then
    Check(state == "none", "ohne Listen ist der Zustand none")
else
    Check(state ~= "none", "mit Listen ist der Zustand nicht none")
end

--------------------------------------------------
-- 2b. Die Dungeons
--------------------------------------------------
-- Namen, Gebiete und Stufenbereiche sind angekuendigt, die
-- Bosslisten nicht. Geprueft wird deshalb dasselbe wie bei den
-- Schlachtzuegen: dass "unbekannt" nicht als Null herauskommt.

Section("Dungeons")

Check(type(WeintCodex_Dungeons) == "table", "data/dungeons.lua ist geladen")
Check(#WeintCodex_Dungeons == 9, "neun Dungeons")

local dungeonIds = {}
for _, dungeon in ipairs(WeintCodex_Dungeons) do
    Check(type(dungeon.id) == "string" and dungeon.id ~= "",
        "Dungeon hat eine Kennung")
    Check(dungeonIds[dungeon.id] == nil,
        "Kennung " .. tostring(dungeon.id) .. " ist eindeutig")
    dungeonIds[dungeon.id] = true

    Check(type(dungeon.name) == "string" and dungeon.name ~= "",
        dungeon.id .. " hat einen Namen")
    Check(dungeon.size == 5, dungeon.id .. " ist eine Fuenfergruppe")
    Check(type(dungeon.bosses) == "table",
        dungeon.id .. " hat eine Bossliste (leer ist erlaubt)")

    -- Ein halber Stufenbereich ist kein Bereich.
    Check(type(dungeon.minLevel) == "number" and type(dungeon.maxLevel) == "number",
        dungeon.id .. " hat beide Stufen")
    Check(dungeon.minLevel <= dungeon.maxLevel,
        dungeon.id .. ": die untere Stufe liegt nicht ueber der oberen")

    -- Der englische Gebietsname ist Pflicht, der deutsche nicht:
    -- Riverglades ist neu und hat keinen.
    Check(type(dungeon.zone) == "string" and dungeon.zone ~= "",
        dungeon.id .. " nennt sein Gebiet")
    Check(dungeon.zoneDe == nil or type(dungeon.zoneDe) == "string",
        dungeon.id .. ": ein deutscher Gebietsname ist Text oder gar nicht da")
    Check(WeintCodex.DungeonData.ZoneLabel(dungeon) ~= nil,
        dungeon.id .. ": es gibt immer einen anzeigbaren Gebietsnamen")

    Check(WeintCodex.DungeonData.HasBosses(dungeon) == (#dungeon.bosses > 0),
        "HasBosses(" .. dungeon.id .. ") stimmt mit dem Bestand ueberein")
end

-- Dieselbe Regel wie bei den Schlachtzuegen, und sie gilt hier noch:
-- ohne eine einzige Bossliste liefert KnownBossCount nil, nicht 0.
local dungeonBosses = 0
for _, dungeon in ipairs(WeintCodex_Dungeons) do
    dungeonBosses = dungeonBosses + #dungeon.bosses
end

if dungeonBosses == 0 then
    Check(WeintCodex.DungeonData.KnownBossCount() == nil,
        "ohne Bosslisten liefert KnownBossCount nil, nicht 0")
else
    Check(WeintCodex.DungeonData.KnownBossCount() == dungeonBosses,
        "mit Bosslisten liefert KnownBossCount die Summe")
end

Check(WeintCodex.DungeonData.Get("gibtesnicht") == nil,
    "eine unbekannte Kennung liefert nil")

-- Ohne Stufe vom Client ist die Antwort nil und nicht false: "passt
-- nicht" waere eine Behauptung ueber eine Stufe, die niemand kennt.
Check(WeintCodex.DungeonData.FitsLevel(WeintCodex_Dungeons[1], nil) == nil,
    "ohne Stufe liefert FitsLevel nil, nicht false")
Check(WeintCodex.DungeonData.FitsLevel(WeintCodex_Dungeons[1], 0) == nil,
    "Stufe 0 ist keine Stufe")

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
-- 3a. Die Rollen
--------------------------------------------------
-- Drei Bestaende, die nicht zusammenfallen duerfen (siehe
-- data/roles.lua). Geprueft wird wieder der MECHANISMUS: dass
-- "nicht bekannt" nicht als Zahl und "gesperrt" nicht als "nichts da"
-- herauskommt.

Section("Rollen")

Check(type(WeintCodex.Roles) == "table", "data/roles.lua ist geladen")
Check(#WeintCodex.Roles.ORDER == 3, "drei Rollen")

-- DER RAHMEN. Fuenf Spieler: einer tankt, einer heilt, drei teilen
-- aus. Zehn, zwanzig, vierzig: NICHT BEKANNT - und zwar nil, nicht
-- eine Aufstellung aus einem anderen Spiel.
local frame5 = WeintCodex.Roles.Frame(5)
Check(type(frame5) == "table", "eine Fuenfergruppe hat einen bekannten Rahmen")
Check(frame5 and frame5.tank == 1 and frame5.healer == 1 and frame5.dps == 3,
    "1 Tank, 1 Heiler, 3 Schadensausteiler")

for _, size in ipairs({ 10, 20, 40 }) do
    Check(WeintCodex.Roles.Frame(size) == nil,
        size .. "er: der Rahmen ist nicht bekannt, also nil")
    Check(WeintCodex.Roles.FrameLabel(size) == nil,
        size .. "er: auch kein Text dafuer")
end

Check(WeintCodex.Roles.Frame(nil) == nil, "ohne Groesse kein Rahmen")
Check(WeintCodex.Roles.FrameLabel(5) == "1 Tank · 1 Heiler · 3 DD",
    "der Rahmen als Text")

-- Jede Schlachtzugsgroesse aus dem Bestand MUSS ohne Rahmen
-- auskommen. Traegt eine eines Tages einen, ist das eine bewusste
-- Entscheidung und keine, die hier durchrutscht.
for _, raid in ipairs(WeintCodex_Raids) do
    Check(WeintCodex.Roles.Frame(raid.size) == nil,
        raid.id .. ": kein geratener Rollenrahmen")
end

-- DIE BAEUME. Jede Rolle muss von mindestens einem getragen werden -
-- eine leere Rolle waere eine Luecke, keine Auskunft.
for _, role in ipairs(WeintCodex.Roles.ORDER) do
    Check(WeintCodex.Roles.SpecCount(role) > 0,
        WeintCodex.Roles.Label(role) .. " wird von Baeumen getragen")
end

Check(#WeintCodex.Roles.Specs("gibtesnicht") == 0,
    "eine unbekannte Rolle liefert eine leere Liste, nicht nil")

-- "WILDER KAMPF" STEHT UNTER BEIDEN ROLLEN. Dieselben Talente tragen
-- Katze und Baer; ihn nur bei den Schadensausteilern zu fuehren waere
-- ein Vorwurf an jeden Baertank, ihn wegzulassen eine Luecke.
local function FeralIn(role)
    for _, entry in ipairs(WeintCodex.Roles.Specs(role)) do
        if entry.spec.class == "DRUID" and entry.spec.english == "Feral" then
            return entry
        end
    end
    return nil
end

Check(FeralIn("tank") ~= nil, "Wilder Kampf steht bei den Tanks")
Check(FeralIn("dps") ~= nil, "Wilder Kampf steht bei den Schadensausteilern")
Check(FeralIn("healer") == nil, "und nicht bei den Heilern")
Check(FeralIn("tank") and FeralIn("tank").formDependent == true,
    "er ist als gestaltabhaengig gekennzeichnet")

-- DIE TIPPS. Vier Zustaende, vier Antworten.
WeintCodex.SavedData = WeintCodex.SavedData or {}
WeintCodex.SavedData.bossData = {
    ["Bandalar"] = { tank = { "eine Notiz" }, healer = {} },
}

Check(WeintCodex.Roles.Tips("Bandalar", "tank") ~= nil
    and #WeintCodex.Roles.Tips("Bandalar", "tank") == 1,
    "geliefert: die Tipps stehen da")
Check(WeintCodex.Roles.Tips("Bandalar", "healer") ~= nil
    and #WeintCodex.Roles.Tips("Bandalar", "healer") == 0,
    "Boss bekannt, Rolle leer: leere Tabelle, nicht nil")
Check(WeintCodex.Roles.Tips("Bandalar", "dps") ~= nil,
    "Boss bekannt, Rolle fehlt ganz: auch leere Tabelle")
Check(WeintCodex.Roles.Tips("Gibtesnicht", "tank") == nil,
    "nie importiert: nil, nicht leer")
Check(WeintCodex.Roles.HasTips("Bandalar") == true, "HasTips erkennt Inhalt")
Check(WeintCodex.Roles.HasTips("Gibtesnicht") == false,
    "HasTips ohne Bestand ist false")

-- GESPERRT IST NICHT LEER. Ohne die Freigabe bossguides.tips muss
-- Tips() nil liefern - nicht eine leere Liste, sonst schriebe die
-- Oberflaeche "nichts geliefert" ueber etwas, das sehr wohl da ist.
do
    local realCan = WeintCodex.Access.Can
    WeintCodex.Access.Can = function(key) return key ~= "bossguides.tips" end

    Check(WeintCodex.Roles.TipsAllowed() == false, "die Sperre greift")
    Check(WeintCodex.Roles.Tips("Bandalar", "tank") == nil,
        "gesperrt liefert nil, nicht eine leere Liste")
    Check(WeintCodex.Roles.HasTips("Bandalar") == false,
        "gesperrt heisst: der Bestand ist nicht zu lesen")

    WeintCodex.Access.Can = realCan
end

Check(WeintCodex.Roles.TipsAllowed() == true, "ohne Sperre wieder offen")

WeintCodex.SavedData.bossData = {}

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
