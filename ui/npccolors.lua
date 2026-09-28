--------------------------------------------------
-- WeintCodex :: Oberflaeche - Plaketten nach NPC
--------------------------------------------------
-- Beta-Test (6.6.2.2): "wie bei Plater: einen NPC per Namen finden und
-- ihm eine Farbe geben. Voreinstellungen: Caster in einer anderen Farbe
-- als normal angreifende Gegner, damit man sieht, was unterbrochen werden
-- muss."
--
-- ZWEI TEILE.
--   * VOREINSTELLUNG "Zaubernde": eine eigene Farbe fuer Gegner, die
--     zaubern. Woran das zu erkennen ist, sagt der Client - keine eigene
--     Liste: die Klasse des NPC (Magier und Paladin sind die NPC-Klassen
--     mit Mana), seine Energieart (Mana), und ob WeintCodex ihn schon
--     einen Zauber mit Zauberzeit beginnen sah. Letzteres merkt es sich je
--     NPC - wer einmal zaubert, ist beim naechsten Mal von Anfang an blau.
--   * EIGENE REGELN: Name eingeben, WeintCodex findet den NPC unter denen,
--     deren Plakette es schon gesehen hat (Kennung, Name, Gebiet), und
--     man gibt ihm eine Farbe. Einen NPC, der noch nie zu sehen war, kann
--     man ueber den Namen anlegen (gilt dann fuer jeden mit genau diesem
--     Namen) - oder ueber "Ziel uebernehmen".
--
-- KEINE EINGEBAUTE NPC-LISTE. Niemand hier hat die NPCs von Forever
-- gelesen; gesucht wird nur, was die eigenen Plaketten gesehen haben
-- (Kein Bestand ohne Herkunft).
--
-- Geheime Werte: Kennung (aus der GUID), Name, Klasse und Energieart
-- werden nur offen gelesen. Ist etwas geheim, faellt die Plakette auf die
-- uebrigen Farben zurueck - nie ein Fehler.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UINpcColors = {}

local NC = WeintCodex.UINpcColors
local K  = WeintCodex.UIKit
local C  = WeintCodex.Colors
local KEY = "nameplates"
-- Regeln und gesehene NPCs liegen getrennt vom Modul: "Standard" bei den
-- Plaketten setzt Groessen und Farben zurueck, nicht die eigenen Regeln.
local STORE = "npccolors"
NC.SEEN_MAX = 600

local lower = string.lower

--------------------------------------------------
-- Erkennen
--------------------------------------------------

-- "Creature-0-1-2-3-12345-0000ABCD" -> 12345. Nur Kreaturen, Begleiter
-- und Fahrzeuge tragen eine NPC-Kennung.
function NC.NpcID(guid)
    guid = K.Plain(guid)
    if type(guid) ~= "string" then return nil end
    local kind, id = guid:match("^(%a+)%-%d+%-%d+%-%d+%-%d+%-(%d+)%-")
    if kind == "Creature" or kind == "Vehicle" or kind == "Pet" then return tonumber(id) end
    return nil
end

-- Gesehene NPCs: [Kennung] = { n = Name, z = Gebiet, c = zaubert, t = Zeit }.
-- Wird an Ort und Stelle ergaenzt (kein Einstellungsereignis je Plakette).
local function Seen()
    local s = K.Get(STORE, "seen")
    if type(s) ~= "table" then
        K.Set(STORE, "seen", {})
        s = K.Get(STORE, "seen")
    end
    return s
end
NC.Seen = Seen

local function Now() return K.Plain(_G.GetTime and _G.GetTime()) or 0 end

local function Trim(seen)
    local n, oldest, oldT = 0, nil, nil
    for id, e in pairs(seen) do
        n = n + 1
        if not oldT or (e.t or 0) < oldT then oldest, oldT = id, e.t or 0 end
    end
    if n > NC.SEEN_MAX and oldest then seen[oldest] = nil end
end

local function Zone()
    local z = _G.GetZoneText and K.Plain(_G.GetZoneText())
    return type(z) == "string" and z ~= "" and z or nil
end

-- Zaubert dieser Gegner? Ja, wenn der Client es sagt (Klasse, Mana) oder
-- WeintCodex es gesehen hat.
local CASTER_CLASS = { MAGE = true, PALADIN = true }
function NC.IsCaster(unit, id)
    local seen = id and Seen()[id]
    if seen and seen.c then return true end
    if _G.UnitClass then
        local ok, _, class = pcall(_G.UnitClass, unit)
        class = ok and K.Plain(class) or nil
        if type(class) == "string" and CASTER_CLASS[class] then return true end
    end
    if _G.UnitPowerType and _G.UnitPowerMax then
        local ok, ptype = pcall(_G.UnitPowerType, unit)
        ptype = ok and K.Plain(ptype) or nil
        if ptype == 0 then
            local okM, max = pcall(_G.UnitPowerMax, unit, 0)
            max = okM and K.Plain(max) or nil
            if type(max) == "number" and max > 0 then return true end
        end
    end
    return false
end

-- Beim Erscheinen einer Plakette: Kennung, Name, zaubert? - an unserer
-- eigenen Plakette gemerkt (nie am Rahmen des Spiels), und der NPC in die
-- Liste der gesehenen.
function NC.Identify(p, unit)
    local id = _G.UnitGUID and NC.NpcID(_G.UnitGUID(unit)) or nil
    local name = _G.UnitName and K.Plain(_G.UnitName(unit))
    if type(name) ~= "string" or name == "" then name = nil end
    p._npcID, p._npcName = id, name
    p._caster = NC.IsCaster(unit, id)
    if id and name and not (_G.UnitIsPlayer and K.Bool(_G.UnitIsPlayer(unit), false)) then
        local seen = Seen()
        local e = seen[id]
        if not e then
            e = {}
            seen[id] = e
            Trim(seen)
        end
        e.n, e.t = name, Now()
        e.z = Zone() or e.z
        if p._caster then e.c = true end
    end
end

-- Ein Zauber mit Zauberzeit beginnt. Liefert true, wenn sich dadurch
-- etwas aendert (die Plakette faerbt dann neu).
function NC.SawCast(p)
    if p._caster then return false end
    p._caster = true
    local e = p._npcID and Seen()[p._npcID]
    if e then e.c = true end
    return true
end

--------------------------------------------------
-- Regeln
--------------------------------------------------
-- { { id = Kennung oder nil, name = "Name", r, g, b }, ... }

local byID, byName = {}, {}
NC.byID, NC.byName = byID, byName

function NC.Rules()
    local r = K.Get(STORE, "rules")
    return type(r) == "table" and r or {}
end

function NC.Rebuild()
    wipe(byID)
    wipe(byName)
    for _, rule in ipairs(NC.Rules()) do
        if type(rule.id) == "number" then byID[rule.id] = rule
        elseif type(rule.name) == "string" then byName[lower(rule.name)] = rule end
    end
end

local function Save(list)
    local copy = {}
    for i, r in ipairs(list) do
        copy[i] = { id = r.id, name = r.name, r = r.r, g = r.g, b = r.b }
    end
    table.sort(copy, function(a, b) return lower(a.name or "") < lower(b.name or "") end)
    K.Set(STORE, "rules", copy)   -- K.Listen unten: neu aufbauen, neu faerben
end

-- Farbe der eigenen Regel fuer diese Plakette, sonst nil.
function NC.RuleColor(p)
    local rule = (p._npcID and byID[p._npcID]) or (p._npcName and byName[lower(p._npcName)])
    if rule then return rule.r, rule.g, rule.b end
    return nil
end

function NC.Find(id, name)
    for i, r in ipairs(NC.Rules()) do
        if (id and r.id == id) or (not id and not r.id and name and r.name and lower(r.name) == lower(name)) then
            return r, i
        end
    end
    return nil, nil
end

-- Regel anlegen (mit der Voreinstellung fuer neue Regeln). Liefert die
-- Regel; gibt es sie schon, die bestehende.
function NC.Add(id, name)
    if type(name) ~= "string" or name:gsub("%s", "") == "" then return nil end
    name = name:gsub("^%s+", ""):gsub("%s+$", "")
    local have = NC.Find(id, name)
    if have then return have end
    local c = WeintCodex.GameColors.npcCustom
    local list = {}
    for i, r in ipairs(NC.Rules()) do list[i] = r end
    list[#list + 1] = { id = id, name = name, r = c[1], g = c[2], b = c[3] }
    Save(list)
    return (NC.Find(id, name))
end

function NC.SetColor(id, name, r, g, b)
    local list = {}
    for i, x in ipairs(NC.Rules()) do
        list[i] = x
        if (id and x.id == id) or (not id and not x.id and x.name == name) then
            list[i] = { id = x.id, name = x.name, r = r, g = g, b = b }
        end
    end
    Save(list)
end

function NC.Remove(index)
    local list = {}
    for i, r in ipairs(NC.Rules()) do
        if i ~= index then list[#list + 1] = r end
    end
    Save(list)
end

-- Suche unter den gesehenen NPCs: Anfang des Namens zuerst, dann der
-- Rest, jeweils nach dem Alphabet.
function NC.Search(text, max)
    max = max or 6
    local out = {}
    if type(text) ~= "string" then return out end
    local q = lower(text:gsub("^%s+", ""):gsub("%s+$", ""))
    if q == "" then return out end
    for id, e in pairs(Seen()) do
        local n = type(e.n) == "string" and lower(e.n) or nil
        local at = n and n:find(q, 1, true)
        if at then out[#out + 1] = { id = id, name = e.n, zone = e.z, caster = e.c and true or false, prefix = at == 1 } end
    end
    table.sort(out, function(a, b)
        if a.prefix ~= b.prefix then return a.prefix end
        return lower(a.name) < lower(b.name)
    end)
    for i = max + 1, #out do out[i] = nil end
    return out
end

-- Das aktuelle Ziel als Regel (nur NPCs).
function NC.AddTarget()
    if not (_G.UnitExists and K.Bool(_G.UnitExists("target"), false)) then return nil, "Kein Ziel." end
    if _G.UnitIsPlayer and K.Bool(_G.UnitIsPlayer("target"), false) then return nil, "Das Ziel ist ein Spieler." end
    local id = _G.UnitGUID and NC.NpcID(_G.UnitGUID("target")) or nil
    local name = _G.UnitName and K.Plain(_G.UnitName("target"))
    if type(name) ~= "string" then return nil, "Den Namen des Ziels nennt der Client gerade nicht." end
    if id then
        local seen = Seen()
        seen[id] = seen[id] or { n = name, t = Now() }
        seen[id].z = seen[id].z or Zone()
    end
    return NC.Add(id, name), nil
end

--------------------------------------------------
-- Einstellungen: Reiter "NPCs" der Namensplaketten
--------------------------------------------------

local RESULT_ROWS, RULE_ROWS = 6, 10
local ROW_H = 26
local search = { text = "", msg = nil }
NC.search = search

local function Edit(parent, width)
    local eb = CreateFrame("EditBox", nil, parent)
    eb:SetSize(width, 26)
    eb:SetAutoFocus(false)
    if eb.SetTextInsets then eb:SetTextInsets(8, 8, 0, 0) end
    K.SetFont(eb, 12)
    local bg = eb:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(eb)
    bg:SetColorTexture(unpack(C.bgDark))
    K.Border(eb, 1, 0, 0, 0, 1, "BORDER")
    eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    return eb
end

local function RowBg(row)
    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(row)
    local s = C.surface1
    bg:SetColorTexture(s[1], s[2], s[3], 0.6)
end

function NC.SearchHeight() return 30 + 22 + RESULT_ROWS * ROW_H + 8 end

function NC.BuildSearch(parent, width)
    local w = CreateFrame("Frame", nil, parent)
    local btnW = 150
    w.edit = Edit(w, width - 2 * (btnW + 8))
    w.edit:SetPoint("TOPLEFT", w, "TOPLEFT", 0, 0)
    w.hint = K.NewText(w.edit, 12)
    w.hint:SetPoint("LEFT", w.edit, "LEFT", 8, 0)
    w.hint:SetTextColor(unpack(C.textFaint))
    w.hint:SetText("Name eines NPC …")
    w.edit:SetScript("OnTextChanged", function(self)
        search.text = self:GetText() or ""
        search.msg = nil
        w.Sync()
    end)
    w.edit:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    w.byName = WeintCodex.CreateButton(w, { text = "Als Namen anlegen", kind = "secondary", height = 26, size = 11,
        onClick = function()
            local r = NC.Add(nil, search.text)
            search.msg = r and ("„" .. r.name .. "“ angelegt – gilt für jeden NPC mit genau diesem Namen.")
                or "Erst einen Namen eingeben."
            w.Sync()
        end })
    w.byName:SetWidth(btnW)
    w.byName:SetPoint("LEFT", w.edit, "RIGHT", 8, 0)
    w.target = WeintCodex.CreateButton(w, { text = "Ziel übernehmen", kind = "secondary", height = 26, size = 11,
        onClick = function()
            local r, err = NC.AddTarget()
            search.msg = r and ("„" .. r.name .. "“ angelegt.") or err
            w.Sync()
        end })
    w.target:SetWidth(btnW)
    w.target:SetPoint("LEFT", w.byName, "RIGHT", 8, 0)
    w.status = K.NewText(w, 11)
    w.status:SetPoint("TOPLEFT", w.edit, "BOTTOMLEFT", 0, -8)
    w.status:SetWidth(width)
    w.status:SetJustifyH("LEFT")
    w.status:SetWordWrap(false)
    w.status:SetTextColor(unpack(C.textDim))
    w.rows = {}
    for i = 1, RESULT_ROWS do
        local row = CreateFrame("Frame", nil, w)
        row:SetSize(width, ROW_H - 2)
        row:SetPoint("TOPLEFT", w, "TOPLEFT", 0, -(30 + 22 + (i - 1) * ROW_H))
        RowBg(row)
        row.name = K.NewText(row, 12)
        row.name:SetPoint("LEFT", row, "LEFT", 8, 0)
        row.name:SetWidth(width * 0.45)
        row.name:SetJustifyH("LEFT")
        row.name:SetWordWrap(false)
        row.info = K.NewText(row, 11)
        row.info:SetPoint("LEFT", row.name, "RIGHT", 8, 0)
        row.info:SetPoint("RIGHT", row, "RIGHT", -110, 0)
        row.info:SetJustifyH("LEFT")
        row.info:SetWordWrap(false)
        row.info:SetTextColor(unpack(C.textMuted))
        row.add = WeintCodex.CreateButton(row, { text = "Färben", kind = "secondary", height = 20, size = 10,
            onClick = function()
                local e = row._entry
                if not e then return end
                local r = NC.Add(e.id, e.name)
                search.msg = r and ("„" .. r.name .. "“ angelegt – Farbe unten in der Liste ändern.") or nil
                w.Sync()
            end })
        row.add:SetWidth(96)
        row.add:SetPoint("RIGHT", row, "RIGHT", -2, 0)
        row:Hide()
        w.rows[i] = row
    end
    w.Sync = function()
        local hits = NC.Search(search.text, RESULT_ROWS)
        w.hint:SetShown(search.text == "")
        local n = 0
        for _ in pairs(Seen()) do n = n + 1 end
        if search.msg then
            w.status:SetText(search.msg)
        elseif search.text == "" then
            w.status:SetText(string.format("%d NPCs gesehen – gesucht wird nur unter denen, deren Plakette du schon hattest.", n))
        elseif #hits == 0 then
            w.status:SetText("Unter den gesehenen NPCs nicht dabei – „Als Namen anlegen“ oder „Ziel übernehmen“.")
        else
            w.status:SetText(#hits .. " gefunden")
        end
        for i, row in ipairs(w.rows) do
            local e = hits[i]
            row._entry = e
            if e then
                row.name:SetText(e.name)
                local parts = {}
                if e.zone then parts[#parts + 1] = e.zone end
                if e.caster then parts[#parts + 1] = "zaubert" end
                parts[#parts + 1] = "ID " .. tostring(e.id)
                row.info:SetText(table.concat(parts, " · "))
                local have = NC.Find(e.id, e.name)
                row.add:SetText(have and "Gefärbt" or "Färben")
                row:Show()
            else
                row:Hide()
            end
        end
    end
    return w
end

function NC.RulesHeight() return RULE_ROWS * 36 + 22 end

function NC.BuildRules(parent, width)
    local w = CreateFrame("Frame", nil, parent)
    w.rows = {}
    for i = 1, RULE_ROWS do
        local row = CreateFrame("Frame", nil, w)
        row:SetSize(width, 34)
        row:SetPoint("TOPLEFT", w, "TOPLEFT", 0, -(i - 1) * 36)
        local idx = i
        row.swatch = WeintCodex.CreateColorSwatch(row, {
            label = "", width = width - 110,
            get = function()
                local r = NC.Rules()[idx]
                return r and { r = r.r, g = r.g, b = r.b } or { r = 1, g = 1, b = 1 }
            end,
            set = function(r, g, b)
                local rule = NC.Rules()[idx]
                if rule then NC.SetColor(rule.id, rule.name, r, g, b) end
            end,
        })
        row.swatch:SetPoint("LEFT", row, "LEFT", 0, 0)
        row.remove = WeintCodex.CreateButton(row, { text = "Entfernen", kind = "secondary", height = 20, size = 10,
            onClick = function() NC.Remove(idx) end })
        row.remove:SetWidth(96)
        row.remove:SetPoint("RIGHT", row, "RIGHT", -2, 0)
        row:Hide()
        w.rows[i] = row
    end
    w.empty = K.NewText(w, 12)
    w.empty:SetPoint("TOPLEFT", w, "TOPLEFT", 0, -6)
    w.empty:SetWidth(width)
    w.empty:SetJustifyH("LEFT")
    w.empty:SetTextColor(unpack(C.textDim))
    w.empty:SetText("Noch keine eigenen Farben. Oben einen NPC suchen und „Färben“.")
    w.more = K.NewText(w, 11)
    w.more:SetPoint("TOPLEFT", w, "TOPLEFT", 0, -RULE_ROWS * 36)
    w.more:SetTextColor(unpack(C.textDim))
    w.Sync = function()
        local rules = NC.Rules()
        for i, row in ipairs(w.rows) do
            local r = rules[i]
            if r then
                local label = r.name .. (r.id and ("  ·  ID " .. r.id) or "  ·  jeder mit diesem Namen")
                if row.swatch.SetLabel then row.swatch:SetLabel(label)
                elseif row.swatch._label then row.swatch._label:SetText(label) end
                if row.swatch.Sync then row.swatch.Sync() end
                row:Show()
            else
                row:Hide()
            end
        end
        w.empty:SetShown(#rules == 0)
        w.more:SetText(#rules > RULE_ROWS and ("… und " .. (#rules - RULE_ROWS) .. " weitere") or "")
    end
    return w
end

function NC.BuildPage(B)
    B:Section("Voreinstellung: Zaubernde",
        "Gegner, die zaubern, in eigener Farbe – was unterbrochen werden muss, fällt sofort auf. Erkannt an der Klasse des NPC (Magier, Paladin), an Mana, oder weil WeintCodex ihn schon einen Zauber mit Zauberzeit beginnen sah; das merkt es sich je NPC.")
    B:Row({ type = "toggle", label = "Zaubernde eigens färben", key = "casterColoring" },
          { type = "color", label = "Zaubernde", key = "caster",
            disabled = function() return not K.Get(KEY, "casterColoring") end })
    B:Section("Eigene Farbe je NPC",
        "Name eingeben – WeintCodex sucht unter den NPCs, deren Plakette du schon gesehen hast. Eine eigene Farbe gilt vor allen anderen außer Ziel, Fokus und „markiert“.")
    B:Row({ type = "custom", height = NC.SearchHeight(), create = function(parent, width)
                return NC.BuildSearch(parent, width)
            end }, nil)
    B:Section("Gefärbte NPCs")
    B:Row({ type = "custom", height = NC.RulesHeight(), create = function(parent, width)
                return NC.BuildRules(parent, width)
            end }, nil)
    B:Note("Eine eingebaute Liste der NPCs von Forever gibt es nicht – niemand hier hat sie gelesen. Gefunden wird, was deine Plaketten gesehen haben.")
end

-- An die Namensplaketten haengen.
do
    local m = K.Module(KEY)
    if m then m.pages[#m.pages + 1] = { key = "npcs", label = "NPCs", build = NC.BuildPage } end
end

K.Listen(function(kind, module, key)
    if kind ~= "setting" or module ~= STORE or key ~= "rules" then return end
    NC.Rebuild()
    local NP = WeintCodex.UINameplates
    if NP and NP.RecolorAll then NP.RecolorAll() end
end)
NC.Rebuild()
