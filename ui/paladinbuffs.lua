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
PB.ORDER = { "might", "wisdom", "kings", "salvation", "light", "sanctuary" }
PB.BLESSINGS = {
    might     = { root = 19740, label = "Macht" },
    wisdom    = { root = 19742, label = "Weisheit" },
    kings     = { root = 20217, label = "Könige" },
    salvation = { root = 1038,  label = "Rettung" },
    light     = { root = 19977, label = "Licht" },
    sanctuary = { root = 20911, label = "Refugium" },
}
-- Grosse Segen aus Classic - auf Forever nicht vorhanden, nie verwendet.
PB.GREATER = { [25782] = true, [25916] = true, [25894] = true, [25918] = true,
               [25898] = true, [25895] = true, [25890] = true, [25899] = true }

PB.CLASSES = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID" }
PB.CLASS_LABEL = { WARRIOR = "Krieger", PALADIN = "Paladin", HUNTER = "Jäger", ROGUE = "Schurke",
                   PRIEST = "Priester", SHAMAN = "Schamane", MAGE = "Magier", WARLOCK = "Hexenmeister",
                   DRUID = "Druide" }
PB.ROLES = { "TANK", "HEALER", "DAMAGER" }
PB.ROLE_LABEL = { TANK = "Tank", HEALER = "Heiler", DAMAGER = "Schaden" }

-- Voreinstellung: Nahkampf Macht, Zauberer und Jaeger (Macht wirkt in
-- Classic nur auf Nahkampf-Angriffskraft) Weisheit; Tank Koenige, Heiler
-- Weisheit, Schaden wie die Klasse. Rettung nie fuer Tanks (PB.Want).
PB.DEFAULTS = {
    blessOn = false,
    blessRefresh = 5,                -- Minuten Restzeit, ab der neu gesegnet wird
    bless_WARRIOR = "might", bless_ROGUE = "might", bless_PALADIN = "might",
    bless_HUNTER = "wisdom", bless_SHAMAN = "wisdom", bless_DRUID = "wisdom",
    bless_PRIEST = "wisdom", bless_MAGE = "wisdom", bless_WARLOCK = "wisdom",
    blessRole_TANK = "kings", blessRole_HEALER = "wisdom", blessRole_DAMAGER = "class",
}

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

local function Role(unit)
    local r = Call(_G.UnitGroupRolesAssigned, unit)
    if r == "TANK" or r == "HEALER" or r == "DAMAGER" then return r end
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
            elseif n == name then
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
            local key, id = PB.Want(class, Role(unit))
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
                            if not fU then fU, fI, fK = unit, id, key end
                        else
                            res.away = res.away + 1
                        end
                    end
                end
            end
        end
    end
    if fU then return fU, fI, fK end
    return uU, uI, uK
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
        if not f:IsShown() then f:Show() end
    end
    PB.Paint()
end

--------------------------------------------------
-- Ereignisse
--------------------------------------------------

PB.EVENTS = { "PLAYER_ENTERING_WORLD", "GROUP_ROSTER_UPDATE", "PLAYER_ROLES_ASSIGNED", "UNIT_AURA",
              "UNIT_SPELLCAST_SUCCEEDED", "PLAYER_REGEN_ENABLED", "PLAYER_REGEN_DISABLED",
              "SPELLS_CHANGED", "UNIT_CONNECTION" }

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
    if not K.InCombat() then PB.Update() end
    local t = _G.C_Timer
    if t and t.After then t.After(30, Periodic) end
end

-- Erfolgreich gezaubert: merken (falls die Auren spaeter unlesbar sind).
function PB.OnCast(spellId)
    spellId = K.Plain(spellId)
    if type(spellId) ~= "number" or not PB.lastPlan then return end
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
    B:Section("Segen je Klasse")
    local items = Items(false)
    for i = 1, #PB.CLASSES, 2 do
        local a, b = PB.CLASSES[i], PB.CLASSES[i + 1]
        B:Row({ type = "dropdown", label = PB.CLASS_LABEL[a], key = "bless_" .. a, items = items, disabled = off },
              b and { type = "dropdown", label = PB.CLASS_LABEL[b], key = "bless_" .. b, items = items, disabled = off }
                or { type = "empty" })
    end
    B:Note("Großen Segen gibt es auf Forever nicht – gesegnet wird jeder einzeln, jeder Segen hält 60 Minuten. "
        .. "Nicht gelernt: dann der Segen der Klasse, sonst Macht. Begleiter bekommen keinen Segen.")
    B:Advanced()
    B:Section("Vorrang nach Rolle")
    local roleItems = Items(true)
    B:Row({ type = "dropdown", label = "Tank", key = "blessRole_TANK", items = roleItems, disabled = off },
          { type = "dropdown", label = "Heiler", key = "blessRole_HEALER", items = roleItems, disabled = off })
    B:Row({ type = "dropdown", label = "Schaden", key = "blessRole_DAMAGER", items = roleItems, disabled = off },
          { type = "slider", label = "Neu segnen ab Restzeit", key = "blessRefresh", min = 0, max = 30, step = 1,
            format = function(v) return v .. " min" end, disabled = off })
    B:Note("Die Rolle kommt vom Spiel (Suche nach Gruppe, Rollenwahl) – ohne Rolle gilt die Klasse. "
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

_G.BINDING_NAME_CLICK_WeintCodexBlessButton_LeftButton = "Segen verteilen (Paladin)"

K.Listen(function(kind, key)
    if (kind == "active" or kind == "setting") and key == KEY then PB.Apply() end
end)
