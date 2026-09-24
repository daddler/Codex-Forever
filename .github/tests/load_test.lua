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

-- Ausgeschaltet heisst ausgeschaltet: nach dem Anmelden laeuft kein
-- ui-Modul, solange der Hauptschalter aus ist.
Check(K.UIEnabled() == false, "Hauptschalter steht nach dem ersten Laden auf aus")
Check(not K.IsActive("nameplates") and not K.IsActive("unitframes"),
    "ohne Hauptschalter laeuft weder Plakette noch Einheitenrahmen")
Check(K.IsActive("questarrow"), "der Questpfeil laeuft auch ohne Hauptschalter")

-- Gespeichert wird in DER Tabelle aus der .toc, und nur die Abweichung.
K.Set("nameplates", "width", 180)
Check(WeintCodex_SavedData.ui.modules.nameplates.width == 180,
    "eine Einstellung landet in WeintCodex_SavedData.ui")
K.Set("nameplates", "width", 140)
Check(WeintCodex_SavedData.ui.modules.nameplates.width == nil,
    "der Standardwert wird nicht gespeichert")

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

-- Einschalten wie ein Spieler: Hauptschalter an, dann so tun, als sei
-- neu geladen (die Module starten beim Anmelden).
K.SetUIEnabled(true)
Check(K.ReloadPending(), "der Hauptschalter verlangt ein Neuladen")
Check(K.WantsActive("nameplates") and K.WantsActive("unitframes"),
    "nach dem Neuladen liefen Plaketten und Einheitenrahmen")

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
end

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
