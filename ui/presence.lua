--------------------------------------------------
-- WeintCodex :: Oberflaeche - Ruhe, Bereit, Kampf
--------------------------------------------------
-- Die Oberflaeche atmet (docs/design/ui-2.0.md, Grundsatz 5): drei
-- Zustaende statt einer Oberflaeche, die immer gleich laut ist.
--
--   Kampf   im Kampf                                  -> alles voll
--   Bereit  ein Ziel, ein laufender Zauber, oder das  -> alles voll
--           Leben ist nicht voll
--   Ruhe    sonst, nach einer kurzen Nachlaufzeit     -> Spielerrahmen
--           und Leisten treten zurueck, die Schadensanzeige wird leiser
--
-- Die Maus holt jedes Element sofort zurueck, solange sie darauf steht.
--
-- NUR DECKKRAFT. SetAlpha ist auch an geschuetzten Rahmen (Einheiten-
-- rahmen, Aktionsleisten) im Kampf erlaubt; Zeigen, Verstecken und
-- Verschieben waeren es nicht. Ein Rahmen auf 0 % bleibt deshalb
-- klickbar - in Ruhe ist man nicht im Kampf, und die Maus bringt ihn
-- ohnehin zurueck.
--
-- Die Module melden ihre Rahmen hier an (P.Register); welche Deckkraft
-- ein Element in Ruhe hat, steht beim Modul "general" (Seite "Ruhe und
-- Kampf" im Fenster).
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIPresence = {}

local P = WeintCodex.UIPresence
local K = WeintCodex.UIKit

-- Einstellungen: liegen beim Modul "general" (ui/options.lua mischt sie
-- in dessen Voreinstellungen).
P.DEFAULTS = {
    presence        = true,
    presenceDelay   = 4,     -- Sekunden nach Kampf/Zielverlust bis Ruhe
    fade_player     = 35,    -- Spielerrahmen (und Begleiter) in Ruhe, %
    fade_mainbar    = 100,   -- Aktionsleiste 1
    fade_bars       = 0,     -- alle weiteren Aktionsleisten
    fade_damage     = 45,    -- Schadensanzeige
}

local function Opt(k)
    local v = K.Get("general", k)
    if v == nil then v = P.DEFAULTS[k] end
    return v
end

local elements, order = {}, {}
local state = "bereit"
local forcedBy = {}   -- [Grund] = true: Testmodus, Entsperren - alles voll
local FADE_TIME = 0.2

P.elements = elements

-- key: Name des Elements; getFrames: Funktion, die die Rahmen liefert
-- (die Blizzard-Leisten gibt es womoeglich erst spaeter); setting: der
-- Schluessel der Deckkraft in Ruhe.
function P.Register(key, getFrames, setting)
    if not elements[key] then order[#order + 1] = key end
    elements[key] = { get = getFrames, setting = setting, cur = 1, hover = false, hooked = {} }
    P.HookHover(key)
    P.Apply(true)
end

local function Frames(el)
    local ok, list = pcall(el.get)
    if not ok or type(list) ~= "table" then return {} end
    local out = {}
    for _, f in pairs(list) do
        if type(f) == "table" and f.SetAlpha and not (f.IsForbidden and f:IsForbidden()) then
            out[#out + 1] = f
        end
    end
    return out
end

-- Die Maus: jede Flaeche, die Mausereignisse bekommt, meldet Betreten und
-- Verlassen. Bei Leisten sind das die Knoepfe, nicht die Leiste.
local leaveToken = 0
local function SetHover(el, on)
    el.hover = on
    if on then
        P.Apply()
    else
        leaveToken = leaveToken + 1
        local token = leaveToken
        -- Kurz warten: von Knopf zu Knopf ist die Maus einen Augenblick
        -- auf keinem.
        if _G.C_Timer and _G.C_Timer.After then
            _G.C_Timer.After(0.3, function() if token == leaveToken then P.Apply() end end)
        else
            P.Apply()
        end
    end
end

local function Hook(el, f)
    if el.hooked[f] or not f.HookScript then return end
    el.hooked[f] = true
    pcall(f.HookScript, f, "OnEnter", function() SetHover(el, true) end)
    pcall(f.HookScript, f, "OnLeave", function() SetHover(el, false) end)
end

function P.HookHover(key)
    local el = elements[key]
    if not el then return end
    for _, f in ipairs(Frames(el)) do
        Hook(el, f)
        if f.GetChildren then
            for _, c in ipairs({ f:GetChildren() }) do
                if type(c) == "table" and c.HookScript and c.IsMouseEnabled
                   and K.Bool(c:IsMouseEnabled(), false) then
                    Hook(el, c)
                end
            end
        end
    end
end

--------------------------------------------------
-- Der Zustand
--------------------------------------------------

local function HealthFull()
    local cur = K.Plain(_G.UnitHealth and _G.UnitHealth("player"))
    local max = K.Plain(_G.UnitHealthMax and _G.UnitHealthMax("player"))
    -- Unbekannt ist nicht "voll": wer seine Lebenspunkte nicht lesen kann,
    -- soll sie wenigstens sehen.
    if type(cur) ~= "number" or type(max) ~= "number" then return false end
    return cur >= max
end

function P.Compute()
    if K.InCombat() or K.Bool(_G.UnitAffectingCombat and _G.UnitAffectingCombat("player"), false) then
        return "kampf"
    end
    if K.Bool(_G.UnitExists and _G.UnitExists("target"), false) then return "bereit" end
    -- Wer zaubert (Ruhestein, Verband), will seinen Zauberbalken sehen -
    -- er haengt am Spielerrahmen und traete sonst mit ihm zurueck.
    local cast = _G.UnitCastingInfo and _G.UnitCastingInfo("player")
    local chan = _G.UnitChannelInfo and _G.UnitChannelInfo("player")
    if type(cast) ~= "nil" or type(chan) ~= "nil" then return "bereit" end
    if K.Bool(_G.UnitIsDeadOrGhost and _G.UnitIsDeadOrGhost("player"), false) then return "bereit" end
    if not HealthFull() then return "bereit" end
    return "ruhe"
end

function P.State() return state end

local function Forced()
    for _ in pairs(forcedBy) do return true end
    return false
end

local function TargetAlpha(el)
    if Forced() or el.hover or not Opt("presence") or state ~= "ruhe" then return 1 end
    local v = Opt(el.setting)
    if type(v) ~= "number" then return 1 end
    return math.max(0, math.min(1, v / 100))
end

-- Den Rahmen die Deckkraft geben: sanft ueber FADE_TIME, oder sofort.
local driver = CreateFrame("Frame")
local function Step(_, elapsed)
    local busy = false
    local d = (elapsed or 0) / FADE_TIME
    for _, key in ipairs(order) do
        local el = elements[key]
        local goal = TargetAlpha(el)
        if el.cur ~= goal then
            if el.cur < goal then el.cur = math.min(goal, el.cur + d) else el.cur = math.max(goal, el.cur - d) end
            for _, f in ipairs(Frames(el)) do f:SetAlpha(el.cur) end
            if el.cur ~= goal then busy = true end
        end
    end
    if not busy then driver:SetScript("OnUpdate", nil) end
end

function P.Apply(instant)
    if instant then
        for _, key in ipairs(order) do
            local el = elements[key]
            el.cur = TargetAlpha(el)
            for _, f in ipairs(Frames(el)) do f:SetAlpha(el.cur) end
        end
        return
    end
    driver:SetScript("OnUpdate", Step)
end

-- Zustand neu bestimmen. In die Ruhe geht es erst nach der Nachlaufzeit
-- (nach dem Kampf will man die Zahlen noch sehen); heraus sofort.
local calmToken = 0
function P.Evaluate(now)
    local want = P.Compute()
    if want == "ruhe" and state ~= "ruhe" and not now then
        calmToken = calmToken + 1
        local token = calmToken
        local delay = Opt("presenceDelay") or 4
        if _G.C_Timer and _G.C_Timer.After and delay > 0 then
            _G.C_Timer.After(delay, function()
                if token == calmToken and P.Compute() == "ruhe" then
                    state = "ruhe"
                    P.Apply()
                end
            end)
            return
        end
    end
    calmToken = calmToken + 1
    if want ~= state then
        state = want
        P.Apply()
    end
end

-- Testmodus und Entsperren zeigen alles voll - jeder aus eigenem Grund,
-- damit das Ende des einen das andere nicht mit beendet.
function P.Force(reason, on)
    forcedBy[reason] = on and true or nil
    P.Apply(true)
end

local events = CreateFrame("Frame")
for _, e in ipairs({ "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED",
    "PLAYER_TARGET_CHANGED", "UNIT_HEALTH", "UNIT_MAXHEALTH", "PLAYER_DEAD", "PLAYER_ALIVE",
    "PLAYER_UNGHOSTED", "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_STOP",
    "UNIT_SPELLCAST_CHANNEL_START", "UNIT_SPELLCAST_CHANNEL_STOP" }) do
    pcall(events.RegisterEvent, events, e)
end
events:SetScript("OnEvent", function(_, event, unit)
    if event:find("^UNIT_") and unit ~= "player" then return end
    if event == "PLAYER_ENTERING_WORLD" then
        -- Leisten, die das Spiel erst jetzt angelegt hat, bekommen ihre
        -- Maushaken nachgereicht.
        for _, key in ipairs(order) do P.HookHover(key) end
        P.Evaluate(true)
        P.Apply(true)
        return
    end
    -- In den Kampf: sofort voll, ohne Blende.
    if event == "PLAYER_REGEN_DISABLED" then
        state = "kampf"
        calmToken = calmToken + 1
        P.Apply(true)
        return
    end
    P.Evaluate()
end)

K.Listen(function(kind, moduleKey, key)
    if kind == "unlock" then P.Force("unlock", moduleKey) end
    if kind == "setting" and moduleKey == "general" then P.Apply(true) end
end)
