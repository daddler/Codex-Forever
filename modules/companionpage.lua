--------------------------------------------------
-- WeintCodex :: Companion
--
-- Der Zustand der Brücke zur Desktop-App, an einer Stelle und in
-- Klartext. Sie hat einen einzigen Zweck: die Frage beantworten, die
-- vor jeder leeren Seite steht - liegt es an der Verbindung, an der
-- Freigabe oder daran, dass es wirklich nichts gibt?
--
-- DREI ZUSTÄNDE, DIE HIER NIEMALS ZUSAMMENFALLEN DÜRFEN:
--
--   1. "Noch keine Lieferung."   Die Companion hat nie geschrieben.
--   2. "Lieferung von <Datum>."  Sie hat geschrieben, es kam nur
--                                nichts Neues.
--   3. "Für dich gesperrt."      Es kam etwas, du darfst es nicht
--                                sehen.
--
-- Bis 2.x zeigte die Übersicht für alle drei dasselbe leere Bild, und
-- die häufigste Frage im Discord war entsprechend "bei mir geht der
-- Sync nicht" - in zwei von drei Fällen ging er.
--
-- DIE INBOX WIRD NUR BEIM LADEN GELESEN. Was hier steht, ist der Stand
-- der letzten Lieferung und nie eine laufende Verbindung. Diese Seite
-- sagt das ausdrücklich; eine Zeile "verbunden" wäre eine Behauptung
-- über etwas, das es technisch gar nicht gibt.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.CompanionPage = {}

local C = WeintCodex.Colors

local page = nil

--------------------------------------------------

local function Stamp(unixtime)
    local value = tonumber(unixtime)
    if not value or value <= 0 then return nil end
    return date("%d.%m.%Y %H:%M", value)
end

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

local function StateRow(parent, y, tone, label, value, valueTone)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(36)
    row:SetPoint("TOPLEFT",  parent, "TOPLEFT",  20, y)
    row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -20, y)

    local dot = WeintCodex.StatusDot(row, tone, 7)
    dot:SetPoint("LEFT", row, "LEFT", 0, 0)

    local lbl = WeintCodex.Label(row, label, { color = "textNormal", size = 13 })
    lbl:SetPoint("LEFT", dot, "RIGHT", 10, 0)

    local val = row:CreateFontString(nil, "OVERLAY")
    val:SetFont(WeintCodex.Fonts.monoBold, 11, "")
    val:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    local vc = C[valueTone or "textMuted"] or C.textMuted
    val:SetTextColor(vc[1], vc[2], vc[3])
    val:SetText(value or "")

    WeintCodex.RowLine(row, -35)
    return y - 38
end

--------------------------------------------------

function WeintCodex.CompanionPage.Show()
    local cp = WeintCodex.ContentPanel
    for _, child in pairs({ cp:GetChildren() }) do child:Hide() end

    local f = BuildPage()
    f:Show()

    -- Jeder Aufbau zeichnet neu: der Zustand kann sich zwischen zwei
    -- Besuchen geaendert haben (Import, Profilwechsel), und eine Seite,
    -- die den Stand von vorhin zeigt, ist schlimmer als keine.
    for _, child in pairs({ f:GetChildren() }) do child:Hide() end
    for _, region in pairs({ f:GetRegions() }) do
        if region.Hide then region:Hide() end
    end

    WeintCodex.SetBreadcrumb("Companion")

    local PAD_X = WeintCodex.Metrics.PAD_X
    local PAD_Y = WeintCodex.Metrics.PAD_Y

    local inbox   = _G.WeintCompanionInboxDB
    local outbox  = _G.WeintCompanionDB
    local live    = WeintCodex.Companion and WeintCodex.Companion.LiveInfo
                    and WeintCodex.Companion.LiveInfo()
    local queued  = (WeintCodex.Companion and WeintCodex.Companion.GetQueueSize
                     and WeintCodex.Companion.GetQueueSize()) or 0

    local head = WeintCodex.PageHead(f, {
        eyebrow = "Brücke",
        title   = "WeintCompanion",
        sub     = "Stand der letzten Lieferung – keine laufende Verbindung.",
        height  = 92,
    })

    local card = WeintCodex.CreateSurface(f, {
        tone = "plain", radius = 14, backdrop = "bgDark",
    })
    card:SetPoint("TOPLEFT",     f, "TOPLEFT",      PAD_X, -(PAD_Y + 92))
    card:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -PAD_X,  PAD_Y)

    local y = -20

    ------------------------------------------------------
    -- Eingang
    ------------------------------------------------------

    if inbox and inbox.companionVersion then
        y = StateRow(card, y, "green", "Companion hat zugestellt",
            "Version " .. tostring(inbox.companionVersion), "successBright")
    else
        -- Kein Punkt: "noch nie" ist kein Fehlerzustand. Wer die App
        -- nicht benutzt, soll hier kein Rot sehen.
        y = StateRow(card, y, nil, "Noch keine Lieferung der Companion",
            "—", "textFaint")
    end

    if live then
        y = StateRow(card, y, "green", "Live-Brücke gelesen",
            (Stamp(live.writtenAt) or "unbekannt"), "textNormal")
    else
        y = StateRow(card, y, nil, "Keine Live-Zustellung vorhanden",
            "—", "textFaint")
    end

    ------------------------------------------------------
    -- Ausgang
    ------------------------------------------------------

    y = StateRow(card, y,
        queued > 0 and "accent" or nil,
        "Nachrichten an die Companion",
        tostring(queued),
        queued > 0 and "accentBright" or "textFaint")

    ------------------------------------------------------
    -- Zugriffsprofil
    ------------------------------------------------------

    local Access = WeintCodex.Access
    local profile = Access and Access.Profile and Access.Profile()

    if profile then
        local stale = Access.IsStale and Access.IsStale()
        y = StateRow(card, y,
            stale == "expired" and "warning" or "green",
            "Verknüpft mit " .. (Access.CommunityName and Access.CommunityName() or "?"),
            Access.TierLabel and Access.TierLabel() or "",
            stale == "expired" and "warningBright" or "successBright")
    else
        y = StateRow(card, y, nil, "Keine Community verknüpft",
            "offen", "textFaint")
    end

    ------------------------------------------------------
    -- Was zuletzt ankam
    ------------------------------------------------------

    local sd = WeintCodex.SavedData or {}

    local function Delivery(label, entry, count)
        if entry and entry.date then
            y = StateRow(card, y, "green", label,
                tostring(entry.date) .. (count and ("  ·  " .. count) or ""),
                "textNormal")
        else
            y = StateRow(card, y, nil, label, "—", "textFaint")
        end
    end

    Delivery("Anmeldung Mittwoch", sd.raidWednesday,
        sd.raidWednesday and sd.raidWednesday.players
            and (#sd.raidWednesday.players .. " Spieler") or nil)
    Delivery("Anmeldung Donnerstag", sd.raidThursday,
        sd.raidThursday and sd.raidThursday.players
            and (#sd.raidThursday.players .. " Spieler") or nil)
    Delivery("Materialien", sd.materialData,
        sd.materialData and sd.materialData.items
            and (#sd.materialData.items .. " Posten") or nil)

    ------------------------------------------------------
    -- Detailbereich
    ------------------------------------------------------

    WeintCodex.Navigation.SetInspector({
        { type = "header", text = "Wie die Brücke arbeitet" },
        { type = "card", lines = {
            "Die Companion schreibt in zwei Ablagen im",
            "Spielordner. WeintCodex liest sie beim Laden.",
            "",
            "Deshalb steht hier der Stand der letzten",
            "Lieferung und nie eine laufende Verbindung.",
            "",
            "/reload holt eine frische Zustellung.",
        }},
        { type = "divider" },
        { type = "header", text = "Was hier nicht ankommt" },
        { type = "card", lines = {
            "Sim-Ergebnisse, WeakAuras und die Academy",
            "gibt es in dieser Fassung nicht – sie hingen",
            "an Daten, die es für Forever nicht gibt.",
            "",
            "Schickt die Companion sie trotzdem, bleiben",
            "sie liegen, ohne einen Fehler auszulösen.",
        }},
        { type = "divider" },
        { type = "button", label = "Import öffnen", onClick = function()
            if WeintCodex.Navigation and WeintCodex.Navigation.GoToTab then
                WeintCodex.Navigation.GoToTab("import")
            end
        end },
    })
end
