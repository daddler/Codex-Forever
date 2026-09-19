--------------------------------------------------
-- WeintCodex :: Dungeons
--
-- Die neun Dungeons von Forever, mit dem, was über sie feststeht -
-- und mit dem, was über sie NICHT feststeht, an derselben Stelle.
--
-- Der Unterschied zur Schlachtzugseite ist der Bestand, nicht der
-- Entwurf: bei den Dungeons sind Name, Gebiet und Stufenbereich
-- bekannt (Blizzard hat sie auf der BlizzCon vorgestellt) und die
-- Bosslisten nicht. Die Seite sagt beides.
--
-- WAS HIER BEWUSST NICHT STEHT:
--
--   * KEINE BOSSLISTE. Für fünf der neun Dungeons liegen Bossnamen
--     im Beta-Client, für vier nicht, und die fünf widersprechen
--     einander zwischen den Builds. Eine Liste, die vier Dungeons
--     stillschweigend als bosslos führt, wäre schlechter als keine.
--   * KEINE TAKTIK. Die Mechaniken sind nicht veröffentlicht. Was
--     hier zu den Rollen steht, ist entweder gesichert (wie viele
--     Plätze, welche Bäume) oder vom Discord-Bot geliefert. Erfunden
--     ist nichts.
--   * KEINE GESPEICHERTE ID. Fünfergruppen haben in dieser Fassung
--     des Spiels keinen Wochen-Lockout. Eine Zeile "keine ID" wäre
--     eine Antwort auf eine Frage, die niemand gestellt hat.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.DungeonPages = {}

local C = WeintCodex.Colors

local page       = nil
local rows       = {}
local selectedId = nil

local function ClearRows()
    for _, row in ipairs(rows) do row:Hide() end
    wipe(rows)
end

--------------------------------------------------
-- Die eigene Stufe
--------------------------------------------------
-- Defensiv wie jeder Client-Aufruf dieser Fassung: es gibt keine
-- laufende Forever-Instanz, an der sich Signatur oder Verhalten
-- prüfen liessen. Antwortet der Client nicht, ist die Stufe nil - und
-- nil heisst überall "nicht bekannt", nie "Stufe 0".

local function MyLevel()
    if type(UnitLevel) ~= "function" then return nil end
    local ok, level = pcall(UnitLevel, "player")
    if not ok or type(level) ~= "number" or level <= 0 then return nil end
    return level
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

local function DrawDungeon(f, dungeon)
    ClearRows()

    local PAD_X = WeintCodex.Metrics.PAD_X
    local PAD_Y = WeintCodex.Metrics.PAD_Y
    local GAP   = WeintCodex.Metrics.GAP

    local known = WeintCodex.DungeonData.HasBosses(dungeon)
    local range = WeintCodex.DungeonData.LevelRange(dungeon)

    --------------------------------------------------
    -- Kopf
    --------------------------------------------------

    local stats = {
        { key = "size", label = "Gruppe", value = dungeon.size, tone = "textNormal" },
    }

    -- Die Bosszahl steht NUR da, wenn sie bekannt ist. Eine 0 wäre
    -- keine leere Auskunft, sondern eine falsche.
    if known then
        stats[#stats + 1] = { key = "bosses", label = "Bosse",
            value = #dungeon.bosses, tone = "textNormal" }
    end

    local head = WeintCodex.PageHead(f, {
        eyebrow   = WeintCodex.DungeonData.ZoneLabel(dungeon) or "Dungeon",
        title     = dungeon.name,
        titleSize = 28,
        sub       = range and ("Stufe " .. range) or "Stufenbereich noch nicht bekannt",
        subColor  = range and "textMuted" or "textFaint",
        height    = 92,
        stats     = stats,
    })
    rows[#rows + 1] = head

    local y = -(PAD_Y + 92)

    --------------------------------------------------
    -- Aufstellung (Tank, Heiler, Schadensausteiler)
    --------------------------------------------------

    local roleCard, roleH = WeintCodex.RolePanel.Card(f, dungeon)
    roleCard:SetPoint("TOPLEFT",  f, "TOPLEFT",   PAD_X, y)
    roleCard:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PAD_X, y)
    rows[#rows + 1] = roleCard

    y = y - roleH - GAP

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
        for _, boss in ipairs(dungeon.bosses) do
            local row = CreateFrame("Frame", nil, bossCard)
            row:SetHeight(34)
            row:SetPoint("TOPLEFT",  bossCard, "TOPLEFT",  20, by)
            row:SetPoint("TOPRIGHT", bossCard, "TOPRIGHT", -20, by)

            local lbl = WeintCodex.Label(row, boss.name or "?",
                { color = "textNormal", size = 13 })
            lbl:SetPoint("LEFT", row, "LEFT", 0, 0)

            WeintCodex.RowLine(row, -33)
            by = by - 36
        end

    else

        -- Der ehrliche Leerzustand. Er sagt, WARUM nichts da ist -
        -- das ist der Unterschied zu einer leeren Liste, die wie ein
        -- Fehler aussieht.
        local empty = WeintCodex.Label(bossCard,
            "Welche Bosse in " .. dungeon.name .. " stehen, hat Blizzard nicht "
            .. "veröffentlicht. Im Beta-Client stehen Namen für einen Teil der "
            .. "Dungeons, für andere keine – und sie ändern sich von Build zu "
            .. "Build. WeintCodex trägt die Listen nach, wenn sie vollständig "
            .. "sind, und erfindet sie bis dahin nicht.",
            { color = "textMuted", size = 13 })
        empty:SetPoint("TOPLEFT",  bossCard, "TOPLEFT",   20, -50)
        empty:SetPoint("TOPRIGHT", bossCard, "TOPRIGHT", -20, -50)

        local when = WeintCodex.Eyebrow(bossCard,
            "Forever erscheint am 04.11.2026",
            { color = "textFaint", size = 10 })
        when:SetPoint("TOPLEFT", empty, "BOTTOMLEFT", 0, -14)

    end

    --------------------------------------------------
    -- Detailbereich
    --------------------------------------------------

    local level = MyLevel()
    local fits  = WeintCodex.DungeonData.FitsLevel(dungeon, level)

    -- Drei Zustaende, drei Texte. Ohne Stufe vom Client steht da
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

    local blocks = {
        { type = "header", text = "Dungeon" },
        { type = "rows", rows = {
            { label = "Gebiet",       value = WeintCodex.DungeonData.ZoneLabel(dungeon) or "—" },
            { label = "Stufen",       value = range or "noch nicht bekannt",
              valueColor = range and "textNormal" or "textFaint" },
            { label = "Gruppengröße", value = dungeon.size .. " Spieler" },
            { label = "Inhalt",       value = dungeon.release or "—" },
            { label = "Bosse",
              value = known and tostring(#dungeon.bosses) or "noch nicht bekannt",
              valueColor = known and "textNormal" or "textFaint" },
            { label = "Deine Stufe",  value = levelValue, valueColor = levelColor },
        }},
        { type = "divider" },
    }

    for _, block in ipairs(WeintCodex.RolePanel.InstanceBlocks(dungeon)) do
        blocks[#blocks + 1] = block
    end

    WeintCodex.Navigation.SetInspector(blocks)
end

--------------------------------------------------

function WeintCodex.DungeonPages.Show()
    local cp = WeintCodex.ContentPanel
    for _, child in pairs({ cp:GetChildren() }) do child:Hide() end

    local f = BuildPage()
    f:Show()

    local dungeons = WeintCodex.DungeonData.All()

    local items = {}
    for _, dungeon in ipairs(dungeons) do
        items[#items + 1] = {
            label   = dungeon.name,
            -- Der Stufenbereich als Statuszeile: er ist das, wonach
            -- man in einer Liste von neun Dungeons sucht.
            status  = WeintCodex.DungeonData.LevelRange(dungeon),
            onClick = function()
                selectedId = dungeon.id
                WeintCodex.SetBreadcrumb("Dungeons", dungeon.name)
                DrawDungeon(f, dungeon)
            end,
        }
    end

    WeintCodex.Navigation.BuildSidebar("Dungeons", items)

    -- Den zuletzt gewählten wieder aufschlagen: wer zwischen zwei
    -- Bereichen hin- und herspringt, will nicht jedes Mal von vorn
    -- anfangen.
    local index = 1
    for i, dungeon in ipairs(dungeons) do
        if dungeon.id == selectedId then index = i break end
    end
    WeintCodex.Navigation.ActivateIndex(index)
end
