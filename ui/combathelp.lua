--------------------------------------------------
-- WeintCodex :: Oberflaeche - Kampfhilfen am Abklingzeitmanager
--------------------------------------------------
-- 1.0.7.0 (Wunsch: "Ich will das alles haben" - Verhalten nach Naowh
-- Forever, KEIN Code: dessen Lizenz ist "All Rights Reserved"). Drei
-- Helfer, eingestellt auf der Seite des Abklingzeitmanagers (Erweitert),
-- gespeichert je Charakter wie dieser (OC.Get/OC.Set):
--
--   Abklingzeit an der Maus (cursorCd, ab Werk AUS - Wunsch "optional"):
--     drueckst du etwas, das noch abklingt, stehen Symbol, Name und
--     Restzeit kurz an der Maus. Erkannt aus UNIT_SPELLCAST_FAILED (eigene
--     Zauber sind nicht geheim) plus der Fehlermeldung "noch nicht bereit"
--     binnen 0,3 s. Die Uhr zeichnet das Spiel (Dauerobjekt), WeintCodex
--     liest sie nicht.
--   GCD-Leiste (gcd): die globale Abklingzeit als schmale Leiste. Forever
--     hat keinen eigenen GCD-Zauber - gelesen wird ein Grundzauber der
--     Klasse ohne eigene Abklingzeit, nur wenn der Client die Werte offen
--     nennt (sonst bleibt die Leiste leer, nie geraten).
--   Co-Tank (coTank): bist du Tank, zeigt ein kleiner Rahmen den anderen
--     Tank mit Leben und seinen Debuffs (Aurenbehaelter des Spiels).
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UICombatHelp = {}

local CH = WeintCodex.UICombatHelp
local K = WeintCodex.UIKit
local C = WeintCodex.Colors

local function OC() return WeintCodex.UIOwnCooldowns end
local function On(k) local o = OC() return o and o.Get and o.Get(k) and true or false end
local function Now() return _G.GetTime and _G.GetTime() or 0 end

local function PlayerClass()
    if not _G.UnitClass then return nil end
    local _, c = _G.UnitClass("player")
    c = K.Plain(c)
    return type(c) == "string" and c or nil
end

local function SpellName(id)
    local cs = _G.C_Spell
    if cs and cs.GetSpellName then
        local ok, n = pcall(cs.GetSpellName, id)
        if ok and not K.IsSecret(n) and type(n) == "string" then return n end
    end
    return nil
end
local function SpellTexture(id)
    local cs = _G.C_Spell
    if cs and cs.GetSpellTexture then
        local ok, t = pcall(cs.GetSpellTexture, id)
        if ok and not K.IsSecret(t) and t then return t end
    end
    return 134400
end

--------------------------------------------------
-- Abklingzeit an der Maus
--------------------------------------------------

CH.CURSOR_WINDOW = 0.3   -- Druck und Fehlermeldung gehoeren zusammen
CH.CURSOR_SHOW = 1.6     -- so lange steht es an der Maus

-- Meldungen des Spiels, die "klingt noch ab" heissen.
function CH.IsCooldownError(msg)
    if type(msg) ~= "string" or K.IsSecret(msg) then return false end
    for _, k in ipairs({ "ERR_ABILITY_COOLDOWN", "SPELL_FAILED_NOT_READY", "ERR_SPELL_COOLDOWN", "ERR_ITEM_COOLDOWN" }) do
        local g = _G.rawget(_G, k)
        if type(g) == "string" and g == msg then return true end
    end
    return false
end

local cursor
local lastFail, lastFailAt, lastErrAt = nil, -10, -10

local function BuildCursor()
    if cursor then return cursor end
    local f = CreateFrame("Frame", "WeintCodexCursorCooldown", UIParent)
    f:SetSize(36, 36)
    f:SetFrameStrata("TOOLTIP")
    f.icon = f:CreateTexture(nil, "ARTWORK")
    f.icon:SetAllPoints(f)
    f.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    K.Border(f, 1, 0, 0, 0, 1, "OVERLAY")
    f.cd = CreateFrame("Cooldown", nil, f, "CooldownFrameTemplate")
    f.cd:SetAllPoints(f)
    f.name = K.NewText(f, 12)
    f.name:SetPoint("LEFT", f, "RIGHT", 6, 0)
    f.name:SetShadowOffset(1, -1)
    f:Hide()
    f:SetScript("OnUpdate", function(self)
        if Now() > (self.until_ or 0) then self:Hide() return end
        local x, y = _G.GetCursorPosition()
        local s = UIParent:GetEffectiveScale()
        self:ClearAllPoints()
        self:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x / s + 18, y / s - 18)
    end)
    cursor = f
    return f
end

function CH.ShowCursor(id)
    if type(id) ~= "number" then return false end
    local cs = _G.C_Spell
    -- Nur die globale Abklingzeit: nichts zeigen (sie ist gleich vorbei).
    if cs and cs.GetSpellCooldown then
        local ok, info = pcall(cs.GetSpellCooldown, id)
        if ok and type(info) == "table" and info.isOnGCD == true then return false end
    end
    local f = BuildCursor()
    f.icon:SetTexture(SpellTexture(id))
    f.name:SetText(SpellName(id) or "")
    local shown = false
    if cs and cs.GetSpellCooldownDuration and f.cd.SetCooldownFromDurationObject then
        local ok, d = pcall(cs.GetSpellCooldownDuration, id)
        if ok and d then shown = pcall(f.cd.SetCooldownFromDurationObject, f.cd, d) end
    end
    if not shown and cs and cs.GetSpellCooldown then
        local ok, info = pcall(cs.GetSpellCooldown, id)
        if ok and type(info) == "table" then
            pcall(f.cd.SetCooldown, f.cd, info.startTime, info.duration)
        end
    end
    f.until_ = Now() + CH.CURSOR_SHOW
    f:Show()
    return true
end

function CH.CheckCursor(now)
    if not On("cursorCd") then return false end
    if lastFail and math.abs(lastFailAt - lastErrAt) <= CH.CURSOR_WINDOW and now - lastFailAt <= CH.CURSOR_WINDOW + 0.05 then
        local id = lastFail
        lastFail = nil
        return CH.ShowCursor(id)
    end
    return false
end

function CH.NoteFail(id, now)
    if K.IsSecret(id) or type(id) ~= "number" then return end
    lastFail, lastFailAt = id, now or Now()
    CH.CheckCursor(lastFailAt)
end
function CH.NoteError(msg, now)
    if not CH.IsCooldownError(msg) then return end
    lastErrAt = now or Now()
    CH.CheckCursor(lastErrAt)
end

--------------------------------------------------
-- GCD-Leiste
--------------------------------------------------

-- Grundzauber je Klasse ohne eigene Abklingzeit (Rang 1, Lehrerbestand).
CH.GCD_SPELLS = {
    WARRIOR = 6673,   -- Schlachtruf
    ROGUE   = 1752,   -- Finsterer Stoss
    HUNTER  = 1978,   -- Schlangenbiss
    MAGE    = 133,    -- Feuerball
    WARLOCK = 686,    -- Schattenblitz
    PRIEST  = 585,    -- Goettliche Pein
    DRUID   = 5176,   -- Zorn
    SHAMAN  = 403,    -- Blitzschlag
    PALADIN = 635,    -- Heiliges Licht
}

-- Startzauber (beim Lehrer nur hoehere Raenge) - load_test.lua laesst sie durch.
CH.GCD_STARTER = { [1752] = true, [133] = true, [585] = true, [686] = true, [5176] = true, [635] = true, [403] = true }

local gcd
local function BuildGcd()
    if gcd then return gcd end
    local f = CreateFrame("Frame", "WeintCodexGcdBar", UIParent)
    f:SetSize(160, 5)
    f.bar = K.NewBar(f, true)
    f.bar:SetAllPoints(f)
    f.bar:SetMinMaxValues(0, 1)
    f.bar:SetValue(0)
    local a = C.accent
    K.PaintBar(f.bar, a[1], a[2], a[3])
    f.bg = f:CreateTexture(nil, "BACKGROUND")
    f.bg:SetAllPoints(f)
    local bg = C.bgPanel
    f.bg:SetColorTexture(bg[1], bg[2], bg[3], 0.8)
    K.Border(f, 1, 0, 0, 0, 1, "OVERLAY")
    f.WCShowForUnlock = function(self, on) self._unlock = on and true or nil CH.UpdateGcd() end
    K.RegisterMover(f, "gcd", "GCD-Leiste", K.Layout("gcd"))
    f:SetAlpha(0)
    f:SetScript("OnUpdate", function(self)
        if not self.start then return end
        local p = (Now() - self.start) / self.dur
        if p >= 1 then
            self.start = nil
            self.bar:SetValue(0)
            if not self._unlock then self:SetAlpha(0) end
            return
        end
        self.bar:SetValue(1 - p)
    end)
    gcd = f
    return f
end

-- Start und Dauer der globalen Abklingzeit, nur wenn offen genannt.
function CH.ReadGcd()
    local id = CH.GCD_SPELLS[PlayerClass() or ""]
    local cs = _G.C_Spell
    if not (id and cs and cs.GetSpellCooldown) then return nil end
    local ok, info = pcall(cs.GetSpellCooldown, id)
    if not (ok and type(info) == "table") then return nil end
    local st, du = K.Plain(info.startTime), K.Plain(info.duration)
    if type(st) ~= "number" or type(du) ~= "number" then return nil end
    if du <= 0 or du > 2 then return nil end
    return st, du
end

function CH.UpdateGcd()
    if not gcd then return end
    if gcd._unlock then gcd:SetAlpha(1) gcd.bar:SetValue(0.6) return end
    if not On("gcd") then gcd.start = nil gcd:SetAlpha(0) return end
    local st, du = CH.ReadGcd()
    if st then
        gcd.start, gcd.dur = st, du
        gcd:SetAlpha(1)
    end
end

--------------------------------------------------
-- Co-Tank
--------------------------------------------------

local cotank
function CH.OtherTank()
    if not (_G.UnitGroupRolesAssigned and _G.GetNumGroupMembers) then return nil end
    local mine = K.Plain(_G.UnitGroupRolesAssigned("player"))
    if mine ~= "TANK" then return nil end
    local n = K.Plain(_G.GetNumGroupMembers()) or 0
    if type(n) ~= "number" or n < 2 then return nil end
    local raid = _G.IsInRaid and K.Bool(_G.IsInRaid(), false)
    for i = 1, raid and n or n - 1 do
        local u = (raid and "raid" or "party") .. i
        local r = K.Plain(_G.UnitGroupRolesAssigned(u))
        local me = _G.UnitIsUnit and K.Bool(_G.UnitIsUnit(u, "player"), false)
        if r == "TANK" and not me then return u end
    end
    return nil
end

local function BuildCoTank()
    if cotank then return cotank end
    local f = CreateFrame("Frame", "WeintCodexCoTank", UIParent)
    f:SetSize(150, 22)
    f.bg = f:CreateTexture(nil, "BACKGROUND")
    f.bg:SetAllPoints(f)
    local bg = C.bgPanel
    f.bg:SetColorTexture(bg[1], bg[2], bg[3], 0.9)
    f.hp = K.NewBar(f)
    f.hp:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
    f.hp:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, 1)
    local ok = C.success or C.accent
    K.PaintBar(f.hp, ok[1], ok[2], ok[3])
    K.Border(f, 1, 0, 0, 0, 1, "OVERLAY")
    local host = CreateFrame("Frame", nil, f)
    host:SetAllPoints(f)
    host:SetFrameLevel((f.hp:GetFrameLevel() or 1) + 2)
    f.name = K.NewText(host, 11)
    f.name:SetPoint("LEFT", f, "LEFT", 4, 0)
    f.name:SetShadowOffset(1, -1)
    f.label = K.NewText(host, 9)
    f.label:SetPoint("BOTTOMLEFT", f, "TOPLEFT", 0, 2)
    f.label:SetText("Co-Tank")
    f.debuffs = WeintCodex.UIAuras.Create(f, { filter = "HARMFUL", max = 6, size = 22, spacing = 2,
        anchor = "TOPLEFT", growth = "RIGHT", growthV = "DOWN", perRow = 6, timer = true })
    f.debuffs:SetPoint("TOPLEFT", f, "TOPRIGHT", 4, 0)
    f.WCShowForUnlock = function(self, on) self._unlock = on and true or nil CH.UpdateCoTank() end
    K.RegisterMover(f, "cotank", "Co-Tank", K.Layout("cotank"))
    f:SetAlpha(0)
    cotank = f
    return f
end

function CH.UpdateCoTank()
    if not cotank then return end
    local u = On("coTank") and CH.OtherTank() or nil
    if u ~= cotank.unit then
        cotank.unit = u
        cotank.debuffs:SetUnit(u or "none")
    end
    if u then
        cotank.name:SetText(_G.UnitName and _G.UnitName(u) or "")
        if _G.UnitHealthMax then
            pcall(cotank.hp.SetMinMaxValues, cotank.hp, 0, _G.UnitHealthMax(u))
            pcall(cotank.hp.SetValue, cotank.hp, _G.UnitHealth(u))
        end
        cotank:SetAlpha(1)
    elseif cotank._unlock then
        cotank.name:SetText("Co-Tank")
        cotank:SetAlpha(1)
    else
        cotank:SetAlpha(0)
    end
end

--------------------------------------------------
-- Ereignisse
--------------------------------------------------

local acc = 0
local function OnEvent(_, event, a1, _, a3)
    if event == "UNIT_SPELLCAST_FAILED" then
        if K.IsSecret(a1) or a1 ~= "player" then return end
        CH.NoteFail(a3, Now())
    elseif event == "UNIT_SPELLCAST_SENT" or event == "SPELL_UPDATE_COOLDOWN" then
        if event == "UNIT_SPELLCAST_SENT" and (K.IsSecret(a1) or a1 ~= "player") then return end
        CH.UpdateGcd()
    else
        CH.UpdateCoTank()
    end
end

function CH.Enable()
    if CH.enabled then return end
    CH.enabled = true
    BuildGcd()
    BuildCoTank()
    local ev = CreateFrame("Frame")
    for _, e in ipairs({ "UNIT_SPELLCAST_FAILED", "UI_ERROR_MESSAGE", "UNIT_SPELLCAST_SENT",
        "SPELL_UPDATE_COOLDOWN", "GROUP_ROSTER_UPDATE", "PLAYER_ROLES_ASSIGNED", "PLAYER_ENTERING_WORLD" }) do
        pcall(ev.RegisterEvent, ev, e)
    end
    ev:SetScript("OnEvent", function(self, event, ...)
        if event == "UI_ERROR_MESSAGE" then
            local _, msg = ...
            CH.NoteError(msg, Now())
            return
        end
        OnEvent(self, event, ...)
    end)
    -- Leben des Co-Tanks: ruhiger Takt, keine Tabelle je Lauf.
    ev:SetScript("OnUpdate", K.Measured("Kampfhilfen", function(_, el)
        acc = acc + el
        if acc < 0.2 then return end
        acc = 0
        if cotank and cotank.unit then CH.UpdateCoTank() end
    end))
    CH.UpdateCoTank()
end

-- An das Modul "Erinnerungen" haengen, wie der Abklingzeitmanager.
do
    local m = K.Module("reminders")
    if m then
        local enable = m.Enable
        m.Enable = function(...)
            if enable then enable(...) end
            local ok, err = pcall(CH.Enable)
            if not ok then K.Report("kampfhilfen", err) end
        end
    end
end
