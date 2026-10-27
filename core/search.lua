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
    trainer   = "LEHRER",
    quest     = "KLASSENQUEST",
    profession = "BERUF",
    recipe    = "REZEPT",
    beast     = "WILDTIER",
    item      = "TASCHEN",
    book      = "BUCH",
    loot      = "BEUTE",
    wish      = "WUNSCHLISTE",
}

-- Hoechstens so viele Treffer je Art: sonst fuellten 2000 Rezepte mit
-- "Leinen" die Liste, und der Lehrer kaeme nie zu Wort.
local MAX_PER_CATEGORY = 4

-- Die Navigationseintraege, als Treffer. Der Schluessel ist derselbe wie
-- in core/navigation.lua; gesperrte Bereiche faengt GoToTab selbst ab
-- (es laeuft ueber SwitchTo und damit ueber die Sperrpruefung).
local PAGES = {
    -- In der Reihenfolge der Spalte (6.13.0.0). "uebersicht" ohne ue-Umlaut:
    -- bis 6.12 stand hier "übersicht", eine ID, die die Navigation nicht
    -- kennt - der Treffer tat nichts. Import hat keinen Eintrag in der
    -- Spalte mehr; GoToTab schlaegt den Reiter unter Companion auf.
    { id = "uebersicht",  label = "Übersicht" },
    { id = "charakter",   label = "Charakter" },
    { id = "lehrer",      label = "Lehrer" },
    { id = "klassenquests", label = "Klassenquests" },
    { id = "berufe",      label = "Berufe" },
    { id = "taschen",     label = "Taschen" },
    { id = "buecher",     label = "Entdecken" },
    { id = "dungeons",    label = "Dungeons" },
    { id = "beute",       label = "Beute" },
    { id = "gruppe",      label = "Gruppencheck" },
    { id = "raids",       label = "Schlachtzüge" },
    { id = "anmeldung",   label = "Raidplanung" },
    { id = "anmeldung",   label = "Anmeldung" },
    { id = "kalender",    label = "Kalender" },
    { id = "materialien", label = "Materialien" },
    { id = "companion",   label = "Companion" },
    { id = "import",      label = "Import" },
    { id = "settings",    label = "Einstellungen" },
}

-- Fuer den Prueflauf: jeder Treffer muss einen Bereich oeffnen.
WeintCodex.Search.PAGES = PAGES

--------------------------------------------------
-- Index aufbauen
--------------------------------------------------
-- Zwei Teile (6.x, "die Suchleiste muss auch fuer Lehrer, Berufe,
-- Taschen funktionieren"): der FESTE Index (Seiten, Schlachtzuege,
-- Dungeons, Lehrer, Klassenquests, Berufe, Buecher) wird beim ersten
-- Suchen gebaut und gemerkt - mit ueber tausend Rezepten ist er nicht
-- mehr klein genug fuer jeden Tastendruck. Der WECHSELNDE Teil
-- (Materialien mit Freigabe, Twinks, Taschen) bleibt je Eingabe neu, so
-- sind Importe, Profilaenderungen und neu gelesene Taschen sofort drin.
-- Namen, die der Client erst nachlaedt (Zauber, Quests), machen den
-- festen Index "unfertig"; er wird dann hoechstens alle zwei Sekunden
-- neu gebaut, bis alle da sind.

-- Vergleich ohne Gross/Klein und ohne Umlaute: "Ruestung", "rüstung" und
-- "RÜSTUNG" finden dasselbe. Byteweise sicher: ersetzt werden nur ganze
-- UTF-8-Folgen.
local FOLD = {
    ["ä"] = "ae", ["ö"] = "oe", ["ü"] = "ue", ["Ä"] = "ae", ["Ö"] = "oe", ["Ü"] = "ue", ["ß"] = "ss",
}
local function Fold(text)
    text = tostring(text or ""):gsub("\195[\132\150\156\164\182\188\159]", FOLD)
    return (text:lower())
end
WeintCodex.Search.Fold = Fold

local function GoTo(tabId)
    local nav = WeintCodex.Navigation
    if not nav then return end
    if nav.GoToTab then nav.GoToTab(tabId)
    elseif nav.SwitchTo then nav.SwitchTo(tabId) end
end

local function Add(index, category, label, onClick)
    index[#index + 1] = { category = category, label = label, key = Fold(label), onClick = onClick }
end

local function BuildStatic()
    local index, complete = {}, true

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

    -- LEHRER: die Zauber der eigenen Klasse (dieselbe Liste wie die Seite),
    -- mit Rang und Stufe. Der Name kommt allein vom Client - fehlt er noch,
    -- steht der Zauber (noch) nicht im Index.
    local TR, T = WeintCodex.Trainer, WeintCodex.TrainerData
    if TR and T and T.Spells and TR.PlayerState and TR.SpellInfo then
        local st = TR.PlayerState()
        local seen = {}
        for _, sp in ipairs(st.class and T.Spells(st.class, st.race, st.faction) or {}) do
            local name, sub = TR.SpellInfo(sp.id)
            if not name then complete = false
            elseif not seen[sp.id] then
                seen[sp.id] = true
                Add(index, "trainer", name .. (sub and ("  · " .. sub) or "") .. "  · Lehrer, Stufe " .. sp.level,
                    function() GoTo("lehrer") end)
            end
        end
    end

    -- KLASSENQUESTS: Titel vom Client, sonst der Rueckfall des Bestands.
    local CQ = WeintCodex.ClassQuests
    if CQ and CQ.List and CQ.Title and TR and TR.PlayerState then
        local st = TR.PlayerState()
        for _, q in ipairs(CQ.List(st.class, CQ.PlayerRace and CQ.PlayerRace() or nil)) do
            local title = CQ.Title(q)
            if title then
                Add(index, "quest", title .. (q.lv and ("  · Klassenquests, Stufe " .. q.lv) or "  · Klassenquests"),
                    function() GoTo("klassenquests") end)
            end
        end
    end

    -- BERUFE und ihre Rezepte: oeffnet den Beruf, das Rezept im Detail.
    local PRO, P = WeintCodex.Professions, WeintCodex.ProfessionData
    if PRO and P and PRO.Recipes and PRO.Select then
        for _, p in ipairs(P.PROFS or {}) do
            local key = p.key
            local pname = PRO.ProfName(key)
            Add(index, "profession", pname, function() PRO.Select(key) GoTo("berufe") end)
            for _, r in ipairs(PRO.Recipes(key)) do
                if r.name then
                    Add(index, "recipe", r.name .. "  · Beruf: " .. pname,
                        function() PRO.Select(key) PRO.selRecipe = r GoTo("berufe") end)
                end
            end
        end
    end

    -- BUECHER der Bibliothek.
    for _, b in ipairs((WeintCodex.BooksData and WeintCodex.BooksData.books) or {}) do
        if type(b[4]) == "string" then
            Add(index, "book", b[4] .. "  · Entdecken › Bücher", function() GoTo("buecher") end)
        end
    end

    -- WILDTIERE (nur Jaeger, Reiter Wildtierkunde unter Lehrer).
    local BL = WeintCodex.Beasts
    local BD = WeintCodex.BeastData
    if BL and BL.IsHunter and BL.IsHunter() and BD and type(BD.b) == "table" then
        for id in pairs(BD.b) do
            local be = BL.Get(id)
            if be and type(be.name) == "string" then
                local fam = BL.Family and BL.Family(be.family)
                Add(index, "beast", be.name .. "  · Wildtier" .. ((type(fam) == "table" and type(fam.name) == "string") and (": " .. fam.name) or ""),
                    function() BL.filter, BL.query, BL.selected = "all", "", id GoTo("wildtierkunde") end)
            end
        end
    end

    -- BEUTE: Bereiche und Bosse (modules/lootbook.lua). Gegenstaende stehen
    -- im wechselnden Teil - ihre Namen kennt erst der Client.
    local LB = WeintCodex.LootBook
    if LB and LB.Count then
        for n = 1, LB.Count() do
            local inst = LB.Instance(n)
            local iname = LB.InstanceName(inst)
            Add(index, "loot", iname .. "  · Beute", function() LB.Open(inst.key) GoTo("beute") end)
            for _, b in ipairs(LB.Bosses(n)) do
                Add(index, "loot", LB.BossName(b) .. "  · Beute: " .. iname,
                    function() LB.Open(inst.key) GoTo("beute") end)
            end
        end
    end

    for _, e in ipairs(index) do e.key = e.key or Fold(e.label) end
    return index, complete
end

local staticIndex, staticComplete, staticAt

local function StaticIndex()
    local now = (GetTime and GetTime()) or 0
    if not staticIndex or (not staticComplete and now - (staticAt or 0) >= 2) then
        staticIndex, staticComplete = BuildStatic()
        staticAt = now
    end
    return staticIndex
end

-- Fuer den Prueflauf und nach Datenwechseln: beim naechsten Suchen neu.
function WeintCodex.Search.Reset() staticIndex = nil end

local function BuildDynamic()
    local index = {}

    -- Nur die Materialien sind gildenintern. Dieser Teil laeuft bei jedem
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

    -- TASCHEN: Gegenstaende aller einbezogenen Charaktere (dieselben
    -- Filter wie Tooltip und Gold: Realm, Fraktion, ausgeschlossen).
    -- Ein Treffer je Gegenstand und Charakter; oeffnet die Seite bei ihm.
    local IV, BG = WeintCodex.UIInventory, WeintCodex.Bags
    local st = IV and IV.Store and IV.Store(false)
    if st and BG and IV.Included then
        local _, _, myRealm = IV.Me()
        local myFaction = IV.MyFaction and IV.MyFaction()
        local names = st.names or {}
        for ckey, c in pairs(st.chars or {}) do
            if IV.Included(ckey, c, myRealm, myFaction) then
                local who = c.name or ckey
                local have = {}
                for _, part in ipairs({ "bags", "bank", "worn" }) do
                    for id in pairs(c[part] or {}) do
                        local nm = names[id]
                        if not have[id] and type(nm) == "string" then
                            have[id] = true
                            index[#index + 1] = { category = "item", label = nm .. "  · Taschen: " .. who,
                                key = Fold(nm), onClick = function() BG.sel = ckey GoTo("taschen") end }
                        end
                    end
                end
            end
        end
    end

    -- BEUTE: Wunschliste und Gegenstaende, deren Namen der Client in dieser
    -- Sitzung schon geliefert hat (nie geraten, nie gespeichert).
    local LB = WeintCodex.LootBook
    if LB and LB.names then
        for id, nm in pairs(LB.names) do
            local n = LB.SourceOf(id)
            local inst = n and LB.Instance(n)
            if inst and type(nm) == "string" then
                local wished = LB.IsWished(id)
                index[#index + 1] = { category = wished and "wish" or "loot",
                    label = nm .. "  · Beute: " .. LB.InstanceName(inst), key = Fold(nm),
                    onClick = function() LB.Open(inst.key, id) GoTo("beute") end }
            end
        end
        for _, id in ipairs(LB.WishIds()) do
            if not LB.names[id] then
                local n = LB.SourceOf(id)
                local inst = n and LB.Instance(n)
                if inst then
                    local label = "Wunsch aus " .. LB.InstanceName(inst)
                    index[#index + 1] = { category = "wish", label = label, key = Fold(label),
                        onClick = function() LB.cat = "wish" LB.Open(nil, id) GoTo("beute") end }
                end
            end
        end
    end

    for _, e in ipairs(index) do e.key = e.key or Fold(e.label) end
    return index
end

local function Filter(query)
    query = Fold(query)
    if query == "" then return {} end
    local matches, perCat = {}, {}
    local function Scan(index)
        for _, entry in ipairs(index) do
            if #matches >= MAX_RESULTS then return end
            local n = perCat[entry.category] or 0
            if n < (entry.category == "page" and MAX_RESULTS or MAX_PER_CATEGORY)
                    and entry.key:find(query, 1, true) then
                matches[#matches + 1] = entry
                perCat[entry.category] = n + 1
            end
        end
    end
    Scan(StaticIndex())
    Scan(BuildDynamic())
    return matches
end
WeintCodex.Search.Filter = Filter

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
-- 6.61.15.0 (Fehlerbericht: "Blockiert: SetPropagateKeyboardInput" - Codex
-- offen im Kampf): das Durchreichen darf im Kampf nicht umgestellt werden.
-- Es steht deshalb immer auf "durch"; nur fuer Strg+K ausserhalb des
-- Kampfes kurz nicht, und gleich danach wieder durch. Im Kampf greift
-- Strg+K nicht - jede Taste geht ans Spiel.
if frame.SetPropagateKeyboardInput then frame:SetPropagateKeyboardInput(true) end
local function InCombat() return InCombatLockdown and InCombatLockdown() and true or false end
frame:SetScript("OnKeyDown", function(self, key)
    if InCombat() or not (IsControlKeyDown() and key == "K") then return end
    self:SetPropagateKeyboardInput(false)
    WeintCodex.SearchBox:SetFocus()
    if C_Timer and C_Timer.After then
        C_Timer.After(0, function()
            if not InCombat() then self:SetPropagateKeyboardInput(true) end
        end)
    end
end)

frame:HookScript("OnHide", function()
    WeintCodex.SearchResults:Hide()
end)
