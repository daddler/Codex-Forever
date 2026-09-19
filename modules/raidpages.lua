--------------------------------------------------
-- WeintCodex :: Schlachtzüge
--
-- Was es zu einem Schlachtzug zu sagen gibt - und was nicht.
--
-- DIE BOSSLISTEN SIND DA, ABER SIE STEHEN NICHT FEST (siehe
-- data/raids.lua). Seit dem Beta-Start liegen die Encounter-Listen
-- für Barrow Deeps und Hyjal Summit im Client; Onyxias Hort hat
-- keine. Diese Seite hält deshalb VIER Bestände auseinander, und das
-- ist ihr eigentlicher Entwurf:
--
--   1. DIE BOSSLISTE (data/raids.lua). Fehlt sie, steht "noch nicht
--      bekannt" - nicht "0 Bosse", nicht "0/0 gelegt", kein leerer
--      Fortschrittsbalken. Ist sie da, steht ihre HERKUNFT daneben:
--      eine vorläufige Liste, die sich als feststehend ausgibt, wäre
--      genau der Fehler, den die leere Liste vermieden hat.
--   2. DER LOCKOUT (Server). Eine echte Auskunft, unabhängig von der
--      Bossliste: "du hast diese Woche schon eine ID" lässt sich
--      sagen, ohne einen einzigen Bossnamen zu kennen.
--   3. DER FORTSCHRITT (modules/encounter_tracking.lua). Gelegt oder
--      offen, je Boss.
--   4. DIE ROLLEN-TIPPS DES BOTS (SavedData.bossData, über
--      WCIMPORT:BOSS). Was Tank, Heiler und Schadensausteiler an
--      einem Boss zu tun haben, weiss dieses Addon aus genau einer
--      Quelle - dem Discord-Bot. Die Mechaniken von Forever sind
--      nicht veröffentlicht, und WeintCodex denkt sich keine aus.
--      Siehe modules/rolepanel.lua.
--
-- Ein Klick auf einen Boss schlägt seine Rollen-Tipps im
-- Detailbereich auf; ohne Auswahl steht dort der Schlachtzug selbst.
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
-- Bossnotizen des Bots ohne Zuordnung
--------------------------------------------------
-- SavedData.bossData[<Bossname>] ist nach Bossnamen abgelegt und
-- kennt keine Instanz. Mit Bosslisten lässt sich der grösste Teil
-- davon zuordnen - was übrig bleibt, gehört zu einem Boss, den keine
-- unserer Listen führt (ein Dungeonboss, ein Boss aus einem neueren
-- Build). Diese Reste stehen weiterhin gesammelt im Detailbereich,
-- statt sie einem Schlachtzug zuzuschlagen, zu dem sie vielleicht
-- nicht gehören.

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

local function DrawRaid(f, raid)
    ClearRows()

    local PAD_X = WeintCodex.Metrics.PAD_X
    local PAD_Y = WeintCodex.Metrics.PAD_Y
    local GAP   = WeintCodex.Metrics.GAP

    local lockouts = WeintCodex.EncounterTracking
        and WeintCodex.EncounterTracking.SavedLockouts
        and WeintCodex.EncounterTracking.SavedLockouts() or {}

    local lock   = lockouts[raid.id]
    local known  = WeintCodex.RaidData.HasBosses(raid)
    local source = WeintCodex.RaidData.BossSourceLabel(raid)

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

    -- Die Rollen-Tipps als Zustandszeile rechts: sie sagt, ob zu
    -- diesem Schlachtzug überhaupt Taktik vorliegt, bevor man
    -- dreizehn Bosse einzeln anklickt.
    local tipsSummary = WeintCodex.RolePanel.TipsSummary(raid)
    if tipsSummary then
        local tipsLbl = WeintCodex.Eyebrow(lockCard, tipsSummary,
            { color = "textFaint", size = 10, justify = "RIGHT" })
        tipsLbl:SetPoint("BOTTOMRIGHT", lockCard, "BOTTOMRIGHT", -20, 16)
    end

    y = y - 74 - GAP

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

        local hint = WeintCodex.Eyebrow(bossCard,
            "Klicken für Tank, Heiler, Schaden",
            { color = "textFaint", size = 10, justify = "RIGHT" })
        hint:SetPoint("TOPRIGHT", bossCard, "TOPRIGHT", -20, -18)

        -- DREIZEHN BOSSE PASSEN NICHT IN EINE KARTE. Bis die Listen
        -- da waren, lief die Liste nie über den Kartenrand hinaus;
        -- mit Hyjal Summit tut sie es. Ohne Bildlauf verschwände der
        -- Rest unten aus dem Fenster - unsichtbar und unerreichbar,
        -- derselbe Fehler wie einst im Detailbereich.
        local cardW = bossCard:GetWidth() or 0
        local cardH = bossCard:GetHeight() or 0
        if cardW <= 0 then cardW = 600 end
        if cardH <= 0 then cardH = 240 end

        local ok, scroll, inner = pcall(WeintCodex.CreateScrollArea, bossCard,
            20, -46, cardW - 40, cardH - 60, true)

        local host = (ok and inner) or bossCard
        if ok and scroll then
            scroll:ClearAllPoints()
            scroll:SetPoint("TOPLEFT",     bossCard, "TOPLEFT",      20, -46)
            scroll:SetPoint("BOTTOMRIGHT", bossCard, "BOTTOMRIGHT", -14, 14)
            scroll.scrollBarHideable = true
            inner:SetWidth(math.max(1, cardW - 44))
        end

        local by = ok and inner and 0 or -46
        for index, boss in ipairs(raid.bosses) do
            local status = WeintCodex.EncounterTracking
                and WeintCodex.EncounterTracking.GetStatus
                and WeintCodex.EncounterTracking.GetStatus(raid.name, index)

            local row = CreateFrame("Button", nil, host)
            row:SetHeight(34)
            row:SetPoint("TOPLEFT",  host, "TOPLEFT",  0, by)
            row:SetPoint("TOPRIGHT", host, "TOPRIGHT", 0, by)

            local hl = row:CreateTexture(nil, "BACKGROUND")
            hl:SetAllPoints(row)
            hl:SetColorTexture(0, 0, 0, 0)
            row:SetScript("OnEnter", function()
                hl:SetColorTexture(C.surface2[1], C.surface2[2], C.surface2[3], 0.6)
            end)
            row:SetScript("OnLeave", function() hl:SetColorTexture(0, 0, 0, 0) end)
            row:SetScript("OnClick", function()
                WeintCodex.SetBreadcrumb("Schlachtzüge", raid.name, boss.name)
                WeintCodex.Navigation.SetInspector(
                    WeintCodex.RolePanel.BossBlocks(raid, boss))
            end)

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

            -- Der Hinweis, dass zu diesem Boss Taktik vorliegt. Er
            -- steht nur da, wo wirklich etwas liegt - ein Zeichen an
            -- jeder Zeile wäre keine Auskunft.
            if WeintCodex.Roles.HasTips(boss.name) then
                local tipMark = row:CreateFontString(nil, "OVERLAY")
                tipMark:SetFont(WeintCodex.Fonts.mono, 9, "")
                tipMark:SetPoint("RIGHT", mark, "LEFT", -12, 0)
                tipMark:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3])
                tipMark:SetText(WeintCodex.Spaced("TIPPS"))
            end

            WeintCodex.RowLine(row, -33)
            by = by - 36
        end

        if ok and inner then
            inner:SetHeight(math.max(1, #raid.bosses * 36 + 8))
        end

    else

        -- Der ehrliche Leerzustand. Er sagt, WARUM nichts da ist und
        -- ab wann etwas da sein wird - das ist der Unterschied zu
        -- einer leeren Liste, die wie ein Fehler aussieht.
        local empty = WeintCodex.Label(bossCard,
            "Welche Bosse in " .. raid.name .. " stehen, ist noch nicht "
            .. "veröffentlicht – auch im Beta-Client steht dazu keine Liste. "
            .. "WeintCodex trägt sie nach, sobald sie feststehen, und "
            .. "erfindet sie bis dahin nicht.",
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

    WeintCodex.Navigation.SetInspector(InstanceInspector(raid, lock))
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
