--------------------------------------------------
-- WeintCodex :: Schlachtzüge
--
-- Was es zu einem Schlachtzug zu sagen gibt - und was nicht.
--
-- DIE BOSSLISTEN VON FOREVER SIND NICHT VERÖFFENTLICHT (siehe
-- data/raids.lua). Diese Seite ist deshalb so gebaut, dass sie den
-- Unterschied zwischen "kenne ich nicht" und "gibt es nicht" an jeder
-- einzelnen Stelle durchhält:
--
--   * Ohne Bossliste steht "noch nicht bekannt" - nicht "0 Bosse",
--     nicht "0/0 gelegt", kein leerer Fortschrittsbalken. Ein Balken
--     bei null Prozent ist eine Aussage über den Fortschritt, und die
--     hat hier niemand.
--   * Der Lockout dagegen ist eine echte Auskunft des Servers, und
--     zwar unabhängig von der Bossliste: "du hast diese Woche schon
--     eine ID" lässt sich sagen, ohne einen einzigen Bossnamen zu
--     kennen. Er steht deshalb auch dann da, wenn sonst nichts da ist.
--   * Bossnotizen aus dem Discord-Bot (WCIMPORT:BOSS) sind ein
--     dritter, unabhängiger Bestand. Sie erscheinen, sobald welche
--     importiert wurden - auch wenn die Bosslisten selbst noch fehlen.
--     Die Gilde weiß unter Umständen früher, was sie pullt, als diese
--     Datei es weiß.
--
-- Sobald data/raids.lua Bosslisten trägt, füllt sich diese Seite von
-- selbst. Am Code ist dafür nichts zu ändern.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.RaidPages = {}

local C = WeintCodex.Colors

local page       = nil
local rows       = {}
local selectedId = nil

local function ClearRows()
    for _, row in ipairs(rows) do row:Hide() end
    wipe(rows)
end

--------------------------------------------------
-- Bossnotizen des Bots
--------------------------------------------------
-- SavedData.bossData[<Bossname>] = { ... } - was der Bot geliefert
-- hat, ist nach Bossnamen abgelegt und kennt keine Instanz. Solange
-- die Bosslisten fehlen, ist deshalb "alles, was da ist" die einzig
-- mögliche Zuordnung; das steht auch so auf der Seite.

local function BossNotes()
    local sd = WeintCodex.SavedData
    local data = sd and sd.bossData
    if type(data) ~= "table" then return {} end

    local out = {}
    for name in pairs(data) do
        out[#out + 1] = name
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

--------------------------------------------------

local function DrawRaid(f, raid)
    ClearRows()

    local PAD_X = WeintCodex.Metrics.PAD_X
    local PAD_Y = WeintCodex.Metrics.PAD_Y

    local lockouts = WeintCodex.EncounterTracking
        and WeintCodex.EncounterTracking.SavedLockouts
        and WeintCodex.EncounterTracking.SavedLockouts() or {}

    local lock  = lockouts[raid.id]
    local known = WeintCodex.RaidData.HasBosses(raid)

    --------------------------------------------------
    -- Kopf
    --------------------------------------------------

    local stats = {
        { key = "size", label = "Gruppe", value = raid.size,
          tone = "textNormal" },
    }

    -- Die Bosszahl steht NUR da, wenn sie bekannt ist. Eine 0 wäre
    -- keine leere Auskunft, sondern eine falsche.
    if known then
        stats[#stats + 1] = { key = "bosses", label = "Bosse",
            value = #raid.bosses, tone = "textNormal" }
    end

    local head = WeintCodex.PageHead(f, {
        eyebrow   = raid.release or "Schlachtzug",
        title     = raid.name,
        titleSize = 28,
        sub       = known and "" or "Bosse noch nicht bekannt",
        subColor  = "textFaint",
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

    y = y - 74 - WeintCodex.Metrics.GAP

    --------------------------------------------------
    -- Bosse
    --------------------------------------------------

    local bossCard = WeintCodex.CreateSurface(f, {
        tone = "plain", radius = 14, backdrop = "bgDark",
    })
    bossCard:SetPoint("TOPLEFT",     f, "TOPLEFT",      PAD_X, y)
    bossCard:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -PAD_X, PAD_Y)
    rows[#rows + 1] = bossCard

    local bossTitle = bossCard:CreateFontString(nil, "OVERLAY")
    bossTitle:SetFont(WeintCodex.Fonts.sansSemi, 14, "")
    bossTitle:SetPoint("TOPLEFT", bossCard, "TOPLEFT", 20, -16)
    bossTitle:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3])
    bossTitle:SetText("Bosse")

    if known then

        local by = -46
        for index, boss in ipairs(raid.bosses) do
            local status = WeintCodex.EncounterTracking
                and WeintCodex.EncounterTracking.GetStatus
                and WeintCodex.EncounterTracking.GetStatus(raid.name, index)

            local row = CreateFrame("Frame", nil, bossCard)
            row:SetHeight(34)
            row:SetPoint("TOPLEFT",  bossCard, "TOPLEFT",  20, by)
            row:SetPoint("TOPRIGHT", bossCard, "TOPRIGHT", -20, by)

            local dot = WeintCodex.StatusDot(row,
                (status and status.cleared) and "success" or nil, 7)
            dot:SetPoint("LEFT", row, "LEFT", 0, 0)

            local lbl = WeintCodex.Label(row, boss.name or "?",
                { color = "textNormal", size = 13 })
            lbl:SetPoint("LEFT", dot, "RIGHT", 10, 0)

            local mark = row:CreateFontString(nil, "OVERLAY")
            mark:SetFont(WeintCodex.Fonts.monoBold, 10, "")
            mark:SetPoint("RIGHT", row, "RIGHT", 0, 0)
            if status and status.cleared then
                mark:SetTextColor(C.successBright[1], C.successBright[2], C.successBright[3])
                mark:SetText(WeintCodex.Spaced("GELEGT"))
            else
                mark:SetTextColor(C.textFaint[1], C.textFaint[2], C.textFaint[3])
                mark:SetText(WeintCodex.Spaced("OFFEN"))
            end

            WeintCodex.RowLine(row, -33)
            by = by - 36
        end

    else

        -- Der ehrliche Leerzustand. Er sagt, WARUM nichts da ist und
        -- ab wann etwas da sein wird - das ist der Unterschied zu
        -- einer leeren Liste, die wie ein Fehler aussieht.
        local empty = WeintCodex.Label(bossCard,
            "Welche Bosse in " .. raid.name .. " stehen, ist noch nicht "
            .. "veröffentlicht. WeintCodex trägt sie nach, sobald sie "
            .. "feststehen – und erfindet sie bis dahin nicht.",
            { color = "textMuted", size = 13 })
        empty:SetPoint("TOPLEFT",  bossCard, "TOPLEFT",   20, -50)
        empty:SetPoint("TOPRIGHT", bossCard, "TOPRIGHT", -20, -50)

        local when = WeintCodex.Eyebrow(bossCard,
            "Schlachtzüge öffnen am " .. (raid.opensAt or "—"),
            { color = "textFaint", size = 10 })
        when:SetPoint("TOPLEFT", empty, "BOTTOMLEFT", 0, -14)

    end

    --------------------------------------------------
    -- Detailbereich
    --------------------------------------------------

    local notes = BossNotes()

    local blocks = {
        { type = "header", text = "Schlachtzug" },
        { type = "rows", rows = {
            { label = "Gruppengröße", value = raid.size .. " Spieler" },
            { label = "Inhalt",       value = raid.release or "—" },
            { label = "Öffnet",       value = raid.opensAt or "—" },
            { label = "Bosse",
              value = known and tostring(#raid.bosses) or "noch nicht bekannt",
              valueColor = known and "textNormal" or "textFaint" },
            { label = "Diese Woche",
              value = lock and "ID gespeichert" or "keine ID",
              valueColor = lock and "warningBright" or "textFaint" },
        }},
    }

    if #notes > 0 then
        blocks[#blocks + 1] = { type = "divider" }
        blocks[#blocks + 1] = { type = "header", text = "Notizen vom Bot" }
        -- Ohne Bosslisten lässt sich nicht sagen, zu welchem
        -- Schlachtzug eine Notiz gehört. Das steht hier, statt sie
        -- einem zuzuordnen.
        blocks[#blocks + 1] = { type = "card", lines = {
            "Importierte Bossnotizen, ohne Zuordnung zum",
            "Schlachtzug – die gäbe es erst mit den Bosslisten.",
        }}
        for _, name in ipairs(notes) do
            blocks[#blocks + 1] = { type = "text", text = "• " .. name,
                color = "textMuted", size = 12 }
        end
    end

    WeintCodex.Navigation.SetInspector(blocks)
end

--------------------------------------------------

function WeintCodex.RaidPages.Show()
    local cp = WeintCodex.ContentPanel
    for _, child in pairs({ cp:GetChildren() }) do child:Hide() end

    local f = BuildPage()
    f:Show()

    local raids = WeintCodex.RaidData.All()

    local items = {}
    for _, raid in ipairs(raids) do
        items[#items + 1] = {
            label   = raid.name,
            status  = raid.size .. "er",
            onClick = function()
                selectedId = raid.id
                WeintCodex.SetBreadcrumb("Schlachtzüge", raid.name)
                DrawRaid(f, raid)
            end,
        }
    end

    WeintCodex.Navigation.BuildSidebar("Schlachtzüge", items)

    -- Den zuletzt gewählten wieder aufschlagen: wer zwischen zwei
    -- Bereichen hin- und herspringt, will nicht jedes Mal von vorn
    -- anfangen.
    local index = 1
    for i, raid in ipairs(raids) do
        if raid.id == selectedId then index = i break end
    end
    WeintCodex.Navigation.ActivateIndex(index)
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
