--------------------------------------------------
-- Laedt das ganze Addon in der Reihenfolge der .toc.
--
--   lua5.1 .github/tests/load_test.lua .
--
-- Rueckgabewert 0 heisst bestanden.
--
-- WARUM DAS DIE WICHTIGSTE PRUEFUNG DIESES REPOS IST: es gibt kein
-- Spiel, in dem sich diese Fassung ausprobieren liesse. Forever ist
-- nicht erschienen. Bis dahin ist `luac -p` alles, was sonst bliebe -
-- und `luac -p` findet ausschliesslich Syntaxfehler. Eine Datei, die
-- in WeintCodex.toc fehlt, eine, die zu frueh steht, und ein Zugriff
-- auf ein Modul, das es nicht mehr gibt, sind syntaktisch tadellos und
-- brechen trotzdem beim Laden.
--
-- Zusaetzlich prueft dieser Lauf zwei Dinge, die nur hier zu haben
-- sind, weil sie die ganze Datei brauchen:
--
--   1. Jede .lua unter core/, data/ und modules/ steht in der .toc.
--      Eine vergessene Datei laedt nicht - ohne Fehler, ohne Hinweis.
--   2. Jeder Navigationseintrag findet sein Modul. Ein Eintrag, dessen
--      Seite es nicht gibt, ist ein Klick, der nichts tut.
--------------------------------------------------

local ROOT = ... or "."

package.path = ROOT .. "/.github/tests/?.lua;" .. package.path

local stub = require("wow_stub")

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

--------------------------------------------------
-- 1. Laden
--------------------------------------------------

Section("Laden in der Reihenfolge der .toc")

stub.Install()

local ok, result = pcall(stub.LoadToc, ROOT)

if not ok then
    print("")
    print(tostring(result))
    print("")
    print("FEHLGESCHLAGEN: das Addon laedt nicht.")
    os.exit(1)
end

print("  ok    " .. #result .. " Dateien geladen")

-- ADDON_LOADED zustellen. Das ist nicht Beiwerk: core/main.lua legt
-- dort WeintCodex_SavedData an, und zwar - das ist die Regel dahinter -
-- AUSSCHLIESSLICH in der globalen Tabelle, die in der .toc unter
-- SavedVariables steht. Eine frisch angelegte Ersatztabelle wuerde beim
-- Abmelden verloren gehen, ohne dass irgendetwas fehlschlaegt.
local fired, fireErr = pcall(stub.FireEvent, "ADDON_LOADED", "WeintCodex")

if not fired then
    print("")
    print(tostring(fireErr))
    print("")
    print("FEHLGESCHLAGEN: ADDON_LOADED bricht ab.")
    os.exit(1)
end

Check(type(_G.WeintCodex_SavedData) == "table",
    "ADDON_LOADED legt WeintCodex_SavedData an")
Check(WeintCodex.SavedData == _G.WeintCodex_SavedData,
    "WeintCodex.SavedData zeigt auf die gespeicherte Tabelle, nicht auf eine Kopie")

-- PLAYER_LOGIN dazu: dort melden sich Charakter und Twinkliste an die
-- Companion, die Rosternamen werden aufgeloest und die Einfuehrung
-- prueft, ob sie sich zeigen muss. Vier Wege, die im Spiel bei JEDEM
-- Login laufen und die sonst nirgends geprueft wuerden.
local loggedIn, loginErr = pcall(stub.FireEvent, "PLAYER_LOGIN")

if not loggedIn then
    print("")
    print(tostring(loginErr))
    print("")
    print("FEHLGESCHLAGEN: PLAYER_LOGIN bricht ab.")
    os.exit(1)
end

Check(true, "PLAYER_LOGIN laeuft durch")

--------------------------------------------------
-- 2. Vollstaendigkeit der .toc
--------------------------------------------------

Section("Jede Datei steht in der .toc")

local toc = assert(io.open(ROOT .. "/WeintCodex.toc", "r")):read("*a")

-- Kein `ls` und kein `find`: der Lauf soll auf jedem System
-- funktionieren, auf dem ein Lua 5.1 liegt. Die Liste kommt deshalb
-- aus der .toc selbst und wird gegen das geprueft, was sich oeffnen
-- laesst - eine Datei, die es nicht gibt, faellt beim Laden oben schon
-- auf. Was hier noch fehlt, ist die Gegenrichtung, und dafuer genuegt
-- ein Verzeichnislauf ueber die drei bekannten Ordner.

local function ListLua(folder)
    local out = {}
    -- io.popen ist nicht ueberall erlaubt; faellt es aus, wird dieser
    -- Teil uebersprungen statt den Lauf scheitern zu lassen.
    local pipe = io.popen and io.popen('ls "' .. ROOT .. "/" .. folder .. '" 2>/dev/null')
    if not pipe then return nil end
    for name in pipe:lines() do
        if name:match("%.lua$") then out[#out + 1] = folder .. "/" .. name end
    end
    pipe:close()
    return out
end

local missing = 0
local checked = 0

for _, folder in ipairs({ "core", "data", "modules" }) do
    local files = ListLua(folder)
    if files then
        for _, file in ipairs(files) do
            checked = checked + 1
            if not toc:find(file, 1, true) then
                missing = missing + 1
                print("  FEHL  " .. file .. " steht in keiner Zeile der .toc")
            end
        end
    end
end

if checked == 0 then
    print("  --    Verzeichnislauf nicht moeglich, uebersprungen")
else
    Check(missing == 0, checked .. " Dateien, alle in der .toc")
end

--------------------------------------------------
-- 3. Die Navigation findet ihre Seiten
--------------------------------------------------

Section("Jeder Navigationseintrag hat sein Modul")

-- Die Zuordnung steht in core/navigation.lua in SwitchTo. Sie hier zu
-- wiederholen waere eine zweite Wahrheit - stattdessen wird die Datei
-- gelesen und geprueft, dass jedes dort genannte Modul existiert.
local navSource = assert(io.open(ROOT .. "/core/navigation.lua", "r")):read("*a")

local seen = {}
for moduleName in navSource:gmatch('elseif tabId == "[%w_]+" then%s*\n%s*if WeintCodex%.([%w_]+)') do
    if not seen[moduleName] then
        seen[moduleName] = true
        Check(type(WeintCodex[moduleName]) == "table",
            "WeintCodex." .. moduleName .. " ist geladen")
    end
end

-- Die Uebersicht laeuft nicht ueber ein Modul, sondern ueber
-- WeintCodex.ShowHome.
Check(type(WeintCodex.ShowHome) == "function", "WeintCodex.ShowHome ist da")
Check(type(WeintCodex.ResetToHome) == "function", "WeintCodex.ResetToHome ist da")

--------------------------------------------------
-- 4. Kein Zugriff auf ein Modul, das es nicht gibt
--------------------------------------------------
-- DIE TEUERSTE FEHLERKLASSE DIESER FASSUNG. Aus der MoP-Fassung sind
-- ein gutes Dutzend Module entfallen, und ein liegengebliebener Aufruf
-- auf eines davon ist syntaktisch tadellos: er laedt, und er bricht
-- erst, wenn jemand die Seite oeffnet.
--
-- Gefunden hat diese Pruefung genau einen solchen Fall:
-- modules/calendar.lua rief nach der Umbenennung der Anmeldeliste
-- weiterhin WeintCodex.Raids.HasLineup() - ungeschuetzt, also ein
-- Lua-Fehler beim ersten Oeffnen des Kalenders.
--
-- Geprueft wird jeder Zugriff der Form `WeintCodex.<Name>` in core/
-- und modules/ gegen das, was nach dem Laden tatsaechlich dasteht.
-- Ein `and`-Schutz davor rettet nicht: er macht den Aufruf still statt
-- richtig, und eine Seite, die stumm die Haelfte weglaesst, ist
-- schlimmer als eine, die sich beschwert.

Section("Kein Zugriff auf ein Modul, das es nicht gibt")

-- Namen, die kein Modul sind: Funktionen, Tabellen und Felder, die
-- core/ui.lua und core/navigation.lua auf WeintCodex legen. Sie
-- stehen hier, weil sie sonst als "fehlendes Modul" gemeldet wuerden -
-- und eine Pruefung mit falschen Treffern schaltet man ab.
local NOT_A_MODULE = {}

local function Known(name)
    return WeintCodex[name] ~= nil
end

local function ScanFolder(folder)
    local pipe = io.popen and io.popen('ls "' .. ROOT .. "/" .. folder .. '" 2>/dev/null')
    if not pipe then return end

    for fileName in pipe:lines() do
        if fileName:match("%.lua$") then

            local handle = io.open(ROOT .. "/" .. folder .. "/" .. fileName, "r")
            if handle then
                local body = handle:read("*a")
                handle:close()

                -- Kommentarzeilen zaehlen nicht mit: dort stehen
                -- Verweise auf entfallene Module absichtlich, als
                -- Begruendung.
                local code = body:gsub("%-%-[^\n]*", "")

                local reported = {}
                for name in code:gmatch("WeintCodex%.([A-Z][%w_]*)") do
                    if not reported[name] and not NOT_A_MODULE[name] then
                        reported[name] = true
                        Check(Known(name),
                            folder .. "/" .. fileName .. " -> WeintCodex." .. name)
                    end
                end
            end

        end
    end

    pipe:close()
end

ScanFolder("core")
ScanFolder("modules")

--------------------------------------------------
-- 5. Jede Seite laesst sich zeichnen
--------------------------------------------------
-- Die letzte Fehlerklasse, die ohne Spiel sonst niemand sieht: eine
-- Seite, die beim OEFFNEN bricht. Laden und Zeichnen sind zwei
-- verschiedene Zeitpunkte - ein Modul kann tadellos laden und beim
-- ersten Klick auf einen nil-Wert laufen.
--
-- Gezeichnet wird gegen die Attrappe, es entsteht also kein Bild. Was
-- diese Pruefung feststellt, ist ausschliesslich: der Aufbau laeuft
-- ohne Fehler durch. Wie die Seite aussieht, sagt sie nicht.

Section("Jede Seite laesst sich zeichnen")

local TABS = {
    "uebersicht", "raids", "dungeons", "anmeldung", "kalender", "gruppe",
    "charakter", "materialien", "import", "companion", "settings",
}

for _, tabId in ipairs(TABS) do
    local drawn, drawErr = pcall(WeintCodex.Navigation.SwitchTo, tabId)
    if drawn then
        print("  ok    " .. tabId)
    else
        failures = failures + 1
        print("  FEHL  " .. tabId .. ": " .. tostring(drawErr))
    end
end

--------------------------------------------------
-- 5a. JEDE INSTANZ, nicht nur die erste
--------------------------------------------------
-- SwitchTo oben schlaegt je Seite den ZULETZT GEWAEHLTEN Eintrag auf -
-- im kopflosen Lauf also den ersten. Genau die interessanten Faelle
-- blieben damit ungeprueft: der Schlachtzug OHNE Bossliste (Onyxias
-- Hort) nimmt einen anderen Zweig als die beiden mit, und die
-- Bossliste mit dreizehn Eintraegen baut ein Bildlauffeld, das die
-- mit acht nicht braucht.
--
-- Beide Zweige brechen erst beim Zeichnen, nicht beim Laden - und
-- ohne Spiel sieht sie sonst niemand.

Section("Jede Instanz laesst sich zeichnen")

local function DrawEach(tabId, list, label)
    WeintCodex.Navigation.SwitchTo(tabId)
    for index, entry in ipairs(list) do
        local ok, err = pcall(WeintCodex.Navigation.ActivateIndex, index)
        if ok then
            print("  ok    " .. label .. " " .. tostring(entry.id))
        else
            failures = failures + 1
            print("  FEHL  " .. label .. " " .. tostring(entry.id)
                .. ": " .. tostring(err))
        end
    end
end

DrawEach("raids",    WeintCodex.RaidData.All(),    "Schlachtzug")
DrawEach("dungeons", WeintCodex.DungeonData.All(), "Dungeon")

-- Und ein Boss mit Rollen-Tipps: der Klick auf eine Bosszeile baut
-- den Detailbereich neu auf, und das ist ein dritter Zeitpunkt, an
-- dem etwas brechen kann.
Section("Rollen-Tipps im Detailbereich")

do
    _G.WeintCodex_SavedData.bossData = {
        ["Bandalar"] = { tank = { "eine Notiz" }, healer = {} },
        ["Kein Boss von uns"] = { dps = { "ohne Zuordnung" } },
    }

    local raid = WeintCodex.RaidData.Get("hyjal_summit")
    local drawn, err = pcall(function()
        for _, boss in ipairs(raid.bosses) do
            WeintCodex.Navigation.SetInspector(
                WeintCodex.RolePanel.BossBlocks(raid, boss))
        end
        -- Und die Seite selbst noch einmal, damit die Zeile "TIPPS"
        -- und die Notiz ohne Zuordnung mitlaufen.
        WeintCodex.Navigation.SwitchTo("raids")
    end)

    Check(drawn, "Rollenbloecke je Boss: " .. (drawn and "ok" or tostring(err)))

    _G.WeintCodex_SavedData.bossData = {}
end

--------------------------------------------------
-- 6. Die Bausteine, auf die sich alles stuetzt
--------------------------------------------------

Section("Grundbausteine")

Check(type(WeintCodex.Colors) == "table", "Farbtokens")
Check(type(WeintCodex.Fonts)  == "table", "Schriften")
Check(type(WeintCodex.MainFrame) == "table", "Hauptfenster")
Check(type(WeintCodex.Navigation) == "table", "Navigation")
Check(type(WeintCodex.Version) == "string", "Fassung gesetzt")

-- Der eine Akzent der Palette "Graphit": violett, und `accent`,
-- `purple` und `violet` zeigen alle darauf. Laeuft einer davon
-- auseinander, stehen wieder zwei Bedeutungsfarben nebeneinander.
local C = WeintCodex.Colors
local function SameColor(a, b)
    for i = 1, 3 do
        if math.abs((a[i] or 0) - (b[i] or 0)) > 0.001 then return false end
    end
    return true
end
Check(SameColor(C.accent, C.purple), "accent und purple sind derselbe Ton")
Check(SameColor(C.accent, C.violet), "accent und violet sind derselbe Ton")
Check(SameColor(C.accent, C.brandA), "der Markenverlauf traegt den Akzent")

--------------------------------------------------

print("")
if failures == 0 then
    print("BESTANDEN")
    os.exit(0)
end

print(failures .. " Pruefung(en) fehlgeschlagen.")
os.exit(1)
