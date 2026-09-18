--------------------------------------------------
-- WeintCodex :: Gruppencheck
--------------------------------------------------
-- Die Ausruestung der ganzen Gruppe bzw. des ganzen Raids auf einen
-- Blick. Beantwortet genau die Fragen, die vor einem Pull zaehlen und
-- die man sonst vierundzwanzig Mal einzeln stellt: traegt jeder etwas
-- auf jedem Platz, ist etwas davon zerbrochen, und wie weit liegen die
-- Gegenstandsstufen auseinander?
--
-- DIESE SEITE BEWERTET NICHT, SIE ZAEHLT. Ob eine Ausruestung "gut"
-- ist, entscheidet sie nicht - dafuer braeuchte es Wertungen, die es
-- fuer Forever nicht gibt. "Platz leer" und "Gegenstand zerbrochen"
-- sind unstrittig; alles darueber hinaus waere ein Vorwurf.
--
-- WAS FRUEHER HIER STAND: in der Fassung fuer Mists of Pandaria zaehlte
-- diese Seite fehlende Verzauberungen und leere Sockel. Beides gibt es
-- in dieser Fassung nicht (siehe modules/charakter.lua) - und beides
-- haette, aus MoP uebernommen, jedem Spieler Maengel vorgeworfen, die
-- sein Spiel gar nicht kennt.
--
-- Alles, was diese Seite liest, steckt im Item-Link und in der
-- Haltbarkeitsabfrage. Kein Tooltip-Scan: sechzehn Plaetze mal
-- vierundzwanzig Spieler waeren eine Zumutung fuer den Client.
--
-- Drei Dinge, die nicht Geschmack sind:
--
--   * NICHT ERREICHBAR IST KEIN BEFUND. Wer zu weit weg, offline oder
--     in einer anderen Phase ist, laesst sich nicht inspizieren. Diese
--     Zeilen bleiben leer und sagen warum, statt als "0 Maengel" in die
--     Zusammenfassung zu wandern - eine Uebersicht, die Ungeprueftes als
--     geprueft zaehlt, ist schlimmer als gar keine.
--   * EINE UNBEKANNTE GEGENSTANDSSTUFE IST KEINE NULL. Der Client
--     beantwortet die Frage nach einem fremden Gegenstand nicht immer;
--     dann steht dort ein Gedankenstrich und der Spieler faellt aus dem
--     Durchschnitt heraus, statt ihn nach unten zu ziehen.
--   * DIE SCHLANGE LAEUFT EINZELN. Der Server beantwortet immer nur eine
--     Inspektion, und zu schnelles Nachfassen liefert die Daten des
--     vorigen Spielers. Deshalb ein Eintrag nach dem anderen, mit
--     Zeitueberschreitung und kurzer Pause dazwischen.
--------------------------------------------------

WeintCodex.GroupCheck = {}

local C = WeintCodex.Colors

local unpack = unpack or table.unpack

--------------------------------------------------
-- Defensive Huellen
--------------------------------------------------
-- Wie in modules/encounter_tracking.lua: hier laesst sich keine einzige
-- API gegen einen echten Client verifizieren, also stirbt im Zweifel der
-- Aufruf und nicht das Addon.

local function Safe(fn, ...)
    if type(fn) ~= "function" then return nil end
    local res = { pcall(fn, ...) }
    if not res[1] then return nil end
    return unpack(res, 2, 8)
end

local function After(seconds, fn)
    if C_Timer and C_Timer.After then
        if pcall(C_Timer.After, seconds, fn) then return end
    end
    fn()
end

--------------------------------------------------
-- Wer gehoert zur Gruppe?
--------------------------------------------------

local function GroupUnits()
    local units = {}
    local count = Safe(GetNumGroupMembers) or 0

    if Safe(IsInRaid) then
        for i = 1, count do units[#units + 1] = "raid" .. i end
    else
        -- Im Party-Fall zaehlt GetNumGroupMembers den Spieler mit, die
        -- Einheiten party1..partyN aber nicht.
        units[#units + 1] = "player"
        for i = 1, math.max(0, count - 1) do units[#units + 1] = "party" .. i end
    end

    return units
end

local function UnitFullName(unit)
    local name, realm = Safe(UnitName, unit)
    if type(name) ~= "string" or name == "" then return nil end
    if type(realm) == "string" and realm ~= "" then
        return name .. "-" .. (realm:gsub("%s+", ""))
    end
    return name
end

--------------------------------------------------
-- Ausruestung eines Spielers auswerten
--------------------------------------------------

-- Rueckgabe: Befund oder nil, wenn die Bausteine fehlen. `slots == 0`
-- heisst "nichts gesehen" und wird vom Aufrufer als fehlgeschlagene
-- Inspektion behandelt, nicht als nackter Spieler.
--
-- Die Plaetze kommen aus modules/charakter.lua und damit vom Client -
-- eine zweite, fest verdrahtete Liste waere genau die Doppelpflege, an
-- der solche Seiten auseinanderlaufen.
local function ScanUnit(unit)
    local CH = WeintCodex.Charakter
    if not (CH and CH.EquipSlots) then return nil end

    local slots = CH.EquipSlots()
    if type(slots) ~= "table" or #slots == 0 then return nil end

    local out = {
        slots        = 0,   -- belegte Plaetze
        empty        = {},  -- Plaetze, die belegt sein sollten
        broken       = {},  -- Gegenstaende mit Haltbarkeit 0
        ilvlSum      = 0,
        ilvlCount    = 0,   -- wie viele Gegenstaende eine Stufe nannten
        unknownItems = 0,   -- ... und wie viele nicht
    }

    for _, slot in ipairs(slots) do
        local link = Safe(GetInventoryItemLink, unit, slot.id)

        if type(link) == "string" then
            out.slots = out.slots + 1

            local detailed = C_Item and C_Item.GetDetailedItemLevelInfo
            local level = Safe(detailed or GetDetailedItemLevelInfo, link)
            if type(level) == "number" and level > 0 then
                out.ilvlSum   = out.ilvlSum + level
                out.ilvlCount = out.ilvlCount + 1
            else
                -- Der Client hat den Gegenstand noch nicht geladen. Das
                -- als 0 in den Durchschnitt zu geben waere eine Messung,
                -- die nie stattgefunden hat.
                out.unknownItems = out.unknownItems + 1
            end

            -- Haltbarkeit gibt es fuer fremde Einheiten nicht in jedem
            -- Client. Antwortet er nicht, bleibt der Gegenstand
            -- ungeprueft - und nicht "heil".
            local current = Safe(GetInventoryItemDurability, slot.id)
            if unit == "player" and type(current) == "number" and current <= 0 then
                out.broken[#out.broken + 1] = slot.name
            end

        elseif slot.key ~= "SecondaryHandSlot" and slot.key ~= "RangedSlot" then
            -- Nebenhand und Distanz duerfen leer sein: ein
            -- Zweihandkaempfer traegt keine Nebenhand, und das ist kein
            -- Mangel.
            out.empty[#out.empty + 1] = slot.name
        end
    end

    return out
end

-- Durchschnittliche Gegenstandsstufe des Befunds, oder nil. Bewusst nil
-- und nicht 0: "nichts gemessen" und "Stufe 0" sind verschiedene
-- Aussagen, und nur eine davon kommt hier je vor.
local function AverageItemLevel(scan)
    if not scan or scan.ilvlCount <= 0 then return nil end
    return scan.ilvlSum / scan.ilvlCount
end

--------------------------------------------------
-- Inspektionsschlange
--------------------------------------------------

local INSPECT_TIMEOUT = 2.0   -- so lange auf INSPECT_READY warten
local INSPECT_GAP     = 0.7   -- Pause zwischen zwei Anfragen

local results   = {}    -- [key] = { key, name, classFile, state, scan, ... }
local order     = {}    -- Reihenfolge wie in der Gruppe
local queue     = {}
local queueIndex = 0
local running   = false
local currentKey, currentGuid = nil, nil
local runToken  = 0
local lastRunAt = nil

local Redraw   -- Vorwaertsdeklaration (die Seite weiter unten)

-- Entprellt: waehrend eines Laufs meldet sich nach jedem Mitglied etwas
-- Neues, und GROUP_ROSTER_UPDATE feuert beim Aufstellen im Sekundentakt.
-- Ein Neuzeichnen je Ereignis wuerde die Bildlaufposition der Tabelle
-- staendig zuruecksetzen - genau waehrend jemand darin liest - und jedes
-- Mal einen neuen Satz Frames anlegen (WoW gibt Frames nie wieder frei,
-- sie werden nur versteckt; dasselbe Muster wie in modules/weinttv.lua).
-- Waehrend eines Laufs deshalb sehr traege; den Fortschritt traegt
-- solange die Schaltflaeche in der Titelleiste, die kostet nichts.
--
-- Der letzte Aufruf darf dabei nicht verlorengehen: ein Aufruf innerhalb
-- des Fensters wird zwar verworfen, der bereits laufende Zeitgeber
-- zeichnet danach aber den dann aktuellen - also endgueltigen - Stand.
local refreshPending = false

local UpdateRunLabel   -- Vorwaertsdeklaration (Titelleiste weiter unten)

local function RefreshIfVisible()
    if type(UpdateRunLabel) == "function" then UpdateRunLabel() end
    if refreshPending then return end
    refreshPending = true
    After(running and 2.0 or 0.35, function()
        refreshPending = false
        if type(Redraw) == "function" then Redraw(true) end
    end)
end

local NextUnit

local function CompleteCurrent(state, scan)
    local rec = results[currentKey]
    if rec then
        rec.state     = state
        rec.checkedAt = time()
        -- Einen frueheren Befund behalten, wenn der neue Versuch nichts
        -- geliefert hat: "war eben noch in Ordnung" ist mehr wert als
        -- eine plötzlich leere Zeile, solange danebensteht, dass die
        -- Inspektion diesmal nicht durchkam.
        if scan then rec.scan = scan end
    end

    currentKey, currentGuid = nil, nil
    RefreshIfVisible()

    After(INSPECT_GAP, function() NextUnit() end)
end

NextUnit = function()
    if not running then return end

    queueIndex = queueIndex + 1
    local item = queue[queueIndex]

    if not item then
        running   = false
        lastRunAt = time()
        Safe(ClearInspectPlayer)
        RefreshIfVisible()
        return
    end

    local unit, key = item.unit, item.key
    currentKey = key

    -- Die Gruppe kann sich waehrend des Laufs aendern, und die Einheiten
    -- ruecken dabei nach: "raid7" ist dann jemand anders als beim
    -- Aufstellen der Schlange. Eine Zeile mit der Ausruestung eines
    -- Fremden zu fuellen waere ein Vorwurf an den Falschen, deshalb hier
    -- und vor jedem Auslesen erneut der Namensabgleich.
    if UnitFullName(unit) ~= key then
        CompleteCurrent("fehlgeschlagen", nil)
        return
    end

    -- Der eigene Charakter braucht keine Inspektion - seine Ausruestung
    -- liest der Client ohnehin.
    if Safe(UnitIsUnit, unit, "player") then
        CompleteCurrent("ok", ScanUnit("player"))
        return
    end

    if Safe(UnitIsConnected, unit) == false then
        CompleteCurrent("offline", nil)
        return
    end

    if not Safe(UnitIsVisible, unit) or not Safe(CanInspect, unit, false) then
        CompleteCurrent("fern", nil)
        return
    end

    currentGuid = Safe(UnitGUID, unit)

    Safe(ClearInspectPlayer)
    Safe(NotifyInspect, unit)

    runToken = runToken + 1
    local token = runToken

    After(INSPECT_TIMEOUT, function()
        -- Der Marker entwertet diese Zeitueberschreitung, sobald
        -- INSPECT_READY frueher da war.
        if not running or token ~= runToken or currentKey ~= key then return end
        if UnitFullName(unit) ~= key then
            CompleteCurrent("fehlgeschlagen", nil)
            return
        end

        local scan = ScanUnit(unit)
        if scan and scan.slots > 0 then
            CompleteCurrent("ok", scan)
        else
            CompleteCurrent("fern", nil)
        end
    end)
end

local watcher = CreateFrame("Frame")
pcall(watcher.RegisterEvent, watcher, "INSPECT_READY")
pcall(watcher.RegisterEvent, watcher, "GROUP_ROSTER_UPDATE")

watcher:SetScript("OnEvent", function(_, event, guid)
    if event == "GROUP_ROSTER_UPDATE" then
        -- Nur neu zeichnen, nicht neu pruefen: wer dazukommt, taucht als
        -- ungeprueft auf, und ein automatischer Inspektionslauf bei jedem
        -- Gruppenwechsel waere waehrend der Aufstellung Dauerfeuer.
        RefreshIfVisible()
        return
    end

    if not running or not currentKey then return end
    if currentGuid and guid and guid ~= currentGuid then return end

    local item = queue[queueIndex]
    if not item then return end

    local unit, key = item.unit, currentKey

    runToken = runToken + 1
    local token = runToken

    -- Kurz warten: direkt im Ereignis liefert GetInventoryItemLink je
    -- nach Client noch die Daten des vorigen Ziels.
    After(0.1, function()
        if not running or token ~= runToken or currentKey ~= key then return end
        if UnitFullName(unit) ~= key then
            CompleteCurrent("fehlgeschlagen", nil)
            return
        end

        local scan = ScanUnit(unit)
        if scan and scan.slots > 0 then
            CompleteCurrent("ok", scan)
        else
            CompleteCurrent("fehlgeschlagen", nil)
        end
    end)
end)

--------------------------------------------------
-- Lauf starten
--------------------------------------------------

function WeintCodex.GroupCheck.Run()
    if running then return end

    local previous = results
    results, order, queue, queueIndex = {}, {}, {}, 0

    for _, unit in ipairs(GroupUnits()) do
        local key = UnitFullName(unit)
        if key and not results[key] then
            local classLoc, classFile = Safe(UnitClass, unit)
            local rec = previous[key] or {}

            rec.key       = key
            rec.name      = Safe(UnitName, unit) or key
            rec.classLoc  = classLoc
            rec.classFile = classFile
            rec.unit      = unit
            rec.state     = "wartet"

            results[key]  = rec
            order[#order + 1] = key
            queue[#queue + 1] = { unit = unit, key = key }
        end
    end

    if #queue == 0 then
        RefreshIfVisible()
        return
    end

    running = true

    -- Hier bewusst NICHT entprellt: die Liste soll sofort mit allen
    -- Mitgliedern und "wird geprueft" dastehen. Ueber RefreshIfVisible
    -- kaeme sie erst zwei Sekunden spaeter, und solange stuende auf der
    -- gerade geoeffneten Seite "Keine Gruppenmitglieder gefunden".
    if type(Redraw) == "function" then Redraw(true) end

    NextUnit()
end

--------------------------------------------------
-- Auswertung einer Zeile
--------------------------------------------------

-- "ok" | "leer" | "defekt" | nil (nichts geprueft)
local function Verdict(rec)
    if rec.state ~= "ok" or not rec.scan then return nil end
    if #rec.scan.empty  > 0 then return "leer" end
    if #rec.scan.broken > 0 then return "defekt" end
    return "ok"
end

local STATE_TEXT = {
    wartet         = "wird geprüft …",
    fern           = "nicht in Reichweite",
    offline        = "offline",
    fehlgeschlagen = "Inspektion fehlgeschlagen",
}

local function Summary()
    local sum = { total = 0, checked = 0, clean = 0, issues = 0, unreachable = 0 }

    for _, key in ipairs(order) do
        local rec = results[key]
        if rec then
            sum.total = sum.total + 1
            local verdict = Verdict(rec)
            if verdict == "ok" then
                sum.checked = sum.checked + 1
                sum.clean   = sum.clean + 1
            elseif verdict then
                sum.checked = sum.checked + 1
                sum.issues  = sum.issues + 1
            elseif rec.state ~= "wartet" then
                sum.unreachable = sum.unreachable + 1
            end
        end
    end

    return sum
end

--------------------------------------------------
-- Darstellung
--------------------------------------------------

local checkFrame   = nil
local onlyProblems = false
local selectedKey  = nil
local runBtn, runLbl = nil, nil

local ROW_H = 34

local function ClassColorText(rec)
    local name = rec.name or rec.key or "—"
    local col  = rec.classFile and RAID_CLASS_COLORS and RAID_CLASS_COLORS[rec.classFile]
    if not col then return name end
    return string.format("|cff%02x%02x%02x%s|r",
        (col.r or 1) * 255, (col.g or 1) * 255, (col.b or 1) * 255, name)
end

local function JoinList(list, maxChars)
    local text = table.concat(list, ", ")
    return WeintCodex.Truncate(text, maxChars or 48)
end

--------------------------------------------------
-- Inspector
--------------------------------------------------

local function BuildInspector()
    local sum    = Summary()
    local blocks = {}

    blocks[#blocks + 1] = { type = "header", text = "Gruppe" }
    blocks[#blocks + 1] = { type = "rows", rows = {
        { label = "Mitglieder",     value = tostring(sum.total) },
        { label = "ohne Befund",    value = tostring(sum.clean),
          valueColor = sum.clean > 0 and "success" or "textDim" },
        { label = "mit Befund",     value = tostring(sum.issues),
          valueColor = sum.issues > 0 and "danger" or "textDim" },
        { label = "nicht geprüft",  value = tostring(sum.unreachable),
          valueColor = sum.unreachable > 0 and "warning" or "textDim" },
    }}

    local rec = selectedKey and results[selectedKey]

    if rec then
        blocks[#blocks + 1] = { type = "divider" }
        blocks[#blocks + 1] = { type = "header", text = rec.name or rec.key }

        local scan = rec.scan
        if scan then
            local lines = {}

            if #scan.empty > 0 then
                lines[#lines + 1] = "Platz leer:"
                for _, slotName in ipairs(scan.empty) do
                    lines[#lines + 1] = "  • " .. slotName
                end
            end

            if #scan.broken > 0 then
                lines[#lines + 1] = "Zerbrochen:"
                for _, slotName in ipairs(scan.broken) do
                    lines[#lines + 1] = "  • " .. slotName
                end
            end

            local avg = AverageItemLevel(scan)
            if avg then
                if #lines > 0 then lines[#lines + 1] = "" end
                lines[#lines + 1] = string.format(
                    "Gegenstandsstufe im Schnitt: %.1f", avg)
            end

            if #lines == 0 then
                lines[1] = "Jeder Platz ist belegt."
            end

            if scan.unknownItems > 0 then
                lines[#lines + 1] = ""
                lines[#lines + 1] = scan.unknownItems
                    .. " Gegenstand/Gegenstände konnte der Client noch nicht"
                    .. " laden - sie fehlen im Durchschnitt."
            end

            blocks[#blocks + 1] = { type = "card", lines = lines }
        else
            blocks[#blocks + 1] = { type = "card", lines = {
                STATE_TEXT[rec.state] or "Noch nicht geprüft.",
            }}
        end
    end

    blocks[#blocks + 1] = { type = "divider" }
    blocks[#blocks + 1] = { type = "header", text = "Was hier geprüft wird" }
    blocks[#blocks + 1] = { type = "card", lines = {
        "Nur ob etwas da ist - nicht, ob es das Richtige ist.",
        "Eine Wertung der Ausrüstung gibt es hier nicht;",
        "sie bräuchte Zahlen, die für Forever niemand kennt.",
        "",
        "Nebenhand und Distanz dürfen leer sein und werden",
        "deshalb nicht angemahnt.",
        "",
        "Wer nicht in Reichweite ist, zählt als ungeprüft -",
        "nicht als fehlerfrei.",
    }}

    WeintCodex.Navigation.SetInspector(blocks)
end

--------------------------------------------------
-- Schaltflaeche in der Titelleiste
--------------------------------------------------

UpdateRunLabel = function()
    if not runLbl then return end
    if running then
        runLbl:SetText(queueIndex .. " / " .. #queue)
        runLbl:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3])
    else
        runLbl:SetText("Prüfen")
        runLbl:SetTextColor(C.textNormal[1], C.textNormal[2], C.textNormal[3])
    end
end

local function MakeRunButton()
    if not runBtn then
        runBtn = WeintCodex.CreateCard(WeintCodex.TitleBarActions,
            { width = 106, height = 30, buttonStyle = true })
        runBtn:SetPoint("TOPRIGHT", WeintCodex.TitleBarActions, "TOPRIGHT", 0, -11)

        runLbl = runBtn:CreateFontString(nil, "OVERLAY")
        runLbl:SetAllPoints(runBtn)
        runLbl:SetFont(WeintCodex.Fonts.sans, 11, "")
        runLbl:SetJustifyH("CENTER")

        runBtn:SetScript("OnEnter", function(self) self:SetSurface("surface3") end)
        runBtn:SetScript("OnLeave", function(self) self:SetSurface("surface2") end)
        runBtn:SetScript("OnClick", function() WeintCodex.GroupCheck.Run() end)
    end

    UpdateRunLabel()
    runBtn:Show()
    return runBtn
end

--------------------------------------------------
-- Seite
--------------------------------------------------

local function ClearContent()
    local cp = WeintCodex.ContentPanel
    if not cp then return end
    for _, child in pairs({ cp:GetChildren() }) do child:Hide() end
end

local function DrawNotice(frame, y, message)
    local card = WeintCodex.CreateCard(frame, {
        width = frame:GetWidth() - 32, height = 56, surface = "surface1",
        style = "border", borderColor = "hairline",
    })
    card:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, y)

    local fs = card:CreateFontString(nil, "OVERLAY")
    fs:SetFont(WeintCodex.Fonts.sans, 11, "")
    fs:SetPoint("TOPLEFT", card, "TOPLEFT", 14, -12)
    fs:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -14, 10)
    fs:SetJustifyH("LEFT")
    fs:SetJustifyV("TOP")
    fs:SetText(WeintCodex.ColorText("textMuted", message))

    return y - 68
end

local COLUMNS = {
    { title = "Spieler",   width = 160 },
    { title = "Stufe",     width = 90  },
    { title = "Plätze",    width = 120 },
    { title = "Befund",    width = 300 },
}

-- Die Zeilen, die gerade gezeigt werden - nach Befund sortiert, damit
-- oben steht, was jemanden interessiert.
local function VisibleRecords()
    local rows = {}

    for _, key in ipairs(order) do
        local rec = results[key]
        if rec then
            local verdict = Verdict(rec)
            local show = true
            if onlyProblems then
                show = (verdict == "leer" or verdict == "defekt")
            end
            if show then
                rows[#rows + 1] = { rec = rec, verdict = verdict }
            end
        end
    end

    local RANK = { leer = 1, defekt = 2, [false] = 3, ok = 4 }
    table.sort(rows, function(a, b)
        local ra = RANK[a.verdict or false] or 3
        local rb = RANK[b.verdict or false] or 3
        if ra ~= rb then return ra < rb end
        return (a.rec.name or "") < (b.rec.name or "")
    end)

    return rows
end

local function DrawTable(frame, y)
    local headerY = y - 6

    local x = 24
    for _, col in ipairs(COLUMNS) do
        local h = WeintCodex.Eyebrow(frame, col.title, { size = 10 })
        h:SetPoint("TOPLEFT", frame, "TOPLEFT", x, headerY)
        h:SetWidth(col.width)
        x = x + col.width + 10
    end

    local divider = frame:CreateTexture(nil, "OVERLAY")
    divider:SetPoint("TOPLEFT",  frame, "TOPLEFT",  16, headerY - 14)
    divider:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -16, headerY - 14)
    divider:SetHeight(1)
    divider:SetColorTexture(C.borderStrong[1], C.borderStrong[2], C.borderStrong[3], 1.0)

    local rows = VisibleRecords()

    if #rows == 0 then
        local fs = frame:CreateFontString(nil, "OVERLAY")
        fs:SetFont(WeintCodex.Fonts.sans, 11, "")
        fs:SetPoint("TOPLEFT", frame, "TOPLEFT", 24, headerY - 34)
        fs:SetWidth(frame:GetWidth() - 48)
        fs:SetJustifyH("LEFT")
        fs:SetText(WeintCodex.ColorText("textDim", onlyProblems
            and "Kein Befund - bei allen geprüften Mitgliedern ist jeder Platz belegt."
            or  "Keine Gruppenmitglieder gefunden."))
        return
    end

    local sf, inner = WeintCodex.CreateScrollArea(frame, 14, headerY - 18, 20, 400)
    sf:ClearAllPoints()
    sf:SetPoint("TOPLEFT",     frame, "TOPLEFT",     14, headerY - 18)
    sf:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -26, 24)
    inner:SetWidth(sf:GetWidth() - 22)

    local yOff = 0

    for _, entry in ipairs(rows) do
        local rec     = entry.rec
        local verdict = entry.verdict
        local scan    = rec.scan

        local rf = CreateFrame("Button", nil, inner)
        rf:SetSize(inner:GetWidth() - 4, ROW_H)
        rf:SetPoint("TOPLEFT", inner, "TOPLEFT", 2, yOff)
        WeintCodex.RowLine(rf, -(ROW_H - 1))

        local tone
        if verdict == "ok" then tone = "green"
        elseif verdict == "leer" then tone = "danger"
        elseif verdict == "defekt" then tone = "gold" end

        local dot = WeintCodex.StatusDot(rf, tone, 7)
        dot:SetPoint("LEFT", rf, "LEFT", 6, 0)

        local cells
        if scan and rec.state == "ok" then
            local avg = AverageItemLevel(scan)

            -- Ein Gedankenstrich, wo nichts gemessen wurde. Eine 0 waere
            -- die Behauptung, der Spieler traege Schrott.
            local ilvlText, ilvlTone
            if avg then
                ilvlText = string.format("%.1f", avg)
                ilvlTone = "textNormal"
            else
                ilvlText = "—"
                ilvlTone = "textFaint"
            end

            local slotText, slotTone
            if #scan.empty > 0 then
                slotText = #scan.empty .. " leer"
                slotTone = "danger"
            else
                slotText = "vollständig (" .. scan.slots .. ")"
                slotTone = "success"
            end

            local findings = {}
            for _, slotName in ipairs(scan.empty) do
                findings[#findings + 1] = slotName .. " leer"
            end
            for _, slotName in ipairs(scan.broken) do
                findings[#findings + 1] = slotName .. " defekt"
            end
            if #findings == 0 and scan.unknownItems > 0 then
                findings[#findings + 1] = scan.unknownItems
                    .. " Gegenstand/Gegenstände noch nicht geladen"
            end

            cells = {
                { ClassColorText(rec) },
                { ilvlText, ilvlTone },
                { slotText, slotTone },
                { #findings > 0 and JoinList(findings, 44) or "—",
                  #findings > 0 and "textNormal" or "textFaint" },
            }
        else
            local note = STATE_TEXT[rec.state] or "noch nicht geprüft"
            cells = {
                { ClassColorText(rec) },
                { "—", "textFaint" },
                { "—", "textFaint" },
                { note, rec.state == "wartet" and "textDim" or "warning" },
            }
        end

        local cx = 22
        for i, col in ipairs(COLUMNS) do
            local cell = cells[i]
            local fs = rf:CreateFontString(nil, "OVERLAY")
            fs:SetFont(WeintCodex.Fonts.sans, 13, "")
            fs:SetPoint("LEFT", rf, "LEFT", cx, 0)
            fs:SetWidth(col.width)
            fs:SetJustifyH("LEFT")
            fs:SetWordWrap(false)
            fs:SetText(cell and cell[1] or "")
            -- Die Spielerspalte traegt ihre Klassenfarbe im Text selbst;
            -- ein SetTextColor darueber wuerde sie ueberschreiben.
            if i > 1 then
                local tint = C[(cell and cell[2]) or "textNormal"] or C.textNormal
                fs:SetTextColor(tint[1], tint[2], tint[3])
            end
            cx = cx + col.width + 10
        end

        -- Die Spalte "Befund" ist gekuerzt; die ganze Liste haengt am
        -- Tooltip und im Detailbereich rechts. Ohne den Hinweisbalken
        -- wuerde niemand merken, dass die Zeile anklickbar ist.
        local hover = rf:CreateTexture(nil, "BACKGROUND")
        hover:SetAllPoints(rf)
        hover:SetColorTexture(1, 1, 1, 0)

        rf:SetScript("OnEnter", function(self)
            hover:SetColorTexture(1, 1, 1, 0.04)

            if not (scan and rec.state == "ok") then return end
            if #scan.empty == 0 and #scan.broken == 0 then return end

            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(rec.name or rec.key)
            for _, slotName in ipairs(scan.empty) do
                GameTooltip:AddLine("Platz leer: " .. slotName,
                    0.96, 0.39, 0.40)
            end
            for _, slotName in ipairs(scan.broken) do
                GameTooltip:AddLine("Zerbrochen: " .. slotName,
                    0.94, 0.65, 0.23)
            end
            GameTooltip:Show()
        end)

        rf:SetScript("OnLeave", function()
            hover:SetColorTexture(1, 1, 1, 0)
            GameTooltip:Hide()
        end)

        rf:SetScript("OnClick", function()
            selectedKey = rec.key
            BuildInspector()
        end)

        yOff = yOff - ROW_H
    end

    inner:SetHeight(math.abs(yOff) + 10)
end

-- onlyIfVisible: aus einem Ereignis heraus aufgerufen, also nur zeichnen,
-- wenn die Seite ueberhaupt offen ist. Die im Detailbereich gewaehlte
-- Zeile (selectedKey) ueberlebt ein Neuzeichnen.
Redraw = function(onlyIfVisible)
    if onlyIfVisible then
        if not (WeintCodex.MainFrame and WeintCodex.MainFrame:IsShown()) then return end
        if WeintCodex.Navigation.CurrentTab
           and WeintCodex.Navigation.CurrentTab() ~= "gruppencheck" then
            return
        end
    end

    UpdateRunLabel()

    ClearContent()
    if checkFrame then checkFrame:Hide() end

    local cp = WeintCodex.ContentPanel
    if not cp then return end

    checkFrame = CreateFrame("Frame", nil, cp)
    checkFrame:SetAllPoints(cp)
    checkFrame:Show()

    WeintCodex.SetBreadcrumb("Gruppencheck",
        onlyProblems and "Nur mit Befund" or "Alle Mitglieder")

    local sum = Summary()

    -- Kopfhoehe wie in modules/weinttv.lua: Eyebrow + 20er Titel +
    -- Unterzeile brauchen die 78, und der Inhalt setzt darunter an.
    -- Die Beschriftungen der Kennzahlen kommen klein herein - Eyebrow
    -- versalisiert und sperrt sie selbst (UTF-8-fest, siehe core/ui.lua).
    local head = WeintCodex.PageHead(checkFrame, {
        eyebrow = "Raid",
        title   = "Gruppencheck", titleSize = 20,
        sub     = "", subSize = 10,
        x = 16, y = 14, height = 78,
        stats = {
            { key = "geprueft", label = "Geprüft", value = sum.checked,
              tone = "textNormal" },
            { key = "befund",   label = "Befund",  value = sum.issues,
              tone = sum.issues > 0 and "dangerBright" or "successBright" },
        },
    })

    head.Sub:SetText(WeintCodex.ColorText("textMuted",
        "Ausrüstung aller Gruppenmitglieder"
        .. (lastRunAt and ("  ·  Stand: " .. date("%H:%M", lastRunAt)) or "")))

    local y = -(14 + head.Height)

    if sum.total <= 1 then
        y = DrawNotice(checkFrame, y,
            "Du bist in keiner Gruppe - geprüft wird nur der eigene Charakter.")
    elseif sum.unreachable > 0 then
        y = DrawNotice(checkFrame, y,
            sum.unreachable .. " Mitglied(er) ließen sich nicht inspizieren"
            .. " (zu weit weg, offline oder in einer anderen Phase) und zählen"
            .. " nicht als geprüft. In der Nähe des Raids erneut prüfen.")
    end

    DrawTable(checkFrame, y)
    BuildInspector()
end

--------------------------------------------------
-- Einstieg aus der Navigation
--------------------------------------------------

function WeintCodex.GroupCheck.Show()
    MakeRunButton()

    WeintCodex.Navigation.BuildSidebar("Gruppencheck", {
        { label = "Alle Mitglieder", onClick = function()
            onlyProblems = false
            Redraw()
        end },
        { label = "Nur mit Befund", onClick = function()
            onlyProblems = true
            Redraw()
        end },
    })

    WeintCodex.Navigation.ActivateFirst()

    -- Beim Oeffnen einmal von selbst pruefen. Wer die Seite aufschlaegt,
    -- will den Stand sehen und nicht erst eine Schaltflaeche suchen; die
    -- Filterreiter darueber loesen bewusst KEINEN neuen Lauf aus.
    if not running then
        WeintCodex.GroupCheck.Run()
    end
end
