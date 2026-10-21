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
OC.DEFAULTS = { big = 40, small = 28, buff = 28, combatOnly = false, numbers = true, glow = true, buffs = true, vertical = false, perLine = 0,
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
    local s = FA and FA.SOUNDS and FA.SOUNDS[k]
    if not s then return end
    if s.file then
        if _G.PlaySoundFile then pcall(_G.PlaySoundFile, (FA.SOUND_PATH or "") .. s.file, "Master") end
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
    for i = #row.icons + 1, n do row.icons[i] = Icon(row) end
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
        if slot == "buffs" then return tonumber(OC.Get("buff")) or 28 end
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
end
OC.ROW_LABEL = { buffs = "Buffs" }

local function Arrange(row, n, s, slot)
    local gap = tonumber(OC.RowOpt(slot, "gap")) or 4
    local per = tonumber(OC.RowOpt(slot, "perLine")) or 0
    if per <= 0 or per > n then per = math.max(1, n) end
    local lines = math.max(1, math.ceil(n / per))
    local vert = OC.RowOpt(slot, "vertical") and true or false
    local long, short = per * s + (per - 1) * gap, lines * s + (lines - 1) * gap
    if vert then row:SetSize(math.max(s, short), math.max(s, long)) else row:SetSize(math.max(s, long), math.max(s, short)) end
    for i = 1, n do
        local b = row.icons[i]
        b:SetSize(s, s)
        b:ClearAllPoints()
        local line, pos = math.floor((i - 1) / per), (i - 1) % per
        local inLine = math.min(per, n - line * per)
        local shift = (per - inLine) * (s + gap) / 2
        if vert then
            b:SetPoint("TOPLEFT", row, "TOPLEFT", line * (s + gap), -(shift + pos * (s + gap)))
        else
            b:SetPoint("TOPLEFT", row, "TOPLEFT", shift + pos * (s + gap), -line * (s + gap))
        end
    end
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

local function DrawSpells(row, slot, size, show)
    local n = 0
    if show or row._unlock then
        for _, e in ipairs(OC.known) do
            if OC.Slot(e) == slot then n = n + 1 end
        end
        if n == 0 and row._unlock then n = 1 end
    end
    Ensure(row, n)
    Arrange(row, n, size, slot)
    local numbers, glow = OC.Get("numbers") and true or false, OC.Get("glow") and true or false
    local i = 0
    for _, e in ipairs(OC.known) do
        if i >= n then break end
        if OC.Slot(e) == slot then
            i = i + 1
            local b = row.icons[i]
            b.icon:SetTexture(e.tex)
            if b.cd.SetHideCountdownNumbers then b.cd:SetHideCountdownNumbers(not numbers) end
            local st, rawD
            if e.item then st = OC.ItemClock(b, e.id) else st, rawD = Clock(b, e.id) end
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
            -- Ton: beim Wechsel auf "bereit" bzw. wenn der DoT auslaeuft
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
            b.state:SetText("")
            b:Show()
        end
    end
    if i < n then   -- Gestaltungsmodus ohne Zauber: ein Platzhalter
        local b = row.icons[1]
        b.icon:SetTexture(134400)
        b.cd:Clear()
        OC.ShowGlow(b, false)
        b.state:SetText(OC.SlotText(slot))
        b:Show()
        i = 1
    end
    for j = i + 1, #row.icons do row.icons[j]:Hide() end
end

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
        if b.cd.SetHideCountdownNumbers then b.cd:SetHideCountdownNumbers(not OC.Get("numbers")) end
        b.icon:SetDesaturated(e.state == "missing")
        OC.ShowGlow(b, false)
        b.state:SetText(e.state == "on" and "an" or e.state == "runs" and "läuft" or e.state == "missing" and "!" or "")
        b:Show()
    end
    for j = n + 1, #row.icons do row.icons[j]:Hide() end
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

local acc = 0
local function Tick(_, el)
    acc = acc + (el or 0)
    if acc < 0.5 then return end
    acc = 0
    if OC.Active() then OC.Update() end
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
    if OC.Active() then OC.Update() end
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

local ROW_H = 26
local HEAD_H = 26
local BAND_GAP = 10
-- Hoehe je Band (bis zu drei Spalten nebeneinander) aus der Zahl der Zauber.
local function Bands()
    local n = {}
    for _, e in ipairs(OC.known) do local sl = OC.Slot(e) n[sl] = (n[sl] or 0) + 1 end
    local slots, bands = OC.Slots(), {}
    for i, sl in ipairs(slots) do
        local b = math.floor((i - 1) / OC.COLS_PER_BAND) + 1
        bands[b] = math.max(bands[b] or 1, n[sl] or 0)
    end
    for b, most in ipairs(bands) do bands[b] = HEAD_H + most * ROW_H + 8 end
    return bands
end
local function ListHeight()
    local h = 0
    for i, bh in ipairs(Bands()) do h = h + bh + (i > 1 and BAND_GAP or 0) end
    return h
end
OC.ListHeight = ListHeight

-- Drei Spalten Wichtig | Weitere | Aus (6.92.0.0, Wunsch). Ziehen ordnet
-- innerhalb einer Spalte und zwischen ihnen; Klick oeffnet die Feinheiten
-- des Zaubers (Rang, Leuchten, Ton).
local function CreateList(parent, width)
    local f = CreateFrame("Frame", nil, parent)
    f.lines, f.cols = {}, {}
    local gap = 10
    local per = OC.COLS_PER_BAND
    local colW = math.floor((width - (per - 1) * gap) / per)
    local bands = Bands()
    local slots = {}
    for i, sl in ipairs(OC.Slots()) do slots[i] = sl end
    for ci, slot in ipairs(slots) do
        local col = CreateFrame("Button", nil, f)
        col.slot = slot
        local band, pos = math.floor((ci - 1) / per) + 1, (ci - 1) % per
        local y = 0
        for b = 1, band - 1 do y = y + bands[b] + BAND_GAP end
        col:SetPoint("TOPLEFT", f, "TOPLEFT", pos * (colW + gap), -y)
        col:SetSize(colW, bands[band])
        -- Eigene Reihe: Klick auf die Kopfzeile -> Umbenennen, Größe, Löschen
        if slot ~= "off" then
            col:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            col:SetScript("OnClick", function(self)
                local _, cy = _G.GetCursorPosition()
                local sc = self:GetEffectiveScale() or 1
                local top = self:GetTop()
                if top and cy / sc < top - HEAD_H then return end
                OC.RowMenu(self, slot)
            end)
        end
        local bg = col:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(col)
        bg:SetColorTexture(unpack(C.surface1))
        col.head = K.NewText(col, 12)
        col.head:SetPoint("TOPLEFT", col, "TOPLEFT", 8, -6)
        col.head:SetTextColor(unpack(slot == "off" and C.textMuted or C.textBright))
        col:SetFrameLevel(f:GetFrameLevel() + 1)
        col:EnableMouse(true)
        f.cols[ci] = col
    end
    -- Zauber oder Gegenstand auf die Liste ziehen: hinzufuegen.
    f.Drop = function()
        local c = OC.FromCursor()
        if c and OC.Add(c) then
            if _G.ClearCursor then _G.ClearCursor() end
            OC.Relayout()
        end
    end
    f:EnableMouse(true)
    f:SetScript("OnReceiveDrag", f.Drop)
    f:SetScript("OnMouseUp", function() if OC.FromCursor() then f.Drop() end end)
    for _, col in ipairs(f.cols) do
        col:SetScript("OnReceiveDrag", f.Drop)
        col:SetScript("OnMouseUp", function() if OC.FromCursor() then f.Drop() end end)
    end
    OC.list = f

    -- Feinheiten je Zauber: kleines Feld neben der Zeile.
    -- Am UIParent, nicht an der Liste (6.93.1.0): die Liste liegt in der
    -- Rollflaeche der Einstellungen und die schneidet alles ab, was
    -- daneben stehen soll - das Feld war unsichtbar.
    local pop = CreateFrame("Frame", "WeintCodexOwnCooldownsPop", UIParent)
    pop:SetSize(240, 6 * 30 + 40)
    pop:SetFrameStrata("FULLSCREEN_DIALOG")
    pop:SetClampedToScreen(true)
    if type(_G.UISpecialFrames) == "table" then table.insert(_G.UISpecialFrames, "WeintCodexOwnCooldownsPop") end
    pop:EnableMouse(true)
    K.Kachel(pop, { shadow = 6, alpha = 1 })
    pop.title = K.NewText(pop, 13, "OVERLAY")
    pop.title:SetPoint("TOPLEFT", pop, "TOPLEFT", 10, -8)
    pop.title:SetPoint("RIGHT", pop, "RIGHT", -10, 0)
    pop.title:SetJustifyH("LEFT")
    if pop.title.SetWordWrap then pop.title:SetWordWrap(false) end
    local function PopBtn(i, onClick)
        local b = WeintCodex.CreateButton(pop, { text = "", kind = "secondary", height = 26, size = 11, onClick = onClick })
        b:SetPoint("TOPLEFT", pop, "TOPLEFT", 10, -32 - (i - 1) * 30)
        b:SetPoint("RIGHT", pop, "RIGHT", -10, 0)
        return b
    end
    pop:Hide()
    f.pop = pop
    local function PopSync()
        local e = pop.entry
        if not e then pop:Hide() return end
        pop.title:SetText(e.name)
        pop.rank:SetText(e.ranks and #e.ranks > 1 and ("Rang: " .. (e.rank or "?") .. "  ›") or (e.rank or "Nur ein Rang"))
        pop.glow:SetText("Leuchten: " .. OC.GLOW_TEXT[OC.GlowMode(e)] .. "  ›")
        pop.sound:SetText("Ton: " .. OC.SoundText(OC.SoundOf(e)) .. "  ›")
        pop.when:SetText("Ton wann: " .. OC.WHEN_TEXT[OC.SoundWhen(e)] .. (OC.DotDuration(e.name) and "  ›" or ""))
        pop.slot:SetText("Spalte: " .. OC.SlotText(OC.Slot(e)) .. "  ›")
        pop.remove:SetText(e.custom and "Entfernen" or "Schließen")
    end
    pop.rank = PopBtn(1, function() if pop.entry then OC.NextRank(pop.entry) PopSync() f.Sync() end end)
    pop.glow = PopBtn(2, function() if pop.entry then OC.NextGlow(pop.entry) PopSync() f.Sync() end end)
    pop.sound = PopBtn(3, function()
        if pop.entry then OC.SoundMenu(pop.sound, pop.entry, function() PopSync() f.Sync() end) end
    end)
    pop.when = PopBtn(4, function()
        if pop.entry and OC.DotDuration(pop.entry.name) then OC.NextSoundWhen(pop.entry) PopSync() end
    end)
    pop.slot = PopBtn(5, function()
        local e = pop.entry
        if not e then return end
        local cur = OC.Slot(e)
        local nxt = OC.NextSlot(cur)
        OC.Place(e.key, nxt, nil)
        OC.Relayout()
    end)
    pop.remove = PopBtn(6, function()
        local e = pop.entry
        pop.entry = nil
        pop:Hide()
        if e and e.custom then OC.Remove(e) OC.Relayout() end
    end)
    f:SetScript("OnHide", function() pop:Hide() end)

    -- Treffer ueber die Mausposition (6.92.1.0): IsMouseOver meldete beim
    -- Loslassen nach dem Ziehen nichts - Spalten wechselten nicht.
    local function Hit(fr)
        if not (fr and fr:IsShown() and _G.GetCursorPosition) then return false end
        local x, y = _G.GetCursorPosition()
        local sc = fr:GetEffectiveScale() or 1
        x, y = x / sc, y / sc
        local l, r, t, b = fr:GetLeft(), fr:GetRight(), fr:GetTop(), fr:GetBottom()
        if not (l and r and t and b) then return false end
        return x >= l and x <= r and y >= b and y <= t
    end
    local function ColUnderMouse()
        for _, col in ipairs(f.cols) do if Hit(col) then return col end end
        return nil
    end

    local function Line(i)
        local l = CreateFrame("Button", nil, f)
        l:SetSize(colW - 8, ROW_H - 4)
        -- Ueber den Spalten (6.93.2.0): die Spalten nehmen die Maus fuer das
        -- Hineinziehen aus dem Zauberbuch und lagen auf gleicher Ebene ueber
        -- den Zeilen - kein Klick, kein Ziehen kam an.
        l:SetFrameLevel(f:GetFrameLevel() + 10)
        l.hl = l:CreateTexture(nil, "BACKGROUND")
        l.hl:SetAllPoints(l)
        l.hl:SetColorTexture(1, 1, 1, 0)
        l.icon = l:CreateTexture(nil, "ARTWORK")
        l.icon:SetSize(ROW_H - 6, ROW_H - 6)
        l.icon:SetPoint("LEFT", l, "LEFT", 2, 0)
        l.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        l.name = K.NewText(l, 12)
        l.name:SetPoint("LEFT", l.icon, "RIGHT", 6, 0)
        l.name:SetPoint("RIGHT", l, "RIGHT", -62, 0)
        l.name:SetJustifyH("LEFT")
        if l.name.SetWordWrap then l.name:SetWordWrap(false) end
        l.mark = K.NewText(l, 11)
        l.mark:SetPoint("RIGHT", l, "RIGHT", -4, 0)
        l.mark:SetTextColor(unpack(C.textMuted))
        l:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        l:SetScript("OnEnter", function(self)
            local c = C.accent
            self.hl:SetColorTexture(c[1], c[2], c[3], 0.15)
            local tt = _G.GameTooltip
            if not (tt and self.entry and self.entry.id) then return end
            tt:SetOwner(self, "ANCHOR_RIGHT")
            if self.entry.item then pcall(tt.SetItemByID, tt, self.entry.id)
            else pcall(tt.SetSpellByID, tt, self.entry.id) end
            tt:AddLine("Klick: Rang, Leuchten, Ton · Ziehen: ordnen oder in eine andere Spalte" .. (self.entry.custom and " · Rechtsklick: entfernen" or ""), 0.6, 0.6, 0.6, true)
            tt:Show()
        end)
        l:SetScript("OnLeave", function(self)
            self.hl:SetColorTexture(1, 1, 1, 0)
            if _G.GameTooltip then _G.GameTooltip:Hide() end
        end)
        l:RegisterForDrag("LeftButton")
        l:SetScript("OnDragStart", function(self)
            f.dragKey = self.entry and self.entry.key
            self:SetAlpha(0.4)
            pop:Hide()
            if self.entry then OC.GhostStart(self.entry, f) end
        end)
        l:SetScript("OnDragStop", function(self)
            self:SetAlpha(1)
            OC.GhostStop()
            local from = f.dragKey
            f.dragKey = nil
            if not from then return end
            local target
            for _, o in ipairs(f.lines) do
                if o:IsShown() and o ~= self and o.entry and Hit(o) then target = o break end
            end
            if target then
                OC.Place(from, OC.Slot(target.entry), target.entry.key)
            else
                local col = ColUnderMouse()
                if col then OC.Place(from, col.slot, nil) end
            end
            OC.Relayout()
        end)
        l:SetScript("OnClick", function(self, button)
            if not self.entry then return end
            if button == "RightButton" then
                if self.entry.custom then OC.Remove(self.entry) OC.Relayout() end
                return
            end
            if pop.entry == self.entry and pop:IsShown() then pop:Hide() pop.entry = nil return end
            pop.entry = self.entry
            pop:ClearAllPoints()
            pop:SetScale(self:GetEffectiveScale() / (UIParent:GetEffectiveScale() or 1))
            pop:SetPoint("TOPLEFT", self, "TOPRIGHT", 6, 0)
            PopSync()
            pop:Show()
        end)
        l:SetScript("OnReceiveDrag", f.Drop)
        f.lines[i] = l
        return l
    end

    f.Sync = function()
        local count = {}
        for _, col in ipairs(f.cols) do count[col.slot] = 0 end
        local colOf = {}
        for ci, col in ipairs(f.cols) do colOf[col.slot] = col end
        local i = 0
        for _, e in ipairs(OC.known) do
            local sl = OC.Slot(e)
            local col = colOf[sl]
            if col then
                i = i + 1
                local l = f.lines[i] or Line(i)
                l.entry = e
                l:ClearAllPoints()
                l:SetPoint("TOPLEFT", col, "TOPLEFT", 4, -HEAD_H - count[sl] * ROW_H)
                l:SetFrameLevel(col:GetFrameLevel() + 10)
                count[sl] = (count[sl] or 0) + 1
                l.icon:SetTexture(e.tex)
                if l.icon.SetDesaturated then l.icon:SetDesaturated(sl == "off") end
                local label = e.rank and (e.name .. " (" .. e.rank .. ")") or e.name
                l.name:SetText(label)
                l.name:SetTextColor(unpack(sl == "off" and C.textMuted or C.textBright))
                l.mark:SetText(OC.SoundOf(e) ~= "none" and "Ton" or "")
                l:Show()
            end
        end
        for j = i + 1, #f.lines do f.lines[j]:Hide() end
        for _, col in ipairs(f.cols) do
            col.head:SetText(OC.SlotText(col.slot) .. "  ·  " .. (count[col.slot] or 0) .. (col.slot ~= "off" and "   · Menü ›" or ""))
        end
        if pop:IsShown() then PopSync() end
    end
    return f
end

-- Menue einer eigenen Reihe (Kopf der Spalte).
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
        root:CreateCheckbox("Nur im Kampf zeigen", function() return OC.RowOpt(id, "combatOnly") and true or false end,
            function() OC.SetRowOpt(id, "combatOnly", not OC.RowOpt(id, "combatOnly")) end)
        if d then root:CreateButton("Reihe löschen", function() OC.RemoveRow(id) OC.Relayout() end) end
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
    if ghost.hit then ghost.hit.hl:SetColorTexture(1, 1, 1, 0) end
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
    local O = WeintCodex.UIOptions
    if O and O.Rebuild then
        local ok, done = pcall(O.Rebuild)
        if ok and done then return end
    end
    if OC.list then OC.list.Sync() end
end

local function px(v) return string.format("%d px", v) end

function OC.BuildSection(B)
    if not K.InCombat() and #OC.known == 0 then OC.Scan() end
    B:Section("WeintCodex-Abklingzeitmanager",
        "Eigene Reihen statt des Managers des Spiels: Wichtig (groß), Weitere (kleiner) und deine Buffs mit Restzeit. Ab Werk steht für deine Klasse schon das Wichtigste drin – sortiert in die Spalten Wichtig, Weitere und Aus. Gilt, wenn oben „WeintCodex“ gewählt ist. Verschieben im Gestaltungsmodus.")
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
    B:Note("So geht's: Jede Spalte ist eine Reihe auf dem Bildschirm – „Wichtig“ große Symbole, „Weitere“ kleine, eigene Reihen in ihrer Größe, „Aus“ wird nicht gezeigt. Eigene Reihen legst du oben an. Klick auf den Kopf einer Spalte („Menü ›“): Größe, Anordnung, Symbole je Zeile, Abstand, nur im Kampf – bei eigenen Reihen auch umbenennen und löschen. Zauber mit der Maus greifen und auf einen anderen Zauber ziehen: er landet davor, auch in einer anderen Spalte; auf freie Fläche einer Spalte: ans Ende. Die Reihenfolge in der Spalte ist die auf dem Bildschirm. Klick auf einen Zauber: Rang, Leuchten, Ton und Spalte einstellen.")
    B:Row({ type = "custom", height = ListHeight(), create = CreateList })
    B:Note("Alle Zauber deines Zauberbuchs, dazu was du selbst hinzufügst. Ziehen ordnet innerhalb einer Spalte oder schiebt in eine andere; ein Klick öffnet Rang, Leuchten und Ton des Zaubers. „Ton“ rechts heißt: dieser Zauber spielt einen Ton, wenn er bereit ist. Buffs kommen aus den Buffzeiten.")
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
