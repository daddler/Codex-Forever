--------------------------------------------------
-- WeintCodex :: Oberflaeche - Stil der Fenster des Spiels (6.7.0.0)
--------------------------------------------------
-- EINE Designsprache fuer alle Fenster, die WeintCodex gestaltet
-- (Beta-Test: "jedes Fenster soll eindeutig nach WeintCodex aussehen -
-- nicht jedes wie das Charakterfenster"). Hier stehen nur die Bausteine;
-- WAS ein Fenster davon nimmt, entscheidet das Fenster.
--
-- Grundsaetze (Rangfolge, von oben nach unten):
--   1. Information   nichts verschwindet, nichts liegt hinter Text
--   2. Interaktion   Maus und Auswahl klar erkennbar
--   3. Orientierung  Abschnittsueberschriften, Trennlinien
--   4. Atmosphaere   dunkle Basis, weiche Raender, Vignette
--   5. Dekoration    so wenig wie noetig
--
-- ZWEI AKZENTE, NIE IN EINER FLAECHE:
--   "class"  die Klassenfarbe (K.Highlight = C.accent) - Charakter,
--            Talente, alles Klassenbezogene.
--   "frame"  gedaempftes warmes Gold (GameColors.frameAccent) - jedes
--            andere Fenster. Es wird von WeintCodex.SetAccent NICHT
--            umgerechnet: es ist keine Ableitung des Violetts.
-- Ein Bereich traegt genau einen der beiden; welcher, sagt sein Stil.
--
-- STILE je Bereich (S.SCOPES): ein Stil gilt fuer einen Rahmen des
-- Spiels und alles darunter (W.HideByAtlas reicht ihn nach unten durch).
--   S.SHOWCASE  Charakter: Klassenfarbe, Kopfzeilen mittig mit Lichthof
--               (W.Header) - das Verhalten bis 6.6.4.5, unveraendert.
--   S.CALM      alles Informationslastige: Gold, Kopfzeilen als Zeile
--               der Liste (W.ListHeader), dezente Atmosphaere.
-- Ein Rahmen ohne Stil verhaelt sich wie bisher (SHOWCASE).
--
-- Neue Fenster migrieren: Namen in S.SCOPES eintragen, dann die
-- Bausteine unten benutzen (ui/reputation.lua ist das Muster).
--
-- Wie ueberall in ui/windows.lua: nur Aussehen. Eigene Flaechen daneben
-- und dahinter, Deckkraft und Schrift an fremden Zeilen - kein SetText,
-- kein Feld auf einem Rahmen des Spiels, nichts wird versteckt, was
-- Inhalt ist.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIStyle = {}

local S = WeintCodex.UIStyle
local K = WeintCodex.UIKit
local C = WeintCodex.Colors
local GC = WeintCodex.GameColors

-- Unsere eigenen Flaechen. ui/windows.lua blendet nie etwas aus, das
-- hier steht (W.own ist dieselbe Tabelle).
S.own = setmetatable({}, { __mode = "k" })
local function Own(t) S.own[t] = true return t end
S.Own = Own

local BLACK = { 0, 0, 0 }
S.BLACK = BLACK

--------------------------------------------------
-- Akzent und Stile
--------------------------------------------------
function S.Accent(kind)
    if kind == "frame" then return GC.frameAccent end
    return K.Highlight()
end

S.SHOWCASE = { key = "showcase", name = "Bühne", accent = "class", header = "showcase" }
S.CALM = { key = "calm", name = "ruhig", accent = "frame", header = "list", barTrack = "barTrack" }

-- Welche Fenster (globale Namen) welchen Stil tragen. Phase 3 des
-- Umbaus: nur der Ruf. Die anderen folgen nach dem Test im Spiel.
S.SCOPES = { ReputationFrame = S.CALM }

local scoped = setmetatable({}, { __mode = "k" })
S.scoped = scoped
function S.Scope(f, style)
    if type(f) == "table" then scoped[f] = style end
end
function S.ScopeOf(f) return scoped[f] end

-- Namen aufloesen, sobald das Spiel die Fenster angelegt hat. Legt nichts
-- an (laeuft in jedem Durchlauf).
function S.Register()
    for n, style in pairs(S.SCOPES) do
        local f = _G[n]
        if type(f) == "table" and scoped[f] == nil then scoped[f] = style end
    end
end

--------------------------------------------------
-- Verlaeufe, Rauten, Linien
--------------------------------------------------
-- Verlauf einer Farbe von `a0` nach `a1`.
-- VERTICAL: a0 unten, a1 oben; HORIZONTAL: a0 links, a1 rechts.
function S.Gradient(t, dir, c, a0, a1)
    t:SetColorTexture(1, 1, 1, 1)
    if _G.CreateColor and t.SetGradient then
        t:SetGradient(dir, _G.CreateColor(c[1], c[2], c[3], a0), _G.CreateColor(c[1], c[2], c[3], a1))
    else
        t:SetColorTexture(c[1], c[2], c[3], (a0 + a1) / 2)
    end
end

-- Waagerechte Linie, die nach `outward` ("LEFT"/"RIGHT") ausblendet.
function S.Fade(t, c, alpha, outward)
    if _G.CreateColor and t.SetGradient then
        if outward == "LEFT" then S.Gradient(t, "HORIZONTAL", c, 0, alpha)
        else S.Gradient(t, "HORIZONTAL", c, alpha, 0) end
    else
        t:SetColorTexture(c[1], c[2], c[3], alpha * 0.5)
    end
end

-- Raute (gedrehtes Quadrat).
function S.Diamond(f, size, c, a, sub)
    local t = Own(f:CreateTexture(nil, "ARTWORK", nil, sub))
    t:SetSize(size, size)
    t:SetColorTexture(c[1], c[2], c[3], a)
    if t.SetRotation then pcall(t.SetRotation, t, math.pi / 4) end
    return t
end

-- Trennlinie: in der Mitte voll, zu beiden Enden auslaufend. Zwei
-- Haelften, weil ein Verlauf nur zwei Farben kennt.
S.DIVIDER_ALPHA = 0.55
function S.Divider(host, c, alpha, sub)
    local d = { l = Own(host:CreateTexture(nil, "ARTWORK", nil, sub or 0)),
                r = Own(host:CreateTexture(nil, "ARTWORK", nil, sub or 0)) }
    local a = alpha or S.DIVIDER_ALPHA
    d.l:SetHeight(1)
    d.r:SetHeight(1)
    S.Gradient(d.l, "HORIZONTAL", c, 0, a)
    S.Gradient(d.r, "HORIZONTAL", c, a, 0)
    return d
end

-- Unter `below` (Mitte), `width` breit, `gap` px darunter.
function S.PlaceDivider(d, below, width, gap)
    if d.width == width and d.below == below then return end
    d.width, d.below = width, below
    local half = math.max(1, width / 2)
    d.l:ClearAllPoints()
    d.r:ClearAllPoints()
    d.l:SetPoint("TOPRIGHT", below, "BOTTOM", 0, -(gap or 6))
    d.r:SetPoint("TOPLEFT", below, "BOTTOM", 0, -(gap or 6))
    d.l:SetWidth(half)
    d.r:SetWidth(half)
end

--------------------------------------------------
-- Flaechen
--------------------------------------------------
-- Weiche dunkle Flaeche um `anchor`: die weiche Maske (media/ui/softmask,
-- innen voll, Rand weich auf null) als Bild, wo der Client es kann als
-- Neunteiler - der Rand bleibt dann S.FEATHER px breit, egal wie gross
-- die Flaeche ist. Keine Kante, nur ein Dunkler-Werden.
S.SOFT_TEXTURE = K.MEDIA .. "softmask"
S.FEATHER = 22
function S.SoftPanel(host, anchor, c, alpha, pad, sub)
    local t = Own(host:CreateTexture(nil, "BACKGROUND", nil, sub or -4))
    t:SetTexture(S.SOFT_TEXTURE)
    local f = S.FEATHER
    local ok = type(t.SetTextureSliceMargins) == "function" and pcall(t.SetTextureSliceMargins, t, f, f, f, f)
    if ok and t.SetTextureSliceMode and _G.Enum and _G.Enum.UITextureSliceMode then
        pcall(t.SetTextureSliceMode, t, _G.Enum.UITextureSliceMode.Stretched)
    end
    t:SetVertexColor(c[1], c[2], c[3], alpha)
    pad = pad or f
    t:SetPoint("TOPLEFT", anchor, "TOPLEFT", -pad, pad)
    t:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMRIGHT", pad, -pad)
    return t
end

-- Randabdunklung: vier Verlaeufe von Schwarz (`strength`) nach innen auf
-- null, `size` px breit. Liegt ganz unten - nie ueber Text.
S.SIDES = { "TOP", "BOTTOM", "LEFT", "RIGHT" }
function S.Vignette(host, area, strength, size, sub)
    local v = {}
    for _, side in ipairs(S.SIDES) do
        local t = Own(host:CreateTexture(nil, "BACKGROUND", nil, sub or -6))
        if side == "TOP" or side == "BOTTOM" then
            t:SetPoint(side .. "LEFT", area, side .. "LEFT", 0, 0)
            t:SetPoint(side .. "RIGHT", area, side .. "RIGHT", 0, 0)
            t:SetHeight(size)
            if side == "TOP" then S.Gradient(t, "VERTICAL", BLACK, 0, strength)
            else S.Gradient(t, "VERTICAL", BLACK, strength, 0) end
        else
            t:SetPoint("TOP" .. side, area, "TOP" .. side, 0, 0)
            t:SetPoint("BOTTOM" .. side, area, "BOTTOM" .. side, 0, 0)
            t:SetWidth(size)
            if side == "LEFT" then S.Gradient(t, "HORIZONTAL", BLACK, strength, 0)
            else S.Gradient(t, "HORIZONTAL", BLACK, 0, strength) end
        end
        v[side] = t
    end
    return v
end

-- Licht von oben: ein Hauch des Akzents, nach unten auf null.
function S.TopLight(host, area, c, alpha, height, sub)
    local t = Own(host:CreateTexture(nil, "BACKGROUND", nil, sub or -5))
    t:SetPoint("TOPLEFT", area, "TOPLEFT", 0, 0)
    t:SetPoint("TOPRIGHT", area, "TOPRIGHT", 0, 0)
    t:SetHeight(height)
    S.Gradient(t, "VERTICAL", c, 0, alpha)
    return t
end

-- Eine eigenstaendige Tafel (etwa die Detailansicht neben einem Fenster):
-- die Kachel der Oberflaeche in der Basis des Charakterfensters.
function S.Panel(f)
    local k = K.Kachel(f, { alpha = 1, shadow = 8 })
    local b = GC.showcaseBase
    k.bg:SetColorTexture(b[1], b[2], b[3], b[4])
    Own(k.bg)
    Own(k.light)
    if k.shadow and k.shadow.tex then Own(k.shadow.tex) end
    return k
end

--------------------------------------------------
-- Zustaende: Maus und Auswahl
--------------------------------------------------
-- Unter der Maus: eine helle Flaeche in der Ebene HIGHLIGHT (zeigt der
-- Client bei Knoepfen von selbst). Halb so hell wie an Balken.
S.HOVER_SHARE = 0.5
function S.Hover(b)
    local h = Own(b:CreateTexture(nil, "HIGHLIGHT"))
    h:SetAllPoints(b)
    local c = GC.hoverFill
    h:SetColorTexture(c[1], c[2], c[3], c[4] * S.HOVER_SHARE)
    return h
end

-- Gewaehlt: links ein 2-px-Strich im Akzent, dahinter ein Hauch des
-- Akzents, der nach rechts ausblendet. Unter dem Text, nie darueber.
S.SELECT_FILL = 0.16
function S.Selection(row)
    local s = { on = false }
    s.fill = Own(row:CreateTexture(nil, "BACKGROUND", nil, 2))
    s.fill:SetAllPoints(row)
    s.bar = Own(row:CreateTexture(nil, "ARTWORK", nil, 7))
    s.bar:SetWidth(2)
    s.bar:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
    s.bar:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
    s.fill:Hide()
    s.bar:Hide()
    return s
end

-- Nur bei einem Wechsel wird gemalt (der Verlauf legt Farbobjekte an).
function S.SetSelected(s, on, c)
    on = on and true or false
    if s.on == on then return end
    s.on = on
    if on then
        S.Gradient(s.fill, "HORIZONTAL", c, S.SELECT_FILL, 0)
        s.bar:SetColorTexture(c[1], c[2], c[3], 1)
    end
    s.fill:SetShown(on)
    s.bar:SetShown(on)
end

--------------------------------------------------
-- Balken und Schrift
--------------------------------------------------
-- Balken des Spiels veredeln, ohne ihn anzufassen: die Fuellung (Farbe
-- und Textur des Spiels - die Farbe IST die Auskunft) bekommt unten
-- einen leichten Schatten und oben die Lichtkante aller Balken der
-- Oberflaeche. Beides haengt an der Fuellung, waechst also mit ihr.
S.BAR_SHADE = 0.30
function S.BarFinish(bar)
    local ok, fill = pcall(bar.GetStatusBarTexture, bar)
    local anchor = (ok and type(fill) == "table" and fill.GetObjectType) and fill or bar
    local o = {}
    o.shade = Own(bar:CreateTexture(nil, "ARTWORK", nil, 7))
    o.shade:SetAllPoints(anchor)
    S.Gradient(o.shade, "VERTICAL", BLACK, S.BAR_SHADE, 0)
    local l = GC.barLight
    o.light = Own(bar:CreateTexture(nil, "ARTWORK", nil, 7))
    o.light:SetPoint("TOPLEFT", anchor, "TOPLEFT", 0, 0)
    o.light:SetPoint("TOPRIGHT", anchor, "TOPRIGHT", 0, 0)
    o.light:SetHeight(1)
    o.light:SetColorTexture(l[1], l[2], l[3], l[4])
    o.fill = anchor ~= bar and anchor or nil
    return o
end

-- Schrift einer fremden Zeile: Groesse, Farbe, Schatten. Der Text bleibt.
local function StyleText(fs, size, c)
    K.SetFont(fs, size)
    fs:SetTextColor(c[1], c[2], c[3], 1)
    if fs.SetShadowOffset then fs:SetShadowOffset(1, -1) end
    if fs.SetShadowColor then fs:SetShadowColor(0, 0, 0, 0.9) end
end
function S.Title(fs, size, c)
    if type(fs) ~= "table" or not fs.SetTextColor then return false end
    return (pcall(StyleText, fs, size, c or C.textBright))
end
