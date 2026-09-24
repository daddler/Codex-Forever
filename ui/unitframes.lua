--------------------------------------------------
-- WeintCodex :: Oberflaeche - Einheitenrahmen
--------------------------------------------------
-- Spieler, Ziel, Ziel des Ziels, Fokus, Begleiter. Jeder Rahmen ist ein
-- geschuetzter Knopf (SecureUnitButtonTemplate): Linksklick waehlt aus,
-- Rechtsklick oeffnet das Einheitenmenue - beides erledigt der Client,
-- nicht dieses Addon, und deshalb geht es auch im Kampf.
--
-- Die Blizzard-Rahmen, die ersetzt werden, ziehen in einen versteckten
-- Rahmen um und verlieren ihre Ereignisse. Das geschieht einmal beim
-- Anmelden und nie im Kampf; zurueck bekommt man sie mit einem
-- Neuladen, nachdem der Rahmen hier abgeschaltet wurde.
--
-- FOREVER-BESONDERHEIT (aus EllesmereUI, dort auf Client 1.60.1
-- gemessen): Kombopunkte gehoeren wie in Classic dem ZIEL. UnitPower
-- meldet beim Zielwechsel noch den Stand des alten Ziels, und es folgt
-- kein Ereignis, das das korrigiert - gelesen wird deshalb
-- GetComboPoints("player", "target"), wie es Blizzards eigener
-- klassischer Kombopunktrahmen tut.
--
-- Positionen: ui/layout.lua (das Cockpit aus docs/design/ui-2.0.md) -
-- Spieler und Ziel als Spiegelbild um die Mittelachse, Kombopunkte und
-- der eigene Zauberbalken mittig darunter.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIUnitFrames = {}

local UF = WeintCodex.UIUnitFrames
local K  = WeintCodex.UIKit
local CB = WeintCodex.UICastBar
local KEY = "unitframes"

local UNITS = { "player", "target", "targettarget", "focus", "pet" }
local LABELS = {
    player = "Spieler", target = "Ziel", targettarget = "Ziel des Ziels",
    focus = "Fokus", pet = "Begleiter",
}

-- Masse je Rahmen (UI 2.0): Spieler und Ziel 200 breit, Leben 24 +
-- Kraft 6 - im Grundmass des Spiels so gross wie im Entwurf 272 x 42 px.
local SHAPE = {
    player       = { w = 200, h = 24, p = 6, power = true,  cast = true,  left = "name",      right = "healthPercent", portrait = "3d" },
    target       = { w = 200, h = 24, p = 6, power = true,  cast = true,  left = "levelname", right = "healthPercent", portrait = "3d" },
    targettarget = { w = 90,  h = 18, p = 0, power = false, cast = false, left = "name", right = "healthPercent" },
    focus        = { w = 130, h = 18, p = 3, power = true,  cast = true,  left = "name", right = "healthPercent", portrait = "2d" },
    pet          = { w = 90,  h = 16, p = 3, power = true,  cast = false, left = "name", right = "healthPercent" },
}
for u, s in pairs(SHAPE) do s.pos = K.Layout("uf_" .. u) end

local defaults = {
    classColor    = true,
    reactionColor = true,
    healthColor   = K.ColorDefault("healthFallback"),
    bgColor       = K.ColorDefault("plateBg"),
    showBorder    = true,
    borderColor   = K.ColorDefault("plateBorder"),
    nameSize      = 12,
    textSize      = 12,
    castHeight    = 14,
    -- Der eigene Zauberbalken mittig ueber den Leisten, die Kombopunkte
    -- mittig unter der Figur (Cockpit). Aus: beides am Rahmen wie bisher.
    playerCastCentered = true,
    comboCentered      = true,
    castIcon      = true,
    castTimer     = true,
    castColor     = K.ColorDefault("cast"),
    castLocked    = K.ColorDefault("castLocked"),
    replacePlayerCast = true,
    comboPoints   = true,
    targetAuras   = true,
    auraSize      = 20,
    onlyOwnDebuffs = false,
}
for _, u in ipairs(UNITS) do
    local s = SHAPE[u]
    defaults[u .. "_enabled"] = true
    defaults[u .. "_width"]   = s.w
    defaults[u .. "_height"]  = s.h
    defaults[u .. "_power"]   = s.power
    defaults[u .. "_powerHeight"] = math.max(4, s.p)
    defaults[u .. "_left"]    = s.left
    defaults[u .. "_right"]   = s.right
    defaults[u .. "_portrait"] = s.portrait or "none"
    -- Das Ziel spiegelt den Spieler: Portraet rechts (wie in EllesmereUI).
    defaults[u .. "_portraitRight"] = (u == "target")
    if s.cast then defaults[u .. "_cast"] = true end
end

local function Opt(key) return K.Get(KEY, key) end

-- Blizzard-Rahmen verstecken: UIKit.HideBlizzard (ui/kit.lua), dieselbe
-- Stelle fuer Einheiten-, Gruppen- und alle anderen ersetzten Rahmen.
local HideBlizzard = K.HideBlizzard

local BLIZZARD = {
    player = { "PlayerFrame" },
    target = { "TargetFrame", "ComboFrame" },
    focus  = { "FocusFrame" },
    pet    = { "PetFrame" },
    -- Ziel des Ziels haengt im Spiel am Zielrahmen und geht mit ihm.
}

--------------------------------------------------
-- Aufbau
--------------------------------------------------

local frames = {}
UF.frames = frames

local function PowerColor(unit)
    local ptype, token
    if _G.UnitPowerType then ptype, token = _G.UnitPowerType(unit) end
    token, ptype = K.Plain(token), K.Plain(ptype)
    local pbc = _G.PowerBarColor
    -- Erst ueber den Namen ("ENERGY"), dann ueber die Nummer: in 6.0.0.5
    -- fand der Name keine Farbe, und die Energie des Schurken stand blau da.
    local c = pbc and ((token and pbc[token]) or (type(ptype) == "number" and pbc[ptype]))
    if type(c) == "table" and c.r then return c.r, c.g, c.b end
    local d = K.ColorDefault("powerFallback")
    return d.r, d.g, d.b
end

local function HealthColor(unit)
    if K.Bool(_G.UnitIsTapDenied and _G.UnitIsTapDenied(unit), false) then
        local c = K.ColorDefault("tapped")
        return c.r, c.g, c.b
    end
    if Opt("classColor") and K.Bool(_G.UnitIsPlayer and _G.UnitIsPlayer(unit), false) then
        local _, class = _G.UnitClass(unit)
        class = K.Plain(class)
        local cc = class and _G.RAID_CLASS_COLORS and _G.RAID_CLASS_COLORS[class]
        if cc then return cc.r, cc.g, cc.b end
    end
    if Opt("reactionColor") and not K.Bool(_G.UnitIsPlayer and _G.UnitIsPlayer(unit), false) then
        local r = K.Plain(_G.UnitReaction and _G.UnitReaction(unit, "player"))
        if type(r) == "number" then
            local name = (r <= 3) and "enemyInCombat" or (r == 4 and "neutral" or "friendly")
            local c = K.ColorDefault(name)
            return c.r, c.g, c.b
        end
    end
    local c = K.GetColor(KEY, "healthColor")
    return c.r, c.g, c.b
end

local function NameText(unit, kind)
    local name = _G.UnitName and (_G.UnitName(unit))
    if kind == "levelname" then
        local lvl = K.Plain(_G.UnitLevel and _G.UnitLevel(unit))
        local lt = (type(lvl) == "number" and lvl >= 0) and tostring(lvl) or "??"
        return lt, name
    end
    return nil, name
end

local function HealthText(unit, kind)
    if K.Bool(_G.UnitIsDeadOrGhost and _G.UnitIsDeadOrGhost(unit), false) then return "Tot" end
    if _G.UnitIsConnected and not K.Bool(_G.UnitIsConnected(unit), true) then return "Offline" end
    local cur = _G.UnitHealth and _G.UnitHealth(unit)
    local pct
    if _G.UnitHealthPercent and _G.CurveConstants and _G.CurveConstants.ScaleTo100 then
        local ok, v = pcall(_G.UnitHealthPercent, unit, true, _G.CurveConstants.ScaleTo100)
        if ok then pct = v end
    end
    if type(pct) == "nil" then
        local c = K.Plain(cur)
        local m = K.Plain(_G.UnitHealthMax and _G.UnitHealthMax(unit))
        if type(c) == "number" and type(m) == "number" and m > 0 then pct = c / m * 100 end
    end
    local num
    if type(cur) ~= "nil" and _G.AbbreviateNumbers then num = _G.AbbreviateNumbers(cur) end
    return nil, pct, num
end

-- Einen Textplatz fuellen, ohne einen geheimen Wert je zu vergleichen:
-- Formatieren darf der Client sie, verketten und pruefen nicht.
local function Fill(fs, unit, kind)
    if kind == "none" then fs:SetText("") return end
    if kind == "name" then
        local _, name = NameText(unit, kind)
        fs:SetText(name)
    elseif kind == "levelname" then
        local lvl, name = NameText(unit, kind)
        if type(name) ~= "nil" then fs:SetFormattedText("%s  %s", lvl, name) else fs:SetText(lvl) end
    elseif kind == "power" then
        local cur = _G.UnitPower and _G.UnitPower(unit)
        if type(cur) ~= "nil" and _G.AbbreviateNumbers then
            fs:SetText(_G.AbbreviateNumbers(cur))
        else
            fs:SetText(K.Plain(cur) and tostring(cur) or "")
        end
    else
        local state, pct, num = HealthText(unit, kind)
        if state then fs:SetText(state) return end
        if kind == "healthPercent" then
            if type(pct) ~= "nil" then fs:SetFormattedText("%d%%", pct) else fs:SetText("") end
        elseif kind == "healthNumber" then
            fs:SetText(num)
        elseif kind == "healthBoth" then
            if type(pct) ~= "nil" and type(num) ~= "nil" then
                fs:SetFormattedText("%s  %d%%", num, pct)
            else
                fs:SetText(num)
            end
        end
    end
end

local Frame = {}

-- Eigene Plaetze im Cockpit (ui/layout.lua) fuer den Zauberbalken des
-- Spielers und die Kombopunkte: ungeschuetzte Rahmen, die nur eine
-- Position tragen. Balken und Punkte bleiben Kinder ihres Einheiten-
-- rahmens (sichtbar nur mit ihm) und werden an den Platz gehaengt.
local holders = {}
local HOLDER = {
    uf_playercast = { label = "Eigener Zauberbalken", w = 186 },
    uf_combo      = { label = "Kombopunkte", w = 111, h = 6 },
}
local function Holder(key)
    local hf = holders[key]
    if hf then return hf end
    local def = HOLDER[key]
    hf = CreateFrame("Frame", nil, UIParent)
    hf:SetSize(def.w, def.h or 14)
    hf.WCShowForUnlock = function() end
    K.RegisterMover(hf, key, def.label, K.Layout(key))
    holders[key] = hf
    return hf
end
UF.Holder = Holder

local function Create(unit)
    local name = "WeintCodexUF_" .. unit
    local f = CreateFrame("Button", name, UIParent, "SecureUnitButtonTemplate")
    f.unit = unit
    f:SetAttribute("unit", unit)
    f:SetAttribute("*type1", "target")
    f:SetAttribute("*type2", "togglemenu")
    if f.RegisterForClicks then f:RegisterForClicks("AnyUp") end
    f:SetFrameStrata("LOW")

    local health = K.NewBar(f)
    f.health = health
    local hbg = health:CreateTexture(nil, "BACKGROUND")
    hbg:SetAllPoints(health)
    f.healthBg = hbg

    local power = K.NewBar(f, true)
    f.power = power
    local pbg = power:CreateTexture(nil, "BACKGROUND")
    pbg:SetAllPoints(power)
    f.powerBg = pbg

    f.border = K.Border(f, 1, 0, 0, 0, 1, "BORDER")
    f._shadow = K.Glow(f, { spread = 6, shadow = true })

    -- Portraet links im Rahmen: als 3D-Modell (wie in EllesmereUI) oder
    -- als Bild. Beides zeichnet der Client; Lua reicht nur die Einheit.
    local pf = CreateFrame("Frame", nil, f)
    pf.bg = pf:CreateTexture(nil, "BACKGROUND")
    pf.bg:SetAllPoints(pf)
    pf.bg:SetColorTexture(0, 0, 0, 1)
    pf.tex = pf:CreateTexture(nil, "ARTWORK")
    pf.tex:SetAllPoints(pf)
    pf.tex:SetTexCoord(0.15, 0.85, 0.15, 0.85)
    local okModel, model = pcall(CreateFrame, "PlayerModel", nil, pf)
    if okModel and type(model) == "table" then
        model:SetAllPoints(pf)
        pf.model = model
    end
    pf:Hide()
    f._portrait = pf

    local textHost = CreateFrame("Frame", nil, f)
    textHost:SetAllPoints(health)
    textHost:SetFrameLevel(health:GetFrameLevel() + 3)
    f.left = K.NewText(textHost)
    f.left:SetJustifyH("LEFT")
    f.left:SetWordWrap(false)
    f.right = K.NewText(textHost)
    f.right:SetJustifyH("RIGHT")
    f.right:SetWordWrap(false)

    f.raid = textHost:CreateTexture(nil, "OVERLAY")
    f.raid:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
    f.raid:SetSize(18, 18)
    f.raid:SetPoint("CENTER", f, "TOP", 0, 2)
    f.raid:Hide()

    if SHAPE[unit].cast then
        f._cast = CB.Create(f)
        f._cast:SetUnit(unit)
    end

    if unit == "target" then
        -- Kombopunkte: EIN Statusbalken mit Trennstrichen statt fuenf
        -- Einzelteilen - SetValue nimmt auch einen geheimen Wert, ein
        -- Vergleich "Punkt 3 an?" nicht.
        local cp = K.NewBar(f)
        cp:SetHeight(5)
        local col = WeintCodex.GameColors.comboPoint
        local tex = cp:GetStatusBarTexture()
        if tex then tex:SetVertexColor(col[1], col[2], col[3], 1) end
        local cbg = cp:CreateTexture(nil, "BACKGROUND")
        cbg:SetAllPoints(cp)
        cbg:SetColorTexture(0, 0, 0, 0.6)
        cp.ticks = {}
        cp:Hide()
        f._combo = cp

        -- Buffs und Debuffs ueber dem Rahmen: der gemeinsame Baustein
        -- (ui/auras.lua), derselbe wie auf Plaketten und Gruppenrahmen.
        local size = Opt("auraSize")
        f._auras = {
            HARMFUL = WeintCodex.UIAuras.Create(f, { filter = "HARMFUL", max = 8, size = size,
                spacing = 3, anchor = "BOTTOMLEFT", growth = "RIGHT", growthV = "UP", perRow = 8, timer = true }),
            HELPFUL = WeintCodex.UIAuras.Create(f, { filter = "HELPFUL", max = 8, size = size,
                spacing = 3, anchor = "BOTTOMLEFT", growth = "RIGHT", growthV = "UP", perRow = 8, timer = true }),
        }
        f._auras.HARMFUL:SetUnit(unit)
        f._auras.HELPFUL:SetUnit(unit)
    end

    for k, v in pairs(Frame) do f[k] = v end

    f:SetScript("OnEnter", function(self)
        if _G.UnitFrame_OnEnter then
            _G.UnitFrame_OnEnter(self)
        elseif _G.GameTooltip_SetDefaultAnchor then
            _G.GameTooltip_SetDefaultAnchor(GameTooltip, self)
            GameTooltip:SetUnit(self.unit)
            GameTooltip:Show()
        end
    end)
    f:SetScript("OnLeave", function(self)
        if _G.UnitFrame_OnLeave then _G.UnitFrame_OnLeave(self) else GameTooltip:Hide() end
    end)

    -- Ziel des Ziels meldet keine eigenen Ereignisse: der Client nennt
    -- seine Lebenspunkte nur auf Nachfrage. Fuenfmal je Sekunde, und nur
    -- solange der Rahmen zu sehen ist (versteckte Rahmen laufen nicht).
    if unit == "targettarget" then
        local acc = 0
        f:SetScript("OnUpdate", function(self, el)
            acc = acc + (el or 0)
            if acc < 0.2 then return end
            acc = 0
            self:Refresh()
        end)
    end
    return f
end

function Frame:UpdatePortrait()
    local pf, u = self._portrait, self.unit
    local kind = Opt(u .. "_portrait")
    if kind == "none" or not K.Bool(_G.UnitExists and _G.UnitExists(u), false) then return end
    -- Ausser Sichtweite zeigt das Modell nichts; dann das Bild.
    local visible = K.Bool(_G.UnitIsVisible and _G.UnitIsVisible(u), true)
    if kind == "3d" and pf.model and visible then
        pf.tex:Hide()
        pf.model:Show()
        pf.model:SetUnit(u)
        if pf.model.SetPortraitZoom then pf.model:SetPortraitZoom(1) end
        if pf.model.SetCamDistanceScale then pf.model:SetCamDistanceScale(1) end
    else
        if pf.model then pf.model:Hide() end
        pf.tex:Show()
        if _G.SetPortraitTexture then _G.SetPortraitTexture(pf.tex, u) end
    end
end

function Frame:Layout()
    local u = self.unit
    local w, h = Opt(u .. "_width"), Opt(u .. "_height")
    local showPower = Opt(u .. "_power")
    local ph = showPower and Opt(u .. "_powerHeight") or 0
    local total = h + (showPower and (ph + 1) or 0)

    K.AfterCombat(function() self:SetSize(w, total) end)

    -- Mit Portraet beginnen die Balken rechts davon; der Rahmen bleibt
    -- so breit wie eingestellt.
    local pf = self._portrait
    local inset = 0
    local right = Opt(u .. "_portraitRight")
    if Opt(u .. "_portrait") ~= "none" then
        inset = total + 1
        pf:ClearAllPoints()
        pf:SetPoint(right and "TOPRIGHT" or "TOPLEFT", self, right and "TOPRIGHT" or "TOPLEFT", 0, 0)
        pf:SetSize(total, total)
        pf:Show()
        self:UpdatePortrait()
    else
        pf:Hide()
    end

    self.health:ClearAllPoints()
    self.health:SetPoint("TOPLEFT", self, "TOPLEFT", right and 0 or inset, 0)
    self.health:SetPoint("TOPRIGHT", self, "TOPRIGHT", right and -inset or 0, 0)
    self.health:SetHeight(h)
    self.power:ClearAllPoints()
    self.power:SetPoint("TOPLEFT", self.health, "BOTTOMLEFT", 0, -1)
    self.power:SetPoint("TOPRIGHT", self.health, "BOTTOMRIGHT", 0, -1)
    self.power:SetHeight(math.max(1, ph))
    if showPower then self.power:Show() else self.power:Hide() end

    local bg = K.GetColor(KEY, "bgColor")
    self.healthBg:SetColorTexture(bg.r, bg.g, bg.b, 1)
    self.powerBg:SetColorTexture(bg.r * 0.7, bg.g * 0.7, bg.b * 0.7, 1)
    self.border:SetShown(Opt("showBorder"))
    local bc = K.GetColor(KEY, "borderColor")
    self.border:SetColor(bc.r, bc.g, bc.b, 1)

    K.SetFont(self.left, Opt("nameSize"))
    K.SetFont(self.right, Opt("textSize"))
    self.left:ClearAllPoints()
    self.left:SetPoint("LEFT", self.health, "LEFT", 5, 0)
    self.left:SetWidth(math.max(20, (w - inset) * 0.62))
    self.right:ClearAllPoints()
    self.right:SetPoint("RIGHT", self.health, "RIGHT", -5, 0)
    self.right:SetWidth(math.max(20, (w - inset) * 0.4))

    if self._cast then
        self._cast:ClearAllPoints()
        if u == "player" and Opt("playerCastCentered") then
            local hf = Holder("uf_playercast")
            hf:SetHeight(Opt("castHeight"))
            self._cast:SetPoint("TOPLEFT", hf, "TOPLEFT", 0, 0)
            self._cast:SetPoint("TOPRIGHT", hf, "TOPRIGHT", 0, 0)
        else
            self._cast:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -4)
            self._cast:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, -4)
        end
        self._cast:ApplyStyle({
            height = Opt("castHeight"), icon = Opt("castIcon"), timer = Opt("castTimer"),
            cast = K.GetColor(KEY, "castColor"), locked = K.GetColor(KEY, "castLocked"),
            bg = bg, border = Opt("showBorder"),
        })
        if not Opt(u .. "_cast") then self._cast:Hide() end
    end

    if self._combo then
        local cp = self._combo
        cp:ClearAllPoints()
        if Opt("comboCentered") then
            local hf = Holder("uf_combo")
            cp:SetPoint("TOPLEFT", hf, "TOPLEFT", 0, 0)
            cp:SetPoint("BOTTOMRIGHT", hf, "BOTTOMRIGHT", 0, 0)
        else
            cp:SetHeight(5)
            cp:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 3)
            cp:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", 0, 3)
        end
        cp._max = nil   -- Trennstriche neu setzen: die Breite hat sich geaendert
    end

    if self._auras then self:LayoutAuras() end
end

function Frame:Refresh()
    local u = self.unit
    if not K.Bool(_G.UnitExists and _G.UnitExists(u), false) and not self._unlockShown then return end

    local max = _G.UnitHealthMax and _G.UnitHealthMax(u)
    if type(max) ~= "nil" then self.health:SetMinMaxValues(0, max) end
    local cur = _G.UnitHealth and _G.UnitHealth(u)
    if type(cur) ~= "nil" then self.health:SetValue(cur) end
    K.PaintBar(self.health, HealthColor(u))

    if Opt(u .. "_power") then
        local pmax = _G.UnitPowerMax and _G.UnitPowerMax(u)
        if type(pmax) ~= "nil" then self.power:SetMinMaxValues(0, pmax) end
        local p = _G.UnitPower and _G.UnitPower(u)
        if type(p) ~= "nil" then self.power:SetValue(p) end
        K.PaintBar(self.power, PowerColor(u))
    end

    Fill(self.left, u, Opt(u .. "_left"))
    Fill(self.right, u, Opt(u .. "_right"))

    local idx = K.Plain(_G.GetRaidTargetIndex and _G.GetRaidTargetIndex(u))
    if type(idx) == "number" and idx > 0 and _G.SetRaidTargetIconTexture then
        _G.SetRaidTargetIconTexture(self.raid, idx)
        self.raid:Show()
    else
        self.raid:Hide()
    end

    if self._cast and Opt(u .. "_cast") then self._cast:Update() end
    if self._combo then self:UpdateCombo() end
    if self._auras then self:UpdateAuras() end
end

--------------------------------------------------
-- Kombopunkte (Ziel)
--------------------------------------------------

local function UsesCombo()
    local _, class = _G.UnitClass("player")
    if class == "ROGUE" then return true end
    if class == "DRUID" then
        -- Katzengestalt. Auf Forever gibt es keine Spezialisierungen, die
        -- das eingrenzen; GetShapeshiftFormID 1 ist die Katze.
        local form = _G.GetShapeshiftFormID and _G.GetShapeshiftFormID()
        return form == 1
    end
    return false
end

function Frame:UpdateCombo()
    local cp = self._combo
    if self._testShown then return end
    if not Opt("comboPoints") or not UsesCombo()
       or not K.Bool(_G.UnitExists and _G.UnitExists("target"), false) then
        cp:Hide()
        return
    end
    local cur
    if _G.GetComboPoints then
        cur = _G.GetComboPoints("player", "target")
    elseif _G.UnitPower and _G.Enum and _G.Enum.PowerType then
        cur = _G.UnitPower("player", _G.Enum.PowerType.ComboPoints)
    end
    local max = 5
    if _G.UnitPowerMax and _G.Enum and _G.Enum.PowerType then
        local m = K.Plain(_G.UnitPowerMax("player", _G.Enum.PowerType.ComboPoints))
        if type(m) == "number" and m > 0 then max = m end
    end
    if type(cur) == "nil" then cp:Hide() return end
    cp:SetMinMaxValues(0, max)
    cp:SetValue(cur)
    self:ComboTicks(max)
    cp:Show()
end

function Frame:ComboTicks(max)
    local cp = self._combo
    -- Trennstriche einmal je Hoechstwert (und nach jedem Layout) setzen.
    if cp._max ~= max then
        cp._max = max
        for _, t in ipairs(cp.ticks) do t:Hide() end
        local w = cp:GetWidth()
        if type(w) ~= "number" or w <= 0 then w = self:GetWidth() or 200 end
        for i = 1, max - 1 do
            local t = cp.ticks[i]
            if not t then
                t = cp:CreateTexture(nil, "OVERLAY")
                t:SetColorTexture(0, 0, 0, 1)
                t:SetWidth(2)
                cp.ticks[i] = t
            end
            t:ClearAllPoints()
            t:SetPoint("TOP", cp, "TOPLEFT", w * i / max, 0)
            t:SetPoint("BOTTOM", cp, "BOTTOMLEFT", w * i / max, 0)
            t:Show()
        end
    end
end

--------------------------------------------------
-- Auren (Ziel)
--------------------------------------------------
-- Der Blizzard-Zielrahmen zeigt Buffs und Debuffs. Wer ihn ersetzt und
-- sie weglaesst, nimmt dem Spieler etwas weg - also zeigt dieser hier
-- sie auch, oberhalb des Rahmens: eine Reihe Debuffs, darueber eine
-- Reihe Buffs. Gelesen und gezeichnet wird ueber ui/auras.lua (Auren-
-- Container des Spiels, wo es ihn gibt).
--------------------------------------------------

function Frame:LayoutAuras()
    local size = Opt("auraSize")
    local y0 = (self._combo and not Opt("comboCentered")) and 10 or 3
    local debuffFilter = Opt("onlyOwnDebuffs") and "HARMFUL|PLAYER" or "HARMFUL"
    local rows = {
        { self._auras.HARMFUL, debuffFilter, y0 },
        { self._auras.HELPFUL, "HELPFUL", y0 + size + 3 },
    }
    for _, r in ipairs(rows) do
        local obj = r[1]
        obj:ApplyLayout({ filter = r[2], max = 8, size = size, spacing = 3,
            anchor = "BOTTOMLEFT", growth = "RIGHT", growthV = "UP", perRow = 8, timer = true })
        obj:ClearAllPoints()
        obj:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, r[3])
    end
end

function Frame:UpdateAuras()
    local on = Opt("targetAuras") and true or false
    for _, obj in pairs(self._auras) do
        obj:SetShown(on)
        if on then obj:Refresh() end
    end
end

--------------------------------------------------
-- Entsperrmodus: einen Rahmen ohne Einheit trotzdem zeigen
--------------------------------------------------

function Frame:WCShowForUnlock(on)
    local u = self.unit
    self._unlockShown = on and true or nil
    K.AfterCombat(function()
        if on then
            if _G.UnregisterUnitWatch and u ~= "player" then _G.UnregisterUnitWatch(self) end
            self:Show()
            self.health:SetMinMaxValues(0, 1)
            self.health:SetValue(1)
            self.left:SetText(LABELS[u])
        else
            if _G.RegisterUnitWatch and u ~= "player" then _G.RegisterUnitWatch(self) end
            self:Refresh()
        end
    end)
end

--------------------------------------------------
-- Testmodus: Beispielwerte statt einer Einheit
--------------------------------------------------
-- ui/testmode.lua. Die Namen sind erfunden; Balken und Texte bekommen
-- feste Werte, bis der Testmodus endet. Nur ausserhalb des Kampfes: die
-- Rahmen sind geschuetzt (Zeigen, UnitWatch).
--------------------------------------------------

local TEST = {
    target       = { name = "Kobold-Geomant", level = "23", color = "enemyInCombat", hp = 0.58, power = 0.7, ptoken = "MANA" },
    targettarget = { name = "Brunhild", class = "WARRIOR", hp = 0.72 },
    focus        = { name = "Liora", class = "PRIEST", hp = 1, power = 0.76, ptoken = "MANA" },
    pet          = { name = "Wolf", color = "friendly", hp = 0.8, power = 0.5, ptoken = "FOCUS" },
}

local function TestColor(t)
    local cc = t.class and _G.RAID_CLASS_COLORS and _G.RAID_CLASS_COLORS[t.class]
    if cc then return cc.r, cc.g, cc.b end
    local c = K.ColorDefault(t.color or "healthFallback")
    return c.r, c.g, c.b
end

function Frame:ShowTest(on)
    local u = self.unit
    if u == "player" then
        if self._cast and Opt("player_cast") then self._cast:ShowPreview(on) end
        return
    end
    local t = TEST[u]
    if not t then return end
    if on then
        self._testShown = true
        if _G.UnregisterUnitWatch then _G.UnregisterUnitWatch(self) end
        self:Show()
        self.health:SetMinMaxValues(0, 1)
        self.health:SetValue(t.hp)
        K.PaintBar(self.health, TestColor(t))
        if Opt(u .. "_power") then
            self.power:SetMinMaxValues(0, 1)
            self.power:SetValue(t.power or 1)
            local pc = t.ptoken and _G.PowerBarColor and _G.PowerBarColor[t.ptoken]
            if type(pc) ~= "table" or not pc.r then pc = K.ColorDefault("powerFallback") end
            K.PaintBar(self.power, pc.r, pc.g, pc.b)
        end
        local left = Opt(u .. "_left")
        if left == "levelname" then
            self.left:SetFormattedText("%s  %s", t.level or "??", t.name)
        elseif left ~= "none" then
            self.left:SetText(t.name)
        else
            self.left:SetText("")
        end
        local right = Opt(u .. "_right")
        if right == "none" then self.right:SetText("") else self.right:SetFormattedText("%d%%", t.hp * 100) end
        if self._portrait.model then self._portrait.model:Hide() end
        if self._cast and Opt(u .. "_cast") then self._cast:ShowPreview(true) end
        if self._combo and Opt("comboPoints") and UsesCombo() then
            self._combo:SetMinMaxValues(0, 5)
            self._combo:SetValue(3)
            self:ComboTicks(5)
            self._combo:Show()
        end
    else
        self._testShown = nil
        if self._cast then self._cast:ShowPreview(false) end
        if _G.RegisterUnitWatch then _G.RegisterUnitWatch(self) end
        if not K.Bool(_G.UnitExists and _G.UnitExists(u), false) then self:Hide() end
        self:Refresh()
        self:UpdatePortrait()
        if self._combo then self:UpdateCombo() end
    end
end

function UF.ShowTest(on)
    K.AfterCombat(function()
        for _, f in pairs(frames) do f:ShowTest(on) end
    end)
end

--------------------------------------------------
-- Ereignisse
--------------------------------------------------

local events = CreateFrame("Frame")

local function RefreshUnit(unit, portrait)
    local f = frames[unit]
    if f and f:IsShown() then
        f:Refresh()
        if portrait then f:UpdatePortrait() end
    end
end

local HEALTH = { UNIT_HEALTH = true, UNIT_MAXHEALTH = true, UNIT_CONNECTION = true }
local POWER = { UNIT_POWER_UPDATE = true, UNIT_POWER_FREQUENT = true, UNIT_MAXPOWER = true, UNIT_DISPLAYPOWER = true }
local FULL = { UNIT_NAME_UPDATE = true, UNIT_LEVEL = true, UNIT_FACTION = true, UNIT_FLAGS = true }
local CAST = {
    UNIT_SPELLCAST_START = "update", UNIT_SPELLCAST_CHANNEL_START = "update",
    UNIT_SPELLCAST_CHANNEL_UPDATE = "update", UNIT_SPELLCAST_DELAYED = "update",
    UNIT_SPELLCAST_INTERRUPTIBLE = "update", UNIT_SPELLCAST_NOT_INTERRUPTIBLE = "update",
    UNIT_SPELLCAST_STOP = "stop", UNIT_SPELLCAST_CHANNEL_STOP = "stop",
    UNIT_SPELLCAST_INTERRUPTED = "failed", UNIT_SPELLCAST_FAILED = "failed",
}

local function OnEvent(_, event, unit)
    if event == "PLAYER_TARGET_CHANGED" then
        RefreshUnit("target", true)
        RefreshUnit("targettarget", true)
        return
    elseif event == "PLAYER_FOCUS_CHANGED" then
        RefreshUnit("focus", true)
        return
    elseif event == "UNIT_TARGET" then
        if unit == "target" then RefreshUnit("targettarget", true) end
        return
    elseif event == "UNIT_PET" then
        if unit == "player" then RefreshUnit("pet", true) end
        return
    elseif event == "UNIT_PORTRAIT_UPDATE" or event == "UNIT_MODEL_CHANGED" then
        if unit and frames[unit] then RefreshUnit(unit, true) end
        return
    elseif event == "PLAYER_ENTERING_WORLD" or event == "RAID_TARGET_UPDATE" then
        for u in pairs(frames) do RefreshUnit(u, event == "PLAYER_ENTERING_WORLD") end
        return
    elseif event == "UPDATE_SHAPESHIFT_FORM" then
        if frames.target then frames.target:UpdateCombo() end
        return
    end

    local f = unit and frames[unit]
    if not f or not f:IsShown() then
        -- Kombopunkte gehoeren dem Ziel, melden sich aber am Spieler.
        if unit == "player" and POWER[event] and frames.target then
            frames.target:UpdateCombo()
        end
        return
    end

    if HEALTH[event] or FULL[event] then
        f:Refresh()
    elseif POWER[event] then
        if Opt(unit .. "_power") then
            local pmax = _G.UnitPowerMax and _G.UnitPowerMax(unit)
            if type(pmax) ~= "nil" then f.power:SetMinMaxValues(0, pmax) end
            local p = _G.UnitPower and _G.UnitPower(unit)
            if type(p) ~= "nil" then f.power:SetValue(p) end
            if event == "UNIT_DISPLAYPOWER" then K.PaintBar(f.power, PowerColor(unit)) end
        end
        if Opt(unit .. "_left") == "power" or Opt(unit .. "_right") == "power" then
            Fill(f.left, unit, Opt(unit .. "_left"))
            Fill(f.right, unit, Opt(unit .. "_right"))
        end
        if unit == "player" and frames.target then frames.target:UpdateCombo() end
    elseif event == "UNIT_AURA" then
        -- Die Auren melden sich selbst (Container bzw. eigenes UNIT_AURA).
    else
        local kind = CAST[event]
        if kind and f._cast and Opt(unit .. "_cast") then
            if kind == "update" then f._cast:Update() else f._cast:Stop(kind == "failed") end
        end
    end
end

local function Register(name)
    return pcall(events.RegisterEvent, events, name)
end

--------------------------------------------------
-- Modul
--------------------------------------------------

local function Build()
    for _, u in ipairs(UNITS) do
        if Opt(u .. "_enabled") then
            local f = Create(u)
            frames[u] = f
            f:Layout()
            K.RegisterMover(f, "uf_" .. u, LABELS[u], SHAPE[u].pos, { secure = true })
            if u ~= "player" and _G.RegisterUnitWatch then
                K.AfterCombat(function() _G.RegisterUnitWatch(f) end)
            end
            for _, b in ipairs(BLIZZARD[u] or {}) do HideBlizzard(b) end
            f:Refresh()
        end
    end
    if frames.player and Opt("player_cast") and Opt("replacePlayerCast") then
        HideBlizzard("PlayerCastingBarFrame")
        HideBlizzard("CastingBarFrame")
    end
    -- Ruhe und Kampf (ui/presence.lua): der Spielerrahmen tritt ausserhalb
    -- des Kampfes zurueck, der Begleiter mit ihm.
    WeintCodex.UIPresence.Register("player", function() return { frames.player, frames.pet } end, "fade_player")
end

local function Enable()
    -- Geschuetzte Knoepfe anlegen und ihre Attribute setzen geht nur
    -- ausserhalb des Kampfes. Wer mitten im Kampf neu laedt, bekommt die
    -- Rahmen, sobald der Kampf vorbei ist - statt einer Fehlermeldung
    -- "Aktion blockiert" und halb gebauter Rahmen.
    K.AfterCombat(Build)

    for _, e in ipairs({
        "PLAYER_TARGET_CHANGED", "PLAYER_FOCUS_CHANGED", "UNIT_TARGET", "UNIT_PET",
        "PLAYER_ENTERING_WORLD", "RAID_TARGET_UPDATE", "UPDATE_SHAPESHIFT_FORM",
        "UNIT_PORTRAIT_UPDATE", "UNIT_MODEL_CHANGED",
    }) do Register(e) end
    for e in pairs(HEALTH) do Register(e) end
    for e in pairs(POWER) do Register(e) end
    for e in pairs(FULL) do Register(e) end
    for e in pairs(CAST) do Register(e) end
    events:SetScript("OnEvent", OnEvent)
end

local function OnSetting(key)
    for _, f in pairs(frames) do
        f:Layout()
        f:Refresh()
    end
end

local function px(v) return string.format("%d px", v) end

local TEXT_ITEMS = {
    { value = "none",          text = "Nichts" },
    { value = "name",          text = "Name" },
    { value = "levelname",     text = "Stufe und Name" },
    { value = "healthPercent", text = "Leben in %" },
    { value = "healthNumber",  text = "Leben als Zahl" },
    { value = "healthBoth",    text = "Leben: Zahl und %" },
    { value = "power",         text = "Kraft als Zahl" },
}

local function UnitPage(u)
    return { key = u, label = LABELS[u], build = function(B)
        local off = function() return not K.Get(KEY, u .. "_enabled") end
        B:Section(LABELS[u])
        B:Row({ type = "toggle", label = "Rahmen anzeigen", key = u .. "_enabled", reload = true,
                description = "Ersetzt den Blizzard-Rahmen. Wirkt nach dem Neuladen." },
              { type = "dropdown", label = "Porträt", key = u .. "_portrait", disabled = off, items = {
                    { value = "3d",   text = "3D-Modell" },
                    { value = "2d",   text = "Bild" },
                    { value = "none", text = "Keins" } } })
        B:Row({ type = "toggle", label = "Porträt rechts", key = u .. "_portraitRight",
                disabled = function() return off() or K.Get(KEY, u .. "_portrait") == "none" end },
              { type = "empty" })
        B:Row({ type = "slider", label = "Breite", key = u .. "_width", min = 60, max = 320, step = 1, format = px, disabled = off },
              { type = "slider", label = "Höhe", key = u .. "_height", min = 10, max = 80, step = 1, format = px, disabled = off })
        B:Row({ type = "toggle", label = "Kraftleiste", key = u .. "_power", disabled = off },
              { type = "slider", label = "Höhe der Kraftleiste", key = u .. "_powerHeight", min = 2, max = 20, step = 1, format = px,
                disabled = function() return off() or not K.Get(KEY, u .. "_power") end })
        B:Section("Texte")
        B:Row({ type = "dropdown", label = "Links", key = u .. "_left", items = TEXT_ITEMS, disabled = off },
              { type = "dropdown", label = "Rechts", key = u .. "_right", items = TEXT_ITEMS, disabled = off })
        if SHAPE[u].cast then
            B:Section("Zauberbalken")
            B:Row({ type = "toggle", label = "Zauberbalken", key = u .. "_cast", disabled = off },
                  u == "player"
                    and { type = "toggle", label = "Blizzard-Zauberleiste ersetzen", key = "replacePlayerCast", reload = true,
                          disabled = function() return off() or not K.Get(KEY, "player_cast") end }
                    or { type = "empty" })
            if u == "player" then
                B:Row({ type = "toggle", label = "Mittig über den Leisten", key = "playerCastCentered",
                        disabled = function() return off() or not K.Get(KEY, "player_cast") end,
                        description = "Aus: direkt unter dem Spielerrahmen." },
                      { type = "empty" })
            end
        end
        if u == "target" then
            B:Section("Auren und Kombopunkte")
            B:Row({ type = "toggle", label = "Buffs und Debuffs", key = "targetAuras", disabled = off },
                  { type = "slider", label = "Symbolgröße", key = "auraSize", min = 14, max = 36, step = 1, format = px,
                    disabled = function() return off() or not K.Get(KEY, "targetAuras") end })
            B:Row({ type = "toggle", label = "Nur eigene Debuffs", key = "onlyOwnDebuffs",
                    disabled = function() return off() or not K.Get(KEY, "targetAuras") end },
                  { type = "toggle", label = "Kombopunkte", key = "comboPoints", disabled = off,
                    description = "Schurken und Druiden in Katzengestalt." })
            B:Row({ type = "toggle", label = "Kombopunkte mittig", key = "comboCentered",
                    disabled = function() return off() or not K.Get(KEY, "comboPoints") end,
                    description = "Unter der Figur statt über dem Zielrahmen." },
                  { type = "empty" })
        end
    end }
end

local pages = {
    { key = "allgemein", label = "Allgemein", build = function(B)
        B:Section("Farben")
        B:Row({ type = "toggle", label = "Spieler in Klassenfarbe", key = "classColor" },
              { type = "toggle", label = "NPCs nach Gesinnung", key = "reactionColor",
                description = "Feindlich rot, neutral gelb, freundlich grün." })
        B:Row({ type = "color", label = "Lebensbalken sonst", key = "healthColor" },
              { type = "color", label = "Hintergrund", key = "bgColor" })
        B:Row({ type = "toggle", label = "Rand anzeigen", key = "showBorder" },
              { type = "color", label = "Randfarbe", key = "borderColor",
                disabled = function() return not K.Get(KEY, "showBorder") end })
        B:Section("Schrift")
        B:Row({ type = "slider", label = "Größe links", key = "nameSize", min = 8, max = 20, step = 1, format = px },
              { type = "slider", label = "Größe rechts", key = "textSize", min = 8, max = 20, step = 1, format = px })
        B:Section("Zauberbalken")
        B:Row({ type = "slider", label = "Höhe", key = "castHeight", min = 8, max = 30, step = 1, format = px },
              { type = "toggle", label = "Zaubersymbol", key = "castIcon" })
        B:Row({ type = "toggle", label = "Restzeit", key = "castTimer" }, { type = "empty" })
        B:Row({ type = "color", label = "Unterbrechbar", key = "castColor" },
              { type = "color", label = "Nicht unterbrechbar", key = "castLocked" })
        B:Note("Position: oben rechts im Fenster auf „Rahmen entsperren“ klicken und die Rahmen an ihren Platz ziehen.")
    end },
}
for _, u in ipairs(UNITS) do pages[#pages + 1] = UnitPage(u) end

K.Register({
    key = KEY, group = "ui", order = 20,
    title = "Einheitenrahmen",
    description = "Spieler, Ziel, Ziel des Ziels, Fokus und Begleiter als schlichte Balken — mit Zauberbalken, Zielauren und Kombopunkten.",
    defaults = defaults,
    Enable = Enable,
    OnSetting = OnSetting,
    pages = pages,
})
