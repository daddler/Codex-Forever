--------------------------------------------------
-- WeintCodex :: Oberflaeche - Erinnerungen
--------------------------------------------------
-- Was frueher WeakAuras konnte, soweit der 12.x-Client es noch zulaesst
-- (Beta-Test: "wie damals WeakAuras, heute Reminder"). WeakAuras selbst
-- ist fuer Midnight eingestellt: Bedingungen, Aktionen und Ausloeser
-- lassen sich mit geheimen Werten nicht mehr bauen.
--
-- VIER TEILE, EIN REGELWERK. Jede Regel ist eine kleine Tabelle
-- ({ kind = ..., spell = ... }); was sie tut, haengt an ihrer Art:
--
--   buff      "Kampfschrei fehlt"      - Erinnerung, solange der Buff fehlt
--   weapon    "Waffengift fehlt"       - Waffe ohne Verzauberung / laeuft ab
--   pet       "Begleiter fehlt"        - er war da und ist weg
--   proc      Symbol, solange ein eigener Buff/Proc laeuft
--   cooldown  Symbol mit Abklingzeit einer Faehigkeit
--
-- WAS GEHT UND WAS NICHT. Ausserhalb des Kampfes ist alles lesbar -
-- Erinnerungen sind deshalb zuverlaessig. Im Kampf kann der Client Auren
-- und Abklingzeiten geheim nennen: Symbole und Uhren bekommen den Wert
-- durchgereicht (der Client zeichnet ihn), aber Lua entscheidet nichts
-- danach. Heisst: Erinnerungen ruhen im Kampf (einstellbar), Procs und
-- Abklingzeiten zeigen, was der Client herausgibt - nennt er eine Aura
-- nur geheim, bleibt ihr Symbol aus, statt zu raten.
--
-- KEIN BESTAND OHNE HERKUNFT. Es gibt keine eingebaute Liste von
-- Zauber-IDs - niemand hier hat die Zauber des Forever-Clients gelesen.
-- Zauber nennt der Spieler selbst (Name oder ID); die Vorschlaege fuer
-- eine Klasse kommen ohne Zauber aus (Waffe, Begleiter).
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIReminders = {}

local R = WeintCodex.UIReminders
local K = WeintCodex.UIKit
local C = WeintCodex.Colors
local KEY = "reminders"

local defaults = {
    showReminders = true,
    showProcs     = true,
    showCooldowns = true,
    remindInCombat = false,   -- Erinnerungen auch im Kampf (wenn lesbar)
    where         = "all",    -- all | group | instance
    iconSize      = 36,       -- Procs
    cdSize        = 32,       -- Abklingzeiten
    weaponMinutes = 5,        -- "laeuft ab" ab so vielen Minuten Rest
    rules         = nil,      -- nil: Vorschlaege der Klasse
}
R.DEFAULTS = defaults

local function Opt(k) return K.Get(KEY, k) end

--------------------------------------------------
-- Regeln
--------------------------------------------------

R.KINDS = {
    { value = "buff",     text = "Buff fehlt" },
    { value = "weapon",   text = "Waffe ohne Verzauberung" },
    { value = "pet",      text = "Begleiter fehlt" },
    { value = "proc",     text = "Buff/Proc anzeigen" },
    { value = "cooldown", text = "Abklingzeit anzeigen" },
}
local KIND_TEXT = {}
for _, k in ipairs(R.KINDS) do KIND_TEXT[k.value] = k.text end
R.KIND_TEXT = KIND_TEXT

-- Braucht die Art einen Zauber?
function R.NeedsSpell(kind)
    return kind == "buff" or kind == "proc" or kind == "cooldown"
end

local function PlayerClass()
    local _, class = _G.UnitClass and _G.UnitClass("player")
    return K.Plain(class)
end

-- Vorschlaege je Klasse - nur, was ohne Zauber-ID geht.
function R.Suggestions(class)
    class = class or PlayerClass()
    if class == "ROGUE" then
        return { { kind = "weapon", hand = "main" }, { kind = "weapon", hand = "off" } }
    elseif class == "SHAMAN" then
        return { { kind = "weapon", hand = "main" } }
    elseif class == "HUNTER" or class == "WARLOCK" then
        return { { kind = "pet" } }
    end
    return {}
end

function R.Rules()
    local r = Opt("rules")
    if type(r) == "table" then return r end
    return R.Suggestions()
end

local function CopyRules(list)
    local out = {}
    for i, rule in ipairs(list) do
        local c = {}
        for k, v in pairs(rule) do c[k] = v end
        out[i] = c
    end
    return out
end

function R.SetRules(list) K.Set(KEY, "rules", CopyRules(list)) end

function R.AddRule(rule)
    local list = CopyRules(R.Rules())
    list[#list + 1] = rule
    R.SetRules(list)
end

function R.RemoveRule(i)
    local list = CopyRules(R.Rules())
    table.remove(list, i)
    R.SetRules(list)
end

--------------------------------------------------
-- Zauber: Name oder ID -> { id, name, icon }
--------------------------------------------------

function R.Resolve(text)
    if type(text) ~= "string" or text == "" then return nil end
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    local key = text:match("^%d+$") and (text + 0) or text
    local ok, info = pcall(function()
        if _G.C_Spell and _G.C_Spell.GetSpellInfo then return _G.C_Spell.GetSpellInfo(key) end
        if _G.GetSpellInfo then
            local name, _, icon, _, _, _, id = _G.GetSpellInfo(key)
            if name then return { name = name, iconID = icon, spellID = id } end
        end
        return nil
    end)
    if not ok or type(info) ~= "table" then
        -- Unbekannt: der eingegebene Name bleibt, als Name einer Aura
        -- (Buffs heissen oft wie ihr Zauber, sind aber nicht immer einer).
        return { name = type(key) == "string" and key or nil, id = type(key) == "number" and key or nil }
    end
    return { id = K.Plain(info.spellID) or (type(key) == "number" and key or nil),
             name = K.Plain(info.name) or text, icon = K.Plain(info.iconID) }
end

--------------------------------------------------
-- Was der Client sagt
--------------------------------------------------

-- Die Aura einer Regel am Spieler: Tabelle, false (sicher nicht da) oder
-- nil (der Client sagt es nicht - geheim oder Fehler).
function R.PlayerAura(rule)
    local sp = R.Resolve(rule.spell)
    if not sp then return nil end
    local ua = _G.C_UnitAuras
    -- Ohne eine Moeglichkeit zu fragen: "weiss nicht", nie "fehlt".
    local canAsk = (ua and (ua.GetPlayerAuraBySpellID or ua.GetAuraDataBySpellName))
        or (_G.AuraUtil and _G.AuraUtil.FindAuraByName)
    if not canAsk then return nil end
    local ok, aura = pcall(function()
        if ua and sp.id and ua.GetPlayerAuraBySpellID then
            local a = ua.GetPlayerAuraBySpellID(sp.id)
            if a then return a end
        end
        -- Nach Namen: der eingegebene Text, dann der aufgeloeste Name.
        if ua and ua.GetAuraDataBySpellName then
            for _, n in ipairs({ rule.spell, sp.name }) do
                if type(n) == "string" then
                    local a = ua.GetAuraDataBySpellName("player", n, "HELPFUL")
                    if a then return a end
                end
            end
        elseif _G.AuraUtil and _G.AuraUtil.FindAuraByName and sp.name then
            local name, icon, count, _, duration, expires = _G.AuraUtil.FindAuraByName(sp.name, "player", "HELPFUL")
            if name then return { icon = icon, applications = count, duration = duration, expirationTime = expires } end
        end
        return false
    end)
    if not ok or K.IsSecret(aura) then return nil end
    return aura
end

local function InGroup()
    return K.Bool(_G.IsInGroup and _G.IsInGroup(), false) or K.Bool(_G.IsInRaid and _G.IsInRaid(), false)
end

local function InInstance()
    if not _G.IsInInstance then return false end
    local _, kind = _G.IsInInstance()
    kind = K.Plain(kind)
    return type(kind) == "string" and kind ~= "none"
end

local petSeen = false
R._petSeen = function(v) if v ~= nil then petSeen = v end return petSeen end

local function WeaponText(hand)
    return hand == "off" and "Nebenhand" or "Haupthand"
end

-- Traegt die Hand eine Waffe (keinen Schild, kein Nebenhand-Buch)?
local function HasWeapon(hand)
    local slot = hand == "off" and 17 or 16
    local id = _G.GetInventoryItemID and K.Plain(_G.GetInventoryItemID("player", slot))
    if not id then return false end
    local info = _G.C_Item and _G.C_Item.GetItemInfoInstant or _G.GetItemInfoInstant
    if not info then return true end
    local ok, _, _, _, _, _, classID = pcall(info, id)
    if not ok then return true end
    classID = K.Plain(classID)
    return classID == nil or classID == 2   -- 2 = Waffe
end

-- Eine Erinnerung: { text, icon } oder nil.
function R.Check(rule)
    local kind = rule.kind
    if kind == "buff" then
        local aura = R.PlayerAura(rule)
        if aura == false then
            local sp = R.Resolve(rule.spell) or {}
            return { text = (sp.name or rule.spell or "?") .. " fehlt", icon = sp.icon }
        end
        return nil
    elseif kind == "weapon" then
        if not _G.GetWeaponEnchantInfo or not HasWeapon(rule.hand) then return nil end
        local ok, hasMain, mainExp, _, _, hasOff, offExp = pcall(_G.GetWeaponEnchantInfo)
        if not ok then return nil end
        local has, exp
        if rule.hand == "off" then has, exp = K.Plain(hasOff), K.Plain(offExp)
        else has, exp = K.Plain(hasMain), K.Plain(mainExp) end
        if has == nil then return nil end
        if not has then return { text = "Waffe (" .. WeaponText(rule.hand) .. ") ohne Verzauberung" } end
        local limit = (Opt("weaponMinutes") or 5) * 60000
        if type(exp) == "number" and exp < limit then
            return { text = string.format("Waffe (%s): noch %d min", WeaponText(rule.hand), math.max(1, math.floor(exp / 60000 + 0.5))) }
        end
        return nil
    elseif kind == "pet" then
        local has = K.Bool(_G.UnitExists and _G.UnitExists("pet"), true)
        if has then petSeen = true return nil end
        if not petSeen then return nil end
        if K.Bool(_G.IsMounted and _G.IsMounted(), false) or K.Bool(_G.UnitOnTaxi and _G.UnitOnTaxi("player"), false)
           or K.Bool(_G.UnitIsDeadOrGhost and _G.UnitIsDeadOrGhost("player"), false) then
            return nil
        end
        return { text = "Begleiter fehlt" }
    end
    return nil
end

-- Alle Erinnerungen, die jetzt gelten.
function R.Active()
    local out = {}
    if not Opt("showReminders") then return out end
    if K.InCombat() and not Opt("remindInCombat") then return out end
    local where = Opt("where")
    if where == "group" and not InGroup() then return out end
    if where == "instance" and not InInstance() then return out end
    for _, rule in ipairs(R.Rules()) do
        if rule.kind == "buff" or rule.kind == "weapon" or rule.kind == "pet" then
            local hit = R.Check(rule)
            if hit then out[#out + 1] = hit end
        end
    end
    return out
end

--------------------------------------------------
-- Anzeige: Erinnerungen
--------------------------------------------------

local MAX_LINES = 6
local banner

local function BuildBanner()
    banner = CreateFrame("Frame", "WeintCodexReminders", UIParent)
    banner:SetSize(260, 30)
    banner:SetFrameStrata("MEDIUM")
    banner.kachel = K.Kachel(banner, { shadow = 6 })
    local a = C.warning or C.accent
    banner.strip = banner:CreateTexture(nil, "ARTWORK")
    banner.strip:SetPoint("TOPLEFT", banner, "TOPLEFT", 0, 0)
    banner.strip:SetPoint("BOTTOMLEFT", banner, "BOTTOMLEFT", 0, 0)
    banner.strip:SetWidth(3)
    banner.strip:SetColorTexture(a[1], a[2], a[3], 1)
    banner.lines = {}
    for i = 1, MAX_LINES do
        local icon = banner:CreateTexture(nil, "ARTWORK")
        icon:SetSize(18, 18)
        icon:SetPoint("TOPLEFT", banner, "TOPLEFT", 10, -8 - (i - 1) * 24)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        local text = K.NewText(banner, 13)
        text:SetPoint("LEFT", icon, "RIGHT", 8, 0)
        text:SetJustifyH("LEFT")
        banner.lines[i] = { icon = icon, text = text }
    end
    banner:Hide()
    banner.WCShowForUnlock = function(self, on)
        self._unlock = on and true or nil
        R.UpdateBanner()
    end
end

function R.UpdateBanner()
    if not banner then return end
    local list = banner._unlock and { { text = "Kampfschrei fehlt" }, { text = "Waffe (Haupthand) ohne Verzauberung" } }
        or R.Active()
    local n = math.min(#list, MAX_LINES)
    local widest = 0
    for i = 1, MAX_LINES do
        local line, item = banner.lines[i], list[i]
        if i <= n then
            line.text:SetText(item.text)
            line.text:Show()
            if item.icon then line.icon:SetTexture(item.icon) line.icon:Show() else line.icon:Hide() end
            local w = K.Plain(line.text:GetStringWidth())
            if type(w) == "number" and w > widest then widest = w end
        else
            line.text:Hide()
            line.icon:Hide()
        end
    end
    if n == 0 then banner:Hide() return end
    banner:SetSize(math.max(200, widest + 46), n * 24 + 12)
    banner:Show()
end
R.Banner = function() return banner end

--------------------------------------------------
-- Anzeige: Procs und Abklingzeiten
--------------------------------------------------

local procRow, cdRow

local function Icon(parent)
    local b = CreateFrame("Frame", nil, parent)
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetAllPoints(b)
    b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    b.cd = CreateFrame("Cooldown", nil, b, "CooldownFrameTemplate")
    b.cd:SetAllPoints(b)
    if b.cd.SetDrawEdge then b.cd:SetDrawEdge(false) end
    local top = CreateFrame("Frame", nil, b)
    top:SetAllPoints(b)
    top:SetFrameLevel((b.cd:GetFrameLevel() or 1) + 2)
    K.Border(top, 1, 0, 0, 0, 1, "OVERLAY")
    b.count = K.NewText(top, 12)
    b.count:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -1, 2)
    b.shadow = K.Glow(b, { spread = 4, shadow = true })
    b:Hide()
    return b
end

local function Row(name)
    local f = CreateFrame("Frame", name, UIParent)
    f:SetSize(200, 36)
    f.icons = {}
    return f
end

-- Reihe mittig anordnen: n Symbole der Groesse s.
local function Arrange(row, n, s)
    local gap = 4
    local total = math.max(1, n * s + (n - 1) * gap)
    row:SetSize(total, s)
    for i = 1, n do
        local b = row.icons[i]
        b:SetSize(s, s)
        b:ClearAllPoints()
        b:SetPoint("LEFT", row, "LEFT", (i - 1) * (s + gap), 0)
    end
end

local function EnsureIcons(row, n)
    for i = #row.icons + 1, n do row.icons[i] = Icon(row) end
end

-- Laufzeit einer Aura an die Uhr - als Dauerobjekt, sonst offen
-- gerechnet, sonst gar nicht.
local function AuraClock(b, aura)
    local ua = _G.C_UnitAuras
    if aura.auraInstanceID and ua and ua.GetAuraDuration and b.cd.SetCooldownFromDurationObject then
        local ok, dur = pcall(ua.GetAuraDuration, "player", aura.auraInstanceID)
        if ok and dur and pcall(b.cd.SetCooldownFromDurationObject, b.cd, dur) then return end
    end
    local d, e = K.Plain(aura.duration), K.Plain(aura.expirationTime)
    if type(d) == "number" and type(e) == "number" and d > 0 then
        b.cd:SetCooldown(e - d, d)
    else
        b.cd:Clear()
    end
end

function R.UpdateProcs()
    if not procRow then return end
    local shown = {}
    if Opt("showProcs") then
        for _, rule in ipairs(R.Rules()) do
            if rule.kind == "proc" then
                local aura = procRow._unlock and { icon = 136116 } or R.PlayerAura(rule)
                if type(aura) == "table" then shown[#shown + 1] = { rule = rule, aura = aura } end
            end
        end
    end
    EnsureIcons(procRow, #shown)
    local s = Opt("iconSize") or 36
    Arrange(procRow, #shown, s)
    for i, b in ipairs(procRow.icons) do
        local it = shown[i]
        if it then
            local sp = R.Resolve(it.rule.spell) or {}
            b.icon:SetTexture(it.aura.icon or sp.icon)
            -- Stapel: geheim oder offen - SetText darf beides.
            local stacks = it.aura.applications
            local plain = K.Plain(stacks)
            if K.IsSecret(stacks) or (type(plain) == "number" and plain > 1) then b.count:SetText(stacks) else b.count:SetText("") end
            AuraClock(b, it.aura)
            b:Show()
        else
            b:Hide()
        end
    end
    procRow:SetShown(#shown > 0)
end

-- Abklingzeit einer Faehigkeit an die Uhr. Der globale Abklingzeitblitz
-- bleibt draussen, wo der Client ihn offen nennt.
local function SpellClock(b, id)
    local cs = _G.C_Spell
    if cs and cs.GetSpellCooldownDuration and b.cd.SetCooldownFromDurationObject then
        local ok, dur = pcall(cs.GetSpellCooldownDuration, id)
        if ok and dur and pcall(b.cd.SetCooldownFromDurationObject, b.cd, dur) then return end
    end
    local ok, start, duration, onGCD = pcall(function()
        if cs and cs.GetSpellCooldown then
            local info = cs.GetSpellCooldown(id)
            if type(info) == "table" then return info.startTime, info.duration, info.isOnGCD end
            return nil
        end
        if _G.GetSpellCooldown then return _G.GetSpellCooldown(id) end
        return nil
    end)
    if not ok or type(start) == "nil" or type(duration) == "nil" then b.cd:Clear() return end
    if K.Bool(onGCD, false) then b.cd:Clear() return end
    -- Offen und 0: bereit. Geheim: der Client zeichnet es selbst.
    local d = K.Plain(duration)
    if type(d) == "number" and d <= 0 then b.cd:Clear() return end
    pcall(b.cd.SetCooldown, b.cd, start, duration)
end

function R.UpdateCooldowns()
    if not cdRow then return end
    local list = {}
    if Opt("showCooldowns") then
        for _, rule in ipairs(R.Rules()) do
            if rule.kind == "cooldown" then
                local sp = R.Resolve(rule.spell)
                if sp and sp.id then list[#list + 1] = sp end
            end
        end
    end
    EnsureIcons(cdRow, #list)
    Arrange(cdRow, #list, Opt("cdSize") or 32)
    for i, b in ipairs(cdRow.icons) do
        local sp = list[i]
        if sp then
            b.icon:SetTexture(sp.icon)
            b.count:SetText("")
            SpellClock(b, sp.id)
            b:Show()
        else
            b:Hide()
        end
    end
    cdRow:SetShown(#list > 0)
end

R.Rows = function() return procRow, cdRow end

function R.UpdateAll()
    R.UpdateBanner()
    R.UpdateProcs()
    R.UpdateCooldowns()
end

--------------------------------------------------
-- Aufbau
--------------------------------------------------

local function Enable()
    BuildBanner()
    procRow = Row("WeintCodexProcs")
    cdRow = Row("WeintCodexCooldowns")
    procRow.WCShowForUnlock = function(self, on) self._unlock = on and true or nil R.UpdateProcs() end
    K.RegisterMover(banner, "reminders", "Erinnerungen", K.Layout("reminders"))
    K.RegisterMover(procRow, "procs", "Buffs und Procs", K.Layout("procs"))
    K.RegisterMover(cdRow, "cooldowns", "Abklingzeiten", K.Layout("cooldowns"))

    local ev = CreateFrame("Frame")
    for _, e in ipairs({ "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_ENABLED", "PLAYER_REGEN_DISABLED",
        "UNIT_AURA", "UNIT_PET", "UNIT_INVENTORY_CHANGED", "GROUP_ROSTER_UPDATE", "ZONE_CHANGED_NEW_AREA",
        "SPELL_UPDATE_COOLDOWN", "SPELL_UPDATE_CHARGES", "READY_CHECK", "PLAYER_MOUNT_DISPLAY_CHANGED" }) do
        pcall(ev.RegisterEvent, ev, e)
    end
    ev:SetScript("OnEvent", function(_, event, unit)
        if event == "UNIT_AURA" or event == "UNIT_INVENTORY_CHANGED" or event == "UNIT_PET" then
            if unit ~= "player" then return end
        end
        if event == "SPELL_UPDATE_COOLDOWN" or event == "SPELL_UPDATE_CHARGES" then
            R.UpdateCooldowns()
            return
        end
        if event == "UNIT_AURA" then R.UpdateProcs() end
        R.UpdateBanner()
        if event == "PLAYER_ENTERING_WORLD" then R.UpdateCooldowns() R.UpdateProcs() end
    end)
    -- Waffenverzauberungen laufen ab, ohne dass ein Ereignis kommt: ein
    -- ruhiger Takt, alle fuenf Sekunden.
    local acc = 0
    ev:SetScript("OnUpdate", function(_, el)
        acc = acc + (el or 0)
        if acc < 5 then return end
        acc = 0
        R.UpdateBanner()
    end)
    R.UpdateAll()
end

--------------------------------------------------
-- Einstellungen
--------------------------------------------------

-- Was im Formular "Regel hinzufuegen" steht (nicht gespeichert).
local draft = { kind = "buff", spell = "", hand = "main" }
R.draft = draft

function R.RuleText(rule)
    local kind = KIND_TEXT[rule.kind] or rule.kind
    if R.NeedsSpell(rule.kind) then
        local sp = R.Resolve(rule.spell)
        local name = sp and sp.name or rule.spell or "?"
        local known = sp and sp.id and "" or "  (unbekannt)"
        return kind .. ": " .. tostring(name) .. known
    elseif rule.kind == "weapon" then
        return kind .. " (" .. WeaponText(rule.hand) .. ")"
    end
    return kind
end

function R.AddDraft()
    local rule = { kind = draft.kind }
    if R.NeedsSpell(draft.kind) then
        local text = (draft.spell or ""):gsub("^%s+", ""):gsub("%s+$", "")
        if text == "" then return false, "Zauber fehlt" end
        rule.spell = text
    elseif draft.kind == "weapon" then
        rule.hand = draft.hand
    end
    R.AddRule(rule)
    draft.spell = ""
    return true
end

-- Die Liste der Regeln im Einstellungsfenster: bis zu acht Zeilen mit
-- Symbol, Beschreibung und einem Knopf zum Entfernen. Mehr passen nicht
-- auf die Seite - die neunte und alle weiteren wirken trotzdem und werden
-- als "... und N weitere" gezaehlt, statt still zu verschwinden.
local LIST_ROWS = 8
function R.BuildRuleList(parent, width)
    local w = CreateFrame("Frame", nil, parent)
    w.rows = {}
    for i = 1, LIST_ROWS do
        local row = CreateFrame("Frame", nil, w)
        row:SetSize(width, 24)
        row:SetPoint("TOPLEFT", w, "TOPLEFT", 0, -(i - 1) * 26)
        row.bg = row:CreateTexture(nil, "BACKGROUND")
        row.bg:SetAllPoints(row)
        local s = C.surface1
        row.bg:SetColorTexture(s[1], s[2], s[3], 0.6)
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(18, 18)
        row.icon:SetPoint("LEFT", row, "LEFT", 4, 0)
        row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        row.text = K.NewText(row, 12)
        row.text:SetPoint("LEFT", row.icon, "RIGHT", 8, 0)
        row.text:SetPoint("RIGHT", row, "RIGHT", -96, 0)
        row.text:SetJustifyH("LEFT")
        row.text:SetWordWrap(false)
        local idx = i
        row.remove = WeintCodex.CreateButton(row, { text = "Entfernen", kind = "secondary", height = 20, size = 10,
            onClick = function() R.RemoveRule(idx) end })
        row.remove:SetPoint("RIGHT", row, "RIGHT", -2, 0)
        w.rows[i] = row
    end
    w.more = K.NewText(w, 11)
    w.more:SetPoint("TOPLEFT", w, "TOPLEFT", 4, -LIST_ROWS * 26)
    w.empty = K.NewText(w, 12)
    w.empty:SetPoint("TOPLEFT", w, "TOPLEFT", 4, -6)
    w.empty:SetText("Noch keine Regel. Unten eine anlegen – oder „Für meine Klasse“.")
    w.empty:SetTextColor(unpack(C.textDim))
    w.Sync = function()
        local rules = R.Rules()
        for i, row in ipairs(w.rows) do
            local rule = rules[i]
            if rule then
                row.text:SetText(R.RuleText(rule))
                local sp = R.NeedsSpell(rule.kind) and R.Resolve(rule.spell)
                if sp and sp.icon then row.icon:SetTexture(sp.icon) row.icon:Show() else row.icon:Hide() end
                row:Show()
            else
                row:Hide()
            end
        end
        local extra = #rules - LIST_ROWS
        w.more:SetText(extra > 0 and ("… und " .. extra .. " weitere") or "")
        w.empty:SetShown(#rules == 0)
    end
    return w
end

-- Aenderungen am Formular (nicht gespeichert) sollen gesperrte Felder
-- nachziehen: dasselbe Signal wie eine Einstellung.
local function DraftChanged() K.Fire("setting", KEY, "draft") end

local function px(v) return string.format("%d px", v) end

K.Register({
    key = KEY, group = "ui", order = 58,
    title = "Erinnerungen",
    description = "Fehlende Buffs, Waffenverzauberung und Begleiter vor dem Kampf; eigene Buffs, Procs und Abklingzeiten als Symbole – so weit der Client sie herausgibt.",
    defaults = defaults,
    Enable = Enable,
    OnSetting = function() R.UpdateAll() end,
    pages = {
        { key = "regeln", label = "Regeln", build = function(B)
            B:Section("Deine Regeln", "Jede Regel ist eine Erinnerung oder ein Symbol. Zauber nennst du mit Namen oder ID – eine eingebaute Liste gibt es nicht.")
            B:Row({ type = "custom", height = 8 * 26 + 6, create = function(parent, width)
                        return R.BuildRuleList(parent, width)
                    end }, nil)
            B:Section("Neue Regel")
            B:Row({ type = "dropdown", label = "Art", items = R.KINDS,
                    get = function() return draft.kind end, set = function(v) draft.kind = v DraftChanged() end },
                  { type = "input", label = "Zauber (Name oder ID)",
                    get = function() return draft.spell end, set = function(v) draft.spell = v end,
                    disabled = function() return not R.NeedsSpell(draft.kind) end })
            B:Row({ type = "dropdown", label = "Hand (bei Waffe)", items = {
                        { value = "main", text = "Haupthand" }, { value = "off", text = "Nebenhand" } },
                    get = function() return draft.hand end, set = function(v) draft.hand = v DraftChanged() end,
                    disabled = function() return draft.kind ~= "weapon" end },
                  { type = "button", label = "Hinzufügen", text = "Regel hinzufügen",
                    onClick = function() R.AddDraft() end })
            B:Row({ type = "button", label = "Vorschläge", text = "Für meine Klasse",
                    tooltip = "Ersetzt die Regeln durch die Vorschläge für deine Klasse (Waffe, Begleiter).",
                    onClick = function() R.SetRules(R.Suggestions()) end },
                  { type = "empty" })
        end },
        { key = "anzeige", label = "Anzeige", build = function(B)
            B:Section("Erinnerungen")
            B:Row({ type = "toggle", label = "Erinnerungen zeigen", key = "showReminders" },
                  { type = "dropdown", label = "Wo", key = "where", items = {
                        { value = "all",      text = "Überall" },
                        { value = "group",    text = "Nur in einer Gruppe" },
                        { value = "instance", text = "Nur in Dungeons und Schlachtzügen" } } })
            B:Row({ type = "toggle", label = "Auch im Kampf", key = "remindInCombat",
                    description = "Im Kampf nennt der Client Buffs oft nur verschlüsselt – dann bleibt die Erinnerung aus, statt zu raten." },
                  { type = "slider", label = "Waffe: erinnern ab", key = "weaponMinutes", min = 1, max = 30, step = 1,
                    format = function(v) return string.format("%d min Rest", v) end })
            B:Section("Symbole")
            B:Row({ type = "toggle", label = "Buffs und Procs", key = "showProcs" },
                  { type = "slider", label = "Größe", key = "iconSize", min = 20, max = 64, step = 2, format = px })
            B:Row({ type = "toggle", label = "Abklingzeiten", key = "showCooldowns" },
                  { type = "slider", label = "Größe", key = "cdSize", min = 20, max = 56, step = 2, format = px })
            B:Note("Verschieben im Gestaltungsmodus. Im Kampf zeigen Symbole und Uhren, was der Client herausgibt; nennt er eine Aura nur verschlüsselt, bleibt ihr Symbol aus.")
        end },
    },
})
