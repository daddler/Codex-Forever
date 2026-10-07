--------------------------------------------------
-- WeintCodex :: Geistheiler und Uebergaenge auf der Weltkarte
--------------------------------------------------
-- Seit 6.21.0.0 (Beta-Test: "dort sind auch die Geistheiler (gruener Punkt)
-- und die gruenen Pfeile eingezeichnet, um zu sehen, wie man zum naechsten
-- Gebiet kommt. Das waere cool, wenn das auch mit reinkommt"). Seite
-- "Karte" im Komfort, wie die Eingaenge (ui/mapentrances.lua) von Haus aus
-- AUS, geht ohne Oberflaeche.
--
-- WOHER: data/mapmarks.lua (erzeugt von .github/scripts/import_mapmarks.py)
-- - nur Lagen, wie die Kartenteile zum Aufdecken. Der Name des Gebiets, in
-- das ein Pfeil fuehrt, kommt vom Client (C_Map.GetMapInfo): in der Sprache
-- des Spielers, und nie ein Name, den der Client nicht kennt - ohne Namen
-- kein Pfeil.
--
-- WIE: dieselben Regeln wie die Eingaenge - eigene Rahmen auf der Flaeche
-- der Karte (QM.Canvas), Kehrwert des Zooms, nie AddDataProvider, nie
-- SetMapID (deshalb fuehrt ein Klick auf den Pfeil nicht hinueber). Nur auf
-- der Karte einer Zone: auf dem Kontinent waeren es ueber hundert Punkte.
--
-- FARBE: Geistheiler und Pfeile in einem hellen Gruen der Spielwelt
-- (GameColors.mapMark, seit 6.21.0.1; bis dahin "friendly"), nicht der
-- Akzent - mit hellem Rand und dunklem Hof.
--------------------------------------------------

local K = WeintCodex.UIKit
local C = WeintCodex.Colors
local GC = WeintCodex.GameColors
local KEY = "comfort"

WeintCodex.UIMapMarks = {}
local MK = WeintCodex.UIMapMarks

MK.DEFAULTS = {
    mapSpirit    = false,    -- Geistheiler
    mapCrossings = false,    -- Uebergaenge in andere Gebiete
}

-- 6.21.0.1 (Beta-Test: "zwar drin, aber nicht gut zu sehen"): groesser,
-- heller (GameColors.mapMark), mit hellem Rand und dunklem Hof - auf dem
-- Gruen und Braun der Karte hob sich das Gruen allein nicht ab.
MK.SPIRIT = 20       -- Groesse des Punkts (Bildpunkte, bei jedem Zoom)
MK.ARROW = 30        -- Groesse des Pfeils
MK.TICK = 0.05

function MK.Wants(kind)
    return K.IsActive(KEY) and K.Get(KEY, kind == "spirit" and "mapSpirit" or "mapCrossings") and true or false
end
function MK.Active() return MK.Wants("spirit") or MK.Wants("crossing") end

local function QM() return WeintCodex.QuestMap end
local function Data() return WeintCodex.MapMarksData or {} end

-- Name einer Karte vom Client, oder nil.
local names = {}
function MK.MapName(mapID)
    if names[mapID] ~= nil then return names[mapID] or nil end
    local cm = _G.C_Map
    local name
    if cm and cm.GetMapInfo then
        local ok, info = pcall(cm.GetMapInfo, mapID)
        name = ok and type(info) == "table" and K.Plain(info.name) or nil
    end
    if type(name) ~= "string" or name == "" then name = nil end
    names[mapID] = name or false
    return name
end

-- { { kind, x, y, rot, to }, ... } fuer diese Karte; gemerkt je Karte.
local forMap = {}

function MK.ForMap(mapID)
    if type(mapID) ~= "number" then return {} end
    local cached = forMap[mapID]
    if cached then return cached end
    local out = {}
    local d = Data()
    if MK.Wants("spirit") then
        local list = d.spirit and d.spirit[mapID]
        for i = 1, list and #list or 0, 2 do
            out[#out + 1] = { kind = "spirit", x = list[i], y = list[i + 1] }
        end
    end
    if MK.Wants("crossing") then
        local list = d.crossings and d.crossings[mapID]
        for i = 1, list and #list or 0, 4 do
            local to = list[i + 3]
            if MK.MapName(to) then
                out[#out + 1] = { kind = "crossing", x = list[i], y = list[i + 1], rot = list[i + 2], to = to }
            end
        end
    end
    forMap[mapID] = out
    return out
end

function MK.Forget()
    for k in pairs(forMap) do forMap[k] = nil end
    for k in pairs(names) do names[k] = nil end
end

--------------------------------------------------
-- Symbole
--------------------------------------------------

local pins = {}
MK.pins = pins

local function Tooltip(self)
    local gt = _G.GameTooltip
    local e = self.entry
    if not (gt and e) then return end
    gt:SetOwner(self, "ANCHOR_RIGHT")
    local t = C.textBright
    if e.kind == "spirit" then
        gt:SetText("Geistheiler", t[1], t[2], t[3])
    else
        gt:SetText("Nach " .. (MK.MapName(e.to) or "?"), t[1], t[2], t[3])
    end
    local m = C.textMuted
    gt:AddLine("Wissensstand aus der Beta – unbestätigt.", m[1], m[2], m[3], true)
    gt:Show()
end

-- Eine Lage eines Symbols: Bild, Farbe, wie weit ueber den Rahmen hinaus
-- (negativ: nach innen).
local function Layer(p, tex, sub, c, a, out)
    local t = p:CreateTexture(nil, "ARTWORK", nil, sub)
    t:SetTexture(tex)
    t:SetPoint("TOPLEFT", p, "TOPLEFT", -out, out)
    t:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", out, -out)
    t:SetVertexColor(c[1], c[2], c[3], a)
    return t
end

local BLACK = { 0, 0, 0 }

local function NewPin(canvas)
    local p = CreateFrame("Frame", nil, canvas)
    p:EnableMouse(true)
    local g, w = GC.mapMark, C.textBright
    local disc, arrow = K.MEDIA .. "disc", K.ARROW_TEXTURE
    -- Punkt: dunkler Hof, heller Ring, gruener Kern (eigene Bilder).
    p.spirit = { Layer(p, disc, 1, BLACK, 0.6, 3), Layer(p, disc, 2, w, 1, 0), Layer(p, disc, 3, g, 1, -3) }
    -- Pfeil: dunkler Schatten, heller Rand, gruener Pfeil.
    p.crossing = { Layer(p, arrow, 1, BLACK, 0.9, 4), Layer(p, arrow, 2, w, 1, 2), Layer(p, arrow, 3, g, 1, 0) }
    p.rim, p.dot = p.spirit[2], p.spirit[3]
    p.shade, p.arrow = p.crossing[1], p.crossing[3]
    p:SetScript("OnEnter", Tooltip)
    p:SetScript("OnLeave", function() if _G.GameTooltip then _G.GameTooltip:Hide() end end)
    p:Hide()
    return p
end

-- Ein Symbol fuer einen Eintrag einrichten (nur, wenn es vorher ein anderes war).
local function Dress(p, e)
    if p.entry == e then return end
    p.entry = e
    local spirit = e.kind == "spirit"
    local size = spirit and MK.SPIRIT or MK.ARROW
    p:SetSize(size, size)
    for _, t in ipairs(p.spirit) do t:SetShown(spirit) end
    for _, t in ipairs(p.crossing) do t:SetShown(not spirit) end
    if not spirit then
        local r = tonumber(e.rot) or 0
        for _, t in ipairs(p.crossing) do
            if t.SetRotation then t:SetRotation(r) end
        end
    end
end

local shownMap, shownCount = nil, 0

local function HideAll(from)
    for i = from or 1, #pins do pins[i]:Hide() end
end

function MK.Place()
    local qm = QM()
    local wm = _G.WorldMapFrame
    if not (MK.Active() and qm and type(wm) == "table" and wm.IsShown and wm:IsShown()) then
        HideAll()
        shownMap, shownCount = nil, 0
        return 0
    end
    local mapID = qm.CurrentMap and qm.CurrentMap()
    local canvas = qm.Canvas and qm.Canvas()
    if not (mapID and canvas) then
        HideAll()
        return 0
    end
    local list = MK.ForMap(mapID)
    local w, h = K.Plain(canvas:GetWidth()), K.Plain(canvas:GetHeight())
    if type(w) ~= "number" or type(h) ~= "number" or w <= 1 or h <= 1 then return 0 end
    local s = 1
    local cs = K.Plain(canvas.GetEffectiveScale and canvas:GetEffectiveScale())
    local ms = K.Plain(wm.GetEffectiveScale and wm:GetEffectiveScale())
    if type(cs) == "number" and type(ms) == "number" and cs > 0 and ms > 0 then s = cs / ms end
    -- Unter den Eingaengen (ui/mapentrances.lua: Flaeche + 1500).
    local lvl = K.Plain(canvas.GetFrameLevel and canvas:GetFrameLevel())
    lvl = math.min(7990, (type(lvl) == "number" and lvl or 0) + 1490)
    for i, e in ipairs(list) do
        local p = pins[i]
        if not p then
            p = NewPin(canvas)
            pins[i] = p
        end
        if p:GetParent() ~= canvas then p:SetParent(canvas) end
        Dress(p, e)
        p:SetScale(1 / s)
        p:SetFrameLevel(lvl)
        p:ClearAllPoints()
        p:SetPoint("CENTER", canvas, "TOPLEFT", w * e.x * s, -h * e.y * s)
        p:Show()
    end
    HideAll(#list + 1)
    shownMap, shownCount = mapID, #list
    return #list
end

--------------------------------------------------
-- Taktgeber (Kind der Weltkarte)
--------------------------------------------------

local driver
local function EnsureDriver()
    if driver then return driver end
    local wm = _G.WorldMapFrame
    if type(wm) ~= "table" then return nil end
    driver = CreateFrame("Frame", nil, wm)
    local acc = 0
    driver:SetScript("OnUpdate", K.Measured("Karte: Geistheiler, Übergänge", function(_, el)
        acc = acc + (el or 0)
        if acc < MK.TICK then return end
        acc = 0
        MK.Place()
    end))
    driver:SetScript("OnHide", function() HideAll() end)
    MK.driver = driver
    return driver
end
MK.EnsureDriver = EnsureDriver

local ev = CreateFrame("Frame")
ev:SetScript("OnEvent", function(_, event, name)
    if event == "ADDON_LOADED" and name ~= "Blizzard_WorldMap" then return end
    if MK.Active() then EnsureDriver() end
end)

local function Apply()
    MK.Forget()
    -- Ein Symbol, das vorher etwas anderes war, wird neu eingerichtet.
    for _, p in ipairs(pins) do p.entry = nil end
    if MK.Active() then
        pcall(ev.RegisterEvent, ev, "ADDON_LOADED")
        EnsureDriver()
        MK.Place()
    else
        pcall(ev.UnregisterEvent, ev, "ADDON_LOADED")
        HideAll()
        shownMap, shownCount = nil, 0
    end
end
MK.Apply = Apply

--------------------------------------------------
-- Bericht (/wcui prüfen) und Seite
--------------------------------------------------

function MK.StatusLines()
    local d = Data()
    local ns, na, ms, ma = 0, 0, 0, 0
    for _, l in pairs(d.spirit or {}) do ns, ms = ns + #l / 2, ms + 1 end
    for _, l in pairs(d.crossings or {}) do na, ma = na + #l / 4, ma + 1 end
    local out = {}
    out[#out + 1] = string.format("Geistheiler im Bestand: %d auf %d Karten · Übergänge: %d auf %d Karten", ns, ms, na, ma)
    if shownMap then
        out[#out + 1] = "Zuletzt gezeigt: " .. shownCount .. " auf Karte " .. shownMap
    end
    return out
end

function MK.BuildRows(B)
    B:Row({ type = "toggle", label = "Geistheiler", key = "mapSpirit",
            description = "Ein grüner Punkt, wo ein Geistheiler steht." },
          { type = "toggle", label = "Übergänge in andere Gebiete", key = "mapCrossings",
            description = "Ein grüner Pfeil, wo der Weg ins nächste Gebiet führt. Maus darauf: wohin." })
end

local mod = K.Module(KEY)
if mod then
    for k, v in pairs(MK.DEFAULTS) do
        if mod.defaults[k] == nil then mod.defaults[k] = v end
    end
end

K.Listen(function(kind, key)
    if (kind == "active" or kind == "setting") and key == KEY then Apply() end
end)
