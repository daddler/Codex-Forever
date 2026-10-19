--------------------------------------------------
-- WeintCodex :: Wildtierkunde - der dritte Reiter unter "Lehrer", nur Jaeger
--------------------------------------------------
-- Wunsch des Besitzers: ein Buch der zaehmbaren Tiere fuer den Jaeger -
-- Familien, Tiere, Stufe, Gebiete, was sie dem Begleiter beibringen, wo sie
-- stehen. Eigener Code, eigenes Aussehen; der Bestand ist erzeugt
-- (data/beasts.lua von .github/scripts/import_beasts.py, Art `classic`,
-- neue Tiere von Forever `community`).
--
-- DREI BESTAENDE, NIE VERMISCHT:
--   * WAS es gibt: data/beasts.lua (erzeugt, nie im Spiel veraendert).
--   * WAS DU GESEHEN HAST: WeintCodex_SavedData.beasts.seen - beim Anvisieren
--     eines zaehmbaren Tieres Name, Stufe, Gebiet; nach Wildtierkunde
--     (Zauber 1462) zusaetzlich, was der Tooltip an Faehigkeiten nennt.
--     Nennt er nichts: "unbekannt", nie "keine".
--   * WAS DEIN BEGLEITER KANN: aus dem Fenster der Wildtierausbildung, je
--     Charakter - nur wenn der Client es oeffnet und antwortet.
-- Ob Forever dieselben Tiere an dieselben Stellen setzt, weiss niemand:
-- jede Angabe traegt ihre Art ("Aus Classic", "Unbestaetigt").
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.Beasts = {}

local BL = WeintCodex.Beasts
local D  = WeintCodex.BeastData
local C  = WeintCodex.Colors

BL.LORE_SPELL = 1462     -- Wildtierkunde (data/trainer.lua, Jaeger)
BL.MAX_ROWS = 150        -- mehr Zeilen baut die Liste nicht; Suche grenzt ein

local function Plain(v)
    local K = WeintCodex.UIKit
    if K and K.Plain then return K.Plain(v) end
    return v
end

--------------------------------------------------
-- Bestand
--------------------------------------------------

local function Split(s, sep)
    local out, i = {}, 1
    while true do
        local j = s:find(sep, i, true)
        if not j then out[#out + 1] = s:sub(i) break end
        out[#out + 1] = s:sub(i, j - 1)
        i = j + 1
    end
    return out
end

-- Ein Tier als Tabelle (erst wenn gebraucht; der Bestand bleibt Text).
-- { id, family, name, level, rare, elite, new, swing, zones = { zi, ... },
--   teaches = { { a = Faehigkeit, rank = n }, ... }, kind }
function BL.Get(id)
    local s = D and D.b and D.b[id]
    if type(s) ~= "string" then return nil end
    local f = Split(s, "\t")
    local b = { id = id, family = tonumber(f[1]), name = f[2], level = f[3] ~= "" and f[3] or nil,
                swing = tonumber(f[5] or ""), zones = {}, teaches = {} }
    local flags = f[4] or ""
    b.rare, b.elite, b.new = flags:find("r", 1, true) ~= nil, flags:find("e", 1, true) ~= nil, flags:find("n", 1, true) ~= nil
    b.kind = b.new and "community" or "classic"
    if f[6] and f[6] ~= "" then
        for _, z in ipairs(Split(f[6], ",")) do b.zones[#b.zones + 1] = tonumber(z) end
    end
    if f[7] and f[7] ~= "" then
        for _, t in ipairs(Split(f[7], ",")) do
            local a, r = t:match("^(%d+):(%d+)$")
            if a then b.teaches[#b.teaches + 1] = { a = tonumber(a), rank = tonumber(r) } end
        end
    end
    return b
end

function BL.Family(i)
    local f = D and D.F and D.F[i]
    if not f then return nil end
    return { index = i, key = f[1], name = f[2], icon = "Interface\\Icons\\" .. f[3], abilities = f[4] }
end

function BL.Ability(i)
    local a = D and D.A and D.A[i]
    if not a then return nil end
    return { index = i, key = a[1], name = a[2], icon = a[3], ranks = a[4] }
end

function BL.ZoneName(i)
    local z = D and D.Z and D.Z[i]
    return z and z[1] or nil
end

function BL.ZoneMap(i)
    local z = D and D.Z and D.Z[i]
    return z and type(z[2]) == "number" and z[2] or nil
end

-- Spawns je Gebiet: { { zone = zi, map = id, points = { {x,y}, ... } }, ... }
function BL.Spots(id)
    local s = D and D.s and D.s[id]
    local out = {}
    if type(s) ~= "string" then return out end
    for _, part in ipairs(Split(s, ";")) do
        local zi, pts = part:match("^(%d+):(%d+)$")
        zi = tonumber(zi)
        local map = zi and BL.ZoneMap(zi)
        if map then
            local e = { zone = zi, map = map, points = {} }
            for i = 1, #pts - 5, 6 do
                e.points[#e.points + 1] = { tonumber(pts:sub(i, i + 2)) / 1000, tonumber(pts:sub(i + 3, i + 5)) / 1000 }
            end
            out[#out + 1] = e
        end
    end
    return out
end

-- Kleinschreibung fuer die Suche, auch fuer die deutschen Umlaute.
local FOLD = { ["\195\132"] = "\195\164", ["\195\150"] = "\195\182", ["\195\156"] = "\195\188" }
function BL.Fold(s)
    return (tostring(s or ""):lower():gsub("\195[\132\150\156]", FOLD))
end

-- Alle Nummern des Bestands, sortiert nach Familie, dann Name (einmal).
local order
local function Order()
    if order then return order end
    order = {}
    for id in pairs(D and D.b or {}) do order[#order + 1] = id end
    local fam, name = {}, {}
    for _, id in ipairs(order) do
        local s = D.b[id]
        fam[id] = tonumber(s:match("^(%d+)")) or 0
        name[id] = s:match("^%d+\t([^\t]*)") or ""
    end
    table.sort(order, function(a, b)
        if fam[a] ~= fam[b] then return fam[a] < fam[b] end
        if name[a] ~= name[b] then return name[a] < name[b] end
        return a < b
    end)
    return order
end

-- Text, in dem die Suche sucht: Name, Familie, Gebiete, Faehigkeiten.
local function Haystack(b)
    local parts = { b.name }
    local f = BL.Family(b.family)
    if f then parts[#parts + 1] = f.name parts[#parts + 1] = f.key end
    for _, z in ipairs(b.zones) do parts[#parts + 1] = BL.ZoneName(z) or "" end
    for _, t in ipairs(b.teaches) do
        local a = BL.Ability(t.a)
        if a then parts[#parts + 1] = a.name end
    end
    return BL.Fold(table.concat(parts, " "))
end

-- filter: "all" | "fav" | "new" | Familiennummer. query: Text oder nil.
-- Mit Suchtext wird ueber alle Familien gesucht.
function BL.Search(query, filter)
    local q = query and BL.Fold(query):gsub("^%s+", ""):gsub("%s+$", "") or ""
    local st = BL.Store()
    local out = {}
    for _, id in ipairs(Order()) do
        local s = D.b[id]
        local fi = tonumber(s:match("^(%d+)"))
        local keep
        if filter == "fav" then keep = st.fav[id] and true or false
        elseif filter == "new" then keep = BL.IsNew(id)
        elseif q ~= "" then keep = true
        elseif type(filter) == "number" then keep = fi == filter
        else keep = true end
        if keep then
            local b = BL.Get(id)
            if q == "" or Haystack(b):find(q, 1, true) then out[#out + 1] = b end
        end
    end
    return out
end

function BL.Count(fi)
    local n = 0
    for _, s in pairs(D and D.b or {}) do
        if tonumber(s:match("^(%d+)")) == fi then n = n + 1 end
    end
    return n
end

--------------------------------------------------
-- Gespeichert (je Konto; was der Begleiter kann, je Charakter)
--------------------------------------------------

function BL.Store()
    local sv = _G.WeintCodex_SavedData
    if type(sv) ~= "table" then
        -- Nie in eine frische Ersatztabelle schreiben: ohne SavedData nur lesen.
        return { seen = {}, fav = {}, known = {}, lastLook = 0, readonly = true }
    end
    local b = sv.beasts
    if type(b) ~= "table" then b = {} sv.beasts = b end
    b.seen = type(b.seen) == "table" and b.seen or {}
    b.fav = type(b.fav) == "table" and b.fav or {}
    b.known = type(b.known) == "table" and b.known or {}
    b.lastLook = type(b.lastLook) == "number" and b.lastLook or 0
    return b
end

local function Now()
    local t = _G.time and Plain(_G.time())
    return type(t) == "number" and t or 0
end

-- Seit dem letzten Blick neu gesehen? Der letzte Blick gilt fuer die ganze
-- Sitzung (sonst verschwaende "neu" beim ersten Zeichnen).
local prevLook
function BL.IsNew(id)
    local st = BL.Store()
    local r = st.seen[id]
    local since = prevLook or st.lastLook
    return type(r) == "table" and type(r.t) == "number" and r.t > since or false
end

function BL.MarkLooked()
    local st = BL.Store()
    if prevLook == nil then prevLook = st.lastLook end
    if not st.readonly then st.lastLook = Now() end
end

function BL.ToggleFav(id)
    local st = BL.Store()
    if st.readonly then return false end
    st.fav[id] = (not st.fav[id]) and true or nil
    return st.fav[id] == true
end

local function PlayerClass()
    if not _G.UnitClass then return nil, nil end
    local ok, name, class = pcall(_G.UnitClass, "player")
    if not ok then return nil, nil end
    name, class = Plain(name), Plain(class)
    return type(class) == "string" and class or nil, type(name) == "string" and name or nil
end
function BL.IsHunter() return PlayerClass() == "HUNTER" end

-- NPC-Nummer aus der GUID ("Creature-0-x-x-x-NPC-xxxx"); geheim = nil.
function BL.NpcId(unit)
    if not _G.UnitGUID then return nil end
    local ok, g = pcall(_G.UnitGUID, unit)
    g = ok and Plain(g) or nil
    if type(g) ~= "string" then return nil end
    local kind, id = g:match("^(%a+)%-%d+%-%d+%-%d+%-%d+%-(%d+)")
    if kind ~= "Creature" then return nil end
    return tonumber(id)
end

local function HereMap()
    local cm = _G.C_Map
    if not (cm and cm.GetBestMapForUnit) then return nil end
    local ok, m = pcall(cm.GetBestMapForUnit, "player")
    m = ok and Plain(m) or nil
    return type(m) == "number" and m or nil
end

-- Ziel anvisiert: zaehmbares Tier aus dem Bestand -> Name, Stufe, Gebiet.
-- Gibt den Eintrag zurueck oder nil.
function BL.RecordTarget(unit)
    unit = unit or "target"
    if not BL.IsHunter() then return nil end
    local id = BL.NpcId(unit)
    if not id or not (D and D.b and D.b[id]) then return nil end
    local st = BL.Store()
    if st.readonly then return nil end
    local r = st.seen[id]
    local first = type(r) ~= "table"
    if first then r = {} st.seen[id] = r end
    local okN, name = pcall(_G.UnitName or function() end, unit)
    name = okN and Plain(name) or nil
    if type(name) == "string" and name ~= "" then r.name = name end
    local okL, lvl = pcall(_G.UnitLevel or function() end, unit)
    lvl = okL and Plain(lvl) or nil
    if type(lvl) == "number" and lvl > 0 then r.level = lvl end
    local map = HereMap()
    if map then r.map = map end
    if first then r.t = Now() end
    return r
end

-- Faehigkeiten aus dem Tooltip des Ziels nach Wildtierkunde: Zeilen, die
-- eine Faehigkeit der Familie nennen, mit "Rang N". Nichts gefunden: nil.
function BL.ReadLoreTooltip(unit, b)
    local ti = _G.C_TooltipInfo
    if not (ti and ti.GetUnit and b) then return nil end
    local ok, data = pcall(ti.GetUnit, unit)
    if not ok or type(data) ~= "table" or type(data.lines) ~= "table" then return nil end
    local fam = BL.Family(b.family)
    local found
    for _, line in ipairs(data.lines) do
        local text = Plain(line.leftText)
        if type(text) == "string" then
            for _, ai in ipairs(fam and fam.abilities or {}) do
                local a = BL.Ability(ai)
                local s, e = text:find(a.name, 1, true)
                if s then
                    local rank = tonumber(text:sub(e + 1):match("(%d+)"))
                    found = found or {}
                    found[ai] = rank or found[ai] or true
                end
            end
        end
    end
    return found
end

function BL.OnLore(unit)
    unit = unit or "target"
    local r = BL.RecordTarget(unit)
    if not r then return nil end
    r.lore = Now()
    local id = BL.NpcId(unit)
    local ab = BL.ReadLoreTooltip(unit, BL.Get(id))
    if ab then r.abilities = ab end
    return r
end

-- Wildtierausbildung (klassische Schnittstelle GetCraft*): was der Begleiter
-- kann, je Charakter. Ohne Antwort bleibt der Stand unbekannt.
local TRAINING = { ["Wildtierausbildung"] = true, ["Beast Training"] = true }
function BL.ReadTraining()
    if not (_G.GetNumCrafts and _G.GetCraftInfo) then return nil end
    if _G.GetCraftDisplaySkillLine then
        local ok, line = pcall(_G.GetCraftDisplaySkillLine)
        line = ok and Plain(line) or nil
        if type(line) ~= "string" or not TRAINING[line] then return nil end
    end
    local okN, n = pcall(_G.GetNumCrafts)
    n = okN and Plain(n) or nil
    if type(n) ~= "number" or n <= 0 then return nil end
    local byName = {}
    for i = 1, #(D and D.A or {}) do byName[D.A[i][2]] = i byName[D.A[i][1]] = i end
    local known = {}
    for i = 1, n do
        local ok, name, sub, kind = pcall(_G.GetCraftInfo, i)
        name, sub, kind = Plain(name), Plain(sub), Plain(kind)
        if ok and type(name) == "string" and byName[name] and kind ~= "header" then
            local rank = type(sub) == "string" and tonumber(sub:match("(%d+)")) or 1
            local ai = byName[name]
            if not known[ai] or known[ai] < rank then known[ai] = rank end
        end
    end
    local K = WeintCodex.UIKit
    local key = K and K.CharKey and K.CharKey()
    local st = BL.Store()
    if key and not st.readonly then st.known[key] = known end
    return known
end

function BL.Known()
    local K = WeintCodex.UIKit
    local key = K and K.CharKey and K.CharKey()
    local st = BL.Store()
    return key and st.known[key] or nil
end

--------------------------------------------------
-- Karte und Pfeil
--------------------------------------------------

local UI = "Interface\\AddOns\\WeintCodex\\media\\ui\\"
local mapState = { map = nil, points = nil }
local dots, driver = {}, nil
BL.mapState = mapState

local function HideDots(from)
    for i = from or 1, #dots do dots[i]:Hide() end
end

local function PlaceDots()
    local QM = WeintCodex.QuestMap
    local wm = _G.WorldMapFrame
    local pts = mapState.points
    if not (pts and QM and QM.Canvas and QM.CurrentMap) or QM.CurrentMap() ~= mapState.map then HideDots() return 0 end
    local canvas = QM.Canvas()
    if not canvas then HideDots() return 0 end
    local w, h = Plain(canvas:GetWidth()), Plain(canvas:GetHeight())
    if type(w) ~= "number" or type(h) ~= "number" or w <= 1 then return 0 end
    local s = 1
    local cs = Plain(canvas.GetEffectiveScale and canvas:GetEffectiveScale())
    local ms = Plain(wm and wm.GetEffectiveScale and wm:GetEffectiveScale())
    if type(cs) == "number" and type(ms) == "number" and cs > 0 and ms > 0 then s = cs / ms end
    for i, p in ipairs(pts) do
        local d = dots[i]
        if not d then
            d = CreateFrame("Frame", nil, canvas)
            d:SetSize(12, 12)
            d.rim = d:CreateTexture(nil, "ARTWORK", nil, 1)
            d.rim:SetTexture(UI .. "disc")
            d.rim:SetAllPoints(d)
            d.rim:SetVertexColor(C.bgPanel[1], C.bgPanel[2], C.bgPanel[3], 0.9)
            d.core = d:CreateTexture(nil, "ARTWORK", nil, 2)
            d.core:SetTexture(UI .. "disc")
            d.core:SetSize(8, 8)
            d.core:SetPoint("CENTER", d, "CENTER")
            d.core:SetVertexColor(C.accentBright[1], C.accentBright[2], C.accentBright[3], 1)
            dots[i] = d
        end
        if d:GetParent() ~= canvas then d:SetParent(canvas) end
        d:SetScale(1 / s)
        local lvl = Plain(canvas.GetFrameLevel and canvas:GetFrameLevel())
        d:SetFrameLevel(math.min(9000, (type(lvl) == "number" and lvl or 0) + 1900))
        d:ClearAllPoints()
        d:SetPoint("CENTER", canvas, "TOPLEFT", w * p[1] * s, -h * p[2] * s)
        d:Show()
    end
    HideDots(#pts + 1)
    return #pts
end
BL.PlaceDots = PlaceDots

local function EnsureDriver()
    if driver then return end
    local wm = _G.WorldMapFrame
    if type(wm) ~= "table" then return end
    driver = CreateFrame("Frame", nil, wm)
    local acc = 0
    driver:SetScript("OnUpdate", function(_, el)
        acc = acc + (el or 0)
        if acc < 0.1 then return end
        acc = 0
        PlaceDots()
    end)
    driver:SetScript("OnHide", function() HideDots() end)
end

-- Der naechste Spawn zum Spieler (gleiche Karte), sonst der erste.
function BL.NearestSpot(id)
    local spots = BL.Spots(id)
    if #spots == 0 then return nil end
    local here = HereMap()
    local px, py
    if here and _G.C_Map and _G.C_Map.GetPlayerMapPosition then
        local ok, pos = pcall(_G.C_Map.GetPlayerMapPosition, here, "player")
        if ok and pos then px, py = Plain(pos.x), Plain(pos.y) end
    end
    local best, bd
    for _, e in ipairs(spots) do
        for _, p in ipairs(e.points) do
            local d
            if e.map == here and type(px) == "number" and type(py) == "number" then
                d = (p[1] - px) ^ 2 + (p[2] - py) ^ 2
            else
                d = 10 + (e.map == here and 0 or 1)
            end
            if not bd or d < bd then best, bd = { map = e.map, x = p[1], y = p[2], zone = e.zone }, d end
        end
    end
    return best
end

-- Weltkarte auf dem Gebiet: Marke am naechsten Spawn, Punkte an allen.
function BL.ShowOnMap(id)
    local b = BL.Get(id)
    local spot = b and BL.NearestSpot(id)
    if not spot then return false end
    for _, e in ipairs(BL.Spots(id)) do
        if e.map == spot.map then mapState.map, mapState.points = e.map, e.points end
    end
    EnsureDriver()
    local QM = WeintCodex.QuestMap
    local fam = BL.Family(b.family)
    if QM and QM.Show then
        QM.Show({ map = spot.map, x = spot.x, y = spot.y, who = b.name }, nil,
            "Wildtier" .. (fam and (" · " .. fam.name) or "") .. (b.level and (" · Stufe " .. b.level) or ""))
    end
    return true
end

function BL.Guide(id)
    local QA = WeintCodex.UIQuestArrow
    local b = BL.Get(id)
    local spot = b and BL.NearestSpot(id)
    if not (spot and QA and QA.SetCustom) then return false end
    QA.SetCustom({ map = spot.map, x = spot.x, y = spot.y, title = "Wildtier: " .. b.name })
    return true
end

--------------------------------------------------
-- Seite
--------------------------------------------------

local page
BL.filter, BL.query, BL.selected = "all", "", nil
local ROW_H, FAM_H = 38, 28
local rowPool, famPool = {}, {}
local usedRows, usedFam = 0, 0

local function SourceText(b)
    local S = WeintCodex.Sources
    local src = b.new and (S and S.COMMUNITY) or (S and S.CLASSIC)
    return src and S.Prefix(src) or (b.new and "Unbestätigt" or "Aus Classic")
end

local function LevelText(b)
    return b.level and ("Stufe " .. b.level) or "Stufe unbekannt"
end

local function Tags(b)
    local t = {}
    if b.rare then t[#t + 1] = WeintCodex.ColorText("infoBright", "Selten") end
    if b.elite then t[#t + 1] = WeintCodex.ColorText("warningBright", "Elite") end
    if b.new then t[#t + 1] = WeintCodex.ColorText("textMuted", "neu in Forever") end
    return table.concat(t, " · ")
end

local function TeachText(b)
    local t = {}
    for _, x in ipairs(b.teaches) do
        local a = BL.Ability(x.a)
        if a then t[#t + 1] = a.name .. " " .. x.rank end
    end
    return #t > 0 and table.concat(t, ", ") or nil
end

local function ZonesText(b, max)
    local t = {}
    for i, z in ipairs(b.zones) do
        if max and i > max then t[#t + 1] = "…" break end
        t[#t + 1] = BL.ZoneName(z) or "?"
    end
    return #t > 0 and table.concat(t, ", ") or "Gebiet unbekannt"
end

local function ResetPools()
    for _, r in ipairs(rowPool) do r:Hide() end
    for _, r in ipairs(famPool) do r:Hide() end
    usedRows, usedFam = 0, 0
end

local function BuildPage()
    if page then return page end
    local cp = WeintCodex.ContentPanel
    local f = CreateFrame("Frame", nil, cp)
    f:SetAllPoints(cp)
    local M = WeintCodex.Metrics
    f.Head = WeintCodex.PageHead(f, {
        eyebrow = "Leveln",
        title   = "Wildtierkunde",
        sub     = "Zähmbare Tiere nach Familie – was sie deinem Begleiter beibringen und wo sie stehen.",
        height  = 84,
    })
    local fc = WeintCodex.CreateSurface(f, { tone = "plain", radius = 14, backdrop = "bgDark" })
    fc:SetPoint("TOPLEFT",    f, "TOPLEFT",    M.PAD_X, -(M.PAD_Y + 84))
    fc:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", M.PAD_X, M.PAD_Y)
    fc:SetWidth(200)
    f.FamCard = fc
    local ft = WeintCodex.Label(fc, "Familien", { size = 14, color = "textBright", font = WeintCodex.Fonts.sansSemi })
    ft:SetPoint("TOPLEFT", fc, "TOPLEFT", 16, -16)
    f.FamScroll, f.FamBody = WeintCodex.CreateScrollArea(fc, 12, -46, 176, 300, true)

    local bc = WeintCodex.CreateSurface(f, { tone = "plain", radius = 14, backdrop = "bgDark" })
    bc:SetPoint("TOPLEFT",     fc, "TOPRIGHT", M.GAP, 0)
    bc:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -M.PAD_X, M.PAD_Y)
    f.BeastCard = bc

    -- Suche wie auf der Seite Taschen: Feld mit Loeschknopf, Esc leert.
    local box = CreateFrame("Frame", nil, bc)
    box:SetPoint("TOPLEFT", bc, "TOPLEFT", 20, -14)
    box:SetSize(260, 28)
    local bb = box:CreateTexture(nil, "BACKGROUND")
    bb:SetAllPoints(box)
    bb:SetColorTexture(C.surface2[1], C.surface2[2], C.surface2[3], 1)
    local eb = CreateFrame("EditBox", nil, box)
    eb:SetPoint("TOPLEFT", box, "TOPLEFT", 0, 0)
    eb:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -26, 0)
    eb:SetAutoFocus(false)
    eb:SetMaxLetters(40)
    eb:SetFont(WeintCodex.Fonts.sans, 12, "")
    eb:SetTextInsets(10, 4, 0, 0)
    eb:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3])
    eb.hint = WeintCodex.Label(box, "Tier, Gebiet oder Fähigkeit …", { size = 12, color = "textMuted" })
    eb.hint:SetPoint("LEFT", box, "LEFT", 10, 0)
    local clear = CreateFrame("Button", nil, box)
    clear:SetSize(24, 24)
    clear:SetPoint("RIGHT", box, "RIGHT", -2, 0)
    clear.x = WeintCodex.Label(clear, "\195\151", { size = 15, color = "textMuted" })
    clear.x:SetPoint("CENTER", clear, "CENTER", 0, 1)
    clear:SetScript("OnClick", function() eb:SetText("") eb:ClearFocus() end)
    clear:Hide()
    eb:SetScript("OnTextChanged", function(self)
        local t = self:GetText() or ""
        self.hint:SetShown(t == "")
        clear:SetShown(t ~= "")
        if t == BL.query then return end
        BL.query = t
        BL.Draw()
    end)
    eb:SetScript("OnEscapePressed", function(self) self:SetText("") self:ClearFocus() end)
    eb:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    f.Search = eb
    f.Count = WeintCodex.Label(bc, "", { size = 11, color = "textDim", justify = "RIGHT" })
    f.Count:SetPoint("TOPRIGHT", bc, "TOPRIGHT", -18, -22)
    f.BeastScroll, f.BeastBody = WeintCodex.CreateScrollArea(bc, 20, -52, 420, 300, true)

    f:SetScript("OnSizeChanged", function(self, width)
        width = Plain(width)
        if self:IsShown() and type(width) == "number" and type(self.drawnWidth) == "number"
           and math.abs(width - self.drawnWidth) > 2 then
            BL.Redraw()
        end
    end)
    page = f
    return f
end

local function FamRow(body, y, w, key, label, count, icon)
    usedFam = usedFam + 1
    local r = famPool[usedFam]
    if not r then
        r = CreateFrame("Button", nil, body)
        r:SetHeight(FAM_H)
        r.sel = r:CreateTexture(nil, "BACKGROUND")
        r.sel:SetAllPoints(r)
        r.sel:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.16)
        local hl = r:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints(r)
        hl:SetColorTexture(C.textBright[1], C.textBright[2], C.textBright[3], 0.05)
        r.icon = r:CreateTexture(nil, "ARTWORK")
        r.icon:SetSize(18, 18)
        r.icon:SetPoint("LEFT", r, "LEFT", 4, 0)
        r.label = WeintCodex.Label(r, "", { size = 12, font = WeintCodex.Fonts.sansMedium })
        r.label:SetPoint("LEFT", r, "LEFT", 28, 0)
        r.count = WeintCodex.Label(r, "", { size = 10, color = "textDim", justify = "RIGHT", font = WeintCodex.Fonts.mono })
        r.count:SetPoint("RIGHT", r, "RIGHT", -6, 0)
        r:SetScript("OnClick", function(self)
            BL.filter, BL.selected = self.key, nil
            BL.Draw()
        end)
        famPool[usedFam] = r
    end
    r:SetParent(body)
    r:ClearAllPoints()
    r:SetPoint("TOPLEFT", body, "TOPLEFT", 0, y)
    r:SetWidth(w)
    r.key = key
    r.sel:SetShown(BL.filter == key)
    r.label:SetText(label)
    r.count:SetText(count and tostring(count) or "")
    r.icon:SetTexture(icon or (UI .. "dot"))
    r:Show()
    return y - FAM_H
end

local function BeastRow(body, y, w, b)
    usedRows = usedRows + 1
    local r = rowPool[usedRows]
    if not r then
        r = CreateFrame("Button", nil, body)
        r:SetHeight(ROW_H)
        r.sel = r:CreateTexture(nil, "BACKGROUND")
        r.sel:SetAllPoints(r)
        r.sel:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.14)
        local hl = r:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints(r)
        hl:SetColorTexture(C.textBright[1], C.textBright[2], C.textBright[3], 0.05)
        r.icon = r:CreateTexture(nil, "ARTWORK")
        r.icon:SetSize(22, 22)
        r.icon:SetPoint("LEFT", r, "LEFT", 2, 0)
        r.level = WeintCodex.Label(r, "", { size = 11, justify = "RIGHT", color = "textDim", font = WeintCodex.Fonts.mono })
        r.level:SetPoint("TOPRIGHT", r, "TOPRIGHT", -4, -5)
        r.mark = WeintCodex.Label(r, "", { size = 10, justify = "RIGHT" })
        r.mark:SetPoint("RIGHT", r.level, "LEFT", -10, 0)
        r.title = WeintCodex.Label(r, "", { size = 12, font = WeintCodex.Fonts.sansMedium })
        r.title:SetPoint("TOPLEFT", r, "TOPLEFT", 32, -4)
        r.title:SetPoint("RIGHT", r.mark, "LEFT", -8, 0)
        r.title:SetWordWrap(false)
        r.sub = WeintCodex.Label(r, "", { size = 10, color = "textMuted" })
        r.sub:SetPoint("TOPLEFT", r.title, "BOTTOMLEFT", 0, -3)
        r.sub:SetPoint("RIGHT", r, "RIGHT", -4, 0)
        r.sub:SetWordWrap(false)
        if r.RegisterForClicks then r:RegisterForClicks("LeftButtonUp", "RightButtonUp") end
        r:SetScript("OnClick", function(self, button)
            if button == "RightButton" then BL.Guide(self.id) return end
            BL.selected = self.id
            BL.Draw()
        end)
        r:SetScript("OnEnter", function(self)
            local gt = _G.GameTooltip
            if not gt then return end
            gt:SetOwner(self, "ANCHOR_RIGHT")
            gt:SetText(self.name or "", C.textBright[1], C.textBright[2], C.textBright[3])
            gt:AddLine("Klick: Einzelheiten · Rechtsklick: Pfeil hierhin", C.textMuted[1], C.textMuted[2], C.textMuted[3], true)
            gt:Show()
        end)
        r:SetScript("OnLeave", function() if _G.GameTooltip then _G.GameTooltip:Hide() end end)
        rowPool[usedRows] = r
    end
    r:SetParent(body)
    r:ClearAllPoints()
    r:SetPoint("TOPLEFT", body, "TOPLEFT", 0, y)
    r:SetWidth(w)
    r.id, r.name = b.id, b.name
    r.sel:SetShown(BL.selected == b.id)
    local fam = BL.Family(b.family)
    r.icon:SetTexture(fam and fam.icon or (UI .. "dot"))
    local st = BL.Store()
    local seen = st.seen[b.id]
    local c = seen and C.textBright or C.textNormal
    r.title:SetText((st.fav[b.id] and WeintCodex.ColorText("goldBright", "\226\152\133 ") or "") .. b.name)
    r.title:SetTextColor(c[1], c[2], c[3])
    r.level:SetText(b.level or "?")
    if BL.IsNew(b.id) then
        r.mark:SetText(WeintCodex.ColorText("accentBright", "NEU"))
    elseif seen then
        r.mark:SetText(WeintCodex.ColorText("textDim", "gesehen"))
    else
        r.mark:SetText("")
    end
    local sub = ZonesText(b, 2)
    local tags, teach = Tags(b), TeachText(b)
    if tags ~= "" then sub = tags .. "  ·  " .. sub end
    if teach then sub = sub .. "  ·  " .. WeintCodex.ColorText("successBright", "Lehrt " .. teach) end
    r.sub:SetText(sub)
    r:Show()
    return y - ROW_H
end

-- Detailbereich: das gewaehlte Tier, sonst die Uebersicht.
function BL.InspectorBlocks(id)
    local b = id and BL.Get(id)
    local st = BL.Store()
    if not b then
        local seen = 0
        for _ in pairs(st.seen) do seen = seen + 1 end
        local known = BL.Known()
        local kt = {}
        if known then
            for ai, rank in pairs(known) do
                local a = BL.Ability(ai)
                if a then kt[#kt + 1] = a.name .. " " .. rank end
            end
            table.sort(kt)
        end
        return {
            { type = "header", text = "Wildtierkunde" },
            { type = "rows", rows = {
                { label = "Tiere im Bestand", value = tostring(#Order()) },
                { label = "Von dir gesehen", value = tostring(seen) },
            }},
            { type = "header", text = "Dein Begleiter kann" },
            { type = "text", text = known and (#kt > 0 and table.concat(kt, ", ") or "nichts aus der Liste")
                or "Unbekannt – öffne einmal das Fenster der Wildtierausbildung." },
            { type = "divider" },
            { type = "header", text = "Woher das stammt" },
            { type = "card", lines = {
                "Aus Classic: Tiere, Stufen, Gebiete und was sie",
                "lehren – ob Forever sie gleich setzt, steht nicht",
                "fest. Neue Tiere von Forever: unbestätigt.",
                "Gesehen ist, was du anvisiert hast; Wildtierkunde",
                "ergänzt, was der Tooltip nennt.",
            }},
        }
    end
    local fam = BL.Family(b.family)
    local seen = st.seen[b.id]
    local S = WeintCodex.Sources
    local src = b.new and (S and S.COMMUNITY) or (S and S.CLASSIC)
    local rows = {
        { label = "Familie", value = fam and fam.name or "—" },
        { label = "Stufe", value = b.level or "unbekannt" },
        { label = "Angriffstempo", value = b.swing and (string.format("%.1f s", b.swing):gsub("%.", ",")) or "unbekannt" },
        { label = "Herkunft", value = SourceText(b) },
    }
    if b.rare or b.elite then rows[#rows + 1] = { label = "Rang", value = (b.rare and "Selten" or "") .. ((b.rare and b.elite) and ", " or "") .. (b.elite and "Elite" or "") } end
    local blocks = {
        { type = "header", text = b.name },
        { type = "rows", rows = rows },
        { type = "header", text = "Gebiete" },
        { type = "text", text = ZonesText(b) },
        { type = "header", text = "Lehrt deinen Begleiter" },
        { type = "text", text = TeachText(b) or "Unbekannt – im Bestand steht nichts dazu." },
        { type = "header", text = "Von dir" },
    }
    if seen then
        local lore
        if seen.lore and type(seen.abilities) == "table" then
            local t = {}
            for ai, rank in pairs(seen.abilities) do
                local a = BL.Ability(ai)
                if a then t[#t + 1] = a.name .. (type(rank) == "number" and (" " .. rank) or "") end
            end
            table.sort(t)
            lore = "Wildtierkunde: " .. table.concat(t, ", ")
        elseif seen.lore then
            lore = "Wildtierkunde gewirkt – Fähigkeiten unbekannt."
        end
        local QM = WeintCodex.QuestMap
        local where = seen.map and QM and QM.MapName and QM.MapName(seen.map)
        blocks[#blocks + 1] = { type = "text", text = "Gesehen" .. (seen.level and (" mit Stufe " .. seen.level) or "")
            .. (where and (" in " .. where) or "") .. "." .. (lore and ("\n" .. lore) or "") }
    else
        blocks[#blocks + 1] = { type = "text", text = "Noch nicht gesehen. Visiere es an oder wirke Wildtierkunde." }
    end
    local spot = BL.NearestSpot(b.id)
    if spot then
        blocks[#blocks + 1] = { type = "button", label = "Auf der Karte zeigen", style = "primary",
            onClick = function() BL.ShowOnMap(b.id) end }
        blocks[#blocks + 1] = { type = "button", label = "Pfeil hierhin", onClick = function() BL.Guide(b.id) end }
    else
        blocks[#blocks + 1] = { type = "text", text = "Keine Lage auf einer Gebietskarte hinterlegt." }
    end
    blocks[#blocks + 1] = { type = "button", label = st.fav[b.id] and "Kein Favorit mehr" or "Als Favorit merken",
        onClick = function() BL.ToggleFav(b.id) BL.Draw() end }
    blocks[#blocks + 1] = { type = "divider" }
    blocks[#blocks + 1] = { type = "text", text = (S and S.Why and src and S.Why(src) or SourceText(b)) }
    return blocks
end

function BL.Draw()
    local cp = WeintCodex.ContentPanel
    for _, child in pairs({ cp:GetChildren() }) do child:Hide() end
    local f = BuildPage()
    f:Show()
    WeintCodex.SetBreadcrumb("Lehrer", "Wildtierkunde")
    BL.MarkLooked()
    WeintCodex.Navigation.SetInspector(BL.InspectorBlocks(BL.selected))

    local total = Plain(f:GetWidth())
    local fh = (Plain(f.FamCard:GetHeight()) or 360) - 62
    local bw = (Plain(f.BeastCard:GetWidth()) or 460) - 40
    local bh = (Plain(f.BeastCard:GetHeight()) or 360) - 68
    f.FamScroll:SetSize(176, math.max(60, fh))
    f.FamBody:SetWidth(166)
    f.BeastScroll:SetSize(bw, math.max(60, bh))
    f.BeastBody:SetWidth(bw - 10)

    ResetPools()
    local st = BL.Store()
    local favs, news = 0, 0
    for id in pairs(st.fav) do if D.b[id] then favs = favs + 1 end end
    for id in pairs(st.seen) do if BL.IsNew(id) then news = news + 1 end end
    local y = 0
    y = FamRow(f.FamBody, y, 166, "all", "Alle Tiere", #Order())
    y = FamRow(f.FamBody, y, 166, "fav", "Favoriten", favs)
    y = FamRow(f.FamBody, y, 166, "new", "Neu gesehen", news)
    y = y - 6
    for i = 1, #(D and D.F or {}) do
        local fam = BL.Family(i)
        y = FamRow(f.FamBody, y, 166, i, fam.name, BL.Count(i), fam.icon)
    end
    f.FamBody:SetHeight(math.max(1, -y))

    local list = BL.Search(BL.query, BL.filter)
    local by = 0
    for i, b in ipairs(list) do
        if i > BL.MAX_ROWS then break end
        by = BeastRow(f.BeastBody, by, bw - 14, b)
    end
    f.Count:SetText(#list > BL.MAX_ROWS and (BL.MAX_ROWS .. " von " .. #list .. " – Suche grenzt ein")
        or (#list == 1 and "1 Tier" or (#list .. " Tiere")))
    if #list == 0 then
        f.Count:SetText(BL.filter == "fav" and "Noch kein Favorit" or BL.filter == "new" and "Nichts Neues gesehen" or "Nichts gefunden")
    end
    f.BeastBody:SetHeight(math.max(1, -by))
    f.drawnWidth = total
    BL.lastDraw = { rows = usedRows, families = usedFam, total = #list }
end

function BL.Page() return page end

local queued = false
function BL.Redraw()
    if queued or not (page and page:IsShown()) then return end
    queued = true
    local function run() queued = false if page and page:IsShown() then BL.Draw() end end
    if _G.C_Timer and _G.C_Timer.After then _G.C_Timer.After(0.3, run) else run() end
end

--------------------------------------------------
-- Ereignisse: nur fuer Jaeger von Belang, billig fuer alle anderen
--------------------------------------------------

local ev = CreateFrame("Frame")
for _, e in ipairs({ "PLAYER_TARGET_CHANGED", "UNIT_SPELLCAST_SUCCEEDED", "CRAFT_SHOW", "CRAFT_UPDATE" }) do
    pcall(ev.RegisterEvent, ev, e)
end
ev:SetScript("OnEvent", function(_, event, unit, _, spellID)
    if not BL.IsHunter() then return end
    if event == "PLAYER_TARGET_CHANGED" then
        if BL.RecordTarget("target") then BL.Redraw() end
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        if Plain(unit) ~= "player" or Plain(spellID) ~= BL.LORE_SPELL then return end
        -- Der Tooltip fuellt sich einen Takt spaeter.
        local function run() if BL.OnLore("target") then BL.Redraw() end end
        if _G.C_Timer and _G.C_Timer.After then _G.C_Timer.After(0.2, run) else run() end
    else
        if BL.ReadTraining() then BL.Redraw() end
    end
end)
BL.events = ev
