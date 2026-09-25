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
    classIcons = true,     -- Klassensymbol vor dem Balken
    showPercent = true,    -- Anteil am Ganzen, wo die Zahlen offen sind
    pinSelf   = true,      -- die eigene Zeile immer zeigen (wie Details)
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
    { key = "DamageTaken",  label = "Erlittener Schaden", short = "Erlitten", rate = true },
    { key = "Interrupts",   label = "Unterbrechungen",    short = "Unterbr.", count = true },
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
    r.icon = r:CreateTexture(nil, "ARTWORK")
    r.icon:SetPoint("TOPLEFT", r, "TOPLEFT", 0, 0)
    r.icon:SetPoint("BOTTOMLEFT", r, "BOTTOMLEFT", 0, 0)
    r.bar = K.NewBar(r)
    r.bar:SetPoint("TOPRIGHT", r, "TOPRIGHT", 0, 0)
    r.bar:SetPoint("BOTTOMRIGHT", r, "BOTTOMRIGHT", 0, 0)
    r.bg = r:CreateTexture(nil, "BACKGROUND")
    r.bg:SetAllPoints(r.bar)
    local s = C.surface2
    r.bg:SetColorTexture(s[1], s[2], s[3], 0.8)
    -- Die eigene Zeile: ein Strich im Akzent am linken Rand ("das bist du"
    -- ist eine Auswahl, keine Wertung).
    r.own = r:CreateTexture(nil, "OVERLAY", nil, 3)
    r.own:SetPoint("TOPLEFT", r.bar, "TOPLEFT", 0, 0)
    r.own:SetPoint("BOTTOMLEFT", r.bar, "BOTTOMLEFT", 0, 0)
    r.own:SetWidth(2)
    local a = C.accent
    r.own:SetColorTexture(a[1], a[2], a[3], 1)
    r.own:Hide()
    -- Maus: Aufschluesselung nach Zaubern (wie Details).
    r:EnableMouse(true)
    r:SetScript("OnEnter", function(self) DM.ShowTooltip(w, self) end)
    r:SetScript("OnLeave", function() GameTooltip:Hide() end)
    -- Klick: Aufschluesselung dieses Spielers (wie Details).
    r:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" and self._src then DM.OpenBreakdown(w, self._src) end
    end)
    local host = CreateFrame("Frame", nil, r)
    host:SetAllPoints(r)
    host:SetFrameLevel((r.bar:GetFrameLevel() or 1) + 2)
    r.name = K.NewText(host, 11)
    r.name:SetPoint("LEFT", r.bar, "LEFT", 5, 0)
    r.name:SetJustifyH("LEFT")
    r.name:SetWordWrap(false)
    r.amount = K.NewText(host, 11)
    r.amount:SetPoint("RIGHT", r, "RIGHT", -4, 0)
    r.amount:SetJustifyH("RIGHT")
    r:Hide()
    return r
end

function Win:Mode() return ModeInfo(Opt("w" .. self.index .. "mode")) end
-- Zeitraum: "Current", "Overall" oder die Nummer eines frueheren Kampfes
-- (C_DamageMeter.GetAvailableCombatSessions). Fruehere Kaempfe gelten nur
-- in dieser Sitzung - gespeichert wird nur "Aktuell" oder "Gesamt".
function Win:Session()
    if self._sessionID then return self._sessionID end
    return Opt("w" .. self.index .. "session") == "Overall" and "Overall" or "Current"
end

-- Fruehere Kaempfe, neuester zuerst. Leer, wenn der Client sie nicht nennt.
function DM.Sessions()
    local cdm = _G.C_DamageMeter
    if not (cdm and cdm.GetAvailableCombatSessions) then return {} end
    local ok, list = pcall(cdm.GetAvailableCombatSessions)
    if not ok or type(list) ~= "table" then return {} end
    local out = {}
    for i = #list, 1, -1 do
        local sess = list[i]
        local id = type(sess) == "table" and K.Plain(sess.sessionID or sess.combatSessionID) or K.Plain(sess)
        if type(id) == "number" then
            local name = type(sess) == "table" and K.Plain(sess.name) or nil
            local dur = type(sess) == "table" and K.Plain(sess.durationSeconds) or nil
            out[#out + 1] = { id = id, name = type(name) == "string" and name or nil,
                              dur = type(dur) == "number" and dur or nil }
        end
    end
    return out
end

-- Die Reihe zum Durchschalten: Aktuell, Gesamt, dann fruehere Kaempfe.
function Win:CycleSession(back)
    local seq = { "Current", "Overall" }
    for _, sess in ipairs(DM.Sessions()) do seq[#seq + 1] = sess.id end
    local cur, idx = self:Session(), 1
    for i, v in ipairs(seq) do if v == cur then idx = i end end
    idx = idx + (back and -1 or 1)
    if idx > #seq then idx = 1 elseif idx < 1 then idx = #seq end
    local v = seq[idx]
    if type(v) == "number" then
        self._sessionID = v
    else
        self._sessionID = nil
        K.Set(KEY, "w" .. self.index .. "session", v)
    end
    self:Refresh()
end

function Win:SessionLabel()
    local sess = self:Session()
    if sess == "Overall" then return "Gesamt" end
    if sess == "Current" then return "Aktuell" end
    for i, info in ipairs(DM.Sessions()) do
        if info.id == sess then
            if info.name then return WeintCodex.Truncate and WeintCodex.Truncate(info.name, 14) or info.name end
            return "Kampf −" .. i
        end
    end
    return "Früher"
end

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

-- Anteil in Prozent - nur mit offenen Zahlen. Eine geheime Summe heisst
-- "kein Anteil", nicht 0 %.
local function Share(src, total)
    local v, t = K.Plain(src.totalAmount), K.Plain(total)
    if type(v) ~= "number" or type(t) ~= "number" or t <= 0 then return nil end
    return v / t * 100
end
DM.Share = Share

local function Amount(fs, src, mode, pct)
    if mode.deaths or type(src.totalAmount) == "nil" then fs:SetText("") return end
    local fmt = Opt("numbers")
    local rate = src.amountPerSecond
    local tail = (pct and Opt("showPercent")) and string.format("  %d%%", math.floor(pct + 0.5)) or ""
    if mode.count or type(rate) == "nil" or fmt == "total" then
        fs:SetFormattedText("%s%s", DM.Format(src.totalAmount), tail)
    elseif fmt == "rate" then
        fs:SetFormattedText("%s%s", DM.Format(rate), tail)
    else
        fs:SetFormattedText("%s (%s)%s", DM.Format(src.totalAmount), DM.Format(rate), tail)
    end
end

-- Klassensymbol aus dem Bild des Spiels (alle Klassen auf einem Blatt).
local CLASS_SHEET = "Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES"
local function ClassIcon(tex, class)
    local tc = class and _G.CLASS_ICON_TCOORDS and _G.CLASS_ICON_TCOORDS[class]
    if not tc then tex:Hide() return false end
    tex:SetTexture(CLASS_SHEET)
    tex:SetTexCoord(tc[1], tc[2], tc[3], tc[4])
    tex:Show()
    return true
end

-- Ist diese Zeile der Spieler selbst? Nur offene Werte werden verglichen.
local function IsMe(src)
    if K.Bool(src.isLocalPlayer, false) then return true end
    local g, me = K.Plain(src.sourceGUID), K.Plain(_G.UnitGUID and _G.UnitGUID("player"))
    if type(g) == "string" and type(me) == "string" then return g == me end
    return false
end
DM.IsMe = IsMe

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
    self.session.text:SetText(self:SessionLabel())

    local title = mode.label
    local cdm = _G.C_DamageMeter
    if Opt("showTime") and Available() and cdm.GetSessionDurationSeconds and type(session) == "string" then
        local ok, secs = pcall(cdm.GetSessionDurationSeconds, _G.Enum.DamageMeterSessionType[session])
        secs = ok and K.Plain(secs)
        -- Nur eine plausible Kampfdauer: im Beta-Test stand hier
        -- "70889:57" - der Client meldete etwas anderes als die Dauer.
        if type(secs) == "number" and secs > 0 and secs < 6 * 3600 then title = title .. "  " .. Clock(secs) end
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
        local data
        ok, data = DM.Fetch(session, mode.key)
        sources = ok and type(data) == "table" and data.combatSources or nil
        self._total = ok and type(data) == "table" and data.totalAmount or nil
    end
    if DM._test then
        local t = 0
        for _, src in ipairs(sources) do t = t + src.totalAmount end
        self._total = t
    elseif type(self._total) == "nil" and sources then
        -- Keine Summe vom Client: selbst zusammenzaehlen, wenn alles offen ist.
        local t = 0
        for _, src in ipairs(sources) do
            local v = K.Plain(src.totalAmount)
            if type(v) ~= "number" then t = nil break end
            t = t + v
        end
        self._total = t
    end

    local n = Opt("bars")
    local count = sources and math.min(#sources, n) or 0
    -- Die eigene Zeile immer: steht man nicht unter den ersten n, nimmt
    -- sie den letzten Platz ein - mit ihrem echten Rang.
    local order = {}
    for i = 1, count do order[i] = i end
    if Opt("pinSelf") and sources and #sources > n and n > 1 then
        local mine
        for i = 1, n do if IsMe(sources[i]) then mine = i break end end
        if not mine then
            for i = n + 1, #sources do if IsMe(sources[i]) then order[n] = i break end end
        end
    end
    if count == 0 then
        self:ShowEmpty(ok and "Noch nichts gemessen." or "Die Messung hat nicht geantwortet.")
        return
    end
    self.empty:Hide()

    -- Die Liste kommt absteigend sortiert: der erste Eintrag ist der
    -- volle Balken (auch wenn Lua seinen Wert nicht sehen darf).
    local maxAmt = sources[1].totalAmount
    local h = Opt("barHeight")
    for i = 1, n do
        local r = self.rows[i]
        local rank = order[i]
        local src = rank and sources[rank]
        if r and src and i <= count then
            r._src, r._rank = src, rank
            local icon = Opt("classIcons") and ClassIcon(r.icon, K.Plain(src.classFilename))
            if not icon then r.icon:Hide() end
            r.icon:SetWidth(h)
            r.bar:SetPoint("TOPLEFT", r, "TOPLEFT", icon and (h + 1) or 0, 0)
            r.bar:SetPoint("BOTTOMLEFT", r, "BOTTOMLEFT", icon and (h + 1) or 0, 0)
            r.own:SetShown(IsMe(src))
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
                r.name:SetFormattedText("%d.", rank)
            elseif Opt("rank") then
                r.name:SetFormattedText("%d. %s", rank, src.name)
            else
                r.name:SetFormattedText("%s", src.name)
            end
            Amount(r.amount, src, mode, Share(src, self._total))
            r:Show()
        elseif r then
            r._src = nil
            r:Hide()
        end
    end
    self:Fit(count)
end

-- Die Daten eines Zeitraums fuer eine Messart. Liefert ok, Daten.
function DM.Fetch(session, modeKey)
    local cdm, e = _G.C_DamageMeter, _G.Enum
    local mt = e.DamageMeterType[modeKey]
    if type(session) == "number" then
        if not cdm.GetCombatSessionFromID then return false, nil end
        return pcall(cdm.GetCombatSessionFromID, session, mt)
    end
    local st = e.DamageMeterSessionType[session] or e.DamageMeterSessionType.Current
    return pcall(cdm.GetCombatSessionFromType, st, mt)
end

-- Die Zauber eines Eintrags, groesste zuerst. Leer, wo der Client sie
-- nicht herausgibt.
function DM.Spells(session, modeKey, guid)
    local cdm, e = _G.C_DamageMeter, _G.Enum
    if not (cdm and e and e.DamageMeterType) or type(guid) == "nil" then return {} end
    local mt = e.DamageMeterType[modeKey]
    local ok, data
    if type(session) == "number" and cdm.GetCombatSessionSourceFromID then
        ok, data = pcall(cdm.GetCombatSessionSourceFromID, session, mt, guid)
    elseif type(session) == "string" and cdm.GetCombatSessionSourceFromType then
        local st = e.DamageMeterSessionType[session] or e.DamageMeterSessionType.Current
        ok, data = pcall(cdm.GetCombatSessionSourceFromType, st, mt, guid)
    end
    local list = ok and type(data) == "table" and (data.combatSpells or data.spells) or nil
    return type(list) == "table" and list or {}
end

local function SpellName(id)
    if type(id) == "nil" then return nil end
    local cs = _G.C_Spell
    if cs and cs.GetSpellName then
        local ok, n = pcall(cs.GetSpellName, id)
        if ok and type(n) ~= "nil" then return n end
    end
    if _G.GetSpellInfo then
        local ok, n = pcall(_G.GetSpellInfo, id)
        if ok and type(n) ~= "nil" then return n end
    end
    return nil
end

local function SpellIcon(id)
    local cs = _G.C_Spell
    if type(id) ~= "nil" and cs and cs.GetSpellTexture then
        local ok, t = pcall(cs.GetSpellTexture, id)
        if ok and type(t) ~= "nil" then return t end
    end
    return nil
end

-- Tooltip einer Zeile: Summe, pro Sekunde, Anteil, dann die Zauber.
function DM.ShowTooltip(w, r)
    local src = r._src
    if not src then return end
    local mode = w:Mode()
    GameTooltip:SetOwner(r, "ANCHOR_LEFT")
    pcall(GameTooltip.SetText, GameTooltip, src.name or "?", 1, 1, 1)
    local muted = C.textMuted
    pcall(GameTooltip.AddLine, GameTooltip, mode.label .. " · " .. w:SessionLabel(), muted[1], muted[2], muted[3])
    if not mode.deaths then
        pcall(GameTooltip.AddDoubleLine, GameTooltip, "Gesamt", DM.Format(src.totalAmount), 1, 1, 1, 1, 1, 1)
        if mode.rate and type(src.amountPerSecond) ~= "nil" then
            pcall(GameTooltip.AddDoubleLine, GameTooltip, "Pro Sekunde", DM.Format(src.amountPerSecond), 1, 1, 1, 1, 1, 1)
        end
        local pct = Share(src, w._total)
        if pct then
            GameTooltip:AddDoubleLine("Anteil", string.format("%d%%", math.floor(pct + 0.5)), 1, 1, 1, 1, 1, 1)
        end
    end
    local spells = DM._test and {} or DM.Spells(w:Session(), mode.key, src.sourceGUID)
    if #spells > 0 then
        GameTooltip:AddLine(" ")
        for i = 1, math.min(8, #spells) do
            local sp = spells[i]
            local name = SpellName(sp.spellID) or "?"
            local icon = SpellIcon(sp.spellID)
            local pct = Share(sp, src.totalAmount)
            local right = DM.Format(sp.totalAmount)
            if pct then right = string.format("%s  %d%%", right, math.floor(pct + 0.5)) end
            local left = name
            if type(icon) ~= "nil" and type(K.Plain(icon)) ~= "nil" then left = string.format("|T%s:14:14:0:0:64:64:5:59:5:59|t %s", tostring(icon), name) end
            pcall(GameTooltip.AddDoubleLine, GameTooltip, left, right, 0.93, 0.93, 0.95, 1, 1, 1)
        end
    elseif not mode.deaths and not DM._test then
        GameTooltip:AddLine("Zauber nennt der Client hier nicht.", muted[1], muted[2], muted[3], true)
    end
    local a = C.accent
    GameTooltip:AddLine("Klick: Aufschlüsselung", a[1], a[2], a[3])
    GameTooltip:Show()
end

--------------------------------------------------
-- Aufschluesselung (Klick auf einen Namen, wie Details)
--------------------------------------------------
-- Ein eigenes Fenster neben der Schadensanzeige: wer, wie viel, wie viel
-- je Sekunde, welcher Anteil, welcher Rang - und darunter jeder Zauber mit
-- Balken, Summe, Anteil und Wert je Sekunde. Oben die Messarten zum
-- Umschalten (Schaden, Heilung, erlittener Schaden ... desselben
-- Spielers), Pfeile blaettern zum naechsten Spieler der Liste. Es folgt
-- dem Takt der Anzeige, also live im Kampf. Esc oder X schliesst.
--
-- Was der Client nicht herausgibt, steht nicht da: keine Zauber ->
-- ein Satz, keine Dauer -> kein "je Sekunde" beim Zauber. Ziele,
-- Treffer, kritische Treffer nennt C_DamageMeter nach allem, was bekannt
-- ist, nicht - deshalb gibt es sie hier nicht.

local BD_W, BD_ROW, BD_MAX = 340, 20, 12
local bd

-- Dieselbe Person in einer anderen Liste: ueber die GUID, sonst den Namen.
local function SameSource(a, guid, name)
    local g = K.Plain(a.sourceGUID)
    if type(guid) == "string" and type(g) == "string" then return g == guid end
    local n = K.Plain(a.name)
    return type(name) == "string" and type(n) == "string" and n == name
end

local function SessionSeconds(session)
    local cdm = _G.C_DamageMeter
    if DM._test then return 42 end
    if not (cdm and cdm.GetSessionDurationSeconds and type(session) == "string") then return nil end
    local ok, secs = pcall(cdm.GetSessionDurationSeconds, _G.Enum.DamageMeterSessionType[session])
    secs = ok and K.Plain(secs) or nil
    if type(secs) == "number" and secs > 0 and secs < 6 * 3600 then return secs end
    return nil
end

local function Stat(parent, label)
    local c = CreateFrame("Frame", nil, parent)
    c:SetSize((BD_W - 24) / 4, 34)
    c.value = K.NewText(c, 14)
    c.value:SetPoint("TOPLEFT", c, "TOPLEFT", 0, 0)
    c.value:SetTextColor(unpack(C.textBright))
    c.label = K.NewText(c, 10)
    c.label:SetPoint("TOPLEFT", c.value, "BOTTOMLEFT", 0, -2)
    c.label:SetTextColor(unpack(C.textDim))
    c.label:SetText(label)
    return c
end

local function SpellRow(parent)
    local r = CreateFrame("Frame", nil, parent)
    r:SetHeight(BD_ROW)
    r.icon = r:CreateTexture(nil, "ARTWORK")
    r.icon:SetSize(BD_ROW, BD_ROW)
    r.icon:SetPoint("LEFT", r, "LEFT", 0, 0)
    if r.icon.SetTexCoord then r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) end
    r.bar = K.NewBar(r)
    r.bar:SetPoint("TOPLEFT", r, "TOPLEFT", BD_ROW + 2, 0)
    r.bar:SetPoint("BOTTOMRIGHT", r, "BOTTOMRIGHT", 0, 0)
    r.bg = r:CreateTexture(nil, "BACKGROUND")
    r.bg:SetAllPoints(r.bar)
    local s = C.surface2
    r.bg:SetColorTexture(s[1], s[2], s[3], 0.8)
    local host = CreateFrame("Frame", nil, r)
    host:SetAllPoints(r)
    host:SetFrameLevel((r.bar:GetFrameLevel() or 1) + 2)
    r.name = K.NewText(host, 11)
    r.name:SetPoint("LEFT", r.bar, "LEFT", 5, 0)
    r.name:SetPoint("RIGHT", r.bar, "RIGHT", -120, 0)
    r.name:SetJustifyH("LEFT")
    r.name:SetWordWrap(false)
    r.amount = K.NewText(host, 11)
    r.amount:SetPoint("RIGHT", r.bar, "RIGHT", -4, 0)
    r.amount:SetJustifyH("RIGHT")
    r:EnableMouse(true)
    r:SetScript("OnEnter", function(self)
        if type(self._spell) == "nil" or not GameTooltip.SetSpellByID then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        pcall(GameTooltip.SetSpellByID, GameTooltip, self._spell)
        GameTooltip:Show()
    end)
    r:SetScript("OnLeave", function() GameTooltip:Hide() end)
    r:Hide()
    return r
end

local function BuildBreakdown()
    if bd then return bd end
    local f = CreateFrame("Frame", "WeintCodexDamageBreakdown", UIParent)
    f:SetSize(BD_W, 200)
    f:SetFrameStrata("MEDIUM")
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    f.kachel = K.Kachel(f, { shadow = 8 })
    bd = { frame = f, rows = {}, tabs = {} }

    bd.icon = f:CreateTexture(nil, "ARTWORK")
    bd.icon:SetSize(24, 24)
    bd.icon:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -12)
    bd.name = K.NewText(f, 15)
    bd.name:SetPoint("TOPLEFT", bd.icon, "TOPRIGHT", 8, 1)
    bd.name:SetPoint("RIGHT", f, "RIGHT", -84, 0)
    bd.name:SetJustifyH("LEFT")
    bd.name:SetWordWrap(false)
    bd.sub = K.NewText(f, 10)
    bd.sub:SetPoint("TOPLEFT", bd.name, "BOTTOMLEFT", 0, -2)
    bd.sub:SetTextColor(unpack(C.textMuted))

    bd.close = IconButton(f, "icon_close", "Schließen", function() f:Hide() end)
    bd.close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -10, -12)
    local function Arrow(text, tip, dir)
        local b = CreateFrame("Button", nil, f)
        b:SetSize(20, 20)
        b.text = K.NewText(b, 16)
        b.text:SetPoint("CENTER", b, "CENTER", 0, 1)
        b.text:SetText(text)
        b.text:SetTextColor(unpack(C.textMuted))
        b:SetScript("OnClick", function() DM.StepBreakdown(dir) end)
        b:SetScript("OnEnter", function(self)
            self.text:SetTextColor(unpack(C.textBright))
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(tip, 1, 1, 1)
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", function(self)
            self.text:SetTextColor(unpack(C.textMuted))
            GameTooltip:Hide()
        end)
        return b
    end
    bd.next = Arrow("›", "Nächster in der Liste", 1)
    bd.next:SetPoint("RIGHT", bd.close, "LEFT", -8, 0)
    bd.prev = Arrow("‹", "Voriger in der Liste", -1)
    bd.prev:SetPoint("RIGHT", bd.next, "LEFT", -2, 0)

    -- Kennzahlen in einer Reihe.
    bd.stats = {}
    for i, label in ipairs({ "Gesamt", "Je Sekunde", "Anteil", "Rang" }) do
        local c = Stat(f, label)
        if i == 1 then
            c:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -48)
        else
            c:SetPoint("TOPLEFT", bd.stats[i - 1], "TOPRIGHT", 0, 0)
        end
        bd.stats[i] = c
    end

    -- Messarten als flache Reiter.
    bd.tabRow = CreateFrame("Frame", nil, f)
    bd.tabRow:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -90)
    bd.tabRow:SetPoint("TOPRIGHT", f, "TOPRIGHT", -12, -90)
    bd.tabRow:SetHeight(20)
    local line = bd.tabRow:CreateTexture(nil, "BACKGROUND")
    line:SetPoint("BOTTOMLEFT", bd.tabRow, "BOTTOMLEFT", 0, 0)
    line:SetPoint("BOTTOMRIGHT", bd.tabRow, "BOTTOMRIGHT", 0, 0)
    line:SetHeight(1)
    line:SetColorTexture(C.border[1], C.border[2], C.border[3], 1)

    bd.list = CreateFrame("Frame", nil, f)
    bd.list:SetPoint("TOPLEFT", bd.tabRow, "BOTTOMLEFT", 0, -8)
    bd.list:SetPoint("TOPRIGHT", bd.tabRow, "BOTTOMRIGHT", 0, -8)
    bd.list:SetHeight(BD_MAX * (BD_ROW + 2))
    for i = 1, BD_MAX do
        local r = SpellRow(bd.list)
        r:SetPoint("TOPLEFT", bd.list, "TOPLEFT", 0, -(i - 1) * (BD_ROW + 2))
        r:SetPoint("TOPRIGHT", bd.list, "TOPRIGHT", 0, -(i - 1) * (BD_ROW + 2))
        bd.rows[i] = r
    end
    bd.note = K.NewText(f, 11)
    bd.note:SetJustifyH("LEFT")
    bd.note:SetWidth(BD_W - 24)
    bd.note:SetTextColor(unpack(C.textDim))

    f:SetScript("OnHide", function() bd.guid, bd.name_ = nil, nil end)
    -- Esc schliesst, wie jedes Fenster des Spiels.
    if type(_G.UISpecialFrames) == "table" then table.insert(_G.UISpecialFrames, "WeintCodexDamageBreakdown") end
    f:Hide()
    return bd
end

local function PaintTabs()
    for _, t in ipairs(bd.tabs) do
        local on = (t._mode == bd.mode)
        t.text:SetTextColor(unpack(on and C.textBright or C.textMuted))
        t.line:SetShown(on)
    end
end

local function BuildTabs()
    for _, t in ipairs(bd.tabs) do t:Hide() end
    local x = 0
    local i = 0
    for _, m in ipairs(Modes()) do
        if not m.deaths then
            i = i + 1
            local t = bd.tabs[i]
            if not t then
                t = CreateFrame("Button", nil, bd.tabRow)
                t:SetHeight(20)
                t.text = K.NewText(t, 11)
                t.text:SetPoint("CENTER", t, "CENTER", 0, 1)
                t.line = t:CreateTexture(nil, "ARTWORK")
                t.line:SetPoint("BOTTOMLEFT", t, "BOTTOMLEFT", 0, 0)
                t.line:SetPoint("BOTTOMRIGHT", t, "BOTTOMRIGHT", 0, 0)
                t.line:SetHeight(2)
                t.line:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 1)
                t:SetScript("OnClick", function(self)
                    bd.mode = self._mode
                    DM.RefreshBreakdown()
                end)
                bd.tabs[i] = t
            end
            t._mode = m.key
            -- Kurz: "Erlittener Schaden" passt sonst nicht in die Reihe.
            t.text:SetText(m.short or m.label)
            local w = K.Plain(t.text:GetStringWidth())
            t:SetWidth((type(w) == "number" and w or 50) + 14)
            t:ClearAllPoints()
            t:SetPoint("LEFT", bd.tabRow, "LEFT", x, 0)
            x = x + t:GetWidth() + 4
            t:Show()
        end
    end
    PaintTabs()
end

-- Neben das Fenster, auf die Seite mit mehr Platz.
local function Place(w)
    local f = bd.frame
    local wf = w.frame
    f:ClearAllPoints()
    local cx = K.Plain(wf.GetCenter and select(1, wf:GetCenter()))
    local uw = K.Plain(UIParent:GetWidth())
    if type(cx) == "number" and type(uw) == "number" and cx > uw / 2 then
        f:SetPoint("BOTTOMRIGHT", wf, "BOTTOMLEFT", -10, 0)
    else
        f:SetPoint("BOTTOMLEFT", wf, "BOTTOMRIGHT", 10, 0)
    end
end

-- Die Liste der aktuellen Messart (Test oder Client), mit Summe.
local function SourcesFor(session, modeKey)
    if DM._test then
        local t = 0
        for _, s in ipairs(DM.TEST_SOURCES) do t = t + s.totalAmount end
        return DM.TEST_SOURCES, t
    end
    if not Available() then return nil, nil end
    local ok, data = DM.Fetch(session, modeKey)
    if not (ok and type(data) == "table" and type(data.combatSources) == "table") then return nil, nil end
    local total = data.totalAmount
    if type(total) == "nil" then
        local t = 0
        for _, src in ipairs(data.combatSources) do
            local v = K.Plain(src.totalAmount)
            if type(v) ~= "number" then t = nil break end
            t = t + v
        end
        total = t
    end
    return data.combatSources, total
end

function DM.RefreshBreakdown()
    if not (bd and bd.frame:IsShown() and bd.win) then return end
    local w = bd.win
    local session = w:Session()
    local mode = ModeInfo(bd.mode)
    PaintTabs()
    local sources, total = SourcesFor(session, mode.key)
    local src, rank
    for i, s in ipairs(sources or {}) do
        if SameSource(s, bd.guid, bd.name_) then src, rank = s, i break end
    end
    bd.sources, bd.rank = sources, rank

    -- Kopf
    local class = src and K.Plain(src.classFilename) or bd.class
    if not ClassIcon(bd.icon, class) then bd.icon:Hide() end
    if src and type(src.name) ~= "nil" then bd.name:SetFormattedText("%s", src.name)
    elseif bd.name_ then bd.name:SetText(bd.name_) end
    local cc = class and _G.RAID_CLASS_COLORS and _G.RAID_CLASS_COLORS[class]
    if cc then bd.name:SetTextColor(cc.r, cc.g, cc.b) else bd.name:SetTextColor(unpack(C.textBright)) end
    bd.sub:SetText(mode.label .. " · " .. w:SessionLabel() .. (DM._test and "  ·  Beispiel" or ""))

    -- Kennzahlen
    local st = bd.stats
    if src then
        st[1].value:SetText(DM.Format(src.totalAmount))
        if mode.rate and type(src.amountPerSecond) ~= "nil" then st[2].value:SetText(DM.Format(src.amountPerSecond))
        else st[2].value:SetText("–") end
        local pct = Share(src, total)
        st[3].value:SetText(pct and string.format("%d%%", math.floor(pct + 0.5)) or "–")
        st[4].value:SetText(string.format("%d / %d", rank, #sources))
    else
        for i = 1, 4 do st[i].value:SetText("–") end
    end

    -- Zauber
    local spells = {}
    if src then
        spells = DM._test and (DM.TEST_SPELLS[rank] or {}) or DM.Spells(session, mode.key, src.sourceGUID)
    end
    local secs = SessionSeconds(session)
    local r, g, b = C.info[1], C.info[2], C.info[3]
    if cc then r, g, b = cc.r, cc.g, cc.b end
    local shown = math.min(#spells, BD_MAX)
    local top = spells[1] and spells[1].totalAmount
    for i = 1, BD_MAX do
        local row = bd.rows[i]
        local sp = spells[i]
        if sp and i <= shown then
            row._spell = sp.spellID
            local icon = SpellIcon(sp.spellID)
            if type(icon) ~= "nil" then row.icon:SetTexture(icon) row.icon:Show() else row.icon:Hide() end
            row.name:SetText(SpellName(sp.spellID) or "?")
            if type(top) ~= "nil" then row.bar:SetMinMaxValues(0, top) end
            if type(sp.totalAmount) ~= "nil" then row.bar:SetValue(sp.totalAmount) else row.bar:SetValue(0) end
            K.PaintBar(row.bar, r, g, b)
            local pct = Share(sp, src.totalAmount)
            local rate = sp.amountPerSecond
            local v = K.Plain(sp.totalAmount)
            local rateText
            if type(rate) ~= "nil" then rateText = DM.Format(rate)
            elseif secs and type(v) == "number" then rateText = DM.Format(v / secs) end
            local parts = DM.Format(sp.totalAmount)
            if rateText then parts = string.format("%s (%s)", parts, rateText) end
            if pct then parts = string.format("%s  %d%%", parts, math.floor(pct + 0.5)) end
            row.amount:SetText(parts)
            row:Show()
        else
            row._spell = nil
            row:Hide()
        end
    end
    local listH = shown * (BD_ROW + 2)
    bd.list:SetHeight(math.max(1, listH))
    bd.note:ClearAllPoints()
    bd.note:SetPoint("TOPLEFT", bd.list, "TOPLEFT", 0, -listH - (shown > 0 and 6 or 0))
    if not src then
        bd.note:SetText("In dieser Messart steht " .. (bd.name_ or "dieser Spieler") .. " nicht auf der Liste.")
    elseif shown == 0 then
        bd.note:SetText(mode.deaths and "" or "Zauber nennt der Client hier nicht.")
    elseif #spells > shown then
        bd.note:SetText(string.format("und %d weitere Zauber", #spells - shown))
    else
        bd.note:SetText("")
    end
    local noteH = (bd.note:GetText() or "") ~= "" and 18 or 0
    bd.frame:SetHeight(90 + 20 + 8 + listH + noteH + 12)
    bd.prev:SetShown(rank ~= nil and rank > 1)
    bd.next:SetShown(rank ~= nil and sources ~= nil and rank < #sources)
end

-- Einen Spieler aufschluesseln. Noch einmal auf denselben: zu.
function DM.OpenBreakdown(w, src)
    if not src then return end
    BuildBreakdown()
    local guid, name = K.Plain(src.sourceGUID), K.Plain(src.name)
    if type(guid) ~= "string" then guid = nil end
    if type(name) ~= "string" then name = nil end
    if bd.frame:IsShown() and bd.win == w and SameSource(src, bd.guid, bd.name_) then
        bd.frame:Hide()
        return
    end
    bd.win, bd.guid, bd.name_ = w, guid, name
    bd.class = K.Plain(src.classFilename)
    bd.mode = w:Mode().key
    if w:Mode().deaths then bd.mode = "DamageDone" end
    BuildTabs()
    Place(w)
    bd.frame:Show()
    DM.RefreshBreakdown()
end

-- Zum naechsten oder vorigen Spieler der Liste.
function DM.StepBreakdown(dir)
    if not (bd and bd.sources and bd.rank) then return end
    local s = bd.sources[bd.rank + dir]
    if not s then return end
    local guid, name = K.Plain(s.sourceGUID), K.Plain(s.name)
    bd.guid = type(guid) == "string" and guid or nil
    bd.name_ = type(name) == "string" and name or nil
    bd.class = K.Plain(s.classFilename)
    DM.RefreshBreakdown()
end

function DM.Breakdown() return bd end

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
    sb:SetSize(70, 20)
    sb.text = K.NewText(sb, 10)
    sb.text:SetPoint("RIGHT", sb, "RIGHT", 0, 0)
    sb.text:SetTextColor(unpack(C.textMuted))
    if sb.RegisterForClicks then sb:RegisterForClicks("LeftButtonUp", "RightButtonUp") end
    sb:SetScript("OnClick", function(_, button) w:CycleSession(button == "RightButton") end)
    sb:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Zeitraum", 1, 1, 1)
        GameTooltip:AddLine("Aktueller Kampf, ganze Sitzung, frühere Kämpfe. Linksklick: weiter, Rechtsklick: zurück.", 0.7, 0.7, 0.75, true)
        GameTooltip:Show()
    end)
    sb:SetScript("OnLeave", function() GameTooltip:Hide() end)
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
    DM.RefreshBreakdown()
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
    { name = "Varek",    classFilename = "ROGUE",   totalAmount = 4940, amountPerSecond = 118, isLocalPlayer = true },
    { name = "Tamsin",   classFilename = "MAGE",    totalAmount = 4370, amountPerSecond = 104 },
    { name = "Orwen",    classFilename = "HUNTER",  totalAmount = 3650, amountPerSecond = 87 },
    { name = "Brunhild", classFilename = "WARRIOR", totalAmount = 2180, amountPerSecond = 52 },
    { name = "Liora",    classFilename = "PRIEST",  totalAmount = 380,  amountPerSecond = 9 },
}

-- Zauber zu den Beispielzeilen (nach Rang), ebenso erfunden.
DM.TEST_SPELLS = {
    { { spellID = 1752, totalAmount = 2100 }, { spellID = 2098, totalAmount = 1540 }, { spellID = 1943, totalAmount = 900 }, { spellID = 6603, totalAmount = 400 } },
    { { spellID = 133, totalAmount = 2600 }, { spellID = 2136, totalAmount = 1100 }, { spellID = 2120, totalAmount = 670 } },
    { { spellID = 75, totalAmount = 1800 }, { spellID = 3044, totalAmount = 1300 }, { spellID = 1978, totalAmount = 550 } },
    { { spellID = 78, totalAmount = 1200 }, { spellID = 6603, totalAmount = 980 } },
    { { spellID = 585, totalAmount = 380 } },
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
                  { type = "toggle", label = "Klassensymbole", key = "classIcons" })
            B:Row({ type = "toggle", label = "Anteil in Prozent", key = "showPercent",
                    description = "Nur wo der Client die Zahlen offen nennt – im Kampf oft erst danach." },
                  { type = "toggle", label = "Eigene Zeile immer zeigen", key = "pinSelf",
                    description = "Stehst du nicht unter den ersten Plätzen, nimmt deine Zeile den letzten Platz ein – mit deinem Rang." })
            B:Note("Maus über einer Zeile: die Zauber dieses Spielers mit Anteil. Klick auf den Zeitraum (oben rechts): aktueller Kampf, ganze Sitzung und frühere Kämpfe.")
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
