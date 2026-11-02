--------------------------------------------------
-- WeintCodex :: Bosskaempfe - Timer und Warnungen (Komfort, 1.10.0.0)
--------------------------------------------------
-- Wunsch des Besitzers: "In Codex muss noch sowas wie BigWigs rein." Das
-- Verhalten folgt BigWigs, der Code ist eigener - BigWigs ist "All Rights
-- Reserved". (Fuer Forever bringt BigWigs selbst kein einziges Bossmodul
-- mit; es lebt dort von dem, was das Spiel meldet - genau das nutzt auch
-- dieser Helfer.)
--
-- WAS ES KANN
--   * Pulltimer: /pull 10 (0 bricht ab). Gezaehlt wird ueber den Countdown
--     des Spiels (C_PartyInfo.DoCountdown) - das Spiel zeigt ihn der ganzen
--     Gruppe, WeintCodex sendet dafuer nichts. Die Leiste erscheint auch,
--     wenn jemand anderes den Countdown startet (START_PLAYER_COUNTDOWN).
--   * Pause: /break 5 (Minuten, 0 bricht ab) - nur fuer dich.
--   * Timer anderer Bossmods hoeren: Pull und Pause aus BigWigs (Praefix
--     "BigWigs", "P^Pull^10" / "P^Break^300") und DBM ("D5", "PT"/"BT").
--     Nur zuhoeren, nie senden.
--   * Kampftimer: ENCOUNTER_START bis ENCOUNTER_END, dazu am Ende "besiegt
--     in 3:12" mit der eigenen Bestzeit je Boss und Schwierigkeit
--     (SavedData.bossTimes) oder "Wipe nach 1:47".
--   * Faehigkeiten des Bosses als Leisten aus der Zeitleiste des Spiels
--     (ENCOUNTER_TIMELINE_EVENT_ADDED/REMOVED) und Warnungen des Spiels
--     gross in der Mitte (ENCOUNTER_WARNING).
--   * Toene je Anlass (1.10.3.0, Wunsch: "welche Toene kann ich wann wo
--     einstellen"): Pull zu Ende, Pause zu Ende, kurz vor einer Faehigkeit
--     (Vorwarnung 2-5 s), Warnung des Spiels, Sieg, Wipe - jeder aus der
--     Liste von "Raus da!" (FA.SOUNDS, mit Memes und eigenen Toenen der
--     Companion) oder "Kein Ton"; dazu "Wo" und der Lautstaerke-Kanal.
--     Ein Probekampf spielt alles einmal ab.
--
-- WAS ES NICHT KANN, mit Absicht
--   * Taktiken je Boss, eigene Warnungen "lauf raus" - fuer keinen Kampf in
--     Forever gibt es eine Quelle (CLAUDE.md, Rollen). Gezeigt wird nur, was
--     das Spiel selbst meldet.
--   * Ob Forever die Zeitleiste und die Warnungen ueberhaupt schickt, ist
--     NICHT gemessen. /wcui prüfen zaehlt, was ankam (BM.stats). Ist eine
--     Dauer geheim, entsteht keine Leiste - eine geratene Zeit waere
--     schlimmer als keine.
--------------------------------------------------

local K = WeintCodex.UIKit
local C = WeintCodex.Colors
local KEY = "comfort"

WeintCodex.UIBossMod = {}
local BM = WeintCodex.UIBossMod

BM.DEFAULTS = {
    bossPull     = true,    -- Pull-/Pausenleiste und /pull, /break
    bossListen   = true,    -- Timer aus BigWigs und DBM hoeren
    bossFight    = true,    -- Kampftimer und Bestzeit
    bossTimeline = true,    -- Faehigkeiten aus der Zeitleiste des Spiels
    bossWarnings = false,   -- Warnungen des Spiels gross in der Mitte (das Spiel zeigt eigene)
    bossSound    = true,    -- Hauptschalter fuer alle Toene unten
    -- Toene je Anlass (1.10.3.0): Schluessel aus FA.SOUNDS oder "none".
    -- Ab Werk wie vorher: Pull-Ende mit Bereitschaftscheck, sonst still -
    -- das Spiel hat fuer seine Warnungen eigene Toene.
    bossSndPull  = "ready",
    bossSndBreak = "alarm2",
    bossSndSoon  = "none",
    bossSndWarn  = "none",
    bossSndKill  = "none",
    bossSndWipe  = "none",
    bossSndCast  = "none",  -- 1.10.6.0: ein Boss beginnt zu zaubern
    bossCasts    = true,    -- 1.10.6.0: Zauber der Bosse als Leisten
    bossLearn    = true,    -- 1.10.8.0: Zeiten aus eigenen Kaempfen lernen
    bossSoonSecs = 3,       -- Vorwarnung: so viele Sekunden vor der Faehigkeit
    bossWhere    = "all",   -- all | group | instance (wie bei "Raus da!")
    bossChannel  = "Master",
    -- Aussehen der Leisten (1.10.4.0, "so wie DBM oder BigWigs").
    bossBarW     = 240,     -- Breite
    bossBarH     = 20,      -- Hoehe
    bossFont     = 11,      -- Schriftgroesse
    bossMax      = 8,       -- hoechstens so viele Leisten
    bossGrow     = "down",  -- down | up
    bossIcon     = "left",  -- left | right | none
    bossFill     = "drain", -- drain (leert sich) | fill (fuellt sich)
    bossEmph     = true,    -- was gleich dran ist, gross am zweiten Anker
    bossEmphSecs = 5,       -- ab so vielen Sekunden Rest
    bossWarnSize = 24,      -- Schrift der grossen Warnung
    bossWarnTime = 4,       -- so lange steht sie (s)
    bossTrack    = false,   -- 1.10.6.0: Zeitleiste von oben nach unten
    bossTrackSecs = 30,     -- 15 | 30 | 60 s im Blick
    bossTrackH   = 300,     -- Hoehe der Zeitleiste
}

-- Die Anlaesse, in der Reihenfolge der Seite.
BM.SOUND_EVENTS = { "Pull", "Break", "Soon", "Cast", "Warn", "Kill", "Wipe" }

BM.MAX_ROWS, BM.EMPH_ROWS, BM.GAP = 10, 4, 3
BM.EMPH_SCALE = 1.5
BM.stats = { timeline = 0, secret = 0, warnings = 0, encounters = 0, countdowns = 0, heard = 0,
    casts = 0, castSecret = 0, emotes = 0, engaged = 0 }

local function Plain(v) return K.Plain(v) end
local function Now() return (_G.GetTime and Plain(_G.GetTime())) or 0 end
local function Opt(k) return K.IsActive(KEY) and K.Get(KEY, k) and true or false end
BM.Opt = Opt

-- Wo die Toene gelten - dieselbe Regel wie bei "Raus da!".
function BM.Here()
    local where = K.Get(KEY, "bossWhere")
    if where == "group" then
        return K.Bool(_G.IsInGroup and _G.IsInGroup(), false) or K.Bool(_G.IsInRaid and _G.IsInRaid(), false)
    elseif where == "instance" then
        if not _G.IsInInstance then return false end
        local _, kind = _G.IsInInstance()
        kind = Plain(kind)
        return type(kind) == "string" and kind ~= "none"
    end
    return true
end

-- Ton fuer einen Anlass. Ein langer Ton (Meme) wird nicht vom naechsten
-- ueberspielt: bis er zu Ende ist, bleibt jeder weitere still.
BM.busyUntil = 0
function BM.Sound(event, force, key)
    if not force and (not Opt("bossSound") or not BM.Here()) then return nil end
    -- key: eigener Ton einer Faehigkeit (Seite "Bosse"); sonst der des Anlasses.
    if type(key) ~= "string" or key == "" then key = K.Get(KEY, "bossSnd" .. event) end
    if key == "none" or type(key) ~= "string" then return nil end
    local FA = WeintCodex.UIFireAlarm
    if not (FA and FA.PlayKey) then return nil end
    FA.MergeCustom()
    if not FA.SOUNDS[key] then key = BM.DEFAULTS["bossSnd" .. event] end
    if key == "none" or not FA.SOUNDS[key] then return nil end
    local now = Now()
    if not force and now < BM.busyUntil then return nil end
    local len = FA.PlayKey(key, K.Get(KEY, "bossChannel") or "Master")
    if not len then return nil end
    BM.busyUntil = now + math.max(len, 0.3)
    return key
end

local function Say(text)
    print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " " .. text)
end

function BM.Format(sec)
    sec = math.max(0, sec)
    if sec < 10 then return string.format("%.1f", sec) end
    sec = math.floor(sec + 0.5)
    if sec >= 60 then return string.format("%d:%02d", math.floor(sec / 60), sec % 60) end
    return tostring(sec)
end

--------------------------------------------------
-- Timer: eine Liste, nach Restzeit sortiert
--------------------------------------------------
-- timer = { key, label, icon, start, ends (nil = zaehlt hoch), color }

local timers = {}
BM.timers = timers

function BM.Start(key, label, duration, icon, color)
    local t = timers[key] or {}
    t.key, t.label, t.icon, t.color = key, label, icon, color
    t.onEnd, t.soon, t.warned, t.demo, t.emph, t.forceEmph = nil, nil, nil, nil, nil, nil
    t.hold, t.total = nil, nil
    t.start = Now()
    t.ends = duration and (t.start + duration) or nil
    timers[key] = t
    BM.Refresh()
    return t
end

function BM.Stop(key)
    if timers[key] then timers[key] = nil BM.Refresh() end
end

-- Sortiert ohne neue Tabelle je Bild: in eine feste Liste.
local order = {}
local function ByEnd(a, b)
    local ea, eb = a.ends or math.huge, b.ends or math.huge
    if ea ~= eb then return ea < eb end
    return a.key < b.key
end
function BM.Sorted()
    for i = #order, 1, -1 do order[i] = nil end
    for _, t in pairs(timers) do order[#order + 1] = t end
    table.sort(order, ByEnd)
    return order
end

--------------------------------------------------
-- Anzeige
--------------------------------------------------

local frame        -- Hauptanker mit den Leisten
local emph         -- zweiter Anker: was gleich dran ist, groesser (wie BigWigs)
local clock        -- Takt, unabhaengig davon, welcher Anker gerade sichtbar ist
local setupOn = false
local handles = {}   -- Flaechen zum Ziehen beim Einrichten (BM.Setup)
local castStarted = {}  -- Einheit -> Zaubername der laufenden Leiste (BM.CastSucceeded)
local castStartedAt = {} -- Einheit -> Zeit des Starts

local function Num(k, lo, hi)
    local v = tonumber(K.Get(KEY, k)) or BM.DEFAULTS[k]
    return math.max(lo, math.min(hi, v))
end
BM.Num = Num

-- Breite, Hoehe, Schrift, Anzahl - immer in den erlaubten Grenzen.
function BM.Look()
    return Num("bossBarW", 160, 420), Num("bossBarH", 14, 32), Num("bossFont", 9, 16), Num("bossMax", 3, BM.MAX_ROWS)
end

local function NewRow(parent)
    local r = CreateFrame("Frame", nil, parent)
    r.icon = r:CreateTexture(nil, "ARTWORK")
    r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    r.bar = K.NewBar(r)
    r.bar:SetMinMaxValues(0, 1)
    r.bg = r.bar:CreateTexture(nil, "BACKGROUND")
    r.bg:SetAllPoints(r.bar)
    local bg = C.surface2 or { 0.1, 0.1, 0.1, 1 }
    r.bg:SetColorTexture(bg[1], bg[2], bg[3], 0.8)
    r.label = K.NewText(r.bar, 11, "OVERLAY")
    r.label:SetJustifyH("LEFT")
    r.label:SetWordWrap(false)
    r.time = K.NewText(r.bar, 11, "OVERLAY")
    r:Hide()
    return r
end

-- Groesse, Schrift, Symbol und Richtung aus den Einstellungen - jederzeit,
-- auch waehrend Leisten laufen. Die Zeilen stehen nicht fest an ihrem
-- Platz: jede hat einen Ziel-Platz (slot) und gleitet dorthin (BM.Animate).
local function RowY(f, slot) return (slot - 1) * (f._h + BM.GAP) end
local function PlaceRow(r, y)
    local f = r._owner
    r._cy = y
    r:ClearAllPoints()
    if f._up then r:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, y)
    else r:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -y) end
end

local function LayRows(f, count, w, h, font)
    local icon = K.Get(KEY, "bossIcon")
    f._up, f._h = K.Get(KEY, "bossGrow") == "up", h
    f:SetSize(w, count * (h + BM.GAP) - BM.GAP)
    for i, r in ipairs(f.rows) do
        r:SetSize(w, h)
        PlaceRow(r, RowY(f, r._slot or i))
        r.icon:ClearAllPoints()
        r.bar:ClearAllPoints()
        r.icon:SetSize(h, h)
        r._noIcon = icon == "none"
        if icon == "right" then
            r.icon:SetPoint("RIGHT", r, "RIGHT", 0, 0)
            r.bar:SetPoint("TOPLEFT", r, "TOPLEFT", 0, 0)
            r.bar:SetPoint("BOTTOMRIGHT", r.icon, "BOTTOMLEFT", -3, 0)
        elseif icon == "none" then
            r.bar:SetAllPoints(r)
        else
            r.icon:SetPoint("LEFT", r, "LEFT", 0, 0)
            r.bar:SetPoint("TOPLEFT", r.icon, "TOPRIGHT", 3, 0)
            r.bar:SetPoint("BOTTOMRIGHT", r, "BOTTOMRIGHT", 0, 0)
        end
        K.SetFont(r.label, font)
        K.SetFont(r.time, font)
        r.label:ClearAllPoints()
        r.label:SetPoint("LEFT", r.bar, "LEFT", 5, 0)
        r.label:SetPoint("RIGHT", r.bar, "RIGHT", -(font * 3 + 10), 0)
        r.time:ClearAllPoints()
        r.time:SetPoint("RIGHT", r.bar, "RIGHT", -5, 0)
    end
end

--------------------------------------------------
-- Zeitleiste von oben nach unten (1.10.6.0, Wunsch des Besitzers): eine
-- senkrechte Spur, oben "spaeter", unten "jetzt"; jede Leiste mit Dauer
-- wandert als Symbol hinunter, sobald sie im Fenster (15/30/60 s) ist.
--------------------------------------------------

BM.TRACK_N = 12
BM.TRACK_TICKS = { 5, 10, 15, 20, 30, 45, 60 }
local track

local function BuildTrack()
    track = CreateFrame("Frame", "WeintCodexBossTrack", UIParent)
    track:SetFrameStrata("MEDIUM")
    track.line = track:CreateTexture(nil, "BACKGROUND")
    track.line:SetWidth(2)
    local lc = C.border
    track.line:SetColorTexture(lc[1], lc[2], lc[3], 0.9)
    track.now = track:CreateTexture(nil, "ARTWORK")
    track.now:SetHeight(2)
    local nc = C.textMuted
    track.now:SetColorTexture(nc[1], nc[2], nc[3], 0.9)
    track.ticks = {}
    for i, sec in ipairs(BM.TRACK_TICKS) do
        local tk = track:CreateTexture(nil, "BACKGROUND")
        tk:SetSize(8, 1)
        tk:SetColorTexture(lc[1], lc[2], lc[3], 0.9)
        local lbl = K.NewText(track, 9, "OVERLAY")
        lbl:SetTextColor(unpack(C.textFaint or C.textMuted))
        lbl:SetText(tostring(sec))
        track.ticks[i] = { tex = tk, label = lbl, sec = sec }
    end
    track.hint = K.NewText(track, 10, "OVERLAY")
    track.hint:SetPoint("BOTTOMLEFT", track, "BOTTOMRIGHT", 8, 4)
    track.hint:SetWidth(170)
    track.hint:SetJustifyH("LEFT")
    track.hint:SetTextColor(unpack(C.textMuted))
    track.hint:SetText("Noch nichts angekündigt. Was der Boss wirkt, merkt sich WeintCodex für den nächsten Versuch.")
    track.hint:Hide()
    track.marks = {}
    for i = 1, BM.TRACK_N do
        local m = CreateFrame("Frame", nil, track)
        m:SetSize(22, 22)
        m.icon = m:CreateTexture(nil, "ARTWORK")
        m.icon:SetAllPoints(m)
        m.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        m.label = K.NewText(m, 11, "OVERLAY")
        m.label:SetPoint("LEFT", m, "RIGHT", 6, 0)
        m.label:SetJustifyH("LEFT")
        m.label:SetWordWrap(false)
        m.label:SetWidth(170)
        m:Hide()
        track.marks[i] = m
    end
    track.WCShowForUnlock = function(self, on)
        self._unlock = on and true or nil
        BM.Refresh()
    end
    K.RegisterMover(track, "bosstrack", "Bosskämpfe: Zeitleiste", K.Layout("bosstrack"))
    track:Hide()
    BM.track = track
end

function BM.TrackWindow()
    local v = tonumber(K.Get(KEY, "bossTrackSecs"))
    return (v == 15 or v == 30 or v == 60) and v or 30
end

local function LayTrack()
    local h = Num("bossTrackH", 160, 500)
    local win = BM.TrackWindow()
    track:SetSize(26, h)
    track._h, track._win = h, win
    track.line:ClearAllPoints()
    track.line:SetPoint("TOP", track, "TOP", 0, 0)
    track.line:SetPoint("BOTTOM", track, "BOTTOM", 0, 0)
    track.now:ClearAllPoints()
    track.now:SetPoint("BOTTOMLEFT", track, "BOTTOMLEFT", -4, 0)
    track.now:SetPoint("BOTTOMRIGHT", track, "BOTTOMRIGHT", 4, 0)
    for _, tk in ipairs(track.ticks) do
        if tk.sec <= win then
            local y = tk.sec / win * h
            tk.tex:ClearAllPoints()
            tk.tex:SetPoint("CENTER", track, "BOTTOM", 0, y)
            tk.label:ClearAllPoints()
            tk.label:SetPoint("RIGHT", track, "BOTTOMLEFT", -2, y)
            tk.tex:Show() tk.label:Show()
        else
            tk.tex:Hide() tk.label:Hide()
        end
    end
end

-- Je Bild: Symbole an ihre Hoehe. Name und Symbol nur, wenn ein Zeichen
-- einen anderen Timer bekommt.
function BM.TrackFrame(now)
    if not track or not track:IsShown() then return end
    local h, win = track._h, track._win
    local n = 0
    for i = 1, #order do
        local t = order[i]
        if n >= BM.TRACK_N then break end
        if t.ends and not t.noTrack then
            local left = t.hold or (t.ends - now)
            if left >= 0 and left <= win then
                n = n + 1
                local m = track.marks[n]
                if m._timer ~= t then
                    m._timer = t
                    m.label:SetText(t.label)
                    if t.icon then
                        m.icon:SetTexture(t.icon)
                        m.icon:SetVertexColor(1, 1, 1, 1)
                    else
                        m.icon:SetColorTexture(1, 1, 1, 1)
                        local c = C[t.color or "accent"] or C.accent
                        m.icon:SetVertexColor(c[1], c[2], c[3], 1)
                    end
                    m:Show()
                end
                m:ClearAllPoints()
                m:SetPoint("CENTER", track, "BOTTOM", 0, left / win * h)
            end
        end
    end
    for i = n + 1, BM.TRACK_N do
        local m = track.marks[i]
        if m._timer then m._timer = nil m:Hide() end
    end
end

function BM.ApplyLook()
    if not frame then return end
    local w, h, font, max = BM.Look()
    LayRows(frame, max, w, h, font)
    LayRows(emph, BM.EMPH_ROWS, math.floor(w * 1.25 + 0.5), math.floor(h * BM.EMPH_SCALE + 0.5), math.floor(font * 1.3 + 0.5))
    local size = Num("bossWarnSize", 16, 40)
    K.SetFont(frame.warn.text, size)
    frame.warn:SetSize(700, size + 16)
    LayTrack()
    for _, m in ipairs(track.marks) do m._timer = nil end
    BM.Refresh()
end

local function ColorOf(name)
    local c = C[name or "accent"] or C.accent
    return c[1], c[2], c[3]
end

-- Der Takt (1.10.6.0: jedes Bild, nicht mehr zehnmal je Sekunde - das
-- ruckelte). Leisten und Zeitleiste bewegen sich jedes Bild, die Zahl
-- daneben wird alle 0,1 s neu geschrieben (Zeichenketten kosten). Werte
-- einmal je Takt gelesen, keine Tabelle und keine Funktion je Bild
-- (CLAUDE.md, "Anything that runs repeatedly").
local tNow, tText, tFill, tEmphOn, tEmphSecs, tSoonSecs, tDone, tRelayout
local function TickRow(r)
    local t = r._timer
    if not t or not r:IsShown() then return end
    if not t.ends then
        r.bar:SetValue(1)
        if tText then r.time:SetText(BM.Format(tNow - t.start)) end
        return
    end
    -- Angehalten (Zeitleiste des Spiels, Zustand "pausiert"): die Restzeit
    -- steht, die Leiste laeuft nicht ab.
    if t.hold then
        t.ends = tNow + t.hold
        local total = t.total or t.hold
        local frac = total > 0 and t.hold / total or 0
        r.bar:SetValue(tFill and (1 - frac) or frac)
        if tText then r.time:SetText(BM.Format(t.hold)) end
        return
    end
    local left = t.ends - tNow
    if left <= 0 then
        tDone = tDone or t
        r.bar:SetValue(tFill and 1 or 0)
        r.time:SetText("0")
        return
    end
    local total = t.ends - t.start
    local frac = total > 0 and left / total or 0
    r.bar:SetValue(tFill and (1 - frac) or frac)
    if tText then r.time:SetText(BM.Format(left)) end
    if t.soon and not t.warned and left <= tSoonSecs then
        t.warned = true
        if not t.demo or Opt("bossSound") then BM.Sound("Soon", t.demo, t.sound) end
    end
    if tEmphOn and not t.emph and left <= tEmphSecs then tRelayout = true end
end

-- doText: Zahlen neu schreiben (ohne Angabe: ja).
function BM.Tick(doText)
    if not frame then return end
    tNow = Now()
    tText = doText ~= false
    tFill = K.Get(KEY, "bossFill") == "fill"
    tEmphOn = Opt("bossEmph")
    tEmphSecs = Num("bossEmphSecs", 2, 10)
    tSoonSecs = tonumber(K.Get(KEY, "bossSoonSecs")) or 3
    tDone, tRelayout = nil, nil
    for i = 1, BM.MAX_ROWS do TickRow(frame.rows[i]) end
    for i = 1, BM.EMPH_ROWS do TickRow(emph.rows[i]) end
    BM.TrackFrame(tNow)
    if tText then BM.CheckWatches() end
    local done = tDone
    if done then
        timers[done.key] = nil
        if done.onEnd then done.onEnd() end
        BM.Refresh()
    elseif tRelayout then
        BM.Refresh()
    end
end

-- Gleiten und Einblenden: je Zeile ein Stueck naeher an ihren Platz.
BM.SLIDE, BM.FADE = 14, 6
local function AnimateRow(r, dt)
    if not r:IsShown() then return end
    local f = r._owner
    local ty = RowY(f, r._slot or 1)
    local cy = r._cy or ty
    if cy ~= ty then
        local ny = cy + (ty - cy) * math.min(1, dt * BM.SLIDE)
        if math.abs(ty - ny) < 0.5 then ny = ty end
        PlaceRow(r, ny)
    end
    local a = r._fade or 1
    if a < 1 then
        a = math.min(1, a + dt * BM.FADE)
        r._fade = a
        r:SetAlpha(a)
    end
end
function BM.Animate(dt)
    if not frame then return end
    for i = 1, BM.MAX_ROWS do AnimateRow(frame.rows[i], dt) end
    for i = 1, BM.EMPH_ROWS do AnimateRow(emph.rows[i], dt) end
end

local function Fill(r, t, slot, fresh)
    r._timer = t
    t._row = r
    r._slot = slot
    r.label:SetText(t.label)
    if t.icon and not r._noIcon then r.icon:SetTexture(t.icon) r.icon:Show() else r.icon:Hide() end
    r.bar:SetStatusBarColor(ColorOf(t.emph and "red" or t.color))
    if fresh then
        -- Neu: gleich an ihrem Platz, kurz eingeblendet.
        PlaceRow(r, RowY(r._owner, slot))
        r._fade = 0
        r:SetAlpha(0)
    end
    r:Show()
end
local function Clear(r)
    if r._timer and r._timer._row == r then r._timer._row = nil end
    r._timer = nil
    r._fade = 1
    r:SetAlpha(1)
    r:Hide()
end

local function Build()
    if frame then return frame end
    frame = CreateFrame("Frame", "WeintCodexBossBars", UIParent)
    frame:SetFrameStrata("MEDIUM")
    frame.rows = {}
    for i = 1, BM.MAX_ROWS do frame.rows[i] = NewRow(frame) frame.rows[i]._owner = frame end
    emph = CreateFrame("Frame", "WeintCodexBossEmph", UIParent)
    emph:SetFrameStrata("MEDIUM")
    emph.rows = {}
    for i = 1, BM.EMPH_ROWS do emph.rows[i] = NewRow(emph) emph.rows[i]._owner = emph end
    -- Grosse Warnung in der Mitte (eigener Platz, verschiebbar).
    local warn = CreateFrame("Frame", "WeintCodexBossWarning", UIParent)
    warn:SetSize(700, 40)
    warn.text = K.NewText(warn, 24, "OVERLAY")
    warn.text:SetAllPoints(warn)
    warn:Hide()
    frame.warn = warn
    BuildTrack()
    clock = CreateFrame("Frame", nil, UIParent)
    clock._acc = 0
    clock:SetScript("OnUpdate", function(self, el)
        el = el or 0
        self._acc = self._acc + el
        local text = self._acc >= 0.1
        if text then self._acc = 0 end
        BM.Animate(el)
        BM.Tick(text)
    end)
    clock:Hide()
    frame.WCShowForUnlock = function(self, on)
        self._unlock = on and true or nil
        BM.DemoBars(on or setupOn)
    end
    emph.WCShowForUnlock = function(self, on)
        self._unlock = on and true or nil
        BM.Refresh()
    end
    warn.WCShowForUnlock = function(self, on)
        self._unlock = on and true or nil
        if on or setupOn then self.text:SetText("Warnung des Spiels") self:Show() else self:Hide() end
    end
    K.RegisterMover(frame, "bossbars", "Bosskämpfe: Leisten", K.Layout("bossbars"))
    K.RegisterMover(emph, "bossemph", "Bosskämpfe: gleich dran", K.Layout("bossemph"))
    K.RegisterMover(warn, "bosswarn", "Bosskämpfe: Warnung", K.Layout("bosswarn"))
    frame:Hide()
    emph:Hide()
    BM.frame, BM.emph, BM.clock = frame, emph, clock
    BM.ApplyLook()
    return frame
end
BM.Build = Build

-- Hauptanker bis "Anzahl", was gleich dran ist an den zweiten - BigWigs
-- nennt das "hervorheben". Ohne Dauer (Kampftimer) nie hervorgehoben.
-- Eine Leiste behaelt ihre Zeile, solange sie am selben Anker bleibt; nur
-- ihr Platz aendert sich - und dorthin gleitet sie.
local mainSel, emphSel = {}, {}
local function Assign(f, sel, n, rowCount)
    for i = 1, rowCount do f.rows[i]._keep = nil end
    -- Erst die, die schon eine Zeile hier haben ...
    for i = 1, n do
        local t = sel[i]
        local r = t._row
        if r and r._owner == f and r._timer == t then
            r._keep = true
            Fill(r, t, i, false)
        else
            t._row = nil
        end
    end
    -- ... dann die neuen in freie Zeilen.
    for i = 1, n do
        local t = sel[i]
        if not t._row then
            for j = 1, rowCount do
                local r = f.rows[j]
                if not r._keep then
                    if r._timer and r._timer._row == r then r._timer._row = nil end
                    r._keep = true
                    Fill(r, t, i, true)
                    break
                end
            end
        end
    end
    for i = 1, rowCount do
        local r = f.rows[i]
        if not r._keep then Clear(r) end
    end
end

function BM.Refresh()
    local f = Build()
    local list = BM.Sorted()
    local now = Now()
    local useEmph = Opt("bossEmph")
    local secs = Num("bossEmphSecs", 2, 10)
    local _, _, _, max = BM.Look()
    local mi, ei = 0, 0
    for i = #mainSel, 1, -1 do mainSel[i] = nil end
    for i = #emphSel, 1, -1 do emphSel[i] = nil end
    for i = 1, #list do
        local t = list[i]
        local e = useEmph and ei < BM.EMPH_ROWS and (t.forceEmph or (t.ends and not t.hold and t.ends - now <= secs))
        if (e and true or nil) ~= t.emph then
            -- Wechsel des Ankers: neue Zeile am anderen.
            t.emph = e and true or nil
            if t._row then t._row = nil end
        end
        if e then
            ei = ei + 1
            emphSel[ei] = t
        elseif mi < max then
            mi = mi + 1
            mainSel[mi] = t
        end
    end
    Assign(f, mainSel, mi, BM.MAX_ROWS)
    Assign(emph, emphSel, ei, BM.EMPH_ROWS)
    if mi > 0 or setupOn or f._unlock then f:Show() else f:Hide() end
    if ei > 0 or setupOn or emph._unlock then emph:Show() else emph:Hide() end
    local trackOn = Opt("bossTrack")
    if trackOn or track._unlock then
        local any = false
        for i = 1, #list do if list[i].ends then any = true break end end
        -- 1.10.8.0: im Bosskampf bleibt sie stehen (vorher blitzte sie nur
        -- bei einem Zauber kurz auf).
        if any or setupOn or track._unlock or BM.fight then track:Show() else track:Hide() end
        if track.hint then
            if BM.fight and not any then track.hint:Show() else track.hint:Hide() end
        end
    else
        track:Hide()
    end
    if setupOn then
        -- Ziehen nur, wo etwas zu sehen ist (Zeitleiste aus: keine Flaeche).
        for _, h in pairs(handles) do
            if h._target and h._target:IsShown() then h:Show() else h:Hide() end
        end
    end
    if #list > 0 then clock:Show() BM.Tick() else clock:Hide() end
end

function BM.Warn(text, icon)
    local f = Build()
    local w = f.warn
    if icon then
        w.text:SetFormattedText("|T%s:24:24:0:0|t  %s", tostring(icon), text)
    else
        w.text:SetText(text)
    end
    w:Show()
    w.until_ = Now() + Num("bossWarnTime", 2, 8)
    if not w.hider then
        w.hider = true
        w:SetScript("OnUpdate", function(self)
            if not self._unlock and not setupOn and Now() > (self.until_ or 0) then self:Hide() end
        end)
    end
end

--------------------------------------------------
-- Testleisten und Einrichten (wie BigWigs/DBM: Anker zum Ziehen,
-- Testleisten, Einstellungen direkt daneben)
--------------------------------------------------

BM.DEMO = {
    { "demo1", "Pull", 10, nil, "accent" },
    { "demo2", "Fähigkeit des Bosses", 24, 136116, "blue" },
    { "demo3", "Noch eine Fähigkeit", 15, 136116, "blue" },
    { "demo4", "Pause", 45, nil, "blue" },
}
local demoActive = false
local function DemoLoop(d)
    if not demoActive then return end
    local t = BM.Start(d[1], d[2], d[3], d[4], d[5])
    t.onEnd = function() DemoLoop(d) end
end
-- Testleisten laufen immer wieder ab - so sieht man auch, wie eine Leiste
-- in den letzten Sekunden an den zweiten Anker springt.
function BM.DemoBars(on)
    on = on and true or false
    if on == demoActive then BM.Refresh() return end
    demoActive = on
    for i, d in ipairs(BM.DEMO) do
        if on then
            DemoLoop(d)
            -- versetzt, damit nicht alle zugleich ablaufen
            local t = timers[d[1]]
            if t and t.ends then t.ends = t.ends - (i - 1) * 3 end
        else
            timers[d[1]] = nil
        end
    end
    BM.Refresh()
end

local function Handle(target, key, label)
    local h = handles[key]
    if not h then
        h = CreateFrame("Button", nil, UIParent)
        h:SetFrameStrata("DIALOG")
        local bg = h:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(h)
        local hc = K.Highlight()
        bg:SetColorTexture(hc[1], hc[2], hc[3], 0.25)
        K.Border(h, 1, hc[1], hc[2], hc[3], 0.9, "ARTWORK")
        local t = K.NewText(h, 11, "OVERLAY")
        t:SetPoint("BOTTOM", h, "TOP", 0, 3)
        t:SetText(label)
        h.text = t
        if h.RegisterForClicks then h:RegisterForClicks("RightButtonUp") end
        K.DragToMove(h, key)
        h:SetScript("OnClick", function(_, button)
            if button == "RightButton" and _G.IsShiftKeyDown and _G.IsShiftKeyDown() then BM.ResetPosition(key) end
        end)
        h:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(label, 1, 1, 1)
            GameTooltip:AddLine("Ziehen verschiebt. Umschalt+Rechtsklick: zurück an den Standardplatz.", 0.7, 0.7, 0.75, true)
            GameTooltip:Show()
        end)
        h:SetScript("OnLeave", function() GameTooltip:Hide() end)
        handles[key] = h
    end
    h._target = target
    h:ClearAllPoints()
    h:SetAllPoints(target)
    return h
end
BM.handles = handles

function BM.ResetPosition(key)
    local ui = K.Profile()
    if ui and ui.positions then ui.positions[key] = nil end
    K.ApplyPosition(key)
end

local panel
local function BuildPanel()
    if panel then return panel end
    local W, COL = 560, 250
    panel = CreateFrame("Frame", "WeintCodexBossSetup", UIParent)
    panel:SetFrameStrata("DIALOG")
    panel:SetSize(W, 500)
    panel:SetPoint("CENTER", UIParent, "CENTER", 0, -170)
    panel:SetClampedToScreen(true)
    panel:EnableMouse(true)
    panel:SetMovable(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", function(self) self:StartMoving() end)
    panel:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    local bg = panel:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(panel)
    bg:SetColorTexture(C.bgDark[1], C.bgDark[2], C.bgDark[3], 0.96)
    K.Border(panel, 1, C.border[1], C.border[2], C.border[3], 1, "BORDER")
    local title = K.NewText(panel, 15, "OVERLAY")
    title:SetPoint("TOPLEFT", panel, "TOPLEFT", 20, -16)
    title:SetText("Bossleisten einstellen")
    local note = K.NewText(panel, 11, "OVERLAY")
    note:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    note:SetPoint("RIGHT", panel, "RIGHT", -20, 0)
    note:SetJustifyH("LEFT")
    note:SetTextColor(unpack(C.textMuted))
    note:SetText("Zieh die farbigen Flächen an ihren Platz. Die Testleisten laufen, bis du auf „Fertig“ klickst; in den letzten Sekunden springen sie an „gleich dran“.")
    panel.widgets = {}
    local function apply(k) return function(v) K.Set(KEY, k, v) BM.ApplyLook() end end
    local function get(k) return function() return K.Get(KEY, k) end end
    local function place(w, col, y)
        w:SetWidth(COL)
        w:SetPoint("TOPLEFT", panel, "TOPLEFT", 20 + (col - 1) * (COL + 20), y)
        if w.Sync then w.Sync() end
        panel.widgets[#panel.widgets + 1] = w
    end
    local function slider(k, label, lo, hi, step, fmt)
        return WeintCodex.CreateSlider(panel, { label = label, min = lo, max = hi, step = step,
            get = get(k), set = apply(k), format = fmt })
    end
    local function dropdown(k, label, items)
        return WeintCodex.CreateDropdown(panel, { label = label, items = items, width = COL, get = get(k), set = apply(k) })
    end
    local px = function(v) return v .. " px" end
    local y0 = -78
    place(slider("bossBarW", "Breite", 160, 420, 10, px), 1, y0)
    place(slider("bossBarH", "Höhe", 14, 32, 1, px), 1, y0 - 56)
    place(slider("bossFont", "Schrift", 9, 16, 1, px), 1, y0 - 112)
    place(slider("bossMax", "Höchstens so viele Leisten", 3, BM.MAX_ROWS, 1), 1, y0 - 168)
    place(slider("bossWarnSize", "Schrift der großen Warnung", 16, 40, 2, px), 1, y0 - 224)
    place(dropdown("bossGrow", "Neue Leisten", {
        { value = "down", text = "Nach unten anhängen" },
        { value = "up",   text = "Nach oben anhängen" } }), 2, y0)
    place(dropdown("bossIcon", "Symbol", {
        { value = "left",  text = "Links" },
        { value = "right", text = "Rechts" },
        { value = "none",  text = "Ohne" } }), 2, y0 - 56)
    place(dropdown("bossFill", "Leiste", {
        { value = "drain", text = "Leert sich" },
        { value = "fill",  text = "Füllt sich" } }), 2, y0 - 112)
    place(WeintCodex.CreateToggle(panel, { label = "Was gleich dran ist, groß extra", width = COL,
        get = get("bossEmph"), set = apply("bossEmph") }), 2, y0 - 172)
    place(slider("bossEmphSecs", "Ab so vielen Sekunden Rest", 2, 10, 1, function(v) return v .. " s" end), 2, y0 - 214)
    place(slider("bossTrackH", "Höhe der Zeitleiste", 160, 500, 10, px), 1, y0 - 280)
    place(WeintCodex.CreateToggle(panel, { label = "Zeitleiste von oben nach unten", width = COL,
        get = get("bossTrack"), set = apply("bossTrack") }), 2, y0 - 270)
    place(dropdown("bossTrackSecs", "Zeitleiste zeigt", {
        { value = 15, text = "die nächsten 15 Sekunden" },
        { value = 30, text = "die nächsten 30 Sekunden" },
        { value = 60, text = "die nächste Minute" } }), 2, y0 - 310)
    local reset = WeintCodex.CreateButton(panel, { text = "Alles zurücksetzen", kind = "secondary", height = 30, size = 11,
        tooltip = "Plätze und Aussehen der Leisten wie ab Werk.",
        onClick = function()
            for k in pairs(BM.LOOK_KEYS) do K.Set(KEY, k, BM.DEFAULTS[k]) end
            BM.ResetPosition("bossbars") BM.ResetPosition("bossemph") BM.ResetPosition("bosswarn")
            for _, w in ipairs(panel.widgets) do if w.Sync then w.Sync() end end
            BM.ApplyLook()
        end })
    reset:SetSize(170, 30)
    reset:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 20, 16)
    local done = WeintCodex.CreateButton(panel, { text = "Fertig", kind = "primary", height = 30, size = 12,
        onClick = function() BM.Setup(false) end })
    done:SetSize(140, 30)
    done:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -20, 16)
    panel:Hide()
    BM.panel = panel
    return panel
end

BM.LOOK_KEYS = { bossBarW = true, bossBarH = true, bossFont = true, bossMax = true, bossGrow = true,
    bossIcon = true, bossFill = true, bossEmph = true, bossEmphSecs = true, bossWarnSize = true,
    bossTrack = true, bossTrackSecs = true, bossTrackH = true }

local hiddenOptions
-- Einrichten: Testleisten, ziehbare Flaechen an allen drei Plaetzen und
-- das Fenster mit dem Aussehen. Nie im Kampf.
function BM.Setup(on)
    on = on and true or false
    if on and K.InCombat() then Say("Im Kampf lassen sich die Leisten nicht einrichten.") return false end
    if on == setupOn then return true end
    local f = Build()
    setupOn = on
    local O = WeintCodex.UIOptions
    if on and O and O.frame and O.frame:IsShown() then
        hiddenOptions = true
        O.frame:Hide()
    end
    BM.DemoBars(on or (f._unlock and true or false))
    Handle(f, "bossbars", "Leisten – ziehen")
    Handle(emph, "bossemph", "Gleich dran – ziehen")
    Handle(f.warn, "bosswarn", "Große Warnung – ziehen")
    Handle(track, "bosstrack", "Zeitleiste – ziehen")
    for _, h in pairs(handles) do if on then h:Show() else h:Hide() end end
    if on then
        f.warn.text:SetText("Warnung des Spiels")
        f.warn:Show()
        BuildPanel():Show()
        for _, w in ipairs(panel.widgets) do if w.Sync then w.Sync() end end
    else
        if not f.warn._unlock then f.warn:Hide() end
        if panel then panel:Hide() end
        if hiddenOptions and O and O.frame then O.frame:Show() end
        hiddenOptions = nil
    end
    BM.Refresh()
    return true
end
function BM.IsSetup() return setupOn end

--------------------------------------------------
-- Pull und Pause
--------------------------------------------------

function BM.PullBar(secs, by)
    if not Opt("bossPull") then return end
    if not secs or secs <= 0 then BM.Stop("pull") return end
    local t = BM.Start("pull", by and ("Pull (" .. by .. ")") or "Pull", secs, nil, "accent")
    t.onEnd = function() BM.Sound("Pull") end
end

function BM.BreakBar(secs, by)
    if not Opt("bossPull") then return end
    if not secs or secs <= 0 then BM.Stop("break") return end
    local t = BM.Start("break", by and ("Pause (" .. by .. ")") or "Pause", secs, nil, "blue")
    t.onEnd = function() Say("Die Pause ist vorbei.") BM.Sound("Break") end
end

-- /pull: ueber den Countdown des Spiels; ohne ihn nur die eigene Leiste.
function BM.Pull(secs)
    secs = tonumber(secs) or 10
    if secs < 0 or secs > 60 then Say("Pull: 1 bis 60 Sekunden, 0 bricht ab.") return false end
    local P = _G.C_PartyInfo
    local inGroup = _G.IsInGroup and K.Bool(_G.IsInGroup(), false)
    if inGroup and P and P.DoCountdown then
        -- 0 bricht den Countdown des Spiels ab.
        local ok = pcall(P.DoCountdown, secs)
        if ok then return true end
    end
    BM.PullBar(secs)
    if inGroup then Say("Der Countdown des Spiels ging nicht – die Leiste siehst nur du.") end
    return true
end

function BM.Break(mins)
    mins = tonumber(mins) or 5
    if mins < 0 or mins > 60 then Say("Pause: 1 bis 60 Minuten, 0 bricht ab.") return false end
    BM.BreakBar(mins * 60)
    return true
end

-- Nachrichten anderer Bossmods, nur gelesen.
function BM.Heard(prefix, msg, sender)
    if not Opt("bossListen") or type(msg) ~= "string" then return nil end
    local who = type(sender) == "string" and sender:match("^[^-]+") or nil
    if prefix == "BigWigs" then
        local kind, n = msg:match("^P%^(%a+)%^(%d+)")
        n = tonumber(n)
        if kind == "Pull" and n then BM.stats.heard = BM.stats.heard + 1 BM.PullBar(n, who) return "pull" end
        if kind == "Break" and n then BM.stats.heard = BM.stats.heard + 1 BM.BreakBar(n, who) return "break" end
    elseif prefix == "D5" then
        local n = tonumber(msg:match("%f[%w]PT\t(%d+)"))
        if n then BM.stats.heard = BM.stats.heard + 1 BM.PullBar(n, who) return "pull" end
        n = tonumber(msg:match("%f[%w]BT\t(%d+)"))
        if n then BM.stats.heard = BM.stats.heard + 1 BM.BreakBar(n, who) return "break" end
    end
    return nil
end

--------------------------------------------------
-- Kampf
--------------------------------------------------

function BM.Times()
    local sd = WeintCodex.SavedData
    if type(sd) ~= "table" then return nil end
    sd.bossTimes = sd.bossTimes or {}
    return sd.bossTimes
end

BM.fight = nil
function BM.InstanceName()
    if not _G.GetInstanceInfo then return nil end
    local n = Plain((_G.GetInstanceInfo()))
    return type(n) == "string" and n ~= "" and n or nil
end
function BM.EncounterStart(id, name, difficulty)
    BM.stats.encounters = BM.stats.encounters + 1
    id, name, difficulty = Plain(id), Plain(name), Plain(difficulty)
    local old = BM.fight
    -- Schon ueber die Bossrahmen erkannt: dieselbe Startzeit behalten.
    local start = (old and (old.src == "engage" or old.src == "codex") and Now() - old.start < 15) and old.start or Now()
    BM.fight = { id = id, name = type(name) == "string" and name or (old and old.name), diff = difficulty, start = start, src = "encounter",
        instance = BM.InstanceName() }
    BM.fight.codex = (old and old.codex) or BM.CodexBoss("boss1") or (BM.fight.name and BM.BossIndex()[BM.fight.name:lower()]) or nil
    if Opt("bossFight") then BM.Start("fight", BM.fight.name or "Bosskampf", nil, nil, "textMuted").start = start end
    BM.Stop("pull")
    BM.CatchUp()
    if not (old and (old.src == "engage" or old.src == "codex")) then BM.LearnStart() end
end

-- Ende eines Kampfes: result = "kill" | "wipe" | nil (unbekannt - weder
-- Sieg noch Wipe, und keine Bestzeit).
function BM.Finish(result)
    if BM.LearnEnd then BM.LearnEnd() end
    local f = BM.fight
    BM.fight = nil
    BM.Stop("fight")
    for k in pairs(timers) do
        if type(k) == "string" and (k:find("^tl") or k:find("^cast") or k:find("^nx")) then timers[k] = nil end
    end
    BM.Refresh()
    if not f then return nil end
    local secs = Now() - f.start
    if not Opt("bossFight") then return result end
    local label = f.name or "Boss"
    if result == "wipe" then
        BM.Sound("Wipe")
        Say(label .. ": Wipe nach " .. BM.Format(secs) .. ".")
        return "wipe"
    elseif result ~= "kill" then
        Say(label .. ": Kampf vorbei nach " .. BM.Format(secs) .. ".")
        return nil
    end
    local text = label .. " besiegt in " .. BM.Format(secs)
    local times = BM.Times()
    local key = (type(f.id) == "number" and (f.id .. ":" .. tostring(f.diff or 0)))
        or (type(f.name) == "string" and ("n:" .. f.name)) or nil
    if times and key then
        local best = times[key]
        if type(best) == "number" then
            text = text .. (secs < best and (" – neue Bestzeit (vorher " .. BM.Format(best) .. ")") or (" (Bestzeit " .. BM.Format(best) .. ")"))
        end
        if type(best) ~= "number" or secs < best then times[key] = math.floor(secs + 0.5) end
    end
    BM.Sound("Kill")
    Say(text .. ".")
    return "kill"
end

function BM.EncounterEnd(id, name, difficulty, size, success)
    local f = BM.fight
    if f and not f.name then
        local n = Plain(name)
        if type(n) == "string" then f.name = n end
    end
    local won = Plain(success)
    won = won == 1 or won == true
    return BM.Finish(won and "kill" or "wipe")
end

-- Ohne ENCOUNTER_START (alte Dungeons, Classic-Clients): ein Boss in den
-- Bossrahmen des Spiels, der kaempft, ist ein Bosskampf. So macht es DBM
-- auch (INSTANCE_ENCOUNTER_ENGAGE_UNIT).
function BM.BossUnit(i)
    local u = "boss" .. i
    if _G.UnitExists and K.Bool(_G.UnitExists(u), false) then return u end
    return nil
end
function BM.Engage()
    if BM.fight then return nil end
    for i = 1, 5 do
        local u = BM.BossUnit(i)
        if u and _G.UnitAffectingCombat and K.Bool(_G.UnitAffectingCombat(u), false) then
            local n = _G.UnitName and Plain(_G.UnitName(u))
            BM.stats.engaged = BM.stats.engaged + 1
            BM.fight = { name = type(n) == "string" and n or nil, start = Now(), src = "engage", instance = BM.InstanceName(),
                codex = BM.CodexBoss(u) }
            if Opt("bossFight") then BM.Start("fight", BM.fight.name or "Bosskampf", nil, nil, "textMuted") end
            BM.Stop("pull")
            BM.LearnStart()
            return true
        end
    end
    return nil
end
--------------------------------------------------
-- War das ein Boss? Abgleich mit dem Dungeonkompendium (1.10.10.0,
-- Beta-Test: "Omokk getoetet, steht nicht unter Bosse"). Alte Dungeons
-- melden oft weder ENCOUNTER_START noch Bossrahmen. Ein Gegner gilt als
-- Boss, wenn seine NPC-Nummer (aus dem GUID, haengt an keiner Sprache) in
-- data/boss_npcs.lua steht - oder, ohne Nummer, sein Name der deutsche oder
-- englische Name eines Bosses des Kompendiums ist.
--------------------------------------------------

BM.CODEX_UNITS = { "target", "focus", "mouseover", "boss1", "boss2", "boss3", "boss4", "boss5" }
for i = 1, 40 do BM.CODEX_UNITS[#BM.CODEX_UNITS + 1] = "nameplate" .. i end
local byName
local function Lower(s) return type(s) == "string" and s:lower() or nil end
function BM.BossIndex()
    if byName then return byName end
    byName = {}
    for npc, e in pairs(WeintCodex.BossNpcs or {}) do
        local entry = { dungeon = e[1], boss = e[2], de = e[3], en = e[4], npc = npc }
        if e[3] then byName[Lower(e[3])] = entry end
        if e[4] then byName[Lower(e[4])] = byName[Lower(e[4])] or entry end
    end
    -- Bosse ohne Nummer: nur ueber den englischen Namen des Kompendiums.
    for _, list in ipairs({ _G.WeintCodex_Dungeons or {}, _G.WeintCodex_ClassicDungeons or {} }) do
        for _, d in ipairs(list) do
            for _, b in ipairs(type(d.bosses) == "table" and d.bosses or {}) do
                local k = Lower(b.name)
                if k and not byName[k] then byName[k] = { dungeon = d.id, boss = b.id, en = b.name } end
            end
        end
    end
    return byName
end

function BM.NpcOf(unit)
    local g = _G.UnitGUID and Plain(_G.UnitGUID(unit))
    if type(g) ~= "string" then return nil, nil end
    local kind, npc = g:match("^(%a+)%-%d+%-%d+%-%d+%-%d+%-(%d+)")
    if kind ~= "Creature" and kind ~= "Vehicle" then return nil, g end
    return tonumber(npc), g
end

-- Eintrag des Kompendiums fuer eine Einheit, oder nil.
function BM.CodexBoss(unit)
    if type(unit) ~= "string" or not (_G.UnitExists and K.Bool(_G.UnitExists(unit), false)) then return nil end
    local npc, guid = BM.NpcOf(unit)
    local e = npc and WeintCodex.BossNpcs and WeintCodex.BossNpcs[npc]
    if e then return { dungeon = e[1], boss = e[2], de = e[3], en = e[4], npc = npc }, guid end
    local n = _G.UnitName and Lower(Plain(_G.UnitName(unit)))
    local hit = n and BM.BossIndex()[n]
    return hit, guid
end

-- Kampf beginnen, wenn diese Einheit ein kaempfender Boss des Kompendiums ist.
function BM.CodexEngage(unit)
    if BM.fight then return nil end
    if not (_G.UnitAffectingCombat and K.Bool(_G.UnitAffectingCombat(unit), false)) then return nil end
    if not (_G.UnitCanAttack and K.Bool(_G.UnitCanAttack("player", unit), false)) then return nil end
    local e, guid = BM.CodexBoss(unit)
    if not e then return nil end
    local n = _G.UnitName and Plain(_G.UnitName(unit))
    BM.stats.codex = (BM.stats.codex or 0) + 1
    BM.fight = { name = type(n) == "string" and n or e.de or e.en, start = Now(), src = "codex",
        codex = e, guid = guid, instance = BM.InstanceName() }
    if Opt("bossFight") then BM.Start("fight", BM.fight.name, nil, nil, "textMuted") end
    BM.Stop("pull")
    BM.LearnStart()
    return true
end

-- Bei Kampfbeginn: Ziel, Fokus und Plaketten durchsehen.
function BM.CodexScan()
    if BM.fight then return nil end
    if BM.CodexEngage("target") or BM.CodexEngage("focus") then return true end
    for i = 1, 40 do
        local u = "nameplate" .. i
        if _G.UnitExists and K.Bool(_G.UnitExists(u), false) and BM.CodexEngage(u) then return true end
    end
    return nil
end

-- Tod des Bosses: an seinem GUID erkannt (Ziel, Plakette, Bossrahmen).
function BM.CodexHealth(unit)
    local f = BM.fight
    if not f or not f.guid or f.killed or type(unit) ~= "string" then return nil end
    local g = _G.UnitGUID and Plain(_G.UnitGUID(unit))
    if g ~= f.guid then return nil end
    if _G.UnitIsDead and K.Bool(_G.UnitIsDead(unit), false) then f.killed = true return true end
    return nil
end

-- Ende ohne ENCOUNTER_END: beim Verlassen des Kampfes. Sieg nur, wenn das
-- Spiel es sagt (BOSS_KILL) oder ein Boss tot ist; lebt einer, Wipe; sonst
-- unbekannt.
function BM.EngageEnd()
    local f = BM.fight
    if not f or (f.src ~= "engage" and f.src ~= "codex") then return nil end
    if f.killed then return BM.Finish("kill") end
    if f.src == "codex" then
        -- Der Boss selbst, wo er noch zu sehen ist: tot = Sieg, lebt = Wipe.
        for _, u in ipairs(f.guid and BM.CODEX_UNITS or {}) do
            if _G.UnitGUID and Plain(_G.UnitGUID(u)) == f.guid then
                if _G.UnitIsDead and K.Bool(_G.UnitIsDead(u), false) then return BM.Finish("kill") end
                return BM.Finish("wipe")
            end
        end
        return BM.Finish(nil)
    end
    local alive, dead = false, false
    for i = 1, 5 do
        local u = BM.BossUnit(i)
        if u then
            if _G.UnitIsDead and K.Bool(_G.UnitIsDead(u), false) then dead = true else alive = true end
        end
    end
    if dead and not alive then return BM.Finish("kill") end
    if alive then return BM.Finish("wipe") end
    return BM.Finish(nil)
end
function BM.BossKill()
    if BM.fight then BM.fight.killed = true end
end

--------------------------------------------------
-- Zeitleiste und Warnungen des Spiels
--------------------------------------------------

-- Die Zeitleiste meldet je Faehigkeit eine Tabelle; gelesen wird nur, was
-- offen ist. Name und Symbol gehen roh an Text und Bild (das darf geheim).
-- 1.10.6.0 nach dem Verhalten von DBM: zweiter Wert ist die Restzeit, die
-- gilt vor der Dauer; ein pausiertes Ereignis steht still. Zustaende (laut
-- Client): 0 laeuft, 1 pausiert, 2 fertig, 3 abgebrochen.
function BM.TimelineAdded(info, remaining)
    if type(info) ~= "table" then return nil end
    BM.stats.timeline = BM.stats.timeline + 1
    if not Opt("bossTimeline") then return nil end
    local id = Plain(info.id)
    local dur = Plain(remaining)
    if type(dur) ~= "number" or dur <= 0 then dur = Plain(info.duration) end
    if type(id) ~= "number" or type(dur) ~= "number" or dur <= 0 then
        BM.stats.secret = BM.stats.secret + 1
        return nil
    end
    local name = info.spellName
    if type(name) == "nil" then name = "Fähigkeit" end
    local t = BM.Start("tl" .. id, name, dur, info.iconFileID, "blue")
    t.soon = true
    if BM.EventState(id) == 1 then t.hold, t.total = dur, dur end
    return true
end

function BM.EventState(id)
    local ET = _G.C_EncounterTimeline
    if not (ET and ET.GetEventState) then return nil end
    local ok, st = pcall(ET.GetEventState, id)
    st = ok and Plain(st) or nil
    return type(st) == "number" and st or nil
end

function BM.TimelineState(id)
    id = Plain(id)
    if type(id) ~= "number" then return nil end
    local t = timers["tl" .. id]
    local st = BM.EventState(id)
    if not t or not st then return nil end
    if st == 2 or st == 3 then BM.Stop("tl" .. id) return "stop" end
    if st == 1 and not t.hold then
        local left = (t.ends or Now()) - Now()
        t.hold, t.total = math.max(0, left), (t.ends or Now()) - t.start
        BM.Refresh()
        return "pause"
    end
    if st == 0 and t.hold then
        local ET = _G.C_EncounterTimeline
        local ok, rem = false, nil
        if ET and ET.GetEventTimeRemaining then ok, rem = pcall(ET.GetEventTimeRemaining, id) end
        rem = ok and Plain(rem) or nil
        local left = type(rem) == "number" and rem or t.hold
        local total = t.total or left
        t.hold, t.total = nil, nil
        t.ends = Now() + left
        t.start = t.ends - total
        BM.Refresh()
        return "resume"
    end
    return nil
end

-- Nach /reload mitten im Kampf: was die Zeitleiste schon hat, nachholen.
function BM.CatchUp()
    local ET = _G.C_EncounterTimeline
    if not (ET and ET.HasActiveEvents and ET.GetEventList and ET.GetEventInfo) then return 0 end
    local ok, has = pcall(ET.HasActiveEvents)
    if not ok or not K.Bool(has, false) then return 0 end
    local okL, list = pcall(ET.GetEventList)
    if not okL or type(list) ~= "table" then return 0 end
    local n = 0
    for _, id in ipairs(list) do
        local okI, info = pcall(ET.GetEventInfo, id)
        local rem
        if ET.GetEventTimeRemaining then
            local okR, r = pcall(ET.GetEventTimeRemaining, id)
            rem = okR and r or nil
        end
        if okI and BM.TimelineAdded(info, rem) then n = n + 1 end
    end
    return n
end

function BM.TimelineRemoved(id)
    id = Plain(id)
    if type(id) == "number" then BM.Stop("tl" .. id) end
end

--------------------------------------------------
-- Zauber der Bosse (1.10.6.0) - was der Client selbst sagt: Name und
-- Dauer des Zaubers. Gibt es auch, wo keine Zeitleiste kommt (Classic,
-- alte Dungeons). Bossrahmen boss1-5; ohne Bossrahmen das Ziel, wenn es
-- ein feindlicher Elitegegner in einer Instanz ist. Gold = unterbrechbar.
--------------------------------------------------

function BM.CastUnit(unit)
    if type(unit) ~= "string" then return false end
    if unit:match("^boss[1-5]$") then return true end
    if unit ~= "target" then return false end
    if not _G.UnitExists or not K.Bool(_G.UnitExists("target"), false) then return false end
    for i = 1, 5 do
        local u = BM.BossUnit(i)
        if u and _G.UnitIsUnit and K.Bool(_G.UnitIsUnit("target", u), false) then return false end
    end
    if not (_G.UnitCanAttack and K.Bool(_G.UnitCanAttack("player", "target"), false)) then return false end
    if not _G.IsInInstance then return false end
    local _, kind = _G.IsInInstance()
    kind = Plain(kind)
    if kind ~= "party" and kind ~= "raid" then return false end
    local c = _G.UnitClassification and Plain(_G.UnitClassification("target"))
    return c == "worldboss" or c == "elite" or c == "rareelite"
end

function BM.CastStart(unit, channel)
    if not Opt("bossCasts") or not BM.CastUnit(unit) then return nil end
    local fn = channel and _G.UnitChannelInfo or _G.UnitCastingInfo
    if not fn then return nil end
    local name, _, icon, startMS, endMS, a6, a7, a8 = fn(unit)
    BM.stats.casts = BM.stats.casts + 1
    startMS, endMS = Plain(startMS), Plain(endMS)
    if type(name) == "nil" or type(startMS) ~= "number" or type(endMS) ~= "number" or endMS <= startMS then
        BM.stats.castSecret = BM.stats.castSecret + 1
        return nil
    end
    -- Kanalisiert: 7. Wert, sonst der 8.: "nicht unterbrechbar".
    local locked = Plain(channel and a7 or a8)
    local left = endMS / 1000 - Now()
    if left <= 0 then return nil end
    -- 1.10.8.0: der Zauber, nicht der Boss - ein langer Bossname frass
    -- sonst den ganzen Platz ("Kriegshaeuptling Rend Schwarzf...").
    local t = BM.Start("cast" .. unit, name, left, Plain(icon), locked == true and "blue" or "gold")
    t.start = startMS / 1000
    BM.Sound("Cast")
    castStarted[unit], castStartedAt[unit] = Plain(name), Now()
    BM.LearnCast(unit, Plain(name), Plain(icon))
    return true
end

--------------------------------------------------
-- Zeiten aus eigenen Kaempfen (1.10.8.0). BigWigs und DBM bringen je Boss
-- hinterlegte Zeiten mit, von Hand aus Kampfaufzeichnungen - fuer Forever
-- gibt es keine, und ihre sind "All Rights Reserved". WeintCodex misst
-- selbst: je Boss und Zauber der frueheste erste Einsatz nach dem Pull und
-- der kuerzeste Abstand, den der Spieler gesehen hat (SavedData.bossLearn).
-- Daraus Leisten mit "~" - eine eigene Messung, keine Angabe des Spiels.
-- Nur Zauber des Bosses (Bossrahmen oder derselbe Name wie der Kampf),
-- nur offene Namen; Abstaende unter 2 s zaehlen nicht (Doppelmeldungen).
--------------------------------------------------

BM.LEARN_MIN, BM.LEARN_MAX = 2, 30   -- Mindestabstand (s), Faehigkeiten je Boss
BM.SAMPLES = 6                       -- so viele Lebens-/Energiewerte je Faehigkeit
BM.HP_PRE, BM.POWER_PRE = 5, 90      -- "gleich": 5 % vor der Schwelle, ab 90 % Energie
local seen, seenCount = {}, {}       -- Zauber -> letzte Zeit / Anzahl, nur im Kampf
BM.watch = {}                        -- Schwellen dieses Kampfes (Leben, Energie)

-- Leben und Energie des Bosses in Prozent - nur, wenn der Client sie offen
-- herausgibt (12.x verdeckt sie im Kampf womoeglich: dann nil, nie geraten).
function BM.BossVitals()
    local f = BM.fight
    local unit = BM.BossUnit(1)
    if not unit and f and f.name and _G.UnitName and Plain(_G.UnitName("target")) == f.name then unit = "target" end
    if not unit then return nil, nil end
    local hp, pw
    if _G.UnitHealth and _G.UnitHealthMax then
        local h, m = Plain(_G.UnitHealth(unit)), Plain(_G.UnitHealthMax(unit))
        if type(h) == "number" and type(m) == "number" and m > 0 then hp = h / m * 100 end
    end
    if _G.UnitPower and _G.UnitPowerMax then
        local p, m = Plain(_G.UnitPower(unit)), Plain(_G.UnitPowerMax(unit))
        if type(p) == "number" and type(m) == "number" and m > 0 then pw = p / m * 100 end
    end
    -- Tiefster Stand im Kampf: volle Energie beim Wirken sagt nur etwas,
    -- wenn sie zwischendurch auch leer war (1.10.11.0, Vosh'gajin: immer
    -- volles Mana, 19 Verhexungen - kein Ausloeser).
    if pw and f and (not f.pwMin or pw < f.pwMin) then f.pwMin = pw end
    if not hp then BM.stats.vitalsHidden = (BM.stats.vitalsHidden or 0) + 1 end
    return hp, pw
end

function BM.LearnStore(create)
    local sd = WeintCodex.SavedData
    local f = BM.fight
    if type(sd) ~= "table" or not f then return nil end
    -- Ein Boss des Kompendiums hat einen festen Schluessel - egal, ob der
    -- Kampf ueber ENCOUNTER_START, Bossrahmen oder den Abgleich begann.
    local key = (type(f.codex) == "table" and f.codex.dungeon and ("c:" .. f.codex.dungeon .. "/" .. f.codex.boss))
        or (type(f.id) == "number" and ("e" .. f.id)) or (type(f.name) == "string" and ("n:" .. f.name)) or nil
    if not key then return nil end
    if create then
        sd.bossLearn = sd.bossLearn or {}
        local st = sd.bossLearn[key] or {}
        sd.bossLearn[key] = st
        if type(f.name) == "string" then st._name = f.name end
        if type(f.instance) == "string" then st._inst = f.instance end
        if type(f.codex) == "table" then st._codex = f.codex.dungeon .. "/" .. f.codex.boss end
        if _G.time then st._last = _G.time() end
    end
    return sd.bossLearn and sd.bossLearn[key]
end

local function Keep(list, v)
    v = math.floor(v + 0.5)
    list[#list + 1] = v
    while #list > BM.SAMPLES do table.remove(list, 1) end
end

-- Vorschlag aus den Messungen - nur ein Vorschlag, der Spieler legt fest.
--   power: jedes Mal bei (fast) voller Energie/Mana
--   hp:    hoechstens einmal je Kampf, immer bei etwa demselben Leben
--   timer: sonst
function BM.Suggest(rec, st)
    if type(rec) ~= "table" then return "timer" end
    local pw, hp = rec.pw, rec.hp
    local drains = type(st) == "table" and type(st._pwMin) == "number" and st._pwMin < 50
    if drains and type(pw) == "table" and #pw >= 2 then
        local all = true
        for _, v in ipairs(pw) do if v < 95 then all = false break end end
        if all then return "power" end
    end
    if type(hp) == "table" and #hp >= 2 and (rec.maxPull or 99) <= 1 then
        local lo, hi = 100, 0
        for _, v in ipairs(hp) do lo, hi = math.min(lo, v), math.max(hi, v) end
        if hi - lo <= 6 and hi < 97 then return "hp", hi end
    end
    return "timer"
end

-- Was gilt: Festgelegtes vor Gemessenem.
function BM.Effective(rec, st)
    local e = type(rec) == "table" and type(rec.edit) == "table" and rec.edit or nil
    local mode = e and e.mode or "auto"
    local sugMode, sugHp = BM.Suggest(rec, st)
    if mode == "auto" then mode = sugMode end
    local hp = e and e.hp or sugHp
    if mode == "hp" and not hp then mode = "timer" end
    return mode, (e and e.first) or rec.first, (e and e.gap) or rec.gap, hp, e and e.sound
end

local function Predict(spell, secs, icon, sound)
    if not secs or secs <= 0 then return end
    local t = BM.Start("nx" .. spell, "~ " .. spell, secs, icon, "textMuted")
    t.soon, t.learned, t.sound = true, true, sound
end

local function Spells(store)
    local n = 0
    for k, v in pairs(store) do if type(v) == "table" and type(k) == "string" and k:sub(1, 1) ~= "_" then n = n + 1 end end
    return n
end

function BM.LearnCast(unit, spell, icon)
    local f = BM.fight
    if not f or not Opt("bossLearn") or type(spell) ~= "string" or spell == "" or spell:sub(1, 1) == "_" then return nil end
    local isBoss = type(unit) == "string" and unit:match("^boss[1-5]$")
    if not isBoss then
        local who = _G.UnitName and Plain(_G.UnitName(unit))
        if type(who) ~= "string" or who ~= f.name then return nil end
    end
    local store = BM.LearnStore(true)
    if not store then return nil end
    local rec = store[spell]
    if type(rec) ~= "table" then
        if Spells(store) >= BM.LEARN_MAX then return nil end
        rec = {}
        store[spell] = rec
    end
    if type(icon) == "number" then rec.icon = icon end
    local now = Now()
    local last = seen[spell]
    if not last then
        local off = math.floor((now - f.start) * 10 + 0.5) / 10
        if off >= 0 and (not rec.first or off < rec.first) then rec.first = off end
    else
        local gap = math.floor((now - last) * 10 + 0.5) / 10
        if gap >= BM.LEARN_MIN and (not rec.gap or gap < rec.gap) then rec.gap = gap end
    end
    seen[spell] = now
    seenCount[spell] = (seenCount[spell] or 0) + 1
    rec.n = (rec.n or 0) + 1
    local hp, pw = BM.BossVitals()
    if hp then rec.hp = rec.hp or {} Keep(rec.hp, hp) end
    if pw then rec.pw = rec.pw or {} Keep(rec.pw, pw) end
    local mode, _, gap, _, sound = BM.Effective(rec, store)
    if mode == "timer" then
        Predict(spell, gap, rec.icon, sound)
    else
        BM.Stop("nx" .. spell)
        for _, w in ipairs(BM.watch) do
            if w.spell == spell and w.kind == "power" then w.armed = false end
        end
    end
    return rec
end

-- Zum Pull: was von frueheren Kaempfen gegen diesen Boss bekannt ist -
-- Zeit, Lebensschwelle oder volle Energie, je Faehigkeit.
function BM.LearnStart()
    for k in pairs(seen) do seen[k] = nil end
    for k in pairs(seenCount) do seenCount[k] = nil end
    for i = #BM.watch, 1, -1 do BM.watch[i] = nil end
    if not Opt("bossLearn") then return 0 end
    -- Angelegt schon zum Pull: auch ein Boss, der nichts wirkt, steht danach
    -- unter "Bosse".
    local store = BM.LearnStore(true)
    if not store then return 0 end
    local n = 0
    for spell, rec in pairs(store) do
        if type(rec) == "table" and type(spell) == "string" and spell:sub(1, 1) ~= "_" then
            local mode, first, _, hp, sound = BM.Effective(rec, store)
            if mode == "timer" and first then
                Predict(spell, first - (Now() - BM.fight.start), rec.icon, sound)
                n = n + 1
            elseif mode == "hp" or mode == "power" then
                BM.watch[#BM.watch + 1] = { spell = spell, kind = mode, at = hp, icon = rec.icon, sound = sound, armed = true }
                n = n + 1
            end
        end
    end
    return n
end

-- Ende des Kampfes: wie oft je Kampf, Zahl der Kaempfe.
function BM.LearnEnd()
    if not BM.fight then return end
    local store = BM.LearnStore(false)
    if not store then return end
    store._pulls = (store._pulls or 0) + 1
    local f = BM.fight
    if f.pwMin and (not store._pwMin or f.pwMin < store._pwMin) then store._pwMin = math.floor(f.pwMin + 0.5) end
    for spell, c in pairs(seenCount) do
        local rec = store[spell]
        if type(rec) == "table" then rec.maxPull = math.max(rec.maxPull or 0, c) end
    end
end

-- Im Takt der Zahlen (0,1 s): Schwellen pruefen. Keine Tabelle je Takt.
function BM.CheckWatches()
    if not BM.fight or #BM.watch == 0 then return end
    local hp, pw = BM.BossVitals()
    for _, w in ipairs(BM.watch) do
        local fire
        if w.kind == "hp" and hp and w.armed and hp <= w.at + BM.HP_PRE then
            w.armed, fire = false, string.format("~ %s (%d %%)", w.spell, w.at)
        elseif w.kind == "power" and pw then
            if w.armed and pw >= BM.POWER_PRE then
                w.armed, fire = false, "~ " .. w.spell .. " (Energie voll)"
            elseif not w.armed and pw < 50 then
                w.armed = true
            end
        end
        if fire then
            local t = BM.Start("nx" .. w.spell, fire, 8, w.icon, "textMuted")
            t.forceEmph, t.noTrack, t.learned = true, true, true
            BM.Sound("Soon", nil, w.sound)
        end
    end
end

function BM.LearnForget(key)
    local sd = WeintCodex.SavedData
    if type(sd) == "table" then
        if key and sd.bossLearn then sd.bossLearn[key] = nil else sd.bossLearn = nil end
    end
    for k in pairs(timers) do if type(k) == "string" and k:find("^nx") then timers[k] = nil end end
    BM.Refresh()
end

-- Sofortzauber (ohne Zauberleiste): UNIT_SPELLCAST_SUCCEEDED. Ein Zauber
-- mit Leiste meldet am Ende auch "erfolgreich" - der zaehlt schon beim Start.
function BM.CastSucceeded(unit, spellID)
    if type(unit) ~= "string" or not BM.fight then return nil end
    local name
    spellID = Plain(spellID)
    if type(spellID) == "number" then
        if _G.C_Spell and _G.C_Spell.GetSpellName then
            local ok, n = pcall(_G.C_Spell.GetSpellName, spellID)
            name = ok and Plain(n) or nil
        elseif _G.GetSpellInfo then
            local ok, n = pcall(_G.GetSpellInfo, spellID)
            name = ok and Plain(n) or nil
        end
    end
    if type(name) ~= "string" then return nil end
    -- Dieselbe Leiste, die gerade lief (Ende eines gewirkten Zaubers): schon
    -- gezaehlt. Nach 15 s gilt der Vermerk nicht mehr (unterbrochen o. ae.).
    if castStarted[unit] == name and Now() - (castStartedAt[unit] or 0) < 15 then
        castStarted[unit] = nil
        return nil
    end
    local icon
    if _G.C_Spell and _G.C_Spell.GetSpellTexture then
        local ok, i = pcall(_G.C_Spell.GetSpellTexture, spellID)
        icon = ok and Plain(i) or nil
    end
    return BM.LearnCast(unit, name, icon)
end
BM.castStarted = castStarted

function BM.CastStop(unit)
    if type(unit) == "string" and timers["cast" .. unit] then BM.Stop("cast" .. unit) return true end
    return nil
end

-- Emotes und Fluestern der Bosse (RAID_BOSS_EMOTE/WHISPER) - der Text des
-- Spiels, "%s" mit dem Namen gefuellt, wo er offen ist.
function BM.Emote(text, who)
    BM.stats.emotes = BM.stats.emotes + 1
    if type(text) == "nil" then return nil end
    local plain = Plain(text)
    if type(plain) == "string" then
        plain = plain:gsub("|T.-|t", ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
        if plain:find("%s", 1, true) then
            local n = Plain(who)
            local ok, out = pcall(string.format, plain, type(n) == "string" and n or "")
            if ok then plain = out end
        end
        text = plain
    end
    BM.Sound("Warn")
    if not Opt("bossWarnings") then return nil end
    BM.Warn(text)
    return true
end

-- Der Ton kommt auch ohne die grosse Anzeige - beides ist einzeln
-- einstellbar.
function BM.Warning(info)
    BM.stats.warnings = BM.stats.warnings + 1
    if type(info) ~= "table" then return nil end
    BM.Sound("Warn")
    if not Opt("bossWarnings") then return nil end
    local text = info.text
    if type(text) == "nil" then text = info.spellName end
    if type(text) == "nil" then return nil end
    BM.Warn(text, Plain(info.iconFileID))
    return true
end

-- Probekampf: Pull, Faehigkeit mit Vorwarnung, Warnung, Sieg - jeder Ton
-- so, wie er eingestellt ist (auch wenn "Wo" gerade nicht passt; der
-- Hauptschalter gilt). Nichts wird gesendet, kein Countdown des Spiels.
function BM.Demo()
    local function play(event) if Opt("bossSound") then BM.Sound(event, true) end end
    local pull = BM.Start("demoPull", "Pull (Probe)", 4, nil, "accent")
    pull.onEnd = function()
        play("Pull")
        local ab = BM.Start("demoSkill", "Fähigkeit des Bosses (Probe)", 6, 136116, "blue")
        ab.soon, ab.demo = true, true
        ab.onEnd = function()
            BM.Warn("Warnung des Spiels (Probe)", 136116)
            play("Warn")
            local fin = BM.Start("demoEnd", "Kampf (Probe)", 4, nil, "textMuted")
            fin.onEnd = function()
                play("Kill")
                Say("Probe zu Ende – so klingt ein Sieg. Ein Wipe hätte seinen eigenen Ton.")
            end
        end
    end
    BM.Refresh()
    return true
end

--------------------------------------------------
-- Ereignisse
--------------------------------------------------

local ev = CreateFrame("Frame")
for _, e in ipairs({ "START_PLAYER_COUNTDOWN", "CANCEL_PLAYER_COUNTDOWN", "CHAT_MSG_ADDON",
        "ENCOUNTER_START", "ENCOUNTER_END", "ENCOUNTER_TIMELINE_EVENT_ADDED",
        "ENCOUNTER_TIMELINE_EVENT_REMOVED", "ENCOUNTER_WARNING", "PLAYER_LOGIN", "PLAYER_REGEN_DISABLED",
        "ENCOUNTER_TIMELINE_EVENT_STATE_CHANGED", "INSTANCE_ENCOUNTER_ENGAGE_UNIT", "BOSS_KILL",
        "PLAYER_REGEN_ENABLED", "RAID_BOSS_EMOTE", "RAID_BOSS_WHISPER", "PLAYER_TARGET_CHANGED",
        "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_FAILED", "UNIT_SPELLCAST_INTERRUPTED",
        "UNIT_SPELLCAST_CHANNEL_START", "UNIT_SPELLCAST_CHANNEL_STOP", "UNIT_SPELLCAST_SUCCEEDED",
        "UNIT_THREAT_LIST_UPDATE", "NAME_PLATE_UNIT_ADDED", "UNIT_HEALTH" }) do
    pcall(ev.RegisterEvent, ev, e)
end
ev:SetScript("OnEvent", function(_, event, a1, a2, a3, a4, a5)
    if event == "PLAYER_LOGIN" then
        local CI = _G.C_ChatInfo
        local reg = (CI and CI.RegisterAddonMessagePrefix) or _G.RegisterAddonMessagePrefix
        if reg then pcall(reg, "BigWigs") pcall(reg, "D5") end
        return
    end
    if event == "PLAYER_REGEN_DISABLED" then
        if setupOn then BM.Setup(false) end
        -- Bossrahmen, die schon vor dem Kampf da waren: jetzt kaempft er.
        -- Sonst: ein Boss des Kompendiums im Ziel oder auf einer Plakette?
        if K.IsActive(KEY) then
            if not BM.Engage() then BM.CodexScan() end
        end
        return
    end
    if not K.IsActive(KEY) then return end
    if event == "START_PLAYER_COUNTDOWN" then
        BM.stats.countdowns = BM.stats.countdowns + 1
        local left = Plain(a2)
        local by = Plain(a5)
        BM.PullBar(type(left) == "number" and left or nil, type(by) == "string" and by:match("^[^-]+") or nil)
    elseif event == "CANCEL_PLAYER_COUNTDOWN" then
        BM.Stop("pull")
    elseif event == "CHAT_MSG_ADDON" then
        BM.Heard(Plain(a1), Plain(a2), Plain(a4))
    elseif event == "ENCOUNTER_START" then
        BM.EncounterStart(a1, a2, a3)
    elseif event == "ENCOUNTER_END" then
        BM.EncounterEnd(a1, a2, a3, a4, a5)
    elseif event == "ENCOUNTER_TIMELINE_EVENT_ADDED" then
        BM.TimelineAdded(a1, a2)
    elseif event == "ENCOUNTER_TIMELINE_EVENT_STATE_CHANGED" then
        BM.TimelineState(a1)
    elseif event == "INSTANCE_ENCOUNTER_ENGAGE_UNIT" then
        BM.Engage()
    elseif event == "BOSS_KILL" then
        BM.BossKill()
    elseif event == "PLAYER_REGEN_ENABLED" then
        BM.EngageEnd()
    elseif event == "RAID_BOSS_EMOTE" or event == "RAID_BOSS_WHISPER" then
        BM.Emote(a1, a2)
    elseif event == "PLAYER_TARGET_CHANGED" then
        BM.CastStop("target")
        if not BM.fight then BM.CodexEngage("target") end
    elseif event == "UNIT_THREAT_LIST_UPDATE" or event == "NAME_PLATE_UNIT_ADDED" then
        if not BM.fight then BM.CodexEngage(a1) end
    elseif event == "UNIT_HEALTH" then
        if BM.fight and BM.fight.src == "codex" then BM.CodexHealth(a1) end
    elseif event == "UNIT_SPELLCAST_START" then
        BM.CastStart(a1, false)
    elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
        BM.CastStart(a1, true)
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        BM.CastSucceeded(a1, a3)
    elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_FAILED"
        or event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_CHANNEL_STOP" then
        BM.CastStop(a1)
    elseif event == "ENCOUNTER_TIMELINE_EVENT_REMOVED" then
        BM.TimelineRemoved(a1)
    elseif event == "ENCOUNTER_WARNING" then
        BM.Warning(a1)
    end
end)
BM.ev = ev

-- /pull und /break - nur, wenn kein anderes Addon (BigWigs, DBM) sie hat.
function BM.RegisterSlash()
    local hash = _G.hash_SlashCmdList
    local list = _G.SlashCmdList
    if type(list) ~= "table" then return end
    if not (hash and hash["/PULL"]) and not list.BIGWIGSPULL and not list.DEADLYBOSSMODSPULL then
        _G.SLASH_WEINTCODEXPULL1 = "/pull"
        list.WEINTCODEXPULL = function(msg) if K.IsActive(KEY) and Opt("bossPull") then BM.Pull(msg ~= "" and msg or nil) end end
    end
    if not (hash and hash["/BREAK"]) and not list.BIGWIGSBREAK then
        _G.SLASH_WEINTCODEXBREAK1 = "/break"
        list.WEINTCODEXBREAK = function(msg) if K.IsActive(KEY) and Opt("bossPull") then BM.Break(msg ~= "" and msg or nil) end end
    end
    -- Immer frei: eigene Namen.
    _G.SLASH_WEINTCODEXPULL2 = "/wcpull"
    list.WEINTCODEXPULL = list.WEINTCODEXPULL or function(msg) if K.IsActive(KEY) and Opt("bossPull") then BM.Pull(msg ~= "" and msg or nil) end end
    _G.SLASH_WEINTCODEXBREAK2 = "/wcbreak"
    list.WEINTCODEXBREAK = list.WEINTCODEXBREAK or function(msg) if K.IsActive(KEY) and Opt("bossPull") then BM.Break(msg ~= "" and msg or nil) end end
end
BM.RegisterSlash()

-- Fuer /wcui prüfen.
function BM.StatusLine()
    local s = BM.stats
    return string.format("Bosskämpfe: %d Kämpfe (+%d über Bossrahmen, +%d über das Kompendium), %d Fähigkeiten aus der Zeitleiste (%d ohne offene Dauer), %d Zauber von Bossen (%d verdeckt), %d Warnungen, %d Emotes, %d Countdowns, %d Timer anderer Bossmods",
        s.encounters, s.engaged, s.codex or 0, s.timeline, s.secret, s.casts, s.castSecret, s.warnings, s.emotes, s.countdowns, s.heard)
end

--------------------------------------------------
-- Einstellungen
--------------------------------------------------

local function off(k) return function() return not K.Get(KEY, k) end end
local SOUND_NONE = { { value = "none", text = "Kein Ton" } }
local function SoundItems() local FA = WeintCodex.UIFireAlarm return FA and FA.Items(true) or SOUND_NONE end
local function Preview(v)
    local FA = WeintCodex.UIFireAlarm
    if v ~= "none" and v ~= "" and FA then FA.Preview(v, K.Get(KEY, "bossChannel") or "Master") end
end
-- Eine Auswahl spielt den Ton einmal vor - so hoert man, was man waehlt.
local function Sound(event, label, description)
    local key = "bossSnd" .. event
    return { type = "dropdown", label = label, key = key, items = SoundItems, disabled = off("bossSound"),
             tooltip = description, set = function(v) K.Set(KEY, key, v) Preview(v) end }
end

-- Reiter 1: was angezeigt wird.
local function BuildGeneral(B)
    B:Section("Pull und Pause", "/pull 10 startet den Countdown des Spiels – die ganze Gruppe sieht ihn, auch ohne WeintCodex. /break 5 ist eine Pause von fünf Minuten, nur für dich. 0 bricht ab. Haben BigWigs oder DBM die Befehle schon, heißen sie /wcpull und /wcbreak.")
    B:Row({ type = "toggle", label = "Pull- und Pausenleiste", key = "bossPull" },
          { type = "toggle", label = "Timer von BigWigs und DBM zeigen", key = "bossListen", disabled = off("bossPull"),
            description = "Startet jemand mit diesen Addons einen Pull oder eine Pause, erscheint die Leiste auch bei dir. WeintCodex hört nur zu." })
    B:Section("Kampf", "Wie lange der Bosskampf läuft, und am Ende „besiegt in 3:12“ mit deiner Bestzeit für diesen Boss – oder „Wipe nach …“.")
    B:Row({ type = "toggle", label = "Kampftimer und Bestzeit", key = "bossFight" },
          { type = "button", label = "Probe", text = "Probekampf abspielen", onClick = BM.Demo,
            tooltip = "Pull, Fähigkeit mit Vorwarnung, Warnung und Sieg – mit deinen Tönen, in gut 14 Sekunden. Nur bei dir." })
    B:Section("Was das Spiel meldet", "Nur, was das Spiel selbst sagt – eigene Taktiken gibt es nicht. Die Zeitleiste der Fähigkeiten kommt nur bei Kämpfen, für die das Spiel eine hat; in alten Dungeons und auf Classic-Servern bleiben die Zauber, die ein Boss gerade wirkt, und seine Emotes. Was ankam, zeigt /wcui prüfen.")
    B:Row({ type = "toggle", label = "Fähigkeiten als Leisten", key = "bossTimeline",
            description = "Aus der Zeitleiste des Spiels – mit Pausen, wie das Spiel sie meldet." },
          { type = "toggle", label = "Zauber der Bosse als Leisten", key = "bossCasts",
            description = "Was ein Boss gerade wirkt, mit Restzeit. Ohne Bossrahmen auch dein Ziel, wenn es ein Elitegegner in einer Instanz ist. Gold heißt: unterbrechbar." })
    B:Row({ type = "toggle", label = "Warnungen groß in der Mitte", key = "bossWarnings",
            description = "Warnungen und Emotes der Bosse – das Spiel zeigt sie auch selbst; das hier ist eine zweite, größere Anzeige." },
          { type = "toggle", label = "Zeiten aus eigenen Kämpfen lernen", key = "bossLearn",
            description = "Wann ein Boss was wirkt, gemessen in deinen Kämpfen. Solche Leisten tragen ein „~“. Einstellen je Boss unter „Bosse“." })
end

-- Reiter 2: Leisten und Zeitleiste.
local function BuildBars(B)
    local function look(k) return function(v) K.Set(KEY, k, v) BM.ApplyLook() end end
    B:Section("Leisten", "Am einfachsten direkt an den Leisten: Testleisten laufen, du ziehst sie an ihren Platz und stellst daneben ein – wie bei BigWigs und DBM.")
    B:Row({ type = "button", label = "Einrichten", text = "Leisten einstellen", kind = "primary",
            onClick = function() BM.Setup(true) end },
          { type = "toggle", label = "Was gleich dran ist, groß extra", key = "bossEmph", set = look("bossEmph"),
            description = "In den letzten Sekunden springt eine Leiste größer und rot an einen eigenen Platz." })
    B:Row({ type = "slider", label = "Breite", key = "bossBarW", min = 160, max = 420, step = 10, set = look("bossBarW") },
          { type = "slider", label = "Höhe", key = "bossBarH", min = 14, max = 32, step = 1, set = look("bossBarH") })
    B:Row({ type = "dropdown", label = "Neue Leisten", key = "bossGrow", set = look("bossGrow"), items = {
                { value = "down", text = "Nach unten anhängen" }, { value = "up", text = "Nach oben anhängen" } } },
          { type = "dropdown", label = "Symbol", key = "bossIcon", set = look("bossIcon"), items = {
                { value = "left", text = "Links" }, { value = "right", text = "Rechts" }, { value = "none", text = "Ohne" } } })
    B:Section("Zeitleiste", "Eine senkrechte Spur neben den Leisten: jede Fähigkeit wandert als Symbol nach unten, unten ist „jetzt“. Im Bosskampf bleibt sie stehen.")
    B:Row({ type = "toggle", label = "Zeitleiste von oben nach unten", key = "bossTrack", set = look("bossTrack") },
          { type = "dropdown", label = "Zeitleiste zeigt", key = "bossTrackSecs", set = look("bossTrackSecs"), items = {
                { value = 15, text = "die nächsten 15 Sekunden" }, { value = 30, text = "die nächsten 30 Sekunden" },
                { value = 60, text = "die nächste Minute" } } })
    B:Advanced()
    B:Row({ type = "slider", label = "Schrift", key = "bossFont", min = 9, max = 16, step = 1, set = look("bossFont") },
          { type = "slider", label = "Höchstens so viele Leisten", key = "bossMax", min = 3, max = BM.MAX_ROWS, step = 1, set = look("bossMax") })
    B:Row({ type = "dropdown", label = "Leiste", key = "bossFill", set = look("bossFill"), items = {
                { value = "drain", text = "Leert sich" }, { value = "fill", text = "Füllt sich" } } },
          { type = "slider", label = "„Gleich dran“ ab Sekunden", key = "bossEmphSecs", min = 2, max = 10, step = 1, set = look("bossEmphSecs") })
    B:Row({ type = "slider", label = "Höhe der Zeitleiste", key = "bossTrackH", min = 160, max = 500, step = 10, set = look("bossTrackH") },
          { type = "slider", label = "Schrift der großen Warnung", key = "bossWarnSize", min = 16, max = 40, step = 2, set = look("bossWarnSize") })
    B:Row({ type = "slider", label = "Große Warnung steht", key = "bossWarnTime", min = 2, max = 8, step = 1,
            format = function(v) return v .. " s" end },
          { type = "empty" })
    B:EndAdvanced()
end

-- Reiter 3: Toene.
local function BuildSounds(B)
    B:Section("Töne", "Für jeden Anlass ein eigener Ton – oder „Kein Ton“. Eine Auswahl spielt ihn einmal vor; dabei sind die Memes, deine eigenen Töne aus der Companion und Töne des Spiels. Ein langer Ton wird nicht vom nächsten unterbrochen. Einzelne Fähigkeiten bekommen eigene Töne unter „Bosse“.")
    B:Row({ type = "toggle", label = "Töne bei Bosskämpfen", key = "bossSound",
            description = "Schaltet alle Töne auf einmal." },
          { type = "dropdown", label = "Wo", key = "bossWhere", disabled = off("bossSound"), items = {
                { value = "all",      text = "Überall" },
                { value = "group",    text = "Nur in einer Gruppe" },
                { value = "instance", text = "Nur in Dungeons und Schlachtzügen" } } })
    B:Row(Sound("Pull", "Wenn der Pull endet"), Sound("Break", "Wenn die Pause endet"))
    B:Row(Sound("Soon", "Kurz vor einer Fähigkeit", "Wenn die Leiste einer Fähigkeit fast abgelaufen ist – aus der Zeitleiste oder aus deinen Messungen."),
          { type = "dropdown", label = "So früh vorher", key = "bossSoonSecs", disabled = off("bossSound"), items = {
                { value = 2, text = "2 Sekunden vorher" }, { value = 3, text = "3 Sekunden vorher" },
                { value = 5, text = "5 Sekunden vorher" } } })
    B:Row(Sound("Cast", "Wenn ein Boss zu zaubern beginnt", "Bei jedem Zauber mit Leiste – bei Bossen, die viel wirken, oft."),
          Sound("Warn", "Bei Warnung oder Emote", "Kommt auch ohne die große Anzeige. Das Spiel hat oft schon einen eigenen Ton dafür."))
    B:Row(Sound("Kill", "Wenn der Boss fällt"), Sound("Wipe", "Bei einem Wipe"))
    B:Row({ type = "dropdown", label = "Lautstärke über", key = "bossChannel", disabled = off("bossSound"), items = {
                { value = "Master", text = "Gesamtlautstärke" },
                { value = "SFX",    text = "Effekte" },
                { value = "Dialog", text = "Dialog" } },
            tooltip = "Welcher Regler in den Toneinstellungen des Spiels diese Töne lauter oder leiser macht. Gesamtlautstärke hört man auch, wenn Effekte stumm sind." },
          { type = "empty" })
end

--------------------------------------------------
-- Reiter 4: Bosse - je Boss und Faehigkeit festlegen, wann sie kommt.
-- Grundlage ist die eigene Messung (SavedData.bossLearn); was der Spieler
-- eintraegt (rec.edit), gilt davor. Nichts davon kommt aus fremden Daten.
--------------------------------------------------

BM.sel = { inst = nil, boss = nil, spell = nil }
BM.listPage = 1
local NO_INST = "Ohne Instanz"

function BM.Bosses()
    local sd = WeintCodex.SavedData
    return type(sd) == "table" and type(sd.bossLearn) == "table" and sd.bossLearn or {}
end
local function InstOf(st) return type(st._inst) == "string" and st._inst or NO_INST end

-- Reihenfolge der Bosse wie im Kompendium ("dungeon/boss" -> Platz).
local compOrder
local function CompOrder(code)
    if not compOrder then
        compOrder = {}
        for _, list in ipairs({ _G.WeintCodex_Dungeons or {}, _G.WeintCodex_ClassicDungeons or {} }) do
            for _, d in ipairs(list) do
                for i, b in ipairs(type(d.bosses) == "table" and d.bosses or {}) do
                    compOrder[tostring(d.id) .. "/" .. tostring(b.id)] = b.order or i
                end
            end
        end
    end
    return type(code) == "string" and compOrder[code] or nil
end

-- Instanzen: wo du gerade bist zuerst, dann zuletzt besucht zuerst.
function BM.InstItems()
    local here = BM.InstanceName()
    local last, out = {}, {}
    for _, st in pairs(BM.Bosses()) do
        if type(st) == "table" then
            local i = InstOf(st)
            last[i] = math.max(last[i] or 0, tonumber(st._last) or 0)
        end
    end
    for i, t in pairs(last) do
        out[#out + 1] = { value = i, text = (i == here) and (i .. " (hier)") or i, last = (i == here) and math.huge or t }
    end
    table.sort(out, function(a, b) if a.last ~= b.last then return a.last > b.last end return a.value < b.value end)
    return out
end
-- Bosse einer Instanz: in der Reihenfolge des Kompendiums, sonst nach Name.
function BM.BossItems()
    local out = {}
    for key, st in pairs(BM.Bosses()) do
        if type(st) == "table" and InstOf(st) == BM.sel.inst then
            out[#out + 1] = { value = key, text = type(st._name) == "string" and st._name or key,
                              order = CompOrder(st._codex) or 999 }
        end
    end
    table.sort(out, function(a, b) if a.order ~= b.order then return a.order < b.order end return a.text < b.text end)
    return out
end
function BM.SpellItems()
    local st = BM.sel.boss and BM.Bosses()[BM.sel.boss]
    local out = {}
    if type(st) ~= "table" then return out end
    for spell, rec in pairs(st) do
        if type(rec) == "table" and type(spell) == "string" and spell:sub(1, 1) ~= "_" then
            out[#out + 1] = { value = spell, text = spell, first = rec.first or 9999 }
        end
    end
    table.sort(out, function(a, b) if a.first ~= b.first then return a.first < b.first end return a.text < b.text end)
    return out
end
-- Vorbelegt: die Instanz, in der du bist, sonst die zuletzt besuchte; der
-- zuletzt gekaempfte Boss darin. Eine gueltige Wahl bleibt.
function BM.FixSelection()
    local function has(items, v) for _, it in ipairs(items) do if it.value == v then return true end end return false end
    local insts = BM.InstItems()
    if not has(insts, BM.sel.inst) then BM.sel.inst, BM.sel.boss, BM.sel.spell = insts[1] and insts[1].value, nil, nil end
    local bosses = BM.BossItems()
    if not has(bosses, BM.sel.boss) then
        local best, bestT
        for _, it in ipairs(bosses) do
            local t = tonumber(BM.Bosses()[it.value]._last) or 0
            if not bestT or t > bestT then best, bestT = it.value, t end
        end
        BM.sel.boss, BM.sel.spell, BM.listPage = best, nil, 1
    end
    local spells = BM.SpellItems()
    if not has(spells, BM.sel.spell) then BM.sel.spell = spells[1] and spells[1].value or nil end
end
function BM.SelRec()
    local st = BM.sel.boss and BM.Bosses()[BM.sel.boss]
    local rec = type(st) == "table" and BM.sel.spell and st[BM.sel.spell]
    return type(rec) == "table" and rec or nil, st
end

local function Secs(v) return v and (string.format("%.1f", v):gsub("%.0$", ""):gsub("%.", ",")) .. " s" or "–" end
local function IsEmpty(t) for _ in pairs(t) do return false end return true end
local function Times(n) return (n == 1) and "1 Kampf" or (tostring(n or 0) .. " Kämpfe") end
function BM.Measured(rec, st)
    if not rec then return "" end
    local parts = {}
    parts[#parts + 1] = "Gemessen in " .. Times(st and st._pulls or 0) .. ", " .. tostring(rec.n or 0) .. "× gesehen"
    parts[#parts + 1] = "zuerst nach " .. Secs(rec.first)
    if rec.gap then parts[#parts + 1] = "danach frühestens alle " .. Secs(rec.gap) end
    if type(rec.hp) == "table" and #rec.hp > 0 then
        local lo, hi = 100, 0
        for _, v in ipairs(rec.hp) do lo, hi = math.min(lo, v), math.max(hi, v) end
        parts[#parts + 1] = (lo == hi) and ("Leben beim Wirken " .. lo .. " %") or ("Leben beim Wirken " .. lo .. "–" .. hi .. " %")
    else
        parts[#parts + 1] = "Leben des Bosses nicht offen gemeldet"
    end
    return table.concat(parts, " · ") .. "."
end
function BM.SuggestText(rec, st)
    local m, hp = BM.Suggest(rec, st)
    if m == "power" then return "bei voller Energie/Mana" end
    if m == "hp" then return "bei " .. hp .. " % Leben" end
    return "nach Zeit"
end
-- Eine Zeile der Tabelle: wie die Faehigkeit gerade angekuendigt wird.
function BM.HowText(rec, st)
    local mode, first, gap, hp = BM.Effective(rec, st)
    local own = type(rec.edit) == "table" and not IsEmpty(rec.edit)
    local t
    if mode == "off" then t = "nicht angekündigt"
    elseif mode == "hp" then t = "bei " .. hp .. " % Leben"
    elseif mode == "power" then t = "bei voller Energie"
    elseif gap then t = "nach " .. Secs(first) .. ", dann alle " .. Secs(gap)
    else t = "nach " .. Secs(first) end
    return own and (t .. " – eingestellt") or t
end

local function Edit(rec, create)
    if not rec then return nil end
    if create and type(rec.edit) ~= "table" then rec.edit = {} end
    return rec.edit
end
local function Num(text)
    if type(text) ~= "string" then return nil end
    local v = tonumber((text:gsub(",", ".")))
    return v and v >= 0 and v or nil
end
local function NumText(v) return v and (string.format("%.1f", v):gsub("%.0$", ""):gsub("%.", ",")) or "" end
local function Rebuild() local O = WeintCodex.UIOptions if O and O.Rebuild then O.Rebuild() end end

-- Die Tabelle aller Faehigkeiten eines Bosses: Haken = ankuendigen,
-- Klick auf die Zeile = darunter einstellen. Feste Hoehe, Seiten statt
-- Rollen (BM.LIST_ROWS je Seite).
BM.LIST_ROWS, BM.LIST_ROW_H = 8, 26
function BM.ToggleSpell(spell)
    local st = BM.sel.boss and BM.Bosses()[BM.sel.boss]
    local rec = type(st) == "table" and st[spell]
    if type(rec) ~= "table" then return nil end
    local e = Edit(rec, true)
    if e.mode == "off" then e.mode = nil else e.mode = "off" end
    if IsEmpty(e) then rec.edit = nil end
    return e.mode ~= "off"
end
local function CreateSpellList(parent, width)
    local H = BM.LIST_ROW_H
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(width, 22 + BM.LIST_ROWS * H + 34)
    local head = K.NewText(f, 11, "OVERLAY")
    head:SetPoint("TOPLEFT", f, "TOPLEFT", 34, -2)
    head:SetTextColor(unpack(C.textMuted))
    head:SetText("Fähigkeit")
    local head2 = K.NewText(f, 11, "OVERLAY")
    head2:SetPoint("TOPLEFT", f, "TOPLEFT", math.floor(width * 0.42), -2)
    head2:SetTextColor(unpack(C.textMuted))
    head2:SetText("Kommt")
    f.rows = {}
    for i = 1, BM.LIST_ROWS do
        local r = CreateFrame("Button", nil, f)
        r:SetSize(width, H - 2)
        r:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -(20 + (i - 1) * H))
        r.bg = r:CreateTexture(nil, "BACKGROUND")
        r.bg:SetAllPoints(r)
        r.check = CreateFrame("Button", nil, r)
        r.check:SetSize(16, 16)
        r.check:SetPoint("LEFT", r, "LEFT", 8, 0)
        r.box = r.check:CreateTexture(nil, "ARTWORK")
        r.box:SetAllPoints(r.check)
        r.name = K.NewText(r, 12, "OVERLAY")
        r.name:SetPoint("LEFT", r, "LEFT", 34, 0)
        r.name:SetWidth(math.floor(width * 0.42) - 40)
        r.name:SetJustifyH("LEFT")
        r.name:SetWordWrap(false)
        r.how = K.NewText(r, 11, "OVERLAY")
        r.how:SetPoint("LEFT", r, "LEFT", math.floor(width * 0.42), 0)
        r.how:SetWidth(math.floor(width * 0.46))
        r.how:SetJustifyH("LEFT")
        r.how:SetWordWrap(false)
        r.seen = K.NewText(r, 11, "OVERLAY")
        r.seen:SetPoint("RIGHT", r, "RIGHT", -8, 0)
        r.seen:SetTextColor(unpack(C.textMuted))
        r:SetScript("OnClick", function(self)
            if self._spell then BM.sel.spell = self._spell Rebuild() end
        end)
        r.check:SetScript("OnClick", function(self)
            local spell = self:GetParent()._spell
            if spell then BM.ToggleSpell(spell) f.Sync() end
        end)
        r:Hide()
        f.rows[i] = r
    end
    f.prev = WeintCodex.CreateButton(f, { text = "‹ Zurück", kind = "secondary", height = 26, size = 11,
        onClick = function() BM.listPage = math.max(1, BM.listPage - 1) f.Sync() end })
    f.prev:SetSize(100, 26)
    f.prev:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
    f.next = WeintCodex.CreateButton(f, { text = "Weiter ›", kind = "secondary", height = 26, size = 11,
        onClick = function() BM.listPage = BM.listPage + 1 f.Sync() end })
    f.next:SetSize(100, 26)
    f.next:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
    f.pageText = K.NewText(f, 11, "OVERLAY")
    f.pageText:SetPoint("BOTTOM", f, "BOTTOM", 0, 7)
    f.pageText:SetTextColor(unpack(C.textMuted))
    f.Sync = function()
        local items = BM.SpellItems()
        local st = BM.sel.boss and BM.Bosses()[BM.sel.boss]
        local pages = math.max(1, math.ceil(#items / BM.LIST_ROWS))
        -- Die gewaehlte Faehigkeit auf ihrer Seite zeigen.
        if f._for ~= BM.sel.spell then
            f._for = BM.sel.spell
            for idx, it in ipairs(items) do
                if it.value == BM.sel.spell then BM.listPage = math.ceil(idx / BM.LIST_ROWS) break end
            end
        end
        BM.listPage = math.min(math.max(1, BM.listPage), pages)
        local base = (BM.listPage - 1) * BM.LIST_ROWS
        for i, r in ipairs(f.rows) do
            local it = items[base + i]
            local rec = it and type(st) == "table" and st[it.value]
            if rec then
                r._spell = it.value
                local on = BM.Effective(rec, st) ~= "off"
                local sel = it.value == BM.sel.spell
                local bg = sel and C.surface3 or C.surface2
                r.bg:SetColorTexture(bg[1], bg[2], bg[3], sel and 1 or 0.5)
                local bc = on and C.accent or C.surface3
                r.box:SetColorTexture(bc[1], bc[2], bc[3], 1)
                r.name:SetText(it.value)
                r.name:SetTextColor(unpack(on and C.textBright or C.textMuted))
                r.how:SetText(BM.HowText(rec, st))
                r.how:SetTextColor(unpack(on and C.textNormal or C.textMuted))
                r.seen:SetText((rec.n or 0) .. "×")
                r:Show()
            else
                r._spell = nil
                r:Hide()
            end
        end
        f.pageText:SetText(#items == 0 and "Noch keine Fähigkeit gesehen."
            or string.format("%d–%d von %d", base + 1, math.min(base + BM.LIST_ROWS, #items), #items))
        if BM.listPage > 1 then f.prev:Show() else f.prev:Hide() end
        if BM.listPage < pages then f.next:Show() else f.next:Hide() end
    end
    f.Sync()
    BM.spellList = f
    return f
end
BM.CreateSpellList = CreateSpellList

local function BuildBosses(B)
    BM.FixSelection()
    B:Section("Bosse", "Nach jedem Bosskampf steht hier, wann der Boss was gewirkt hat. Haken weg = nicht ankündigen. Klick auf eine Zeile: darunter genauer einstellen.")
    if not BM.sel.boss then
        B:Row({ type = "toggle", label = "Zeiten aus eigenen Kämpfen lernen", key = "bossLearn" },
              { type = "empty" })
        B:Note("Noch kein Boss gemessen. Nach dem ersten Bosskampf steht er hier – du landest immer in der Instanz, in der du gerade bist.")
        return
    end
    B:Row({ type = "dropdown", label = "Instanz", items = BM.InstItems,
            get = function() return BM.sel.inst end,
            set = function(v) BM.sel.inst, BM.sel.boss, BM.sel.spell = v, nil, nil Rebuild() end },
          { type = "dropdown", label = "Boss", items = BM.BossItems,
            get = function() return BM.sel.boss end,
            set = function(v) BM.sel.boss, BM.sel.spell, BM.listPage = v, nil, 1 Rebuild() end })
    B:Row({ type = "custom", height = 22 + BM.LIST_ROWS * BM.LIST_ROW_H + 34, create = CreateSpellList })
    local rec, st = BM.SelRec()
    if not rec then return end
    B:Section(BM.sel.spell, BM.Measured(rec, st))
    B:Row({ type = "dropdown", label = "Ankündigen", items = function() return {
                { value = "auto",  text = "Wie gemessen (" .. BM.SuggestText(rec, st) .. ")" },
                { value = "timer", text = "Nach Zeit" },
                { value = "hp",    text = "Bei Leben des Bosses" },
                { value = "power", text = "Bei voller Energie/Mana" },
                { value = "off",   text = "Nicht ankündigen" } } end,
            get = function() local e = Edit(rec) return e and e.mode or "auto" end,
            set = function(v) local e = Edit(rec, true) e.mode = (v ~= "auto") and v or nil Rebuild() end,
            tooltip = "Leben und Energie gehen nur, wenn das Spiel sie im Kampf offen meldet – sonst bleibt nur „nach Zeit“." },
          { type = "dropdown", label = "Eigener Ton", items = function()
                local list = { { value = "", text = "Wie bei „Kurz vor einer Fähigkeit“" } }
                for _, it in ipairs(SoundItems()) do list[#list + 1] = it end
                return list end,
            get = function() local e = Edit(rec) return e and e.sound or "" end,
            set = function(v) local e = Edit(rec, true) e.sound = (v ~= "") and v or nil Preview(v) end })
    local mode = BM.Effective(rec, st)
    if mode == "hp" then
        B:Row({ type = "input", label = "Bei Leben des Bosses (%)",
                get = function() local e = Edit(rec) return NumText(e and e.hp) end,
                set = function(v) local e = Edit(rec, true) local n = Num(v) e.hp = n and math.min(100, n) or nil end },
              { type = "button", label = "Diese Fähigkeit", text = "Auf Messung zurücksetzen",
                onClick = function() rec.edit = nil Rebuild() end })
    elseif mode ~= "off" and mode ~= "power" then
        B:Row({ type = "input", label = "Zuerst nach dem Pull (s) – leer: " .. Secs(rec.first),
                get = function() local e = Edit(rec) return NumText(e and e.first) end,
                set = function(v) local e = Edit(rec, true) e.first = Num(v) end },
              { type = "input", label = "Danach alle (s) – leer: " .. Secs(rec.gap),
                get = function() local e = Edit(rec) return NumText(e and e.gap) end,
                set = function(v) local e = Edit(rec, true) e.gap = Num(v) end })
        B:Row({ type = "button", label = "Diese Fähigkeit", text = "Auf Messung zurücksetzen",
                onClick = function() rec.edit = nil Rebuild() end },
              { type = "empty" })
    else
        B:Row({ type = "button", label = "Diese Fähigkeit", text = "Auf Messung zurücksetzen",
                onClick = function() rec.edit = nil Rebuild() end },
              { type = "empty" })
    end
    B:Advanced()
    B:Row({ type = "toggle", label = "Zeiten aus eigenen Kämpfen lernen", key = "bossLearn" },
          { type = "button", label = "Diesen Boss", text = "Messung und Einstellungen löschen",
            onClick = function() BM.LearnForget(BM.sel.boss) BM.sel.boss, BM.sel.spell = nil, nil Rebuild() end })
    B:Row({ type = "button", label = "Alle Bosse", text = "Alles vergessen",
            onClick = function() BM.LearnForget() BM.sel.inst, BM.sel.boss, BM.sel.spell = nil, nil, nil Rebuild() end,
            tooltip = "Löscht alle Messungen und Einstellungen aller Bosse." },
          { type = "empty" })
    B:EndAdvanced()
end

BM.BuildGeneral, BM.BuildBars, BM.BuildSounds, BM.BuildBosses = BuildGeneral, BuildBars, BuildSounds, BuildBosses
BM.BuildPage = BuildGeneral

local mod = K.Module(KEY)
if mod then
    for k, v in pairs(BM.DEFAULTS) do
        if mod.defaults[k] == nil then mod.defaults[k] = v end
    end
    -- 1.10.9.0 (Wunsch: "eigene Rubrik links, eine Registerkarte genuegt
    -- nicht"): vier Reiter im eigenen Thema "Bosskaempfe" (QoL.THEMES).
    local pages = {
        { key = "boss",        label = "Allgemein", build = BuildGeneral, rank = 16 },
        { key = "boss_bars",   label = "Leisten",   build = BuildBars,    rank = 16.1 },
        { key = "boss_sounds", label = "Töne",      build = BuildSounds,  rank = 16.2 },
        { key = "boss_bosses", label = "Bosse",     build = BuildBosses,  rank = 16.3 },
    }
    for _, p in ipairs(pages) do
        mod.pages[#mod.pages + 1] = { key = p.key, label = p.label, build = p.build }
        if type(mod.pageOrder) == "table" then mod.pageOrder[p.key] = p.rank end
    end
end
