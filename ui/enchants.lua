--------------------------------------------------
-- WeintCodex :: Oberflaeche - fehlende Verzauberungen (6.63.0.0)
--------------------------------------------------
-- Beta-Test: "ob alle Verzauberungen vorhanden sind oder nicht. 1.
-- klassenspezifisch, 2. dezent, da ja erstmal gelevelt wird. Sobald man 60
-- ist, soll die Meldung kraeftiger sein, wenn man sein Charakterfenster
-- aufmacht."
--
-- Quelle (Beta-Test: "halte dich an die Daten, die der Verzauberer auch
-- kann"): die Rezepte der Verzauberkunst in data/professions.lua (P.RAW,
-- aus dem Forever-Client, Art `community`). Ein Platz zaehlt, wenn es fuer
-- ihn mindestens ein Rezept "Enchant <Platz> - ..." gibt - gelesen beim
-- ersten Blick, nicht von Hand gepflegt: kommen mit einem neuen Import
-- Rezepte dazu oder fallen weg, zieht das Charakterfenster mit. Ob eine
-- Verzauberung drauf ist, sagt der Client (Feld 2 des Links); welche die
-- beste waere, sagt dieses Modul nie.
--
-- Rezeptname -> Platz:
--   Cloak Umhang, Chest Brust, Bracer Handgelenke, Gloves Haende,
--   Boots Fuesse, Necklace Hals (neu in Forever)
--   Weapon / 2H Weapon  Waffenhand; Weapon auch die Nebenhand mit Waffe
--   Shield              Nebenhand mit Schild
-- Nicht vom Verzauberer (Zielfernrohr, Arkanum, Schulterverzauberung)
-- zaehlt nicht. Klassenspezifisch ist, was der Charakter traegt: Schild
-- oder Zweitwaffe nur, wenn vorhanden; ein Gegenstand "in der Nebenhand"
-- hat kein Rezept.
-- Leerer Platz: nichts zu verzaubern. Link nicht lesbar: unbekannt - nie
-- als "fehlt" gezaehlt.
--
-- Anzeige: unter der Hoechststufe ein kleiner Punkt in Gold am Platz und
-- eine gedaempfte Zeile; auf der Hoechststufe ein roter Punkt und die Zeile
-- in Rot mit den Namen. Im Tooltip des Platzes "Ohne Verzauberung".
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIEnchants = {}

local EN = WeintCodex.UIEnchants
local K = WeintCodex.UIKit
local C = WeintCodex.Colors
local CS = WeintCodex.UICharacter
local EquipInfo

EN.MAX_LEVEL = 60
EN.DOT_SMALL, EN.DOT_BIG = 8, 10

-- { Platz des Clients, Name, Rezeptworte }
EN.SLOTS = {
    { "NeckSlot", "Hals", { "Necklace" } },
    { "BackSlot", "Umhang", { "Cloak" } },
    { "ChestSlot", "Brust", { "Chest" } },
    { "WristSlot", "Handgelenke", { "Bracer" } },
    { "HandsSlot", "Hände", { "Gloves" } },
    { "FeetSlot", "Füße", { "Boots" } },
    { "MainHandSlot", "Waffenhand", { "Weapon", "2H Weapon" } },
    { "SecondaryHandSlot", "Nebenhand", { "Shield", "Weapon" }, "offhand" },
}
-- Nebenhand: welches Rezeptwort zu welchem Gegenstand passt.
EN.OFFHAND = { INVTYPE_SHIELD = "Shield", INVTYPE_WEAPON = "Weapon", INVTYPE_WEAPONOFFHAND = "Weapon" }

-- Rezeptworte aus der Verzauberkunst: { [Wort] = Anzahl Rezepte }.
-- nil = Daten fehlen (dann zeigt das Modul nichts - unbekannt, nicht leer).
function EN.Kinds()
    if EN.kinds ~= nil then return EN.kinds or nil end
    local P = WeintCodex.ProfessionData
    local raw = P and P.RAW and P.RAW.enchanting
    if type(raw) ~= "string" then EN.kinds = false return nil end
    local k, r = {}, {}
    for line in raw:gmatch("[^\n]+") do
        local spell, learn, w, effect = line:match("^(%d+) %S+ (%S+) .-|Enchant ([^|]-) %- (.+)$")
        if spell then
            k[w] = (k[w] or 0) + 1
            r[w] = r[w] or {}
            r[w][#r[w] + 1] = { spell = tonumber(spell), learn = tonumber(learn) or 0, effect = effect }
        end
    end
    EN.kinds = _G.next(k) and k or false
    EN.recipes = r
    return EN.kinds or nil
end

-- Vorschlaege (6.64.0.0, Beta-Test: "was ich darauf verzaubern sollte").
-- KEINE Wertung, nur ein Filter: Rezepte des Verzauberers fuer den Platz,
-- deren Wirkung eine Hauptwerte-Faustregel der Klasse nennt (Stand aus
-- Classic, im Spiel "Faustregel") - und in einer Stufe, die zum Charakter
-- passt (Fertigkeit bis Stufe x 6; auf der Hoechststufe alle). Die
-- staerksten zuerst, hoechstens drei. Welche die beste ist, sagt das nicht.
EN.CLASS_WORDS = {
    WARRIOR = { "Strength", "Agility", "Stamina", "Defense", "Striking", "Impact", "Crusader", "Fiery", "Icy Chill" },
    ROGUE   = { "Agility", "Strength", "Stamina", "Striking", "Crusader", "Fiery", "Lifestealing" },
    HUNTER  = { "Agility", "Stamina", "Intellect" },
    PALADIN = { "Strength", "Intellect", "Stamina", "Healing", "Impact", "Crusader" },
    SHAMAN  = { "Intellect", "Strength", "Agility", "Stamina", "Healing", "Spell Power", "Impact", "Crusader" },
    DRUID   = { "Intellect", "Agility", "Strength", "Stamina", "Spirit", "Healing", "Impact" },
    PRIEST  = { "Intellect", "Spirit", "Stamina", "Healing", "Spell Power", "Spellpower" },
    MAGE    = { "Intellect", "Spirit", "Stamina", "Spell Power", "Spellpower", "Frost Power", "Fire Power" },
    WARLOCK = { "Intellect", "Stamina", "Spirit", "Spell Power", "Spellpower", "Shadow Power", "Fire Power" },
}
EN.ALWAYS = { "Stats" }      -- "+x auf alle Werte" passt jeder Klasse
EN.SUGGEST_MAX = 3
EN.SKILL_PER_LEVEL = 6

local function Matches(effect, words)
    for _, w in ipairs(words) do
        if effect:find(w, 1, true) then return true end
    end
    return false
end

-- Rezeptworte, die zum angelegten Gegenstand passen.
function EN.WordsFor(slotName, link)
    for _, s in ipairs(EN.SLOTS) do
        if s[1] == slotName then
            if s[4] == "offhand" then
                local w = EN.OFFHAND[EquipInfo(link) or ""]
                return w and { w } or {}
            end
            if slotName == "MainHandSlot" then
                return EquipInfo(link) == "INVTYPE_2HWEAPON" and { "2H Weapon", "Weapon" } or { "Weapon" }
            end
            return s[3]
        end
    end
    return {}
end

function EN.Suggest(slotName, link, class, level, atMax)
    if not EN.Kinds() or not EN.recipes then return {} end
    local words = class and EN.CLASS_WORDS[class]
    if not words then return {} end
    local cap = atMax and math.huge or (level or 1) * EN.SKILL_PER_LEVEL
    local fit, any = {}, {}
    for _, w in ipairs(EN.WordsFor(slotName, link)) do
        for _, r in ipairs(EN.recipes[w] or {}) do
            if Matches(r.effect, words) or Matches(r.effect, EN.ALWAYS) then
                any[#any + 1] = r
                if r.learn <= cap then fit[#fit + 1] = r end
            end
        end
    end
    local list = #fit > 0 and fit or any
    table.sort(list, function(a, b) if a.learn ~= b.learn then return a.learn > b.learn end return a.spell < b.spell end)
    if #fit == 0 then   -- nichts in Reichweite: die kleinsten
        table.sort(list, function(a, b) return a.learn < b.learn end)
    end
    for i = #list, EN.SUGGEST_MAX + 1, -1 do list[i] = nil end
    return list, #fit == 0 and #list > 0
end

local function RecipeName(r)
    local cs = _G.C_Spell
    local ok, n = pcall(function()
        if cs and cs.GetSpellName then return cs.GetSpellName(r.spell) end
        return _G.GetSpellInfo and (_G.GetSpellInfo(r.spell)) or nil
    end)
    n = ok and K.Plain(n) or nil
    return type(n) == "string" and n ~= "" and n or r.effect
end
EN.RecipeName = RecipeName

local function Opt() return K.Get("general", "enchantHint") ~= false end

local function Level()
    local l = _G.UnitLevel and K.Plain(_G.UnitLevel("player"))
    return type(l) == "number" and l or nil
end

function EN.AtMax()
    local l = Level()
    local max = _G.GetMaxPlayerLevel and K.Plain(_G.GetMaxPlayerLevel())
    if type(max) ~= "number" or max <= 0 then max = EN.MAX_LEVEL end
    return l ~= nil and l >= max
end

-- Feld 2 des Links: die Verzauberung. true / false / nil (unbekannt).
function EN.HasEnchant(link)
    if type(link) ~= "string" then return nil end
    local ench = link:match("item:%-?%d+:(%-?%d*)")
    if ench == nil then return nil end
    return (tonumber(ench) or 0) ~= 0
end

function EquipInfo(link)
    local f = (_G.C_Item and _G.C_Item.GetItemInfoInstant) or _G.GetItemInfoInstant
    if not f then return nil end
    local ok, _, _, _, loc = pcall(f, link)
    if not ok then return nil end
    return K.Plain(loc)
end

-- Gilt der Platz mit diesem Gegenstand? true / false / nil (unbekannt).
function EN.Applies(slot, link, kinds)
    if slot[4] == "offhand" then
        local loc = EquipInfo(link)
        if type(loc) ~= "string" then return nil end
        local word = EN.OFFHAND[loc]
        return word ~= nil and kinds[word] ~= nil
    end
    for _, w in ipairs(slot[3]) do
        if kinds[w] then return true end
    end
    return false
end

EN.missing = {}     -- Namen in Reihenfolge
EN.state = {}       -- [Platzname] = "missing" / "ok" / "unknown" / nil (gilt nicht)
EN.dirty = true

function EN.Scan()
    EN.dirty = false
    local missing, state = EN.missing, EN.state
    for i = #missing, 1, -1 do missing[i] = nil end
    for k in pairs(state) do state[k] = nil end
    if not (_G.GetInventorySlotInfo and _G.GetInventoryItemLink) then return missing end
    local kinds = EN.Kinds()
    if not kinds then return missing end
    for _, s in ipairs(EN.SLOTS) do
        local ok, id = pcall(_G.GetInventorySlotInfo, s[1])
        id = ok and K.Plain(id) or nil
        if type(id) == "number" then
            local link = K.Plain(_G.GetInventoryItemLink("player", id))
            if type(link) == "string" then
                local applies = EN.Applies(s, link, kinds)
                if applies == nil then
                    state[s[1]] = "unknown"
                elseif applies then
                    local has = EN.HasEnchant(link)
                    if has == nil then state[s[1]] = "unknown"
                    elseif has then state[s[1]] = "ok"
                    else
                        state[s[1]] = "missing"
                        missing[#missing + 1] = s[2]
                    end
                end
            end
        end
    end
    return missing
end

-- Anzeige ----------------------------------------------------------------
local dots = {}
EN.dots = dots
local line

local function Dot(name)
    local slot = _G["Character" .. name]
    if type(slot) ~= "table" or not slot.CreateTexture then return nil end
    local d = dots[name]
    if not d then
        d = slot:CreateTexture(nil, "OVERLAY", nil, 7)
        d:SetTexture(K.MEDIA .. "dot")
        d:SetPoint("TOPRIGHT", slot, "TOPRIGHT", -2, -2)
        dots[name] = d
        if slot.HookScript then
            slot:HookScript("OnEnter", function()
                if EN.state[name] ~= "missing" or not Opt() then return end
                local tip = _G.GameTooltip
                if not (tip and tip.AddLine) then return end
                local atMax = EN.AtMax()
                local c = atMax and C.dangerBright or C.warning
                tip:AddLine(" ")
                tip:AddLine("Ohne Verzauberung", c[1], c[2], c[3])
                local id = _G.GetInventorySlotInfo and select(2, pcall(_G.GetInventorySlotInfo, name))
                local link = type(K.Plain(id)) == "number" and K.Plain(_G.GetInventoryItemLink("player", id)) or nil
                local cname, class
                if _G.UnitClass then cname, class = _G.UnitClass("player") end
                local list, later = EN.Suggest(name, link, K.Plain(class), (function()
                    local l = _G.UnitLevel and K.Plain(_G.UnitLevel("player")) return type(l) == "number" and l or 1 end)(), atMax)
                if #list > 0 then
                    local m = C.textMuted
                    tip:AddLine("Passend für " .. tostring(K.Plain(cname) or "deine Klasse") .. " (Faustregel)"
                        .. (later and ", erst auf höherer Stufe üblich:" or ":"), m[1], m[2], m[3])
                    local t = C.textNormal
                    for _, r in ipairs(list) do
                        tip:AddDoubleLine("  " .. RecipeName(r), "Verzauberkunst " .. r.learn, t[1], t[2], t[3], m[1], m[2], m[3])
                    end
                end
                tip:Show()
            end)
        end
    end
    return d
end

local function Line()
    if line then return line end
    local anchor = _G.CharacterMainHandSlot
    if type(anchor) ~= "table" then return nil end
    line = K.NewText(anchor, 11, "OVERLAY")
    line:SetPoint("BOTTOM", anchor, "TOP", 0, 8)
    line:SetJustifyH("CENTER")
    return line
end

-- Bei offenem Fenster jeder Durchlauf: nur neu zeichnen, wenn sich etwas
-- geaendert hat (keine Zeichenkette je Durchlauf).
local painted = {}
function EN.Paint()
    local scanned = EN.dirty
    if scanned then EN.Scan() end
    local on = Opt()
    local strong = EN.AtMax()
    if not scanned and painted.on == on and painted.strong == strong then return end
    painted.on, painted.strong = on, strong
    local col = strong and C.danger or C.warning
    local size = strong and EN.DOT_BIG or EN.DOT_SMALL
    local alpha = strong and 1 or 0.85
    for _, s in ipairs(EN.SLOTS) do
        local miss = on and EN.state[s[1]] == "missing"
        local d = (miss or dots[s[1]]) and Dot(s[1])
        if d then
            if miss then
                d:SetSize(size, size)
                d:SetVertexColor(col[1], col[2], col[3], alpha)
            end
            d:SetShown(miss)
        end
    end
    local l = Line()
    if not l then return end
    local n = #EN.missing
    -- 6.64.0.0: beim Leveln steht der Hinweis nur am Platz (Punkt, Tooltip),
    -- die Zeile ueber den Waffen erst auf der Hoechststufe.
    if not on or n == 0 or not strong then l:Hide() return end
    if strong then
        local c = C.dangerBright
        l:SetTextColor(c[1], c[2], c[3], 1)
        l:SetText(n .. (n == 1 and " Verzauberung fehlt: " or " Verzauberungen fehlen: ") .. table.concat(EN.missing, ", "))
    else
        local c = C.textMuted
        l:SetTextColor(c[1], c[2], c[3], 0.8)
        -- 6.63.1.0: ohne Namen las sich die Zeile ueber der Waffe als "die
        -- Waffe fehlt" (Beta-Test) - der Platz steht immer dabei.
        l:SetText("Ohne Verzauberung: " .. table.concat(EN.missing, ", "))
    end
    l:Show()
end

-- Ein Durchlauf des Charakterfensters ruft auch uns (kein eigener Takt).
if CS and CS.Update then
    local orig = CS.Update
    CS.Update = function(f, d)
        orig(f, d)
        pcall(EN.Paint)
    end
end

local ev = CreateFrame("Frame")
EN.events = ev
for _, e in ipairs({ "PLAYER_EQUIPMENT_CHANGED", "UNIT_INVENTORY_CHANGED", "PLAYER_LEVEL_UP", "PLAYER_ENTERING_WORLD" }) do
    pcall(ev.RegisterEvent, ev, e)
end
ev:SetScript("OnEvent", function() EN.dirty = true end)

local gen = K.Module and K.Module("general")
if gen and gen.defaults and gen.defaults.enchantHint == nil then gen.defaults.enchantHint = true end
