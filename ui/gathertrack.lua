--------------------------------------------------
-- WeintCodex :: Kraeuter und Erz zugleich suchen (Wechsel der Suche)
--------------------------------------------------
-- Seit 6.22.0.0 (Beta-Test: "Mineraliensuche und Kraeutersuche zusammen
-- ... 0,5 sec Wechsel"). Das Spiel laesst immer nur EINE Suche laufen -
-- wer die zweite waehlt, schaltet die erste ab. Dieser Teil wechselt
-- ausserhalb des Kampfes in einem festen Takt zwischen beiden.
--
-- WAS NICHT GEHT, und warum:
--   * 0,5 s: ein Wechsel ist ein Zauber und loest in Classic die globale
--     Abklingzeit aus (1,5 s). Schneller als FA.MIN wechselt nichts.
--   * Beide Punkte zugleich: die gelben Punkte zeichnet das Spiel nur fuer
--     die GERADE laufende Suche. Nach dem Wechsel sind die anderen weg -
--     jede Art steht jeden zweiten Takt auf der Minikarte.
--   * Eigene Symbole fuer Kraut und Erz: die Punkte sind ein Bild des
--     Spiels fuer alle Suchen, Addons erfahren weder Lage noch Art.
--
-- UNGEMESSEN: ob Forever Addons die Suche selbst wechseln laesst. Meldet
-- das Spiel ADDON_ACTION_BLOCKED/FORBIDDEN kurz nach einem Wechsel, oder
-- bleibt der Wechsel dreimal ohne Wirkung, schaltet sich der Wechsel ab
-- und sagt es; /wcui prüfen zeigt die Zaehler.
--------------------------------------------------

local K = WeintCodex.UIKit
local KEY = "comfort"

WeintCodex.UIGatherTrack = {}
local GT = WeintCodex.UIGatherTrack

GT.DEFAULTS = {
    gatherSwap  = false,
    gatherEvery = 20,      -- Zehntelsekunden
}
GT.MIN = 15                -- globale Abklingzeit: 1,5 s
GT.SPELLS = { herb = 2383, ore = 2580 }   -- Kraeutersuche, Mineraliensuche
GT.BLOCK_WINDOW = 0.5
GT.MAX_NOEFFECT = 3

local stats = { swaps = 0, paused = 0, noEffect = 0, blocked = 0 }
GT.stats = stats
GT.stopped = nil            -- Grund, warum der Wechsel sich abgeschaltet hat
local swapAt = -math.huge
local pending              -- Index, der nach dem letzten Wechsel an sein muss
local misses = 0

local function Say(text) print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " " .. text) end

local function Now()
    local t = _G.GetTime and K.Plain(_G.GetTime())
    return type(t) == "number" and t or 0
end

function GT.Active() return K.IsActive(KEY) and K.Get(KEY, "gatherSwap") and true or false end
function GT.Every()
    local v = tonumber(K.Get(KEY, "gatherEvery")) or GT.DEFAULTS.gatherEvery
    return math.max(GT.MIN, v) / 10
end

--------------------------------------------------
-- Suchen des Spiels lesen und setzen
--------------------------------------------------

local function API()
    local cm = _G.C_Minimap
    if cm and cm.GetNumTrackingTypes and cm.GetTrackingInfo and cm.SetTracking then
        return cm.GetNumTrackingTypes, cm.GetTrackingInfo, cm.SetTracking
    end
    if _G.GetNumTrackingTypes and _G.GetTrackingInfo and _G.SetTracking then
        return _G.GetNumTrackingTypes, _G.GetTrackingInfo, _G.SetTracking
    end
end
GT.API = API

local function SpellName(id)
    local cs = _G.C_Spell
    if cs and cs.GetSpellName then
        local ok, n = pcall(cs.GetSpellName, id)
        if ok and type(K.Plain(n)) == "string" then return K.Plain(n) end
    end
    if _G.GetSpellInfo then
        local ok, n = pcall(_G.GetSpellInfo, id)
        if ok and type(K.Plain(n)) == "string" then return K.Plain(n) end
    end
end

-- name, aktiv, spellID einer Suche - Tabelle (neuer Client) oder Liste.
local function Info(get, i)
    local ok, a, b, c, d, e, f = pcall(get, i)
    if not ok then return end
    if type(a) == "table" then
        return K.Plain(a.name), K.Bool(a.active, false), K.Plain(a.spellID)
    end
    return K.Plain(a), K.Bool(c, false), nil
end

-- Indizes von Kraeuter- und Mineraliensuche und welche gerade an ist.
function GT.Find()
    local num, get = API()
    if not num then return nil end
    local ok, n = pcall(num)
    n = ok and K.Plain(n)
    if type(n) ~= "number" then return nil end
    local herbName, oreName = SpellName(GT.SPELLS.herb), SpellName(GT.SPELLS.ore)
    local herb, ore, on
    for i = 1, n do
        local name, active, spell = Info(get, i)
        local isHerb = spell == GT.SPELLS.herb or (herbName and name == herbName)
        local isOre = spell == GT.SPELLS.ore or (oreName and name == oreName)
        if isHerb then herb = i if active then on = i end end
        if isOre then ore = i if active then on = i end end
    end
    return herb, ore, on
end

function GT.IsOn(i)
    local _, get = API()
    if not (get and i) then return false end
    local _, active = Info(get, i)
    return active and true or false
end

-- Pause: im Kampf, tot, beim Zaubern (der Wechsel wuerde unterbrechen).
function GT.Paused()
    if _G.InCombatLockdown and K.Bool(_G.InCombatLockdown(), false) then return "Kampf" end
    if _G.UnitIsDeadOrGhost and K.Bool(_G.UnitIsDeadOrGhost("player"), false) then return "tot" end
    if _G.UnitCastingInfo and type(_G.UnitCastingInfo("player")) ~= "nil" then return "zaubert" end
    if _G.UnitChannelInfo and type(_G.UnitChannelInfo("player")) ~= "nil" then return "zaubert" end
    return nil
end

local function Stop(reason, text)
    GT.stopped = reason
    K.Set(KEY, "gatherSwap", false)
    Say(text)
end

-- Ein Takt: hat der letzte Wechsel gewirkt? Dann zur anderen Suche.
function GT.Swap()
    if not GT.Active() then return false end
    if pending then
        if GT.IsOn(pending) then misses = 0
        else
            misses = misses + 1
            stats.noEffect = stats.noEffect + 1
            if misses >= GT.MAX_NOEFFECT then
                pending = nil
                Stop("ohne Wirkung", "Die Suche lässt sich von WeintCodex nicht wechseln – der Wechsel ist wieder aus.")
                return false
            end
        end
        pending = nil
    end
    if GT.Paused() then stats.paused = stats.paused + 1 return false end
    local herb, ore, on = GT.Find()
    if not (herb and ore) then return false end
    local target = (on == herb) and ore or herb
    local _, _, set = API()
    swapAt = Now()
    local ok = pcall(set, target, true)
    if not ok then return false end
    pending = target
    stats.swaps = stats.swaps + 1
    return true
end

-- ADDON_ACTION_BLOCKED/FORBIDDEN kurz nach einem eigenen Wechsel.
function GT.OnBlocked(addon)
    if K.Plain(addon) ~= "WeintCodex" or Now() - swapAt > GT.BLOCK_WINDOW then return false end
    stats.blocked = stats.blocked + 1
    pending = nil
    Stop("gesperrt", "Das Spiel lässt WeintCodex die Suche nicht wechseln – der Wechsel ist wieder aus.")
    return true
end

--------------------------------------------------
-- Takt
--------------------------------------------------

local ticker = CreateFrame("Frame")
ticker:Hide()
local acc = 0
ticker:SetScript("OnUpdate", K.Measured("Suche wechseln", function(_, el)
    acc = acc + (el or 0)
    if acc < GT.Every() then return end
    acc = 0
    GT.Swap()
end))
GT.ticker = ticker

local ev = CreateFrame("Frame")
ev:SetScript("OnEvent", function(_, event, addon)
    if event == "ADDON_ACTION_BLOCKED" or event == "ADDON_ACTION_FORBIDDEN" then GT.OnBlocked(addon) end
end)

local function Apply()
    if GT.Active() then
        GT.stopped, misses, pending, acc = nil, 0, nil, 0
        pcall(ev.RegisterEvent, ev, "ADDON_ACTION_BLOCKED")
        pcall(ev.RegisterEvent, ev, "ADDON_ACTION_FORBIDDEN")
        ticker:Show()
    else
        pcall(ev.UnregisterEvent, ev, "ADDON_ACTION_BLOCKED")
        pcall(ev.UnregisterEvent, ev, "ADDON_ACTION_FORBIDDEN")
        ticker:Hide()
    end
end
GT.Apply = Apply

--------------------------------------------------
-- Bericht und Seite
--------------------------------------------------

function GT.StatusLines()
    local out = {}
    local num = API()
    local herb, ore, on = GT.Find()
    out[#out + 1] = "Suchen lesen/setzen: " .. (num and "ja" or "nein")
        .. " · Kräutersuche: " .. (herb and "gelernt" or "nicht gefunden")
        .. " · Mineraliensuche: " .. (ore and "gelernt" or "nicht gefunden")
        .. (on and (" · an: " .. (on == herb and "Kräuter" or "Erz")) or "")
    out[#out + 1] = string.format("Gewechselt %d · pausiert %d · ohne Wirkung %d · gesperrt %d",
        stats.swaps, stats.paused, stats.noEffect, stats.blocked)
    if GT.stopped then out[#out + 1] = "Abgeschaltet: " .. GT.stopped end
    return out
end

local function Build(B)
    local off = function() return not K.Get(KEY, "gatherSwap") end
    B:Section("Kräuter und Erz", "Das Spiel lässt nur eine Suche zugleich laufen. WeintCodex wechselt außerhalb des Kampfes zwischen Kräuter- und Mineraliensuche – auf der Minikarte steht jede Art jeden zweiten Takt.")
    B:Row({ type = "toggle", label = "Kräuter- und Mineraliensuche wechseln", key = "gatherSwap",
            description = "Pause im Kampf und beim Zaubern." },
          { type = "slider", label = "Wechsel alle", key = "gatherEvery", min = GT.MIN, max = 100, step = 5,
            format = function(v) return string.format("%.1f s", v / 10) end, disabled = off })
    B:Note("Jeder Wechsel ist ein Zauber mit globaler Abklingzeit – darum nicht schneller als 1,5 s. Die Punkte bleiben gelb: welcher Punkt Kraut und welcher Erz ist, verrät das Spiel Addons nicht.")
end

local mod = K.Module(KEY)
if mod then
    for k, v in pairs(GT.DEFAULTS) do
        if mod.defaults[k] == nil then mod.defaults[k] = v end
    end
    mod.pages[#mod.pages + 1] = { key = "sammeln", label = "Sammeln", build = Build }
end

K.Listen(function(kind, key)
    if (kind == "active" or kind == "setting") and key == KEY then Apply() end
end)
