--------------------------------------------------
-- WeintCodex :: Oberflaeche - Ziel der Mitspieler, Buffs von anderen (1.0.5.13)
--------------------------------------------------
-- Wunsch (mit Bild der Gruppenrahmen):
--   1. "in der Gruppe einsehen, welcher Spieler welches Ziel hat" - unter
--      dem Namen eine kleine Zeile "» Zielname" (UnitName(unit.."target")).
--      Hat er dasselbe Ziel wie du, in der Akzentfarbe.
--   2. "der Magier hat mich gebufft, aber den Buff sehe ich nicht" - die
--      Rahmen des Spiels zeigen nur Buffs, die DU selbst wirken koenntest
--      (Filter des Spiels, geschuetzt - ihn zu ersetzen hiesse Taint). Darum
--      eine eigene kleine Reihe oben rechts: Buffs von ANDEREN (Intelligenz,
--      Mal der Wildnis, Segen ...), hoechstens groupOtherMax.
--      Forever gibt Addons Auren im Kampf nicht heraus: gelesen wird nur
--      ausserhalb des Kampfes; im Kampf bleibt stehen, was davor galt (Buffs
--      dieser Art halten 30-60 Minuten), danach wird nachgelesen.
-- Fuer die Rahmen des Spiels (ui/gamegroup.lua) und die eigenen Kacheln
-- (ui/groupframes.lua). Kein Feld der Rahmen des Spiels wird geschrieben.
--------------------------------------------------

local K = WeintCodex.UIKit
local C = WeintCodex.Colors
local KEY = "groupframes"

WeintCodex.UIGroupExtra = {}
local GX = WeintCodex.UIGroupExtra

GX.DEFAULTS = { groupTargets = true, groupOtherBuffs = true, groupOtherMax = 4, groupTargetBar = true }
GX.ICON = 12
GX.BAR_W, GX.BAR_H = 72, 14   -- wie der kleine Fokusbalken (Bild des Spielers)

local function Opt(k) return K.Get(KEY, k) end
local over = setmetatable({}, { __mode = "k" })   -- [Rahmen] = Zusatz
GX.over = over

local function InCombat() return _G.InCombatLockdown and K.Bool(_G.InCombatLockdown(), false) or false end

-- Rahmen mit Einheit: { frame, unit } ueber beide Arten.
local list = {}
function GX.Frames()
    for i = #list, 1, -1 do list[i] = nil end
    local GG = WeintCodex.UIGameGroup
    if GG and GG.active and GG.Frames then
        local n = 0
        for _, f in ipairs(GG.Frames()) do
            n = n + 1
            if GX.UnitOf(f) and f.IsShown and K.Bool(f:IsShown(), true) then list[#list + 1] = f end
        end
        GX.gameFrames = n
    end
    local GF = WeintCodex.UIGroupFrames
    for _, b in ipairs(GF and GF.buttons or {}) do
        if b._wcUnit and b.IsShown and K.Bool(b:IsShown(), true) then list[#list + 1] = b end
    end
    return list
end

-- 1.0.5.15 (Feedback: "Buffs immer noch nicht"): f.unit kann am Rahmen
-- des Spiels geheim sein - dann wurde der Rahmen uebersprungen. Weitere
-- Wege: displayedUnit, das Attribut "unit" (vom Kopfrahmen gesetzt).
function GX.UnitOf(f)
    if type(f._wcUnit) == "string" then return f._wcUnit end
    for _, k in ipairs({ "unit", "displayedUnit" }) do
        local v = K.Plain(f[k])
        if type(v) == "string" and v ~= "" then return v end
    end
    if f.GetAttribute then
        local ok, v = pcall(f.GetAttribute, f, "unit")
        v = ok and K.Plain(v) or nil
        if type(v) == "string" and v ~= "" then return v end
    end
    return nil
end
local UnitOf = GX.UnitOf

local function Over(f)
    local o = over[f]
    if o then return o end
    o = CreateFrame("Frame", nil, f)
    o:SetAllPoints(f)
    o:SetFrameLevel((f:GetFrameLevel() or 1) + 6)
    o:EnableMouse(false)
    o.target = K.NewText(o, 9, "OVERLAY")
    o.target:SetPoint("TOPLEFT", f, "TOPLEFT", 4, -16)
    o.target:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -16)
    o.target:SetJustifyH("CENTER")
    o.target:SetWordWrap(false)
    if o.target.SetShadowOffset then o.target:SetShadowOffset(1, -1) end
    o.icons = {}
    over[f] = o
    return o
end

local function Icon(o, i)
    local t = o.icons[i]
    if t then return t end
    t = o:CreateTexture(nil, "OVERLAY")
    t:SetSize(GX.ICON, GX.ICON)
    t:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    t:SetPoint("TOPRIGHT", o, "TOPRIGHT", -3 - (i - 1) * (GX.ICON + 1), -3 - 13)
    o.icons[i] = t
    return t
end

-- Ziel eines Mitspielers.
function GX.UpdateTarget(f)
    local o = Over(f)
    local u = UnitOf(f)
    if not (Opt("groupTargets") and u) or Opt("groupTargetBar") or not (_G.UnitExists and K.Bool(_G.UnitExists(u .. "target"), false)) then
        o.target:SetText("")
        return nil
    end
    local name = _G.UnitName and _G.UnitName(u .. "target")
    if type(name) == "nil" then o.target:SetText("") return nil end
    local plain = K.Plain(name)
    if type(plain) == "string" then o.target:SetText("» " .. plain) else o.target:SetText(name) end
    local same = _G.UnitIsUnit and K.Bool(_G.UnitIsUnit(u .. "target", "target"), false)
    local c = same and (C.accent or C.textBright) or C.textMuted
    o.target:SetTextColor(c[1], c[2], c[3], 1)
    return name
end

-- Ein Buff an Stelle i: icon, mine (true/false/nil), dauer (Zahl/nil) -
-- oder nil, wenn dort keiner ist. 1.0.5.14 (Feedback: "Buffs sieht man immer
-- noch nicht"): drei Wege, weil Forever nicht jeden kennt, und nie ein
-- Vergleich mit einem Wert, der geheim sein koennte (type() statt ~= nil).
-- Ein unlesbares Feld heisst "unbekannt", nicht "weglassen".
function GX.BuffAt(u, i)
    local ua = _G.C_UnitAuras
    if ua and type(ua.GetAuraDataByIndex) == "function" then
        local ok, a = pcall(ua.GetAuraDataByIndex, u, i, "HELPFUL")
        if ok and type(a) == "table" then
            if type(a.icon) == "nil" then return nil end
            -- 1.0.5.16 (/wcui gruppe: "player: 4 gelesen, 0 gezeigt"):
            -- isFromPlayerOrPlayerPet heisst "von IRGENDEINEM Spieler", nicht
            -- "von dir" - so fiel der Buff des Magiers heraus. Von dir ist nur,
            -- was sourceUnit als dich nennt.
            local src, mine = K.Plain(a.sourceUnit), nil
            if type(src) == "string" and _G.UnitIsUnit then mine = K.Bool(_G.UnitIsUnit(src, "player"), false) end
            GX.via = "C_UnitAuras"
            return a.icon, mine, K.Plain(a.duration)
        end
        if ok then GX.via = "C_UnitAuras" return nil end
    end
    local fn = _G.UnitBuff or _G.UnitAura
    if type(fn) == "function" then
        local ok, name, icon, _, _, dur, _, caster = pcall(fn, u, i, "HELPFUL")
        if not ok or type(name) == "nil" then return nil end
        GX.via = "UnitBuff"
        local c = K.Plain(caster)
        local mine = (type(c) == "string" and _G.UnitIsUnit) and K.Bool(_G.UnitIsUnit(c, "player"), false) or nil
        return icon, mine, K.Plain(dur)
    end
    return nil
end

-- Buffs fuer die Reihe: alles, was nicht sicher von dir ist (deine eigenen
-- zeigt das Spiel), kurze (unter 2 Minuten, wenn lesbar) weg. Nur
-- ausserhalb des Kampfes gelesen.
GX.lastRead = {}
function GX.UpdateBuffs(f)
    local o = Over(f)
    local u = UnitOf(f)
    local max = tonumber(Opt("groupOtherMax")) or 4
    local n, seen = 0, 0
    if Opt("groupOtherBuffs") and u then
        if InCombat() then return nil end   -- stehen lassen, was davor galt
        for i = 1, 40 do
            if n >= max then break end
            local icon, mine, dur = GX.BuffAt(u, i)
            if type(icon) == "nil" then break end
            seen = seen + 1
            local short = type(dur) == "number" and dur > 0 and dur < 120
            if mine ~= true and not short then
                n = n + 1
                local t = Icon(o, n)
                t:SetTexture(icon)
                t:Show()
            end
        end
        GX.lastRead[u] = seen .. " gelesen, " .. n .. " gezeigt"
    end
    for i = n + 1, #o.icons do o.icons[i]:Hide() end
    return n
end

-- 1.0.5.14 (Wunsch: "einen kleinen Balken rechts daneben"): rechts neben
-- jedem Rahmen das Leben des Ziels dieses Mitspielers - rot fuer Gegner,
-- gruen fuer Freunde. Werte gehen ungeprueft an den Balken (der nimmt auch
-- geheime), gerechnet wird nichts.
function GX.UpdateTargetBar(f)
    local o = Over(f)
    local u = UnitOf(f)
    local tu = u and (u .. "target")
    if not (Opt("groupTargetBar") and tu and _G.UnitExists and K.Bool(_G.UnitExists(tu), false)) then
        if type(o.wcBar) == "table" then o.wcBar:Hide() end
        return false
    end
    if type(o.wcBar) ~= "table" then
        -- 1.0.5.16 (Feedback: "Balken gar nicht gut - kleiner, daneben, mit
        -- kleiner Schrift und dem Namen des Ziels"): waagerecht rechts neben
        -- dem Rahmen, mittig, mit dem Namen im Balken.
        local b = CreateFrame("StatusBar", nil, o)
        b:SetStatusBarTexture(K.BAR_TEXTURE)
        b:SetSize(GX.BAR_W, GX.BAR_H)
        b:SetPoint("LEFT", f, "RIGHT", 3, 0)
        b.bg = b:CreateTexture(nil, "BACKGROUND")
        b.bg:SetAllPoints(b)
        b.bg:SetColorTexture(0, 0, 0, 0.7)
        b.edge = K.Border(b, 1, 0, 0, 0, 1, "OVERLAY")
        b.name = K.NewText(b, 8, "OVERLAY")
        b.name:SetPoint("LEFT", b, "LEFT", 2, 0)
        b.name:SetPoint("RIGHT", b, "RIGHT", -26, 0)
        b.pct = K.NewText(b, 8, "OVERLAY")
        b.pct:SetPoint("RIGHT", b, "RIGHT", -2, 0)
        b.pct:SetJustifyH("RIGHT")
        if b.pct.SetShadowOffset then b.pct:SetShadowOffset(1, -1) end
        b.name:SetJustifyH("LEFT")
        b.name:SetWordWrap(false)
        if b.name.SetShadowOffset then b.name:SetShadowOffset(1, -1) end
        o.wcBar = b
    end
    local b = o.wcBar
    local hp, mx = _G.UnitHealth and _G.UnitHealth(tu), _G.UnitHealthMax and _G.UnitHealthMax(tu)
    pcall(b.SetMinMaxValues, b, 0, mx or 1)
    pcall(b.SetValue, b, hp or 0)
    local enemy = _G.UnitCanAttack and K.Bool(_G.UnitCanAttack("player", tu), false)
    local GC = WeintCodex.GameColors
    local c = enemy and (GC.enemyInCombat or { 0.8, 0.2, 0.2 }) or (GC.friendly or { 0.3, 0.8, 0.4 })
    b:SetStatusBarColor(c[1], c[2], c[3], 0.85)
    -- Prozent: vom Client (UnitHealthPercent, auch geheim an SetFormattedText),
    -- sonst gerechnet, wenn lesbar; sonst leer - nie geraten.
    local okP = false
    if _G.UnitHealthPercent and _G.CurveConstants and _G.CurveConstants.ScaleTo100 then
        okP = pcall(function()
            local v = _G.UnitHealthPercent(tu, true, _G.CurveConstants.ScaleTo100)
            b.pct:SetFormattedText("%.0f%%", v)
        end)
    end
    if not okP then
        local h, m = K.Plain(hp), K.Plain(mx)
        if type(h) == "number" and type(m) == "number" and m > 0 then
            b.pct:SetText(string.format("%d%%", math.floor(h / m * 100 + 0.5)))
        else
            b.pct:SetText("")
        end
    end
    local name = _G.UnitName and _G.UnitName(tu)
    local plain = K.Plain(name)
    if type(plain) == "string" then b.name:SetText(plain) elseif type(name) ~= "nil" then b.name:SetText(name) else b.name:SetText("") end
    b:Show()
    return true
end

-- Fuer /wcui gruppe.
function GX.Lines()
    local fr = GX.Frames()
    local out = { "Buffs von anderen: " .. (Opt("groupOtherBuffs") and "an" or "aus") .. " · gelesen über " .. tostring(GX.via or "–")
        .. " · Rahmen des Spiels " .. tostring(GX.gameFrames or 0) .. ", davon mit Einheit " .. #fr }
    if GX.lastErr then out[#out + 1] = "   Fehler zuletzt: " .. GX.lastErr end
    for u, l in pairs(GX.lastRead) do out[#out + 1] = "   " .. u .. ": " .. l end
    return out
end

function GX.UpdateAll(what)
    if not K.IsActive(KEY) then
        for _, o in pairs(over) do o:Hide() end
        return
    end
    local fight = InCombat()
    for _, f in ipairs(GX.Frames()) do
        -- Neue Zusaetze an Rahmen des Spiels nur ausserhalb des Kampfes anlegen.
        if over[f] or not fight then
        Over(f):Show()
        local ok, err = pcall(function()
            if what ~= "buffs" then GX.UpdateTarget(f) GX.UpdateTargetBar(f) end
            if what ~= "targets" then GX.UpdateBuffs(f) end
        end)
        if not ok then GX.lastErr = tostring(err) end
        end
    end
end

local ev = CreateFrame("Frame")
for _, e in ipairs({ "GROUP_ROSTER_UPDATE", "PLAYER_ENTERING_WORLD", "PLAYER_TARGET_CHANGED", "UNIT_TARGET",
                     "UNIT_AURA", "PLAYER_REGEN_ENABLED" }) do
    pcall(ev.RegisterEvent, ev, e)
end
local dirtyT, dirtyB = true, true
ev:SetScript("OnEvent", function(_, event, unit)
    if event == "UNIT_TARGET" or event == "PLAYER_TARGET_CHANGED" then dirtyT = true
    elseif event == "UNIT_AURA" then dirtyB = true
    else dirtyT, dirtyB = true, true end
end)
GX.events = ev
local acc = 0
local tick = CreateFrame("Frame")
tick:SetScript("OnUpdate", function(_, el)
    acc = acc + (el or 0)
    if acc < 0.5 then return end
    acc = 0
    -- Leben der Ziele aendert sich laufend: Balken jede halbe Sekunde.
    if not (dirtyT or dirtyB) then
        if Opt("groupTargetBar") and K.IsActive(KEY) then
            for _, f in ipairs(GX.Frames()) do if over[f] then GX.UpdateTargetBar(f) end end
        end
        return
    end
    local what = (dirtyT and dirtyB) and nil or (dirtyT and "targets" or "buffs")
    dirtyT, dirtyB = false, false
    GX.UpdateAll(what)
end)
GX.tick = tick

K.Listen(function(kind, key)
    if (kind == "active" or kind == "setting") and key == KEY then dirtyT, dirtyB = true, true end
end)

local mod = K.Module(KEY)
if mod then
    for k, v in pairs(GX.DEFAULTS) do
        if mod.defaults[k] == nil then mod.defaults[k] = v end
    end
end
