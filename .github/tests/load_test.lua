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

-- Ueber Select() und nicht ueber ActivateIndex(): die Unternavigation
-- ist ein BAUM, ihre Zeilen zaehlen Bosse mit. Ein Index aus der
-- Instanzliste zeigte damit auf eine Bosszeile - der Lauf waere gruen
-- geworden und haette etwas anderes geprueft, als er meint.
local function DrawEach(module, tabId, list, label)
    for _, entry in ipairs(list) do
        local ok, err = pcall(function()
            assert(module.Select(entry.id), "Select lehnt eine bekannte Kennung ab")
            WeintCodex.Navigation.SwitchTo(tabId)
        end)
        if ok then
            print("  ok    " .. label .. " " .. tostring(entry.id))
        else
            failures = failures + 1
            print("  FEHL  " .. label .. " " .. tostring(entry.id)
                .. ": " .. tostring(err))
        end
    end
end

DrawEach(WeintCodex.RaidPages,    "raids",    WeintCodex.RaidData.All(),    "Schlachtzug")
DrawEach(WeintCodex.DungeonPages, "dungeons", WeintCodex.DungeonData.All(), "Dungeon")

-- Und JEDER Boss. Die Bossseite ist eine eigene Darstellung (drei
-- Rollenkarten statt Lockout und Aufstellung) und damit ein eigener
-- Zeitpunkt, an dem etwas brechen kann - mit importierten Tipps
-- anders als ohne, und gesperrt wieder anders.
Section("Jeder Boss laesst sich zeichnen")

do
    local function EveryBoss(label)
        for _, raid in ipairs(WeintCodex.RaidData.All()) do
            for _, boss in ipairs(raid.bosses or {}) do
                local ok, err = pcall(function()
                    assert(WeintCodex.RaidPages.Select(raid.id, boss.id))
                    WeintCodex.Navigation.SwitchTo("raids")
                end)
                if not ok then
                    failures = failures + 1
                    print("  FEHL  " .. label .. " " .. boss.id .. ": " .. tostring(err))
                    return false
                end
            end
        end
        print("  ok    " .. label)
        return true
    end

    EveryBoss("ohne Tipps")

    -- Mit Tipps: ein langer Tipp muss gekuerzt werden (sonst schoebe
    -- er die dritte Rollenkarte aus dem Fenster), eine leere Rolle
    -- ist etwas anderes als eine fehlende, und eine Notiz ohne
    -- Zuordnung landet im Detailbereich.
    _G.WeintCodex_SavedData.bossData = {
        ["Bandalar"] = {
            tank   = { "eine Notiz", "noch eine", "und eine dritte" },
            healer = {},
            dps    = { string.rep("sehr langer Hinweis ", 20) },
        },
        ["Kein Boss von uns"] = { dps = { "ohne Zuordnung" } },
    }
    EveryBoss("mit Tipps")

    -- Gesperrt: die Karten muessen "gesperrt" sagen und duerfen nicht
    -- an einem nil-Wert brechen.
    local realCan = WeintCodex.Access.Can
    WeintCodex.Access.Can = function(key) return key ~= "bossguides.tips" end
    EveryBoss("mit gesperrtem Zugriffsprofil")
    WeintCodex.Access.Can = realCan

    _G.WeintCodex_SavedData.bossData = {}
end

--------------------------------------------------
-- 5b. NICHTS MUSS SCROLLEN
--------------------------------------------------
-- Zwei Spalten koennen ueber den Fensterrand hinauslaufen, und beide
-- tun es LAUTLOS: ein Navigationseintrag unter der Kontozeile und ein
-- Bosseintrag unter dem Fensterrand sehen nicht aus wie ein Fehler,
-- sondern wie eine Funktion, die es nicht gibt.
--
-- Bis 5.1.0.0 stand die Rechnung als Kommentar in core/navigation.lua
-- ("wer hier etwas ergaenzt, rechnet nach"). Ein Kommentar prueft
-- nichts. Jetzt rechnen NavColumnHeight/SubNavHeight dasselbe nach,
-- und dieser Abschnitt haelt sie gegen die Hoehe, die beim KLEINSTEN
-- zulaessigen Fenster zur Verfuegung steht.

Section("Nichts muss scrollen")

local navUsed   = WeintCodex.Navigation.NavColumnHeight()
local navBudget = WeintCodex.Navigation.NavColumnBudget()

Check(navUsed <= navBudget,
    "Navigationsspalte: " .. navUsed .. " von " .. navBudget .. " px")

-- Luft fuer mindestens einen weiteren Eintrag. Ohne diese Pruefung
-- faellt erst der Eintrag auf, der schon nicht mehr passt - und dann
-- ist die Frage nicht mehr "passt er?", sondern "was werfen wir
-- raus?".
Check(navBudget - navUsed >= 40,
    "Navigationsspalte hat Luft fuer einen weiteren Eintrag ("
    .. (navBudget - navUsed) .. " px frei)")

local subBudget = WeintCodex.Navigation.SubNavBudget()

-- Die Unternavigation ist ein BAUM: unter dem ausgewaehlten
-- Schlachtzug haengen seine Bosse. Geprueft wird der schlimmste Fall,
-- also der Schlachtzug mit den meisten Bossen - Hyjal Summit mit
-- dreizehn ist der Grund, warum die Liste ueberhaupt aus der Seite
-- heraus musste.
local function WorstCase(all, HasBosses)
    local worst, count = nil, -1
    for _, entry in ipairs(all) do
        local n = HasBosses(entry) and #entry.bosses or 0
        if n > count then worst, count = entry, n end
    end
    return worst
end

local worstRaid = WorstCase(WeintCodex.RaidData.All(),
    WeintCodex.RaidData.HasBosses)

-- Ueber Select() und nicht ueber ActivateIndex(): der Baum zaehlt
-- Bosszeilen mit, ein Index aus der Schlachtzugliste zeigte also auf
-- die falsche Zeile. Genau dieser Irrtum hat beim ersten Lauf den
-- kleinsten statt des groessten Baums gemessen.
if worstRaid then WeintCodex.RaidPages.Select(worstRaid.id) end
WeintCodex.Navigation.SwitchTo("raids")

local subUsed = WeintCodex.Navigation.SubNavHeight()
Check(subUsed > 0, "die Unternavigation der Schlachtzuege ist eine Spalte")
Check(subUsed <= subBudget,
    "Schlachtzuege mit den meisten Bossen (" .. tostring(worstRaid and worstRaid.name)
    .. "): " .. subUsed .. " von " .. subBudget .. " px")

-- Luft fuer weitere Bosse. Die Bosslisten stammen aus dem
-- Beta-Client (data/raids.lua) und koennen sich aendern; ein
-- vierzehnter Boss darf nicht der sein, bei dem die Spalte still
-- ueberlaeuft.
Check(subBudget - subUsed >= 60,
    "die Unternavigation hat Luft fuer weitere Bosse ("
    .. (subBudget - subUsed) .. " px frei)")

-- DIE DUNGEONS SIND SEIT 5.2.0.0 DER SCHWIERIGERE FALL, und zwar
-- um Groessenordnungen: neunundzwanzig Instanzen (neun aus Forever,
-- zwanzig aus Classic) mit Stufenzeile waeren 1334 px in einer
-- Spalte von 716. Die Seite staffelt deshalb nach Stufenabschnitt
-- und Fluegel und rechnet ihren Baum vor dem Bauen durch.
--
-- EINE STICHPROBE REICHT HIER NICHT. Welcher Baum der hoechste ist,
-- haengt nicht am Dungeon mit den meisten Bossen (Blackrock Depths
-- mit zweiundzwanzig ist in Fluegel geteilt und deshalb harmlos),
-- sondern am Zusammenspiel aus Abschnittsgroesse, Fluegelzahl und
-- Bosszahl. Geprueft wird deshalb JEDE Instanz in JEDEM Fluegel -
-- das sind ein paar Dutzend Baeume, und genau einer davon muss
-- eines Tages der sein, der zu hoch wird.
local subHeadroom = WeintCodex.Navigation.SubNavHeadroom()
local worstDung, worstDungName, worstDungFail = 0, "", nil

for _, dungeon in ipairs(WeintCodex.DungeonData.AllInstances()) do
    local wings = WeintCodex.DungeonData.Wings(dungeon) or { false }
    for _, wing in ipairs(wings) do
        -- Ueber Select() auf einen Boss des Fluegels: nur so geht
        -- die Seite in die vertiefte Ansicht, und nur die traegt die
        -- Bossliste.
        local first = wing
            and WeintCodex.DungeonData.BossesInWing(dungeon, wing)[1]
            or (dungeon.bosses or {})[1]
        WeintCodex.DungeonPages.Select(dungeon.id, first and first.id or nil)
        WeintCodex.Navigation.SwitchTo("dungeons")

        local used = WeintCodex.Navigation.SubNavHeight()
        if used > worstDung then
            worstDung     = used
            worstDungName = dungeon.name .. (wing and (" / " .. wing) or "")
        end
        if used > subBudget - subHeadroom and not worstDungFail then
            worstDungFail = dungeon.name .. (wing and (" / " .. wing) or "")
                .. " (" .. used .. " px)"
        end
    end
end

Check(worstDungFail == nil,
    "jeder der " .. #WeintCodex.DungeonData.AllInstances()
    .. " Dungeons passt in die Spalte"
    .. (worstDungFail and (" - zu hoch: " .. worstDungFail) or ""))

Check(worstDung <= subBudget,
    "Dungeons, schlimmster Fall (" .. worstDungName .. "): "
    .. worstDung .. " von " .. subBudget .. " px")

Check(subBudget - worstDung >= subHeadroom,
    "auch der hoechste Dungeonbaum laesst Luft ("
    .. (subBudget - worstDung) .. " px frei)")

-- Und die Seite muss dieselbe Grenze benutzen wie dieser Prueflauf.
-- Stuenden die 60 px an zwei Stellen, liefe eine davon irgendwann
-- nach - und der Fehler waere eine Spalte, die still ueberlaeuft.
-- DER AUFKLAPPWEG SELBST. Stufenabschnitte und Fluegel sind
-- Gruppenkoepfe, und die stehen nicht in sidebarItems -
-- ActivateIndex loest sie also nie aus. Ein Fehler darin faellt
-- ohne diese Runde erst im Spiel auf, und zwar als Spalte, die
-- nicht mehr reagiert.
--
-- Geklickt wird in Runden, weil jeder Klick die Liste neu aufwirft:
-- ein Abschnitt oeffnet sich, und darunter stehen ploetzlich sieben
-- Instanzen, die es vorher nicht gab.
do
    WeintCodex.Navigation.SwitchTo("dungeons")
    local clicks, broken, overflow = 0, nil, nil

    for round = 1, 5 do
        local count = #WeintCodex.Navigation.SidebarButtons()
        for index = 1, count do
            local btn = WeintCodex.Navigation.SidebarButtons()[index]
            if btn then
                local ok, err = pcall(function() btn:Click() end)
                clicks = clicks + 1
                if not ok and not broken then
                    broken = "Runde " .. round .. ", Eintrag " .. index
                        .. ": " .. tostring(err)
                end
                local used = WeintCodex.Navigation.SubNavHeight()
                if used > subBudget and not overflow then
                    overflow = "nach Runde " .. round .. ", Eintrag " .. index
                        .. ": " .. used .. " px"
                end
            end
        end
    end

    Check(clicks > 50, "der Aufklappweg wurde durchlaufen (" .. clicks .. " Klicks)")

    -- DASS HIER UEBERHAUPT ETWAS PASSIERT, IST NEU. Bis 5.2.0.0
    -- kannte die Client-Attrappe kein Click() und fiel auf Noop
    -- zurueck - ActivateIndex aktivierte nie einen Eintrag, und
    -- damit lief im ganzen Prueflauf keine einzige Seitenzeichnung.
    -- Gruen war er trotzdem.
    Check(WeintCodex.DungeonPages.PageHeight() > 0,
        "ein Klick zeichnet wirklich eine Seite")
    Check(broken == nil, "kein Eintrag der Dungeonspalte wirft"
        .. (broken and (" - " .. broken) or ""))
    Check(overflow == nil, "die Spalte laeuft auf keinem Weg ueber"
        .. (overflow and (" - " .. overflow) or ""))
end

-- DER INHALTSBEREICH SCROLLT GENAUSO WENIG WIE DIE SPALTE, und er
-- ist der schwierigere Fall: wie lang eine Bosskarte wird,
-- entscheidet der Bestand (Beschwoerungsanleitungen, Widersprueche,
-- Teillisten). Eine Karte, deren Text unter dem Kartenrand
-- weiterlaeuft, sieht nicht aus wie ein Fehler, sondern wie ein
-- Satz, der aufhoert.
do
    local budget = WeintCodex.DungeonPages.PageBudget()
    local worst, worstName, failed = 0, "", nil

    local function Measure(dungeonId, bossId, label)
        WeintCodex.DungeonPages.Select(dungeonId, bossId)
        WeintCodex.Navigation.SwitchTo("dungeons")
        local used = WeintCodex.DungeonPages.PageHeight()
        if used > worst then worst, worstName = used, label end
        if used > budget and not failed then
            failed = label .. " (" .. used .. " px)"
        end
    end

    for _, dungeon in ipairs(WeintCodex.DungeonData.AllInstances()) do
        Measure(dungeon.id, nil, dungeon.name)
        for _, boss in ipairs(dungeon.bosses or {}) do
            Measure(dungeon.id, boss.id, dungeon.name .. " / " .. boss.name)
        end
    end

    -- Die Uebersicht der beschwoerbaren Bosse waechst mit dem
    -- Bestand und wird nur ueber einen Klick erreicht.
    WeintCodex.Navigation.SwitchTo("dungeons")
    local first = WeintCodex.Navigation.SidebarButtons()[1]
    if first then
        first:Click()
        local used = WeintCodex.DungeonPages.PageHeight()
        if used > worst then worst, worstName = used, "Beschwoerbare Zusatzbosse" end
        if used > budget and not failed then
            failed = "Beschwoerbare Zusatzbosse (" .. used .. " px)"
        end
    end

    Check(failed == nil, "keine Dungeonseite laeuft unten aus dem Fenster"
        .. (failed and (" - " .. failed) or ""))
    Check(worst <= budget, "Seiteninhalt, schlimmster Fall (" .. worstName .. "): "
        .. worst .. " von " .. budget .. " px")
end

Check(WeintCodex.Navigation.Fits({ { label = "A" } }) == true,
    "Navigation.Fits nimmt einen kleinen Baum an")
do
    local huge = {}
    for i = 1, 60 do huge[i] = { label = "x" .. i, status = "y" } end
    Check(WeintCodex.Navigation.Fits(huge) == false,
        "Navigation.Fits lehnt einen zu grossen Baum ab")
end

-- Und die Rechnung ohne Aufbau muss dieselbe sein wie die mit: sonst
-- koennte eine Seite vorher etwas anderes pruefen, als hinterher
-- dasteht.
do
    local items = {
        { label = "A", status = "x" },
        { label = "B" },
        { label = "C", indent = true },
        { isGroup = true, label = "G" },
    }
    WeintCodex.Navigation.BuildSidebar("Probe", items)
    Check(WeintCodex.Navigation.SubNavHeight()
        == WeintCodex.Navigation.MeasureSidebar(items),
        "MeasureSidebar rechnet dasselbe wie der Aufbau")
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
