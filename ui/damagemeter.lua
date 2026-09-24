--------------------------------------------------
-- WeintCodex :: Oberflaeche - Schadensanzeige
--------------------------------------------------
-- Ein Fenster mit Balken: wer wie viel Schaden gemacht, geheilt, erlitten
-- hat, wer unterbrochen, gebannt hat, wer gestorben ist - fuer den
-- laufenden Kampf oder die ganze Sitzung.
--
-- DIE ZAHLEN ZAEHLT DAS SPIEL, NICHT WEINTCODEX. Ab Client 12.0 bekommen
-- Addons kein Kampflog mehr (COMBAT_LOG_EVENT_UNFILTERED); dafuer misst
-- das Spiel selbst und reicht die Ergebnisse ueber C_DamageMeter heraus.
-- Diese Anzeige ist ein anderes Gesicht fuer dieselben Zahlen, die auch
-- Blizzards eingebaute Anzeige zeigt - dieselbe Loesung wie in
-- EllesmereUI. Die eingebaute Anzeige wird dabei ausgeblendet
-- (Spieleinstellung damageMeterEnabled = 0); die Messung laeuft weiter.
--
-- Die Werte koennen im Kampf geheim sein: Balken und Text bekommen sie
-- durchgereicht (SetValue, AbbreviateNumbers, SetFormattedText), Lua
-- rechnet nie damit.
--
-- Gibt es C_DamageMeter nicht, steht das im Fenster - keine leeren
-- Balken, keine Nullen.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIDamageMeter = {}

local DM = WeintCodex.UIDamageMeter
local K  = WeintCodex.UIKit
local C  = WeintCodex.Colors
local F  = WeintCodex.Fonts
local KEY = "damagemeter"

local defaults = {
    width     = 240,
    bars      = 8,
    barHeight = 18,
    mode      = "DamageDone",
    session   = "Current",
    classColor = true,
    perSecond = true,
    hideBlizzard = true,
    bgAlpha   = 80,
}

local function Opt(k) return K.Get(KEY, k) end

-- Die Messarten, in der Reihenfolge des Umschaltens. Was der Client
-- nicht kennt (Enum fehlt), faellt heraus.
local MODES = {
    { key = "DamageDone",   label = "Schaden",          rate = true },
    { key = "HealingDone",  label = "Heilung",          rate = true },
    { key = "DamageTaken",  label = "Erlittener Schaden", rate = true },
    { key = "Interrupts",   label = "Unterbrechungen",  count = true },
    { key = "Dispels",      label = "Bannungen",        count = true },
    { key = "Deaths",       label = "Tode",             deaths = true },
}

local function Available()
    return _G.C_DamageMeter and _G.C_DamageMeter.GetCombatSessionFromType
        and _G.Enum and _G.Enum.DamageMeterType and _G.Enum.DamageMeterSessionType
        and true or false
end
DM.Available = Available

local function Modes()
    local out = {}
    local e = _G.Enum and _G.Enum.DamageMeterType
    for _, m in ipairs(MODES) do
        if not e or e[m.key] ~= nil then out[#out + 1] = m end
    end
    return out
end

local function ModeInfo(key)
    for _, m in ipairs(MODES) do if m.key == key then return m end end
    return MODES[1]
end

local win, header, modeBtn, sessionBtn, empty
local rows = {}

local function Row(i)
    local r = CreateFrame("Frame", nil, win)
    r.bar = CreateFrame("StatusBar", nil, r)
    r.bar:SetAllPoints(r)
    r.bar:SetStatusBarTexture(K.BAR_TEXTURE)
    r.bg = r:CreateTexture(nil, "BACKGROUND")
    r.bg:SetAllPoints(r)
    local s = C.surface2
    r.bg:SetColorTexture(s[1], s[2], s[3], 0.8)
    local host = CreateFrame("Frame", nil, r)
    host:SetAllPoints(r)
    host:SetFrameLevel((r.bar:GetFrameLevel() or 1) + 2)
    r.name = host:CreateFontString(nil, "OVERLAY")
    K.SetFont(r.name, 11)
    r.name:SetPoint("LEFT", r, "LEFT", 4, 0)
    r.name:SetJustifyH("LEFT")
    r.name:SetWordWrap(false)
    r.amount = host:CreateFontString(nil, "OVERLAY")
    K.SetFont(r.amount, 11)
    r.amount:SetPoint("RIGHT", r, "RIGHT", -4, 0)
    r.amount:SetJustifyH("RIGHT")
    r:Hide()
    return r
end

local function Layout()
    if not win then return end
    local w, n, h = Opt("width"), Opt("bars"), Opt("barHeight")
    win:SetSize(w, 26 + n * (h + 1) + 4)
    local bg = C.bgDark
    win.bg:SetColorTexture(bg[1], bg[2], bg[3], (Opt("bgAlpha") or 80) / 100)
    for i = 1, math.max(n, #rows) do
        local r = rows[i] or Row(i)
        rows[i] = r
        r:ClearAllPoints()
        r:SetPoint("TOPLEFT", win, "TOPLEFT", 2, -(26 + (i - 1) * (h + 1)))
        r:SetPoint("TOPRIGHT", win, "TOPRIGHT", -2, -(26 + (i - 1) * (h + 1)))
        r:SetHeight(h)
        K.SetFont(r.name, math.max(8, math.floor(h * 0.6)))
        K.SetFont(r.amount, math.max(8, math.floor(h * 0.6)))
        r.name:SetWidth(w * 0.55)
        if i > n then r:Hide() end
    end
    K.SetFont(modeBtn.text, 11)
    K.SetFont(sessionBtn.text, 10)
    K.SetFont(empty, 11)
    empty:SetWidth(w - 16)
end

local function Amount(fs, src, mode)
    local total = src.totalAmount
    if mode.deaths then fs:SetText("") return end
    if type(total) == "nil" then fs:SetText("") return end
    local abbr = _G.AbbreviateNumbers
    if mode.count or not Opt("perSecond") or type(src.amountPerSecond) == "nil" then
        if abbr then fs:SetText(abbr(total))
        elseif type(K.Plain(total)) == "number" then fs:SetText(tostring(total))
        else fs:SetText("") end
        return
    end
    if abbr then
        fs:SetFormattedText("%s (%s)", abbr(total), abbr(src.amountPerSecond))
    elseif type(K.Plain(total)) == "number" then
        fs:SetText(tostring(total))
    else
        fs:SetText("")
    end
end

function DM.Refresh()
    if not win or not win:IsShown() then return end
    local mode = ModeInfo(Opt("mode"))
    modeBtn.text:SetText(mode.label)
    sessionBtn.text:SetText(Opt("session") == "Overall" and "Gesamt" or "Aktuell")

    if not Available() then
        for _, r in ipairs(rows) do r:Hide() end
        empty:SetText("Die Schadensmessung des Spiels steht auf diesem Client nicht zur Verfügung.")
        empty:Show()
        return
    end

    local e = _G.Enum
    local st = e.DamageMeterSessionType[Opt("session")] or e.DamageMeterSessionType.Current
    local mt = e.DamageMeterType[mode.key]
    local ok, session = pcall(_G.C_DamageMeter.GetCombatSessionFromType, st, mt)
    local sources = ok and session and session.combatSources or nil

    local n = Opt("bars")
    local count = sources and math.min(#sources, n) or 0
    if count == 0 then
        for _, r in ipairs(rows) do r:Hide() end
        empty:SetText(ok and "Noch nichts gemessen." or "Die Messung hat nicht geantwortet.")
        empty:Show()
        return
    end
    empty:Hide()

    -- Die Liste kommt absteigend sortiert: der erste Eintrag ist der
    -- volle Balken (auch wenn Lua seinen Wert nicht sehen darf).
    local maxAmt = sources[1].totalAmount
    for i = 1, n do
        local r = rows[i]
        local src = sources[i]
        if r and src and i <= count then
            if mode.deaths or type(maxAmt) == "nil" then
                r.bar:SetMinMaxValues(0, 1)
                r.bar:SetValue(1)
            else
                r.bar:SetMinMaxValues(0, maxAmt)
                -- Kein `or 0`: ein Wahrheitstest auf einem geheimen Wert
                -- waere ein Fehler.
                local v = src.totalAmount
                if type(v) ~= "nil" then r.bar:SetValue(v) else r.bar:SetValue(0) end
            end
            local cr, cg, cb = C.info[1], C.info[2], C.info[3]
            local class = K.Plain(src.classFilename)
            if Opt("classColor") and class and _G.RAID_CLASS_COLORS and _G.RAID_CLASS_COLORS[class] then
                local cc = _G.RAID_CLASS_COLORS[class]
                cr, cg, cb = cc.r, cc.g, cc.b
            end
            K.PaintBar(r.bar, cr, cg, cb)
            if type(src.name) ~= "nil" then
                r.name:SetFormattedText("%d. %s", i, src.name)
            else
                r.name:SetFormattedText("%d.", i)
            end
            Amount(r.amount, src, mode)
            r:Show()
        elseif r then
            r:Hide()
        end
    end
end

-- Fuer den Prueflauf: wie viele Balken stehen, und was steht statt ihrer.
function DM.RowsShown()
    local n = 0
    for _, r in ipairs(rows or {}) do if r:IsShown() then n = n + 1 end end
    return n
end
function DM.EmptyText() return empty and empty:IsShown() and empty:GetText() or nil end

local function HeaderButton(parent, onClick)
    local b = CreateFrame("Button", nil, parent)
    b:SetHeight(20)
    b.text = b:CreateFontString(nil, "OVERLAY")
    -- Schrift VOR jedem Text: SetText ohne Schrift bricht im Client ab.
    -- Genau daran scheiterte in 6.0.0.3 der Aufbau des ganzen Fensters
    -- ("Leeren" bekam seinen Text vor seiner Schrift).
    K.SetFont(b.text, 11)
    b.text:SetPoint("LEFT", b, "LEFT", 0, 0)
    b.text:SetTextColor(unpack(C.textBright))
    if b.RegisterForClicks then b:RegisterForClicks("LeftButtonUp", "RightButtonUp") end
    b:SetScript("OnClick", onClick)
    return b
end

local function CycleMode(_, button)
    local list = Modes()
    local cur = Opt("mode")
    local idx = 1
    for i, m in ipairs(list) do if m.key == cur then idx = i end end
    idx = idx + ((button == "RightButton") and -1 or 1)
    if idx > #list then idx = 1 elseif idx < 1 then idx = #list end
    K.Set(KEY, "mode", list[idx].key)
    DM.Refresh()
end

local function Build()
    win = CreateFrame("Frame", "WeintCodexDamageMeter", UIParent)
    win:SetFrameStrata("MEDIUM")
    win:SetClampedToScreen(true)
    win.bg = win:CreateTexture(nil, "BACKGROUND")
    win.bg:SetAllPoints(win)
    WeintCodex.DrawBorder(win, C.border[1], C.border[2], C.border[3], 1, 1)

    header = CreateFrame("Frame", nil, win)
    header:SetPoint("TOPLEFT", win, "TOPLEFT", 6, -3)
    header:SetPoint("TOPRIGHT", win, "TOPRIGHT", -6, -3)
    header:SetHeight(20)

    modeBtn = HeaderButton(header, CycleMode)
    modeBtn:SetPoint("LEFT", header, "LEFT", 0, 0)
    modeBtn:SetWidth(140)
    modeBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Messart", 1, 1, 1)
        GameTooltip:AddLine("Linksklick: nächste, Rechtsklick: vorige.", 0.7, 0.7, 0.75, true)
        GameTooltip:Show()
    end)
    modeBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    sessionBtn = HeaderButton(header, function()
        K.Set(KEY, "session", Opt("session") == "Overall" and "Current" or "Overall")
        DM.Refresh()
    end)
    sessionBtn:SetWidth(60)
    sessionBtn.text:SetTextColor(unpack(C.textMuted))

    local reset = HeaderButton(header, function()
        local cdm = _G.C_DamageMeter
        if cdm and cdm.ResetAllCombatSessions then pcall(cdm.ResetAllCombatSessions) end
        DM.Refresh()
    end)
    reset:SetWidth(46)
    reset.text:SetText("Leeren")
    reset.text:SetTextColor(unpack(C.textMuted))
    reset:SetPoint("RIGHT", header, "RIGHT", 0, 0)
    sessionBtn:SetPoint("RIGHT", reset, "LEFT", -8, 0)
    K.SetFont(reset.text, 10)

    empty = win:CreateFontString(nil, "OVERLAY")
    K.SetFont(empty, 11)
    empty:SetPoint("TOPLEFT", win, "TOPLEFT", 8, -32)
    empty:SetJustifyH("LEFT")
    empty:SetTextColor(unpack(C.textDim))
    empty:Hide()

    win.WCShowForUnlock = function() end
    K.RegisterMover(win, "damagemeter", "Schadensanzeige",
        { point = "BOTTOMRIGHT", relPoint = "BOTTOMRIGHT", x = -20, y = 300 })
    Layout()
end

--------------------------------------------------
-- Takt und Ereignisse
--------------------------------------------------
-- Die Messung meldet sich mit eigenen Ereignissen; im Kampf wird
-- zusaetzlich zweimal je Sekunde gelesen, damit die Balken fliessen.

local ticker = CreateFrame("Frame")
local acc = 0
local function OnTick(_, el)
    acc = acc + (el or 0)
    if acc < 0.5 then return end
    acc = 0
    DM.Refresh()
end

local function Enable()
    Build()
    win:Show()
    if Opt("hideBlizzard") then
        local set = (_G.C_CVar and _G.C_CVar.SetCVar) or _G.SetCVar
        if set then pcall(set, "damageMeterEnabled", "0") end
    end
    local ev = CreateFrame("Frame")
    for _, e in ipairs({ "DAMAGE_METER_COMBAT_SESSION_UPDATED", "DAMAGE_METER_CURRENT_SESSION_UPDATED",
        "DAMAGE_METER_RESET", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "PLAYER_ENTERING_WORLD" }) do
        pcall(ev.RegisterEvent, ev, e)
    end
    ev:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_DISABLED" then
            ticker:SetScript("OnUpdate", OnTick)
        elseif event == "PLAYER_REGEN_ENABLED" then
            ticker:SetScript("OnUpdate", nil)
        end
        DM.Refresh()
    end)
    DM.Refresh()
end

local function px(v) return string.format("%d px", v) end

K.Register({
    key = KEY, group = "ui", order = 55,
    title = "Schadensanzeige",
    description = "Schaden, Heilung, erlittener Schaden, Unterbrechungen, Bannungen und Tode als Balken – gemessen vom Spiel selbst.",
    defaults = defaults,
    Enable = Enable,
    OnSetting = function() if win then Layout() DM.Refresh() end end,
    pages = {
        { key = "allgemein", label = "Allgemein", build = function(B)
            B:Section("Fenster")
            B:Row({ type = "slider", label = "Breite", key = "width", min = 160, max = 420, step = 2, format = px },
                  { type = "slider", label = "Balken", key = "bars", min = 3, max = 25, step = 1,
                    format = function(v) return tostring(v) end })
            B:Row({ type = "slider", label = "Balkenhöhe", key = "barHeight", min = 12, max = 30, step = 1, format = px },
                  { type = "slider", label = "Deckkraft des Hintergrunds", key = "bgAlpha", min = 0, max = 100, step = 5,
                    format = function(v) return string.format("%d %%", v) end })
            B:Section("Anzeige")
            B:Row({ type = "toggle", label = "Klassenfarben", key = "classColor" },
                  { type = "toggle", label = "Pro Sekunde in Klammern", key = "perSecond" })
            B:Row({ type = "toggle", label = "Anzeige des Spiels ausblenden", key = "hideBlizzard", reload = true,
                    description = "Die Messung läuft weiter – nur Blizzards Fenster geht aus." },
                  { type = "empty" })
            B:Section("Bedienung")
            B:Note("Klick auf die Messart schaltet weiter (Rechtsklick zurück), „Aktuell/Gesamt“ wechselt zwischen diesem Kampf und der ganzen Sitzung, „Leeren“ setzt alles zurück. Verschieben: „Rahmen entsperren“.")
            B:Note("Die Zahlen misst das Spiel selbst – Addons bekommen auf dem neuen Client kein Kampflog mehr. Sie stimmen deshalb mit Blizzards eigener Anzeige überein.")
        end },
    },
})
