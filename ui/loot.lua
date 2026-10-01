--------------------------------------------------
-- WeintCodex :: Oberflaeche - Beute (6.9.0.0)
--------------------------------------------------
-- Das Beutefenster des Spiels (LootFrame, "Gegenstaende") in der ruhigen
-- Informationsoberflaeche. Es gehoert nicht zur Klasse: GOLD (S.CALM), wie
-- Haendler und Gespraech. Beta-Test 6.9.0.0: Metallrahmen, Sand als Grund,
-- jede Beute auf einer eigenen Karte mit Rahmen und Etikett.
--
--   Huelle     Metallrahmen und Sand weg (W.WINDOWS, W.HIDE_ATLAS), eine
--              Kachel wie jedes Fenster, Titel hell, kein Schein der Klasse
--              (W.HoldGlow), ein Hauch neutrales Licht, oben eine feine
--              Kante in Gold.
--   Beute      die Liste (LootFrame.ScrollBox) liegt auf der angehobenen
--              Flaeche der Register mit weichem Schatten und Kante in Gold.
--              Die Karten je Gegenstand verlieren Grund, Rahmen und den
--              Rahmen des Etiketts ("Looting_ItemCard_BG",
--              "Looting_ItemCard_Stroke_Normal", "Looting_RarityTag_Frame")
--              - sie stehen auf der Flaeche.
--
-- Unveraendert: Symbole, Namen in der Farbe ihrer Qualitaet, das Etikett
-- ("Schlecht", "Selten" ...), jeder Rahmen, der nicht "Normal" heisst (er
-- traegt die Qualitaet oder zeigt die Maus), Klick und Tooltip, das
-- Schliessen.
--
-- GEMESSEN (6.8.1.0, /wcui fenster): LootFrame mit LootFrameBg (Bild 0,
-- "UIFrameBackground-NineSlice-Corner*"), LootFrame.NineSlice
-- ("UI-Frame-Metal-*"), LootFrame.ScrollBox.ScrollTarget.<Karte>
-- ("Looting_ItemCard_Stroke_Normal", "Looting_ItemCard_BG",
-- "Looting_RarityTag_Frame"; .Item mit Symbol), LootFrame.ClosePanelButton
-- ("RedButton-Exit").
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UILoot = {}

local LT = WeintCodex.UILoot
local K = WeintCodex.UIKit
local C = WeintCodex.Colors
local GC = WeintCodex.GameColors
local W = WeintCodex.UIWindows
local S = WeintCodex.UIStyle
local RG = WeintCodex.UIRegister

local Visible, IsFrame = RG.Visible, RG.IsFrame

LT.LABEL = "Beute"
LT.HOST = "LootFrame"
LT.STYLE = S.CALM
LT.LIGHT_HEIGHT = 60        -- das Fenster ist klein
LT.EDGE = 0.5               -- Kante oben am Fenster in Gold
LT.PAD = 4                  -- Flaeche so weit ueber die Liste hinaus
LT.SHADOW_PAD = 8
LT.LIST_EDGE = 0.45         -- Kante oben an der Flaeche in Gold

S.SCOPES[LT.HOST] = LT.STYLE
W.HOSTED[LT.HOST] = W.HOSTED[LT.HOST] or {}
table.insert(W.HOSTED[LT.HOST], LT)

local windows = setmetatable({}, { __mode = "k" })
LT.windows = windows

function LT.List(f)
    local l = f and f.ScrollBox
    return IsFrame(l) and l or nil
end

-- Der Titel ("Gegenstaende"): hell statt Gold des Spiels.
local function Title(f)
    local tc = f.TitleContainer
    local t = (type(tc) == "table" and tc.TitleText) or f.TitleText or _G.LootFrameTitleText
    if type(t) == "table" and t.SetTextColor then
        K.SetFont(t, 13)
        t:SetTextColor(unpack(C.textBright))
        return true
    end
    return false
end

local function Build(f)
    local accent = S.Accent(LT.STYLE.accent)
    local w = {}
    local l = GC.atmosLight
    w.light = S.TopLight(f, f, l, l[4], LT.LIGHT_HEIGHT, -5)
    w.edge = S.Under(S.Divider(f, accent, LT.EDGE, 0), -3)
    S.PlaceTop(w.edge, f, 10, -1)
    w.title = Title(f)
    local list = LT.List(f)
    if list then
        local c = GC.surfaceRaised
        local card = { on = true }
        card.body = S.SoftPanel(f, list, c, c[4], LT.PAD, -4)
        card.shadow = S.Shadow(f, list, LT.PAD + LT.SHADOW_PAD, -5)
        card.edge = S.Under(S.Divider(f, accent, LT.LIST_EDGE, 0), -3)
        S.PlaceTop(card.edge, list, 10, LT.PAD)
        card.parts = { card.body, card.shadow, card.edge.l, card.edge.r }
        w.card = card
    end
    windows[f] = w
    return w
end

function LT.Update(f)
    local w = windows[f] or Build(f)
    local card = w.card
    if card then
        local on = Visible(LT.List(f))
        if card.on ~= on then
            card.on = on
            for _, t in ipairs(card.parts) do t:SetShown(on) end
        end
    end
    return w
end

function LT.Report(f, out)
    local w = windows[f]
    if not w then return out end
    out[#out + 1] = string.format("   %s (Stil %s): Kante in Gold, kein Schein der Klasse · Titel %s · Liste %s",
        LT.LABEL, LT.STYLE.name, w.title and "hell" or "nicht gefunden",
        w.card and (w.card.on and "auf Fläche" or "zu") or "nicht gefunden")
    return out
end
