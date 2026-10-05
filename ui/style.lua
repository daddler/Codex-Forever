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
--   S.CALM      informationslastige Fenster, die nicht der Klasse
--               gehoeren: Gold, Kopfzeilen als Zeile der Liste
--               (W.ListHeader), dezente Atmosphaere. Noch in keinem Gebrauch.
--   S.CHARACTER_INFO  dasselbe fuer die Informations-Reiter des
--               Charakterfensters (Ruf, 6.7.0.1): Klassenfarbe statt Gold -
--               sie gehoeren zum Charakter (Beta-Test).
-- Ein Rahmen ohne Stil verhaelt sich wie bisher (SHOWCASE).
--
-- Neue Fenster migrieren: eine Liste mit Detailansicht wird ein Register
-- (ui/register.lua; Muster ui/reputation.lua, ui/skills.lua) - es traegt
-- seinen Stil selbst in S.SCOPES ein. Sonst den Namen in S.SCOPES
-- eintragen und die Bausteine unten benutzen. Hier gehoert nichts hin,
-- was nur ein Fenster braucht.
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
-- barEdge: Deckkraft des schwarzen Randes um Balken (1 = hart).
-- 6.7.5.0 (Berufe, erstes Fenster in Gold): wie S.CHARACTER_INFO, nur der
-- Akzent ist ein anderer - Abschnitte mit Band, 14 pt.
S.CALM = { key = "calm", name = "ruhig", accent = "frame", header = "list",
           band = true, headerSize = 14, barTrack = "barTrack", barEdge = 0.5 }
-- band/headerSize (6.7.0.2): Kopfzeilen als eigene Sektion (S.Band), 14 pt.
S.CHARACTER_INFO = { key = "charinfo", name = "ruhig, Klasse", accent = "class", header = "list",
                     band = true, headerSize = 14,
                     barTrack = "barTrack", barEdge = 0.5 }

-- Welche Fenster welchen Stil tragen: globaler Name oder Pfad
-- ("CharacterFrame.SkillsFrame"). Seit 6.7.1.0 tragen sich die Fenster
-- selbst ein (ui/register.lua: Ruf, Fertigkeiten) - hier steht kein Name.
S.SCOPES = {}

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
        local W = WeintCodex.UIWindows
        local f = (n:find(".", 1, true) and W and W.Resolve) and W.Resolve(n) or _G[n]
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

-- Linie von einem Bildpunkt (6.10.4.2): mindestens ein Bildpunkt am Bildschirm hoch.
-- Gemessen 05.10.2026 (Zauberbuch, Talente): Raute zu sehen, die Linie von
-- 1 Einheit dahinter nicht - auch mit Deckkraft 0.9 (6.8.0.4). Ist eine
-- Einheit kleiner als ein Bildpunkt (kleine UI-Skalierung), rundet das
-- Spiel Ober- und Unterkante je nach Lage auf DIESELBE Bildpunktzeile -
-- die Linie hat dann die Hoehe 0. Dieselbe Linie an anderer Stelle (Berufe)
-- traf zufaellig. Dagegen: Hoehe = ein Bildpunkt, nie unter 1 Einheit.
-- Laeuft in jedem Durchlauf (Skalierung kann sich aendern), ohne Tabelle.
function S.PixelSize(r)
    local get = _G.GetPhysicalScreenSize
    if type(r.GetEffectiveScale) ~= "function" and type(r.GetParent) == "function" then
        local okP, p = pcall(r.GetParent, r)
        r = okP and type(p) == "table" and p or r
    end
    if type(get) ~= "function" or type(r.GetEffectiveScale) ~= "function" then return nil end
    local ok, _, h = pcall(get)
    local okS, s = pcall(r.GetEffectiveScale, r)
    h = ok and K.Plain(h) or nil
    s = okS and K.Plain(s) or nil
    if type(h) ~= "number" or h <= 0 or type(s) ~= "number" or s <= 0 then return nil end
    return 768 / h / s
end

function S.PixelLine(t)
    local px = S.PixelSize(t)
    local hgt = (px and px > 1) and px or 1
    if t.pixelLine ~= hgt then
        t.pixelLine = hgt
        t:SetHeight(hgt)
    end
    return hgt, px
end

-- Auf ganze Bildpunkte (6.10.4.3). Gemessen 05.10.2026 mit 6.10.4.2:
-- "Linie: 614 breit, 1.00 hoch = 1.00 Bildpunkte, Oberkante bei Bildpunkt
-- 866.50, sichtbar ja" - und im Bild nichts. Die Hoehe war es nicht: eine
-- Linie von einem Bildpunkt, an ihrer MITTE verankert (LEFT am CENTER der
-- Raute), hat ihre Kanten auf halben Bildpunkten, wenn die Mitte auf
-- einem ganzen liegt - das Spiel rundet beide auf dieselbe Zeile. Hier:
-- der Versatz in y, mit dem die Oberkante auf einem ganzen Bildpunkt
-- liegt. `y` ist der jetzige Versatz; zurueck der neue (gleich, wenn
-- nichts zu tun ist oder Lage/Mass unbekannt sind). Bleibt in (-1, 0]
-- Bildpunkt, wandert also nicht.
function S.PixelY(t, y)
    local px = S.PixelSize(t)
    local ok, top = pcall(t.GetTop, t)
    top = ok and K.Plain(top) or nil
    if not px or type(top) ~= "number" then return y end
    local p = top / px
    local frac = p - math.floor(p)
    if frac < 0.01 or frac > 0.99 then return y end
    local ny = y - frac * px
    if ny <= -px then ny = ny + px end
    return ny
end

-- Fuer /wcui fenster: was die Linie im Client ist - damit die naechste
-- Messung sagt, ob die Hoehe der Linie der Grund war.
function S.LineReport(t)
    local function Num(m)
        local ok, v = pcall(t[m], t)
        v = ok and K.Plain(v) or nil
        return type(v) == "number" and v or nil
    end
    local w, h, top = Num("GetWidth"), Num("GetHeight"), Num("GetTop")
    local px = S.PixelSize(t)
    local okS, shown = pcall(t.IsVisible, t)
    return string.format("Linie: %s breit, %s hoch = %s Bildpunkte, Oberkante bei Bildpunkt %s, sichtbar %s",
        w and string.format("%.0f", w) or "?", h and string.format("%.2f", h) or "?",
        (h and px) and string.format("%.2f", h / px) or "?",
        (top and px) and string.format("%.2f", top / px) or "?",
        (okS and K.Bool(shown, false)) and "ja" or "nein")
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

-- Oben an `region`, `inset` px vom Rand: eine Kante aus Licht (oder
-- Akzent), die zu beiden Seiten auslaeuft.
-- `y` (6.7.0.2): so weit unter/ueber der Oberkante (negativ = tiefer);
-- `edge` = "BOTTOM" legt die Linie an die Unterkante.
function S.PlaceTop(d, region, inset, y, edge)
    inset, y, edge = inset or 0, y or 0, edge or "TOP"
    d.l:ClearAllPoints()
    d.r:ClearAllPoints()
    d.l:SetPoint(edge .. "LEFT", region, edge .. "LEFT", inset, y)
    d.l:SetPoint(edge .. "RIGHT", region, edge, 0, y)
    d.r:SetPoint(edge .. "LEFT", region, edge, 0, y)
    d.r:SetPoint(edge .. "RIGHT", region, edge .. "RIGHT", -inset, y)
end

-- Eine Linie in die unterste Ebene legen (unter jeden Text des Rahmens).
function S.Under(d, sub)
    d.l:SetDrawLayer("BACKGROUND", sub or 1)
    d.r:SetDrawLayer("BACKGROUND", sub or 1)
    return d
end

-- Haarlinie: neutral (GameColors.hairline), zu beiden Seiten auslaufend -
-- trennt Zeilen und Bereiche, ohne Kaesten zu bauen.
function S.Hairline(host, region, inset, edge, sub)
    local h = GC.hairline
    local d = S.Under(S.Divider(host, h, h[4], 0), sub or 1)
    S.PlaceTop(d, region, inset, 0, edge)
    return d
end

-- Kopfzeile als eigene Sektion (6.7.0.2): ein Hauch Licht von links, der
-- nach rechts auslaeuft, und oben eine Haarlinie - die Gruppe beginnt
-- sichtbar, ohne dass die Liste neu angeordnet wird.
function S.Band(f)
    local c = GC.sectionBand
    local b = { fill = Own(f:CreateTexture(nil, "BACKGROUND", nil, 1)) }
    b.fill:SetAllPoints(f)
    S.Gradient(b.fill, "HORIZONTAL", c, c[4], 0)
    b.line = S.Hairline(f, f, 2, "TOP", 2)
    return b
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
-- `corner`: optional ein zweiter Rahmen fuer die untere rechte Ecke (etwa
-- die Bildlaufleiste neben einer Liste).
function S.SoftPanel(host, anchor, c, alpha, pad, sub, corner)
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
    t:SetPoint("BOTTOMRIGHT", corner or anchor, "BOTTOMRIGHT", pad, -pad)
    return t
end

-- Weicher Schatten um `anchor`: dieselbe weiche Flaeche in Schwarz, weiter
-- ausladend. Liegt UNTER der Flaeche, die er absetzt.
function S.Shadow(host, anchor, pad, sub, corner)
    local c = GC.shadowSoft
    return S.SoftPanel(host, anchor, c, c[4], pad or 16, sub or -8, corner)
end

-- Eine weiche Flaeche auf zwei Hoehen innerhalb von `host` (relativ zu
-- seiner Oberkante, negativ = tiefer), `inset` px vom Rand. Fuer Bereiche,
-- deren Grenzen andere Rahmen vorgeben (Detailansicht).
function S.PlaceBand(t, host, inset, yTop, yBottom)
    t:ClearAllPoints()
    t:SetPoint("TOPLEFT", host, "TOPLEFT", inset, yTop)
    if yBottom then t:SetPoint("BOTTOMRIGHT", host, "TOPRIGHT", -inset, yBottom)
    else t:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", -inset, 0) end
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

-- Eine Hervorhebung DES SPIELS in den Akzent faerben: entsaettigt, dann
-- getoent - Form, Zeitpunkt (Maus, Auswahl) und Deckkraftwechsel bleiben
-- die des Spiels. Liefert, ob etwas gesetzt wurde; setzt nur, wenn die
-- Farbe abweicht (jeder Durchlauf fragt, nichts wird angelegt).
function S.Tint(t, c, alpha)
    local ok, r, g, b, a = pcall(t.GetVertexColor, t)
    r, g, b, a = K.Plain(r), K.Plain(g), K.Plain(b), K.Plain(a)
    if ok and type(r) == "number" and math.abs(r - c[1]) < 0.01 and math.abs(g - c[2]) < 0.01
       and math.abs(b - c[3]) < 0.01 and type(a) == "number" and math.abs(a - alpha) < 0.01 then
        return false
    end
    if t.SetDesaturated then pcall(t.SetDesaturated, t, true) end
    t:SetVertexColor(c[1], c[2], c[3], alpha)
    return true
end

-- Gewaehlt: links ein 2-px-Strich im Akzent, daneben ein Schein des
-- Akzents, der nach rechts ausblendet, und die Zeile eine Spur heller.
-- Unter dem Text, nie darueber. 6.7.0.2: der Schein reicht nur noch uebers
-- erste Drittel (S.SELECT_SPREAD) - schmaler Streifen, kein Block.
S.SELECT_FILL = 0.22
S.SELECT_SPREAD = 0.35
function S.Selection(row)
    local s = { on = false, row = row }
    local l = GC.selectLift
    s.lift = Own(row:CreateTexture(nil, "BACKGROUND", nil, 1))
    s.lift:SetAllPoints(row)
    s.lift:SetColorTexture(l[1], l[2], l[3], l[4])
    s.lift:Hide()
    s.fill = Own(row:CreateTexture(nil, "BACKGROUND", nil, 2))
    s.fill:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
    s.fill:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
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
        local ok, w = pcall(s.row.GetWidth, s.row)
        w = ok and K.Plain(w) or nil
        s.fill:SetWidth(math.max(60, (type(w) == "number" and w or 300) * S.SELECT_SPREAD))
        S.Gradient(s.fill, "HORIZONTAL", c, S.SELECT_FILL, 0)
        s.bar:SetColorTexture(c[1], c[2], c[3], 1)
    end
    s.lift:SetShown(on)
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
-- `fill`: die Fuellung, wenn der Balken kein Statusbalken ist (etwa ein
-- Rahmen mit einem Bild als Fuellung, Ruf in diesem Client).
S.BAR_SHADE = 0.30
function S.BarFinish(bar, fill)
    if type(fill) ~= "table" and type(bar.GetStatusBarTexture) == "function" then
        local ok, t = pcall(bar.GetStatusBarTexture, bar)
        fill = ok and t or nil
    end
    local anchor = (type(fill) == "table" and fill.GetObjectType) and fill or bar
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
    if c then fs:SetTextColor(c[1], c[2], c[3], 1) end
    if fs.SetShadowOffset then fs:SetShadowOffset(1, -1) end
    if fs.SetShadowColor then fs:SetShadowColor(0, 0, 0, 0.9) end
end
-- `c` = false (6.7.2.0): Farbe des Spiels behalten - wo sie Bedeutung
-- traegt (Rang, Qualitaet), bekommt die Zeile nur Groesse und Schatten.
function S.Title(fs, size, c)
    if type(fs) ~= "table" or not fs.SetTextColor then return false end
    if c == nil then c = C.textBright end
    return (pcall(StyleText, fs, size, c))
end

--------------------------------------------------
-- Mittelpunkt, Ornament, Flaeche nach Zahlen (6.7.2.0)
--------------------------------------------------
-- Buehne: ein Element als Mittelpunkt, ohne es anzufassen - dahinter ein
-- weicher dunkler Hof (nimmt die Umgebung zurueck) und darin ein Hauch
-- Licht. Beides liegt auf `host` in der untersten Ebene, also unter dem
-- Element, wenn `host` darunter liegt (ein Elternrahmen). Gross = Faktor
-- zur Groesse des Elements.
S.STAGE_SHADE, S.STAGE_LIGHT = 2.4, 1.5
function S.Stage(host, target, sub)
    local g = { shade = Own(host:CreateTexture(nil, "BACKGROUND", nil, sub or -5)),
                light = Own(host:CreateTexture(nil, "BACKGROUND", nil, (sub or -5) + 1)) }
    local sh, li = GC.stageShade, GC.stageLight
    g.shade:SetTexture(K.MEDIA .. "halo")
    g.shade:SetVertexColor(sh[1], sh[2], sh[3], sh[4])
    g.light:SetTexture(K.MEDIA .. "halo")
    g.light:SetVertexColor(li[1], li[2], li[3], li[4])
    g.shade:SetPoint("CENTER", target, "CENTER", 0, 0)
    g.light:SetPoint("CENTER", target, "CENTER", 0, 0)
    g.target = target
    return g
end

-- Groesse der Buehne nach dem Element (nur bei einer Aenderung).
function S.FitStage(g, w, h)
    local size = math.max(w or 0, h or 0)
    if size <= 0 or g.size == size then return end
    g.size = size
    g.shade:SetSize(size * S.STAGE_SHADE, size * S.STAGE_SHADE)
    g.light:SetSize(size * S.STAGE_LIGHT, size * S.STAGE_LIGHT)
end

-- Ornament: Linie zu beiden Seiten auslaufend, in der Mitte eine Raute mit
-- dunklem Kern - der Abschnittsbeginn ohne eigenen Text.
function S.Ornament(host, c, alpha)
    local o = { line = S.Under(S.Divider(host, c, alpha or 0.45, 0), -1) }
    o.dot = S.Diamond(host, 5, c, 0.8, 0)
    o.dot:SetDrawLayer("BACKGROUND", 0)
    o.hole = S.Diamond(host, 2, C.surface1, 1, 0)
    o.hole:SetDrawLayer("BACKGROUND", 1)
    o.hole:SetPoint("CENTER", o.dot, "CENTER", 0, 0)
    o.parts = { o.line.l, o.line.r, o.dot, o.hole }
    return o
end

-- Auf Hoehe `y` (relativ zur Oberkante von `host`), `inset` vom Rand.
function S.PlaceOrnament(o, host, inset, y)
    if o.y == y and o.host == host then return end
    o.y, o.host = y, host
    S.PlaceTop(o.line, host, inset, y)
    o.dot:ClearAllPoints()
    o.dot:SetPoint("CENTER", host, "TOP", 0, y)
end

-- Eine Flaeche nach Zahlen: links/oben/rechts/unten relativ zur linken
-- oberen Ecke von `host` (y negativ = tiefer). Fuer Bereiche, die sich aus
-- der Lage mehrerer Rahmen des Spiels ergeben.
function S.PlaceRect(t, host, x1, y1, x2, y2)
    t:ClearAllPoints()
    t:SetPoint("TOPLEFT", host, "TOPLEFT", x1, y1)
    t:SetPoint("BOTTOMRIGHT", host, "TOPLEFT", x2, y2)
end
