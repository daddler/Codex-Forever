--------------------------------------------------
-- WeintCodex :: Komfort - Kompass des Questpfeils (6.35.0.0)
--------------------------------------------------
-- Ein schmales Band oben am Bildschirm, wie ein Kompass in einer Linie:
-- Striche alle 15 Grad, an den vier Himmelsrichtungen mit Buchstaben, zu
-- den Enden hin ausgeblendet - keine Flaeche, kein Rahmen. Geradeaus ist
-- die Mitte. Darauf:
--   * das Ziel als Nadel,
--   * der naechste Halt (Flugmeister, Anleger, Portal), wenn die Route
--     einen hat,
--   * der Punkt voraus auf dem Weg, darunter die Entfernung.
-- Was ausserhalb des Bandes liegt, klebt an seinem Rand. Liegen zwei
-- Zeichen aufeinander, bleibt das wichtigere (Ziel vor Halt vor Weg).
--
-- Gewuenscht nach dem Vorbild von Shortest Path Forever (GPL): Verhalten
-- und Aussehen nachgebaut, kein Code uebernommen.
--
-- Daten liefert ui/questarrow.lua (QA.cmp, fuenfmal je Sekunde); die
-- Blickrichtung liest das Band selbst, solange es steht, und dreht weich
-- nach (exponentiell, unabhaengig von der Bildrate, ueber Norden auf dem
-- kuerzesten Weg).
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UICompass = {}

local CP = WeintCodex.UICompass
local K  = WeintCodex.UIKit
local GC = WeintCodex.GameColors
local KEY = "questarrow"

CP.WIDTH, CP.HEIGHT = 360, 52
CP.FADE = 80          -- so viele Bildpunkte blenden die Striche zum Ende hin aus
CP.EASE = 18          -- wie schnell das Band der Blickrichtung folgt
CP.OVERLAP = 6        -- naeher als das: ein Zeichen verdeckt das andere
CP.LETTERS = { "N", "W", "S", "O" }   -- 0, 90, 180, 270 Grad (gegen den Uhrzeigersinn, wie GetPlayerFacing)

local TURN = 2 * math.pi
local frame
-- Zustand in einer eigenen Tabelle, nicht als Felder am Rahmen.
local st = {}
CP.state = st

-- Unterschied zweier Winkel, -pi..pi.
function CP.Diff(a, b)
    return (a - b + math.pi) % TURN - math.pi
end

-- Lage auf dem Band: Blickrichtung und Peilung zaehlen nach Westen; Osten
-- gehoert nach rechts. Ein halber Kreis fuellt die halbe Breite.
function CP.Offset(angle, facing)
    return -CP.Diff(angle, facing) * CP.WIDTH / math.pi
end

-- Peilung von (pN, pW) nach (tN, tW), wie GetPlayerFacing gezaehlt.
function CP.Bearing(pN, pW, tN, tW)
    return math.atan2(tW - pW, tN - pN) % TURN
end

local function HasAtlas(name)
    local ct = _G.C_Texture
    if not (ct and ct.GetAtlasInfo) then return false end
    local ok, info = pcall(ct.GetAtlasInfo, name)
    return ok and type(info) == "table"
end

-- Ein Zeichen: Atlas des Spiels, wenn der Client ihn kennt, sonst ein
-- farbiger Punkt (nie ein geratener Pfad - der waere ein gruenes Rechteck).
local function Marker(size, atlas, col)
    local t = frame:CreateTexture(nil, "OVERLAY")
    t:SetSize(size, size)
    if atlas and HasAtlas(atlas) then
        t:SetAtlas(atlas)
    else
        t:SetColorTexture(col[1], col[2], col[3], 1)
        t:SetSize(math.floor(size / 2), math.floor(size / 2))
    end
    t:Hide()
    return t
end

local function Build()
    frame = CreateFrame("Frame", "WeintCodexCompass", UIParent)
    frame:SetSize(CP.WIDTH, CP.HEIGHT)
    frame:SetFrameStrata("LOW")
    frame:EnableMouse(false)
    st.ticks = {}
    local tc = GC.compassTick
    for i = 0, 23 do
        local tick = frame:CreateTexture(nil, "ARTWORK")
        tick._angle = i * TURN / 24
        tick._major = i % 6 == 0
        tick:SetColorTexture(tc[1], tc[2], tc[3], tc[4])
        tick:SetSize(1, tick._major and 6 or 3)
        if tick._major then
            tick._label = K.NewText(frame, 11)
            tick._label:SetText(CP.LETTERS[i / 6 + 1])
            local g = WeintCodex.Colors.gold
            tick._label:SetTextColor(g[1], g[2], g[3], 1)
            tick._label:SetShadowOffset(1, -1)
            tick._label:SetPoint("TOP", tick, "BOTTOM", 0, -1)
        end
        st.ticks[#st.ticks + 1] = tick
    end
    local a = GC.compassAhead
    st.ahead = frame:CreateTexture(nil, "OVERLAY")
    st.ahead:SetColorTexture(a[1], a[2], a[3], a[4])
    st.ahead:SetSize(1, 8)
    st.ahead:SetPoint("TOP", frame, "TOP", 0, -3)
    local C = WeintCodex.Colors
    st.goal = Marker(18, "Waypoint-MapPin-Tracked", C.gold)
    st.stop = Marker(16, "Navigation-Tracked-Icon", C.routeAlt)
    st.bend = Marker(12, nil, C.routeYellow)
    st.markers = { st.goal, st.stop, st.bend }
    st.dist = K.NewText(frame, 11)
    st.dist:SetShadowOffset(1, -1)
    frame:SetScript("OnUpdate", function(_, el) CP.Step(el or 0) end)
    frame:Hide()
    CP.frame = frame
    K.RegisterMover(frame, "compass", "Kompass", K.Layout("compass"))
end

-- Ein Zeichen auf das Band legen; nil = ausgeblendet (verdeckt).
local function Place(m, angle, facing, index)
    m._visible = false
    if not angle then m:Hide() return end
    local half = CP.WIDTH / 2
    local off = math.max(-half, math.min(half, CP.Offset(angle, facing)))
    for i = 1, index - 1 do
        local o = st.markers[i]
        if o._visible and math.abs(o._offset - off) <= CP.OVERLAP then m:Hide() m._cover = o return end
    end
    m._offset, m._cover, m._visible = off, nil, true
    m:ClearAllPoints()
    m:SetPoint("CENTER", frame, "TOP", off, -10)
    m:Show()
end

function CP.Render()
    local d, facing = WeintCodex.UIQuestArrow.cmp, st.facing
    local half = CP.WIDTH / 2
    for _, tick in ipairs(st.ticks) do
        local off = CP.Offset(tick._angle, facing)
        local inside = math.abs(off) <= half
        tick:SetShown(inside)
        if tick._label then tick._label:SetShown(inside) end
        if inside then
            local edge = math.max(0, math.min(1, (half - math.abs(off)) / CP.FADE))
            local alpha = edge * edge * (tick._major and 1 or 0.6)
            tick:ClearAllPoints()
            tick:SetPoint("TOP", frame, "TOP", off, -3)
            tick:SetAlpha(alpha)
            if tick._label then tick._label:SetAlpha(alpha) end
        end
    end
    Place(st.goal, d.gN and CP.Bearing(d.pN, d.pW, d.gN, d.gW), facing, 1)
    Place(st.stop, d.sN and CP.Bearing(d.pN, d.pW, d.sN, d.sW), facing, 2)
    Place(st.bend, d.bN and CP.Bearing(d.pN, d.pW, d.bN, d.bW), facing, 3)
    -- Die Entfernung steht unter dem Punkt voraus - oder unter dem
    -- Zeichen, das ihn verdeckt.
    local owner = st.bend._visible and st.bend or st.bend._cover
    if owner and d.dist then
        local QA = WeintCodex.UIQuestArrow
        st.dist:SetText(QA.FormatDistance(d.dist, K.Get(KEY, "units")))
        st.dist:ClearAllPoints()
        st.dist:SetPoint("TOP", owner, "BOTTOM", 0, -2)
        st.dist:Show()
    else
        st.dist:Hide()
    end
end

-- Weich nachdrehen und zeichnen.
function CP.Step(elapsed)
    if not CP.Wanted() then frame:Hide() return end
    local raw = _G.GetPlayerFacing and K.Plain(_G.GetPlayerFacing())
    if type(raw) ~= "number" then frame:SetAlpha(0) st.facing = nil return end
    frame:SetAlpha(1)
    -- Nur zeichnen, wenn sich Blick oder Daten geaendert haben: das Band
    -- laeuft jedes Bild, steht man still, kostet es nichts.
    local stamp = WeintCodex.UIQuestArrow.cmp.n
    if st.facing == raw and st.stamp == stamp then return end
    st.stamp = stamp
    if not st.facing then
        st.facing = raw
    else
        local delta = CP.Diff(raw, st.facing)
        if math.abs(delta) > 0.001 then
            st.facing = (st.facing + delta * (1 - math.exp(-CP.EASE * elapsed))) % TURN
        else
            st.facing = raw
        end
    end
    CP.Render()
end

-- Soll das Band stehen? Questpfeil an, Kompass gewaehlt, ein Ziel auf
-- diesem Kontinent und der Pfeil selbst gerade zu sehen (nicht im Kampf
-- ausgeblendet, nicht im Dungeon).
function CP.Wanted()
    local QA = WeintCodex.UIQuestArrow
    if not (QA and K.IsActive(KEY)) then return false end
    if (K.Get(KEY, "compass") or "off") == "off" then return false end
    if not (QA.cmp and QA.cmp.ok) then return false end
    return QA.frame and QA.frame:IsShown() and true or false
end

function CP.Refresh()
    local want = CP.Wanted()
    if want and not frame then Build() end
    if not frame then return end
    frame:SetScale((K.Get(KEY, "compassScale") or 100) / 100)
    K.SetMoverEnabled("compass", (K.Get(KEY, "compass") or "off") ~= "off")
    if want then
        if not frame:IsShown() then st.facing, st.stamp = nil, nil end
        frame:Show()
        CP.Step(0)
    else
        frame:Hide()
    end
end
