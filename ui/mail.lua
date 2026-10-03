--------------------------------------------------
-- WeintCodex :: Oberflaeche - Post (6.9.1.2)
--------------------------------------------------
-- Der Briefkasten des Spiels (MailFrame: Posteingang und "Post
-- versenden") in der ruhigen Informationsoberflaeche. Post gehoert nicht
-- zur Klasse: GOLD (S.CALM), wie Bank, Handel und Auktionshaus. Beta-Test
-- 6.9.1.1: Metallrahmen, Marmor, Pergament, Steinplaetze, Eingabefelder
-- mit Goldrand, Holzleisten.
--
--   Huelle     Metallrahmen, Marmor, Streifen weg (W.WINDOWS), das Symbol
--              des Briefkastens oben links weg (wie die Portraets), Kachel,
--              kein Schein der Klasse, Licht und Kante in Gold (ui/calm.lua,
--              Gast "Post").
--   Pergament  im Posteingang (Bild 530419) und hinter dem Brief beim
--              Versenden (136859, 136860) weg, an seiner Stelle eine
--              Innenflaeche. Die Schrift des Briefs ist auf Pergament
--              dunkelbraun - auf der Flaeche wird sie hell (ML.TEXTS).
--   Zeilen     im Posteingang: Rahmen der Zeile (Bild 136383) weg, der
--              Knopf mit dem Symbol flach mit 1 px Rand.
--   Plaetze    die Anhaenge beim Versenden: Stein (130862) und Rand (130718)
--              weg, flach wie im Handel.
--   Felder     "An", "Betreff" und die drei Geldfelder: Goldrand (130975)
--              weg, eine flache Leiste.
--   Leisten    die Trennleisten beim Versenden (130968) weg.
--   Geld       Grund unten (SendMailMoneyBg, 525911) als Innenflaeche; die
--              Innenflaeche des Fensters (MailFrameInset) wie ueberall.
--   Reiter     "Posteingang", "Post versenden" flach, der gewaehlte in Gold.
--   Knoepfe    "Alle oeffnen", "Senden", "Abbrechen": flach (W.SkinPanelButtons
--              im Durchlauf). Blaettern, Geld oder Nachnahme bleiben.
--
-- DAS SYMBOL EINES GEGENSTANDS ODER BRIEFS BLEIBT, ebenso der Rand der
-- Qualitaet. Ausgeblendet wird ein Bild nur, solange es eines der
-- gemessenen ist; zeigt dieselbe Region spaeter etwas anderes, wird sie
-- wieder sichtbar. Geaendert werden nur Bilder und Schriftfarben - kein
-- Skript, kein Feld.
--
-- GEMESSEN (6.9.1.0, /wcui fenster, beide Reiter): MailFrame (374155,
-- NineSlice "UI-Frame-Metal-*", "UI-Frame-PortraitMetal-*", Streifen),
-- MailFrame.PortraitContainer (136382), MailFrameInset (374154,
-- "!UI-Frame-InnerLeftTile"), InboxFrame (530419), MailItem1 (136383 14x,
-- leeres Symbol 7x), OpenAllMail (130828/130826), PrevPageButton (130757),
-- MailFrameTab1 ("uiframe-tab-*", "uiframe-activetab-*"),
-- SendMailScrollFrame (136859, 136860), SendMailNameEditBox (130975 15x),
-- SendMailAttachment1 (130862 7x, 130718 7x), SendMailFrame (130968 4x),
-- SendMailMoneyBg (525911 3x), SendMailMailButton (130824).
-- UNGEMESSEN: ein geoeffneter Brief (OpenMailFrame) - er bekommt Huelle und
-- Gold, sein Pergament sagt erst /wcui fenster bei offenem Brief.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIMail = {}

local ML = WeintCodex.UIMail
local K = WeintCodex.UIKit
local C = WeintCodex.Colors
local GC = WeintCodex.GameColors
local W = WeintCodex.UIWindows
local S = WeintCodex.UIStyle
local RG = WeintCodex.UIRegister

local IsFrame = RG.IsFrame

ML.LABEL = "Post"
ML.HOST = "MailFrame"
ML.STYLE = S.CALM
ML.EDGE = 0.5
ML.DEPTH = 5
-- Bild -> was es ist (gemessen).
ML.KIND = {
    [530419] = "bg",     -- Pergament des Posteingangs
    [136859] = "bg",     -- Pergament hinter dem Brief, oben
    [136860] = "bg",     -- und unten
    [136383] = "row",    -- Rahmen einer Zeile im Posteingang
    [130862] = "slot",   -- Stein eines Anhangs
    [130718] = "slot",   -- Rand des Knopfs
    [130975] = "field",  -- Goldrand der Eingabefelder
    [130968] = "decor",  -- Trennleisten beim Versenden
    [136382] = "decor",  -- Symbol des Briefkastens oben links
}
ML.MONEY = { "SendMailMoneyBg" }
-- Schrift, die auf Pergament dunkel war und auf der Flaeche hell sein muss.
ML.TEXTS = { "SendMailBodyEditBox", "MailEditBox" }
ML.ROW_BUTTON = "MailItem%dButton"
ML.ROWS = 7
ML.TAB_NAMES = { "MailFrameTab1", "MailFrameTab2" }
ML.FIELD_ALPHA = 0.55

S.SCOPES[ML.HOST] = ML.STYLE
W.HOSTED[ML.HOST] = W.HOSTED[ML.HOST] or {}
table.insert(W.HOSTED[ML.HOST], ML)

local frames = setmetatable({}, { __mode = "k" })
local flat = setmetatable({}, { __mode = "k" })      -- Knopf -> { bg, edge }
local fields = setmetatable({}, { __mode = "k" })    -- Eingabefeld -> Leiste
local hidden = setmetatable({}, { __mode = "k" })    -- Region -> true
local surfaces = setmetatable({}, { __mode = "k" })  -- Pergament -> Flaeche
ML.frames, ML.flat, ML.fields, ML.hidden, ML.surfaces = frames, flat, fields, hidden, surfaces

local function FileOf(r)
    if type(r) ~= "table" or not r.GetTexture then return nil end
    local ok, v = pcall(r.GetTexture, r)
    return ok and K.Plain(v) or nil
end

local function Kind(r)
    local id = FileOf(r)
    return id and ML.KIND[id] or nil
end
ML.Kind = Kind

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

-- Eingabefeld: eine flache Leiste mit 1 px Rand.
local function Field(b)
    if fields[b] or not b.CreateTexture then return end
    local bg = b:CreateTexture(nil, "BACKGROUND", nil, -7)
    bg:SetAllPoints(b)
    local c = GC.plateBg
    bg:SetColorTexture(c[1], c[2], c[3], ML.FIELD_ALPHA)
    fields[b] = { bg = bg, edge = K.Border(b, 1, 0, 0, 0, 1, "BORDER") }
end

-- Innenflaeche genau dort, wo das Pergament lag.
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
    if depth > ML.DEPTH or type(f) ~= "table" or (f.IsForbidden and f:IsForbidden()) then return end
    -- Innenflaeche (InsetFrameTemplate: Leder + NineSlice) wie im Handel.
    if depth > 0 and type(f.Bg) == "table" and type(f.NineSlice) == "table" then
        W.OwnBackground(f)
        m.insets = m.insets + 1
    end
    for _, r in ipairs(W.Regions(f, "mail", depth)) do
        if not IsIcon(f, r) then
            local kind = Kind(r)
            if kind then
                Hide(r)
                if kind == "slot" then Flat(f)
                elseif kind == "field" then Field(f)
                elseif kind == "bg" then Surface(f, r) m.parchment = m.parchment + 1 end
            end
        end
    end
    for _, ch in ipairs(W.Children(f, "mail", depth)) do Walk(ch, depth + 1, m) end
end

-- Die Knoepfe der Zeilen im Posteingang (das Symbol eines Briefs).
local function Rows()
    local n = 0
    for i = 1, ML.ROWS do
        local b = _G[ML.ROW_BUTTON:format(i)]
        if IsFrame(b) then Flat(b) n = n + 1 end
    end
    return n
end

local function Texts()
    local n = 0
    for _, key in ipairs(ML.TEXTS) do
        local t = _G[key]
        if type(t) == "table" and t.SetTextColor then
            t:SetTextColor(unpack(C.textBright))
            n = n + 1
        end
    end
    return n
end

local function Tabs(f, m, accent)
    local selected = K.Plain(f.selectedTab)
    local n = 0
    for i, name in ipairs(ML.TAB_NAMES) do
        local tab = _G[name]
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

function ML.Update(f)
    local accent = S.Accent(ML.STYLE.accent)
    local m = frames[f]
    if not m then
        m = {}
        m.edge = S.Under(S.Divider(f, accent, ML.EDGE, 0), -3)
        S.PlaceTop(m.edge, f, 10, -1)
        frames[f] = m
    end
    local money = 0
    for _, key in ipairs(ML.MONEY) do
        local part = _G[key]
        if IsFrame(part) then W.OwnBackground(part) money = money + 1 end
    end
    m.money = money
    Release()
    m.insets, m.parchment = 0, 0
    Walk(f, 0, m)
    m.rows = Rows()
    -- Die Schrift erst, wenn das Pergament weg ist - vorher waere helle
    -- Schrift auf hellem Pergament unlesbar.
    m.texts = m.parchment > 0 and Texts() or 0
    Tabs(f, m, accent)
    return m
end

function ML.Report(f, out)
    local m = frames[f]
    if not m then return out end
    local nf, nb = 0, 0
    for _ in pairs(flat) do nf = nf + 1 end
    for _ in pairs(fields) do nb = nb + 1 end
    out[#out + 1] = string.format("   %s (Stil %s): Kante in Gold, kein Schein der Klasse · Pergament auf Fläche %d · Plätze und Zeilen flach %d · Felder flach %d · Innenflächen %d · Geld %d · Schrift hell %d · Reiter %d",
        ML.LABEL, ML.STYLE.name, m.parchment or 0, nf, nb, m.insets or 0, m.money or 0, m.texts or 0, m.tabs or 0)
    return out
end
