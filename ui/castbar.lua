--------------------------------------------------
-- WeintCodex :: Oberflaeche - Zauberbalken
--------------------------------------------------
-- EIN Zauberbalken fuer Namensplaketten und Einheitenrahmen. Zwei
-- Stellen, die dieselbe Aufgabe verschieden loesen, laufen auseinander
-- (Designsystem: "keine zwei Komponenten fuer dieselbe Aufgabe").
--
-- WARUM DAS NICHT TRIVIAL IST. Ab Client 12.0 sind Beginn und Ende eines
-- gegnerischen Zaubers im Kampf "secret": man darf sie nicht voneinander
-- abziehen. Der Client bietet dafuer Dauerobjekte an
-- (UnitCastingDuration), die ein Statusbalken selbst abspielt
-- (SetTimerDuration). Ob unterbrechbar, ist ebenfalls geheim - gefaerbt
-- wird dann ueber C_CurveUtil.EvaluateColorValueFromBoolean, eingeblendet
-- ueber SetAlphaFromBoolean, beides ohne dass Lua den Wert je sieht.
--
-- Ob Forever diese Funktionen hat, weiss niemand hier. Deshalb gibt es
-- zu jedem modernen Weg den alten als Rueckfall (Millisekunden rechnen,
-- wenn sie NICHT geheim sind) - und wenn beides fehlt, steht der Name
-- des Zaubers ohne Fortschritt da, statt eines Balkens, der etwas
-- Falsches behauptet.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UICastBar = {}

local CB = WeintCodex.UICastBar
local K  = WeintCodex.UIKit

local function Direction(kind)
    local e = _G.Enum and _G.Enum.StatusBarTimerDirection
    if not e then return nil end
    return (kind == "channel") and e.RemainingTime or e.ElapsedTime
end

local function Duration(unit, channel)
    if channel then
        return _G.UnitChannelDuration and _G.UnitChannelDuration(unit)
    end
    return _G.UnitCastingDuration and _G.UnitCastingDuration(unit)
end

--------------------------------------------------
-- Aufbau
--------------------------------------------------
-- style = { height, icon = bool, timer = bool, fontSize,
--           cast = {r,g,b}, locked = {r,g,b}, failed = {r,g,b},
--           bg = {r,g,b}, shield = bool }
--------------------------------------------------

local Bar = {}

function CB.Create(parent)
    local f = CreateFrame("Frame", nil, parent)
    f:SetHeight(14)
    f:Hide()

    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(f)
    f._bg = bg

    local sb = CreateFrame("StatusBar", nil, f)
    sb:SetStatusBarTexture(K.BAR_TEXTURE)
    sb:SetMinMaxValues(0, 1)
    sb:SetValue(0)
    f._bar = sb

    local icon = f:CreateTexture(nil, "ARTWORK")
    if icon.SetTexCoord then icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) end
    f._icon = icon

    local text = sb:CreateFontString(nil, "OVERLAY")
    text:SetJustifyH("LEFT")
    text:SetWordWrap(false)
    f._text = text

    local timer = sb:CreateFontString(nil, "OVERLAY")
    timer:SetJustifyH("RIGHT")
    f._timer = timer

    -- Nicht unterbrechbar: ein heller Rahmen um den Balken. Keine
    -- Schildgrafik - ein geratener Texturpfad waere im Spiel ein gruenes
    -- Rechteck, und eine eigene Schildform liest sich bei 14 px nicht.
    f._lock = K.Border(sb, 1, 1, 1, 1, 0.9, "OVERLAY")
    f._lockAlpha = 0

    f._border = K.Border(f, 1, 0, 0, 0, 1, "BORDER")

    for k, v in pairs(Bar) do f[k] = v end
    f:SetScript("OnUpdate", f.OnTick)
    return f
end

function Bar:ApplyStyle(style)
    self._style = style
    local h = style.height or 14
    self:SetHeight(h)

    self._icon:ClearAllPoints()
    self._bar:ClearAllPoints()
    if style.icon then
        self._icon:SetSize(h, h)
        self._icon:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)
        self._icon:Show()
        self._bar:SetPoint("TOPLEFT", self, "TOPLEFT", h + 1, 0)
    else
        self._icon:Hide()
        self._bar:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)
    end
    self._bar:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 0)

    local fs = style.fontSize or math.max(8, math.floor(h * 0.62))
    K.SetFont(self._text, fs)
    K.SetFont(self._timer, fs)
    self._text:ClearAllPoints()
    self._text:SetPoint("LEFT", self._bar, "LEFT", 4, 0)
    self._text:SetPoint("RIGHT", self._bar, "RIGHT", style.timer and -34 or -4, 0)
    self._timer:ClearAllPoints()
    self._timer:SetPoint("RIGHT", self._bar, "RIGHT", -4, 0)
    if style.timer then self._timer:Show() else self._timer:Hide() end

    local b = style.bg or { r = 0.1, g = 0.1, b = 0.12 }
    self._bg:SetColorTexture(b.r, b.g, b.b, 0.9)
    self._border:SetShown(style.border ~= false)
end

--------------------------------------------------
-- Zustand
--------------------------------------------------

function Bar:SetUnit(unit)
    self._unit = unit
end

local function Color(style, key, fallbackName)
    local c = style and style[key]
    if type(c) == "table" then return c.r or 1, c.g or 1, c.b or 1 end
    local d = K.ColorDefault(fallbackName)
    return d.r, d.g, d.b
end

-- Faerbt nach "unterbrechbar", ohne den (moeglicherweise geheimen)
-- Wahrheitswert je in Lua anzufassen.
function Bar:PaintInterrupt(notInterruptible)
    local style = self._style
    local cr, cg, cb = Color(style, "cast", "cast")
    local lr, lg, lb = Color(style, "locked", "castLocked")
    local tex = self._bar:GetStatusBarTexture()
    local cu = _G.C_CurveUtil
    local nb = notInterruptible
    if type(nb) == "nil" then nb = false end

    if K.IsSecret(nb) then
        if cu and cu.EvaluateColorValueFromBoolean and tex then
            local ev = cu.EvaluateColorValueFromBoolean
            tex:SetVertexColor(ev(nb, lr, cr), ev(nb, lg, cg), ev(nb, lb, cb), 1)
        elseif tex then
            tex:SetVertexColor(cr, cg, cb, 1)
        end
        local showShield = not style or style.shield ~= false
        for _, t in ipairs({ self._lock.top, self._lock.bottom, self._lock.left, self._lock.right }) do
            if showShield and t.SetAlphaFromBoolean then
                t:SetAlphaFromBoolean(nb, 1, 0)
            else
                t:SetAlpha(0)
            end
        end
        return
    end

    if tex then
        if nb then tex:SetVertexColor(lr, lg, lb, 1) else tex:SetVertexColor(cr, cg, cb, 1) end
    end
    local a = (nb and (not style or style.shield ~= false)) and 1 or 0
    for _, t in ipairs({ self._lock.top, self._lock.bottom, self._lock.left, self._lock.right }) do
        t:SetAlpha(a)
    end
end

-- Liest den laufenden Zauber und stellt ihn dar. Ruft der Besitzer bei
-- jedem Zauberereignis der Einheit (START, CHANNEL_START, UPDATE,
-- DELAYED, (NOT_)INTERRUPTIBLE) und beim Zuweisen einer Einheit.
function Bar:Update()
    local unit = self._unit
    if not unit or not _G.UnitCastingInfo then self:Hide() return end

    local channel = false
    local name, text, texture, startMS, endMS, _, _, notInt = _G.UnitCastingInfo(unit)
    if type(name) == "nil" and _G.UnitChannelInfo then
        local n, t, tx, s, e, _, ni = _G.UnitChannelInfo(unit)
        name, text, texture, startMS, endMS, notInt = n, t, tx, s, e, ni
        channel = true
    end
    if type(name) == "nil" then
        if not self._holding then self:Hide() end
        return
    end

    self._holding = nil
    self._channel = channel
    self._icon:SetTexture(texture)
    -- Kein `text or name`: ein Wahrheitstest auf einem geheimen Text
    -- waere ein Fehler, `type` nicht.
    if type(text) ~= "nil" then self._text:SetText(text) else self._text:SetText(name) end
    self:PaintInterrupt(notInt)

    -- Fortschritt: modern ueber das Dauerobjekt, sonst gerechnet - aber nur
    -- mit Zahlen, mit denen gerechnet werden darf.
    self._duration, self._startMS, self._endMS = nil, nil, nil
    local dur = Duration(unit, channel)
    if dur and self._bar.SetTimerDuration then
        self._bar:SetMinMaxValues(0, 1)
        self._bar:SetTimerDuration(dur, nil, Direction(channel and "channel" or "cast"))
        self._duration = dur
    else
        local s, e = K.Plain(startMS), K.Plain(endMS)
        if type(s) == "number" and type(e) == "number" and e > s then
            self._startMS, self._endMS = s, e
            self._bar:SetMinMaxValues(0, e - s)
        else
            -- Weder Dauerobjekt noch rechenbare Zeiten: der Name steht,
            -- der Balken bleibt voll. Ein leerer Balken hiesse "faengt
            -- gerade an", und das weiss hier niemand.
            self._bar:SetMinMaxValues(0, 1)
            self._bar:SetValue(1)
        end
    end
    self._elapsed = 1
    self:Show()
end

-- Ende des Zaubers. `failed`: unterbrochen oder fehlgeschlagen - dann
-- steht der Balken kurz rot da, damit man sieht, DASS es geklappt hat.
function Bar:Stop(failed)
    if not self:IsShown() then return end
    if failed then
        local r, g, b = Color(self._style, "failed", "castFailed")
        local tex = self._bar:GetStatusBarTexture()
        if tex then tex:SetVertexColor(r, g, b, 1) end
        self._duration, self._startMS, self._endMS = nil, nil, nil
        self._bar:SetMinMaxValues(0, 1)
        self._bar:SetValue(1)
        self._text:SetText("Unterbrochen")
        self._timer:SetText("")
        self._holding = true
        local me = self
        if _G.C_Timer and _G.C_Timer.After then
            _G.C_Timer.After(0.6, function()
                if me._holding then me._holding = nil me:Hide() end
            end)
        end
        return
    end
    self._holding = nil
    self:Hide()
end

function Bar:OnTick(elapsed)
    if self._preview then return end
    self._elapsed = (self._elapsed or 0) + (elapsed or 0)

    -- Rechenweg: den Balken jede Bildwiederholung nachziehen.
    if self._startMS and self._endMS then
        local now = (_G.GetTime and _G.GetTime() or 0) * 1000
        local total = self._endMS - self._startMS
        local done = math.max(0, math.min(total, now - self._startMS))
        self._bar:SetValue(self._channel and (total - done) or done)
        if self._elapsed >= 0.1 then
            self._elapsed = 0
            self._timer:SetFormattedText("%.1f", math.max(0, (self._endMS - now) / 1000))
        end
        if now >= self._endMS + 250 and not self._holding then self:Hide() end
        return
    end

    -- Dauerobjekt: der Balken laeuft von selbst, nur die Zahl rechts
    -- wird zehnmal je Sekunde gesetzt (SetFormattedText nimmt auch einen
    -- geheimen Wert).
    if self._duration and self._elapsed >= 0.1 then
        self._elapsed = 0
        local ok, remaining = pcall(self._duration.GetRemainingDuration, self._duration)
        if ok and type(remaining) ~= "nil" then
            self._timer:SetFormattedText("%.1f", remaining)
        else
            self._timer:SetText("")
        end
    end
end

-- Fuer die Vorschau und den Entsperrmodus: ein stehender Beispielzauber.
function Bar:ShowPreview(on)
    self._preview = on and true or nil
    if not on then
        self._holding = nil
        self:Hide()
        return
    end
    self._duration, self._startMS, self._endMS = nil, nil, nil
    self._icon:SetTexture("Interface\\Icons\\Spell_Shadow_ShadowBolt")
    self._text:SetText("Schattenblitz")
    self._timer:SetText("1.4")
    self._bar:SetMinMaxValues(0, 1)
    self._bar:SetValue(0.6)
    self:PaintInterrupt(false)
    self:Show()
end
