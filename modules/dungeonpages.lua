--------------------------------------------------
-- WeintCodex :: Dungeons
--
-- NEUNUNDZWANZIG INSTANZEN, DREI EBENEN, EINE SEITE.
--
-- Die Seite kennt zwei Zustaende und drei Ebenen. Die Ebenen stehen
-- immer in derselben Reihenfolge, und keine davon ist dekorativ:
--
--   1. DIE KOPFKARTE. Eine eigene Flaeche, die den Dungeon
--      aufschlaegt: Kennzeichnung (Classic oder Forever), der Name
--      in der Serife, der Themensatz in der ruhigen Kursiven, eine
--      Haarlinie - und darunter das TATSACHENBAND, in dem jede
--      Auskunft eine eigene Spalte hat (Wert oben, Rubrik darunter:
--      Gebiet, Stufen, Spieler, Bosse und, wenn der Client eine
--      Stufe nennt, ob sie passt). Bis 5.2.0.4 waren das vier
--      verstreute Flaechen, bis 5.2.0.5 eine umbrechende Satzzeile;
--      seit 5.2.0.6 eine Flaeche und ein Band, das man ueberfliegt
--      statt es zu lesen. Wie viele Spalten in eine Zeile des
--      Bandes passen, ist gerechnet wie die Spaltenzahl des
--      Bossrasters.
--   2. DIE BOSSE, als Raster aus Karten - nicht mehr als Kette aus
--      Pillen. Eine Pillenzeile liest sich wie eine zweite
--      Navigation; eine Karte mit Nummer, Namen und Kennzeichen
--      liest sich wie das, was sie ist: der Inhalt des Dungeons.
--      Wie viele Spalten das Raster bekommt, entscheidet die
--      WIRKLICHE Breite und der laengste Name der gezeigten Liste
--      (GridLayout) - drei, wo sie passen, sonst zwei, sonst eine.
--      Grosse Instanzen zeigen ihre Fluegel als Reiter darueber,
--      einen Fluegel zur Zeit, so verliert kein Fluegel einen Boss.
--   3. DIE KONTEXTKARTE, nachrangig und nie leer. Ohne Boss traegt
--      sie ZWEI Spalten nebeneinander - BESONDERHEITEN (Fluegel,
--      beschwoerbare Bosse, optionale Bosse, unbekannte Reihenfolge,
--      unvollstaendige Liste, Classic-Herkunft: alles abgeleitet,
--      nichts erfunden) und AUFSTELLUNG (Rollen, Plaetze, Baeume) -
--      und darunter, wo die Seite in voller Breite steht und der
--      Detailbereich rechts also fehlt, die Herkunft der Bossliste
--      als schmale Fusszeile. Mit Boss traegt sie ihn: der Name in
--      der Serife, die Notiz als Aufschlag in der Kursiven, dann wo
--      er steht, wie er kommt, was die Rollen tun, mit einem Weg
--      zurueck zur Uebersicht im Kartenkopf. Sie ist die eine
--      Flaeche, die rollen darf - was der Bot je Rolle schickt,
--      weiss niemand vorher, und gekuerzt wird hier nichts.
--
-- ZWEI ZUSTAENDE, EINE STRUKTUR. Ein Klick auf eine Bosskarte
-- ersetzt die Uebersicht NICHT: das Raster bleibt stehen, die
-- angeklickte Karte traegt den Akzentbalken, und die Kontextkarte
-- darunter wechselt ihren Inhalt. Wer wissen will, wo er ist, muss
-- dafuer nichts zuklappen.
--
-- WAS ES HIER NICHT MEHR GIBT: den Wegweiser "Ein Klick auf einen
-- Boss zeigt ihn hier". Er stand im Kopf einer Karte, die ohne Boss
-- nichts anderes zu sagen hatte, und beschrieb damit vor allem ihre
-- eigene Leere. Eine Karte, die Aufstellung UND Herkunft traegt,
-- braucht keine Bedienungsanleitung.
--
-- Die Spalte links fuehrt nur Dungeons, nach Stufenabschnitt.
--
-- DER DETAILBEREICH RECHTS bleibt, was er seit 5.2.0.3 ist: derselbe
-- Kontextbereich wie auf der Schlachtzugseite (Kennzahlen, Herkunft
-- der Bossliste) - aber NICHT bedingungslos. Er braucht 420 px, die
-- dem Raster fehlen. Die Seite zeichnet sich zuerst mit Bereich,
-- misst sich selbst gegen ihr eigenes Budget und faellt bei
-- Ueberlauf auf die volle Breite ohne Bereich zurueck (siehe
-- DrawDungeon/DrawDungeonAt). Welche Dungeons das trifft, steht
-- nirgends als Name im Code - es ist eine Folge des Bestands.
--
-- DASS SICH DAS WIE DIE SCHLACHTZUGSEITE ANFUEHLT, IST DER PUNKT,
-- und es ist keine Behauptung, sondern dieselben Bausteine:
-- derselbe Seitenkopf (WeintCodex.PageHead), derselbe rechte
-- Detailbereich (Navigation.SetInspector), dieselbe Listenspalte mit
-- derselben zweiten Zeile (Navigation.BuildSidebar), derselbe Rahmen
-- fuer Anklickbares (WeintCodex.DrawBorder aus core/ui.lua, mit dem
-- auch Chip und Knopf umrandet sind). Wo der Dungeonbereich etwas
-- anders macht - keine gespeicherte ID, keine Bosse in der Spalte,
-- eine rollende Karte statt einer Liste -, steht der Grund daneben.
-- Eine zweite Oberflaechensprache ist es nicht.
--
-- WAS SICH NICHT GEAENDERT HAT, weil es keine Frage der Form ist:
--
--   * DIE HERKUNFT STEHT DRAN. Eine Bossliste aus einem Forenbericht
--     sieht auf einer Oberflaeche genauso aus wie eine aus dem
--     Handbuch - es sei denn, die Oberflaeche sagt den Unterschied.
--     Er steht als Vorsatz an der Rubrik ueber dem Raster, und wer
--     ihn ueberfaehrt, liest, warum.
--   * KEINE ERFUNDENE TAKTIK. Was eine Rolle an einem Kampf tut,
--     kommt vom Discord-Bot oder gar nicht.
--   * KEINE PULLNUMMER OHNE REIHENFOLGE. `orderKnown = false` heisst:
--     die Karten tragen keine Zahl.
--   * KEINE KARTENBILDER. Siehe unten.
--   * KEINE GESPEICHERTE ID. Fuenfergruppen haben keinen Lockout.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.DungeonPages = {}

local C = WeintCodex.Colors
local D = WeintCodex.DungeonData
local S = WeintCodex.Sources
local M = WeintCodex.Metrics

local page           = nil
local rows           = {}
local selectedId     = nil
local selectedBoss   = nil
local selectedWing   = nil
local openBracket    = 1
local showSummons    = false
local building       = false
local inspectorShown = false

-- Was das zuletzt gezeichnete Raster geworden ist. DrawDungeon liest
-- beides, um zu entscheiden, ob die Seite den Detailbereich rechts
-- behalten darf (siehe dort).
local gridCols       = 0
local gridLongest    = 0

local function ClearRows()
    for _, row in ipairs(rows) do row:Hide() end
    wipe(rows)
end

--------------------------------------------------
-- Masse
--------------------------------------------------

local PAD_X, PAD_Y, GAP = M.PAD_X, M.PAD_Y, M.GAP

local CARD_PAD      = 20    -- Innenabstand der Kontextkarte
local BAR_W         = 10    -- schlanke Bildlaufleiste in der Karte
local SECTION_H     = 22    -- Rubrikzeile "Bosse"
local MIN_DETAIL_H  = 160   -- weniger Karte als das ist keine
local CARD_GAP      = 12    -- Raster -> Kontextkarte

-- DAS BOSSRASTER. Eine Karte traegt bis zu drei Auskuenfte: die
-- Nummer (nur bei bekannter Reihenfolge), den Namen und ein
-- Kennzeichen. Nummer und Kennzeichen teilen sich eine Kopfzeile;
-- traegt in der ganzen gezeigten Liste keine Karte eine davon, faellt
-- die Zeile weg und die Karte wird flach - eine reservierte Zeile,
-- die nirgends etwas enthaelt, ist Luft, die wie ein Fehler aussieht.
local BOSS_H        = 44    -- Karte mit Kopfzeile
local BOSS_H_FLAT   = 32    -- Karte ohne Kopfzeile
local BOSS_GAP      = 10
local BOSS_MIN_W    = 150   -- schmaler ist keine Karte mehr, sondern eine Pille
local BOSS_COLS     = 3     -- mehr als drei Spalten waeren wieder eine Kette
local BOSS_NAME     = 12    -- Schriftgrad des Namens auf der Karte

--------------------------------------------------
-- Die eigene Stufe
--------------------------------------------------
-- Defensiv wie jeder Client-Aufruf dieser Fassung. Antwortet der
-- Client nicht, ist die Stufe nil - und nil heisst ueberall "nicht
-- bekannt", nie "Stufe 0".

local function MyLevel()
    if type(UnitLevel) ~= "function" then return nil end
    local ok, level = pcall(UnitLevel, "player")
    if not ok or type(level) ~= "number" or level <= 0 then return nil end
    return level
end

--------------------------------------------------
-- WARUM HIER KEINE BILDER STEHEN
--------------------------------------------------
-- Nach einem Kompendium mit Bildern war ausdruecklich gefragt, und
-- die ehrliche Antwort ist: dieses Addon kann keine liefern, und
-- zwar aus zwei voneinander unabhaengigen Gruenden.
--
--   1. ES GIBT SIE NICHT. Blizzard hat fuer Forever keine
--      Dungeonkarten veroeffentlicht. Im Beta-Client liegt fuer
--      VIER der neun Instanzen ueberhaupt Kartenmaterial (Hall of
--      Thanes, Ruins of Lordaeron, Excavation Site, City of
--      Dalaran); fuer die anderen fuenf nicht. Ein Kompendium, das
--      fuenf leere Rahmen zeigt, ist keines.
--   2. SIE GEHOEREN NICHT UNS. Das Kartenmaterial ist Blizzards
--      Eigentum. Es in ein oeffentliches Repository zu legen, waere
--      unabhaengig von 1. keine Option.
--
-- Was ein Addon stattdessen duerfte, waere auf die Texturpfade des
-- Clients zu zeigen. Genau das ist hier aber verboten: welche Pfade
-- Forever vergibt, weiss niemand in diesem Projekt, und ein
-- geratener Pfad zeichnet im Spiel ein gruenes Rechteck - eine
-- Fehlermeldung, die wie ein Bild aussieht.
--
-- WAS ES STATTDESSEN GIBT, und das ist der brauchbare Teil: WO ein
-- Boss steht, laesst sich SAGEN, auch ohne ihn zu zeigen. Genau
-- dafuer ist `boss.position` da, und genau deshalb steht es auf der
-- Bosskarte an erster Stelle.

--------------------------------------------------
-- Was die Seite an Platz hat
--------------------------------------------------
-- BREITE: im Spiel die des Inhaltsbereichs; im Prueflauf setzt
-- load_test.lua den Inhaltsbereich auf die Breite des kleinsten
-- Fensters, damit der Lauf den schlimmsten Fall misst. Wo eine
-- Hoehe aus Text geschaetzt wird (WeintCodex.Paragraph), rechnet
-- die Seite IMMER mit der kleinsten Breite - die Schaetzung soll im
-- Spiel und im Prueflauf dieselbe sein.
--
-- HOEHE: dasselbe Budget wie fuer die Listenspalte
-- (Navigation.SubNavBudget), nur fuer den Inhalt - und aus demselben
-- Grund: was hier unten rausfaellt, faellt lautlos raus.

-- Seit 5.2.0.3 zeigt die Dungeonseite denselben rechten Detailbereich
-- wie die Schlachtzugseite (WeintCodex.Navigation.SetInspector). Der
-- schmaelert den Inhaltsbereich im Spiel automatisch (WeintCodex.
-- SetDetailShown) - diese Funktion muss dieselbe Schmaelerung schon
-- VOR dem Zeichnen kennen, sonst rechnet die Seite mit mehr Platz,
-- als tatsaechlich da ist, sobald der Bereich offen ist.
local function MinContentWidth()
    local w = WeintCodex.Navigation.ContentBudgetWidth()
    if inspectorShown then
        w = w - (M.DETAIL_W + M.DETAIL_GAP + M.PAD_X)
    end
    return w
end

local function ContentWidth()
    local cp = WeintCodex.ContentPanel
    local w  = cp and cp:GetWidth()
    if type(w) ~= "number" or w < MinContentWidth() then
        return MinContentWidth()
    end
    return w
end

-- Der Inhalt zwischen den Raendern, beim kleinsten Fenster.
local function ContentBudget()
    local limits = WeintCodex.WindowLimits or {}
    return (limits.minH or 780) - (M.TITLEBAR_H or 40) - 2 * PAD_Y
end

-- Was im SPIEL gerade an Hoehe da ist - mehr als das Budget, wenn
-- das Fenster groesser ist als das kleinste. Die Detailkarte darf
-- den Platz nehmen; die Rechnung des Prueflaufs bleibt beim Budget.
local function AvailableHeight()
    local cp = WeintCodex.ContentPanel
    local h  = cp and cp:GetHeight()
    local budget = ContentBudget()
    if type(h) ~= "number" or h - 2 * PAD_Y < budget then return budget end
    return h - 2 * PAD_Y
end

-- Wie hoch die zuletzt gezeichnete Seite geworden ist, von der
-- Oberkante des Inhaltsbereichs bis zur Unterkante des letzten
-- Bausteins. Der Prueflauf haelt das gegen PageBudget().
local pageUsed = 0

function WeintCodex.DungeonPages.PageHeight()
    return pageUsed
end

function WeintCodex.DungeonPages.PageBudget()
    return ContentBudget() + PAD_Y
end

-- Breite, die ein Absatz in der Detailkarte mindestens hat.
local function BodyWidthMin()
    return MinContentWidth() - 2 * PAD_X - 2 * CARD_PAD - BAR_W
end

--------------------------------------------------
-- Kleine Helfer
--------------------------------------------------

-- Breite eines Textes: gemessen, aber nie schmaler als geschaetzt.
-- Im Prueflauf antwortet der Client mit einem Naeherungswert, im
-- Spiel mit der Wahrheit - und wo die Schaetzung darueber liegt,
-- bleibt Luft, nie fehlt welche.
local function TextWidth(fs, text, size, factor)
    local est = WeintCodex.Utf8Len(text) * size * (factor or 0.56)
    local ok, w = pcall(fs.GetStringWidth, fs)
    if ok and type(w) == "number" and w > est then return w end
    return est
end

local function Tooltip(frame, title, lines)
    frame:EnableMouse(true)
    frame:SetScript("OnEnter", function(self)
        if not GameTooltip then return end
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
        GameTooltip:SetText(title, C.textBright[1], C.textBright[2], C.textBright[3])
        for _, line in ipairs(lines) do
            if line and line ~= "" then
                GameTooltip:AddLine(line, C.textMuted[1], C.textMuted[2], C.textMuted[3], true)
            end
        end
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function()
        if GameTooltip then GameTooltip:Hide() end
    end)
end

-- Eine duenne Kontur um eine Bosskarte. Ohne sie verschwimmt eine
-- nicht ausgewaehlte Karte mit dem dunklen Seitenhintergrund (surface2
-- auf bgDark ist nur ein Hauch heller) - nichts sagt "das hier ist ein
-- Gegenstand, kein Fliesstext". Die Eckmasken der Karte
-- (WeintCodex.CutCorners, OVERLAY, Unterebene 6) zeichnen sich ueber
-- die eckigen Enden dieser Linien und runden sie damit mit, ohne dass
-- die Kontur das selbst tun muss.
--
-- SIE KOMMT AUS core/ui.lua und ist keine eigene Nachbildung.
-- WeintCodex.DrawBorder zieht denselben Rahmen, mit dem auch der Chip
-- und der Danger-Knopf umrandet sind, gibt seine vier Kanten zum
-- Umfaerben zurueck und haengt sie - wie jede andere Kante im Addon -
-- zwei Punkte weit auf, sodass sie mit der Karte mitwaechst. Hier
-- stand bis 5.2.0.3 eine zeilenweise gleiche Zweitfassung davon;
-- zwei Rahmenimplementierungen sind zwei Gelegenheiten, dass eine
-- davon beim naechsten Palettenwechsel stehen bleibt.
local function CardEdge(card, alpha)
    return WeintCodex.DrawBorder(card,
        C.border[1], C.border[2], C.border[3], alpha or 0.9, 1)
end

-- Ein Eyebrow, den man ueberfahren kann: fuer den Vorsatz der
-- Herkunft, der seine Begruendung im Tooltip traegt.
local function HoverEyebrow(parent, text, opts)
    local host = CreateFrame("Frame", nil, parent)
    host:SetHeight(14)
    local fs = WeintCodex.Eyebrow(host, text, opts)
    fs:SetPoint("RIGHT", host, "RIGHT", 0, 0)
    host:SetWidth(TextWidth(fs, WeintCodex.Spaced(text), opts.size or 10, 0.6) + 4)
    return host, fs
end

-- Was ueber die Vollstaendigkeit zu sagen ist. Drei Faelle, drei
-- Saetze - und "vollstaendig" heisst hier "so vollstaendig, wie die
-- Quelle sie hergibt", nicht "von Blizzard abgesegnet".
local function CompletenessLine(dungeon)
    if not D.HasBosses(dungeon) then return nil end
    local named = #dungeon.bosses
    if D.BossesComplete(dungeon) == false then
        local total = D.BossCount(dungeon)
        if total then
            return named .. " von " .. total .. " Kämpfen benannt - die Liste "
                .. "ist unvollständig."
        end
        return "Die Liste ist unvollständig: " .. named .. " Kämpfe sind bekannt, "
            .. "wie viele es insgesamt sind, nicht."
    end
    if D.OrderKnown(dungeon) == false then
        return named .. " Kämpfe sind bekannt, ihre Reihenfolge nicht - deshalb "
            .. "steht keine Nummer daran."
    end
    return nil
end

--------------------------------------------------
-- Seite
--------------------------------------------------

local Redraw

local function BuildPage()
    if page then return page end
    local cp = WeintCodex.ContentPanel
    local f  = CreateFrame("Frame", nil, cp)
    f:SetAllPoints(cp)

    -- Waechst das Fenster, bekommt das Bossraster andere Spalten -
    -- und alles darunter rueckt. Die Karten ruecken dann still nach
    -- (PlaceGrid); neu GEZEICHNET wird die Seite nur, wenn sich die
    -- Spaltenzahl wirklich aendert, denn nur dann aendert sich die
    -- Hoehe des Rasters (siehe f._relayout, gesetzt in PlaceGrid).
    f:SetScript("OnSizeChanged", function()
        if f._relayout then f._relayout() end
    end)

    page = f
    return f
end

--------------------------------------------------
-- 1. Der Dungeonkontext
--------------------------------------------------
-- EIN AUFSCHLAG, KEINE VIER FLAECHEN. Bis 5.2.0.4 verteilte sich,
-- was dieser Dungeon IST, auf vier Stellen: eine Kennzahl rechts
-- oben ("BOSSE 9"), ein Stufenchip darunter, eine Faktenzeile links
-- und der Themensatz. 5.2.0.5 zog das auf EINE Zeile zusammen. Seit
-- 5.2.0.6 steht diese eine Auskunft auf einer eigenen Flaeche -
-- einer Kopfkarte, die den Dungeon aufschlaegt, statt ihn oben in
-- den Seitenrand zu schreiben:
--
--   +------------------------------------------------------------+
--   | C L A S S I C                                              |
--   | Maraudon                                                   |
--   | Drei Zugaenge: der orange und der violette Fluegel ...      |
--   | ---------------------------------------------------------- |
--   | Desolace | 46-55        | 5       | 9     | Stufe 10       |
--   | GEBIET   | STUFENBEREICH| SPIELER | BOSSE | ZU NIEDRIG     |
--   +------------------------------------------------------------+
--
-- WARUM EINE FLAECHE UND NICHT NUR TEXT. Der Seitenkopf stand bis
-- 5.2.0.5 auf demselben Grund wie alles andere; was ihn vom Rest
-- trennte, war Abstand. Abstand trennt aber auch den Bossabschnitt
-- vom Kartenraster, und so las sich die Seite als eine Folge
-- gleichrangiger Abschnitte. Die Kopfkarte ist die EINE Flaeche der
-- Seite, die eine Ueberschrift traegt statt eines Bestands - dass
-- sie einen eigenen Grund hat, sagt genau das.
--
-- DAS TATSACHENBAND STATT DER TATSACHENZEILE. Bis 5.2.0.5 stand
-- "Desolace · Stufe 46-55 · 5 Spieler · 9 Bosse · Deine Stufe 10 ·
-- zu niedrig" als umbrechender Absatz da. Das ist ein Satz, und ein
-- Satz wird gelesen, nicht ueberflogen - wer wissen will, ob seine
-- Stufe passt, sucht die Auskunft zwischen vier anderen heraus.
-- Jetzt traegt jede Tatsache eine eigene Spalte: oben der WERT in
-- Lesegroesse, darunter die RUBRIK als gesperrte Versalie. Das ist
-- dieselbe Form wie die Kennzahlen im Seitenkopf der anderen Seiten
-- (WeintCodex.PageHead, `stats`) - nur von links nach rechts
-- gelesen statt von rechts nach links gesetzt, weil es hier fuenf
-- sind und keine zwei.
--
-- WIE VIELE SPALTEN IN EINE ZEILE PASSEN, IST GERECHNET. Jede Zelle
-- ist so breit wie ihr breiterer der beiden Texte; was nicht mehr in
-- die Zeile passt, faellt in die naechste. Beim kleinsten Fenster
-- mit offenem Detailbereich bleiben dem Band 232 px, da stehen zwei
-- Zellen je Zeile - abgeschnitten wird nichts, und eine feste
-- Spaltenzahl gibt es nicht.
--
-- DIE STUFENZELLE IST DIE EINZIGE, DIE VON DER EIGENEN FIGUR
-- ABHAENGT, und sie faerbt beide Zeilen: "Stufe 10" ueber "ZU
-- NIEDRIG" in Warnfarbe. Nennt der Client keine Stufe, fehlt die
-- Zelle ganz - nicht "Stufe 0", nicht "passt nicht".

local TITLE_SIZE  = 30
local THEME_SIZE  = 14
local THEME_SPACE = 2

local HERO_PAD    = 22    -- Innenabstand der Kopfkarte, links/rechts
local HERO_TOP    = 14
local HERO_BOT    = 8

-- Das Tatsachenband. Wert oben, Rubrik darunter.
local FACT_VALUE  = 14
local FACT_LABEL  = 9
local FACT_GAP    = 20    -- Abstand zwischen zwei Zellen
local FACT_ROW_H  = FACT_VALUE + 3 + FACT_LABEL + 2
local FACT_ROW_GAP = 8

local DASH = "\226\128\148"   -- Geviertstrich: "nicht bekannt", nie eine 0

-- Was der Dungeon IST, Zelle fuer Zelle. Jede Auskunft steht genau
-- einmal darin - und keine steht da, die niemand hat.
local function MetaCells(dungeon)
    local cells = {}

    local zone = D.ZoneLabel(dungeon)
    cells[#cells + 1] = { value = zone or DASH, label = "Gebiet",
                          tone = zone and "textNormal" or "textFaint" }

    local range = D.LevelRange(dungeon)
    cells[#cells + 1] = range
        and { value = range, label = "Stufen", mono = true }
        or  { value = DASH,  label = "Stufen offen", tone = "textFaint" }

    cells[#cells + 1] = { value = tostring(dungeon.size), label = "Spieler", mono = true }

    -- Die Bosszahl. Eine 0 waere keine leere Auskunft, sondern eine
    -- falsche - und "4/9" ist eine dritte, die weder "4 Bosse" noch
    -- "9 Bosse" ist. Fuenf Bestaende, fuenf Zellen.
    local named = D.HasBosses(dungeon) and #dungeon.bosses or nil
    local total = D.BossCount(dungeon)
    if named and total and named < total then
        cells[#cells + 1] = { value = named .. " / " .. total, mono = true,
                              label = "Bosse benannt", tone = "warningBright" }
    elseif named then
        cells[#cells + 1] = { value = tostring(named), mono = true, label = "Bosse" }
    elseif total then
        cells[#cells + 1] = { value = tostring(total), mono = true,
                              label = "Kämpfe · Namen offen", tone = "warningBright" }
    elseif dungeon.conflict then
        cells[#cells + 1] = { value = DASH, label = "Quellen widersprechen sich",
                              tone = "warningBright" }
    else
        cells[#cells + 1] = { value = DASH, label = "Bosse unbekannt",
                              tone = "textFaint" }
    end

    -- Vier Zustaende, drei davon sichtbar. Ohne Stufe vom Client
    -- steht hier NICHTS - nicht "passt nicht", und nicht "Stufe 0".
    local level = MyLevel()
    local fits  = D.FitsLevel(dungeon, level)
    if level and fits ~= nil then
        local label, tone
        if fits then
            label, tone = "passt", "successBright"
        elseif level < (dungeon.minLevel or 0) then
            label, tone = "zu niedrig", "warningBright"
        else
            label, tone = "darüber", "textFaint"
        end
        cells[#cells + 1] = { value = "Stufe " .. level, label = label,
                              tone = tone, labelTone = tone }
    end

    return cells
end

-- Wie breit eine Zelle wird: so breit wie ihr breiterer Text.
-- Gerechnet, nicht gemessen - der Prueflauf soll dasselbe Band
-- bauen wie das Spiel (0,60 em je Zeichen; die gesperrte Rubrik
-- traegt zwischen jedem Zeichen ein Leerzeichen und ist deshalb
-- rund doppelt so breit je Zeichen).
local function CellWidth(cell)
    local valueW = WeintCodex.Utf8Len(cell.value) * FACT_VALUE * 0.60
    local labelW = WeintCodex.Utf8Len(cell.label) * FACT_LABEL * 1.15
    return math.max(valueW, labelW)
end

-- Legt das Band ab `y` in `parent` (Breite `width`) und gibt seine
-- Hoehe zurueck. Zeilenumbruch nach Platz, nicht nach Anzahl.
local function DrawMetaStrip(parent, y, cells, width)
    local rowsOut, current, used = {}, {}, 0
    for _, cell in ipairs(cells) do
        local w = CellWidth(cell)
        local need = (#current > 0 and FACT_GAP or 0) + w
        if #current > 0 and used + need > width then
            rowsOut[#rowsOut + 1] = current
            current, used = {}, 0
            need = w
        end
        cell._w = w
        current[#current + 1] = cell
        used = used + need
    end
    if #current > 0 then rowsOut[#rowsOut + 1] = current end

    local top = y
    for rowIndex, row in ipairs(rowsOut) do
        local x = 0
        for cellIndex, cell in ipairs(row) do
            if cellIndex > 1 then
                -- Eine Haarlinie zwischen zwei Zellen. Sie trennt,
                -- ohne eine Kachel zu zeichnen: fuenf umrandete
                -- Kaesten waeren fuenf Bedienelemente, und bedienen
                -- laesst sich hier nichts.
                local sep = parent:CreateTexture(nil, "ARTWORK")
                sep:SetSize(1, FACT_ROW_H - 6)
                sep:SetPoint("TOPLEFT", parent, "TOPLEFT",
                    x - math.floor(FACT_GAP / 2), top - 3)
                sep:SetColorTexture(C.border[1], C.border[2], C.border[3], 1.0)
            end

            local value = parent:CreateFontString(nil, "OVERLAY")
            value:SetFont(cell.mono and WeintCodex.Fonts.monoMedium
                or WeintCodex.Fonts.sansMedium, FACT_VALUE, "")
            value:SetJustifyH("LEFT")
            value:SetWordWrap(false)
            value:SetPoint("TOPLEFT", parent, "TOPLEFT", x, top)
            local vc = C[cell.tone or "textNormal"] or C.textNormal
            value:SetTextColor(vc[1], vc[2], vc[3])
            value:SetText(cell.value)

            local label = WeintCodex.Eyebrow(parent, cell.label,
                { size = FACT_LABEL, color = cell.labelTone or "textFaint" })
            label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, top - FACT_VALUE - 4)

            x = x + cell._w + FACT_GAP
        end
        top = top - FACT_ROW_H
        if rowIndex < #rowsOut then top = top - FACT_ROW_GAP end
    end

    return y - top
end

-- Wie hoch das Band bei `width` wird - dieselbe Packung wie oben,
-- ohne zu zeichnen. DrawHead braucht die Zahl, bevor die Kopfkarte
-- steht.
local function MetaStripHeight(cells, width)
    local lines, used = 1, 0
    for _, cell in ipairs(cells) do
        local w = CellWidth(cell)
        local need = (used > 0 and FACT_GAP or 0) + w
        if used > 0 and used + need > width then
            lines = lines + 1
            used = w
        else
            used = used + need
        end
    end
    return lines * FACT_ROW_H + (lines - 1) * FACT_ROW_GAP
end

local function DrawHead(f, dungeon)
    local inner = MinContentWidth() - 2 * PAD_X - 2 * HERO_PAD

    local themeH = 0
    if dungeon.theme then
        local cols = math.floor(inner / (THEME_SIZE * 0.60))
        themeH = 8 + WeintCodex.EstimateLines(dungeon.theme, cols)
                    * (THEME_SIZE + THEME_SPACE)
    end

    local cells  = MetaCells(dungeon)
    local stripH = MetaStripHeight(cells, inner)

    -- 12 Eyebrow + 6 Abstand + 34 Titel + Themensatz + 13 Trennlinie
    local headH  = 12 + 6 + 34 + themeH + 13
    local heroH  = HERO_TOP + headH + stripH + HERO_BOT

    -- Die Kopfkarte. `tone = "plain"` heisst: derselbe Kartenverlauf
    -- und dieselbe 1-px-Oberkante wie jede andere Flaeche des Addons
    -- (core/ui.lua, CreateSurface) - kein zweiter Kartenstil neben
    -- dem einen, den es gibt.
    local hero = WeintCodex.CreateSurface(f, {
        tone = "plain", radius = M.CARD_R, backdrop = "bgDark", height = heroH,
    })
    hero:SetPoint("TOPLEFT",  f, "TOPLEFT",   PAD_X, -PAD_Y)
    hero:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PAD_X, -PAD_Y)
    rows[#rows + 1] = hero

    -- Der Akzentstreifen an der linken Kante. Er traegt Bedeutung
    -- und keine Zierde: er sagt, WO auf der Seite man ist - dieselbe
    -- Marke, die in der Spalte links am ausgewaehlten Dungeon steht
    -- und auf der ausgewaehlten Bosskarte. Drei Stellen, ein Zeichen.
    local edge = hero:CreateTexture(nil, "OVERLAY", nil, 2)
    edge:SetWidth(3)
    edge:SetPoint("TOPLEFT",    hero, "TOPLEFT",    0, -12)
    edge:SetPoint("BOTTOMLEFT", hero, "BOTTOMLEFT", 0,  12)
    edge:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.85)

    -- Derselbe Seitenkopf wie ueberall (WeintCodex.PageHead), nur in
    -- der Kopfkarte statt im Seitenrand.
    local head = WeintCodex.PageHead(hero, {
        eyebrow   = D.IsLegacy(dungeon) and "Classic" or "Forever",
        title     = dungeon.name,
        titleSize = TITLE_SIZE,
        x         = HERO_PAD,
        y         = HERO_TOP,
        height    = headH,
    })

    if dungeon.theme then
        local themeFs = WeintCodex.Paragraph(head, dungeon.theme, {
            width = inner, size = THEME_SIZE, spacing = THEME_SPACE,
            color = "textDim", font = WeintCodex.Fonts.displayQuiet,
        })
        themeFs:SetPoint("TOPLEFT",  head.Title, "BOTTOMLEFT", 0, -8)
        themeFs:SetPoint("TOPRIGHT", head,       "TOPRIGHT",   0, 0)
    end

    -- Die Trennlinie zwischen Aufschlag und Tatsachenband. Sie ist
    -- der Grund, dass das Band als Band gelesen wird und nicht als
    -- vierte Textzeile.
    --
    -- SIE HAENGT AN DER KOPFKARTE UND NICHT AM TEXT DARUEBER, und das
    -- ist kein Zufall: wie hoch der Client eine 30-px-Serife
    -- tatsaechlich setzt, weiss nur er. Haengte die Linie am Titel,
    -- verschoebe eine um drei Pixel hoehere Schrift sie unter das
    -- Band - und die Kopfkarte haette einen Strich mitten durch die
    -- Tatsachen. Die gerechnete Hoehe (headH) ist dieselbe, mit der
    -- die Karte gebaut wird, also sitzt die Linie in Spiel und
    -- Prueflauf an derselben Stelle.
    local rule = hero:CreateTexture(nil, "ARTWORK")
    rule:SetHeight(1)
    rule:SetPoint("TOPLEFT",  hero, "TOPLEFT",   HERO_PAD, -(HERO_TOP + headH - 9))
    rule:SetPoint("TOPRIGHT", hero, "TOPRIGHT", -HERO_PAD, -(HERO_TOP + headH - 9))
    rule:SetColorTexture(C.border[1], C.border[2], C.border[3], 1.0)

    local band = CreateFrame("Frame", nil, hero)
    band:SetPoint("TOPLEFT",  hero, "TOPLEFT",   HERO_PAD, -(HERO_TOP + headH))
    band:SetPoint("TOPRIGHT", hero, "TOPRIGHT", -HERO_PAD, -(HERO_TOP + headH))
    band:SetHeight(math.max(1, stripH))
    DrawMetaStrip(band, 0, cells, inner)

    return -(PAD_Y + heroH)
end

--------------------------------------------------
-- 2. Die Bosse
--------------------------------------------------
-- EIN RASTER AUS KARTEN, KEINE KETTE AUS PILLEN.
--
-- Bis 5.2.0.4 lagen die Bosse als Zeile nummerierter Pillen da, und
-- die las sich wie eine zweite Navigation: schmale, gerundete
-- Schaltflaechen in einer Reihe sind das Bild, mit dem jede
-- Oberflaeche "hier wechselst du die Ansicht" sagt. Was der Dungeon
-- ENTHAELT, sah damit aus wie ein Bedienelement.
--
-- Eine Karte sieht aus wie ein Gegenstand: sie hat eine eigene
-- Flaeche, eine Nummer oben links, den Namen darunter in Lesegroesse
-- und - wo es eines gibt - ein Kennzeichen oben rechts.
--
--     +---------------------------+
--     | 03               OPTIONAL |
--     | Commander Springvale      |
--     +---------------------------+
--
-- DIE SPALTENZAHL IST GERECHNET, NICHT GESETZT. Drei Spalten sind
-- das Ziel, aber sie sind eine Folge, keine Vorgabe: sie gelten nur,
-- wenn eine Karte darin noch BOSS_MIN_W breit ist UND der laengste
-- Name der gezeigten Liste ganz hineinpasst. "Temple of Atal'Hakkar"
-- hat Bosse mit 26 Zeichen; in 210 px stuenden die nicht, sondern
-- endeten in einem abgeschnittenen Wort. Dann sind es zwei Spalten,
-- und wo auch die nicht reichen (offener Detailbereich, 232 px), ist
-- es eine. Gerechnet wird mit derselben Kennzahl wie ueberall in
-- diesem Repository (0,60 em je Zeichen, siehe WeintCodex.Paragraph),
-- damit Spiel und Prueflauf dasselbe Raster bauen.
--
-- Umgebrochen wird mit dem Fenster: waechst es, rechnet _relayout
-- die Spalten neu und ruecht die Karten. Neu GEZEICHNET wird die
-- Seite nur, wenn sich die Spaltenzahl wirklich aendert - dann
-- aendert sich auch die Hoehe des Rasters und alles darunter.

-- Das Kennzeichen einer Karte. BESCHWOEREN schlaegt OPTIONAL schlaegt
-- TIPPS, weil "steht ohne Zutun gar nicht da" die dringendere
-- Auskunft ist.
local function BossTag(boss)
    if boss.summon then
        return "Beschwören", "warningBright"
    elseif boss.optional then
        return "Optional", "textFaint"
    elseif WeintCodex.Roles.HasTips(boss.name) then
        return "Tipps", "textMuted"
    end
end

-- Wie viele Spalten in `width` passen, und wie breit eine Karte
-- darin wird. `longest` ist die Laenge des laengsten Namens der
-- gezeigten Liste, in ZEICHEN (nicht Bytes).
local function GridLayout(width, longest)
    local need = 12 + longest * BOSS_NAME * 0.60 + 12
    for cols = BOSS_COLS, 2, -1 do
        local w = (width - (cols - 1) * BOSS_GAP) / cols
        if w >= BOSS_MIN_W and w >= need then return cols, w end
    end
    return 1, width
end

-- EINE KARTE, KEIN EINGABEFELD. Bis 5.2.0.5 war die Bosskarte eine
-- flache Flaeche (surface2) mit duennem Rahmen und blassem Namen -
-- genau das Bild, das in jeder Oberflaeche ein Textfeld ist. Sie
-- traegt jetzt denselben Kartenverlauf mit 1-px-Oberkante wie jede
-- andere Flaeche des Addons (CreateSurface, tone = "plain"), und
-- der Name steht in Lesefarbe statt in Beschriftungsfarbe: was hier
-- zaehlt, ist der Boss, nicht die Karte.
--
-- DREI ZUSTAENDE, DREI TOENE - und der ausgewaehlte ist der EINE
-- Akzentton der Seite (tone = "accent", violett getoenter Verlauf
-- mit Akzent-Oberkante). Im Entwurf gibt es genau eine solche
-- Flaeche je Ansicht, und das ist sie: die Kopfkarte oben traegt
-- ihren Akzent als Kantenstreifen, nicht als Flaeche.
local function BossCard(f, boss, height, headline)
    local card = WeintCodex.CreateSurface(f, {
        button = true, tone = "plain",
        radius = 10, backdrop = "bgDark", height = height,
    })
    local edge = CardEdge(card)

    -- Der aktive Zustand traegt einen Balken an der LINKEN Kante,
    -- nicht mehr eine Linie unten: die Karten stehen jetzt neben- UND
    -- untereinander, und eine Unterkante gehoerte optisch ebenso gut
    -- zur Karte darunter. Er liegt UEBER der Randkante (OVERLAY,
    -- Unterebene 3, statt ARTWORK), weil der Rahmen aus core/ui.lua
    -- selbst auf OVERLAY zeichnet; unter den Eckmasken (Unterebene 6)
    -- bleibt er trotzdem.
    local mark = card:CreateTexture(nil, "OVERLAY", nil, 3)
    mark:SetWidth(3)
    mark:SetPoint("TOPLEFT",    card, "TOPLEFT",    0, -7)
    mark:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 0,  7)
    mark:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 1.0)
    mark:Hide()

    local num
    if headline then
        if boss.order then
            num = card:CreateFontString(nil, "OVERLAY")
            num:SetFont(WeintCodex.Fonts.monoBold, 10, "")
            num:SetPoint("TOPLEFT", card, "TOPLEFT", 12, -9)
            num:SetText(string.format("%02d", boss.order))
        end
        local tag, tagTone = BossTag(boss)
        if tag then
            -- DAS KENNZEICHEN IST EINE PILLE, KEIN FREI SCHWEBENDES
            -- WORT. Bis 5.2.0.5 stand es als blosse Versalie oben
            -- rechts und sah aus, als waere es aus der Zeile darunter
            -- nach oben gerutscht. WeintCodex.Chip ist der Baustein,
            -- den das Addon dafuer hat - derselbe, der auch sonst
            -- einen Zustand an eine Zeile haengt.
            --
            -- Die Breite wird GERECHNET und nicht gemessen: der
            -- Prueflauf kennt keine Schriftmetrik, und eine Pille,
            -- die im Spiel breiter ist als im Lauf, haengt ueber der
            -- Karte. Gesperrter Text traegt hinter jedem Zeichen ein
            -- Leerzeichen, darum rund 1,15 em je Zeichen.
            local chip = WeintCodex.Chip(card, {
                text        = tag,
                tone        = tagTone,
                textColor   = tagTone,
                size        = 8,
                height      = 15,
                fill        = 0.10,
                borderAlpha = 0.45,
                backdrop    = "bgCard",
                width       = math.ceil(WeintCodex.Utf8Len(tag) * 8 * 1.15) + 14,
            })
            chip:SetPoint("TOPRIGHT", card, "TOPRIGHT", -10, -8)
        end
    end

    local name = card:CreateFontString(nil, "OVERLAY")
    name:SetFont(WeintCodex.Fonts.sansMedium, BOSS_NAME, "")
    name:SetWordWrap(false)
    name:SetJustifyH("LEFT")
    if headline then
        name:SetPoint("TOPLEFT",  card, "TOPLEFT",   12, -25)
        name:SetPoint("TOPRIGHT", card, "TOPRIGHT", -12, -25)
    else
        name:SetPoint("LEFT",  card, "LEFT",   12, 0)
        name:SetPoint("RIGHT", card, "RIGHT", -12, 0)
    end
    name:SetText(boss.name or "?")

    local active = (selectedBoss == boss.id)
    local function SetEdge(color, alpha)
        for _, t in ipairs(edge) do
            t:SetColorTexture(color[1], color[2], color[3], alpha)
        end
    end
    local function Paint(hover)
        if active then
            card:SetTone("accent")
            name:SetFont(WeintCodex.Fonts.sansSemi, BOSS_NAME, "")
            name:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3])
            if num then num:SetTextColor(C.accent[1], C.accent[2], C.accent[3]) end
            mark:Show()
            SetEdge(C.accent, 0.65)
        elseif hover then
            card:SetSurface("surface3")
            name:SetFont(WeintCodex.Fonts.sansMedium, BOSS_NAME, "")
            name:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3])
            if num then num:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3]) end
            mark:Hide()
            SetEdge(C.borderStrong, 1.0)
        else
            card:SetTone("plain")
            name:SetFont(WeintCodex.Fonts.sansMedium, BOSS_NAME, "")
            name:SetTextColor(C.textNormal[1], C.textNormal[2], C.textNormal[3])
            if num then num:SetTextColor(C.textFaint[1], C.textFaint[2], C.textFaint[3]) end
            mark:Hide()
            SetEdge(C.border, 0.9)
        end
    end
    Paint(false)

    card:SetScript("OnEnter", function() Paint(true) end)
    card:SetScript("OnLeave", function() Paint(false) end)
    card:SetScript("OnClick", function()
        if selectedBoss == boss.id then
            selectedBoss = nil
        else
            selectedBoss = boss.id
        end
        Redraw()
    end)

    rows[#rows + 1] = card
    return card
end

-- Eine Karte ohne Namen. Der Fall City of Dalaran: neun Kaempfe sind
-- berichtet, ihre Namen nicht. Neun leere Plaetze sagen genau das -
-- und keine Nummer, weil eine Reihenfolge ohne Namen keine ist.
local function GhostCard(f, height)
    local card = WeintCodex.CreateSurface(f, {
        tone = "flat", surface = "surface1", radius = 10,
        backdrop = "bgDark", height = height,
    })
    CardEdge(card, 0.6)
    local q = card:CreateFontString(nil, "OVERLAY")
    q:SetFont(WeintCodex.Fonts.mono, 11, "")
    q:SetPoint("LEFT", card, "LEFT", 12, 0)
    q:SetTextColor(C.textFaint[1], C.textFaint[2], C.textFaint[3])
    q:SetText("?")
    rows[#rows + 1] = card
    return card
end

-- Karten ins Raster legen, ab `top`. Setzt `f._relayout` und gibt
-- das y unter dem Raster zurueck.
local function PlaceGrid(f, cards, top, longest, height)
    if #cards == 0 then return top end

    local function Apply(cols, cardW)
        for index, card in ipairs(cards) do
            local col = (index - 1) % cols
            local row = math.floor((index - 1) / cols)
            card:SetWidth(cardW)
            card:ClearAllPoints()
            card:SetPoint("TOPLEFT", f, "TOPLEFT",
                PAD_X + col * (cardW + BOSS_GAP),
                top - row * (height + BOSS_GAP))
        end
        return math.ceil(#cards / cols)
    end

    local cols, cardW = GridLayout(ContentWidth() - 2 * PAD_X, longest)
    local n = Apply(cols, cardW)
    gridCols, gridLongest = cols, longest

    f._relayout = function()
        local c, w = GridLayout(ContentWidth() - 2 * PAD_X, longest)
        if c ~= cols then
            Redraw()
        else
            Apply(c, w)
        end
    end

    return top - n * height - (n - 1) * BOSS_GAP
end

-- Die Rubrikzeile ueber dem Raster: links "BOSSE", rechts der
-- Vorsatz der Herkunft. Er ist die eine Stelle auf der Seite, die
-- sagt, wie fest die Liste steht - und im Tooltip, warum.
--
-- OHNE ZAHL. Wie viele Bosse es sind, steht in der Tatsachenzeile im
-- Kopf; "BOSSE · 9" darueber waere dieselbe Zahl ein zweites Mal auf
-- derselben Seite.
local function SectionHead(f, y, label, source, extraLines, badgeText)
    local rubric = WeintCodex.Eyebrow(f, label, { color = "textDim", size = 10 })
    rubric:SetPoint("TOPLEFT", f, "TOPLEFT", PAD_X, y - 4)
    rows[#rows + 1] = rubric

    local text = badgeText or (source and S.Label(source))
    if text then
        local host = HoverEyebrow(f, text, { color = "warningBright", size = 10, justify = "RIGHT" })
        host:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PAD_X, y - 4)
        local lines = { source and S.Why(source) or nil }
        for _, extra in ipairs(extraLines or {}) do lines[#lines + 1] = extra end
        Tooltip(host, "Woher das stammt", lines)
        rows[#rows + 1] = host
    end

    return y - SECTION_H
end

-- Ein kurzer Absatz unter dem Raster (Vollstaendigkeit) oder an
-- seiner Stelle (kein Bestand). Gibt das y darunter zurueck.
local function Note(f, y, text, color, size)
    local fs, h = WeintCodex.Paragraph(f, text, {
        width = MinContentWidth() - 2 * PAD_X, size = size or 12, color = color or "textDim",
    })
    fs:SetPoint("TOPLEFT",  f, "TOPLEFT",   PAD_X, y)
    fs:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PAD_X, y)
    rows[#rows + 1] = fs
    return y - h
end

-- Zeichnet den ganzen Bossabschnitt und gibt das y darunter zurueck.
-- Vier Zustaende, vier Bilder - keiner davon ist eine leere Liste.
-- `bossOpen` sagt, ob unter dem Raster gerade ein Boss steht. Davon
-- haengt EIN Absatz ab: die Vollstaendigkeitszeile ("14 Kaempfe sind
-- bekannt, ihre Reihenfolge nicht"). Ohne Boss traegt sie die Spalte
-- BESONDERHEITEN der Kontextkarte, mit Boss gibt es die Spalte nicht
-- - dann steht der Satz hier. So steht er in JEDEM Zustand genau
-- einmal, nach derselben Regel wie die Herkunft.
local function DrawBosses(f, y, dungeon, bossOpen)
    local named = D.HasBosses(dungeon) and #dungeon.bosses or nil
    local total = D.BossCount(dungeon)

    -- Namen liegen vor.
    if named then
        local wings = D.Wings(dungeon)
        local completeness = CompletenessLine(dungeon)
        y = SectionHead(f, y, "Bosse", D.BossSource(dungeon), { completeness })

        local shown = dungeon.bosses
        if wings then
            local known = false
            for _, wing in ipairs(wings) do
                if wing == selectedWing then known = true end
            end
            if not known then selectedWing = wings[1] end
            shown = D.BossesInWing(dungeon, selectedWing)

            local items, selected = {}, 1
            for index, wing in ipairs(wings) do
                items[index] = { text = wing .. " · " .. #D.BossesInWing(dungeon, wing), key = wing }
                if wing == selectedWing then selected = index end
            end
            local tabs = WeintCodex.CreateSegmentedControl(f, {
                items = items, selected = selected, backdrop = "bgDark",
                onSelect = function(key)
                    selectedWing = key
                    selectedBoss = nil
                    Redraw()
                end,
            })
            tabs:SetPoint("TOPLEFT", f, "TOPLEFT", PAD_X, y)
            rows[#rows + 1] = tabs
            y = y - 38 - 10
        end

        -- Die Kopfzeile der Karten gibt es nur, wo sie etwas traegt:
        -- eine Nummer (nur bei bekannter Reihenfolge) oder ein
        -- Kennzeichen. Ist in der GANZEN gezeigten Liste keines von
        -- beidem da, sind alle Karten flach - und zwar alle, damit
        -- das Raster eine Zeilenhoehe hat und keine zwei.
        local headline, longest = false, 1
        for _, boss in ipairs(shown) do
            if boss.order or BossTag(boss) then headline = true end
            local len = WeintCodex.Utf8Len(boss.name or "?")
            if len > longest then longest = len end
        end
        local height = headline and BOSS_H or BOSS_H_FLAT

        local cards = {}
        for _, boss in ipairs(shown) do
            cards[#cards + 1] = BossCard(f, boss, height, headline)
        end
        y = PlaceGrid(f, cards, y, longest, height)

        if completeness and bossOpen then
            y = Note(f, y - 6, completeness, "textFaint", 11)
        end
        return y

    -- Die Anzahl liegt vor, die Namen nicht.
    elseif total then
        y = SectionHead(f, y, "Kämpfe", dungeon.countSource or S.COMMUNITY,
            { "Berichtet sind " .. total .. " Kämpfe. Ihre Namen sind es nicht - und "
              .. "die wenigen, die kursieren, ergeben keine Liste, sondern einen "
              .. "Ausschnitt." })
        local cards = {}
        for _ = 1, total do cards[#cards + 1] = GhostCard(f, BOSS_H_FLAT) end
        y = PlaceGrid(f, cards, y, 1, BOSS_H_FLAT)

        local text = total .. " Kämpfe berichtet, Namen unbekannt."
        if dungeon.partial and dungeon.partial.names then
            text = text .. " Bisher benannt (" .. #dungeon.partial.names .. " von "
                .. total .. "): " .. table.concat(dungeon.partial.names, ", ") .. "."
        end
        return Note(f, y - 10, text, "textFaint", 11)

    -- Zwei Quellen, die einander widersprechen, ergeben keine Liste -
    -- sie ergeben einen offenen Punkt, und der steht hier als solcher.
    elseif dungeon.conflict then
        y = SectionHead(f, y, "Bosse", nil, nil, "Quellen widersprechen sich")
        f._relayout = nil
        return Note(f, y, dungeon.conflict, "textMuted", 12)

    -- Gar nichts. Auch das ist eine Auskunft, und sie steht da.
    else
        y = SectionHead(f, y, "Bosse", nil, nil, nil)
        f._relayout = nil
        return Note(f, y, "Welche Bosse in " .. dungeon.name .. " stehen, hat Blizzard "
            .. "nicht veröffentlicht, und aus der Beta wird dazu nichts berichtet. "
            .. "WeintCodex trägt die Liste nach, wenn es eine gibt, und erfindet "
            .. "sie bis dahin nicht.", "textMuted", 12)
    end
end
-- Passt neben den Titel einer Kontextkarte noch ein zweites Element
-- (der Weg zurueck zur Uebersicht), ohne ihn zu ueberlagern?
-- Gerechnet mit derselben Kennzahl wie jede andere Textbreite hier
-- (0,60 em je Zeichen), und gegen die SCHMALSTE Breite, die die Karte
-- haben kann - mit offenem Detailbereich sind das 192 px, und da
-- passt neben einem Bossnamen kein Satz mehr. Dann steht dort das
-- blosse Kreuz.
local function HintFits(title, titleSize, hint, hintSize)
    local inner = MinContentWidth() - 2 * PAD_X - 2 * CARD_PAD
    local need  = WeintCodex.Utf8Len(title or "") * titleSize * 0.60
                + 16
                + WeintCodex.Utf8Len(hint or "") * hintSize * 0.60
    return inner >= need
end

--------------------------------------------------
-- 3. Die Kontextkarte
--------------------------------------------------
-- EINE Karte, mit Kopf und Koerper. Der Koerper ist ein Bildlauffeld:
-- passt der Inhalt, ist die Karte genau so hoch wie er; passt er
-- nicht, nimmt die Karte den Platz bis zum Fensterrand und rollt.
-- Das ist die eine Flaeche der Seite, die rollen darf - und sie
-- rollt nur, wenn der Bot mehr geschickt hat, als das Fenster zeigt.
--
-- SIE IST DIE DRITTE EBENE, NICHT DIE ERSTE. Bis 5.2.0.4 war sie
-- ohne ausgewaehlten Boss die groesste Flaeche der Seite und trug
-- eine einzige Auskunft (die Aufstellung) plus den Satz, dass hier
-- gleich etwas stehen koennte. Jetzt steht ueber ihr ein Raster, das
-- den Platz nimmt, den es braucht, und sie traegt in beiden
-- Zustaenden etwas, das es ohne sie nicht gaebe.
--
-- opts:
--   eyebrow, title, titleFont, titleSize
--   onClose            Weg zurueck, rechts oben im Kartenkopf
--   closeText          Beschriftung dafuer, wo sie neben den Titel
--                      passt (HintFits); sonst das blosse Kreuz
--   build(inner, w)    zeichnet den Koerper in `inner`, `w` ist die
--                      kleinste Breite; gibt die Hoehe zurueck
--
-- Gibt das y unter der Karte zurueck.

local function DetailCard(f, y, opts)
    local card = WeintCodex.CreateSurface(f, { tone = "plain", radius = 14, backdrop = "bgDark" })
    card:SetPoint("TOPLEFT",  f, "TOPLEFT",   PAD_X, y)
    card:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PAD_X, y)
    rows[#rows + 1] = card

    local headY = -CARD_PAD
    if opts.eyebrow then
        local eb = WeintCodex.Eyebrow(card, opts.eyebrow, { color = "textDim", size = 10 })
        eb:SetPoint("TOPLEFT", card, "TOPLEFT", CARD_PAD, headY)
        headY = headY - 16
    end

    -- OHNE TITEL GIBT ES KEINEN KOPF. Die Karte ohne Boss traegt
    -- seit 5.2.0.6 zwei Rubriken IN ihrem Koerper (Besonderheiten,
    -- Aufstellung) und darueber keinen dritten Namen mehr - ein Titel
    -- "Aufstellung" ueber einer Spalte "Aufstellung" waere dasselbe
    -- Wort zweimal, und die Zeile dafuer waere Luft.
    local titleSize = opts.titleSize or 20
    if opts.title then
        local title = card:CreateFontString(nil, "OVERLAY")
        title:SetFont(opts.titleFont or WeintCodex.Fonts.display, titleSize, "")
        title:SetPoint("TOPLEFT", card, "TOPLEFT", CARD_PAD, headY)
        title:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3])
        title:SetText(opts.title)
        headY = headY - titleSize - 8
    end

    -- DER WEG ZURUECK. Dass das Raster oben stehen bleibt, sagt schon,
    -- dass es die Uebersicht noch gibt; dass man aus dem Boss wieder
    -- herauskommt, sagt erst dieser Knopf. Er traegt seine
    -- Beschriftung, wo sie danebenpasst - in einer 192 px schmalen
    -- Karte bleibt es beim Kreuz, das an derselben Stelle dasselbe
    -- tut.
    if opts.onClose then
        local label = opts.closeText
            and HintFits(opts.title or "", titleSize, opts.closeText .. "    ", 12)
            and opts.closeText or nil
        local close = WeintCodex.CreateButton(card, {
            kind   = "ghost",
            text   = label or "\195\151",
            width  = label and (WeintCodex.Utf8Len(label) * 12 * 0.60 + 28) or 28,
            height = 28,
            size   = label and 12 or 15,
            radius = 8, backdrop = "cardTop", onClick = opts.onClose,
        })
        close:SetPoint("TOPRIGHT", card, "TOPRIGHT", -12, -12)
    end

    local headH = -headY

    -- Der Koerper. Breite im Spiel aus dem Rahmen, im Prueflauf aus
    -- dem Budget; die Schaetzung der Absaetze rechnet immer mit dem
    -- Budget.
    local sf, inner = WeintCodex.CreateScrollArea(card, CARD_PAD, -headH, 100, 100, true)
    sf:ClearAllPoints()
    sf:SetPoint("TOPLEFT",     card, "TOPLEFT",      CARD_PAD, -headH)
    sf:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -CARD_PAD - BAR_W, CARD_PAD)
    inner:SetWidth(ContentWidth() - 2 * PAD_X - 2 * CARD_PAD - BAR_W)
    sf.scrollBarHideable = true
    sf:HookScript("OnSizeChanged", function(self, w)
        if type(w) == "number" and w > 0 then inner:SetWidth(w) end
    end)

    local needed = opts.build(inner, BodyWidthMin()) or 0
    inner:SetHeight(math.max(1, needed))

    local remaining = AvailableHeight() + y - PAD_Y
    local wanted    = headH + needed + CARD_PAD
    local bar       = sf.WCScrollBar

    if wanted <= remaining then
        card:SetHeight(math.max(wanted, MIN_DETAIL_H))
        if bar then bar:Hide() end
        y = y - card:GetHeight()
    else
        -- Fuellt bis zum Rand und rollt. Unten verankert, damit die
        -- Karte mit dem Fenster mitwaechst, ohne neu zu zeichnen.
        card:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -PAD_X, PAD_Y)
        if bar then bar:Show() end
        y = -(PAD_Y + AvailableHeight())
        -- Weniger als MIN_DETAIL_H waere keine Karte, sondern ein
        -- Schlitz - dann ist die Bosszeile zu hoch, nicht der Text zu
        -- lang, und der Prueflauf soll es so sehen.
        if remaining < MIN_DETAIL_H then
            y = y - (MIN_DETAIL_H - remaining)
        end
    end

    sf:SetVerticalScroll(0)
    if sf.UpdateScrollChildRect then sf:UpdateScrollChildRect() end
    return y
end

-- Ein Zwischentitel im Kartenkoerper.
local function BodyHeading(inner, y, text)
    local h = WeintCodex.Label(inner, text, { color = "textBright", size = 13,
        font = WeintCodex.Fonts.sansSemi })
    h:SetPoint("TOPLEFT", inner, "TOPLEFT", 0, y)
    return y - 20
end

local function BodyText(inner, y, text, width, opts)
    opts = opts or {}
    local fs, h = WeintCodex.Paragraph(inner, text, {
        width = width, size = opts.size or 13, color = opts.color or "textMuted",
    })
    fs:SetPoint("TOPLEFT",  inner, "TOPLEFT",  0, y)
    fs:SetPoint("TOPRIGHT", inner, "TOPRIGHT", 0, y)
    return y - h
end

--------------------------------------------------
-- 3a. Ohne Boss: Besonderheiten, Aufstellung, Herkunft
--------------------------------------------------
-- DREI AUSKUENFTE IN ZWEI SPALTEN, NICHT EINE UNTER DER ANDEREN.
-- Bis 5.2.0.5 trug diese Karte die Aufstellung und darunter die
-- Herkunft als zwei Absatzbloecke - eine schmale Saeule Text in
-- einer breiten Karte, mit viel Flaeche rechts daneben, die nichts
-- tat. Seit 5.2.0.6 stehen BESONDERHEITEN und AUFSTELLUNG
-- nebeneinander, getrennt durch eine Haarlinie, und die Herkunft
-- laeuft als schmale Fusszeile unter beiden durch.
--
-- Die Karte traegt deshalb keinen eigenen Titel mehr: sie ist kein
-- Abschnitt "Aufstellung" mit Beiwerk, sondern die Flaeche, auf der
-- alles steht, was der Dungeon ausser seinen Bossen noch hergibt.
-- Jede Spalte fuehrt ihre eigene Rubrik.
--
-- WAS UNTER "BESONDERHEITEN" STEHT, IST ABGELEITET UND NICHT
-- ERFUNDEN. Jede Zeile kommt aus dem Bestand - wie viele Fluegel
-- die Instanz hat, wie viele Bosse nur auf Beschwoerung erscheinen,
-- wie viele neben dem Hauptweg stehen, ob die Reihenfolge bekannt
-- ist, ob die Liste vollstaendig ist, ob der Dungeon aus Classic
-- stammt. Ein Satz ueber "viel Laufweg" oder "schwierige Trashpacks"
-- waere zu jedem Dungeon dieser Welt zu schreiben und zu keinem
-- belegt; hier steht er nicht.
--
-- Liegt zu einem Dungeon keine einzige dieser Auskuenfte vor, faellt
-- die Spalte WEG und die Aufstellung nimmt die volle Breite. Eine
-- Rubrik ueber einer leeren Flaeche ist die Sorte Leerraum, die wie
-- ein Fehler aussieht.

local FACT_BAR_W   = 2
local FACT_TITLE_H = 16
local FACT_ENTRY_GAP = 9
local COL_GUTTER   = 24
local COL_MIN_W    = 210   -- schmaler als das ist keine Spalte mehr

-- Alles, was ueber diesen Dungeon zu sagen ist, ohne dass jemand
-- einen Boss angeklickt hat. Reihenfolge ist Rangfolge: was die
-- Gruppe VORHER wissen muss, steht oben.
local function FactEntries(dungeon)
    local out = {}

    local wings = D.Wings(dungeon)
    if wings and #wings > 1 then
        out[#out + 1] = {
            title  = #wings .. " Bereiche",
            detail = table.concat(wings, " · ") .. " - die Bossliste oben zeigt "
                  .. "einen davon zur Zeit.",
        }
    end

    local summonable = D.SummonableBosses(dungeon)
    if summonable and #summonable > 0 then
        local names = {}
        for _, boss in ipairs(summonable) do names[#names + 1] = boss.name end
        out[#out + 1] = {
            title  = #summonable == 1 and "Ein Boss nur auf Beschwörung"
                  or (#summonable .. " Bosse nur auf Beschwörung"),
            detail = table.concat(names, " · ") .. " - erscheint nicht von "
                  .. "selbst; die Bosskarte sagt, wie.",
            tone   = "warningBright",
        }
    end

    local optional = 0
    for _, boss in ipairs(dungeon.bosses or {}) do
        if boss.optional and not boss.summon then optional = optional + 1 end
    end
    if optional > 0 then
        out[#out + 1] = {
            title  = optional == 1 and "Ein Boss neben dem Hauptweg"
                  or (optional .. " Bosse neben dem Hauptweg"),
            detail = "Als OPTIONAL gekennzeichnet - die Gruppe kommt auch ohne "
                  .. "sie bis zum Ende.",
        }
    end

    local completeness = CompletenessLine(dungeon)
    if completeness then
        out[#out + 1] = {
            title  = D.BossesComplete(dungeon) == false and "Liste unvollständig"
                  or "Reihenfolge nicht bekannt",
            detail = completeness,
            tone   = "warningBright",
        }
    end

    if D.IsLegacy(dungeon) then
        out[#out + 1] = {
            title  = "Klassischer Dungeon",
            detail = "Blizzard hat die Beute jedes Bosses überarbeitet; die "
                  .. "Legacy-Aufgaben führen weiter durch ihn hindurch.",
        }
    end

    return out
end

-- Zeichnet die Besonderheiten ab `y` und gibt das y darunter zurueck.
local function DrawFacts(parent, y, entries, w)
    for _, entry in ipairs(entries) do
        local bar = parent:CreateTexture(nil, "ARTWORK")
        bar:SetSize(FACT_BAR_W, 13)
        bar:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y - 2)
        local bc = C[entry.tone] or C.borderStrong
        bar:SetColorTexture(bc[1], bc[2], bc[3], entry.tone and 0.9 or 1.0)

        local title = WeintCodex.Label(parent, entry.title,
            { color = entry.tone or "textNormal", size = 12,
              font = WeintCodex.Fonts.sansMedium })
        title:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, y)

        local detail, detailH = WeintCodex.Paragraph(parent, entry.detail,
            { width = w - 12, size = 11, spacing = 2, color = "textDim" })
        detail:SetPoint("TOPLEFT",  parent, "TOPLEFT",  12, y - FACT_TITLE_H)
        detail:SetPoint("TOPRIGHT", parent, "TOPRIGHT",  0, y - FACT_TITLE_H)

        y = y - FACT_TITLE_H - detailH - FACT_ENTRY_GAP
    end
    return y
end

-- DIE HERKUNFT ALS FUSSZEILE, NICHT ALS ERKLAERKARTE. Bis 5.2.0.5
-- standen hier zwei Zwischentitel und zwei Absaetze; das war die
-- groesste zusammenhaengende Textflaeche der Seite fuer die
-- nachrangigste Auskunft, die sie hat. Jetzt sind es drei Zeilen
-- unter einer Haarlinie - Rubrik, Vorsatz mit Quelle, Begruendung.
--
-- SIE STEHT NUR, WO DER DETAILBEREICH RECHTS FEHLT. Ist er offen,
-- steht sie dort (DungeonInspector), und zweimal derselbe Absatz
-- nebeneinander waere keine Betonung. So steht sie in JEDEM Zustand
-- der Seite genau einmal sichtbar.
local function SourceFooter(parent, y, dungeon, w)
    local source = D.BossSource(dungeon)
    local label, why
    if source then
        label, why = S.Label(source), S.Why(source)
    elseif dungeon.conflict then
        label, why = "Quellen widersprechen sich", dungeon.conflict
    else
        return y
    end

    local rule = parent:CreateTexture(nil, "ARTWORK")
    rule:SetHeight(1)
    rule:SetPoint("TOPLEFT",  parent, "TOPLEFT",  0, y - 6)
    rule:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, y - 6)
    rule:SetColorTexture(C.border[1], C.border[2], C.border[3], 1.0)
    y = y - 16

    local rubric = WeintCodex.Eyebrow(parent, "Quelle", { color = "textFaint", size = 9 })
    rubric:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)
    y = y - 14

    y = BodyText(parent, y, label, w, { size = 11, color = "warningBright" }) - 2
    y = BodyText(parent, y, why,   w, { size = 11, color = "textDim" })
    return y
end

local function DrawRoster(f, y, dungeon)
    local entries = FactEntries(dungeon)

    return DetailCard(f, y, {
        build = function(inner, w)
            local endY

            -- ZWEI SPALTEN, WO ZWEI SPALTEN PASSEN. Gerechnet aus der
            -- wirklichen Breite wie das Bossraster darueber - beim
            -- kleinsten Fenster mit offenem Detailbereich bleiben der
            -- Karte 192 px, und zwei Spalten daraus waeren zwei
            -- Textsaeulen von 84 px.
            local colW = math.floor((w - COL_GUTTER) / 2)
            if #entries > 0 and colW >= COL_MIN_W then
                local left = CreateFrame("Frame", nil, inner)
                left:SetPoint("TOPLEFT", inner, "TOPLEFT", 0, 0)
                left:SetWidth(colW)

                local right = CreateFrame("Frame", nil, inner)
                right:SetPoint("TOPLEFT", inner, "TOPLEFT", colW + COL_GUTTER, 0)
                right:SetWidth(colW)

                local lY = WeintCodex.Eyebrow(left, "Besonderheiten",
                    { color = "textDim", size = 10 })
                lY:SetPoint("TOPLEFT", left, "TOPLEFT", 0, 0)
                local leftEnd = DrawFacts(left, -20, entries, colW)

                local rY = WeintCodex.Eyebrow(right, "Aufstellung",
                    { color = "textDim", size = 10 })
                rY:SetPoint("TOPLEFT", right, "TOPLEFT", 0, 0)
                local rightEnd = WeintCodex.RolePanel.Roster(right, -20, dungeon,
                    { width = colW })

                local h = math.max(-leftEnd, -rightEnd)
                left:SetHeight(math.max(1, h))
                right:SetHeight(math.max(1, h))

                local sep = inner:CreateTexture(nil, "ARTWORK")
                sep:SetWidth(1)
                sep:SetPoint("TOPLEFT",    inner, "TOPLEFT",
                    colW + math.floor(COL_GUTTER / 2), 0)
                sep:SetPoint("BOTTOMLEFT", left,  "BOTTOMLEFT",
                    colW + math.floor(COL_GUTTER / 2), 0)
                sep:SetColorTexture(C.border[1], C.border[2], C.border[3], 1.0)

                endY = -h
            else
                endY = 0
                if #entries > 0 then
                    local rubric = WeintCodex.Eyebrow(inner, "Besonderheiten",
                        { color = "textDim", size = 10 })
                    rubric:SetPoint("TOPLEFT", inner, "TOPLEFT", 0, 0)
                    endY = DrawFacts(inner, -20, entries, w) - 8
                end
                local rubric = WeintCodex.Eyebrow(inner, "Aufstellung",
                    { color = "textDim", size = 10 })
                rubric:SetPoint("TOPLEFT", inner, "TOPLEFT", 0, endY)
                endY = WeintCodex.RolePanel.Roster(inner, endY - 20, dungeon,
                    { width = w })
            end

            if not inspectorShown then
                endY = SourceFooter(inner, endY - 4, dungeon, w)
            end
            return -endY
        end,
    })
end

--------------------------------------------------
-- 3b. Mit Boss: was ueber ihn berichtet ist
--------------------------------------------------
-- DER KARTENKOPF IST DER BOSSKOPF. Oben die Einordnung als gesperrte
-- Versalie - "BOSS 3 VON 9 · SCARLET · OPTIONAL" -, darunter der Name
-- in Lesegroesse, rechts der Weg zurueck. Das Raster darueber bleibt
-- stehen, und die angeklickte Karte darin traegt den Akzentbalken:
-- welcher Boss offen ist, steht damit an zwei Stellen, die einander
-- nicht wiederholen, sondern zusammengehoeren.
--
-- OHNE FUEHRENDE NULL, anders als auf der Karte. Dort ist die Nummer
-- eine Marke in einer Monospalte, die untereinander buendig stehen
-- soll; hier ist sie Teil eines Satzes, und "Boss 03 von 9" waere
-- keiner.

local BACK_TEXT = "Zurück zur Übersicht"

local function DrawBossDetail(f, y, dungeon, boss)
    local parts = {}
    if boss.order then
        parts[#parts + 1] = "Boss " .. boss.order .. " von " .. #dungeon.bosses
    else
        parts[#parts + 1] = "Boss"
    end
    if boss.wing then parts[#parts + 1] = boss.wing end
    if boss.summon then
        parts[#parts + 1] = "Nur beschworen"
    elseif boss.optional then
        parts[#parts + 1] = "Optional"
    end

    return DetailCard(f, y, {
        eyebrow   = table.concat(parts, " · "),
        title     = boss.name or "?",
        -- DER BOSSNAME STEHT IN DERSELBEN SCHRIFT WIE DER
        -- DUNGEONNAME, nur kleiner: beides sind Ueberschriften eines
        -- Bestands, und die Ueberschriftenschrift dieses Addons ist
        -- die Serife (WeintCodex.Fonts.display). Bis 5.2.0.5 stand
        -- hier die Grotesk - dieselbe Schrift wie auf den
        -- Bosskarten, den Rollenzeilen und den Knoepfen; der Name des
        -- geoeffneten Bosses sah damit aus wie eine weitere
        -- Beschriftung und nicht wie der Titel dessen, was darunter
        -- steht.
        titleFont = WeintCodex.Fonts.display,
        titleSize = 22,
        closeText = BACK_TEXT,
        onClose = function()
            selectedBoss = nil
            Redraw()
        end,
        build = function(inner, w)
            local y = 0

            -- DIE NOTIZ IST DER AUFSCHLAG, KEIN ABSCHNITT. Bis
            -- 5.2.0.5 stand sie unter einem Zwischentitel "Dazu" -
            -- zwischen "Wo er steht" und "Rollen", also so, als
            -- waere sie eine vierte Auskunft derselben Art. Sie ist
            -- aber der eine Satz, der sagt, WAS dieser Boss ist, und
            -- steht deshalb direkt unter seinem Namen, in derselben
            -- ruhigen Kursiven wie der Themensatz des Dungeons oben.
            if boss.note then
                local lead, leadH = WeintCodex.Paragraph(inner, boss.note, {
                    width = w, size = 13, spacing = 2, color = "textDim",
                    font = WeintCodex.Fonts.displayQuiet,
                })
                lead:SetPoint("TOPLEFT",  inner, "TOPLEFT",  0, y)
                lead:SetPoint("TOPRIGHT", inner, "TOPRIGHT", 0, y)
                y = y - leadH - 14
            end

            if boss.nameAlt then
                y = BodyText(inner, y, "Wird auch als „" .. boss.nameAlt .. "“ berichtet - "
                    .. "welchen Namen der Client vergibt, ist offen.", w,
                    { size = 12, color = "textDim" }) - 12
            end

            -- Die Beschwoerung steht VOR dem Standort: wer den Boss
            -- nicht holen kann, braucht nicht zu wissen, wo er steht.
            if boss.summon then
                y = BodyHeading(inner, y, "So kommt er")
                y = BodyText(inner, y, boss.summon.text or "", w)
                local label = S.Label(boss.summon.source)
                if label then
                    y = BodyText(inner, y - 4, label, w, { size = 11, color = "warningBright" })
                end
                y = y - 14
            end

            if boss.position then
                y = BodyHeading(inner, y, "Wo er steht")
                y = BodyText(inner, y, boss.position, w) - 14
            end

            y = BodyHeading(inner, y, "Rollen")
            y = WeintCodex.RolePanel.BossRoleRows(inner, y, boss, { width = w })

            return -y
        end,
    })
end

--------------------------------------------------
-- Detailbereich: der Dungeon selbst
--------------------------------------------------
-- Derselbe Baustein wie auf der Schlachtzugseite (WeintCodex.
-- Navigation.SetInspector) - fuer ein einheitliches Bild zeigt die
-- Dungeonseite seit 5.2.0.3 denselben rechten Kontextbereich.
--
-- WAS BEWUSST NICHT MIT HINUEBERWANDERT ist die vollstaendige
-- Rollenliste je Talentbaum (bei Schlachtzuegen: RolePanel.
-- InstanceBlocks). Die steht bei Schlachtzuegen im Detailbereich,
-- weil deren Seite keine eigene Bosszeile hat, die die Breite
-- braucht. Bei Dungeons zeigt die Aufstellung-Karte im Hauptinhalt
-- genau das schon, in voller Breite lesbar statt in 372 px
-- zusammengequetscht - eine zweite Kopie waere hier keine Erklaerung,
-- sondern eine schlechtere Wiederholung derselben Liste.
local function DungeonInspector(dungeon)
    local named  = D.HasBosses(dungeon) and #dungeon.bosses or nil
    local total  = D.BossCount(dungeon)
    local source = D.BossSource(dungeon)
    local range  = D.LevelRange(dungeon)

    local bossValue, bossColor
    if named and total and named < total then
        bossValue, bossColor = named .. " von " .. total, "warningBright"
    elseif named then
        bossValue, bossColor = tostring(named), source and "warningBright" or "textNormal"
    elseif total then
        bossValue, bossColor = total .. " · Namen unbekannt", "warningBright"
    elseif dungeon.conflict then
        bossValue, bossColor = "Quellen widersprechen sich", "warningBright"
    else
        bossValue, bossColor = "noch nicht bekannt", "textFaint"
    end

    -- DIE KENNZAHLEN SIND DIESELBEN WIE IM TATSACHENBAND DER
    -- KOPFKARTE, und das ist keine Wiederholung, sondern derselbe
    -- Bestand an zwei Orten mit verschiedener Aufgabe: das Band
    -- beantwortet "was ist das hier", waehrend man liest; der
    -- Detailbereich bleibt stehen, waehrend man durch die Bosse
    -- klickt. Dass er dabei die Herkunft NENNT (die Art) und
    -- darunter BEGRUENDET (die Quelle, der Warum-Satz), ist der
    -- Unterschied zum Band, das sie gar nicht fuehrt.
    local rowList = {
        { label = "Gebiet",  value = D.ZoneLabel(dungeon) or "—" },
        { label = "Stufe",   value = range or "unbekannt",
          valueColor = range and "textNormal" or "textFaint" },
        { label = "Spieler", value = tostring(dungeon.size) },
        { label = "Bosse",   value = bossValue, valueColor = bossColor },
    }
    local prefix = source and S.Prefix(source)
    if prefix then
        rowList[#rowList + 1] = { label = "Herkunft", value = prefix,
            valueColor = "warningBright" }
    elseif source then
        rowList[#rowList + 1] = { label = "Herkunft", value = "Bestätigt",
            valueColor = "successBright" }
    end

    local blocks = {
        { type = "header", text = "Dungeon-Details" },
        { type = "rows", rows = rowList },
    }

    -- "Woher die Bossliste stammt" wie bei Schlachtzuegen - bisher
    -- stand die Begruendung nur im Tooltip des Vorsatzes an der
    -- Bosszeile, und ein Tooltip findet niemand, der nicht ohnehin
    -- schon vermutet, dass da einer ist.
    if source then
        blocks[#blocks + 1] = { type = "divider" }
        blocks[#blocks + 1] = { type = "header", text = "Woher die Bossliste stammt" }
        -- Die QUELLE, nicht noch einmal die Art: die steht schon in
        -- der Kennzahlenzeile darueber.
        blocks[#blocks + 1] = { type = "text", text = source.label,
            color = "warningBright", size = 11, gap = 4 }
        -- Eine bestaetigte Quelle hat keinen Warum-Satz (S.Why liefert
        -- dafuer nil) - ein leerer Absatz waere eine Luecke, die wie
        -- ein verlorener Text aussieht.
        local why = S.Why(source)
        if why then
            blocks[#blocks + 1] = { type = "text", text = why, color = "textMuted" }
        end
    elseif dungeon.conflict then
        blocks[#blocks + 1] = { type = "divider" }
        blocks[#blocks + 1] = { type = "header", text = "Woher die Bossliste stammt" }
        blocks[#blocks + 1] = { type = "text", text = "Quellen widersprechen sich",
            color = "warningBright", size = 11, gap = 4 }
        blocks[#blocks + 1] = { type = "text", text = dungeon.conflict, color = "textMuted" }
    end

    if D.IsLegacy(dungeon) then
        blocks[#blocks + 1] = { type = "divider" }
        blocks[#blocks + 1] = { type = "header", text = "Klassischer Dungeon" }
        blocks[#blocks + 1] = { type = "text",
            text = "Blizzard hat die Beute jedes Bosses überarbeitet; die "
                .. "Legacy-Aufgaben führen weiter durch ihn hindurch.",
            color = "textDim", size = 10 }
    end

    return blocks
end

--------------------------------------------------
-- Der Dungeon, zusammengesetzt
--------------------------------------------------

-- Zeichnet den Dungeon einmal, mit oder ohne rechten Detailbereich.
-- `withInspector` entscheidet VOR jeder Pixelrechnung (MinContentWidth
-- liest inspectorShown), sonst zeichnet die Runde noch mit der alten
-- Breite.
local function DrawDungeonAt(f, dungeon, withInspector)
    ClearRows()
    f._relayout = nil
    gridCols, gridLongest = 0, 0

    -- EIN DETAILBEREICH OHNE INHALT NIMMT KEINE BREITE. SetInspector
    -- zeigt nichts, wenn die Liste leer ist - die Seite raeumte ihm
    -- die 420 px aber trotzdem ein und rechnete mit einer Breite, die
    -- sie gar nicht hergeben musste. Fuer die Dungeons ohne Bestand
    -- und ohne Herkunft (Alcaz Island Prison, Krol'dok Stronghold,
    -- Shaper's Terrace) war das die halbe Seite fuer nichts.
    local blocks = withInspector and DungeonInspector(dungeon) or nil
    withInspector = (blocks ~= nil and #blocks > 0)

    inspectorShown = withInspector
    if withInspector then
        WeintCodex.Navigation.SetInspector(blocks)
    else
        WeintCodex.Navigation.ClearInspector()
    end

    -- DER AUSGEWAEHLTE BOSS WIRD VOR DEM ZEICHNEN AUFGELOEST, nicht
    -- danach: der Bossabschnitt richtet sich danach (siehe
    -- DrawBosses, `bossOpen`), und eine Kennung aus einem anderen
    -- Dungeon darf dabei nicht als "ein Boss ist offen" durchgehen.
    local boss
    if selectedBoss then
        for _, candidate in ipairs(dungeon.bosses or {}) do
            if candidate.id == selectedBoss then boss = candidate end
        end
        if not boss then selectedBoss = nil end
    end

    local y = DrawHead(f, dungeon)
    y = DrawBosses(f, y - 8, dungeon, boss ~= nil)

    if boss then
        y = DrawBossDetail(f, y - CARD_GAP, dungeon, boss)
    else
        y = DrawRoster(f, y - CARD_GAP, dungeon)
    end

    pageUsed = -y
end

-- ERST DER DETAILBEREICH WIE BEI SCHLACHTZUEGEN, DANN DIE MESSUNG.
-- Zwei Dinge koennen die Seite in die volle Breite zwingen, und
-- beide sind gerechnet, nicht geschaetzt:
--
--   1. SIE PASST NICHT. Viele Bosse, viele Fluegelreiter - dann
--      bliebe der Kontextkarte nicht einmal ihre Mindesthoehe.
--      Gemessen wird mit derselben Rechnung, mit der load_test.lua
--      das Budget prueft (PageHeight gegen PageBudget), damit hier
--      kein Fall entsteht, den der Prueflauf nicht ohnehin
--      durchspielt.
--   2. DAS RASTER WAERE KEINES MEHR. Bei offenem Detailbereich
--      bleiben dem Inhalt im kleinsten Fenster 232 px - darin steht
--      eine Karte je Zeile, und eine Spalte ist keine Uebersicht,
--      sondern eine Liste. Kaeme die Seite in voller Breite auf
--      mehr als eine Spalte, ist die Uebersicht den Bereich wert:
--      seine Auskuenfte (Herkunft, klassischer Dungeon) traegt dann
--      die Kontextkarte im Seitenkoerper (SourceFooter), es geht also
--      keine verloren.
--
-- Im voreingestellten Fenster (1500 px) greift Nummer 2 nicht: dort
-- bleiben dem Inhalt auch mit Bereich 552 px, und das sind drei
-- Spalten. Sie ist die Regel fuer das kleinste zulaessige Fenster.
local function DrawDungeon(f, dungeon)
    DrawDungeonAt(f, dungeon, true)

    local wideCols = gridCols
    if inspectorShown and gridLongest > 0 then
        local full = ContentWidth() + (M.DETAIL_W + M.DETAIL_GAP + M.PAD_X)
        wideCols = GridLayout(full - 2 * PAD_X, gridLongest)
    end

    if pageUsed > WeintCodex.DungeonPages.PageBudget()
        or (gridCols == 1 and wideCols > 1) then
        DrawDungeonAt(f, dungeon, false)
    end
end

--------------------------------------------------
-- Uebersicht: alles, was sich beschwoeren laesst
--------------------------------------------------
-- Verstreut ueber neunundzwanzig Dungeons waere diese Auskunft
-- keine. Deshalb hat sie eine eigene Seite, erreichbar aus der
-- Spalte - und jede Zeile fuehrt zum Boss.

local BuildTree

local function DrawSummons(f)
    ClearRows()
    f._relayout = nil

    -- Diese Uebersicht gehoert zu keinem einzelnen Dungeon - kein
    -- Detailbereich, dafuer die volle Breite fuer die Liste.
    inspectorShown = false
    WeintCodex.Navigation.ClearInspector()

    local all = D.AllSummonable()

    local head = WeintCodex.PageHead(f, {
        eyebrow   = "Dungeons",
        title     = "Beschwörbare Zusatzbosse",
        titleSize = 30,
        sub       = #all .. " Gegner erscheinen erst, wenn die Gruppe etwas dafür tut",
        subSize   = 13,
        subColor  = "textMuted",
        height    = 10 + 6 + 34 + 4 + 16,
    })
    rows[#rows + 1] = head

    local y = -(PAD_Y + head.Height) - GAP

    pageUsed = -DetailCard(f, y, {
        title     = "Wo es welche gibt",
        titleFont = WeintCodex.Fonts.sansSemi,
        titleSize = 15,
        build = function(inner, w)
            local y = 0
            local ROW = 30
            for _, entry in ipairs(all) do
                local row = CreateFrame("Button", nil, inner)
                row:SetHeight(ROW)
                row:SetPoint("TOPLEFT",  inner, "TOPLEFT",  0, y)
                row:SetPoint("TOPRIGHT", inner, "TOPRIGHT", 0, y)
                local bg = row:CreateTexture(nil, "BACKGROUND")
                bg:SetAllPoints(row)
                bg:SetColorTexture(1, 1, 1, 0)

                local name = WeintCodex.Label(row, entry.boss.name, { color = "textNormal", size = 13 })
                name:SetPoint("LEFT", row, "LEFT", 4, 0)

                local where = WeintCodex.Eyebrow(row, entry.dungeon.name,
                    { color = "textFaint", size = 9, justify = "RIGHT" })
                where:SetPoint("RIGHT", row, "RIGHT", -4, 0)

                row:SetScript("OnEnter", function()
                    bg:SetColorTexture(1, 1, 1, 0.04)
                    name:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3])
                end)
                row:SetScript("OnLeave", function()
                    bg:SetColorTexture(1, 1, 1, 0)
                    name:SetTextColor(C.textNormal[1], C.textNormal[2], C.textNormal[3])
                end)
                row:SetScript("OnClick", function()
                    selectedId   = entry.dungeon.id
                    selectedBoss = entry.boss.id
                    selectedWing = entry.boss.wing
                    showSummons  = false
                    BuildTree(f)
                end)
                WeintCodex.RowLine(row, -(ROW - 1))
                y = y - ROW
            end
            if #all == 0 then
                y = BodyText(inner, y, "Keiner bekannt.", w)
            end

            -- DIE WICHTIGE UNTERSCHEIDUNG, UND SIE WIRD STAENDIG
            -- VERWECHSELT: Spieler beschwoeren und Bosse beschwoeren
            -- sind zwei verschiedene Dinge, und nur eines davon geht
            -- in Forever ueberhaupt.
            y = BodyHeading(inner, y - 20, "Spieler beschwören ist etwas anderes")
            y = BodyText(inner, y, D.SUMMONING.players or "", w)
            local label = S.Label(D.SUMMONING.source)
            if label then
                y = BodyText(inner, y - 4, label, w, { size = 11, color = "warningBright" })
            end
            return -y
        end,
    })
end

--------------------------------------------------
-- Neu zeichnen, was gerade dran ist
--------------------------------------------------

Redraw = function()
    if not page then return end
    if showSummons then
        WeintCodex.SetBreadcrumb("Dungeons", "Beschwörbare Zusatzbosse")
        DrawSummons(page)
        return
    end
    local dungeon = D.Get(selectedId)
    if not dungeon then return end
    local bossName
    for _, boss in ipairs(dungeon.bosses or {}) do
        if boss.id == selectedBoss then bossName = boss.name end
    end
    if bossName then
        WeintCodex.SetBreadcrumb("Dungeons", dungeon.name, bossName)
    else
        WeintCodex.SetBreadcrumb("Dungeons", dungeon.name)
    end
    DrawDungeon(page, dungeon)
end

--------------------------------------------------
-- Die Spalte links: Dungeons, nach Stufe
--------------------------------------------------
-- Stufenabschnitte als Koepfe, darunter die Instanzen des offenen
-- Abschnitts. So sucht man einen Dungeon: nach Stufe, nicht nach
-- Namen. Bosse stehen hier NICHT mehr - sie stehen auf der Seite,
-- wo Platz fuer sie ist. Die Spalte passt damit immer (642 von 716
-- px im groessten Abschnitt), und load_test.lua misst es nach.

-- ZWEI ZEILEN, UND DIE ZWEITE TRAEGT BEIDES. Bis 5.2.0.3 stand die
-- Herkunft ("FOREVER") als gesperrtes Kennzeichen rechts in der
-- Zeile - und nahm der Beschriftung rund 70 der 176 px, die sie hat.
-- Sichtbar war das als abgeschnittener Name: "Temple of Atal'Hakk…",
-- "Alcaz Island Priso…". Der Name ist aber das, wonach man in dieser
-- Spalte sucht; er bekommt die ganze Breite, und die zweite Zeile
-- sagt in einem Zug, aus welchem Spiel der Dungeon ist und fuer
-- welche Stufen er gedacht ist.
local function InstanceItem(f, dungeon)
    local kind  = D.IsLegacy(dungeon) and "Classic" or "Forever"
    local range = D.LevelRange(dungeon)

    return {
        label  = dungeon.name,
        -- Ohne Stufenbereich steht nur die Herkunft da. "Stufe ?"
        -- waere eine Auskunft, die niemand hat.
        status = range and (kind .. " · Stufe " .. range) or kind,
        onClick = function()
            local changed = (selectedId ~= dungeon.id)
            selectedId  = dungeon.id
            showSummons = false
            -- Ein zweiter Klick auf den offenen Dungeon fuehrt zurueck
            -- zur Aufstellung. Waehrend die Spalte gebaut wird, klickt
            -- nicht der Nutzer, sondern ActivateIndex - dann bleibt
            -- die Bossauswahl stehen (Select() setzt sie vorher).
            if changed or not building then
                selectedBoss = nil
            end
            if changed then selectedWing = nil end
            Redraw()
        end,
    }
end

local function SummonRow(f)
    return {
        label   = "Beschwörbare Zusatzbosse",
        status  = "Übersicht · " .. tostring(#D.AllSummonable()) .. " im Spiel",
        onClick = function()
            showSummons  = true
            selectedBoss = nil
            Redraw()
        end,
    }
end

BuildTree = function(f)
    building = true

    local current = D.Get(selectedId) or D.AllInstances()[1]
    selectedId  = current and current.id or nil
    openBracket = D.BracketIndexOf(selectedId)

    local items = {}
    for index, bucket in ipairs(D.Brackets()) do
        items[#items + 1] = {
            isGroup = true,
            label   = bucket.label,
            rangeLo = bucket.min,
            rangeHi = bucket.max,
            count   = #bucket.dungeons,
            open    = (index == openBracket),
            onClick = function()
                openBracket = index
                local first = bucket.dungeons[1]
                if first then
                    selectedId   = first.id
                    selectedBoss = nil
                    selectedWing = nil
                    showSummons  = false
                end
                if not building then BuildTree(f) end
            end,
        }
        if index == openBracket then
            for _, dungeon in ipairs(bucket.dungeons) do
                items[#items + 1] = InstanceItem(f, dungeon)
            end
        end
    end
    items[#items + 1] = SummonRow(f)

    -- Welche Zeile ist die aktive? Ueber den Inhalt gesucht und
    -- nicht mitgezaehlt: Gruppenkoepfe zaehlen in sidebarItems nicht
    -- mit, ein mitlaufender Zaehler saesse also daneben.
    local active, cursor = 1, 0
    for _, item in ipairs(items) do
        if not item.isGroup then
            cursor = cursor + 1
            if showSummons then
                if item.label == "Beschwörbare Zusatzbosse" then active = cursor end
            elseif item.label == (current and current.name) then
                active = cursor
            end
        end
    end

    WeintCodex.Navigation.BuildSidebar("Dungeons", items)
    WeintCodex.Navigation.ActivateIndex(active)

    building = false
end

--------------------------------------------------
-- Von aussen auf einen Dungeon oder Boss zeigen
--------------------------------------------------
-- Die Suche kennt neunundzwanzig Instanzen mit Stufenbereich, und
-- ein Treffer soll dort landen, wo er hingehoert.

function WeintCodex.DungeonPages.Select(dungeonId, bossId)
    local dungeon = D.Get(dungeonId)
    if not dungeon then return false end

    selectedId   = dungeon.id
    selectedBoss = nil
    selectedWing = nil
    showSummons  = false

    if bossId then
        for _, boss in ipairs(dungeon.bosses or {}) do
            if boss.id == bossId then
                selectedBoss = bossId
                selectedWing = boss.wing
            end
        end
    end

    if page and page:IsShown() then BuildTree(page) end
    return true
end

--------------------------------------------------

function WeintCodex.DungeonPages.Show()
    local cp = WeintCodex.ContentPanel
    for _, child in pairs({ cp:GetChildren() }) do child:Hide() end

    -- Der Detailbereich wird nicht hier pauschal geleert: SwitchTo tut
    -- das schon vor jedem Tabwechsel, und innerhalb des Tabs setzt ihn
    -- DrawDungeon/DrawSummons bei jeder Zeichnung neu - je nachdem, ob
    -- gerade ein einzelner Dungeon oder die Uebersicht gezeigt wird.

    local f = BuildPage()
    f:Show()

    BuildTree(f)
end
