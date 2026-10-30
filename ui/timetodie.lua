--------------------------------------------------
-- WeintCodex :: Oberflaeche - Sterbezeit an der Plakette
--------------------------------------------------
-- Wunsch des Besitzers (1.8.0.0): "wann das Ziel sekundengenau stirbt,
-- mit dem Schaden berechnet, der auf dem Ziel gemacht wurde" - und "Does
-- it die": reichen die eigenen DoTs, wenn man nichts mehr tut?
--
-- STERBEZEIT. Je Gegner (GUID) die letzten Lebensstaende mit Zeit, ueber
-- hoechstens TD.WINDOW Sekunden; die Steigung (kleinste Quadrate) ist der
-- Schaden je Sekunde ALLER, die draufhauen - Leben / Schaden je Sekunde
-- ist die Zeit. Zwischen zwei Treffern zaehlt die Anzeige weiter herunter.
--
-- STERBEN DIE DOTS? Ohne Kampflog (Addons haben keins) und ohne Auren im
-- Kampf (geheim) rechnet WeintCodex mit dem, was es sieht: das eigene
-- Wirken (UNIT_SPELLCAST_SUCCEEDED) auf das angreifbare Ziel und die
-- Beschreibung des Zaubers aus dem Client ("… im Verlauf von 18 Sek. 66
-- Schattenschaden" / "… 66 Shadow damage over 18 sec"). Restschaden =
-- Gesamtschaden x Restzeit / Dauer, je laufendem DoT. Kein Bestand von
-- Hand: was die Beschreibung nicht so nennt, zaehlt nicht. Kanalisierte
-- Zauber (Gedankenschinden) enden mit dem Kanal und zaehlen nie.
--
-- WAS NICHT GERATEN WIRD.
--   * Ist das Leben geheim (12.x im Kampf), gibt es keine Zahl - die
--     Plakette schweigt, /wcui pruefen zaehlt es (TD.stats.secret).
--   * Unter TD.MIN_SPAN Sekunden Messung oder ohne sinkendes Leben:
--     keine Zeit (unbekannt ist nicht "nie").
--   * Die Beschreibung nennt den Schaden ohne Kritische und ohne
--     Wirkung von Talenten: das Urteil ist eine Schaetzung, und so steht
--     es auch im Tooltip der Einstellung.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UITimeToDie = {}

local TD = WeintCodex.UITimeToDie
local K = WeintCodex.UIKit

TD.WINDOW   = 12     -- Sekunden Verlauf je Gegner
TD.MIN_SPAN = 2      -- so lange messen, bevor eine Zeit steht
TD.SLOTS    = 24     -- Lebensstaende je Gegner (Ring, einmal angelegt)
TD.MAX_UNITS = 40    -- so viele Gegner merkt es sich hoechstens
TD.stats = { secret = 0, samples = 0, dots = 0, unknownSpell = 0 }

-- guid -> { t = {}, h = {}, n = 0, head = 0, seen = Zeit }
local hist = {}
local histCount = 0
-- guid -> { [spellId] = Ablauf }
local dots = {}
-- spellId -> { total, dur } | false (kein DoT laut Beschreibung)
local spellCache = {}
local channeled = {}

local function Now() return K.Plain(_G.GetTime and _G.GetTime()) or 0 end

--------------------------------------------------
-- Verlauf
--------------------------------------------------

local function Forget()
    local oldG, oldT
    for g, r in pairs(hist) do
        if not oldT or r.seen < oldT then oldG, oldT = g, r.seen end
    end
    if oldG then hist[oldG] = nil histCount = histCount - 1 end
end

local function Record(guid, hp, now)
    local r = hist[guid]
    if not r then
        if histCount >= TD.MAX_UNITS then Forget() end
        r = { t = {}, h = {}, n = 0, head = 0, seen = now }
        hist[guid] = r
        histCount = histCount + 1
    end
    -- Leben gestiegen (Heilung, Ruecksetzen): der alte Verlauf luegt.
    if r.n > 0 and hp > r.h[r.head] then r.n = 0 end
    -- Gleicher Zeitpunkt: nur den Wert ersetzen.
    if r.n > 0 and r.t[r.head] == now then
        r.h[r.head] = hp
    else
        r.head = r.head % TD.SLOTS + 1
        r.t[r.head], r.h[r.head] = now, hp
        if r.n < TD.SLOTS then r.n = r.n + 1 end
    end
    r.seen = now
    TD.stats.samples = TD.stats.samples + 1
    return r
end

-- Schaden je Sekunde ueber das Fenster (kleinste Quadrate), oder nil.
function TD.Rate(r, now)
    if not r or r.n < 2 then return nil end
    local n, st, sh, stt, sth = 0, 0, 0, 0, 0
    local first
    for i = 0, r.n - 1 do
        local idx = (r.head - 1 - i) % TD.SLOTS + 1
        local t = r.t[idx]
        if now - t > TD.WINDOW then break end
        local x = t - now
        n, st, sh, stt, sth = n + 1, st + x, sh + r.h[idx], stt + x * x, sth + x * r.h[idx]
        first = t
    end
    if n < 2 or not first or now - first < TD.MIN_SPAN then return nil end
    local den = n * stt - st * st
    if den <= 0 then return nil end
    local slope = (n * sth - st * sh) / den
    if slope >= 0 then return nil end
    return -slope
end

--------------------------------------------------
-- Eigene DoTs
--------------------------------------------------

local function Num(s)
    if not s then return nil end
    -- Tausender: "1.200" (de) bzw. "1,200" (en); Dauer "1,5" gibt es bei DoTs nicht.
    return tonumber((s:gsub("[%.,]", "")))
end

-- Liest Gesamtschaden und Dauer aus der Beschreibung des Clients.
function TD.ParseDot(desc)
    if type(desc) ~= "string" or desc == "" then return nil end
    -- de: "im Verlauf von 18 Sek. 66 Schattenschaden" / "… weitere 12 Arkanschaden"
    local s, e, dur = desc:find("[Ii]m Verlauf von (%d+) Sek")
    if dur then
        local amount = desc:match("^%D-(%d[%d%.]*)%s+%S-[Ss]chaden", e + 1)
        if amount then return Num(amount), tonumber(dur) end
    end
    -- en: "66 Shadow damage over 18 sec"
    local amount, dur2 = desc:match("(%d[%d,]*)%s+%a*%s*damage over (%d+) sec")
    if amount then return Num(amount), tonumber(dur2) end
    return nil
end

local function DotOf(id)
    local c = spellCache[id]
    if c ~= nil then return c end
    local desc = _G.C_Spell and _G.C_Spell.GetSpellDescription and _G.C_Spell.GetSpellDescription(id)
    desc = K.Plain(desc)
    -- Noch nicht geladen: nicht als "kein DoT" merken.
    if type(desc) ~= "string" or desc == "" then return false end
    local total, dur = TD.ParseDot(desc)
    if total and dur and total > 0 and dur > 0 then
        c = { total = total, dur = dur }
    else
        c = false
    end
    spellCache[id] = c
    return c
end

function TD.OnCast(id)
    id = K.Plain(id)
    if type(id) ~= "number" or channeled[id] then return end
    local d = DotOf(id)
    if not d then return end
    if not K.Bool(_G.UnitCanAttack and _G.UnitCanAttack("player", "target"), false) then return end
    local guid = K.Plain(_G.UnitGUID and _G.UnitGUID("target"))
    if type(guid) ~= "string" then return end
    local list = dots[guid]
    if not list then list = {} dots[guid] = list end
    list[id] = Now() + d.dur
    TD.stats.dots = TD.stats.dots + 1
end

-- Restschaden der eigenen DoTs auf `guid`, oder nil ohne laufenden DoT.
function TD.DotRemaining(guid, now)
    local list = dots[guid]
    if not list then return nil end
    local sum, any = 0, false
    for id, expires in pairs(list) do
        local left = expires - now
        local d = spellCache[id]
        if left <= 0 or not d then
            list[id] = nil
        else
            any = true
            sum = sum + d.total * math.min(left, d.dur) / d.dur
        end
    end
    if not any then dots[guid] = nil return nil end
    return sum
end

--------------------------------------------------
-- Anzeige
--------------------------------------------------

local function Hex(c)
    return string.format("%02x%02x%02x", math.floor(c[1] * 255 + 0.5),
        math.floor(c[2] * 255 + 0.5), math.floor(c[3] * 255 + 0.5))
end

function TD.Format(sec)
    sec = math.floor(sec + 0.5)
    if sec >= 60 then return string.format("%d:%02d", math.floor(sec / 60), sec % 60) end
    return string.format("%d s", sec)
end

local shown = {}   -- p -> true, solange der Text steht (Takt zaehlt herunter)

local function Hide(p)
    if p.ttd then p.ttd:Hide() end
    shown[p] = nil
end

local function Draw(p, S, now)
    local fs = p.ttd
    local timeText, verdict = "", ""
    if p._ttdEnd then
        timeText = TD.Format(math.max(0, p._ttdEnd - now))
    end
    if S.ttdDots and p._ttdGuid and p._ttdHp then
        local rest = TD.DotRemaining(p._ttdGuid, now)
        if rest then
            local C = WeintCodex.Colors
            if rest >= p._ttdHp then
                verdict = "|cff" .. Hex(C.green) .. "DoTs reichen|r"
            else
                verdict = "|cff" .. Hex(C.red) .. "DoTs reichen nicht|r"
            end
        end
    end
    if timeText == "" and verdict == "" then Hide(p) return end
    fs:SetFormattedText("%s%s%s", timeText, (timeText ~= "" and verdict ~= "") and "  " or "", verdict)
    fs:Show()
    shown[p] = true
end

-- Aus ui/nameplates.lua: bei jedem UNIT_HEALTH und Zielwechsel.
function TD.Update(p, S, sample)
    if not p.ttd then return end
    if not (S.ttd or S.ttdDots) or p._friendly or not p.unit
        or (S.ttdTargetOnly and p._isTarget ~= true) then
        Hide(p) return
    end
    local unit = p.unit
    local guid = K.Plain(_G.UnitGUID and _G.UnitGUID(unit))
    local hp = K.Plain(_G.UnitHealth and _G.UnitHealth(unit))
    if type(guid) ~= "string" or type(hp) ~= "number" then
        -- Unbekannt, nicht 0: die Plakette schweigt.
        if type(hp) ~= "number" then TD.stats.secret = TD.stats.secret + 1 end
        p._ttdEnd, p._ttdGuid, p._ttdHp = nil, nil, nil
        Hide(p) return
    end
    local now = Now()
    local r = hist[guid]
    if sample ~= false then r = Record(guid, hp, now) end
    p._ttdGuid, p._ttdHp = guid, hp
    p._ttdEnd = nil
    if S.ttd and hp > 0 then
        local rate = TD.Rate(r, now)
        if rate then p._ttdEnd = now + hp / rate end
    end
    Draw(p, S, now)
end

-- Takt: einmal je Sekunde die stehenden Texte herunterzaehlen.
function TD.Tick()
    local NP = WeintCodex.UINameplates
    local S = NP and NP.Settings and NP.Settings()
    if not S then return end
    local now = Now()
    for p in pairs(shown) do
        if p.unit and p.ttd and p.ttd:IsShown() then Draw(p, S, now) else shown[p] = nil end
    end
end

function TD.Reset()
    wipe(hist) wipe(dots) wipe(shown)
    histCount = 0
end

local frame = CreateFrame("Frame")
local function Listen(name) pcall(frame.RegisterEvent, frame, name) end
frame:SetScript("OnEvent", function(_, event, unit, _, spellId)
    if event == "PLAYER_REGEN_ENABLED" then
        -- Nach dem Kampf: Verlauf und abgelaufene DoTs weg.
        wipe(hist) histCount = 0
        local now = Now()
        for g in pairs(dots) do TD.DotRemaining(g, now) end
        return
    end
    if unit ~= "player" then return end
    if event == "UNIT_SPELLCAST_CHANNEL_START" then
        spellId = K.Plain(spellId)
        if type(spellId) == "number" then channeled[spellId] = true end
    else
        TD.OnCast(spellId)
    end
end)
Listen("UNIT_SPELLCAST_SUCCEEDED")
Listen("UNIT_SPELLCAST_CHANNEL_START")
Listen("PLAYER_REGEN_ENABLED")

if _G.C_Timer and _G.C_Timer.NewTicker then
    TD.ticker = _G.C_Timer.NewTicker(1, TD.Tick)
end

-- Fuer /wcui pruefen.
function TD.Report()
    local s = TD.stats
    return string.format("Sterbezeit: %d Lebensstände, %d geheim (keine Zeit), %d DoTs gewirkt",
        s.samples, s.secret, s.dots)
end
