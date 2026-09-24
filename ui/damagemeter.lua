--------------------------------------------------
-- WeintCodex :: Oberflaeche - Schadensanzeige
--------------------------------------------------
-- Bis zu vier Fenster mit Balken: wer wie viel Schaden gemacht, geheilt,
-- erlitten hat, wer unterbrochen, gebannt hat, wer gestorben ist - jedes
-- Fenster mit eigener Messart und eigenem Zeitraum (dieser Kampf oder
-- die ganze Sitzung). Das Plus in der Kopfzeile oeffnet ein weiteres,
-- das Kreuz schliesst es wieder.
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
-- ZAHLEN. AbbreviateNumbers ohne Einstellung gibt Werte unter 1000
-- ungerundet heraus - in 6.0.0.4 stand deshalb "387 (16.826086956522)"
-- im Fenster. Die Stufen (K, M, B, darunter ganze Zahlen) kommen jetzt
-- ueber CreateAbbreviateConfig; der Client rundet selbst, auch geheime
-- Werte.
--
-- Gibt es C_DamageMeter nicht, steht das im Fenster - keine leeren
-- Balken, keine Nullen.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIDamageMeter = {}

local DM = WeintCodex.UIDamageMeter
local K  = WeintCodex.UIKit
local C  = WeintCodex.Colors
local KEY = "damagemeter"
local MAX_WINDOWS = 4
local MEDIA = "Interface\\AddOns\\WeintCodex\\media\\ui\\"

local defaults = {
    windows   = 1,
    width     = 260,
    bars      = 8,
    barHeight = 18,
    classColor = true,
    numbers   = "both",    -- both | total | rate
    rank      = true,
    showTime  = true,
    hideBlizzard = true,
    bgAlpha   = 85,
    fitRows   = true,      -- Fenster so hoch wie die gezeigten Zeilen
    -- Je Fenster Messart und Zeitraum (flach gespeichert: UIKit.Set
    -- vergleicht Tabellen nur eine Ebene tief).
    w1mode = "DamageDone",  w1session = "Current",
    w2mode = "HealingDone", w2session = "Current",
    w3mode = "DamageTaken", w3session = "Current",
    w4mode = "Interrupts",  w4session = "Overall",
}

local function Opt(k) return K.Get(KEY, k) end
local function Count() return math.max(1, math.min(MAX_WINDOWS, Opt("windows") or 1)) end

-- Die Messarten, in der Reihenfolge des Umschaltens. Was der Client
-- nicht kennt (Enum fehlt), faellt heraus.
local MODES = {
    { key = "DamageDone",   label = "Schaden",            rate = true },
    { key = "HealingDone",  label = "Heilung",            rate = true },
    { key = "DamageTaken",  label = "Erlittener Schaden", rate = true },
    { key = "Interrupts",   label = "Unterbrechungen",    count = true },
    { key = "Dispels",      label = "Bannungen",          count = true },
    { key = "Deaths",       label = "Tode",               deaths = true },
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

--------------------------------------------------
-- Zahlen
--------------------------------------------------

local abbrevOpts
local function AbbrevOptions()
    if abbrevOpts ~= nil then return abbrevOpts or nil end
    abbrevOpts = false
    if _G.CreateAbbreviateConfig then
        local ok, cfg = pcall(_G.CreateAbbreviateConfig, {
            { breakpoint = 1000000000, abbreviation = "B", significandDivisor = 10000000, fractionDivisor = 100, abbreviationIsGlobal = false },
            { breakpoint = 1000000,    abbreviation = "M", significandDivisor = 10000,    fractionDivisor = 100, abbreviationIsGlobal = false },
            { breakpoint = 1000,       abbreviation = "K", significandDivisor = 100,      fractionDivisor = 10,  abbreviationIsGlobal = false },
            { breakpoint = 1,          abbreviation = "",  significandDivisor = 1,        fractionDivisor = 1,   abbreviationIsGlobal = false },
        })
        if ok and cfg then abbrevOpts = { config = cfg } end
    end
    return abbrevOpts or nil
end

-- Eine Zahl kurz. Offene Zahlen rechnet Lua selbst (dieselben Stufen),
-- geheime gehen an den Client.
function DM.Format(v)
    if type(v) == "nil" then return "" end
    local plain = K.Plain(v)
    if type(plain) == "number" then
        local a = math.abs(plain)
        local s
        if a >= 1e9 then s = string.format("%.2fB", plain / 1e9)
        elseif a >= 1e6 then s = string.format("%.2fM", plain / 1e6)
        elseif a >= 1e3 then s = string.format("%.1fK", plain / 1e3)
        else s = string.format("%d", math.floor(plain + 0.5)) end
        return (s:gsub("%.", ","))
    end
    local abbr = _G.AbbreviateNumbers
    if not abbr then return "" end
    local opts = AbbrevOptions()
    if opts then
        local ok, s = pcall(abbr, v, opts)
        if ok then return s end
    end
    return abbr(v)
end

local function Clock(secs)
    secs = math.floor(secs + 0.5)
    return string.format("%d:%02d", math.floor(secs / 60), secs % 60)
end

--------------------------------------------------
-- Ein Fenster
--------------------------------------------------

local windows = {}      -- [i] = Fenster
local Win = {}

local function MoverKey(i) return i == 1 and "damagemeter" or ("damagemeter" .. i) end

local function IconButton(parent, icon, tip, onClick)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(16, 16)
    b.tex = b:CreateTexture(nil, "ARTWORK")
    b.tex:SetAllPoints(b)
    b.tex:SetTexture(MEDIA .. icon)
    b.tex:SetVertexColor(unpack(C.textMuted))
    if b.RegisterForClicks then b:RegisterForClicks("LeftButtonUp", "RightButtonUp") end
    b:SetScript("OnClick", onClick)
    b:SetScript("OnEnter", function(self)
        self.tex:SetVertexColor(unpack(C.textBright))
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(tip, 1, 1, 1)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function(self)
        self.tex:SetVertexColor(unpack(C.textMuted))
        GameTooltip:Hide()
    end)
    return b
end

local function Row(w)
    local r = CreateFrame("Frame", nil, w.frame)
    r.bar = K.NewBar(r)
    r.bar:SetAllPoints(r)
    r.bg = r:CreateTexture(nil, "BACKGROUND")
    r.bg:SetAllPoints(r)
    local s = C.surface2
    r.bg:SetColorTexture(s[1], s[2], s[3], 0.8)
    local host = CreateFrame("Frame", nil, r)
    host:SetAllPoints(r)
    host:SetFrameLevel((r.bar:GetFrameLevel() or 1) + 2)
    r.name = K.NewText(host, 11)
    r.name:SetPoint("LEFT", r, "LEFT", 4, 0)
    r.name:SetJustifyH("LEFT")
    r.name:SetWordWrap(false)
    r.amount = K.NewText(host, 11)
    r.amount:SetPoint("RIGHT", r, "RIGHT", -4, 0)
    r.amount:SetJustifyH("RIGHT")
    r:Hide()
    return r
end

function Win:Mode() return ModeInfo(Opt("w" .. self.index .. "mode")) end
function Win:Session() return Opt("w" .. self.index .. "session") == "Overall" and "Overall" or "Current" end

function Win:Layout()
    local w, n, h = Opt("width"), Opt("bars"), Opt("barHeight")
    local f = self.frame
    f:SetSize(w, 24 + n * (h + 1) + 3)
    local bg = C.bgDark
    f.bg:SetColorTexture(bg[1], bg[2], bg[3], (Opt("bgAlpha") or 85) / 100)
    for i = 1, math.max(n, #self.rows) do
        local r = self.rows[i] or Row(self)
        self.rows[i] = r
        r:ClearAllPoints()
        r:SetPoint("TOPLEFT", f, "TOPLEFT", 2, -(24 + (i - 1) * (h + 1)))
        r:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -(24 + (i - 1) * (h + 1)))
        r:SetHeight(h)
        K.SetFont(r.name, math.max(8, math.floor(h * 0.6)))
        K.SetFont(r.amount, math.max(8, math.floor(h * 0.6)))
        r.name:SetWidth(w * 0.55)
        if i > n then r:Hide() end
    end
    self.empty:SetWidth(w - 16)
    self.close:SetShown(self.index > 1)
    self.plus:SetShown(Count() < MAX_WINDOWS)
    -- Die Knoepfe rechts reihen sich von aussen nach innen.
    local anchor, x = self.header, -4
    for _, b in ipairs({ self.close, self.gear, self.reset, self.plus }) do
        if b:IsShown() then
            b:ClearAllPoints()
            b:SetPoint("RIGHT", anchor, anchor == self.header and "RIGHT" or "LEFT", x, 0)
            anchor, x = b, -4
        end
    end
    self.session:ClearAllPoints()
    self.session:SetPoint("RIGHT", anchor, anchor == self.header and "RIGHT" or "LEFT", -8, 0)
end

local function Amount(fs, src, mode)
    if mode.deaths or type(src.totalAmount) == "nil" then fs:SetText("") return end
    local fmt = Opt("numbers")
    local rate = src.amountPerSecond
    if mode.count or type(rate) == "nil" or fmt == "total" then
        fs:SetText(DM.Format(src.totalAmount))
    elseif fmt == "rate" then
        fs:SetText(DM.Format(rate))
    else
        fs:SetFormattedText("%s (%s)", DM.Format(src.totalAmount), DM.Format(rate))
    end
end

-- Das Fenster so hoch wie das, was es zeigt (im Beta-Test: eine Zeile
-- und darunter acht leere). Fest auf "Balken" Zeilen, wenn abgeschaltet.
function Win:Fit(rows)
    local h = Opt("barHeight")
    local n = Opt("fitRows") and math.max(1, math.min(rows, Opt("bars"))) or Opt("bars")
    self.frame:SetHeight(24 + n * (h + 1) + 3)
end

function Win:ShowEmpty(text)
    for _, r in ipairs(self.rows) do r:Hide() end
    self.empty:SetText(text)
    self.empty:Show()
    self:Fit(2)   -- zwei Zeilen Platz fuer den Satz
end

function Win:Refresh()
    local f = self.frame
    if not f:IsShown() then return end
    local mode = self:Mode()
    local session = self:Session()
    self.session.text:SetText(session == "Overall" and "Gesamt" or "Aktuell")

    local title = mode.label
    local cdm = _G.C_DamageMeter
    if Opt("showTime") and Available() and cdm.GetSessionDurationSeconds then
        local ok, secs = pcall(cdm.GetSessionDurationSeconds, _G.Enum.DamageMeterSessionType[session])
        secs = ok and K.Plain(secs)
        if type(secs) == "number" and secs > 0 then title = title .. "  " .. Clock(secs) end
    end
    local ok, sources
    if DM._test then
        -- Testmodus (ui/testmode.lua): Beispielzeilen, und die Kopfzeile
        -- sagt es - Beispielzahlen duerfen nie wie gemessene aussehen.
        self.title:SetText(mode.label .. "  0:42  " .. WeintCodex.ColorText("textMuted", "Beispiel"))
        ok, sources = true, DM.TEST_SOURCES
    else
        self.title:SetText(title)
        if not Available() then
            self:ShowEmpty("Die Schadensmessung des Spiels steht auf diesem Client nicht zur Verfügung.")
            return
        end
        local e = _G.Enum
        local st = e.DamageMeterSessionType[session] or e.DamageMeterSessionType.Current
        local mt = e.DamageMeterType[mode.key]
        local data
        ok, data = pcall(cdm.GetCombatSessionFromType, st, mt)
        sources = ok and data and data.combatSources or nil
    end

    local n = Opt("bars")
    local count = sources and math.min(#sources, n) or 0
    if count == 0 then
        self:ShowEmpty(ok and "Noch nichts gemessen." or "Die Messung hat nicht geantwortet.")
        return
    end
    self.empty:Hide()

    -- Die Liste kommt absteigend sortiert: der erste Eintrag ist der
    -- volle Balken (auch wenn Lua seinen Wert nicht sehen darf).
    local maxAmt = sources[1].totalAmount
    for i = 1, n do
        local r = self.rows[i]
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
            if type(src.name) == "nil" then
                r.name:SetFormattedText("%d.", i)
            elseif Opt("rank") then
                r.name:SetFormattedText("%d. %s", i, src.name)
            else
                r.name:SetFormattedText("%s", src.name)
            end
            Amount(r.amount, src, mode)
            r:Show()
        elseif r then
            r:Hide()
        end
    end
    self:Fit(count)
end

function Win:CycleMode(back)
    local list = Modes()
    local cur = self:Mode().key
    local idx = 1
    for i, m in ipairs(list) do if m.key == cur then idx = i end end
    idx = idx + (back and -1 or 1)
    if idx > #list then idx = 1 elseif idx < 1 then idx = #list end
    K.Set(KEY, "w" .. self.index .. "mode", list[idx].key)
    self:Refresh()
end

local function CreateWindow(i)
    local w = setmetatable({ index = i, rows = {} }, { __index = Win })
    local f = CreateFrame("Frame", i == 1 and "WeintCodexDamageMeter" or ("WeintCodexDamageMeter" .. i), UIParent)
    w.frame = f
    f:SetFrameStrata("MEDIUM")
    f:SetClampedToScreen(true)
    f.bg = f:CreateTexture(nil, "BACKGROUND")
    f.bg:SetAllPoints(f)
    WeintCodex.DrawBorder(f, C.border[1], C.border[2], C.border[3], 1, 1)
    f.shadow = K.Glow(f, { spread = 7, shadow = true })

    local header = CreateFrame("Frame", nil, f)
    header:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
    header:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -1)
    header:SetHeight(21)
    local hb = header:CreateTexture(nil, "BACKGROUND")
    hb:SetAllPoints(header)
    local s2 = C.surface2
    hb:SetColorTexture(s2[1], s2[2], s2[3], 1)
    w.header = header

    -- Der Titel ist der Schalter fuer die Messart.
    local tb = CreateFrame("Button", nil, header)
    tb:SetPoint("LEFT", header, "LEFT", 6, 0)
    tb:SetSize(150, 20)
    if tb.RegisterForClicks then tb:RegisterForClicks("LeftButtonUp", "RightButtonUp") end
    w.title = K.NewText(tb, 11)
    w.title:SetPoint("LEFT", tb, "LEFT", 0, 0)
    w.title:SetTextColor(unpack(C.textBright))
    tb:SetScript("OnClick", function(_, button) w:CycleMode(button == "RightButton") end)
    tb:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Messart", 1, 1, 1)
        GameTooltip:AddLine("Linksklick: nächste, Rechtsklick: vorige.", 0.7, 0.7, 0.75, true)
        GameTooltip:Show()
    end)
    tb:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local sb = CreateFrame("Button", nil, header)
    sb:SetSize(48, 20)
    sb.text = K.NewText(sb, 10)
    sb.text:SetPoint("RIGHT", sb, "RIGHT", 0, 0)
    sb.text:SetTextColor(unpack(C.textMuted))
    sb:SetScript("OnClick", function()
        K.Set(KEY, "w" .. w.index .. "session", w:Session() == "Overall" and "Current" or "Overall")
        w:Refresh()
    end)
    w.session = sb

    w.plus = IconButton(header, "icon_plus", "Weiteres Fenster", function() DM.AddWindow() end)
    w.reset = IconButton(header, "icon_reset", "Alle Messungen leeren", function()
        local cdm = _G.C_DamageMeter
        if cdm and cdm.ResetAllCombatSessions then pcall(cdm.ResetAllCombatSessions) end
        DM.Refresh()
    end)
    w.gear = IconButton(header, "icon_gear", "Einstellungen", function()
        local O = WeintCodex.UIOptions
        if O and O.Show then O.Show(KEY) end
    end)
    w.close = IconButton(header, "icon_close", "Fenster schließen", function() DM.RemoveWindow(w.index) end)

    w.empty = K.NewText(f, 11)
    w.empty:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -30)
    w.empty:SetJustifyH("LEFT")
    w.empty:SetTextColor(unpack(C.textDim))
    w.empty:Hide()

    f.WCShowForUnlock = function() end
    local width = Opt("width") or 260
    K.RegisterMover(f, MoverKey(i), i == 1 and "Schadensanzeige" or ("Schadensanzeige " .. i),
        K.Layout("damagemeter", -(i - 1) * (width + 8), 0))
    windows[i] = w
    return w
end

-- Die Fenster auf den gespeicherten Stand bringen: so viele zeigen wie
-- eingestellt, die uebrigen verstecken (und ihre Verschiebeflaeche).
local function Sync()
    local n = Count()
    for i = 1, MAX_WINDOWS do
        local w = windows[i]
        if i <= n then
            w = w or CreateWindow(i)
            w.frame:Show()
            K.SetMoverEnabled(MoverKey(i), true)
        elseif w then
            w.frame:Hide()
            K.SetMoverEnabled(MoverKey(i), false)
        end
    end
    for i = 1, n do windows[i]:Layout() end
end

function DM.Refresh()
    for i = 1, Count() do
        local w = windows[i]
        if w then w:Refresh() end
    end
end

function DM.AddWindow()
    local n = Count()
    if n >= MAX_WINDOWS then return end
    K.Set(KEY, "windows", n + 1)
    Sync()
    DM.Refresh()
end

-- Fenster i schliessen: die dahinter ruecken mit ihren Einstellungen auf.
function DM.RemoveWindow(i)
    local n = Count()
    if i <= 1 or i > n then return end
    for j = i, n - 1 do
        K.Set(KEY, "w" .. j .. "mode", Opt("w" .. (j + 1) .. "mode"))
        K.Set(KEY, "w" .. j .. "session", Opt("w" .. (j + 1) .. "session"))
    end
    K.Set(KEY, "windows", n - 1)
    Sync()
    DM.Refresh()
end

-- Fuer den Prueflauf.
function DM.WindowCount() return Count() end
function DM.Window(i) return windows[i or 1] end
function DM.RowsShown(i)
    local w = windows[i or 1]
    local n = 0
    for _, r in ipairs(w and w.rows or {}) do if r:IsShown() then n = n + 1 end end
    return n
end
function DM.EmptyText(i)
    local w = windows[i or 1]
    return w and w.empty:IsShown() and w.empty:GetText() or nil
end
function DM.AmountText(i, row)
    local w = windows[i or 1]
    local r = w and w.rows[row or 1]
    return r and r.amount:GetText() or nil
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

-- Beispielzeilen fuer den Testmodus. Namen und Zahlen sind erfunden und
-- stehen nur da, solange der Testmodus laeuft.
DM.TEST_SOURCES = {
    { name = "Varek",    classFilename = "ROGUE",   totalAmount = 4940, amountPerSecond = 118 },
    { name = "Tamsin",   classFilename = "MAGE",    totalAmount = 4370, amountPerSecond = 104 },
    { name = "Orwen",    classFilename = "HUNTER",  totalAmount = 3650, amountPerSecond = 87 },
    { name = "Brunhild", classFilename = "WARRIOR", totalAmount = 2180, amountPerSecond = 52 },
    { name = "Liora",    classFilename = "PRIEST",  totalAmount = 380,  amountPerSecond = 9 },
}

function DM.ShowTest(on)
    DM._test = on and true or nil
    DM.Refresh()
end

local function Enable()
    Sync()
    -- Ruhe und Kampf (ui/presence.lua): ausserhalb des Kampfes leiser.
    WeintCodex.UIPresence.Register("damage", function()
        local out = {}
        for i = 1, Count() do if windows[i] then out[#out + 1] = windows[i].frame end end
        return out
    end, "fade_damage")
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

local function ModeItems()
    local items = {}
    for _, m in ipairs(MODES) do items[#items + 1] = { value = m.key, text = m.label } end
    return items
end
local SESSION_ITEMS = { { value = "Current", text = "Dieser Kampf" }, { value = "Overall", text = "Ganze Sitzung" } }

K.Register({
    key = KEY, group = "ui", order = 55,
    title = "Schadensanzeige",
    description = "Schaden, Heilung, erlittener Schaden, Unterbrechungen, Bannungen und Tode als Balken – bis zu vier Fenster, gemessen vom Spiel selbst.",
    defaults = defaults,
    Enable = Enable,
    OnSetting = function()
        if windows[1] then Sync() DM.Refresh() end
    end,
    pages = {
        { key = "allgemein", label = "Allgemein", build = function(B)
            B:Section("Fenster")
            B:Row({ type = "slider", label = "Anzahl Fenster", key = "windows", min = 1, max = MAX_WINDOWS, step = 1,
                    format = function(v) return tostring(v) end },
                  { type = "slider", label = "Breite", key = "width", min = 160, max = 420, step = 2, format = px })
            B:Row({ type = "slider", label = "Balken", key = "bars", min = 3, max = 25, step = 1,
                    format = function(v) return tostring(v) end },
                  { type = "slider", label = "Balkenhöhe", key = "barHeight", min = 12, max = 30, step = 1, format = px })
            B:Row({ type = "slider", label = "Deckkraft des Hintergrunds", key = "bgAlpha", min = 0, max = 100, step = 5,
                    format = function(v) return string.format("%d %%", v) end },
                  { type = "toggle", label = "Kampfdauer in der Kopfzeile", key = "showTime" })
            B:Row({ type = "toggle", label = "Höhe nach Inhalt", key = "fitRows",
                    description = "So hoch wie die gezeigten Zeilen, statt immer Platz für alle Balken." },
                  { type = "empty" })
            B:Section("Zahlen")
            B:Row({ type = "dropdown", label = "Rechts im Balken", key = "numbers", items = {
                        { value = "both",  text = "Gesamt (pro Sekunde)" },
                        { value = "total", text = "Nur Gesamt" },
                        { value = "rate",  text = "Nur pro Sekunde" } } },
                  { type = "toggle", label = "Platz vor dem Namen", key = "rank" })
            B:Row({ type = "toggle", label = "Klassenfarben", key = "classColor" },
                  { type = "toggle", label = "Anzeige des Spiels ausblenden", key = "hideBlizzard", reload = true,
                    description = "Die Messung läuft weiter – nur Blizzards Fenster geht aus." })
            B:Section("Bedienung")
            B:Note("Klick auf die Messart schaltet weiter (Rechtsklick zurück), „Aktuell/Gesamt“ wechselt zwischen diesem Kampf und der ganzen Sitzung. In der Kopfzeile: Plus öffnet ein weiteres Fenster, der Kreis leert alle Messungen, das Zahnrad öffnet diese Seite, das Kreuz schließt ein zusätzliches Fenster. Verschieben: „Rahmen entsperren“.")
        end },
        { key = "fenster", label = "Je Fenster", build = function(B)
            for i = 1, MAX_WINDOWS do
                B:Section(i == 1 and "Fenster 1" or ("Fenster " .. i))
                B:Row({ type = "dropdown", label = "Messart", key = "w" .. i .. "mode", items = ModeItems(),
                        disabled = function() return i > Count() end },
                      { type = "dropdown", label = "Zeitraum", key = "w" .. i .. "session", items = SESSION_ITEMS,
                        disabled = function() return i > Count() end })
            end
            B:Note("Die Zahlen misst das Spiel selbst – Addons bekommen auf dem neuen Client kein Kampflog mehr. Sie stimmen deshalb mit Blizzards eigener Anzeige überein.")
        end },
    },
})
