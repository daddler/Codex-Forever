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
    player       = { w = 200, h = 24, p = 6, power = true,  cast = true,  left = "levelname", right = "healthPercent", portrait = "3d" },
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
    -- Der eigene Zauberbalken in der Mitte ist das, worauf man beim
    -- Zaubern schaut: groesser als die an Ziel und Fokus, mit Latenz
    -- (seit 6.3.0.8; im Beta-Test "muss schoener sein").
    playerCastHeight = 20,
    -- Zwischen Spieler und Ziel (ui/layout.lua), nicht darueber hinaus.
    playerCastWidth  = K.LAYOUT_METRICS.castWidth,
    playerCastLatency = true,
    tintedBg      = true,      -- Grund in der dunklen Balkenfarbe
    -- Eingehende Heilung und Schilde hinter dem Leben (6.6.0.6, Beta-Test:
    -- "auch beim Spieler- und Zielrahmen" - wie in den Gruppenrahmen).
    healPrediction = true,
    absorbs        = true,
    -- Treffer und Heilung als kleine Zahl im Rahmen von Spieler und Ziel
    -- (6.6.1.8, Beta-Test: "in kleinen roten Zahlen mit einem Minus davor,
    -- Heilung in Gruen mit einem Plus").
    combatFeedback = true,
    hover         = true,      -- Maus darueber hellt auf
    -- Der eigene Zauberbalken mittig ueber den Leisten, die Kombopunkte
    -- mittig unter der Figur (Cockpit). Aus: beides am Rahmen wie bisher.
    playerCastCentered = true,
    comboCentered      = true,
    castIcon      = true,
    castTimer     = true,
    castTarget    = true,     -- Ziel des Zaubers bei Ziel und Fokus
    castColor     = K.ColorDefault("cast"),
    castLocked    = K.ColorDefault("castLocked"),
    replacePlayerCast = true,
    comboPoints   = true,
    targetAuras   = true,
    -- Woher die Symbole am Zielrahmen kommen: "game" (der Aurenbehaelter
    -- des Zielrahmens des Spiels, auch im Kampf) oder "own" (eigene
    -- Symbole ueber ui/auras.lua - im Kampf leer, gemessen 6.3.0.2).
    targetAuraSource = "game",
    targetGameScale  = 100,
    -- Lage der Symbole ueber dem Zielrahmen (Beta-Test 6.4.0.3: "optional
    -- einstellbar"): links- oder rechtsbuendig, Abstand zum Rahmen.
    targetAuraAlign  = "left",
    targetAuraGap    = 3,
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

-- Symbol fuer Kampf und Ruhe am Spielerrahmen (Beta-Test 6.3.2.0: "ein
-- Symbol, wenn man im Kampf ist, im Ruhemodus (Gasthaus)"). Eigene
-- Grafiken (make_ui_media.py), keine des Spiels.
defaults.player_stateIcon = true

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

-- Stufe wie auf der Plakette: in der Farbe der Schwierigkeit, Elite mit
-- "+". Eine Stufe, die der Client nicht nennt (Boss, geheim), ist "??" in
-- Rot - nie eine 0.
local function LevelParts(unit)
    local lvl = K.Plain(_G.UnitLevel and _G.UnitLevel(unit))
    if type(lvl) ~= "number" or lvl < 0 then return "??", 1, 0.2, 0.2 end
    local text = tostring(lvl)
    local cls = K.Plain(_G.UnitClassification and _G.UnitClassification(unit))
    if cls == "elite" or cls == "rareelite" or cls == "worldboss" then text = text .. "+" end
    local r, g, b = 1, 0.82, 0
    if _G.GetCreatureDifficultyColor then
        local c = _G.GetCreatureDifficultyColor(lvl)
        if type(c) == "table" and type(K.Plain(c.r)) == "number" then r, g, b = c.r, c.g, c.b end
    end
    return text, r, g, b
end
UF.LevelParts = LevelParts

-- Ein Name, den der Client noch nicht kennt ("Unbekannt" beim Einloggen),
-- zaehlt als keiner - dann zeichnet der Rahmen einen Takt spaeter nach.
local function NameText(unit, kind)
    local name = _G.UnitName and (_G.UnitName(unit))
    local plain = K.Plain(name)
    if type(plain) == "string" and (plain == "" or plain == _G.UNKNOWNOBJECT or plain == _G.UNKNOWN) then
        name = nil
    end
    if kind == "levelname" then
        local lt, r, g, b = LevelParts(unit)
        return string.format("|cff%02x%02x%02x%s|r", r * 255, g * 255, b * 255, lt), name
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
        return type(name) ~= "nil"
    elseif kind == "levelname" then
        local lvl, name = NameText(unit, kind)
        if type(name) ~= "nil" then fs:SetFormattedText("%s  %s", lvl, name) else fs:SetText(lvl) end
        return type(name) ~= "nil"
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
    uf_playercast = { label = "Eigener Zauberbalken", w = K.LAYOUT_METRICS.castWidth },
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

    -- Heilung und Schild in einer Klammer ueber dem Lebensbalken (wie in
    -- den Gruppenrahmen): links an der Kante der Fuellung, so breit wie
    -- der Balken; wie weit sie reichen, rechnet der Client (Wert /
    -- Hoechstwert) - Lua addiert nie geheime Zahlen. Was ueber den
    -- Balken hinausragt, schneidet die Klammer ab.
    local clip = CreateFrame("Frame", nil, f)
    if clip.SetClipsChildren then pcall(clip.SetClipsChildren, clip, true) end
    clip:SetAllPoints(health)
    clip:SetFrameLevel((health:GetFrameLevel() or 1) + 1)
    f._predClip = clip
    local fill = health:GetStatusBarTexture()
    f._heal = K.NewBar(clip, true)
    f._absorb = K.NewBar(clip, true)
    if fill then
        f._heal:SetPoint("TOPLEFT", fill, "TOPRIGHT", 0, 0)
        f._heal:SetPoint("BOTTOMLEFT", fill, "BOTTOMRIGHT", 0, 0)
    end
    -- Der Schild liegt UEBER dem Leben, vom rechten Rand her (seit
    -- 6.6.1.6). Hinter der Fuellung, wie die Heilung, war er bei vollem
    -- Leben ganz abgeschnitten - Beta-Test: "wenn ich mir ein Schild gebe,
    -- sehe ich nichts". Wie weit er reicht, rechnet weiter der Client.
    f._absorb:SetAllPoints(health)
    if f._absorb.SetReverseFill then f._absorb:SetReverseFill(true) end
    f._absorb:SetFrameLevel(clip:GetFrameLevel() + 1)
    f._heal:Hide()
    f._absorb:Hide()

    local power = K.NewBar(f, true)
    f.power = power
    local pbg = power:CreateTexture(nil, "BACKGROUND")
    pbg:SetAllPoints(power)
    f.powerBg = pbg

    f.border = K.Border(f, 1, 0, 0, 0, 1, "BORDER")
    f._shadow = K.Glow(f, { spread = 6, shadow = true })

    -- Maus darueber: der Lebensbalken hellt auf wie auf der Plakette.
    local GC = WeintCodex.GameColors
    local hf = health:CreateTexture(nil, "OVERLAY", nil, 1)
    hf:SetAllPoints(health)
    hf:SetColorTexture(GC.hoverFill[1], GC.hoverFill[2], GC.hoverFill[3], GC.hoverFill[4])
    if hf.SetBlendMode then hf:SetBlendMode("ADD") end
    hf:Hide()
    f._hover = hf

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
        -- Kamera erst setzen, wenn das Modell geladen ist - vorher wirkt
        -- sie auf nichts, und das Portraet bleibt schwarz.
        pcall(model.SetScript, model, "OnModelLoaded", function(m)
            if m.SetPortraitZoom then m:SetPortraitZoom(1) end
            if m.SetCamDistanceScale then m:SetCamDistanceScale(1) end
        end)
    end
    pf:Hide()
    f._portrait = pf

    -- Treffer und Heilung (UNIT_COMBAT): eine kleine Zahl ueber dem
    -- Portraet (ohne Portraet mitten im Lebensbalken), die nach einer
    -- Sekunde ausblendet - so zeigt es auch der Rahmen des Spiels.
    if unit == "player" or unit == "target" then
        local fbHost = CreateFrame("Frame", nil, f)
        fbHost:SetAllPoints(f)
        fbHost:SetFrameLevel((f:GetFrameLevel() or 1) + 20)
        f._fb = K.NewText(fbHost, 11)
        f._fb:Hide()
        fbHost:SetScript("OnUpdate", K.Measured("Einheitenrahmen", function(_, elapsed)
            local left = f._fbLeft
            if not left then return end
            left = left - (elapsed or 0)
            if left <= 0 then
                f._fbLeft = nil
                f._fb:Hide()
            else
                f._fbLeft = left
                if left < UF.FEEDBACK_FADE then f._fb:SetAlpha(left / UF.FEEDBACK_FADE) end
            end
        end))
    end

    local textHost = CreateFrame("Frame", nil, f)
    textHost:SetAllPoints(health)
    textHost:SetFrameLevel(health:GetFrameLevel() + 3)
    f.left = K.NewText(textHost)
    f.left:SetJustifyH("LEFT")
    f.left:SetWordWrap(false)
    f.right = K.NewText(textHost)
    f.right:SetJustifyH("RIGHT")
    f.right:SetWordWrap(false)

    f.raid = K.NewRaidIcon(textHost, 18)
    f.raid:SetPoint("CENTER", f, "TOP", 0, 2)

    if unit == "player" then
        -- Oben links an der Ecke, halb ueber dem Rahmen; ein schwarzer
        -- Schatten darunter, damit es auf jedem Portraet lesbar bleibt.
        local st = CreateFrame("Frame", nil, f)
        st:SetSize(18, 18)
        st:SetPoint("CENTER", f, "TOPLEFT", 2, -2)
        st:SetFrameLevel(textHost:GetFrameLevel() + 2)
        st.shade = st:CreateTexture(nil, "ARTWORK", nil, 1)
        st.shade:SetPoint("TOPLEFT", st, "TOPLEFT", 1, -1)
        st.shade:SetPoint("BOTTOMRIGHT", st, "BOTTOMRIGHT", 1, -1)
        st.shade:SetVertexColor(0, 0, 0, 0.9)
        st.icon = st:CreateTexture(nil, "ARTWORK", nil, 2)
        st.icon:SetAllPoints(st)
        -- Ruhe als Schrift "zZ" (Beta-Test: "statt Mond ein zZ, das ist
        -- einfacher") - scharf in jeder Groesse, keine Grafik noetig.
        st.text = K.NewText(st, 13, "OVERLAY")
        st.text:SetPoint("CENTER", st, "CENTER", 1, 0)
        st.text:SetText("zZ")
        st.text:Hide()
        -- Im Kampf pulsiert es leicht.
        local ag = st.CreateAnimationGroup and st:CreateAnimationGroup()
        if type(ag) == "table" and ag.CreateAnimation then
            local a = ag:CreateAnimation("Alpha")
            if type(a) == "table" then
                if a.SetFromAlpha then a:SetFromAlpha(1) a:SetToAlpha(0.45) end
                if a.SetDuration then a:SetDuration(0.6) end
                if ag.SetLooping then ag:SetLooping("BOUNCE") end
                st.pulse = ag
            end
        end
        st:Hide()
        f._state = st
    end

    if SHAPE[unit].cast then
        f._cast = CB.Create(f)
        f._cast:SetUnit(unit)
    end

    if unit == "target" then
        -- Kombopunkte: fuenf einzelne Segmente mit Luft dazwischen (UI 2.0).
        -- Jedes ist ein eigener Balken von i-1 bis i, und ALLE bekommen
        -- denselben Stand per SetValue: Segment 3 ist voll, sobald der Stand
        -- 3 erreicht - ohne dass Lua den (womoeglich geheimen) Stand je mit
        -- 3 vergleicht.
        local cp = CreateFrame("Frame", nil, f)
        cp:SetHeight(5)
        cp.pips = {}
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
        if Opt("hover") then self._hover:Show() end
        if _G.UnitFrame_OnEnter then
            _G.UnitFrame_OnEnter(self)
        elseif _G.GameTooltip_SetDefaultAnchor then
            _G.GameTooltip_SetDefaultAnchor(GameTooltip, self)
            GameTooltip:SetUnit(self.unit)
            GameTooltip:Show()
        end
    end)
    f:SetScript("OnLeave", function(self)
        self._hover:Hide()
        if _G.UnitFrame_OnLeave then _G.UnitFrame_OnLeave(self) else GameTooltip:Hide() end
    end)
    -- Erscheint der Rahmen (UnitWatch: neues Ziel, Fokus, Begleiter),
    -- zeichnet er sich sofort - nicht erst beim naechsten Ereignis.
    f:HookScript("OnShow", function(self)
        if self._testShown then return end
        self:Refresh()
        self:UpdatePortrait()
    end)

    -- Ziel des Ziels meldet keine eigenen Ereignisse: der Client nennt
    -- seine Lebenspunkte nur auf Nachfrage. Fuenfmal je Sekunde, und nur
    -- solange der Rahmen zu sehen ist (versteckte Rahmen laufen nicht).
    if unit == "targettarget" then
        local acc = 0
        f:SetScript("OnUpdate", K.Measured("Einheitenrahmen", function(self, el)
            acc = acc + (el or 0)
            if acc < 0.2 then return end
            acc = 0
            self:Refresh()
        end))
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
        -- Ohne Modelldatei (im Beta-Client beim Ziel gesehen: ein schwarzes
        -- Kaestchen) das Bild statt des Modells. Einen Augenblick spaeter:
        -- das Modell laedt nicht sofort.
        local me, token = self, (self._portraitToken or 0) + 1
        self._portraitToken = token
        if _G.C_Timer and _G.C_Timer.After and pf.model.GetModelFileID then
            _G.C_Timer.After(0.4, function()
                if me._portraitToken ~= token or not pf.model:IsShown() then return end
                local id = K.Plain(pf.model:GetModelFileID())
                if type(id) ~= "number" or id <= 0 then
                    pf.model:Hide()
                    pf.tex:Show()
                    if _G.SetPortraitTexture then _G.SetPortraitTexture(pf.tex, u) end
                end
            end)
        end
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
    if self._fb then
        self._fb:ClearAllPoints()
        self._fb:SetPoint("CENTER", pf:IsShown() and pf or self.health, "CENTER", 0, 0)
    end

    self.health:ClearAllPoints()
    self.health:SetPoint("TOPLEFT", self, "TOPLEFT", right and 0 or inset, 0)
    self.health:SetPoint("TOPRIGHT", self, "TOPRIGHT", right and -inset or 0, 0)
    self.health:SetHeight(h)
    local hw = math.max(1, w - inset)
    self._heal:SetWidth(hw)
    local hc, ac = WeintCodex.GameColors.healPredict, WeintCodex.GameColors.absorbOver
    self._heal:SetStatusBarColor(hc[1], hc[2], hc[3], hc[4])
    self._absorb:SetStatusBarColor(ac[1], ac[2], ac[3], ac[4])
    self.power:ClearAllPoints()
    self.power:SetPoint("TOPLEFT", self.health, "BOTTOMLEFT", 0, -1)
    self.power:SetPoint("TOPRIGHT", self.health, "BOTTOMRIGHT", 0, -1)
    self.power:SetHeight(math.max(1, ph))
    if showPower then self.power:Show() else self.power:Hide() end

    local bg = K.GetColor(KEY, "bgColor")
    self.healthBg:SetColorTexture(bg.r, bg.g, bg.b, 1)
    self._bgR = nil
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
        local centered = (u == "player" and Opt("playerCastCentered"))
        if centered then
            local hf = Holder("uf_playercast")
            hf:SetSize(Opt("playerCastWidth"), Opt("playerCastHeight"))
            self._cast:SetPoint("TOPLEFT", hf, "TOPLEFT", 0, 0)
            self._cast:SetPoint("TOPRIGHT", hf, "TOPRIGHT", 0, 0)
        else
            self._cast:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -4)
            self._cast:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, -4)
        end
        self._cast:ApplyStyle({
            height = centered and Opt("playerCastHeight") or Opt("castHeight"),
            latency = (u == "player") and Opt("playerCastLatency"),
            icon = Opt("castIcon"), timer = Opt("castTimer"),
            cast = K.GetColor(KEY, "castColor"), locked = K.GetColor(KEY, "castLocked"),
            bg = bg, border = Opt("showBorder"),
            -- Beim eigenen Zauber waere das Ziel das eigene Ziel - das
            -- steht schon im Zielrahmen.
            target = (u ~= "player") and Opt("castTarget"),
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
        cp._max = nil   -- Segmente neu verteilen: die Breite hat sich geaendert
    end

    if self._auras then self:LayoutAuras() end
end

-- Grund unter dem fehlenden Leben: dunkler Ton der Balkenfarbe (wie die
-- Plakette), sonst die eingestellte Hintergrundfarbe.
local TINT = 0.22
function Frame:PaintBg(r, g, b)
    local bg = K.GetColor(KEY, "bgColor")
    local br, bgg, bb = bg.r, bg.g, bg.b
    if Opt("tintedBg") then
        br, bgg, bb = br * (1 - TINT) + r * TINT, bgg * (1 - TINT) + g * TINT, bb * (1 - TINT) + b * TINT
    end
    if self._bgR == br and self._bgG == bgg and self._bgB == bb then return end
    self._bgR, self._bgG, self._bgB = br, bgg, bb
    self.healthBg:SetColorTexture(br, bgg, bb, 1)
end

-- Treffer und Heilung als Zahl. UNIT_COMBAT(unit, action, flag, amount):
-- "WOUND" ist erlittener Schaden, "HEAL" erhaltene Heilung; Ausweichen,
-- Parieren usw. zeigt WeintCodex nicht. Ist die Art geheim, kann Lua
-- nicht unterscheiden - dann keine Zahl statt einer falschen Farbe. Die
-- Zahl selbst darf geheim sein: sie geht gekuerzt (UIDamageMeter.Format,
-- dieselben Stufen wie die Schadensanzeige) und ueber SetFormattedText an
-- den Client, Lua rechnet nie damit.
UF.FEEDBACK_HOLD, UF.FEEDBACK_FADE = 1.0, 0.6
function Frame:CombatFeedback(action, flag, amount)
    local fs = self._fb
    if not fs or not Opt("combatFeedback") then return end
    local act = K.Plain(action)
    if act ~= "WOUND" and act ~= "HEAL" then return end
    if type(amount) == "nil" then return end
    local plain = K.Plain(amount)
    if type(plain) == "number" and plain <= 0 then return end
    local DM = WeintCodex.UIDamageMeter
    local ok, text = pcall(DM and DM.Format or tostring, amount)
    if not ok or type(text) == "nil" then return end
    local c = act == "WOUND" and WeintCodex.Colors.danger or WeintCodex.Colors.success
    K.SetFont(fs, K.Plain(flag) == "CRITICAL" and 13 or 11)
    fs:SetTextColor(c[1], c[2], c[3], 1)
    if not pcall(fs.SetFormattedText, fs, act == "WOUND" and "-%s" or "+%s", text) then return end
    fs:SetAlpha(1)
    fs:Show()
    self._fbLeft = UF.FEEDBACK_HOLD + UF.FEEDBACK_FADE
end

-- Eingehende Heilung und Schilde. Keine Antwort des Clients: kein Balken.
function Frame:UpdatePrediction()
    local u = self.unit
    local max = _G.UnitHealthMax and _G.UnitHealthMax(u)
    local function Show(bar, on, value)
        if not on or type(max) == "nil" or type(value) == "nil" then bar:Hide() return end
        bar:SetMinMaxValues(0, max)
        bar:SetValue(value)
        bar:Show()
    end
    Show(self._heal, Opt("healPrediction"), _G.UnitGetIncomingHeals and _G.UnitGetIncomingHeals(u))
    Show(self._absorb, Opt("absorbs"), _G.UnitGetTotalAbsorbs and _G.UnitGetTotalAbsorbs(u))
end

function Frame:Refresh()
    local u = self.unit
    if not K.Bool(_G.UnitExists and _G.UnitExists(u), false) and not self._unlockShown then return end

    local max = _G.UnitHealthMax and _G.UnitHealthMax(u)
    if type(max) ~= "nil" then self.health:SetMinMaxValues(0, max) end
    local cur = _G.UnitHealth and _G.UnitHealth(u)
    if type(cur) ~= "nil" then self.health:SetValue(cur) end
    local hr, hg, hb = HealthColor(u)
    K.PaintBar(self.health, hr, hg, hb)
    self:PaintBg(hr, hg, hb)
    self:UpdatePrediction()

    if Opt(u .. "_power") then
        local pmax = _G.UnitPowerMax and _G.UnitPowerMax(u)
        if type(pmax) ~= "nil" then self.power:SetMinMaxValues(0, pmax) end
        local p = _G.UnitPower and _G.UnitPower(u)
        if type(p) ~= "nil" then self.power:SetValue(p) end
        K.PaintBar(self.power, PowerColor(u))
    end

    -- NAME BEIM EINLOGGEN (6.6.0.1, Beta-Test: "manchmal ist mein Name
    -- nicht auf meinem Spielerfenster"). Der Name wird nur beim Aufbau und
    -- bei UNIT_NAME_UPDATE gesetzt, die Lebensanzeige daneben bei jedem
    -- Treffer. Kennt der Client den Namen noch nicht, oder ist die eigene
    -- Schrift beim ersten Setzen noch nicht geladen, blieb er leer, bis
    -- zufaellig UNIT_NAME_UPDATE kam. Jetzt: ohne Namen ein Wiederholversuch,
    -- und nach dem Einloggen zeichnen alle Rahmen ihre Texte zweimal neu
    -- (UF.RedrawTexts), mit geleertem Text, damit gleicher Text neu gesetzt wird.
    local okL = Fill(self.left, u, Opt(u .. "_left"))
    local okR = Fill(self.right, u, Opt(u .. "_right"))
    if okL == false or okR == false then
        -- Hoechstens zehnmal je Einheit, einmal je Sekunde.
        self._nameTries = (self._nameTries or 0) + 1
        if not self._nameRetry and self._nameTries <= 10 and _G.C_Timer and _G.C_Timer.After then
            self._nameRetry = true
            _G.C_Timer.After(1, function()
                self._nameRetry = nil
                if self:IsShown() then self:Refresh() end
            end)
        end
    else
        self._nameTries = 0
    end

    K.ShowRaidIcon(self.raid, u)

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
    self:SetCombo(cur, max)
end

local PIP_GAP = 3

-- Die Segmente fuer `max` Punkte anlegen und verteilen - einmal je
-- Hoechstwert und nach jedem Layout (die Breite kann sich geaendert haben).
function Frame:ComboPips(max)
    local cp = self._combo
    if cp._max == max then return end
    cp._max = max
    local w = cp:GetWidth()
    if type(w) ~= "number" or w <= 0 then w = self:GetWidth() or 200 end
    local pw = (w - PIP_GAP * (max - 1)) / max
    local col = WeintCodex.GameColors.comboPoint
    for i = 1, math.max(max, #cp.pips) do
        local pip = cp.pips[i]
        if i <= max then
            if not pip then
                pip = K.NewBar(cp)
                local bg = pip:CreateTexture(nil, "BACKGROUND")
                bg:SetAllPoints(pip)
                bg:SetColorTexture(0, 0, 0, 0.6)
                pip._border = K.Border(pip, 1, 0, 0, 0, 1, "BORDER")
                cp.pips[i] = pip
            end
            pip:SetMinMaxValues(i - 1, i)
            K.PaintBar(pip, col[1], col[2], col[3])
            pip:ClearAllPoints()
            pip:SetPoint("TOPLEFT", cp, "TOPLEFT", (i - 1) * (pw + PIP_GAP), 0)
            pip:SetPoint("BOTTOMLEFT", cp, "BOTTOMLEFT", (i - 1) * (pw + PIP_GAP), 0)
            pip:SetWidth(pw)
            pip:Show()
        elseif pip then
            pip:Hide()
        end
    end
end

function Frame:SetCombo(cur, max)
    self:ComboPips(max)
    for i = 1, max do self._combo.pips[i]:SetValue(cur) end
    self._combo:Show()
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

local UseGameAuras   -- siehe "Auren des Spiels am Zielrahmen"

-- Unterkante der Symbole ueber dem Rahmen: der eingestellte Abstand, bei
-- Kombopunkten ueber dem Rahmen (nicht mittig) zusaetzlich deren Hoehe.
function UF.AuraBaseY(f)
    local gap = Opt("targetAuraGap") or 3
    return gap + ((f._combo and Opt("comboPoints") and not Opt("comboCentered")) and 7 or 0)
end

function Frame:LayoutAuras()
    if UseGameAuras() then
        UF.ConfigureGameAuras()
        UF.AnchorGameAuras()
    end
    local size = Opt("auraSize")
    local y0 = UF.AuraBaseY(self)
    local right = Opt("targetAuraAlign") == "right"
    local pt, rel = right and "BOTTOMRIGHT" or "BOTTOMLEFT", right and "TOPRIGHT" or "TOPLEFT"
    local debuffFilter = Opt("onlyOwnDebuffs") and "HARMFUL|PLAYER" or "HARMFUL"
    local rows = {
        { self._auras.HARMFUL, debuffFilter, y0 },
        { self._auras.HELPFUL, "HELPFUL", y0 + size + 3 },
    }
    for _, r in ipairs(rows) do
        local obj = r[1]
        obj:ApplyLayout({ filter = r[2], max = 8, size = size, spacing = 3,
            anchor = pt, growth = right and "LEFT" or "RIGHT", growthV = "UP", perRow = 8, timer = true })
        obj:ClearAllPoints()
        obj:SetPoint(pt, self, rel, 0, r[3])
    end
end

function Frame:UpdateAuras()
    local on = Opt("targetAuras") and true or false
    local game = UseGameAuras()
    for _, obj in pairs(self._auras) do
        obj:SetShown(on and not game)
        if on and not game then obj:Refresh() end
    end
    if game then UF.ShowGameAuras(on) end
end

--------------------------------------------------
-- Auren des Spiels am Zielrahmen (6.4.0.3)
--------------------------------------------------
-- Eigene Symbole bleiben im Kampf leer: dort sperrt der Client Addons das
-- Lesen von Auren (gemessen 6.3.0.2), und die Knoepfe eines eigenen
-- Aurenbehaelters sind verboten. Die Debuffs auf den Plaketten sind
-- deshalb schon die Symbole des Spiels. Beim Zielrahmen geht dasselbe:
-- der Zielrahmen des Spiels traegt einen Aurenbehaelter
-- (TargetFrame.TargetFrameContent.TargetFrameContentContextual.Auras,
-- TargetFrame.lua im 12.x-Quelltext), den das Spiel selbst fuellt.
--
-- Bei targetAuraSource = "game" bleibt der Zielrahmen des Spiels deshalb
-- am Leben: alles an ihm unsichtbar ausser dem Behaelter, ohne Maus, und
-- der Behaelter haengt ueber UNSEREM Zielrahmen. Kein Feld am Rahmen des
-- Spiels wird geschrieben - Blizzard-Code, der einen von uns gesetzten
-- Wert liest, liefe unsicher weiter und scheiterte an geheimen Werten.
-- Gesetzt wird nur ueber Methoden des Behaelters, NACH dem Spiel
-- (hooksecurefunc auf ConfigureAuraContainer/AnchorAuraContainer):
--   * Wachsen nach oben (wie "Buffs oben" im Bearbeitungsmodus),
--   * keine verkuerzten Reihen neben dem (unsichtbaren) Ziel des Ziels,
--   * Reihenbreite = Breite unseres Zielrahmens.
-- Ob der Forever-Client den Behaelter so nennt, ist nicht gemessen -
-- /wcui auren nennt UF.gameAuraState. Fehlt er, wird der Zielrahmen des
-- Spiels wie bisher ganz versteckt und es gelten die eigenen Symbole.

UF.gameAuraState = "nicht verwendet"
local gameAuras        -- der Behaelter, wenn der Weg steht
local gameHooked = false
local gameSizes        -- { klein, gross } des Spiels, bevor wir sie aendern
local anchoringGame = false

UseGameAuras = function()
    return gameAuras ~= nil and Opt("targetAuraSource") == "game"
end

-- Behaelter und der Weg dorthin (Zielrahmen -> Inhalt -> Kontext -> Auren).
local function FindGameAuras()
    local tf = _G.TargetFrame
    if type(tf) ~= "table" then return nil, "kein Zielrahmen des Spiels" end
    if tf.IsForbidden and tf:IsForbidden() then return nil, "Zielrahmen des Spiels verboten" end
    local content = tf.TargetFrameContent
    local ctx = type(content) == "table" and content.TargetFrameContentContextual or nil
    local auras = type(ctx) == "table" and ctx.Auras or nil
    if type(auras) ~= "table" or type(auras.SetPoint) ~= "function" then
        return nil, "Aurenbehälter des Spiels nicht gefunden"
    end
    if auras.IsForbidden and auras:IsForbidden() then return nil, "Aurenbehälter des Spiels verboten" end
    return { tf, content, ctx, auras }
end

local function KeepHiddenPart(r)
    local AB = WeintCodex.UIActionBars
    if AB and AB.KeepHidden then AB.KeepHidden(r) else r:SetAlpha(0) end
end

-- Alles an `parent` unsichtbar ausser `keep` (Kinder und Flaechen).
local function DimAllBut(parent, keep)
    for _, ch in ipairs({ parent:GetChildren() }) do
        if ch ~= keep and type(ch) == "table" and ch.SetAlpha then KeepHiddenPart(ch) end
    end
    for _, rg in ipairs({ parent:GetRegions() }) do
        if type(rg) == "table" and rg.SetAlpha then KeepHiddenPart(rg) end
    end
end

-- Keine Maus fuer den ganzen Zielrahmen des Spiels ausser dem Behaelter:
-- ein unsichtbarer Rahmen, der Klicks faengt, waere eine Falle. Nur
-- ausserhalb des Kampfes (Build laeuft dort) - Rahmen und Ziel des Ziels
-- sind geschuetzt.
local function NoMouse(f, keep)
    if f == keep or type(f) ~= "table" then return end
    if f.EnableMouse then pcall(f.EnableMouse, f, false) end
    local ok, kids = pcall(function() return { f:GetChildren() } end)
    if ok then
        for _, ch in ipairs(kids) do NoMouse(ch, keep) end
    end
end

local function Call(obj, name, ...)
    local fn = obj[name]
    if type(fn) ~= "function" then return false end
    return pcall(fn, obj, ...)
end

-- Masse unseres Rahmens im Massstab des Behaelters.
local function Ratio(f)
    local a = K.Plain(gameAuras.GetEffectiveScale and gameAuras:GetEffectiveScale())
    local b = K.Plain(f.GetEffectiveScale and f:GetEffectiveScale())
    if type(a) ~= "number" or type(b) ~= "number" or a <= 0 then return 1 end
    return b / a
end

-- Ist der Behaelter geschuetzt, darf er im Kampf nicht angefasst werden
-- (das waere "Aktion blockiert", kein abfangbarer Fehler) - dann nach dem
-- Kampf.
local function Locked()
    return K.Bool(_G.InCombatLockdown and _G.InCombatLockdown(), false)
        and gameAuras.IsProtected and K.Bool(gameAuras:IsProtected(), false)
end

-- Nach ConfigureAuraContainer des Spiels: nach oben wachsen, volle Reihen.
local ConfigureGameAuras
ConfigureGameAuras = function()
    local f = frames.target
    if not (gameAuras and f) then return end
    if Locked() then K.AfterCombat(ConfigureGameAuras) return end
    -- Groesse ueber die Symbolgroessen des Behaelters (scharf), nicht ueber
    -- SetScale. Die Ausgangsgroessen des Spiels einmal gemerkt.
    if not gameSizes then
        local okS, small = Call(gameAuras, "GetSmallAuraSize")
        local okL, large = Call(gameAuras, "GetLargeAuraSize")
        small, large = K.Plain(small), K.Plain(large)
        if okS and okL and type(small) == "number" and type(large) == "number" and small > 0 and large > 0 then
            gameSizes = { small, large }
        end
    end
    local scale = (Opt("targetGameScale") or 100) / 100
    if gameSizes then
        Call(gameAuras, "SetSmallAuraSize", math.floor(gameSizes[1] * scale + 0.5))
        Call(gameAuras, "SetLargeAuraSize", math.floor(gameSizes[2] * scale + 0.5))
    else
        Call(gameAuras, "SetScale", scale)
    end
    Call(gameAuras, "SetFlowLayoutMirroredVertically", true)
    -- Rechtsbuendig: von rechts nach links, jede Reihe endet am rechten Rand.
    -- SetFlowLayoutMirroredVertically setzt den Ankerpunkt auf BOTTOMLEFT,
    -- darum danach.
    local FD = _G.AnchorUtil and _G.AnchorUtil.FlowDirection
    if FD then
        local right = Opt("targetAuraAlign") == "right"
        Call(gameAuras, "SetFlowLayoutAnchorPoint", right and "BOTTOMRIGHT" or "BOTTOMLEFT")
        Call(gameAuras, "SetFlowLayoutGrowthDirection", right and FD.Left or FD.Right, FD.Up)
    end
    Call(gameAuras, "SetNumConstrainedFlowLayoutLines", 0)
    local w = K.Plain(f:GetWidth())
    if type(w) == "number" and w > 0 then
        Call(gameAuras, "SetFlowLayoutMaximumLineSize", w * Ratio(f))
    end
    if not Opt("targetAuras") then Call(gameAuras, "Hide") end
end
UF.ConfigureGameAuras = ConfigureGameAuras

function UF.AnchorGameAuras()
    local f = frames.target
    if anchoringGame or not (gameAuras and f) then return end
    if Locked() then K.AfterCombat(UF.AnchorGameAuras) return end
    anchoringGame = true
    local y = UF.AuraBaseY(f)
    local right = Opt("targetAuraAlign") == "right"
    local ok, err = pcall(function()
        gameAuras:ClearAllPoints()
        gameAuras:SetPoint(right and "BOTTOMRIGHT" or "BOTTOMLEFT", f, right and "TOPRIGHT" or "TOPLEFT", 0, y * Ratio(f))
    end)
    anchoringGame = false
    UF.gameAuraState = ok and "Symbole des Spiels über dem Zielrahmen"
        or ("vom Spiel abgelehnt: " .. tostring(err))
end

function UF.ShowGameAuras(on)
    if not gameAuras or Locked() then return end
    if on then Call(gameAuras, "Show") else Call(gameAuras, "Hide") end
end

-- Aufgerufen aus Build, ausserhalb des Kampfes. true = der Weg steht, der
-- Zielrahmen des Spiels darf NICHT versteckt werden.
local function SetupGameAuras()
    if Opt("targetAuraSource") ~= "game" then
        UF.gameAuraState = "eigene Symbole gewählt"
        return false
    end
    local path, why = FindGameAuras()
    if not path then
        UF.gameAuraState = why .. " – eigene Symbole"
        return false
    end
    local tf, content, ctx, auras = path[1], path[2], path[3], path[4]
    local ok, err = pcall(function()
        DimAllBut(tf, content)
        DimAllBut(content, ctx)
        DimAllBut(ctx, auras)
        NoMouse(tf, auras)
    end)
    if not ok then
        UF.gameAuraState = "Zielrahmen des Spiels nicht auszublenden (" .. tostring(err) .. ") – eigene Symbole"
        return false
    end
    gameAuras = auras
    if not gameHooked and _G.hooksecurefunc then
        gameHooked = true
        if type(tf.ConfigureAuraContainer) == "function" then
            _G.hooksecurefunc(tf, "ConfigureAuraContainer", ConfigureGameAuras)
        end
        if type(tf.AnchorAuraContainer) == "function" then
            _G.hooksecurefunc(tf, "AnchorAuraContainer", UF.AnchorGameAuras)
        end
    end
    ConfigureGameAuras()
    UF.AnchorGameAuras()
    return true
end
UF._SetupGameAuras = SetupGameAuras   -- fuer den Prueflauf

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
            self._heal:Hide()
            self._absorb:Hide()
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
    target       = { name = "Kobold-Geomant", level = "23", color = "enemyInCombat", hp = 0.58, power = 0.7, ptoken = "MANA",
                     heal = 0.14, absorb = 0.08 },
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
        self:PaintBg(TestColor(t))
        for _, pair in ipairs({ { self._heal, "healPrediction", t.heal }, { self._absorb, "absorbs", t.absorb } }) do
            local bar, key, v = pair[1], pair[2], pair[3]
            if v and Opt(key) then
                bar:SetMinMaxValues(0, 1)
                bar:SetValue(v)
                bar:Show()
            else
                bar:Hide()
            end
        end
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
            self:SetCombo(3, 5)
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

-- NICHT nur, wenn der Rahmen schon zu sehen ist: beim Zielwechsel zeigt
-- der Client den Rahmen (UnitWatch) erst NACH PLAYER_TARGET_CHANGED. Bis
-- 6.2.0.0 blieb der gerade erschienene Zielrahmen deshalb manchmal leer -
-- ein weisser Balken ohne Namen (im Beta-Test gesehen). Gezeichnet wird
-- jetzt immer, wenn es die Einheit gibt, und beim Erscheinen noch einmal
-- (OnShow, siehe Create).
-- Alle Texte leeren und neu setzen: eine Schrift, die beim ersten SetText
-- noch nicht geladen war, zeichnet sonst nichts, und derselbe Text noch
-- einmal gesetzt aendert nichts.
function UF.RedrawTexts()
    for _, f in pairs(frames) do
        if f.left and f.right and f:IsShown() then
            f.left:SetText("")
            f.right:SetText("")
            f:Refresh()
        end
    end
end

local function RefreshUnit(unit, portrait)
    local f = frames[unit]
    if not f then return end
    if f:IsShown() or K.Bool(_G.UnitExists and _G.UnitExists(unit), false) then
        f:Refresh()
        if portrait then f:UpdatePortrait() end
    end
end

local HEALTH = { UNIT_HEALTH = true, UNIT_MAXHEALTH = true, UNIT_CONNECTION = true }
local POWER = { UNIT_POWER_UPDATE = true, UNIT_POWER_FREQUENT = true, UNIT_MAXPOWER = true, UNIT_DISPLAYPOWER = true }
local PREDICTION = { UNIT_HEAL_PREDICTION = true, UNIT_ABSORB_AMOUNT_CHANGED = true }
local FULL = { UNIT_NAME_UPDATE = true, UNIT_LEVEL = true, UNIT_FACTION = true, UNIT_FLAGS = true }
local CAST = {
    UNIT_SPELLCAST_START = "update", UNIT_SPELLCAST_CHANNEL_START = "update",
    UNIT_SPELLCAST_CHANNEL_UPDATE = "update", UNIT_SPELLCAST_DELAYED = "update",
    UNIT_SPELLCAST_INTERRUPTIBLE = "update", UNIT_SPELLCAST_NOT_INTERRUPTIBLE = "update",
    UNIT_SPELLCAST_STOP = "stop", UNIT_SPELLCAST_CHANNEL_STOP = "stop",
    UNIT_SPELLCAST_INTERRUPTED = "failed", UNIT_SPELLCAST_FAILED = "failed",
}

local function OnEvent(_, event, unit, ...)
    if event == "PLAYER_TARGET_CHANGED" then
        RefreshUnit("target", true)
        RefreshUnit("targettarget", true)
        return
    elseif event == "PLAYER_FOCUS_CHANGED" then
        RefreshUnit("focus", true)
        return
    elseif event == "UNIT_TARGET" then
        if unit == "target" then RefreshUnit("targettarget", true) end
        local f = unit and frames[unit]
        if f and f._cast and f._cast:IsShown() then f._cast:UpdateTarget() end
        return
    elseif event == "UNIT_PET" then
        if unit == "player" then RefreshUnit("pet", true) end
        return
    elseif event == "UNIT_PORTRAIT_UPDATE" or event == "UNIT_MODEL_CHANGED" then
        if unit and frames[unit] then RefreshUnit(unit, true) end
        return
    elseif event == "PLAYER_ENTERING_WORLD" or event == "RAID_TARGET_UPDATE" then
        for u in pairs(frames) do RefreshUnit(u, event == "PLAYER_ENTERING_WORLD") end
        UF.UpdateState()
        if event == "PLAYER_ENTERING_WORLD" and _G.C_Timer and _G.C_Timer.After then
            _G.C_Timer.After(1, UF.RedrawTexts)
            _G.C_Timer.After(4, UF.RedrawTexts)
        end
        return
    elseif event == "UPDATE_SHAPESHIFT_FORM" then
        if frames.target then frames.target:UpdateCombo() end
        return
    elseif event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED"
        or event == "PLAYER_UPDATE_RESTING" then
        UF.UpdateState()
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
    elseif event == "UNIT_COMBAT" then
        f:CombatFeedback(...)
    elseif PREDICTION[event] then
        f:UpdatePrediction()
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

-- Kampf vor Ruhe: wer im Gasthaus kaempft, soll das sehen.
function UF.UpdateState()
    local f = frames.player
    local st = f and f._state
    if not st then return end
    local which
    if Opt("player_stateIcon") then
        if K.Bool(_G.UnitAffectingCombat and _G.UnitAffectingCombat("player"), false) then
            which = "combat"
        elseif K.Bool(_G.IsResting and _G.IsResting(), false) then
            which = "rest"
        end
    end
    st._which = which
    if not which then
        if st.pulse and st.pulse.Stop then st.pulse:Stop() end
        st:Hide()
        return
    end
    local c = WeintCodex.GameColors[which == "combat" and "stateCombat" or "stateRest"]
    if which == "combat" then
        local tex = K.MEDIA .. "icon_combat"
        st.icon:SetTexture(tex)
        st.shade:SetTexture(tex)
        st.icon:SetVertexColor(c[1], c[2], c[3], 1)
        st.icon:Show()
        st.shade:Show()
        st.text:Hide()
    else
        st.icon:Hide()
        st.shade:Hide()
        st.text:SetTextColor(c[1], c[2], c[3], 1)
        st.text:Show()
    end
    st:Show()
    if st.pulse then
        if which == "combat" then
            if st.pulse.Play then st.pulse:Play() end
        elseif st.pulse.Stop then
            st.pulse:Stop()
        end
    end
end
UF.StateIcon = function() return frames.player and frames.player._state end

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
            local keepGame = (u == "target") and SetupGameAuras()
            for _, b in ipairs(BLIZZARD[u] or {}) do
                if not (keepGame and b == "TargetFrame") then HideBlizzard(b) end
            end
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
        "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "PLAYER_UPDATE_RESTING", "UNIT_COMBAT",
    }) do Register(e) end
    for e in pairs(HEALTH) do Register(e) end
    for e in pairs(PREDICTION) do Register(e) end
    for e in pairs(POWER) do Register(e) end
    for e in pairs(FULL) do Register(e) end
    for e in pairs(CAST) do Register(e) end
    events:SetScript("OnEvent", K.Measured("Einheitenrahmen", OnEvent))
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
                B:Row({ type = "toggle", label = "Symbol für Kampf und Ruhe", key = "player_stateIcon", disabled = off,
                        description = "Gekreuzte Schwerter im Kampf, „zZ“ beim Ausruhen (Gasthaus, Stadt)." },
                      { type = "empty" })
                B:Row({ type = "toggle", label = "Mittig über den Leisten", key = "playerCastCentered",
                        disabled = function() return off() or not K.Get(KEY, "player_cast") end,
                        description = "Aus: direkt unter dem Spielerrahmen." },
                      { type = "empty" })
            end
        end
        if u == "target" then
            B:Section("Auren und Kombopunkte")
            local noAuras = function() return off() or not K.Get(KEY, "targetAuras") end
            local notOwn = function() return noAuras() or K.Get(KEY, "targetAuraSource") ~= "own" end
            local notGame = function() return noAuras() or K.Get(KEY, "targetAuraSource") ~= "game" end
            B:Row({ type = "toggle", label = "Buffs und Debuffs", key = "targetAuras", disabled = off },
                  { type = "dropdown", label = "Symbole", key = "targetAuraSource", reload = true, disabled = noAuras,
                    items = {
                        { value = "game", text = "Des Spiels (auch im Kampf)" },
                        { value = "own",  text = "Eigene (im Kampf leer)" } },
                    description = "Im Kampf gibt der Client Auren nur an seine eigenen Symbole heraus – wie auf den Plaketten." })
            B:Row({ type = "slider", label = "Größe (Spiel)", key = "targetGameScale", min = 60, max = 200, step = 5,
                    format = function(v) return string.format("%d %%", v) end, disabled = notGame },
                  { type = "slider", label = "Symbolgröße (eigene)", key = "auraSize", min = 14, max = 36, step = 1, format = px,
                    disabled = notOwn })
            B:Row({ type = "dropdown", label = "Ausrichtung", key = "targetAuraAlign", disabled = noAuras, items = {
                        { value = "left",  text = "Linksbündig" },
                        { value = "right", text = "Rechtsbündig" } } },
                  { type = "slider", label = "Abstand zum Rahmen", key = "targetAuraGap", min = 0, max = 30, step = 1,
                    format = px, disabled = noAuras })
            B:Row({ type = "toggle", label = "Nur eigene Debuffs", key = "onlyOwnDebuffs",
                    disabled = notOwn },
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
        B:Row({ type = "toggle", label = "Grund in der Balkenfarbe", key = "tintedBg",
                description = "Fehlendes Leben dunkel in der Farbe des Balkens statt im Hintergrund." },
              { type = "toggle", label = "Maus hebt hervor", key = "hover" })
        B:Row({ type = "toggle", label = "Eingehende Heilung", key = "healPrediction",
                description = "Ein heller grüner Balken hinter dem Leben: so weit reichen Heilungen, die gerade gewirkt werden." },
              { type = "toggle", label = "Schilde", key = "absorbs",
                description = "Eine blaue Fläche vom rechten Rand über dem Leben: wie viel Schaden Schilde noch abfangen." })
        B:Row({ type = "toggle", label = "Treffer und Heilung als Zahl", key = "combatFeedback",
                description = "Spieler und Ziel: erlittener Schaden rot mit Minus, erhaltene Heilung grün mit Plus – kurz im Rahmen." })
        B:Section("Schrift")
        B:Row({ type = "slider", label = "Größe links", key = "nameSize", min = 8, max = 20, step = 1, format = px },
              { type = "slider", label = "Größe rechts", key = "textSize", min = 8, max = 20, step = 1, format = px })
        B:Section("Zauberbalken")
        B:Row({ type = "slider", label = "Höhe (Ziel, Fokus)", key = "castHeight", min = 8, max = 30, step = 1, format = px },
              { type = "toggle", label = "Zaubersymbol", key = "castIcon" })
        B:Row({ type = "slider", label = "Höhe (eigener, mittig)", key = "playerCastHeight", min = 10, max = 36, step = 1, format = px },
              { type = "slider", label = "Breite (eigener, mittig)", key = "playerCastWidth", min = 120, max = 400, step = 4, format = px })
        B:Row({ type = "toggle", label = "Latenz am eigenen Zauber", key = "playerCastLatency",
                description = "Rot am Ende: ab da darfst du den nächsten Zauber schon drücken." },
              { type = "empty" })
        B:Row({ type = "toggle", label = "Restzeit", key = "castTimer" },
              { type = "toggle", label = "Ziel des Zaubers (Ziel, Fokus)", key = "castTarget",
                description = "Auf wen der Gegner zaubert – „Dich“ in Rot." })
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
