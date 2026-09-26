--------------------------------------------------
-- WeintCodex :: Oberflaeche - Gruppen- und Schlachtzugsrahmen
--------------------------------------------------
-- Zwei Kopfrahmen des Spiels (SecureGroupHeaderTemplate): einer fuer die
-- Gruppe, einer fuer den Schlachtzug. Welche Einheit in welchem Knopf
-- steht, entscheidet der Client - auch im Kampf, wenn jemand beitritt.
-- Klicken waehlt aus, Rechtsklick oeffnet das Menue; beides erledigt der
-- geschuetzte Knopf selbst.
--
-- FOREVER UND DIE SNIPPETS. EllesmereUI schaltet seine Schlachtzugsrahmen
-- im Forever-Beta-Client ab, weil dort der Uebersetzer fuer "Secure
-- Snippets" fehlt (loadstring_untainted). Diese Rahmen hier kommen ohne
-- aus:
--   * kein initialConfigFunction (das ist ein Snippet): die Knoepfe
--     werden beim Anmelden ALLE auf einmal angelegt (startingIndex-Trick)
--     und dann ausserhalb des Kampfes eingerichtet - Groesse, Klick-
--     Attribute, Aussehen. Im Kampf entsteht nie ein neuer Knopf.
--   * Sichtbarkeit ueber RegisterStateDriver (Makrobedingungen, kein
--     Snippet).
-- Ob das auf Forever wirklich laeuft, hat niemand hier geprueft.
--
-- WAS DER CLIENT VERSCHWEIGT. Lebenspunkte und Reichweite koennen im
-- Kampf geheim sein. Balken bekommen den Wert durchgereicht; die
-- Reichweite blendet ueber SetAlphaFromBoolean ab, ohne dass Lua sie je
-- sieht.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIGroupFrames = {}

local GF = WeintCodex.UIGroupFrames
local K  = WeintCodex.UIKit
local KEY = "groupframes"

local defaults = {
    partyEnabled = true,
    partyWidth = 120, partyHeight = 40, partySpacing = 4,
    partyShowPlayer = true,
    partyHorizontal = false,
    raidEnabled = true,
    raidWidth = 88, raidHeight = 40, raidSpacing = 3,

    classColor  = true,
    healthColor = K.ColorDefault("healthFallback"),
    bgColor     = K.ColorDefault("plateBg"),
    showBorder  = true,
    borderColor = K.ColorDefault("plateBorder"),
    nameSize    = 11,
    statusText  = "percent",   -- none | percent | deficit
    power       = true,
    powerHeight = 3,
    rangeAlpha  = 45,          -- Prozent ausser Reichweite
    aggroBorder = true,
    debuffs     = true,
    debuffSize  = 16,
    debuffMax   = 3,
    onlyDispellable = true,
    -- Seit 6.3.2.4 (Beta-Test: "muss etwas detaillierter werden"):
    healPrediction = true,   -- eingehende Heilung als heller Balken hinter dem Leben
    absorbs     = true,      -- Schilde als weisser Balken dahinter
    roleIcon    = true,      -- Tank / Heiler / Schaden oben links
    leaderIcon  = true,      -- Krone beim Gruppenleiter
    readyCheck  = true,      -- Haken / Kreuz / ? beim Bereitschaftscheck
    hitFlash    = true,      -- kurzes rotes Aufblitzen bei einem Treffer
}

local function Opt(k) return K.Get(KEY, k) end

--------------------------------------------------
-- Ein Knopf
--------------------------------------------------

local byUnit = {}      -- [unit] = { knopf, ... }
local allButtons = {}  -- jeder eingerichtete Knopf
GF.buttons = allButtons

local function Remap()
    wipe(byUnit)
    for _, b in ipairs(allButtons) do
        local u = b._wcUnit
        if u then
            byUnit[u] = byUnit[u] or {}
            table.insert(byUnit[u], b)
        end
    end
end

local function HealthColor(unit)
    if Opt("classColor") then
        local _, class = _G.UnitClass(unit)
        class = K.Plain(class)
        local cc = class and _G.RAID_CLASS_COLORS and _G.RAID_CLASS_COLORS[class]
        if cc then return cc.r, cc.g, cc.b end
    end
    local c = K.GetColor(KEY, "healthColor")
    return c.r, c.g, c.b
end

local function StatusText(fs, unit)
    if _G.UnitIsConnected and not K.Bool(_G.UnitIsConnected(unit), true) then
        fs:SetText("Offline") return
    end
    -- Was gleich passiert, vor dem Zustand: "Tot" allein verschweigt,
    -- dass schon jemand wiederbelebt.
    if K.Bool(_G.UnitHasIncomingResurrection and _G.UnitHasIncomingResurrection(unit), false) then
        fs:SetText("Wird belebt") return
    end
    local sm = _G.C_IncomingSummon
    if sm and sm.HasIncomingSummon and K.Bool(sm.HasIncomingSummon(unit), false) then
        fs:SetText("Beschwörung") return
    end
    if K.Bool(_G.UnitIsGhost and _G.UnitIsGhost(unit), false) then fs:SetText("Geist") return end
    if K.Bool(_G.UnitIsDead and _G.UnitIsDead(unit), false) then fs:SetText("Tot") return end
    local mode = Opt("statusText")
    if mode == "percent" then
        if _G.UnitHealthPercent and _G.CurveConstants and _G.CurveConstants.ScaleTo100 then
            local ok, v = pcall(_G.UnitHealthPercent, unit, true, _G.CurveConstants.ScaleTo100)
            if ok and type(v) ~= "nil" then fs:SetFormattedText("%d%%", v) return end
        end
        local c = K.Plain(_G.UnitHealth and _G.UnitHealth(unit))
        local m = K.Plain(_G.UnitHealthMax and _G.UnitHealthMax(unit))
        if type(c) == "number" and type(m) == "number" and m > 0 then
            fs:SetFormattedText("%d%%", c / m * 100)
        else
            fs:SetText("")
        end
    elseif mode == "deficit" then
        -- Fehlende Lebenspunkte. Rechnen darf Lua nur mit offenen Zahlen;
        -- mit UnitHealthMissing rechnet der Client selbst.
        local missing
        if _G.UnitHealthMissing then
            missing = _G.UnitHealthMissing(unit)
        else
            local c = K.Plain(_G.UnitHealth and _G.UnitHealth(unit))
            local m = K.Plain(_G.UnitHealthMax and _G.UnitHealthMax(unit))
            if type(c) == "number" and type(m) == "number" then missing = m - c end
        end
        local plain = K.Plain(missing)
        if type(missing) == "nil" or (type(plain) == "number" and plain <= 0) then
            fs:SetText("")
        elseif _G.AbbreviateNumbers then
            fs:SetFormattedText("-%s", _G.AbbreviateNumbers(missing))
        else
            fs:SetText("")
        end
    else
        fs:SetText("")
    end
end

local Btn = {}

function Btn:Layout(w, h)
    local c = self._wc
    local ph = Opt("power") and Opt("powerHeight") or 0
    c.health:ClearAllPoints()
    c.health:SetPoint("TOPLEFT", c, "TOPLEFT", 0, 0)
    c.health:SetPoint("BOTTOMRIGHT", c, "BOTTOMRIGHT", 0, ph > 0 and (ph + 1) or 0)
    c.power:ClearAllPoints()
    c.power:SetPoint("BOTTOMLEFT", c, "BOTTOMLEFT", 0, 0)
    c.power:SetPoint("BOTTOMRIGHT", c, "BOTTOMRIGHT", 0, 0)
    c.power:SetHeight(math.max(1, ph))
    if ph > 0 then c.power:Show() else c.power:Hide() end

    local bg = K.GetColor(KEY, "bgColor")
    c.bg:SetColorTexture(bg.r, bg.g, bg.b, 1)
    c.border:SetShown(Opt("showBorder"))
    local bc = K.GetColor(KEY, "borderColor")
    c.border:SetColor(bc.r, bc.g, bc.b, 1)

    K.SetFont(c.name, Opt("nameSize"))
    K.SetFont(c.status, math.max(8, Opt("nameSize") - 1))
    c.name:SetWidth(math.max(20, w - 8))
    c.status:SetWidth(math.max(20, w - 8))

    -- Heilung und Schild: so breit wie der Lebensbalken, links an der
    -- Kante seiner Fuellung. Wie weit sie reichen, rechnet der Client
    -- (Wert / Hoechstwert) - Lua addiert nie geheime Zahlen. Was ueber
    -- den Balken hinausragt, schneidet die Klammer ab.
    c.clip:ClearAllPoints()
    c.clip:SetAllPoints(c.health)
    for _, bar in ipairs({ c.heal, c.absorb }) do bar:SetWidth(math.max(1, w)) end
    local hc, ac = WeintCodex.GameColors.healPredict, WeintCodex.GameColors.absorb
    c.heal:SetStatusBarColor(hc[1], hc[2], hc[3], hc[4])
    c.absorb:SetStatusBarColor(ac[1], ac[2], ac[3], ac[4])

    local size = Opt("debuffSize")
    c.debuffs:ApplyLayout({ filter = Opt("onlyDispellable") and "HARMFUL|RAID" or "HARMFUL",
        max = Opt("debuffMax"), size = size, spacing = 1, anchor = "BOTTOMRIGHT",
        growth = "LEFT", growthV = "UP", perRow = Opt("debuffMax") })
    c.debuffs:ClearAllPoints()
    c.debuffs:SetPoint("BOTTOMRIGHT", c, "BOTTOMRIGHT", -2, ph + 3)
    c.debuffs:SetShown(Opt("debuffs"))
end

function Btn:Refresh()
    local unit = self._wcUnit
    local c = self._wc
    if not unit or not K.Bool(_G.UnitExists and _G.UnitExists(unit), false) then return end

    local max = _G.UnitHealthMax and _G.UnitHealthMax(unit)
    if type(max) ~= "nil" then c.health:SetMinMaxValues(0, max) end
    local cur = _G.UnitHealth and _G.UnitHealth(unit)
    if type(cur) ~= "nil" then c.health:SetValue(cur) end
    if K.Bool(_G.UnitIsConnected and _G.UnitIsConnected(unit), true) then
        K.PaintBar(c.health, HealthColor(unit))
    else
        local g = K.ColorDefault("tapped")
        K.PaintBar(c.health, g.r, g.g, g.b)
    end

    if Opt("power") then
        local pmax = _G.UnitPowerMax and _G.UnitPowerMax(unit)
        if type(pmax) ~= "nil" then c.power:SetMinMaxValues(0, pmax) end
        local p = _G.UnitPower and _G.UnitPower(unit)
        if type(p) ~= "nil" then c.power:SetValue(p) end
        local ptype, token
        if _G.UnitPowerType then ptype, token = _G.UnitPowerType(unit) end
        token, ptype = K.Plain(token), K.Plain(ptype)
        local pbc = _G.PowerBarColor
        local pc = pbc and ((token and pbc[token]) or (type(ptype) == "number" and pbc[ptype]))
        if type(pc) == "table" and pc.r then K.PaintBar(c.power, pc.r, pc.g, pc.b) end
    end

    c.name:SetText(_G.UnitName and (_G.UnitName(unit)))
    StatusText(c.status, unit)

    self:UpdatePrediction()
    self:UpdateRole()
    self:UpdateReady()

    local idx = K.Plain(_G.GetRaidTargetIndex and _G.GetRaidTargetIndex(unit))
    if type(idx) == "number" and idx > 0 and _G.SetRaidTargetIconTexture then
        _G.SetRaidTargetIconTexture(c.raid, idx)
        c.raid:Show()
    else
        c.raid:Hide()
    end
    self:UpdateThreat()
end

function Btn:UpdatePrediction()
    local c, unit = self._wc, self._wcUnit
    if not unit then return end
    local max = _G.UnitHealthMax and _G.UnitHealthMax(unit)
    local function Fill(bar, on, value)
        if not on or type(max) == "nil" or type(value) == "nil" then bar:Hide() return end
        bar:SetMinMaxValues(0, max)
        bar:SetValue(value)
        bar:Show()
    end
    Fill(c.heal, Opt("healPrediction"), _G.UnitGetIncomingHeals and _G.UnitGetIncomingHeals(unit))
    Fill(c.absorb, Opt("absorbs"), _G.UnitGetTotalAbsorbs and _G.UnitGetTotalAbsorbs(unit))
end

local ROLE = {
    TANK    = { tex = "icon_tank",   color = "roleTank" },
    HEALER  = { tex = "icon_plus",   color = "roleHeal" },
    DAMAGER = { tex = "icon_dps",    color = "roleDps" },
}

-- Rolle oben links, Krone daneben. Keine Rolle (nicht zugewiesen): kein
-- Symbol - nie ein geratenes.
function Btn:UpdateRole()
    local c, unit = self._wc, self._wcUnit
    local role = unit and Opt("roleIcon") and K.Plain(_G.UnitGroupRolesAssigned and _G.UnitGroupRolesAssigned(unit))
    local r = type(role) == "string" and ROLE[role]
    if r then
        c.role:SetTexture(K.MEDIA .. r.tex)
        local col = WeintCodex.GameColors[r.color]
        c.role:SetVertexColor(col[1], col[2], col[3], 1)
        c.role:Show()
    else
        c.role:Hide()
    end
    local lead = unit and Opt("leaderIcon") and K.Bool(_G.UnitIsGroupLeader and _G.UnitIsGroupLeader(unit), false)
    c.leader:ClearAllPoints()
    if r then
        c.leader:SetPoint("LEFT", c.role, "RIGHT", 1, 0)
    else
        c.leader:SetPoint("TOPLEFT", c, "TOPLEFT", 2, -2)
    end
    c.leader:SetShown(lead and true or false)
end

-- Bereitschaftscheck: Haken, Kreuz oder "?" in der Mitte. Nach dem Ende
-- bleibt das Ergebnis ein paar Sekunden stehen.
local readyDone = false
function Btn:UpdateReady()
    local c, unit = self._wc, self._wcUnit
    local st = unit and Opt("readyCheck") and K.Plain(_G.GetReadyCheckStatus and _G.GetReadyCheckStatus(unit))
    c.readyText:Hide()
    if st == "ready" or st == "notready" then
        c.ready:SetTexture(K.MEDIA .. (st == "ready" and "icon_check" or "icon_close"))
        local col = WeintCodex.GameColors[st == "ready" and "readyYes" or "readyNo"]
        c.ready:SetVertexColor(col[1], col[2], col[3], 1)
        c.ready:Show()
    elseif st == "waiting" then
        c.ready:Hide()
        local col = WeintCodex.GameColors.readyWait
        c.readyText:SetTextColor(col[1], col[2], col[3], 1)
        c.readyText:Show()
    elseif not readyDone then
        c.ready:Hide()
    end
end

-- Ein Treffer: der Knopf blitzt kurz rot auf. UNIT_COMBAT nennt nur, DASS
-- getroffen wurde; die Zahl wird nicht gelesen (sie kann geheim sein).
function Btn:Flash()
    local c = self._wc
    if not Opt("hitFlash") then return end
    c.flash:SetAlpha(1)
    c.flash:SetShown(true)
    c._flashLeft = 0.35
end

function Btn:UpdateThreat()
    local c = self._wc
    if not Opt("aggroBorder") or not _G.UnitThreatSituation or not self._wcUnit then
        c.aggro:SetShown(false)
        return
    end
    local st = K.Plain(_G.UnitThreatSituation(self._wcUnit))
    c.aggro:SetShown(type(st) == "number" and st >= 2)
end

-- Reichweite: der einzige Wert, der ohne Ereignis kommt (siehe Takt).
function Btn:UpdateRange()
    if self._wcTest then return end   -- Beispielknopf: Deckkraft setzt der Testmodus
    local c, unit = self._wc, self._wcUnit
    if not unit or not _G.UnitInRange then c:SetAlpha(1) return end
    local out = (Opt("rangeAlpha") or 45) / 100
    if K.Bool(_G.UnitIsUnit and _G.UnitIsUnit(unit, "player"), false) then c:SetAlpha(1) return end
    local inRange, checked = _G.UnitInRange(unit)
    if K.IsSecret(inRange) then
        if c.SetAlphaFromBoolean then c:SetAlphaFromBoolean(inRange, 1, out) else c:SetAlpha(1) end
        return
    end
    -- "nicht geprueft" heisst nicht "ausser Reichweite": dann voll.
    if checked == false or K.IsSecret(checked) then c:SetAlpha(1) return end
    c:SetAlpha(inRange and 1 or out)
end

local function Style(b)
    if b._wc then return end
    -- Alles Sichtbare haengt an einem ungeschuetzten Kindrahmen. Den darf
    -- Lua auch im Kampf abblenden; den geschuetzten Knopf nicht.
    local c = CreateFrame("Frame", nil, b)
    c:SetAllPoints(b)
    b._wc = c
    c.bg = c:CreateTexture(nil, "BACKGROUND")
    c.bg:SetAllPoints(c)
    c.health = K.NewBar(c)
    c.power = K.NewBar(c, true)
    c.border = K.Border(c, 1, 0, 0, 0, 1, "BORDER")
    c.shadow = K.Glow(c, { spread = 4, shadow = true })
    local danger = WeintCodex.Colors.danger
    c.aggro = K.Border(c, 2, danger[1], danger[2], danger[3], 1, "OVERLAY")
    c.aggro:SetShown(false)

    local host = CreateFrame("Frame", nil, c)
    host:SetAllPoints(c)
    host:SetFrameLevel((c.health:GetFrameLevel() or 1) + 3)
    c.name = K.NewText(host)
    c.name:SetPoint("TOP", c, "TOP", 0, -5)
    c.name:SetWordWrap(false)
    c.status = K.NewText(host)
    c.status:SetPoint("CENTER", c, "CENTER", 0, -6)
    c.status:SetWordWrap(false)
    -- Schrift sofort: der Kopfrahmen setzt die Einheit (und damit den
    -- ersten Text) womoeglich, bevor Layout gelaufen ist - und Text ohne
    -- Schrift ist im Client ein Fehler.
    K.SetFont(c.name, Opt("nameSize"))
    K.SetFont(c.status, math.max(8, Opt("nameSize") - 1))
    c.raid = host:CreateTexture(nil, "OVERLAY")
    c.raid:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
    c.raid:SetSize(14, 14)
    -- Oben rechts: oben links stehen Rolle und Krone.
    c.raid:SetPoint("TOPRIGHT", c, "TOPRIGHT", -2, -2)
    c.raid:Hide()

    -- Heilung und Schild in einer Klammer ueber dem Lebensbalken.
    c.clip = CreateFrame("Frame", nil, c)
    if c.clip.SetClipsChildren then pcall(c.clip.SetClipsChildren, c.clip, true) end
    c.clip:SetFrameLevel((c.health:GetFrameLevel() or 1) + 1)
    local fill = c.health:GetStatusBarTexture()
    c.heal = K.NewBar(c.clip, true)
    c.absorb = K.NewBar(c.clip, true)
    if fill then
        c.heal:SetPoint("TOPLEFT", fill, "TOPRIGHT", 0, 0)
        c.heal:SetPoint("BOTTOMLEFT", fill, "BOTTOMRIGHT", 0, 0)
    end
    local healFill = c.heal:GetStatusBarTexture()
    if healFill then
        c.absorb:SetPoint("TOPLEFT", healFill, "TOPRIGHT", 0, 0)
        c.absorb:SetPoint("BOTTOMLEFT", healFill, "BOTTOMRIGHT", 0, 0)
    end
    c.heal:Hide()
    c.absorb:Hide()

    c.role = host:CreateTexture(nil, "OVERLAY")
    c.role:SetSize(11, 11)
    c.role:SetPoint("TOPLEFT", c, "TOPLEFT", 2, -2)
    c.role:Hide()
    c.leader = host:CreateTexture(nil, "OVERLAY")
    c.leader:SetSize(11, 11)
    c.leader:SetTexture(K.MEDIA .. "icon_leader")
    local lc = WeintCodex.GameColors.leader
    c.leader:SetVertexColor(lc[1], lc[2], lc[3], 1)
    c.leader:Hide()
    c.ready = host:CreateTexture(nil, "OVERLAY", nil, 2)
    c.ready:SetSize(18, 18)
    c.ready:SetPoint("CENTER", c, "CENTER", 0, 0)
    c.ready:Hide()
    c.readyText = K.NewText(host, 16, "OVERLAY")
    c.readyText:SetPoint("CENTER", c, "CENTER", 0, 0)
    c.readyText:SetText("?")
    c.readyText:Hide()
    -- Treffer: eine rote Flaeche ueber dem Knopf, die ausklingt. Kein
    -- Rand - den roten Rand hat schon die Aggro.
    c.flash = host:CreateTexture(nil, "OVERLAY", nil, -1)
    c.flash:SetAllPoints(c)
    local fc = WeintCodex.GameColors.hitFlash
    c.flash:SetColorTexture(fc[1], fc[2], fc[3], fc[4])
    c.flash:SetShown(false)
    c.debuffs = WeintCodex.UIAuras.Create(host, { filter = "HARMFUL|RAID", max = 3, size = 16,
        spacing = 1, anchor = "BOTTOMRIGHT", growth = "LEFT", growthV = "UP", perRow = 3 })

    for k, v in pairs(Btn) do b[k] = v end

    -- Welche Einheit der Knopf zeigt, setzt der Kopfrahmen ueber das
    -- Attribut "unit" - auch im Kampf.
    b:HookScript("OnAttributeChanged", function(self, name, value)
        if name ~= "unit" then return end
        self._wcUnit = value
        Remap()
        self._wc.debuffs:SetUnit(value)
        self:Refresh()
    end)
    b:HookScript("OnShow", function(self) self:Refresh() self:UpdateRange() end)

    if b.RegisterForClicks then b:RegisterForClicks("AnyUp") end
    b:SetAttribute("*type1", "target")
    b:SetAttribute("*type2", "togglemenu")
    b:SetScript("OnEnter", function(self)
        if not self._wcUnit then return end
        if _G.UnitFrame_OnEnter then
            self.unit = self._wcUnit
            _G.UnitFrame_OnEnter(self)
        elseif _G.GameTooltip_SetDefaultAnchor then
            _G.GameTooltip_SetDefaultAnchor(GameTooltip, self)
            GameTooltip:SetUnit(self._wcUnit)
            GameTooltip:Show()
        end
    end)
    b:SetScript("OnLeave", function(self)
        if _G.UnitFrame_OnLeave then _G.UnitFrame_OnLeave(self) else GameTooltip:Hide() end
    end)
    allButtons[#allButtons + 1] = b
end

GF._Style = Style   -- fuer den Prueflauf: einen Knopf einrichten wie der Kopfrahmen

--------------------------------------------------
-- Kopfrahmen
--------------------------------------------------

local headers = {}   -- [kind] = { header, anchor, max }

local function Children(header, max)
    local out = {}
    for i = 1, max do
        local child = header.GetAttribute and header:GetAttribute("child" .. i)
        if type(child) ~= "table" then child = nil end
        out[#out + 1] = child
    end
    if #out == 0 and header.GetChildren then
        for _, c in ipairs({ header:GetChildren() }) do out[#out + 1] = c end
    end
    return out
end

-- Wie der Kopfrahmen seine Knoepfe reiht. MUSS vor dem ersten Show()
-- stehen: der Client liest "point" beim Anordnen ohne Rueckfall, und ohne
-- das Attribut bricht er in SecureGroupHeaders.lua ab (so geschehen in
-- 6.0.0.3 - die Gruppenrahmen kamen nie zustande).
local function LayoutAttributes(kind, h)
    local sp = Opt(kind .. "Spacing")
    if kind == "raid" then
        h:SetAttribute("point", "TOP")
        h:SetAttribute("xOffset", 0)
        h:SetAttribute("yOffset", -sp)
        h:SetAttribute("columnSpacing", sp)
        h:SetAttribute("columnAnchorPoint", "LEFT")
    else
        local horiz = Opt("partyHorizontal")
        h:SetAttribute("point", horiz and "LEFT" or "TOP")
        h:SetAttribute("xOffset", horiz and sp or 0)
        h:SetAttribute("yOffset", horiz and 0 or -sp)
        h:SetAttribute("showPlayer", Opt("partyShowPlayer") and true or false)
    end
end

local function Configure(kind)
    local hd = headers[kind]
    if not hd then return end
    local h = hd.header
    local w, ht, sp = Opt(kind .. "Width"), Opt(kind .. "Height"), Opt(kind .. "Spacing")
    for _, b in ipairs(Children(h, hd.max)) do
        Style(b)
        b:SetSize(w, ht)
        b:Layout(w, ht)
        b:Refresh()
    end
    LayoutAttributes(kind, h)
    if kind == "raid" then
        hd.anchor:SetSize(8 * w + 7 * sp, 5 * ht + 4 * sp)
    elseif Opt("partyHorizontal") then
        hd.anchor:SetSize(5 * w + 4 * sp, ht)
    else
        hd.anchor:SetSize(w, 5 * ht + 4 * sp)
    end
    h:ClearAllPoints()
    h:SetPoint("TOPLEFT", hd.anchor, "TOPLEFT", 0, 0)
end

local function CreateHeader(kind)
    local isRaid = (kind == "raid")
    local name = isRaid and "WeintCodexRaidHeader" or "WeintCodexPartyHeader"
    local h = CreateFrame("Frame", name, UIParent, "SecureGroupHeaderTemplate")
    h:SetAttribute("template", "SecureUnitButtonTemplate")
    h:SetAttribute("templateType", "Button")
    h:SetAttribute("sortMethod", "INDEX")
    local max
    if isRaid then
        h:SetAttribute("showRaid", true)
        h:SetAttribute("groupBy", "GROUP")
        h:SetAttribute("groupingOrder", "1,2,3,4,5,6,7,8")
        h:SetAttribute("maxColumns", 8)
        h:SetAttribute("unitsPerColumn", 5)
        max = 40
    else
        h:SetAttribute("showParty", true)
        h:SetAttribute("showPlayer", Opt("partyShowPlayer") and true or false)
        h:SetAttribute("showSolo", false)
        max = 5
    end

    LayoutAttributes(kind, h)

    -- Alle Knoepfe JETZT anlegen (ausserhalb des Kampfes): ohne
    -- initialConfigFunction koennte ein im Kampf angelegter Knopf weder
    -- Groesse noch Klick-Attribute bekommen.
    h:SetAttribute("startingIndex", -(max - 1))
    h:Show()
    h:SetAttribute("startingIndex", 1)

    local anchor = CreateFrame("Frame", nil, UIParent)
    anchor:SetSize(100, 100)
    anchor.WCShowForUnlock = function() end
    headers[kind] = { header = h, anchor = anchor, max = max }
    K.RegisterMover(anchor, kind == "raid" and "gf_raid" or "gf_party",
        isRaid and "Schlachtzug" or "Gruppe",
        K.Layout(isRaid and "gf_raid" or "gf_party"), { secure = true })

    Configure(kind)

    if _G.RegisterStateDriver then
        _G.RegisterStateDriver(h, "visibility", isRaid and "[group:raid] show; hide"
            or "[group:party,nogroup:raid] show; hide")
    end
end

--------------------------------------------------
-- Testmodus: eine Beispielgruppe
--------------------------------------------------
-- ui/testmode.lua. Die echten Knoepfe gehoeren dem Kopfrahmen und zeigen
-- nur, wer wirklich in der Gruppe ist. Fuer den Testmodus stehen fuenf
-- ungeschuetzte Knoepfe mit demselben Aussehen an derselben Stelle -
-- solange man allein ist (sonst zeigt die echte Gruppe sich selbst).
--------------------------------------------------

local TEST_PARTY = {
    { name = "Brunhild", class = "WARRIOR", hp = 0.72, ptoken = "RAGE", power = 0.35, aggro = true,
      role = "TANK", leader = true, absorb = 0.12 },
    { name = "Liora",    class = "PRIEST",  hp = 1.00, ptoken = "MANA", power = 0.76, role = "HEALER" },
    { name = "Tamsin",   class = "MAGE",    hp = 0.45, ptoken = "MANA", power = 0.40, role = "DAMAGER", heal = 0.25 },
    { name = "Orwen",    class = "HUNTER",  hp = 0.88, ptoken = "MANA", power = 0.90, out = true, role = "DAMAGER" },
    { name = "Kaelen",   class = "PALADIN", dead = true, role = "DAMAGER", res = true },
}
local testButtons = {}

local function TestButton(i)
    local b = testButtons[i]
    if b then return b end
    b = CreateFrame("Button", nil, UIParent)
    b._wcTest = true
    Style(b)
    -- Kein Klickziel: ein Beispielknopf waehlt niemanden aus.
    b:EnableMouse(false)
    testButtons[i] = b
    return b
end

function GF.ShowTest(on)
    local hd = headers.party
    for i = 1, #TEST_PARTY do
        local b = testButtons[i]
        if b then b:Hide() end
    end
    if not on or not hd or (hd.header.IsVisible and hd.header:IsVisible()) then return end
    local w, ht, sp = Opt("partyWidth"), Opt("partyHeight"), Opt("partySpacing")
    local horiz = Opt("partyHorizontal")
    for i, t in ipairs(TEST_PARTY) do
        local b = TestButton(i)
        local c = b._wc
        b:SetSize(w, ht)
        b:Layout(w, ht)
        b:ClearAllPoints()
        if horiz then
            b:SetPoint("TOPLEFT", hd.anchor, "TOPLEFT", (i - 1) * (w + sp), 0)
        else
            b:SetPoint("TOPLEFT", hd.anchor, "TOPLEFT", 0, -(i - 1) * (ht + sp))
        end
        c.health:SetMinMaxValues(0, 1)
        c.health:SetValue(t.dead and 0 or t.hp)
        local cc = _G.RAID_CLASS_COLORS and _G.RAID_CLASS_COLORS[t.class]
        if Opt("classColor") and cc then
            K.PaintBar(c.health, cc.r, cc.g, cc.b)
        else
            local hc = K.GetColor(KEY, "healthColor")
            K.PaintBar(c.health, hc.r, hc.g, hc.b)
        end
        c.power:SetMinMaxValues(0, 1)
        c.power:SetValue(t.power or 0)
        local pc = t.ptoken and _G.PowerBarColor and _G.PowerBarColor[t.ptoken]
        if type(pc) == "table" and pc.r then K.PaintBar(c.power, pc.r, pc.g, pc.b) end
        c.name:SetText(t.name)
        for _, pair in ipairs({ { c.heal, "healPrediction", t.heal }, { c.absorb, "absorbs", t.absorb } }) do
            local bar, key, v = pair[1], pair[2], pair[3]
            if v and Opt(key) then
                bar:SetMinMaxValues(0, 1)
                bar:SetValue(v)
                bar:Show()
            else
                bar:Hide()
            end
        end
        local r = t.role and Opt("roleIcon") and ROLE[t.role]
        if r then
            c.role:SetTexture(K.MEDIA .. r.tex)
            local col = WeintCodex.GameColors[r.color]
            c.role:SetVertexColor(col[1], col[2], col[3], 1)
        end
        c.role:SetShown(r and true or false)
        c.leader:ClearAllPoints()
        if r then c.leader:SetPoint("LEFT", c.role, "RIGHT", 1, 0) else c.leader:SetPoint("TOPLEFT", c, "TOPLEFT", 2, -2) end
        c.leader:SetShown((t.leader and Opt("leaderIcon")) and true or false)
        if t.res then
            c.status:SetText("Wird belebt")
        elseif t.dead then
            c.status:SetText("Tot")
        elseif Opt("statusText") == "percent" then
            c.status:SetFormattedText("%d%%", t.hp * 100)
        else
            c.status:SetText("")
        end
        c.aggro:SetShown(Opt("aggroBorder") and t.aggro or false)
        c:SetAlpha(t.out and (Opt("rangeAlpha") or 45) / 100 or 1)
        b:Show()
    end
end

--------------------------------------------------
-- Ereignisse und Takt
--------------------------------------------------

local events = CreateFrame("Frame")
local UNIT_EVENTS = {
    UNIT_HEALTH = true, UNIT_MAXHEALTH = true, UNIT_NAME_UPDATE = true,
    UNIT_CONNECTION = true, UNIT_FLAGS = true,
    UNIT_POWER_UPDATE = true, UNIT_MAXPOWER = true, UNIT_DISPLAYPOWER = true,
    INCOMING_RESURRECT_CHANGED = true, INCOMING_SUMMON_CHANGED = true,
}
-- Nur ein Teil des Knopfs: kein ganzes Refresh je Heilzauber.
local PART_EVENTS = {
    UNIT_HEAL_PREDICTION = "UpdatePrediction", UNIT_ABSORB_AMOUNT_CHANGED = "UpdatePrediction",
    UNIT_COMBAT = "combat",
}

-- Neue Knoepfe nachziehen. Ob der Kopfrahmen beim Anmelden wirklich alle
-- Knoepfe auf Vorrat anlegt (auch allein, ohne Gruppe), ist auf Forever
-- nicht geprueft. Legt er einen erst beim Beitritt an, haette der kein
-- Aussehen - klickbar, aber unsichtbar. Deshalb nach jeder Aenderung der
-- Gruppe: alle Knoepfe einrichten (wer schon eingerichtet ist, bleibt
-- unberuehrt). Einen Takt spaeter, damit der Kopfrahmen zuerst dran war;
-- im Kampf erst danach.
local function RestyleLater()
    local function run()
        K.AfterCombat(function()
            for kind in pairs(headers) do Configure(kind) end
            Remap()
        end)
    end
    if _G.C_Timer and _G.C_Timer.After then _G.C_Timer.After(0, run) else run() end
end

local function OnEvent(_, event, unit, ...)
    if event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_ENTERING_WORLD" then
        RestyleLater()
    end
    if event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_ENTERING_WORLD"
       or event == "RAID_TARGET_UPDATE" then
        Remap()
        for _, b in ipairs(allButtons) do if b:IsShown() then b:Refresh() end end
        return
    end
    if event == "UNIT_THREAT_SITUATION_UPDATE" then
        local list = unit and byUnit[unit]
        if list then for _, b in ipairs(list) do b:UpdateThreat() end end
        return
    end
    if event == "READY_CHECK" or event == "READY_CHECK_CONFIRM" or event == "READY_CHECK_FINISHED"
       or event == "PARTY_LEADER_CHANGED" or event == "PLAYER_ROLES_ASSIGNED" then
        readyDone = (event == "READY_CHECK_FINISHED")
        for _, b in ipairs(allButtons) do
            if b:IsShown() then b:UpdateRole() b:UpdateReady() end
        end
        if readyDone then
            -- Das Ergebnis bleibt kurz stehen, dann ist Ruhe.
            local function clear()
                readyDone = false
                for _, b in ipairs(allButtons) do if b._wc then b._wc.ready:Hide() b._wc.readyText:Hide() end end
            end
            if _G.C_Timer and _G.C_Timer.After then _G.C_Timer.After(6, clear) else clear() end
        end
        return
    end
    local part = PART_EVENTS[event]
    if part then
        local list = unit and byUnit[unit]
        if not list then return end
        for _, b in ipairs(list) do
            if b:IsShown() then
                if part == "combat" then
                    -- UNIT_COMBAT(unit, action, ...): nur "WOUND" ist ein Treffer.
                    local action = select(1, ...)
                    if K.Plain(action) == "WOUND" then b:Flash() end
                else
                    b[part](b)
                end
            end
        end
        return
    end
    local list = unit and byUnit[unit]
    if not list then return end
    for _, b in ipairs(list) do
        if b:IsShown() then b:Refresh() end
    end
end

local ticker = CreateFrame("Frame")
local acc = 0
local function OnTick(_, el)
    -- Aufblitzen ausklingen lassen (jedes Bild, nur wo es laeuft).
    for _, b in ipairs(allButtons) do
        local c = b._wc
        if c and c._flashLeft then
            c._flashLeft = c._flashLeft - (el or 0)
            if c._flashLeft <= 0 then
                c._flashLeft = nil
                c.flash:SetShown(false)
            else
                c.flash:SetAlpha(c._flashLeft / 0.35)
            end
        end
    end
    acc = acc + (el or 0)
    if acc < 0.25 then return end
    acc = 0
    for _, b in ipairs(allButtons) do
        if b:IsVisible() then b:UpdateRange() end
    end
end

local function Enable()
    K.AfterCombat(function()
        if Opt("partyEnabled") then
            CreateHeader("party")
            K.HideBlizzard("PartyFrame")
            K.HideBlizzard("CompactPartyFrame")
        end
        if Opt("raidEnabled") then
            CreateHeader("raid")
            K.HideBlizzard("CompactRaidFrameContainer")
            K.HideBlizzard("CompactRaidFrameManager")
        end
        Remap()
    end)
    for e in pairs(UNIT_EVENTS) do pcall(events.RegisterEvent, events, e) end
    for e in pairs(PART_EVENTS) do pcall(events.RegisterEvent, events, e) end
    for _, e in ipairs({ "GROUP_ROSTER_UPDATE", "PLAYER_ENTERING_WORLD", "RAID_TARGET_UPDATE",
        "UNIT_THREAT_SITUATION_UPDATE", "READY_CHECK", "READY_CHECK_CONFIRM", "READY_CHECK_FINISHED",
        "PARTY_LEADER_CHANGED", "PLAYER_ROLES_ASSIGNED" }) do pcall(events.RegisterEvent, events, e) end
    events:SetScript("OnEvent", OnEvent)
    ticker:SetScript("OnUpdate", OnTick)
end

local function OnSetting()
    K.AfterCombat(function()
        for kind in pairs(headers) do Configure(kind) end
    end)
end

--------------------------------------------------
-- Modul
--------------------------------------------------

local function px(v) return string.format("%d px", v) end

K.Register({
    key = KEY, group = "ui", order = 25,
    title = "Gruppenrahmen",
    description = "Gruppe und Schlachtzug als schlichte Kacheln: Klassenfarbe, Name, Leben, eingehende Heilung, Schilde, Rolle, Reichweite, Aggro und bannbare Debuffs.",
    defaults = defaults,
    Enable = Enable,
    OnSetting = OnSetting,
    pages = {
        { key = "allgemein", label = "Allgemein", build = function(B)
            B:Section("Farben und Rahmen")
            B:Row({ type = "toggle", label = "Klassenfarbe", key = "classColor" },
                  { type = "color", label = "Lebensbalken sonst", key = "healthColor" })
            B:Row({ type = "color", label = "Hintergrund", key = "bgColor" },
                  { type = "toggle", label = "Rand anzeigen", key = "showBorder" })
            B:Row({ type = "toggle", label = "Roter Rand bei Aggro", key = "aggroBorder" },
                  { type = "slider", label = "Deckkraft außer Reichweite", key = "rangeAlpha", min = 10, max = 100, step = 5,
                    format = function(v) return string.format("%d %%", v) end })
            B:Section("Texte")
            B:Row({ type = "slider", label = "Schriftgröße", key = "nameSize", min = 8, max = 16, step = 1, format = px },
                  { type = "dropdown", label = "Unter dem Namen", key = "statusText", items = {
                        { value = "none",    text = "Nichts" },
                        { value = "percent", text = "Leben in %" },
                        { value = "deficit", text = "Fehlendes Leben" } } })
            B:Section("Kraft und Debuffs")
            B:Row({ type = "toggle", label = "Kraftleiste", key = "power" },
                  { type = "slider", label = "Höhe der Kraftleiste", key = "powerHeight", min = 1, max = 8, step = 1, format = px,
                    disabled = function() return not K.Get(KEY, "power") end })
            B:Row({ type = "toggle", label = "Debuffs", key = "debuffs" },
                  { type = "toggle", label = "Nur bannbare", key = "onlyDispellable",
                    disabled = function() return not K.Get(KEY, "debuffs") end,
                    description = "Was du selbst entfernen kannst." })
            B:Row({ type = "slider", label = "Symbolgröße", key = "debuffSize", min = 10, max = 28, step = 1, format = px,
                    disabled = function() return not K.Get(KEY, "debuffs") end },
                  { type = "slider", label = "Höchstens", key = "debuffMax", min = 1, max = 6, step = 1,
                    format = function(v) return tostring(v) end,
                    disabled = function() return not K.Get(KEY, "debuffs") end })
            B:Section("Mehr im Rahmen")
            B:Row({ type = "toggle", label = "Eingehende Heilung", key = "healPrediction",
                    description = "Ein heller grüner Balken hinter dem Leben: so weit reichen Heilungen, die gerade gewirkt werden." },
                  { type = "toggle", label = "Schilde", key = "absorbs",
                    description = "Ein weißer Balken dahinter: wie viel Schaden Schilde noch abfangen." })
            B:Row({ type = "toggle", label = "Rollensymbol", key = "roleIcon",
                    description = "Schild, Kreuz oder Schwert oben links – nur, wenn eine Rolle zugewiesen ist." },
                  { type = "toggle", label = "Krone beim Gruppenleiter", key = "leaderIcon" })
            B:Row({ type = "toggle", label = "Bereitschaftscheck", key = "readyCheck",
                    description = "Haken, Kreuz oder „?“ in der Mitte; das Ergebnis bleibt ein paar Sekunden stehen." },
                  { type = "toggle", label = "Aufblitzen bei Treffern", key = "hitFlash",
                    description = "Der Knopf blitzt kurz rot auf, wenn jemand getroffen wird." })
            B:Note("Wer gerade wiederbelebt oder beschworen wird, steht unter dem Namen („Wird belebt“, „Beschwörung“). Schaden, der erst noch kommt, kennt das Spiel nicht – das Aufblitzen zeigt Treffer in dem Moment, in dem sie landen.")
        end },
        { key = "gruppe", label = "Gruppe", build = function(B)
            local off = function() return not K.Get(KEY, "partyEnabled") end
            B:Section("Gruppe (bis fünf)")
            B:Row({ type = "toggle", label = "Gruppenrahmen anzeigen", key = "partyEnabled", reload = true,
                    description = "Ersetzt die Gruppenrahmen des Spiels. Wirkt nach dem Neuladen." },
                  { type = "toggle", label = "Mich selbst zeigen", key = "partyShowPlayer", disabled = off })
            B:Row({ type = "slider", label = "Breite", key = "partyWidth", min = 60, max = 220, step = 1, format = px, disabled = off },
                  { type = "slider", label = "Höhe", key = "partyHeight", min = 20, max = 80, step = 1, format = px, disabled = off })
            B:Row({ type = "slider", label = "Abstand", key = "partySpacing", min = 0, max = 20, step = 1, format = px, disabled = off },
                  { type = "toggle", label = "Nebeneinander", key = "partyHorizontal", disabled = off })
        end },
        { key = "raid", label = "Schlachtzug", build = function(B)
            local off = function() return not K.Get(KEY, "raidEnabled") end
            B:Section("Schlachtzug (bis vierzig)")
            B:Row({ type = "toggle", label = "Schlachtzugsrahmen anzeigen", key = "raidEnabled", reload = true,
                    description = "Ersetzt die Schlachtzugsrahmen des Spiels samt Seitenleiste. Wirkt nach dem Neuladen." },
                  { type = "empty" })
            B:Row({ type = "slider", label = "Breite", key = "raidWidth", min = 50, max = 160, step = 1, format = px, disabled = off },
                  { type = "slider", label = "Höhe", key = "raidHeight", min = 20, max = 70, step = 1, format = px, disabled = off })
            B:Row({ type = "slider", label = "Abstand", key = "raidSpacing", min = 0, max = 12, step = 1, format = px, disabled = off },
                  { type = "empty" })
            B:Note("Die Seitenleiste des Spiels (Zielmarkierungen, Bereitschaftscheck) verschwindet mit den Schlachtzugsrahmen. Markierungen gehen weiter über Tastenbelegung oder das Einheitenmenü.")
        end },
    },
})
