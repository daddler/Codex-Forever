--------------------------------------------------
-- WeintCodex :: Oberflaeche - Eigener Abklingzeitmanager
--------------------------------------------------
-- Wunsch des Spielers: "Ein komplett eigener Abklingzeitmanager fuer alle
-- Klassen, als Alternative zu dem von Blizzard (der ist schwer
-- einzustellen). Gute Voreinstellungen sollen schon drin sein, leicht zu
-- bedienen und einzustellen. Alles optional zum normalen
-- Abklingzeitenmanager. Es muss also auch im Einstellungsbereich erkennbar
-- sein, ob Blizzards Abklingzeitenmanager genutzt werden moechte oder
-- WeintCodex Abklingzeitenmanager."
--
-- DIE WAHL (je Charakter, K.CharState().ocd.mode):
--   "blizzard"  - der Manager des Spiels (ab Werk; aendert nichts).
--   "weintcodex"- drei eigene Reihen; die Anzeige des Spiels wird ueber
--                 seine eigene Einstellung "cooldownViewerEnabled"
--                 ausgeschaltet - ueber PF.SetCVar (Wert von vorher
--                 gemerkt) und beim Zurueckwechseln mit PF.Release
--                 zurueckgegeben, nur wenn noch UNSER Wert steht.
--   "off"       - keiner: unsere Reihen aus, die des Spiels ebenso
--                 (ebenfalls gemerkt und zurueckgegeben).
-- Nie im Kampf umgestellt.
--
-- DIE REIHEN: "Wichtig" (gross), "Weitere" (kleiner), "Buffs" (eigene
-- Buffs mit Restzeit aus ui/bufftimes.lua - WeintCodex rechnet sie aus
-- dem Wirken, weil der Client im Kampf keine Auren herausgibt). Lage aus
-- ui/layout.lua, verschiebbar im Gestaltungsmodus.
--
-- ZAEHLWERK: die Uhr des Spiels. C_Spell.GetSpellCooldownDuration ->
-- Cooldown:SetCooldownFromDurationObject, sonst SetCooldown mit den
-- Werten des Clients - beide zeichnen auch geheime Werte, ohne dass
-- WeintCodex sie liest (wie die Abklingzeit-Symbole der Erinnerungen).
-- "Bereit" (Leuchten) nur, wenn der Client die Dauer offen nennt: eine
-- geheime Dauer ist "weiss nicht", nie "bereit". UNGEMESSEN auf Forever:
-- ob die Dauer im Kampf geheim ist (dann leuchtet im Kampf nichts).
--
-- VOREINSTELLUNG je Klasse: die Reihen "Wichtig" und "Hilfreich" aus
-- ui/cdmsetup.lua (CS.LISTS, Zaubernummern aus Classic wie im
-- Lehrerbestand, load_test.lua prueft). Weitere Zauber mit Abklingzeit aus
-- dem Lehrerbestand (GetSpellBaseCooldown >= 2 s) stehen in der Liste und
-- sind ab Werk aus. Gezeigt wird nur, was der Charakter gelernt hat
-- (Nummer der Rangkette oder ueber den Namen - Forever-Nummern weichen
-- von Classic ab).
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIOwnCooldowns = {}

local OC = WeintCodex.UIOwnCooldowns
local K = WeintCodex.UIKit
local C = WeintCodex.Colors
local KEY = "reminders"
local CVAR = "cooldownViewerEnabled"

OC.SOURCE = { kind = "classic", label = "Voreinstellung aus Classic (Lehrerbestand)" }
OC.MODES = {
    { value = "blizzard",   text = "Blizzard (Manager des Spiels)" },
    { value = "weintcodex", text = "WeintCodex (eigener Manager)" },
    { value = "off",        text = "Keiner" },
}
-- 6.106.0.0 (Wunsch: "ab Werk an soll der Abklingzeitmanager von WeintCodex sein").
OC.DEFAULT_MODE = "weintcodex"
OC.SLOTS = { "big", "small", "off" }
OC.SLOT_TEXT = { big = "Wichtig", small = "Weitere", off = "Aus" }
OC.MAX_EXTRA = 6     -- eigene Reihen (6.98.0.0)
OC.COLS_PER_BAND = 3 -- Spalten je Band in den Einstellungen
-- 1.0.7.0: alles Neue ab Werk AUS (Wunsch: bestehende Oberflaechen
-- sollen nach dem Update unveraendert bleiben) - einschalten unter Erweitert.
OC.DEFAULTS = { big = 40, small = 28, buff = 28, combatOnly = false, numbers = true, glow = true, buffs = true, debuffs = false, dbfHighlight = false, cursorCd = false, gcd = false, coTank = false, swing = false, gearBar = false, trinketBar = false, consumables = false, druidMana = false, focusCast = false, stealthWarn = false, attuneTracker = false, vertical = false, perLine = 0,
    glowColor = "green", glowStrength = 100, glowPulse = true }
OC.MAX_LIST = 80
OC.MIN_BASE_CD = 2000   -- ms; darunter ist es die globale Abklingzeit

local function Plain(v) return K.Plain(v) end

--------------------------------------------------
-- Gespeichertes (je Charakter, nie in einer Ersatztabelle)
--------------------------------------------------

local function Mem()
    local st = K.CharState and K.CharState()
    if not st then return nil end
    st.ocd = st.ocd or {}
    st.ocd.spells = st.ocd.spells or {}
    st.ocd.order = st.ocd.order or {}     -- Reihenfolge per Ziehen (Schluessel)
    st.ocd.custom = st.ocd.custom or {}   -- selbst hinzugefuegt: { kind = "spell"|"item", id }
    st.ocd.rank = st.ocd.rank or {}       -- je Zauber gewaehlter Rang (Nummer)
    st.ocd.glowOf = st.ocd.glowOf or {}   -- je Zauber Leuchten an/aus (nil = Vorgabe)
    st.ocd.sound = st.ocd.sound or {}     -- je Zauber Ton, wenn bereit
    st.ocd.display = st.ocd.display or {} -- je Zauber "bar" (Balken) oder nil (Symbol), 1.0.9.0
    st.ocd.barColor = st.ocd.barColor or {} -- je Zauber Farbe der Wirkung im Balken
    return st.ocd
end
OC.Mem = Mem

function OC.Get(k)
    local m = Mem()
    local v = m and m[k]
    if v == nil then
        if k == "mode" then return OC.DEFAULT_MODE end
        return OC.DEFAULTS[k]
    end
    return v
end

function OC.Set(k, v)
    local m = Mem()
    if not m then return false end
    m[k] = v
    OC.Refresh()
    return true
end

--------------------------------------------------
-- Eigene Reihen (6.98.0.0, Wunsch: "noch mehr Abklingzeitenreihen
-- erstellen und benennen"). m.rowsDef = { { id = "r1", name, size } }.
-- Jede Reihe ist eine Spalte in den Einstellungen und ein Rahmen im
-- Gestaltungsmodus ("ocd_x_<id>").
--------------------------------------------------
function OC.ExtraRows()
    local m = Mem()
    if not m then return {} end
    m.rowsDef = m.rowsDef or {}
    return m.rowsDef
end
function OC.ExtraDef(id)
    if type(id) ~= "string" then return nil end
    for _, d in ipairs(OC.ExtraRows()) do if d.id == id then return d end end
    return nil
end
local slotList = {}
function OC.Slots()
    for i = #slotList, 1, -1 do slotList[i] = nil end
    slotList[1], slotList[2] = "big", "small"
    for _, d in ipairs(OC.ExtraRows()) do slotList[#slotList + 1] = d.id end
    slotList[#slotList + 1] = "off"
    return slotList
end
function OC.SlotText(slot)
    local t = OC.SLOT_TEXT[slot]
    if t then return t end
    local d = OC.ExtraDef(slot)
    return d and d.name or "?"
end
function OC.NextSlot(cur)
    local list = OC.Slots()
    for i, k in ipairs(list) do if k == cur then return list[i % #list + 1] end end
    return "big"
end
function OC.AddRow(name)
    local defs = OC.ExtraRows()
    if #defs >= OC.MAX_EXTRA then return false, "Höchstens " .. OC.MAX_EXTRA .. " eigene Reihen." end
    name = type(name) == "string" and name:gsub("^%s+", ""):gsub("%s+$", "") or ""
    if name == "" then name = "Reihe " .. (#defs + 1) end
    local n, id = 1, nil
    repeat id = "r" .. n n = n + 1 until not OC.ExtraDef(id)
    defs[#defs + 1] = { id = id, name = name, size = 32 }
    OC.Refresh()
    return true
end
function OC.RenameRow(id, name)
    local d = OC.ExtraDef(id)
    if not d or type(name) ~= "string" or name:match("^%s*$") then return false end
    d.name = name:gsub("^%s+", ""):gsub("%s+$", "")
    if OC.extraRows and OC.extraRows[id] and K.RegisterMover then
        K.RegisterMover(OC.extraRows[id], "ocd_x_" .. id, "Abklingzeiten: " .. d.name, OC.ExtraDefault(id))
    end
    OC.Refresh()
    return true
end
function OC.RemoveRow(id)
    local m = Mem()
    local defs = OC.ExtraRows()
    for i = #defs, 1, -1 do if defs[i].id == id then table.remove(defs, i) end end
    -- Zauber der Reihe zurueck nach "Weitere"
    if m then for k, v in pairs(m.spells) do if v == id then m.spells[k] = "small" end end end
    OC.Refresh()
end
function OC.SetRowSize(id, size) OC.SetRowOpt(id, "size", size) end
function OC.ExtraDefault(id)
    local idx = 1
    for i, d in ipairs(OC.ExtraRows()) do if d.id == id then idx = i end end
    return K.Layout("ocd_buffs", 0, 40 * idx)
end

function OC.Mode() return OC.Get("mode") end
function OC.Active() return OC.Mode() == "weintcodex" end

--------------------------------------------------
-- Die Wahl Blizzard / WeintCodex / keiner
--------------------------------------------------

local function PF() return WeintCodex.UIProfile end

local function GameOn()
    local P = PF()
    local v = P and P.GetCVar and P.GetCVar(CVAR)
    if v == nil then return nil end
    return tonumber(v) ~= 0
end
OC.GameOn = GameOn

-- Die Anzeige des Spiels so stellen, wie die Wahl es will.
function OC.ApplyGame(mode)
    local P = PF()
    if not (P and P.SetCVar and P.Release) then return false end
    if mode == "weintcodex" or mode == "off" then
        return P.SetCVar(CVAR, "0", KEY)
    end
    -- Blizzard: unseren Wert zurueckgeben; steht danach noch "aus", hat der
    -- Spieler eben Blizzard gewaehlt - also an.
    P.Release(CVAR)
    if GameOn() == false then
        local CD = WeintCodex.UICooldowns
        if CD and CD.SetGameEnabled then CD.SetGameEnabled(true) end
    end
    return true
end

function OC.SetMode(mode)
    if mode ~= "blizzard" and mode ~= "weintcodex" and mode ~= "off" then return false end
    if K.InCombat() then
        print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " Im Kampf – Abklingzeitmanager nicht umgestellt.")
        return false
    end
    local m = Mem()
    if not m then return false end
    m.mode = mode
    OC.ApplyGame(mode)
    if mode == "weintcodex" then OC.Scan() end
    OC.Refresh()
    return true
end

--------------------------------------------------
-- Welche Zauber
--------------------------------------------------

-- Rang vom Client ("Rang 3"), sonst nichts (6.90.1.0, Wunsch).
local function SpellRank(id)
    local cs = _G.C_Spell
    local f = (cs and cs.GetSpellSubtext) or _G.GetSpellSubtext
    if not f then return nil end
    local ok, r = pcall(f, id)
    r = ok and Plain(r) or nil
    if type(r) == "string" and r ~= "" then return r end
    return nil
end
OC.SpellRank = SpellRank

OC.SpellRank = function(id) return SpellRank(id) end
local function SpellName(id)
    local cs = _G.C_Spell
    if cs and cs.GetSpellName then
        local ok, n = pcall(cs.GetSpellName, id)
        n = ok and Plain(n) or nil
        if type(n) == "string" and n ~= "" then return n end
    end
    if _G.GetSpellInfo then
        local ok, n = pcall(_G.GetSpellInfo, id)
        n = ok and Plain(n) or nil
        if type(n) == "string" and n ~= "" then return n end
    end
end

local function Texture(id)
    local cs = _G.C_Spell
    if cs and cs.GetSpellTexture then
        local ok, t = pcall(cs.GetSpellTexture, id)
        t = ok and Plain(t) or nil
        if t then return t end
    end
    if _G.GetSpellTexture then
        local ok, t = pcall(_G.GetSpellTexture, id)
        t = ok and Plain(t) or nil
        if t then return t end
    end
    return 134400
end

local function Known(id)
    local TR = WeintCodex.Trainer
    return TR and TR.Known and TR.Known(id) == true or false
end

-- Die Nummer, unter der der Charakter den Zauber hat, oder nil.
function OC.Resolve(chain)
    for i = #chain, 1, -1 do
        if Known(chain[i]) then return chain[i] end
    end
    -- Ueber den Namen: der Client loest ihn nur zu einem eigenen Zauber auf.
    local cs = _G.C_Spell
    local n = SpellName(chain[1])
    if n and cs and cs.GetSpellInfo then
        local ok, info = pcall(cs.GetSpellInfo, n)
        local id = ok and type(info) == "table" and Plain(info.spellID) or nil
        if type(id) == "number" and Known(id) then return id end
    end
    return nil
end

local function Chain(class, id)
    local T = WeintCodex.TrainerData
    local chain = T and T.RankChain and T.RankChain(class, id)
    if chain then return chain end
    return { id }
end

local function BaseCooldown(id)
    local fn = _G.GetSpellBaseCooldown
    if type(fn) ~= "function" then return nil end
    local ok, ms = pcall(fn, id)
    ms = ok and Plain(ms) or nil
    return type(ms) == "number" and ms or nil
end

-- Alle Eintraege der Klasse: { key = erste Nummer der Rangkette, chain,
-- preset = "big"|"small"|"off" }. Voreinstellung zuerst, in ihrer Folge.
function OC.Catalog(class)
    local out, seen = {}, {}
    local function Add(id, preset)
        local chain = Chain(class, id)
        local key = chain[1]
        if seen[key] then return end
        seen[key] = true
        out[#out + 1] = { key = key, chain = chain, preset = preset }
    end
    local CS = WeintCodex.UICooldownSetup
    local L = CS and CS.LISTS and CS.LISTS[class]
    if L then
        for _, id in ipairs(L.essential or {}) do Add(id, "big") end
        for _, id in ipairs(L.utility or {}) do Add(id, "small") end
    end
    local T = WeintCodex.TrainerData
    if T and T.Spells then
        for _, sp in ipairs(T.Spells(class)) do
            local ms = not sp.pet and BaseCooldown(sp.id)
            if ms and ms >= OC.MIN_BASE_CD then Add(sp.id, "off") end
        end
    end
    return out
end

-- Alle aktiven Zauber im Zauberbuch, je Name der hoechste Rang
-- (6.91.0.0, Wunsch: "Es sollen alle zur Zeit verfuegbaren Zauber drin
-- sein"). Rueckgabe: Liste { id, name } in Buchfolge, dazu name -> id.
function OC.Spellbook()
    local out, byName = {}, {}
    local function Take(id, passive)
        id = tonumber(Plain(id))
        if not id or K.Bool(passive, false) then return end
        local n = SpellName(id)
        if not n then return end
        if byName[n] then
            -- spaeter im Buch = hoeherer Rang
            for _, o in ipairs(out) do
                if o.name == n then o.id = id o.ranks[#o.ranks + 1] = id end
            end
        else
            out[#out + 1] = { id = id, name = n, ranks = { id } }
        end
        byName[n] = id
    end
    local sb = _G.C_SpellBook
    local bank = _G.Enum and _G.Enum.SpellBookSpellBank and _G.Enum.SpellBookSpellBank.Player
    if sb and sb.GetNumSpellBookSkillLines and sb.GetSpellBookSkillLineInfo and sb.GetSpellBookItemInfo and bank then
        local ok, lines = pcall(sb.GetNumSpellBookSkillLines)
        for l = 1, (ok and tonumber(Plain(lines)) or 0) do
            local ok2, info = pcall(sb.GetSpellBookSkillLineInfo, l)
            if ok2 and type(info) == "table" and not K.Bool(info.shouldHide, false) then
                local off, num = tonumber(Plain(info.itemIndexOffset)) or 0, tonumber(Plain(info.numSpellBookItems)) or 0
                for i = off + 1, off + num do
                    local ok3, it = pcall(sb.GetSpellBookItemInfo, i, bank)
                    if ok3 and type(it) == "table" then
                        local typ = Plain(it.itemType)
                        local isSpell = _G.Enum.SpellBookItemType and typ == _G.Enum.SpellBookItemType.Spell or typ == 1
                        if isSpell then Take(it.spellID or it.actionID, it.isPassive) end
                    end
                end
            end
        end
    elseif _G.GetNumSpellTabs and _G.GetSpellTabInfo and _G.GetSpellBookItemInfo then
        local ok, tabs = pcall(_G.GetNumSpellTabs)
        for t = 1, (ok and tonumber(Plain(tabs)) or 0) do
            local ok2, _, _, off, num = pcall(_G.GetSpellTabInfo, t)
            off, num = ok2 and tonumber(Plain(off)) or 0, ok2 and tonumber(Plain(num)) or 0
            for i = off + 1, off + num do
                local ok3, typ, id = pcall(_G.GetSpellBookItemInfo, i, "spell")
                if ok3 and Plain(typ) == "SPELL" then
                    local passive = _G.IsPassiveSpell and select(2, pcall(_G.IsPassiveSpell, i, "spell"))
                    Take(id, passive)
                end
            end
        end
    end
    OC.bookRanks = {}
    for _, o in ipairs(out) do OC.bookRanks[o.name] = o.ranks end
    return out, byName
end

-- Gelernte Eintraege (nur ausserhalb des Kampfes neu gelesen).
OC.known = {}
OC.class = nil
function OC.Scan()
    if K.InCombat() then return OC.known end
    local class
    if _G.UnitClass then class = Plain(select(2, _G.UnitClass("player"))) end
    OC.class = class
    local list = OC.known
    for i = #list, 1, -1 do list[i] = nil end
    if type(class) ~= "string" then return list end
    local book, byName = OC.Spellbook()
    for _, e in ipairs(OC.Catalog(class)) do
        local id = OC.Resolve(e.chain)
        -- Hoechster Rang laut Zauberbuch (der Lehrerbestand kennt nicht jeden)
        local bn = id and SpellName(id)
        if bn and byName[bn] then id = byName[bn] end
        if id and #list < OC.MAX_LIST then
            e.id, e.name, e.tex, e.rank = id, SpellName(id) or tostring(id), Texture(id), SpellRank(id)
            -- Derselbe Zauber in zwei Ketten: nur einmal, der hoechste Rang.
            local dup
            for _, o in ipairs(list) do if o.name == e.name then dup = true break end end
            if not dup then list[#list + 1] = e end
        end
    end
    -- Alles Weitere aus dem Zauberbuch, ab Werk "Aus"
    local have = {}
    for _, o in ipairs(list) do have[o.name] = true end
    for _, b in ipairs(book) do
        if not have[b.name] and #list < OC.MAX_LIST then
            have[b.name] = true
            list[#list + 1] = { key = "n:" .. b.name, preset = "off", id = b.id, name = b.name,
                                tex = Texture(b.id), rank = SpellRank(b.id) }
        end
    end
    OC.AddCustom(list)
    local m = Mem()
    for _, e in ipairs(list) do
        e.ranks = not e.item and OC.bookRanks and OC.bookRanks[e.name] or nil
        local want = m and tonumber(m.rank[e.key])
        if want and e.ranks then
            for _, r in ipairs(e.ranks) do
                if r == want then e.id, e.rank, e.tex = r, SpellRank(r), Texture(r) break end
            end
        end
    end
    OC.SortByOrder(list)
    return list
end

--------------------------------------------------
-- Selbst hinzugefuegt (6.91.0.0, Wunsch: "wenn du einen Zauber vergessen
-- hast ... manuell hinzufuegen. Auch ein Item.")
--------------------------------------------------

local function ItemInfo(id)
    local name, tex
    local ci = _G.C_Item
    if ci and ci.GetItemNameByID then
        local ok, n = pcall(ci.GetItemNameByID, id)
        n = ok and Plain(n) or nil
        if type(n) == "string" and n ~= "" then name = n end
    end
    if not name and _G.GetItemInfo then
        local ok, n = pcall(_G.GetItemInfo, id)
        n = ok and Plain(n) or nil
        if type(n) == "string" and n ~= "" then name = n end
    end
    local f = (ci and ci.GetItemIconByID) or _G.GetItemIcon
    if f then
        local ok, t = pcall(f, id)
        t = ok and Plain(t) or nil
        if t then tex = t end
    end
    return name, tex
end

function OC.AddCustom(list)
    local m = Mem()
    if not m then return end
    for _, c in ipairs(m.custom) do
        local id = tonumber(c.id)
        if id then
            local e = { key = (c.kind == "item" and "i:" or "s:") .. id, custom = true, preset = "small" }
            if c.kind == "item" then
                local n, t = ItemInfo(id)
                e.item, e.id, e.name, e.tex = true, id, n or ("Gegenstand " .. id), t or 134400
            else
                e.id, e.name, e.tex, e.rank = id, SpellName(id) or ("Zauber " .. id), Texture(id), SpellRank(id)
            end
            list[#list + 1] = e
        end
    end
end

-- Text oder Nummer -> { kind, id } oder nil, Grund.
function OC.ParseAdd(text)
    text = type(text) == "string" and text:gsub("^%s+", ""):gsub("%s+$", "") or ""
    if text == "" then return nil, "Name oder Nummer eingeben." end
    local item = text:match("|Hitem:(%d+)")
    if item then return { kind = "item", id = tonumber(item) } end
    local spell = text:match("|Hspell:(%d+)")
    if spell then return { kind = "spell", id = tonumber(spell) } end
    local num = tonumber(text)
    local cs = _G.C_Spell
    if num then
        if SpellName(num) and Known(num) then return { kind = "spell", id = num } end
        if ItemInfo(num) then return { kind = "item", id = num } end
        if SpellName(num) then return { kind = "spell", id = num } end
        return nil, "Unter dieser Nummer kennt das Spiel nichts."
    end
    -- Name: zuerst ein eigener Zauber, dann ein Gegenstand
    if cs and cs.GetSpellInfo then
        local ok, info = pcall(cs.GetSpellInfo, text)
        local id = ok and type(info) == "table" and Plain(info.spellID) or nil
        if type(id) == "number" then return { kind = "spell", id = id } end
    elseif _G.GetSpellInfo then
        local ok, _, _, _, _, _, _, id = pcall(_G.GetSpellInfo, text)
        id = ok and Plain(id) or nil
        if type(id) == "number" then return { kind = "spell", id = id } end
    end
    if _G.GetItemInfo then
        local ok, _, link = pcall(_G.GetItemInfo, text)
        link = ok and Plain(link) or nil
        local id = type(link) == "string" and tonumber(link:match("item:(%d+)"))
        if id then return { kind = "item", id = id } end
    end
    return nil, "„" .. text .. "“ nicht gefunden – Gegenstände kennt das Spiel nur, wenn du sie schon gesehen hast. Tipp: direkt auf die Liste ziehen."
end

function OC.Add(c)
    local m = Mem()
    if not (m and type(c) == "table" and tonumber(c.id)) then return false end
    for _, o in ipairs(m.custom) do
        if o.kind == c.kind and tonumber(o.id) == tonumber(c.id) then return false end
    end
    m.custom[#m.custom + 1] = { kind = c.kind, id = tonumber(c.id) }
    OC.Scan()
    OC.Refresh()
    return true
end

function OC.Remove(e)
    local m = Mem()
    if not (m and e and e.custom) then return false end
    for i = #m.custom, 1, -1 do
        local o = m.custom[i]
        if ((o.kind == "item") == (e.item and true or false)) and tonumber(o.id) == e.id then table.remove(m.custom, i) end
    end
    m.spells[e.key] = nil
    OC.Scan()
    OC.Refresh()
    return true
end

-- Was gerade am Mauszeiger haengt (aus Zauberbuch oder Taschen).
function OC.FromCursor()
    if type(_G.GetCursorInfo) ~= "function" then return nil end
    local kind, a, b, c = _G.GetCursorInfo()
    kind = Plain(kind)
    if kind == "item" then return { kind = "item", id = tonumber(Plain(a)) } end
    if kind == "spell" then
        local id = tonumber(Plain(c)) or tonumber(Plain(b))
        if not id and _G.GetSpellBookItemInfo then
            local ok, _, sid = pcall(_G.GetSpellBookItemInfo, a, b)
            id = ok and tonumber(Plain(sid)) or nil
        end
        if id then return { kind = "spell", id = id } end
    end
    return nil
end

--------------------------------------------------
-- Reihenfolge per Ziehen (6.91.0.0)
--------------------------------------------------

function OC.SortByOrder(list)
    local m = Mem()
    local pos = {}
    if m then for i, k in ipairs(m.order) do pos[k] = i end end
    for i, e in ipairs(list) do e._i = i end
    table.sort(list, function(a, b)
        local pa, pb = pos[a.key] or (1000 + a._i), pos[b.key] or (1000 + b._i)
        return pa < pb
    end)
end

-- "from" vor "to" setzen; die ganze Folge wird dabei festgeschrieben.
function OC.Move(fromKey, toKey)
    local m = Mem()
    if not m or fromKey == toKey then return false end
    local keys, fi, ti = {}, nil, nil
    for i, e in ipairs(OC.known) do
        keys[i] = e.key
        if e.key == fromKey then fi = i end
        if e.key == toKey then ti = i end
    end
    if not (fi and ti) then return false end
    table.remove(keys, fi)
    table.insert(keys, ti, fromKey)
    m.order = keys
    OC.SortByOrder(OC.known)
    OC.Refresh()
    return true
end

function OC.Slot(e)
    local m = Mem()
    local v = m and m.spells[e.key]
    if v == "big" or v == "small" or v == "off" or OC.ExtraDef(v) then return v end
    return e.preset
end

function OC.SetSlot(e, slot)
    local m = Mem()
    if not m then return end
    m.spells[e.key] = (slot ~= e.preset) and slot or nil
    OC.Refresh()
end

--------------------------------------------------
-- Darstellung je Faehigkeit (1.0.9.0, Wunsch: "ob Balken oder Symbol -
-- wie bei WeakAuras"). Ein Balken laeuft erst ueber die WIRKUNG ab (eigener
-- DoT auf dem Ziel, eigener Buff aus den Buffzeiten - Dauern aus Classic,
-- aus dem eigenen Wirken gerechnet, nie aus einer gelesenen Aura), danach
-- ueber die ABKLINGZEIT bis "bereit". Jede Reihe kann beides mischen.
--------------------------------------------------
-- "both" (Spieler: "die Falken individuell in eine Leiste, aber die
-- Laufzeit der Falken in Balken"): das Symbol steht fest und zeigt die
-- Abklingzeit; solange Wirkungen laufen, steht daneben je Wirkung ein Balken.
OC.DISPLAY_TEXT = { icon = "Symbol", bar = "Balken", both = "Symbol + Balken der Wirkung" }
function OC.Display(e)
    local m = Mem()
    local v = m and m.display[e.key]
    if v == "bar" then return "bar" end
    if v == "both" and OC.HasEffect(e) then return "both" end
    return "icon"
end
function OC.SetDisplay(e, v)
    local m = Mem()
    if not m then return end
    m.display[e.key] = (v == "bar" or v == "both") and v or nil
    OC.Refresh()
end
-- Rechtsklick auf der Buehne: Symbol -> Balken -> (mit Wirkung) beides -> Symbol.
function OC.NextDisplay(e)
    local cur = OC.Display(e)
    if cur == "icon" then return "bar" end
    if cur == "bar" and OC.HasEffect(e) then return "both" end
    return "icon"
end
OC.BAR_COLOR_DEFAULT = "blue"
OC.BAR_WIDTHS = { 100, 140, 180, 220, 260, 320 }
OC.BAR_HEIGHTS = { 12, 16, 20, 24, 28, 32 }
function OC.BarColor(e)
    local m = Mem()
    local v = m and m.barColor[e.key]
    for _, c in ipairs(OC.GLOW_COLORS or {}) do if c.value == v then return v end end
    return OC.BAR_COLOR_DEFAULT
end
function OC.SetBarColor(e, v)
    local m = Mem()
    if not m then return end
    m.barColor[e.key] = (v ~= OC.BAR_COLOR_DEFAULT) and v or nil
    OC.Refresh()
end
function OC.BarRGB(e)
    local want = OC.BarColor(e)
    for _, c in ipairs(OC.GLOW_COLORS) do
        if c.value == want then return C[c.token] or C.infoBright end
    end
    return C.infoBright
end

-- Gruppe der Buffzeiten, zu der der Zauber gehoert (jeder Rang), oder nil.
-- 1.0.9.0 (Spieler mit Tooltip: "Falke beschwoeren" - 6 s Abklingzeit, 18 s
-- je Falke, bis zu zwei): Forever-Zauber ohne bekannte Nummer fuehren die
-- Buffzeiten ueber den Namen (g.names, BT.byId nach dem ersten Wirken).
function OC.BuffGroup(e)
    local BT = WeintCodex.UIBuffTimes
    if not (BT and BT.Groups and e and (e.id or e.name)) then return nil end
    local known = e.id and BT.byId and BT.byId[e.id]
    if known and known.duration and not known.variable then return known end
    for _, g in ipairs(BT.Groups()) do
        if g.duration and not g.variable then
            for _, id in ipairs(g.spells or {}) do
                if id == e.id then return g end
                if e.ranks then for _, r in ipairs(e.ranks) do if r == id then return g end end end
            end
            for _, sn in ipairs(g.names or {}) do
                if sn == e.name then return g end
            end
        end
    end
    return nil
end

-- Alle laufenden Wirkungen (Falken: bis zu zwei, jede mit eigener Uhr):
-- Startzeiten in `out`, aelteste zuerst; Anzahl und Dauer.
function OC.Effects(e, out)
    for i = #out, 1, -1 do out[i] = nil end
    if not e or e.item then return 0, nil end
    local ds, dd = OC.DotOn(e.name)
    if ds then out[1] = ds return 1, dd end
    local g = OC.BuffGroup(e)
    local BT = WeintCodex.UIBuffTimes
    local a = g and BT and BT.active and BT.active[g.key]
    if not (a and type(a.start) == "number" and type(a.duration) == "number") then return 0, nil end
    local now = _G.GetTime and Plain(_G.GetTime()) or 0
    for _, st0 in ipairs(a.earlier or {}) do
        if type(st0) == "number" and now < st0 + a.duration then out[#out + 1] = st0 end
    end
    if now < a.start + a.duration then out[#out + 1] = a.start end
    return #out, a.duration
end

-- Hat die Faehigkeit eine bekannte Wirkdauer? (Sonst zeigt ihr Balken nur
-- die Abklingzeit.)
function OC.HasEffect(e)
    if not e or e.item then return false end
    return (OC.DotDuration(e.name) or OC.BuffGroup(e)) and true or false
end

-- Laufende Wirkung: Start, Dauer (eigene Zahlen) - oder nil.
function OC.EffectOf(e)
    if not e or e.item then return nil end
    local ds, dd = OC.DotOn(e.name)
    if ds then return ds, dd end
    local g = OC.BuffGroup(e)
    local BT = WeintCodex.UIBuffTimes
    local a = g and BT and BT.active and BT.active[g.key]
    if a and type(a.start) == "number" and type(a.duration) == "number" then
        local now = _G.GetTime and Plain(_G.GetTime()) or 0
        if now < a.start + a.duration then return a.start, a.duration end
    end
    return nil
end

-- Leuchten je Zauber (6.93.0.0): "ready" = wenn bereit, "dot" = wenn der
-- eigene DoT auf dem Ziel fehlt oder gleich auslaeuft, "off". Alte
-- Speicherstaende (true/false) gelten als "ready"/"off".
OC.GLOW_TEXT = { ready = "wenn bereit", dot = "wenn DoT fehlt/ausläuft", off = "aus" }
OC.DOT_WARN = 3   -- s Rest, ab dem "ausläuft" leuchtet

function OC.GlowMode(e)
    local m = Mem()
    local v = m and m.glowOf[e.key]
    if v == true then return "ready" elseif v == false then return "off" end
    if v == "ready" or v == "dot" or v == "off" then return v end
    if OC.DotDuration(e.name) then return "dot" end
    return OC.Get("glow") and "ready" or "off"
end
function OC.GlowOf(e) return OC.GlowMode(e) ~= "off" end

function OC.NextGlow(e)
    local m = Mem()
    if not m then return end
    local cur = OC.GlowMode(e)
    local list = OC.DotDuration(e.name) and { "ready", "dot", "off" } or { "ready", "off" }
    local nxt = list[1]
    for i, k in ipairs(list) do if k == cur then nxt = list[i % #list + 1] break end end
    m.glowOf[e.key] = nxt
    OC.Refresh()
end

-- Toene (6.93.0.0, Wunsch: "Sowas soll drin sein" - Bild der Tonauswahl
-- des Spiels): Gruppen im Menue, eigene Toene, Toene des Spiels und
-- Vorlesen. Toene des Spiels nur, wenn der Client den Namen kennt
-- (SOUNDKIT) - sonst fehlen sie im Menue statt still zu bleiben.
-- Toene des Abklingzeitmanagers des Spiels (Nummern aus
-- Blizzard_CooldownViewer/CooldownViewerSoundAlertData.lua, Fassung 12.x).
-- Namen: Rueckfall, wenn der Client seine eigenen (CDMSND_*) nicht hat.
OC.GAME_SOUNDS = {
    { cat = "Animals", text = "Tiere", items = {
        { 316401, "CDMSND_ANIMALS_CAT", "Cat" },
        { 316406, "CDMSND_ANIMALS_CHICKEN", "Chicken" },
        { 316407, "CDMSND_ANIMALS_COW", "Cow" },
        { 316409, "CDMSND_ANIMALS_GNOLL", "Gnoll" },
        { 316715, "CDMSND_ANIMALS_GOAT", "Goat" },
        { 316411, "CDMSND_ANIMALS_LION", "Lion" },
        { 316412, "CDMSND_ANIMALS_PANTHER", "Panther" },
        { 316413, "CDMSND_ANIMALS_RATTLESNAKE", "Rattlesnake" },
        { 316414, "CDMSND_ANIMALS_SHEEP", "Sheep" },
        { 316415, "CDMSND_ANIMALS_WOLF", "Wolf" },
    } },
    { cat = "Devices", text = "Geräte", items = {
        { 316442, "CDMSND_DEVICES_BOAT_HORN", "Boat Horn" },
        { 316436, "CDMSND_DEVICES_AIR_HORN", "Air Horn" },
        { 316713, "CDMSND_DEVICES_BIKE_HORN", "Bike Horn" },
        { 316446, "CDMSND_DEVICES_CASH_REGISTER", "Cash Register" },
        { 316717, "CDMSND_DEVICES_JACKPOT_BELL", "Jackpot Bell" },
        { 316718, "CDMSND_DEVICES_JACKPOT_COINS", "Jackpot Coins" },
        { 316719, "CDMSND_DEVICES_JACKPOT_FAIL", "Jackpot Fail" },
        { 316433, "CDMSND_DEVICES_ROTARY_PHONE_DIAL", "Rotary Phone Dial" },
        { 316492, "CDMSND_DEVICES_ROTARY_PHONE_RING", "Rotary Phone Ring" },
        { 316425, "CDMSND_DEVICES_STOVE_PIPE", "Stove Pipe" },
        { 316430, "CDMSND_DEVICES_TRASHCAN_LID", "Trashcan Lid" },
    } },
    { cat = "Impacts", text = "Treffer", items = {
        { 316528, "CDMSND_IMPACTS_ANVIL_STRIKE", "Anvil Strike" },
        { 316419, "CDMSND_IMPACTS_BUBBLE_SMASH", "Bubble Smash" },
        { 316531, "CDMSND_IMPACTS_LOW_THUD", "Low Thud" },
        { 316532, "CDMSND_IMPACTS_METAL_CLANKS", "Metal Clanks" },
        { 316486, "CDMSND_IMPACTS_METAL_RATTLE", "Metal Rattle" },
        { 316484, "CDMSND_IMPACTS_METAL_SCRAPE", "Metal Scrape" },
        { 316536, "CDMSND_IMPACTS_METAL_WARBLE", "Metal Warble" },
        { 316434, "CDMSND_IMPACTS_POP_CLICK", "Pop Click" },
        { 316453, "CDMSND_IMPACTS_STRANGE_CLANG", "Strange Clang" },
        { 316535, "CDMSND_IMPACTS_SWORD_SCRAPE", "Sword Scrape" },
    } },
    { cat = "Instruments", text = "Instrumente", items = {
        { 316493, "CDMSND_INSTRUMENTS_BELL_RING", "Bell Ring" },
        { 316712, "CDMSND_INSTRUMENTS_BELL_TRILL", "Bell Trill" },
        { 316722, "CDMSND_INSTRUMENTS_BRASS", "Brass" },
        { 316447, "CDMSND_INSTRUMENTS_CHIME_ASCENDING", "Chime Ascending" },
        { 316477, "CDMSND_INSTRUMENTS_GUITAR_CHUG", "Guitar Chug" },
        { 316482, "CDMSND_INSTRUMENTS_GUITAR_PINCH", "Guitar Pinch" },
        { 316509, "CDMSND_INSTRUMENTS_PITCH_PIPE_DISTRESSED", "Pitch Pipe Distressed" },
        { 316501, "CDMSND_INSTRUMENTS_PITCH_PIPE_NOTE", "Pitch Pipe Note" },
        { 316540, "CDMSND_INSTRUMENTS_SYNTH_BIG", "Synth Big" },
        { 316476, "CDMSND_INSTRUMENTS_SYNTH_BUZZ", "Synth Buzz" },
        { 316460, "CDMSND_INSTRUMENTS_SYNTH_HIGH", "Synth High" },
        { 316723, "CDMSND_INSTRUMENTS_WARHORN", "Warhorn" },
    } },
    { cat = "Short", text = "Kurz", items = {
        { 353392, "CDMSND_SHORT_BELL_STRIKE", "Bell Strike" },
        { 353387, "CDMSND_SHORT_BELL_TREE", "Bell Tree" },
        { 353388, "CDMSND_SHORT_BIG_POT", "Big Pot" },
        { 353389, "CDMSND_SHORT_BLADES", "Blades" },
        { 353424, "CDMSND_SHORT_COFFEE_MUG", "Coffee Mug" },
        { 353393, "CDMSND_SHORT_COW_BELL", "Cow Bell" },
        { 353395, "CDMSND_SHORT_FINGER_SNAP", "Finger Snap" },
        { 353404, "CDMSND_SHORT_GUITAR", "Guiter" },
        { 353405, "CDMSND_SHORT_KALIMBA", "Kalimba" },
        { 353406, "CDMSND_SHORT_METAL_BLADE_DROP", "Metal Blade Drop" },
        { 353407, "CDMSND_SHORT_METAL_BLADE_ON_ROD", "Metal Blade On Rod" },
        { 353408, "CDMSND_SHORT_METAL_IMPACT", "Metal Impact" },
        { 353410, "CDMSND_SHORT_MINI_WOOD_XYLOPHONE", "Mini Wood Xylophone" },
        { 353425, "CDMSND_SHORT_PAPER_CUP", "Paper Cup" },
        { 353417, "CDMSND_SHORT_SHEET_METAL", "Sheet Metal" },
        { 353419, "CDMSND_SHORT_STOVE_PIPE", "Stove Pipe" },
        { 353420, "CDMSND_SHORT_STOVE_PIPE_BLADE", "Stove Pipe Blade" },
        { 353421, "CDMSND_SHORT_SWORD_SHING", "Sword Shing" },
        { 353402, "CDMSND_SHORT_SYNTH_BLEEP", "Synth Bleep" },
        { 353400, "CDMSND_SHORT_SYNTH_BLURP", "Synth Blurp" },
        { 353397, "CDMSND_SHORT_SYNTH_ERROR", "Synth Error" },
        { 353399, "CDMSND_SHORT_SYNTH_HIGH", "Synth High" },
        { 353423, "CDMSND_SHORT_TRIANGLE", "Triangle" },
        { 353426, "CDMSND_SHORT_WATER_DROP", "Water Drop" },
        { 353427, "CDMSND_SHORT_WINE_BOTTLE", "Wine Bottle" },
        { 353428, "CDMSND_SHORT_WOOD_XYLOPHONE", "Wood Xylophone" },
    } },
    { cat = "War2", text = "Warcraft 2", items = {
        { 316731, "CDMSND_WAR2_ABSTRACT_WHOOSH", "Abstract Whoosh" },
        { 316733, "CDMSND_WAR2_CHOIR", "Choir" },
        { 316735, "CDMSND_WAR2_CONSTRUCTION", "Construction" },
        { 316736, "CDMSND_WAR2_MAGIC_CHIMES", "Magic Chimes" },
        { 316745, "CDMSND_WAR2_PIG_SQUEAL", "Pig Squeal" },
        { 316738, "CDMSND_WAR2_SAWS", "Saws" },
        { 316746, "CDMSND_WAR2_SEAL", "Seal" },
        { 316748, "CDMSND_WAR2_SLOW", "Slow" },
        { 316749, "CDMSND_WAR2_SMITH", "Smith" },
        { 316739, "CDMSND_WAR2_SYNTH_STINGER", "Synth Stinger" },
        { 316740, "CDMSND_WAR2_TRUMPET_RALLY", "Trumpet Rally" },
        { 316737, "CDMSND_WAR2_ZIPPY_MAGIC", "Zippy Magic" },
    } },
    { cat = "War3", text = "Warcraft 3", items = {
        { 316773, "CDMSND_WAR3_BELL", "Bell" },
        { 316774, "CDMSND_WAR3_CRUNCHY_BELL", "Crunchy Bell" },
        { 316768, "CDMSND_WAR3_DRUM_SPLASH", "Drum Splash" },
        { 316775, "CDMSND_WAR3_ERROR", "Error" },
        { 316769, "CDMSND_WAR3_FANFARE", "Fanfare" },
        { 316776, "CDMSND_WAR3_GATE_OPEN", "Gate Open" },
        { 316770, "CDMSND_WAR3_GOLD", "Gold" },
        { 316778, "CDMSND_WAR3_MAGIC_SHIMMER", "Magic Shimmer" },
        { 316771, "CDMSND_WAR3_RINGOUT", "Ringout" },
        { 316765, "CDMSND_WAR3_ROOSTER", "Rooster" },
        { 316779, "CDMSND_WAR3_SHIMMER_BELL", "Shimmer Bell" },
        { 316766, "CDMSND_WAR3_WOLF_HOWL", "Wolf Howl" },
    } },
}

-- Danach die eigenen (6.95.0.0: alle Toene des Spiels zuerst, wie dort).
OC.SOUND_GROUPS = {
    { text = "WeintCodex", items = { "hoch", "tief", "trill", "dreifach", "achtung", "fehler", "hupe", "sirene", "raus" } },
    { text = "Huhn", items = { "file:huhn_gack", "file:huhn_bwaak", "file:huhn_piep", "file:huhn_pock", "file:huhn_gold", "file:huhn_bumm" } },
}

-- Name eines Spiel-Tons: der des Clients, sonst der Rueckfall.
OC.cdmName = {}
for _, g in ipairs(OC.GAME_SOUNDS) do
    for _, it in ipairs(g.items) do OC.cdmName[it[1]] = it end
end
function OC.GameSoundText(it)
    local t = _G[it[2]]
    return type(t) == "string" and t ~= "" and t or it[3]
end
function OC.GameCatText(g)
    local t = _G["COOLDOWN_VIEWER_SETTINGS_SOUND_ALERT_CATEGORY_" .. g.cat:upper()]
    return type(t) == "string" and t ~= "" and t or g.text
end
OC.KIT_TEXT = {
    MAP_PING = "Kartenpieps", IG_QUEST_LIST_COMPLETE = "Quest fertig", UI_EPICLOOT_TOAST = "Epische Beute",
    AUCTION_WINDOW_OPEN = "Auktionshaus", IG_BACKPACK_COIN_OK = "Münzen", UI_RAID_LOOT_TOAST_LESSER_ITEM_WON = "Beute gewonnen",
    UI_LEGENDARY_LOOT_TOAST = "Legendär",
}
OC.FILE_TEXT = { huhn_gack = "Gack", huhn_bwaak = "Bwaak", huhn_piep = "Piep", huhn_pock = "Pock", huhn_gold = "Gold", huhn_bumm = "Bumm" }

local function KitOf(k)
    local name = type(k) == "string" and k:match("^kit:(.+)$")
    if not name then return nil end
    local id = _G.SOUNDKIT and _G.SOUNDKIT[name]
    return type(id) == "number" and id or nil, name
end

function OC.SoundAvailable(k)
    if k == "tts" then return true end
    if k:match("^cdm:") then return true end
    if k:match("^kit:") then return KitOf(k) ~= nil end
    if k:match("^file:") then return true end
    local FA = WeintCodex.UIFireAlarm
    if FA and FA.MergeCustom then FA.MergeCustom() end
    return FA and FA.SOUNDS and FA.SOUNDS[k] ~= nil or false
end

function OC.SoundText(k)
    if k == "none" or not k then return "Kein Ton" end
    if k == "tts" then return "Vorlesen (Name des Zaubers)" end
    local cdm = tonumber(k:match("^cdm:(%d+)$") or "")
    if cdm then
        local it = OC.cdmName[cdm]
        return it and OC.GameSoundText(it) or ("Ton " .. cdm)
    end
    local _, kit = KitOf(k)
    if kit then return OC.KIT_TEXT[kit] or kit end
    local f = k:match("^file:(.+)$")
    if f then return "Huhn: " .. (OC.FILE_TEXT[f] or f) end
    local FA = WeintCodex.UIFireAlarm
    local s = FA and FA.SOUNDS and FA.SOUNDS[k]
    return s and s.text or k
end

-- Vorlesen: TextToSpeech des Spiels, wenn es ihn gibt.
function OC.Speak(text)
    if type(text) ~= "string" or text == "" then return false end
    if type(_G.TextToSpeech_Speak) == "function" then
        local voice = _G.TextToSpeech_GetSelectedVoice and _G.Enum and _G.Enum.TtsVoiceType
            and select(2, pcall(_G.TextToSpeech_GetSelectedVoice, _G.Enum.TtsVoiceType.Standard)) or nil
        if pcall(_G.TextToSpeech_Speak, text, voice) then return true end
    end
    local vc = _G.C_VoiceChat
    if vc and vc.SpeakText then
        local voices = vc.GetTtsVoices and select(2, pcall(vc.GetTtsVoices))
        local id = type(voices) == "table" and voices[1] and voices[1].voiceID or 0
        if pcall(vc.SpeakText, id, text, 0, 100, false) then return true end
        if pcall(vc.SpeakText, id, text, _G.Enum and _G.Enum.VoiceTtsDestination and _G.Enum.VoiceTtsDestination.LocalPlayback or 1, 0, 100) then return true end
    end
    return false
end

function OC.PlaySound(k, e)
    if not k or k == "none" then return end
    if k == "tts" then OC.Speak(e and e.name or "Bereit") return end
    local cdm = tonumber(k:match("^cdm:(%d+)$") or "")
    if cdm then if _G.PlaySound then pcall(_G.PlaySound, cdm, "Master") end return end
    local kit = KitOf(k)
    if kit then if _G.PlaySound then pcall(_G.PlaySound, kit, "Master") end return end
    local FA = WeintCodex.UIFireAlarm
    local f = k:match("^file:(.+)$")
    if f then
        if _G.PlaySoundFile then pcall(_G.PlaySoundFile, (FA and FA.SOUND_PATH or "") .. f .. ".ogg", "Master") end
        return
    end
    if FA and FA.MergeCustom then FA.MergeCustom() end
    local s = FA and FA.SOUNDS and FA.SOUNDS[k]
    if not s then return end
    local path = FA.FileOf and FA.FileOf(s)
    if path then
        if _G.PlaySoundFile then pcall(_G.PlaySoundFile, path, "Master") end
        return
    end
    local id = _G.SOUNDKIT and _G.SOUNDKIT[s.kit] or s.id
    if _G.PlaySound then pcall(_G.PlaySound, id, "Master") end
end

function OC.SoundOf(e)
    local m = Mem()
    return m and m.sound[e.key] or "none"
end

function OC.SetSound(e, k)
    local m = Mem()
    if not m then return end
    m.sound[e.key] = (k and k ~= "none") and k or nil
    if k and k ~= "none" then OC.PlaySound(k, e) end
end

-- Wann der Ton kommt: "ready" (Abklingzeit vorbei) oder "dot" (DoT laeuft aus)
OC.WHEN_TEXT = { ready = "Verfügbar", dot = "DoT ausgelaufen" }
function OC.SoundWhen(e)
    local m = Mem()
    local v = m and m.soundWhen and m.soundWhen[e.key]
    if v == "ready" or v == "dot" then return v end
    return OC.DotDuration(e.name) and "dot" or "ready"
end
function OC.NextSoundWhen(e)
    local m = Mem()
    if not m then return end
    m.soundWhen = m.soundWhen or {}
    m.soundWhen[e.key] = OC.SoundWhen(e) == "ready" and "dot" or "ready"
end

-- Menue wie das des Spiels: Gruppen mit Untermenues, Vorlesen, kein Ton.
function OC.SoundMenu(owner, e, after)
    local MU = _G.MenuUtil
    if not (MU and MU.CreateContextMenu) then
        -- ohne Menue des Spiels: weiterschalten
        local flat = { "none" }
        for _, g in ipairs(OC.GAME_SOUNDS) do
            for _, it in ipairs(g.items) do flat[#flat + 1] = "cdm:" .. it[1] end
        end
        for _, g in ipairs(OC.SOUND_GROUPS) do
            for _, k in ipairs(g.items) do if OC.SoundAvailable(k) then flat[#flat + 1] = k end end
        end
        flat[#flat + 1] = "tts"
        local cur, nxt = OC.SoundOf(e), "none"
        for i, k in ipairs(flat) do if k == cur then nxt = flat[i % #flat + 1] break end end
        OC.SetSound(e, nxt)
        if after then after() end
        return
    end
    MU.CreateContextMenu(owner, function(_, root)
        if root.CreateTitle then root:CreateTitle("Tonhinweis") end
        root:CreateRadio("Kein Ton", function() return OC.SoundOf(e) == "none" end,
            function() OC.SetSound(e, "none") if after then after() end end)
        for _, g in ipairs(OC.GAME_SOUNDS) do
            local sub = root:CreateButton(OC.GameCatText(g))
            for _, it in ipairs(g.items) do
                local k = "cdm:" .. it[1]
                sub:CreateRadio(OC.GameSoundText(it), function() return OC.SoundOf(e) == k end,
                    function() OC.SetSound(e, k) if after then after() end end)
            end
        end
        for _, g in ipairs(OC.SOUND_GROUPS) do
            local sub = root:CreateButton(g.text)
            for _, k in ipairs(g.items) do
                if OC.SoundAvailable(k) then
                    sub:CreateRadio(OC.SoundText(k), function() return OC.SoundOf(e) == k end,
                        function() OC.SetSound(e, k) if after then after() end end)
                end
            end
        end
        root:CreateRadio("Vorlesen (Text-to-Speech)", function() return OC.SoundOf(e) == "tts" end,
            function() OC.SetSound(e, "tts") if after then after() end end)
    end)
end

function OC.NextRank(e)
    local m = Mem()
    if not (m and e.ranks and #e.ranks > 1) then return end
    local idx = 1
    for i, r in ipairs(e.ranks) do if r == e.id then idx = i end end
    local r = e.ranks[idx % #e.ranks + 1]
    m.rank[e.key] = (r ~= e.ranks[#e.ranks]) and r or nil
    e.id, e.rank, e.tex = r, SpellRank(r), Texture(r)
    OC.Refresh()
end

function OC.Cycle(e)
    local cur = OC.Slot(e)
    local nxt = OC.NextSlot(cur)
    OC.SetSlot(e, nxt)
end

-- "Voreinstellung wiederherstellen": eigene Wahl je Zauber vergessen,
-- Groessen und Schalter auf Werk. Die Wahl des Managers bleibt.
function OC.ResetPreset()
    local m = Mem()
    if not m then return end
    m.spells = {}
    for k in pairs(OC.DEFAULTS) do m[k] = nil end
    OC.Refresh()
end

--------------------------------------------------
-- Anzeige
--------------------------------------------------

local rows = {}
OC.rows = rows
OC.prev = {}
OC.prevDot = {}

local function Now()
    local t = _G.GetTime and Plain(_G.GetTime())
    return type(t) == "number" and t or 0
end

-- true/false nur bei offener Antwort des Clients, sonst nil.
function OC.Usable(id)
    local cs = _G.C_Spell
    local f = (cs and cs.IsSpellUsable) or _G.IsUsableSpell
    if not f then return nil end
    local ok, u, noMana = pcall(f, id)
    if not ok then return nil end
    u, noMana = Plain(u), Plain(noMana)
    if type(u) ~= "boolean" then return nil end
    if u == false and noMana == true then return false end
    return u
end

function OC.HasEnemyTarget()
    if not (_G.UnitExists and _G.UnitCanAttack) then return false end
    local ok, ex = pcall(_G.UnitExists, "target")
    if not (ok and K.Bool(ex, false)) then return false end
    local ok2, can = pcall(_G.UnitCanAttack, "player", "target")
    if not (ok2 and K.Bool(can, false)) then return false end
    if _G.UnitIsDead then
        local ok3, dead = pcall(_G.UnitIsDead, "target")
        if ok3 and K.Bool(dead, false) then return false end
    end
    return true
end
local fighting = false

-- 1.0.7.8 (Bild: Zahl trotz "Restzeit in Zahlen" aus, Debuffs doppelt):
-- SetHideCountdownNumbers allein haelt nicht ueberall - die Zahl der Uhr
-- zusaetzlich ueber ihre Schrift ein- und ausblenden.
function OC.CountdownShown(cd, on)
    if not cd then return end
    if cd.SetHideCountdownNumbers then pcall(cd.SetHideCountdownNumbers, cd, not on) end
    if cd.GetCountdownFontString then
        local ok, fs = pcall(cd.GetCountdownFontString, cd)
        if ok and type(fs) == "table" and fs.SetAlpha then fs:SetAlpha(on and 1 or 0) end
    end
end

local slotNumbers
local function Icon(parent)
    local b = CreateFrame("Frame", nil, parent)
    b.isBar = false
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
    -- Hinter dem Symbol (6.90.1.0): oben drauf deckte die Flaeche das Bild ganz zu.
    b.glow = K.Glow(b, { layer = "BACKGROUND", spread = 5, color = C.successBright, shown = false })
    -- Pulsieren (6.96.0.0): Alpha-Animation der Engine, kein OnUpdate.
    local ag = b.glow.tex:CreateAnimationGroup()
    ag:SetLooping("BOUNCE")
    local a = ag:CreateAnimation("Alpha")
    a:SetFromAlpha(1)
    a:SetToAlpha(0.25)
    a:SetDuration(0.6)
    if a.SetSmoothing then a:SetSmoothing("IN_OUT") end
    b.pulse = ag
    b.state = K.NewText(top, 10)
    b.state:SetPoint("BOTTOM", b, "BOTTOM", 0, 2)
    b:Hide()
    return b
end

local function Ensure(row, n)
    for i = #row.icons + 1, n do
        row.icons[i] = Icon(row)
        if row.onNew then row.onNew(row.icons[i]) end
    end
end

-- Balken (1.0.9.0): Symbol links, Leiste mit Name und Restzeit. Laeuft eine
-- Wirkung oder Abklingzeit mit bekannter Laenge, zaehlt ein OnUpdate am
-- Balken selbst herunter - nur dann, und ohne Tabellen je Bild; der Text
-- wird nur neu gesetzt, wenn sich die angezeigte Zahl aendert.
function OC.BarTime(left)
    if left >= 60 then return string.format("%d:%02d", math.floor(left / 60), math.floor(left % 60)) end
    if left >= 10 then return tostring(math.floor(left)) end
    return string.format("%.1f", left)
end
local function BarTick(self)
    local endAt, dur = self._endAt2, self._dur2
    if not (endAt and dur and dur > 0) then self:SetScript("OnUpdate", nil) return end
    local left = endAt - Now()
    if left <= 0 then
        self:SetScript("OnUpdate", nil)
        self.sb:SetValue(0)
        OC.pending = true
        return
    end
    self.sb:SetValue(left / dur)
    local key = left >= 10 and -math.floor(left) or math.floor(left * 10)
    if key ~= self._tkey then
        self._tkey = key
        self.time:SetText(self._numbers and OC.BarTime(left) or "")
    end
end
OC.BarTick = BarTick

local function Bar(parent)
    local b = CreateFrame("Frame", nil, parent)
    b.isBar = true
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetPoint("TOPLEFT", b, "TOPLEFT", 0, 0)
    b.icon:SetPoint("BOTTOMLEFT", b, "BOTTOMLEFT", 0, 0)
    b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    b.sb = K.NewBar(b)
    b.sb:SetMinMaxValues(0, 1)
    b.sb:SetValue(0)
    b.sb:SetPoint("TOPLEFT", b.icon, "TOPRIGHT", 1, 0)
    b.sb:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", 0, 0)
    b.track = b:CreateTexture(nil, "BACKGROUND")
    b.track:SetAllPoints(b.sb)
    local tr = WeintCodex.GameColors.barTrack
    b.track:SetColorTexture(tr[1], tr[2], tr[3], tr[4])
    -- Unsichtbare Uhr: Clock() liest und setzt die Abklingzeit wie am Symbol.
    b.cd = CreateFrame("Cooldown", nil, b, "CooldownFrameTemplate")
    b.cd:SetAllPoints(b.icon)
    b.cd:SetAlpha(0)
    local top = CreateFrame("Frame", nil, b)
    top:SetAllPoints(b)
    top:SetFrameLevel((b.sb:GetFrameLevel() or 1) + 2)
    K.Border(top, 1, 0, 0, 0, 1, "OVERLAY")
    b.name = K.NewText(top, 11)
    b.name:SetPoint("LEFT", b.sb, "LEFT", 4, 0)
    b.name:SetPoint("RIGHT", b.sb, "RIGHT", -34, 0)
    b.name:SetJustifyH("LEFT")
    if b.name.SetWordWrap then b.name:SetWordWrap(false) end
    b.time = K.NewText(top, 11)
    b.time:SetPoint("RIGHT", b.sb, "RIGHT", -4, 0)
    b.time:SetJustifyH("RIGHT")
    b.state = b.time
    b.glow = K.Glow(b, { layer = "BACKGROUND", spread = 5, color = C.successBright, shown = false })
    local ag = b.glow.tex:CreateAnimationGroup()
    ag:SetLooping("BOUNCE")
    local a = ag:CreateAnimation("Alpha")
    a:SetFromAlpha(1)
    a:SetToAlpha(0.25)
    a:SetDuration(0.6)
    if a.SetSmoothing then a:SetSmoothing("IN_OUT") end
    b.pulse = ag
    b:Hide()
    return b
end
OC.NewBar = Bar

local function NeedIcon(row, i)
    Ensure(row, i)
    return row.icons[i]
end
-- Felder der Reihe ueber rawget: an Rahmen der Pruef-Attrappe liefern
-- unbekannte Felder Funktionen, im Client nil.
local function Field(row, key)
    local v = _G.rawget(row, key)
    if type(v) ~= "table" then v = {} row[key] = v end
    return v
end
local function NeedBar(row, i)
    Field(row, "bars")
    for j = #row.bars + 1, i do
        row.bars[j] = Bar(row)
        if row.onNew then row.onNew(row.bars[j]) end
    end
    return row.bars[i]
end

-- Groesse eines Balkens: Breite und Hoehe je Reihe (RowOpt barWidth,
-- barHeight; ohne Wahl aus der Symbolgroesse).
function OC.BarSize(slot, s)
    local w = tonumber(OC.RowOpt(slot, "barWidth")) or 180
    local h = tonumber(OC.RowOpt(slot, "barHeight")) or math.max(14, math.floor(s * 0.6 + 0.5))
    return w, h
end
local function SizeBar(b, w, h)
    if b._w == w and b._h == h then return end
    b._w, b._h = w, h
    b:SetSize(w, h)
    b.icon:SetWidth(h)
    local fs = math.max(8, math.min(16, math.floor(h * 0.6)))
    K.SetFont(b.name, fs)
    K.SetFont(b.time, fs)
end

-- Anordnung (6.90.1.0, Wunsch): waagerecht oder senkrecht, umbrechen nach
-- "Symbole je Zeile" (0 = alle in einer Zeile); mittig wie die Reihen des Spiels.
-- Einstellungen je Reihe (6.98.2.0, Wunsch: "die einzelnen Reihen auch
-- einstellen koennen in Groesse etc"). m.rowOpt[slot] = { size, vertical,
-- perLine, gap, combatOnly }; fehlt ein Wert, gilt der allgemeine.
function OC.RowOpt(slot, key)
    local m = Mem()
    local o = m and m.rowOpt and m.rowOpt[slot]
    local v = o and o[key]
    if v ~= nil then return v end
    if key == "size" then
        if slot == "big" then return tonumber(OC.Get("big")) or 40 end
        if slot == "small" then return tonumber(OC.Get("small")) or 28 end
        if slot == "buffs" or slot == "debuffs" then return tonumber(OC.Get("buff")) or 28 end
        local d = OC.ExtraDef(slot)
        return d and tonumber(d.size) or 32
    end
    if key == "vertical" then return OC.Get("vertical") and true or false end
    if key == "perLine" then return tonumber(OC.Get("perLine")) or 0 end
    if key == "gap" then return 4 end
    if key == "combatOnly" then return OC.Get("combatOnly") and true or false end
    return nil
end
function OC.SetRowOpt(slot, key, v)
    local m = Mem()
    if not m then return end
    m.rowOpt = m.rowOpt or {}
    m.rowOpt[slot] = m.rowOpt[slot] or {}
    m.rowOpt[slot][key] = v
    OC.Refresh()
    -- Groesse, Anordnung, Balken: die Buehne der Einstellungen folgt.
    local ST = WeintCodex.UICooldownStage
    if ST and ST.current and ST.current:IsVisible() and _G.C_Timer and _G.C_Timer.After then
        _G.C_Timer.After(0, OC.Relayout)
    end
end
OC.ROW_LABEL = { buffs = "Buffs", debuffs = "Eigene Debuffs" }

-- Anordnung gemischter Reihen (1.0.9.0): jedes Teil hat seine Groesse
-- (Symbol s x s, Balken Breite x Hoehe). Waagerecht: Zeilen zu "je Zeile"
-- Teilen, jede Zeile mittig; senkrecht: Spalten, jede mittig. Reine
-- Rechnung - ohne place nur die Groesse (fuer die Hoehe der Buehne).
local lineW, lineH = {}, {}
function OC.Layout(n, sizeOf, gap, per, vert, place)
    if per <= 0 or per > n then per = math.max(1, n) end
    local lines = math.max(1, math.ceil(n / per))
    local total1, total2 = 0, 0   -- Laenge (laengste Zeile), Breite (Summe der Zeilen)
    for l = 1, lines do
        local a, z = (l - 1) * per + 1, math.min(n, l * per)
        local len, thick = 0, 0
        for i = a, z do
            local w, h = sizeOf(i)
            if vert then w, h = h, w end
            len = len + w + (i > a and gap or 0)
            if h > thick then thick = h end
        end
        lineW[l], lineH[l] = len, thick
        if len > total1 then total1 = len end
        total2 = total2 + thick + (l > 1 and gap or 0)
    end
    if place then
        local off = 0
        for l = 1, lines do
            local a, z = (l - 1) * per + 1, math.min(n, l * per)
            local pos = (total1 - lineW[l]) / 2
            for i = a, z do
                local w, h = sizeOf(i)
                local along = vert and h or w
                if vert then place(i, off, -pos) else place(i, pos, -off) end
                pos = pos + along + gap
            end
            off = off + lineH[l] + gap
        end
    end
    if vert then return total2, total1 end
    return total1, total2
end

local function Arrange(row, n, s, slot)
    local gap = tonumber(OC.RowOpt(slot, "gap")) or 4
    local per = tonumber(OC.RowOpt(slot, "perLine")) or 0
    local vert = OC.RowOpt(slot, "vertical") and true or false
    local bw, bh = OC.BarSize(slot, s)
    local items = _G.rawget(row, "items")
    if type(items) ~= "table" then items = row.icons end
    -- Welche Plaetze Balken sind, als Zahl (bis 52 Teile; darueber immer neu).
    local mask = 0
    for i = 1, math.min(n, 52) do if items[i] and items[i].isBar then mask = mask + 2 ^ (i - 1) end end
    -- 1.0.5.43 (/wcui speicher: 3,6 ms/s): nur neu anordnen, wenn sich
    -- etwas geaendert hat - nicht bei jedem Takt. Dieselben Teile an
    -- denselben Plaetzen: row._layItems merkt sich, welches Teil wo stand.
    local L = row._lay
    if L and n <= 52 and L.n == n and L.s == s and L.gap == gap and L.per == per and L.vert == vert
       and L.bw == bw and L.bh == bh and L.mask == mask then
        local same = true
        for i = 1, n do if row._layItems[i] ~= items[i] then same = false break end end
        if same then return end
    end
    if not L then L = {} row._lay = L row._layItems = {} end
    L.n, L.s, L.gap, L.per, L.vert, L.bw, L.bh, L.mask = n, s, gap, per, vert, bw, bh, mask
    for i = 1, n do row._layItems[i] = items[i] end
    for i = n + 1, #row._layItems do row._layItems[i] = nil end
    local function sizeOf(i)
        local b = items[i]
        if b and b.isBar then return bw, bh end
        return s, s
    end
    local w, h = OC.Layout(n, sizeOf, gap, per, vert, function(i, x, y)
        local b = items[i]
        if b.isBar then SizeBar(b, bw, bh) else b:SetSize(s, s) end
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", row, "TOPLEFT", x, y)
    end)
    row:SetSize(math.max(s, w), math.max(s, h))
end

-- Uhr des Spiels; gibt "ready"/"cd"/nil (weiss nicht) zurueck.
local function Clock(b, id)
    local cs = _G.C_Spell
    local start, duration, gcd
    if cs and cs.GetSpellCooldown then
        local ok, info = pcall(cs.GetSpellCooldown, id)
        if ok and type(info) == "table" then start, duration, gcd = info.startTime, info.duration, info.isOnGCD end
    elseif _G.GetSpellCooldown then
        local ok, s, d = pcall(_G.GetSpellCooldown, id)
        if ok then start, duration = s, d end
    end
    local d = Plain(duration)
    local s0 = Plain(start)
    b._start = type(s0) == "number" and s0 or nil
    local onGCD = K.Bool(gcd, false) or (type(d) == "number" and d > 0 and d <= 1.5)
    if type(d) == "number" and (d <= 0 or onGCD) then
        b.cd:Clear()
        return "ready"
    end
    if cs and cs.GetSpellCooldownDuration and b.cd.SetCooldownFromDurationObject then
        local ok, dur = pcall(cs.GetSpellCooldownDuration, id)
        if ok and dur and pcall(b.cd.SetCooldownFromDurationObject, b.cd, dur) then
            return type(d) == "number" and "cd" or nil, d
        end
    end
    if type(start) == "nil" or type(duration) == "nil" then b.cd:Clear() return nil end
    pcall(b.cd.SetCooldown, b.cd, start, duration)
    return type(d) == "number" and "cd" or nil, d
end

-- Abklingzeit selbst mitgerechnet (6.97.3.0, Beta-Test: Arkaner Schuss
-- wurde im Kampf nicht grau). Im Kampf nennt der Client die Dauer nur
-- geheim; die Uhr zeichnet er trotzdem, sagen kann ein Addon daraus
-- nichts. Darum: Laenge einmal offen gelernt (ausserhalb des Kampfes)
-- oder aus GetSpellBaseCooldown, Start aus dem eigenen Wirken.
OC.lastCast = {}   -- Name -> Zeit des letzten eigenen Wirkens
OC.cdLen = {}      -- Name -> Sekunden (gelernt)
function OC.Learn(name, d)
    if name and type(d) == "number" and d > 1.5 then OC.cdLen[name] = d end
end
function OC.Estimate(e)
    local t = e.name and OC.lastCast[e.name]
    if not t then return nil end
    local len = OC.cdLen[e.name]
    if not len and not e.item then
        local fn = _G.GetSpellBaseCooldown
        if type(fn) == "function" then
            local ok, ms = pcall(fn, e.id)
            ms = ok and Plain(ms) or nil
            if type(ms) == "number" and ms > 1500 then len = ms / 1000 OC.cdLen[e.name] = len end
        end
    end
    if not len then return nil end
    local now = _G.GetTime and Plain(_G.GetTime()) or 0
    return now < t + len and "cd" or "ready"
end

-- Wie OC.Estimate, aber mit Zahlen fuer den Balken: Ende, Laenge - oder nil.
function OC.EstimateEnd(e)
    if OC.Estimate(e) ~= "cd" then return nil end
    local t, len = OC.lastCast[e.name], OC.cdLen[e.name]
    if not (t and len) then return nil end
    return t + len, len
end

function OC.ItemClock(b, id)
    local f = (_G.C_Container and _G.C_Container.GetItemCooldown) or _G.GetItemCooldown
    if not f then b.cd:Clear() return nil end
    local ok, start, duration = pcall(f, id)
    local d = ok and Plain(duration) or nil
    if type(d) ~= "number" then b.cd:Clear() return nil end
    if d <= 1.5 then b.cd:Clear() return "ready" end
    pcall(b.cd.SetCooldown, b.cd, start, duration)
    return "cd"
end

-- Farbe, Staerke und Pulsieren des Leuchtens (Farben aus core/ui.lua).
OC.GLOW_COLORS = {
    { value = "green", text = "Grün", token = "successBright" },
    { value = "gold",  text = "Gold", token = "gold" },
    { value = "class", text = "Klassenfarbe", token = "accent" },
    { value = "red",   text = "Rot",  token = "dangerBright" },
    { value = "blue",  text = "Blau", token = "infoBright" },
    { value = "white", text = "Weiß", token = "textBright" },
}
function OC.GlowRGB()
    local want = OC.Get("glowColor")
    for _, c in ipairs(OC.GLOW_COLORS) do
        if c.value == want then return C[c.token] or C.successBright end
    end
    return C.successBright
end

function OC.ShowGlow(b, on)
    if on then
        local c = OC.GlowRGB()
        local s = (tonumber(OC.Get("glowStrength")) or 100) / 100
        b.glow:SetColor(c[1], c[2], c[3], math.max(0.1, math.min(1, s)))
        b.glow:SetSpread(3 + math.floor(4 * s + 0.5))
    end
    b.glow:SetShown(on)
    if b.pulse then
        local want = on and OC.Get("glowPulse") and true or false
        if want and not b.pulse:IsPlaying() then b.pulse:Play()
        elseif not want and b.pulse:IsPlaying() then b.pulse:Stop() b.glow.tex:SetAlpha(1) end
    end
end

local function Visible()
    if not OC.Active() then return false end
    if OC.Get("combatOnly") and not (fighting or K.InCombat()) then return false end
    return true
end

local effBuf = {}
-- Balken einer Faehigkeit zeichnen: Wirkung, sonst Abklingzeit, sonst bereit.
-- b._inst: der wievielte laufende Falke (je Wirkung ein Balken).
-- Unbekannt (geheim, nie selbst gewirkt) ist leer mit "?", nie "bereit".
function OC.DrawBar(b, e, st, numbers)
    local GC = WeintCodex.GameColors
    if b._nameKey ~= e.key then b._nameKey = e.key b.name:SetText(e.name or "") end
    b._numbers = numbers
    local es, ed
    if b._inst then
        local n, dur = OC.Effects(e, effBuf)
        if n > 0 then es, ed = effBuf[math.min(b._inst, n)], dur end
    else
        es, ed = OC.EffectOf(e)
    end
    local endAt, dur, phase
    if es then
        phase, endAt, dur = "effect", es + ed, ed
    elseif st == "cd" then
        if type(b._endAt) == "number" and b._endAt ~= math.huge and type(b._start) == "number" and b._endAt > b._start then
            endAt, dur = b._endAt, b._endAt - b._start
        else
            endAt, dur = OC.EstimateEnd(e)
        end
        phase = endAt and "cd" or "cdq"
    elseif st == "ready" then
        phase = "ready"
    else
        phase = "unknown"
    end
    b.phase = phase
    local c = (phase == "effect" and OC.BarRGB(e)) or (phase == "ready" and GC.ocdReady) or GC.ocdCooldown
    K.PaintBar(b.sb, c[1], c[2], c[3])
    if phase == "effect" or phase == "cd" then
        b._endAt2, b._dur2, b._tkey = endAt, dur, nil
        b:SetScript("OnUpdate", BarTick)
        BarTick(b)
    else
        b:SetScript("OnUpdate", nil)
        b.sb:SetValue(phase == "ready" and 1 or 0)
        b.time:SetText(phase == "ready" and "bereit" or phase == "cdq" and "läuft" or "?")
    end
    return phase
end

local function DrawSpells(row, slot, size, show)
    local items = Field(row, "items")
    Field(row, "bars")
    local n, ni, nb = 0, 0, 0
    if show or row._unlock then
        for _, e in ipairs(OC.known) do
            if OC.Slot(e) == slot then
                n = n + 1
                local b
                if OC.Display(e) == "bar" then
                    -- Mehrere Wirkungen zugleich (Falken): je eine ein Balken,
                    -- aelteste zuerst; sonst einer.
                    local k = OC.Effects(e, effBuf)
                    nb = nb + 1
                    b = NeedBar(row, nb)
                    b._inst = k > 1 and 1 or nil
                    items[n], b._e = b, e
                    for inst = 2, k do
                        n, nb = n + 1, nb + 1
                        local b2 = NeedBar(row, nb)
                        b2._inst, b2._e = inst, e
                        items[n] = b2
                    end
                else
                    ni = ni + 1
                    b = NeedIcon(row, ni)
                    items[n], b._e = b, e
                    -- Symbol + je laufender Wirkung ein Balken daneben.
                    if OC.Display(e) == "both" then
                        local k = OC.Effects(e, effBuf)
                        for inst = 1, k do
                            n, nb = n + 1, nb + 1
                            local b2 = NeedBar(row, nb)
                            b2._inst, b2._e = inst, e
                            items[n] = b2
                        end
                    end
                end
            end
        end
        if n == 0 and row._unlock then
            n, ni = 1, 1
            items[1] = NeedIcon(row, 1)
            items[1]._e = nil
        end
    end
    for j = n + 1, #items do items[j] = nil end
    Arrange(row, n, size, slot)
    local numbers, glow = OC.Get("numbers") and true or false, OC.Get("glow") and true or false
    local i = 0
    for k = 1, n do
        local b, e = items[k], items[k]._e
        if e then
            i = i + 1
            b.icon:SetTexture(e.tex)
            OC.CountdownShown(b.cd, numbers)
            local st, rawD
            -- 1.0.5.43: die Uhr des Spiels nur nach einem Ereignis fragen
            -- (jede Abfrage legt beim Client neue Tabellen an). Dazwischen
            -- reicht die gemerkte Endzeit; die Uhr am Symbol laeuft allein.
            -- Geheim (im Kampf, b._st = nil): bis zum naechsten Ereignis
            -- schaetzt OC.Estimate weiter unten, wie zuvor.
            if not OC.clockDirty and b._spell == e.key then
                if b._st == "cd" and type(b._endAt) == "number" and Now() >= b._endAt then b.cd:Clear() b._st = "ready" end
                st = b._st
            else
                if e.item then st = OC.ItemClock(b, e.id) else st, rawD = Clock(b, e.id) end
                b._spell, b._st, b._endAt = e.key, st, nil
                if st == "ready" then b._endAt = math.huge
                elseif st == "cd" and type(rawD) == "number" and type(b._start) == "number" then
                    b._endAt = b._start + rawD
                end
            end
            OC.Learn(e.name, rawD)
            -- Geheim (im Kampf): selbst mitgerechnet
            if st == nil and not e.item then st = OC.Estimate(e) end
            -- Eigener DoT auf dem Ziel: seine Laufzeit statt "bereit"
            local ds, dd
            if not e.item then ds, dd = OC.DotOn(e.name) end
            if ds and (st == "ready" or st == nil) then
                pcall(b.cd.SetCooldown, b.cd, ds, dd)
                st = "dot"
            end
            if b.cd.SetReverse then b.cd:SetReverse(st == "dot") end
            -- Leuchten je Zauber: wenn bereit, oder wenn der DoT fehlt/auslaeuft
            local gm = OC.GlowMode(e)
            local dotLeft = ds and (ds + dd - Now()) or nil
            local needDot = OC.DotDuration(e.name) and OC.HasEnemyTarget()
                and (not ds or (dotLeft and dotLeft <= OC.DOT_WARN)) or false
            OC.ShowGlow(b, (gm == "ready" and st == "ready") or (gm == "dot" and needDot and st ~= "cd"))
            -- Ausgegraut, wenn der Client sagt: gerade nicht nutzbar (Proc fehlt,
            -- falsche Haltung) - nur bei offener Antwort, geheim = farbig.
            local usable = e.item and true or OC.Usable(e.id)
            -- Grau auch, solange eine Abklingzeit laeuft (6.96.0.0, Wunsch)
            local grey = usable == false or st == "cd"
            if b.icon.SetDesaturated then b.icon:SetDesaturated(grey) end
            local v = grey and 0.55 or 1
            b.icon:SetVertexColor(v, v, v)
            -- Ton: beim Wechsel auf "bereit" bzw. wenn der DoT auslaeuft.
            -- Die Vorschau der Einstellungen (row._preview) spielt nie und
            -- merkt sich nichts - sonst klaengen Toene doppelt oder gar nicht.
            if not row._preview then
                local was, wasDot = OC.prev[e.key], OC.prevDot[e.key]
                if st then OC.prev[e.key] = st end
                -- Auslaufen nur auf demselben Ziel - ein Zielwechsel ist kein Ablauf
                local tg = OC.TargetGUID and OC.TargetGUID() or "?"
                wasDot = wasDot and wasDot == tg
                OC.prevDot[e.key] = ds and tg or false
                local snd = OC.SoundOf(e)
                if snd ~= "none" then
                    local when = OC.SoundWhen(e)
                    if (when == "ready" and was == "cd" and st == "ready")
                       or (when == "dot" and wasDot and not ds) then
                        OC.PlaySound(snd, e)
                    end
                end
            end
            if b.isBar then
                OC.DrawBar(b, e, st, numbers)
            else
                -- Mehrere Wirkungen zugleich (Falken): ihre Zahl am Symbol.
                local k = (not e.item) and OC.Effects(e, effBuf) or 0
                b.state:SetText(k > 1 and tostring(k) or "")
            end
            b:Show()
        else   -- Gestaltungsmodus ohne Zauber: ein Platzhalter
            b.icon:SetTexture(134400)
            b.cd:Clear()
            OC.ShowGlow(b, false)
            b.state:SetText(OC.SlotText(slot))
            b:Show()
        end
    end
    for j = ni + 1, #row.icons do row.icons[j]:Hide() end
    for j = nb + 1, #row.bars do row.bars[j]:SetScript("OnUpdate", nil) row.bars[j]:Hide() end
end
OC.DrawSpells = DrawSpells

local function DrawBuffs(row, size, show)
    local BT = WeintCodex.UIBuffTimes
    local list = (BT and BT.Entries and (show and OC.Get("buffs") or row._unlock))
        and BT.Entries(_G.GetTime and _G.GetTime() or 0, fighting or K.InCombat(), true, row._unlock) or nil
    local n = list and #list or 0
    Ensure(row, n)
    Arrange(row, n, size, "buffs")
    for i = 1, n do
        local e, b = list[i], row.icons[i]
        b.icon:SetTexture(Texture(e.spell))
        local a = BT.active[e.group.key]
        if e.state == "time" and a then b.cd:SetCooldown(a.start, a.duration) else b.cd:Clear() end
        OC.CountdownShown(b.cd, OC.Get("numbers") and true or false)
        b.icon:SetDesaturated(e.state == "missing")
        OC.ShowGlow(b, false)
        b.state:SetText(e.state == "on" and "an" or e.state == "runs" and "läuft" or e.state == "missing" and "!" or "")
        b:Show()
    end
    for j = n + 1, #row.icons do row.icons[j]:Hide() end
end

-- 1.0.6.27 (Wunsch: "was auch bei Naowh moeglich ist, inkl. Tracking der
-- Debuffs, die man selbst gemacht hat"): eigene Debuffs auf dem Ziel. Im
-- Kampf gibt der Client Addons keine Auren heraus - der Aurenbehaelter des
-- Spiels (ui/auras.lua) zeigt sie trotzdem, mit Restzeit. WeintCodex liest
-- nichts davon. Groesse/Anordnung nur ausserhalb des Kampfes (die Felder
-- des Behaelters verweigern sich, solange Auren geheim sind); zeigen und
-- verbergen ueber die Deckkraft, das geht immer.
-- 1.0.6.28 ("ich will das alles haben", Verhalten nach Naowh Forever
-- "Raid Debuffs", kein Code - All Rights Reserved): je Klasse feste Felder
-- fuer die eigenen Debuffs. Im Feld liegt unten ein eigenes, abgedunkeltes
-- Symbol ("fehlt"), darueber ein Aurenbehaelter des Spiels fuer genau
-- diesen Zauber (alle Raenge). Liegt der Debuff, zeigt das Spiel ihn mit
-- Restzeit und deckt das Fehlt-Symbol ab - auch im Kampf, ohne dass
-- WeintCodex eine Aura liest. Nummern aus Classic (Lehrerbestand): wo
-- Forever neu nummeriert, bleibt das Feld "fehlt" - ungeprueft.
OC.DEBUFFS = {
    WARRIOR = { { "sunder", 7386, "Rüstung zerreißen" }, { "rend", 772, "Verwunden" },
                { "demo", 1160, "Demoralisierender Ruf" }, { "thunder", 6343, "Donnerknall" },
                { "hamstring", 1715, "Kniesehne" } },
    ROGUE   = { { "rupture", 1943, "Blutung" }, { "expose", 8647, "Rüstung schwächen" },
                { "garrote", 703, "Erdrosseln" } },
    HUNTER  = { { "mark", 1130, "Mal des Jägers" }, { "serpent", 1978, "Schlangenbiss" },
                { "scorpid", 3043, "Skorpidstich" }, { "viper", 3034, "Vipernbiss" },
                { "wingclip", 2974, "Zurechtstutzen" } },
    WARLOCK = { { "corruption", 172, "Verderbnis" }, { "agony", 980, "Fluch der Pein" },
                { "immolate", 348, "Feuerbrand" }, { "weakness", 702, "Fluch der Schwäche" },
                { "reckless", 704, "Fluch der Tollkühnheit" }, { "elements", 402792, "Fluch der Elemente" },
                { "tongues", 1714, "Fluch der Sprachen" } },
    PRIEST  = { { "swp", 589, "Schattenwort: Schmerz" } },
    DRUID   = { { "moonfire", 8921, "Mondfeuer" }, { "faerie", 770, "Feenfeuer" },
                { "rake", 1822, "Krallenhieb" }, { "rip", 1079, "Zerfetzen" },
                { "roar", 99, "Demoralisierendes Gebrüll" } },
    SHAMAN  = { { "flameshock", 8050, "Flammenschock" } },
    MAGE    = {},
    PALADIN = {},
}

-- Nicht beim Lehrer (Startzauber oder auf Forever anders gelehrt):
-- Nummer aus Classic, ungeprueft. load_test.lua laesst nur diese durch.
OC.DEBUFF_UNTRAINED = { [7386] = true, [1079] = true, [402792] = true }

local function PlayerClass()
    if not _G.UnitClass then return nil end
    local _, c = _G.UnitClass("player")
    c = K.Plain(c)
    return type(c) == "string" and c or nil
end

function OC.DebuffOn(key)
    local v = OC.Get("dbf_" .. key)
    if v == nil then return true end
    return v and true or false
end
function OC.SetDebuffOn(key, on)
    OC.Set("dbf_" .. key, on and true or false)
    OC.debuffDirty = true
    OC.Refresh()
end
-- Was die Reihe zeigt: Felder der Klasse, die an sind und gelernt.
function OC.DebuffList(class)
    local out = {}
    for _, d in ipairs(OC.DEBUFFS[class or PlayerClass() or ""] or {}) do
        if OC.DebuffOn(d[1]) and (OC.debuffAll or Known(d[2]) or OC.KnownAnyRank(d[2])) then
            out[#out + 1] = d
        end
    end
    return out
end
function OC.KnownAnyRank(id)
    local GF = WeintCodex.UIGroupFrames
    local set = GF and GF.RankSet and GF.RankSet(id)
    if not set then return false end
    for x in pairs(set) do if Known(x) then return true end end
    return false
end

-- Alle Nummern eines Debuffs: Raenge aus dem Lehrerbestand, Fassungen von
-- Forever (data/debuffids_nf.lua) und was WeintCodex selbst am Ziel gesehen
-- hat (OC.LearnDebuffs, je Konto in WeintCodex_SavedData.debuffIds).
local function Learned()
    local sd = _G.WeintCodex_SavedData
    if type(sd) ~= "table" then return nil end
    sd.debuffIds = sd.debuffIds or {}
    return sd.debuffIds
end
function OC.DebuffIDs(d)
    local GF = WeintCodex.UIGroupFrames
    local set = {}
    for id in pairs((GF and GF.RankSet and GF.RankSet(d[2])) or { [d[2]] = true }) do set[id] = true end
    for _, id in ipairs((WeintCodex.DebuffIDs or {})[d[2]] or {}) do set[id] = true end
    local l = Learned()
    for id in pairs(l and l[d[2]] or {}) do set[id] = true end
    return set
end

-- 1.0.7.1 (Bild: "es wird nicht angezeigt, welche Debuffs drauf sind"):
-- Forever fuehrt manche Debuffs unter anderen Nummern. Ausserhalb des
-- Kampfes liest WeintCodex die eigenen Debuffs am Ziel; heisst einer wie
-- ein Feld, kommt seine Nummer dazu (gemerkt) und das Feld des Spiels
-- bekommt die neue Liste. Im Kampf nie (geheim).
function OC.LearnDebuffs(row)
    if K.InCombat() then return 0 end
    local ua = _G.C_UnitAuras
    if not (ua and ua.GetAuraDataByIndex) then return 0 end
    local l = Learned()
    if not l then return 0 end
    local byName = {}
    for _, d in ipairs(OC.DEBUFFS[PlayerClass() or ""] or {}) do
        local n = SpellName(d[2])
        if n then byName[n] = d end
    end
    local added = 0
    for i = 1, 40 do
        local ok, a = pcall(ua.GetAuraDataByIndex, "target", i, "HARMFUL|PLAYER")
        if not ok or type(a) ~= "table" then break end
        local name, id = K.Plain(a.name), K.Plain(a.spellId)
        local d = type(name) == "string" and byName[name]
        if d and type(id) == "number" and not OC.DebuffIDs(d)[id] then
            l[d[2]] = l[d[2]] or {}
            l[d[2]][id] = true
            added = added + 1
            local c = row and row.slotC
            if c and c.SetAuraSlotCandidateFilters then
                pcall(c.SetAuraSlotCandidateFilters, c, d[1], { includeSpellIDs = OC.DebuffIDs(d) })
            end
        end
    end
    OC.learnedDebuffs = (OC.learnedDebuffs or 0) + added
    return added
end

-- Ein Behaelter des Spiels fuer die ganze Reihe, je Debuff ein Feld
-- (AddAuraSlot) ueber seinem Fehlt-Symbol - so wie Naowh Forever "Raid
-- Debuffs" (dort im Spiel bewaehrt; eigener Code). Felder lassen sich nicht
-- entfernen, nur abschalten (SetAuraSlotEnabled).
local function SlotContainer(row)
    if row.slotC ~= nil then return row.slotC or nil end
    local A = WeintCodex.UIAuras
    if not (A and A.EngineAvailable and A.EngineAvailable()) then row.slotC = false return nil end
    local ok, c = pcall(CreateFrame, "AuraContainer", nil, row, "CustomAuraContainerTemplate")
    if not (ok and c and c.AddAuraSlot) then row.slotC = false return nil end
    c:SetAllPoints(row)
    c:SetFrameLevel((row:GetFrameLevel() or 1) + 5)
    if c.EnableMouse then pcall(c.EnableMouse, c, false) end
    pcall(c.SetUnit, c, "target")
    row.slotC, row.slotKeys = c, {}
    return c
end
-- /wcui debuffs: Stand der Felder und was am Ziel liegt (nur ausserhalb des Kampfes lesbar).
function OC.DebuffReport()
    local out = {}
    local row = rows.debuffs
    out[#out + 1] = "Reihe an: " .. tostring(OC.Get("debuffs") and true or false) .. " · Behälter des Spiels: "
        .. (row and row.slotC and "ja" or (row and row.slotC == false and "NEIN" or "noch nicht gebaut"))
        .. (OC.slotError and (" · Fehler: " .. OC.slotError) or "")
    for _, d in ipairs(OC.DebuffList()) do
        local ids = {}
        for id in pairs(OC.DebuffIDs(d)) do ids[#ids + 1] = id end
        table.sort(ids)
        out[#out + 1] = d[3] .. ": " .. table.concat(ids, ", ") .. ((row and row.slotKeys and row.slotKeys[d[1]]) and "" or "  (kein Feld)")
    end
    local ua = _G.C_UnitAuras
    if ua and ua.GetAuraDataByIndex and not K.InCombat() then
        out[#out + 1] = "Eigene Debuffs am Ziel jetzt:"
        for i = 1, 40 do
            local ok, a = pcall(ua.GetAuraDataByIndex, "target", i, "HARMFUL|PLAYER")
            if not ok or type(a) ~= "table" then break end
            out[#out + 1] = "  " .. tostring(K.Plain(a.name)) .. " = " .. tostring(K.Plain(a.spellId))
        end
    end
    -- 1.0.7.9: woraus ein Feld des Spiels besteht (Zahl doppelt?).
    if K.InCombat() then out[#out + 1] = "Felder: im Kampf gesperrt – außerhalb des Kampfes noch einmal." end
    for b, n in pairs(K.InCombat() and {} or slotNumbers) do
        OC.ScanSlot(b)
        local parts = {}
        for _, fs in ipairs(n.foreign) do
            local ok, t = pcall(fs.GetText, fs)
            local okA, al = pcall(fs.GetAlpha, fs)
            parts[#parts + 1] = tostring(ok and K.Plain(t) or "?") .. "@" .. tostring(okA and K.Plain(al) or "?")
        end
        local kids = 0
        if b.GetChildren then
            local okK, k = pcall(function() return select("#", b:GetChildren()) end)
            kids = okK and k or "?"
        end
        out[#out + 1] = "Feld: Kinder " .. kids .. ", fremde Schriften " .. #n.foreign .. ": " .. table.concat(parts, ", ")
    end
    out[#out + 1] = "Selbst gelernt bisher: " .. tostring(OC.learnedDebuffs or 0)
    return out
end

-- Zahlen der Debuff-Felder (je Feld des Spiels; Lua-Tabelle, nicht am Rahmen).
slotNumbers = setmetatable({}, { __mode = "k" })
-- Alle Schriften des Feldes ausser unserer Stapelzahl, auch in Kindern und
-- Enkeln (die Uhr des Spiels haengt ihre Zahl an einen eigenen Rahmen).
-- 1.0.7.9: auch spaeter neu gesucht - das Spiel baut Teile erst beim ersten
-- Zeigen.
local function ScanFrame(f, n, depth)
    if not (f and f.GetRegions) then return end
    for _, r in ipairs({ f:GetRegions() }) do
        if type(r) == "table" and r.GetObjectType and r:GetObjectType() == "FontString" and not n.own[r] then
            local dup
            for _, x in ipairs(n.foreign) do if x == r then dup = true break end end
            if not dup then n.foreign[#n.foreign + 1] = r end
        end
    end
    if depth < 3 and f.GetChildren then
        for _, ch in ipairs({ f:GetChildren() }) do ScanFrame(ch, n, depth + 1) end
    end
end
function OC.ScanSlot(button)
    local n = slotNumbers[button]
    if not n then return 0 end
    -- 1.0.7.10 (Fehlerbericht): im Kampf sind die Felder des Spiels fuer
    -- Addons gesperrt (GetRegions: forbidden object) - nur ausserhalb.
    if K.InCombat() then return #n.foreign end
    ScanFrame(button, n, 0)
    -- Auch die Zahl unserer Uhr zaehlt als fremd: das Spiel schaltet sie an.
    return #n.foreign
end
function OC.SlotNumbers(button, on)
    local n = slotNumbers[button]
    if not n then return end
    n.holder:SetAlpha(on and 1 or 0)
    -- Die Teile des Spiels nur ausserhalb des Kampfes anfassen (gesperrt).
    if K.InCombat() then return end
    for _, fs in ipairs(n.foreign) do pcall(fs.SetAlpha, fs, 0) end
    OC.CountdownShown(n.cd, false)
end

function OC.EnsureSlot(row, d, cell, size, timer)
    local c = SlotContainer(row)
    if not c then return false end
    local key = d[1]
    local slot = row.slotKeys[key]
    if not slot then
        local A = WeintCodex.UIAuras
        local ok, s = pcall(c.AddAuraSlot, c, key, "HARMFUL|PLAYER", {
            candidateFilters = { includeSpellIDs = OC.DebuffIDs(d) },
            initializeFrame = function(button)
                -- 1.0.7.6 (Bild: "2x eine Abklingzeit"): die Uhr des Spiels
                -- zeichnet ihre Zahl selbst, sobald der Behaelter sie fuehrt -
                -- also nur diese, keine eigene Restzeit daneben.
                -- 1.0.7.8: blieb doppelt - das Feld des Spiels bringt eine
                -- eigene Zahl mit. Genau eine Zahl: die des Feldes, wenn es
                -- eine hat, sonst die unserer Uhr; beide folgen dem Schalter.
                -- 1.0.7.9: feste Regel statt Raten. Das Spiel schaltet die
                -- Zahlen, die es dem Feld gibt, selbst an (Schalter half nicht).
                -- Darum: JEDE fremde Schrift im Feld dauerhaft unsichtbar
                -- (Alpha fasst das Spiel nicht an); die Restzeit schreibt das
                -- Spiel in UNSERE Schrift, die in einem eigenen Rahmen liegt -
                -- und nur dessen Alpha folgt dem Schalter.
                local icon, cd, count, dur = A.StyleIcon(button, size, { timer = true })
                local holder = CreateFrame("Frame", nil, button)
                holder:SetAllPoints(button)
                holder:SetFrameLevel((K.Plain(button:GetFrameLevel()) or 1) + 6)
                if holder.EnableMouse then holder:EnableMouse(false) end
                dur:SetParent(holder)
                dur:ClearAllPoints()
                dur:SetPoint("CENTER", button, "CENTER", 0, 0)
                dur:SetJustifyH("CENTER")
                K.SetFont(dur, math.max(10, math.floor(size * 0.5)))
                dur:Show()
                pcall(button.SetIcon, button, icon)
                pcall(button.SetDurationCooldown, button, cd)
                pcall(button.SetApplicationCount, button, count, {})
                pcall(button.SetDurationText, button, dur, {})
                slotNumbers[button] = { cd = cd, holder = holder, own = { [count] = true, [dur] = true }, foreign = {} }
                OC.ScanSlot(button)
                OC.SlotNumbers(button, timer)
                if button.EnableMouse then pcall(button.EnableMouse, button, false) end
            end,
        })
        if not (ok and s) then OC.slotError = tostring(s) return false end
        slot = s
        row.slotKeys[key] = slot
    end
    for b in pairs(slotNumbers) do OC.SlotNumbers(b, timer) end
    slot:ClearAllPoints()
    slot:SetAllPoints(cell)
    pcall(c.SetAuraSlotEnabled, c, key, true)
    return true
end

local function BuildSlot(row, d, size)
    local f = CreateFrame("Frame", nil, row)
    f:SetSize(size, size)
    f.miss = f:CreateTexture(nil, "BACKGROUND")
    f.miss:SetAllPoints(f)
    f.miss:SetTexture(Texture(d[2]))
    f.miss:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    f.edge = K.Border(f, 1, 0, 0, 0, 1, "BORDER")
    local warn = C.danger
    f.alert = K.Border(f, 2, warn[1], warn[2], warn[3], 1, "OVERLAY")
    f.alert:SetShown(false)
    f.key = d[1]
    return f
end

local debuffLayout
function OC.DebuffLayoutKey(size, vertical, perLine, gap)
    return size .. ":" .. tostring(vertical) .. ":" .. perLine .. ":" .. gap
end
local function DrawGeneric(row, size, vertical, perLine, gap, timer)
    local A = WeintCodex.UIAuras
    local max = 8
    local per = perLine > 0 and math.min(perLine, max) or max
    local o = { filter = "HARMFUL|PLAYER", max = max, size = size, spacing = gap,
        anchor = "TOPLEFT", growth = "RIGHT", growthV = "DOWN", timer = timer, perRow = vertical and 1 or per }
    if not row.auras then
        row.auras = A.Create(row, o)
        row.auras:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
        row.auras:SetUnit("target")
    elseif row._wcGen ~= OC.DebuffLayoutKey(size, vertical, perLine, gap) .. tostring(timer) then
        pcall(row.auras.ApplyLayout, row.auras, o)
    end
    row._wcGen = OC.DebuffLayoutKey(size, vertical, perLine, gap) .. tostring(timer)
    local cols = vertical and 1 or per
    local lines = math.ceil(max / cols)
    row:SetSize(cols * size + (cols - 1) * gap, lines * size + (lines - 1) * gap)
end

local function DrawDebuffs(row, size, show)
    local A = WeintCodex.UIAuras
    if not (row and A and A.Create) then return end
    local vertical = OC.RowOpt("debuffs", "vertical") and true or false
    local perLine = tonumber(OC.RowOpt("debuffs", "perLine")) or 0
    local gap = tonumber(OC.RowOpt("debuffs", "gap")) or 4
    local timer = OC.Get("numbers") and true or false
    local on = (show and OC.Get("debuffs") and OC.HasEnemyTarget()) or row._unlock
    row:SetAlpha(on and 1 or 0)
    -- Bauen und umstellen nur ausserhalb des Kampfes.
    -- Die Zahl folgt dem Schalter auch im Kampf (nur Alpha unseres Rahmens).
    for b in pairs(slotNumbers) do OC.SlotNumbers(b, timer) end
    if K.InCombat() then
        if row.slots then OC.PaintSlots(row) end
        return
    end
    local list = OC.DebuffList()
    local key = OC.DebuffLayoutKey(size, vertical, perLine, gap) .. tostring(timer) .. #list
    for _, d in ipairs(list) do key = key .. d[1] end
    if #list == 0 then
        if row.slots then for _, f in ipairs(row.slots) do f:Hide() end end
        if row.slotC then for k in pairs(row.slotKeys) do pcall(row.slotC.SetAuraSlotEnabled, row.slotC, k, false) end end
        DrawGeneric(row, size, vertical, perLine, gap, timer)
        if row.auras then row.auras:SetShown(true) end
        return
    end
    if row.auras then row.auras:SetShown(false) end
    local now = Now()
    if not OC.slotScanAt or now - OC.slotScanAt > 3 then
        OC.slotScanAt = now
        for b in pairs(slotNumbers) do OC.ScanSlot(b) OC.SlotNumbers(b, timer) end
    end
    if key ~= debuffLayout or OC.debuffDirty or not row.slots then
        debuffLayout, OC.debuffDirty = key, nil
        -- Alte Felder still legen (der Behaelter kennt kein Entfernen).
        for _, f in ipairs(row.slots or {}) do f:Hide() end
        if row.slotC then for k in pairs(row.slotKeys) do pcall(row.slotC.SetAuraSlotEnabled, row.slotC, k, false) end end
        row.slots = {}
        row.slotPool = row.slotPool or {}
        local per = perLine > 0 and perLine or #list
        if vertical then per = 1 end
        for i, d in ipairs(list) do
            local pk = d[1] .. ":" .. size
            local f = row.slotPool[pk]
            if not f then f = BuildSlot(row, d, size) row.slotPool[pk] = f end
            f:ClearAllPoints()
            local c, l = (i - 1) % per, math.floor((i - 1) / per)
            f:SetPoint("TOPLEFT", row, "TOPLEFT", c * (size + gap), -l * (size + gap))
            f:Show()
            OC.EnsureSlot(row, d, f, size, timer)
            row.slots[i] = f
        end
        local cols = math.min(per, #list)
        local lines = math.ceil(#list / per)
        row:SetSize(cols * size + (cols - 1) * gap, lines * size + (lines - 1) * gap)
    end
    OC.PaintSlots(row)
end

-- Fehlt-Symbol: abgedunkelt, oder mit "Fehlende hervorheben" hell mit
-- rotem Rand. Ob der Debuff liegt, weiss WeintCodex nicht - das Feld des
-- Spiels liegt einfach darueber.
function OC.PaintSlots(row)
    local hl = OC.Get("dbfHighlight") and true or false
    for _, f in ipairs(row.slots or {}) do
        f.miss:SetDesaturated(not hl)
        f.miss:SetAlpha(hl and 1 or 0.45)
        f.alert:SetShown(hl)
    end
end

-- Reihe zeigen? Allgemein sichtbar und - je Reihe - "nur im Kampf".
function OC.RowShow(slot, show)
    if not show then return false end
    if OC.RowOpt(slot, "combatOnly") and not (fighting or K.InCombat()) then return false end
    return true
end

function OC.Update()
    if not rows.big then return end
    local show = Visible()
    DrawSpells(rows.big, "big", OC.RowOpt("big", "size"), OC.RowShow("big", show))
    DrawSpells(rows.small, "small", OC.RowOpt("small", "size"), OC.RowShow("small", show))
    DrawBuffs(rows.buffs, OC.RowOpt("buffs", "size"), OC.RowShow("buffs", show))
    if rows.debuffs then pcall(DrawDebuffs, rows.debuffs, OC.RowOpt("debuffs", "size"), OC.RowShow("debuffs", show)) end
    -- Eigene Reihen: Rahmen bei Bedarf, geloeschte bleiben leer
    local seen = OC.seenRows
    for k in _G.next, seen do seen[k] = nil end
    for _, d in ipairs(OC.ExtraRows()) do
        local row = OC.extraRows[d.id]
        if not row then
            row = CreateFrame("Frame", "WeintCodexOwnCooldowns_" .. d.id, UIParent)
            row:SetSize(28, 28)
            row.icons = {}
            row.WCShowForUnlock = function(self, on) self._unlock = on and true or nil OC.Update() end
            K.RegisterMover(row, "ocd_x_" .. d.id, "Abklingzeiten: " .. d.name, OC.ExtraDefault(d.id))
            OC.extraRows[d.id] = row
        end
        seen[d.id] = true
        DrawSpells(row, d.id, OC.RowOpt(d.id, "size"), OC.RowShow(d.id, show))
    end
    for id, row in pairs(OC.extraRows) do
        if not seen[id] then
            row._unlock = nil
            DrawSpells(row, id, 28, false)
            if K.SetMoverEnabled then pcall(K.SetMoverEnabled, "ocd_x_" .. id, false) end
        elseif K.SetMoverEnabled then pcall(K.SetMoverEnabled, "ocd_x_" .. id, true) end
    end
end
OC.extraRows = {}
OC.seenRows = {}

-- Die Buffzeiten-Reihe zeigt dasselbe - solange unsere Buffs laufen, steht
-- sie nicht doppelt da (ui/bufftimes.lua fragt hier).
function OC.OwnsBuffs()
    return OC.Active() and OC.Get("buffs") and true or false
end

function OC.Refresh()
    OC.Update()
    local BT = WeintCodex.UIBuffTimes
    if BT and BT.Update then pcall(BT.Update) end
end

local acc, since = 0, 0
OC.CLOCK_EVERY = 2      -- die Uhren des Spiels ohne Ereignis spaetestens so oft neu lesen
local clockAcc = 0
local function Tick(_, el)
    el = el or 0
    acc, since, clockAcc = acc + el, since + el, clockAcc + el
    if not ((OC.pending and since >= 0.1) or acc >= 0.5) then return end
    if clockAcc >= OC.CLOCK_EVERY then OC.clockDirty = true end
    acc, since = 0, 0
    OC.pending = nil
    if OC.Active() then OC.Update() end
    if OC.clockDirty then clockAcc = 0 end
    OC.clockDirty = nil
end

--------------------------------------------------
-- Laufzeit eigener DoTs (6.92.0.0, Wunsch: "Die Laufzeit von DoTs, wie
-- zB Schlangengift, sollte im Abklingzeitmanager einzusehen sein")
--------------------------------------------------
-- Die Plakette zeigt die Auren ueber den Aurenbehaelter des Spiels - lesen
-- kann ein Addon sie im Kampf nicht. Darum wie bei den Buffzeiten: aus dem
-- eigenen Wirken (UNIT_SPELLCAST_SUCCEEDED) und der Dauer aus Classic,
-- gebunden an das Ziel beim Wirken. Herkunft `classic`; erste Nummer der
-- Rangkette, der Name kommt vom Client. Dauer, die an Kombopunkten oder am
-- Rang haengt (Blutung, Zerfetzen, Verwunden), fehlt bewusst.
OC.DOTS = {
    { id = 1978,  dur = 15 },   -- Schlangenbiss
    { id = 3043,  dur = 20 },   -- Skorpidstich
    { id = 3034,  dur = 8 },    -- Vipernbiss
    { id = 1130,  dur = 120 },  -- Mal des Jaegers
    { id = 172,   dur = 18 },   -- Verderbnis (Rang 1: 12 s)
    { id = 980,   dur = 24 },   -- Fluch der Pein
    { id = 348,   dur = 15 },   -- Feuerbrand
    { id = 18265, dur = 30 },   -- Lebensentzug
    { id = 589,   dur = 18 },   -- Schattenwort: Schmerz
    { id = 2944,  dur = 24 },   -- Verschlingende Seuche
    { id = 8921,  dur = 12 },   -- Mondfeuer (Rang 1: 9 s)
    { id = 5570,  dur = 12 },   -- Insektenschwarm
    { id = 1822,  dur = 9 },    -- Krallenhieb
    { id = 703,   dur = 18 },   -- Erdrosseln
    { id = 8050,  dur = 12 },   -- Flammenschock
    { id = 770,   dur = 40 },   -- Feenfeuer
}
OC.dots = {}       -- Name -> { start, dur, guid }
local dotDur       -- Name -> Sekunden (beim ersten Gebrauch gebaut)

function OC.DotDuration(name)
    if not dotDur then
        dotDur = {}
        for _, d in ipairs(OC.DOTS) do
            local n = SpellName(d.id)
            if n then dotDur[n] = d.dur end
        end
    end
    return name and dotDur[name] or nil
end

local function TargetGUID()
    if not _G.UnitGUID then return nil end
    local ok, g = pcall(_G.UnitGUID, "target")
    g = ok and Plain(g) or nil
    return type(g) == "string" and g or nil
end

-- Je Ziel eine Uhr (6.94.0.0, Wunsch: zwei Gegner mit Schlangenbiss -
-- beim Zielwechsel die Restzeit DIESES Ziels). OC.dots[Name][GUID].
local NOGUID = "?"
OC.TargetGUID = function() return TargetGUID() or NOGUID end
function OC.OnCast(unit, spellID)
    if Plain(unit) ~= "player" then return end
    local id = Plain(spellID)
    if type(id) ~= "number" then return end
    local n = SpellName(id)
    if n then OC.lastCast[n] = _G.GetTime and Plain(_G.GetTime()) or 0 end
    local dur = OC.DotDuration(n)
    if not dur then return end
    local now = _G.GetTime and Plain(_G.GetTime()) or 0
    local per = OC.dots[n]
    if not per then per = {} OC.dots[n] = per end
    local g = TargetGUID() or NOGUID
    local d = per[g]
    if d then d.start, d.dur = now, dur else per[g] = { start = now, dur = dur } end
    -- Abgelaufene anderer Ziele wegraeumen (selten, keine Last pro Bild)
    for k, o in _G.next, per do
        if now - o.start >= o.dur then per[k] = nil end
    end
end

-- Laeuft der DoT dieses Zaubers auf dem aktuellen Ziel? -> start, dur
function OC.DotOn(name)
    local per = name and OC.dots[name]
    if not per then return nil end
    local g = TargetGUID() or NOGUID
    local d = per[g]
    if not d then return nil end
    local now = _G.GetTime and Plain(_G.GetTime()) or 0
    if now - d.start >= d.dur then per[g] = nil return nil end
    return d.start, d.dur
end

local function OnEvent(_, event, a1, a2, a3)
    if event == "UNIT_SPELLCAST_SUCCEEDED" then OC.OnCast(a1, a3) end
    if event == "PLAYER_REGEN_DISABLED" then
        fighting = true
    elseif event == "PLAYER_REGEN_ENABLED" then
        fighting = false
        if OC.dirty then OC.dirty = nil OC.Scan() end
    elseif event == "SPELLS_CHANGED" or event == "LEARNED_SPELL_IN_TAB" or event == "PLAYER_ENTERING_WORLD" then
        if K.InCombat() then OC.dirty = true else OC.Scan() end
    end
    -- 1.0.5.43: SPELL_UPDATE_COOLDOWN kommt im Kampf viele Male je
    -- Sekunde - nicht jedes Mal alles neu zeichnen, sondern beim naechsten
    -- Bild hoechstens alle 0,1 s.
    OC.clockDirty = true
    OC.pending = true
end

local function NewRow(key, label, name)
    local row = CreateFrame("Frame", name, UIParent)
    row:SetSize(28, 28)
    row.icons = {}
    row.WCShowForUnlock = function(self, on) self._unlock = on and true or nil OC.Update() end
    K.RegisterMover(row, key, label, K.Layout(key))
    return row
end

function OC.Enable()
    if rows.big then return end
    rows.big = NewRow("ocd_big", "Abklingzeiten: Wichtig", "WeintCodexOwnCooldownsBig")
    rows.small = NewRow("ocd_small", "Abklingzeiten: Weitere", "WeintCodexOwnCooldownsSmall")
    rows.buffs = NewRow("ocd_buffs", "Abklingzeiten: Buffs", "WeintCodexOwnCooldownsBuffs")
    rows.debuffs = NewRow("ocd_debuffs", "Abklingzeiten: Eigene Debuffs", "WeintCodexOwnCooldownsDebuffs")
    -- 1.0.7.1: Nummern der eigenen Debuffs ausserhalb des Kampfes lernen.
    local learn = CreateFrame("Frame")
    pcall(learn.RegisterEvent, learn, "PLAYER_TARGET_CHANGED")
    pcall(learn.RegisterUnitEvent or learn.RegisterEvent, learn, "UNIT_AURA", "target")
    learn:SetScript("OnEvent", K.Measured("Eigene Debuffs lernen", function(_, event, unit)
        if event == "UNIT_AURA" and unit ~= "target" then return end
        if OC.Get("debuffs") and not K.InCombat() then OC.LearnDebuffs(rows.debuffs) end
    end))
    local ev = CreateFrame("Frame")
    for _, e in ipairs({ "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "SPELLS_CHANGED",
        "LEARNED_SPELL_IN_TAB", "PLAYER_ENTERING_WORLD", "SPELL_UPDATE_COOLDOWN", "UNIT_SPELLCAST_SUCCEEDED" }) do
        pcall(ev.RegisterEvent, ev, e)
    end
    ev:SetScript("OnEvent", K.Measured("Eigener Abklingzeitmanager", OnEvent))
    ev:SetScript("OnUpdate", K.Measured("Eigener Abklingzeitmanager", Tick))
    OC.Scan()
    -- 6.106.0.0: noch nie gewaehlt -> die Vorgabe einmal richtig setzen
    -- (auch die Anzeige des Spiels aus, sonst stuenden beide da). Danach
    -- gilt die gespeicherte Wahl, auch "Blizzard".
    local m = Mem()
    if m and m.mode == nil then
        K.AfterCombat(function() if m.mode == nil then OC.SetMode(OC.DEFAULT_MODE) end end)
    end
    -- Steht nach dem Laden die Anzeige des Spiels wieder an, obwohl
    -- WeintCodex gewaehlt ist (z. B. in den Optionen des Spiels
    -- eingeschaltet), bleibt das so: das hat der Spieler entschieden.
    OC.Update()
end

-- Fuer /wcui pruefen.
function OC.StatusLines()
    local out = {}
    local on = GameOn()
    out[#out + 1] = string.format("Gewählt: %s · Anzeige des Spiels: %s", OC.Mode(),
        on == nil and "unbekannt" or (on and "an" or "aus"))
    local c = { big = 0, small = 0, off = 0 }
    for _, e in ipairs(OC.known) do local s = OC.Slot(e) c[s] = c[s] + 1 end
    out[#out + 1] = string.format("Gelernte Zauber mit Abklingzeit: %d (Wichtig %d, Weitere %d, aus %d)",
        #OC.known, c.big, c.small, c.off)
    return out
end

--------------------------------------------------
-- Einstellungen (Seite "Abklingzeitmanager" der Erinnerungen)
--------------------------------------------------

function OC.ModeRow(B)
    B:Row({ type = "dropdown", label = "Welcher Abklingzeitmanager?", items = OC.MODES,
            get = function() return OC.Mode() end, set = function(v) OC.SetMode(v) OC.Relayout() end,
            tooltip = "Blizzard: der Manager des Spiels. WeintCodex: eigene Reihen, die Anzeige des Spiels wird dafür ausgeschaltet und beim Zurückwechseln wieder so gestellt wie vorher. Je Charakter." },
          { type = "empty" })
end

-- Menue einer Reihe (Kopf ihrer Bahn auf der Buehne, ui/cdstage.lua).
function OC.RowMenu(owner, id)
    local d = OC.ExtraDef(id)
    if id == "off" then return end
    local MU = _G.MenuUtil
    if not (MU and MU.CreateContextMenu) then if d then OC.AskRename(id) end return end
    local title = OC.ROW_LABEL[id] or OC.SlotText(id)
    MU.CreateContextMenu(owner, function(_, root)
        if root.CreateTitle then root:CreateTitle(title) end
        if d then root:CreateButton("Umbenennen …", function() OC.AskRename(id) end) end
        local sub = root:CreateButton("Symbolgröße")
        for _, px in ipairs({ 18, 20, 24, 28, 32, 36, 40, 44, 48, 56, 64 }) do
            sub:CreateRadio(px .. " px", function() return (tonumber(OC.RowOpt(id, "size")) or 32) == px end,
                function() OC.SetRowOpt(id, "size", px) end)
        end
        local ori = root:CreateButton("Anordnung")
        ori:CreateRadio("Waagerecht", function() return not OC.RowOpt(id, "vertical") end,
            function() OC.SetRowOpt(id, "vertical", false) end)
        ori:CreateRadio("Senkrecht", function() return OC.RowOpt(id, "vertical") and true or false end,
            function() OC.SetRowOpt(id, "vertical", true) end)
        local per = root:CreateButton("Symbole je Zeile")
        for _, n in ipairs({ 0, 2, 3, 4, 5, 6, 8, 10, 12 }) do
            per:CreateRadio(n == 0 and "alle in einer Zeile" or tostring(n),
                function() return (tonumber(OC.RowOpt(id, "perLine")) or 0) == n end,
                function() OC.SetRowOpt(id, "perLine", n) end)
        end
        local gap = root:CreateButton("Abstand")
        for _, g in ipairs({ 0, 2, 4, 6, 8, 12 }) do
            gap:CreateRadio(g .. " px", function() return (tonumber(OC.RowOpt(id, "gap")) or 4) == g end,
                function() OC.SetRowOpt(id, "gap", g) end)
        end
        if id ~= "buffs" and id ~= "debuffs" then
            -- 1.0.9.0: Groesse der Balken dieser Reihe.
            local bw = root:CreateButton("Balkenbreite")
            for _, w in ipairs(OC.BAR_WIDTHS) do
                bw:CreateRadio(w .. " px", function() return select(1, OC.BarSize(id, OC.RowOpt(id, "size"))) == w end,
                    function() OC.SetRowOpt(id, "barWidth", w) end)
            end
            local bh = root:CreateButton("Balkenhöhe")
            bh:CreateRadio("passend zur Symbolgröße", function() return OC.RowOpt(id, "barHeight") == nil end,
                function() OC.SetRowOpt(id, "barHeight", nil) end)
            for _, h in ipairs(OC.BAR_HEIGHTS) do
                bh:CreateRadio(h .. " px", function() return OC.RowOpt(id, "barHeight") == h end,
                    function() OC.SetRowOpt(id, "barHeight", h) end)
            end
        end
        root:CreateCheckbox("Nur im Kampf zeigen", function() return OC.RowOpt(id, "combatOnly") and true or false end,
            function() OC.SetRowOpt(id, "combatOnly", not OC.RowOpt(id, "combatOnly")) end)
        if d then root:CreateButton("Reihe löschen", function() OC.RemoveRow(id) OC.Relayout() end) end
        if id == "debuffs" then
            root:CreateCheckbox("Fehlende hervorheben", function() return OC.Get("dbfHighlight") and true or false end,
                function() OC.Set("dbfHighlight", not OC.Get("dbfHighlight")) OC.Refresh() end)
            local list = OC.DEBUFFS[PlayerClass() or ""] or {}
            if #list > 0 then
                local sub = root:CreateButton("Welche Debuffs")
                for _, dd in ipairs(list) do
                    local k = dd[1]
                    sub:CreateCheckbox(dd[3], function() return OC.DebuffOn(k) end,
                        function() OC.SetDebuffOn(k, not OC.DebuffOn(k)) end)
                end
            end
        end
    end)
end

function OC.AskRename(id)
    local d = OC.ExtraDef(id)
    if not d or type(_G.StaticPopupDialogs) ~= "table" or not _G.StaticPopup_Show then return end
    _G.StaticPopupDialogs.WEINTCODEX_OCD_RENAME = _G.StaticPopupDialogs.WEINTCODEX_OCD_RENAME or {
        text = "Neuer Name der Reihe:", button1 = "Übernehmen", button2 = "Abbrechen",
        hasEditBox = true, timeout = 0, whileDead = true, hideOnEscape = true,
        OnShow = function(self, data)
            local eb = self.editBox or self.EditBox
            if eb then eb:SetText(data and data.name or "") eb:HighlightText() end
        end,
        OnAccept = function(self, data)
            local eb = self.editBox or self.EditBox
            if eb and data then OC.RenameRow(data.id, eb:GetText()) OC.Relayout() end
        end,
        EditBoxOnEnterPressed = function(self)
            local p = self:GetParent()
            if p and p.button1 then p.button1:Click() end
        end,
    }
    _G.StaticPopup_Show("WEINTCODEX_OCD_RENAME", nil, nil, { id = id, name = d.name })
end

-- Gezogener Zauber haengt an der Maus (6.97.0.0, Wunsch: "visuelle
-- Bestaetigung"); die Zeile oder Spalte darunter wird hell.
local ghost
function OC.GhostStart(e, list)
    if not ghost then
        ghost = CreateFrame("Frame", "WeintCodexOwnCooldownsGhost", UIParent)
        ghost:SetSize(200, 26)
        ghost:SetFrameStrata("TOOLTIP")
        ghost:EnableMouse(false)
        K.Kachel(ghost, { shadow = 4, alpha = 0.95 })
        ghost.icon = ghost:CreateTexture(nil, "ARTWORK")
        ghost.icon:SetSize(22, 22)
        ghost.icon:SetPoint("LEFT", ghost, "LEFT", 3, 0)
        ghost.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        ghost.text = K.NewText(ghost, 12, "OVERLAY")
        ghost.text:SetPoint("LEFT", ghost.icon, "RIGHT", 6, 0)
        ghost.text:SetPoint("RIGHT", ghost, "RIGHT", -6, 0)
        ghost.text:SetJustifyH("LEFT")
        ghost:SetScript("OnUpdate", function(self)
            local x, y = _G.GetCursorPosition()
            local sc = UIParent:GetEffectiveScale()
            self:ClearAllPoints()
            self:SetPoint("LEFT", UIParent, "BOTTOMLEFT", x / sc + 14, y / sc)
            -- Ziel hervorheben
            local L = self.list
            if not L then return end
            local hit
            for _, o in ipairs(L.lines) do
                if o:IsShown() and o.entry and o.entry.key ~= self.key then
                    local os = o:GetEffectiveScale() or 1
                    local cx, cy = x / os, y / os
                    local l, r, t, b = o:GetLeft(), o:GetRight(), o:GetTop(), o:GetBottom()
                    if l and cx >= l and cx <= r and cy >= b and cy <= t then hit = o break end
                end
            end
            if hit ~= self.hit then
                if self.hit then self.hit.hl:SetColorTexture(1, 1, 1, 0) end
                if hit then local c = C.accent hit.hl:SetColorTexture(c[1], c[2], c[3], 0.35) end
                self.hit = hit
            end
        end)
    end
    ghost.icon:SetTexture(e.tex)
    ghost.text:SetText(e.rank and (e.name .. " (" .. e.rank .. ")") or e.name)
    ghost.key, ghost.list, ghost.hit = e.key, list, nil
    ghost:Show()
end

function OC.GhostStop()
    if not ghost then return end
    local hit = _G.rawget(ghost, "hit")
    if hit and hit.hl then hit.hl:SetColorTexture(1, 1, 1, 0) end
    ghost.hit, ghost.list = nil, nil
    ghost:Hide()
end

-- Zauber "key" in Spalte "slot" setzen, vor "beforeKey" (nil = ans Ende).
function OC.Place(key, slot, beforeKey)
    local m = Mem()
    if not m then return false end
    local e
    for _, o in ipairs(OC.known) do if o.key == key then e = o break end end
    if not e then return false end
    if OC.Slot(e) ~= slot then
        m.spells[e.key] = (slot ~= e.preset) and slot or nil
    end
    local keys = {}
    for _, o in ipairs(OC.known) do if o.key ~= key then keys[#keys + 1] = o.key end end
    local at = #keys + 1
    if beforeKey then
        for i, k in ipairs(keys) do if k == beforeKey then at = i break end end
    else
        -- ans Ende der Spalte: hinter den letzten dieser Spalte
        for i, k in ipairs(keys) do
            for _, o in ipairs(OC.known) do
                if o.key == k and OC.Slot(o) == slot then at = i + 1 end
            end
        end
    end
    table.insert(keys, at, key)
    m.order = keys
    OC.SortByOrder(OC.known)
    OC.Refresh()
    return true
end

-- Seite neu bauen, wenn die Liste waechst oder schrumpft (Hoehe steht beim Bau fest).
function OC.Relayout()
    -- 1.0.9.0: die Buehne passt sich an, solange ihre Hoehe bleibt.
    local ST = WeintCodex.UICooldownStage
    if ST and ST.Refit and ST.Refit() then return end
    local O = WeintCodex.UIOptions
    if O and O.Rebuild then
        local ok, done = pcall(O.Rebuild)
        if ok and done then return end
    end
    if ST and ST.current then ST.current.Sync() end
end

local function px(v) return string.format("%d px", v) end

function OC.BuildSection(B)
    if not K.InCombat() and #OC.known == 0 then OC.Scan() end
    B:Section("WeintCodex-Abklingzeitmanager",
        "Eigene Reihen statt des Managers des Spiels: Wichtig (groß), Weitere (kleiner), deine Buffs mit Restzeit und deine Debuffs auf dem Ziel. Ab Werk steht für deine Klasse schon das Wichtigste drin – sortiert in die Spalten Wichtig, Weitere und Aus. Gilt, wenn oben „WeintCodex“ gewählt ist. Verschieben im Gestaltungsmodus.")
    local off = function() return not OC.Active() end
    B:Row({ type = "slider", label = "Größe: Wichtig", min = 24, max = 64, step = 2, format = px,
            get = function() return tonumber(OC.Get("big")) end, set = function(v) OC.Set("big", v) OC.SetRowOpt("big", "size", nil) end, disabled = off },
          { type = "slider", label = "Größe: Weitere und Buffs", min = 18, max = 48, step = 2, format = px,
            get = function() return tonumber(OC.Get("small")) end,
            set = function(v)
                OC.Set("small", v) OC.Set("buff", v)
                OC.SetRowOpt("small", "size", nil) OC.SetRowOpt("buffs", "size", nil)
            end, disabled = off })
    B:Advanced()
    B:Row({ type = "dropdown", label = "Anordnung", disabled = off, items = {
                { value = "h", text = "Waagerecht" }, { value = "v", text = "Senkrecht" } },
            get = function() return OC.Get("vertical") and "v" or "h" end, set = function(v) OC.Set("vertical", v == "v") end },
          { type = "slider", label = "Symbole je Zeile", min = 0, max = 16, step = 1, disabled = off,
            format = function(v) return v == 0 and "alle" or tostring(v) end,
            get = function() return tonumber(OC.Get("perLine")) or 0 end, set = function(v) OC.Set("perLine", v) end })
    B:Row({ type = "toggle", label = "Nur im Kampf zeigen", disabled = off,
            get = function() return OC.Get("combatOnly") and true or false end, set = function(v) OC.Set("combatOnly", v and true or false) end },
          { type = "toggle", label = "Restzeit als Zahl", disabled = off,
            get = function() return OC.Get("numbers") and true or false end, set = function(v) OC.Set("numbers", v and true or false) end })
    B:Row({ type = "toggle", label = "Leuchten, wenn bereit (Vorgabe)", disabled = off,
            get = function() return OC.Get("glow") and true or false end, set = function(v) OC.Set("glow", v and true or false) end,
            description = "Nur wenn der Client die Abklingzeit offen nennt – sonst lieber kein Leuchten als ein falsches." },
          { type = "toggle", label = "Leuchten pulsiert", disabled = off,
            get = function() return OC.Get("glowPulse") and true or false end, set = function(v) OC.Set("glowPulse", v and true or false) end })
    B:Row({ type = "dropdown", label = "Farbe des Leuchtens", items = OC.GLOW_COLORS,
            get = function() return OC.Get("glowColor") end, set = function(v) OC.Set("glowColor", v) end },
          { type = "slider", label = "Stärke des Leuchtens", min = 20, max = 100, step = 10, disabled = off,
            format = function(v) return v .. " %" end,
            get = function() return tonumber(OC.Get("glowStrength")) or 100 end, set = function(v) OC.Set("glowStrength", v) end })
    B:Row({ type = "button", label = "Voreinstellung", text = "Voreinstellung wiederherstellen",
            tooltip = "Zauberwahl, Größen und Schalter wie ab Werk für deine Klasse.",
            onClick = function() OC.ResetPreset() end },
          { type = "button", label = "Eigene Reihen", text = "Reihe löschen …",
            tooltip = "Wählt eine eigene Reihe zum Löschen; ihre Zauber wandern nach „Weitere“. Geht auch über den Kopf ihrer Spalte.",
            onClick = function(btn)
                local MU = _G.MenuUtil
                local defs = OC.ExtraRows()
                if #defs == 0 then
                    print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " Es gibt keine eigenen Reihen.")
                    return
                end
                if not (MU and MU.CreateContextMenu) then OC.RemoveRow(defs[#defs].id) OC.Relayout() return end
                MU.CreateContextMenu(btn or UIParent, function(_, root)
                    if root.CreateTitle then root:CreateTitle("Reihe löschen") end
                    for _, d in ipairs(defs) do
                        local id = d.id
                        root:CreateButton(d.name, function() OC.RemoveRow(id) OC.Relayout() end)
                    end
                end)
            end })
    B:Row({ type = "button", label = "Reihe der Buffs", text = "Buffs-Reihe einstellen …",
            tooltip = "Größe, Anordnung, Symbole je Zeile, Abstand und „Nur im Kampf“ für die Reihe der Buffs. Die anderen Reihen: Klick auf den Kopf ihrer Spalte.",
            onClick = function() OC.RowMenu(UIParent, "buffs") end },
          { type = "button", label = "Reihe der eigenen Debuffs", text = "Debuffs-Reihe einstellen …",
            tooltip = "Größe, Anordnung, Symbole je Zeile, Abstand und „Nur im Kampf“ für deine Debuffs auf dem Ziel. Größe und Anordnung ändern sich erst nach dem Kampf.",
            onClick = function() OC.RowMenu(UIParent, "debuffs") end })
    B:Row({ type = "toggle", label = "Abklingzeit an der Maus",
            get = function() return OC.Get("cursorCd") and true or false end, set = function(v) OC.Set("cursorCd", v and true or false) end,
            description = "Drückst du etwas, das noch abklingt, stehen Symbol, Name und Restzeit kurz an der Maus." },
          { type = "toggle", label = "GCD-Leiste",
            get = function() return OC.Get("gcd") and true or false end,
            set = function(v) OC.Set("gcd", v and true or false) local CH = WeintCodex.UICombatHelp if CH then CH.UpdateGcd() end end,
            description = "Die globale Abklingzeit als schmale Leiste. Verschieben im Gestaltungsmodus." })
    B:Row({ type = "toggle", label = "Co-Tank-Rahmen",
            get = function() return OC.Get("coTank") and true or false end,
            set = function(v) OC.Set("coTank", v and true or false) local CH = WeintCodex.UICombatHelp if CH then CH.UpdateCoTank() end end,
            description = "Bist du Tank, zeigt ein kleiner Rahmen den anderen Tank mit Leben und Debuffs." },
          { type = "toggle", label = "Swing-Timer",
            get = function() return OC.Get("swing") and true or false end, set = function(v) OC.Set("swing", v and true or false) end,
            description = "Eine Leiste je Waffe bis zum nächsten automatischen Schlag – Dauer vom Spiel, Tempo schon drin." })
    B:Row({ type = "toggle", label = "Ausrüstungssets",
            get = function() return OC.Get("gearBar") and true or false end,
            set = function(v) OC.Set("gearBar", v and true or false) local GS = WeintCodex.UIGearSets if GS then GS.Update() end end,
            description = "Deine Sets aus dem Ausrüstungsmanager als Leiste: Klick legt an, „+“ speichert, was du trägst." },
          { type = "toggle", label = "Schmuckleiste",
            get = function() return OC.Get("trinketBar") and true or false end,
            set = function(v) OC.Set("trinketBar", v and true or false) local GS = WeintCodex.UIGearSets if GS then GS.UpdateTrinkets() end end,
            description = "Deine beiden Schmuckstücke zum Anklicken, mit Abklingzeit. Rechtsklick: anderen Schmuck anlegen." })
    B:Row({ type = "toggle", label = "Verbrauchsleiste",
            get = function() return OC.Get("consumables") and true or false end,
            set = function(v) OC.Set("consumables", v and true or false) local CB = WeintCodex.UIConsumables if CB then CB.Layout() end end,
            description = "Tränke, Elixiere, Fläschchen, Essen und Verbände aus deinen Taschen zum Anklicken, mit Anzahl und Abklingzeit." },
          { type = "toggle", label = "Druiden-Mana",
            get = function() return OC.Get("druidMana") and true or false end,
            set = function(v) OC.Set("druidMana", v and true or false) local SH = WeintCodex.UISmallHelpers if SH then SH.UpdateMana() end end,
            description = "In Bär- und Katzengestalt eine Leiste mit deinem Mana." })
    B:Row({ type = "toggle", label = "Fokus-Zauberleiste",
            get = function() return OC.Get("focusCast") and true or false end,
            set = function(v) OC.Set("focusCast", v and true or false) local SH = WeintCodex.UISmallHelpers if SH then SH.UpdateFocus() end end,
            description = "Was dein Fokus gerade wirkt, mit Restzeit." },
          { type = "toggle", label = "Tarnungserinnerung",
            get = function() return OC.Get("stealthWarn") and true or false end,
            set = function(v) OC.Set("stealthWarn", v and true or false) local SH = WeintCodex.UISmallHelpers if SH then SH.UpdateStealth() end end,
            description = "Schurke oder Druide in Katzengestalt: Hinweis, wenn du außerhalb des Kampfes nicht getarnt bist." })
    B:Row({ type = "toggle", label = "Einstimmungen verfolgen",
            get = function() return OC.Get("attuneTracker") and true or false end,
            set = function(v) OC.Set("attuneTracker", v and true or false) local AT = WeintCodex.UIAttunements if AT then AT.Update() end end,
            description = "Schlüssel und Einstimmungen (Maraudon, Schwarzfelstiefen, Scholomance …): der nächste Schritt der Questkette, Klick setzt den Questpfeil. Alles im Chat: /wcui einstimmung." },
          { type = "empty" })
    B:Row({ type = "toggle", label = "Eigene Debuffs am Ziel", disabled = off,
            get = function() return OC.Get("debuffs") and true or false end, set = function(v) OC.Set("debuffs", v and true or false) end,
            description = "Was du selbst auf dein Ziel gewirkt hast (Stiche, Flüche, Rüstung zerreißen …) mit Restzeit – auch im Kampf. Das Spiel zeigt sie, WeintCodex liest sie nicht." },
          { type = "empty" })
    B:EndAdvanced()
    local rowDraft = ""
    B:Row({ type = "input", label = "Neue Reihe (Name)",
            get = function() return rowDraft end, set = function(v) rowDraft = v or "" end, disabled = off },
          { type = "button", label = " ", text = "Reihe hinzufügen", disabled = off,
            tooltip = "Legt eine weitere Reihe an – sie erscheint als Spalte unten und als eigener Rahmen im Gestaltungsmodus. Klick auf ihren Spaltenkopf: umbenennen, Größe, löschen.",
            onClick = function()
                local ok, why = OC.AddRow(rowDraft)
                if ok then rowDraft = "" OC.Relayout()
                elseif why then print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " " .. why) end
            end })
    local draft = ""
    B:Row({ type = "input", label = "Zauber oder Gegenstand hinzufügen",
            get = function() return draft end, set = function(v) draft = v or "" end, disabled = off },
          { type = "button", label = " ", text = "Hinzufügen", disabled = off,
            tooltip = "Name oder Nummer eines Zaubers oder Gegenstands. Du kannst ihn auch direkt aus Zauberbuch oder Taschen auf die Liste ziehen.",
            onClick = function()
                local c, why = OC.ParseAdd(draft)
                if c and OC.Add(c) then
                    draft = ""
                    OC.Relayout()
                elseif why then
                    print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " " .. why)
                end
            end })
    -- 1.0.9.0: die Buehne (ui/cdstage.lua) statt der Spaltenliste.
    local ST = WeintCodex.UICooldownStage
    B:Note("So sieht es im Spiel aus – mit laufenden Uhren. Fähigkeiten greifen und an die Stelle ziehen, an der sie stehen sollen; eine Marke zeigt, wo sie landen. In den Vorrat gezogen: nicht zeigen. Klick: Darstellung, Farbe, Rang, Leuchten, Ton. Rechtsklick: Symbol → Balken → Symbol + Balken der Wirkung. Ein Balken läuft erst über die Wirkung (DoT, Buff, Falken – je Falke einer), dann über die Abklingzeit; „Symbol + Balken der Wirkung“ lässt das Symbol stehen und zeigt nur, solange etwas wirkt, die Balken daneben. Aus Zauberbuch oder Taschen direkt auf eine Reihe ziehen: hinzufügen.")
    local O = WeintCodex.UIOptions
    B:Row({ type = "custom", height = ST.Height((O and O.CONTENT_W) or 560), create = function(parent, width) return ST.Create(parent, width) end })
end

-- An das Modul "Erinnerungen" haengen.
do
    local m = K.Module(KEY)
    if m then
        local enable = m.Enable
        m.Enable = function(...)
            if enable then enable(...) end
            local ok, err = pcall(OC.Enable)
            if not ok then K.Report("eigener abklingzeitmanager", err) end
        end
    end
end

-- /wcui speicher: interne Tabellen dieser Datei (1.0.8.27).
WeintCodex.Hold("ui/owncooldowns.lua", function() return { slotList = slotList, rows = rows } end)
