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
-- Der Baum links ist derselbe wie bei den Schlachtzügen: Instanzen
-- auf der ersten Ebene, die Bosse des ausgewählten eingerückt auf der
-- zweiten. Heute bleibt die zweite Ebene leer - sobald data/dungeons.lua
-- Bosslisten trägt, füllt sie sich, ohne dass hier etwas zu ändern wäre.
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

local page         = nil
local rows         = {}
local selectedId   = nil
local selectedBoss = nil
local building     = false

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
-- Detailbereich: der Dungeon selbst
--------------------------------------------------

local function InstanceInspector(dungeon)
    local known = WeintCodex.DungeonData.HasBosses(dungeon)
    local range = WeintCodex.DungeonData.LevelRange(dungeon)
    local level = MyLevel()
    local fits  = WeintCodex.DungeonData.FitsLevel(dungeon, level)

    -- Vier Zustände, vier Texte. Ohne Stufe vom Client steht da
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

    return blocks
end

--------------------------------------------------

local function DrawInstance(f, dungeon)
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

    local text, note
    if known then
        text = #dungeon.bosses .. " Bosse stehen links in der Spalte. Ein Klick "
            .. "auf einen davon zeigt hier, was für Tank, Heiler und "
            .. "Schadensausteiler zu beachten ist."
    else
        -- Der ehrliche Leerzustand. Er sagt, WARUM nichts da ist -
        -- das ist der Unterschied zu einer leeren Liste, die wie ein
        -- Fehler aussieht.
        text = "Welche Bosse in " .. dungeon.name .. " stehen, hat Blizzard nicht "
            .. "veröffentlicht. Im Beta-Client stehen Namen für einen Teil der "
            .. "Dungeons, für andere keine – und sie ändern sich von Build zu "
            .. "Build. WeintCodex trägt die Listen nach, wenn sie vollständig "
            .. "sind, und erfindet sie bis dahin nicht."
        note = "Forever erscheint am 04.11.2026"
    end

    local lbl = WeintCodex.Label(bossCard, text, { color = "textMuted", size = 13 })
    lbl:SetPoint("TOPLEFT",  bossCard, "TOPLEFT",   20, -50)
    lbl:SetPoint("TOPRIGHT", bossCard, "TOPRIGHT", -20, -50)

    if note then
        local when = WeintCodex.Eyebrow(bossCard, note,
            { color = "textFaint", size = 10 })
        when:SetPoint("TOPLEFT", lbl, "BOTTOMLEFT", 0, -14)
    end

    WeintCodex.Navigation.SetInspector(InstanceInspector(dungeon))
end

--------------------------------------------------
-- Ein Boss: die drei Rollen
--------------------------------------------------

local function DrawBoss(f, dungeon, boss, index)
    ClearRows()

    local PAD_Y = WeintCodex.Metrics.PAD_Y
    local GAP   = WeintCodex.Metrics.GAP

    local head = WeintCodex.PageHead(f, {
        eyebrow   = dungeon.name,
        title     = boss.name or "?",
        titleSize = 26,
        sub       = WeintCodex.DungeonData.ZoneLabel(dungeon) or "",
        subColor  = "textMuted",
        height    = 86,
        stats     = {
            { key = "pull", label = "Pull",
              value = (boss.order or index) .. "/" .. #dungeon.bosses,
              tone = "textNormal" },
        },
    })
    rows[#rows + 1] = head

    local y = -(PAD_Y + 86) - (GAP - 8)

    local cards = WeintCodex.RolePanel.BossCards(f, y, dungeon, boss)
    for _, card in ipairs(cards) do rows[#rows + 1] = card end

    WeintCodex.Navigation.SetInspector(
        WeintCodex.RolePanel.BossBlocks(dungeon, boss))
end

--------------------------------------------------
-- Der Baum links
--------------------------------------------------

local function BuildTree(f)
    building = true

    local dungeons = WeintCodex.DungeonData.All()
    local items    = {}
    local active   = 1

    local current = WeintCodex.DungeonData.Get(selectedId) or dungeons[1]
    selectedId = current and current.id or nil

    for _, dungeon in ipairs(dungeons) do
        items[#items + 1] = {
            -- Der Stufenbereich als zweite Zeile: er ist das, wonach
            -- man in einer Liste von neun Dungeons sucht.
            label   = dungeon.name,
            status  = WeintCodex.DungeonData.LevelRange(dungeon),
            onClick = function()
                local changed = (selectedId ~= dungeon.id)
                selectedId   = dungeon.id
                selectedBoss = nil
                WeintCodex.SetBreadcrumb("Dungeons", dungeon.name)
                DrawInstance(f, dungeon)
                if changed and not building then BuildTree(f) end
            end,
        }

        if current and dungeon.id == current.id and not selectedBoss then
            active = #items
        end

        if current and dungeon.id == current.id then
            for index, boss in ipairs(dungeon.bosses or {}) do
                items[#items + 1] = {
                    label  = boss.name,
                    indent = true,
                    mark   = WeintCodex.Roles.HasTips(boss.name) and "Tipps" or nil,
                    markColor = "textMuted",
                    onClick = function()
                        selectedBoss = boss.id
                        WeintCodex.SetBreadcrumb("Dungeons", dungeon.name, boss.name)
                        DrawBoss(f, dungeon, boss, index)
                    end,
                }
                if selectedBoss == boss.id then active = #items end
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
-- Dasselbe wie bei den Schlachtzuegen, und aus demselben Grund: die
-- Suche kennt neun Dungeons mit Stufenbereich, und ein Treffer soll
-- dort landen, wo er hingehoert.

function WeintCodex.DungeonPages.Select(dungeonId, bossId)
    local dungeon = WeintCodex.DungeonData.Get(dungeonId)
    if not dungeon then return false end

    selectedId   = dungeon.id
    selectedBoss = nil

    if bossId then
        for _, boss in ipairs(dungeon.bosses or {}) do
            if boss.id == bossId then selectedBoss = bossId break end
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
