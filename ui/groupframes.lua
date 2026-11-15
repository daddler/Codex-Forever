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
    -- Welche Rahmen (6.6.0.9, Beta-Test: "Schilde, Buffs, HoTs werden nicht
    -- angezeigt"): "game" = die des Spiels im WeintCodex-Stil
    -- (ui/gamegroup.lua) - nur sie zeigen Auren im Kampf; "own" = die
    -- eigenen Kacheln dieses Moduls, ohne Auren im Kampf.
    -- 1.0.6.20 ("Gruppenrahmen wie VuhDo/VoidBox"): ab Werk die eigenen.
    -- Die Rahmen des Spiels liessen sich nicht zuverlaessig fuer Klickzauber
    -- nutzen (Seitentasten kamen nie an, Blizzard setzt Klicks zurueck);
    -- HoTs zeigen die eigenen jetzt ueber die Container des Spiels mit
    -- Zauberfilter (VoidBox-Technik) - auch im Kampf.
    source = "own",
    partyEnabled = true,
    partyWidth = 120, partyHeight = 40, partySpacing = 4,
    partyShowPlayer = true,
    partyHorizontal = false,
    raidEnabled = true,
    raidHorizontal = false,     -- 6.27.2.0: Gruppen des Schlachtzugs als Zeilen statt Spalten
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
    -- 6.61.14.0 (Beta-Test: "die Buffs im Gruppenfenster muessten angezeigt
    -- werden - SdK, Int etc."): Buffs unten links, Debuffs unten rechts.
    buffs       = true,
    buffSize    = 14,
    buffMax     = 4,
    onlyDispellable = true,
    -- Seit 6.3.2.4 (Beta-Test: "muss etwas detaillierter werden"):
    healPrediction = true,   -- eingehende Heilung als heller Balken hinter dem Leben
    absorbs     = true,      -- Schilde als weisser Balken dahinter
    roleIcon    = true,      -- Tank / Heiler / Schaden oben links
    leaderIcon  = true,      -- Krone beim Gruppenleiter
    readyCheck  = true,      -- Haken / Kreuz / ? beim Bereitschaftscheck
    hitFlash    = true,      -- kurzes rotes Aufblitzen bei einem Treffer
    -- 1.0.6.20: HoT-Felder (je ein Zauber, alle Raenge), Bannring,
    -- Sortierung, Tankrahmen.
    -- 1.0.6.21 ("muss schoener"): Aussehen. "dark" = dunkler Balken, das
    -- fehlende Leben in Klassenfarbe, Name in Klassenfarbe (wie VuhDo/Cell);
    -- "class" = Balken in Klassenfarbe, Name weiss.
    -- 1.0.6.22 ("mehr dreidimensional, mehr Pepp"): "relief" = Balken in
    -- Klassenfarbe mit Verlauf, Glanz oben, Schatten unten, Kanten.
    look        = "relief",
    targetRing  = true,
    hots        = true,
    hotSize     = 14,
    hotTimer    = true,
    hot1 = -1, hot2 = -1, hot3 = 0, hot4 = 0,   -- -1 = Vorschlag der Klasse, 0 = leer
    hot1Pos = "RIGHT", hot2Pos = "LEFT", hot3Pos = "CENTER", hot4Pos = "TOPRIGHT",
    dispelRing  = true,
    partySort   = "group",   -- group | role | class | name
    raidSort    = "group",
    tankEnabled = false,
    tankWidth = 120, tankHeight = 40, tankSpacing = 4,
}

--------------------------------------------------
-- HoT-Felder (1.0.6.20)
--------------------------------------------------
-- Je Feld ein Zauber des Spielers; das Spiel zeigt ihn, solange er auf dem
-- Mitspieler liegt - auch im Kampf, weil Lua nichts liest (Filter
-- "HELPFUL|PLAYER" plus Zauberliste, siehe ui/auras.lua). Alle Raenge eines
-- Zaubers zaehlen (Rangketten aus data/trainer.lua). Vorschlaege je Klasse:
-- Zaubernummern aus Classic (Art classic); der Name kommt vom Client.
GF.CLASS_HOTS = {
    PRIEST  = { 139, 17, 6346, 1243, 14752 },
    DRUID   = { 774, 8936, 1126, 467, 29166 },
    PALADIN = { 1022, 6940, 1044, 19740, 19742, 20217 },
    MAGE    = { 1459, 1008, 604, 130 },
    SHAMAN  = { 546, 131 },
    WARLOCK = { 5697, 132 },
}
GF.HOT_POSITIONS = { "TOPLEFT", "TOP", "TOPRIGHT", "LEFT", "CENTER", "RIGHT", "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT" }
GF.HOT_POS_TEXT = { TOPLEFT = "Oben links", TOP = "Oben Mitte", TOPRIGHT = "Oben rechts", LEFT = "Links",
    CENTER = "Mitte", RIGHT = "Rechts", BOTTOMLEFT = "Unten links", BOTTOM = "Unten Mitte", BOTTOMRIGHT = "Unten rechts" }

local function PlayerClass()
    if not _G.UnitClass then return nil end
    local _, c = _G.UnitClass("player")
    c = K.Plain(c)
    return type(c) == "string" and c or nil
end

-- Zauber eines Feldes: Nummer oder nil. -1 = Vorschlag der Klasse.
function GF.HotSpell(i)
    local v = tonumber(K.Get(KEY, "hot" .. i)) or 0
    if v == -1 then
        local list = GF.CLASS_HOTS[PlayerClass() or ""] or {}
        return list[i]
    end
    return v > 0 and v or nil
end

-- Alle Raenge als Menge {[id] = true}; gleiche Tabelle fuer gleiche
-- Nummer (der Baustein baut nur bei neuer Tabelle neu).
local rankSets = {}
function GF.RankSet(id)
    if type(id) ~= "number" then return nil end
    if rankSets[id] then return rankSets[id] end
    local set = { [id] = true }
    local T = WeintCodex.TrainerData
    local class = PlayerClass()
    if T and T.RankChain and class then
        local chain = T.RankChain(class, id)
        for _, x in ipairs(chain or {}) do set[x] = true end
    end
    -- Hoehere Raenge setzen beim Lehrer den vorigen voraus (Erneuerung
    -- 139 -> 6074 -> 6075 ...). Gefolgt wird nur, wo der Name passt - sofern
    -- der Client ihn nennt; ohne Namen jeder Zauber mit genau dieser einen
    -- Voraussetzung.
    if T and T.Spells and class then
        local base = GF.SpellName(id)
        local list = T.Spells(class)
        local grew = true
        while grew do
            grew = false
            for _, sp in ipairs(list) do
                local req = sp.requiredIds
                if not set[sp.id] and type(req) == "table" and #req == 1 and set[req[1]] then
                    local n = GF.SpellName(sp.id)
                    if (base == nil and n == nil) or (base ~= nil and n == base) then
                        set[sp.id] = true
                        grew = true
                    end
                end
            end
        end
    end
    rankSets[id] = set
    return set
end

function GF.SpellName(id)
    local cs = _G.C_Spell
    if type(id) ~= "number" then return nil end
    if cs and cs.GetSpellName then
        local ok, n = pcall(cs.GetSpellName, id)
        n = ok and K.Plain(n) or nil
        if type(n) == "string" and n ~= "" then return n end
    elseif _G.GetSpellInfo then
        local ok, n = pcall(_G.GetSpellInfo, id)
        n = ok and K.Plain(n) or nil
        if type(n) == "string" and n ~= "" then return n end
    end
    return nil
end

-- Auswahl fuer ein Feld: leer, Vorschlag, die Zauber der Klasse.
function GF.HotItems(i)
    local items = { { value = 0, text = "Leer" } }
    local list = GF.CLASS_HOTS[PlayerClass() or ""] or {}
    if list[i] then
        items[#items + 1] = { value = -1, text = "Vorschlag: " .. (GF.SpellName(list[i]) or ("Zauber " .. list[i])) }
    end
    for _, id in ipairs(list) do
        items[#items + 1] = { value = id, text = GF.SpellName(id) or ("Zauber " .. id) }
    end
    return items
end

function GF.PosItems()
    local items = {}
    for _, p in ipairs(GF.HOT_POSITIONS) do items[#items + 1] = { value = p, text = GF.HOT_POS_TEXT[p] } end
    return items
end

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

-- Farben eines Knopfs nach dem Aussehen. gone: tot oder offline.
local function Grad(tex, r1, g1, b1, a1, r2, g2, b2, a2)
    -- Unten nach oben. Ohne Verlauf im Client: die obere Farbe flach.
    if tex.SetGradient and _G.CreateColor then
        tex:SetColorTexture(1, 1, 1, 1)
        tex:SetGradient("VERTICAL", _G.CreateColor(r1, g1, b1, a1), _G.CreateColor(r2, g2, b2, a2))
    else
        tex:SetColorTexture(r2, g2, b2, a2)
    end
end
GF._Grad = Grad

-- Farben eines Knopfs nach dem Aussehen. gone: tot oder offline.
function GF.Paint(c, r, g, b, gone)
    local G = WeintCodex.GameColors
    local look = Opt("look")
    if c.name.SetShadowColor then c.name:SetShadowColor(0, 0, 0, 0.9) c.status:SetShadowColor(0, 0, 0, 0.9) end
    if c.relief then c.relief:SetShown(look ~= "dark" or gone) end
    if gone then
        K.PaintBar(c.health, G.gfGone[1], G.gfGone[2], G.gfGone[3])
        c.bg:SetColorTexture(G.gfGone[1], G.gfGone[2], G.gfGone[3], 1)
        c.name:SetTextColor(G.gfGoneText[1], G.gfGoneText[2], G.gfGoneText[3])
        c.status:SetTextColor(G.gfGoneText[1], G.gfGoneText[2], G.gfGoneText[3])
        return
    end
    if look == "relief" then
        -- Der Balken selbst traegt den Verlauf; PaintBar darf danach nicht
        -- glauben, seine Farbe stehe noch.
        local tex = c.health:GetStatusBarTexture()
        local lo, hi = G.gfReliefLow[1], G.gfReliefHigh[1]
        if tex and c._wcRel ~= r + g * 7 + b * 49 then
            c._wcRel = r + g * 7 + b * 49
            c.health._wcR = nil
            if tex.SetGradient and _G.CreateColor then
                tex:SetVertexColor(1, 1, 1, 1)
                tex:SetGradient("VERTICAL", _G.CreateColor(r * lo, g * lo, b * lo, 1),
                    _G.CreateColor(r * hi, g * hi, b * hi, 1))
            else
                tex:SetVertexColor(r * hi, g * hi, b * hi, 1)
            end
        end
        local d = G.gfReliefBack
        Grad(c.bg, d[1], d[2], d[3], 1, d[1] * 1.8, d[2] * 1.8, d[3] * 1.8, 1)
        c.name:SetTextColor(1, 1, 1)
        c.status:SetTextColor(0.95, 0.95, 0.95)
        return
    end
    c._wcRel = nil
    if look == "class" then
        K.PaintBar(c.health, r * 0.85, g * 0.85, b * 0.85)
        local bg = K.GetColor(KEY, "bgColor")
        c.bg:SetColorTexture(bg.r, bg.g, bg.b, 1)
        c.name:SetTextColor(1, 1, 1)
        c.status:SetTextColor(0.92, 0.92, 0.92)
    else
        local f, m = G.gfDarkFill, G.gfMissing[1]
        K.PaintBar(c.health, f[1], f[2], f[3])
        c.bg:SetColorTexture(r * m, g * m, b * m, 1)
        c.name:SetTextColor(r, g, b)
        c.status:SetTextColor(0.78, 0.78, 0.80)
    end
end

-- Plastik: Glanz in der oberen Haelfte, Schatten unten, helle Oberkante,
-- dunkle Unterkante. Liegt ueber dem Leben, unter Text und Symbolen.
local function Relief(c, host)
    local G = WeintCodex.GameColors
    local f = CreateFrame("Frame", nil, c)
    f:SetAllPoints(c)
    f:SetFrameLevel((host:GetFrameLevel() or 2) - 1)
    local gl, sh, hi, lo = G.gfGloss, G.gfShade, G.gfBevelHi, G.gfBevelLo
    local gloss = f:CreateTexture(nil, "ARTWORK")
    gloss:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
    gloss:SetPoint("BOTTOMRIGHT", f, "RIGHT", -1, 0)
    Grad(gloss, gl[1], gl[2], gl[3], 0.02, gl[1], gl[2], gl[3], gl[4])
    local shade = f:CreateTexture(nil, "ARTWORK")
    shade:SetPoint("TOPLEFT", f, "LEFT", 1, -2)
    shade:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, 1)
    Grad(shade, sh[1], sh[2], sh[3], sh[4], sh[1], sh[2], sh[3], 0)
    local top = f:CreateTexture(nil, "OVERLAY")
    top:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
    top:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -1)
    top:SetHeight(1)
    top:SetColorTexture(hi[1], hi[2], hi[3], hi[4])
    local bot = f:CreateTexture(nil, "OVERLAY")
    bot:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 1, 1)
    bot:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, 1)
    bot:SetHeight(1)
    bot:SetColorTexture(lo[1], lo[2], lo[3], lo[4])
    return f
end

local function StatusText(fs, unit)
    if _G.UnitIsConnected and not K.Bool(_G.UnitIsConnected(unit), true) then
        fs:SetText("Offline") return
    end
    -- Was gleich passiert, vor dem Zustand: "Tot" allein verschweigt,
    -- dass schon jemand wiederbelebt.
    if K.Bool(_G.UnitHasIncomingResurrection and _G.UnitHasIncomingResurrection(unit), false) then
        fs:SetText("Belebt …") return
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

    c.border:SetShown(Opt("showBorder"))
    local bc = K.GetColor(KEY, "borderColor")
    c.border:SetColor(bc.r, bc.g, bc.b, 1)

    K.SetFont(c.name, Opt("nameSize"))
    K.SetFont(c.status, math.max(8, Opt("nameSize") - 2))
    -- Name oben links (hinter Rolle/Krone), Leben oben rechts, eine Zeile.
    self._wcSW = math.max(26, math.floor(w * 0.3))
    c.status:SetWidth(self._wcSW)
    self._wcW = w
    self:PlaceName()

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
    -- HoT-Felder: angelegt beim ersten Bedarf, je Feld ein Container.
    c.wcHots = _G.rawget(c, "wcHots") or {}
    local hs = Opt("hotSize") or 14
    for i = 1, 4 do
        local id = Opt("hots") and GF.HotSpell(i) or nil
        local o = c.wcHots[i]
        if id then
            local opts = { filter = "HELPFUL|PLAYER", max = 1, size = hs, spacing = 0, anchor = "TOPLEFT",
                growth = "RIGHT", growthV = "DOWN", perRow = 1, spells = GF.RankSet(id), timer = Opt("hotTimer") }
            if not o then
                o = WeintCodex.UIAuras.Create(c.hotHost, opts)
                c.wcHots[i] = o
                o:SetUnit(self._wcUnit)
            else
                o:ApplyLayout(opts)
            end
            local pos = Opt("hot" .. i .. "Pos") or "CENTER"
            local inset = pos:find("LEFT") and 2 or (pos:find("RIGHT") and -2 or 0)
            local dy = pos:find("TOP") and -2 or (pos:find("BOTTOM") and (ph + 3) or 0)
            o:ClearAllPoints()
            o:SetPoint(pos, c, pos, inset, dy)
            o:SetShown(true)
        elseif o then
            o:SetShown(false)
        end
    end
    if _G.rawget(c, "ring") then c.ring:SetShown(Opt("dispelRing") and true or false) end

    if c.buffs then
        c.buffs:ApplyLayout({ filter = "HELPFUL", max = Opt("buffMax"), size = Opt("buffSize"), spacing = 1,
            anchor = "BOTTOMLEFT", growth = "RIGHT", growthV = "UP", perRow = Opt("buffMax") })
        c.buffs:ClearAllPoints()
        c.buffs:SetPoint("BOTTOMLEFT", c, "BOTTOMLEFT", 2, ph + 3)
        c.buffs:SetShown(Opt("buffs"))
    end
end

function Btn:Refresh()
    local unit = self._wcUnit
    local c = self._wc
    if not unit or not K.Bool(_G.UnitExists and _G.UnitExists(unit), false) then return end

    local GZ = WeintCodex.UIGlanz
    local snap = GZ.Changed(c.health, unit)
    local max = _G.UnitHealthMax and _G.UnitHealthMax(unit)
    if type(max) ~= "nil" then GZ.Range(c.health, 0, max) end
    local cur = _G.UnitHealth and _G.UnitHealth(unit)
    if type(cur) ~= "nil" then GZ.Set(c.health, cur, snap) end
    local gone = not K.Bool(_G.UnitIsConnected and _G.UnitIsConnected(unit), true)
        or K.Bool(_G.UnitIsDeadOrGhost and _G.UnitIsDeadOrGhost(unit), false)
    local hr, hg, hb = HealthColor(unit)
    GF.Paint(c, hr, hg, hb, gone)

    if Opt("power") then
        local pmax = _G.UnitPowerMax and _G.UnitPowerMax(unit)
        if type(pmax) ~= "nil" then c.power:SetMinMaxValues(0, pmax) end
        local p = _G.UnitPower and _G.UnitPower(unit)
        if type(p) ~= "nil" then GZ.Set(c.power, p, snap) end
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

    K.ShowRaidIcon(c.raid, unit)
    self:UpdateThreat()
    self:UpdateTarget()
end

-- Name hinter Rolle und Krone; Breite bis vor das Leben.
function Btn:PlaceName()
    local c = self._wc
    local x = 4
    if c.role:IsShown() then x = x + 16 end
    if c.leader:IsShown() then x = x + 16 end
    c.name:ClearAllPoints()
    c.name:SetPoint("TOPLEFT", c, "TOPLEFT", x, -4)
    c.name:SetWidth(math.max(16, (self._wcW or 100) - x - (self._wcSW or 30) - 6))
end

-- Dein Ziel: feiner heller Rand.
function Btn:UpdateTarget()
    local c, unit = self._wc, self._wcUnit
    local on = unit and Opt("targetRing") and K.Bool(_G.UnitIsUnit and _G.UnitIsUnit(unit, "target"), false)
    c.targetRing:SetShown(on and true or false)
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
        c.leader:SetPoint("TOPLEFT", c, "TOPLEFT", 3, -3)
    end
    c.leader:SetShown(lead and true or false)
    self:PlaceName()
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

-- Eine kleine Plakette: dunkler Grund, 1 px Rand, Symbol darauf. Kennt
-- SetTexture/SetVertexColor wie eine Textur, damit der Rest sie so
-- behandeln kann.
-- 1.0.6.21: ohne Plakette - auf dem dunklen Balken stehen die Symbole
-- frei; nur ein Schatten dahinter.
local BADGE, BADGE_ICON = 15, 14
local function Badge(parent)
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(BADGE, BADGE)
    f:SetFrameLevel((parent:GetFrameLevel() or 1) + 1)
    -- 1.0.6.23 ("Rollen schwer zu erkennen"): dasselbe Symbol schwarz und
    -- etwas groesser dahinter - ein Umriss, keine Plakette.
    local sh = f:CreateTexture(nil, "BACKGROUND")
    sh:SetPoint("CENTER", f, "CENTER", 0, 0)
    sh:SetSize(BADGE_ICON + 3, BADGE_ICON + 3)
    sh:SetVertexColor(0, 0, 0, 0.95)
    f.outline = sh
    f.icon = f:CreateTexture(nil, "ARTWORK")
    f.icon:SetSize(BADGE_ICON, BADGE_ICON)
    f.icon:SetPoint("CENTER", f, "CENTER", 0, 0)
    function f:SetTexture(t) self.icon:SetTexture(t) self.outline:SetTexture(t) self.outline:SetVertexColor(0, 0, 0, 0.95) end
    function f:SetVertexColor(r, g, b, a) self.icon:SetVertexColor(r, g, b, a) end
    f:Hide()
    return f
end
GF._Badge = Badge

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
    -- Glanz (6.43.0.0): vor der Klammer ueber dem Leben.
    WeintCodex.UIGlanz.Bar(c.health, "group", "health")
    WeintCodex.UIGlanz.Bar(c.power, "group")
    c.border = K.Border(c, 1, 0, 0, 0, 1, "BORDER")
    c.shadow = K.Glow(c, { spread = 4, shadow = true })
    local danger = WeintCodex.Colors.danger
    c.aggro = K.Border(c, 2, danger[1], danger[2], danger[3], 1, "OVERLAY")
    c.aggro:SetShown(false)

    local host = CreateFrame("Frame", nil, c)
    host:SetAllPoints(c)
    host:SetFrameLevel((c.health:GetFrameLevel() or 1) + 3)
    c.name = K.NewText(host)
    c.name:SetPoint("TOPLEFT", c, "TOPLEFT", 4, -4)
    c.name:SetJustifyH("LEFT")
    c.name:SetWordWrap(false)
    c.status = K.NewText(host)
    c.status:SetPoint("TOPRIGHT", c, "TOPRIGHT", -4, -5)
    c.status:SetJustifyH("RIGHT")
    c.status:SetWordWrap(false)
    for _, fs in ipairs({ c.name, c.status }) do
        if fs.SetShadowOffset then fs:SetShadowOffset(1, -1) fs:SetShadowColor(0, 0, 0, 0.9) end
    end
    local tc = WeintCodex.Colors.textBright
    c.targetRing = K.Border(host, 1, tc[1], tc[2], tc[3], 0.9, "OVERLAY")
    c.targetRing:SetShown(false)
    local hv = WeintCodex.GameColors.gfHover
    c.relief = Relief(c, host)
    c.hover = host:CreateTexture(nil, "OVERLAY", nil, -2)
    c.hover:SetAllPoints(c)
    c.hover:SetColorTexture(hv[1], hv[2], hv[3], hv[4])
    c.hover:Hide()
    -- Schrift sofort: der Kopfrahmen setzt die Einheit (und damit den
    -- ersten Text) womoeglich, bevor Layout gelaufen ist - und Text ohne
    -- Schrift ist im Client ein Fehler.
    K.SetFont(c.name, Opt("nameSize"))
    K.SetFont(c.status, math.max(8, Opt("nameSize") - 1))
    c.raid = K.NewRaidIcon(host, 14)
    -- Oben rechts: oben links stehen Rolle und Krone.
    c.raid:SetPoint("CENTER", c, "CENTER", 0, 0)

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

    -- Rolle und Krone auf einer kleinen dunklen Plakette: direkt auf der
    -- Klassenfarbe gingen sie unter (Beta-Test 6.3.2.4: "sehr
    -- undurchsichtig, schwer zu erkennen").
    c.role = Badge(host)
    c.role:SetPoint("TOPLEFT", c, "TOPLEFT", 3, -3)
    c.leader = Badge(host)
    c.leader:SetTexture(K.MEDIA .. "icon_leader")
    local lc = WeintCodex.GameColors.leader
    c.leader:SetVertexColor(lc[1], lc[2], lc[3], 1)
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
    local fc = WeintCodex.GameColors.groupHitFlash
    c.flash:SetColorTexture(fc[1], fc[2], fc[3], fc[4])
    c.flash:SetShown(false)
    -- HoT-Felder ueber allem anderen im Knopf (Layout legt sie an).
    c.hotHost = CreateFrame("Frame", nil, c)
    c.hotHost:SetAllPoints(c)
    c.hotHost:SetFrameLevel((host:GetFrameLevel() or 1) + 2)
    if not b._wcTest then c.ring = WeintCodex.UIAuras.DispelRing(c) end
    c.debuffs = WeintCodex.UIAuras.Create(host, { filter = "HARMFUL|RAID", max = 3, size = 16,
        spacing = 1, anchor = "BOTTOMRIGHT", growth = "LEFT", growthV = "UP", perRow = 3 })
    c.buffs = WeintCodex.UIAuras.Create(host, { filter = "HELPFUL", max = 4, size = 14,
        spacing = 1, anchor = "BOTTOMLEFT", growth = "RIGHT", growthV = "UP", perRow = 4 })

    for k, v in pairs(Btn) do b[k] = v end

    -- Welche Einheit der Knopf zeigt, setzt der Kopfrahmen ueber das
    -- Attribut "unit" - auch im Kampf.
    b:HookScript("OnAttributeChanged", function(self, name, value)
        if name ~= "unit" then return end
        self._wcUnit = value
        Remap()
        self._wc.debuffs:SetUnit(value)
        if self._wc.buffs then self._wc.buffs:SetUnit(value) end
        for _, o in pairs(_G.rawget(self._wc, "wcHots") or {}) do o:SetUnit(value) end
        if _G.rawget(self._wc, "ring") then pcall(self._wc.ring.SetUnit, self._wc.ring, value or "none") end
        self:Refresh()
    end)
    b:HookScript("OnShow", function(self) self:Refresh() self:UpdateRange() end)

    if b.RegisterForClicks then b:RegisterForClicks("AnyUp") end
    -- 1.0.0.9: Klickzauber (Entfluchen) auch mit "Aktion beim Druecken".
    b:SetAttribute("useOnKeyDown", false)
    b:SetAttribute("*type1", "target")
    b:SetAttribute("*type2", "togglemenu")
    b:SetScript("OnEnter", function(self)
        self._wc.hover:Show()
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
        self._wc.hover:Hide()
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
-- Sortierung (1.0.6.20). Nur Attribute des Kopfrahmens - kein Schnipsel.
GF.SORT_TEXT = { group = "Nach Gruppe", role = "Nach Rolle (Tank, Heiler, Schaden)", class = "Nach Klasse", name = "Nach Name" }
GF.CLASS_ORDER = "WARRIOR,PALADIN,PRIEST,DRUID,SHAMAN,MAGE,WARLOCK,HUNTER,ROGUE"
function GF.SortAttributes(kind, h)
    if kind == "tank" then
        h:SetAttribute("groupBy", nil)
        h:SetAttribute("sortMethod", "NAME")
        return
    end
    local mode = Opt(kind .. "Sort") or "group"
    if mode == "role" then
        h:SetAttribute("groupBy", "ASSIGNEDROLE")
        h:SetAttribute("groupingOrder", "TANK,HEALER,DAMAGER,NONE")
        h:SetAttribute("sortMethod", "NAME")
    elseif mode == "class" then
        h:SetAttribute("groupBy", "CLASS")
        h:SetAttribute("groupingOrder", GF.CLASS_ORDER)
        h:SetAttribute("sortMethod", "NAME")
    elseif mode == "name" then
        h:SetAttribute("groupBy", nil)
        h:SetAttribute("sortMethod", "NAME")
    elseif kind == "raid" then
        h:SetAttribute("groupBy", "GROUP")
        h:SetAttribute("groupingOrder", "1,2,3,4,5,6,7,8")
        h:SetAttribute("sortMethod", "INDEX")
    else
        h:SetAttribute("groupBy", nil)
        h:SetAttribute("sortMethod", "INDEX")
    end
end

local function LayoutAttributes(kind, h)
    GF.SortAttributes(kind, h)
    local sp = Opt(kind .. "Spacing")
    if kind == "tank" then
        h:SetAttribute("point", "TOP")
        h:SetAttribute("xOffset", 0)
        h:SetAttribute("yOffset", -sp)
        return
    end
    if kind == "raid" then
        -- Untereinander (ab Werk): je Gruppe eine Spalte. Nebeneinander:
        -- je Gruppe eine Zeile (6.27.2.0).
        local horiz = Opt("raidHorizontal")
        h:SetAttribute("point", horiz and "LEFT" or "TOP")
        h:SetAttribute("xOffset", horiz and sp or 0)
        h:SetAttribute("yOffset", horiz and 0 or -sp)
        h:SetAttribute("columnSpacing", sp)
        h:SetAttribute("columnAnchorPoint", horiz and "TOP" or "LEFT")
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
    if kind == "tank" then
        hd.anchor:SetSize(w, 5 * ht + 4 * sp)
    elseif kind == "raid" and Opt("raidHorizontal") then
        hd.anchor:SetSize(5 * w + 4 * sp, 8 * ht + 7 * sp)
    elseif kind == "raid" then
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
    local isTank = (kind == "tank")
    local name = isTank and "WeintCodexTankHeader" or (isRaid and "WeintCodexRaidHeader" or "WeintCodexPartyHeader")
    local h = CreateFrame("Frame", name, UIParent, "SecureGroupHeaderTemplate")
    h:SetAttribute("template", "SecureUnitButtonTemplate")
    h:SetAttribute("templateType", "Button")
    h:SetAttribute("sortMethod", "INDEX")
    local max
    if isTank then
        -- Alle mit der Rolle Tank, in Gruppe und Schlachtzug.
        h:SetAttribute("showRaid", true)
        h:SetAttribute("showParty", true)
        h:SetAttribute("showPlayer", true)
        h:SetAttribute("roleFilter", "TANK")
        max = 5
    elseif isRaid then
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
    local mkey = "gf_" .. kind
    K.RegisterMover(anchor, mkey, isTank and "Tanks" or (isRaid and "Schlachtzug" or "Gruppe"),
        K.Layout(mkey), { secure = true })

    Configure(kind)

    if _G.RegisterStateDriver then
        _G.RegisterStateDriver(h, "visibility", isTank and "[group] show; hide"
            or (isRaid and "[group:raid] show; hide" or "[group:party,nogroup:raid] show; hide"))
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

-- n (1.0.6.20, /wcui gruppentest 5|10|20|40): so viele Beispielspieler,
-- ab sechs im Schlachtzugsrahmen (je fuenf eine Gruppe).
GF.testCount = 5
function GF.ShowTest(on, n)
    if n then GF.testCount = math.max(1, math.min(40, math.floor(n))) end
    for _, b in pairs(testButtons) do b:Hide() end
    n = GF.testCount
    local kind = (n > 5 and headers.raid) and "raid" or "party"
    local hd = headers[kind]
    if not on or not hd or (hd.header.IsVisible and hd.header:IsVisible()) then return end
    local w, ht, sp = Opt(kind .. "Width"), Opt(kind .. "Height"), Opt(kind .. "Spacing")
    local horiz = Opt(kind .. "Horizontal")
    for i = 1, n do
        local t = TEST_PARTY[(i - 1) % #TEST_PARTY + 1]
        local b = TestButton(i)
        local c = b._wc
        b:SetSize(w, ht)
        b:Layout(w, ht)
        b:ClearAllPoints()
        local slot, grp = (i - 1) % 5, math.floor((i - 1) / 5)
        if kind == "party" then slot, grp = i - 1, 0 end
        if horiz then
            b:SetPoint("TOPLEFT", hd.anchor, "TOPLEFT", slot * (w + sp), -grp * (ht + sp))
        else
            b:SetPoint("TOPLEFT", hd.anchor, "TOPLEFT", grp * (w + sp), -slot * (ht + sp))
        end
        c.health:SetMinMaxValues(0, 1)
        c.health:SetValue(t.dead and 0 or t.hp)
        local cc = _G.RAID_CLASS_COLORS and _G.RAID_CLASS_COLORS[t.class]
        if Opt("classColor") and cc then
            GF.Paint(c, cc.r, cc.g, cc.b, t.dead)
        else
            local hc = K.GetColor(KEY, "healthColor")
            GF.Paint(c, hc.r, hc.g, hc.b, t.dead)
        end
        c.power:SetMinMaxValues(0, 1)
        c.power:SetValue(t.power or 0)
        local pc = t.ptoken and _G.PowerBarColor and _G.PowerBarColor[t.ptoken]
        if type(pc) == "table" and pc.r then K.PaintBar(c.power, pc.r, pc.g, pc.b) end
        c.name:SetText(n > 5 and (t.name .. " " .. i) or t.name)
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
        if r then c.leader:SetPoint("LEFT", c.role, "RIGHT", 1, 0) else c.leader:SetPoint("TOPLEFT", c, "TOPLEFT", 3, -3) end
        c.leader:SetShown((t.leader and Opt("leaderIcon")) and true or false)
        b:PlaceName()
        c.targetRing:SetShown(i == 2 and Opt("targetRing") and true or false)
        if t.res then
            c.status:SetText("Belebt …")
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
-- Klickzauber auf neue Knoepfe (auch die Seitentasten beim Ueberfahren).
function GF.ApplyClicks()
    local CC = WeintCodex.UIClickCast
    if CC and CC.Apply and not K.InCombat() then pcall(CC.Apply) end
end

local function RestyleLater()
    local function run()
        K.AfterCombat(function()
            for kind in pairs(headers) do Configure(kind) end
            Remap()
            GF.ApplyClicks()
        end)
    end
    if _G.C_Timer and _G.C_Timer.After then _G.C_Timer.After(0, run) else run() end
end

local function OnEvent(_, event, unit, ...)
    if event == "PLAYER_TARGET_CHANGED" then
        for _, b in ipairs(allButtons) do if b:IsShown() and b.UpdateTarget then b:UpdateTarget() end end
        return
    end
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
    if Opt("source") == "game" then
        WeintCodex.UIGameGroup.Enable()
        return
    end
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
        if Opt("tankEnabled") then CreateHeader("tank") end
        Remap()
        GF.ApplyClicks()
    end)
    for e in pairs(UNIT_EVENTS) do pcall(events.RegisterEvent, events, e) end
    for e in pairs(PART_EVENTS) do pcall(events.RegisterEvent, events, e) end
    for _, e in ipairs({ "GROUP_ROSTER_UPDATE", "PLAYER_ENTERING_WORLD", "RAID_TARGET_UPDATE",
        "UNIT_THREAT_SITUATION_UPDATE", "READY_CHECK", "READY_CHECK_CONFIRM", "READY_CHECK_FINISHED",
        "PARTY_LEADER_CHANGED", "PLAYER_ROLES_ASSIGNED", "PLAYER_TARGET_CHANGED" }) do pcall(events.RegisterEvent, events, e) end
    events:SetScript("OnEvent", K.Measured("Gruppenrahmen", OnEvent))
    ticker:SetScript("OnUpdate", K.Measured("Gruppenrahmen", OnTick))
end

-- Ausrichtung der Rahmen des Spiels (6.27.2.0): in das eigene Layout
-- "WeintCodex" schreiben; sonst einmal sagen, wo es geht.
function GF.ApplyGameOrientation(key)
    local kind = (key == "partyHorizontal" and "party") or (key == "raidHorizontal" and "raid") or nil
    if not kind or Opt("source") ~= "game" then return nil end
    local ES = WeintCodex.UISetup
    if not (ES and ES.SetGroupHorizontal) then return false end
    local ok, why = ES.SetGroupHorizontal(kind, Opt(key))
    if not ok then
        print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " Ausrichtung nicht übernommen (" .. tostring(why)
            .. "). Im Bearbeitungsmodus des Spiels: Gruppenrahmen → „Horizontale Gruppen“.")
    end
    return ok
end

local function OnSetting(key)
    -- Krone an den Rahmen des Spiels (ui/gamegroup.lua) sofort.
    local GG = WeintCodex.UIGameGroup
    if (key == "leaderIcon" or key == "*") and GG and GG.UpdateLeaders then GG.UpdateLeaders() end
    K.AfterCombat(function()
        for kind in pairs(headers) do Configure(kind) end
        GF.ApplyGameOrientation(key)
        GF.ApplyClicks()
    end)
end

--------------------------------------------------
-- Modul
--------------------------------------------------

local function px(v) return string.format("%d px", v) end

K.Register({
    key = KEY, group = "ui", order = 25,
    title = "Gruppenrahmen",
    description = "Eigene Gruppen- und Schlachtzugsrahmen: HoT-Felder, Bannring, Sortierung, Tanks für sich, Klickzauber auf allen Maustasten.",
    defaults = defaults,
    Enable = Enable,
    OnSetting = OnSetting,
    pages = {
        { key = "allgemein", label = "Allgemein", build = function(B)
            B:Section("Welche Rahmen")
            B:Row({ type = "dropdown", label = "Rahmen", key = "source", reload = true, items = {
                        { value = "own",  text = "Eigene Rahmen (empfohlen)" },
                        { value = "game", text = "Des Spiels im WeintCodex-Stil" } },
                    description = "Eigene Rahmen: HoT-Felder, Bannring, Sortierung, Tankrahmen und Klickzauber auf allen Maustasten. Die Rahmen des Spiels bleiben als Rückweg." },
                  { type = "empty" })
            B:Row({ type = "button", label = "Rahmen des Spiels", text = "Einrichten",
                    tooltip = "Legt das Layout „WeintCodex“ im Bearbeitungsmodus an: schlachtzugsartige Gruppenrahmen, ohne Blizzards Linien, an den WeintCodex-Plätzen. Danach neu laden. Auch mit /wcui einrichten.",
                    onClick = function() WeintCodex.UISetup.Show() end },
                  { type = "button", label = "Lage und Größe", text = "Bearbeitungsmodus des Spiels",
                    tooltip = "Für die Rahmen des Spiels: Platz und Größe stellt sein Bearbeitungsmodus ein. Schließt du ihn, bist du wieder hier. Die eigenen Kacheln verschiebst du im Gestaltungsmodus.",
                    gameEditMode = true })
            B:Note("Die folgenden Einstellungen gelten für die eigenen Kacheln; bei den Rahmen des Spiels wirken Rand, Farben und Schriftgröße.")
            B:Section("Farben und Rahmen")
            B:Row({ type = "dropdown", label = "Aussehen", key = "look", items = {
                        { value = "relief", text = "Plastisch – Klassenfarbe mit Glanz und Tiefe" },
                        { value = "dark",  text = "Dunkel – fehlendes Leben in Klassenfarbe" },
                        { value = "class", text = "Klassenfarbe – Balken farbig" } },
                    description = "Plastisch: gewölbte Balken mit Glanz. Dunkel: wer Leben verliert, leuchtet in seiner Klassenfarbe auf – gut für Heiler. Klassenfarbe: der klassische Balken." },
                  { type = "toggle", label = "Rand um dein Ziel", key = "targetRing" })
            B:Row({ type = "toggle", label = "Klassenfarbe", key = "classColor" },
                  { type = "toggle", label = "Roter Rand bei Aggro", key = "aggroBorder" })
            B:Row({ type = "slider", label = "Deckkraft außer Reichweite", key = "rangeAlpha", min = 10, max = 100, step = 5,
                    format = function(v) return string.format("%d %%", v) end },
                  { type = "dropdown", label = "Unter dem Namen", key = "statusText", items = {
                        { value = "none",    text = "Nichts" },
                        { value = "percent", text = "Leben in %" },
                        { value = "deficit", text = "Fehlendes Leben" } } })
            B:Section("Kraft, Buffs und Debuffs")
            B:Row({ type = "toggle", label = "Kraftleiste", key = "power" },
                  { type = "toggle", label = "Debuffs", key = "debuffs" })
            B:Row({ type = "toggle", label = "Nur bannbare", key = "onlyDispellable",
                    disabled = function() return not K.Get(KEY, "debuffs") end,
                    description = "Was du selbst entfernen kannst." },
                  { type = "toggle", label = "Buffs", key = "buffs",
                    description = "Unten links im Rahmen, z. B. Segen, Intelligenz, Mal der Wildnis." })
            B:Section("Mehr im Rahmen")
            B:Row({ type = "toggle", label = "Eingehende Heilung", key = "healPrediction",
                    description = "Ein heller grüner Balken hinter dem Leben: so weit reichen Heilungen, die gerade gewirkt werden." },
                  { type = "toggle", label = "Schilde", key = "absorbs",
                    description = "Ein weißer Balken dahinter: wie viel Schaden Schilde noch abfangen." })
            B:Note("Wer gerade wiederbelebt oder beschworen wird, steht unter dem Namen („Wird belebt“, „Beschwörung“). Schaden, der erst noch kommt, kennt das Spiel nicht – das Aufblitzen zeigt Treffer in dem Moment, in dem sie landen.")
            -- 6.10.1.0: Farbtoene, Rand, Groessen und Kleinigkeiten zugeklappt.
            B:Advanced()
            B:Section("Mitspieler")
            B:Row({ type = "toggle", label = "Ziel der Mitspieler", key = "groupTargets",
                    description = "Unter dem Namen „» Ziel“ – in deiner Akzentfarbe, wenn es auch dein Ziel ist." },
                  { type = "toggle", label = "Fehlende Buffs deiner Klasse", key = "groupOtherBuffs",
                    description = "Oben rechts, rot: wem dein Gruppenbuff fehlt – Magier Intelligenz, Druide Mal der Wildnis, Priester Seelenstärke, Paladin Segen. Nur, was du gelernt hast; gelesen außerhalb des Kampfes." })
            B:Section("Farben und Rand")
            B:Row({ type = "color", label = "Lebensbalken sonst", key = "healthColor" },
                  { type = "color", label = "Hintergrund", key = "bgColor" })
            B:Row({ type = "toggle", label = "Rand anzeigen", key = "showBorder" },
                  { type = "toggle", label = "Aufblitzen bei Treffern", key = "hitFlash",
                    description = "Der Knopf blitzt kurz rot auf, wenn jemand getroffen wird." })
            B:Section("Größen")
            B:Row({ type = "slider", label = "Schriftgröße", key = "nameSize", min = 8, max = 16, step = 1, format = px },
                  { type = "slider", label = "Höhe der Kraftleiste", key = "powerHeight", min = 1, max = 8, step = 1, format = px,
                    disabled = function() return not K.Get(KEY, "power") end })
            B:Row({ type = "slider", label = "Symbolgröße der Debuffs", key = "debuffSize", min = 10, max = 28, step = 1, format = px,
                    disabled = function() return not K.Get(KEY, "debuffs") end },
                  { type = "slider", label = "Höchstens Debuffs", key = "debuffMax", min = 1, max = 6, step = 1,
                    format = function(v) return tostring(v) end,
                    disabled = function() return not K.Get(KEY, "debuffs") end })
            B:Row({ type = "slider", label = "Symbolgröße der Buffs", key = "buffSize", min = 10, max = 24, step = 1, format = px,
                    disabled = function() return not K.Get(KEY, "buffs") end },
                  { type = "slider", label = "Höchstens Buffs", key = "buffMax", min = 1, max = 8, step = 1,
                    format = function(v) return tostring(v) end,
                    disabled = function() return not K.Get(KEY, "buffs") end })
            B:Row({ type = "toggle", label = "Krone beim Gruppenleiter", key = "leaderIcon" },
                  { type = "toggle", label = "Balken: Leben des Ziels", key = "groupTargetBar",
                    description = "Rechts neben jedem Rahmen ein schmaler Balken: das Leben des Ziels dieses Mitspielers, rot bei Gegnern." })
            -- 1.0.5.13: unter "Erweitert", damit Ziel und Buffs von anderen oben Platz haben.
            B:Row({ type = "toggle", label = "Rollensymbol", key = "roleIcon",
                    description = "Schild, Kreuz oder Schwert oben links – nur, wenn eine Rolle zugewiesen ist." },
                  { type = "toggle", label = "Bereitschaftscheck", key = "readyCheck",
                    description = "Haken, Kreuz oder „?“ in der Mitte; das Ergebnis bleibt ein paar Sekunden stehen." })
        end },
        { key = "hots", label = "HoTs & Bannen", build = function(B)
            local off = function() return not K.Get(KEY, "hots") end
            B:Section("HoT-Felder", "Bis zu vier eigene Zauber je Rahmen, jeder an seinem Platz – das Spiel zeigt sie, solange sie liegen, auch im Kampf. Alle Ränge eines Zaubers zählen. Nur deine eigenen.")
            B:Row({ type = "toggle", label = "HoT-Felder anzeigen", key = "hots" },
                  { type = "toggle", label = "Restzeit als Zahl", key = "hotTimer", disabled = off })
            for i = 1, 4 do
                B:Row({ type = "dropdown", label = "Feld " .. i, key = "hot" .. i, items = GF.HotItems(i), disabled = off },
                      { type = "dropdown", label = "Platz", key = "hot" .. i .. "Pos", items = GF.PosItems(), disabled = off })
            end
            B:Row({ type = "slider", label = "Größe", key = "hotSize", min = 8, max = 28, step = 1, format = px, disabled = off },
                  { type = "empty" })
            B:Section("Bannen")
            B:Row({ type = "toggle", label = "Farbiger Ring bei bannbaren Debuffs", key = "dispelRing", reload = true,
                    description = "Liegt auf jemandem, was du bannen kannst, bekommt sein Rahmen einen Ring in der Farbe der Art: Magie blau, Fluch lila, Krankheit braun, Gift grün. Auch im Kampf." },
                  { type = "empty" })
            B:Note("Vorschläge je Klasse sind Zauber aus Classic; kennt das Spiel einen nicht, steht dort „Zauber“ mit Nummer. Mit Rechtsklick-Zaubern auf die Rahmen: Komfort → Klickzauber.")
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
                  { type = "toggle", label = "Nebeneinander", key = "partyHorizontal", disabled = off,
                    description = "Aus: untereinander (senkrecht). An: nebeneinander (waagerecht). Gilt auch für die Rahmen des Spiels." })
            B:Row({ type = "dropdown", label = "Sortierung", key = "partySort", disabled = off, items = {
                        { value = "group", text = "Wie die Gruppe" }, { value = "role", text = GF.SORT_TEXT.role },
                        { value = "class", text = GF.SORT_TEXT.class }, { value = "name", text = GF.SORT_TEXT.name } } },
                  { type = "button", label = "Vorschau", text = "Beispielgruppe zeigen",
                    tooltip = "Fünf Beispielspieler, solange du allein bist. Wieder weg mit /wcui test.",
                    onClick = function() GF.ShowTest(true, 5) end })
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
                  { type = "toggle", label = "Gruppen nebeneinander", key = "raidHorizontal", disabled = off,
                    description = "Aus: jede Gruppe eine Spalte (senkrecht). An: jede Gruppe eine Zeile (waagerecht). Gilt auch für die Rahmen des Spiels." })
            B:Row({ type = "dropdown", label = "Sortierung", key = "raidSort", disabled = off, items = {
                        { value = "group", text = GF.SORT_TEXT.group }, { value = "role", text = GF.SORT_TEXT.role },
                        { value = "class", text = GF.SORT_TEXT.class }, { value = "name", text = GF.SORT_TEXT.name } } },
                  { type = "dropdown", label = "Vorschau", key = "_gfTest", items = {
                        { value = 10, text = "10 Spieler" }, { value = 20, text = "20 Spieler" }, { value = 40, text = "40 Spieler" } },
                    set = function(v) GF.ShowTest(true, v) end })
            B:Section("Tanks für sich")
            B:Row({ type = "toggle", label = "Eigener Rahmen für Tanks", key = "tankEnabled", reload = true,
                    description = "Alle mit der Rolle Tank noch einmal in einem eigenen Rahmen – verschiebbar im Gestaltungsmodus. Nur, wem das Spiel die Rolle zugewiesen hat." },
                  { type = "slider", label = "Breite der Tanks", key = "tankWidth", min = 60, max = 220, step = 1, format = px,
                    disabled = function() return not K.Get(KEY, "tankEnabled") end })
            B:Note("Die Seitenleiste des Spiels (Zielmarkierungen, Bereitschaftscheck) verschwindet mit den Schlachtzugsrahmen. Markierungen gehen weiter über Tastenbelegung oder das Einheitenmenü.")
        end },
    },
})
