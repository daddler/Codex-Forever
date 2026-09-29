--------------------------------------------------
-- WeintCodex :: Oberflaeche - Ruf (6.7.0.0)
--------------------------------------------------
-- Das erste Fenster im Stil S.CALM (ui/style.lua) - das Muster fuer alle
-- informationslastigen Fenster, die folgen. Der Reiter "Ruf" im
-- Charakterfenster (ReputationFrame) und seine Detailansicht rechts.
--
-- ALLES BLEIBT, WAS DAS SPIEL ZEIGT: Liste, Gruppen, Fraktionen, Balken
-- mit Farbe und Text, Auswahl, Detailansicht mit Beschreibung und
-- Haekchen (Krieg, inaktiv, beobachten), Filter, Bildlauf. Dieses Modul
-- legt nur eigene Flaechen daneben und dahinter und setzt Schrift und
-- Deckkraft - kein SetText, kein Feld an einem Rahmen des Spiels, keine
-- Zeile wird versteckt oder verschoben.
--
-- Was es tut, von hinten nach vorn:
--   Atmosphaere   auf dem Charakterfenster selbst (unter allem, was das
--                 Spiel zeichnet - nie ueber Text): weiche Randabdunklung,
--                 ein Hauch Gold von oben, ein dunkler Grund mit weichem
--                 Rand unter der Liste. Nur solange der Ruf offen ist.
--   Gruppen       Kopfzeilen der Liste als Zeile mit Raute und Linie in
--                 Gold (W.ListHeader), Einrueckung des Spiels bleibt.
--   Balken        dunklere Bahn, Schatten und Lichtkante an der Fuellung;
--                 Farbe und Text der Stufe bleiben die des Spiels.
--   Auswahl       die Fraktion, die rechts in der Detailansicht steht:
--                 Strich und Hauch in Gold. Unter der Maus: heller.
--   Detail        eigene Tafel statt des Dialograhmens, Titel groesser,
--                 darunter eine Trennlinie in Gold.
--
-- WIE DIESER CLIENT DEN RUF BAUT, IST NUR ZUM TEIL GEMESSEN (6.6.2.9:
-- Liste in ReputationFrame.ScrollBox, Kopfzeilen, Balken). Zeilen,
-- Namen, Balken und Detailansicht werden deshalb ueber mehrere Wege
-- gesucht (Schluessel des Quelltexts, dann nach Art), und /wcui fenster
-- ueber dem Fenster sagt, was gefunden wurde.
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
RP.STYLE = S.CALM

-- Atmosphaere: "subtil" (Ruf steht bei Berufen und Abzeichen, nicht beim
-- Charakter). Zahlen klein mit Absicht - sie sollen nicht auffallen.
RP.VIGNETTE, RP.VIGNETTE_SIZE = 0.30, 44
RP.LIGHT, RP.LIGHT_HEIGHT = 0.045, 120
RP.WELL_PAD = 8
-- Detailansicht.
RP.DETAIL_TITLE = 14
RP.DETAIL_DIVIDER = 0.6
RP.DETAIL_INSET = 14
RP.DETAIL_DECOR = { "Border", "NineSlice", "Bg", "Background" }
RP.TITLE_KEYS = { "Title", "FactionName", "Name" }
-- Zeilen: Name und Balken (Quelltext des Spiels 11.x/12.x).
RP.NAME_KEYS = { "Name", "Title", "Label" }
RP.BAR_KEYS = { "ReputationBar", "StatusBar", "Bar" }

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

local function WidthOf(r)
    local ok, w = pcall(r.GetWidth, r)
    w = ok and K.Plain(w) or nil
    return type(w) == "number" and w or 0
end

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

-- Die Zeile selbst oder ihr Inhalt (.Content im Quelltext des Spiels).
local function ContentOf(row)
    local c = row.Content
    return IsFrame(c) and c or nil
end

local function ByKeys(f, keys, kind)
    if not f then return nil end
    for _, key in ipairs(keys) do
        local t = f[key]
        if IsFrame(t) and Kind(t) == kind then return t end
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

function RP.RowBar(row)
    local c = ContentOf(row)
    return ByKeys(c, RP.BAR_KEYS, "StatusBar") or ByKeys(row, RP.BAR_KEYS, "StatusBar")
        or FirstChild(row, "StatusBar", 0)
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
    local accent = S.Accent(RP.STYLE.accent)
    local v = S.Vignette(f, rf, RP.VIGNETTE, RP.VIGNETTE_SIZE, -6)
    for _, side in ipairs(S.SIDES) do a.parts[#a.parts + 1] = v[side] end
    a.vignette = v
    a.light = S.TopLight(f, rf, accent, RP.LIGHT, RP.LIGHT_HEIGHT, -5)
    a.parts[#a.parts + 1] = a.light
    local list = RP.List(rf)
    if list then
        local w = GC.panelWell
        a.well = S.SoftPanel(f, list, w, w[4], RP.WELL_PAD, -4)
        a.parts[#a.parts + 1] = a.well
    end
    atmos[rf] = a
    -- Sofort mit dem Reiter, nicht erst mit dem naechsten Takt: sonst
    -- laege der Grund der Liste einen Augenblick unter der Figur.
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
    finished[bar] = S.BarFinish(bar)
    return finished[bar]
end

function RP.Row(row)
    local r = rows[row]
    if r then return r end
    if not row.CreateTexture then return nil end
    local host = ContentOf(row) or row
    if not host.CreateTexture then host = row end
    r = { host = host, bar = RP.RowBar(row) }
    r.sel = S.Selection(host)
    local header = W.ListHeaders[row] or W.Headers[row]
    if not header then
        for _, b in ipairs({ row, host }) do
            if Kind(b) == "Button" then r.hover = S.Hover(b) break end
        end
    end
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

local function UpdateRows(rf, target, selected)
    local accent = S.Accent(RP.STYLE.accent)
    for _, row in ipairs(W.Children(target, "repRows")) do
        if IsFrame(row) and Visible(row) then
            local r = RP.Row(row)
            if r then
                -- Balken, die das Spiel spaeter in eine Zeile legt.
                if not r.bar then
                    r.bar = RP.RowBar(row)
                    if r.bar then RP.FinishBar(r.bar) end
                end
                if selected and not r.name then r.name = RP.RowName(row) end
                S.SetSelected(r.sel, selected ~= nil and r.name ~= nil and TextOf(r.name) == selected, accent)
            end
        end
    end
end

--------------------------------------------------
-- Detailansicht
--------------------------------------------------
function RP.Detail(f, rf)
    local det = RP.DetailFrame(rf)
    if not det or not Visible(det) then return nil end
    local d = details[det]
    if not d then
        d = { frame = det, hidden = 0 }
        S.Scope(det, RP.STYLE)
        for _, key in ipairs(RP.DETAIL_DECOR) do
            local part = det[key]
            if IsFrame(part) then W.HideDecor(part) end
        end
        d.panel = S.Panel(det)
        d.title = RP.DetailTitle(det)
        if d.title then
            S.Title(d.title, RP.DETAIL_TITLE, C.textBright)
            d.divider = S.Divider(det, S.Accent(RP.STYLE.accent), RP.DETAIL_DIVIDER)
        end
        d.inTree = RP.InTree(det, f)
        details[det] = d
    end
    if d.divider then
        local w = WidthOf(det) - 2 * RP.DETAIL_INSET
        S.PlaceDivider(d.divider, d.title, w > 40 and w or 180, 6)
    end
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
    local open = Visible(rf)
    if not open then
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
    if list then UpdateRows(rf, RP.Target(list), selected) end
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
    local n, heads, bars, named = 0, 0, 0, 0
    if list then
        for _, row in ipairs(W.Children(RP.Target(list), "repReport")) do
            if IsFrame(row) and Visible(row) then
                n = n + 1
                if W.ListHeaders[row] or W.Headers[row] then heads = heads + 1 end
                if rows[row] and rows[row].bar then bars = bars + 1 end
                if RP.RowName(row) then named = named + 1 end
            end
        end
    end
    out[#out + 1] = string.format("   Ruf (Stil %s, Akzent Gold): Liste %s, %d Zeilen (%d Kopfzeilen, %d mit Balken, %d mit Namen)",
        RP.STYLE.name, list and "gefunden" or "FEHLT", n, heads, bars, named)
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
        out[#out + 1] = string.format("   Ruf, Detailansicht: gestaltet, %s, Titel %s, Rahmen des Spiels: %d Bilder noch sichtbar",
            d.inTree and "im Fenster" or "frei", d.title and ("„" .. (TextOf(d.title) or "?") .. "“") or "FEHLT", shown)
    end
    return out
end
