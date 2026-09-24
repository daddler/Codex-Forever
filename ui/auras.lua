--------------------------------------------------
-- WeintCodex :: Oberflaeche - Auren (ein Baustein fuer alle)
--------------------------------------------------
-- Buffs und Debuffs auf Plaketten, am Zielrahmen und an Gruppenrahmen -
-- drei Stellen, EIN Baustein.
--
-- ZWEI WEGE, und der Client entscheidet, welcher geht:
--
--   Engine (Client 12.1+): Addons lesen Auren nicht mehr selbst. Man baut
--     einen "AuraContainer" des Spiels, sagt ihm Filter, Anzahl und
--     Anordnung, meldet Symbol, Uhr und Stapelzahl an - und das Spiel
--     fuellt sie, auch mit Werten, die Lua nie sehen darf. Auf diesem Weg
--     gibt es keine geheimen Werte, an denen etwas brechen koennte.
--     Vorbild: EllesmereUI (AuraKit), dort gegen den Forever-Client
--     gelaufen. Der Code ist eigener.
--
--   Alt: C_UnitAuras.GetAuraDataByIndex je Aura, mit Dauerobjekt fuer die
--     Uhr, wo es eins gibt. Nur, wenn es den Container nicht gibt. Jeder
--     Lesevorgang laeuft in pcall: ab 12.1 kann das Lesen einer Aura in
--     manchen Lagen ein harter Fehler sein, und ein Fehler hier soll die
--     Symbole verstecken, nicht den Rahmen.
--
-- Gewaehlt wird einmal, beim ersten Bedarf, und fuer alle gleich.
--
-- RESTZEIT ALS ZAHL (opts.timer): oben links am Symbol, wie in
-- EllesmereUI. Im Engine-Weg zaehlt das Spiel selbst (SetDurationText),
-- auch geheime Werte. Im alten Weg ein Takt je Objekt, zehnmal je
-- Sekunde, nur solange ein Symbol mit Ablauf zu sehen ist.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIAuras = {}

local A = WeintCodex.UIAuras
local K = WeintCodex.UIKit

--------------------------------------------------
-- Welcher Weg?
--------------------------------------------------

-- Was der Baustein im Spiel tatsaechlich tut - fuer /wcui und fuer
-- Fehlermeldungen aus dem Beta-Client. In 6.0.0.5 zeigten Plaketten und
-- Zielrahmen im Spiel KEINE Auren, und der Grund war von aussen nicht zu
-- sehen: jeder Schritt lief in pcall, und ein Fehlschlag verschwand still.
-- Jetzt wird der erste Fehlschlag je Schritt gemerkt und einmal gemeldet.
local stats = { engine = nil, built = 0, minimal = 0, legacy = 0, errors = {} }
A.stats = stats

local function Note(step, err)
    if err == nil or stats.errors[step] then return end
    stats.errors[step] = tostring(err)
    K.Report("auren", step .. ": " .. tostring(err))
end

local engine   -- nil = noch nicht geprueft
function A.EngineAvailable()
    if engine ~= nil then return engine end
    engine = false
    stats.engine = false
    local ca = _G.C_AddOns
    if not (ca and _G.AnchorUtil and _G.AnchorUtil.FlowDirection) then return false end
    if ca.IsAddOnLoaded and ca.LoadAddOn and not ca.IsAddOnLoaded("Blizzard_AuraContainer") then
        pcall(ca.LoadAddOn, "Blizzard_AuraContainer")
    end
    local ok, probe = pcall(CreateFrame, "AuraContainer", nil, UIParent, "CustomAuraContainerTemplate")
    if ok and type(probe) == "table" and type(probe.AddAuraGroup) == "function" then
        probe:Hide()
        engine = true
        stats.engine = true
    elseif not ok then
        stats.probeError = tostring(probe)
    end
    return engine
end

-- In Worten, fuer die Einstellungsseite.
function A.StatusText()
    if stats.engine == nil then return "Noch keine Auren angelegt." end
    local parts = {}
    if stats.engine then
        parts[#parts + 1] = string.format("Auren-Container des Spiels: %d angelegt", stats.built)
        if stats.minimal > 0 then parts[#parts + 1] = string.format("%d davon vereinfacht", stats.minimal) end
    else
        parts[#parts + 1] = "Auren-Container des Spiels nicht verfügbar"
            .. (stats.probeError and (" (" .. stats.probeError .. ")") or "")
    end
    if stats.legacy > 0 then parts[#parts + 1] = string.format("%d über den alten Weg", stats.legacy) end
    for step, err in pairs(stats.errors) do parts[#parts + 1] = step .. ": " .. err end
    return table.concat(parts, " · ")
end

-- Fuer den Prueflauf: den Weg neu bestimmen lassen.
function A._ResetEngineProbe() engine = nil end

--------------------------------------------------
-- Ein Symbol
--------------------------------------------------

local function StyleIcon(button, size, o)
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints(button)
    if icon.SetTexCoord then icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) end

    local cd = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
    cd:SetAllPoints(button)
    if cd.SetHideCountdownNumbers then cd:SetHideCountdownNumbers(true) end
    if cd.SetDrawEdge then cd:SetDrawEdge(false) end
    if cd.SetReverse then cd:SetReverse(true) end

    -- Rand und Zahl liegen ueber der Uhr und nehmen keine Maus: auf einer
    -- Plakette saesse sonst ein unsichtbares Klickfeld zwischen Zeiger und
    -- Ziel (in der Vorlage im Spiel gemessen: "mehrere Klicks, um das Ziel
    -- zu wechseln").
    local top = CreateFrame("Frame", nil, button)
    top:SetAllPoints(button)
    top:SetFrameLevel((cd:GetFrameLevel() or 1) + 2)
    top:EnableMouse(false)
    K.Border(top, 1, 0, 0, 0, 1, "OVERLAY")
    local count = K.NewText(top)
    count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 2, -1)
    -- Die Schrift MUSS stehen, bevor das Spiel die Zahl setzt: eine
    -- FontString ohne Schrift ist in SetText ein harter Fehler.
    K.SetFont(count, math.max(8, math.floor(size * 0.5)))

    local dur = K.NewText(top, math.max(9, math.floor(size * 0.46)))
    dur:SetPoint("TOPLEFT", button, "TOPLEFT", -3, 4)
    dur:SetJustifyH("LEFT")
    dur:SetShown(o and o.timer and true or false)
    return icon, cd, count, dur
end

-- Restzeit in Worten des Spiels: Sekunden als Zahl, ab einer Minute "2m",
-- ab einer Stunde "1h". Nur fuer offene Zahlen.
function A.FormatRemaining(sec)
    if type(sec) ~= "number" or sec <= 0 then return "" end
    if sec >= 3600 then return string.format("%dh", math.floor(sec / 3600 + 0.5)) end
    if sec >= 60 then return string.format("%dm", math.floor(sec / 60 + 0.5)) end
    if sec < 3 then return (string.format("%.1f", sec):gsub("%.", ",")) end
    return string.format("%d", math.floor(sec + 0.5))
end

--------------------------------------------------
-- Engine
--------------------------------------------------

local Obj = {}
Obj.__index = Obj

local function FlowDir(token)
    local FD = _G.AnchorUtil.FlowDirection
    if token == "LEFT" then return FD.Left end
    if token == "UP" then return FD.Up end
    if token == "DOWN" then return FD.Down end
    return FD.Right
end

local function Call(obj, names, ...)
    for _, n in ipairs(names) do
        local f = obj[n]
        if type(f) == "function" then return pcall(f, obj, ...) end
    end
    return false
end

local function BuildEngine(self, minimal)
    local o = self.opts
    local c = CreateFrame("AuraContainer", nil, self.parent, "CustomAuraContainerTemplate")
    -- Anker und Groesse VOR der ersten Gruppe: das Spiel arbeitet seine
    -- Auren in einem OnUpdate ab, das nur fuer einen zeichenbaren Rahmen
    -- anspringt - ohne Anker beim ersten Anlass blieb der Container leer
    -- (so beschreibt es EllesmereUI; bei uns bis 6.0.0.5 ohne Anker).
    c:SetPoint("CENTER", self.parent, "CENTER", 0, 0)
    c:SetSize(1, 1)
    Call(c, { "SetFlowLayoutAnchorPoint", "SetAuraLayoutAnchorPoint" }, o.anchor)
    Call(c, { "SetFlowLayoutGrowthDirection", "SetAuraLayoutGrowthDirection" },
        FlowDir(o.growth), FlowDir(o.growthV))
    Call(c, { "SetFlowLayoutMaximumLineSize", "SetAuraLayoutRowWidth" },
        o.perRow * (o.size + o.spacing))

    local size = o.size
    local sort = _G.AuraContainerSortMethod and _G.AuraContainerSortMethod.Default or nil
    c:AddAuraGroup("wc", o.filter, {
        maxFrameCount = o.max,
        sortMethod = sort,
        layout = { elementWidth = size, elementHeight = size,
                   elementSpacing = o.spacing, lineSpacing = o.spacing },
        initializeFrame = function(button)
            if minimal then
                -- Zweiter Versuch: nur Symbol und Uhr, nichts darum herum.
                local icon = button:CreateTexture(nil, "ARTWORK")
                icon:SetAllPoints(button)
                local okI, errI = pcall(button.SetIcon, button, icon)
                if not okI then Note("SetIcon", errI) end
                return
            end
            local icon, cd, count, dur = StyleIcon(button, size, o)
            pcall(button.SetMouseClickEnabled, button, false)
            local okI, errI = pcall(button.SetIcon, button, icon)
            if not okI then Note("SetIcon", errI) end
            local okC, errC = pcall(button.SetDurationCooldown, button, cd)
            if not okC then Note("SetDurationCooldown", errC) end
            local okA, errA = pcall(button.SetApplicationCount, button, count, {})
            if not okA then Note("SetApplicationCount", errA) end
            if o.timer then
                local okD, errD = pcall(button.SetDurationText, button, dur, {})
                if not okD then Note("SetDurationText", errD) end
            end
        end,
    })
    return c
end

--------------------------------------------------
-- Alter Weg
--------------------------------------------------

local function Place(self, frame, i)
    local o = self.opts
    local step = o.size + o.spacing
    local col = (i - 1) % o.perRow
    local row = math.floor((i - 1) / o.perRow)
    local dx = (o.growth == "LEFT") and -1 or 1
    local dy = (o.growthV == "DOWN") and -1 or 1
    frame:ClearAllPoints()
    frame:SetPoint(o.anchor, self.frame, o.anchor, col * step * dx, row * step * dy)
end

local function LegacyButton(self)
    local b = CreateFrame("Frame", nil, self.frame)
    b:SetSize(self.opts.size, self.opts.size)
    b.icon, b.cd, b.count, b.dur = StyleIcon(b, self.opts.size, self.opts)
    b:Hide()
    return b
end

local function PaintLegacy(b, unit, aura)
    b.icon:SetTexture(aura.icon)
    local cu = _G.C_UnitAuras
    local id = aura.auraInstanceID
    if cu and cu.GetAuraApplicationDisplayCount and type(id) ~= "nil" then
        b.count:SetText(cu.GetAuraApplicationDisplayCount(unit, id, 2, 99))
    else
        local n = K.Plain(aura.applications)
        b.count:SetText((type(n) == "number" and n > 1) and tostring(n) or "")
    end
    b.cd:Hide()
    b._exp, b._durObj = nil, nil
    if cu and cu.GetAuraDuration and type(id) ~= "nil" and b.cd.SetCooldownFromDurationObject then
        local dur = cu.GetAuraDuration(unit, id)
        if type(dur) ~= "nil" then
            b.cd:SetCooldownFromDurationObject(dur)
            b.cd:Show()
            b._durObj = dur
        end
    else
        local d, e = K.Plain(aura.duration), K.Plain(aura.expirationTime)
        if type(d) == "number" and type(e) == "number" and d > 0 then
            b.cd:SetCooldown(e - d, d)
            b.cd:Show()
            b._exp = e
        end
    end
    b.dur:SetText("")
    b:Show()
end

-- Die Zahl eines Symbols im alten Weg. Offene Zahlen rechnet Lua; eine
-- geheime Restzeit (Dauerobjekt) formatiert der Client selbst.
local function TickLegacy(b)
    if b._exp and _G.GetTime then
        b.dur:SetText(A.FormatRemaining(b._exp - _G.GetTime()))
    elseif b._durObj and b._durObj.GetRemainingDuration then
        local ok, rem = pcall(b._durObj.GetRemainingDuration, b._durObj)
        if ok and type(rem) ~= "nil" then
            local plain = K.Plain(rem)
            if type(plain) == "number" then
                b.dur:SetText(A.FormatRemaining(plain))
            else
                b.dur:SetFormattedText("%.0f", rem)
            end
        else
            b.dur:SetText("")
        end
    else
        b.dur:SetText("")
    end
end

local function AuraAt(unit, i, filter)
    local cu = _G.C_UnitAuras
    if cu and cu.GetAuraDataByIndex then return cu.GetAuraDataByIndex(unit, i, filter) end
    if _G.UnitAura then
        local name, icon, count, _, duration, expiration = _G.UnitAura(unit, i, filter)
        if type(name) ~= "nil" then
            return { icon = icon, applications = count, duration = duration, expirationTime = expiration }
        end
    end
    return nil
end

--------------------------------------------------
-- Oeffentlich
--------------------------------------------------
-- opts: { filter = "HARMFUL|PLAYER", max = 6, size = 20, spacing = 2,
--         anchor = "BOTTOMLEFT", growth = "RIGHT", growthV = "UP",
--         perRow = 6 }
-- Liefert ein Objekt mit :SetPoint(...), :SetUnit(unit), :Refresh(),
-- :SetShown(on), :ApplyLayout(opts).
--------------------------------------------------

local function Normalize(opts)
    local o = {}
    for k, v in pairs(opts or {}) do o[k] = v end
    o.filter  = o.filter or "HARMFUL"
    o.max     = o.max or 6
    o.size    = o.size or 20
    o.spacing = o.spacing or 2
    o.anchor  = o.anchor or "BOTTOMLEFT"
    o.growth  = o.growth or "RIGHT"
    o.growthV = o.growthV or "UP"
    o.perRow  = math.max(1, o.perRow or o.max)
    return o
end

function A.Create(parent, opts)
    local self = setmetatable({ parent = parent, opts = Normalize(opts), points = {} }, Obj)
    self.engine = A.EngineAvailable()
    if self.engine then
        local ok, c = pcall(BuildEngine, self)
        if not (ok and c) then
            Note("AddAuraGroup", c)
            ok, c = pcall(BuildEngine, self, true)
            if ok and c then stats.minimal = stats.minimal + 1 else Note("AddAuraGroup (vereinfacht)", c) end
        end
        if ok and c then
            self.frame = c
            stats.built = stats.built + 1
        else
            self.engine = false
        end
    end
    if not self.engine then
        stats.legacy = stats.legacy + 1
        self.frame = CreateFrame("Frame", nil, parent)
        self.frame:SetSize(1, 1)
        self.buttons = {}
        self.events = CreateFrame("Frame")
        self.events:SetScript("OnEvent", function() self:Refresh() end)
        local acc = 0
        self.ticker = function(_, el)
            acc = acc + (el or 0)
            if acc < 0.1 then return end
            acc = 0
            for _, b in ipairs(self.buttons) do
                if b:IsShown() then TickLegacy(b) end
            end
        end
    end
    return self
end

function Obj:SetPoint(...)
    self.points[#self.points + 1] = { ... }
    self.frame:SetPoint(...)
end

function Obj:ClearAllPoints()
    self.points = {}
    self.frame:ClearAllPoints()
end

function Obj:SetShown(on)
    self.shown = on and true or false
    if on then self.frame:Show() else self.frame:Hide() end
end

function Obj:SetUnit(unit)
    self.unit = unit
    if self.engine then
        local ok, err = pcall(self.frame.SetUnit, self.frame, unit or "none")
        if not ok then Note("SetUnit", err) end
        ok, err = pcall(self.frame.UpdateAllAuras, self.frame)
        if not ok then Note("UpdateAllAuras", err) end
        return
    end
    self.events:UnregisterAllEvents()
    if unit then
        if not pcall(self.events.RegisterUnitEvent, self.events, "UNIT_AURA", unit) then
            pcall(self.events.RegisterEvent, self.events, "UNIT_AURA")
        end
    end
    self:Refresh()
end

-- Alles neu lesen (Zielwechsel: dafuer gibt es kein UNIT_AURA).
function Obj:Refresh()
    if self.engine then
        pcall(self.frame.UpdateAllAuras, self.frame)
        return
    end
    local unit, o = self.unit, self.opts
    local shown = 0
    if unit and self.shown ~= false then
        local ok, err = pcall(function()
            for i = 1, 40 do
                if shown >= o.max then break end
                local aura = AuraAt(unit, i, o.filter)
                if not aura then break end
                shown = shown + 1
                local b = self.buttons[shown]
                if not b then
                    b = LegacyButton(self)
                    self.buttons[shown] = b
                end
                Place(self, b, shown)
                PaintLegacy(b, unit, aura)
            end
        end)
        if not ok then K.Report("auren", err) end
    end
    for i = shown + 1, #self.buttons do self.buttons[i]:Hide() end
    -- Die Zahlen laufen nur, solange es etwas zu zaehlen gibt.
    self.events:SetScript("OnUpdate", (o.timer and shown > 0) and self.ticker or nil)
    if o.timer then for i = 1, shown do TickLegacy(self.buttons[i]) end end
end

-- Groesse, Anzahl oder Filter geaendert. Die Engine kennt fuer die Groesse
-- eines Symbols nur den Wert beim Anlegen - dann wird der Container neu
-- gebaut (selten: nur wenn jemand am Regler zieht).
function Obj:ApplyLayout(opts)
    local old = self.opts
    local new = Normalize(opts)
    self.opts = new
    if not self.engine then
        for _, b in ipairs(self.buttons) do
            b:SetSize(new.size, new.size)
            K.SetFont(b.count, math.max(8, math.floor(new.size * 0.5)))
            K.SetFont(b.dur, math.max(9, math.floor(new.size * 0.46)))
            b.dur:SetShown(new.timer and true or false)
        end
        self:Refresh()
        return
    end
    if old.size == new.size and old.spacing == new.spacing and old.filter == new.filter
       and old.anchor == new.anchor and old.growth == new.growth and old.growthV == new.growthV
       and old.perRow == new.perRow and (old.timer and true or false) == (new.timer and true or false) then
        pcall(self.frame.SetAuraGroupMaxFrameCount, self.frame, "wc", new.max)
        return
    end
    local ok, c = pcall(BuildEngine, self)
    if not (ok and c) then
        Note("AddAuraGroup", c)
        ok, c = pcall(BuildEngine, self, true)
        if not (ok and c) then return end
    end
    self.frame:Hide()
    pcall(self.frame.SetUnit, self.frame, "none")
    self.frame = c
    -- Der neue Container steht schon mittig (BuildEngine); die Anker des
    -- Aufrufers ersetzen das, nicht ergaenzen es.
    if #self.points > 0 then c:ClearAllPoints() end
    for _, p in ipairs(self.points) do c:SetPoint(unpack(p)) end
    if self.shown == false then c:Hide() end
    self:SetUnit(self.unit)
end
