--------------------------------------------------
-- WeintCodex :: Schlachtzüge
--
-- Was es zu einem Schlachtzug zu sagen gibt - und was nicht.
--
-- DIE UNTERNAVIGATION IST DER BAUM, NICHT DIE SEITE. Links stehen die
-- drei Schlachtzüge, und unter dem ausgewählten eingerückt seine
-- Bosse. Wer hinsieht, liest beide Antworten auf "wo bin ich?"
-- gleichzeitig und dauerhaft: in welcher Instanz, an welchem Boss.
--
-- Bis 5.1.0.0 stand die Bossliste im Inhaltsbereich, und Hyjal
-- Summits dreizehn Bosse passten dort nicht hinein - die Liste bekam
-- ein Bildlauffeld. Das war zweimal falsch: eine Liste, die man
-- ohnehin links braucht, noch einmal in der Mitte zu zeigen, und dann
-- ausgerechnet die Mitte scrollen zu lassen. Jetzt zeigt die Mitte
-- den AUSGEWÄHLTEN Boss - also das, wofür links kein Platz ist.
--
-- VIER BESTÄNDE, die diese Seite auseinanderhält:
--
--   1. DIE BOSSLISTE (data/raids.lua). Fehlt sie, steht "noch nicht
--      bekannt" - nicht "0 Bosse", nicht "0/0 gelegt". Ist sie da,
--      steht ihre HERKUNFT daneben: eine vorläufige Liste, die sich
--      als feststehend ausgibt, wäre genau der Fehler, den die leere
--      Liste vermieden hat.
--   2. DER LOCKOUT (Server). Eine echte Auskunft, unabhängig von der
--      Bossliste.
--   3. DER FORTSCHRITT (modules/encounter_tracking.lua). Gelegt oder
--      offen, je Boss - links als Statuspunkt am Bosseintrag.
--   4. DIE ROLLEN-TIPPS DES BOTS (SavedData.bossData, über
--      WCIMPORT:BOSS). Was Tank, Heiler und Schadensausteiler an
--      einem Boss zu tun haben, weiss dieses Addon aus genau einer
--      Quelle. Die Mechaniken von Forever sind nicht veröffentlicht,
--      und WeintCodex denkt sich keine aus. Siehe
--      modules/rolepanel.lua.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.RaidPages = {}

local C = WeintCodex.Colors

local page         = nil
local rows         = {}
local selectedId   = nil
local selectedBoss = nil

-- Schutz gegen Selbstaufruf: der Baum wird neu gebaut, und das
-- Wiederherstellen der Auswahl klickt einen Eintrag an - dessen
-- onClick würde sonst denselben Aufbau erneut anstossen.
local building = false

local function ClearRows()
    for _, row in ipairs(rows) do row:Hide() end
    wipe(rows)
end

--------------------------------------------------
-- Bossnotizen des Bots ohne Zuordnung
--------------------------------------------------
-- SavedData.bossData[<Bossname>] ist nach Bossnamen abgelegt und
-- kennt keine Instanz. Mit Bosslisten lässt sich der grösste Teil
-- davon zuordnen - was übrig bleibt, gehört zu einem Boss, den keine
-- unserer Listen führt (ein Dungeonboss, ein Boss aus einem neueren
-- Build). Diese Reste stehen gesammelt im Detailbereich, statt sie
-- einem Schlachtzug zuzuschlagen, zu dem sie vielleicht nicht gehören.

local function UnassignedBossNotes()
    local sd   = WeintCodex.SavedData
    local data = sd and sd.bossData
    if type(data) ~= "table" then return {} end

    local assigned = {}
    for _, raid in ipairs(WeintCodex.RaidData.All()) do
        for _, boss in ipairs(raid.bosses or {}) do
            assigned[boss.name] = true
        end
    end
    for _, dungeon in ipairs((WeintCodex.DungeonData
            and WeintCodex.DungeonData.All()) or {}) do
        for _, boss in ipairs(dungeon.bosses or {}) do
            assigned[boss.name] = true
        end
    end

    local out = {}
    for name in pairs(data) do
        if not assigned[name] then out[#out + 1] = name end
    end
    table.sort(out)
    return out
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

local function Lockout(raid)
    local lockouts = WeintCodex.EncounterTracking
        and WeintCodex.EncounterTracking.SavedLockouts
        and WeintCodex.EncounterTracking.SavedLockouts() or {}
    return lockouts[raid.id]
end

--------------------------------------------------
-- Detailbereich: der Schlachtzug selbst
--------------------------------------------------

local function InstanceInspector(raid, lock)
    local known  = WeintCodex.RaidData.HasBosses(raid)
    local source = WeintCodex.RaidData.BossSourceLabel(raid)

    local bossValue, bossColor
    if not known then
        bossValue, bossColor = "noch nicht bekannt", "textFaint"
    elseif source then
        -- Die Zahl steht da, aber nicht allein: "8 (vorläufig)" ist
        -- eine andere Aussage als "8".
        bossValue, bossColor = #raid.bosses .. " (vorläufig)", "textNormal"
    else
        bossValue, bossColor = tostring(#raid.bosses), "textNormal"
    end

    local blocks = {
        { type = "header", text = "Schlachtzug" },
        { type = "rows", rows = {
            { label = "Gruppengröße", value = raid.size .. " Spieler" },
            { label = "Inhalt",       value = raid.release or "—" },
            { label = "Öffnet",       value = raid.opensAt or "—" },
            { label = "Bosse",        value = bossValue, valueColor = bossColor },
            { label = "Diese Woche",
              value = lock and "ID gespeichert" or "keine ID",
              valueColor = lock and "warningBright" or "textFaint" },
        }},
    }

    if source then
        blocks[#blocks + 1] = { type = "card",
            title    = "Woher die Bossliste stammt",
            subtitle = source,
            lines    = {
                "Aus den Dateien des Beta-Clients, nicht aus",
                "einer Ankündigung. Namen und Reihenfolge",
                "sind nicht bestätigt und ändern sich von",
                "Build zu Build.",
            },
        }
    end

    blocks[#blocks + 1] = { type = "divider" }

    for _, block in ipairs(WeintCodex.RolePanel.InstanceBlocks(raid)) do
        blocks[#blocks + 1] = block
    end

    local notes = UnassignedBossNotes()
    if #notes > 0 then
        blocks[#blocks + 1] = { type = "divider" }
        blocks[#blocks + 1] = { type = "header", text = "Notizen ohne Zuordnung" }
        blocks[#blocks + 1] = { type = "card", lines = {
            "Importierte Bossnotizen zu Namen, die in",
            "keiner unserer Listen stehen.",
        }}
        for _, name in ipairs(notes) do
            blocks[#blocks + 1] = { type = "text", text = "• " .. name,
                color = "textMuted", size = 12 }
        end
    end

    return blocks
end

--------------------------------------------------
-- Die Instanz: Lockout, Aufstellung, Wegweiser
--------------------------------------------------

local function DrawInstance(f, raid)
    ClearRows()

    local PAD_X = WeintCodex.Metrics.PAD_X
    local PAD_Y = WeintCodex.Metrics.PAD_Y
    local GAP   = WeintCodex.Metrics.GAP

    local lock   = Lockout(raid)
    local known  = WeintCodex.RaidData.HasBosses(raid)
    local source = WeintCodex.RaidData.BossSourceLabel(raid)

    --------------------------------------------------
    -- Kopf
    --------------------------------------------------

    local stats = {
        { key = "size", label = "Gruppe", value = raid.size, tone = "textNormal" },
    }

    -- Die Bosszahl steht NUR da, wenn sie bekannt ist. Eine 0 wäre
    -- keine leere Auskunft, sondern eine falsche.
    if known then
        stats[#stats + 1] = { key = "bosses", label = "Bosse",
            value = #raid.bosses, tone = "textNormal" }
    end

    -- Die Unterzeile trägt die Einschränkung, nicht das Kleingedruckte
    -- im Detailbereich: wer die Bosszahl im Kopf liest, liest die
    -- Herkunft im selben Blick.
    local sub, subColor
    if not known then
        sub, subColor = "Bosse noch nicht bekannt", "textFaint"
    elseif source then
        sub, subColor = source, "warningBright"
    else
        sub, subColor = WeintCodex.RolePanel.TipsSummary(raid) or "", "textMuted"
    end

    local head = WeintCodex.PageHead(f, {
        eyebrow   = raid.release or "Schlachtzug",
        title     = raid.name,
        titleSize = 28,
        sub       = sub,
        subColor  = subColor,
        height    = 92,
        stats     = stats,
    })
    rows[#rows + 1] = head

    local y = -(PAD_Y + 92)

    --------------------------------------------------
    -- Die ID dieser Woche
    --------------------------------------------------

    local lockCard = WeintCodex.CreateSurface(f, {
        height = 74, tone = lock and "accent" or "plain",
        radius = 14, backdrop = "bgDark",
    })
    lockCard:SetPoint("TOPLEFT",  f, "TOPLEFT",   PAD_X, y)
    lockCard:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PAD_X, y)
    rows[#rows + 1] = lockCard

    local lockEyebrow = WeintCodex.Eyebrow(lockCard, "Diese Woche",
        { color = lock and "accentBright" or "textFaint", size = 10 })
    lockEyebrow:SetPoint("TOPLEFT", lockCard, "TOPLEFT", 20, -14)

    local lockText
    if lock then
        lockText = "Gespeicherte ID"
        if lock.difficulty and lock.difficulty ~= "" then
            lockText = lockText .. " · " .. lock.difficulty
        end
        if lock.reset and lock.reset > 0 then
            local hours = math.floor(lock.reset / 3600)
            lockText = lockText .. " · läuft in "
                .. (hours >= 24 and (math.floor(hours / 24) .. " Tagen")
                                or (hours .. " Stunden")) .. " ab"
        end
    else
        -- "Keine ID" ist hier eine echte Aussage: der Server hat
        -- geantwortet und nichts gemeldet. Was er nicht beantwortet
        -- hat, führt SavedLockouts gar nicht erst auf.
        lockText = "Keine gespeicherte ID"
    end

    local lockLbl = WeintCodex.Label(lockCard, lockText,
        { color = "textNormal", size = 14 })
    lockLbl:SetPoint("TOPLEFT", lockEyebrow, "BOTTOMLEFT", 0, -8)

    local tipsSummary = WeintCodex.RolePanel.TipsSummary(raid)
    if tipsSummary then
        local tipsLbl = WeintCodex.Eyebrow(lockCard, tipsSummary,
            { color = "textFaint", size = 10, justify = "RIGHT" })
        tipsLbl:SetPoint("BOTTOMRIGHT", lockCard, "BOTTOMRIGHT", -20, 16)
    end

    y = y - 74 - GAP

    --------------------------------------------------
    -- Aufstellung
    --------------------------------------------------

    local roleCard, roleH = WeintCodex.RolePanel.Card(f, raid)
    roleCard:SetPoint("TOPLEFT",  f, "TOPLEFT",   PAD_X, y)
    roleCard:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PAD_X, y)
    rows[#rows + 1] = roleCard

    y = y - roleH - GAP

    --------------------------------------------------
    -- Der Wegweiser bzw. der Leerzustand
    --------------------------------------------------

    local hint = WeintCodex.CreateSurface(f, {
        tone = "plain", radius = 14, backdrop = "bgDark",
    })
    hint:SetPoint("TOPLEFT",     f, "TOPLEFT",      PAD_X, y)
    hint:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -PAD_X, PAD_Y)
    rows[#rows + 1] = hint

    local hintTitle = hint:CreateFontString(nil, "OVERLAY")
    hintTitle:SetFont(WeintCodex.Fonts.sansSemi, 14, "")
    hintTitle:SetPoint("TOPLEFT", hint, "TOPLEFT", 20, -16)
    hintTitle:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3])
    hintTitle:SetText("Bosse")

    local hintText, hintNote
    if known then
        hintText = #raid.bosses .. " Bosse stehen links in der Spalte. Ein Klick "
            .. "auf einen davon zeigt hier, was für Tank, Heiler und "
            .. "Schadensausteiler zu beachten ist."
        hintNote = source
    else
        -- Der ehrliche Leerzustand. Er sagt, WARUM nichts da ist und
        -- ab wann etwas da sein wird.
        hintText = "Welche Bosse in " .. raid.name .. " stehen, ist noch nicht "
            .. "veröffentlicht – auch im Beta-Client steht dazu keine Liste. "
            .. "WeintCodex trägt sie nach, sobald sie feststehen, und "
            .. "erfindet sie bis dahin nicht."
        hintNote = "Schlachtzüge öffnen am " .. (raid.opensAt or "—")
    end

    local hintLbl = WeintCodex.Label(hint, hintText,
        { color = "textMuted", size = 13 })
    hintLbl:SetPoint("TOPLEFT",  hint, "TOPLEFT",   20, -50)
    hintLbl:SetPoint("TOPRIGHT", hint, "TOPRIGHT", -20, -50)

    if hintNote then
        local note = WeintCodex.Eyebrow(hint, hintNote,
            { color = "textFaint", size = 10 })
        note:SetPoint("TOPLEFT", hintLbl, "BOTTOMLEFT", 0, -14)
    end

    WeintCodex.Navigation.SetInspector(InstanceInspector(raid, lock))
end

--------------------------------------------------
-- Ein Boss: die drei Rollen
--------------------------------------------------

local function DrawBoss(f, raid, boss, index)
    ClearRows()

    local PAD_Y = WeintCodex.Metrics.PAD_Y
    local GAP   = WeintCodex.Metrics.GAP

    local status = WeintCodex.EncounterTracking
        and WeintCodex.EncounterTracking.GetStatus
        and WeintCodex.EncounterTracking.GetStatus(raid.name, index)

    local source = WeintCodex.RaidData.BossSourceLabel(raid)

    local head = WeintCodex.PageHead(f, {
        eyebrow   = raid.name,
        title     = boss.name or "?",
        titleSize = 26,
        sub       = source or ((status and status.cleared)
                        and "Diese Woche gelegt" or "Noch offen"),
        subColor  = source and "warningBright"
                        or ((status and status.cleared) and "successBright" or "textFaint"),
        height    = 86,
        stats     = {
            { key = "pull", label = "Pull",
              value = (boss.order or index) .. "/" .. #raid.bosses,
              tone = "textNormal" },
        },
    })
    rows[#rows + 1] = head

    local y = -(PAD_Y + 86) - (GAP - 8)

    local cards = WeintCodex.RolePanel.BossCards(f, y, raid, boss)
    for _, card in ipairs(cards) do rows[#rows + 1] = card end

    WeintCodex.Navigation.SetInspector(
        WeintCodex.RolePanel.BossBlocks(raid, boss))
end

--------------------------------------------------
-- Der Baum links
--------------------------------------------------
-- Instanzen auf der ersten, die Bosse des AUSGEWÄHLTEN Schlachtzugs
-- auf der zweiten Ebene. Nur die des ausgewählten: alle einundzwanzig
-- gleichzeitig wären wieder eine Spalte, die scrollen müsste - und
-- Bosse eines Schlachtzugs, in dem man gerade nicht steckt, beantworten
-- keine Frage.

local function BuildTree(f)
    building = true

    local raids  = WeintCodex.RaidData.All()
    local items  = {}
    local active = 1

    -- Ohne Auswahl der erste Schlachtzug: irgendeine Seite muss
    -- aufgeschlagen sein, und die Spalte soll nicht leer wirken.
    local current = WeintCodex.RaidData.Get(selectedId) or raids[1]
    selectedId = current and current.id or nil

    for _, raid in ipairs(raids) do
        items[#items + 1] = {
            label   = raid.name,
            status  = raid.size .. "er",
            onClick = function()
                local changed = (selectedId ~= raid.id)
                selectedId   = raid.id
                selectedBoss = nil
                WeintCodex.SetBreadcrumb("Schlachtzüge", raid.name)
                DrawInstance(f, raid)
                -- Der Baum ändert sich: die Bosse hängen unter dem
                -- ausgewählten Schlachtzug.
                if changed and not building then BuildTree(f) end
            end,
        }

        if current and raid.id == current.id and not selectedBoss then
            active = #items
        end

        if current and raid.id == current.id then
            for index, boss in ipairs(raid.bosses or {}) do
                local st = WeintCodex.EncounterTracking
                    and WeintCodex.EncounterTracking.GetStatus
                    and WeintCodex.EncounterTracking.GetStatus(raid.name, index)

                items[#items + 1] = {
                    label  = boss.name,
                    indent = true,
                    -- Leerer Punkt heisst "offen", nicht "unbekannt
                    -- ob offen" - der Lockout beantwortet das.
                    dot    = (st and st.cleared) and "success" or nil,
                    mark   = WeintCodex.Roles.HasTips(boss.name) and "Tipps" or nil,
                    markColor = "textMuted",
                    onClick = function()
                        selectedBoss = boss.id
                        WeintCodex.SetBreadcrumb("Schlachtzüge", raid.name, boss.name)
                        DrawBoss(f, raid, boss, index)
                    end,
                }

                if selectedBoss == boss.id then active = #items end
            end
        end
    end

    WeintCodex.Navigation.BuildSidebar("Schlachtzüge", items)
    WeintCodex.Navigation.ActivateIndex(active)

    building = false
end

--------------------------------------------------
-- Von aussen auf einen Schlachtzug oder Boss zeigen
--------------------------------------------------
-- Gebraucht von der globalen Suche: wer dort "Sonya Darkhallow"
-- eingibt, will bei Sonya Darkhallow landen und nicht auf der
-- Schlachtzugseite, die gerade irgendetwas anderes aufgeschlagen hat.
--
-- Setzt nur die Auswahl. Der Aufruf danach (GoToTab) oeffnet die
-- Seite, und die baut ihren Baum damit auf. Ist die Seite schon
-- offen, wird er sofort neu gebaut.

function WeintCodex.RaidPages.Select(raidId, bossId)
    local raid = WeintCodex.RaidData.Get(raidId)
    if not raid then return false end

    selectedId   = raid.id
    selectedBoss = nil

    -- Eine Bosskennung, die es in diesem Schlachtzug nicht gibt,
    -- waehlt die Instanz aus und nicht irgendeinen Boss.
    if bossId then
        for _, boss in ipairs(raid.bosses or {}) do
            if boss.id == bossId then selectedBoss = bossId break end
        end
    end

    if page and page:IsShown() then BuildTree(page) end
    return true
end

--------------------------------------------------

function WeintCodex.RaidPages.Show()
    local cp = WeintCodex.ContentPanel
    for _, child in pairs({ cp:GetChildren() }) do child:Hide() end

    local f = BuildPage()
    f:Show()

    BuildTree(f)
end

--------------------------------------------------
-- Anmeldung beim Fortschritts-Tracking
--------------------------------------------------
-- Damit der Lockout-Import auch dann laeuft, wenn das Fenster nie
-- offen war. Der Namensteil ist der Instanzname selbst - lokalisierte
-- Namen faengt SavedLockouts zusaetzlich ueber die Kleinschreibung ab.

do
    local ET = WeintCodex.EncounterTracking
    if ET and ET.RegisterInstance then
        for _, raid in ipairs(WeintCodex.RaidData.All()) do
            ET.RegisterInstance(raid.name, raid.name)
        end
    end
end
