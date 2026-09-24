--------------------------------------------------
-- WeintCodex :: Oberflaeche - Namensplaketten
--------------------------------------------------
-- Eigene Plaketten fuer Gegner - und seit 6.0.0.3 fuer Freunde (nur der
-- Name in Klassenfarbe, wahlweise mit Balken). In Instanzen sind
-- freundliche Plaketten fuer Addons gesperrt ("forbidden"); dort bleiben
-- die des Spiels. Das ist der eine Ort, an dem die Plakette je nach Ort
-- anders aussieht, und die Einstellungsseite sagt es.
--
-- Auren ueber gegnerischen Plaketten kommen aus ui/auras.lua (Auren-
-- Container des Spiels, wo es ihn gibt).
--
-- WIE. Die Plakette ist ein eigener Rahmen, der an der Blizzard-Plakette
-- haengt (SetParent: Abstandsskalierung und Sichtbarkeit erbt er so
-- mit). Der Blizzard-Inhalt wird unsichtbar gestellt und von seinen
-- Ereignissen getrennt - er bleibt aber, wo er ist: der Klick auf eine
-- Plakette waehlt im Client das Ziel ueber den Blizzard-Rahmen aus, und
-- den darf man nicht wegnehmen. Das Verfahren folgt der Vorlage
-- (EllesmereUI); der Code ist eigener.
--
-- WAS DER CLIENT VERSCHWEIGT. Ab 12.0 sind Lebenspunkte, Stufe und
-- manches mehr im Kampf "secret" (siehe ui/kit.lua). Balken und Texte
-- bekommen die Werte durchgereicht, verglichen wird nur, was nicht
-- geheim ist. Eine Stufe, die der Client nicht nennt, steht als "??" da -
-- nie als 0.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UINameplates = {}

local NP = WeintCodex.UINameplates
local K  = WeintCodex.UIKit
local CB = WeintCodex.UICastBar
local KEY = "nameplates"

--------------------------------------------------
-- Voreinstellungen (Zahlen nach EllesmereUI 9.2.6, Forever-Zweig)
--------------------------------------------------

local defaults = {
    width  = 140,
    height = 17,               -- Vorlage: healthBarHeight 17
    targetScale    = 100,      -- Prozent
    nonTargetAlpha = 100,      -- Prozent; 100 = nichts abblenden
    showBorder  = true,
    borderColor = K.ColorDefault("plateBorder"),
    bgColor     = K.ColorDefault("plateBg"),
    targetRing  = true,

    enemyInCombat = K.ColorDefault("enemyInCombat"),
    hostile       = K.ColorDefault("hostile"),
    darkenOOC     = true,      -- Vorlage: darkenEnemiesOOC = true
    neutral       = K.ColorDefault("neutral"),
    tapped        = K.ColorDefault("tapped"),
    boss          = K.ColorDefault("boss"),
    elite         = K.ColorDefault("elite"),
    eliteColoring = true,
    focusColorEnabled  = true,  -- Vorlage: true
    focus              = K.ColorDefault("focus"),
    targetColorEnabled = false, -- Vorlage: false
    target             = K.ColorDefault("target"),
    classColorPlayers  = true,
    threatColors = false,       -- Vorlage: tankHasAggroEnabled = false
    tankAggro  = K.ColorDefault("tankAggro"),
    tankLosing = K.ColorDefault("tankLosing"),
    dpsAggro   = K.ColorDefault("dpsAggro"),
    dpsNear    = K.ColorDefault("dpsNear"),

    -- Textplaetze. Auf Forever steht links die Stufe (Vorlage:
    -- textSlotLeft = "level" nur auf Forever) - in einer Welt mit
    -- Stufenunterschieden ist sie die wichtigste Zahl auf der Plakette.
    textTop    = "name",
    textLeft   = "level",
    textRight  = "healthPercent",
    textCenter = "none",
    nameSize = 11,
    textSize = 10,
    levelColor = true,
    eliteMark  = true,
    raidMarker = "topright",
    raidMarkerSize = 20,

    castEnabled = true,
    castHeight  = 17,          -- Vorlage: castBarHeight 17
    castIcon    = true,
    castTimer   = true,
    castShield  = true,
    castColor   = K.ColorDefault("cast"),
    castLocked  = K.ColorDefault("castLocked"),

    -- Auren ueber der Plakette (Vorlage: debuffSlot "top", Symbol 26,
    -- maxDebuffs 5). Von Haus aus nur die eigenen - auf einer Plakette,
    -- die zwanzig Spieler gleichzeitig bearbeiten, waeren alle Debuffs
    -- ein Muster, keine Auskunft.
    auraEnabled = true,
    auraOnlyMine = true,
    auraSize = 22,
    auraMax = 5,

    -- Freundliche Plaketten: nur der Name, in Klassenfarbe (Vorlage:
    -- friendlyNameOnly = true, classColorFriendly = true). In Instanzen
    -- gesperrt das Spiel sie fuer Addons - dort bleiben die des Spiels.
    friendlyEnabled = true,
    friendlyHealth = false,
    friendlyClassColor = true,
    friendlyNameSize = 12,
    friendlyColor = K.ColorDefault("friendly"),
}

local S = {}   -- aufgeloeste Einstellungen, neu gelesen bei jeder Aenderung
local function Resolve()
    for k in pairs(defaults) do S[k] = K.Get(KEY, k) end
end

--------------------------------------------------
-- Blizzard-Inhalt unsichtbar stellen
--------------------------------------------------

local hidden = CreateFrame("Frame")
hidden:Hide()
local parked = {}   -- [Blizzard-Kindrahmen] = urspruenglicher Elternrahmen

local function Suppress(nameplate)
    local uf = nameplate and nameplate.UnitFrame
    if type(uf) ~= "table" then return end
    if uf.IsForbidden and uf:IsForbidden() then return end
    uf:SetAlpha(0)
    -- Die Auren der Blizzard-Plakette sind Knoepfe mit Tooltip: bei
    -- Alpha 0 waeren sie eine unsichtbare Tooltipfalle ueber jeder
    -- Plakette. Sie ziehen in einen versteckten Rahmen um.
    local auras = uf.AurasFrame
    if type(auras) ~= "table" then auras = uf.BuffFrame end
    if type(auras) == "table" and not (auras.IsProtected and auras:IsProtected()) then
        parked[auras] = parked[auras] or auras:GetParent()
        auras:SetParent(hidden)
    end
    -- Die Blizzard-Plakette arbeitet sonst unsichtbar weiter, bei jedem
    -- Treffer. Der Client meldet sie beim naechsten Zuweisen einer
    -- Einheit (CompactUnitFrame_SetUnit) von selbst wieder an.
    uf:UnregisterAllEvents()
    local cast = uf.castBar
    if type(cast) ~= "table" then cast = uf.CastBar end
    if type(cast) == "table" and cast.UnregisterAllEvents then cast:UnregisterAllEvents() end
end

local function Restore(nameplate)
    local uf = nameplate and nameplate.UnitFrame
    if type(uf) ~= "table" then return end
    if uf.IsForbidden and uf:IsForbidden() then return end
    local auras = uf.AurasFrame
    if type(auras) ~= "table" then auras = uf.BuffFrame end
    if type(auras) == "table" and parked[auras] then
        auras:SetParent(parked[auras])
        parked[auras] = nil
    end
    uf:SetAlpha(1)
end

--------------------------------------------------
-- Aufbau einer Plakette
--------------------------------------------------

local pool, plates = {}, {}
NP.plates = plates

local SLOTS = { "top", "left", "right", "center" }

local function Build(parent)
    local p = CreateFrame("Frame", nil, parent or UIParent)
    p:SetSize(defaults.width, defaults.height)

    local health = CreateFrame("StatusBar", nil, p)
    health:SetAllPoints(p)
    health:SetStatusBarTexture(K.BAR_TEXTURE)
    health:SetMinMaxValues(0, 1)
    health:SetValue(1)
    p.health = health

    local bg = health:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(health)
    p.bg = bg

    p.border = K.Border(health, 1, 0, 0, 0, 1, "BORDER")
    p.ring = K.Border(health, 2, 1, 1, 1, 1, "OVERLAY")
    p.ring:SetShown(false)

    -- Texte liegen auf einem eigenen Rahmen ueber dem Balken, damit der
    -- Rand sie nicht ueberdeckt.
    local textHost = CreateFrame("Frame", nil, p)
    textHost:SetAllPoints(p)
    textHost:SetFrameLevel(health:GetFrameLevel() + 3)
    p.texts = {}
    for _, slot in ipairs(SLOTS) do
        local fs = textHost:CreateFontString(nil, "OVERLAY")
        fs:SetWordWrap(false)
        p.texts[slot] = fs
    end

    local raid = textHost:CreateTexture(nil, "OVERLAY")
    raid:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
    raid:Hide()
    p.raid = raid

    p.cast = CB.Create(p)
    p.auras = WeintCodex.UIAuras.Create(p, { filter = "HARMFUL|PLAYER", max = defaults.auraMax,
        size = defaults.auraSize, spacing = 2, anchor = "BOTTOMLEFT", growth = "RIGHT",
        growthV = "UP", perRow = defaults.auraMax })
    return p
end

local function AuraFilter()
    return S.auraOnlyMine and "HARMFUL|PLAYER" or "HARMFUL"
end

-- Nur Name: kein Balken, kein Rand, der Name in der Mitte. Freundliche
-- Plaketten brauchen keine Lebenspunkte, um lesbar zu sein - und wer sie
-- will, schaltet den Balken zu.
local function LayoutFriendly(p)
    local bar = S.friendlyHealth
    p:SetSize(S.width, bar and S.height or 1)
    if bar then p.health:Show() else p.health:Hide() end
    p.border:SetShown(bar and S.showBorder)
    p.ring:SetShown(false)
    for _, slot in ipairs(SLOTS) do p.texts[slot]:Hide() end
    local t = p.texts.top
    K.SetFont(t, S.friendlyNameSize)
    t:ClearAllPoints()
    if bar then t:SetPoint("BOTTOM", p, "TOP", 0, 3) else t:SetPoint("CENTER", p, "CENTER", 0, 0) end
    t:SetWidth(S.width + 40)
    t:SetJustifyH("CENTER")
    p.cast:Hide()
    p.auras:SetShown(false)
    p.raid:ClearAllPoints()
    p.raid:SetSize(S.raidMarkerSize, S.raidMarkerSize)
    p.raid:SetPoint("BOTTOM", t, "TOP", 0, 2)
end

local function Layout(p)
    if p._friendly then return LayoutFriendly(p) end
    p.health:Show()
    p:SetSize(S.width, S.height)

    local bgc = S.bgColor or defaults.bgColor
    p.bg:SetColorTexture(bgc.r, bgc.g, bgc.b, 1)
    p.border:SetShown(S.showBorder)
    local bc = S.borderColor or defaults.borderColor
    p.border:SetColor(bc.r, bc.g, bc.b, 1)
    local rc = WeintCodex.GameColors.targetRing
    p.ring:SetColor(rc[1], rc[2], rc[3], 1)

    local t = p.texts
    for _, slot in ipairs(SLOTS) do
        local fs = t[slot]
        K.SetFont(fs, slot == "top" and S.nameSize or S.textSize)
        fs:ClearAllPoints()
    end
    t.top:SetPoint("BOTTOM", p, "TOP", 0, 3)
    t.top:SetWidth(S.width + 20)
    t.top:SetJustifyH("CENTER")
    t.left:SetPoint("LEFT", p, "LEFT", 4, 0)
    t.left:SetWidth(S.width * 0.5 - 6)
    t.left:SetJustifyH("LEFT")
    t.right:SetPoint("RIGHT", p, "RIGHT", -3, 0)
    t.right:SetWidth(S.width * 0.5 - 6)
    t.right:SetJustifyH("RIGHT")
    t.center:SetPoint("CENTER", p, "CENTER", 0, 0)
    t.center:SetWidth(S.width - 8)
    t.center:SetJustifyH("CENTER")

    local raid = p.raid
    raid:ClearAllPoints()
    raid:SetSize(S.raidMarkerSize, S.raidMarkerSize)
    local pos = S.raidMarker
    if pos == "top" then
        raid:SetPoint("BOTTOM", t.top, "TOP", 0, 2)
    elseif pos == "left" then
        raid:SetPoint("RIGHT", p, "LEFT", -4, 0)
    elseif pos == "right" then
        raid:SetPoint("LEFT", p, "RIGHT", 4, 0)
    else
        raid:SetPoint("BOTTOMLEFT", p, "TOPRIGHT", -S.raidMarkerSize * 0.5, 2)
    end

    -- Auren ueber dem Namen, linksbuendig.
    p.auras:ApplyLayout({ filter = AuraFilter(), max = S.auraMax, size = S.auraSize,
        spacing = 2, anchor = "BOTTOMLEFT", growth = "RIGHT", growthV = "UP", perRow = S.auraMax })
    p.auras:ClearAllPoints()
    p.auras:SetPoint("BOTTOMLEFT", p, "TOPLEFT", 0, (S.textTop ~= "none" and S.nameSize or 0) + 8)
    p.auras:SetShown(S.auraEnabled)

    local cast = p.cast
    cast:ClearAllPoints()
    cast:SetPoint("TOPLEFT", p, "BOTTOMLEFT", 0, -2)
    cast:SetPoint("TOPRIGHT", p, "BOTTOMRIGHT", 0, -2)
    cast:ApplyStyle({
        height = S.castHeight, icon = S.castIcon, timer = S.castTimer,
        shield = S.castShield, cast = S.castColor, locked = S.castLocked,
        bg = S.bgColor, border = S.showBorder,
    })
end

--------------------------------------------------
-- Inhalte
--------------------------------------------------

local function IsUnit(unit, other)
    return K.Bool(_G.UnitIsUnit and _G.UnitIsUnit(unit, other), false)
end

local function LevelText(unit)
    -- Kein `a and b or c`: das `or` prueft b auf Wahrheit, und b kann
    -- geheim sein.
    local lvl
    if _G.UnitEffectiveLevel then
        lvl = _G.UnitEffectiveLevel(unit)
    elseif _G.UnitLevel then
        lvl = _G.UnitLevel(unit)
    end
    local plain = K.Plain(lvl)
    local cls = K.Plain(_G.UnitClassification and _G.UnitClassification(unit))
    if type(plain) ~= "number" or plain < 0 then
        -- Boss (-1) oder vom Client verschwiegen: beides "??", wie im
        -- Spiel selbst. Eine 0 waere eine Behauptung.
        return "??", 1, 0.2, 0.2
    end
    local text = tostring(plain)
    if S.eliteMark and (cls == "elite" or cls == "rareelite" or cls == "worldboss") then
        text = text .. "+"
    end
    local r, g, b = 1, 0.82, 0
    if S.levelColor and _G.GetCreatureDifficultyColor then
        local c = _G.GetCreatureDifficultyColor(plain)
        if type(c) == "table" and K.Plain(c.r) then r, g, b = c.r, c.g, c.b end
    end
    return text, r, g, b
end

-- Lebenspunkte als Text. Mit UnitHealthPercent (12.0+) rechnet der
-- Client den Anteil selbst - auch wenn er ihn Lua gegenueber geheim
-- haelt, nimmt ihn string.format entgegen.
local function HealthTexts(unit)
    local cur = _G.UnitHealth and _G.UnitHealth(unit)
    local max = _G.UnitHealthMax and _G.UnitHealthMax(unit)
    local pct
    if _G.UnitHealthPercent and _G.CurveConstants and _G.CurveConstants.ScaleTo100 then
        local ok, v = pcall(_G.UnitHealthPercent, unit, true, _G.CurveConstants.ScaleTo100)
        if ok then pct = v end
    end
    if type(pct) == "nil" then
        local c, m = K.Plain(cur), K.Plain(max)
        if type(c) == "number" and type(m) == "number" and m > 0 then
            pct = c / m * 100
        end
    end
    -- `type()` statt `~= nil`: ein Vergleich mit einem geheimen Wert ist
    -- im 12.x-Client ein Fehler, `type` nicht.
    local pctText = (type(pct) ~= "nil") and string.format("%d%%", pct) or ""
    local numText = ""
    if type(cur) ~= "nil" then
        if _G.AbbreviateNumbers then
            numText = _G.AbbreviateNumbers(cur)
        elseif type(K.Plain(cur)) == "number" then
            numText = WeintCodex.FormatAmount and WeintCodex.FormatAmount(cur) or tostring(cur)
        end
    end
    return pctText, numText
end

local function FillTexts(p, onlyHealth)
    local unit = p.unit
    if not unit then return end
    if p._friendly then
        if onlyHealth then return end
        local t = p.texts.top
        t:SetText(_G.UnitName and (_G.UnitName(unit)))
        local r, g, b = 1, 1, 1
        local c = S.friendlyColor
        if c then r, g, b = c.r, c.g, c.b end
        if S.friendlyClassColor and K.Bool(_G.UnitIsPlayer and _G.UnitIsPlayer(unit), false) then
            local _, class = _G.UnitClass(unit)
            class = K.Plain(class)
            local cc = class and _G.RAID_CLASS_COLORS and _G.RAID_CLASS_COLORS[class]
            if cc then r, g, b = cc.r, cc.g, cc.b end
        end
        t:SetTextColor(r, g, b, 1)
        t:Show()
        return
    end
    local kinds = { top = S.textTop, left = S.textLeft, right = S.textRight, center = S.textCenter }
    local pctText, numText
    for slot, kind in pairs(kinds) do
        local fs = p.texts[slot]
        if kind == "none" then
            fs:Hide()
        elseif kind == "healthPercent" or kind == "healthNumber" or kind == "healthBoth" then
            if not pctText then pctText, numText = HealthTexts(unit) end
            if kind == "healthPercent" then
                fs:SetText(pctText)
            elseif kind == "healthNumber" then
                fs:SetText(numText)
            else
                -- SetFormattedText statt `..`: beide Teile koennen geheim
                -- sein, und formatieren darf der Client sie.
                fs:SetFormattedText("%s  %s", numText, pctText)
            end
            fs:SetTextColor(1, 1, 1, 1)
            fs:Show()
        elseif not onlyHealth then
            if kind == "name" then
                -- Kein `or ""`: ein Wahrheitstest auf einem geheimen Namen
                -- (Schlachtfelder) waere ein Fehler, SetText(nil) nicht.
                fs:SetText(_G.UnitName and (_G.UnitName(unit)))
                fs:SetTextColor(1, 1, 1, 1)
            elseif kind == "level" then
                local text, r, g, b = LevelText(unit)
                fs:SetText(text)
                fs:SetTextColor(r, g, b, 1)
            end
            fs:Show()
        end
    end
end

local function UpdateHealth(p)
    local unit = p.unit
    if not unit then return end
    local max = _G.UnitHealthMax and _G.UnitHealthMax(unit)
    if type(max) ~= "nil" then p.health:SetMinMaxValues(0, max) end
    local cur = _G.UnitHealth and _G.UnitHealth(unit)
    if type(cur) ~= "nil" then p.health:SetValue(cur) end
    FillTexts(p, true)
end

-- Die Farbe des Balkens, in Rangfolge. Jede Frage, die der Client geheim
-- beantwortet, zaehlt als "nein" - die Plakette faellt dann auf die
-- naechste Stufe zurueck, statt mit einem Fehler stehen zu bleiben.
local function BarColor(p)
    local unit = p.unit
    local function C3(c) return c.r, c.g, c.b end

    if p._friendly then
        if S.friendlyClassColor and K.Bool(_G.UnitIsPlayer and _G.UnitIsPlayer(unit), false) then
            local _, class = _G.UnitClass(unit)
            class = K.Plain(class)
            local cc = class and _G.RAID_CLASS_COLORS and _G.RAID_CLASS_COLORS[class]
            if cc then return cc.r, cc.g, cc.b end
        end
        return C3(S.friendlyColor)
    end

    if K.Bool(_G.UnitIsTapDenied and _G.UnitIsTapDenied(unit), false) then
        return C3(S.tapped)
    end
    if S.targetColorEnabled and IsUnit(unit, "target") then return C3(S.target) end
    if S.focusColorEnabled and IsUnit(unit, "focus") then return C3(S.focus) end

    if S.classColorPlayers and K.Bool(_G.UnitIsPlayer and _G.UnitIsPlayer(unit), false) then
        local _, class = _G.UnitClass(unit)
        class = K.Plain(class)
        local cc = class and _G.RAID_CLASS_COLORS and _G.RAID_CLASS_COLORS[class]
        if cc then return cc.r, cc.g, cc.b end
    end

    local inCombat = K.Bool(_G.UnitAffectingCombat and _G.UnitAffectingCombat(unit), true)

    if S.threatColors and inCombat and _G.UnitThreatSituation then
        local status = K.Plain(_G.UnitThreatSituation("player", unit))
        if type(status) == "number" then
            local tank = _G.UnitGroupRolesAssigned
                and _G.UnitGroupRolesAssigned("player") == "TANK"
            if tank then
                if status == 3 then return C3(S.tankAggro) end
                if status == 2 then return C3(S.tankLosing) end
                return C3(S.dpsAggro)
            else
                if status >= 2 then return C3(S.dpsAggro) end
                if status == 1 then return C3(S.dpsNear) end
            end
        end
    end

    local reaction = K.Plain(_G.UnitReaction and _G.UnitReaction(unit, "player"))
    if reaction == 4 then return C3(S.neutral) end

    local cls = K.Plain(_G.UnitClassification and _G.UnitClassification(unit))
    local lvl = K.Plain(_G.UnitLevel and _G.UnitLevel(unit))
    if cls == "worldboss" or lvl == -1 then return C3(S.boss) end
    if S.eliteColoring and (cls == "elite" or cls == "rareelite") then return C3(S.elite) end

    if inCombat or not S.darkenOOC then return C3(S.enemyInCombat) end
    return C3(S.hostile)
end

local function UpdateColor(p)
    if not p.unit then return end
    local r, g, b = BarColor(p)
    K.PaintBar(p.health, r, g, b)
end

local anyTarget = false
local function UpdateTarget(p)
    if not p.unit then return end
    local isTarget = IsUnit(p.unit, "target")
    p.ring:SetShown(S.targetRing and isTarget and not p._friendly)
    p:SetScale(isTarget and (S.targetScale / 100) or 1)
    if anyTarget and not isTarget then
        p:SetAlpha(S.nonTargetAlpha / 100)
    else
        p:SetAlpha(1)
    end
    -- Ziel oben: sonst liegt die ausgewaehlte Plakette halb unter der
    -- naechsten.
    if p.SetFrameLevel then p:SetFrameLevel(isTarget and 20 or 5) end
end

local function UpdateRaidIcon(p)
    if not p.unit or S.raidMarker == "none" then p.raid:Hide() return end
    local idx = K.Plain(_G.GetRaidTargetIndex and _G.GetRaidTargetIndex(p.unit))
    if type(idx) == "number" and idx > 0 and _G.SetRaidTargetIconTexture then
        _G.SetRaidTargetIconTexture(p.raid, idx)
        p.raid:Show()
    else
        p.raid:Hide()
    end
end

local function FullUpdate(p)
    UpdateHealth(p)
    FillTexts(p, false)
    UpdateColor(p)
    UpdateTarget(p)
    UpdateRaidIcon(p)
    if p._friendly then return end
    if S.castEnabled then p.cast:Update() else p.cast:Hide() end
end

--------------------------------------------------
-- Zuweisen und Freigeben
--------------------------------------------------

local function Attach(unit)
    if not (_G.C_NamePlate and _G.C_NamePlate.GetNamePlateForUnit) then return end
    local nameplate = _G.C_NamePlate.GetNamePlateForUnit(unit)
    if not nameplate then return end
    -- In Instanzen sind freundliche Plaketten fuer Addons gesperrt
    -- ("forbidden"): dann bleiben die des Spiels, ohne Fehler.
    if nameplate.IsForbidden and nameplate:IsForbidden() then return end
    local friendly = not K.Bool(_G.UnitCanAttack and _G.UnitCanAttack("player", unit), false)
    if friendly and not S.friendlyEnabled then return end

    local p = table.remove(pool) or Build(nameplate)
    p._friendly = friendly
    p:SetParent(nameplate)
    p:ClearAllPoints()
    p:SetPoint("CENTER", nameplate, "CENTER", 0, 0)
    p.unit, p.nameplate = unit, nameplate
    p.cast:SetUnit(unit)
    Layout(p)
    if not friendly then p.auras:SetUnit(S.auraEnabled and unit or nil) end
    Suppress(nameplate)
    plates[unit] = p
    FullUpdate(p)
    p:Show()
end

local function Detach(unit)
    local p = plates[unit]
    if not p then return end
    plates[unit] = nil
    Restore(p.nameplate)
    p.cast:Stop(false)
    p.cast:SetUnit(nil)
    p.auras:SetUnit(nil)
    p.unit, p.nameplate, p._friendly = nil, nil, nil
    p:Hide()
    p:SetParent(hidden)
    pool[#pool + 1] = p
end

--------------------------------------------------
-- Ereignisse
--------------------------------------------------

local events = CreateFrame("Frame")

local UNIT_EVENTS = {
    UNIT_HEALTH = function(p) UpdateHealth(p) end,
    UNIT_MAXHEALTH = function(p) UpdateHealth(p) end,
    UNIT_NAME_UPDATE = function(p) FillTexts(p, false) UpdateColor(p) end,
    UNIT_LEVEL = function(p) FillTexts(p, false) end,
    UNIT_CLASSIFICATION_CHANGED = function(p) FillTexts(p, false) UpdateColor(p) end,
    UNIT_FLAGS = function(p) UpdateColor(p) end,
    UNIT_THREAT_SITUATION_UPDATE = function(p) UpdateColor(p) end,
    UNIT_THREAT_LIST_UPDATE = function(p) UpdateColor(p) end,
}

local CAST_EVENTS = {
    UNIT_SPELLCAST_START = "update", UNIT_SPELLCAST_CHANNEL_START = "update",
    UNIT_SPELLCAST_CHANNEL_UPDATE = "update", UNIT_SPELLCAST_DELAYED = "update",
    UNIT_SPELLCAST_INTERRUPTIBLE = "update", UNIT_SPELLCAST_NOT_INTERRUPTIBLE = "update",
    UNIT_SPELLCAST_STOP = "stop", UNIT_SPELLCAST_CHANNEL_STOP = "stop",
    UNIT_SPELLCAST_INTERRUPTED = "failed", UNIT_SPELLCAST_FAILED = "failed",
}

local function OnEvent(_, event, unit)
    if event == "NAME_PLATE_UNIT_ADDED" then
        Attach(unit)
        return
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        Detach(unit)
        return
    elseif event == "UNIT_FACTION" then
        -- Wird ein Freund zum Feind (oder umgekehrt), wechselt die Plakette.
        if unit and _G.C_NamePlate and _G.C_NamePlate.GetNamePlateForUnit
           and _G.C_NamePlate.GetNamePlateForUnit(unit) then
            Detach(unit)
            Attach(unit)
        end
        return
    elseif event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_FOCUS_CHANGED" then
        anyTarget = K.Bool(_G.UnitExists and _G.UnitExists("target"), false)
        for _, p in pairs(plates) do
            UpdateTarget(p)
            UpdateColor(p)
        end
        return
    elseif event == "RAID_TARGET_UPDATE" then
        for _, p in pairs(plates) do UpdateRaidIcon(p) end
        return
    end

    local p = unit and plates[unit]
    if not p then return end

    local handler = UNIT_EVENTS[event]
    if handler then handler(p) return end

    local cast = CAST_EVENTS[event]
    if cast and S.castEnabled then
        if cast == "update" then
            p.cast:Update()
        else
            p.cast:Stop(cast == "failed")
        end
    end
end

-- Ereignisse, die ein Client nicht kennt, wirft RegisterEvent als
-- Fehler. Forever ist ungeprueft, also wird jedes einzeln versucht.
local function Register(frame, name)
    local ok = pcall(frame.RegisterEvent, frame, name)
    return ok
end

--------------------------------------------------
-- Einstellungen, die das Spiel selbst haelt (CVars)
--------------------------------------------------
-- Diese drei schreibt die Seite direkt in die Spieleinstellungen - sie
-- gelten also auch, wenn das Modul aus ist, genau wie im Spielmenue.

local function GetCVar(name)
    if _G.C_CVar and _G.C_CVar.GetCVar then return _G.C_CVar.GetCVar(name) end
    if _G.GetCVar then return _G.GetCVar(name) end
    return nil
end

local function SetCVar(name, value)
    if K.InCombat() then return end
    if _G.C_CVar and _G.C_CVar.SetCVar then
        pcall(_G.C_CVar.SetCVar, name, value)
    elseif _G.SetCVar then
        pcall(_G.SetCVar, name, value)
    end
end

NP.GetCVar, NP.SetCVar = GetCVar, SetCVar

--------------------------------------------------
-- Vorschau im Einstellungsfenster
--------------------------------------------------

local preview
function NP.CreatePreview(parent)
    Resolve()
    local host = CreateFrame("Frame", nil, parent)
    host:SetHeight(92)
    local p = Build(host)
    p:SetPoint("CENTER", host, "CENTER", 0, 8)
    preview = p
    NP.RefreshPreview()
    return host, 92
end

function NP.RefreshPreview()
    local p = preview
    if not p then return end
    Resolve()
    Layout(p)
    p.health:SetMinMaxValues(0, 100)
    p.health:SetValue(64)
    local kinds = { top = S.textTop, left = S.textLeft, right = S.textRight, center = S.textCenter }
    local sample = {
        name = "Kobold-Tunnelgräber", level = S.eliteMark and "14+" or "14",
        healthPercent = "64%", healthNumber = "1,2 Tsd", healthBoth = "1,2 Tsd  64%",
    }
    for slot, kind in pairs(kinds) do
        local fs = p.texts[slot]
        if kind == "none" then
            fs:Hide()
        else
            fs:SetText(sample[kind] or "")
            if kind == "level" and S.levelColor then
                fs:SetTextColor(1, 0.82, 0, 1)
            else
                fs:SetTextColor(1, 1, 1, 1)
            end
            fs:Show()
        end
    end
    local c = S.eliteColoring and S.elite or S.enemyInCombat
    K.PaintBar(p.health, c.r, c.g, c.b)
    p.ring:SetShown(S.targetRing)
    if S.raidMarker ~= "none" and _G.SetRaidTargetIconTexture then
        _G.SetRaidTargetIconTexture(p.raid, 8)
        p.raid:Show()
    else
        p.raid:Hide()
    end
    if S.castEnabled then p.cast:ShowPreview(true) else p.cast:ShowPreview(false) end
end

--------------------------------------------------
-- Modul
--------------------------------------------------

local function Enable()
    Resolve()
    for _, e in ipairs({
        "NAME_PLATE_UNIT_ADDED", "NAME_PLATE_UNIT_REMOVED", "UNIT_FACTION",
        "PLAYER_TARGET_CHANGED", "PLAYER_FOCUS_CHANGED", "RAID_TARGET_UPDATE",
    }) do Register(events, e) end
    for e in pairs(UNIT_EVENTS) do Register(events, e) end
    for e in pairs(CAST_EVENTS) do Register(events, e) end
    events:SetScript("OnEvent", OnEvent)

    -- Plaketten, die beim Einschalten schon stehen (Neuladen mitten in
    -- der Welt), bekommen kein ADDED mehr.
    if _G.C_NamePlate and _G.C_NamePlate.GetNamePlates then
        for _, np in ipairs(_G.C_NamePlate.GetNamePlates() or {}) do
            local unit = np.namePlateUnitToken
                or (np.UnitFrame and np.UnitFrame.unit)
            if unit then Attach(unit) end
        end
    end
end

local function OnSetting()
    Resolve()
    for _, p in pairs(plates) do
        Layout(p)
        FullUpdate(p)
    end
    NP.RefreshPreview()
end

local function CVarToggle(label, cvar, onValue, offValue, tooltip)
    return {
        type = "toggle", label = label, tooltip = tooltip,
        get = function() return GetCVar(cvar) == onValue end,
        set = function(on) SetCVar(cvar, on and onValue or offValue) end,
        disabled = function() return GetCVar(cvar) == nil end,
        disabledHint = "Diese Spieleinstellung kennt der Client nicht.",
    }
end

local SLOT_ITEMS = {
    { value = "none",          text = "Nichts" },
    { value = "name",          text = "Name" },
    { value = "level",         text = "Stufe" },
    { value = "healthPercent", text = "Leben in %" },
    { value = "healthNumber",  text = "Leben als Zahl" },
    { value = "healthBoth",    text = "Leben: Zahl und %" },
}

local function pct(v) return string.format("%d %%", v) end
local function px(v) return string.format("%d px", v) end

K.Register({
    key = KEY, group = "ui", order = 10,
    title = "Namensplaketten",
    description = "Eigene Plaketten: Gegner mit Farben nach Lage, Stufe, Debuffs, Zauberbalken und Zielrahmen; Freunde als Name in Klassenfarbe.",
    defaults = defaults,
    Enable = Enable,
    OnSetting = OnSetting,
    preview = NP.CreatePreview,
    pages = {
        { key = "allgemein", label = "Allgemein", build = function(B)
            B:Section("Größe")
            B:Row({ type = "slider", label = "Breite", key = "width", min = 80, max = 250, step = 1, format = px },
                  { type = "slider", label = "Höhe", key = "height", min = 6, max = 30, step = 1, format = px })
            B:Section("Ziel")
            B:Row({ type = "slider", label = "Größe des Ziels", key = "targetScale", min = 100, max = 150, step = 5, format = pct },
                  { type = "slider", label = "Deckkraft der anderen", key = "nonTargetAlpha", min = 30, max = 100, step = 5, format = pct,
                    tooltip = "Wie sichtbar die übrigen Plaketten sind, solange du ein Ziel hast." })
            B:Row({ type = "toggle", label = "Zielrahmen", key = "targetRing",
                    description = "Ein Rahmen im Akzent um die Plakette deines Ziels." },
                  { type = "empty" })
            B:Section("Rahmen")
            B:Row({ type = "toggle", label = "Rand anzeigen", key = "showBorder" },
                  { type = "color", label = "Randfarbe", key = "borderColor",
                    disabled = function() return not K.Get(KEY, "showBorder") end })
            B:Row({ type = "color", label = "Hintergrund", key = "bgColor" }, { type = "empty" })
            B:Section("Spieleinstellungen",
                "Diese Schalter ändern die Einstellung des Spiels selbst und gelten deshalb auch ohne WeintCodex-Plaketten.")
            B:Row(CVarToggle("Plaketten stapeln", "nameplateMotion", "1", "0",
                    "An: Plaketten weichen einander aus. Aus: sie dürfen sich überlappen."),
                  CVarToggle("Gegnerische Begleiter", "nameplateShowEnemyPets", "1", "0"))
            B:Row(CVarToggle("Gegnerische Diener", "nameplateShowEnemyMinions", "1", "0"),
                  { type = "empty" })
        end },
        { key = "farben", label = "Farben", build = function(B)
            B:Section("Gegner")
            B:Row({ type = "color", label = "Feind im Kampf", key = "enemyInCombat" },
                  { type = "color", label = "Feind außerhalb des Kampfes", key = "hostile",
                    disabled = function() return not K.Get(KEY, "darkenOOC") end })
            B:Row({ type = "toggle", label = "Feinde außer Kampf abdunkeln", key = "darkenOOC",
                    description = "Wer (noch) nicht kämpft, trägt die dunklere Farbe." },
                  { type = "color", label = "Neutral", key = "neutral" })
            B:Row({ type = "color", label = "Von anderen markiert", key = "tapped" },
                  { type = "color", label = "Boss", key = "boss" })
            B:Row({ type = "toggle", label = "Elite eigens färben", key = "eliteColoring" },
                  { type = "color", label = "Elite", key = "elite",
                    disabled = function() return not K.Get(KEY, "eliteColoring") end })
            B:Row({ type = "toggle", label = "Spieler in Klassenfarbe", key = "classColorPlayers" },
                  { type = "empty" })
            B:Section("Ziel und Fokus")
            B:Row({ type = "toggle", label = "Fokus eigens färben", key = "focusColorEnabled" },
                  { type = "color", label = "Fokus", key = "focus",
                    disabled = function() return not K.Get(KEY, "focusColorEnabled") end })
            B:Row({ type = "toggle", label = "Ziel eigens färben", key = "targetColorEnabled" },
                  { type = "color", label = "Ziel", key = "target",
                    disabled = function() return not K.Get(KEY, "targetColorEnabled") end })
            B:Section("Bedrohung",
                "Ob du Tank bist, liest WeintCodex aus der zugewiesenen Gruppenrolle. Ohne zugewiesene Rolle gelten die Farben für Schaden und Heilung.")
            B:Row({ type = "toggle", label = "Bedrohungsfarben", key = "threatColors" },
                  { type = "empty" })
            local noThreat = function() return not K.Get(KEY, "threatColors") end
            B:Row({ type = "color", label = "Tank: hält die Aggro", key = "tankAggro", disabled = noThreat },
                  { type = "color", label = "Tank: verliert sie", key = "tankLosing", disabled = noThreat })
            B:Row({ type = "color", label = "Aggro gezogen", key = "dpsAggro", disabled = noThreat },
                  { type = "color", label = "Kurz davor", key = "dpsNear", disabled = noThreat })
        end },
        { key = "texte", label = "Texte", build = function(B)
            B:Section("Textplätze")
            B:Row({ type = "dropdown", label = "Oben", key = "textTop", items = SLOT_ITEMS },
                  { type = "dropdown", label = "Mitte", key = "textCenter", items = SLOT_ITEMS })
            B:Row({ type = "dropdown", label = "Links", key = "textLeft", items = SLOT_ITEMS },
                  { type = "dropdown", label = "Rechts", key = "textRight", items = SLOT_ITEMS })
            B:Row({ type = "slider", label = "Schriftgröße oben", key = "nameSize", min = 8, max = 18, step = 1, format = px },
                  { type = "slider", label = "Schriftgröße im Balken", key = "textSize", min = 7, max = 16, step = 1, format = px })
            B:Section("Stufe")
            B:Row({ type = "toggle", label = "Stufe nach Schwierigkeit färben", key = "levelColor" },
                  { type = "toggle", label = "Elite mit + kennzeichnen", key = "eliteMark" })
            B:Section("Schlachtzugsmarkierung")
            B:Row({ type = "dropdown", label = "Position", key = "raidMarker", items = {
                        { value = "topright", text = "Oben rechts" },
                        { value = "top",      text = "Über dem Namen" },
                        { value = "left",     text = "Links" },
                        { value = "right",    text = "Rechts" },
                        { value = "none",     text = "Aus" } } },
                  { type = "slider", label = "Größe", key = "raidMarkerSize", min = 12, max = 40, step = 1, format = px,
                    disabled = function() return K.Get(KEY, "raidMarker") == "none" end })
        end },
        { key = "auren", label = "Auren", build = function(B)
            local off = function() return not K.Get(KEY, "auraEnabled") end
            B:Section("Debuffs über der Plakette")
            B:Row({ type = "toggle", label = "Debuffs anzeigen", key = "auraEnabled" },
                  { type = "toggle", label = "Nur meine", key = "auraOnlyMine", disabled = off,
                    description = "Aus: alle Debuffs, auch die anderer Spieler." })
            B:Row({ type = "slider", label = "Symbolgröße", key = "auraSize", min = 14, max = 40, step = 1, format = px, disabled = off },
                  { type = "slider", label = "Höchstens", key = "auraMax", min = 1, max = 10, step = 1,
                    format = function(v) return tostring(v) end, disabled = off })
            B:Note("Auf dem neuen Client liest das Spiel die Auren selbst und reicht sie an die Plakette – WeintCodex sieht sie dabei nicht. Deshalb gibt es hier keine Liste einzelner Zauber zum Ein- und Ausblenden.")
        end },
        { key = "freundlich", label = "Freundlich", build = function(B)
            local off = function() return not K.Get(KEY, "friendlyEnabled") end
            B:Section("Freundliche Plaketten",
                "In Dungeons und Schlachtzügen sperrt das Spiel freundliche Plaketten für Addons – dort bleiben die des Spiels.")
            B:Row({ type = "toggle", label = "WeintCodex-Plaketten auch für Freunde", key = "friendlyEnabled" },
                  { type = "toggle", label = "Mit Lebensbalken", key = "friendlyHealth", disabled = off,
                    description = "Aus: nur der Name." })
            B:Row({ type = "toggle", label = "Spieler in Klassenfarbe", key = "friendlyClassColor", disabled = off },
                  { type = "color", label = "Farbe sonst", key = "friendlyColor", disabled = off })
            B:Row({ type = "slider", label = "Schriftgröße", key = "friendlyNameSize", min = 8, max = 20, step = 1, format = px, disabled = off },
                  { type = "empty" })
            B:Row(CVarToggle("Freundliche Spieler zeigen", "nameplateShowFriends", "1", "0"),
                  CVarToggle("Freundliche NPCs zeigen", "nameplateShowFriendlyNPCs", "1", "0"))
        end },
        { key = "zauber", label = "Zauberbalken", build = function(B)
            local off = function() return not K.Get(KEY, "castEnabled") end
            B:Section("Zauberbalken")
            B:Row({ type = "toggle", label = "Zauberbalken anzeigen", key = "castEnabled" },
                  { type = "slider", label = "Höhe", key = "castHeight", min = 8, max = 30, step = 1, format = px, disabled = off })
            B:Row({ type = "toggle", label = "Zaubersymbol", key = "castIcon", disabled = off },
                  { type = "toggle", label = "Restzeit", key = "castTimer", disabled = off })
            B:Section("Unterbrechen")
            B:Row({ type = "color", label = "Unterbrechbar", key = "castColor", disabled = off },
                  { type = "color", label = "Nicht unterbrechbar", key = "castLocked", disabled = off })
            B:Row({ type = "toggle", label = "Rahmen, wenn nicht unterbrechbar", key = "castShield", disabled = off,
                    description = "Ein heller Rand zusätzlich zur Farbe." },
                  { type = "empty" })
        end },
    },
})
