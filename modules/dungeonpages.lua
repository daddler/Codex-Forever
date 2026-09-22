--------------------------------------------------
-- WeintCodex :: Dungeons
--
-- NEUNUNDZWANZIG INSTANZEN, DREI FLAECHEN, EINE SEITE.
--
-- Bis 5.2.0.0 teilten sich vier Flaechen die Aufmerksamkeit:
-- Navigation, ein Baum aus Stufen, Instanzen und Bossen, ein
-- Inhaltsbereich von 212 px und rechts ein Detailbereich, der alles
-- trug, was auf der Seite nicht mehr Platz hatte. Die Seite selbst
-- war die schmalste der vier - und ihre Bosskarte sagte, dass die
-- Bosse links stehen.
--
-- Seither ist es EINE Seite in voller Breite, und sie liest sich von
-- oben nach unten:
--
--   1. DER KOPF. Name, darunter Stufenbereich und Gruppengroesse,
--      darunter der Themensatz - und rechts die Bosszahl als
--      Kennzahl, wo sie neben den Titel passt, darunter, ob die
--      eigene Stufe passt. Wo sie nicht hinpasst, traegt der
--      Detailbereich sie (siehe DrawHead).
--   2. DIE BOSSE, als Zeile nummerierter Pillen. Ein Klick oeffnet
--      den Boss darunter, ein zweiter schliesst ihn. Grosse
--      Instanzen zeigen ihre Fluegel als Reiter darueber, einen
--      Fluegel zur Zeit - so verliert kein Fluegel einen Boss.
--   3. DIE DETAILKARTE. Ohne Boss die Aufstellung (Rollen, Plaetze,
--      Baeume), mit Boss das, was ueber ihn berichtet ist: wo er
--      steht, wie er kommt, was die Rollen tun. Sie ist die eine
--      Flaeche, die rollen darf - was der Bot je Rolle schickt, weiss
--      niemand vorher, und gekuerzt wird hier nichts.
--
-- Die Spalte links fuehrt nur noch Dungeons, nach Stufenabschnitt.
--
-- SEIT 5.2.0.3 zeigt die Seite denselben rechten Detailbereich wie
-- die Schlachtzugseite (Kennzahlen, Herkunft der Bossliste) - aber
-- NICHT bedingungslos: der Bereich braucht 420 px, die der Bosszeile
-- fehlen. Bei den wenigen Dungeons mit vielen Bossen in einem Fluegel
-- (Stratholme, Blackrock Depths, Scholomance, Lower Blackrock Spire)
-- zeichnet die Seite sich zuerst mit Bereich, misst sich selbst gegen
-- ihr eigenes Budget und faellt bei Ueberlauf auf die volle Breite
-- ohne Bereich zurueck (siehe DrawDungeon/DrawDungeonAt).
--
-- DASS SICH DAS WIE DIE SCHLACHTZUGSEITE ANFUEHLT, IST DER PUNKT,
-- und es ist keine Behauptung, sondern dieselben Bausteine:
-- derselbe Seitenkopf mit derselben Kennzahl rechts
-- (WeintCodex.PageHead), derselbe rechte Detailbereich
-- (Navigation.SetInspector), dieselbe Listenspalte mit derselben
-- zweiten Zeile (Navigation.BuildSidebar), derselbe Rahmen fuer
-- Anklickbares (WeintCodex.DrawBorder aus core/ui.lua, mit dem auch
-- Chip und Knopf umrandet sind). Wo der Dungeonbereich etwas anders
-- macht - keine gespeicherte ID, keine Bosse in der Spalte, eine
-- rollende Karte statt einer Liste -, steht der Grund daneben. Eine
-- zweite Oberflaechensprache ist es nicht.
--
-- WAS SICH NICHT GEAENDERT HAT, weil es keine Frage der Form ist:
--
--   * DIE HERKUNFT STEHT DRAN. Eine Bossliste aus einem Forenbericht
--     sieht auf einer Oberflaeche genauso aus wie eine aus dem
--     Handbuch - es sei denn, die Oberflaeche sagt den Unterschied.
--     Er steht als Vorsatz an der Bosszeile, und wer ihn ueberfaehrt,
--     liest, warum.
--   * KEINE ERFUNDENE TAKTIK. Was eine Rolle an einem Kampf tut,
--     kommt vom Discord-Bot oder gar nicht.
--   * KEINE PULLNUMMER OHNE REIHENFOLGE. `orderKnown = false` heisst:
--     die Pillen tragen keine Zahl.
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

local function ClearRows()
    for _, row in ipairs(rows) do row:Hide() end
    wipe(rows)
end

--------------------------------------------------
-- Masse
--------------------------------------------------

local PAD_X, PAD_Y, GAP = M.PAD_X, M.PAD_Y, M.GAP

local CARD_PAD      = 20    -- Innenabstand der Detailkarte
local BAR_W         = 10    -- schlanke Bildlaufleiste in der Karte
local SECTION_H     = 22    -- Rubrikzeile "Bosse"
local PILL_H        = 28
local PILL_GAP_X    = 8
local PILL_GAP_Y    = 6
local GHOST_W       = 40    -- Pille ohne Namen (Anzahl bekannt)
local MIN_DETAIL_H  = 160   -- weniger Karte als das ist keine

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

-- Eine duenne Kontur um eine Pille. Ohne sie verschwimmt eine nicht
-- ausgewaehlte Pille mit dem dunklen Seitenhintergrund (surface2 auf
-- bgDark ist nur ein Hauch heller) - nichts sagt "das hier ist ein
-- Knopf, kein Fliesstext". Die Eckmasken der Pille (WeintCodex.CutCorners,
-- OVERLAY, Unterebene 6) zeichnen sich ueber die eckigen Enden dieser
-- Linien und runden sie damit mit, ohne dass die Kontur das selbst tun
-- muss.
--
-- SIE KOMMT AUS core/ui.lua und ist keine eigene Nachbildung mehr.
-- WeintCodex.DrawBorder zieht denselben Rahmen, mit dem auch der Chip
-- und der Danger-Knopf umrandet sind, gibt seine vier Kanten zum
-- Umfaerben zurueck und haengt sie - wie jede andere Kante im Addon -
-- zwei Punkte weit auf, sodass sie mit der Pille mitwaechst. Hier
-- stand bis 5.2.0.3 eine zeilenweise gleiche Zweitfassung davon;
-- zwei Rahmenimplementierungen sind zwei Gelegenheiten, dass eine
-- davon beim naechsten Palettenwechsel stehen bleibt.
local function PillEdge(pill, alpha)
    return WeintCodex.DrawBorder(pill,
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

    -- Waechst das Fenster, laufen die Pillen anders um - und alles
    -- darunter rueckt. Neu gezeichnet wird nur, wenn sich die
    -- Zeilenzahl wirklich aendert; das entscheidet die Seite selbst
    -- (siehe f._relayout, gesetzt in DrawBosses).
    f:SetScript("OnSizeChanged", function()
        if f._relayout then f._relayout() end
    end)

    page = f
    return f
end

--------------------------------------------------
-- 1. Der Kopf
--------------------------------------------------
-- Der Name ist das Zentrum. Darunter eine Zeile Tatsachen, darunter
-- - in der ruhigen Serife - der eine Satz, der sagt, was das fuer
-- ein Ort ist. Rechts oben die Bosszahl als Kennzahl, so wie im Kopf
-- der Schlachtzugseite (modules/raidpages.lua), und darunter, falls
-- der Client eine Stufe nennt, ob sie passt.
--
-- DIE BOSSZAHL STEHT AN GENAU EINER STELLE, und welche das ist,
-- entscheidet der Platz - gerechnet, nicht gehofft:
--
--   1. Als KENNZAHL rechts im Kopf, wenn der Titel daneben noch
--      Platz laesst. Das ist der Normalfall in voller Breite und
--      das Bild, das die Schlachtzugseite zeigt.
--   2. In der FAKTENZEILE, wenn die Kennzahl nicht danebenpasst und
--      auch der Detailbereich sie nicht traegt.
--   3. GAR NICHT im Kopf, wenn der Detailbereich offen ist: der
--      fuehrt "Bosse" ohnehin als Zeile, und die Rubrik ueber den
--      Pillen sagt es ein drittes Mal. Dreimal dieselbe Zahl auf
--      einer Seite ist keine Betonung, sondern Laerm.
--
-- Warum ueberhaupt gerechnet wird: mit offenem Detailbereich bleiben
-- dem Inhalt 296 px, dem Kopf also 232. Ein Kennzahlenblock ist
-- 64 px breit und rechtsbuendig - ein Titel wie "Temple of
-- Atal'Hakkar" in 30 px liefe ihm ungebremst darunter. Geschaetzt
-- wird mit derselben Kennzahl wie ueberall (0,60 em je Zeichen,
-- WeintCodex.Paragraph), damit Spiel und Prueflauf dieselbe Seite
-- bauen.

local TITLE_SIZE = 30
local STAT_W     = 64   -- PageHead: Vorgabebreite eines Kennzahlenblocks
local STAT_GAP   = 16

local function HeadStatFits(dungeon)
    local avail = MinContentWidth() - 2 * PAD_X
    local title = WeintCodex.Utf8Len(dungeon.name or "") * TITLE_SIZE * 0.60
    return (avail - title) >= (STAT_W + STAT_GAP)
end

local function DrawHead(f, dungeon)
    local range = D.LevelRange(dungeon)
    local named = D.HasBosses(dungeon) and #dungeon.bosses or nil
    local total = D.BossCount(dungeon)

    local facts = {}
    facts[#facts + 1] = range and ("Stufe " .. range) or "Stufenbereich noch nicht bekannt"
    facts[#facts + 1] = dungeon.size .. " Spieler"

    -- Die Zahl steht NUR da, wo es sie gibt. Eine 0 waere keine leere
    -- Auskunft, sondern eine falsche - und "4/9" ist eine dritte, die
    -- weder "4 Bosse" noch "9 Bosse" ist.
    local stats = {}
    if HeadStatFits(dungeon) then
        if named and total and named < total then
            stats[1] = { key = "bosses", label = "Bosse",
                value = named .. "/" .. total, tone = "textNormal" }
        elseif named then
            stats[1] = { key = "bosses", label = "Bosse", value = named, tone = "textNormal" }
        elseif total then
            stats[1] = { key = "bosses", label = "Kämpfe", value = total, tone = "textDim" }
        end
    elseif not inspectorShown then
        if named and total and named < total then
            facts[#facts + 1] = named .. " von " .. total .. " Bossen bekannt"
        elseif named then
            facts[#facts + 1] = named .. (named == 1 and " Boss" or " Bosse")
        elseif total then
            facts[#facts + 1] = total .. " Kämpfe"
        end
    end

    -- Hoehe aus den Teilen, nicht geraten: Eyebrow, Titel, Fakten -
    -- und der Themensatz, wenn es einen gibt.
    local baseH  = 10 + 6 + 34 + 4 + 16
    local themeH = 0
    local THEME_SIZE, THEME_SPACING = 14, 2
    if dungeon.theme then
        local cols = math.floor((MinContentWidth() - 2 * PAD_X) / (THEME_SIZE * 0.60))
        themeH = 6 + WeintCodex.EstimateLines(dungeon.theme, cols) * (THEME_SIZE + THEME_SPACING)
    end

    local head = WeintCodex.PageHead(f, {
        eyebrow   = (D.IsLegacy(dungeon) and "Classic · " or "Dungeon · ")
                 .. (D.ZoneLabel(dungeon) or ""),
        title     = dungeon.name,
        titleSize = TITLE_SIZE,
        sub       = table.concat(facts, "   ·   "),
        subSize   = 13,
        subColor  = range and "textMuted" or "textFaint",
        height    = baseH + themeH,
        stats     = stats,
    })
    rows[#rows + 1] = head

    if dungeon.theme then
        local themeFs = WeintCodex.Paragraph(head, dungeon.theme, {
            width = MinContentWidth() - 2 * PAD_X, size = THEME_SIZE, spacing = THEME_SPACING,
            color = "textDim", font = WeintCodex.Fonts.displayQuiet,
        })
        themeFs:SetPoint("TOPLEFT",  head.Sub, "BOTTOMLEFT", 0, -6)
        themeFs:SetPoint("TOPRIGHT", head,     "TOPRIGHT",   0, 0)
    end

    -- Vier Zustaende, drei davon sichtbar. Ohne Stufe vom Client
    -- steht hier NICHTS - nicht "passt nicht", und nicht "Stufe 0".
    local level = MyLevel()
    local fits  = D.FitsLevel(dungeon, level)
    if level and fits ~= nil then
        local text, tone
        if fits then
            text, tone = "Deine Stufe " .. level .. " · passt", "successBright"
        elseif level < (dungeon.minLevel or 0) then
            text, tone = "Deine Stufe " .. level .. " · zu niedrig", "warningBright"
        else
            text, tone = "Deine Stufe " .. level .. " · darüber", "textFaint"
        end
        -- UNTER der Kennzahl, nicht neben ihr: beide stehen rechts
        -- oben, und nebeneinander waere die eine ueber der anderen
        -- gezeichnet. Ohne Kennzahl rueckt der Hinweis nach oben in
        -- die Ecke, die dann frei ist.
        local chip = WeintCodex.Eyebrow(head, text, { color = tone, size = 10, justify = "RIGHT" })
        chip:SetPoint("TOPRIGHT", head, "TOPRIGHT", 0, stats[1] and -50 or -1)
    end

    return -(PAD_Y + head.Height)
end

--------------------------------------------------
-- 2. Die Bosse
--------------------------------------------------

-- EINE PILLE JE BOSS. Nummer (nur wo die Reihenfolge bekannt ist),
-- Name, und rechts ein Kennzeichen, wenn es eines gibt: BESCHWOEREN
-- schlaegt OPTIONAL schlaegt TIPPS, weil "steht ohne Zutun gar nicht
-- da" die dringendere Auskunft ist. Die Breite kommt aus dem Text.
local function BossPill(f, dungeon, boss)
    local tag, tagTone
    if boss.summon then
        tag, tagTone = "Beschwören", "warningBright"
    elseif boss.optional then
        tag, tagTone = "Optional", "textFaint"
    elseif WeintCodex.Roles.HasTips(boss.name) then
        tag, tagTone = "Tipps", "textMuted"
    end

    local pill = WeintCodex.CreateSurface(f, {
        button = true, tone = "flat", surface = "surface2",
        radius = 8, backdrop = "bgDark", height = PILL_H,
    })
    local edge = PillEdge(pill)

    local x = 12
    local num
    if boss.order then
        num = pill:CreateFontString(nil, "OVERLAY")
        num:SetFont(WeintCodex.Fonts.monoBold, 10, "")
        num:SetPoint("LEFT", pill, "LEFT", x, 0)
        num:SetText(tostring(boss.order))
        x = x + TextWidth(num, tostring(boss.order), 10, 0.6) + 8
    end

    local name = pill:CreateFontString(nil, "OVERLAY")
    name:SetFont(WeintCodex.Fonts.sans, 12, "")
    name:SetWordWrap(false)
    name:SetPoint("LEFT", pill, "LEFT", x, 0)
    name:SetText(boss.name or "?")
    x = x + TextWidth(name, boss.name or "?", 12)

    -- Ungesperrt, anders als die Kennzeichen der Spalte: in einer
    -- Zeile aus elf Pillen ist Breite das knappe Gut.
    if tag then
        local mark = pill:CreateFontString(nil, "OVERLAY")
        mark:SetFont(WeintCodex.Fonts.mono, 9, "")
        mark:SetPoint("LEFT", pill, "LEFT", x + 8, 0)
        local mc = C[tagTone] or C.textFaint
        mark:SetTextColor(mc[1], mc[2], mc[3])
        mark:SetText(WeintCodex.Upper(tag))
        x = x + 8 + TextWidth(mark, tag, 9, 0.6)
    end

    pill:SetWidth(x + 12)
    pill._w = x + 12

    -- Der aktive Zustand: hellere Flaeche, heller Name, Akzentlinie
    -- unten. Derselbe Wortschatz wie in der Navigationsspalte.
    --
    -- Die Linie liegt UEBER der Randkante (OVERLAY, Unterebene 3,
    -- statt ARTWORK): der Rahmen aus core/ui.lua zeichnet auf
    -- OVERLAY, und seine Unterkante laege sonst genau auf der Linie,
    -- die den ausgewaehlten Boss ausweist. Unter den Eckmasken
    -- (Unterebene 6) bleibt sie trotzdem.
    local line = pill:CreateTexture(nil, "OVERLAY", nil, 3)
    line:SetHeight(2)
    line:SetPoint("BOTTOMLEFT",  pill, "BOTTOMLEFT",   8, 0)
    line:SetPoint("BOTTOMRIGHT", pill, "BOTTOMRIGHT", -8, 0)
    line:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 1.0)
    line:Hide()

    local active = (selectedBoss == boss.id)
    local function SetEdge(color, alpha)
        for _, t in ipairs(edge) do
            t:SetColorTexture(color[1], color[2], color[3], alpha)
        end
    end
    local function Paint(hover)
        if active then
            pill:SetSurface("surface3")
            name:SetFont(WeintCodex.Fonts.sansMedium, 12, "")
            name:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3])
            if num then num:SetTextColor(C.accent[1], C.accent[2], C.accent[3]) end
            line:Show()
            SetEdge(C.accent, 0.55)
        elseif hover then
            pill:SetSurface("surface3")
            name:SetTextColor(C.textNormal[1], C.textNormal[2], C.textNormal[3])
            SetEdge(C.borderStrong, 1.0)
        else
            pill:SetSurface("surface2")
            name:SetFont(WeintCodex.Fonts.sans, 12, "")
            name:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3])
            if num then num:SetTextColor(C.textFaint[1], C.textFaint[2], C.textFaint[3]) end
            line:Hide()
            SetEdge(C.border, 0.9)
        end
    end
    Paint(false)

    pill:SetScript("OnEnter", function() Paint(true) end)
    pill:SetScript("OnLeave", function() Paint(false) end)
    pill:SetScript("OnClick", function()
        if selectedBoss == boss.id then
            selectedBoss = nil
        else
            selectedBoss = boss.id
        end
        Redraw()
    end)

    rows[#rows + 1] = pill
    return pill
end

-- Eine Pille ohne Namen. Der Fall City of Dalaran: neun Kaempfe
-- sind berichtet, ihre Namen nicht. Neun leere Plaetze sagen genau
-- das - und keine Nummer, weil eine Reihenfolge ohne Namen keine
-- ist.
local function GhostPill(f)
    local pill = WeintCodex.CreateSurface(f, {
        tone = "flat", surface = "surface1", radius = 8,
        backdrop = "bgDark", height = PILL_H, width = GHOST_W,
    })
    PillEdge(pill)
    local q = pill:CreateFontString(nil, "OVERLAY")
    q:SetFont(WeintCodex.Fonts.mono, 11, "")
    q:SetPoint("CENTER", pill, "CENTER", 0, 0)
    q:SetTextColor(C.textFaint[1], C.textFaint[2], C.textFaint[3])
    q:SetText("?")
    pill._w = GHOST_W
    rows[#rows + 1] = pill
    return pill
end

-- Pillen in Zeilen legen. Gibt die Zeilenzahl zurueck - und wird
-- beim Vergroessern des Fensters noch einmal gefragt, ob sie
-- gleich bleibt.
local function LayoutPills(f, pills, top, width)
    local x, y, n = 0, top, 1
    for _, pill in ipairs(pills) do
        if x > 0 and x + pill._w > width then
            x = 0
            y = y - PILL_H - PILL_GAP_Y
            n = n + 1
        end
        pill:ClearAllPoints()
        pill:SetPoint("TOPLEFT", f, "TOPLEFT", PAD_X + x, y)
        x = x + pill._w + PILL_GAP_X
    end
    return n
end

-- Die Rubrikzeile ueber den Pillen: links "BOSSE · 4", rechts der
-- Vorsatz der Herkunft. Er ist die eine Stelle auf der Seite, die
-- sagt, wie fest die Liste steht - und im Tooltip, warum.
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

-- Ein kurzer Absatz unter der Bosszeile (Vollstaendigkeit) oder an
-- ihrer Stelle (kein Bestand). Gibt das y darunter zurueck.
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
local function DrawBosses(f, y, dungeon)
    local named = D.HasBosses(dungeon) and #dungeon.bosses or nil
    local total = D.BossCount(dungeon)

    -- Namen liegen vor.
    if named then
        local wings = D.Wings(dungeon)
        local completeness = CompletenessLine(dungeon)
        y = SectionHead(f, y, "Bosse · " .. named, D.BossSource(dungeon),
            { completeness })

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

        local pills = {}
        for _, boss in ipairs(shown) do
            pills[#pills + 1] = BossPill(f, dungeon, boss)
        end

        local top = y
        local n = LayoutPills(f, pills, top, ContentWidth() - 2 * PAD_X)
        y = y - n * PILL_H - (n - 1) * PILL_GAP_Y

        -- Beim Vergroessern des Fensters neu umbrechen; nur wenn die
        -- Zeilenzahl kippt, wird die Seite neu gezeichnet.
        f._relayout = function()
            local m = LayoutPills(f, pills, top, ContentWidth() - 2 * PAD_X)
            if m ~= n then Redraw() end
        end

        if completeness then
            y = Note(f, y - 6, completeness, "textFaint", 11)
        end
        return y

    -- Die Anzahl liegt vor, die Namen nicht.
    elseif total then
        y = SectionHead(f, y, "Kämpfe · " .. total, dungeon.countSource or S.COMMUNITY,
            { "Berichtet sind " .. total .. " Kämpfe. Ihre Namen sind es nicht - und "
              .. "die wenigen, die kursieren, ergeben keine Liste, sondern einen "
              .. "Ausschnitt." })
        local pills = {}
        for _ = 1, total do pills[#pills + 1] = GhostPill(f) end
        local top = y
        local n = LayoutPills(f, pills, top, ContentWidth() - 2 * PAD_X)
        y = y - n * PILL_H - (n - 1) * PILL_GAP_Y
        f._relayout = function()
            local m = LayoutPills(f, pills, top, ContentWidth() - 2 * PAD_X)
            if m ~= n then Redraw() end
        end

        local text = total .. " Kämpfe berichtet, Namen unbekannt."
        if dungeon.partial and dungeon.partial.names then
            text = text .. " Bisher benannt (" .. #dungeon.partial.names .. " von "
                .. total .. "): " .. table.concat(dungeon.partial.names, ", ") .. "."
        end
        return Note(f, y - 8, text, "textFaint", 11)

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

-- Passt neben den Titel einer Detailkarte noch ein Hinweis, ohne
-- ihn zu ueberlagern? Gerechnet mit derselben Kennzahl wie jede
-- andere Textbreite hier (0,60 em je Zeichen), und gegen die
-- SCHMALSTE Breite, die die Karte haben kann - mit offenem
-- Detailbereich sind das 192 px, und da passt neben "Aufstellung"
-- kein Satz mehr. Dann steht lieber keiner da als einer im Titel.
local function HintFits(title, titleSize, hint, hintSize)
    local inner = MinContentWidth() - 2 * PAD_X - 2 * CARD_PAD
    local need  = WeintCodex.Utf8Len(title or "") * titleSize * 0.60
                + 16
                + WeintCodex.Utf8Len(hint or "") * hintSize * 0.60
    return inner >= need
end

--------------------------------------------------
-- 3. Die Detailkarte
--------------------------------------------------
-- EINE Karte, mit Kopf und Koerper. Der Koerper ist ein Bildlauffeld:
-- passt der Inhalt, ist die Karte genau so hoch wie er; passt er
-- nicht, nimmt die Karte den Platz bis zum Fensterrand und rollt.
-- Das ist die eine Flaeche der Seite, die rollen darf - und sie
-- rollt nur, wenn der Bot mehr geschickt hat, als das Fenster zeigt.
--
-- opts:
--   eyebrow, title, titleFont, titleSize
--   hint               eine Zeile rechts neben dem Titel: was als
--                      NAECHSTES zu tun ist. Sie kostet keine Hoehe -
--                      aber Breite, und ob die da ist, entscheidet
--                      der Aufrufer mit HintFits().
--   onClose            Schliessen-Knopf rechts oben
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

    local titleSize = opts.titleSize or 20
    local title = card:CreateFontString(nil, "OVERLAY")
    title:SetFont(opts.titleFont or WeintCodex.Fonts.display, titleSize, "")
    title:SetPoint("TOPLEFT", card, "TOPLEFT", CARD_PAD, headY)
    title:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3])
    title:SetText(opts.title or "")

    -- DER WEGWEISER, den die Schlachtzugseite als eigene Karte hat
    -- ("Bosse - ein Klick auf einen davon zeigt hier ..."). Hier ist
    -- er eine Zeile im Kartenkopf: die Seite hat drei Flaechen, und
    -- eine vierte nur fuer einen Satz waere eine zu viel.
    if opts.hint then
        local hint = WeintCodex.Label(card, opts.hint,
            { color = "textFaint", size = 12, justify = "RIGHT" })
        hint:SetPoint("TOPRIGHT", card, "TOPRIGHT", -CARD_PAD, headY - 3)
        hint:SetWordWrap(false)
    end

    headY = headY - titleSize - 8

    if opts.onClose then
        local close = WeintCodex.CreateButton(card, {
            kind = "ghost", text = "\195\151", width = 28, height = 28, size = 15,
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
-- 3a. Ohne Boss: die Aufstellung
--------------------------------------------------

-- Kein Kennzeichen im Kopf: die Zeilen sagen die Plaetze selbst, und
-- "1 Tank · 1 Heiler · 3 DD" darueber sagte dasselbe noch einmal.
local ROSTER_HINT = "Ein Klick auf einen Boss zeigt ihn hier"

local function DrawRoster(f, y, dungeon)
    -- Der Wegweiser steht nur da, wo er stimmt UND wo er hinpasst:
    -- ohne Bossliste gibt es nichts anzuklicken, und in einer 192 px
    -- schmalen Karte gaebe es nichts zu lesen.
    local hint = (D.HasBosses(dungeon)
        and HintFits("Aufstellung", 15, ROSTER_HINT, 12)) and ROSTER_HINT or nil

    return DetailCard(f, y, {
        title      = "Aufstellung",
        titleFont  = WeintCodex.Fonts.sansSemi,
        titleSize  = 15,
        hint       = hint,
        build = function(inner, w)
            local endY = WeintCodex.RolePanel.Roster(inner, 0, dungeon, { width = w })
            return -endY
        end,
    })
end

--------------------------------------------------
-- 3b. Mit Boss: was ueber ihn berichtet ist
--------------------------------------------------

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
        eyebrow = table.concat(parts, " · "),
        title   = boss.name or "?",
        onClose = function()
            selectedBoss = nil
            Redraw()
        end,
        build = function(inner, w)
            local y = 0

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

            if boss.note then
                y = BodyHeading(inner, y, "Dazu")
                y = BodyText(inner, y, boss.note, w) - 14
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

    local blocks = {
        { type = "header", text = "Dungeon" },
        { type = "rows", rows = {
            { label = "Gebiet",       value = D.ZoneLabel(dungeon) or "—" },
            { label = "Stufe",        value = range or "unbekannt",
              valueColor = range and "textNormal" or "textFaint" },
            { label = "Gruppe",       value = dungeon.size .. " Spieler" },
            { label = "Bosse",        value = bossValue, valueColor = bossColor },
        }},
    }

    -- "Woher die Bossliste stammt" wie bei Schlachtzuegen - bisher
    -- stand die Begruendung nur im Tooltip des Vorsatzes an der
    -- Bosszeile, und ein Tooltip findet niemand, der nicht ohnehin
    -- schon vermutet, dass da einer ist.
    if source then
        blocks[#blocks + 1] = { type = "divider" }
        blocks[#blocks + 1] = { type = "header", text = "Woher die Bossliste stammt" }
        blocks[#blocks + 1] = { type = "text", text = S.Label(source),
            color = "warningBright", size = 11, gap = 4 }
        blocks[#blocks + 1] = { type = "text", text = S.Why(source), color = "textMuted" }
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

    inspectorShown = withInspector
    if withInspector then
        WeintCodex.Navigation.SetInspector(DungeonInspector(dungeon))
    else
        WeintCodex.Navigation.ClearInspector()
    end

    local y = DrawHead(f, dungeon)
    y = DrawBosses(f, y - 8, dungeon)

    local boss
    if selectedBoss then
        for _, candidate in ipairs(dungeon.bosses or {}) do
            if candidate.id == selectedBoss then boss = candidate end
        end
        if not boss then selectedBoss = nil end
    end

    if boss then
        y = DrawBossDetail(f, y - GAP, dungeon, boss)
    else
        y = DrawRoster(f, y - GAP, dungeon)
    end

    pageUsed = -y
end

-- ERST DER DETAILBEREICH WIE BEI SCHLACHTZUEGEN. Passt die Seite bei
-- der schmaleren Breite nicht ins Budget (viele Bosse, viele
-- Fluegel-Pillen - Stratholme, Blackrock Depths, Dire Maul, Scarlet
-- Monastery), faellt sie auf die volle Breite ohne Detailbereich
-- zurueck. Das ist dieselbe Messung, mit der load_test.lua das
-- Budget prueft (PageHeight gegen PageBudget), keine eigene
-- Schaetzung, die davon abweichen koennte - und deshalb kein neuer
-- Fall, den der Prueflauf nicht ohnehin schon durchspielt.
local function DrawDungeon(f, dungeon)
    DrawDungeonAt(f, dungeon, true)
    if pageUsed > WeintCodex.DungeonPages.PageBudget() then
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
