--------------------------------------------------
-- WeintCodex :: Herstellzeit - wie lange dauert das noch? (6.88.0.0)
--------------------------------------------------
-- Wunsch: "Wenn ich etwas laenger berufstechnisch mache, verhuetten oder
-- so, will ich sehen, wie lange das dauert."
--
-- WIEVIELE: der Auftrag an das Berufsfenster (C_TradeSkillUI.CraftRecipe
-- bzw. DoTradeSkill/DoCraft mit Anzahl), nachgehaengt per hooksecurefunc;
-- wo der Client es nennt, zaehlt C_TradeSkillUI.GetRecipeRepeatCount.
-- WIE LANGE: die Dauer des laufenden Zaubers aus UnitCastingInfo (vom
-- Client, nie geraten). Rest = laufender Zauber + (uebrig - 1) x Dauer.
-- ENDE: alle hergestellt, unterbrochen, gescheitert - oder nach
-- CT.GAP s ohne neuen Zauber.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UICraftTimer = {}

local CT = WeintCodex.UICraftTimer
local K  = WeintCodex.UIKit
local C  = WeintCodex.Colors
local KEY = "comfort"

CT.DEFAULTS = { craftTimer = true }
CT.W, CT.H = 260, 38
CT.GAP = 2.5          -- s ohne neuen Zauber: Auftrag vorbei

local frame
local job             -- { total, done, name, cast, castEnd, lastAt }
CT.state = function() return job end

function CT.Active()
    return K.IsActive(KEY) and K.Get(KEY, "craftTimer") ~= false
end

local function Now() return _G.GetTime and K.Plain(_G.GetTime()) or 0 end

function CT.Format(secs)
    secs = math.max(0, math.floor(secs + 0.5))
    if secs >= 3600 then
        return string.format("%d:%02d:%02d", math.floor(secs / 3600), math.floor(secs / 60) % 60, secs % 60)
    end
    return string.format("%d:%02d", math.floor(secs / 60), secs % 60)
end

-- Restzeit aus Anzahl und Dauer (rein, fuer den Prueflauf).
function CT.Remaining(total, done, cast, castLeft)
    if type(total) ~= "number" or type(cast) ~= "number" or cast <= 0 then return nil end
    local left = total - (done or 0)
    if left <= 0 then return 0 end
    return (castLeft or cast) + (left - 1) * cast
end

--------------------------------------------------
-- Anzeige
--------------------------------------------------

local function Build()
    if frame then return frame end
    frame = CreateFrame("Frame", "WeintCodexCraftTimer", UIParent)
    frame:SetSize(CT.W, CT.H)
    frame:SetFrameStrata("MEDIUM")
    frame.kachel = K.Kachel(frame, { shadow = 4 })
    frame.title = K.NewText(frame, 12, "OVERLAY")
    frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -6)
    frame.title:SetPoint("RIGHT", frame, "RIGHT", -86, 0)
    frame.title:SetJustifyH("LEFT")
    frame.title:SetWordWrap(false)
    frame.time = K.NewText(frame, 12, "OVERLAY")
    frame.time:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -6)
    frame.time:SetJustifyH("RIGHT")
    frame.bar = K.NewBar(frame)
    frame.bar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 8, 7)
    frame.bar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, 7)
    frame.bar:SetHeight(6)
    frame.bar:SetMinMaxValues(0, 1)
    local a = C.accent
    frame.bar:SetStatusBarColor(a[1], a[2], a[3], 1)
    frame.barBg = frame.bar:CreateTexture(nil, "BACKGROUND")
    frame.barBg:SetAllPoints(frame.bar)
    local s = C.surface1
    frame.barBg:SetColorTexture(s[1], s[2], s[3], 1)
    frame:Hide()
    frame.WCShowForUnlock = function(self, on)
        self._unlock = on and true or nil
        if on then
            CT.Fill("Kupferbarren · 8 von 20", "noch 0:36", 0.4)
            self:Show()
        elseif not job then
            self:Hide()
        else
            CT.Tick()
        end
    end
    frame:SetScript("OnUpdate", function(self, el)
        if self._unlock then return end
        self._acc = (self._acc or 0) + (el or 0)
        if self._acc < 0.25 then return end
        self._acc = 0
        CT.Tick()
    end)
    K.RegisterMover(frame, "crafttimer", "Herstellzeit", K.Layout("crafttimer"))
    CT.frame = frame
    return frame
end

function CT.Fill(title, time, part)
    frame.title:SetText(title)
    frame.time:SetText(time)
    frame.bar:SetValue(math.max(0, math.min(1, part or 0)))
end

function CT.Tick()
    if not frame or frame._unlock then return end
    if not job then frame:Hide() return end
    local now = Now()
    if job.done >= job.total or (job.lastAt and now - job.lastAt > CT.GAP and not job.casting) then
        CT.Stop()
        return
    end
    local castLeft = job.casting and job.castEnd and math.max(0, job.castEnd - now) or nil
    local rest = CT.Remaining(job.total, job.done, job.cast, castLeft)
    local title = (job.name or "Herstellen") .. " · " .. (job.done + 1) .. " von " .. job.total
    local part = (job.done + ((job.casting and job.cast and castLeft) and (1 - castLeft / job.cast) or 0)) / job.total
    CT.Fill(title, rest and ("noch " .. CT.Format(rest)) or "Dauer unbekannt", part)
    frame:Show()
end

function CT.Stop()
    job = nil
    if frame and not frame._unlock then frame:Hide() end
end

--------------------------------------------------
-- Ablauf
--------------------------------------------------

-- Auftrag mit Anzahl (nur ab 2 - ein einzelnes Stueck braucht keine Uhr).
function CT.Order(count)
    count = K.Plain(count)
    if type(count) ~= "number" or count < 2 or not CT.Active() then return end
    job = { total = count, done = 0, lastAt = Now() }
    Build()
end

local function CastInfo()
    if not _G.UnitCastingInfo then return nil end
    local ok, name, _, _, startMS, endMS = pcall(_G.UnitCastingInfo, "player")
    if not ok then return nil end
    name, startMS, endMS = K.Plain(name), K.Plain(startMS), K.Plain(endMS)
    if type(startMS) ~= "number" or type(endMS) ~= "number" then return nil end
    return type(name) == "string" and name or nil, (endMS - startMS) / 1000, endMS / 1000
end

function CT.OnStart(unit)
    if K.Plain(unit) ~= "player" or not job then return end
    local name, cast, castEnd = CastInfo()
    if not cast then return end
    -- Zaehlt der Client selbst mit, gilt seine Zahl.
    local tsu = _G.C_TradeSkillUI
    if tsu and tsu.GetRecipeRepeatCount then
        local ok, n = pcall(tsu.GetRecipeRepeatCount)
        n = ok and K.Plain(n) or nil
        if type(n) == "number" and n > 0 then job.total = job.done + n end
    end
    job.name = job.name or name
    job.cast, job.castEnd, job.casting, job.lastAt = cast, castEnd, true, Now()
    CT.Tick()
end

function CT.OnDone(unit)
    if K.Plain(unit) ~= "player" or not job or not job.casting then return end
    job.casting = false
    job.done = job.done + 1
    job.lastAt = Now()
    CT.Tick()
end

function CT.OnBreak(unit)
    if K.Plain(unit) ~= "player" or not job then return end
    CT.Stop()
end

local ev = CreateFrame("Frame")
CT.events = ev
for _, e in ipairs({ "PLAYER_LOGIN", "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_SUCCEEDED",
                     "UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_FAILED" }) do
    pcall(ev.RegisterEvent, ev, e)
end
local hooked = false
ev:SetScript("OnEvent", function(_, event, unit)
    if event == "PLAYER_LOGIN" then
        if not hooked and _G.hooksecurefunc then
            hooked = true
            local tsu = _G.C_TradeSkillUI
            if type(tsu) == "table" and type(tsu.CraftRecipe) == "function" then
                pcall(_G.hooksecurefunc, tsu, "CraftRecipe", function(_, n) CT.Order(n) end)
            end
            if type(_G.DoTradeSkill) == "function" then
                pcall(_G.hooksecurefunc, "DoTradeSkill", function(_, n) CT.Order(n) end)
            end
            if type(_G.DoCraft) == "function" then
                pcall(_G.hooksecurefunc, "DoCraft", function(_, n) CT.Order(n) end)
            end
        end
        if K.SetMoverEnabled then K.SetMoverEnabled("crafttimer", CT.Active()) end
    elseif event == "UNIT_SPELLCAST_START" then CT.OnStart(unit)
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then CT.OnDone(unit)
    else CT.OnBreak(unit) end
end)

--------------------------------------------------
-- Einstellungen: auf der Komfortseite "Sammeln"
--------------------------------------------------

local function BuildSection(B)
    B:Section("Herstellzeit", "Stellst du mehrere Stücke auf einmal her – Barren verhütten, Stoff, Tränke –, zeigt eine Leiste, wie viele noch fehlen und wie lange es dauert. Verschieben im Gestaltungsmodus.")
    B:Row({ type = "toggle", label = "Herstellzeit anzeigen", key = "craftTimer",
            description = "Die Dauer je Stück nennt das Spiel beim Herstellen – vorher steht nichts geraten da." },
          { type = "empty" })
end
CT.BuildSection = BuildSection

local mod = K.Module(KEY)
if mod then
    for k, v in pairs(CT.DEFAULTS) do
        if mod.defaults[k] == nil then mod.defaults[k] = v end
    end
    for _, page in ipairs(mod.pages) do
        if page.key == "sammeln" then
            local orig = page.build
            page.build = function(B, ...)
                if orig then orig(B, ...) end
                BuildSection(B)
            end
        end
    end
end

K.Listen(function(kind, key)
    if (kind == "active" or kind == "setting") and key == KEY then
        if K.SetMoverEnabled then K.SetMoverEnabled("crafttimer", CT.Active()) end
        if not CT.Active() then CT.Stop() end
    end
end)
