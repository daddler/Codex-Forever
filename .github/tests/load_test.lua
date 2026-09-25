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
        tostring = true, select = true, unpack = true, wipe = true, assert = true,
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
        assert(btn._reloadOverlay._armed, "Makroknopf nicht scharf")
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
    Check(picked == 9, "abgegeben: der Pfeil waehlt die naechste Quest (" .. tostring(picked) .. ")")

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

-- Aktionsleisten, Minikarte, Chat.
do
    local ok, err = pcall(function()
        local b = CreateFrame("CheckButton", "ActionButton1", UIParent)
        b.icon = b:CreateTexture()
        b.HotKey = b:CreateFontString()
        b.Count = b:CreateFontString()
        b.Name = b:CreateFontString()
        WeintCodex.UIActionBars.SkinAll()
        assert(WeintCodex.UIActionBars.skinned[b], "Knopf nicht umgestaltet")
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
        local base = #WeintCodex.UIMinimap.ColumnButtons()
        assert(_G.LibDBIcon10_WeintCodex == nil or base == 1, "der eigene Knopf gehoert in die Spalte")
        _G.MinimapCluster.Tracking = CreateFrame("Frame", nil, _G.MinimapCluster)
        _G.GameTimeFrame = CreateFrame("Button", "GameTimeFrame", _G.MinimapCluster)
        local list = WeintCodex.UIMinimap.ColumnButtons()
        assert(#list == base + 2, "Knopfspalte: " .. #list .. " statt " .. (base + 2) .. " Knoepfe")
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

        -- Plakette: die Debuff-Symbole des Spiels haengen an unserer Plakette.
        local af = stub.NewObject("Frame")
        af._parent = blizzPlate.UnitFrame
        blizzPlate.UnitFrame.AurasFrame = af
        stub.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate1")
        local p = NP.plates["nameplate1"]
        assert(af:GetParent() == p, "Symbole des Spiels nicht an der Plakette")
        K.Set("nameplates", "auraSource", "own")
        assert(af:GetParent() ~= p, "eigene Symbole gewaehlt, die des Spiels haengen noch dran")
        K.Set("nameplates", "auraSource", "game")
        assert(af:GetParent() == p, "zurueck auf die des Spiels greift nicht")
        stub.FireEvent("NAME_PLATE_UNIT_REMOVED", "nameplate1")
        assert(af:GetParent() == blizzPlate.UnitFrame, "Symbole nicht an die Plakette des Spiels zurueckgegeben")
        blizzPlate.UnitFrame.AurasFrame = nil

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
        WeintCodex.UIActionBars.SkinAll()
        assert(b:GetAlpha() == 0, "leerer Platz sichtbar")
        stub.FireEvent("ACTIONBAR_SHOWGRID")
        assert(b:GetAlpha() == 1, "beim Ziehen bleibt der Platz unsichtbar")
        stub.FireEvent("ACTIONBAR_HIDEGRID")
        assert(b:GetAlpha() == 0, "nach dem Ziehen nicht wieder weg")
        _G.HasAction = function() return true end
        WeintCodex.UIActionBars.SkinAll()
        assert(b:GetAlpha() == 1, "belegter Platz unsichtbar")
        _G.HasAction = oldHas
        _G.ActionButton2 = nil
    end)
    Check(ok, "Aktionsleisten: leere Plaetze aus, beim Ziehen sichtbar" .. (ok and "" or (": " .. tostring(err))))
end

-- Die Seitenleiste des Einstellungsfensters traegt jetzt elf Eintraege.
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
