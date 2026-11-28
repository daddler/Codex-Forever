--------------------------------------------------
-- WeintCodex :: Komfort - eigene Lage auf der Dungeonkarte (1.0.10.6)
--------------------------------------------------
-- Wunsch: "dass der Spieler sehen kann, wo man in der Dungeon gerade steht".
-- In Instanzen nennt der Client einem Addon keine Lage (UnitPosition und
-- GetPlayerMapPosition schweigen, /wcui dungeonkarte misst das). Was er
-- nennt: die Entfernung im Raum zum Ziel, das die Navigation gerade
-- verfolgt (C_Navigation.GetDistance). Verfolgt die Navigation nacheinander
-- mehrere Flugmeister, deren Lage in der Welt bekannt ist, ergibt sich aus
-- vier und mehr Entfernungen die eigene Lage (Trilateration, kleinste
-- Quadrate, danach Gauss-Newton). Die Idee stammt aus MapUtils (GPL-3.0),
-- der Code ist eigener; die Zahlen stehen in data/dungeonpos.lua.
--
-- VORSICHT, darum eng begrenzt: dafuer stellt das Modul die Zielverfolgung
-- des Spiels kurz um (C_SuperTrack). Ein solcher Aufruf aus einem Addon hat
-- 6.6.0.1 die Questverfolgung "beruehrt" (im Kampf ADDON_ACTION_BLOCKED,
-- ui/questarrow.lua). Darum:
--   * nur bei offener Dungeonkarte (ui/dungeonmap.lua fragt an), sonst nie;
--   * nie im Kampf - beginnt einer, endet die Messung sofort
--     (PLAYER_REGEN_DISABLED kommt vor der Sperre) und die vorige
--     Verfolgung (Kartenmarke, eigener Wegpunkt) kommt zurueck;
--   * nie, solange das Spiel eine Quest verfolgt - die liesse sich nur mit
--     SetSuperTrackedQuestID zurueckgeben, und das ist verboten (6.6.0.1);
--   * jede Aenderung ueber K.QuietMap (die Weltkarte hoert nicht zu);
--   * die Bildschirmmarke der Navigation ist waehrenddessen ausgeblendet;
--   * Schalter "Eigene Lage" auf der Seite "Karte".
-- Unbekannt bleibt unbekannt: weniger als vier frische Entfernungen oder ein
-- zu grosser Rest der Rechnung -> kein Punkt, nie ein geratener.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIDungeonPos = {}

local DP = WeintCodex.UIDungeonPos
local K = WeintCodex.UIKit

DP.STEP = 0.05        -- s: so lange mindestens je Messpunkt
DP.TIMEOUT = 0.4      -- s: dann gilt der Messpunkt als stumm
DP.MAX_AGE = 1.6      -- s: aeltere Entfernungen zaehlen nicht mehr
DP.MIN_FIX = 4        -- so viele Entfernungen mindestens
DP.ANCHORS = 10       -- Messpunkte im Umlauf
DP.RES_OK = 12        -- Yards: mittlerer Rest, darueber verworfen
DP.SHOW_AGE = 3       -- s: so lange gilt eine Lage
-- 1.0.10.7 (Spieler: "besser wieder der Spielerpfeil"): in Instanzen nennt
-- das Spiel keine Blickrichtung (GetPlayerFacing leer) - die Richtung kommt
-- aus der Bewegung zwischen zwei Lagen, erst ab so vielen Yards (darunter
-- waere es Rauschen der Messung). Drehen auf der Stelle sieht sie nicht.
DP.HEAD_MOVE = 8
-- 1.0.10.9 (im Tempel: "immer noch ein Punkt"): nach dem Wechsel des Ziels
-- nennt das Spiel noch einige Bilder lang die Entfernung zum VORIGEN Ziel.
-- Im Stehen fiel das auf (gleicher Wert), beim Laufen nicht - fast jede Lage
-- wurde verworfen. Jetzt: eine Entfernung muss zur letzten Lage passen
-- (hoechstens DP.JUMP Yards daneben plus DP.SPEED je Sekunde seither);
-- ist die letzte Lage aelter als DP.TRUST_AGE, gilt wieder nur "anders als
-- zuvor".
DP.JUMP = 15
DP.SPEED = 12
DP.TRUST_AGE = 5
DP.SETTLE = 0.25      -- s: ohne verlaessliche Lage so lange nach dem Wechsel warten
DP.TAXI = _G.Enum and _G.Enum.SuperTrackingMapPinType and _G.Enum.SuperTrackingMapPinType.TaxiNode or 2

local floor, sqrt, abs = math.floor, math.sqrt, math.abs
local state = { active = false, readings = {}, misses = {}, list = {}, saved = nil }
DP.state = state
DP.stats = { readings = 0, misses = 0, refused = 0, fixes = 0, rejected = 0 }

local function Now()
    local f = _G.GetTime
    return type(f) == "function" and (K.Plain(f()) or 0) or 0
end

local function Data() return WeintCodex.DungeonPosData end

local function InCombat()
    return K.InCombat and K.InCombat() or (_G.InCombatLockdown and K.Bool(_G.InCombatLockdown(), false)) or false
end

-- Kann der Client das ueberhaupt? (Zielverfolgung einer Flugmeister-Marke
-- und die Entfernung dorthin.)
function DP.Available()
    local st, nav = _G.C_SuperTrack, _G.C_Navigation
    return type(st) == "table" and type(st.SetSuperTrackedMapPin) == "function"
        and type(nav) == "table" and type(nav.GetDistance) == "function" and Data() ~= nil
end

-- Grenzen der Ebene { x min, x max, y min, y max } oder nil.
function DP.Bounds(inst, floorIndex)
    local d = Data()
    local f = d and d.FLOORS and d.FLOORS[inst]
    return f and f[floorIndex] or nil
end

-- Messpunkte fuer die Instanz: die Auswahl, dann der Ersatz; nur der
-- eigenen Fraktion oder beider.
function DP.Anchors(inst)
    local d = Data()
    local out, seen = {}, {}
    local fac = _G.UnitFactionGroup and K.Plain((_G.UnitFactionGroup("player")))
    local bit = fac == "Alliance" and 1 or (fac == "Horde" and 2 or nil)
    local function Add(list)
        for _, id in ipairs(list or {}) do
            local n = d.NODES[id]
            if n and not seen[id] and (n[4] == 3 or not bit or n[4] == bit) and #out < DP.ANCHORS then
                seen[id] = true
                out[#out + 1] = id
            end
        end
    end
    if d then Add(d.ANCHORS and d.ANCHORS[inst]) Add(d.FALLBACK) end
    return out
end

--------------------------------------------------
-- Zielverfolgung sichern und zurueckgeben
--------------------------------------------------

local function Call(fn, ...)
    if type(fn) ~= "function" then return nil end
    local r = { pcall(fn, ...) }
    if not r[1] then return nil end
    return K.Plain(r[2]), K.Plain(r[3])
end

-- Jede Aenderung der Zielverfolgung ueber K.QuietMap (ui/kit.lua, 1.0.6.7):
-- die Weltkarte hoert waehrenddessen nicht zu und merkt sich keine
-- verunreinigten Werte - sonst sperrt das Spiel sie beim naechsten Oeffnen
-- im Kampf (SetPassThroughButtons).
local function Quiet(fn, ...)
    if type(fn) ~= "function" then return false end
    if K.QuietMap then return K.QuietMap(fn, ...) end
    return pcall(fn, ...)
end
DP.Quiet = Quiet

local function Save()
    local st = _G.C_SuperTrack
    local s = {}
    s.quest = Call(st.GetSuperTrackedQuestID)
    s.pinType, s.pinID = Call(st.GetSuperTrackedMapPin)
    s.waypoint = Call(st.IsSuperTrackingUserWaypoint)
    local f = _G.SuperTrackedFrame
    if type(f) == "table" and f.GetAlpha then
        s.alpha = Call(f.GetAlpha, f)
        pcall(f.SetAlpha, f, 0)
    end
    return s
end

local function Restore(s)
    if not s then return end
    local st = _G.C_SuperTrack
    Quiet(st.ClearAllSuperTracked)
    -- Eine Quest wird nie zurueckgegeben (Regel 6.6.0.1, load_test.lua:
    -- kein Aufruf, der die Questverfolgung setzt) - darum misst DP.Start gar
    -- nicht erst, solange eine verfolgt wird (DP.QuestTracked).
    if type(s.pinType) == "number" and type(s.pinID) == "number" then
        Quiet(st.SetSuperTrackedMapPin, s.pinType, s.pinID)
    elseif s.waypoint == true then
        Quiet(st.SetSuperTrackedUserWaypoint, true)
    end
    local f = _G.SuperTrackedFrame
    if type(f) == "table" and f.SetAlpha then pcall(f.SetAlpha, f, type(s.alpha) == "number" and s.alpha or 1) end
end

--------------------------------------------------
-- Rechnen
--------------------------------------------------

-- 3 x 3 loesen (Cramer); nil, wenn fast singulaer.
local function Solve3(a, b)
    local det = a[1] * (a[5] * a[9] - a[6] * a[8]) - a[2] * (a[4] * a[9] - a[6] * a[7]) + a[3] * (a[4] * a[8] - a[5] * a[7])
    if abs(det) < 1e-9 then return nil end
    local x = (b[1] * (a[5] * a[9] - a[6] * a[8]) - a[2] * (b[2] * a[9] - a[6] * b[3]) + a[3] * (b[2] * a[8] - a[5] * b[3])) / det
    local y = (a[1] * (b[2] * a[9] - a[6] * b[3]) - b[1] * (a[4] * a[9] - a[6] * a[7]) + a[3] * (a[4] * b[3] - b[2] * a[7])) / det
    local z = (a[1] * (a[5] * b[3] - b[2] * a[8]) - a[2] * (a[4] * b[3] - b[2] * a[7]) + b[1] * (a[4] * a[8] - a[5] * a[7])) / det
    return x, y, z
end

-- Lage aus Punkten { x, y, z } und Entfernungen d: Startwert aus der
-- linearisierten Rechnung (Differenzen der Kugelgleichungen), dann
-- Gauss-Newton. Liefert x, y, z, mittlerer Rest - oder nil.
function DP.Trilaterate(pts, dist)
    local n = #pts
    if n < DP.MIN_FIX then return nil end
    local p1, d1 = pts[1], dist[1]
    local A, B = { 0, 0, 0, 0, 0, 0, 0, 0, 0 }, { 0, 0, 0 }
    local s1 = p1[1] * p1[1] + p1[2] * p1[2] + p1[3] * p1[3]
    for i = 2, n do
        local p = pts[i]
        local r = { 2 * (p[1] - p1[1]), 2 * (p[2] - p1[2]), 2 * (p[3] - p1[3]) }
        local rhs = (p[1] * p[1] + p[2] * p[2] + p[3] * p[3]) - s1 - dist[i] * dist[i] + d1 * d1
        for j = 1, 3 do
            for k = 1, 3 do A[(j - 1) * 3 + k] = A[(j - 1) * 3 + k] + r[j] * r[k] end
            B[j] = B[j] + r[j] * rhs
        end
    end
    local x, y, z = Solve3(A, B)
    if not x then return nil end
    for _ = 1, 8 do
        local J, g = { 0, 0, 0, 0, 0, 0, 0, 0, 0 }, { 0, 0, 0 }
        for i = 1, n do
            local p = pts[i]
            local dx, dy, dz = x - p[1], y - p[2], z - p[3]
            local len = sqrt(dx * dx + dy * dy + dz * dz)
            if len > 1e-6 then
                local u = { dx / len, dy / len, dz / len }
                local r = len - dist[i]
                for j = 1, 3 do
                    for k = 1, 3 do J[(j - 1) * 3 + k] = J[(j - 1) * 3 + k] + u[j] * u[k] end
                    g[j] = g[j] - u[j] * r
                end
            end
        end
        local sx, sy, sz = Solve3(J, g)
        if not sx then break end
        x, y, z = x + sx, y + sy, z + sz
        if abs(sx) + abs(sy) + abs(sz) < 0.01 then break end
    end
    local sum = 0
    for i = 1, n do
        local p = pts[i]
        local r = sqrt((x - p[1]) ^ 2 + (y - p[2]) ^ 2 + (z - p[3]) ^ 2) - dist[i]
        sum = sum + r * r
    end
    return x, y, z, sqrt(sum / n)
end

local pts, dist = {}, {}
local function Fix(now)
    local d = Data()
    local n = 0
    for id, r in pairs(state.readings) do
        if now - r.t <= DP.MAX_AGE then
            local node = d.NODES[id]
            n = n + 1
            pts[n], dist[n] = node, r.d
        end
    end
    for i = #pts, n + 1, -1 do pts[i], dist[i] = nil, nil end
    if n < DP.MIN_FIX then return end
    local x, y, z, res = DP.Trilaterate(pts, dist)
    if not x then return end
    if res > DP.RES_OK then DP.stats.rejected = DP.stats.rejected + 1 return end
    local f = state.fix or {}
    f.x, f.y, f.z, f.res, f.t, f.n = x, y, z, res, now, n
    state.fix = f
    -- Richtung aus der Bewegung (x = Norden, y = Westen; 0 = Norden, gegen
    -- den Uhrzeigersinn wie GetPlayerFacing).
    if not state.refX then
        state.refX, state.refY = x, y
    else
        local dx, dy = x - state.refX, y - state.refY
        if dx * dx + dy * dy >= DP.HEAD_MOVE * DP.HEAD_MOVE then
            state.heading = math.atan2(dy, dx) % (2 * math.pi)
            state.refX, state.refY = x, y
        end
    end
    DP.stats.fixes = DP.stats.fixes + 1
end

--------------------------------------------------
-- Messen (nur bei offener Dungeonkarte, nie im Kampf)
--------------------------------------------------

local frame = CreateFrame("Frame")
DP.frame = frame

local function ReadDistance()
    local nav = _G.C_Navigation
    local ok, d = pcall(nav.GetDistance)
    if not ok or K.IsSecret(d) then return nil end
    d = K.Plain(d)
    return type(d) == "number" and d > 0 and d or nil
end

-- Passt Entfernung d zu Flugpunkt id, gemessen an der letzten Lage?
function DP.Plausible(id, d, now)
    local f = state.fix
    local node = Data().NODES[id]
    if not (f and node) then return true end
    local age = now - f.t
    if age > DP.TRUST_AGE then return true end
    local expect = sqrt((f.x - node[1]) ^ 2 + (f.y - node[2]) ^ 2 + (f.z - node[3]) ^ 2)
    return abs(d - expect) <= DP.JUMP + DP.SPEED * age
end

local function Switch(now)
    local list = state.list
    if #list == 0 then return end
    state.idx = state.idx % #list + 1
    state.cur = list[state.idx]
    state.since = now
    Quiet(_G.C_SuperTrack.SetSuperTrackedMapPin, DP.TAXI, state.cur)
end

-- Im Takt: ohne Tabelle (Call legt eine an).
local function Ours()
    local fn = _G.C_SuperTrack.GetSuperTrackedMapPin
    if type(fn) ~= "function" then return true end   -- nicht abfragbar: vertrauen
    local ok, t, id = pcall(fn)
    if not ok then return true end
    t, id = K.Plain(t), K.Plain(id)
    if t == nil and id == nil then return true end
    return t == DP.TAXI and id == state.cur
end

function DP.Step()
    if not state.active then return end
    if InCombat() then DP.Stop() return end
    local now = Now()
    if not state.cur then Switch(now) return end
    local age = now - state.since
    if age < DP.STEP then return end
    -- Ohne verlaessliche Lage (Karte im Laufen geoeffnet) erst nach DP.SETTLE
    -- lesen - vorher kann noch das vorige Ziel antworten.
    local f = state.fix
    if age < DP.SETTLE and not (f and now - f.t <= DP.TRUST_AGE) then return end
    local d = ReadDistance()
    if not Ours() then
        DP.stats.refused = DP.stats.refused + 1
        Switch(now)
        return
    end
    -- Gleich der vorigen Entfernung: die Navigation zeigt noch das alte Ziel.
    -- Passt sie nicht zur letzten Lage, ebenso (siehe DP.JUMP).
    if d and not DP.Plausible(state.cur, d, now) then
        DP.stats.stale = (DP.stats.stale or 0) + 1
        d = nil
    end
    if d and (d ~= state.last or age >= DP.TIMEOUT) then
        state.readings[state.cur] = state.readings[state.cur] or {}
        state.readings[state.cur].d, state.readings[state.cur].t = d, now
        state.last = d
        DP.stats.readings = DP.stats.readings + 1
        Fix(now)
        Switch(now)
    elseif age >= DP.TIMEOUT then
        DP.stats.misses = DP.stats.misses + 1
        Switch(now)
    end
end

-- Verfolgt das Spiel gerade eine Quest? Dann wird nicht gemessen: sie
-- kaeme danach nicht zurueck (siehe Restore).
function DP.QuestTracked()
    local st = _G.C_SuperTrack
    local q = st and Call(st.GetSuperTrackedQuestID)
    return type(q) == "number" and q > 0
end

function DP.Start(inst)
    if state.active and state.inst == inst then return true end
    if not DP.Available() or InCombat() or DP.QuestTracked() then return false end
    if state.active then DP.Stop() end
    local list = DP.Anchors(inst)
    if #list < DP.MIN_FIX then return false end
    state.saved = Save()
    state.active, state.inst, state.list, state.idx, state.cur, state.last = true, inst, list, 0, nil, nil
    for k in pairs(state.readings) do state.readings[k] = nil end
    state.refX, state.refY, state.heading = nil, nil, nil
    frame:SetScript("OnUpdate", function() DP.Step() end)
    return true
end

function DP.Stop()
    if not state.active then return end
    state.active, state.cur = false, nil
    frame:SetScript("OnUpdate", nil)
    Restore(state.saved)
    state.saved = nil
end

-- Die eigene Lage x, y (Welt), wenn frisch und zur Instanz gehoerend; sonst nil.
function DP.Get(inst)
    local f = state.fix
    if not f or state.inst ~= inst or Now() - f.t > DP.SHOW_AGE then return nil end
    return f.x, f.y, f.z, f.res
end

-- Blickrichtung aus der Bewegung (Bogenmass wie GetPlayerFacing) oder nil.
function DP.Heading(inst)
    if not DP.Get(inst) then return nil end
    return state.heading
end

-- Lage auf der Ebene als Anteil (0..1, links -> rechts, oben -> unten) oder nil.
function DP.OnFloor(inst, floorIndex)
    local b = DP.Bounds(inst, floorIndex)
    local x, y = DP.Get(inst)
    if not (b and x) then return nil end
    local u = (b[4] - y) / (b[4] - b[3])
    local v = (b[2] - x) / (b[2] - b[1])
    if u < -0.05 or u > 1.05 or v < -0.05 or v > 1.05 then return nil end
    return u, v
end

local ev = CreateFrame("Frame")
DP.events = ev
for _, e in ipairs({ "PLAYER_REGEN_DISABLED", "PLAYER_ENTERING_WORLD", "PLAYER_LEAVING_WORLD" }) do
    pcall(ev.RegisterEvent, ev, e)
end
ev:SetScript("OnEvent", WeintCodex.Measured("Eigene Lage im Dungeon", function() DP.Stop() end))

-- /wcui dungeonkarte: was die Lage-Messung gerade weiss.
function DP.StatusLines()
    local s = DP.stats
    local out = {
        "Eigene Lage: Zielverfolgung " .. (DP.Available() and "da" or "fehlt")
            .. " · misst " .. (state.active and "ja" or "nein")
            .. string.format(" · Entfernungen %d, stumm %d, abgelehnt %d, alt %d, Lagen %d, verworfen %d",
                s.readings, s.misses, s.refused, s.stale or 0, s.fixes, s.rejected),
        "Richtung aus der Bewegung: " .. (state.heading and string.format("%.0f°", math.deg(state.heading)) or "noch keine")
            .. " · Blickrichtung vom Spiel: " .. ((_G.GetPlayerFacing and type(K.Plain(_G.GetPlayerFacing())) == "number") and "ja" or "nein"),
    }
    local f = state.fix
    if f then
        out[#out + 1] = string.format("Letzte Lage: %.1f, %.1f, %.1f (Rest %.1f yd aus %d Punkten, vor %.1f s)",
            f.x, f.y, f.z, f.res, f.n, Now() - f.t)
    end
    return out
end

WeintCodex.Hold("ui/dungeonpos.lua", function() return { state = state, pts = pts, dist = dist } end)
