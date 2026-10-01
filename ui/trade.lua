--------------------------------------------------
-- WeintCodex :: Oberflaeche - Handel (6.9.0.2)
--------------------------------------------------
-- Das Handelsfenster des Spiels (TradeFrame) in der ruhigen
-- Informationsoberflaeche. Handeln gehoert nicht zur Klasse: GOLD (S.CALM),
-- wie Haendler, Beute und Makros. Beta-Test 6.9.0.1: Metallrahmen, Marmor,
-- Leder, Steinplaetze, Namensfelder, rote Knoepfe, Portraets.
--
--   Huelle     Metallrahmen, Marmor, Trennleiste, Streifen und beide
--              Portraets weg (W.WINDOWS: W.Skin, HideOwnTextures), Kachel,
--              kein Schein der Klasse, oben eine feine Kante in Gold.
--              Die beiden Namen oben hell.
--   Flaechen   jede Innenflaeche (InsetFrameTemplate: .Bg Leder + .NineSlice)
--              und der Grund des Gelds beim Gegenueber werden Innenflaechen
--              (W.OwnBackground); Schatten und Kante in Gold: ui/calm.lua.
--   Plaetze    Stein, Goldrand und leerer Platz der sieben Plaetze je Seite
--              (Bilder TR.SLOT_FILES) weg, der Knopf flach mit 1 px Rand wie
--              die Aktionsknoepfe; das Namensfeld daneben (TR.NAME_FILES)
--              wird eine flache Leiste.
--   Knoepfe    "Handeln", "Abbrechen": flach (W.SkinPanelButtons im
--              allgemeinen Durchlauf).
--
-- DAS SYMBOL EINES GEGENSTANDS BLEIBT. Ausgeblendet wird ein Bild nur,
-- solange es eines der gemessenen ist; zeigt dieselbe Region spaeter etwas
-- anderes (ein Gegenstand liegt im Platz), wird sie wieder sichtbar - und
-- Symbolregionen (.icon, .Icon, "...IconTexture") werden nie angefasst.
-- Geaendert werden nur Bilder - kein Skript, kein Feld (Handeln ist
-- geschuetzt).
--
-- GEMESSEN (6.9.0.1, /wcui fenster): TradeFrame (Bild 374155), sechs
-- Innenflaechen (Bild 374154, NineSlice "_UI-Frame-InnerTopTile/BotTile"),
-- "!UI-Frame-LeftTile", TradeFrame.NineSlice ("UI-Frame-Metal-*",
-- "UI-Frame-PortraitMetal-*"), "_UI-Frame-TopTileStreaks", RTPortrait1 (2x),
-- TradeRecipientItem1..7 (Bilder 136796, 130766, je 14x), ...ItemButton
-- (130841, 130718, je 14x), TradeRecipientItem7 (137072, 2x),
-- TradeRecipientMoneyBg (525911, 2x), TradeFrameTradeButton (130826, 130828).
-- UNGEMESSEN: welche der Bilder Rand, Stein oder leerer Platz ist - alle
-- drei gehen; und ob die Knoepfe Left/Middle/Right tragen (dann flach).
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UITrade = {}

local TR = WeintCodex.UITrade
local K = WeintCodex.UIKit
local C = WeintCodex.Colors
local GC = WeintCodex.GameColors
local W = WeintCodex.UIWindows
local S = WeintCodex.UIStyle
local RG = WeintCodex.UIRegister

local IsFrame = RG.IsFrame

TR.LABEL = "Handel"
TR.HOST = "TradeFrame"
TR.STYLE = S.CALM
TR.EDGE = 0.5
TR.DEPTH = 4
-- Stein, Rand und leerer Platz (gemessen); 130718 traegt der Knopf selbst.
TR.SLOT_FILES = { [130718] = true, [130766] = true, [130841] = true, [137072] = true }
TR.BUTTON_FILE = 130718
-- Namensfeld neben dem Platz.
TR.NAME_FILES = { [136796] = true }
-- Grund des Gelds beim Gegenueber (Rahmen, kein InsetFrameTemplate).
TR.MONEY_BG = "TradeRecipientMoneyBg"
TR.NAMES = { "TradeFramePlayerNameText", "TradeFrameRecipientNameText" }
TR.NAME_ALPHA = 0.55

S.SCOPES[TR.HOST] = TR.STYLE
W.HOSTED[TR.HOST] = W.HOSTED[TR.HOST] or {}
table.insert(W.HOSTED[TR.HOST], TR)

local frames = setmetatable({}, { __mode = "k" })
local flat = setmetatable({}, { __mode = "k" })      -- Knopf -> { bg, edge }
local strips = setmetatable({}, { __mode = "k" })    -- Namensfeld -> Leiste
local hidden = setmetatable({}, { __mode = "k" })    -- Region -> true
TR.frames, TR.flat, TR.strips, TR.hidden = frames, flat, strips, hidden

local function FileOf(r)
    if type(r) ~= "table" or not r.GetTexture then return nil end
    local ok, v = pcall(r.GetTexture, r)
    return ok and K.Plain(v) or nil
end

-- Symbol eines Gegenstands? Dann nie anfassen.
local function IsIcon(owner, r)
    if r == owner.icon or r == owner.Icon or r == owner.IconTexture then return true end
    local ok, name = pcall(r.GetName, r)
    name = ok and K.Plain(name) or nil
    return type(name) == "string" and name:find("IconTexture$") ~= nil
end

local function Flat(b)
    if flat[b] or not b.CreateTexture then return end
    local bg = b:CreateTexture(nil, "BACKGROUND", nil, -7)
    bg:SetAllPoints(b)
    local c = GC.plateBg
    bg:SetColorTexture(c[1], c[2], c[3], 0.9)
    flat[b] = { bg = bg, edge = K.Border(b, 1, 0, 0, 0, 1, "BORDER") }
end

-- Leiste an der Stelle des Namensfelds (das Bild selbst traegt die Lage).
local function Strip(owner, r)
    if strips[r] or not owner.CreateTexture then return end
    local t = owner:CreateTexture(nil, "BACKGROUND", nil, -7)
    t:SetAllPoints(r)
    local c = GC.plateBg
    t:SetColorTexture(c[1], c[2], c[3], TR.NAME_ALPHA)
    strips[r] = t
end

local function Hide(r)
    if K.Plain(r:GetAlpha()) ~= 0 then r:SetAlpha(0) end
    hidden[r] = true
end

-- Ausgeblendetes, das jetzt etwas anderes zeigt, wieder zeigen.
local function Release()
    for r in pairs(hidden) do
        local id = FileOf(r)
        if not (id and (TR.SLOT_FILES[id] or TR.NAME_FILES[id])) then
            r:SetAlpha(1)
            hidden[r] = nil
        end
    end
end

-- Plaetze, Namensfelder, Innenflaechen bis in die Tiefe (gepoolte Listen).
local function Walk(f, depth, m)
    if depth > TR.DEPTH or type(f) ~= "table" or (f.IsForbidden and f:IsForbidden()) then return end
    if depth > 0 and type(f.Bg) == "table" and type(f.NineSlice) == "table" then
        W.OwnBackground(f)
        m.insets = m.insets + 1
    end
    for _, r in ipairs(W.Regions(f, "trade", depth)) do
        local id = FileOf(r)
        if id and not IsIcon(f, r) then
            if TR.SLOT_FILES[id] then
                Hide(r)
                if id == TR.BUTTON_FILE then Flat(f) end
            elseif TR.NAME_FILES[id] then
                Hide(r)
                Strip(f, r)
            end
        end
    end
    for _, ch in ipairs(W.Children(f, "trade", depth)) do Walk(ch, depth + 1, m) end
end

local function Names()
    local n = 0
    for _, key in ipairs(TR.NAMES) do
        local t = _G[key]
        if type(t) == "table" and t.SetTextColor then
            t:SetTextColor(unpack(C.textBright))
            n = n + 1
        end
    end
    return n
end

function TR.Update(f)
    local m = frames[f]
    if not m then
        local accent = S.Accent(TR.STYLE.accent)
        m = { insets = 0 }
        m.edge = S.Under(S.Divider(f, accent, TR.EDGE, 0), -3)
        S.PlaceTop(m.edge, f, 10, -1)
        local money = _G[TR.MONEY_BG]
        if IsFrame(money) then W.OwnBackground(money) m.money = true end
        frames[f] = m
    end
    Release()
    m.insets = 0
    Walk(f, 0, m)
    m.names = Names()
    return m
end

function TR.Report(f, out)
    local m = frames[f]
    if not m then return out end
    local nf, ns = 0, 0
    for _ in pairs(flat) do nf = nf + 1 end
    for _ in pairs(strips) do ns = ns + 1 end
    out[#out + 1] = string.format("   %s (Stil %s): Kante in Gold, kein Schein der Klasse · Plätze flach %d · Namensfelder %d · Innenflächen %d · Geld %s · Namen hell %d",
        TR.LABEL, TR.STYLE.name, nf, ns, m.insets or 0, m.money and "auf Fläche" or "nicht gefunden", m.names or 0)
    return out
end
