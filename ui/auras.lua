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
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIAuras = {}

local A = WeintCodex.UIAuras
local K = WeintCodex.UIKit

--------------------------------------------------
-- Welcher Weg?
--------------------------------------------------

local engine   -- nil = noch nicht geprueft
function A.EngineAvailable()
    if engine ~= nil then return engine end
    engine = false
    local ca = _G.C_AddOns
    if not (ca and _G.AnchorUtil and _G.AnchorUtil.FlowDirection) then return false end
    if ca.IsAddOnLoaded and ca.LoadAddOn and not ca.IsAddOnLoaded("Blizzard_AuraContainer") then
        pcall(ca.LoadAddOn, "Blizzard_AuraContainer")
    end
    local ok, probe = pcall(CreateFrame, "AuraContainer", nil, UIParent, "CustomAuraContainerTemplate")
    if ok and type(probe) == "table" and type(probe.AddAuraGroup) == "function" then
        probe:Hide()
        engine = true
    end
    return engine
end

-- Fuer den Prueflauf: den Weg neu bestimmen lassen.
function A._ResetEngineProbe() engine = nil end

--------------------------------------------------
-- Ein Symbol
--------------------------------------------------

local function StyleIcon(button, size)
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
    local count = top:CreateFontString(nil, "OVERLAY")
    count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 2, -1)
    -- Die Schrift MUSS stehen, bevor das Spiel die Zahl setzt: eine
    -- FontString ohne Schrift ist in SetText ein harter Fehler.
    K.SetFont(count, math.max(8, math.floor(size * 0.5)))
    return icon, cd, count
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

local function BuildEngine(self)
    local o = self.opts
    local c = CreateFrame("AuraContainer", nil, self.parent, "CustomAuraContainerTemplate")
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
            local icon, cd, count = StyleIcon(button, size)
            pcall(button.SetMouseClickEnabled, button, false)
            pcall(button.SetIcon, button, icon)
            pcall(button.SetDurationCooldown, button, cd)
            pcall(button.SetApplicationCount, button, count, {})
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
    b.icon, b.cd, b.count = StyleIcon(b, self.opts.size)
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
    if cu and cu.GetAuraDuration and type(id) ~= "nil" and b.cd.SetCooldownFromDurationObject then
        local dur = cu.GetAuraDuration(unit, id)
        if type(dur) ~= "nil" then
            b.cd:SetCooldownFromDurationObject(dur)
            b.cd:Show()
        end
    else
        local d, e = K.Plain(aura.duration), K.Plain(aura.expirationTime)
        if type(d) == "number" and type(e) == "number" and d > 0 then
            b.cd:SetCooldown(e - d, d)
            b.cd:Show()
        end
    end
    b:Show()
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
        if ok and c then
            self.frame = c
        else
            self.engine = false
        end
    end
    if not self.engine then
        self.frame = CreateFrame("Frame", nil, parent)
        self.frame:SetSize(1, 1)
        self.buttons = {}
        self.events = CreateFrame("Frame")
        self.events:SetScript("OnEvent", function() self:Refresh() end)
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
        pcall(self.frame.SetUnit, self.frame, unit or "none")
        pcall(self.frame.UpdateAllAuras, self.frame)
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
        end
        self:Refresh()
        return
    end
    if old.size == new.size and old.spacing == new.spacing and old.filter == new.filter
       and old.anchor == new.anchor and old.growth == new.growth and old.growthV == new.growthV
       and old.perRow == new.perRow then
        pcall(self.frame.SetAuraGroupMaxFrameCount, self.frame, "wc", new.max)
        return
    end
    local ok, c = pcall(BuildEngine, self)
    if not (ok and c) then return end
    self.frame:Hide()
    pcall(self.frame.SetUnit, self.frame, "none")
    self.frame = c
    for _, p in ipairs(self.points) do c:SetPoint(unpack(p)) end
    if self.shown == false then c:Hide() end
    self:SetUnit(self.unit)
end
