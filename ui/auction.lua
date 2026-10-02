--------------------------------------------------
-- WeintCodex :: Oberflaeche - Auktionshaus (6.9.0.4)
--------------------------------------------------
-- Das Auktionshaus des Spiels (AuctionHouseFrame, Blizzard_AuctionHouseUI,
-- erst beim Ansprechen geladen) in der ruhigen Informationsoberflaeche.
-- Handeln gehoert nicht zur Klasse: GOLD (S.CALM), wie Haendler und Handel.
-- Beta-Test 6.9.0.3: Metallrahmen, Marmor, braune Kategorien, Lederlisten,
-- Spaltenkoepfe aus Holz, Reiter des Spiels.
--
--   Huelle     Metallrahmen, Marmor, Streifen, Portraet weg (W.WINDOWS),
--              Kachel, kein Schein der Klasse, Licht und Kante in Gold
--              (ui/calm.lua, Gast "Auktionshaus").
--   Kategorien links: kleine Kacheln statt brauner Balken, die gewaehlte
--              mit Rand in Gold (W.NavEntry, "auctionhouse-nav-button*").
--   Listen     der Grund jeder Liste ("auctionhouse-background-*": Kategorien,
--              Ergebnisse und die weiteren Ansichten) weg, darunter eine
--              Innenflaeche an derselben Stelle; Schatten und Kante in Gold
--              aus ui/calm.lua (W.Insets).
--   Spalten    die Koepfe ("Preis", "Name", "Verfuegbar"; Bild AH.HEADER_FILES)
--              flach mit 1 px Rand - der Sortierpfeil bleibt.
--   Geld       Rahmen und Grund unten links (MoneyFrameBorder, MoneyFrameInset)
--              als Innenflaechen.
--   Reiter     "Kaufen", "Verkaufen", "Auktionen" flach, der gewaehlte in Gold
--              (W.SkinTab).
--   Knoepfe    "Suchen" u. a.: flach (W.SkinPanelButtons im Durchlauf).
--
-- Unveraendert: Suche, Filter, Favoritenstern, Symbole, Farben der
-- Qualitaet, Preise, Tipps. Geaendert werden nur Bilder - kein Skript und
-- kein Feld (Bieten und Kaufen sind geschuetzt).
--
-- GEMESSEN (6.9.0.3, /wcui fenster, Reiter "Kaufen"): AuctionHouseFrame
-- (Bild 374155), NineSlice "UI-Frame-Metal-*", "_UI-Frame-TopTileStreaks",
-- "auctionhouse-background-index" (BrowseResultsFrame.ItemList),
-- "auctionhouse-background-categories" (CategoriesList),
-- "auctionhouse-nav-button" (9x, CategoriesList.ScrollBox.ScrollTarget),
-- Spaltenkoepfe Bild 131139 (9x) und 136580 (3x, Sortierpfeil),
-- AuctionHouseFrameBuyTab ("uiframe-tab-*"), SearchBar.SearchBox
-- ("common-search-border-*"), MoneyFrameInset (374154), MoneyFrameBorder
-- (525911), SearchBar.SearchButton (130828), RTPortrait1.
-- UNGEMESSEN: die Reiter "Verkaufen" und "Auktionen" und die Zeilen einer
-- gefuellten Liste - was dort noch Holz traegt, sagt /wcui fenster.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIAuction = {}

local AH = WeintCodex.UIAuction
local K = WeintCodex.UIKit
local C = WeintCodex.Colors
local GC = WeintCodex.GameColors
local W = WeintCodex.UIWindows
local S = WeintCodex.UIStyle
local RG = WeintCodex.UIRegister

local IsFrame = RG.IsFrame

AH.LABEL = "Auktionshaus"
AH.HOST = "AuctionHouseFrame"
AH.STYLE = S.CALM
AH.EDGE = 0.5
AH.DEPTH = 7                -- Kategorien liegen in CategoriesList.ScrollBox.ScrollTarget
AH.BG_ATLAS = "^auctionhouse%-background%-"
-- Holz der Spaltenkoepfe (links, Mitte, rechts). 136580 ist der
-- Sortierpfeil - er bleibt.
AH.HEADER_FILES = { [131139] = true }
AH.MONEY = { "MoneyFrameBorder", "MoneyFrameInset" }
AH.TAB_NAMES = { "AuctionHouseFrameBuyTab", "AuctionHouseFrameSellTab", "AuctionHouseFrameAuctionsTab" }
AH.HEADER_ALPHA = 0.85

S.SCOPES[AH.HOST] = AH.STYLE
W.HOSTED[AH.HOST] = W.HOSTED[AH.HOST] or {}
table.insert(W.HOSTED[AH.HOST], AH)

local frames = setmetatable({}, { __mode = "k" })
local lists = setmetatable({}, { __mode = "k" })     -- Grund (Region) -> Flaeche
local heads = setmetatable({}, { __mode = "k" })     -- Spaltenkopf -> { bg, edge }
AH.frames, AH.lists, AH.heads = frames, lists, heads

local function FileOf(r)
    if type(r) ~= "table" or not r.GetTexture then return nil end
    local ok, v = pcall(r.GetTexture, r)
    return ok and K.Plain(v) or nil
end

local function AtlasOf(r)
    if type(r) ~= "table" or not r.GetAtlas then return nil end
    local ok, v = pcall(r.GetAtlas, r)
    v = ok and K.Plain(v) or nil
    return type(v) == "string" and v or nil
end

-- Eine Innenflaeche genau dort, wo der Grund des Spiels lag (der Rahmen
-- kann groesser sein als sein Grund). Der Rahmen zaehlt als Innenflaeche
-- (W.Insets) - ui/calm.lua legt Schatten und Kante in Gold daran.
local function Surface(owner, r)
    if lists[r] or not owner.CreateTexture then return end
    local t = owner:CreateTexture(nil, "BACKGROUND", nil, -8)
    t:SetAllPoints(r)
    local s1 = C.surface1
    t:SetColorTexture(s1[1], s1[2], s1[3], 0.45)
    lists[r] = t
    W.Insets[owner] = true
end

-- Ein Spaltenkopf: flach mit 1 px Rand, einmal.
local function Head(b)
    if heads[b] or not b.CreateTexture then return end
    local bg = b:CreateTexture(nil, "BACKGROUND", nil, -7)
    bg:SetAllPoints(b)
    local c = GC.plateBg
    bg:SetColorTexture(c[1], c[2], c[3], AH.HEADER_ALPHA)
    heads[b] = { bg = bg, edge = K.Border(b, 1, 0, 0, 0, 1, "BORDER") }
end

-- Gruende und Spaltenkoepfe bis in die Tiefe (gepoolte Listen).
local function Walk(f, depth, m)
    if depth > AH.DEPTH or type(f) ~= "table" or (f.IsForbidden and f:IsForbidden()) then return end
    for _, r in ipairs(W.Regions(f, "auction", depth)) do
        local atlas = AtlasOf(r)
        if atlas and atlas:find(AH.BG_ATLAS) then
            Surface(f, r)
            m.lists = m.lists + 1
        else
            local id = FileOf(r)
            if id and AH.HEADER_FILES[id] then
                if K.Plain(r:GetAlpha()) ~= 0 then r:SetAlpha(0) end
                Head(f)
            end
        end
    end
    for _, ch in ipairs(W.Children(f, "auction", depth)) do Walk(ch, depth + 1, m) end
end

local function TabOf(f, i)
    local list = f.Tabs
    local tab = type(list) == "table" and list[i] or nil
    if not IsFrame(tab) then tab = _G[AH.TAB_NAMES[i]] end
    return IsFrame(tab) and tab or nil
end

-- Reiter unten: flach, der gewaehlte in Gold (PanelTemplates: selectedTab).
local function Tabs(f, m, accent)
    local selected = K.Plain(f.selectedTab)
    local n = 0
    local count = (type(f.Tabs) == "table" and #f.Tabs) or #AH.TAB_NAMES
    for i = 1, count do
        local tab = TabOf(f, i)
        if tab and tab.CreateTexture then
            local ok, id = pcall(tab.GetID, tab)
            id = ok and K.Plain(id) or i
            if type(id) ~= "number" or id == 0 then id = i end
            W.SkinTab(tab, accent, selected == id)
            n = n + 1
        end
    end
    m.tabs = n
end

function AH.Update(f)
    local accent = S.Accent(AH.STYLE.accent)
    local m = frames[f]
    if not m then
        m = { tabs = 0, lists = 0, money = 0 }
        m.edge = S.Under(S.Divider(f, accent, AH.EDGE, 0), -3)
        S.PlaceTop(m.edge, f, 10, -1)
        frames[f] = m
    end
    -- Geld unten links (Felder am Fenster, sonst globale Namen).
    local money = 0
    for _, key in ipairs(AH.MONEY) do
        local part = f[key]
        if not IsFrame(part) then part = _G[AH.HOST .. key] end
        if IsFrame(part) then W.OwnBackground(part) money = money + 1 end
    end
    m.money = money
    m.lists = 0
    Walk(f, 0, m)
    Tabs(f, m, accent)
    return m
end

function AH.Report(f, out)
    local m = frames[f]
    if not m then return out end
    local nh = 0
    for _ in pairs(heads) do nh = nh + 1 end
    out[#out + 1] = string.format("   %s (Stil %s): Kante in Gold, kein Schein der Klasse · Listen auf Fläche %d · Spaltenköpfe flach %d · Geld %d · Reiter %d",
        AH.LABEL, AH.STYLE.name, m.lists or 0, nh, m.money or 0, m.tabs or 0)
    return out
end
