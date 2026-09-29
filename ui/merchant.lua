--------------------------------------------------
-- WeintCodex :: Oberflaeche - Haendler (6.8.0.6)
--------------------------------------------------
-- Der Haendler (MerchantFrame: kaufen, verkaufen, Rueckkauf, reparieren)
-- in der ruhigen Informationsoberflaeche. Er gehoert nicht zur Klasse:
-- GOLD (S.CALM), wie das Gespraech, aus dem man meist zu ihm kommt.
--
--   Grund      der Schein der Klasse oben ist in Gold aus (W.HoldGlow) -
--              im Spiel lag er als brauner Verlauf ueber den Waren
--              (Beta-Test 6.8.0.4, Krieger). Statt dessen ein Hauch
--              neutrales Licht und oben eine feine Kante in Gold.
--   Waren      die Plaetze (MerchantItem1 ... 12) liegen auf der
--              angehobenen Flaeche der Register mit weichem Schatten und
--              Kante in Gold - von der ersten Ware bis zur letzten, die zu
--              sehen ist (Haendler: 10, Rueckkauf: 12).
--   Geld       die Leiste unten (MerchantMoneyInset, Leder Bild 374154;
--              MerchantMoneyBg, Bild 525911) wird eine Innenflaeche wie
--              ueberall.
--   Reiter     "Haendler" / "Rueckkauf" (MerchantFrameTab1/2,
--              uiframe-tab-*/-activetab-*) flach wie die Reiter oben in
--              den anderen Fenstern, der gewaehlte in Gold.
--
-- Unveraendert: die Plaetze selbst samt Farbe (rot: nicht verwendbar - das
-- faerbt das Spiel am Platz, es sagt etwas), Symbole, Namen, Preise,
-- Waehrungen, Reparieren, Muell verkaufen, Blaettern, Rueckkauf-Platz.
--
-- GEMESSEN (6.8.0.4, /wcui fenster): MerchantFrame, MerchantItem1..
-- (…ItemButton), MerchantFrameTab1 (uiframe-tab-left/-right,
-- uiframe-activetab-left/-right), MerchantMoneyInset (Bild 374154),
-- MerchantMoneyBg (Bild 525911, 3x), MerchantBuyBackItemItemButton,
-- MerchantRepairAllButton, MerchantSellAllJunkButton, MerchantRepairItemButton.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIMerchant = {}

local MC = WeintCodex.UIMerchant
local K = WeintCodex.UIKit
local GC = WeintCodex.GameColors
local W = WeintCodex.UIWindows
local S = WeintCodex.UIStyle
local RG = WeintCodex.UIRegister

local Visible, IsFrame = RG.Visible, RG.IsFrame

MC.LABEL = "Händler"
MC.HOST = "MerchantFrame"
MC.STYLE = S.CALM
MC.LIGHT_HEIGHT = 90
MC.EDGE = 0.5               -- Kante oben am Fenster in Gold
MC.PAD = 6                  -- Flaeche so weit ueber die Waren hinaus
MC.SHADOW_PAD = 10
MC.LIST_EDGE = 0.45         -- Kante oben an der Flaeche in Gold
MC.MAX_ITEMS = 12           -- Rueckkauf zeigt zwoelf Plaetze, der Haendler zehn
MC.TABS = 2

-- Namen einmal bauen: im Takt keine Zeichenketten zusammensetzen.
MC.ITEM_NAMES, MC.TAB_NAMES = {}, {}
for i = 1, MC.MAX_ITEMS do MC.ITEM_NAMES[i] = "MerchantItem" .. i end
for i = 1, MC.TABS do MC.TAB_NAMES[i] = "MerchantFrameTab" .. i end

S.SCOPES[MC.HOST] = MC.STYLE
W.HOSTED[MC.HOST] = W.HOSTED[MC.HOST] or {}
table.insert(W.HOSTED[MC.HOST], MC)

local shops = setmetatable({}, { __mode = "k" })
MC.shops = shops

-- Letzte Ware, die zu sehen ist (untere rechte Ecke der Flaeche).
local function LastItem()
    for i = MC.MAX_ITEMS, 1, -1 do
        local it = _G[MC.ITEM_NAMES[i]]
        if IsFrame(it) and Visible(it) then return it end
    end
    return nil
end

local function Build(f, accent)
    local m = { tabs = 0 }
    local l = GC.atmosLight
    m.light = S.TopLight(f, f, l, l[4], MC.LIGHT_HEIGHT, -5)
    m.edge = S.Under(S.Divider(f, accent, MC.EDGE, 0), -3)
    S.PlaceTop(m.edge, f, 10, -1)
    local first = _G[MC.ITEM_NAMES[1]]
    if IsFrame(first) then
        local c = GC.surfaceRaised
        local g = { on = true, first = first }
        g.body = S.SoftPanel(f, first, c, c[4], MC.PAD, -4)
        g.shadow = S.Shadow(f, first, MC.PAD + MC.SHADOW_PAD, -5)
        g.edge = S.Under(S.Divider(f, accent, MC.LIST_EDGE, 0), -3)
        -- An der Flaeche: zieht mit, wenn sie neu verankert wird.
        S.PlaceTop(g.edge, g.body, 12, 0)
        g.parts = { g.body, g.shadow, g.edge.l, g.edge.r }
        m.goods = g
    end
    shops[f] = m
    return m
end

-- Flaeche von der ersten bis zur letzten sichtbaren Ware; neu verankert
-- nur, wenn sich die letzte aendert (Haendler <-> Rueckkauf).
local function Goods(f, g)
    local last = LastItem()
    local on = last ~= nil and Visible(g.first)
    if on and g.last ~= last then
        g.last = last
        g.body:ClearAllPoints()
        g.body:SetPoint("TOPLEFT", g.first, "TOPLEFT", -MC.PAD, MC.PAD)
        g.body:SetPoint("BOTTOMRIGHT", last, "BOTTOMRIGHT", MC.PAD, -MC.PAD)
        local sp = MC.PAD + MC.SHADOW_PAD
        g.shadow:ClearAllPoints()
        g.shadow:SetPoint("TOPLEFT", g.first, "TOPLEFT", -sp, sp)
        g.shadow:SetPoint("BOTTOMRIGHT", last, "BOTTOMRIGHT", sp, -sp)
    end
    if g.on ~= on then
        g.on = on
        for _, t in ipairs(g.parts) do t:SetShown(on) end
    end
end

-- Reiter unten: flach, der gewaehlte in Gold. Welcher gewaehlt ist, merkt
-- sich das Fenster (selectedTab, PanelTemplates des Spiels).
local function Tabs(f, m, accent)
    local selected = K.Plain(f.selectedTab)
    local n = 0
    for i = 1, MC.TABS do
        local tab = _G[MC.TAB_NAMES[i]]
        if IsFrame(tab) and tab.CreateTexture then
            local ok, id = pcall(tab.GetID, tab)
            id = ok and K.Plain(id) or i
            if type(id) ~= "number" or id == 0 then id = i end
            W.SkinTab(tab, accent, selected == id)
            n = n + 1
        end
    end
    m.tabs = n
end

function MC.Update(f)
    local accent = S.Accent(MC.STYLE.accent)
    local m = shops[f] or Build(f, accent)
    if not m.money then
        local inset = _G.MerchantMoneyInset
        if IsFrame(inset) then W.OwnBackground(inset) m.money = true end
        local bg = _G.MerchantMoneyBg
        if IsFrame(bg) then W.HideOwnTextures(bg) end
    end
    if m.goods then Goods(f, m.goods) end
    Tabs(f, m, accent)
    return m
end

function MC.Report(f, out)
    local m = shops[f]
    if not m then return out end
    local g = m.goods
    out[#out + 1] = string.format("   %s (Stil %s): Kante in Gold, kein Schein der Klasse · Waren %s · Geld %s · Reiter %d",
        MC.LABEL, MC.STYLE.name, g and (g.on and "auf Fläche" or "zu") or "nicht gefunden",
        m.money and "auf Innenfläche" or "nicht gefunden", m.tabs or 0)
    return out
end
