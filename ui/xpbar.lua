--------------------------------------------------
-- WeintCodex :: Oberflaeche - Erfahrungsbalken
--------------------------------------------------
-- Ein eigener Balken fuer Erfahrung im Stil der Oberflaeche (Kachel,
-- Balken aus UIKit.NewBar), statt der goldenen Leiste des Spiels unter
-- den Aktionsleisten (Beta-Test: "der EP-Balken muss nach dem neuen Stil
-- sein, auch nur bei Maus darueber").
--
-- Was er zeigt:
--   * Erfahrung, dahinter blass die erholte Erfahrung (wie weit sie
--     reicht).
--   * Auf Hoechststufe (oder mit gesperrter Erfahrung) den beobachteten
--     Ruf, sonst nichts - ein leerer Balken waere ein gemessenes Nichts.
--   * Unter der Maus: Stufe, Werte, was fehlt, erholt, und aus dieser
--     Sitzung Erfahrung je Stunde samt Schaetzung bis zur naechsten Stufe.
--     Geschaetzt wird nur, wenn in dieser Sitzung Erfahrung dazukam; die
--     Zahl heisst dann auch so ("bei diesem Tempo").
--
-- Die Leiste des Spiels wird nur unsichtbar (Deckkraft 0, keine Maus),
-- nicht versteckt oder umgehaengt: sie gehoert zum Bearbeitungsmodus, und
-- dessen Anordnung der unteren Leisten ist im Kampf geschuetzt (6.3.0.5:
-- ADDON_ACTION_BLOCKED, als WeintCodex dort Rahmen verschob).
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIXPBar = {}

local XB = WeintCodex.UIXPBar
local K  = WeintCodex.UIKit
local C  = WeintCodex.Colors
local KEY = "actionbars"   -- siehe unten: Reiter der Aktionsleisten
local MOVER = "xpbar"

-- Die Einstellungen gehoeren zum Modul "Aktionsleisten" (Reiter
-- "Erfahrung"): ein eigener Eintrag haette die Seitenleiste des
-- Einstellungsfensters ueberfuellt, und die Leiste des Spiels, die er
-- ersetzt, gehoert ebenfalls zu den unteren Leisten.
local defaults = {
    xpEnabled    = true,
    xpWidth      = 520,
    xpHeight     = 10,
    xpShow       = "always",  -- always | mouseover
    xpText       = "hover",   -- hover | always | never
    xpRested     = true,
    xpReputation = true,
    xpHideGame   = true,
}
XB.DEFAULTS = defaults

local function Opt(k) return K.Get(KEY, "xp" .. k:sub(1, 1):upper() .. k:sub(2)) end

local frame
local session = { start = nil, gained = 0, lastXP = nil, lastMax = nil }

--------------------------------------------------
-- Werte
--------------------------------------------------

local function Num(v)
    v = K.Plain(v)
    return type(v) == "number" and v or nil
end

local function MaxLevel()
    local lvl
    if _G.GetMaxLevelForPlayerExpansion then lvl = Num(_G.GetMaxLevelForPlayerExpansion()) end
    if not lvl and _G.GetMaxPlayerLevel then lvl = Num(_G.GetMaxPlayerLevel()) end
    return lvl
end

-- Erfahrung: { cur, max, rested, level } oder nil, wenn es keine gibt
-- (Hoechststufe, gesperrt) oder der Client sie nicht nennt.
function XB.Experience()
    local level = _G.UnitLevel and Num(_G.UnitLevel("player"))
    local top = MaxLevel()
    if level and top and level >= top then return nil end
    if _G.IsXPUserDisabled and K.Bool(_G.IsXPUserDisabled(), false) then return nil end
    local cur = _G.UnitXP and Num(_G.UnitXP("player"))
    local max = _G.UnitXPMax and Num(_G.UnitXPMax("player"))
    if not cur or not max or max <= 0 then return nil end
    local rested = _G.GetXPExhaustion and Num(_G.GetXPExhaustion()) or nil
    return { cur = cur, max = max, rested = rested, level = level }
end

-- Beobachteter Ruf: { name, cur, max, reaction } oder nil.
function XB.Reputation()
    local ok, r = pcall(function()
        if _G.C_Reputation and _G.C_Reputation.GetWatchedFactionData then
            local d = _G.C_Reputation.GetWatchedFactionData()
            if type(d) ~= "table" or type(d.name) ~= "string" then return nil end
            local lo, hi, val = Num(d.currentReactionThreshold), Num(d.nextReactionThreshold), Num(d.currentStanding)
            if not lo or not hi or not val or hi <= lo then return nil end
            return { name = d.name, cur = val - lo, max = hi - lo, reaction = Num(d.reaction) }
        end
        if _G.GetWatchedFactionInfo then
            local name, reaction, lo, hi, val = _G.GetWatchedFactionInfo()
            lo, hi, val = Num(lo), Num(hi), Num(val)
            if type(name) ~= "string" or not lo or not hi or not val or hi <= lo then return nil end
            return { name = name, cur = val - lo, max = hi - lo, reaction = Num(reaction) }
        end
        return nil
    end)
    return ok and r or nil
end

local function Pct(cur, max) return math.floor(cur / max * 1000 + 0.5) / 10 end

-- Was der Balken gerade zeigt: "xp", "rep" oder nil.
function XB.Mode()
    if XB.Experience() then return "xp" end
    if Opt("reputation") and XB.Reputation() then return "rep" end
    return nil
end

-- Sitzung: Erfahrung, die seit dem Einloggen dazukam. Ein Stufenaufstieg
-- zaehlt den Rest der alten Stufe mit.
function XB.Track()
    local xp = XB.Experience()
    local now = _G.GetTime and Num(_G.GetTime()) or nil
    if not xp or not now then return end
    if not session.start then session.start = now end
    if session.lastXP then
        if xp.cur >= session.lastXP then
            session.gained = session.gained + (xp.cur - session.lastXP)
        elseif session.lastMax then
            session.gained = session.gained + (session.lastMax - session.lastXP) + xp.cur
        end
    end
    session.lastXP, session.lastMax = xp.cur, xp.max
end

-- Erfahrung je Stunde und Sekunden bis zur naechsten Stufe - oder nil,
-- solange nichts dazukam oder die Sitzung zu kurz ist, um zu rechnen.
function XB.Rate()
    local now = _G.GetTime and Num(_G.GetTime()) or nil
    if not session.start or not now or session.gained <= 0 then return nil end
    local secs = now - session.start
    if secs < 60 then return nil end
    local perHour = session.gained / secs * 3600
    local xp = XB.Experience()
    local eta = xp and perHour > 0 and (xp.max - xp.cur) / perHour * 3600 or nil
    return perHour, eta
end
XB._session = session

--------------------------------------------------
-- Zeichnen
--------------------------------------------------

local function Short(v) return WeintCodex.FormatGrouped(v) end

function XB.Label()
    local mode = XB.Mode()
    if mode == "xp" then
        local xp = XB.Experience()
        local s = string.format("%s / %s  ·  %s %%", Short(xp.cur), Short(xp.max),
            (tostring(Pct(xp.cur, xp.max)):gsub("%.", ",")))
        if Opt("rested") and xp.rested and xp.rested > 0 then
            s = s .. "  ·  erholt " .. (tostring(Pct(math.min(xp.rested, xp.max * 1.5), xp.max)):gsub("%.", ",")) .. " %"
        end
        return s
    elseif mode == "rep" then
        local r = XB.Reputation()
        return string.format("%s  ·  %s / %s", r.name, Short(r.cur), Short(r.max))
    end
    return nil
end

local function RepColor(reaction)
    local fc = _G.FACTION_BAR_COLORS
    local c = type(fc) == "table" and reaction and fc[reaction]
    if type(c) == "table" and type(c.r) == "number" then return c.r, c.g, c.b end
    local f = WeintCodex.GameColors.friendly
    return f[1], f[2], f[3]
end

local function TextShown()
    local mode = Opt("text")
    if mode == "always" then return true end
    if mode == "hover" then return frame and frame._over end
    return false
end

function XB.Update()
    if not frame then return end
    local mode = XB.Mode()
    frame:SetShown(mode ~= nil or frame._unlock)
    if not mode then return end
    local GC = WeintCodex.GameColors
    if mode == "xp" then
        local xp = XB.Experience()
        frame.bar:SetMinMaxValues(0, xp.max)
        frame.bar:SetValue(xp.cur)
        local c = GC.xpBar
        K.PaintBar(frame.bar, c[1], c[2], c[3])
        local rest = Opt("rested") and xp.rested or 0
        frame.rest:SetMinMaxValues(0, xp.max)
        frame.rest:SetValue(math.min(xp.max, xp.cur + (rest or 0)))
        local rc = GC.xpRested
        frame.rest:SetStatusBarColor(rc[1], rc[2], rc[3], rc[4])
        frame.rest:SetShown((rest or 0) > 0)
    else
        local r = XB.Reputation()
        frame.bar:SetMinMaxValues(0, r.max)
        frame.bar:SetValue(r.cur)
        K.PaintBar(frame.bar, RepColor(r.reaction))
        frame.rest:Hide()
    end
    frame.text:SetText(XB.Label() or "")
    frame.text:SetShown(TextShown() and true or false)
end

--------------------------------------------------
-- Nur bei Maus darueber
--------------------------------------------------

local fadeAlpha = 1
local fader = CreateFrame("Frame")

local function Over()
    if not frame then return false end
    local ok, v = pcall(frame.IsMouseOver, frame, 6, -6, -6, 6)
    return ok and K.Bool(v, false) or false
end

-- Laeuft nur, solange "nur bei Maus darueber" gilt.
local function FadeStep(_, elapsed)
    if not frame then return end
    local target = (Over() or frame._unlock) and 1 or 0
    local step = (elapsed or 0.1) * 6
    if fadeAlpha < target then fadeAlpha = math.min(target, fadeAlpha + step)
    elseif fadeAlpha > target then fadeAlpha = math.max(target, fadeAlpha - step) end
    frame:SetAlpha(fadeAlpha)
end
XB._fadeStep = FadeStep

--------------------------------------------------
-- Tooltip
--------------------------------------------------

local function ShowTooltip(self)
    local GT = _G.GameTooltip
    if not GT then return end
    GT:SetOwner(self, "ANCHOR_TOP")
    local mode = XB.Mode()
    if mode == "xp" then
        local xp = XB.Experience()
        GT:SetText(xp.level and ("Stufe " .. xp.level) or "Erfahrung", 1, 1, 1)
        GT:AddDoubleLine("Erfahrung", Short(xp.cur) .. " / " .. Short(xp.max), 0.7, 0.7, 0.75, 1, 1, 1)
        GT:AddDoubleLine("Bis zur nächsten Stufe", Short(xp.max - xp.cur), 0.7, 0.7, 0.75, 1, 1, 1)
        if xp.rested and xp.rested > 0 then
            GT:AddDoubleLine("Erholt", Short(xp.rested), 0.7, 0.7, 0.75, 1, 1, 1)
        end
        local perHour, eta = XB.Rate()
        if perHour then
            GT:AddLine(" ")
            GT:AddDoubleLine("Diese Sitzung", Short(session.gained) .. " EP", 0.7, 0.7, 0.75, 1, 1, 1)
            GT:AddDoubleLine("Je Stunde", Short(perHour), 0.7, 0.7, 0.75, 1, 1, 1)
            if eta then
                GT:AddDoubleLine("Nächste Stufe, bei diesem Tempo", "~" .. WeintCodex.FormatClock(eta), 0.7, 0.7, 0.75, 1, 1, 1)
            end
        end
    elseif mode == "rep" then
        local r = XB.Reputation()
        GT:SetText(r.name, 1, 1, 1)
        GT:AddDoubleLine("Ruf", Short(r.cur) .. " / " .. Short(r.max), 0.7, 0.7, 0.75, 1, 1, 1)
    end
    GT:Show()
end

--------------------------------------------------
-- Die Leiste des Spiels
--------------------------------------------------

local GAME_BARS = { "MainStatusTrackingBarContainer", "SecondaryStatusTrackingBarContainer",
                    "StatusTrackingBarManager", "MainMenuExpBar", "ReputationWatchBar" }

function XB.HideGameBars()
    local AB = WeintCodex.UIActionBars
    for _, n in ipairs(GAME_BARS) do
        local f = _G[n]
        if type(f) == "table" and f.SetAlpha and not (f.IsForbidden and f:IsForbidden()) then
            if AB and AB.KeepHidden then AB.KeepHidden(f) else f:SetAlpha(0) end
            -- Unsichtbar, aber sonst noch unter der Maus (Tooltip des
            -- Spiels ueber unserem Balken).
            if f.EnableMouse then pcall(f.EnableMouse, f, false) end
            local ok, kids = pcall(function() return { f:GetChildren() } end)
            for _, ch in ipairs(ok and kids or {}) do
                if type(ch) == "table" and ch.EnableMouse and not (ch.IsForbidden and ch:IsForbidden()) then
                    pcall(ch.EnableMouse, ch, false)
                end
            end
        end
    end
end

--------------------------------------------------
-- Aufbau
--------------------------------------------------

local function Build()
    frame = CreateFrame("Frame", "WeintCodexXPBar", UIParent)
    frame:SetFrameStrata("MEDIUM")
    frame.kachel = K.Kachel(frame, { shadow = 5 })
    frame.rest = K.NewBar(frame, true)
    frame.rest:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
    frame.rest:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
    frame.bar = K.NewBar(frame)
    frame.bar:SetAllPoints(frame.rest)
    frame.bar:SetFrameLevel((frame.rest:GetFrameLevel() or 1) + 1)
    frame.text = K.NewText(frame.bar, 10, "OVERLAY")
    frame.text:SetPoint("CENTER", frame, "CENTER", 0, 0)
    frame:EnableMouse(true)
    frame:SetScript("OnEnter", function(self) self._over = true XB.Update() ShowTooltip(self) end)
    frame:SetScript("OnLeave", function(self) self._over = false XB.Update() if _G.GameTooltip then _G.GameTooltip:Hide() end end)
    frame.WCShowForUnlock = function(self, on)
        self._unlock = on and true or nil
        XB.Update()
    end
end

function XB.Apply()
    if not frame then return end
    frame:SetSize(Opt("width") or defaults.xpWidth, Opt("height") or defaults.xpHeight)
    -- Ab 12 px Hoehe passt eine 10-px-Schrift in den Balken; darunter
    -- steht der Text ueber ihm.
    frame.text:ClearAllPoints()
    if (Opt("height") or defaults.xpHeight) >= 12 then
        frame.text:SetPoint("CENTER", frame, "CENTER", 0, 0)
    else
        frame.text:SetPoint("BOTTOM", frame, "TOP", 0, 3)
    end
    if Opt("hideGame") then XB.HideGameBars() end
    if Opt("show") == "mouseover" then
        fader:SetScript("OnUpdate", FadeStep)
    else
        fader:SetScript("OnUpdate", nil)
        fadeAlpha = 1
        frame:SetAlpha(1)
    end
    XB.Update()
end

function XB.Enable()
    if frame or not Opt("enabled") then return end
    Build()
    K.RegisterMover(frame, MOVER, "Erfahrung", K.Layout(MOVER))
    local ev = CreateFrame("Frame")
    for _, e in ipairs({ "PLAYER_ENTERING_WORLD", "PLAYER_XP_UPDATE", "PLAYER_LEVEL_UP", "UPDATE_EXHAUSTION",
                         "UPDATE_FACTION", "DISABLE_XP_GAIN", "ENABLE_XP_GAIN" }) do
        pcall(ev.RegisterEvent, ev, e)
    end
    ev:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_ENTERING_WORLD" and Opt("hideGame") then XB.HideGameBars() end
        XB.Track()
        XB.Update()
    end)
    XB.Track()
    XB.Apply()
end

XB.Frame = function() return frame end

local function px(v) return string.format("%d px", v) end

function XB.BuildPage(B)
    local function off() return not K.Get(KEY, "xpEnabled") end
    B:Section("Balken", "Ein schmaler Erfahrungsbalken im Stil der Oberfläche statt der Leiste des Spiels.")
    B:Row({ type = "toggle", label = "Eigener Erfahrungsbalken", key = "xpEnabled", reload = true },
          { type = "toggle", label = "Leiste des Spiels ausblenden", key = "xpHideGame", reload = true, disabled = off })
    B:Row({ type = "slider", label = "Breite", key = "xpWidth", min = 200, max = 1400, step = 10, format = px, disabled = off },
          { type = "slider", label = "Höhe", key = "xpHeight", min = 4, max = 24, step = 1, format = px, disabled = off })
    B:Row({ type = "dropdown", label = "Sichtbar", key = "xpShow", disabled = off, items = {
                { value = "always", text = "Immer" },
                { value = "mouseover", text = "Nur bei Maus darüber" } } },
          { type = "dropdown", label = "Zahlen", key = "xpText", disabled = off, items = {
                { value = "hover", text = "Bei Maus darüber" },
                { value = "always", text = "Immer" },
                { value = "never", text = "Nie" } } })
    B:Section("Inhalt")
    B:Row({ type = "toggle", label = "Erholte Erfahrung zeigen", key = "xpRested", disabled = off },
          { type = "toggle", label = "Ruf auf Höchststufe", key = "xpReputation", disabled = off,
            description = "Zeigt den beobachteten Ruf, sobald es keine Erfahrung mehr gibt. Ohne beobachteten Ruf verschwindet der Balken." })
    B:Note("Die Maus über dem Balken zeigt Werte, erholte Erfahrung und – sobald in dieser Sitzung Erfahrung dazukam – das Tempo je Stunde samt Schätzung bis zur nächsten Stufe. Verschieben im Gestaltungsmodus.")
end

-- An das Modul "Aktionsleisten" haengen (es laedt vorher, siehe .toc):
-- Standardwerte, Reiter, Einschalten und Einstellungen.
do
    local m = K.Module(KEY)
    if m then
        for k, v in pairs(defaults) do m.defaults[k] = v end
        m.pages[#m.pages + 1] = { key = "erfahrung", label = "Erfahrung", build = XB.BuildPage }
        local enable, onSetting = m.Enable, m.OnSetting
        m.Enable = function(...)
            if enable then enable(...) end
            local ok, err = pcall(XB.Enable)
            if not ok then K.Report("erfahrung", err) end
        end
        m.OnSetting = function(key, ...)
            if type(key) == "string" and key:sub(1, 2) == "xp" then
                XB.Apply()
                return
            end
            if onSetting then onSetting(key, ...) end
            if key == "*" then XB.Apply() end
        end
    end
end
