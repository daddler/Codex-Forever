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
--     gross in der Mitte (ENCOUNTER_WARNING), auf Wunsch mit Ton.
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
    bossSound    = true,    -- Ton bei Warnung und Pull-Ende
}

BM.ROWS = 8
BM.W, BM.ROW_H = 240, 20
BM.stats = { timeline = 0, secret = 0, warnings = 0, encounters = 0, countdowns = 0, heard = 0 }

local function Plain(v) return K.Plain(v) end
local function Now() return (_G.GetTime and Plain(_G.GetTime())) or 0 end
local function Opt(k) return K.IsActive(KEY) and K.Get(KEY, k) and true or false end
BM.Opt = Opt

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

local frame
local function Build()
    if frame then return frame end
    frame = CreateFrame("Frame", "WeintCodexBossBars", UIParent)
    frame:SetSize(BM.W, BM.ROWS * (BM.ROW_H + 3))
    frame:SetFrameStrata("MEDIUM")
    frame.rows = {}
    for i = 1, BM.ROWS do
        local r = CreateFrame("Frame", nil, frame)
        r:SetSize(BM.W, BM.ROW_H)
        r:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -(i - 1) * (BM.ROW_H + 3))
        r.icon = r:CreateTexture(nil, "ARTWORK")
        r.icon:SetSize(BM.ROW_H, BM.ROW_H)
        r.icon:SetPoint("LEFT", r, "LEFT", 0, 0)
        r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        r.bar = K.NewBar(r)
        r.bar:SetPoint("TOPLEFT", r.icon, "TOPRIGHT", 3, 0)
        r.bar:SetPoint("BOTTOMRIGHT", r, "BOTTOMRIGHT", 0, 0)
        r.bar:SetMinMaxValues(0, 1)
        r.bg = r.bar:CreateTexture(nil, "BACKGROUND")
        r.bg:SetAllPoints(r.bar)
        local bg = C.surface2 or { 0.1, 0.1, 0.1, 1 }
        r.bg:SetColorTexture(bg[1], bg[2], bg[3], 0.8)
        r.label = K.NewText(r.bar, 11, "OVERLAY")
        r.label:SetPoint("LEFT", r.bar, "LEFT", 5, 0)
        r.label:SetPoint("RIGHT", r.bar, "RIGHT", -40, 0)
        r.label:SetJustifyH("LEFT")
        r.label:SetWordWrap(false)
        r.time = K.NewText(r.bar, 11, "OVERLAY")
        r.time:SetPoint("RIGHT", r.bar, "RIGHT", -5, 0)
        r:Hide()
        frame.rows[i] = r
    end
    -- Grosse Warnung in der Mitte (eigener Platz, verschiebbar).
    local warn = CreateFrame("Frame", "WeintCodexBossWarning", UIParent)
    warn:SetSize(600, 40)
    warn.text = K.NewText(warn, 24, "OVERLAY")
    warn.text:SetAllPoints(warn)
    warn:Hide()
    frame.warn = warn
    frame._acc = 0
    frame:SetScript("OnUpdate", function(self, el)
        self._acc = self._acc + (el or 0)
        if self._acc < 0.1 then return end
        self._acc = 0
        BM.Tick()
    end)
    frame.WCShowForUnlock = function(self, on)
        self._unlock = on and true or nil
        if on then
            BM.Start("demo1", "Pull", 8, nil, "accent")
            BM.Start("demo2", "Fähigkeit des Bosses", 22, 136116, "blue")
        else
            timers.demo1, timers.demo2 = nil, nil
        end
        BM.Refresh()
    end
    warn.WCShowForUnlock = function(self, on)
        self._unlock = on and true or nil
        if on then self.text:SetText("Warnung des Spiels") self:Show() else self:Hide() end
    end
    K.RegisterMover(frame, "bossbars", "Bosskämpfe: Leisten", K.Layout("bossbars"))
    K.RegisterMover(warn, "bosswarn", "Bosskämpfe: Warnung", K.Layout("bosswarn"))
    frame:Hide()
    BM.frame = frame
    return frame
end
BM.Build = Build

local function ColorOf(name)
    local c = C[name or "accent"] or C.accent
    return c[1], c[2], c[3]
end

function BM.Tick()
    local now = Now()
    local list = BM.Sorted()
    local f = frame
    local done
    for i = 1, BM.ROWS do
        local r = f.rows[i]
        local t = list[i]
        if t then
            if t.ends then
                local left = t.ends - now
                if left <= 0 then
                    done = done or t
                    r.bar:SetValue(0)
                    r.time:SetText("0")
                else
                    local total = t.ends - t.start
                    r.bar:SetValue(total > 0 and left / total or 0)
                    r.time:SetText(BM.Format(left))
                end
            else
                r.bar:SetValue(1)
                r.time:SetText(BM.Format(now - t.start))
            end
        end
    end
    if done then
        timers[done.key] = nil
        if done.onEnd then done.onEnd() end
        BM.Refresh()
    end
end

function BM.Refresh()
    local f = Build()
    local list = BM.Sorted()
    for i = 1, BM.ROWS do
        local r = f.rows[i]
        local t = list[i]
        if t then
            r.label:SetText(t.label)
            if t.icon then r.icon:SetTexture(t.icon) r.icon:Show() else r.icon:Hide() end
            r.bar:SetStatusBarColor(ColorOf(t.color))
            r:Show()
        else
            r:Hide()
        end
    end
    if #list > 0 then f:Show() BM.Tick() elseif not f._unlock then f:Hide() end
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
    w.until_ = Now() + 4
    if not w.hider then
        w.hider = true
        w:SetScript("OnUpdate", function(self)
            if not self._unlock and Now() > (self.until_ or 0) then self:Hide() end
        end)
    end
    if Opt("bossSound") and _G.PlaySound and _G.SOUNDKIT and _G.SOUNDKIT.RAID_WARNING then
        pcall(_G.PlaySound, _G.SOUNDKIT.RAID_WARNING, "Master")
    end
end

--------------------------------------------------
-- Pull und Pause
--------------------------------------------------

function BM.PullBar(secs, by)
    if not Opt("bossPull") then return end
    if not secs or secs <= 0 then BM.Stop("pull") return end
    local t = BM.Start("pull", by and ("Pull (" .. by .. ")") or "Pull", secs, nil, "accent")
    t.onEnd = function()
        if Opt("bossSound") and _G.PlaySound and _G.SOUNDKIT and _G.SOUNDKIT.READY_CHECK then
            pcall(_G.PlaySound, _G.SOUNDKIT.READY_CHECK, "Master")
        end
    end
end

function BM.BreakBar(secs, by)
    if not Opt("bossPull") then return end
    if not secs or secs <= 0 then BM.Stop("break") return end
    local t = BM.Start("break", by and ("Pause (" .. by .. ")") or "Pause", secs, nil, "blue")
    t.onEnd = function() Say("Die Pause ist vorbei.") end
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
    BM.Start("tl" .. id, name, dur, info.iconFileID, "blue")
    return true
end

function BM.TimelineRemoved(id)
    id = Plain(id)
    if type(id) == "number" then BM.Stop("tl" .. id) end
end

function BM.Warning(info)
    BM.stats.warnings = BM.stats.warnings + 1
    if not Opt("bossWarnings") or type(info) ~= "table" then return nil end
    local text = info.text
    if type(text) == "nil" then text = info.spellName end
    if type(text) == "nil" then return nil end
    BM.Warn(text, Plain(info.iconFileID))
    return true
end

--------------------------------------------------
-- Ereignisse
--------------------------------------------------

local ev = CreateFrame("Frame")
for _, e in ipairs({ "START_PLAYER_COUNTDOWN", "CANCEL_PLAYER_COUNTDOWN", "CHAT_MSG_ADDON",
        "ENCOUNTER_START", "ENCOUNTER_END", "ENCOUNTER_TIMELINE_EVENT_ADDED",
        "ENCOUNTER_TIMELINE_EVENT_REMOVED", "ENCOUNTER_WARNING", "PLAYER_LOGIN" }) do
    pcall(ev.RegisterEvent, ev, e)
end
ev:SetScript("OnEvent", function(_, event, a1, a2, a3, a4, a5)
    if event == "PLAYER_LOGIN" then
        local CI = _G.C_ChatInfo
        local reg = (CI and CI.RegisterAddonMessagePrefix) or _G.RegisterAddonMessagePrefix
        if reg then pcall(reg, "BigWigs") pcall(reg, "D5") end
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
    B:Section("Pull und Pause", "/pull 10 startet den Countdown des Spiels – die ganze Gruppe sieht ihn, auch ohne WeintCodex. /break 5 ist eine Pause von fünf Minuten, nur für dich. 0 bricht ab. Haben BigWigs oder DBM die Befehle schon, heißen sie /wcpull und /wcbreak.")
    B:Row({ type = "toggle", label = "Pull- und Pausenleiste", key = "bossPull" },
          { type = "toggle", label = "Timer von BigWigs und DBM zeigen", key = "bossListen", disabled = off("bossPull"),
            description = "Startet jemand mit diesen Addons einen Pull oder eine Pause, erscheint die Leiste auch bei dir. WeintCodex hört nur zu." })
    B:Section("Kampf", "Wie lange der Bosskampf läuft, und am Ende „besiegt in 3:12“ mit deiner Bestzeit für diesen Boss – oder „Wipe nach …“.")
    B:Row({ type = "toggle", label = "Kampftimer und Bestzeit", key = "bossFight" },
          { type = "empty" })
    B:Section("Was das Spiel meldet", "Fähigkeiten des Bosses als Leisten und Warnungen, so wie das Spiel sie ankündigt. Eigene Taktiken gibt es nicht – für Forever kennt sie niemand. Ob Forever das in jedem Kampf schickt, zeigt /wcui prüfen.")
    B:Row({ type = "toggle", label = "Fähigkeiten als Leisten", key = "bossTimeline" },
          { type = "toggle", label = "Warnungen groß in der Mitte", key = "bossWarnings",
            description = "Das Spiel zeigt eigene Warnungen; das hier ist eine zweite, größere Anzeige." })
    B:Row({ type = "toggle", label = "Mit Ton", key = "bossSound" },
          { type = "empty" })
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
