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

-- SEIT 6.0.0.3: DIE OBERFLAECHE IST FUER ALLE AN (UIKit.OPT_IN = false),
-- weil der Forever-Beta-Client keine Einstellungen speichert. Nach dem
-- Anmelden laeuft deshalb jedes ui-Modul - und zwar gegen die Attrappe,
-- ohne einen einzigen Fehler (K.Report meldete ihn im Chat, und
-- K.IsActive bliebe false).
Check(K.OPT_IN == false, "Hauptschalter ausgesetzt (OPT_IN = false) - bis der Client speichert")
Check(K.UIEnabled() == true, "ohne OPT_IN ist die Oberflaeche an")
for _, key in ipairs({ "nameplates", "unitframes", "groupframes", "actionbars",
    "minimap", "chat", "bags", "damagemeter", "questarrow", "comfort" }) do
    Check(K.IsActive(key), "Modul '" .. key .. "' laeuft nach dem Anmelden")
end

-- Gespeichert wird in DER Tabelle aus der .toc, und nur die Abweichung.
K.Set("nameplates", "width", 180)
Check(WeintCodex_SavedData.ui.modules.nameplates.width == 180,
    "eine Einstellung landet in WeintCodex_SavedData.ui")
K.Set("nameplates", "width", 150)
Check(WeintCodex_SavedData.ui.modules.nameplates.width == nil,
    "der Standardwert wird nicht gespeichert")
-- Die Falle aus 6.0.0.0 bis 6.0.0.2: `x and false or nil` ist nil. Ein
-- Schalter, der von "an" auf "aus" geht, muss als false im Speicher
-- stehen - sonst laesst sich keine eingeschaltete Option abschalten.
K.Set("nameplates", "hover", false)
Check(WeintCodex_SavedData.ui.modules.nameplates.hover == false
    and K.Get("nameplates", "hover") == false,
    "ein Schalter laesst sich von an auf aus stellen (false wird gespeichert)")
K.Set("nameplates", "hover", true)
Check(WeintCodex_SavedData.ui.modules.nameplates.hover == nil,
    "zurueck auf den Standard: der Eintrag verschwindet")

-- Jede Seite jedes Moduls bauen.
for _, key in ipairs(K.order) do
    local m = K.Module(key)
    for i, page in ipairs(m.pages) do
        local ok, err = pcall(UO.Show, key, i)
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

-- AB HIER BIS ZUM "EINSCHALTEN WIE EIN SPIELER" MIT OPT_IN = true: die
-- Frage beim Einloggen ruht, bleibt aber geprueft - sie muss mit einer
-- einzigen Zeile in ui/kit.lua zurueckkommen koennen.
do
    local WL = WeintCodex.UIWelcome
    local sd = WeintCodex.SavedData
    sd.ui.asked = nil
    WL.MaybeAsk()
    Check(not WL.IsShown(), "ohne OPT_IN fragt WeintCodex nie, auch nicht ungefragt")
    K.OPT_IN = true
    Check(K.UIEnabled() == false, "mit OPT_IN liest der Hauptschalter wieder den Speicher (aus)")
end

-- Die Frage beim Einloggen. Sie darf nicht UEBER der Einfuehrung
-- erscheinen (die steht im Prueflauf seit PLAYER_LOGIN da, weil der
-- Speicher frisch ist), sondern erst, wenn diese weg ist - und beide
-- Antworten muessen tun, was sie sagen.
do
    local WL = WeintCodex.UIWelcome
    local ok, err = pcall(function()
        assert(WeintCodex.Onboarding.IsShowing(), "Einfuehrung steht nicht (Voraussetzung)")
        WL.MaybeAsk()
        assert(not WL.IsShown(), "Frage erscheint ueber der Einfuehrung")

        -- Einfuehrung wegklicken: jetzt kommt die Frage.
        WeintCodex.Onboarding.Dismiss()
        assert(WL.IsShown(), "nach der Einfuehrung kommt keine Frage")

        -- "Nein": nichts eingeschaltet, Hinweis auf die Einstellungen, nie wieder fragen.
        WL.Button("no"):Click()
        assert(not K.UIEnabled(), "Nein hat die Oberflaeche eingeschaltet")
        assert(WeintCodex_SavedData.ui.asked == true, "Nein wird nicht gemerkt")
        assert(WL.BodyText():find("Einstellungen", 1, true)
            and WL.BodyText():find("/wcui", 1, true),
            "Nein nennt nicht, wo man es spaeter einschaltet")
        WL.Button("settings"):Click()
        assert(not WL.IsShown(), "Einstellungen oeffnen schliesst die Frage nicht")
        assert((WeintCodex.Breadcrumb:GetText() or ""):find(
            WeintCodex.Spaced(WeintCodex.Upper("Oberfläche")), 1, true),
            "Einstellungen oeffnen landet nicht auf der Ansicht Oberflaeche")
        WL.MaybeAsk()
        assert(not WL.IsShown(), "nach Nein wird erneut gefragt")

        -- "Ja": Hauptschalter an, Neuladen wird angeboten.
        WL.Ask()
        WL.Button("yes"):Click()
        assert(K.UIEnabled(), "Ja schaltet die Oberflaeche nicht ein")
        assert(WL.Button("reload") and WL.Button("later"), "Ja bietet kein Neuladen an")
        WL.Button("later"):Click()
        assert(not WL.IsShown(), "Spaeter schliesst die Frage nicht")

        -- Zurueck auf den Ausgangszustand fuer die Pruefungen darunter.
        K.SetUIEnabled(false)
    end)
    Check(ok, "Frage beim Einloggen: erst nach der Einfuehrung, Nein und Ja tun, was sie sagen"
        .. (ok and "" or (": " .. tostring(err))))
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

        sd.ui.asked = nil
        WL.MaybeAsk()
        assert(not WL.IsShown(), "nach /reload wird wieder gefragt (die Schleife)")

        sd.saveProbe = time() - 3600
        stub.FireEvent("PLAYER_ENTERING_WORLD", false, true)
        assert(WeintCodex.SaveHealth() == "failed", "veralteter Stempel nach /reload nicht erkannt")

        sd.saveProbe = time() - 5
        stub.FireEvent("PLAYER_ENTERING_WORLD", false, true)
        assert(WeintCodex.SaveHealth() == "ok", "frischer Stempel nicht als gespeichert erkannt")

        sd.saveProbe = nil
        stub.FireEvent("PLAYER_LOGOUT")
        assert(type(sd.saveProbe) == "number", "PLAYER_LOGOUT setzt keinen Stempel")

        -- Echtes Einloggen: dann darf (und soll) wieder gefragt werden.
        stub.FireEvent("PLAYER_ENTERING_WORLD", true, false)
        assert(not WL.IsReloadSession(), "Einloggen als Neuladen gewertet")
        WL.MaybeAsk()
        assert(WL.IsShown(), "beim Einloggen wird nicht gefragt, obwohl die Antwort fehlt")
        WL.Button("no"):Click()
        WL.Button("ok"):Click()
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
    local offenders = {}
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
                end
            end
            pipe:close()
        end
    end
    Check(#offenders == 0, "kein direkter Aufruf von ReloadUI/C_UI.Reload"
        .. (#offenders == 0 and "" or (": " .. table.concat(offenders, ", "))))

    local blocked = 0
    _G.ReloadUI = function() blocked = blocked + 1 end
    _G.C_UI = { Reload = function() blocked = blocked + 1 end }
    local WL = WeintCodex.UIWelcome
    local ok, err = pcall(function()
        WL.Ask()
        WL.Button("yes"):Click()
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

-- Mit OPT_IN: der Hauptschalter verlangt ein Neuladen und schaltet die
-- ui-Module fuer das naechste Laden ein. Danach zurueck auf den Stand der
-- Fassung (OPT_IN = false).
K.SetUIEnabled(true)
Check(K.ReloadPending(), "mit OPT_IN verlangt der Hauptschalter ein Neuladen")
Check(K.WantsActive("nameplates") and K.WantsActive("unitframes"),
    "nach dem Neuladen liefen Plaketten und Einheitenrahmen")
K.SetUIEnabled(false)
K.OPT_IN = false
Check(K.UIEnabled() and K.WantsActive("groupframes"), "OPT_IN zurueck auf false: wieder alles an")

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
        QA.Replan()
        assert(calls == 1, "Karte je Quest neu abgefragt: " .. calls)
        QA.Update(true)
        assert(QA.texts.dist:GetText() == "80 m", "Pfeil zeigt nicht auf das geplante Ziel: " .. tostring(QA.texts.dist:GetText()))
        -- Nicht hin und her: 13 taucht 70 m entfernt auf - kaum naeher, 9 bleibt.
        table.insert(log, { questID = 13, level = 10 })
        where[13] = { 0.5, 0.43 }
        QA.Replan()
        assert(QA.Chosen == 9, "springt wegen 10 m zu einem anderen Ziel")
        -- Deutlich naeher (20 m): jetzt wechselt er.
        where[13] = { 0.5, 0.48 }
        QA.Replan()
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
        stub.FireEvent("QUEST_LOG_UPDATE")
        assert(p.quest:GetText() == "9/10", "nach Questlog-Aenderung nicht neu gelesen")
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
        assert(chatReset == 1 and r.chat, "Chatfenster nicht zurueckgesetzt")
        assert(cvars.chatStyle == "im" and cvars.whisperMode == "inline" and cvars.lockActionBars == "1", "Spieleinstellungen nicht gesetzt")
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
        assert(ES.BodyText():find("Chatfenster", 1, true), "Frage nennt den Chat nicht")
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
    Check(ok, "Einrichtung: alle Rahmen des Spiels fest auf der Vorlage, Chat, Spieleinstellungen, danach neu laden"
        .. (ok and "" or (": " .. tostring(err))))
end

-- 6.6.0.7: Klickzauber - Maustaste + Zusatztaste wirkt einen Zauber auf
-- die Einheit des Rahmens. Nur Klick-Attribute, je Klasse gespeichert.
do
    local ok, err = pcall(function()
        local CC = WeintCodex.UIClickCast
        assert(CC, "ui/clickcast.lua nicht geladen")
        local gm = K.Module("groupframes")
        local page = false
        for _, pg in ipairs(gm.pages) do if pg.key == "klickzauber" then page = true end end
        assert(page, "kein Reiter Klickzauber an den Gruppenrahmen")
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
        assert(#R.Suggestions("HUNTER") == 2 and R.Suggestions("HUNTER")[1].kind == "pet"
            and R.Suggestions("HUNTER")[2].kind == "ammo", "Jaeger ohne Begleiter- und Munitions-Vorschlag")
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
        R.SetRules({ { kind = "buff", spell = "Kampfschrei" }, { kind = "weapon", hand = "main", class = R.ALL }, { kind = "pet" },
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
        local DP = WeintCodex.DungeonPages
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
        DP.Select("maraudon", nil)
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
        assert(DP.mapLinks == 5, "Kartenlinks in The Deadmines: " .. tostring(DP.mapLinks) .. " statt 5")
        -- 6.5.1.1: jede Quest in ihrer Kachel (sieben in The Deadmines).
        assert(DP.questTiles == #J.Quests("the_deadmines", nil) or DP.questTiles == #J.Quests("the_deadmines", "alliance"),
            "Questkacheln: " .. tostring(DP.questTiles))
        assert(DP.questTiles > 0, "keine Questkachel")
        DP.Select("hall_of_thanes", nil)
        WeintCodex.Navigation.SwitchTo("dungeons")
        assert(DP.mapLinks == 1, "Fundort der Dark Iron Map ohne Link")

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
        -- 6.6.2.1: die Startseite fragt den Lehrer und die Dungeons.
        local nav0 = WeintCodex.Navigation
        local home = nav0.HomeTrainer()
        assert(home and #home.cat.sections.now > 0 and home.budget and home.budget.money == 150,
            "Startseite kennt den Lehrer nicht")
        local fit = nav0.HomeDungeons(15)
        local hot = false
        for _, d in ipairs(fit) do if d.id == "hall_of_thanes" then hot = true end end
        assert(hot, "Hall of Thanes (13-18) passt nicht zu Stufe 15")
        local none, nextUp = nav0.HomeDungeons(1)
        assert(#none == 0 and nextUp and nextUp.minLevel > 1, "ohne passenden Dungeon kein naechster")
        assert(#nav0.HomeDungeons(nil) == 0, "ohne Stufe trotzdem Dungeons empfohlen")
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
        assert(rep:find("Gilde & Communitys (Stil ruhig): Liste Fläche · Chat Fläche · Mitglieder Fläche", 1, true), "Bericht: " .. rep)
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
        assert(rep:find("Questlog (Stil ruhig): Spalte auf Fläche · Karte unberührt", 1, true), "Bericht: " .. rep)
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
        W.done[map] = nil
        _G.WorldMapFrame, _G.QuestScrollFrame = oldWM, oldQSF
    end)
    Check(okQ, "Karte & Questlog: Gold, Questlog auf Flaeche, Zonen als Abschnitte, weicher Rand der Karte bleibt"
        .. (okQ and "" or (": " .. tostring(errQ))))

    -- 6.8.0.0: Suche nach Gruppe in Gold - Schein der Klasse aus, die
    -- Innenflaechen (W.Insets, nicht ueber Namen) mit Schatten und Kante in
    -- Gold, aus mit ihrer Flaeche.
    local okL, errL = pcall(function()
        local W, S, LF = WeintCodex.UIWindows, WeintCodex.UIStyle, WeintCodex.UILFG
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

--------------------------------------------------

print("")
if failures == 0 then
    print("BESTANDEN")
    os.exit(0)
end

print(failures .. " Pruefung(en) fehlgeschlagen.")
os.exit(1)
