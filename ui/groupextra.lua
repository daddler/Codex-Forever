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

GX.DEFAULTS = { groupTargets = true, groupOtherBuffs = true, groupOtherMax = 4 }
GX.ICON = 12

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
        for _, f in ipairs(GG.Frames()) do
            local u = K.Plain(f.unit)
            if type(u) == "string" and f.IsShown and f:IsShown() then list[#list + 1] = f end
        end
    end
    local GF = WeintCodex.UIGroupFrames
    for _, b in ipairs(GF and GF.buttons or {}) do
        if b._wcUnit and b.IsShown and b:IsShown() then list[#list + 1] = b end
    end
    return list
end

local function UnitOf(f) return f._wcUnit or K.Plain(f.unit) end

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
    if not (Opt("groupTargets") and u) or not (_G.UnitExists and K.Bool(_G.UnitExists(u .. "target"), false)) then
        o.target:SetText("")
        return nil
    end
    local name = _G.UnitName and _G.UnitName(u .. "target")
    if name == nil then o.target:SetText("") return nil end
    o.target:SetText("» " .. tostring(K.Plain(name) or name))
    local same = _G.UnitIsUnit and K.Bool(_G.UnitIsUnit(u .. "target", "target"), false)
    local c = same and (C.accent or C.textBright) or C.textMuted
    o.target:SetTextColor(c[1], c[2], c[3], 1)
    return name
end

-- Buffs von anderen (nicht von dir), nur ausserhalb des Kampfes gelesen.
function GX.UpdateBuffs(f)
    local o = Over(f)
    local u = UnitOf(f)
    local max = tonumber(Opt("groupOtherMax")) or 4
    local n = 0
    if Opt("groupOtherBuffs") and u then
        if InCombat() then return nil end   -- stehen lassen, was davor galt
        local ua = _G.C_UnitAuras
        local get = ua and ua.GetAuraDataByIndex
        for i = 1, 40 do
            if n >= max or not get then break end
            local ok, a = pcall(get, u, i, "HELPFUL")
            if not ok or type(a) ~= "table" then break end
            local mine = K.Bool(a.isFromPlayerOrPlayerPet, false)
            local src = K.Plain(a.sourceUnit)
            if not mine and type(src) == "string" and _G.UnitIsUnit then
                mine = K.Bool(_G.UnitIsUnit(src, "player"), false)
            end
            local dur = K.Plain(a.duration)
            -- Lange Buffs anderer Spieler (>= 2 Minuten oder ohne Ende, aber
            -- von einem Spieler): genau die, die das Spiel hier weglaesst.
            local long = type(dur) == "number" and (dur == 0 or dur >= 120)
            local byPlayer = K.Bool(a.isFromPlayerOrPlayerPet, false) or (type(src) == "string")
            if not mine and long and byPlayer and a.icon ~= nil then
                n = n + 1
                local t = Icon(o, n)
                t:SetTexture(a.icon)
                t:Show()
            end
        end
    end
    for i = n + 1, #o.icons do o.icons[i]:Hide() end
    return n
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
        if what ~= "buffs" then GX.UpdateTarget(f) end
        if what ~= "targets" then GX.UpdateBuffs(f) end
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
    if not (dirtyT or dirtyB) then return end
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
