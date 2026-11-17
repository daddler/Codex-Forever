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
    -- 6.21.2.0 (Beta-Test: "alle Geistheiler, Pfeile etc. azerothweit"):
    mapFlight    = false,    -- Flugmeister
    mapTravel    = false,    -- Schiffe, Zeppeline, Trams, Portale
    mapMarksOther = false,   -- auch die der anderen Fraktion
    mapMarksContinent = true, -- auch auf der Kontinentkarte
    -- 6.30.16.0 (Wunsch: "die Schiffsanleger muessten auch auf der
    -- Minimap zu sehen sein"): Reisen auch auf der Minikarte.
    mapTravelMinimap = true,
    -- 1.0.7.4 (Wunsch: "auf der Minimap erkennen, wo was in der Naehe ist"):
    -- Stadt-Pins auch auf der Minikarte (nur, wenn Staedte an sind).
    mapTownMinimap = true,
    -- 1.0.7.0 (Vergleich mit Naowh Forever "Town Pins"): Dienste in Staedten
    -- und Briefkaesten (data/towns.lua, erzeugt, `community`).
    mapTown      = false,
}
MK.TOWN_TEXT = { vendor = "Gemischtwaren", repair = "Reparieren", profession = "Berufslehrer", class = "Klassenlehrer",
    trade = "Handwerkswaren", food = "Essen und Trinken", flight = "Flugmeister", stable = "Stallmeister",
    inn = "Gasthaus", bank = "Bank", auction = "Auktionshaus", reagents = "Reagenzien", ammo = "Munition", mail = "Briefkasten" }
MK.TOWN = 20
-- 1.0.7.3 (Bild: "das sieht echt nicht geil aus"): Pins, die naeher als
-- MK.TOWN_MERGE (Kartenanteil) beieinander liegen, werden ein Pin mit Zahl;
-- das Symbol nennt die wichtigste Art, der Tooltip alle.
-- 1.0.7.4 (Wunsch: "wenn ich in die Map reinscrolle, sollen sich die Symbole
-- vereinzeln"): der Abstand gilt in Bildpunkten der Karte, nicht als
-- Kartenanteil - je naeher gezoomt, desto mehr einzelne Pins.
MK.TOWN_MERGE_PX = 34
MK.TOWN_MERGE = 0.05   -- nur Rueckfall ohne Kartengroesse
-- 1.0.7.2 (Bild: "die Symbole sind da, aber nicht zu erkennen, was wer ist"):
-- je Art ein Symbol aus dem Spiel (Gegenstands-/Zaubersymbole, die jeder
-- Client hat) und ein Filter direkt an der Karte. Ab Werk ohne Haendler fuer
-- Gemischtwaren, Handwerkswaren, Essen, Reagenzien und Munition.
-- 1.0.7.27 (Wunsch: "Symbole professionell"): eigene gemalte Symbole aus
-- .github/scripts/make_map_icons.py statt Spielsymbolen im Kreis.
MK.ICONS = "Interface\\AddOns\\WeintCodex\\media\\mapicons\\"
MK.TOWN_ICON = {}
for _, k in ipairs({ "vendor", "repair", "profession", "class", "trade", "food", "stable", "inn",
                     "bank", "auction", "reagents", "ammo", "mail" }) do
    MK.TOWN_ICON[k] = MK.ICONS .. k
end

-- Noch besser: die Symbole, die das Spiel selbst im Aufspuermenue der
-- Minikarte zeigt (Bankier, Gastwirt, Briefkasten ...). WeintCodex ERRAET
-- keinen Pfad - es fragt den Client (C_Minimap.GetTrackingInfo) und ordnet
-- nach dem Namen zu. Was der Client nicht nennt, bleibt beim eigenen Bild.
MK.TRACK_WORDS = {
    bank = { "bankier", "banker" }, auction = { "auktion" }, inn = { "gastwirt", "innkeeper" },
    mail = { "briefkast", "mailbox" }, repair = { "reparat", "repair" },
    flight = { "flugmeister", "flight master" }, stable = { "stallmeister", "stable" },
    class = { "klassenlehrer", "class trainer" }, profession = { "berufslehrer", "profession" },
    food = { "essen", "food" }, reagents = { "reagenz", "reagent" }, ammo = { "munition", "ammunition" },
}
local clientIcon
function MK.ClientIcons()
    if clientIcon then return clientIcon end
    local cm = _G.C_Minimap
    local num = (cm and cm.GetNumTrackingTypes) or _G.GetNumTrackingTypes
    local info = (cm and cm.GetTrackingInfo) or _G.GetTrackingInfo
    if not (num and info) then return {} end
    local ok, n = pcall(num)
    n = ok and K.Plain(n)
    if type(n) ~= "number" or n == 0 then return {} end
    clientIcon = {}
    for i = 1, n do
        local ok2, a, b = pcall(info, i)
        local name, tex
        if ok2 and type(a) == "table" then name, tex = K.Plain(a.name), K.Plain(a.texture)
        elseif ok2 then name, tex = K.Plain(a), K.Plain(b) end
        if type(name) == "string" and (type(tex) == "number" or type(tex) == "string") then
            local low = name:lower()
            for cat, words in pairs(MK.TRACK_WORDS) do
                for _, w in ipairs(words) do
                    if not clientIcon[cat] and low:find(w, 1, true) then clientIcon[cat] = tex end
                end
            end
        end
    end
    return clientIcon
end
function MK.Icon(cat)
    return MK.ClientIcons()[cat] or MK.TOWN_ICON[cat] or (MK.ICONS .. (cat or "vendor"))
end
MK.TOWN_ORDER = { "mail", "bank", "auction", "inn", "repair", "class", "profession", "stable",
    "vendor", "trade", "food", "reagents", "ammo" }
MK.TOWN_DEFAULT = { mail = true, bank = true, auction = true, inn = true, repair = true, class = true,
    profession = false, stable = true, vendor = false, trade = false, food = false, reagents = false, ammo = false }
for cat, on in pairs(MK.TOWN_DEFAULT) do MK.DEFAULTS["mapTown_" .. cat] = on end
function MK.TownWants(cat) return K.Get(KEY, "mapTown_" .. cat) and true or false end
MK.SMALL = 0.7       -- auf dem Kontinent kleiner (es sind ueber zweihundert)
MK.VEHICLE = { "Schiff", "Zeppelin", "Tram", "Portal" }
MK.FACTION = { "Allianz", "Horde", "neutral" }

-- 6.21.0.1 (Beta-Test: "zwar drin, aber nicht gut zu sehen"): groesser,
-- heller (GameColors.mapMark), mit hellem Rand und dunklem Hof - auf dem
-- Gruen und Braun der Karte hob sich das Gruen allein nicht ab.
-- 6.26.5.0 (Beta-Test: "sehr praegnant, ein bisschen dezenter"): kleiner,
-- Hof und Rand leiser, das ganze Symbol etwas durchsichtig - unter der Maus
-- wieder voll.
MK.SPIRIT = 20       -- Groesse des Punkts (Bildpunkte, bei jedem Zoom)
MK.ARROW = 22        -- Groesse des Pfeils
MK.ALPHA = 0.8       -- Deckkraft ohne Maus
MK.HALO = 0.35       -- dunkler Hof
MK.RIM = 0.7         -- heller Rand
MK.TICK = 0.05

local WANT = { spirit = "mapSpirit", crossing = "mapCrossings", flight = "mapFlight", travel = "mapTravel", town = "mapTown" }
function MK.Wants(kind)
    return K.IsActive(KEY) and K.Get(KEY, WANT[kind]) and true or false
end
function MK.Active() return MK.Wants("spirit") or MK.Wants("crossing") or MK.Wants("flight") or MK.Wants("travel") or MK.Wants("town") end

-- Eigene Fraktion: 1 Allianz, 2 Horde, nil unbekannt (dann alle).
local function MyFaction()
    local f = _G.UnitFactionGroup and K.Plain(_G.UnitFactionGroup("player"))
    return f == "Alliance" and 1 or f == "Horde" and 2 or nil
end
local function Shows(f)
    if f == 3 or K.Get(KEY, "mapMarksOther") then return true end
    local me = MyFaction()
    return me == nil or me == f
end

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

-- Die Eintraege einer Zone in `out`; `x0..y1` legt sie auf den Kontinent.
-- Nahe Pins zusammenfassen: nach Rang der Art (MK.TOWN_ORDER) sortiert,
-- jeder Pin geht in die erste Gruppe in Reichweite, sonst in eine neue.
local RANK = {}
for i, cat in ipairs(MK.TOWN_ORDER) do RANK[cat] = i end
local function ByRank(a, b)
    local ra, rb = RANK[a.cat] or 99, RANK[b.cat] or 99
    if ra ~= rb then return ra < rb end
    if a.x ~= b.x then return a.x < b.x end
    return a.y < b.y
end
function MK.SortTowns(raw) table.sort(raw, ByRank) return raw end
function MK.ClusterTowns(raw, radius)
    MK.SortTowns(raw)
    local r = radius or MK.TOWN_MERGE
    local out, r2 = {}, r * r
    for _, p in ipairs(raw) do
        local hit
        for _, c in ipairs(out) do
            local dx, dy = c.x - p.x, c.y - p.y
            if dx * dx + dy * dy <= r2 then hit = c break end
        end
        if hit then
            hit.n = hit.n + 1
            if not hit.cats[p.cat] then hit.order[#hit.order + 1] = p.cat end
            hit.cats[p.cat] = (hit.cats[p.cat] or 0) + 1
        else
            out[#out + 1] = { kind = "town", x = p.x, y = p.y, cat = p.cat, n = 1,
                              cats = { [p.cat] = 1 }, order = { p.cat } }
        end
    end
    return out
end

local function AddZone(out, d, zone, x0, x1, y0, y1)
    local function P(x, y)
        if not x0 then return x, y end
        return x0 + x * (x1 - x0), y0 + y * (y1 - y0)
    end
    local small = x0 ~= nil
    -- 6.21.2.0: auf dem Kontinent nur die Reisen (Schiffe, Zeppeline, ...) -
    -- Geistheiler, Pfeile und Flugmeister erst in der Zone (Wunsch aus dem
    -- Test: die grosse Karte war zu voll).
    if not small and MK.Wants("spirit") then
        local list = d.spirit and d.spirit[zone]
        for i = 1, list and #list or 0, 2 do
            local x, y = P(list[i], list[i + 1])
            out[#out + 1] = { kind = "spirit", x = x, y = y, small = small }
        end
    end
    if not small and MK.Wants("crossing") then
        local list = d.crossings and d.crossings[zone]
        for i = 1, list and #list or 0, 4 do
            local to = list[i + 3]
            if MK.MapName(to) then
                local x, y = P(list[i], list[i + 1])
                out[#out + 1] = { kind = "crossing", x = x, y = y, rot = list[i + 2], to = to, small = small }
            end
        end
    end
    if not small and MK.Wants("flight") then
        local list = d.flights and d.flights[zone]
        for i = 1, list and #list or 0, 3 do
            if Shows(list[i + 2]) then
                local x, y = P(list[i], list[i + 1])
                out[#out + 1] = { kind = "flight", x = x, y = y, faction = list[i + 2], zone = zone, small = small }
            end
        end
    end
    if not small and MK.Wants("town") then
        local towns = WeintCodex.TownData and WeintCodex.TownData.maps[zone]
        local me = MyFaction()
        local cls = _G.UnitClass and select(2, _G.UnitClass("player"))
        local raw = {}
        for _, t in ipairs(towns or {}) do
            local fac = t[4]
            local ok = K.Get(KEY, "mapMarksOther") or fac == nil or fac == "AH" or me == nil
                or (me == 1 and fac == "A") or (me == 2 and fac == "H")
            -- Klassenlehrer nur der eigenen Klasse; Flugmeister zeichnet die eigene Art.
            if ok and t[3] ~= "flight" and (t[3] ~= "class" or t[5] == cls) and MK.TownWants(t[3]) then
                local x, y = P(t[1] / 100, t[2] / 100)
                raw[#raw + 1] = { x = x, y = y, cat = t[3] }
            end
        end
        -- Roh (nach Rang sortiert); zusammengefasst wird je Zoom in MK.Visible.
        MK.SortTowns(raw)
        for _, c in ipairs(raw) do
            c.kind, c.small = "town", small
            out[#out + 1] = c
        end
    end
    if MK.Wants("travel") then
        local list = d.travel and d.travel[zone]
        for i = 1, list and #list or 0, 5 do
            if Shows(list[i + 3]) and MK.MapName(list[i + 4]) then
                local x, y = P(list[i], list[i + 1])
                out[#out + 1] = { kind = "travel", x = x, y = y, vehicle = list[i + 2], faction = list[i + 3],
                                  to = list[i + 4], small = small }
            end
        end
    end
end

function MK.ForMap(mapID)
    if type(mapID) ~= "number" then return {} end
    local cached = forMap[mapID]
    if cached then return cached end
    local out = {}
    local d = Data()
    AddZone(out, d, mapID)
    -- Kontinent: jede Zone darunter, ueber das Rechteck, das der Client nennt.
    local ME = WeintCodex.UIMapEntrances
    local info = ME and ME.MapInfo(mapID)
    if K.Get(KEY, "mapMarksContinent") and info and K.Plain(info.mapType) == ME.CONTINENT then
        local zones, seen = {}, {}
        for _, set in ipairs({ d.travel }) do
            for zone in pairs(set or {}) do
                if not seen[zone] then seen[zone] = true zones[#zones + 1] = zone end
            end
        end
        table.sort(zones)
        for _, zone in ipairs(zones) do
            if zone ~= mapID and ME.Under(zone, mapID) then
                local x0, x1, y0, y1 = ME.Rect(zone, mapID)
                if x0 then AddZone(out, d, zone, x0, x1, y0, y1) end
            end
        end
    end
    forMap[mapID] = out
    return out
end

-- Was die Weltkarte bei dieser Groesse zeigt: alles ausser den Stadt-Pins
-- unveraendert, die Stadt-Pins zusammengefasst. Neu gerechnet nur, wenn
-- sich der Zoom spuerbar aendert (nicht je Takt).
local visible = {}
function MK.Visible(mapID, px)
    local list = MK.ForMap(mapID)
    local r = (type(px) == "number" and px > 1) and (MK.TOWN_MERGE_PX / px) or MK.TOWN_MERGE
    local v = visible[mapID]
    if v and v.src == list and math.abs(v.r - r) <= v.r * 0.08 then return v.list end
    local out, towns = {}, {}
    for _, e in ipairs(list) do
        if e.kind == "town" then towns[#towns + 1] = e else out[#out + 1] = e end
    end
    if #towns == 0 then out = list
    else for _, c in ipairs(MK.ClusterTowns(towns, r)) do out[#out + 1] = c end end
    visible[mapID] = { src = list, r = r, list = out }
    return out
end

function MK.Forget()
    for k in pairs(visible) do visible[k] = nil end
    for k in pairs(forMap) do forMap[k] = nil end
    for k in pairs(names) do names[k] = nil end
end

--------------------------------------------------
-- Symbole
--------------------------------------------------

local pins = {}
MK.pins = pins
-- Zaehlung auf der Minikarte je Symbol (nicht am Rahmen: Felder dort
-- koennten Methoden des Rahmens verdecken).
local mmInfo = setmetatable({}, { __mode = "k" })

local function Tooltip(self)
    local gt = _G.GameTooltip
    local e = self.entry
    if not (gt and e) then return end
    gt:SetOwner(self, "ANCHOR_RIGHT")
    local t = C.textBright
    if e.kind == "spirit" then
        gt:SetText("Geistheiler", t[1], t[2], t[3])
    elseif e.kind == "flight" then
        gt:SetText("Flugmeister (" .. MK.FACTION[e.faction] .. ")", t[1], t[2], t[3])
        local z = MK.MapName(e.zone)
        if z then gt:AddLine(z, C.textNormal[1], C.textNormal[2], C.textNormal[3]) end
    elseif e.kind == "town" then
        gt:SetText(MK.TOWN_TEXT[e.cat] or e.cat, t[1], t[2], t[3])
        local n, cats = e.n, e.cats
        local inf = mmInfo[self]
        if inf and inf.n > 0 then n, cats = inf.n, inf.cats end
        if n and n > 1 and cats then
            local nrm = C.textNormal
            for _, cat in ipairs(MK.TOWN_ORDER) do
                local k = cats[cat]
                if k then
                gt:AddLine("|T" .. MK.Icon(cat) .. ":14:14|t " .. (MK.TOWN_TEXT[cat] or cat) .. (k > 1 and (" ×" .. k) or ""),
                    nrm[1], nrm[2], nrm[3])
                end
            end
        end
    elseif e.kind == "travel" then
        gt:SetText(MK.VEHICLE[e.vehicle] .. " nach " .. (MK.MapName(e.to) or "?"), t[1], t[2], t[3])
        gt:AddLine(MK.FACTION[e.faction], C.textNormal[1], C.textNormal[2], C.textNormal[3])
    else
        gt:SetText("Nach " .. (MK.MapName(e.to) or "?"), t[1], t[2], t[3])
    end
    local m = C.textMuted
    gt:AddLine("Von Spielern gesammelt.", m[1], m[2], m[3], true)
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

local holders = setmetatable({}, { __mode = "k" })
function MK.Holder(canvas)
    local h = holders[canvas]
    if not h then
        h = CreateFrame("Frame", nil, canvas)
        h:SetAllPoints(canvas)
        holders[canvas] = h
    end
    return h
end

local function NewPin(canvas)
    local p = CreateFrame("Frame", nil, canvas)
    p:EnableMouse(true)
    local g, w = GC.mapMark, C.textBright
    local disc, arrow = K.MEDIA .. "disc", K.ARROW_TEXTURE
    -- Punkt: dunkler Hof, heller Ring, gruener Kern (eigene Bilder).
    p.spirit = { Layer(p, disc, 1, BLACK, MK.HALO, 2), Layer(p, disc, 2, w, MK.RIM, 0), Layer(p, disc, 3, g, 1, -2) }
    -- Pfeil: dunkler Schatten, heller Rand, gruener Pfeil.
    p.crossing = { Layer(p, arrow, 1, BLACK, MK.HALO, 3), Layer(p, arrow, 2, w, MK.RIM, 1), Layer(p, arrow, 3, g, 1, 0) }
    -- Flugmeister: Raute; Reise: Kreis mit hellem Kern - je in der Farbe
    -- der Fraktion (der Kern wird beim Einrichten gefaerbt).
    -- 1.0.7.27: Geistheiler, Flugmeister, Reisen als gemalte Symbole; die
    -- Fraktion zeigt ein kleiner Punkt unten rechts.
    local white = { 1, 1, 1 }
    p.spirit = { Layer(p, MK.ICONS .. "spirit", 3, white, 1, 2) }
    local dot = Layer(p, disc, 5, g, 1, 0)
    dot:ClearAllPoints()
    dot:SetSize(7, 7)
    dot:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", 1, -1)
    local dotRim = Layer(p, disc, 4, BLACK, 1, 0)
    dotRim:ClearAllPoints()
    dotRim:SetSize(9, 9)
    dotRim:SetPoint("CENTER", dot, "CENTER", 0, 0)
    p.flight = { Layer(p, MK.ICONS .. "flight", 3, white, 1, 2), dot, dotRim }
    p.flightArt = p.flight[1]
    p.travel = { Layer(p, MK.ICONS .. "travel", 3, white, 1, 2), dot, dotRim }
    -- Stadt (1.0.7.3 rund): dunkler Hof, farbiger Ring, darin rund das
    -- Symbol der Art; bei mehreren eine Zahl unten rechts.
    local icon = p:CreateTexture(nil, "ARTWORK", nil, 3)
    icon:SetPoint("TOPLEFT", p, "TOPLEFT", -2, 2)
    icon:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", 2, -2)
    p.townIcon = icon
    local count = K.NewText(p, 9, "OVERLAY", 7)
    count:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", 4, -3)
    count:SetShadowOffset(1, -1)
    p.townCount = count
    p.town = { icon }
    p.rim, p.dot = p.spirit[1], p.spirit[1]
    p.shade, p.arrow = p.crossing[1], p.crossing[3]
    p:SetAlpha(MK.ALPHA)
    p:SetScript("OnEnter", function(self) self:SetAlpha(1) Tooltip(self) end)
    p:SetScript("OnLeave", function(self)
        self:SetAlpha(MK.ALPHA)
        if _G.GameTooltip then _G.GameTooltip:Hide() end
    end)
    p:Hide()
    return p
end

-- Ein Symbol fuer einen Eintrag einrichten (nur, wenn es vorher ein anderes war).
local function Dress(p, e)
    if p.entry == e then return end
    p.entry = e
    local spirit = e.kind == "spirit"
    local size = e.kind == "crossing" and MK.ARROW or (e.kind == "town" and MK.TOWN or MK.SPIRIT)
    p:SetSize(size, size)
    if e.kind == "town" then
        p.townIcon:SetTexture(MK.Icon(e.cat))
        p.townCount:SetText(e.n and e.n > 1 and tostring(e.n) or "")
    end
    if e.kind ~= "town" then p.townCount:SetText("") end
    for _, kind in ipairs({ "spirit", "crossing", "flight", "travel", "town" }) do
        for _, t in ipairs(p[kind]) do t:SetShown(false) end
    end
    for _, t in ipairs(p[e.kind] or {}) do t:Show() end
    if e.kind == "flight" then p.flightArt:SetTexture(MK.Icon("flight")) end
    if e.kind == "flight" or e.kind == "travel" then
        local c = e.faction == 1 and GC.alliance or e.faction == 2 and GC.horde or GC.neutral
        p.flight[2]:SetVertexColor(c[1], c[2], c[3], 1)
    end
    if e.kind == "crossing" then
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
    local w, h = K.Plain(canvas:GetWidth()), K.Plain(canvas:GetHeight())
    if type(w) ~= "number" or type(h) ~= "number" or w <= 1 or h <= 1 then return 0 end
    local s = 1
    local cs = K.Plain(canvas.GetEffectiveScale and canvas:GetEffectiveScale())
    local ms = K.Plain(wm.GetEffectiveScale and wm:GetEffectiveScale())
    if type(cs) == "number" and type(ms) == "number" and cs > 0 and ms > 0 then s = cs / ms end
    local list = MK.Visible(mapID, w * s)
    -- Ueber den erkundeten Gebieten, unter den Eingaengen (6.22.0.2,
    -- ui/mapentrances.lua ME.BaseLevel).
    local ME = WeintCodex.UIMapEntrances
    local lvl = ME.BaseLevel(canvas)
    for i, e in ipairs(list) do
        local p = pins[i]
        if not p then
            p = NewPin(MK.Holder(canvas))
            pins[i] = p
        end
        -- Alle Symbole in EINEM Rahmen auf der Flaeche (6.21.1.1): direkt auf
        -- der Flaeche wurden es ueber zweihundert Kinder, und wer sie mit
        -- GetChildren las, brachte das Spiel zum Absturz.
        local holder = MK.Holder(canvas)
        if p:GetParent() ~= holder then p:SetParent(holder) end
        if mmInfo[p] then mmInfo[p].n = 0 end
        Dress(p, e)
        -- Der Abstand gilt im Massstab des Symbols: kleiner gemacht (Kontinent)
        -- muss er im selben Mass groesser werden - sonst rutschte alles zur
        -- linken oberen Ecke (6.21.1.2, Beta-Test: alles in einer Spalte).
        local f = e.small and MK.SMALL or 1
        p:SetScale(f / s)
        p:SetFrameLevel(lvl)
        p:ClearAllPoints()
        p:SetPoint("CENTER", canvas, "TOPLEFT", w * e.x * s / f, -h * e.y * s / f)
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
-- 1.0.7.2 (Wunsch: "an der Map direkt filtern, was man sehen moechte"):
-- ein Knopf oben rechts auf der Karte mit allen Arten zum An- und Abhaken.
function MK.FilterMenu(owner)
    local MU = _G.MenuUtil
    if not (MU and MU.CreateContextMenu) then return end
    local function toggle(key) K.Set(KEY, key, not K.Get(KEY, key)) MK.Forget() end
    MU.CreateContextMenu(owner, function(_, root)
        if root.CreateTitle then root:CreateTitle("Auf der Karte zeigen") end
        for _, it in ipairs({ { "mapSpirit", "Geistheiler" }, { "mapCrossings", "Übergänge" },
            { "mapFlight", "Flugmeister" }, { "mapTravel", "Schiffe, Zeppeline, Portale" }, { "mapTown", "Städte" } }) do
            local k = it[1]
            root:CreateCheckbox(it[2], function() return K.Get(KEY, k) and true or false end, function() toggle(k) end)
        end
        if root.CreateDivider then root:CreateDivider() end
        if root.CreateTitle then root:CreateTitle("In Städten") end
        for _, cat in ipairs(MK.TOWN_ORDER) do
            local k = "mapTown_" .. cat
            local label = "|T" .. MK.Icon(cat) .. ":14:14|t " .. MK.TOWN_TEXT[cat]
            root:CreateCheckbox(label, function() return K.Get(KEY, k) and true or false end, function()
                toggle(k)
                if not K.Get(KEY, "mapTown") and K.Get(KEY, k) then K.Set(KEY, "mapTown", true) end
            end)
        end
    end)
end
local function EnsureFilterButton(wm)
    if MK.filterBtn or not K.IsActive(KEY) then return end
    local host = wm.ScrollContainer or wm
    local b = CreateFrame("Button", "WeintCodexMapFilter", wm)
    b:SetSize(26, 26)
    b:SetPoint("TOPRIGHT", host, "TOPRIGHT", -6, -6)
    b:SetFrameLevel((K.Plain(host:GetFrameLevel()) or 1) + 20)
    local bg = b:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(b)
    local p = C.bgPanel
    bg:SetColorTexture(p[1], p[2], p[3], 0.9)
    K.Border(b, 1, 0, 0, 0, 1, "BORDER")
    local ic = b:CreateTexture(nil, "ARTWORK")
    ic:SetPoint("TOPLEFT", b, "TOPLEFT", 4, -4)
    ic:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -4, 4)
    ic:SetTexture(K.MEDIA .. "pin")
    b:SetScript("OnClick", function(self) MK.FilterMenu(self) end)
    b:SetScript("OnEnter", function(self)
        local gt = _G.GameTooltip
        if not gt then return end
        gt:SetOwner(self, "ANCHOR_LEFT")
        gt:SetText("WeintCodex: was die Karte zeigt")
        gt:AddLine("Geistheiler, Übergänge, Flugmeister, Reisen und die Dienste in Städten an- und abhaken.", 0.8, 0.8, 0.8, true)
        gt:Show()
    end)
    b:SetScript("OnLeave", function() if _G.GameTooltip then _G.GameTooltip:Hide() end end)
    MK.filterBtn = b
end
MK.EnsureFilterButton = EnsureFilterButton

local function EnsureDriver()
    local wm0 = _G.WorldMapFrame
    if type(wm0) == "table" then pcall(EnsureFilterButton, wm0) end
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

--------------------------------------------------
-- Minikarte (6.30.16.0): Schiffe, Zeppeline, Trams, Portale
--------------------------------------------------
-- Dieselbe Umrechnung wie die Questhilfe (QH.MinimapOffset: Lage einmal in
-- Weltkoordinaten, im Takt nur der Abstand). Nur die Reisen der Zone, in der
-- du stehst; Tooltip wie auf der Weltkarte, Klicks gehen an die Minikarte.
MK.MM_TICK = 0.1
MK.MM_SCALE = 0.8
local mmPins = {}
MK.mmPins = mmPins
local function MMHide(from) for i = from or 1, #mmPins do mmPins[i]:Hide() end end

local function MMTravel() return MK.Wants("travel") and K.Get(KEY, "mapTravelMinimap") and true or false end
local function MMTown() return MK.Wants("town") and K.Get(KEY, "mapTownMinimap") and true or false end
function MK.MinimapActive()
    return MMTravel() or MMTown()
end
-- Stadt-Pins auf der Minikarte: naeher als so viele Bildpunkte = ein Pin.
MK.MM_MERGE = 11
-- 1.0.7.5 (Bild: Minikarte zu voll): dort nur diese Arten.
MK.MM_TOWN = { bank = true, auction = true, mail = true, inn = true, repair = true }
local mmX, mmY = {}, {}

function MK.PlaceMinimap()
    local mm = _G.Minimap
    local QH = WeintCodex.UIQuestHelper
    if not (MK.MinimapActive() and QH and type(mm) == "table" and mm.IsShown and mm:IsShown()) then
        MMHide()
        return 0
    end
    local mapID = K.BestMap and K.BestMap()
    local yards = QH.MinimapYards()
    local pc, pn, pw = K.PlayerWorld()
    local w = K.Plain(mm:GetWidth())
    if not (mapID and yards and pc and type(w) == "number" and w > 1) then MMHide() return 0 end
    local facing
    if _G.GetCVar and K.Plain(_G.GetCVar("rotateMinimap")) == "1" and _G.GetPlayerFacing then
        facing = K.Plain(_G.GetPlayerFacing())
        if type(facing) ~= "number" then MMHide() return 0 end
    end
    local square = K.IsActive("minimap") and K.Get("minimap", "square") and true or false
    local half = w / 2
    local n = 0
    local travel, town = MMTravel(), MMTown()
    local merge2 = MK.MM_MERGE * MK.MM_MERGE
    for _, e in ipairs(MK.ForMap(mapID)) do
        local want = not e.small and ((e.kind == "travel" and travel) or (e.kind == "town" and town))
        local dx, dy
        if want then dx, dy = QH.MinimapOffset(e, mapID, pc, pn, pw, yards, half, facing, square) end
        -- 1.0.7.5 (Bild: "der Spielerpfeil muss ueber den Symbolen sein"): den
        -- Pfeil zeichnet die Minikarte selbst, jedes Kind liegt darueber -
        -- also bleibt die Mitte frei.
        if QH.UnderArrow(dx, dy) then dx = nil end
        -- Auf der Minikarte nur die wichtigen Dienste (MK.MM_TOWN).
        if dx and e.kind == "town" and not MK.MM_TOWN[e.cat] then dx = nil end
        -- Stadt: schon ein Stadt-Pin in der Naehe? Dann dort mitzaehlen
        -- (Liste ist nach Rang sortiert, der erste nennt die wichtigste Art).
        if dx and e.kind == "town" then
            for i = 1, n do
                local inf = mmInfo[mmPins[i]]
                if inf and inf.n > 0 then
                    local ax, ay = mmX[i] - dx, mmY[i] - dy
                    if ax * ax + ay * ay <= merge2 then
                        inf.n = inf.n + 1
                        inf.cats[e.cat] = (inf.cats[e.cat] or 0) + 1
                        dx = nil
                        break
                    end
                end
            end
        end
        if dx then
                n = n + 1
                local p = mmPins[n]
                if not p then
                    p = NewPin(mm)
                    if p.EnableMouseClicks then p:EnableMouseClicks(false) end
                    if p.EnableMouseMotion then p:EnableMouseMotion(true) end
                    p:SetScale(MK.MM_SCALE)
                    mmPins[n] = p
                end
                Dress(p, e)
                local inf = mmInfo[p]
                if not inf then inf = { n = 0, cats = {} } mmInfo[p] = inf end
                for k in pairs(inf.cats) do inf.cats[k] = nil end
                if e.kind == "town" then
                    inf.cats[e.cat] = 1
                    inf.n = 1
                else
                    inf.n = 0
                end
                mmX[n], mmY[n] = dx, dy
                p:SetFrameLevel((K.Plain(mm:GetFrameLevel()) or 0) + 6)
                p:ClearAllPoints()
                p:SetPoint("CENTER", mm, "CENTER", dx / MK.MM_SCALE, dy / MK.MM_SCALE)
                p:Show()
        end
    end
    for i = 1, n do
        local inf = mmInfo[mmPins[i]]
        if inf and inf.n > 0 then mmPins[i].townCount:SetText(inf.n > 1 and tostring(inf.n) or "") end
    end
    MMHide(n + 1)
    return n
end

local mmAcc = 0
local mmTicker = CreateFrame("Frame")
mmTicker:Hide()
mmTicker:SetScript("OnUpdate", K.Measured("Minikarte: Reisen", function(_, el)
    mmAcc = mmAcc + (el or 0)
    if mmAcc < MK.MM_TICK then return end
    mmAcc = 0
    MK.PlaceMinimap()
end))
MK.mmTicker = mmTicker

local ev = CreateFrame("Frame")
ev:SetScript("OnEvent", WeintCodex.Measured("Karte: Geistheiler, Übergänge", function(_, event, name)
    if event == "ADDON_LOADED" and name ~= "Blizzard_WorldMap" then return end
    if MK.Active() then EnsureDriver()
    elseif _G.WorldMapFrame then pcall(EnsureFilterButton, _G.WorldMapFrame) end
end))

local function Apply()
    MK.Forget()
    -- Ein Symbol, das vorher etwas anderes war, wird neu eingerichtet.
    for _, p in ipairs(pins) do p.entry = nil end
    for _, p in ipairs(mmPins) do p.entry = nil end
    mmTicker:SetShown(MK.MinimapActive())
    if not MK.MinimapActive() then MMHide() end
    -- Der Filterknopf soll auch da sein, wenn noch nichts an ist.
    pcall(ev.RegisterEvent, ev, "ADDON_LOADED")
    if _G.WorldMapFrame then pcall(EnsureFilterButton, _G.WorldMapFrame) end
    if MK.filterBtn then MK.filterBtn:SetShown(K.IsActive(KEY) and true or false) end
    if MK.Active() then
        EnsureDriver()
        MK.Place()
    else
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
    B:Row({ type = "toggle", label = "Flugmeister", key = "mapFlight",
            description = "Eine Raute in der Farbe der Fraktion." },
          { type = "toggle", label = "Schiffe, Zeppeline, Trams, Portale", key = "mapTravel",
            description = "Ein Kreis in der Farbe der Fraktion. Maus darauf: wohin." })
    B:Row({ type = "toggle", label = "Auch die der anderen Fraktion", key = "mapMarksOther",
            description = "Sonst nur deine und die neutralen." },
          { type = "toggle", label = "Reisen auch auf der Kontinentkarte", key = "mapMarksContinent",
            description = "Dort nur Schiffe, Zeppeline, Trams und Portale, etwas kleiner. Der Rest erst in der Zone." })
    B:Advanced()
    B:Row({ type = "toggle", label = "Reisen auch auf der Minikarte", key = "mapTravelMinimap",
            description = "Schiffe, Zeppeline, Trams und Portale in deiner Nähe. Maus darauf: wohin.",
            disabled = function() return not K.Get(KEY, "mapTravel") end },
          { type = "toggle", label = "Städte: Händler, Lehrer, Briefkästen", key = "mapTown",
            description = "Kleine Punkte für Händler, Reparieren, Lehrer, Bank, Auktionshaus, Gasthaus – Briefkästen in eigener Farbe. Maus darauf: was es ist." })
    B:Row({ type = "toggle", label = "Städte auch auf der Minikarte", key = "mapTownMinimap",
            description = "Bank, Auktionshaus, Briefkasten, Gasthaus und Reparieren in deiner Nähe; dicht beieinander mit Zahl. Maus darauf: was es ist.",
            disabled = function() return not K.Get(KEY, "mapTown") end })
    B:EndAdvanced()
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
