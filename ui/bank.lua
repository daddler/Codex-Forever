--------------------------------------------------
-- WeintCodex :: Oberflaeche - Bank (6.9.1.1)
--------------------------------------------------
-- Die Bank des Spiels (BankFrame) in der ruhigen Informationsoberflaeche.
-- Die Bank gehoert nicht zur Klasse: GOLD (S.CALM), wie Haendler, Handel
-- und Auktionshaus. Beta-Test 6.9.1.0: Metallrahmen, Portraet, Steinplaetze,
-- Holzleisten, Grund aus Leder.
--
--   Huelle     Metallrahmen, Marmor, Streifen, Portraet weg (W.WINDOWS,
--              Muster in W.HIDE_ATLAS), Kachel, kein Schein der Klasse,
--              Licht und Kante in Gold (ui/calm.lua, Gast "Bank").
--   Grund      "bank-frame-background" weg, an seiner Stelle eine
--              Innenflaeche (W.Insets: Schatten und Kante in Gold aus
--              ui/calm.lua); Trennleiste und Schatten am Rand weg.
--   Plaetze    Stein ("bags-item-bankslot64"), Rahmen
--              ("bank-frame-item-slotframe") und Rand des Knopfs (Bild
--              BK.BUTTON_FILE) der 48 Plaetze weg, der Knopf flach mit 1 px
--              Rand wie die Aktionsknoepfe. Dasselbe fuer die acht
--              Taschenplaetze ("bank-frame-bag-slotframe", "-slot-bg").
--              Das Schloss eines ungekauften Platzes bleibt - es sagt etwas.
--   Geld       der Rahmen unten rechts (BankPanel.MoneyFrame.Border, Bild
--              525911) als Innenflaeche.
--   Reiter     rechts (Gold des Spiels "common-sidetab"): kleine Kacheln, der
--              gewaehlte in Gold (W.SkinSideTabs im allgemeinen Durchlauf).
--   Knoepfe    "Kaufen": flach (W.SkinPanelButtons im Durchlauf).
--
-- DAS SYMBOL EINES GEGENSTANDS BLEIBT, ebenso der Rand in der Farbe der
-- Qualitaet (IconBorder), die Suche und das Sortieren. Ausgeblendet wird
-- ein Bild nur, solange es eines der gemessenen ist; zeigt dieselbe Region
-- spaeter etwas anderes, wird sie wieder sichtbar. Geaendert werden nur
-- Bilder - kein Skript, kein Feld.
--
-- GEMESSEN (6.9.1.0, /wcui fenster): BankFrame (Bild 374155,
-- "bank-frame-background", "bank-divider", NineSlice "UI-Frame-Metal-*",
-- "UI-Frame-PortraitMetal-*", "_UI-Frame-TopTileStreaks", RTPortrait1),
-- BankPanel.EdgeShadows ("_bank-frame-horiz-shadow" 2x,
-- "!bank-frame-vert-shadow" 2x), 48 Plaetze ("bags-item-bankslot64",
-- "bank-frame-item-slotframe"), Bild 130718 (57x), acht Taschenplaetze
-- ("bank-frame-bag-slot-bg", "bank-frame-bag-slotframe",
-- "bankslot-icon-lock"), BankPanel.MoneyFrame.Border (525911, 3x),
-- Seitenreiter ("common-sidetab", "common-sidetab-selected").
-- UNGEMESSEN: die Gildenbank (GuildBankFrame, erst beim Oeffnen geladen) -
-- sie bekommt Huelle und Gold, ihre Plaetze sagt erst /wcui fenster.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIBank = {}

local BK = WeintCodex.UIBank
local K = WeintCodex.UIKit
local C = WeintCodex.Colors
local GC = WeintCodex.GameColors
local W = WeintCodex.UIWindows
local S = WeintCodex.UIStyle
local RG = WeintCodex.UIRegister

local IsFrame = RG.IsFrame

BK.LABEL = "Bank"
BK.HOST = "BankFrame"
BK.STYLE = S.CALM
BK.EDGE = 0.5
BK.DEPTH = 5
-- Stein und Rahmen der Plaetze und Taschenplaetze (Atlanten, gemessen).
BK.SLOT_ATLAS = { "^bags%-item%-bankslot", "^bank%-frame%-item%-slotframe",
                  "^bank%-frame%-bag%-slotframe", "^bank%-frame%-bag%-slot%-bg" }
-- Rand des Knopfs (Bild, gemessen - dasselbe wie im Handel).
BK.BUTTON_FILE = 130718
-- Grund der Bank: wird Innenflaeche.
BK.BG_ATLAS = "^bank%-frame%-background"
-- Schmuck: Trennleiste und Schatten am Rand.
BK.DECOR_ATLAS = { "^bank%-divider", "^[_!]?bank%-frame%-%a+%-shadow" }

S.SCOPES[BK.HOST] = BK.STYLE
W.HOSTED[BK.HOST] = W.HOSTED[BK.HOST] or {}
table.insert(W.HOSTED[BK.HOST], BK)

local frames = setmetatable({}, { __mode = "k" })
local flat = setmetatable({}, { __mode = "k" })      -- Knopf -> { bg, edge }
local hidden = setmetatable({}, { __mode = "k" })    -- Region -> true
local surfaces = setmetatable({}, { __mode = "k" })  -- Grund -> Flaeche
BK.frames, BK.flat, BK.hidden, BK.surfaces = frames, flat, hidden, surfaces

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

local function Any(list, s)
    if not s then return false end
    for _, pat in ipairs(list) do
        if s:find(pat) then return true end
    end
    return false
end

-- Was eine Region ist: "slot" (weg, Knopf flach), "bg" (weg, Innenflaeche),
-- "decor" (weg) oder nil (bleibt).
local function Kind(r)
    local atlas = AtlasOf(r)
    if atlas then
        if Any(BK.SLOT_ATLAS, atlas) then return "slot" end
        if atlas:find(BK.BG_ATLAS) then return "bg" end
        if Any(BK.DECOR_ATLAS, atlas) then return "decor" end
        return nil
    end
    if FileOf(r) == BK.BUTTON_FILE then return "slot" end
    return nil
end
BK.Kind = Kind

-- Symbol oder Rand der Qualitaet? Dann nie anfassen.
local function IsIcon(owner, r)
    if r == owner.icon or r == owner.Icon or r == owner.IconTexture or r == owner.IconBorder
        or r == owner.IconOverlay then return true end
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

-- Innenflaeche genau dort, wo der Grund des Spiels lag.
local function Surface(owner, r)
    if surfaces[r] or not owner.CreateTexture then return end
    local t = owner:CreateTexture(nil, "BACKGROUND", nil, -8)
    t:SetAllPoints(r)
    local s1 = C.surface1
    t:SetColorTexture(s1[1], s1[2], s1[3], 0.45)
    surfaces[r] = t
    W.Insets[owner] = true
end

local function Hide(r)
    if K.Plain(r:GetAlpha()) ~= 0 then r:SetAlpha(0) end
    hidden[r] = true
end

-- Ausgeblendetes, das jetzt etwas anderes zeigt, wieder zeigen.
local function Release()
    for r in pairs(hidden) do
        if not Kind(r) then
            r:SetAlpha(1)
            hidden[r] = nil
        end
    end
end

local function Walk(f, depth, m)
    if depth > BK.DEPTH or type(f) ~= "table" or (f.IsForbidden and f:IsForbidden()) then return end
    for _, r in ipairs(W.Regions(f, "bank", depth)) do
        if not IsIcon(f, r) then
            local kind = Kind(r)
            if kind then
                Hide(r)
                if kind == "slot" then Flat(f)
                elseif kind == "bg" then Surface(f, r) m.surface = true end
            end
        end
    end
    for _, ch in ipairs(W.Children(f, "bank", depth)) do Walk(ch, depth + 1, m) end
end

-- Geldrahmen unten: BankPanel.MoneyFrame.Border.
local function Money(f)
    local panel = f.BankPanel
    if not IsFrame(panel) then panel = _G.BankPanel end
    local mf = IsFrame(panel) and panel.MoneyFrame or nil
    local border = IsFrame(mf) and mf.Border or nil
    if IsFrame(border) then
        W.OwnBackground(border)
        return true
    end
    return false
end

function BK.Update(f)
    local m = frames[f]
    if not m then
        local accent = S.Accent(BK.STYLE.accent)
        m = {}
        m.edge = S.Under(S.Divider(f, accent, BK.EDGE, 0), -3)
        S.PlaceTop(m.edge, f, 10, -1)
        frames[f] = m
    end
    Release()
    Walk(f, 0, m)
    m.money = Money(f)
    return m
end

function BK.Report(f, out)
    local m = frames[f]
    if not m then return out end
    local nf, nh = 0, 0
    for _ in pairs(flat) do nf = nf + 1 end
    for _ in pairs(hidden) do nh = nh + 1 end
    out[#out + 1] = string.format("   %s (Stil %s): Kante in Gold, kein Schein der Klasse · Plätze flach %d · Bilder weg %d · Grund %s · Geld %s",
        BK.LABEL, BK.STYLE.name, nf, nh, m.surface and "auf Fläche" or "nicht gefunden",
        m.money and "auf Fläche" or "nicht gefunden")
    return out
end
