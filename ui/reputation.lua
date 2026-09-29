--------------------------------------------------
-- WeintCodex :: Oberflaeche - Ruf (6.7.0.0)
--------------------------------------------------
-- Das erste Fenster der Designsprache (ui/style.lua) - das Muster fuer
-- die informationslastigen Fenster, die folgen. Der Reiter "Ruf" im
-- Charakterfenster (ReputationFrame) und seine Detailansicht rechts.
--
-- 6.7.0.1 (Beta-Test mit Screenshot): Ruf gehoert zum Charakterfenster,
-- also traegt er die KLASSENFARBE als Akzent, nicht Gold (Stil
-- S.CHARACTER_INFO). Und "zu schwarz und flach": Liste und Detailansicht
-- liegen jetzt auf einer leicht HELLEREN Flaeche als die Basis, mit weichem
-- Rand und einer Lichtkante oben - statt dunkler Kaesten nebeneinander.
-- Character = Szene + Figur + Klassenfarbe; Ruf = Information + dezente
-- Atmosphaere + Klassenfarbe. Kein kleines Charakterfenster.
--
-- ALLES BLEIBT, WAS DAS SPIEL ZEIGT: Liste, Gruppen, Fraktionen, Balken
-- mit Farbe und Text, Auswahl, Detailansicht mit Beschreibung und
-- Haekchen (Krieg, inaktiv, beobachten), Filter, Bildlauf. Dieses Modul
-- legt nur eigene Flaechen daneben und dahinter und setzt Schrift, Farbe
-- und Deckkraft - kein SetText, kein Feld an einem Rahmen des Spiels,
-- keine Zeile wird versteckt oder verschoben.
--
-- Was es tut, von hinten nach vorn:
--   Atmosphaere   auf dem Charakterfenster selbst (unter allem, was das
--                 Spiel zeichnet - nie ueber Text): Basis sehr dunkles
--                 Anthrazit (ui/character.lua), weiche Randabdunklung,
--                 neutrales Licht von oben, unter Liste und Bildlauf eine
--                 leicht angehobene Flaeche mit weichem Rand und Lichtkante.
--                 Nur solange der Ruf offen ist.
--   Gruppen       Kopfzeilen als Zeile mit Raute und Linie in der
--                 Klassenfarbe (W.ListHeader), Einrueckung des Spiels bleibt.
--   Balken        Bahn dunkler als die Flaeche, weicher Rand, Schatten und
--                 Lichtkante an der Fuellung; Farbe und Text der Stufe
--                 bleiben die des Spiels (Neutral gelb, Freundlich gruen ...).
--   Maus          die Hervorhebung DES SPIELS (Content.BackgroundHighlight,
--                 gemessen) in der Klassenfarbe - sie bleibt, wann sie kommt.
--   Auswahl       die Fraktion, die rechts in der Detailansicht steht:
--                 Strich und Schein in der Klassenfarbe - der staerkste
--                 Akzent im Fenster.
--   Detail        dieselbe angehobene Flaeche wie die Liste, oben eine
--                 feine Kante in der Klassenfarbe, Titel groesser.
--
-- GEMESSEN (6.7.0.0, /wcui fenster): Zeilen unter
-- ReputationFrame.ScrollBox.ScrollTarget mit .Content; der Balken
-- Content.ReputationBar ist KEIN Statusbalken dieses Clients - seine
-- Fuellung ist das Bild "common-stat-bar-white" (0 Balken gefunden, weil
-- nach StatusBar gesucht wurde). Detailansicht
-- ReputationFrame.ReputationDetailFrame im Fenster, Titel .Title.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIReputation = {}

local RP = WeintCodex.UIReputation
local K = WeintCodex.UIKit
local C = WeintCodex.Colors
local GC = WeintCodex.GameColors
local W = WeintCodex.UIWindows
local S = WeintCodex.UIStyle

RP.FRAME = "ReputationFrame"
RP.STYLE = S.CHARACTER_INFO

-- Atmosphaere: dezent. Zahlen klein mit Absicht - sie sollen nicht auffallen.
RP.VIGNETTE, RP.VIGNETTE_SIZE = 0.35, 48
RP.LIGHT_HEIGHT = 140
RP.LIST_PAD = 8          -- so weit reicht die Flaeche ueber Liste und Bildlauf
RP.SURFACE_EDGE = 0.07   -- Lichtkante oben an einer Flaeche (weiss)
RP.SHADOW_PAD = 16       -- weicher Schatten unter Liste und Detailansicht
RP.SIGIL_SIZE, RP.SIGIL_SHOW = 240, 0.6   -- Codex-Zeichen: Groesse, gezeigter Teil
RP.SEP_INSET = 10        -- Haarlinie zwischen Fraktionen, vom Rand
-- Detailansicht (6.7.0.2: Tafel mit Bereichen - Name, Stufe | Balken,
-- Beschreibung | Optionen).
RP.DETAIL_TITLE = 16
RP.DETAIL_PAD = 4
RP.DETAIL_LINE = 0.55    -- Kante oben in der Klassenfarbe
RP.DETAIL_INSET = 10
RP.DETAIL_DECOR = { "Border", "NineSlice", "Bg", "Background" }
RP.TITLE_KEYS = { "Title", "FactionName", "Name" }
-- Zeilen: Name und Balken (Quelltext des Spiels, gemessen: Content.ReputationBar).
RP.NAME_KEYS = { "Name", "Title", "Label" }
RP.BAR_KEYS = { "ReputationBar", "StatusBar", "Bar" }
-- Fuellung eines Balkens, der kein Statusbalken ist (gemessen).
RP.FILL_ATLAS = "^common%-stat%-bar%-white"
-- Hervorhebung des Spiels unter der Maus und an der gewaehlten Zeile
-- (gemessen: Content.BackgroundHighlight, braun-gold).
RP.HIGHLIGHT_ATLAS = "^charactercreate%-customize%-dropdown%-linemouseover"
RP.HIGHLIGHT_ALPHA = 0.30   -- 6.7.0.2: 0.55 wirkte als Block
RP.DETAIL_BAR_KEYS = { "ReputationBar", "Bar", "StatusBar" }
RP.DETAIL_GAP = 9        -- Abstand der Trennlinie ueber dem Balken
RP.OPTION_GAP = 14       -- Abstand der Trennlinie ueber den Optionen
RP.OPTION_LINE = 0.40    -- Deckkraft dieser Linie (Klassenfarbe)

local atmos = setmetatable({}, { __mode = "k" })
local rows = setmetatable({}, { __mode = "k" })
local finished = setmetatable({}, { __mode = "k" })
local details = setmetatable({}, { __mode = "k" })
RP.atmos, RP.rows, RP.bars, RP.details = atmos, rows, finished, details
RP.state = { selected = nil, runs = 0 }

local function Visible(t)
    if type(t) ~= "table" or not t.IsVisible then return false end
    local ok, v = pcall(t.IsVisible, t)
    return ok and K.Bool(v, false) or false
end

local function Kind(r)
    local ok, t = pcall(r.GetObjectType, r)
    return ok and t or nil
end

local function IsFrame(t) return type(t) == "table" and type(t.GetObjectType) == "function" end

local function TextOf(fs)
    if not IsFrame(fs) then return nil end
    local ok, v = pcall(fs.GetText, fs)
    v = ok and K.Plain(v) or nil
    return (type(v) == "string" and v ~= "") and v or nil
end

local function AtlasOf(r)
    if Kind(r) ~= "Texture" or not r.GetAtlas then return nil end
    local ok, a = pcall(r.GetAtlas, r)
    a = ok and K.Plain(a) or nil
    return type(a) == "string" and a or nil
end

local function Accent() return S.Accent(RP.STYLE.accent) end
local WHITE = { 1, 1, 1 }

--------------------------------------------------
-- Finden
--------------------------------------------------
function RP.Frame()
    local rf = _G[RP.FRAME]
    return IsFrame(rf) and rf or nil
end

function RP.List(rf)
    local l = rf.ScrollBox
    return IsFrame(l) and l or nil
end

function RP.ScrollBar(rf)
    local b = rf.ScrollBar
    return IsFrame(b) and b or nil
end

-- Wo die Zeilen haengen: ScrollTarget (WowScrollBoxList), sonst die Liste.
function RP.Target(list)
    local t = list.ScrollTarget
    if IsFrame(t) then return t end
    if type(list.GetScrollTarget) == "function" then
        local ok, v = pcall(list.GetScrollTarget, list)
        if ok and IsFrame(v) then return v end
    end
    return list
end

function RP.DetailFrame(rf)
    local d = rf and rf.ReputationDetailFrame
    if IsFrame(d) then return d end
    d = _G.ReputationDetailFrame
    return IsFrame(d) and d or nil
end

function RP.DetailTitle(det)
    for _, key in ipairs(RP.TITLE_KEYS) do
        local t = det[key]
        if IsFrame(t) and Kind(t) == "FontString" then return t end
    end
    local g = _G.ReputationDetailFactionName
    return IsFrame(g) and g or nil
end

-- Die Zeile selbst oder ihr Inhalt (.Content, gemessen).
local function ContentOf(row)
    local c = row.Content
    return IsFrame(c) and c or nil
end

local function ByKeys(f, keys, kind)
    if not f then return nil end
    for _, key in ipairs(keys) do
        local t = f[key]
        if IsFrame(t) and (not kind or Kind(t) == kind) then return t end
    end
    return nil
end

local function FirstRegion(f, kind)
    if not f then return nil end
    for _, r in ipairs(W.Regions(f, "repFind")) do
        if Kind(r) == kind then return r end
    end
    return nil
end

local function FirstChild(f, kind, depth)
    if not f or depth > 2 then return nil end
    for _, ch in ipairs(W.Children(f, "repFind", depth)) do
        if Kind(ch) == kind then return ch end
    end
    for _, ch in ipairs(W.Children(f, "repFind", depth)) do
        local hit = FirstChild(ch, kind, depth + 1)
        if hit then return hit end
    end
    return nil
end

function RP.RowName(row)
    local head = W.ListHeaders[row] or W.Headers[row]
    if head and head.title then return head.title end
    local c = ContentOf(row)
    return ByKeys(c, RP.NAME_KEYS, "FontString") or ByKeys(row, RP.NAME_KEYS, "FontString")
        or FirstRegion(c, "FontString") or FirstRegion(row, "FontString")
end

-- Der Balken einer Zeile. Ueber den Schluessel jede Art von Rahmen
-- (gemessen: in diesem Client kein Statusbalken), sonst der erste
-- Statusbalken bis zwei Ebenen tief.
function RP.RowBar(row)
    local c = ContentOf(row)
    return ByKeys(c, RP.BAR_KEYS) or ByKeys(row, RP.BAR_KEYS) or FirstChild(row, "StatusBar", 0)
end

-- Die Fuellung eines Balkens: beim Statusbalken seine Textur, sonst das
-- Bild "common-stat-bar-white" an ihm. Ohne beides: nil (dann liegt die
-- Veredelung auf dem ganzen Balken).
function RP.BarFill(bar)
    if Kind(bar) == "StatusBar" and bar.GetStatusBarTexture then
        local ok, t = pcall(bar.GetStatusBarTexture, bar)
        if ok and IsFrame(t) then return t, "Statusbalken" end
    end
    for _, r in ipairs(W.Regions(bar, "repFill")) do
        local a = AtlasOf(r)
        if a and a:find(RP.FILL_ATLAS) then return r, "Bild" end
    end
    return nil, "keine"
end

-- Haengt die Detailansicht im Charakterfenster (dann gestaltet sie der
-- Durchlauf ueber das ganze Fenster mit) oder frei am Bildschirm?
function RP.InTree(t, root)
    local p = t
    for _ = 1, 12 do
        local ok, q = pcall(p.GetParent, p)
        if not ok or not IsFrame(q) or q == p then return false end
        if q == root then return true end
        p = q
    end
    return false
end

--------------------------------------------------
-- Flaechen
--------------------------------------------------
-- Eine angehobene Flaeche: weicher Rand, oben eine Lichtkante, die zu
-- beiden Seiten auslaeuft. Dieselbe fuer Liste und Detailansicht - zwei
-- Bereiche derselben Oberflaeche.
-- 6.7.0.2: mit Schatten darunter (S.Shadow) und je Bereich eigener Dichte
-- (`color`: Liste surfaceRaised, Detailansicht surfaceDetail).
function RP.Surface(host, anchor, pad, corner, sub, color)
    local c = color or GC.surfaceRaised
    sub = sub or -4
    local o = { body = S.SoftPanel(host, anchor, c, c[4], pad, sub, corner) }
    o.shadow = S.Shadow(host, anchor, pad + RP.SHADOW_PAD, sub - 1, corner)
    o.edge = S.Divider(host, WHITE, RP.SURFACE_EDGE, 0)
    -- Die Kante liegt auf der Flaeche selbst, ganz unten (unter allem
    -- anderen des Rahmens).
    o.edge.l:SetDrawLayer("BACKGROUND", -3)
    o.edge.r:SetDrawLayer("BACKGROUND", -3)
    S.PlaceTop(o.edge, anchor, 12)
    o.parts = { o.shadow, o.body, o.edge.l, o.edge.r }
    -- Fuer RP.PlaceCard: Flaeche und Schatten mit ihrem Abstand zum Rand.
    o.card = { { tex = o.body, extra = pad - RP.DETAIL_PAD }, { tex = o.shadow, extra = pad - RP.DETAIL_PAD + RP.SHADOW_PAD } }
    return o
end

--------------------------------------------------
-- Atmosphaere
--------------------------------------------------
local function ShowAtmos(a, on)
    if a.on == on then return end
    a.on = on
    for _, t in ipairs(a.parts) do t:SetShown(on) end
end

function RP.Atmosphere(f, rf)
    local a = atmos[rf]
    if a then return a end
    a = { parts = {}, on = true, host = f }
    local v = S.Vignette(f, rf, RP.VIGNETTE, RP.VIGNETTE_SIZE, -6)
    for _, side in ipairs(S.SIDES) do a.parts[#a.parts + 1] = v[side] end
    a.vignette = v
    local l = GC.atmosLight
    a.light = S.TopLight(f, rf, l, l[4], RP.LIGHT_HEIGHT, -5)
    a.parts[#a.parts + 1] = a.light
    local list = RP.List(rf)
    if list then
        a.list = RP.Surface(f, list, RP.LIST_PAD, RP.ScrollBar(rf))
        for _, t in ipairs(a.list.parts) do a.parts[#a.parts + 1] = t end
        -- Codex-Zeichen (media/ui/sigil, 6.7.0.2): ein Astrolab, unten rechts
        -- in der Ecke der Liste angeschnitten, 4,5 % - erst beim Hinsehen.
        local g = GC.codexSigil
        local t = S.Own(f:CreateTexture(nil, "BACKGROUND", nil, -3))
        t:SetTexture(K.MEDIA .. "sigil")
        t:SetVertexColor(g[1], g[2], g[3], g[4])
        t:SetSize(RP.SIGIL_SIZE * RP.SIGIL_SHOW, RP.SIGIL_SIZE * RP.SIGIL_SHOW)
        t:SetTexCoord(0, RP.SIGIL_SHOW, 0, RP.SIGIL_SHOW)
        t:SetPoint("BOTTOMRIGHT", list, "BOTTOMRIGHT", 0, 0)
        a.sigil = t
        a.parts[#a.parts + 1] = t
    end
    atmos[rf] = a
    -- Sofort mit dem Reiter, nicht erst mit dem naechsten Takt: sonst
    -- laege die Flaeche der Liste einen Augenblick unter der Figur.
    if rf.HookScript then
        rf:HookScript("OnShow", function() ShowAtmos(a, true) end)
        rf:HookScript("OnHide", function() ShowAtmos(a, false) end)
    end
    return a
end

--------------------------------------------------
-- Zeilen: Balken, Maus, Auswahl
--------------------------------------------------
function RP.FinishBar(bar)
    if not IsFrame(bar) or finished[bar] or not bar.CreateTexture then return finished[bar] end
    local fill, how = RP.BarFill(bar)
    local o = S.BarFinish(bar, fill)
    o.how = how
    finished[bar] = o
    return o
end

-- Hervorhebungen des Spiels an einer Zeile (Maus, Auswahl).
local function FindHighlights(r, f, out)
    if not f then return end
    for _, t in ipairs(W.Regions(f, "repHl")) do
        local a = AtlasOf(t)
        if a and a:find(RP.HIGHLIGHT_ATLAS) then out[#out + 1] = t end
    end
    local bh = f.BackgroundHighlight
    if IsFrame(bh) then
        for _, t in ipairs(W.Regions(bh, "repHl")) do
            if Kind(t) == "Texture" then out[#out + 1] = t end
        end
    end
end

function RP.Row(row)
    local r = rows[row]
    if r then return r end
    if not row.CreateTexture then return nil end
    local host = ContentOf(row) or row
    if not host.CreateTexture then host = row end
    r = { host = host, bar = RP.RowBar(row), hl = {} }
    r.sel = S.Selection(host)
    FindHighlights(r, host, r.hl)
    if host ~= row then FindHighlights(r, row, r.hl) end
    -- Nur wenn das Spiel keine eigene Hervorhebung hat: unsere (sonst
    -- doppelt unter der Maus).
    local header = W.ListHeaders[row] or W.Headers[row]
    if #r.hl == 0 and not header then
        if Kind(row) == "Button" then r.hover = S.Hover(row)
        elseif Kind(host) == "Button" then r.hover = S.Hover(host) end
    end
    -- Fraktionen voneinander absetzen (6.7.0.2): Haarlinie unten.
    if not header then r.sep = S.Hairline(host, host, RP.SEP_INSET, "BOTTOM", 1) end
    if r.bar then RP.FinishBar(r.bar) end
    rows[row] = r
    return r
end

-- Welche Fraktion gewaehlt ist: die, deren Name rechts in der
-- Detailansicht steht. Ist sie zu, ist keine markiert - lieber keine
-- Auskunft als eine geratene.
function RP.Selected(rf)
    local det = RP.DetailFrame(rf)
    if not det or not Visible(det) then return nil end
    local t = RP.DetailTitle(det)
    return t and TextOf(t) or nil
end

local function UpdateRows(target, selected)
    local accent = Accent()
    for _, row in ipairs(W.Children(target, "repRows")) do
        if IsFrame(row) and Visible(row) then
            local r = RP.Row(row)
            if r then
                -- Balken, die das Spiel spaeter in eine Zeile legt.
                if not r.bar then
                    r.bar = RP.RowBar(row)
                    if r.bar then RP.FinishBar(r.bar) end
                end
                for i = 1, #r.hl do S.Tint(r.hl[i], accent, RP.HIGHLIGHT_ALPHA) end
                if selected and not r.name then r.name = RP.RowName(row) end
                S.SetSelected(r.sel, selected ~= nil and r.name ~= nil and TextOf(r.name) == selected, accent)
            end
        end
    end
end

--------------------------------------------------
-- Detailansicht
--------------------------------------------------
-- 6.7.0.2 (Beta-Test: "hochwertige Informations-/Codex-Tafel"). Die
-- Reihenfolge des Spiels bleibt, WeintCodex zieht nur Grenzen:
--   Name (16 pt) / Stufe
--   ---- Linie in der Klassenfarbe ----
--   Balken (weicher Schatten darunter, Tiefe an der Fuellung)
--   Beschreibung
--   ---- Linie mit Raute ----
--   Optionen (Haekchen) auf eigener, ruhiger Flaeche
-- Die Grenzen richten sich nach den Rahmen des Spiels (Oberkante Balken,
-- oberstes Haekchen), gemessen in jedem Durchlauf, neu gelegt nur bei
-- einer Aenderung. Seit 6.7.0.3 ruecken die Haekchen unter die
-- Beschreibung (siehe "Die Karte" unten) - das einzige, was hier bewegt
-- wird, und nur ueber SetPoint.

-- Der Balken der Detailansicht: ueber den Schluessel, sonst der erste
-- Rahmen bis zwei Ebenen tief, der die Fuellung des Rufs traegt.
local function HasFill(f)
    for _, r in ipairs(W.Regions(f, "repDetFill")) do
        local a = AtlasOf(r)
        if a and a:find(RP.FILL_ATLAS) then return true end
    end
    return false
end

local function FindBar(f, depth)
    if not f or depth > 2 then return nil end
    for _, ch in ipairs(W.Children(f, "repDetBar", depth)) do
        if IsFrame(ch) and (Kind(ch) == "StatusBar" or HasFill(ch)) then return ch end
    end
    for _, ch in ipairs(W.Children(f, "repDetBar", depth)) do
        local hit = IsFrame(ch) and FindBar(ch, depth + 1)
        if hit then return hit end
    end
    return nil
end

function RP.DetailBar(det)
    return ByKeys(det, RP.DETAIL_BAR_KEYS) or FindBar(det, 0)
end

local function Edge(r, method)
    local ok, v = pcall(r[method], r)
    v = ok and K.Plain(v) or nil
    return type(v) == "number" and v or nil
end

-- Oberkante des obersten sichtbaren Haekchens (Optionen), so wie das
-- Spiel es hinsetzt - fuer den Fall, dass die Optionen nicht ruecken.
function RP.OptionTop(det)
    local top, bottom
    for _, ch in ipairs(W.Children(det, "repOpt")) do
        if IsFrame(ch) and Kind(ch) == "CheckButton" and Visible(ch) then
            local t, b = Edge(ch, "GetTop"), Edge(ch, "GetBottom")
            if t and (not top or t > top) then top = t end
            if b and (not bottom or b < bottom) then bottom = b end
        end
    end
    return top, bottom
end

--------------------------------------------------
-- Die Karte (6.7.0.3)
--------------------------------------------------
-- Beta-Test mit Screenshot: unter Beschreibung und Balken viel leerer
-- Raum, die drei Haekchen kleben am unteren Rand (dort verankert sie das
-- Spiel). Jetzt eine KARTE: Name, Stufe, Balken, Beschreibung, darunter
-- direkt der abgesetzte Optionsbereich - und die Flaeche endet kurz unter
-- den Optionen, statt leer bis zum Rand zu laufen.
--
-- Dafuer ruecken die Haekchen nach oben, unter den TEXT der Beschreibung
-- (Oberkante minus Hoehe des Textes). Regeln, damit nichts verloren geht:
--   * nur nach oben, nie tiefer als das Spiel sie setzt; ist die
--     Beschreibung lang, bleiben sie, wo sie sind;
--   * alle gemeinsam, Abstaende untereinander wie im Spiel (gemessen
--     einmal, bevor irgendetwas bewegt wurde);
--   * nur wenn JEDES Haekchen seine Beschriftung selbst traegt (sonst
--     liefe der Text nicht mit) und kein weiterer Knopf in der
--     Detailansicht sichtbar ist (etwa "Ruhm ansehen");
--   * nur SetPoint - Skripte, Zustand, Groesse und Text bleiben die des
--     Spiels. Schiebt das Spiel sie zurueck, rueckt der naechste Durchlauf
--     sie wieder hin.
-- Die Beschreibung: ueber einen Schluessel des Quelltexts, sonst die
-- Schriftzeile mit dem laengsten Text in der Detailansicht (Name, Stufe,
-- Balkentext und Beschriftungen sind kurz).
RP.DESC_KEYS = { "Description", "DescriptionText", "ScrollingDescription", "Text" }
RP.DESC_MIN = 40          -- kuerzer ist keine Beschreibung (Laenge in Bytes, nur zum Vergleich)
RP.OPTION_SPACE = 30      -- Beschreibung -> oberstes Haekchen (Platz fuer die Linie)
RP.OPTION_MIN_SHIFT = 8   -- kleiner lohnt sich das Ruecken nicht
RP.CARD_BOTTOM = 12       -- so weit reicht die Karte unter das letzte Haekchen

local function Longest(f, depth, skip, best, len)
    if not f or depth > 2 then return best, len end
    for _, r in ipairs(W.Regions(f, "repDesc", depth)) do
        if r ~= skip and Kind(r) == "FontString" then
            local t = TextOf(r)
            if t and #t > len then best, len = r, #t end
        end
    end
    for _, ch in ipairs(W.Children(f, "repDesc", depth)) do
        if IsFrame(ch) and Kind(ch) ~= "CheckButton" then best, len = Longest(ch, depth + 1, skip, best, len) end
    end
    return best, len
end

function RP.DetailDescription(det, title)
    for _, key in ipairs(RP.DESC_KEYS) do
        local t = det[key]
        if IsFrame(t) then
            if Kind(t) == "FontString" then return t end
            if type(t.GetFontString) == "function" then
                local ok, fs = pcall(t.GetFontString, t)
                if ok and IsFrame(fs) then return fs end
            end
        end
    end
    local fs, len = Longest(det, 0, title, nil, 0)
    return (fs and len >= RP.DESC_MIN) and fs or nil
end

-- Die Haekchen einmal vermessen, BEVOR etwas bewegt wird: Lage relativ
-- zur Detailansicht, Beschriftung, und ob etwas das Ruecken verbietet.
function RP.Options(d)
    local det = d.frame
    local left, top = Edge(det, "GetLeft"), Edge(det, "GetTop")
    if not left or not top then return nil end
    local list, why = {}, nil
    for _, ch in ipairs(W.Children(det, "repOptAll")) do
        if IsFrame(ch) and Visible(ch) then
            local kind = Kind(ch)
            if kind == "CheckButton" then
                local l, t, b = Edge(ch, "GetLeft"), Edge(ch, "GetTop"), Edge(ch, "GetBottom")
                if l and t then
                    local o = { frame = ch, x = l - left, y = t - top, yb = (b or t) - top }
                    o.label = FirstRegion(ch, "FontString") ~= nil
                        or (IsFrame(ch.Text) and Kind(ch.Text) == "FontString")
                    if not o.label then why = "Beschriftung nicht am Häkchen" end
                    list[#list + 1] = o
                end
            elseif kind == "Button" and ch ~= det.CloseButton then
                why = why or "weiterer Knopf in der Detailansicht"
            end
        end
    end
    if #list == 0 then return nil end
    local first, low = list[1].y, list[1].yb
    for _, o in ipairs(list) do
        if o.y > first then first = o.y end
        if o.yb < low then low = o.yb end
    end
    d.opts, d.optFirst, d.optLow = list, first, low
    d.movable, d.why = why == nil, why
    return list
end

-- Die Haekchen um `shift` px nach oben (0 = wo das Spiel sie hatte).
-- Legt nur neu, wenn sich das Ziel aendert oder das Spiel sie verschoben hat.
function RP.PlaceOptions(d, shift)
    local det, first = d.frame, d.opts[1]
    local top, now = Edge(det, "GetTop"), Edge(first.frame, "GetTop")
    local drift = top and now and math.abs((now - top) - (first.y + (d.shift or 0))) > 1
    if d.shift == shift and not drift then return end
    if d.shift == nil and shift == 0 then return end   -- nie bewegt: nichts anfassen
    for _, o in ipairs(d.opts) do
        o.frame:ClearAllPoints()
        o.frame:SetPoint("TOPLEFT", det, "TOPLEFT", o.x, o.y + shift)
    end
    d.shift = shift
end

function RP.DetailParts(d)
    local det, accent = d.frame, Accent()
    -- Optionen: leicht vertieft, eigener Bereich unter einer Linie mit Raute.
    local c = GC.surfaceSunken
    d.options = S.SoftPanel(det, det, c, c[4], 0, -6)
    d.optLine = S.Under(S.Divider(det, accent, RP.OPTION_LINE, 0), -1)
    d.optDot = S.Diamond(det, 5, accent, 0.8, 0)
    d.optDot:SetDrawLayer("BACKGROUND", 0)
    d.optHole = S.Diamond(det, 2, C.surface1, 1, 0)
    d.optHole:SetDrawLayer("BACKGROUND", 1)
    d.optHole:SetPoint("CENTER", d.optDot, "CENTER", 0, 0)
    d.zones = { d.options, d.optLine.l, d.optLine.r, d.optDot, d.optHole }
    for _, t in ipairs(d.zones) do t:Hide() end
end

function RP.DetailBarParts(d)
    local det = d.frame
    d.barShadow = S.Shadow(det, d.bar, 8, -5)
    d.barLine = S.Under(S.Divider(det, Accent(), RP.DETAIL_LINE, 0), -1)
    d.barLine.l:Hide()
    d.barLine.r:Hide()
    RP.FinishBar(d.bar)
end

local function ShowZone(on, ...)
    for i = 1, select("#", ...) do
        local t = select(i, ...)
        if t then t:SetShown(on) end
    end
end

-- Flaeche der Karte (und ihr Schatten): oben wie immer, unten bis
-- `yBottom` (relativ zur Oberkante) oder bis zum Rand.
function RP.PlaceCard(d, yBottom)
    local o, det = d.surface, d.frame
    if not o then return end
    local pad = RP.DETAIL_PAD
    for _, part in ipairs(o.card) do
        local p = pad + part.extra
        part.tex:ClearAllPoints()
        part.tex:SetPoint("TOPLEFT", det, "TOPLEFT", -p, p)
        if yBottom then part.tex:SetPoint("BOTTOMRIGHT", det, "TOPRIGHT", p, yBottom - p)
        else part.tex:SetPoint("BOTTOMRIGHT", det, "BOTTOMRIGHT", p, -p) end
    end
end

-- Wo die Beschreibung endet (relativ zur Oberkante): Oberkante des
-- Textes minus seine Hoehe.
local function DescBottom(d, top)
    if not d.desc then return nil end
    local t, h = Edge(d.desc, "GetTop"), Edge(d.desc, "GetStringHeight")
    if not t or not h then return nil end
    return t - h - top
end

function RP.DetailLayout(d)
    local det = d.frame
    local top = Edge(det, "GetTop")
    if not top then return end
    if not d.desc then d.desc = RP.DetailDescription(det, d.title) end
    if not d.opts then RP.Options(d) end
    -- Ruecken: Ziel knapp unter dem Text der Beschreibung, nie tiefer als
    -- das Spiel die Haekchen setzt.
    local shift = 0
    if d.opts and d.movable then
        local db = DescBottom(d, top)
        if db then
            local up = (db - RP.OPTION_SPACE) - d.optFirst
            if up >= RP.OPTION_MIN_SHIFT then shift = math.floor(up + 0.5) end
        end
        RP.PlaceOptions(d, shift)
    end
    local barTop = d.bar and Edge(d.bar, "GetTop")
    local barBottom = d.bar and Edge(d.bar, "GetBottom")
    local yBar = barTop and (barTop - top) or false
    local yBarB = barBottom and (barBottom - top) or false
    local yOpt, yOptB
    if d.opts and d.movable then
        -- Aus der eigenen Rechnung: gleich nach SetPoint misst der Client
        -- noch die alte Lage.
        yOpt, yOptB = d.optFirst + shift, d.optLow + shift
    else
        local ot, ob = RP.OptionTop(det)
        yOpt, yOptB = ot and (ot - top) or false, ob and (ob - top) or false
    end
    yOpt, yOptB = yOpt or false, yOptB or false
    if d.yBar == yBar and d.yBarB == yBarB and d.yOpt == yOpt and d.yOptB == yOptB then return end
    d.yBar, d.yBarB, d.yOpt, d.yOptB = yBar, yBarB, yOpt, yOptB
    local inset = RP.DETAIL_INSET
    if yBar and d.barLine then
        S.PlaceTop(d.barLine, det, inset, yBar + RP.DETAIL_GAP)
    end
    if d.barLine then ShowZone(yBar and true or false, d.barLine.l, d.barLine.r) end
    local yLine = yOpt and (yOpt + RP.OPTION_GAP) or false
    if yLine then
        S.PlaceTop(d.optLine, det, inset, yLine)
        d.optDot:ClearAllPoints()
        d.optDot:SetPoint("CENTER", det, "TOP", 0, yLine)
        -- Bereich der Optionen: von der Linie bis knapp unter das letzte
        -- Haekchen (geruckt) bzw. bis zum Rand.
        local moved = (d.shift or 0) > 0
        S.PlaceBand(d.options, det, 2, yLine - 1, (moved and yOptB) and (yOptB - RP.CARD_BOTTOM + 4) or nil)
    end
    ShowZone(yLine and true or false, d.optLine.l, d.optLine.r, d.optDot, d.optHole, d.options)
    -- Die Karte endet unter den Optionen, wenn sie geruckt sind.
    local moved = (d.shift or 0) > 0 and yOptB
    RP.PlaceCard(d, moved and (yOptB - RP.CARD_BOTTOM) or nil)
end

-- Im Fenster: dieselbe angehobene Flaeche wie die Liste (ein Bereich der
-- Oberflaeche, keine zweite Tafel), oben eine feine Kante in der
-- Klassenfarbe. Frei am Bildschirm (anderer Client): eine deckende Tafel,
-- sonst stuende der Text ueber der Welt.
function RP.Detail(f, rf)
    local det = RP.DetailFrame(rf)
    if not det or not Visible(det) then return nil end
    local d = details[det]
    if not d then
        d = { frame = det }
        S.Scope(det, RP.STYLE)
        for _, key in ipairs(RP.DETAIL_DECOR) do
            local part = det[key]
            if IsFrame(part) then W.HideDecor(part) end
        end
        d.inTree = RP.InTree(det, f)
        if d.inTree then
            d.surface = RP.Surface(det, det, RP.DETAIL_PAD, nil, -7, GC.surfaceDetail)
        else
            d.panel = S.Panel(det)
        end
        d.line = S.Divider(det, Accent(), RP.DETAIL_LINE, 1)
        d.line.l:SetDrawLayer("BACKGROUND", -2)
        d.line.r:SetDrawLayer("BACKGROUND", -2)
        S.PlaceTop(d.line, det, RP.DETAIL_INSET)
        d.title = RP.DetailTitle(det)
        if d.title then S.Title(d.title, RP.DETAIL_TITLE, C.textBright) end
        RP.DetailParts(d)
        details[det] = d
    end
    if not d.bar then
        d.bar = RP.DetailBar(det)
        if d.bar then RP.DetailBarParts(d) end
    end
    RP.DetailLayout(d)
    -- Frei am Bildschirm: der Durchlauf ueber das Fenster erreicht sie
    -- nicht - Holz und rote Knoepfe hier.
    if not d.inTree then
        W.HideByAtlas(det)
        W.Grey(det)
    end
    return d
end

--------------------------------------------------
-- Ein Durchlauf (aus W.Inner, Charakterfenster offen)
--------------------------------------------------
function RP.Update(f)
    local rf = RP.Frame()
    if not rf then return nil end
    local a = atmos[rf]
    if not Visible(rf) then
        if a then ShowAtmos(a, false) end
        return nil
    end
    S.Scope(rf, RP.STYLE)
    a = RP.Atmosphere(f, rf)
    ShowAtmos(a, true)
    RP.state.runs = RP.state.runs + 1
    local selected = RP.Selected(rf)
    RP.state.selected = selected
    local list = RP.List(rf)
    if list then UpdateRows(RP.Target(list), selected) end
    RP.Detail(f, rf)
    return a
end

--------------------------------------------------
-- /wcui fenster
--------------------------------------------------
function RP.Report(f, out)
    local rf = RP.Frame()
    if not rf or not Visible(rf) then return out end
    local list = RP.List(rf)
    local n, heads, bars, named, hls, kind, how = 0, 0, 0, 0, 0, nil, nil
    if list then
        for _, row in ipairs(W.Children(RP.Target(list), "repReport")) do
            if IsFrame(row) and Visible(row) then
                n = n + 1
                if W.ListHeaders[row] or W.Headers[row] then heads = heads + 1 end
                local r = rows[row]
                if r and r.bar then
                    bars = bars + 1
                    kind = kind or Kind(r.bar)
                    how = how or (finished[r.bar] and finished[r.bar].how)
                end
                if r then hls = hls + #r.hl end
                if RP.RowName(row) then named = named + 1 end
            end
        end
    end
    out[#out + 1] = string.format("   Ruf (Stil %s): Liste %s, %d Zeilen (%d Kopfzeilen, %d mit Balken, %d mit Namen)",
        RP.STYLE.name, list and "gefunden" or "FEHLT", n, heads, bars, named)
    out[#out + 1] = string.format("   Ruf, Balken: %s, Füllung %s · Hervorhebungen des Spiels getönt: %d",
        kind or "–", how or "–", hls)
    out[#out + 1] = "   Ruf, gewählt: " .. (RP.state.selected and ("„" .. RP.state.selected .. "“") or "keine (Detailansicht zu)")
    local det = RP.DetailFrame(rf)
    local d = det and details[det]
    if not det then
        out[#out + 1] = "   Ruf, Detailansicht: nicht gefunden"
    elseif not d then
        out[#out + 1] = "   Ruf, Detailansicht: " .. (Visible(det) and "offen, noch nicht gestaltet" or "zu")
    else
        local shown = 0
        for _, key in ipairs(RP.DETAIL_DECOR) do
            local part = det[key]
            if IsFrame(part) then
                for _, r in ipairs(W.Regions(part, "repReport")) do
                    if Kind(r) == "Texture" and not S.own[r] and K.Plain(r:GetAlpha()) ~= 0 then shown = shown + 1 end
                end
            end
        end
        out[#out + 1] = string.format("   Ruf, Detailansicht: %s, Titel %s, Rahmen des Spiels: %d Bilder noch sichtbar",
            d.inTree and "Fläche im Fenster" or "Tafel, frei", d.title and ("„" .. (TextOf(d.title) or "?") .. "“") or "FEHLT", shown)
        local opts = 0
        for _, ch in ipairs(W.Children(det, "repReport")) do
            if IsFrame(ch) and Kind(ch) == "CheckButton" then opts = opts + 1 end
        end
        out[#out + 1] = string.format("   Ruf, Karte: Balken %s, Beschreibung %s, Optionen %d Häkchen, Bereiche: Balken %s, Optionen %s",
            d.bar and (Kind(d.bar) or "?") or "FEHLT", d.desc and "gefunden" or "FEHLT", opts,
            d.yBar and string.format("%.0f", d.yBar) or "–",
            d.yOpt and string.format("%.0f", d.yOpt) or "–")
        local moved
        if not d.opts then moved = "nicht gerückt (keine Häkchen vermessen)"
        elseif not d.movable then moved = "nicht gerückt (" .. tostring(d.why) .. ")"
        elseif (d.shift or 0) > 0 then moved = string.format("um %d px nach oben gerückt, Karte endet darunter", d.shift)
        else moved = "an ihrem Platz (Beschreibung lang oder unbekannt)" end
        out[#out + 1] = "   Ruf, Optionen: " .. moved
    end
    return out
end
