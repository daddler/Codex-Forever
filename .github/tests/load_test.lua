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

-- Seit 6.6.0.9 nimmt die Gruppe standardmaessig die Rahmen des Spiels
-- (ui/gamegroup.lua). Die Pruefungen der eigenen Kacheln weiter unten
-- brauchen die eigenen: vor dem Einloggen umstellen. Die Rahmen des Spiels
-- prueft ein eigener Abschnitt.
WeintCodex.UIKit.Set("groupframes", "source", "own")

-- Seit 6.9.0.0 ist die Oberflaeche wieder freiwillig (UIKit.OPT_IN). Der
-- Prueflauf spielt einen Spieler, der "Ja" gesagt hat - sonst liefe nach
-- dem Anmelden kein ui-Modul, und alles darunter prueft sie. Den Weg ohne
-- Oberflaeche prueft der Abschnitt "Ohne Oberflaeche".
WeintCodex.UIKit.Root().enabled = true

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

for _, folder in ipairs({ "core", "data", "modules", "ui" }) do
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
ScanFolder("ui")

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

-- DER INHALTSBEREICH HAT HIER DIE BREITE DES KLEINSTEN FENSTERS, MIT
-- OFFENEM DETAILBEREICH. Die Attrappe gibt jedem Frame 800 px und
-- kennt SetPoint nicht (core/ui.lua schmaelert den Inhaltsbereich im
-- echten Spiel ueber genau das, wenn WeintCodex.SetDetailShown(true)
-- laeuft) - ohne diese Zeile rechnete der Prueflauf mit mehr Platz,
-- als seit 5.2.0.3 tatsaechlich da ist, sobald die Dungeonseite ihren
-- Detailbereich zeigt (wie die Schlachtzugseite es schon immer tut).
-- Schlachtzugseite und die Uebersicht der beschwoerbaren Zusatzbosse
-- lesen diese Zahl nicht direkt und bleiben unberuehrt.
local M = WeintCodex.Metrics
WeintCodex.ContentPanel:SetWidth(WeintCodex.Navigation.ContentBudgetWidth()
    - (M.DETAIL_W + M.DETAIL_GAP + M.PAD_X))

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
    -- Schlachtzug UND Dungeon: die Bossseiten sind zwei Darstellungen
    -- (Rollenkarten dort, Detailkarte hier) und damit zwei Stellen,
    -- an denen etwas brechen kann.
    local function EveryBoss(label)
        local function Each(list, module, tabId)
            for _, instance in ipairs(list) do
                for _, boss in ipairs(instance.bosses or {}) do
                    local ok, err = pcall(function()
                        assert(module.Select(instance.id, boss.id))
                        WeintCodex.Navigation.SwitchTo(tabId)
                    end)
                    if not ok then
                        failures = failures + 1
                        print("  FEHL  " .. label .. " " .. boss.id .. ": " .. tostring(err))
                        return false
                    end
                end
            end
            return true
        end
        if not Each(WeintCodex.RaidData.All(), WeintCodex.RaidPages, "raids") then return false end
        if not Each(WeintCodex.DungeonData.AllInstances(), WeintCodex.DungeonPages, "dungeons") then return false end
        print("  ok    " .. label)
        return true
    end

    EveryBoss("ohne Tipps")

    -- Mit Tipps: ein langer Tipp muss gekuerzt werden (sonst schoebe
    -- er die dritte Rollenkarte aus dem Fenster), eine leere Rolle
    -- ist etwas anderes als eine fehlende, und eine Notiz ohne
    -- Zuordnung landet im Detailbereich. Der Dungeonboss bekommt so
    -- viele Tipps, dass seine Detailkarte rollen MUSS.
    local many = {}
    for i = 1, 30 do many[i] = "Hinweis " .. i .. ": " .. string.rep("Text ", 30) end
    _G.WeintCodex_SavedData.bossData = {
        ["Bandalar"] = {
            tank   = { "eine Notiz", "noch eine", "und eine dritte" },
            healer = {},
            dps    = { string.rep("sehr langer Hinweis ", 20) },
        },
        ["Faldrim Anvilmar"] = { tank = many, healer = {}, dps = { "kurz" } },
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
-- Spalte von 716. Die Spalte staffelt deshalb nach Stufenabschnitt,
-- und die Bosse stehen seit dem Umbau der Seite nicht mehr in ihr,
-- sondern auf der Seite (Bosszeile, ein Fluegel zur Zeit).
--
-- Geprueft wird trotzdem JEDE Instanz in JEDEM Fluegel: der offene
-- Stufenabschnitt entscheidet, wie hoch die Spalte wird, und jeder
-- Fluegel zeichnet die Seite einmal mit seiner Bosszeile - ein
-- Fehler in einem Fluegelreiter fiele sonst erst im Spiel auf.
local subHeadroom = WeintCodex.Navigation.SubNavHeadroom()
local worstDung, worstDungName, worstDungFail = 0, "", nil

for _, dungeon in ipairs(WeintCodex.DungeonData.AllInstances()) do
    local wings = WeintCodex.DungeonData.Wings(dungeon) or { false }
    for _, wing in ipairs(wings) do
        -- Ueber Select() auf einen Boss des Fluegels: so zeigt die
        -- Seite diesen Fluegel und diesen Boss.
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
    -- Bestand und wird nur ueber einen Klick erreicht: ihre Zeile
    -- steht am Ende der Spalte, und gesucht wird sie ueber ihre
    -- Beschriftung, nicht ueber einen Index, der beim naechsten
    -- Umbau daneben saesse.
    WeintCodex.Navigation.SwitchTo("dungeons")
    local summonRow
    for _, btn in ipairs(WeintCodex.Navigation.SidebarButtons()) do
        if btn._label and btn._label:GetText() == "Beschwörbare Zusatzbosse" then
            summonRow = btn
        end
    end
    Check(summonRow ~= nil, "die Spalte fuehrt die beschwoerbaren Zusatzbosse")
    if summonRow then
        summonRow:Click()
        local used = WeintCodex.DungeonPages.PageHeight()
        if used > worst then worst, worstName = used, "Beschwoerbare Zusatzbosse" end
        if used > budget and not failed then
            failed = "Beschwoerbare Zusatzbosse (" .. used .. " px)"
        end
    end

    -- ZWEI ZUSTAENDE OHNE ECHTEN FALL (seit 6.9.0.6). "Quellen
    -- widersprechen sich" und "gezaehlt, aber nicht benannt" trugen bis
    -- dahin die Excavation Site und die City of Dalaran; seit beide eine
    -- Liste haben, zeichnet sie kein Dungeon des Bestands mehr. Die Seite
    -- muss sie trotzdem koennen - der naechste umstrittene Dungeon kommt
    -- bestimmt. Also hier mit geliehenen Tabellen, danach zurueck.
    do
        -- Die Attrappe kennt keine Kindrahmen; mitgeschrieben wird darum
        -- jeder Text, den die Seite beim Zeichnen setzt.
        local seen = {}
        local setText = stub.Methods.SetText
        local function Record(fn)
            seen = {}
            stub.Methods.SetText = function(self, t)
                if type(t) == "string" then seen[#seen + 1] = t end
                return setText(self, t)
            end
            local ok, err = pcall(fn)
            stub.Methods.SetText = setText
            assert(ok, err)
        end
        local function Shows(text)
            for _, t in ipairs(seen) do
                if t:find(text, 1, true) then return true end
            end
            return false
        end
        local D = WeintCodex.DungeonData
        local KEYS = { "bosses", "bossSource", "bossesComplete", "orderKnown", "bossCount",
                       "countSource", "partial", "conflict" }
        local function Borrow(id, state)
            local d = D.Get(id)
            local saved = {}
            for _, k in ipairs(KEYS) do saved[k] = d[k] d[k] = nil end
            for k, v in pairs(state) do d[k] = v end
            return function() for _, k in ipairs(KEYS) do d[k] = saved[k] end end
        end
        local back = Borrow("excavation_site", { bosses = {},
            conflict = "Zwei Quellen nennen verschiedene Bosse (Prueflauf)." })
        Record(function() Measure("excavation_site", nil, "Excavation Site, umstritten (Prueflauf)") end)
        local contested = Shows("Quellen widersprechen sich") and Shows("(Prueflauf)")
        back()
        back = Borrow("city_of_dalaran", { bosses = {}, bossCount = 9,
            countSource = WeintCodex.Sources.COMMUNITY,
            partial = { names = { "Arcane Anomaly", "Lyn the Ignored" }, source = WeintCodex.Sources.COMMUNITY } })
        Record(function() Measure("city_of_dalaran", nil, "City of Dalaran, gezaehlt (Prueflauf)") end)
        local counted = Shows("9 Kämpfe berichtet, Namen unbekannt") and Shows("Bisher benannt (2 von 9)")
        back()
        Check(contested, "Zustand 'Quellen widersprechen sich' wird gezeichnet (geliehene Tabelle)")
        Check(counted, "Zustand 'gezaehlt, Namen offen' wird gezeichnet, samt Teilliste (geliehene Tabelle)")
        Check(#D.Get("excavation_site").bosses == 3 and #D.Get("city_of_dalaran").bosses == 9,
            "nach dem Leihen stehen die echten Listen wieder da")
    end

    Check(failed == nil, "keine Dungeonseite laeuft unten aus dem Fenster"
        .. (failed and (" - " .. failed) or ""))
    Check(worst <= budget, "Seiteninhalt, schlimmster Fall (" .. worstName .. "): "
        .. worst .. " von " .. budget .. " px")

    -- Und mit einem Bot, der nicht aufhoert: dreissig Tipps zu einer
    -- Rolle passen in kein Fenster. Die Detailkarte nimmt dann den
    -- Platz bis zum Rand und rollt - die Seite wird genau so hoch
    -- wie das Budget, keinen Pixel hoeher.
    local many = {}
    for i = 1, 30 do many[i] = "Hinweis " .. i .. ": " .. string.rep("Text ", 30) end
    _G.WeintCodex_SavedData.bossData = { ["Faldrim Anvilmar"] = { tank = many } }
    Measure("hall_of_thanes", "faldrim_anvilmar", "Hall of Thanes / Faldrim Anvilmar mit 30 Tipps")
    _G.WeintCodex_SavedData.bossData = {}
    Check(WeintCodex.DungeonPages.PageHeight() == budget,
        "eine Bosskarte mit zu vielen Tipps fuellt das Fenster und rollt ("
        .. WeintCodex.DungeonPages.PageHeight() .. " von " .. budget .. " px)")
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
-- 7. Die optionale Oberflaeche (ui/)
--------------------------------------------------
-- Drei Fragen, die ohne Spiel sonst niemand stellt:
--
--   * Laesst sich jede Einstellungsseite bauen? Die Seiten entstehen
--     erst beim ersten Oeffnen - ein Tippfehler darin bricht nicht beim
--     Laden, sondern beim Klick.
--   * Laufen die Module, wenn der Spieler sie einschaltet? Die
--     Attrappe spielt dafuer eine Plakette, einen Treffer, einen Zauber
--     und einen Zielwechsel durch.
--   * Rechnet der Questpfeil richtig herum? Die Achsen der
--     Weltkoordinaten sind der Fehler, den man erst im Spiel saehe - als
--     Pfeil, der nach links zeigt, wenn das Ziel rechts liegt.

Section("Optionale Oberflaeche")

local K  = WeintCodex.UIKit
local UO = WeintCodex.UIOptions
local QA = WeintCodex.UIQuestArrow

Check(type(K) == "table" and type(UO) == "table", "UIKit und UIOptions sind geladen")
for _, key in ipairs({ "general", "nameplates", "unitframes", "questarrow", "comfort" }) do
    Check(K.Module(key) ~= nil, "Modul '" .. key .. "' ist angemeldet")
end

-- SEIT 6.9.0.0 IST DIE OBERFLAECHE WIEDER FREIWILLIG (UIKit.OPT_IN = true;
-- 6.0.0.3 bis 6.8.1.0 war sie fuer alle an, weil der Client nicht
-- speicherte). Der Prueflauf hat "Ja" gesagt: nach dem Anmelden laeuft jedes
-- ui-Modul - gegen die Attrappe, ohne einen einzigen Fehler (K.Report
-- meldete ihn im Chat, und K.IsActive bliebe false).
-- 6.14.0.2: /wcui speicher sagt, was davon Abfall war.
do
    local saved, savedData = _G.C_AddOns, K.prof.data
    local vals, i = { 17920, 9216 }, 0
    _G.C_AddOns = { GetAddOnMemoryUsage = function() i = i + 1 return vals[math.min(i, 2)] end }
    K.prof.data = {}
    local lines = table.concat(K.ProfileReport(30), " | ")
    _G.C_AddOns, K.prof.data = saved, savedData
    Check(lines:find("Speicher jetzt 17.5 MB", 1, true) and lines:find("Nach dem Aufräumen 9.0 MB (8.5 MB waren Abfall)", 1, true),
        "/wcui speicher: Wert nach dem Aufraeumen - " .. lines)
end
Check(K.OPT_IN == true, "Hauptschalter in Kraft (OPT_IN = true) - der Client speichert wieder")
Check(K.UIEnabled() == true, "mit gespeichertem Ja ist die Oberflaeche an")
for _, key in ipairs({ "nameplates", "unitframes", "groupframes", "actionbars",
    "minimap", "chat", "bags", "damagemeter", "questarrow", "comfort" }) do
    Check(K.IsActive(key), "Modul '" .. key .. "' laeuft nach dem Anmelden")
end

-- Gespeichert wird in DER Tabelle aus der .toc, und nur die Abweichung.
K.Set("nameplates", "width", 180)
Check(WeintCodex.UIKit.Profile().modules.nameplates.width == 180,
    "eine Einstellung landet in WeintCodex_SavedData.ui")
K.Set("nameplates", "width", 150)
Check(WeintCodex.UIKit.Profile().modules.nameplates.width == nil,
    "der Standardwert wird nicht gespeichert")
-- Die Falle aus 6.0.0.0 bis 6.0.0.2: `x and false or nil` ist nil. Ein
-- Schalter, der von "an" auf "aus" geht, muss als false im Speicher
-- stehen - sonst laesst sich keine eingeschaltete Option abschalten.
K.Set("nameplates", "hover", false)
Check(WeintCodex.UIKit.Profile().modules.nameplates.hover == false
    and K.Get("nameplates", "hover") == false,
    "ein Schalter laesst sich von an auf aus stellen (false wird gespeichert)")
K.Set("nameplates", "hover", true)
Check(WeintCodex.UIKit.Profile().modules.nameplates.hover == nil,
    "zurueck auf den Standard: der Eintrag verschwindet")

-- 6.19.0.1 (Beta-Test: "Flüstern" stand als achter Reiter im Komfort ueber
-- dem Rand): jede Reiterleiste passt in die Breite des Inhalts - jeder
-- Reiter mit seinem rechten Rand, gerechnet mit SEG_CHAR_W je Zeichen
-- wie im Spiel. Reicht eine Zeile nicht, bricht sie um, und der Inhalt
-- rueckt um die Hoehe der Leiste nach unten.
do
    local over, wrapped = {}, nil
    for _, key in ipairs(K.order) do
        local m = K.Module(key)
        if #m.pages > 1 then
            UO.Show(key, 1)
            local b = UO.built[key]
            local tabs = b and b.tabs
            if not tabs then
                over[#over + 1] = key .. ": keine Reiter"
            else
                local w = tabs:GetWidth() or 0
                if w > UO.CONTENT_W then over[#over + 1] = key .. " " .. w .. " > " .. UO.CONTENT_W end
                for i, p in ipairs(m.pages) do
                    local need = WeintCodex.Utf8Len(p.label) * WeintCodex.SEG_CHAR_W + 28
                    if need > UO.CONTENT_W then over[#over + 1] = key .. "/" .. p.key .. " allein zu breit" end
                    -- Gerechnet wie im Spiel, nicht mit den 6 px der Attrappe.
                    local seg = tabs.segs and tabs.segs[i]
                    if not seg or (seg:GetWidth() or 0) < need then over[#over + 1] = key .. "/" .. p.key .. " schmaler gerechnet als im Spiel" end
                end
                -- Der Inhalt beginnt unter der ganzen Leiste.
                if UO.tabsBottom ~= 96 + (tabs:GetHeight() or 0) + 10 then
                    over[#over + 1] = key .. ": Inhalt bei " .. tostring(UO.tabsBottom) .. ", Leiste " .. tostring(tabs:GetHeight())
                end
                if (tabs.rows or 1) > 1 then wrapped = key end
            end
        end
    end
    Check(#over == 0, "Reiterleisten passen ins Fenster" .. (#over > 0 and (": " .. table.concat(over, ", ")) or ""))
    -- Der Komfort hat so viele Seiten, dass seine Leiste umbricht.
    local comfortRows = UO.built.comfort and UO.built.comfort.tabs and UO.built.comfort.tabs.rows
    Check(wrapped ~= nil and comfortRows and comfortRows > 1
        and (UO.built.comfort.tabs:GetHeight() or 0) == 38 + (comfortRows - 1) * 34,
        "Reiterleiste bricht um, wenn eine Zeile nicht reicht (Komfort: " .. tostring(comfortRows) .. " Zeilen)")
end

-- 6.21.0.0 (Beta-Test: "unter den Punkten erklaert, allerdings mit 3
-- Punkten abgekuerzt"): Beschriftung und Erlaeuterung eines Schalters
-- haengen nur oben links und haben eine Breite - ein Punkt "RIGHT" der
-- Zeile legte auch ihre Hoehe fest (eine Zeile, dann "..."). Die Zeile
-- waechst mit der Erlaeuterung.
do
    local ok, err = pcall(function()
        local pts = setmetatable({}, { __mode = "k" })
        local sp = stub.Methods.SetPoint
        stub.Methods.SetPoint = function(self, p, ...)
            pts[self] = pts[self] or {}
            table.insert(pts[self], p)
            return sp(self, p, ...)
        end
        local long = string.rep("Ein langer Satz, der umbrechen muss. ", 6)
        local host = CreateFrame("Frame")
        local t = WeintCodex.CreateToggle(host, { label = "Schalter", description = long, width = UO.CELL_W,
            get = function() return true end })
        stub.Methods.SetPoint = sp
        local textW = UO.CELL_W - 58
        for _, fs in ipairs({ t._label, t._hint }) do
            assert(pts[fs] and #pts[fs] > 0, "Text ohne Anker")
            for _, p in ipairs(pts[fs]) do
                assert(p == "TOPLEFT", "Text haengt an " .. tostring(p) .. " - das legt seine Hoehe fest")
            end
            assert(fs._width == textW, "Breite " .. tostring(fs._width) .. " statt " .. textW)
        end
        local lines = WeintCodex.EstimateLines(long, math.floor(textW / 5.4))
        assert(lines >= 4, "Probetext zu kurz")
        assert(t:GetHeight() >= 2 + 15 + 4 + lines * 11 + 8, "Zeile waechst nicht mit: " .. tostring(t:GetHeight()))
        local short = WeintCodex.CreateToggle(host, { label = "S", description = "kurz", width = UO.CELL_W })
        assert(short:GetHeight() == 46, "kurze Erlaeuterung: Zeile " .. tostring(short:GetHeight()))
        -- Ausgegraut steht ein anderer Text darunter - auch der passt hinein.
        local off = WeintCodex.CreateToggle(host, { label = "S", description = "kurz", width = UO.CELL_W,
            disabled = function() return true end, disabledHint = long })
        assert(off:GetHeight() == t:GetHeight(), "Hinweis bei gesperrtem Schalter abgeschnitten")
    end)
    Check(ok, "Schalter: Erlaeuterung ganz, nicht abgekuerzt, Zeile waechst mit" .. (ok and "" or (": " .. tostring(err))))
end

-- 6.21.0.0: die Beschreibung eines Moduls steht im Kopf der Seite (96 px)
-- - mehr als zwei Zeilen laufen in die Reiter. Umbrochen nach Woertern,
-- 6 px je Zeichen (IBM Plex Sans 12 misst im Schnitt 5,5 - der Rest ist
-- Spielraum: Zeichen zaehlen ist keine Messung, und an der Grenze lag es
-- daneben).
do
    local long = {}
    local cols = math.floor((UO.CONTENT_W - 200) / 6)
    local function Lines(text)
        local n, cur = 1, 0
        for word in text:gmatch("%S+") do
            local len = WeintCodex.Utf8Len(word)
            local add = cur == 0 and len or cur + 1 + len
            if add > cols and cur > 0 then n, cur = n + 1, len else cur = add end
        end
        return n
    end
    for _, key in ipairs(K.order) do
        local d = K.Module(key).description
        if type(d) == "string" and Lines(d) > 2 then long[#long + 1] = key end
    end
    Check(#long == 0, "Beschreibungen der Module passen in zwei Zeilen" .. (#long > 0 and (": " .. table.concat(long, ", ")) or ""))
end

-- 6.21.0.0 (Beta-Test: "nirgendwo als Quelle ... dass dies von
-- ForeverGuide uebernommen wurde ... das soll ueberall so sein"): kein Text,
-- den ein Spieler sieht, nennt ein fremdes Addon als Quelle. Geprueft an
-- jeder Zeichenkette ausserhalb von Kommentaren. Erlaubt ist nur der blosse
-- Name als Schluessel (ob ein Addon geladen ist, alter gemerkter Wert) und
-- Leatrix Maps als Hinweis, wer die Karte schon aufdeckt - eine Auskunft
-- ueber den Spieler, keine Quelle.
do
    local NAMES = { "ForeverGuide", "Questie", "What's Training", "Dungeon Journal 1", "Leatrix Maps 1" }
    local ALLOWED = { ['"ForeverGuide"'] = true }
    local bad = {}
    local p = io.popen("find '" .. ROOT .. "/core' '" .. ROOT .. "/data' '" .. ROOT .. "/modules' '" .. ROOT .. "/ui' -name '*.lua' | sort")
    for path in p:lines() do
        local n = 0
        for line in io.lines(path) do
            n = n + 1
            local code = line:gsub("%-%-.*$", "")
            for lit in code:gmatch('"[^"]*"') do
                if not ALLOWED[lit] then
                    for _, name in ipairs(NAMES) do
                        if lit:find(name, 1, true) then bad[#bad + 1] = path:gsub("^.*/(%w+/[^/]+)$", "%1") .. ":" .. n end
                    end
                end
            end
        end
    end
    p:close()
    Check(#bad == 0, "kein fremdes Addon als Quelle in sichtbaren Texten" .. (#bad > 0 and (": " .. table.concat(bad, ", ")) or ""))
end

-- 6.21.1.0: eigene Farbe der Oberflaeche - eine dritte Wahl, weiter EIN Akzent.
do
    local ok, err = pcall(function()
        local C = WeintCodex.Colors
        K.Set("general", "highlight", "custom")
        K.Set("general", "highlightColor", { r = 1, g = 0.5, b = 0 })
        K.ResetHighlight()
        assert(C.accent[1] == 1 and C.accent[2] == 0.5 and C.accent[3] == 0, "eigene Farbe nicht gesetzt")
        assert(C.purple[1] == C.accent[1] and C.violet[2] == C.accent[2] and C.brandA[3] == C.accent[3], "zweiter Akzent")
        assert(WeintCodex.AC == "|cffFF8000", "Farbcode im Text: " .. tostring(WeintCodex.AC))
        K.Set("general", "highlight", "accent")
        K.ResetHighlight()
        local v = WeintCodex.VioletRGB()
        assert(math.abs(C.accent[1] - v.r) < 1e-6, "zurueck auf Lila")
        local d = K.Module("general").defaults.highlightColor
        assert(d.r == v.r and d.b == v.b, "Vorgabe der eigenen Farbe nicht das Lila")
    end)
    K.Set("general", "highlight", "class")
    K.Set("general", "highlightColor", nil)
    K.ResetHighlight()
    Check(ok, "Farbe der Oberflaeche: eigene Farbe als dritte Wahl, ein Akzent" .. (ok and "" or (": " .. tostring(err))))
end

-- 6.21.1.0: Warnton bei vermeidbarem Schaden (wie GTFO, ohne Kampflog).
do
    local G = _G
    local names = { "C_DamageMeter", "Enum", "PlaySound", "GetTime", "UnitGUID", "SOUNDKIT" }
    local saved = {}
    for i, n in ipairs(names) do saved[i] = G[n] end
    local FA = WeintCodex.UIFireAlarm
    local ok, err = pcall(function()
        local now, mine, played = 100, nil, {}
        G.GetTime = function() return now end
        G.UnitGUID = function() return "Player-1" end
        G.SOUNDKIT = { RAID_WARNING = 8959, READY_CHECK = 8960 }
        G.PlaySound = function(id, ch) played[#played + 1] = id end
        G.Enum = { DamageMeterType = { AvoidableDamageTaken = 9, DamageDone = 0 },
                   DamageMeterSessionType = { Current = 1, Overall = 0 } }
        local secret = setmetatable({}, { __tostring = function() return "geheim" end })
        G.C_DamageMeter = { GetCombatSessionFromType = function(st, mt)
            assert(mt == 9, "falsche Messart")
            local list = { { sourceGUID = "Player-2", totalAmount = 999 } }
            if mine ~= nil then list[2] = { sourceGUID = "Player-1", totalAmount = mine } end
            return { combatSources = list }
        end }
        K.Set("comfort", "fireAlarm", false)
        mine = 0
        assert(FA.Check() == false and #played == 0, "Ton, obwohl aus")
        K.Set("comfort", "fireAlarm", true)
        FA.Reset()
        assert(FA.Check() == false, "Ton beim ersten Blick")
        mine = 0
        assert(FA.Check() == false, "Ton ohne neuen Schaden")
        mine = 50
        assert(FA.Check() == true and played[1] == 8959, "kein Ton bei vermeidbarem Schaden")
        mine = 60
        now = now + 0.5
        assert(FA.Check() == false and #played == 1, "Ton oefter als einmal je Sekunde")
        now = now + 1
        mine = 70
        K.Set("comfort", "fireSound", "ready")
        assert(FA.Check() == true and played[2] == 8960, "gewaehlter Ton nicht gespielt")
        -- Fremder Schaden zaehlt nicht.
        now = now + 2
        assert(FA.Check() == false, "Ton fuer den Schaden eines anderen")
        -- Geheim: kein Ton, gezaehlt.
        local before = FA.stats.secret
        mine = secret
        now = now + 2
        assert(FA.Check() == false and FA.stats.secret == before + 1, "geheime Summe nicht erkannt")
        -- Neuer Kampf: was vorher war, zaehlt nicht.
        mine = 5
        FA.Reset()
        assert(FA.Check() == false, "Ton zu Kampfbeginn")
        local sc = table.concat(FA.StatusLines(), "\n")
        assert(sc:find("Vermeidbarer Schaden im Client: ja", 1, true) and sc:find("geheim 1", 1, true), "Bericht: " .. sc)
        -- Takt nur im Kampf.
        stub.FireEvent("PLAYER_REGEN_DISABLED")
        assert(FA.ticker:IsShown(), "kein Takt im Kampf")
        stub.FireEvent("PLAYER_REGEN_ENABLED")
        assert(not FA.ticker:IsShown(), "Takt nach dem Kampf")
    end)
    for i, n in ipairs(names) do G[n] = saved[i] end
    K.Set("comfort", "fireAlarm", false)
    K.Set("comfort", "fireSound", "raid")
    FA.Reset()
    Check(ok, "Feuer: Ton bei eigenem vermeidbarem Schaden, gewaehlter Ton, einmal je Sekunde, geheim stumm, nur im Kampf"
        .. (ok and "" or (": " .. tostring(err))))
end

-- 6.21.1.1 (Absturz im Spiel, "L->top < L->ci->top"): Rahmen mit sehr
-- vielen Kindern werden nicht mit GetChildren gelesen, und die Symbole der
-- Karte haengen in einem Rahmen, nicht direkt auf der Flaeche.
do
    local ok, err = pcall(function()
        local W, MK = WeintCodex.UIWindows, WeintCodex.UIMapMarks
        local big, called = CreateFrame("Frame"), false
        big.GetNumChildren = function() return 300 end
        big.GetNumRegions = function() return 300 end
        big.GetChildren = function() called = true end
        big.GetRegions = function() called = true end
        local before = W.tooMany
        assert(W.Children(big, "probe").n == 0 and W.Regions(big, "probe").n == 0 and not called,
            "Rahmen mit 300 Kindern trotzdem gelesen")
        assert(W.tooMany == before + 2, "nicht gezaehlt")
        local small = CreateFrame("Frame")
        local kid = CreateFrame("Frame", nil, small)
        small.GetNumChildren = function() return 1 end
        small.GetChildren = function() return kid end
        assert(W.Children(small, "probe").n == 1, "kleiner Rahmen nicht gelesen")
        local canvas = CreateFrame("Frame")
        local h = MK.Holder(canvas)
        assert(h:GetParent() == canvas and MK.Holder(canvas) == h, "kein eigener Rahmen fuer die Symbole")
    end)
    Check(ok, "Absturzschutz: Rahmen mit vielen Kindern nicht gelesen, Kartensymbole in einem Rahmen" .. (ok and "" or (": " .. tostring(err))))
end

-- Jede Seite jedes Moduls bauen.
for _, key in ipairs(K.order) do
    local m = K.Module(key)
    for i, page in ipairs(m.pages) do
        local ok, err = pcall(UO.Show, key, i)
        if ok and not UO.logo then ok, err = false, "Seitenleiste ohne Logo" end
        local widgets = ok and #UO.CurrentWidgets() or 0
        if ok and widgets > 0 then
            print("  ok    Seite " .. key .. "/" .. page.key .. " (" .. widgets .. " Elemente)")
        else
            failures = failures + 1
            print("  FEHL  Seite " .. key .. "/" .. page.key .. ": "
                .. (ok and "keine Bedienelemente" or tostring(err)))
        end
    end
end

-- Jede Auswahlliste oeffnet ihre Liste, jeder Schalter schaltet, und
-- danach steht alles wieder, wie es war (zweimal klicken).
do
    local ok, err = pcall(function()
        for _, key in ipairs(K.order) do
            for i in ipairs(K.Module(key).pages) do
                UO.Show(key, i)
                for _, w in ipairs(UO.CurrentWidgets()) do
                    if w._button then w._button:Click() end
                end
            end
        end
    end)
    Check(ok, "jede Auswahlliste laesst sich oeffnen" .. (ok and "" or (": " .. tostring(err))))
end

-- 6.10.0.0: Feineinstellungen zugeklappt ("Erweitert"). Zugeklappt nennt
-- der Knopf, wie viele Einstellungen dahinter liegen; aufgeklappt sind sie
-- alle da - und jede Auswahlliste darin oeffnet sich wie die anderen.
do
    local ok, err = pcall(function()
        assert(K.Get("general", "showAdvanced") == false, "Erweitert ist nicht von Haus aus zu")
        local closed, zonesSeen = {}, 0
        for _, key in ipairs(K.order) do
            for i in ipairs(K.Module(key).pages) do
                UO.Show(key, i)
                closed[key .. "/" .. i] = #UO.CurrentWidgets()
                for _, z in ipairs(UO.CurrentZones()) do
                    zonesSeen = zonesSeen + 1
                    assert(not z.open and z.count > 0, key .. "/" .. i .. ": leerer oder offener Bereich")
                    assert(z.button._label:GetText() == UO.AdvancedText(z.count), key .. "/" .. i .. ": Knopf nennt die Zahl nicht")
                end
            end
        end
        assert(zonesSeen >= 6, "zu wenige Bereiche 'Erweitert': " .. zonesSeen)
        -- Zugeklappt wird auch ein Hinweis darin nicht gebaut.
        local texts = {}
        local setText = stub.Methods.SetText
        stub.Methods.SetText = function(self, t) texts[#texts + 1] = tostring(t) return setText(self, t) end
        UO.SetAdvanced(false)
        UO.Show("damagemeter", 1)
        stub.Methods.SetText = setText
        for _, t in ipairs(texts) do
            assert(not t:find("Gemeldet wird nur nach dem Kampf", 1, true), "Hinweis unter 'Erweitert' trotzdem gebaut")
        end
        UO.Show("nameplates", 1)
        UO.CurrentZones()[1].button:Click()
        assert(K.Get("general", "showAdvanced") == true, "Knopf blendet nicht ein")
        local grew = 0
        for _, key in ipairs(K.order) do
            for i in ipairs(K.Module(key).pages) do
                UO.Show(key, i)
                local n = #UO.CurrentWidgets()
                local zones = UO.CurrentZones()
                local hidden = 0
                for _, z in ipairs(zones) do
                    assert(z.open and z.button._label:GetText() == UO.ADV_HIDE, key .. "/" .. i .. ": Bereich bleibt zu")
                end
                if #zones > 0 then
                    assert(n > closed[key .. "/" .. i], key .. "/" .. i .. ": aufgeklappt nicht mehr Elemente")
                    grew = grew + 1
                end
                for _, w in ipairs(UO.CurrentWidgets()) do
                    if w._button then w._button:Click() end
                end
            end
        end
        assert(grew >= 6, "aufgeklappt kaum mehr: " .. grew)
        UO.Show("nameplates", 1)
        UO.CurrentZones()[1].button:Click()
        assert(K.Get("general", "showAdvanced") == false, "Knopf blendet nicht wieder aus")
        UO.frame:Hide()
    end)
    Check(ok, "Einstellungen: 'Erweitert' zu (Knopf nennt die Zahl), auf (mehr Elemente, alle Listen oeffnen sich), wieder zu"
        .. (ok and "" or (": " .. tostring(err))))
end

-- AB HIER BIS ZUM "EINSCHALTEN WIE EIN SPIELER" OHNE GESPEICHERTE ANTWORT:
-- die Frage beim Einloggen, und beide Antworten.
do
    local WL = WeintCodex.UIWelcome
    local sd = WeintCodex.SavedData
    sd.ui.asked = nil
    -- Der Rueckweg muss mit einer Zeile gehen: OPT_IN = false heisst
    -- "fuer alle an, nie fragen".
    K.OPT_IN = false
    WL.MaybeAsk()
    Check(not WL.IsShown() and K.UIEnabled(), "ohne OPT_IN fragt WeintCodex nie, und die Oberflaeche ist an")
    K.OPT_IN = true
    -- Ab hier ein Spieler, der noch nicht geantwortet hat.
    sd.ui.enabled = nil
    Check(K.UIEnabled() == false, "mit OPT_IN liest der Hauptschalter den Speicher (keine Antwort = aus)")
end

-- Die Frage beim Einloggen. Sie darf nicht UEBER der Einfuehrung
-- erscheinen (die steht im Prueflauf seit PLAYER_LOGIN da, weil der
-- Speicher frisch ist), sondern erst, wenn diese weg ist - und beide
-- Antworten muessen tun, was sie sagen.
do
    local WL = WeintCodex.UIWelcome
    local sd = WeintCodex.SavedData
    local ok, err = pcall(function()
        assert(WeintCodex.Onboarding.IsShowing(), "Einfuehrung steht nicht (Voraussetzung)")
        WL.MaybeAsk()
        assert(not WL.IsShown(), "Assistent erscheint ueber der Einfuehrung")

        -- Einfuehrung wegklicken: jetzt kommt der Assistent, Schritt 1.
        WeintCodex.Onboarding.Dismiss()
        assert(WL.IsShown(), "nach der Einfuehrung kommt kein Assistent")
        assert(WL.Step() == "start" and WL.ShownShot() == "overview", "Assistent beginnt nicht bei Willkommen mit Bild")

        -- "Spaeter": nichts gemerkt, nichts geschaltet - beim naechsten Mal wieder.
        WL.Button("later"):Click()
        assert(not WL.IsShown() and not sd.ui.asked and not K.UIEnabled(), "Spaeter hat etwas entschieden")

        -- WEG OHNE OBERFLAECHE: danach trotzdem die Komfortfrage.
        WL.Ask()
        assert(WL.logo and WL.logo:GetWidth() == WL.LOGO, "Assistent ohne Logo")
        WL.Button("next"):Click()
        assert(WL.Step() == "ui" and WL.BodyText():find("Profil bleibt deins", 1, true), "Schritt Oberflaeche ohne Profilversprechen")
        WL.ShowShot("plates")
        assert(WL.ShownShot() == "plates", "Galerie wechselt das Bild nicht")
        WL.Button("no"):Click()
        assert(WL.Step() == "anzeigen", "nach Nein keine Komfortfrage")
        local c = WL.choice
        assert(not c.shows.damagemeter and not c.shows.reminders and c.shows.questarrow,
            "ohne Oberflaeche Anzeigen vorgewaehlt, die niemand gewaehlt hat")
        WL.Row("show", "damagemeter"):Click()
        assert(c.shows.damagemeter and WL.ShownShot() == "damage", "Schadensanzeige laesst sich nicht waehlen")
        assert(not K.WantsActive("damagemeter") and not sd.ui.asked, "vor Uebernehmen schon geschaltet")
        WL.Button("next"):Click()
        assert(WL.Step() == "helfer" and WL.BodyText():find("Klickzauber", 1, true), "Helfer ohne Hinweis auf Klickzauber")
        WL.Row("help", "autoRepair"):Click()
        assert(c.helpers.autoRepair and not K.Get("comfort", "autoRepair"), "Helfer vor Uebernehmen geschaltet")
        -- Zurueckblaettern bis zur Oberflaeche und wieder Nein: Haken bleiben.
        WL.Button("back"):Click()
        WL.Button("back"):Click()
        WL.Button("no"):Click()
        assert(c.shows.damagemeter, "Zurueckblaettern verliert die Wahl")
        WL.Button("next"):Click()
        WL.Button("next"):Click()
        assert(WL.Step() == "bereit", "keine Zusammenfassung")
        local txt = WL.BodyText()
        assert(txt:find("Oberfläche: nein", 1, true) and txt:find("Schadensanzeige", 1, true)
            and txt:find("Automatisch reparieren", 1, true) and txt:find("/wcui", 1, true),
            "Zusammenfassung nennt die Wahl nicht: " .. txt)
        WL.Button("apply"):Click()
        assert(WL.Step() == "fertig" and sd.ui.asked == true and not K.UIEnabled(), "Uebernehmen ohne Oberflaeche falsch")
        assert(K.WantsActive("damagemeter") and WeintCodex.UIKit.Profile().modules.damagemeter.enabled == true, "Schadensanzeige nicht gewaehlt")
        assert(not K.WantsActive("reminders") and K.Get("comfort", "autoRepair") == true, "Helfer oder Erinnerungen falsch")
        assert(WL.Button("reload") and WL.Button("close"), "Anzeige gewaehlt, aber kein Neuladen angeboten")
        WL.Button("close"):Click()
        assert(not WL.IsShown(), "Spaeter schliesst nicht")
        WL.MaybeAsk()
        assert(not WL.IsShown(), "nach der Antwort wird erneut gefragt")
        K.Set("comfort", "autoRepair", false)
        WeintCodex.UIKit.Profile().modules.damagemeter.enabled = nil

        -- WEG MIT OBERFLAECHE: das Komplettpaket ist vorgewaehlt, und das
        -- Layout entsteht gleich beim Uebernehmen (ein Neuladen statt zwei).
        local ES = WeintCodex.UISetup
        local oldHas, oldApply = ES.HasLayout, ES.Apply
        local setupRan = 0
        ES.HasLayout = function() return false end
        ES.Apply = function() setupRan = setupRan + 1 return true end
        sd.ui.asked = nil
        WL.Ask()
        WL.Button("next"):Click()
        WL.Button("yes"):Click()
        assert(c.ui and c.shows.damagemeter and c.shows.reminders, "mit Oberflaeche kein Komplettpaket")
        assert(setupRan == 0 and not K.UIEnabled(), "vor Uebernehmen eingerichtet")
        WL.Button("next"):Click()
        WL.Button("next"):Click()
        WL.Button("apply"):Click()
        ES.HasLayout, ES.Apply = oldHas, oldApply
        assert(K.UIEnabled() and setupRan == 1, "Oberflaeche nicht an oder Layout nicht eingerichtet")
        assert(WL.BodyText():find("Layout „WeintCodex“", 1, true), "Bericht nennt das Layout nicht")
        -- Das Paket ist der Standard, keine ausdrueckliche Wahl: es folgt
        -- der Oberflaeche, wenn sie spaeter ausgeht.
        assert(K.WantsActive("reminders") and (WeintCodex.UIKit.Profile().modules.reminders or {}).enabled == nil,
            "Komplettpaket als feste Wahl gespeichert")
        assert(WL.Button("reload"), "mit Oberflaeche kein Neuladen angeboten")
        WL.Button("close"):Click()

        -- Zurueck auf den Ausgangszustand fuer die Pruefungen darunter.
        K.SetUIEnabled(false)
    end)
    if WL.IsShown() then WL.Close() end
    Check(ok, "Willkommens-Assistent: nach der Einfuehrung, Spaeter, ohne Oberflaeche mit Komfortwahl, mit Komplettpaket, erst Uebernehmen schaltet"
        .. (ok and "" or (": " .. tostring(err))))
end

-- DER ASSISTENT PASST INS FENSTER. Texte werden geschaetzt
-- (WeintCodex.EstimateLines, wie WeintCodex.Paragraph), nicht vom
-- Client gemessen - so rechnen Test und Spiel gleich.
do
    local WL = WeintCodex.UIWelcome
    local budget = WL.H - WL.BODY_TOP - WL.FOOT_H
    local cols = math.floor(WL.COL_W / (WL.TEXT_SIZE * 0.60))
    local line = WL.TEXT_SIZE + WL.TEXT_SPACING
    local worst, worstName = 0, ""
    local function Measure(name, text)
        local h = WeintCodex.EstimateLines(text, cols) * line
        if h > worst then worst, worstName = h, name end
    end
    Measure("start", WL.Text("start"))
    Measure("ui", WL.Text("ui"))
    WL.Decide(true)
    for _, s in ipairs(WL.SHOWS) do WL.choice.shows[s.key] = true end
    for _, h in ipairs(WL.HELPERS) do WL.choice.helpers[h.key] = true end
    Measure("bereit", WL.ReadyText())
    -- Helfer: jede Zeile Name + Erlaeuterung (Mono 9 auf der Zeilenbreite),
    -- darunter der Hinweis.
    local rowsH = 0
    for _, h in ipairs(WL.HELPERS) do
        rowsH = rowsH + 23 + WeintCodex.EstimateLines(h.text, math.floor((WL.COL_W - 58) / (9 * 0.60))) * 13 + 6 + 6
    end
    Measure("helfer", string.rep("\n", math.ceil(rowsH / line)) .. WL.Text("helfer"))
    Check(worst <= budget, "Assistent: laengster Schritt (" .. worstName .. ") " .. worst .. " von " .. budget .. " px")
    -- Jedes Bild, das er zeigt, gibt es als Datei.
    local missing = {}
    for key, s in pairs(WL.SHOTS) do
        local file = ROOT .. "/" .. s.file:gsub("^Interface\\AddOns\\WeintCodex\\", ""):gsub("\\", "/") .. ".blp"
        local h = io.open(file, "rb")
        if h then h:close() else missing[#missing + 1] = key end
    end
    Check(#missing == 0, "Assistent: jedes Bild liegt in media/welcome" .. (#missing == 0 and "" or (": " .. table.concat(missing, ", "))))
end

-- KEINE VERSEHENTLICHEN GLOBALEN in ui/. Mit 6.0.0.1 stand ein `local`
-- unterhalb der Funktion, die es liest - darin war es eine globale
-- Variable, immer nil, und die Sperre gegen die Frageschleife wirkte nie.
-- luac sieht das: jede Schreibung einer globalen Variable ausser
-- WeintCodex und SLASH_* ist ein Fehler, jede Lesung eines Namens, den
-- weder Lua noch WoW kennt, ebenso.
do
    local ALLOWED_GET = {
        WeintCodex = true, _G = true, CreateFrame = true, UIParent = true,
        GameTooltip = true, SlashCmdList = true,
        ipairs = true, pairs = true, pcall = true, print = true, type = true,
        tostring = true, tonumber = true, select = true, unpack = true, wipe = true, assert = true,
        setmetatable = true, math = true, string = true, table = true,
        date = true,
    }
    local bad, checked = {}, 0
    local pipe = io.popen and io.popen('ls "' .. ROOT .. '/ui" 2>/dev/null')
    if pipe then
        for name in pipe:lines() do
            if name:match("%.lua$") then
                local lst = io.popen('luac5.1 -l -p "' .. ROOT .. '/ui/' .. name .. '" 2>/dev/null')
                local out = lst and lst:read("*a") or ""
                if lst then lst:close() end
                if out ~= "" then
                    checked = checked + 1
                    for op, g in out:gmatch("([SG]ETGLOBAL)[^\n]-; ([%w_]+)") do
                        local okName = (op == "SETGLOBAL")
                            and (g == "WeintCodex" or g:match("^SLASH_"))
                            or ALLOWED_GET[g]
                        if not okName then bad[#bad + 1] = "ui/" .. name .. ": " .. op .. " " .. g end
                    end
                end
            end
        end
        pipe:close()
    end
    if checked == 0 then
        print("  --    luac5.1 nicht verfuegbar, Globalenpruefung uebersprungen")
    else
        Check(#bad == 0, checked .. " Dateien in ui/ ohne versehentliche globale Variable"
            .. (#bad == 0 and "" or (": " .. table.concat(bad, ", "))))
    end
end

-- DIE SCHLEIFE AUS 6.0.0.1: "Ja" -> neu laden -> der Beta-Client hat
-- nicht gespeichert -> dieselbe Frage wieder. Speichern kann das Addon
-- nicht erzwingen; es darf aber nach einem /reload nicht erneut fragen,
-- und es muss sagen koennen, ob der Client gespeichert hat.
do
    local WL = WeintCodex.UIWelcome
    local sd = WeintCodex.SavedData
    local ok, err = pcall(function()
        sd.saveProbe = nil
        stub.FireEvent("PLAYER_ENTERING_WORLD", false, true)
        assert(WeintCodex.SaveHealth() == "unknown", "ohne Stempel ist Speichern unbekannt, nicht ok")
        assert(WL.IsReloadSession(), "Neuladen nicht erkannt")

        sd.ui.asked, sd.ui.later = nil, nil
        WL.MaybeAsk()
        assert(not WL.IsShown(), "nach /reload ohne Speicherpruefung wird gefragt (die Schleife)")

        sd.saveProbe = time() - 3600
        stub.FireEvent("PLAYER_ENTERING_WORLD", false, true)
        assert(WeintCodex.SaveHealth() == "failed", "veralteter Stempel nach /reload nicht erkannt")
        WL.MaybeAsk()
        assert(not WL.IsShown(), "nach /reload ohne Speichern wird gefragt (die Schleife)")

        sd.saveProbe = time() - 5
        stub.FireEvent("PLAYER_ENTERING_WORLD", false, true)
        assert(WeintCodex.SaveHealth() == "ok", "frischer Stempel nicht als gespeichert erkannt")
        -- 6.9.0.1 (Beta-Test: "6.9.0.0 geladen, /reload - sollte nicht der
        -- Willkommensbildschirm kommen?"): hat der Client gespeichert, gibt
        -- es keine Schleife - dann auch nach einem /reload fragen.
        WL.MaybeAsk()
        assert(WL.IsShown(), "nach /reload mit Speichern wird nicht gefragt (Aktualisierung in der Sitzung)")
        -- "Spaeter" gilt bis zum Einloggen, auch ueber ein /reload hinweg.
        WL.Button("later"):Click()
        assert(not WL.IsShown() and sd.ui.later == true and not sd.ui.asked, "Spaeter nicht gemerkt")
        sd.saveProbe = time() - 5
        stub.FireEvent("PLAYER_ENTERING_WORLD", false, true)
        WL.MaybeAsk()
        assert(not WL.IsShown(), "nach Spaeter beim naechsten /reload wieder gefragt")

        sd.saveProbe = nil
        stub.FireEvent("PLAYER_LOGOUT")
        assert(type(sd.saveProbe) == "number", "PLAYER_LOGOUT setzt keinen Stempel")

        -- Echtes Einloggen: dann darf (und soll) wieder gefragt werden.
        stub.FireEvent("PLAYER_ENTERING_WORLD", true, false)
        assert(not WL.IsReloadSession(), "Einloggen als Neuladen gewertet")
        assert(sd.ui.later == nil, "Spaeter ueberlebt das Einloggen")
        WL.MaybeAsk()
        assert(WL.IsShown(), "beim Einloggen wird nicht gefragt, obwohl die Antwort fehlt")
        WL.Button("later"):Click()
        sd.ui.asked = true
    end)
    Check(ok, "keine Frageschleife nach /reload; Speicherpruefung erkennt ok/verloren/unbekannt"
        .. (ok and "" or (": " .. tostring(err))))
    -- Die Einstellungsseite nennt den Zustand (Ansicht Diagnose).
    local drawn = pcall(function()
        WeintCodex.Navigation.SwitchTo("settings")
        WeintCodex.Navigation.ActivateIndex(2)
    end)
    Check(drawn, "Diagnose zeigt den Speicherzustand")
end

-- TEXT NUR MIT SCHRIFT. Jede Textzeile der Oberflaeche entsteht ueber
-- UIKit.NewText, das die Schrift sofort setzt. "Font not set" kam aus dem
-- Beta-Client zweimal: 6.0.0.3 beim Aufbau der Schadensanzeige, 6.0.0.4
-- siebenfach beim Angreifen (Zauberbalken einer frischen Plakette).
do
    local offenders = {}
    local pipe = io.popen and io.popen('ls "' .. ROOT .. '/ui" 2>/dev/null')
    if pipe then
        for name in pipe:lines() do
            if name:match("%.lua$") and name ~= "kit.lua" then
                local h = io.open(ROOT .. "/ui/" .. name, "r")
                local code = h:read("*a"):gsub("%-%-[^\n]*", "")
                h:close()
                if code:find("CreateFontString%s*%(") then offenders[#offenders + 1] = name end
            end
        end
        pipe:close()
    end
    Check(#offenders == 0, "Textzeilen in ui/ nur ueber UIKit.NewText (Schrift sofort)"
        .. (#offenders == 0 and "" or (": " .. table.concat(offenders, ", "))))
end

-- WELTKARTE UND QUESTVERFOLGUNG NICHT BERUEHREN (6.6.0.1). Was das Addon
-- in die Weltkarte (SetMapID, OpenWorldMap, Oeffnen/Schliessen ueber
-- Show-/HideUIPanel) oder in die Questverfolgung (SetSuperTrackedQuestID)
-- schreibt, lesen Blizzards Questmarken spaeter mit - und im Kampf
-- blockiert das Spiel dann SetPassThroughButtons (Beta-Test). Erlaubt ist
-- nur C_Map.OpenWorldMap (die Karte stellt ihre Zone selbst ein).
do
    local offenders = {}
    for _, dir in ipairs({ "core", "modules", "ui" }) do
        local pipe = io.popen and io.popen('ls "' .. ROOT .. '/' .. dir .. '" 2>/dev/null')
        if pipe then
            for name in pipe:lines() do
                if name:match("%.lua$") then
                    local h = io.open(ROOT .. "/" .. dir .. "/" .. name, "r")
                    local code = h:read("*a"):gsub("%-%-[^\n]*", "")
                    h:close()
                    code = code:gsub("C_Map%.OpenWorldMap", ""):gsub("cm%.OpenWorldMap", "")
                    for _, pat in ipairs({ "SetMapID", "SetSuperTrackedQuestID", "OpenWorldMap",
                                           "UIPanel%s*%(%s*WorldMapFrame", "UIPanel,%s*wm" }) do
                        if code:find(pat) then offenders[#offenders + 1] = dir .. "/" .. name .. " (" .. pat .. ")" end
                    end
                end
            end
            pipe:close()
        end
    end
    Check(#offenders == 0, "Weltkarte und Questverfolgung bleiben unberuehrt"
        .. (#offenders == 0 and "" or (": " .. table.concat(offenders, ", "))))
end

-- NEULADEN IST AUF FOREVER GESCHUETZT. ReloadUI()/C_UI.Reload() aus
-- Addon-Code endet im Beta-Client in ADDON_ACTION_BLOCKED - gemeldet mit
-- 6.0.0.0 vom Knopf "Jetzt neu laden" der Frage beim Einloggen, und
-- derselbe Fehler steckte seit Langem in zwei aelteren Knoepfen. Erlaubt
-- ist nur der Klick auf einen Makroknopf (WeintCodex.AttachReload).
--
-- Zwei Pruefungen: kein direkter Aufruf irgendwo im Code (Kommentare
-- ausgenommen), und die Knoepfe, die neu laden, tun es ueber den
-- Makroknopf, ohne selbst etwas Geschuetztes aufzurufen.
do
    local offenders, marking = {}, {}
    for _, folder in ipairs({ "core", "modules", "ui" }) do
        local pipe = io.popen and io.popen('ls "' .. ROOT .. "/" .. folder .. '" 2>/dev/null')
        if pipe then
            for name in pipe:lines() do
                if name:match("%.lua$") then
                    local h = io.open(ROOT .. "/" .. folder .. "/" .. name, "r")
                    local code = h:read("*a"):gsub("%-%-[^\n]*", "")
                    h:close()
                    if code:find("ReloadUI%s*%(") or code:find("C_UI%.Reload") then
                        offenders[#offenders + 1] = folder .. "/" .. name
                    end
                    -- 6.9.0.2: Markieren ebenso (ADDON_ACTION_FORBIDDEN aus
                    -- Automark, gemessen) - auch als Verweis in pcall.
                    if code:find("SetRaidTarget") then
                        marking[#marking + 1] = folder .. "/" .. name
                    end
                end
            end
            pipe:close()
        end
    end
    Check(#offenders == 0, "kein direkter Aufruf von ReloadUI/C_UI.Reload"
        .. (#offenders == 0 and "" or (": " .. table.concat(offenders, ", "))))
    Check(#marking == 0, "kein Aufruf von SetRaidTarget (Markieren nur ueber den Klick auf einen Makroknopf)"
        .. (#marking == 0 and "" or (": " .. table.concat(marking, ", "))))

    local blocked = 0
    _G.ReloadUI = function() blocked = blocked + 1 end
    _G.C_UI = { Reload = function() blocked = blocked + 1 end }
    local WL = WeintCodex.UIWelcome
    local ok, err = pcall(function()
        WL.Ask()
        WL.Button("next"):Click()
        WL.Button("yes"):Click()
        WL.Button("next"):Click()
        WL.Button("next"):Click()
        WL.Button("apply"):Click()
        local btn = WL.Button("reload")
        assert(btn and btn._reloadOverlay, "Neuladeknopf ohne Makroknopf")
        assert(WeintCodex.ReloadArmed(btn._reloadOverlay), "Makroknopf nicht scharf")
        assert(btn._reloadOverlay._template == "SecureActionButtonTemplate",
            "Makroknopf nicht sicher - InsecureActionButton darf kein Makro ausfuehren (6.4.1.1)")
        btn:Click()
        btn._reloadOverlay:Click()
        assert(not WL.IsShown(), "Klick auf Neuladen schliesst die Frage nicht")
        K.SetUIEnabled(false)
    end)
    Check(ok and blocked == 0, "Neuladen laeuft ueber den Makroknopf, nie ueber eine geschuetzte Funktion"
        .. (ok and "" or (": " .. tostring(err))))
    _G.ReloadUI, _G.C_UI = nil, nil
end

-- Die Einfuehrung erklaert die Oberflaeche: jede Seite zeichnet, und
-- das Kapitel ist da. (Nach der Frage oben, damit Dismiss hier nicht
-- noch einmal fragt.)
do
    local O = WeintCodex.Onboarding
    local ok, err = pcall(function()
        O.ShowTour()
        local steps = O.TourSteps()
        local found = {}
        for i, step in ipairs(steps) do
            O.RenderStep(i)
            found[step.title] = true
        end
        assert(found["Die WeintCodex-Oberfläche"], "Seite zur Oberflaeche fehlt")
        assert(found["Questpfeil und kleine Helfer"], "Seite zum Questpfeil fehlt")
        O.Dismiss()
        assert(not WeintCodex.UIWelcome.IsShown(), "nach Nein fragt die Einfuehrung erneut")
    end)
    Check(ok, "Einfuehrung: jede Seite zeichnet, Kapitel 'Oberflaeche & Komfort' ist da"
        .. (ok and "" or (": " .. tostring(err))))
end

-- Der Hauptschalter verlangt ein Neuladen und schaltet die ui-Module fuer
-- das naechste Laden ein.
K.SetUIEnabled(true)
Check(K.ReloadPending(), "mit OPT_IN verlangt der Hauptschalter ein Neuladen")
Check(K.WantsActive("nameplates") and K.WantsActive("unitframes"),
    "nach dem Neuladen liefen Plaketten und Einheitenrahmen")
K.SetUIEnabled(false)
Check(not K.WantsActive("nameplates") and K.WantsActive("questarrow"),
    "Oberflaeche aus: Plaketten nicht mehr, Questpfeil weiter")
-- Zurueck auf den Spieler mit "Ja" fuer alles darunter.
K.Root().enabled = true
Check(K.UIEnabled() and K.WantsActive("groupframes"), "zurueck auf Ja: wieder alles an")

-- Eine Welt mit einer feindlichen Plakette und einem Ziel.
local blizzPlate = stub.NewObject("Frame", "NamePlate1")
blizzPlate.UnitFrame = stub.NewObject("Frame")
blizzPlate.namePlateUnitToken = "nameplate1"
_G.C_NamePlate = {
    GetNamePlateForUnit = function(unit) return unit == "nameplate1" and blizzPlate or nil end,
    GetNamePlates = function() return {} end,
}
_G.UnitCanAttack = function() return true end
_G.UnitExists = function() return true end
_G.UnitHealth = function() return 640 end
_G.UnitHealthMax = function() return 1000 end
_G.UnitIsUnit = function(a, b) return a == "nameplate1" and b == "target" end
_G.UnitReaction = function() return 2 end
_G.UnitClassification = function() return "elite" end
_G.UnitAffectingCombat = function() return true end
_G.UnitIsPlayer = function() return false end
_G.UnitPower = function() return 50 end
_G.UnitPowerMax = function() return 100 end
_G.UnitPowerType = function() return 0, "MANA" end
_G.UnitCastingInfo = function(unit)
    if unit == "nameplate1" then
        return "Schattenblitz", "Schattenblitz", 136197, 1000, 3000, false, 7, true, 686
    end
end

for _, key in ipairs({ "nameplates", "unitframes" }) do
    K.Activate(key)
    Check(K.IsActive(key), "Modul '" .. key .. "' startet gegen die Attrappe")
end

do
    local NP = WeintCodex.UINameplates
    local ok, err = pcall(function()
        stub.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate1")
        assert(NP.plates["nameplate1"], "keine Plakette angelegt")
        stub.FireEvent("UNIT_HEALTH", "nameplate1")
        stub.FireEvent("UNIT_SPELLCAST_START", "nameplate1")
        stub.FireEvent("UNIT_SPELLCAST_INTERRUPTED", "nameplate1")
        stub.FireEvent("PLAYER_TARGET_CHANGED")
        stub.FireEvent("RAID_TARGET_UPDATE")
        -- Jede Einstellung einmal umlegen: OnSetting baut alle Plaketten neu.
        K.Set("nameplates", "textCenter", "healthBoth")
        K.Set("nameplates", "raidMarker", "left")
        K.Set("general", "barStyle", "gradient")
        stub.FireEvent("NAME_PLATE_UNIT_REMOVED", "nameplate1")
        assert(NP.plates["nameplate1"] == nil, "Plakette nicht freigegeben")
    end)
    Check(ok, "Plakette: anlegen, Treffer, Zauber, Zielwechsel, freigeben"
        .. (ok and "" or (": " .. tostring(err))))
    Check(blizzPlate.UnitFrame._scripts ~= nil, "die Blizzard-Plakette bleibt an ihrem Platz")
end

do
    local ok, err = pcall(function()
        stub.FireEvent("PLAYER_TARGET_CHANGED")
        stub.FireEvent("UNIT_HEALTH", "player")
        stub.FireEvent("UNIT_POWER_UPDATE", "player")
        stub.FireEvent("UNIT_AURA", "target")
        stub.FireEvent("UNIT_SPELLCAST_START", "target")
        K.Set("unitframes", "player_right", "healthBoth")
        assert(K.SetUnlocked(true), "Entsperren verweigert")
        K.SetUnlocked(false)
    end)
    Check(ok, "Einheitenrahmen: Zielwechsel, Treffer, Kraft, Auren, Entsperren"
        .. (ok and "" or (": " .. tostring(err))))
end

-- Komfort: alles an, dann die Ereignisse, auf die es hoert.
do
    local ok, err = pcall(function()
        for _, feature in ipairs({ "autoRepair", "sellJunk", "fastLoot", "deleteFill",
            "skipCinematics", "hideErrorsInCombat", "combatAlert", "fps", "durability", "mapCoords" }) do
            K.Set("comfort", feature, true)
        end
        for _, e in ipairs({ "MERCHANT_SHOW", "LOOT_READY", "DELETE_ITEM_CONFIRM",
            "CINEMATIC_START", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED",
            "UPDATE_INVENTORY_DURABILITY" }) do
            stub.FireEvent(e)
        end
    end)
    Check(ok, "Komfort: jede Funktion an, jedes Ereignis zugestellt"
        .. (ok and "" or (": " .. tostring(err))))
    Check(WeintCodex.UIComfort.LowestDurability() == nil,
        "ohne Auskunft des Clients ist die Haltbarkeit unbekannt, nicht 0")
end

-- Automark (6.8.1.0, 6.9.0.2 auf Klick): Tank und Heiler markieren - nur mit
-- der Rolle, die das Spiel vergeben hat, nur als Gruppenleiter, je Instanz
-- einmal, nie im Kampf, und nur ueber den Klick auf einen Makroknopf.
do
    local ok, err = pcall(function()
        local AM = WeintCodex.UIAutoMark
        local pagesOk = false
        for _, pg in ipairs(K.Module("comfort").pages) do if pg.key == "automark" then pagesOk = true end end
        assert(AM and pagesOk and not K.Module("automark"), "Automark nicht als Seite im Komfort")
        assert(K.Get("comfort", "autoMark") == false, "Automark von Haus aus an (Komfort: von Haus aus aus)")
        K.Set("comfort", "autoMark", true)
        local names = { "IsInInstance", "GetInstanceInfo", "UnitIsGroupLeader", "UnitIsGroupAssistant", "UnitExists",
            "UnitGroupRolesAssigned", "UnitGUID", "UnitName", "InCombatLockdown", "SetRaidTarget", "GetRaidTargetIndex" }
        local saved = {}
        for _, n in ipairs(names) do saved[n] = _G[n] end
        K.Set("comfort", "markChat", false)
        AM.state.instance, AM.state.done = nil, {}
        local okIn, errIn = pcall(function()
        local roles = { player = "DAMAGER", party1 = "TANK", party2 = "HEALER", party3 = "DAMAGER", party4 = "HEALER" }
        local inside, kind, instID, leader, combat = true, "party", 36, true, false
        local calls = 0
        _G.IsInInstance = function() return inside, kind end
        _G.GetInstanceInfo = function() return "Die Todesminen", kind, 1, "Normal", 5, 0, false, instID end
        _G.UnitIsGroupLeader = function() return leader end
        _G.UnitIsGroupAssistant = function() return false end
        _G.UnitExists = function(u) return roles[u] ~= nil end
        _G.UnitGroupRolesAssigned = function(u) return roles[u] or "NONE" end
        _G.UnitGUID = function(u) return "Player-1-" .. u end
        _G.UnitName = function(u) return ({ party1 = "Brunhild", party2 = "Kalle", party4 = "Zweite" })[u] or u end
        _G.InCombatLockdown = function() return combat end
        -- 6.9.0.2 (gemessen: ADDON_ACTION_FORBIDDEN): Markieren ist fuer
        -- Addons geschuetzt. Automark ruft es NIE; es bietet einen Knopf
        -- mit Makro an, den der Spieler klickt.
        _G.SetRaidTarget = function() calls = calls + 1 end
        _G.GetRaidTargetIndex = function() return nil end
        local function Macro() local b = _G[AM.BUTTON] return b and b:GetAttribute("macrotext1") end
        -- 6.9.0.2: eine Abfrage (Fenster), darin der geschuetzte Knopf.
        local function Shown() return AM.dialog ~= nil and AM.dialog:IsShown() end
        stub.FireEvent("PLAYER_ENTERING_WORLD")
        local b = _G[AM.BUTTON]
        assert(b and b._template == "SecureActionButtonTemplate", "kein geschuetzter Knopf")
        assert(AM.IsOffered() and Shown(), "Abfrage nicht gezeigt")
        assert(b._parent == AM.dialog, "geschuetzter Knopf nicht in der Abfrage")
        local body = AM.dialog.body:GetText()
        assert(body:find("Tank:  Brunhild", 1, true) and body:find("Heiler:  Kalle", 1, true), "Abfrage nennt niemanden: " .. body)
        assert(b:GetAttribute("type1") == "macro" and b:GetAttribute("type") == nil and b:GetAttribute("type2") == nil
            and b:GetAttribute("useOnKeyDown") == false, "Knopf falsch belegt (Rechtsklick muss nichts tun)")
        assert(Macro() == "/tm [@party1] 6\n/tm [@party2] 4", "Makro: " .. tostring(Macro()))
        assert(AM.Status():find("wartet auf Klick", 1, true), "Status behauptet Markierung vor dem Klick: " .. AM.Status())
        -- Weitere Ereignisse: dasselbe Angebot, nichts doppelt.
        stub.FireEvent("GROUP_ROSTER_UPDATE")
        stub.FireEvent("ZONE_CHANGED_NEW_AREA")
        assert(Macro() == "/tm [@party1] 6\n/tm [@party2] 4", "Angebot veraendert")
        -- Klick: gemerkt, Knopf weg.
        b:Click("LeftButton")
        assert(not Shown() and not AM.IsOffered(), "Knopf bleibt nach dem Klick")
        local st = AM.Status()
        assert(st:find("Tank: Brunhild", 1, true) and st:find("Heiler: Kalle", 1, true)
            and not st:find("wartet", 1, true), "Status nach Klick: " .. st)
        stub.FireEvent("GROUP_ROSTER_UPDATE")
        assert(not Shown(), "nach dem Klick erneut angeboten - Markierung waere abgenommen")
        -- Rolle wechselt: nur der neue Tank.
        roles.party1, roles.party3 = "DAMAGER", "TANK"
        stub.FireEvent("PLAYER_ROLES_ASSIGNED")
        assert(Shown() and Macro() == "/tm [@party3] 6", "neuer Tank nicht angeboten: " .. tostring(Macro()))
        b:Click("LeftButton")
        -- Keine Rollen vergeben: nichts raten.
        roles = { player = "NONE", party1 = "NONE", party2 = "NONE" }
        instID = 48
        stub.FireEvent("PLAYER_ENTERING_WORLD")
        assert(not Shown() and AM.Status():find("keine Rolle vergeben", 1, true), "ohne Rolle angeboten")
        -- Nicht Leiter: nichts.
        roles = { player = "DAMAGER", party1 = "TANK", party2 = "HEALER" }
        leader, instID = false, 49
        stub.FireEvent("PLAYER_ENTERING_WORLD")
        assert(not Shown() and AM.Status():find("Gruppenleiter", 1, true), "angeboten ohne Leiter")
        -- Im Kampf: der Knopf ist geschuetzt - erst danach.
        leader, combat, instID = true, true, 50
        stub.FireEvent("PLAYER_ENTERING_WORLD")
        assert(not Shown(), "im Kampf angeboten")
        combat = false
        stub.FireEvent("PLAYER_REGEN_ENABLED")
        assert(Shown() and Macro() == "/tm [@party1] 6\n/tm [@party2] 4", "nach dem Kampf nicht angeboten")
        -- Klick im Kampf: gemerkt, der Knopf geht nach dem Kampf.
        combat = true
        b:Click("LeftButton")
        assert(Shown(), "geschuetzter Knopf im Kampf versteckt")
        combat = false
        stub.FireEvent("PLAYER_REGEN_ENABLED")
        assert(not Shown(), "Knopf nach dem Kampf nicht weg")
        -- Rechtsklick: ausgeblendet bis zum naechsten Betreten.
        instID = 53
        stub.FireEvent("PLAYER_ENTERING_WORLD")
        assert(Shown(), "neue Instanz nicht angeboten")
        AM.dialog.no:Click()
        assert(not Shown(), "Nicht jetzt blendet nicht aus")
        stub.FireEvent("GROUP_ROSTER_UPDATE")
        assert(not Shown(), "nach Rechtsklick wieder angeboten")
        assert(AM.Status():find("wartet auf Klick", 1, true), "Nicht jetzt als Markierung gewertet: " .. AM.Status())
        -- Rechtsklick auf "Markieren" wirkt wie "Nicht jetzt".
        inside, kind = false, "none"
        stub.FireEvent("ZONE_CHANGED_NEW_AREA")
        inside, kind = true, "party"
        stub.FireEvent("PLAYER_ENTERING_WORLD")
        assert(Shown(), "nach dem Wiederbetreten keine Abfrage")
        b:Click("RightButton")
        stub.FireEvent("GROUP_ROSTER_UPDATE")
        assert(not Shown() and AM.Status():find("wartet auf Klick", 1, true), "Rechtsklick markiert oder blendet nicht aus")
        -- Draussen: weg; wieder hinein: neu angeboten.
        inside, kind = false, "none"
        stub.FireEvent("ZONE_CHANGED_NEW_AREA")
        assert(not Shown(), "Knopf draussen sichtbar")
        inside, kind = true, "party"
        stub.FireEvent("PLAYER_ENTERING_WORLD")
        assert(Shown(), "nach dem Wiederbetreten nicht angeboten")
        -- Schlachtzug abgeschaltet: nichts.
        K.Set("comfort", "markRaids", false)
        kind, instID = "raid", 51
        stub.FireEvent("PLAYER_ENTERING_WORLD")
        assert(not Shown(), "im Schlachtzug trotz Schalter angeboten")
        K.Set("comfort", "markRaids", true)
        -- Gleiche Markierung fuer beide Rollen: der Heiler wird ausgelassen.
        kind, instID = "party", 52
        K.Set("comfort", "markHealer", 6)
        assert(Macro() == "/tm [@party1] 6" and AM.Status():find("dieselbe Markierung", 1, true), "doppelte Markierung")
        K.Set("comfort", "markHealer", 4)
        -- Eine andere Einstellung aendert das Angebot nicht.
        local before = Macro()
        K.Set("comfort", "markChat", true)
        K.Set("comfort", "markChat", false)
        assert(Macro() == before, "Einstellung geaendert - Angebot veraendert")
        -- Automark aus: Knopf weg.
        K.Set("comfort", "autoMark", false)
        assert(not Shown(), "Knopf bleibt mit Automark aus")
        K.Set("comfort", "autoMark", true)
        assert(calls == 0, "SetRaidTarget aufgerufen (geschuetzt): " .. calls)
        end)
        for _, n in ipairs(names) do _G[n] = saved[n] end
        AM.state.instance, AM.state.done = nil, {}
        K.Set("comfort", "markChat", true)
        K.Set("comfort", "autoMark", false)
        assert(okIn, errIn)
    end)
    Check(ok, "Automark: Knopf mit Makro statt SetRaidTarget, Rolle vom Spiel, nur Leiter, je Instanz einmal, nie im Kampf, nichts geraten"
        .. (ok and "" or (": " .. tostring(err))))
end

-- Makro-Helfer (6.8.1.0): was, auf wen, welcher Zauber -> Text der
-- Makrosprache, erklaert; anlegen, ersetzen, aufnehmen; nie im Kampf.
do
    local ok, err = pcall(function()
        local MH = WeintCodex.UIMacros
        local found = false
        -- Seit 6.9.0.0 im Komfort (geht ohne Oberflaeche), Speicher bleibt.
        for _, pg in ipairs(K.Module("comfort").pages) do
            if pg.key == "makros" and pg.store == "actionbars" then found = true end
        end
        assert(MH and found, "Makro-Helfer nicht als Seite im Komfort (Speicher der Aktionsleisten)")
        local function D(t)
            local d = { kind = "cast", target = "target", mod = "shift", reset = "target", spells = { "", "", "" },
                        slot = 1, tooltip = true, startattack = false, stopcasting = false, name = "", save = "account" }
            for k, v in pairs(t) do d[k] = v end
            return d
        end
        local function Text(t) local x, _, e = MH.Build(D(t)) return x, e end
        assert(Text({ spells = { "Blitzschlag", "", "" } }) == "#showtooltip\n/cast Blitzschlag", "einfacher Zauber")
        assert(Text({ target = "mouseover", tooltip = false, spells = { "Blitzschlag", "", "" } })
            == "/cast [@mouseover,exists,nodead][] Blitzschlag", "Maus-Ziel, sonst Ziel")
        assert(Text({ target = "mouseoverself", tooltip = false, spells = { "Blitzheilung", "", "" } })
            == "/cast [@mouseover,help,nodead][@player] Blitzheilung", "Maus-Ziel, sonst selbst")
        assert(Text({ target = "cursor", tooltip = false, spells = { "Blizzard", "", "" } }) == "/cast [@cursor] Blizzard", "Mauszeiger")
        assert(Text({ kind = "modifier", tooltip = false, spells = { "Heilen", "Blitzheilung", "" } })
            == "/cast [mod:shift] Blitzheilung; Heilen", "Zusatztaste ohne Zielbedingung")
        assert(Text({ kind = "modifier", mod = "ctrl", target = "mouseover", tooltip = false, spells = { "Heilen", "Erneuerung", "" } })
            == "/cast [mod:ctrl,@mouseover,exists,nodead][mod:ctrl] Erneuerung; [@mouseover,exists,nodead][] Heilen",
            "Zusatztaste mit Maus-Ziel: " .. tostring(Text({ kind = "modifier", mod = "ctrl", target = "mouseover", tooltip = false, spells = { "Heilen", "Erneuerung", "" } })))
        assert(Text({ kind = "sequence", tooltip = false, spells = { "Verderbnis", "Fluch der Pein", "Feuerbrand" } })
            == "/castsequence reset=target Verderbnis, Fluch der Pein, Feuerbrand", "Abfolge")
        assert(Text({ kind = "sequence", reset = "", target = "focus", tooltip = false, spells = { "A", "B", "" } })
            == "/castsequence [@focus,exists,nodead][] A, B", "Abfolge ohne Neubeginn, mit Fokus")
        assert(Text({ startattack = true, stopcasting = true, spells = { "Tritt", "", "" } })
            == "#showtooltip\n/stopcasting\n/startattack\n/cast Tritt", "Extras")
        local x, e = Text({ spells = { "", "", "" } })
        assert(x == nil and e:find("Zauber", 1, true), "leer ohne Hinweis")
        x, e = Text({ kind = "sequence", spells = { "A", "", "" } })
        assert(x == nil and e:find("zwei", 1, true), "Abfolge mit einem Zauber")
        x, e = Text({ kind = "modifier", spells = { "A", "", "" } })
        assert(x == nil and e, "Zusatztaste ohne zweiten Zauber")
        x, e = Text({ spells = { string.rep("x", 260), "", "" } })
        assert(x and e and e:find("255", 1, true), "zu lang ohne Hinweis")
        -- Erklaerung je Zeile.
        local _, why = MH.Build(D({ target = "mouseoverself", spells = { "Heilen", "", "" } }))
        assert(#why == 2 and why[2]:find("Heilen", 1, true) and why[2]:find("selbst", 1, true), "keine Erklaerung")
        -- Name: hoechstens 16 Zeichen, Umlaute heil.
        local n = MH.Name(D({ spells = { "Große Heilung der Ältesten", "", "" } }))
        assert(WeintCodex.Utf8Len(n) == 16 and n == "Große Heilung de", "Name: " .. n)
        assert(MH.Name(D({ name = "  Mein Makro ", spells = { "A", "", "" } })) == "Mein Makro", "eigener Name")
        -- Anlegen.
        local names = { "InCombatLockdown", "CreateMacro", "EditMacro", "GetMacroIndexByName", "GetNumMacros", "PickupMacro" }
        local saved = {}
        for _, k in ipairs(names) do saved[k] = _G[k] end
        local macros, combat, picked = {}, false, nil
        _G.InCombatLockdown = function() return combat end
        _G.GetMacroIndexByName = function(nm) for i, m in ipairs(macros) do if m.name == nm then return i end end return 0 end
        _G.GetNumMacros = function() local g, c = 0, 0 for _, m in ipairs(macros) do if m.char then c = c + 1 else g = g + 1 end end return g, c end
        _G.CreateMacro = function(nm, icon, body, perChar) macros[#macros + 1] = { name = nm, body = body, char = perChar } return #macros end
        _G.EditMacro = function(i, nm, icon, body) macros[i].body = body return i end
        _G.PickupMacro = function(i) picked = i end
        local okIn, errIn = pcall(function()
            local d = D({ spells = { "Blitzheilung", "", "" }, target = "mouseoverself", save = "char" })
            local idx, msg = MH.Create(d)
            assert(idx == 1 and macros[1].name == "Blitzheilung" and macros[1].char == true
                and macros[1].body == "#showtooltip\n/cast [@mouseover,help,nodead][@player] Blitzheilung", "nicht angelegt: " .. tostring(msg))
            d.target = "player"
            idx = MH.Create(d)
            assert(idx == 1 and #macros == 1 and macros[1].body:find("[@player]", 1, true), "nicht ersetzt")
            assert(MH.Pickup(d) and picked == 1, "nicht aufgenommen")
            combat = true
            local n0 = #macros
            assert(MH.Create(D({ name = "Neu", spells = { "A", "", "" } })) == nil and #macros == n0
                and MH.last:find("Kampf", 1, true), "im Kampf angelegt")
            assert(not MH.Pickup(d), "im Kampf aufgenommen")
            combat = false
            for i = 1, 18 do macros[#macros + 1] = { name = "c" .. i, char = true } end
            assert(MH.Create(D({ name = "Voll", save = "char", spells = { "A", "", "" } })) == nil
                and MH.last:find("belegt", 1, true), "voller Charakter nicht gemeldet")
            x = MH.Create(D({ name = "Lang", spells = { string.rep("x", 260), "", "" } }))
            assert(x == nil, "zu langes Makro angelegt")
        end)
        for _, k in ipairs(names) do _G[k] = saved[k] end
        assert(okIn, errIn)
        -- Tafel: ein Klick fuellt das gewaehlte Feld und rueckt weiter.
        local dr = MH.draft
        dr.kind, dr.slot, dr.spells = "sequence", 1, { "", "", "" }
        MH.Pick("Verderbnis")
        MH.Pick("Fluch der Pein")
        assert(dr.spells[1] == "Verderbnis" and dr.spells[2] == "Fluch der Pein" and dr.slot == 3, "Tafel fuellt nicht")
        dr.kind, dr.slot, dr.spells = "cast", 1, { "", "", "" }
    end)
    Check(ok, "Makro-Helfer: Text der Makrosprache, Erklaerung, Grenzen, anlegen/ersetzen/aufnehmen, nie im Kampf"
        .. (ok and "" or (": " .. tostring(err))))
end

-- Entfluchen auf Klick (6.8.1.0): ein Schalter legt die Zauber der Klasse
-- auf Zusatztaste + Links/Rechts; nur gelernte (Name vom Client, im
-- Zauberbuch); die eigene Belegung gewinnt; ohne Schalter nichts.
do
    local ok, err = pcall(function()
        local DP, CC = WeintCodex.UIDispel, WeintCodex.UIClickCast
        assert(DP and CC.ExtraBindings == DP.Bindings, "Entfluchen nicht an den Klickzaubern")
        assert(K.Get("groupframes", "clickDispel") == false, "Entfluchen von Haus aus an")
        local saved = { UnitClass = _G.UnitClass, C_Spell = _G.C_Spell, IsPlayerSpell = _G.IsPlayerSpell,
                        Spellbook = CC.Spellbook, Bindings = CC.Bindings }
        local okIn, errIn = pcall(function()
        local class = "PRIEST"
        local names = { [527] = "Magiebannung", [988] = "Magiebannung", [552] = "Krankheit aufheben", [528] = "Krankheit heilen",
                        [2782] = "Fluch aufheben", [2893] = "Vergiftung aufheben", [8946] = "Vergiftung heilen" }
        local book = { { name = "Magiebannung" }, { name = "Krankheit heilen" }, { name = "Blitzheilung" } }
        local mine = {}
        _G.UnitClass = function() return "x", class, 5 end
        _G.C_Spell = { GetSpellName = function(id) return names[id] end }
        _G.IsPlayerSpell = function() return false end
        CC.Spellbook = function() return book end
        CC.Bindings = function() return mine end
        -- Aus: nichts.
        assert(#DP.Bindings() == 0, "ohne Schalter belegt")
        K.Set("groupframes", "clickDispel", true)
        local eff = CC.Effective()
        assert(#eff == 2 and eff[1].mod == "ctrl-" and eff[1].button == 1 and eff[1].spell == "Magiebannung"
            and eff[2].button == 2 and eff[2].spell == "Krankheit heilen", "Priester: falsch belegt")
        -- Aufheben gelernt: das bessere zuerst.
        book[#book + 1] = { name = "Krankheit aufheben" }
        assert(CC.Effective()[2].spell == "Krankheit aufheben", "das bessere nicht gewaehlt")
        -- Auf dem Rahmen: Attribute wie bei jedem Klickzauber.
        local f = stub.NewObject("Button")
        local attrs = {}
        f.SetAttribute = function(_, k, v) attrs[k] = v end
        CC.ApplyTo(f, CC.Effective())
        assert(attrs["ctrl-type1"] == "spell" and attrs["ctrl-spell1"] == "Magiebannung"
            and attrs["ctrl-spell2"] == "Krankheit aufheben", "nicht auf dem Rahmen")
        -- Eigene Belegung gewinnt.
        mine[1] = { button = 1, mod = "ctrl-", action = "spell", spell = "Erneuerung" }
        eff = CC.Effective()
        assert(#eff == 2 and eff[1].spell == "Erneuerung" and eff[2].spell == "Krankheit aufheben", "eigene Belegung ueberschrieben")
        assert(DP.Summary():find("besetzt", 1, true), "Seite sagt nicht, dass Links besetzt ist: " .. DP.Summary())
        mine[1] = nil
        -- Andere Zusatztaste.
        K.Set("groupframes", "clickDispelMod", "shift-")
        assert(CC.Effective()[1].mod == "shift-", "Zusatztaste nicht uebernommen")
        K.Set("groupframes", "clickDispelMod", "ctrl-")
        -- Nicht gelernt: nicht angeboten, aber genannt.
        class, book = "DRUID", { { name = "Heilende Beruehrung" } }
        assert(#CC.Effective() == 0 and DP.Summary():find("noch nicht gelernt", 1, true), "Druide ohne Zauber")
        book[#book + 1] = { name = "Vergiftung heilen" }
        eff = CC.Effective()
        assert(#eff == 1 and eff[1].button == 2 and eff[1].spell == "Vergiftung heilen", "Gift auf Rechts erwartet")
        -- ID ohne Namen im Client (in Forever geaendert): nichts Falsches.
        names[2893], names[8946] = nil, nil
        assert(#CC.Effective() == 0, "Zauber ohne Namen vom Client belegt")
        -- Klasse ohne Entfluchen.
        class = "WARRIOR"
        assert(#CC.Effective() == 0 and DP.Summary():find("keinen Zauber", 1, true), "Krieger: " .. DP.Summary())
        end)
        K.Set("groupframes", "clickDispel", false)
        -- Einzeln zuruecksetzen: pairs ueberginge Werte, die vorher nil waren.
        _G.UnitClass, _G.C_Spell, _G.IsPlayerSpell = saved.UnitClass, saved.C_Spell, saved.IsPlayerSpell
        CC.Spellbook, CC.Bindings = saved.Spellbook, saved.Bindings
        assert(okIn, errIn)
    end)
    Check(ok, "Entfluchen auf Klick: nur gelernte Zauber, bessere zuerst, eigene Belegung gewinnt, von Haus aus aus"
        .. (ok and "" or (": " .. tostring(err))))
end

-- Questpfeil: die Rechnung.
do
    local function Near(a, b) return math.abs(a - b) < 1e-6 end
    local d, r = QA.Solve(0, 0, 10, 0, 0)
    Check(Near(d, 10) and Near(r, 0), "Ziel im Norden, Blick nach Norden: geradeaus")
    d, r = QA.Solve(0, 0, 0, 10, 0)
    Check(Near(r, math.pi / 2), "Ziel im Westen, Blick nach Norden: Pfeil nach links")
    d, r = QA.Solve(0, 0, 0, -10, 0)
    Check(Near(r, -math.pi / 2), "Ziel im Osten, Blick nach Norden: Pfeil nach rechts")
    d, r = QA.Solve(0, 0, 10, 0, math.pi / 2)
    Check(Near(r, -math.pi / 2), "Ziel im Norden, Blick nach Westen: Pfeil nach rechts")
    d, r = QA.Solve(0, 0, -10, 0, 0)
    Check(Near(math.abs(r), math.pi), "Ziel im Sueden: Pfeil zeigt zurueck")
    local _, noFacing = QA.Solve(0, 0, 3, 4, nil)
    Check(noFacing == nil, "ohne Blickrichtung keine Pfeildrehung")
    Check(select(1, QA.Solve(0, 0, 3, 4, 0)) == 5, "Entfernung ist der Satz des Pythagoras")
    Check(QA.Compass(0) == "Norden" and QA.Compass(math.pi / 2) == "Westen"
        and QA.Compass(-math.pi / 2) == "Osten", "Himmelsrichtungen zaehlen gegen den Uhrzeigersinn")
    Check(QA.FormatDistance(40, "game") == "40 m", "Spieleinheit heisst m, wie im deutschen Client")
    Check(QA.FormatDistance(40, "metric") == "37 m", "echte Meter rechnen mit 0,9144")
    Check(QA.FormatDistance(40, "yards") == "40 yd", "Yards auf Wunsch")
    Check(QA.FormatDistance(1234, "game") == "1,2 km", "ab 1000 in km, mit Dezimalkomma")
end

-- Questpfeil: der ganze Weg vom ausgewaehlten Ziel bis zur Anzeige.
-- Die Karte der Attrappe: 1000 x 1000 Einheiten, oben ist Norden,
-- links ist Westen - wie im Spiel.
do
    _G.CreateVector2D = function(x, y) return { x = x, y = y } end
    _G.C_Map = {
        GetBestMapForUnit = function() return 1 end,
        GetPlayerMapPosition = function() return { x = 0.5, y = 0.5 } end,
        GetWorldPosFromMapPos = function(_, v)
            return 0, { x = 1000 - v.y * 1000, y = 1000 - v.x * 1000 }
        end,
    }
    _G.GetPlayerFacing = function() return 0 end
    -- Dieser Block prueft das Folgen der verfolgten Quest (bis 6.6.2.6 das
    -- einzige Verhalten); das Planen steht im Block danach.
    K.Set("questarrow", "plan", "tracked")
    local tracked = 42
    _G.C_SuperTrack = { GetSuperTrackedQuestID = function() return tracked end }
    _G.C_QuestLog = {
        GetTitleForQuestID = function() return "Die verlorene Axt" end,
        GetQuestsOnMap = function() return { { questID = 42, x = 0.5, y = 0.4 } } end,
    }
    QA.Update(true)
    Check(QA.frame:IsShown() and QA.texts.dist:GetText() == "100 m",
        "ausgewaehlte Quest 100 Einheiten noerdlich: 100 m")
    Check(QA.texts.title:GetText() == "Die verlorene Axt", "der Questname steht darueber")

    -- 6.6.0.1: Hoehe aus der Navigation des Spiels. Luftlinie 125, auf der
    -- Karte 100 -> 75 Hoehenunterschied; verdeckt -> Hinweis; Zielmarke
    -- am Bildschirmpunkt des Ziels.
    Check(QA.Height(125, 100) == 75 and QA.Height(90, 100) == nil, "Hoehe aus Luftlinie und Kartenabstand")
    -- 6.6.0.8: hoeher oder tiefer - nur aus der eigenen Hoehe, nie geraten.
    do
        local ok, err = pcall(function()
            QA.ResetHeight()
            assert(QA.TrackHeight(nil, 40) == nil, "ohne eigene Hoehe eine Richtung")
            -- Ziel auf Hoehe 100: bei z = 60 ist der Unterschied 40.
            QA.TrackHeight(60, 40)
            assert(QA.TrackHeight(61, 39) == nil, "unter 3 Einheiten schon entschieden")
            assert(QA.TrackHeight(70, 30) == "up", "Ziel hoeher nicht erkannt")
            QA.ResetHeight()
            -- Ziel auf Hoehe 20: bei z = 60 ist der Unterschied 40, steigt man, waechst er.
            QA.TrackHeight(60, 40)
            assert(QA.TrackHeight(70, 50) == "down", "Ziel tiefer nicht erkannt")
            QA.ResetHeight()
            -- Rauschen (Verhaeltnis passt nicht): keine Richtung.
            QA.TrackHeight(60, 40)
            assert(QA.TrackHeight(70, 40) == nil, "Rauschen als Richtung gedeutet")
            QA.ResetHeight()
            -- UnitPosition mit z = 0: "nicht gefuehrt", bis es sich bewegt.
            local oldUP = _G.UnitPosition
            local z = 0
            _G.UnitPosition = function() return 1, 2, z, 0 end
            QA._ResetZ()
            assert(QA.PlayerZ() == nil, "z = 0 als Hoehe genommen")
            z = 12.5
            assert(QA.PlayerZ() == 12.5, "echte Hoehe nicht gelesen")
            local lines = table.concat(QA.Inspect(), " | ")
            assert(lines:find("Höhe 12.5", 1, true), "/wcui pfeil ohne Hoehe: " .. lines)
            _G.UnitPosition = oldUP
            QA._ResetZ()
        end)
        Check(ok, "Questpfeil: hoeher oder tiefer nur aus der eigenen Hoehe, /wcui pfeil" .. (ok and "" or (": " .. tostring(err))))
    end
    local navFrame = CreateFrame("Frame", nil, UIParent)
    _G.Enum = _G.Enum or {}
    _G.Enum.NavigationState = { Invalid = 0, Occluded = 1, InRange = 2, Disabled = 3 }
    _G.C_Navigation = { GetDistance = function() return 125 end, GetTargetState = function() return 1 end,
                        GetFrame = function() return navFrame end, HasValidScreenPosition = function() return true end,
                        WasClampedToScreen = function() return false end }
    QA.Update(true)
    local ht = QA.texts.height:GetText() or ""
    Check(ht:find("Höhenunterschied ≈ 75 m", 1, true) and ht:find("verdeckt", 1, true),
        "Hoehenunterschied und verdeckt: " .. ht)
    Check(QA.marker and QA.marker:IsShown() and QA.marker:GetAlpha() == 0.5, "Zielmarke im Raum fehlt oder nicht halb durchsichtig")
    -- Eigene Wahl des Pfeils: die Navigation zeigt woandershin - keine Hoehe.
    QA.Chosen = 42
    tracked = 7
    QA.Update(true)
    Check((QA.texts.height:GetText() or "") == "" and not QA.marker:IsShown(),
        "Hoehe einer anderen Quest angezeigt")
    QA.Chosen, tracked = nil, 42
    _G.C_Navigation = nil
    QA.Update(true)
    Check((QA.texts.height:GetText() or "") == "" and not QA.marker:IsShown(), "ohne Navigation keine Hoehe")

    _G.C_Map.GetPlayerMapPosition = function() return nil end
    QA.Update(true)
    Check(QA.texts.dist:GetText() == "Position unbekannt",
        "ohne Spielerposition: unbekannt, nicht 0 m")

    _G.C_Map.GetPlayerMapPosition = function() return { x = 0.5, y = 0.5 } end
    _G.C_QuestLog.GetQuestsOnMap = function() return {} end
    QA.Update(true)
    Check(QA.texts.dist:GetText() == "Ort unbekannt",
        "Quest ohne Ort auf der Karte: Ort unbekannt")

    tracked = 0
    QA.Update(true)
    Check(not QA.frame:IsShown(), "nichts ausgewaehlt: kein Pfeil")

    -- Ziele erfuellt: der Pfeil fuehrt zur Abgabe und sagt es.
    tracked = 42
    _G.C_QuestLog.GetQuestsOnMap = function() return { { questID = 42, x = 0.5, y = 0.4 } } end
    _G.C_QuestLog.IsComplete = function(id) return id == 42 end
    QA.Update(true)
    Check(QA.texts.title:GetText() == "Abgeben: Die verlorene Axt", "erfuellte Quest: Abgeben davor")
    _G.C_QuestLog.IsComplete = nil

    -- Die naechste Quest: die naechstgelegene aus dem Questlog, ohne die
    -- abgegebene, auf Wunsch ohne erfuellte.
    _G.C_QuestLog.GetNumQuestLogEntries = function() return 4 end
    local log = { { questID = 42 }, { isHeader = true }, { questID = 7 }, { questID = 9 } }
    _G.C_QuestLog.GetInfo = function(i) return log[i] end
    _G.C_QuestLog.GetQuestsOnMap = function() return {
        { questID = 42, x = 0.5, y = 0.49 }, { questID = 7, x = 0.5, y = 0.2 }, { questID = 9, x = 0.5, y = 0.45 } } end
    Check(QA.NearestQuest(42) == 9, "naechste Quest: die naechstgelegene, ohne die abgegebene")
    _G.C_QuestLog.IsComplete = function(id) return id == 9 end
    Check(QA.NearestQuest(42, true) == 7, "naechste Quest ohne erfuellte")
    _G.C_QuestLog.IsComplete = nil
    local picked
    _G.C_SuperTrack.SetSuperTrackedQuestID = function(id) picked = id end
    local after = _G.C_Timer.After
    _G.C_Timer.After = function(_, fn) fn() end
    stub.FireEvent("SUPER_TRACKING_CHANGED")
    stub.FireEvent("QUEST_TURNED_IN", 42)
    _G.C_Timer.After = after
    -- 6.6.0.1: die Wahl bleibt beim Pfeil - C_SuperTrack aus dem Addon
    -- beruehrt Blizzards Questverfolgung (ADDON_ACTION_BLOCKED im Kampf).
    Check(QA.Chosen == 9 and picked == nil, "abgegeben: der Pfeil waehlt die naechste Quest selbst ("
        .. tostring(QA.Chosen) .. "), ohne C_SuperTrack (" .. tostring(picked) .. ")")
    QA.Update(true)
    Check(QA.frame:IsShown(), "der Pfeil zeigt auf seine eigene Wahl")
    local oldGet = _G.C_SuperTrack.GetSuperTrackedQuestID
    _G.C_SuperTrack.GetSuperTrackedQuestID = function() return 7 end
    stub.FireEvent("SUPER_TRACKING_CHANGED")
    Check(QA.Chosen == nil, "waehlt der Spieler selbst, gilt seine Wahl")
    _G.C_SuperTrack.GetSuperTrackedQuestID = oldGet
    QA.Chosen = nil

    -- Als Geist: zur Leiche, ohne Auswahl.
    tracked = 0
    _G.UnitIsGhost = function() return true end
    _G.C_DeathInfo = { GetCorpseMapPosition = function() return { x = 0.5, y = 0.3 } end }
    QA.Update(true)
    Check(QA.frame:IsShown() and QA.texts.title:GetText() == "Deine Leiche"
        and QA.texts.dist:GetText() == "200 m", "als Geist: 200 m zur Leiche")
    _G.C_DeathInfo.GetCorpseMapPosition = function() return nil end
    QA.Update(true)
    Check(QA.texts.dist:GetText() == "Ort unbekannt", "Leiche ohne Ort: unbekannt, nicht 0 m")
    _G.UnitIsGhost, _G.C_DeathInfo = nil, nil
    QA.Update(true)
    Check(not QA.frame:IsShown(), "wiederbelebt und nichts ausgewaehlt: kein Pfeil")
    K.Set("questarrow", "plan", "smart")

    -- 6.6.2.7: der Pfeil plant selbst (Beta-Test: "schickt mich durch die
    -- Weltgeschichte"). Spieler bei (500, 500); Norden = kleineres y.
    local oldGT, oldUL, oldAfter = _G.GetTime, _G.UnitLevel, _G.C_Timer.After
    local ok, err = pcall(function()
        local now = 1000
        _G.GetTime = function() return now end
        _G.UnitLevel = function() return 10 end
        _G.C_Timer.After = function(_, fn) fn() end
        assert(QA.Weight(15, 10) == 4 and QA.Weight(13, 10) == 1.5 and QA.Weight(10, 10) == 1
            and QA.Weight(10, 10, 3) == 3 and QA.Weight(nil, 10) == 1, "Gewichte falsch")
        -- Spiel verfolgt 7 (weit weg, erfuellt: Abgabe im Norden, 400 m).
        -- Offen: 9 (80 m) und 11 (60 m, aber 6 Stufen ueber dir -> 240).
        local game = 7
        _G.C_SuperTrack.GetSuperTrackedQuestID = function() return game end
        local log = { { questID = 7, level = 10 }, { questID = 9, level = 10 }, { questID = 11, level = 16 } }
        local where = { [7] = { 0.5, 0.1 }, [9] = { 0.5, 0.42 }, [11] = { 0.5, 0.44 } }
        _G.C_QuestLog.GetNumQuestLogEntries = function() return #log end
        _G.C_QuestLog.GetInfo = function(i) return log[i] end
        _G.C_QuestLog.IsComplete = function(id) return id == 7 end
        local calls = 0
        _G.C_QuestLog.GetQuestsOnMap = function()
            calls = calls + 1
            local out = {}
            for _, e in ipairs(log) do
                local p = where[e.questID]
                out[#out + 1] = { questID = e.questID, x = p[1], y = p[2] }
            end
            return out
        end
        QA.manual, QA.Chosen = nil, nil
        stub.FireEvent("PLAYER_ENTERING_WORLD")
        assert(QA.Chosen == 9, "nicht das naechste lohnende Ziel: " .. tostring(QA.Chosen))
        calls = 0
        QA.PlanDirty()
        QA.Replan()
        assert(calls == 1, "Karte je Quest neu abgefragt: " .. calls)
        -- 6.14.0.2: ohne Ereignis rechnet der Lauf nur - kein GetInfo, keine Karte.
        local infos, getInfo = 0, _G.C_QuestLog.GetInfo
        _G.C_QuestLog.GetInfo = function(i) infos = infos + 1 return getInfo(i) end
        calls = 0
        QA.Replan()
        assert(calls == 0 and infos == 0 and QA.Chosen == 9, "Planen ohne Ereignis fragt den Questlog: " .. calls .. "/" .. infos)
        _G.C_QuestLog.GetInfo = getInfo
        QA.Update(true)
        assert(QA.texts.dist:GetText() == "80 m", "Pfeil zeigt nicht auf das geplante Ziel: " .. tostring(QA.texts.dist:GetText()))
        -- Nicht hin und her: 13 taucht 70 m entfernt auf - kaum naeher, 9 bleibt.
        table.insert(log, { questID = 13, level = 10 })
        where[13] = { 0.5, 0.43 }
        stub.FireEvent("QUEST_ACCEPTED", 13)
        assert(QA.Chosen == 9, "springt wegen 10 m zu einem anderen Ziel")
        -- Deutlich naeher (20 m): jetzt wechselt er (das Spiel meldet den
        -- neuen Ort mit QUEST_POI_UPDATE).
        where[13] = { 0.5, 0.48 }
        stub.FireEvent("QUEST_POI_UPDATE")
        assert(QA.Chosen == 13, "deutlich naeheres Ziel nicht genommen")
        -- Das Spiel waehlt beim Annehmen selbst: gilt NICHT als eigene Wahl.
        stub.FireEvent("QUEST_ACCEPTED", 13)
        game = 7
        stub.FireEvent("SUPER_TRACKING_CHANGED")
        assert(not QA.manual and QA.Chosen == 13, "Wahl des Spiels beim Annehmen als eigene Wahl genommen")
        -- Auch wenn das Spiel die Verfolgung VOR dem Annehmen meldet.
        now = now + 10
        game = 9
        local queued = {}
        _G.C_Timer.After = function(_, fn) queued[#queued + 1] = fn end
        stub.FireEvent("SUPER_TRACKING_CHANGED")
        stub.FireEvent("QUEST_ACCEPTED", 9)
        _G.C_Timer.After = function(_, fn) fn() end
        assert(#queued >= 1, "Entscheidung nicht verschoben")
        for _, fn in ipairs(queued) do fn() end
        assert(not QA.manual, "Verfolgung vor dem Annehmen als eigene Wahl genommen")
        game = 7
        -- Spaeter, ohne Anlass: der Spieler hat geklickt - seine Wahl gilt.
        now = now + 10
        game = 11
        stub.FireEvent("SUPER_TRACKING_CHANGED")
        assert(QA.manual == 11, "eigene Wahl uebergangen")
        QA.Update(true)
        assert(QA.texts.dist:GetText() == "60 m", "Pfeil zeigt nicht auf die eigene Wahl")
        -- Abgegeben: zurueck zum Planen.
        table.remove(log, 3)
        stub.FireEvent("QUEST_TURNED_IN", 11)
        assert(not QA.manual and QA.Chosen == 13, "nach der Abgabe nicht weiter geplant: " .. tostring(QA.Chosen))
        -- /wcui pfeil weiter: das jetzige Ziel auslassen.
        assert(QA.Skip() == 13 and QA.Chosen == 9, "Ueberspringen waehlt nicht das naechste")
        local lines = table.concat(QA.Inspect(), " | ")
        assert(lines:find("Ziel: geplant", 1, true) and lines:find("Abgeben: ", 1, true), "/wcui pfeil ohne Plan: " .. lines)
    end)
    QA.skipped[13] = nil
    QA.manual, QA.Chosen = nil, nil
    _G.GetTime, _G.UnitLevel, _G.C_Timer.After = oldGT, oldUL, oldAfter
    _G.C_QuestLog.IsComplete, _G.C_QuestLog.GetNumQuestLogEntries, _G.C_QuestLog.GetInfo = nil, nil, nil
    Check(ok, "Questpfeil plant: naechstes lohnendes Ziel, kein Hin und Her, eigene Wahl bis zur Abgabe"
        .. (ok and "" or (": " .. tostring(err))))

    -- 6.14.0.2: die eigene Lage ueber UnitPosition, wenn es mit der Karte
    -- uebereinstimmt - dann keine Vektoren mehr je Lauf.
    local saved = { _G.GetTime, _G.UnitPosition, _G.C_Map.GetPlayerMapPosition }
    ok, err = pcall(function()
        local now = 5000
        _G.GetTime = function() return now end
        local mapCalls = 0
        -- Spieler bei Karte (0.4, 0.5): Norden 500, Westen 600 (siehe oben).
        _G.C_Map.GetPlayerMapPosition = function() mapCalls = mapCalls + 1 return { x = 0.4, y = 0.5 } end
        local un, uw = 500, 600
        _G.UnitPosition = function() return un, uw, 0, 0 end
        WeintCodex.UIKit._posFast.ok, WeintCodex.UIKit._posFast.at = false, -math.huge
        local c, n, w = QA.PlayerWorld()
        assert(c == 0 and n == 500 and w == 600 and WeintCodex.UIKit._posFast.ok, "Abgleich mit der Karte nicht bestanden")
        mapCalls = 0
        un = 510
        c, n = QA.PlayerWorld()
        assert(mapCalls == 0 and n == 510, "UnitPosition nicht genommen")
        -- Nach WeintCodex.UIKit.POS_CHECK_EVERY s wieder ueber die Karte geprueft.
        now = now + WeintCodex.UIKit.POS_CHECK_EVERY + 1
        c, n = QA.PlayerWorld()
        assert(mapCalls == 1 and n == 500 and not WeintCodex.UIKit._posFast.ok, "nicht erneut geprueft oder Abweichung uebersehen")
        -- Vertauschte Achsen oder andere Zaehlung: nie genommen.
        un, uw = 600, 500
        now = now + WeintCodex.UIKit.POS_CHECK_EVERY + 1
        QA.PlayerWorld()
        assert(not WeintCodex.UIKit._posFast.ok, "vertauschte Achsen genommen")
        -- Auf der Diagonale (Norden = Westen) waere ein Tausch unsichtbar.
        _G.C_Map.GetPlayerMapPosition = function() return { x = 0.5, y = 0.5 } end
        un, uw = 500, 500
        QA.PlayerWorld()
        assert(not WeintCodex.UIKit._posFast.ok, "auf der Diagonale genommen")
        -- Anderer Kontinent als die Karte: nicht genommen.
        _G.C_Map.GetPlayerMapPosition = function() return { x = 0.4, y = 0.5 } end
        un, uw = 500, 600
        _G.UnitPosition = function() return un, uw, 0, 1 end
        QA.PlayerWorld()
        assert(not WeintCodex.UIKit._posFast.ok, "anderer Kontinent genommen")
        -- Kartenkoordinaten (Minikarte, Weltkarte) aus derselben Lage: wie
        -- ueber die Karte, aber ohne neue Vektoren.
        local KK = WeintCodex.UIKit
        _G.UnitPosition = function() return un, uw, 0, 0 end
        now = now + KK.POS_CHECK_EVERY + 1
        local x, y = KK.PlayerMapXY(1)
        assert(math.abs(x - 0.4) < 1e-9 and math.abs(y - 0.5) < 1e-9 and KK._posFast.ok, "Kartenlage: " .. tostring(x) .. "/" .. tostring(y))
        mapCalls = 0
        _G.C_Map.GetPlayerMapPosition = function() mapCalls = mapCalls + 1 return { x = 0.4, y = 0.5 } end
        un, uw = 400, 700     -- 100 nach Sueden und Osten: x 0.3, y 0.6
        x, y = KK.PlayerMapXY(1)
        assert(mapCalls == 0 and math.abs(x - 0.3) < 1e-9 and math.abs(y - 0.6) < 1e-9, "Kartenlage ohne Karte gerechnet: " .. tostring(x) .. "/" .. tostring(y))
        -- Ausserhalb der Karte: nichts, keine 0 oder 1.
        un = -5
        assert(KK.PlayerMapXY(1) == nil, "Lage ausserhalb der Karte erfunden")
        -- Ohne UnitPosition: der Weg ueber die Karte.
        _G.UnitPosition = nil
        now = now + KK.POS_CHECK_EVERY + 1
        x = KK.PlayerMapXY(1)
        assert(x == 0.4, "ohne UnitPosition nicht ueber die Karte")
        -- Haushalt: 100 Laeufe (20 s Spiel) mit bestaetigter Lage legen
        -- kaum Wegwerf-Speicher an - vorher zwei Vektoren je Lauf.
        local oldST = _G.C_SuperTrack.GetSuperTrackedQuestID
        _G.C_SuperTrack.GetSuperTrackedQuestID = function() return 42 end
        QA.manual, QA.Chosen = nil, nil
        K.Set("questarrow", "plan", "tracked")
        _G.C_QuestLog.GetQuestsOnMap = function() return { { questID = 42, x = 0.5, y = 0.4 } } end
        _G.UnitPosition = function() return 500, 600, 0, 0 end
        now = now + KK.POS_CHECK_EVERY + 1
        QA.Update(true)
        local vecs = 0
        _G.C_Map.GetPlayerMapPosition = function() vecs = vecs + 1 return { x = 0.4, y = 0.5 } end
        collectgarbage("collect") collectgarbage("stop")
        local kb0 = collectgarbage("count")
        for _ = 1, 100 do now = now + 0.2 QA.Update() end
        local used = collectgarbage("count") - kb0
        collectgarbage("restart")
        local shown = QA.texts.dist:GetText()
        _G.C_SuperTrack.GetSuperTrackedQuestID = oldST
        K.Set("questarrow", "plan", "smart")
        assert(QA.frame:IsShown() and tostring(shown):find("^%d+ m$"), "Haushalt ohne Pfeil gemessen: " .. tostring(shown))
        print(string.format("  --    Questpfeil: 100 Laeufe %.1f KB, %d Kartenabfragen", used, vecs))
        assert(vecs <= 3, "Questpfeil fragt die Karte je Lauf: " .. vecs)
        assert(used < 6, string.format("Questpfeil: %.1f KB fuer 100 Laeufe", used))
    end)
    _G.GetTime, _G.UnitPosition, _G.C_Map.GetPlayerMapPosition = saved[1], saved[2], saved[3]
    WeintCodex.UIKit._posFast.ok = false
    Check(ok, "Questpfeil: eigene Lage ueber UnitPosition nur nach Abgleich mit der Karte"
        .. (ok and "" or (": " .. tostring(err))))
end

-- Questpfeil: die 3D-Ansichten und die Farbe.
do
    local idx, l, r, t, b = QA.Frame(0)
    Check(idx == 0 and l == 0 and r == 0.125 and t == 0 and b == 0.125, "geradeaus: Ansicht 0, oben links")
    idx = QA.Frame(math.pi / 2)
    Check(idx == 16, "90 Grad links: Ansicht 16")
    idx = QA.Frame(-math.pi / 2)
    Check(idx == 48, "90 Grad rechts: Ansicht 48")
    idx = QA.Frame(math.pi * 2 - 0.01)
    Check(idx == 0, "knapp unter 360 Grad: wieder Ansicht 0")
    local C = WeintCodex.Colors
    local r0, g0 = QA.CourseColor(0)
    local r1, g1 = QA.CourseColor(math.pi)
    local rm, gm = QA.CourseColor(math.pi / 2)
    local function Eq(a, b) return math.abs(a - b) < 1e-9 end
    Check(Eq(r0, C.successBright[1]) and Eq(g0, C.successBright[2]), "geradeaus gruen")
    Check(Eq(r1, C.dangerBright[1]) and Eq(g1, C.dangerBright[2]), "entgegengesetzt rot")
    Check(Eq(rm, C.warningBright[1]) and Eq(gm, C.warningBright[2]), "quer gelb")
    local h = io.open(ROOT .. "/media/ui/arrow3d.tga", "rb")
    local head = h and h:read(18)
    if h then h:close() end
    local w = head and (head:byte(13) + head:byte(14) * 256)
    local hh = head and (head:byte(15) + head:byte(16) * 256)
    Check(w == 512 and hh == 512, "arrow3d.tga ist 512 x 512 (8 x 8 Ansichten)")
end

-- JEDE GRAFIK, DIE ui/ ANFORDERT, GIBT ES (6.9.0.2). Ein Pfad ohne Datei
-- zeichnet im Spiel ein gruenes Rechteck - und faellt hier sonst niemandem
-- auf. Gesucht wird K.MEDIA .. "name" im Code (Kommentare ausgenommen).
do
    local missing, seen = {}, 0
    local pipe = io.popen and io.popen('ls "' .. ROOT .. '/ui" 2>/dev/null')
    if pipe then
        for name in pipe:lines() do
            if name:match("%.lua$") then
                local h = io.open(ROOT .. "/ui/" .. name, "r")
                local code = h:read("*a"):gsub("%-%-[^\n]*", "")
                h:close()
                for tex in code:gmatch('K%.MEDIA%s*%.%.%s*"([%w_]+)"') do
                    seen = seen + 1
                    local f = io.open(ROOT .. "/media/ui/" .. tex .. ".tga", "rb")
                        or io.open(ROOT .. "/media/ui/" .. tex .. ".blp", "rb")
                    if f then f:close() else missing[#missing + 1] = "ui/" .. name .. ": " .. tex end
                end
            end
        end
        pipe:close()
    end
    Check(seen > 0 and #missing == 0, seen .. " Grafiken aus ui/ liegen in media/ui"
        .. (#missing == 0 and "" or (" – fehlt: " .. table.concat(missing, ", "))))

    -- Das Logo der Oberflaeche: zwei Groessen, oben links gespeichert (wie
    -- die anderen Grafiken, Kopfbyte 0x28), an Minikarte, Assistent und /wcui.
    local function Head(file)
        local h = io.open(ROOT .. "/media/ui/" .. file, "rb")
        local head = h and h:read(18)
        if h then h:close() end
        if not head then return nil end
        return head:byte(13) + head:byte(14) * 256, head:byte(15) + head:byte(16) * 256, head:byte(17), head:byte(18)
    end
    local ok = true
    for file, size in pairs({ ["logo_32.tga"] = 32, ["logo_64.tga"] = 64 }) do
        local w, hh, bpp, desc = Head(file)
        if not (w == size and hh == size and bpp == 32 and desc == 0x28) then ok = false end
    end
    local LN, WL = WeintCodex.UILauncher, WeintCodex.UIWelcome
    Check(ok and LN.ICON == K.MEDIA .. "logo_32" and LN.ICON_COORDS and LN.ICON_COORDS[1] == 0
        and LN.ICON_COORDS[2] == 1, "Logo: 32 und 64 px mit Alpha, oben links; Symbol an der Minikarte zeigt es ganz")
end

-- DIE MODULE AUS 6.0.0.3 gegen die Attrappe: jedes einmal mit Daten,
-- nicht nur geladen.
do
    local A = WeintCodex.UIAuras

    -- Auren, Engine-Weg: der Auren-Container des Spiels (12.1).
    _G.C_AddOns = { IsAddOnLoaded = function() return true end, LoadAddOn = function() end }
    _G.AnchorUtil = { FlowDirection = { Left = 1, Right = 2, Up = 3, Down = 4 } }
    A._ResetEngineProbe()
    local ok, err = pcall(function()
        assert(A.EngineAvailable(), "Container nicht erkannt")
        local o = A.Create(UIParent, { filter = "HARMFUL|PLAYER", max = 4, size = 20 })
        assert(o.engine, "Engine-Weg nicht genommen")
        o:SetPoint("CENTER", UIParent, "CENTER")
        o:SetUnit("target")
        o:Refresh()
        o:ApplyLayout({ filter = "HARMFUL", max = 4, size = 26 })
        o:SetUnit(nil)
    end)
    Check(ok, "Auren ueber den Container des Spiels" .. (ok and "" or (": " .. tostring(err))))

    -- Der Container wie im Spiel: AddAuraGroup ruft initializeFrame fuer
    -- jeden Knopf, und der Knopf nimmt Symbol, Uhr, Zahl und Restzeit an.
    -- Einmal scheitert der erste Aufbau - dann muss der vereinfachte
    -- greifen und der Fehlschlag in A.StatusText stehen.
    ok, err = pcall(function()
        local realCreate = _G.CreateFrame
        local failNext = false
        local registered = {}
        _G.CreateFrame = function(kind, name, parent, template)
            local f = realCreate(kind, name, parent, template)
            if kind == "AuraContainer" then
                f.AddAuraGroup = function(self, key, filter, spec)
                    if failNext then failNext = false error("Testfehler im Initialisierer") end
                    local b = realCreate("Button", nil, self)
                    b.SetIcon = function(_, t) registered.icon = t end
                    b.SetDurationCooldown = function(_, c) registered.cd = c end
                    b.SetApplicationCount = function(_, fs) registered.count = fs; fs:SetText("3") end
                    b.SetDurationText = function(_, fs) registered.dur = fs; fs:SetText("7") end
                    spec.initializeFrame(b)
                    self._anchoredBeforeGroup = self._anchored
                end
                local sp = f.SetPoint
                f.SetPoint = function(self, ...) self._anchored = true return sp(self, ...) end
            end
            return f
        end
        local o = A.Create(UIParent, { filter = "HARMFUL", max = 4, size = 24, timer = true })
        assert(o.engine and o.frame._anchoredBeforeGroup, "Container nicht vor der ersten Gruppe verankert")
        assert(registered.icon and registered.cd and registered.count and registered.dur,
            "Knopf hat nicht alles angemeldet")
        failNext = true
        local o2 = A.Create(UIParent, { filter = "HARMFUL", max = 4, size = 24 })
        assert(o2.engine, "nach einem Fehlschlag kein vereinfachter Container")
        assert(A.stats.minimal >= 1 and A.StatusText():find("Testfehler", 1, true),
            "Fehlschlag nicht gemeldet: " .. A.StatusText())
        _G.CreateFrame = realCreate
    end)
    Check(ok, "Auren-Container: vor der Gruppe verankert, Knopf angemeldet, Fehlschlag gemeldet"
        .. (ok and "" or (": " .. tostring(err))))
    _G.C_AddOns, _G.AnchorUtil = nil, nil
    A._ResetEngineProbe()

    -- Auren, alter Weg: gelesen, gekappt bei max.
    _G.C_UnitAuras = { GetAuraDataByIndex = function(_, i)
        if i <= 3 then
            return { icon = 136197, applications = 2, duration = 10, expirationTime = 20, auraInstanceID = i }
        end
    end }
    ok, err = pcall(function()
        local o = A.Create(UIParent, { max = 2 })
        assert(not o.engine, "ohne Container darf der Engine-Weg nicht gewaehlt werden")
        o:SetUnit("target")
        assert(#o.buttons == 2, "alter Weg haelt sich nicht an max (" .. #o.buttons .. ")")
    end)
    Check(ok, "Auren ueber GetAuraDataByIndex, hoechstens max" .. (ok and "" or (": " .. tostring(err))))

    -- Der Weg laesst sich im laufenden Spiel umschalten, und /wcui auren
    -- sagt, was das Spiel nennt und was davon zu sehen ist. Der Container
    -- ist so gross wie seine Symbole (bis 6.1.0.0: 1 x 1).
    _G.C_AddOns = { IsAddOnLoaded = function() return true end, LoadAddOn = function() end }
    _G.AnchorUtil = { FlowDirection = { Left = 1, Right = 2, Up = 3, Down = 4 } }
    A._ResetEngineProbe()
    ok, err = pcall(function()
        local o = A.Create(UIParent, { filter = "HARMFUL", max = 5, size = 20, spacing = 2 })
        assert(o.engine, "Container erwartet")
        assert(o.frame:GetWidth() == 110 and o.frame:GetHeight() == 22,
            "Container nicht so gross wie seine Symbole: " .. o.frame:GetWidth() .. "x" .. o.frame:GetHeight())
        o:SetPoint("BOTTOMLEFT", UIParent, "TOPLEFT", 0, 3)
        o:SetUnit("target")
        A.SetMode("legacy")
        assert(not o.engine and o.buttons and #o.buttons == 3, "Umschalten auf den alten Weg liest nicht neu")
        local lines = A.Inspect()
        local joined = table.concat(lines, " | ")
        assert(joined:find("nennt am Ziel: 3", 1, true) and joined:find("alter Weg, 3 Symbole, 3 gezeigt", 1, true),
            "Auskunft unvollstaendig: " .. joined)
        A.SetMode("auto")
        assert(o.engine, "zurueck auf Automatisch nimmt den Container nicht")
        -- Selbstheilung: das Spiel nennt 3 Auren, der Container zeigt
        -- keine -> ab jetzt selbst lesen, einmal gemeldet.
        local oldAfter = _G.C_Timer.After
        _G.C_Timer.After = function(_, fn) fn() end
        A._ResetVerdict()
        o:Refresh()
        _G.C_Timer.After = oldAfter
        assert(not o.engine and A.stats.autoFallback and #o.buttons == 3,
            "Container ohne Symbole: kein Rueckfall auf den alten Weg")
        assert(A.StatusText():find("liest selbst", 1, true), "Rueckfall nicht im Zustand: " .. A.StatusText())
        A._ResetVerdict()
        A.SetMode("legacy") A.SetMode("auto")
    end)
    Check(ok, "Auren: Weg umschaltbar, Container in voller Groesse, /wcui auren gibt Auskunft"
        .. (ok and "" or (": " .. tostring(err))))
    _G.C_AddOns, _G.AnchorUtil = nil, nil
    A._ResetEngineProbe()
    _G.C_UnitAuras = nil
end

-- Questfortschritt auf der Plakette: aus den Tooltipdaten, nur eigene
-- Quests, nichts Geratenes.
do
    local NP = WeintCodex.UINameplates
    local ok, err = pcall(function()
        _G.Enum = _G.Enum or {}
        _G.Enum.TooltipDataLineType = { QuestTitle = 17, QuestObjective = 8 }
        local lines = {
            { type = 17, id = 500 },
            { type = 8, completed = false, numFulfilled = 8, numRequired = 10, leftText = "Ohr eines Kultisten: 8/10" },
        }
        _G.C_TooltipInfo = { GetUnit = function() return { lines = lines } end }
        _G.C_QuestLog = _G.C_QuestLog or {}
        local onQuest = true
        _G.C_QuestLog.IsOnQuest = function() return onQuest end
        assert(NP.QuestProgress("nameplate1") == "8/10", "8/10 erwartet: " .. tostring(NP.QuestProgress("nameplate1")))
        stub.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate1")
        local p = NP.plates["nameplate1"]
        assert(p.quest:IsShown() and p.quest:GetText() == "8/10", "Plakette zeigt den Stand nicht")
        onQuest = false
        assert(NP.QuestProgress("nameplate1") == nil, "Quest eines anderen zaehlt nicht")
        onQuest = true
        lines[2].completed = true
        assert(NP.QuestProgress("nameplate1") == nil, "erledigtes Ziel zaehlt nicht")
        lines[2] = { type = 8, completed = false, leftText = "Gebiet gesaeubert: 40 %" }
        assert(NP.QuestProgress("nameplate1") == "40%", "Gebietsquest in Prozent")
        lines[2] = { type = 8, completed = false }
        assert(NP.QuestProgress("nameplate1") == "!", "ohne lesbaren Stand: markiert, nicht geraten")
        -- Questlog geaendert: neu gelesen.
        lines[2] = { type = 8, completed = false, numFulfilled = 9, numRequired = 10 }
        -- 6.14.0.2: ein Schub QUEST_LOG_UPDATE liest den Tooltip je Plakette
        -- einmal (der Zeitgeber der Attrappe laeuft nie - hier von Hand).
        local reads, getUnit = 0, _G.C_TooltipInfo.GetUnit
        _G.C_TooltipInfo.GetUnit = function(...) reads = reads + 1 return getUnit(...) end
        local queued, after = {}, _G.C_Timer.After
        _G.C_Timer.After = function(_, fn) queued[#queued + 1] = fn end
        NP.QuestRefresh()   -- ein haengender Merker aus frueheren Schritten
        reads = 0
        stub.FireEvent("QUEST_LOG_UPDATE")
        stub.FireEvent("QUEST_LOG_UPDATE")
        stub.FireEvent("UNIT_QUEST_LOG_CHANGED", "player")
        _G.C_Timer.After = after
        local mine = 0
        for _, fn in ipairs(queued) do if fn == NP.QuestRefresh then mine = mine + 1 end end
        assert(reads == 0 and mine == 1, "Tooltip je Ereignis gelesen oder je Ereignis geplant: " .. reads .. "/" .. mine)
        NP.QuestRefresh()
        assert(reads == 1, "Tooltip je Schub nicht genau einmal: " .. reads)
        assert(p.quest:GetText() == "9/10", "nach Questlog-Aenderung nicht neu gelesen")
        -- Haushalt (6.14.0.2): 100 Treffer an einer Plakette legen keine
        -- Tabelle je Treffer an (vorher eine fuer die Textplaetze).
        local handler
        for _, f in ipairs(stub._registry) do
            if f._events and f._events.NAME_PLATE_UNIT_ADDED and f._scripts and f._scripts.OnEvent then
                local fr = f
                handler = function(...) fr._scripts.OnEvent(fr, ...) end
            end
        end
        handler("UNIT_HEALTH", "nameplate1")
        collectgarbage("collect") collectgarbage("stop")
        local kb0 = collectgarbage("count")
        for _ = 1, 100 do handler("UNIT_HEALTH", "nameplate1") end
        local used = collectgarbage("count") - kb0
        collectgarbage("restart")
        print(string.format("  --    Plakette: 100 Treffer %.1f KB", used))
        assert(used < 2, string.format("Plakette: %.1f KB fuer 100 Treffer", used))
        stub.FireEvent("NAME_PLATE_UNIT_REMOVED", "nameplate1")
        _G.C_TooltipInfo, _G.C_QuestLog.IsOnQuest = nil, nil
    end)
    Check(ok, "Plakette: Questfortschritt 8/10, nur eigene, Prozent, nichts geraten"
        .. (ok and "" or (": " .. tostring(err))))
    Check(WeintCodex.UIAuras.FormatRemaining(7.2) == "7" and WeintCodex.UIAuras.FormatRemaining(125) == "2m"
        and WeintCodex.UIAuras.FormatRemaining(1.44) == "1,4" and WeintCodex.UIAuras.FormatRemaining(-1) == "",
        "Restzeit am Symbol: 7 / 2m / 1,4 / abgelaufen leer")
end

-- Plaketten 2.0: Ziel leuchtet mit Marken, die Maus hellt auf, die
-- anderen treten zurueck - und die Maus holt eine zurueckgetretene nach
-- vorn.
do
    local NP = WeintCodex.UINameplates
    local ok, err = pcall(function()
        local isTarget, mouse = {}, nil
        local oldIsUnit, oldExists = _G.UnitIsUnit, _G.UnitExists
        _G.UnitIsUnit = function(a, b)
            if b == "target" then return isTarget[a] == true end
            if b == "mouseover" then return mouse == a end
            return a == b
        end
        _G.UnitExists = function(u) if u == "mouseover" then return mouse ~= nil end return true end
        local plate2 = stub.NewObject("Frame", "NamePlate2")
        plate2.UnitFrame = stub.NewObject("Frame")
        local oldGet = _G.C_NamePlate.GetNamePlateForUnit
        _G.C_NamePlate.GetNamePlateForUnit = function(unit)
            if unit == "nameplate2" then return plate2 end
            return oldGet(unit)
        end
        stub.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate1")
        stub.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate2")
        local a, b = NP.plates["nameplate1"], NP.plates["nameplate2"]
        assert(a and b, "zwei Plaketten erwartet")
        isTarget.nameplate1 = true
        stub.FireEvent("PLAYER_TARGET_CHANGED")
        assert(a.glow.tex:IsShown() and a.marks[1]:IsShown() and a.marks[2]:IsShown(), "Ziel ohne Leuchten und Marken")
        assert(not b.glow.tex:IsShown() and not b.marks[1]:IsShown(), "Nicht-Ziel leuchtet")
        assert(math.abs(b:GetAlpha() - 0.7) < 0.001, "Nicht-Ziel nicht auf 70 %: " .. tostring(b:GetAlpha()))
        assert(a:GetAlpha() == 1, "Ziel abgedunkelt")
        mouse = "nameplate2"
        stub.FireEvent("UPDATE_MOUSEOVER_UNIT")
        assert(b.hoverFill:IsShown() and b.hoverGlow.tex:IsShown(), "Maus hellt nicht auf")
        assert(b:GetAlpha() == 1, "Maus holt die Plakette nicht nach vorn")
        mouse = nil
        NP.SetHovered(nil)
        assert(not b.hoverFill:IsShown() and math.abs(b:GetAlpha() - 0.7) < 0.001, "Maus weg: Hervorhebung bleibt")
        K.Set("nameplates", "targetStyle", "ring")
        stub.FireEvent("PLAYER_TARGET_CHANGED")
        assert(not a.glow.tex:IsShown() and a.ring.top:IsShown(), "Zielstil 'Rand' greift nicht")
        K.Set("nameplates", "targetStyle", "glow")
        isTarget.nameplate1 = nil
        stub.FireEvent("NAME_PLATE_UNIT_REMOVED", "nameplate1")
        stub.FireEvent("NAME_PLATE_UNIT_REMOVED", "nameplate2")
        _G.UnitIsUnit, _G.UnitExists = oldIsUnit, oldExists
        _G.C_NamePlate.GetNamePlateForUnit = oldGet
    end)
    Check(ok, "Plakette 2.0: Ziel leuchtet mit Marken, Maus hellt auf, andere auf 70 %"
        .. (ok and "" or (": " .. tostring(err))))
end

-- Plaketten 3.0 (6.8.1.0, Entwurf B + C): Schadensspur, weiche Balken,
-- Ziel atmet (Leuchten, Glanz, Kante, Marken), Treffer blitzt. Werte nur
-- durchgereicht (geheim erlaubt), kein Muell je Treffer.
do
    local NP = WeintCodex.UINameplates
    local ok, err = pcall(function()
        local isTarget, now, cur = {}, 100, 100
        local saved = { UnitIsUnit = _G.UnitIsUnit, UnitHealth = _G.UnitHealth, UnitHealthMax = _G.UnitHealthMax,
                        GetTime = _G.GetTime, Enum = _G.Enum }
        local okIn, errIn = pcall(function()
        _G.UnitIsUnit = function(a, b) if b == "target" then return isTarget[a] == true end return a == b end
        _G.UnitHealth = function() return cur end
        _G.UnitHealthMax = function() return 100 end
        _G.GetTime = function() return now end
        _G.Enum = setmetatable({ StatusBarInterpolation = { Immediate = 0, ExponentialEaseOut = 1 } }, { __index = saved.Enum })
        NP.smoothBroken = nil
        stub.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate1")
        local p = NP.plates["nameplate1"]
        assert(p and p.trail and p.bg._parent == p, "Plakette ohne Spur oder Grund nicht am Rahmen")
        assert(p.trail:GetFrameLevel() < p.health:GetFrameLevel(), "Spur nicht hinter dem Leben")
        local hv, hi, tv, ti, tcalls = nil, nil, nil, nil, 0
        p.health.SetValue = function(_, v, i) hv, hi = v, i end
        p.trail.SetValue = function(_, v, i) tv, ti, tcalls = v, i, tcalls + 1 end
        -- Treffer: Leben gleitet sofort, die Spur wartet.
        cur = 70
        stub.FireEvent("UNIT_HEALTH", "nameplate1")
        assert(hv == 70 and hi == 1, "Leben gleitet nicht: " .. tostring(hi))
        assert(tcalls == 0 and NP.trailPending[p], "Spur folgt sofort statt zu warten")
        now = now + NP.TRAIL_DELAY / 2
        cur = 55
        stub.FireEvent("UNIT_HEALTH", "nameplate1")
        NP.TrailTick()
        assert(tcalls == 0, "Spur zu frueh")
        -- Kurz nach der Frist des ERSTEN Treffers: die Spur schmilzt - der
        -- zweite Treffer darf die Uhr nicht zuruecksetzen (sonst schmilzt
        -- sie in einem langen Kampf nie).
        now = now + NP.TRAIL_DELAY / 2 + 0.01
        NP.TrailTick()
        assert(tcalls == 1 and tv == 55 and ti == 1 and not NP.trailPending[p], "Spur schmilzt nicht zum neuesten Wert")
        -- Neue Einheit: Spur sofort.
        stub.FireEvent("NAME_PLATE_UNIT_REMOVED", "nameplate1")
        stub.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate1")
        p = NP.plates["nameplate1"]
        tcalls = 0
        p.trail.SetValue = function(_, v) tv, tcalls = v, tcalls + 1 end
        p.health.SetValue = function(_, v, i) hv, hi = v, i end
        assert(not NP.trailPending[p], "neue Einheit wartet mit alter Spur")
        -- Client lehnt das Gleiten ab: einmal Rueckfall, danach ohne.
        p.health.SetValue = function(_, v, i) if i ~= nil then error("kein Gleiten") end hv, hi = v, i end
        cur = 40
        stub.FireEvent("UNIT_HEALTH", "nameplate1")
        assert(hv == 40 and hi == nil and NP.smoothBroken, "Rueckfall ohne Gleiten fehlt")
        NP.smoothBroken = nil
        -- Ziel: atmen, Glanz, Kante, Marken; Treffer blitzt.
        local plays, stops = {}, {}
        local function Spy(ag, name)
            ag.Play = function() plays[name] = (plays[name] or 0) + 1 end
            ag.Stop = function() stops[name] = (stops[name] or 0) + 1 end
        end
        Spy(p.pulseAnims[1], "pulse") Spy(p.sheenAnim, "sheen") Spy(p.markAnims[1], "marks") Spy(p.flashAnim, "flash")
        p._fxPulse, p._fxSheen, p._fxMarks, p._fxEdge = nil, nil, nil, nil
        local edgeColor
        p.border.SetColor = function(_, r, g, b) edgeColor = { r, g, b } end
        -- 6.10.0.0: von Haus aus "Ruhig" - das Ziel leuchtet, aber nichts
        -- atmet, glaenzt, bewegt sich oder blitzt; die Kante bleibt.
        assert(K.Get("nameplates", "motion") == "calm", "Standard ist nicht 'Ruhig'")
        isTarget.nameplate1 = true
        stub.FireEvent("PLAYER_TARGET_CHANGED")
        assert(not plays.pulse and not plays.sheen and not plays.marks and not p.sheen:IsShown(), "'Ruhig' bewegt sich trotzdem")
        assert(edgeColor, "'Ruhig' nimmt auch die Kante weg")
        local calmCur = cur
        cur = cur - 5
        stub.FireEvent("UNIT_HEALTH", "nameplate1")
        assert(not plays.flash, "'Ruhig' blitzt")
        cur = calmCur
        isTarget.nameplate1 = nil
        stub.FireEvent("PLAYER_TARGET_CHANGED")
        plays, stops = {}, {}
        p._fxPulse, p._fxSheen, p._fxMarks, p._fxEdge = nil, nil, nil, nil
        edgeColor = nil
        K.Set("nameplates", "motion", "lively")
        isTarget.nameplate1 = true
        stub.FireEvent("PLAYER_TARGET_CHANGED")
        local hc = K.Highlight()
        assert(plays.pulse == 1 and plays.sheen == 1 and plays.marks == 1 and p.sheen:IsShown(), "Ziel bewegt sich nicht")
        assert(edgeColor and edgeColor[1] == hc[1] and edgeColor[3] == hc[3], "Kante nicht in Klassenfarbe")
        stub.FireEvent("PLAYER_TARGET_CHANGED")
        assert(plays.pulse == 1 and plays.sheen == 1, "Animation bei jedem Zielwechsel neu gestartet")
        cur = 30
        stub.FireEvent("UNIT_HEALTH", "nameplate1")
        assert(plays.flash == 1, "Treffer am Ziel blitzt nicht")
        stub.FireEvent("UNIT_MAXHEALTH", "nameplate1")
        assert(plays.flash == 1, "Hoechstwert blitzt wie ein Treffer")
        -- Einzelne Schalter gelten nur mit "Eigene"; "Lebendig" laesst sie liegen.
        K.Set("nameplates", "hitFlash", false)
        cur = 25
        stub.FireEvent("UNIT_HEALTH", "nameplate1")
        assert(plays.flash == 2, "'Lebendig' haelt sich an einen einzelnen Schalter")
        K.Set("nameplates", "motion", "custom")
        cur = 20
        stub.FireEvent("UNIT_HEALTH", "nameplate1")
        assert(plays.flash == 2, "Blitz trotz Schalter")
        K.Set("nameplates", "hitFlash", true)
        isTarget.nameplate1 = nil
        stub.FireEvent("PLAYER_TARGET_CHANGED")
        assert(stops.pulse and stops.sheen and stops.marks and not p.sheen:IsShown(), "Bewegung bleibt ohne Ziel")
        stub.FireEvent("UNIT_HEALTH", "nameplate1")
        assert(plays.flash == 2, "Nicht-Ziel blitzt")
        -- Schalter: kein Glanz.
        K.Set("nameplates", "targetSheen", false)
        Spy(NP.plates["nameplate1"].sheenAnim, "sheen")
        isTarget.nameplate1 = true
        stub.FireEvent("PLAYER_TARGET_CHANGED")
        assert(not NP.plates["nameplate1"].sheen:IsShown(), "Glanz trotz Schalter")
        K.Set("nameplates", "targetSheen", true)
        K.Set("nameplates", "motion", nil)
        isTarget.nameplate1 = nil
        stub.FireEvent("PLAYER_TARGET_CHANGED")
        -- 6.10.1.0: Uebernahme. Eine Mischung von vor 6.10 wird "Eigene",
        -- einmal je Konto; alles aus bleibt "Ruhig", nichts gespeichert auch.
        do
            local ui = K.Root()
            local st = K.Profile().modules.nameplates
            assert(ui.migrated and ui.migrated.npMotion, "Uebernahme laeuft beim Einschalten der Plaketten nicht")
            local function Fresh(off)
                ui.migrated = ui.migrated or {}
                ui.migrated.npMotion = nil
                st.motion = nil
                for _, k in ipairs(NP.MOTION_KEYS) do st[k] = nil end
                for _, k in ipairs(off) do st[k] = false end
            end
            Fresh({ "targetSheen", "hitFlash" })
            assert(NP.MigrateMotion() == "custom" and K.Get("nameplates", "motion") == "custom",
                "Mischung von vor 6.10 nicht als 'Eigene' uebernommen")
            assert(ui.migrated.npMotion, "Uebernahme nicht gemerkt")
            st.motion = nil
            assert(NP.MigrateMotion() == nil and K.Get("nameplates", "motion") == "calm",
                "Uebernahme laeuft zweimal - wer selbst auf 'Ruhig' geht, wird zurueckgestellt")
            Fresh({ "targetPulse", "targetSheen", "hitFlash", "markMotion" })
            assert(NP.MigrateMotion() == nil and K.Get("nameplates", "motion") == "calm", "Alles aus ist 'Ruhig', nicht 'Eigene'")
            Fresh({})
            assert(NP.MigrateMotion() == nil and K.Get("nameplates", "motion") == "calm", "Nichts gespeichert wird 'Eigene'")
            Fresh({ "hitFlash" })
            st.motion = "lively"
            assert(NP.MigrateMotion() == nil and st.motion == "lively", "Gespeicherte Stufe ueberschrieben")
            Fresh({})
        end
        -- Kein Muell: Spur und Balken im Takt.
        p = NP.plates["nameplate1"]
        local tr, hb = stub.NewObject("StatusBar"), stub.NewObject("StatusBar")
        tr.SetValue = function() end
        hb.SetValue = function() end
        local realTrail, realHealth = p.trail, p.health
        p.trail, p.health = tr, hb
        collectgarbage("collect")
        collectgarbage("stop")
        local k0 = collectgarbage("count")
        for i = 1, 50 do
            NP.Trail(p, i)
            NP.SetBar(hb, i, true)
            now = now + 1
            NP.TrailTick()
        end
        local grew = collectgarbage("count") - k0
        collectgarbage("restart")
        assert(grew < 1, string.format("Spur legt je Treffer Muell an: %.1f KB", grew))
        p.trail, p.health = realTrail, realHealth
        p.trail.SetValue, p.health.SetValue = nil, nil
        stub.FireEvent("NAME_PLATE_UNIT_REMOVED", "nameplate1")
        end)
        for k, v in pairs(saved) do _G[k] = v end
        NP.smoothBroken = nil
        assert(okIn, errIn)
    end)
    Check(ok, "Plakette 3.0: Schadensspur, weiche Balken, Ziel atmet (Leuchten, Glanz, Kante, Marken), Treffer blitzt, kein Muell"
        .. (ok and "" or (": " .. tostring(err))))
end

-- 6.3.1.4: Keine verwaiste Plakette. ADDED doppelt (Neuladen) oder eine
-- Plakette des Spiels, die ohne REMOVED an eine andere Einheit geht, liess
-- die alte sichtbar und eingefroren an ihr haengen.
do
    local NP = WeintCodex.UINameplates
    local ok, err = pcall(function()
        stub.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate1")
        local first = NP.plates["nameplate1"]
        stub.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate1")
        local second = NP.plates["nameplate1"]
        assert(first and second, "keine Plakette")
        assert(first == second or not first:IsShown(), "doppeltes ADDED laesst eine alte Plakette stehen")
        -- Dieselbe Plakette des Spiels geht an nameplate7, ohne REMOVED.
        local oldGet = _G.C_NamePlate.GetNamePlateForUnit
        _G.C_NamePlate.GetNamePlateForUnit = function(unit)
            if unit == "nameplate7" or unit == "nameplate1" then return blizzPlate end
            return oldGet(unit)
        end
        stub.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate7")
        assert(NP.plates["nameplate1"] == nil, "alte Einheit haengt noch an der Plakette des Spiels")
        assert(not second:IsShown() or NP.plates["nameplate7"] == second, "verwaiste Plakette sichtbar")
        stub.FireEvent("NAME_PLATE_UNIT_REMOVED", "nameplate7")
        _G.C_NamePlate.GetNamePlateForUnit = oldGet
    end)
    Check(ok, "Plaketten: keine verwaiste Plakette bei doppeltem ADDED oder wiederverwendeter Plakette"
        .. (ok and "" or (": " .. tostring(err))))
end

-- 6.3.1.5: Erfahrungsbalken im Stil der Oberflaeche (Reiter der
-- Aktionsleisten): Werte, erholt, Ruf auf Hoechststufe, nur bei Maus,
-- Tempo erst mit gemessener Erfahrung, Leiste des Spiels unsichtbar.
do
    local XB = WeintCodex.UIXPBar
    local ok, err = pcall(function()
        local saved = { _G.UnitXP, _G.UnitXPMax, _G.GetXPExhaustion, _G.UnitLevel, _G.GetMaxLevelForPlayerExpansion,
                        _G.GetTime, _G.C_Reputation }
        local xp, level, now = 1200, 15, 1000
        _G.UnitXP = function() return xp end
        _G.UnitXPMax = function() return 5000 end
        _G.GetXPExhaustion = function() return 2500 end
        _G.UnitLevel = function() return level end
        _G.GetMaxLevelForPlayerExpansion = function() return 60 end
        _G.GetTime = function() return now end
        assert(K.Module("actionbars").defaults.xpEnabled == true, "Erfahrung haengt nicht an den Aktionsleisten")
        local f = XB.Frame()
        assert(f, "kein Erfahrungsbalken")
        XB.Update()
        assert(XB.Mode() == "xp" and f:IsShown(), "Balken zeigt keine Erfahrung")
        local lo, hi = f.bar:GetMinMaxValues()
        assert(hi == 5000 and f.bar:GetValue() == 1200, "Balkenwerte falsch")
        assert(f.rest:GetValue() == 3700, "erholte Erfahrung nicht dahinter: " .. tostring(f.rest:GetValue()))
        assert(XB.Label():find("24", 1, true), "Anteil fehlt im Text: " .. tostring(XB.Label()))
        -- 6.6.0.1: Erfahrung aus Quests - abgabebereit gruen im Balken,
        -- ohne die Funktion des Clients keine Auskunft (nie 0).
        local oldQL, oldRX = _G.C_QuestLog, _G.GetQuestLogRewardXP
        _G.GetQuestLogRewardXP = nil
        assert(XB.QuestXP() == nil, "Quest-EP ohne Auskunft des Clients")
        local qlog = { { questID = 1 }, { isHeader = true }, { questID = 2 }, { questID = 3 } }
        _G.C_QuestLog = { GetNumQuestLogEntries = function() return #qlog end,
                          GetInfo = function(i) return qlog[i] end,
                          ReadyForTurnIn = function(id) return id ~= 3 end }
        _G.GetQuestLogRewardXP = function(id) return ({ [1] = 800, [2] = 450, [3] = 1000 })[id] end
        local q = XB.QuestXP()
        assert(q.ready == 1250 and q.readyCount == 2 and q.all == 2250 and q.allCount == 3,
            "Quest-EP falsch: " .. tostring(q.ready) .. "/" .. tostring(q.all))
        XB.Update()
        assert(f.quest:IsShown() and f.quest:GetValue() == 1200 + 1250, "gruenes Stueck fehlt: " .. tostring(f.quest:GetValue()))
        -- Reicht es fuer den Aufstieg, laeuft der Balken voll (nicht drueber).
        _G.GetQuestLogRewardXP = function() return 3000 end
        XB.Update()
        assert(f.quest:GetValue() == 5000, "Aufstieg: gruenes Stueck laeuft ueber")
        _G.C_QuestLog, _G.GetQuestLogRewardXP = oldQL, oldRX
        XB.Update()
        assert(not f.quest:IsShown(), "gruenes Stueck ohne Quests")
        -- Tempo: erst nach gemessener Erfahrung und einer Minute.
        XB._session.start, XB._session.gained, XB._session.lastXP, XB._session.lastMax = nil, 0, nil, nil
        XB.Track()
        assert(XB.Rate() == nil, "Tempo ohne gemessene Erfahrung")
        xp, now = 2200, 1000 + 1800
        XB.Track()
        local perHour, eta = XB.Rate()
        assert(perHour == 2000 and math.abs(eta - 2800 / 2000 * 3600) < 0.01, "Tempo falsch: " .. tostring(perHour))
        -- Stufenaufstieg zaehlt den Rest der alten Stufe.
        xp, now = 300, now + 60
        XB.Track()
        assert(XB._session.gained == 1000 + 2800 + 300, "Stufenaufstieg falsch gezaehlt: " .. XB._session.gained)
        -- Hoechststufe: Ruf oder gar nichts - nie ein leerer Balken.
        level = 60
        _G.C_Reputation = { GetWatchedFactionData = function() return nil end }
        XB.Update()
        assert(XB.Mode() == nil and not f:IsShown(), "leerer Balken auf Hoechststufe")
        _G.C_Reputation = { GetWatchedFactionData = function()
            return { name = "Sturmwind", currentReactionThreshold = 3000, nextReactionThreshold = 9000,
                     currentStanding = 4500, reaction = 5 }
        end }
        XB.Update()
        assert(XB.Mode() == "rep" and f:IsShown() and f.bar:GetValue() == 1500, "Ruf auf Hoechststufe fehlt")
        -- Nur bei Maus darueber.
        K.Set("actionbars", "xpShow", "mouseover")
        f.IsMouseOver = function() return false end
        for _ = 1, 10 do XB._fadeStep(nil, 0.1) end
        assert(f:GetAlpha() == 0, "Balken bleibt ohne Maus sichtbar")
        f.IsMouseOver = function() return true end
        for _ = 1, 10 do XB._fadeStep(nil, 0.1) end
        assert(f:GetAlpha() == 1, "Maus holt den Balken nicht zurueck")
        K.Set("actionbars", "xpShow", nil)
        assert(f:GetAlpha() == 1, "zurueck auf Immer: Balken bleibt unsichtbar")
        -- Leiste des Spiels: unsichtbar, keine Maus.
        local game = CreateFrame("Frame", "MainStatusTrackingBarContainer", UIParent)
        local mouse = true
        game.EnableMouse = function(_, v) mouse = v end
        XB.HideGameBars()
        assert(game:GetAlpha() == 0 and mouse == false, "Leiste des Spiels bleibt sichtbar")
        _G.MainStatusTrackingBarContainer = nil
        _G.UnitXP, _G.UnitXPMax, _G.GetXPExhaustion, _G.UnitLevel, _G.GetMaxLevelForPlayerExpansion,
            _G.GetTime, _G.C_Reputation = unpack(saved, 1, 7)
    end)
    Check(ok, "Erfahrungsbalken: Werte, erholt, Tempo, Ruf auf Hoechststufe, nur bei Maus"
        .. (ok and "" or (": " .. tostring(err))))
end

-- 6.3.1.6: Tageszeit in waehlbarer Ecke; LibDBIcon-Knoepfe mit
-- eingefrorener Schicht werden geloest; das Charakterfenster verliert
-- seinen Schmuck, nicht seinen Inhalt; /wcui fenster fasst zusammen.
do
    local ok, err = pcall(function()
        local MM = WeintCodex.UIMinimap
        local cl, mm = _G.MinimapCluster, _G.Minimap
        local diel = CreateFrame("Frame", nil, cl)
        local pt
        diel.SetPoint = function(_, p, rel, rp, x, y) pt = { p, rel, rp, x, y } end
        cl.DielFrame = diel
        K.Set("minimap", "dayCorner", "TOPLEFT")
        MM.LayoutButtons()
        assert(pt and pt[1] == "TOPLEFT" and pt[3] == "TOPLEFT" and pt[4] > 0 and pt[5] < 0, "Tageszeit nicht oben links")
        K.Set("minimap", "dayCorner", nil)
        MM.LayoutButtons()
        assert(pt[1] == "BOTTOMRIGHT" and pt[4] < 0 and pt[5] > 0, "Tageszeit nicht zurueck unten rechts")
        cl.DielFrame = nil
        -- Eingefrorene Schicht loesen, bevor sie gesetzt wird.
        local btn = CreateFrame("Button", "LibDBIcon10_Frozen", mm)
        local unfrozen, strataAfter = nil, nil
        btn.SetFixedFrameStrata = function(_, v) unfrozen = (v == false) end
        btn.SetFrameStrata = function(_, v) if unfrozen then strataAfter = v end end
        local oldKids = mm.GetChildren
        mm.GetChildren = function() return btn end
        local _, flyout = MM.Bag()
        flyout.GetFrameStrata = function() return "MEDIUM" end
        MM.LayoutBag()
        assert(strataAfter == "MEDIUM", "eingefrorene Schicht des Addon-Knopfs nicht geloest")
        mm.GetChildren = oldKids
        _G.LibDBIcon10_Frozen = nil

        -- Charakterfenster: Schmuck (Bg, NineSlice, Inset) weg, Inhalt bleibt.
        local W = WeintCodex.UIWindows
        local cf = CreateFrame("Frame", "TestCharFrame", UIParent)
        cf.Bg = cf:CreateTexture()
        cf.NineSlice = CreateFrame("Frame", nil, cf)
        local edge = cf.NineSlice:CreateTexture()
        cf.NineSlice.GetRegions = function() return edge end
        cf.GetRegions = function() return cf.Bg end
        local slot = CreateFrame("Button", "TestCharFrameHeadSlot", cf)
        local icon = slot:CreateTexture()
        cf.Bg.GetObjectType = function() return "Texture" end
        edge.GetObjectType = function() return "Texture" end
        W.Skin(cf)
        assert(cf.Bg:GetAlpha() == 0 and edge:GetAlpha() == 0, "Holz und Metall bleiben stehen")
        assert(icon:GetAlpha() ~= 0, "Inhalt des Fensters ausgeblendet")
        assert(W.done[cf] and W.done[cf].kachel, "keine Kachel unter dem Fenster")
        -- 6.3.1.7: das Innere nach Atlas; die Buehne des Modells bleibt.
        local statBg, raceBg, title = slot:CreateTexture(), slot:CreateTexture(), slot:CreateTexture()
        statBg.GetAtlas = function() return "UI-Character-Info-Stat-BG" end
        raceBg.GetAtlas = function() return "UI-Character-Info-RaceBG-Overlay" end
        title.GetAtlas = function() return "UI-Character-Info-Title" end
        for _, t in ipairs({ statBg, raceBg, title }) do t.GetObjectType = function() return "Texture" end end
        slot.GetRegions = function() return statBg, raceBg, title end
        cf.GetChildren = function() return slot end
        W.HideByAtlas(cf)
        assert(statBg:GetAlpha() == 0 and title:GetAlpha() == 0, "Holz im Inneren bleibt stehen")
        assert(raceBg:GetAlpha() ~= 0, "Buehne des Modells ausgeblendet")
        assert(W.HidesAtlas("UI-Character-Info-Warrior-BG") and W.HidesAtlas("UI-Character-Info-Druid-BG"),
            "Klassenhintergrund nicht erkannt")
        assert(not W.HidesAtlas("UI-Character-Info-RaceBG") and not W.HidesAtlas(nil), "zu viel erkannt")
        -- 6.3.1.8: Reiter rechts, Balkenrahmen, Zustand fuer /wcui fenster.
        assert(W.HidesAtlas("common-sidetab-selected") and W.HidesAtlas("common-stat-bar-BG")
            and not W.HidesAtlas("common-stat-bar-white"), "Reiter/Balken falsch erkannt")
        local tab = CreateFrame("Button", "CharacterFrameModeTab1", UIParent)
        tab.SelectedTexture = tab:CreateTexture()
        tab.SelectedTexture:Show()
        W.SkinModeTabs()
        _G.CharacterFrameModeTab1 = nil
        local runs = W.stats.runs
        W.Inner()
        assert(W.stats.runs == runs + 1, "Laeufe nicht gezaehlt")
        assert(W.Status():find("Läufe", 1, true), "Zustand fehlt")
        _G.TestCharFrame, _G.TestCharFrameHeadSlot = nil, nil

        -- 6.6.1.4: Gespraeche - schwarze Farbcodes im Text werden hell,
        -- farbige bleiben; Pergament und dunkle Schrift wie im Zauberbuch.
        assert(W.DIALOGS.GossipFrame and W.DIALOGS.QuestFrame, "Gespraech und Quest nicht dabei")
        local lt, n = W.LightCodes("|cff000000Eine schleimige Bedrohung|r und |cffff2020rot|r")
        assert(n == 1 and not lt:find("|cff000000", 1, true) and lt:find("|cffff2020", 1, true), "Farbcodes falsch ersetzt")
        assert(select(2, W.LightCodes("ohne Code")) == 0 and select(2, W.LightCodes(nil)) == 0, "Text ohne Code angefasst")
        local gf = CreateFrame("Frame", "GossipFrame", UIParent)
        local opt = gf:CreateFontString()
        local txt = "|cff000000Ich möchte dieses Gasthaus zu meinem Heimatort machen.|r"
        opt.GetText = function() return txt end
        opt.SetText = function(_, v) txt = v end
        opt.GetObjectType = function() return "FontString" end
        gf.GetRegions = function() return opt end
        W.LightenText(gf, true)
        assert(not txt:find("|cff000000", 1, true), "Gespraechsoption bleibt schwarz")
        _G.GossipFrame = nil

        -- /wcui fenster: ohne Fenster unter der Maus ein Satz.
        local oldFoci = _G.GetMouseFoci
        _G.GetMouseFoci = function() return {} end
        assert(K.InspectWindow()[1]:find("kein Fenster", 1, true), "/wcui fenster ohne Fenster stumm")
        _G.GetMouseFoci = oldFoci
    end)
    Check(ok, "Tageszeit in waehlbarer Ecke, eingefrorene Addon-Knoepfe, Charakterfenster ohne Holz"
        .. (ok and "" or (": " .. tostring(err))))
end

-- 6.3.2.1: Eingabezeile erst mit Enter - nur Deckkraft: unsichtbar, bis
-- geschrieben wird (auch wenn das Spiel sie auf 0,35 setzt); die Infozeile
-- steht so lange darunter.
do
    local ok, err = pcall(function()
        local CH = WeintCodex.UIChat
        local oldHook = _G.hooksecurefunc
        _G.hooksecurefunc = function(obj, name, fn)
            local orig = obj[name]
            obj[name] = function(...) local r = orig(...) fn(...) return r end
        end
        local eb = CreateFrame("EditBox", "TestChatEditBox", UIParent)
        local focus = false
        eb.HasFocus = function() return focus end
        eb:Show()
        CH.HookEdit(eb)
        CH.UpdateEditState()
        assert(eb:GetAlpha() == 0, "Eingabezeile ohne Schreiben sichtbar")
        eb:SetAlpha(0.35)
        assert(eb:GetAlpha() == 0, "Spiel setzt die Zeile wieder halbdurchsichtig")
        focus = true
        CH.UpdateEditState()
        assert(eb:GetAlpha() == 1, "beim Schreiben unsichtbar")
        focus = false
        CH.UpdateEditState()
        assert(eb:GetAlpha() == 0, "nach dem Schreiben sichtbar")
        K.Set("chat", "editOnEnter", false)
        CH.UpdateEditState()
        assert(eb:GetAlpha() == 1, "ausgeschaltet bleibt die Zeile unsichtbar")
        K.Set("chat", "editOnEnter", nil)
        _G.hooksecurefunc = oldHook
        _G.TestChatEditBox = nil
    end)
    Check(ok, "Chat: Eingabezeile erst mit Enter" .. (ok and "" or (": " .. tostring(err))))
end

-- 6.6.0.9: Gruppenrahmen des Spiels im WeintCodex-Stil - nur sie zeigen
-- HoTs, Buffs und Schilde im Kampf. Standard, eigene Kacheln waehlbar.
do
    local ok, err = pcall(function()
        local GG = WeintCodex.UIGameGroup
        assert(GG, "ui/gamegroup.lua nicht geladen")
        assert(K.Module("groupframes").defaults.source == "game", "Standard ist nicht der Rahmen des Spiels")
        -- Ein Rahmen, wie das Spiel ihn anlegt.
        local f = CreateFrame("Button", "CompactPartyFrameMember1", UIParent)
        _G.CompactPartyFrameMember1 = f
        local parts = {
            healthBar = CreateFrame("StatusBar", nil, f), powerBar = CreateFrame("StatusBar", nil, f),
            background = f:CreateTexture(), name = f:CreateFontString(), statusText = f:CreateFontString(),
            horizTopBorder = f:CreateTexture(),
        }
        local icon = f:CreateTexture()
        local coords
        icon.SetTexCoord = function(_, ...) coords = { ... } end
        parts.buffFrames = { { icon = icon } }
        -- Die Teile als Felder, wie das Spiel sie setzt (WeintCodex liest sie nur).
        for k, v in pairs(parts) do rawset(f, k, v) end
        local barTex
        parts.healthBar.SetStatusBarTexture = function(_, t) barTex = t end
        assert(#GG.Frames() >= 1, "Rahmen des Spiels nicht gefunden")
        assert(GG.Style(f), "Stil nicht angewendet")
        assert(barTex == K.BarTexture(), "Lebensbalken ohne WeintCodex-Textur")
        assert(coords and math.abs(coords[1] - 0.08) < 1e-6, "Aurensymbol nicht beschnitten")
        assert(GG.styled[f] and GG.styled[f].border, "kein Rand")
        assert(parts.horizTopBorder:GetAlpha() == 0, "Rahmenlinie des Spiels noch sichtbar")
        -- 6.6.1.1: Name oben mittig wie auf den Kacheln, Ueberschrift weg.
        local namePts = {}
        parts.name.SetPoint = function(_, p) namePts[#namePts + 1] = p end
        local just
        parts.name.SetJustifyH = function(_, j) just = j end
        GG.Style(f)
        assert(namePts[1] == "TOPLEFT" and namePts[2] == "TOPRIGHT" and just == "CENTER", "Name nicht oben mittig")
        local oldCPF = _G.CompactPartyFrame
        local box0 = CreateFrame("Frame", nil, UIParent)
        local title = box0:CreateFontString()
        rawset(box0, "title", title)
        _G.CompactPartyFrame = box0
        GG.StyleContainers()
        assert(title:GetAlpha() == 0, "Ueberschrift 'Gruppe' noch sichtbar")
        _G.CompactPartyFrame = oldCPF
        -- Wiederholbar (das Spiel richtet neu ein): kein zweiter Rand.
        local b1 = GG.styled[f].border
        GG.Style(f)
        assert(GG.styled[f].border == b1, "zweiter Rand beim Neueinrichten")
        -- Klickzauber greift auch auf die Rahmen des Spiels.
        GG.active = true
        local CC = WeintCodex.UIClickCast
        local found = false
        for _, x in ipairs(CC.Frames()) do if x == f then found = true end end
        assert(found, "Klickzauber kennt die Rahmen des Spiels nicht")
        GG.active = nil
        -- 6.6.1.0: Klassenfarbe statt des Gruens des Spiels, nur per Methode.
        local col
        parts.healthBar.SetStatusBarColor = function(_, r, g, b) col = { r, g, b } end
        rawset(f, "unit", "party1")
        local oUP, oUC, oRCC, oCon, oDead = _G.UnitIsPlayer, _G.UnitClass, _G.RAID_CLASS_COLORS, _G.UnitIsConnected, _G.UnitIsDeadOrGhost
        _G.UnitIsPlayer = function() return true end
        _G.UnitClass = function() return "Priesterin", "PRIEST", 5 end
        _G.RAID_CLASS_COLORS = { PRIEST = { r = 1, g = 1, b = 1 } }
        _G.UnitIsConnected = function() return true end
        _G.UnitIsDeadOrGhost = function() return false end
        GG.Color(f)
        assert(col and col[1] == 1 and col[2] == 1 and col[3] == 1, "keine Klassenfarbe")
        assert(rawget(parts.healthBar, "r") == nil, "Feld am Balken des Spiels geschrieben")
        _G.UnitIsDeadOrGhost = function() return true end
        col = nil
        GG.Color(f)
        assert(col == nil, "Tote umgefaerbt (das Spiel zeigt sie grau)")
        _G.UnitIsPlayer, _G.UnitClass, _G.RAID_CLASS_COLORS, _G.UnitIsConnected, _G.UnitIsDeadOrGhost = oUP, oUC, oRCC, oCon, oDead
        -- Anders benannt: im Behaelter des Spiels gefunden.
        local box = CreateFrame("Frame", nil, UIParent)
        local odd = CreateFrame("Button", nil, box)
        rawset(odd, "healthBar", CreateFrame("StatusBar", nil, odd))
        box.GetChildren = function() return odd end
        local oldBox = _G.CompactPartyFrame
        _G.CompactPartyFrame = box
        local seen = false
        for _, x in ipairs(GG.Frames()) do if x == odd then seen = true end end
        assert(seen, "Rahmen im Behaelter nicht gefunden")
        _G.CompactPartyFrame = oldBox
        local lines = table.concat(GG.Inspect(), " | ")
        assert(lines:find("gefunden", 1, true), "/wcui gruppe ohne Auskunft: " .. lines)
        _G.CompactPartyFrameMember1 = nil
        GG.styled[f] = nil
    end)
    Check(ok, "Gruppenrahmen des Spiels: gefunden, im WeintCodex-Stil, Klickzauber, /wcui gruppe"
        .. (ok and "" or (": " .. tostring(err))))
end

-- 6.6.1.1: Einrichtung beim ersten Mal - ein eigenes Layout "WeintCodex"
-- im Bearbeitungsmodus, danach neu laden (wie EllesmereUI).
do
    local ok, err = pcall(function()
        local ES = WeintCodex.UISetup
        assert(ES, "ui/setup.lua nicht geladen")
        local oldEM, oldPM, oldEnum = _G.C_EditMode, _G.EditModePresetLayoutManager, _G.Enum
        local oldCV, oldReset = _G.C_CVar, _G.FCF_ResetChatWindows
        _G.Enum = setmetatable({
            EditModeSystem = { ActionBar = 0, UnitFrame = 3, ChatFrame = 8, Minimap = 2 },
            EditModeActionBarSystemIndices = { MainBar = 1, Bar2 = 2, RightBar1 = 4 },
            EditModeActionBarSetting = { Orientation = 0, HideBarArt = 6 },
            EditModeUnitFrameSystemIndices = { Player = 1, Target = 2, Party = 4, Raid = 5 },
            EditModeUnitFrameSetting = { UseRaidStylePartyFrames = 4, DisplayBorder = 12 },
            EditModeChatFrameSetting = { WidthHundreds = 0, WidthTensAndOnes = 1, HeightHundreds = 2, HeightTensAndOnes = 3 },
            EditModeLayoutType = { Preset = 0, Account = 1, Character = 2 },
        }, { __index = oldEnum })
        local function Sys(system, idx, extra)
            local t = { system = system, systemIndex = idx, settings = {}, isInDefaultPosition = true,
                        anchorInfo = { point = "BOTTOMLEFT", relativeTo = "UIParent", relativePoint = "BOTTOMLEFT", offsetX = 0, offsetY = 0 } }
            for k, v in pairs(extra or {}) do t[k] = v end
            return t
        end
        local modern = { layoutName = "Modern", layoutType = 0, systems = {
            Sys(0, 1), Sys(0, 2), Sys(0, 4), Sys(8, 0), Sys(2, 0),
            Sys(3, 4, { settings = { { setting = 4, value = 0 } } }), Sys(3, 5),
        } }
        _G.EditModePresetLayoutManager = { GetCopyOfPresetLayouts = function() return { modern, { layoutName = "Klassisch", systems = {} } } end }
        -- Das aktive Layout des Spielers stammt von einem anderen Addon:
        -- der Chat steht dort, wo es ihn hinstellte. Seit 6.6.1.3 zaehlt
        -- das nicht mehr - Grundlage ist die Vorlage, jeder Rahmen fest.
        local elle = { layoutName = "EllesmereUI Forever v4", layoutType = 1, systems = {
            Sys(0, 1), Sys(8, 0, { anchorInfo = { point = "TOPLEFT", relativePoint = "TOPLEFT", offsetX = 900, offsetY = -40 } }),
            Sys(3, 4), Sys(3, 5),
        } }
        local stored = { activeLayout = 3, layouts = { elle } }
        local saved, active
        _G.C_EditMode = {
            GetLayouts = function() return stored end,
            SaveLayouts = function(info) saved = info end,
            SetActiveLayout = function(i) active = i end,
        }
        local cvars = { chatStyle = "classic", whisperMode = "popout", lockActionBars = "0" }
        _G.C_CVar = {
            GetCVar = function(n) return cvars[n] end,
            SetCVar = function(n, v) if cvars[n] == nil then error("unbekannt") end cvars[n] = v end,
        }
        local chatReset = 0
        _G.FCF_ResetChatWindows = function() chatReset = chatReset + 1 end
        K.Root().before, K.Root().cvars = nil, nil
        assert(ES.HasLayout() == false, "Layout vor der Einrichtung schon da")
        assert(ES.BaseName() == "Modern", "Grundlage nicht die Vorlage des Spiels")
        local okA, why = ES.Apply()
        assert(okA, "Einrichten schlug fehl: " .. tostring(why))
        local l = saved and saved.layouts[2]
        assert(l and l.layoutName == "WeintCodex" and l.layoutType == 1, "Layout nicht angelegt")
        assert(saved.layouts[1].layoutName == "EllesmereUI Forever v4", "bisheriges Layout ueberschrieben")
        assert(saved.activeLayout == 4 and active == 4, "Layout nicht aktiv (2 Vorlagen + 2)")
        local function Get(system, idx)
            for _, sy in ipairs(l.systems) do if sy.system == system and sy.systemIndex == idx then return sy end end
        end
        local function Setting(sy, id)
            for _, st in ipairs(sy.settings) do if st.setting == id then return st.value end end
        end
        local party = Get(3, 4)
        assert(Setting(party, 4) == 1 and Setting(party, 12) == 0, "Gruppe nicht schlachtzugsartig oder mit Rand")
        local want = K.LAYOUT.gf_party
        assert(party.anchorInfo.point == want.point and party.anchorInfo.offsetX == want.x
            and party.isInDefaultPosition == false, "Gruppe nicht am WeintCodex-Platz")
        assert(Get(3, 5).anchorInfo.relativePoint == K.LAYOUT.gf_raid.relPoint, "Schlachtzug nicht am WeintCodex-Platz")
        -- Jeder Rahmen fest gesetzt, keiner auf dem Standardplatz des Spiels.
        local function Entry(key) for _, e in ipairs(K.GAME_LAYOUT) do if e.key == key then return e end end end
        for _, pair in ipairs({ { 0, 1, "bar1" }, { 0, 2, "bar2" }, { 0, 4, "bar4" }, { 8, 0, "chat" }, { 2, 0, "minimap" } }) do
            local sy, e = Get(pair[1], pair[2]), Entry(pair[3])
            assert(sy.isInDefaultPosition == false and sy.anchorInfo.point == e.point
                and sy.anchorInfo.offsetX == e.x and sy.anchorInfo.offsetY == e.y, e.label .. " nicht am WeintCodex-Platz")
        end
        local chat = Get(8, 0)
        assert(Setting(chat, 0) * 100 + Setting(chat, 1) == K.CHAT_SIZE.w
            and Setting(chat, 2) * 100 + Setting(chat, 3) == K.CHAT_SIZE.h, "Chatgroesse nicht gesetzt")
        assert(Setting(Get(0, 1), 6) == 1 and Setting(Get(0, 4), 0) == 1, "Leisteneinstellungen nicht gesetzt")
        assert(elle.systems[2].anchorInfo.offsetX == 900, "Layout des Spielers veraendert statt kopiert")
        -- Was das Layout der Vorlage nicht traegt, nennt der Bericht.
        local r = ES.report
        assert(r.frames == 7 and #r.missing == #K.GAME_LAYOUT - 7, "Bericht zaehlt die Rahmen falsch: " .. tostring(r.frames))
        -- 6.9.0.0: die Chatreiter gehoeren dem Spieler - nie mehr zuruecksetzen.
        assert(chatReset == 0 and r.chat == nil, "Chatfenster angefasst (eigene Reiter weg)")
        assert(cvars.chatStyle == "im" and cvars.whisperMode == "inline" and cvars.lockActionBars == "1", "Spieleinstellungen nicht gesetzt")
        -- ... und vorher gemerkt, was galt: das Layout und die alten Werte.
        local before = K.Root().before
        assert(before and before.layout and before.layout.name == "EllesmereUI Forever v4", "Layout von vorher nicht gemerkt")
        local rec = K.Root().cvars and K.Root().cvars.chatStyle
        assert(rec and rec.orig == "classic" and rec.set == "im" and rec.owner == "ui", "alter Wert nicht gemerkt")
        assert(r.cvars == 3 and #r.unknownCVars == #ES.CVARS - 3, "unbekannte Einstellungen nicht ehrlich gemeldet")
        -- 6.6.1.4: eigene Rahmen bleiben, wo der Spieler sie hingezogen hat.
        assert(r.own == nil, "eigene Rahmen zurueckgesetzt")
        -- Neu einrichten: wieder auf der Vorlage, nie auf sich selbst.
        local again = { activeLayout = 4, layouts = { elle, l } }
        local b2, n2 = ES.Base(again, _G.EditModePresetLayoutManager.GetCopyOfPresetLayouts())
        assert(b2 == modern and n2 == "Modern", "Neu einrichten baut nicht auf der Vorlage auf")
        -- Ohne Vorlage: das eigene Layout des Spielers, nie "WeintCodex".
        assert(select(2, ES.Base(again, nil)) == "EllesmereUI Forever v4", "ohne Vorlage kein Rueckfall aufs eigene Layout")
        assert(ES.Base({ activeLayout = 3, layouts = { l } }, nil) == nil, "baut auf sich selbst auf")
        -- Pruefen laeuft und nennt das aktive Layout - auch mit Rahmen,
        -- die eine Lage haben (6.6.1.3 brach genau dort ab: fy blieb nil).
        stored = saved
        local chatE = Entry("chat")
        local cf = _G.ChatFrame1 or CreateFrame("Frame", "ChatFrame1", UIParent)
        local oldCF = {}
        for _, m in ipairs({ "GetLeft", "GetRight", "GetTop", "GetBottom", "GetWidth", "GetEffectiveScale" }) do oldCF[m] = cf[m] end
        cf.GetLeft = function() return chatE.x end
        cf.GetBottom = function() return chatE.y end
        cf.GetRight = function() return chatE.x + 400 end
        cf.GetTop = function() return chatE.y + 160 end
        cf.GetWidth = function() return 400 end
        cf.GetEffectiveScale = function() return 1 end
        local oldUI = {}
        for _, m in ipairs({ "GetLeft", "GetRight", "GetTop", "GetBottom", "GetEffectiveScale" }) do oldUI[m] = UIParent[m] end
        UIParent.GetLeft = function() return 0 end
        UIParent.GetBottom = function() return 0 end
        UIParent.GetRight = function() return 1366 end
        UIParent.GetTop = function() return 768 end
        UIParent.GetEffectiveScale = function() return 1 end
        local okC, lines = pcall(ES.Check)
        assert(okC, "Pruefung bricht ab: " .. tostring(lines))
        assert(lines[1]:find("WeintCodex", 1, true) and lines[2]:find("Rahmen am Platz", 1, true), "Pruefung sagt nichts")
        assert(tonumber(lines[2]:match("^(%d+) Rahmen am Platz")) >= 1, "Chat am Platz nicht erkannt")
        cf.GetLeft = function() return chatE.x + 50 end
        cf.GetRight = function() return chatE.x + 450 end
        lines = ES.Check()
        local named = false
        for _, line in ipairs(lines) do if line:find("^Chat: soll") then named = true end end
        assert(named, "verschobener Chat nicht genannt")
        for m, fn in pairs(oldCF) do cf[m] = fn end
        for m, fn in pairs(oldUI) do UIParent[m] = fn end

        -- 6.6.1.4: der Abklingzeitmanager kommt aus dem bisherigen Layout.
        _G.Enum.EditModeSystem.CooldownViewer = 20
        _G.Enum.EditModeCooldownViewerSystemIndices = { Essential = 0, Utility = 1, BuffIcon = 2, BuffBar = 3 }
        _G.Enum.EditModeCooldownViewerSetting = { IconSize = 3, VisibleSetting = 6 }
        _G.Enum.CooldownViewerVisibleSetting = { Always = 0, InCombat = 1, Hidden = 2 }
        local oldDI = _G.EditModeSettingDisplayInfoManager
        _G.EditModeSettingDisplayInfoManager = { systemSettingDisplayInfo = {
            [20] = { { setting = 3, minValue = 50, maxValue = 200, stepSize = 10 } } } }
        table.insert(modern.systems, Sys(20, 0))
        table.insert(modern.systems, Sys(20, 2))
        table.insert(modern.systems, Sys(20, 3))
        local mine = { point = "TOPLEFT", relativeTo = "UIParent", relativePoint = "TOPLEFT", offsetX = 111, offsetY = -222 }
        table.insert(elle.systems, Sys(20, 0, { anchorInfo = mine, isInDefaultPosition = false,
            settings = { { setting = 1, value = 7 } } }))
        table.insert(elle.systems, Sys(20, 3, { anchorInfo = mine }))
        table.insert(elle.systems, Sys(20, 2, { anchorInfo = mine }))   -- Buff-Symbole: bleiben am Spieler
        stored = { activeLayout = 3, layouts = { elle } }
        assert(ES.Apply(), "Einrichten mit Abklingzeitmanager schlug fehl")
        local wc = saved.layouts[2]
        local ess
        for _, sy in ipairs(wc.systems) do if sy.system == 20 and sy.systemIndex == 0 then ess = sy end end
        assert(ess.anchorInfo.offsetX == 111, "Platz des Abklingzeitmanagers nicht uebernommen")
        -- 6.6.1.5: nur der Platz kommt mit; Groesse 80 % (Regler 50-200 in
        -- Zehnern -> 3), die Buff-Anzeigen des Spiels aus.
        local function SetOf(sy, id) for _, st in ipairs(sy.settings) do if st.setting == id then return st.value end end end
        assert(SetOf(ess, 1) == nil and SetOf(ess, 3) == 3, "Groesse nicht umgerechnet oder fremde Einstellung mitgekommen")
        local bi
        for _, sy in ipairs(wc.systems) do if sy.system == 20 and sy.systemIndex == 2 then bi = sy end end
        -- 6.6.1.7: Buff-Symbole sichtbar, klein, ueber dem Spieler, nicht aus
        -- dem frueheren Layout; die Buffleisten bleiben aus.
        local bb
        for _, sy in ipairs(wc.systems) do if sy.system == 20 and sy.systemIndex == 3 then bb = sy end end
        assert(SetOf(bi, 6) == 0 and SetOf(bi, 3) == 1 and bi.anchorInfo.offsetX == K.LAYOUT.uf_player.x,
            "Buff-Symbole nicht klein ueber dem Spieler")
        assert(SetOf(bb, 6) == 2, "Buffleisten des Spiels nicht aus")
        assert(ES.report.kept == 2 and ES.report.keptFrom == "EllesmereUI Forever v4", "Uebernahme nicht gemeldet")
        assert(ES.RawValue(20, 3, 500) == nil and ES.RawValue(99, 3, 80) == nil, "Wert ausserhalb des Reglers gesetzt")
        -- 6.6.3.4: Hoehe der Questliste - aus der Bildschirmhoehe, auf den
        -- Regler begrenzt.
        assert(ES.RawValue(20, 3, 500, true) == 15 and ES.RawValue(20, 3, 10, true) == 0, "Begrenzen auf den Regler")
        local oldGH = UIParent.GetHeight
        UIParent.GetHeight = function() return 1080 end
        assert(K.TrackerHeight() == 1080 - 305 - K.TRACKER_BOTTOM, "Hoehe der Questliste: " .. tostring(K.TrackerHeight()))
        UIParent.GetHeight = oldGH
        local tracker = Entry("tracker")
        assert(tracker.display and tracker.display.Height == K.TrackerHeight and tracker.clamp, "Questliste ohne Hoehe im Layout")
        _G.EditModeSettingDisplayInfoManager = oldDI
        -- Erneut, waehrend "WeintCodex" aktiv ist und nie verschoben wurde:
        -- wieder aus dem Layout davor. Hat der Spieler verschoben: seins.
        for _, key in ipairs({ "essential", "utility", "buffbar" }) do
            local e = Entry(key)
            for _, sy in ipairs(wc.systems) do
                if sy.system == 20 and sy.systemIndex == _G.Enum.EditModeCooldownViewerSystemIndices[e.idx] then
                    sy.anchorInfo = { point = e.point, relativeTo = "UIParent", relativePoint = e.relPoint, offsetX = e.x, offsetY = e.y }
                end
            end
        end
        assert(ES.PersonalSource({ activeLayout = 4, layouts = { elle, wc } }, { modern, {} }) == elle, "unberuehrt: nicht aus dem Layout davor")
        ess.anchorInfo = { point = "CENTER", offsetX = 5, offsetY = 5 }
        assert(ES.PersonalSource({ activeLayout = 4, layouts = { elle, wc } }, { modern, {} }) == wc, "verschoben: nicht die eigenen Plaetze")
        stored = saved
        _G.C_CVar, _G.FCF_ResetChatWindows = oldCV, oldReset
        -- Danach gibt es das Layout - es wird nicht mehr gefragt.
        assert(ES.HasLayout() == true, "Layout danach nicht erkannt")
        ES._ResetAsked()
        ES.MaybeAsk()
        assert(not ES.IsShown(), "gefragt, obwohl eingerichtet")
        -- Ohne Layout: das Fenster fragt; "Einrichten" fuehrt zu "neu laden".
        stored = { activeLayout = 1, layouts = {} }
        ES._ResetAsked()
        ES.MaybeAsk()
        assert(ES.IsShown() and ES.Button("apply") and ES.Button("later"), "Einrichtungsfenster nicht gezeigt")
        assert(ES.BodyText():find("Chatreiter", 1, true) and not ES.BodyText():find("Reiter verschwinden", 1, true),
            "Frage sagt nicht, dass die Chatreiter bleiben")
        ES.Button("apply"):Click()
        assert(ES.Button("reload") and ES.BodyText():find("Neuladen", 1, true), "nach dem Einrichten kein Neuladen angeboten")
        assert(ES.BodyText():find("Nicht im Layout", 1, true), "fehlende Rahmen verschwiegen")
        -- Im Kampf nie; ohne C_EditMode ehrlich gescheitert.
        local oldCombat = _G.InCombatLockdown
        _G.InCombatLockdown = function() return true end
        assert(select(2, ES.Apply()) == "im Kampf", "im Kampf eingerichtet")
        _G.InCombatLockdown = oldCombat
        _G.C_EditMode = nil
        local okF, whyF = ES.Apply()
        assert(not okF and tostring(whyF):find("C_EditMode", 1, true), "ohne C_EditMode kein Grund")
        ES.Show()
        ES.Button("apply"):Click()
        assert(ES.Button("close") and ES.BodyText():find("von Hand", 1, true), "Scheitern ohne Handgriffe")
        ES.Button("close"):Click()
        _G.C_EditMode, _G.EditModePresetLayoutManager, _G.Enum = oldEM, oldPM, oldEnum
    end)
    Check(ok, "Einrichtung: alle Rahmen des Spiels fest auf der Vorlage, Chatreiter bleiben, Spieleinstellungen gemerkt, danach neu laden"
        .. (ok and "" or (": " .. tostring(err))))
end

-- 6.9.0.0: DEIN PROFIL BLEIBT DEINS. Einschalten merkt das Layout von
-- vorher (einmal) und setzt "WeintCodex" aktiv; Ausschalten gibt das
-- gemerkte zurueck - nur, wenn noch "WeintCodex" aktiv ist - und die
-- Spieleinstellungen, aber nur, wo noch UNSER Wert steht.
do
    local PF = WeintCodex.UIProfile
    local ui = K.Root()
    local oldEM, oldPM, oldCV = _G.C_EditMode, _G.EditModePresetLayoutManager, _G.C_CVar
    local oldEnabled = ui.enabled
    local ok, err = pcall(function()
        assert(PF, "ui/profile.lua nicht geladen")
        _G.EditModePresetLayoutManager = { GetCopyOfPresetLayouts = function()
            return { { layoutName = "Modern" }, { layoutName = "Klassisch" } } end }
        local stored = { activeLayout = 3, layouts = { { layoutName = "Mein Layout" }, { layoutName = "WeintCodex" } } }
        local switches = 0
        _G.C_EditMode = {
            GetLayouts = function() return stored end,
            SetActiveLayout = function(i) stored.activeLayout = i switches = switches + 1 end,
        }
        local cvars = { chatStyle = "classic", whisperMode = "popout", damageMeterEnabled = "1" }
        _G.C_CVar = {
            GetCVar = function(n) return cvars[n] end,
            SetCVar = function(n, v) if cvars[n] == nil then error("unbekannt") end cvars[n] = v end,
        }
        ui.before, ui.cvars, ui.enabled = nil, nil, false

        -- Sagt der Client nichts, wird nichts gemerkt (sonst versperrte ein
        -- leeres "vorher" das echte).
        local em = _G.C_EditMode
        _G.C_EditMode = nil
        assert(PF.Remember() == false and ui.before == nil, "ohne Client ein leeres Vorher gemerkt")
        _G.C_EditMode = em

        -- Einschalten: gemerkt, dann das eigene Layout aktiv.
        K.SetUIEnabled(true)
        assert(ui.before and ui.before.layout.name == "Mein Layout", "Layout von vorher nicht gemerkt")
        assert(stored.activeLayout == 4, "Layout WeintCodex nicht aktiv gesetzt")
        -- Ein zweites Einschalten ueberschreibt das Original nicht.
        assert(PF.Remember() == false and ui.before.layout.name == "Mein Layout", "Original mit WeintCodex ueberschrieben")

        -- Spieleinstellungen: der allererste Wert zaehlt.
        assert(PF.SetCVar("chatStyle", "im", "ui") and PF.SetCVar("chatStyle", "im2", "ui"), "Einstellung nicht gesetzt")
        assert(ui.cvars.chatStyle.orig == "classic" and ui.cvars.chatStyle.set == "im2", "Original ueberschrieben")
        assert(PF.SetCVar("whisperMode", "inline", "ui"), "Fluestern nicht gesetzt")
        assert(PF.SetCVar("gibtsNicht", "1", "ui") == false and ui.cvars.gibtsNicht == nil, "unbekannte Einstellung gemerkt")
        -- Der Spieler stellt selbst um: seine Wahl gilt.
        cvars.whisperMode = "selbst"

        -- Ausschalten: Layout und eigener Wert zurueck, fremder bleibt.
        K.SetUIEnabled(false)
        assert(stored.activeLayout == 3, "Layout von vorher nicht zurueck")
        assert(cvars.chatStyle == "classic", "Spieleinstellung nicht zurueckgegeben")
        assert(cvars.whisperMode == "selbst", "Wahl des Spielers ueberschrieben")
        assert(ui.before == nil and ui.cvars.chatStyle == nil and ui.cvars.whisperMode == nil, "Merkliste nicht geleert")

        -- Selbst umgestellt (Vorlage aktiv): Ausschalten fasst das Layout nicht an.
        K.SetUIEnabled(true)
        stored.activeLayout = 1
        local n = switches
        assert(PF.Leave() == "kept" and stored.activeLayout == 1 and switches == n, "eigene Wahl des Spielers ueberstimmt")

        -- Nichts gemerkt (Oberflaeche vor 6.9.0.0): erstes eigenes Layout,
        -- ehrlich als Ersatz gemeldet - nie "WeintCodex".
        stored.activeLayout, ui.before = 4, nil
        local how, now = PF.Leave()
        assert(how == "fallback" and now.name == "Mein Layout" and stored.activeLayout == 3, "kein ehrlicher Ersatz: " .. tostring(how))
        -- Ohne eigenes Layout: die erste Vorlage des Spiels.
        stored.layouts = { { layoutName = "WeintCodex" } }
        stored.activeLayout = 3
        how, now = PF.Leave()
        assert(how == "fallback" and now.preset == 1 and stored.activeLayout == 1, "keine Vorlage als Ersatz")

        -- Besitzer Modul: die Anzeige des Spiels kommt zurueck, sobald die
        -- Schadensanzeige aus ist.
        ui.enabled = true
        PF.SetCVar("damageMeterEnabled", "0", "damagemeter")
        assert(PF.Sweep() == 0 and cvars.damageMeterEnabled == "0", "laufender Besitzer verliert seine Einstellung")
        K.Profile().modules.damagemeter = K.Profile().modules.damagemeter or {}
        K.Profile().modules.damagemeter.enabled = false
        assert(PF.Sweep() == 1 and cvars.damageMeterEnabled == "1", "Anzeige des Spiels nicht zurueck")
        K.Profile().modules.damagemeter.enabled = nil
    end)
    _G.C_EditMode, _G.EditModePresetLayoutManager, _G.C_CVar = oldEM, oldPM, oldCV
    ui.before, ui.cvars, ui.enabled = nil, nil, oldEnabled
    Check(ok, "Profil: Layout von vorher gemerkt und zurueck, Spieleinstellungen nur eigene zurueck, ehrlicher Ersatz"
        .. (ok and "" or (": " .. tostring(err))))
end

-- 6.9.0.0: OHNE OBERFLAECHE. Komfort laeuft, Oberflaeche nicht; was ein
-- Fenster zeigt (Schadensanzeige, Erinnerungen), kommt ohne Oberflaeche
-- erst, wenn man es waehlt. Klickzauber gelten dann auf den Rahmen des
-- Spiels.
do
    local ui = K.Root()
    local oldEnabled = ui.enabled
    local CC = WeintCodex.UIClickCast
    local gf = K.Module("groupframes")
    local oldActive = gf._active
    local ok, err = pcall(function()
        ui.enabled = false
        for _, key in ipairs({ "damagemeter", "reminders", "questarrow", "comfort" }) do
            assert(K.Module(key).group == "qol", key .. " haengt an der Oberflaeche")
        end
        for _, key in ipairs({ "nameplates", "unitframes", "groupframes", "actionbars", "minimap", "chat", "bags", "questtracker" }) do
            assert(K.Module(key).group == "ui" and not K.WantsActive(key), key .. " liefe ohne Oberflaeche")
        end
        assert(K.WantsActive("questarrow") and K.WantsActive("comfort"), "Komfort laeuft ohne Oberflaeche nicht")
        assert(not K.WantsActive("damagemeter") and not K.WantsActive("reminders"),
            "ohne Oberflaeche erscheint ein Fenster, das niemand gewaehlt hat")
        K.SetModuleEnabled("damagemeter", true)
        assert(K.WantsActive("damagemeter") and K.ReloadPending(), "Schadensanzeige ohne Oberflaeche nicht waehlbar")
        ui.enabled = true
        assert(K.WantsActive("reminders"), "mit Oberflaeche ist das Komplettpaket nicht an")
        K.Profile().modules.damagemeter.enabled = nil
        -- Klickzauber: Rahmen des Spiels, wenn die eigenen Gruppenrahmen
        -- nicht laufen; mit eigenen Kacheln nicht (die des Spiels sind weg).
        gf._active = false
        assert(CC.GameFrames(), "ohne Gruppenrahmen von WeintCodex keine Klickzauber auf denen des Spiels")
        gf._active = true
        local GG = WeintCodex.UIGameGroup
        local was = GG.active
        GG.active = false
        assert(not CC.GameFrames(), "Klickzauber auf versteckten Rahmen des Spiels")
        GG.active = was
        -- Komfort aus: keine Belegung.
        local seen
        local oldApplyTo, oldFrames = CC.ApplyTo, CC.Frames
        local f = CreateFrame("Button")
        CC.Frames = function() return { f } end
        CC.ApplyTo = function(x, list) if x == f then seen = #list end end
        local oldBind = CC.Effective
        CC.Effective = function() return { { button = 1, mod = "shift-", action = "target" } } end
        K.Profile().modules.comfort = K.Profile().modules.comfort or {}
        K.Profile().modules.comfort.enabled = false
        CC.Apply()
        assert(seen == 0, "Komfort aus, Klickzauber gelten trotzdem")
        K.Profile().modules.comfort.enabled = nil
        CC.Apply()
        assert(seen == 1, "Komfort an, Klickzauber gelten nicht")
        CC.ApplyTo, CC.Frames, CC.Effective = oldApplyTo, oldFrames, oldBind
    end)
    ui.enabled, gf._active = oldEnabled, oldActive
    Check(ok, "Ohne Oberflaeche: Komfort ja, Oberflaeche nein, Fenster nur gewaehlt, Klickzauber auf Rahmen des Spiels"
        .. (ok and "" or (": " .. tostring(err))))
end

-- 6.6.0.7: Klickzauber - Maustaste + Zusatztaste wirkt einen Zauber auf
-- die Einheit des Rahmens. Nur Klick-Attribute, je Klasse gespeichert.
do
    local ok, err = pcall(function()
        local CC = WeintCodex.UIClickCast
        assert(CC, "ui/clickcast.lua nicht geladen")
        -- Seit 6.9.0.0 im Komfort; die Einstellungen bleiben bei den
        -- Gruppenrahmen (store), dort stehen auch die Standardwerte.
        local page = false
        for _, pg in ipairs(K.Module("comfort").pages) do
            if pg.key == "klickzauber" and pg.store == "groupframes" then page = true end
        end
        assert(page, "kein Reiter Klickzauber im Komfort (Speicher der Gruppenrahmen)")
        assert(K.Get("groupframes", "clickTooltip") ~= nil, "Standardwerte der Klickzauber fehlen")
        local oldClass, oldCombat, oldFrames = _G.UnitClass, _G.InCombatLockdown, CC.Frames
        _G.UnitClass = function() return "Priesterin", "PRIEST", 5 end
        _G.InCombatLockdown = function() return false end
        local f1, f2 = CreateFrame("Button"), CreateFrame("Button")
        f1:SetAttribute("*type1", "target")
        local frames = { f1, f2 }
        CC.Frames = function() return frames end
        CC.SetBindings({})
        CC.draft.button, CC.draft.mod = 1, "shift-"
        assert(CC.Pick("spell", "Blitzheilung"), "Belegung nicht angelegt")
        CC.draft.button, CC.draft.mod = 2, ""
        assert(CC.Pick("spell", "Erneuerung"), "zweite Belegung nicht angelegt")
        for _, f in ipairs(frames) do
            assert(f:GetAttribute("shift-type1") == "spell" and f:GetAttribute("shift-spell1") == "Blitzheilung",
                "Umschalt + Links nicht belegt")
            assert(f:GetAttribute("type2") == "spell" and f:GetAttribute("spell2") == "Erneuerung",
                "Rechts nicht belegt")
        end
        assert(f1:GetAttribute("*type1") == "target", "Grundeinstellung des Rahmens angefasst")
        -- Dieselbe Taste ersetzt, Leerer Zauber wird abgelehnt.
        CC.draft.button, CC.draft.mod = 1, "shift-"
        CC.Pick("spell", "Heilen")
        assert(#CC.Bindings() == 2 and f1:GetAttribute("shift-spell1") == "Heilen", "gleiche Taste nicht ersetzt")
        assert(CC.Current() and CC.Current().spell == "Heilen", "Belegung der gewaehlten Taste nicht erkannt")
        assert(not CC.Pick("spell", ""), "Belegung ohne Zauber angelegt")
        -- Tooltip-Zeilen, Tastentext.
        local lines = CC.TooltipLines()
        assert(#lines == 2 and lines[1][1] == "Umschalt + Links" and lines[1][2] == "Heilen", "Tooltip-Zeilen falsch")
        -- Entfernen raeumt die Attribute weg; "Rechts" faellt aufs Menue zurueck.
        CC.Remove(2)
        assert(f1:GetAttribute("type2") == nil and f1:GetAttribute("spell2") == nil, "entfernte Belegung haengt noch")
        -- Je Klasse: der Krieger sieht die Belegung der Priesterin nicht.
        _G.UnitClass = function() return "Krieger", "WARRIOR", 1 end
        assert(#CC.Bindings() == 0, "Belegung einer anderen Klasse gilt")
        CC.Apply()
        assert(f1:GetAttribute("shift-type1") == nil, "Belegung der Priesterin am Krieger")
        _G.UnitClass = function() return "Priesterin", "PRIEST", 5 end
        -- Im Kampf: nichts anfassen, danach nachholen.
        _G.InCombatLockdown = function() return true end
        assert(CC.Apply() == false, "im Kampf Attribute gesetzt")
        assert(f1:GetAttribute("shift-type1") == nil, "im Kampf Attribute gesetzt")
        _G.InCombatLockdown = function() return false end
        CC.Apply()
        assert(f1:GetAttribute("shift-spell1") == "Heilen", "nach dem Kampf nicht nachgeholt")
        -- Zauberbuch: je Name einmal (Raenge), ohne passive, ohne Gilde;
        -- "nur hilfreiche" fragt den Client, "weiss nicht" bleibt drin.
        local oldSB, oldEnum, oldCS = _G.C_SpellBook, _G.Enum, _G.C_Spell
        _G.Enum = setmetatable({ SpellBookSpellBank = { Player = 0 }, SpellBookItemType = { Spell = 1, Flyout = 4 } },
            { __index = oldEnum })
        local book = {
            [1] = { spellID = 2050, name = "Geringes Heilen", iconID = 1, itemType = 1, subName = "Rang 1" },
            [2] = { spellID = 2052, name = "Geringes Heilen", iconID = 1, itemType = 1, subName = "Rang 2" },
            [3] = { spellID = 585, name = "Göttliche Pein", iconID = 2, itemType = 1 },
            [4] = { spellID = 9, name = "Passiv", iconID = 3, itemType = 1, isPassive = true },
            [5] = { spellID = 10, name = "Flugmenue", iconID = 4, itemType = 4 },
            [6] = { spellID = 11, name = "Gildenzauber", iconID = 5, itemType = 1 },
        }
        _G.C_SpellBook = {
            GetNumSpellBookSkillLines = function() return 2 end,
            GetSpellBookSkillLineInfo = function(i)
                if i == 1 then return { itemIndexOffset = 0, numSpellBookItems = 5 } end
                return { itemIndexOffset = 5, numSpellBookItems = 1, isGuild = true }
            end,
            GetSpellBookItemInfo = function(slot) return book[slot] end,
        }
        _G.C_Spell = { IsSpellHelpful = function(id) return id ~= 585 end }
        local all = CC.Spellbook(false)
        assert(#all == 2 and all[1].name == "Geringes Heilen" and all[2].name == "Göttliche Pein",
            "Zauberbuch falsch gelesen: " .. #all)
        assert(#all[1].ranks == 2 and all[1].ranks[1].rank == "Rang 1" and all[1].id == 2052,
            "Raenge nicht gesammelt oder id nicht die des hoechsten")
        assert(#all[2].ranks == 0 and CC.RankNumber("Rassenfähigkeit") == nil and CC.RankNumber("Rang 12") == 12,
            "Untertitel falsch als Rang gelesen")
        local helpful = CC.Spellbook(true)
        assert(#helpful == 1 and helpful[1].name == "Geringes Heilen", "Pein als hilfreich gelistet")
        _G.C_Spell = {}
        assert(#CC.Spellbook(true) == 2, "ohne Antwort des Clients Zauber versteckt")
        -- Die Tafel: Klick auf ein Symbol legt den Zauber auf die Taste.
        local picker = CC.BuildPicker(UIParent, 500)
        picker.Sync()
        assert(picker.tiles[1].entry.action == "target" and picker.tiles[3].entry.name == "Geringes Heilen",
            "Tafel ohne Ziel/Menue oder Zauber")
        -- Raenge: der Klick oeffnet die Liste am Symbol, die Wahl legt den
        -- Rang ("Name(Rang 1)"); "Hoechster" legt nur den Namen.
        local oldOpen, menu = WeintCodex.OpenDropMenu, nil
        WeintCodex.OpenDropMenu = function(owner, items, current, onPick)
            menu = { owner = owner, items = items, current = current, pick = onPick }
        end
        CC.draft.button, CC.draft.mod = 3, "alt-"
        picker.tiles[3]:Click()
        assert(menu and menu.owner == picker.tiles[3] and #menu.items == 3 and menu.items[2].value == "Rang 1"
            and menu.current == nil, "Rangliste oeffnet nicht am Symbol")
        assert(f1:GetAttribute("alt-type3") == nil, "Taste belegt, bevor ein Rang gewaehlt ist")
        menu.pick("")
        assert(f1:GetAttribute("alt-type3") == "spell" and f1:GetAttribute("alt-spell3") == "Geringes Heilen",
            "Klick in der Tafel belegt die Taste nicht")
        picker.Sync()
        assert(picker.tiles[3].ring.top:IsShown() and not picker.tiles[4].ring.top:IsShown(), "Belegung in der Tafel nicht markiert")
        menu = nil
        picker.tiles[3]:Click()
        assert(menu.current == "", "Hoechster Rang in der Liste nicht markiert")
        menu.pick("Rang 1")
        assert(f1:GetAttribute("alt-spell3") == "Geringes Heilen(Rang 1)", "Rang nicht ins Attribut")
        assert(CC.ActionText(CC.Current()) == "Geringes Heilen (Rang 1)", "Rang nicht genannt")
        menu = nil
        picker.tiles[3]:Click()
        assert(menu.current == "Rang 1", "gewaehlter Rang in der Liste nicht markiert")
        menu.pick("")
        assert(f1:GetAttribute("alt-spell3") == "Geringes Heilen" and CC.Current().rank == nil, "zurueck auf hoechsten geht nicht")
        -- Ein Rang: keine Liste, sofort gelegt.
        menu = nil
        picker.tiles[4]:Click()
        assert(menu == nil and f1:GetAttribute("alt-spell3") == "Göttliche Pein", "Zauber ohne Raenge fragt nach")
        WeintCodex.OpenDropMenu = oldOpen
        picker.tiles[1]:Click()
        assert(f1:GetAttribute("alt-type3") == "target" and f1:GetAttribute("alt-spell3") == nil, "Ziel waehlen nicht gelegt")
        CC.Remove(#CC.Bindings())
        _G.C_SpellBook, _G.Enum, _G.C_Spell = oldSB, oldEnum, oldCS
        -- "Standard" der Gruppenrahmen loescht die Zauber nicht.
        K.ResetModule("groupframes")
        assert(#CC.Bindings() == 1, "Standard der Gruppenrahmen loescht die Belegung")
        CC.SetBindings({})
        K.Set("clickcast", "bindings", nil)
        CC.Frames = oldFrames
        CC.Apply()
        _G.UnitClass, _G.InCombatLockdown = oldClass, oldCombat
    end)
    Check(ok, "Klickzauber: Taste + Zauber an die Rahmen, ersetzen, entfernen, je Klasse, Kampfsperre"
        .. (ok and "" or (": " .. tostring(err))))
end

-- 6.4.0.0: Erinnerungen - Regeln, Vorschlaege, fehlende Buffs, Waffe,
-- Begleiter, Procs, Abklingzeiten, Regel-Editor.
do
    local ok, err = pcall(function()
        local R = WeintCodex.UIReminders
        local saved = { _G.UnitClass, _G.C_UnitAuras, _G.C_Spell, _G.GetWeaponEnchantInfo,
                        _G.GetInventoryItemID, _G.C_Item, _G.UnitExists, _G.InCombatLockdown, _G.issecretvalue }
        -- Vorschlaege ohne Zauber-ID.
        assert(#R.Suggestions("ROGUE") == 2 and R.Suggestions("ROGUE")[1].kind == "weapon", "Schurke ohne Waffengift-Vorschlag")
        assert(#R.Suggestions("HUNTER") == 3 and R.Suggestions("HUNTER")[1].kind == "pet"
            and R.Suggestions("HUNTER")[2].kind == "ammo" and R.Suggestions("HUNTER")[3].kind == "happy",
            "Jaeger ohne Begleiter-, Munitions- und Laune-Vorschlag")
        assert(#R.Suggestions("WARLOCK") == 1, "Hexenmeister mit Laune-Vorschlag (Daemonen haben keine)")
        assert(#R.Suggestions("WARRIOR") == 0, "Vorschlag mit geratener Zauber-ID")
        -- Ohne Angabe: die Klasse des Spielers (zweiter Rueckgabewert).
        local oldClass = _G.UnitClass
        _G.UnitClass = function() return "Schurkin", "ROGUE", 4 end
        assert(#R.Suggestions() == 2, "Klasse des Spielers nicht erkannt")
        _G.UnitClass = oldClass

        -- 6.4.0.2: "Für meine Klasse" ergaenzt, statt eigene Regeln zu loeschen.
        R.SetRules({ { kind = "buff", spell = "Schlachtruf" } })
        local added, total = R.AddSuggestions("WARRIOR")
        assert(added == 0 and total == 0 and #R.Rules() == 1, "Vorschlaege loeschen eigene Regeln (Krieger)")
        added = R.AddSuggestions("ROGUE")
        assert(added == 2 and #R.Rules() == 3 and R.Rules()[1].spell == "Schlachtruf", "Vorschlaege nicht ergaenzt")
        assert(R.AddSuggestions("ROGUE") == 0 and #R.Rules() == 3, "Vorschlaege doppelt ergaenzt")

        -- Zauber aufloesen: Name oder ID.
        _G.C_Spell = {
            GetSpellInfo = function(k)
                if k == "Kampfschrei" or k == 6673 then return { name = "Kampfschrei", spellID = 6673, iconID = 132333 } end
                if k == "Blutrausch" or k == 2687 then return { name = "Blutrausch", spellID = 2687, iconID = 132277 } end
                return nil
            end,
            GetSpellCooldown = function() return { startTime = 100, duration = 60, isOnGCD = false } end,
        }
        local sp = R.Resolve("6673")
        assert(sp and sp.id == 6673 and sp.name == "Kampfschrei", "ID nicht aufgeloest")
        assert(R.Resolve("Unbekannt").id == nil, "Unbekannter Zauber bekommt eine ID")

        -- Regeln setzen: Buff fehlt, Waffe, Begleiter, Proc, Abklingzeit.
        R.SetRules({ { kind = "buff", spell = "Kampfschrei" }, { kind = "weapon", hand = "main", class = R.ALL }, { kind = "pet", class = R.ALL },
                     { kind = "proc", spell = "Kampfschrei" }, { kind = "cooldown", spell = "Blutrausch" } })
        local hasBuff = false
        _G.C_UnitAuras = { GetPlayerAuraBySpellID = function(id)
            if hasBuff and id == 6673 then return { icon = 132333, applications = 0, duration = 120, expirationTime = 200 } end
            return nil
        end, GetAuraDataBySpellName = function() return nil end }
        _G.GetInventoryItemID = function() return 1234 end
        _G.C_Item = { GetItemInfoInstant = function() return 1234, "Waffe", "Schwert", "INVTYPE_WEAPON", 1, 2, 7 end }
        local enchanted, expMs = false, 0
        _G.GetWeaponEnchantInfo = function() return enchanted, expMs, 0, 0, false, 0, 0, 0 end
        local pet = true
        _G.UnitExists = function(u) if u == "pet" then return pet end return true end
        _G.InCombatLockdown = function() return false end

        local function texts()
            local t = {}
            for _, a in ipairs(R.Active()) do t[#t + 1] = a.text end
            return table.concat(t, " | ")
        end
        R.Check({ kind = "pet" })        -- Begleiter einmal gesehen
        pet = false
        local now = texts()
        assert(now:find("Kampfschrei fehlt", 1, true), "fehlender Buff nicht erinnert: " .. now)
        assert(now:find("ohne Verzauberung", 1, true), "Waffe ohne Verzauberung nicht erinnert: " .. now)
        assert(now:find("Begleiter fehlt", 1, true), "fehlender Begleiter nicht erinnert: " .. now)
        hasBuff, enchanted, expMs, pet = true, true, 2 * 60000, true
        now = texts()
        assert(not now:find("Kampfschrei", 1, true), "Buff da und trotzdem erinnert")
        assert(now:find("noch 2 min", 1, true), "ablaufende Waffe nicht erinnert: " .. now)
        -- Im Kampf ruhen die Erinnerungen (Standard).
        _G.InCombatLockdown = function() return true end
        assert(#R.Active() == 0, "Erinnerung im Kampf trotz Einstellung")
        _G.InCombatLockdown = function() return false end
        -- Geheim: keine Erinnerung, kein Raten.
        local secret = setmetatable({}, {})
        _G.issecretvalue = function(v) return v == secret end
        _G.C_UnitAuras.GetPlayerAuraBySpellID = function() return secret end
        assert(R.PlayerAura({ spell = "Kampfschrei" }) == nil, "geheime Aura als bekannt behandelt")
        _G.issecretvalue = saved[9]
        _G.C_UnitAuras.GetPlayerAuraBySpellID = function(id) if id == 6673 then return { icon = 132333, duration = 120, expirationTime = 200 } end end

        -- Symbole: Proc sichtbar, Abklingzeit sichtbar.
        R.UpdateAll()
        assert(R.Banner() and R.Banner():IsShown(), "Erinnerungskachel nicht sichtbar")
        local procRow, cdRow = R.Rows()
        assert(procRow:IsShown() and procRow.icons[1]:IsShown(), "laufender Buff ohne Symbol")
        assert(cdRow:IsShown() and cdRow.icons[1]:IsShown(), "Abklingzeit ohne Symbol")
        local cdArgs
        cdRow.icons[1].cd.SetCooldown = function(_, a, b) cdArgs = { a, b } end
        R.UpdateCooldowns()
        assert(cdArgs and cdArgs[1] == 100 and cdArgs[2] == 60, "Abklingzeit nicht an die Uhr")
        _G.C_UnitAuras.GetPlayerAuraBySpellID = function() return nil end
        R.UpdateProcs()
        assert(not procRow:IsShown(), "Symbol bleibt, obwohl der Buff weg ist")

        -- Editor: Regel hinzufuegen und entfernen.
        local before = #R.Rules()
        R.draft.kind, R.draft.spell = "buff", ""
        assert(not R.AddDraft(), "Regel ohne Zauber angelegt")
        R.draft.spell = " Blutrausch "
        assert(R.AddDraft() and #R.Rules() == before + 1 and R.Rules()[before + 1].spell == "Blutrausch", "Regel nicht angelegt")
        R.RemoveRule(before + 1)
        assert(#R.Rules() == before, "Regel nicht entfernt")
        local list = R.BuildRuleList(UIParent, 400)
        list.Sync()
        assert(list.rows[1]:IsShown() and list.rows[1].text:GetText():find("Kampfschrei", 1, true), "Regelliste leer")
        assert(R.RuleText({ kind = "buff", spell = "Gibtsnicht" }):find("unbekannt", 1, true), "unbekannter Zauber nicht markiert")

        -- 6.6.0.5: Regeln gelten fuer eine Klasse ("Schlachtruf-Erinnerung
        -- auf dem Jaeger"). Buff sicher fehlend, damit nur die Klasse zaehlt.
        _G.C_UnitAuras = { GetPlayerAuraBySpellID = function() return nil end,
                           GetAuraDataBySpellName = function() return nil end }
        local oldIPS = _G.IsPlayerSpell
        _G.UnitClass = function() return "Jäger", "HUNTER", 3 end
        R.SetRules({ { kind = "buff", spell = "Kampfschrei", class = "WARRIOR" } })
        assert(#R.Active() == 0, "Kriegerregel erinnert den Jaeger")
        assert(R.RuleText(R.Rules()[1]):find("(hier aus)", 1, true), "fremde Regel nicht als aus markiert")
        R.SetRules({ { kind = "buff", spell = "Kampfschrei", class = R.ALL } })
        assert(#R.Active() == 1 and R.RuleText(R.Rules()[1]):find("alle Klassen", 1, true), "Regel fuer alle gilt nicht")
        -- Alte Regel ohne Klasse: gilt, wenn der Charakter den Zauber kennt.
        local knows = false
        _G.IsPlayerSpell = function() return knows end
        R.SetRules({ { kind = "buff", spell = "Kampfschrei" }, { kind = "buff", spell = "Gibtsnicht" },
                     { kind = "weapon", hand = "main" } })
        assert(#R.Active() == 0, "alte Regeln gelten trotz unbekanntem Zauber / fremder Waffe: " .. #R.Active())
        knows = true
        assert(#R.Active() == 1, "alte Regel mit bekanntem Zauber gilt nicht")
        -- Neue Regeln tragen die Klasse, "Alle Klassen" das Sternchen.
        R.SetRules({})
        R.draft.kind, R.draft.spell, R.draft.scope = "buff", "Kampfschrei", "class"
        R.AddDraft()
        R.draft.spell, R.draft.scope = "Blutrausch", "all"
        R.AddDraft()
        assert(R.Rules()[1].class == "HUNTER" and R.Rules()[2].class == R.ALL, "neue Regel ohne Klasse")
        R.draft.scope = "class"
        assert(R.Suggestions("ROGUE")[1].class == "ROGUE", "Vorschlag ohne Klasse")
        _G.IsPlayerSpell = oldIPS

        -- 6.6.0.6: Munition und Vorrat. Munition = Platz 0; leer, nachdem
        -- welche drin war = 0. Ohne Antwort des Clients: keine Erinnerung.
        local oldInvID, oldInvCount, oldItem = _G.GetInventoryItemID, _G.GetInventoryItemCount, _G.C_Item
        local ammoId, ammoN, bag = 2512, 150, { [2512] = 0, [118] = 3 }
        _G.GetInventoryItemID = function(_, slot) if slot == 0 then return ammoId end return 1234 end
        _G.GetInventoryItemCount = function(_, slot) if slot == 0 then return ammoN end return 1 end
        _G.C_Item = { GetItemCount = function(id) return bag[id] end,
                      GetItemInfoInstant = function(k)
                          if k == 118 or k == "Schwacher Heiltrank" then return 118, "Trank", "", "", 134829 end
                      end,
                      GetItemInfo = function(id) if id == 118 then return "Schwacher Heiltrank" end end }
        R._ammoSeen(false)
        R.SetRules({ { kind = "ammo", min = 200, class = "HUNTER" } })
        local a = R.Active()
        assert(#a == 1 and a[1].text == "Munition knapp: noch 150", "Munition knapp nicht erinnert: " .. (a[1] and a[1].text or "-"))
        ammoN = 500
        assert(#R.Active() == 0, "genug Munition und trotzdem erinnert")
        ammoId = nil
        a = R.Active()
        assert(#a == 1 and a[1].text == "Munition leer", "verschossene Munition nicht erinnert")
        R._ammoSeen(false)
        assert(#R.Active() == 0, "ohne je gesehene Munition erinnert (weiss nicht ist nicht leer)")
        -- Vorrat: Name oder ID, Mindestmenge.
        R.SetRules({ { kind = "item", item = "Schwacher Heiltrank", min = 5, class = R.ALL } })
        a = R.Active()
        assert(#a == 1 and a[1].text == "Schwacher Heiltrank: noch 3", "Vorrat knapp nicht erinnert: " .. (a[1] and a[1].text or "-"))
        bag[118] = 0
        assert(R.Active()[1].text == "Schwacher Heiltrank fehlt", "leerer Vorrat nicht erinnert")
        R.SetRules({ { kind = "item", item = "Gibtsnicht", min = 5, class = R.ALL } })
        assert(#R.Active() == 0, "unbekannter Gegenstand als 0 behandelt")
        -- Editor: Menge pruefen, Standard 200 fuer Munition.
        R.SetRules({})
        R.draft.kind, R.draft.min = "ammo", ""
        assert(R.AddDraft() and R.Rules()[1].min == 200, "Munition ohne Standardmenge")
        R.draft.kind, R.draft.spell, R.draft.min = "item", "118", "abc"
        assert(not R.AddDraft(), "Menge 'abc' angenommen")
        R.draft.spell, R.draft.min = "118", "10"
        assert(R.AddDraft() and R.Rules()[2].item == "118" and R.Rules()[2].min == 10, "Vorratsregel nicht angelegt")
        assert(R.RuleText(R.Rules()[2]):find("Schwacher Heiltrank unter 10", 1, true), "Vorratsregel ohne Namen: " .. R.RuleText(R.Rules()[2]))
        R.draft.kind, R.draft.spell, R.draft.min = "buff", "", ""
        _G.GetInventoryItemID, _G.GetInventoryItemCount, _G.C_Item = oldInvID, oldInvCount, oldItem
        R._ammoSeen(false)

        K.Set("reminders", "rules", nil)
        _G.UnitClass, _G.C_UnitAuras, _G.C_Spell, _G.GetWeaponEnchantInfo,
            _G.GetInventoryItemID, _G.C_Item, _G.UnitExists, _G.InCombatLockdown = unpack(saved, 1, 8)
    end)
    Check(ok, "Erinnerungen: Regeln, fehlende Buffs, Waffe, Begleiter, Editor" .. (ok and "" or (": " .. tostring(err))))
end

-- 6.13.1.0: Laune des Jaegerbegleiters - als Erinnerung und als Punkt am
-- Begleiterrahmen. Nur, was der Client sagt: ohne GetPetHappiness, ohne
-- Laune (Wichtel) oder geheim nichts, nie "ungluecklich".
do
    local saved = { _G.GetPetHappiness, _G.UnitClass, _G.InCombatLockdown, _G.issecretvalue, _G.UnitExists, _G.C_PetInfo }
    local ok, err = pcall(function()
        local R, UF = WeintCodex.UIReminders, WeintCodex.UIUnitFrames
        -- 6.13.3.0, gemessen auf Forever: kein GetPetHappiness, aber
        -- C_PetInfo.GetPetHappiness. Gegenprobe ueber den Schaden in Prozent.
        _G.GetPetHappiness = nil
        local ans
        _G.C_PetInfo = { GetPetHappiness = function(...) return ans(...) end }
        ans = function() return 3, 125, 0 end
        assert(K.PetHappiness() == 3 and select(2, K.PetHappinessSource()) == "C_PetInfo.GetPetHappiness",
            "C_PetInfo.GetPetHappiness nicht gelesen")
        ans = function() return 3, 100, 0 end
        assert(K.PetHappiness() == nil, "Laune trotz unpassendem Schaden angenommen")
        ans = function() return 2 end
        assert(K.PetHappiness() == 2, "Laune ohne zweiten Wert nicht gelesen")
        ans = function(u) if u == "pet" then return 1, 75 end end
        assert(K.PetHappiness() == 1, "Abfrage mit \"pet\" nicht versucht")
        ans = function() error("Usage") end
        assert(K.PetHappiness() == nil, "Fehler der Abfrage als Laune")
        ans = function() error(3, 0) end   -- Stufe 0: ohne Ortsangabe bleibt es die Zahl
        assert(K.PetHappiness() == nil, "Fehler mit Zahl als Laune gelesen")
        _G.issecretvalue = function(v) return v == 3 end
        ans = function() return 3, 125 end
        assert(K.PetHappiness() == nil, "geheime Laune aus C_PetInfo gelesen")
        _G.issecretvalue = saved[4]
        _G.C_PetInfo = saved[6]
        _G.InCombatLockdown = function() return false end
        _G.UnitClass = function() return "Jäger", "HUNTER", 3 end
        local mood
        _G.GetPetHappiness = function() return mood, K.HAPPY_DAMAGE[mood], 0 end
        assert(K.PetHappiness() == nil, "keine Laune als Laune gelesen")
        mood = 0
        assert(K.PetHappiness() == nil, "Laune 0 angenommen")
        mood = 2
        assert(K.PetHappiness() == 2, "Laune nicht gelesen")
        -- Geheim ist im Spiel eine Zahl (type "number") - hier die 3.
        _G.issecretvalue = function(v) return v == 3 end
        mood = 3
        assert(K.PetHappiness() == nil, "geheime Laune gelesen")
        _G.issecretvalue = saved[4]

        local function texts()
            local t = {}
            for _, a in ipairs(R.Active()) do t[#t + 1] = a.text end
            return table.concat(t, " | ")
        end
        -- Standard: erinnern, solange nicht gluecklich.
        R.SetRules({ { kind = "happy", below = 3, class = "HUNTER" } })
        mood = 3
        assert(texts() == "", "gluecklich und trotzdem erinnert: " .. texts())
        mood = 2
        assert(texts() == "Begleiter zufrieden – füttern", "zufrieden nicht erinnert: " .. texts())
        mood = 1
        assert(texts() == "Begleiter unglücklich – füttern", "ungluecklich nicht erinnert: " .. texts())
        mood = nil
        assert(texts() == "", "ohne Laune erinnert (weiss nicht ist nicht ungluecklich)")
        _G.GetPetHappiness = nil
        assert(texts() == "", "ohne Abfrage erinnert")
        _G.GetPetHappiness = function() return mood, K.HAPPY_DAMAGE[mood], 0 end
        -- Schwelle "ungluecklich": zufrieden reicht.
        R.SetRules({ { kind = "happy", below = 2, class = "HUNTER" } })
        mood = 2
        assert(texts() == "", "Schwelle ungluecklich erinnert bei zufrieden")
        mood = 1
        assert(texts() == "Begleiter unglücklich – füttern", "Schwelle ungluecklich erinnert nicht")
        -- Regel ohne Schwelle: Standard "nicht gluecklich".
        R.SetRules({ { kind = "happy", class = "HUNTER" } })
        mood = 2
        assert(texts() ~= "", "Regel ohne Schwelle erinnert nicht bei zufrieden")
        assert(R.RuleText(R.Rules()[1]):find("nicht glücklich", 1, true), "Regeltext ohne Schwelle")
        -- Kriegerregel? Gilt nicht fuer den Jaeger; Klasse bleibt die Regel.
        R.SetRules({ { kind = "happy", class = "WARRIOR" } })
        assert(texts() == "", "Laune-Regel einer anderen Klasse erinnert")
        -- Editor: Schwelle aus dem Formular.
        R.SetRules({})
        R.draft.kind, R.draft.below = "happy", 2
        assert(R.AddDraft() and R.Rules()[1].kind == "happy" and R.Rules()[1].below == 2
            and R.Rules()[1].class == "HUNTER", "Laune-Regel nicht angelegt")
        assert(R.RuleText(R.Rules()[1]):find("wenn unglücklich", 1, true), "Regeltext ohne Schwelle: " .. R.RuleText(R.Rules()[1]))
        R.draft.kind, R.draft.below = "buff", 3
        -- "Fuer meine Klasse" ergaenzt die Laune nicht doppelt, auch bei anderer Schwelle.
        R.SetRules({ { kind = "happy", below = 2, class = "HUNTER" } })
        local added = R.AddSuggestions("HUNTER")
        assert(added == 2 and #R.Rules() == 3, "Laune doppelt ergaenzt: " .. added)
        K.Set("reminders", "rules", nil)

        -- Punkt am Begleiterrahmen: Farbe der Laune, sonst aus.
        local f = UF.frames.pet
        assert(f and f._happy, "Begleiterrahmen ohne Punkt fuer die Laune")
        assert(not (UF.frames.player._happy or UF.frames.target._happy), "Laune-Punkt an einem anderen Rahmen")
        local Cc = WeintCodex.Colors
        local vc = {}
        f._happy.SetVertexColor = function(_, r, g, b) vc = { r, g, b } end
        local function shows(color)
            if not f._happy:IsShown() then return false end
            local r, g, b = vc[1], vc[2], vc[3]
            return r == Cc[color][1] and g == Cc[color][2] and b == Cc[color][3]
        end
        for level, color in pairs({ [1] = "danger", [2] = "warning", [3] = "success" }) do
            mood = level
            f:UpdateHappiness()
            assert(shows(color), "Laune " .. level .. " nicht in " .. color)
        end
        mood = nil
        f:UpdateHappiness()
        assert(not f._happy:IsShown(), "Punkt ohne Laune sichtbar")
        -- Der Rahmen zeichnet beim Neuzeichnen die Laune mit (Erscheinen, Einstellung).
        _G.UnitExists = function() return true end
        mood = 2
        f:Refresh()
        assert(shows("warning"), "Refresh zeichnet die Laune nicht")
        -- Ereignis UNIT_HAPPINESS zeichnet nach.
        mood = 1
        stub.FireEvent("UNIT_HAPPINESS", "pet")
        assert(shows("danger"), "UNIT_HAPPINESS zeichnet den Punkt nicht")
        -- Tooltip: die Laune als Wort.
        local lines = {}
        local oldAdd = GameTooltip.AddLine
        GameTooltip.AddLine = function(_, text) lines[#lines + 1] = text end
        f:HappinessTooltip()
        GameTooltip.AddLine = oldAdd
        -- Die Attrappe ersetzt bei HookScript (Klickzauber), statt
        -- anzuhaengen - deshalb die Quelle: OnEnter ruft die Zeile.
        local src = assert(io.open(ROOT .. "/ui/unitframes.lua")):read("*a")
        assert(src:find('SetScript%("OnEnter".-self:HappinessTooltip%(%)'), "OnEnter ohne Laune")
        assert(table.concat(lines, "|"):find("Laune: unglücklich", 1, true), "Laune fehlt im Tooltip")
        -- Testmodus: gluecklich, danach wieder, was der Client sagt.
        mood = nil
        _G.UnitExists = function(u) return u ~= "pet" end
        f:ShowTest(true)
        assert(shows("success"), "Testmodus ohne Laune")
        f:ShowTest(false)
        assert(not f._happy:IsShown(), "Punkt des Testmodus bleibt stehen")
    end)
    _G.GetPetHappiness, _G.UnitClass, _G.InCombatLockdown, _G.issecretvalue, _G.UnitExists, _G.C_PetInfo = unpack(saved, 1, 6)
    K.Set("reminders", "rules", nil)
    WeintCodex.UIReminders.draft.kind, WeintCodex.UIReminders.draft.below = "buff", 3
    Check(ok, "Laune des Begleiters: Erinnerung mit Schwelle, weiss nicht, Editor, Punkt am Rahmen, Tooltip, Testmodus"
        .. (ok and "" or (": " .. tostring(err))))
end

-- 6.14.0.0: Abgleich mit ForeverGuide - Quests ohne eigene Texte (Geber
-- und Abgabe als NPC mit Gebiet oder "im Dungeon"), Ketten, feste
-- Belohnungen, Herkunft je Abschnitt, Eingaenge auf der Karte.
do
    local saved = { WeintCodex.Paragraph, _G.UnitFactionGroup, _G.C_Map, _G.C_QuestLog }
    local ok, err = pcall(function()
        local DP, J = WeintCodex.DungeonPages, WeintCodex.DungeonJournal
        _G.C_QuestLog = nil   -- Namen aus dem Bestand, nicht aus einer Attrappe davor
        -- Bestand: eingemischt, Handgepflegtes bleibt vorn.
        local brd = J.Quests("blackrock_depths")
        local q4126
        for _, q in ipairs(brd) do if q.id == 4126 then q4126 = q end end
        assert(q4126 and q4126.src == "fg" and J.QuestSource(q4126) == J.FG_SOURCE, "Quest 4126 nicht aus dem Abgleich")
        assert(J.QuestSource(J.Quests("hall_of_thanes")[1]) == J.SOURCE, "Journal-Quest traegt die Herkunft des Abgleichs")
        assert(J.LootSource("scholomance", "darkmaster_gandling") == J.CLASSIC_LOOT_SOURCE, "Classic-Beute ohne Classic-Herkunft")
        assert(J.LootSource("hall_of_thanes", "faldrim_anvilmar") == J.SOURCE, "Journal-Beute als Classic ausgewiesen")
        assert(J.Chain(4242) and J.Chain(4242).prev[1] == 4241 and J.QuestName(4241) == "Marshal Windsor", "Kette von 4242")
        -- Einmischen ersetzt nie Handgepflegtes und ist wiederholbar - auch
        -- wenn der Abgleich dieselben Nummern bringt.
        local nThanes, nBrd = #J.Quests("hall_of_thanes"), #J.Quests("blackrock_depths")
        local nOthers = #J.Others("blackrock_depths")
        local fq, fp, fl = J.FG_QUESTS.hall_of_thanes, J.FG_PLACES[214], J.CLASSIC_LOOT.hall_of_thanes
        local hand = J.Quests("hall_of_thanes")[1]
        J.FG_QUESTS.hall_of_thanes = { { id = hand.id, name = "Falsch", level = 1, faction = "both" } }
        J.FG_PLACES[214] = { map = 1, x = 0.5, y = 0.5, who = "Falsch" }
        J.CLASSIC_LOOT.hall_of_thanes = { faldrim_anvilmar = { { 1, "Falsch", "Kopf", 1 } } }
        J.MergeForeverGuide()
        J.FG_QUESTS.hall_of_thanes, J.FG_PLACES[214], J.CLASSIC_LOOT.hall_of_thanes = fq, fp, fl
        assert(#J.Quests("hall_of_thanes") == nThanes and J.Quests("hall_of_thanes")[1].name ~= "Falsch",
            "Journal-Quest vom Abgleich ersetzt oder doppelt")
        assert(J.Place(214).who == "Scout Riell", "Ort des Journals vom Abgleich ersetzt")
        assert(J.Loot("hall_of_thanes", "faldrim_anvilmar")[1][2] == "Ephemeral Choker"
            and J.LootSource("hall_of_thanes", "faldrim_anvilmar") == J.SOURCE, "Beute des Journals vom Abgleich ersetzt")
        assert(#J.Quests("blackrock_depths") == nBrd and #J.Others("blackrock_depths") == nOthers,
            "zweites Einmischen verdoppelt")
        -- Geber in Worten.
        _G.C_Map = { GetMapInfo = function(id) if id == 1426 then return { name = "Dun Morogh" } end end }
        assert(DP.NpcText("Eigener Text", { name = "X", map = 1426 }) == "Eigener Text", "Journaltext ueberschrieben")
        assert(DP.NpcText(nil, { name = "Ragnar Thunderbrew", map = 1426 }) == "Ragnar Thunderbrew, Dun Morogh", "Geber ohne Gebiet")
        assert(DP.NpcText(nil, { name = "Marshal Windsor", inside = true }) == "Marshal Windsor, im Dungeon", "Geber im Dungeon")
        assert(DP.NpcText(nil, { name = "Niemand", map = 9999 }) == "Niemand", "unbekanntes Gebiet erfunden")
        assert(DP.NpcText(nil, nil) == nil, "Geber erfunden")
        -- Die Seite: Texte mitschreiben.
        local texts = {}
        WeintCodex.Paragraph = function(parent, text, opts)
            texts[#texts + 1] = tostring(text)
            return saved[1](parent, text, opts)
        end
        _G.UnitFactionGroup = function() return "Alliance" end
        DP.Select("blackrock_depths", nil)
        WeintCodex.Navigation.SwitchTo("dungeons")
        local all = table.concat(texts, "\n")
        assert(all:find("Beginnt: Ragnar Thunderbrew, Dun Morogh", 1, true), "Geber aus dem Abgleich fehlt")
        assert(all:find("Beginnt: Marshal Windsor, im Dungeon", 1, true), "Geber im Dungeon fehlt")
        assert(all:find("Vorher: „Marshal Windsor“", 1, true) and all:find("Danach: „", 1, true), "Kette fehlt")
        assert(all:find("Dazu:", 1, true), "feste Belohnung fehlt")
        assert(all:find("Quests: Wissensstand aus der Beta", 1, true), "Herkunft der Quests aus dem Abgleich nicht genannt")
        assert(not all:find("ForeverGuide", 1, true) and not all:find("Questie", 1, true), "fremdes Addon als Quelle genannt")
        assert(all:find("Beute aus Classic", 1, true), "Classic-Beute nicht ausgewiesen")
        assert(DP.entranceLinks == 1, "Eingang von Blackrock Depths: " .. tostring(DP.entranceLinks))
        DP.Select("stratholme", nil)
        WeintCodex.Navigation.SwitchTo("dungeons")
        assert(DP.entranceLinks == 2, "Stratholme hat zwei Eingaenge: " .. tostring(DP.entranceLinks))
        -- Boss mit Classic-Beute: die Zeile nennt Classic.
        texts = {}
        DP.Select("scholomance", "darkmaster_gandling")
        WeintCodex.Navigation.SwitchTo("dungeons")
        assert(table.concat(texts, "\n"):find("Beute aus Classic", 1, true), "Boss mit Classic-Beute ohne Hinweis")
        assert(DP.itemRows > 0, "Classic-Beute ohne Zeilen")
    end)
    WeintCodex.Paragraph, _G.UnitFactionGroup, _G.C_Map, _G.C_QuestLog = saved[1], saved[2], saved[3], saved[4]
    Check(ok, "Dungeons: Abgleich mit ForeverGuide - Geber, Ketten, Belohnungen, Herkunft, Eingaenge"
        .. (ok and "" or (": " .. tostring(err))))
end

-- 6.14.0.0: Berufe - Fertigkeit und Gelerntes aus dem Client, Rezepte
-- nach Faechern, Lehrer der Fraktion, Startseite, Selbstpruefung.
do
    local G = _G
    local saved = { G.GetProfessions, G.GetProfessionInfo, G.GetNumSkillLines, G.GetSkillLineInfo, G.C_TradeSkillUI,
                    G.GetNumTradeSkills, G.GetTradeSkillRecipeLink, G.UnitFactionGroup, G.UnitName }
    local PRO, P = WeintCodex.Professions, WeintCodex.ProfessionData
    local sd = WeintCodex.SavedData
    local savedProf = sd and sd.professions
    local ok, err = pcall(function()
        assert(#P.PROFS == 12, "Berufe im Bestand: " .. #P.PROFS)
        local tail = PRO.Recipes("tailoring")
        local lines = select(2, P.RAW.tailoring:gsub("\n", ""))
        assert(#tail == lines and #tail > 300, "Schneiderei: " .. #tail .. " Rezepte, " .. lines .. " Zeilen")
        local withReag = 0
        for _, r in ipairs(tail) do if #r.reagents > 0 then withReag = withReag + 1 end end
        assert(withReag > 300, "Reagenzien nicht gelesen")
        -- Schwierigkeit wie im Berufsfenster.
        local r0 = { learn = 1, yellow = 10, green = 15, grey = 20 }
        assert(PRO.Difficulty(r0, 5) == "orange" and PRO.Difficulty(r0, 12) == "yellow" and PRO.Difficulty(r0, 16) == "green"
            and PRO.Difficulty(r0, 25) == "grey" and PRO.Difficulty({ learn = 30 }, 10) == "unavailable"
            and PRO.Difficulty(r0, nil) == nil, "Schwierigkeit")
        -- Fertigkeit: GetProfessions, sonst die Fertigkeitsliste, sonst nichts.
        G.GetProfessions = function() return 1, 2, nil, nil, 3, nil end
        G.GetProfessionInfo = function(i)
            if i == 1 then return "Schneiderei", nil, 75, 150, 0, 0, 197 end
            if i == 2 then return "Kräuterkunde", nil, 40, 75, 0, 0, 182 end
            if i == 3 then return "Kochkunst", nil, 10, 75, 0, 0, 185 end
        end
        local skills, answered = PRO.Skills()
        assert(answered and skills.tailoring.rank == 75 and skills.tailoring.max == 150 and skills.herbalism.rank == 40
            and skills.cooking.rank == 10 and not skills.alchemy, "GetProfessions nicht gelesen")
        G.GetProfessions = nil
        G.GetNumSkillLines = function() return 2 end
        G.GetSkillLineInfo = function(i)
            if i == 1 then return "Berufe", true end
            return "Schneiderei", false, nil, 30, 0, 0, 75
        end
        skills = PRO.Skills()
        assert(skills.tailoring and skills.tailoring.rank == 30, "Fertigkeitsliste nicht gelesen")
        G.GetNumSkillLines, G.GetSkillLineInfo = nil, nil
        skills, answered = PRO.Skills()
        assert(not answered and next(skills) == nil, "ohne Abfrage eine Fertigkeit erfunden")

        -- Gelernt: ohne Berufsfenster "weiss nicht", danach der Speicher.
        sd.professions = nil
        -- Detailbereich ohne Berufsfenster: Grenzen statt fester Zahlen
        -- (6.14.0.1: die Liste zeigte 6 "bringt Fertigkeit", der Detailbereich "—").
        local function inspect(skill)
            local cat = PRO.Categorize("tailoring", skill)
            local vals = {}
            for _, b in ipairs(PRO.InspectorBlocks("tailoring", skill, cat)) do
                for _, r in ipairs(b.rows or {}) do vals[r.label] = r.value end
            end
            return vals, cat
        end
        local TRk = WeintCodex.Trainer
        local oldKnown = TRk.Known
        local firstLearn
        for _, r in ipairs(tail) do if r.learn and r.learn <= 75 and r.grey and r.grey > 75 then firstLearn = r break end end
        TRk.Known = function(id) return id == firstLearn.spell end
        local iv, icat = inspect(75)
        TRk.Known = oldKnown
        assert(#icat.sections.skillup == 1 and iv["Bringt Fertigkeit"] == "mind. 1", "Untergrenze: " .. tostring(iv["Bringt Fertigkeit"]))
        assert(iv["Jetzt lernbar"]:find("^bis zu %d"), "Obergrenze: " .. tostring(iv["Jetzt lernbar"]))
        local learnable = {}
        for _, r in ipairs(tail) do
            if r.learn and r.learn <= 75 and #learnable < 3 then learnable[#learnable + 1] = r end
        end
        local c0 = PRO.Categorize("tailoring", 75)
        assert(not c0.learnedKnown and #c0.sections.now > 0 and #c0.sections.recipe > 0 and #c0.sections.known == 0,
            "ohne Berufsfenster: lernbar/gelernt falsch")
        for _, r in ipairs(c0.sections.now) do assert(r.trainer, "Rezept ohne Lehrer unter 'Beim Lehrer'") end
        for _, r in ipairs(c0.sections.recipe) do assert(not r.trainer, "Lehrer-Rezept unter 'Als Rezept'") end
        assert(PRO.Learned(learnable[1]) == nil, "ohne Berufsfenster: Gelerntes behauptet")
        local s1, s2, s3 = learnable[1].spell, learnable[2].spell, learnable[3].spell
        G.C_TradeSkillUI = { GetAllRecipeIDs = function() return { s1, s2, s3 } end,
                             GetRecipeInfo = function(id) return { learned = id ~= s3 } end }
        assert(PRO.Scan() == 2, "Berufsfenster nicht gelesen")
        assert(PRO.Learned(learnable[1]) == true and PRO.Learned(learnable[3]) == false, "Gelernt/nicht gelernt nach dem Lesen")
        local c1 = PRO.Categorize("tailoring", 75)
        assert(c1.learnedKnown and #c1.sections.known + #c1.sections.skillup == 2, "Gelerntes nicht einsortiert")
        assert(PRO.lastScan.ids == 3 and PRO.lastScan.matched == 3 and PRO.lastScan.via[1] == "C_TradeSkillUI",
            "Messung des Berufsfensters fehlt")
        for _, r in ipairs(c1.sections.now) do assert(r.spell ~= s1 and r.spell ~= s2, "Gelerntes als lernbar") end
        -- Klassisches Fenster: Links.
        G.C_TradeSkillUI = nil
        local r4
        for _, r in ipairs(tail) do if r.learn and r.learn <= 75 and r.spell ~= s1 and r.spell ~= s2 and r.spell ~= s3 then r4 = r break end end
        G.GetNumTradeSkills = function() return 1 end
        G.GetTradeSkillRecipeLink = function() return "|cffffd000|Henchant:" .. r4.spell .. "|h[x]|h|r" end
        PRO.Scan()
        assert(PRO.Learned(r4) == true, "Link aus dem klassischen Fenster nicht erkannt")
        -- Neu gelernt beim Lehrer: das Ereignis traegt nach.
        stub.FireEvent("NEW_RECIPE_LEARNED", s3)
        assert(PRO.Learned(learnable[3]) == true, "NEW_RECIPE_LEARNED nicht gemerkt")
        -- Je Charakter.
        G.UnitName = function() return "Twink" end
        assert(PRO.Learned(learnable[1]) == nil, "Gelerntes eines anderen Charakters")
        G.UnitName = saved[9]

        -- Lehrer: Fraktion, der naechste Rang zuerst.
        -- Ein Lehrer "hier" (gleiche Karte), der den naechsten Rang NICHT lehrt,
        -- steht trotzdem hinter denen, die ihn lehren.
        -- Grenze 150 (Geselle): der naechste Rang ist Experte (3). Eldrin in
        -- Elwynn lehrt nur bis 150 - steht er "hier", bleibt er trotzdem hinten.
        local low
        for _, t in ipairs(P.TRAINERS.tailoring) do if t[7] == 2 and t[3] and t[6] == "Alliance" then low = t end end
        assert(low, "kein Lehrer mit Rang 2 im Bestand")
        local oldMap = G.C_Map
        G.C_Map = { GetBestMapForUnit = function() return low[3] end, GetMapInfo = function() return nil end }
        local tr, need = PRO.Trainers("tailoring", "Alliance", 150)
        G.C_Map = oldMap
        local lowSeen = false
        for _, t in ipairs(tr) do if t.id == low[1] then lowSeen = t.here end end
        assert(lowSeen, "Lehrer auf der eigenen Karte nicht erkannt")
        assert(need == 3 and #tr > 0 and tr[1].next and tr[1].rank >= 3, "naechster Rang nicht zuerst")
        local seenOther = false
        for _, t in ipairs(tr) do
            if not t.next then seenOther = true end
            assert(not (t.next and seenOther), "Lehrer des naechsten Rangs hinter einem anderen")
        end
        for _, t in ipairs(tr) do assert(t.faction == nil or t.faction == "Alliance", "Lehrer der Horde fuer die Allianz") end
        -- 6.14.0.1: mit Weltlage vom Client der naechste zuerst. Die Attrappe
        -- legt jede Karte 1000 Einheiten neben die vorige; eine Karte liegt
        -- auf einem anderen Kontinent und zaehlt dann nicht als nah.
        local far
        for _, t in ipairs(P.TRAINERS.tailoring) do
            if t[3] and t[3] ~= low[3] and t[6] == "Alliance" and t[7] >= 3 then far = t[3] break end
        end
        G.C_Map = {
            GetBestMapForUnit = function() return low[3] end,
            GetPlayerMapPosition = function() return { x = 0.5, y = 0.5 } end,
            GetWorldPosFromMapPos = function(map, v)
                return map == far and 2 or 1, { x = map * 1000 + v.x * 100, y = v.y * 100 }
            end,
        }
        tr = PRO.Trainers("tailoring", "Alliance", 150)
        local lastD, noDist = -1, false
        for _, t in ipairs(tr) do
            if t.next then
                if t.dist then
                    assert(not noDist and t.dist >= lastD, "Lehrer nicht nach Entfernung: " .. t.name)
                    lastD = t.dist
                else
                    noDist = true
                end
                if t.map == far then assert(t.dist == nil, "anderer Kontinent als nah gerechnet") end
            end
        end
        assert(tr[1].next and tr[1].dist and math.abs(tr[1].map - low[3]) <= math.abs((tr[2].map or 0) - low[3]),
            "der naechste Lehrer steht nicht oben")
        -- Ohne Weltlage: die eigene Karte, dann der niedrigere Rang.
        G.C_Map = { GetBestMapForUnit = function() return -1 end }
        tr = PRO.Trainers("tailoring", "Alliance", 75)
        local lastRank = 0
        for _, t in ipairs(tr) do
            if t.next then
                assert(t.dist == nil and t.rank >= lastRank, "ohne Weltlage nicht nach Rang aufsteigend: " .. t.name)
                lastRank = t.rank
            end
        end
        G.C_Map = oldMap

        -- Seite: deine Berufe zuerst, Rezepte und Lehrer, Spalte passt.
        G.GetProfessions = function() return 1, 2, nil, nil, 3, nil end
        G.UnitFactionGroup = function() return "Alliance" end
        PRO.ShowAll(false)
        PRO.Select("tailoring")
        WeintCodex.Navigation.SwitchTo("berufe")
        local d = PRO.lastDraw
        assert(d and d.key == "tailoring" and d.skill == 75 and d.rows > 0 and d.trainers > 0, "Seite nicht gezeichnet")
        local nav = WeintCodex.Navigation
        assert(nav.SubNavHeight() <= nav.SubNavBudget() - nav.SubNavHeadroom(),
            "Spalte der Berufe zu hoch: " .. nav.SubNavHeight())
        local items = PRO.SidebarItems(PRO.Skills())
        assert(items[1].isGroup and items[1].label == "Deine Berufe" and items[5].isGroup, "deine Berufe nicht zuerst")
        assert(d.hidden > 0, "Spaeteres nicht zugeklappt")
        PRO.ShowAll(true)
        PRO.Show()
        assert(PRO.lastDraw.hidden == 0 and PRO.lastDraw.rows >= d.rows, "Alle zeigen zeigt nicht alles")
        PRO.ShowAll(false)
        -- Ohne Fertigkeit: nach Raengen.
        PRO.Select("alchemy")
        PRO.Show()
        assert(PRO.lastDraw.skill == nil and PRO.lastDraw.rows > 0, "Beruf ohne Fertigkeit")

        -- Startseite: Schritt nur mit bekanntem Gelernten.
        local HM = WeintCodex.Home
        local prof = HM.Professions()
        assert(#prof == 1 and prof[1].key == "tailoring" and prof[1].now > 0, "Startseite kennt den Beruf nicht")
        local steps = HM.Steps({ professions = prof })
        assert(steps[1] and steps[1].key == "profession" and steps[1].go.tab == "berufe" and steps[1].go.profession == "tailoring",
            "Schritt Beruf fehlt")
        PRO.Select("alchemy")
        HM.Go(steps[1])
        assert(PRO.Selected() == "tailoring", "Schritt schlaegt den Beruf nicht auf")
        sd.professions = nil
        assert(#HM.Professions() == 0, "Schritt ohne Blick ins Berufsfenster")

        -- Selbstpruefung: zaehlt, ob das Spiel das Berufsfenster gemeldet hat.
        stub.FireEvent("TRADE_SKILL_SHOW")
        local SC = WeintCodex.UISelfCheck
        local out = {}
        for _, c in ipairs(SC.CHECKS) do
            if c.name == "Berufe" then c.fn(function(mark, text) out[#out + 1] = (mark ~= "" and (mark .. " ") or "") .. text end) end
        end
        local txt = table.concat(out, "\n")
        assert(txt:find("Fertigkeit gelesen:", 1, true) and txt:find("Schneiderei 75/150", 1, true), "Selbstpruefung Berufe: " .. txt)
        assert(txt:find("Nummern vom Client", 1, true) and txt:find("TRADE_SKILL_SHOW [1-9]"), "Selbstpruefung ohne Messung: " .. txt)
        -- Nummern, die nicht zum Bestand passen, sind ein Befund.
        G.C_TradeSkillUI = { GetAllRecipeIDs = function() return { 1, 2 } end, GetRecipeInfo = function() return { learned = true } end }
        G.GetNumTradeSkills = nil
        PRO.Scan()
        out = {}
        for _, c in ipairs(SC.CHECKS) do
            if c.name == "Berufe" then c.fn(function(mark, text) out[#out + 1] = (mark ~= "" and (mark .. " ") or "") .. text end) end
        end
        assert(table.concat(out, "\n"):find("passen nicht zum Bestand", 1, true), "fremde Nummern ohne Befund")
        -- Die Seite: Legende der Zahlen, Lehrer nach Ort.
        assert(PRO.Legend():find("lernbar ab", 1, true) and PRO.Legend():find("grau ab", 1, true), "Legende")
    end)
    G.GetProfessions, G.GetProfessionInfo, G.GetNumSkillLines, G.GetSkillLineInfo, G.C_TradeSkillUI,
        G.GetNumTradeSkills, G.GetTradeSkillRecipeLink, G.UnitFactionGroup, G.UnitName = unpack(saved, 1, 9)
    if sd then sd.professions = savedProf end
    PRO.ShowAll(false)
    Check(ok, "Berufe: Fertigkeit, Gelerntes aus dem Berufsfenster, Faecher, Lehrer, Seite, Startseite, Selbstpruefung"
        .. (ok and "" or (": " .. tostring(err))))
end

-- 6.15.0.0: Klassenquests - Volk und Klasse, Stand nur vom Client, Vorquest,
-- Seite als zweiter Reiter unter Lehrer, Startseite, Lehrer nach Entfernung.
do
    local G = _G
    local saved = { G.UnitClass, G.UnitRace, G.UnitLevel, G.UnitFactionGroup, G.C_QuestLog, G.C_Spell }
    local K = WeintCodex.UIKit
    local savedK = { K.PlayerWorld, K.BestMap, K.ToWorld }
    local CQ, Q, TR = WeintCodex.ClassQuests, WeintCodex.ClassQuestData, WeintCodex.Trainer
    local ok, err = pcall(function()
        G.UnitClass = function() return "Jäger", "HUNTER", 3 end
        G.UnitRace = function() return "Nachtelf", "NightElf", 4 end
        G.UnitLevel = function() return 10 end
        G.UnitFactionGroup = function() return "Alliance" end
        G.C_Spell = { GetSpellName = function(id) return id == 1579 and "Wildtier zähmen lehren" or nil end }
        local done, inLog = {}, {}
        G.C_QuestLog = {
            IsQuestFlaggedCompleted = function(id) return done[id] == true end,
            GetLogIndexForQuestID = function(id) return inLog[id] end,
            IsComplete = function() return false end,
        }
        -- Volk: nur, was fuer Nachtelfen gilt (Bit 8) oder fuer alle.
        local list = CQ.List("HUNTER", 4)
        local taming, tauren
        for _, q in ipairs(list) do
            assert(not q.ra or math.floor(q.ra / 8) % 2 == 1, "Quest eines anderen Volkes: " .. q.id)
            if q.spell == 1579 then taming = q end
        end
        for _, q in ipairs(Q.CLASSES.HUNTER) do if q.ra == 32 then tauren = q end end
        assert(taming and tauren and #list < #Q.CLASSES.HUNTER, "Volksfilter")
        assert(CQ.ForRace(tauren, nil) == true, "ohne Volk etwas ausgelassen")
        -- Vorquest offen (Client antwortet "nicht erledigt"): wartet.
        local cat = CQ.Categorize(list, 10)
        local function where(c, q)
            for key, l in pairs(c.sections) do for _, x in ipairs(l) do if x == q then return key end end end
        end
        assert(where(cat, taming) == "chain", "Zaehmen ohne Vorquest als moeglich: " .. tostring(where(cat, taming)))
        -- Schweigt der Client zur Vorquest, sperrt sie nicht.
        local pre = {}
        for _, id in ipairs(taming.pre) do pre[id] = true end
        G.C_QuestLog.IsQuestFlaggedCompleted = function(id) if pre[id] then error("geheim") end return done[id] == true end
        assert(CQ.Blocked(taming) == false, "Vorquest ohne Antwort sperrt")
        G.C_QuestLog.IsQuestFlaggedCompleted = function(id) return done[id] == true end
        for _, id in ipairs(taming.pre) do done[id] = true end
        cat = CQ.Categorize(list, 10)
        assert(where(cat, taming) == "now", "Zaehmen nach der Vorquest nicht moeglich: " .. tostring(where(cat, taming)))
        inLog[taming.id] = 3
        assert(where(CQ.Categorize(list, 10), taming) == "active", "im Questlog nicht erkannt")
        inLog[taming.id] = nil
        assert(where(CQ.Categorize(list, 8), taming) == "soon", "zwei Stufen darueber nicht 'bald'")
        -- Schweigt der Client: unbekannt, nie "fehlt".
        G.C_QuestLog.IsQuestFlaggedCompleted = nil
        cat = CQ.Categorize(list, 10)
        assert(#cat.sections.unknown == #list and #cat.sections.now == 0, "ohne Antwort ein Stand behauptet")
        G.C_QuestLog.IsQuestFlaggedCompleted = function(id) return done[id] == true end

        -- Startseite: die naechste Quest, die einen Zauber lehrt.
        local nq = CQ.NextSpellQuest()
        assert(nq and nq.q.spell and nq.state == "now", "keine Klassenquest mit Zauber gefunden")
        local HM = WeintCodex.Home
        local steps = HM.Steps({ classQuest = { q = taming, state = "now", title = "Zähmen", spell = "Wildtier zähmen",
                                                giver = "bei Dazalar" } })
        assert(steps[1] and steps[1].key == "classQuest" and steps[1].go.tab == "klassenquests", "Schritt Klassenquest fehlt")

        -- Seite: zweiter Reiter unter Lehrer, ueber Navigation und Startseite.
        WeintCodex.Navigation.SwitchTo("lehrer")
        assert(TR.view == "spells" and #WeintCodex.Navigation.SidebarButtons() >= 2, "Lehrer ohne Reiter")
        HM.Go(steps[1])
        local d = CQ.lastDraw
        assert(TR.view == "quests" and d and d.class == "HUNTER" and d.total == #list and d.rows > 0,
            "Klassenquests nicht gezeichnet")
        assert(d.hidden > 0, "Erledigtes/Spaeteres nicht zugeklappt")
        CQ.ShowAll(true)
        CQ.Draw()
        assert(CQ.lastDraw.hidden == 0 and CQ.lastDraw.rows >= d.rows, "Alle zeigen zeigt nicht alles")
        CQ.ShowAll(false)
        WeintCodex.Navigation.SwitchTo("lehrer")
        assert(TR.view == "spells", "Lehrer schlaegt nicht die Zauber auf")

        -- Lehrer: Fraktion, der naechste zuerst (Weltlage vom Client).
        K.BestMap = function() return 1438 end
        K.PlayerWorld = function() return 1, 0, 0 end
        K.ToWorld = function(map, x, y) return 1, (map - 1438) * 1000 + x * 100, y * 100 end
        local tr = CQ.Trainers("HUNTER", "Alliance")
        assert(#tr > 0, "keine Jaegerlehrer der Allianz")
        local last = -1
        for _, n in ipairs(tr) do
            assert(n.faction ~= "H", "Lehrer der Horde fuer die Allianz: " .. n.name)
            if n.dist then assert(n.dist >= last, "Lehrer nicht nach Entfernung") last = n.dist end
        end
        assert(tr[1].dist and tr[1].map == 1438, "der naechste Lehrer steht nicht oben: " .. tostring(tr[1].map))
    end)
    G.UnitClass, G.UnitRace, G.UnitLevel, G.UnitFactionGroup, G.C_QuestLog, G.C_Spell = unpack(saved, 1, 6)
    K.PlayerWorld, K.BestMap, K.ToWorld = savedK[1], savedK[2], savedK[3]
    CQ.ShowAll(false)
    TR.view = "spells"
    Check(ok, "Klassenquests: Volk, Stand vom Client, Vorquest, Reiter unter Lehrer, Startseite, Lehrer nach Entfernung"
        .. (ok and "" or (": " .. tostring(err))))
end

-- 6.16.0.0: Seltene Gegner - erkannt vom Client oder aus dem Bestand,
-- gemeldet mit Ton, Chat und Hinweis, hoechstens alle 5 Minuten, nicht tot,
-- nicht in Instanzen; Vignetten; Bericht; Selbstpruefung.
do
    local G = _G
    local names = { "UnitGUID", "UnitClassification", "UnitName", "UnitLevel", "UnitIsDead", "UnitIsPlayer",
                    "UnitExists", "IsInInstance", "PlaySound", "SOUNDKIT", "C_VignetteInfo", "GetTime", "print" }
    local saved = {}
    for i, n in ipairs(names) do saved[i] = G[n] end
    local K = WeintCodex.UIKit
    local savedBest = K.BestMap
    local RA = WeintCodex.UIRares
    local ok, err = pcall(function()
        assert(RA.NpcId("Creature-0-1465-0-2105-61-00001A2F3C") == 61 and RA.NpcId("Player-1-0ABC") == nil
            and RA.NpcId(nil) == nil and RA.NpcId("Pet-0-1-0-1-61-0000") == nil
            and RA.NpcId("GameObject-0-1-0-1-61-0000") == nil, "NPC-Nummer aus der GUID (nur Kreaturen)")
        local info = RA.Info(61)
        assert(info and info.name == "Thuros Lightfingers" and info.lv1 == 11 and info.placeholder and info.rs1 == 5400
            and info.pos[1][1] == 1429, "Bestand: Thuros")
        assert(RA.Info(1) == nil, "Gegner erfunden")
        assert(RA.RespawnText(info) == "Wiederkehr in Classic 1:30–2:30 h", "Wiederkehr: " .. tostring(RA.RespawnText(info)))
        assert(RA.Describe(info) == "Stufe 11", "Beschreibung: " .. RA.Describe(info))

        local now, guid, cls, dead, inside = 1000, "Creature-0-1-0-1-61-0000AAAA", "normal", false, false
        local sounds, lines = 0, {}
        G.GetTime = function() return now end
        G.UnitExists = function() return true end
        G.UnitIsPlayer = function() return false end
        G.UnitGUID = function() return guid end
        G.UnitClassification = function() return cls end
        G.UnitName = function() return "Thuros Lightfingers" end
        G.UnitLevel = function() return 11 end
        G.UnitIsDead = function() return dead end
        G.IsInInstance = function() return inside, inside and "party" or "none" end
        G.SOUNDKIT = { RAID_WARNING = 8959 }
        G.PlaySound = function() sounds = sounds + 1 end
        G.print = function(...) lines[#lines + 1] = table.concat({ ... }, " ") end
        K.BestMap = function() return 1429 end

        -- Aus: nichts.
        K.Set("comfort", "rareAlert", false)
        assert(RA.CheckUnit("nameplate3", "nameplate") == false and #lines == 0, "gemeldet, obwohl aus")
        K.Set("comfort", "rareAlert", true)
        stub.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate3")
        assert(#lines == 1 and lines[1]:find("Thuros Lightfingers", 1, true) and sounds == 1, "Plakette nicht gemeldet")
        assert(RA.toast:IsShown() and RA.toast.title:GetText():find("Thuros", 1, true)
            and RA.toast.sub:GetText():find("Wiederkehr in Classic", 1, true), "Hinweis fehlt")
        -- Hoechstens alle 5 Minuten.
        stub.FireEvent("PLAYER_TARGET_CHANGED")
        assert(#lines == 1, "zweimal gemeldet")
        now = now + RA.REALERT + 1
        stub.FireEvent("UPDATE_MOUSEOVER_UNIT")
        assert(#lines == 2, "nach 5 Minuten nicht wieder gemeldet")
        -- Gemerkt: wann, wo (deine Lage).
        local mem = RA.Memory()
        assert(mem[61] and mem[61].name == "Thuros Lightfingers" and mem[61].map == 1429, "nicht gemerkt")
        -- Gewoehnlicher Gegner, nicht im Bestand: nichts.
        guid = "Creature-0-1-0-1-424242-0000AAAA"
        assert(RA.CheckUnit("target", "target") == false and #lines == 2, "gewoehnlicher Gegner gemeldet")
        -- Der Client sagt "selten", der Bestand kennt ihn nicht: melden, ehrlich.
        cls = "rareelite"
        G.UnitName = function() return "Unbekannter Schrecken" end
        assert(RA.CheckUnit("target", "target") == true and lines[3]:find("nicht im Bestand", 1, true)
            and lines[3]:find("Elite", 1, true), "Seltener nur vom Client nicht gemeldet: " .. tostring(lines[3]))
        -- Tot: gemerkt, nicht gemeldet.
        guid, dead = "Creature-0-1-0-1-79-0000AAAA", true
        assert(RA.CheckUnit("target", "target") == false and #lines == 3 and mem[79] and mem[79].dead, "Toter gemeldet")
        -- In Instanzen nur auf Wunsch.
        dead, inside = false, true
        assert(RA.CheckUnit("target", "target") == false, "in der Instanz gemeldet")
        inside = false
        -- Spieler nie.
        G.UnitIsPlayer = function() return true end
        guid = "Creature-0-1-0-1-100-0000AAAA"
        assert(RA.CheckUnit("target", "target") == false, "Spieler gemeldet")
        G.UnitIsPlayer = function() return false end

        -- Minikarte: Vignetten.
        G.C_VignetteInfo = {
            GetVignettes = function() return { "v1", "v2" } end,
            GetVignetteInfo = function(v)
                if v == "v1" then return { objectGUID = "Creature-0-1-0-1-462-0000", name = "Vultros", atlasName = "VignetteKill" } end
                return { objectGUID = "GameObject-0-1-0-1-5-0", name = "Truhe", atlasName = "VignetteLoot" }
            end,
        }
        assert(RA.ScanVignettes() == 1 and lines[#lines]:find("Vultros", 1, true), "Vignette nicht gemeldet")

        -- Bericht fuer das Gebiet.
        local rep = table.concat(RA.Report(), "\n")
        assert(rep:find("Thuros Lightfingers", 1, true) and rep:find("zuletzt gesehen", 1, true)
            and rep:find("Classic", 1, true), "Bericht: " .. rep)

        -- Selbstpruefung.
        local SC = WeintCodex.UISelfCheck
        local out = {}
        for _, c in ipairs(SC.CHECKS) do
            if c.name == "Seltene Gegner" then c.fn(function(mark, text) out[#out + 1] = (mark ~= "" and (mark .. " ") or "") .. text end) end
        end
        local txt = table.concat(out, "\n")
        assert(txt:find("im Bestand", 1, true) and txt:find("Zuletzt gemeldet: Vultros", 1, true), "Selbstpruefung: " .. txt)
    end)
    for i, n in ipairs(names) do G[n] = saved[i] end
    K.BestMap = savedBest
    K.Set("comfort", "rareAlert", false)
    if RA.toast then RA.toast:Hide() end
    Check(ok, "Seltene Gegner: Client oder Bestand, Ton/Chat/Hinweis, 5 Minuten, tot, Instanz, Vignette, Bericht"
        .. (ok and "" or (": " .. tostring(err))))
end

-- 6.17.0.0: Auktionspreise - Vollscan, sonst Suche Seite um Seite (erst,
-- wenn das Auktionshaus Anfragen nimmt), nebenbei die eigene Suche; eine
-- Zahl je Gegenstand; Tooltip mit Preis, Menge, Tag, Stapel; je Seite.
do
    local G = _G
    local names = { "C_AuctionHouse", "AuctionHouseFrame", "UnitFactionGroup", "C_Container", "print", "Enum" }
    local saved = {}
    for i, n in ipairs(names) do saved[i] = G[n] end
    local K = WeintCodex.UIKit
    local savedBest = K.BestMap
    local AP = WeintCodex.UIAuctionPrices
    local savedBatch = AP.BATCH
    local savedHook = AP.OnOwnScanHook
    local savedAuction = WeintCodex.SavedData.auction
    local gt = G.GameTooltip
    local savedAdd, savedAdd2, savedPrim = gt.AddLine, gt.AddDoubleLine, gt.GetPrimaryTooltipInfo
    local ok, err = pcall(function()
        -- Eine Zahl je Gegenstand: Preis, Menge, Tag.
        local p, q, d = AP.Unpack(AP.Pack(123456789, 42, 280))
        assert(p == 123456789 and q == 42 and d == 280, "Packen: " .. p .. "/" .. q .. "/" .. d)
        p, q, d = AP.Unpack(AP.Pack(AP.PRICE_MAX, 5000, 9999))
        assert(p == AP.PRICE_MAX and q == AP.QTY_MAX and d == AP.DAY_MAX, "Packen an der Grenze")
        local sh
        p, q, d, sh = AP.Unpack(AP.Pack(AP.PRICE_MAX, 999, AP.DAY_MAX, true))
        assert(p == AP.PRICE_MAX and q == 999 and d == AP.DAY_MAX and sh == true, "Packen: von Spielern")
        assert(select(4, AP.Unpack(AP.Pack(5, 1, 0))) == false, "eigener Preis als fremd")
        p = AP.Unpack(AP.Pack(AP.PRICE_MAX * 10, 1, 1))
        assert(p == AP.PRICE_MAX, "zu teuer nicht gekappt")
        for _, v in ipairs({ { 899999998, 999, 4998 }, { 1, 0, 0 }, { 7, 1, 1 } }) do
            local a, b, c = AP.Unpack(AP.Pack(v[1], v[2], v[3]))
            assert(a == v[1] and b == v[2] and c == v[3], "Packen: " .. v[1])
        end
        assert(AP.Day(os.time({ year = 2026, month = 1, day = 1, hour = 12 })) == 0
            and AP.Day(os.time({ year = 2026, month = 3, day = 1, hour = 12 })) == 59, "Tagesnummer")
        assert(AP.AgeText(10, 10) == "heute" and AP.AgeText(9, 10) == "gestern" and AP.AgeText(5, 10) == "vor 5 Tagen", "Alter")
        assert(AP.Money(12345) == "1 G 23 S 45 K" and AP.Money(80) == "80 K", "Geld: " .. AP.Money(12345))

        local lines = {}
        G.print = function(...) lines[#lines + 1] = table.concat({ ... }, " ") end
        G.UnitFactionGroup = function() return "Horde" end
        G.AuctionHouseFrame = CreateFrame("Frame")
        WeintCodex.SavedData.auction = nil
        local map = 1454
        K.BestMap = function() return map end

        -- Der Client: Vollscan mit 0-basierten Nummern, Suche in Seiten.
        local rep, calls = {}, { replicate = 0, query = 0, more = 0 }
        local repN, ready, full, results, queryFails = 0, true, false, {}, 0
        G.C_AuctionHouse = {
            ReplicateItems = function() calls.replicate = calls.replicate + 1 end,
            GetNumReplicateItems = function() return repN end,
            GetReplicateItemInfo = function(i)
                local r = rep[i + 1]
                assert(r, "Vollscan: Nummer " .. i .. " gibt es nicht")
                return "x", 1, r[2], 1, true, 1, 0, 1, 1, r[3], 0, false, nil, nil, nil, 0, r[1], true
            end,
            SendBrowseQuery = function(q)
                calls.query = calls.query + 1
                if queryFails > 0 then queryFails = queryFails - 1 error("bad query") end
                assert(q.searchString == "", "Suche nicht leer")
            end,
            RequestMoreBrowseResults = function() calls.more = calls.more + 1 end,
            GetBrowseResults = function() return results end,
            HasFullBrowseResults = function() return full end,
            IsThrottledMessageSystemReady = function() return ready end,
        }
        local function Fire(e) AP.OnEvent(nil, e) end
        local function Store(side) return WeintCodex.SavedData.auction["Testrealm|" .. side] end

        -- Aus: nichts, auch kein Scan.
        K.Set("comfort", "ahPrices", false)
        assert(AP.Start() == false and calls.replicate == 0, "Scan, obwohl aus")
        K.Set("comfort", "ahPrices", true)
        assert(AP.Start() == false and lines[#lines]:find("Erst das Auktionshaus", 1, true), "Scan ohne Auktionshaus")
        Fire("AUCTION_HOUSE_SHOW")
        assert(AP.button and AP.button:IsShown() and AP.button:GetText() == "Preise scannen", "Knopf am Auktionshaus fehlt")

        -- 1. Vollscan: guenstigstes Angebot je Stueck, Menge zusammen,
        -- nur Sofortkauf; in Stuecken zu AP.BATCH je Bild.
        rep = { { 100, 5, 500 }, { 100, 1, 80 }, { 200, 1, 0 }, { 300, 20, 2000000 }, { 100, 2, 300 } }
        repN = #rep
        AP.BATCH = 2
        local hooked
        AP.OnOwnScanHook = function(side) hooked = side end
        assert(AP.Start() == true and calls.replicate == 1 and AP.Phase() == "replicate", "Vollscan nicht angefragt")
        assert(AP.Start() == false, "zweiter Scan gleichzeitig")
        Fire("REPLICATE_ITEM_LIST_UPDATE")
        assert(AP.Phase() == "read", "Ereignis nicht gelesen")
        AP.Step(0.01)
        assert(AP.Phase() == "read" and AP.button:GetText():find("40 %%"), "Stueckweise: " .. tostring(AP.button:GetText()))
        AP.Step(0.01) AP.Step(0.01)
        assert(not AP.Scanning(), "Vollscan nicht fertig")
        assert(hooked == "Horde", "Spielernetz nicht ueber den eigenen Scan unterrichtet")
        local st = Store("Horde")
        local function Get(id) return AP.Unpack(st.items[id]) end
        p, q = Get(100)
        assert(p == 80 and q == 8, "Preis/Menge 100: " .. p .. "/" .. q)
        assert(st.items[200] == nil, "Gebot ohne Sofortkauf gespeichert")
        assert(select(1, Get(300)) == 100000 and st.full and st.via == "Vollscan" and st.lots == 4 and st.n == 2, "Vollscan-Ablage")
        assert(lines[#lines]:find("4 Angebote, 2 Gegenstände", 1, true), "Meldung: " .. lines[#lines])
        AP.BATCH = savedBatch
        -- Keine 15 Minuten spaeter: kein zweiter Vollscan, gleich die Suche.
        AP.Start()
        assert(calls.replicate == 1 and AP.Phase() == "browse" and table.concat(AP.log, " "):find("keine 15 Minuten", 1, true),
            "Vollscan vor Ablauf der 15 Minuten")
        AP.Step(AP.STALL)
        assert(not AP.Scanning(), "Suche nicht beendet")
        calls.query = 0
        -- Ohne Ereignis: zweimal dieselbe Zahl hintereinander heisst fertig.
        st.replicateAt = 0
        AP.Start()
        AP.Step(1) AP.Step(1)
        assert(AP.Phase() == "replicate", "zu frueh gelesen")
        AP.Step(1)
        assert(AP.Phase() == "read" and table.concat(AP.log, " "):find("ohne Ereignis", 1, true), "ohne Ereignis nicht gelesen")
        AP.Step(0) AP.Step(0) AP.Step(0)
        assert(not AP.Scanning() and calls.replicate == 2, "Vollscan ohne Ereignis nicht fertig")
        calls.replicate = 1

        -- Tooltip: Preis, Menge, Tag; Stapel aus der Tasche; nur, was bekannt ist.
        local tl = {}
        gt.AddDoubleLine = function(_, l, r) tl[#tl + 1] = l .. " = " .. r end
        gt.AddLine = function(_, l) tl[#tl + 1] = l end
        gt.GetPrimaryTooltipInfo = function() return { getterName = "GetBagItem", getterArgs = { 0, 3 } } end
        G.C_Container = { GetContainerItemInfo = function(b, sl) return (b == 0 and sl == 3) and { stackCount = 20 } or nil end }
        AP.OnItem(gt, { id = 100 })
        local txt = table.concat(tl, "\n")
        assert(tl[1] == "Auktionshaus = ab 80 K" and tl[2] == "Stapel (20) = 16 S" and tl[3] == "heute · 8 Stück im Angebot",
            "Tooltip: " .. txt)
        tl = {}
        K.Set("comfort", "ahStack", false)
        AP.OnItem(gt, { id = 100 })
        assert(#tl == 2, "Stapel trotz Schalter")
        K.Set("comfort", "ahStack", true)
        tl = {}
        AP.OnItem(gt, { id = 999 })
        local other = CreateFrame("Frame")
        other.AddDoubleLine, other.AddLine = gt.AddDoubleLine, gt.AddLine
        AP.OnItem(other, { id = 100 })
        assert(#tl == 0, "Preis erfunden oder fremder Tooltip: " .. table.concat(tl, " | "))
        K.Set("comfort", "ahPrices", false)
        AP.OnItem(gt, { id = 100 })
        assert(#tl == 0, "Tooltip, obwohl aus")
        K.Set("comfort", "ahPrices", true)
        Fire("AUCTION_HOUSE_SHOW")

        -- 2. Der Server schweigt zum Vollscan: nach AP.REPLICATE_WAIT s die
        -- Suche; erste Form abgelehnt, zweite genommen; weitere Seiten erst,
        -- wenn das Auktionshaus Anfragen nimmt.
        st.replicateAt = 0
        repN = 0
        queryFails = 1
        assert(AP.Start() == true and calls.replicate == 2, "zweiter Vollscan nicht angefragt")
        for _ = 1, AP.REPLICATE_WAIT - 1 do AP.Step(1) end
        assert(AP.Phase() == "replicate", "zu frueh aufgegeben")
        AP.Step(1)
        assert(AP.Phase() == "browse" and calls.query == 2 and (st.noReplicate or 0) > os.time(), "keine Suche nach dem Schweigen")
        results = { { itemKey = { itemID = 400 }, minPrice = 5000, totalQuantity = 3 },
                    { itemKey = { itemID = 100 }, minPrice = 70, totalQuantity = 12 } }
        ready = false
        Fire("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED")
        assert(calls.more == 0 and AP.Phase() == "browse", "weitere Seite trotz Drosselung")
        ready = true
        AP.Step(0.1)
        assert(calls.more == 1, "weitere Seite nicht angefragt (Takt)")
        results[3] = { itemKey = { itemID = 500 }, minPrice = 999, totalQuantity = 1 }
        ready = false
        Fire("AUCTION_HOUSE_BROWSE_RESULTS_ADDED")
        assert(calls.more == 1, "dritte Seite trotz Drosselung")
        ready = true
        Fire("AUCTION_HOUSE_THROTTLED_SYSTEM_READY")
        assert(calls.more == 2, "weitere Seite nicht angefragt (Ereignis)")
        results[4] = { itemKey = { itemID = 450 }, minPrice = 9, totalQuantity = 1 }
        full = true
        Fire("AUCTION_HOUSE_BROWSE_RESULTS_ADDED")
        assert(not AP.Scanning() and st.via == "Suche" and st.n == 4 and st.lots == 4, "Suche nicht fertig: " .. tostring(st.via))
        assert(select(1, Get(100)) == 70 and select(1, Get(400)) == 5000, "Preise aus der Suche")

        -- 300 war beim letzten vollstaendigen Scan nicht dabei.
        st.items[300] = AP.Pack(100000, 20, AP.Day() - 2)
        tl = {}
        gt.GetPrimaryTooltipInfo = nil
        AP.OnItem(gt, { id = 300 })
        assert(tl[2] == "zuletzt vor 2 Tagen · beim letzten Scan nicht im Angebot", "Fehlt: " .. table.concat(tl, " | "))

        -- 3. Drei Tage lang gleich die Suche; ohne neue Seite nach AP.STALL s
        -- ist Schluss - ohne Ergebnis ehrlich gesagt.
        full, results = false, {}
        AP.Start()
        assert(calls.replicate == 2 and AP.Phase() == "browse" and table.concat(AP.log, " "):find("zuletzt nicht", 1, true),
            "Vollscan trotz Schweigen")
        AP.Step(AP.STALL)
        assert(not AP.Scanning() and AP.last.ok == false and lines[#lines]:find("keine Preise", 1, true), "Stillstand")

        -- 4. Nebenbei: deine eigene Suche.
        results = { { itemKey = { itemID = 600 }, minPrice = 1234, totalQuantity = 2 } }
        Fire("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED")
        assert(st.items[600] and select(1, Get(600)) == 1234, "eigene Suche nicht gemerkt")
        K.Set("comfort", "ahPassive", false)
        results = { { itemKey = { itemID = 601 }, minPrice = 1, totalQuantity = 1 } }
        Fire("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED")
        assert(st.items[601] == nil, "eigene Suche trotz Schalter")
        K.Set("comfort", "ahPassive", true)

        -- 5. Geschlossen mitten im Scan: behalten, was da ist, unvollstaendig.
        results = { { itemKey = { itemID = 700 }, minPrice = 10, totalQuantity = 1 } }
        st.full = 1
        local fullBefore = st.full
        AP.Start()
        Fire("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED")
        Fire("AUCTION_HOUSE_CLOSED")
        assert(not AP.Scanning() and st.items[700] and st.full == fullBefore and AP.last.full == false, "geschlossen im Scan")

        -- 6. Neutral (Gadgetzan): eigene Ablage; die Horde sieht sie im
        -- Tooltip, wenn ihre eigene nichts weiss.
        map = 1446
        Fire("AUCTION_HOUSE_SHOW")
        results, full = { { itemKey = { itemID = 800 }, minPrice = 555, totalQuantity = 4 } }, true
        AP.Start()
        Fire("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED")
        assert(Store("Neutral") and Store("Neutral").items[800] and st.items[800] == nil, "neutral nicht getrennt")
        Fire("AUCTION_HOUSE_CLOSED")
        tl = {}
        AP.OnItem(gt, { id = 800 })
        assert(tl[1] == "Auktionshaus (neutral) = ab 5 S 55 K", "neutral im Tooltip: " .. tostring(tl[1]))

        -- Nach 30 Tagen faellt es heraus.
        st.items[900] = AP.Pack(1, 1, AP.Day() - AP.KEEP_DAYS - 1)
        AP.Prune(st)
        assert(st.items[900] == nil and st.items[100], "Aufraeumen")

        -- Bericht, Selbstpruefung, Seite.
        local r = table.concat(AP.Report(), "\n")
        assert(r:find("Auktionshaus Horde", 1, true) and r:find("Auktionshaus neutral", 1, true) and r:find("Schritte", 1, true)
            and r:find("kein Durchschnitt", 1, true), "Bericht: " .. r)
        local SC = WeintCodex.UISelfCheck
        local out = {}
        for _, c in ipairs(SC.CHECKS) do
            if c.name == "Auktionspreise" then c.fn(function(mark, text) out[#out + 1] = (mark ~= "" and (mark .. " ") or "") .. text end) end
        end
        local sc = table.concat(out, "\n")
        assert(sc:find("Vollscan (ReplicateItems): ja", 1, true) and sc:find("Letzter Scan", 1, true), "Selbstpruefung: " .. sc)
        local page
        for _, pg in ipairs(K.Module("comfort").pages) do if pg.key == "auktion" then page = pg end end
        assert(page and page.label == "Auktionshaus", "Seite im Komfort fehlt")
        -- Aus: Knopf weg, nichts registriert.
        K.Set("comfort", "ahPrices", false)
        assert(not AP.button:IsShown(), "Knopf bleibt, obwohl aus")
    end)
    for i, n in ipairs(names) do G[n] = saved[i] end
    gt.AddLine, gt.AddDoubleLine, gt.GetPrimaryTooltipInfo = savedAdd, savedAdd2, savedPrim
    K.BestMap = savedBest
    AP.BATCH = savedBatch
    AP.OnOwnScanHook = savedHook
    K.Set("comfort", "ahPrices", false)
    WeintCodex.SavedData.auction = savedAuction
    Check(ok, "Auktionspreise: Vollscan, Suche nach Schweigen, Drosselung, eigene Suche, Tooltip, Stapel, neutral, 30 Tage"
        .. (ok and "" or (": " .. tostring(err))))
end

-- 6.18.0.0: Auktionspreise von anderen Spielern. Gilde: fragen, anbieten,
-- waehlen, in Stuecken senden - nur Eigenes aus dem letzten vollstaendigen
-- Scan. ForeverGuide: nur zuhoeren. Fremde Preise: eigener Realm, nicht
-- aelter, eigener Preis vom selben Tag geht vor, Ausreisser erst bestaetigt.
do
    local G = _G
    local names = { "GetTime", "GetServerTime", "UnitName", "UnitFactionGroup", "IsInGuild", "InCombatLockdown",
                    "C_ChatInfo", "GetChannelName", "JoinTemporaryChannel", "LeaveChannelByName", "C_AddOns", "IsLoggedIn" }
    local saved = {}
    for i, n in ipairs(names) do saved[i] = G[n] end
    local K = WeintCodex.UIKit
    local AP, AS = WeintCodex.UIAuctionPrices, WeintCodex.UIAuctionShare
    local savedAuction = WeintCodex.SavedData.auction
    local ok, err = pcall(function()
        local E = AS.E
        assert(E(0) == "0" and E(35) == "z" and E(36) == "10" and AS.D("10") == 36 and AS.D("zz") == 1295, "Basis 36")
        local clock, combat, inGuild = 1000, false, true
        local OFFSET = 7200                       -- die Uhr des Servers geht zwei Stunden vor
        G.GetTime = function() return clock end
        G.GetServerTime = function() return os.time() + OFFSET end
        G.UnitName = function() return "Ich" end
        G.UnitFactionGroup = function() return "Horde" end
        G.IsInGuild = function() return inGuild end
        G.InCombatLockdown = function() return combat end
        G.IsLoggedIn = function() return true end
        local sent, prefixes = {}, {}
        G.C_ChatInfo = {
            SendAddonMessage = function(prefix, msg, kind) sent[#sent + 1] = { prefix, msg, kind } return 0 end,
            RegisterAddonMessagePrefix = function(pf) prefixes[pf] = true end,
        }
        local chan, joins, leaves, fgLoaded = 0, 0, 0, true
        G.GetChannelName = function(n) return (n == "FGLayers" and chan > 0) and chan or 0 end
        G.JoinTemporaryChannel = function(n) if n == "FGLayers" then chan, joins = 5, joins + 1 end end
        G.LeaveChannelByName = function() chan, leaves = 0, leaves + 1 end
        G.C_AddOns = { IsAddOnLoaded = function(n) return n == "ForeverGuide" and fgLoaded end }
        local function Msg(text, sender, prefix, channel)
            AS.OnAddonMessage(prefix or "WCAH", text, channel or "GUILD", sender, clock)
        end
        local function Run(secs) for _ = 1, secs do clock = clock + 1 AS.Step(clock) end end
        local function Server() return os.time() + OFFSET end

        WeintCodex.SavedData.auction = nil
        local today = AP.Day()
        local st = AP.Store("Horde", true)
        st.full = os.time() - 60
        st.items[100] = AP.Pack(80, 8, today)
        st.items[300] = AP.Pack(100000, 20, today)
        st.items[555] = AP.Pack(1, 1, today - 3)          -- nicht im letzten Scan
        st.items[777] = AP.Pack(5, 1, today, true)        -- von Spielern: nie weiterreichen

        -- Aus: nichts gehoert, nichts gesendet.
        K.Set("comfort", "ahPrices", true)
        K.Set("comfort", "ahShareGuild", false)
        Msg("W:1:H:" .. E(Server()) .. ":Ich", "Anna")
        AS.OnOwnScan("Horde")
        Run(10)
        assert(#sent == 0, "gesendet, obwohl aus")

        K.Set("comfort", "ahShareGuild", true)
        assert(prefixes.WCAH, "Kennung nicht angemeldet")
        -- Eigener Scan: angeboten, nur Eigenes aus dem letzten Scan gezaehlt.
        AS.OnOwnScan("Horde")
        Run(7)
        assert(#sent == 1 and sent[1][1] == "WCAH" and sent[1][3] == "GUILD"
            and sent[1][2] == "O:1:H:" .. E(AS.ToServer(st.full)) .. ":2", "Angebot: " .. tostring(sent[1] and sent[1][2]))

        -- Frage von Anna (alt): ich biete an - es sei denn, Bob kommt zuvor.
        Msg("Q:1:H:" .. E(Server() - 3600), "Anna")
        assert(AS.pendingOffer.Horde, "Frage nicht beantwortet")
        Msg("O:1:H:" .. E(AS.ToServer(st.full)) .. ":9", "Bob")
        assert(AS.pendingOffer.Horde == nil, "doppeltes Angebot")
        Run(5)
        assert(#sent == 1, "trotzdem angeboten")

        -- Nicht frischer als ich: kein Angebot. Gefluestert oder von mir selbst:
        -- zaehlt nicht. Gewaehlt ist ein anderer: nichts.
        Msg("Q:1:H:" .. E(AS.ToServer(st.full)), "Anna")
        Msg("Q:1:H:" .. E(Server() - 3600), "Ich")
        Msg("Q:1:H:" .. E(Server() - 3600), "Anna", "WCAH", "WHISPER")
        assert(AS.pendingOffer.Horde == nil, "Angebot ohne Grund")
        Msg("W:1:H:" .. E(AS.ToServer(st.full)) .. ":Bob", "Anna")
        Msg("W:1:H:" .. E(AS.ToServer(st.full)) .. ":Ich", "Anna", "WCAH", "WHISPER")
        assert(AS.QueueSize() == 0, "gesendet, obwohl ein anderer gewaehlt war")
        -- Anna waehlt mich: der Scan in Stuecken an die Gilde, eine je Sekunde.
        Msg("W:1:H:" .. E(AS.ToServer(st.full)) .. ":Ich-Testrealm", "Anna")
        assert(AS.QueueSize() == 1, "Scan nicht eingereiht: " .. AS.QueueSize())
        combat = true
        Run(3)
        assert(#sent == 1, "im Kampf gesendet")
        combat = false
        Run(2)
        local b = sent[2] and sent[2][2] or ""
        assert(b:find("^B:1:H:" .. E(AS.ToServer(st.full)) .. ":1:") and b:find(E(100) .. "," .. E(80) .. "," .. E(8), 1, true)
            and b:find(E(300) .. "," .. E(100000) .. "," .. E(20), 1, true)
            and not b:find(E(555) .. ",", 1, true) and not b:find(E(777) .. ",", 1, true), "Stuecke: " .. b)
        -- Dieselbe Seite nicht gleich noch einmal; ein anderer "Ich" ist nicht ich.
        Msg("W:1:H:" .. E(AS.ToServer(st.full)) .. ":Ich", "Carl")
        Msg("W:1:H:" .. E(AS.ToServer(st.full)) .. ":Ich-Andersrealm", "Carl")
        assert(AS.QueueSize() == 0, "zweimal gesendet")

        -- Empfangen von Anna (frischer): neue Gegenstaende ja; mein Preis vom
        -- selben Tag bleibt; Ausreisser erst mit zweitem Spieler.
        local fresh = Server()
        Msg("B:1:H:" .. E(fresh) .. ":1:" .. E(400) .. "," .. E(1234) .. "," .. E(3) .. ";" .. E(100) .. "," .. E(70) .. ",1;"
            .. E(555) .. "," .. E(50) .. ",1", "Anna-Testrealm")
        local p, q, d, sh = AP.Unpack(st.items[400])
        assert(p == 1234 and q == 3 and sh == true and d == today, "fremder Preis nicht uebernommen")
        assert(select(1, AP.Unpack(st.items[100])) == 80, "eigener Preis vom selben Tag ueberschrieben")
        assert(select(1, AP.Unpack(st.items[555])) == 1 and AS.held[555], "Ausreisser sofort uebernommen")
        Msg("B:1:H:" .. E(fresh) .. ":2:" .. E(555) .. "," .. E(55) .. ",2", "Anna")
        assert(select(1, AP.Unpack(st.items[555])) == 1, "Ausreisser vom selben Absender bestaetigt")
        Run(1)
        assert(st.shared == nil, "Empfang vor der Stille beendet")
        Msg("B:1:H:" .. E(fresh - 1) .. ":1:" .. E(555) .. "," .. E(60) .. ",2", "Bob")
        assert(select(1, AP.Unpack(st.items[555])) == 60, "bestaetigter Ausreisser nicht uebernommen")
        -- Tooltip: "von Spielern".
        local lines = AP.TooltipLines(400)
        assert(lines[2][1] == "von Spielern, heute · 3 Stück im Angebot", "Tooltip: " .. tostring(lines[2][1]))
        -- Fremder Realm, ich selbst, Zukunft: nichts.
        assert(AS.OnBulk("Zed-Andersrealm", "Gilde", "Horde", fresh, E(401) .. ",1,1", clock) == 0
            and AS.OnBulk("Ich", "Gilde", "Horde", fresh, E(402) .. ",1,1", clock) == 0
            and AS.OnBulk("Zed", "Gilde", "Horde", Server() + 3600, E(403) .. ",1,1", clock) == 0
            and st.items[401] == nil and st.items[402] == nil and st.items[403] == nil, "falscher Absender angenommen")
        -- Fertig nach AS.IDLE s Stille: gemerkt, von wem.
        Run(AS.IDLE + 1)
        assert(type(st.shared) == "table" and st.shared.from == "Anna" and st.shared.via == "Gilde" and st.shared.stamp == fresh,
            "Empfang nicht gemerkt")
        -- Ein ganzer Scan, aelter als meiner: zaehlt nicht.
        local ign = AS.stats.ignored
        Msg("B:1:H:" .. E(fresh - 3600) .. ":1:" .. E(404) .. ",1,1", "Dora")
        assert(st.items[404] == nil and AS.stats.ignored == ign + 1, "alter Scan angenommen")

        -- Als Fragender: meine Preise alt; zwei Angebote, der frischere gewinnt.
        st.full, st.shared = os.time() - 3 * 3600, nil
        Msg("O:1:H:" .. E(Server() - 300) .. ":40", "Dave")
        Msg("O:1:H:" .. E(Server() - 600) .. ":50", "Carl")
        local n0 = #sent
        Run(AS.WANT_WAIT + 1)
        assert(#sent == n0 + 1 and sent[#sent][2] == "W:1:H:" .. E(Server() - 300) .. ":Dave", "Wahl: " .. tostring(sent[#sent][2]))
        -- Regelmaessig fragen, wenn die eigenen Preise alt sind.
        n0 = #sent
        Run(AS.QUERY_EVERY + 2)
        assert(#sent == n0 + 1 and sent[#sent][2]:find("^Q:1:H:"), "Gilde nicht gefragt")

        -- ForeverGuide: beitreten (verzoegert), nur zuhoeren.
        K.Set("comfort", "ahListenFG", true)
        assert(joins == 0, "sofort beigetreten")
        Run(3)
        assert(joins == 1 and AS.joined and prefixes.FGD, "Kanal nicht beigetreten")
        local fgStamp = Server() - 60
        Msg("B:1:H:" .. E(fgStamp) .. ":3:" .. E(900) .. "," .. E(777) .. "," .. E(4), "Erik", "FGD", "CHANNEL")
        assert(st.items[900] and select(1, AP.Unpack(st.items[900])) == 777, "ForeverGuide nicht gelesen")
        -- Wie das Spiel es schickt: neun Angaben, die fuenfte ist der Name
        -- des Kanals (6.18.0.0 hielt sie fuer die Uhrzeit, Beta-Test).
        stub.FireEvent("CHAT_MSG_ADDON", "FGD", "B:1:H:" .. E(fgStamp) .. ":4:" .. E(905) .. "," .. E(42) .. ",1",
            "CHANNEL", "Flor Scyth", "5. FGLayers", 0, 5, "FGLayers", 0)
        assert(st.items[905] and select(1, AP.Unpack(st.items[905])) == 42, "Ereignis des Spiels nicht gelesen")
        for _, ib in pairs(AS.inbound) do assert(type(ib.last) == "number", "Empfangszeit ist keine Zahl: " .. tostring(ib.last)) end
        Msg("B:1:H:" .. E(fgStamp) .. ":3:" .. E(901) .. ",1,1", "Erik", "FGD", "GUILD")
        Msg("B:2:H:" .. E(fgStamp) .. ":3:" .. E(902) .. ",1,1", "Erik", "FGD", "CHANNEL")
        assert(st.items[901] == nil and st.items[902] == nil, "fremde Form angenommen")
        Run(AS.IDLE + 1)
        assert(st.shared.via == AS.VIA_CHANNEL and st.shared.from == "Erik", "Kanal nicht gemerkt")
        for _, m in ipairs(sent) do assert(m[1] == "WCAH" and m[3] == "GUILD", "in den Kanal gesendet") end
        -- Aus: Kanal bleibt, solange ForeverGuide selbst laeuft; sonst verlassen.
        K.Set("comfort", "ahListenFG", false)
        assert(leaves == 0 and not AS.joined, "Kanal von ForeverGuide verlassen")
        K.Set("comfort", "ahListenFG", true)
        Run(2)
        fgLoaded = false
        K.Set("comfort", "ahListenFG", false)
        assert(leaves == 1, "Kanal nicht verlassen")
        Msg("B:1:H:" .. E(Server()) .. ":3:" .. E(903) .. ",1,1", "Erik", "FGD", "CHANNEL")
        assert(st.items[903] == nil, "gelesen, obwohl aus")

        -- Bericht und Selbstpruefung.
        local r = table.concat(AP.Report(), "\n")
        assert(r:find("Mit der Gilde teilen: an", 1, true) and r:find("Zuletzt von Spielern", 1, true)
            and r:find("Von anderen Auktions-Addons übernehmen: aus", 1, true)
            and r:find("(andere Auktions-Addons)", 1, true) and not r:find("ForeverGuide", 1, true), "Bericht: " .. r)
        -- Frueher gemerkt als "ForeverGuide": gezeigt ohne den Namen.
        st.shared.via = "ForeverGuide"
        r = table.concat(AP.Report(), "\n")
        assert(not r:find("ForeverGuide", 1, true), "alter Name im Bericht: " .. r)
        local SC = WeintCodex.UISelfCheck
        local out = {}
        for _, c in ipairs(SC.CHECKS) do
            if c.name == "Auktionspreise" then c.fn(function(mark, text) out[#out + 1] = text end) end
        end
        assert(table.concat(out, "\n"):find("SendAddonMessage: ja", 1, true), "Selbstpruefung")

        -- Frisch (eben von ForeverGuide): nicht fragen. Alt: fragen - und
        -- nach dem Ausschalten der Gilde nichts mehr senden.
        assert(AS.Query("Horde", clock) == false, "gefragt, obwohl frisch")
        st.shared = nil
        assert(AS.Query("Horde", clock) == true and AS.QueueSize() == 1, "nicht gefragt, obwohl alt")
        K.Set("comfort", "ahShareGuild", false)
        n0 = #sent
        Run(3)
        assert(#sent == n0, "gesendet nach dem Ausschalten")
    end)
    for i, n in ipairs(names) do G[n] = saved[i] end
    K.Set("comfort", "ahShareGuild", false)
    K.Set("comfort", "ahListenFG", false)
    K.Set("comfort", "ahPrices", false)
    WeintCodex.SavedData.auction = savedAuction
    Check(ok, "Auktionspreise teilen: Gilde fragt/bietet/waehlt/sendet, nur Eigenes, Empfang mit Regeln, ForeverGuide nur zuhoeren"
        .. (ok and "" or (": " .. tostring(err))))
end

-- 6.19.0.0: Fluestern als Messenger. Ein Fenster, links die Gespraeche,
-- rechts der Verlauf; im Kampf erst danach; Geheimes nur gezaehlt; nichts
-- in den gespeicherten Daten; Antworten ueber die Chatzeile des Spiels,
-- direkt nur auf Wunsch - gesperrt schaltet es sich selbst ab.
do
    local G = _G
    local names = { "GetNormalizedRealmName", "GetPlayerInfoByGUID", "InCombatLockdown", "issecretvalue",
                    "ChatFrame_OpenChat", "ChatFrameUtil", "ChatFrame_SendBNetTell", "C_ChatInfo", "BNSendWhisper",
                    "ERR_CHAT_PLAYER_NOT_FOUND_S", "print" }
    local saved = {}
    for i, n in ipairs(names) do saved[i] = G[n] end
    local K = WeintCodex.UIKit
    local MS = WeintCodex.UIMessenger
    local ok, err = pcall(function()
        local combat, secret = false, {}
        G.GetNormalizedRealmName = function() return "Testrealm" end
        G.GetPlayerInfoByGUID = function(g) if g == "Player-1-AAA" then return "Krieger", "WARRIOR" end end
        G.InCombatLockdown = function() return combat end
        G.issecretvalue = function(v) return secret[v] == true end
        G.ERR_CHAT_PLAYER_NOT_FOUND_S = "Kein Spieler namens '%s' ist derzeit gespielt."
        local opened, bnTell, lines = {}, {}, {}
        G.ChatFrameUtil = nil
        G.ChatFrame_OpenChat = function(t) opened[#opened + 1] = t end
        G.ChatFrame_SendBNetTell = function(n) bnTell[#bnTell + 1] = n end
        G.print = function(...) lines[#lines + 1] = table.concat({ ... }, " ") end
        local function W(text, sender, guid) MS.OnEvent(nil, "CHAT_MSG_WHISPER", text, sender, "", "", "", "", 0, 0, "", 0, 1, guid) end
        local function Out(text, target) MS.OnEvent(nil, "CHAT_MSG_WHISPER_INFORM", text, target, "", "", "", "", 0, 0, "", 0, 1, nil) end

        -- Aus: nichts.
        K.Set("comfort", "msgOn", false)
        W("hallo Welt", "Anna-Testrealm", "Player-1-AAA")
        assert(#MS.order == 0, "gemerkt, obwohl aus")
        K.Set("comfort", "msgOn", true)

        -- Eingehend: Gespraech, Klasse, Fenster geht auf, gelesen.
        MS.Build()
        local shown = {}
        MS.smf.AddMessage = function(_, t) shown[#shown + 1] = t end
        MS.smf.Clear = function() shown = {} end
        W("hallo Welt", "Anna-Testrealm", "Player-1-AAA")
        local a = MS.conv["w:Anna"]
        assert(a and a.name == "Anna" and a.class == "WARRIOR" and a.target == "Anna-Testrealm", "Gespraech mit Anna")
        -- Von selbst aufgegangen: ungelesen, bis du hinsiehst (6.19.1.1).
        assert(MS.win:IsShown() and MS.current == "w:Anna" and a.unread == 1, "Fenster nicht aufgegangen")
        assert(#shown == 1 and shown[1]:find("hallo Welt", 1, true) and shown[1]:find("Anna", 1, true), "Verlauf: " .. tostring(shown[1]))
        MS.win:GetScript("OnUpdate")(MS.win, 1)
        assert(a.unread == 1, "ohne Maus gelesen")
        -- Noch nicht gesehen: die naechste zaehlt dazu, auch im offenen Gespraech.
        W("bist du da?", "Anna-Testrealm", "Player-1-AAA")
        assert(a.unread == 2, "zweite ungesehene nicht gezaehlt: " .. a.unread)
        table.remove(a.lines)
        MS.win.IsMouseOver = function() return true end
        MS.win:GetScript("OnUpdate")(MS.win, 1)
        MS.win.IsMouseOver = nil
        assert(a.unread == 0, "Maus ueber dem Fenster: nicht gelesen")
        -- Offen und gewaehlt: gelesen, nicht ungelesen.
        W("noch was", "Anna-Testrealm", "Player-1-AAA")
        assert(a.unread == 0 and #a.lines == 2, "offenes Gespraech als ungelesen gezaehlt")
        -- Ein zweiter, waehrend Anna offen ist: Anna bleibt, Bob ungelesen.
        W("bist du da?", "Bob")
        assert(MS.current == "w:Anna" and MS.conv["w:Bob"].unread == 1, "Gespraech gewechselt")
        assert(MS.order[1] == "w:Bob" and MS.rows[1].badge:GetText() == "1", "Ungelesen nicht angezeigt")
        MS.Select("w:Bob")
        assert(MS.conv["w:Bob"].unread == 0 and #shown == 1, "Auswahl")

        -- Im Kampf: zu, bis der Kampf vorbei ist.
        MS.win:Hide()
        combat = true
        W("inv pls", "Carl")
        assert(not MS.win:IsShown() and MS.pending == "w:Carl", "im Kampf aufgegangen")
        combat = false
        MS.OnEvent(nil, "PLAYER_REGEN_ENABLED")
        assert(MS.win:IsShown() and MS.current == "w:Carl", "nach dem Kampf nicht aufgegangen")
        K.Set("comfort", "msgCombat", true)
        MS.win:Hide()
        combat = true
        W("noch da?", "Carl")
        assert(MS.win:IsShown(), "trotz Schalter nicht im Kampf aufgegangen")
        combat = false
        K.Set("comfort", "msgCombat", false)

        -- Geheim (Sperre des Spiels): nur gezaehlt, nie gelesen.
        local hidden = "geheimer Text"
        secret[hidden] = true
        local n0 = #MS.order
        W(hidden, "Dora")
        assert(MS.locked == 1 and #MS.order == n0 and MS.conv["w:Dora"] == nil, "Geheimes gelesen")
        -- Auch ein geheimer Absender, und Battle.net ohne Konto.
        local who = "Geheimname"
        secret[who] = true
        W("offen", who)
        MS.OnEvent(nil, "CHAT_MSG_BN_WHISPER", "offen", "|Kq7|k", "", "", "", "", 0, 0, "", 0, 1, "", nil)
        assert(MS.locked == 3 and #MS.order == n0, "geheimer Absender oder Konto gelesen")
        secret[who] = nil
        assert(MS.foot:GetText():find("Sperre", 1, true), "Sperre nicht genannt")
        secret[hidden] = nil

        -- Eigenes Fluestern: aufgehen nur auf Wunsch.
        MS.win:Hide()
        K.Set("comfort", "msgOutgoing", false)
        Out("treffen wir uns?", "Emil-Testrealm")
        assert(MS.conv["w:Emil"] and not MS.win:IsShown(), "bei eigenem Fluestern aufgegangen")
        K.Set("comfort", "msgOutgoing", true)
        Out("hallo?", "Emil-Testrealm")
        assert(MS.win:IsShown() and MS.conv["w:Emil"].lines[2].kind == "out", "eigenes Fluestern")

        -- Battle.net: an 13. Stelle die Nummer des Kontos.
        MS.OnEvent(nil, "CHAT_MSG_BN_WHISPER", "na du", "|Kq42|k", "", "", "", "", 0, 0, "", 0, 1, "", 42)
        local b = MS.conv["bn:42"]
        assert(b and b.bn and b.target == 42, "Battle.net-Gespraech")

        -- Abwesend und nicht online.
        MS.OnEvent(nil, "CHAT_MSG_AFK", "bin weg", "Anna-Testrealm")
        MS.OnEvent(nil, "CHAT_MSG_SYSTEM", "Kein Spieler namens 'Bob' ist derzeit gespielt.")
        MS.OnEvent(nil, "CHAT_MSG_SYSTEM", "Kein Spieler namens 'Fremder' ist derzeit gespielt.")
        local la, lb = MS.conv["w:Anna"].lines, MS.conv["w:Bob"].lines
        assert(la[#la].kind == "sys" and la[#la].text == "Abwesend: bin weg", "Abwesend")
        assert(lb[#lb].text == "Bob ist nicht online.", "nicht online")
        assert(MS.conv["w:Fremder"] == nil, "Gespraech fuer Fremden angelegt")

        -- Markieren (6.19.0.1): Textfeld nur zum Lesen, ohne Farben und
        -- Link-Kodes; tippen aendert nichts; Esc zurueck zum Verlauf.
        MS.win:Show()
        MS.Select("w:Anna")
        W("schau: |cff0070dd|Hitem:19019::::|h[Donnerzorn]|h|r", "Anna-Testrealm", "Player-1-AAA")
        MS.SetCopyMode(true)
        local txt = MS.copyEdit:GetText() or ""
        assert(MS.copy:IsShown() and not MS.smf:IsShown(), "Markieren nicht umgeschaltet")
        assert(txt:find("Anna: schau: [Donnerzorn]", 1, true) and txt:find("Abwesend: bin weg", 1, true)
            and txt:find("Anna: hallo Welt", 1, true) and not txt:find("|", 1, true), "Text zum Markieren: " .. txt)
        assert(MS.foot:GetText():find("Strg+C", 1, true), "Hinweis fehlt")
        MS.copyEdit:SetText("weg damit")
        MS.copyEdit:GetScript("OnTextChanged")(MS.copyEdit, true)
        assert(MS.copyEdit:GetText() == txt, "Text zum Markieren veraendert")
        MS.copyEdit:GetScript("OnEscapePressed")(MS.copyEdit)
        assert(not MS.copyMode and MS.smf:IsShown() and not MS.copy:IsShown(), "Esc fuehrt nicht zurueck")
        MS.markBtn:GetScript("OnClick")(MS.markBtn)
        assert(MS.copyMode, "Knopf Markieren")
        MS.markBtn:GetScript("OnClick")(MS.markBtn)
        assert(not MS.copyMode, "Knopf Markieren zurueck")

        -- Antworten: ab Werk ueber die Chatzeile des Spiels.
        MS.Select("w:Anna")
        MS.input:GetScript("OnEditFocusGained")(MS.input)
        assert(opened[#opened] == "/w Anna-Testrealm ", "Klick in die Antwortzeile: " .. tostring(opened[#opened]))
        assert(MS.Send("w:Anna", "gleich") == true and opened[#opened] == "/w Anna-Testrealm gleich", "Chatzeile: " .. tostring(opened[#opened]))
        MS.Send("bn:42", "ok")
        assert(bnTell[#bnTell] == 42, "Battle.net-Antwort")

        -- Direkt: gesendet; gesperrt -> abgeschaltet, gemerkt, Text in die Chatzeile.
        local sentDirect = {}
        G.C_ChatInfo = { SendChatMessage = function(t, kind, _, to) sentDirect[#sentDirect + 1] = { t, kind, to } end }
        K.Set("comfort", "msgDirect", true)
        assert(MS.Send("w:Anna", "direkt") == true and sentDirect[1][1] == "direkt" and sentDirect[1][2] == "WHISPER"
            and sentDirect[1][3] == "Anna-Testrealm", "direkt nicht gesendet")
        local nOpen = #opened
        G.C_ChatInfo.SendChatMessage = function() MS.OnEvent(nil, "ADDON_ACTION_BLOCKED", "WeintCodex", "SendChatMessage()") end
        assert(MS.Send("w:Anna", "gesperrt") == false, "Sperre nicht erkannt")
        assert(K.Get("comfort", "msgDirect") == false and WeintCodex.SavedData.ui.msgDirectBlocked
            and opened[nOpen + 1] == "/w Anna-Testrealm gesperrt" and lines[#lines]:find("nicht selbst", 1, true), "nach der Sperre")
        -- Eine Sperre eines anderen Addons zaehlt nicht.
        assert(MS.OnBlocked("AnderesAddon") == false, "fremde Sperre gezaehlt")

        -- Grenzen: Zeilen je Gespraech, Zahl der Gespraeche; schliessen.
        for i = 1, MS.MAX_LINES + 5 do MS.Add(MS.conv["w:Anna"], "in", "z" .. i) end
        assert(#MS.conv["w:Anna"].lines == MS.MAX_LINES and MS.conv["w:Anna"].lines[MS.MAX_LINES].text == "z" .. (MS.MAX_LINES + 5), "Zeilen")
        for i = 1, MS.MAX_CONV + 1 do W("x", "Neu" .. i) end
        assert(#MS.order == MS.MAX_CONV and MS.conv["w:Anna"] == nil, "zu viele Gespraeche")
        local first = MS.order[1]
        MS.Select(first)
        MS.Close(first)
        assert(MS.conv[first] == nil and MS.current == MS.order[1], "Schliessen")

        -- Nichts davon in den gespeicherten Daten.
        local function Find(t, needle, seen)
            seen = seen or {}
            if seen[t] then return false end
            seen[t] = true
            for k, v in pairs(t) do
                if v == needle or k == needle then return true end
                if type(v) == "table" and Find(v, needle, seen) then return true end
            end
            return false
        end
        assert(not Find(WeintCodex.SavedData, "hallo Welt") and not Find(WeintCodex.SavedData, "bist du da?"), "Fluestern gespeichert")

        -- Selbstpruefung, Seite, Befehl.
        local SC = WeintCodex.UISelfCheck
        local out = {}
        for _, c in ipairs(SC.CHECKS) do
            if c.name == "Flüstern" then c.fn(function(_, text) out[#out + 1] = text end) end
        end
        local sc = table.concat(out, "\n")
        assert(sc:find("gemessen gesperrt", 1, true) and sc:find("SendChatMessage: ja", 1, true), "Selbstpruefung: " .. sc)
        local page
        for _, pg in ipairs(K.Module("comfort").pages) do if pg.key == "fluestern" then page = pg end end
        assert(page and page.label == "Flüstern", "Seite fehlt")
        K.Set("comfort", "msgOn", false)
        assert(not MS.win:IsShown(), "Fenster bleibt, obwohl aus")
    end)
    for i, n in ipairs(names) do G[n] = saved[i] end
    K.Set("comfort", "msgOn", false)
    K.Set("comfort", "msgDirect", false)
    if WeintCodex.SavedData.ui then WeintCodex.SavedData.ui.msgDirectBlocked = nil end
    Check(ok, "Fluestern: Fenster, Gespraeche, Kampf, Geheimes, eigenes, Battle.net, abwesend, Chatzeile, direkt/gesperrt, nichts gespeichert"
        .. (ok and "" or (": " .. tostring(err))))
end

-- 6.19.1.0 (Beta-Test: "das Fenster ist nicht verschiebbar", "Whisper
-- sollen nicht parallel auch im Chat zu sehen sein", "infight minimieren
-- und wieder aufploppen", "/w Name oder Name anklicken -> Fenster",
-- "ein Icon, damit ich die Whisper auch so wieder oeffnen kann").
do
    local G = _G
    local names = { "GetNormalizedRealmName", "InCombatLockdown", "issecretvalue", "ChatFrameUtil",
                    "ChatFrame_AddMessageEventFilter", "ChatFrame_OpenChat", "NUM_CHAT_WINDOWS", "ChatFrame1EditBox",
                    "hooksecurefunc", "ChatEdit_UpdateHeader", "BNet_GetBNetIDAccount", "PlaySound", "SOUNDKIT",
                    "FlashClientIcon", "GetTime", "ERR_CHAT_PLAYER_NOT_FOUND_S", "ChatFrame_ReplyTell",
                    "ChatEdit_GetActiveWindow", "ChatFrame_SendBNetTell", "C_Timer" }
    local saved = {}
    for i, n in ipairs(names) do saved[i] = G[n] end
    local K = WeintCodex.UIKit
    local MS = WeintCodex.UIMessenger
    local ok, err = pcall(function()
        local combat, secret, now = false, {}, 1000
        G.GetNormalizedRealmName = function() return "Testrealm" end
        G.InCombatLockdown = function() return combat end
        G.issecretvalue = function(v) return secret[v] == true end
        G.GetTime = function() return now end
        G.ChatFrameUtil = nil
        local opened = {}
        G.ChatFrame_OpenChat = function(t) opened[#opened + 1] = t end
        G.ChatFrame_SendBNetTell = function(id) opened[#opened + 1] = "bn:" .. tostring(id) end
        local filters, sounds, flashed = {}, 0, 0
        G.ChatFrame_AddMessageEventFilter = function(e, f) filters[e] = f end
        G.SOUNDKIT = { TELL_MESSAGE = 3081 }
        G.PlaySound = function(id) if id == 3081 then sounds = sounds + 1 end end
        G.FlashClientIcon = function() flashed = flashed + 1 end
        -- Die Chatzeile des Spiels: WeintCodex darf sie nur lesen.
        G.ERR_CHAT_PLAYER_NOT_FOUND_S = "Kein Spieler namens '%s' ist derzeit gespielt."
        G.NUM_CHAT_WINDOWS = 1
        local eb = CreateFrame("EditBox", nil, UIParent)
        G.ChatFrame1EditBox = eb
        local touched = {}
        for _, m in ipairs({ "SetText", "Insert", "Hide", "ClearFocus", "SetFocus" }) do
            eb[m] = function() touched[#touched + 1] = m end
        end
        local headerHook, replyHook
        G.ChatEdit_UpdateHeader = function() end
        G.ChatFrame_ReplyTell = function() end
        G.ChatEdit_GetActiveWindow = function() return eb end
        G.hooksecurefunc = function(name, fn)
            if name == "ChatEdit_UpdateHeader" then headerHook = fn end
            if name == "ChatFrame_ReplyTell" then replyHook = fn end
        end
        G.BNet_GetBNetIDAccount = function(n) if n == "Kumpel" then return 77 end end
        local function W(text, sender) MS.OnEvent(nil, "CHAT_MSG_WHISPER", text, sender, "", "", "", "", 0, 0, "", 0, 1, nil) end
        local function Filter(event, text, sender, ...) return filters[event](nil, event, text, sender, ...) end

        K.Set("comfort", "msgOn", false)
        K.Set("comfort", "msgOn", true)
        MS.Build()
        MS.win:Hide()

        -- Nur im Fenster: der Chat verbirgt, was das Fenster liest - und nur das.
        assert(MS.filterApi == "ChatFrame_AddMessageEventFilter", "Chatfilter nicht angemeldet: " .. tostring(MS.filterApi))
        for _, e in ipairs({ "CHAT_MSG_WHISPER", "CHAT_MSG_WHISPER_INFORM", "CHAT_MSG_BN_WHISPER", "CHAT_MSG_BN_WHISPER_INFORM",
                             "CHAT_MSG_AFK", "CHAT_MSG_DND", "CHAT_MSG_SYSTEM" }) do
            assert(filters[e], "kein Filter fuer " .. e)
        end
        assert(K.Get("comfort", "msgHideChat") == true, "nur im Fenster ab Werk aus")
        assert(Filter("CHAT_MSG_WHISPER", "hi", "Mara") == true, "Fluestern im Chat geblieben")
        assert(Filter("CHAT_MSG_WHISPER_INFORM", "hi", "Mara") == true, "eigenes Fluestern im Chat geblieben")
        local hidden = "geheim"
        secret[hidden] = true
        assert(Filter("CHAT_MSG_WHISPER", hidden, "Mara") == false, "Geheimes im Chat verborgen - stuende nirgends")
        assert(Filter("CHAT_MSG_WHISPER", "hi", hidden) == false, "geheimer Absender verborgen")
        secret[hidden] = nil
        assert(Filter("CHAT_MSG_BN_WHISPER", "na", "|Kq1|k", "", "", "", "", 0, 0, "", 0, 1, "", nil) == false, "Battle.net ohne Konto verborgen")
        assert(Filter("CHAT_MSG_BN_WHISPER", "na", "|Kq1|k", "", "", "", "", 0, 0, "", 0, 1, "", 5) == true, "Battle.net im Chat geblieben")
        W("hallo", "Mara-Testrealm")
        assert(Filter("CHAT_MSG_AFK", "weg", "Mara-Testrealm") == true, "Abwesend im Chat geblieben")
        assert(Filter("CHAT_MSG_AFK", "weg", "Fremdling") == false, "Abwesend ohne Gespraech verborgen")
        assert(Filter("CHAT_MSG_SYSTEM", "Kein Spieler namens 'Mara' ist derzeit gespielt.") == true, "nicht online im Chat geblieben")
        assert(Filter("CHAT_MSG_SYSTEM", "Du hast Erfahrung erhalten.") == false, "Systemzeile verborgen")
        -- Ohne Muster des Spiels: keine Systemzeile verbergen (war "false ~= nil").
        G.ERR_CHAT_PLAYER_NOT_FOUND_S = nil
        assert(Filter("CHAT_MSG_SYSTEM", "Du hast Erfahrung erhalten.") == false, "ohne Muster jede Systemzeile verborgen")
        -- Kommt das Muster spaeter (oder anders), gilt das neue.
        G.ERR_CHAT_PLAYER_NOT_FOUND_S = "'%s' ist nicht da."
        assert(Filter("CHAT_MSG_SYSTEM", "'Mara' ist nicht da.") == true, "Muster des Spiels veraltet gemerkt")
        G.ERR_CHAT_PLAYER_NOT_FOUND_S = "Kein Spieler namens '%s' ist derzeit gespielt."
        K.Set("comfort", "msgHideChat", false)
        assert(Filter("CHAT_MSG_WHISPER", "hi", "Mara") == false, "verborgen, obwohl aus")
        K.Set("comfort", "msgHideChat", true)
        local api = MS.filterApi
        MS.filterApi = false
        assert(Filter("CHAT_MSG_WHISPER", "hi", "Mara") == false, "ohne Chatfilter nicht Hiding")
        MS.filterApi = api
        K.Set("comfort", "msgOn", false)
        assert(Filter("CHAT_MSG_WHISPER", "hi", "Mara") == false, "verborgen, obwohl der Helfer aus ist")
        K.Set("comfort", "msgOn", true)

        -- Ton: der des Spiels kommt mit der Chatzeile - jetzt einer von hier.
        local s0 = sounds
        now = now + 100
        W("ping", "Mara-Testrealm")
        assert(sounds == s0 + 1 and flashed > 0, "kein Ton bei verborgenem Fluestern")
        W("ping2", "Mara-Testrealm")
        assert(sounds == s0 + 1, "Ton nicht gedrosselt")
        now = now + MS.PING_GAP + 1
        MS.OnEvent(nil, "CHAT_MSG_WHISPER_INFORM", "selbst", "Mara-Testrealm", "", "", "", "", 0, 0, "", 0, 1, nil)
        assert(sounds == s0 + 1, "Ton bei eigenem Fluestern")
        K.Set("comfort", "msgHideChat", false)
        W("ping3", "Mara-Testrealm")
        assert(sounds == s0 + 1, "zweiter Ton, obwohl der Chat zeigt")
        K.Set("comfort", "msgHideChat", true)

        -- Im Kampf einklappen, danach wieder auf - das Gespraech von vorher.
        MS.Show("w:Mara")
        combat = true
        MS.OnEvent(nil, "PLAYER_REGEN_DISABLED")
        assert(not MS.win:IsShown() and MS.folded == "w:Mara", "im Kampf nicht eingeklappt")
        combat = false
        MS.OnEvent(nil, "PLAYER_REGEN_ENABLED")
        assert(MS.win:IsShown() and MS.current == "w:Mara" and MS.folded == nil, "nach dem Kampf nicht wieder auf")
        -- Neues im Kampf: Symbol zaehlt, danach geht DAS Gespraech auf.
        combat = true
        MS.OnEvent(nil, "PLAYER_REGEN_DISABLED")
        W("hilfe!", "Nils")
        assert(not MS.win:IsShown() and MS.icon:IsShown() and MS.icon.badge:GetText() == tostring(MS.Unread())
            and MS.Unread() >= 1, "Symbol zaehlt nicht: " .. tostring(MS.icon.badge:GetText()))
        combat = false
        MS.OnEvent(nil, "PLAYER_REGEN_ENABLED")
        assert(MS.win:IsShown() and MS.current == "w:Nils", "nach dem Kampf nicht beim Neuen")
        -- Von selbst auf: die Zahl bleibt am Symbol, bis du hinsiehst.
        assert(MS.conv["w:Nils"].unread == 1 and MS.icon.dot:IsShown() and MS.icon.badge:GetText() == tostring(MS.Unread()),
            "Zahl am Symbol weg, obwohl nicht gesehen")
        MS.input:GetScript("OnEditFocusGained")(MS.input)
        assert(MS.conv["w:Nils"].unread == 0, "Klick in die Antwortzeile: nicht gelesen")
        MS.conv["w:Nils"].unread = 3
        MS.SetCopyMode(true)
        assert(MS.conv["w:Nils"].unread == 0, "Markieren: nicht gelesen")
        MS.SetCopyMode(false)
        -- Alles gelesen: kein Punkt, keine Zahl.
        for _, k in ipairs(MS.order) do MS.conv[k].unread = 0 end
        MS.UpdateIcon()
        assert(not MS.icon.dot:IsShown() and MS.icon.badge:GetText() == "", "Punkt ohne Ungelesenes")
        MS.conv["w:Nils"].unread = 120
        MS.UpdateIcon()
        assert(MS.icon.badge:GetText() == "99+", "mehr als 99: " .. tostring(MS.icon.badge:GetText()))
        MS.conv["w:Nils"].unread = 0
        -- Geschlossen in den Kampf: bleibt zu.
        MS.win:Hide()
        MS.OnEvent(nil, "PLAYER_REGEN_DISABLED")
        MS.OnEvent(nil, "PLAYER_REGEN_ENABLED")
        assert(not MS.win:IsShown(), "aufgegangen, obwohl es vor dem Kampf zu war")
        -- "Im Kampf offen lassen": bleibt offen.
        K.Set("comfort", "msgCombat", true)
        MS.Show("w:Mara")
        MS.OnEvent(nil, "PLAYER_REGEN_DISABLED")
        assert(MS.win:IsShown() and MS.folded == nil, "trotz Schalter eingeklappt")
        K.Set("comfort", "msgCombat", false)
        -- Markieren endet beim Einklappen.
        MS.SetCopyMode(true)
        MS.OnEvent(nil, "PLAYER_REGEN_DISABLED")
        assert(not MS.copyMode, "Markieren ueberlebt das Einklappen")
        MS.OnEvent(nil, "PLAYER_REGEN_ENABLED")

        -- "/w Name" oder Klick auf einen Namen: Gespraech geht auf.
        MS.win:Hide()
        eb:SetAttribute("chatType", "WHISPER")
        eb:SetAttribute("tellTarget", "Zora-Testrealm")
        eb:GetScript("OnTextChanged")(eb, true)
        assert(MS.win:IsShown() and MS.current == "w:Zora" and MS.conv["w:Zora"].target == "Zora-Testrealm", "/w Zora oeffnet nicht")
        -- Einmal je Ziel: weiter tippen oeffnet nicht wieder.
        MS.win:Hide()
        eb:GetScript("OnTextChanged")(eb, true)
        assert(not MS.win:IsShown(), "bei jedem Tastendruck aufgegangen")
        -- Zeile zu und wieder auf: wieder.
        eb:GetScript("OnHide")(eb)
        eb:GetScript("OnShow")(eb)
        assert(MS.win:IsShown(), "nach neuem Oeffnen der Zeile nicht auf")
        -- Offen: wechselt zum Ziel.
        MS.Select("w:Mara")
        W("noch was", "Nils")
        assert(MS.conv["w:Nils"].unread == 1, "Nils nicht ungelesen")
        eb:SetAttribute("tellTarget", "Nils")
        headerHook(eb)
        assert(MS.current == "w:Nils" and MS.conv["w:Nils"].unread == 0, "offenes Fenster wechselt nicht zum Ziel (UpdateHeader)")
        -- Kein Fluestern: nichts.
        MS.win:Hide()
        for _, kind in ipairs({ "SAY", "GUILD", "PARTY" }) do
            eb:SetAttribute("chatType", kind)
            -- Ein Ziel bleibt in der Zeile stehen - auch eines, das Battle.net kennt.
            for _, who in ipairs({ "Otto", "Kumpel" }) do
                eb:SetAttribute("tellTarget", who)
                eb:GetScript("OnTextChanged")(eb, true)
                assert(not MS.win:IsShown() and MS.conv["w:Otto"] == nil and MS.conv["bn:77"] == nil,
                    "bei " .. kind .. " aufgegangen")
            end
        end
        -- Battle.net ueber die Nummer des Kontos.
        eb:SetAttribute("chatType", "BN_WHISPER")
        eb:SetAttribute("tellTarget", "Kumpel")
        eb:GetScript("OnTextChanged")(eb, true)
        assert(MS.win:IsShown() and MS.current == "bn:77" and MS.conv["bn:77"].bn, "Battle.net-Ziel")
        -- Ein schon offenes Battle.net-Gespraech ueber den Namen (ohne Nummer vom Spiel).
        MS.OnEvent(nil, "CHAT_MSG_BN_WHISPER", "huhu", "Altfreund", "", "", "", "", 0, 0, "", 0, 1, "", 9)
        eb:SetAttribute("tellTarget", "Altfreund")
        eb:GetScript("OnTextChanged")(eb, true)
        assert(MS.current == "bn:9" and MS.conv["bn:Altfreund"] == nil, "Battle.net-Gespraech ueber den Namen: " .. tostring(MS.current))
        -- Im Kampf: erst danach.
        MS.win:Hide()
        combat = true
        eb:SetAttribute("chatType", "WHISPER")
        eb:SetAttribute("tellTarget", "Pia")
        eb:GetScript("OnTextChanged")(eb, true)
        assert(not MS.win:IsShown() and MS.pending == "w:Pia", "im Kampf aufgegangen")
        combat = false
        MS.OnEvent(nil, "PLAYER_REGEN_ENABLED")
        assert(MS.win:IsShown() and MS.current == "w:Pia", "nach dem Kampf nicht bei Pia")
        -- Ohne "Bei eigenem Fluestern aufgehen": nichts.
        MS.win:Hide()
        K.Set("comfort", "msgOutgoing", false)
        eb:GetScript("OnHide")(eb)
        eb:SetAttribute("tellTarget", "Quentin")
        eb:GetScript("OnShow")(eb)
        assert(not MS.win:IsShown() and MS.conv["w:Quentin"] == nil, "aufgegangen, obwohl abgeschaltet")
        K.Set("comfort", "msgOutgoing", true)

        -- Taste "Antworten" (R, 6.19.1.2): Fenster beim zuletzt Fluesternden auf;
        -- zielt die Chatzeile (veraltet) woanders hin, neu mit "/w Name".
        -- Seit 6.19.1.3 erst im naechsten Bild - sonst landet das "r" der
        -- Taste in der eben geoeffneten Zeile. Der Zeitgeber hier feuert,
        -- wenn der Test es sagt (Next).
        assert(replyHook, "Taste Antworten nicht angehaengt")
        local queue = {}
        G.C_Timer = { After = function(d, fn) queue[#queue + 1] = { d, fn } end, NewTicker = function() return {} end }
        local function Next()
            local q = queue
            queue = {}
            for _, e in ipairs(q) do assert(e[1] == 0, "nicht im naechsten Bild: " .. tostring(e[1])) e[2]() end
        end
        local function R() replyHook() Next() end
        MS.win:Hide()
        W("antwortest du?", "Rita")
        MS.OnEvent(nil, "CHAT_MSG_WHISPER_INFORM", "selbst", "Sven", "", "", "", "", 0, 0, "", 0, 1, nil)
        assert(MS.lastIn == "w:Rita", "zuletzt fluesternd: " .. tostring(MS.lastIn))
        MS.win:Hide()
        eb:SetAttribute("chatType", "WHISPER")
        eb:SetAttribute("tellTarget", "Altbekannt")
        local nOpen = #opened
        replyHook()
        assert(MS.win:IsShown() and #opened == nOpen, "Chatzeile im selben Augenblick wie die Taste geoeffnet (das r landet darin)")
        Next()
        assert(MS.win:IsShown() and MS.current == "w:Rita" and MS.conv["w:Rita"].unread == 0 and MS.order[1] == "w:Rita",
            "R oeffnet nicht bei Rita: " .. tostring(MS.current))
        assert(#opened == nOpen + 1 and opened[#opened] == "/w Rita ", "Chatzeile nicht auf Rita: " .. tostring(opened[#opened]))
        -- Zielt sie schon auf Rita: nicht noch einmal.
        eb:SetAttribute("tellTarget", "Rita-Testrealm")
        R()
        assert(#opened == nOpen + 1, "Chatzeile doppelt geoeffnet")
        -- Im Kampf: ausdruecklich gedrueckt, also auf.
        MS.win:Hide()
        combat = true
        R()
        assert(MS.win:IsShown(), "R im Kampf: Fenster bleibt zu")
        combat = false
        -- Direkt senden: die Antwortzeile des Fensters, nicht die Chatzeile.
        K.Set("comfort", "msgDirect", true)
        local focused
        MS.input.SetFocus = function() focused = true end
        eb:SetAttribute("tellTarget", "Altbekannt")
        replyHook()
        assert(not focused, "direkt: Fokus im selben Augenblick wie die Taste (das r landet darin)")
        Next()
        assert(focused and #opened == nOpen + 1, "direkt: Fokus nicht im Fenster oder Chatzeile geoeffnet")
        MS.input.SetFocus = nil
        K.Set("comfort", "msgDirect", false)
        -- Zwischen Taste und naechstem Bild abgeschaltet: nichts mehr anfassen.
        eb:SetAttribute("chatType", "WHISPER")
        eb:SetAttribute("tellTarget", "Altbekannt")
        replyHook()
        K.Set("comfort", "msgOn", false)
        Next()
        K.Set("comfort", "msgOn", true)
        assert(#opened == nOpen + 1, "nach dem Abschalten noch die Chatzeile geoeffnet")
        -- Battle.net: Ziel ueber den Namen.
        MS.OnEvent(nil, "CHAT_MSG_BN_WHISPER", "bn?", "Bnfreund", "", "", "", "", 0, 0, "", 0, 1, "", 31)
        eb:SetAttribute("chatType", "BN_WHISPER")
        eb:SetAttribute("tellTarget", "Bnfreund")
        R()
        assert(MS.current == "bn:31" and #opened == nOpen + 1, "Battle.net: Chatzeile zielte schon richtig")
        eb:SetAttribute("tellTarget", "Jemandanders")
        R()
        assert(#opened == nOpen + 2 and opened[#opened] == "bn:31", "Battle.net: Chatzeile nicht neu gezielt")
        nOpen = #opened
        -- Gespraech inzwischen geschlossen: nichts, und nicht neu angelegt.
        MS.Close("bn:31")
        MS.win:Hide()
        R()
        assert(not MS.win:IsShown() and MS.conv["bn:31"] == nil and #opened == nOpen, "R nach geschlossenem Gespraech")
        MS.lastIn = "w:Rita"
        -- Niemand hat gefluestert, oder der Helfer ist aus: nichts.
        MS.lastIn = nil
        MS.win:Hide()
        R()
        assert(not MS.win:IsShown(), "R ohne Fluesternden: aufgegangen")
        MS.lastIn = "w:Rita"
        K.Set("comfort", "msgOn", false)
        R()
        assert(not MS.win:IsShown() and #opened == nOpen, "R bei abgeschaltetem Helfer")
        K.Set("comfort", "msgOn", true)
        assert(#touched == 0, "Chatzeile des Spiels angefasst: " .. table.concat(touched, ", "))

        -- Symbol: Klick auf/zu, abschaltbar, mit dem Helfer weg.
        MS.win:Hide()
        MS.conv[MS.current].unread = 2
        MS.icon:GetScript("OnClick")(MS.icon)
        assert(MS.win:IsShown() and MS.conv[MS.current].unread == 0, "Symbol oeffnet nicht (oder laesst ungelesen)")
        MS.icon:GetScript("OnClick")(MS.icon)
        assert(not MS.win:IsShown(), "Symbol schliesst nicht")
        K.Set("comfort", "msgIcon", false)
        assert(not MS.icon:IsShown(), "Symbol trotz Schalter")
        K.Set("comfort", "msgIcon", true)
        assert(MS.icon:IsShown(), "Symbol kommt nicht wieder")

        -- Ziehen: am Fenster selbst, gespeichert wie im Gestaltungsmodus.
        local moving
        MS.win.StartMoving = function() moving = true end
        MS.win.StopMovingOrSizing = function() moving = false end
        MS.win.GetPoint = function() return "BOTTOMLEFT", UIParent, "BOTTOMLEFT", 101.4, 222.6 end
        MS.win:GetScript("OnDragStart")(MS.win)
        assert(moving == true, "Fenster laesst sich nicht ziehen")
        MS.win:GetScript("OnDragStop")(MS.win)
        local pos = K.Profile().positions.messenger
        assert(moving == false and pos and pos.x == 101 and pos.y == 223, "Stelle nicht gespeichert")
        K.Profile().positions.messenger = nil
        assert(MS.icon:GetScript("OnDragStart") and MS.icon:GetScript("OnDragStop"), "Symbol laesst sich nicht ziehen")

        -- Selbstpruefung nennt den Chatfilter.
        local sc = table.concat(MS.StatusLines(), "\n")
        assert(sc:find("Chatfilter: ChatFrame_AddMessageEventFilter", 1, true), "Selbstpruefung: " .. sc)

        K.Set("comfort", "msgOn", false)
        assert(not MS.icon:IsShown() and not MS.win:IsShown(), "Symbol oder Fenster bleibt, obwohl aus")
    end)
    for i, n in ipairs(names) do G[n] = saved[i] end
    K.Set("comfort", "msgOn", false)
    K.Set("comfort", "msgCombat", false)
    K.Set("comfort", "msgOutgoing", true)
    K.Set("comfort", "msgHideChat", true)
    K.Set("comfort", "msgIcon", true)
    Check(ok, "Fluestern nur im Fenster: Chatfilter verbirgt nur Lesbares, Ton, Kampf einklappen, /w oeffnet (Zeile unberuehrt), Symbol, ziehen"
        .. (ok and "" or (": " .. tostring(err))))
end

-- 6.20.0.0: Instanzeingaenge auf der Weltkarte (Komfort -> Karte). Eigene
-- Symbole auf der Flaeche der Karte, aus J.ENTRANCES; ein Symbol je Stelle
-- (Blackrock: drei Dungeons); auf dem Kontinent ueber GetMapRectOnMap;
-- nichts, wo das Spiel selbst Eingaenge zeigt; nie in die Karte schreiben.
do
    local G = _G
    local names = { "WorldMapFrame", "C_Map", "C_EncounterJournal", "GameTooltip" }
    local saved = {}
    for i, n in ipairs(names) do saved[i] = G[n] end
    local K = WeintCodex.UIKit
    local ME = WeintCodex.UIMapEntrances
    local navSaved = WeintCodex.Navigation.GoToTab
    local ok, err = pcall(function()
        local wm = CreateFrame("Frame", "WorldMapFrame", UIParent)
        G.WorldMapFrame = wm
        local mapID = 1427
        local wrote = 0
        wm.GetMapID = function() return mapID end
        wm.SetMapID = function() wrote = wrote + 1 end
        wm.AddDataProvider = function() wrote = wrote + 1 end
        local canvas = CreateFrame("Frame", nil, wm)
        canvas._width, canvas._height = 1000, 600
        wm.GetCanvas = function() return canvas end
        -- Zonen unter den Oestlichen Koenigreichen (1415), Kalimdor 1414.
        local KALIMDOR = { [1413] = true, [1440] = true, [1443] = true, [1444] = true, [1446] = true, [1454] = true, [1435] = false }
        G.C_Map = {
            GetMapInfo = function(id)
                if id == 1414 or id == 1415 then return { mapType = 2, parentMapID = 947 } end
                if id == 947 then return { mapType = 1 } end
                return { mapType = 3, parentMapID = KALIMDOR[id] and 1414 or 1415 }
            end,
            -- Jedes Rechteck gleich - welche Zone auf welchen Kontinent gehoert,
            -- muss WeintCodex selbst ueber die Eltern wissen.
            GetMapRectOnMap = function(zone, top)
                if top == 1414 or top == 1415 or top == 947 then return 0.4, 0.6, 0.5, 0.7 end
                return nil
            end,
        }
        local gameShows = {}
        G.C_EncounterJournal = { GetDungeonEntrancesForMap = function(id) return gameShows[id] or {} end }

        -- Bestand: Blackrock einmal mit drei Dungeons, Stratholme zweimal.
        local spots = ME.Spots()
        local br, strat = nil, 0
        for _, sp in ipairs(spots) do
            if sp.map == 1427 then br = sp end
            if sp.map == 1423 then strat = strat + 1 end
        end
        assert(br and #br.entries == 3 and strat == 2, "Stellen falsch zusammengefasst")
        assert(br.entries[1].dungeon.minLevel <= br.entries[3].dungeon.minLevel, "nicht nach Stufe")

        -- Aus: nichts auf der Karte.
        K.Set("comfort", "mapEntrances", false)
        wm:Show()
        assert(ME.Place() == 0 and (not ME.pins[1] or not ME.pins[1]:IsShown()), "Symbole, obwohl aus")
        K.Set("comfort", "mapEntrances", true)
        assert(ME.driver and ME.driver:GetParent() == wm, "kein Taktgeber an der Karte")

        -- Zone: ein Symbol an der Stelle, gleich gross bei jedem Zoom.
        local pt
        assert(ME.Place() == 1, "Blackrock: nicht genau ein Symbol")
        local p = ME.pins[1]
        p.SetPoint = function(_, a, rel, b, x, y) pt = { a, rel, b, x, y } end
        ME.Place()
        assert(pt[1] == "CENTER" and pt[2] == canvas and pt[3] == "TOPLEFT" and math.abs(pt[4] - 348) < 0.01
            and math.abs(pt[5] + 511.8) < 0.01, "an falscher Stelle: " .. tostring(pt[4]) .. ", " .. tostring(pt[5]))
        assert(p:GetParent() == canvas and p:IsShown() and p.spot == br, "Symbol nicht auf der Flaeche")
        -- Gezoomt: die Flaeche doppelt so gross, das Symbol halb.
        local scale
        p.SetScale = function(_, v) scale = v end
        canvas.GetEffectiveScale = function() return 2 end
        wm.GetEffectiveScale = function() return 1 end
        ME.Place()
        assert(scale == 0.5 and math.abs(pt[4] - 696) < 0.01 and math.abs(pt[5] + 1023.6) < 0.01, "Zoom nicht ausgeglichen")
        canvas.GetEffectiveScale, wm.GetEffectiveScale = nil, nil
        p.SetScale = nil
        -- Neue Flaeche (die Karte baut sie neu): die Symbole ziehen mit.
        local canvas2 = CreateFrame("Frame", nil, wm)
        canvas2._width, canvas2._height = 1000, 600
        wm.GetCanvas = function() return canvas2 end
        ME.Place()
        assert(p:GetParent() == canvas2, "Symbol bleibt auf der alten Flaeche")
        wm.GetCanvas = function() return canvas end
        ME.Place()
        mapID = 1423
        assert(ME.Place() == 2 and ME.pins[2]:IsShown(), "Stratholme: zwei Eingaenge")
        mapID = 1429
        assert(ME.Place() == 0 and not ME.pins[1]:IsShown() and not ME.pins[2]:IsShown(), "Zone ohne Eingang zeigt Symbole")

        -- Kontinent: nur, wo der Client das Rechteck nennt.
        mapID = 1415
        assert(ME.Place() == 12, "Oestliche Koenigreiche: " .. tostring(ME.Place()))
        mapID = 1414
        assert(ME.Place() == 8, "Kalimdor: " .. tostring(ME.Place()))
        mapID = 1415
        ME.Place()
        assert(ME.pins[1].spot == br, "Kontinent: erstes Symbol nicht Blackrock")
        ME.pins[1].SetPoint = function(_, a, rel, b, x, y) pt = { a, rel, b, x, y } end
        ME.Place()
        assert(math.abs(pt[4] - 1000 * (0.4 + 0.348 * 0.2)) < 0.01 and math.abs(pt[5] + 600 * (0.5 + 0.853 * 0.2)) < 0.01,
            "Kontinent an falscher Stelle")
        K.Set("comfort", "mapContinent", false)
        assert(ME.Place() == 0, "Kontinent, obwohl abgeschaltet")
        K.Set("comfort", "mapContinent", true)
        -- Die ganze Welt (kein Kontinent): nichts.
        mapID = 947
        assert(ME.Place() == 0, "Weltkarte zeigt Symbole")

        -- Zeigt das Spiel selbst Eingaenge: unsere bleiben weg.
        gameShows[1427] = { { name = "Schwarzfels" } }
        ME.Forget()
        mapID = 1427
        assert(ME.Place() == 0, "doppelt zu den Eingaengen des Spiels")
        gameShows[1427] = nil
        ME.Forget()
        assert(ME.Place() == 1, "Symbol kommt nicht wieder")

        -- Tooltip: alle drei, mit Stufe, und woher.
        local lines = {}
        G.GameTooltip = setmetatable({
            SetOwner = function() end, Show = function() end, Hide = function() end,
            SetText = function(_, t) lines[#lines + 1] = t end,
            AddLine = function(_, t) lines[#lines + 1] = t end,
        }, {})
        ME.pins[1]:GetScript("OnEnter")(ME.pins[1])
        local tip = table.concat(lines, "\n")
        for _, e in ipairs(br.entries) do assert(tip:find(e.dungeon.name, 1, true), "Tooltip ohne " .. e.dungeon.name) end
        assert(tip:find("Stufe ", 1, true) and tip:find("unbestätigt", 1, true), "Tooltip: " .. tip)

        -- Klick: Codex auf, beim Dungeon.
        local went
        WeintCodex.Navigation.GoToTab = function(t) went = t end
        local main = WeintCodex.MainFrame
        main:Hide()
        ME.pins[1]:GetScript("OnClick")(ME.pins[1])
        assert(main:IsShown() and went == "dungeons", "Klick oeffnet den Codex nicht")
        main:Hide()

        -- Karte zu: Taktgeber stellt nichts.
        wm:Hide()
        assert(ME.Place() == 0 and not ME.pins[1]:IsShown(), "Symbole bei geschlossener Karte")
        assert(wrote == 0, "in die Weltkarte geschrieben")

        -- Selbstpruefung.
        local sc = table.concat(ME.StatusLines(), "\n")
        assert(sc:find("Eingänge im Bestand: 22 an 20 Stellen", 1, true) and sc:find("GetMapRectOnMap): ja", 1, true), "Selbstpruefung: " .. sc)
        local page
        for _, pg in ipairs(K.Module("comfort").pages) do if pg.key == "karte" then page = pg end end
        assert(page and page.label == "Karte", "Seite fehlt")
    end)
    for i, n in ipairs(names) do G[n] = saved[i] end
    WeintCodex.Navigation.GoToTab = navSaved
    K.Set("comfort", "mapEntrances", false)
    K.Set("comfort", "mapContinent", true)
    ME.Forget()
    Check(ok, "Karte: Instanzeingaenge als Symbol, je Stelle eins, Kontinent, nicht doppelt zum Spiel, Tooltip mit Herkunft, Klick in den Codex"
        .. (ok and "" or (": " .. tostring(err))))
end

-- 6.21.0.0: Geistheiler und Uebergaenge (Beta-Test: "dort sind auch die
-- Geistheiler und die gruenen Pfeile eingezeichnet ... das waere cool").
do
    local G = _G
    local names = { "WorldMapFrame", "C_Map", "GameTooltip" }
    local saved = {}
    for i, n in ipairs(names) do saved[i] = G[n] end
    local K = WeintCodex.UIKit
    local MK = WeintCodex.UIMapMarks
    local ME = WeintCodex.UIMapEntrances
    local svc, gvc = stub.Methods.SetVertexColor, stub.Methods.GetVertexColor
    stub.Methods.SetVertexColor = function(self, r, g, b, a) self._vc = { r, g, b, a } end
    stub.Methods.GetVertexColor = function(self) local v = self._vc or {} return v[1], v[2], v[3], v[4] end
    local ok, err = pcall(function()
        local D = WeintCodex.MapMarksData
        -- Bestand: Lagen auf der Karte, Richtung und Ziel als Zahlen.
        local ns, na = 0, 0
        for map, l in pairs(D.spirit) do
            assert(#l % 2 == 0, "Geistheiler " .. map .. ": ungerade Liste")
            for _, v in ipairs(l) do assert(v >= 0 and v <= 1, "Geistheiler " .. map .. " ausserhalb") end
            ns = ns + #l / 2
        end
        for map, l in pairs(D.crossings) do
            assert(#l % 4 == 0, "Uebergang " .. map .. ": Liste nicht in Vierern")
            for i = 1, #l, 4 do
                assert(l[i] >= 0 and l[i] <= 1 and l[i + 1] >= 0 and l[i + 1] <= 1, "Uebergang " .. map .. " ausserhalb")
                assert(type(l[i + 2]) == "number" and l[i + 3] ~= map and l[i + 3] > 0, "Uebergang " .. map .. ": Richtung oder Ziel")
            end
            na = na + #l / 4
        end
        assert(ns == 103 and na == 110, "Bestand: " .. ns .. " Geistheiler, " .. na .. " Uebergaenge")
        assert(K.Module("comfort").defaults.mapSpirit == false and K.Module("comfort").defaults.mapCrossings == false,
            "nicht von Haus aus aus")

        local wm = CreateFrame("Frame", "WorldMapFrame", UIParent)
        G.WorldMapFrame = wm
        local mapID, wrote = 1440, 0
        wm.GetMapID = function() return mapID end
        wm.SetMapID = function() wrote = wrote + 1 end
        wm.AddDataProvider = function() wrote = wrote + 1 end
        local canvas = CreateFrame("Frame", nil, wm)
        canvas._width, canvas._height = 1000, 600
        wm.GetCanvas = function() return canvas end
        -- Der Client kennt jede Zone beim Namen - ausser Dunkelkueste (1439).
        G.C_Map = { GetMapInfo = function(id)
            if id == 1414 then return { mapType = 2, parentMapID = 947, name = "Kalimdor" } end
            return { mapType = 3, parentMapID = 1414, name = id ~= 1439 and ("Zone " .. id) or nil }
        end }
        wm:Show()
        K.Set("comfort", "mapSpirit", false)
        K.Set("comfort", "mapCrossings", false)
        assert(MK.Place() == 0 and not MK.Active(), "Symbole, obwohl aus")
        K.Set("comfort", "mapSpirit", true)
        assert(MK.driver and MK.driver:GetParent() == wm, "kein Taktgeber an der Karte")
        assert(MK.Place() == 7, "Eschental: sieben Geistheiler, gezeigt " .. tostring(MK.Place()))
        local p = MK.pins[1]
        assert(p:GetParent() ~= canvas and p:GetParent():GetParent() == canvas, "Symbol direkt auf der Flaeche")
        local pt
        p.SetPoint = function(_, a, rel, b, x, y) pt = { a, rel, b, x, y } end
        MK.Place()
        assert(pt[2] == canvas and math.abs(pt[4] - 178) < 0.01 and math.abs(pt[5] + 66) < 0.01, "Geistheiler an falscher Stelle")
        assert(p:GetWidth() == MK.SPIRIT and p.dot:IsShown() and not p.arrow:IsShown(), "Geistheiler nicht als Punkt")
        -- 6.21.0.1 (Beta-Test: "nicht gut zu sehen"): gross genug, helles
        -- Gruen mit hellem Rand und dunklem Hof.
        local gc = WeintCodex.GameColors.mapMark
        local cr, cg, cb = p.dot:GetVertexColor()
        assert(MK.SPIRIT >= 20 and MK.ARROW >= 30 and cr == gc[1] and cg == gc[2] and cb == gc[3]
            and gc[2] > WeintCodex.GameColors.friendly[2], "Geistheiler zu klein oder zu dunkel")
        assert(#p.spirit == 3 and #p.crossing == 3 and p.spirit[1]:IsShown() and p.rim:IsShown()
            and not p.crossing[2]:IsShown(), "Hof oder Rand fehlt")
        -- Unter den Eingaengen.
        assert(p:GetFrameLevel() < (canvas:GetFrameLevel() or 0) + 1500, "Geistheiler ueber den Eingaengen")

        -- Uebergaenge dazu: sieben, drei davon nach Dunkelkueste - die kennt
        -- der Client nicht beim Namen, also keiner davon.
        K.Set("comfort", "mapCrossings", true)
        assert(MK.Place() == 7 + 4, "Eschental mit Uebergaengen: " .. tostring(MK.Place()))
        local a = MK.pins[8]
        assert(a.entry.kind == "crossing" and a.entry.to == 1442 and a:GetWidth() == MK.ARROW
            and a.arrow:IsShown() and not a.dot:IsShown(), "Pfeil nicht als Pfeil")
        for i = 8, 11 do assert(MK.pins[i].entry.to ~= 1439, "Pfeil ohne Namen des Ziels") end
        -- Richtung, gesetzt beim ersten Einrichten.
        MK.Forget()
        for _, q in ipairs(MK.pins) do q.entry = nil end
        local set, layers = {}, {}
        for i = 8, 11 do MK.pins[i].arrow.SetRotation = function(_, r) set[i] = r end end
        -- 6.21.0.1: Schatten und Rand drehen mit - sonst zeigt der Rand woandershin.
        for li, t in ipairs(MK.pins[8].crossing) do
            if t ~= MK.pins[8].arrow then t.SetRotation = function(_, r) layers[li] = r end end
        end
        MK.Place()
        assert(layers[1] == 2.7 and layers[2] == 2.7, "Schatten oder Rand nicht gedreht")
        assert(set[8] == 2.7 and set[9] == 0 and set[10] == 4.4 and set[11] == 3.2, "Richtungen: "
            .. tostring(set[8]) .. " " .. tostring(set[9]) .. " " .. tostring(set[10]) .. " " .. tostring(set[11]))

        -- Tooltip: wohin, und woher die Lage stammt - ohne fremdes Addon.
        local lines = {}
        G.GameTooltip = setmetatable({
            SetOwner = function() end, Show = function() end, Hide = function() end,
            SetText = function(_, t) lines[#lines + 1] = t end,
            AddLine = function(_, t) lines[#lines + 1] = t end,
        }, {})
        a:GetScript("OnEnter")(a)
        MK.pins[1]:GetScript("OnEnter")(MK.pins[1])
        local tip = table.concat(lines, "\n")
        assert(tip:find("Nach Zone 1442", 1, true) and tip:find("Geistheiler", 1, true)
            and tip:find("unbestätigt", 1, true), "Tooltip: " .. tip)

        -- Nur die Pfeile: die Punkte verschwinden.
        K.Set("comfort", "mapSpirit", false)
        assert(MK.Place() == 4 and MK.pins[1].entry.kind == "crossing" and not MK.pins[5]:IsShown(), "Geistheiler bleiben stehen")
        K.Set("comfort", "mapSpirit", true)
        -- Nur die Geistheiler wieder: die Pfeile verschwinden.
        K.Set("comfort", "mapCrossings", false)
        assert(MK.Place() == 7 and not MK.pins[8]:IsShown(), "Pfeile bleiben stehen")
        -- 6.21.2.0: Kontinent - jede Zone darunter, kleiner; nur mit Rechteck.
        K.Set("comfort", "mapCrossings", true)
        mapID = 1414
        assert(MK.Place() == 0, "Kontinent ohne Rechteck zeigt Symbole")
        G.C_Map.GetMapRectOnMap = function(zone, top) if top == 1414 then return 0.4, 0.6, 0.5, 0.7 end end
        MK.Forget()
        local n = MK.Place()
        assert(n > 50 and MK.pins[1].entry.small, "Kontinent: " .. tostring(n))
        assert(math.abs(MK.pins[1].entry.x - (0.4 + D.spirit[1411][1] * 0.2)) < 1e-6, "Kontinent an falscher Stelle")
        -- 6.21.1.2: kleiner gemacht, aber an derselben Stelle - der Abstand
        -- gilt im Massstab des Symbols.
        local cpt, csc
        MK.pins[1].SetPoint = function(_, a, rel, b, x, y) cpt = { x, y } end
        MK.pins[1].SetScale = function(_, v) csc = v end
        MK.Place()
        assert(csc == MK.SMALL and math.abs(cpt[1] * csc - 1000 * MK.pins[1].entry.x) < 1e-6
            and math.abs(cpt[2] * csc + 600 * MK.pins[1].entry.y) < 1e-6, "Kontinent: verkleinert und verschoben")
        MK.pins[1].SetPoint, MK.pins[1].SetScale = nil, nil
        K.Set("comfort", "mapMarksContinent", false)
        assert(MK.Place() == 0, "Kontinent, obwohl abgeschaltet")
        K.Set("comfort", "mapMarksContinent", true)
        -- Flugmeister und Reisen, nach Fraktion.
        G.UnitFactionGroup = function() return "Horde" end
        K.Set("comfort", "mapSpirit", false)
        K.Set("comfort", "mapCrossings", false)
        K.Set("comfort", "mapFlight", true)
        K.Set("comfort", "mapTravel", true)
        mapID = 1420
        MK.Place()
        local kinds, factions = {}, {}
        for _, q in ipairs(MK.pins) do
            if q:IsShown() then kinds[q.entry.kind] = true factions[q.entry.faction] = true end
        end
        assert(kinds.travel and not factions[1], "Tirisfal: Zeppelin fehlt oder Allianz gezeigt")
        K.Set("comfort", "mapMarksOther", true)
        mapID = 1455
        local all = MK.Place()
        K.Set("comfort", "mapMarksOther", false)
        assert(MK.Place() < all, "andere Fraktion nicht ausgeblendet")
        lines = {}
        for _, q in ipairs(MK.pins) do
            if q:IsShown() and q.entry.kind == "travel" then q:GetScript("OnEnter")(q) break end
        end
        K.Set("comfort", "mapMarksOther", true)
        mapID = 1455
        MK.Place()
        for _, q in ipairs(MK.pins) do
            if q:IsShown() and q.entry.kind == "travel" then q:GetScript("OnEnter")(q) break end
        end
        assert(table.concat(lines, "\n"):find("Tram nach Zone 1453", 1, true), "Tooltip der Reise: " .. table.concat(lines, "|"))
        K.Set("comfort", "mapMarksOther", false)
        K.Set("comfort", "mapFlight", false)
        K.Set("comfort", "mapTravel", false)
        K.Set("comfort", "mapSpirit", true)
        G.UnitFactionGroup = nil
        mapID = 1414
        -- Karte zu: nichts.
        mapID = 1440
        wm:Hide()
        assert(MK.Place() == 0 and not MK.pins[1]:IsShown(), "Symbole bei geschlossener Karte")
        assert(wrote == 0, "in die Weltkarte geschrieben")
        local sc = table.concat(MK.StatusLines(), "\n")
        assert(sc:find("Geistheiler im Bestand: 103 auf", 1, true) and sc:find("Übergänge: 110 auf", 1, true), "Selbstpruefung: " .. sc)
    end)
    for i, n in ipairs(names) do G[n] = saved[i] end
    G.UnitFactionGroup = nil
    K.Set("comfort", "mapFlight", false)
    K.Set("comfort", "mapTravel", false)
    K.Set("comfort", "mapMarksOther", false)
    stub.Methods.SetVertexColor, stub.Methods.GetVertexColor = svc, gvc
    K.Set("comfort", "mapSpirit", false)
    K.Set("comfort", "mapCrossings", false)
    MK.Forget()
    Check(ok, "Karte: Geistheiler und Uebergaenge - Bestand, Lage, Pfeilrichtung, Ziel nur mit Namen vom Client, Tooltip, nur Zonen, kein Schreiben in die Karte"
        .. (ok and "" or (": " .. tostring(err))))
end

-- 6.20.0.0: Weltkarte aufdecken. Daten aus data/mapreveal.lua (erzeugt aus
-- Leatrix Maps, nur Daten); im Spiel gegen die erkundeten Teile gehalten;
-- gezeichnet nur Unerkundetes, abgedunkelt; Kacheln wie in den Spieldaten.
do
    local G = _G
    local names = { "WorldMapFrame", "C_Map", "C_MapExplorationInfo", "C_AddOns", "IsAddOnLoaded" }
    local saved = {}
    for i, n in ipairs(names) do saved[i] = G[n] end
    local K = WeintCodex.UIKit
    local MR = WeintCodex.UIMapReveal
    local ok, err = pcall(function()
        -- Bestand: jede Zone mit Teilen, jedes Teil mit so vielen Bildern wie Kacheln.
        local data = MR.Data()
        local zones, parts = 0, 0
        for art, z in pairs(data) do
            zones = zones + 1
            assert(type(z.map) == "number" and type(z.name) == "string" and #z > 0, "Zone " .. art)
            for _, p in ipairs(z) do
                parts = parts + 1
                assert(#p[5] == math.ceil(p[1] / 256) * math.ceil(p[2] / 256), "Bilder je Teil: " .. z.name)
            end
        end
        assert(zones == 44 and parts == 569 and data[2169].map == 1411, "Bestand: " .. zones .. "/" .. parts)

        local wm = CreateFrame("Frame", "WorldMapFrame", UIParent)
        G.WorldMapFrame = wm
        local mapID = 1411
        local wrote = 0
        wm.GetMapID = function() return mapID end
        wm.SetMapID = function() wrote = wrote + 1 end
        wm.AddDataProvider = function() wrote = wrote + 1 end
        local canvas = CreateFrame("Frame", nil, wm)
        canvas._width, canvas._height = 1002, 668
        wm.GetCanvas = function() return canvas end
        -- Die erkundeten Teile des Spiels: ein Rahmen auf der Flaeche.
        local gamePin = CreateFrame("Frame", nil, canvas)
        gamePin.pinTemplate = "MapExplorationPinTemplate"
        gamePin:SetFrameLevel(37)
        canvas.GetChildren = function() return gamePin end
        -- Kartenbild wie im Bestand; 1429 bekommt eines, das er nicht kennt.
        G.C_Map = { GetMapArtID = function(id)
            if id == 1429 then return 999999 end
            for art, z in pairs(data) do if z.map == id then return art end end
        end }
        local explored = {}
        G.C_MapExplorationInfo = { GetExploredMapTextures = function() return explored end }
        G.C_AddOns = { IsAddOnLoaded = function() return false end }
        local durotar = data[2169]
        local function Info(p, ids) return { textureWidth = p[1], textureHeight = p[2], offsetX = p[3], offsetY = p[4], fileDataIDs = ids or p[5] } end

        K.Set("comfort", "mapReveal", false)
        wm:Show()
        assert(MR.Update() == 0, "aufgedeckt, obwohl aus")
        -- Eingeschaltet auf einer Zone ohne Daten: der Rahmen entsteht, Bilder nicht.
        mapID = 1429
        K.Set("comfort", "mapReveal", true)
        assert(MR.driver and MR.driver:GetParent() == wm, "kein Taktgeber an der Karte")

        -- Aufzeichnende Bilder: was gesetzt wird, steht danach am Bild.
        assert(MR.layer and (MR.drawn or 0) == 0 and #MR.tex == 0, "Zone ohne Daten gezeichnet")
        MR.layer.CreateTexture = function()
            local t = CreateFrame("Frame", nil, MR.layer)
            t.SetTexture = function(self, v) self.file = v end
            t.SetTexCoord = function(self, a, b, c, d) self.tc = { a, b, c, d } end
            t.SetPoint = function(self, a, rel, b, x, y) self.pt = { a, rel, b, x, y } end
            t.SetVertexColor = function(self, r, g, b, a) self.col = { r, g, b, a } end
            return t
        end

        -- Nichts erkundet: alles gezeichnet, ungeprueft, abgedunkelt.
        mapID = 1411
        MR.Forget()
        local tiles = 0
        for _, p in ipairs(durotar) do tiles = tiles + #p[5] end
        assert(MR.Update() == tiles, "nicht alle Kacheln: " .. tostring(MR.drawn) .. " von " .. tiles)
        assert(MR.Check(1411).status == "unchecked", "ohne Erkundetes nicht ungeprueft")
        assert(MR.layer:GetParent() == canvas and MR.layer:GetFrameLevel() == 37, "nicht auf der Ebene der erkundeten Teile")
        assert(MR.tex[1].col[1] == MR.TINT and MR.tex[1].col[4] == 1, "nicht abgedunkelt")

        -- Kacheln wie in den Spieldaten: Zeile fuer Zeile, Rest auf die
        -- naechste Zweierpotenz.
        -- Ein Teil mit Rest in beiden Richtungen (2 x 2 Kacheln, keine voll).
        local big, bigMap
        for _, z in pairs(data) do
            for _, p in ipairs(z) do
                if not big and p[1] > 256 and p[1] < 512 and p[2] > 256 and p[2] < 512 and p[1] % 256 ~= 0 and p[2] % 256 ~= 0 then
                    big, bigMap = p, z.map
                end
            end
        end
        assert(big, "kein Teil mit Rest im Bestand")
        mapID = bigMap
        MR.Update()
        local function Find(file) for _, t in ipairs(MR.tex) do if t.file == file and t:IsShown() then return t end end end
        local t1, t2, t3, t4 = Find(big[5][1]), Find(big[5][2]), Find(big[5][3]), Find(big[5][4])
        assert(t1 and t2 and t3 and t4, "Kacheln des Teils fehlen")
        local rw, rh = big[1] - 256, big[2] - 256
        local function P2(n) local q = 1 while q < n do q = q * 2 end return q end
        assert(t1._width == 256 and t1._height == 256 and t1.tc[2] == 1 and t1.pt[4] == big[3] and t1.pt[5] == -big[4], "Kachel oben links")
        assert(t2._width == rw and t2._height == 256 and t2.tc[2] == rw / P2(rw) and t2.tc[4] == 1
            and t2.pt[4] == big[3] + 256 and t2.pt[5] == -big[4], "Kachel oben rechts")
        assert(t3._width == 256 and t3._height == rh and t3.tc[4] == rh / P2(rh) and t3.pt[4] == big[3]
            and t3.pt[5] == -(big[4] + 256), "Kachel unten links")
        assert(t4._width == rw and t4._height == rh and t4.pt[4] == big[3] + 256 and t4.pt[5] == -(big[4] + 256), "Kachel unten rechts")
        mapID = 1411
        MR.Update()

        -- Erkundet und passend: das Erkundete zeichnet das Spiel, wir den Rest.
        -- Neu erkundet meldet das Spiel mit einem Ereignis - das allein reicht.
        explored = { Info(durotar[1]), Info(durotar[2]) }
        MR.events:GetScript("OnEvent")(MR.events, "MAP_EXPLORATION_UPDATED")
        local n = MR.Update()
        assert(MR.Check(1411).status == "fits" and n == tiles - #durotar[1][5] - #durotar[2][5], "Erkundetes doppelt gezeichnet: " .. n)
        assert(not Find(durotar[1][5][1]), "erkundetes Teil von WeintCodex gezeichnet")
        -- Abdunkeln aus: volle Helligkeit.
        K.Set("comfort", "mapRevealTint", false)
        MR.Update()
        assert(MR.tex[1].col[1] == 1, "abgedunkelt, obwohl aus")
        K.Set("comfort", "mapRevealTint", true)

        -- Passt nicht (anderes Bild oder unbekanntes Teil): Zone bleibt, wie sie ist.
        explored = { Info(durotar[1], { 1 }) }
        MR.Forget()
        MR.Update()
        local c = MR.Check(1411)
        assert(c.status == "mismatch" and MR.drawn == 0, "trotz falscher Bilder aufgedeckt")
        for _, t in ipairs(MR.tex) do assert(not t:IsShown(), "Kacheln von vorher bleiben stehen") end
        explored = { { textureWidth = 10, textureHeight = 10, offsetX = 1, offsetY = 1, fileDataIDs = { 5 } } }
        MR.Forget()
        MR.Update()
        assert(MR.Check(1411).status == "mismatch" and MR.drawn == 0, "trotz unbekanntem Teil aufgedeckt")
        local sc = table.concat(MR.StatusLines(), "\n")
        assert(sc:find("1 passen nicht: Durotar", 1, true) and sc:find("44 Zonen", 1, true), "Selbstpruefung: " .. sc)

        -- Leatrix Maps geladen: es deckt auf, wir nicht.
        explored = {}
        MR.Forget()
        G.C_AddOns = { IsAddOnLoaded = function(n) return n == "Leatrix_Maps" end }
        assert(not MR.Active() and MR.Update() == 0 and not MR.tex[1]:IsShown(), "doppelt zu Leatrix Maps")
        G.C_AddOns = { IsAddOnLoaded = function() return false end }
        assert(MR.Update() > 0, "kommt nach Leatrix nicht wieder")

        -- Karte zu: nichts; nie in die Karte geschrieben.
        wm:Hide()
        assert(MR.Update() == 0 and not MR.layer:IsShown(), "gezeichnet bei geschlossener Karte")
        assert(wrote == 0, "in die Weltkarte geschrieben")
    end)
    for i, n in ipairs(names) do G[n] = saved[i] end
    K.Set("comfort", "mapReveal", false)
    K.Set("comfort", "mapRevealTint", true)
    MR.Forget()
    Check(ok, "Karte aufdecken: Bestand, Gegenprobe mit dem Erkundeten, nur Unerkundetes abgedunkelt, Kacheln wie im Spiel, Leatrix hat Vorrang"
        .. (ok and "" or (": " .. tostring(err))))
end

-- 6.13.2.0: die Regelliste zeigt nur, was fuer diesen Charakter gilt
-- (Beta-Test: "Ich sehe in den Erinnerungen alle Erinnerungen von allen
-- Charakteren"). Alte Begleiter-/Munitionsregeln ohne Klasse gelten nur, wo
-- die Klasse sie vorschlaegt. Dazu die Messung der Laune in /wcui pruefen.
do
    local saved = { _G.UnitClass, _G.UnitExists, _G.GetPetHappiness, _G.PetPaperDollPetHappinessInfo, _G.C_PetHappy, _G.C_PetInfo, _G.issecretvalue }
    local R = WeintCodex.UIReminders
    local ok, err = pcall(function()
        _G.UnitClass = function() return "Jäger", "HUNTER", 3 end
        -- Alte Regeln ohne Klasse: Begleiter, Laune, Munition beim Jaeger ja.
        for _, kind in ipairs({ "pet", "happy", "ammo" }) do
            assert(R.Applies({ kind = kind }, "HUNTER"), kind .. " ohne Klasse gilt beim Jaeger nicht")
            assert(not R.Applies({ kind = kind }, "WARRIOR"), kind .. " ohne Klasse gilt beim Krieger")
        end
        assert(R.Applies({ kind = "pet" }, "WARLOCK") and not R.Applies({ kind = "happy" }, "WARLOCK"),
            "Hexenmeister: Begleiter ja, Laune nein")
        assert(R.Applies({ kind = "pet", class = R.ALL }, "WARRIOR"), "Regel fuer alle gilt nicht ueberall")
        assert(R.Applies({ kind = "weapon", hand = "main" }, "SHAMAN") and not R.Applies({ kind = "weapon", hand = "off" }, "SHAMAN"),
            "Schamane: alte Nebenhand-Regel gilt")

        -- Liste: Jaeger sieht seine Regeln, die anderen als eine Zeile.
        R.listAll = false
        R.SetRules({
            { kind = "buff", spell = "Schlachtruf", class = "WARRIOR" },
            { kind = "pet" },
            { kind = "buff", spell = "Inneres Feuer", class = "PRIEST" },
            { kind = "ammo", min = 200, class = "HUNTER" },
            { kind = "weapon", hand = "main" },
        })
        local listed, hidden = R.ListedRules()
        assert(#listed == 2 and hidden == 3, "Liste nicht gefiltert: " .. #listed .. "/" .. hidden)
        assert(listed[1].index == 2 and listed[2].index == 4, "Liste traegt die falschen Stellen")
        local w = R.BuildRuleList(UIParent, 500)
        w.Sync()
        assert(w.rows[1]:IsShown() and w.rows[2]:IsShown() and not w.rows[3]:IsShown(), "falsche Zeilen sichtbar")
        assert(w.rows[1].text:GetText():find("Begleiter fehlt", 1, true), "erste Zeile nicht der Begleiter: " .. w.rows[1].text:GetText())
        assert(w.more:GetText():find("3 Regeln anderer Klassen ausgeblendet", 1, true), "Ausgeblendete nicht gezaehlt: " .. w.more:GetText())
        assert(w.toggle:IsShown(), "kein Knopf fuer die anderen")
        -- Entfernen trifft die Regel der Zeile, nicht die n-te gespeicherte.
        w.rows[2].remove:Click()
        assert(#R.Rules() == 4 and R.Rules()[2].kind == "pet" and R.Rules()[3].spell == "Inneres Feuer"
            and R.Rules()[4].kind == "weapon", "falsche Regel entfernt")
        w.Sync()
        -- "Alle zeigen": die anderen dazu, blass; zurueck mit demselben Knopf.
        w.toggle:Click()
        assert(R.listAll and #R.ListedRules() == 4, "Alle zeigen zeigt nicht alle")
        assert(w.rows[1].text:GetText():find("(hier aus)", 1, true), "fremde Regel nicht als aus markiert")
        assert(w.more:GetText() == "", "im Modus 'alle' trotzdem ausgeblendet gezaehlt")
        w.toggle:Click()
        assert(not R.listAll, "zurueck auf 'nur diese Klasse' geht nicht")
        -- Nur fremde Regeln: Hinweis statt leerer Flaeche.
        R.SetRules({ { kind = "buff", spell = "Schlachtruf", class = "WARRIOR" } })
        w.Sync()
        assert(w.empty:IsShown() and w.empty:GetText():find("Für diese Klasse noch keine Regel", 1, true), "leere Liste ohne Hinweis")
        -- Nur eigene: kein Knopf, keine Zaehlzeile - auch im Modus "alle".
        R.SetRules({ { kind = "ammo", min = 200, class = "HUNTER" } })
        w.Sync()
        assert(not w.toggle:IsShown() and w.more:GetText() == "", "Knopf ohne fremde Regeln")
        R.listAll = true
        w.Sync()
        assert(not w.toggle:IsShown(), "Knopf im Modus 'alle' ohne fremde Regeln")
        R.listAll = false

        -- /wcui pruefen, Begleiter: ohne Begleiter offen; mit: was der Client fuehrt.
        local SC = WeintCodex.UISelfCheck
        local function run()
            local lines = {}
            for _, c in ipairs(SC.CHECKS) do
                if c.name == "Begleiter" then
                    c.fn(function(mark, text) lines[#lines + 1] = (mark ~= "" and (mark .. " ") or "") .. text end)
                end
            end
            return table.concat(lines, "\n")
        end
        _G.UnitExists = function(u) return u ~= "pet" end
        assert(run():find("[?] Kein Begleiter", 1, true), "ohne Begleiter nicht offen")
        _G.UnitExists = function() return true end
        _G.GetPetHappiness = nil
        _G.C_PetHappy = { GetPetHappiness = function() return 3 end }
        local tex = stub.NewObject("Texture")
        tex.GetAtlas = function() return "UI-PetHappiness" end
        tex.GetTexCoord = function() return 0, 0.1875, 0, 0.359375 end
        _G.PetPaperDollPetHappinessInfo = { Texture = tex, happiness = 3, tooltip = "Glücklich" }
        local out = run()
        assert(out:find("[!] Laune nicht lesbar", 1, true), "fehlende Laune nicht als Befund: " .. out)
        assert(out:find("GetPetHappiness: gibt es nicht", 1, true), "fehlende Abfrage nicht genannt")
        assert(out:find("C_PetHappy.GetPetHappiness", 1, true), "Funktion in C_* nicht gefunden: " .. out)
        assert(out:find("happiness=3", 1, true) and out:find("tooltip=Glücklich", 1, true), "Werte des Spielrahmens fehlen: " .. out)
        assert(out:find("Atlas UI-PetHappiness", 1, true) and out:find("0.188", 1, true), "Bild des Spielrahmens fehlt: " .. out)
        assert(out:find("Ereignis UNIT_HAPPINESS", 1, true), "Ereignis nicht geprueft")
        assert(out:find("Quelle: keine", 1, true), "fehlende Quelle nicht genannt: " .. out)
        _G.GetPetHappiness = function() return 2, 100, 0 end
        out = run()
        assert(out:find("[ok] Laune gelesen: 2 (zufrieden)", 1, true) and out:find("GetPetHappiness(): 2, 100, 0, leer", 1, true),
            "gelesene Laune nicht berichtet: " .. out)
        -- Forever: C_PetInfo, ohne und mit "pet", geheim als Wort.
        _G.GetPetHappiness = nil
        local secret = {}
        _G.issecretvalue = function(v) return v == secret end
        _G.C_PetInfo = { GetPetHappiness = function(u) if u == "pet" then return secret, 125 end end }
        out = run()
        _G.issecretvalue = nil
        assert(out:find("C_PetInfo.GetPetHappiness(): leer, leer, leer, leer", 1, true)
            and out:find('C_PetInfo.GetPetHappiness("pet"): geheim, 125, leer, leer', 1, true)
            and out:find("Quelle: C_PetInfo.GetPetHappiness", 1, true), "Antworten von C_PetInfo nicht berichtet: " .. out)
    end)
    _G.UnitClass, _G.UnitExists, _G.GetPetHappiness, _G.PetPaperDollPetHappinessInfo, _G.C_PetHappy, _G.C_PetInfo, _G.issecretvalue = unpack(saved, 1, 7)
    R.listAll = false
    K.Set("reminders", "rules", nil)
    Check(ok, "Erinnerungen nur fuer diesen Charakter, Entfernen je Zeile, Alle zeigen; Laune messen"
        .. (ok and "" or (": " .. tostring(err))))
end

-- 6.9.0.3: der Zauberbalken des Spiels an Ziel und Fokus ist weg. Beta-Test:
-- beim Unterbrechen erschien ueber dem Zielrahmen der Balken des Spiels in
-- Rot - der Zielrahmen des Spiels lebt fuer seine Auren, und die
-- Animation "Unterbrochen" setzt die Deckkraft an SetAlpha vorbei.
-- 6.9.0.4: NICHT umhaengen - das Spiel fragt in AdjustPosition seinen
-- Elternrahmen (ShouldAnchorSpellBarToAuraContainer); 6.9.0.3 hing ihn an
-- einen leeren Rahmen, und beim Anvisieren des Auktionators kam
-- "TargetFrame.lua:829: attempt to call a nil value".
do
    local ok, err = pcall(function()
        local UF = WeintCodex.UIUnitFrames
        local saved = { _G.TargetFrameSpellBar, _G.FocusFrameSpellBar, _G.FocusFrame, _G.hooksecurefunc }
        _G.hooksecurefunc = function(obj, name, fn)
            local orig = obj[name]
            obj[name] = function(...) local r = orig(...) fn(...) return r end
        end
        local unreg = {}
        local function Bar(name, owner)
            local b = stub.NewObject("StatusBar", name)
            b:SetParent(owner)
            b:Show()
            b.UnregisterAllEvents = function(self) unreg[self] = true end
            -- wie TargetSpellBarMixin:AdjustPosition im Quelltext des Spiels
            b.AdjustPosition = function(self) return self:GetParent():ShouldAnchorSpellBarToAuraContainer() end
            return b
        end
        local function Owner()
            local o = stub.NewObject("Frame")
            o.ShouldAnchorSpellBarToAuraContainer = function() return false end
            return o
        end
        -- Ueber den Namen.
        local towner = Owner()
        local tbar = Bar("TargetFrameSpellBar", towner)
        _G.TargetFrameSpellBar = tbar
        assert(UF.HideGameCastBar("target") == tbar, "Zauberbalken des Ziels nicht gefunden")
        assert(not tbar:IsShown() and unreg[tbar], "Zauberbalken des Ziels nicht still (sichtbar oder Ereignisse)")
        assert(tbar:GetParent() == towner, "Zauberbalken umgehaengt - AdjustPosition des Spiels scheitert")
        assert(pcall(tbar.AdjustPosition, tbar), "AdjustPosition des Spiels scheitert")
        -- Zeigt ihn doch jemand: er bleibt weg.
        tbar:Show()
        assert(not tbar:IsShown(), "Zauberbalken laesst sich wieder zeigen")
        tbar:SetShown(true)
        assert(not tbar:IsShown(), "Zauberbalken laesst sich ueber SetShown zeigen")
        -- Ohne globalen Namen: ueber das Feld am Rahmen.
        _G.FocusFrameSpellBar = nil
        _G.FocusFrame = Owner()
        local fbar = Bar(nil, _G.FocusFrame)
        _G.FocusFrame.spellbar = fbar
        assert(UF.HideGameCastBar("focus") == fbar and not fbar:IsShown() and fbar:GetParent() == _G.FocusFrame,
            "Zauberbalken des Fokus bleibt oder wird umgehaengt")
        assert(UF.HideGameCastBar("player") == nil, "Spieler hat hier keinen Balken des Spiels")
        _G.TargetFrameSpellBar, _G.FocusFrameSpellBar, _G.FocusFrame, _G.hooksecurefunc = saved[1], saved[2], saved[3], saved[4]
        -- Der Aufbau ruft es fuer jeden ersetzten Rahmen.
        local h = io.open(ROOT .. "/ui/unitframes.lua", "r")
        local code = h:read("*a"):gsub("%-%-[^\n]*", "")
        h:close()
        local build = code:match("local function Build%(%)(.-)\nend")
        assert(build and build:find("UF.HideGameCastBar(u)", 1, true), "Aufbau legt die Zauberbalken des Spiels nicht still")
    end)
    Check(ok, "Zauberbalken des Spiels an Ziel und Fokus still, am eigenen Elternrahmen (AdjustPosition des Spiels laeuft)"
        .. (ok and "" or (": " .. tostring(err))))
end

-- 6.4.0.3: Debuffs am Zielrahmen - der Aurenbehaelter des Zielrahmens des
-- Spiels haengt ueber unserem, alles andere an ihm unsichtbar und ohne Maus.
do
    local ok, err = pcall(function()
        local UF = WeintCodex.UIUnitFrames
        assert(UF.frames.target, "kein Zielrahmen gebaut")
        -- Ohne Zielrahmen des Spiels (Attrappe): eigene Symbole, benannt.
        assert(UF.gameAuraState:find("eigene Symbole", 1, true), "Rueckfall ohne Auskunft: " .. tostring(UF.gameAuraState))

        local tf = stub.NewObject("Frame", "TargetFrame")
        local content = stub.NewObject("Frame")
        local ctx = stub.NewObject("Frame")
        local auras = stub.NewObject("AuraContainer")
        local container, tot, portraitTex = stub.NewObject("Frame"), stub.NewObject("Button"), stub.NewObject("Texture")
        local main, ping = stub.NewObject("Frame"), stub.NewObject("Frame")
        tf.TargetFrameContent, content.TargetFrameContentContextual, ctx.Auras = content, ctx, auras
        tf.GetChildren = function() return container, content, tot end
        tf.GetRegions = function() return portraitTex end
        content.GetChildren = function() return main, ctx end
        ctx.GetChildren = function() return ping, auras end
        local mouse = {}
        for _, f in ipairs({ tf, content, ctx, auras, container, tot, main, ping }) do
            f.EnableMouse = function(self, on) mouse[self] = on end
        end
        local cfg = {}
        auras.SetFlowLayoutMirroredVertically = function(_, v) cfg.mirror = v end
        auras.SetNumConstrainedFlowLayoutLines = function(_, v) cfg.constrained = v end
        auras.SetFlowLayoutMaximumLineSize = function(_, v) cfg.line = v end
        local anchor
        auras.SetPoint = function(_, pt, rel, relPt) anchor = { pt, rel, relPt } end
        tf.ConfigureAuraContainer = function() cfg.mirror = false cfg.constrained = 2 end
        tf.AnchorAuraContainer = function() anchor = { "TOPLEFT", tf, "BOTTOMLEFT" } end

        local oldTF, oldHook = _G.TargetFrame, _G.hooksecurefunc
        _G.TargetFrame = tf
        _G.hooksecurefunc = function(obj, name, fn)
            local orig = obj[name]
            obj[name] = function(...) local r = orig(...) fn(...) return r end
        end
        K.Set("unitframes", "targetAuraSource", "game")
        assert(UF._SetupGameAuras(), "Weg des Spiels nicht genommen: " .. tostring(UF.gameAuraState))
        assert(auras:GetAlpha() == 1, "Symbole des Spiels unsichtbar")
        assert(container:GetAlpha() == 0 and tot:GetAlpha() == 0 and main:GetAlpha() == 0
            and ping:GetAlpha() == 0 and portraitTex:GetAlpha() == 0, "Rest des Zielrahmens des Spiels sichtbar")
        assert(mouse[tf] == false and mouse[tot] == false and mouse[ping] == false, "unsichtbarer Rahmen faengt Klicks")
        assert(mouse[auras] == nil, "Symbole ohne Maus - kein Tooltip")
        assert(cfg.mirror == true and cfg.constrained == 0 and cfg.line, "Behaelter nicht eingestellt")
        assert(anchor[1] == "BOTTOMLEFT" and anchor[2] == UF.frames.target and anchor[3] == "TOPLEFT", "Behaelter nicht ueber dem Zielrahmen")
        -- Das Spiel stellt neu ein und setzt neu an: unsere Werte gewinnen.
        tf:ConfigureAuraContainer()
        tf:AnchorAuraContainer()
        assert(cfg.mirror == true and cfg.constrained == 0, "Spiel stellt den Behaelter zurueck")
        assert(anchor[2] == UF.frames.target, "Spiel setzt den Behaelter zurueck an seinen Rahmen")
        -- 6.4.0.4: rechtsbuendig, Abstand, Groesse ueber die Symbolgroessen.
        local oldAU = _G.AnchorUtil
        _G.AnchorUtil = { FlowDirection = { Left = 1, Right = 2, Up = 3, Down = 4 } }
        local flow = {}
        auras.SetFlowLayoutAnchorPoint = function(_, p) flow.anchor = p end
        auras.SetFlowLayoutGrowthDirection = function(_, h, v) flow.h, flow.v = h, v end
        local sizes = { 17, 21 }
        auras.GetSmallAuraSize = function() return sizes[1] end
        auras.GetLargeAuraSize = function() return sizes[2] end
        auras.SetSmallAuraSize = function(_, v) sizes[1] = v end
        auras.SetLargeAuraSize = function(_, v) sizes[2] = v end
        local lastY
        auras.SetPoint = function(_, pt, rel, relPt, x, y) anchor = { pt, rel, relPt } lastY = y end
        K.Set("unitframes", "targetAuraAlign", "right")
        assert(flow.anchor == "BOTTOMRIGHT" and flow.h == 1 and flow.v == 3, "rechtsbuendig: Fluss nicht von rechts")
        assert(anchor[1] == "BOTTOMRIGHT" and anchor[3] == "TOPRIGHT", "rechtsbuendig: Behaelter nicht rechts")
        K.Set("unitframes", "targetAuraGap", 12)
        assert(lastY == 12, "Abstand nicht uebernommen: " .. tostring(lastY))
        K.Set("unitframes", "targetGameScale", 200)
        assert(sizes[1] == 34 and sizes[2] == 42, "Groesse nicht ueber die Symbolgroessen: " .. sizes[1] .. "/" .. sizes[2])
        K.Set("unitframes", "targetGameScale", 100)
        assert(sizes[1] == 17 and sizes[2] == 21, "Groesse kommt nicht zurueck")
        K.Set("unitframes", "targetAuraAlign", "left")
        assert(flow.anchor == "BOTTOMLEFT" and flow.h == 2 and anchor[1] == "BOTTOMLEFT", "zurueck auf linksbuendig greift nicht")
        K.Set("unitframes", "targetAuraGap", nil)
        _G.AnchorUtil = oldAU

        -- Ausgeschaltet: Behaelter weg, eigene Symbole ebenfalls.
        K.Set("unitframes", "targetAuras", false)
        assert(not auras:IsShown(), "Symbole trotz Aus")
        K.Set("unitframes", "targetAuras", true)
        assert(auras:IsShown(), "Symbole kommen nicht zurueck")
        for _, obj in pairs(UF.frames.target._auras) do
            assert(not obj.frame:IsShown(), "eigene Symbole zusaetzlich zu denen des Spiels")
        end
        _G.TargetFrame, _G.hooksecurefunc = oldTF, oldHook
    end)
    Check(ok, "Zielrahmen: Auren des Spiels ueber dem Rahmen" .. (ok and "" or (": " .. tostring(err))))
end

-- 6.4.1.0: Abklingzeitmanager des Spiels im WeintCodex-Stil (Reiter der
-- Erinnerungen): eckig, ohne Schmuck, eigene Schrift - Daten bleiben die
-- des Spiels.
do
    local ok, err = pcall(function()
        local CD = WeintCodex.UICooldowns
        local m = K.Module("reminders")
        assert(CD and CD.PAGE and m.pages[CD.PAGE].key == "abklingzeitmanager", "kein Reiter Abklingzeitmanager an den Erinnerungen")
        assert(not K.Module("cooldowns"), "eigener Eintrag in der vollen Seitenleiste")

        local function IconItem()
            local item = stub.NewObject("Frame")
            local icon = stub.NewObject("Texture")
            local mask = stub.NewObject("MaskTexture")
            local masks = { mask }
            icon.GetNumMaskTextures = function() return #masks end
            icon.GetMaskTexture = function(_, i) return masks[i] end
            icon.RemoveMaskTexture = function(_, mt) for i, x in ipairs(masks) do if x == mt then table.remove(masks, i) end end end
            local overlay = stub.NewObject("Texture")
            overlay.GetAtlas = function() return "UI-HUD-CoolDownManager-IconOverlay" end
            local oor = stub.NewObject("Texture")
            oor.GetAtlas = function() return "UI-CooldownManager-OORshadow" end
            item.Icon = icon
            item.GetRegions = function() return icon, overlay, oor end
            local cd = stub.NewObject("Cooldown")
            local got = {}
            cd.SetSwipeTexture = function(_, t) got.swipe = t end
            cd.SetCountdownFont = function(_, f) got.font = f end
            item.Cooldown = cd
            item.ChargeCount = { Current = stub.NewObject("FontString") }
            return item, masks, overlay, oor, got
        end
        local item1, masks1, overlay1, oor1, got1 = IconItem()
        local acquired = {}
        local viewer = stub.NewObject("Frame", "EssentialCooldownViewer")
        viewer.OnAcquireItemFrame = function(self, item) acquired[#acquired + 1] = item end
        viewer.itemFramePool = { EnumerateActive = function()
            local i = 0
            return function() i = i + 1 if i == 1 then return item1 end end
        end }

        -- Buff-Balken.
        local barItem = stub.NewObject("Frame")
        local iconFrame = stub.NewObject("Frame")
        iconFrame.Icon = stub.NewObject("Texture")
        iconFrame.Applications = stub.NewObject("FontString")
        local bar = stub.NewObject("StatusBar")
        bar.BarBG, bar.Pip = stub.NewObject("Texture"), stub.NewObject("Texture")
        bar.Name, bar.Duration = stub.NewObject("FontString"), stub.NewObject("FontString")
        local barTex
        bar.SetStatusBarTexture = function(_, t) barTex = t end
        barItem.Icon, barItem.Bar = iconFrame, bar
        local barViewer = stub.NewObject("Frame", "BuffBarCooldownViewer")
        barViewer.OnAcquireItemFrame = function() end
        barViewer.itemFramePool = { EnumerateActive = function()
            local i = 0
            return function() i = i + 1 if i == 1 then return barItem end end
        end }

        local oldE, oldB, oldHook = _G.EssentialCooldownViewer, _G.BuffBarCooldownViewer, _G.hooksecurefunc
        _G.EssentialCooldownViewer, _G.BuffBarCooldownViewer = viewer, barViewer
        _G.hooksecurefunc = function(obj, name, fn)
            local orig = obj[name]
            obj[name] = function(...) local r = orig(...) fn(...) return r end
        end
        CD.SkinAll()
        assert(CD.state:find("2 Anzeigen", 1, true), "Anzeigen nicht gefunden: " .. tostring(CD.state))
        assert(#masks1 == 0, "runde Maske noch am Symbol")
        assert(overlay1:GetAlpha() == 0, "Rahmenschmuck des Spiels sichtbar")
        assert(oor1:GetAlpha() == 1, "Ausser-Reichweite-Schatten versteckt - der traegt Bedeutung")
        assert(got1.swipe and got1.font == "WeintCodexCooldownManagerFont", "Abdeckung oder Schrift nicht gesetzt")
        assert(item1.ChargeCount.Current._font, "Ladungen ohne Schrift")
        assert(bar.BarBG:GetAlpha() == 0 and bar.Pip:GetAlpha() == 0, "Balkenschmuck des Spiels sichtbar")
        assert(barTex, "Balken ohne Textur der Oberflaeche")
        assert(bar.Name._font and bar.Duration._font, "Balkentexte ohne Schrift")
        -- Ein neues Symbol aus dem Vorrat: per Haken, genau einmal umgestaltet.
        local item2, masks2, overlay2 = IconItem()
        viewer:OnAcquireItemFrame(item2)
        assert(acquired[1] == item2, "Haken verschluckt den Aufruf des Spiels")
        assert(#masks2 == 0 and overlay2:GetAlpha() == 0, "neues Symbol nicht umgestaltet")
        local d = CD.skinned[item2]
        viewer:OnAcquireItemFrame(item2)
        assert(CD.skinned[item2] == d, "Symbol doppelt umgestaltet")
        -- 6.4.1.1: eckige Symbole ueberlappten - das Spiel setzt sie 4 px
        -- enger als eingestellt. Einzug so, dass 2 px Luft bleiben.
        assert(CD.Inset({ iconPadding = 2 }) == 3, "Einzug beim Standardabstand")
        assert(CD.Inset({ iconPadding = 8 }) == 1, "Einzug bei grossem Abstand")
        assert(CD.Inset({}) == 3, "Einzug ohne Antwort des Spiels")
        for _, pad in ipairs({ 0, 2, 4, 6 }) do
            local gap = (pad - 4) + 2 * CD.Inset({ iconPadding = pad }) - 2
            assert(gap >= 2, "Symbole ueberlappen bei Abstand " .. pad .. ": " .. gap .. " px")
        end
        -- Kein Feld am Rahmen des Spiels geschrieben.
        for k in pairs(item2) do
            assert(k:sub(1, 1) == "_" or ({ Icon = 1, GetRegions = 1, Cooldown = 1, ChargeCount = 1 })[k], "Feld am Symbol des Spiels geschrieben: " .. k)
        end
        _G.EssentialCooldownViewer, _G.BuffBarCooldownViewer, _G.hooksecurefunc = oldE, oldB, oldHook
    end)
    Check(ok, "Abklingzeitmanager: Symbole und Balken im WeintCodex-Stil" .. (ok and "" or (": " .. tostring(err))))
end

-- 6.4.1.2: Zauberbuch im Stil der Oberflaeche - Pergament weg, dunkle
-- Schrift hell, Zaubersymbole eckig mit Rand.
do
    local ok, err = pcall(function()
        local W = WeintCodex.UIWindows
        assert(W.HidesAtlas("spellbook-background-evergreen-left"), "Pergament des Zauberbuchs bleibt")
        assert(W.HidesAtlas("spellbook-item-backplate"), "Schatten hinter Zaubern bleibt")
        assert(W.HidesAtlas("Talents-Main-Ring-c60") and W.HidesAtlas("spellbook-Tab-Frame-C60"), "Goldschmuck (gemessen) bleibt")
        assert(not W.HidesAtlas("spellbook-Tab-Frame-Glow-C60"), "Schein des gewaehlten Reiters ausgeblendet")
        assert(not W.HidesAtlas("talents-node-square-green"), "Zustandsrahmen der Talente ausgeblendet")
        assert(not W.HidesAtlas("spellbook-item-needtrainer-shadow"), "Lehrer-Hinweis ausgeblendet - der traegt Bedeutung")
        assert(W.IsDark(0.25, 0.18, 0.11) and not W.IsDark(1, 0.82, 0) and not W.IsDark(0.1, 1, 0.1), "hell/dunkel falsch")

        local book = stub.NewObject("Frame", "SpellBookFrame")
        local item = stub.NewObject("Frame")
        local btn = stub.NewObject("Button")
        local icon, border, mask = stub.NewObject("Texture"), stub.NewObject("Texture"), stub.NewObject("MaskTexture")
        local removed
        icon.RemoveMaskTexture = function(_, m) removed = m end
        btn.Icon, btn.Border, btn.IconMask = icon, border, mask
        item.Button = btn
        local name, gold = stub.NewObject("FontString"), stub.NewObject("FontString")
        name._font, gold._font = true, true
        local col = { [name] = { 0.25, 0.18, 0.11 }, [gold] = { 1, 0.82, 0 } }
        for fs, c in pairs(col) do
            fs.GetTextColor = function() return c[1], c[2], c[3], 1 end
            fs.SetTextColor = function(_, r, g, b) col[fs] = { r, g, b } end
        end
        item.GetRegions = function() return name, gold end
        book.GetChildren = function() return item end
        W.SkinSpellItems(book)
        W.LightenText(book)
        assert(border:GetAlpha() == 0, "Zierrahmen des Zaubers sichtbar")
        assert(removed == mask, "runde Maske am Zaubersymbol")
        assert(not W.IsDark(col[name][1], col[name][2], col[name][3]), "Pergament-Schrift bleibt dunkel")
        assert(col[gold][1] == 1 and col[gold][2] == 0.82, "farbige Schrift umgefaerbt")
        _G.SpellBookFrame = nil

        -- 6.4.1.3: grosse Bilder (Pergament, Talent-Landschaften) nach
        -- Flaeche; Talentfenster ueber den Namen gefunden.
        local oldHookW = _G.hooksecurefunc
        _G.hooksecurefunc = function(obj, name, fn)
            local orig = obj[name]
            obj[name] = function(...) local r = orig(...) fn(...) return r end
        end
        local tf = stub.NewObject("Frame", "ForeverTalentFrame")
        tf._width, tf._height = 1000, 600
        _G.ForeverTalentFrame = tf   -- benannte Rahmen sind im Client global
        local art, icon2, own = stub.NewObject("Texture"), stub.NewObject("Texture"), nil
        art._width, art._height = 330, 560
        icon2._width, icon2._height = 36, 36
        local tree = stub.NewObject("Frame")
        tree.GetRegions = function() return art, icon2 end
        tf.GetChildren = function() return tree end
        assert(W.Adopt(tf), "Talentfenster nicht aufgenommen")
        assert(W.done[tf] and W.done[tf].kachel, "Talentfenster ohne Kachel")
        own = W.done[tf].kachel.bg
        tf.GetRegions = function() return own end
        W.Inner()
        -- 6.4.1.4: Landschaften gedaempft statt weg ("nur schwarz ist langweilig").
        local tone = WeintCodex.GameColors.artTone
        assert(W.toned[art] and art:GetAlpha() == tone[4], "Landschaft des Talentbaums nicht gedaempft")
        art:SetAlpha(1)   -- das Spiel setzt zurueck ...
        assert(W.toned[art] and art:GetAlpha() == tone[4], "Spiel hebt die Daempfung auf")
        assert(icon2:GetAlpha() == 1, "Talentsymbol ausgeblendet")
        assert(own:GetAlpha() == 1, "eigene Kachel ausgeblendet")
        -- Ohne "Stimmung": weg, wie 6.4.1.3.
        K.Set("general", "windowArt", false)
        local art2 = stub.NewObject("Texture")
        art2._width, art2._height = 330, 560
        tree.GetRegions = function() return art, icon2, art2 end
        W.Inner()
        assert(art2:GetAlpha() == 0 and not W.toned[art2], "ohne Stimmung bleibt die Landschaft")
        K.Set("general", "windowArt", nil)
        -- Schein in der Klassenfarbe: nur mit Antwort des Spiels.
        local oldUC, oldRCC = _G.UnitClass, _G.RAID_CLASS_COLORS
        _G.UnitClass = function() return "Krieger", "WARRIOR", 1 end
        _G.RAID_CLASS_COLORS = { WARRIOR = { r = 0.78, g = 0.61, b = 0.43 } }
        local d2 = {}
        W.AddGlow(stub.NewObject("Frame"), d2)
        assert(d2.glow and W.own[d2.glow], "kein Schein in der Klassenfarbe")
        _G.RAID_CLASS_COLORS = nil
        local d3 = {}
        W.AddGlow(stub.NewObject("Frame"), d3)
        assert(not d3.glow, "Schein ohne Klassenfarbe geraten")
        _G.UnitClass, _G.RAID_CLASS_COLORS = oldUC, oldRCC

        -- 6.4.1.5: Gold an Bedienelementen.
        assert(W.Desaturates("RedButton-Exit") and W.Desaturates("common-dropdown-a-button"), "rote/gelbe Knoepfe bleiben farbig")
        assert(not W.Desaturates("talents-node-square-green"), "Talentzustand entfaerbt")
        -- Reiter: Kachel, gewaehlter mit Akzent.
        local tabs = stub.NewObject("Frame")
        tabs.AddTab = function() end
        local t1, t2 = stub.NewObject("Button"), stub.NewObject("Button")
        for _, t in ipairs({ t1, t2 }) do
            t.Left, t.Middle, t.Right = stub.NewObject("Texture"), stub.NewObject("Texture"), stub.NewObject("Texture")
            t.MiddleActive = stub.NewObject("Texture")
        end
        t1.isSelected, t2.isSelected = true, false
        tabs.tabs = { t1, t2 }
        W.SkinTabSystems(tabs)
        assert(t1.Middle:GetAlpha() == 0 and t1.MiddleActive:GetAlpha() == 0, "Goldreiter sichtbar")
        -- 6.4.1.6: Reiter mit Bild (Zauberbuch-Kategorien): kein Goldschein,
        -- Rand innen am Bild, gewaehlter im Akzent.
        local cat = stub.NewObject("Frame")
        cat.AddTab = function() end
        local it = stub.NewObject("Button")
        local pic, frameArt, glow = stub.NewObject("Texture"), stub.NewObject("Texture"), stub.NewObject("Texture")
        pic._width, pic._height = 36, 36
        pic.GetTexture = function() return 135274 end
        frameArt.GetAtlas = function() return "spellbook-Tab-Frame-C60" end
        glow.GetAtlas = function() return "spellbook-Tab-Frame-Glow-C60" end
        glow.GetTexture = function() return 999 end
        local backdrop = stub.NewObject("Texture")   -- dunkle Flaeche hinter dem Bild (gemessen)
        it.GetRegions = function() return pic, frameArt, glow, backdrop end
        it.isSelected = true
        cat.tabs = { it }
        W.SkinTabSystems(cat)
        local td = W.TabSkin[it]
        assert(td and td.icon == pic and not td.kachel, "Bildreiter nicht als solcher erkannt")
        assert(frameArt:GetAlpha() == 0 and glow:GetAlpha() == 0, "Goldrahmen/-schein am Bildreiter")
        assert(backdrop:GetAlpha() == 0, "dunkle Flaeche hinter dem Bild bleibt (Balken)")
        assert(pic:GetAlpha() == 1, "Bild des Reiters ausgeblendet")
        assert(td.sel == true, "gewaehlter Bildreiter ohne Akzent")
        -- 6.4.1.7: Schnitt relativ zum Ausschnitt des Spiels (Klassenbild
        -- aus einem Bogen: 0..0,25), und neu, wenn das Spiel ihn zuruecksetzt.
        local tc = { 0, 0, 0, 0.25, 0.25, 0, 0.25, 0.25 }
        pic.GetTexCoord = function() return unpack(tc) end
        pic.SetTexCoord = function(_, l, r, t, b) tc = { l, t, l, b, r, t, r, b } end
        W.SkinTabSystems(cat)
        assert(math.abs(tc[1] - 0.025) < 1e-6 and math.abs(tc[5] - 0.225) < 1e-6, "Klassenbild nicht relativ geschnitten: " .. tc[1] .. ".." .. tc[5])
        W.SkinTabSystems(cat)
        assert(math.abs(tc[1] - 0.025) < 1e-6, "doppelt geschnitten")
        tc = { 0.25, 0, 0.25, 0.25, 0.5, 0, 0.5, 0.25 }   -- das Spiel setzt neu
        W.SkinTabSystems(cat)
        assert(math.abs(tc[1] - 0.275) < 1e-6, "neuer Ausschnitt des Spiels nicht geschnitten")
        -- 6.5.0.0: Textreiter mit leerem, verstecktem .Icon (Talentfenster:
        -- Primaer/Sekundaer) bleiben Textreiter mit Kachel.
        local tt = stub.NewObject("Frame")
        tt.AddTab = function() end
        local prim = stub.NewObject("Button")
        prim.Left, prim.Middle, prim.Right = stub.NewObject("Texture"), stub.NewObject("Texture"), stub.NewObject("Texture")
        prim.Icon = stub.NewObject("Texture")
        prim.Icon.GetObjectType = function() return "Texture" end
        prim.Icon.GetTexture = function() return nil end
        prim.Icon:Hide()
        prim.Text = stub.NewObject("FontString")
        prim.Text._text = "Primär"
        prim.isSelected = true
        tt.tabs = { prim }
        W.SkinTabSystems(tt)
        local pd = W.TabSkin[prim]
        assert(pd and pd.kachel and not pd.icon, "Textreiter mit leerem Bild als Bildreiter behandelt")
        assert(prim.Text:GetAlpha() ~= 0, "Beschriftung des Textreiters ausgeblendet")
        -- Auch mit gesetztem Bild: eine sichtbare Beschriftung entscheidet.
        local sec = stub.NewObject("Button")
        sec.Icon = stub.NewObject("Texture")
        sec.Icon.GetObjectType = function() return "Texture" end
        sec.Icon.GetTexture = function() return 135274 end
        sec.Text = stub.NewObject("FontString")
        sec.Text._text = "Sekundär"
        assert(W.TabIcon(sec) == nil, "sichtbare Beschriftung ignoriert")
        sec.Text._text = ""
        assert(W.TabIcon(sec) == sec.Icon, "Bildreiter ohne Beschriftung nicht erkannt")
        -- Knopf "Aenderungen anwenden" (UIPanelButtonTemplate).
        local apply = stub.NewObject("Button")
        apply.Left, apply.Middle, apply.Right = stub.NewObject("Texture"), stub.NewObject("Texture"), stub.NewObject("Texture")
        local host = stub.NewObject("Frame")
        host.GetChildren = function() return apply end
        W.SkinPanelButtons(host)
        assert(apply.Middle:GetAlpha() == 0, "Goldknopf sichtbar")
        -- Werte: Name endet vor der Zahl.
        local stat = stub.NewObject("Frame")
        stat.Label, stat.Value = stub.NewObject("FontString"), stub.NewObject("FontString")
        local anchored
        stat.Label.SetPoint = function(_, pt, rel) if pt == "RIGHT" then anchored = rel end end
        local pane = stub.NewObject("Frame")
        pane.GetChildren = function() return stat end
        W.FitStats(pane)
        assert(anchored == stat.Value, "Name des Wertes laeuft in die Zahl")
        _G.hooksecurefunc = oldHookW
        assert(not W.Adopt(stub.NewObject("Frame", "MailFrame")), "fremdes Fenster aufgenommen")
        _G.ForeverTalentFrame = nil
    end)
    Check(ok, "Zauberbuch und Talente: Pergament weg, Schrift hell, Symbole eckig" .. (ok and "" or (": " .. tostring(err))))
end

-- 6.5.0.0: Beute je Boss und Quests je Dungeon auf der Dungeonseite.
do
    local ok, err = pcall(function()
        local DP, J = WeintCodex.DungeonPages, WeintCodex.DungeonJournal
        -- Boss mit drei berichteten Gegenstaenden.
        DP.Select("hall_of_thanes", "faldrim_anvilmar")
        WeintCodex.Navigation.SwitchTo("dungeons")
        assert(DP.itemRows == 3, "Beute von Faldrim Anvilmar: " .. tostring(DP.itemRows) .. " Zeilen statt 3")
        -- Der Client kennt die Gegenstaende noch nicht: angefragt und nachgezogen.
        assert(DP.pendingItems[270227], "unbekannter Gegenstand nicht zum Nachladen vorgemerkt")
        local row = DP.pendingItems[270227][1]
        assert(row.label:GetText() == "Ephemeral Choker", "Rueckfallname fehlt: " .. tostring(row.label:GetText()))
        local oldCI = _G.C_Item
        _G.C_Item = { GetItemInfo = function(id)
            if id == 270227 then return "Vergaenglicher Halsreif", "|Hitem:270227|h", 3, nil, nil, nil, nil, nil, nil, 135 end
        end }
        DP.itemEvents:GetScript("OnEvent")(DP.itemEvents, "GET_ITEM_INFO_RECEIVED", 270227, true)
        assert(row.label:GetText() == "Vergaenglicher Halsreif", "Name des Clients nicht nachgezogen")
        _G.C_Item = oldCI
        -- Dungeon ohne Boss: Quests mit ihren Belohnungen.
        DP.Select("hall_of_thanes", nil)
        WeintCodex.Navigation.SwitchTo("dungeons")
        assert(DP.itemRows > 0, "keine Questbelohnungen auf der Dungeonseite")
        -- Ein Dungeon ohne Journal zeichnet keine einzige Gegenstandszeile.
        -- (Seit 6.14.0.0 hat Maraudon Quests und Beute aus dem Abgleich -
        -- ohne Journal bleiben die Forever-Dungeons ohne Berichte.)
        assert(not J.Has("kroldok_stronghold"), "Krol'dok Stronghold hat ein Journal")
        DP.Select("kroldok_stronghold", nil)
        WeintCodex.Navigation.SwitchTo("dungeons")
        assert(DP.itemRows == 0, "Gegenstandszeilen in einem Dungeon ohne Journal")
    end)
    Check(ok, "Dungeonseite: Beute je Boss, Quests je Dungeon, Namen vom Client" .. (ok and "" or (": " .. tostring(err))))
end

-- 6.5.1.0: Questgeber auf der Weltkarte - Link je Quest mit bekannter
-- Lage, Klick oeffnet die Karte auf der Zone und setzt eine Marke.
do
    local ok, err = pcall(function()
        local DP, J, QM = WeintCodex.DungeonPages, WeintCodex.DungeonJournal, WeintCodex.QuestMap
        assert(J.Place(214) and J.Place(214).map == 1436, "Lage von Scout Riell fehlt")
        assert(J.Place(6981) == nil, "The Glowing Shard mit Lage eines Nicht-Gebers")
        for id, p in pairs(J.PLACES) do
            assert(type(p.map) == "number" and p.x > 0 and p.x < 1 and p.y > 0 and p.y < 1 and type(p.who) == "string",
                "Lage " .. id .. " unvollstaendig")
        end
        DP.Select("the_deadmines", nil)
        WeintCodex.Navigation.SwitchTo("dungeons")
        -- 6.14.0.0: dazu der Eingang (Westfalen) - fuenf Geber, ein Eingang.
        assert(DP.mapLinks == 6 and DP.entranceLinks == 1,
            "Kartenlinks in The Deadmines: " .. tostring(DP.mapLinks) .. " statt 6, Eingaenge " .. tostring(DP.entranceLinks))
        -- 6.5.1.1: jede Quest in ihrer Kachel (sieben in The Deadmines).
        assert(DP.questTiles == #J.Quests("the_deadmines", nil) or DP.questTiles == #J.Quests("the_deadmines", "alliance"),
            "Questkacheln: " .. tostring(DP.questTiles))
        assert(DP.questTiles > 0, "keine Questkachel")
        DP.Select("hall_of_thanes", nil)
        WeintCodex.Navigation.SwitchTo("dungeons")
        assert(DP.mapLinks - DP.entranceLinks >= 1 and DP.entranceLinks == 1, "Fundort der Dark Iron Map ohne Link")

        -- Weltkarte als Attrappe.
        local oldWM, oldOpen = _G.WorldMapFrame, _G.OpenWorldMap
        local wm = CreateFrame("Frame", "WorldMapFrame", UIParent)
        _G.WorldMapFrame = wm
        wm:Hide()
        local mapID = 1453
        wm.GetMapID = function() return mapID end
        -- 6.6.0.1: WeintCodex schreibt die Zone der Weltkarte nie selbst -
        -- sonst blockiert das Spiel ihre Questmarken im Kampf.
        local wrote = 0
        wm.SetMapID = function(_, id) wrote = wrote + 1 mapID = id end
        local canvas = CreateFrame("Frame", nil, wm)
        canvas._width, canvas._height = 1000, 600
        wm.GetCanvas = function() return canvas end
        local luaOpen = 0
        _G.OpenWorldMap = function() luaOpen = luaOpen + 1 end
        local oldCMap = _G.C_Map
        _G.C_Map = setmetatable({ OpenWorldMap = function(id) wm:Show() mapID = id end }, { __index = oldCMap })
        -- Im Kampf: keine Karte, aber die Marke steht bereit.
        local oldICL = _G.InCombatLockdown
        _G.InCombatLockdown = function() return true end
        assert(QM.Show(J.Place(214), "Red Silk Bandanas") and not wm:IsShown(), "im Kampf die Weltkarte geoeffnet")
        _G.InCombatLockdown = oldICL
        local main = WeintCodex.MainFrame
        main:Show()
        assert(QM.Show(J.Place(214), "Red Silk Bandanas"), "Marke nicht gesetzt")
        assert(wrote == 0 and luaOpen == 0, "Zone der Weltkarte selbst gesetzt (SetMapID " .. wrote .. ", OpenWorldMap " .. luaOpen .. ")")
        -- 6.5.1.2: Codex geht zu, auf der Karte steht der Weg zurueck.
        assert(not main:IsShown(), "Codex liegt weiter ueber der Karte")
        local back = QM.BackButton()
        assert(back and back:IsShown() and QM.FromCodex(), "kein Knopf zurueck zum Codex")
        -- 6.6.0.1: Leiste mit Namen, Nadel mit Spitze auf dem Ort.
        assert(back.title:GetText() == "Scout Riell", "Leiste nennt den Markierten nicht")
        assert(back.button and back.button._scripts.OnClick, "Leiste ohne Knopf")
        assert(wm:IsShown() and mapID == 1436, "Weltkarte nicht auf Westfalen geoeffnet")
        local pin = QM.Pin()
        assert(pin and pin:IsShown(), "keine Marke auf der Karte")
        local pt
        pin.SetPoint = function(_, p, rel, rp, x, y) pt = { p, rel, rp, x, y } end
        QM.Place()
        assert(pt and pt[1] == "BOTTOM" and pt[2] == canvas and math.abs(pt[4] - 566.7) < 0.01 and math.abs(pt[5] + 284.1) < 0.01,
            "Marke an falscher Stelle: " .. tostring(pt and pt[4]) .. ", " .. tostring(pt and pt[5]))
        mapID = 1453
        QM.Place()
        assert(not pin:IsShown(), "Marke auf der falschen Zone")
        mapID = 1436
        QM.Place()
        assert(pin:IsShown(), "Marke kommt beim Zurueckwechseln nicht wieder")
        -- Zurueck: der Codex kommt ueber die Karte; die Karte schliesst
        -- WeintCodex nicht selbst (HideUIPanel aus dem Addon, s. o.).
        local hid = 0
        local oldHide = _G.HideUIPanel
        _G.HideUIPanel = function() hid = hid + 1 end
        back.button._scripts.OnClick(back.button)
        assert(main:IsShown() and hid == 0, "Zurueck: Codex nicht offen oder Karte selbst geschlossen")
        assert(not back:IsShown() and not QM.FromCodex(), "Knopf bleibt nach dem Zurueck")
        _G.HideUIPanel = oldHide
        -- Karte ohne offenen Codex: kein Rueckweg angeboten.
        main:Hide()
        wm:Hide()
        QM.Show(J.Place(214), "Red Silk Bandanas")
        assert(not back:IsShown(), "Zurueck-Knopf ohne Codex")
        wm:Show()
        QM.Place()
        pin._scripts.OnClick(pin, "RightButton")
        assert(not pin:IsShown() and QM.Target() == nil, "Rechtsklick entfernt die Marke nicht")
        _G.WorldMapFrame, _G.OpenWorldMap, _G.C_Map = oldWM, oldOpen, oldCMap
        assert(wrote == 0, "Zone der Weltkarte selbst gesetzt")
    end)
    Check(ok, "Dungeonseite: Questgeber auf der Weltkarte" .. (ok and "" or (": " .. tostring(err))))
end

-- 6.6.0.0: Lehrer - was gelernt ist, fragt die Seite den Client; der
-- Bestand sagt nur, was es gibt.
do
    local ok, err = pcall(function()
        local TR, T = WeintCodex.Trainer, WeintCodex.TrainerData
        local known = { [6673] = true, [78] = true, [772] = true }
        local oldIPS, oldLvl, oldRace, oldFac, oldMoney =
            _G.IsPlayerSpell, _G.UnitLevel, _G.UnitRace, _G.UnitFactionGroup, _G.GetMoney
        _G.IsPlayerSpell = function(id) return known[id] == true end
        _G.UnitLevel = function() return 10 end
        _G.UnitRace = function() return "Mensch", "Human", 1 end
        _G.UnitFactionGroup = function() return "Alliance" end
        _G.GetMoney = function() return 150 end
        local function In(cat, key, id)
            for _, sp in ipairs(cat.sections[key]) do if sp.id == id then return true end end
            return false
        end
        local cat = TR.Categorize()
        assert(In(cat, "known", 6673), "gelernter Schlachtruf nicht als gelernt")
        assert(In(cat, "now", 100), "Sturmangriff (Stufe 4) nicht jetzt lernbar")
        assert(In(cat, "now", 284), "Heldenhafter Stoss Rang 2 trotz Rang 1 nicht lernbar")
        assert(In(cat, "soon", 5242), "Stufe 12 nicht unter den naechsten Stufen")
        assert(In(cat, "later", 285), "Stufe 16 nicht unter Spaeter")
        assert(In(cat, "talent", 23893), "Blutdurst Rang ohne Talent nicht erkannt")
        -- Ohne Rang 1 fehlt die Vorstufe.
        known[78] = nil
        cat = TR.Categorize()
        assert(In(cat, "missing", 284), "fehlende Vorstufe nicht erkannt")
        -- Hoeherer Rang ersetzt den niedrigeren: Schlachtruf Rang 2 bekannt
        -- -> Rang 1 gilt als gelernt, auch wenn der Client ihn nicht mehr meldet.
        known[6673], known[5242] = nil, true
        cat = TR.Categorize()
        assert(In(cat, "known", 6673), "ersetzter Rang nicht als gelernt")
        assert(cat.total.now > 0 and TR.Money(cat.total.now) ~= "—", "Kosten fehlen")
        assert(TR.Money(12345) == "1 G 23 S 45 K" and TR.Money(nil) == "—", "Geldformat: " .. TR.Money(12345))
        -- 6.6.2.1: die Rechnung. 150 Kupfer gegen die Kosten von "jetzt".
        local b = TR.Budget(nil, cat, {})
        assert(b.money == 150 and b.rest == 150 - b.now and b.upcoming == b.now + b.soon, "Rechnung falsch")
        local sum, n = 0, 0
        for _, sp in ipairs(cat.sections.now) do sum = sum + sp.cost if sum > 150 then break end n = n + 1 end
        assert(b.affordable == n, "reicht fuer " .. tostring(b.affordable) .. " statt " .. n)
        assert(TR.Verdict(-40) == "fehlen 40 K" and TR.Verdict(12345) == "bleiben 1 G 23 S 45 K"
            and TR.Verdict(nil) == "—", "Urteil falsch formuliert")
        -- Kein Gold vom Client: kein Urteil, keine 0.
        _G.GetMoney = function() return nil end
        local nb = TR.Budget(nil, cat, {})
        assert(nb.money == nil and nb.rest == nil and nb.affordable == nil, "ohne Gold trotzdem gerechnet")
        _G.GetMoney = function() return 150 end
        -- Waffen: gelernt / lernbar / ab Stufe 20, Meister der eigenen Fraktion.
        known[201] = true
        local ws = TR.WeaponState()
        local byId = {}
        for _, w in ipairs(ws) do byId[w.id] = w end
        assert(byId[201].key == "known" and byId[1180].key == "now" and byId[200].key == "later", "Waffenzustand falsch")
        assert(#byId[1180].masters == 3, "Dolchmeister der Allianz (Bixi, Woo Ping, Ilyenia): " .. #byId[1180].masters)
        -- Jaeger: Tierausbildung ohne Zustand, nie als "nicht gelernt".
        local oldClass = _G.UnitClass
        _G.UnitClass = function() return "Jäger", "HUNTER" end
        cat = TR.Categorize()
        assert(#cat.sections.pet == 45, "Tierausbildung: " .. #cat.sections.pet)
        for _, sp in ipairs(cat.sections.known) do assert(not sp.pet, "Tierfaehigkeit als gelernt") end
        _G.UnitClass = oldClass
        -- Die Seite: Zauber und Waffen gezeichnet, Karte je Waffenmeister.
        WeintCodex.Navigation.SwitchTo("lehrer")
        assert(TR.Page() and TR.Page():IsShown(), "Lehrerseite nicht offen")
        assert((TR.drawnRows or 0) > 5, "zu wenige Zeilen: " .. tostring(TR.drawnRows))
        assert((TR.mapButtons or 0) > 0, "kein Kartenknopf fuer Waffenmeister")
        assert(TR.lastBill and TR.lastBill[1][2][2] == TR.Money(150), "Rechnung zeigt das Gold nicht")
        assert(TR.lastBill[1][3][1] == ((b.rest < 0) and "Es fehlen" or "Danach"), "Rechnung: bleibt/fehlt falsch")
        -- 6.6.2.1: die Startseite fragt den Lehrer und die Dungeons
        -- (seit 6.11.0.0 modules/home.lua).
        local nav0, HM0 = WeintCodex.Navigation, WeintCodex.Home
        local home = HM0.Trainer()
        assert(home and #home.cat.sections.now > 0 and home.budget and home.budget.money == 150,
            "Startseite kennt den Lehrer nicht")
        local fit = HM0.Dungeons(15)
        local hot = false
        for _, d in ipairs(fit) do if d.id == "hall_of_thanes" then hot = true end end
        assert(hot, "Hall of Thanes (13-18) passt nicht zu Stufe 15")
        local none, nextUp = HM0.Dungeons(1)
        assert(#none == 0 and nextUp and nextUp.minLevel > 1, "ohne passenden Dungeon kein naechster")
        assert(#HM0.Dungeons(nil) == 0, "ohne Stufe trotzdem Dungeons empfohlen")
        nav0.SwitchTo("uebersicht")
        -- 6.6.0.1: erst der Detailbereich, dann gemessen - er macht die
        -- Flaeche schmaler, und die Karten muessen die schmale Breite nehmen.
        local nav = WeintCodex.Navigation
        local oldInsp = nav.SetInspector
        local pg = TR.Page()
        pg._width = 1400
        nav.SetInspector = function(...) pg._width = 900 return oldInsp(...) end
        TR.Show()
        nav.SetInspector = oldInsp
        local M = WeintCodex.Metrics
        local want = math.floor((900 - 2 * M.PAD_X - M.GAP) * 0.56)
        assert(pg.SpellCard:GetWidth() == want, "Karten vor dem Detailbereich gemessen: "
            .. tostring(pg.SpellCard:GetWidth()) .. " statt " .. want)
        _G.IsPlayerSpell, _G.UnitLevel, _G.UnitRace, _G.UnitFactionGroup, _G.GetMoney =
            oldIPS, oldLvl, oldRace, oldFac, oldMoney
    end)
    Check(ok, "Lehrer: Faecher, Raenge, Talente, Waffen, Tierausbildung, Seite" .. (ok and "" or (": " .. tostring(err))))
end

-- 6.3.2.8: Im Dungeon verfolgt die Questliste nur dessen Quests; beim
-- Verlassen kommt genau das zurueck, was geaendert wurde.
do
    local ok, err = pcall(function()
        local QT = WeintCodex.UIQuestTracker
        local oldQL, oldInst, oldInfo = _G.C_QuestLog, _G.IsInInstance, _G.GetInstanceInfo
        local log = {
            { isHeader = true, title = "Westfall" },
            { questID = 1, title = "Pastete" },
            { questID = 2, title = "Eintopf" },
            { isHeader = true, title = "Die Todesminen" },
            { questID = 3, title = "Rote Seide" },
            { questID = 4, title = "Der Defias-Bruder" },
            { isHeader = true, title = "Dämmerwald" },
            { questID = 5, title = "Nachtwache", isOnMap = true },
        }
        local watched = { 1, 2, 3 }
        local function has(id) for _, w in ipairs(watched) do if w == id then return true end end return false end
        _G.C_QuestLog = {
            GetNumQuestLogEntries = function() return #log end,
            GetInfo = function(i) return log[i] end,
            GetNumQuestWatches = function() return #watched end,
            GetQuestIDForQuestWatchIndex = function(i) return watched[i] end,
            AddQuestWatch = function(id) if not has(id) then watched[#watched + 1] = id end end,
            RemoveQuestWatch = function(id)
                for i, w in ipairs(watched) do if w == id then table.remove(watched, i) return end end
            end,
        }
        _G.GetInstanceInfo = function() return "Die Todesminen", "party" end
        _G.IsInInstance = function() return true, "party" end
        QT.CheckDungeon()
        table.sort(watched)
        assert(table.concat(watched, ",") == "3,4,5", "im Dungeon falsch verfolgt: " .. table.concat(watched, ","))
        _G.IsInInstance = function() return false, "none" end
        QT.CheckDungeon()
        table.sort(watched)
        assert(table.concat(watched, ",") == "1,2,3", "nach dem Dungeon nicht zurueck: " .. table.concat(watched, ","))
        _G.C_QuestLog, _G.IsInInstance, _G.GetInstanceInfo = oldQL, oldInst, oldInfo
    end)
    Check(ok, "Questliste: im Dungeon nur dessen Quests, danach alles zurueck" .. (ok and "" or (": " .. tostring(err))))
end

-- 6.3.2.8: Questpfeil in Instanzen aus.
do
    local ok, err = pcall(function()
        local QA = WeintCodex.UIQuestArrow
        local old = _G.IsInInstance
        _G.IsInInstance = function() return true, "party" end
        assert(QA.InInstance(), "Dungeon nicht erkannt")
        _G.IsInInstance = function() return false, "none" end
        assert(not QA.InInstance(), "offene Welt als Instanz erkannt")
        _G.IsInInstance = old
        assert(K.Get("questarrow", "hideInInstance") == true, "Pfeil in Dungeons nicht standardmaessig aus")
    end)
    Check(ok, "Questpfeil: in Dungeons aus" .. (ok and "" or (": " .. tostring(err))))
end

-- 6.3.2.7: Markierungen - auch mit geheimem Index, als Bild aus einem
-- formatierten Text (der Client setzt die Zahl ein, Lua sieht sie nie).
do
    local NP = WeintCodex.UINameplates
    local ok, err = pcall(function()
        local oldIdx, oldSecret = _G.GetRaidTargetIndex, _G.issecretvalue
        _G.GetRaidTargetIndex = function() return 8 end
        stub.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate1")
        local p = NP.plates["nameplate1"]
        stub.FireEvent("RAID_TARGET_UPDATE")
        assert(p.raid:IsShown() and tostring(p.raid:GetText()):find("RaidTargetingIcon_8", 1, true),
            "Totenkopf nicht an der Plakette: " .. tostring(p.raid:GetText()))
        local secret = setmetatable({}, {})
        _G.issecretvalue = function(v) return v == secret end
        _G.GetRaidTargetIndex = function() return secret end
        -- Die Attrappe formatiert keine geheimen Werte; im Client tut es
        -- SetFormattedText. Hier zaehlt: gezeigt, und kein Rechnen damit.
        local fmt = p.raid.SetFormattedText
        local got
        p.raid.SetFormattedText = function(self, f, v) got = v self:SetText("x") end
        stub.FireEvent("RAID_TARGET_UPDATE")
        assert(p.raid:IsShown() and got == secret, "geheime Markierung nicht gezeigt")
        assert(NP.raidInfo:find("geheim", 1, true), "Auskunft fehlt")
        p.raid.SetFormattedText = fmt
        _G.GetRaidTargetIndex = function() return nil end
        stub.FireEvent("RAID_TARGET_UPDATE")
        assert(not p.raid:IsShown(), "Markierung bleibt ohne Markierung stehen")
        _G.GetRaidTargetIndex, _G.issecretvalue = oldIdx, oldSecret
        stub.FireEvent("NAME_PLATE_UNIT_REMOVED", "nameplate1")
    end)
    Check(ok, "Plaketten: Markierung offen und geheim" .. (ok and "" or (": " .. tostring(err))))
end

-- 6.3.2.6: Bedrohung in Prozent an der Plakette.
do
    local NP = WeintCodex.UINameplates
    local ok, err = pcall(function()
        local old = _G.UnitDetailedThreatSituation
        local scaled, status = 84, 1
        _G.UnitDetailedThreatSituation = function() return false, status, scaled, 90, 1000 end
        stub.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate1")
        local p = NP.plates["nameplate1"]
        stub.FireEvent("UNIT_THREAT_LIST_UPDATE", "nameplate1")
        assert(p.threat:IsShown() and p.threat:GetText() == "84%", "Bedrohung fehlt: " .. tostring(p.threat:GetText()))
        scaled = nil
        stub.FireEvent("UNIT_THREAT_LIST_UPDATE", "nameplate1")
        assert(not p.threat:IsShown(), "Bedrohung ohne Liste gezeigt")
        scaled = 0
        stub.FireEvent("UNIT_THREAT_LIST_UPDATE", "nameplate1")
        assert(not p.threat:IsShown(), "0 % als Bedrohung gezeigt")
        K.Set("nameplates", "threatText", "none")
        scaled = 100
        NP.UpdateThreatText(p)
        assert(not p.threat:IsShown(), "abgeschaltet und trotzdem da")
        K.Set("nameplates", "threatText", nil)
        stub.FireEvent("NAME_PLATE_UNIT_REMOVED", "nameplate1")
        _G.UnitDetailedThreatSituation = old
    end)
    Check(ok, "Plaketten: Bedrohung in Prozent" .. (ok and "" or (": " .. tostring(err))))
end

-- 6.3.2.5: Zauberbalken nennt das Ziel des Zaubers ("» Dich" rot).
do
    local ok, err = pcall(function()
        local CB = WeintCodex.UICastBar
        local saved = { _G.UnitCastingInfo, _G.UnitExists, _G.UnitIsUnit, _G.UnitName, _G.UnitIsPlayer, _G.UnitClass }
        _G.UnitCastingInfo = function() return "Frostblitz", nil, 135846, 1000, 3000, false, nil, false end
        _G.UnitExists = function() return true end
        local me = true
        _G.UnitIsUnit = function(a, b) return me and a == "nameplate9target" and b == "player" end
        _G.UnitName = function(u) if u == "nameplate9target" then return "Liora" end return "Gegner" end
        _G.UnitIsPlayer = function() return true end
        _G.UnitClass = function() return "Priester", "PRIEST" end
        local bar = CB.Create(UIParent)
        bar:ApplyStyle({ height = 14, timer = true, target = true })
        bar:SetUnit("nameplate9")
        bar:Update()
        assert(bar._target:IsShown() and bar._target:GetText() == "» Dich", "Ziel 'Dich' fehlt: " .. tostring(bar._target:GetText()))
        me = false
        bar:UpdateTarget()
        assert(bar._target:GetText() == "» Liora", "Zielname fehlt: " .. tostring(bar._target:GetText()))
        bar:Stop(true)
        assert(not bar._target:IsShown(), "Ziel bleibt bei 'Unterbrochen' stehen")
        bar:ApplyStyle({ height = 14, timer = true, target = false })
        bar:Update()
        assert(not bar._target:IsShown(), "Ziel trotz abgeschalteter Einstellung")
        _G.UnitCastingInfo, _G.UnitExists, _G.UnitIsUnit, _G.UnitName, _G.UnitIsPlayer, _G.UnitClass = unpack(saved, 1, 6)
    end)
    Check(ok, "Zauberbalken: Ziel des Zaubers" .. (ok and "" or (": " .. tostring(err))))
end

-- 6.3.2.3: UNIT_FACTION fuer Gruppenkennungen ("partypet4") fragt nicht
-- nach einer Plakette - der Client wirft dort einen Fehler.
do
    local NP = WeintCodex.UINameplates
    local ok, err = pcall(function()
        local oldGet = _G.C_NamePlate.GetNamePlateForUnit
        _G.C_NamePlate.GetNamePlateForUnit = function(unit)
            if not tostring(unit):find("^nameplate") then
                error("Raid<n>/Party<n> unit tokens are not allowed for this call.")
            end
            return oldGet(unit)
        end
        stub.FireEvent("UNIT_FACTION", "partypet4")
        stub.FireEvent("UNIT_FACTION", "raid12")
        stub.FireEvent("UNIT_FACTION", "nameplate1")
        assert(NP.IsPlateToken("nameplate12") and not NP.IsPlateToken("party1") and not NP.IsPlateToken(nil),
            "Plakettenkennung falsch erkannt")
        stub.FireEvent("NAME_PLATE_UNIT_REMOVED", "nameplate1")
        _G.C_NamePlate.GetNamePlateForUnit = oldGet
    end)
    Check(ok, "Plaketten: UNIT_FACTION fuer Gruppenkennungen ohne Fehler" .. (ok and "" or (": " .. tostring(err))))
end

-- 6.3.2.1: Spielerrahmen mit Stufe und Symbol fuer Kampf/Ruhe.
do
    local ok, err = pcall(function()
        local UF = WeintCodex.UIUnitFrames
        assert(K.Get("unitframes", "player_left") == "levelname", "Spielerrahmen ohne Stufe")
        local st = UF.StateIcon()
        assert(st, "kein Symbol am Spielerrahmen")
        local oldCombat, oldRest = _G.UnitAffectingCombat, _G.IsResting
        local combat, rest = true, true
        _G.UnitAffectingCombat = function() return combat end
        _G.IsResting = function() return rest end
        UF.UpdateState()
        assert(st:IsShown() and st._which == "combat", "Kampf geht nicht vor Ruhe")
        combat = false
        UF.UpdateState()
        assert(st:IsShown() and st._which == "rest", "Ruhe ohne Symbol")
        rest = false
        UF.UpdateState()
        assert(not st:IsShown(), "Symbol bleibt ohne Kampf und Ruhe")
        _G.UnitAffectingCombat, _G.IsResting = oldCombat, oldRest
    end)
    Check(ok, "Spielerrahmen: Stufe, Symbol fuer Kampf und Ruhe" .. (ok and "" or (": " .. tostring(err))))
end

-- 6.20.0.0: Portraet im Balken (Spieler, Ziel): der Kopf als Modell ueber
-- der Fuellung, halb durchsichtig, unter Text; die Balken ueber die ganze
-- Breite; ausser Sichtweite oder ohne Modelldatei kein Kopf.
do
    local G = _G
    local names = { "UnitExists", "UnitIsVisible", "C_Timer" }
    local saved = {}
    for i, n in ipairs(names) do saved[i] = G[n] end
    local UF = WeintCodex.UIUnitFrames
    local ok, err = pcall(function()
        local function Has(list, v) for _, it in ipairs(list) do if it.value == v then return true end end end
        assert(Has(UF.PortraitItems("player"), "bar") and Has(UF.PortraitItems("target"), "bar"), "Spieler/Ziel ohne 'Im Balken'")
        assert(not Has(UF.PortraitItems("focus"), "bar") and Has(UF.PortraitItems("focus"), "3d"), "Fokus mit 'Im Balken'")
        local visible = true
        G.UnitExists = function() return true end
        G.UnitIsVisible = function() return visible end
        local queue = {}
        G.C_Timer = { After = function(_, fn) queue[#queue + 1] = fn end, NewTicker = function() return {} end }
        local f = UF.frames.player
        local bm = f._barModel
        assert(bm and UF.frames.target._barModel and not (UF.frames.focus and UF.frames.focus._barModel), "Modell im Balken fehlt oder zu viel")
        local unitSet, healthPts, cam = nil, {}, nil
        bm.SetUnit = function(_, u) unitSet = u end
        bm.SetCamDistanceScale = function(_, v) cam = v end
        bm.GetModelFileID = function() return 123 end
        f.health.SetPoint = function(_, a, rel, b, x) healthPts[a] = x end
        f._portrait.tex:Hide()
        K.Set("unitframes", "player_portrait", "bar")
        f:Layout()
        assert(bm:IsShown() and unitSet == "player" and not f._portrait:IsShown(), "Kopf nicht im Balken")
        assert(not f._portrait.tex:IsShown(), "Bild des Portraets nebenbei gesetzt")
        assert(healthPts.TOPLEFT == 0 and healthPts.TOPRIGHT == 0, "Balken mit Platz fuer ein Portraet")
        assert(math.abs(bm:GetAlpha() - 0.35) < 0.001, "Deckkraft: " .. tostring(bm:GetAlpha()))
        assert(bm:GetFrameLevel() == f.health:GetFrameLevel() + 1 and bm:GetFrameLevel() < f.left:GetParent():GetFrameLevel(),
            "Kopf nicht zwischen Fuellung und Text")
        -- 6.21.0.0: weiter weg als das Portraet ("ein bisschen weiter
        -- rausgezoomt"), einstellbar.
        assert(cam == 1.5, "Kamera im Balken: " .. tostring(cam))
        K.Set("unitframes", "player_barAlpha", 60)
        K.Set("unitframes", "player_barCam", 220)
        f:UpdatePortrait()
        assert(math.abs(bm:GetAlpha() - 0.6) < 0.001, "Deckkraft nicht eingestellt")
        assert(math.abs(cam - 2.2) < 0.001, "Abstand nicht eingestellt: " .. tostring(cam))
        K.Set("unitframes", "player_barCam", 999)
        f:UpdatePortrait()
        assert(cam == 3, "Abstand nicht begrenzt: " .. tostring(cam))
        K.Set("unitframes", "player_barCam", 150)
        assert(not f._portrait.tex:IsShown(), "Bild des Portraets bei jedem Neuzeichnen gesetzt")
        -- Modell geladen: bleibt. Ohne Modelldatei: weg.
        for _, fn in ipairs(queue) do fn() end
        assert(bm:IsShown(), "Kopf trotz Modelldatei weg")
        queue = {}
        bm.GetModelFileID = function() return 0 end
        f:UpdatePortrait()
        for _, fn in ipairs(queue) do fn() end
        assert(not bm:IsShown(), "Kopf ohne Modelldatei (schwarzer Balken)")
        bm.GetModelFileID = function() return 123 end
        -- Ausser Sichtweite: kein Kopf, auch kein Bild im Balken.
        visible = false
        f:UpdatePortrait()
        assert(not bm:IsShown() and not f._portrait:IsShown(), "Kopf ausser Sichtweite")
        visible = true
        -- Zurueck zum 3D-Portraet: Kopf weg, Portraet links mit Platz.
        K.Set("unitframes", "player_portrait", "3d")
        f:Layout()
        assert(not bm:IsShown() and f._portrait:IsShown() and healthPts.TOPLEFT > 0, "3D-Portraet nicht zurueck")
        -- Ziel im Testmodus: Beispiel statt Kopf.
        local t = UF.frames.target
        K.Set("unitframes", "target_portrait", "bar")
        t:Layout()
        t:ShowTest(true)
        assert(not t._barModel:IsShown(), "Kopf im Testmodus")
        t:UpdatePortrait()
        assert(not t._barModel:IsShown(), "Kopf kommt im Testmodus zurueck")
        t:ShowTest(false)
    end)
    for i, n in ipairs(names) do G[n] = saved[i] end
    K.Set("unitframes", "player_portrait", "3d")
    K.Set("unitframes", "target_portrait", "3d")
    K.Set("unitframes", "player_barAlpha", 35)
    Check(ok, "Portraet im Balken: Spieler/Ziel, ganze Breite, Deckkraft, ohne Modell/ausser Sicht keins, Testmodus"
        .. (ok and "" or (": " .. tostring(err))))
end

-- 6.3.2.0: Haltungsleiste so breit wie die Haltungen der Klasse.
do
    local AB = WeintCodex.UIActionBars
    local ok, err = pcall(function()
        local bar = CreateFrame("Frame", "StanceBar", UIParent)
        local w
        bar.SetSize = function(_, x) w = x end
        for k = 1, 10 do CreateFrame("CheckButton", "StanceButton" .. k, bar) end
        local oldForms = _G.GetNumShapeshiftForms
        _G.GetNumShapeshiftForms = function() return 2 end
        K.Set("actionbars", "layout", "wc")
        AB.LayoutAll()
        local size, gap = K.Get("actionbars", "b9_size"), K.Get("actionbars", "b9_spacing")
        assert(w == 2 * (size + gap) - gap, "Haltungsleiste nicht so breit wie zwei Haltungen: " .. tostring(w))
        assert(_G.StanceButton3:GetAlpha() == 0, "dritter Platz ohne Haltung sichtbar")
        _G.GetNumShapeshiftForms = oldForms
        K.Set("actionbars", "layout", nil)
        _G.StanceBar = nil
        for k = 1, 10 do _G["StanceButton" .. k] = nil end
    end)
    Check(ok, "Haltungsleiste so breit wie die Haltungen" .. (ok and "" or (": " .. tostring(err))))
end

-- 6.3.1.9: Name im Balken (Voreinstellung), Debuffs links/mittig/rechts.
do
    local NP = WeintCodex.UINameplates
    local ok, err = pcall(function()
        NP.SetNamePlace("above")
        assert(NP.NamePlace() == "above", "Voreinstellung 'ueber der Plakette' nicht erkannt")
        NP.SetNamePlace("left")
        assert(K.Get("nameplates", "textTop") == "none" and K.Get("nameplates", "textLeft") == "levelName",
            "Name nicht in den Balken gesetzt")
        assert(NP.NamePlace() == "left", "Voreinstellung nicht wiedererkannt")
        stub.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate1")
        local p = NP.plates["nameplate1"]
        assert(p and p.texts.left:IsShown(), "Stufe und Name nicht im Balken")
        assert(p.texts.left:GetWidth() > p.texts.right:GetWidth(), "Name hat nicht den meisten Platz")
        K.Set("nameplates", "textRight", "healthNumber")
        assert(NP.NamePlace() == "custom", "eigene Belegung nicht erkannt")
        NP.SetNamePlace("above")
        stub.FireEvent("NAME_PLATE_UNIT_REMOVED", "nameplate1")
        -- 6.3.2.0: Symbole des Spiels mittig UEBER unserer Plakette (an den
        -- Aurenrahmen gesetzt standen sie im Beta-Test darunter).
        local uf = blizzPlate.UnitFrame
        local oldAuras = uf.AurasFrame
        uf.AurasFrame = stub.NewObject("Frame")
        local list = stub.NewObject("Frame")
        uf.AurasFrame.DebuffListFrame = list
        local pt
        list.SetPoint = function(_, a, rel, b, x, y) pt = { a, rel, b, x, y } end
        K.Set("nameplates", "auraAlign", "center")
        stub.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate1")
        local plate = NP.plates["nameplate1"]
        assert(pt and pt[1] == "BOTTOM" and pt[2] == plate and pt[3] == "TOP" and pt[5] > 0,
            "Symbole des Spiels nicht mittig ueber der Plakette")
        K.Set("nameplates", "auraAlign", nil)
        stub.FireEvent("NAME_PLATE_UNIT_REMOVED", "nameplate1")
        uf.AurasFrame = oldAuras
    end)
    Check(ok, "Plaketten: Name im Balken, Debuffs ausrichten" .. (ok and "" or (": " .. tostring(err))))
end

-- Freundliche Plaketten, und die Sperre in Instanzen.
do
    local NP = WeintCodex.UINameplates
    local ok, err = pcall(function()
        _G.UnitCanAttack = function() return false end
        _G.UnitIsPlayer = function() return true end
        stub.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate1")
        local p = NP.plates["nameplate1"]
        assert(p and p._friendly, "keine freundliche Plakette")
        stub.FireEvent("NAME_PLATE_UNIT_REMOVED", "nameplate1")
        blizzPlate.IsForbidden = function() return true end
        stub.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate1")
        assert(NP.plates["nameplate1"] == nil, "gesperrte Plakette wurde trotzdem uebernommen")
        blizzPlate.IsForbidden = nil
        _G.UnitCanAttack = function() return true end
        _G.UnitIsPlayer = function() return false end
    end)
    Check(ok, "freundliche Plakette; gesperrte (Instanz) bleibt die des Spiels"
        .. (ok and "" or (": " .. tostring(err))))
end

-- Gruppenrahmen: ein Knopf, wie ihn der Kopfrahmen einrichtet.
do
    local GF = WeintCodex.UIGroupFrames
    local ok, err = pcall(function()
        _G.UnitInRange = function() return false, true end
        _G.UnitThreatSituation = function() return 3 end
        local b = CreateFrame("Button", nil, UIParent)
        GF._Style(b)
        b._scripts.OnAttributeChanged(b, "unit", "party1")
        assert(b._wcUnit == "party1", "Einheit nicht uebernommen")
        b:Layout(120, 44)
        stub.FireEvent("UNIT_HEALTH", "party1")
        stub.FireEvent("UNIT_THREAT_SITUATION_UPDATE", "party1")
        b:UpdateRange()
        K.Set("groupframes", "statusText", "deficit")
        b:Refresh()
        _G.UnitInRange, _G.UnitThreatSituation = nil, nil
    end)
    Check(ok, "Gruppenrahmen: Einheit, Leben, Aggro, Reichweite" .. (ok and "" or (": " .. tostring(err))))
end

-- 6.3.2.4: Gruppenrahmen mit eingehender Heilung, Schild, Rolle, Krone,
-- Bereitschaftscheck, Wiederbelebung und Aufblitzen bei Treffern.
do
    local GF = WeintCodex.UIGroupFrames
    local ok, err = pcall(function()
        local saved = { _G.UnitGetIncomingHeals, _G.UnitGetTotalAbsorbs, _G.UnitGroupRolesAssigned,
                        _G.UnitIsGroupLeader, _G.GetReadyCheckStatus, _G.UnitHasIncomingResurrection }
        _G.UnitGetIncomingHeals = function() return 200 end
        _G.UnitGetTotalAbsorbs = function() return nil end
        _G.UnitGroupRolesAssigned = function() return "HEALER" end
        _G.UnitIsGroupLeader = function() return true end
        local ready = "waiting"
        _G.GetReadyCheckStatus = function() return ready end
        local b = CreateFrame("Button", nil, UIParent)
        GF._Style(b)
        b._scripts.OnAttributeChanged(b, "unit", "party2")
        b:Layout(120, 44)
        b:Show()
        local c = b._wc
        b:Refresh()
        assert(c.heal:IsShown() and c.heal:GetValue() == 200, "eingehende Heilung fehlt")
        assert(not c.absorb:IsShown(), "Schild ohne Wert gezeigt")
        assert(c.role:IsShown() and c.leader:IsShown(), "Rolle oder Krone fehlt")
        assert(c.readyText:IsShown() and not c.ready:IsShown(), "Bereitschaft 'wartet' ohne ?")
        ready = "ready"
        b:UpdateReady()
        assert(c.ready:IsShown() and not c.readyText:IsShown(), "Bereit ohne Haken")
        _G.UnitGroupRolesAssigned = function() return "NONE" end
        b:UpdateRole()
        assert(not c.role:IsShown(), "Rolle geraten, obwohl keine zugewiesen ist")
        _G.UnitHasIncomingResurrection = function() return true end
        b:Refresh()
        assert(c.status:GetText() == "Wird belebt", "Wiederbelebung nicht genannt: " .. tostring(c.status:GetText()))
        b:Flash()
        assert(c._flashLeft, "Treffer blitzt nicht")
        _G.UnitGetIncomingHeals, _G.UnitGetTotalAbsorbs, _G.UnitGroupRolesAssigned,
            _G.UnitIsGroupLeader, _G.GetReadyCheckStatus, _G.UnitHasIncomingResurrection = unpack(saved, 1, 6)
    end)
    Check(ok, "Gruppenrahmen: Heilung, Schild, Rolle, Krone, Bereitschaft, Wiederbelebung, Treffer"
        .. (ok and "" or (": " .. tostring(err))))
end

-- Aktionsleisten, Minikarte, Chat.
do
    local ok, err = pcall(function()
        local b = CreateFrame("CheckButton", "ActionButton1", UIParent)
        b.icon = b:CreateTexture()
        b.HotKey = b:CreateFontString()
        b.Count = b:CreateFontString()
        b.Name = b:CreateFontString()
        -- 6.6.1.4: das rote Blinken bei automatischem Angriff wird flach.
        b.Flash = b:CreateTexture()
        local flashColor
        b.Flash.SetColorTexture = function(_, r, g, bl, a) flashColor = { r, g, bl, a } end
        b.Flash.SetAtlas = function() end
        local oldHook = _G.hooksecurefunc
        _G.hooksecurefunc = function(obj, name, fn)
            if type(obj) ~= "table" then return oldHook(obj, name, fn) end
            local orig = obj[name]
            obj[name] = function(...) local r = orig(...) fn(...) return r end
        end
        WeintCodex.UIActionBars.SkinAll()
        _G.hooksecurefunc = oldHook
        assert(WeintCodex.UIActionBars.skinned[b], "Knopf nicht umgestaltet")
        local acc = K.Highlight()
        assert(flashColor and flashColor[1] == acc[1] and flashColor[4] < 0.5, "Blinken bleibt der rote Rahmen des Spiels")
        flashColor = nil
        b.Flash:SetAtlas("UI-HUD-ActionBar-IconFrame-Flash")
        assert(flashColor, "neu gesetztes Blinken nicht wieder flach")
        K.Set("actionbars", "hotkeys", false)
        -- Mikromenue und Taschenleiste: fehlt eines, bleibt das andere.
        CreateFrame("Frame", "BagsBar", UIParent)
        WeintCodex.UIActionBars.Place()
        CreateFrame("Frame", "MicroMenuContainer", UIParent)
        WeintCodex.UIActionBars.Place()
        _G.BagsBar, _G.MicroMenuContainer = nil, nil
    end)
    Check(ok, "Aktionsleisten: Knopf des Spiels umgestaltet" .. (ok and "" or (": " .. tostring(err))))

    ok, err = pcall(function()
        K.Set("minimap", "square", false)
        assert(_G.GetMinimapShape() == "ROUND", "runde Karte meldet nicht ROUND")
        K.Set("minimap", "square", true)
        assert(_G.GetMinimapShape() == "SQUARE", "eckige Karte meldet nicht SQUARE")
        -- Knopfspalte: was es gibt, kommt hinein; was fehlt, faellt heraus.
        -- Der eigene Knopf (LibDBIcon) steht seit 6.3.1.1 im Sammelknopf,
        -- die Tageszeit unten rechts an der Karte - beide nicht in der Spalte.
        local base = #WeintCodex.UIMinimap.ColumnButtons()
        assert(base == 0, "Spalte ohne Knoepfe des Spiels hat " .. base .. " Eintraege")
        _G.MinimapCluster.Tracking = CreateFrame("Frame", nil, _G.MinimapCluster)
        _G.GameTimeFrame = CreateFrame("Button", "GameTimeFrame", _G.MinimapCluster)
        local list = WeintCodex.UIMinimap.ColumnButtons()
        assert(#list == base + 1, "Knopfspalte: " .. #list .. " statt " .. (base + 1) .. " Knoepfe")
        WeintCodex.UIMinimap.LayoutButtons()
        _G.MinimapCluster.Tracking, _G.GameTimeFrame = nil, nil
    end)
    Check(ok, "Minikarte: eckig/rund, GetMinimapShape, Knopfspalte" .. (ok and "" or (": " .. tostring(err))))

    ok, err = pcall(function()
        CreateFrame("ScrollingMessageFrame", "ChatFrame1", UIParent)
        CreateFrame("Button", "ChatFrame1Tab", UIParent)
        CreateFrame("EditBox", "ChatFrame1EditBox", UIParent)
        local qj = CreateFrame("Button", "QuickJoinToastButton", UIParent)
        _G.FCF_GetCurrentChatFrame = function() return _G.ChatFrame1 end
        WeintCodex.UIChat.ApplyAll()
        assert(qj:GetParent() == _G.WeintCodexChatTabRow, "Freunde-Knopf steht nicht in der Reiterzeile")
        assert(_G.CHAT_FRAME_TAB_NORMAL_NOMOUSE_ALPHA == 0.75, "Reiter werden weiter ausgeblendet")
        K.Set("chat", "buttons", "column")
        assert(qj:GetParent() == _G.WeintCodexChatButtons, "Freunde-Knopf steht nicht in der Spalte")
        K.Set("chat", "buttons", "tabrow")
        K.Set("chat", "editBoxTop", true)
        _G.FCF_GetCurrentChatFrame = nil
    end)
    Check(ok, "Chat: Fenster, Reiter, Eingabezeile, Knopfspalte" .. (ok and "" or (": " .. tostring(err))))
end

-- Taschen: alle Plaetze aller Taschen, als Knoepfe des Spiels.
do
    local BG = WeintCodex.UIBags
    local ok, err = pcall(function()
        _G.C_Container = {
            GetContainerNumSlots = function() return 4 end,
            GetContainerItemInfo = function(bag, slot)
                if slot == 1 then
                    return { iconFileID = 134400, stackCount = 3, quality = bag == 0 and 0 or 3,
                             hyperlink = "|Hitem:1|h", itemID = 1 }
                end
            end,
        }
        BG.Open()
        BG.Refresh()
        -- Rucksack + vier Taschen, je vier Plaetze (Reagenzientasche gibt es
        -- in der Attrappe nicht).
        assert(BG.UsedSlots() == 20, "falsche Zahl Plaetze: " .. tostring(BG.UsedSlots()))
        -- Belegt ist, was der Client meldet: je Tasche Platz 1.
        assert(BG._filled == 5, "falsche Zahl belegter Plaetze: " .. tostring(BG._filled))
        BG.Close()
        _G.C_Container = nil
    end)
    Check(ok, "Taschen: 20 Plaetze aus fuenf Taschen, 5 belegt" .. (ok and "" or (": " .. tostring(err))))
end

-- Questliste: eigene Flaeche hinter der Zielverfolgung, so hoch wie ihr
-- Inhalt; ohne Inhalt keine leere Flaeche.
do
    local QT = WeintCodex.UIQuestTracker
    local ok, err = pcall(function()
        local t = CreateFrame("Frame", "ObjectiveTrackerFrame", UIParent)
        t.Header = CreateFrame("Frame", nil, t)
        t.Header.Background = t.Header:CreateTexture()
        t.GetTop = function() return 800 end
        local mod = CreateFrame("Frame", nil, t)
        mod.GetBottom = function() return 600 end
        t.GetChildren = function() return t.Header, mod end
        K.Module("questtracker").Enable()
        local p = QT.Panel()
        assert(p and p:IsShown(), "Flaeche fehlt")
        assert(p:GetHeight() == 200 + 16, "Hoehe folgt dem Inhalt: " .. tostring(p:GetHeight()))
        -- 6.3.1.4: Deckkraft 0 % = gar keine Flaeche (auch kein Rand/Schatten).
        K.Set("questtracker", "bgAlpha", 0)
        QT.Apply()
        assert(not p:IsShown(), "Deckkraft 0 % laesst Rand und Schatten stehen")
        K.Set("questtracker", "bgAlpha", nil)
        QT.Apply()
        assert(p:IsShown(), "Flaeche kommt nicht zurueck")
        mod.GetBottom = function() return nil end
        QT.Apply()
        assert(not p:IsShown(), "ohne messbaren Inhalt keine leere Flaeche")
        _G.ObjectiveTrackerFrame = nil
    end)
    Check(ok, "Questliste: Flaeche so hoch wie der Inhalt" .. (ok and "" or (": " .. tostring(err))))
end

-- Schadensanzeige: ohne Messung ein Satz, mit Messung Balken.
do
    local DM = WeintCodex.UIDamageMeter
    local ok, err = pcall(function()
        DM.Refresh()
        assert(DM.RowsShown() == 0 and DM.EmptyText()
            and DM.EmptyText():find("nicht zur Verf", 1, true),
            "ohne C_DamageMeter keine Auskunft (oder leere Balken)")
        _G.Enum = _G.Enum or {}
        _G.Enum.DamageMeterType = { DamageDone = 0, HealingDone = 1, DamageTaken = 2,
            Interrupts = 5, Dispels = 6, Deaths = 7 }
        _G.Enum.DamageMeterSessionType = { Current = 0, Overall = 1 }
        _G.C_DamageMeter = { GetCombatSessionFromType = function()
            return { combatSources = {
                { name = "Testchar", classFilename = "WARRIOR", totalAmount = 12000, amountPerSecond = 400 },
                { name = "Zweiter", classFilename = "MAGE", totalAmount = 8000, amountPerSecond = 260 },
            } }
        end }
        DM.Refresh()
        assert(DM.RowsShown() == 2, "zwei Quellen, " .. DM.RowsShown() .. " Balken")
        assert(DM.AmountText(1, 1) == "12,0K (400)  60%", "Zahl im Balken: " .. tostring(DM.AmountText(1, 1)))
        -- Die Zahl aus dem Beta-Client (6.0.0.4): pro Sekunde ungerundet.
        assert(DM.Format(16.826086956522) == "17", "16,83 pro Sekunde: " .. DM.Format(16.826086956522))
        assert(DM.Format(1234567) == "1,23M" and DM.Format(0.4) == "0", "Stufen K/M, unter 1 ist 0")
        -- Weitere Fenster: oeffnen, eigene Messart, schliessen ruecken auf.
        DM.AddWindow()
        DM.AddWindow()
        assert(DM.WindowCount() == 3, "drei Fenster: " .. DM.WindowCount())
        assert(DM.RowsShown(2) == 2 and DM.Window(2):Mode().key == "HealingDone", "Fenster 2 misst Heilung")
        DM.Window(3):CycleMode()
        local third = DM.Window(3):Mode().key
        DM.RemoveWindow(2)
        assert(DM.WindowCount() == 2 and DM.Window(2):Mode().key == third, "Fenster 3 rueckt auf Platz 2")
        assert(not DM.Window(3).frame:IsShown(), "das dritte Fenster ist weg")
        DM.RemoveWindow(1)
        assert(DM.WindowCount() == 2, "das erste Fenster laesst sich nicht schliessen")
        DM.RemoveWindow(2)
        K.Set("damagemeter", "w2mode", nil)
        _G.C_DamageMeter.GetCombatSessionFromType = function() return { combatSources = {} } end
        DM.Refresh()
        assert(DM.RowsShown() == 0 and DM.EmptyText() == "Noch nichts gemessen.",
            "leere Sitzung zeigt keine Auskunft")
        _G.C_DamageMeter = nil
    end)
    Check(ok, "Schadensanzeige: unbekannt / Balken / Zahlen / Fenster / leer" .. (ok and "" or (": " .. tostring(err))))
end

-- UI 2.0, Phase 1: das Cockpit steht spiegelbildlich, die Gruppe links
-- daneben, jeder bewegliche Rahmen hat einen Platz in ui/layout.lua.
do
    local L = K.LAYOUT
    local M = K.LAYOUT_METRICS
    Check(L.uf_player.x == -L.uf_target.x and L.uf_player.y == L.uf_target.y
        and L.uf_player.point == "BOTTOMRIGHT" and L.uf_target.point == "BOTTOMLEFT",
        "Cockpit: Spieler und Ziel spiegelbildlich um die Mittelachse")
    Check(L.gf_party.x <= L.uf_player.x - M.unitWidth and L.uf_targettarget.x >= L.uf_target.x + M.unitWidth,
        "Cockpit: Gruppe links neben dem Spieler, Ziel des Ziels rechts neben dem Ziel")
    Check(K.Get("unitframes", "player_width") == M.unitWidth and K.Get("unitframes", "target_width") == M.unitWidth,
        "Cockpit: Rahmenbreite und Layout rechnen mit derselben Zahl")
    Check(not pcall(K.Layout, "gibtsnicht"), "ein Rahmen ohne Platz im Layout faellt auf")
    -- 6.6.1.4: der eigene Zauberbalken steht zwischen Spieler und Ziel -
    -- 240 breit lag er auf beiden (Beta-Test).
    local cw = K.Get("unitframes", "playerCastWidth")
    Check(cw <= 2 * M.axis - 8 and L.uf_playercast.point == "BOTTOM" and L.uf_playercast.x == 0
        and L.uf_playercast.y >= M.cockpitY and L.uf_playercast.y + K.Get("unitframes", "playerCastHeight") <= M.cockpitY + M.unitHeight,
        "Cockpit: Zauberbalken passt zwischen Spieler und Ziel (" .. tostring(cw) .. ")")
    -- 6.6.1.4: Questliste schliesst rechts mit der Minikarte ab.
    local mmE, trE
    for _, e in ipairs(K.GAME_LAYOUT) do
        if e.key == "minimap" then mmE = e elseif e.key == "tracker" then trE = e end
    end
    Check(trE.point == "TOPRIGHT" and mmE.point == "TOPRIGHT"
        and trE.x + K.Get("questtracker", "padding") == mmE.x - 6,
        "Rand: Questliste buendig mit der Minikarte")
    -- 6.6.1.6: Buffs des Spiels ueber dem Spieler, der Fokus weicht nach links.
    -- 6.6.1.7: dort nur die ausgewaehlten Buffs (Abklingzeitmanager); die
    -- Buff-Anzeige des Spiels mit allen fremden Buffs wieder oben rechts.
    local buffE, iconE
    for _, e in ipairs(K.GAME_LAYOUT) do
        if e.key == "buffs" then buffE = e elseif e.key == "bufficon" then iconE = e end
    end
    Check(iconE.point == "BOTTOMRIGHT" and iconE.relPoint == L.uf_player.relPoint and iconE.x == L.uf_player.x
        and iconE.y >= M.cockpitY + M.unitHeight and not iconE.personal and buffE.point == "TOPRIGHT"
        and L.uf_focus.x <= L.uf_player.x - M.unitWidth,
        "Cockpit: ausgewaehlte Buffs ueber dem Spielerrahmen, alle Buffs oben rechts, Fokus daneben")
end

-- Stil 2.0: Balken bekommen die Glanztextur, ein Stilwechsel erreicht sie.
do
    local ok, err = pcall(function()
        assert(K.Module("general").defaults.barStyle == "glanz", "Standard ist der Glanz")
        K.Set("general", "barStyle", "glanz")
        assert(K.BarTexture() == K.GLOSS_TEXTURE, "Glanz ist die eigene Textur")
        local sb = K.NewBar(UIParent)
        assert(sb._wcLight, "Balken ohne Lichtkante")
        K.Set("general", "barStyle", "flat")
        assert(K.BarTexture() == K.BAR_TEXTURE, "flach ist die Flaechentextur")
        K.Set("general", "barStyle", "glanz")
        local g = K.Glow(UIParent, { spread = 5 })
        assert(g.tex and g.ok, "Schein nicht angelegt")
        local kachel = K.Kachel(stub.NewObject("Frame"))
        assert(kachel.bg and kachel.border and kachel.shadow, "Kachel unvollstaendig")
        assert(K.FontPath() == WeintCodex.Fonts.hudSemi, "Standardschrift ist Plex Sans Condensed")
    end)
    Check(ok, "Stil 2.0: Glanzbalken, Lichtkante, Schein, Kachel, schmale Schrift"
        .. (ok and "" or (": " .. tostring(err))))
end

-- 6.6.0.1: Name auf dem Spielerrahmen beim Einloggen. Kennt der Client ihn
-- noch nicht ("Unbekannt"), zeichnet der Rahmen nach, bis er da ist.
do
    local UF = WeintCodex.UIUnitFrames
    local ok, err = pcall(function()
        local f = UF.frames.player
        assert(f, "kein Spielerrahmen")
        local oldName, oldAfter = _G.UnitName, _G.C_Timer.After
        local later = {}
        _G.C_Timer.After = function(_, fn) later[#later + 1] = fn end
        _G.UNKNOWNOBJECT = "Unbekannt"
        _G.UnitName = function() return "Unbekannt" end
        f:Show()
        f:Refresh()
        local kind = WeintCodex.UIKit.Get("unitframes", "player_left")
        assert(#later == 1, "ohne Namen kein Wiederholversuch (" .. #later .. ", Textplatz " .. tostring(kind) .. ")")
        _G.UnitName = function() return "Aloha" end
        later[1]()
        local shown = f.left:GetText() or ""
        assert(shown:find("Aloha", 1, true), "Name nach dem Wiederholversuch fehlt: " .. shown)
        -- Nach dem Einloggen: Texte geleert und neu gesetzt.
        f.left:SetText("")
        UF.RedrawTexts()
        assert((f.left:GetText() or ""):find("Aloha", 1, true), "RedrawTexts setzt den Namen nicht")
        _G.UnitName, _G.C_Timer.After = oldName, oldAfter
        -- 6.6.0.6: eingehende Heilung und Schilde auch an Spieler und Ziel.
        local oldHeal, oldAbs, oldMax = _G.UnitGetIncomingHeals, _G.UnitGetTotalAbsorbs, _G.UnitHealthMax
        _G.UnitHealthMax = function() return 1000 end
        _G.UnitGetIncomingHeals = function() return 250 end
        _G.UnitGetTotalAbsorbs = nil
        for _, u in ipairs({ "player", "target" }) do
            local fr = UF.frames[u]
            fr:UpdatePrediction()
            assert(fr._heal:IsShown() and fr._heal:GetValue() == 250, u .. ": eingehende Heilung fehlt")
            assert(not fr._absorb:IsShown(), u .. ": Schild ohne Antwort des Clients gezeigt")
        end
        WeintCodex.UIKit.Set("unitframes", "healPrediction", false)
        UF.frames.player:UpdatePrediction()
        assert(not UF.frames.player._heal:IsShown(), "Heilung trotz ausgeschalteter Einstellung")
        WeintCodex.UIKit.Set("unitframes", "healPrediction", true)
        _G.UnitGetIncomingHeals, _G.UnitGetTotalAbsorbs, _G.UnitHealthMax = oldHeal, oldAbs, oldMax
        -- 6.6.1.8: Treffer rot mit Minus, Heilung gruen mit Plus; alles
        -- andere (Ausweichen, geheime Art, 0) zeigt nichts.
        local pf = UF.frames.player
        local shown
        local oldFmt = pf._fb.SetFormattedText
        pf._fb.SetFormattedText = function(_, fmt, v) shown = string.format(fmt, v) end
        pf._fb:Hide()
        pf:CombatFeedback("WOUND", "", 1234)
        assert(pf._fb:IsShown() and shown == "-1,2K", "Treffer nicht als -1,2K: " .. tostring(shown))
        pf:CombatFeedback("HEAL", "CRITICAL", 87)
        assert(shown == "+87", "Heilung nicht als +87: " .. tostring(shown))
        shown = nil
        pf:CombatFeedback("DODGE", "", 0)
        pf:CombatFeedback("WOUND", "", 0)
        local oldSecret = _G.issecretvalue
        local secret = {}
        _G.issecretvalue = function(v) return v == secret end
        pf:CombatFeedback(secret, "", 50)
        _G.issecretvalue = oldSecret
        assert(shown == nil, "Zahl fuer Ausweichen, 0 oder geheime Art gezeigt")
        WeintCodex.UIKit.Set("unitframes", "combatFeedback", false)
        pf:CombatFeedback("WOUND", "", 5)
        assert(shown == nil, "Zahl trotz ausgeschalteter Einstellung")
        WeintCodex.UIKit.Set("unitframes", "combatFeedback", true)
        pf._fb.SetFormattedText = oldFmt
        assert(UF.frames.target._fb and not UF.frames.focus._fb, "Zahl nur an Spieler und Ziel")
        -- 6.6.0.4: Aurenleisten wieder ausgebaut - der Client gibt Addons
        -- im Kampf weder die Auren des Ziels noch die eigenen heraus.
        assert(not UF.frames.player._auraBars and not UF.frames.target._auraBars,
            "Aurenleisten zurueck (im Kampf geheim, Beta-Test 6.6.0.3)")
    end)
    Check(ok, "Spielerrahmen: Name kommt nach, wenn der Client ihn beim Einloggen noch nicht kennt"
        .. (ok and "" or (": " .. tostring(err))))
end

-- 6.6.1.8: Speicher messen - K.Measured zaehlt nur waehrend einer Messung,
-- der Bericht nennt die groessten Erzeuger; Erinnerungen und
-- Schadensanzeige sammeln haeufige Ereignisse.
do
    local ok, err = pcall(function()
        local oldGc, oldClock, oldAfter = _G.collectgarbage, _G.debugprofilestop, _G.C_Timer.After
        local mem, clock = 1000, 0
        _G.collectgarbage = function(opt) assert(opt == "count") return mem end
        _G.debugprofilestop = function() return clock end
        local calls = 0
        local fn = K.Measured("Testteil", function(a, b) calls = calls + 1 mem = mem + 5 clock = clock + 2 return a + b, "x" end)
        assert(fn(1, 2) == 3 and not next(K.prof.data), "ohne Messung gezaehlt")
        local later
        _G.C_Timer.After = function(_, f) later = f end
        local lines
        K.ProfileRun(10, function(l) lines = l end)
        local r1, r2 = fn(2, 3)
        fn(1, 1)
        assert(r1 == 5 and r2 == "x", "Rueckgabewerte verloren")
        assert(K.prof.data.Testteil.calls == 2 and K.prof.data.Testteil.kb == 10, "Aufrufe/Speicher falsch gezaehlt")
        later()
        assert(not K.prof.on and lines, "Messung endet nicht")
        local found = false
        for _, l in ipairs(lines) do if l:find("Testteil: 1,0 KB/s", 1, true) or l:find("Testteil: 1.0 KB/s", 1, true) then found = true end end
        assert(found, "Bericht nennt den Erzeuger nicht: " .. table.concat(lines, " | "))
        -- Erinnerungen: viele Ereignisse, eine Auswertung.
        local R = WeintCodex.UIReminders
        local n, oldUC = 0, R.UpdateCooldowns
        R.UpdateCooldowns = function() n = n + 1 end
        R.Flush()   -- was frueher im Test angestossen wurde
        n = 0
        local flush
        _G.C_Timer.After = function(_, f) flush = f end
        for _ = 1, 20 do R.Schedule(false, false, true) end
        flush()
        assert(n == 1, "Abklingzeiten " .. n .. "x statt 1x ausgewertet")
        R.UpdateCooldowns = oldUC
        -- Aufgeloeste Zauber werden gemerkt, bis SPELLS_CHANGED leert.
        local asked = 0
        local oldSpell = _G.C_Spell
        _G.C_Spell = { GetSpellInfo = function(k) asked = asked + 1 return { spellID = 17, name = "Schild", iconID = 1 } end }
        R.ClearCache()
        R.Resolve("Schild") R.Resolve("Schild")
        assert(asked == 1, "Zauber " .. asked .. "x aufgeloest")
        R.ClearCache()
        R.Resolve("Schild")
        assert(asked == 2, "Merkliste nicht geleert")
        R.ClearCache()
        _G.C_Spell = oldSpell
        _G.collectgarbage, _G.debugprofilestop, _G.C_Timer.After = oldGc, oldClock, oldAfter
    end)
    Check(ok, "Speicher: Messung je Teil, Ereignisse gesammelt, Zauber gemerkt" .. (ok and "" or (": " .. tostring(err))))
end

-- 6.6.1.9: /wcui speicher im Beta-Test - die Aktionsleisten machten 350
-- von 400 KB/s, weil das Einblenden bei Maus darueber jedes Bild eine
-- frische Liste baute. Gemessen mit dem echten Speicherzaehler von Lua:
-- 300 Bilder duerfen kaum Speicher belegen.
do
    local ok, err = pcall(function()
        local AB = WeintCodex.UIActionBars
        if type(_G.MultiBarBottomLeft) ~= "table" then CreateFrame("Frame", "MultiBarBottomLeft", UIParent) end
        K.Set("actionbars", "b2_show", "mouseover")
        AB.UpdateMouseover()
        AB._fadeStep(nil, 0.016)
        collectgarbage("collect")
        collectgarbage("stop")
        local before = collectgarbage("count")
        for _ = 1, 300 do AB._fadeStep(nil, 0.016) end
        local grew = collectgarbage("count") - before
        collectgarbage("restart")
        K.Set("actionbars", "b2_show", "always")
        AB.UpdateMouseover()
        assert(grew < 30, string.format("300 Bilder Einblenden belegen %.0f KB", grew))
        -- Questpfeil: zwischen den ganzen Durchlaeufen dreht sich nur der Pfeil.
        local QA = WeintCodex.UIQuestArrow
        local aim = QA._aim
        aim.ok = false
        assert(QA.Turn() == false, "Pfeil gedreht ohne gemerkte Punkte")
    end)
    Check(ok, "Speicher: Aktionsleisten blenden ohne neue Tabellen je Bild, Questpfeil dreht zwischendurch nur"
        .. (ok and "" or (": " .. tostring(err))))
end

-- Ruhe und Kampf: ohne Ziel und bei vollem Leben treten Spielerrahmen und
-- Schadensanzeige zurueck; Ziel, Kampf und Testmodus holen sie zurueck.
do
    local P = WeintCodex.UIPresence
    local UF = WeintCodex.UIUnitFrames
    local DM = WeintCodex.UIDamageMeter
    local ok, err = pcall(function()
        assert(P.elements.player and P.elements.mainbar and P.elements.bars and P.elements.damage,
            "nicht alle Elemente angemeldet")
        local target, combat = false, false
        local oldExists, oldHealth, oldMax, oldCombat = _G.UnitExists, _G.UnitHealth, _G.UnitHealthMax, _G.InCombatLockdown
        local oldAffecting = _G.UnitAffectingCombat
        _G.UnitAffectingCombat = function() return combat end
        _G.UnitExists = function(u) if u == "target" then return target end return true end
        _G.UnitHealth = function() return 100 end
        _G.UnitHealthMax = function() return 100 end
        _G.InCombatLockdown = function() return combat end
        assert(P.Compute() == "ruhe", "ohne Ziel bei vollem Leben: " .. P.Compute())
        P.Evaluate(true)
        P.Apply(true)
        local player = UF.frames.player
        assert(math.abs(player:GetAlpha() - 0.35) < 0.001, "Spielerrahmen in Ruhe: " .. tostring(player:GetAlpha()))
        assert(math.abs(DM.Window(1).frame:GetAlpha() - 0.45) < 0.001, "Schadensanzeige in Ruhe")
        target = true
        P.Evaluate(true)
        P.Apply(true)
        assert(P.State() == "bereit" and player:GetAlpha() == 1, "mit Ziel nicht voll")
        target = false
        _G.UnitHealth = function() return 60 end
        assert(P.Compute() == "bereit", "angeschlagen ist nicht Ruhe")
        _G.UnitHealth = function() return nil end
        assert(P.Compute() == "bereit", "unbekanntes Leben zaehlt nicht als voll")
        _G.UnitHealth = function() return 100 end
        P.Evaluate(true)
        P.Force("test", true)
        assert(player:GetAlpha() == 1, "Testmodus zeigt nicht alles voll")
        P.Force("test", false)
        assert(math.abs(player:GetAlpha() - 0.35) < 0.001, "nach dem Testmodus nicht zurueck in Ruhe")
        K.Set("general", "presence", false)
        assert(player:GetAlpha() == 1, "abgeschaltet: trotzdem leiser")
        K.Set("general", "presence", true)
        combat = true
        stub.FireEvent("PLAYER_REGEN_DISABLED")
        assert(P.State() == "kampf" and player:GetAlpha() == 1, "im Kampf nicht sofort voll")
        combat = false
        _G.UnitExists, _G.UnitHealth, _G.UnitHealthMax, _G.InCombatLockdown = oldExists, oldHealth, oldMax, oldCombat
        _G.UnitAffectingCombat = oldAffecting
    end)
    Check(ok, "Ruhe und Kampf: Ruhe leiser, Ziel/Kampf/Testmodus voll, Unbekannt ist nicht Ruhe"
        .. (ok and "" or (": " .. tostring(err))))
end

-- Testmodus: Beispieldaten, als solche gekennzeichnet, und wieder weg.
do
    local T = WeintCodex.UITestMode
    local UF = WeintCodex.UIUnitFrames
    local DM = WeintCodex.UIDamageMeter
    local ok, err = pcall(function()
        local party = _G.WeintCodexPartyHeader
        if party then party:Hide() end
        T.Set(true)
        assert(T.IsOn() and _G.WeintCodexTestBanner and _G.WeintCodexTestBanner:IsShown(), "kein Band 'Testmodus'")
        local tf = UF.frames.target
        assert(tf:IsShown() and tf.left:GetText():find("Kobold", 1, true), "Zielrahmen ohne Beispiel: " .. tostring(tf.left:GetText()))
        assert(DM.Window(1).title:GetText():find("Beispiel", 1, true), "Schadensanzeige sagt nicht 'Beispiel'")
        assert(DM.RowsShown() == 5, "fuenf Beispielzeilen erwartet: " .. DM.RowsShown())
        local shownTest = 0
        for _, b in ipairs(WeintCodex.UIGroupFrames.buttons) do
            if b._wcTest and b:IsShown() then shownTest = shownTest + 1 end
        end
        assert(shownTest == 5, "fuenf Beispielknoepfe der Gruppe erwartet: " .. shownTest)
        stub.FireEvent("PLAYER_REGEN_DISABLED")
        assert(not T.IsOn() and not _G.WeintCodexTestBanner:IsShown(), "Kampf beendet den Testmodus nicht")
        assert(not DM._test, "Schadensanzeige bleibt im Beispiel")
        if party then party:Show() end
    end)
    Check(ok, "Testmodus: Band, Beispielziel, Beispielgruppe, Schadensanzeige 'Beispiel', endet im Kampf"
        .. (ok and "" or (": " .. tostring(err))))
end

-- UI 2.0, Phase 2: das Cockpit im Einzelnen.
do
    local UF = WeintCodex.UIUnitFrames
    local AB = WeintCodex.UIActionBars
    local DM = WeintCodex.UIDamageMeter
    local NP = WeintCodex.UINameplates
    local ok, err = pcall(function()
        -- Kombopunkte: fuenf Segmente, alle mit demselben Stand, jedes von
        -- i-1 bis i - kein Vergleich mit dem (womoeglich geheimen) Stand.
        local tf = UF.frames.target
        tf:SetCombo(3, 5)
        local pips = tf._combo.pips
        assert(#pips == 5 and tf._combo:IsShown(), "fuenf Segmente erwartet: " .. #pips)
        for i, pip in ipairs(pips) do
            assert(pip._min == i - 1 and pip._max == i and pip._value == 3,
                "Segment " .. i .. " falsch: " .. tostring(pip._min) .. "-" .. tostring(pip._max) .. " = " .. tostring(pip._value))
        end
        -- Stufe in Schwierigkeitsfarbe, Elite mit +.
        local oldLevel, oldCls = _G.UnitLevel, _G.UnitClassification
        _G.UnitLevel = function() return 23 end
        _G.UnitClassification = function() return "elite" end
        assert(UF.LevelParts("target") == "23+", "Elite ohne +")
        _G.UnitLevel = function() return -1 end
        assert(UF.LevelParts("target") == "??", "unbekannte Stufe nicht ??")
        _G.UnitLevel, _G.UnitClassification = oldLevel, oldCls
        -- Kurze Tastenkuerzel.
        assert(AB.ShortHotkey("Maustaste 4") == "M4" and AB.ShortHotkey("s-1") == "S1"
            and AB.ShortHotkey("c-s-2") == "CS2" and AB.ShortHotkey("Mausrad hoch") == "MU"
            and AB.ShortHotkey("E") == "E", "Tastenkuerzel nicht gekuerzt")
        -- Schadensanzeige: so hoch wie ihre Zeilen.
        DM.ShowTest(true)
        local h5 = DM.Window(1).frame:GetHeight()
        DM.ShowTest(false)
        _G.C_DamageMeter = nil
        DM.Refresh()
        local hEmpty = DM.Window(1).frame:GetHeight()
        assert(h5 > hEmpty, "Hoehe folgt dem Inhalt nicht: " .. h5 .. " / " .. hEmpty)
        -- Plakette: Hinrichtungsmarke bei 20 % der Breite.
        K.Set("nameplates", "executeMark", true)
        stub.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate1")
        local p = NP.plates["nameplate1"]
        assert(p.exec:IsShown(), "Hinrichtungsmarke fehlt")
        stub.FireEvent("NAME_PLATE_UNIT_REMOVED", "nameplate1")
        K.Set("nameplates", "executeMark", false)
    end)
    Check(ok, "Cockpit: Kombosegmente ohne Vergleich, Stufe 23+/??, kurze Tastenkuerzel, Schadensanzeige nach Inhalt, Hinrichtungsmarke"
        .. (ok and "" or (": " .. tostring(err))))
end

-- UI 2.0, 6.3.0.0: Antworten auf den vierten Beta-Test.
do
    local UF = WeintCodex.UIUnitFrames
    local NP = WeintCodex.UINameplates
    local DM = WeintCodex.UIDamageMeter
    local E  = WeintCodex.UIEditMode
    local T  = WeintCodex.UITestMode
    local ok, err = pcall(function()
        -- Zielrahmen zeichnet sich beim Erscheinen (war: weisser Balken).
        local oldName, oldExists = _G.UnitName, _G.UnitExists
        _G.UnitName = function() return "Himmelshuepfer" end
        _G.UnitExists = function() return true end
        local tf = UF.frames.target
        tf.left:SetText("")
        tf._scripts.OnShow(tf)
        assert(tf.left:GetText():find("Himmelshuepfer", 1, true), "Zielrahmen beim Erscheinen leer: " .. tostring(tf.left:GetText()))
        _G.UnitName, _G.UnitExists = oldName, oldExists

        -- Plakette: die Debuff-Symbole des Spiels bleiben an ihrem Platz
        -- sichtbar, der Rest der Spielplakette wird ausgeblendet. Kein
        -- Anker wird gelesen (6.3.0.0: "Can't measure restricted regions").
        local uf = blizzPlate.UnitFrame
        local af = stub.NewObject("Frame")
        af._parent = uf
        local hp = stub.NewObject("Frame")
        local nameFs = stub.NewObject("FontString")
        uf.AurasFrame = af
        uf.GetChildren = function() return af, hp end
        uf.GetRegions = function() return nameFs end
        local measured = false
        af.GetPoint = function() measured = true error("Can't measure restricted regions") end
        af.GetNumPoints = function() measured = true return 1 end
        local oldHook = _G.hooksecurefunc
        _G.hooksecurefunc = function(obj, name, fn)
            local orig = obj[name]
            obj[name] = function(...) local r = orig(...) fn(...) return r end
        end
        stub.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate1")
        local p = NP.plates["nameplate1"]
        assert(p, "Plakette nicht angelegt")
        assert(not measured, "Anker der Spiel-Symbole gelesen - im Beta-Client verboten")
        assert(af:GetParent() == uf, "Symbole des Spiels umgehaengt")
        assert(uf:GetAlpha() == 1 and af:GetAlpha() == 1, "Symbole des Spiels unsichtbar")
        assert(hp:GetAlpha() == 0 and nameFs:GetAlpha() == 0, "Rest der Spielplakette sichtbar")
        hp:SetAlpha(1)   -- das Spiel setzt zurueck ...
        assert(hp:GetAlpha() == 0, "Spiel blendet seine Plakette wieder ein")
        assert(NP.GameAuraInfo("nameplate1"):find("sichtbar an ihrem Platz", 1, true), "Auren-Pruefung: " .. tostring(NP.GameAuraInfo("nameplate1")))
        K.Set("nameplates", "auraSource", "own")
        assert(uf:GetAlpha() == 0 and af:GetParent() ~= uf, "eigene Symbole gewaehlt, die des Spiels stehen noch da")
        assert(hp:GetAlpha() == 1, "Teile der Spielplakette nicht zurueckgesetzt")
        K.Set("nameplates", "auraSource", "game")
        assert(af:GetParent() == uf and uf:GetAlpha() == 1 and hp:GetAlpha() == 0, "zurueck auf die des Spiels greift nicht")
        stub.FireEvent("NAME_PLATE_UNIT_REMOVED", "nameplate1")
        assert(af:GetParent() == uf and uf:GetAlpha() == 1 and hp:GetAlpha() == 1, "Spielplakette nicht zurueckgegeben")
        _G.hooksecurefunc = oldHook
        uf.AurasFrame, uf.GetChildren, uf.GetRegions = nil, nil, nil

        -- Schadensanzeige: eigene Zeile immer da, mit echtem Rang.
        _G.Enum = _G.Enum or {}
        _G.Enum.DamageMeterType = { DamageDone = 0, HealingDone = 1, DamageTaken = 2, Interrupts = 5, Dispels = 6, Deaths = 7 }
        _G.Enum.DamageMeterSessionType = { Current = 0, Overall = 1 }
        local srcs = {}
        for i = 1, 5 do srcs[i] = { name = "Spieler" .. i, classFilename = "MAGE", totalAmount = 600 - i * 100,
            amountPerSecond = 10, sourceGUID = "G" .. i, isLocalPlayer = (i == 5) } end
        local spellsAsked
        _G.C_DamageMeter = {
            GetCombatSessionFromType = function() return { combatSources = srcs } end,
            GetCombatSessionFromID = function() return { combatSources = srcs } end,
            GetAvailableCombatSessions = function() return { { sessionID = 11, name = "Kobold" }, { sessionID = 12 } } end,
            GetCombatSessionSourceFromType = function(_, _, guid)
                spellsAsked = guid
                return { combatSpells = { { spellID = 1, totalAmount = 60 }, { spellID = 2, totalAmount = 40 } } }
            end,
        }
        K.Set("damagemeter", "bars", 3)
        DM.Refresh()
        local w = DM.Window(1)
        assert(DM.RowsShown() == 3, "drei Zeilen erwartet")
        assert(w.rows[3].name:GetText() == "5. Spieler5", "eigene Zeile nicht angeheftet: " .. tostring(w.rows[3].name:GetText()))
        assert(w.rows[3].own:IsShown() and not w.rows[1].own:IsShown(), "eigene Zeile nicht markiert")
        DM.ShowTooltip(w, w.rows[1])
        assert(spellsAsked == "G1", "Tooltip fragt die Zauber nicht ab")
        w:CycleSession()        -- Gesamt
        w:CycleSession()        -- neuester frueherer Kampf (12)
        assert(w:Session() == 12 and w:SessionLabel() == "Kampf −1", "frueherer Kampf: " .. tostring(w:Session()) .. " " .. w:SessionLabel())
        w:CycleSession()
        assert(w:Session() == 11 and w:SessionLabel() == "Kobold", "Name des Kampfes fehlt: " .. w:SessionLabel())
        w:CycleSession()
        assert(w:Session() == "Current", "Reihe laeuft nicht zurueck auf Aktuell")
        K.Set("damagemeter", "bars", 8)
        _G.C_DamageMeter = nil
        DM.Refresh()

        -- Gestaltungsmodus: Fenster zu, Leiste, Testdaten, Pfeiltasten,
        -- Esc, Fenster wieder auf.
        UO.Show("general")
        K.SetUnlocked(true)
        local bar = _G.WeintCodexDesignBar
        assert(bar and bar:IsShown() and not UO.frame:IsShown(), "Leiste fehlt oder Fenster noch offen")
        assert(T.IsOn(), "Testdaten nicht an")
        K.SelectMover("uf_player")
        local y0 = K.LAYOUT.uf_player.y
        bar._scripts.OnKeyDown(bar, "UP")
        local pos = K.MoverPosition("uf_player")
        assert(pos.y == y0 + 1, "Pfeiltaste schiebt nicht: " .. tostring(pos.y))
        bar._scripts.OnKeyDown(bar, "ESCAPE")
        assert(not K.IsUnlocked() and not bar:IsShown() and not T.IsOn() and UO.frame:IsShown(),
            "Esc beendet nicht sauber")
        K.ResetAllPositions()
        UO.frame:Hide()
        assert(E.ModuleFor("uf_target") == "unitframes" and E.ModuleFor("damagemeter2") == "damagemeter",
            "Doppelklick findet die Einstellungsseite nicht")
        -- Einrasten: nah an der Mitte -> auf die Achse, sonst aufs 8er-Raster.
        K.SetUnlocked(true)
        local fake = { GetLeft = function() return 395 end, GetBottom = function() return 51 end,
                       GetWidth = function() return 10 end, GetHeight = function() return 10 end }
        local dx, dy = E.SnapOffset(fake)
        assert(dx == 400 - 400 and dy == -3, "Einrasten: " .. dx .. ", " .. dy)
        fake.GetLeft = function() return 103 end
        dx = E.SnapOffset(fake)
        assert(dx == 1, "Raster: " .. dx)
        K.SetUnlocked(false)
    end)
    Check(ok, "6.3: Zielrahmen beim Erscheinen, Symbole des Spiels, Schadensanzeige wie Details, Gestaltungsmodus"
        .. (ok and "" or (": " .. tostring(err))))

    -- Aktionsleisten: leere Plaetze weg, beim Ziehen eines Zaubers da.
    ok, err = pcall(function()
        local b = CreateFrame("CheckButton", "ActionButton2", UIParent)
        b.icon = b:CreateTexture()
        b.HotKey = b:CreateFontString()
        b.action = 5
        local oldHas = _G.HasAction
        _G.HasAction = function() return false end
        -- Seit 6.3.1.9 sind leere Plaetze standardmaessig sichtbar.
        WeintCodex.UIActionBars.SkinAll()
        assert(b:GetAlpha() == 1, "leerer Platz im Standard unsichtbar")
        K.Set("actionbars", "emptySlots", "hide")
        WeintCodex.UIActionBars.SkinAll()
        assert(b:GetAlpha() == 0, "leerer Platz sichtbar")
        stub.FireEvent("ACTIONBAR_SHOWGRID")
        assert(b:GetAlpha() == 1, "beim Ziehen bleibt der Platz unsichtbar")
        stub.FireEvent("ACTIONBAR_HIDEGRID")
        assert(b:GetAlpha() == 0, "nach dem Ziehen nicht wieder weg")
        _G.HasAction = function() return true end
        WeintCodex.UIActionBars.SkinAll()
        assert(b:GetAlpha() == 1, "belegter Platz unsichtbar")
        K.Set("actionbars", "emptySlots", nil)
        _G.HasAction = oldHas
        _G.ActionButton2 = nil
    end)
    Check(ok, "Aktionsleisten: leere Plaetze aus, beim Ziehen sichtbar" .. (ok and "" or (": " .. tostring(err))))

    -- 6.3.0.2: der Symbolrahmen des Spiels bleibt weg, auch wenn das Spiel
    -- ihn neu setzt; das Symbol fuellt den Knopf.
    ok, err = pcall(function()
        local oldHook = _G.hooksecurefunc
        _G.hooksecurefunc = function(obj, name, fn)
            local orig = obj[name]
            obj[name] = function(...) local r = orig(...) fn(...) return r end
        end
        local b = CreateFrame("CheckButton", "ActionButton3", UIParent)
        b.icon = b:CreateTexture()
        local normal = b:CreateTexture()
        b.GetNormalTexture = function() return normal end
        b.SetNormalAtlas = function() normal:SetAlpha(1) end
        b.action = 6
        local oldHas = _G.HasAction
        _G.HasAction = function() return true end
        WeintCodex.UIActionBars.SkinAll()
        assert(normal:GetAlpha() == 0, "Symbolrahmen des Spiels sichtbar")
        b:SetNormalAtlas("UI-HUD-ActionBar-IconFrame")
        assert(normal:GetAlpha() == 0, "Symbolrahmen nach SetNormalAtlas wieder da (innerer Rahmen)")
        normal:SetAlpha(1)
        assert(normal:GetAlpha() == 0, "Symbolrahmen nach SetAlpha wieder da")
        _G.HasAction = oldHas
        _G.hooksecurefunc = oldHook
        _G.ActionButton3 = nil
    end)
    Check(ok, "Aktionsleisten: ein Rahmen, der des Spiels bleibt weg" .. (ok and "" or (": " .. tostring(err))))

    -- 6.3.0.3: Flaeche hinter der Leiste, verankert an linker oberer und
    -- rechter unterer Taste; Blaetterpfeile weg.
    ok, err = pcall(function()
        local AB = WeintCodex.UIActionBars
        local bar = CreateFrame("Frame", "MultiBarBottomLeft", UIParent)
        local pos = { { 100, 200 }, { 140, 200 }, { 100, 160 }, { 140, 160 } }
        for i, xy in ipairs(pos) do
            local b = CreateFrame("CheckButton", "MultiBarBottomLeftButton" .. i, bar)
            b.GetLeft = function() return xy[1] end
            b.GetTop = function() return xy[2] end
            b.GetRight = function() return xy[1] + 36 end
            b.GetBottom = function() return xy[2] - 36 end
        end
        AB.UpdateBackdrops()
        local bd = AB.backdrops[bar]
        assert(bd and bd:IsShown(), "keine Flaeche hinter der Leiste")
        assert(bd:GetParent() == bar, "Flaeche blendet nicht mit der Leiste ab")
        K.Set("actionbars", "barBackdrop", false)
        AB.UpdateBackdrops()
        assert(not bd:IsShown(), "Flaeche bleibt trotz Schalter")
        K.Set("actionbars", "barBackdrop", true)
        -- Ordnet das Spiel: Flaeche an den gemessenen Ecken; geheime Lage
        -- -> keine Flaeche statt eines Fehlers.
        K.Set("actionbars", "layout", "game")
        AB.UpdateBackdrops()
        assert(bd:IsShown(), "Flaeche fehlt, wenn das Spiel ordnet")
        _G.MultiBarBottomLeftButton2.GetLeft = function() error("Can't measure restricted regions") end
        AB.UpdateBackdrops()
        assert(not bd:IsShown(), "Flaeche trotz unmessbarer Knoepfe")
        K.Set("actionbars", "layout", "wc")

        -- 6.3.0.4: WeintCodex ordnet je Leiste - Groesse, Abstand, je Reihe,
        -- Anzahl; jenseits der Anzahl unsichtbar und taub.
        for i = 1, 4 do _G["MultiBarBottomLeftButton" .. i].GetLeft = nil end
        local sizes, pts, mouse = {}, {}, {}
        for i = 1, 4 do
            local b = _G["MultiBarBottomLeftButton" .. i]
            b.SetSize = function(_, w, h) sizes[i] = w end
            b.SetPoint = function(_, p, rel, rp, x, y) pts[i] = { p, rel, rp, x, y } end
            b.EnableMouse = function(_, on) mouse[i] = on end
        end
        local barW, barH
        bar.SetSize = function(_, w, h) barW, barH = w, h end
        K.Set("actionbars", "b2_size", 30)
        K.Set("actionbars", "b2_spacing", 4)
        K.Set("actionbars", "b2_perRow", 2)
        K.Set("actionbars", "b2_count", 3)
        AB.LayoutAll()
        assert(sizes[1] == 30 and sizes[3] == 30, "Symbolgroesse nicht gesetzt")
        assert(pts[2][2] == bar and pts[2][4] == 34 and pts[2][5] == 0, "zweiter Knopf falsch: " .. tostring(pts[2] and pts[2][4]))
        assert(pts[3][4] == 0 and pts[3][5] == -34, "zweite Reihe falsch")
        assert(AB.cut[_G.MultiBarBottomLeftButton4] and mouse[4] == false, "Knopf jenseits der Anzahl nicht ausgeblendet")
        assert(barW == 64 and barH == 64, "Leiste nicht auf ihre Knoepfe zugeschnitten: " .. tostring(barW) .. "x" .. tostring(barH))
        K.Set("actionbars", "b2_count", 12)
        AB.LayoutAll()
        assert(not AB.cut[_G.MultiBarBottomLeftButton4] and mouse[4] == true, "Knopf kommt nicht zurueck")
        for _, k in ipairs({ "b2_size", "b2_spacing", "b2_perRow", "b2_count" }) do K.Set("actionbars", k, nil) end

        -- Nur bei Maus darueber: aus "Ruhe und Kampf" heraus.
        K.Set("actionbars", "b2_show", "mouseover")
        assert(AB.IsMouseoverBar(bar), "Leiste nicht als 'Maus darueber' erkannt")
        K.Set("actionbars", "b2_show", nil)
        assert(not AB.IsMouseoverBar(bar), "Leiste bleibt 'Maus darueber'")


        -- Die Seite "Leisten" baut sich, und ihre Regler folgen der Auswahl.
        local reported
        local oldReport = K.Report
        K.Report = function(_, msg) reported = msg end
        WeintCodex.UIOptions.Show("actionbars", 2)
        K.Set("actionbars", "editBar", 9)
        WeintCodex.UIOptions.frame:Hide()
        K.Set("actionbars", "editBar", nil)
        K.Report = oldReport
        assert(not reported, "Seite 'Leisten' bricht ab: " .. tostring(reported))

        -- Die Leisten des Spiels stehen NICHT im Gestaltungsmodus: das Spiel
        -- stapelt sie im Kampf selbst neu (ADDON_ACTION_BLOCKED, 6.3.0.5).
        for key in pairs(K.movers) do
            assert(not key:find("^ab_"), "Aktionsleiste im Gestaltungsmodus: " .. key)
        end
        for i = 1, 4 do _G["MultiBarBottomLeftButton" .. i] = nil end
        _G.MultiBarBottomLeft = nil
        AB.backdrops[bar] = nil

        local up = CreateFrame("Button", "ActionBarUpButton", UIParent)
        AB.HidePaging()
        assert(up:GetAlpha() == 0, "Blaetterpfeil sichtbar")
        _G.ActionBarUpButton = nil
    end)
    Check(ok, "Aktionsleisten: Flaeche hinter der Leiste, Blaetterpfeile weg" .. (ok and "" or (": " .. tostring(err))))

    -- 6.3.0.2: die Auren-Pruefung uebersteht geheime Breiten und verbotene
    -- Knoepfe (im Beta-Client: "secret number", "forbidden object").
    ok, err = pcall(function()
        local A = WeintCodex.UIAuras
        local obj = A.Create(UIParent, { filter = "HARMFUL", max = 3, size = 20 })
        local secretBtn = stub.NewObject("Button")
        secretBtn.GetWidth = function() return setmetatable({}, { __sub = function() error("attempt to perform arithmetic on a secret number value") end }) end
        local forbiddenBtn = stub.NewObject("Button")
        forbiddenBtn.IsForbidden = function() return true end
        forbiddenBtn.GetWidth = function() error("Attempt to access forbidden object") end
        obj.frame.GetChildren = function() return secretBtn, forbiddenBtn end
        local oldExists, oldIsUnit = _G.UnitExists, _G.UnitIsUnit
        _G.UnitExists = function() return true end
        _G.UnitIsUnit = function() return true end
        obj:SetUnit("target")
        local oldButtons = obj.buttons
        obj.buttons = nil          -- Container-Weg: Kinder ablaufen
        local lines = A.Inspect()
        obj.buttons = oldButtons
        _G.UnitExists, _G.UnitIsUnit = oldExists, oldIsUnit
        obj:SetUnit(nil)
        assert(#lines >= 2, "Auren-Pruefung zu kurz")
    end)
    Check(ok, "Auren-Pruefung: geheime Breite und verbotene Knoepfe brechen nichts ab" .. (ok and "" or (": " .. tostring(err))))
end

-- 6.3.0.7: Aufschluesselung wie Details, Infozeile unter dem Chat,
-- Taschenleiste im Stil der Aktionsknoepfe.
do
    local DM = WeintCodex.UIDamageMeter
    local ok, err = pcall(function()
        DM.ShowTest(true)
        local w = DM.Window(1)
        local r1, r2 = w.rows[1], w.rows[2]
        assert(r1._src and r1._scripts.OnMouseUp, "Zeile ohne Klick")
        r1._scripts.OnMouseUp(r1, "LeftButton")
        local bd = DM.Breakdown()
        assert(bd and bd.frame:IsShown(), "Aufschluesselung geht nicht auf")
        assert(bd.name:GetText() == "Varek", "falscher Spieler: " .. tostring(bd.name:GetText()))
        assert(bd.stats[4].value:GetText() == "1 / 5", "Rang: " .. tostring(bd.stats[4].value:GetText()))
        assert(bd.stats[3].value:GetText() == "32%", "Anteil: " .. tostring(bd.stats[3].value:GetText()))
        assert(bd.rows[1]:IsShown() and bd.rows[4]:IsShown() and not bd.rows[5]:IsShown(), "Zauberzeilen")
        -- 2100 von 4940 in 42 s: "2.100 (50)  43%" in welcher Schreibweise auch immer.
        local amt = bd.rows[1].amount:GetText() or ""
        assert(amt:find("43%", 1, true) and amt:find("(", 1, true), "Zauberzeile ohne Anteil/je Sekunde: " .. amt)
        DM.StepBreakdown(1)
        assert(bd.name:GetText() == "Tamsin", "Pfeil blaettert nicht: " .. tostring(bd.name:GetText()))
        assert(bd.prev:IsShown(), "Pfeil zurueck fehlt")
        -- Noch einmal auf den gezeigten Spieler: zu.
        r2._scripts.OnMouseUp(r2, "LeftButton")
        assert(not bd.frame:IsShown(), "zweiter Klick schliesst nicht")
        DM.ShowTest(false)
    end)
    Check(ok, "Schadensanzeige: Aufschluesselung per Klick (Kennzahlen, Zauber, Blaettern)"
        .. (ok and "" or (": " .. tostring(err))))

    -- 6.6.2.1: verschiebbar, Vergleich, Verlauf, Auren.
    ok, err = pcall(function()
        DM.ShowTest(true)
        local w = DM.Window(1)
        local r1 = w.rows[1]
        r1._scripts.OnMouseUp(r1, "LeftButton")
        local bd = DM.Breakdown()
        local f = bd.frame
        assert(f._scripts.OnDragStart and f._scripts.OnDragStop, "Aufschluesselung nicht verschiebbar")
        K.Set("damagemeter", "bdX", 300)
        K.Set("damagemeter", "bdY", 200)
        assert(DM.PlaceBreakdown(w) == "saved", "verschobene Stelle vergessen")
        f._scripts.OnMouseUp(f, "RightButton")
        assert(K.Get("damagemeter", "bdX") == nil and DM.PlaceBreakdown(w) == "beside", "Rechtsklick setzt nicht zurueck")
        -- Vergleich: Tamsin waehlbar, Varek (der Gezeigte) nicht.
        local names = {}
        for _, it in ipairs(DM.CompareItems()) do names[it.value] = true end
        assert(names.Tamsin and not names.Varek and names[""], "Vergleichsliste falsch")
        DM.SetCompare("Tamsin")
        local cmp = bd.stats[1].cmp:GetText() or ""
        assert(bd.stats[1].cmp:IsShown() and cmp:find("+13 %", 1, true), "Kennzahl ohne Vergleich: " .. cmp)
        assert(bd.rows[1].bar2:IsShown() and (bd.rows[1].amount:GetText() or ""):find("|", 1, true),
            "Zauber ohne zweiten Balken")
        assert(DM.Diff(50, 100) == "-50 %" and DM.Diff(1, nil) == nil, "Unterschied falsch")
        -- Verlauf und Auren als Ansichten.
        bd.view = "graph"
        DM.RefreshBreakdown()
        assert(bd.graph:IsShown() and DM.lastRates and #DM.lastRates == 48, "Verlauf nicht gezeichnet")
        assert(bd.marks[1] and bd.marks[1]:IsShown(), "Vergleich fehlt im Verlauf")
        bd.view = "auras"
        DM.RefreshBreakdown()
        local shown = 0
        for _, t in ipairs(bd.icons) do if t:IsShown() then shown = shown + 1 end end
        assert(bd.auraBox:IsShown() and shown == 3, "Auren beider Spieler: " .. shown)
        DM.SetCompare("")
        assert(not bd.cmp and not bd.stats[1].cmp:IsShown(), "Vergleich laesst sich nicht abwaehlen")
        bd.view = "spells"
        f:Hide()
        DM.ShowTest(false)

        -- Aufzeichnung: offene Zahlen ja, geheime nein.
        local oldCDM, oldTime, oldEnum = _G.C_DamageMeter, _G.GetTime, _G.Enum
        _G.Enum = setmetatable({ DamageMeterType = { DamageDone = 0, HealingDone = 1 },
            DamageMeterSessionType = { Current = 0, Overall = 1 } }, { __index = oldEnum })
        local now, total = 100, 0
        _G.GetTime = function() return now end
        _G.C_DamageMeter = { GetCombatSessionFromType = function()
            return { combatSources = { { sourceGUID = "G1", totalAmount = total } } } end }
        DM.StartHistory()
        for i = 1, 11 do now = 100 + i ; total = total + 50 ; DM.Sample() end
        local rates, dur = DM.Rates("G1", "DamageDone", 5)
        assert(rates and #rates == 5 and dur == 11 and math.abs(rates[3] - 50) < 1, "Verlauf je Sekunde falsch")
        local oldSecret = _G.issecretvalue
        _G.issecretvalue = function(v) return type(v) == "table" and getmetatable(v) ~= nil end
        _G.C_DamageMeter.GetCombatSessionFromType = function()
            return { combatSources = { { sourceGUID = "G2", totalAmount = setmetatable({}, {}) } } } end
        DM.Sample()
        assert(DM.History().secret and DM.Rates("G2", "DamageDone", 5) == nil, "mit geheimer Zahl gerechnet")
        -- 6.6.2.3: geheime Summen werden trotzdem gemerkt und als Summe
        -- ueber den Kampf gezeichnet (Balken des Spiels nehmen sie).
        local sums, last = DM.Cumulative("G2", "DamageDone", 5)
        assert(sums and #sums == 5 and type(last) == "table" and sums[5] == last, "geheime Summe nicht gemerkt")
        local h, note = DM.DrawSums(sums, last, 12)
        assert(h > 0 and note:find("verdeckt", 1, true) and DM.Breakdown().sums[5]:IsShown(), "Summe nicht gezeichnet")
        DM.StopHistory()
        _G.issecretvalue = oldSecret

        -- Auren merken: nur ausserhalb des Kampfes, geheimer Stand zaehlt nicht.
        local oldUA, oldGUID, oldIC, oldExists = _G.C_UnitAuras, _G.UnitGUID, _G.InCombatLockdown, _G.UnitExists
        _G.UnitGUID = function(u) return u == "player" and "P1" or nil end
        _G.UnitExists = function() return true end
        _G.InCombatLockdown = function() return false end
        _G.C_UnitAuras = { GetAuraDataByIndex = function(_, i)
            if i == 1 then return { name = "Satt", icon = 136000, spellId = 19705, expirationTime = 900 } end
            if i == 2 then return { name = "Fläschchen", icon = 134806, spellId = 17628, expirationTime = 0 } end
        end }
        assert(DM.SnapAuras("player") and #DM.auras.P1.list == 2, "Auren nicht gemerkt")
        assert(DM.GroupUnit("raid3") and DM.GroupUnit("party1") and not DM.GroupUnit("nameplate2"), "Gruppeneinheit falsch")
        _G.InCombatLockdown = function() return true end
        DM.AuraChanged("player")
        _G.InCombatLockdown = function() return false end
        DM.auras.P1 = nil
        _G.C_UnitAuras, _G.UnitGUID, _G.InCombatLockdown, _G.UnitExists = oldUA, oldGUID, oldIC, oldExists
        _G.C_DamageMeter, _G.GetTime, _G.Enum = oldCDM, oldTime, oldEnum
    end)
    Check(ok, "Schadensanzeige: Aufschluesselung verschiebbar, Vergleich, Verlauf, Auren"
        .. (ok and "" or (": " .. tostring(err))))

    -- 6.6.2.1: Weltkarte im Stil der Oberflaeche - die Karte selbst bleibt;
    -- weicher Rand ums Modell im Charakterfenster.
    ok, err = pcall(function()
        local W = WeintCodex.UIWindows
        local function Tex(atlas, w, h)
            local t = stub.NewObject("Texture")
            t.GetAtlas = function() return atlas end
            t._width, t._height = w or 10, h or 10
            return t
        end
        assert(W.HidesAtlas("QuestLog-main-background") and W.HidesAtlas("gamepad-mapquestlog-bgtile-2k")
            and W.HidesAtlas("_UI-Frame-Metal-EdgeTop"), "Rahmen der Karte bleibt")
        assert(not W.HidesAtlas("QuestNormal") and not W.HidesAtlas("QuestTurnin"), "Questmarke ausgeblendet")
        local map = stub.NewObject("Frame", "WorldMapFrame")
        _G.WorldMapFrame = map
        map._width, map._height = 1000, 700
        local border, nine, over, canvas, nav, home = stub.NewObject("Frame"), stub.NewObject("Frame"),
            stub.NewObject("Frame"), stub.NewObject("Frame"), stub.NewObject("Frame"), stub.NewObject("Button")
        local edge, bgtile, tile = Tex("_UI-Frame-Metal-EdgeTop"), Tex("gamepad-mapquestlog-bgtile-2k", 900, 600),
            Tex(nil, 256, 256)
        nine.GetRegions = function() return edge end
        border.NineSlice = nine
        border.GetChildren = function() return nine end
        over.GetRegions = function() return bgtile end
        canvas.GetRegions = function() return tile end
        local normal = stub.NewObject("Texture")
        home.GetNormalTexture = function() return normal end
        nav.homeButton, nav.navList = home, { home }
        map.BorderFrame, map.OverscrollBG, map.ScrollContainer, map.NavBar = border, over, canvas, nav
        map.GetChildren = function() return border, over, canvas, nav end
        local d = W.SkinMap(map)
        assert(d and d.kachel, "Karte ohne Kachel")
        assert(edge:GetAlpha() == 0 and bgtile:GetAlpha() == 0, "Metallkante oder Pergament bleibt")
        assert(tile:GetAlpha() == 1, "Kartenkachel ausgeblendet")
        assert(normal:GetAlpha() == 0, "Holzknopf in der Leiste bleibt")
        W.Inner()
        assert(tile:GetAlpha() == 1, "Kartenkachel nach dem Takt ausgeblendet")
        -- 6.6.3.1: weicher Rand ueber der Karte, unter ihren Knoepfen; die
        -- Kacheln selbst bleiben unberuehrt.
        local o = W.softOverlay[canvas]
        assert(o and o.LEFT and o.RIGHT and o.TOP and o.BOTTOM and W.own[o.TOP], "kein weicher Rand um die Karte")
        canvas:SetFrameLevel(5)
        local pinBtn = stub.NewObject("Button")
        pinBtn:SetFrameLevel(40)
        map.overlayFrames = { pinBtn }
        assert(W.MapOverlayLevel(map) == 39, "Rand nicht direkt unter den Knoepfen der Karte")
        pinBtn:SetFrameLevel(5)
        assert(W.MapOverlayLevel(map) == 105, "Knoepfe unter der Karte: Rand nicht darueber")
        W.SoftMap(map)
        assert(W.softOverlay[canvas] == o and o._level == 105, "Rand doppelt angelegt oder Ebene nicht gesetzt")
        assert(table.concat(W.SoftReport(map), " "):find("Weicher Rand (Karte): Verlauf, Ebene 105", 1, true), "Bericht ohne Kartenrand")
        -- 6.6.3.2: die Kartenbilder selbst laufen aus (Maske am Ausschnitt);
        -- Marken (klein) bleiben, der dunkle Verlauf geht weg.
        local inner, layer = stub.NewObject("Frame"), stub.NewObject("Frame")
        local bigTile, pin, own0 = stub.NewObject("Texture"), stub.NewObject("Texture"), stub.NewObject("Texture")
        bigTile._width, bigTile._height = 256, 256
        pin._width, pin._height = 20, 20
        own0._width, own0._height = 300, 300
        layer.GetRegions = function() return bigTile, pin end
        inner.GetRegions = function() return own0 end
        inner.GetChildren = function() return layer end
        canvas.Child = inner
        W.SoftMap(map)
        assert(bigTile._masks and #bigTile._masks == 1, "Kachel ohne Maske")
        assert(not pin._masks, "Marke maskiert")
        assert(own0._masks and #own0._masks == 1, "Bild am Inhalt selbst ohne Maske")
        assert(not o:IsShown(), "dunkler Verlauf bleibt ueber der maskierten Karte")
        W.SoftMap(map)
        assert(#bigTile._masks == 1, "Maske doppelt")
        assert(table.concat(W.SoftReport(map), " "):find("Maske an 2 Bildern", 1, true), "Bericht ohne Maske")
        -- 6.8.0.8: die Questdetails liegen ueber dem rechten Teil der Karte -
        -- der weiche Rand endet vor ihnen, nicht unter ihnen.
        local mask = bigTile._masks[1]
        local br
        mask.SetPoint = function(_, p, _, _, x) if p == "BOTTOMRIGHT" then br = x end end
        canvas.GetRight = function() return 1000 end
        local qm, details = stub.NewObject("Frame"), stub.NewObject("Frame")
        qm.GetLeft = function() return 1000 end
        details.GetLeft = function() return 880 end
        -- Gemessen (6.8.0.8): die Details liegen unter .QuestsFrame.
        local qsF = stub.NewObject("Frame")
        qm.QuestsFrame, qsF.DetailsFrame = qsF, details
        map.QuestMapFrame = qm
        W.SoftMap(map)
        assert(br == -120 and W.mapMask.cut == 120, "Rand laeuft unter den Questdetails aus: " .. tostring(br))
        assert(table.concat(W.SoftReport(map), " "):find("rechts 120 px früher", 1, true), "Bericht ohne Tafel")
        details:Hide()
        W.SoftMap(map)
        assert(br == 0 and W.mapMask.cut == 0, "Rand bleibt verkuerzt ohne Details")
        assert(table.concat(W.SoftReport(map), " "):find("rechts bis zum Rand (Karte rechts 1000, Tafel links 1000)", 1, true),
            "Bericht ohne Messung: " .. table.concat(W.SoftReport(map), " "))
        br = nil
        W.SoftMap(map)
        assert(br == nil, "Maske in jedem Durchlauf neu verankert")
        map.QuestMapFrame = nil
        canvas.GetRight = nil
        canvas.Child = nil
        _G.WorldMapFrame = nil

        local cf = stub.NewObject("Frame")
        local scene = stub.NewObject("Frame")
        local race = Tex("UI-Character-Info-Human-RaceBG", 230, 330)
        race.GetParent = function() return scene end
        scene.GetRegions = function() return race end
        cf.GetChildren = function() return scene end
        local hosts = W.SoftenModel(cf)
        local e = W.soft[scene]
        assert(#hosts == 1 and hosts[1] == scene and e and e.mask, "kein weicher Rand um das Modell")
        assert(race:GetAlpha() == 1, "Hintergrund des Modells ausgeblendet")
        -- 6.6.2.5: das Bild selbst laeuft aus (Maske), statt dass ein
        -- Verlauf nach Fast-Schwarz auf fast schwarzem Bild liegt.
        assert(race._masks and race._masks[1] == e.mask and e.count == 1, "Maske nicht am Hintergrundbild")
        -- Ein Bild, das das Spiel spaeter anlegt, bekommt sie beim naechsten Durchlauf - einmal.
        local late = Tex("UI-Character-Info-Human-RaceBG", 230, 330)
        scene.GetRegions = function() return race, late, e.mask end
        assert(W.SoftenModel(cf) == hosts, "Rand zweimal gesucht")
        W.SoftenModel(cf)
        assert(#race._masks == 1 and late._masks and #late._masks == 1 and e.count == 2, "Maske doppelt oder fehlt")
        local report = table.concat(W.SoftReport(cf), "\n")
        assert(report:find("Maske an 2 Bildern", 1, true) and report:find("Darunter: UI-Character-Info-Human-RaceBG", 1, true),
            "Bericht ohne Maske: " .. report)
        -- 6.6.4.0: Charakterfenster als eigenes System (ui/character.lua).
        local CS = WeintCodex.UICharacter
        -- Thema: DEFAULT fuer jede Klasse ohne Eintrag, PRIEST darueber.
        local paladin, priest = WeintCodex.ClassTheme("KEINEKLASSE"), WeintCodex.ClassTheme("PRIEST")
        assert(paladin.art == nil and paladin.gameOverlay == true and paladin.glass == WeintCodex.ClassThemes.DEFAULT.glass,
            "Klasse ohne Thema faellt nicht auf DEFAULT zurueck")
        assert(priest.art and priest.art.file == "classes/priest" and priest.gameOverlay == false
            and priest.glass == WeintCodex.ClassThemes.DEFAULT.glass and priest.light.ambient,
            "Priester-Thema nicht ueber DEFAULT gelegt")
        assert(WeintCodex.ClassTheme(nil).class == "DEFAULT", "ohne Klasse kein DEFAULT")
        -- Klasse ohne Eintrag (seit 6.6.4.5 hat jede der neun einen): Szene des Spiels bleibt, dasselbe Geruest.
        local wScene = CS.Scene(e, scene, paladin)
        CS.KeepScene(e)
        assert(not wScene.art and race:GetAlpha() == 1 and wScene.vignette and wScene.vignette.TOP._masks,
            "Paladin: Buehne des Spiels nicht behalten oder keine Vignette")

        local cf2, scene2 = stub.NewObject("Frame"), stub.NewObject("Frame")
        local race2 = Tex("UI-Character-Info-RaceBG-Overlay", 230, 330)
        race2.GetParent = function() return scene2 end
        scene2.GetRegions = function() return race2 end
        cf2.GetChildren = function() return scene2 end
        local made = {}
        local create = scene2.CreateTexture
        scene2.CreateTexture = function(self, ...)
            local t = create(self, ...)
            t.SetTexture = function(tt, file) tt._file = file end
            t.SetTexCoord = function(tt, ...) tt._coord = { ... } end
            made[#made + 1] = t
            return t
        end
        scene2._width, scene2._height = 397, 464
        local amb, sets = { 1, 1, 1 }, 0
        scene2.SetLightAmbientColor = function(_, r, g, b) amb = { r, g, b } sets = sets + 1 end
        scene2.GetLightAmbientColor = function() return amb[1], amb[2], amb[3] end
        scene2:SetFrameLevel(10)
        local slotF = stub.NewObject("Button")
        slotF:SetFrameLevel(15)
        local oldSlot = _G.CharacterHeadSlot
        _G.CharacterHeadSlot = slotF
        W.SoftenModel(cf2)
        local e2 = W.soft[scene2]
        local s2 = CS.Scene(e2, scene2, priest)
        local m = CS.Light(e2, scene2, priest)
        CS.KeepScene(e2)
        CS.KeepLight(e2)
        local art = s2.art
        assert(art and W.own[art], "Priester ohne Szene")
        assert(art._file == "Interface\\AddOns\\WeintCodex\\media\\classes\\priest", "falscher Pfad: " .. tostring(art._file))
        local layer, sub = art:GetDrawLayer()
        assert(layer == "BACKGROUND" and sub == 7 and art._masks[1] == e2.mask, "Szene falsch geschichtet oder ohne Maske")
        assert(art._coord and art._coord[1] == 0 and art._coord[2] == 1 and art._coord[3] > 0 and art._coord[4] < 1,
            "Ausschnitt verzerrt oder fehlt")
        assert(race2:GetAlpha() == 0, "Abdunklung des Spiels bleibt ueber dem eigenen Bild")
        race2:SetAlpha(1)
        CS.KeepScene(e2)
        assert(race2:GetAlpha() == 0, "Abdunklung kommt nach dem Zuruecksetzen wieder")
        assert(s2.calm and select(2, s2.calm:GetDrawLayer()) == 2 and s2.calm._masks, "keine Ruhe hinter der Figur")
        local count = #made
        CS.Scene(e2, scene2, priest)
        CS.Light(e2, scene2, priest)
        assert(#made == count, "Szene doppelt angelegt")
        -- Licht: einmal, und nur nach einem Zuruecksetzen erneut.
        local L = priest.light
        assert(m.scene == scene2 and amb[1] == L.ambient[1] and amb[3] == L.ambient[3], "Licht der Szene nicht gesetzt")
        local setsNow = sets
        CS.KeepLight(e2)
        assert(sets == setsNow, "Licht in jedem Durchlauf neu gesetzt")
        amb = { 1, 1, 1 }
        CS.KeepLight(e2)
        assert(sets == setsNow + 1 and amb[2] == L.ambient[2], "Licht nach Zuruecksetzen nicht erneuert")
        assert(m.shadow and select(2, m.shadow:GetDrawLayer()) == 3 and m.shadow._masks, "Schatten fehlt")
        assert(m.over and m.over:GetFrameLevel() == 11 and m.over:IsShown() and m.haze._masks and m.wash._masks,
            "Schicht ueber der Figur nicht direkt ueber dem Modell")
        slotF:SetFrameLevel(11)
        CS.KeepLight(e2)
        assert(not m.over:IsShown(), "Dunst liegt ueber den Ausruestungsplaetzen")
        slotF:SetFrameLevel(15)
        CS.KeepLight(e2)
        assert(m.over:IsShown(), "Schicht kommt nicht zurueck")
        local srep = table.concat(W.SoftReport(cf2), " ")
        assert(srep:find("Szene: classes/priest, Abdunklung des Spiels aus", 1, true) and srep:find("Licht: an der Szene", 1, true),
            "Bericht ohne Szene/Licht: " .. srep)
        _G.CharacterHeadSlot = oldSlot
        -- 6.6.4.4: Jaeger - dasselbe Geruest, eigenes Bild und Licht.
        local hunter = WeintCodex.ClassTheme("HUNTER")
        assert(hunter.art and hunter.art.file == "classes/hunter" and hunter.gameOverlay == false
            and hunter.glass == WeintCodex.ClassThemes.DEFAULT.glass, "Jaeger-Thema nicht ueber DEFAULT gelegt")
        local cf3, scene3 = stub.NewObject("Frame"), stub.NewObject("Frame")
        local race3 = Tex("UI-Character-Info-RaceBG-Overlay", 230, 330)
        race3.GetParent = function() return scene3 end
        scene3.GetRegions = function() return race3 end
        cf3.GetChildren = function() return scene3 end
        local create3 = scene3.CreateTexture
        scene3.CreateTexture = function(self, ...)
            local t = create3(self, ...)
            t.SetTexture = function(tt, file) tt._file = file end
            t.SetTexCoord = function(tt, ...) tt._coord = { ... } end
            return t
        end
        scene3._width, scene3._height = 397, 464
        W.SoftenModel(cf3)
        local e3 = W.soft[scene3]
        e3.box._width, e3.box._height = 397, 464   -- Modellfeld wie im Spiel gemessen
        local s3 = CS.Scene(e3, scene3, hunter)
        CS.Light(e3, scene3, hunter)
        CS.KeepScene(e3)
        assert(s3.art and s3.art._file == "Interface\\AddOns\\WeintCodex\\media\\classes\\hunter",
            "Jaeger ohne sein Bild: " .. tostring(s3.art and s3.art._file))
        -- Querformat im hochkanten Feld: die BREITE wird beschnitten, die
        -- Hoehe bleibt ganz, der Ausschnitt um das Tor (focusX 0.44).
        local c3 = s3.art._coord
        assert(c3 and c3[1] > 0 and c3[2] < 1 and c3[3] == 0 and c3[4] == 1
            and math.abs((c3[1] + c3[2]) / 2 - 0.44) < 0.001, "Ausschnitt des Jaegers falsch")
        assert(s3.art._masks[1] == e3.mask and race3:GetAlpha() == 0 and s3.calm and e3.light.shadow,
            "Jaeger nicht wie der Priester eingebettet")
        -- Priester unveraendert (Stand 6.6.4.3).
        local P = WeintCodex.ClassTheme("PRIEST")
        assert(P.art.file == "classes/priest" and P.art.w == 1024 and P.art.h == 1536 and P.art.focusY == 0.55
            and P.art.dim == 0.9 and P.vignette == 0.60 and P.calm == 0.30 and P.shadow == 0.60 and P.haze == 0.40
            and P.light.ambient[1] == 0.58 and P.light.diffuse[1] == 0.95 and P.wash[4] == 0.04,
            "Priester-Thema veraendert")
        -- Gruen nur als Akzent: mit der Jaegerfarbe als Akzent bleiben
        -- Basis und Glas neutral (r = g = b), der Lichthauch unter 5 %.
        local GCs = WeintCodex.GameColors
        local base0, glass0 = { unpack(GCs.showcaseBase) }, { unpack(GCs.showcaseGlass) }
        local hc = _G.RAID_CLASS_COLORS.HUNTER
        WeintCodex.SetAccent(hc.r, hc.g, hc.b)
        local acc = WeintCodex.UIKit.Highlight()
        assert(math.abs(acc[1] - hc.r) < 0.01 and math.abs(acc[2] - hc.g) < 0.01, "Akzent nicht die Jaegerfarbe")
        for i = 1, 4 do
            assert(GCs.showcaseBase[i] == base0[i] and GCs.showcaseGlass[i] == glass0[i], "Klassenfarbe faerbt die Grundflaechen")
        end
        local function Neutral(c) return math.abs(c[1] - c[2]) < 0.01 and math.abs(c[2] - c[3]) < 0.01 end
        assert(Neutral(GCs.showcaseBase) and Neutral(GCs.showcaseGlass), "Grundflaechen nicht neutral")
        assert(hunter.wash[4] <= 0.05 and P.wash[4] <= 0.05, "Lichthauch zu stark")
        WeintCodex.UIKit.ResetHighlight()
        -- 6.6.4.5: Krieger, Druide, Magier, Schurke, Hexenmeister - jeder
        -- mit eigenem Bild und eigenem Licht, alle auf demselben Geruest.
        for _, token in ipairs({ "WARRIOR", "DRUID", "MAGE", "ROGUE", "WARLOCK", "PALADIN", "SHAMAN" }) do
            local t = WeintCodex.ClassTheme(token)
            assert(t.art and t.art.file == "classes/" .. token:lower() and t.art.w == 1496 and t.art.h == 1051,
                token .. ": falsches Bild")
            assert(t.gameOverlay == false and t.light and t.light.ambient and t.wash and t.wash[4] <= 0.05
                and t.glass == WeintCodex.ClassThemes.DEFAULT.glass, token .. ": Thema nicht wie Priester/Jaeger")
        end
        assert(WeintCodex.ClassTheme("KEINEKLASSE").art == nil and WeintCodex.ClassTheme(nil).art == nil,
            "Klasse ohne Eintrag faellt nicht auf das Spiel zurueck")
        -- Paladin: ohne Licht keine Schicht.
        local wLight = CS.Light(e, scene, paladin)
        assert(wLight.theme.light == nil and wLight.over, "Paladin: Dunst des DEFAULT fehlt")

        -- Kopfbereich: HOLY LARENA / PRIESTERIN · STUFE 13, Titel und
        -- Stufenzeile des Spiels unsichtbar, solange er zu sehen ist.
        local sp = WeintCodex.Spaced
        assert(CS.IdentityLine("Priesterin", 13) == sp("PRIESTERIN · STUFE 13"), "Kopfzeile falsch")
        assert(CS.IdentityLine(nil, 13) == sp("STUFE 13") and CS.IdentityLine("Magier", nil) == sp("MAGIER"), "Teilwissen verloren")
        assert(CS.IdentityLine(nil, nil) == nil and CS.IdentityLine("", 0) == nil, "Kopfzeile ohne Wissen")
        assert(CS.NameLine("Holy Larena") == "HOLY LARENA" and CS.NameLine("") == nil, "Name nicht versal")
        local oldClass = _G.UnitClass
        _G.UnitClass = function() return "Priesterin", "PRIEST" end
        local charF, paper = stub.NewObject("Frame"), stub.NewObject("Frame")
        local titleText = WeintCodex.UIKit.NewText(charF, 13)
        -- 6.6.4.3: der Fenstertitel ist NICHT der Name - vom PvP-Reiter
        -- zurueck stand "Spieler gegen Spieler" darin (Beta-Test).
        titleText:SetText("Spieler gegen Spieler")
        local oldPvp = _G.UnitPVPName
        _G.UnitPVPName = function() return "Holy Larena" end
        charF.TitleContainer = { TitleText = titleText }
        local lvlText = WeintCodex.UIKit.NewText(paper, 10)
        local oldPaper, oldHead, oldLvl = _G.PaperDollFrame, CS.head, _G.CharacterLevelText
        _G.PaperDollFrame, CS.head, _G.CharacterLevelText = paper, nil, lvlText
        local oldLvlAlpha = lvlText:GetAlpha()
        lvlText:SetAlpha(1)
        local head = CS.Header(charF)
        assert(head and head:GetParent() == paper, "Kopfzeile nicht am Reiter Charakter")
        assert(head.name:GetText() == "HOLY LARENA" and head.sub:GetText() == sp("PRIESTERIN · STUFE 60"),
            "Kopfzeile: " .. tostring(head.name:GetText()) .. " / " .. tostring(head.sub:GetText()))
        assert(titleText:GetAlpha() == 0 and lvlText:GetAlpha() == 0, "Name/Stufe doppelt (Titel des Spiels sichtbar)")
        head:Show()
        titleText:SetAlpha(1)   -- das Spiel setzt den Titel neu
        CS.KeepHeader(head, nil)
        assert(titleText:GetAlpha() == 0, "Titel des Spiels kommt zurueck")
        head:GetScript("OnHide")()
        assert(titleText:GetAlpha() == 1 and lvlText:GetAlpha() == 1, "Titel auf anderen Reitern weg")
        assert(CS.Header(charF) == head, "Kopfzeile doppelt")
        head.Update(61)
        assert(head.sub:GetText() == sp("PRIESTERIN · STUFE 61"), "Stufenaufstieg nicht uebernommen")
        -- 6.6.4.1: die doppelte Stufenzeile am Inhalt finden, samt grauer
        -- Flaeche ihres Traegers.
        local holder = stub.NewObject("Frame")
        local dupText = WeintCodex.UIKit.NewText(holder, 12)
        dupText:SetText("Stufe 60, Priesterin")
        local greyBg, smallIcon = stub.NewObject("Texture"), stub.NewObject("Texture")
        greyBg._width, greyBg._height, smallIcon._width, smallIcon._height = 200, 40, 20, 20
        local hiddenDecor = stub.NewObject("Texture")
        hiddenDecor:SetAlpha(0)   -- vom Fensterstil schon ausgeblendet
        holder.GetRegions = function() return dupText, greyBg, smallIcon end
        dupText.GetParent = function() return holder end
        paper.GetChildren = function() return holder end
        head:Show()
        CS.KeepHeader(head, nil)
        assert(CS.dup == dupText and dupText:GetAlpha() == 0, "doppelte Stufenzeile bleibt")
        -- 6.6.4.3: nur die Zeile - die Bilder ihres Traegers bleiben.
        assert(greyBg:GetAlpha() == 1 and smallIcon:GetAlpha() == 1, "Erkennung zu breit: Bilder des Traegers ausgeblendet")
        -- Zurueck geht es auf die Deckkraft von vorher, nicht auf 1.
        local hr = head.replaced
        hr[#hr + 1] = hiddenDecor
        head.orig[hiddenDecor] = 0
        head:GetScript("OnHide")()
        assert(dupText:GetAlpha() == 1 and hiddenDecor:GetAlpha() == 0, "Zuruecksetzen zeigt Ausgeblendetes wieder")
        hr[#hr] = nil
        local oldCF = _G.CharacterFrame
        _G.CharacterFrame = charF
        local repOut = {}
        CS.ReportFrame(charF, repOut)
        _G.CharacterFrame = oldCF
        local rep = table.concat(repOut, " ")
        assert(rep:find("Ersetzt: ", 1, true) and rep:find("„Stufe 60, Priesterin“", 1, true), "Bericht ohne ersetzte Zeilen: " .. rep)
        local oldScene = _G.CharacterModelScene
        _G.CharacterModelScene = stub.NewObject("Frame")
        _G.CharacterModelScene:SetFrameLevel(40)
        CS.KeepHeader(head, nil)
        assert(head:GetFrameLevel() == 43, "Kopfzeile unter der Figur")
        _G.CharacterModelScene = oldScene
        _G.PaperDollFrame, CS.head, _G.CharacterLevelText = oldPaper, oldHead, oldLvl
        _G.UnitClass, _G.UnitPVPName = oldClass, oldPvp
        lvlText:SetAlpha(oldLvlAlpha)

        -- Layout: dunkle Basis, keine grauen Innenflaechen, Glas rechts,
        -- das dem rechten Bereich folgt.
        local win = stub.NewObject("Frame")
        local insetR = stub.NewObject("Frame")
        win.InsetRight = insetR
        local d = W.Skin(win)
        assert(d and d.InsetRight, "Innenflaeche nicht gefunden")
        local Lay = CS.Layout(win, d, priest)
        assert(Lay.base and d.InsetRight:GetAlpha() == 0, "Basis/Innenflaeche nicht umgestellt")
        -- 6.6.4.2: der Schein ist versteckt und bleibt es, auch wenn ihn
        -- etwas wieder zeigt (Beta-Test: graue Flaeche oben rechts).
        d.glow = d.glow or win:CreateTexture()
        d.glow:Show()
        CS.Layout(win, d, priest)
        assert(CS.TOP_GLOW == 0 and not d.glow:IsShown(), "Schein der Klasse faerbt weiter das Fenster")
        d.glow:Show()
        CS.Layout(win, d, priest)
        assert(not d.glow:IsShown(), "Schein kommt zurueck")
        assert(Lay.glass and Lay.glass.name == "InsetRight" and Lay.glass.shown == true and W.own[Lay.glass.body],
            "keine Glasebene rechts")
        insetR:Hide()
        CS.Layout(win, d, priest)
        assert(Lay.glass.shown == false and not Lay.glass.body:IsShown(), "Glas bleibt bei eingeklapptem Bereich")
        insetR:Show()
        CS.Layout(win, d, priest)
        assert(Lay.glass.body:IsShown(), "Glas kommt nicht zurueck")
        -- Ohne Innenflaeche: der erste SICHTBARE Kandidat - in diesem
        -- Client die ScrollBox der Werte, nicht der unsichtbare Pane.
        local win2 = stub.NewObject("Frame")
        local oldSB, oldPane = _G.CharacterStatsPaneScrollBox, _G.CharacterStatsPane
        _G.CharacterStatsPane, _G.CharacterStatsPaneScrollBox = stub.NewObject("Frame"), stub.NewObject("Frame")
        _G.CharacterStatsPane:Hide()
        local rp, rn = CS.RightPane(win2)
        assert(rp == _G.CharacterStatsPaneScrollBox and rn == "CharacterStatsPaneScrollBox", "Glas am unsichtbaren Pane: " .. tostring(rn))
        _G.CharacterStatsPaneScrollBox:Hide()
        local _, rn2 = CS.RightPane(win2)
        assert(rn2 == "CharacterStatsPaneScrollBox", "ohne Sichtbares nicht der erste vorhandene")
        _G.CharacterStatsPaneScrollBox, _G.CharacterStatsPane = oldSB, oldPane
        -- Titel des Spiels auch unter <Name>TitleText / .TitleText.
        local named = stub.NewObject("Frame")
        local tt = WeintCodex.UIKit.NewText(named, 12)
        named.TitleText = tt
        assert(CS.Title(named) == tt, "Titel an .TitleText nicht gefunden")

        -- Werte: Namen ruhig statt gold, einmal.
        local label = WeintCodex.UIKit.NewText(win, 11)
        local colored = 0
        label.SetTextColor = function(_, r) colored = colored + 1 label._r = r end
        W.StatLabels[#W.StatLabels + 1] = label
        CS.Info()
        CS.Info()
        assert(colored == 1 and label._r == WeintCodex.Colors.textMuted[1], "Namen der Werte nicht ruhig oder mehrfach")

        -- Ausruestung: leer neutral und gedaempft, belegt im Akzent (halb),
        -- Maus im Akzent (voll).
        local slot = stub.NewObject("Button")
        slot.GetID = function() return 1 end
        slot.icon = stub.NewObject("Texture")
        local bcol
        local border = { SetColor = function(_, r, g, b, a) bcol = { r, g, b, a } end }
        W.SlotList[#W.SlotList + 1] = slot
        W.SlotBorder[slot] = border
        local oldInv = _G.GetInventoryItemTexture
        local worn = nil
        _G.GetInventoryItemTexture = function() return worn end
        CS.Slots()
        local acc = WeintCodex.UIKit.Highlight()
        assert(CS.slotState[slot].state == "empty" and bcol[1] == 0 and bcol[4] == 1 and slot.icon:GetAlpha() == CS.SLOT_EMPTY_ICON,
            "leerer Platz nicht neutral")
        worn = 12345
        CS.Slots()
        assert(CS.slotState[slot].state == "filled" and bcol[1] == acc[1] and bcol[4] == CS.SLOT_FILLED and slot.icon:GetAlpha() == 1,
            "belegter Platz nicht im Akzent")
        slot:GetScript("OnLeave")   -- vorhanden
        slot._scripts.OnEnter()
        assert(bcol[4] == 1 and CS.slotState[slot].state == "hover", "Maus ohne vollen Akzent")
        CS.Slots()
        assert(CS.slotState[slot].state == "hover", "Durchlauf ueberschreibt die Maus")
        slot._scripts.OnLeave()
        assert(CS.slotState[slot].state == "filled" and bcol[4] == CS.SLOT_FILLED, "nach der Maus nicht zurueck")
        _G.GetInventoryItemTexture = oldInv
        table.remove(W.SlotList)
        table.remove(W.StatLabels)
    end)
    -- Berufe und Gilde & Communitys (6.6.2.1).
    local ok2, err2 = pcall(function()
        local W = WeintCodex.UIWindows
        local function Tex(atlas)
            local t = stub.NewObject("Texture")
            t.GetAtlas = function() return atlas end
            t._width, t._height = 10, 10
            return t
        end
        for _, a in ipairs({ "!UI-Frame-Metal-EdgeLeft", "UI-Frame-Metal-CornerBottomLeft", "_UI-Frame-Metal-EdgeBottom",
                             "Profession-ProgressBar-frame", "Profession-square-frame", "Profession-Background-Overview" }) do
            assert(W.HidesAtlas(a), "bleibt sichtbar: " .. a)
        end
        -- 6.7.6.0: Karten und Bilder der Uebersicht weg (standen hinter Text).
        assert(W.HidesAtlas("Profession-overview-card-generic-Fishing") and W.HidesAtlas("Profession-overview-Card")
            and not W.TonesAtlas("Profession-overview-card-generic-Fishing"), "Berufskarte bleibt hinter dem Text")
        assert(not W.IsDark(1, 0.1, 0.1), "rote Schrift (fehlt) wird hell")
        assert(W.WantsLarge("ProfessionsFrame"), "Berufe ohne gedaempfte Bilder")
        -- Seitenreiter: Goldrahmen weg, Kachel, gewaehlter im Akzent.
        local win = stub.NewObject("Frame")
        local tab1, tab2 = stub.NewObject("CheckButton"), stub.NewObject("CheckButton")
        local gold1, gold2 = Tex("common-sidetab"), Tex("common-sidetab")
        tab1.GetRegions = function() return gold1 end
        tab2.GetRegions = function() return gold2 end
        tab1.GetChecked = function() return true end
        tab2.GetChecked = function() return false end
        win.GetChildren = function() return tab1, tab2 end
        W.SkinSideTabs(win)
        assert(gold1:GetAlpha() == 0 and W.SideTabs[tab1] and W.SideTabs[tab2], "Seitenreiter nicht gestaltet")
        assert(W.SideTabs[tab1].on == true and W.SideTabs[tab2].on == false, "gewaehlter Reiter nicht erkannt")
        -- 6.6.2.2: tragen ALLE das Zeichen, trennt es nichts - dann keiner
        -- (Beta-Test: alle vier im Akzent). Heller Rahmen trennt eindeutig.
        tab2.GetChecked = function() return true end
        gold1.GetVertexColor = function() return 1, 1, 1 end
        gold2.GetVertexColor = function() return 1, 1, 1 end
        W.SkinSideTabs(win)
        assert(not W.SideTabs[tab1].on and not W.SideTabs[tab2].on, "alle Reiter gewaehlt")
        gold2.GetVertexColor = function() return 0.5, 0.5, 0.5 end
        W.SkinSideTabs(win)
        assert(W.SideTabs[tab1].on and not W.SideTabs[tab2].on and W.SideTabs[tab1].why == "frameLight",
            "hellerer Rahmen entscheidet nicht")
        -- 6.7.5.0: der gewaehlte Reiter traegt den Akzent seines Fensters -
        -- ohne Stil die Klassenfarbe, im Berufsfenster (S.CALM) Gold.
        local S = WeintCodex.UIStyle
        assert(W.SideTabs[tab1].accent == K.Highlight(), "Seitenreiter ohne Stil nicht in der Klassenfarbe")
        S.Scope(win, S.CALM)
        W.SkinSideTabs(win)
        assert(W.SideTabs[tab1].accent == WeintCodex.GameColors.frameAccent, "Seitenreiter im Berufsfenster nicht in Gold")
        S.Scope(win, nil)
        W.SkinSideTabs(win)
        assert(W.SideTabs[tab1].accent == K.Highlight(), "Seitenreiter bleibt Gold ohne Stil")
        local rep = W.SideTabReport(win)
        assert(#rep == 2 and rep[1]:find("GEWÄHLT", 1, true), "Bericht der Seitenreiter fehlt")
        for _, a in ipairs({ "groupfinder-button-cover-hover", "groupfinder-background", "UI-Frame-PortraitMetal-CornerTopLeft",
                             "_UI-Frame-TopTileStreaks", "common-search-border-middle", "MapCornerShadow-Right" }) do
            assert(W.HidesAtlas(a), "bleibt sichtbar: " .. a)
        end
        assert(W.TonesAtlas("groupfinder-button-questing") and not W.TonesAtlas("groupfinder-button-cover"),
            "Kategoriebild weg statt gedaempft")
        assert(not W.HidesAtlas("UI-LFG-RoleIcon-DPS") and not W.HidesAtlas("UI-QuestPoi-QuestNumber"), "Symbol ausgeblendet")
        assert(W.Desaturates("QuestCollapse-Hide-Up"), "brauner Pfeilknopf bleibt braun")
        -- Communitys: Reiter ueber ihren Namen, Innenflaechen tiefer im Fenster.
        local comm = stub.NewObject("Frame")
        local chatTab, bg = stub.NewObject("CheckButton"), stub.NewObject("Texture")
        chatTab.Background = bg
        comm.ChatTab = chatTab
        local list, inset, nine = stub.NewObject("Frame"), stub.NewObject("Frame"), stub.NewObject("Frame")
        local edge = Tex("UI-Frame-InnerTopLeft")
        nine.GetRegions = function() return edge end
        inset.NineSlice = nine
        list.InsetFrame = inset
        comm.GetChildren = function() return list end
        W.SkinSideTabs(comm)
        W.SkinInsets(comm)
        assert(bg:GetAlpha() == 0 and W.SideTabs[chatTab], "Chat-Reiter der Communitys nicht gestaltet")
        assert(W.Insets[inset] and edge:GetAlpha() == 0, "Innenflaeche der Communitys nicht gestaltet")
        -- 6.6.3.3: die Mitgliederliste bleibt, wie das Spiel sie zeichnet.
        local members, mInset = stub.NewObject("Frame"), stub.NewObject("Frame")
        local mBg = stub.NewObject("Texture")
        mInset.Bg = mBg
        members.InsetFrame = mInset
        comm.MemberList = members
        comm.GetChildren = function() return list, members end
        W.SkinInsets(comm)
        assert(not W.Insets[mInset] and mBg:GetAlpha() == 1, "Mitgliederliste verdunkelt")
        comm.MemberList = nil
        -- 6.6.2.3: Liste links - Eintraege als Kachel, gewaehlter im Akzent;
        -- das Wappen oben links bleibt.
        assert(W.HidesAtlas("communities-nav-button-green-normal") and not W.HidesAtlas("communities-guildbanner-background"),
            "Eintrag bleibt gruen oder Wappen im Eintrag weg")
        local entry = stub.NewObject("Button")
        local normal, pressed = Tex("communities-nav-button-green-normal"), Tex("communities-nav-button-green-pressed")
        pressed.IsShown = function() return true end
        entry.GetRegions = function() return normal, pressed end
        W.HideByAtlas(entry)
        assert(normal:GetAlpha() == 0 and W.Entries[entry] and W.Entries[entry].on, "gewaehlter Eintrag nicht markiert")
        pressed.IsShown = function() return false end
        W.Inner()   -- neuer Durchlauf
        W.HideByAtlas(entry)
        assert(not W.Entries[entry].on, "Markierung bleibt nach dem Abwaehlen")
        local cframe = stub.NewObject("Frame")
        local portrait = stub.NewObject("Frame")
        local emblem = stub.NewObject("Texture")
        portrait.GetRegions = function() return emblem end
        cframe.PortraitOverlay = portrait
        W.Skin(cframe)
        assert(emblem:GetAlpha() == 1, "Gildenwappen ausgeblendet")
        -- Weicher Rand an den Kanten des Bildes, nicht des Traegers.
        local a1, a2 = stub.NewObject("Texture"), stub.NewObject("Texture")
        a1.GetLeft, a1.GetRight, a1.GetTop, a1.GetBottom = function() return 10 end, function() return 110 end, function() return 300 end, function() return 150 end
        a2.GetLeft, a2.GetRight, a2.GetTop, a2.GetBottom = function() return 10 end, function() return 200 end, function() return 150 end, function() return 20 end
        local L, R, T, B = W.Bounds({ a1, a2 })
        assert(L == 10 and R == 200 and T == 300 and B == 20, "Kanten des Bildes falsch")
        assert(W.Bounds({ stub.NewObject("Texture") }) == nil, "Lage geraten")
    end)
    Check(ok2, "Berufe und Gilde & Communitys: Metall, Goldrahmen, Seitenreiter, Innenflaechen"
        .. (ok2 and "" or (": " .. tostring(err2))))

    -- 6.6.2.6: der Takt der Fenster legt keinen Muell an und fasst nur
    -- offene Fenster an (Beta-Test: Speicher Richtung 40 MB, Ruckler).
    local ok6, err6 = pcall(function()
        local W = WeintCodex.UIWindows
        local function Build(name)
            local root = stub.NewObject("Frame", name)
            local function Fill(f, depth)
                local regs = {}
                for i = 1, 6 do
                    local t = stub.NewObject("Texture")
                    local atlas = (i == 1) and "UI-Frame-Metal-EdgeTop" or ("plain-" .. i)
                    t.GetAtlas = function() return atlas end
                    regs[#regs + 1] = t
                end
                regs[#regs + 1] = stub.NewObject("FontString")
                f.GetRegions = function() return unpack(regs) end
                local kids = {}
                if depth < 3 then
                    for i = 1, 4 do
                        local ch = stub.NewObject("Frame")
                        Fill(ch, depth + 1)
                        kids[#kids + 1] = ch
                    end
                end
                f.GetChildren = function() return unpack(kids) end
            end
            Fill(root, 0)
            return root
        end
        local open, shut = Build("WCTestOpenFrame"), Build("WCTestShutFrame")
        _G.WCTestOpenFrame, _G.WCTestShutFrame = open, shut
        shut:Hide()
        table.insert(W.WINDOWS, "WCTestOpenFrame")
        table.insert(W.WINDOWS, "WCTestShutFrame")
        W.done[open], W.done[shut] = {}, {}
        -- Geschlossen: nichts angefasst.
        local asked = 0
        local g = shut.GetChildren
        shut.GetChildren = function(...) asked = asked + 1 return g(...) end
        for _ = 1, 3 do W.Inner() end   -- Listen und Merker anlegen
        assert(asked == 0, "geschlossenes Fenster durchlaufen")
        collectgarbage("collect")
        collectgarbage("stop")
        local k0 = collectgarbage("count")
        for _ = 1, 20 do W.Inner() end
        local grew = collectgarbage("count") - k0
        collectgarbage("restart")
        table.remove(W.WINDOWS) table.remove(W.WINDOWS)
        W.done[open], W.done[shut] = nil, nil
        _G.WCTestOpenFrame, _G.WCTestShutFrame = nil, nil
        print(string.format("    (20 Durchlaeufe ueber 85 Rahmen, 595 Flaechen: %.1f KB)", grew))
        assert(grew < 64, string.format("Takt legt Muell an: %.1f KB in 20 Durchlaeufen", grew))
        -- 6.6.4.0: auch das Charakterfenster legt im Durchlauf nichts an.
        do
            local CS = WeintCodex.UICharacter
            local cfA, hostA, inset = stub.NewObject("Frame"), stub.NewObject("Frame"), stub.NewObject("Frame")
            local bg = stub.NewObject("Texture")
            bg.GetAtlas = function() return "UI-Character-Info-RaceBG-Overlay" end
            bg._width, bg._height = 397, 464
            bg.GetParent = function() return hostA end
            hostA.GetRegions = function() return bg end
            cfA.GetChildren = function() return hostA end
            cfA.InsetRight = inset
            local slotA = stub.NewObject("Button")
            slotA.GetID = function() return 1 end
            W.SlotList[#W.SlotList + 1] = slotA
            local oldP, oldH = _G.PaperDollFrame, CS.head
            _G.PaperDollFrame, CS.head = stub.NewObject("Frame"), nil
            local dA = W.Skin(cfA)
            for _ = 1, 3 do CS.Update(cfA, dA) end
            collectgarbage("collect")
            collectgarbage("stop")
            local c0 = collectgarbage("count")
            for _ = 1, 20 do CS.Update(cfA, dA) end
            local cgrew = collectgarbage("count") - c0
            collectgarbage("restart")
            table.remove(W.SlotList)
            _G.PaperDollFrame, CS.head = oldP, oldH
            print(string.format("    (20 Durchlaeufe Charakterfenster: %.1f KB)", cgrew))
            assert(cgrew < 1, string.format("Charakterfenster legt im Takt Muell an: %.1f KB", cgrew))
        end
        -- Takt: schnell nach dem Wecken, danach langsam.
        local t = 100
        local oldGT = _G.GetTime
        _G.GetTime = function() return t end
        W.tick.last = -math.huge
        W.Wake()
        assert(W.Tick(), "erster Lauf nach dem Oeffnen fehlt")
        t = t + W.TICK_FAST / 2
        assert(not W.Tick(), "Takt zu schnell")
        t = t + W.TICK_FAST
        assert(W.Tick(), "schneller Takt nach dem Oeffnen fehlt")
        t = t + W.FAST_FOR + 0.1
        W.tick.last = t - W.TICK_FAST - 0.01
        assert(not W.Tick(), "nach der Ruhe weiter im schnellen Takt")
        t = t + W.TICK_SLOW
        assert(W.Tick(), "langsamer Takt fehlt")
        _G.GetTime = oldGT
    end)
    Check(ok6, "Fenster-Takt: nur offene Fenster, kein Muell, schnell nach dem Oeffnen, dann langsam"
        .. (ok6 and "" or (": " .. tostring(err6))))

    -- 6.6.2.7: Kategorien ("Allgemein", "Primaere Eigenschaften") als Band
    -- statt blanken Texts - erkannt am Holzbalken des Spiels.
    local ok7, err7 = pcall(function()
        local W = WeintCodex.UIWindows
        local pane, head = stub.NewObject("Frame"), stub.NewObject("Frame")
        local beam = stub.NewObject("Texture")
        beam.GetAtlas = function() return "UI-Character-Info-Title" end
        local title = stub.NewObject("FontString")
        title._text = "Allgemein"
        head.Title = title
        head.GetRegions = function() return beam, title end
        pane.GetChildren = function() return head end
        W.HideByAtlas(pane)
        local d = W.Headers[head]
        assert(beam:GetAlpha() == 0, "Holzbalken bleibt")
        -- 6.6.2.8: Zierlinie statt Block. 6.6.3.0: auffaelliger - Lichthof,
        -- Raute mit Kern, Punkt, Linie mit Schein je Seite.
        assert(d and d.l and d.r and d.halo and d.title == title and not d.band, "Kopfzeile ohne Zierlinie")
        for _, e in ipairs({ d.l, d.r }) do
            assert(e.line and e.glow and e.dot and e.hole and e.pip and W.own[e.line] and W.own[e.dot],
                "Seite der Zierlinie unvollstaendig")
        end
        assert(W.own[d.halo], "Lichthof als fremdes Bild behandelt")
        -- Zu langer Titel: kleiner, ohne Punkte.
        local long = stub.NewObject("Frame")
        local lbeam = stub.NewObject("Texture")
        lbeam.GetAtlas = function() return "UI-Character-Info-Title" end
        lbeam._width = 180
        local ltitle = stub.NewObject("FontString")
        ltitle._text = "Primäre Eigenschaften"
        local tw = 160
        ltitle.GetStringWidth = function() return tw end
        ltitle.SetFont = function(self, _, size) if size == W.HEADER_SIZE_SMALL then tw = 130 end return true end
        long.Title = ltitle
        long.GetRegions = function() return lbeam, ltitle end
        local ld = W.Header(long, lbeam)
        assert(ld.small and not ld.l.pip:IsShown(), "zu langer Titel ragt ueber die Spalte")
        local short = W.Headers[head]
        assert(not short.small, "kurzer Titel verkleinert")
        W.HideByAtlas(pane)
        assert(W.Headers[head] == d, "Band doppelt angelegt")
        assert(W.HeaderAtlas("UI-Character-Info-Title") and not W.HeaderAtlas("UI-Character-Info-StatTab"),
            "Kopfzeilen falsch erkannt")
        local report = table.concat(W.HeaderReport(), "\n")
        assert(report:find("Kategorien: ", 1, true) and report:find("Allgemein", 1, true), "Bericht ohne Kategorien: " .. report)
        -- 6.6.2.9: Ruf und Fertigkeiten (gemessen): Zeile der Liste mit
        -- zweimal "common-button-list-collapseExpand" und dem Minus-Zeichen.
        local list, row = stub.NewObject("Frame"), stub.NewObject("Button")
        local small, wide = stub.NewObject("Texture"), stub.NewObject("Texture")
        small.GetAtlas = function() return "common-button-list-collapseExpand" end
        wide.GetAtlas = function() return "common-button-list-collapseExpand" end
        small._width, wide._width = 20, 300
        local minus = stub.NewObject("Texture")
        minus.GetAtlas = function() return "common-button-list-minus" end
        local name = stub.NewObject("FontString")
        name._text = "Allianz"
        row.GetRegions = function() return small, wide, minus, name end
        list.GetChildren = function() return row end
        W.HideByAtlas(list)
        local rd = W.Headers[row]
        assert(small:GetAlpha() == 0 and wide:GetAlpha() == 0, "Grund der Ruf-Kopfzeile bleibt")
        assert(minus:GetAlpha() == 1, "Zeichen zum Auf- und Zuklappen ausgeblendet")
        assert(rd and rd.title == name and rd.icon == minus and rd.beam == wide and rd.hover,
            "Ruf-Kopfzeile nicht am breitesten Grund gestaltet")
        -- 6.9.0.0: rechte Linie bis vor das Zeichen nur links verankert,
        -- Breite gerechnet (das Zeichen liegt nicht auf der Hoehe des Titels).
        local rPts = {}
        local rsp = rd.r.line.SetPoint
        rd.r.line.SetPoint = function(self, p, ...) rPts[#rPts + 1] = p return rsp(self, p, ...) end
        name.GetRight, minus.GetLeft = function() return 150 end, function() return 280 end
        W.HideByAtlas(list)
        -- 280 - 6 - (150 + 8 + 19 - 6) = 103
        assert(rd.r.line:GetWidth() == 103 and rd.r.line:IsShown(), "rechte Linie: " .. tostring(rd.r.line:GetWidth()))
        -- Ein breiterer Grund legt neu an: auch dann nur "LEFT".
        local wider = stub.NewObject("Texture")
        wider._width = 400
        W.Header(row, wider)
        rd.r.line.SetPoint = rsp
        assert(#rPts > 0 and rd.beam == wider, "rechte Linie nicht neu gelegt")
        for _, p in ipairs(rPts) do assert(p == "LEFT", "rechte Linie an zweitem Punkt: " .. p) end
        assert(rd.r.line:GetWidth() == 103, "Breite nach neuem Grund verloren")
    end)
    -- 6.6.3.3: das Spielmenue (gemessen): Diamantmetall-Rahmen und Kopf
    -- weg, Kachel ohne Schatten nach aussen, rote Knoepfe flach.
    local ok8, err8 = pcall(function()
        local W = WeintCodex.UIWindows
        local function Tex(atlas)
            local t = stub.NewObject("Texture")
            t.GetAtlas = function() return atlas end
            return t
        end
        local menu = stub.NewObject("Frame", "GameMenuFrame")
        local border, header = stub.NewObject("Frame"), stub.NewObject("Frame")
        local edge, bgfile = Tex("!UI-Frame-DiamondMetal-EdgeLeft"), Tex(nil)
        border.GetRegions = function() return edge, bgfile end
        local hTile = Tex("_UI-Frame-DiamondMetal-Header-Tile")
        local hText = stub.NewObject("FontString")
        header.GetRegions = function() return hTile, hText end
        header.Text = hText
        local moved
        hText.SetPoint = function(_, point, rel) moved = point .. ":" .. tostring(rel == menu) end
        menu.Border, menu.Header = border, header
        local btn = stub.NewObject("Button")
        local left, center, glow = Tex("128-RedButton-Left"), Tex("_128-RedButton-Center"), Tex("128-RedButton-Highlight")
        btn.GetRegions = function() return left, center, glow end
        menu.GetChildren = function() return border, header, btn end
        local d = W.Skin(menu)
        assert(edge:GetAlpha() == 0 and bgfile:GetAlpha() == 0 and hTile:GetAlpha() == 0, "Diamantmetall bleibt")
        assert(d and d.kachel and not d.kachel.shadow, "Spielmenue mit Schatten ueber den Rand")
        assert(moved == "TOP:true", "Titel nicht in die Kachel gerueckt: " .. tostring(moved))
        W.HideByAtlas(menu)
        assert(left:GetAlpha() == 0 and center:GetAlpha() == 0 and glow:GetAlpha() == 0, "rote Knoepfe bleiben")
        assert(W.ButtonSkin[btn], "Knopf des Spielmenues nicht flach gestaltet")
        -- 6.6.3.3: Sammlung - Leder, Schatten, Ecken innen weg, Innenflaeche.
        local journal = stub.NewObject("Frame", "CollectionsJournal")
        local marble = stub.NewObject("Texture")
        journal.GetRegions = function() return marble end
        local items = stub.NewObject("Frame")
        local leather, corner = stub.NewObject("Texture"), Tex("collections-background-corner")
        items.GetRegions = function() return leather, corner end
        _G.WardrobeCollectionFrame = { ItemsCollectionFrame = items }
        _G.CollectionsJournal = journal
        W.Apply()
        assert(W.done[journal] and marble:GetAlpha() == 0, "Sammlung ohne Kachel oder Marmor bleibt")
        assert(leather:GetAlpha() == 0 and corner:GetAlpha() == 0 and W.OwnBgDone[items] and W.Insets[items],
            "Leder der Sammlung bleibt")
        assert(W.HidesAtlas("collections-background-shadow-large"), "Schatten der Sammlung bleibt")
        _G.WardrobeCollectionFrame, _G.CollectionsJournal = nil, nil
        local found = false
        for _, n in ipairs(W.WINDOWS) do if n == "GameMenuFrame" then found = true end end
        assert(found, "Spielmenue nicht in der Fensterliste")
    end)
    -- 6.6.3.4: Dialoge (StaticPopup, gemessen): Grund weg, Kachel ohne
    -- Schatten, Knoepfe flach; das Warnzeichen des Dialogs bleibt.
    local ok9, err9 = pcall(function()
        local W = WeintCodex.UIWindows
        local pop = stub.NewObject("Frame", "StaticPopup1")
        local bg = stub.NewObject("Frame")
        local border, dark = stub.NewObject("Texture"), stub.NewObject("Texture")
        border.GetAtlas = function() return "UI-DiamondDialogBox-Border" end
        dark.GetAtlas = function() return "UI-DialogBox-Background-Dark" end
        bg.GetRegions = function() return border, dark end
        pop.BG = bg
        local alert = stub.NewObject("Texture")
        pop.GetRegions = function() return alert end
        pop.GetChildren = function() return bg end
        local b1 = stub.NewObject("Button", "StaticPopup1Button1")
        local up, hl = stub.NewObject("Texture"), stub.NewObject("Texture")
        b1.GetNormalTexture = function() return up end
        b1.GetHighlightTexture = function() return hl end
        _G.StaticPopup1, _G.StaticPopup1Button1 = pop, b1
        W.Apply()
        local d = W.PopupDone[pop]
        assert(d and d.kachel and not d.kachel.shadow, "Dialog ohne Kachel oder mit Schatten")
        assert(border:GetAlpha() == 0 and dark:GetAlpha() == 0, "Rahmen/Grund des Dialogs bleibt")
        assert(alert:GetAlpha() == 1, "Warnzeichen des Dialogs ausgeblendet")
        assert(W.ButtonSkin[b1] and up:GetAlpha() == 0 and hl:GetAlpha() == 0, "roter Dialogknopf bleibt")
        W.Apply()
        assert(W.PopupDone[pop] == d, "Dialog doppelt gestaltet")
        _G.StaticPopup1, _G.StaticPopup1Button1 = nil, nil
    end)
    Check(ok9, "Dialoge: Kachel, Knoepfe flach, eigene Zeichen bleiben" .. (ok9 and "" or (": " .. tostring(err9))))
    Check(ok8, "Spielmenue: Rahmen und rote Knoepfe im WeintCodex-Stil" .. (ok8 and "" or (": " .. tostring(err8))))
    Check(ok7, "Kategorien im Charakterfenster: Titel mittig zwischen auslaufenden Zierlinien"
        .. (ok7 and "" or (": " .. tostring(err7))))

    -- 6.7.0.0: Designsprache der Fenster (ui/style.lua), der Ruf als
    -- erstes Fenster (ui/reputation.lua); 6.7.0.1: in der Klassenfarbe
    -- (Stil S.CHARACTER_INFO), Balken und Hervorhebung wie gemessen. Wichtigste Regel:
    -- keine Information geht verloren - kein SetText, keine Zeile weg,
    -- kein Titel verschoben.
    local okR, errR = pcall(function()
        local W, S, RP = WeintCodex.UIWindows, WeintCodex.UIStyle, WeintCodex.UIReputation
        local GC = WeintCodex.GameColors
        assert(S and RP, "ui/style.lua oder ui/reputation.lua nicht geladen")
        assert(W.own == S.own and W.Diamond == S.Diamond and WeintCodex.UICharacter.Gradient == S.Gradient,
            "Bausteine doppelt statt aus ui/style.lua")
        -- Zwei Akzente, nie vermischt: Gold folgt der Klasse NICHT.
        local gold = { GC.frameAccent[1], GC.frameAccent[2], GC.frameAccent[3] }
        local oldUC, oldRCC = _G.UnitClass, _G.RAID_CLASS_COLORS
        _G.UnitClass = function() return "Jäger", "HUNTER", 3 end
        _G.RAID_CLASS_COLORS = { HUNTER = { r = 0.67, g = 0.83, b = 0.45 } }
        K.ResetHighlight()
        assert(S.Accent("class") == K.Highlight() and S.Accent(nil) == K.Highlight() and S.Accent("frame") == GC.frameAccent,
            "Akzente vertauscht")
        assert(GC.frameAccent[1] == gold[1] and GC.frameAccent[2] == gold[2] and GC.frameAccent[3] == gold[3],
            "Gold der Fenster folgt der Klassenfarbe")
        _G.UnitClass, _G.RAID_CLASS_COLORS = oldUC, oldRCC
        K.ResetHighlight()

        local function Tex(atlas)
            local t = stub.NewObject("Texture")
            t.GetAtlas = function() return atlas end
            return t
        end
        local wrote, moved = {}, false
        local function Line(text)
            local fs = stub.NewObject("FontString")
            fs._text, fs._font = text, true
            fs.SetText = function() wrote[#wrote + 1] = text end
            return fs
        end
        local cf = stub.NewObject("Frame")
        local rf = stub.NewObject("Frame", "ReputationFrame")
        rf._parent = cf
        local list, target = stub.NewObject("Frame"), stub.NewObject("Frame")
        rf.ScrollBox, list.ScrollTarget = list, target
        -- Kopfzeile, wie 6.6.2.9 gemessen.
        local head = stub.NewObject("Button")
        local hBg, minus = Tex("common-button-list-collapseExpand"), Tex("common-button-list-minus")
        hBg._width = 300
        local hName = Line("Classic")
        hName.ClearAllPoints = function() moved = true end
        head.GetRegions = function() return hBg, minus, hName end
        -- Fraktionen: Inhalt mit Name und Balken. Gemessen (6.7.0.0): der
        -- Balken ist KEIN Statusbalken, seine Fuellung das Bild
        -- "common-stat-bar-white"; am Inhalt die Hervorhebung des Spiels.
        -- Die zweite Zeile wie im Quelltext: Statusbalken, keine Hervorhebung.
        local tinted = {}
        local function Faction(text, measured)
            local row, content = stub.NewObject("Frame"), stub.NewObject("Button")
            local bar = stub.NewObject(measured and "Frame" or "StatusBar")
            local fill = measured and Tex("common-stat-bar-white") or stub.NewObject("Texture")
            local track = Tex("common-stat-bar-BG")
            if measured then
                bar.GetRegions = function() return track, fill end
                local bh = stub.NewObject("Frame")
                local side, mid = Tex("charactercreate-customize-dropdown-linemouseover-side"),
                                  Tex("charactercreate-customize-dropdown-linemouseover-middle")
                for _, t in ipairs({ side, mid }) do
                    t.SetDesaturated = function(self, v) self._desat = v end
                    t.SetVertexColor = function(self, r, g, b, a) self._vc = { r, g, b, a } tinted[self] = true end
                    t.GetVertexColor = function(self) if self._vc then return unpack(self._vc) end return 1, 1, 1, 1 end
                end
                bh.GetRegions = function() return side, mid end
                content.BackgroundHighlight = bh
                content.GetChildren = function() return bar, bh end
            else
                bar.GetRegions = function() return track end
                bar.GetStatusBarTexture = function() return fill end
                content.GetChildren = function() return bar end
            end
            content.Name, content.ReputationBar = Line(text), bar
            row.Content = content
            row.GetChildren = function() return content end
            return row, bar, content.Name, track, fill
        end
        local row1, bar1, name1, track1, fill1 = Faction("Sturmwind", true)
        local row2, bar2, _, _, fill2 = Faction("Eisenschmiede")
        target.GetChildren = function() return head, row1, row2 end
        list.GetChildren = function() return target end
        -- Detailansicht rechts, mit Dialograhmen.
        local det, border = stub.NewObject("Frame"), stub.NewObject("Frame")
        local edge = stub.NewObject("Texture")
        border.GetRegions = function() return edge end
        det.Border, det.Title = border, Line("Sturmwind")
        det._parent, det._width = rf, 240
        -- 6.7.0.2: Tafel mit Bereichen. Balken (Bild als Fuellung) und zwei
        -- Haekchen mit Lage; keiner davon darf verschoben werden.
        local detBar, detFill = stub.NewObject("Frame"), Tex("common-stat-bar-white")
        detBar.GetRegions = function() return detFill end
        local war, watch = stub.NewObject("CheckButton"), stub.NewObject("CheckButton")
        local shoved = {}
        detBar.SetPoint = function() shoved[#shoved + 1] = "bar" end
        detBar.ClearAllPoints = function() shoved[#shoved + 1] = "bar" end
        det.GetTop, det.GetLeft = function() return 500 end, function() return 400 end
        detBar.GetTop, detBar.GetBottom = function() return 440 end, function() return 420 end
        -- 6.7.0.3: die Haekchen ruecken unter die Beschreibung - nur per
        -- SetPoint, gemeinsam, mit den Abstaenden des Spiels.
        for fr, t in pairs({ [war] = 200, [watch] = 170 }) do
            fr._top = t
            fr.GetTop = function(self) return self._top end
            fr.GetBottom = function(self) return self._top - 20 end
            fr.GetLeft = function() return 412 end
            fr.SetPoint = function(self, point, rel, relPoint, x, y)
                assert(point == "TOPLEFT" and rel == det and x == 12, "Haekchen falsch verankert")
                self._top = 500 + y
            end
            local label = Line("Beschriftung")
            fr.GetRegions = function() return label end
        end
        local desc = Line("Diese Hauptstadt der Allianz wird von Nachtelfen bewohnt und liegt auf der Insel Teldrassil.")
        desc.GetTop = function() return 400 end
        local descH = 60
        desc.GetStringHeight = function() return descH end
        det.GetRegions = function() return det.Title, desc end
        det.GetChildren = function() return border, detBar, war, watch end
        det:Hide()
        rf.ReputationDetailFrame = det
        rf.GetChildren = function() return list, det end
        cf.GetChildren = function() return rf end
        local oldRF = _G.ReputationFrame
        _G.ReputationFrame = rf

        -- Kein Gold im Ruf: jeder Verlauf, der hier gemalt wird, zaehlt.
        local grad, golden = S.Gradient, 0
        S.Gradient = function(t, dir, c, a0, a1)
            if c == GC.frameAccent then golden = golden + 1 end
            return grad(t, dir, c, a0, a1)
        end
        -- Stil durchgereicht: Kopfzeile als Listenzeile in der Klassenfarbe, Titel bleibt stehen.
        S.Register()
        assert(S.ScopeOf(rf) == S.CHARACTER_INFO and S.CHARACTER_INFO.accent == "class", "Ruf ohne Stil der Klasse")
        W.HideByAtlas(cf)
        local lh = W.ListHeaders[head]
        assert(lh and not W.Headers[head] and lh.title == hName and lh.icon == minus, "Ruf-Kopfzeile nicht als Listenzeile")
        assert(lh.accent == K.Highlight() and not lh.halo and W.own[lh.line] and W.own[lh.dot],
            "Ruf-Kopfzeile nicht in der Klassenfarbe oder mit Lichthof")
        assert(lh.band and W.own[lh.band.fill] and W.own[lh.band.line.l], "Gruppe nicht als eigene Sektion")
        assert(not moved, "Titel der Gruppe verschoben - die Einrueckung ginge verloren")
        assert(hBg:GetAlpha() == 0 and minus:GetAlpha() == 1, "Grund bleibt oder Zeichen zum Aufklappen weg")
        assert(track1:GetAlpha() == 0 and W.FlatBars[bar1] and W.FlatBars[bar1].style == S.CHARACTER_INFO,
            "Balken ohne dunkle Bahn")

        -- Atmosphaere unter dem Fenster, Zeilen, Balken.
        RP.Update(cf)
        local a = RP.atmos[rf]
        assert(a and a.on and a.list and a.list.body and a.list.edge and a.light and a.vignette.TOP and a.vignette.RIGHT,
            "Atmosphaere oder Flaeche der Liste fehlt")
        assert(a.list.body._parent == cf and a.light._parent == cf and a.vignette.TOP._parent == cf,
            "Atmosphaere nicht unter allem, was das Spiel zeichnet")
        local r1, r2 = RP.rows[row1], RP.rows[row2]
        assert(r1 and r2 and r1.bar == bar1 and r2.bar == bar2, "Balken nicht gefunden (auch ohne Statusbalken)")
        assert(RP.bars[bar1].fill == fill1 and RP.bars[bar1].how == "Bild" and RP.bars[bar2].fill == fill2,
            "Fuellung nicht veredelt")
        -- Maus: die Hervorhebung des Spiels in der Klassenfarbe, keine zweite.
        assert(#r1.hl == 2 and not r1.hover and r2.hover, "Hervorhebung doppelt oder fehlt")
        local acc, nTinted = K.Highlight(), 0
        for _ in pairs(tinted) do nTinted = nTinted + 1 end
        assert(nTinted == 2, "Hervorhebung des Spiels nicht getoent (" .. nTinted .. " von 2)")
        for t in pairs(tinted) do
            assert(t._desat and t._vc[1] == acc[1] and t._vc[4] == RP.HIGHLIGHT_ALPHA, "Hervorhebung nicht in der Klassenfarbe")
        end
        assert(r1.sel and not r1.sel.on, "Auswahl ohne Detailansicht")
        assert(r1.sep and r2.sep and RP.rows[head] and not RP.rows[head].sep, "Fraktionen nicht voneinander abgesetzt")
        assert(a.sigil and W.own[a.sigil] and a.sigil._parent == cf and a.list.shadow, "Codex-Zeichen oder Schatten fehlt")
        -- Auswahl = was rechts steht.
        det:Show()
        RP.Update(cf)
        assert(RP.state.selected == "Sturmwind" and r1.sel.on and not r2.sel.on, "gewaehlte Fraktion nicht markiert")
        local dd = RP.details[det]
        assert(dd and dd.inTree and dd.surface and not dd.panel and dd.line and edge:GetAlpha() == 0,
            "Detailansicht nicht als Flaeche der Oberflaeche gestaltet")
        assert(W.own[dd.line.l] and W.own[dd.surface.body], "Flaeche der Detailansicht als fremdes Bild")
        -- Tafel: Balken gefunden, Grenzen nach den Rahmen des Spiels.
        assert(dd.bar == detBar and RP.bars[detBar] and RP.bars[detBar].fill == detFill, "Balken der Detailansicht nicht gefunden")
        -- Beschreibung endet bei -160, Optionen 30 darunter: 110 px nach oben.
        assert(dd.desc == desc and dd.movable and dd.shift == 110, "Optionen nicht unter die Beschreibung gerueckt: "
            .. tostring(dd.shift) .. " " .. tostring(dd.why))
        assert(war._top == 310 and watch._top == 280, "Abstand der Haekchen nicht erhalten")
        assert(dd.yBar == -60 and dd.yBarB == -80 and dd.yOpt == -190 and dd.yOptB == -240, "Bereiche falsch vermessen")
        assert(dd.barLine.l:IsShown() and dd.options:IsShown() and dd.optLine.l:IsShown(), "Bereiche der Karte fehlen")
        -- 6.7.2.1: Gliederung wie bei den Fertigkeiten - Linie UNTER dem
        -- Balken (-80 - 9), Karte endet 12 px unter den Haekchen.
        assert(dd.barLineY == -89, "Linie nicht unter dem Balken: " .. tostring(dd.barLineY))
        assert(dd.cardBottom == -252, "Karte endet nicht unter den Haekchen: " .. tostring(dd.cardBottom))
        assert(#shoved == 0, "Balken der Detailansicht verschoben")
        -- Lange Beschreibung: zurueck an den Platz des Spiels, nie tiefer.
        descH = 250
        RP.Update(cf)
        assert(dd.shift == 0 and war._top == 200 and watch._top == 170, "Haekchen bei langer Beschreibung nicht zurueck")
        -- Auch ungerueckt endet die Karte unter dem Inhalt, nicht am Rand.
        assert(dd.cardBottom == -362, "Karte reicht ohne Ruecken bis zum Rand: " .. tostring(dd.cardBottom))
        descH = 60
        RP.Update(cf)
        assert(dd.shift == 110 and war._top == 310, "Haekchen ruecken nicht wieder hoch")
        -- Schiebt das Spiel sie zurueck, holt der naechste Durchlauf sie.
        war._top, watch._top = 200, 170
        RP.Update(cf)
        assert(war._top == 310 and watch._top == 280, "vom Spiel zurueckgesetzte Haekchen bleiben unten")
        -- Schutzregeln: ohne eigene Beschriftung oder mit weiterem Knopf ruecken sie nicht.
        local function Guard(extra)
            local d2 = stub.NewObject("Frame")
            d2.GetTop, d2.GetLeft = function() return 500 end, function() return 400 end
            local cb = stub.NewObject("CheckButton")
            cb.GetTop, cb.GetLeft = function() return 200 end, function() return 412 end
            if extra == "label" then
                cb.GetRegions = function() return Line("Im Krieg") end
                local btn = stub.NewObject("Button")
                d2.GetChildren = function() return cb, btn end
            else
                d2.GetChildren = function() return cb end
            end
            local g = { frame = d2 }
            RP.Options(g)
            return g
        end
        local g1, g2 = Guard(nil), Guard("label")
        assert(g1.opts and not g1.movable and g1.why == "Beschriftung nicht am Häkchen", "Haekchen ohne Beschriftung wuerde gerueckt")
        assert(g2.opts and not g2.movable and g2.why == "weiterer Knopf in der Detailansicht", "weiterer Knopf nicht beachtet")
        det.Title._text = "Eisenschmiede"
        RP.Update(cf)
        assert(r2.sel.on and not r1.sel.on, "Auswahl folgt der Detailansicht nicht")
        -- Nichts verloren: Namen, Balken, Zeilen da; kein Text ueberschrieben.
        for _, t in ipairs({ name1, bar1, row1, row2, head, hName, det.Title, minus }) do
            assert(t:IsShown() and t:GetAlpha() == 1, "Inhalt ausgeblendet")
        end
        assert(#wrote == 0, "SetText auf einer Zeile des Spiels: " .. table.concat(wrote, ", "))
        -- Bericht.
        local rep = table.concat(RP.Report(cf, {}), "\n")
        assert(rep:find("Ruf (Stil ruhig, Klasse)", 1, true) and rep:find("3 Zeilen (1 Kopfzeilen, 2 mit Balken, 3 mit Namen)", 1, true)
            and rep:find("Balken: Frame, Füllung Bild", 1, true) and rep:find("getönt: 2", 1, true)
            and rep:find("gewählt: „Eisenschmiede“", 1, true) and rep:find("Detailansicht: Fläche im Fenster", 1, true)
            and rep:find("Karte: Balken Frame, Beschreibung gefunden, Optionen 2 Häkchen, Bereiche: Balken -60, Optionen -190", 1, true)
            and rep:find("Optionen: um 110 px nach oben gerückt", 1, true),
            "Bericht: " .. rep)
        S.Gradient = grad
        assert(golden == 0, "Gold im Ruf: " .. golden .. " Verlaeufe")
        -- Kein Muell im Takt.
        for _ = 1, 3 do RP.Update(cf) end
        collectgarbage("collect")
        collectgarbage("stop")
        local k0 = collectgarbage("count")
        for _ = 1, 20 do RP.Update(cf) end
        local grew = collectgarbage("count") - k0
        collectgarbage("restart")
        print(string.format("    (20 Durchlaeufe Ruf: %.1f KB)", grew))
        assert(grew < 1, string.format("Ruf legt im Takt Muell an: %.1f KB", grew))
        -- Anderer Reiter: Atmosphaere sofort weg (Haken), und im Takt.
        rf._scripts.OnHide(rf)
        assert(not a.on and not a.list.body:IsShown(), "Flaeche der Liste bleibt nach dem Reiterwechsel")
        rf._scripts.OnShow(rf)
        assert(a.on and a.list.body:IsShown(), "Atmosphaere kommt nicht zurueck")
        rf:Hide()
        RP.Update(cf)
        assert(not a.on, "Atmosphaere ueber anderem Reiter")
        _G.ReputationFrame = oldRF
    end)
    Check(okR, "Ruf im Stil der Fenster: Klassenfarbe, Flaechen, Sektionen, Balken, Maus, Auswahl, Codex-Tafel - nichts verloren, kein Muell"
        .. (okR and "" or (": " .. tostring(errR))))

    -- 6.7.1.0: Fertigkeiten - dasselbe Register (ui/register.lua), eigene
    -- Eigenheiten. Nachgebaut wie aeltere Fassungen des Fensters: Name und
    -- Fortschritt IM Balken, Detailansicht ohne bekannten Schluessel, eine
    -- Zeile unter der Beschreibung, ein Knopf neben dem Balken. Die Liste
    -- wie gemessen (dieselben Vorlagen wie im Ruf).
    local okF, errF = pcall(function()
        local W, S, RG, SK, RP = WeintCodex.UIWindows, WeintCodex.UIStyle, WeintCodex.UIRegister,
                                 WeintCodex.UISkills, WeintCodex.UIReputation
        assert(RG and SK and RP and RG.all[1] == RP and RG.all[2] == SK, "Register nicht angelegt")
        assert(S.SCOPES.SkillsFrame == S.CHARACTER_INFO and S.SCOPES.ReputationFrame == S.CHARACTER_INFO,
            "Fenster tragen ihren Stil nicht selbst ein")
        local function Tex(atlas)
            local t = stub.NewObject("Texture")
            t.GetAtlas = function() return atlas end
            return t
        end
        local wrote, touched = {}, {}
        local function Line(text, top, h)
            local fs = stub.NewObject("FontString")
            fs._text, fs._font = text, true
            fs.SetText = function() wrote[#wrote + 1] = text end
            fs.SetPoint = function() touched[#touched + 1] = text end
            fs.ClearAllPoints = function() touched[#touched + 1] = text end
            if top then
                fs.GetTop, fs.GetBottom = function() return top end, function() return top - (h or 12) end
                fs.GetStringHeight = function() return h or 12 end
            end
            return fs
        end
        local cf = stub.NewObject("Frame")
        local sk = stub.NewObject("Frame", "SkillsFrame")
        sk._parent = cf
        local list, target = stub.NewObject("Frame"), stub.NewObject("Frame")
        sk.ScrollBox, list.ScrollTarget = list, target
        local head = stub.NewObject("Button")
        local hBg, minus = Tex("common-button-list-collapseExpand"), Tex("common-button-list-minus")
        hBg._width = 300
        local hName = Line("Berufe")
        head.GetRegions = function() return hBg, minus, hName end
        -- Zeile: Balken unter einem ungemessenen Schluessel (RankBar), blau.
        local recolored = {}
        local function Skill(text)
            local row, content = stub.NewObject("Frame"), stub.NewObject("Button")
            local bar, fill = stub.NewObject("StatusBar"), stub.NewObject("Texture")
            local track = Tex("common-stat-bar-BG")
            bar.GetRegions = function() return track end
            bar.GetStatusBarTexture = function() return fill end
            bar.SetStatusBarColor = function() recolored[#recolored + 1] = text end
            fill.SetVertexColor = function() recolored[#recolored + 1] = text end
            content.Name, content.RankBar = Line(text), bar
            content.GetChildren = function() return bar end
            row.Content = content
            row.GetChildren = function() return content end
            return row, bar, track
        end
        local row1, bar1, track1 = Skill("Bergbau")
        local row2 = Skill("Schmiedekunst")
        target.GetChildren = function() return head, row1, row2 end
        list.GetChildren = function() return target end
        -- Detailansicht ohne bekannten Schluessel (sk.RightPanel).
        local det = stub.NewObject("Frame")
        det._parent, det._width = sk, 220
        det.GetTop = function() return 500 end
        local dBar, dFill = stub.NewObject("StatusBar"), stub.NewObject("Texture")
        dBar.GetStatusBarTexture = function() return dFill end
        dBar.GetTop, dBar.GetBottom = function() return 470 end, function() return 450 end
        dBar._parent = det
        local name, rank = Line("Bergbau", 468), Line("32 / 75", 466)
        name._parent, rank._parent = dBar, dBar
        name.SetFont = function() touched[#touched + 1] = "Schrift im Balken" end
        dBar.GetRegions = function() return name, rank end
        local desc = Line("Mit Bergbau kannst du Erz und Stein abbauen, um daraus Metallbarren zu schmelzen.", 430, 45)
        local cost = Line("Kosten: 1 Gold", 350, 14)
        local unlearn = stub.NewObject("Button")
        unlearn.GetTop, unlearn.GetBottom = function() return 470 end, function() return 455 end
        unlearn.SetPoint = function() touched[#touched + 1] = "Knopf" end
        det.GetRegions = function() return desc, cost end
        det.GetChildren = function() return dBar, unlearn end
        dBar.SetPoint = function() touched[#touched + 1] = "Balken" end
        sk.RightPanel = det
        sk.GetChildren = function() return list, det end
        cf.GetChildren = function() return sk end
        local oldSK = _G.SkillsFrame
        _G.SkillsFrame = sk

        S.Register()
        assert(S.ScopeOf(sk) == S.CHARACTER_INFO, "Fertigkeiten ohne Stil der Klasse")
        W.HideByAtlas(cf)
        local lh = W.ListHeaders[head]
        assert(lh and lh.band and lh.accent == K.Highlight(), "Gruppe der Fertigkeiten nicht als Sektion")
        assert(track1:GetAlpha() == 0 and W.FlatBars[bar1] and W.FlatBars[bar1].style == S.CHARACTER_INFO,
            "Fortschrittsbalken ohne dunkle Bahn")
        SK.Update(cf)
        local a = SK.atmos[sk]
        assert(a and a.on and a.list and a.vignette.TOP and not a.sigil, "Atmosphaere falsch (kein Zeichen bei den Fertigkeiten)")
        local r1, r2 = SK.rows[row1], SK.rows[row2]
        assert(r1 and r2 and r1.bar == bar1 and SK.bars[bar1] and SK.bars[bar1].how == "Statusbalken",
            "Balken ohne bekannten Schluessel nicht gefunden")
        assert(r1.sep and r1.hover and not SK.rows[head].sep, "Zeilen nicht abgesetzt oder ohne Maus")
        -- Detailansicht gefunden, Titel steht im Balken und bleibt, wie er ist.
        local d = SK.details[det]
        assert(d and d.inTree and d.surface and d.bar == dBar and d.desc == desc and d.title == name,
            "Detailansicht der Fertigkeiten nicht gefunden")
        assert(SK.state.selected == "Bergbau" and r1.sel.on and not r2.sel.on, "gewaehlte Fertigkeit nicht markiert")
        -- Linie UNTER dem Balken, darunter Beschreibung, dann das, was folgt.
        assert(d.yBar == -30 and d.yBarB == -50 and d.db == -115, "Karte falsch vermessen")
        assert(d.yOpt == -150 and d.yOptB == -164 and not d.opts, "was unter der Beschreibung folgt, nicht erkannt")
        assert(d.barLine.l:IsShown() and d.optLine.l:IsShown() and d.options:IsShown(), "Linien der Karte fehlen")
        assert(d.barLineY == -59, "Linie nicht unter dem Balken: " .. tostring(d.barLineY))
        assert(d.cardBottom == -176, "Karte endet nicht unter dem Inhalt: " .. tostring(d.cardBottom))
        -- Nichts verloren, nichts umgefaerbt, nichts verschoben.
        assert(#wrote == 0, "SetText auf einer Zeile des Spiels")
        assert(#touched == 0, "Rahmen oder Schrift der Detailansicht angefasst: " .. table.concat(touched, ", "))
        assert(#recolored == 0, "Farbe eines Fortschrittsbalkens veraendert")
        for _, t in ipairs({ bar1, row1, row2, head, name, rank, desc, cost, unlearn, dBar }) do
            assert(t:IsShown() and t:GetAlpha() == 1, "Inhalt ausgeblendet")
        end
        local rep = table.concat(SK.Report(cf, {}), "\n")
        assert(rep:find("Fertigkeiten (Stil ruhig, Klasse): Liste gefunden, 3 Zeilen (1 Kopfzeilen, 2 mit Balken, 3 mit Namen)", 1, true)
            and rep:find("Fertigkeiten, gewählt: „Bergbau“", 1, true) and rep:find("Titel „Bergbau“ (im Balken)", 1, true)
            and rep:find("Fertigkeiten, Optionen: darunter abgesetzt ab -150", 1, true), "Bericht: " .. rep)
        -- Der Ruf bleibt unberuehrt: sein Bericht schweigt (Ruf zu).
        assert(#RP.Report(cf, {}) == 0 or not _G.ReputationFrame, "Ruf meldet sich ueber den Fertigkeiten")
        for _ = 1, 3 do SK.Update(cf) end
        collectgarbage("collect")
        collectgarbage("stop")
        local k0 = collectgarbage("count")
        for _ = 1, 20 do SK.Update(cf) end
        local grew = collectgarbage("count") - k0
        collectgarbage("restart")
        print(string.format("    (20 Durchlaeufe Fertigkeiten: %.1f KB)", grew))
        assert(grew < 1, string.format("Fertigkeiten legen im Takt Muell an: %.1f KB", grew))
        _G.SkillsFrame = oldSK
    end)
    Check(okF, "Fertigkeiten als Register: Stil, Sektionen, Balken (Farbe bleibt), Auswahl, Karte - nichts verloren, kein Muell"
        .. (okF and "" or (": " .. tostring(errF))))

    -- 6.7.2.0: PvP als Profil (ui/pvp.lua). Ungemessen - gefunden wird ueber
    -- Lage und Form. Nachgebaut nach der Beschreibung im Beta-Test: links
    -- Rangsymbol, Rang, Rangpunkte, Balken; rechts Rang, Beschreibung,
    -- "Naechste Belohnungen", Belohnung (Knopf mit Symbol und Name),
    -- Beschreibung. Dazu zwei Fallen: ein Hintergrundbild (zu gross) und ein
    -- kleines Symbol (zu klein) duerfen nicht das Rangsymbol sein.
    local okP, errP = pcall(function()
        local W, S, PV, RP, SK = WeintCodex.UIWindows, WeintCodex.UIStyle, WeintCodex.UIPvP,
                                 WeintCodex.UIReputation, WeintCodex.UISkills
        assert(PV and W.TABS[1] == RP and W.TABS[2] == SK and W.TABS[3] == PV, "Reiter nicht eingetragen")
        assert(S.SCOPES.PVPFrame == S.CHARACTER_INFO, "PvP ohne Stil der Klasse")
        local touched = {}
        local function Box(obj, l, t, r, b)
            obj.GetLeft, obj.GetTop = function() return l end, function() return t end
            obj.GetRight, obj.GetBottom = function() return r end, function() return b end
            obj._width, obj._height = r - l, t - b
            obj.SetPoint = function() touched[#touched + 1] = "SetPoint" end
            obj.ClearAllPoints = function() touched[#touched + 1] = "ClearAllPoints" end
            return obj
        end
        local function Line(text, l, t, r, b)
            local fs = Box(stub.NewObject("FontString"), l, t, r, b)
            fs._text, fs._font = text, true
            fs.SetText = function() touched[#touched + 1] = "SetText " .. text end
            fs.SetTextColor = function() touched[#touched + 1] = "Farbe " .. text end
            fs.GetStringHeight = function() return t - b end
            return fs
        end
        local cf = stub.NewObject("Frame")
        local root = Box(stub.NewObject("Frame", "PVPFrame"), 100, 500, 480, 50)
        root._parent = cf
        local bg = Box(stub.NewObject("Texture"), 100, 500, 480, 50)            -- Hintergrund: zu gross
        local tiny = Box(stub.NewObject("Texture"), 300, 480, 320, 460)         -- 20 px: zu klein
        root.GetRegions = function() return bg, tiny end
        local rankFrame = Box(stub.NewObject("Frame"), 110, 430, 250, 280)
        local icon = Box(stub.NewObject("Texture"), 140, 420, 204, 356)
        icon._parent = Box(stub.NewObject("Frame"), 0, 100, 100, 0)
        -- Rang unter dem Balken: die Beschreibung rechts steht dem Symbol
        -- naeher - sie darf trotzdem nicht als Rang gelten.
        local rank = Line("Zivilist", 130, 285, 214, 271)
        local points = Line("Rangpunkte: 0 / 750", 120, 320, 230, 306)
        local bar, fill = Box(stub.NewObject("StatusBar"), 120, 300, 230, 290), stub.NewObject("Texture")
        bar.GetStatusBarTexture = function() return fill end
        bar.SetStatusBarColor = function() touched[#touched + 1] = "Balkenfarbe" end
        rankFrame.GetRegions = function() return icon, rank, points end
        rankFrame.GetChildren = function() return bar end
        -- Detailansicht rechts.
        local det = Box(stub.NewObject("Frame"), 270, 480, 470, 60)
        det._parent = root
        local title = Line("Zivilist", 280, 470, 460, 454)
        local desc = Line("Du hast noch keinen Rang in der Armee deiner Fraktion erworben.", 280, 440, 460, 400)
        local head = Line("Nächste Belohnungen", 280, 380, 460, 366)
        local itemDesc = Line("Ein schlichter Umhang für jene, die gerade erst ins Feld ziehen.", 280, 320, 460, 290)
        local reward = Box(stub.NewObject("Button"), 280, 360, 460, 324)
        local rIcon = Box(stub.NewObject("Texture"), 280, 360, 316, 324)
        local rName = Line("Umhang des Gefreiten", 322, 358, 460, 344)
        rName.SetFont = function() touched[#touched + 1] = "Schrift Itemname" end
        reward.Icon = rIcon
        reward.GetRegions = function() return rIcon, rName end
        det.GetRegions = function() return title, desc, head, itemDesc end
        det.GetChildren = function() return reward end
        root.GetChildren = function() return rankFrame, det end
        cf.GetChildren = function() return root end
        local oldPV = _G.PVPFrame
        _G.PVPFrame = root

        PV.Update(cf)
        local L = PV.layouts[root]
        assert(L and L.detail == det and L.icon == icon and L.rank == rank and L.points == points and L.bar == bar,
            "Profil nicht erkannt: Symbol " .. tostring(L and L.icon == icon) .. ", Rang " .. tostring(L and L.rank == rank))
        assert(L.title == title and L.reward == reward and L.head == head, "Detailansicht nicht erkannt")
        -- Das Symbol haengt hier an einem kleinen Rahmen AUSSERHALB des
        -- Fensters: kein Medaillon ausserhalb des Reiters.
        assert(L.medal == nil, "Medaillon ausserhalb des Fensters")
        -- Rangbereich um Symbol, Rang, Punkte und Balken; Buehne am Symbol.
        assert(L.ax1 == 20 and L.ay1 == -80 and L.ax2 == 130 and L.ay2 == -229, "Rangbereich falsch gelegt: "
            .. tostring(L.ax1) .. "/" .. tostring(L.ay1) .. " " .. tostring(L.ax2) .. "/" .. tostring(L.ay2))
        assert(L.stage and L.stage.target == icon and L.stage.size == 64 and L.stage.shade._parent == cf,
            "Rangsymbol nicht als Mittelpunkt")
        assert(L.barFinish and L.barFinish.how == "Statusbalken" and L.torchL and L.torchR and L.on,
            "Balken oder Atmosphaere fehlt")
        -- Karte: Linie unter dem Rang, Ornament ueber "Naechste Belohnungen",
        -- Belohnung auf eigener Flaeche, Karte endet darunter.
        local d = L.card
        assert(d and d.inTree and d.yTitle == -26 and d.yHead == -100 and d.yReward == -120 and d.yLow == -190,
            "Karte falsch vermessen")
        assert(d.titleLine.l:IsShown() and d.rewardOrn.dot:IsShown() and d.rewardBody:IsShown() and d.cardBottom == -202,
            "Bereiche der Karte fehlen")
        -- Nichts verloren, keine Farbe des Spiels ueberschrieben, nichts verschoben.
        assert(#touched == 0, "Blizzard-Teile angefasst: " .. table.concat(touched, ", "))
        for _, t in ipairs({ icon, rank, points, bar, title, desc, head, itemDesc, reward, rIcon, rName }) do
            assert(t:IsShown() and t:GetAlpha() == 1, "Inhalt ausgeblendet")
        end
        local rep = table.concat(PV.Report(cf, {}), "\n")
        assert(rep:find("PvP (Stil ruhig, Klasse): Fenster PVPFrame", 1, true)
            and rep:find("Punkte „Rangpunkte: 0 / 750“", 1, true) and rep:find("Rang „Zivilist“", 1, true)
            and rep:find("Überschrift „Nächste Belohnungen“", 1, true) and rep:find("Karte endet bei -202", 1, true),
            "Bericht: " .. rep)
        -- Anderer Reiter: Atmosphaere weg.
        root._scripts.OnHide(root)
        assert(not L.on and not L.torchL:IsShown(), "Atmosphaere bleibt ueber anderem Reiter")
        root._scripts.OnShow(root)
        for _ = 1, 3 do PV.Update(cf) end
        collectgarbage("collect")
        collectgarbage("stop")
        local k0 = collectgarbage("count")
        for _ = 1, 20 do PV.Update(cf) end
        local grew = collectgarbage("count") - k0
        collectgarbage("restart")
        print(string.format("    (20 Durchlaeufe PvP: %.1f KB)", grew))
        assert(grew < 1, string.format("PvP legt im Takt Muell an: %.1f KB", grew))
        _G.PVPFrame = oldPV

        -- 6.7.2.1: der Reiter, wie er im Spiel GEMESSEN ist (/wcui fenster
        -- nach 6.7.2.0, das dort nicht griff): PVPRankFrame mit
        -- MainInfoFrame.RankProgressBarDisplay (Schein = groesstes Bild, Ring,
        -- Wappen, NextRewardLevel mit "0") und DetailFrame.Content. Fallen:
        -- der Schein darf nicht das Symbol sein, die "0" nicht der Rang, und
        -- die Belohnung ist kein Knopf.
        assert(S.SCOPES.PVPRankFrame == S.CHARACTER_INFO and PV.FRAMES[1] == "PVPRankFrame", "PVPRankFrame nicht eingetragen")
        local function Tex(atlas, l, t, r, b)
            local x = Box(stub.NewObject("Texture"), l, t, r, b)
            x.GetAtlas = function() return atlas end
            return x
        end
        local cf2 = stub.NewObject("Frame")
        local root2 = Box(stub.NewObject("Frame", "PVPRankFrame"), 100, 500, 480, 50)
        root2._parent = cf2
        local main = Box(stub.NewObject("Frame"), 100, 490, 290, 60)
        main._parent = root2
        local levelBG = Tex("UI-Character-Info-Honor-LevelBG", 150, 370, 250, 270)
        local rankName = Line("Zivilist", 150, 420, 250, 404)
        local points2 = Line("Rangpunkte: 0 / 750", 130, 215, 270, 201)
        main.GetRegions = function() return levelBG, rankName, points2 end
        local medal = Box(stub.NewObject("Frame"), 120, 390, 280, 230)
        medal._parent = main
        main.GetChildren = function() return medal end
        local glow = Tex("UI-Character-Info-Honor-Bar-BG-Glow", 110, 400, 290, 220)
        local ring = Tex("UI-Character-Info-Honor-Bar-BG-Alliance", 125, 385, 275, 235)
        local emblem = Tex("UI-Character-Info-Honor-Icon-Alliance", 165, 345, 235, 275)
        for _, x in ipairs({ glow, ring, emblem }) do x._parent = medal end
        medal.GetRegions = function() return glow, ring, emblem end
        local nextLvl = Box(stub.NewObject("Frame"), 185, 250, 215, 220)
        nextLvl._parent = medal
        local ringTex = Tex("UI-Character-Info-Honor-RewardRing", 185, 250, 215, 220)
        local zero = Line("0", 192, 242, 208, 228)
        nextLvl.GetRegions = function() return ringTex, zero end
        medal.GetChildren = function() return nextLvl end
        local det2 = Box(stub.NewObject("Frame"), 300, 490, 470, 60)
        det2._parent = root2
        local content = Box(stub.NewObject("Frame"), 300, 490, 470, 60)
        content._parent = det2
        det2.GetChildren = function() return content end
        local title2 = Line("Zivilist", 310, 480, 460, 464)
        local desc2 = Line("Jede Woche wird das Limit für Rangpunkte erhöht, bis maximal 24750 für Rang 14.", 310, 450, 460, 410)
        local rdesc = Line("Belohnungen können in der Halle des Champions in Stormwind erworben werden.", 310, 300, 460, 270)
        content.GetRegions = function() return title2, desc2, rdesc end
        -- Ueberschrift: eine Kopfzeile des Spiels (Text darf wie bei den
        -- Fertigkeiten hell werden - er traegt keine Bedeutung).
        local hf = Box(stub.NewObject("Frame"), 310, 380, 460, 362)
        hf._parent = content
        local hTex = Tex("UI-Character-Info-Title", 310, 380, 460, 362)
        local hTitle = stub.NewObject("FontString")
        hTitle._text, hTitle._font, hTitle._parent = "Nächste Belohnungen auf Rang 1", true, hf
        hTitle.GetTop, hTitle.GetBottom = function() return 378 end, function() return 364 end
        hTitle.GetLeft, hTitle.GetRight = function() return 320 end, function() return 450 end
        hf.Title = hTitle
        hf.GetRegions = function() return hTex, hTitle end
        -- Belohnung: namenloser Rahmen (kein Knopf) mit Symbol und Name.
        local rw = Box(stub.NewObject("Frame"), 310, 350, 460, 318)
        rw._parent = content
        local rIcon2 = Box(stub.NewObject("Texture"), 310, 350, 342, 318)
        local rName2 = Line("Wappenrock der Allianz", 350, 340, 460, 326)
        rw.GetRegions = function() return rIcon2, rName2 end
        content.GetChildren = function() return hf, rw end
        root2.MainInfoFrame, root2.DetailFrame = main, det2
        root2.GetChildren = function() return main, det2 end
        cf2.GetChildren = function() return root2 end
        local oldRank = _G.PVPRankFrame
        _G.PVPRankFrame = root2
        S.Register()
        W.HideByAtlas(cf2)
        assert(W.ListHeaders[hf] and W.ListHeaders[hf].band, "Ueberschrift nicht wie bei den Fertigkeiten")
        PV.Update(cf2)
        local L2 = PV.layouts[root2]
        assert(PV.Frame() == root2 and L2 and L2.detail == det2, "PVPRankFrame oder DetailFrame nicht gefunden")
        assert(L2.icon == emblem, "Rangsymbol falsch: " .. tostring(L2.icon == glow and "Schein" or L2.icon))
        assert(L2.medal == medal and L2.rank == rankName and L2.points == points2,
            "Medaillon/Rang falsch: " .. tostring(L2.rank == zero and "„0“" or L2.rank))
        assert(L2.title == title2 and L2.reward == rw and L2.head == hTitle, "Detailansicht nicht erkannt")
        -- Rangbereich schliesst das Medaillon ein.
        assert(L2.ax1 == 20 and L2.ay1 == -80 and L2.ax2 == 180 and L2.ay2 == -299, "Rangbereich falsch gelegt: "
            .. tostring(L2.ax1) .. "/" .. tostring(L2.ay1) .. " " .. tostring(L2.ax2) .. "/" .. tostring(L2.ay2))
        assert(L2.stage and L2.stage.target == emblem and L2.stage.size == 70, "Wappen nicht als Mittelpunkt")
        local d2 = L2.card
        assert(d2 and d2.yTitle == -26 and d2.yHead == -112 and d2.yReward == -140 and d2.yLow == -220
            and d2.cardBottom == -232, "Karte falsch vermessen")
        -- Die Kopfzeile traegt Raute und Linie selbst: kein zweites Ornament.
        assert(d2.headStyled and not d2.rewardOrn.dot:IsShown() and d2.rewardBody:IsShown(), "Ornament doppelt oder Belohnung ohne Flaeche")
        assert(#touched == 0, "Blizzard-Teile angefasst: " .. table.concat(touched, ", "))
        for _, t in ipairs({ emblem, ring, glow, levelBG, rankName, points2, zero, title2, desc2, rdesc, hTitle, rIcon2, rName2 }) do
            assert(t:IsShown() and t:GetAlpha() == 1, "Inhalt ausgeblendet")
        end
        local rep2 = table.concat(PV.Report(cf2, {}), "\n")
        assert(rep2:find("Fenster PVPRankFrame", 1, true) and rep2:find("Rang „Zivilist“", 1, true)
            and rep2:find("Überschrift „Nächste Belohnungen auf Rang 1“ (Kopfzeile)", 1, true), "Bericht: " .. rep2)
        for _ = 1, 3 do PV.Update(cf2) end
        collectgarbage("collect")
        collectgarbage("stop")
        k0 = collectgarbage("count")
        for _ = 1, 20 do PV.Update(cf2) end
        grew = collectgarbage("count") - k0
        collectgarbage("restart")
        assert(grew < 1, string.format("PvP (gemessen) legt im Takt Muell an: %.1f KB", grew))
        _G.PVPRankFrame = oldRank
    end)
    Check(okP, "PvP als Profil: Rangsymbol als Mittelpunkt, Rangbereich, Karte mit Belohnung - Farben bleiben, nichts verloren, kein Muell"
        .. (okP and "" or (": " .. tostring(errP))))

    -- 6.7.3.0: Abzeichen (Waehrungen) - das dritte Register. Gemessen nur
    -- der Leerzustand (Liste leer, rechts ein Hinweis); danach, wie es mit
    -- einer Waehrung aussehen duerfte: Kopfzeile wie im Ruf, Zeile mit
    -- Symbol, Name und Anzahl (kein Balken), Detailansicht ohne bekannten
    -- Schluessel mit Name, Beschreibung und einer Zeile darunter.
    local okC, errC = pcall(function()
        local W, S, CU, PV = WeintCodex.UIWindows, WeintCodex.UIStyle, WeintCodex.UICurrency, WeintCodex.UIPvP
        assert(CU and W.TABS[4] == CU and W.TABS[3] == PV and S.SCOPES.TokenFrame == S.CHARACTER_INFO,
            "Abzeichen nicht als Reiter eingetragen")
        local touched = {}
        local function Tex(atlas)
            local t = stub.NewObject("Texture")
            t.GetAtlas = function() return atlas end
            return t
        end
        local function Line(text, top, bottom)
            local fs = stub.NewObject("FontString")
            fs._text, fs._font = text, true
            fs.SetText = function() touched[#touched + 1] = "SetText " .. text end
            if top then
                fs.GetTop, fs.GetBottom = function() return top end, function() return bottom end
                fs.GetStringHeight = function() return top - bottom end
            end
            return fs
        end
        local cf = stub.NewObject("Frame")
        local rf = stub.NewObject("Frame", "TokenFrame")
        rf._parent = cf
        local list, target, sbar = stub.NewObject("Frame"), stub.NewObject("Frame"), stub.NewObject("Frame")
        rf.ScrollBox, rf.ScrollBar, list.ScrollTarget = list, sbar, target
        local head = stub.NewObject("Button")
        local hBg, minus = Tex("common-button-list-collapseExpand"), Tex("common-button-list-minus")
        hBg._width = 300
        local hName = Line("Spieler gegen Spieler")
        head.GetRegions = function() return hBg, minus, hName end
        local row, content = stub.NewObject("Frame"), stub.NewObject("Button")
        local cName, count, cIcon = Line("Ehrenpunkte"), Line("150"), stub.NewObject("Texture")
        count.SetTextColor = function() touched[#touched + 1] = "Farbe Anzahl" end
        content.Name, content.Count, content.Icon = cName, count, cIcon
        content.GetRegions = function() return cIcon, cName, count end
        row.Content = content
        row.GetChildren = function() return content end
        -- Gemessen: Liste leer.
        target.GetChildren = function() return end
        list.GetChildren = function() return target end
        -- Detailansicht: nur der Hinweis.
        local det = stub.NewObject("Frame")
        det._parent = rf
        det.GetTop, det.GetLeft = function() return 500 end, function() return 400 end
        -- Falle: der Hinweis steht (ausgeblendet) ueber dem Titel und ist
        -- laenger als die Beschreibung - er darf spaeter keins von beiden sein.
        local hint = Line("Wählt eine Währung, um ihre Details anzuzeigen.", 495, 480)
        hint.SetFont = function() touched[#touched + 1] = "Schrift Hinweis" end
        det.GetRegions = function() return hint end
        rf.GetChildren = function() return list, sbar, det end
        cf.GetChildren = function() return rf end
        local oldTF = _G.TokenFrame
        _G.TokenFrame = rf

        S.Register()
        W.HideByAtlas(cf)
        CU.Update(cf)
        local a = CU.atmos[rf]
        assert(a and a.on and a.list and not a.sigil, "Atmosphaere oder Flaeche der Liste fehlt (kein Zeichen)")
        local d = CU.details[det]
        assert(d and d.surface and d.empty and not d.settled and not d.title, "Leerzustand nicht erkannt")
        assert(CU.state.selected == nil or CU.state.selected == hint._text, "Auswahl im Leerzustand")
        local rep = table.concat(CU.Report(cf, {}), "\n")
        assert(rep:find("Abzeichen (Stil ruhig, Klasse): Liste gefunden, 0 Zeilen", 1, true)
            and rep:find("Leerzustand", 1, true), "Bericht (leer): " .. rep)
        for _ = 1, 3 do CU.Update(cf) end
        collectgarbage("collect")
        collectgarbage("stop")
        local k0 = collectgarbage("count")
        for _ = 1, 20 do CU.Update(cf) end
        local grew = collectgarbage("count") - k0
        collectgarbage("restart")
        assert(grew < 1, string.format("Abzeichen (leer) legen im Takt Muell an: %.1f KB", grew))

        -- Mit Waehrung: Liste gefuellt, Hinweis weg, Name/Beschreibung/Zeile.
        target.GetChildren = function() return head, row end
        W.HideByAtlas(cf)
        local title = Line("Ehrenpunkte", 490, 474)
        local desc = Line("Ehre erhaltet Ihr für Siege gegen Spieler.", 460, 420)
        local extra = Line("Höchstens 75000", 405, 391)
        det.GetRegions = function() return hint, title, desc, extra end
        hint:Hide()
        CU.Update(cf)
        local lh = W.ListHeaders[head]
        assert(lh and lh.band and not W.Headers[head], "Gruppe nicht als Abschnitt wie im Ruf")
        local r = CU.rows[row]
        assert(r and not r.bar and r.sep, "Zeile falsch (Balken erfunden oder keine Trennlinie)")
        assert(d.settled and d.title == title and d.desc == desc, "Titel/Beschreibung nach der Auswahl falsch: "
            .. tostring(d.title and d.title._text) .. " / " .. tostring(d.desc and d.desc._text))
        assert(CU.state.selected == "Ehrenpunkte" and r.sel.on, "gewaehlte Waehrung nicht markiert")
        assert(d.db == -80 and d.yOpt == -95 and d.optLine.l:IsShown() and d.cardBottom == -121,
            "Karte falsch: db " .. tostring(d.db) .. " yOpt " .. tostring(d.yOpt) .. " Ende " .. tostring(d.cardBottom))
        assert(not d.barLine, "Linie am Balken ohne Balken")
        assert(#touched == 0, "Blizzard-Teile angefasst: " .. table.concat(touched, ", "))
        for _, t in ipairs({ cName, count, cIcon, title, desc, extra, hName, minus }) do
            assert(t:IsShown() and t:GetAlpha() == 1, "Inhalt ausgeblendet")
        end
        rep = table.concat(CU.Report(cf, {}), "\n")
        assert(rep:find("2 Zeilen (1 Kopfzeilen, 0 mit Balken, 2 mit Namen)", 1, true)
            and rep:find("gewählt: „Ehrenpunkte“", 1, true) and rep:find("darunter abgesetzt ab -95", 1, true),
            "Bericht: " .. rep)
        for _ = 1, 3 do CU.Update(cf) end
        collectgarbage("collect")
        collectgarbage("stop")
        k0 = collectgarbage("count")
        for _ = 1, 20 do CU.Update(cf) end
        grew = collectgarbage("count") - k0
        collectgarbage("restart")
        print(string.format("    (20 Durchlaeufe Abzeichen: %.1f KB)", grew))
        assert(grew < 1, string.format("Abzeichen legen im Takt Muell an: %.1f KB", grew))
        _G.TokenFrame = oldTF
    end)
    Check(okC, "Abzeichen als Register: Leerzustand ohne Titel, Abschnitte, Auswahl, Karte - nichts verloren, kein Muell"
        .. (okC and "" or (": " .. tostring(errC))))

    -- 6.7.4.0: Statistiken - Register ohne Detailansicht. Nachgebaut wie
    -- gemessen: Kopfzeile "Charakter", Gruppenzeile "Vermoegen" mit
    -- ToggleCollapseButton, Zeilen mit Name, Wert und der Hervorhebung des
    -- Spiels (dieselben Bilder wie im Ruf).
    local okS, errS = pcall(function()
        local W, S, ST, CU = WeintCodex.UIWindows, WeintCodex.UIStyle, WeintCodex.UIStatistics, WeintCodex.UICurrency
        assert(ST and W.TABS[5] == ST and W.TABS[4] == CU and S.SCOPES.StatisticsFrame == S.CHARACTER_INFO,
            "Statistiken nicht als Reiter eingetragen")
        local touched = {}
        local function Tex(atlas)
            local t = stub.NewObject("Texture")
            t.GetAtlas = function() return atlas end
            return t
        end
        local function Line(text)
            local fs = stub.NewObject("FontString")
            fs._text, fs._font = text, true
            fs.SetText = function() touched[#touched + 1] = "SetText " .. text end
            fs.SetTextColor = function() touched[#touched + 1] = "Farbe " .. text end
            fs.SetFont = function() touched[#touched + 1] = "Schrift " .. text end
            fs.ClearAllPoints = function() touched[#touched + 1] = "Lage " .. text end
            return fs
        end
        local cf = stub.NewObject("Frame")
        local rf = stub.NewObject("Frame", "StatisticsFrame")
        rf._parent = cf
        local list, target, sbar = stub.NewObject("Frame"), stub.NewObject("Frame"), stub.NewObject("Frame")
        rf.ScrollBox, rf.ScrollBar, list.ScrollTarget = list, sbar, target
        local head = stub.NewObject("Button")
        local hBg, minus = Tex("common-button-list-collapseExpand"), Tex("common-button-list-minus")
        hBg._width = 300
        local hName = stub.NewObject("FontString")
        hName._text, hName._font = "Charakter", true
        head.GetRegions = function() return hBg, minus, hName end
        local tinted = 0
        local function Stat(name, value, toggle)
            local row, content = stub.NewObject("Frame"), stub.NewObject("Button")
            local n, v = Line(name), value and Line(value) or nil
            local bh = stub.NewObject("Frame")
            local side, mid = Tex("charactercreate-customize-dropdown-linemouseover-side"),
                              Tex("charactercreate-customize-dropdown-linemouseover-middle")
            for _, t in ipairs({ side, mid }) do
                t.SetVertexColor = function() tinted = tinted + 1 end
            end
            bh.GetRegions = function() return side, mid end
            content.BackgroundHighlight, content.Name = bh, n
            content.GetRegions = function() return n, v end
            local kids = { bh }
            if toggle then
                local tb = stub.NewObject("Button")
                local icon = Tex("Campaign_HeaderIcon_Open")
                icon.SetDesaturated = function() touched[#touched + 1] = "Knopf grau" end
                tb.GetRegions = function() return icon end
                row.ToggleCollapseButton = tb
                row.GetChildren = function() return content, tb end
            else
                row.GetChildren = function() return content end
            end
            content.GetChildren = function() return unpack(kids) end
            row.Content = content
            return row, n, v
        end
        local group, gName = Stat("Vermögen", nil, true)
        local r1, n1, v1 = Stat("Talentneuverteilungen", "--")
        local r2, n2, v2 = Stat("Auktionserwerbungen", "2")
        target.GetChildren = function() return head, r1, group, r2 end
        list.GetChildren = function() return target end
        rf.GetChildren = function() return list, sbar end
        cf.GetChildren = function() return rf end
        local oldSF = _G.StatisticsFrame
        _G.StatisticsFrame = rf

        S.Register()
        W.HideByAtlas(cf)
        local lh = W.ListHeaders[head]
        assert(lh and lh.band and not W.Headers[head], "Kategorie nicht als Abschnitt wie im Ruf")
        ST.Update(cf)
        local a = ST.atmos[rf]
        assert(a and a.on and a.list and a.list.shadow and not a.sigil, "Atmosphaere oder Flaeche der Liste fehlt")
        for _, row in ipairs({ r1, group, r2 }) do
            local r = ST.rows[row]
            assert(r and r.sep and #r.hl == 2 and not r.hover and not r.bar, "Zeile nicht wie im Ruf abgesetzt")
            assert(not r.sel.on, "Auswahl ohne Detailansicht")
        end
        assert(tinted == 6, "Hervorhebung des Spiels nicht getoent: " .. tinted)
        assert(ST.state.selected == nil and ST.Detail(cf, rf) == nil, "Detailansicht erfunden")
        assert(#touched == 0, "Blizzard-Teile angefasst: " .. table.concat(touched, ", "))
        for _, t in ipairs({ n1, v1, n2, v2, gName, hName, minus, group.ToggleCollapseButton }) do
            assert(t:IsShown() and t:GetAlpha() == 1, "Inhalt ausgeblendet")
        end
        local rep = table.concat(ST.Report(cf, {}), "\n")
        assert(rep:find("Statistiken (Stil ruhig, Klasse): Liste gefunden, 4 Zeilen (1 Kopfzeilen, 0 mit Balken, 4 mit Namen)", 1, true)
            and rep:find("getönt: 6", 1, true) and rep:find("nur die Liste", 1, true)
            and not rep:find("gewählt", 1, true), "Bericht: " .. rep)
        for _ = 1, 3 do ST.Update(cf) end
        collectgarbage("collect")
        collectgarbage("stop")
        local k0 = collectgarbage("count")
        for _ = 1, 20 do ST.Update(cf) end
        local grew = collectgarbage("count") - k0
        collectgarbage("restart")
        print(string.format("    (20 Durchlaeufe Statistiken: %.1f KB)", grew))
        assert(grew < 1, string.format("Statistiken legen im Takt Muell an: %.1f KB", grew))
        rf._scripts.OnHide(rf)
        assert(not a.on and not a.list.body:IsShown(), "Flaeche bleibt nach dem Reiterwechsel")
        _G.StatisticsFrame = oldSF
    end)
    Check(okS, "Statistiken als Register ohne Detailansicht: Abschnitte, Zeilen, Maus in der Klassenfarbe - Werte bleiben, kein Muell"
        .. (okS and "" or (": " .. tostring(errS))))

    -- 6.7.5.0: Berufe - Rezeptseite als Register im Berufsfenster (nicht im
    -- Charakterfenster), in GOLD. Nachgebaut wie gemessen: CraftingPage mit
    -- Grund, RecipeList (Grund, ScrollBox, ScrollBar), Zeilen mit
    -- Professions_Recipe_Hover/_Active, SchematicForm mit grossem Bild,
    -- Rezeptname, Beschreibung, Zeile und Reagenz-Knopf darunter.
    local okB, errB = pcall(function()
        local W, S, PR = WeintCodex.UIWindows, WeintCodex.UIStyle, WeintCodex.UIProfessions
        local GC = WeintCodex.GameColors
        assert(PR and W.HOSTED.ProfessionsFrame and W.HOSTED.ProfessionsFrame[1] == PR, "Berufe nicht am Berufsfenster eingetragen")
        for _, tab in ipairs(W.TABS) do assert(tab ~= PR, "Berufe laufen im Charakterfenster") end
        assert(S.SCOPES.ProfessionsFrame == S.CALM and PR.STYLE == S.CALM and S.CALM.band, "Berufe nicht in Gold mit Abschnitten")
        local touched = {}
        local function Box(obj, l, t, r, b)
            obj.GetLeft, obj.GetTop = function() return l end, function() return t end
            obj.GetRight, obj.GetBottom = function() return r end, function() return b end
            obj.SetPoint = function() touched[#touched + 1] = "SetPoint" end
            obj.ClearAllPoints = function() touched[#touched + 1] = "ClearAllPoints" end
            return obj
        end
        local function Tex(atlas)
            local t = stub.NewObject("Texture")
            t.GetAtlas = function() return atlas end
            return t
        end
        local function Line(text, top, bottom)
            local fs = stub.NewObject("FontString")
            fs._text, fs._font = text, true
            fs.SetText = function() touched[#touched + 1] = "SetText " .. text end
            fs.SetTextColor = function() touched[#touched + 1] = "Farbe " .. text end
            if top then
                fs.GetTop, fs.GetBottom = function() return top end, function() return bottom end
                fs.GetStringHeight = function() return top - bottom end
            end
            return fs
        end
        local pf = stub.NewObject("Frame", "ProfessionsFrame")
        local cp = stub.NewObject("Frame")
        cp._parent, pf.CraftingPage = pf, cp
        local pageBg = Tex("Profession-Background-Template2")
        cp.GetRegions = function() return pageBg end
        local rl = stub.NewObject("Frame")
        rl._parent, cp.RecipeList = cp, rl
        local listBg = Tex("Professions-background-summarylist")
        rl.GetRegions = function() return listBg end
        local list, target, sbar = stub.NewObject("Frame"), stub.NewObject("Frame"), stub.NewObject("Frame")
        rl.ScrollBox, rl.ScrollBar, list.ScrollTarget = list, sbar, target
        rl.GetChildren = function() return list, sbar end
        local head = stub.NewObject("Button")
        local hBg, minus = Tex("common-button-list-collapseExpand"), Tex("common-button-list-minus")
        hBg._width = 300
        local hName = stub.NewObject("FontString")
        hName._text, hName._font = "Alltägliche Mahlzeiten", true
        head.GetRegions = function() return hBg, minus, hName end
        local tints = {}
        local function Recipe(name)
            local row = stub.NewObject("Button")
            local label = Line(name)
            local hover, active = Tex("Professions_Recipe_Hover"), Tex("Professions_Recipe_Active")
            for _, t in ipairs({ hover, active }) do
                t.SetVertexColor = function(self, r) tints[self] = r end
            end
            row.Label = label
            row.GetRegions = function() return hover, active, label end
            return row, label
        end
        local row1, l1 = Recipe("Gewürztes Wolfsfleisch")
        local row2, l2 = Recipe("Gebratener Eberrücken")
        target.GetChildren = function() return head, row1, row2 end
        list.GetChildren = function() return target end
        -- Das Rezept.
        local det = stub.NewObject("Frame")
        det._parent, cp.SchematicForm = cp, det
        det.GetTop, det.GetLeft = function() return 500 end, function() return 400 end
        local art = Tex("Profession-background-card-Cooking")
        local title = Line("Gewürztes Wolfsfleisch", 490, 474)
        local desc = Line("Stellt im Laufe von 18 Sek. insgesamt 61 Gesundheit wieder her. Wer isst, muss sitzen bleiben.", 460, 420)
        local need = Line("Benötigt: Kochfeuer", 405, 391)
        local reagent = Box(stub.NewObject("Button"), 410, 380, 450, 350)
        det.OutputText, det.Description = title, desc
        det.GetRegions = function() return art, title, desc, need end
        det.GetChildren = function() return reagent end
        cp.GetChildren = function() return rl, det end
        pf.GetChildren = function() return cp end
        local oldPF = _G.ProfessionsFrame
        _G.ProfessionsFrame = pf

        -- Kein Pinselstrich in der Klassenfarbe in diesem Fenster.
        local grad, classy = S.Gradient, 0
        S.Gradient = function(t, dir, c, a0, a1)
            if c == K.Highlight() then classy = classy + 1 end
            return grad(t, dir, c, a0, a1)
        end
        S.Register()
        W.HideByAtlas(pf)
        assert(pageBg:GetAlpha() == 0 and listBg:GetAlpha() == 0 and art:GetAlpha() == 0,
            "Grund der Seite, der Liste oder Bild hinter dem Rezept noch da")
        local lh = W.ListHeaders[head]
        assert(lh and lh.band and lh.accent == GC.frameAccent, "Kategorie nicht als Abschnitt in Gold")
        PR.Update(pf)
        local a = PR.atmos[cp]
        assert(a and a.on and a.list and a.host == pf and not a.sigil, "Atmosphaere oder Flaeche der Rezeptliste fehlt")
        local r1, r2 = PR.rows[row1], PR.rows[row2]
        assert(r1 and r2 and #r1.hl == 2 and r1.sep and not r1.bar, "Rezeptzeile nicht abgesetzt oder Hervorhebung nicht gefunden")
        local nT = 0
        for _, r in pairs(tints) do
            nT = nT + 1
            assert(r == GC.frameAccent[1], "Hervorhebung des Spiels nicht in Gold getoent")
        end
        assert(nT == 4, "Hervorhebung des Spiels nicht getoent: " .. nT .. " von 4")
        assert(PR.state.selected == "Gewürztes Wolfsfleisch" and r1.sel.on and not r2.sel.on, "gewaehltes Rezept nicht markiert")
        local d = PR.details[det]
        assert(d and d.surface and d.title == title and d.desc == desc, "Rezept nicht als Karte")
        assert(d.db == -80 and d.yOpt == -95 and d.yOptB == -150 and d.cardBottom == -162 and d.optLine.l:IsShown(),
            "Karte falsch: " .. tostring(d.db) .. " " .. tostring(d.yOpt) .. " " .. tostring(d.yOptB) .. " " .. tostring(d.cardBottom))
        S.Gradient = grad
        assert(classy == 0, "Klassenfarbe im Berufsfenster: " .. classy .. " Verlaeufe")
        assert(#touched == 0, "Blizzard-Teile angefasst: " .. table.concat(touched, ", "))
        for _, t in ipairs({ l1, l2, title, desc, need, reagent, hName, minus }) do
            assert(t:IsShown() and t:GetAlpha() == 1, "Inhalt ausgeblendet")
        end
        local rep = table.concat(PR.Report(pf, {}), "\n")
        assert(rep:find("Berufe (Stil ruhig): Liste gefunden, 3 Zeilen (1 Kopfzeilen, 0 mit Balken, 3 mit Namen)", 1, true)
            and rep:find("gewählt: „Gewürztes Wolfsfleisch“", 1, true), "Bericht: " .. rep)
        -- /wcui fenster ueber dem Berufsfenster fragt das Register (W.HOSTED).
        local sr = table.concat(W.SoftReport(pf), "\n")
        assert(sr:find("Berufe (Stil ruhig)", 1, true), "/wcui fenster fragt die Berufe nicht: " .. sr)
        for _ = 1, 3 do PR.Update(pf) end
        collectgarbage("collect")
        collectgarbage("stop")
        local k0 = collectgarbage("count")
        for _ = 1, 20 do PR.Update(pf) end
        local grew = collectgarbage("count") - k0
        collectgarbage("restart")
        print(string.format("    (20 Durchlaeufe Berufe: %.1f KB)", grew))
        assert(grew < 1, string.format("Berufe legen im Takt Muell an: %.1f KB", grew))
        _G.ProfessionsFrame = oldPF
    end)
    Check(okB, "Berufe: Rezeptseite als Register im Berufsfenster, Gold statt Klassenfarbe, Grundbilder weg - nichts verloren, kein Muell"
        .. (okB and "" or (": " .. tostring(errB))))

    -- 6.7.6.0: Berufe, Uebersicht - Karten je Beruf. Nachgebaut wie gemessen:
    -- BookPage.ProfessionsContentFrame mit PrimaryProfession1 (braune
    -- Flaeche, Titel links, Balken, Knopf zum Verlernen) und
    -- SecondaryProfession1 (Bild hinter dem Text, Titel mittig, Rahmen).
    local okO, errO = pcall(function()
        local W, S, PB, PR = WeintCodex.UIWindows, WeintCodex.UIStyle, WeintCodex.UIProfessionBook, WeintCodex.UIProfessions
        local GC = WeintCodex.GameColors
        assert(PB and W.HOSTED.ProfessionsFrame[1] == PR and W.HOSTED.ProfessionsFrame[2] == PB, "Uebersicht nicht am Berufsfenster")
        local touched = {}
        local function Tex(atlas)
            local t = stub.NewObject("Texture")
            t.GetAtlas = function() return atlas end
            return t
        end
        local function Line(text, top, bottom, justify)
            local fs = stub.NewObject("FontString")
            fs._text, fs._font = text, true
            fs.SetText = function() touched[#touched + 1] = "SetText " .. text end
            fs.GetTop, fs.GetBottom = function() return top end, function() return bottom end
            fs.GetStringWidth = function() return 90 end
            fs.GetJustifyH = function() return justify or "LEFT" end
            return fs
        end
        local function Card(top, art, title)
            local card = stub.NewObject("Frame")
            card.GetTop = function() return top end
            card.SetPoint = function() touched[#touched + 1] = "SetPoint Karte" end
            local bar, fill = stub.NewObject("StatusBar"), Tex("Skillbar_Fill_Flipbook_Cooking")
            bar.GetStatusBarTexture = function() return fill end
            bar.SetStatusBarColor = function() touched[#touched + 1] = "Balkenfarbe" end
            local flare = Tex("Skillbar_Flare_Cooking")
            local barText = Line("Kochkunst 8/75", top - 40, top - 52)
            bar.GetRegions = function() return fill, flare, barText end
            card.StatusBar = bar
            local bg = Tex(art)
            card.GetRegions = function() return bg, title end
            return card, bg, bar, fill, flare, barText
        end
        local pf = stub.NewObject("Frame", "ProfessionsFrame")
        local book, content = stub.NewObject("Frame"), stub.NewObject("Frame")
        pf.BookPage, book.ProfessionsContentFrame = book, content
        local t1 = Line("Schmiedekunst", 470, 456, "LEFT")
        t1.GetLeft = function() return 110 end
        local c1, bg1, bar1, fill1, flare1 = Card(480, "Profession-overview-Card", t1)
        c1.GetRight = function() return 470 end
        local unlearn = stub.NewObject("Button")
        local cross = Tex("Profession-button-red-crossmark")
        unlearn.GetRegions = function() return cross end
        c1.UnlearnButton = unlearn
        c1.GetChildren = function() return bar1, unlearn end
        local t2 = Line("Kochkunst", 290, 280, "CENTER")
        local c2, bg2, bar2 = Card(300, "Profession-overview-card-generic-Cooking", t2)
        local nine = stub.NewObject("Frame")
        local nineEdge = stub.NewObject("Texture")
        nine.GetRegions = function() return nineEdge end
        c2.NineSlice = nine
        c2.GetChildren = function() return bar2, nine end
        content.PrimaryProfession1, content.SecondaryProfession1 = c1, c2
        content.GetChildren = function() return c1, c2 end
        book.GetChildren = function() return content end
        pf.GetChildren = function() return book end
        local oldPF = _G.ProfessionsFrame
        _G.ProfessionsFrame = pf

        local grad, classy, goldy = S.Gradient, 0, 0
        S.Gradient = function(t, dir, c, a0, a1)
            if c == K.Highlight() then classy = classy + 1 end
            if c == GC.frameAccent then goldy = goldy + 1 end
            return grad(t, dir, c, a0, a1)
        end
        S.Register()
        W.HideByAtlas(pf)
        assert(bg1:GetAlpha() == 0 and bg2:GetAlpha() == 0, "braune Flaeche oder Bild hinter dem Text noch da")
        PB.Update(pf)
        local p = PB.pages[content]
        assert(p and p.on and p.host == pf and p.vignette.TOP, "Atmosphaere der Uebersicht fehlt")
        local k1, k2 = PB.cards[c1], PB.cards[c2]
        assert(k1 and k2 and k1.body and k1.shadow and k2.body and nineEdge:GetAlpha() == 0, "Karte ohne Flaeche oder Rahmen bleibt")
        assert(k1.title == t1 and k2.title == t2, "Titel der Karten nicht gefunden")
        -- Links: Raute und Linie hinter dem Text; mittig: Linie darunter.
        assert(not k1.centered and k1.dot:IsShown() and k1.line:IsShown() and not k1.orn.dot:IsShown(), "Titel links falsch")
        -- 6.7.8.0: Linie nur links verankert, Breite bis 12 px vor den Rand
        -- der Karte: 470 - 12 - (110 + 90 + 2 * 8 + 3).
        assert(k1.width == 239, "Linie hinter dem Titel falsch breit: " .. tostring(k1.width))
        local pts = {}
        k1.line.SetPoint = function(self, p) pts[#pts + 1] = p end
        t1.GetStringWidth = function() return 100 end
        PB.Update(pf)
        assert(#pts == 1 and pts[1] == "LEFT" and k1.width == 229, "Linie wieder an der Karte verankert: " .. table.concat(pts, ","))
        assert(k2.centered and not k2.dot:IsShown() and k2.orn.dot:IsShown() and k2.y == -27, "Titel mittig falsch: " .. tostring(k2.y))
        assert(k1.bar and k1.bar.how == "Statusbalken" and k2.bar, "Balken ohne Tiefe")
        S.Gradient = grad
        assert(classy == 0 and goldy > 0, "Uebersicht nicht in Gold: Klasse " .. classy .. ", Gold " .. goldy)
        assert(#touched == 0, "Blizzard-Teile angefasst: " .. table.concat(touched, ", "))
        for _, t in ipairs({ t1, t2, bar1, fill1, flare1, unlearn, cross, bar2 }) do
            assert(t:IsShown() and t:GetAlpha() == 1, "Inhalt ausgeblendet")
        end
        local rep = table.concat(PB.Report(pf, {}), "\n")
        assert(rep:find("Berufe, Übersicht (Stil ruhig): 2 Karten, 2 mit Titel (1 mittig), 2 Balken (Füllung Statusbalken)", 1, true)
            and rep:find("„Schmiedekunst“, „Kochkunst“", 1, true), "Bericht: " .. rep)
        for _ = 1, 3 do PB.Update(pf) end
        collectgarbage("collect")
        collectgarbage("stop")
        local k0 = collectgarbage("count")
        for _ = 1, 20 do PB.Update(pf) end
        local grew = collectgarbage("count") - k0
        collectgarbage("restart")
        print(string.format("    (20 Durchlaeufe Berufsuebersicht: %.1f KB)", grew))
        assert(grew < 1, string.format("Uebersicht legt im Takt Muell an: %.1f KB", grew))
        content:Hide()
        PB.Update(pf)
        assert(not p.on and not p.light:IsShown(), "Atmosphaere bleibt ueber der Rezeptseite")
        _G.ProfessionsFrame = oldPF
    end)
    Check(okO, "Berufe, Uebersicht: Karten mit Flaeche, Titel als Abschnitt, Balken mit Tiefe, Gold - nichts verloren, kein Muell"
        .. (okO and "" or (": " .. tostring(errO))))

    -- 6.7.7.0: Zauberbuch - Flaeche, Ueberschrift als Abschnitt in der
    -- Klassenfarbe, ruhige Atmosphaere statt des Scheins der Klasse. Dazu der
    -- Schein im Berufsfenster (Gold): nie. Nachgebaut wie gemessen:
    -- PlayerSpellsFrame.SpellBookFrame.PagedSpellsFrame.View1 mit Eintraegen
    -- (Zauber mit .Button) und einer Ueberschrift (ohne .Button).
    local okZ, errZ = pcall(function()
        local W, S, SB = WeintCodex.UIWindows, WeintCodex.UIStyle, WeintCodex.UISpellBook
        local GC = WeintCodex.GameColors
        assert(SB and W.HOSTED.PlayerSpellsFrame and W.HOSTED.PlayerSpellsFrame[1] == SB, "Zauberbuch nicht am Fenster eingetragen")
        assert(S.SCOPES["PlayerSpellsFrame.SpellBookFrame"] == S.CHARACTER_INFO and not S.SCOPES.PlayerSpellsFrame,
            "Zauberbuch nicht in der Klassenfarbe (oder die Talente gleich mit)")
        local touched = {}
        local function Line(text)
            local fs = stub.NewObject("FontString")
            fs._text, fs._font = text, true
            fs.SetText = function() touched[#touched + 1] = "SetText " .. text end
            fs.SetTextColor = function() touched[#touched + 1] = "Farbe " .. text end
            fs.SetFont = function() touched[#touched + 1] = "Schrift " .. text end
            fs.ClearAllPoints = function() touched[#touched + 1] = "Lage " .. text end
            fs.GetStringWidth = function() return 120 end
            return fs
        end
        local psf = stub.NewObject("Frame", "PlayerSpellsFrame")
        local book, paged, view = stub.NewObject("Frame"), stub.NewObject("Frame"), stub.NewObject("Frame")
        psf.SpellBookFrame, book.PagedSpellsFrame, paged.View1 = book, paged, view
        local head = stub.NewObject("Frame")
        local hText = Line("Allgemein")
        hText.GetLeft = function() return 100 end
        paged.GetRight = function() return 700 end
        head.Text = hText
        head.GetRegions = function() return hText end
        local function Spell(name)
            local e, btn = stub.NewObject("Frame"), stub.NewObject("Button")
            local n = Line(name)
            e.Button = btn
            e.GetRegions = function() return n end
            e.GetChildren = function() return btn end
            return e, n, btn
        end
        local s1, n1, b1 = Spell("Angreifen")
        local s2, n2 = Spell("Werfen")
        view.GetChildren = function() return head, s1, s2 end
        paged.GetChildren = function() return view end
        book.GetChildren = function() return paged end
        psf.GetChildren = function() return book end
        -- Schein der Klasse, wie W.Skin ihn anlegt.
        local glow = stub.NewObject("Texture")
        W.done[psf] = { glow = glow }

        local grad, classy, goldy, classTex = S.Gradient, 0, 0, {}
        S.Gradient = function(t, dir, c, a0, a1)
            if c == K.Highlight() then classy = classy + 1 classTex[t] = true end
            if c == GC.frameAccent then goldy = goldy + 1 end
            return grad(t, dir, c, a0, a1)
        end
        SB.Update(psf)
        W.HoldGlow(psf, "PlayerSpellsFrame")
        S.Gradient = grad
        local b = SB.books[book]
        assert(b and b.on and b.body and b.shadow and b.host == psf and b.vignette.TOP and b.light, "Flaeche oder Atmosphaere fehlt")
        local h = SB.heads[head]
        assert(h and h.fs == hText and h.dot and h.line and b.heads == 1, "Ueberschrift nicht als Abschnitt")
        -- 6.7.8.0: die Linie war im Spiel unsichtbar (rechts an der halben
        -- Hoehe der Seite verankert). Jetzt: links verankert, Breite bis 16 px
        -- vor den Rand der Seite: 700 - 16 - (100 + 120 + 2 * 8 + 3).
        assert(h.width == 445 and h.line:IsShown(), "Linie hinter der Ueberschrift falsch: " .. tostring(h.width))
        -- Neu gelegt (anderer Text): nur EIN Anker, links - keiner an der Seite.
        local pts = {}
        h.line.SetPoint = function(self, p) pts[#pts + 1] = p end
        hText.GetStringWidth = function() return 130 end
        SB.Update(psf)
        assert(#pts == 1 and pts[1] == "LEFT" and h.width == 435, "Linie wieder rechts verankert: " .. table.concat(pts, ","))
        -- 6.10.4.2 im Spiel: Raute zu sehen, Linie nicht. Eine Einheit ist
        -- bei kleiner Skalierung weniger als ein Bildpunkt - die Linie ist
        -- einen Bildpunkt hoch, nie unter einer Einheit, und folgt der
        -- Skalierung (auch ohne neuen Text).
        assert(h.line:GetHeight() == 1, "Linie ohne Bildschirmmass nicht 1 hoch: " .. tostring(h.line:GetHeight()))
        local oldPhys = _G.GetPhysicalScreenSize
        _G.GetPhysicalScreenSize = function() return 1920, 1080 end
        h.line.GetEffectiveScale = function() return 0.5 end   -- 768/1080/0.5 = 1.42 Einheiten je Bildpunkt
        SB.Update(psf)
        assert(math.abs(h.line:GetHeight() - 768 / 1080 / 0.5) < 1e-6, "Linie nicht einen Bildpunkt hoch: " .. tostring(h.line:GetHeight()))
        h.line.GetEffectiveScale = function() return 1.0 end   -- 0.71: eine Einheit ist mehr als ein Bildpunkt
        SB.Update(psf)
        assert(h.line:GetHeight() == 1, "Linie unter einer Einheit: " .. tostring(h.line:GetHeight()))
        h.line.GetEffectiveScale = function() return 0.5 end
        h.line.GetTop = function() return 300 end
        SB.Update(psf)
        local lrep = table.concat(SB.Report(psf, {}), "\n")
        assert(lrep:find("Zauberbuch, Linie: 435 breit, 1.42 hoch = 1.00 Bildpunkte, Oberkante bei Bildpunkt 210.94, sichtbar ja", 1, true),
            "Bericht ohne Linie: " .. lrep)
        -- 6.10.4.3, gemessen mit 6.10.4.2: "1.00 hoch = 1.00 Bildpunkte,
        -- Oberkante bei Bildpunkt 866.50" und nichts zu sehen. Die Kanten
        -- auf halben Bildpunkten - die Linie wird um den Rest verschoben.
        _G.GetPhysicalScreenSize = function() return 1920, 768 end   -- eine Einheit = ein Bildpunkt
        h.line.GetEffectiveScale = function() return 1.0 end
        local top, set = 866.5, {}
        h.lineY = 0   -- der Schritt davor hat sie schon einmal verschoben
        h.line.GetTop = function() return top end
        h.line.SetPoint = function(_, p, rel, rp, x, y) set[#set + 1] = { p, rel, rp, x, y } top = 866.5 + y end
        SB.Update(psf)
        assert(#set == 1 and set[1][1] == "LEFT" and set[1][2] == h.dot and set[1][4] == SB.GAP and math.abs(set[1][5] + 0.5) < 1e-6,
            "Linie nicht auf ganze Bildpunkte gelegt: " .. tostring(set[1] and set[1][5]))
        assert(math.abs(top - 866) < 1e-6, "Oberkante nicht ganz: " .. top)
        SB.Update(psf)
        assert(#set == 1, "Linie je Durchlauf neu gesetzt")
        -- S.PixelY selbst: fast ganz bleibt, wie es ist; der Versatz bleibt
        -- unter einem Bildpunkt (wandert nicht).
        local probe = stub.NewObject("Texture")
        probe.GetEffectiveScale = function() return 1.0 end
        probe.GetTop = function() return 866.004 end
        assert(S.PixelY(probe, 0) == 0, "fast ganze Oberkante verschoben")
        probe.GetTop = function() return 866.5 end
        assert(math.abs(S.PixelY(probe, -0.8) + 0.3) < 1e-6, "Versatz waechst ueber einen Bildpunkt: " .. tostring(S.PixelY(probe, -0.8)))
        probe.GetTop = function() return nil end
        assert(S.PixelY(probe, -0.25) == -0.25, "ohne Lage verschoben")
        local okRep = table.concat(SB.Report(psf, {}), "\n")
        assert(okRep:find("Oberkante bei Bildpunkt 866.00", 1, true), "Bericht: " .. okRep)
        _G.GetPhysicalScreenSize = oldPhys
        h.line.GetEffectiveScale, h.line.GetTop, h.line.SetPoint = nil, nil, nil
        assert(b.edge and W.own[b.edge.l], "Kante ueber der Flaeche fehlt")
        -- Ein bisschen Klassenfarbe: Licht von oben und Kante ueber der Flaeche.
        assert(classTex[b.light] and classTex[b.edge.l] and classTex[b.edge.r], "Licht oder Kante nicht in der Klassenfarbe")
        assert(not SB.heads[s1] and not SB.heads[s2], "Zauber als Ueberschrift gestaltet")
        assert(classy > 0 and goldy == 0, "Zauberbuch nicht in der Klassenfarbe: Klasse " .. classy .. ", Gold " .. goldy)
        assert(not glow:IsShown(), "Schein der Klasse bleibt ueber dem Zauberbuch")
        assert(#touched == 0, "Blizzard-Teile angefasst: " .. table.concat(touched, ", "))
        for _, t in ipairs({ hText, n1, n2, b1 }) do
            assert(t:IsShown() and t:GetAlpha() == 1, "Inhalt ausgeblendet")
        end
        local rep = table.concat(SB.Report(psf, {}), "\n")
        assert(rep:find("Zauberbuch (Stil ruhig, Klasse): Seite gefunden, Fläche ja, Schein der Klasse aus", 1, true)
            and rep:find("Überschriften: „Allgemein“", 1, true), "Bericht: " .. rep)
        for _ = 1, 3 do SB.Update(psf) W.HoldGlow(psf, "PlayerSpellsFrame") end
        collectgarbage("collect")
        collectgarbage("stop")
        local k0 = collectgarbage("count")
        for _ = 1, 20 do SB.Update(psf) W.HoldGlow(psf, "PlayerSpellsFrame") end
        local grew = collectgarbage("count") - k0
        collectgarbage("restart")
        print(string.format("    (20 Durchlaeufe Zauberbuch: %.1f KB)", grew))
        assert(grew < 1, string.format("Zauberbuch legt im Takt Muell an: %.1f KB", grew))
        -- Anderer Reiter (Talente): Schein zurueck, Atmosphaere weg.
        book:Hide()
        SB.Update(psf)
        W.HoldGlow(psf, "PlayerSpellsFrame")
        assert(glow:IsShown() and not b.on and not b.body:IsShown(), "Talente ohne Schein oder mit Flaeche des Zauberbuchs")
        -- Berufsfenster (Gold): der Schein der Klasse nie.
        local pf = stub.NewObject("Frame", "ProfessionsFrame")
        local pglow = stub.NewObject("Texture")
        W.done[pf] = { glow = pglow }
        S.Scope(pf, S.CALM)
        W.HoldGlow(pf, "ProfessionsFrame")
        assert(not pglow:IsShown(), "Schein der Klasse im Berufsfenster (Gold)")
        W.done[psf], W.done[pf] = nil, nil
    end)
    Check(okZ, "Zauberbuch: Flaeche, Ueberschrift als Abschnitt in der Klassenfarbe, Schein der Klasse aus - Berufe ohne Schein"
        .. (okZ and "" or (": " .. tostring(errZ))))

    -- 6.7.8.0: Gilde & Communitys - Gold, drei Spalten auf Flaechen, der
    -- gewaehlte Eintrag links in Gold, kein Schein der Klasse. Nachgebaut
    -- wie gemessen: CommunitiesFrame mit .MemberList, .ChatEditBox, Chat
    -- und der Liste links als CommunitiesFrameCommunitiesList.
    local okG, errG = pcall(function()
        local W, S, CO = WeintCodex.UIWindows, WeintCodex.UIStyle, WeintCodex.UICommunity
        local GC = WeintCodex.GameColors
        assert(CO and W.HOSTED.CommunitiesFrame and W.HOSTED.CommunitiesFrame[1] == CO and S.SCOPES.CommunitiesFrame == S.CALM,
            "Gilde nicht in Gold am Fenster eingetragen")
        local cf = stub.NewObject("Frame", "CommunitiesFrame")
        local list, chat, edit, members = stub.NewObject("Frame"), stub.NewObject("Frame"), stub.NewObject("EditBox"), stub.NewObject("Frame")
        cf.Chat, cf.ChatEditBox, cf.MemberList = chat, edit, members
        -- 6.10.4.3 gemessen: Mitgliederliste mit grauem Rand, Leder hinter
        -- dem Bildlauf und zwei Baendern je Zeile; Rang und Namen bleiben.
        local function FileTex(id)
            local t = stub.NewObject("Texture")
            t.GetTexture = function() return id end
            return t
        end
        local mInset, mNine, mBar = stub.NewObject("Frame"), stub.NewObject("Frame"), stub.NewObject("Frame")
        mInset.NineSlice, members.InsetFrame = mNine, mInset
        local nineEdge = stub.NewObject("Texture")
        mNine.GetRegions = function() return nineEdge end
        -- 6.10.4.4, Ansicht "Mitglieder gross": Spaltenkoepfe mit zweitem Rahmen und Marmor.
        local cols = stub.NewObject("Frame")
        local COLS = { "Background", "InsetBorderTop", "InsetBorderLeft", "InsetBorderTopLeft", "InsetBorderTopRight",
                       "InsetBorderBottomLeft" }   -- gemessen
        for _, k in ipairs(COLS) do cols[k] = stub.NewObject("Texture") end
        members.ColumnDisplay = cols
        mBar.Background, members.ScrollBar = FileTex(374154), mBar
        local mBox, mTarget = stub.NewObject("Frame"), stub.NewObject("Frame")
        mBox.ScrollTarget, members.ScrollBox = mTarget, mBox
        local mRow = stub.NewObject("Button")
        local band1, band2, rankIcon = FileTex(410251), FileTex(131128), FileTex(132061)
        mRow.GetRegions = function() return band1, band2, rankIcon end
        mTarget.GetChildren = function() return mRow end
        -- 6.10.4.2 gemessen: Eingabezeile mit Left/Mid/Right (heller Rahmen).
        edit.Left, edit.Mid, edit.Right = stub.NewObject("Texture"), stub.NewObject("Texture"), stub.NewObject("Texture")
        local oldCL, oldCF = _G.CommunitiesFrameCommunitiesList, _G.CommunitiesFrame
        _G.CommunitiesFrameCommunitiesList, _G.CommunitiesFrame = list, cf
        -- Eintrag links (gewaehlt), wie 6.6.2.3 gemessen.
        local entry = stub.NewObject("Button")
        local pressed = stub.NewObject("Texture")
        pressed.GetAtlas = function() return "communities-nav-button-pressed" end
        entry.GetRegions = function() return pressed end
        list.GetChildren = function() return entry end
        cf.GetChildren = function() return list, chat, members end
        local glow = stub.NewObject("Texture")
        W.done[cf] = { glow = glow }

        local grad, classy, goldy = S.Gradient, 0, 0
        S.Gradient = function(t, dir, c, a0, a1)
            if c == K.Highlight() then classy = classy + 1 end
            if c == GC.frameAccent then goldy = goldy + 1 end
            return grad(t, dir, c, a0, a1)
        end
        S.Register()
        W.HideByAtlas(cf)
        CO.Update(cf)
        W.HoldGlow(cf, "CommunitiesFrame")
        S.Gradient = grad
        local d = CO.frames[cf]
        assert(d and d.vignette.TOP and d.light, "Atmosphaere fehlt")
        for _, key in ipairs({ "Liste", "Chat", "Mitglieder" }) do
            local col = d.cols[key]
            assert(col and col.on and col.body and col.shadow and W.own[col.body], "Spalte ohne Flaeche: " .. key)
        end
        assert(d.cols.Liste.anchor == list and d.cols.Chat.anchor == chat and d.cols.Mitglieder.anchor == members, "Spalten vertauscht")
        assert(W.Entries[entry] and W.Entries[entry].on and W.Entries[entry].accent == GC.frameAccent, "gewaehlter Eintrag nicht in Gold")
        assert(classy == 0 and goldy > 0, "Gilde nicht in Gold: Klasse " .. classy .. ", Gold " .. goldy)
        assert(not glow:IsShown(), "Schein der Klasse ueber der Gilde")
        local rep = table.concat(CO.Report(cf, {}), "\n")
        assert(rep:find("Gilde & Communitys (Stil ruhig): Liste Fläche · Chat Fläche · Mitglieder Fläche · Eingabe flach", 1, true), "Bericht: " .. rep)
        assert(edit.Left:GetAlpha() == 0 and edit.Mid:GetAlpha() == 0 and edit.Right:GetAlpha() == 0 and CO.fields[edit],
            "Eingabezeile behaelt den hellen Rahmen des Spiels")
        assert(mNine:GetAlpha() == 0 and nineEdge:GetAlpha() == 0 and mBar.Background:GetAlpha() == 0, "Rand oder Leder der Mitgliederliste bleibt")
        for _, k in ipairs(COLS) do
            assert(cols[k]:GetAlpha() == 0, "Rahmen oder Marmor der Spaltenkoepfe bleibt: " .. k)
        end
        assert(band1:GetAlpha() == 0 and band2:GetAlpha() == 0 and rankIcon:GetAlpha() == 1, "Baender der Zeile bleiben oder Rang weg")
        assert(not W.Insets[mInset], "Mitgliederliste verdunkelt (6.6.3.3: Normalzustand)")
        assert(rep:find("Zeilen ohne Band 2", 1, true), "Bericht: " .. rep)
        -- 6.10.4.5 gemessen: Reiter "Info" - Pergament, Kopfbalken und
        -- Holzleiste je Flaeche, graue Raender am Rahmen, Leder am Bildlauf.
        local det = stub.NewObject("Frame")
        local function Atl(a)
            local t = stub.NewObject("Texture")
            t.GetAtlas = function() return a end
            return t
        end
        local eL, eTL2, other = Atl("!UI-Frame-InnerLeftTile"), Atl("UI-Frame-InnerTopLeft"), Atl("talents-sheen-node")
        det.GetRegions = function() return eL, eTL2, other end
        local info, news = stub.NewObject("Frame"), stub.NewObject("Frame")
        local parch, head1, bar2 = FileTex(410251), FileTex(410251), FileTex(130968)
        local motd = stub.NewObject("FontString")
        motd._text, motd._font = "Nachricht des Tages", true
        info.GetRegions = function() return parch, head1, bar2, motd end
        local nParch, nBar = FileTex(410251), stub.NewObject("Frame")
        nBar.Background = FileTex(374154)
        news.GetRegions = function() return nParch end
        news.ScrollBar = nBar
        det.Info, det.News = info, news
        cf.GuildDetailsFrame = det
        CO.Update(cf)
        assert(eL:GetAlpha() == 0 and eTL2:GetAlpha() == 0 and other:GetAlpha() == 1, "graue Raender des Info-Reiters bleiben (oder Fremdes weg)")
        assert(parch:GetAlpha() == 0 and head1:GetAlpha() == 0 and bar2:GetAlpha() == 0 and nParch:GetAlpha() == 0
            and W.OwnBgDone[info] and W.OwnBgDone[news], "Pergament oder Leisten im Info-Reiter bleiben")
        assert(nBar.Background:GetAlpha() == 0, "Leder am Bildlauf der News bleibt")
        assert(motd:GetAlpha() == 1, "Ueberschrift im Info-Reiter ausgeblendet")
        local rep3 = table.concat(CO.Report(cf, {}), "\n")
        assert(rep3:find("Info: Flächen 2, Ränder weg 2", 1, true), "Bericht: " .. rep3)
        cf.GuildDetailsFrame = nil
        cf.ChatEditBox = nil
        CO.Update(cf)
        local rep2 = table.concat(CO.Report(cf, {}), "\n")
        assert(rep2:find("Eingabe nicht gefunden", 1, true), "Bericht nennt eine Eingabe, die es nicht gibt: " .. rep2)
        cf.ChatEditBox = edit
        CO.Update(cf)
        -- Andere Ansicht: der Chat geht, seine Flaeche mit.
        chat:Hide()
        CO.Update(cf)
        assert(not d.cols.Chat.on and not d.cols.Chat.body:IsShown() and d.cols.Liste.on, "Flaeche bleibt ohne Chat")
        chat:Show()
        for _ = 1, 3 do CO.Update(cf) end
        collectgarbage("collect")
        collectgarbage("stop")
        local k0 = collectgarbage("count")
        for _ = 1, 20 do CO.Update(cf) W.HoldGlow(cf, "CommunitiesFrame") end
        local grew = collectgarbage("count") - k0
        collectgarbage("restart")
        print(string.format("    (20 Durchlaeufe Gilde: %.1f KB)", grew))
        assert(grew < 1, string.format("Gilde legt im Takt Muell an: %.1f KB", grew))
        _G.CommunitiesFrameCommunitiesList, _G.CommunitiesFrame = oldCL, oldCF
        W.done[cf] = nil
    end)
    Check(okG, "Gilde & Communitys: Gold, drei Spalten auf Flaechen, Eintrag links in Gold, kein Schein der Klasse, kein Muell"
        .. (okG and "" or (": " .. tostring(errG))))

    -- 6.7.9.0: Spielmenue und Dialoge in Gold. Menue: Titel mit Linie
    -- darunter, eine Haarlinie in jeder Luecke zwischen Gruppen von
    -- Knoepfen (gemessen an der Lage), kein Schein der Klasse. Dialog: statt
    -- des Scheins neutrales Licht und Kante in Gold.
    local okM, errM = pcall(function()
        local W, S, GM = WeintCodex.UIWindows, WeintCodex.UIStyle, WeintCodex.UIGameMenu
        local GC = WeintCodex.GameColors
        assert(GM and W.HOSTED.GameMenuFrame and W.HOSTED.GameMenuFrame[1] == GM and S.SCOPES.GameMenuFrame == S.CALM,
            "Spielmenue nicht in Gold am Fenster eingetragen")
        local moved = {}
        local menu = stub.NewObject("Frame")
        menu.GetTop = function() return 500 end
        local header, title = stub.NewObject("Frame"), stub.NewObject("FontString")
        title._text, title._font = "Spielmenü", true
        title.GetBottom = function() return 486 end
        header.Text = title
        menu.Header = header
        -- Drei Gruppen: 1 | 2 3 | 4, Knoepfe 20 hoch, Luecke 12.
        local tops = { 470, 438, 418, 386 }
        local buttons = {}
        for i, t in ipairs(tops) do
            local b = stub.NewObject("Button")
            b.GetTop, b.GetBottom = function() return t end, function() return t - 20 end
            b.SetPoint = function() moved[#moved + 1] = i end
            buttons[i] = b
        end
        menu.GetChildren = function() return header, unpack(buttons) end
        local glow = stub.NewObject("Texture")
        W.done[menu] = { glow = glow }
        local grad, classy = S.Gradient, 0
        S.Gradient = function(t, dir, c, a0, a1)
            if c == K.Highlight() then classy = classy + 1 end
            return grad(t, dir, c, a0, a1)
        end
        S.Scope(menu, S.CALM)
        GM.Update(menu)
        W.HoldGlow(menu, "GameMenuFrame")
        local m = GM.menus[menu]
        assert(m and m.light and m.edge and m.y == -20 and m.orn.dot:IsShown(), "Titel ohne Linie: " .. tostring(m and m.y))
        -- Luecken: 450 -> 438 und 398 -> 386: Linien bei -56 und -108.
        assert(m.groups == 2 and m.lines[1].on and m.lines[2].on and not m.lines[3].on, "Gruppen falsch: " .. tostring(m.groups))
        assert(m.lines[1].y == -56 and m.lines[2].y == -108, "Linie nicht in der Luecke: " .. tostring(m.lines[1].y) .. "/" .. tostring(m.lines[2].y))
        assert(not glow:IsShown() and #moved == 0, "Schein der Klasse bleibt oder Knopf bewegt")
        -- Ein Knopf weg (anderes Menue): eine Linie weniger.
        buttons[1]:Hide()
        GM.Update(menu)
        assert(m.groups == 1 and not m.lines[2].on and not m.lines[2].l:IsShown(), "Linie bleibt ohne Luecke")
        buttons[1]:Show()
        for _ = 1, 3 do GM.Update(menu) end
        collectgarbage("collect")
        collectgarbage("stop")
        local k0 = collectgarbage("count")
        for _ = 1, 20 do GM.Update(menu) W.HoldGlow(menu, "GameMenuFrame") end
        local grew = collectgarbage("count") - k0
        collectgarbage("restart")
        print(string.format("    (20 Durchlaeufe Spielmenue: %.1f KB)", grew))
        assert(grew < 1, string.format("Spielmenue legt im Takt Muell an: %.1f KB", grew))
        local rep = table.concat(GM.Report(menu, {}), "\n")
        assert(rep:find("Spielmenü (Stil ruhig): Titel gefunden, Trennlinien 2", 1, true), "Bericht: " .. rep)
        -- Dialog: kein Schein der Klasse, Licht neutral, Kante in Gold.
        local pop = stub.NewObject("Frame", "StaticPopup3")
        _G.StaticPopup3 = pop
        local oldUC, oldRCC = _G.UnitClass, _G.RAID_CLASS_COLORS
        _G.UnitClass = function() return "Krieger", "WARRIOR", 1 end
        _G.RAID_CLASS_COLORS = { WARRIOR = { r = 0.78, g = 0.61, b = 0.43 } }
        local goldy = 0
        S.Gradient = function(t, dir, c, a0, a1)
            if c == K.Highlight() then classy = classy + 1 end
            if c == GC.frameAccent then goldy = goldy + 1 end
            return grad(t, dir, c, a0, a1)
        end
        local d = W.SkinPopup(pop)
        S.Gradient = grad
        _G.UnitClass, _G.RAID_CLASS_COLORS = oldUC, oldRCC
        _G.StaticPopup3 = nil
        assert(d and not d.glow and d.light and d.edge and goldy > 0, "Dialog mit Schein der Klasse oder ohne Kante in Gold")
        assert(classy == 0, "Klassenfarbe in Menue oder Dialog: " .. classy)
        W.done[menu] = nil
    end)
    Check(okM, "Spielmenue und Dialoge: Gold, Linie unter dem Titel, Haarlinien zwischen Gruppen, kein Schein der Klasse"
        .. (okM and "" or (": " .. tostring(errM))))

    -- 6.8.0.4: Gespraeche in Gold. Beta-Test 6.8.0.3: ueber dem Gespraech lag
    -- der Schein der Klasse (brauner Verlauf beim Krieger). Jetzt aus; Licht
    -- und Kante in Gold, Begruessung und Optionen auf einer Flaeche.
    local okG, errG = pcall(function()
        local W, S, GS, GC = WeintCodex.UIWindows, WeintCodex.UIStyle, WeintCodex.UIGossip, WeintCodex.GameColors
        for _, n in ipairs({ "GossipFrame", "QuestFrame", "ItemTextFrame" }) do
            assert(GS and S.SCOPES[n] == S.CALM and W.HOSTED[n] and W.HOSTED[n][1] == GS, n .. " nicht in Gold eingetragen")
        end
        local gf = stub.NewObject("Frame", "GossipFrame")
        local panel, box, bar = stub.NewObject("Frame"), stub.NewObject("Frame"), stub.NewObject("Frame")
        gf.GreetingPanel, panel.ScrollBox, panel.ScrollBar = panel, box, bar
        local opt = stub.NewObject("FontString")
        opt._text, opt._font = "Das Auktionshaus", true
        opt.SetTextColor = function() error("Farbe einer Option ueberschrieben") end
        box.GetRegions = function() return opt end
        panel.GetChildren = function() return box, bar end
        gf.GetChildren = function() return panel end
        local oldGF = _G.GossipFrame
        _G.GossipFrame = gf
        S.Register()
        local glow = stub.NewObject("Texture")
        W.done[gf] = { glow = glow }
        local grad, gold = S.Gradient, {}
        S.Gradient = function(t, dir, c, a0, a1)
            if c == GC.frameAccent then gold[t] = true end
            return grad(t, dir, c, a0, a1)
        end
        GS.Update(gf)
        S.Gradient = grad
        W.HoldGlow(gf, "GossipFrame")
        local w = GS.windows[gf]
        assert(not glow:IsShown(), "Schein der Klasse ueber dem Gespraech")
        assert(w and w.light and gold[w.edge.l] and gold[w.edge.r], "Kante oben nicht in Gold")
        assert(w.card and w.card.on and w.card.body._parent == gf and gold[w.card.edge.l], "Gespraech nicht auf Flaeche mit Kante in Gold")
        assert(opt:IsShown() and opt:GetAlpha() == 1, "Option angefasst")
        local rep = table.concat(GS.Report(gf, {}), "\n")
        assert(rep:find("Gespräch (Stil ruhig): Kante in Gold, kein Schein der Klasse, Gespräch auf Fläche", 1, true), "Bericht: " .. rep)
        box:Hide()
        GS.Update(gf)
        assert(not w.card.on and not w.card.body:IsShown(), "Flaeche bleibt ohne Gespraech")
        box:Show()
        collectgarbage("collect")
        collectgarbage("stop")
        local k0 = collectgarbage("count")
        for _ = 1, 20 do GS.Update(gf) W.HoldGlow(gf, "GossipFrame") end
        local grew = collectgarbage("count") - k0
        collectgarbage("restart")
        assert(grew < 1, string.format("Gespraech legt im Takt Muell an: %.1f KB", grew))
        -- Questtext (ungemessen): Gold und Kante, keine Flaeche.
        local qf = stub.NewObject("Frame", "QuestFrame")
        GS.Update(qf)
        assert(GS.windows[qf] and not GS.windows[qf].card, "Questtext mit geratener Flaeche")
        W.done[gf] = nil
        _G.GossipFrame = oldGF
    end)
    Check(okG, "Gespraeche: Gold, kein Schein der Klasse, Gespraech auf Flaeche, kein Muell"
        .. (okG and "" or (": " .. tostring(errG))))

    -- 6.8.0.6: Haendler in Gold. Beta-Test 6.8.0.4: Schein der Klasse ueber
    -- den Waren, Leder unter dem Geld, Reiter des Spiels. Jetzt Gold, Waren
    -- auf Flaeche (bis zur letzten sichtbaren), Geld als Innenflaeche,
    -- Reiter flach, der gewaehlte in Gold; die Plaetze selbst bleiben.
    local okM, errM = pcall(function()
        local W, S, MC, GC = WeintCodex.UIWindows, WeintCodex.UIStyle, WeintCodex.UIMerchant, WeintCodex.GameColors
        assert(MC and S.SCOPES.MerchantFrame == S.CALM and W.HOSTED.MerchantFrame and W.HOSTED.MerchantFrame[1] == MC,
            "Haendler nicht in Gold eingetragen")
        local mf = stub.NewObject("Frame", "MerchantFrame")
        local saved = {}
        local function Global(name, obj) saved[name] = _G[name] _G[name] = obj return obj end
        Global("MerchantFrame", mf)
        local items = {}
        for i = 1, 12 do
            local it = Global("MerchantItem" .. i, stub.NewObject("Frame"))
            local slot = stub.NewObject("Texture")
            slot.SetVertexColor = function() error("Farbe eines Platzes ueberschrieben") end
            it.GetRegions = function() return slot end
            it._slot = slot
            if i > 10 then it:Hide() end
            items[i] = it
        end
        local money = Global("MerchantMoneyInset", stub.NewObject("Frame"))
        local leather = stub.NewObject("Texture")
        money.GetRegions = function() return leather end
        local mbg = Global("MerchantMoneyBg", stub.NewObject("Frame"))
        local mbgTex = stub.NewObject("Texture")
        mbg.GetRegions = function() return mbgTex end
        local tabs = {}
        for i = 1, 2 do
            local tab = Global("MerchantFrameTab" .. i, stub.NewObject("Button"))
            tab.GetID = function() return i end
            tab.LeftActive = stub.NewObject("Texture")
            -- PanelTabButton kennt weder isSelected noch IsSelected; die
            -- Attrappe gaebe fuer fehlende Felder bei jedem Zugriff eine neue
            -- Funktion zurueck (Muell, den es im Spiel nicht gibt).
            tab.isSelected, tab.IsSelected = false, false
            tabs[i] = tab
        end
        mf.selectedTab = 1
        S.Register()
        local glow = stub.NewObject("Texture")
        W.done[mf] = { glow = glow }
        local grad, gold = S.Gradient, {}
        S.Gradient = function(t, dir, c, a0, a1)
            if c == GC.frameAccent then gold[t] = true end
            return grad(t, dir, c, a0, a1)
        end
        MC.Update(mf)
        S.Gradient = grad
        W.HoldGlow(mf, "MerchantFrame")
        local m = MC.shops[mf]
        assert(not glow:IsShown(), "Schein der Klasse ueber dem Haendler")
        assert(gold[m.edge.l] and m.goods and m.goods.on and gold[m.goods.edge.l], "Kanten nicht in Gold")
        assert(m.goods.last == items[10], "Flaeche nicht bis zur letzten Ware (Haendler: 10)")
        assert(leather:GetAlpha() == 0 and mbgTex:GetAlpha() == 0 and W.Insets[money], "Geld nicht auf Innenflaeche")
        assert(tabs[1].LeftActive:GetAlpha() == 0, "Reiter des Spiels bleibt")
        local sk1, sk2 = W.TabSkin[tabs[1]], W.TabSkin[tabs[2]]
        assert(sk1 and sk2 and sk1.accent == GC.frameAccent and sk2.accent == nil, "gewaehlter Reiter nicht in Gold")
        for i = 1, 10 do assert(items[i]._slot:GetAlpha() == 1, "Platz einer Ware angefasst") end
        -- Rueckkauf: zwoelf Plaetze, zweiter Reiter gewaehlt.
        items[11]:Show() items[12]:Show()
        mf.selectedTab = 2
        MC.Update(mf)
        assert(m.goods.last == items[12] and W.TabSkin[tabs[2]].accent == GC.frameAccent and W.TabSkin[tabs[1]].accent == nil,
            "Rueckkauf: Flaeche oder Reiter folgt nicht")
        local rep = table.concat(MC.Report(mf, {}), "\n")
        assert(rep:find("Händler (Stil ruhig): Kante in Gold, kein Schein der Klasse · Waren auf Fläche · Geld auf Innenfläche · Reiter 2", 1, true),
            "Bericht: " .. rep)
        collectgarbage("collect")
        collectgarbage("stop")
        local k0 = collectgarbage("count")
        for _ = 1, 20 do MC.Update(mf) W.HoldGlow(mf, "MerchantFrame") end
        local grew = collectgarbage("count") - k0
        collectgarbage("restart")
        assert(grew < 1, string.format("Haendler legt im Takt Muell an: %.1f KB", grew))
        W.done[mf] = nil
        for name, v in pairs(saved) do _G[name] = v end
    end)
    Check(okM, "Haendler: Gold, kein Schein der Klasse, Waren auf Flaeche, Geld als Innenflaeche, Reiter flach in Gold, kein Muell"
        .. (okM and "" or (": " .. tostring(errM))))

    -- 6.9.0.0: Beute und Optionen in Gold. Beta-Test: Metallrahmen, Sand,
    -- Karten mit Rahmen im Beutefenster; Metall, brauner Rahmen und braune
    -- Kategorie-Balken in den Optionen des Spiels.
    local okL, errL = pcall(function()
        local W, S, LT, LF, GC = WeintCodex.UIWindows, WeintCodex.UIStyle, WeintCodex.UILoot, WeintCodex.UICalm, WeintCodex.GameColors
        local listed = {}
        for _, n in ipairs(W.WINDOWS) do listed[n] = true end
        assert(listed.LootFrame and listed.SettingsPanel, "Beute oder Optionen nicht im Fensterdurchlauf")
        assert(LT and S.SCOPES.LootFrame == S.CALM and W.HOSTED.LootFrame and W.HOSTED.LootFrame[1] == LT, "Beute nicht in Gold eingetragen")
        assert(S.SCOPES.SettingsPanel == S.CALM and W.HOSTED.SettingsPanel and W.HOSTED.SettingsPanel[1] == LF, "Optionen nicht in Gold eingetragen")
        -- Was weg muss, was bleibt.
        for _, a in ipairs({ "Looting_ItemCard_BG", "Looting_ItemCard_Stroke_Normal", "Looting_RarityTag_Frame",
                             "UIFrameBackground-NineSlice-CornerBottomLeft", "Options_InnerFrame", "Options_CategoryHeader_2",
                             "!UI-Frame-Metal-EdgeLeft", "UI-Frame-Metal-CornerTopRight" }) do
            assert(W.HidesAtlas(a), a .. " bleibt")
        end
        for _, a in ipairs({ "Looting_ItemCard_Stroke_Highlight", "Looting_ItemCard_Stroke_Epic", "Options_List_Active",
                             "checkbox-minimal", "checkmark-minimal", "_Minimal_SliderBar_Middle", "common-dropdown-c-button" }) do
            assert(not W.HidesAtlas(a), a .. " ausgeblendet, sagt aber etwas")
        end
        assert(W.HeaderAtlas("Options_CategoryHeader_1"), "Kategorie der Optionen wird kein Abschnitt")

        -- Beute: Liste auf Flaeche, Titel hell, kein Schein der Klasse.
        local lf = stub.NewObject("Frame", "LootFrame")
        local box = stub.NewObject("Frame")
        lf.ScrollBox = box
        local tc = stub.NewObject("Frame")
        local ttl = stub.NewObject("FontString")
        ttl._text, ttl._font = "Gegenstände", true
        local col
        ttl.SetTextColor = function(_, r, g, b) col = { r, g, b } end
        tc.TitleText = ttl
        lf.TitleContainer = tc
        local oldLF = _G.LootFrame
        _G.LootFrame = lf
        S.Register()
        local glow = stub.NewObject("Texture")
        W.done[lf] = { glow = glow }
        local grad, gold = S.Gradient, {}
        S.Gradient = function(t, dir, c, a0, a1)
            if c == GC.frameAccent then gold[t] = true end
            return grad(t, dir, c, a0, a1)
        end
        LT.Update(lf)
        S.Gradient = grad
        W.HoldGlow(lf, "LootFrame")
        local w = LT.windows[lf]
        assert(not glow:IsShown(), "Schein der Klasse ueber der Beute")
        assert(w and gold[w.edge.l] and w.card and w.card.on and gold[w.card.edge.l], "Beute nicht auf Flaeche mit Kante in Gold")
        assert(col and col[1] == WeintCodex.Colors.textBright[1], "Titel nicht hell")
        local rep = table.concat(LT.Report(lf, {}), "\n")
        assert(rep:find("Beute (Stil ruhig): Kante in Gold, kein Schein der Klasse · Titel hell · Liste auf Fläche", 1, true), "Bericht: " .. rep)
        box:Hide()
        LT.Update(lf)
        for _, t in ipairs(w.card.parts) do assert(not t:IsShown(), "Flaeche, Schatten oder Kante bleibt ohne Liste") end
        assert(not w.card.on, "Flaeche gilt ohne Liste als offen")
        box:Show()
        collectgarbage("collect")
        collectgarbage("stop")
        local k0 = collectgarbage("count")
        for _ = 1, 20 do LT.Update(lf) W.HoldGlow(lf, "LootFrame") end
        local grew = collectgarbage("count") - k0
        collectgarbage("restart")
        assert(grew < 1, string.format("Beute legt im Takt Muell an: %.1f KB", grew))
        W.done[lf] = nil
        _G.LootFrame = oldLF

        -- Optionen: Kategorien und Einstellungen als Innenflaechen, Titel
        -- hell, Kategorie-Balken als Abschnitt in Gold.
        local sp = stub.NewObject("Frame", "SettingsPanel")
        local cats, cont, ns = stub.NewObject("Frame"), stub.NewObject("Frame"), stub.NewObject("Frame")
        local catTex, contTex = stub.NewObject("Texture"), stub.NewObject("Texture")
        cats.GetRegions = function() return catTex end
        cont.GetRegions = function() return contTex end
        cats.GetParent = function() return sp end
        cont.GetParent = function() return sp end
        local head = stub.NewObject("Button")
        local hBg = stub.NewObject("Texture")
        hBg.GetAtlas = function() return "Options_CategoryHeader_1" end
        hBg._width = 180
        local hName = stub.NewObject("FontString")
        hName._text, hName._font = "Gameplay", true
        head.GetRegions = function() return hBg, hName end
        cats.GetChildren = function() return head end
        sp.GetChildren = function() return cats, cont end
        local nsText = stub.NewObject("FontString")
        nsText._text, nsText._font = "Optionen", true
        local nsCol
        nsText.SetTextColor = function(_, r) nsCol = r end
        ns.Text = nsText
        sp.CategoryList, sp.Container, sp.NineSlice = cats, cont, ns
        local oldSP = _G.SettingsPanel
        _G.SettingsPanel = sp
        S.Register()
        W.done[sp] = { glow = stub.NewObject("Texture") }
        LF.Update(sp)
        W.HideByAtlas(sp)
        LF.Update(sp)
        assert(W.Insets[cats] and W.Insets[cont] and catTex:GetAlpha() == 0 and contTex:GetAlpha() == 0,
            "Kategorien oder Einstellungen nicht auf Innenflaeche")
        assert(nsCol == WeintCodex.Colors.textBright[1], "Titel der Optionen nicht hell")
        assert(hBg:GetAlpha() == 0, "brauner Kategorie-Balken bleibt")
        local lh = W.ListHeaders[head]
        assert(lh and lh.accent == GC.frameAccent, "Kategorie nicht als Abschnitt in Gold")
        assert((LF.windows[sp].decks or 0) == 2, "Innenflaechen ohne Kante in Gold: " .. tostring(LF.windows[sp].decks))
        W.done[sp] = nil
        _G.SettingsPanel = oldSP
    end)
    Check(okL, "Beute und Optionen: Gold, Metall und Sand weg, Beute auf Flaeche, Optionen auf Innenflaechen, Kategorien als Abschnitte, kein Muell"
        .. (okL and "" or (": " .. tostring(errL))))

    -- 6.10.4.2, gemessen 05.10.2026: die Sammlung trug am Reiter
    -- "Gegenstaende" noch das Gold des Spiels (uiframe-activetab-*).
    local okCJ, errCJ = pcall(function()
        local W, LF, GC = WeintCodex.UIWindows, WeintCodex.UICalm, WeintCodex.GameColors
        local saved = {}
        local function Global(name, obj) saved[name] = _G[name] _G[name] = obj return obj end
        local cj = Global("CollectionsJournal", stub.NewObject("Frame", "CollectionsJournal"))
        local wf = Global("WardrobeCollectionFrame", stub.NewObject("Frame"))
        local function Tab(name)
            local t = Global(name, stub.NewObject("Button", name))
            for _, k in ipairs({ "LeftActive", "MiddleActive", "RightActive", "LeftHighlight" }) do
                t[k] = stub.NewObject("Texture")
            end
            return t
        end
        local t1, t2 = Tab("WardrobeCollectionFrameTab1"), Tab("WardrobeCollectionFrameTab2")
        wf.selectedTab = 1
        W.done[cj] = { glow = stub.NewObject("Texture") }
        LF.Update(cj)
        assert(t1.LeftActive:GetAlpha() == 0 and t1.MiddleActive:GetAlpha() == 0 and t2.RightActive:GetAlpha() == 0,
            "Gold des Spiels am Reiter der Sammlung bleibt")
        assert(W.TabSkin[t1] and W.TabSkin[t1].accent == GC.frameAccent and W.TabSkin[t2].accent == nil, "gewaehlter Reiter der Sammlung nicht in Gold")
        wf.selectedTab = 2
        LF.Update(cj)
        assert(W.TabSkin[t2].accent == GC.frameAccent and W.TabSkin[t1].accent == nil, "Reiter der Sammlung folgt der Wahl nicht")
        local rep = table.concat(LF.Report(cj, {}), "\n")
        assert(rep:find("Sammlung (Stil ruhig): 0 Innenflächen mit Kante in Gold (keine gefunden) · Reiter oben 2", 1, true), "Bericht: " .. rep)
        W.done[cj], LF.windows[cj] = nil, nil
        for name, old in pairs(saved) do _G[name] = old end
    end)
    Check(okCJ, "Sammlung: Reiter oben flach, der gewaehlte in Gold" .. (okCJ and "" or (": " .. tostring(errCJ))))

    -- 6.9.0.0: Makrofenster in Gold. Beta-Test: Metallrahmen, Marmor,
    -- Leder, Steinplaetze, Reiter des Spiels.
    local okMF, errMF = pcall(function()
        local W, S, MF, LF, GC = WeintCodex.UIWindows, WeintCodex.UIStyle, WeintCodex.UIMacroFrame, WeintCodex.UICalm, WeintCodex.GameColors
        local listed = false
        for _, n in ipairs(W.WINDOWS) do if n == "MacroFrame" then listed = true end end
        assert(listed and MF and S.SCOPES.MacroFrame == S.CALM, "Makrofenster nicht im Durchlauf oder nicht in Gold")
        local hosts = {}
        for _, h in ipairs(W.HOSTED.MacroFrame or {}) do hosts[h] = true end
        assert(hosts[MF] and hosts[LF], "Makrofenster ohne Plaetze/Reiter oder ohne Innenflaechen")
        local saved = {}
        local function Global(name, obj) saved[name] = _G[name] _G[name] = obj return obj end
        local mf = Global("MacroFrame", stub.NewObject("Frame", "MacroFrame"))
        local selector, btn = stub.NewObject("Frame"), stub.NewObject("CheckButton")
        local stone, icon = stub.NewObject("Texture"), stub.NewObject("Texture")
        stone.GetTexture = function() return 130764 end
        icon.GetTexture = function() return 136243 end
        btn.GetRegions = function() return stone, icon end
        selector.GetChildren = function() return btn end
        local inset = Global("MacroFrameInset", stub.NewObject("Frame"))
        local leather = stub.NewObject("Texture")
        inset.GetRegions = function() return leather end
        inset.GetParent = function() return mf end
        local textBg = Global("MacroFrameTextBackground", stub.NewObject("Frame"))
        textBg.GetParent = function() return mf end
        mf.GetChildren = function() return selector, inset, textBg end
        local tabs = {}
        for i = 1, 2 do
            local tab = Global("MacroFrameTab" .. i, stub.NewObject("Button"))
            tab.LeftActive = stub.NewObject("Texture")
            tab.isSelected, tab.IsSelected = false, false
            tabs[i] = tab
        end
        mf.selectedTab = 1
        S.Register()
        local glow = stub.NewObject("Texture")
        W.done[mf] = { glow = glow }
        local grad, gold = S.Gradient, {}
        S.Gradient = function(t, dir, c, a0, a1)
            if c == GC.frameAccent then gold[t] = true end
            return grad(t, dir, c, a0, a1)
        end
        LF.Update(mf)
        MF.Update(mf)
        LF.Update(mf)
        S.Gradient = grad
        W.HoldGlow(mf, "MacroFrame")
        local m = MF.frames[mf]
        assert(not glow:IsShown(), "Schein der Klasse ueber den Makros")
        assert(m and gold[m.edge.l], "Kante oben nicht in Gold")
        assert(stone:GetAlpha() == 0 and MF.slots[btn], "Stein unter dem Platz bleibt oder Platz nicht flach")
        assert(icon:GetAlpha() == 1 and btn:GetAlpha() == 1, "Symbol oder Platz eines Makros ausgeblendet")
        assert(W.Insets[inset] and W.Insets[textBg] and leather:GetAlpha() == 0, "Liste oder Textfeld nicht auf Innenflaeche")
        assert((LF.windows[mf].decks or 0) == 2, "Innenflaechen ohne Kante in Gold")
        local sk1, sk2 = W.TabSkin[tabs[1]], W.TabSkin[tabs[2]]
        assert(sk1 and sk2 and sk1.accent == GC.frameAccent and sk2.accent == nil, "gewaehlter Reiter nicht in Gold")
        local rep = table.concat(MF.Report(mf, {}), "\n")
        assert(rep:find("Makros (Stil ruhig): Kante in Gold, kein Schein der Klasse · Plätze flach 1 · Reiter 2", 1, true), "Bericht: " .. rep)
        collectgarbage("collect")
        collectgarbage("stop")
        local k0 = collectgarbage("count")
        for _ = 1, 20 do MF.Update(mf) LF.Update(mf) W.HoldGlow(mf, "MacroFrame") end
        local grew = collectgarbage("count") - k0
        collectgarbage("restart")
        assert(grew < 1, string.format("Makrofenster legt im Takt Muell an: %.1f KB", grew))
        W.done[mf] = nil
        for name, v in pairs(saved) do _G[name] = v end
    end)
    Check(okMF, "Makrofenster: Gold, Plaetze flach, Symbole bleiben, Liste und Textfeld als Innenflaechen, Reiter in Gold, kein Muell"
        .. (okMF and "" or (": " .. tostring(errMF))))

    -- 6.9.0.2: Handel in Gold. Beta-Test 6.9.0.1: Metallrahmen, Marmor,
    -- Leder, Steinplaetze, Namensfelder, Portraets.
    local okTR, errTR = pcall(function()
        local W, S, TR, LF, GC = WeintCodex.UIWindows, WeintCodex.UIStyle, WeintCodex.UITrade, WeintCodex.UICalm, WeintCodex.GameColors
        local listed = false
        for _, n in ipairs(W.WINDOWS) do if n == "TradeFrame" then listed = true end end
        assert(listed and TR and S.SCOPES.TradeFrame == S.CALM, "Handel nicht im Durchlauf oder nicht in Gold")
        local hosts = {}
        for _, h in ipairs(W.HOSTED.TradeFrame or {}) do hosts[h] = true end
        assert(hosts[TR] and hosts[LF], "Handel ohne Plaetze oder ohne Kante an den Innenflaechen")
        local saved = {}
        local function Global(name, obj) saved[name] = _G[name] _G[name] = obj return obj end
        local function Tex(id) local t = stub.NewObject("Texture") t._file = id t.GetTexture = function(self) return self._file end return t end
        local tf = Global("TradeFrame", stub.NewObject("Frame", "TradeFrame"))
        -- Ein Platz: Rahmen mit Stein/Namensfeld, Knopf mit Rand, leerem Platz und Symbol.
        local item, btn = stub.NewObject("Frame"), stub.NewObject("Button")
        local slotBg, nameBg = Tex(130766), Tex(136796)
        item.GetRegions = function() return slotBg, nameBg end
        -- Das Symbol traegt (leer) dasselbe Bild wie der leere Platz - es
        -- darf trotzdem nie ausgeblendet werden.
        local rim, empty, icon = Tex(130718), Tex(130841), Tex(130841)
        btn.icon = icon
        btn.GetRegions = function() return rim, empty, icon end
        item.GetChildren = function() return btn end
        -- Eine Innenflaeche (InsetFrameTemplate) und der Grund des Gelds.
        local inset = stub.NewObject("Frame")
        inset.Bg, inset.NineSlice = Tex(374154), stub.NewObject("Frame")
        inset.GetRegions = function() return inset.Bg end
        inset.GetParent = function() return tf end
        local money = Global("TradeRecipientMoneyBg", stub.NewObject("Frame"))
        local moneyTex = Tex(525911)
        money.GetRegions = function() return moneyTex end
        money.GetParent = function() return tf end
        tf.GetChildren = function() return item, inset end
        local pName = Global("TradeFramePlayerNameText", stub.NewObject("FontString"))
        local colored
        pName.SetTextColor = function(_, r) colored = r end
        S.Register()
        local glow = stub.NewObject("Texture")
        W.done[tf] = { glow = glow }
        local grad, gold = S.Gradient, {}
        S.Gradient = function(t, dir, c, a0, a1)
            if c == GC.frameAccent then gold[t] = true end
            return grad(t, dir, c, a0, a1)
        end
        TR.Update(tf)
        LF.Update(tf)
        S.Gradient = grad
        W.HoldGlow(tf, "TradeFrame")
        local m = TR.frames[tf]
        assert(not glow:IsShown(), "Schein der Klasse ueber dem Handel")
        assert(m and gold[m.edge.l], "Kante oben nicht in Gold")
        assert(slotBg:GetAlpha() == 0 and rim:GetAlpha() == 0 and empty:GetAlpha() == 0, "Stein, Rand oder leerer Platz bleibt")
        assert(TR.flat[btn] and not TR.flat[item], "Knopf nicht flach (oder der ganze Platz statt des Knopfs)")
        assert(nameBg:GetAlpha() == 0 and TR.strips[nameBg], "Namensfeld nicht als Leiste")
        assert(icon:GetAlpha() == 1 and btn:GetAlpha() == 1 and item:GetAlpha() == 1, "Symbol oder Platz ausgeblendet")
        assert(W.Insets[inset] and inset.Bg:GetAlpha() == 0, "Leder bleibt / keine Innenflaeche")
        assert(W.Insets[money] and moneyTex:GetAlpha() == 0, "Grund des Gelds nicht auf Flaeche")
        assert((LF.windows[tf].decks or 0) == 2, "Innenflaechen ohne Kante in Gold: " .. tostring(LF.windows[tf].decks))
        assert(colored == C.textBright[1], "Name oben nicht hell")
        -- Ein Gegenstand im Platz: die Region zeigt etwas anderes - wieder sichtbar.
        empty._file = 135274
        TR.Update(tf)
        assert(empty:GetAlpha() == 1 and not TR.hidden[empty], "Bild eines Gegenstands bleibt unsichtbar")
        assert(rim:GetAlpha() == 0, "Rand kommt mit zurueck")
        -- Wieder leer: wieder weg.
        empty._file = 130841
        TR.Update(tf)
        assert(empty:GetAlpha() == 0, "leerer Platz kommt nicht wieder weg")
        -- Ruhe im Takt: was ausgeblendet ist, wird nicht je Durchlauf neu gesetzt.
        local sets = 0
        local rsa = rim.SetAlpha
        rim.SetAlpha = function(self, a) sets = sets + 1 return rsa(self, a) end
        for _ = 1, 5 do TR.Update(tf) end
        rim.SetAlpha = rsa
        assert(sets == 0, "Rand je Durchlauf neu gesetzt: " .. sets)
        local rep = table.concat(TR.Report(tf, {}), "\n")
        assert(rep:find("Handel (Stil ruhig): Kante in Gold, kein Schein der Klasse · Plätze flach 1 · Namensfelder 1 · Innenflächen 1 · Geld auf Fläche · Namen hell 1", 1, true), "Bericht: " .. rep)
        collectgarbage("collect")
        collectgarbage("stop")
        local k0 = collectgarbage("count")
        for _ = 1, 20 do TR.Update(tf) LF.Update(tf) W.HoldGlow(tf, "TradeFrame") end
        local grew = collectgarbage("count") - k0
        collectgarbage("restart")
        assert(grew < 1, string.format("Handel legt im Takt Muell an: %.1f KB", grew))
        W.done[tf] = nil
        for name, v in pairs(saved) do _G[name] = v end
    end)
    Check(okTR, "Handel: Gold, Plaetze flach, Symbole bleiben, Namensfelder als Leiste, Innenflaechen und Geld auf Flaeche, kein Muell"
        .. (okTR and "" or (": " .. tostring(errTR))))

    -- 6.9.0.4: Auktionshaus in Gold. Beta-Test 6.9.0.3: Metallrahmen,
    -- Marmor, braune Kategorien, Lederlisten, Spaltenkoepfe aus Holz.
    local okAH, errAH = pcall(function()
        local W, S, AH, LF, GC = WeintCodex.UIWindows, WeintCodex.UIStyle, WeintCodex.UIAuction, WeintCodex.UICalm, WeintCodex.GameColors
        local listed = false
        for _, n in ipairs(W.WINDOWS) do if n == "AuctionHouseFrame" then listed = true end end
        assert(listed and AH and S.SCOPES.AuctionHouseFrame == S.CALM, "Auktionshaus nicht im Durchlauf oder nicht in Gold")
        local hosts = {}
        for _, h in ipairs(W.HOSTED.AuctionHouseFrame or {}) do hosts[h] = true end
        assert(hosts[AH] and hosts[LF], "Auktionshaus ohne eigene Teile oder ohne Kante an den Innenflaechen")
        local saved = {}
        local function Global(name, obj) saved[name] = _G[name] _G[name] = obj return obj end
        local function Tex(atlas, file)
            local t = stub.NewObject("Texture")
            t.GetAtlas = function() return atlas end
            t.GetTexture = function() return file end
            return t
        end
        local ah = Global("AuctionHouseFrame", stub.NewObject("Frame", "AuctionHouseFrame"))
        -- Kategorien: Liste mit Grund, ein Eintrag (gewaehlt) und einer nicht.
        local cats, scroll = stub.NewObject("Frame"), stub.NewObject("Frame")
        local catBg = Tex("auctionhouse-background-categories")
        cats.GetRegions = function() return catBg end
        cats.GetParent = function() return ah end
        local navA, navB = stub.NewObject("Button"), stub.NewObject("Button")
        local aNormal, aSel = Tex("auctionhouse-nav-button"), Tex("auctionhouse-nav-button-select")
        aSel:Show()
        navA.GetRegions = function() return aNormal, aSel end
        local bNormal, bSel = Tex("auctionhouse-nav-button"), Tex("auctionhouse-nav-button-select")
        bSel:Hide()
        navB.GetRegions = function() return bNormal, bSel end
        scroll.GetChildren = function() return navA, navB end
        cats.GetChildren = function() return scroll end
        -- Ergebnisliste mit Grund und einem Spaltenkopf (Holz + Sortierpfeil).
        local list, headBtn = stub.NewObject("Frame"), stub.NewObject("Button")
        local listBg = Tex("auctionhouse-background-index")
        list.GetRegions = function() return listBg end
        list.GetParent = function() return ah end
        local wood, arrow = Tex(nil, 131139), Tex(nil, 136580)
        headBtn.GetRegions = function() return wood, arrow end
        list.GetChildren = function() return headBtn end
        -- Geld.
        local border, inset = stub.NewObject("Frame"), stub.NewObject("Frame")
        local borderTex, insetTex = Tex(nil, 525911), Tex(nil, 374154)
        border.GetRegions = function() return borderTex end
        inset.GetRegions = function() return insetTex end
        border.GetParent = function() return ah end
        inset.GetParent = function() return ah end
        ah.MoneyFrameBorder, ah.MoneyFrameInset = border, inset
        ah.GetChildren = function() return cats, list, border, inset end
        -- Reiter.
        local tabs = {}
        for i = 1, 3 do
            local tab = stub.NewObject("Button")
            tab.LeftActive = stub.NewObject("Texture")
            tab.GetID = function() return i end
            tabs[i] = tab
        end
        ah.Tabs, ah.selectedTab = tabs, 2
        S.Register()
        local glow = stub.NewObject("Texture")
        W.done[ah] = { glow = glow }
        local grad, gold = S.Gradient, {}
        S.Gradient = function(t, dir, c, a0, a1)
            if c == GC.frameAccent then gold[t] = true end
            return grad(t, dir, c, a0, a1)
        end
        W.HideByAtlas(ah)
        AH.Update(ah)
        LF.Update(ah)
        S.Gradient = grad
        W.HoldGlow(ah, "AuctionHouseFrame")
        local m = AH.frames[ah]
        assert(not glow:IsShown(), "Schein der Klasse ueber dem Auktionshaus")
        assert(m and gold[m.edge.l], "Kante oben nicht in Gold")
        assert(catBg:GetAlpha() == 0 and listBg:GetAlpha() == 0, "Grund der Listen bleibt")
        assert(AH.lists[catBg] and AH.lists[listBg] and W.Insets[cats] and W.Insets[list], "Listen nicht auf Innenflaeche")
        assert(aNormal:GetAlpha() == 0 and W.Entries[navA] and W.Entries[navB], "Kategorien nicht als Kacheln")
        assert(W.Entries[navA].on and not W.Entries[navB].on and W.Entries[navA].accent == GC.frameAccent,
            "gewaehlte Kategorie nicht in Gold (oder die falsche)")
        assert(wood:GetAlpha() == 0 and AH.heads[headBtn] and arrow:GetAlpha() == 1, "Spaltenkopf nicht flach oder Sortierpfeil weg")
        assert(W.Insets[border] and W.Insets[inset] and borderTex:GetAlpha() == 0 and insetTex:GetAlpha() == 0, "Geld nicht auf Flaeche")
        assert((LF.windows[ah].decks or 0) == 4, "Innenflaechen ohne Kante in Gold: " .. tostring(LF.windows[ah].decks))
        local sk1, sk2 = W.TabSkin[tabs[1]], W.TabSkin[tabs[2]]
        assert(sk1 and sk2 and sk2.accent == GC.frameAccent and sk1.accent == nil, "gewaehlter Reiter nicht in Gold")
        local rep = table.concat(AH.Report(ah, {}), "\n")
        assert(rep:find("Auktionshaus (Stil ruhig): Kante in Gold, kein Schein der Klasse · Listen auf Fläche 2 · Spaltenköpfe flach 1 · Geld 2 · Reiter 3", 1, true), "Bericht: " .. rep)
        collectgarbage("collect")
        collectgarbage("stop")
        local k0 = collectgarbage("count")
        for _ = 1, 20 do AH.Update(ah) LF.Update(ah) W.HoldGlow(ah, "AuctionHouseFrame") end
        local grew = collectgarbage("count") - k0
        collectgarbage("restart")
        assert(grew < 1, string.format("Auktionshaus legt im Takt Muell an: %.1f KB", grew))
        W.done[ah] = nil
        for name, v in pairs(saved) do _G[name] = v end
    end)
    Check(okAH, "Auktionshaus: Gold, Kategorien als Kacheln (gewaehlte in Gold), Listen und Geld auf Flaeche, Spaltenkoepfe flach, Reiter, kein Muell"
        .. (okAH and "" or (": " .. tostring(errAH))))

    -- 6.9.1.1: Bank in Gold. Beta-Test 6.9.1.0: Metallrahmen, Portraet,
    -- Steinplaetze, Holzleisten, Grund aus Leder.
    local okBK, errBK = pcall(function()
        local W, S, BK, LF, GC = WeintCodex.UIWindows, WeintCodex.UIStyle, WeintCodex.UIBank, WeintCodex.UICalm, WeintCodex.GameColors
        local listed = {}
        for _, n in ipairs(W.WINDOWS) do listed[n] = true end
        assert(listed.BankFrame and listed.GuildBankFrame and BK and S.SCOPES.BankFrame == S.CALM
            and S.SCOPES.GuildBankFrame == S.CALM, "Bank/Gildenbank nicht im Durchlauf oder nicht in Gold")
        local hosts = {}
        for _, h in ipairs(W.HOSTED.BankFrame or {}) do hosts[h] = true end
        assert(hosts[BK] and hosts[LF], "Bank ohne Plaetze oder ohne Kante an den Innenflaechen")
        local saved = {}
        local function Global(name, obj) saved[name] = _G[name] _G[name] = obj return obj end
        local function Tex(atlas, file)
            local t = stub.NewObject("Texture")
            t._atlas, t._file = atlas, file
            t.GetAtlas = function(self) return self._atlas end
            t.GetTexture = function(self) return self._file end
            return t
        end
        local bf = Global("BankFrame", stub.NewObject("Frame", "BankFrame"))
        local panel = stub.NewObject("Frame")
        bf.BankPanel = panel
        local bgTex, divider = Tex("bank-frame-background"), Tex("bank-divider")
        bf.GetRegions = function() return bgTex, divider end
        -- Ein Platz: Stein, Rahmen, Rand des Knopfs, Symbol, Rand der Qualitaet.
        local slot = stub.NewObject("Button")
        local stone, frame, rim = Tex("bags-item-bankslot64"), Tex("bank-frame-item-slotframe"), Tex(nil, 130718)
        -- Symbol, Rand der Qualitaet und Ueberlagerung tragen (leer) dasselbe
        -- Bild wie der Rand des Knopfs - sie duerfen trotzdem nie weg.
        local icon, quality, overlay = Tex(nil, 130718), Tex(nil, 130718), Tex(nil, 130718)
        slot.icon, slot.IconBorder, slot.IconOverlay = icon, quality, overlay
        slot.GetRegions = function() return stone, frame, rim, icon, quality, overlay end
        -- Ein Taschenplatz mit Schloss (bleibt).
        local bag = stub.NewObject("Button")
        local bagBg, bagFrame, lock = Tex("bank-frame-bag-slot-bg"), Tex("bank-frame-bag-slotframe"), Tex("bankslot-icon-lock")
        bag.GetRegions = function() return bagBg, bagFrame, lock end
        -- Schatten am Rand und Geld.
        local shadows = stub.NewObject("Frame")
        local hs, vs = Tex("_bank-frame-horiz-shadow"), Tex("!bank-frame-vert-shadow")
        shadows.GetRegions = function() return hs, vs end
        local mf, border = stub.NewObject("Frame"), stub.NewObject("Frame")
        local moneyTex = Tex(nil, 525911)
        border.GetRegions = function() return moneyTex end
        border.GetParent = function() return mf end
        mf.Border = border
        panel.MoneyFrame = mf
        panel.GetChildren = function() return slot, bag, shadows end
        bf.GetChildren = function() return panel end
        S.Register()
        local glow = stub.NewObject("Texture")
        W.done[bf] = { glow = glow }
        local grad, gold = S.Gradient, {}
        S.Gradient = function(t, dir, c, a0, a1)
            if c == GC.frameAccent then gold[t] = true end
            return grad(t, dir, c, a0, a1)
        end
        BK.Update(bf)
        LF.Update(bf)
        S.Gradient = grad
        W.HoldGlow(bf, "BankFrame")
        local m = BK.frames[bf]
        assert(not glow:IsShown(), "Schein der Klasse ueber der Bank")
        assert(m and gold[m.edge.l], "Kante oben nicht in Gold")
        assert(stone:GetAlpha() == 0 and frame:GetAlpha() == 0 and rim:GetAlpha() == 0, "Stein, Rahmen oder Rand des Platzes bleibt")
        assert(BK.flat[slot] and BK.flat[bag] and not BK.flat[panel], "Platz nicht flach (oder das ganze Fenster)")
        assert(icon:GetAlpha() == 1 and quality:GetAlpha() == 1 and overlay:GetAlpha() == 1 and slot:GetAlpha() == 1,
            "Symbol, Rand der Qualitaet oder Ueberlagerung ausgeblendet")
        assert(bagBg:GetAlpha() == 0 and bagFrame:GetAlpha() == 0 and lock:GetAlpha() == 1, "Taschenplatz: Rahmen bleibt oder Schloss weg")
        assert(bgTex:GetAlpha() == 0 and BK.surfaces[bgTex] and W.Insets[bf], "Grund nicht als Innenflaeche")
        assert(divider:GetAlpha() == 0 and hs:GetAlpha() == 0 and vs:GetAlpha() == 0, "Trennleiste oder Schatten bleibt")
        assert(W.Insets[border] and moneyTex:GetAlpha() == 0, "Geld nicht auf Flaeche")
        -- Zeigt eine Region spaeter etwas anderes: wieder sichtbar.
        rim._file = 135274
        BK.Update(bf)
        assert(rim:GetAlpha() == 1 and not BK.hidden[rim], "Bild eines Gegenstands bleibt unsichtbar")
        rim._file = 130718
        BK.Update(bf)
        assert(rim:GetAlpha() == 0, "Rand kommt nicht wieder weg")
        -- Ruhe im Takt: nichts wird je Durchlauf neu gesetzt.
        local sets = 0
        local ssa = stone.SetAlpha
        stone.SetAlpha = function(self, a) sets = sets + 1 return ssa(self, a) end
        for _ = 1, 5 do BK.Update(bf) end
        stone.SetAlpha = ssa
        assert(sets == 0, "Stein je Durchlauf neu gesetzt: " .. sets)
        local rep = table.concat(BK.Report(bf, {}), "\n")
        assert(rep:find("Bank (Stil ruhig): Kante in Gold, kein Schein der Klasse · Plätze flach 2", 1, true)
            and rep:find("Grund auf Fläche · Geld auf Fläche", 1, true), "Bericht: " .. rep)
        collectgarbage("collect")
        collectgarbage("stop")
        local k0 = collectgarbage("count")
        for _ = 1, 20 do BK.Update(bf) LF.Update(bf) W.HoldGlow(bf, "BankFrame") end
        local grew = collectgarbage("count") - k0
        collectgarbage("restart")
        assert(grew < 1, string.format("Bank legt im Takt Muell an: %.1f KB", grew))
        W.done[bf] = nil
        for name, v in pairs(saved) do _G[name] = v end
    end)
    Check(okBK, "Bank: Gold (auch Gildenbank), Plaetze und Taschenplaetze flach, Symbol/Qualitaet/Schloss bleiben, Grund und Geld auf Flaeche, Schmuck weg, kein Muell"
        .. (okBK and "" or (": " .. tostring(errBK))))

    -- 6.10.4.2, gemessen 05.10.2026: Gildenbank - Reiter des Spiels,
    -- Goldrahmen um das Geld, goldene Fluegel am Wappen; das Wappen bleibt.
    local okGB, errGB = pcall(function()
        local W, GB, GC = WeintCodex.UIWindows, WeintCodex.UIGuildBank, WeintCodex.GameColors
        local hosts = {}
        for _, h in ipairs(W.HOSTED.GuildBankFrame or {}) do hosts[h] = true end
        assert(GB and hosts[GB] and hosts[WeintCodex.UICalm], "Gildenbank ohne eigene Teile")
        local saved = {}
        local function Global(name, obj) saved[name] = _G[name] _G[name] = obj return obj end
        local function Tex(file)
            local t = stub.NewObject("Texture")
            t._file = file
            t.GetTexture = function(self) return self._file end
            return t
        end
        local gb = Global("GuildBankFrame", stub.NewObject("Frame", "GuildBankFrame"))
        -- 6.10.4.3, Beta-Test: ohne Fluegel ragte das Wappen allein ueber
        -- die Kachel ("sieht oben in der Mitte bloed aus") - ganz weg.
        for _, name in ipairs(GB.EMBLEM) do Global(name, stub.NewObject("Texture", name)) end
        local mL, mM, mR = Tex(525911), Tex(525911), Tex(525911)
        local emblem = stub.NewObject("Frame")
        local wingL, wingR, tabard = Tex(132069), Tex(132069), Tex(180159)
        emblem.GetRegions = function() return wingL, wingR, tabard end
        gb.GetRegions = function() return mL, mM, mR end
        gb.GetChildren = function() return emblem end
        local tabs, seen = {}, {}
        for i = 1, 4 do
            tabs[i] = Global("GuildBankFrameTab" .. i, stub.NewObject("Button"))
            tabs[i].GetID = function() return i end
        end
        gb.selectedTab = 3
        local skinTab = W.SkinTab
        W.SkinTab = function(tab, accent, sel) seen[tab] = { accent, sel } return true end
        W.done[gb] = { glow = stub.NewObject("Texture") }
        GB.Update(gb)
        W.SkinTab = skinTab
        assert(mL:GetAlpha() == 0 and mM:GetAlpha() == 0 and mR:GetAlpha() == 0 and GB.strips[mL] and GB.strips[mR],
            "Goldrahmen um das Geld bleibt")
        assert(wingL:GetAlpha() == 0 and wingR:GetAlpha() == 0, "goldene Fluegel am Wappen bleiben")
        for _, name in ipairs(GB.EMBLEM) do
            assert(_G[name]:GetAlpha() == 0, "Wappen der Gildenbank bleibt: " .. name)
        end
        local gbRep = table.concat(GB.Report(gb, {}), "\n")
        assert(gbRep:find("Wappen weg 12 · Reiter 4", 1, true), "Bericht: " .. gbRep)
        assert(seen[tabs[3]] and seen[tabs[3]][1] == GC.frameAccent and seen[tabs[3]][2] == true
            and seen[tabs[1]][2] == false and seen[tabs[4]][2] == false, "Reiter der Gildenbank nicht flach oder falsch gewaehlt")
        W.done[gb], GB.frames[gb] = nil, nil
        for name, old in pairs(saved) do _G[name] = old end
    end)
    Check(okGB, "Gildenbank: Reiter flach, Geld ohne Goldrahmen, Wappen samt Fluegeln weg"
        .. (okGB and "" or (": " .. tostring(errGB))))

    -- 6.9.1.2: Post in Gold. Beta-Test 6.9.1.1: Metallrahmen, Pergament,
    -- Steinplaetze, Eingabefelder mit Goldrand, Holzleisten.
    local okML, errML = pcall(function()
        local W, S, ML, LF, GC = WeintCodex.UIWindows, WeintCodex.UIStyle, WeintCodex.UIMail, WeintCodex.UICalm, WeintCodex.GameColors
        local listed = {}
        for _, n in ipairs(W.WINDOWS) do listed[n] = true end
        assert(listed.MailFrame and listed.OpenMailFrame and ML and S.SCOPES.MailFrame == S.CALM
            and S.SCOPES.OpenMailFrame == S.CALM, "Post/Brief nicht im Durchlauf oder nicht in Gold")
        local hosts = {}
        for _, h in ipairs(W.HOSTED.MailFrame or {}) do hosts[h] = true end
        assert(hosts[ML] and hosts[LF], "Post ohne eigene Teile oder ohne Kante an den Innenflaechen")
        local saved = {}
        local function Global(name, obj) saved[name] = _G[name] _G[name] = obj return obj end
        local function Tex(file)
            local t = stub.NewObject("Texture")
            t._file = file
            t.GetTexture = function(self) return self._file end
            return t
        end
        local mf = Global("MailFrame", stub.NewObject("Frame", "MailFrame"))
        mf.selectedTab = 2
        -- Posteingang: Pergament, eine Zeile mit Rahmen und Knopf (Symbol bleibt).
        local inbox = stub.NewObject("Frame")
        local inboxBg = Tex(530419)
        inbox.GetRegions = function() return inboxBg end
        local row = stub.NewObject("Frame")
        local rowRim = Tex(136383)
        row.GetRegions = function() return rowRim end
        local rowBtn = Global("MailItem1Button", stub.NewObject("Button"))
        local letter = Tex(133468)
        rowBtn.Icon = letter
        rowBtn.GetRegions = function() return letter end
        row.GetChildren = function() return rowBtn end
        inbox.GetChildren = function() return row end
        -- Versenden: Pergament hinter dem Brief, Feld, Anhang, Trennleiste.
        local send = stub.NewObject("Frame")
        local divider = Tex(130968)
        send.GetRegions = function() return divider end
        local scroll = stub.NewObject("Frame")
        local pTop, pBot = Tex(136859), Tex(136860)
        scroll.GetRegions = function() return pTop, pBot end
        local field = stub.NewObject("EditBox")
        local fl, fm, fr = Tex(130975), Tex(130975), Tex(130975)
        field.GetRegions = function() return fl, fm, fr end
        local att = stub.NewObject("Button")
        -- Das (leere) Symbol traegt dasselbe Bild wie der Stein - es bleibt.
        local stone, rim, attIcon = Tex(130862), Tex(130718), Tex(130862)
        att.icon = attIcon
        att.GetRegions = function() return stone, rim, attIcon end
        send.GetChildren = function() return scroll, field, att end
        -- Symbol des Briefkastens und die Innenflaeche des Fensters.
        local portrait = stub.NewObject("Frame")
        local mailbox = Tex(136382)
        portrait.GetRegions = function() return mailbox end
        local inset = stub.NewObject("Frame")
        inset.Bg, inset.NineSlice = Tex(374154), stub.NewObject("Frame")
        inset.GetRegions = function() return inset.Bg end
        inset.GetParent = function() return mf end
        mf.GetChildren = function() return inbox, send, portrait, inset end
        local money = Global("SendMailMoneyBg", stub.NewObject("Frame"))
        local moneyTex = Tex(525911)
        money.GetRegions = function() return moneyTex end
        money.GetParent = function() return mf end
        local body = Global("SendMailBodyEditBox", stub.NewObject("EditBox"))
        local bodyColor
        body.SetTextColor = function(_, r) bodyColor = r end
        local tab1 = Global("MailFrameTab1", stub.NewObject("Button"))
        local tab2 = Global("MailFrameTab2", stub.NewObject("Button"))
        tab1.GetID = function() return 1 end
        tab2.GetID = function() return 2 end
        local tabsSeen = {}
        local skinTab = W.SkinTab
        W.SkinTab = function(tab, accent, sel) tabsSeen[tab] = sel return true end
        S.Register()
        local glow = stub.NewObject("Texture")
        W.done[mf] = { glow = glow }
        local grad, gold = S.Gradient, {}
        S.Gradient = function(t, dir, c, a0, a1)
            if c == GC.frameAccent then gold[t] = true end
            return grad(t, dir, c, a0, a1)
        end
        ML.Update(mf)
        LF.Update(mf)
        S.Gradient = grad
        W.SkinTab = skinTab
        W.HoldGlow(mf, "MailFrame")
        local m = ML.frames[mf]
        assert(not glow:IsShown(), "Schein der Klasse ueber der Post")
        assert(m and gold[m.edge.l], "Kante oben nicht in Gold")
        assert(inboxBg:GetAlpha() == 0 and ML.surfaces[inboxBg] and W.Insets[inbox], "Pergament im Posteingang bleibt")
        assert(pTop:GetAlpha() == 0 and pBot:GetAlpha() == 0 and W.Insets[scroll], "Pergament hinter dem Brief bleibt")
        assert(rowRim:GetAlpha() == 0 and ML.flat[rowBtn] and letter:GetAlpha() == 1, "Zeile: Rahmen bleibt, Knopf nicht flach oder Symbol weg")
        assert(stone:GetAlpha() == 0 and rim:GetAlpha() == 0 and ML.flat[att] and attIcon:GetAlpha() == 1, "Anhang: Stein/Rand bleibt oder Symbol weg")
        assert(fl:GetAlpha() == 0 and fm:GetAlpha() == 0 and fr:GetAlpha() == 0 and ML.fields[field], "Feld behaelt den Goldrand")
        assert(divider:GetAlpha() == 0 and mailbox:GetAlpha() == 0, "Trennleiste oder Briefkasten bleibt")
        assert(W.Insets[inset] and inset.Bg:GetAlpha() == 0, "Innenflaeche des Fensters bleibt Leder")
        assert(W.Insets[money] and moneyTex:GetAlpha() == 0, "Geld nicht auf Flaeche")
        assert(bodyColor == C.textBright[1], "Schrift des Briefs bleibt dunkel")
        assert(tabsSeen[tab1] == false and tabsSeen[tab2] == true, "Reiter: der gewaehlte nicht in Gold")
        -- Ein Gegenstand im Anhang: die Region zeigt etwas anderes - wieder sichtbar.
        stone._file = 135274
        ML.Update(mf)
        assert(stone:GetAlpha() == 1 and not ML.hidden[stone], "Bild eines Gegenstands bleibt unsichtbar")
        stone._file = 130862
        ML.Update(mf)
        assert(stone:GetAlpha() == 0, "Stein kommt nicht wieder weg")
        local sets = 0
        local rsa = rowRim.SetAlpha
        rowRim.SetAlpha = function(self, a) sets = sets + 1 return rsa(self, a) end
        for _ = 1, 5 do ML.Update(mf) end
        rowRim.SetAlpha = rsa
        assert(sets == 0, "Rahmen je Durchlauf neu gesetzt: " .. sets)
        local rep = table.concat(ML.Report(mf, {}), "\n")
        assert(rep:find("Post (Stil ruhig): Kante in Gold, kein Schein der Klasse · Pergament auf Fläche 3", 1, true), "Bericht: " .. rep)
        -- 6.10.4.2 im Spiel: das Pergament (512 x 512) ragt rechts und unten
        -- ueber das Fenster - die Flaeche an seiner Stelle nicht mehr.
        local surf = ML.surfaces[inboxBg]
        local pts = {}
        surf.SetPoint = function(_, p, rel, rp, x, y) pts[p] = { rel, rp, x, y } end
        surf.ClearAllPoints = function() end
        mf.GetLeft, mf.GetRight, mf.GetTop, mf.GetBottom = function() return 100 end, function() return 484 end,
            function() return 700 end, function() return 188 end
        inboxBg.GetLeft, inboxBg.GetRight, inboxBg.GetTop, inboxBg.GetBottom = function() return 104 end, function() return 616 end,
            function() return 640 end, function() return 128 end
        ML.Update(mf)
        assert(pts.TOPLEFT and pts.TOPLEFT[1] == inboxBg and pts.TOPLEFT[3] == 0 and pts.TOPLEFT[4] == 0, "Flaeche oben links verschoben")
        assert(pts.BOTTOMRIGHT and pts.BOTTOMRIGHT[1] == inboxBg and pts.BOTTOMRIGHT[3] == -132 and pts.BOTTOMRIGHT[4] == 60,
            "Flaeche ragt ueber das Fenster: " .. tostring(pts.BOTTOMRIGHT and pts.BOTTOMRIGHT[3]) .. "/" .. tostring(pts.BOTTOMRIGHT and pts.BOTTOMRIGHT[4]))
        -- Gezogen: beide wandern - die Abstaende bleiben, nichts neu gesetzt.
        pts = {}
        mf.GetLeft, mf.GetRight = function() return 300 end, function() return 684 end
        inboxBg.GetLeft, inboxBg.GetRight = function() return 304 end, function() return 816 end
        ML.Update(mf)
        assert(next(pts) == nil, "Flaeche beim Ziehen neu gesetzt")
        -- Innerhalb des Fensters: genau am Bild.
        inboxBg.GetRight, inboxBg.GetBottom = function() return 600 end, function() return 300 end
        mf.GetRight = function() return 684 end
        ML.Update(mf)
        assert(pts.BOTTOMRIGHT and pts.BOTTOMRIGHT[3] == 0 and pts.BOTTOMRIGHT[4] == 0, "Flaeche innerhalb des Fensters beschnitten")
        for _, k in ipairs({ "GetLeft", "GetRight", "GetTop", "GetBottom" }) do mf[k], inboxBg[k] = nil, nil end
        collectgarbage("collect")
        collectgarbage("stop")
        local k0 = collectgarbage("count")
        for _ = 1, 20 do ML.Update(mf) LF.Update(mf) W.HoldGlow(mf, "MailFrame") end
        local grew = collectgarbage("count") - k0
        collectgarbage("restart")
        assert(grew < 1, string.format("Post legt im Takt Muell an: %.1f KB", grew))
        W.done[mf] = nil
        for name, v in pairs(saved) do _G[name] = v end
    end)
    Check(okML, "Post: Gold (auch Brief), Pergament weg und Schrift hell, Zeilen/Anhaenge flach, Symbole bleiben, Felder flach, Geld und Innenflaeche, Reiter, kein Muell"
        .. (okML and "" or (": " .. tostring(errML))))

    -- 6.10.1.0: Kontakte in Gold, gemessen am Reiter "Freunde".
    local okFR, errFR = pcall(function()
        local W, S, FR, LF, GC = WeintCodex.UIWindows, WeintCodex.UIStyle, WeintCodex.UIFriends, WeintCodex.UICalm, WeintCodex.GameColors
        local listed = {}
        for _, n in ipairs(W.WINDOWS) do listed[n] = true end
        assert(listed.FriendsFrame and FR and S.SCOPES.FriendsFrame == S.CALM, "Kontakte nicht im Durchlauf oder nicht in Gold")
        assert(W.HidesAtlas("UI-Frame-Metal-CornerTopLeft") and W.HidesAtlas("!UI-Frame-Metal-EdgeLeft")
            and W.HidesAtlas("UI-Frame-PortraitMetal-CornerTopLeft") and W.HidesAtlas("_UI-Frame-TopTileStreaks"),
            "gemessener Metallrahmen der Kontakte bleibt")
        local hosts = {}
        for _, h in ipairs(W.HOSTED.FriendsFrame or {}) do hosts[h] = true end
        assert(hosts[FR] and hosts[LF] and LF.WINDOWS.FriendsFrame == "Kontakte", "Kontakte ohne eigene Teile oder ohne Licht in Gold")
        local saved = {}
        local function Global(name, obj) saved[name] = _G[name] _G[name] = obj return obj end
        local function Tex(file, atlas)
            local t = stub.NewObject("Texture")
            t._file, t._atlas = file, atlas
            t.GetTexture = function(self) return self._file end
            if atlas then t.GetAtlas = function(self) return self._atlas end end
            return t
        end
        local ff = Global("FriendsFrame", stub.NewObject("Frame", "FriendsFrame"))
        ff.selectedTab = 1
        local heads = Tex(526421)
        ff.GetRegions = function() return heads end
        local bnet = stub.NewObject("Frame")
        local blue = Tex(632259)
        bnet.GetRegions = function() return blue end
        local status = stub.NewObject("Button")
        local holder = Tex(nil, "common-dropdown-textholder")
        status.GetRegions = function() return holder end
        local inset = stub.NewObject("Frame")
        inset.Bg, inset.NineSlice = Tex(374154), stub.NewObject("Frame")
        inset.GetRegions = function() return inset.Bg end
        inset.GetParent = function() return ff end
        -- Der Schein einer Zeile unter der Maus sagt etwas - er bleibt.
        local list = stub.NewObject("Frame")
        local rowGlow = Tex(136809)
        list.GetRegions = function() return rowGlow end
        ff.GetChildren = function() return bnet, status, inset, list end
        local tab1 = Global("FriendsFrameTab1", stub.NewObject("Button"))
        local tab3 = Global("FriendsFrameTab3", stub.NewObject("Button"))
        tab1.GetID = function() return 1 end
        tab3.GetID = function() return 3 end
        local tabsSeen = {}
        local skinTab = W.SkinTab
        W.SkinTab = function(tab, accent, sel) tabsSeen[tab] = sel return true end
        S.Register()
        local glow = stub.NewObject("Texture")
        W.done[ff] = { glow = glow }
        local grad, gold = S.Gradient, {}
        S.Gradient = function(t, dir, c, a0, a1)
            if c == GC.frameAccent then gold[t] = true end
            return grad(t, dir, c, a0, a1)
        end
        FR.Update(ff)
        LF.Update(ff)
        S.Gradient = grad
        W.SkinTab = skinTab
        W.HoldGlow(ff, "FriendsFrame")
        local m = FR.frames[ff]
        assert(not glow:IsShown(), "Schein der Klasse ueber den Kontakten")
        assert(m and gold[m.edge.l], "Kante oben nicht in Gold")
        assert(heads:GetAlpha() == 0, "Symbol oben links bleibt")
        assert(blue:GetAlpha() == 0 and FR.fields[bnet], "BattleTag bleibt blauer Kasten")
        assert(holder:GetAlpha() == 0 and FR.fields[status], "Feld des Status nicht flach")
        assert(W.Insets[inset] and inset.Bg:GetAlpha() == 0, "Innenflaeche der Liste bleibt")
        assert(rowGlow:GetAlpha() == 1 and not FR.hidden[rowGlow], "Schein der Zeile weg")
        assert(tabsSeen[tab1] == true and tabsSeen[tab3] == false and m.tabs == 2, "Reiter: der gewaehlte nicht in Gold")
        local rep = table.concat(FR.Report(ff, {}), "\n")
        assert(rep:find("Kontakte (Stil ruhig): Kante in Gold, kein Schein der Klasse", 1, true), "Bericht: " .. rep)
        -- Einmal vorweg: die flachen Leisten haengen neue Bilder an BattleTag
        -- und Status, der zweite Lauf liest deren Liste einmal neu (gemessen
        -- 16 KB, danach je Lauf 0). Gemessen wird der Takt, nicht das Aufbauen.
        FR.Update(ff)
        collectgarbage("collect")
        collectgarbage("stop")
        local k0 = collectgarbage("count")
        for _ = 1, 20 do FR.Update(ff) LF.Update(ff) W.HoldGlow(ff, "FriendsFrame") end
        local grew = collectgarbage("count") - k0
        collectgarbage("restart")
        assert(grew < 1, string.format("Kontakte legen im Takt Muell an: %.1f KB", grew))
        W.done[ff] = nil
        for name, v in pairs(saved) do _G[name] = v end
    end)
    Check(okFR, "Kontakte: Gold, Metall weg, Symbol weg, BattleTag und Status flach, Liste auf Flaeche, Schein der Zeile bleibt, Reiter, kein Muell"
        .. (okFR and "" or (": " .. tostring(errFR))))

    -- 6.20.0.0: das neue Kontaktfenster (SocialUIFrame), gemessen am Reiter
    -- "Freunde" - Reiter rechts, Karten je Freund, Suche und Filter.
    local okSF, errSF = pcall(function()
        local W, S, FR, LF, GC = WeintCodex.UIWindows, WeintCodex.UIStyle, WeintCodex.UIFriends, WeintCodex.UICalm, WeintCodex.GameColors
        local SF = FR and FR.Social
        local listed, movable = {}, {}
        for _, n in ipairs(W.WINDOWS) do listed[n] = true end
        for _, n in ipairs(WeintCodex.UIMoveWindows.WINDOWS) do movable[n] = true end
        assert(listed.SocialUIFrame and SF and S.SCOPES.SocialUIFrame == S.CALM, "neue Kontakte nicht im Durchlauf oder nicht in Gold")
        assert(movable.SocialUIFrame, "neue Kontakte nicht verschiebbar")
        assert(WeintCodex.UICalmParts.hosts.SocialUIFrame == SF, "neue Kontakte ohne Baustein-Fenster")
        local hosts = {}
        for _, h in ipairs(W.HOSTED.SocialUIFrame or {}) do hosts[h] = true end
        assert(hosts[SF] and hosts[LF] and LF.WINDOWS.SocialUIFrame == "Kontakte", "neue Kontakte ohne eigene Teile oder ohne Licht in Gold")
        -- Was der allgemeine Durchlauf nehmen muss (gemessen: SOLLTE WEG SEIN).
        for _, a in ipairs({ "UI-Frame-Metal-CornerTopLeft", "UI-Frame-PortraitMetal-CornerTopLeft", "_UI-Frame-Metal-EdgeTop",
                             "!UI-Frame-Metal-EdgeLeft", "128-RedButton-Left", "_128-RedButton-Center", "common-sidetab",
                             "common-sidetab-selected", "common-button-list-collapseExpand" }) do
            assert(W.HidesAtlas(a), "bleibt am neuen Kontaktfenster: " .. a)
        end
        local function Tex(file, atlas)
            local t = stub.NewObject("Texture")
            t._file, t._atlas = file, atlas
            t.GetTexture = function(self) return self._file end
            if atlas then t.GetAtlas = function(self) return self._atlas end end
            return t
        end
        local function Holder(...)
            local f = stub.NewObject("Frame")
            local regions = { ... }
            f.GetRegions = function() return unpack(regions) end
            return f
        end
        local heads, top, bottom = Tex(526421), Tex(nil, "friends-frame-topTexBG"), Tex(nil, "friends-frame-bottomTexBG")
        local sf = Holder(heads, top, bottom)
        local band, blue = Tex(nil, "friends-frame-infoBG"), Tex(632259)
        local holder = Tex(nil, "common-dropdown-textholder")
        local status = Holder(holder)
        local controls = Holder(blue)
        controls.GetChildren = function() return status end
        local bar = Holder(band)
        bar.GetChildren = function() return controls end
        local search = Tex(nil, "common-searchbar-a")
        local searchBar = Holder(search)
        local filterBg = Tex(nil, "common-dropdown-b-button")
        local filter = Holder(filterBg)
        local filterBar = stub.NewObject("Frame")
        filterBar.GetChildren = function() return searchBar, filter end
        -- Die Karte eines Freundes (eine Ebene tiefer als abgelaufen) bleibt.
        local cardBg = Tex(nil, "friends-card-disabled")
        local card, cardReads = stub.NewObject("Frame"), 0
        card.GetRegions = function() cardReads = cardReads + 1 return cardBg end
        local target = stub.NewObject("Frame")
        target.GetChildren = function() return card end
        local box = stub.NewObject("Frame")
        box.GetChildren = function() return target end
        local div1, div2 = Tex(nil, "perks-divider-short"), Tex(nil, "perks-divider-short")
        local list = Holder(div1, div2)
        list.GetChildren = function() return filterBar, box end
        sf.GetChildren = function() return bar, list end
        S.Register()
        local glow = stub.NewObject("Texture")
        W.done[sf] = { glow = glow }
        local grad, gold = S.Gradient, {}
        S.Gradient = function(t, dir, c, a0, a1)
            if c == GC.frameAccent then gold[t] = true end
            return grad(t, dir, c, a0, a1)
        end
        S.scoped[sf] = S.SCOPES.SocialUIFrame
        SF.Update(sf)
        LF.Update(sf)
        S.Gradient = grad
        W.HoldGlow(sf, "SocialUIFrame")
        local m = SF.frames[sf]
        assert(not glow:IsShown(), "Schein der Klasse ueber den neuen Kontakten")
        assert(m and gold[m.edge.l], "Kante oben nicht in Gold")
        assert(heads:GetAlpha() == 0, "Symbol oben links bleibt")
        assert(top:GetAlpha() == 0 and bottom:GetAlpha() == 0, "Verlauf oben/unten bleibt")
        assert(band:GetAlpha() == 0 and blue:GetAlpha() == 0 and SF.strips[blue], "BattleTag bleibt blauer Kasten auf Band")
        assert(not SF.fields[controls], "ganze BattleTag-Zeile mit Rand statt Leiste")
        assert(holder:GetAlpha() == 0 and SF.fields[status], "Feld des Status nicht flach")
        assert(search:GetAlpha() == 0 and SF.fields[searchBar], "Suchfeld nicht flach")
        assert(div1:GetAlpha() == 0 and div2:GetAlpha() == 0, "Linien ueber/unter der Liste bleiben")
        assert(filterBg:GetAlpha() == 1 and not SF.fields[filter], "Filterknopf verliert seinen Pfeil")
        assert(cardBg:GetAlpha() == 1 and not SF.hidden[cardBg], "Karte eines Freundes angefasst")
        assert(cardReads == 0, "Karten der Liste werden im Takt abgelaufen")
        local rep = table.concat(SF.Report(sf, {}), "\n")
        assert(rep:find("Kontakte (Stil ruhig): Kante in Gold, kein Schein der Klasse", 1, true), "Bericht: " .. rep)
        SF.Update(sf)
        collectgarbage("collect")
        collectgarbage("stop")
        local k0 = collectgarbage("count")
        for _ = 1, 20 do SF.Update(sf) LF.Update(sf) W.HoldGlow(sf, "SocialUIFrame") end
        local grew = collectgarbage("count") - k0
        collectgarbage("restart")
        assert(grew < 1, string.format("neue Kontakte legen im Takt Muell an: %.1f KB", grew))
        W.done[sf], S.scoped[sf] = nil, nil
    end)
    -- 6.21.0.0 (Beta-Test: "bei Freundesliste 0/2 ist das durchgestrichen"):
    -- die Kopfzeile traegt vor ihrem Text eine leere Zeile. Raute und Linie
    -- hingen an ihr - am Anfang der Zeile, die Linie durch den Text. Jetzt:
    -- Titel ist eine Zeile MIT Text, die Verzierung beginnt hinter dem
    -- letzten Text ("0/2"), und ohne Text gibt es keine.
    local okFH, errFH = pcall(function()
        local W, S = WeintCodex.UIWindows, WeintCodex.UIStyle
        local function Fs(text, left)
            local fs = stub.NewObject("FontString")
            fs._text = text
            fs.GetLeft = function() return left end
            return fs
        end
        local function Row(...)
            local row = stub.NewObject("Frame")
            local regions = { ... }
            row.GetRegions = function() return unpack(regions) end
            return row
        end
        local bg = stub.NewObject("Texture")
        bg.GetRight = function() return 360 end
        local empty, name, count = Fs("", 20), Fs("Freundesliste", 20), Fs("0/2", 110)
        local row = Row(empty, name, count, bg)
        local d = W.ListHeader(row, bg, S.CALM)
        assert(d and d.title == name, "Titel ist die leere Zeile")
        assert(d.tail == count and d.tw == 18, "Verzierung beginnt nicht hinter dem letzten Text")
        assert(d.dot:IsShown() and d.width > 0, "Raute oder Linie fehlt")
        assert(d.width == 360 - W.HEADER_INSET - (110 + 18 + 2 * W.LIST_GAP + 3), "Linie nicht vom Ende des Textes bis vor den Rand: " .. tostring(d.width))
        -- Eine Kopfzeile, deren Text erst spaeter kommt: erst keine
        -- Verzierung, dann die Zeile mit dem Text.
        local blank, later = Fs("", 20), Fs("", 20)
        local row2 = Row(blank, later, bg)
        local d2 = W.ListHeader(row2, bg, S.CALM)
        assert(d2 and not d2.dot:IsShown() and not d2.line:IsShown() and d2.width == 0, "Verzierung ohne Text")
        later._text = "Freundesliste"
        W.ListHeader(row2, bg, S.CALM)
        assert(d2.title == later and d2.dot:IsShown() and d2.width > 0, "Text kam spaeter - Verzierung bleibt weg oder an der leeren Zeile: " .. tostring(d2.title == later) .. tostring(d2.dot:IsShown()) .. tostring(d2.width))
    end)
    Check(okFH, "Kopfzeile einer Liste: nie durch den Text, Titel mit Text, hinter dem letzten Text, ohne Text keine Verzierung"
        .. (okFH and "" or (": " .. tostring(errFH))))

    Check(okSF, "Kontakte neu (SocialUIFrame): Gold, verschiebbar, Rahmen/Knopf/Reiter im Durchlauf, Verlauf und Band weg, BattleTag als Leiste, Status und Suche flach, Filter und Karten bleiben, kein Muell"
        .. (okSF and "" or (": " .. tostring(errSF))))

    -- 6.10.1.0: Lehrer in Gold. Pergament, Zeilengrund, Schein und
    -- Markierung sind EIN Bild (404984) - sortiert wird nach Rolle.
    local okCT, errCT = pcall(function()
        local W, S, CT, LF, GC = WeintCodex.UIWindows, WeintCodex.UIStyle, WeintCodex.UIClassTrainer, WeintCodex.UICalm, WeintCodex.GameColors
        local listed = {}
        for _, n in ipairs(W.WINDOWS) do listed[n] = true end
        assert(listed.ClassTrainerFrame and CT and S.SCOPES.ClassTrainerFrame == S.CALM, "Lehrer nicht im Durchlauf oder nicht in Gold")
        local hosts = {}
        for _, h in ipairs(W.HOSTED.ClassTrainerFrame or {}) do hosts[h] = true end
        assert(hosts[CT] and hosts[LF] and LF.WINDOWS.ClassTrainerFrame == "Lehrer", "Lehrer ohne eigene Teile oder ohne Licht in Gold")
        local saved = {}
        local function Global(name, obj) saved[name] = _G[name] _G[name] = obj return obj end
        local function Tex(file)
            local t = stub.NewObject("Texture")
            t._file = file
            t.GetTexture = function(self) return self._file end
            return t
        end
        local function NewRow()
            local b = stub.NewObject("Button")
            b._normal, b.selectedTex, b._high, b.icon = Tex(404984), Tex(404984), Tex(404984), Tex(135812)
            b.GetNormalTexture = function(self) return self._normal end
            b.GetRegions = function(self) return self._normal, self.selectedTex, self._high, self.icon end
            return b
        end
        local tf = Global("ClassTrainerFrame", stub.NewObject("Frame", "ClassTrainerFrame"))
        tf.BG = Tex(404984)
        local moneyBorder = Global("ClassTrainerFrameMoneyBg", Tex(237619))
        tf.GetRegions = function() return tf.BG, moneyBorder end
        tf.skillStepButton = NewRow()
        local rowA, rowB = NewRow(), NewRow()
        local target = stub.NewObject("Frame")
        target.GetChildren = function() return rowA, rowB end
        tf.ScrollBox = stub.NewObject("Frame")
        tf.ScrollBox.ScrollTarget = target
        tf.ScrollBox.GetChildren = function() return target end
        local inset = stub.NewObject("Frame")
        inset.Bg, inset.NineSlice = Tex(374154), stub.NewObject("Frame")
        inset.GetRegions = function() return inset.Bg end
        inset.GetParent = function() return tf end
        tf.GetChildren = function() return tf.skillStepButton, tf.ScrollBox, inset end
        S.Register()
        local glow = stub.NewObject("Texture")
        W.done[tf] = { glow = glow }
        local grad, gold = S.Gradient, {}
        S.Gradient = function(t, dir, c, a0, a1)
            if c == GC.frameAccent then gold[t] = true end
            return grad(t, dir, c, a0, a1)
        end
        CT.Update(tf)
        LF.Update(tf)
        S.Gradient = grad
        W.HoldGlow(tf, "ClassTrainerFrame")
        local m = CT.frames[tf]
        assert(not glow:IsShown(), "Schein der Klasse ueber dem Lehrer")
        assert(m and gold[m.edge.l], "Kante oben nicht in Gold")
        assert(tf.BG:GetAlpha() == 0 and m.parchment == 1, "Pergament bleibt")
        for _, b in ipairs({ tf.skillStepButton, rowA, rowB }) do
            assert(b._normal:GetAlpha() == 0 and CT.flat[b], "Zeile behaelt ihren Grund")
            assert(b.selectedTex:GetAlpha() == 1 and b._high:GetAlpha() == 1 and b.icon:GetAlpha() == 1,
                "Markierung, Schein oder Symbol der Zeile weg - gleiches Bild, andere Rolle")
        end
        assert(m.rows == 3, "nicht alle Zeilen flach: " .. tostring(m.rows))
        assert(moneyBorder:GetAlpha() == 0 and m.money_bar and m.money_bar:IsShown(), "Geld ohne Leiste oder Rahmen bleibt")
        assert(W.Insets[inset] and inset.Bg:GetAlpha() == 0, "Innenflaeche bleibt Leder")
        -- Eine wiederverwendete Zeile zeigt etwas anderes: wieder sichtbar.
        rowB._normal._file = 999
        CT.Update(tf)
        assert(rowB._normal:GetAlpha() == 1 and not CT.own[rowB._normal], "fremdes Bild in einer Zeile bleibt unsichtbar")
        rowB._normal._file = 404984
        local rep = table.concat(CT.Report(tf, {}), "\n")
        assert(rep:find("Lehrer (Stil ruhig): Kante in Gold, kein Schein der Klasse · Pergament weg 1 · Zeilen flach", 1, true), "Bericht: " .. rep)
        assert(rep:find("Leiste der Fertigkeit –", 1, true), "Klassenlehrer meldet eine Leiste: " .. rep)
        -- 6.10.4.6, gemessen beim Berufslehrer: Leiste der Fertigkeit mit
        -- Rahmen (410251, Left/Middle/Right) und blauer Fuellung (136570).
        local sb = Global("ClassTrainerStatusBar", stub.NewObject("StatusBar", "ClassTrainerStatusBar"))
        local parts = {}
        for _, n in ipairs({ "ClassTrainerStatusBarLeft", "ClassTrainerStatusBarMiddle", "ClassTrainerStatusBarRight" }) do
            parts[#parts + 1] = Global(n, Tex(410251))
        end
        -- Blaue Farbflaeche (FileData ID 0, gemessen mit 6.10.4.6). Seit
        -- 6.10.4.8 bleiben sie und das Blau der Fuellung (Beta-Test).
        local blueBg = Global("ClassTrainerStatusBarBackground", Tex(0))
        local col, colSets, barTex = { 0, 0, 1 }, 0, nil
        sb.GetStatusBarColor = function() return col[1], col[2], col[3], 1 end
        sb.SetStatusBarColor = function(_, r, g, b) col = { r, g, b } colSets = colSets + 1 end
        sb.SetStatusBarTexture = function(_, t) barTex = t end
        CT.Update(tf)
        for _, t in ipairs(parts) do assert(t:GetAlpha() == 0, "Rahmen der Leiste bleibt") end
        assert(barTex == K.BAR_TEXTURE and CT.bars[sb] and CT.bars[sb].edge, "Leiste nicht flach")
        assert(blueBg:GetAlpha() == 1, "blaue Flaeche der Leiste ausgeblendet")
        CT.Update(tf)
        assert(colSets == 0 and col[1] == 0 and col[3] == 1, "Blau der Fuellung umgefaerbt")
        local rep2 = table.concat(CT.Report(tf, {}), "\n")
        assert(rep2:find("Leiste der Fertigkeit flach", 1, true), "Bericht: " .. rep2)
        CT.Update(tf)
        collectgarbage("collect")
        collectgarbage("stop")
        local k0 = collectgarbage("count")
        for _ = 1, 20 do CT.Update(tf) LF.Update(tf) W.HoldGlow(tf, "ClassTrainerFrame") end
        local grew = collectgarbage("count") - k0
        collectgarbage("restart")
        assert(grew < 1, string.format("Lehrer legt im Takt Muell an: %.1f KB", grew))
        W.done[tf] = nil
        for name, v in pairs(saved) do _G[name] = v end
    end)
    Check(okCT, "Lehrer: Gold, Pergament weg, Zeilen flach (Markierung, Schein, Symbol bleiben), Geld als Leiste, Innenflaeche, kein Muell"
        .. (okCT and "" or (": " .. tostring(errCT))))

    -- 6.9.0.0: Symbol der Oberflaeche an der Minikarte - nur mit Oberflaeche.
    local okLN, errLN = pcall(function()
        local LN = WeintCodex.UILauncher
        local icon = LibStub("LibDBIcon-1.0")
        assert(K.UIEnabled() and icon:IsRegistered(LN.NAME), "mit Oberflaeche kein Symbol an der Minikarte")
        local b = icon:GetMinimapButton(LN.NAME)
        assert(b and b:IsShown(), "Symbol nicht zu sehen")
        -- Klicks: links die Einstellungen, rechts der Gestaltungsmodus.
        local UO = WeintCodex.UIOptions
        local toggled = 0
        local oldToggle = UO.Toggle
        UO.Toggle = function() toggled = toggled + 1 end
        LN.Click("LeftButton")
        UO.Toggle = oldToggle
        assert(toggled == 1, "Linksklick oeffnet die Einstellungen nicht")
        local was = K.IsUnlocked()
        LN.Click("RightButton")
        assert(K.IsUnlocked() ~= was, "Rechtsklick schaltet den Gestaltungsmodus nicht")
        LN.Click("RightButton")
        assert(K.IsUnlocked() == was, "zweiter Rechtsklick beendet den Gestaltungsmodus nicht")
        K.SetUnlocked(was)
        local lines = {}
        local tt = { AddLine = function(_, t) lines[#lines + 1] = t end,
                     AddDoubleLine = function(_, a, t) lines[#lines + 1] = a .. " " .. t end }
        LN.Tooltip(tt)
        assert(table.concat(lines, "|"):find("Einstellungen (/wcui)", 1, true), "Tooltip nennt den Linksklick nicht")
        -- Oberflaeche aus: das Symbol geht sofort; wieder an: es kommt.
        K.SetUIEnabled(false)
        assert(not b:IsShown() and not LN.Wanted(), "ohne Oberflaeche bleibt das Symbol")
        K.SetUIEnabled(true)
        assert(b:IsShown(), "Symbol kommt mit der Oberflaeche nicht zurueck")
        -- Abschalten in /wcui.
        LN.SetShown(false)
        assert(not b:IsShown() and K.Root().launcher.hide == true, "Symbol laesst sich nicht abschalten")
        LN.SetShown(true)
        assert(b:IsShown(), "Symbol laesst sich nicht wieder einschalten")
    end)
    Check(okLN, "Symbol der Oberflaeche an der Minikarte: nur mit Oberflaeche, Links Einstellungen, Rechts Gestaltung, abschaltbar"
        .. (okLN and "" or (": " .. tostring(errLN))))

    -- 6.7.9.0: Karte & Questlog in Gold. Der weiche Rand um die Karte
    -- (ausdruecklich gewuenscht) bleibt; der Questlog liegt auf einer
    -- Flaeche, seine Zonen sind Abschnitte wie im Ruf, kein Schein der Klasse.
    local okQ, errQ = pcall(function()
        local W, S, QL = WeintCodex.UIWindows, WeintCodex.UIStyle, WeintCodex.UIQuestLog
        local GC = WeintCodex.GameColors
        assert(QL and W.HOSTED.WorldMapFrame and W.HOSTED.WorldMapFrame[1] == QL and S.SCOPES.WorldMapFrame == S.CALM,
            "Questlog nicht in Gold an der Karte eingetragen")
        local function Tex(atlas)
            local t = stub.NewObject("Texture")
            t.GetAtlas = function() return atlas end
            return t
        end
        local map = stub.NewObject("Frame", "WorldMapFrame")
        map._width, map._height = 1000, 700
        local canvas, inner, layer = stub.NewObject("Frame"), stub.NewObject("Frame"), stub.NewObject("Frame")
        local tileA = stub.NewObject("Texture")
        tileA._width, tileA._height = 256, 256
        layer.GetRegions = function() return tileA end
        inner.GetChildren = function() return layer end
        canvas.Child = inner
        local made = 0
        local mk = canvas.CreateTexture
        canvas.CreateTexture = function(self, ...) made = made + 1 return mk(self, ...) end
        -- Questlog: eine Zone (Kopfzeile des Spiels) und eine Quest.
        local qsf, contents, sbar = stub.NewObject("Frame"), stub.NewObject("Frame"), stub.NewObject("Frame")
        qsf.Contents, qsf.ScrollBar = contents, sbar
        local head = stub.NewObject("Button")
        local hBg, minus = Tex("common-button-list-collapseExpand"), Tex("common-button-list-minus")
        hBg._width = 280
        local hName = stub.NewObject("FontString")
        hName._text, hName._font = "Die Todesminen", true
        head.GetRegions = function() return hBg, minus, hName end
        local quest = stub.NewObject("Button")
        local qTitle = stub.NewObject("FontString")
        qTitle._text, qTitle._font = "[18] Die Suche nach Andenken", true
        qTitle.SetTextColor = function() error("Farbe einer Quest ueberschrieben") end
        quest.GetRegions = function() return qTitle end
        contents.GetChildren = function() return head, quest end
        qsf.GetChildren = function() return contents, sbar end
        map.ScrollContainer = canvas
        map.GetChildren = function() return canvas, qsf end
        local oldWM, oldQSF = _G.WorldMapFrame, _G.QuestScrollFrame
        _G.WorldMapFrame, _G.QuestScrollFrame = map, qsf

        S.Register()
        W.SkinMap(map)
        W.SoftMap(map)
        local lh = W.ListHeaders[head]
        assert(lh and lh.band and lh.accent == GC.frameAccent and not W.Headers[head], "Zone nicht als Abschnitt in Gold")
        -- 6.9.0.0 (Beta-Test: "Brachland", "Dunkelkueste", "Stormwind" mit
        -- Raute, ohne Linie): die Linie haengt an EINEM Punkt (links an der
        -- Raute), ihre Breite ist gerechnet - zwei Punkte an Regionen
        -- verschiedener Hoehe zeichnet das Spiel nicht. Ohne Kanten keine
        -- geratene Breite, und der Bericht nennt die Zeile.
        local linePts = {}
        local sp = lh.line.SetPoint
        lh.line.SetPoint = function(self, p, ...) linePts[#linePts + 1] = p return sp(self, p, ...) end
        hName.GetLeft, hName.GetStringWidth = function() return nil end, function() return 100 end
        minus.GetLeft = function() return 290 end
        head:Show()
        W.SkinMap(map)
        assert(lh.width == 0 and not lh.line:IsShown(), "Linie ohne gemessene Kante: Breite geraten")
        local hrep = table.concat(W.HeaderReport(), "\n")
        local before = tonumber(hrep:match("Abschnitte: %d+, mit Linie (%d+) · ohne: "))
        assert(before, "Bericht ohne fehlende Linie: " .. hrep)
        hName.GetLeft = function() return 20 end
        W.SkinMap(map)
        -- bis 6 px vor das Zeichen: 290 - 6 - (20 + 100 + 2 * 8 + 3) = 145
        assert(lh.width == 145 and lh.line:IsShown() and lh.line:GetWidth() == 145,
            "Breite der Linie falsch: " .. tostring(lh.width))
        for _, p in ipairs(linePts) do assert(p == "LEFT", "Linie an zweitem Punkt verankert: " .. p) end
        assert(#linePts > 0, "Linie nie neu gelegt")
        hrep = table.concat(W.HeaderReport(), "\n")
        assert(tonumber(hrep:match("Abschnitte: %d+, mit Linie (%d+)")) == before + 1, "Bericht zaehlt die Linie nicht: " .. hrep)
        -- Die Zeile wandert (Liste verwendet sie neu): Breite folgt.
        minus.GetLeft = function() return 250 end
        W.SkinMap(map)
        assert(lh.width == 105, "Breite folgt der Kante nicht: " .. tostring(lh.width))
        -- Ohne Zeichen in der Zeile (Questlog: es steckt im CollapseButton):
        -- bis 10 px vor das Ende des Balkens.
        local icon = lh.icon
        lh.icon = nil
        hBg.GetRight = function() return 300 end
        W.SkinMap(map)
        assert(lh.width == 151, "Linie endet nicht vor dem Balken: " .. tostring(lh.width))
        lh.icon = icon
        QL.Update(map)
        local glow = stub.NewObject("Texture")
        W.done[map].glow = glow
        W.HoldGlow(map, "WorldMapFrame")
        local col = QL.cols[map]
        assert(col and col.on and col.body._parent == map and col.anchor == qsf, "Questlog nicht auf Flaeche")
        assert(not glow:IsShown(), "Schein der Klasse ueber der Karte")
        -- Die Karte bleibt: weicher Rand wie gehabt, nichts Neues auf ihr.
        assert(tileA._masks and #tileA._masks == 1, "weicher Rand der Karte verloren")
        local before = made
        for _ = 1, 3 do QL.Update(map) W.SkinMap(map) end
        assert(made == before and #tileA._masks == 1, "Questlog legt etwas auf die Karte")
        local rep = table.concat(QL.Report(map, {}), "\n")
        assert(rep:find("Questlog (Stil ruhig): Spalte auf Fläche · Details nicht gefunden · Karte unberührt", 1, true), "Bericht: " .. rep)
        -- Seitenleiste zu: Flaeche weg.
        qsf:Hide()
        QL.Update(map)
        assert(not col.on and not col.body:IsShown(), "Flaeche bleibt ohne Questlog")
        qsf:Show()
        collectgarbage("collect")
        collectgarbage("stop")
        local k0 = collectgarbage("count")
        for _ = 1, 20 do QL.Update(map) W.HoldGlow(map, "WorldMapFrame") end
        local grew = collectgarbage("count") - k0
        collectgarbage("restart")
        assert(grew < 1, string.format("Questlog legt im Takt Muell an: %.1f KB", grew))
        -- 6.8.0.9: eine Quest geoeffnet (gemessen: QuestMapFrame.QuestsFrame.
        -- DetailsFrame, Text in QuestMapDetailsScrollFrame). Pergament, Balken
        -- und Rahmen der Belohnungen weg, Schrift hell, Text auf Flaeche.
        local qmf, qframe, dframe = stub.NewObject("Frame"), stub.NewObject("Frame"), stub.NewObject("Frame")
        local dtext, dbar = stub.NewObject("Frame"), stub.NewObject("Frame")
        dtext.ScrollBar = dbar
        qmf.QuestsFrame, qframe.DetailsFrame = qframe, dframe
        local parchment, rewardTop, divider = Tex("QuestDetailsBackgrounds"), Tex("QuestLog-reward-top-frame"),
            Tex("UI-Frame-BtnDivMiddle")
        local title = stub.NewObject("FontString")
        title._text, title._font = "Geschäfte in Auberdine", true
        title.GetTextColor = function(self) return self._r or 0.18, self._g or 0.10, self._b or 0.02 end
        title.SetTextColor = function(self, r, g, b) self._r, self._g, self._b = r, g, b end
        local green = stub.NewObject("FontString")
        green._text, green._font = "Belohnung", true
        green.GetTextColor = function() return 0.1, 1, 0.1 end
        green.SetTextColor = function() error("Farbe mit Bedeutung ueberschrieben") end
        dtext.GetRegions = function() return title, green end
        dtext.GetChildren = function() return dbar end
        dframe.GetRegions = function() return parchment, rewardTop, divider end
        dframe.GetChildren = function() return dtext end
        qframe.GetChildren = function() return dframe end
        qmf.GetChildren = function() return qframe end
        map.QuestMapFrame = qmf
        local oldDSF = _G.QuestMapDetailsScrollFrame
        _G.QuestMapDetailsScrollFrame = dtext
        qsf:Hide()
        W.SkinMap(map)
        QL.Update(map)
        assert(parchment:GetAlpha() == 0 and rewardTop:GetAlpha() == 0 and divider:GetAlpha() == 0, "Pergament, Balken oder Striche bleiben")
        local dcol = QL.details[map]
        assert(dcol and dcol.on and dcol.body._parent == map and dcol.anchor == dtext, "Questdetails nicht auf Flaeche")
        assert(not col.on, "Spalte bleibt unter den Details")
        assert(title._r and title._r > 0.5, "braune Schrift der Quest bleibt dunkel")
        rep = table.concat(QL.Report(map, {}), "\n")
        assert(rep:find("Details auf Fläche, Schrift hell", 1, true), "Bericht: " .. rep)
        collectgarbage("collect")
        collectgarbage("stop")
        k0 = collectgarbage("count")
        for _ = 1, 20 do QL.Update(map) end
        grew = collectgarbage("count") - k0
        collectgarbage("restart")
        assert(grew < 1, string.format("Questdetails legen im Takt Muell an: %.1f KB", grew))
        dframe:Hide()
        QL.Update(map)
        assert(not dcol.on and not dcol.body:IsShown(), "Flaeche der Details bleibt")
        map.QuestMapFrame = nil
        _G.QuestMapDetailsScrollFrame = oldDSF
        W.done[map] = nil
        _G.WorldMapFrame, _G.QuestScrollFrame = oldWM, oldQSF
    end)
    Check(okQ, "Karte & Questlog: Gold, Questlog auf Flaeche, Zonen als Abschnitte, weicher Rand der Karte bleibt"
        .. (okQ and "" or (": " .. tostring(errQ))))

    -- 6.8.0.0: Suche nach Gruppe in Gold - Schein der Klasse aus, die
    -- Innenflaechen (W.Insets, nicht ueber Namen) mit Schatten und Kante in
    -- Gold, aus mit ihrer Flaeche.
    local okL, errL = pcall(function()
        local W, S, LF = WeintCodex.UIWindows, WeintCodex.UIStyle, WeintCodex.UICalm
        local GC = WeintCodex.GameColors
        assert(LF and W.HOSTED.LFGParentFrame[1] == LF and W.HOSTED.PVEFrame[1] == LF
            and S.SCOPES.LFGParentFrame == S.CALM and S.SCOPES.PVEFrame == S.CALM, "Suche nach Gruppe nicht in Gold eingetragen")
        local f = stub.NewObject("Frame", "LFGParentFrame")
        local listing, inset = stub.NewObject("Frame"), stub.NewObject("Frame")
        listing._parent, inset._parent = f, listing
        listing.Inset = inset
        listing.GetChildren = function() return inset end
        f.GetChildren = function() return listing end
        -- Eine Innenflaeche eines anderen Fensters darf nichts bekommen.
        local other, otherInset = stub.NewObject("Frame"), stub.NewObject("Frame")
        otherInset._parent = other
        W.Insets[otherInset] = true
        W.SkinInsets(f)
        assert(W.Insets[inset], "Innenflaeche nicht gestaltet")
        local glow = stub.NewObject("Texture")
        W.done[f] = { glow = glow }
        S.Scope(f, S.CALM)
        local grad, classy, goldy = S.Gradient, 0, 0
        S.Gradient = function(t, dir, c, a0, a1)
            if c == K.Highlight() then classy = classy + 1 end
            if c == GC.frameAccent then goldy = goldy + 1 end
            return grad(t, dir, c, a0, a1)
        end
        LF.Update(f)
        W.HoldGlow(f, "LFGParentFrame")
        S.Gradient = grad
        local d = LF.decks[inset]
        assert(d and d.on and d.shadow and d.edge and LF.windows[f].light, "Innenflaeche ohne Kante oder Schatten")
        assert(not LF.decks[otherInset], "Innenflaeche eines anderen Fensters gestaltet")
        assert(classy == 0 and goldy > 0 and not glow:IsShown(), "nicht in Gold oder Schein der Klasse bleibt")
        local rep = table.concat(LF.Report(f, {}), "\n")
        assert(rep:find("Suche nach Gruppe (Stil ruhig): 1 Innenflächen mit Kante in Gold", 1, true), "Bericht: " .. rep)
        inset:Hide()
        LF.Update(f)
        assert(not d.on and not d.shadow:IsShown(), "Kante bleibt ohne Innenflaeche")
        inset:Show()
        -- 6.8.0.1: die Reiter "Gruppen durchsuchen" und "Spielersuche" - wie
        -- gemessen Marmor, Stein, Goldlinien; nach W.Apply Innenflaechen, die
        -- das Modul findet. Texte bleiben.
        local function Tex2(atlas)
            local t = stub.NewObject("Texture")
            t.GetAtlas = function() return atlas end
            return t
        end
        local tabs, hidden, texts = {}, {}, {}
        for _, name in ipairs({ "LFGBrowseFrame", "LFGWhoListFrame" }) do
            local tf = stub.NewObject("Frame", name)
            tf._parent = f
            local marble, stone, line = stub.NewObject("Texture"), Tex2("groupfinder-Stat-StoneBG"), Tex2("groupfinder-ScrollLine")
            local note = stub.NewObject("FontString")
            note._text, note._font = "Keine Gruppen gefunden.", true
            tf.GetRegions = function() return marble, stone, line, note end
            _G[name] = tf
            tabs[#tabs + 1] = tf
            for _, t in ipairs({ marble, stone, line }) do hidden[#hidden + 1] = t end
            texts[#texts + 1] = note
        end
        W.Apply()
        LF.Update(f)
        for _, t in ipairs(hidden) do assert(t:GetAlpha() == 0, "Marmor, Stein oder Goldlinie bleibt") end
        for _, t in ipairs(texts) do assert(t:IsShown() and t:GetAlpha() == 1, "Text der Suche ausgeblendet") end
        for _, tf in ipairs(tabs) do
            assert(W.Insets[tf] and LF.decks[tf] and LF.decks[tf].on, "Reiter ohne Innenflaeche oder Kante in Gold")
        end
        assert(LF.windows[f].decks == 3, "Innenflaechen falsch gezaehlt: " .. tostring(LF.windows[f].decks))
        _G.LFGBrowseFrame, _G.LFGWhoListFrame = nil, nil
        for _ = 1, 3 do LF.Update(f) end
        collectgarbage("collect")
        collectgarbage("stop")
        local k0 = collectgarbage("count")
        for _ = 1, 20 do LF.Update(f) W.HoldGlow(f, "LFGParentFrame") end
        local grew = collectgarbage("count") - k0
        collectgarbage("restart")
        assert(grew < 1, string.format("Suche nach Gruppe legt im Takt Muell an: %.1f KB", grew))
        W.Insets[otherInset], W.done[f] = nil, nil
    end)
    Check(okL, "Suche nach Gruppe: Gold, Innenflaechen mit Kante und Schatten, kein Schein der Klasse"
        .. (okL and "" or (": " .. tostring(errL))))

    -- 6.8.0.2: Sammlung ("Vorlagen") in Gold - derselbe Baustein (ui/calm.lua):
    -- die Innenflaeche WardrobeCollectionFrame.ItemsCollectionFrame (seit
    -- 6.6.3.3 in W.OWN_BG_PATHS) bekommt Schatten und Kante in Gold, kein
    -- Schein der Klasse; gewaehlte Reiter oben (Reitersystem) in Gold.
    local okJ, errJ = pcall(function()
        local W, S, CA = WeintCodex.UIWindows, WeintCodex.UIStyle, WeintCodex.UICalm
        local GC = WeintCodex.GameColors
        assert(W.HOSTED.CollectionsJournal and W.HOSTED.CollectionsJournal[1] == CA and S.SCOPES.CollectionsJournal == S.CALM,
            "Sammlung nicht in Gold eingetragen")
        local cj = stub.NewObject("Frame", "CollectionsJournal")
        local wardrobe, items = stub.NewObject("Frame"), stub.NewObject("Frame")
        wardrobe._parent, items._parent = cj, wardrobe
        wardrobe.ItemsCollectionFrame = items
        local leather = stub.NewObject("Texture")
        items.GetRegions = function() return leather end
        local oldWCF, oldCJ = _G.WardrobeCollectionFrame, _G.CollectionsJournal
        _G.WardrobeCollectionFrame, _G.CollectionsJournal = wardrobe, cj
        W.Apply()
        assert(W.Insets[items] and leather:GetAlpha() == 0, "Vorlagen ohne Innenflaeche")
        local glow = stub.NewObject("Texture")
        W.done[cj] = { glow = glow }
        S.Register()
        CA.Update(cj)
        W.HoldGlow(cj, "CollectionsJournal")
        assert(CA.decks[items] and CA.decks[items].on and not glow:IsShown(), "Vorlagen ohne Kante oder mit Schein der Klasse")
        local rep = table.concat(CA.Report(cj, {}), "\n")
        assert(rep:find("Sammlung (Stil ruhig): 1 Innenflächen mit Kante in Gold", 1, true), "Bericht: " .. rep)
        -- Reiter oben (Reitersystem des Spiels): der gewaehlte in Gold.
        local sys, tab = stub.NewObject("Frame"), stub.NewObject("Button")
        tab.IsSelected = function() return true end
        sys.tabs, sys.AddTab = { tab }, function() end
        cj.GetChildren = function() return sys end
        W.SkinTabSystems(cj)
        assert(W.TabSkin[tab] and W.TabSkin[tab].accent == GC.frameAccent, "gewaehlter Reiter nicht in Gold")
        W.done[cj] = nil
        _G.WardrobeCollectionFrame, _G.CollectionsJournal = oldWCF, oldCJ
    end)
    Check(okJ, "Sammlung: Gold, Vorlagen auf Innenflaeche mit Kante, Reiter oben in Gold, kein Schein der Klasse"
        .. (okJ and "" or (": " .. tostring(errJ))))

    -- 6.8.0.3: Talente - Klassenfarbe, die Animation und die Landschaften
    -- bleiben unberuehrt; Licht und Kante in der Klassenfarbe; die Namen der
    -- Baeume (vom Spiel, GetTalentTabInfo) mit Raute und Linie; Schein der
    -- Klasse aus, solange die Talente offen sind.
    local okT, errT = pcall(function()
        local W, S, TL, SB = WeintCodex.UIWindows, WeintCodex.UIStyle, WeintCodex.UITalents, WeintCodex.UISpellBook
        assert(TL and W.HOSTED.PlayerSpellsFrame[1] == SB and W.HOSTED.PlayerSpellsFrame[2] == TL
            and S.SCOPES["PlayerSpellsFrame.TalentsFrame"] == S.CHARACTER_INFO, "Talente nicht eingetragen")
        local function Tex(atlas)
            local t = stub.NewObject("Texture")
            t.GetAtlas = function() return atlas end
            return t
        end
        local psf = stub.NewObject("Frame")
        local tf, buttons = stub.NewObject("Frame"), stub.NewObject("Frame")
        psf.TalentsFrame, tf.ButtonsParent = tf, buttons
        local clouds, land, particles = Tex("talents-animations-clouds"), Tex("talent-background-warrior"),
            Tex("talents-animations-particles")
        local heads, hs = {}, {}
        for i, name in ipairs({ "Waffen", "Furor", "Schutz" }) do
            local hf = stub.NewObject("Frame")
            local fs = stub.NewObject("FontString")
            fs._text, fs._font, fs._parent = name, true, hf
            fs.GetStringWidth = function() return 60 end
            fs.SetText = function() error("Name eines Baums ueberschrieben") end
            fs.SetTextColor = function() error("Farbe eines Baums ueberschrieben") end
            hf.GetRegions = function() return fs end
            heads[i], hs[i] = hf, fs
        end
        local node = stub.NewObject("Button")
        local green = Tex("talents-node-square-green")
        local rank = stub.NewObject("FontString")
        rank._text, rank._font = "3", true
        node.GetRegions = function() return green, rank end
        buttons.GetChildren = function() return node end
        tf.GetRegions = function() return clouds, land, particles end
        tf.GetChildren = function() return heads[1], heads[2], heads[3], buttons end
        psf.GetChildren = function() return tf end
        local oldInfo, oldNum = _G.GetTalentTabInfo, _G.GetNumTalentTabs
        local names = { "Waffen", "Furor", "Schutz" }
        _G.GetNumTalentTabs = function() return 3 end
        _G.GetTalentTabInfo = function(i) return 100 + i, names[i], "Beschreibung", 132000 end
        local glow = stub.NewObject("Texture")
        W.done[psf] = { glow = glow }
        local grad, classy, classTex = S.Gradient, 0, {}
        S.Gradient = function(t, dir, c, a0, a1)
            if c == K.Highlight() then classy = classy + 1 classTex[t] = true end
            return grad(t, dir, c, a0, a1)
        end
        TL.Update(psf)
        W.HoldGlow(psf, "PlayerSpellsFrame")
        S.Gradient = grad
        local t = TL.frames[tf]
        assert(t and t.light and t.edge and classTex[t.light] and classTex[t.edge.l], "Licht oder Kante nicht in der Klassenfarbe")
        assert(t.light._parent == tf and t.light:GetDrawLayer() == "OVERLAY" and t.edge.l:GetDrawLayer() == "OVERLAY",
            "Licht oder Kante unter den Wolken (im Spiel nicht zu sehen, 6.8.0.3)")
        assert(#t.order == 3 and t.marks[hs[1]] and t.marks[hs[3]], "Namen der Baeume nicht gefunden: " .. #t.order)
        assert(not t.heads[rank], "Rang eines Talents als Name eines Baums")
        assert(t.marks[hs[2]].dot._parent == heads[2], "Raute nicht am Namen")
        -- 6.8.0.4 im Spiel: Raute zu sehen, Linie und Licht nicht. Linie
        -- kraeftig, Zeile auf dunklem Grund ueber dem Nebel, Licht additiv.
        local h2 = t.marks[hs[2]]
        assert(h2.back and h2.back._parent == heads[2] and h2.back:GetDrawLayer() == "ARTWORK"
            and select(2, h2.back:GetDrawLayer()) < select(2, h2.dot:GetDrawLayer()), "Zeile eines Baums ohne dunklen Grund")
        assert(TL.LINE >= 0.85 and t.light:GetBlendMode() == "ADD", "Linie oder Licht zu schwach fuer den Nebel")
        -- 6.8.0.5 im Spiel: der Grund reichte bis 200 px hinter den Namen,
        -- weit rechts ueber den Baum hinaus. Jetzt feste Breite (etwa ein
        -- Baum), nach rechts ausblendend, die Linie endet davor.
        local rowW = h2.backIn:GetWidth() + h2.back:GetWidth()
        assert(rowW == TL.ROW and TL.ROW <= 240, "Grund nicht auf Baumbreite: " .. tostring(rowW))
        assert(h2.backIn._parent == heads[2] and h2.backIn:GetDrawLayer() == "ARTWORK", "Grund links fehlt")
        local lineEnd = 60 + 2 * TL.GAP + 3 + h2.line:GetWidth()
        assert(h2.line:GetWidth() == TL.LineWidth(60) and lineEnd <= TL.ROW - TL.BACK_LEFT - TL.LINE_END + 1,
            "Linie laeuft ueber den Grund hinaus: " .. tostring(h2.line:GetWidth()))
        assert(TL.LineWidth(400) == TL.MIN_LINE, "Linie bei langem Namen nicht begrenzt")
        -- 6.10.4.2: auch mit Deckkraft 0.9 unsichtbar - es war die Hoehe.
        local oldPhys = _G.GetPhysicalScreenSize
        _G.GetPhysicalScreenSize = function() return 1920, 1080 end
        h2.line.GetEffectiveScale = function() return 0.5 end
        TL.Update(psf)
        assert(math.abs(h2.line:GetHeight() - 768 / 1080 / 0.5) < 1e-6, "Linie eines Baums nicht einen Bildpunkt hoch: " .. tostring(h2.line:GetHeight()))
        -- 6.10.4.3: Oberkante auf halbem Bildpunkt - verschoben.
        h2.line.GetEffectiveScale = function() return 768 / 1080 end   -- eine Einheit = ein Bildpunkt
        local top2, set2 = 400.5, {}
        h2.line.GetTop = function() return top2 end
        h2.line.SetPoint = function(_, p, rel, rp, x, y) set2[#set2 + 1] = y top2 = 400.5 + y end
        TL.Update(psf)
        assert(#set2 == 1 and math.abs(set2[1] + 0.5) < 1e-6 and math.abs(top2 - 400) < 1e-6,
            "Linie eines Baums nicht auf ganze Bildpunkte: " .. tostring(set2[1]))
        TL.Update(psf)
        assert(#set2 == 1, "Linie eines Baums je Durchlauf neu gesetzt")
        h2.line.GetTop, h2.line.SetPoint = nil, nil
        _G.GetPhysicalScreenSize = oldPhys
        h2.line.GetEffectiveScale = nil
        TL.Update(psf)
        assert(h2.line:GetHeight() == 1, "Linie eines Baums ohne Bildschirmmass nicht 1 hoch")
        assert(not glow:IsShown(), "Schein der Klasse ueber den Talenten")
        for _, x in ipairs({ clouds, land, particles, green, rank, hs[1] }) do
            assert(x:IsShown() and x:GetAlpha() == 1, "Animation, Landschaft oder Talent angefasst")
        end
        local rep = table.concat(TL.Report(psf, {}), "\n")
        assert(rep:find("Bäume „Waffen“, „Furor“, „Schutz“ auf dunklem Grund", 1, true)
            and rep:find("Talente, Linie: ", 1, true), "Bericht: " .. rep)
        -- Gefunden ist gefunden: keine weitere Suche.
        local scans = t.scans
        for _ = 1, 5 do TL.Update(psf) end
        assert(t.scans == scans, "sucht weiter, obwohl alle Namen da sind")
        collectgarbage("collect")
        collectgarbage("stop")
        local k0 = collectgarbage("count")
        for _ = 1, 20 do TL.Update(psf) W.HoldGlow(psf, "PlayerSpellsFrame") end
        local grew = collectgarbage("count") - k0
        collectgarbage("restart")
        assert(grew < 1, string.format("Talente legen im Takt Muell an: %.1f KB", grew))
        -- Talente zu, Zauberbuch zu: Schein zurueck, Licht weg.
        tf:Hide()
        TL.Update(psf)
        W.HoldGlow(psf, "PlayerSpellsFrame")
        assert(glow:IsShown() and not t.light:IsShown(), "Schein nicht zurueck oder Licht bleibt")
        W.done[psf] = nil
        -- 6.8.0.4, gemessen: der Forever-Client nennt die Baeume nicht
        -- ("Baeume keine gefunden"). Dann die eigene Klasse aus data/specs.lua.
        local oldUC, oldSpec = _G.UnitClass, _G.GetSpecializationInfo
        _G.GetTalentTabInfo, _G.GetSpecializationInfo = nil, nil
        local function Fresh(class)
            _G.UnitClass = function() return "x", class, 1 end
            TL.frames[tf] = nil
            for _, fs in ipairs(hs) do fs:Show() end
            tf:Show()
            TL.Update(psf)
            return TL.frames[tf]
        end
        local t2 = Fresh("WARRIOR")
        assert(#t2.order == 3 and t2.from[#t2.from] == "data/specs.lua", "Baeume ohne Spiel nicht aus data/specs.lua: " .. #t2.order)
        rep = table.concat(TL.Report(psf, {}), "\n")
        assert(rep:find("Bäume „Waffen“", 1, true) and not rep:find("gesucht", 1, true), "Bericht: " .. rep)
        -- Andere Klasse, kein Name passt: der Bericht sagt, was gesucht wurde
        -- und welche Schrift im Fenster steht.
        local t3 = Fresh("MAGE")
        assert(#t3.order == 0, "fremde Namen gefunden")
        rep = table.concat(TL.Report(psf, {}), "\n")
        assert(rep:find("keine gefunden", 1, true) and rep:find("gesucht: Arkan, Feuer, Frost (aus data/specs.lua)", 1, true)
            and rep:find("„Furor“", 1, true) and not rep:find("„3“", 1, true), "Bericht ohne Hinweis: " .. rep)
        _G.UnitClass, _G.GetSpecializationInfo = oldUC, oldSpec
        _G.GetTalentTabInfo, _G.GetNumTalentTabs = oldInfo, oldNum
        TL.frames[tf] = nil
    end)
    Check(okT, "Talente: Klassenfarbe, Animation unberuehrt, Baeume mit Raute und Linie, kein Schein der Klasse, kein Muell"
        .. (okT and "" or (": " .. tostring(errT))))

    -- 6.6.3.1: der Akzent IST die Klassenfarbe - im ganzen Addon. Violett
    -- auf Wunsch. Es bleibt ein Akzent (accent = purple = violet = brandA).
    local ok4, err4 = pcall(function()
        local C, GC = WeintCodex.Colors, WeintCodex.GameColors
        local oldUC, oldRCC = _G.UnitClass, _G.RAID_CLASS_COLORS
        local function Near(a, b) return math.abs(a - b) < 1e-6 end
        _G.UnitClass = function() return "Jäger", "HUNTER", 3 end
        _G.RAID_CLASS_COLORS = { HUNTER = { r = 0.67, g = 0.83, b = 0.45 } }
        K.ResetHighlight()
        local h = K.Highlight()
        assert(h == C.accent and Near(h[1], 0.67) and Near(h[2], 0.83) and Near(h[3], 0.45), "Akzent nicht in Klassenfarbe")
        for _, k in ipairs({ "purple", "violet", "brandA", "accentDot" }) do
            assert(Near(C[k][1], 0.67) and Near(C[k][3], 0.45), k .. " nicht mitgezogen")
        end
        for _, k in ipairs({ "cast", "xpBar", "targetRing", "targetGlow" }) do
            assert(Near(GC[k][1], 0.67), "Spielfarbe " .. k .. " nicht mitgezogen")
        end
        assert(Near(GC.targetGlow[4], 0.85) and Near(C.washAccent[4], 0.08), "Deckkraft abgeleiteter Toene verloren")
        assert(C.accentBright[2] > C.accent[2] and C.accentDim[2] < C.accent[2], "helle/gedaempfte Stufe nicht abgeleitet")
        assert(Near(C.green[1], 0.204) and Near(C.red[1], 0.957), "Zustandsfarbe veraendert")
        assert(WeintCodex.AC == "|cffABD473", "Farbcode fuer Texte: " .. tostring(WeintCodex.AC))
        K.Set("general", "highlight", "accent")
        K.ResetHighlight()
        assert(Near(C.accent[1], 0.486) and Near(C.purpleDim[1], 0.318) and WeintCodex.AC == "|cff7C6CFF",
            "Violett laesst sich nicht waehlen")
        K.Set("general", "highlight", nil)
        _G.RAID_CLASS_COLORS = nil
        K.ResetHighlight()
        assert(Near(C.accent[1], 0.486), "ohne Klassenfarbe nicht Violett")
        _G.UnitClass, _G.RAID_CLASS_COLORS = oldUC, oldRCC
        K.ResetHighlight()
    end)
    Check(ok4, "Akzent in der Klassenfarbe, im ganzen Addon, wahlweise Violett" .. (ok4 and "" or (": " .. tostring(err4))))
    -- Kein fester Violett-Farbcode im Code: er bliebe Violett, waehrend
    -- alles andere die Klassenfarbe traegt. Nur die Changelog-Daten
    -- behalten ihn (Stilregel), sie werden beim Zeigen umgefaerbt.
    do
        local hits = {}
        for line in toc:gmatch("[^\r\n]+") do
            local file = line:match("^%s*([%w_/]+%.lua)%s*$")
            if file and file ~= "data/changelog.lua" then
                local h = io.open(ROOT .. "/" .. file, "r")
                local src = h and h:read("*a") or ""
                if h then h:close() end
                local n = 0
                for code in src:gmatch("|cff(%x%x%x%x%x%x)") do
                    if code:upper() == "7C6CFF" then n = n + 1 end
                end
                -- Kommentare, die den Code nennen, zaehlen nicht.
                for _ in src:gmatch("%-%-[^\n]*|cff7C6CFF") do n = n - 1 end
                if n > 0 then hits[#hits + 1] = file .. " (" .. n .. ")" end
            end
        end
        Check(#hits == 0, "kein fester Violett-Farbcode in Texten (WeintCodex.AC)"
            .. (#hits == 0 and "" or (": " .. table.concat(hits, ", "))))
    end

    -- 6.6.2.2: Plaketten nach NPC - Zaubernde und eigene Farben.
    local ok3, err3 = pcall(function()
        local NC, NP = WeintCodex.UINpcColors, WeintCodex.UINameplates
        local GC = WeintCodex.GameColors
        assert(NC.NpcID("Creature-0-1-2-3-12345-0000ABCD") == 12345, "Kennung aus der GUID")
        assert(NC.NpcID("Player-1-0ABC") == nil and NC.NpcID(nil) == nil, "Spieler als NPC gelesen")
        local saved = { _G.UnitGUID, _G.UnitName, _G.UnitClass, _G.UnitPowerType, _G.UnitPowerMax, _G.UnitIsPlayer }
        local guid, name, class, ptype = "Creature-0-1-2-3-12345-0000ABCD", "Kobold-Geomant", "MAGE", 0
        _G.UnitGUID = function() return guid end
        _G.UnitName = function() return name end
        _G.UnitClass = function() return "Magier", class end
        _G.UnitPowerType = function() return ptype end
        _G.UnitPowerMax = function() return ptype == 0 and 300 or 0 end
        _G.UnitIsPlayer = function() return false end
        K.Set("npccolors", "rules", nil)
        -- Die Farbe, die der Balken zuletzt bekam (die Attrappe hat keine
        -- Textur am Balken, PaintBar kaeme sonst nicht bis zum Merken).
        local oldPaint, painted = K.PaintBar, {}
        K.PaintBar = function(bar, r, g, b) painted[bar] = { r, g, b } return oldPaint(bar, r, g, b) end
        local function Col(pl) return painted[pl.health] or {} end
        stub.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate1")
        local p = NP.plates["nameplate1"]
        assert(p and p._npcID == 12345 and p._caster, "Magier nicht als Zaubernder erkannt")
        assert(Col(p)[1] == GC.caster[1] and Col(p)[3] == GC.caster[3], "Zaubernder nicht blau")
        assert(NC.Seen()[12345] and NC.Seen()[12345].n == "Kobold-Geomant", "NPC nicht gemerkt")
        stub.FireEvent("NAME_PLATE_UNIT_REMOVED", "nameplate1")
        -- Krieger ohne Mana: erst normal, nach dem ersten Zauber blau - und
        -- beim naechsten Mal gleich.
        guid, name, class, ptype = "Creature-0-1-2-3-777-0000ABCD", "Kobold-Arbeiter", "WARRIOR", 1
        stub.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate1")
        p = NP.plates["nameplate1"]
        assert(not p._caster and Col(p)[1] ~= GC.caster[1], "Nahkaempfer als Zaubernder")
        stub.FireEvent("UNIT_SPELLCAST_START", "nameplate1")
        assert(p._caster and Col(p)[1] == GC.caster[1], "gesehener Zauber faerbt nicht")
        stub.FireEvent("NAME_PLATE_UNIT_REMOVED", "nameplate1")
        stub.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate1")
        p = NP.plates["nameplate1"]
        assert(p._caster, "gesehener Zauber nicht gemerkt")
        -- Eigene Regel: Suche, anlegen, Farbe gilt vor "Zaubernde".
        local hits = NC.Search("kobold")
        assert(#hits == 2 and hits[1].name == "Kobold-Arbeiter", "Suche: " .. #hits)
        assert(#NC.Search("arbeiter") == 1 and not NC.Search("arbeiter")[1].prefix, "Suche mitten im Namen")
        local rule = NC.Add(777, "Kobold-Arbeiter")
        assert(rule and NC.Add(777, "Kobold-Arbeiter") and #NC.Rules() == 1, "Regel doppelt angelegt")
        assert(Col(p)[1] == GC.npcCustom[1], "eigene Farbe gilt nicht")
        NC.SetColor(777, "Kobold-Arbeiter", 0.1, 0.9, 0.2)
        assert(Col(p)[2] == 0.9, "geaenderte Farbe gilt nicht")
        -- Ueber den Namen: jeder mit genau diesem Namen.
        NC.Remove(1)
        NC.Add(nil, "  Kobold-Arbeiter ")
        assert(NC.Rules()[1].name == "Kobold-Arbeiter" and not NC.Rules()[1].id, "Namensregel falsch angelegt")
        assert(Col(p)[1] == GC.npcCustom[1], "Namensregel gilt nicht")
        assert(NC.Add(nil, "   ") == nil, "leerer Name angelegt")
        -- Die Seite laesst sich bauen und zeigt Treffer und Regeln.
        local sw = NC.BuildSearch(UIParent, 600)
        NC.search.text = "kob"
        sw.Sync()
        assert(sw.rows[1]:IsShown() and sw.rows[2]:IsShown() and not sw.rows[3]:IsShown(), "Treffer nicht gezeigt")
        local rw = NC.BuildRules(UIParent, 600)
        rw.Sync()
        assert(rw.rows[1]:IsShown() and not rw.empty:IsShown(), "Regel nicht gelistet")
        NC.search.text = ""
        stub.FireEvent("NAME_PLATE_UNIT_REMOVED", "nameplate1")
        K.Set("npccolors", "rules", nil)
        K.Set("npccolors", "seen", nil)
        K.PaintBar = oldPaint
        _G.UnitGUID, _G.UnitName, _G.UnitClass, _G.UnitPowerType, _G.UnitPowerMax, _G.UnitIsPlayer = unpack(saved, 1, 6)
    end)
    Check(ok3, "Plaketten nach NPC: Zaubernde erkannt und gemerkt, Suche, eigene Farben"
        .. (ok3 and "" or (": " .. tostring(err3))))
    Check(ok, "Weltkarte im WeintCodex-Stil (Karte bleibt), weicher Rand ums Modell"
        .. (ok and "" or (": " .. tostring(err))))

    local CH = WeintCodex.UIChat
    ok, err = pcall(function()
        local oldMoney, oldFree = _G.GetMoney, _G.C_Container
        _G.GetMoney = function() return 1234567 end
        _G.C_Container = { GetContainerNumFreeSlots = function(bag) return bag == 0 and 5 or 2 end }
        CH.ApplyAll()
        local info = CH.info()
        assert(info and info:IsShown(), "keine Infozeile")
        assert(CH.Money():find("123", 1, true) and CH.Money():find("45 s", 1, true), "Gold: " .. CH.Money())
        assert(CH.FreeSlots() == 13, "freie Plaetze: " .. tostring(CH.FreeSlots()))
        _G.C_Container = { GetContainerNumFreeSlots = function() return setmetatable({}, {}) end }
        local oldSecret = _G.issecretvalue
        _G.issecretvalue = function(v) return type(v) == "table" and getmetatable(v) ~= nil end
        assert(CH.FreeSlots() == nil, "geheime Zahl als Taschenplaetze gezaehlt")
        _G.issecretvalue = oldSecret
        _G.GetMoney, _G.C_Container = oldMoney, oldFree
    end)
    Check(ok, "Chat: Infozeile (Gold, Taschen, Unbekanntes bleibt unbekannt)" .. (ok and "" or (": " .. tostring(err))))

    local AB = WeintCodex.UIActionBars
    ok, err = pcall(function()
        local bar = CreateFrame("Frame", "BagsBar", UIParent)
        local b = CreateFrame("Button", "MainMenuBarBackpackButton", bar)
        b.icon = b:CreateTexture()
        local border = b:CreateTexture()
        b.IconBorder = border
        AB.SkinBags()
        assert(AB.skinned[b], "Rucksack nicht umgestaltet")
        assert(border:GetAlpha() == 0, "goldener Rand bleibt")
        assert(AB.bagsBackdrop and AB.bagsBackdrop:IsShown(), "keine Flaeche hinter den Taschen")
        _G.BagsBar, _G.MainMenuBarBackpackButton = nil, nil
    end)
    Check(ok, "Taschenleiste: flach, ohne goldenen Rand, mit Flaeche" .. (ok and "" or (": " .. tostring(err))))

    -- 6.3.0.8: Mikromenue und Taschenleiste nur bei Maus darueber.
    ok, err = pcall(function()
        local micro = CreateFrame("Frame", "MicroMenuContainer", UIParent)
        local bags = CreateFrame("Frame", "BagsBar", UIParent)
        local over = false
        micro.IsMouseOver = function() return over end
        bags.IsMouseOver = function() return false end
        K.Set("actionbars", "microShow", "mouseover")
        K.Set("actionbars", "bagsShow", "mouseover")
        AB.UpdateMouseover()
        assert(micro:GetAlpha() == 0 and bags:GetAlpha() == 0, "ohne Maus sichtbar")
        over = true
        AB._fadeStep(nil, 1)   -- ein langer Schritt: ganz eingeblendet
        assert(micro:GetAlpha() == 1 and bags:GetAlpha() == 0, "Maus ueber dem Mikromenue blendet nicht ein")
        K.Set("actionbars", "microShow", "always")
        K.Set("actionbars", "bagsShow", "always")
        AB.UpdateMouseover()
        assert(micro:GetAlpha() == 1 and bags:GetAlpha() == 1, "zurueck auf Immer bleibt unsichtbar")
        _G.MicroMenuContainer, _G.BagsBar = nil, nil
    end)
    Check(ok, "Mikromenue und Taschenleiste: nur bei Maus darueber" .. (ok and "" or (": " .. tostring(err))))

    -- 6.3.0.8: Zauberbalken - Name statt (leerem) Anzeigetext, Kante,
    -- Latenz beim eigenen Zauber, Symbol abgesetzt.
    ok, err = pcall(function()
        local CB = WeintCodex.UICastBar
        local cb = CB.Create(UIParent)
        cb:ApplyStyle({ height = 20, icon = true, timer = true, latency = true })
        cb.GetWidth = function() return 240 end
        cb._bar.GetWidth = function() return 217 end
        cb:SetUnit("player")
        local oldCast, oldNet, oldDur = _G.UnitCastingInfo, _G.GetNetStats, _G.UnitCastingDuration
        _G.UnitCastingInfo = function() return "Ruhestein", "", "icon", 1000, 11000, false, "x", false end
        _G.GetNetStats = function() return 0, 0, 50, 100 end
        _G.UnitCastingDuration = nil
        cb:Update()
        assert(cb._text:GetText() == "Ruhestein", "Zaubername fehlt: " .. tostring(cb._text:GetText()))
        assert(cb._spark:IsShown(), "keine Kante am Ende der Fuellung")
        assert(cb._latency:IsShown(), "keine Latenz beim eigenen Zauber")
        -- 100 ms von 10 s auf 217 px: gut 2 px.
        local lw = cb._latency:GetWidth()
        assert(type(lw) ~= "number" or (lw > 1.5 and lw < 3), "Latenzbreite: " .. tostring(lw))
        cb:Stop(true)
        assert(not cb._spark:IsShown() and not cb._latency:IsShown(), "Kante/Latenz bleiben nach Abbruch")
        -- Ohne rechenbare Zeiten: keine Latenz (nichts geraten).
        _G.UnitCastingInfo = function() return "Feuerball", nil, "icon", nil, nil, false, "x", false end
        cb._holding = nil
        cb:Update()
        assert(not cb._latency:IsShown(), "Latenz ohne Zeiten")
        _G.UnitCastingInfo, _G.GetNetStats, _G.UnitCastingDuration = oldCast, oldNet, oldDur
    end)
    Check(ok, "Zauberbalken: Name, Kante, Latenz, Symbol abgesetzt" .. (ok and "" or (": " .. tostring(err))))
end

-- 6.3.0.9: Chat-Reiter ueber der Flaeche, Bildlaufleiste weg, Tooltip als
-- Kachel, Minikarte oben, fremde Koordinaten weg.
do
    local ok, err = pcall(function()
        -- Chat: die Flaeche liegt unter dem Chatrahmen (und damit unter
        -- den Reitern), nicht auf ihm.
        local cf = _G.ChatFrame1
        local sbar = stub.NewObject("Frame")
        cf.ScrollBar = sbar
        cf.GetFrameLevel = function() return 5 end
        WeintCodex.UIChat.ApplyAll()
        assert(sbar:GetAlpha() == 0, "Bildlaufleiste sichtbar")
        cf.ScrollBar = nil
    end)
    Check(ok, "Chat: Bildlaufleiste weg" .. (ok and "" or (": " .. tostring(err))))

    ok, err = pcall(function()
        local T = WeintCodex.UITooltip
        local tt = CreateFrame("GameTooltip", "WCTestTooltip", UIParent)
        local ns = stub.NewObject("Frame")
        tt.NineSlice = ns
        local bd = T.Style(tt)
        assert(bd and ns:GetAlpha() == 0, "Blizzard-Rahmen des Tooltips sichtbar")
        -- Spieler: Name und Rand in Klassenfarbe; unbekannte Einheit: nichts.
        local oldGT, oldLine = _G.GameTooltip, _G.GameTooltipTextLeft1
        local line = stub.NewObject("FontString")
        local col
        line.SetTextColor = function(_, r, g, b) col = { r, g, b } end
        _G.GameTooltip, _G.GameTooltipTextLeft1 = tt, line
        local oldIsP, oldClass = _G.UnitIsPlayer, _G.UnitClass
        _G.UnitIsPlayer = function() return true end
        _G.UnitClass = function() return "Krieger", "WARRIOR" end
        _G.RAID_CLASS_COLORS = _G.RAID_CLASS_COLORS or {}
        _G.RAID_CLASS_COLORS.WARRIOR = _G.RAID_CLASS_COLORS.WARRIOR or { r = 0.78, g = 0.61, b = 0.43 }
        tt.GetUnit = function() return "Aloha", "mouseover" end
        T.OnUnit(tt)
        assert(col and math.abs(col[1] - _G.RAID_CLASS_COLORS.WARRIOR.r) < 0.01, "Name nicht in Klassenfarbe")
        col = nil
        tt.GetUnit = function() return nil, nil end
        T.OnUnit(tt)
        assert(col == nil, "Farbe ohne bekannte Einheit")
        _G.GameTooltip, _G.GameTooltipTextLeft1 = oldGT, oldLine
        _G.UnitIsPlayer, _G.UnitClass = oldIsP, oldClass
    end)
    Check(ok, "Tooltip: Kachel statt Blizzard-Rahmen, Klassenfarbe nur bei bekannter Einheit" .. (ok and "" or (": " .. tostring(err))))

    ok, err = pcall(function()
        local MM = WeintCodex.UIMinimap
        assert(MM.LooksLikeCoords("56.3, 30.6") and MM.LooksLikeCoords("56, 31"), "Koordinaten nicht erkannt")
        assert(not MM.LooksLikeCoords("7:15") and not MM.LooksLikeCoords("Saldeans Farm") and not MM.LooksLikeCoords("15 min"),
            "Uhrzeit/Gebiet als Koordinaten erkannt")
        local cl = _G.MinimapCluster or CreateFrame("Frame", "MinimapCluster", UIParent)
        _G.MinimapCluster = cl
        local other = stub.NewObject("FontString")
        other.GetObjectType = function() return "FontString" end
        other.GetText = function() return "56.3, 30.6" end
        local zoneFs = stub.NewObject("FontString")
        zoneFs.GetObjectType = function() return "FontString" end
        zoneFs.GetText = function() return "Saldeans Farm" end
        cl.GetRegions = function() return other, zoneFs end
        local n = MM.HideOtherCoords()
        assert(n == 1 and other:GetAlpha() == 0 and zoneFs:GetAlpha() ~= 0, "fremde Koordinaten: " .. tostring(n))
        cl.GetRegions = nil
        -- Karte oben im Bereich.
        local mm = _G.Minimap
        if mm then
            local pt
            mm.SetPoint = function(_, p, rel, rp, x, y) pt = { p, rel, rp, x, y } end
            MM.PlaceMap()
            assert(pt and pt[1] == "TOPRIGHT" and pt[2] == cl and pt[5] == -6, "Karte nicht oben")
        end
    end)
    Check(ok, "Minikarte: oben im Bereich, fremde Koordinaten weg" .. (ok and "" or (": " .. tostring(err))))

    -- 6.3.1.1: Addon-Knoepfe (LibDBIcon) in den Sammelknopf, andere kleine
    -- Knoepfe auf der Karte (Wegpunkte) bleiben; Tageszeit unten rechts.
    ok, err = pcall(function()
        local MM = WeintCodex.UIMinimap
        local mm = _G.Minimap
        local addonBtn = CreateFrame("Button", "LibDBIcon10_TestAddon", mm)
        local pin = CreateFrame("Button", "HBDPin1", mm)
        local oldKids = mm.GetChildren
        mm.GetChildren = function() return addonBtn, pin end
        local found, pinFound = false, false
        for _, b in ipairs(MM.AddonButtons()) do
            if b == addonBtn then found = true end
            if b == pin then pinFound = true end
        end
        assert(found, "Addon-Knopf nicht erkannt")
        assert(not pinFound, "Kartenmarkierung als Addon-Knopf eingesammelt")
        MM.LayoutBag()
        local bag, flyout = MM.Bag()
        assert(bag and bag:IsShown(), "kein Sammelknopf")
        assert(addonBtn:GetParent() == flyout, "Addon-Knopf nicht im Sammelknopf")
        assert(not flyout:IsShown(), "Liste steht offen")
        bag._scripts.OnClick(bag)
        assert(flyout:IsShown(), "Klick klappt nicht auf")
        bag._scripts.OnClick(bag)
        for _, b in ipairs(MM.ColumnButtons()) do assert(b ~= addonBtn, "Addon-Knopf zusaetzlich in der Spalte") end
        mm.GetChildren = oldKids
        -- Tageszeit unten rechts an der Karte.
        local gt = CreateFrame("Button", "GameTimeFrame", UIParent)
        local pt
        gt.SetPoint = function(_, p, rel, rp, x, y) pt = { p, rel, rp, x, y } end
        MM.LayoutButtons()
        assert(pt and pt[1] == "BOTTOMRIGHT" and pt[2] == mm and pt[3] == "BOTTOMRIGHT", "Tageszeit nicht unten rechts")
        _G.GameTimeFrame, _G.LibDBIcon10_TestAddon, _G.HBDPin1 = nil, nil, nil
        assert(WeintCodex.UIChat.Inspect()[1]:find("Chatfenster 1", 1, true), "/wcui chat ohne Auskunft")
    end)
    Check(ok, "Minikarte: Sammelknopf fuer Addons, Wegpunkte bleiben, Tageszeit unten rechts" .. (ok and "" or (": " .. tostring(err))))

    -- 6.5.0.0: eigene Knoepfe ohne LibDBIcon kommen ueber ihren Namen in
    -- die Liste und bleiben drin, auch wenn sie keine Kinder der Karte
    -- mehr sind; Knoepfe des Spiels nicht; /wcui addons zaehlt sie.
    ok, err = pcall(function()
        local MM = WeintCodex.UIMinimap
        local mm = _G.Minimap
        local own = CreateFrame("Button", "TestAddonMinimapButton", mm)
        local game = CreateFrame("Button", "ExpansionLandingPageMinimapButton", mm)
        local pin = CreateFrame("Button", "HBDPin2", mm)
        assert(MM.LooksLikeAddonButton("Foo_MiniMapButton") and MM.LooksLikeAddonButton("LibDBIcon10_Bar"), "Name nicht erkannt")
        assert(not MM.LooksLikeAddonButton("MiniMapTracking") and not MM.LooksLikeAddonButton("HBDPin2"), "falscher Name erkannt")
        local oldKids = mm.GetChildren
        mm.GetChildren = function() return own, game, pin end
        local function Has(b)
            for _, x in ipairs(MM.AddonButtons()) do if x == b then return true end end
            return false
        end
        assert(Has(own), "eigener Knopf nicht erkannt")
        assert(not Has(game) and not Has(pin), "Spielknopf oder Markierung eingesammelt")
        MM.LayoutBag()
        mm.GetChildren = function() return end
        assert(Has(own), "Knopf aus der Liste gefallen, nachdem er in die Kachel kam")
        local lines = MM.InspectAddons()
        assert(lines[1]:find("Addon-Knöpfe in der Liste", 1, true), "/wcui addons ohne Auskunft")
        local named = false
        for _, l in ipairs(lines) do if l:find("TestAddonMinimapButton", 1, true) then named = true end end
        assert(named, "/wcui addons nennt den Knopf nicht")
        own:Hide()
        assert(not Has(own), "ausgeblendeter Knopf in der Liste")
        mm.GetChildren = oldKids
        _G.TestAddonMinimapButton, _G.ExpansionLandingPageMinimapButton, _G.HBDPin2 = nil, nil, nil
    end)
    Check(ok, "Minikarte: eigene Addon-Knoepfe ueber den Namen, bleiben in der Liste, /wcui addons" .. (ok and "" or (": " .. tostring(err))))

    -- 6.3.1.2: Addon-Knoepfe liegen in der Schicht ihrer Liste (sonst
    -- dunkelt deren Kachel sie ab), die Tageszeit wird auch unter anderem
    -- Namen gefunden, /wcui maus beschreibt die Rahmen unter der Maus.
    ok, err = pcall(function()
        local MM, K = WeintCodex.UIMinimap, WeintCodex.UIKit
        local mm = _G.Minimap
        local addonBtn = CreateFrame("Button", "LibDBIcon10_TestAddon", mm)
        local strata
        addonBtn.SetFrameStrata = function(_, v) strata = v end
        local oldKids = mm.GetChildren
        mm.GetChildren = function() return addonBtn end
        local _, flyout = MM.Bag()
        flyout.GetFrameStrata = function() return "DIALOG" end
        MM.LayoutBag()
        assert(addonBtn:GetParent() == flyout, "Addon-Knopf nicht in der Liste")
        assert(strata == "DIALOG", "Addon-Knopf liegt unter der Kachel der Liste")
        -- Ohne Sammelknopf zurueck an die Karte.
        K.Set("minimap", "addonBag", false)
        MM.ColumnButtons()
        assert(addonBtn:GetParent() == mm, "Addon-Knopf bleibt in der versteckten Liste haengen")
        K.Set("minimap", "addonBag", nil)
        -- Tageszeit unter anderem Namen, als Kind des Kartenbereichs.
        local cl = _G.MinimapCluster
        local sun = CreateFrame("Button", nil, cl)
        sun.GetDebugName = function() return "MinimapCluster.DayNightFrame" end
        local oldCl = cl.GetChildren
        cl.GetChildren = function() return sun end
        mm.GetChildren = function() return end
        assert(MM.TimeButton() == sun, "Tageszeit unter anderem Namen nicht gefunden")
        cl.GetChildren, mm.GetChildren = oldCl, oldKids
        _G.LibDBIcon10_TestAddon = nil
        -- /wcui maus
        local oldFoci = _G.GetMouseFoci
        _G.GetMouseFoci = function() return { sun } end
        local lines = K.InspectMouse()
        assert(lines[1]:find("DayNightFrame", 1, true), "/wcui maus nennt den Rahmen nicht")
        _G.GetMouseFoci = function() return {} end
        assert(K.InspectMouse()[1]:find("kein Rahmen", 1, true), "/wcui maus ohne Rahmen stumm")
        _G.GetMouseFoci = oldFoci
    end)
    Check(ok, "Minikarte: Addon-Knoepfe hell, Tageszeit unter anderem Namen, /wcui maus" .. (ok and "" or (": " .. tostring(err))))

    -- 6.3.1.3: Die Chatflaeche liegt eine Schicht unter den Reitern (das
    -- Spiel hob sie in LOW auf die Stufe des Chatrahmens, ueber die
    -- Reiter); /wcui maus findet auch Texturen ohne Mausannahme.
    ok, err = pcall(function()
        local K = WeintCodex.UIKit
        local strata, fixed = nil, nil
        local back = {
            SetFrameStrata = function(_, v) strata = v end,
            SetFrameLevel = function() end,
            SetFixedFrameStrata = function(_, v) fixed = v end,
        }
        WeintCodex.UIChat.PinBack({ back = back })
        assert(strata == "BACKGROUND" and fixed == true, "Chatflaeche nicht unter den Reitern")

        local function Box(name, l, b, size, extra)
            local o = {
                GetName = function() return name end,
                GetLeft = function() return l end, GetRight = function() return l + size end,
                GetBottom = function() return b end, GetTop = function() return b + size end,
                GetEffectiveScale = function() return 1 end,
                IsVisible = function() return true end, IsShown = function() return true end,
                GetAlpha = function() return 1 end,
            }
            for k, v in pairs(extra or {}) do o[k] = v end
            return o
        end
        local sun = Box("SunTexture", 90, 90, 20, {
            GetObjectType = function() return "Texture" end,
            GetTexture = function() return "Interface\\Sun" end,
        })
        local map = Box("TestMap", 0, 0, 200, {
            GetObjectType = function() return "Frame" end,
            GetRegions = function() return sun end,
            IsMouseEnabled = function() return false end,
        })
        local oldEnum, oldCursor = _G.EnumerateFrames, _G.GetCursorPosition
        _G.EnumerateFrames = function(f) if f == nil then return map end return nil end
        _G.GetCursorPosition = function() return 100, 100 end
        local hits = K.UnderCursor()
        assert(#hits == 2 and hits[1].line:find("Interface", 1, true), "Textur unter der Maus nicht gefunden")
        _G.GetCursorPosition = function() return 300, 300 end
        assert(#K.UnderCursor() == 0, "Rahmen neben der Maus gemeldet")
        _G.EnumerateFrames, _G.GetCursorPosition = oldEnum, oldCursor
    end)
    Check(ok, "Chat: Flaeche unter den Reitern; /wcui maus findet Texturen" .. (ok and "" or (": " .. tostring(err))))

    -- 6.3.1.4: Die Tageszeit heisst im Beta-Client MinimapCluster.DielFrame;
    -- Addon-Knoepfe in der Liste bleiben voll deckend.
    ok, err = pcall(function()
        local MM = WeintCodex.UIMinimap
        local cl, mm = _G.MinimapCluster, _G.Minimap
        local diel = CreateFrame("Frame", nil, cl)
        cl.DielFrame = diel
        assert(MM.TimeButton() == diel, "DielFrame nicht als Tageszeit erkannt")
        cl.DielFrame = nil
        local addonBtn = CreateFrame("Button", "LibDBIcon10_TestAddon", mm)
        local alpha
        addonBtn.SetAlpha = function(_, a) alpha = a end
        local oldKids = mm.GetChildren
        mm.GetChildren = function() return addonBtn end
        alpha = 0.3
        MM.LayoutBag()
        assert(alpha == 1, "Addon-Knopf in der Liste nicht voll deckend")
        mm.GetChildren = oldKids
        _G.LibDBIcon10_TestAddon = nil
        -- Andockleiste der Chat-Reiter eine Schicht ueber den Chat.
        local oldDock = _G.GeneralDockManager
        local dstrata
        _G.GeneralDockManager = { SetFrameStrata = function(_, v) dstrata = v end }
        WeintCodex.UIChat.RaiseDock()
        assert(dstrata == "MEDIUM", "Reiterleiste nicht ueber dem Chat")
        _G.GeneralDockManager = oldDock
    end)
    Check(ok, "Minikarte: DielFrame als Tageszeit, Addon-Knoepfe voll deckend; Chat-Reiter oben" .. (ok and "" or (": " .. tostring(err))))
end

-- Die Seitenleiste des Einstellungsfensters traegt jetzt zwoelf Eintraege.
-- Sie rollt nie - also muss sie passen, mit Luft fuer einen weiteren.
Check((UO._sidebarUsed or 9999) + 40 <= UO.HEIGHT,
    "Seitenleiste des Einstellungsfensters: " .. tostring(UO._sidebarUsed)
    .. " von " .. tostring(UO.HEIGHT) .. " px, Luft fuer einen weiteren Eintrag")

-- Und die Seite im Hauptfenster, die hierher fuehrt.
do
    -- Ansicht 4 ausdruecklich waehlen: SwitchTo schlaegt die zuletzt
    -- gewaehlte auf, und das ist im Prueflauf die erste.
    local ok, err = pcall(function()
        WeintCodex.Navigation.SwitchTo("settings")
        WeintCodex.Navigation.ActivateIndex(4)
        -- Die Brotkrume ist versal und gesperrt (SetBreadcrumb).
        local crumb = WeintCodex.Breadcrumb:GetText() or ""
        local want = WeintCodex.Spaced(WeintCodex.Upper("Oberfläche"))
        assert(crumb:find(want, 1, true),
            "Brotkrume zeigt nicht die Ansicht Oberflaeche: " .. tostring(crumb))
    end)
    Check(ok, "Einstellungsseite mit Ansicht 'Oberflaeche' zeichnet"
        .. (ok and "" or (": " .. tostring(err))))
end

-- Queststatus im Dungeonkompendium (6.9.0.7): was der Client sagt -
-- erledigt, abgabebereit, im Questlog, fehlt, zu niedrig. Antwortet er
-- nicht, steht nichts da (unbekannt ist nicht "fehlt").
do
    local DP = WeintCodex.DungeonPages
    local saved = { _G.C_QuestLog, _G.IsQuestFlaggedCompleted, _G.UnitLevel, _G.UnitFactionGroup }
    local ok, err = pcall(function()
        local done, log, complete, level = {}, {}, {}, 20
        _G.IsQuestFlaggedCompleted = nil
        _G.C_QuestLog = {
            IsQuestFlaggedCompleted = function(id) return done[id] == true end,
            GetLogIndexForQuestID = function(id) return log[id] end,
            IsComplete = function(id) return complete[id] == true end,
        }
        _G.UnitLevel = function() return level end
        _G.UnitFactionGroup = function() return "Horde" end
        local Q = function(id, req) return { id = id, requires = req or 10 } end
        done[1] = true; log[2] = 3; complete[2] = true; log[3] = 4
        assert(DP.QuestState(Q(1)) == "done", "erledigt nicht erkannt")
        assert(DP.QuestState(Q(2)) == "ready", "abgabebereit nicht erkannt")
        assert(DP.QuestState(Q(3)) == "active", "im Questlog nicht erkannt")
        assert(DP.QuestState(Q(4)) == "open", "fehlende Quest nicht erkannt")
        assert(DP.QuestState(Q(5, 25)) == "later", "zu niedrige Stufe nicht erkannt")
        -- Unbekannt bleibt unbekannt.
        _G.C_QuestLog.IsQuestFlaggedCompleted = nil
        assert(DP.QuestState(Q(4)) == nil, "ohne Antwort auf 'erledigt' trotzdem ein Status")
        _G.C_QuestLog.IsQuestFlaggedCompleted = function() return true end
        _G.C_QuestLog.IsQuestFlaggedCompleted = function() error("gesperrt") end
        assert(DP.QuestState(Q(4)) == nil, "Fehler des Clients als Status gelesen")
        _G.C_QuestLog.IsQuestFlaggedCompleted = function(id) return done[id] == true end
        _G.C_QuestLog.GetLogIndexForQuestID = function() error("gesperrt") end
        assert(DP.QuestState(Q(4)) == nil, "ohne Antwort auf 'im Log' trotzdem 'fehlt'")
        _G.C_QuestLog.IsOnQuest = function(id) return id == 3 end
        assert(DP.QuestState(Q(3)) == "active" and DP.QuestState(Q(4)) == "open", "IsOnQuest als Ersatz nicht genutzt")
        _G.C_QuestLog.IsOnQuest = nil
        _G.C_QuestLog.GetLogIndexForQuestID = function(id) return log[id] end

        -- Auf der Seite: Ragefire Chasm (Horde). Jede Kachel traegt ihren
        -- Status, oben rechts die Summe.
        local quests = WeintCodex.DungeonJournal.Quests("ragefire_chasm", "horde")
        assert(#quests >= 3, "Voraussetzung: Quests in Ragefire Chasm")
        for k in pairs(done) do done[k] = nil end
        for k in pairs(log) do log[k] = nil end
        done[quests[1].id] = true
        log[quests[2].id] = 1
        DP.Select("ragefire_chasm", nil)
        WeintCodex.Navigation.SwitchTo("dungeons")
        assert(#DP.questMarks == #quests, "nicht jede Kachel hat einen Status (" .. #DP.questMarks .. " von " .. #quests .. ")")
        local byId = {}
        for _, m in ipairs(DP.questMarks) do byId[m.q.id] = m end
        assert(byId[quests[1].id].fs:GetText() == "Erledigt", "Kachel 'Erledigt' fehlt")
        assert(byId[quests[2].id].fs:GetText() == "Im Questlog", "Kachel 'Im Questlog' fehlt")
        assert(byId[quests[3].id].fs:GetText() == "Fehlt noch", "Kachel 'Fehlt noch' fehlt")
        local sum = DP.QuestSummaryText() or ""
        assert(sum:find("1 im Questlog", 1, true) and sum:find("1 erledigt", 1, true),
            "Summe falsch: " .. sum)
        -- Annehmen: die Kachel faerbt sich um, ohne neu zu zeichnen.
        for _, m in ipairs(DP.questMarks) do m.fs:Show() end
        log[quests[3].id] = 2
        stub.FireEvent("QUEST_ACCEPTED", quests[3].id)
        assert(byId[quests[3].id].fs:GetText() == "Im Questlog", "nach dem Annehmen nicht umgefaerbt")
        -- Kein Client, kein Status - und keine Summe.
        _G.C_QuestLog = nil
        DP.Select("ragefire_chasm", nil)
        WeintCodex.Navigation.SwitchTo("dungeons")
        for _, m in ipairs(DP.questMarks) do
            assert(m.fs:GetText() == "" and not m.state, "ohne Client ein Status: " .. tostring(m.fs:GetText()))
        end
        assert((DP.QuestSummaryText() or "") == "", "ohne Client eine Summe")
    end)
    _G.C_QuestLog, _G.IsQuestFlaggedCompleted, _G.UnitLevel, _G.UnitFactionGroup = unpack(saved, 1, 4)
    Check(ok, "Queststatus: erledigt, abgabebereit, im Questlog, fehlt, zu niedrig; unbekannt bleibt leer; Summe; Umfaerben beim Annehmen"
        .. (ok and "" or (": " .. tostring(err))))
end

-- Bruecke zum Bearbeitungsmodus des Spiels (6.9.0.5): was WeintCodex nicht
-- verschiebt, erreicht ein Knopf - und wer von hier kam, kommt zurueck.
do
    local E = WeintCodex.UIEditMode
    local sd = WeintCodex.SavedData
    local saved = { _G.EditModeManagerFrame, _G.ShowUIPanel, _G.C_Timer.After, _G.InCombatLockdown,
                    _G.SLASH_EDITMODE1, _G.SlashCmdList.EDITMODE, sd.ui.enabled, K.OPT_IN }
    local ok, err = pcall(function()
        sd.ui.enabled, K.OPT_IN = true, true
        _G.C_Timer.After = function(_, fn) fn() end
        _G.InCombatLockdown = function() return false end
        _G.SLASH_EDITMODE1, _G.SlashCmdList.EDITMODE = nil, nil
        -- Das Fenster des Spiels: Show/Hide loesen OnShow/OnHide aus wie im Client.
        local game = CreateFrame("Frame")
        function game:Show() self._shown = true local f = self:GetScript("OnShow") if f then f(self) end end
        function game:Hide() self._shown = false local f = self:GetScript("OnHide") if f then f(self) end end
        -- Sein X oben rechts: schliesst das Fenster.
        game.CloseButton = CreateFrame("Button")
        game.CloseButton:SetScript("OnClick", function() game:Hide() end)
        _G.EditModeManagerFrame = game
        local opens = 0
        _G.ShowUIPanel = function(f) opens = opens + 1 f:Show() end
        assert(E.HookGame(), "Fenster des Spiels nicht eingehakt")
        assert(E.GamePath() == "direct", "ohne Befehl nicht der direkte Weg: " .. E.GamePath())

        -- 1. Aus dem Gestaltungsmodus hinueber und zurueck.
        UO.frame:Hide()
        assert(K.SetUnlocked(true), "Gestaltungsmodus geht nicht an")
        local gb = E.buttons.game
        assert(gb and gb:GetScript("OnClick"), "Knopf zum Bearbeitungsmodus fehlt in der Leiste")
        gb:Click()
        assert(opens == 1 and E.GameShown(), "Bearbeitungsmodus des Spiels nicht geoeffnet")
        assert(not K.IsUnlocked(), "Gestaltungsmodus bleibt offen unter dem des Spiels")
        assert(E.StripShown(), "keine Leiste unter dem Bearbeitungsmodus des Spiels")
        assert(E.bridge.from == "design", "Rueckweg nicht gemerkt: " .. tostring(E.bridge.from))
        game:Hide()
        assert(not E.StripShown(), "Leiste bleibt nach dem Schliessen")
        assert(K.IsUnlocked(), "nach dem Schliessen nicht zurueck im Gestaltungsmodus")
        K.SetUnlocked(false)

        -- 2. Aus dem Einstellungsfenster hinueber und zurueck auf dieselbe Seite.
        UO.Show("general", 1)
        local cell
        for _, w in ipairs(UO.CurrentWidgets()) do if w._gameEditMode then cell = w._gameEditMode end end
        assert(cell, "Allgemein: kein Knopf zum Bearbeitungsmodus des Spiels")
        cell:Click()
        assert(E.GameShown() and not UO.frame:IsShown(), "Einstellungsfenster bleibt ueber dem Bearbeitungsmodus")
        assert(E.bridge.from == "options", "Rueckweg ins Fenster nicht gemerkt")
        game:Hide()
        assert(UO.frame:IsShown(), "nach dem Schliessen nicht zurueck im Einstellungsfenster")

        -- 3. Der Knopf zurueck: ein sicherer Knopf klickt das X des Spiels
        -- (das Spiel schliesst selbst, samt Rueckfrage); erst wenn es zu
        -- ist, geht der Gestaltungsmodus auf - und nach Fertig das Fenster.
        cell:Click()
        local sb = E.StripButton()
        local back = sb and sb._gameBack
        assert(back and back:GetAttribute("type") == "click" and back:GetAttribute("clickbutton") == game.CloseButton
            and back:GetAttribute("useOnKeyDown") == false, "Knopf zurueck klickt nicht das X des Spiels")
        assert(back:GetScript("PreClick") == E.PrepareBack, "Rueckweg nicht vor dem Klick gemerkt")
        back:GetScript("PreClick")(back)
        assert(E.GameShown() and not K.IsUnlocked(), "Gestaltungsmodus geht auf, bevor das Spiel geschlossen hat")
        game.CloseButton:Click()              -- das Spiel fuehrt den Klick aus
        assert(not E.GameShown() and K.IsUnlocked() and not UO.frame:IsShown(), "zurueck: nicht im Gestaltungsmodus")
        K.SetUnlocked(false)
        assert(UO.frame:IsShown(), "nach Fertig nicht zurueck im Einstellungsfenster")
        -- Rueckfrage abgebrochen (das X schliesst nicht): nichts geht auf,
        -- bis man wirklich schliesst.
        cell:Click()
        back:GetScript("PreClick")(back)
        assert(E.GameShown() and not K.IsUnlocked() and not UO.frame:IsShown(), "abgebrochen und trotzdem gewechselt")
        game:Hide()
        assert(K.IsUnlocked(), "nach dem Schliessen nicht im Gestaltungsmodus")
        K.SetUnlocked(false)
        -- Ohne X: der Rueckweg wird gemerkt, ein Satz sagt den Rest.
        local x = game.CloseButton
        game.CloseButton = nil
        UO.frame:Hide()
        local fb = WeintCodex.CreateButton(UIParent, { text = "z" })
        assert(E.AttachBack(fb) == nil, "ohne X ein sicherer Knopf")
        game:Show()                           -- ueber Esc hinein
        assert(E.bridge.from == nil, "ueber Esc hinein und schon ein Rueckweg")
        fb:Click()
        assert(E.bridge.from == "design", "ohne X: Rueckweg nicht gemerkt")
        game:Hide()
        assert(K.IsUnlocked(), "ohne X: nach dem Schliessen nicht im Gestaltungsmodus")
        K.SetUnlocked(false)
        game.CloseButton = x
        -- Die Leiste traegt einen geschuetzten Knopf: im Kampf nie
        -- ausblenden, beim Kampfbeginn (vor der Sperre) schon.
        game:Show()
        assert(E.StripShown(), "Leiste fehlt (Voraussetzung)")
        _G.InCombatLockdown = function() return true end
        E.HideStrip()
        assert(E.StripShown(), "Leiste mit geschuetztem Knopf im Kampf ausgeblendet")
        _G.InCombatLockdown = function() return false end
        stub.FireEvent("PLAYER_REGEN_DISABLED")
        assert(not E.StripShown(), "Leiste beim Kampfbeginn nicht weg")
        stub.FireEvent("PLAYER_REGEN_ENABLED")
        game:Hide()
        UO.frame:Hide()

        -- 3b. Fenster -> Gestaltungsmodus -> Spiel: das Fenster wartet, bis
        -- der Gestaltungsmodus fertig ist, und geht nicht mit dem Spiel auf.
        UO.Show("general", 1)
        K.SetUnlocked(true)
        assert(not UO.frame:IsShown(), "Fenster bleibt im Gestaltungsmodus offen (Voraussetzung)")
        E.buttons.game:Click()
        assert(E.GameShown() and not UO.frame:IsShown(), "Fenster geht mit dem Bearbeitungsmodus des Spiels auf")
        game:Hide()
        assert(K.IsUnlocked() and not UO.frame:IsShown(), "zurueck: nicht im Gestaltungsmodus")
        K.SetUnlocked(false)
        assert(UO.frame:IsShown(), "nach Fertig nicht zurueck im Fenster, aus dem man kam")

        -- 4. Geht er nicht auf: sofort zurueck, wo man war.
        UO.frame:Hide()
        _G.ShowUIPanel = function() end
        K.SetUnlocked(true)
        E.buttons.game:Click()
        assert(K.IsUnlocked() and E.bridge.from == nil, "nicht geoeffnet und trotzdem weg")
        K.SetUnlocked(false)
        _G.ShowUIPanel = function(f) f:Show() end

        -- 5. Im Kampf: nichts aendert sich.
        _G.InCombatLockdown = function() return true end
        assert(not E.OpenGame() and not E.GameShown(), "im Kampf geoeffnet")
        _G.InCombatLockdown = function() return false end

        -- 6. Mit Befehl des Spiels: ein sicherer Knopf fuehrt ihn als Makro
        -- aus; Platz gemacht wird erst danach (PostClick).
        _G.SLASH_EDITMODE1 = "/editmode"
        _G.SlashCmdList.EDITMODE = function() game:Show() end
        assert(E.GamePath() == "slash", "Befehl nicht erkannt")
        local b = WeintCodex.CreateButton(UIParent, { text = "x" })
        local ov = E.AttachGame(b)
        assert(ov and ov:GetAttribute("type") == "macro" and ov:GetAttribute("macrotext") == "/editmode"
            and ov:GetAttribute("useOnKeyDown") == false, "kein sicherer Makroknopf mit /editmode")
        assert(ov:GetScript("PostClick") == E.AfterGameClick, "Platz machen nicht nach dem Klick")
        assert(ov:GetScript("PreClick") == E.NoteOrigin, "Ausgangsort nicht VOR dem Klick gemerkt")
        local function SecureClick()           -- Reihenfolge wie im Client
            ov:GetScript("PreClick")(ov)
            _G.SlashCmdList.EDITMODE()         -- das Makro, ausgefuehrt vom Spiel
            ov:GetScript("PostClick")(ov)
        end
        K.SetUnlocked(true)
        SecureClick()
        assert(not K.IsUnlocked() and E.bridge.from == "design", "nach dem Makro nicht hinueber")
        game:Hide()
        assert(K.IsUnlocked(), "mit Befehl: nicht zurueck im Gestaltungsmodus")
        K.SetUnlocked(false)
        -- 6.9.0.7, Beta-Test: das Spiel SCHLIESST beim Oeffnen selbst das
        -- Einstellungsfenster (UISpecialFrames). Der Rueckweg muss vorher
        -- gemerkt sein - und zurueck geht es auf dieselbe Seite.
        _G.SlashCmdList.EDITMODE = function() UO.frame:Hide() game:Show() end
        UO.Show("actionbars", 2)
        local before = UO.Where()
        assert(before.module == "actionbars" and before.page == 2, "Voraussetzung: Aktionsleisten, Seite 2")
        SecureClick()
        assert(E.GameShown() and not UO.frame:IsShown() and E.bridge.from == "options",
            "Fenster vom Spiel geschlossen: Rueckweg verloren (" .. tostring(E.bridge.from) .. ")")
        game:Hide()
        local after = UO.Where()
        assert(UO.frame:IsShown() and after.module == "actionbars" and after.page == 2,
            "nicht zurueck auf derselben Seite: " .. tostring(after.module) .. "/" .. tostring(after.page))
        -- Und ueber den Gestaltungsmodus: Fenster -> Gestaltung -> Spiel ->
        -- Gestaltung -> Fertig landet wieder auf derselben Seite.
        K.SetUnlocked(true)
        SecureClick()
        game:Hide()
        assert(K.IsUnlocked(), "ueber den Gestaltungsmodus: nicht zurueck")
        K.SetUnlocked(false)
        after = UO.Where()
        assert(UO.frame:IsShown() and after.module == "actionbars" and after.page == 2,
            "nach Fertig nicht auf derselben Seite: " .. tostring(after.module) .. "/" .. tostring(after.page))
        UO.frame:Hide()
        _G.SlashCmdList.EDITMODE = function() game:Show() end
        -- Im Kampf wird kein sicherer Knopf angelegt.
        _G.InCombatLockdown = function() return true end
        assert(E.AttachGame(WeintCodex.CreateButton(UIParent, { text = "y" })) == nil, "sicherer Knopf im Kampf angelegt")
        _G.InCombatLockdown = function() return false end
        assert(E.Report():find("/editmode", 1, true), "Diagnose nennt den Weg nicht")

        -- 7. Jede Seite, deren Rahmen das Spiel stellt, hat den Knopf.
        local want = { general = true, actionbars = true, minimap = true, questtracker = true,
                       groupframes = true, reminders = true }
        local found = {}
        for _, key in ipairs(K.order) do
            for i in ipairs(K.Module(key).pages) do
                UO.Show(key, i)
                for _, w in ipairs(UO.CurrentWidgets()) do
                    if w._gameEditMode then found[key] = true end
                end
            end
        end
        local missing = {}
        for key in pairs(want) do if not found[key] then missing[#missing + 1] = key end end
        table.sort(missing)
        assert(#missing == 0, "ohne Knopf zum Bearbeitungsmodus: " .. table.concat(missing, ", "))
        UO.frame:Hide()
    end)
    _G.EditModeManagerFrame, _G.ShowUIPanel, _G.C_Timer.After, _G.InCombatLockdown,
        _G.SLASH_EDITMODE1, _G.SlashCmdList.EDITMODE, sd.ui.enabled, K.OPT_IN = unpack(saved, 1, 8)
    if K.IsUnlocked() then K.SetUnlocked(false) end
    Check(ok, "Bruecke zum Bearbeitungsmodus des Spiels: hinueber und zurueck (Gestaltung, Fenster), Knopf zurueck ueber das X des Spiels, ohne X, Kampf, nicht aufgegangen, Kampf, /editmode als Makro, Knopf auf jeder Seite"
        .. (ok and "" or (": " .. tostring(err))))
end

-- 6.9.0.8: Schadensanzeige wie Details - pro Sekunde als Rangliste,
-- Bedrohung, Melden in den Chat; an den Plaketten Bedrohungsleiste und
-- wer die Aggro hat.
do
    local DM = WeintCodex.UIDamageMeter
    local NP = WeintCodex.UINameplates
    local names = { "UnitExists", "UnitCanAttack", "UnitDetailedThreatSituation", "IsInGroup", "IsInRaid",
        "UnitName", "UnitClass", "UnitIsUnit", "InCombatLockdown", "SendChatMessage", "issecretvalue",
        "UnitIsPlayer", "IsInGuild", "UnitGroupRolesAssigned", "UnitPlayerControlled", "C_DamageMeter", "print" }
    local saved = {}
    for i, n in ipairs(names) do saved[i] = _G[n] end
    local savedEnum = _G.Enum and _G.Enum.DamageMeterType
    local savedSess = _G.Enum and _G.Enum.DamageMeterSessionType
    local printed = {}
    local ok, err = pcall(function()
        _G.print = function(s) printed[#printed + 1] = tostring(s) end
        _G.Enum = _G.Enum or {}
        local w = DM.Window(1)

        -- 1. Messarten: nur, was der Client nennt; ohne Enum die Grundarten.
        _G.Enum.DamageMeterType = nil
        local keys = {}
        for _, m in ipairs(DM.Modes()) do keys[#keys + 1] = m.key end
        assert(table.concat(keys, ",") == "DamageDone,HealingDone,DamageTaken,Interrupts,Dispels,Deaths",
            "ohne Enum: " .. table.concat(keys, ","))
        _G.Enum.DamageMeterType = { DamageDone = 0, Dps = 1, HealingDone = 2, DamageTaken = 7, Deaths = 9 }
        _G.Enum.DamageMeterSessionType = { Current = 0, Overall = 1 }
        keys = {}
        for _, m in ipairs(DM.Modes()) do keys[#keys + 1] = m.key end
        assert(table.concat(keys, ",") == "DamageDone,Dps,HealingDone,DamageTaken,Deaths",
            "Messarten nach Enum: " .. table.concat(keys, ","))

        -- 2. Pro Sekunde: Balken und erste Zahl nach pro Sekunde.
        local srcs = {
            { name = "Schnell", classFilename = "ROGUE", totalAmount = 1000, amountPerSecond = 50 },
            { name = "Lang",    classFilename = "MAGE",  totalAmount = 2000, amountPerSecond = 40 },
        }
        _G.C_DamageMeter = { GetCombatSessionFromType = function() return { combatSources = srcs } end }
        K.Set("damagemeter", "w1mode", "Dps")
        DM.Refresh()
        local _, mx = w.rows[1].bar:GetMinMaxValues()
        assert(mx == 50 and w.rows[2].bar:GetValue() == 40, "DPS-Balken nach Summe statt pro Sekunde: " .. tostring(mx))
        assert(DM.AmountText(1, 1) == "50 (1,0K)  33%", "DPS-Zahl: " .. tostring(DM.AmountText(1, 1)))
        K.Set("damagemeter", "w1mode", "DamageDone")
        DM.Refresh()
        _, mx = w.rows[1].bar:GetMinMaxValues()
        assert(mx == 1000, "Schaden misst nicht mehr die Summe")

        -- Aufschluesselung: alle Reiter passen hinein (Beta-Test: "Bannungen"
        -- lief rechts aus dem Fenster), und mit wenigen wird sie wieder schmal.
        local allTypes = { DamageDone = 0, Dps = 1, HealingDone = 2, Hps = 3, Absorbs = 4, Interrupts = 5,
            Dispels = 6, DamageTaken = 7, AvoidableDamageTaken = 8, Deaths = 9, EnemyDamageTaken = 10 }
        local function TabsFit()
            local bdx = DM.Breakdown()
            local sum, n = 0, 0
            for _, t in ipairs(bdx.tabs) do
                if t:IsShown() then sum, n = sum + t:GetWidth(), n + 1 end
            end
            return sum + 4 * (n - 1) <= bdx.frame:GetWidth() - 24 and bdx.frame:GetWidth() == DM.BreakdownWidth(), n
        end
        _G.Enum.DamageMeterType = allTypes
        DM.OpenBreakdown(w, srcs[1])
        local fits, n = TabsFit()
        assert(DM.Breakdown().frame:IsShown() and n == 8 and fits,
            "Reiter laufen aus dem Fenster: " .. n .. " Reiter, " .. DM.Breakdown().frame:GetWidth() .. " px")
        assert(DM.Breakdown().stats[4]:GetWidth() == (DM.BreakdownWidth() - 24) / 4, "Kennzahlen nicht mitgewachsen")
        DM.Breakdown().frame:Hide()
        _G.Enum.DamageMeterType = { DamageDone = 0, HealingDone = 2 }
        DM.OpenBreakdown(w, srcs[1])
        assert(DM.Breakdown().frame:GetWidth() == 360 and TabsFit(), "mit zwei Reitern nicht wieder schmal")
        DM.Breakdown().frame:Hide()
        _G.Enum.DamageMeterType = { DamageDone = 0, Dps = 1, HealingDone = 2, DamageTaken = 7, Deaths = 9 }

        -- 3. Melden: offene Zahlen nach dem Kampf, sonst nichts.
        local sent = {}
        _G.SendChatMessage = function(msg, chan) sent[#sent + 1] = chan .. "|" .. msg end
        _G.InCombatLockdown = function() return false end
        assert(DM.Report(w, "PARTY"), "Melden schlaegt fehl")
        assert(#sent == 3 and sent[1]:find("^PARTY|WeintCodex – Schaden, Aktuell") and sent[2] == "PARTY|1. Schnell  1,0K (50), 33%",
            "Meldung: " .. table.concat(sent, " / "))
        sent = {}
        _G.InCombatLockdown = function() return true end
        assert(not DM.Report(w, "PARTY") and #sent == 0, "im Kampf gemeldet")
        assert(printed[#printed]:find("nach dem Kampf", 1, true), "kein Hinweis im Kampf")
        _G.InCombatLockdown = function() return false end
        _G.issecretvalue = function(v) return v == 1000 end
        assert(not DM.Report(w, "PARTY") and #sent == 0, "geheime Zahl gemeldet")
        _G.issecretvalue = saved[11]
        DM.ShowTest(true)
        assert(not DM.Report(w, "PARTY") and #sent == 0, "Beispielzahlen gemeldet")
        DM.ShowTest(false)
        _G.IsInGroup = function() return true end
        _G.IsInRaid = function() return false end
        _G.IsInGuild = function() return true end
        _G.UnitIsPlayer = function(u) return u == "target" end
        _G.UnitIsUnit = function(a, b) return a == b end
        _G.UnitName = function(u) return ({ target = "Freund" })[u] or "Testchar" end
        local ch = {}
        for _, c in ipairs(DM.ReportChannels()) do ch[#ch + 1] = c.value end
        assert(table.concat(ch, ",") == "PARTY,GUILD,SAY,WHISPER", "Kanaele: " .. table.concat(ch, ","))
        -- 6.10.4.6, gemessen: an die Gilde selbst schreiben -> ADDON_ACTION_BLOCKED
        -- (pcall faengt es nicht). Gilde/Sagen/Fluestern: eine Zeile in die
        -- Eingabezeile, nichts gesendet; die Gruppe weiter direkt.
        local box = {}
        local oldOpen = _G.ChatFrame_OpenChat
        _G.ChatFrame_OpenChat = function(text) box[#box + 1] = text end
        sent = {}
        assert(DM.Report(w, "GUILD") and #sent == 0 and #box == 1, "Gilde selbst geschrieben: " .. table.concat(sent, " / "))
        assert(box[1]:find("^/g WeintCodex – Schaden, Aktuell") and box[1]:find(": 1. Schnell  1,0K (50), 33% · 2. ", 1, true),
            "Zeile fuer die Gilde: " .. tostring(box[1]))
        assert(printed[#printed]:find("Enter sendet", 1, true), "kein Hinweis auf Enter")
        assert(DM.Report(w, "WHISPER", "Freund") and box[2]:find("^/w Freund WeintCodex") and #sent == 0, "Fluestern: " .. tostring(box[2]))
        assert(DM.Report(w, "SAY") and box[3]:find("^/s ") and #sent == 0, "Sagen: " .. tostring(box[3]))
        assert(DM.Report(w, "PARTY") and #sent == 3 and #box == 3, "Gruppe nicht mehr direkt")
        -- Eine Zeile, hoechstens 255 Bytes, nur ganze Plaetze.
        local long = { "Kopf:" }
        for i = 1, 30 do long[#long + 1] = string.format("%d. Spieler%02d  12,3K (456), 10%%", i, i) end
        local one = DM.OneLine(long, 255 - 3)
        assert(#one <= 252 and one:sub(-3) == "10%" and one:find("^Kopf: 1%. Spieler01"), "zu lang oder abgeschnitten: " .. #one .. " " .. one)
        _G.ChatFrame_OpenChat = nil
        assert(not DM.Report(w, "GUILD") and printed[#printed]:find("ließ sich nicht öffnen", 1, true), "ohne Eingabezeile still")
        _G.ChatFrame_OpenChat = function() error("gesperrt") end
        assert(not DM.Report(w, "GUILD") and printed[#printed]:find("ließ sich nicht öffnen", 1, true), "Fehler der Eingabezeile verschluckt")
        _G.ChatFrame_OpenChat = oldOpen
        assert(w.report:IsShown(), "Sprechblase fehlt in der Kopfzeile")

        -- 4. Bedrohung: Gruppe auf dem Ziel, Tank zuerst, eigene Zeile.
        local threat = {
            player = { false, 0, 84, 92 },
            party1 = { true, 3, 100, 100 },
            party2 = { false, 0, 61, 70 },
            party3 = { false, 0, 0, 0 },     -- auf der Liste, aber 0: weg
        }
        local unitName = { player = "Testchar", party1 = "Tanky", party2 = "Magier", party3 = "Leer", target = "Kobold" }
        local exists = { player = true, target = true, party1 = true, party2 = true, party3 = true, party4 = true }
        _G.UnitExists = function(u) return exists[u] or false end
        _G.UnitCanAttack = function(_, u) return u == "target" end
        _G.UnitIsPlayer = function() return false end
        _G.UnitName = function(u) return unitName[u] end
        _G.UnitClass = function(u) return "x", u == "party1" and "WARRIOR" or "MAGE" end
        _G.UnitDetailedThreatSituation = function(u)
            local t = threat[u]
            if not t then return nil end
            return t[1], t[2], t[3], t[4]
        end
        K.Set("damagemeter", "w1mode", "Threat")
        assert(DM.Window(1):Mode().threat and DM.ShowsThreat(), "Bedrohung nicht gewaehlt")
        DM.Refresh()
        assert(DM.RowsShown() == 3, "drei auf der Liste erwartet, " .. DM.RowsShown())
        assert(w.rows[1].name:GetText() == "1. Tanky" and w.rows[1].amount:GetText() == "Aggro", "Tank nicht zuerst: " .. tostring(w.rows[1].name:GetText()))
        assert(w.rows[2].name:GetText() == "2. Testchar" and DM.AmountText(1, 2) == "84%" and w.rows[2].own:IsShown(),
            "eigene Zeile: " .. tostring(w.rows[2].name:GetText()) .. " " .. tostring(DM.AmountText(1, 2)))
        _, mx = w.rows[2].bar:GetMinMaxValues()
        assert(mx == 100 and w.rows[2].bar:GetValue() == 84, "Bedrohungsbalken nicht bis 100")
        assert(w.title:GetText():find("Kobold", 1, true) and not w.session:IsShown(), "Titel/Zeitraum: " .. tostring(w.title:GetText()))
        -- Gleichstand bei 100 % (und mehr roher Bedrohung): der Tank bleibt oben.
        threat.party4 = { false, 1, 100, 110 }
        unitName.party4 = "Vier"
        DM.Refresh()
        assert(w.rows[1].name:GetText() == "1. Tanky" and w.rows[2].name:GetText() == "2. Vier",
            "Tank nicht vor Gleichstand: " .. tostring(w.rows[1].name:GetText()))
        threat.party4 = nil
        DM.Refresh()
        w.rows[2]._scripts.OnMouseUp(w.rows[2], "LeftButton")
        assert(not (DM.Breakdown() and DM.Breakdown().frame:IsShown()), "Bedrohungszeile oeffnet eine Aufschluesselung")
        sent = {}
        assert(DM.Report(w, "PARTY") and sent[1] == "PARTY|WeintCodex – Bedrohung auf Kobold:" and sent[2] == "PARTY|1. Tanky  Aggro"
            and sent[3] == "PARTY|2. Testchar  84%", "Bedrohung melden: " .. table.concat(sent, " / "))
        -- Geheim: keine Sortierung, keine Platznummern, Zahl trotzdem da.
        _G.issecretvalue = function(v) return v == 61 end
        DM.Refresh()
        assert(w.rows[1].name:GetText() == "Testchar" and DM.AmountText(1, 1) == "84%",
            "geheim und trotzdem sortiert: " .. tostring(w.rows[1].name:GetText()))
        assert(w.rows[3].bar:GetValue() == 61, "geheimer Wert nicht an den Balken")
        sent = {}
        assert(not DM.Report(w, "PARTY") and #sent == 0, "geheime Bedrohung gemeldet")
        _G.issecretvalue = saved[11]
        -- Freundliches Ziel: dessen Ziel. Kein Ziel: ein Satz.
        exists.targettarget = true
        unitName.targettarget = "Ork"
        _G.UnitCanAttack = function(_, u) return u == "targettarget" end
        DM.Refresh()
        assert(w.title:GetText():find("Ork", 1, true), "freundliches Ziel: nicht dessen Ziel")
        exists.target = false
        DM.Refresh()
        assert(DM.RowsShown() == 0 and DM.EmptyText():find("Kein Ziel", 1, true), "ohne Ziel: " .. tostring(DM.EmptyText()))
        exists.target = true
        _G.UnitDetailedThreatSituation = nil
        DM.Refresh()
        assert(DM.EmptyText():find("keine Bedrohung", 1, true), "ohne Client-Funktion: " .. tostring(DM.EmptyText()))
        K.Set("damagemeter", "w1mode", nil)

        -- 5. Plakette: Leiste unter dem Leben, "Aggro: …" nach Rolle.
        _G.UnitCanAttack = function(_, u) return u == "nameplate1" end
        exists.nameplate1, exists.nameplate1target = true, true
        stub.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate1")
        local p = NP.plates["nameplate1"]
        assert(p and not p._friendly, "Plakette fehlt")
        local mine = { false, 1, 95 }
        _G.UnitDetailedThreatSituation = function() return mine[1], mine[2], mine[3] end
        local roles = { player = "DAMAGER", nameplate1target = "DAMAGER" }
        _G.UnitGroupRolesAssigned = function(u) return roles[u] or "NONE" end
        _G.UnitPlayerControlled = function(u) return u == "nameplate1target" end
        _G.UnitIsUnit = function(a, b) return a == b end
        unitName.nameplate1target = "Tamsin"
        NP.UpdateThreatText(p)
        assert(p.threatBar:IsShown() and p.threatBar:GetValue() == 95, "Bedrohungsleiste fehlt")
        assert(type(p.threatBar.edge) == "table" and p.threatBar.edge.top, "Bedrohungsleiste ohne Rand")
        assert(p.aggro:IsShown() and p.aggro:GetText():find("Tamsin", 1, true), "Aggro-Name fehlt: " .. tostring(p.aggro:GetText()))
        -- Der Gegner schlaegt eine Wache (kein Spieler): niemand aus der Gruppe.
        _G.UnitPlayerControlled = function() return false end
        NP.UpdateThreatText(p)
        assert(not p.aggro:IsShown(), "Wache als Aggro-Halter gemeldet")
        _G.UnitPlayerControlled = function(u) return u == "nameplate1target" end
        roles.nameplate1target = "TANK"
        NP.UpdateThreatText(p)
        assert(not p.aggro:IsShown(), "beim Tank trotzdem gemeldet")
        K.Set("nameplates", "aggroName", "always")
        NP.UpdateThreatText(p)
        assert(p.aggro:IsShown(), "'immer' zeigt den Tank nicht")
        K.Set("nameplates", "aggroName", nil)
        mine[1] = true
        NP.UpdateThreatText(p)
        assert(p.aggro:IsShown() and p.aggro:GetText():find("Du", 1, true), "eigene Aggro als DD nicht gemeldet")
        -- 6.10.3.2, Tank: die Leiste zeigt den Naechsten, nicht sich selbst.
        local GC = WeintCodex.GameColors
        local painted
        local paint = K.PaintBar
        K.PaintBar = function(b, r, g, bl) if b == p.threatBar then painted = { r, g, bl } end return paint(b, r, g, bl) end
        local others = { party1 = 40, party2 = 85 }
        exists.party1, exists.party2 = true, true
        _G.UnitDetailedThreatSituation = function(u)
            if u == "player" then return mine[1], mine[2], mine[3] end
            local v = others[u]
            if v == nil then return nil end
            return false, 0, v
        end
        roles.player = "TANK"
        mine[1], mine[2], mine[3] = true, 3, 100
        others.party1, others.party2 = 60, 40     -- der Hoechste steht nicht zuletzt
        NP.UpdateThreatText(p)
        assert(p.threatBar:IsShown() and p.threatBar:GetValue() == 60 and p._threatLead == 60,
            "Tank: Leiste zeigt nicht den Naechsten: " .. tostring(p.threatBar:GetValue()))
        -- Im Schlachtzug steht der Spieler selbst in der Liste (raid1): er
        -- zaehlt nicht als der Naechste.
        local oldRaid, oldIsUnit = _G.IsInRaid, _G.UnitIsUnit
        _G.IsInRaid = function() return true end
        _G.UnitIsUnit = function(a, b) return a == b or (a == "raid1" and b == "player") end
        exists.raid1, exists.raid2 = true, true
        others.raid1, others.raid2 = 100, 55
        NP.UpdateThreatText(p)
        assert(p._threatLead == 55, "Schlachtzug: der Tank zaehlt sich selbst: " .. tostring(p._threatLead))
        _G.IsInRaid, _G.UnitIsUnit = oldRaid, oldIsUnit
        exists.raid1, exists.raid2, others.raid1, others.raid2 = nil, nil, nil, nil
        others.party1, others.party2 = 40, 60
        local ta = K.Get("nameplates", "tankAggro")
        assert(painted and painted[1] == ta.r and painted[2] == ta.g, "Tank mit Abstand nicht gruen")
        others.party2 = 85
        NP.UpdateThreatText(p)
        local tl = K.Get("nameplates", "tankLosing")
        assert(p.threatBar:GetValue() == 85 and painted[1] == tl.r and painted[2] == tl.g,
            "Tank, der Naechste kurz davor: nicht orange")
        -- Niemand sonst auf der Liste: 0, gemessen - nicht unbekannt.
        others.party1, others.party2 = nil, nil
        NP.UpdateThreatText(p)
        assert(p._threatLead == 0 and p.threatBar:GetValue() == 0, "Tank allein auf der Liste: " .. tostring(p._threatLead))
        -- Geheim: zurueck zur eigenen Bedrohung.
        others.party1 = 61
        local oldSecret = _G.issecretvalue
        _G.issecretvalue = function(v) return v == 61 end
        NP.UpdateThreatText(p)
        _G.issecretvalue = oldSecret
        assert(p._threatLead == nil and p.threatBar:GetValue() == 100, "geheime Bedrohung als Abstand gelesen")
        -- Kein Tank: die eigene Bedrohung, auch wenn du sie haeltst (rot).
        roles.player = "DAMAGER"
        others.party1 = 40
        NP.UpdateThreatText(p)
        assert(p._threatLead == nil and p.threatBar:GetValue() == 100, "DD mit Aggro: nicht die eigene Bedrohung")
        -- 6.10.3.3: eine Farbe der Lage fuer Leiste UND Lebensbalken.
        assert(K.Get("nameplates", "threatColors") == true, "Bedrohungsfarben ab Werk aus")
        local healthPaint
        K.PaintBar = function(b, r, g, bl)
            if b == p.threatBar then painted = { r, g, bl } end
            if b == p.health then healthPaint = { r, g, bl } end
            return paint(b, r, g, bl)
        end
        local da, dn = K.Get("nameplates", "dpsAggro"), K.Get("nameplates", "dpsNear")
        local oldUAC = _G.UnitAffectingCombat
        _G.UnitAffectingCombat = function() return true end
        local function Run() NP.UpdateThreatText(p) NP.RecolorAll() end
        -- DD mit Aggro: Leiste und Leben rot.
        Run()
        assert(p._threatTint == da and painted[1] == da.r and healthPaint[1] == da.r and healthPaint[2] == da.g,
            "DD mit Aggro: Leben nicht rot")
        -- DD nah dran (Status 0, 85 %): orange - nicht erst bei Status 1.
        mine[1], mine[2], mine[3] = false, 0, 85
        Run()
        assert(p._threatTint == dn and painted[1] == dn.r and healthPaint[1] == dn.r, "DD bei 85 %: nicht orange")
        -- DD weit weg: keine Lage, Leiste grau, Leben in seiner Farbe.
        mine[3] = 50
        Run()
        local low = WeintCodex.GameColors.threatLow
        assert(p._threatTint == nil and painted[1] == low[1] and healthPaint[1] ~= da.r and healthPaint[1] ~= dn.r,
            "DD bei 50 %: gefaerbt")
        -- Tank hat sie verloren: rot.
        roles.player = "TANK"
        mine[1], mine[2], mine[3] = false, 1, 95
        Run()
        assert(p._threatTint == da and healthPaint[1] == da.r, "Tank ohne Aggro: nicht rot")
        -- Abgeschaltet: Leben in seiner Farbe, Leiste weiter gefaerbt.
        K.Set("nameplates", "threatColors", false)
        Run()
        assert(healthPaint[1] ~= da.r and painted[1] == da.r, "abgeschaltete Bedrohungsfarben faerben das Leben")
        K.Set("nameplates", "threatColors", nil)
        roles.player = "DAMAGER"
        -- Ueber das Ereignis und beim Erscheinen: erst die Lage, dann die
        -- Farbe - sonst traegt das Leben die Lage vom letzten Mal.
        K.PaintBar = function(b, r, g, bl)
            local cur = NP.plates["nameplate1"]
            if cur and b == cur.health then healthPaint = { r, g, bl } end
            return paint(b, r, g, bl)
        end
        mine[1], mine[2], mine[3] = false, 0, 50
        stub.FireEvent("UNIT_THREAT_LIST_UPDATE", "nameplate1")
        assert(healthPaint[1] ~= da.r, "Vorbedingung: Leben schon rot")
        mine[1], mine[2], mine[3] = true, 3, 100
        stub.FireEvent("UNIT_THREAT_LIST_UPDATE", "nameplate1")
        assert(healthPaint[1] == da.r, "Ereignis: Leben folgt der Lage erst beim naechsten Mal")
        mine[1], mine[2], mine[3] = false, 0, 50
        stub.FireEvent("UNIT_THREAT_SITUATION_UPDATE", "nameplate1")
        assert(healthPaint[1] ~= da.r, "Lage-Ereignis: Leben bleibt rot")
        mine[1], mine[2], mine[3] = true, 3, 100
        stub.FireEvent("UNIT_THREAT_SITUATION_UPDATE", "nameplate1")
        assert(healthPaint[1] == da.r, "Lage-Ereignis: Leben folgt erst beim naechsten Mal")
        mine[1], mine[2], mine[3] = false, 0, 50
        stub.FireEvent("UNIT_THREAT_LIST_UPDATE", "nameplate1")
        stub.FireEvent("NAME_PLATE_UNIT_REMOVED", "nameplate1")
        mine[1], mine[2], mine[3] = true, 3, 100
        stub.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate1")
        p = NP.plates["nameplate1"]
        assert(healthPaint[1] == da.r, "neue Plakette: Leben folgt der Lage nicht")
        -- Allein ohne Begleiter: keine Farbe (sonst waere jeder Gegner rot).
        local oldGroup = _G.IsInGroup
        _G.IsInGroup = function() return false end
        exists.pet = nil
        Run()
        assert(p._threatTint == nil and healthPaint[1] ~= da.r, "allein ohne Begleiter: Leben rot")
        -- 6.10.3.4: was fest war, ist einstellbar.
        K.PaintBar = function(b, r, g, bl)
            local cur = NP.plates["nameplate1"]
            if cur and b == cur.threatBar then painted = { r, g, bl } end
            if cur and b == cur.health then healthPaint = { r, g, bl } end
            return paint(b, r, g, bl)
        end
        -- "Auch allein zeigen": dann Leiste und Farbe auch ohne Begleiter.
        K.Set("nameplates", "threatSolo", true)
        Run()
        assert(p.threatBar:IsShown() and p._threatTint == da, "auch allein: keine Leiste/Farbe")
        K.Set("nameplates", "threatSolo", nil)
        _G.IsInGroup = function() return true end
        -- "Warnen ab": 90 % - ein DD bei 85 % ist noch nicht orange, bei 95 % schon.
        K.Set("nameplates", "threatWarn", 90)
        mine[1], mine[2], mine[3] = false, 0, 85
        Run()
        assert(p._threatTint == nil, "Warnen ab 90: bei 85 % schon gefaerbt")
        mine[3] = 95
        Run()
        assert(p._threatTint == dn, "Warnen ab 90: bei 95 % nicht orange")
        -- Eigene Farbe fuer "weit weg".
        K.Set("nameplates", "threatLow", { r = 0.1, g = 0.2, b = 0.3 })
        mine[3] = 40
        Run()
        assert(painted[1] == 0.1 and painted[2] == 0.2 and painted[3] == 0.3, "eigene Farbe 'weit weg' nicht an der Leiste")
        K.Set("nameplates", "threatLow", nil)
        -- Tank: der Naechste bei 85 % unter "Warnen ab 90" bleibt gruen;
        -- "den Naechsten zeigen" aus: die eigene Bedrohung.
        roles.player = "TANK"
        mine[1], mine[2], mine[3] = true, 3, 100
        others.party1 = 85
        exists.party1 = true
        Run()
        local ta2 = K.Get("nameplates", "tankAggro")
        assert(p._threatLead == 85 and p._threatTint == ta2, "Tank, Warnen ab 90, Naechster 85: nicht gruen")
        K.Set("nameplates", "tankLead", false)
        Run()
        assert(p._threatLead == nil and p.threatBar:GetValue() == 100 and p._threatTint == ta2,
            "Tank ohne 'den Naechsten zeigen': nicht die eigene Bedrohung")
        K.Set("nameplates", "tankLead", nil)
        K.Set("nameplates", "threatWarn", nil)
        others.party1 = nil
        roles.player = "DAMAGER"
        -- Vorschau: folgt "Warnen ab" (Beispiel 84 %).
        NP.CreatePreview(UIParent)
        local pv = NP.PreviewPlate()
        local pvPaint
        local prev = K.PaintBar
        K.PaintBar = function(b, r, g, bl) if b == pv.threatBar then pvPaint = { r, g, bl } end return prev(b, r, g, bl) end
        NP.RefreshPreview()
        assert(pvPaint and pvPaint[1] == dn.r, "Vorschau bei Warnen ab 80: nicht orange")
        K.Set("nameplates", "threatWarn", 90)
        NP.RefreshPreview()
        local lw = K.Get("nameplates", "threatLow")
        assert(pvPaint[1] == lw.r and pvPaint[2] == lw.g, "Vorschau folgt 'Warnen ab' nicht")
        K.Set("nameplates", "threatWarn", nil)
        K.PaintBar = prev
        -- Die Einstellungen stehen sichtbar, nicht unter "Erweitert".
        local O = WeintCodex.UIOptions
        local seen = {}
        for _, e in ipairs(O.SearchIndex()) do
            if e.module == "nameplates" and not e.advanced then seen[e.label] = true end
        end
        for _, l in ipairs({ "Warnen ab", "Auch allein zeigen", "Als Tank: den Nächsten zeigen", "Weit weg (nur Leiste)",
                             "Aggro gezogen", "Kurz davor", "Tank: hält die Aggro", "Tank: der Nächste ist nah", "Höhe der Leiste" }) do
            assert(seen[l], "nicht sichtbar auf der Seite: " .. l)
        end
        _G.IsInGroup = oldGroup
        _G.UnitAffectingCombat = oldUAC
        K.PaintBar = paint
        others.party1 = nil
        _G.IsInGroup = function() return false end
        -- Allein ohne Begleiter: immer 100 % - keine Leiste (das war Rauschen).
        exists.pet = nil
        NP.UpdateThreatText(p)
        assert(not p.aggro:IsShown() and not p.threatBar:IsShown(), "allein ohne Begleiter: Leiste oder Name")
        -- Mit Begleiter kann dir jemand die Aggro nehmen: Leiste ja.
        exists.pet = true
        NP.UpdateThreatText(p)
        assert(p.threatBar:IsShown(), "allein mit Begleiter: keine Leiste")
        mine[3] = nil
        NP.UpdateThreatText(p)
        assert(not p.threatBar:IsShown() and not p.threat:IsShown(), "nicht auf der Liste und trotzdem Leiste")
        K.Set("nameplates", "threatBar", false)
        mine[3] = 50
        NP.UpdateThreatText(p)
        assert(not p.threatBar:IsShown(), "abgeschaltete Leiste erscheint")
        K.Set("nameplates", "threatBar", nil)
        stub.FireEvent("NAME_PLATE_UNIT_REMOVED", "nameplate1")
    end)
    for i, n in ipairs(names) do _G[n] = saved[i] end
    _G.Enum.DamageMeterType, _G.Enum.DamageMeterSessionType = savedEnum, savedSess
    K.Set("damagemeter", "w1mode", nil)
    DM.ShowTest(false)
    DM.Refresh()
    Check(ok, "Schadensanzeige wie Details: pro Sekunde, Bedrohung (sortiert, geheim, Ziel), Melden (offen, Kampf, geheim, Beispiel, Kanaele); Plaketten: Bedrohungsleiste, Aggro nach Rolle"
        .. (ok and "" or (": " .. tostring(err))))
end

-- 6.9.1.0: Mikromenue und Taschenleiste frei verschiebbar (Beta-Test: "das
-- Mikromenue laesst sich nicht frei verschieben" - WeintCodex setzte es nach
-- jedem Anordnen fest nach unten links, im Gestaltungsmodus fehlte es).
do
    local AB = WeintCodex.UIActionBars
    local E  = WeintCodex.UIEditMode
    local saved = { _G.MicroMenuContainer, _G.BagsBar, _G.InCombatLockdown }
    local ok, err = pcall(function()
        local function Track(f)
            f.SetPoint = function(self, ...) self._pt = { ... } end
            f.GetPoint = function(self) local p = self._pt or {} return p[1], p[2], p[3], p[4], p[5] end
            return f
        end
        local micro = Track(CreateFrame("Frame", "MicroMenuContainer", UIParent))
        local bags = Track(CreateFrame("Frame", "BagsBar", UIParent))
        micro.SetScale = function(self, v) self._scale = v end
        local pos = K.Profile().positions
        pos.hud_micro, pos.hud_bags = nil, nil
        _G.InCombatLockdown = function() return false end
        -- Schon einmal angemeldet (frueherer Lauf): die Flaeche muss auf den
        -- neuen Rahmen.
        local old = K.movers.hud_micro and K.movers.hud_micro.overlay
        if old then old.SetAllPoints = function(self, f) self._anchor = f end end
        AB.Place()
        if old then assert(old._anchor == micro, "Flaeche im Gestaltungsmodus liegt auf dem alten Rahmen") end
        local m = K.movers.hud_micro
        assert(m and m.frame == micro and K.movers.hud_bags and K.movers.hud_bags.frame == bags,
            "Mikromenue/Taschenleiste nicht im Gestaltungsmodus")
        assert(micro._pt[1] == "BOTTOMLEFT" and micro._pt[4] == 4 and micro._pt[5] == 4, "Standardplatz nicht aus ui/layout.lua")
        assert(E.ModuleFor("hud_micro") == "actionbars" and E.ModuleFor("hud_bags") == "actionbars",
            "Doppelklick fuehrt nicht zu den Aktionsleisten")
        -- Ziehen: der neue Platz bleibt, auch wenn das Spiel neu anordnet.
        m.overlay._scripts.OnDragStart(m.overlay)
        micro:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 300, 200)
        m.overlay._scripts.OnDragStop(m.overlay)
        local want = pos.hud_micro
        assert(want and want.point == "BOTTOMLEFT", "gezogener Platz nicht gespeichert")
        micro:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 4, 4)   -- das Spiel ordnet an
        AB.Place()
        assert(micro._pt[4] == want.x and micro._pt[5] == want.y and want.x ~= 4,
            "Mikromenue springt zurueck: " .. tostring(micro._pt[4]) .. "/" .. tostring(micro._pt[5]))
        -- Im Kampf wird nichts gesetzt.
        _G.InCombatLockdown = function() return true end
        micro:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 4, 4)
        micro._scale = nil
        AB.Place()
        assert(micro._pt[4] == 4 and micro._scale == nil, "im Kampf versetzt oder skaliert")
        _G.InCombatLockdown = function() return false end
        -- Rechtsklick: zurueck an den Standardplatz.
        m.overlay._scripts.OnClick(m.overlay, "RightButton")
        assert(not pos.hud_micro and micro._pt[4] == 4 and micro._pt[5] == 4, "Rechtsklick setzt nicht zurueck")
        -- "Wie im Spiel": WeintCodex laesst den Platz in Ruhe.
        K.Set("actionbars", "microMenu", "game")
        micro:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 77, 88)
        AB.Place()
        assert(micro._pt[4] == 77, "'Wie im Spiel' wird trotzdem versetzt")
        K.Set("actionbars", "microMenu", nil)
        pos.hud_micro, pos.hud_bags = nil, nil
    end)
    _G.MicroMenuContainer, _G.BagsBar, _G.InCombatLockdown = saved[1], saved[2], saved[3]
    if K.movers.hud_micro then K.SetMoverEnabled("hud_micro", false) end
    if K.movers.hud_bags then K.SetMoverEnabled("hud_bags", false) end
    Check(ok, "Mikromenue und Taschenleiste: im Gestaltungsmodus, Platz bleibt nach dem Anordnen des Spiels, Kampf, Rechtsklick, 'Wie im Spiel'"
        .. (ok and "" or (": " .. tostring(err))))
end

-- 6.9.1.3: Nachrichten an die Companion schreiben nichts in den Chat
-- (Beta-Test: "character_sheet aktualisiert" bei jeder Fertigkeitsstufe).
do
    local CO = WeintCodex.Companion
    local savedPrint, savedDB = _G.print, _G.WeintCompanionDB
    local printed = {}
    local ok, err = pcall(function()
        _G.WeintCompanionDB = { queue = {} }
        _G.print = function(...) printed[#printed + 1] = table.concat({ ... }, " ") end
        local id1 = CO.Send("character_sheet", "a")
        local id2 = CO.Send("character_sheet", "b")     -- ersetzt
        local id3 = CO.Send("calendar", "c")            -- neu
        assert(id1 and id2 == id1 and id3 and id3 ~= id1, "Warteschlange arbeitet nicht mehr")
        assert(#WeintCompanionDB.queue == 2 and WeintCompanionDB.queue[1].payload == "b", "Zustandsnachricht nicht ersetzt")
        assert(#printed == 0, "Chat: " .. tostring(printed[1]))
    end)
    _G.print, _G.WeintCompanionDB = savedPrint, savedDB
    Check(ok, "Companion: Nachrichten still in die Warteschlange (neu und ersetzt), kein Satz im Chat"
        .. (ok and "" or (": " .. tostring(err))))
end

-- 6.10.0.0: Fenster in Gold aus Bausteinen - Handel, Bank, Post sind nur
-- noch Beschreibung (ui/calmparts.lua).
do
    local CP = WeintCodex.UICalmParts
    local ok, err = pcall(function()
        for _, host in ipairs({ "TradeFrame", "BankFrame", "MailFrame", "FriendsFrame", "SocialUIFrame" }) do
            assert(CP.hosts[host], "kein Baustein-Fenster: " .. host)
        end
        assert(CP.hosts.TradeFrame == WeintCodex.UITrade and CP.hosts.BankFrame == WeintCodex.UIBank
            and CP.hosts.MailFrame == WeintCodex.UIMail and CP.hosts.FriendsFrame == WeintCodex.UIFriends, "Module zeigen nicht auf ihr Baustein-Fenster")
        local bad = pcall(CP.New, { label = "X", host = "XFrame", files = { [1] = "stein" } })
        assert(not bad, "unbekannte Art wird angenommen")
        bad = pcall(CP.New, { label = "X", host = "XFrame", atlases = { { "^x", "holz" } } })
        assert(not bad, "unbekannte Art (Atlas) wird angenommen")
        assert(not CP.hosts.XFrame, "abgelehntes Fenster trotzdem angemeldet")
    end)
    Check(ok, "Fenster in Gold aus Bausteinen: Handel, Bank, Post angemeldet, unbekannte Arten abgelehnt"
        .. (ok and "" or (": " .. tostring(err))))
end

-- 6.10.0.0: Suche in den Einstellungen - findet auch Zugeklapptes und
-- klappt es beim Oeffnen auf.
do
    local ok, err = pcall(function()
        local idx = UO.SearchIndex()
        assert(#idx > 250, "Suche kennt zu wenige Einstellungen: " .. #idx)
        -- 6.10.1.0: zugeklappt zeigt keine Seite mehr als 15 Einstellungen
        -- (vorher bis 19: Zielrahmen). Wer eine Seite fuellt, sortiert
        -- Feinheiten hinter B:Advanced() - oder begruendet hier eine Ausnahme.
        local shown = {}
        for _, e in ipairs(idx) do
            if not e.advanced then
                local k = e.module .. "/" .. e.page
                shown[k] = (shown[k] or 0) + 1
            end
        end
        for k, n in pairs(shown) do
            assert(n <= 15, k .. ": zugeklappt " .. n .. " Einstellungen - Feinheiten unter 'Erweitert'")
        end
        -- Wo Feinheiten waren, gibt es jetzt einen Bereich.
        for _, key in ipairs({ "nameplates", "unitframes", "groupframes", "actionbars", "damagemeter",
                               "questarrow", "minimap", "chat" }) do
            local any = false
            for _, e in ipairs(idx) do if e.module == key and e.advanced then any = true break end end
            assert(any, key .. ": keine Einstellung unter 'Erweitert'")
        end
        local function Find(label, module)
            for _, e in ipairs(idx) do
                if e.label == label and (not module or e.module == module) then return e end
            end
        end
        local sheen = Find("Ziel: Glanz läuft über den Balken")
        assert(sheen and sheen.module == "nameplates" and sheen.page == 1 and sheen.advanced
            and sheen.section == "Bewegung einzeln", "Eintrag unter 'Erweitert' fehlt oder falsch einsortiert")
        local bar = Find("Bedrohungsleiste", "nameplates")
        assert(bar and not bar.advanced and bar.pageLabel == "Bedrohung & Farben", "Bedrohungsleiste falsch einsortiert")
        -- Gross/klein und Umlaute egal; ein Zeichen sucht nicht.
        local hits = UO.Search("glanz")
        local found = false
        for _, e in ipairs(hits) do if e == sheen then found = true end end
        assert(found, "'glanz' findet den Glanz nicht")
        -- Nur ueber die Faltung zu finden: im Text steht "über der Plakette".
        local u = UO.Search("ÜBER DER PLAKETTE")
        assert(#u > 0, "Umlaut in Grossbuchstaben findet nichts")
        -- Zeichen, die in Lua-Mustern etwas bedeuten, sind hier nur Text.
        local okPct, pct = pcall(UO.Search, "in %")
        assert(okPct and #pct > 0, "'in %' findet 'Bedrohung in %' nicht: " .. tostring(pct))
        assert(#UO.Search("g") == 0, "ein Zeichen sucht schon")
        assert(#UO.Search("zzqxy") == 0, "Unsinn findet etwas")
        -- Im Fenster: Feld, Treffer, Klick oeffnet die Seite und klappt auf.
        UO.Show("general", 1)
        K.Set("general", "showAdvanced", false)
        UO.searchBox:SetText("glanz")
        UO.searchBox._scripts.OnTextChanged(UO.searchBox)
        assert(UO.results and UO.results:IsShown(), "Treffer erscheinen nicht")
        local row
        for _, r in ipairs(UO.SearchRows()) do if r:IsShown() and r._hit == sheen then row = r end end
        assert(row, "Treffer nicht in der Liste")
        row:Click()
        assert(not UO.results:IsShown() and UO.searchBox:GetText() == "", "Suche bleibt nach dem Klick stehen")
        local w = UO.Where()
        assert(w.module == "nameplates" and w.page == 1, "Klick oeffnet die falsche Seite: " .. tostring(w.module) .. "/" .. tostring(w.page))
        assert(K.Get("general", "showAdvanced") == true, "Treffer unter 'Erweitert' klappt nicht auf")
        -- Leere Suche: zurueck zur Seite; Klick links ersetzt die Treffer.
        UO.ShowSearch("bedrohung")
        assert(UO.results:IsShown(), "zweite Suche zeigt nichts")
        UO.Show("chat", 1)
        assert(not UO.results:IsShown(), "Seite links geklickt, Treffer bleiben stehen")
        UO.ShowSearch("zzqxy")
        assert(UO.results.empty:IsShown(), "kein Treffer ohne Satz")
        UO.ShowSearch("")
        assert(not UO.results:IsShown(), "leere Suche bleibt")
        UO.SetAdvanced(false)
        UO.frame:Hide()
    end)
    Check(ok, "Einstellungen: Suche (Index, Umlaute, Erweitert aufklappen, Klick oeffnet die Seite, leer und links zurueck)"
        .. (ok and "" or (": " .. tostring(err))))
end

-- 6.10.2.0: Bericht zum Kopieren, /wcui fenster je Fundort, /wcui pruefen.
do
    local ok, err = pcall(function()
        -- Kopiert kommt Text an, keine Farbcodes.
        assert(K.PlainText("|cff7C6CFFRot|r und |TInterface\\x:12|t gut") == "Rot und  gut", "Farbcodes oder Symbole bleiben im Bericht")
        -- Namenlose Rahmen einer Liste fallen in eine Zeile.
        assert(K.PatternName("A.ScrollBox.ScrollTarget.63f74260.NormalTexture") == "A.ScrollBox.ScrollTarget.*.NormalTexture",
            "Adresse namenloser Rahmen bleibt im Namen")
        assert(K.PatternName("ClassTrainerFrame.BG") == "ClassTrainerFrame.BG" and K.PatternName(nil) == "(ohne Namen)",
            "Name mit Schluessel veraendert")

        -- Fenster: nur lesen, alles markiert, ohne Farbcodes.
        local rep = K.ShowReport("|cffffffffTitel|r", { "Zeile |cffff0000eins|r", "Zeile zwei" })
        assert(rep:IsShown() and rep.title:GetText() == "Titel", "Bericht nicht offen oder Titel mit Farbcode")
        assert(rep.edit:GetText() == "Zeile eins\nZeile zwei", "Text im Feld: " .. tostring(rep.edit:GetText()))
        rep.edit:SetText("getippt")
        rep.edit._scripts.OnTextChanged(rep.edit, true)
        assert(rep.edit:GetText() == "Zeile eins\nZeile zwei", "Bericht laesst sich ueberschreiben")
        local special = false
        for _, n in ipairs(UISpecialFrames) do if n == "WeintCodexReport" then special = true end end
        assert(special, "Esc schliesst den Bericht nicht")
        rep:Hide()

        -- /wcui fenster: je Bild jeder Fundort, Zeilen zusammengefasst,
        -- unsichtbare gezaehlt, keine Grenze bei 24, Art der Bausteine.
        local function Tex(file, debug, alpha)
            local t = stub.NewObject("Texture")
            t._file, t._alpha = file, alpha
            t.GetTexture = function(self) return self._file end
            t.GetDebugName = function() return debug end
            return t
        end
        local top = stub.NewObject("Frame", "WCTestWindow")
        top.GetDebugName = function() return "WCTestWindow" end
        top.GetParent = function() return UIParent end
        local bgTex = Tex(404984, "WCTestWindow.BG")
        local gone = Tex(130718, "WCTestWindow.Gone", 0)
        local many = {}
        for i = 1, 30 do many[i] = Tex(500000 + i, "WCTestWindow.Deko" .. i) end
        bgTex._kind = "bg"
        top.GetRegions = function() return bgTex, gone, unpack(many) end
        local rows = {}
        for i, hex in ipairs({ "63f74260", "b9a2d740" }) do
            local row = stub.NewObject("Button")
            local name = "WCTestWindow.ScrollBox.ScrollTarget." .. hex
            row.GetDebugName = function() return name end
            local normal = Tex(404984, name .. ".NormalTexture")
            local icon = Tex(135812, name .. ".Icon")
            row.GetRegions = function() return normal, icon end
            rows[i] = row
        end
        top.GetChildren = function() return rows[1], rows[2] end
        local CP = WeintCodex.UICalmParts
        CP.hosts.WCTestWindow = { LABEL = "Test", Kind = function(r) return r._kind end }
        local oldFoci = _G.GetMouseFoci
        _G.GetMouseFoci = function() return { top } end
        local lines = K.InspectWindow()
        _G.GetMouseFoci = oldFoci
        CP.hosts.WCTestWindow = nil
        local text = table.concat(lines, "\n")
        assert(text:find("Bild 404984 · 3× · Baustein: bg", 1, true), "Bild nicht zusammengefasst oder Art fehlt:\n" .. text)
        assert(text:find("\n   2× WCTestWindow.ScrollBox.ScrollTarget.*.NormalTexture", 1, true)
            and text:find("\n   1× WCTestWindow.BG", 1, true), "Fundorte fehlen:\n" .. text)
        assert(text:find("unsichtbar (Deckkraft 0, auch die von WeintCodex): 1", 1, true), "Unsichtbare nicht gezaehlt")
        assert(not text:find("Bild 130718", 1, true), "Unsichtbares als sichtbar gelistet")
        local images = 0
        for _, l in ipairs(lines) do if l:find("^Bild ") then images = images + 1 end end
        assert(images == 32, "nicht alle Bilder im Bericht (Grenze?): " .. images)

        -- /wcui pruefen: jede Pruefung, Stand je Zeile, Summe stimmt.
        local SC = WeintCodex.UISelfCheck
        local saved = {}
        local function Set(name, v) if saved[name] == nil then saved[name] = { v = _G[name] } end _G[name] = v end
        local SECRET = {}
        Set("issecretvalue", function(v) return v == SECRET end)
        Set("UnitExists", function() return false end)
        Set("UnitDetailedThreatSituation", function() return nil end)
        Set("C_DamageMeter", {})
        Set("Enum", { DamageMeterType = {} })
        local out = table.concat(SC.Run(), "\n")
        assert(out:find("WeintCodex " .. WeintCodex.Version, 1, true), "Fassung fehlt im Kopf")
        for _, c in ipairs(SC.CHECKS) do assert(out:find(c.name .. ":", 1, true), "Pruefung fehlt: " .. c.name) end
        assert(out:find("[?] Bedrohung: Kein angreifbares Ziel", 1, true), "ohne Ziel keine Anleitung:\n" .. out)
        -- Mit Ziel: offen, dann geheim.
        Set("UnitExists", function() return true end)
        Set("UnitCanAttack", function() return true end)
        Set("UnitDetailedThreatSituation", function() return true, 3, 100, 100, 5000 end)
        out = table.concat(SC.Run(), "\n")
        assert(out:find("[ok] Bedrohung: Bedrohung außerhalb des Kampfes offen: isTanking=true, status=3", 1, true), "offene Bedrohung:\n" .. out)
        Set("UnitDetailedThreatSituation", function() return SECRET, SECRET, nil, nil, nil end)
        out = table.concat(SC.Run(), "\n")
        assert(out:find("[!] Bedrohung: Bedrohung außerhalb des Kampfes: 2 von 5 Werten geheim", 1, true)
            and out:find("isTanking=geheim", 1, true), "geheime Bedrohung nicht erkannt:\n" .. out)
        -- 6.10.2.1: allein ein Hinweis auf die Gruppe; in der Gruppe ein
        -- Mitspieler eigens - offen bei dir heisst nicht offen bei ihm.
        Set("UnitDetailedThreatSituation", function(u)
            if u == "player" then return true, 3, 100, 100, 5000 end
            return SECRET, 1, SECRET, nil, nil
        end)
        Set("IsInGroup", function() return false end)
        Set("IsInRaid", function() return false end)
        out = table.concat(SC.Run(), "\n")
        assert(out:find("[?] Bedrohung: Allein: ob der Client die Bedrohung anderer Spieler", 1, true), "allein kein Hinweis auf die Gruppe:\n" .. out)
        Set("IsInGroup", function() return true end)
        Set("UnitIsUnit", function(a, b) return a == b end)
        out = table.concat(SC.Run(), "\n")
        assert(out:find("[ok] Bedrohung: Bedrohung außerhalb des Kampfes offen", 1, true)
            and out:find("[!] Bedrohung: Bedrohung von party1 außerhalb des Kampfes: 2 von 5 Werten geheim", 1, true),
            "Mitspieler nicht eigens geprueft:\n" .. out)
        assert(SC.GroupMate() == "party1", "Mitspieler nicht gefunden")
        Set("UnitIsUnit", function(a) return a == "party1" end)
        assert(SC.GroupMate() == "party2", "du selbst als Mitspieler gezaehlt")
        Set("IsInGroup", function() return false end)
        -- Fenster: Alternativen, Pakete des Spiels (spaeter, geladen ohne
        -- Fenster, unbekannt).
        Set("C_AddOns", {
            GetAddOnInfo = function(name)
                if name == "Blizzard_TrainerUI" or name == "Blizzard_TalentUI" or name == "Blizzard_GuildBankUI" then
                    return name, name, "", true, nil
                end
                return name, name, "", false, "MISSING"
            end,
            IsAddOnLoaded = function(name) return name == "Blizzard_GuildBankUI" end,
        })
        for _, n in ipairs({ "ClassTrainerFrame", "GuildBankFrame", "PVEFrame", "PVPFrame", "HonorFrame",
                             "PlayerTalentFrame", "TalentFrame", "ClassTalentFrame" }) do Set(n, nil) end
        Set("LFGParentFrame", stub.NewObject("Frame"))
        out = table.concat(SC.Run(), "\n")
        assert(out:find("ClassTrainerFrame (Blizzard_TrainerUI)", 1, true)
            and out:find("PlayerTalentFrame/TalentFrame/ClassTalentFrame (Blizzard_TalentUI)", 1, true),
            "laedt beim Oeffnen nicht erkannt:\n" .. out)
        assert(out:find("Aus einer Gruppe von Alternativen da: ", 1, true) and out:find("LFGParentFrame", 1, true)
            and not out:find("PVEFrame", 1, true), "Alternative als fehlend gemeldet:\n" .. out)
        assert(out:find("[!] Fenster in Gold: Paket geladen, aber kein Fenster unter diesem Namen – heißt im Client anders: GuildBankFrame (Blizzard_GuildBankUI geladen)", 1, true),
            "geladenes Paket ohne Fenster nicht gemeldet:\n" .. out)
        assert(out:find("[?] Fenster in Gold: Nicht gefunden", 1, true) and out:find("PVPFrame/HonorFrame", 1, true),
            "Gruppe ohne Mitglied nicht gemeldet:\n" .. out)
        -- Eine Gruppe, deren Paket geladen ist, ohne Fenster: auch ein Befund.
        local isLoaded = C_AddOns.IsAddOnLoaded
        C_AddOns.IsAddOnLoaded = function(name) return name == "Blizzard_TalentUI" end
        out = table.concat(SC.Run(), "\n")
        C_AddOns.IsAddOnLoaded = isLoaded
        assert(out:find("PlayerTalentFrame/TalentFrame/ClassTalentFrame (Blizzard_TalentUI geladen)", 1, true),
            "Gruppe mit geladenem Paket ohne Fenster nicht gemeldet:\n" .. out)
        assert(SC.AddonState("Blizzard_GuildBankUI") == "loaded" and SC.AddonState("Blizzard_TrainerUI") == "ondemand"
            and SC.AddonState("Gibtsnicht") == "missing", "Zustand eines Pakets falsch")
        Set("C_AddOns", { GetAddOnInfo = function() error("kaputt") end })
        assert(SC.AddonState("Blizzard_TrainerUI") == "missing", "kaputte Abfrage des Pakets nicht abgefangen")
        -- Messarten: fehlende und neue.
        local oldEnum = Enum.DamageMeterType
        Enum.DamageMeterType = { DamageDone = 0, HealingDone = 1, Neuigkeit = 99 }
        out = table.concat(SC.Run(), "\n")
        Enum.DamageMeterType = oldEnum
        assert(out:find("[!] Messarten: Der Client kennt 2 von", 1, true) and out:find("Absorbs", 1, true),
            "fehlende Messarten nicht genannt:\n" .. out)
        assert(out:find("[?] Messarten: Der Client hat Messarten, die WeintCodex nicht zeigt: Neuigkeit", 1, true), "neue Messart verschwiegen")
        -- Mikromenue geschuetzt.
        local mm = stub.NewObject("Frame")
        mm.IsProtected = function() return true, true end
        Set("MicroMenuContainer", mm)
        -- Ein Fehler eines Teils und eine Pruefung, die selbst scheitert.
        -- Ueber den echten Weg: K.Report merkt sich den Fehler.
        K.Report("testteil", "kaputt")
        assert(K.errors[#K.errors] == "testteil: kaputt", "K.Report merkt sich den Fehler nicht")
        table.insert(SC.CHECKS, { name = "Kaputt", fn = function() error("absichtlich") end })
        local res = SC.Run()
        table.remove(SC.CHECKS)
        table.remove(K.errors)
        out = table.concat(res, "\n")
        assert(out:find("[!] Mikromenü: MicroMenuContainer: geschützt true (ausdrücklich)", 1, true), "geschuetztes Mikromenue:\n" .. out)
        assert(out:find(string.format("[!] Fehler: %d Fehler seit dem Laden:", #K.errors + 1), 1, true)
            and out:find("\n   testteil: kaputt", 1, true), "Fehler nicht genannt")
        assert(out:find("[!] Kaputt: Prüfung selbst scheiterte", 1, true) and out:find("Speicherbedarf:", 1, true),
            "eine scheiternde Pruefung nimmt den Rest mit")
        local bad, open = 0, 0
        for _, l in ipairs(res) do
            if l:find("^%[!%]") then bad = bad + 1 elseif l:find("^%[%?%]") then open = open + 1 end
        end
        assert(SC.last.bad == bad and SC.last.open == open and out:find(string.format("Summe: %d Befunde [!], %d offen [?].", bad, open), 1, true),
            "Summe stimmt nicht")
        for name, v in pairs(saved) do _G[name] = v.v end
        -- Befehle: Bericht im Fenster.
        SlashCmdList["WEINTCODEXUI"]("prüfen")
        assert(K.report:IsShown() and K.report.title:GetText() == "Selbstprüfung", "/wcui prüfen zeigt keinen Bericht")
        K.report:Hide()
        SlashCmdList["WEINTCODEXUI"]("check")
        assert(K.report:IsShown(), "/wcui check zeigt keinen Bericht")
        K.report:Hide()
    end)
    Check(ok, "Bericht zum Kopieren, /wcui fenster je Fundort ohne Grenze, /wcui pruefen (Bedrohung offen/geheim, Messarten, Mikromenue, Fehler, Summe)"
        .. (ok and "" or (": " .. tostring(err))))
end

-- 6.10.3.0: /wc abgleich - Dungeons und Schlachtzuege aus dem Client
-- lesen und gegen den Codex halten. Liest nur.
do
    local ok, err = pcall(function()
        local CC = WeintCodex.ClientCheck
        assert(CC and CC.Run, "Abgleich fehlt")
        local saved = {}
        local function Set(name, v) if saved[name] == nil then saved[name] = { v = _G[name] } end _G[name] = v end
        -- Geheim ist im Client eine Zeichenkette, die Lua nicht lesen darf -
        -- keine Tabelle: die Typpruefung allein liesse sie durch.
        local SECRET = "Geheimer Name"
        Set("issecretvalue", function(v) return v == SECRET end)
        Set("GetLocale", function() return "deDE" end)
        local LFG = {
            [10] = { "Hall of Thanes", 1, 1, 13, 18, 15, 13, 18, 0, 0, "", 1, 5,
                     bosses = { "Magmatus", "Faldrim Anvilmar", "Plunder", "Neuer Boss" } },
            [20] = { "Ruinen von Lordaeron", 1, 1, 15, 20, 17, 15, 20, 0, 0, "", 1, 5, bosses = { "Witterzahn" } },
            [30] = { "Geheimnis", 1, 1, 70, 70, 70, 70, 70, 0, 0, "", 1, 5, bosses = {} },
            [40] = { SECRET, 1, 1, 10, 12, 11, 10, 12, 0, 0, "", 1, 5, bosses = {} },
            -- Ohne "The": der Codex fuehrt "The Drowned City".
            [50] = { "Drowned City", 1, 1, 35, 40, 37, 35, 40, 0, 0, "", 1, 5, bosses = {} },
        }
        Set("GetLFGDungeonInfo", function(id) local e = LFG[id] if e then return unpack(e) end return nil end)
        Set("GetLFGDungeonNumEncounters", function(id) local e = LFG[id] return e and #e.bosses or 0, 0 end)
        Set("GetLFGDungeonEncounterInfo", function(id, i) return LFG[id].bosses[i], "", false end)
        for _, n in ipairs({ "EJ_GetNumTiers", "EJ_SelectTier", "EJ_GetInstanceByIndex", "EJ_GetEncounterInfoByIndex",
                             "EJ_SelectInstance", "EJ_GetCurrentTier" }) do Set(n, nil) end
        -- Der Codex bleibt, wie er ist.
        local before = 0
        for _, d in ipairs(CC.CodexInstances()) do before = before + #(d.bosses or {}) end
        local lines = CC.Run()
        local after = 0
        for _, d in ipairs(CC.CodexInstances()) do after = after + #(d.bosses or {}) end
        assert(before == after and before > 0, "Abgleich veraendert den Codex")
        local text = table.concat(lines, "\n")
        assert(text:find("Liest nur.", 1, true) and text:find("Gruppensuche: 4 Einträge", 1, true)
            and text:find("Dungeonkompendium: kein Dungeonkompendium", 1, true), "Kopf falsch:\n" .. text)
        assert(text:find("Der Client ist nicht englisch", 1, true), "deutscher Client nicht erwaehnt")
        -- Gleicher Name: Boss fuer Boss, Reihenfolge.
        assert(text:find("[Name] Hall of Thanes (Stufe 13–18, 4 Bosse im Codex, Unbestätigt)", 1, true), "Name nicht zugeordnet:\n" .. text)
        assert(text:find("      gleich 3: ", 1, true) and text:find("      nur im Codex: Durgen Dirgehammer", 1, true)
            and text:find("      nur im Client: Neuer Boss", 1, true), "Bossvergleich falsch:\n" .. text)
        assert(text:find("      Reihenfolge weicht ab – Client: Magmatus › Faldrim Anvilmar", 1, true), "Reihenfolge nicht verglichen")
        -- Anderer Name: nur ueber die Stufen, vermutlich, ohne Bossvergleich.
        assert(text:find("[Stufen, vermutlich] Ruins of Lordaeron", 1, true)
            and text:find("Gruppensuche #20 „Ruinen von Lordaeron“ · Stufe 15–20 · 1 Kämpfe: Witterzahn", 1, true),
            "Stufenzuordnung falsch:\n" .. text)
        -- Bestand: Unzugeordnetes steht da, Geheimes nicht.
        assert(text:find("(nicht zugeordnet) Gruppensuche #30 „Geheimnis“", 1, true), "Unzugeordnetes fehlt im Bestand")
        assert(not text:find("Gruppensuche #40", 1, true) and not text:find(SECRET, 1, true), "geheimer Name im Bestand")
        assert(text:find("[Name] The Drowned City", 1, true), "'The' verhindert die Zuordnung ueber den Namen")
        assert(text:find("[kein Gegenstück] ", 1, true), "Codex ohne Gegenstueck nicht gemeldet")
        assert(CC.last and CC.last.name == 2 and CC.last.level > 0 and CC.last.none > 0, "Summe falsch")
        -- Kompendium: Schlachtzug ueber den Namen, Erweiterung zurueckgesetzt.
        local selected = {}
        Set("EJ_GetNumTiers", function() return 1 end)
        Set("EJ_GetCurrentTier", function() return 7 end)
        Set("EJ_SelectTier", function(t) selected[#selected + 1] = t end)
        Set("EJ_SelectInstance", function() end)
        Set("EJ_GetInstanceByIndex", function(idx, isRaid)
            if isRaid and idx == 1 then return 1001, "Barrow Deeps" end
            return nil
        end)
        Set("EJ_GetEncounterInfoByIndex", function(i, inst)
            local list = { "Deepscar Matriarch", "Amethrax" }
            if inst == 1001 then return list[i] end
        end)
        text = table.concat(CC.Run(), "\n")
        assert(text:find("Dungeonkompendium: 1 Instanzen", 1, true) and text:find("[Name] Barrow Deeps", 1, true)
            and text:find("Kompendium #1001 „Barrow Deeps“", 1, true), "Kompendium nicht gelesen:\n" .. text)
        assert(selected[#selected] == 7, "Erweiterung des Kompendiums nicht zurueckgesetzt")
        -- Ohne Gruppensuche: ein Satz statt eines Fehlers.
        Set("GetLFGDungeonInfo", nil)
        text = table.concat(CC.Run(), "\n")
        assert(text:find("Gruppensuche: GetLFGDungeonInfo fehlt", 1, true), "fehlende Gruppensuche nicht gemeldet")
        for name, v in pairs(saved) do _G[name] = v.v end
        -- Befehl: Bericht im Fenster.
        SlashCmdList["WEINTCODEX"]("abgleich")
        assert(WeintCodex.UIKit.report:IsShown() and WeintCodex.UIKit.report.title:GetText() == "Abgleich mit dem Client",
            "/wc abgleich zeigt keinen Bericht")
        WeintCodex.UIKit.report:Hide()
    end)
    Check(ok, "/wc abgleich: Gruppensuche und Kompendium gelesen, Name/Stufen/kein Gegenstueck, Boss fuer Boss, Bestand, schreibt nichts"
        .. (ok and "" or (": " .. tostring(err))))
end

-- 6.10.0.0: Kopfzeile der Schadensanzeige gerechnet statt fest - bei
-- jeder erlaubten Breite passen Titel, Zeitraum und Knoepfe nebeneinander.
do
    local DM = WeintCodex.UIDamageMeter
    local ok, err = pcall(function()
        local H = DM.HEADER
        for w = DM.MIN_WIDTH, 420, 2 do
            for buttons = 0, 5 do
                local tw, sw = DM.HeaderWidths(w, buttons)
                local used = H.left + tw + H.between + sw + H.gap + buttons * H.button + H.edge
                assert(used <= w - 2, string.format("Kopfzeile laeuft ueber: %d px, %d Knoepfe, %d gebraucht", w, buttons, used))
                assert(tw >= H.titleMin and sw >= H.sessionMin, "Titel oder Zeitraum zu schmal bei " .. w)
            end
        end
        -- Eine schmalere Einstellung von frueher wird gehoben.
        K.Set("damagemeter", "width", 160)
        DM.Window(1):Layout()
        assert(DM.Window(1).frame:GetWidth() == DM.MIN_WIDTH, "alte schmale Breite bleibt: " .. tostring(DM.Window(1).frame:GetWidth()))
        local win = DM.Window(1)
        assert(win._titleW and win.title:GetWidth() == win._titleW and win.session:GetWidth() == win._sessionW,
            "Titel/Zeitraum bekommen ihre Breite nicht")
        local n = 0
        for _, b in ipairs({ win.close, win.gear, win.reset, win.report, win.plus }) do
            if b:IsShown() then n = n + 1 end
        end
        assert(n > 0 and win._buttons == n, "Knoepfe nicht mitgezaehlt: " .. tostring(win._buttons) .. " statt " .. n)
        -- Name und Zahl einer Zeile ueberlappen nicht (schmalstes Fenster).
        local r = win.rows[1]
        r.amount:SetText("12,0K (400)  60%")
        win:FitName(r, true)
        local rowW = DM.Width() - 4
        local iconW = K.Get("damagemeter", "barHeight") + 1
        assert(iconW + 5 + r.name:GetWidth() + 10 + r.amount:GetStringWidth() <= rowW,
            "Name laeuft in die Zahl: " .. r.name:GetWidth())
        -- Geheime Breite: Rueckfall auf 55 %, kein Fehler.
        local gsw = r.amount.GetStringWidth
        local secret = 77
        local oldSecret = _G.issecretvalue
        _G.issecretvalue = function(v) return v == secret end
        r.amount.GetStringWidth = function() return secret end
        win:FitName(r, true)
        assert(r.name:GetWidth() == math.floor(DM.Width() * 0.55), "geheime Breite ohne Rueckfall")
        r.amount.GetStringWidth, _G.issecretvalue = gsw, oldSecret
        K.Set("damagemeter", "width", nil)
        DM.Window(1):Layout()
    end)
    Check(ok, "Schadensanzeige: Kopfzeile passt bei jeder Breite (Titel, Zeitraum, Knoepfe), alte schmale Breite gehoben"
        .. (ok and "" or (": " .. tostring(err))))
end

-- 6.10.3.1: Wuerfeln um Beute in Gold. Toast und leuchtender Rand weg,
-- Kachel, Rand des Symbols in der Qualitaet (ab Selten), Zeit flach in
-- Gold UND ueber der Kachel - das Spiel legt sie bei jedem Zeigen darunter.
do
    local oldInfo, oldItem, oldF = _G.GetLootRollItemInfo, _G.C_Item, _G.GroupLootFrame2
    local ok, err = pcall(function()
        local LR, W, K, GC, S = WeintCodex.UILootRoll, WeintCodex.UIWindows, WeintCodex.UIKit,
            WeintCodex.GameColors, WeintCodex.UIStyle
        assert(LR and LR.Skin and LR.Apply, "ui/lootroll.lua fehlt")
        local f = stub.NewObject("Frame", "GroupLootFrame2")
        f._level = 5
        f.Background, f.Border = stub.NewObject("Texture"), stub.NewObject("Texture")
        f.Name = stub.NewObject("FontString")
        f.Name._font = true
        local icf = stub.NewObject("Button")
        icf.Icon, icf.Border = stub.NewObject("Texture"), stub.NewObject("Texture")
        f.IconFrame = icf
        local timer = stub.NewObject("StatusBar")
        timer.Background = stub.NewObject("Texture")
        f.Timer = timer
        local need = stub.NewObject("Button")
        f.NeedButton = need
        local coords, barTex, vc, bgc
        icf.Icon.SetTexCoord = function(_, a) coords = a end
        timer.SetStatusBarTexture = function(_, t) barTex = t end
        local bar = stub.NewObject("Texture")
        timer.GetStatusBarTexture = function() return bar end
        bar.SetVertexColor = function(_, r, g, b) vc = { r, g, b } end
        timer.Background.SetColorTexture = function(_, r, g, b) bgc = { r, g, b } end
        f.rollID = 7
        local quality = 3
        _G.GetLootRollItemInfo = function(id)
            assert(id == 7, "falscher Wurf gelesen")
            return 132, "Kantiges Bastardschwert", 1, quality
        end
        _G.C_Item = setmetatable({ GetItemQualityColor = function(q)
            if q == 3 then return 0, 0.44, 0.87 end
            return 1, 1, 1
        end }, { __index = oldItem })
        _G.GroupLootFrame2 = f
        timer._level = 4            -- so legt es das Spiel hin
        LR.Apply()
        local d = LR.done[f]
        assert(d and d.kachel, "Wurf nicht gestaltet")
        assert(f.Background:GetAlpha() == 0 and f.Border:GetAlpha() == 0, "Toast des Spiels bleibt")
        assert(icf.Border:GetAlpha() == 0, "leuchtender Rand des Spiels bleibt")
        assert(need:GetAlpha() == 1, "Bedarf angefasst")
        assert(W.own[d.kachel.bg], "Kachel nicht als eigene Flaeche eingetragen")
        assert(S.ScopeOf(f) == S.CALM and d.edge and d.light, "Wurf nicht in Gold")
        assert(coords == 0.08, "Symbol nicht beschnitten")
        assert(barTex == K.BAR_TEXTURE, "Zeit nicht flach")
        local a = GC.frameAccent
        assert(vc and vc[1] == a[1] and vc[2] == a[2] and vc[3] == a[3], "Zeit nicht in Gold")
        assert(bgc and bgc[1] == WeintCodex.Colors.bgDark[1], "Rinne der Zeit nicht dunkel")
        assert(f.Name:GetWidth() == LR.NAME_W, "Name nicht verbreitert")
        assert(timer:GetFrameLevel() == 6, "Zeit liegt unter der Kachel: " .. timer:GetFrameLevel())
        assert(d.qualityColored, "Rand nicht in der Qualitaet")
        -- Naechster Wurf: das Spiel legt die Zeit wieder darunter, die
        -- Qualitaet ist gewoehnlich - Rand schwarz.
        local qc
        d.quality.top.SetColorTexture = function(_, r, g, b) qc = { r, g, b } end
        quality, timer._level = 1, 4
        f:GetScript("OnShow")(f)
        assert(timer:GetFrameLevel() == 6, "Zeit beim naechsten Zeigen unter der Kachel")
        assert(qc and qc[1] == 0 and qc[2] == 0 and qc[3] == 0 and not d.qualityColored,
            "gewoehnlicher Gegenstand mit farbigem Rand")
        quality = 3
        f:GetScript("OnShow")(f)
        assert(qc[2] == 0.44 and qc[3] == 0.87, "seltener Gegenstand ohne Rand in der Qualitaet")
        -- Kein Wurf bekannt: kein Fehler, Rand schwarz.
        f.rollID = nil
        f:GetScript("OnShow")(f)
        assert(qc[1] == 0 and qc[3] == 0, "Rand ohne Wurf nicht schwarz")
        LR.Apply()
        assert(LR.done[f] == d, "Wurf doppelt gestaltet")
        -- Der allgemeine Durchlauf nimmt die Wuerfe mit.
        local f3 = stub.NewObject("Frame", "GroupLootFrame3")
        local oldF3 = _G.GroupLootFrame3
        _G.GroupLootFrame3 = f3
        local wasOn = K.Get("general", "windowSkin")
        K.Set("general", "windowSkin", true)
        W.Apply()
        K.Set("general", "windowSkin", wasOn)
        _G.GroupLootFrame3 = oldF3
        assert(LR.done[f3], "W.Apply gestaltet die Wuerfe nicht")
        local rep = table.concat(LR.Report({}), "\n")
        assert(rep:find("1 von 4 gestaltet", 1, true), "Bericht: " .. rep)
        -- /wcui fenster ueber dem Wurf (Maus auf Bedarf) nennt die Gestaltung.
        need.GetParent = function() return f end
        f.GetParent = function() return _G.UIParent end
        local oldFoci = _G.GetMouseFoci
        _G.GetMouseFoci = function() return { need } end
        local insp = table.concat(K.InspectWindow(), "\n")
        _G.GetMouseFoci = oldFoci
        assert(insp:find("Fenster: GroupLootFrame2", 1, true) and insp:find("Würfeln um Beute", 1, true),
            "/wcui fenster ueber dem Wurf: " .. insp)
    end)
    _G.GetLootRollItemInfo, _G.C_Item, _G.GroupLootFrame2 = oldInfo, oldItem, oldF
    Check(ok, "Wuerfeln um Beute: Kachel in Gold, Rand in der Qualitaet, Zeit flach und ueber der Kachel"
        .. (ok and "" or (": " .. tostring(err))))
end

-- 6.10.4.0: Fenster verschieben (wie MoveAny, eigener Code). Ziehen,
-- merken, nach dem Ordnen des Spiels wieder hin, im Kampf geschuetzte
-- Fenster nicht anfassen, Umschalt+Rechtsklick zurueck, Platz zurueck fuer
-- alle, Reiter nicht loesen, vergroesserte Karte nicht, MoveAny/BlizzMove
-- haben Vorrang.
do
    local MW = WeintCodex.UIMoveWindows
    local names = { "CharacterFrame", "SpellBookFrame", "PlayerSpellsFrame", "WorldMapFrame", "MacroFrame",
                    "C_AddOns", "InCombatLockdown", "IsShiftKeyDown", "UpdateUIPanelPositions", "hooksecurefunc" }
    local saved = {}
    for i, n in ipairs(names) do saved[i] = _G[n] end
    local ok, err = pcall(function()
        assert(MW and MW.Start and MW.Hook and MW.Apply, "ui/movewindows.lua fehlt")
        -- Ein Fenster mit echten Ankern und Kanten.
        local function Win(name, parent)
            local f = CreateFrame("Frame", name, parent or UIParent)
            f._pt = { "TOPLEFT", UIParent, "TOPLEFT", 16, -116 }
            f.SetPoint = function(self, p, rel, rp, x, y) self._pt = { p, rel, rp, x, y } end
            f.ClearAllPoints = function(self) self._pt = {} end
            f.GetPoint = function(self) local q = self._pt return q[1], q[2], q[3], q[4], q[5] end
            f._l, f._t = 16, 700
            f.GetLeft = function(self) return self._l end
            f.GetTop = function(self) return self._t end
            f.StartMoving = function(self) self._moving = true end
            f.StopMovingOrSizing = function(self) self._moving = false end
            f.SetUserPlaced = function(self, v) self._userPlaced = v end
            f.IsProtected = function(self) return self._protected or false end
            f:Hide()
            return f
        end
        local loaded = {}
        _G.C_AddOns = { IsAddOnLoaded = function(a) return loaded[a] or false end }
        local combat = false
        _G.InCombatLockdown = function() return combat end
        local shift = false
        _G.IsShiftKeyDown = function() return shift end
        local uiHook
        _G.UpdateUIPanelPositions = function() end
        _G.hooksecurefunc = function(a, b) if a == "UpdateUIPanelPositions" then uiHook = b end end
        -- Bis 6.10.4.0 gemerkte Plaetze: beim Start weg.
        local ui = K.Root()
        ui.windowPos = { CharacterFrame = { x = 1, y = 2 } }
        -- Vorrang fuer MoveAny.
        loaded.MoveAny = true
        local cf = Win("CharacterFrame")
        _G.CharacterFrame = cf
        assert(MW.Start() == false and not MW.active and MW.Status():find("MoveAny", 1, true), "MoveAny geladen, trotzdem aktiv")
        assert(not MW.hooked[cf], "neben MoveAny eingerichtet")
        loaded.MoveAny = nil
        -- Normal: oberstes Fenster ja, Reiter (Eltern = anderes Fenster) nein.
        local psf = Win("PlayerSpellsFrame")
        psf.IsMouseEnabled = function(self) return self._mouse or false end
        psf.EnableMouse = function(self, v) self._mouse = v end
        _G.PlayerSpellsFrame = psf
        local sbf = Win("SpellBookFrame", psf)
        _G.SpellBookFrame = sbf
        MW._uiHook = nil
        assert(MW.Start() and MW.active, "nicht gestartet")
        assert(ui.windowPos == nil, "alte dauerhafte Plaetze bleiben stehen")
        assert(MW.hooked[cf] == "CharacterFrame" and MW.hooked[psf], "Fenster nicht eingerichtet")
        assert(not MW.hooked[sbf], "Teilfenster wird vom Fenster geloest")
        assert(psf._mouse == true, "Fenster ohne Maus bleibt unziehbar")
        assert(type(uiHook) == "function", "Ordnen des Spiels nicht beobachtet")
        -- Ein unverschobenes Fenster: Schliessen fasst es nicht an.
        cf:Show()
        local touched = false
        local sp = cf.SetPoint
        cf.SetPoint = function(...) touched = true return sp(...) end
        cf:Hide()
        cf._scripts.OnHide(cf)
        assert(not touched, "unverschobenes Fenster beim Schliessen versetzt")
        cf.SetPoint = sp
        -- Ziehen: der Platz gilt, solange es offen ist.
        cf:Show()
        cf._scripts.OnDragStart(cf)
        assert(cf._moving, "Ziehen beginnt nicht")
        cf._l, cf._t = 300.4, 650.6
        cf._scripts.OnDragStop(cf)
        assert(not cf._moving and cf._userPlaced == false, "Layout des Spiels uebernimmt den Platz")
        assert(MW.open[cf] and MW.open[cf].x == 300 and MW.open[cf].y == 651, "Platz nicht gemerkt")
        assert(cf._pt[1] == "TOPLEFT" and cf._pt[2] == UIParent and cf._pt[3] == "BOTTOMLEFT" and cf._pt[4] == 300,
            "nach dem Ziehen nicht an den gemerkten Platz verankert")
        assert(K.Root().windowPos == nil, "Platz dauerhaft gespeichert")
        -- Ein zweites Fenster geht auf, das Spiel ordnet neu: es bleibt da.
        cf._pt = { "TOPLEFT", UIParent, "TOPLEFT", 16, -116 }
        uiHook()
        assert(cf._pt[3] == "BOTTOMLEFT" and cf._pt[4] == 300 and cf._pt[5] == 651, "offen: nach dem Ordnen des Spiels nicht am Platz")
        assert(MW.default[cf] and MW.default[cf].x == 16 and MW.default[cf].y == -116, "Platz des Spiels nicht gemerkt")
        -- Mitten im Ziehen ordnet das Spiel: das Fenster bleibt an der Maus.
        cf._scripts.OnDragStart(cf)
        cf._pt = { "CENTER", UIParent, "CENTER", 7, 7 }
        uiHook()
        assert(cf._pt[1] == "CENTER", "Fenster beim Ziehen weggesetzt")
        cf._l, cf._t = 300, 651
        cf._scripts.OnDragStop(cf)
        -- Zu: zurueck an den Platz des Spiels, und beim naechsten Oeffnen
        -- bleibt es dort.
        cf:Hide()
        cf._scripts.OnHide(cf)
        assert(MW.open[cf] == nil and cf._pt[3] == "TOPLEFT" and cf._pt[4] == 16 and cf._pt[5] == -116,
            "nach dem Schliessen nicht am Platz des Spiels")
        cf:Show()
        cf._scripts.OnShow(cf)
        uiHook()
        assert(cf._pt[4] == 16, "beim naechsten Oeffnen am alten gezogenen Platz")
        -- Platz des Spiels ist jetzt bekannt, nicht verschoben: Schliessen
        -- setzt trotzdem nichts.
        local touched2 = false
        local sp2 = cf.SetPoint
        cf.SetPoint = function(...) touched2 = true return sp2(...) end
        cf:Hide()
        cf._scripts.OnHide(cf)
        cf.SetPoint = sp2
        assert(not touched2, "unverschobenes Fenster beim Schliessen versetzt (Platz des Spiels bekannt)")
        cf:Show()
        -- Im Kampf: ein geschuetztes Fenster wird nicht angefasst, danach schon.
        cf._scripts.OnDragStart(cf)
        cf._l, cf._t = 300, 651
        cf._scripts.OnDragStop(cf)
        cf._protected, combat = true, true
        cf._pt = { "TOPLEFT", UIParent, "TOPLEFT", 16, -116 }
        uiHook()
        assert(cf._pt[4] == 16 and MW.pending[cf], "geschuetztes Fenster im Kampf gesetzt")
        cf._scripts.OnDragStart(cf)
        assert(not cf._moving, "geschuetztes Fenster im Kampf gezogen")
        combat = false
        stub.FireEvent("PLAYER_REGEN_ENABLED")
        assert(cf._pt[4] == 300 and not MW.pending[cf], "nach dem Kampf nicht nachgeholt")
        -- Im Kampf geschlossen: zurueck erst nach dem Kampf.
        combat = true
        cf:Hide()
        cf._scripts.OnHide(cf)
        assert(cf._pt[4] == 300 and MW.pending[cf] == "reset", "geschuetztes Fenster im Kampf zurueckgesetzt")
        combat = false
        stub.FireEvent("PLAYER_REGEN_ENABLED")
        assert(cf._pt[4] == 16 and cf._pt[5] == -116, "nach dem Kampf nicht an den Platz des Spiels")
        cf._protected = false
        cf:Show()
        -- Ein geschuetztes Fenster, das im Kampf erst auftaucht: Einrichten nachgeholt.
        local mf = Win("MacroFrame")
        mf._protected = true
        combat = true
        _G.MacroFrame = mf
        stub.FireEvent("ADDON_LOADED", "Blizzard_MacroUI")
        assert(not MW.hooked[mf], "geschuetztes Fenster im Kampf eingerichtet")
        combat = false
        stub.FireEvent("PLAYER_REGEN_ENABLED")
        assert(MW.hooked[mf] == "MacroFrame", "Einrichten nach dem Kampf nicht nachgeholt")
        -- Vergroesserte Karte: nicht ziehen, nicht setzen.
        local map = Win("WorldMapFrame")
        _G.WorldMapFrame = map
        map.IsMaximized = function() return true end
        stub.FireEvent("ADDON_LOADED", "Blizzard_WorldMap")
        assert(MW.hooked[map], "Karte nicht eingerichtet")
        map:Show()
        map._scripts.OnDragStart(map)
        assert(not map._moving, "vergroesserte Karte gezogen")
        MW.open[map] = { x = 5, y = 6 }
        map._scripts.OnShow(map)
        assert(map._pt[4] ~= 5, "vergroesserte Karte versetzt")
        MW.open[map] = nil
        -- Umschalt + Rechtsklick: an den Platz des Spiels.
        cf._scripts.OnDragStart(cf)
        cf._l, cf._t = 300, 651
        cf._scripts.OnDragStop(cf)
        cf._scripts.OnMouseUp(cf, "RightButton")
        assert(MW.open[cf], "Rechtsklick ohne Umschalt setzt zurueck")
        shift = true
        cf._scripts.OnMouseUp(cf, "RightButton")
        shift = false
        assert(MW.open[cf] == nil and cf._pt[3] == "TOPLEFT" and cf._pt[4] == 16, "Umschalt+Rechtsklick setzt nicht zurueck")
        -- /wcui fenster zurück: alle offenen.
        cf._scripts.OnDragStart(cf)
        cf._scripts.OnDragStop(cf)
        psf:Show()
        psf._scripts.OnDragStart(psf)
        psf._scripts.OnDragStop(psf)
        assert(MW.Status():find("2 gerade verschoben", 1, true), "Status: " .. MW.Status())
        SlashCmdList["WEINTCODEXUI"]("fenster zurück")
        assert(next(MW.open) == nil, "/wcui fenster zurück laesst Plaetze stehen")
        assert(MW.Status():find("ziehbar", 1, true), "Status: " .. MW.Status())
        for f in pairs(MW.hooked) do MW.hooked[f] = nil end
    end)
    for i, n in ipairs(names) do _G[n] = saved[i] end
    Check(ok, "Fenster verschieben: ziehen, merken, nach dem Ordnen wieder hin, Kampf, Reiter, Karte, zurueck, MoveAny hat Vorrang"
        .. (ok and "" or (": " .. tostring(err))))
end

-- 6.10.4.1: Markieren per Mouseover. Maus ueber den Gegner, eine Taste
-- (Vorrang-Belegung nur dort, wo markiert wird); naechste freie Markierung,
-- nicht doppelt, Tank/Heiler frei, nie im Kampf, nach dem Kampf frei, was tot ist.
do
    local HM = WeintCodex.UIHoverMark
    local names = { "IsInInstance", "UnitExists", "UnitCanAttack", "UnitPlayerControlled", "UnitIsDead", "UnitGUID",
                    "SetOverrideBindingClick", "ClearOverrideBindings", "InCombatLockdown", "SetRaidTarget" }
    local saved = {}
    for i, n in ipairs(names) do saved[i] = _G[n] end
    local ok, err = pcall(function()
        assert(HM and HM.Prepare and HM.Bind, "ui/hovermark.lua fehlt")
        assert(K.Get("comfort", "markHover") == false, "Mouseover-Markieren von Haus aus an (Komfort: aus)")
        local bindings = {}
        _G.SetOverrideBindingClick = function(owner, prio, key, name, mb)
            bindings[key] = { owner = owner, prio = prio, name = name, mb = mb }
        end
        _G.ClearOverrideBindings = function() for k in pairs(bindings) do bindings[k] = nil end end
        local inside, kind = false, nil
        _G.IsInInstance = function() return inside, kind end
        local mouse = { exists = true, attack = true, player = false, dead = false, guid = "Creature-0-A" }
        local plates = {}
        local function Of(u) if u == "mouseover" then return mouse end return plates[u] end
        _G.UnitExists = function(u) local m = Of(u) return m ~= nil and m.exists ~= false end
        _G.UnitCanAttack = function(_, u) local m = Of(u) return m and m.attack end
        _G.UnitPlayerControlled = function(u) local m = Of(u) return m and m.player end
        _G.UnitIsDead = function(u) local m = Of(u) return m and m.dead end
        _G.UnitGUID = function(u) local m = Of(u) return m and m.guid end
        local combat = false
        _G.InCombatLockdown = function() return combat end
        _G.SetRaidTarget = function() error("SetRaidTarget gerufen") end
        local amWas = K.Get("comfort", "autoMark")
        K.Set("comfort", "autoMark", false)
        HM.Clear()
        K.Set("comfort", "markHover", true)
        assert(HM.On(), "nicht an")
        local b = _G[HM.BUTTON]
        assert(b and HM.button == b, "Knopf fehlt")
        -- Draussen: keine Taste, kein Makro.
        assert(next(bindings) == nil and b:GetAttribute("macrotext") == "", "draussen belegt oder Makro")
        -- In einem Dungeon: Taste mit Vorrang auf den Knopf.
        inside, kind = true, "party"
        stub.FireEvent("ZONE_CHANGED_NEW_AREA")
        local bd = bindings.BUTTON3
        assert(bd and bd.prio == true and bd.name == HM.BUTTON and bd.owner == b, "Taste nicht belegt")
        -- Ueber einem Gegner: Totenkopf vorbereitet.
        stub.FireEvent("UPDATE_MOUSEOVER_UNIT")
        assert(b:GetAttribute("macrotext") == "/tm [@mouseover,harm,nodead] 8", "Makro: " .. tostring(b:GetAttribute("macrotext")))
        -- Gedrueckt: gemerkt; derselbe Gegner bekommt kein Makro mehr.
        b._scripts.PostClick(b)
        assert(HM.state.byGuid["Creature-0-A"] == 8 and b:GetAttribute("macrotext") == "", "zweiter Druck naehme die Markierung ab")
        -- Naechster Gegner: Kreuz.
        mouse.guid = "Creature-0-B"
        stub.FireEvent("UPDATE_MOUSEOVER_UNIT")
        assert(b:GetAttribute("macrotext"):find("%] 7$"), "zweiter Gegner nicht Kreuz: " .. b:GetAttribute("macrotext"))
        b._scripts.PostClick(b)
        -- Automark aus: Quadrat ist frei, obwohl es die Tank-Markierung waere.
        mouse.guid = "Creature-0-C"
        stub.FireEvent("UPDATE_MOUSEOVER_UNIT")
        assert(b:GetAttribute("macrotext"):find("%] 6$"), "Automark aus, Quadrat trotzdem gesperrt: " .. b:GetAttribute("macrotext"))
        -- Kreuz vergeben, Quadrat dem Tank (Automark an): der dritte bekommt Mond.
        K.Set("comfort", "markHoverUse6", true)
        K.Set("comfort", "autoMark", true)
        K.Set("comfort", "markTank", 6)
        mouse.guid = "Creature-0-C"
        stub.FireEvent("UPDATE_MOUSEOVER_UNIT")
        assert(b:GetAttribute("macrotext"):find("%] 5$"), "Tank-Markierung nicht ausgelassen: " .. b:GetAttribute("macrotext"))
        K.Set("comfort", "markHoverUse5", false)
        stub.FireEvent("UPDATE_MOUSEOVER_UNIT")
        assert(b:GetAttribute("macrotext"):find("%] 4$") == nil and b:GetAttribute("macrotext"):find("%] [34]$"),
            "abgewaehlte Markierung benutzt: " .. b:GetAttribute("macrotext"))
        K.Set("comfort", "markHoverUse5", nil)
        K.Set("comfort", "autoMark", false)
        K.Set("comfort", "markTank", nil)
        -- Kein Gegner: Spieler, Freund, Toter.
        for _, f in ipairs({ { "player", true }, { "attack", false }, { "dead", true } }) do
            local was = mouse[f[1]]
            mouse[f[1]] = f[2]
            stub.FireEvent("UPDATE_MOUSEOVER_UNIT")
            assert(b:GetAttribute("macrotext") == "", "markiert trotz " .. f[1])
            mouse[f[1]] = was
        end
        -- Kampf: Text beim Beginn geleert, ein Druck im Kampf merkt nichts.
        stub.FireEvent("UPDATE_MOUSEOVER_UNIT")
        assert(b:GetAttribute("macrotext") ~= "", "Vorbedingung: Makro da")
        stub.FireEvent("PLAYER_REGEN_DISABLED")
        combat = true
        assert(b:GetAttribute("macrotext") == "", "Makro im Kampf noch gesetzt")
        stub.FireEvent("UPDATE_MOUSEOVER_UNIT")
        assert(b:GetAttribute("macrotext") == "", "im Kampf neu vorbereitet")
        local said = {}
        local oldPrint = print
        print = function(s) said[#said + 1] = tostring(s) end
        b._scripts.PostClick(b)
        b._scripts.PostClick(b)
        print = oldPrint
        assert(HM.state.byGuid["Creature-0-C"] == nil, "im Kampf als markiert gemerkt")
        assert(#said == 1 and said[1]:find("außerhalb des Kampfes", 1, true), "Druck im Kampf ohne (einmaligen) Hinweis: " .. #said)
        -- Nach dem Kampf: A ist tot, B lebt mit Plakette - A's Totenkopf ist frei.
        plates.nameplate1 = { guid = "Creature-0-A", dead = true }
        plates.nameplate2 = { guid = "Creature-0-B", dead = false }
        combat = false
        stub.FireEvent("PLAYER_REGEN_ENABLED")
        assert(HM.state.byGuid["Creature-0-A"] == nil and HM.state.byMark[8] == nil, "Markierung des Toten nicht frei")
        assert(HM.state.byGuid["Creature-0-B"] == 7, "Markierung des Lebenden verloren")
        mouse.guid = "Creature-0-D"
        stub.FireEvent("UPDATE_MOUSEOVER_UNIT")
        assert(b:GetAttribute("macrotext"):find("%] 8$"), "frei gewordener Totenkopf nicht wieder vergeben")
        -- Taste waehlbar, Wo: nur Dungeons.
        K.Set("comfort", "markHoverKey", "BUTTON4")
        assert(bindings.BUTTON4 and not bindings.BUTTON3, "neue Taste nicht belegt")
        K.Set("comfort", "markHoverWhere", "party")
        kind = "raid"
        stub.FireEvent("ZONE_CHANGED_NEW_AREA")
        assert(next(bindings) == nil, "nur Dungeons: im Schlachtzug belegt")
        assert(next(HM.state.byGuid) == nil, "Gebietswechsel: alte Markierungen gemerkt")
        K.Set("comfort", "markHoverWhere", nil)
        K.Set("comfort", "markHoverKey", nil)
        -- Gebiet im Kampf gewechselt: Belegung erst danach.
        inside, kind = false, nil
        stub.FireEvent("ZONE_CHANGED_NEW_AREA")
        assert(next(bindings) == nil, "Vorbedingung: draussen belegt")
        inside, kind = true, "party"
        combat = true
        stub.FireEvent("ZONE_CHANGED_NEW_AREA")
        assert(next(bindings) == nil, "Belegung im Kampf gesetzt")
        combat = false
        stub.FireEvent("PLAYER_REGEN_ENABLED")
        assert(bindings.BUTTON3, "Belegung nach dem Kampf nicht nachgeholt")
        -- Aus: Taste wieder frei.
        K.Set("comfort", "markHover", nil)
        assert(next(bindings) == nil and b:GetAttribute("macrotext") == "", "ausgeschaltet: Taste belegt")
        assert(HM.Status() == "Aus.", "Status: " .. HM.Status())
        -- Einstellungen: drei sichtbar auf der Seite Automark, die acht Markierungen unter Erweitert.
        local O = WeintCodex.UIOptions
        local vis, adv = {}, 0
        for _, e in ipairs(O.SearchIndex()) do
            if e.module == "comfort" and e.pageLabel == "Automark" then
                if e.advanced then adv = adv + 1 else vis[e.label] = true end
            end
        end
        assert(vis["Per Mouseover markieren"] and vis["Taste"] and vis["Wo"], "Mouseover-Einstellungen nicht sichtbar")
        assert(adv == 8, "Markierungen nicht unter Erweitert: " .. adv)
        K.Set("comfort", "autoMark", amWas)
    end)
    for i, n in ipairs(names) do _G[n] = saved[i] end
    Check(ok, "Mouseover-Markieren: Taste nur in der Instanz, naechste freie Markierung, nicht doppelt, Tank/Heiler frei, nie im Kampf, frei nach dem Tod"
        .. (ok and "" or (": " .. tostring(err))))
end

-- 6.11.0.0: Startseite neu - "Was mache ich als Naechstes?". Hoechstens
-- drei Schritte nach Dringlichkeit, der Weg der naechsten Stufen; leere
-- Plaetze sind kein Mangel (Beta-Test, Stufe 3: "11 Dinge sind noch offen").
Section("Startseite")
do
    local HM = WeintCodex.Home
    local ok, err = pcall(function()
        local function Trainer(nowN, money, nowCost, soon, later, weapons)
            local now = {}
            for i = 1, nowN do now[i] = { id = i, level = 1, cost = 10 } end
            local rest = type(money) == "number" and (money - nowCost) or nil
            return { cat = { sections = { now = now, soon = soon or {}, later = later or {} } },
                     budget = { money = money, now = nowCost, rest = rest,
                                weaponCount = weapons or 0, weapons = (weapons or 0) * 1000 } }
        end
        local function Keys(steps)
            local k = {}
            for i, s in ipairs(steps) do k[i] = s.key end
            return table.concat(k, ",")
        end
        local hot = WeintCodex.DungeonData.Get("hall_of_thanes")
        assert(hot, "Hall of Thanes fehlt im Bestand")

        -- Das Bild aus dem Beta-Test: Stufe 3, elf leere Plaetze, nichts
        -- beim Lehrer, vier Waffen. Leere Plaetze sind KEIN Schritt.
        local ctx = { level = 3, className = "Paladin", trainer = Trainer(0, 18300, 0, {}, {}, 4),
                      gear = { empty = { "Kopf", "Hals", "Schultern", "Umhang", "a", "b", "c", "d", "e", "f", "g" }, broken = {} },
                      fit = {}, dungeonQuests = {}, dungeons = { hot } }
        local steps = HM.Steps(ctx)
        assert(Keys(steps) == "weapons", "Stufe 3: " .. Keys(steps))
        assert(HM.Headline(ctx, steps) == "4 Waffenfertigkeiten lernbar", "Ueberschrift: " .. HM.Headline(ctx, steps))
        for _, s in ipairs(steps) do assert(not s.title:find("offen"), "leere Plaetze als offen") end
        -- 1s 83k gegen 4 x 10s: das Gold reicht nicht - gesagt, aber nicht rot.
        ctx.trainer.budget.money = 183
        assert(HM.Steps(ctx)[1].detail:find("es fehlen 38s 17k", 1, true) and not HM.Steps(ctx)[1].tone,
            "Waffen: " .. HM.Steps(ctx)[1].detail)
        ctx.trainer.budget.money = 18300
        assert(HM.Steps(ctx)[1].detail:find("dein Gold reicht", 1, true), "Waffen, Gold reicht")

        -- Lehrer: Gold reicht / fehlt / unbekannt - nie 0.
        local s = HM.Steps({ trainer = Trainer(2, 500, 20) })[1]
        assert(s.key == "trainer" and s.title == "2 Zauber lernbar" and s.detail:find("dein Gold reicht", 1, true)
            and not s.tone, "Lehrer, Gold reicht: " .. tostring(s.detail))
        assert(s.headline == "2 Zauber warten beim Lehrer" and s.go.tab == "lehrer", "Lehrer: Ueberschrift/Ziel")
        s = HM.Steps({ trainer = Trainer(1, 5, 20) })[1]
        assert(s.tone == "danger" and s.detail:find("es fehlen 15k", 1, true) and s.title == "Ein Zauber lernbar",
            "Lehrer, Gold fehlt: " .. tostring(s.detail))
        s = HM.Steps({ trainer = Trainer(1, nil, 20) })[1]
        assert(not s.tone and s.detail:find("unbekannt", 1, true), "Lehrer ohne Gold geurteilt: " .. tostring(s.detail))

        -- Quests und Reparieren.
        s = HM.Steps({ quests = { readyCount = 3, ready = 4200 } })[1]
        assert(s.key == "quests" and s.title == "3 Quests abgabebereit" and s.detail:find("4.200 EP", 1, true)
            and s.action == "Auf der Karte zeigen" and s.go.map, "Quests: " .. tostring(s.title))
        assert(#HM.Steps({ quests = { readyCount = 0, ready = 0 } }) == 0, "keine Quest als Schritt")
        s = HM.Steps({ gear = { empty = {}, broken = { "Brust" } } })[1]
        assert(s.key == "repair" and s.tone == "danger" and s.detail:find("Brust", 1, true), "Reparieren fehlt")

        -- Reihenfolge und Obergrenze: alles da -> die drei dringendsten.
        local all = { trainer = Trainer(2, 500, 20, {}, {}, 1), quests = { readyCount = 1, ready = 100 },
                      gear = { broken = { "Brust" } }, fit = { hot },
                      dungeonQuests = { { dungeon = hot, active = 1, ready = 1 } } }
        assert(Keys(HM.Steps(all)) == "trainer,quests,repair", "Reihenfolge: " .. Keys(HM.Steps(all)))
        all.trainer, all.quests, all.gear = nil, nil, nil
        steps = HM.Steps(all)
        assert(Keys(steps) == "dungeonQuests", "Dungeon mit Quests verdraengt den passenden nicht: " .. Keys(steps))
        assert(steps[1].detail:find("2 Quests im Log", 1, true) and steps[1].detail:find("1 abgabebereit", 1, true)
            and steps[1].go.dungeon == "hall_of_thanes", "Dungeon-Quests: " .. steps[1].detail)
        all.dungeonQuests = {}
        steps = HM.Steps(all)
        assert(Keys(steps) == "dungeonFit" and steps[1].title == hot.name, "passender Dungeon: " .. Keys(steps))

        -- Ohne Stufe: kein Schritt, kein Weg, ehrliche Ueberschrift.
        steps = HM.Steps({})
        assert(#steps == 0 and HM.Path({}) == nil and HM.Headline({}, steps) == "Willkommen zurück", "ohne Stufe geraten")
        assert(HM.IdleDetail({}, nil):find("meldet der Client", 1, true), "ohne Stufe: Leerzeile")

        -- Der Weg: Zauber je Stufe, Dungeons ab ihrer Stufe, aufsteigend,
        -- hoechstens HM.MAX_PATH; was unter der eigenen Stufe liegt, fehlt.
        local soon = { { level = 4 }, { level = 4 }, { level = 5 } }
        local later = { { level = 10 }, { level = 12 }, { level = 14 }, { level = 16 } }
        local low = { name = "Niedrig", minLevel = 2 }
        local four = { name = "Vier", minLevel = 4 }
        local path = HM.Path({ level = 3, trainer = Trainer(0, 0, 0, soon, later), dungeons = { hot, low, four } })
        assert(#path == HM.MAX_PATH, "Weg: " .. #path)
        assert(path[1].level == 4 and path[1].spells == 2 and path[1].dungeons[1] == "Vier", "Stufe 4 falsch")
        assert(path[2].level == 5 and path[3].level == 10 and path[4].level == 12 and path[5].level == 13
            and path[5].dungeons[1] == hot.name, "Weg nicht aufsteigend oder Dungeon fehlt")
        for _, m in ipairs(path) do assert(m.level > 3, "Weg zeigt Vergangenes") end
        assert(HM.IdleDetail({ level = 3 }, path) == "Der nächste Zauber kommt mit Stufe 4.", "Leerzeile ohne naechsten Zauber")

        -- Nichts muss scrollen: volle Seite im kleinsten Fenster.
        local budget = WeintCodex.DungeonPages.PageBudget()
        assert(HM.PageHeight() <= budget, "Startseite " .. HM.PageHeight() .. " > " .. budget)

        -- Die Seite: einmal gebaut, danach nur gefuellt.
        WeintCodex.Navigation.SwitchTo("uebersicht")
        local f = HM.Page()
        assert(f and f:IsShown(), "Startseite nicht offen")
        local nav = WeintCodex.Navigation
        local badges, counts = {}, {}
        local oldB, oldC = nav.SetTabBadge, nav.SetTabCount
        nav.SetTabBadge = function(id, on) badges[id] = on end
        nav.SetTabCount = function(id, v) counts[id] = v or false end
        local oldSnap = WeintCodex.Charakter.Snapshot
        WeintCodex.Charakter.Snapshot = function() return ctx.gear end
        HM.Show()
        WeintCodex.Charakter.Snapshot = oldSnap
        nav.SetTabBadge, nav.SetTabCount = oldB, oldC
        assert(HM.Page() == f, "Startseite bei jedem Oeffnen neu gebaut")
        assert(badges.charakter == false, "leere Plaetze setzen den Punkt am Charakter")
        assert(badges.import == nil and badges.companion ~= nil, "Punkt der Companion-Warteschlange nicht an Companion")
        assert(counts.raids == false, "Schlachtzuege tragen auf der Startseite eine Zahl")

        -- 6.11.0.2: "AUßERDEM" im Spiel - ß wird SS.
        assert(WeintCodex.Upper("Außerdem") == "AUSSERDEM" and WeintCodex.Upper("Größe") == "GRÖSSE",
            "Versal: " .. WeintCodex.Upper("Außerdem"))
        -- Laufweite: Haar-Leerzeichen zwischen den Zeichen, Umlaute ganz.
        assert(HM.Tracked("Stufe") == "S\226\128\138T\226\128\138U\226\128\138F\226\128\138E", "Laufweite")
        local nae, gaps = HM.Tracked("Nä"):gsub("\226\128\138", "")
        assert(nae == "NÄ" and gaps == 1, "Laufweite trennt Umlaute: " .. gaps .. " Luecken")
        local PX = WeintCodex.Metrics.PAD_X
        assert(HM.InnerWidth(1468) == HM.MAX_W and HM.InnerWidth(884) == 884 - 2 * PX and HM.InnerWidth(nil) == HM.MAX_W,
            "Breite innen: " .. HM.InnerWidth(1468) .. " / " .. HM.InnerWidth(884))
        -- Muenzen: ohne GetCoinTextureString in Worten, nie 0 fuer unbekannt.
        assert(HM.Coins(nil) == "—" and HM.Coins(4000) == "40s", "Muenzen: " .. HM.Coins(4000))

        -- Das Bild aus dem Entwurf: Stufe 7, zwei Quests (1.220 EP), Waffen.
        ctx.level, ctx.xp = 7, { cur = 2160, max = 4500, rested = 10 }
        ctx.quests = { readyCount = 2, ready = 1220 }
        ctx.trainer.budget.money = 1280
        HM.Fill(f, ctx)
        local h = f.hero
        assert(h.title:GetText() == "2 Quests abgabebereit" and h.button:IsShown()
            and h.button._label:GetText() == "Auf der Karte zeigen", "Kachel: " .. tostring(h.title:GetText()))
        assert(h.detail:GetText():find("1.220 EP", 1, true), "Kachel, Einzelheit: " .. tostring(h.detail:GetText()))
        assert(h.level:GetText() == "7" and h.class:GetText() == "Paladin", "Stufe in der Kachel")
        local plain = function(t) return (tostring(t):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")) end
        assert(plain(h.xpLeft:GetText()) == "2.160 / 4.500 EP bis Stufe 8 · 48 %", "Erfahrung: " .. plain(h.xpLeft:GetText()))
        assert(plain(h.xpRight:GetText()) == "nach Abgabe 75 % · erholt 10 EP", "nach Abgabe: " .. plain(h.xpRight:GetText()))
        assert(math.abs(h.pct - 0.48) < 0.001 and math.abs(h.after - (3380 / 4500)) < 0.001 and h.legend2:IsShown(),
            "Leiste: " .. tostring(h.pct) .. " / " .. tostring(h.after))
        -- Ausserdem: eine Karte mit Symbol, Kosten und Fehlbetrag in Bernstein.
        assert(f.more:IsShown() and f.more.count:GetText() == "1 weiterer Schritt", "Ausserdem: Zahl")
        local c = f.cards[1]
        assert(c:IsShown() and not f.cards[2]:IsShown() and c.title:GetText() == "4 Waffenfertigkeiten lernbar"
            and c.sub:GetText() == "Beim Waffenmeister · optional" and c.iconPath == HM.ICONS.weapons,
            "Karte: " .. tostring(c.title:GetText()))
        assert(c.cost:GetText() == "40s" and c.short:GetText() == "es fehlen 27s 20k", "Kosten: " .. tostring(c.short:GetText()))
        assert(c.shortColor == "warningBright", "optionaler Fehlbetrag nicht in Bernstein")
        -- 6.11.0.4: Satz und Zeile enden vor dem LAENGEREN von Kosten und
        -- Fehlbetrag (Beta-Test: Namen liefen unter "es fehlen" durch).
        local shortEst = WeintCodex.Utf8Len("es fehlen 27s 20k") * 12 * 0.56
        assert(c.moneyW >= shortEst, "Spalte Kosten schmaler als der Fehlbetrag: " .. c.moneyW)
        local hf = io.open(ROOT .. "/modules/home.lua"):read("*a")
        assert(hf:find('c.title:SetPoint("RIGHT", c.money, "LEFT"', 1, true) and hf:find('c.sub:SetPoint("RIGHT", c.money, "LEFT"', 1, true),
            "Satz oder Zeile der Karte enden nicht vor der Spalte der Kosten")
        assert(HM.Visible("|cffffffff12|r|TInterface\\MoneyFrame\\UI-SilverIcon:0:0:2:0|t") == "1200", "sichtbarer Text")
        -- Dein Weg: acht Stufen nebeneinander, ab der eigenen.
        local lv = HM.last.levels
        assert(#lv == HM.WEG_COLS and lv[1].level == 7 and lv[1].current and lv[8].level == 14, "Weg: Stufen")
        assert(f.cols[1].kind == "current" and f.cols[1].text:GetText() == "du bist hier", "Weg: du")
        local thanes
        for _, s2 in ipairs(f.cols) do if s2.m and s2.m.level == 13 then thanes = s2 end end
        assert(thanes and thanes.kind == "dungeon" and thanes.text:GetText():find(hot.name, 1, true), "Weg: Dungeon bei 13")
        assert(f.cols[2].kind == "none" and f.cols[2].level:GetText() == "8", "Weg: Stufe ohne Neues")
        -- 6.13.5.0: Fraktion. Ein Allianz-Jaeger bekam Ragefire Chasm
        -- (Orgrimmar) als "passt"; ohne bekannte Fraktion bleibt alles.
        local D = WeintCodex.DungeonData
        assert(D.ForFaction({ faction = "Horde" }, "Alliance") == false and D.ForFaction({ faction = "Horde" }, "Horde")
            and D.ForFaction({}, "Alliance") and D.ForFaction({ faction = "Horde" }, nil), "ForFaction")
        local function ids(list)
            local t = {}
            for _, d in ipairs(list) do t[d.id] = true end
            return t
        end
        local fitA = ids((HM.Dungeons(13, "Alliance")))
        local fitH = ids((HM.Dungeons(13, "Horde")))
        local fitN = ids((HM.Dungeons(13, nil)))
        assert(fitA.hall_of_thanes and not fitA.ragefire_chasm, "Allianz auf 13: Ragefire vorgeschlagen")
        assert(fitH.ragefire_chasm and not fitH.hall_of_thanes, "Horde auf 13: Hall of Thanes vorgeschlagen")
        assert(fitN.ragefire_chasm and fitN.hall_of_thanes, "ohne Fraktion ausgeschlossen")
        local allA, allH = ids(HM.AllDungeons("Alliance")), ids(HM.AllDungeons("Horde"))
        assert(allA.the_stockade and not allH.the_stockade and allA.the_deadmines and allH.the_deadmines,
            "Weg: Stockade nur Allianz, Deadmines beide")
        local hf2 = io.open(ROOT .. "/modules/home.lua"):read("*a")
        assert(hf2:find("HM.Dungeons(ctx.level, ctx.faction)", 1, true) and hf2:find("ctx.dungeons = AllDungeons(ctx.faction)", 1, true),
            "Uebersicht fragt ohne Fraktion")
        -- 6.13.4.0, Beta-Test Stufe 13: bei 17 stand "Wailing Caverns..." -
        -- zwei Dungeons mit Zeilenumbruch in einem einzeiligen Text, der
        -- zweite (The Deadmines) war unsichtbar. Jetzt zwei Texte.
        assert(not thanes.text:GetText():find("\n", 1, true), "Zeilenumbruch in einem einzeiligen Text")
        local l1, l2 = HM.ColumnText({ dungeons = { "Wailing Caverns", "The Deadmines" }, spells = 3 })
        assert(l1.text == "Wailing Caverns" and l2 and l2.text == "The Deadmines" and l2.color == "infoBright",
            "zweiter Dungeon nicht in der zweiten Zeile")
        l1, l2 = HM.ColumnText({ dungeons = { "A", "B", "C" }, spells = 0 })
        assert(l2 and l2.text == "+2 weitere", "drei Dungeons ohne Zaehlung: " .. tostring(l2 and l2.text))
        l1, l2 = HM.ColumnText({ dungeons = { "A" }, spells = 3 })
        assert(l2 and l2.text == "3 neue Zauber" and l2.color == "textMuted", "Zauber nicht unter dem Dungeon")
        l1, l2 = HM.ColumnText({ dungeons = { "A" }, spells = 0 })
        assert(l2 == nil, "zweite Zeile ohne Inhalt")
        local two = { level = 13, trainer = Trainer(0, 0, 0, {}, {}), dungeons = {
            { name = "Wailing Caverns", minLevel = 17 }, { name = "The Deadmines", minLevel = 17 } } }
        HM.Fill(f, two)
        local at17
        for _, s2 in ipairs(f.cols) do if s2.m and s2.m.level == 17 then at17 = s2 end end
        assert(at17 and at17.text:GetText() == "Wailing Caverns" and at17.text2:GetText() == "The Deadmines",
            "Stufe 17: " .. tostring(at17 and at17.text:GetText()) .. " / " .. tostring(at17 and at17.text2:GetText()))
        for _, s2 in ipairs(f.cols) do
            if s2.m and s2.m.level ~= 17 then assert(s2.text2:GetText() == "", "zweite Zeile bleibt stehen bei " .. s2.m.level) end
        end
        HM.Fill(f, ctx)
        assert(f.track:IsShown() and math.abs(f.wayPct - 0.48) < 0.001, "Weg: Linie bis zur naechsten Stufe")
        for key, path in pairs(HM.ICONS) do assert(path:find("media\\ui\\icon_"), "Symbol " .. key) end
        -- Kosten, ohne dass das Gold reicht -> Rot beim Lehrer (Pflicht).
        local three = { level = 5, trainer = Trainer(2, 5, 20, {}, {}, 1), quests = { readyCount = 1, ready = 100 },
                        gear = { broken = { "Brust" } }, dungeons = {} }
        HM.Fill(f, three)
        assert(h.title:GetText() == "2 Zauber warten beim Lehrer" and f.cards[1]:IsShown() and f.cards[2]:IsShown()
            and f.more.count:GetText() == "2 weitere Schritte", "drei Schritte falsch verteilt")
        assert(f.cards[1].step.key == "quests" and f.cards[1].iconPath == HM.ICONS.quests
            and not f.cards[1].cost:IsShown(), "Karte Quests")
        assert(f.cards[1].moneyW == 0, "Karte ohne Kosten haelt Platz frei: " .. f.cards[1].moneyW)
        assert(f.cards[2].step.key == "repair" and f.cards[2].button:IsShown(), "Karte Reparieren")
        assert(not h.bar:IsShown() and not h.xpLeft:IsShown(), "Erfahrung ohne Antwort als Leiste")

        -- 6.11.0.3: welche Zauber, mit Namen - ohne erst zum Lehrer zu
        -- gehen. Namen nennt der Client; fehlt einer, Wort und Nummer.
        local TRm = WeintCodex.Trainer
        local oldInfo = TRm.SpellInfo
        local NAMES = { [1] = "Arkaner Schuss", [2] = "Biss der Schlange", [3] = "Raptorstoß",
                        [4] = "Mal des Jägers", [5] = "Erschütternder Schuss", [6] = "Aspekt des Affen",
                        [196] = "Einhandäxte", [264] = "Bogen" }
        TRm.SpellInfo = function(id) return NAMES[id], id == 3 and "Rang 2" or nil, "icon" .. id end
        local listOk, listErr = pcall(function()
            local st = HM.Steps({ trainer = Trainer(2, 500, 20) })[1]
            assert(#st.spells == 2 and st.spells[1] == 1 and st.spells[2] == 2, "Lehrer: Zauber-IDs fehlen am Schritt")
            local wt = Trainer(0, 18300, 0, {}, {}, 2)
            wt.weapons = { { id = 196, key = "now" }, { id = 197, key = "known" }, { id = 264, key = "now" },
                           { id = 200, key = "later" } }
            st = HM.Steps({ trainer = wt })[1]
            assert(st.key == "weapons" and #st.spells == 2 and st.spells[1] == 196 and st.spells[2] == 264,
                "Waffen: nur die jetzt lernbaren")
            -- Kachel: Namen unter der Einzelheit, Erfahrung rueckt nach unten.
            HM.Fill(f, three)
            assert(h.listShown and h.chips:IsShown() and #h.chipNames == 2 and h.chipNames[1] == "Arkaner Schuss"
                and h.chipNames[2] == "Biss der Schlange" and h.chipRest == 0, "Kachel: Namen der Zauber")
            assert(h.chip[1]:IsShown() and h.chip[1].spellID == 1 and not h.chip[3]:IsShown(), "Kachel: Zauber-Knoepfe")
            assert(h.xpTop == HM.HERO_TOP + HM.LIST_H, "Erfahrung nicht unter der Namenszeile: " .. tostring(h.xpTop))
            -- Zu viele fuer die Zeile: so viele wie passen, der Rest als Zahl.
            local six = Trainer(6, 500, 60)
            local oldW = h.chips.GetWidth
            h.chips.GetWidth = function() return 360 end
            HM.Fill(f, { level = 5, trainer = six, dungeons = {} })
            local n = #h.chipNames
            assert(n >= 1 and n < 6 and h.chipRest == 6 - n and h.chipMore:IsShown()
                and h.chipMore:GetText() == "+" .. (6 - n) .. ((6 - n) == 1 and " weiterer" or " weitere"),
                "Ueberlauf: " .. n .. " / " .. tostring(h.chipMore:GetText()))
            assert(h.chip[3]:IsShown() == (n >= 3) and not h.chip[6]:IsShown(), "Ueberlauf: Knoepfe sichtbar")
            -- Schon der erste passt nicht: er steht trotzdem, gekuerzt.
            h.chips.GetWidth = function() return 60 end
            HM.LayoutChips(h)
            assert(#h.chipNames == 1 and h.chipRest == 5 and h.chip[1]:IsShown(), "schmal: erster fehlt")
            HM.Fill(f, three)
            assert(#h.chipNames == 1 and h.chipRest == 1 and h.chipMore:GetText() == "+1 weiterer", "Einzahl: " .. tostring(h.chipMore:GetText()))
            h.chips.GetWidth = oldW
            -- Name fehlt noch: Wort und Nummer, nie leer.
            NAMES[2] = nil
            HM.Fill(f, three)
            assert(h.chipNames[2] == "Zauber 2", "fehlender Name: " .. tostring(h.chipNames[2]))
            NAMES[2] = "Biss der Schlange"
            -- Nichts muss scrollen: gerechnet wie gezeichnet - drei Schritte,
            -- Namenszeile, Erfahrung.
            local full = { level = 5, trainer = Trainer(2, 500, 20, {}, {}, 1), quests = { readyCount = 1, ready = 100 },
                           xp = { cur = 10, max = 100 }, gear = { broken = { "Brust" } }, dungeons = {} }
            HM.Fill(f, full)
            local drawn = HM.TOP + h:GetHeight() + HM.GAP + f.more:GetHeight() + HM.GAP + f.way:GetHeight()
            assert(h.listShown and drawn == HM.PageHeight(), "Seitenhoehe " .. HM.PageHeight() .. ", gezeichnet " .. drawn)
            -- Ohne Liste: Textblock wie zuvor, Erfahrung an ihrem Platz.
            HM.Fill(f, { level = 5, quests = { readyCount = 1, ready = 100 }, xp = { cur = 10, max = 100 }, dungeons = {} })
            assert(not h.listShown and not h.chips:IsShown() and h.xpTop == HM.HERO_TOP and #h.chipNames == 0,
                "Namenszeile ohne Zauber")
            -- Karte Waffen: erst was, dann wo.
            HM.Fill(f, { level = 5, quests = { readyCount = 1, ready = 100 }, trainer = wt, dungeons = {} })
            assert(f.cards[1].step.key == "weapons" and f.cards[1].sub:GetText() == "Einhandäxte, Bogen – optional, beim Waffenmeister",
                "Karte Waffen: " .. tostring(f.cards[1].sub:GetText()))
            assert(not f.cards[1].short:IsShown() and f.cards[1].moneyW >= WeintCodex.Utf8Len(f.cards[1].cost:GetText()) * 14 * 0.56,
                "Spalte Kosten ohne Fehlbetrag: " .. f.cards[1].moneyW)
            -- Dein Weg: die Namen einer Stufe im Tooltip; "du" und "nichts" ohne.
            local wtr = Trainer(0, 0, 0, { { id = 4, level = 6 }, { id = 3, level = 6 } }, { { id = 6, level = 9 } })
            HM.Fill(f, { level = 5, trainer = wtr, dungeons = { { name = "Tor", minLevel = 9 } } })
            local col6, col9
            for _, c2 in ipairs(f.cols) do
                if c2.m and c2.m.level == 6 then col6 = c2 elseif c2.m and c2.m.level == 9 then col9 = c2 end
            end
            local lines = HM.ColumnLines(col6.m)
            assert(#lines == 2 and lines[1].text:find("Mal des Jägers", 1, true) and lines[1].text:find("|Ticon4:", 1, true)
                and lines[2].text:find("Raptorstoß", 1, true) and lines[2].text:find("Rang 2", 1, true), "Weg-Tooltip: Zauber")
            lines = HM.ColumnLines(col9.m)
            assert(#lines == 2 and lines[1].text:find("Aspekt des Affen", 1, true) and lines[2].text == "Dungeon: Tor"
                and lines[2].color == "infoBright", "Weg-Tooltip: Dungeon")
            assert(#HM.ColumnLines(f.cols[1].m) == 0 and #HM.ColumnLines(f.cols[3].m) == 0, "Weg-Tooltip bei du/nichts")
            local shown = {}
            local oldGT = _G.GameTooltip
            _G.GameTooltip = { SetOwner = function() end, SetText = function(_, t) shown[#shown + 1] = t end,
                               AddLine = function(_, t) shown[#shown + 1] = t end, Show = function() shown.on = true end,
                               Hide = function() end }
            HM.ColumnTooltip(col6)
            _G.GameTooltip = oldGT
            assert(shown.on and shown[1] == "Stufe 6" and #shown == 3, "Weg-Tooltip nicht gezeigt")
        end)
        TRm.SpellInfo = oldInfo
        assert(listOk, listErr)

        HM.Fill(f, { level = 3, trainer = Trainer(0, 0, 0), dungeons = {} })
        assert(h.title:GetText() == "Nichts offen – weiter leveln" and not h.button:IsShown()
            and not f.more:IsShown(), "nichts offen: " .. tostring(h.title:GetText()))
        assert(f.wayEmpty:IsShown() and not f.track:IsShown(), "leerer Weg ohne Hinweis")
        HM.Fill(f, {})
        assert(h.level:GetText() == "–" and h.title:GetText() == "Willkommen zurück"
            and f.wayEmpty:GetText():find("Stufe", 1, true), "ohne Stufe: " .. tostring(h.level:GetText()))
        -- Quests: Knopf oeffnet die Karte nur ueber questmap (C_Map), im Kampf nicht.
        local QMm = WeintCodex.QuestMap
        local oldOpen, opened = QMm._OpenMap, 0
        QMm._OpenMap = function() opened = opened + 1 return true end
        HM.Go({ go = { map = true } })
        QMm._OpenMap = oldOpen
        assert(opened == 1, "Karte nicht ueber questmap geoeffnet")
        -- Ziel eines Knopfs: Dungeon vorwaehlen, dann die Seite.
        local sel, went
        local oldSel, oldGo = WeintCodex.DungeonPages.Select, nav.GoToTab
        WeintCodex.DungeonPages.Select = function(id) sel = id end
        nav.GoToTab = function(tab) went = tab end
        HM.Go({ go = { tab = "dungeons", dungeon = "hall_of_thanes" } })
        WeintCodex.DungeonPages.Select, nav.GoToTab = oldSel, oldGo
        assert(sel == "hall_of_thanes" and went == "dungeons", "Knopf fuehrt nicht zum Dungeon")
    end)
    Check(ok, "Startseite: drei Schritte nach Dringlichkeit, leere Plaetze kein Mangel, Gold nie geraten, Weg aufsteigend, einmal gebaut"
        .. (ok and "" or (": " .. tostring(err))))
end

-- 6.11.0.4: Profile je Charakter (ui/profiles.lua). Was bis 6.11.0.3 fuer
-- alle galt, zieht nach "Standard"; das Profil einer Sitzung steht bis zum
-- Neuladen fest; "Standard" bleibt immer.
Section("Profile")
do
    local K, PR, O = WeintCodex.UIKit, WeintCodex.UIProfiles, WeintCodex.UIOptions
    local sd = WeintCodex.SavedData
    local savedUI, oldName = sd.ui, _G.UnitName
    local me = "Shooty"
    local reloads, counting = 0, false
    _G.UnitName = function(u) if u == "player" then return me end return oldName(u) end
    local ok, err = pcall(function()
        -- Umzug: alte Ablage -> "Standard", Konto-Werte bleiben, wo sie sind.
        sd.ui = { enabled = true, asked = true, modules = { nameplates = { width = 170 } },
                  positions = { hud_player = { point = "CENTER", x = 1, y = 2 } } }
        K._SetActiveProfile(nil)
        local ui = K.Root()
        assert(ui.modules == nil and ui.positions == nil, "alte Ablage nicht geraeumt")
        assert(ui.profiles.Standard.modules.nameplates.width == 170 and ui.profiles.Standard.positions.hud_player.x == 1,
            "alte Einstellungen nicht nach Standard gezogen")
        assert(ui.enabled == true and ui.asked == true, "Konto-Werte mit umgezogen")
        assert(K.Get("nameplates", "width") == 170 and K.ActiveProfile() == "Standard" and PR.Chosen() == "Standard",
            "Standard nicht aktiv")
        assert(K.CharKey() == "Shooty-Testrealm", "Charakter: " .. tostring(K.CharKey()))
        -- "Standard" gibt es immer, auch wenn die Datei es nicht mehr kennt.
        local keep = sd.ui
        sd.ui = { profiles = { X = {} } }
        assert(K.Root().profiles.Standard and K.Root().profiles.X, "Standard fehlt")
        sd.ui = keep
        -- Ein Wechsel meldet "neu laden" (gezaehlt, der Merker steht laengst).
        reloads, counting = 0, true
        K.Listen(function(kind) if counting and kind == "reload" then reloads = reloads + 1 end end)

        -- Neues Profil: Kopie (tief) des gewaehlten, nach dem Charakter
        -- benannt, gewaehlt - laufen tut bis zum Neuladen das alte.
        local name = PR.New()
        assert(name == "Shooty" and PR.Chosen() == "Shooty" and ui.profileOf["Shooty-Testrealm"] == "Shooty", "Neues Profil")
        assert(ui.profiles.Shooty.modules.nameplates.width == 170
            and ui.profiles.Shooty.modules.nameplates ~= ui.profiles.Standard.modules.nameplates, "keine tiefe Kopie")
        assert(K.ActiveProfile() == "Standard" and PR.Pending() and K.ReloadPending() and reloads == 1,
            "Wechsel mitten in der Sitzung (Neuladen gemeldet: " .. reloads .. ")")
        assert(PR.StatusText():find("Nach dem Neuladen gilt", 1, true), "Hinweis aufs Neuladen fehlt")
        assert(PR.FreeName("Shooty") == "Shooty 2" and PR.FreeName("Neu") == "Neu", "freier Name")
        ui.profiles["Shooty 2"] = {}
        assert(PR.FreeName("Shooty") == "Shooty 3", "freier Name zaehlt nicht weiter")
        ui.profiles["Shooty 2"] = nil

        -- Neue Sitzung als Shooty: Einstellungen landen in seinem Profil.
        K._SetActiveProfile(nil)
        assert(K.ActiveProfile() == "Shooty" and not PR.Pending(), "Shooty nach dem Neuladen")
        K.Set("nameplates", "width", 200)
        assert(K.Get("nameplates", "width") == 200 and ui.profiles.Standard.modules.nameplates.width == 170,
            "Einstellung schreibt ins falsche Profil")
        K.Profile().positions.hud_player = { point = "TOP", x = 9, y = 9 }
        assert(ui.profiles.Standard.positions.hud_player.x == 1, "Platz schreibt ins falsche Profil")
        -- Verschieben mit den Pfeiltasten schreibt ins laufende Profil.
        local mf = CreateFrame("Frame", nil, UIParent)
        K.RegisterMover(mf, "proftest", "Profilprobe", { point = "CENTER", x = 0, y = 0 })
        K.SelectMover("proftest")
        assert(K.NudgeMover(3, 0) and K.Profile().positions.proftest.x == 3
            and ui.profiles.Standard.positions.proftest == nil, "Pfeiltasten schreiben ins falsche Profil")
        K.SelectMover(nil)
        -- Willkommen: eine fruehere Wahl im Profil gilt (Schadensanzeige aus).
        local WL = WeintCodex.UIWelcome
        local dmKey
        for _, sh in ipairs(WL.SHOWS) do if sh.key == "damagemeter" then dmKey = sh.key end end
        if dmKey then
            K.Profile().modules.damagemeter = { enabled = false }
            WL.choice.picked = nil
            WL.Decide(true)
            assert(WL.choice.shows.damagemeter == false, "Willkommen liest die Wahl nicht aus dem Profil")
            K.Profile().modules.damagemeter = nil
            WL.choice.picked = nil
        end

        -- Zweiter Charakter: ohne Wahl "Standard", waehlt dann Shooty mit.
        me = "Twink"
        assert(PR.Chosen() == "Standard", "neuer Charakter nicht bei Standard")
        assert(PR.Choose("Shooty") and table.concat(PR.Users("Shooty"), ",") == "Shooty,Twink", "geteiltes Profil")
        assert(PR.Choose("Standard") and ui.profileOf["Twink-Testrealm"] == nil, "Standard braucht keinen Eintrag")
        PR.Choose("Shooty")
        assert(PR.StatusText():find("Shooty, Twink", 1, true), "Status nennt die Nutzer nicht: " .. PR.StatusText())
        me = "Shooty"

        -- Umbenennen: Eintraege und laufendes Profil ziehen mit; ungueltig
        -- aendert nichts.
        assert(PR.Rename("Shooty", "Jäger") and ui.profiles["Jäger"] and not ui.profiles.Shooty, "Umbenennen")
        assert(ui.profileOf["Shooty-Testrealm"] == "Jäger" and ui.profileOf["Twink-Testrealm"] == "Jäger"
            and K.ActiveProfile() == "Jäger" and K.Get("nameplates", "width") == 200, "Umbenennen verliert Zuordnung")
        assert(not PR.Rename("Jäger", "Standard") and not PR.Rename("Jäger", "  ") and not PR.Rename("Standard", "X")
            and not PR.Rename("Jäger", string.rep("x", PR.MAX_NAME + 1)), "ungueltiger Name angenommen")
        assert(PR.Rename("Jäger", " Jägerin ") and ui.profiles["Jägerin"], "Leerzeichen am Rand nicht entfernt")
        PR.Rename("Jägerin", "Jäger")
        -- Das laufende umbenennen, waehrend ein anderes gewaehlt ist: die
        -- Sitzung bleibt bei ihm.
        PR.Choose("Standard")
        assert(PR.Rename("Jäger", "Jagd") and K.ActiveProfile() == "Jagd" and K.Get("nameplates", "width") == 200,
            "laufendes Profil nach dem Umbenennen verloren: " .. tostring(K.ActiveProfile()))
        PR.Rename("Jagd", "Jäger")
        PR.Choose("Jäger")

        -- Uebernehmen und Zuruecksetzen: in das gewaehlte, tief kopiert.
        assert(PR.CopyFrom("Standard") and K.Get("nameplates", "width") == 170, "Uebernehmen")
        assert(ui.profiles["Jäger"].modules ~= ui.profiles.Standard.modules, "Uebernehmen teilt Tabellen")
        assert(not PR.CopyFrom("Jäger") and not PR.CopyFrom("Gibtsnicht"), "Uebernehmen von sich selbst")
        assert(PR.Reset() and K.Get("nameplates", "width") == 150 and next(K.Profile().positions) == nil, "Zuruecksetzen")
        assert(ui.profiles.Standard.modules.nameplates.width == 170, "Zuruecksetzen trifft Standard")

        -- Loeschen: nie Standard, das laufende oder das gewaehlte; wer es
        -- nutzte, landet bei Standard.
        assert(not PR.Deletable("Standard") and not PR.Deletable("Jäger"), "Laufendes/Standard loeschbar")
        PR.New("Neu")
        assert(PR.Chosen() == "Neu" and not PR.Deletable("Neu") and not PR.Deletable("Jäger"), "gewaehltes loeschbar")
        PR.Choose("Jäger")
        ui.profileOf["Twink-Testrealm"] = "Neu"
        assert(PR.Delete("Neu") and not ui.profiles.Neu and ui.profileOf["Twink-Testrealm"] == nil, "Loeschen")
        me = "Twink"
        assert(PR.Chosen() == "Standard", "nach dem Loeschen nicht bei Standard")
        me = "Shooty"
        local list = PR.List()
        assert(list[1] == "Standard" and list[2] == "Jäger" and #list == 2, "Liste: " .. table.concat(list, ","))

        -- Ohne Charakternamen: keine Wahl, aber Standard laeuft.
        me = nil
        assert(not PR.Choose("Jäger") and K.ChosenProfile() == "Standard", "Wahl ohne Charakter")
        me = "Shooty"

        -- Die Seite und der Befehl.
        local idx = O.PageIndex("general", "profile")
        assert(idx > 1 and K.Module("general").pages[idx].key == "profile", "Seite Profile fehlt")
        SlashCmdList["WEINTCODEXUI"]("profil")
        local widgets = O.CurrentWidgets()
        assert(#widgets >= 6, "Seite Profile: " .. #widgets .. " Bedienelemente")
        local status
        for _, w in ipairs(widgets) do if w.isProfileStatus == true then status = w.text:GetText() end end
        assert(status and status:find("„Jäger“ nutzen", 1, true), "Statuszeile: " .. tostring(status))

        -- 6.12.0.1: beim Einloggen fragen - einmal je Charakter ohne Wahl,
        -- nur mit Oberflaeche, nie vor dem Willkommen, nicht neben dem
        -- Hinweis auf ein Update.
        local oldEnabled, oldAsked = ui.enabled, ui.asked
        ui.enabled, ui.asked = true, true
        me = "Neuling"
        PR.ResetLater()
        assert(not PR.Answered() and PR.ShouldAsk(), "Neuling wird nicht gefragt")
        ui.asked = nil
        assert(not PR.ShouldAsk(), "Frage vor dem Willkommen")
        ui.asked, ui.enabled = true, false
        assert(not PR.ShouldAsk(), "Frage ohne Oberflaeche")
        ui.enabled = true
        local OB = WeintCodex.Onboarding
        local oldShowing = OB.IsShowing
        OB.IsShowing = function() return true end
        assert(not PR.ShouldAsk(), "Frage neben dem Hinweis auf ein Update")
        OB.IsShowing = oldShowing
        local WLm = WeintCodex.UIWelcome
        local oldWShown, oldBlocks = WLm.IsShown, WLm.ReloadBlocks
        WLm.IsShown = function() return true end
        assert(not PR.ShouldAsk(), "Frage neben dem Willkommen")
        WLm.IsShown = oldWShown
        WLm.ReloadBlocks = function() return true end
        assert(not PR.ShouldAsk(), "Frage nach /reload, obwohl der Client nicht speichert")
        WLm.ReloadBlocks = oldBlocks
        assert(PR.MaybeAsk(), "MaybeAsk fragt nicht")
        local a = PR.AskFrame()
        assert(a and a:IsShown() and a.state == "frage" and a.title:GetText():find("Neuling", 1, true)
            and a.create:IsShown() and a.keep:IsShown() and a.pick:IsShown() and not a.reload:IsShown(),
            "Dialog: " .. tostring(a and a.title:GetText()))
        assert(not PR.ShouldAsk(), "doppelt gefragt")
        -- "Standard behalten": Antwort, nie wieder.
        PR.AskKeep()
        assert(not a:IsShown() and PR.Answered() and not PR.ShouldAsk() and PR.Chosen() == "Standard",
            "Standard behalten")
        -- Esc / "×": Spaeter - bis zum naechsten Einloggen.
        me = "Zweiter"
        PR.ShowAsk("frage")
        a.close:Click()
        assert(not a:IsShown() and not PR.Answered() and not PR.ShouldAsk(), "Spaeter fragt sofort wieder")
        stub.FireEvent("PLAYER_ENTERING_WORLD", true, false)
        assert(PR.ShouldAsk(), "Spaeter endet nicht mit dem Einloggen")
        stub.FireEvent("PLAYER_ENTERING_WORLD", false, true)
        -- "Eigenes Profil anlegen": angelegt, gewaehlt, Knopf zum Neuladen.
        PR.MaybeAsk()
        local made = PR.AskCreate()
        assert(made == "Zweiter" and PR.Chosen() == "Zweiter" and PR.Answered() and a:IsShown()
            and a.state == "angelegt" and a.reload:IsShown() and a.later:IsShown() and not a.create:IsShown(),
            "Anlegen aus dem Dialog")
        assert(a.body:GetText():find("bis dahin läuft", 1, true), "Hinweis aufs Neuladen fehlt")
        a.later:Click()
        assert(not a:IsShown(), "Spaeter schliesst nicht")
        -- Wer schon gewaehlt hat, wird nie gefragt.
        me = "Shooty"
        assert(PR.Answered(), "Charakter mit Profil gefragt")
        -- "Profil waehlen": nur bei mehr als Standard; oeffnet die Seite.
        me = "Dritter"
        PR.ShowAsk("frage")
        PR.AskPick()
        assert(not a:IsShown() and PR.Answered() and O.CurrentWidgets()[1] ~= nil, "Profil waehlen")
        local keepProfiles = ui.profiles
        ui.profiles = { Standard = {} }
        me = "Vierter"
        PR.ShowAsk("frage")
        assert(not a.pick:IsShown() and a.keep:IsShown(), "Waehlen ohne Auswahl")
        a.decided = true
        a:Hide()
        ui.profiles = keepProfiles
        me = "Shooty"
        ui.enabled, ui.asked = oldEnabled, oldAsked
    end)
    counting = false
    sd.ui, _G.UnitName = savedUI, oldName
    K._SetActiveProfile(nil)
    Check(ok, "Profile: Umzug nach Standard, je Charakter gewaehlt, fest bis zum Neuladen, Kopie, Umbenennen, Uebernehmen, Zuruecksetzen, Loeschen"
        .. (ok and "" or (": " .. tostring(err))))
end

-- 6.13.0.0: Die Spalte als Informationsarchitektur. Vier Gruppen, je
-- eine Frage; Import ist ein Reiter unter Companion, die ID bleibt.
Section("Navigation")
do
    local nav = WeintCodex.Navigation
    local ok, err = pcall(function()
        local want = {
            { "uebersicht", "Leveln" }, { "charakter" }, { "lehrer" }, { "berufe" }, { "dungeons" },
            { "gruppe", "Gruppe" }, { "raids" }, { "anmeldung" }, { "kalender" },
            { "materialien", "Gilde" },
            { "companion", "System" }, { "settings" },
        }
        local tabs = nav.Tabs()
        assert(#tabs == #want, "Eintraege: " .. #tabs)
        for i, w in ipairs(want) do
            assert(tabs[i].id == w[1] and tabs[i].group == w[2],
                "Spalte, Platz " .. i .. ": " .. tostring(tabs[i].id) .. " / " .. tostring(tabs[i].group))
        end
        -- Freigaben unveraendert, Import ohne Eintrag und ohne Sperre.
        local feat = nav.GetTabFeatures()
        assert(feat.anmeldung == "raids.view" and feat.kalender == "calendar.view"
            and feat.materialien == "materials.view" and feat.import == nil and feat.companion == nil,
            "Freigaben veraendert")
        assert(nav.SUBTABS.import and nav.SUBTABS.import.tab == "companion", "Import ohne Platz")

        -- Jeder Bereich ist erreichbar - aus der Spalte, und jeder Treffer
        -- der Suche landet in der Spalte auf seinem Eintrag.
        for _, t in ipairs(tabs) do
            WeintCodex.ResetToHome()
            nav.GoToTab(t.id)
            assert(nav.CurrentTab() == t.id, t.id .. " nicht erreichbar: " .. tostring(nav.CurrentTab()))
        end
        for _, page in ipairs(WeintCodex.Search.PAGES) do
            WeintCodex.ResetToHome()
            if page.id ~= "uebersicht" then nav.GoToTab("settings") end
            nav.GoToTab(page.id)
            local host = nav.SUBTABS[page.id] and nav.SUBTABS[page.id].tab or page.id
            assert(nav.CurrentTab() == host, "Suche: " .. page.id .. " -> " .. tostring(nav.CurrentTab()))
        end

        -- Import: Companion markiert, Reiter Import offen - auch wenn
        -- Companion schon offen war; Brotkrume und Detail bei jedem Mal.
        local CPG = WeintCodex.CompanionPage
        local crumbs = {}
        local oldCrumb = WeintCodex.SetBreadcrumb
        WeintCodex.SetBreadcrumb = function(...) crumbs[#crumbs + 1] = table.concat({ ... }, "/") end
        WeintCodex.ResetToHome()
        nav.GoToTab("companion")
        assert(nav.CurrentTab() == "companion" and CPG.current == "sync", "Companion: erster Reiter")
        nav.GoToTab("import")
        assert(nav.CurrentTab() == "companion" and CPG.current == "import", "Import aus Companion heraus")
        nav.ActivateIndex(1)
        assert(CPG.current == "sync", "zurueck zur Synchronisierung")
        nav.ActivateIndex(2)
        WeintCodex.SetBreadcrumb = oldCrumb
        local imports = 0
        for _, c in ipairs(crumbs) do if c == "Companion/Import" then imports = imports + 1 end end
        assert(imports >= 2, "Brotkrume beim zweiten Oeffnen von Import nicht gesetzt (" .. imports .. ")")

        -- Slash-Befehle: wie gehabt, /wc import landet auf dem Reiter.
        local slash = SlashCmdList["WEINTCODEX"]
        local cases = {
            { "import", "companion" }, { "companion", "companion" }, { "einstellungen", "settings" },
            { "dungeons", "dungeons" }, { "raids", "raids" }, { "anmeldung", "anmeldung" },
            { "kalender", "kalender" }, { "charakter", "charakter" }, { "materialien", "materialien" },
            { "lehrer", "lehrer" }, { "gruppe", "gruppe" },
        }
        for _, c in ipairs(cases) do
            WeintCodex.ResetToHome()
            slash(c[1])
            assert(nav.CurrentTab() == c[2], "/wc " .. c[1] .. " -> " .. tostring(nav.CurrentTab()))
        end
        WeintCodex.ResetToHome()
        slash("import")
        assert(CPG.current == "import", "/wc import schlaegt den Reiter nicht auf")

        -- Sperre unveraendert: ohne Freigabe zeigt Materialien die
        -- Sperrseite, Import bleibt offen.
        local A = WeintCodex.Access
        local realCan = A.Can
        local locked
        local oldLock = nav.ShowAccessLock
        nav.ShowAccessLock = function(id) locked = id end
        A.Can = function(key) return key ~= "materials.view" end
        WeintCodex.ResetToHome()
        nav.GoToTab("materialien")
        local matLocked = locked
        locked = nil
        nav.GoToTab("import")
        A.Can, nav.ShowAccessLock = realCan, oldLock
        assert(matLocked == "materialien" and locked == nil and CPG.current == "import", "Sperre veraendert")

        -- Minikarte, Rechtsklick: Schlachtzuege, in der Spalte markiert.
        local mm = io.open(ROOT .. "/core/minimap.lua"):read("*a")
        assert(not mm:find("SwitchTo(\"raids\")", 1, true) and mm:find('GoToTab("raids")', 1, true),
            "Minikarte oeffnet Schlachtzuege ohne Markierung")
        WeintCodex.ResetToHome()
    end)
    Check(ok, "Navigation: Leveln/Gruppe/Gilde/System, Import unter Companion, alles erreichbar, Befehle, Suche, Sperre"
        .. (ok and "" or (": " .. tostring(err))))
end

--------------------------------------------------

print("")
if failures == 0 then
    print("BESTANDEN")
    os.exit(0)
end

print(failures .. " Pruefung(en) fehlgeschlagen.")
os.exit(1)
