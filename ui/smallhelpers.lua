--------------------------------------------------
-- WeintCodex :: Oberflaeche - Kleine Kampfhelfer
--------------------------------------------------
-- 1.0.7.0 (Wunsch nach dem Vergleich mit Naowh Forever, Verhalten
-- nachgebaut, eigener Code - dort "All Rights Reserved"):
--
--   Druiden-Mana (druidMana): in Baer- und Katzengestalt eine Leiste mit
--     dem Mana. Werte gehen ungelesen an die Leiste und an den Text (der
--     Client darf sie im Kampf geheim liefern) - WeintCodex rechnet nicht.
--   Fokus-Zauberleiste (focusCast): was dein Fokus gerade wirkt, mit Name
--     und Restzeit. Die Zeiten kommen aus UnitCastingInfo; sind sie geheim,
--     steht nur der Name, ohne geratene Leiste.
--   Tarnungserinnerung (stealthWarn): Schurke (und Druide in
--     Katzengestalt) ausserhalb des Kampfes und nicht getarnt - ein
--     Hinweis "Nicht getarnt". Nicht beim Reiten, Fliegen, Ausruhen, tot.
--
-- Schalter auf der Seite des Abklingzeitmanagers (Erweitert); verschieben
-- im Gestaltungsmodus.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UISmallHelpers = {}

local SH = WeintCodex.UISmallHelpers
local K = WeintCodex.UIKit
local C = WeintCodex.Colors

SH.BEAR, SH.CAT, SH.DIRE = 5, 1, 8

local function On(k)
    local OC = WeintCodex.UIOwnCooldowns
    return OC and OC.Get and OC.Get(k) and true or false
end
local function Class()
    if not _G.UnitClass then return nil end
    local _, c = _G.UnitClass("player")
    return K.Plain(c)
end
local function Form()
    return _G.GetShapeshiftFormID and K.Plain(_G.GetShapeshiftFormID()) or nil
end

local function Bar(name, label, w, h, key)
    local f = CreateFrame("Frame", name, UIParent)
    f:SetSize(w, h)
    f.bg = f:CreateTexture(nil, "BACKGROUND")
    f.bg:SetAllPoints(f)
    local bg = C.bgPanel
    f.bg:SetColorTexture(bg[1], bg[2], bg[3], 0.85)
    f.bar = K.NewBar(f)
    f.bar:SetAllPoints(f)
    K.Border(f, 1, 0, 0, 0, 1, "OVERLAY")
    local top = CreateFrame("Frame", nil, f)
    top:SetAllPoints(f)
    top:SetFrameLevel((f.bar:GetFrameLevel() or 1) + 2)
    f.text = K.NewText(top, 10)
    f.text:SetPoint("CENTER", f, "CENTER", 0, 0)
    f.text:SetShadowOffset(1, -1)
    f.left = K.NewText(top, 10)
    f.left:SetPoint("LEFT", f, "LEFT", 4, 0)
    f.left:SetShadowOffset(1, -1)
    f.right = K.NewText(top, 10)
    f.right:SetPoint("RIGHT", f, "RIGHT", -4, 0)
    f.right:SetShadowOffset(1, -1)
    f:SetAlpha(0)
    K.RegisterMover(f, key, label, K.Layout(key))
    return f
end

--------------------------------------------------
-- Druiden-Mana
--------------------------------------------------

local mana
function SH.ManaShown()
    if Class() ~= "DRUID" or not On("druidMana") then return false end
    local f = Form()
    return f == SH.BEAR or f == SH.CAT or f == SH.DIRE
end
function SH.UpdateMana()
    if not mana then return end
    local show = SH.ManaShown() or mana._unlock
    mana:SetAlpha(show and 1 or 0)
    if not show or not _G.UnitPower then return end
    local cur, max = _G.UnitPower("player", 0), _G.UnitPowerMax("player", 0)
    pcall(mana.bar.SetMinMaxValues, mana.bar, 0, max)
    pcall(mana.bar.SetValue, mana.bar, cur)
    pcall(mana.text.SetFormattedText, mana.text, "%d / %d", cur, max)
end

--------------------------------------------------
-- Fokus-Zauberleiste
--------------------------------------------------

local focus
function SH.UpdateFocus()
    if not focus then return end
    if focus._unlock then focus:SetAlpha(1) focus.left:SetText("Fokus") return end
    if not On("focusCast") or not _G.UnitCastingInfo then focus:SetAlpha(0) focus.cast = nil return end
    local name, _, _, st, en = _G.UnitCastingInfo("focus")
    local channel = false
    if type(name) == "nil" and _G.UnitChannelInfo then
        name, _, _, st, en = _G.UnitChannelInfo("focus")
        channel = true
    end
    if type(name) == "nil" then focus:SetAlpha(0) focus.cast = nil return end
    pcall(focus.left.SetText, focus.left, name)
    st, en = K.Plain(st), K.Plain(en)
    if type(st) == "number" and type(en) == "number" and en > st then
        focus.cast = { st = st / 1000, en = en / 1000, channel = channel }
        focus.bar:SetMinMaxValues(0, 1)
    else
        focus.cast = nil
        focus.bar:SetMinMaxValues(0, 1)
        focus.bar:SetValue(1)
        focus.right:SetText("")
    end
    focus:SetAlpha(1)
end
local function FocusTick()
    local c = focus and focus.cast
    if not c then return end
    local now = _G.GetTime()
    local p = (now - c.st) / (c.en - c.st)
    if p >= 1 then focus.cast = nil focus:SetAlpha(0) return end
    focus.bar:SetValue(c.channel and (1 - p) or p)
    focus.right:SetText(string.format("%.1f", c.en - now))
end

--------------------------------------------------
-- Tarnungserinnerung
--------------------------------------------------

local stealth
function SH.StealthMissing()
    if not On("stealthWarn") or K.InCombat() then return false end
    local cls = Class()
    if cls ~= "ROGUE" and not (cls == "DRUID" and Form() == SH.CAT) then return false end
    local function B(fn, ...) return fn and K.Bool(fn(...), false) or false end
    if B(_G.UnitIsDeadOrGhost, "player") or B(_G.IsMounted) or B(_G.UnitOnTaxi, "player") or B(_G.IsResting) then return false end
    return not B(_G.IsStealthed)
end
function SH.UpdateStealth()
    if not stealth then return end
    stealth:SetShown((SH.StealthMissing() or stealth._unlock) and true or false)
end

--------------------------------------------------
-- Start
--------------------------------------------------

local acc = 0
function SH.Enable()
    if mana then return end
    mana = Bar("WeintCodexDruidMana", "Druiden-Mana", 160, 10, "druidmana")
    local mc = WeintCodex.GameColors and WeintCodex.GameColors.mana or C.info
    K.PaintBar(mana.bar, mc[1], mc[2], mc[3])
    mana.WCShowForUnlock = function(self, on) self._unlock = on and true or nil SH.UpdateMana() end
    focus = Bar("WeintCodexFocusCast", "Fokus-Zauberleiste", 200, 16, "focuscast")
    local wc = C.warning or C.accent
    K.PaintBar(focus.bar, wc[1], wc[2], wc[3])
    focus.WCShowForUnlock = function(self, on) self._unlock = on and true or nil if not on then self:SetAlpha(0) end SH.UpdateFocus() end
    stealth = CreateFrame("Frame", "WeintCodexStealthWarn", UIParent)
    stealth:SetSize(160, 24)
    stealth.text = K.NewText(stealth, 16)
    stealth.text:SetPoint("CENTER", stealth, "CENTER", 0, 0)
    stealth.text:SetText("Nicht getarnt")
    local warn = C.warningBright or C.warning or C.accent
    stealth.text:SetTextColor(warn[1], warn[2], warn[3])
    stealth.text:SetShadowOffset(1, -1)
    stealth:Hide()
    stealth.WCShowForUnlock = function(self, on) self._unlock = on and true or nil SH.UpdateStealth() end
    K.RegisterMover(stealth, "stealthwarn", "Tarnungserinnerung", K.Layout("stealthwarn"))

    local ev = CreateFrame("Frame")
    for _, e in ipairs({ "UNIT_POWER_UPDATE", "UNIT_MAXPOWER", "UPDATE_SHAPESHIFT_FORM", "PLAYER_ENTERING_WORLD",
        "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_FAILED", "UNIT_SPELLCAST_INTERRUPTED",
        "UNIT_SPELLCAST_CHANNEL_START", "UNIT_SPELLCAST_CHANNEL_STOP", "PLAYER_FOCUS_CHANGED",
        "UPDATE_STEALTH", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "PLAYER_UPDATE_RESTING",
        "PLAYER_MOUNT_DISPLAY_CHANGED", "PLAYER_DEAD", "PLAYER_ALIVE", "PLAYER_UNGHOST" }) do
        pcall(ev.RegisterEvent, ev, e)
    end
    ev:SetScript("OnEvent", K.Measured("Kleine Helfer", function(_, event, unit)
        if event:find("^UNIT_SPELLCAST") then
            if unit == "focus" then SH.UpdateFocus() end
            return
        end
        if event == "PLAYER_FOCUS_CHANGED" then SH.UpdateFocus() return end
        if event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER" then
            if unit == "player" then SH.UpdateMana() end
            return
        end
        SH.UpdateMana()
        SH.UpdateStealth()
    end))
    ev:SetScript("OnUpdate", function(_, el)
        if focus.cast then FocusTick() end
        acc = acc + el
        if acc > 0.5 then acc = 0 SH.UpdateStealth() end
    end)
    SH.UpdateMana()
    SH.UpdateStealth()
end

do
    local m = K.Module("reminders")
    if m then
        local enable = m.Enable
        m.Enable = function(...)
            if enable then enable(...) end
            local ok, err = pcall(SH.Enable)
            if not ok then K.Report("kleine helfer", err) end
        end
    end
end
