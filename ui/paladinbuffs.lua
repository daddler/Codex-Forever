--------------------------------------------------
-- WeintCodex :: Komfort - Segen verteilen (Paladin)
--------------------------------------------------
-- Wunsch des Spielers: "Einstellen, welche Klasse und Rolle welchen Buff
-- haben soll und dann braucht man nur noch auf Buffen klicken und es
-- passiert dann alles automatisch statt dass man nachdenken muss."
--
-- Nach dem VERHALTEN eines bekannten Paladin-Addons gebaut, ohne dessen
-- Code, Daten oder Bilder ("All Rights Reserved"); in Spielertexten wird
-- es nicht genannt.
--
-- WAS FOREVER HERGIBT (Stand Beta):
--   * Grosse Segen gibt es nicht - nur der Segen auf ein Ziel. Die grossen
--     Nummern aus Classic stehen zwar im Lehrerbestand, werden hier aber
--     ausdruecklich ausgelassen (PB.GREATER).
--   * Jeder Segen haelt 60 Minuten.
--   * Begleiter werden nicht gesegnet.
--   * Auren koennen im Kampf und in Instanzen geheim sein: gelesen wird nur
--     ausserhalb des Kampfes, jeder Wert ueber K.Plain/type(). Was nicht
--     lesbar ist, heisst "unklar" - nicht "fehlt" und nicht "sitzt"
--     (unknown ~= 0). Was WeintCodex selbst erfolgreich gezaubert hat,
--     merkt es sich (UNIT_SPELLCAST_SUCCEEDED) und zaehlt es 60 Minuten.
--
-- ZAUBERN IST GESCHUETZT. Der Knopf "Buffen" ist ein SecureActionButton
-- (type = spell, spell = Nummer, unit = Einheit der Gruppe). Kurz vor jedem
-- Klick (PreClick, nur ausserhalb des Kampfes - im Kampf duerfen Attribute
-- nicht geaendert werden) sucht WeintCodex das naechste Gruppenmitglied
-- ohne seinen Segen (oder mit weniger Restzeit als eingestellt) und setzt
-- Ziel und Zauber. Im Kampf tut der Knopf nichts und sagt das.
-- Tastenbelegung: Bindings.xml, "CLICK WeintCodexBlessButton:LeftButton".
--
-- NICHTS WIRD GESENDET. Keine Addon-Nachrichten, keine Absprache mit
-- anderen Paladinen - das waere eine neue Ausnahme, die niemand verlangt.
--
-- UNGEMESSEN: ob der Forever-Client das Attribut `spell` als Nummer nimmt
-- (sonst faellt PB auf den Namen zurueck, wenn der Client ihn nennt), und
-- ob IsSpellInRange fuer Gruppenmitglieder dort eine Antwort gibt (ohne
-- Antwort wird es versucht - der Client meldet "ausser Reichweite" selbst).
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIPaladinBuffs = {}

local PB = WeintCodex.UIPaladinBuffs
local K = WeintCodex.UIKit
local KEY = "comfort"
local MIN = 60

PB.BUTTON = "WeintCodexBlessButton"
PB.DURATION = 60 * MIN

-- Segen und ihr Rang 1 (Nummern aus data/trainer.lua; Refugium kommt aus
-- dem Talentbaum, seine hoeheren Raenge vom Lehrer).
-- Zur Wahl nur die 60-Minuten-Segen (6.102.0.0, Wunsch): Macht, Weisheit,
-- Koenige, Licht. Rettung und Refugium bleiben bekannt, sind aber keine Wahl.
PB.ORDER = { "might", "wisdom", "kings", "light" }
PB.BLESSINGS = {
    might     = { root = 19740, label = "Macht" },
    wisdom    = { root = 19742, label = "Weisheit" },
    kings     = { root = 20217, label = "Könige" },
    salvation = { root = 1038,  label = "Rettung" },
    light     = { root = 19977, label = "Licht" },
    sanctuary = { root = 20911, label = "Refugium" },
}
-- Grosse Segen (Lehrerbestand, Classic). 6.102.0.0, Beta-Test: "Laut
-- WeintCodex im Berufsbereich vom Paladin gibt es grosse Segen" - die
-- Annahme "auf Forever nicht vorhanden" war falsch. Ein grosser Segen trifft
-- alle der Klasse in der Gruppe; genutzt nur, wenn ALLE dieser Klasse
-- denselben Segen bekommen sollen und er gelernt ist.
PB.GREATER = { [25782] = true, [25916] = true, [25894] = true, [25918] = true,
               [25898] = true, [25895] = true, [25890] = true, [25899] = true }
PB.GREATER_OF = { might = { 25782, 25916 }, wisdom = { 25894, 25918 }, kings = { 25898 }, light = { 25890 } }

PB.CLASSES = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID" }
PB.CLASS_LABEL = { WARRIOR = "Krieger", PALADIN = "Paladin", HUNTER = "Jäger", ROGUE = "Schurke",
                   PRIEST = "Priester", SHAMAN = "Schamane", MAGE = "Magier", WARLOCK = "Hexenmeister",
                   DRUID = "Druide" }
PB.ROLES = { "TANK", "HEALER", "DAMAGER" }
PB.editClass = "WARRIOR"   -- in den Einstellungen gewaehlte Klasse
PB.ROLE_LABEL = { TANK = "Tank", HEALER = "Heiler", DAMAGER = "Schaden",
                  MELEE = "Nahkampf", CASTER = "Zauberschaden" }
-- Welche Rollen eine Klasse spielen kann (6.101.0.0, Wunsch: "nach der
-- Auswahl der Klasse auch die Rolle"). Schaden ist bei Druide und Schamane
-- geteilt: Nahkampf braucht Macht, Zauberschaden Weisheit.
PB.CLASS_ROLES = {
    WARRIOR = { "TANK", "MELEE" },
    PALADIN = { "TANK", "HEALER", "MELEE" },
    HUNTER  = { "DAMAGER" },
    ROGUE   = { "MELEE" },
    PRIEST  = { "HEALER", "CASTER" },
    SHAMAN  = { "HEALER", "MELEE", "CASTER" },
    MAGE    = { "CASTER" },
    WARLOCK = { "CASTER" },
    DRUID   = { "TANK", "HEALER", "MELEE", "CASTER" },
}
-- Talentbaum (Reihenfolge wie data/specs.lua) -> Rolle dieser Liste.
-- Wilder Kampf: Tank nur mit Gruppenrolle Tank, sonst Nahkampf.
PB.TREE_ROLE = {
    WARRIOR = { "MELEE", "MELEE", "TANK" },
    PALADIN = { "HEALER", "TANK", "MELEE" },
    HUNTER  = { "DAMAGER", "DAMAGER", "DAMAGER" },
    ROGUE   = { "MELEE", "MELEE", "MELEE" },
    PRIEST  = { "HEALER", "HEALER", "CASTER" },
    SHAMAN  = { "CASTER", "MELEE", "HEALER" },
    MAGE    = { "CASTER", "CASTER", "CASTER" },
    WARLOCK = { "CASTER", "CASTER", "CASTER" },
    DRUID   = { "CASTER", "MELEE", "HEALER" },
}

-- Voreinstellung: Nahkampf Macht, Zauberer und Jaeger (Macht wirkt in
-- Classic nur auf Nahkampf-Angriffskraft) Weisheit; Tank Koenige, Heiler
-- Weisheit, Schaden wie die Klasse. Rettung nie fuer Tanks (PB.Want).
PB.DEFAULTS = {
    blessOn = false,
    blessGreater = true,
    blessRefresh = 5,                -- Minuten Restzeit, ab der neu gesegnet wird
    bless_WARRIOR = "might", bless_ROGUE = "might", bless_PALADIN = "might",
    bless_HUNTER = "wisdom", bless_SHAMAN = "wisdom", bless_DRUID = "wisdom",
    bless_PRIEST = "wisdom", bless_MAGE = "wisdom", bless_WARLOCK = "wisdom",
    blessRole_TANK = "kings", blessRole_HEALER = "wisdom", blessRole_DAMAGER = "class",
}
-- Je Klasse und Rolle (bless_KLASSE_ROLLE): Tank Koenige, Heiler und
-- Zauberschaden Weisheit, Nahkampf Macht, Jaeger Macht.
for class, roles in pairs(PB.CLASS_ROLES) do
    for _, r in ipairs(roles) do
        PB.DEFAULTS["bless_" .. class .. "_" .. r] =
            r == "TANK" and "kings" or (r == "HEALER" or r == "CASTER") and "wisdom" or "might"
    end
end

local function Call(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b, c = pcall(fn, ...)
    if not ok then return nil end
    return K.Plain(a), K.Plain(b), K.Plain(c)
end

local function Now() return Call(_G.GetTime) or 0 end

function PB.IsPaladin()
    local _, class = Call(_G.UnitClass, "player")
    return class == "PALADIN"
end

function PB.On()
    return K.IsActive(KEY) and K.Get(KEY, "blessOn") and PB.IsPaladin() and true or false
end

--------------------------------------------------
-- Rangketten aus dem Lehrerbestand
--------------------------------------------------

local chains = {}
function PB.Chain(key)
    if chains[key] then return chains[key] end
    local b = PB.BLESSINGS[key]
    local chain = { b.root }
    local T = WeintCodex.TrainerData
    local spells = (T and T.Spells) and T.Spells("PALADIN") or {}
    local grew = true
    while grew do
        grew = false
        local last = chain[#chain]
        for _, s in ipairs(spells) do
            if not PB.GREATER[s.id] and s.id ~= last then
                for _, r in ipairs(s.requiredIds or {}) do
                    if r == last then chain[#chain + 1] = s.id grew = true break end
                end
            end
            if grew then break end
        end
    end
    chains[key] = chain
    return chain
end

local function Knows(id)
    if Call(_G.IsPlayerSpell, id) then return true end
    if Call(_G.IsSpellKnown, id) then return true end
    return false
end

-- Hoechster gelernter Rang oder nil.
function PB.Best(key)
    if not PB.BLESSINGS[key] then return nil end
    local chain = PB.Chain(key)
    for i = #chain, 1, -1 do
        if Knows(chain[i]) then return chain[i] end
    end
    return nil
end

function PB.BestGreater(key)
    local g = PB.GREATER_OF[key]
    if not g or K.Get(KEY, "blessGreater") == false then return nil end
    for i = #g, 1, -1 do if Knows(g[i]) then return g[i] end end
    return nil
end

local names = {}
local function SpellName(id)
    local cs = _G.C_Spell
    local n = cs and Call(cs.GetSpellName, id)
    if type(n) ~= "string" or n == "" then n = Call(_G.GetSpellInfo, id) end
    if type(n) == "string" and n ~= "" then return n end
end
-- Name des Segens fuer den Abgleich mit Auren (Forever fuehrt Auren teils
-- unter anderen Nummern als den Zauber - wie ui/bufftimes.lua).
function PB.Name(key)
    if names[key] then return names[key] end
    local chain = PB.Chain(key)
    for i = 1, #chain do
        local n = SpellName(chain[i])
        if n then names[key] = n return n end
    end
end

--------------------------------------------------
-- Wer bekommt was
--------------------------------------------------

--------------------------------------------------
-- Rolle: Talente (eigene direkt, andere per Betrachten) vor Gruppenrolle
--------------------------------------------------
PB.specOf = {}      -- [guid] = Index des Baums mit den meisten Punkten
PB.specAt = {}      -- [guid] = Zeit der Messung

-- Punkte je Baum aus GetTalentTabInfo (Classic: 3. Wert, neuere: 5.).
local function TreePoints(tab, inspect)
    if type(_G.GetTalentTabInfo) ~= "function" then return nil end
    local ok, a, b, c, d, e = pcall(_G.GetTalentTabInfo, tab, inspect)
    if not ok then return nil end
    c, e = K.Plain(c), K.Plain(e)
    if type(e) == "number" then return e end
    if type(c) == "number" then return c end
    return nil
end

function PB.ReadTrees(inspect)
    local best, bestN, any = nil, -1, false
    for t = 1, 3 do
        local n = TreePoints(t, inspect)
        if n then any = true if n > bestN then best, bestN = t, n end end
    end
    if not any or bestN <= 0 then return nil end
    return best
end

-- Betrachten: eine Einheit nach der anderen, nur ausserhalb des Kampfes.
PB.inspectQ, PB.inspecting = {}, nil
function PB.QueueInspect(unit, guid)
    if not guid or PB.specOf[guid] or PB.inspectQ[guid] then return end
    PB.inspectQ[guid] = unit
end
function PB.InspectNext()
    if PB.inspecting or K.InCombat() or not _G.NotifyInspect then return end
    local f = _G.InspectFrame
    if f and f.IsShown and f:IsShown() then return end
    for guid, unit in pairs(PB.inspectQ) do
        PB.inspectQ[guid] = nil
        if Call(_G.UnitGUID, unit) == guid and Call(_G.CanInspect, unit) then
            PB.inspecting = guid
            pcall(_G.NotifyInspect, unit)
            return
        end
    end
end
function PB.OnInspect(guid)
    guid = K.Plain(guid)
    if not PB.inspecting or (type(guid) == "string" and guid ~= PB.inspecting) then return end
    local t = PB.ReadTrees(true)
    if t then PB.specOf[PB.inspecting] = t PB.specAt[PB.inspecting] = Now() end
    PB.inspecting = nil
    if _G.ClearInspectPlayer then pcall(_G.ClearInspectPlayer) end
end

function PB.RoleOf(unit, class)
    local roles = class and PB.CLASS_ROLES[class]
    if not roles then return nil end
    local group = Call(_G.UnitGroupRolesAssigned, unit)
    local guid = Call(_G.UnitGUID, unit)
    local tree
    if Call(_G.UnitIsUnit, unit, "player") then
        tree = PB.ReadTrees(false)
    elseif type(guid) == "string" then
        tree = PB.specOf[guid]
        if not tree then PB.QueueInspect(unit, guid) end
    end
    if tree then
        local r = PB.TREE_ROLE[class] and PB.TREE_ROLE[class][tree]
        -- Wilder Druide: Baer nur als Tank der Gruppe
        if class == "DRUID" and tree == 2 and group == "TANK" then r = "TANK" end
        if r then return r end
    end
    if group == "TANK" or group == "HEALER" then
        for _, r in ipairs(roles) do if r == group then return r end end
    end
    -- Schaden oder unbekannt: erste Schadensrolle der Klasse
    for _, r in ipairs(roles) do
        if r == "MELEE" or r == "CASTER" or r == "DAMAGER" then return r end
    end
    return roles[1]
end

-- Gewuenschter, gelernter Segen fuer eine Einheit: key, spellId - oder nil.
-- Rolle vor Klasse; nicht gelernt -> Klasse; dann Macht. Tanks nie Rettung.
local function Usable(key, tank)
    if type(key) ~= "string" or not PB.BLESSINGS[key] then return nil end
    if tank and key == "salvation" then return nil end
    return PB.Best(key)
end

function PB.Want(class, role)
    local tank = role == "TANK"
    -- Klasse + Rolle zuerst (6.101.0.0)
    local cr = class and role and K.Get(KEY, "bless_" .. class .. "_" .. role)
    if cr == "none" then return nil end
    if cr then
        local id = Usable(cr, tank)
        if id then return cr, id end
    end
    local roleKey = role and K.Get(KEY, "blessRole_" .. role)
    if roleKey == "none" then return nil end
    if roleKey and roleKey ~= "class" then
        local id = Usable(roleKey, tank)
        if id then return roleKey, id end
    end
    local classKey = class and K.Get(KEY, "bless_" .. class)
    if classKey == "none" then return nil end
    local id = Usable(classKey, tank)
    if id then return classKey, id end
    id = Usable("might", tank)
    if id then return "might", id end
    return nil
end

-- Selbst gezaubert: [guid] = { [key] = Zeit }.
PB.memo = {}

-- Restzeit des Segens auf der Einheit: Sekunden, math.huge (ohne Ende),
-- 0 (fehlt) oder nil (unklar: Auren geheim oder nicht lesbar).
local gnames = {}
function PB.GreaterName(key)
    if gnames[key] ~= nil then return gnames[key] or nil end
    local g = PB.GREATER_OF[key]
    local n = g and SpellName(g[1])
    gnames[key] = n or false
    return n
end

function PB.Remaining(unit, key, guid)
    local name = PB.Name(key)
    local ua = _G.C_UnitAuras
    local known = false
    if name and ua and ua.GetAuraDataByIndex and not K.InCombat() then
        known = true
        for i = 1, 40 do
            local ok, d = pcall(ua.GetAuraDataByIndex, unit, i, "HELPFUL")
            if not ok then known = false break end
            if type(d) ~= "table" then break end
            local n = K.Plain(d.name)
            if type(n) ~= "string" then known = false
            elseif n == name or (PB.GreaterName(key) and n == PB.GreaterName(key)) then
                local exp = K.Plain(d.expirationTime)
                if type(exp) ~= "number" then return nil end
                if exp == 0 then return math.huge end
                local left = exp - Now()
                return left > 0 and left or 0
            end
        end
    end
    local m = guid and PB.memo[guid]
    local t = m and m[key]
    if t then
        local left = t + PB.DURATION - Now()
        if left > 0 then return left end
    end
    if known then return 0 end
    return nil
end

local PARTY = { "player", "party1", "party2", "party3", "party4" }
local RAID = {}
for i = 1, 40 do RAID[i] = "raid" .. i end
local SOLO = { "player" }

local function Units()
    if Call(_G.IsInRaid) then return RAID end
    if Call(_G.IsInGroup) then return PARTY end
    return SOLO
end

local function InRange(unit, id)
    if unit == "player" then return true end
    local cs = _G.C_Spell
    local r
    if cs and cs.IsSpellInRange then r = Call(cs.IsSpellInRange, id, unit) end
    if r == nil and _G.IsSpellInRange then
        local n = SpellName(id)
        if n then r = Call(_G.IsSpellInRange, n, unit) end
    end
    if r == true or r == 1 then return true end
    if r == false or r == 0 then return false end
    local inR, checked = Call(_G.UnitInRange, unit)
    if checked and not inR then return false end
    return true      -- unklar: versuchen; der Client meldet die Reichweite selbst
end

-- Ergebnis des letzten Durchlaufs (fuer Anzeige und Einstellungen).
PB.result = { missing = 0, unclear = 0, away = 0, total = 0 }

-- Ein Durchlauf ueber die Gruppe. Gibt das erste Ziel zurueck (unit, id,
-- key) und zaehlt in PB.result. Legt keine Tabellen an.
function PB.Scan()
    local res = PB.result
    res.missing, res.unclear, res.away, res.total = 0, 0, 0, 0
    local refresh = (tonumber(K.Get(KEY, "blessRefresh")) or 5) * MIN
    local fU, fI, fK, uU, uI, uK
    for _, unit in ipairs(Units()) do
        if Call(_G.UnitExists, unit) and Call(_G.UnitIsPlayer, unit) ~= false then
            local _, class = Call(_G.UnitClass, unit)
            local key, id = PB.Want(class, PB.RoleOf(unit, class))
            if key then
                res.total = res.total + 1
                local guid = Call(_G.UnitGUID, unit)
                local left = PB.Remaining(unit, key, type(guid) == "string" and guid or nil)
                if left == nil or left < refresh then
                    local usable = Call(_G.UnitIsConnected, unit) ~= false
                        and not Call(_G.UnitIsDeadOrGhost, unit) and InRange(unit, id)
                    if left == nil then
                        res.unclear = res.unclear + 1
                        if usable and not uU then uU, uI, uK = unit, id, key end
                    else
                        res.missing = res.missing + 1
                        if usable then
                            if not fU then fU, fI, fK, PB.planClass = unit, id, key, class end
                        else
                            res.away = res.away + 1
                        end
                    end
                end
            end
        end
    end
    if fU then
        local g = PB.BestGreater(fK)
        if g and PB.AllOfClassWant(PB.planClass, fK) then return fU, g, fK end
        return fU, fI, fK
    end
    return uU, uI, uK
end

-- Sollen alle dieser Klasse in der Gruppe denselben Segen haben?
function PB.AllOfClassWant(class, key)
    if not class then return false end
    for _, unit in ipairs(Units()) do
        if Call(_G.UnitExists, unit) then
            local _, c = Call(_G.UnitClass, unit)
            if c == class and PB.Want(c, PB.RoleOf(unit, c)) ~= key then return false end
        end
    end
    return true
end

--------------------------------------------------
-- Rahmen mit dem Knopf
--------------------------------------------------

PB.W, PB.H, PB.PAD = 168, 58, 8
local frame
local NO_TARGET = "Alle gesegnet."

function PB.Frame()
    if frame then return frame end
    if K.InCombat() then return nil end
    local f = CreateFrame("Frame", "WeintCodexBlessFrame", UIParent)
    f:SetSize(PB.W, PB.H)
    K.Kachel(f, { alpha = 0.92, shadow = 6 })
    f.title = K.NewText(f, 12, "OVERLAY")
    f.title:SetPoint("TOPLEFT", f, "TOPLEFT", PB.PAD, -PB.PAD)
    f.title:SetText(WeintCodex.AC .. "Segen|r")
    f.count = K.NewText(f, 11, "OVERLAY")
    f.count:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PB.PAD, -PB.PAD)
    f.count:SetJustifyH("RIGHT")
    f.btn = WeintCodex.CreateButton(f, { text = "Buffen", kind = "primary", height = 24, size = 12 })
    f.btn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", PB.PAD, PB.PAD)
    f.btn:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -PB.PAD, PB.PAD)
    local ok, b = pcall(CreateFrame, "Button", PB.BUTTON, f, "SecureActionButtonTemplate")
    if not ok or not b then return nil end
    b:SetAllPoints(f.btn)
    b:SetFrameLevel((f.btn:GetFrameLevel() or 1) + 5)
    if b.RegisterForClicks then b:RegisterForClicks("AnyUp") end
    b:SetAttribute("useOnKeyDown", false)
    b:SetScript("PreClick", function(self) PB.PreClick(self) end)
    b:SetScript("OnEnter", function(self)
        if not GameTooltip then return end
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:AddLine("Segen verteilen")
        GameTooltip:AddLine("Jeder Klick segnet das nächste Gruppenmitglied ohne seinen Segen. "
            .. "Nur außerhalb des Kampfes.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    f.secure = b
    f.WCShowForUnlock = function(self, on) self._unlock = on and true or nil PB.Update() end
    K.RegisterMover(f, "paladinbuffs", "Segen", K.Layout("paladinbuffs"), { secure = true })
    -- Frei ziehbar am Rahmen (6.100.1.0, Wunsch), nicht nur im
    -- Gestaltungsmodus; der Platz wird wie dort gemerkt. Nie im Kampf.
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) if not K.InCombat() then self:StartMoving() end end)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        if K.SavePosition then K.SavePosition("paladinbuffs", self) end
    end)
    f:Hide()
    frame = f
    PB.frame = f
    return f
end

-- Kurz vor dem Klick: Ziel und Zauber setzen (nur ausserhalb des Kampfes).
function PB.PreClick(b)
    if K.InCombat() then return end
    local unit, id = PB.Scan()
    if unit then
        b:SetAttribute("type", "spell")
        b:SetAttribute("spell", id)
        b:SetAttribute("unit", unit)
        PB.lastPlan = unit
    else
        b:SetAttribute("type", nil)
        b:SetAttribute("spell", nil)
        b:SetAttribute("unit", nil)
        PB.lastPlan = nil
    end
    PB.Paint()
end

function PB.Text()
    local r = PB.result
    if K.InCombat() then return "Im Kampf" end
    if r.missing == 0 and r.unclear == 0 then return NO_TARGET end
    if r.unclear > 0 and r.missing == 0 then return "unklar: " .. r.unclear end
    return "noch " .. r.missing .. " ohne Segen"
end

function PB.Paint()
    if not frame then return end
    frame.count:SetText(PB.Text())
    if frame.btn.SetEnabled then pcall(frame.btn.SetEnabled, frame.btn, not K.InCombat()) end
end

function PB.Update()
    if not PB.On() then
        if frame and frame:IsShown() then
            if K.InCombat() then K.AfterCombat(PB.Update) return end
            frame:Hide()
        end
        return
    end
    local f = PB.Frame()
    if not f then K.AfterCombat(PB.Update) return end
    if not K.InCombat() then
        PB.Scan()
        -- Alle gesegnet: Rahmen weg (6.100.1.0, Wunsch); kommt wieder,
        -- sobald einer seinen Segen braucht. Im Gestaltungsmodus immer da.
        local r = PB.result
        local done = r and r.missing == 0 and r.unclear == 0
        if done and not f._unlock then
            if f:IsShown() then f:Hide() end
        elseif not f:IsShown() then
            f:Show()
        end
    end
    PB.Paint()
end

--------------------------------------------------
-- Ereignisse
--------------------------------------------------

PB.EVENTS = { "PLAYER_ENTERING_WORLD", "GROUP_ROSTER_UPDATE", "PLAYER_ROLES_ASSIGNED", "UNIT_AURA",
              "UNIT_SPELLCAST_SUCCEEDED", "PLAYER_REGEN_ENABLED", "PLAYER_REGEN_DISABLED",
              "SPELLS_CHANGED", "UNIT_CONNECTION", "INSPECT_READY", "PLAYER_TALENT_UPDATE",
              "CHARACTER_POINTS_CHANGED" }

local queued = false
local function Deferred()
    queued = false
    PB.Update()
end
local function Soon()
    if queued then return end
    local t = _G.C_Timer
    if t and t.After then queued = true t.After(1, Deferred) else PB.Update() end
end
-- Restzeiten laufen ab, ohne dass ein Ereignis kommt: alle 30 s nachsehen.
local function Periodic()
    if not PB.On() then PB.periodic = false return end
    if not K.InCombat() then PB.Update() PB.InspectNext() end
    local t = _G.C_Timer
    if t and t.After then t.After(PB.inspecting and 30 or (_G.next(PB.inspectQ) and 3 or 30), Periodic) end
end

-- Erfolgreich gezaubert: merken (falls die Auren spaeter unlesbar sind).
function PB.OnCast(spellId)
    spellId = K.Plain(spellId)
    if type(spellId) ~= "number" or not PB.lastPlan then return end
    for key, g in pairs(PB.GREATER_OF) do
        for _, id in ipairs(g) do
            if id == spellId and PB.planClass then
                local t = Now()
                for _, unit in ipairs(Units()) do
                    local _, c = Call(_G.UnitClass, unit)
                    local guid = Call(_G.UnitGUID, unit)
                    if c == PB.planClass and type(guid) == "string" then
                        local m = PB.memo[guid] or {}
                        m[key] = t
                        PB.memo[guid] = m
                    end
                end
                return
            end
        end
    end
    for key in pairs(PB.BLESSINGS) do
        for _, id in ipairs(PB.Chain(key)) do
            if id == spellId then
                local guid = Call(_G.UnitGUID, PB.lastPlan)
                if type(guid) == "string" then
                    local m = PB.memo[guid] or {}
                    m[key] = Now()
                    PB.memo[guid] = m
                end
                return
            end
        end
    end
end

local events = CreateFrame("Frame")
events:SetScript("OnEvent", K.Measured("Segen", function(_, event, unit, _, spellId)
    if event == "INSPECT_READY" then PB.OnInspect(unit) Soon() return end
    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        if unit ~= "player" then return end
        PB.OnCast(spellId)
    elseif event == "SPELLS_CHANGED" then
        for k in pairs(names) do names[k] = nil end
    end
    if event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then PB.Update() return end
    Soon()
end))

function PB.Apply()
    events:UnregisterAllEvents()
    if not PB.On() then PB.Update() return end
    for _, e in ipairs(PB.EVENTS) do pcall(events.RegisterEvent, events, e) end
    PB.Update()
    if not PB.periodic then PB.periodic = true Periodic() end
end

--------------------------------------------------
-- Seite im Komfort
--------------------------------------------------

local function Items(withClass)
    local items = {}
    if withClass then items[#items + 1] = { value = "class", text = "Wie die Klasse" } end
    for _, key in ipairs(PB.ORDER) do
        local label = PB.BLESSINGS[key].label
        if PB.IsPaladin() and not PB.Best(key) then label = label .. " (nicht gelernt)" end
        items[#items + 1] = { value = key, text = label }
    end
    items[#items + 1] = { value = "none", text = "Keiner" }
    return items
end

function PB.Status()
    if not PB.IsPaladin() then return "Nur für Paladine." end
    if not PB.On() then return "Aus." end
    return PB.Text()
end

local function Build(B)
    local off = function() return not K.Get(KEY, "blessOn") end
    B:Section("Segen verteilen")
    B:Row({ type = "toggle", label = "Knopf „Buffen“ zeigen", key = "blessOn",
            description = "Jeder Klick segnet das nächste Gruppenmitglied, dem sein Segen fehlt. Nur für Paladine, nur außerhalb des Kampfes." },
          { type = "empty" })
    B:Section("Segen je Klasse und Rolle", "Erst die Klasse wählen, dann je Rolle den Segen. Welche Rolle jemand spielt, liest WeintCodex aus seinen Talenten (andere Spieler werden dafür kurz betrachtet, nur außerhalb des Kampfes), sonst aus der Gruppenrolle.")
    local classItems = {}
    for _, c in ipairs(PB.CLASSES) do classItems[#classItems + 1] = { value = c, text = PB.CLASS_LABEL[c] } end
    B:Row({ type = "dropdown", label = "Klasse", items = classItems,
            get = function() return PB.editClass end,
            set = function(v)
                PB.editClass = v
                local O = WeintCodex.UIOptions
                if O and O.Rebuild then pcall(O.Rebuild) end
            end },
          { type = "empty" })
    local items = Items(false)
    local roles = PB.CLASS_ROLES[PB.editClass] or {}
    for i = 1, #roles, 2 do
        local a, b = roles[i], roles[i + 1]
        B:Row({ type = "dropdown", label = PB.ROLE_LABEL[a], key = "bless_" .. PB.editClass .. "_" .. a, items = items, disabled = off },
              b and { type = "dropdown", label = PB.ROLE_LABEL[b], key = "bless_" .. PB.editClass .. "_" .. b, items = items, disabled = off }
                or { type = "empty" })
    end
    -- Ueberblick aller Klassen in Worten
    local lines = {}
    for _, c in ipairs(PB.CLASSES) do
        local parts = {}
        for _, r in ipairs(PB.CLASS_ROLES[c]) do
            local k = K.Get(KEY, "bless_" .. c .. "_" .. r)
            local lbl = k == "none" and "keiner" or (PB.BLESSINGS[k] and PB.BLESSINGS[k].label or "?")
            parts[#parts + 1] = PB.ROLE_LABEL[r] .. ": " .. lbl
        end
        lines[#lines + 1] = PB.CLASS_LABEL[c] .. " – " .. table.concat(parts, ", ")
    end
    B:Note(table.concat(lines, "\n"))
    B:Row({ type = "toggle", label = "Große Segen nutzen", key = "blessGreater", disabled = off,
            description = "Sollen alle einer Klasse denselben Segen bekommen und kennst du den großen, segnet ein Klick die ganze Klasse." },
          { type = "empty" })
    B:Note("Zur Wahl stehen die 60-Minuten-Segen: Macht, Weisheit, Könige, Licht. "
        .. "Nicht gelernt: dann Macht. Begleiter bekommen keinen Segen.")
    B:Advanced()
    B:Row({ type = "slider", label = "Neu segnen ab Restzeit", key = "blessRefresh", min = 0, max = 30, step = 1,
            format = function(v) return v .. " min" end, disabled = off },
          { type = "empty" })
    B:Note("Rolle: Talentbaum mit den meisten Punkten (Wilder Kampf als Tank nur mit Gruppenrolle Tank), sonst die Gruppenrolle, sonst Schaden. "
        .. "Ein Tank bekommt nie Rettung. Der Knopf heißt " .. PB.BUTTON
        .. " – belegbar unter Tastenbelegung → AddOns.")
    B:EndAdvanced()
    B:Note("Zuletzt: " .. PB.Status())
end

local mod = K.Module(KEY)
if mod then
    for k, v in pairs(PB.DEFAULTS) do
        if mod.defaults[k] == nil then mod.defaults[k] = v end
    end
    mod.pages[#mod.pages + 1] = { key = "segen", label = "Segen", build = Build }
    if type(mod.pageOrder) == "table" then mod.pageOrder.segen = 13.5 end
end

-- Nur fuer Paladine sichtbar (6.102.1.0, Wunsch): beim Einloggen steht die
-- Klasse fest - wer kein Paladin ist, bekommt die Seite gar nicht.
function PB.DropPageIfNotPaladin()
    local m = K.Module(KEY)
    if not m or PB.IsPaladin() then return false end
    for i = #m.pages, 1, -1 do
        if m.pages[i].key == "segen" then table.remove(m.pages, i) end
    end
    m._sortedFor = nil
    return true
end
do
    local login = CreateFrame("Frame")
    login:RegisterEvent("PLAYER_LOGIN")
    login:SetScript("OnEvent", function() PB.DropPageIfNotPaladin() end)
end

_G.BINDING_NAME_CLICK_WeintCodexBlessButton_LeftButton = "Segen verteilen (Paladin)"

K.Listen(function(kind, key)
    if (kind == "active" or kind == "setting") and key == KEY then PB.Apply() end
end)
