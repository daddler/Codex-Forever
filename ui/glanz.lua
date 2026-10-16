--------------------------------------------------
-- WeintCodex :: Glanz - lebendige Balken ueberall (6.43.0.0)
--------------------------------------------------
-- Wunsch des Spielers: "Es fehlt der Glanz ueberall. In DPS-Meter,
-- Einheitsfenster etc. eine kleine lebendige Animation wie bei den
-- Namensplaketten. Optional einschaltbar, individuell einstellbar."
--
-- Was die Plaketten seit 6.8.1.0 koennen, fuer jeden Balken, der sich hier
-- anmeldet (GZ.Bar):
--   Schimmer   ein heller Streifen laeuft ab und zu ueber den Balken
--   Gleiten    der Balken laeuft zum neuen Wert, statt zu springen
--   Spur       was ein Treffer nahm, bleibt kurz hell stehen (nur Leben)
--
-- REGELN wie bei den Plaketten:
--   * Alles, was sich bewegt, ist eine Animation des Spiels oder ein Wert,
--     den der Balken selbst gleiten laesst - kein Lua je Bild. Einziger
--     Takt: die Spur wartet GZ.TRAIL_DELAY s; er laeuft nur, solange eine
--     Spur wartet, ohne Tabelle oder Closure je Treffer.
--   * Werte koennen geheim sein (12.x): nie damit gerechnet oder
--     verglichen - der Balken bekommt sie nur durchgereicht.
--   * Aus (Standard) ist alles wie vorher: kein Schimmer, keine Spur,
--     SetValue wie immer.
-- Einstellungen: Seite "Glanz" unter Allgemein (ui/glanzpage.lua; bis
-- 6.43.0.0 im Komfort - Wunsch: "gehoert zur Grundeinstellung").
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIGlanz = {}

local GZ = WeintCodex.UIGlanz
local K  = WeintCodex.UIKit
local KEY = "general"   -- 6.44.0.0: Grundeinstellung, nicht Komfort

GZ.TRAIL_DELAY = 0.35   -- so lange bleibt, was ein Treffer nahm, hell stehen
GZ.SHEEN_W     = 40     -- Breite des Schimmers in px

-- Bereiche und ihre Schalter.
GZ.AREAS = {
    { key = "unit",  opt = "glanzUnit",  label = "Einheitenrahmen" },
    { key = "group", opt = "glanzGroup", label = "Gruppenrahmen" },
    { key = "meter", opt = "glanzMeter", label = "Schadensanzeige" },
    { key = "cast",  opt = "glanzCast",  label = "Zauberleiste" },
    { key = "xp",    opt = "glanzXp",    label = "Erfahrungsbalken" },
}

GZ.DEFAULTS = {
    glanz = false,
    glanzUnit = true, glanzGroup = true, glanzMeter = true, glanzCast = true, glanzXp = true,
    glanzSheen = true, glanzSmooth = true, glanzTrail = true,
    glanzStrength = 60,   -- % Helligkeit des Schimmers
    glanzRun = 9,         -- Zehntelsekunden fuer einen Lauf
    glanzPause = 5,       -- s Ruhe zwischen zwei Laeufen
}

local bars = setmetatable({}, { __mode = "k" })   -- [Balken] = Zustand
GZ.bars = bars

local function Opt(k)
    local v = K.Get(KEY, k)
    if v == nil then v = GZ.DEFAULTS[k] end
    return v
end
GZ.Opt = Opt

function GZ.On() return Opt("glanz") == true end

local areaOpt = {}
for _, a in ipairs(GZ.AREAS) do areaOpt[a.key] = a.opt end

function GZ.AreaOn(area)
    return GZ.On() and Opt(areaOpt[area] or "") ~= false
end

--------------------------------------------------
-- Gleiten
--------------------------------------------------

function GZ.Interp()
    if GZ.smoothBroken then return nil end
    local E = _G.Enum
    local I = E and E.StatusBarInterpolation
    return I and I.ExponentialEaseOut or nil
end

local function SetSmooth(bar, v)
    local interp = GZ.Interp()
    if interp then
        if pcall(bar.SetValue, bar, v, interp) then return end
        GZ.smoothBroken = true
    end
    bar:SetValue(v)
end

--------------------------------------------------
-- Spur
--------------------------------------------------

local pending = {}
GZ.pending = pending
local driver = CreateFrame("Frame")
local function Now() return K.Plain(_G.GetTime and _G.GetTime()) or 0 end

local function Tick()
    local now = Now()
    for st in pairs(pending) do
        if now >= st.trailAt then
            pending[st] = nil
            if st.trail then SetSmooth(st.trail, st.trailVal) end
        end
    end
    if _G.next(pending) == nil then driver:SetScript("OnUpdate", nil) end
end
GZ.Tick = Tick

--------------------------------------------------
-- Schimmer
--------------------------------------------------

local function Anim(region, kind)
    if type(region) ~= "table" or type(region.CreateAnimationGroup) ~= "function" then return nil end
    local ok, ag = pcall(region.CreateAnimationGroup, region)
    if not ok or type(ag) ~= "table" or type(ag.CreateAnimation) ~= "function" then return nil end
    local a = ag:CreateAnimation(kind)
    if type(a) ~= "table" then return nil end
    return ag, a
end

local function BuildSheen(st, bar)
    local clip = CreateFrame("Frame", nil, bar)
    clip:SetAllPoints(bar)
    clip:SetFrameLevel((bar:GetFrameLevel() or 1) + 1)
    if clip.SetClipsChildren then pcall(clip.SetClipsChildren, clip, true) end
    local sheen = CreateFrame("Frame", nil, clip)
    sheen:SetWidth(GZ.SHEEN_W)
    sheen:SetPoint("TOPRIGHT", clip, "TOPLEFT", 0, 0)
    sheen:SetPoint("BOTTOMRIGHT", clip, "BOTTOMLEFT", 0, 0)
    sheen.half = {}
    for i = 1, 2 do
        local t = sheen:CreateTexture(nil, "OVERLAY")
        t:SetColorTexture(1, 1, 1, 1)
        if t.SetBlendMode then t:SetBlendMode("ADD") end
        t:SetPoint("TOP", sheen, "TOP", 0, 0)
        t:SetPoint("BOTTOM", sheen, "BOTTOM", 0, 0)
        t:SetWidth(GZ.SHEEN_W / 2)
        if i == 1 then t:SetPoint("LEFT", sheen, "LEFT", 0, 0) else t:SetPoint("RIGHT", sheen, "RIGHT", 0, 0) end
        sheen.half[i] = t
    end
    sheen:Hide()
    local ag, move = Anim(sheen, "Translation")
    if ag then
        if move.SetSmoothing then move:SetSmoothing("IN_OUT") end
        move:SetOrder(1)
        local wait = ag:CreateAnimation("Alpha")
        if type(wait) == "table" and wait.SetFromAlpha then
            wait:SetFromAlpha(1) wait:SetToAlpha(1) wait:SetOrder(2)
        end
        if ag.SetLooping then ag:SetLooping("REPEAT") end
        st.wait = wait
    end
    st.clip, st.sheen, st.ag, st.move = clip, sheen, ag, move
    -- Neue Breite, neuer Weg.
    if bar.HookScript then
        bar:HookScript("OnSizeChanged", function() if st.running then GZ.Restart(st) end end)
    end
end

local function PaintSheen(st)
    local c = WeintCodex.GameColors.glanzSheen
    local a = c[4] * (Opt("glanzStrength") or 60) / 100
    for i, t in ipairs(st.sheen.half) do
        if t.SetGradient and _G.CreateColor then
            local a0, a1 = (i == 1) and 0 or a, (i == 1) and a or 0
            t:SetGradient("HORIZONTAL", _G.CreateColor(c[1], c[2], c[3], a0), _G.CreateColor(c[1], c[2], c[3], a1))
        else
            t:SetVertexColor(c[1], c[2], c[3], a * 0.5)
        end
    end
end

function GZ.Restart(st)
    if not st.ag then return end
    st.ag:Stop()
    local w = K.Plain(st.bar.GetWidth and st.bar:GetWidth())
    if type(w) ~= "number" or w <= 0 then w = 100 end
    st.move:SetOffset(w + GZ.SHEEN_W, 0)
    st.move:SetDuration((Opt("glanzRun") or 9) / 10)
    if st.wait then st.wait:SetDuration(math.max(0.5, Opt("glanzPause") or 5)) end
    -- Nicht alle Balken zugleich: jeder beginnt zu einer anderen Zeit.
    local t = _G.C_Timer
    local delay = (st.seed or 0) * math.max(0.5, Opt("glanzPause") or 5)
    if t and t.After and delay > 0 then
        t.After(delay, function() if st.running and st.ag and not st.ag:IsPlaying() then st.ag:Play() end end)
    else
        st.ag:Play()
    end
end

--------------------------------------------------
-- Anmelden und anwenden
--------------------------------------------------

-- Ein Balken macht mit. area: "unit"/"group"/"meter"/"cast"/"xp";
-- kind: "health" (mit Spur) oder nil. bg: eine Hintergrundtextur, die AM
-- Balken selbst haengt - sie zieht unter die Spur, sonst laege die Spur
-- unsichtbar hinter ihr. Aufrufen direkt nach K.NewBar, bevor weitere
-- Rahmen ueber dem Balken entstehen (die Spur nimmt seine alte Ebene, der
-- Balken eine hoeher).
function GZ.Bar(bar, area, kind, bg)
    if type(bar) ~= "table" or bars[bar] then return bars[bar] end
    local st = { bar = bar, area = area, kind = kind, seed = math.random() }
    bars[bar] = st
    if kind == "health" then
        local parent = bar:GetParent()
        local level = bar:GetFrameLevel() or 1
        local trail = CreateFrame("StatusBar", nil, parent)
        trail:SetStatusBarTexture(K.BarTexture())
        trail:SetAllPoints(bar)
        trail:SetMinMaxValues(0, 1)
        trail:SetValue(0)
        local c = WeintCodex.GameColors.glanzTrail
        trail:SetStatusBarColor(c[1], c[2], c[3], c[4])
        trail:SetFrameLevel(level)
        bar:SetFrameLevel(level + 1)
        if bg and bg.SetParent then
            local under = CreateFrame("Frame", nil, parent)
            under:SetAllPoints(bar)
            under:SetFrameLevel(math.max(0, level - 1))
            bg:SetParent(under)
            st.under = under
        end
        trail:Hide()
        st.trail = trail
    end
    GZ.Apply(st)
    return st
end

function GZ.Apply(st)
    local on = GZ.AreaOn(st.area)
    st.smooth = on and Opt("glanzSmooth") ~= false
    local trailOn = on and st.trail and Opt("glanzTrail") ~= false and true or false
    if st.trail then
        if not trailOn then pending[st] = nil end
        st.trail:SetShown(trailOn)
        st.trailOn = trailOn
    end
    local sheen = on and Opt("glanzSheen") ~= false
    if sheen and not st.sheen then BuildSheen(st, st.bar) end
    if st.sheen then
        st.sheen:SetShown(sheen)
        if sheen then
            PaintSheen(st)
            st.running = true
            GZ.Restart(st)
        else
            st.running = false
            if st.ag then st.ag:Stop() end
        end
    end
end

function GZ.ApplyAll()
    for _, st in pairs(bars) do GZ.Apply(st) end
end

-- Statt bar:SetMinMaxValues(lo, hi): die Spur geht mit.
function GZ.Range(bar, lo, hi)
    bar:SetMinMaxValues(lo, hi)
    local st = bars[bar]
    if st and st.trail then st.trail:SetMinMaxValues(lo, hi) end
end

-- Statt bar:SetValue(v). snap = true: ohne Gleiten und Spur (neue Einheit,
-- anderes Ziel - ein Sprung ist dann die Wahrheit).
function GZ.Set(bar, v, snap)
    local st = bars[bar]
    if not st or snap or not st.smooth then
        bar:SetValue(v)
    else
        SetSmooth(bar, v)
    end
    if st and st.trail then
        if snap or not st.trailOn then
            pending[st] = nil
            st.trail:SetValue(v)
        else
            st.trailVal = v
            if not pending[st] then
                st.trailAt = Now() + GZ.TRAIL_DELAY
                pending[st] = true
                driver:SetScript("OnUpdate", Tick)
            end
        end
    end
end

-- Steht jetzt jemand anderes im Balken (anderes Ziel, neuer Gruppenplatz)?
-- Dann springt er - Gleiten und Spur gehoeren zu EINER Einheit.
function GZ.Changed(bar, unit)
    local st = bars[bar]
    if not st then return false end
    local g = _G.UnitGUID and K.Plain(_G.UnitGUID(unit))
    if type(g) ~= "string" then g = nil end
    if st.guid ~= g then st.guid = g return true end
    return false
end

K.Listen(function(kind, key, opt)
    if kind == "setting" and key == KEY and type(opt) == "string" and opt:sub(1, 5) == "glanz" then
        GZ.ApplyAll()
    elseif kind == "setting" and key == "general" then
        -- Neue Balkentextur: die Spur zieht mit.
        for _, st in pairs(bars) do
            if st.trail then st.trail:SetStatusBarTexture(K.BarTexture()) end
        end
    end
end)
