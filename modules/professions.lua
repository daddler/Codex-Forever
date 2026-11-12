--------------------------------------------------
-- WeintCodex :: Berufe - Rezepte nach deiner Fertigkeit, Lehrer auf der Karte
--------------------------------------------------
-- Seit 6.14.0.0, aus dem Abgleich mit dem Addon ForeverGuide: je Beruf,
-- was du jetzt lernen kannst, was dir noch Fertigkeit bringt, was neu in
-- Forever ist - und wo der naechste Lehrer steht.
--
-- ZWEI BESTAENDE, NIE VERMISCHT (wie beim Klassenlehrer):
--   * WAS es gibt (Rezepte, Stufen, Reagenzien, Lehrer) steht in
--     data/professions.lua und ist `community` - die Seite sagt das.
--   * WIE WEIT du bist und WAS du kannst, fragt die Seite den Client:
--     Fertigkeit ueber GetProfessions/GetProfessionInfo (sonst die
--     Fertigkeitsliste GetSkillLineInfo), gelernte Rezepte ueber dein
--     Berufsfenster (C_TradeSkillUI, sonst GetTradeSkillRecipeLink) - beim
--     Oeffnen gemerkt, je Charakter. Was der Client nicht beantwortet, wird
--     nicht geraten: ohne Blick ins Berufsfenster heisst "lernbar" "ab
--     deiner Fertigkeit, vielleicht schon gelernt", nie "fehlt".
--
-- Die Schwierigkeit (orange/gelb/gruen/grau) kommt aus den Stufen des
-- Rezepts und deiner Fertigkeit - dieselbe Regel wie im Berufsfenster.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.Professions = {}

local PRO = WeintCodex.Professions
local P   = WeintCodex.ProfessionData
local C   = WeintCodex.Colors

local function Plain(v)
    local K = WeintCodex.UIKit
    if K and K.Plain then return K.Plain(v) end
    return v
end

--------------------------------------------------
-- Bestand
--------------------------------------------------

local byKey, byLine = {}, {}
for _, p in ipairs(P and P.PROFS or {}) do
    byKey[p.key] = p
    if p.line then byLine[p.line] = p.key end
end
PRO.byKey = byKey

-- Die Rezepte eines Berufs, gelesen erst beim ersten Blick (die Zeilen in
-- data/professions.lua kosten als Tabellen ein Vielfaches).
local parsed = {}
local bySpell   -- Zauber -> Beruf, fuer das Auslesen des Berufsfensters
local function Num(s) return s ~= "-" and tonumber(s) or nil end

-- Fertigkeitslinie eines Berufs (171 Alchemie …), fuer P.RANKS.
function PRO.Line(key) return byKey[key] and byKey[key].line end

function PRO.Recipes(key)
    if parsed[key] then return parsed[key] end
    local raw = P and P.RAW and P.RAW[key]
    -- 1.0.5.2: dazu die Rezepte, die nur SkillUp/Naowh kennen
    -- (data/professions_su.lua, P.SU_RAW).
    local extra = P and P.SU_RAW and P.SU_RAW[key]
    if extra then raw = (raw or "") .. "\n" .. extra end
    -- 1.0.5.54: und was nur Naowh Forever kennt (data/professions_nf.lua).
    local nfAdd = P and P.NF_ADD and P.NF_ADD[key]
    if nfAdd then raw = (raw or "") .. "\n" .. nfAdd end
    local out = {}
    for line in (raw or ""):gmatch("[^\n]+") do
        local head, reag, name = line:match("^([^|]*)|([^|]*)|(.*)$")
        if head then
            local f = {}
            for w in head:gmatch("%S+") do f[#f + 1] = w end
            local r = {
                spell = Num(f[1]), item = Num(f[2]), learn = Num(f[3]),
                yellow = Num(f[4]), green = Num(f[5]), grey = Num(f[6]),
                state = f[7], trainer = f[8]:find("t", 1, true) ~= nil, bop = f[8]:find("b", 1, true) ~= nil,
                recipeItem = Num(f[9]), favor = Num(f[10]), name = name, reagents = {}, key = key,
            }
            -- 1.9.0.0: Schwellen aus dem neueren Client-Build (data/professions_su.lua).
            local fix = r.spell and P.SU_THRESH and P.SU_THRESH[r.spell]
            if fix then
                local l, y, g, gr = fix:match("^(%S+) (%d+) (%d+) (%d+)$")
                if l then
                    r.learn = Num(l)
                    r.yellow, r.green, r.grey = tonumber(y), tonumber(g), tonumber(gr)
                end
            end
            -- 1.0.5.54: Naowh Forever belegt eine andere Herkunft (Haendler,
            -- Beute, Quest) - dann ist es kein Lehrerrezept; fehlt die
            -- Lernstufe, nimmt sie die ihre. Gelb/grau bleiben vom Client.
            local nf = r.spell and P.NF_FIX and P.NF_FIX[r.spell]
            if nf then
                if nf.t == 0 then r.trainer = false elseif nf.t == 1 then r.trainer = true end
                if r.learn == nil and nf.l then r.learn = nf.l end
            end
            for id, n in reag:gmatch("(%d+):(%d+)") do
                r.reagents[#r.reagents + 1] = { tonumber(id), tonumber(n) }
            end
            if r.spell then out[#out + 1] = r end
        end
    end
    parsed[key] = out
    return out
end

local function SpellIndex()
    if bySpell then return bySpell end
    bySpell = {}
    for _, p in ipairs(P and P.PROFS or {}) do
        for _, r in ipairs(PRO.Recipes(p.key)) do bySpell[r.spell] = p.key end
    end
    return bySpell
end
PRO.SpellIndex = SpellIndex

-- Name eines Berufs: der Client (Zauber des Berufs), sonst Deutsch aus dem Bestand.
function PRO.ProfName(key)
    local p = byKey[key]
    if not p then return key end
    -- 6.52.3.0 (Beta-Test: "Alchimie ist falsch, muss Alchemie heissen"):
    -- der deutsche Client nennt den Zauber 2259 "Alchimie". Auf Deutsch
    -- gilt der eigene Name; der Zauber nur fuer andere Sprachen.
    if _G.GetLocale and _G.GetLocale() == "deDE" and p.name then return p.name end
    local cs = _G.C_Spell
    if cs and cs.GetSpellName then
        local ok, n = pcall(cs.GetSpellName, p.spell)
        n = ok and Plain(n) or nil
        if type(n) == "string" and n ~= "" then return n end
    end
    return p.name
end

--------------------------------------------------
-- Client: Fertigkeit
--------------------------------------------------

-- { [key] = { rank, max } } und ob der Client ueberhaupt geantwortet hat.
function PRO.Skills()
    local out, answered = {}, false
    local GP, GPI = _G.GetProfessions, _G.GetProfessionInfo
    if type(GP) == "function" and type(GPI) == "function" then
        local res = { pcall(GP) }
        -- 1.0.1.7 (Bericht: Discord zeigt keine Berufe): antwortet
        -- GetProfessions ohne einen einzigen Beruf (Forever direkt nach dem
        -- Einloggen, oder der Client kennt die Funktion nur dem Namen nach),
        -- gilt das NICHT als Antwort - dann fragt die Fertigkeitsliste.
        local any = false
        for i = 2, 7 do if type(Plain(res[i])) == "number" then any = true end end
        if res[1] and any then
            answered = true
            -- Sechs Plaetze (Haupt 1, Haupt 2, Archaeologie, Angeln, Kochen,
            -- Erste Hilfe) MIT Luecken - ipairs braeche an der ersten ab.
            for i = 2, 7 do
                local idx = Plain(res[i])
                if type(idx) == "number" then
                    local ok2, name, _, rank, max, _, _, line = pcall(GPI, idx)
                    rank, max, line = Plain(rank), Plain(max), Plain(line)
                    local key = ok2 and (byLine[line] or PRO.KeyByName(Plain(name))) or nil
                    if key and type(rank) == "number" then out[key] = { rank = rank, max = type(max) == "number" and max or nil } end
                end
            end
        end
    end
    if next(out) == nil and type(_G.GetNumSkillLines) == "function" and type(_G.GetSkillLineInfo) == "function" then
        local ok, n = pcall(_G.GetNumSkillLines)
        n = ok and Plain(n) or nil
        if type(n) == "number" then
            answered = true
            for i = 1, n do
                local ok2, name, isHeader, _, rank, _, _, max = pcall(_G.GetSkillLineInfo, i)
                local key = ok2 and not Plain(isHeader) and PRO.KeyByName(Plain(name)) or nil
                rank, max = Plain(rank), Plain(max)
                if key and type(rank) == "number" then out[key] = { rank = rank, max = type(max) == "number" and max or nil } end
            end
        end
    end
    return out, answered
end

-- Beruf zu einem Namen des Clients: Name des Berufszaubers, sonst Deutsch.
function PRO.KeyByName(name)
    if type(name) ~= "string" then return nil end
    for _, p in ipairs(P and P.PROFS or {}) do
        if name == PRO.ProfName(p.key) or name == p.name then return p.key end
    end
    -- 1.0.1.7: englischer Client ("Tailoring", "First Aid") - der Schluessel
    -- ist der englische Name klein und ohne Leerzeichen.
    local flat = name:lower():gsub("%s+", "")
    for _, p in ipairs(P and P.PROFS or {}) do
        if flat == (p.key:gsub("%-", "")) or flat == (tostring(p.name):lower():gsub("%s+", "")) then return p.key end
    end
    return nil
end

--------------------------------------------------
-- Client: gelernte Rezepte (aus dem Berufsfenster gemerkt)
--------------------------------------------------

local function CharKey()
    local n = _G.UnitName and Plain(_G.UnitName("player"))
    local r = _G.GetRealmName and Plain(_G.GetRealmName())
    if type(n) ~= "string" then return nil end
    return n .. "-" .. (type(r) == "string" and r or "")
end

-- Der Speicher dieses Charakters: { known = { [Zauber] = true }, scanned = { [Beruf] = Zeit } }.
function PRO.Memory()
    local sd = WeintCodex.SavedData
    local who = CharKey()
    if type(sd) ~= "table" or not who then return nil end
    sd.professions = sd.professions or {}
    local m = sd.professions[who]
    if not m then
        m = { known = {}, scanned = {} }
        sd.professions[who] = m
    end
    m.known, m.scanned = m.known or {}, m.scanned or {}
    m.names = m.names or {}
    return m
end

-- 1.0.3.5 (Rezeptsuche im Discord nur auf Englisch): der Name eines
-- gelernten Rezepts so, wie ihn der Client nennt (deutsch im deutschen
-- Spiel). Der Bestand kennt nur die englischen Namen; die Companion
-- meldet diese, wenn hier keiner steht.
function PRO.RememberName(m, id, name)
    if not m or type(id) ~= "number" then return end
    name = Plain(name)
    if type(name) ~= "string" or name == "" then
        local cs = _G.C_Spell
        local ok, n = false, nil
        if type(cs) == "table" and type(cs.GetSpellName) == "function" then ok, n = pcall(cs.GetSpellName, id) end
        name = ok and Plain(n) or nil
    end
    if type(name) == "string" and name ~= "" then m.names[id] = name end
end

-- Namen fuer alles Gelernte nachtragen, das noch keinen hat.
function PRO.FillNames()
    local m = PRO.Memory()
    if not m then return 0 end
    local n = 0
    for id in pairs(m.known) do
        if not m.names[id] then
            PRO.RememberName(m, id)
            if m.names[id] then n = n + 1 end
        end
    end
    return n
end

local function Now() return (_G.time and _G.time()) or 0 end

-- Liest das offene Berufsfenster aus. Liefert, wie viele Rezepte erkannt
-- wurden (fuer die Selbstpruefung und den Prueflauf).
function PRO.Scan()
    local m = PRO.Memory()
    if not m then return 0 end
    local index = SpellIndex()
    local seen, count, ids, matched, via = {}, 0, 0, 0, {}
    local function mark(id, learned, name)
        id = Plain(id)
        ids = ids + 1
        local key = type(id) == "number" and index[id] or nil
        if not key then return end
        matched = matched + 1
        seen[key] = true
        if learned then
            m.known[id] = true
            count = count + 1
            PRO.RememberName(m, id, name)
        else
            m.known[id] = nil
        end
    end
    local ts = _G.C_TradeSkillUI
    if type(ts) == "table" and type(ts.GetAllRecipeIDs) == "function" and type(ts.GetRecipeInfo) == "function" then
        local ok, list = pcall(ts.GetAllRecipeIDs)
        if ok and type(list) == "table" then
            via[#via + 1] = "C_TradeSkillUI"
            for _, id in ipairs(list) do
                local ok2, info = pcall(ts.GetRecipeInfo, id)
                if ok2 and type(info) == "table" then mark(id, Plain(info.learned) == true, info.name) end
            end
        end
    end
    -- Klassische Fenster: die Liste zeigt nur Gelerntes.
    local function classic(numFn, linkFn, name)
        if type(numFn) ~= "function" or type(linkFn) ~= "function" then return end
        local ok, n = pcall(numFn)
        n = ok and Plain(n) or nil
        if type(n) == "number" and n > 0 then via[#via + 1] = name end
        for i = 1, (type(n) == "number" and n or 0) do
            local ok2, link = pcall(linkFn, i)
            link = ok2 and Plain(link) or nil
            local id = type(link) == "string" and tonumber(link:match("enchant:(%d+)") or link:match("spell:(%d+)"))
            if id then mark(id, true) end
        end
    end
    classic(_G.GetNumTradeSkills, _G.GetTradeSkillRecipeLink, "GetTradeSkillRecipeLink")
    classic(_G.GetNumCrafts, _G.GetCraftRecipeLink, "GetCraftRecipeLink")
    for key in pairs(seen) do m.scanned[key] = Now() end
    -- Fuer /wcui pruefen: wie viele Nummern der Client nannte und wie viele
    -- davon im Bestand stehen (passen sie nicht, bleibt "gelernt" unbekannt).
    PRO.lastScan = { count = count, professions = seen, ids = ids, matched = matched, via = via }
    return count
end

-- true: gelernt, false: sicher nicht (das Berufsfenster war offen), nil: weiss nicht.
-- Nach einem Blick ins Berufsfenster gilt der Speicher allein (neu Gelerntes
-- traegt NEW_RECIPE_LEARNED nach); vorher fragt die Seite den Client - der
-- sagt nur "ja" sicher.
function PRO.Learned(r, m)
    m = m or PRO.Memory()
    if m and m.known[r.spell] then return true end
    if m and m.scanned[r.key] then return false end
    local TR = WeintCodex.Trainer
    if TR and TR.Known and TR.Known(r.spell) then return true end
    return nil
end

-- 1.0.0.0: Fertigkeit je Beruf merken (fuer die Companion, Seite „Berufe“):
-- { [key] = { rank, max } } und skillsAt. Nur wenn der Client geantwortet
-- hat - sonst bleibt der alte Stand, nie ein leerer.
function PRO.RememberSkills()
    local skills, answered = PRO.Skills()
    if not answered then return false end
    local m = PRO.Memory()
    if not m then return false end
    local out, n = {}, 0
    for key, s in pairs(skills) do out[key] = { rank = s.rank, max = s.max } n = n + 1 end
    -- 1.0.1.6 (Bericht: "der Bot zeigt nicht, welche Berufe gelernt wurden"):
    -- direkt nach dem Einloggen antwortet der Client oft noch ohne Berufe -
    -- eine leere Antwort ueberschreibt einen gemerkten Stand nicht. Einen
    -- verlernten Beruf traegt SKILL_LINES_CHANGED nach, sobald der Client
    -- einen anderen nennt.
    if n == 0 and type(m.skills) == "table" and next(m.skills) ~= nil then return false end
    m.skills, m.skillsAt = out, Now()
    return true
end

-- Wann das Berufsfenster dieses Berufs zuletzt gelesen wurde (oder nil).
function PRO.ScannedAt(key)
    local m = PRO.Memory()
    return m and m.scanned[key] or nil
end

--------------------------------------------------
-- Einordnen
--------------------------------------------------

-- Farbe eines Rezepts bei dieser Fertigkeit, wie im Berufsfenster.
function PRO.Difficulty(r, skill)
    if type(skill) ~= "number" then return nil end
    if r.learn and skill < r.learn then return "unavailable" end
    if r.yellow and skill < r.yellow then return "orange" end
    if r.green and skill < r.green then return "yellow" end
    if r.grey and skill < r.grey then return "green" end
    return "grey"
end

PRO.SOON = 25   -- "bald": bis 25 Punkte ueber deiner Fertigkeit

PRO.SECTIONS = {
    { key = "now",     label = "Beim Lehrer lernbar",       color = "successBright" },
    { key = "recipe",  label = "Als Rezept lernbar",        color = "successBright" },
    { key = "skillup", label = "Bringt noch Fertigkeit",    color = "infoBright" },
    { key = "soon",    label = "Bald",                      color = "infoBright" },
    { key = "later",   label = "Später",                    color = "textMuted", collapsible = true },
    { key = "unknown", label = "Lernstufe unbekannt",       color = "textMuted", collapsible = true },
    { key = "known",   label = "Gelernt, bringt nichts mehr", color = "textDim", collapsible = true },
}
-- Ohne Fertigkeit (Beruf nicht gelernt oder vom Client nicht genannt):
-- nach den Raengen, wie die Lehrer sie lehren.
PRO.RANKS = {
    { key = "r1", label = "Lehrling · bis 75",   upto = 74 },
    { key = "r2", label = "Geselle · bis 150",   upto = 149 },
    { key = "r3", label = "Experte · bis 225",   upto = 224 },
    { key = "r4", label = "Fachmann · bis 300",  upto = 9999 },
    { key = "unknown", label = "Lernstufe unbekannt" },
}

-- Ordnet die Rezepte eines Berufs. `skill` nil: nach Raengen.
function PRO.Categorize(key, skill)
    local out = { sections = {}, byRank = skill == nil, learnedKnown = PRO.ScannedAt(key) ~= nil }
    local mem = PRO.Memory()
    local defs = skill and PRO.SECTIONS or PRO.RANKS
    for _, s in ipairs(defs) do out.sections[s.key] = {} end
    for _, r in ipairs(PRO.Recipes(key)) do
        local sec
        if not skill then
            if not r.learn then
                sec = "unknown"
            else
                for _, rk in ipairs(PRO.RANKS) do
                    if rk.upto and r.learn <= rk.upto then sec = rk.key break end
                end
            end
        else
            -- Gelernt sein kann nur, was die Fertigkeit schon erlaubt.
            local learned = (not r.learn or r.learn <= skill) and PRO.Learned(r, mem) or nil
            if learned then
                sec = (r.grey and skill < r.grey) and "skillup" or "known"
            elseif not r.learn then
                sec = "unknown"
            elseif r.learn <= skill then
                sec = r.trainer and "now" or "recipe"
            elseif r.learn <= skill + PRO.SOON then
                sec = "soon"
            else
                sec = "later"
            end
        end
        table.insert(out.sections[sec], r)
    end
    return out
end

-- Zahlen fuer Startseite und Detailbereich: { now, recipe, skillup } - nur,
-- wenn das Gelernte bekannt ist (sonst waere "lernbar" geraten).
function PRO.Summary(key, skill)
    if type(skill) ~= "number" then return nil end
    local cat = PRO.Categorize(key, skill)
    return { now = #cat.sections.now, recipe = #cat.sections.recipe, skillup = #cat.sections.skillup,
             soon = #cat.sections.soon, sure = cat.learnedKnown }
end

-- Lehrer eines Berufs fuer eine Fraktion; der deinen naechsten Rang lehrt zuerst.
PRO.RANK_TEXT = { [1] = "Lehrling · bis 75", [2] = "Geselle · bis 150", [3] = "Experte · bis 225", [4] = "Fachmann · bis 300" }
PRO.RANK_CAP = { 75, 150, 225, 300 }
local CAP_RANK = { [75] = 1, [150] = 2, [225] = 3, [300] = 4 }

-- Weltlage eines Kartenpunkts (x, y 0..1): Kontinent und Koordinaten, vom
-- Client gerechnet - nil, wenn er nicht antwortet.
local function WorldPos(map, x, y)
    local cm, V = _G.C_Map, _G.CreateVector2D
    if not (cm and type(cm.GetWorldPosFromMapPos) == "function" and type(V) == "function") then return nil end
    local ok, cont, pos = pcall(cm.GetWorldPosFromMapPos, map, V(x, y))
    cont = ok and Plain(cont) or nil
    if type(cont) ~= "number" or type(pos) ~= "table" then return nil end
    local wx, wy = pos.x, pos.y
    if type(pos.GetXY) == "function" then wx, wy = pos:GetXY() end
    wx, wy = Plain(wx), Plain(wy)
    if type(wx) ~= "number" or type(wy) ~= "number" then return nil end
    return cont, wx, wy
end

-- Karte und Weltlage des Spielers (in Instanzen nur die Karte, oder nichts).
local function PlayerPos()
    local cm = _G.C_Map
    if not (cm and type(cm.GetBestMapForUnit) == "function") then return nil end
    local ok, m = pcall(cm.GetBestMapForUnit, "player")
    m = ok and Plain(m) or nil
    if type(m) ~= "number" then return nil end
    if type(cm.GetPlayerMapPosition) ~= "function" then return m end
    local ok2, p = pcall(cm.GetPlayerMapPosition, m, "player")
    if not ok2 or type(p) ~= "table" then return m end
    local x, y = p.x, p.y
    if type(p.GetXY) == "function" then x, y = p:GetXY() end
    x, y = Plain(x), Plain(y)
    if type(x) ~= "number" or type(y) ~= "number" then return m end
    return m, WorldPos(m, x, y)
end

-- Lehrer eines Berufs fuer eine Fraktion. Wer deinen naechsten Rang lehrt,
-- steht vorn; darin der naechste zuerst (Entfernung vom Client, nur auf
-- demselben Kontinent), ohne Entfernung die eigene Karte, dann der
-- niedrigere Rang - die hohen stehen meist weit draussen (6.14.0.1: ein
-- Fachmann im Hinterland stand vor dem Gesellen in Eisenschmiede).
function PRO.Trainers(key, faction, max)
    local need = max and CAP_RANK[max] and (CAP_RANK[max] + 1) or nil
    local here, pc, px, py = PlayerPos()
    local out = {}
    local list = {}
    for _, t in ipairs(P and P.TRAINERS and P.TRAINERS[key] or {}) do list[#list + 1] = t end
    -- 1.0.5.54: Lehrer, die nur Naowh Forever kennt - ohne bekannten Rang.
    for _, t in ipairs(P and P.NF_TRAINERS and P.NF_TRAINERS[key] or {}) do
        list[#list + 1] = { t[1], t[2], t[4], t[5], t[6], t[3] or nil, nil }
    end
    for _, t in ipairs(list) do
        local fr = t[6]
        if not faction or not fr or fr == faction then
            local dist
            if pc and t[3] then
                local c, wx, wy = WorldPos(t[3], t[4] / 100, t[5] / 100)
                if c == pc then dist = math.sqrt((wx - px) ^ 2 + (wy - py) ^ 2) end
            end
            out[#out + 1] = { id = t[1], name = t[2], map = t[3], x = t[4], y = t[5], faction = fr, rank = t[7],
                              next = need ~= nil and t[7] ~= nil and t[7] >= need, here = here ~= nil and t[3] == here, dist = dist }
        end
    end
    table.sort(out, function(a, b)
        if a.next ~= b.next then return a.next end
        if (a.dist ~= nil) ~= (b.dist ~= nil) then return a.dist ~= nil end
        if a.dist and a.dist ~= b.dist then return a.dist < b.dist end
        if a.here ~= b.here then return a.here end
        if a.rank ~= b.rank then return (a.rank or 99) < (b.rank or 99) end
        return a.name < b.name
    end)
    return out, need
end

--------------------------------------------------
-- Namen
--------------------------------------------------

local pending = {}
PRO.pending = pending

function PRO.RecipeName(r)
    local cs = _G.C_Spell
    if cs and cs.GetSpellName then
        local ok, n = pcall(cs.GetSpellName, r.spell)
        n = ok and Plain(n) or nil
        if type(n) == "string" and n ~= "" then return n end
        pending[r.spell] = true
        if cs.RequestLoadSpellData then pcall(cs.RequestLoadSpellData, r.spell) end
    end
    return r.name
end

function PRO.ItemName(id)
    local ci = _G.C_Item
    local info = (ci and ci.GetItemInfo) or _G.GetItemInfo
    if info then
        local ok, n = pcall(info, id)
        n = ok and Plain(n) or nil
        if type(n) == "string" and n ~= "" then return n end
        if ci and ci.RequestLoadItemDataByID then pcall(ci.RequestLoadItemDataByID, id) end
    end
    return (P and P.NAMES and P.NAMES[id]) or ("Gegenstand " .. id)
end

local function Icon(r)
    local ci = _G.C_Item
    if r.item and ci and ci.GetItemIconByID then
        local ok, t = pcall(ci.GetItemIconByID, r.item)
        t = ok and Plain(t) or nil
        if t then return t end
    end
    local cs = _G.C_Spell
    if cs and cs.GetSpellTexture then
        local ok, t = pcall(cs.GetSpellTexture, r.spell)
        t = ok and Plain(t) or nil
        if t then return t end
    end
    return nil
end

-- "75 · 95 · 115 · 135" in den Farben des Berufsfensters.
function PRO.StepsText(r)
    local parts = {}
    local function add(v, tone) if v then parts[#parts + 1] = WeintCodex.ColorText(tone, tostring(v)) end end
    add(r.learn, "skillOrange")
    add(r.yellow, "skillYellow")
    add(r.green, "skillGreen")
    add(r.grey, "skillGrey")
    return table.concat(parts, " ")
end

-- Was die vier Zahlen einer Zeile heissen, in ihren Farben.
function PRO.Legend()
    local CT = WeintCodex.ColorText
    return "Fertigkeit: " .. CT("skillOrange", "lernbar ab") .. " · " .. CT("skillYellow", "gelb ab")
        .. " · " .. CT("skillGreen", "grün ab") .. " · " .. CT("skillGrey", "grau ab")
end

--------------------------------------------------
-- Seite
--------------------------------------------------
-- Links die Berufe (deine zuerst), in der Mitte die Rezepte nach Faechern,
-- rechts die Lehrer. Rezepte und Lehrer rollen; alles andere steht still.
-- Zeilen werden wiederverwendet (500 Rezepte der Lederverarbeitung waeren
-- sonst bei jedem Aufschlagen 500 neue Rahmen).

local page
local selected
local showAll = false
local ROW_H, HEAD_H = 26, 30
local rowPool, headPool, notePool, trainerPool, bookPool = {}, {}, {}, {}, {}
local used = { row = 0, head = 0, note = 0, trainer = 0, book = 0 }

local function ResetPools()
    for _, pool in ipairs({ rowPool, headPool, notePool, trainerPool, bookPool }) do
        for _, f in ipairs(pool) do f:Hide() end
    end
    used.row, used.head, used.note, used.trainer, used.book = 0, 0, 0, 0, 0
end

local function BuildPage()
    if page then return page end
    local cp = WeintCodex.ContentPanel
    local f = CreateFrame("Frame", nil, cp)
    f:SetAllPoints(cp)
    local PAD_X, PAD_Y, GAP = WeintCodex.Metrics.PAD_X, WeintCodex.Metrics.PAD_Y, WeintCodex.Metrics.GAP
    f.Head = WeintCodex.PageHead(f, {
        eyebrow = "Leveln",
        title   = "Berufe",
        sub     = "Was du jetzt lernen kannst, was dir noch Fertigkeit bringt – und wo der nächste Lehrer steht.",
        height  = 84,
    })
    local rc = WeintCodex.CreateSurface(f, { tone = "plain", radius = 14, backdrop = "bgDark" })
    -- 6.129.0.0: Umschalter Rezepte/Werkzeuge (modules/proftools.lua) unter dem Kopf.
    local PT = WeintCodex.ProfTools
    if PT then
        PT.AttachBar(f, "rezepte")
        rc:SetPoint("TOPLEFT", f.BarHolder, "BOTTOMLEFT", 0, 0)
    else
        rc:SetPoint("TOPLEFT", f, "TOPLEFT", PAD_X, -(PAD_Y + 84))
    end
    rc:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", PAD_X, PAD_Y)
    rc:SetWidth(460)
    f.RecipeCard = rc
    f.RecipeTitle = WeintCodex.Label(rc, "Rezepte", { size = 14, color = "textBright", font = WeintCodex.Fonts.sansSemi })
    f.RecipeTitle:SetPoint("TOPLEFT", rc, "TOPLEFT", 20, -16)
    f.AllButton = WeintCodex.CreateButton(rc, { kind = "ghost", text = "Alle zeigen", height = 24,
        size = 11, padding = 20, radius = 0, onClick = function()
            showAll = not showAll
            PRO.Show()
        end })
    f.AllButton:SetPoint("TOPRIGHT", rc, "TOPRIGHT", -16, -12)
    -- 1.0.5.63 (Wunsch: "eine Rubrik, in der steht, wo ich die
    -- Lagerfeuerverbesserungen finde"): alle Berufe auf einer Seite. Als
    -- Knopf in der Karte - die Spalte der Berufe ist voll (nachgerechnet).
    f.CampButton = WeintCodex.CreateButton(rc, { kind = "ghost", text = "Lagerfeuer", height = 24,
        size = 11, padding = 20, radius = 0, onClick = function()
            PRO.campAll = not PRO.campAll
            if PRO.campAll and f.SearchEdit then f.SearchEdit:SetText("") end
            PRO.query = PRO.campAll and "" or PRO.query
            PRO.Show()
        end })
    f.CampButton:SetPoint("LEFT", f.RecipeTitle, "RIGHT", 14, 0)
    -- 1.0.5.60 (Wunsch: "Rezeptsuche fuer alle Berufe und wo sie zu
    -- bekommen sind"): Suche ueber alle Berufe, jeder Treffer mit Beruf und
    -- Herkunft; Klick zeigt das Rezept im Detail.
    local sb = CreateFrame("Frame", nil, rc)
    sb:SetHeight(24)
    -- 1.0.5.61 (Bild: ueberlappte "Alle zeigen"): eigene Zeile unter dem Titel.
    sb:SetPoint("TOPLEFT", rc, "TOPLEFT", 20, -44)
    sb:SetPoint("TOPRIGHT", rc, "TOPRIGHT", -20, -44)
    local sbg = sb:CreateTexture(nil, "BACKGROUND")
    sbg:SetAllPoints(sb)
    sbg:SetColorTexture(C.surface2[1], C.surface2[2], C.surface2[3], 1)
    local eb = CreateFrame("EditBox", nil, sb)
    eb:SetPoint("TOPLEFT", sb, "TOPLEFT", 8, 0)
    eb:SetPoint("BOTTOMRIGHT", sb, "BOTTOMRIGHT", -24, 0)
    eb:SetAutoFocus(false)
    eb:SetMaxLetters(40)
    eb:SetFont(WeintCodex.Fonts.sans, 12, "")
    eb:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3])
    eb.hint = WeintCodex.Label(sb, "Rezept suchen – alle Berufe", { size = 12, color = "textDim" })
    eb.hint:SetPoint("LEFT", sb, "LEFT", 10, 0)
    local clear = CreateFrame("Button", nil, sb)
    clear:SetSize(22, 22)
    clear:SetPoint("RIGHT", sb, "RIGHT", -2, 0)
    clear.x = WeintCodex.Label(clear, "\195\151", { size = 14, color = "textMuted" })
    clear.x:SetPoint("CENTER", clear, "CENTER", 0, 1)
    clear:SetScript("OnClick", function() eb:SetText("") eb:ClearFocus() end)
    clear:Hide()
    eb:SetScript("OnTextChanged", function(self)
        local t = Plain(self:GetText()) or ""
        self.hint:SetShown(t == "")
        clear:SetShown(t ~= "")
        if t ~= PRO.query then PRO.query = t PRO.Redraw() end
    end)
    eb:SetScript("OnEscapePressed", function(self) self:SetText("") self:ClearFocus() end)
    eb:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    sb:EnableMouse(true)
    sb:SetScript("OnMouseDown", function() eb:SetFocus() end)
    f.SearchBox, f.SearchEdit = sb, eb
    f.RecipeScroll, f.RecipeBody = WeintCodex.CreateScrollArea(rc, 20, -78, 420, 300, true)

    local tc = WeintCodex.CreateSurface(f, { tone = "plain", radius = 14, backdrop = "bgDark" })
    tc:SetPoint("TOPLEFT",     rc, "TOPRIGHT", GAP, 0)
    tc:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -PAD_X, PAD_Y)
    f.TrainerCard = tc
    local tt = WeintCodex.Label(tc, "Lehrer", { size = 14, color = "textBright", font = WeintCodex.Fonts.sansSemi })
    tt:SetPoint("TOPLEFT", tc, "TOPLEFT", 20, -16)
    f.TrainerScroll, f.TrainerBody = WeintCodex.CreateScrollArea(tc, 20, -46, 260, 260, true)

    f:SetScript("OnSizeChanged", function(self, width)
        width = Plain(width)
        if self:IsShown() and type(width) == "number" and type(self.drawnWidth) == "number"
           and math.abs(width - self.drawnWidth) > 2 then
            PRO.Redraw()
        end
    end)
    page = f
    return f
end

-- Haendler eines Rezepts (6.66.0.0, Beta-Test: "die Verlinkung von allen
-- Rezepten, die gekauft werden koennen, und wo"). Nur Haendler der eigenen
-- Fraktion oder beider; ohne Fraktion des Spielers alle. Die Liste der
-- Haendler ist der Stand aus Classic (P.VENDOR_SOURCE) und sagt das.
-- 1.0.5.54: Herkunft je Rezept aus dem Abgleich mit Naowh Forever
-- (data/professions_nf.lua, P.NF_SRC) - gelesen erst, wenn gebraucht.
local nfCache = {}
function PRO.Money(c)
    c = tonumber(c)
    if not c then return nil end
    if _G.GetCoinTextureString then
        local ok, t = pcall(_G.GetCoinTextureString, c)
        if ok and type(t) == "string" and t ~= "" then return t end
    end
    local g, sv, k = math.floor(c / 10000), math.floor(c / 100) % 100, c % 100
    local parts = {}
    if g > 0 then parts[#parts + 1] = g .. " G" end
    if sv > 0 then parts[#parts + 1] = sv .. " S" end
    if k > 0 or #parts == 0 then parts[#parts + 1] = k .. " K" end
    return table.concat(parts, " ")
end
-- Reagenz beim Haendler zu kaufen? { price = Kupfer oder nil, names = {...} }
function PRO.ReagentVendor(item)
    local v = P and P.NF_REAGENT_VENDORS and P.NF_REAGENT_VENDORS[item]
    if not v then return nil end
    local names = {}
    for i = 2, #v do names[#names + 1] = v[i] end
    return { price = v[1] or nil, names = names }
end

-- Questname vom Client (deutsch), sonst der englische aus dem Bestand.
function PRO.QuestName(id, fallback)
    local q = id and _G.C_QuestLog and _G.C_QuestLog.GetTitleForQuestID
    if q then
        local ok, t = pcall(q, id)
        t = ok and Plain(t) or nil
        if type(t) == "string" and t ~= "" then return t end
    end
    return fallback or (id and ("Quest " .. id)) or "?"
end

function PRO.NFSources(spell)
    if not spell then return nil end
    if nfCache[spell] ~= nil then return nfCache[spell] or nil end
    local raw = P and P.NF_SRC and P.NF_SRC[spell]
    if type(raw) ~= "string" then nfCache[spell] = false return nil end
    local out = { vendors = {}, sellers = {}, drops = {}, bosses = {}, quests = {} }
    for line in raw:gmatch("[^\n]+") do
        local f = {}
        for part in (line .. "\t"):gmatch("([^\t]*)\t") do f[#f + 1] = part end
        local k = f[1]
        local FAC = { A = "Alliance", H = "Horde" }
        if k == "v" then
            out.vendors[#out.vendors + 1] = { f[3], tonumber(f[5]), tonumber(f[6]), tonumber(f[7]), FAC[f[4]],
                price = tonumber(f[8]), npc = tonumber(f[2]) }
        elseif k == "s" then out.sellers[#out.sellers + 1] = { name = f[2], faction = FAC[f[3]], price = tonumber(f[4]) }
        elseif k == "d" then out.drops[#out.drops + 1] = { name = f[2], npc = tonumber(f[3]), min = tonumber(f[4]),
                max = tonumber(f[5]), chance = tonumber(f[6]) }
        elseif k == "b" then out.bosses[#out.bosses + 1] = f[2]
        elseif k == "w" then out.world = tonumber(f[2]) or true
        elseif k == "m" then out.mobs = tonumber(f[2])
        elseif k == "c" then out.chests = true
        elseif k == "q" then out.quests[#out.quests + 1] = { id = tonumber(f[2]), name = f[3], level = tonumber(f[4]),
                side = FAC[f[5]], giver = (f[7] and f[7] ~= "") and { f[7], tonumber(f[9]), tonumber(f[10]), tonumber(f[11]), FAC[f[8]] } or nil }
        elseif k == "r" then out.rep = f[2]
        elseif k == "k" then out.cost = tonumber(f[2]) end
    end
    nfCache[spell] = out
    return out
end

function PRO.Vendors(r)
    local out = {}
    -- 1.0.5.54: zuerst die Haendler aus dem Abgleich mit Naowh Forever, mit Preis.
    local nf = r and PRO.NFSources(r.spell)
    if nf and #nf.vendors > 0 then
        local mine = _G.UnitFactionGroup and Plain(_G.UnitFactionGroup("player"))
        if mine ~= "Alliance" and mine ~= "Horde" then mine = nil end
        for _, v in ipairs(nf.vendors) do
            if not mine or not v[5] or v[5] == mine then out[#out + 1] = v end
        end
        if #out > 0 then return out end
    end
    if not (r and r.recipeItem) then return out end
    -- 1.0.5.50: zuerst die Haendler aus der Datenbank fuer Forever
    -- (data/recipe_sources.lua), erst ohne sie die aus Classic.
    local src = PRO.ItemSources(r.recipeItem)
    if src and #src.vendors > 0 then return src.vendors end
    if not P.VENDORS then return out end
    local mine = _G.UnitFactionGroup and _G.UnitFactionGroup("player")
    if type(mine) ~= "string" then mine = nil end
    for _, npc in ipairs(P.VENDORS[r.recipeItem] or {}) do
        local v = P.VENDOR_NPC and P.VENDOR_NPC[npc]
        if v and (not mine or not v[5] or v[5] == mine) then out[#out + 1] = v end
    end
    out.classic = true
    return out
end

-- 1.0.5.50 (Bericht: "Herkunft der Rezepte bzw. die Buecher, womit man den
-- Skill erlernen kann, fuer Erste Hilfe etc. fehlen"): wer einen Rezept-
-- oder Rangbuch-Gegenstand verkauft, fallen laesst oder als Belohnung gibt
-- - aus data/recipe_sources.lua (Datenbank der Community fuer Forever).
-- Haendler nur der eigenen Fraktion (oder beider); ohne Fraktion alle.
-- { vendors = { {Name, Karte, x, y, Fraktion} }, drops = {Name}, objects, quests, world }
local srcCache = {}
local FAC = { A = "Alliance", H = "Horde" }
local function SplitList(t)
    local out = {}
    for n in (t or ""):gmatch("%d+") do out[#out + 1] = tonumber(n) end
    return out
end
-- Deutsche Namen neuer Forever-Gegner, die der Bestand nur englisch kennt
-- (1.0.5.62, Liste der Baupläne vom Spieler, `community`).
PRO.NPC_DE = { [260325] = "Schemenzahn", [260326] = "Reliktwächter", [246017] = "Instabile Schildwache" }
local function Npc(id)
    local RS = WeintCodex.RecipeSources
    local raw = RS and RS.n and RS.n[id]
    if type(raw) ~= "string" then return nil end
    local name, map, x, y, fac = raw:match("^([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t?([^\t]*)")
    return { PRO.NPC_DE[id] or name, tonumber(map), tonumber(x), tonumber(y), FAC[fac] }, fac
end
function PRO.ItemSources(item)
    if srcCache[item] ~= nil then return srcCache[item] or nil end
    local RS = WeintCodex.RecipeSources
    local raw = RS and RS.r and RS.r[item]
    if type(raw) ~= "string" then srcCache[item] = false return nil end
    local f = {}
    for part in (raw .. "\t"):gmatch("([^\t]*)\t") do f[#f + 1] = part end
    local mine = _G.UnitFactionGroup and Plain(_G.UnitFactionGroup("player"))
    if mine ~= "Alliance" and mine ~= "Horde" then mine = nil end
    local out = { vendors = {}, drops = {}, objects = {}, quests = {}, world = f[5] == "w" }
    for _, id in ipairs(SplitList(f[1])) do
        local v, fac = Npc(id)
        if v and (not mine or fac == "" or fac == "AH" or v[5] == mine) then out.vendors[#out.vendors + 1] = v end
    end
    for _, id in ipairs(SplitList(f[2])) do
        local v = Npc(id)
        if v then out.drops[#out.drops + 1] = v end
    end
    for _, id in ipairs(SplitList(f[3])) do
        local n = RS.o and RS.o[id]
        if n then out.objects[#out.objects + 1] = n end
    end
    for _, id in ipairs(SplitList(f[4])) do
        local n = RS.q and RS.q[id]
        if n then out.quests[#out.quests + 1] = n end
    end
    srcCache[item] = out
    return out
end

-- Die anderen Wege als Text, oder nil.
function PRO.OtherSources(item, spell)
    local nf = spell and PRO.NFSources(spell)
    if nf then
        local parts = {}
        for _, q in ipairs(nf.quests) do
            if not q.side or not _G.UnitFactionGroup or q.side == Plain(_G.UnitFactionGroup("player")) then
                parts[#parts + 1] = "Quest „" .. PRO.QuestName(q.id, q.name) .. "“" .. (q.giver and (" bei " .. q.giver[1]) or "")
            end
        end
        if #nf.drops > 0 then
            local names = {}
            for i, d in ipairs(nf.drops) do
                if i > 3 then break end
                names[#names + 1] = d.name .. (d.chance and string.format(" (%.1f %%)", d.chance) or "")
            end
            parts[#parts + 1] = "Beute von " .. table.concat(names, ", ") .. ((nf.mobs and nf.mobs > #nf.drops) and (" und " .. (nf.mobs - math.min(3, #nf.drops)) .. " weiteren") or "")
        elseif #nf.bosses > 0 then
            parts[#parts + 1] = "Beute von " .. table.concat(nf.bosses, ", ")
        elseif nf.world then
            parts[#parts + 1] = "Weltbeute" .. (type(nf.world) == "number" and nf.world > 1 and (" (" .. nf.world .. " Gegner)") or "")
        end
        if nf.chests then parts[#parts + 1] = "auch aus Truhen" end
        if nf.rep then parts[#parts + 1] = "Ruf: " .. nf.rep end
        for _, sl in ipairs(nf.sellers) do
            parts[#parts + 1] = "begrenzt bei " .. sl.name .. (sl.price and (" (" .. PRO.Money(sl.price) .. ")") or "")
        end
        if #parts > 0 then return table.concat(parts, " · ") end
    end
    local src = item and PRO.ItemSources(item)
    if not src then return nil end
    local parts = {}
    if #src.quests > 0 then parts[#parts + 1] = "Belohnung der Quest „" .. table.concat(src.quests, "“, „") .. "“" end
    if #src.drops > 0 then
        local names = {}
        for _, d in ipairs(src.drops) do names[#names + 1] = d[1] end
        parts[#parts + 1] = "Beute von " .. table.concat(names, ", ")
    elseif src.world then
        parts[#parts + 1] = "Weltbeute (viele Gegner)"
    end
    if #src.objects > 0 then parts[#parts + 1] = "aus " .. table.concat(src.objects, ", ") end
    if #parts == 0 then return nil end
    return table.concat(parts, " · ")
end

-- Pfeil zum ersten Haendler (Kartennummer und Lage aus dem Bestand).
function PRO.GuideToVendor(r)
    local QA = WeintCodex.UIQuestArrow
    local v = PRO.Vendors(r)[1]
    if not (v and v[2] and v[3] and v[4] and QA and QA.SetCustom) then return false end
    QA.SetCustom({ map = v[2], x = v[3] / 100, y = v[4] / 100,
        title = "Rezept bei " .. v[1] })
    return true
end

local function Tooltip(row)
    local gt = _G.GameTooltip
    local r = row.recipe
    if not (gt and r) then return end
    gt:SetOwner(row, "ANCHOR_RIGHT")
    local tb = C.textBright
    gt:SetText(PRO.RecipeName(r), tb[1], tb[2], tb[3])
    local function line(text, tone)
        local c = C[tone or "textNormal"] or C.textNormal
        gt:AddLine(text, c[1], c[2], c[3], true)
    end
    if r.state == "n" then line("Neu in Forever", "infoBright")
    elseif r.state == "c" then line("In Forever geändert", "textMuted") end
    local steps = PRO.StepsText(r)
    if steps ~= "" then line("Fertigkeit: " .. steps, "textMuted") end
    if #r.reagents > 0 then
        line("Reagenzien:", "textMuted")
        for _, e in ipairs(r.reagents) do
            local rv = PRO.ReagentVendor(e[1])
            line("  " .. e[2] .. "× " .. PRO.ItemName(e[1]) .. (rv and ("  – beim Händler" .. (rv.price and (", " .. PRO.Money(rv.price)) or "")) or ""), "textNormal")
        end
    end
    if r.trainer then
        local _, origin = PRO.Origin(r)
        line("Herkunft: " .. origin, "textMuted")
    elseif r.recipeItem or PRO.NFSources(r.spell) then
        if r.recipeItem then
            line("Herkunft: Rezept „" .. PRO.ItemName(r.recipeItem) .. "“" .. (r.bop and " (beim Aufheben gebunden)" or ""), "textMuted")
        end
        local QM = WeintCodex.QuestMap
        local vs = PRO.Vendors(r)
        for _, v in ipairs(vs) do
            local zone = v[2] and QM and QM.MapName(v[2])
            line("  Händler: " .. v[1] .. (zone and (", " .. zone) or "")
                .. (v[3] and string.format(" (%.0f, %.0f)", v[3], v[4]) or "") .. (v.price and (" – " .. PRO.Money(v.price)) or "")
                .. (vs.classic and " – aus Classic" or ""), "textDim")
        end
        local _, origin = PRO.Origin(r)
        line(origin, #vs > 0 and "goldBright" or "textMuted")
        local other = #vs > 0 and PRO.OtherSources(r.recipeItem, r.spell)
        if other then line("Auch: " .. other, "textDim") end
        line("Klick: Details rechts", "accent")
        if r.favor then line("  Für " .. r.favor .. " Händlergunst", "textDim") end
    else
        line("Herkunft unbekannt", "textDim")
    end
    gt:Show()
end

local function RecipeRow(body, y, w, r, opts)
    used.row = used.row + 1
    local row = rowPool[used.row]
    if not row then
        row = CreateFrame("Button", nil, body)
        row:SetHeight(ROW_H)
        row.sel = row:CreateTexture(nil, "BACKGROUND")
        row.sel:SetAllPoints(row)
        row.sel:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.14)
        row.sel:Hide()
        local hl = row:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints(row)
        hl:SetColorTexture(C.textBright[1], C.textBright[2], C.textBright[3], 0.05)
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(20, 20)
        row.icon:SetPoint("LEFT", row, "LEFT", 2, 0)
        row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        row.steps = WeintCodex.Label(row, "", { size = 10, justify = "RIGHT", font = WeintCodex.Fonts.mono })
        row.steps:SetPoint("RIGHT", row, "RIGHT", -4, 0)
        row.tag = WeintCodex.Label(row, "", { size = 10, justify = "RIGHT" })
        row.tag:SetPoint("RIGHT", row.steps, "LEFT", -6, 0)
        row.name = WeintCodex.Label(row, "", { size = 12, font = WeintCodex.Fonts.sansMedium })
        row.name:SetPoint("LEFT", row.icon, "RIGHT", 8, 0)
        row.name:SetPoint("RIGHT", row.tag, "LEFT", -8, 0)
        row.name:SetWordWrap(false)
        row:SetScript("OnEnter", Tooltip)
        row:SetScript("OnLeave", function() if _G.GameTooltip then _G.GameTooltip:Hide() end end)
        row:SetScript("OnClick", function(self)
            if not (_G.IsModifiedClick and _G.IsModifiedClick("CHATLINK") and _G.ChatEdit_InsertLink) then
                PRO.SelectRecipe(self.recipe)
                return
            end
            local cs = _G.C_Spell
            local link = cs and cs.GetSpellLink and cs.GetSpellLink(self.recipe.spell)
            if type(link) == "string" then _G.ChatEdit_InsertLink(link) end
        end)
        rowPool[used.row] = row
    end
    row:SetParent(body)
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", body, "TOPLEFT", 0, y)
    row:SetWidth(w)
    row.recipe = r
    row.sel:SetShown(PRO.selRecipe ~= nil and PRO.selRecipe == r)
    local icon = Icon(r)
    if icon then row.icon:SetTexture(icon) else row.icon:SetColorTexture(C.surface3[1], C.surface3[2], C.surface3[3], 1) end
    if row.icon.SetDesaturated then row.icon:SetDesaturated(opts.dim and true or false) end
    row.name:SetText(PRO.RecipeName(r))
    local tone = opts.tone or (opts.dim and "textDim" or "textNormal")
    local c = C[tone] or C.textNormal
    row.name:SetTextColor(c[1], c[2], c[3])
    row.steps:SetText(PRO.StepsText(r))
    if r.state == "n" then
        row.tag:SetText("Neu")
        row.tag:SetTextColor(C.infoBright[1], C.infoBright[2], C.infoBright[3])
    elseif r.state == "c" then
        row.tag:SetText("Geändert")
        row.tag:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3])
    elseif not r.trainer and #PRO.Vendors(r) > 0 then
        row.tag:SetText("Händler")
        row.tag:SetTextColor(C.goldBright[1], C.goldBright[2], C.goldBright[3])
    else
        row.tag:SetText("")
    end
    row:Show()
    return y - ROW_H
end

-- Ein Absatz wie WeintCodex.Paragraph, aber wiederverwendet.
local function Note(body, y, w, note)
    used.note = used.note + 1
    local fs = notePool[used.note]
    if not fs then
        fs = WeintCodex.Paragraph(body, "", { size = 11, color = "textDim" })
        notePool[used.note] = fs
    end
    fs:SetParent(body)
    fs:ClearAllPoints()
    fs:SetPoint("TOPLEFT", body, "TOPLEFT", 0, y)
    fs:SetWidth(w)
    fs:SetText(note)
    -- Hoehe geschaetzt wie in Paragraph (Groesse 11, Abstand 3), nie vom Client gelesen.
    local h = WeintCodex.EstimateLines(note, math.floor(w / (11 * 0.60))) * (11 + 3)
    fs:SetHeight(h)
    fs:Show()
    return y - h - 6
end

local function SectionHead(body, y, w, label, color, count, note)
    used.head = used.head + 1
    local head = headPool[used.head]
    if not head then
        head = CreateFrame("Frame", nil, body)
        head:SetHeight(HEAD_H)
        head.eb = WeintCodex.Eyebrow(head, "", { size = 10 })
        head.eb:SetPoint("BOTTOMLEFT", head, "BOTTOMLEFT", 0, 8)
        head.right = WeintCodex.Label(head, "", { size = 11, color = "textDim", justify = "RIGHT" })
        head.right:SetPoint("BOTTOMRIGHT", head, "BOTTOMRIGHT", -4, 7)
        local line = head:CreateTexture(nil, "ARTWORK")
        line:SetHeight(1)
        line:SetPoint("BOTTOMLEFT", head, "BOTTOMLEFT", 0, 2)
        line:SetPoint("BOTTOMRIGHT", head, "BOTTOMRIGHT", 0, 2)
        line:SetColorTexture(C.border[1], C.border[2], C.border[3], 1)
        headPool[used.head] = head
    end
    head:SetParent(body)
    head:ClearAllPoints()
    head:SetPoint("TOPLEFT", body, "TOPLEFT", 0, y)
    head:SetWidth(w)
    head.eb:SetText(WeintCodex.Spaced and WeintCodex.Spaced(WeintCodex.Upper(label)) or label)
    local c = C[color] or C.textMuted
    head.eb:SetTextColor(c[1], c[2], c[3])
    -- 1.0.5.51: ohne Zahl kein Text - sonst stand ein alter "… Rezepte"
    -- aus dem Vorrat unter "Ränge ohne Lehrer" (Bild vom Spieler).
    head.right:SetText(type(count) ~= "number" and "" or count == 1 and "1 Rezept" or (count .. " Rezepte"))
    head:Show()
    y = y - HEAD_H - 4
    if note then y = Note(body, y, w, note) end
    return y
end

local TONE = { orange = "skillOrange", yellow = "skillYellow", green = "skillGreen", grey = "textDim" }

-- Hinweise je Fach; der erste nur, solange das Gelernte unbekannt ist.
local NOTE_UNSURE = "Ob du ein Rezept schon kannst, weiß WeintCodex erst, wenn du einmal dein Berufsfenster öffnest – bis dahin heißt „lernbar“: ab deiner Fertigkeit."
PRO.NOTE_UNSURE = NOTE_UNSURE

-- Rezeptsuche (1.0.5.60): ueber alle Berufe, Name im Spiel (deutsch),
-- Name im Bestand und Name des hergestellten Gegenstands. Hoechstens
-- PRO.SEARCH_MAX Treffer - mehr liest keiner, und jede Zeile kostet.
PRO.query = ""
PRO.SEARCH_MAX = 40
local function Fold(t) return (type(t) == "string" and t:lower()) or "" end
function PRO.Search(query)
    local q = Fold(query):gsub("^%s+", ""):gsub("%s+$", "")
    local out = {}
    if #q < 2 then return out, q end
    for _, p in ipairs(P and P.PROFS or {}) do
        for _, r in ipairs(PRO.Recipes(p.key)) do
            if Fold(PRO.RecipeName(r)):find(q, 1, true) or Fold(r.name):find(q, 1, true)
               or (r.item and P.NAMES and Fold(P.NAMES[r.item]):find(q, 1, true)) then
                out[#out + 1] = r
                if #out >= PRO.SEARCH_MAX then return out, q, true end
            end
        end
    end
    return out, q
end

local function DrawSearch(body, w)
    local list, q, more = PRO.Search(PRO.query)
    local y = 0
    if #list == 0 then
        y = SectionHead(body, y, w, "Suche", "textMuted", 0,
            #q < 2 and "Mindestens zwei Buchstaben." or "Kein Rezept heißt so – in keinem Beruf.")
        body:SetHeight(math.max(1, -y))
        return
    end
    y = SectionHead(body, y, w, "Treffer in allen Berufen", "accent", #list,
        more and ("Die ersten " .. PRO.SEARCH_MAX .. " – genauer suchen für mehr.") or nil)
    for _, r in ipairs(list) do
        y = RecipeRow(body, y, w, r, {})
        local _, origin = PRO.Origin(r)
        y = Note(body, y + 4, w, PRO.ProfName(r.key) .. " · " .. origin)
    end
    body:SetHeight(math.max(1, -y))
end
PRO.DrawSearch = DrawSearch

-- Fuers Lagerfeuer (1.0.5.61, Wunsch: "Goodies am Lagerfeuer, 3 an der
-- Zahl, verbessern mit hoeherer Fertigkeit - wo man das findet und wie man
-- es verbessert"). Erkannt an der Nummer des hergestellten Gegenstands:
-- die Lagergegenstaende von Forever liegen in 279930-279999 (Bestand
-- data/professions.lua, gezaehlt: je Beruf drei Stufen 20/140/300, beim
-- Kochen auch die drei Lagerfeuer). Stufe = Rang nach Lernstufe.
PRO.CAMP_FROM, PRO.CAMP_TO = 279930, 279999
function PRO.IsCamp(r) return r and r.item and r.item >= PRO.CAMP_FROM and r.item <= PRO.CAMP_TO or false end
function PRO.CampItems(key)
    local out = {}
    for _, r in ipairs(PRO.Recipes(key)) do if PRO.IsCamp(r) then out[#out + 1] = r end end
    table.sort(out, function(a, b) return (a.learn or 0) < (b.learn or 0) end)
    return out
end
-- Was zum Bauen fehlt: Zutaten, die kein Rezept herstellt und die der
-- Bestand nicht kennt (Nummern ab 272000 = neu in Forever) - ehrlich
-- "Herkunft nicht im Bestand". `step` bleibt fuer spaeter ungenutzt.
function PRO.CampLine(r, step)
    local _, origin = PRO.Origin(r)
    local t = "ab Fertigkeit " .. (r.learn or "?") .. " · " .. origin
    for _, rg in ipairs(r.reagents) do
        if rg[1] >= 272000 and P.NAMES and P.NAMES[rg[1]] then
            t = t .. " · braucht " .. PRO.ItemName(rg[1]) .. " (Herkunft nicht im Bestand)"
        end
    end
    return t
end
local function DrawCamp(body, y, w, key)
    local list = PRO.CampItems(key)
    if #list == 0 then return y end
    y = SectionHead(body, y, w, "Fürs Lagerfeuer", "goldBright", #list,
        "Am Lagerfeuer aufstellbar. Verbessert wird nicht das Aufgestellte: die stärkere Fassung ist ein eigenes Rezept ab mehr Fertigkeit – meist als Rezept zu finden.")
    for i, r in ipairs(list) do
        y = RecipeRow(body, y, w, r, {})
        y = Note(body, y + 4, w, PRO.CampLine(r, i))
    end
    return y - 10
end
PRO.DrawCamp = DrawCamp
-- Alle Berufe: je Beruf seine Lagergegenstaende, die eigenen Berufe zuerst.
local function DrawCampAll(body, w, skills)
    local y = Note(body, 0, w, "Alles, was du am Lagerfeuer aufstellen kannst – je Beruf drei Stufen. Die erste lehrt der Lehrer, die höheren sind Baupläne: meist Beute bestimmter Bosse. Ein Klick zeigt rechts Fundort und Zutaten.")
    local function Block(p)
        local list = PRO.CampItems(p.key)
        if #list == 0 then return end
        local s = skills and skills[p.key]
        y = SectionHead(body, y, w, PRO.ProfName(p.key) .. (s and ("  ·  deine Fertigkeit " .. s.rank) or ""),
            s and "goldBright" or "textMuted", #list)
        for i, r in ipairs(list) do
            local have = s and r.learn and s.rank >= r.learn
            y = RecipeRow(body, y, w, r, { tone = have and "skillGreen" or nil })
            y = Note(body, y + 4, w, PRO.CampLine(r, i))
        end
        y = y - 10
    end
    for _, p in ipairs(P and P.PROFS or {}) do if skills and skills[p.key] then Block(p) end end
    for _, p in ipairs(P and P.PROFS or {}) do if not (skills and skills[p.key]) then Block(p) end end
    body:SetHeight(math.max(1, -y))
end
PRO.DrawCampAll = DrawCampAll

local function DrawRecipes(body, w, skill, cat)
    local y, shown, hidden = 0, 0, 0
    local defs = skill and PRO.SECTIONS or PRO.RANKS
    y = Note(body, y, w, PRO.Legend())
    y = DrawCamp(body, y, w, selected)
    for i, sec in ipairs(defs) do
        local list = cat.sections[sec.key]
        -- Ohne Fertigkeit: der erste Rang offen, die anderen nur mit "Alle zeigen".
        local collapsed = (sec.collapsible or (not skill and i > 1)) and not showAll
        if #list > 0 then
            if collapsed then
                hidden = hidden + #list
            else
                shown = shown + 1
                local note
                if skill and not cat.learnedKnown and (sec.key == "now" or sec.key == "recipe") then note = NOTE_UNSURE end
                y = SectionHead(body, y, w, sec.label, sec.color, #list, note)
                for _, r in ipairs(list) do
                    local d = skill and PRO.Difficulty(r, skill)
                    y = RecipeRow(body, y, w, r, { tone = d and TONE[d], dim = sec.key == "known" })
                end
                y = y - 10
            end
        end
    end
    if shown == 0 then
        local text = hidden > 0 and "Alles Weitere steht unter „Alle zeigen“." or "Für diesen Beruf ist nichts hinterlegt."
        y = SectionHead(body, y, w, "Rezepte", "textMuted", 0, text)
    end
    body:SetHeight(math.max(1, -y))
    return cat, hidden
end

local function TrainerRow(body, y, w, t, profName)
    used.trainer = used.trainer + 1
    local row = trainerPool[used.trainer]
    if not row then
        row = CreateFrame("Frame", nil, body)
        row:SetHeight(40)
        row.name = WeintCodex.Label(row, "", { size = 12, font = WeintCodex.Fonts.sansMedium })
        row.name:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -4)
        row.sub = WeintCodex.Label(row, "", { size = 10, color = "textMuted" })
        row.sub:SetPoint("TOPLEFT", row.name, "BOTTOMLEFT", 0, -3)
        -- 1.0.5.53 (Bericht: "alles abgehackt"): Knopf neben dem Namen,
        -- die zweite Zeile ueber die ganze Breite.
        row.name:SetPoint("RIGHT", row, "RIGHT", -60, 0)
        row.sub:SetPoint("RIGHT", row, "RIGHT", -2, 0)
        row.name:SetWordWrap(false)
        row.sub:SetWordWrap(false)
        row:EnableMouse(true)
        row:SetScript("OnEnter", function(self)
            local gt, tt = _G.GameTooltip, self.trainer
            if not (gt and tt) then return end
            gt:SetOwner(self, "ANCHOR_RIGHT")
            local tb, tm = C.textBright, C.textMuted
            gt:SetText(tt.name, tb[1], tb[2], tb[3])
            gt:AddLine((self.prof or "") .. ": " .. (PRO.RANK_TEXT[tt.rank] or "Rang unbekannt"), tm[1], tm[2], tm[3], true)
            if tt.next then
                local g = C.successBright
                gt:AddLine("Lehrt deinen nächsten Rang", g[1], g[2], g[3], true)
            end
            gt:Show()
        end)
        row:SetScript("OnLeave", function() if _G.GameTooltip then _G.GameTooltip:Hide() end end)
        row.map = WeintCodex.CreateButton(row, { kind = "secondary", text = "Karte", height = 20, size = 10,
            padding = 18, radius = 0, onClick = function()
                local tt = row.trainer
                local QM = WeintCodex.QuestMap
                if tt and tt.map and QM then
                    QM.Show({ map = tt.map, x = tt.x / 100, y = tt.y / 100, who = tt.name }, nil, "Lehrt: " .. (row.prof or ""))
                end
            end })
        WeintCodex.DrawSlimBorder(row.map, "accentDim", 1, 1)
        row.map:SetPoint("TOPRIGHT", row, "TOPRIGHT", -2, -2)
        trainerPool[used.trainer] = row
    end
    row:SetParent(body)
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", body, "TOPLEFT", 0, y)
    row:SetWidth(w)
    row.trainer, row.prof = t, profName
    row.name:SetText(t.name)
    local c = t.next and C.successBright or C.textNormal
    row.name:SetTextColor(c[1], c[2], c[3])
    local QM = WeintCodex.QuestMap
    local zone = t.map and QM and QM.MapName(t.map)
    -- Erst der Ort, dann bis wohin er lehrt - der Rangname steht im Tooltip
    -- (6.14.0.1: "Fachmann · bis 300 · Hinterl..." schnitt den Ort ab).
    local parts = {}
    if zone then parts[1] = zone elseif not t.map then parts[1] = "Lage unbekannt" end
    if PRO.RANK_CAP[t.rank] then parts[#parts + 1] = "bis " .. PRO.RANK_CAP[t.rank] end
    row.map:SetShown(t.map ~= nil)
    row.sub:SetText(table.concat(parts, "  ·  "))
    row:Show()
    return y - 48
end

-- 1.0.5.50: Raenge, die kein Lehrer gibt (Experte der Nebenberufe als
-- Buch, Fachmann ueber eine Quest) - unter den Lehrern, mit Haendler.
PRO.RANK_LABEL = { [150] = "Geselle", [225] = "Experte", [300] = "Fachmann" }
function PRO.RankBookLines(key)
    -- 1.0.5.54: zuerst die Raenge aus dem Abgleich mit Naowh Forever -
    -- mit Preis des Buchs und den Lehrern einer Quest (Pfeil dorthin).
    local nfr = P and P.NF_RANKS and P.NF_RANKS[key]
    if nfr and #nfr > 0 then
        local out = {}
        local mine = _G.UnitFactionGroup and Plain(_G.UnitFactionGroup("player"))
        if mine ~= "Alliance" and mine ~= "Horde" then mine = nil end
        local function pick(list)
            local res = {}
            for _, v in ipairs(list or {}) do
                if not mine or not v[3] or v[3] == mine then
                    res[#res + 1] = { v[2], v[4], v[5], v[6], v[3] or nil, price = v[7] or nil, npc = v[1] }
                end
            end
            return res
        end
        for _, r in ipairs(nfr) do
            local rank = PRO.RANK_LABEL[r.cap] or tostring(r.cap)
            if r.item then
                out[#out + 1] = { rank = rank, cap = r.cap, item = r.item, req = r.skill, vendors = pick(r.vendors),
                    text = "Rang " .. rank .. ": Buch „" .. PRO.ItemName(r.item) .. "“" }
            elseif r.quest then
                local q = r.quest[mine == "Horde" and "H" or "A"] or r.quest.A or r.quest.H
                out[#out + 1] = { rank = rank, cap = r.cap, req = r.skill, level = r.level, quest = q or nil,
                    questName = r.questName, teachers = pick(r.teachers),
                    text = "Rang " .. rank .. ": über eine Quest" }
            end
        end
        return out
    end
    local line = PRO.Line and PRO.Line(key)
    local rows = line and P and P.RANKS and P.RANKS[line]
    local out = {}
    if not rows then return out end
    local QM = WeintCodex.QuestMap
    local horde = _G.UnitFactionGroup and Plain(_G.UnitFactionGroup("player")) == "Horde"
    for _, r in ipairs(rows) do
        local rank = PRO.RANK_LABEL[r[1]] or tostring(r[1])
        if r[2] == "book" and r[5] ~= 0 then
            local vs = PRO.Vendors({ recipeItem = r[5] })
            local where = {}
            for _, v in ipairs(vs) do
                local zone = v[2] and QM and QM.MapName(v[2])
                where[#where + 1] = v[1] .. (zone and (", " .. zone) or "")
            end
            out[#out + 1] = { rank = rank, cap = r[1], item = r[5], req = r[3], vendors = vs,
                text = "Rang " .. rank .. " (bis " .. r[1] .. ", ab " .. r[3] .. "): Buch „" .. PRO.ItemName(r[5]) .. "“"
                    .. (#where > 0 and (" – bei " .. table.concat(where, " oder ")) or " – Händler unbekannt") }
        elseif r[2] == "quest" then
            local q = horde and r[7] or r[6]
            out[#out + 1] = { rank = rank, cap = r[1], req = r[3], quest = q ~= 0 and q or nil,
                text = "Rang " .. rank .. " (bis " .. r[1] .. ", ab " .. r[3] .. (r[4] > 0 and (", Stufe " .. r[4]) or "")
                    .. "): über eine Quest, nicht beim Lehrer" }
        end
    end
    return out
end
-- 1.0.5.51 (Bericht mit Bild: "Buecher ohne Questpfeil, alles ueberlappt"):
-- je Haendler eine Zeile wie bei den Lehrern - Buch, Haendler und Ort,
-- rechts "Pfeil" zum Haendler. Ein Rang ueber eine Quest steht als Zeile
-- ohne Knopf.
local function BookRow(body, y, w, title, line2, line3, target)
    used.book = used.book + 1
    local row = bookPool[used.book]
    if not row then
        row = CreateFrame("Frame", nil, body)
        row:SetHeight(54)
        row.name = WeintCodex.Label(row, "", { size = 12, font = WeintCodex.Fonts.sansMedium, color = "goldBright" })
        row.name:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -4)
        row.name:SetPoint("RIGHT", row, "RIGHT", -60, 0)
        row.name:SetWordWrap(false)
        row.line2 = WeintCodex.Label(row, "", { size = 11, color = "textNormal" })
        row.line2:SetPoint("TOPLEFT", row.name, "BOTTOMLEFT", 0, -3)
        row.line2:SetPoint("RIGHT", row, "RIGHT", -2, 0)
        row.line2:SetWordWrap(false)
        row.sub = WeintCodex.Label(row, "", { size = 10, color = "textMuted" })
        row.sub:SetPoint("TOPLEFT", row.line2, "BOTTOMLEFT", 0, -3)
        row.sub:SetPoint("RIGHT", row, "RIGHT", -2, 0)
        row.sub:SetWordWrap(false)
        row.go = WeintCodex.CreateButton(row, { kind = "secondary", text = "Pfeil", height = 20, size = 10,
            padding = 18, radius = 0, onClick = function()
                local t, QA = row.target, WeintCodex.UIQuestArrow
                if t and QA and QA.SetCustom then
                    QA.SetCustom({ map = t[2], x = t[3] / 100, y = t[4] / 100, title = row.title })
                end
            end })
        WeintCodex.DrawSlimBorder(row.go, "accentDim", 1, 1)
        row.go:SetPoint("TOPRIGHT", row, "TOPRIGHT", -2, -2)
        bookPool[used.book] = row
    end
    row:SetParent(body)
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", body, "TOPLEFT", 0, y)
    row:SetWidth(w)
    row.target, row.title = target, line2
    row.name:SetText(title)
    row.line2:SetText(line2)
    row.sub:SetText(line3)
    row.go:SetShown(target ~= nil and target[2] ~= nil and target[3] ~= nil and WeintCodex.UIQuestArrow ~= nil)
    row:Show()
    return y - 60
end

function PRO.DrawRankBooks(body, y, w, key)
    local lines = PRO.RankBookLines(key)
    if #lines == 0 then return y end
    y = y - 6
    y = SectionHead(body, y, w, "Ränge ohne Lehrer", "goldBright", nil, nil)
    local QM = WeintCodex.QuestMap
    for _, l in ipairs(lines) do
        local head = l.rank .. "  ·  ab " .. tostring(l.req or "?")
        if l.item then
            local book = PRO.ItemName(l.item)
            if #l.vendors == 0 then
                y = BookRow(body, y, w, head, book, "Händler unbekannt", nil)
            end
            for _, v in ipairs(l.vendors) do
                local zone = v[2] and QM and QM.MapName(v[2])
                y = BookRow(body, y, w, head, book .. (v.price and ("  ·  " .. PRO.Money(v.price)) or ""),
                    v[1] .. (zone and (", " .. zone) or ""), v)
            end
        else
            local qn = (l.quest or l.questName) and ("Quest „" .. PRO.QuestName(l.quest, l.questName) .. "“") or "über eine Quest"
            if l.level then head = head .. "  ·  Stufe " .. l.level end
            local ts = l.teachers or {}
            if #ts == 0 then y = BookRow(body, y, w, head, qn, "nicht beim Lehrer", nil) end
            for _, t in ipairs(ts) do
                local zone = t[2] and QM and QM.MapName(t[2])
                y = BookRow(body, y, w, head, qn, t[1] .. (zone and (", " .. zone) or ""), t)
            end
        end
    end
    return y
end

local function DrawTrainers(body, w, key, faction, max)
    local list, need = PRO.Trainers(key, faction, max)
    local y = 0
    local profName = PRO.ProfName(key)
    -- 1.0.5.56 (Wunsch: "direkter Hinweis auf Raenge ohne Lehrer - zur Zeit
    -- muss man herunterscrollen"): oben ein Satz, welche Raenge nicht der
    -- Lehrer gibt; ist der naechste Rang einer davon, stehen sie ganz oben.
    local books = PRO.RankBookLines(key)
    local nextCap = tonumber(max) and (max + 75) or nil
    local booksFirst = false
    if #books > 0 then
        local names = {}
        for _, l in ipairs(books) do
            names[#names + 1] = l.rank .. " (ab " .. tostring(l.req or "?") .. ")"
            if nextCap and l.cap == nextCap then booksFirst = true end
        end
        y = Note(body, y, w, WeintCodex.ColorText("goldBright", table.concat(names, " und ")
            .. " gibt es nicht beim Lehrer")
            .. (booksFirst and " – dein nächster Rang, gleich hier darunter." or " – Buch bzw. Quest unter den Lehrern."))
        if booksFirst then
            y = PRO.DrawRankBooks(body, y, w, key)
            y = SectionHead(body, y - 6, w, "Lehrer", "textMuted", nil, nil)
        end
    end
    if list[1] and list[1].next and PRO.RANK_CAP[need] then
        y = Note(body, y, w, WeintCodex.ColorText("successBright", "Grün") .. ": lehrt deinen nächsten Rang (bis "
            .. PRO.RANK_CAP[need] .. ")" .. (list[1].dist and " – der nächstgelegene steht oben." or "."))
    end
    for _, t in ipairs(list) do y = TrainerRow(body, y, w, t, profName) end
    if not booksFirst then y = PRO.DrawRankBooks(body, y, w, key) end
    if #list == 0 then
        y = SectionHead(body, y, w, "Lehrer", "textMuted", 0,
            "Für diesen Beruf ist kein Lehrer deiner Fraktion hinterlegt.")
    end
    body:SetHeight(math.max(1, -y))
    return list, need
end

-- Die Liste links: deine Berufe zuerst (mit Fertigkeit), dann die anderen.
function PRO.SidebarItems(skills)
    local mine, others = {}, {}
    for _, p in ipairs(P and P.PROFS or {}) do
        local s = skills[p.key]
        if s then mine[#mine + 1] = p else others[#others + 1] = p end
    end
    local items, order = {}, {}
    local function add(p, status)
        items[#items + 1] = { label = PRO.ProfName(p.key), status = status, onClick = function()
            selected = p.key
            PRO.campAll = false
            -- 6.131.1.0 (Beta-Test: "Planer springt zurueck auf Leder"): ein
            -- Werkzeug bleibt offen und nimmt den gewaehlten Beruf.
            PRO.Show()
        end }
        order[#order + 1] = p.key
    end
    if #mine > 0 then
        items[#items + 1] = { label = "Deine Berufe", isGroup = true }
        for _, p in ipairs(mine) do
            local s = skills[p.key]
            add(p, { text = s.rank .. (s.max and (" / " .. s.max) or ""), color = "textMuted" })
        end
        items[#items + 1] = { label = "Weitere", isGroup = true }
    end
    for _, p in ipairs(others) do add(p, nil) end
    return items, order
end

local function Faction()
    local f = _G.UnitFactionGroup and Plain(_G.UnitFactionGroup("player"))
    return (f == "Alliance" or f == "Horde") and f or nil
end

-- Woher ein Rezept kommt (6.67.0.0, Beta-Test: "ob es kaeuflich zu
-- erwerben ist oder ob man was anderes dafuer machen muss"). Nur was der
-- Bestand sagt: Lehrer, Haendler (Classic), Haendlergunst, sonst ein
-- Rezeptgegenstand ohne bekannten Haendler - dann sagen wir genau das und
-- raten keine Quelle (Beute, Quest, Ruf sind nicht im Bestand).
function PRO.Origin(r)
    if not r then return "unknown", "Herkunft unbekannt" end
    local nf = PRO.NFSources(r.spell)
    if r.trainer then
        return "trainer", "Beim Lehrer lernbar" .. ((nf and nf.cost) and (" für " .. PRO.Money(nf.cost)) or "")
    end
    if #PRO.Vendors(r) > 0 then
        local v = PRO.Vendors(r)[1]
        return "vendor", "Käuflich beim Händler" .. (v.price and (" für " .. PRO.Money(v.price)) or "")
    end
    if not r.recipeItem and not nf then return "unknown", "Herkunft unbekannt" end
    if r.favor then return "favor", "Gegen " .. r.favor .. " Händlergunst" end
    local other = PRO.OtherSources(r.recipeItem, r.spell)
    if other then return "drop", other end
    if r.bop then return "drop", "Rezept muss selbst gefunden werden (beim Aufheben gebunden) – Fundort nicht im Bestand" end
    return "item", "Rezept als Gegenstand – kein Händler bekannt (Beute, Quest oder Auktionshaus)"
end

PRO.selRecipe = nil
-- 1.0.5.55: Detailbereich schmaler, damit die Lehrer Platz haben.
PRO.DETAIL_W = 300
local function RecipeInspector(r)
    local BP = WeintCodex.BooksPage
    local QM = WeintCodex.QuestMap
    local kind, text = PRO.Origin(r)
    local rows = { { label = "Herkunft", value = ({ trainer = "Lehrer", vendor = "Händler", favor = "Händlergunst",
        drop = "Fundstück", item = "Gegenstand", unknown = "unbekannt" })[kind] } }
    local steps = PRO.StepsText(r)
    if steps ~= "" then rows[#rows + 1] = { label = "Fertigkeit", value = steps } end
    local blocks = {
        { type = "header", text = PRO.RecipeName(r) },
        { type = "text", text = text .. "." },
    }
    local v = PRO.Vendors(r)[1]
    if kind == "vendor" and v then
        rows[#rows + 1] = { label = "Händler", value = v[1] }
        local zone = v[2] and QM and QM.MapName(v[2])
        if zone then rows[#rows + 1] = { label = "Gebiet", value = zone } end
        if v[3] then rows[#rows + 1] = { label = "Lage", value = string.format("%.1f, %.1f", v[3], v[4]) } end
        if v.price then rows[#rows + 1] = { label = "Preis", value = PRO.Money(v.price) } end
        if BP and BP.MapWidget and v[2] and v[3] then
            blocks[#blocks + 1] = { type = "custom", create = function(parent, width)
                local w = BP.MapWidget(parent, width)
                BP.PaintMap(w, v[2], v[3] / 100, v[4] / 100)
                return w
            end }
        end
    end
    -- 1.0.5.54: Quest mit Geber (Pfeil dorthin) und Gegner mit Dropchance.
    local nf = PRO.NFSources(r.spell)
    local giver
    if nf and kind ~= "vendor" then
        for _, q in ipairs(nf.quests) do
            if q.giver and q.giver[2] and (not q.side or q.side == Plain(_G.UnitFactionGroup and _G.UnitFactionGroup("player"))) then
                giver = q
                break
            end
        end
        if giver then
            rows[#rows + 1] = { label = "Quest", value = PRO.QuestName(giver.id, giver.name) }
            rows[#rows + 1] = { label = "Geber", value = giver.giver[1] }
            local zone = QM and QM.MapName(giver.giver[2])
            if zone then rows[#rows + 1] = { label = "Gebiet", value = zone } end
        end
        if #nf.drops > 0 then
            local lines = {}
            for i, d in ipairs(nf.drops) do
                if i > 6 then break end
                lines[#lines + 1] = d.name .. (d.min and ("  (Stufe " .. d.min .. ((d.max and d.max ~= d.min) and ("–" .. d.max) or "") .. ")") or "")
                    .. (d.chance and string.format("  %.1f %%", d.chance) or "")
            end
            if nf.mobs and nf.mobs > #lines then lines[#lines + 1] = "… und " .. (nf.mobs - #lines) .. " weitere Gegner" end
            blocks[#blocks + 1] = { type = "card", lines = lines }
        end
    end
    blocks[#blocks + 1] = { type = "rows", rows = rows }
    if giver and BP and BP.Pill and WeintCodex.UIQuestArrow then
        blocks[#blocks + 1] = { type = "custom", create = function(parent, width)
            if not PRO.questBtn then PRO.questBtn = BP.Pill(parent, "Questpfeil zum Geber", { height = 32, size = 12, primary = true }) end
            local g = PRO.questBtn
            g:SetParent(parent)
            g:SetWidth(width)
            g:SetScript("OnClick", function()
                local QA, gv = WeintCodex.UIQuestArrow, giver.giver
                if QA.SetCustom then QA.SetCustom({ map = gv[2], x = gv[3] / 100, y = gv[4] / 100, title = gv[1] }) end
            end)
            g:Paint(false)
            return g
        end }
    end
    if kind == "vendor" and v and BP and BP.Pill and WeintCodex.UIQuestArrow then
        blocks[#blocks + 1] = { type = "custom", create = function(parent, width)
            if not PRO.guideBtn then PRO.guideBtn = BP.Pill(parent, "Questpfeil hierhin", { height = 32, size = 12, primary = true }) end
            local g = PRO.guideBtn
            g:SetParent(parent)
            g:SetWidth(width)
            g:SetScript("OnClick", function() PRO.GuideToVendor(r) end)
            g:Paint(false)
            return g
        end }
        local more = #PRO.Vendors(r) - 1
        if more > 0 then blocks[#blocks + 1] = { type = "text", text = "Auch bei " .. more .. " weiteren Händlern – siehe Tooltip." } end
    end
    if #r.reagents > 0 then
        local lines = {}
        for _, e in ipairs(r.reagents) do
            local rv = PRO.ReagentVendor(e[1])
            lines[#lines + 1] = e[2] .. "× " .. PRO.ItemName(e[1])
                .. (rv and ("  – Händler" .. (rv.price and (", " .. PRO.Money(rv.price)) or "")) or "")
        end
        blocks[#blocks + 1] = { type = "divider" }
        blocks[#blocks + 1] = { type = "header", text = "Reagenzien" }
        blocks[#blocks + 1] = { type = "card", lines = lines }
    end
    local PT = WeintCodex.ProfTools
    if PT and PT.RecipeBlocks then PT.RecipeBlocks(r, blocks) end
    blocks[#blocks + 1] = { type = "divider" }
    local vs = PRO.Vendors(r)
    blocks[#blocks + 1] = { type = "text", text = (kind == "vendor" and vs.classic) and "Händler und Lage aus Classic – in Forever unbestätigt."
        or "Unbestätigt – Wissensstand der Community." }
    return blocks
end
PRO.RecipeInspector = RecipeInspector

function PRO.SelectRecipe(r)
    PRO.selRecipe = r
    for _, row in ipairs(rowPool) do
        if row.sel then row.sel:SetShown(r ~= nil and row.recipe == r) end
    end
    local nav = WeintCodex.Navigation
    if r and nav and nav.SetInspector then nav.SetInspector(RecipeInspector(r), PRO.DETAIL_W) end
end

local function InspectorBlocks(key, skill, cat)
    local total, new, changed = 0, 0, 0
    for _, r in ipairs(PRO.Recipes(key)) do
        total = total + 1
        if r.state == "n" then new = new + 1 elseif r.state == "c" then changed = changed + 1 end
    end
    local rows = {
        { label = "Beruf", value = PRO.ProfName(key) },
        { label = "Fertigkeit", value = skill and tostring(skill) or "nicht gelernt" },
        { label = "Rezepte", value = tostring(total) },
        { label = "Neu in Forever", value = tostring(new) },
        { label = "Geändert", value = tostring(changed) },
    }
    if skill then
        -- Ohne Blick ins Berufsfenster sagt der Client nur "gelernt" sicher:
        -- "lernbar" ist dann eine Obergrenze, "bringt Fertigkeit" eine
        -- Untergrenze (6.14.0.1: die Liste zeigte 6, der Detailbereich "—").
        local now, up = #cat.sections.now + #cat.sections.recipe, #cat.sections.skillup
        local sure = cat.learnedKnown
        rows[#rows + 1] = { label = "Jetzt lernbar", value = (sure or now == 0) and tostring(now) or ("bis zu " .. now) }
        rows[#rows + 1] = { label = "Bringt Fertigkeit", value = sure and tostring(up) or (up > 0 and ("mind. " .. up) or "—") }
    end
    local at = PRO.ScannedAt(key)
    return {
        { type = "header", text = "Dein Beruf" },
        { type = "rows", rows = rows },
        { type = "divider" },
        { type = "header", text = "Was du schon kannst" },
        { type = "card", lines = at and {
            "Gelesen aus deinem Berufsfenster",
            (_G.date and _G.date("am %d.%m. um %H:%M", at)) or "",
            "Öffne es nach dem Lernen erneut.",
        } or {
            "Noch unbekannt: öffne einmal dein",
            "Berufsfenster, dann merkt sich",
            "WeintCodex, welche Rezepte du kannst.",
        }},
        { type = "divider" },
        { type = "header", text = "Woher das stammt" },
        { type = "card", lines = {
            "Unbestätigt: Rezepte aus dem Forever-",
            "Client, Herkunft, Lehrer und Händler",
            "Wissensstand der Community – nicht",
            "von Blizzard. Ohne „Season of Discovery“.",
        }},
    }
end

PRO.InspectorBlocks = InspectorBlocks

function PRO.Show()
    local cp = WeintCodex.ContentPanel
    for _, child in pairs({ cp:GetChildren() }) do child:Hide() end
    local skills = PRO.Skills()
    local items, order = PRO.SidebarItems(skills)
    if not (selected and byKey[selected]) then selected = order[1] end
    local nav = WeintCodex.Navigation
    nav.BuildSidebar("Berufe", items)
    for i, key in ipairs(order) do
        if key == selected and nav.SidebarButtons then
            local btn = nav.SidebarButtons()[i]
            if btn and btn.SetActive then btn:SetActive(true) end
        end
    end

    local PT = WeintCodex.ProfTools
    if PRO.view and PT then return PT.Draw(PRO.view) end
    local f = BuildPage()
    f:Show()
    if f.ToolBar then f.ToolBar:Select(1) end
    local name = PRO.ProfName(selected)
    WeintCodex.SetBreadcrumb("Berufe", name)
    local s = skills[selected]
    local skill = s and s.rank or nil
    if f.Head and f.Head.Title then f.Head.Title:SetText("Berufe · " .. name) end

    ResetPools()
    wipe(pending)
    -- Erst der Detailbereich, dann messen (wie beim Lehrer).
    local cat = PRO.Categorize(selected, skill)
    if PRO.selRecipe and PRO.selRecipe.key ~= selected and (PRO.query or "") == "" and not PRO.campAll then PRO.selRecipe = nil end
    if PRO.selRecipe then nav.SetInspector(RecipeInspector(PRO.selRecipe), PRO.DETAIL_W)
    else nav.SetInspector(InspectorBlocks(selected, skill, cat), PRO.DETAIL_W) end

    if PT and PT.FitBar then
        PT.FitBar(f)
        if f.ToolBar then f.ToolBar:Select(1) end
    end
    local total = Plain(f:GetWidth())
    if type(total) == "number" and total > 400 then
        f.RecipeCard:SetWidth(math.floor((total - 2 * WeintCodex.Metrics.PAD_X - WeintCodex.Metrics.GAP) * 0.58))
    end
    local rw = (Plain(f.RecipeCard:GetWidth()) or 460) - 40
    local tw = (Plain(f.TrainerCard:GetWidth()) or 280) - 40
    local rh = (Plain(f.RecipeCard:GetHeight()) or 360) - 94
    local th = (Plain(f.TrainerCard:GetHeight()) or 360) - 62
    f.RecipeScroll:SetSize(rw, math.max(60, rh))
    f.RecipeBody:SetWidth(rw - 10)
    f.TrainerScroll:SetSize(tw, math.max(60, th))
    f.TrainerBody:SetWidth(tw - 10)

    local hidden = 0
    local searching = type(PRO.query) == "string" and PRO.query ~= ""
    local camp = PRO.campAll and not searching
    if searching then DrawSearch(f.RecipeBody, rw - 14)
    elseif camp then DrawCampAll(f.RecipeBody, rw - 14, skills)
    else local _c _c, hidden = DrawRecipes(f.RecipeBody, rw - 14, skill, cat) end
    if camp then
        if f.Head and f.Head.Title then f.Head.Title:SetText("Berufe · Lagerfeuer") end
        WeintCodex.SetBreadcrumb("Berufe", "Lagerfeuer")
    end
    if f.CampButton then f.CampButton:SetText(camp and "Zurück zum Beruf" or "Lagerfeuer") end
    if f.RecipeTitle then f.RecipeTitle:SetText(camp and "Lagerfeuer" or "Rezepte") end
    DrawTrainers(f.TrainerBody, tw - 14, selected, Faction(), s and s.max)
    f.AllButton:SetText(showAll and "Weniger zeigen" or ("Alle zeigen" .. (hidden > 0 and (" (" .. hidden .. ")") or "")))
    f.AllButton:SetShown(not searching and not camp and (showAll or hidden > 0))
    f.drawnWidth = total
    PRO.lastDraw = { key = selected, skill = skill, rows = used.row, trainers = used.trainer, hidden = hidden }
end

function PRO.Select(key) if byKey[key] then selected = key end end
function PRO.ShowAll(v) showAll = v and true or false end
function PRO.Page() return page end
function PRO.Selected() return selected end

--------------------------------------------------
-- Ereignisse
--------------------------------------------------

local redrawQueued = false
local function Redraw()
    if redrawQueued or not (page and page:IsShown()) then return end
    local main = WeintCodex.MainFrame
    if type(main) == "table" and main.IsShown and not main:IsShown() then return end
    redrawQueued = true
    local function run() redrawQueued = false if page and page:IsShown() then PRO.Show() end end
    if _G.C_Timer and _G.C_Timer.After then _G.C_Timer.After(0.2, run) else run() end
end
PRO.Redraw = Redraw

-- Das Berufsfenster liest sich hoechstens alle drei Sekunden aus (das Spiel
-- meldet beim Blaettern viele Aenderungen).
local scanQueued = false
local function QueueScan(delay)
    if scanQueued then return end
    scanQueued = true
    local function run() scanQueued = false PRO.Scan() Redraw() end
    if _G.C_Timer and _G.C_Timer.After then _G.C_Timer.After(delay, run) else run() end
end
PRO.QueueScan = QueueScan

local ev = CreateFrame("Frame")
for _, e in ipairs({ "TRADE_SKILL_SHOW", "TRADE_SKILL_LIST_UPDATE", "TRADE_SKILL_UPDATE", "NEW_RECIPE_LEARNED",
                     "CRAFT_SHOW", "CRAFT_UPDATE", "SKILL_LINES_CHANGED", "SPELL_DATA_LOAD_RESULT",
                     "GET_ITEM_INFO_RECEIVED", "PLAYER_LOGIN" }) do
    pcall(ev.RegisterEvent, ev, e)
end
-- Wie oft jedes Ereignis kam (fuer /wcui pruefen: hat das Spiel das
-- Berufsfenster ueberhaupt gemeldet?).
PRO.eventCount = {}
ev:SetScript("OnEvent", WeintCodex.Measured("Berufe", function(_, event, id)
    PRO.eventCount[event] = (PRO.eventCount[event] or 0) + 1
    if event == "PLAYER_LOGIN" or event == "SKILL_LINES_CHANGED" then pcall(PRO.RememberSkills) end
    if event == "PLAYER_LOGIN" then
        -- 1.0.1.6: noch einmal, wenn der Client die Berufe sicher kennt.
        if _G.C_Timer and _G.C_Timer.After then _G.C_Timer.After(10, function() pcall(PRO.RememberSkills) pcall(PRO.FillNames) end) end
        return
    end
    if event == "TRADE_SKILL_SHOW" or event == "CRAFT_SHOW" then QueueScan(0.3) return end
    if event == "NEW_RECIPE_LEARNED" then
        local m = PRO.Memory()
        id = Plain(id)
        if m and type(id) == "number" then m.known[id] = true PRO.RememberName(m, id) end
    end
    if event == "TRADE_SKILL_LIST_UPDATE" or event == "TRADE_SKILL_UPDATE" or event == "CRAFT_UPDATE"
       or event == "NEW_RECIPE_LEARNED" then
        QueueScan(3)
        return
    end
    if event == "SPELL_DATA_LOAD_RESULT" and not pending[id] then return end
    Redraw()
end))
PRO.events = ev

--------------------------------------------------
-- Sammelstellen im Tooltip (1.0.5.55)
--------------------------------------------------
-- Wunsch: "die Sammelstellen mit Fertigkeit in den Tooltip". Aus dem
-- Abgleich (P.NF_NODES: Kraut/Ader -> Fertigkeit, Gegenstand): ein Kraut
-- oder Erz nennt im Tooltip, ab welcher Fertigkeit man es sammelt - gruen,
-- wenn du so weit bist, rot, wenn nicht, sonst neutral.
PRO.GATHER_KIND = { herb = { "herbalism", "Kräuterkunde" }, ore = { "mining", "Bergbau" },
                    leather = { "skinning", "Kürschnerei" }, skin = { "skinning", "Kürschnerei" } }
local gatherByItem
function PRO.GatherNeed(item)
    if not gatherByItem then
        gatherByItem = {}
        for _, v in pairs(P and P.NF_NODES or {}) do
            local kind, skill, it = v[1], v[2], v[3]
            if it and skill and PRO.GATHER_KIND[kind] then
                local cur = gatherByItem[it]
                if not cur or skill < cur.skill then gatherByItem[it] = { kind = kind, skill = skill } end
            end
        end
    end
    return gatherByItem[item]
end

function PRO.GatherLine(item)
    local need = PRO.GatherNeed(item)
    if not need then return nil end
    local k = PRO.GATHER_KIND[need.kind]
    local ok, skills = pcall(PRO.Skills)
    local mine = ok and type(skills) == "table" and skills[k[1]]
    local tone = "textMuted"
    if mine and type(mine.rank) == "number" then tone = mine.rank >= need.skill and "successBright" or "danger" end
    return "Sammeln: " .. k[2] .. " ab " .. need.skill, tone
end

local function OnGatherItem(tt, data)
    if tt ~= _G.GameTooltip and tt ~= _G.ItemRefTooltip then return end
    if tt.IsForbidden and tt:IsForbidden() then return end
    local id = type(data) == "table" and Plain(data.id)
    if type(id) ~= "number" then return end
    local text, tone = PRO.GatherLine(id)
    if not text then return end
    local c = C[tone] or C.textMuted
    tt:AddLine(text, c[1], c[2], c[3])
end
PRO.OnGatherItem = OnGatherItem
do
    local tdp, e = _G.TooltipDataProcessor, _G.Enum and _G.Enum.TooltipDataType
    if tdp and tdp.AddTooltipPostCall and e and e.Item then
        pcall(tdp.AddTooltipPostCall, e.Item, WeintCodex.Measured("Berufe: Sammeln", OnGatherItem))
    end
end
