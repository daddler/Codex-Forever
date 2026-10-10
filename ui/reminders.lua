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
--   happy     "Begleiter unglücklich"  - Laune des Jaegerbegleiters unter
--                                        der Schwelle (6.13.1.0)
--   proc      Symbol, solange ein eigener Buff/Proc laeuft
--   cooldown  Symbol mit Abklingzeit einer Faehigkeit
--   ammo      "Munition knapp"         - angelegte Munition unter der Menge
--   item      "Vorrat knapp"           - ein Gegenstand unter der Menge
--
-- WAS GEHT UND WAS NICHT. Ausserhalb des Kampfes ist alles lesbar -
-- Erinnerungen sind deshalb zuverlaessig. Im Kampf kann der Client Auren
-- und Abklingzeiten geheim nennen: Symbole und Uhren bekommen den Wert
-- durchgereicht (der Client zeichnet ihn), aber Lua entscheidet nichts
-- danach. Heisst: Erinnerungen ruhen im Kampf (einstellbar), Procs und
-- Abklingzeiten zeigen, was der Client herausgibt - nennt er eine Aura
-- nur geheim, bleibt ihr Symbol aus, statt zu raten.
--
-- KEIN BESTAND OHNE HERKUNFT. Bis 6.26.12.0 gab es keine eingebaute Liste
-- von Zauber-IDs. Seit 6.26.13.0 (Beta-Test: "fuer alle Klassen
-- vernuenftige Reminder") schlaegt jede Klasse ihre Dauerbuffs vor
-- (R.CLASS_BUFFS) - IDs aus Classic, dieselben wie im Lehrerbestand
-- (data/trainer.lua, Art `classic`). Sie gelten nur, wenn der Client sagt,
-- dass der Charakter einen davon gelernt hat (`learned`); kennt der Client
-- die ID nicht, gilt die Regel nicht - nie eine geratene Erinnerung.
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
    -- 6.27.0.0 (Beta-Test: "Essensbuff 5 % EP in der Levelphase ... items in
    -- der Tasche scannen, die einen nuetzlichen Buff haben"):
    bagFood       = true,     -- Essen mit Buff in der Tasche, Buff fehlt
    bagElixir     = false,    -- Elixiere, Flaeschchen, Rollen in der Tasche
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
    { value = "happy",    text = "Begleiter nicht glücklich" },
    { value = "proc",     text = "Buff/Proc anzeigen" },
    { value = "cooldown", text = "Abklingzeit anzeigen" },
    { value = "ammo",     text = "Munition knapp" },
    { value = "item",     text = "Vorrat knapp (Gegenstand)" },
}
local KIND_TEXT = {}
for _, k in ipairs(R.KINDS) do KIND_TEXT[k.value] = k.text end
R.KIND_TEXT = KIND_TEXT

-- Braucht die Art einen Zauber?
function R.NeedsSpell(kind)
    return kind == "buff" or kind == "proc" or kind == "cooldown"
end

-- Braucht die Art einen Gegenstand / eine Mindestmenge? (6.6.0.6)
function R.NeedsItem(kind) return kind == "item" end
function R.NeedsAmount(kind) return kind == "ammo" or kind == "item" end
-- Ohne Angabe: ein Stapel Pfeile/Kugeln (200), bei Vorrat "gar keiner mehr".
R.DEFAULT_MIN = { ammo = 200, item = 1 }

-- Laune des Begleiters (6.13.1.0, Beta-Test als Jaeger: "sehen, wie
-- gluecklich mein Pet ist ... am besten als Reminder"). `below`: erinnern,
-- solange die Laune darunter liegt - 3 "nicht gluecklich" (Standard),
-- 2 "ungluecklich". Die Laune selbst: UIKit.PetHappiness.
R.HAPPY_BELOW = {
    { value = 3, text = "nicht glücklich" },
    { value = 2, text = "unglücklich" },
}
R.DEFAULT_BELOW = 3
local function Below(rule)
    local b = tonumber(rule.below)
    return (b == 2 or b == 3) and b or R.DEFAULT_BELOW
end

local function PlayerClass()
    -- Nicht `_G.UnitClass and _G.UnitClass(...)`: das `and` kappt auf EINEN
    -- Rueckgabewert, die Klasse (der zweite) kam nie an.
    if not _G.UnitClass then return nil end
    local _, class = _G.UnitClass("player")
    return K.Plain(class)
end

-- Dauerbuffs je Klasse (6.26.13.0). `any`: einer davon genuegt (Raenge
-- heissen gleich - die Aura wird auch ueber den Namen gefunden; bei
-- Ruestungen, Aspekten, Segen und Auren zaehlt jede der Reihe). `label`:
-- der Text der Erinnerung, wenn es mehrere gibt. Krieger und Schurke haben
-- keinen Buff, den man ausserhalb des Kampfes halten koennte (Schlachtruf
-- kostet Wut) - sie bekommen nur, was ohne Zauber geht.
R.CLASS_BUFFS = {
    MAGE    = { { any = { 1459 } },
                { any = { 6117, 7302, 168 }, label = "Rüstung (Frost, Eis oder Magie)" } },
    PRIEST  = { { any = { 1243 } }, { any = { 588 } } },
    DRUID   = { { any = { 1126 } } },
    PALADIN = { { any = { 19740, 19742, 20217, 1038, 19977 }, label = "Segen" },
                { any = { 465, 7294, 19746, 19876, 19888, 19891 }, label = "Aura" } },
    WARLOCK = { { any = { 706, 687 }, label = "Dämonenrüstung oder Dämonenhaut" } },
    HUNTER  = { { any = { 13165, 13163, 5118, 13159, 20043, 13161 }, label = "Aspekt" } },
    SHAMAN  = { { any = { 324 } } },
}

-- Vorschlaege je Klasse.
function R.Suggestions(class)
    class = class or PlayerClass()
    local out = {}
    if class == "ROGUE" then
        out = { { kind = "weapon", hand = "main" }, { kind = "weapon", hand = "off" } }
    elseif class == "SHAMAN" then
        out = { { kind = "weapon", hand = "main" } }
    elseif class == "HUNTER" then
        out = { { kind = "pet" }, { kind = "ammo", min = R.DEFAULT_MIN.ammo },
                { kind = "happy", below = R.DEFAULT_BELOW } }
    elseif class == "WARLOCK" then
        out = { { kind = "pet" } }
    end
    for _, b in ipairs(R.CLASS_BUFFS[class] or {}) do
        local any = {}
        for i, id in ipairs(b.any) do any[i] = tostring(id) end
        out[#out + 1] = { kind = "buff", spell = any[1], any = any, label = b.label, learned = true }
    end
    for _, r in ipairs(out) do r.class = class end
    return out
end

--------------------------------------------------
-- Fuer wen gilt eine Regel?
--------------------------------------------------
-- 6.6.0.5, Beta-Test: "Ich habe auf meinen Jaeger eingeloggt und bekomme
-- weiterhin den Reminder, meinen Schlachtruf zu setzen." Die Einstellungen
-- gelten fuer den ganzen Account - eine Regel des Kriegers erinnerte also
-- jeden Twink. Seitdem traegt jede neue Regel die Klasse, auf der sie
-- angelegt wurde (`class`), oder R.ALL ("alle Klassen", etwa fuer einen
-- Buff, den andere geben).
--
-- Regeln von vorher haben keine Klasse. Fuer sie entscheidet, was der
-- Client sagt: ein Zauber gilt, wenn der Charakter ihn kennt; einer, den
-- er nicht kennt (oder der sich nicht einmal aufloesen laesst - Namen
-- loest der Client nur fuer bekannte Zauber auf), gilt nicht. Waffe,
-- Begleiter, Laune und Munition gelten, wo sie Vorschlag der Klasse sind
-- (bis 6.13.1.0 galt der Begleiter ueberall - Beta-Test: "Begleiter fehlt"
-- stand auch beim Krieger in der Liste). Kann der Client gar nicht sagen,
-- was bekannt ist, gilt die Regel - "weiss nicht" ist nicht "gilt nicht".
R.ALL = "*"
-- Arten, die an der Klasse haengen: ohne `class` gelten sie nur dort, wo
-- die Klasse sie vorschlaegt.
R.CLASS_KINDS = { weapon = true, pet = true, happy = true, ammo = true }

local function CanAskSpells()
    local sb = _G.C_SpellBook
    local TR = WeintCodex.Trainer
    return ((sb and (sb.IsSpellKnown or sb.IsSpellInSpellBook)) or _G.IsPlayerSpell or _G.IsSpellKnown)
        and TR and TR.Known and true or false
end

-- true / false / nil (der Client kann es nicht sagen).
local function SpellKnown(id)
    if not CanAskSpells() then return nil end
    return WeintCodex.Trainer.Known(id)
end
R._SpellKnown = SpellKnown

-- Hat der Charakter einen Zauber der Regel gelernt? true / false / nil.
function R.Learned(rule)
    if not CanAskSpells() then return nil end
    for _, t in ipairs(rule.any or { rule.spell }) do
        local id = tonumber(t)
        if id and SpellKnown(id) then return true end
    end
    return false
end

function R.Applies(rule, class)
    if rule.learned and R.Learned(rule) == false then return false end
    if rule.class == R.ALL then return true end
    class = class or PlayerClass()
    if rule.class then return class == nil or rule.class == class end
    if R.NeedsSpell(rule.kind) then
        local sp = R.Resolve(rule.spell)
        local id = sp and sp.id
        if not id then return not CanAskSpells() end
        return SpellKnown(id) ~= false
    elseif R.CLASS_KINDS[rule.kind] then
        for _, sg in ipairs(R.Suggestions(class)) do
            if sg.kind == rule.kind and (rule.kind ~= "weapon" or sg.hand == rule.hand) then return true end
        end
        return false
    end
    return true
end

-- Die Regeln, die fuer diesen Charakter gelten.
function R.Here()
    local out = {}
    for _, rule in ipairs(R.Rules()) do
        if R.Applies(rule) then out[#out + 1] = rule end
    end
    return out
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

-- Vorschlaege ERGAENZEN, nie ersetzen: in 6.4.0.1 loeschte "Für meine
-- Klasse" beim Krieger (keine Vorschlaege) den selbst angelegten
-- Schlachtruf. Was schon da ist (gleiche Art, gleiche Hand), kommt nicht
-- doppelt. Gibt zurueck, wie viele neu dazukamen und wie viele die Klasse
-- ueberhaupt hat.
local function SameRule(a, b)
    -- Eine alte Regel ohne Klasse zaehlt als dieselbe (sonst kaeme die
    -- Waffe des Schurken doppelt).
    return a.kind == b.kind and a.hand == b.hand and a.spell == b.spell and a.item == b.item
        and (a.class == b.class or a.class == nil or b.class == nil)
end

function R.AddSuggestions(class)
    local sugg = R.Suggestions(class)
    local list = CopyRules(R.Rules())
    local added = 0
    for _, s in ipairs(sugg) do
        local found = false
        for _, r in ipairs(list) do
            if SameRule(r, s) then found = true break end
        end
        if not found then
            list[#list + 1] = s
            added = added + 1
        end
    end
    if added > 0 then R.SetRules(list) end
    return added, #sugg
end

function R.RemoveRule(i)
    local list = CopyRules(R.Rules())
    table.remove(list, i)
    R.SetRules(list)
end

--------------------------------------------------
-- Zauber: Name oder ID -> { id, name, icon }
--------------------------------------------------

-- Aufgeloeste Zauber merken: jede Aufloesung kostet einen Text (trim),
-- eine Abfrage beim Client (eine neue Tabelle) und das Ergebnis - und
-- sie lief bei jedem Ereignis fuer jede Regel. Gemerkt wird nur, was der
-- Client kennt; SPELLS_CHANGED (neu gelernt) und das Laden leeren.
local resolved = {}
function R.ClearCache() wipe(resolved) end

function R.Resolve(text)
    if type(text) ~= "string" or text == "" then return nil end
    local hit = resolved[text]
    if hit then return hit end
    local sp = R.ResolveUncached(text)
    if sp and sp.id then resolved[text] = sp end
    return sp
end

function R.ResolveUncached(text)
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
    if type(rule.any) == "table" then
        -- Einer der Reihe genuegt; "weiss nicht" schlaegt "fehlt".
        local result = false
        for _, t in ipairs(rule.any) do
            local a = R.PlayerAura({ spell = t })
            if a then return a end
            if a == nil and R.Resolve(t) and R.Resolve(t).name then result = nil end
        end
        return result
    end
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

--------------------------------------------------
-- Munition und Vorrat (6.6.0.6, Beta-Test: "Erinnerung, wenn ich zu
-- wenig Munition habe")
--------------------------------------------------
-- Auch hier keine eingebaute Liste: die Munition ist, was im
-- Munitionsplatz steckt (Platz 0), ein Vorrat der Gegenstand, den der
-- Spieler nennt. Was der Client nicht beantwortet, ist "weiss nicht" -
-- keine Erinnerung, nie "0 uebrig".

-- Gegenstand: Name oder ID -> { id, name, icon } oder nil. Namen kennt
-- der Client nur fuer Gegenstaende, die er schon gesehen hat.
function R.ResolveItem(text)
    if type(text) ~= "string" or text == "" then return nil end
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    local key = text:match("^%d+$") and (text + 0) or text
    local ci = _G.C_Item
    local instant = (ci and ci.GetItemInfoInstant) or _G.GetItemInfoInstant
    local id, icon
    if instant then
        local ok, i, _, _, _, ic = pcall(instant, key)
        if ok then id, icon = K.Plain(i), K.Plain(ic) end
    end
    if type(key) == "number" then id = id or key end
    local name
    local info = (ci and ci.GetItemInfo) or _G.GetItemInfo
    if info and id then
        local ok, n = pcall(info, id)
        if ok then name = K.Plain(n) end
    end
    return { id = id, name = name or (type(key) == "string" and key or nil), icon = icon }
end

-- Wie viele traegt der Spieler? Zahl oder nil (weiss nicht).
local function ItemCount(id)
    if not id then return nil end
    local ci = _G.C_Item
    local count = (ci and ci.GetItemCount) or _G.GetItemCount
    if not count then return nil end
    local ok, n = pcall(count, id)
    n = ok and K.Plain(n) or nil
    return type(n) == "number" and n or nil
end

local AMMO_SLOT = 0
local ammoSeen     -- die zuletzt angelegte Munition
R._ammoSeen = function(v) if v ~= nil then ammoSeen = v or nil end return ammoSeen end

-- Angelegte Munition: id, Anzahl - oder nil (kein Platz, nichts gesehen).
-- Ist der Platz leer, nachdem Munition drin war, zaehlt dieselbe Sorte in
-- den Taschen (verschossen: 0).
function R.Ammo()
    if not _G.GetInventoryItemID then return nil end
    local ok, id = pcall(_G.GetInventoryItemID, "player", AMMO_SLOT)
    id = ok and K.Plain(id) or nil
    if id then
        ammoSeen = id
        local n
        if _G.GetInventoryItemCount then
            local okC, c = pcall(_G.GetInventoryItemCount, "player", AMMO_SLOT)
            n = okC and K.Plain(c) or nil
        end
        if type(n) ~= "number" then n = ItemCount(id) end
        return id, n
    end
    if ammoSeen then return ammoSeen, ItemCount(ammoSeen) or 0 end
    return nil
end

local function ItemIcon(id)
    if not id then return nil end
    local ci = _G.C_Item
    local f = (ci and ci.GetItemIconByID) or _G.GetItemIcon
    if not f then return nil end
    local ok, ic = pcall(f, id)
    return ok and K.Plain(ic) or nil
end

-- Waffenbuffs des Schamanen (6.27.0.4, Beta-Test: "Verzauberung Waffe
-- fehlt" - gewuenscht ist "Waffe der Flammenzunge" / "des Felsbeissers").
-- IDs aus Classic wie im Lehrerbestand (Art `classic`): Felsbeisser,
-- Flammenzunge, Frostbrand, Windzorn. Genannt werden nur die gelernten,
-- mit dem Namen, den der Client sagt.
R.SHAMAN_IMBUES = { 8017, 8024, 8033, 8232 }

-- Namen der gelernten Waffenbuffs, oder nil (kein Schamane, nichts gelernt).
function R.ImbueNames()
    if PlayerClass() ~= "SHAMAN" then return nil end
    local names = {}
    for _, id in ipairs(R.SHAMAN_IMBUES) do
        if SpellKnown(id) ~= false then
            local sp = R.Resolve(tostring(id))
            if sp and type(sp.name) == "string" then names[#names + 1] = sp.name end
        end
    end
    return #names > 0 and names or nil
end

-- Kern eines Namens fuer den Tooltip der Waffe: dort steht der Buff ohne
-- "Waffe des/der" und ohne Genitiv ("Felsbeißer 3", nicht "Waffe des
-- Felsbeißers") - 6.27.0.4 suchte den vollen Namen und fand ihn nie.
function R.ImbueStem(name)
    local stem = name:gsub("^Waffe de[rs] ", ""):gsub(" Weapon$", "")
    if stem ~= name and stem:sub(-1) == "s" then stem = stem:sub(1, -2) end
    return stem
end

-- Liegt ein Waffenbuff an? (6.27.0.5, gemessen 6.27.0.4: "Waffe des
-- Felsbeißers ist aktiv", trotzdem Erinnerung.) Drei Wege, jeder genuegt:
-- eine Aura gleichen Namens auf dir (so fuehren neuere Clients die Buffs),
-- der Kern des Namens im Tooltip der Waffe, oder dort eine Zeile mit
-- Restzeit ("(30 Min.)") - die hat nur eine zeitweise Verzauberung.
function R.WeaponTipHas(slot, names)
    if names then
        local any = {}
        for i, id in ipairs(R.SHAMAN_IMBUES) do any[i] = tostring(id) end
        if R.PlayerAura({ any = any }) then return true end
        local ua = _G.C_UnitAuras
        if ua and ua.GetAuraDataBySpellName then
            for _, n in ipairs(names) do
                local ok, a = pcall(ua.GetAuraDataBySpellName, "player", n, "HELPFUL")
                if ok and a and not K.IsSecret(a) then return true end
            end
        end
    end
    local ti = _G.C_TooltipInfo
    if not (ti and ti.GetInventoryItem) then return false end
    local ok, data = pcall(ti.GetInventoryItem, "player", slot)
    if not ok or type(data) ~= "table" or type(data.lines) ~= "table" then return false end
    for i, l in ipairs(data.lines) do
        local t = K.Plain(l.leftText)
        if type(t) == "string" and i > 1 then
            if t:find("%(%d+ [Mm]in") or t:find("%(%d+ [Ss]ek") or t:find("%(%d+ sec") then return true end
            for _, n in ipairs(names or {}) do
                if t:find(R.ImbueStem(n), 1, true) then return true end
            end
        end
    end
    return false
end

-- Eine Erinnerung: { text, icon } oder nil.
function R.Check(rule)
    local kind = rule.kind
    if kind == "buff" then
        local aura = R.PlayerAura(rule)
        if aura == false then
            local sp = R.Resolve(rule.spell) or {}
            return { text = (rule.label or sp.name or rule.spell or "?") .. " fehlt", icon = sp.icon }
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
        local imbues = R.ImbueNames()
        if not has and R.WeaponTipHas(rule.hand == "off" and 17 or 16, imbues) then return nil end
        if not has then
            if imbues then
                local sp = R.Resolve(tostring(R.SHAMAN_IMBUES[2]))
                return { text = table.concat(imbues, " oder ") .. " fehlt", icon = sp and sp.icon }
            end
            return { text = "Waffe (" .. WeaponText(rule.hand) .. ") ohne Verzauberung" }
        end
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
    elseif kind == "happy" then
        -- Nur, was der Client sagt: ohne Laune (kein Jaegerbegleiter, keine
        -- Abfrage, geheim) keine Erinnerung - "weiss nicht" ist nicht
        -- "ungluecklich".
        local h = K.PetHappiness()
        if not h or h >= Below(rule) then return nil end
        return { text = "Begleiter " .. K.HAPPINESS[h].text .. " – füttern" }
    elseif kind == "ammo" then
        local id, n = R.Ammo()
        if not id or type(n) ~= "number" then return nil end
        local min = tonumber(rule.min) or R.DEFAULT_MIN.ammo
        if n >= min then return nil end
        if n == 0 then return { text = "Munition leer", icon = ItemIcon(id) } end
        return { text = string.format("Munition knapp: noch %d", n), icon = ItemIcon(id) }
    elseif kind == "item" then
        local it = R.ResolveItem(rule.item)
        local n = it and ItemCount(it.id)
        if type(n) ~= "number" then return nil end
        local min = tonumber(rule.min) or R.DEFAULT_MIN.item
        if n >= min then return nil end
        local name = it.name or rule.item or "?"
        if n == 0 then return { text = name .. " fehlt", icon = it.icon or ItemIcon(it.id) } end
        return { text = string.format("%s: noch %d", name, n), icon = it.icon or ItemIcon(it.id) }
    end
    return nil
end

--------------------------------------------------
-- Buffs aus der Tasche (6.27.0.0)
--------------------------------------------------
-- Auch hier keine eingebaute Liste von Gegenstaenden: was in der Tasche
-- liegt, sagt der Client, und was es tut, sein Tooltip. Essen zaehlt nur,
-- wenn sein Tooltip "Wohlgenaehrt" oder Erfahrung nennt (also einen Buff
-- gibt, nicht nur Leben); Elixier, Flaeschchen und Rolle (Verbrauchsgut,
-- Unterklasse 2-4) nennen ihren Zauber selbst (GetItemSpell). Gilt einer
-- davon schon, keine Erinnerung. Wie der Erfahrungsbuff von Forever heisst,
-- ist ungemessen - erkannt wird er an "Erfahrung"/"Experience" im Namen
-- einer Aura auf dir, oder an "Wohlgenaehrt"/"Well Fed".

-- "satt" (6.27.0.1, gemeldet vom Spieler: so heisst der Essensbuff auf
-- Forever) nur als ganzes Wort - "Sattel" ist keiner.
R.FED_WORDS = { "wohlgenährt", "well fed", "%f[%a]satt%f[%A]" }
R.XP_WORDS = { "erfahrung", "experience" }
R.EATING_WORDS = { "essen", "food", "trinken", "drink" }

local function HasWord(text, words)
    if type(text) ~= "string" then return false end
    text = text:lower()
    for _, w in ipairs(words) do
        if w:find("%f", 1, true) then
            if text:find(w) then return true end
        elseif text:find(w, 1, true) then return true end
    end
    return false
end

local bagCache = {}
R._bagCache = bagCache

local function TooltipText(id)
    local ti = _G.C_TooltipInfo
    if not (ti and ti.GetItemByID) then return nil end
    local ok, data = pcall(ti.GetItemByID, id)
    if not ok or type(data) ~= "table" or type(data.lines) ~= "table" then return nil end
    local parts = {}
    for _, l in ipairs(data.lines) do
        local t = K.Plain(l.leftText)
        if type(t) == "string" then parts[#parts + 1] = t end
    end
    if #parts == 0 then return nil end
    return table.concat(parts, "\n")
end

-- Was ein Gegenstand gibt: { kind = "food"|"xp"|"elixir", spell, name }
-- oder false (nichts Nuetzliches). nil: der Client weiss es noch nicht.
function R.BagItemKind(id)
    local c = bagCache[id]
    if c ~= nil then return c end
    local ci = _G.C_Item
    local instant = (ci and ci.GetItemInfoInstant) or _G.GetItemInfoInstant
    if not instant then return nil end
    local ok, _, _, _, _, _, classID, subID = pcall(instant, id)
    classID, subID = ok and K.Plain(classID), ok and K.Plain(subID)
    if classID ~= 0 or type(subID) ~= "number" then bagCache[id] = false return false end
    local getSpell = (ci and ci.GetItemSpell) or _G.GetItemSpell
    local spell
    if getSpell then
        local okS, sp = pcall(getSpell, id)
        spell = okS and K.Plain(sp) or nil
    end
    local info = (ci and ci.GetItemInfo) or _G.GetItemInfo
    local name, minLevel
    if info then
        local okI, n, _, _, _, ml = pcall(info, id)
        if okI then name, minLevel = K.Plain(n), K.Plain(ml) end
    end
    if type(name) ~= "string" then return nil end
    local entry = false
    if subID == 5 then
        local tip = TooltipText(id)
        if not tip then return nil end
        if HasWord(tip, R.XP_WORDS) then entry = { kind = "xp" }
        elseif HasWord(tip, R.FED_WORDS) then entry = { kind = "food" } end
    elseif subID >= 2 and subID <= 4 and type(spell) == "string" then
        entry = { kind = "elixir", spell = spell }
    end
    if entry then entry.name, entry.minLevel = name, type(minLevel) == "number" and minLevel or 0 end
    bagCache[id] = entry
    return entry
end

-- Namen der eigenen hilfreichen Auren, oder nil (der Client sagt es nicht).
-- Dazu (6.27.0.2) je Aura ihr Tooltiptext: "Satt" sagt im Namen nichts
-- von Erfahrung, sein Tooltip schon ("Durch Siege erhaltene Erfahrung um
-- 5 % erhoeht"). So gilt jeder Buff, der Erfahrung gibt, egal wie er heisst.
local auraTips = {}
R._auraTips = auraTips
local function AuraTip(a)
    local sid = K.Plain(a.spellId)
    if type(sid) == "number" and auraTips[sid] ~= nil then return auraTips[sid] or nil end
    local ti = _G.C_TooltipInfo
    local inst = K.Plain(a.auraInstanceID)
    if not (ti and ti.GetUnitBuffByAuraInstanceID and type(inst) == "number") then return nil end
    local ok, data = pcall(ti.GetUnitBuffByAuraInstanceID, "player", inst)
    if not ok or type(data) ~= "table" or type(data.lines) ~= "table" then return nil end
    local parts = {}
    for _, l in ipairs(data.lines) do
        local t = K.Plain(l.leftText)
        if type(t) == "string" then parts[#parts + 1] = t end
    end
    local text = #parts > 0 and table.concat(parts, "\n"):lower() or nil
    if type(sid) == "number" and text then auraTips[sid] = text end
    return text
end

local function HelpfulNames()
    local ua = _G.C_UnitAuras
    if not (ua and ua.GetAuraDataByIndex) then return nil end
    local names, tips = {}, {}
    for i = 1, 40 do
        local ok, a = pcall(ua.GetAuraDataByIndex, "player", i, "HELPFUL")
        if not ok or K.IsSecret(a) then return nil end
        if not a then break end
        local n = K.Plain(a.name)
        if type(n) == "string" then names[#names + 1] = n:lower() end
        local tip = AuraTip(a)
        if tip then tips[#tips + 1] = tip end
    end
    return names, tips
end
local function AnyName(names, words)
    for _, n in ipairs(names) do
        if HasWord(n, words) then return true end
    end
    return false
end

-- Erinnerungen aus der Tasche: Liste von { text, icon }.
function R.BagBuffs(out)
    out = out or {}
    local wantFood, wantElixir = Opt("bagFood"), Opt("bagElixir")
    if not (wantFood or wantElixir) then return out end
    local cc = _G.C_Container
    if not (cc and cc.GetContainerNumSlots and cc.GetContainerItemID) then return out end
    if K.Bool(_G.IsMounted and _G.IsMounted(), false) or K.Bool(_G.UnitOnTaxi and _G.UnitOnTaxi("player"), false)
       or K.Bool(_G.UnitIsDeadOrGhost and _G.UnitIsDeadOrGhost("player"), false) then
        return out
    end
    local names, tips = HelpfulNames()
    if not names then return out end
    if AnyName(names, R.EATING_WORDS) then return out end   -- isst gerade
    local level = K.Plain(_G.UnitLevel and _G.UnitLevel("player"))
    level = type(level) == "number" and level or 0
    local maxLevel = K.Plain(_G.GetMaxPlayerLevel and _G.GetMaxPlayerLevel())
    local leveling = type(maxLevel) == "number" and level < maxLevel
    -- Keine Sorte vorschreiben (6.27.0.2, Beta-Test: "er moechte, dass ich
    -- die Suppe nehme - ich nehme aber das Fleisch"): die Erinnerung nennt,
    -- dass Buff-Essen da ist und wie viele Sorten, nicht welches.
    local food, xp, elixir, elixirHas = nil, nil, nil, false
    local foodKinds, xpKinds = 0, 0
    for bag = 0, tonumber(_G.NUM_BAG_SLOTS) or 4 do
        local okN, n = pcall(cc.GetContainerNumSlots, bag)
        n = okN and K.Plain(n)
        for slot = 1, type(n) == "number" and n or 0 do
            local okI, id = pcall(cc.GetContainerItemID, bag, slot)
            id = okI and K.Plain(id)
            local e = type(id) == "number" and R.BagItemKind(id)
            if e and e.minLevel <= level then
                if e.kind == "xp" or e.kind == "food" then
                    if not e._counted then
                        e._counted = true
                        foodKinds = foodKinds + 1
                        if e.kind == "xp" then xpKinds = xpKinds + 1 end
                    end
                    if e.kind == "xp" and leveling then xp = xp or { id = id, e = e } end
                    food = food or { id = id, e = e }
                elseif e.kind == "elixir" then
                    elixir = elixir or { id = id, e = e }
                    if AnyName(names, { e.spell:lower() }) then elixirHas = true end
                end
            end
        end
    end
    for _, e in pairs(bagCache) do if e then e._counted = nil end end
    if wantFood then
        -- Satt ist, wer einen Essensbuff hat (Name) oder irgendeinen Buff,
        -- der laut Tooltip Erfahrung gibt oder satt macht.
        local fed = AnyName(names, R.FED_WORDS) or AnyName(tips, R.FED_WORDS) or AnyName(tips, R.XP_WORDS)
        local pick = (xp and leveling) and xp or food
        if pick and not fed then
            local kinds = (xp and leveling) and xpKinds or foodKinds
            local what = (xp and leveling) and "Essen mit Erfahrungsbuff" or "Essen mit Buff"
            out[#out + 1] = { text = string.format("Nicht satt – %s in der Tasche%s", what,
                                  kinds > 1 and string.format(" (%d Sorten)", kinds) or ""),
                              icon = ItemIcon(pick.id) }
        end
    end
    if wantElixir and elixir and not elixirHas then
        out[#out + 1] = { text = elixir.e.name .. " in der Tasche – Buff fehlt", icon = ItemIcon(elixir.id) }
    end
    return out
end

-- Alle Erinnerungen, die jetzt gelten.
function R.Active()
    local out = {}
    if not Opt("showReminders") then return out end
    if K.InCombat() and not Opt("remindInCombat") then return out end
    local where = Opt("where")
    if where == "group" and not InGroup() then return out end
    if where == "instance" and not InInstance() then return out end
    for _, rule in ipairs(R.Here()) do
        local k = rule.kind
        if k == "buff" or k == "weapon" or k == "pet" or k == "happy" or k == "ammo" or k == "item" then
            local hit = R.Check(rule)
            if hit then out[#out + 1] = hit end
        end
    end
    if not K.InCombat() then R.BagBuffs(out) end
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
        for _, rule in ipairs(R.Here()) do
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
        for _, rule in ipairs(R.Here()) do
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

-- EREIGNISSE SAMMELN (6.6.1.8, Beta-Test: "das Addon verbraucht 10 bis
-- 40 MB"). SPELL_UPDATE_COOLDOWN kommt im Kampf bei jedem Zauber
-- mehrfach, UNIT_AURA bei jedem Buff - und jede Auswertung legt Tabellen
-- an (Regeln, Zauberinfos, Auren des Clients). Jetzt merkt sich ein
-- Ereignis nur, WAS neu zu zeichnen ist; ausgewertet wird hoechstens
-- einmal je Zehntelsekunde.
local pending, queued = {}, false
local function Flush()
    queued = false
    local b, p, c = pending.banner, pending.procs, pending.cooldowns
    pending.banner, pending.procs, pending.cooldowns = nil, nil, nil
    if b then R.UpdateBanner() end
    if p then R.UpdateProcs() end
    if c then R.UpdateCooldowns() end
end
R.Flush = Flush

function R.Schedule(banner, procs, cooldowns)
    if banner then pending.banner = true end
    if procs then pending.procs = true end
    if cooldowns then pending.cooldowns = true end
    if queued then return end
    queued = true
    if _G.C_Timer and _G.C_Timer.After then _G.C_Timer.After(R.FLUSH_DELAY, Flush) else Flush() end
end
R.FLUSH_DELAY = 0.1

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
        "SPELL_UPDATE_COOLDOWN", "SPELL_UPDATE_CHARGES", "READY_CHECK", "PLAYER_MOUNT_DISPLAY_CHANGED",
        "BAG_UPDATE_DELAYED", "UNIT_HAPPINESS" }) do
        pcall(ev.RegisterEvent, ev, e)
    end
    pcall(ev.RegisterEvent, ev, "SPELLS_CHANGED")
    ev:SetScript("OnEvent", K.Measured("Erinnerungen", function(_, event, unit)
        if event == "UNIT_AURA" or event == "UNIT_INVENTORY_CHANGED" or event == "UNIT_PET" then
            if unit ~= "player" then return end
        end
        if event == "SPELLS_CHANGED" or event == "PLAYER_ENTERING_WORLD" then R.ClearCache() end
        if event == "SPELL_UPDATE_COOLDOWN" or event == "SPELL_UPDATE_CHARGES" then
            R.Schedule(false, false, true)
            return
        end
        R.Schedule(true, event == "UNIT_AURA", false)
        if event == "PLAYER_ENTERING_WORLD" then R.Schedule(true, true, true) end
    end))
    -- Waffenverzauberungen laufen ab, ohne dass ein Ereignis kommt: ein
    -- ruhiger Takt, alle fuenf Sekunden.
    local acc = 0
    ev:SetScript("OnUpdate", K.Measured("Erinnerungen", function(_, el)
        acc = acc + (el or 0)
        if acc < 5 then return end
        acc = 0
        R.UpdateBanner()
    end))
    R.UpdateAll()
end

--------------------------------------------------
-- Einstellungen
--------------------------------------------------

-- Was im Formular "Regel hinzufuegen" steht (nicht gespeichert).
local draft = { kind = "buff", spell = "", hand = "main", scope = "class", min = "", below = 3 }
R.draft = draft

-- Fuer wen: "alle Klassen", "nur Krieger" oder - alte Regel - offen.
function R.ScopeText(rule)
    if rule.class == R.ALL then return "alle Klassen" end
    if rule.class then return "nur " .. (WeintCodex.Names.ClassLabel(rule.class) or rule.class) end
    return nil
end

function R.RuleText(rule)
    local text = R.BaseRuleText(rule)
    local scope = R.ScopeText(rule)
    if scope then text = text .. "  ·  " .. scope end
    if not R.Applies(rule) then text = text .. "  (hier aus)" end
    return text
end

function R.BaseRuleText(rule)
    local kind = KIND_TEXT[rule.kind] or rule.kind
    if R.NeedsSpell(rule.kind) then
        local sp = R.Resolve(rule.spell)
        local name = rule.label or (sp and sp.name) or rule.spell or "?"
        local known = sp and sp.id and "" or "  (unbekannt)"
        return kind .. ": " .. tostring(name) .. known
    elseif rule.kind == "weapon" then
        return kind .. " (" .. WeaponText(rule.hand) .. ")"
    elseif rule.kind == "happy" then
        return "Begleiter-Laune: erinnern, wenn " .. (Below(rule) == 2 and "unglücklich" or "nicht glücklich")
    elseif rule.kind == "ammo" then
        return string.format("Munition knapp: unter %d", tonumber(rule.min) or R.DEFAULT_MIN.ammo)
    elseif rule.kind == "item" then
        local it = R.ResolveItem(rule.item)
        local name = it and it.name or rule.item or "?"
        local known = it and it.id and "" or "  (unbekannt)"
        return string.format("Vorrat knapp: %s unter %d", tostring(name), tonumber(rule.min) or R.DEFAULT_MIN.item) .. known
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
    elseif draft.kind == "happy" then
        rule.below = Below(draft)
    elseif R.NeedsItem(draft.kind) then
        local text = (draft.spell or ""):gsub("^%s+", ""):gsub("%s+$", "")
        if text == "" then return false, "Gegenstand fehlt" end
        rule.item = text
    end
    if R.NeedsAmount(draft.kind) then
        local m = (draft.min or ""):gsub("%s", "")
        if m ~= "" then
            local n = tonumber(m)
            if not n or n < 1 or n ~= math.floor(n) then return false, "Menge ist keine ganze Zahl" end
            rule.min = n
        else
            rule.min = R.DEFAULT_MIN[draft.kind]
        end
    end
    rule.class = draft.scope == "all" and R.ALL or PlayerClass()
    R.AddRule(rule)
    draft.spell, draft.min = "", ""
    return true
end

-- Die Liste der Regeln im Einstellungsfenster: bis zu acht Zeilen mit
-- Symbol, Beschreibung und einem Knopf zum Entfernen. Mehr passen nicht
-- auf die Seite - die neunte und alle weiteren wirken trotzdem und werden
-- als "... und N weitere" gezaehlt, statt still zu verschwinden.
--
-- NUR DIESER CHARAKTER (6.13.2.0, Beta-Test: "Ich sehe in den Erinnerungen
-- alle Erinnerungen von allen Charakteren ... das macht das alles sehr
-- unuebersichtlich"). Die Regeln sind accountweit gespeichert; die Liste
-- zeigt, was hier gilt (R.Applies), und zaehlt den Rest in einer Zeile.
-- "Alle zeigen" holt die anderen dazu (blass, "(hier aus)") - zum
-- Aufraeumen. Entfernen trifft immer die Regel der Zeile (`row.index`),
-- nicht die n-te gespeicherte.
local LIST_ROWS = 8
R.LIST_ROWS = LIST_ROWS
R.LIST_HEIGHT = LIST_ROWS * 26 + 28
R.listAll = false

-- Was die Liste zeigt: { { rule, index }, ... } und wie viele ausgeblendet sind.
function R.ListedRules()
    local out, hidden = {}, 0
    for i, rule in ipairs(R.Rules()) do
        if R.listAll or R.Applies(rule) then
            out[#out + 1] = { rule = rule, index = i }
        else
            hidden = hidden + 1
        end
    end
    return out, hidden
end

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
        row.remove = WeintCodex.CreateButton(row, { text = "Entfernen", kind = "secondary", height = 20, size = 10,
            onClick = function() if row.index then R.RemoveRule(row.index) end end })
        row.remove:SetPoint("RIGHT", row, "RIGHT", -2, 0)
        w.rows[i] = row
    end
    w.more = K.NewText(w, 11)
    w.more:SetPoint("TOPLEFT", w, "TOPLEFT", 4, -LIST_ROWS * 26 - 4)
    w.toggle = WeintCodex.CreateButton(w, { text = "Alle zeigen", kind = "secondary", height = 20, size = 10,
        onClick = function()
            R.listAll = not R.listAll
            w.Sync()
        end })
    w.toggle:SetPoint("TOPRIGHT", w, "TOPLEFT", width - 2, -LIST_ROWS * 26)
    w.empty = K.NewText(w, 12)
    w.empty:SetPoint("TOPLEFT", w, "TOPLEFT", 4, -6)
    w.empty:SetTextColor(unpack(C.textDim))
    w.Sync = function()
        local listed, hidden = R.ListedRules()
        for i, row in ipairs(w.rows) do
            local entry = listed[i]
            local rule = entry and entry.rule
            row.index = entry and entry.index or nil
            if rule then
                row.text:SetText(R.RuleText(rule))
                row.text:SetTextColor(unpack(R.Applies(rule) and C.textNormal or C.textDim))
                local sp = (R.NeedsSpell(rule.kind) and R.Resolve(rule.spell))
                    or (R.NeedsItem(rule.kind) and R.ResolveItem(rule.item))
                if sp and sp.icon then row.icon:SetTexture(sp.icon) row.icon:Show() else row.icon:Hide() end
                row:Show()
            else
                row:Hide()
            end
        end
        local extra = #listed - LIST_ROWS
        local parts = {}
        if extra > 0 then parts[#parts + 1] = "… und " .. extra .. " weitere" end
        if hidden > 0 then
            parts[#parts + 1] = hidden == 1 and "1 Regel anderer Klassen ausgeblendet"
                or (hidden .. " Regeln anderer Klassen ausgeblendet")
        end
        w.more:SetText(table.concat(parts, "  ·  "))
        -- Der Knopf nur, wenn es etwas umzuschalten gibt.
        local others = hidden > 0 or R.listAll
        if R.listAll then
            local n = 0
            for _, e in ipairs(listed) do if not R.Applies(e.rule) then n = n + 1 end end
            others = n > 0
        end
        w.toggle:SetShown(others)
        if w.toggle.SetText then w.toggle:SetText(R.listAll and "Nur diese Klasse" or "Alle zeigen") end
        w.empty:SetText(hidden > 0 and "Für diese Klasse noch keine Regel. Unten eine anlegen – oder „Für meine Klasse“."
            or "Noch keine Regel. Unten eine anlegen – oder „Für meine Klasse“.")
        w.empty:SetShown(#listed == 0)
    end
    return w
end

-- Aenderungen am Formular (nicht gespeichert) sollen gesperrte Felder
-- nachziehen: dasselbe Signal wie eine Einstellung.
local function DraftChanged() K.Fire("setting", KEY, "draft") end

local function px(v) return string.format("%d px", v) end

-- Komfort, nicht Oberflaeche (6.9.0.0): ein eigenes Fenster, das dem
-- Spiel fehlt - es geht auch ohne die WeintCodex-Oberflaeche. Von Haus aus
-- an, wenn die Oberflaeche an ist; sonst erst, wenn du es einschaltest.
-- Schalten wirkt nach dem Neuladen (eigene Fenster und Ereignisse, die
-- sich im laufenden Spiel nicht sauber abbauen).
K.Register({
    key = KEY, group = "qol", order = 58, defaultEnabled = "ui", reload = true,
    title = "Erinnerungen",
    description = "Fehlende Buffs, Waffenverzauberung, Begleiter und seine Laune vor dem Kampf; eigene Buffs, Procs und Abklingzeiten als Symbole – so weit der Client sie herausgibt.",
    defaults = defaults,
    Enable = Enable,
    OnSetting = function() R.ClearCache() R.UpdateAll() end,
    pages = {
        { key = "regeln", label = "Regeln", build = function(B)
            B:Section("Deine Regeln", "Jede Regel ist eine Erinnerung oder ein Symbol. Zauber nennst du mit Namen oder ID – eine eingebaute Liste gibt es nicht. Eine Regel gilt für die Klasse, auf der du sie anlegst, oder für alle. Hier stehen die Regeln dieser Klasse; die der anderen holt „Alle zeigen“ dazu.")
            B:Row({ type = "custom", height = R.LIST_HEIGHT, create = function(parent, width)
                        return R.BuildRuleList(parent, width)
                    end }, nil)
            B:Section("Neue Regel")
            B:Row({ type = "dropdown", label = "Art", items = R.KINDS,
                    get = function() return draft.kind end, set = function(v) draft.kind = v DraftChanged() end },
                  { type = "input", label = "Zauber oder Gegenstand (Name oder ID)",
                    get = function() return draft.spell end, set = function(v) draft.spell = v end,
                    disabled = function() return not (R.NeedsSpell(draft.kind) or R.NeedsItem(draft.kind)) end })
            B:Row({ type = "dropdown", label = "Hand (bei Waffe)", items = {
                        { value = "main", text = "Haupthand" }, { value = "off", text = "Nebenhand" } },
                    get = function() return draft.hand end, set = function(v) draft.hand = v DraftChanged() end,
                    disabled = function() return draft.kind ~= "weapon" end },
                  { type = "dropdown", label = "Gilt für", items = {
                        { value = "class", text = "Nur diese Klasse" }, { value = "all", text = "Alle Klassen" } },
                    get = function() return draft.scope end, set = function(v) draft.scope = v DraftChanged() end })
            B:Row({ type = "input", label = "Mindestmenge (Munition: 200, Vorrat: 1)",
                    get = function() return draft.min end, set = function(v) draft.min = v end,
                    disabled = function() return not R.NeedsAmount(draft.kind) end },
                  { type = "button", label = "Hinzufügen", text = "Regel hinzufügen",
                    onClick = function()
                        local ok, why = R.AddDraft()
                        if not ok and why then
                            print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " Regel nicht angelegt: " .. why .. ".")
                        end
                    end })
            B:Row({ type = "button", label = "Vorschläge", text = "Für meine Klasse",
                    tooltip = "Ergänzt die Vorschläge für deine Klasse (Waffe, Begleiter und seine Laune, Munition). Eigene Regeln bleiben.",
                    onClick = function()
                        local added, total = R.AddSuggestions()
                        local line
                        if total == 0 then
                            line = "Für deine Klasse gibt es keine Vorschläge ohne Zauber – lege Buffs selbst an (Name oder ID)."
                        elseif added == 0 then
                            line = "Die Vorschläge für deine Klasse stehen schon in der Liste."
                        else
                            line = added == 1 and "Ein Vorschlag ergänzt." or string.format("%d Vorschläge ergänzt.", added)
                        end
                        print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " " .. line)
                    end },
                  { type = "dropdown", label = "Laune (bei Begleiter): erinnern, wenn", items = R.HAPPY_BELOW,
                    get = function() return draft.below end, set = function(v) draft.below = v DraftChanged() end,
                    disabled = function() return draft.kind ~= "happy" end })
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
            B:Section("Aus der Tasche")
            B:Row({ type = "toggle", label = "Essen mit Buff", key = "bagFood",
                    description = "Liegt Essen in der Tasche, das „Wohlgenährt“ oder Erfahrung gibt, und der Buff fehlt: Erinnerung. Erfahrungsessen nur beim Leveln." },
                  { type = "toggle", label = "Elixiere, Fläschchen, Rollen", key = "bagElixir",
                    description = "Liegt eins in der Tasche und keiner seiner Buffs ist auf dir: Erinnerung." })
            B:Section("Symbole")
            B:Row({ type = "toggle", label = "Buffs und Procs", key = "showProcs" },
                  { type = "slider", label = "Größe", key = "iconSize", min = 20, max = 64, step = 2, format = px })
            B:Row({ type = "toggle", label = "Abklingzeiten", key = "showCooldowns" },
                  { type = "slider", label = "Größe", key = "cdSize", min = 20, max = 56, step = 2, format = px })
            B:Note("Verschieben im Gestaltungsmodus. Im Kampf zeigen Symbole und Uhren, was der Client herausgibt; nennt er eine Aura nur verschlüsselt, bleibt ihr Symbol aus.")
        end },
    },
})
