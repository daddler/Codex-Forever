--------------------------------------------------
-- WeintCodex :: Oberflaeche - Klickzauber
--------------------------------------------------
-- Beta-Test: "ein ganz einfaches Addon, womit ich Zauber auf Tasten binden
-- kann, fuers Heilen - aehnlich wie VuhDo, Clique, Healbot. Einfach, aber
-- es soll den Sinn erfuellen."
--
-- DAS PRINZIP. Eine Belegung ist Maustaste + Zusatztaste -> Aktion, und
-- sie gilt auf jedem Rahmen von WeintCodex, der eine Einheit zeigt
-- (Gruppe, Schlachtzug, Spieler, Ziel, Fokus, ...). Wer mit Umschalt +
-- Links auf Brunhild klickt, heilt Brunhild - ohne sie erst anzuwaehlen.
-- Die Maus zeigt beim Drueberfahren, was welche Taste gerade tut.
--
-- WIE. Nur die Klick-Attribute des geschuetzten Knopfes ("shift-type1" =
-- "spell", "shift-spell1" = Name) - der Client zaubert beim Klick selbst,
-- Lua ist nicht beteiligt. Keine Snippets: dem Forever-Client fehlt dafuer
-- der Uebersetzer (siehe ui/groupframes.lua), und alle Knoepfe entstehen
-- ohnehin ausserhalb des Kampfes. Attribute setzen darf Lua nur ausserhalb
-- des Kampfes - eine Aenderung im Kampf greift danach.
--
-- WAS ES NICHT KANN. Tastatur-Tasten beim Drueberfahren (wie Clique sie
-- anbietet) brauchen Snippets oder Tastenbelegungen, die im Kampf
-- gesperrt sind - beides geht hier nicht. Kombinationen (Strg + Umschalt)
-- auch nicht: ein Mausklick, eine Zusatztaste.
--
-- JE KLASSE. Die Einstellungen gelten fuer den ganzen Account; Zauber
-- aber gehoeren einer Klasse (gelernt aus den Erinnerungen, 6.6.0.5).
-- Die Belegung wird deshalb je Klasse gespeichert.
--
-- RAENGE (6.6.2.0/6.6.2.1, Beta-Test: "die einzelnen Raenge auswaehlen
-- und nicht immer den hoechsten", dann: "ein Dropdown mit den Raengen,
-- wenn ich den Zauber waehle"). Hat ein Zauber mehrere Raenge, oeffnet
-- der Klick in der Tafel eine Liste am Symbol: "Hoechster Rang" legt ihn
-- ohne Rang auf die Taste - der Client wirkt dann den hoechsten, und ein
-- neu gelernter greift von selbst -, ein fester Rang (Mana sparen) legt
-- genau den. Gespeichert wird der Rang so, wie das Zauberbuch ihn nennt
-- ("Rang 3"), als Attribut steht dann "Erneuerung(Rang 3)" - dieselbe
-- Schreibweise wie in einem Makro.
--
-- KEINE EINGEBAUTE ZAUBERLISTE. Niemand hier hat die Zauber des
-- Forever-Clients gelesen - die Tafel zeigt, was das Zauberbuch des
-- Charakters nennt, und getippt wird nichts (Beta-Test: "einfach
-- auswaehlen").
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIClickCast = {}

local CC = WeintCodex.UIClickCast
local K = WeintCodex.UIKit
local C = WeintCodex.Colors
-- Die Einstellungen stehen im Modul der Gruppenrahmen (eigener Reiter):
-- die Seitenleiste des Einstellungsfensters hat keinen Platz fuer einen
-- weiteren Eintrag, und geheilt wird dort.
local KEY = "groupframes"
-- Die Belegung selbst liegt getrennt davon: "Standard" bei den
-- Gruppenrahmen setzt Groessen und Farben zurueck, nicht die Zauber
-- aller Klassen.
local STORE = "clickcast"

CC.BUTTONS = {
    { value = 1, text = "Linke Maustaste",   short = "Links" },
    { value = 2, text = "Rechte Maustaste",  short = "Rechts" },
    { value = 3, text = "Mittlere Maustaste", short = "Mitte" },
    { value = 4, text = "Maustaste 4",       short = "Maus 4" },
    { value = 5, text = "Maustaste 5",       short = "Maus 5" },
}
-- Seit 6.29.9.0 (Spieler: "Corsair Scimitar mit 12 Tasten"): Maustasten
-- 6 bis 12. Der Client nennt sie "Button6" usw.; das Attribut heisst dann
-- "type-Button6" (SecureButton_GetButtonSuffix), nicht "type6".
for n = 6, 12 do
    CC.BUTTONS[#CC.BUTTONS + 1] = { value = n, text = "Maustaste " .. n, short = "Maus " .. n }
end
-- 6.30.21.0 (Wunsch: "auch Scrollen, hoch und runter"): das Mausrad ist fuer
-- das Spiel eine Taste ("MOUSEWHEELUP") - es geht den Weg der Tasten
-- (Vorrang-Belegung, Zauber auf die Einheit unter der Maus).
CC.WHEEL = { MOUSEWHEELUP = "In", MOUSEWHEELDOWN = "Out" }
CC.BUTTONS[#CC.BUTTONS + 1] = { value = "MOUSEWHEELUP",   text = "Mausrad hoch",   short = "Mausrad hoch" }
CC.BUTTONS[#CC.BUTTONS + 1] = { value = "MOUSEWHEELDOWN", text = "Mausrad runter", short = "Mausrad runter" }
CC.MODS = {
    { value = "",       text = "ohne" },
    { value = "shift-", text = "Umschalt",  short = "Umschalt" },
    { value = "ctrl-",  text = "Strg",      short = "Strg" },
    { value = "alt-",   text = "Alt",       short = "Alt" },
}
CC.ACTIONS = {
    { value = "spell",  text = "Zauber" },
    { value = "target", text = "Ziel wählen" },
    { value = "menu",   text = "Menü" },
}
CC.DEFAULTS = {
    clickUnitFrames = true,   -- auch Spieler, Ziel, Fokus, ...
    clickTooltip    = true,   -- Belegung im Tooltip
    clickHelpfulOnly = true,  -- Tafel: nur hilfreiche Zauber
}

local function Opt(k) return K.Get(KEY, k) end

local function Short(list, v)
    for _, e in ipairs(list) do if e.value == v then return e.short or e.text end end
    return tostring(v)
end

local function PlayerClass()
    if not _G.UnitClass then return nil end
    local _, class = _G.UnitClass("player")
    return K.Plain(class)
end
CC._class = PlayerClass

--------------------------------------------------
-- Belegung
--------------------------------------------------

local function Copy(list)
    local out = {}
    for i, b in ipairs(list or {}) do
        out[i] = { button = b.button, mod = b.mod, action = b.action, spell = b.spell, rank = b.rank }
    end
    return out
end

-- Die Belegung dieser Klasse (Kopie ist nicht noetig: nur gelesen).
function CC.Bindings(class)
    class = class or PlayerClass() or "?"
    local all = K.Get(STORE, "bindings")   -- [Klasse] = { { button, mod, action, spell }, ... }
    return type(all) == "table" and type(all[class]) == "table" and all[class] or {}
end

function CC.SetBindings(list, class)
    class = class or PlayerClass() or "?"
    local all = {}
    local old = K.Get(STORE, "bindings")
    if type(old) == "table" then
        for c, l in pairs(old) do all[c] = Copy(l) end
    end
    all[class] = Copy(list)
    K.Set(STORE, "bindings", all)   -- meldet "setting" -> CC.Apply
end

-- Taste + Zusatztaste gibt es einmal: eine neue Belegung ersetzt die alte.
function CC.Add(b)
    local list = Copy(CC.Bindings())
    for i = #list, 1, -1 do
        if list[i].button == b.button and list[i].mod == b.mod then table.remove(list, i) end
    end
    list[#list + 1] = b
    table.sort(list, function(x, y)
        if x.button ~= y.button then
            -- Maustasten vor Tastatur-Tasten, dann nach Zahl bzw. Name.
            local nx, ny = type(x.button) == "number", type(y.button) == "number"
            if nx ~= ny then return nx end
            return x.button < y.button
        end
        return x.mod < y.mod
    end)
    CC.SetBindings(list)
end

function CC.Remove(i)
    local list = Copy(CC.Bindings())
    table.remove(list, i)
    CC.SetBindings(list)
end

-- Was wirklich auf den Rahmen kommt: deine Belegung, dazu Belegungen
-- anderer Teile (6.8.1.0: Entfluchen auf Klick, ui/dispel.lua) - aber nur
-- auf Tasten, die du nicht selbst belegt hast. Deine Wahl gewinnt immer.
function CC.Effective()
    local list = CC.Bindings()
    local extra = CC.ExtraBindings and CC.ExtraBindings()
    if type(extra) ~= "table" or #extra == 0 then return list end
    local out, taken = {}, {}
    for _, b in ipairs(list) do
        out[#out + 1] = b
        taken[b.mod .. b.button] = true
    end
    for _, b in ipairs(extra) do
        if not taken[b.mod .. b.button] then out[#out + 1] = b end
    end
    return out
end

-- Eine Belegung auf einer Tastatur-Taste ("1", "F", "NUMPAD3") statt
-- einer Maustaste: button ist dann der Name der Taste.
function CC.IsKey(b) return type(b.button) == "string" end

-- Was hinter "type" im Attribut steht: 1..5 wie gehabt, ab 6 "-Button6".
function CC.Suffix(n)
    if n <= 5 then return tostring(n) end
    return "-Button" .. n
end

-- "Umschalt + Links"
function CC.KeyText(b)
    local key
    if CC.WHEEL[b.button] then
        key = Short(CC.BUTTONS, b.button)
    elseif CC.IsKey(b) then
        local t = type(_G.GetBindingText) == "function" and _G.GetBindingText(b.button)
        key = "Taste " .. ((type(t) == "string" and t ~= "") and t or b.button)
    else
        key = Short(CC.BUTTONS, b.button)
    end
    if b.mod == "" then return key end
    return Short(CC.MODS, b.mod) .. " + " .. key
end

function CC.ActionText(b)
    if b.action == "spell" then
        local note = b.note and ("  –  " .. b.note) or ""
        if b.rank then return (b.spell or "?") .. " (" .. b.rank .. ")" .. note end
        return (b.spell or "?") .. note
    end
    return Short(CC.ACTIONS, b.action)
end

-- Was im Attribut steht: der Name (hoechster Rang) oder "Name(Rang 3)".
function CC.SpellAttr(b)
    if not b.spell then return nil end
    if b.rank then return b.spell .. "(" .. b.rank .. ")" end
    return b.spell
end

--------------------------------------------------
-- Auf die Rahmen
--------------------------------------------------

-- Was dieses Modul an einem Rahmen gesetzt hat - beim naechsten Mal wird
-- genau das wieder geloescht, dann greifen die Grundeinstellungen des
-- Rahmens ("*type1" = Ziel, "*type2" = Menue) von selbst.
local applied = setmetatable({}, { __mode = "k" })
local hooked = setmetatable({}, { __mode = "k" })

local ATTR_ACTION = { spell = "spell", target = "target", menu = "togglemenu" }

function CC.ApplyTo(f, list)
    if not (f and f.SetAttribute) then return end
    for _, key in ipairs(applied[f] or {}) do f:SetAttribute(key, nil) end
    local keys = {}
    for _, b in ipairs(list) do
        local kind = ATTR_ACTION[b.action]
        if kind and not CC.IsKey(b) and not (b.action == "spell" and not b.spell) then
            local t = b.mod .. "type" .. CC.Suffix(b.button)
            f:SetAttribute(t, kind)
            keys[#keys + 1] = t
            if b.action == "spell" then
                local s = b.mod .. "spell" .. CC.Suffix(b.button)
                f:SetAttribute(s, CC.SpellAttr(b))
                keys[#keys + 1] = s
            end
        end
    end
    applied[f] = keys
    CC.HookTooltip(f)
end

-- Jeder Rahmen, der eine Einheit zeigt.
-- OHNE OBERFLAECHE (seit 6.9.0.0 Komfort): laufen die Gruppenrahmen von
-- WeintCodex nicht, sind die Rahmen des Spiels die, auf die man klickt -
-- dann gilt die Belegung dort, ungestylt. Mit eigenen Kacheln nicht: die
-- Rahmen des Spiels sind dann versteckt.
function CC.GameFrames()
    local GG = WeintCodex.UIGameGroup
    if not GG then return false end
    return GG.active or not K.IsActive("groupframes")
end

function CC.Frames()
    local out = {}
    local GG = WeintCodex.UIGameGroup
    if CC.GameFrames() then
        for _, f in ipairs(GG.Frames()) do out[#out + 1] = f end
    end
    local GF = WeintCodex.UIGroupFrames
    if GF and GF.buttons then
        for _, b in ipairs(GF.buttons) do out[#out + 1] = b end
    end
    local UF = WeintCodex.UIUnitFrames
    if Opt("clickUnitFrames") and UF and UF.frames then
        for _, f in pairs(UF.frames) do out[#out + 1] = f end
    end
    return out
end

local pendingApply = false
function CC.Apply()
    if K.InCombat() then
        if not pendingApply then
            pendingApply = true
            K.AfterCombat(function() pendingApply = false CC.Apply() end)
        end
        return false
    end
    -- Seit 6.9.0.0 ein Teil des Komforts: ist der aus, gilt keine Belegung.
    local list = K.ModuleEnabled("comfort") and CC.Effective() or {}
    -- Nichts belegt und nie etwas gesetzt: die Rahmen des Spiels nicht
    -- einmal anfassen (kein Tooltip-Haken auf Rahmen, die niemand belegt).
    if #list == 0 and _G.next(applied) == nil then return true end
    local seen = {}
    for _, f in ipairs(CC.Frames()) do
        seen[f] = true
        CC.ApplyTo(f, list)
    end
    -- Einheitenrahmen abgeschaltet: was dort stand, wieder weg.
    for f in pairs(applied) do
        if not seen[f] then CC.ApplyTo(f, {}) end
    end
    CC.ApplyKeys(list)
    return true
end

--------------------------------------------------
-- Tastatur-Tasten (6.29.9.0)
--------------------------------------------------
-- Viele Mäuse mit vielen Tasten (Corsair Scimitar, Razer Naga) schicken
-- ihre Seitentasten als Tastatur-Tasten 1 bis 12 - als Maustaste kommen
-- sie nie an einem Rahmen an. Clique löst das mit Snippets beim
-- Drüberfahren; die fehlen dem Forever-Client. Was geht, ohne Snippet und
-- auch im Kampf: die Taste fest (ausserhalb des Kampfes gesetzt) auf
-- einen geschützten Knopf legen, der "/cast [@mouseover,exists] Zauber"
-- wirkt. Der Preis, offen gesagt: solange die Belegung steht, tut die
-- Taste nichts anderes mehr - und sie wirkt auf jede Einheit unter der
-- Maus, auch auf Plaketten und in der Welt, nicht nur auf Rahmen.

local keyOwner
local keyButtons = {}
CC.keyBound = {}   -- [Taste] = was darauf liegen soll

-- Liegen unsere Tasten noch? Beim ersten Einloggen laedt das Spiel die
-- Tastenbelegung erst NACH PLAYER_ENTERING_WORLD - was davor gesetzt war,
-- war danach weg. Gefragt wird nach jedem UPDATE_BINDINGS; neu gesetzt
-- nur, wenn etwas fehlt (unser Setzen loest selbst UPDATE_BINDINGS aus).
function CC.KeysIntact()
    local get = _G.GetBindingAction
    if type(get) ~= "function" then return true end
    for key, want in pairs(CC.keyBound) do
        local ok, have = pcall(get, key, true)
        if ok and have ~= want then return false end
    end
    return true
end

function CC.KeyMacro(b)
    local text
    if b.action == "spell" then
        local s = CC.SpellAttr(b)
        text = s and ("/cast [@mouseover,exists] " .. s) or nil
    elseif b.action == "target" then
        text = "/target [@mouseover,exists]"
    end
    -- Mausrad ohne Zusatztaste: die Belegung nimmt dem Spiel das Zoomen.
    -- Ohne Einheit unter der Maus zoomt die Kamera deshalb weiter.
    local dir = CC.WHEEL[b.button]
    if text and dir and (b.mod or "") == "" then
        text = text .. "\n/run if not UnitExists(\"mouseover\") then CameraZoom" .. dir .. "(1) end"
    end
    return text   -- Menü: ohne Snippet nicht über eine Taste zu öffnen
end

-- "shift-" + "1" -> "SHIFT-1", wie SetBinding es will.
function CC.BindingKey(b)
    return string.upper(b.mod or "") .. b.button
end

function CC.ApplyKeys(list)
    local set = type(_G.SetOverrideBindingClick) == "function"
    if not keyOwner then
        if not set then return 0 end
        keyOwner = CreateFrame("Frame", "WeintCodexClickKeys", UIParent)
    end
    if type(_G.ClearOverrideBindings) == "function" then _G.ClearOverrideBindings(keyOwner) end
    CC.keyBound = {}
    local n = 0
    for _, b in ipairs(list) do
        local text = CC.IsKey(b) and CC.KeyMacro(b)
        if text and set then
            n = n + 1
            local btn = keyButtons[n]
            if not btn then
                local ok, made = pcall(CreateFrame, "Button", "WeintCodexClickKey" .. n, UIParent,
                    "SecureActionButtonTemplate")
                if not ok then break end
                btn = made
                if btn.RegisterForClicks then btn:RegisterForClicks("AnyUp") end
                btn:SetAttribute("useOnKeyDown", false)
                btn:SetAttribute("type", "macro")
                keyButtons[n] = btn
            end
            btn:SetAttribute("macrotext", text)
            -- Vorrang (true): Leisten-Addons wie Bartender legen ihre
            -- Tasten ebenfalls als Vorrang-Belegung - wer nach uns kommt,
            -- gewinnt sonst (6.29.11.0, Spieler: "nach dem Einloggen ging
            -- der Zauber auf der Taste nicht mehr").
            _G.SetOverrideBindingClick(keyOwner, true, CC.BindingKey(b), "WeintCodexClickKey" .. n, "LeftButton")
            CC.keyBound[CC.BindingKey(b)] = "CLICK WeintCodexClickKey" .. n .. ":LeftButton"
        end
    end
    for i = n + 1, #keyButtons do keyButtons[i]:SetAttribute("macrotext", "") end
    CC.keyCount = n
    return n
end

--------------------------------------------------
-- Tooltip: was tut welche Taste hier?
--------------------------------------------------

function CC.TooltipLines()
    local out = {}
    for _, b in ipairs(CC.Effective()) do
        if b.action == "spell" then out[#out + 1] = { CC.KeyText(b), CC.ActionText(b) } end
    end
    return out
end

function CC.HookTooltip(f)
    if hooked[f] or not f.HookScript then return end
    hooked[f] = true
    f:HookScript("OnEnter", function(self)
        if not Opt("clickTooltip") then return end
        local tip = _G.GameTooltip
        if not (tip and tip.IsOwned and tip:IsOwned(self)) then return end
        local lines = CC.TooltipLines()
        if #lines == 0 then return end
        local a, d = C.accent, C.textMuted
        tip:AddLine(" ")
        tip:AddLine("Klickzauber", a[1], a[2], a[3])
        for _, l in ipairs(lines) do
            tip:AddDoubleLine(l[1], l[2], d[1], d[2], d[3], 1, 1, 1)
        end
        tip:Show()
    end)
end

--------------------------------------------------
-- Einstellungen: Reiter "Klickzauber" der Gruppenrahmen
--------------------------------------------------

--------------------------------------------------
-- Das Zauberbuch (6.6.0.7, Beta-Test: "nichts manuell eingeben - die
-- Zauber einfach in einer Liste auswaehlen")
--------------------------------------------------
-- Was im Zauberbuch steht, sagt der Client - keine eigene Liste. Je Name
-- einmal, seine Raenge darunter (`ranks`, aufsteigend; `id` ist die des
-- hoechsten - der Name wirkt ihn), ohne passive Zauber,
-- ohne Gilden- und versteckte Reiter. "Nur hilfreiche": fragt den Client
-- (C_Spell.IsSpellHelpful / IsHelpfulSpell); kann er es nicht sagen,
-- bleibt der Zauber drin - "weiss nicht" ist nicht "schaedlich".

local function Helpful(id, name)
    local cs = _G.C_Spell
    local f = (cs and cs.IsSpellHelpful) or _G.IsHelpfulSpell
    if not f then return nil end
    local ok, v = pcall(f, (cs and cs.IsSpellHelpful) and id or name)
    if not ok then return nil end
    return K.Bool(v, nil)
end

-- "Rang 3" -> 3. Andere Untertitel ("Rassenfaehigkeit", "Stufe 2" einer
-- Gestalt ohne Zahl ...) sind kein Rang.
function CC.RankNumber(sub)
    sub = K.Plain(sub)
    if type(sub) ~= "string" then return nil end
    return tonumber(sub:match("(%d+)%s*$"))
end

local function Add(out, seen, id, name, icon, sub)
    name = K.Plain(name)
    if type(name) ~= "string" or name == "" then return end
    id = K.Plain(id)
    if type(sub) == "nil" and type(id) == "number" then
        local cs = _G.C_Spell
        local get = (cs and cs.GetSpellSubtext) or _G.GetSpellSubtext
        if get then
            local ok, v = pcall(get, id)
            if ok then sub = v end
        end
    end
    local n = CC.RankNumber(sub)
    local sp = seen[name]
    if not sp then
        sp = { id = id, name = name, icon = K.Plain(icon), ranks = {}, top = n or 0 }
        seen[name] = sp
        out[#out + 1] = sp
    elseif (n or 0) > sp.top then
        sp.id, sp.top = id or sp.id, n
    end
    if n then
        for _, r in ipairs(sp.ranks) do if r.n == n then return end end
        sp.ranks[#sp.ranks + 1] = { id = id, rank = K.Plain(sub), n = n }
        table.sort(sp.ranks, function(a, b) return a.n < b.n end)
    end
end

function CC.Spellbook(helpfulOnly)
    local out, seen = {}, {}
    local sb = _G.C_SpellBook
    local E = _G.Enum
    local bank = E and E.SpellBookSpellBank and E.SpellBookSpellBank.Player
    local SPELL = E and E.SpellBookItemType and E.SpellBookItemType.Spell
    if sb and sb.GetNumSpellBookSkillLines and sb.GetSpellBookSkillLineInfo and sb.GetSpellBookItemInfo then
        local okN, n = pcall(sb.GetNumSpellBookSkillLines)
        for line = 1, (okN and K.Plain(n) or 0) do
            local okL, info = pcall(sb.GetSpellBookSkillLineInfo, line)
            if okL and type(info) == "table" and not K.Bool(info.isGuild, false)
               and not K.Bool(info.shouldHide, false) and not ((K.Plain(info.offSpecID) or 0) > 0) then
                local first = K.Plain(info.itemIndexOffset) or 0
                for slot = first + 1, first + (K.Plain(info.numSpellBookItems) or 0) do
                    local okI, it = pcall(sb.GetSpellBookItemInfo, slot, bank)
                    if okI and type(it) == "table" and not K.Bool(it.isPassive, false)
                       and (SPELL == nil or K.Plain(it.itemType) == SPELL) then
                        Add(out, seen, it.spellID, it.name, it.iconID, it.subName)
                    end
                end
            end
        end
    elseif _G.GetNumSpellTabs and _G.GetSpellTabInfo and _G.GetSpellBookItemName then
        for tab = 1, K.Plain(_G.GetNumSpellTabs()) or 0 do
            local _, _, offset, count = _G.GetSpellTabInfo(tab)
            offset, count = K.Plain(offset) or 0, K.Plain(count) or 0
            for slot = offset + 1, offset + count do
                local kind, id = nil, nil
                if _G.GetSpellBookItemInfo then kind, id = _G.GetSpellBookItemInfo(slot, "spell") end
                local passive = _G.IsPassiveSpell and K.Bool(_G.IsPassiveSpell(slot, "spell"), false)
                if (kind == nil or K.Plain(kind) == "SPELL") and not passive then
                    local name, sub = _G.GetSpellBookItemName(slot, "spell")
                    local icon = _G.GetSpellTexture and _G.GetSpellTexture(slot, "spell")
                    Add(out, seen, id, name, icon, sub)
                end
            end
        end
    end
    if helpfulOnly then
        local keep = {}
        for _, sp in ipairs(out) do
            if Helpful(sp.id, sp.name) ~= false then keep[#keep + 1] = sp end
        end
        out = keep
    end
    table.sort(out, function(a, b) return a.name < b.name end)
    return out
end

-- Welche Taste bekommt den naechsten Klick in der Tafel.
local draft = { button = 1, mod = "shift-" }
CC.draft = draft

-- Ein Klick in der Tafel: legt Zauber (oder Ziel/Menue) auf die Taste.
-- rank: "Rang 3" wie im Zauberbuch; nil oder "" = der hoechste.
function CC.Pick(action, spell, rank)
    local b = { button = draft.button, mod = draft.mod, action = action }
    if action == "spell" then
        if type(spell) ~= "string" or spell == "" then return false end
        b.spell = spell
        if type(rank) == "string" and rank ~= "" then b.rank = rank end
    end
    CC.Add(b)
    return true
end

-- Was liegt gerade auf der Taste, die oben gewaehlt ist?
function CC.Current()
    for _, b in ipairs(CC.Bindings()) do
        if b.button == draft.button and b.mod == draft.mod then return b end
    end
    return nil
end

-- Die Raenge eines Zaubers, wie das Zauberbuch sie nennt (aufsteigend).
function CC.Ranks(name)
    for _, sp in ipairs(CC.Spellbook(false)) do
        if sp.name == name then return sp.ranks end
    end
    return {}
end

-- Die Liste, die ein Klick auf einen Zauber mit mehreren Raengen
-- oeffnet: "Hoechster" (der Name allein, steigt mit) und jeder Rang.
function CC.RankItems(name)
    local items = { { value = "", text = "Höchster Rang – steigt mit" } }
    for _, r in ipairs(CC.Ranks(name)) do
        items[#items + 1] = { value = r.rank, text = r.rank }
    end
    return items
end

-- Klick auf ein Zaubersymbol: ein Rang -> sofort auf die Taste, mehrere
-- -> erst die Liste am Symbol, die Wahl legt ihn dann.
function CC.PickSpell(owner, e)
    local ranks = e.ranks or {}
    local open = WeintCodex.OpenDropMenu
    if #ranks < 2 or not open then return CC.Pick("spell", e.name) end
    local cur = CC.Current()
    local current = (cur and cur.action == "spell" and cur.spell == e.name) and (cur.rank or "") or nil
    open(owner, CC.RankItems(e.name), current, function(v) CC.Pick("spell", e.name, v) end, 190)
    return true
end

local LIST_ROWS = 10
function CC.BuildList(parent, width)
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
        row.key = K.NewText(row, 12)
        row.key:SetPoint("LEFT", row.icon, "RIGHT", 8, 0)
        row.key:SetWidth(150)
        row.key:SetJustifyH("LEFT")
        row.key:SetWordWrap(false)
        row.key:SetTextColor(unpack(C.textMuted))
        row.text = K.NewText(row, 12)
        row.text:SetPoint("LEFT", row.key, "RIGHT", 8, 0)
        row.text:SetPoint("RIGHT", row, "RIGHT", -96, 0)
        row.text:SetJustifyH("LEFT")
        row.text:SetWordWrap(false)
        local idx = i
        row.remove = WeintCodex.CreateButton(row, { text = "Entfernen", kind = "secondary", height = 20, size = 10,
            onClick = function() CC.Remove(idx) end })
        row.remove:SetPoint("RIGHT", row, "RIGHT", -2, 0)
        w.rows[i] = row
    end
    w.more = K.NewText(w, 11)
    w.more:SetPoint("TOPLEFT", w, "TOPLEFT", 4, -LIST_ROWS * 26)
    w.empty = K.NewText(w, 12)
    w.empty:SetPoint("TOPLEFT", w, "TOPLEFT", 4, -6)
    w.empty:SetWidth(math.max(100, width - 8))
    w.empty:SetText("Noch nichts belegt. Unten Taste wählen und einen Zauber anklicken – zum Beispiel Umschalt + Links: dein kleiner Heilzauber.")
    w.empty:SetTextColor(unpack(C.textDim))
    w.Sync = function()
        local list = CC.Bindings()
        local R = WeintCodex.UIReminders
        for i, row in ipairs(w.rows) do
            local b = list[i]
            if b then
                row.key:SetText(CC.KeyText(b))
                row.text:SetText(CC.ActionText(b))
                local sp = b.action == "spell" and R and R.Resolve and R.Resolve(b.spell)
                if sp and sp.icon then row.icon:SetTexture(sp.icon) row.icon:Show() else row.icon:Hide() end
                row:Show()
            else
                row:Hide()
            end
        end
        local extra = #list - LIST_ROWS
        w.more:SetText(extra > 0 and ("… und " .. extra .. " weitere") or "")
        w.empty:SetShown(#list == 0)
    end
    return w
end


-- DIE ZAUBERTAFEL: oben die gewaehlte Taste in Worten, darunter "Ziel
-- waehlen", "Menue" und die Symbole aus dem Zauberbuch als Raster. Ein
-- Klick legt, was er trifft, auf die Taste; was dort schon liegt, ist
-- im Akzent umrandet. Die Hoehe steht fest (die Seite springt nicht):
-- PICK_ROWS Reihen, was darueber hinausgeht, wird gezaehlt und genannt.
local TILE, TILE_GAP, PICK_ROWS = 30, 4, 6
CC.PICK_ROWS = PICK_ROWS
local SPECIAL = {
    { action = "target", name = "Ziel wählen", icon = K.MEDIA .. "targetmark" },
    { action = "menu",   name = "Menü",        icon = K.MEDIA .. "icon_gear" },
}

function CC.PickerHeight() return 22 + PICK_ROWS * (TILE + TILE_GAP) + 16 end

function CC.BuildPicker(parent, width)
    local w = CreateFrame("Frame", nil, parent)
    local perRow = math.max(4, math.floor((width + TILE_GAP) / (TILE + TILE_GAP)))
    local cap = perRow * PICK_ROWS
    w.perRow, w.tiles = perRow, {}
    w.head = K.NewText(w, 12)
    w.head:SetPoint("TOPLEFT", w, "TOPLEFT", 0, 0)
    w.head:SetWidth(width)
    w.head:SetJustifyH("LEFT")
    w.more = K.NewText(w, 11)
    w.more:SetPoint("TOPLEFT", w, "TOPLEFT", 0, -(22 + PICK_ROWS * (TILE + TILE_GAP)))
    w.more:SetWidth(width)
    w.more:SetJustifyH("LEFT")
    w.more:SetTextColor(unpack(C.textDim))
    local function Tile(i)
        local t = CreateFrame("Button", nil, w)
        t:SetSize(TILE, TILE)
        local col, row = (i - 1) % perRow, math.floor((i - 1) / perRow)
        t:SetPoint("TOPLEFT", w, "TOPLEFT", col * (TILE + TILE_GAP), -(22 + row * (TILE + TILE_GAP)))
        t.bg = t:CreateTexture(nil, "BACKGROUND")
        t.bg:SetAllPoints(t)
        t.bg:SetColorTexture(unpack(C.surface2))
        t.icon = t:CreateTexture(nil, "ARTWORK")
        t.icon:SetPoint("TOPLEFT", t, "TOPLEFT", 1, -1)
        t.icon:SetPoint("BOTTOMRIGHT", t, "BOTTOMRIGHT", -1, 1)
        t.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        local hc = K.Highlight()
        t.ring = K.Border(t, 2, hc[1], hc[2], hc[3], 1, "OVERLAY")
        t:SetScript("OnClick", function(self)
            local e = self.entry
            if not e then return end
            if e.action then CC.Pick(e.action) else CC.PickSpell(self, e) end
        end)
        t:SetScript("OnEnter", function(self)
            local e = self.entry
            if not e then return end
            local tip = _G.GameTooltip
            tip:SetOwner(self, "ANCHOR_TOP")
            if e.id and tip.SetSpellByID then tip:SetSpellByID(e.id) else tip:SetText(e.name, 1, 1, 1) end
            local a = C.accent
            tip:AddLine("Klick: auf " .. CC.KeyText(draft) .. " legen", a[1], a[2], a[3])
            local ranks = e.ranks or {}
            if #ranks > 1 then
                local d = C.textMuted
                tip:AddLine(string.format("%d Ränge – Klick öffnet die Auswahl", #ranks), d[1], d[2], d[3])
            end
            tip:Show()
        end)
        t:SetScript("OnLeave", function() _G.GameTooltip:Hide() end)
        return t
    end
    w.Sync = function()
        local cur = CC.Current()
        w.head:SetText(CC.KeyText(draft) .. ":  " .. (cur and CC.ActionText(cur) or "frei")
            .. "   –   Klick auf einen Zauber legt ihn auf diese Taste.")
        local entries = {}
        for _, e in ipairs(SPECIAL) do entries[#entries + 1] = e end
        local book = CC.Spellbook(Opt("clickHelpfulOnly"))
        for _, sp in ipairs(book) do entries[#entries + 1] = sp end
        for i = 1, math.min(#entries, cap) do
            local t = w.tiles[i] or Tile(i)
            w.tiles[i] = t
            local e = entries[i]
            t.entry = e
            t.icon:SetTexture(e.icon)
            local on = cur and ((e.action and cur.action == e.action)
                or (not e.action and cur.action == "spell" and cur.spell == e.name))
            t.ring:SetShown(on and true or false)
            t:Show()
        end
        for i = #entries + 1, #w.tiles do w.tiles[i]:Hide() end
        if #book == 0 then
            w.more:SetText("Im Zauberbuch steht noch nichts, das der Client nennt – nach dem Einloggen noch einmal öffnen.")
        elseif #entries > cap then
            w.more:SetText(string.format("… und %d weitere – „Nur hilfreiche Zauber“ kürzt die Tafel.", #entries - cap))
        else
            w.more:SetText("")
        end
    end
    return w
end

local function DraftChanged() K.Fire("setting", KEY, "clickDraft") end

--------------------------------------------------
-- Taste zuweisen: Maus drüber, Taste drücken (6.29.9.0)
--------------------------------------------------
-- Spieler: "einen Bereich, über den man mit der Maus geht und dann die
-- Taste drückt". Statt Dropdowns mit Namen, die keiner Maus aufgedruckt
-- sind: die Fläche nimmt jede Maustaste (1-12) und, solange die Maus über
-- ihr steht, jede Tastatur-Taste - mit der gehaltenen Zusatztaste.

local MOUSE = { LeftButton = 1, RightButton = 2, MiddleButton = 3 }
local MODKEYS = { LSHIFT = true, RSHIFT = true, LCTRL = true, RCTRL = true, LALT = true, RALT = true,
                  LMETA = true, RMETA = true }

local function HeldMod()
    if _G.IsShiftKeyDown and _G.IsShiftKeyDown() then return "shift-" end
    if _G.IsControlKeyDown and _G.IsControlKeyDown() then return "ctrl-" end
    if _G.IsAltKeyDown and _G.IsAltKeyDown() then return "alt-" end
    return ""
end

-- Was die Fläche aus einem Druck macht: Maustaste -> Zahl, Taste -> Name;
-- nil = nicht belegbar (Zusatztaste allein, Escape, Maustaste über 12).
function CC.CaptureValue(input, isMouse)
    if type(input) ~= "string" or input == "" then return nil end
    if isMouse then
        if MOUSE[input] then return MOUSE[input] end
        local n = tonumber(input:match("^Button(%d+)$"))
        if n and n >= 4 and n <= 12 then return n end
        return nil
    end
    if MODKEYS[input] or input == "ESCAPE" or input == "UNKNOWN" then return nil end
    return input
end

function CC.Capture(input, isMouse, mod)
    local v = CC.CaptureValue(input, isMouse)
    if v == nil then return false end
    draft.button, draft.mod = v, mod or HeldMod()
    DraftChanged()
    return true
end

function CC.BuildCapture(parent, width)
    local f = CreateFrame("Button", nil, parent)
    f:SetSize(width, 34)
    f.bg = f:CreateTexture(nil, "BACKGROUND")
    f.bg:SetAllPoints(f)
    f.bg:SetColorTexture(unpack(C.surface2))
    local hc = K.Highlight()
    f.ring = K.Border(f, 1, hc[1], hc[2], hc[3], 1, "OVERLAY")
    f.ring:SetShown(false)
    f.text = K.NewText(f, 12)
    f.text:SetPoint("LEFT", f, "LEFT", 10, 0)
    f.text:SetPoint("RIGHT", f, "RIGHT", -10, 0)
    f.text:SetJustifyH("LEFT")
    f.text:SetWordWrap(false)
    if f.RegisterForClicks then f:RegisterForClicks("AnyUp") end
    local function Sync()
        if f.hover then
            f.text:SetText(CC.KeyText(draft) .. "   –   jetzt drücken oder scrollen: Maustaste, Mausrad oder Taste, gern mit Umschalt, Strg oder Alt")
        else
            f.text:SetText("Taste zuweisen:  " .. CC.KeyText(draft) .. "   –   Maus hierher, dann die Taste drücken.")
        end
    end
    f.Sync = Sync
    f:SetScript("OnEnter", function(self)
        self.hover = true
        self.ring:SetShown(true)
        -- Tastatur nur ausserhalb des Kampfes: dort ist das Weiterreichen
        -- der Tasten (SetPropagateKeyboardInput) erlaubt.
        if not K.InCombat() and self.EnableKeyboard then
            self:EnableKeyboard(true)
            if self.SetPropagateKeyboardInput then self:SetPropagateKeyboardInput(false) end
        end
        Sync()
    end)
    f:SetScript("OnLeave", function(self)
        self.hover = false
        self.ring:SetShown(false)
        if not K.InCombat() and self.EnableKeyboard then self:EnableKeyboard(false) end
        Sync()
    end)
    f:SetScript("OnMouseDown", function(_, button) CC.Capture(button, true) end)
    if f.EnableMouseWheel then f:EnableMouseWheel(true) end
    f:SetScript("OnMouseWheel", function(_, delta)
        CC.Capture((delta or 0) > 0 and "MOUSEWHEELUP" or "MOUSEWHEELDOWN", false)
    end)
    f:SetScript("OnKeyDown", function(self, key)
        -- Escape schliesst weiter das Fenster, Zusatztasten allein warten.
        local pass = not CC.CaptureValue(key, false)
        if self.SetPropagateKeyboardInput and not K.InCombat() then self:SetPropagateKeyboardInput(pass) end
        if not pass then CC.Capture(key, false) end
    end)
    f:SetScript("OnHide", function(self)
        self.hover = false
        if not K.InCombat() and self.EnableKeyboard then self:EnableKeyboard(false) end
    end)
    Sync()
    return f
end

function CC.BuildPage(B)
    local class = PlayerClass()
    local label = class and WeintCodex.Names and WeintCodex.Names.ClassLabel(class) or "deine Klasse"
    B:Section("Belegung – " .. tostring(label),
        "Klick mit Taste auf einen Gruppen- oder Schlachtzugsrahmen (auch die des Spiels, wenn du die Oberfläche nicht nutzt) wirkt den Zauber auf diese Einheit – ohne sie erst anzuwählen. Gilt für diese Klasse. Im Kampf änderst du nichts; es greift danach.")
    B:Row({ type = "custom", height = LIST_ROWS * 26 + 18, create = function(parent, width)
                return CC.BuildList(parent, width)
            end }, nil)
    B:Section("Neue Belegung", "Erst die Taste zuweisen – Maus auf das Feld, Taste drücken –, dann den Zauber anklicken.")
    B:Row({ type = "custom", height = 34, create = function(parent, width)
                return CC.BuildCapture(parent, width)
            end }, nil)
    B:Row({ type = "dropdown", label = "Maustaste", items = CC.BUTTONS,
            get = function()
                if type(draft.button) == "number" or CC.WHEEL[draft.button] then return draft.button end
                return nil
            end,
            set = function(v) draft.button = v DraftChanged() end },
          { type = "dropdown", label = "Zusatztaste", items = CC.MODS,
            get = function() return draft.mod end, set = function(v) draft.mod = v DraftChanged() end })
    B:Row({ type = "custom", height = CC.PickerHeight(), create = function(parent, width)
                return CC.BuildPicker(parent, width)
            end }, nil)
    B:Row({ type = "toggle", label = "Nur hilfreiche Zauber", key = "clickHelpfulOnly",
            description = "Heilungen, Buffs, Bannen – was man auf Verbündete wirkt." },
          { type = "empty" })
    local DP = WeintCodex.UIDispel
    if DP and DP.BuildSection then DP.BuildSection(B) end
    B:Section("Wo")
    B:Row({ type = "toggle", label = "Auch Einheitenrahmen", key = "clickUnitFrames",
            description = "Spieler, Ziel, Fokus, Ziel des Ziels und Begleiter von WeintCodex – nur mit der Oberfläche." },
          { type = "toggle", label = "Belegung im Tooltip", key = "clickTooltip",
            description = "Maus über einem Rahmen zeigt, welche Taste welchen Zauber wirkt." })
    B:Note("Links ohne Zusatztaste wählt sonst das Ziel, Rechts öffnet das Menü – belegst du sie, gilt deine Belegung. Maustasten 6 bis 12 wirken auf dem Rahmen wie Links und Rechts. Schickt deine Maus ihre Seitentasten als Tastatur-Tasten (Corsair Scimitar, Razer Naga ab Werk), wirkt die Taste auf die Einheit unter der Maus – überall, auch auf Plaketten – und tut sonst nichts mehr, solange sie belegt ist. Das Menü geht nur mit Maustasten, Kombinationen wie Strg + Umschalt gar nicht.")
end

-- Die Standardwerte stehen bei den Gruppenrahmen (dort waren sie immer;
-- gespeicherte Werte bleiben). Die SEITE steht seit 6.9.0.0 im Komfort
-- (ui/comfort.lua haengt sie an) - Klickzauber gehen auch ohne Oberflaeche.
do
    local m = K.Module(KEY)
    if m then
        for k, v in pairs(CC.DEFAULTS) do m.defaults[k] = v end
    end
end

-- Anwenden: nach dem Einloggen (die Rahmen stehen dann), bei jeder
-- Aenderung der Einstellungen und nach einem Klassenwechsel des Kontos
-- (neuer Charakter = neues Einloggen).
K.Listen(function(kind, module, key)
    if kind ~= "setting" then return end
    if module == STORE or (module == KEY and key ~= "clickDraft")
       or (module == "comfort" and key == "enabled") then CC.Apply() end
end)
-- Ohne die Gruppenrahmen von WeintCodex entstehen die Rahmen des Spiels,
-- wenn die Gruppe waechst - dann neu anwenden (mit ihnen erledigt das
-- ui/gamegroup.lua). Kurz gesammelt: ein Gruppenwechsel kommt selten allein.
local applyLater = false
local function ApplySoon()
    if applyLater then return end
    applyLater = true
    local function run() applyLater = false CC.Apply() end
    if _G.C_Timer and _G.C_Timer.After then _G.C_Timer.After(0.3, run) else run() end
end
CC.ApplySoon = ApplySoon

local ev = CreateFrame("Frame")
for _, e in ipairs({ "PLAYER_ENTERING_WORLD", "GROUP_ROSTER_UPDATE", "UPDATE_BINDINGS" }) do
    pcall(ev.RegisterEvent, ev, e)
end
ev:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_ENTERING_WORLD" then
        CC.Apply()
        -- Nach dem Laden der Tastenbelegung noch einmal (siehe CC.KeysIntact).
        if _G.C_Timer and _G.C_Timer.After then _G.C_Timer.After(2, ApplySoon) end
        return
    end
    if event == "UPDATE_BINDINGS" then
        if not CC.KeysIntact() then ApplySoon() end
        return
    end
    local GG = WeintCodex.UIGameGroup
    if not (GG and GG.active) then ApplySoon() end
end)
