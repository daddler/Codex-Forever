--------------------------------------------------
-- WeintCodex :: PvP (Komfort, Seite "PvP", 1.6.0.0)
--------------------------------------------------
-- Wunsch aus der Gilde (Cónnecticut): Gegnerrahmen fuer die Arena "wie
-- Gladius", Heiler sichtbar machen "wie Healers Have To Die" (auch Heiler
-- unter den Gegnern in Instanzen), im Schlachtfeld schon vor dem Start
-- sehen, wer gegen einen steht, und eine Meldung, wenn ein Feind in die
-- eigene Stadt kommt - mit einem Klick ins Ziel.
--
-- Verhalten nach diesen Addons, eigener Code: Gladius Reloaded ist "All
-- rights reserved" (wie MoveAny), von Healers Have To Die liegt fuer
-- Forever nichts vor. Nichts davon ist uebernommen.
--
-- Vier Teile, ein Schalter je Teil:
--
--   ARENA      bis zu fuenf geschuetzte Einheitenknoepfe (arena1..5):
--              Links = Ziel, Rechts = Fokus. Name, Leben und Klasse sagt
--              der Client (auch geheime Werte gehen an Balken und Text);
--              in der Vorbereitung die Spezialisierung, wenn der Client
--              sie nennt (GetArenaOpponentSpec). Sichtbar nur in der Arena.
--   SCHLACHTFELD  die Gegner aus der Punktetafel (C_PvP.GetScoreInfo, sonst
--              GetBattlefieldScore) - die steht schon vor dem Start.
--              Klick: "/targetexact Name" - ins Ziel kommt nur, wer in
--              Sichtweite ist; das Spiel waehlt kein Ziel aus der Ferne.
--              Leben nur, wenn der Gegner gerade eine Plakette hat oder
--              Ziel/Fokus ist. Belegt wird die Liste nur ausserhalb des
--              Kampfes (geschuetzte Knoepfe).
--   HEILER     ein gruenes Kreuz ueber der Plakette:
--              Spieler: die Rolle ihrer Spezialisierung (Arena: Client,
--              Schlachtfeld: Punktetafel ueber data/specs.lua) - ohne die
--              Angabe keiner. Gegner (NPC) in Instanzen: wer einen Zauber
--              wirkt, dessen Beschreibung im Client vom Heilen spricht.
--              Das ist eine Erkennung, keine Liste - ein Gegner, der nie
--              heilt, bekommt nie ein Kreuz.
--   FEIND      ausserhalb von Instanzen (auf Wunsch nur in Staedten und
--              Gasthaeusern, IsResting): ein feindlicher Spieler mit
--              Plakette -> Meldung im Chat und der Hinweis der seltenen
--              Gegner mit Zielknopf (RA.TargetToast). Je Name hoechstens
--              alle ALERT_AGAIN Sekunden.
--
-- Nichts wird gesendet, nichts automatisch ins Ziel genommen: jedes Ziel
-- ist ein Klick des Spielers.
--------------------------------------------------

local K = WeintCodex.UIKit
local C = WeintCodex.Colors
local KEY = "comfort"

WeintCodex.UIPvPFrames = {}
local PV = WeintCodex.UIPvPFrames

PV.DEFAULTS = {
    pvpArena    = true,
    pvpBg       = true,
    pvpHealers  = true,
    pvpHealMobs = true,
    pvpAlert    = false,
    pvpAlertCity = true,
    pvpAlertSound = true,
}
PV.ARENA_MAX = 5
PV.BG_ROWS = 15
PV.ALERT_AGAIN = 120
PV.HEAL_WORDS = { "heil", "heal" }     -- in der Beschreibung des Zaubers (de/en)
PV.ROW_W, PV.ROW_H = 190, 26

local function Plain(v) return K.Plain(v) end
local function Now() return (_G.GetTime and Plain(_G.GetTime())) or 0 end
local function Opt(k) return K.IsActive(KEY) and K.Get(KEY, k) and true or false end
PV.Opt = Opt

local function InstanceKind()
    if not _G.IsInInstance then return "none" end
    local _, kind = _G.IsInInstance()
    kind = Plain(kind)
    return type(kind) == "string" and kind or "none"
end
PV.InstanceKind = InstanceKind

local function ClassRGB(token)
    if type(token) ~= "string" then return 0.5, 0.5, 0.5 end
    local cc = type(_G.RAID_CLASS_COLORS) == "table" and _G.RAID_CLASS_COLORS[token]
    if type(cc) == "table" and type(cc.r) == "number" then return cc.r, cc.g, cc.b end
    return 0.5, 0.5, 0.5
end

--------------------------------------------------
-- Rollen aus Spezialisierungen
--------------------------------------------------

-- Name eines Talentbaums (de oder en, wie die Punktetafel ihn nennt) +
-- Klasse -> Rolle aus data/specs.lua. Unbekannt: nil, nie "dps".
function PV.RoleOfSpec(specName, classToken)
    if type(specName) ~= "string" or specName == "" then return nil end
    for _, s in ipairs(_G.WeintCodex_Specs or {}) do
        if (s.name == specName or s.english == specName) and (not classToken or s.class == classToken) then
            return s.role
        end
    end
    return nil
end

-- Arena-Gegner i: Spezialisierung, Klasse und Rolle vom Client.
function PV.ArenaSpec(i)
    if not _G.GetArenaOpponentSpec then return nil end
    local ok, id = pcall(_G.GetArenaOpponentSpec, i)
    id = ok and Plain(id) or nil
    if type(id) ~= "number" or id <= 0 or not _G.GetSpecializationInfoByID then return nil end
    local ok2, _, name, _, icon, role, class = pcall(_G.GetSpecializationInfoByID, id)
    if not ok2 then return nil end
    role = Plain(role)
    local r = role == "HEALER" and "healer" or role == "TANK" and "tank" or role == "DAMAGER" and "dps" or nil
    return { name = Plain(name), icon = Plain(icon), role = r, class = Plain(class) }
end

--------------------------------------------------
-- Heiler
--------------------------------------------------

PV.healerNames = {}     -- Spielername -> true (Spezialisierung)
PV.healerGuids = {}     -- NPC-Kennung -> true (Heilzauber gesehen)
PV.healSpell = {}       -- Zauber -> true/false (Beschreibung gelesen)

function PV.IsHealSpell(spellID)
    spellID = Plain(spellID)
    if type(spellID) ~= "number" then return false end
    local known = PV.healSpell[spellID]
    if known ~= nil then return known end
    local desc
    if _G.C_Spell and _G.C_Spell.GetSpellDescription then
        local ok, d = pcall(_G.C_Spell.GetSpellDescription, spellID)
        desc = ok and Plain(d) or nil
    elseif _G.GetSpellDescription then
        local ok, d = pcall(_G.GetSpellDescription, spellID)
        desc = ok and Plain(d) or nil
    end
    -- Ohne Beschreibung (noch nicht geladen): nicht merken, spaeter erneut.
    if type(desc) ~= "string" or desc == "" then return false end
    local low, hit = desc:lower(), false
    for _, w in ipairs(PV.HEAL_WORDS) do
        if low:find(w, 1, true) then hit = true break end
    end
    PV.healSpell[spellID] = hit
    return hit
end

local function UnitNameOf(unit)
    if not _G.UnitName then return nil end
    local ok, n, realm = pcall(_G.UnitName, unit)
    n, realm = ok and Plain(n) or nil, ok and Plain(realm) or nil
    if type(n) ~= "string" then return nil end
    return n, realm
end

local function GuidOf(unit)
    if not _G.UnitGUID then return nil end
    local ok, g = pcall(_G.UnitGUID, unit)
    g = ok and Plain(g) or nil
    return type(g) == "string" and g or nil
end

function PV.IsHealer(unit)
    if K.Bool(_G.UnitIsPlayer and _G.UnitIsPlayer(unit), false) then
        local n = UnitNameOf(unit)
        return n ~= nil and PV.healerNames[n] == true
    end
    local g = GuidOf(unit)
    return g ~= nil and PV.healerGuids[g] == true
end

-- Kreuz an der Plakette: eigene Rahmen, nur angehaengt.
local marks = setmetatable({}, { __mode = "k" })
local function Cross(plate)
    local m = marks[plate]
    if m then return m end
    m = CreateFrame("Frame", nil, plate)
    m:SetSize(16, 16)
    m:SetPoint("BOTTOM", plate, "TOP", 0, 2)
    m:SetFrameStrata("HIGH")
    local g = C.green or { 0.2, 0.78, 0.48 }
    local back = m:CreateTexture(nil, "BACKGROUND")
    back:SetPoint("CENTER")
    back:SetSize(18, 18)
    back:SetColorTexture(0, 0, 0, 0.6)
    local h = m:CreateTexture(nil, "ARTWORK")
    h:SetPoint("CENTER")
    h:SetSize(14, 4)
    h:SetColorTexture(g[1], g[2], g[3], 1)
    local v = m:CreateTexture(nil, "ARTWORK")
    v:SetPoint("CENTER")
    v:SetSize(4, 14)
    v:SetColorTexture(g[1], g[2], g[3], 1)
    marks[plate] = m
    return m
end

local function PlateOf(unit)
    if type(unit) ~= "string" or not unit:find("^nameplate%d+$") then return nil end
    if not (_G.C_NamePlate and _G.C_NamePlate.GetNamePlateForUnit) then return nil end
    local ok, plate = pcall(_G.C_NamePlate.GetNamePlateForUnit, unit)
    if not ok or not plate then return nil end
    if plate.IsForbidden and plate:IsForbidden() then return nil end
    return plate
end

function PV.MarkPlate(unit)
    local plate = PlateOf(unit)
    if not plate then return end
    local hostile = K.Bool(_G.UnitCanAttack and _G.UnitCanAttack("player", unit), false)
    local show = Opt("pvpHealers") and hostile and PV.IsHealer(unit)
    if show then
        Cross(plate):Show()
    elseif marks[plate] then
        marks[plate]:Hide()
    end
end

function PV.RefreshPlates()
    if not (_G.C_NamePlate and _G.C_NamePlate.GetNamePlates) then return end
    local ok, plates = pcall(_G.C_NamePlate.GetNamePlates)
    if not ok or type(plates) ~= "table" then return end
    for _, plate in ipairs(plates) do
        local unit = plate.namePlateUnitToken or (plate.UnitFrame and plate.UnitFrame.unit)
        if unit then PV.MarkPlate(unit) end
    end
end

-- Ein Gegner wirkt etwas: heilt er?
function PV.OnCast(unit, spellID)
    if not Opt("pvpHealers") or not Opt("pvpHealMobs") then return end
    if type(unit) ~= "string" or not unit:find("^nameplate%d+$") then return end
    if InstanceKind() == "none" then return end
    if K.Bool(_G.UnitIsPlayer and _G.UnitIsPlayer(unit), true) then return end
    if not K.Bool(_G.UnitCanAttack and _G.UnitCanAttack("player", unit), false) then return end
    local g = GuidOf(unit)
    if not g or PV.healerGuids[g] then return end
    if PV.IsHealSpell(spellID) then
        PV.healerGuids[g] = true
        PV.MarkPlate(unit)
    end
end

--------------------------------------------------
-- Arena
--------------------------------------------------

local arena
local function BarRow(parent, w, h)
    local r = {}
    r.bar = K.NewBar(parent)
    r.bar:SetSize(w, h)
    r.bar:SetMinMaxValues(0, 1)
    r.bar:SetValue(0)
    r.bg = r.bar:CreateTexture(nil, "BACKGROUND")
    r.bg:SetAllPoints(r.bar)
    local s = C.surface1 or { 0.1, 0.1, 0.12 }
    r.bg:SetColorTexture(s[1], s[2], s[3], 0.9)
    return r
end

local function BuildArena()
    if arena then return arena end
    arena = CreateFrame("Frame", "WeintCodexArenaFrames", UIParent)
    arena:SetSize(PV.ROW_W, PV.ARENA_MAX * (PV.ROW_H + 4))
    arena.buttons = {}
    for i = 1, PV.ARENA_MAX do
        local ok, b = pcall(CreateFrame, "Button", "WeintCodexArena" .. i, arena, "SecureUnitButtonTemplate")
        if not ok or not b then b = CreateFrame("Button", nil, arena) end
        b:SetSize(PV.ROW_W, PV.ROW_H)
        b:SetPoint("TOPLEFT", arena, "TOPLEFT", 0, -(i - 1) * (PV.ROW_H + 4))
        if b.RegisterForClicks then b:RegisterForClicks("AnyUp") end
        b.unit = "arena" .. i
        b:SetAttribute("unit", b.unit)
        b:SetAttribute("*type1", "target")
        b:SetAttribute("*type2", "focus")
        local row = BarRow(b, PV.ROW_W, PV.ROW_H)
        row.bar:SetPoint("TOPLEFT", b, "TOPLEFT", 0, 0)
        b.bar = row.bar
        b.name = K.NewText(b, 11, "OVERLAY")
        b.name:SetPoint("LEFT", b, "LEFT", 6, 0)
        b.name:SetPoint("RIGHT", b, "RIGHT", -60, 0)
        b.name:SetJustifyH("LEFT")
        b.name:SetWordWrap(false)
        b.spec = K.NewText(b, 10, "OVERLAY")
        b.spec:SetPoint("RIGHT", b, "RIGHT", -24, 0)
        b.spec:SetJustifyH("RIGHT")
        b.healer = CreateFrame("Frame", nil, b)
        b.healer:SetSize(16, 16)
        b.healer:SetPoint("RIGHT", b, "RIGHT", -4, 0)
        local g = C.green or { 0.2, 0.78, 0.48 }
        local hh = b.healer:CreateTexture(nil, "ARTWORK"); hh:SetPoint("CENTER"); hh:SetSize(12, 3); hh:SetColorTexture(g[1], g[2], g[3], 1)
        local hv = b.healer:CreateTexture(nil, "ARTWORK"); hv:SetPoint("CENTER"); hv:SetSize(3, 12); hv:SetColorTexture(g[1], g[2], g[3], 1)
        b.healer:Hide()
        b:SetScript("OnEnter", function(self)
            if not GameTooltip then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(self.label or ("Gegner " .. i))
            GameTooltip:AddLine("Links: ins Ziel  ·  Rechts: Fokus", 1, 1, 1)
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
        arena.buttons[i] = b
    end
    arena:Hide()
    arena.WCShowForUnlock = function(self, on)
        self._unlock = on and true or nil
        if K.InCombat() then return end
        if on then
            for i, b in ipairs(self.buttons) do
                local r, g, bl = ClassRGB(({ "PRIEST", "WARRIOR", "MAGE" })[i] or "ROGUE")
                b.bar:SetStatusBarColor(r, g, bl, 1)
                b.bar:SetValue(1 - i * 0.12)
                b.name:SetText("Gegner " .. i)
                b.spec:SetText(i == 1 and "Heilig" or "")
                b.healer:SetShown(i == 1)
                b:SetShown(i <= 3)
            end
            self:Show()
        else
            PV.UpdateArenaVisibility()
        end
    end
    K.RegisterMover(arena, "arenaframes", "Gegner (Arena)", K.Layout("arenaframes"), { secure = true })
    PV.arena = arena
    return arena
end

function PV.InArena() return InstanceKind() == "arena" end

-- Wie viele Gegner? Vorbereitung: Zahl der Spezialisierungen, sonst die
-- groesste vorhandene arenaN-Einheit.
function PV.ArenaCount()
    local n = 0
    if _G.GetNumArenaOpponentSpecs then
        local ok, c = pcall(_G.GetNumArenaOpponentSpecs)
        c = ok and Plain(c) or nil
        if type(c) == "number" then n = c end
    end
    for i = PV.ARENA_MAX, 1, -1 do
        if i <= n then break end
        if K.Bool(_G.UnitExists and _G.UnitExists("arena" .. i), false) then n = i break end
    end
    return math.min(n, PV.ARENA_MAX)
end

function PV.UpdateArenaUnit(i)
    if not arena then return end
    local b = arena.buttons[i]
    if not b then return end
    local unit = b.unit
    local spec = PV.ArenaSpec(i)
    local exists = K.Bool(_G.UnitExists and _G.UnitExists(unit), false)
    local token = spec and spec.class
    if exists and _G.UnitClass then
        local ok, _, cls = pcall(_G.UnitClass, unit)
        cls = ok and Plain(cls) or nil
        if type(cls) == "string" then token = cls end
    end
    local r, g, bl = ClassRGB(token)
    b.bar:SetStatusBarColor(r, g, bl, exists and 1 or 0.4)
    if exists and _G.UnitHealth and _G.UnitHealthMax then
        -- Geheime Werte duerfen an den Balken - nur nicht verglichen werden.
        pcall(b.bar.SetMinMaxValues, b.bar, 0, _G.UnitHealthMax(unit))
        pcall(b.bar.SetValue, b.bar, _G.UnitHealth(unit))
        local nm = _G.UnitName and (_G.UnitName(unit))
        local ok = pcall(b.name.SetText, b.name, nm)
        if not ok then b.name:SetText("Gegner " .. i) end
    else
        b.bar:SetMinMaxValues(0, 1)
        b.bar:SetValue(1)
        b.name:SetText(spec and spec.name or ("Gegner " .. i))
    end
    b.spec:SetText(exists and spec and spec.name or "")
    local n = exists and UnitNameOf(unit)
    b.label = n or (spec and spec.name)
    local healer = spec and spec.role == "healer"
    if healer and n then PV.healerNames[n] = true end
    b.healer:SetShown(Opt("pvpHealers") and healer or false)
end

function PV.UpdateArenaVisibility()
    if not arena or arena._unlock then return end
    if K.InCombat() then K.AfterCombat(PV.UpdateArenaVisibility) return end
    local on = Opt("pvpArena") and PV.InArena()
    if not on then arena:Hide() return end
    local n = PV.ArenaCount()
    for i, b in ipairs(arena.buttons) do
        b:SetShown(i <= math.max(n, 0))
        if i <= n then PV.UpdateArenaUnit(i) end
    end
    arena:SetShown(n > 0)
end

--------------------------------------------------
-- Schlachtfeld: Gegner aus der Punktetafel
--------------------------------------------------

PV.bgEnemies = {}       -- { name, class, spec, role }
local bg
local byName = {}       -- sichtbare Gegner: Name -> Einheit (Plakette/Ziel/Fokus)

function PV.ScoreRows()
    local out = {}
    local n = 0
    if _G.GetNumBattlefieldScores then
        local ok, c = pcall(_G.GetNumBattlefieldScores)
        n = ok and Plain(c) or 0
    end
    if type(n) ~= "number" then return out end
    local mine
    if _G.GetBattlefieldArenaFaction then
        local ok, f = pcall(_G.GetBattlefieldArenaFaction)
        mine = ok and Plain(f) or nil
    end
    for i = 1, n do
        local row
        if _G.C_PvP and _G.C_PvP.GetScoreInfo then
            local ok, s = pcall(_G.C_PvP.GetScoreInfo, i)
            if ok and type(s) == "table" then
                row = { name = Plain(s.name), faction = Plain(s.faction), class = Plain(s.classToken), spec = Plain(s.talentSpec) }
            end
        elseif _G.GetBattlefieldScore then
            local ok, name, _, _, _, _, faction, _, _, _, classToken, _, _, _, _, _, _, talentSpec = pcall(_G.GetBattlefieldScore, i)
            if ok then
                row = { name = Plain(name), faction = Plain(faction), class = Plain(classToken), spec = Plain(talentSpec) }
            end
        end
        if row and type(row.name) == "string" and mine ~= nil and row.faction ~= nil and row.faction ~= mine then
            row.short = row.name:match("^([^%-]+)") or row.name
            row.role = PV.RoleOfSpec(row.spec, row.class)
            out[#out + 1] = row
        end
    end
    table.sort(out, function(a, b)
        if (a.role == "healer") ~= (b.role == "healer") then return a.role == "healer" end
        return a.name < b.name
    end)
    return out
end

local function BuildBg()
    if bg then return bg end
    bg = CreateFrame("Frame", "WeintCodexBgEnemies", UIParent)
    bg:SetSize(PV.ROW_W, 20 + PV.BG_ROWS * (PV.ROW_H - 6 + 2))
    bg.kachel = K.Kachel(bg, { shadow = 4 })
    bg.head = K.NewText(bg, 11, "OVERLAY")
    bg.head:SetPoint("TOPLEFT", bg, "TOPLEFT", 6, -5)
    bg.rows = {}
    local h = PV.ROW_H - 6
    for i = 1, PV.BG_ROWS do
        local ok, b = pcall(CreateFrame, "Button", "WeintCodexBgEnemy" .. i, bg, "SecureActionButtonTemplate")
        if not ok or not b then b = CreateFrame("Button", nil, bg) end
        b:SetSize(PV.ROW_W - 8, h)
        b:SetPoint("TOPLEFT", bg, "TOPLEFT", 4, -20 - (i - 1) * (h + 2))
        if b.RegisterForClicks then b:RegisterForClicks("AnyUp") end
        b:SetAttribute("type1", "macro")
        local row = BarRow(b, PV.ROW_W - 8, h)
        row.bar:SetPoint("TOPLEFT", b, "TOPLEFT", 0, 0)
        b.bar = row.bar
        b.name = K.NewText(b, 10, "OVERLAY")
        b.name:SetPoint("LEFT", b, "LEFT", 4, 0)
        b.name:SetPoint("RIGHT", b, "RIGHT", -70, 0)
        b.name:SetJustifyH("LEFT")
        b.name:SetWordWrap(false)
        b.spec = K.NewText(b, 9, "OVERLAY")
        b.spec:SetPoint("RIGHT", b, "RIGHT", -4, 0)
        b.spec:SetJustifyH("RIGHT")
        b:SetScript("OnEnter", function(self)
            if not GameTooltip or not self.enemy then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(self.enemy.name)
            GameTooltip:AddLine("Klick: ins Ziel – nur in Sichtweite.", 1, 1, 1, true)
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
        b:Hide()
        bg.rows[i] = b
    end
    bg:Hide()
    bg.WCShowForUnlock = function(self, on)
        self._unlock = on and true or nil
        if K.InCombat() then return end
        if on then
            PV.FillBg({ { name = "Gegner-Eins", short = "Gegner-Eins", class = "PRIEST", spec = "Heilig", role = "healer" },
                        { name = "Gegner-Zwei", short = "Gegner-Zwei", class = "WARRIOR", spec = "Waffen" } }, true)
            self:Show()
        else
            PV.UpdateBg()
        end
    end
    K.RegisterMover(bg, "bgenemies", "Gegner (Schlachtfeld)", K.Layout("bgenemies"), { secure = true })
    PV.bg = bg
    return bg
end

-- Liste belegen - nur ausserhalb des Kampfes (Makrotext, Zeigen).
function PV.FillBg(list, test)
    local f = BuildBg()
    if K.InCombat() then return false end
    f.head:SetText("Gegner: " .. #list .. (#list > PV.BG_ROWS and (" (" .. PV.BG_ROWS .. " gezeigt)") or ""))
    local h = PV.ROW_H - 6
    local shown = 0
    for i, b in ipairs(f.rows) do
        local e = list[i]
        b.enemy = e
        if e then
            shown = i
            local r, g, bl = ClassRGB(e.class)
            b.bar:SetStatusBarColor(r, g, bl, 0.55)
            b.bar:SetMinMaxValues(0, 1)
            b.bar:SetValue(1)
            b.name:SetText((e.role == "healer" and WeintCodex.ColorText("green", "+ ") or "") .. e.short)
            b.spec:SetText(e.spec or "")
            if not test then b:SetAttribute("macrotext1", "/targetexact " .. e.name) end
            b:Show()
        else
            b:SetAttribute("macrotext1", nil)
            b:Hide()
        end
    end
    f:SetHeight(24 + math.max(shown, 1) * (h + 2))
    return true
end

function PV.UpdateBg()
    if bg and bg._unlock then return end
    local on = Opt("pvpBg") and InstanceKind() == "pvp"
    if not on then
        if bg then
            if K.InCombat() then K.AfterCombat(PV.UpdateBg) return end
            bg:Hide()
        end
        return
    end
    local list = PV.ScoreRows()
    wipe(PV.bgEnemies)
    for _, e in ipairs(list) do
        PV.bgEnemies[#PV.bgEnemies + 1] = e
        if e.role == "healer" then PV.healerNames[e.short] = true; PV.healerNames[e.name] = true end
    end
    if K.InCombat() then K.AfterCombat(PV.UpdateBg) return end
    if #list == 0 then
        if bg then bg:Hide() end
        return
    end
    PV.FillBg(list)
    bg:Show()
end

-- Leben eines sichtbaren Gegners an seiner Zeile (auch im Kampf: nur Balken).
function PV.BgHealth()
    if not bg or not bg:IsShown() then return end
    for _, b in ipairs(bg.rows) do
        local e = b.enemy
        local unit = e and (byName[e.name] or byName[e.short])
        if unit and K.Bool(_G.UnitExists and _G.UnitExists(unit), false) then
            pcall(b.bar.SetMinMaxValues, b.bar, 0, _G.UnitHealthMax(unit))
            pcall(b.bar.SetValue, b.bar, _G.UnitHealth(unit))
            local r, g, bl = ClassRGB(e.class)
            b.bar:SetStatusBarColor(r, g, bl, 1)
        elseif e then
            b.bar:SetMinMaxValues(0, 1)
            b.bar:SetValue(1)
            local r, g, bl = ClassRGB(e.class)
            b.bar:SetStatusBarColor(r, g, bl, 0.55)
        end
    end
end

--------------------------------------------------
-- Feind in der Naehe
--------------------------------------------------

PV.alerted = {}
function PV.CheckEnemy(unit)
    if not Opt("pvpAlert") then return end
    if InstanceKind() ~= "none" then return end
    if Opt("pvpAlertCity") and not K.Bool(_G.IsResting and _G.IsResting(), false) then return end
    if not K.Bool(_G.UnitIsPlayer and _G.UnitIsPlayer(unit), false) then return end
    if not K.Bool(_G.UnitIsEnemy and _G.UnitIsEnemy("player", unit), false) then return end
    local name, realm = UnitNameOf(unit)
    if not name then return end
    local full = (realm and realm ~= "") and (name .. "-" .. realm) or name
    local t = Now()
    if PV.alerted[full] and t - PV.alerted[full] < PV.ALERT_AGAIN then return end
    PV.alerted[full] = t
    local level = _G.UnitLevel and Plain(_G.UnitLevel(unit))
    local cls
    if _G.UnitClass then
        local ok, c = pcall(_G.UnitClass, unit)
        cls = ok and Plain(c) or nil
    end
    local desc = {}
    if type(level) == "number" and level > 0 then desc[#desc + 1] = "Stufe " .. level end
    if type(cls) == "string" then desc[#desc + 1] = cls end
    local sub = table.concat(desc, " · ")
    print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " " .. WeintCodex.ColorText("red", "Feind in der Nähe: ") .. full .. (sub ~= "" and (" (" .. sub .. ")") or ""))
    if Opt("pvpAlertSound") and _G.PlaySound and _G.SOUNDKIT and _G.SOUNDKIT.RAID_WARNING then
        pcall(_G.PlaySound, _G.SOUNDKIT.RAID_WARNING, "Master")
    end
    local RA = WeintCodex.UIRares
    if RA and RA.TargetToast then RA.TargetToast("Feind in der Nähe: " .. name, sub, full) end
    PV.lastAlert = full
end

--------------------------------------------------
-- Ereignisse
--------------------------------------------------

local function Track(unit, on)
    local n, realm = UnitNameOf(unit)
    if not n then return end
    local full = (realm and realm ~= "") and (n .. "-" .. realm) or n
    if on then byName[n], byName[full] = unit, unit
    else
        if byName[n] == unit then byName[n] = nil end
        if byName[full] == unit then byName[full] = nil end
    end
end

local ev = CreateFrame("Frame")
for _, e in ipairs({ "PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA", "ARENA_PREP_OPPONENT_SPECIALIZATIONS",
                     "ARENA_OPPONENT_UPDATE", "UPDATE_BATTLEFIELD_SCORE", "NAME_PLATE_UNIT_ADDED",
                     "NAME_PLATE_UNIT_REMOVED", "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_CHANNEL_START",
                     "UNIT_SPELLCAST_SUCCEEDED", "UNIT_HEALTH", "UNIT_MAXHEALTH", "UNIT_NAME_UPDATE",
                     "PLAYER_TARGET_CHANGED", "PLAYER_FOCUS_CHANGED" }) do
    pcall(ev.RegisterEvent, ev, e)
end
ev:SetScript("OnEvent", function(_, event, unit, _, spellID)
    if not K.IsActive(KEY) then return end
    if event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
        wipe(PV.healerGuids)
        if InstanceKind() == "none" then wipe(PV.healerNames) end
        if PV.InArena() and Opt("pvpArena") then BuildArena() end
        PV.UpdateArenaVisibility()
        if InstanceKind() == "pvp" and _G.RequestBattlefieldScoreData then pcall(_G.RequestBattlefieldScoreData) end
        PV.UpdateBg()
    elseif event == "ARENA_PREP_OPPONENT_SPECIALIZATIONS" or event == "ARENA_OPPONENT_UPDATE" then
        if Opt("pvpArena") then BuildArena() end
        PV.UpdateArenaVisibility()
        PV.RefreshPlates()
    elseif event == "UPDATE_BATTLEFIELD_SCORE" then
        PV.UpdateBg()
        PV.RefreshPlates()
    elseif event == "NAME_PLATE_UNIT_ADDED" then
        Track(unit, true)
        PV.MarkPlate(unit)
        PV.CheckEnemy(unit)
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        Track(unit, false)
    elseif event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" or event == "UNIT_SPELLCAST_SUCCEEDED" then
        PV.OnCast(unit, spellID)
    elseif event == "PLAYER_TARGET_CHANGED" then
        Track("target", true)
    elseif event == "PLAYER_FOCUS_CHANGED" then
        Track("focus", true)
    elseif type(unit) == "string" then
        local i = unit:match("^arena(%d)$")
        if i and arena and arena:IsShown() then PV.UpdateArenaUnit(tonumber(i)) end
        if bg and bg:IsShown() then PV.BgHealth() end
    end
end)
PV.ev = ev

-- Punktetafel alle 5 s neu anfordern, solange man im Schlachtfeld ist.
local tick = CreateFrame("Frame")
tick:SetScript("OnUpdate", function(self, el)
    self.acc = (self.acc or 0) + (el or 0)
    if self.acc < 5 then return end
    self.acc = 0
    if Opt("pvpBg") and InstanceKind() == "pvp" and _G.RequestBattlefieldScoreData then
        pcall(_G.RequestBattlefieldScoreData)
    end
end)

--------------------------------------------------
-- Einstellungen
--------------------------------------------------

local function Build(B)
    local function off(k) return function() return not K.Get(KEY, k) end end
    B:Section("Arena", "Gegnerrahmen für bis zu fünf Gegner: Name, Leben und Klasse, in der Vorbereitung die Spezialisierung, wenn das Spiel sie nennt. Links ins Ziel, rechts Fokus. Verschieben über „Rahmen entsperren“.")
    B:Row({ type = "toggle", label = "Gegnerrahmen in der Arena", key = "pvpArena" },
          { type = "empty" })
    B:Section("Schlachtfeld", "Die Gegner aus der Punktetafel – schon vor dem Start. Klick nimmt sie ins Ziel, sobald sie in Sichtweite sind; Leben, wenn sie eine Plakette haben. Heiler stehen oben.")
    B:Row({ type = "toggle", label = "Gegnerliste im Schlachtfeld", key = "pvpBg" },
          { type = "empty" })
    B:Section("Heiler", "Ein grünes Kreuz über gegnerischen Heilern. Spieler: nach ihrer Spezialisierung (Arena, Schlachtfeld). Gegner in Instanzen: sobald sie einen Heilzauber wirken – ein Gegner, der nie heilt, bekommt keins.")
    B:Row({ type = "toggle", label = "Heiler markieren", key = "pvpHealers" },
          { type = "toggle", label = "Auch heilende Gegner in Instanzen", key = "pvpHealMobs", disabled = off("pvpHealers") })
    B:Section("Feind in der Nähe", "Meldung, sobald ein feindlicher Spieler eine Plakette bekommt – mit Klick ins Ziel. Nur außerhalb von Instanzen; jeden Namen höchstens alle zwei Minuten.")
    B:Row({ type = "toggle", label = "Feinde melden", key = "pvpAlert" },
          { type = "toggle", label = "Nur in Städten und Gasthäusern", key = "pvpAlertCity", disabled = off("pvpAlert") })
    B:Row({ type = "toggle", label = "Mit Ton", key = "pvpAlertSound", disabled = off("pvpAlert") },
          { type = "empty" })
end
PV.BuildPage = Build

local mod = K.Module(KEY)
if mod then
    for k, v in pairs(PV.DEFAULTS) do
        if mod.defaults[k] == nil then mod.defaults[k] = v end
    end
    mod.pages[#mod.pages + 1] = { key = "pvp", label = "PvP", build = Build }
    if type(mod.pageOrder) == "table" then mod.pageOrder.pvp = 15 end
end

K.Listen(function(kind, key)
    if (kind == "active" or kind == "setting") and key == KEY then
        PV.UpdateArenaVisibility()
        PV.UpdateBg()
        PV.RefreshPlates()
    end
end)
