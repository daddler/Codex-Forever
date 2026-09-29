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
--   Beschreibung auf einer leicht vertieften Flaeche
--   ---- Linie mit Raute ----
--   Optionen (Haekchen) auf eigener, ruhiger Flaeche bis unten
-- Keine Zeile des Spiels wird verschoben: die Grenzen richten sich nach
-- den Rahmen des Spiels (Oberkante Balken, oberstes Haekchen), gemessen
-- in jedem Durchlauf, neu gelegt nur bei einer Aenderung.

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

-- Oberkante des obersten sichtbaren Haekchens (Optionen).
function RP.OptionTop(det)
    local top
    for _, ch in ipairs(W.Children(det, "repOpt")) do
        if IsFrame(ch) and Kind(ch) == "CheckButton" and Visible(ch) then
            local t = Edge(ch, "GetTop")
            if t and (not top or t > top) then top = t end
        end
    end
    return top
end

function RP.DetailParts(d)
    local det, accent = d.frame, Accent()
    -- Beschreibung: leicht vertieft. Optionen: ebenso, bis unten.
    local c = GC.surfaceSunken
    d.page = S.SoftPanel(det, det, c, c[4], 0, -6)
    d.options = S.SoftPanel(det, det, c, c[4], 0, -6)
    d.optLine = S.Under(S.Divider(det, accent, RP.OPTION_LINE, 0), -1)
    d.optDot = S.Diamond(det, 5, accent, 0.8, 0)
    d.optDot:SetDrawLayer("BACKGROUND", 0)
    d.optHole = S.Diamond(det, 2, C.surface1, 1, 0)
    d.optHole:SetDrawLayer("BACKGROUND", 1)
    d.optHole:SetPoint("CENTER", d.optDot, "CENTER", 0, 0)
    d.zones = { d.page, d.options, d.optLine.l, d.optLine.r, d.optDot, d.optHole }
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

function RP.DetailLayout(d)
    local det = d.frame
    local top = Edge(det, "GetTop")
    if not top then return end
    local barTop = d.bar and Edge(d.bar, "GetTop")
    local barBottom = d.bar and Edge(d.bar, "GetBottom")
    local optTop = RP.OptionTop(det)
    local yBar = barTop and (barTop - top) or false
    local yBarB = barBottom and (barBottom - top) or false
    local yOpt = optTop and (optTop - top) or false
    if d.yBar == yBar and d.yBarB == yBarB and d.yOpt == yOpt then return end
    d.yBar, d.yBarB, d.yOpt = yBar, yBarB, yOpt
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
        S.PlaceBand(d.options, det, 2, yLine - 1, nil)
    end
    ShowZone(yLine and true or false, d.optLine.l, d.optLine.r, d.optDot, d.optHole, d.options)
    -- Beschreibung: zwischen Balken und Optionen, nur wenn Platz ist.
    local page = yBarB and yLine and (yBarB - yLine) > 30
    if page then S.PlaceBand(d.page, det, inset - 4, yBarB - 6, yLine + 6) end
    d.page:SetShown(page and true or false)
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
        out[#out + 1] = string.format("   Ruf, Tafel: Balken %s, Optionen %d Häkchen, Bereiche: Balken %s, Beschreibung %s, Optionen %s",
            d.bar and (Kind(d.bar) or "?") or "FEHLT", opts,
            d.yBar and string.format("%.0f", d.yBar) or "–",
            (d.page and d.page:IsShown()) and "ja" or "nein",
            d.yOpt and string.format("%.0f", d.yOpt) or "–")
    end
    return out
end
