--------------------------------------------------
-- WeintCodex :: Globale Suche (Titelleiste, Strg+K)
--
-- Baut einen flachen Treffer-Index und zeigt passende Treffer in einem
-- Dropdown unter dem Suchfeld (core/ui.lua: WeintCodex.SearchBox /
-- WeintCodex.SearchResults). Wird als letzte Datei geladen (siehe
-- WeintCodex.toc), damit alle referenzierten Datentabellen und Module
-- beim Aufbau bereits existieren.
--
-- DIE SEITEN STEHEN MIT IM INDEX, und das war fuer diese Fassung nicht
-- nebensaechlich: als die Bosslisten von Forever noch leer waren, faende
-- eine Suche, die ausschliesslich Bossnamen kennt, auf einem frischen
-- Stand ueberhaupt nichts. Sie saehe dann aus wie kaputt. Mit den Seiten
-- darin ist sie vom ersten Tag an brauchbar - und sie fuellt sich von
-- selbst, sobald Daten dazukommen. Genau das ist seither passiert:
-- neun Dungeons und einundzwanzig Bosse stehen inzwischen mit drin.
--------------------------------------------------

WeintCodex.Search = {}

local C = WeintCodex.Colors
local MAX_RESULTS = 8
local ROW_H = 26

local CATEGORY_LABEL = {
    page      = "SEITE",
    raid      = "SCHLACHTZUG",
    dungeon   = "DUNGEON",
    boss      = "BOSS",
    material  = "MATERIAL",
    character = "CHARAKTER",
}

-- Die Navigationseintraege, als Treffer. Der Schluessel ist derselbe wie
-- in core/navigation.lua; gesperrte Bereiche faengt GoToTab selbst ab
-- (es laeuft ueber SwitchTo und damit ueber die Sperrpruefung).
local PAGES = {
    { id = "übersicht",  label = "Übersicht" },
    { id = "raids",       label = "Schlachtzüge" },
    { id = "dungeons",    label = "Dungeons" },
    { id = "anmeldung",   label = "Anmeldung" },
    { id = "kalender",    label = "Kalender" },
    { id = "gruppe",      label = "Gruppencheck" },
    { id = "charakter",   label = "Charakter" },
    { id = "materialien", label = "Materialien" },
    { id = "import",      label = "Import" },
    { id = "companion",   label = "Companion" },
    { id = "settings",    label = "Einstellungen" },
}

--------------------------------------------------
-- Index aufbauen
--------------------------------------------------
-- Klein genug, um bei jeder Eingabe neu gebaut zu werden - so sind
-- frisch importierte Daten und eine gerade erst eingetroffene
-- Profilaenderung ohne weiteres Zutun enthalten.

local function GoTo(tabId)
    local nav = WeintCodex.Navigation
    if not nav then return end
    if nav.GoToTab then nav.GoToTab(tabId)
    elseif nav.SwitchTo then nav.SwitchTo(tabId) end
end

local function BuildIndex()
    local index = {}

    for _, page in ipairs(PAGES) do
        index[#index + 1] = {
            category = "page",
            label    = page.label,
            onClick  = function() GoTo(page.id) end,
        }
    end

    -- EIN TREFFER LANDET AUF DEM TREFFER, nicht auf der Seite, auf der
    -- er steht. Wer "Sonya Darkhallow" sucht, will bei Sonya
    -- Darkhallow herauskommen - nicht auf einer Schlachtzugseite, die
    -- gerade irgendetwas anderes aufgeschlagen hat. Select() setzt die
    -- Auswahl, GoTo() oeffnet die Seite damit.
    local function Open(module, instanceId, bossId, tabId)
        return function()
            if module and module.Select then module.Select(instanceId, bossId) end
            GoTo(tabId)
        end
    end

    for _, raid in ipairs((WeintCodex.RaidData and WeintCodex.RaidData.All()) or {}) do
        index[#index + 1] = {
            category = "raid",
            label    = raid.name .. " (" .. raid.size .. "er)",
            onClick  = Open(WeintCodex.RaidPages, raid.id, nil, "raids"),
        }

        -- Solange die Listen leer sind, passiert hier schlicht nichts.
        -- Das ist der Unterschied zu einem Platzhaltereintrag: die Suche
        -- behauptet keinen Boss, den sie nicht kennt.
        for _, boss in ipairs(raid.bosses or {}) do
            index[#index + 1] = {
                category = "boss",
                label    = boss.name,
                onClick  = Open(WeintCodex.RaidPages, raid.id, boss.id, "raids"),
            }
        end
    end

    -- DIE DUNGEONS SIND DER GRUND, WARUM DIE SUCHE ETWAS FINDET, und
    -- seit 5.2.0.0 sind es NEUNUNDZWANZIG Instanzen statt neun: die
    -- klassischen gehoeren dazu, weil Forever sie im Kern
    -- weiterfuehrt. Der Stufenbereich steht mit im Treffer, weil
    -- "welche Ini mit 42?" die Frage ist, mit der man sucht - und die
    -- beantwortet eine Neunerliste falsch.
    --
    -- AllInstances() und nicht All(): die klassischen Dungeons sind
    -- genau die, die man ueber die Suche ansteuert, weil sie in der
    -- Listenspalte hinter einem Stufenabschnitt liegen.
    for _, dungeon in ipairs((WeintCodex.DungeonData
            and WeintCodex.DungeonData.AllInstances()) or {}) do
        local range  = WeintCodex.DungeonData.LevelRange(dungeon)
        local legacy = WeintCodex.DungeonData.IsLegacy(dungeon)
        index[#index + 1] = {
            category = "dungeon",
            label    = dungeon.name .. (range and (" (" .. range .. ")") or "")
                    .. (legacy and "  · Classic" or ""),
            onClick  = Open(WeintCodex.DungeonPages, dungeon.id, nil, "dungeons"),
        }

        -- Auch hier: leere Liste, kein Platzhalter. Der Zusatz am
        -- Bossnamen sagt, wonach man sonst vergeblich suchte -
        -- ein beschwoerbarer Boss steht nicht da, bis jemand etwas
        -- tut, und das ist die Auskunft, die ein Treffer braucht.
        for _, boss in ipairs(dungeon.bosses or {}) do
            index[#index + 1] = {
                category = "boss",
                label    = boss.name .. "  · " .. dungeon.name
                        .. (boss.summon and "  · beschwörbar" or ""),
                onClick  = Open(WeintCodex.DungeonPages, dungeon.id, boss.id, "dungeons"),
            }
        end
    end

    -- Nur die Materialien sind gildenintern. BuildIndex laeuft bei jedem
    -- Tastendruck neu und greift eine Profilaenderung damit sofort auf.
    local matAllowed = not (WeintCodex.Access and WeintCodex.Access.Can)
        or WeintCodex.Access.Can("materials.view")

    if matAllowed and WeintCodex.Materials and WeintCodex.Materials.GetItems then
        for _, item in ipairs(WeintCodex.Materials.GetItems()) do
            if item.name then
                index[#index + 1] = {
                    category = "material",
                    label    = item.name,
                    onClick  = function() GoTo("materialien") end,
                }
            end
        end
    end

    -- Die eigenen Charaktere. Sie stehen nur auf einer Seite, aber es ist
    -- nicht die, die man beim Namen eines Twinks erwartet.
    for name in pairs((WeintCodex.SavedData and WeintCodex.SavedData.twinks) or {}) do
        index[#index + 1] = {
            category = "character",
            label    = name,
            onClick  = function() GoTo("charakter") end,
        }
    end

    return index
end

local function Filter(query)
    query = query:lower()
    local index = BuildIndex()
    local matches = {}
    for _, entry in ipairs(index) do
        if entry.label:lower():find(query, 1, true) then
            matches[#matches + 1] = entry
            if #matches >= MAX_RESULTS then break end
        end
    end
    return matches
end

--------------------------------------------------
-- Dropdown befuellen
--------------------------------------------------

local resultRows = {}

local function GetRow(i)
    local row = resultRows[i]
    if row then return row end

    row = CreateFrame("Button", nil, WeintCodex.SearchResults)
    row:SetHeight(ROW_H)
    row:SetPoint("LEFT",  WeintCodex.SearchResults, "LEFT",  0, 0)
    row:SetPoint("RIGHT", WeintCodex.SearchResults, "RIGHT", 0, 0)

    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(row)
    bg:SetColorTexture(0, 0, 0, 0)
    row._bg = bg

    local tag = row:CreateFontString(nil, "OVERLAY")
    tag:SetFont(WeintCodex.Fonts.mono, 9, "")
    tag:SetPoint("LEFT", row, "LEFT", 10, 0)
    tag:SetWidth(78)
    tag:SetJustifyH("LEFT")
    tag:SetTextColor(C.textFaint[1], C.textFaint[2], C.textFaint[3])
    row._tag = tag

    local label = row:CreateFontString(nil, "OVERLAY")
    label:SetFont(WeintCodex.Fonts.sans, 12, "")
    label:SetPoint("LEFT",  row, "LEFT",  92, 0)
    label:SetPoint("RIGHT", row, "RIGHT", -10, 0)
    label:SetJustifyH("LEFT")
    label:SetTextColor(C.textNormal[1], C.textNormal[2], C.textNormal[3])
    row._label = label

    row:SetScript("OnEnter", function(self) self._bg:SetColorTexture(C.surface2[1], C.surface2[2], C.surface2[3], 1.0) end)
    row:SetScript("OnLeave", function(self) self._bg:SetColorTexture(0, 0, 0, 0) end)
    row:SetScript("OnClick", function(self)
        if self._onClick then self._onClick() end
        WeintCodex.Search.CloseDropdown()
        WeintCodex.SearchBox:SetText("")
        WeintCodex.SearchBox:ClearFocus()
    end)

    resultRows[i] = row
    return row
end

local currentMatches = {}

local function RenderMatches(matches)
    currentMatches = matches
    for i, entry in ipairs(matches) do
        local row = GetRow(i)
        row._tag:SetText(WeintCodex.ColorText("textFaint", CATEGORY_LABEL[entry.category] or ""))
        row._label:SetText(entry.label)
        row._onClick = entry.onClick
        row:SetPoint("TOP", WeintCodex.SearchResults, "TOP", 0, -(i - 1) * ROW_H)
        row:Show()
    end
    for i = #matches + 1, #resultRows do
        resultRows[i]:Hide()
    end

    if #matches > 0 then
        WeintCodex.SearchResults:SetHeight(#matches * ROW_H + 2)
        WeintCodex.SearchResults:Show()
    else
        WeintCodex.SearchResults:Hide()
    end
end

--------------------------------------------------
-- Oeffentliche Hooks (werden von core/ui.lua's EditBox-Scripts aufgerufen)
--------------------------------------------------

function WeintCodex.Search.OnTextChanged(text)
    if text == "" then
        WeintCodex.SearchResults:Hide()
        currentMatches = {}
        return
    end
    RenderMatches(Filter(text))
end

function WeintCodex.Search.OnFocusGained(text)
    if text ~= "" then
        RenderMatches(Filter(text))
    end
end

function WeintCodex.Search.OnFocusLost()
    if C_Timer and C_Timer.After then
        C_Timer.After(0.15, function()
            if not WeintCodex.SearchBox:HasFocus() then
                WeintCodex.SearchResults:Hide()
            end
        end)
    else
        WeintCodex.SearchResults:Hide()
    end
end

function WeintCodex.Search.CloseDropdown()
    WeintCodex.SearchResults:Hide()
    currentMatches = {}
end

-- Enter waehlt den obersten Treffer (ueberschreibt den simplen ClearFocus-
-- Fallback aus core/ui.lua, sobald dieses Modul geladen ist)
WeintCodex.SearchBox:SetScript("OnEnterPressed", function(self)
    if currentMatches[1] then
        currentMatches[1].onClick()
    end
    WeintCodex.Search.CloseDropdown()
    self:SetText("")
    self:ClearFocus()
end)

--------------------------------------------------
-- Strg+K: fokussiert das Suchfeld, solange das WeintCodex-Fenster offen ist.
-- Kein globales Blizzard-Keybinding (dafuer gibt es keine bestehende
-- Infrastruktur) - greift nur, waehrend WeintCodex.MainFrame sichtbar ist,
-- und laesst alle anderen Tasten unangetastet durch (SetPropagateKeyboardInput).
--------------------------------------------------

local frame = WeintCodex.MainFrame
frame:EnableKeyboard(true)
frame:SetScript("OnKeyDown", function(self, key)
    if IsControlKeyDown() and key == "K" then
        self:SetPropagateKeyboardInput(false)
        WeintCodex.SearchBox:SetFocus()
    else
        self:SetPropagateKeyboardInput(true)
    end
end)

frame:HookScript("OnHide", function()
    WeintCodex.SearchResults:Hide()
end)
