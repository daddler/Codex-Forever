--------------------------------------------------
-- WeintCodex :: Sammel-Atlas (Fundstellen, Farmroute, stilles Teilen)
--------------------------------------------------
-- Seit 6.82.0.0 (Wunsch des Spielers: "wo habe ich schon gesammelt, eine
-- Farmroute daraus, und still mit der Gilde teilen"). Seite "Sammeln" im
-- Komfort, von Haus aus AUS, geht ohne Oberflaeche.
--
-- WOHER: nur aus dem eigenen Spiel. WeintCodex bringt KEINE Liste von
-- Fundstellen mit - jede Stelle hat der Spieler (oder jemand aus seiner
-- Gilde mit WeintCodex) selbst gesammelt. Kein Bestand ohne Herkunft:
-- ohne Sammeln kein Punkt.
--
-- ERKENNEN (ohne Kampflog - 12.x gibt Addons keins):
--   1. UNIT_SPELLCAST_SENT des Spielers mit einem Sammelzauber (GA.SPELLS,
--      die Zauber der klassischen Clients) - merkt Ziel, castGUID, Lage.
--   2. UNIT_SPELLCAST_SUCCEEDED mit derselben castGUID - gelungen.
--   3. LOOT_OPENED kurz danach (GA.LOOT_WINDOW; Angeln GA.FISH_WINDOW):
--      GetLootSourceInfo(1) nennt die GUID der Quelle, aus
--      "GameObject-...-<objectID>-..." die Art der Fundstelle. Ohne GUID
--      zaehlt der Name aus dem Zauber (Schluessel ist dann der Name, und
--      geteilt wird so ein Punkt nicht - die Gilde bekommt nur Nummern).
--   Nie in Instanzen. Jeder Wert des Clients durch K.Plain/pcall.
--   Angeln: nur aus einem Schwarm (Quelle ist nicht der Schwimmer); die
--   Lage ist die des Spielers, nicht die des Schwarms (der liegt ~15 m
--   weiter im Wasser - die Karte zeigt, von wo aus man ihn erreicht).
--   "Oeffnen" (Truhen) ist auch der Zauber vieler Questobjekte: liegt NUR
--   Questbeute darin, zaehlt es nicht.
--   UNGEMESSEN auf Forever: ob SENT ein Ziel nennt, ob GetLootSourceInfo
--   offen antwortet, ob Angeln die GUID des Schwarms nennt - /wcui prüfen
--   zeigt die letzte Erkennung.
--
-- SPEICHER (kontoweit, WeintCodex_SavedData.gather):
--   nodes[mapID][objectID] = { {x=,y=,n=,last=,s=}, ... }   s: von der Gilde
--   names[objectID] = Name vom Client (einmal), kinds[objectID] = Art
--   routes[mapID] = { kind = ..., stops = { {x, y}, ... } }
--   Punkte naeher als GA.MERGE gelten als derselbe; je Karte hoechstens
--   GA.MAP_CAP Punkte.
--
-- ROUTE: automatisch (Raster -> naechster Nachbar -> 2-opt, FarmRoute.Order,
-- reine Funktion, offline geprueft) oder von Hand auf der Weltkarte. Folgen
-- setzt den Questpfeil (QA.SetCustom) auf den naechsten Halt; naeher als
-- GA.REACH m oder dort gesammelt: weiter zum naechsten, im Kreis.
--
-- TEILEN (gatherShare, nur mit eingeschaltetem Atlas): Addon-Nachrichten
-- an die Gilde, Kennung GA.PREFIX, je neu gefundener Stelle eine Zeile
-- "n,<Karte>,<Objekt>,<x*10000>,<y*10000>[,<Art>]". Nie im Chat, nie im
-- Kampf gesendet. Empfangenes wird streng geprueft (Zahlen, Bereiche,
-- Laenge, Takt je Absender) und als "von der Gilde" gemerkt, nie als
-- eigenes Sammeln gezaehlt. Sonst geht nichts nach draussen.
--
-- Verhalten angelehnt an GatherLite (MIT, Wuild): Sammelzauber + castGUID
-- + kurz danach die Beute. Code und Daten von dort sind NICHT uebernommen.
--------------------------------------------------

local K = WeintCodex.UIKit
local C = WeintCodex.Colors
local GC = WeintCodex.GameColors
local KEY = "comfort"

WeintCodex.UIGatherAtlas = {}
local GA = WeintCodex.UIGatherAtlas
WeintCodex.FarmRoute = {}
local FR = WeintCodex.FarmRoute

GA.DEFAULTS = {
    gatherAtlas = true,      -- der ganze Atlas (6.106.0.0: ab Werk an, Wunsch)
    gatherShare = true,      -- still mit der Gilde teilen (nur mit Atlas)
    gaMapHerb = true, gaMapOre = true, gaMapChest = true, gaMapFish = true,
    gaMiniHerb = true, gaMiniOre = true, gaMiniChest = false, gaMiniFish = false,
    gaRouteKind = "all",
}
GA.KINDS = { "herb", "ore", "chest", "fish" }
GA.KIND_LABEL = { herb = "Kraut", ore = "Erz", chest = "Truhe", fish = "Fischschwarm" }
GA.KIND_COLOR = { herb = "gatherHerb", ore = "gatherOre", chest = "gatherChest", fish = "gatherFish" }
GA.KIND_CODE = { herb = "h", ore = "o", chest = "c", fish = "f" }
GA.CODE_KIND = { h = "herb", o = "ore", c = "chest", f = "fish" }
local MAPKEY = { herb = "gaMapHerb", ore = "gaMapOre", chest = "gaMapChest", fish = "gaMapFish" }
local MINIKEY = { herb = "gaMiniHerb", ore = "gaMiniOre", chest = "gaMiniChest", fish = "gaMiniFish" }

-- Sammelzauber der klassischen Clients: Kraeutersammeln, Bergbau, Oeffnen,
-- Angeln (vier Raenge).
GA.SPELLS = { [2366] = "herb", [2575] = "ore", [3365] = "chest",
              [7620] = "fish", [7731] = "fish", [7732] = "fish", [18248] = "fish" }
GA.BOBBER = 35591          -- Angelschwimmer: Angeln im freien Wasser, kein Schwarm
GA.MERGE = 0.004           -- Kartenanteil: so nah = dieselbe Stelle
GA.MAP_CAP = 1500          -- Punkte je Karte
GA.LOOT_WINDOW = 1.5       -- s nach dem Zauber
GA.FISH_WINDOW = 30
GA.REACH = 15              -- m: Halt erreicht (6.84.2.0: 10 war zu knapp)
GA.MAX_PINS = 400          -- Symbole auf der Weltkarte
GA.MAX_MINI = 60
GA.PIN = 14
GA.MINI_PIN = 22   -- 6.84.6.0: 26 war zu gross; 6.84.7.0: 18 verdeckte das Vorkommen - duenner Ring, grosses Loch
-- 6.84.1.0 (Beta-Test: "immer noch schwer zu sehen - eine Ebene tiefer
-- waere super"): tiefer geht nicht - die Vorkommen zeichnet die Minikarte
-- selbst, auf ihrem eigenen deckenden Bild; alles von Addons liegt
-- darueber (unter der Minikarte waere es verdeckt). Darum ein groesserer,
-- duenner Ring, in dessen Loch das Symbol des Spiels ganz frei steht.
-- 6.83.4.0 (Beta-Test mit Bild: "das wirkliche Vorkommen wird vom Icon
-- ueberdeckt"): auf der Minikarte ein offener Ring statt des Symbols - das
-- Vorkommen des Spiels steht sichtbar in der Mitte; nur gedeckt gezeigt.
GA.MINI_RING = K.MEDIA .. "gather_ring"
GA.MINI_ALPHA = 0.85
GA.MINI_FADE, GA.MINI_GONE = 34, 10   -- Bildpunkte vom Spielerpfeil (6.84.3.0)
GA.TICK = 0.1
GA.MM_TICK = 0.2
GA.FOLLOW_TICK = 0.5
GA.MEDIA = { herb = K.MEDIA .. "gather_herb", ore = K.MEDIA .. "gather_ore",
             chest = K.MEDIA .. "gather_chest", fish = K.MEDIA .. "gather_fish" }

local function Now()
    local t = _G.GetTime and K.Plain(_G.GetTime())
    return type(t) == "number" and t or 0
end
local function Clock()
    local t = _G.time and _G.time()
    return type(t) == "number" and t or 0
end
local function Say(text) print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " " .. text) end

function GA.Active() return K.IsActive(KEY) and K.Get(KEY, "gatherAtlas") and true or false end
function GA.Sharing() return GA.Active() and K.Get(KEY, "gatherShare") and true or false end
function GA.ShowsOnMap(kind) return GA.Active() and MAPKEY[kind] and K.Get(KEY, MAPKEY[kind]) and true or false end
function GA.ShowsOnMini(kind) return GA.Active() and MINIKEY[kind] and K.Get(KEY, MINIKEY[kind]) and true or false end

--------------------------------------------------
-- Speicher
--------------------------------------------------

-- Nie in eine frische Ersatztabelle: ohne WeintCodex.SavedData nil.
function GA.Store(create)
    local sd = WeintCodex.SavedData
    if type(sd) ~= "table" then return nil end
    local g = sd.gather
    if type(g) ~= "table" then
        if not create then return nil end
        g = {}
        sd.gather = g
    end
    if type(g.nodes) ~= "table" then g.nodes = {} end
    if type(g.names) ~= "table" then g.names = {} end
    if type(g.kinds) ~= "table" then g.kinds = {} end
    if type(g.routes) ~= "table" then g.routes = {} end
    return g
end

GA.version = 0          -- steigt bei jeder Aenderung; Symbole bauen dann neu
local function Changed() GA.version = GA.version + 1 end

local function CountMap(m)
    local n = 0
    for _, list in pairs(m) do n = n + #list end
    return n
end
GA.CountMap = CountMap

-- Eine Stelle merken. `key`: objectID (Zahl) oder Name (Text, ohne GUID).
-- Gibt den Punkt und ob er neu ist zurueck - oder nil (ungueltig, voll).
function GA.Record(mapID, key, x, y, kind, name, shared, when)
    if type(mapID) ~= "number" or mapID <= 0 then return nil end
    if not (type(key) == "number" and key > 0) and not (type(key) == "string" and key ~= "") then return nil end
    if type(x) ~= "number" or type(y) ~= "number" or x < 0 or x > 1 or y < 0 or y > 1 then return nil end
    local g = GA.Store(true)
    if not g then return nil end
    if kind and GA.KIND_LABEL[kind] and not g.kinds[key] then g.kinds[key] = kind end
    if type(name) == "string" and name ~= "" and not g.names[key] then g.names[key] = name end
    local m = g.nodes[mapID]
    if not m then m = {} g.nodes[mapID] = m end
    local list = m[key]
    when = when or Clock()
    for _, p in ipairs(list or {}) do
        if math.abs(p.x - x) < GA.MERGE and math.abs(p.y - y) < GA.MERGE then
            if not shared then
                p.n = (p.n or 0) + 1
                p.last = when
                p.s = nil
                Changed()
            end
            return p, false
        end
    end
    if CountMap(m) >= GA.MAP_CAP then return nil end
    if not list then list = {} m[key] = list end
    local p = { x = math.floor(x * 10000 + 0.5) / 10000, y = math.floor(y * 10000 + 0.5) / 10000,
                n = shared and 0 or 1, last = when, s = shared and true or nil }
    list[#list + 1] = p
    Changed()
    return p, true
end

function GA.KindOf(key)
    local g = GA.Store()
    return g and g.kinds[key] or nil
end
function GA.NameOf(key)
    local g = GA.Store()
    local n = g and g.names[key]
    if n then return n end
    local kind = g and g.kinds[key]
    return kind and GA.KIND_LABEL[kind] or "Fundstelle"
end

--------------------------------------------------
-- Farmroute (rein, ohne Client - offline geprueft)
--------------------------------------------------

-- Punkte {x, y} in ein Raster der Groesse `cell` fassen; je Zelle der
-- Schwerpunkt. Mehr als `cap` Zellen: Raster groeber, bis es passt.
function FR.Cluster(points, cell, cap)
    cell, cap = cell or 0.02, cap or 150
    local out
    for _ = 1, 20 do
        local cells, order = {}, {}
        for _, p in ipairs(points) do
            local k = math.floor(p[1] / cell) * 100000 + math.floor(p[2] / cell)
            local c = cells[k]
            if not c then
                c = { 0, 0, 0 }
                cells[k] = c
                order[#order + 1] = k
            end
            c[1], c[2], c[3] = c[1] + p[1], c[2] + p[2], c[3] + 1
        end
        out = {}
        for _, k in ipairs(order) do
            local c = cells[k]
            out[#out + 1] = { c[1] / c[3], c[2] / c[3] }
        end
        if #out <= cap then return out end
        cell = cell * 1.5
    end
    return out
end

local function Dist(a, b, ax)
    local dx, dy = (a[1] - b[1]) * ax, a[2] - b[2]
    return math.sqrt(dx * dx + dy * dy)
end

-- Reihenfolge eines geschlossenen Rundwegs: naechster Nachbar ab dem
-- ersten Punkt, dann 2-opt, bis nichts mehr kuerzer wird. `ax`: wie viel
-- breiter als hoch die Karte in der Welt ist (Standard 1). Gibt eine neue
-- Liste derselben Punkte zurueck, jeder genau einmal.
function FR.Order(points, ax)
    ax = (type(ax) == "number" and ax > 0) and ax or 1
    local n = #points
    if n <= 2 then
        local out = {}
        for i = 1, n do out[i] = points[i] end
        return out
    end
    local used, tour = {}, { 1 }
    used[1] = true
    for _ = 2, n do
        local last, best, bd = points[tour[#tour]], nil, math.huge
        for j = 1, n do
            if not used[j] then
                local d = Dist(last, points[j], ax)
                if d < bd then best, bd = j, d end
            end
        end
        used[best] = true
        tour[#tour + 1] = best
    end
    -- 2-opt auf dem geschlossenen Rundweg.
    for _ = 1, 60 do
        local better = false
        for i = 1, n - 2 do
            local a, b = points[tour[i]], points[tour[i + 1]]
            for j = i + 2, n do
                local c = points[tour[j]]
                local d = points[tour[j % n + 1]]
                if j % n + 1 ~= i then
                    local delta = Dist(a, c, ax) + Dist(b, d, ax) - Dist(a, b, ax) - Dist(c, d, ax)
                    if delta < -1e-9 then
                        local lo, hi = i + 1, j
                        while lo < hi do
                            tour[lo], tour[hi] = tour[hi], tour[lo]
                            lo, hi = lo + 1, hi - 1
                        end
                        a, b = points[tour[i]], points[tour[i + 1]]
                        better = true
                    end
                end
            end
        end
        if not better then break end
    end
    local out = {}
    for i, idx in ipairs(tour) do out[i] = points[idx] end
    return out
end

function FR.Length(points, ax)
    ax = ax or 1
    local n, sum = #points, 0
    for i = 1, n do sum = sum + Dist(points[i], points[i % n + 1], ax) end
    return sum
end

-- Seitenverhaeltnis einer Karte in der Welt (Breite / Hoehe), oder 1.
local aspects = {}
function GA.Aspect(mapID)
    local a = aspects[mapID]
    if a then return a end
    a = 1
    local c0, n0, w0 = K.ToWorld(mapID, 0, 0)
    local c1, n1, w1 = K.ToWorld(mapID, 1, 1)
    if c0 and c0 == c1 and n1 ~= n0 then a = math.abs((w1 - w0) / (n1 - n0)) end
    aspects[mapID] = a
    return a
end

-- Route aus den Stellen einer Karte (Art "all" oder eine aus GA.KINDS).
function GA.BuildRoute(mapID, kind)
    local g = GA.Store(true)
    if not (g and type(mapID) == "number") then return 0 end
    local pts = {}
    for key, list in pairs(g.nodes[mapID] or {}) do
        local k = g.kinds[key]
        if k and (kind == "all" or kind == k) then
            for _, p in ipairs(list) do pts[#pts + 1] = { p.x, p.y } end
        end
    end
    if #pts == 0 then g.routes[mapID] = nil Changed() return 0 end
    local stops = FR.Order(FR.Cluster(pts, 0.02, 150), GA.Aspect(mapID))
    for _, s in ipairs(stops) do
        s[1] = math.floor(s[1] * 10000 + 0.5) / 10000
        s[2] = math.floor(s[2] * 10000 + 0.5) / 10000
    end
    g.routes[mapID] = { kind = kind, stops = stops }
    Changed()
    return #stops
end

function GA.Route(mapID)
    local g = GA.Store()
    local r = g and g.routes[mapID]
    return (type(r) == "table" and type(r.stops) == "table") and r or nil
end

-- Von Hand: einen Halt an x, y anfuegen oder (wenn schon da) entfernen.
function GA.ToggleStop(mapID, x, y)
    local g = GA.Store(true)
    if not (g and type(mapID) == "number") then return nil end
    local r = GA.Route(mapID)
    if not r then r = { kind = "manual", stops = {} } g.routes[mapID] = r end
    r.kind = "manual"
    for i, s in ipairs(r.stops) do
        if math.abs(s[1] - x) < GA.MERGE and math.abs(s[2] - y) < GA.MERGE then
            table.remove(r.stops, i)
            Changed()
            return false
        end
    end
    r.stops[#r.stops + 1] = { x, y }
    Changed()
    return true
end

function GA.ClearRoute(mapID)
    local g = GA.Store()
    if g and mapID then g.routes[mapID] = nil end
    if GA.following == mapID then GA.StopFollow() end
    Changed()
end

--------------------------------------------------
-- Route folgen (Questpfeil)
--------------------------------------------------

GA.following, GA.step = nil, 1
local followTarget      -- die Tabelle, die der Pfeil haelt (unsere?)

local function PointTo()
    local QA = WeintCodex.UIQuestArrow
    local r = GA.following and GA.Route(GA.following)
    if not (r and #r.stops > 0 and QA and QA.SetCustom) then GA.StopFollow() return false end
    if GA.step > #r.stops then GA.step = 1 end
    local s = r.stops[GA.step]
    followTarget = { map = GA.following, x = s[1], y = s[2],
                     title = "Farmroute: Halt " .. GA.step .. " von " .. #r.stops }
    QA.SetCustom(followTarget)
    return true
end

function GA.Follow(mapID)
    if not (mapID and GA.Route(mapID)) then return false end
    GA.following, GA.step = mapID, 1
    -- Beim naechstgelegenen Halt beginnen.
    local r = GA.Route(mapID)
    local px, py = K.PlayerMapXY(mapID)
    if px then
        local bd = math.huge
        for i, s in ipairs(r.stops) do
            local d = (s[1] - px) ^ 2 + (s[2] - py) ^ 2
            if d < bd then bd, GA.step = d, i end
        end
    end
    if GA.followFrame then GA.followFrame:Show() end
    return PointTo()
end

function GA.StopFollow()
    local QA = WeintCodex.UIQuestArrow
    if followTarget and QA and QA.custom == followTarget and QA.ClearCustom then QA.ClearCustom() end
    followTarget = nil
    GA.following = nil
    if GA.followFrame then GA.followFrame:Hide() end
    if GA.skipButton then GA.skipButton:Hide() end
end

function GA.Advance()
    GA.step = GA.step + 1
    return PointTo()
end

_G.BINDING_HEADER_WEINTCODEX = "WeintCodex"
_G.BINDING_NAME_WEINTCODEX_FARM_SKIP = "Farmroute: Halt überspringen"

-- 6.84.4.0 (Wunsch: "im Kampf einen Halt auslassen, zu viele Mobs"):
-- von Hand weiter - Knopf, Taste (Bindings.xml) und /wcui weiter. Nur
-- Pfeil und eigene Daten, nichts Geschuetztes - geht auch im Kampf.
function GA.Skip()
    if not GA.following then
        Say("Du folgst gerade keiner Farmroute.")
        return false
    end
    return GA.Advance()
end

-- Abstand des Spielers zum aktuellen Halt in Metern (oder nil).
local stopWorld = { 0, 0, 0 }
function GA.YardsToStop()
    local r = GA.following and GA.Route(GA.following)
    local s = r and r.stops[GA.step]
    if not s then return nil end
    local c, n, w = K.ToWorld(GA.following, s[1], s[2])
    local pc, pn, pw = K.PlayerWorld()
    if not (c and pc and c == pc) then return nil end
    stopWorld[1], stopWorld[2], stopWorld[3] = c, n, w
    return math.sqrt((n - pn) ^ 2 + (w - pw) ^ 2)
end

function GA.CheckFollow()
    if not GA.following then return end
    local QA = WeintCodex.UIQuestArrow
    local d = GA.YardsToStop()
    -- 6.84.2.0 (Beta-Test: "Punkt erreicht, der Pfeil geht nicht weiter"):
    -- am Halt loest das Spiel seinen Wegpunkt und mit ihm das Ziel des
    -- Pfeils - das galt als "Spieler hat aufgehoert". Jetzt: ist das Ziel
    -- nur weg und der Spieler nah am Halt, geht es zum naechsten. Aufhoeren
    -- nur, wenn ein anderes Ziel gesetzt ist oder der Spieler weit weg ist.
    if QA and QA.custom ~= followTarget then
        if QA.custom == nil and d and d <= GA.REACH * 3 then
            GA.Advance()
            return
        end
        followTarget = nil
        GA.StopFollow()
        return
    end
    if d and d <= GA.REACH then GA.Advance() end
end

-- 6.84.5.0 (Wunsch): kleiner Knopf "Weiter" rechts am Questpfeil - nur
-- solange einer Farmroute gefolgt wird und der Pfeil steht. Ein normaler
-- Knopf (nichts Geschuetztes), klickbar auch im Kampf.
local Paint    -- Pille malen (weiter unten, Farm-Leiste)
function GA.SyncSkipButton()
    local qa = _G.WeintCodexQuestArrow
    local want = GA.following and type(qa) == "table" and qa.IsShown and qa:IsShown()
    local b = GA.skipButton
    if want and not b then
        -- 6.84.6.0 (Beta-Test mit Bild: "eckig"): Pille wie die Farm-Leiste.
        b = CreateFrame("Button", nil, UIParent)
        b:SetSize(70, 20)
        b:SetPoint("LEFT", qa, "RIGHT", 2, 18)
        b:SetFrameStrata("MEDIUM")
        b.text = K.NewText(b, 11)
        b.text:SetPoint("CENTER", b, "CENTER", 0, 0)
        b.text:SetText("Weiter ›")
        b.fill = b:CreateTexture(nil, "BACKGROUND")
        b.fill:SetPoint("TOPLEFT", b, "TOPLEFT", 10, 0)
        b.fill:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -10, 0)
        b.capL = b:CreateTexture(nil, "BACKGROUND")
        b.capL:SetSize(20, 20)
        b.capL:SetPoint("LEFT", b, "LEFT", 0, 0)
        b.capL:SetTexture(K.MEDIA .. "disc")
        b.capR = b:CreateTexture(nil, "BACKGROUND")
        b.capR:SetSize(20, 20)
        b.capR:SetPoint("RIGHT", b, "RIGHT", 0, 0)
        b.capR:SetTexture(K.MEDIA .. "disc")
        b:SetScript("OnClick", function() GA.Skip() end)
        b:SetScript("OnEnter", function(self)
            local tt = _G.GameTooltip
            if not tt then return end
            tt:SetOwner(self, "ANCHOR_RIGHT")
            tt:SetText("Halt überspringen", 1, 1, 1)
            tt:AddLine("Der Pfeil zeigt zum nächsten Halt der Farmroute.", nil, nil, nil, true)
            tt:Show()
            Paint(self, true, true)
        end)
        b:SetScript("OnLeave", function(self)
            if _G.GameTooltip then _G.GameTooltip:Hide() end
            Paint(self, false, false)
        end)
        Paint(b, false, false)
        GA.skipButton = b
    end
    if b then b:SetShown(want and true or false) end
end

local followFrame = CreateFrame("Frame")
followFrame:Hide()
local fAcc = 0
followFrame:SetScript("OnUpdate", K.Measured("Sammel-Atlas: Route folgen", function(_, el)
    fAcc = fAcc + (el or 0)
    if fAcc < GA.FOLLOW_TICK then return end
    fAcc = 0
    GA.CheckFollow()
    GA.SyncSkipButton()
end))
GA.followFrame = followFrame

--------------------------------------------------
-- Erkennen
--------------------------------------------------

GA.last = {}            -- letzte Erkennung (fuer /wcui prüfen)
GA.stats = { gathered = 0, sent = 0, received = 0, rejected = 0 }
local tracker = {}      -- laufender Sammelversuch

local function InInstance()
    if not _G.IsInInstance then return false end
    local ok, inst = pcall(_G.IsInInstance)
    return ok and K.Bool(inst, true) or false
end
GA.InInstance = InInstance

-- objectID aus einer GUID "GameObject-0-...-<objectID>-<spawn>", oder nil.
function GA.ObjectID(guid)
    if type(guid) ~= "string" then return nil end
    local id = guid:match("^GameObject%-%d+%-%d+%-%d+%-%d+%-(%d+)%-")
    id = tonumber(id)
    return (id and id > 0) and id or nil
end

function GA.OnSent(unit, target, castGUID, spellID)
    unit, target, castGUID, spellID = K.Plain(unit), K.Plain(target), K.Plain(castGUID), K.Plain(spellID)
    if unit ~= "player" then return end
    local kind = GA.SPELLS[spellID]
    if not kind then return end
    for k in pairs(tracker) do tracker[k] = nil end
    if InInstance() then GA.last.where = "Instanz" return end
    local map = K.BestMap()
    local x, y
    if map then x, y = K.PlayerMapXY(map) end
    if not (map and x) then GA.last.where = "Lage unbekannt" return end
    tracker.kind, tracker.spell, tracker.cast = kind, spellID, castGUID
    tracker.target = (type(target) == "string" and target ~= "") and target or nil
    tracker.map, tracker.x, tracker.y = map, x, y
    GA.last.spell, GA.last.target, GA.last.where = spellID, tracker.target ~= nil, "ok"
    GA.last.guid, GA.last.objectID = nil, nil
end

function GA.OnSucceeded(unit, castGUID, spellID)
    unit, castGUID, spellID = K.Plain(unit), K.Plain(castGUID), K.Plain(spellID)
    if unit ~= "player" or not tracker.spell or spellID ~= tracker.spell then return end
    if tracker.cast and castGUID ~= tracker.cast then return end
    tracker.at = Now()
    -- Kommt keine Beute (voll, schon leer): nach dem Fenster mit dem Namen.
    if tracker.kind ~= "fish" and _G.C_Timer and _G.C_Timer.After then
        _G.C_Timer.After(GA.LOOT_WINDOW + 0.1, GA.Expire)
    end
end

function GA.OnFailed(unit, castGUID)
    unit, castGUID = K.Plain(unit), K.Plain(castGUID)
    if unit == "player" and tracker.cast and castGUID == tracker.cast and not tracker.at then
        for k in pairs(tracker) do tracker[k] = nil end
    end
end

-- Den laufenden Versuch als Stelle merken (key: objectID oder Name).
local function Commit(key, name)
    local kind, map, x, y = tracker.kind, tracker.map, tracker.x, tracker.y
    for k in pairs(tracker) do tracker[k] = nil end
    if not key then GA.last.result = "ohne Namen und Nummer – nicht gemerkt" return nil end
    local p, fresh = GA.Record(map, key, x, y, kind, name, false)
    if not p then GA.last.result = "nicht gemerkt (voll oder ungültig)" return nil end
    GA.stats.gathered = GA.stats.gathered + 1
    GA.last.result = fresh and "neue Stelle" or "bekannte Stelle"
    if fresh then GA.Share(map, key, p.x, p.y, kind) end
    -- Am Halt der Route gesammelt: weiter.
    if GA.following == map then
        local r = GA.Route(map)
        local s = r and r.stops[GA.step]
        if s and math.abs(s[1] - x) < 0.01 and math.abs(s[2] - y) < 0.01 then GA.Advance() end
    end
    return p
end

function GA.Expire()
    if tracker.at and tracker.kind ~= "fish" and Now() - tracker.at >= GA.LOOT_WINDOW then
        Commit(tracker.target, tracker.target)
    end
end

-- Nur Questbeute (Questobjekt mit "Oeffnen")?
local function OnlyQuestLoot(n)
    if not _G.GetLootSlotInfo then return false end
    for i = 1, n do
        local ok, _, _, _, _, _, _, isQuest = pcall(_G.GetLootSlotInfo, i)
        if not ok or not K.Bool(isQuest, false) then return false end
    end
    return n > 0
end

function GA.OnLootOpened()
    -- 6.82.1.0 (Messung /wcui prüfen: "Beutequelle: noch keine Beute" nach
    -- zwei Kraeutern): die Beute kann vor UNIT_SPELLCAST_SUCCEEDED kommen
    -- (und mit Schnellpluendern als LOOT_READY). Laeuft ein Sammelzauber,
    -- zaehlt sie ab jetzt; je Versuch nur einmal.
    if not tracker.spell or tracker.looted then return end
    if not tracker.at then tracker.at = Now() end
    tracker.looted = true
    local window = tracker.kind == "fish" and GA.FISH_WINDOW or GA.LOOT_WINDOW
    if Now() - tracker.at > window then for k in pairs(tracker) do tracker[k] = nil end return end
    local n = _G.GetNumLootItems and K.Plain(_G.GetNumLootItems())
    n = type(n) == "number" and n or 0
    local guid
    if n > 0 and _G.GetLootSourceInfo then
        local ok, g = pcall(_G.GetLootSourceInfo, 1)
        if ok then
            if K.IsSecret(g) then GA.last.guid = "geheim" else guid = g end
        end
    end
    local id = GA.ObjectID(guid)
    GA.last.guid = guid and (id and "GameObject" or "andere Quelle") or GA.last.guid or "keine"
    GA.last.objectID = id
    if tracker.kind == "fish" then
        local fishing = _G.IsFishingLoot and K.Bool(_G.IsFishingLoot(), false)
        if not (fishing and id and id ~= GA.BOBBER) then
            for k in pairs(tracker) do tracker[k] = nil end
            GA.last.result = "Angeln ohne Schwarm – nicht gemerkt"
            return
        end
    elseif tracker.kind == "chest" and OnlyQuestLoot(n) then
        for k in pairs(tracker) do tracker[k] = nil end
        GA.last.result = "nur Questbeute – nicht gemerkt"
        return
    end
    Commit(id or tracker.target, tracker.target)
end

--------------------------------------------------
-- Stilles Teilen mit der Gilde
--------------------------------------------------

GA.PREFIX = "WCGA"
GA.SEND_GAP = 1.0
GA.QUEUE_MAX = 30
GA.RATE_WINDOW = 60
GA.RATE_MAX = 30          -- Nachrichten je Absender und Minute
GA.SENDER_MAX = 200
GA.MSG_MAX = 96
-- 6.83.2.0 (Gildentest: "er sieht meine Bluemchen nicht"): geteilt wurde
-- nur, was beim Sammeln eine Objektnummer hatte, und nur in dem Moment.
-- Jetzt auch nach Name ("t,...") und der eigene Bestand langsam nach dem
-- Einloggen und alle GA.BACKLOG_EVERY s (GA.BACKLOG_GAP je Zeile).
GA.BACKLOG_MAX = 400
GA.BACKLOG_GAP = 2.0
GA.BACKLOG_EVERY = 1800
GA.NAME_MAX = 40

local queue = {}
GA.queue = queue
local senders = {}        -- [Name] = { t0, count }
local senderN = 0

function GA.Format(mapID, objectID, x, y, kind)
    local s = "n," .. mapID .. "," .. objectID .. "," .. math.floor(x * 10000 + 0.5) .. "," .. math.floor(y * 10000 + 0.5)
    if kind and GA.KIND_CODE[kind] then s = s .. "," .. GA.KIND_CODE[kind] end
    return s
end

-- Ohne Objektnummer: nach Name, die Art ist dann Pflicht.
function GA.FormatName(mapID, name, x, y, kind)
    return "t," .. mapID .. "," .. GA.KIND_CODE[kind] .. "," .. math.floor(x * 10000 + 0.5) .. ","
        .. math.floor(y * 10000 + 0.5) .. "," .. name
end

-- Eine empfangene Zeile pruefen. Gibt mapID, objectID (oder Name), x, y,
-- kind|nil zurueck - oder nil.
function GA.Parse(text)
    if type(text) ~= "string" or #text > GA.MSG_MAX then return nil end
    if text:sub(1, 2) == "t," then
        local m, k, x, y, name = text:match("^t,(%d+),(%a),(%d+),(%d+),(.+)$")
        m, x, y = tonumber(m), tonumber(x), tonumber(y)
        local kind = k and GA.CODE_KIND[k]
        if not (m and x and y and kind and name) then return nil end
        if m < 1 or m > 100000 or x > 10000 or y > 10000 then return nil end
        if #name > GA.NAME_MAX or name:find("[%c|]") then return nil end
        return m, name, x / 10000, y / 10000, kind
    end
    local m, o, x, y, k = text:match("^n,(%d+),(%d+),(%d+),(%d+),?(%a?)$")
    m, o, x, y = tonumber(m), tonumber(o), tonumber(x), tonumber(y)
    if not (m and o and x and y) then return nil end
    if m < 1 or m > 100000 or o < 1 or o > 10000000 or x > 10000 or y > 10000 then return nil end
    local kind
    if k and k ~= "" then
        kind = GA.CODE_KIND[k]
        if not kind then return nil end
    end
    return m, o, x / 10000, y / 10000, kind
end

local function InCombat()
    return _G.InCombatLockdown and K.Bool(_G.InCombatLockdown(), true) or false
end
local function InGuild()
    return _G.IsInGuild and K.Bool(_G.IsInGuild(), false) or false
end

local function Line(mapID, key, x, y, kind)
    if type(key) == "number" then return GA.Format(mapID, key, x, y, kind) end
    if type(key) == "string" and GA.KIND_CODE[kind or ""] and #key <= GA.NAME_MAX and not key:find("[%c|]") then
        return GA.FormatName(mapID, key, x, y, kind)
    end
end
GA.Line = Line

function GA.Share(mapID, objectID, x, y, kind)
    if not (GA.Sharing() and InGuild()) or #queue >= GA.QUEUE_MAX then return false end
    local line = Line(mapID, objectID, x, y, kind)
    if not line then return false end
    queue[#queue + 1] = line
    if GA.sendFrame then GA.sendFrame:Show() end
    return true
end

-- Eigener Bestand, langsam hinterher (nur eigene Stellen, nie Geteiltes).
local backlog = {}
GA.backlog = backlog
function GA.QueueBacklog()
    for i = #backlog, 1, -1 do backlog[i] = nil end
    if not (GA.Sharing() and InGuild()) then return 0 end
    local g = GA.Store()
    for mapID, m in pairs(g and g.nodes or {}) do
        for key, list in pairs(m) do
            local kind = g.kinds[key]
            for _, p in ipairs(list) do
                if not p.s and #backlog < GA.BACKLOG_MAX then
                    local line = Line(mapID, key, p.x, p.y, kind)
                    if line then backlog[#backlog + 1] = line end
                end
            end
        end
    end
    if #backlog > 0 and GA.sendFrame then GA.sendFrame:Show() end
    return #backlog
end

local nextSend = 0
function GA.SendNext(now)
    if #queue == 0 and #backlog > 0 then
        if now < nextSend or InCombat() then return false end
        local cc = _G.C_ChatInfo
        if not (cc and cc.SendAddonMessage and GA.Sharing()) then
            for i = #backlog, 1, -1 do backlog[i] = nil end
            return true
        end
        local ok, res = pcall(cc.SendAddonMessage, GA.PREFIX, backlog[#backlog], "GUILD")
        if ok and (res == nil or res == true or res == 0) then
            backlog[#backlog] = nil
            GA.stats.sent = GA.stats.sent + 1
            nextSend = now + GA.BACKLOG_GAP
        else
            nextSend = now + 5
        end
        return #backlog == 0
    end
    if #queue == 0 then return true end
    if now < nextSend or InCombat() then return false end
    local cc = _G.C_ChatInfo
    if not (cc and cc.SendAddonMessage and GA.Sharing()) then
        for i = #queue, 1, -1 do queue[i] = nil end
        return true
    end
    local ok, res = pcall(cc.SendAddonMessage, GA.PREFIX, queue[1], "GUILD")
    if ok and (res == nil or res == true or res == 0) then
        table.remove(queue, 1)
        GA.stats.sent = GA.stats.sent + 1
        nextSend = now + GA.SEND_GAP
    else
        nextSend = now + 5
    end
    return #queue == 0
end

local sendFrame = CreateFrame("Frame")
sendFrame:Hide()
local sAcc = 0
sendFrame:SetScript("OnUpdate", K.Measured("Sammel-Atlas: teilen", function(self, el)
    sAcc = sAcc + (el or 0)
    if sAcc < 0.25 then return end
    sAcc = 0
    if GA.SendNext(Now()) then self:Hide() end
end))
GA.sendFrame = sendFrame

local function MyName()
    local n = _G.UnitName and K.Plain(_G.UnitName("player"))
    return type(n) == "string" and n or "?"
end

-- Takt je Absender: hoechstens GA.RATE_MAX je GA.RATE_WINDOW s.
function GA.Allow(sender, now)
    local r = senders[sender]
    if not r then
        if senderN >= GA.SENDER_MAX then return false end
        r = { now, 0 }
        senders[sender] = r
        senderN = senderN + 1
    end
    if now - r[1] > GA.RATE_WINDOW then r[1], r[2] = now, 0 end
    r[2] = r[2] + 1
    return r[2] <= GA.RATE_MAX
end

function GA.OnAddonMessage(prefix, text, channel, sender, now)
    prefix, text, channel, sender = K.Plain(prefix), K.Plain(text), K.Plain(channel), K.Plain(sender)
    if prefix ~= GA.PREFIX or channel ~= "GUILD" or type(sender) ~= "string" or not GA.Sharing() then return false end
    local short = sender:match("^([^%-]+)") or sender
    if short == MyName() then return false end
    if not GA.Allow(short, type(now) == "number" and now or Now()) then
        GA.stats.rejected = GA.stats.rejected + 1
        return false
    end
    local m, o, x, y, kind = GA.Parse(text)
    if not m then GA.stats.rejected = GA.stats.rejected + 1 return false end
    local p, fresh = GA.Record(m, o, x, y, kind, nil, true)
    if fresh then GA.stats.received = GA.stats.received + 1 end
    return p ~= nil
end

--------------------------------------------------
-- Weltkarte: Symbole und Route
--------------------------------------------------

local function QM() return WeintCodex.QuestMap end
local pins, lines = {}, {}
GA.pins, GA.lines = pins, lines
local entries = {}      -- [mapID] = { version, list } - fuer Welt- und Minikarte
local routeEntries = {} -- [mapID] = { version, list }

-- Eintraege einer Karte (eigene Tabellen, nie die gespeicherten: die
-- Minikarte merkt sich an ihnen die Weltlage).
function GA.Entries(mapID)
    local c = entries[mapID]
    if c and c.version == GA.version then return c.list end
    local list = {}
    local g = GA.Store()
    for key, pts in pairs(g and g.nodes[mapID] or {}) do
        local kind = g.kinds[key]
        if kind then
            for _, p in ipairs(pts) do
                list[#list + 1] = { x = p.x, y = p.y, kind = kind, key = key, p = p }
            end
        end
    end
    entries[mapID] = { version = GA.version, list = list }
    return list
end

function GA.RouteEntries(mapID)
    local c = routeEntries[mapID]
    if c and c.version == GA.version then return c.list end
    local list = {}
    local r = GA.Route(mapID)
    for i, s in ipairs(r and r.stops or {}) do list[i] = { x = s[1], y = s[2] } end
    routeEntries[mapID] = { version = GA.version, list = list }
    return list
end

local function Tooltip(self)
    local gt, e = _G.GameTooltip, self.entry
    if not (gt and e) then return end
    gt:SetOwner(self, "ANCHOR_RIGHT")
    local t, n, m = C.textBright, C.textNormal, C.textMuted
    gt:SetText(GA.NameOf(e.key), t[1], t[2], t[3])
    local p = e.p
    if p.s then
        gt:AddLine("Von der Gilde", n[1], n[2], n[3])
    else
        gt:AddLine("Gesammelt: " .. (p.n or 0) .. "×", n[1], n[2], n[3])
    end
    if type(p.last) == "number" and p.last > 0 and _G.date then
        gt:AddLine("Zuletzt: " .. _G.date("%d.%m.%Y", p.last), n[1], n[2], n[3])
    end
    if GA.editing and not self.mini then
        gt:AddLine("Klick: zur Route oder aus der Route", m[1], m[2], m[3], true)
    end
    gt:Show()
end

local function NewPin(parent, size)
    local p = CreateFrame("Button", nil, parent)
    p:SetSize(size, size)
    p.icon = p:CreateTexture(nil, "ARTWORK")
    p.icon:SetAllPoints(p)
    p:SetScript("OnEnter", Tooltip)
    p:SetScript("OnLeave", function() if _G.GameTooltip then _G.GameTooltip:Hide() end end)
    p:Hide()
    return p
end

local function Dress(p, e)
    if p.entry == e then return end
    p.entry = e
    p.icon:SetTexture(p.mini and GA.MINI_RING or GA.MEDIA[e.kind])
    local c = GC[e.p.s and "gatherShared" or GA.KIND_COLOR[e.kind]]
    p.icon:SetVertexColor(c[1], c[2], c[3], p.mini and GA.MINI_ALPHA or 1)
end

local function OnPinClick(self)
    local e = self.entry
    if not (GA.editing and e and GA.shownMap) then return end
    GA.ToggleStop(GA.shownMap, e.x, e.y)
end

local holder
local function Holder(canvas)
    if not holder then
        holder = CreateFrame("Frame", nil, canvas)
        GA.holder = holder
    elseif holder:GetParent() ~= canvas then
        holder:SetParent(canvas)
    end
    holder:ClearAllPoints()
    holder:SetAllPoints(canvas)
    return holder
end

local function HidePins(from) for i = from or 1, #pins do pins[i]:Hide() end end
local function HideLines(from) for i = from or 1, #lines do lines[i]:Hide() end end

local function Line(i, parent, x1, y1, x2, y2, W, H, width, col, alpha)
    local l = lines[i]
    if not l then
        if not parent.CreateLine then return false end
        l = parent:CreateLine(nil, "OVERLAY")
        lines[i] = l
    end
    l:SetThickness(width)
    l:SetColorTexture(col[1], col[2], col[3], alpha)
    l:SetStartPoint("TOPLEFT", parent, x1 * W, -y1 * H)
    l:SetEndPoint("TOPLEFT", parent, x2 * W, -y2 * H)
    l:Show()
    return true
end

GA.shownMap, GA.shownCount = nil, 0
local sig = { map = nil, w = 0, h = 0, s = 0, v = -1, edit = false }

function GA.Place()
    local qm, wm = QM(), _G.WorldMapFrame
    if not (GA.Active() and qm and type(wm) == "table" and wm.IsShown and wm:IsShown()) then
        HidePins() HideLines()
        GA.shownMap, GA.shownCount, sig.map = nil, 0, nil
        return 0
    end
    local mapID = qm.CurrentMap and qm.CurrentMap()
    local canvas = qm.Canvas and qm.Canvas()
    if not (mapID and canvas) then HidePins() HideLines() return 0 end
    local w, h = K.Plain(canvas:GetWidth()), K.Plain(canvas:GetHeight())
    if type(w) ~= "number" or type(h) ~= "number" or w <= 1 or h <= 1 then return 0 end
    local s = 1
    local cs = K.Plain(canvas.GetEffectiveScale and canvas:GetEffectiveScale())
    local ms = K.Plain(wm.GetEffectiveScale and wm:GetEffectiveScale())
    if type(cs) == "number" and type(ms) == "number" and cs > 0 and ms > 0 then s = cs / ms end
    local edit = GA.editing and true or false
    if sig.map == mapID and sig.w == w and sig.h == h and sig.s == s and sig.v == GA.version and sig.edit == edit then
        return GA.shownCount
    end
    sig.map, sig.w, sig.h, sig.s, sig.v, sig.edit = mapID, w, h, s, GA.version, edit
    local hold = Holder(canvas)
    local ME = WeintCodex.UIMapEntrances
    local lvl = ME and ME.BaseLevel and ME.BaseLevel(canvas)
    if type(lvl) ~= "number" then lvl = (K.Plain(canvas:GetFrameLevel()) or 0) + 4 end
    hold:SetFrameLevel(lvl)
    -- Route darunter (Linien auf dem Halter).
    local route = GA.RouteEntries(mapID)
    local col, out = GC.gatherRoute, C.routeOutline
    local nl = 0
    local n = #route
    if n >= 2 then
        for i = 1, n do
            local a, b = route[i], route[i % n + 1]
            if n == 2 and i == 2 then break end
            nl = nl + 1
            Line(nl, hold, a.x, a.y, b.x, b.y, w, h, 5, out, out[4])
            nl = nl + 1
            Line(nl, hold, a.x, a.y, b.x, b.y, w, h, 2.5, col, 1)
        end
    end
    HideLines(nl + 1)
    local count = 0
    for _, e in ipairs(GA.Entries(mapID)) do
        if count >= GA.MAX_PINS then break end
        if GA.ShowsOnMap(e.kind) then
            count = count + 1
            local p = pins[count]
            if not p then
                p = NewPin(hold, GA.PIN)
                p:SetScript("OnClick", OnPinClick)
                pins[count] = p
            end
            if p:GetParent() ~= hold then p:SetParent(hold) end
            Dress(p, e)
            p:SetScale(1 / s)
            p:SetFrameLevel(lvl + 1)
            p:ClearAllPoints()
            p:SetPoint("CENTER", canvas, "TOPLEFT", w * e.x * s, -h * e.y * s)
            p:Show()
        end
    end
    HidePins(count + 1)
    GA.shownMap, GA.shownCount = mapID, count
    if GA.bar then GA.SyncBar() end
    return count
end

--------------------------------------------------
-- Leiste auf der Weltkarte: Route bearbeiten, aus der Zone, folgen, leeren
--------------------------------------------------

local function ViewMap()
    local qm, wm = QM(), _G.WorldMapFrame
    if qm and qm.CurrentMap and type(wm) == "table" and wm.IsShown and wm:IsShown() then
        local m = qm.CurrentMap()
        if m then return m end
    end
    return K.BestMap()
end
GA.ViewMap = ViewMap

function GA.CmdBuild()
    local map = ViewMap()
    local n = map and GA.BuildRoute(map, K.Get(KEY, "gaRouteKind") or "all") or 0
    Say(n > 0 and ("Farmroute mit " .. n .. " Halten.") or "Hier hast du noch nichts dieser Art gesammelt – keine Route.")
    return n
end
function GA.CmdEdit()
    GA.editing = not GA.editing
    if GA.editing then Say("Route bearbeiten: auf der Weltkarte Fundstellen anklicken – in dieser Reihenfolge. Noch einmal: fertig.") end
    sig.map = nil
end
function GA.CmdFollow()
    if GA.following then GA.StopFollow() return false end
    local map = ViewMap()
    if not GA.Follow(map) then Say("Auf dieser Karte gibt es keine Farmroute.") return false end
    return true
end
function GA.CmdClear()
    local map = ViewMap()
    if map then GA.ClearRoute(map) end
end

-- 6.82.1.0 (Beta-Test mit Bild: "die Knoepfe verdecken Koordinaten und
-- Spielerposition, man weiss nicht, wofuer sie stehen, eckig statt rund";
-- Wunsch: "unter Quests noch einen Balken mit Farmen", Kraeuter/Erz
-- waehlen und die Suche des Charakters stellt sich mit): eine zweite
-- Leiste unter dem Kartenfenster - unter der Quest-Leiste, sonst direkt
-- unter der Karte -, Pillen wie dort, jede mit Erklaerung beim Zeigen.
--   Kraeuter / Erz / Beides: was Karte und Route zeigen; Kraeuter oder Erz
--   stellen die Suche des Spiels fest um (der Wechsel ruht), Beides laesst
--   wieder wechseln.
--   Route erstellen / bearbeiten / folgen / loeschen.
GA.FARM = {
    { key = "herb", text = "Kräuter", tip = "Nur Kräuter auf Karte und Route. Stellt die Kräutersuche deines Charakters ein. Noch einmal klicken: ausblenden." },
    { key = "ore",  text = "Erz",     tip = "Nur Erz auf Karte und Route. Stellt die Mineraliensuche deines Charakters ein. Noch einmal klicken: ausblenden." },
    { key = "all",  text = "Beides",  tip = "Kräuter und Erz. Die Suche wechselt wieder zwischen beiden, wenn du das eingeschaltet hast. Noch einmal klicken: ausblenden." },
    { gap = true },
    { key = "build",  text = "Route erstellen", tip = "Kürzester Rundweg durch alle Fundstellen der Auswahl auf dieser Karte." },
    { key = "edit",   text = "Route ändern",    tip = "Fundstellen auf der Karte anklicken: hinzufügen oder entfernen, in Klickreihenfolge. Noch einmal klicken: fertig." },
    { key = "follow", text = "Route folgen",    tip = "Der Questpfeil führt von Halt zu Halt, im Kreis." },
    { key = "skip",   text = "Halt überspringen", tip = "Beim Folgen: diesen Halt auslassen, der Pfeil zeigt zum nächsten. Geht auch im Kampf – per Taste (Tastenbelegung → WeintCodex) oder /wcui weiter." },
    { key = "clear",  text = "Route löschen",   tip = "Die Farmroute dieser Karte entfernen." },
}

function GA.Choice()
    if K.Get(KEY, "gaMapHerb") == false and K.Get(KEY, "gaMapOre") == false then return "none" end
    local k = K.Get(KEY, "gaRouteKind") or "all"
    if k ~= "herb" and k ~= "ore" then k = "all" end
    return k
end

-- Auswahl setzen: Karte, Route und Suche des Spiels.
function GA.Choose(kind)
    -- 6.83.3.0 (Wunsch: "nochmal auf Kraeuter klicken blendet sie aus"):
    -- die gewaehlte Pille noch einmal - Kraeuter und Erz von der Karte,
    -- die Suche des Spiels bleibt, wie sie ist.
    if kind == GA.Choice() then
        K.Set(KEY, "gaMapHerb", false)
        K.Set(KEY, "gaMapOre", false)
        return
    end
    K.Set(KEY, "gaRouteKind", kind)
    K.Set(KEY, "gaMapHerb", kind ~= "ore")
    K.Set(KEY, "gaMapOre", kind ~= "herb")
    local GT = WeintCodex.UIGatherTrack
    if not GT then return end
    if kind == "all" then
        if GT.wasSwap ~= nil then K.Set(KEY, "gatherSwap", GT.wasSwap) GT.wasSwap = nil end
        return
    end
    if GT.wasSwap == nil then GT.wasSwap = K.Get(KEY, "gatherSwap") and true or false end
    K.Set(KEY, "gatherSwap", false)
    if _G.InCombatLockdown and K.Bool(_G.InCombatLockdown(), false) then return end
    local herb, ore = GT.Find and GT.Find()
    local want = kind == "herb" and herb or ore
    local _, _, set = GT.API and GT.API()
    if want and set then
        pcall(set, want, true)
    else
        Say(kind == "herb" and "Kräutersuche ist nicht gelernt." or "Mineraliensuche ist nicht gelernt.")
    end
end

local CHIP_H = 18
local function Chip(bar, f, x)
    local b = CreateFrame("Button", nil, bar)
    b.key, b.tip = f.key, f.tip
    b.text = K.NewText(b, 11)
    b.text:SetPoint("CENTER", b, "CENTER", 0, 0)
    b.text:SetText(f.text)
    local tw = K.Plain(b.text.GetStringWidth and b.text:GetStringWidth())
    local bw = (type(tw) == "number" and tw > 0 and tw or 70) + 22
    b:SetSize(bw, CHIP_H)
    b:SetPoint("LEFT", bar, "LEFT", x, 0)
    b.fill = b:CreateTexture(nil, "BACKGROUND")
    b.fill:SetPoint("TOPLEFT", b, "TOPLEFT", CHIP_H / 2, 0)
    b.fill:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -CHIP_H / 2, 0)
    b.capL = b:CreateTexture(nil, "BACKGROUND")
    b.capL:SetSize(CHIP_H, CHIP_H)
    b.capL:SetPoint("LEFT", b, "LEFT", 0, 0)
    b.capL:SetTexture(K.MEDIA .. "disc")
    b.capR = b:CreateTexture(nil, "BACKGROUND")
    b.capR:SetSize(CHIP_H, CHIP_H)
    b.capR:SetPoint("RIGHT", b, "RIGHT", 0, 0)
    b.capR:SetTexture(K.MEDIA .. "disc")
    b:SetScript("OnEnter", function(self)
        self._hot = true
        GA.SyncBar()
        local tt = _G.GameTooltip
        if tt then
            tt:SetOwner(self, "ANCHOR_TOP")
            tt:SetText(self.text:GetText() or "", 1, 1, 1)
            tt:AddLine(self.tip, nil, nil, nil, true)
            tt:Show()
        end
    end)
    b:SetScript("OnLeave", function(self)
        self._hot = nil
        GA.SyncBar()
        if _G.GameTooltip then _G.GameTooltip:Hide() end
    end)
    b:SetScript("OnClick", function(self)
        local k = self.key
        if k == "herb" or k == "ore" or k == "all" then GA.Choose(k)
        elseif k == "build" then GA.CmdBuild()
        elseif k == "edit" then GA.CmdEdit()
        elseif k == "follow" then GA.CmdFollow()
        elseif k == "skip" then GA.Skip()
        elseif k == "clear" then GA.CmdClear() end
        GA.SyncBar()
    end)
    return b, bw
end

Paint = function(b, on, hot)
    local a, base = K.Highlight(), WeintCodex.GameColors.kachelFill
    local r, g, bl
    if on then
        local k = hot and 0.55 or 0.40
        r, g, bl = base[1] + (a[1] - base[1]) * k, base[2] + (a[2] - base[2]) * k, base[3] + (a[3] - base[3]) * k
    else
        local s1 = hot and (C.borderStrong or C.surface3) or C.surface3
        r, g, bl = s1[1], s1[2], s1[3]
    end
    b.fill:SetColorTexture(r, g, bl, 1)
    b.capL:SetVertexColor(r, g, bl, 1)
    b.capR:SetVertexColor(r, g, bl, 1)
    local tc = on and C.textBright or C.textNormal
    b.text:SetTextColor(tc[1], tc[2], tc[3], on and 1 or 0.85)
end

function GA.SyncBar()
    local bar = GA.bar
    if not bar then return end
    local choice = GA.Choice()
    local map = ViewMap()
    local r = map and GA.Route(map)
    for _, b in ipairs(bar.chips) do
        local k, on = b.key, false
        if k == "herb" or k == "ore" or k == "all" then on = (k == choice)
        elseif k == "edit" then on = GA.editing and true or false
            b.text:SetText(GA.editing and "Fertig" or "Route ändern")
        elseif k == "follow" then on = GA.following and true or false
            b.text:SetText(GA.following and "Folgen beenden" or "Route folgen")
        end
        Paint(b, on, b._hot)
    end
    local n = r and r.stops and #r.stops or 0
    bar.info:SetText(n > 0 and ("Route: " .. n .. " Halte") or "Noch keine Route")
    -- Unter der Quest-Leiste, wenn sie steht; sonst direkt unter der Karte.
    local QH, wm = WeintCodex.UIQuestHelper, _G.WorldMapFrame
    local qb = QH and QH.bar
    local below = (qb and qb.IsShown and qb:IsShown()) and qb or wm
    if bar._below ~= below then
        bar:ClearAllPoints()
        bar:SetPoint("TOPLEFT", below, "BOTTOMLEFT", 0, -4)
        bar._below = below
    end
end

local function EnsureBar()
    if GA.bar then return GA.bar end
    local wm = _G.WorldMapFrame
    if type(wm) ~= "table" then return nil end
    local bar = CreateFrame("Frame", "WeintCodexFarmBar", wm)
    if bar.SetClampedToScreen then bar:SetClampedToScreen(true) end
    bar:SetHeight(28)
    bar:SetFrameStrata("HIGH")
    bar.kachel = K.Kachel(bar, { shadow = 3 })
    bar.mark = bar:CreateTexture(nil, "ARTWORK")
    bar.mark:SetSize(16, 16)
    bar.mark:SetPoint("LEFT", bar, "LEFT", 8, 0)
    bar.mark:SetTexture(K.MEDIA .. "gather_herb")
    local hc = WeintCodex.GameColors.gatherHerb
    if hc then bar.mark:SetVertexColor(hc[1], hc[2], hc[3], 1) end
    bar.title = K.NewText(bar, 12)
    bar.title:SetFont(WeintCodex.Fonts.sansSemi, 12, "")
    bar.title:SetPoint("LEFT", bar.mark, "RIGHT", 4, 0)
    bar.title:SetText("Farmen")
    local tc = C.textBright
    bar.title:SetTextColor(tc[1], tc[2], tc[3], 1)
    bar.chips = {}
    local x = 8 + 16 + 4 + 54
    for _, f in ipairs(GA.FARM) do
        if f.gap then
            x = x + 10
        else
            local b, w = Chip(bar, f, x)
            bar.chips[#bar.chips + 1] = b
            x = x + w + 4
        end
    end
    bar.info = K.NewText(bar, 11)
    bar.info:SetPoint("LEFT", bar, "LEFT", x + 6, 0)
    local mc = C.textMuted
    bar.info:SetTextColor(mc[1], mc[2], mc[3], 1)
    bar:SetWidth(x + 110)
    GA.bar = bar
    GA.SyncBar()
    return bar
end
GA.EnsureBar = EnsureBar

local driver
local function EnsureDriver()
    if driver then return driver end
    local wm = _G.WorldMapFrame
    if type(wm) ~= "table" then return nil end
    driver = CreateFrame("Frame", nil, wm)
    local acc = 0
    driver:SetScript("OnUpdate", K.Measured("Karte: Sammel-Atlas", function(_, el)
        acc = acc + (el or 0)
        if acc < GA.TICK then return end
        acc = 0
        GA.Place()
    end))
    driver:SetScript("OnHide", function() HidePins() HideLines() sig.map = nil end)
    GA.driver = driver
    EnsureBar()
    return driver
end
GA.EnsureDriver = EnsureDriver

--------------------------------------------------
-- Minikarte
--------------------------------------------------

local mmPins, mmLines = {}, {}
GA.mmPins = mmPins
local mmHolder
local function MMHide(from)
    for i = from or 1, #mmPins do mmPins[i]:Hide() end
end
local function MMHideLines(from)
    for i = from or 1, #mmLines do mmLines[i]:Hide() end
end

function GA.MinimapActive()
    if not GA.Active() then return false end
    for _, k in ipairs(GA.KINDS) do if GA.ShowsOnMini(k) then return true end end
    return GA.following ~= nil
end

function GA.PlaceMinimap()
    local mm, QH = _G.Minimap, WeintCodex.UIQuestHelper
    if not (GA.MinimapActive() and QH and QH.MinimapOffset and type(mm) == "table" and mm.IsShown and mm:IsShown()) then
        MMHide() MMHideLines()
        return 0
    end
    local mapID = K.BestMap()
    local yards = QH.MinimapYards()
    local pc, pn, pw = K.PlayerWorld()
    local w = K.Plain(mm:GetWidth())
    if not (mapID and yards and pc and type(w) == "number" and w > 1) then MMHide() MMHideLines() return 0 end
    local facing
    if _G.GetCVar and K.Plain(_G.GetCVar("rotateMinimap")) == "1" and _G.GetPlayerFacing then
        facing = K.Plain(_G.GetPlayerFacing())
        if type(facing) ~= "number" then MMHide() MMHideLines() return 0 end
    end
    local square = K.IsActive("minimap") and K.Get("minimap", "square") and true or false
    local half = w / 2
    if not mmHolder then
        mmHolder = CreateFrame("Frame", nil, mm)
        mmHolder:SetAllPoints(mm)
        GA.mmHolder = mmHolder
    end
    mmHolder:SetFrameLevel((K.Plain(mm:GetFrameLevel()) or 0) + 5)
    -- Route: Abschnitte, deren beide Enden auf der Minikarte liegen.
    local nl = 0
    local route = GA.following == mapID and GA.RouteEntries(mapID) or nil
    local n = route and #route or 0
    for i = 1, n do
        local a, b = route[i], route[i % n + 1]
        local ax, ay = QH.MinimapOffset(a, mapID, pc, pn, pw, yards, half, facing, square)
        local bx, by = QH.MinimapOffset(b, mapID, pc, pn, pw, yards, half, facing, square)
        if ax and bx and mmHolder.CreateLine then
            nl = nl + 1
            local l = mmLines[nl]
            if not l then l = mmHolder:CreateLine(nil, "OVERLAY") mmLines[nl] = l end
            local c = GC.gatherRoute
            l:SetThickness(2)
            l:SetColorTexture(c[1], c[2], c[3], 0.9)
            l:SetStartPoint("CENTER", mmHolder, ax, ay)
            l:SetEndPoint("CENTER", mmHolder, bx, by)
            l:Show()
        end
    end
    MMHideLines(nl + 1)
    local count = 0
    for _, e in ipairs(GA.Entries(mapID)) do
        if count >= GA.MAX_MINI then break end
        if GA.ShowsOnMini(e.kind) then
            local dx, dy = QH.MinimapOffset(e, mapID, pc, pn, pw, yards, half, facing, square)
            if dx then
                count = count + 1
                local p = mmPins[count]
                if not p then
                    p = NewPin(mmHolder, GA.MINI_PIN)
                    p.mini = true
                    if p.EnableMouseClicks then p:EnableMouseClicks(false) end
                    if p.EnableMouseMotion then p:EnableMouseMotion(true) end
                    mmPins[count] = p
                end
                Dress(p, e)
                p:SetFrameLevel((K.Plain(mmHolder:GetFrameLevel()) or 0) + 1)
                p:ClearAllPoints()
                p:SetPoint("CENTER", mmHolder, "CENTER", dx, dy)
                -- 6.84.3.0 (Wunsch): naht der Spielerpfeil, blendet der Ring
                -- weich aus - ab GA.MINI_FADE Bildpunkten, ganz weg bei
                -- GA.MINI_GONE.
                local r = math.sqrt(dx * dx + dy * dy)
                local a = (r - GA.MINI_GONE) / (GA.MINI_FADE - GA.MINI_GONE)
                p:SetAlpha(a >= 1 and 1 or (a <= 0 and 0 or a))
                p:Show()
            end
        end
    end
    MMHide(count + 1)
    return count
end

local mmTicker = CreateFrame("Frame")
mmTicker:Hide()
local mmAcc = 0
mmTicker:SetScript("OnUpdate", K.Measured("Minikarte: Sammel-Atlas", function(_, el)
    mmAcc = mmAcc + (el or 0)
    if mmAcc < GA.MM_TICK then return end
    mmAcc = 0
    GA.PlaceMinimap()
end))
GA.mmTicker = mmTicker

--------------------------------------------------
-- Ereignisse und Schalter
--------------------------------------------------

local ev = CreateFrame("Frame")
GA.events = ev
ev:SetScript("OnEvent", K.Measured("Sammel-Atlas", function(_, event, a, b, c, d)
    if event == "UNIT_SPELLCAST_SENT" then GA.OnSent(a, b, c, d)
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then GA.OnSucceeded(a, b, c)
    elseif event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" then GA.OnFailed(a, b)
    elseif event == "LOOT_OPENED" or event == "LOOT_READY" then GA.OnLootOpened()
    elseif event == "CHAT_MSG_ADDON" then GA.OnAddonMessage(a, b, c, d)
    elseif event == "ADDON_LOADED" then
        if a == "Blizzard_WorldMap" then EnsureDriver() end
    elseif event == "PLAYER_ENTERING_WORLD" then
        if not GA.backlogTicker and _G.C_Timer and _G.C_Timer.After then
            GA.backlogTicker = true
            _G.C_Timer.After(30, GA.QueueBacklog)
            if _G.C_Timer.NewTicker then _G.C_Timer.NewTicker(GA.BACKLOG_EVERY, GA.QueueBacklog) end
        end
    end
end))

local EVENTS = { "UNIT_SPELLCAST_SENT", "UNIT_SPELLCAST_SUCCEEDED", "UNIT_SPELLCAST_FAILED",
                 "UNIT_SPELLCAST_INTERRUPTED", "LOOT_OPENED", "LOOT_READY", "ADDON_LOADED",
                 "PLAYER_ENTERING_WORLD" }

function GA.Apply()
    Changed()
    sig.map = nil
    for _, p in ipairs(pins) do p.entry = nil end
    for _, p in ipairs(mmPins) do p.entry = nil end
    local on = GA.Active()
    for _, e in ipairs(EVENTS) do
        if on then pcall(ev.RegisterEvent, ev, e) else pcall(ev.UnregisterEvent, ev, e) end
    end
    if GA.Sharing() then
        local cc = _G.C_ChatInfo
        if cc and cc.RegisterAddonMessagePrefix then pcall(cc.RegisterAddonMessagePrefix, GA.PREFIX) end
        pcall(ev.RegisterEvent, ev, "CHAT_MSG_ADDON")
    else
        pcall(ev.UnregisterEvent, ev, "CHAT_MSG_ADDON")
        for i = #queue, 1, -1 do queue[i] = nil end
    end
    if on then
        EnsureDriver()
        if GA.bar then GA.bar:Show() end
    else
        GA.editing = false
        if GA.following then GA.StopFollow() end
        if GA.bar then GA.bar:Hide() end
        HidePins() HideLines()
    end
    mmTicker:SetShown(GA.MinimapActive())
    if not GA.MinimapActive() then MMHide() MMHideLines() end
end

--------------------------------------------------
-- Bericht (/wcui prüfen) und Seite
--------------------------------------------------

function GA.StatusLines()
    local out = {}
    local g = GA.Store()
    local maps, pts, shared = 0, 0, 0
    for _, m in pairs(g and g.nodes or {}) do
        maps = maps + 1
        for _, list in pairs(m) do
            for _, p in ipairs(list) do
                pts = pts + 1
                if p.s then shared = shared + 1 end
            end
        end
    end
    out[#out + 1] = string.format("Fundstellen: %d auf %d Karten (von der Gilde: %d) · gesammelt in dieser Sitzung: %d",
        pts, maps, shared, GA.stats.gathered)
    local L = GA.last
    if L.spell then
        out[#out + 1] = "Letzte Erkennung: Zauber " .. tostring(L.spell)
            .. " · Ziel aus dem Zauber: " .. (L.target and "ja" or "nein")
            .. " · Beutequelle: " .. tostring(L.guid or "noch keine Beute")
            .. (L.objectID and (" (Objekt " .. L.objectID .. ")") or "")
            .. " · " .. tostring(L.result or "offen")
    else
        out[#out + 1] = "Letzte Erkennung: noch nichts gesammelt" .. (L.where and (" (" .. L.where .. ")") or "")
    end
    out[#out + 1] = string.format("Gilde: %s · gesendet %d · empfangen %d · abgewiesen %d",
        GA.Sharing() and "teilen an" or "teilen aus", GA.stats.sent, GA.stats.received, GA.stats.rejected)
    return out
end

GA.ROUTE_KINDS = {
    { value = "all", text = "Alles" }, { value = "herb", text = "Kräuter" },
    { value = "ore", text = "Erz" }, { value = "chest", text = "Truhen" }, { value = "fish", text = "Fischschwärme" },
}

function GA.BuildRows(B)
    local off = function() return not K.Get(KEY, "gatherAtlas") end
    B:Section("Sammel-Atlas", "Merkt sich jede Stelle, an der du Kräuter, Erz, Truhen oder Fischschwärme gesammelt hast – auf Welt- und Minikarte, mit Farmroute. WeintCodex bringt keine Fundstellen mit: nur, was du (oder deine Gilde) selbst gesammelt hast.")
    B:Row({ type = "toggle", label = "Sammel-Atlas", key = "gatherAtlas",
            description = "Nicht in Instanzen. Maus auf ein Symbol: Name, wie oft, zuletzt." },
          { type = "toggle", label = "Mit der Gilde teilen", key = "gatherShare", disabled = off,
            description = "Still, ohne Chatzeile: nur Karte, Objektnummer und Lage einer neuen Stelle. Von der Gilde Gefundenes steht grau." })
    B:Row({ type = "toggle", label = "Weltkarte: Kräuter", key = "gaMapHerb", disabled = off },
          { type = "toggle", label = "Weltkarte: Erz", key = "gaMapOre", disabled = off })
    B:Row({ type = "toggle", label = "Weltkarte: Truhen", key = "gaMapChest", disabled = off },
          { type = "toggle", label = "Weltkarte: Fischschwärme", key = "gaMapFish", disabled = off })
    B:Row({ type = "dropdown", label = "Farmroute aus", key = "gaRouteKind", items = GA.ROUTE_KINDS, disabled = off },
          { type = "button", label = "Farmroute", text = "Route aus dieser Zone", disabled = off,
            onClick = function() GA.CmdBuild() end,
            description = "Fasst nahe Stellen zusammen und legt einen kurzen Rundweg hindurch." })
    B:Row({ type = "button", label = "Von Hand", text = function() return GA.editing and "Fertig" or "Route bearbeiten" end,
            disabled = off, onClick = function() GA.CmdEdit() end,
            description = "Dann auf der Weltkarte Fundstellen anklicken – in dieser Reihenfolge; noch einmal: wieder heraus." },
          { type = "button", label = "Questpfeil", text = function() return GA.following and "Nicht mehr folgen" or "Route folgen" end,
            disabled = off, onClick = function() GA.CmdFollow() end,
            description = "Der Pfeil zeigt zum nächsten Halt; dort angekommen oder gesammelt: weiter, im Kreis." })
    B:Row({ type = "button", label = "Route", text = "Route leeren", disabled = off, onClick = function() GA.CmdClear() end },
          { type = "empty" })
    B:Advanced()
    B:Row({ type = "toggle", label = "Minikarte: Kräuter", key = "gaMiniHerb", disabled = off },
          { type = "toggle", label = "Minikarte: Erz", key = "gaMiniOre", disabled = off })
    B:Row({ type = "toggle", label = "Minikarte: Truhen", key = "gaMiniChest", disabled = off },
          { type = "toggle", label = "Minikarte: Fischschwärme", key = "gaMiniFish", disabled = off })
    B:EndAdvanced()
end

local mod = K.Module(KEY)
if mod then
    for k, v in pairs(GA.DEFAULTS) do
        if mod.defaults[k] == nil then mod.defaults[k] = v end
    end
    -- Auf der Seite "Sammeln" (ui/gathertrack.lua) unter dem Wechsel der Suche.
    for _, pg in ipairs(mod.pages) do
        if pg.key == "sammeln" and not pg.atlas then
            local base = pg.build
            pg.build = function(B) base(B) GA.BuildRows(B) end
            pg.atlas = true
        end
    end
end

K.Listen(function(kind, key)
    if (kind == "active" or kind == "setting") and key == KEY then GA.Apply() end
end)
