--------------------------------------------------
-- WeintCodex :: Oberflaeche - Register (6.7.1.0)
--------------------------------------------------
-- Die "ruhige Informationsoberflaeche" als EIN Baustein: eine Liste des
-- Spiels (ScrollBox mit Gruppen, Zeilen, Balken) und rechts daneben eine
-- Detailansicht, die zur Karte wird. Entstanden im Ruf (6.7.0.0 bis
-- 6.7.0.3, ui/reputation.lua), seit 6.7.1.0 hier, damit das
-- Fertigkeitenfenster (ui/skills.lua) dasselbe System bekommt statt einer
-- Kopie - und jedes weitere Fenster dieser Art ebenso.
--
--   WeintCodex.UIRegister.New(cfg)  ->  ein Register mit Update/Report
--
-- Was ein Register tut, von hinten nach vorn (Einzelheiten an den
-- Funktionen, Werte in core/ui.lua und ui/style.lua):
--   Atmosphaere  auf dem Charakterfenster selbst, unter allem, was das
--                Spiel zeichnet: Vignette, neutrales Licht, angehobene
--                Flaeche mit Schatten unter Liste und Bildlauf; wahlweise
--                das Codex-Zeichen (cfg.sigil).
--   Gruppen      Kopfzeilen im Stil des Bereichs (ui/windows.lua,
--                W.ListHeader): Band, Raute, Linie; Einrueckung bleibt.
--   Zeilen       Haarlinie zwischen den Eintraegen; Hervorhebung des
--                Spiels getoent; Auswahl = Strich, Schein, Spur heller.
--   Balken       Bahn dunkler, Schatten und Lichtkante an der Fuellung.
--                Farbe und Text des Spiels bleiben (Ruf: Stufe; Fertigkeit:
--                Fortschritt) - nie die Klassenfarbe.
--   Karte        Detailansicht als Karte: Titel groesser (nicht, wenn er
--                IM Balken steht), Linie am Balken, Beschreibung, darunter
--                ein abgesetzter Bereich fuer das, was folgt (Haekchen oder
--                weitere Zeilen), Karte endet unter dem Inhalt.
--
-- Nur Aussehen und - einzige Ausnahme - die Lage von Haekchen unter der
-- Beschreibung (siehe "Die Karte"). Kein SetText, kein Feld an einem
-- Rahmen des Spiels, keine Zeile versteckt.
--
-- cfg (alle optional ausser label/frames):
--   label         Name im Bericht ("Ruf", "Fertigkeiten")
--   frames        Wege zum Fenster: { "Name" } (global) oder
--                 { "Eltern.Schluessel" } (ueber W.Resolve)
--   style         Stil aus ui/style.lua (Standard S.CHARACTER_INFO)
--   detailKeys    Schluessel der Detailansicht am Fenster
--   detailGlobals globale Namen der Detailansicht
--   detailSearch  true: sonst das Kind des Fensters mit dem laengsten Text
--   titleKeys, titleGlobals   Titel der Detailansicht; sonst (titleTop)
--                 die oberste Schriftzeile in ihr
--   sigil         true: Codex-Zeichen unten rechts in der Liste
--   barLine       "above" (Linie ueber dem Balken) oder "below"
--   tail          true: was unter der Beschreibung steht (keine Haekchen),
--                 bekommt den abgesetzten Bereich
--   compact       true: Karte endet immer unter dem Inhalt (sonst nur,
--                 wenn Haekchen geruckt sind)
--   key           Kurzname fuer die wiederverwendeten Listen (W.Regions)
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIRegister = {}

local RG = WeintCodex.UIRegister
local K = WeintCodex.UIKit
local C = WeintCodex.Colors
local GC = WeintCodex.GameColors
local W = WeintCodex.UIWindows
local S = WeintCodex.UIStyle

local WHITE = { 1, 1, 1 }

--------------------------------------------------
-- Werkzeuge (fuer alle Register gleich)
--------------------------------------------------
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

local function Edge(r, method)
    local ok, v = pcall(r[method], r)
    v = ok and K.Plain(v) or nil
    return type(v) == "number" and v or nil
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
    for _, r in ipairs(W.Regions(f, "regFind")) do
        if Kind(r) == kind then return r end
    end
    return nil
end

local function FirstChild(f, kind, depth)
    if not f or depth > 2 then return nil end
    for _, ch in ipairs(W.Children(f, "regFind", depth)) do
        if Kind(ch) == kind then return ch end
    end
    for _, ch in ipairs(W.Children(f, "regFind", depth)) do
        local hit = FirstChild(ch, kind, depth + 1)
        if hit then return hit end
    end
    return nil
end

-- Haengt `t` unter `root` (bis zwoelf Ebenen)?
local function InTree(t, root)
    local p = t
    for _ = 1, 12 do
        local ok, q = pcall(p.GetParent, p)
        if not ok or not IsFrame(q) or q == p then return false end
        if q == root then return true end
        p = q
    end
    return false
end

-- Schriftzeile mit dem laengsten Text unter `f` (bis zwei Ebenen, ohne
-- Haekchen). Laenge in Bytes - nur zum Vergleich, nie zur Anzeige.
local function Longest(f, depth, skip, best, len)
    if not f or depth > 2 then return best, len end
    for _, r in ipairs(W.Regions(f, "regDesc", depth)) do
        if r ~= skip and Kind(r) == "FontString" then
            local t = TextOf(r)
            if t and #t > len then best, len = r, #t end
        end
    end
    for _, ch in ipairs(W.Children(f, "regDesc", depth)) do
        if IsFrame(ch) and Kind(ch) ~= "CheckButton" then best, len = Longest(ch, depth + 1, skip, best, len) end
    end
    return best, len
end

-- Oberste Schriftzeile mit Text unter `f` (bis zwei Ebenen).
local function Topmost(f, depth, best, top)
    if not f or depth > 2 then return best, top end
    for _, r in ipairs(W.Regions(f, "regTop", depth)) do
        if Kind(r) == "FontString" and TextOf(r) then
            local t = Edge(r, "GetTop")
            if t and (not top or t > top) then best, top = r, t end
        end
    end
    for _, ch in ipairs(W.Children(f, "regTop", depth)) do
        if IsFrame(ch) and Kind(ch) ~= "CheckButton" then best, top = Topmost(ch, depth + 1, best, top) end
    end
    return best, top
end

local function ShowZone(on, ...)
    for i = 1, select("#", ...) do
        local t = select(i, ...)
        if t then t:SetShown(on) end
    end
end

local function ShowAtmos(a, on)
    if a.on == on then return end
    a.on = on
    for _, t in ipairs(a.parts) do t:SetShown(on) end
end

-- Balken finden (6.7.2.0 aus dem Register herausgeloest - auch das PvP-
-- Fenster braucht sie): ein Statusbalken oder ein Rahmen, der die
-- Fuellung "common-stat-bar-white" traegt (gemessen im Ruf), bis zwei
-- Ebenen tief.
RG.FILL_ATLAS = "^common%-stat%-bar%-white"

local function HasFill(f)
    for _, r in ipairs(W.Regions(f, "regDetFill")) do
        local a = AtlasOf(r)
        if a and a:find(RG.FILL_ATLAS) then return true end
    end
    return false
end

local function FindBar(f, depth, skip)
    if not f or depth > 2 then return nil end
    for _, ch in ipairs(W.Children(f, "regDetBar", depth)) do
        if IsFrame(ch) and ch ~= skip and (Kind(ch) == "StatusBar" or HasFill(ch)) then return ch end
    end
    for _, ch in ipairs(W.Children(f, "regDetBar", depth)) do
        local hit = IsFrame(ch) and ch ~= skip and FindBar(ch, depth + 1, skip)
        if hit then return hit end
    end
    return nil
end

-- Die Fuellung eines Balkens: beim Statusbalken seine Textur, sonst das
-- Bild "common-stat-bar-white" an ihm. Ohne beides: nil (dann liegt die
-- Veredelung auf dem ganzen Balken).
function RG.BarFill(bar)
    if Kind(bar) == "StatusBar" and bar.GetStatusBarTexture then
        local ok, t = pcall(bar.GetStatusBarTexture, bar)
        if ok and IsFrame(t) then return t, "Statusbalken" end
    end
    for _, r in ipairs(W.Regions(bar, "regFill")) do
        local a = AtlasOf(r)
        if a and a:find(RG.FILL_ATLAS) then return r, "Bild" end
    end
    return nil, "keine"
end

-- Werkzeuge fuer andere Fenster derselben Sprache (ui/pvp.lua).
RG.Visible, RG.Kind, RG.TextOf, RG.InTree = Visible, Kind, TextOf, InTree
RG.IsFrame, RG.AtlasOf, RG.Edge, RG.FindBar = IsFrame, AtlasOf, Edge, FindBar
RG.Longest, RG.Topmost, RG.ShowZone, RG.ShowAtmos = Longest, Topmost, ShowZone, ShowAtmos

-- Alle Register, in der Reihenfolge ihres Anlegens. ui/windows.lua ruft
-- jedes in jedem Durchlauf ueber das Charakterfenster (W.Inner) und im
-- Bericht (W.SoftReport); ein neues Fenster braucht dort keine Zeile.
RG.all = {}

--------------------------------------------------
-- Ein Register
--------------------------------------------------
function RG.New(cfg)
    local R = {}
    R.LABEL = cfg.label or "Register"
    R.FRAMES = cfg.frames or {}
    R.STYLE = cfg.style or S.CHARACTER_INFO
    R.CFG = cfg
    RG.all[#RG.all + 1] = R
    -- Reiter des Charakterfensters: W.Inner ruft jeden (ui/windows.lua, W.TABS).
    W.TABS[#W.TABS + 1] = R
    -- Der Stil gilt ab dem ersten Durchlauf fuer das ganze Fenster (auch
    -- fuer Kopfzeilen, die W.HideByAtlas vor R.Update gestaltet).
    for _, path in ipairs(R.FRAMES) do S.SCOPES[path] = R.STYLE end

    -- Atmosphaere: dezent. Zahlen klein mit Absicht - sie sollen nicht auffallen.
    R.VIGNETTE, R.VIGNETTE_SIZE = 0.35, 48
    R.LIGHT_HEIGHT = 140
    R.LIST_PAD = 8          -- so weit reicht die Flaeche ueber Liste und Bildlauf
    R.SURFACE_EDGE = 0.07   -- Lichtkante oben an einer Flaeche (weiss)
    R.SHADOW_PAD = 16       -- weicher Schatten unter Liste und Detailansicht
    R.SIGIL_SIZE, R.SIGIL_SHOW = 240, 0.6   -- Codex-Zeichen: Groesse, gezeigter Teil
    R.SEP_INSET = 10        -- Haarlinie zwischen Eintraegen, vom Rand
    -- Detailansicht als Karte.
    R.DETAIL_TITLE = 16
    R.DETAIL_PAD = 4
    R.DETAIL_LINE = 0.55    -- Kante oben und Linie am Balken (Klassenfarbe)
    R.DETAIL_INSET = 10
    R.DETAIL_DECOR = { "Border", "NineSlice", "Bg", "Background" }
    R.DETAIL_KEYS = cfg.detailKeys or {}
    R.DETAIL_GLOBALS = cfg.detailGlobals or {}
    R.TITLE_KEYS = cfg.titleKeys or { "Title", "Name" }
    R.TITLE_GLOBALS = cfg.titleGlobals or {}
    -- Zeilen: Name und Balken (gemessen im Ruf: Content.Name, Content.ReputationBar).
    R.NAME_KEYS = { "Name", "Title", "Label" }
    R.BAR_KEYS = cfg.barKeys or { "StatusBar", "Bar" }
    -- Fuellung eines Balkens, der kein Statusbalken ist (gemessen im Ruf).
    R.FILL_ATLAS = RG.FILL_ATLAS
    -- Hervorhebung des Spiels unter der Maus und an der gewaehlten Zeile
    -- (gemessen im Ruf: Content.BackgroundHighlight, braun-gold).
    R.HIGHLIGHT_ATLAS = "^charactercreate%-customize%-dropdown%-linemouseover"
    R.HIGHLIGHT_ALPHA = 0.30
    R.DETAIL_BAR_KEYS = cfg.detailBarKeys or { "Bar", "StatusBar" }
    R.DETAIL_GAP = 9        -- Abstand der Linie am Balken
    R.OPTION_GAP = 14       -- Abstand der Linie ueber dem unteren Bereich
    R.OPTION_LINE = 0.40    -- Deckkraft dieser Linie (Klassenfarbe)
    R.DESC_KEYS = { "Description", "DescriptionText", "ScrollingDescription", "Text" }
    R.DESC_MIN = 40          -- kuerzer ist keine Beschreibung (Bytes, nur Vergleich)
    R.OPTION_SPACE = 30      -- Beschreibung -> oberstes Haekchen (Platz fuer die Linie)
    R.OPTION_MIN_SHIFT = 8   -- kleiner lohnt sich das Ruecken nicht
    R.CARD_BOTTOM = 12       -- so weit reicht die Karte unter den Inhalt
    R.TAIL_GAP = 14          -- Beschreibung -> Linie ueber dem, was folgt

    local atmos = setmetatable({}, { __mode = "k" })
    local rows = setmetatable({}, { __mode = "k" })
    local finished = setmetatable({}, { __mode = "k" })
    local details = setmetatable({}, { __mode = "k" })
    R.atmos, R.rows, R.bars, R.details = atmos, rows, finished, details
    R.state = { selected = nil, runs = 0 }

    local function Accent() return S.Accent(R.STYLE.accent) end

    --------------------------------------------------
    -- Finden
    --------------------------------------------------
    function R.Frame()
        for _, path in ipairs(R.FRAMES) do
            local f = path:find(".", 1, true) and W.Resolve(path) or _G[path]
            if IsFrame(f) then return f end
        end
        return nil
    end

    function R.List(rf)
        local l = rf.ScrollBox
        return IsFrame(l) and l or nil
    end

    function R.ScrollBar(rf)
        local b = rf.ScrollBar
        return IsFrame(b) and b or nil
    end

    -- Wo die Zeilen haengen: ScrollTarget (WowScrollBoxList), sonst die Liste.
    function R.Target(list)
        local t = list.ScrollTarget
        if IsFrame(t) then return t end
        if type(list.GetScrollTarget) == "function" then
            local ok, v = pcall(list.GetScrollTarget, list)
            if ok and IsFrame(v) then return v end
        end
        return list
    end

    -- Die Detailansicht: Schluessel, globale Namen, sonst (cfg.detailSearch)
    -- das Kind des Fensters - nicht Liste, nicht Bildlauf - mit dem
    -- laengsten Text (die Beschreibung).
    function R.DetailFrame(rf)
        if not rf then return nil end
        local d = ByKeys(rf, R.DETAIL_KEYS)
        if d then return d end
        for _, n in ipairs(R.DETAIL_GLOBALS) do
            if IsFrame(_G[n]) then return _G[n] end
        end
        if cfg.detailSearch then
            if R.found and R.found.root == rf then return R.found.frame end
            local list, bar = R.List(rf), R.ScrollBar(rf)
            local best, blen = nil, R.DESC_MIN - 1
            for _, ch in ipairs(W.Children(rf, "regDetail")) do
                if IsFrame(ch) and ch ~= list and ch ~= bar and Visible(ch) then
                    local _, len = Longest(ch, 0, nil, nil, 0)
                    if len > blen then best, blen = ch, len end
                end
            end
            if best then R.found = { root = rf, frame = best } end
            return best
        end
        return nil
    end

    -- Titel: Schluessel, globale Namen, sonst (cfg.titleTop) die oberste
    -- Schriftzeile der Detailansicht.
    function R.DetailTitle(det)
        local t = ByKeys(det, R.TITLE_KEYS, "FontString")
        if t then return t end
        for _, n in ipairs(R.TITLE_GLOBALS) do
            if IsFrame(_G[n]) then return _G[n] end
        end
        if cfg.titleTop then return (Topmost(det, 0, nil, nil)) end
        return nil
    end

    -- Die Zeile selbst oder ihr Inhalt (.Content, gemessen im Ruf).
    local function ContentOf(row)
        local c = row.Content
        return IsFrame(c) and c or nil
    end

    function R.RowName(row)
        local head = W.ListHeaders[row] or W.Headers[row]
        if head and head.title then return head.title end
        local c = ContentOf(row)
        return ByKeys(c, R.NAME_KEYS, "FontString") or ByKeys(row, R.NAME_KEYS, "FontString")
            or FirstRegion(c, "FontString") or FirstRegion(row, "FontString")
    end

    -- Der Balken einer Zeile. Ueber den Schluessel jede Art von Rahmen
    -- (gemessen im Ruf: kein Statusbalken), sonst der erste Balken bis zwei
    -- Ebenen tief (6.7.1.0: auch einer mit Bild als Fuellung - die Schluessel
    -- anderer Fenster sind ungemessen).
    function R.RowBar(row)
        local c = ContentOf(row)
        return ByKeys(c, R.BAR_KEYS) or ByKeys(row, R.BAR_KEYS) or FindBar(row, 0)
    end

    R.BarFill = RG.BarFill

    R.InTree = InTree

    --------------------------------------------------
    -- Flaechen
    --------------------------------------------------
    -- Eine angehobene Flaeche: weicher Rand, Schatten darunter, oben eine
    -- Lichtkante, die zu beiden Seiten auslaeuft. Je Bereich eigene Dichte
    -- (`color`: Liste surfaceRaised, Detailansicht surfaceDetail).
    function R.Surface(host, anchor, pad, corner, sub, color)
        local c = color or GC.surfaceRaised
        sub = sub or -4
        local o = { body = S.SoftPanel(host, anchor, c, c[4], pad, sub, corner) }
        o.shadow = S.Shadow(host, anchor, pad + R.SHADOW_PAD, sub - 1, corner)
        o.edge = S.Divider(host, WHITE, R.SURFACE_EDGE, 0)
        o.edge.l:SetDrawLayer("BACKGROUND", -3)
        o.edge.r:SetDrawLayer("BACKGROUND", -3)
        S.PlaceTop(o.edge, anchor, 12)
        o.parts = { o.shadow, o.body, o.edge.l, o.edge.r }
        -- Fuer R.PlaceCard: Flaeche und Schatten mit ihrem Abstand zum Rand.
        o.card = { { tex = o.body, extra = pad - R.DETAIL_PAD }, { tex = o.shadow, extra = pad - R.DETAIL_PAD + R.SHADOW_PAD } }
        return o
    end

    --------------------------------------------------
    -- Atmosphaere
    --------------------------------------------------
    function R.Atmosphere(f, rf)
        local a = atmos[rf]
        if a then return a end
        a = { parts = {}, on = true, host = f }
        local v = S.Vignette(f, rf, R.VIGNETTE, R.VIGNETTE_SIZE, -6)
        for _, side in ipairs(S.SIDES) do a.parts[#a.parts + 1] = v[side] end
        a.vignette = v
        local l = GC.atmosLight
        a.light = S.TopLight(f, rf, l, l[4], R.LIGHT_HEIGHT, -5)
        a.parts[#a.parts + 1] = a.light
        local list = R.List(rf)
        if list then
            a.list = R.Surface(f, list, R.LIST_PAD, R.ScrollBar(rf))
            for _, t in ipairs(a.list.parts) do a.parts[#a.parts + 1] = t end
            -- Codex-Zeichen (media/ui/sigil, 6.7.0.2): ein Astrolab, unten
            -- rechts in der Ecke der Liste angeschnitten, 4,5 %.
            if cfg.sigil then
                local g = GC.codexSigil
                local t = S.Own(f:CreateTexture(nil, "BACKGROUND", nil, -3))
                t:SetTexture(K.MEDIA .. "sigil")
                t:SetVertexColor(g[1], g[2], g[3], g[4])
                t:SetSize(R.SIGIL_SIZE * R.SIGIL_SHOW, R.SIGIL_SIZE * R.SIGIL_SHOW)
                t:SetTexCoord(0, R.SIGIL_SHOW, 0, R.SIGIL_SHOW)
                t:SetPoint("BOTTOMRIGHT", list, "BOTTOMRIGHT", 0, 0)
                a.sigil = t
                a.parts[#a.parts + 1] = t
            end
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
    function R.FinishBar(bar)
        if not IsFrame(bar) or finished[bar] or not bar.CreateTexture then return finished[bar] end
        local fill, how = R.BarFill(bar)
        local o = S.BarFinish(bar, fill)
        o.how = how
        finished[bar] = o
        return o
    end

    -- Hervorhebungen des Spiels an einer Zeile (Maus, Auswahl).
    local function FindHighlights(f, out)
        if not f then return end
        for _, t in ipairs(W.Regions(f, "regHl")) do
            local a = AtlasOf(t)
            if a and a:find(R.HIGHLIGHT_ATLAS) then out[#out + 1] = t end
        end
        local bh = f.BackgroundHighlight
        if IsFrame(bh) then
            for _, t in ipairs(W.Regions(bh, "regHl")) do
                if Kind(t) == "Texture" then out[#out + 1] = t end
            end
        end
    end

    function R.Row(row)
        local r = rows[row]
        if r then return r end
        if not row.CreateTexture then return nil end
        local host = ContentOf(row) or row
        if not host.CreateTexture then host = row end
        r = { host = host, bar = R.RowBar(row), hl = {} }
        r.sel = S.Selection(host)
        FindHighlights(host, r.hl)
        if host ~= row then FindHighlights(row, r.hl) end
        -- Nur wenn das Spiel keine eigene Hervorhebung hat: unsere (sonst
        -- doppelt unter der Maus).
        local header = W.ListHeaders[row] or W.Headers[row]
        if #r.hl == 0 and not header then
            if Kind(row) == "Button" then r.hover = S.Hover(row)
            elseif Kind(host) == "Button" then r.hover = S.Hover(host) end
        end
        -- Eintraege voneinander absetzen: Haarlinie unten.
        if not header then r.sep = S.Hairline(host, host, R.SEP_INSET, "BOTTOM", 1) end
        if r.bar then R.FinishBar(r.bar) end
        rows[row] = r
        return r
    end

    -- Gewaehlt ist der Eintrag, dessen Name rechts in der Detailansicht
    -- steht. Ist sie zu, ist keiner markiert - lieber keine Auskunft als
    -- eine geratene.
    function R.Selected(rf)
        local det = R.DetailFrame(rf)
        if not det or not Visible(det) then return nil end
        local d = details[det]
        local t = (d and d.title) or R.DetailTitle(det)
        return t and TextOf(t) or nil
    end

    local function UpdateRows(target, selected)
        local accent = Accent()
        for _, row in ipairs(W.Children(target, "regRows")) do
            if IsFrame(row) and Visible(row) then
                local r = R.Row(row)
                if r then
                    if not r.bar then
                        r.bar = R.RowBar(row)
                        if r.bar then R.FinishBar(r.bar) end
                    end
                    for i = 1, #r.hl do S.Tint(r.hl[i], accent, R.HIGHLIGHT_ALPHA) end
                    if selected and not r.name then r.name = R.RowName(row) end
                    S.SetSelected(r.sel, selected ~= nil and r.name ~= nil and TextOf(r.name) == selected, accent)
                end
            end
        end
    end

    --------------------------------------------------
    -- Detailansicht als Karte
    --------------------------------------------------
    -- Reihenfolge des Spiels, WeintCodex zieht nur Grenzen:
    --   Titel (16 pt; steht er IM Balken, bleibt er, wie er ist)
    --   ---- Linie am Balken (cfg.barLine: darueber oder darunter) ----
    --   Balken (weicher Schatten, Tiefe an der Fuellung)
    --   Beschreibung
    --   ---- Linie mit Raute ----
    --   was folgt: Haekchen (Ruf) oder weitere Zeilen (cfg.tail)
    --   Ende der Karte
    function R.DetailBar(det)
        return ByKeys(det, R.DETAIL_BAR_KEYS) or FindBar(det, 0)
    end

    -- Oberkante/Unterkante der sichtbaren Haekchen, so wie das Spiel sie setzt.
    function R.OptionTop(det)
        local top, bottom
        for _, ch in ipairs(W.Children(det, "regOpt")) do
            if IsFrame(ch) and Kind(ch) == "CheckButton" and Visible(ch) then
                local t, b = Edge(ch, "GetTop"), Edge(ch, "GetBottom")
                if t and (not top or t > top) then top = t end
                if b and (not bottom or b < bottom) then bottom = b end
            end
        end
        return top, bottom
    end

    -- DIE KARTE (6.7.0.3, im Ruf). Haekchen ruecken nach oben, unter den
    -- TEXT der Beschreibung (Oberkante minus Hoehe des Textes):
    --   * nur nach oben, nie tiefer als das Spiel sie setzt;
    --   * alle gemeinsam, Abstaende wie im Spiel (gemessen, bevor etwas
    --     bewegt wurde);
    --   * nur wenn JEDES Haekchen seine Beschriftung selbst traegt und kein
    --     weiterer Knopf in der Detailansicht sichtbar ist;
    --   * nur SetPoint. Schiebt das Spiel sie zurueck, rueckt der naechste
    --     Durchlauf sie wieder hin.
    function R.DetailDescription(det, title)
        for _, key in ipairs(R.DESC_KEYS) do
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
        return (fs and len >= R.DESC_MIN) and fs or nil
    end

    function R.Options(d)
        local det = d.frame
        local left, top = Edge(det, "GetLeft"), Edge(det, "GetTop")
        if not left or not top then return nil end
        local list, why = {}, nil
        for _, ch in ipairs(W.Children(det, "regOptAll")) do
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

    function R.PlaceOptions(d, shift)
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

    -- WAS FOLGT (cfg.tail, 6.7.1.0): alles Sichtbare unter dem Text der
    -- Beschreibung - Schriftzeilen mit Text und Knoepfe, nicht Titel, nicht
    -- Beschreibung, nicht der Balken und was in ihm steht. Nichts davon wird
    -- bewegt; es bekommt nur die Linie mit Raute und den abgesetzten Bereich.
    local function TailScan(d, f, depth, below, top, hi, lo)
        if not f or depth > 2 then return hi, lo end
        for _, r in ipairs(W.Regions(f, "regTail", depth)) do
            if r ~= d.title and r ~= d.desc and Kind(r) == "FontString" and not S.own[r] and TextOf(r) and Visible(r) then
                local t, b = Edge(r, "GetTop"), Edge(r, "GetBottom")
                if t and b and t - top < below then
                    if not hi or t > hi then hi = t end
                    if not lo or b < lo then lo = b end
                end
            end
        end
        for _, ch in ipairs(W.Children(f, "regTail", depth)) do
            if IsFrame(ch) and ch ~= d.bar and Visible(ch) then
                local kind = Kind(ch)
                if kind == "Button" or kind == "CheckButton" then
                    local t, b = Edge(ch, "GetTop"), Edge(ch, "GetBottom")
                    if t and b and t - top < below and ch ~= d.frame.CloseButton then
                        if not hi or t > hi then hi = t end
                        if not lo or b < lo then lo = b end
                    end
                elseif not (d.bar and InTree(ch, d.bar)) then
                    hi, lo = TailScan(d, ch, depth + 1, below, top, hi, lo)
                end
            end
        end
        return hi, lo
    end

    function R.DetailParts(d)
        local det, accent = d.frame, Accent()
        -- Unterer Bereich: leicht vertieft, unter einer Linie mit Raute.
        local c = GC.surfaceSunken
        d.options = S.SoftPanel(det, det, c, c[4], 0, -6)
        d.optLine = S.Under(S.Divider(det, accent, R.OPTION_LINE, 0), -1)
        d.optDot = S.Diamond(det, 5, accent, 0.8, 0)
        d.optDot:SetDrawLayer("BACKGROUND", 0)
        d.optHole = S.Diamond(det, 2, C.surface1, 1, 0)
        d.optHole:SetDrawLayer("BACKGROUND", 1)
        d.optHole:SetPoint("CENTER", d.optDot, "CENTER", 0, 0)
        d.zones = { d.options, d.optLine.l, d.optLine.r, d.optDot, d.optHole }
        for _, t in ipairs(d.zones) do t:Hide() end
    end

    function R.DetailBarParts(d)
        local det = d.frame
        d.barShadow = S.Shadow(det, d.bar, 8, -5)
        d.barLine = S.Under(S.Divider(det, Accent(), R.DETAIL_LINE, 0), -1)
        d.barLine.l:Hide()
        d.barLine.r:Hide()
        R.FinishBar(d.bar)
    end

    -- Flaeche der Karte (und ihr Schatten): oben wie immer, unten bis
    -- `yBottom` (relativ zur Oberkante) oder bis zum Rand.
    function R.PlaceCard(d, yBottom)
        local o, det = d.surface, d.frame
        if not o then return end
        if d.cardBottom == yBottom then return end
        d.cardBottom = yBottom
        local pad = R.DETAIL_PAD
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

    function R.DetailLayout(d)
        local det = d.frame
        local top = Edge(det, "GetTop")
        if not top then return end
        if not d.desc then d.desc = R.DetailDescription(det, d.title) end
        if not d.opts then R.Options(d) end
        local db = DescBottom(d, top)
        -- Ruecken: Ziel knapp unter dem Text der Beschreibung, nie tiefer als
        -- das Spiel die Haekchen setzt.
        local shift = 0
        if d.opts and d.movable then
            if db then
                local up = (db - R.OPTION_SPACE) - d.optFirst
                if up >= R.OPTION_MIN_SHIFT then shift = math.floor(up + 0.5) end
            end
            R.PlaceOptions(d, shift)
        end
        local barTop = d.bar and Edge(d.bar, "GetTop")
        local barBottom = d.bar and Edge(d.bar, "GetBottom")
        local yBar = barTop and (barTop - top) or false
        local yBarB = barBottom and (barBottom - top) or false
        local yOpt, yOptB, lineAt
        if d.opts and d.movable then
            -- Aus der eigenen Rechnung: gleich nach SetPoint misst der
            -- Client noch die alte Lage.
            yOpt, yOptB = d.optFirst + shift, d.optLow + shift
        elseif d.opts then
            local ot, ob = R.OptionTop(det)
            yOpt, yOptB = ot and (ot - top) or false, ob and (ob - top) or false
        elseif cfg.tail and db then
            local hi, lo = TailScan(d, det, 0, db + 2, top, nil, nil)
            yOpt, yOptB = hi and (hi - top) or false, lo and (lo - top) or false
            -- Linie mittig zwischen Beschreibung und dem, was folgt.
            if yOpt then lineAt = math.floor((db + yOpt) / 2 + 0.5) end
        end
        yOpt, yOptB = yOpt or false, yOptB or false
        local dbKey = db and math.floor(db + 0.5) or false
        if d.yBar == yBar and d.yBarB == yBarB and d.yOpt == yOpt and d.yOptB == yOptB and d.db == dbKey then return end
        d.yBar, d.yBarB, d.yOpt, d.yOptB, d.db = yBar, yBarB, yOpt, yOptB, dbKey
        local inset = R.DETAIL_INSET
        if yBar and d.barLine then
            local y = (cfg.barLine == "below" and yBarB) and (yBarB - R.DETAIL_GAP) or (yBar + R.DETAIL_GAP)
            S.PlaceTop(d.barLine, det, inset, y)
            d.barLineY = y
        end
        if d.barLine then ShowZone(yBar and true or false, d.barLine.l, d.barLine.r) end
        local yLine = yOpt and (lineAt or (yOpt + R.OPTION_GAP)) or false
        if yLine then
            S.PlaceTop(d.optLine, det, inset, yLine)
            d.optDot:ClearAllPoints()
            d.optDot:SetPoint("CENTER", det, "TOP", 0, yLine)
            local moved = (d.shift or 0) > 0
            local closed = (moved or cfg.compact) and yOptB
            S.PlaceBand(d.options, det, 2, yLine - 1, closed and (yOptB - R.CARD_BOTTOM + 4) or nil)
        end
        ShowZone(yLine and true or false, d.optLine.l, d.optLine.r, d.optDot, d.optHole, d.options)
        -- Ende der Karte: unter geruckten Haekchen; mit cfg.compact unter dem
        -- tiefsten Inhalt (was folgt, sonst Beschreibung, sonst Balken).
        local bottom
        if (d.shift or 0) > 0 and yOptB then
            bottom = yOptB
        elseif cfg.compact then
            bottom = yOptB or db or yBarB or nil
            if bottom and db and db < bottom then bottom = db end
        end
        R.PlaceCard(d, bottom and (bottom - R.CARD_BOTTOM) or nil)
    end

    -- Im Fenster: dieselbe angehobene Flaeche wie die Liste (ein Bereich
    -- der Oberflaeche), oben eine feine Kante in der Klassenfarbe. Frei am
    -- Bildschirm (anderer Client): eine deckende Tafel.
    function R.Detail(f, rf)
        local det = R.DetailFrame(rf)
        if not det or not Visible(det) then return nil end
        local d = details[det]
        if not d then
            d = { frame = det }
            S.Scope(det, R.STYLE)
            for _, key in ipairs(R.DETAIL_DECOR) do
                local part = det[key]
                if IsFrame(part) then W.HideDecor(part) end
            end
            d.inTree = InTree(det, f)
            if d.inTree then
                d.surface = R.Surface(det, det, R.DETAIL_PAD, nil, -7, GC.surfaceDetail)
            else
                d.panel = S.Panel(det)
            end
            d.line = S.Divider(det, Accent(), R.DETAIL_LINE, 1)
            d.line.l:SetDrawLayer("BACKGROUND", -2)
            d.line.r:SetDrawLayer("BACKGROUND", -2)
            S.PlaceTop(d.line, det, R.DETAIL_INSET)
            d.title = R.DetailTitle(det)
            d.styledTitle = d.title and true or false
            R.DetailParts(d)
            details[det] = d
        end
        if not d.bar then
            d.bar = R.DetailBar(det)
            if d.bar then R.DetailBarParts(d) end
        end
        -- Titel groesser: einmal - und nicht, wenn er IM Balken steht (Name
        -- auf dem Fortschritt): 16 pt passen nicht in einen Balken.
        if d.styledTitle and not d.titleDone then
            d.titleDone = true
            if not (d.bar and InTree(d.title, d.bar)) then S.Title(d.title, R.DETAIL_TITLE, C.textBright) end
        end
        R.DetailLayout(d)
        if not d.inTree then
            W.HideByAtlas(det)
            W.Grey(det)
        end
        return d
    end

    --------------------------------------------------
    -- Ein Durchlauf (aus W.Inner, Charakterfenster offen)
    --------------------------------------------------
    function R.Update(f)
        local rf = R.Frame()
        if not rf then return nil end
        local a = atmos[rf]
        if not Visible(rf) then
            if a then ShowAtmos(a, false) end
            return nil
        end
        S.Scope(rf, R.STYLE)
        a = R.Atmosphere(f, rf)
        ShowAtmos(a, true)
        R.state.runs = R.state.runs + 1
        local selected = R.Selected(rf)
        R.state.selected = selected
        local list = R.List(rf)
        if list then UpdateRows(R.Target(list), selected) end
        R.Detail(f, rf)
        return a
    end

    --------------------------------------------------
    -- /wcui fenster
    --------------------------------------------------
    function R.Report(f, out)
        local rf = R.Frame()
        if not rf or not Visible(rf) then return out end
        local L = R.LABEL
        local list = R.List(rf)
        local n, heads, bars, named, hls, kind, how = 0, 0, 0, 0, 0, nil, nil
        if list then
            for _, row in ipairs(W.Children(R.Target(list), "regReport")) do
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
                    if R.RowName(row) then named = named + 1 end
                end
            end
        end
        out[#out + 1] = string.format("   %s (Stil %s): Liste %s, %d Zeilen (%d Kopfzeilen, %d mit Balken, %d mit Namen)",
            L, R.STYLE.name, list and "gefunden" or "FEHLT", n, heads, bars, named)
        out[#out + 1] = string.format("   %s, Balken: %s, Füllung %s · Hervorhebungen des Spiels getönt: %d",
            L, kind or "–", how or "–", hls)
        out[#out + 1] = string.format("   %s, gewählt: %s", L,
            R.state.selected and ("„" .. R.state.selected .. "“") or "keine (Detailansicht zu)")
        local det = R.DetailFrame(rf)
        local d = det and details[det]
        if not det then
            out[#out + 1] = string.format("   %s, Detailansicht: nicht gefunden", L)
        elseif not d then
            out[#out + 1] = string.format("   %s, Detailansicht: %s", L, Visible(det) and "offen, noch nicht gestaltet" or "zu")
        else
            local shown = 0
            for _, key in ipairs(R.DETAIL_DECOR) do
                local part = det[key]
                if IsFrame(part) then
                    for _, r in ipairs(W.Regions(part, "regReport")) do
                        if Kind(r) == "Texture" and not S.own[r] and K.Plain(r:GetAlpha()) ~= 0 then shown = shown + 1 end
                    end
                end
            end
            local dname = (det.GetDebugName and det:GetDebugName()) or (det.GetName and det:GetName()) or "?"
            out[#out + 1] = string.format("   %s, Detailansicht: %s (%s), Titel %s%s, Rahmen des Spiels: %d Bilder noch sichtbar",
                L, d.inTree and "Fläche im Fenster" or "Tafel, frei", tostring(K.Plain(dname) or "?"),
                d.title and ("„" .. (TextOf(d.title) or "?") .. "“") or "FEHLT",
                (d.title and d.bar and InTree(d.title, d.bar)) and " (im Balken)" or "", shown)
            local opts = 0
            for _, ch in ipairs(W.Children(det, "regReport")) do
                if IsFrame(ch) and Kind(ch) == "CheckButton" then opts = opts + 1 end
            end
            out[#out + 1] = string.format("   %s, Karte: Balken %s, Beschreibung %s, Optionen %d Häkchen, Bereiche: Balken %s, Optionen %s",
                L, d.bar and (Kind(d.bar) or "?") or "FEHLT", d.desc and "gefunden" or "FEHLT", opts,
                d.yBar and string.format("%.0f", d.yBar) or "–",
                d.yOpt and string.format("%.0f", d.yOpt) or "–")
            local moved
            if cfg.tail and not d.opts then
                moved = d.yOpt and string.format("darunter abgesetzt ab %.0f", d.yOpt) or "nichts unter der Beschreibung"
            elseif not d.opts then moved = "nicht gerückt (keine Häkchen vermessen)"
            elseif not d.movable then moved = "nicht gerückt (" .. tostring(d.why) .. ")"
            elseif (d.shift or 0) > 0 then moved = string.format("um %d px nach oben gerückt, Karte endet darunter", d.shift)
            else moved = "an ihrem Platz (Beschreibung lang oder unbekannt)" end
            out[#out + 1] = string.format("   %s, Optionen: %s", L, moved)
        end
        return out
    end

    return R
end
