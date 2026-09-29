--------------------------------------------------
-- WeintCodex :: Oberflaeche - Charakterfenster (6.6.4.0)
--------------------------------------------------
-- Neukonzept (Beta-Test): kein graues Standardfenster ueber einem Bild,
-- sondern EIN System aus
--
--     dunkler neutraler Basis
--   + Szene der Klasse hinter der Figur
--   + Klassenfarbe als einzigem Akzent
--   + 3D-Figur als Mittelpunkt
--   + klarer Hierarchie: Figur > Szene > Name/Klasse/Stufe > Werte und
--     Ausruestung > Schmuck (so wenig wie noetig).
--
-- Gebaut wird NICHTS Paralleles: Figur, Ausruestungsplaetze, Werte,
-- Reiter und Knoepfe sind die des Spiels und tun, was sie immer taten.
-- Dieses Modul aendert nur Aussehen (Deckkraft, Farbe, eigene Flaechen
-- daneben und dahinter) - kein SetText auf fremde Zeilen, kein Feld auf
-- einem Rahmen des Spiels, keine geschuetzte Funktion.
--
-- Sieben Teile, jeder fuer sich (Reihenfolge = Aufruf in CS.Update):
--
--   1. Layout       CS.Layout   Basis, Innenflaechen, Glasebene rechts
--   2. Szene        CS.Scene    Bild hinter der Figur, Vignette, Ruhe
--   3. Thema        CS.Theme    was je Klasse anders ist (data/classthemes.lua)
--   4. Akzent       CS.Accent   die Klassenfarbe - der Akzent der ganzen
--                               Oberflaeche (core/ui.lua, SetAccent)
--   5. Ausruestung  CS.Slots    Plaetze: leer neutral, belegt/Maus im Akzent
--   6. Information  CS.Header   Name, Klasse, Stufe oben; keine Doppelung
--                   CS.Info     Werte: Namen ruhig, Zahlen hell
--   7. Licht        CS.Light    Licht der 3D-Szene, Schatten, Dunst
--
-- Der Rahmen um das Modell - wo das Bild liegt, seine weiche Maske -
-- kommt aus ui/windows.lua (W.SoftenModel): dasselbe Werkzeug wie fuer
-- die Karte, hier nur benutzt.
--
-- NEUE KLASSE: nichts in dieser Datei. Bild und Thema eintragen, siehe
-- Kopf von data/classthemes.lua.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UICharacter = {}

local CS = WeintCodex.UICharacter
local K = WeintCodex.UIKit
local C = WeintCodex.Colors
local W = WeintCodex.UIWindows
local GC = WeintCodex.GameColors

local function Opt(k) return K.Get("general", k) end
local function Own(t) W.own[t] = true return t end
local function Num(v)
    v = K.Plain(v)
    return type(v) == "number" and v or nil
end
local function LevelOf(f)
    if type(f) ~= "table" then return nil end
    local ok, v = pcall(f.GetFrameLevel, f)
    return ok and Num(v) or nil
end
CS.LevelOf = LevelOf

-- Waagerechter oder senkrechter Verlauf einer Farbe von `a0` nach `a1`.
-- VERTICAL: a0 unten, a1 oben; HORIZONTAL: a0 links, a1 rechts.
local function Gradient(t, dir, c, a0, a1)
    t:SetColorTexture(1, 1, 1, 1)
    if _G.CreateColor and t.SetGradient then
        t:SetGradient(dir, _G.CreateColor(c[1], c[2], c[3], a0), _G.CreateColor(c[1], c[2], c[3], a1))
    else
        t:SetColorTexture(c[1], c[2], c[3], (a0 + a1) / 2)
    end
end
CS.Gradient = Gradient

local BLACK = { 0, 0, 0 }

--------------------------------------------------
-- 3. Thema
--------------------------------------------------
function CS.ClassToken()
    local ok, _, token = pcall(_G.UnitClass, "player")
    token = ok and K.Plain(token) or nil
    return type(token) == "string" and token or nil
end

-- Einmal je Sitzung; ohne Antwort des Clients (noch) kein fester Wert.
function CS.Theme()
    if CS.theme then return CS.theme end
    local token = CS.ClassToken()
    local theme = WeintCodex.ClassTheme(token)
    if token then CS.theme = theme end
    return theme
end

--------------------------------------------------
-- 4. Akzent
--------------------------------------------------
-- Die Klassenfarbe, wie sie jede Flaeche der Oberflaeche traegt
-- (K.Highlight = C.accent, seit 6.6.3.1 die Klassenfarbe). Die Tabelle
-- wird bei einem Wechsel der Einstellung an Ort und Stelle umgerechnet;
-- wer sie jedes Mal hier holt, sieht die aktuelle.
function CS.Accent() return K.Highlight() end

--------------------------------------------------
-- 1. Layout
--------------------------------------------------
-- Die Basis: statt der grau-schwarzen Kachel sehr dunkles Anthrazit. Die
-- Innenflaechen (Inset) - die grauen Bloecke links und rechts - gehen;
-- der Schein der Klasse oben im Fenster wird ein Hauch (er faerbte das
-- halbe Fenster). Rechts liegt eine dunkle Glasebene mit weicher linker
-- Kante ueber dem Auslauf der Szene, an ihrer Kante eine feine Linie im
-- Akzent: die Werte liegen UEBER der Szene, nicht in einem zweiten Fenster.
-- 6.6.4.1: 0 - der weisse Schein des Priesters lag als graue Flaeche
-- oben ueber dem rechten Bereich (Beta-Test). Der Akzent bleibt fuer
-- Linien, Rauten und Zustaende.
CS.TOP_GLOW = 0
CS.GLASS_EDGE = 80          -- Breite der weichen linken Kante (6.6.4.1: 44 war zu hart)
CS.GLASS_PAD = 6            -- so weit ragt das Glas ueber die Werte
CS.GLASS_LINE = 0.22        -- Deckkraft der Linie im Akzent

local layout = setmetatable({}, { __mode = "k" })
CS.layouts = layout

-- Der sichtbare rechte Bereich: die Innenflaeche rechts, sonst der
-- Rahmen, in dem die Werte laufen (ihr Bildlauf), sonst die Werte selbst.
-- 6.6.4.2: in diesem Client laufen die Werte in CharacterStatsPaneScrollBox;
-- CharacterStatsPane selbst meldet sich unsichtbar (/wcui fenster:
-- "Glas CharacterStatsPane, eingeklappt") - das Glas wurde nie gezeichnet.
-- Jetzt gilt der erste SICHTBARE Kandidat, sonst der erste vorhandene.
CS.RIGHT_PANES = { "InsetRight", "CharacterStatsPaneScrollBox", "CharacterStatsPane" }

local function Visible(t)
    local ok, v = pcall(t.IsVisible, t)
    return ok and K.Bool(v, false) or false
end

function CS.RightPane(f)
    local first, firstName
    for _, n in ipairs(CS.RIGHT_PANES) do
        local t = (n == "InsetRight") and f.InsetRight or _G[n]
        if n == "InsetRight" and type(t) ~= "table" and f.GetName and f:GetName() then t = _G[f:GetName() .. "InsetRight"] end
        if type(t) == "table" and t.GetObjectType then
            if Visible(t) then return t, n end
            if not first then first, firstName = t, n end
        end
    end
    return first, firstName
end

local function Glass(f, theme)
    local target, name = CS.RightPane(f)
    if not target then return nil end
    local g = { target = target, name = name }
    local c, a, pad = GC.showcaseGlass, theme.glass or 0.8, CS.GLASS_PAD
    -- Auf dem Fenster selbst, ueber Basis und Schein (BACKGROUND -7/-6),
    -- unter allem, was das Spiel zeichnet.
    g.body = Own(f:CreateTexture(nil, "BACKGROUND", nil, -4))
    g.body:SetColorTexture(c[1], c[2], c[3], a)
    g.frame = f
    g.edge = Own(f:CreateTexture(nil, "BACKGROUND", nil, -4))
    g.edge:SetPoint("TOPRIGHT", g.body, "TOPLEFT", 0, 0)
    g.edge:SetPoint("BOTTOMRIGHT", g.body, "BOTTOMLEFT", 0, 0)
    g.edge:SetWidth(CS.GLASS_EDGE)
    Gradient(g.edge, "HORIZONTAL", c, 0, a)
    -- Linie im Akzent, oben und unten auslaufend.
    local acc = CS.Accent()
    g.lineTop = Own(f:CreateTexture(nil, "BACKGROUND", nil, -3))
    g.lineTop:SetWidth(1)
    g.lineTop:SetPoint("TOPLEFT", g.body, "TOPLEFT", 0, 0)
    g.lineTop:SetPoint("BOTTOMLEFT", g.body, "LEFT", 0, 0)
    Gradient(g.lineTop, "VERTICAL", acc, CS.GLASS_LINE, 0)
    g.lineBottom = Own(f:CreateTexture(nil, "BACKGROUND", nil, -3))
    g.lineBottom:SetWidth(1)
    g.lineBottom:SetPoint("TOPLEFT", g.body, "LEFT", 0, 0)
    g.lineBottom:SetPoint("BOTTOMLEFT", g.body, "BOTTOMLEFT", 0, 0)
    Gradient(g.lineBottom, "VERTICAL", acc, 0, CS.GLASS_LINE)
    g.parts = { g.body, g.edge, g.lineTop, g.lineBottom }
    CS.AnchorGlass(g, target, name)
    return g
end

-- Das Glas reicht von unter dem Titelbalken (CS.GLASS_TOP) bis unter die
-- Werte: EINE Flaeche rechts, die mit "Allgemein" beginnt - kein
-- Kasten erst ab der Liste. Links haengt es an der Kante der Werte.
CS.GLASS_TOP = -30
function CS.AnchorGlass(g, target, name)
    g.target, g.name, g.dx = target, name, nil
    CS.PlaceGlass(g)
end

function CS.PlaceGlass(g)
    local tok, tl = pcall(g.target.GetLeft, g.target)
    local fok, fl = pcall(g.frame.GetLeft, g.frame)
    tl, fl = tok and Num(tl) or nil, fok and Num(fl) or nil
    local dx = (tl and fl) and (tl - fl - CS.GLASS_PAD) or false
    if g.dx == dx then return end
    g.dx = dx
    local pad = CS.GLASS_PAD
    g.body:ClearAllPoints()
    if dx then
        g.body:SetPoint("TOPLEFT", g.frame, "TOPLEFT", dx, CS.GLASS_TOP)
    else
        g.body:SetPoint("TOPLEFT", g.target, "TOPLEFT", -pad, pad)
    end
    g.body:SetPoint("BOTTOMRIGHT", g.target, "BOTTOMRIGHT", pad, -pad)
end

function CS.Layout(f, d, theme)
    local L = layout[f]
    if not L then
        L = {}
        if d and d.kachel then
            local b = GC.showcaseBase
            d.kachel.bg:SetColorTexture(b[1], b[2], b[3], b[4])
            L.base = true
        end
        for _, key in ipairs({ "Inset", "InsetRight", "InsetLeft" }) do
            if d and d[key] then d[key]:SetAlpha(0) end
        end
        L.glass = Glass(f, theme)
        layout[f] = L
    end
    -- Der Schein der Klasse oben (W.AddGlow): 6.6.4.2 in JEDEM Durchlauf
    -- gehalten. Einmal auf Deckkraft 0 gesetzt, war er im Beta-Test
    -- trotzdem da (gemessen: neutralgrau 99 oben, bis 260 px auslaufend -
    -- genau dieser Schein, weiss beim Priester) - jetzt versteckt statt
    -- durchsichtig, und nachgezogen, falls ihn etwas wieder zeigt.
    local glow = d and d.glow
    if glow then
        if CS.TOP_GLOW <= 0 then
            if glow:IsShown() then glow:Hide() end
        elseif glow:GetAlpha() ~= CS.TOP_GLOW then
            glow:SetAlpha(CS.TOP_GLOW)
        end
        L.glow = glow
    end
    -- Das Glas folgt dem rechten Bereich (der laesst sich einklappen);
    -- ist sein Traeger weg, nimmt es den naechsten sichtbaren.
    local g = L.glass
    if g then
        if not Visible(g.target) then
            local t, n = CS.RightPane(f)
            if t and t ~= g.target and Visible(t) then CS.AnchorGlass(g, t, n) end
        end
        CS.PlaceGlass(g)
        local shown = Visible(g.target)
        if g.shown ~= shown then
            g.shown = shown
            for _, t in ipairs(g.parts) do t:SetShown(shown) end
        end
    end
    return L
end

--------------------------------------------------
-- 2. Szene
--------------------------------------------------
-- Im Kasten des Modellbildes (e.box aus W.SoftenModel), mit dessen weicher
-- Maske. Schichten, von hinten nach vorn:
--   BACKGROUND/0  Buehne des Spiels (vier Teile)
--   BACKGROUND/7  Bild der Klasse (Thema `scene`)
--   BORDER/0      Abdunklung des Spiels (Thema `gameOverlay`)
--   BORDER/1      Vignette (Thema `vignette`)
--   BORDER/2      Ruhe hinter der Figur (Thema `calm`)
--   BORDER/3      Schatten unter den Fuessen (Licht, Thema `shadow`)
--   [Figur]
--   eigener Rahmen darueber: Dunst und Lichthauch (Licht)
CS.ART_LAYER, CS.ART_SUB = "BACKGROUND", 7
-- Lage relativ zum Kasten: Brust (Ruhe), Fuesse (Schatten, gemessen bei
-- Standardkamera rund 11 % ueber der Unterkante), Dunst im untersten Sechstel.
CS.CALM_Y, CS.FEET_Y, CS.HAZE_H = 0.45, 0.09, 0.17
-- RIGHT breiter (6.6.4.1): der Uebergang zur Glasebene ist eine weiche
-- dunkle Zone, keine Kante.
CS.VIGNETTE = { TOP = 0.28, BOTTOM = 0.22, LEFT = 0.22, RIGHT = 0.34 }

local function Halo(frame, layer, sub, mask)
    local t = Own(frame:CreateTexture(nil, layer, nil, sub))
    t:SetTexture(K.MEDIA .. "halo")
    if mask then pcall(t.AddMaskTexture, t, mask) end
    return t
end

local function Masked(t, mask)
    if mask then pcall(t.AddMaskTexture, t, mask) end
    return t
end

function CS.Scene(e, host, theme)
    if e.scene then return e.scene end
    local s = { theme = theme }
    e.scene = s
    local art = theme.art
    if art then
        local t = Own(host:CreateTexture(nil, CS.ART_LAYER, nil, CS.ART_SUB))
        t:SetTexture("Interface\\AddOns\\WeintCodex\\media\\" .. string.gsub(art.file, "/", "\\"))
        t:SetAllPoints(e.box)
        local dim = art.dim or 1
        t:SetVertexColor(dim, dim, dim, 1)
        s.art = Masked(t, e.mask)
    end
    if (theme.vignette or 0) > 0 then
        s.vignette = {}
        for side in pairs(CS.VIGNETTE) do
            local v = Masked(Own(host:CreateTexture(nil, "BORDER", nil, 1)), e.mask)
            local a = theme.vignette
            if side == "TOP" then Gradient(v, "VERTICAL", BLACK, 0, a)
            elseif side == "BOTTOM" then Gradient(v, "VERTICAL", BLACK, a, 0)
            elseif side == "LEFT" then Gradient(v, "HORIZONTAL", BLACK, a, 0)
            else Gradient(v, "HORIZONTAL", BLACK, 0, a) end
            s.vignette[side] = v
        end
    end
    if (theme.calm or 0) > 0 then
        s.calm = Halo(host, "BORDER", 2, e.mask)
        s.calm:SetVertexColor(0, 0, 0, theme.calm)
    end
    return s
end

-- Jeder Durchlauf: die Abdunklung des Spiels so, wie das Thema sie will
-- (das Spiel tauscht das Bild je Volk, die Deckkraft bleibt - geprueft
-- wird trotzdem, ohne Tabellen), Lage nur wenn der Kasten sich aendert.
function CS.KeepScene(e)
    local s = e.scene
    if not s then return end
    if not s.theme.gameOverlay then
        for _, r in ipairs(e.parts) do
            local ok, a = pcall(r.GetAlpha, r)
            if not (ok and Num(a) == 0) then pcall(r.SetAlpha, r, 0) end
        end
    end
    if s.key == e.key then return end
    s.key = e.key
    local ok, w, h = pcall(function() return e.box:GetWidth(), e.box:GetHeight() end)
    w, h = ok and Num(w) or nil, ok and Num(h) or nil
    if s.art then
        local a = s.theme.art
        s.art:SetTexCoord(WeintCodex.CoverCoords(a.w, a.h, w, h, a.focusX, a.focusY))
    end
    if not (w and h) then return end
    if s.vignette then
        for side, v in pairs(s.vignette) do
            v:ClearAllPoints()
            local share = CS.VIGNETTE[side]
            if side == "TOP" or side == "BOTTOM" then
                v:SetPoint(side .. "LEFT", e.box, side .. "LEFT", 0, 0)
                v:SetPoint(side .. "RIGHT", e.box, side .. "RIGHT", 0, 0)
                v:SetHeight(h * share)
            else
                v:SetPoint("TOP" .. side, e.box, "TOP" .. side, 0, 0)
                v:SetPoint("BOTTOM" .. side, e.box, "BOTTOM" .. side, 0, 0)
                v:SetWidth(w * share)
            end
        end
    end
    if s.calm then
        s.calm:ClearAllPoints()
        s.calm:SetSize(w * 0.75, h * 0.8)
        s.calm:SetPoint("CENTER", e.box, "TOP", 0, -h * CS.CALM_Y)
    end
    CS.PlaceLight(e, w, h)
end

--------------------------------------------------
-- 7. Licht und Atmosphaere
--------------------------------------------------
-- Die Figur soll in der Szene stehen, nicht davor: Licht der 3D-Szene in
-- den Farben des Bildes (ModelScene:SetLightAmbientColor/-DiffuseColor,
-- Richtung bleibt die des Spiels - echtes Randlicht kann der Client
-- nicht), Schatten unter den Fuessen, darueber Dunst am Boden und ein
-- Hauch der Lichtfarbe. Kein Leuchten um die Figur.
-- Die Schicht ueber der Figur liegt eine Ebene ueber dem Modell und nur,
-- solange die Ausruestungsplaetze hoeher liegen - der Dunst darf die
-- Waffenplaetze nicht verdunkeln.
CS.SLOT_NAMES = { "CharacterHeadSlot", "CharacterHandsSlot", "CharacterMainHandSlot", "CharacterSecondaryHandSlot" }

local function ModelSceneOf(host)
    if type(host.SetLightAmbientColor) == "function" then return host end
    local s = _G.CharacterModelScene
    if type(s) == "table" and type(s.SetLightAmbientColor) == "function" then return s end
    return nil
end

function CS.Light(e, host, theme)
    if e.light then return e.light end
    local m = { scene = ModelSceneOf(host), lit = 0, theme = theme }
    e.light = m
    if (theme.shadow or 0) > 0 then
        m.shadow = Halo(host, "BORDER", 3, e.mask)
        m.shadow:SetVertexColor(0, 0, 0, theme.shadow)
    end
    if (theme.haze or 0) > 0 or theme.wash then
        local o = CreateFrame("Frame", nil, host)
        o:SetAllPoints(e.box)
        -- Eine Maske wirkt nur in ihrem Rahmen: eigene.
        local mok, mask = pcall(function() return o:CreateMaskTexture() end)
        if mok and type(mask) == "table" then
            mask:SetTexture(W.SOFT_MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
            mask:SetAllPoints(e.box)
            Own(mask)
        else
            mask = nil
        end
        if (theme.haze or 0) > 0 then
            m.haze = Masked(Own(o:CreateTexture(nil, "ARTWORK", nil, 0)), mask)
            m.haze:SetPoint("BOTTOMLEFT", e.box, "BOTTOMLEFT", 0, 0)
            m.haze:SetPoint("BOTTOMRIGHT", e.box, "BOTTOMRIGHT", 0, 0)
            Gradient(m.haze, "VERTICAL", C.surface1, theme.haze, 0)
        end
        if theme.wash then
            local c = theme.wash
            m.wash = Masked(Own(o:CreateTexture(nil, "ARTWORK", nil, 1)), mask)
            m.wash:SetAllPoints(e.box)
            m.wash:SetColorTexture(c[1], c[2], c[3], c[4])
            pcall(m.wash.SetBlendMode, m.wash, "ADD")
        end
        m.over = o
    end
    return m
end

function CS.PlaceLight(e, w, h)
    local m = e.light
    if not m then return end
    if m.shadow then
        m.shadow:ClearAllPoints()
        m.shadow:SetSize(w * 0.5, h * 0.08)
        m.shadow:SetPoint("CENTER", e.box, "BOTTOM", 0, h * CS.FEET_Y)
    end
    if m.haze then m.haze:SetHeight(h * CS.HAZE_H) end
end

local function SlotLevel()
    local low
    for _, n in ipairs(CS.SLOT_NAMES) do
        local l = LevelOf(_G[n])
        if l and (not low or l < low) then low = l end
    end
    return low
end
CS.SlotLevel = SlotLevel

local function Close(a, b) a = Num(a) return a ~= nil and math.abs(a - b) < 0.01 end

-- Jeder Durchlauf: Licht vergleichen und nur nach einem Zuruecksetzen
-- neu setzen (ohne Getter: jedes Mal - billig, ohne Tabellen); Ebene der
-- Schicht ueber der Figur halten.
function CS.KeepLight(e)
    local m = e.light
    if not m then return end
    local L, s = m.theme.light, m.scene
    if s and L and L.ambient then
        local ok, r, g, b = pcall(s.GetLightAmbientColor, s)
        local a = L.ambient
        if not (ok and Close(r, a[1]) and Close(g, a[2]) and Close(b, a[3])) then
            pcall(s.SetLightAmbientColor, s, a[1], a[2], a[3])
            if L.diffuse then pcall(s.SetLightDiffuseColor, s, L.diffuse[1], L.diffuse[2], L.diffuse[3]) end
            m.lit = m.lit + 1
        end
    end
    if m.over then
        local sl, slots = LevelOf(s) or LevelOf(m.over:GetParent()), SlotLevel()
        local want = sl and sl + 1
        local fits = want ~= nil and (slots == nil or slots > want)
        if fits and LevelOf(m.over) ~= want then m.over:SetFrameLevel(want) end
        if m.over:IsShown() ~= fits then m.over:SetShown(fits) end
        m.overLevel, m.slotLevel, m.sceneLevel = want, slots, sl
    end
end

--------------------------------------------------
-- 6. Information: Kopfbereich
--------------------------------------------------
-- HOLY LARENA
-- PRIESTERIN · STUFE 13
-- ────────── ◆ ──────────   (Akzent)
--
-- Ueber der Szene, mittig ueber dem Modell. Der Titel des Spiels und die
-- Zeile "Stufe 13, Priesterin" rechts sind so lange unsichtbar (Deckkraft),
-- wie die Kopfzeile zu sehen ist - also auf dem Reiter Charakter; auf
-- Ruf, Waehrung usw. steht der Titel wie immer. Der Name kommt aus dem
-- Titel des Spiels (mit Titel wie "Hueter ..."), sonst aus UnitName.
-- Klasse und Stufe beim Zeigen und bei PLAYER_LEVEL_UP, nicht im Durchlauf.
-- HEAD_Y und die Abstaende 6.6.4.2 enger: Raute und Linie lagen in der
-- Reihe der Zoomknoepfe ueber dem Modell.
CS.NAME_SIZE, CS.SUB_SIZE, CS.LINE_W, CS.HEAD_Y = 18, 10, 90, -5
CS.REDUNDANT = { "CharacterLevelText" }

function CS.IdentityLine(className, level)
    className = K.Plain(className)
    level = K.Plain(level)
    local parts = {}
    if type(className) == "string" and className ~= "" then parts[#parts + 1] = WeintCodex.Upper(className) end
    if type(level) == "number" and level > 0 then parts[#parts + 1] = "STUFE " .. level end
    if #parts == 0 then return nil end
    return WeintCodex.Spaced(table.concat(parts, " · "))
end

function CS.NameLine(name)
    name = K.Plain(name)
    if type(name) ~= "string" or name == "" then return nil end
    return WeintCodex.Upper(name)
end

-- Wie StyleTitle in ui/windows.lua: der Titel liegt je nach Client an
-- TitleContainer.TitleText, an .TitleText oder heisst <Name>TitleText.
-- 6.6.4.2: nur der erste Weg war gefragt - in diesem Client blieb
-- "Holy Larena" deshalb neben der Kopfzeile stehen (Beta-Test).
local function Title(f)
    local tc = f.TitleContainer
    if type(tc) == "table" and type(tc.TitleText) == "table" then return tc.TitleText end
    if type(f.TitleText) == "table" then return f.TitleText end
    local n = f.GetName and f:GetName()
    local t = type(n) == "string" and _G[n .. "TitleText"]
    return type(t) == "table" and t or nil
end
CS.Title = Title

-- Deckkraft der Zeilen des Spiels, die die Kopfzeile ersetzt.
-- 6.6.4.3: zurueck geht jede Zeile auf die Deckkraft, die sie VOR uns
-- hatte - nicht pauschal auf 1 (sonst kaeme auf anderen Reitern zurueck,
-- was der Fensterstil schon ausgeblendet hatte).
local function Replace(h, t)
    for _, o in ipairs(h.replaced) do if o == t then return end end
    local ok, a = pcall(t.GetAlpha, t)
    h.orig[t] = ok and Num(a) or 1
    h.replaced[#h.replaced + 1] = t
end

local function Replaced(h, alpha)
    for _, t in ipairs(h.replaced) do
        pcall(t.SetAlpha, t, alpha == 0 and 0 or (h.orig[t] or 1))
    end
end

-- Die Zeile "Stufe 13, Priesterin" rechts oben heisst in diesem Client
-- nicht (sicher) CharacterLevelText (6.6.4.1, Beta-Test: doppelte
-- Anzeige). Gesucht wird sie am Inhalt: eine Schriftzeile im Reiter
-- Charakter, die Stufe UND Klasse nennt. Ihr Traeger bekommt keine
-- graue Flaeche mehr (seine grossen Bilder Deckkraft 0) - der rechte
-- Bereich beginnt dann mit "Allgemein".

local function Mentions(fs, className, level)
    local ok, text = pcall(fs.GetText, fs)
    text = ok and K.Plain(text) or nil
    return type(text) == "string" and text:find(level, 1, true) ~= nil and text:find(className, 1, true) ~= nil
end

local function FindIdentity(f, className, level, depth)
    if depth > 5 or type(f) ~= "table" or (f.IsForbidden and f:IsForbidden()) then return nil end
    for _, r in ipairs(W.Regions(f, "ident", depth)) do
        local ok, kind = pcall(r.GetObjectType, r)
        if ok and kind == "FontString" and not W.own[r] and Mentions(r, className, level) then return r end
    end
    for _, ch in ipairs(W.Children(f, "ident", depth)) do
        if ch ~= CS.head then
            local hit = FindIdentity(ch, className, level, depth + 1)
            if hit then return hit end
        end
    end
    return nil
end

function CS.FindDuplicate(h)
    if CS.dup ~= nil then return end
    local cok, className = pcall(_G.UnitClass, "player")
    local lok, level = pcall(_G.UnitLevel, "player")
    className, level = cok and K.Plain(className) or nil, lok and Num(level) or nil
    if type(className) ~= "string" or not level then return end
    local fs = FindIdentity(_G.PaperDollFrame, className, tostring(level), 0)
    if not fs then
        -- Nicht ewig suchen: nach 20 Durchlaeufen gilt "gibt es nicht".
        CS.dupTries = (CS.dupTries or 0) + 1
        if CS.dupTries >= 20 then CS.dup = false end
        return
    end
    CS.dup = fs
    -- Nur die Zeile selbst. Bis 6.6.4.2 gingen auch alle Bilder ab 60x14
    -- ihres Traegers mit - geraten (die graue Flaeche war der Schein) und
    -- zu breit: ist der Traeger das Fenster, trifft das Rahmenbilder.
    Replace(h, fs)
    Replaced(h, 0)
end

function CS.KeepHeaderLevel(h)
    local sl, hl = LevelOf(_G.CharacterModelScene), LevelOf(h)
    if sl and hl and hl <= sl + 2 then h:SetFrameLevel(sl + 3) end
end

function CS.Header(f)
    if CS.head then return CS.head end
    local paper = _G.PaperDollFrame
    if type(f) ~= "table" or type(paper) ~= "table" then return nil end
    local acc, bright = CS.Accent(), C.textBright
    local h = CreateFrame("Frame", nil, paper)
    h:SetSize(320, 52)
    h:SetPoint("TOP", f, "TOP", 0, CS.HEAD_Y)
    h.frame = f
    h.name = K.NewText(h, CS.NAME_SIZE, "OVERLAY")
    h.name:SetPoint("TOP", h, "TOP", 0, 0)
    h.name:SetTextColor(bright[1], bright[2], bright[3], 1)
    h.sub = K.NewText(h, CS.SUB_SIZE, "OVERLAY")
    h.sub:SetPoint("TOP", h.name, "BOTTOM", 0, -2)
    h.sub:SetTextColor(acc[1], acc[2], acc[3], 0.9)
    h.dot = W.Diamond(h, 6, acc, 1, 2)
    h.dot:SetPoint("TOP", h.sub, "BOTTOM", 0, -3)
    h.hole = W.Diamond(h, 2, C.surface1, 1, 3)
    h.hole:SetPoint("CENTER", h.dot, "CENTER", 0, 0)
    h.lines = {}
    for _, side in ipairs({ "LEFT", "RIGHT" }) do
        local line = Own(h:CreateTexture(nil, "ARTWORK", nil, 1))
        line:SetSize(CS.LINE_W, 1)
        W.Fade(line, acc, 0.8, side)
        if side == "LEFT" then line:SetPoint("RIGHT", h.dot, "LEFT", -3, 0)
        else line:SetPoint("LEFT", h.dot, "RIGHT", 3, 0) end
        h.lines[#h.lines + 1] = line
    end
    h.replaced, h.orig = {}, {}
    local title = Title(f)
    if type(title) == "table" and title.SetAlpha then Replace(h, title) end
    for _, n in ipairs(CS.REDUNDANT) do
        local t = _G[n]
        if type(t) == "table" and t.SetAlpha then Replace(h, t) end
    end
    function h.Update(level)
        -- Der Name des CHARAKTERS, nicht der Titel des Fensters: den setzt
        -- das Spiel je Reiter ("Spieler gegen Spieler" auf PvP), und beim
        -- Zurueckwechseln stand er noch da, als die Kopfzeile ihn las
        -- (6.6.4.3, Beta-Test). UnitPVPName = was der Reiter Charakter
        -- selbst zeigt (mit Titel), sonst UnitName.
        local pok, pvp = pcall(_G.UnitPVPName, "player")
        local name = CS.NameLine(pok and pvp or nil)
        if not name then
            local nok, n = pcall(_G.UnitName, "player")
            name = CS.NameLine(nok and n or nil)
        end
        local cok, className = pcall(_G.UnitClass, "player")
        if type(level) ~= "number" then
            local lok, lv = pcall(_G.UnitLevel, "player")
            level = lok and lv or nil
        end
        local line = CS.IdentityLine(cok and className or nil, level)
        h.name:SetText(name or "")
        h.named = name ~= nil
        h.sub:SetText(line or "")
        -- Nicht h verstecken: dann kaeme kein OnShow mehr.
        for _, t in ipairs({ h.dot, h.hole, h.lines[1], h.lines[2] }) do t:SetShown(line ~= nil) end
        -- Ohne eigenen Namen bleibt der Titel des Spiels stehen.
        local vok, vis = pcall(h.IsVisible, h)
        Replaced(h, (name and vok and K.Bool(vis, false)) and 0 or 1)
    end
    h:SetScript("OnShow", function() h.Update() end)
    h:SetScript("OnHide", function() Replaced(h, 1) end)
    h:RegisterEvent("PLAYER_LEVEL_UP")
    h:SetScript("OnEvent", function(_, _, level) h.Update(K.Plain(level)) end)
    h.Update()
    CS.KeepHeaderLevel(h)
    CS.head = h
    return h
end

-- Jeder Durchlauf: ueber der Figur bleiben (sie wurde ueber der Zeile
-- gezeichnet) und mittig ueber dem Modell stehen.
function CS.KeepHeader(h, box)
    CS.KeepHeaderLevel(h)
    CS.FindDuplicate(h)
    -- Was die Kopfzeile ersetzt, bleibt unsichtbar, solange sie zu sehen
    -- ist - auch wenn das Spiel die Zeile neu setzt (ohne Tabellen).
    if h.named and Visible(h) then
        local list = h.replaced
        for i = 1, #list do
            local t = list[i]
            local ok, a = pcall(t.GetAlpha, t)
            if not (ok and Num(a) == 0) then pcall(t.SetAlpha, t, 0) end
        end
    end
    local off = 0
    if box then
        -- Ohne Closure: das laeuft in jedem Durchlauf.
        local bok, bx = pcall(box.GetCenter, box)
        local fok, fx = pcall(h.frame.GetCenter, h.frame)
        bx, fx = bok and Num(bx) or nil, fok and Num(fx) or nil
        if bx and fx then off = bx - fx end
    end
    if h.off ~= off then
        h.off = off
        h:ClearAllPoints()
        h:SetPoint("TOP", h.frame, "TOP", off, CS.HEAD_Y)
    end
end

--------------------------------------------------
-- 6. Information: Werte
--------------------------------------------------
-- Die Werteanzeige des Spiels bleibt (Kategorien, Zeilen, Bildlauf); die
-- Kopfzeilen der Kategorien traegt W.Header (Linien im Akzent). Die Namen
-- der Werte waren gold - eine zweite Farbwelt neben dem Akzent. Jetzt
-- ruhig (textMuted); die Zahlen bleiben, wie das Spiel sie faerbt (hell,
-- gruen/rot bei Zu- und Abschlaegen - das ist Bedeutung).
local labelDone = setmetatable({}, { __mode = "k" })
CS.labels = labelDone
function CS.Info()
    local list = W.StatLabels
    for i = 1, #list do
        local label = list[i]
        if not labelDone[label] then
            labelDone[label] = true
            local c = C.textMuted
            pcall(label.SetTextColor, label, c[1], c[2], c[3], 1)
        end
    end
end

--------------------------------------------------
-- 5. Ausruestung
--------------------------------------------------
-- Die Plaetze des Spiels (W.SkinSlots: flach, 1 px Rand). Zustand nur
-- ueber den Rand und das Symbol:
--   leer     Rand schwarz, Symbol (Umriss des Spiels) gedaempft und grau
--   belegt   Rand im Akzent, halb; der Qualitaetsrand des Spiels bleibt
--            (gruen/blau/lila ist Information, kein Schmuck)
--   Maus     Rand im Akzent, voll
-- "Ausgewaehlt" im Sinn von "hier passt, was du haeltst" zeichnet das
-- Spiel selbst (Leuchten des Platzes) - bleibt unberuehrt.
CS.SLOT_FILLED, CS.SLOT_EMPTY_ICON = 0.45, 0.45

local slotState = setmetatable({}, { __mode = "k" })
CS.slotState = slotState

local function SlotIcon(slot)
    if type(slot.icon) == "table" then return slot.icon end
    local n = slot.GetName and slot:GetName()
    local t = type(n) == "string" and _G[n .. "IconTexture"]
    return type(t) == "table" and t or nil
end

function CS.Filled(slot)
    local ok, id = pcall(slot.GetID, slot)
    id = ok and Num(id) or nil
    if not id or id <= 0 then return nil end
    local tok, tex = pcall(_G.GetInventoryItemTexture, "player", id)
    if not tok then return nil end
    return not (type(K.Plain(tex)) == "nil")
end

local function PaintSlot(slot, st, state)
    st.state = state
    local border = W.SlotBorder[slot]
    local acc = CS.Accent()
    if border then
        if state == "hover" then border:SetColor(acc[1], acc[2], acc[3], 1)
        elseif state == "filled" then border:SetColor(acc[1], acc[2], acc[3], CS.SLOT_FILLED)
        else border:SetColor(0, 0, 0, 1) end
    end
    local icon = st.icon
    if icon then
        local empty = state == "empty"
        pcall(icon.SetDesaturated, icon, empty)
        pcall(icon.SetAlpha, icon, empty and CS.SLOT_EMPTY_ICON or 1)
    end
end

local function SlotStateOf(st)
    if st.hover then return "hover" end
    if st.filled then return "filled" end
    return "empty"
end

function CS.Slots()
    local list = W.SlotList
    for i = 1, #list do
        local slot = list[i]
        local st = slotState[slot]
        if not st then
            st = { icon = SlotIcon(slot) }
            slotState[slot] = st
            if slot.HookScript then
                slot:HookScript("OnEnter", function() st.hover = true PaintSlot(slot, st, "hover") end)
                slot:HookScript("OnLeave", function() st.hover = false PaintSlot(slot, st, SlotStateOf(st)) end)
            end
        end
        st.filled = CS.Filled(slot) == true
        local state = SlotStateOf(st)
        if st.state ~= state then PaintSlot(slot, st, state) end
    end
end

--------------------------------------------------
-- Ein Durchlauf (aus W.Inner, solange das Fenster offen ist)
--------------------------------------------------
function CS.Update(f, d)
    local theme = CS.Theme()
    CS.Layout(f, d, theme)
    local h = CS.Header(f)
    CS.Info()
    CS.Slots()
    local box
    if Opt("windowArt") then
        for _, host in ipairs(W.SoftenModel(f)) do
            local e = W.soft[host]
            CS.Scene(e, host, theme)
            CS.Light(e, host, theme)
            CS.KeepScene(e)
            CS.KeepLight(e)
            box = box or e.box
        end
    end
    if h then CS.KeepHeader(h, box) end
end

--------------------------------------------------
-- /wcui fenster
--------------------------------------------------
function CS.ReportFrame(f, out)
    if f ~= _G.CharacterFrame then return end
    local theme = CS.Theme()
    local L = layout[f]
    out[#out + 1] = string.format("   Charakterfenster: Thema %s, Szene %s", tostring(theme.class),
        theme.art and tostring(theme.art.file) or "des Spiels")
    if L then
        local g = L.glass
        out[#out + 1] = string.format("   Basis %s, Glas %s, Schein oben %s", L.base and "dunkel" or "fehlt (keine Kachel)",
            not g and "fehlt (kein rechter Bereich)" or (tostring(g.name) .. (g.shown and "" or ", eingeklappt")),
            not L.glow and "keiner" or (L.glow:IsShown() and ("an, " .. tostring(L.glow:GetAlpha())) or "aus"))
    end
    local h = CS.head
    if h then
        out[#out + 1] = "   Doppelte Stufenzeile: " .. (CS.dup and "gefunden, ausgeblendet" or "nicht gefunden")
        local names = {}
        for _, t in ipairs(h.replaced) do
            local nok, n = pcall(t.GetName, t)
            n = nok and K.Plain(n) or nil
            local tok, text = pcall(t.GetText, t)
            text = tok and K.Plain(text) or nil
            names[#names + 1] = (type(n) == "string" and n or "(ohne Namen)")
                .. (type(text) == "string" and text ~= "" and (" „" .. text .. "“") or "")
        end
        out[#out + 1] = "   Ersetzt: " .. (#names > 0 and table.concat(names, ", ") or "nichts")
        local title = Title(h.frame)
        out[#out + 1] = "   Titel des Spiels: " .. (not title and "nicht gefunden"
            or (string.format("Deckkraft %s", tostring(title:GetAlpha()))))
        out[#out + 1] = string.format("   Kopfzeile: %s ersetzt, Ebene %s (Modell %s)", tostring(#h.replaced),
            tostring(LevelOf(h)), tostring(LevelOf(_G.CharacterModelScene)))
    end
    local counts = { empty = 0, filled = 0, hover = 0 }
    for _, st in pairs(slotState) do counts[st.state or "empty"] = (counts[st.state or "empty"] or 0) + 1 end
    out[#out + 1] = string.format("   Plätze: %d belegt, %d leer", counts.filled + counts.hover, counts.empty)
end

function CS.ReportScene(e, out)
    local s, m = e.scene, e.light
    if s then
        out[#out + 1] = string.format("   Szene: %s, Abdunklung des Spiels %s, Vignette %s, Ruhe %s",
            s.art and tostring(s.theme.art.file) or "Bühne des Spiels",
            s.theme.gameOverlay and "an" or "aus", s.vignette and "an" or "aus", s.calm and "an" or "aus")
    end
    if m then
        out[#out + 1] = string.format("   Licht: %s (%d× gesetzt), Schicht über der Figur %s (Modell %s, Plätze %s)",
            not m.theme.light and "des Spiels" or (m.scene and "an der Szene" or "fehlt (keine ModelScene)"), m.lit,
            not m.over and "aus" or (m.over:IsShown() and ("auf " .. tostring(m.overLevel)) or "weggelassen"),
            tostring(m.sceneLevel), tostring(m.slotLevel))
    end
end
