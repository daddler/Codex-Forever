--------------------------------------------------
-- WeintCodex :: Weltkarte aufdecken
--------------------------------------------------
-- Seit 6.20.0.0 (Wunsch des Spielers: "optional die Karte komplett
-- aufgedeckt. Wo ich selbst noch nicht war, kann es etwas abgedunkelt
-- sein, damit ich weiss, wo ich noch hin muss"). Auf der Seite "Karte" im
-- Komfort (ui/mapentrances.lua), ab Werk aus; geht ohne Oberflaeche.
--
-- WARUM DATEN: die Karte einer Zone ist ein Grundbild plus ein Bild je
-- Teilgebiet. Der Client gibt Addons nur die schon erkundeten Teile
-- heraus (C_MapExplorationInfo.GetExploredMapTextures). Die ganze Liste
-- steht in data/mapreveal.lua - ERZEUGT aus der Tabelle "Reveal Data for
-- Forever" des Addons Leatrix Maps (nur die Daten, kein Code; siehe
-- .github/scripts/import_mapreveal.py).
--
-- GEGENPROBE IM SPIEL: bevor WeintCodex eine Zone aufdeckt, haelt es die
-- erkundeten Teile, die der Client nennt, gegen die Tabelle. Fehlt dort
-- einer oder traegt er andere Bilder, passt die Tabelle nicht zu dieser
-- Zone - dann bleibt sie, wie sie ist (ein falsches Bild zeichnet das
-- Spiel als gruene Flaeche). Ohne erkundeten Teil laesst sich nichts
-- pruefen; die Zone wird aufgedeckt und als "ungeprueft" gezaehlt.
-- /wcui pruefen nennt beides.
--
-- WIE: eigene Bilder in einem eigenen Rahmen auf der Flaeche der Karte
-- (wie die Marke und die Eingaenge), auf der Ebene der erkundeten Teile
-- des Spiels; gezeichnet werden nur die UNerkundeten - die erkundeten
-- zeichnet das Spiel selbst. Nie in Rahmen des Spiels geschrieben.
-- Leatrix Maps selbst geladen: es deckt auf, WeintCodex nicht (wie
-- MoveAny beim Verschieben der Fenster).
--------------------------------------------------

local K = WeintCodex.UIKit
local KEY = "comfort"

WeintCodex.UIMapReveal = {}
local MR = WeintCodex.UIMapReveal

MR.DEFAULTS = {
    mapReveal     = false,   -- ganze Karte zeigen
    mapRevealTint = true,    -- Unerkundetes abdunkeln
}

MR.TINT = 0.45     -- Helligkeit des Unerkundeten (abgedunkelt)
MR.TILE = 256      -- Kantenlaenge einer Kachel in den Spieldaten
MR.TICK = 0.1

local SETTING = { tint = "mapRevealTint" }
local function Get(k) return K.Get(KEY, SETTING[k] or k) end

-- Leatrix Maps hat Vorrang: zwei Aufdecker zeichnen alles doppelt.
function MR.Other()
    local f = (_G.C_AddOns and _G.C_AddOns.IsAddOnLoaded) or _G.IsAddOnLoaded
    if type(f) ~= "function" then return false end
    local ok, loaded = pcall(f, "Leatrix_Maps")
    return ok and K.Bool(loaded, false) or false
end

function MR.Active()
    return K.IsActive(KEY) and K.Get(KEY, "mapReveal") and not MR.Other() and true or false
end

--------------------------------------------------
-- Bestand
--------------------------------------------------

local data
function MR.Data()
    if data then return data end
    local src = WeintCodex.MapRevealData
    data = (src and type(src.build) == "function") and src.build() or {}
    return data
end

local function Key(w, h, x, y) return w .. ":" .. h .. ":" .. x .. ":" .. y end

function MR.ArtID(mapID)
    local cm = _G.C_Map
    if not (cm and cm.GetMapArtID) then return nil end
    local ok, id = pcall(cm.GetMapArtID, mapID)
    id = ok and K.Plain(id) or nil
    return type(id) == "number" and id or nil
end

-- Was der Client als erkundet nennt: [Key] = { Bilder } (oder nil, wenn
-- er nichts sagt).
function MR.Explored(mapID)
    local ex = _G.C_MapExplorationInfo
    if not (ex and type(ex.GetExploredMapTextures) == "function") then return nil end
    local ok, list = pcall(ex.GetExploredMapTextures, mapID)
    if not ok or type(list) ~= "table" then return nil end
    local out = {}
    for _, t in ipairs(list) do
        local w, h = K.Plain(t.textureWidth), K.Plain(t.textureHeight)
        local x, y = K.Plain(t.offsetX), K.Plain(t.offsetY)
        if type(w) == "number" and type(h) == "number" and type(x) == "number" and type(y) == "number" then
            out[Key(w, h, x, y)] = t.fileDataIDs or {}
        end
    end
    return out
end

-- Pruefung einer Zone, gemerkt bis sich etwas aendert:
-- { status = "fits"|"unchecked"|"mismatch"|"nodata", missing = { Teile }, explored = n, total = n }
local checked = {}
local dirty = true    -- neu zeichnen beim naechsten Takt

function MR.Check(mapID)
    if type(mapID) ~= "number" then return { status = "nodata", missing = {} } end
    local c = checked[mapID]
    if c then return c end
    local zone = MR.Data()[MR.ArtID(mapID) or -1]
    if not zone then
        c = { status = "nodata", missing = {} }
        checked[mapID] = c
        return c
    end
    local explored = MR.Explored(mapID) or {}
    local known = {}
    for _, p in ipairs(zone) do known[Key(p[1], p[2], p[3], p[4])] = p end
    local n, bad = 0, 0
    for key, ids in pairs(explored) do
        n = n + 1
        local p = known[key]
        if not p then
            bad = bad + 1
        else
            for i, id in ipairs(p[5]) do
                local got = K.Plain(ids[i])
                if got ~= id then bad = bad + 1 break end
            end
        end
    end
    local missing = {}
    for _, p in ipairs(zone) do
        if not explored[Key(p[1], p[2], p[3], p[4])] then missing[#missing + 1] = p end
    end
    local status = bad > 0 and "mismatch" or (n > 0 and "fits" or "unchecked")
    c = { status = status, missing = status ~= "mismatch" and missing or {}, explored = n, total = #zone, bad = bad, name = zone.name }
    checked[mapID] = c
    return c
end

function MR.Forget()
    for k in pairs(checked) do checked[k] = nil end
    dirty = true
end

--------------------------------------------------
-- Zeichnen
--------------------------------------------------

local layer, drawnMap, drawnCanvas
local tex = {}
MR.tex = tex

local function Pow2(n)
    local p = 1
    while p < n do p = p * 2 end
    return p
end

-- Die Ebene der erkundeten Teile des Spiels: darauf liegen unsere. Nur
-- gelesen (GetChildren, ein Feld, GetFrameLevel), nie geschrieben.
local function GameLevel(canvas)
    if not canvas.GetChildren then return nil end
    local kids = { canvas:GetChildren() }
    for _, f in ipairs(kids) do
        if type(f) == "table" and f.pinTemplate == "MapExplorationPinTemplate" and f.GetFrameLevel then
            local l = K.Plain(f:GetFrameLevel())
            if type(l) == "number" then return l end
        end
    end
    return nil
end

local function HideFrom(i)
    for n = i, #tex do tex[n]:Hide() end
end

-- Zeichnet die unerkundeten Teile der Zone, die offen ist. Gibt die Zahl
-- der Kacheln zurueck.
function MR.Draw(mapID, canvas)
    if not layer or layer:GetParent() ~= canvas then
        if not layer then
            layer = CreateFrame("Frame", nil, canvas)
            MR.layer = layer
        else
            layer:SetParent(canvas)
        end
        layer:ClearAllPoints()
        layer:SetAllPoints(canvas)
    end
    local lvl = GameLevel(canvas)
    MR.levelKnown = lvl ~= nil
    if not lvl then
        local cl = K.Plain(canvas.GetFrameLevel and canvas:GetFrameLevel())
        lvl = (type(cl) == "number" and cl or 0) + 1
    end
    layer:SetFrameLevel(lvl)
    local c = MR.Check(mapID)
    local shade = Get("tint") and MR.TINT or 1
    local n = 0
    for _, p in ipairs(c.missing) do
        local w, h, x, y, ids = p[1], p[2], p[3], p[4], p[5]
        local wide, tall = math.ceil(w / MR.TILE), math.ceil(h / MR.TILE)
        for j = 0, tall - 1 do
            local ph = (j < tall - 1) and MR.TILE or (h - MR.TILE * (tall - 1))
            local fh = (j < tall - 1) and MR.TILE or Pow2(ph)
            for i = 0, wide - 1 do
                local pw = (i < wide - 1) and MR.TILE or (w - MR.TILE * (wide - 1))
                local fw = (i < wide - 1) and MR.TILE or Pow2(pw)
                n = n + 1
                local t = tex[n]
                if not t then
                    t = layer:CreateTexture(nil, "ARTWORK")
                    if t.SetSnapToPixelGrid then t:SetSnapToPixelGrid(false) end
                    if t.SetTexelSnappingBias then t:SetTexelSnappingBias(0) end
                    tex[n] = t
                end
                t:SetTexture(ids[j * wide + i + 1])
                t:SetSize(pw, ph)
                t:SetTexCoord(0, pw / fw, 0, ph / fh)
                t:ClearAllPoints()
                t:SetPoint("TOPLEFT", layer, "TOPLEFT", x + MR.TILE * i, -(y + MR.TILE * j))
                t:SetVertexColor(shade, shade, shade, 1)
                t:Show()
            end
        end
    end
    HideFrom(n + 1)
    layer:Show()
    drawnMap, drawnCanvas = mapID, canvas
    dirty = false
    MR.drawn = n
    return n
end

function MR.Clear()
    HideFrom(1)
    if layer then layer:Hide() end
    drawnMap, drawnCanvas = nil, nil
    MR.drawn = 0
end

-- Im Takt: nur zeichnen, wenn sich Zone oder Flaeche geaendert haben.
function MR.Update()
    local qm = WeintCodex.QuestMap
    local wm = _G.WorldMapFrame
    if not (MR.Active() and qm and type(wm) == "table" and wm.IsShown and wm:IsShown()) then
        if drawnMap then MR.Clear() end
        return 0
    end
    local mapID = qm.CurrentMap and qm.CurrentMap()
    local canvas = qm.Canvas and qm.Canvas()
    if not (mapID and canvas) then
        MR.Clear()
        return 0
    end
    if mapID == drawnMap and canvas == drawnCanvas and not dirty then return MR.drawn or 0 end
    return MR.Draw(mapID, canvas)
end

--------------------------------------------------
-- Taktgeber und Ereignisse
--------------------------------------------------

local driver
local function EnsureDriver()
    if driver then return driver end
    local wm = _G.WorldMapFrame
    if type(wm) ~= "table" then return nil end
    driver = CreateFrame("Frame", nil, wm)
    local acc = 0
    driver:SetScript("OnUpdate", K.Measured("Karte: aufdecken", function(_, el)
        acc = acc + (el or 0)
        if acc < MR.TICK then return end
        acc = 0
        MR.Update()
    end))
    MR.driver = driver
    return driver
end

-- Neu erkundet: neu pruefen und zeichnen.
local ev = CreateFrame("Frame")
MR.events = ev
ev:SetScript("OnEvent", function(_, event, name)
    if event == "ADDON_LOADED" then
        if name == "Blizzard_WorldMap" and MR.Active() then EnsureDriver() end
        return
    end
    MR.Forget()
end)

local function Apply()
    MR.Forget()
    if MR.Active() then
        pcall(ev.RegisterEvent, ev, "ADDON_LOADED")
        pcall(ev.RegisterEvent, ev, "MAP_EXPLORATION_UPDATED")
        EnsureDriver()
        MR.Update()
    else
        pcall(ev.UnregisterEvent, ev, "ADDON_LOADED")
        pcall(ev.UnregisterEvent, ev, "MAP_EXPLORATION_UPDATED")
        MR.Clear()
    end
end
MR.Apply = Apply

--------------------------------------------------
-- Bericht (/wcui prüfen)
--------------------------------------------------

function MR.StatusLines()
    local out = {}
    local src = WeintCodex.MapRevealData
    local n = 0
    for _ in pairs(MR.Data()) do n = n + 1 end
    out[#out + 1] = "Aufdecken: " .. n .. " Zonen im Bestand (" .. tostring(src and src.source or "?") .. ")"
        .. (MR.Other() and " · Leatrix Maps geladen – es deckt selbst auf" or "")
    local cm, ex = _G.C_Map, _G.C_MapExplorationInfo
    out[#out + 1] = "GetMapArtID: " .. ((cm and type(cm.GetMapArtID) == "function") and "ja" or "nein")
        .. " · GetExploredMapTextures: " .. ((ex and type(ex.GetExploredMapTextures) == "function") and "ja" or "nein")
    local fits, unchecked, bad = {}, 0, {}
    for _, c in pairs(checked) do
        if c.status == "fits" then fits[#fits + 1] = c.name
        elseif c.status == "unchecked" then unchecked = unchecked + 1
        elseif c.status == "mismatch" then bad[#bad + 1] = c.name .. " (" .. c.bad .. " von " .. c.explored .. ")" end
    end
    if #fits + unchecked + #bad > 0 then
        out[#out + 1] = "Geprüft: " .. #fits .. " passen, " .. unchecked .. " ohne Erkundetes (ungeprüft), "
            .. #bad .. " passen nicht" .. (#bad > 0 and (": " .. table.concat(bad, ", ")) or "")
    end
    if drawnMap then
        out[#out + 1] = "Zuletzt: " .. (MR.drawn or 0) .. " Kacheln auf Karte " .. drawnMap
            .. (MR.levelKnown and "" or " · Ebene der erkundeten Teile nicht gefunden (geschätzt)")
    end
    return out
end

--------------------------------------------------
-- Zeilen auf der Seite "Karte" (gebaut von ui/mapentrances.lua)
--------------------------------------------------

function MR.BuildRows(B)
    local off = function() return not K.Get(KEY, "mapReveal") end
    B:Row({ type = "toggle", label = "Ganze Karte zeigen", key = "mapReveal",
            description = "Auch Gebiete, in denen du noch nicht warst. Hat Leatrix Maps das Aufdecken, macht es das." },
          { type = "toggle", label = "Unerkundetes abdunkeln", key = "mapRevealTint", disabled = off,
            description = "Dunkler, wo du noch hin musst." })
    B:Note("Die Kartenteile stammen aus Leatrix Maps (nur die Daten). WeintCodex prüft sie gegen das, was du schon erkundet hast, und deckt eine Zone nicht auf, wenn sie nicht passen.")
end

local mod = K.Module(KEY)
if mod then
    for k, v in pairs(MR.DEFAULTS) do
        if mod.defaults[k] == nil then mod.defaults[k] = v end
    end
end

K.Listen(function(kind, key)
    if (kind == "active" or kind == "setting") and key == KEY then Apply() end
end)
