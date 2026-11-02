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
}

-- Die Anlaesse, in der Reihenfolge der Seite.
BM.SOUND_EVENTS = { "Pull", "Break", "Soon", "Warn", "Kill", "Wipe" }

BM.MAX_ROWS, BM.EMPH_ROWS, BM.GAP = 10, 4, 3
BM.EMPH_SCALE = 1.5
BM.stats = { timeline = 0, secret = 0, warnings = 0, encounters = 0, countdowns = 0, heard = 0 }

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
function BM.Sound(event, force)
    if not force and (not Opt("bossSound") or not BM.Here()) then return nil end
    local key = K.Get(KEY, "bossSnd" .. event)
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
-- auch waehrend Leisten laufen.
local function LayRows(f, count, w, h, font)
    local up = K.Get(KEY, "bossGrow") == "up"
    local icon = K.Get(KEY, "bossIcon")
    f:SetSize(w, count * (h + BM.GAP) - BM.GAP)
    for i, r in ipairs(f.rows) do
        r:SetSize(w, h)
        r:ClearAllPoints()
        local off = (i - 1) * (h + BM.GAP)
        if up then r:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, off)
        else r:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -off) end
        r.icon:ClearAllPoints()
        r.bar:ClearAllPoints()
        r.icon:SetSize(h, h)
        r.noIcon = icon == "none"
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

function BM.ApplyLook()
    if not frame then return end
    local w, h, font, max = BM.Look()
    LayRows(frame, max, w, h, font)
    LayRows(emph, BM.EMPH_ROWS, math.floor(w * 1.25 + 0.5), math.floor(h * BM.EMPH_SCALE + 0.5), math.floor(font * 1.3 + 0.5))
    local size = Num("bossWarnSize", 16, 40)
    K.SetFont(frame.warn.text, size)
    frame.warn:SetSize(700, size + 16)
    BM.Refresh()
end

local function ColorOf(name)
    local c = C[name or "accent"] or C.accent
    return c[1], c[2], c[3]
end

-- Der Takt: Werte einmal je Takt gelesen, keine Tabelle und keine
-- Funktion je Bild (CLAUDE.md, "Anything that runs repeatedly").
local tNow, tFill, tEmphOn, tEmphSecs, tSoonSecs, tDone, tRelayout
local function TickRow(r)
    local t = r.timer
    if not t or not r:IsShown() then return end
    if not t.ends then
        r.bar:SetValue(1)
        r.time:SetText(BM.Format(tNow - t.start))
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
    r.time:SetText(BM.Format(left))
    if t.soon and not t.warned and left <= tSoonSecs then
        t.warned = true
        if not t.demo or Opt("bossSound") then BM.Sound("Soon", t.demo) end
    end
    if tEmphOn and not t.emph and left <= tEmphSecs then tRelayout = true end
end

function BM.Tick()
    if not frame then return end
    tNow = Now()
    tFill = K.Get(KEY, "bossFill") == "fill"
    tEmphOn = Opt("bossEmph")
    tEmphSecs = Num("bossEmphSecs", 2, 10)
    tSoonSecs = tonumber(K.Get(KEY, "bossSoonSecs")) or 3
    tDone, tRelayout = nil, nil
    for i = 1, BM.MAX_ROWS do TickRow(frame.rows[i]) end
    for i = 1, BM.EMPH_ROWS do TickRow(emph.rows[i]) end
    local done = tDone
    if done then
        timers[done.key] = nil
        if done.onEnd then done.onEnd() end
        BM.Refresh()
    elseif tRelayout then
        BM.Refresh()
    end
end

local function Fill(r, t)
    r.timer = t
    r.label:SetText(t.label)
    if t.icon and not r.noIcon then r.icon:SetTexture(t.icon) r.icon:Show() else r.icon:Hide() end
    r.bar:SetStatusBarColor(ColorOf(t.emph and "red" or t.color))
    r:Show()
end
local function Clear(r) r.timer = nil r:Hide() end

local function Build()
    if frame then return frame end
    frame = CreateFrame("Frame", "WeintCodexBossBars", UIParent)
    frame:SetFrameStrata("MEDIUM")
    frame.rows = {}
    for i = 1, BM.MAX_ROWS do frame.rows[i] = NewRow(frame) end
    emph = CreateFrame("Frame", "WeintCodexBossEmph", UIParent)
    emph:SetFrameStrata("MEDIUM")
    emph.rows = {}
    for i = 1, BM.EMPH_ROWS do emph.rows[i] = NewRow(emph) end
    -- Grosse Warnung in der Mitte (eigener Platz, verschiebbar).
    local warn = CreateFrame("Frame", "WeintCodexBossWarning", UIParent)
    warn:SetSize(700, 40)
    warn.text = K.NewText(warn, 24, "OVERLAY")
    warn.text:SetAllPoints(warn)
    warn:Hide()
    frame.warn = warn
    clock = CreateFrame("Frame", nil, UIParent)
    clock._acc = 0
    clock:SetScript("OnUpdate", function(self, el)
        self._acc = self._acc + (el or 0)
        if self._acc < 0.1 then return end
        self._acc = 0
        BM.Tick()
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
function BM.Refresh()
    local f = Build()
    local list = BM.Sorted()
    local now = Now()
    local useEmph = Opt("bossEmph")
    local secs = Num("bossEmphSecs", 2, 10)
    local _, _, _, max = BM.Look()
    local mi, ei = 0, 0
    for i = 1, #list do
        local t = list[i]
        local e = useEmph and ei < BM.EMPH_ROWS and (t.forceEmph or (t.ends and t.ends - now <= secs))
        t.emph = e and true or nil
        if e then
            ei = ei + 1
            Fill(emph.rows[ei], t)
        elseif mi < max then
            mi = mi + 1
            Fill(f.rows[mi], t)
        end
    end
    for i = mi + 1, BM.MAX_ROWS do Clear(f.rows[i]) end
    for i = ei + 1, BM.EMPH_ROWS do Clear(emph.rows[i]) end
    if mi > 0 or setupOn or f._unlock then f:Show() else f:Hide() end
    if ei > 0 or setupOn or emph._unlock then emph:Show() else emph:Hide() end
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

local handles = {}
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
    panel:SetSize(W, 420)
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
    bossIcon = true, bossFill = true, bossEmph = true, bossEmphSecs = true, bossWarnSize = true }

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
function BM.EncounterStart(id, name, difficulty)
    BM.stats.encounters = BM.stats.encounters + 1
    id, name, difficulty = Plain(id), Plain(name), Plain(difficulty)
    BM.fight = { id = id, name = type(name) == "string" and name or nil, diff = difficulty, start = Now() }
    if Opt("bossFight") then BM.Start("fight", BM.fight.name or "Bosskampf", nil, nil, "textMuted") end
    BM.Stop("pull")
end

function BM.EncounterEnd(id, name, difficulty, size, success)
    local f = BM.fight
    BM.fight = nil
    BM.Stop("fight")
    for k in pairs(timers) do if type(k) == "string" and k:find("^tl") then timers[k] = nil end end
    BM.Refresh()
    if not f then return nil end
    local secs = Now() - f.start
    local won = Plain(success)
    won = won == 1 or won == true
    if not Opt("bossFight") then return nil end
    local label = f.name or (type(Plain(name)) == "string" and Plain(name)) or "Boss"
    if not won then
        BM.Sound("Wipe")
        Say(label .. ": Wipe nach " .. BM.Format(secs) .. ".")
        return "wipe"
    end
    local text = label .. " besiegt in " .. BM.Format(secs)
    local times = BM.Times()
    local key = type(f.id) == "number" and (f.id .. ":" .. tostring(f.diff or 0)) or nil
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

--------------------------------------------------
-- Zeitleiste und Warnungen des Spiels
--------------------------------------------------

-- Die Zeitleiste meldet je Faehigkeit eine Tabelle; gelesen wird nur, was
-- offen ist. Name und Symbol gehen roh an Text und Bild (das darf geheim).
function BM.TimelineAdded(info)
    if type(info) ~= "table" then return nil end
    BM.stats.timeline = BM.stats.timeline + 1
    if not Opt("bossTimeline") then return nil end
    local id, dur = Plain(info.id), Plain(info.duration)
    if type(id) ~= "number" or type(dur) ~= "number" or dur <= 0 then
        BM.stats.secret = BM.stats.secret + 1
        return nil
    end
    local name = info.spellName
    if type(name) == "nil" then name = "Fähigkeit" end
    local t = BM.Start("tl" .. id, name, dur, info.iconFileID, "blue")
    t.soon = true
    return true
end

function BM.TimelineRemoved(id)
    id = Plain(id)
    if type(id) == "number" then BM.Stop("tl" .. id) end
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
        "ENCOUNTER_TIMELINE_EVENT_REMOVED", "ENCOUNTER_WARNING", "PLAYER_LOGIN", "PLAYER_REGEN_DISABLED" }) do
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
        BM.TimelineAdded(a1)
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
    return string.format("Bosskämpfe: %d Kämpfe, %d Fähigkeiten aus der Zeitleiste (%d ohne offene Dauer), %d Warnungen, %d Countdowns, %d Timer anderer Bossmods",
        s.encounters, s.timeline, s.secret, s.warnings, s.countdowns, s.heard)
end

--------------------------------------------------
-- Einstellungen
--------------------------------------------------

local function BuildPage(B)
    local function off(k) return function() return not K.Get(KEY, k) end end
    local FA = WeintCodex.UIFireAlarm
    local items = FA and FA.Items(true) or { { value = "none", text = "Kein Ton" } }
    local soundOff = off("bossSound")
    -- Eine Auswahl spielt den Ton einmal vor - so hoert man, was man waehlt.
    local function Sound(event, label, description)
        local key = "bossSnd" .. event
        return { type = "dropdown", label = label, key = key, items = items, disabled = soundOff,
                 tooltip = description,
                 set = function(v)
                     K.Set(KEY, key, v)
                     if v ~= "none" and FA then FA.PlayKey(v, K.Get(KEY, "bossChannel") or "Master") end
                 end }
    end
    B:Section("Töne", "Für jeden Anlass ein eigener Ton – oder „Kein Ton“. Eine Auswahl spielt ihn einmal vor; dabei sind auch die Memes und deine eigenen Töne aus der Companion. Ein langer Ton wird nicht vom nächsten unterbrochen.")
    B:Row({ type = "toggle", label = "Töne bei Bosskämpfen", key = "bossSound",
            description = "Schaltet alle Töne dieser Seite auf einmal." },
          { type = "dropdown", label = "Wo", key = "bossWhere", disabled = soundOff, items = {
                { value = "all",      text = "Überall" },
                { value = "group",    text = "Nur in einer Gruppe" },
                { value = "instance", text = "Nur in Dungeons und Schlachtzügen" } } })
    B:Row({ type = "button", label = "Probe", text = "Probekampf abspielen", onClick = BM.Demo,
            tooltip = "Pull, Fähigkeit mit Vorwarnung, Warnung und Sieg – mit deinen Tönen, in gut 14 Sekunden. Nur bei dir." },
          { type = "button", label = "Leisten", text = "Leisten einstellen",
            onClick = function() BM.Setup(true) end,
            tooltip = "Testleisten laufen, du ziehst sie an ihren Platz und stellst Größe, Schrift und Richtung direkt daneben ein – wie bei BigWigs und DBM." })
    B:Section("Pull und Pause", "/pull 10 startet den Countdown des Spiels – die ganze Gruppe sieht ihn, auch ohne WeintCodex. /break 5 ist eine Pause von fünf Minuten, nur für dich. 0 bricht ab. Haben BigWigs oder DBM die Befehle schon, heißen sie /wcpull und /wcbreak.")
    B:Row({ type = "toggle", label = "Pull- und Pausenleiste", key = "bossPull" },
          { type = "toggle", label = "Timer von BigWigs und DBM zeigen", key = "bossListen", disabled = off("bossPull"),
            description = "Startet jemand mit diesen Addons einen Pull oder eine Pause, erscheint die Leiste auch bei dir. WeintCodex hört nur zu." })
    B:Row(Sound("Pull", "Ton, wenn der Pull endet"), Sound("Break", "Ton, wenn die Pause endet"))
    B:Section("Kampf", "Wie lange der Bosskampf läuft, und am Ende „besiegt in 3:12“ mit deiner Bestzeit für diesen Boss – oder „Wipe nach …“.")
    B:Row({ type = "toggle", label = "Kampftimer und Bestzeit", key = "bossFight" },
          Sound("Kill", "Ton, wenn der Boss fällt"))
    B:Section("Was das Spiel meldet", "Fähigkeiten des Bosses als Leisten und Warnungen, so wie das Spiel sie ankündigt. Eigene Taktiken gibt es nicht – für Forever kennt sie niemand. Ob Forever das in jedem Kampf schickt, zeigt /wcui prüfen.")
    B:Row({ type = "toggle", label = "Fähigkeiten als Leisten", key = "bossTimeline" },
          Sound("Soon", "Ton kurz vor einer Fähigkeit", "Wenn die Leiste einer Fähigkeit fast abgelaufen ist – wie früh, steht unten in den Feineinstellungen."))
    B:Row({ type = "toggle", label = "Warnungen groß in der Mitte", key = "bossWarnings",
            description = "Das Spiel zeigt eigene Warnungen; das hier ist eine zweite, größere Anzeige." },
          Sound("Warn", "Ton bei einer Warnung des Spiels", "Kommt auch ohne die große Anzeige. Das Spiel hat oft schon einen eigenen Ton dafür."))
    B:Advanced()
    B:Row({ type = "dropdown", label = "Vorwarnung vor einer Fähigkeit", key = "bossSoonSecs", disabled = soundOff, items = {
                { value = 2, text = "2 Sekunden vorher" },
                { value = 3, text = "3 Sekunden vorher" },
                { value = 5, text = "5 Sekunden vorher" } } },
          Sound("Wipe", "Ton bei einem Wipe"))
    B:Row({ type = "dropdown", label = "Lautstärke über", key = "bossChannel", disabled = soundOff, items = {
                { value = "Master", text = "Gesamtlautstärke" },
                { value = "SFX",    text = "Effekte" },
                { value = "Dialog", text = "Dialog" } },
            tooltip = "Welcher Regler in den Toneinstellungen des Spiels diese Töne lauter oder leiser macht. Gesamtlautstärke hört man auch, wenn Effekte stumm sind." },
          { type = "empty" })
    B:EndAdvanced()
end
BM.BuildPage = BuildPage

local mod = K.Module(KEY)
if mod then
    for k, v in pairs(BM.DEFAULTS) do
        if mod.defaults[k] == nil then mod.defaults[k] = v end
    end
    mod.pages[#mod.pages + 1] = { key = "boss", label = "Bosskämpfe", build = BuildPage }
    if type(mod.pageOrder) == "table" then mod.pageOrder.boss = 16 end
end
