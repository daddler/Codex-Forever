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
OC.DEFAULT_MODE = "blizzard"
OC.SLOTS = { "big", "small", "off" }
OC.SLOT_TEXT = { big = "Wichtig", small = "Weitere", off = "Aus" }
OC.DEFAULTS = { big = 40, small = 28, buff = 28, combatOnly = false, numbers = true, glow = true, buffs = true, vertical = false, perLine = 0 }
OC.MAX_LIST = 30
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
    for _, e in ipairs(OC.Catalog(class)) do
        local id = OC.Resolve(e.chain)
        if id and #list < OC.MAX_LIST then
            e.id, e.name, e.tex, e.rank = id, SpellName(id) or tostring(id), Texture(id), SpellRank(id)
            -- Derselbe Zauber in zwei Ketten: nur einmal, der hoechste Rang.
            local dup
            for _, o in ipairs(list) do if o.name == e.name then dup = true break end end
            if not dup then list[#list + 1] = e end
        end
    end
    return list
end

function OC.Slot(e)
    local m = Mem()
    local v = m and m.spells[e.key]
    if v == "big" or v == "small" or v == "off" then return v end
    return e.preset
end

function OC.SetSlot(e, slot)
    local m = Mem()
    if not m then return end
    m.spells[e.key] = (slot ~= e.preset) and slot or nil
    OC.Refresh()
end

function OC.Cycle(e)
    local cur = OC.Slot(e)
    local nxt = cur == "big" and "small" or cur == "small" and "off" or "big"
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
local function Arrange(row, n, s)
    local gap = 4
    local per = tonumber(OC.Get("perLine")) or 0
    if per <= 0 or per > n then per = math.max(1, n) end
    local lines = math.max(1, math.ceil(n / per))
    local vert = OC.Get("vertical") and true or false
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
            return type(d) == "number" and "cd" or nil
        end
    end
    if type(start) == "nil" or type(duration) == "nil" then b.cd:Clear() return nil end
    pcall(b.cd.SetCooldown, b.cd, start, duration)
    return type(d) == "number" and "cd" or nil
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
    Arrange(row, n, size)
    local numbers, glow = OC.Get("numbers") and true or false, OC.Get("glow") and true or false
    local i = 0
    for _, e in ipairs(OC.known) do
        if i >= n then break end
        if OC.Slot(e) == slot then
            i = i + 1
            local b = row.icons[i]
            b.icon:SetTexture(e.tex)
            if b.cd.SetHideCountdownNumbers then b.cd:SetHideCountdownNumbers(not numbers) end
            local st = Clock(b, e.id)
            b.glow:SetShown(glow and st == "ready")
            b.state:SetText("")
            b:Show()
        end
    end
    if i < n then   -- Gestaltungsmodus ohne Zauber: ein Platzhalter
        local b = row.icons[1]
        b.icon:SetTexture(134400)
        b.cd:Clear()
        b.glow:SetShown(false)
        b.state:SetText(OC.SLOT_TEXT[slot])
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
    Arrange(row, n, size)
    for i = 1, n do
        local e, b = list[i], row.icons[i]
        b.icon:SetTexture(Texture(e.spell))
        local a = BT.active[e.group.key]
        if e.state == "time" and a then b.cd:SetCooldown(a.start, a.duration) else b.cd:Clear() end
        if b.cd.SetHideCountdownNumbers then b.cd:SetHideCountdownNumbers(not OC.Get("numbers")) end
        b.icon:SetDesaturated(e.state == "missing")
        b.glow:SetShown(false)
        b.state:SetText(e.state == "on" and "an" or e.state == "runs" and "läuft" or e.state == "missing" and "!" or "")
        b:Show()
    end
    for j = n + 1, #row.icons do row.icons[j]:Hide() end
end

function OC.Update()
    if not rows.big then return end
    local show = Visible()
    DrawSpells(rows.big, "big", tonumber(OC.Get("big")) or 40, show)
    DrawSpells(rows.small, "small", tonumber(OC.Get("small")) or 28, show)
    DrawBuffs(rows.buffs, tonumber(OC.Get("buff")) or 28, show)
end

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

local function OnEvent(_, event)
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
            get = function() return OC.Mode() end, set = function(v) OC.SetMode(v) end,
            tooltip = "Blizzard: der Manager des Spiels. WeintCodex: eigene Reihen, die Anzeige des Spiels wird dafür ausgeschaltet und beim Zurückwechseln wieder so gestellt wie vorher. Je Charakter." },
          { type = "empty" })
end

local ROW_H = 26
local function ListHeight()
    local n = #OC.known
    if n == 0 then return 40 end
    return math.ceil(n / 2) * ROW_H + 4
end

local function CreateList(parent, width)
    local f = CreateFrame("Frame", nil, parent)
    f.lines = {}
    f.empty = K.NewText(f, 12)
    f.empty:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -4)
    f.empty:SetTextColor(unpack(C.textMuted))
    f.empty:SetText("Noch keine gelernten Zauber mit Abklingzeit erkannt.")
    local colW = math.floor((width - 12) / 2)
    f.Sync = function()
        local list = OC.known
        f.empty:SetShown(#list == 0)
        for i, e in ipairs(list) do
            local l = f.lines[i]
            if not l then
                l = CreateFrame("Frame", nil, f)
                l:SetSize(colW, ROW_H - 4)
                l.icon = l:CreateTexture(nil, "ARTWORK")
                l.icon:SetSize(ROW_H - 4, ROW_H - 4)
                l.icon:SetPoint("LEFT", l, "LEFT", 0, 0)
                l.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                l.name = K.NewText(l, 12)
                l.name:SetPoint("LEFT", l.icon, "RIGHT", 6, 0)
                -- Tooltip des Zaubers mit Rang (6.90.1.0)
                l:EnableMouse(true)
                l:SetScript("OnEnter", function(self)
                    local tt = _G.GameTooltip
                    if not (tt and self.entry and self.entry.id) then return end
                    tt:SetOwner(self, "ANCHOR_RIGHT")
                    pcall(tt.SetSpellByID, tt, self.entry.id)
                    tt:Show()
                end)
                l:SetScript("OnLeave", function() if _G.GameTooltip then _G.GameTooltip:Hide() end end)
                l.name:SetWidth(colW - (ROW_H - 4) - 96)
                l.name:SetJustifyH("LEFT")
                if l.name.SetWordWrap then l.name:SetWordWrap(false) end
                l.btn = WeintCodex.CreateButton(l, { text = "", kind = "secondary", height = ROW_H - 4, size = 11,
                    tooltip = "Klick: Wichtig → Weitere → Aus",
                    onClick = function() if l.entry then OC.Cycle(l.entry) f.Sync() end end })
                l.btn:SetWidth(84)
                l.btn:SetPoint("RIGHT", l, "RIGHT", 0, 0)
                f.lines[i] = l
            end
            l.entry = e
            l:ClearAllPoints()
            local col, r = (i - 1) % 2, math.floor((i - 1) / 2)
            l:SetPoint("TOPLEFT", f, "TOPLEFT", col * (colW + 12), -r * ROW_H)
            l.icon:SetTexture(e.tex)
            local label = e.rank and (e.name .. " (" .. e.rank .. ")") or e.name
            l.name:SetText(WeintCodex.Truncate and WeintCodex.Truncate(label, 26) or label)
            local s = OC.Slot(e)
            l.btn:SetText(OC.SLOT_TEXT[s])
            l.name:SetTextColor(unpack(s == "off" and C.textMuted or C.textBright))
            l:Show()
        end
        for j = #list + 1, #f.lines do f.lines[j]:Hide() end
    end
    return f
end

local function px(v) return string.format("%d px", v) end

function OC.BuildSection(B)
    if not K.InCombat() and #OC.known == 0 then OC.Scan() end
    B:Section("WeintCodex-Abklingzeitmanager",
        "Eigene Reihen statt des Managers des Spiels: Wichtig (groß), Weitere (kleiner) und deine Buffs mit Restzeit. Ab Werk steht für deine Klasse schon das Wichtigste drin – je Zauber ein Klick: Wichtig, Weitere oder Aus. Gilt, wenn oben „WeintCodex“ gewählt ist. Verschieben im Gestaltungsmodus.")
    local off = function() return not OC.Active() end
    B:Row({ type = "slider", label = "Größe: Wichtig", min = 24, max = 64, step = 2, format = px,
            get = function() return tonumber(OC.Get("big")) end, set = function(v) OC.Set("big", v) end, disabled = off },
          { type = "slider", label = "Größe: Weitere und Buffs", min = 18, max = 48, step = 2, format = px,
            get = function() return tonumber(OC.Get("small")) end,
            set = function(v) OC.Set("small", v) OC.Set("buff", v) end, disabled = off })
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
    B:Row({ type = "toggle", label = "Leuchten, wenn bereit", disabled = off,
            get = function() return OC.Get("glow") and true or false end, set = function(v) OC.Set("glow", v and true or false) end,
            description = "Nur wenn der Client die Abklingzeit offen nennt – sonst lieber kein Leuchten als ein falsches." },
          { type = "button", label = "Voreinstellung", text = "Voreinstellung wiederherstellen",
            tooltip = "Zauberwahl, Größen und Schalter wie ab Werk für deine Klasse.",
            onClick = function() OC.ResetPreset() end })
    B:Row({ type = "custom", height = ListHeight(), create = CreateList })
    B:Note("Liste: deine gelernten Zauber mit Abklingzeit (Voreinstellung aus Classic, ergänzt um Zauber des Lehrers mit Abklingzeit). Buffs kommen aus den Buffzeiten.")
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
