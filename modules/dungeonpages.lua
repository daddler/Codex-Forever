--------------------------------------------------
-- WeintCodex :: Dungeons
--
-- NEUNUNDZWANZIG INSTANZEN, DREI HERKUENFTE, EIN BAUM.
--
-- Bis 5.1.0.0 fuehrte diese Seite neun Dungeons ohne einen einzigen
-- Boss. Seither hat sich zweierlei geaendert, und nur eines davon
-- ist neue Information:
--
--   1. Die klassischen Dungeons gehoeren dazu. Forever ersetzt sie
--      nicht, es stellt neun daneben - wer auf Stufe 32 einen
--      Dungeon sucht, bekommt von einer Neunerliste die falsche
--      Antwort.
--   2. Fuer einen Teil der Forever-Dungeons liegen Bossnamen vor.
--      NICHT von Blizzard, sondern aus Beta-Berichten. Sie stehen
--      hier, und daneben steht, woher sie kommen.
--
-- DIE SEITE HAT DESHALB EINE AUFGABE MEHR ALS FRUEHER: sie muss
-- sichtbar machen, wie fest etwas steht. Eine Bossliste aus einem
-- Forenbericht sieht auf einer Oberflaeche genauso aus wie eine aus
-- dem Handbuch - es sei denn, die Oberflaeche sagt den Unterschied.
-- Das tut sie hier an drei Stellen: im Kopf (Herkunftszeile), auf
-- der Bosskarte (warum es nicht feststeht) und im Detailbereich
-- (der lange Text dazu).
--
-- WARUM DER BAUM SICH STAFFELT. Neunundzwanzig Instanzen mit
-- Stufenzeile sind 1334 px, die Listenspalte hat 716. Die Seite
-- rechnet ihren Baum deshalb VOR dem Bauen durch
-- (Navigation.Fits) und faellt auf eine Ansicht zurueck, die passt.
-- Das ist genau der Zweck, fuer den MeasureSidebar gebaut wurde:
-- eine Spalte, die still ueberlaeuft, sieht nicht aus wie ein
-- Fehler, sondern wie eine Funktion, die es nicht gibt.
--
-- WAS HIER WEITERHIN NICHT STEHT:
--
--   * KEINE ERFUNDENE TAKTIK. Positionshinweise ("patrouilliert den
--     ersten Gang") stehen da, wo sie berichtet sind. Was eine Rolle
--     an einem Kampf tut, kommt vom Discord-Bot oder gar nicht.
--   * KEINE KARTENBILDER. Siehe MapNote() weiter unten - das ist
--     eine eigene Entscheidung mit einer eigenen Begruendung.
--   * KEINE GESPEICHERTE ID. Fuenfergruppen haben keinen
--     Wochen-Lockout.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.DungeonPages = {}

local C = WeintCodex.Colors
local D = WeintCodex.DungeonData
local S = WeintCodex.Sources

local page         = nil
local rows         = {}
local selectedId   = nil
local selectedBoss = nil
local selectedWing = nil
local openBracket  = 1
local browsing     = true
local showSummons  = false
local building     = false

local function ClearRows()
    for _, row in ipairs(rows) do row:Hide() end
    wipe(rows)
end

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
-- dafuer ist `boss.position` da.

local function MapNote(dungeon)
    if D.IsLegacy(dungeon) then
        return "Karten zeigt WeintCodex keine - die des Spiels gehören "
            .. "Blizzard. Wo ein Boss steht, steht als Text an ihm."
    end
    if dungeon.mapArt == true then
        return "Für diesen Dungeon liegt im Beta-Client Kartenmaterial. "
            .. "WeintCodex zeigt es nicht: es gehört Blizzard, und welchen "
            .. "Texturpfad Forever dafür vergibt, ist unbekannt. Wo ein Boss "
            .. "steht, steht als Text an ihm."
    end
    if dungeon.mapArt == false then
        return "Für diesen Dungeon liegt im Beta-Client noch keine Karte - "
            .. "auch nicht im Spiel. Ohne Karte und ohne Bossliste bleibt "
            .. "diese Seite bei dem, was angekündigt ist."
    end
    return nil
end

--------------------------------------------------
-- Herkunft als Text
--------------------------------------------------

-- Die kurze Zeile: "Unbestaetigt - Beta-Berichte der Community".
local function SourceLine(dungeon)
    return S.Label(D.BossSource(dungeon))
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
        return "Diese Liste ist UNVOLLSTAENDIG: es sind " .. named .. " Kämpfe "
            .. "bekannt, wie viele es insgesamt sind, nicht."
    end
    if D.OrderKnown(dungeon) == false then
        return named .. " Kämpfe sind bekannt, ihre Reihenfolge nicht."
    end
    return nil
end

--------------------------------------------------
-- Seite
--------------------------------------------------

local function BuildPage()
    if page then return page end
    local cp = WeintCodex.ContentPanel
    local f  = CreateFrame("Frame", nil, cp)
    f:SetAllPoints(cp)
    page = f
    return f
end

--------------------------------------------------
-- Detailbereich: der Dungeon selbst
--------------------------------------------------

local function InstanceInspector(dungeon)
    local range = D.LevelRange(dungeon)
    local level = MyLevel()
    local fits  = D.FitsLevel(dungeon, level)

    -- Vier Zustaende, vier Texte. Ohne Stufe vom Client steht da
    -- "nicht bekannt" und nicht "passt nicht".
    local levelValue, levelColor
    if level == nil then
        levelValue, levelColor = "noch nicht bekannt", "textFaint"
    elseif fits == true then
        levelValue, levelColor = level .. " · passt", "successBright"
    elseif level < (dungeon.minLevel or 0) then
        levelValue, levelColor = level .. " · zu niedrig", "warningBright"
    else
        levelValue, levelColor = level .. " · darüber", "textMuted"
    end

    -- Die Bosszeile unterscheidet drei Dinge, die frueher alle
    -- "noch nicht bekannt" hiessen: benannte Kaempfe, gezaehlte
    -- Kaempfe, und gar nichts.
    local named  = D.HasBosses(dungeon) and #dungeon.bosses or nil
    local total  = D.BossCount(dungeon)
    local bossValue, bossColor
    if named and total and named < total then
        bossValue, bossColor = named .. " von " .. total, "warningBright"
    elseif named then
        bossValue, bossColor = tostring(named), "textNormal"
    elseif total then
        bossValue, bossColor = total .. " · Namen unbekannt", "warningBright"
    else
        bossValue, bossColor = "noch nicht bekannt", "textFaint"
    end

    local blocks = {
        { type = "header", text = D.IsLegacy(dungeon) and "Dungeon (Classic)" or "Dungeon" },
        { type = "rows", rows = {
            { label = "Gebiet",       value = D.ZoneLabel(dungeon) or "—" },
            { label = "Stufen",       value = range or "noch nicht bekannt",
              valueColor = range and "textNormal" or "textFaint" },
            { label = "Gruppengröße", value = dungeon.size .. " Spieler" },
            { label = "Inhalt",       value = dungeon.release or "—" },
            { label = "Bosse",        value = bossValue, valueColor = bossColor },
            { label = "Deine Stufe",  value = levelValue, valueColor = levelColor },
        }},
    }

    if dungeon.theme then
        blocks[#blocks + 1] = { type = "divider" }
        blocks[#blocks + 1] = { type = "text", text = dungeon.theme, color = "textMuted" }
    end

    -- DER LANGE HERKUNFTSTEXT. Er steht im Detailbereich und nicht
    -- auf der Seite, weil der Detailbereich die eine Stelle ist, die
    -- rollen darf - und weil er nur den interessiert, der nachfragt.
    local source = D.BossSource(dungeon)
    if source then
        blocks[#blocks + 1] = { type = "divider" }
        blocks[#blocks + 1] = { type = "header", text = "Woher die Bossliste stammt" }
        blocks[#blocks + 1] = { type = "text", text = S.Label(source) or source.label,
                                color = "warningBright" }
        blocks[#blocks + 1] = { type = "text", text = S.Why(source) or "", color = "textDim" }
        local completeness = CompletenessLine(dungeon)
        if completeness then
            blocks[#blocks + 1] = { type = "text", text = completeness, color = "textDim" }
        end
    end

    if dungeon.conflict then
        blocks[#blocks + 1] = { type = "divider" }
        blocks[#blocks + 1] = { type = "header", text = "Widerspruch in den Quellen" }
        blocks[#blocks + 1] = { type = "text", text = dungeon.conflict, color = "textDim" }
    end

    local mapNote = MapNote(dungeon)
    if mapNote then
        blocks[#blocks + 1] = { type = "divider" }
        blocks[#blocks + 1] = { type = "header", text = "Karten und Bilder" }
        blocks[#blocks + 1] = { type = "text", text = mapNote, color = "textDim" }
    end

    blocks[#blocks + 1] = { type = "divider" }
    for _, block in ipairs(WeintCodex.RolePanel.InstanceBlocks(dungeon)) do
        blocks[#blocks + 1] = block
    end

    return blocks
end

--------------------------------------------------
-- Eine Karte mit Titel, Text und optionalem Zusatz
--------------------------------------------------
-- Dreimal gebraucht auf dieser Seite (Bosse, Beschwoerung,
-- Widerspruch), deshalb einmal gebaut.

-- WIE HOCH EINE KARTE WIRD, UND WARUM DAS AUSGERECHNET WIRD.
--
-- Beim kleinsten zulaessigen Fenster ist der Inhaltsbereich keine
-- Seite, sondern eine rund 212 px schmale Spalte - da passen etwa
-- vierunddreissig Zeichen in eine Zeile. Eine Karte mit fester Hoehe
-- und einem Text, dessen Laenge aus dem Bestand kommt, laeuft dort
-- ueber, und ein Text, der unter dem Kartenrand weiterlaeuft, sieht
-- nicht aus wie ein Fehler, sondern wie ein Satz, der aufhoert.
--
-- Dieselbe Gefahr und dieselbe Antwort wie bei RolePanel.BossCards:
-- rechnen, und im Zweifel kuerzen. Der ungekuerzte Text steht im
-- Detailbereich - das ist die eine Stelle, die rollen darf.
local LINE_H      = 16
local NARROW_COLS = 34   -- Zeichen je Zeile beim schmalsten Inhaltsbereich
local MAX_LINES   = 9

-- WAS AUF DER BOSSSEITE FUER DIE DREI ROLLENKARTEN RESERVIERT WIRD.
-- Sie stehen UNTER der Karte und messen sich selbst
-- (RolePanel.BossCards) - ihre Hoehe steht also erst fest, wenn die
-- Karte darueber schon haengt. Statt sie zweimal zu zeichnen,
-- bekommt die Karte oben einen Deckel, und der Prueflauf rechnet die
-- fertige Seite gegen das Budget: laeuft sie ueber, ist diese Zahl
-- zu klein und nicht die Karte zu lang.
local ROLE_CARDS_RESERVE = 260

-- Zeichenweise, nicht byteweise: ein Umlaut, den man in der Mitte
-- zerschneidet, wird im Spiel zu einem leeren Kaestchen.
local function EstimateLines(text)
    local lines = 0
    for segment in (tostring(text or "") .. "\n"):gmatch("(.-)\n") do
        local len = WeintCodex.Utf8Len(segment)
        lines = lines + math.max(1, math.ceil(len / NARROW_COLS))
    end
    return lines
end

-- WAS DIE SEITE UEBERHAUPT ZUR VERFUEGUNG HAT. Dieselbe Rechnung wie
-- fuer die Listenspalte (Navigation.SubNavBudget), nur fuer den
-- Inhaltsbereich - und aus demselben Grund: was hier unten
-- rausfaellt, faellt lautlos raus.
local function ContentBudget()
    local limits = WeintCodex.WindowLimits or {}
    return (limits.minH or 780) - (WeintCodex.Metrics.TITLEBAR_H or 40)
        - 2 * WeintCodex.Metrics.PAD_Y
end

-- Wie hoch die zuletzt gezeichnete Seite geworden ist. Der Prueflauf
-- haelt das gegen ContentBudget() - siehe .github/tests/load_test.lua.
local pageUsed = 0

function WeintCodex.DungeonPages.PageHeight()
    return pageUsed
end

function WeintCodex.DungeonPages.PageBudget()
    return ContentBudget()
end

-- DIE HOEHENRECHNUNG STEHT AN EINER STELLE, UND DAS IST DIE LEHRE
-- AUS DEM ERSTEN ANLAUF: sie stand an zweien (Aufrufer rechnete
-- Zeilen, Karte rechnete Hoehe) und lief um 26 px auseinander - genau
-- um die Fussnote, die eine gekuerzte Karte zusaetzlich braucht. Die
-- Seite lief damit unten aus dem Fenster.
--
-- Der Aufrufer sagt jetzt, WIE VIEL PLATZ da ist. Wie viele Zeilen
-- daraus werden, entscheidet die Karte.
--
-- Die Fussnotenzeile wird IMMER mitgerechnet, auch ohne Fussnote:
-- ob gekuerzt wird, stellt sich erst beim Messen heraus, und eine
-- Karte, die dann 26 px mehr braucht als zugeteilt, ist derselbe
-- Fehler noch einmal.
local function InfoCard(f, y, opts)
    local text     = opts.text or ""
    local overhead = 16 + 26                    -- Rand + Titelzeile
        + (opts.badge and 18 or 0)
        + 26                                    -- Fussnotenzeile, immer
        + 16

    local maxLines = opts.maxHeight
        and math.max(1, math.floor((opts.maxHeight - overhead) / LINE_H))
        or MAX_LINES

    local lines = EstimateLines(text)
    local cut   = false
    if lines > maxLines then
        text  = WeintCodex.Truncate(text, maxLines * NARROW_COLS)
        lines = maxLines
        cut   = true
    end

    local height = overhead + lines * LINE_H

    local card = WeintCodex.CreateSurface(f, {
        tone = "plain", radius = 14, backdrop = "bgDark",
    })
    card:SetPoint("TOPLEFT",  f, "TOPLEFT",   WeintCodex.Metrics.PAD_X, y)
    card:SetPoint("TOPRIGHT", f, "TOPRIGHT", -WeintCodex.Metrics.PAD_X, y)
    card:SetHeight(height)

    local title = card:CreateFontString(nil, "OVERLAY")
    title:SetFont(WeintCodex.Fonts.sansSemi, 14, "")
    title:SetPoint("TOPLEFT", card, "TOPLEFT", 20, -16)
    title:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3])
    title:SetText(opts.title or "")

    local top = -42

    -- Die Herkunftszeile steht UEBER dem Text und nicht darunter:
    -- wer die Liste liest, soll vorher wissen, worauf er schaut.
    if opts.badge then
        local badge = WeintCodex.Eyebrow(card, opts.badge,
            { color = opts.badgeColor or "warningBright", size = 10 })
        badge:SetPoint("TOPLEFT", card, "TOPLEFT", 20, top)
        top = top - 18
    end

    local lbl = WeintCodex.Label(card, text, { color = "textMuted", size = 13 })
    lbl:SetPoint("TOPLEFT",  card, "TOPLEFT",  20, top)
    lbl:SetPoint("TOPRIGHT", card, "TOPRIGHT", -20, top)

    -- VERLOREN GEHT NICHTS, UND DIE KARTE SAGT AUCH, DASS GEKUERZT
    -- WURDE. Eine stille Kuerzung ist schlimmer als eine sichtbare:
    -- sie liest sich wie der ganze Text.
    local note = opts.note
    if cut then
        note = (note and (note .. "  ·  ") or "") .. "gekürzt – vollständig rechts"
    end
    if note then
        local n = WeintCodex.Eyebrow(card, note, { color = "textFaint", size = 10 })
        n:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 20, 14)
    end

    rows[#rows + 1] = card
    return card
end

--------------------------------------------------
-- Der Dungeon
--------------------------------------------------

local function DrawInstance(f, dungeon)
    ClearRows()

    local PAD_X = WeintCodex.Metrics.PAD_X
    local PAD_Y = WeintCodex.Metrics.PAD_Y
    local GAP   = WeintCodex.Metrics.GAP

    local range  = D.LevelRange(dungeon)
    local named  = D.HasBosses(dungeon) and #dungeon.bosses or nil
    local total  = D.BossCount(dungeon)

    local stats = {
        { key = "size", label = "Gruppe", value = dungeon.size, tone = "textNormal" },
    }
    if named then
        stats[#stats + 1] = { key = "bosses", label = "Bosse", value = named,
            tone = D.BossesComplete(dungeon) and "textNormal" or "warningBright" }
    elseif total then
        stats[#stats + 1] = { key = "bosses", label = "Kämpfe", value = total,
            tone = "warningBright" }
    end

    local head = WeintCodex.PageHead(f, {
        eyebrow   = (D.IsLegacy(dungeon) and "Classic · " or "")
                 .. (D.ZoneLabel(dungeon) or "Dungeon"),
        title     = dungeon.name,
        titleSize = 28,
        sub       = range and ("Stufe " .. range) or "Stufenbereich noch nicht bekannt",
        subColor  = range and "textMuted" or "textFaint",
        height    = 92,
        stats     = stats,
    })
    rows[#rows + 1] = head

    local y = -(PAD_Y + 92)

    local roleCard, roleH = WeintCodex.RolePanel.Card(f, dungeon)
    roleCard:SetPoint("TOPLEFT",  f, "TOPLEFT",   PAD_X, y)
    roleCard:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PAD_X, y)
    rows[#rows + 1] = roleCard
    y = y - roleH - GAP

    --------------------------------------------------
    -- Die Bosskarte: vier Zustaende
    --------------------------------------------------

    local title, text, badge, note

    if named then
        title = "Bosse"
        badge = SourceLine(dungeon)
        local wings = D.Wings(dungeon)
        text = named .. " Kämpfe stehen links in der Spalte"
            .. (wings and (", nach " .. #wings .. " Flügeln geteilt") or "")
            .. ". Ein Klick darauf zeigt hier, wo der Boss steht und was für "
            .. "Tank, Heiler und Schadensausteiler zu beachten ist."
        note = CompletenessLine(dungeon)

    elseif total then
        -- DER FALL CITY OF DALARAN: die Anzahl ist bekannt, die
        -- Namen sind es nicht. Das ist eine Auskunft und kein
        -- Leerzustand - "neun Kaempfe" beantwortet die Frage "wie
        -- lang wird das?" bereits.
        title = "Kämpfe"
        badge = S.Label(dungeon.countSource or S.COMMUNITY)
        text  = "Berichtet sind " .. total .. " Kämpfe. Ihre Namen sind es "
             .. "nicht - und die wenigen, die kursieren, ergeben keine Liste, "
             .. "sondern einen Ausschnitt."
        if dungeon.partial and dungeon.partial.names then
            text = text .. "\n\nBisher benannt (" .. #dungeon.partial.names
                .. " von " .. total .. "): "
                .. table.concat(dungeon.partial.names, ", ") .. "."
        end
        note = "Reihenfolge unbekannt"

    elseif dungeon.conflict then
        -- DER FALL EXCAVATION SITE UND BLACKMAW HOLD. Zwei Quellen,
        -- die einander widersprechen, ergeben keine Liste - sie
        -- ergeben einen offenen Punkt, und der steht hier als
        -- solcher. Das ist mehr wert als Schweigen: wer die
        -- kursierende Liste anderswo gesehen hat, erfaehrt hier,
        -- warum sie hier fehlt.
        title = "Bosse"
        badge = "Quellen widersprechen sich"
        text  = dungeon.conflict
        note  = "Forever erscheint am 04.11.2026"

    else
        title = "Bosse"
        text  = "Welche Bosse in " .. dungeon.name .. " stehen, hat Blizzard "
             .. "nicht veröffentlicht, und aus der Beta wird dazu nichts "
             .. "berichtet. WeintCodex trägt die Liste nach, wenn es eine "
             .. "gibt, und erfindet sie bis dahin nicht."
        note  = "Forever erscheint am 04.11.2026"
    end

    local summonable = D.SummonableBosses(dungeon)

    -- DER PLATZ WIRD GETEILT, NICHT GESCHAETZT. Was nach Kopf und
    -- Aufstellung uebrig ist, geht an die Bosskarte - und wenn eine
    -- Beschwoerungskarte folgt, an beide zur Haelfte. Feste Hoehen
    -- waeren hier das Problem: wie lang der Text wird, entscheidet
    -- der Bestand.
    local space = ContentBudget() + y - PAD_Y
    if #summonable > 0 then space = math.floor((space - GAP) / 2) end

    local bossCard = InfoCard(f, y, {
        title = title, text = text, badge = badge, note = note,
        maxHeight = space,
    })
    y = y - bossCard:GetHeight() - GAP

    --------------------------------------------------
    -- Beschwoerbare Zusatzbosse
    --------------------------------------------------
    -- Sie bekommen eine eigene Karte und nicht eine Zeile in der
    -- Liste. Grund: sie stehen nicht da, bis jemand etwas tut - wer
    -- das nicht weiss, laeuft an ihnen vorbei, und genau das ist die
    -- Auskunft, die eine Bossliste nicht gibt.

    if #summonable > 0 then
        local lines = {}
        for _, boss in ipairs(summonable) do
            lines[#lines + 1] = boss.name .. " — " .. (boss.summon.text or "")
        end
        local summonCard = InfoCard(f, y, {
            title  = #summonable == 1 and "Beschwörbarer Zusatzboss"
                  or ("Beschwörbare Zusatzbosse (" .. #summonable .. ")"),
            text   = table.concat(lines, "\n\n"),
            badge    = S.Label(summonable[1].summon.source),
            maxHeight = ContentBudget() + y - PAD_Y,
        })
        y = y - summonCard:GetHeight()
    end

    pageUsed = -y + PAD_Y
    WeintCodex.Navigation.SetInspector(InstanceInspector(dungeon))
end

--------------------------------------------------
-- Ein Boss
--------------------------------------------------

local function BossInspector(dungeon, boss)
    local blocks = {
        { type = "header", text = "Boss" },
        { type = "rows", rows = {
            { label = "Instanz", value = dungeon.name },
            { label = "Flügel", value = boss.wing or "—",
              valueColor = boss.wing and "textNormal" or "textFaint" },
            -- DIE PULLNUMMER STEHT NUR DA, WO DIE REIHENFOLGE
            -- BEKANNT IST. In den Ruins of Lordaeron liegen sieben
            -- Namen vor und keine Folge; "3 von 7" waere dort eine
            -- Zahl, die niemand kennt.
            { label = "Reihenfolge",
              value = boss.order and (boss.order .. " von " .. #dungeon.bosses)
                   or "nicht bekannt",
              valueColor = boss.order and "textNormal" or "textFaint" },
            { label = "Art", value = boss.summon and "nur beschworen"
                   or (boss.optional and "optional" or "auf dem Weg"),
              valueColor = boss.summon and "warningBright" or "textNormal" },
        }},
    }

    if boss.nameAlt then
        blocks[#blocks + 1] = { type = "divider" }
        blocks[#blocks + 1] = { type = "header", text = "Zweiter Name" }
        blocks[#blocks + 1] = { type = "text", color = "textDim",
            text = "Derselbe Kampf wird auch als \"" .. boss.nameAlt .. "\" "
                .. "berichtet. Welchen Namen der Client vergibt, ist offen - "
                .. "WeintCodex sucht Bossnotizen unter beiden." }
    end

    if boss.position then
        blocks[#blocks + 1] = { type = "divider" }
        blocks[#blocks + 1] = { type = "header", text = "Wo er steht" }
        blocks[#blocks + 1] = { type = "text", text = boss.position, color = "textMuted" }
    end

    if boss.note then
        blocks[#blocks + 1] = { type = "divider" }
        blocks[#blocks + 1] = { type = "header", text = "Dazu" }
        blocks[#blocks + 1] = { type = "text", text = boss.note, color = "textMuted" }
    end

    if boss.summon then
        blocks[#blocks + 1] = { type = "divider" }
        blocks[#blocks + 1] = { type = "header", text = "Beschwören" }
        blocks[#blocks + 1] = { type = "text", text = boss.summon.text, color = "textMuted" }
        blocks[#blocks + 1] = { type = "text", color = "textFaint",
            text = S.Label(boss.summon.source) or "" }
    end

    blocks[#blocks + 1] = { type = "divider" }
    for _, block in ipairs(WeintCodex.RolePanel.BossBlocks(dungeon, boss)) do
        blocks[#blocks + 1] = block
    end

    return blocks
end

local function DrawBoss(f, dungeon, boss)
    ClearRows()

    local PAD_X = WeintCodex.Metrics.PAD_X
    local PAD_Y = WeintCodex.Metrics.PAD_Y
    local GAP   = WeintCodex.Metrics.GAP

    local stats = {}
    if boss.order then
        stats[#stats + 1] = { key = "pull", label = "Pull",
            value = boss.order .. "/" .. #dungeon.bosses, tone = "textNormal" }
    end

    local head = WeintCodex.PageHead(f, {
        eyebrow   = dungeon.name .. (boss.wing and (" · " .. boss.wing) or ""),
        title     = boss.name or "?",
        titleSize = 26,
        sub       = boss.summon and "Erscheint nur, wenn die Gruppe ihn holt"
                 or (boss.optional and "Optional - nicht auf dem Hauptweg"
                 or (D.ZoneLabel(dungeon) or "")),
        subColor  = boss.summon and "warningBright" or "textMuted",
        height    = 86,
        stats     = stats,
    })
    rows[#rows + 1] = head

    local y = -(PAD_Y + 86) - (GAP - 8)

    -- Die Beschwoerung steht UEBER den Rollenkarten: wer den Boss
    -- nicht beschwoeren kann, braucht nicht zu wissen, wie man ihn
    -- tankt.
    if boss.summon then
        local card = InfoCard(f, y, {
            title  = "So kommt er",
            text   = boss.summon.text,
            badge    = S.Label(boss.summon.source),
            maxHeight = ContentBudget() + y - PAD_Y - ROLE_CARDS_RESERVE,
        })
        y = y - card:GetHeight() - GAP
    elseif boss.position then
        local card = InfoCard(f, y, {
            title    = "Wo er steht",
            text     = boss.position,
            maxHeight = ContentBudget() + y - PAD_Y - ROLE_CARDS_RESERVE,
        })
        y = y - card:GetHeight() - GAP
    end

    -- BossCards liefert die Karten UND das y darunter - nur damit
    -- laesst sich sagen, wie hoch die Seite geworden ist. Wie hoch
    -- sie werden DARF, prueft .github/tests/load_test.lua.
    local cards, endY = WeintCodex.RolePanel.BossCards(f, y, dungeon, boss)
    for _, card in ipairs(cards) do rows[#rows + 1] = card end

    pageUsed = -endY + PAD_Y
    WeintCodex.Navigation.SetInspector(BossInspector(dungeon, boss))
end

--------------------------------------------------
-- Uebersicht: alles, was sich beschwoeren laesst
--------------------------------------------------
-- Verstreut ueber neunundzwanzig Dungeons waere diese Auskunft
-- keine. Deshalb hat sie eine eigene Seite, erreichbar aus der
-- Liste.

local function DrawSummonOverview(f)
    ClearRows()

    local PAD_X = WeintCodex.Metrics.PAD_X
    local PAD_Y = WeintCodex.Metrics.PAD_Y
    local GAP   = WeintCodex.Metrics.GAP

    local all = D.AllSummonable()

    local head = WeintCodex.PageHead(f, {
        eyebrow   = "Dungeons",
        title     = "Beschwörbare Zusatzbosse",
        titleSize = 28,
        sub       = "Gegner, die nur erscheinen, wenn die Gruppe etwas dafür tut",
        subColor  = "textMuted",
        height    = 92,
        stats     = { { key = "n", label = "Bosse", value = #all, tone = "textNormal" } },
    })
    rows[#rows + 1] = head

    local y = -(PAD_Y + 92)

    local lines = {}
    for _, entry in ipairs(all) do
        lines[#lines + 1] = entry.boss.name .. "  ·  " .. entry.dungeon.name
    end

    local card = InfoCard(f, y, {
        title = "Wo es welche gibt",
        text  = (#lines > 0) and table.concat(lines, "\n")
             or "Keiner bekannt.",
        note     = "Ein Klick auf den Dungeon links zeigt, wie er beschworen wird",
        maxHeight = ContentBudget() + y - PAD_Y,
    })

    -- DIE WICHTIGE UNTERSCHEIDUNG, UND SIE WIRD STAENDIG
    -- VERWECHSELT: Spieler beschwoeren und Bosse beschwoeren sind
    -- zwei verschiedene Dinge, und nur eines davon geht in Forever
    -- ueberhaupt.
    local blocks = {
        { type = "header", text = "Zwei Arten von Beschwörung" },
        { type = "text", color = "textMuted",
          text = "BOSSE beschwören: " .. #all .. " Gegner im ganzen Spiel "
              .. "erscheinen erst, wenn die Gruppe etwas dafür tut - ein "
              .. "Kohlenbecken entzündet, einen Gegenstand einsetzt, eine "
              .. "Questreihe abschließt." },
        { type = "divider" },
        { type = "text", color = "textMuted",
          text = "SPIELER beschwören: " .. (D.SUMMONING.players or "") },
        { type = "text", color = "textFaint",
          text = S.Label(D.SUMMONING.source) or "" },
    }
    pageUsed = -y + card:GetHeight() + PAD_Y
    WeintCodex.Navigation.SetInspector(blocks)
end

--------------------------------------------------
-- Der Baum links
--------------------------------------------------
-- ZWEI ANSICHTEN, UND DIE SEITE RECHNET AUS, WELCHE PASST.
--
--   BLAETTERN  Stufenabschnitte als Koepfe, darunter die Instanzen
--              des offenen Abschnitts. So sucht man einen Dungeon:
--              nach Stufe, nicht nach Namen.
--   VERTIEFEN  Eine Ruecksprungzeile, die gewaehlte Instanz, ihre
--              Fluegel und deren Kaempfe.
--
-- Wo beides zusammen passt, wird beides gezeigt (Navigation.Fits
-- rechnet es nach). Wo nicht - und das ist bei den grossen
-- klassischen Instanzen der Regelfall -, vertieft die Spalte.

local BuildTree
local BossItem

local function InstanceItem(f, dungeon, withBosses)
    return {
        label  = dungeon.name,
        status = D.LevelRange(dungeon),
        onClick = function()
            local changed = (selectedId ~= dungeon.id)
            selectedId   = dungeon.id
            selectedBoss = nil
            showSummons  = false
            if changed then selectedWing = nil end
            WeintCodex.SetBreadcrumb("Dungeons", dungeon.name)
            DrawInstance(f, dungeon)
            if not building and (changed or browsing) then
                browsing = false
                BuildTree(f)
            end
        end,
    }
end

local function BossItems(f, dungeon, into)
    local wings = D.Wings(dungeon)

    if wings then
        if selectedWing == nil then selectedWing = wings[1] end
        local known = false
        for _, wing in ipairs(wings) do
            if wing == selectedWing then known = true end
        end
        if not known then selectedWing = wings[1] end

        for _, wing in ipairs(wings) do
            local count = #D.BossesInWing(dungeon, wing)
            into[#into + 1] = {
                isGroup = true,
                label   = wing,
                count   = count,
                open    = (wing == selectedWing),
                onClick = function()
                    selectedWing = wing
                    selectedBoss = nil
                    if not building then BuildTree(f) end
                end,
            }
            if wing == selectedWing then
                for _, boss in ipairs(D.BossesInWing(dungeon, wing)) do
                    into[#into + 1] = BossItem(f, dungeon, boss)
                end
            end
        end
    else
        for _, boss in ipairs(dungeon.bosses or {}) do
            into[#into + 1] = BossItem(f, dungeon, boss)
        end
    end
end

--------------------------------------------------

BossItem = function(f, dungeon, boss)
    -- Das Kennzeichen rechts sagt, WAS fuer ein Eintrag das ist,
    -- und es gibt drei Sorten. "BESCHWOEREN" schlaegt "TIPPS":
    -- dass der Boss ohne Zutun gar nicht dasteht, ist die
    -- dringendere Auskunft.
    local mark, markColor
    if boss.summon then
        mark, markColor = "Beschwören", "warningBright"
    elseif boss.optional then
        mark, markColor = "Optional", "textFaint"
    elseif WeintCodex.Roles.HasTips(boss.name) then
        mark, markColor = "Tipps", "textMuted"
    end

    return {
        label     = boss.name,
        indent    = true,
        mark      = mark,
        markColor = markColor,
        onClick   = function()
            selectedBoss = boss.id
            showSummons  = false
            WeintCodex.SetBreadcrumb("Dungeons", dungeon.name, boss.name)
            DrawBoss(f, dungeon, boss)
        end,
    }
end

--------------------------------------------------

BuildTree = function(f)
    building = true

    local current = D.Get(selectedId) or D.AllInstances()[1]
    selectedId = current and current.id or nil
    openBracket = D.BracketIndexOf(selectedId)

    local brackets = D.Brackets()

    -- Die Uebersicht der beschwoerbaren Bosse steht ganz oben und
    -- nicht in einem Abschnitt: sie gehoert zu keiner Stufe.
    local function SummonRow()
        return {
            label   = "Beschwörbare Zusatzbosse",
            status  = tostring(#D.AllSummonable()) .. " im ganzen Spiel",
            onClick = function()
                showSummons  = true
                selectedBoss = nil
                WeintCodex.SetBreadcrumb("Dungeons", "Beschwörbare Zusatzbosse")
                DrawSummonOverview(f)
            end,
        }
    end

    -- ANSICHT 1: blaettern, mit den Bossen der gewaehlten Instanz,
    -- falls sie noch dazupassen.
    local function BrowseItems(withBosses)
        local items = { SummonRow() }
        for index, bucket in ipairs(brackets) do
            items[#items + 1] = {
                isGroup = true,
                label   = bucket.label,
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
                        WeintCodex.SetBreadcrumb("Dungeons", first.name)
                        DrawInstance(f, first)
                    end
                    browsing = true
                    if not building then BuildTree(f) end
                end,
            }
            if index == openBracket then
                for _, dungeon in ipairs(bucket.dungeons) do
                    items[#items + 1] = InstanceItem(f, dungeon)
                    if withBosses and dungeon.id == selectedId then
                        BossItems(f, dungeon, items)
                    end
                end
            end
        end
        return items
    end

    -- ANSICHT 2: vertiefen.
    local function FocusItems()
        local items = {
            {
                label   = "‹  Alle Dungeons",
                onClick = function()
                    browsing     = true
                    selectedBoss = nil
                    if not building then BuildTree(f) end
                end,
            },
            InstanceItem(f, current),
        }
        BossItems(f, current, items)
        return items
    end

    local items
    if showSummons then
        items = BrowseItems(false)
    elseif browsing then
        -- Passt der Baum MIT Bossen, zeigt er sie: ein Klick
        -- weniger, und kein Verlust.
        local withBosses = BrowseItems(true)
        items = WeintCodex.Navigation.Fits(withBosses) and withBosses
             or BrowseItems(false)
    else
        items = FocusItems()
        -- DER RUECKFALL, DEN ES HOFFENTLICH NIE BRAUCHT. Traegt eine
        -- Instanz eines Tages mehr Kaempfe, als selbst die vertiefte
        -- Ansicht fasst, waere die Spalte still uebergelaufen. Dann
        -- lieber ohne Bossliste als mit einer unsichtbaren - und der
        -- Prueflauf faellt vorher durch.
        if not WeintCodex.Navigation.Fits(items) then
            items = { items[1], items[2] }
        end
    end

    -- Welche Zeile ist die aktive? Ueber den Inhalt gesucht und
    -- nicht mitgezaehlt: Gruppenkoepfe zaehlen in sidebarItems nicht
    -- mit, ein mitlaufender Zaehler saesse also daneben.
    local active, cursor = 1, 0
    for _, item in ipairs(items) do
        if not item.isGroup then
            cursor = cursor + 1
            if showSummons then
                if item.status and item.label == "Beschwörbare Zusatzbosse" then
                    active = cursor
                end
            elseif selectedBoss then
                if item.indent then
                    for _, boss in ipairs(current.bosses or {}) do
                        if boss.id == selectedBoss and boss.name == item.label then
                            active = cursor
                        end
                    end
                end
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
    browsing     = true

    if bossId then
        for _, boss in ipairs(dungeon.bosses or {}) do
            if boss.id == bossId then
                selectedBoss = bossId
                selectedWing = boss.wing
                browsing     = false
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

    local f = BuildPage()
    f:Show()

    BuildTree(f)
end
