--------------------------------------------------
-- WeintCodex :: Berufe - Werkzeuge (Gilde, Planer, Merkliste, Abklingzeiten)
--------------------------------------------------
-- Seit 6.129.0.0, Wunsch des Spielers ("sowas wie Profession Master"). Nach
-- dem VERHALTEN von Profession Master gebaut, ohne dessen Code - das Addon
-- ist "All Rights Reserved". Vier Werkzeuge auf der Codex-Seite "Berufe",
-- unter den Berufen in der Seitenleiste:
--
--   Gilde          wer (Gilde und eigene Twinks) welches Rezept kann. Dafuer
--                  teilt WeintCodex die eigenen GELERNTEN Rezepte still als
--                  Addon-Nachricht mit der Gilde (Prefix WCPR, nur GUILD;
--                  Schalter SavedData.profShare, an). Gesendet werden nur
--                  Beruf, Fertigkeit und Zaubernummern - nichts sonst.
--   Planer         guenstigster Weg bis zur Obergrenze der Fertigkeit, mit
--                  Einkaufsliste. Preise nur aus den eigenen Auktionspreisen;
--                  ein Rezept mit unbekanntem Preis ist "unbekannt", nie 0.
--   Merkliste      vorgemerkte Rezepte, was an Reagenzien fehlt (gezaehlt
--                  ueber alle eigenen Charaktere, wenn der Bestand an ist).
--   Abklingzeiten  welche Rezepte gerade abklingen, je Charakter. Welche
--                  Rezepte eine haben, sagt der Client beim Herstellen -
--                  keine feste Liste.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.ProfTools = {}

local PT  = WeintCodex.ProfTools
local PRO = WeintCodex.Professions
local P   = WeintCodex.ProfessionData
local C   = WeintCodex.Colors

local function Plain(v)
    local K = WeintCodex.UIKit
    if K and K.Plain then return K.Plain(v) end
    return v
end

local function Now() return (_G.time and _G.time()) or 0 end

local function Me()
    local n = _G.UnitName and Plain(_G.UnitName("player"))
    local r = _G.GetRealmName and Plain(_G.GetRealmName())
    if type(n) ~= "string" then return nil end
    return n .. "-" .. (type(r) == "string" and r or ""), n
end

local function SD()
    local sd = WeintCodex.SavedData
    return type(sd) == "table" and sd or nil
end

PT.TOOLS = {
    { key = "gilde",    label = "Gilde" },
    { key = "planer",   label = "Planer" },
    { key = "merkliste", label = "Merkliste" },
    { key = "cooldowns", label = "Abklingzeiten" },
}

--------------------------------------------------
-- Rezepte nach Zauber und nach Gegenstand
--------------------------------------------------

local bySpellR, byItem
local function Index()
    if bySpellR then return end
    bySpellR, byItem = {}, {}
    for _, p in ipairs(P and P.PROFS or {}) do
        for _, r in ipairs(PRO.Recipes(p.key)) do
            bySpellR[r.spell] = r
            if r.item then
                byItem[r.item] = byItem[r.item] or {}
                table.insert(byItem[r.item], r)
            end
        end
    end
end
function PT.RecipeBySpell(id) Index() return bySpellR[id] end
function PT.RecipesForItem(id) Index() return byItem[id] end

--------------------------------------------------
-- Gilde: wer kann was
--------------------------------------------------

PT.PREFIX = "WCPR"
PT.MSG_MAX = 250
PT.SEND_GAP = 1.5
PT.KEEP_DAYS = 45
PT.ANSWER_EVERY = 600     -- hoechstens alle 10 Minuten auf eine Frage antworten
PT.RATE_MAX = 40          -- Nachrichten je Absender und Minute

function PT.Sharing()
    local sd = SD()
    if not sd then return false end
    if sd.profShare == nil then sd.profShare = true end
    return sd.profShare and true or false
end

function PT.SetSharing(on)
    local sd = SD()
    if sd then sd.profShare = on and true or false end
    PT.ApplyShare()
end

function PT.Guild()
    local sd = SD()
    if not sd then return nil end
    sd.guildProfs = sd.guildProfs or {}
    return sd.guildProfs
end

-- 36er-Zahlen halten die Nachrichten kurz.
local DIGITS = "0123456789abcdefghijklmnopqrstuvwxyz"
function PT.B36(n)
    if n == 0 then return "0" end
    local s = ""
    while n > 0 do
        local d = n % 36
        s = DIGITS:sub(d + 1, d + 1) .. s
        n = math.floor(n / 36)
    end
    return s
end

-- Nachrichten fuer einen Beruf: "D|Beruf|Rang|Max|Teil|Teile|id,id,...".
function PT.Encode(prof, rank, max, ids)
    table.sort(ids)
    local chunks, cur = {}, {}
    local headLen = #prof + 24
    local len = headLen
    for _, id in ipairs(ids) do
        local s = PT.B36(id)
        if len + #s + 1 > PT.MSG_MAX and #cur > 0 then
            chunks[#chunks + 1] = cur
            cur, len = {}, headLen
        end
        cur[#cur + 1] = s
        len = len + #s + 1
    end
    if #cur > 0 or #chunks == 0 then chunks[#chunks + 1] = cur end
    local out = {}
    for i, c in ipairs(chunks) do
        out[i] = "D|" .. prof .. "|" .. rank .. "|" .. (max or 0) .. "|" .. i .. "|" .. #chunks .. "|" .. table.concat(c, ",")
    end
    return out
end

-- Eine empfangene Zeile pruefen. Gibt prof, rank, max, part, parts, ids zurueck - oder nil.
function PT.Decode(text)
    if type(text) ~= "string" or #text > 255 then return nil end
    local prof, rank, max, part, parts, list = text:match("^D|(%a+)|(%d+)|(%d+)|(%d+)|(%d+)|([%w,]*)$")
    if not (prof and PRO.byKey[prof]) then return nil end
    rank, max, part, parts = tonumber(rank), tonumber(max), tonumber(part), tonumber(parts)
    if rank > 1000 or max > 1000 or part < 1 or parts < 1 or part > parts or parts > 40 then return nil end
    local ids = {}
    for w in list:gmatch("[^,]+") do
        local id = tonumber(w, 36)
        if not id or id > 10000000 then return nil end
        ids[#ids + 1] = id
    end
    return prof, rank, max, part, parts, ids
end

local queue = {}
PT.queue = queue
local lastQueued = 0

-- Die eigenen Berufe in die Warteschlange (nur gelesene Berufe: was nie im
-- Berufsfenster war, ist unbekannt und wird nicht als "kann nichts" geteilt).
function PT.QueueOwn()
    if not (PT.Sharing() and _G.IsInGuild and Plain(_G.IsInGuild())) then return 0 end
    local m = PRO.Memory()
    if not m then return 0 end
    local skills = PRO.Skills()
    -- Nur die eigenen Berufszeilen ersetzen; Haendler (V|) bleiben drin.
    for i = #queue, 1, -1 do if queue[i]:sub(1, 2) == "D|" then table.remove(queue, i) end end
    for key, s in pairs(skills) do
        if m.scanned[key] then
            local ids = {}
            for _, r in ipairs(PRO.Recipes(key)) do
                if m.known[r.spell] then ids[#ids + 1] = r.spell end
            end
            for _, line in ipairs(PT.Encode(key, s.rank, s.max, ids)) do queue[#queue + 1] = line end
        end
    end
    lastQueued = Now()
    if #queue > 0 and PT.sender then PT.sender:Show() end
    return #queue
end

local nextSend = 0
function PT.SendNext(now)
    if #queue == 0 then return true end
    if now < nextSend then return false end
    if _G.InCombatLockdown and Plain(_G.InCombatLockdown()) then return false end
    local cc = _G.C_ChatInfo
    if not (cc and cc.SendAddonMessage and PT.Sharing()) then
        for i = #queue, 1, -1 do queue[i] = nil end
        return true
    end
    local ok, res = pcall(cc.SendAddonMessage, PT.PREFIX, queue[1], "GUILD")
    if ok and (res == nil or res == true or res == 0) then
        table.remove(queue, 1)
        nextSend = now + PT.SEND_GAP
    else
        nextSend = now + 5
    end
    return #queue == 0
end

local senders = {}
local staging = {}
function PT.OnAddonMessage(prefix, text, channel, sender)
    if prefix ~= PT.PREFIX or channel ~= "GUILD" or type(sender) ~= "string" then return end
    local me, short = Me()
    local name = sender:match("^([^-]+)") or sender
    if sender == me or name == short then return end
    local t = Now()
    local s = senders[sender]
    if not s or t - s[1] > 60 then s = { t, 0 } senders[sender] = s end
    s[2] = s[2] + 1
    if s[2] > PT.RATE_MAX then return end
    if text == "Q" then
        -- Jemand fragt nach: hoechstens alle 10 Minuten antworten, zeitversetzt.
        if t - lastQueued > PT.ANSWER_EVERY and _G.C_Timer and _G.C_Timer.After then
            lastQueued = t
            _G.C_Timer.After(5 + math.random() * 20, PT.QueueOwn)
        end
        return
    end
    if text:sub(1, 2) == "V|" then
        local id, e = PT.DecodeVendor(text)
        if id then e.s, e.by = true, name PT.StoreVendor(id, e) end
        return
    end
    local prof, rank, max, part, parts, ids = PT.Decode(text)
    if not prof then return end
    local key = sender .. "|" .. prof
    local st = staging[key]
    if part == 1 or not st or st.parts ~= parts then st = { parts = parts, got = 0, ids = {} } staging[key] = st end
    st.got = st.got + 1
    for _, id in ipairs(ids) do st.ids[id] = true end
    if st.got < parts then return end
    staging[key] = nil
    local g = PT.Guild()
    if not g then return end
    g[name] = g[name] or {}
    g[name][prof] = { rank = rank, max = max > 0 and max or nil, known = st.ids, at = t }
end

-- Alte Eintraege (laenger nicht gehoert) raus.
function PT.Prune()
    local g = PT.Guild()
    if not g then return end
    local limit = Now() - PT.KEEP_DAYS * 86400
    for name, profs in pairs(g) do
        local any = false
        for prof, e in pairs(profs) do
            if (e.at or 0) < limit then profs[prof] = nil else any = true end
        end
        if not any then g[name] = nil end
    end
end

-- Wer ein Rezept kann: eigene Charaktere (aus dem Berufsfenster gemerkt) und
-- die Gilde. Liste von { name, own }.
function PT.Crafters(spell)
    local out = {}
    local sd = SD()
    local me = Me()
    for char, m in pairs(sd and sd.professions or {}) do
        if type(m) == "table" and m.known and m.known[spell] then
            out[#out + 1] = { name = (char:match("^([^-]+)") or char), own = true, me = char == me }
        end
    end
    for name, profs in pairs(PT.Guild() or {}) do
        for _, e in pairs(profs) do
            if e.known and e.known[spell] then out[#out + 1] = { name = name } break end
        end
    end
    table.sort(out, function(a, b)
        if (a.own or false) ~= (b.own or false) then return a.own and true or false end
        return a.name < b.name
    end)
    return out
end

function PT.CraftersText(spell, max)
    local list = PT.Crafters(spell)
    if #list == 0 then return nil end
    local names = {}
    for i, c in ipairs(list) do
        if i > (max or 6) then break end
        names[#names + 1] = c.me and "du" or c.name
    end
    local more = #list - #names
    return table.concat(names, ", ") .. (more > 0 and (" und " .. more .. " weitere") or "")
end

-- Tooltip eines Gegenstands: "Herstellbar von …".
local function OnItem(tt, data)
    if tt ~= _G.GameTooltip and tt ~= _G.ItemRefTooltip then return end
    if tt.IsForbidden and tt:IsForbidden() then return end
    local AP = WeintCodex.UIAuctionPrices
    local id
    if AP and AP.ItemIdOf then id = AP.ItemIdOf(tt, data)
    else id = type(data) == "table" and Plain(data.id) or nil end
    if type(id) ~= "number" then return end
    -- 6.135.0.0: steht er auf der Merkliste und fehlt noch?
    local sd = SD()
    local w = sd and (next(sd.profWatchItems or {}) or next(sd.profWatch or {})) and PT.Missing()[id]
    if w then
        local g = C.goldBright or C.accent
        tt:AddLine("Merkliste: dir fehlen noch " .. w, g[1], g[2], g[3])
    end
    local rs = PT.RecipesForItem(id)
    if not rs then return end
    for _, r in ipairs(rs) do
        local text = PT.CraftersText(r.spell, 5)
        if text then
            local m = C.textMuted
            tt:AddLine("Herstellbar von: " .. text, m[1], m[2], m[3], true)
            return
        end
    end
end
PT.OnItem = OnItem

function PT.HookTooltips()
    if PT._hooked then return end
    PT._hooked = true
    local tdp, e = _G.TooltipDataProcessor, _G.Enum and _G.Enum.TooltipDataType
    if tdp and tdp.AddTooltipPostCall and e and e.Item then
        pcall(tdp.AddTooltipPostCall, e.Item, OnItem)
    else
        for _, n in ipairs({ "GameTooltip", "ItemRefTooltip" }) do
            local tt = _G[n]
            if type(tt) == "table" and tt.HookScript then
                tt:HookScript("OnTooltipSetItem", function(self) OnItem(self) end)
            end
        end
    end
end

--------------------------------------------------
-- Planer
--------------------------------------------------

-- Preis eines Reagenz aus den eigenen Auktionspreisen, sonst nil.
function PT.Price(id)
    local AP = WeintCodex.UIAuctionPrices
    local f = AP and AP.Lookup and AP.Lookup(id)
    return f and type(f.price) == "number" and f.price or nil
end

-- Kosten eines Herstellens; nil, wenn ein Preis fehlt.
function PT.CraftCost(r)
    local sum = 0
    for _, e in ipairs(r.reagents) do
        local p = PT.Price(e[1])
        if not p then return nil end
        sum = sum + p * e[2]
    end
    return sum
end

-- Chance auf einen Punkt bei Fertigkeit s (Regel aus Classic): orange sicher,
-- ab gelb faellt sie bis grau auf 0.
function PT.Chance(r, s)
    if not (r.learn and r.grey) or s < r.learn or s >= r.grey then return 0 end
    local yellow = r.yellow or r.learn
    if s < yellow then return 1 end
    local span = r.grey - yellow
    if span <= 0 then return 0 end
    return (r.grey - s) / span
end

-- Rezepte, mit denen geplant wird: gelernte und solche vom Lehrer.
function PT.Usable(key)
    local m = PRO.Memory()
    local out = {}
    for _, r in ipairs(PRO.Recipes(key)) do
        if r.learn and r.grey and #r.reagents > 0 then
            local learned = PRO.Learned(r, m)
            -- 6.133.0.0: auch Lehrer- und Haendlerrezepte, die du noch
            -- lernen musst - der Weg sagt dann "lernen"/"kaufen".
            if learned then r._how = "known"
            elseif r.trainer then r._how = "trainer"
            elseif #PRO.Vendors(r) > 0 then r._how = "vendor"
            else r._how = nil end
            if r._how then out[#out + 1] = r end
        end
    end
    return out
end

-- Farbe eines Rezepts bei Fertigkeit s, wie im Berufsfenster.
function PT.Color(r, s)
    if not (r.learn and r.grey) or s < r.learn or s >= r.grey then return "grey" end
    if s < (r.yellow or r.learn) then return "orange" end
    if s < (r.green or r.grey) then return "yellow" end
    return "green"
end

-- Weg von rank bis target. 6.131.0.0 (Beta-Test: "wenn nur noch ein Rezept
-- gruen ist, ist kein Punkt garantiert, grau gibt gar keinen"): erst
-- orange und gelb, darunter das mit den geringsten Kosten je erwartetem
-- Punkt. Gruen nur, wenn es kein oranges oder gelbes gibt - als Wagnis
-- markiert. Grau nie. Abschnitte wechseln auch mit der Farbe.
PT.RANK_STEP = 75
PT.STICKY = 0.7
PT.RANK_NAMES = { [75] = "Geselle", [150] = "Experte", [225] = "Fachmann" }
function PT.Plan(key, rank, target, cap)
    local usable = PT.Usable(key)
    local steps, shop = {}, {}
    local cur
    local function costOf(r)
        if r._cost == nil then r._cost = PT.CraftCost(r) or false end
        return r._cost or nil
    end
    for _, r in ipairs(usable) do r._cost = nil end
    local gap
    local function pick(s, allowGreen, allowVendor)
        local best, bestScore, bestKnown
        for _, r in ipairs(usable) do
            local col = PT.Color(r, s)
            if (r._how ~= "vendor" or allowVendor)
               and (col == "orange" or col == "yellow" or (allowGreen and col == "green")) then
                local ch = PT.Chance(r, s)
                if ch > 0 then
                    local c = costOf(r)
                    local known = c ~= nil
                    local score = known and (c / ch) or (1 / ch)
                    if not best or (known and not bestKnown) or (known == bestKnown and score < bestScore) then
                        best, bestScore, bestKnown = r, score, known
                    end
                end
            end
        end
        return best
    end
    local announced = {}
    local lastCraft
    for s = rank, target - 1 do
        -- Obergrenze erreicht: naechster Rang beim Lehrer.
        if cap and s >= cap and cap < target then
            steps[#steps + 1] = { kind = "rank", at = s, cap = cap, name = PT.RANK_NAMES[cap] }
            cap = cap + PT.RANK_STEP
            cur = nil
        end
        -- Beim selben Rezept bleiben, solange es noch fast sicher Punkte
        -- bringt - sonst springt der Weg alle paar Punkte zum Lehrer.
        local last = lastCraft and lastCraft.recipe
        local best
        if last and PT.Chance(last, s) >= PT.STICKY then best = last end
        best = best or pick(s, false, false) or pick(s, false, true) or pick(s, true, false) or pick(s, true, true)
        if not best then gap = s break end
        if best._how ~= "known" and not announced[best] then
            announced[best] = true
            steps[#steps + 1] = { kind = best._how == "vendor" and "buy" or "learn", at = s, recipe = best }
            cur = nil
        end
        local col = PT.Color(best, s)
        local ch = PT.Chance(best, s)
        local RANKC = { orange = 1, yellow = 2, green = 3 }
        if cur and cur.recipe == best then
            cur.to, cur.crafts = s + 1, cur.crafts + 1 / ch
            cur.minChance = math.min(cur.minChance, ch)
            if (RANKC[col] or 0) > (RANKC[cur.color] or 0) then cur.color = col end
            if col == "green" then cur.risky = true end
        else
            cur = { kind = "craft", from = s, to = s + 1, recipe = best, crafts = 1 / ch, color = col, minChance = ch, risky = col == "green" }
            steps[#steps + 1] = cur
            lastCraft = cur
        end
    end
    local total, unknown = 0, 0
    for _, st in ipairs(steps) do
        if st.kind == "craft" then
            st.crafts = math.ceil(st.crafts - 0.001)
            for _, e in ipairs(st.recipe.reagents) do shop[e[1]] = (shop[e[1]] or 0) + e[2] * st.crafts end
        end
    end
    local list = {}
    for id, n in pairs(shop) do
        local p = PT.Price(id)
        if p then total = total + p * n else unknown = unknown + 1 end
        list[#list + 1] = { id = id, count = n, price = p }
    end
    table.sort(list, function(a, b) return a.count > b.count end)
    return { steps = steps, shop = list, total = total, unknown = unknown, gap = gap }
end

-- Ziel und Obergrenze fuer "den Beruf maxen": bis zum hoechsten Grau
-- der Rezepte (hoechstens 300), Raenge alle 75 Punkte beim Lehrer.
function PT.Goal(key, s)
    local top = 0
    for _, r in ipairs(PRO.Recipes(key)) do if r.grey and r.grey > top then top = r.grey end end
    local target = math.min(300, math.max(top, s.rank))
    local cap = s.max
    if not cap or cap <= s.rank then cap = nil end
    if cap and cap % PT.RANK_STEP ~= 0 then cap = nil end
    return target, cap
end

-- Der Weg als Zeilen fuer beide Ansichten: { left, right, tone, recipe, hint, crafts }.
local LTONE = { orange = "skillOrange", yellow = "skillYellow", green = "skillGreen" }
function PT.PlanLines(plan)
    local out = {}
    for _, st in ipairs(plan.steps) do
        if st.kind == "rank" then
            out[#out + 1] = { left = "→ Lehrer: Rang " .. (st.name or "") .. " lernen", right = "bei " .. st.at,
                tone = "accent", hint = "Deine Obergrenze ist " .. st.cap .. ". Beim Berufslehrer den nächsten Rang lernen (der Lehrer nennt die nötige Stufe)." }
        elseif st.kind == "learn" then
            out[#out + 1] = { left = "→ Lehrer: " .. PRO.RecipeName(st.recipe) .. " lernen", right = "bei " .. st.at,
                tone = "accent", recipe = st.recipe, hint = "Beim Berufslehrer lernen (falls du es noch nicht kannst)." }
        elseif st.kind == "buy" then
            local v = PRO.Vendors(st.recipe)[1]
            out[#out + 1] = { left = "→ Händler: Rezept " .. PRO.RecipeName(st.recipe) .. " kaufen", right = "bei " .. st.at,
                tone = "goldBright", recipe = st.recipe, hint = v and ("Bei " .. v[1] .. " – Händler aus Classic, in Forever unbestätigt.") or "Händler unbekannt." }
        else
            local pct = math.floor(st.minChance * 100 + 0.5)
            out[#out + 1] = {
                left = (st.color == "orange" and "" or "ca. ") .. st.crafts .. "× " .. PRO.RecipeName(st.recipe) .. (st.risky and " (Glückssache)" or ""),
                right = st.from .. "–" .. st.to, tone = LTONE[st.color], recipe = st.recipe, crafts = st.crafts, step = st,
                hint = st.color == "orange" and "Orange: jedes Herstellen bringt einen Punkt."
                    or st.color == "yellow" and ("Gelb: meist ein Punkt, zuletzt etwa " .. pct .. " %.")
                    or ("Grün: nur etwa " .. pct .. " % – kein Punkt garantiert."),
            }
        end
    end
    return out
end

--------------------------------------------------
-- Merkliste
--------------------------------------------------

function PT.Watch()
    local sd = SD()
    if not sd then return nil end
    sd.profWatch = sd.profWatch or {}
    return sd.profWatch
end

function PT.AddWatch(spell, n)
    local w = PT.Watch()
    if not w then return end
    local v = (w[spell] or 0) + (n or 1)
    w[spell] = v > 0 and v or nil
end

-- 6.134.0.0: auch einzelne Gegenstaende (aus der Einkaufsliste).
function PT.WatchItems()
    local sd = SD()
    if not sd then return nil end
    sd.profWatchItems = sd.profWatchItems or {}
    return sd.profWatchItems
end

function PT.AddWatchItem(id, n)
    local w = PT.WatchItems()
    if not w then return end
    local v = (w[id] or 0) + (n or 1)
    w[id] = v > 0 and v or nil
end

-- Wie viele ein Charakter hat: eigener Client (Taschen + Bank), dazu die
-- anderen Charaktere aus dem Bestand (wenn an).
function PT.Have(id)
    local mine = 0
    local gic = (_G.C_Item and _G.C_Item.GetItemCount) or _G.GetItemCount
    if gic then
        local ok, n = pcall(gic, id, true)
        n = ok and Plain(n) or nil
        if type(n) == "number" then mine = n end
    end
    local others = 0
    local IV = WeintCodex.UIInventory
    if IV and IV.Holders then
        local ok, hs = pcall(IV.Holders, id)
        for _, h in ipairs(ok and hs or {}) do
            if not h.me and type(h.total) == "number" then others = others + h.total end
        end
    end
    return mine, others
end

-- Alles, was fuer die Merkliste gebraucht wird: { id, need, mine, others, missing, price }.
function PT.Needs()
    local need = {}
    for spell, n in pairs(PT.Watch() or {}) do
        local r = PT.RecipeBySpell(spell)
        if r then
            for _, e in ipairs(r.reagents) do need[e[1]] = (need[e[1]] or 0) + e[2] * n end
        end
    end
    for id, n in pairs(PT.WatchItems() or {}) do need[id] = (need[id] or 0) + n end
    local out = {}
    for id, n in pairs(need) do
        local mine, others = PT.Have(id)
        out[#out + 1] = { id = id, need = n, mine = mine, others = others,
            missing = math.max(0, n - mine), price = PT.Price(id) }
    end
    table.sort(out, function(a, b)
        if (a.missing > 0) ~= (b.missing > 0) then return a.missing > 0 end
        return a.id < b.id
    end)
    return out
end

--------------------------------------------------
-- Abklingzeiten
--------------------------------------------------

PT.CD_MIN = 600   -- alles darunter ist die globale oder eine kurze Abklingzeit

function PT.CDStore()
    local sd = SD()
    if not sd then return nil end
    sd.profCD = sd.profCD or {}
    local s = sd.profCD
    s.spells, s.chars = s.spells or {}, s.chars or {}
    return s
end

-- Abklingzeit eines Zaubers laut Client: Restsekunden oder nil.
function PT.SpellRemaining(spell)
    local start, dur
    local cs = _G.C_Spell
    if cs and cs.GetSpellCooldown then
        local ok, info = pcall(cs.GetSpellCooldown, spell)
        if ok and type(info) == "table" then start, dur = Plain(info.startTime), Plain(info.duration) end
    elseif _G.GetSpellCooldown then
        local ok, a, b = pcall(_G.GetSpellCooldown, spell)
        if ok then start, dur = Plain(a), Plain(b) end
    end
    if type(start) ~= "number" or type(dur) ~= "number" or not _G.GetTime then return nil end
    if dur < PT.CD_MIN or start <= 0 then return 0 end
    return math.max(0, start + dur - _G.GetTime())
end

-- Alle gelernten Rezepte pruefen, die schon einmal eine Abklingzeit hatten
-- (oder - beim Herstellen - das eine).
function PT.CheckCooldowns(onlySpell)
    local s = PT.CDStore()
    local m = PRO.Memory()
    local me = Me()
    if not (s and m and me) then return end
    s.chars[me] = s.chars[me] or {}
    local mine = s.chars[me]
    local function check(spell)
        local rem = PT.SpellRemaining(spell)
        if rem == nil then return end
        if rem > 0 then
            s.spells[spell] = true
            mine[spell] = Now() + math.floor(rem)
        elseif s.spells[spell] then
            mine[spell] = Now()
        end
    end
    if onlySpell then check(onlySpell) return end
    for spell in pairs(s.spells) do
        if m.known[spell] then check(spell) end
    end
end

function PT.Remaining(at)
    local left = (at or 0) - Now()
    if left <= 0 then return nil end
    local d, h, mi = math.floor(left / 86400), math.floor(left % 86400 / 3600), math.floor(left % 3600 / 60)
    if d > 0 then return d .. " T " .. h .. " Std" end
    if h > 0 then return h .. " Std " .. mi .. " Min" end
    return math.max(1, mi) .. " Min"
end

--------------------------------------------------
-- Seite
--------------------------------------------------

local page
local ROW_H, HEAD_H = 24, 30
local rowPool, headPool, notePool = {}, {}, {}
local used = { row = 0, head = 0, note = 0 }

local function ResetPools()
    for _, pool in ipairs({ rowPool, headPool, notePool }) do
        for _, f in ipairs(pool) do f:Hide() end
    end
    used.row, used.head, used.note = 0, 0, 0
end

local function Tip(row)
    local gt = _G.GameTooltip
    if not gt then return end
    if row.item then
        gt:SetOwner(row, "ANCHOR_RIGHT")
        if gt.SetItemByID then pcall(gt.SetItemByID, gt, row.item) end
        gt:Show()
    elseif row.recipe then
        gt:SetOwner(row, "ANCHOR_RIGHT")
        if gt.SetSpellByID then pcall(gt.SetSpellByID, gt, row.recipe.spell) end
        if row.hint then gt:AddLine(row.hint, C.accent[1], C.accent[2], C.accent[3], true) end
        gt:Show()
    end
end

local editRows = setmetatable({}, { __mode = "k" })
local function Row(body, y, w, left, right, opts)
    opts = opts or {}
    used.row = used.row + 1
    local row = rowPool[used.row]
    if not row then
        row = CreateFrame("Button", nil, body)
        row:SetHeight(ROW_H)
        local hl = row:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints(row)
        hl:SetColorTexture(C.textBright[1], C.textBright[2], C.textBright[3], 0.05)
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(18, 18)
        row.icon:SetPoint("LEFT", row, "LEFT", 2, 0)
        row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        row.right = WeintCodex.Label(row, "", { size = 11, justify = "RIGHT", font = WeintCodex.Fonts.mono })
        row.right:SetPoint("RIGHT", row, "RIGHT", -4, 0)
        row.left = WeintCodex.Label(row, "", { size = 12, font = WeintCodex.Fonts.sansMedium })
        row.left:SetPoint("LEFT", row.icon, "RIGHT", 8, 0)
        row.left:SetPoint("RIGHT", row.right, "LEFT", -8, 0)
        row.left:SetWordWrap(false)
        row:SetScript("OnEnter", Tip)
        row:SetScript("OnLeave", function() if _G.GameTooltip then _G.GameTooltip:Hide() end end)
        row:SetScript("OnClick", function(self, button) if self.onClick then self.onClick(button) end end)
        if row.RegisterForClicks then row:RegisterForClicks("LeftButtonUp", "RightButtonUp") end
        rowPool[used.row] = row
    end
    row:SetParent(body)
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", body, "TOPLEFT", opts.indent or 0, y)
    row:SetWidth(w - (opts.indent or 0))
    row.item, row.recipe, row.hint, row.onClick = opts.item, opts.recipe, opts.hint, opts.onClick
    local tex
    local ci = _G.C_Item
    if opts.item and ci and ci.GetItemIconByID then
        local ok, t = pcall(ci.GetItemIconByID, opts.item)
        tex = ok and Plain(t) or nil
    elseif opts.recipe then
        local r = opts.recipe
        if r.item and ci and ci.GetItemIconByID then
            local ok, t = pcall(ci.GetItemIconByID, r.item)
            tex = ok and Plain(t) or nil
        end
    end
    if tex then row.icon:SetTexture(tex) row.icon:Show()
    elseif opts.item or opts.recipe then row.icon:SetColorTexture(C.surface3[1], C.surface3[2], C.surface3[3], 1) row.icon:Show()
    else row.icon:Hide() end
    if row.icon:IsShown() then
        row.left:SetPoint("LEFT", row.icon, "RIGHT", 8, 0)
    else
        row.left:SetPoint("LEFT", row, "LEFT", 4, 0)
    end
    row.left:SetText(left)
    local c = C[opts.tone or "textNormal"] or C.textNormal
    row.left:SetTextColor(c[1], c[2], c[3])
    -- 6.140.0.0 (Beta-Test: "60x vorgeschlagen - 60 mal klicken zum
    -- Loeschen"): Menge direkt eintippen, × loescht.
    if opts.edit then
        if not editRows[row] then
            editRows[row] = true
            row.wcDel = CreateFrame("Button", nil, row)
            row.wcDel:SetSize(18, 18)
            row.wcDel:SetPoint("RIGHT", row, "RIGHT", -2, 0)
            row.wcDel.t = WeintCodex.Label(row.wcDel, "×", { size = 14, color = "dangerBright", justify = "CENTER" })
            row.wcDel.t:SetPoint("CENTER", row.wcDel, "CENTER", 0, 1)
            row.wcDel:SetScript("OnClick", function(self) local r = self:GetParent() if r.edit then r.edit(0) end end)
            row.wcDel:SetScript("OnEnter", function(self)
                local gt = _G.GameTooltip
                if gt then gt:SetOwner(self, "ANCHOR_RIGHT") gt:SetText("Von der Merkliste nehmen") gt:Show() end
            end)
            row.wcDel:SetScript("OnLeave", function() if _G.GameTooltip then _G.GameTooltip:Hide() end end)
            local eb = CreateFrame("EditBox", nil, row)
            eb:SetSize(44, 18)
            eb:SetPoint("RIGHT", row.wcDel, "LEFT", -6, 0)
            eb:SetAutoFocus(false)
            if eb.SetNumeric then eb:SetNumeric(true) end
            if eb.SetMaxLetters then eb:SetMaxLetters(4) end
            eb:SetFont(WeintCodex.Fonts.mono, 11, "")
            eb:SetJustifyH("CENTER")
            eb:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3])
            local bg = eb:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints(eb)
            bg:SetColorTexture(C.surface3[1], C.surface3[2], C.surface3[3], 1)
            local function commit(self)
                local r = self:GetParent()
                local n = tonumber(self:GetText())
                self:ClearFocus()
                if r.edit and n then r.edit(n) end
            end
            eb:SetScript("OnEnterPressed", commit)
            eb:SetScript("OnEditFocusLost", function(self)
                local r = self:GetParent()
                if r.editValue and tonumber(self:GetText()) ~= r.editValue then commit(self) end
            end)
            eb:SetScript("OnEscapePressed", function(self)
                local r = self:GetParent()
                self:SetText(tostring(r.editValue or ""))
                self:ClearFocus()
            end)
            row.wcBox = eb
        end
        row.edit, row.editValue = opts.edit, opts.editValue
        row.wcBox:SetText(tostring(opts.editValue or ""))
        row.wcBox:Show()
        row.wcDel:Show()
        row.right:ClearAllPoints()
        row.right:SetPoint("RIGHT", row.wcBox, "LEFT", -8, 0)
    else
        if editRows[row] then row.wcBox:Hide() row.wcDel:Hide() end
        row.edit, row.editValue = nil, nil
        row.right:ClearAllPoints()
        row.right:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    end
    row.right:SetText(right or "")
    local rc = C[opts.rightTone or "textMuted"] or C.textMuted
    row.right:SetTextColor(rc[1], rc[2], rc[3])
    row:Show()
    return y - ROW_H
end

local function Note(body, y, w, text)
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
    fs:SetText(text)
    local h = WeintCodex.EstimateLines(text, math.floor(w / (11 * 0.60))) * (11 + 3)
    fs:SetHeight(h)
    fs:Show()
    return y - h - 6
end

local function Head(body, y, w, label, right)
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
    head.right:SetText(right or "")
    head:Show()
    return y - HEAD_H - 4
end

local function Money(c)
    local AP = WeintCodex.UIAuctionPrices
    if AP and AP.Money then return AP.Money(c) end
    return type(c) == "number" and (math.floor(c / 10000) .. "g") or "—"
end

local SUBS = {
    gilde     = "Wer in deiner Gilde und unter deinen Charakteren welches Rezept kann.",
    planer    = "Der günstigste Weg bis zur Obergrenze deiner Fertigkeit – mit Einkaufsliste.",
    merkliste = "Vorgemerkte Rezepte und was dir an Reagenzien noch fehlt.",
    cooldowns = "Welche Rezepte gerade abklingen – für alle deine Charaktere.",
}

local function BuildPage()
    if page then return page end
    local cp = WeintCodex.ContentPanel
    local f = CreateFrame("Frame", nil, cp)
    f:SetAllPoints(cp)
    local PAD_X, PAD_Y = WeintCodex.Metrics.PAD_X, WeintCodex.Metrics.PAD_Y
    f.Head = WeintCodex.PageHead(f, { eyebrow = "Leveln", title = "Berufe", sub = SUBS.gilde, height = 84 })
    PT.AttachBar(f, "gilde")
    local card = WeintCodex.CreateSurface(f, { tone = "plain", radius = 14, backdrop = "bgDark" })
    card:SetPoint("TOPLEFT", f, "TOPLEFT", PAD_X, -(PAD_Y + 84 + PT.BAR_H))
    card:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -PAD_X, PAD_Y)
    f.Card = card
    f.Title = WeintCodex.Label(card, "", { size = 14, color = "textBright", font = WeintCodex.Fonts.sansSemi })
    f.Title:SetPoint("TOPLEFT", card, "TOPLEFT", 20, -16)
    f.Action = WeintCodex.CreateButton(card, { kind = "ghost", text = "", height = 24, size = 11, padding = 20, radius = 0,
        onClick = function() if f.Action.run then f.Action.run() end end })
    f.Action:SetPoint("TOPRIGHT", card, "TOPRIGHT", -16, -12)
    f.Scroll, f.Body = WeintCodex.CreateScrollArea(card, 20, -46, 600, 300, true)
    page = f
    return f
end

local function Skills()
    local skills = PRO.Skills()
    local order = {}
    for _, p in ipairs(P and P.PROFS or {}) do
        if skills[p.key] then order[#order + 1] = p.key end
    end
    return skills, order
end

function PT.DrawGuild(body, w)
    local y = 0
    local g = PT.Guild() or {}
    local f = page
    f.Title:SetText("Berufe der Gilde")
    f.Action:SetText(PT.Sharing() and "Teilen: an" or "Teilen: aus")
    f.Action.run = function() PT.SetSharing(not PT.Sharing()) PT.Draw("gilde") end
    f.Action:Show()
    if not PT.Sharing() then
        y = Note(body, y, w, "Teilen ist aus: deine Rezepte gehen nicht an die Gilde. Was andere teilen, siehst du trotzdem.")
    end
    -- Je Beruf: wer, mit Fertigkeit und Zahl der Rezepte.
    local any = false
    local sd = SD()
    for _, p in ipairs(P and P.PROFS or {}) do
        local people = {}
        for char, m in pairs(sd and sd.professions or {}) do
            if type(m) == "table" and m.scanned and m.scanned[p.key] then
                local n = 0
                for _, r in ipairs(PRO.Recipes(p.key)) do if m.known[r.spell] then n = n + 1 end end
                people[#people + 1] = { name = char:match("^([^-]+)") or char, own = true, n = n }
            end
        end
        for name, profs in pairs(g) do
            local e = profs[p.key]
            if e then
                local n = 0
                for _ in pairs(e.known or {}) do n = n + 1 end
                people[#people + 1] = { name = name, rank = e.rank, max = e.max, n = n, at = e.at }
            end
        end
        if #people > 0 then
            any = true
            table.sort(people, function(a, b) return (a.rank or 0) > (b.rank or 0) end)
            y = Head(body, y, w, PRO.ProfName(p.key), #people == 1 and "1 Person" or (#people .. " Personen"))
            for _, x in ipairs(people) do
                local right = (x.rank and (x.rank .. (x.max and (" / " .. x.max) or "")) or "") .. "   " .. x.n .. " Rezepte"
                y = Row(body, y, w, x.name .. (x.own and "  (dein Charakter)" or ""), right,
                    { tone = x.own and "textBright" or "textNormal" })
            end
            y = y - 8
        end
    end
    if not any then
        y = Note(body, y, w, "Noch niemand bekannt. Öffne einmal dein Berufsfenster – dann kennt WeintCodex deine Rezepte. Was die Gilde kann, kommt von Mitgliedern, die WeintCodex nutzen, nach und nach herein.")
    end
    y = Note(body, y - 6, w, "Wer ein bestimmtes Rezept kann, steht im Tooltip des Gegenstands („Herstellbar von …“) und in den Details eines Rezepts. Geteilt werden nur Beruf, Fertigkeit, gelernte Rezepte und gesehene Händler für Handwerkswaren (Name, Ort, Preis).")
    return y
end

function PT.DrawPlanner(body, w)
    local y = 0
    local f = page
    f.Title:SetText("Planer")
    f.Action:Hide()
    local skills, order = Skills()
    if #order == 0 then
        return Note(body, y, w, "Du hast noch keinen Beruf gelernt.")
    end
    local sel = PRO.Selected and PRO.Selected()
    if sel and skills[sel] then PT.planKey = sel end
    PT.planKey = (PT.planKey and skills[PT.planKey]) and PT.planKey or order[1]
    if #order > 1 then
        f.Action:SetText("Beruf wechseln")
        f.Action.run = function()
            local i = 1
            for k, key in ipairs(order) do if key == PT.planKey then i = k end end
            PT.planKey = order[i % #order + 1]
            PRO.Select(PT.planKey)
            PRO.Show()
        end
        f.Action:Show()
    end
    local key = PT.planKey
    if sel and not skills[sel] then
        y = Note(body, y, w, PRO.ProfName(sel) .. " hast du nicht gelernt – geplant wird " .. PRO.ProfName(key) .. ".")
    end
    local s = skills[key]
    local target, cap = PT.Goal(key, s)
    f.Title:SetText("Planer · " .. PRO.ProfName(key) .. "  " .. s.rank .. " → " .. target)
    if s.rank >= target then return Note(body, y, w, "Nichts mehr zu planen.") end
    local plan = PT.Plan(key, s.rank, target, cap)
    local lines = PT.PlanLines(plan)
    y = Head(body, y, w, "Weg", #lines .. " Schritte")
    -- 6.141.0.0 (Beta-Test: "es muss irgendwo stehen, dass man das anklicken kann").
    y = Note(body, y, w, WeintCodex.ColorText("accent", "Tipp:") .. " Klick auf einen Herstell-Schritt setzt das Rezept mit dieser Anzahl auf die Merkliste – die Materialien dafür stehen dann dort.")
    local risky = false
    for _, l in ipairs(lines) do
        local right = l.right
        if l.crafts then
            local cost = PT.CraftCost(l.recipe)
            right = right .. "   " .. (cost and Money(cost * l.crafts) or "Preis unbekannt")
            if l.step.risky then risky = true end
        end
        y = Row(body, y, w, l.left, right,
            { recipe = l.recipe, tone = l.tone, hint = l.hint .. (l.crafts and ("\nKlick: auf die Merkliste (" .. l.crafts .. "×)") or ""),
              onClick = l.crafts and function() PT.AddWatch(l.recipe.spell, l.crafts) end or nil })
    end
    if risky then
        y = Note(body, y, w, "Grüne Schritte sind Glückssache: die Zahl ist der Durchschnitt, es können deutlich mehr werden. Besser: ein neues Rezept beim Lehrer oder Händler suchen, das dort noch orange oder gelb ist.")
    end
    if plan.gap then
        y = Note(body, y, w, "Ab " .. plan.gap .. " ist jedes deiner Rezepte grau und bringt keinen Punkt mehr – vielleicht gibt es eins beim Händler oder als Fundstück (siehe Rezepte des Berufs).")
    end
    y = y - 8
    y = Head(body, y, w, "Einkaufsliste", plan.unknown > 0 and ("ab " .. Money(plan.total)) or Money(plan.total))
    y = Note(body, y, w, WeintCodex.ColorText("accent", "Tipp:") .. " Klick auf einen Gegenstand setzt ihn auf die Merkliste – oder alles auf einmal:")
    y = Row(body, y, w, "+ Ganze Einkaufsliste auf die Merkliste", "", { tone = "accent",
        onClick = function()
            for _, e in ipairs(plan.shop) do PT.AddWatchItem(e.id, e.count) end
            print(WeintCodex.AC .. "[WeintCodex]|r " .. #plan.shop .. " Gegenstände auf der Merkliste.")
        end })
    for _, e in ipairs(plan.shop) do
        local mine = PT.Have(e.id)
        y = Row(body, y, w, e.count .. "× " .. PRO.ItemName(e.id),
            (mine > 0 and ("hast " .. mine .. "   ") or "") .. (e.price and Money(e.price * e.count) or "Preis unbekannt"),
            { item = e.id, onClick = function()
                PT.AddWatchItem(e.id, e.count)
                print(WeintCodex.AC .. "[WeintCodex]|r " .. e.count .. "× " .. PRO.ItemName(e.id) .. " auf der Merkliste.")
            end })
    end
    y = Note(body, y - 6, w, "Gerechnet wird mit Rezepten, die du kannst oder beim Lehrer lernst, und der Chance auf einen Punkt wie in Classic: orange immer, gelb meist, grün selten, grau nie. Orange und Gelb gehen vor; Grün nur, wenn es nichts anderes gibt. Preise nur aus deinen Auktionspreisen – „Preis unbekannt“ heißt: nie gesehen, nicht umsonst. Klick auf einen Schritt setzt ihn auf die Merkliste.")
    return y
end

function PT.DrawWatch(body, w)
    local y = 0
    local f = page
    f.Title:SetText("Merkliste")
    local watch = PT.Watch() or {}
    local witems = PT.WatchItems() or {}
    f.Action:SetText("Leeren")
    f.Action.run = function() local sd = SD() if sd then sd.profWatch, sd.profWatchItems = {}, {} end PT.selItem = nil PT.Draw("merkliste") end
    f.Action:SetShown(next(watch) ~= nil or next(witems) ~= nil)
    if next(watch) == nil and next(witems) == nil then
        return Note(body, y, w, "Noch nichts vorgemerkt. In den Details eines Rezepts, im Planer (Schritt oder Einkaufsliste) mit einem Klick hinzufügen.")
    end
    local list = {}
    for spell, n in pairs(watch) do
        local r = PT.RecipeBySpell(spell)
        if r then list[#list + 1] = { r = r, n = n } end
    end
    table.sort(list, function(a, b) return a.r.spell < b.r.spell end)
    if #list > 0 then
        y = Head(body, y, w, "Rezepte", #list .. "")
        for _, e in ipairs(list) do
            y = Row(body, y, w, PRO.RecipeName(e.r), PRO.ProfName(e.r.key),
                { recipe = e.r, hint = "Menge rechts eintippen (Enter), × nimmt es heraus. Linksklick: eins mehr · Rechtsklick: eins weniger",
                  editValue = e.n,
                  edit = function(n) PT.AddWatch(e.r.spell, n - (watch[e.r.spell] or 0)) PT.Draw("merkliste") end,
                  onClick = function(button)
                      PT.AddWatch(e.r.spell, button == "RightButton" and -1 or 1)
                      PT.Draw("merkliste")
                  end })
        end
    end
    y = y - 8
    local needs = PT.Needs()
    local cost, unknown = 0, 0
    for _, e in ipairs(needs) do
        if e.missing > 0 then
            if e.price then cost = cost + e.price * e.missing else unknown = unknown + 1 end
        end
    end
    y = Head(body, y, w, "Gegenstände", unknown > 0 and ("fehlt: ab " .. Money(cost)) or ("fehlt: " .. Money(cost)))
    for _, e in ipairs(needs) do
        local right = e.mine .. " / " .. e.need
        if e.others > 0 then right = right .. "  (+" .. e.others .. " Twinks)" end
        if e.missing > 0 then right = right .. "   " .. (e.price and Money(e.price * e.missing) or "Preis unbekannt") end
        y = Row(body, y, w, PRO.ItemName(e.id), right,
            { item = e.id, tone = e.missing > 0 and "textNormal" or "textDim", rightTone = e.missing > 0 and "dangerBright" or "successBright",
              editValue = witems[e.id],
              edit = witems[e.id] and function(n) PT.AddWatchItem(e.id, n - (witems[e.id] or 0)) PT.Draw("merkliste") end or nil,
              onClick = function(button)
                  if button == "RightButton" and witems[e.id] then
                      PT.AddWatchItem(e.id, -witems[e.id])
                      PT.Draw("merkliste")
                      return
                  end
                  PT.SelectItem(e.id)
              end })
    end
    y = Note(body, y - 6, w, "Klick auf einen Gegenstand: Preis, Preisverlauf und Fundorte rechts. Menge eintippen und Enter ändert sie, × nimmt sie heraus. Gezählt: Taschen und Bank dieses Charakters; was deine anderen Charaktere haben, steht in Klammern (Bestand aller Charaktere muss dafür an sein).")
    return y
end

-- Detailbereich eines Gegenstands: Auktionspreis, Verlauf, Fundorte.
local chart
local function Chart(parent, width, hist)
    if not chart then
        chart = CreateFrame("Frame", nil, parent)
        chart.bars, chart.labels = {}, {}
        for i = 1, 7 do
            chart.bars[i] = chart:CreateTexture(nil, "ARTWORK")
            chart.labels[i] = WeintCodex.Label(chart, "", { size = 9, color = "textDim", justify = "CENTER" })
        end
    end
    chart:SetParent(parent)
    chart:SetSize(width, 80)
    local AP = WeintCodex.UIAuctionPrices
    local today = AP and AP.Day and AP.Day() or 0
    local byDay, max = {}, 0
    for _, e in ipairs(hist) do byDay[e[1]] = e[2] if e[2] > max then max = e[2] end end
    local bw = math.floor((width - 6 * 6) / 7)
    for i = 1, 7 do
        local d = today - 7 + i
        local v = byDay[d]
        local b, l = chart.bars[i], chart.labels[i]
        local h = (v and max > 0) and math.max(3, math.floor(56 * v / max)) or 2
        b:ClearAllPoints()
        b:SetPoint("BOTTOMLEFT", chart, "BOTTOMLEFT", (i - 1) * (bw + 6), 16)
        b:SetSize(bw, h)
        local c = v and C.accent or C.surface3
        b:SetColorTexture(c[1], c[2], c[3], v and 0.9 or 0.6)
        l:ClearAllPoints()
        l:SetPoint("TOP", b, "BOTTOM", 0, -3)
        l:SetText(i == 7 and "heute" or ("-" .. (7 - i)))
    end
    chart:Show()
    return chart
end

-- Haendlerliste mit Karte: eine Zeile je Haendler, alle auf der Karte des
-- gewaehlten; Maus ueber eine Zeile laesst ihren Punkt pulsieren.
local vblock
function PT.VendorBlock(parent, width, vs)
    local BP = WeintCodex.BooksPage
    local QM = WeintCodex.QuestMap
    if not vblock then
        vblock = CreateFrame("Frame", nil, parent)
        vblock.rows, vblock.pins = {}, {}
    end
    local f = vblock
    f:SetParent(parent)
    f:SetWidth(width)
    for _, r in ipairs(f.rows) do r:Hide() end
    for _, p in ipairs(f.pins) do p:Hide() end
    local y = 0
    local sel = vs[PT.selVendor] or vs[1]
    local function pinFor(i)
        local p = f.pins[i]
        if not p then
            p = CreateFrame("Frame", nil, f)
            p:SetSize(14, 14)
            p.dot = p:CreateTexture(nil, "OVERLAY")
            p.dot:SetAllPoints(p)
            p.dot:SetTexture("Interface\\AddOns\\WeintCodex\\media\\ui\\disc")
            if p.CreateAnimationGroup then
                local ag = p:CreateAnimationGroup()
                local sc = ag:CreateAnimation("Scale")
                if sc and sc.SetScale then
                    sc:SetScale(1.8, 1.8) sc:SetDuration(0.45)
                    ag:SetLooping("BOUNCE")
                    p.anim = ag
                end
            end
            f.pins[i] = p
        end
        return p
    end
    for i, v in ipairs(vs) do
        local r = f.rows[i]
        if not r then
            r = CreateFrame("Button", nil, f)
            r:SetHeight(34)
            r.sel = r:CreateTexture(nil, "BACKGROUND")
            r.sel:SetAllPoints(r)
            r.sel:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.16)
            local hl = r:CreateTexture(nil, "HIGHLIGHT")
            hl:SetAllPoints(r)
            hl:SetColorTexture(1, 1, 1, 0.06)
            r.a = WeintCodex.Label(r, "", { size = 11, color = "textBright" })
            r.a:SetPoint("TOPLEFT", r, "TOPLEFT", 6, -3)
            r.a:SetPoint("RIGHT", r, "RIGHT", -6, 0)
            r.a:SetWordWrap(false)
            r.b = WeintCodex.Label(r, "", { size = 10, color = "textMuted" })
            r.b:SetPoint("TOPLEFT", r.a, "BOTTOMLEFT", 0, -2)
            r:SetScript("OnEnter", function(self)
                local p = self.pin
                if p and p:IsShown() and p.anim then p.anim:Play() end
            end)
            r:SetScript("OnLeave", function(self)
                local p = self.pin
                if p and p.anim then p.anim:Stop() end
            end)
            r:SetScript("OnClick", function(self)
                PT.selVendor = self.index
                PT.Draw("merkliste")
            end)
            f.rows[i] = r
        end
        r.index = i
        r:ClearAllPoints()
        r:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -y)
        r:SetWidth(width)
        local zone = v.m and QM and QM.MapName and QM.MapName(v.m)
        r.a:SetText(v.n .. (v.t and (" <" .. v.t .. ">") or "") .. (v.s and WeintCodex.ColorText("textDim", "  · von " .. (v.by or "der Gilde")) or ""))
        r.b:SetText((zone or "Ort unbekannt") .. (v.x and string.format(" (%.0f, %.0f)", v.x * 100, v.y * 100) or "")
            .. (v.p and ("  ·  " .. Money(v.p) .. ((v.q and v.q > 1) and (" für " .. v.q) or "")) or ""))
        r.sel:SetShown(v == sel)
        r.pin = nil
        r:Show()
        y = y + 36
    end
    if sel and sel.m and sel.x and BP and BP.MapWidget then
        local w = BP.MapWidget(f, width)
        w:ClearAllPoints()
        w:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -(y + 4))
        BP.PaintMap(w, sel.m, sel.x, sel.y)
        w.ring:Hide()
        w.dot:Hide()
        local W, H = Plain(w:GetWidth()) or width, Plain(w:GetHeight()) or 0
        for i, v in ipairs(vs) do
            if v.m == sel.m and v.x then
                local p = pinFor(i)
                p:SetParent(w)
                p:SetFrameLevel((w:GetFrameLevel() or 1) + 3)
                p:ClearAllPoints()
                p:SetPoint("CENTER", w, "TOPLEFT", W * v.x, -H * v.y)
                local c = (v == sel) and C.gold or C.textBright
                p.dot:SetVertexColor(c[1], c[2], c[3], 1)
                p:Show()
                f.rows[i].pin = p
            end
        end
        y = y + 4 + H
    end
    f:SetHeight(math.max(1, y))
    f:Show()
    PT.vendorShown = #vs
    return f
end

function PT.ItemBlocks(id)
    local blocks = { { type = "header", text = PRO.ItemName(id) } }
    local rows = {}
    local mine, others = PT.Have(id)
    rows[#rows + 1] = { label = "Du hast", value = tostring(mine) }
    if others > 0 then rows[#rows + 1] = { label = "Twinks", value = tostring(others) } end
    local AP = WeintCodex.UIAuctionPrices
    local f = AP and AP.Lookup and AP.Lookup(id)
    if f and type(f.price) == "number" then
        rows[#rows + 1] = { label = "Auktionshaus", value = Money(f.price) }
        if AP.AgeText then rows[#rows + 1] = { label = "Gesehen", value = AP.AgeText(f.day) } end
    else
        rows[#rows + 1] = { label = "Auktionshaus", value = "nie gesehen" }
    end
    blocks[#blocks + 1] = { type = "rows", rows = rows }
    local hist = AP and AP.History and AP.History(id) or {}
    blocks[#blocks + 1] = { type = "divider" }
    blocks[#blocks + 1] = { type = "header", text = "Preis der letzten 7 Tage" }
    if #hist >= 1 then
        blocks[#blocks + 1] = { type = "custom", create = function(parent, width) return Chart(parent, width, hist) end }
        local lo, hi = math.huge, 0
        for _, e in ipairs(hist) do lo = math.min(lo, e[2]) hi = math.max(hi, e[2]) end
        blocks[#blocks + 1] = { type = "text", text = "Niedrigster Preis je Tag, an dem du gescannt hast: " .. Money(lo) .. " bis " .. Money(hi) .. ". Leere Tage: kein Scan." }
    else
        blocks[#blocks + 1] = { type = "text", text = "Noch kein Verlauf – er entsteht mit jedem Scan im Auktionshaus (ab dieser Fassung)." }
    end
    -- Fundorte: Haendler, eigene Sammelstellen, Dungeonbeute aus dem Bestand.
    blocks[#blocks + 1] = { type = "divider" }
    blocks[#blocks + 1] = { type = "header", text = "Wo finde ich das?" }
    local any = false
    local QM0 = WeintCodex.QuestMap
    local BP0 = WeintCodex.BooksPage
    local vs = PT.Vendors(id)
    if vs[1] then
        any = true
        -- 6.138.0.0 (Beta-Test: "beide Haendler auf die Karte, Maus drueber
        -- pulsiert, Klick waehlt fuer den Questpfeil").
        if not (PT.selVendor and vs[PT.selVendor] and PT.selVendorItem == id) then PT.selVendor, PT.selVendorItem = 1, id end
        blocks[#blocks + 1] = { type = "text", text = "Beim Händler – gesehen von dir oder der Gilde (Maus drüber: auf der Karte, Klick: wählen):" }
        blocks[#blocks + 1] = { type = "custom", create = function(parent, width) return PT.VendorBlock(parent, width, vs) end }
        local v = vs[PT.selVendor]
        local QA = WeintCodex.UIQuestArrow
        if v.m and v.x and QA and QA.SetCustom and BP0 and BP0.Pill then
            blocks[#blocks + 1] = { type = "custom", create = function(parent, width)
                if not PT.vendorBtn then PT.vendorBtn = BP0.Pill(parent, "Questpfeil hierhin", { height = 30, size = 12, primary = true }) end
                local b = PT.vendorBtn
                b:SetParent(parent)
                b:SetWidth(width)
                b.label:SetText("Questpfeil zu " .. v.n)
                b:SetScript("OnClick", function() QA.SetCustom({ map = v.m, x = v.x, y = v.y, title = v.n }) end)
                b:Paint(false)
                return b
            end }
        end
    end
    local GA = WeintCodex.UIGatherAtlas
    local where = GA and GA.WhereItem and GA.WhereItem(id) or {}
    local QM = WeintCodex.QuestMap
    local BP = WeintCodex.BooksPage
    if where[1] then
        any = true
        local lines = {}
        for i, e in ipairs(where) do
            if i > 4 then break end
            lines[#lines + 1] = ((QM and QM.MapName and QM.MapName(e.mapID)) or ("Karte " .. e.mapID)) .. ": " .. e.count .. " Fundstellen"
        end
        blocks[#blocks + 1] = { type = "card", lines = lines }
        local e = where[1]
        if BP and BP.MapWidget and not (vs[1] and vs[1].m) then
            blocks[#blocks + 1] = { type = "custom", create = function(parent, width)
                local wdg = BP.MapWidget(parent, width)
                BP.PaintMap(wdg, e.mapID, e.x, e.y)
                return wdg
            end }
        end
        blocks[#blocks + 1] = { type = "text", text = "Aus deinem Sammel-Atlas: Stellen, an denen du (oder deine Gilde) das gesammelt hast." }
    end
    local LB = WeintCodex.LootBook
    if LB and LB.SourceOf then
        local n, bi = LB.SourceOf(id)
        if n then
            any = true
            local inst = LB.Instance(n)
            local b = LB.Bosses(n)[bi]
            blocks[#blocks + 1] = { type = "text", text = "Beute: " .. LB.InstanceName(inst) .. (b and (" – " .. LB.BossName(b)) or "") .. " (aus Classic, in Forever unbestätigt)." }
        end
    end
    if not any then
        blocks[#blocks + 1] = { type = "text", text = "Kein Fundort im Bestand. Sammelst du es selbst, merkt sich der Sammel-Atlas die Stellen; Stoff und Fleisch fallen von Gegnern – wo genau, weiß WeintCodex nicht." }
    end
    return blocks
end

function PT.SelectItem(id)
    PT.selItem = id
    PT.Draw("merkliste")
end

function PT.DrawCooldowns(body, w)
    local y = 0
    local f = page
    f.Title:SetText("Abklingzeiten")
    f.Action:Hide()
    PT.CheckCooldowns()
    local s = PT.CDStore()
    local sd = SD()
    local any = false
    if s then
        local chars = {}
        for char in pairs(s.chars) do chars[#chars + 1] = char end
        table.sort(chars)
        for _, char in ipairs(chars) do
            local m = sd and sd.professions and sd.professions[char]
            local list = {}
            for spell, at in pairs(s.chars[char]) do
                local r = PT.RecipeBySpell(spell)
                if r and (not m or not m.known or m.known[spell]) then list[#list + 1] = { r = r, at = at } end
            end
            if #list > 0 then
                any = true
                table.sort(list, function(a, b) return a.at < b.at end)
                y = Head(body, y, w, char:match("^([^-]+)") or char, "")
                for _, e in ipairs(list) do
                    local left = PT.Remaining(e.at)
                    y = Row(body, y, w, PRO.RecipeName(e.r), left and ("noch " .. left) or "bereit",
                        { recipe = e.r, rightTone = left and "textMuted" or "successBright" })
                end
                y = y - 8
            end
        end
    end
    if not any then
        y = Note(body, y, w, "Noch keine Abklingzeit gesehen. Sobald du ein Rezept mit Abklingzeit herstellst (etwa Transmutieren oder Mondstoff), merkt sich WeintCodex sie – und zeigt sie hier für alle deine Charaktere.")
    end
    return y
end

-- Die Seite "Berufe" mit diesem Werkzeug (nil = Rezepte).
function PT.Show(key)
    PRO.view = key
    PRO.Show()
end

-- Umschalter unter dem Kopf beider Seiten. Die Spalte links ist voll (der
-- Prueflauf haelt sie gegen 780 px), deshalb stehen die Werkzeuge hier.
PT.BAR_H = 46
PT.BAR_ITEMS = { { key = "rezepte", text = "Rezepte" } }
for _, t in ipairs(PT.TOOLS) do PT.BAR_ITEMS[#PT.BAR_ITEMS + 1] = { key = t.key, text = t.label } end
function PT.AttachBar(f, active)
    local sel = 1
    for i, it in ipairs(PT.BAR_ITEMS) do if it.key == active then sel = i end end
    local bar = WeintCodex.CreateSegmentedControl(f, { items = PT.BAR_ITEMS, selected = sel, backdrop = "bgDark",
        onSelect = function(key) PT.Show(key ~= "rezepte" and key or nil) end })
    bar:SetPoint("TOPLEFT", f, "TOPLEFT", WeintCodex.Metrics.PAD_X, -(WeintCodex.Metrics.PAD_Y + 84))
    f.ToolBar = bar
    return bar
end

PT.view = nil
function PT.Draw(key)
    PT.view = key
    PRO.view = key
    local cp = WeintCodex.ContentPanel
    for _, child in pairs({ cp:GetChildren() }) do child:Hide() end
    local f = BuildPage()
    f:Show()
    local label = key
    for _, t in ipairs(PT.TOOLS) do if t.key == key then label = t.label end end
    WeintCodex.SetBreadcrumb("Berufe", label)
    if f.Head and f.Head.Title then f.Head.Title:SetText("Berufe · " .. label) end
    if f.Head and f.Head.Sub and SUBS[key] then f.Head.Sub:SetText(SUBS[key]) end
    for i, it in ipairs(PT.BAR_ITEMS) do if it.key == key and f.ToolBar then f.ToolBar:Select(i) end end
    local nav = WeintCodex.Navigation
    if nav and nav.ClearInspector then nav.ClearInspector() end
    -- 6.134.0.1 (Beta-Test: "das ueberlappt"): erst der Detailbereich, dann
    -- messen - er macht die Karte schmaler.
    if key == "merkliste" and PT.selItem and nav and nav.SetInspector then
        nav.SetInspector(PT.ItemBlocks(PT.selItem))
    end
    local cw = (Plain(f.Card:GetWidth()) or 640) - 40
    local ch = (Plain(f.Card:GetHeight()) or 360) - 62
    f.Scroll:SetSize(cw, math.max(60, ch))
    f.Body:SetWidth(cw - 10)
    ResetPools()
    local w = cw - 14
    local y
    if key == "planer" then y = PT.DrawPlanner(f.Body, w)
    elseif key == "merkliste" then y = PT.DrawWatch(f.Body, w)
    elseif key == "cooldowns" then y = PT.DrawCooldowns(f.Body, w)
    else y = PT.DrawGuild(f.Body, w) end
    f.Body:SetHeight(math.max(1, -(y or 0)))
    PT.lastDraw = { key = key, rows = used.row }
end

-- Bloecke fuer die Details eines Rezepts (modules/professions.lua).
function PT.RecipeBlocks(r, blocks)
    local text = PT.CraftersText(r.spell, 8)
    blocks[#blocks + 1] = { type = "divider" }
    blocks[#blocks + 1] = { type = "header", text = "Wer es kann" }
    blocks[#blocks + 1] = { type = "text", text = text or "Niemand bekannt – weder deine Charaktere noch die Gilde." }
    local BP = WeintCodex.BooksPage
    if BP and BP.Pill then
        blocks[#blocks + 1] = { type = "custom", create = function(parent, width)
            if not PT.watchBtn then PT.watchBtn = BP.Pill(parent, "Auf die Merkliste", { height = 32, size = 12 }) end
            local b = PT.watchBtn
            b:SetParent(parent)
            b:SetWidth(width)
            b:SetScript("OnClick", function()
                PT.AddWatch(r.spell, 1)
                local n = (PT.Watch() or {})[r.spell] or 0
                print(WeintCodex.AC .. "[WeintCodex]|r " .. PRO.RecipeName(r) .. " auf der Merkliste (" .. n .. "×).")
            end)
            b:Paint(false)
            return b
        end }
    end
end

--------------------------------------------------
-- Ereignisse
--------------------------------------------------

local sender = CreateFrame("Frame")
sender:Hide()
PT.sender = sender
local acc = 0
sender:SetScript("OnUpdate", function(self, el)
    acc = acc + el
    if acc < 0.25 then return end
    acc = 0
    if PT.SendNext(_G.GetTime and _G.GetTime() or 0) then self:Hide() end
end)

function PT.ApplyShare()
    local cc = _G.C_ChatInfo
    if PT.Sharing() then
        if cc and cc.RegisterAddonMessagePrefix then pcall(cc.RegisterAddonMessagePrefix, PT.PREFIX) end
    else
        for i = #queue, 1, -1 do queue[i] = nil end
    end
end

local ev = CreateFrame("Frame")
PT.events = ev
for _, e in ipairs({ "PLAYER_ENTERING_WORLD", "CHAT_MSG_ADDON", "UNIT_SPELLCAST_SUCCEEDED", "TRADE_SKILL_SHOW", "CRAFT_SHOW" }) do
    pcall(ev.RegisterEvent, ev, e)
end
local started = false
local shareQueued = false
ev:SetScript("OnEvent", function(_, event, a, b, c, d)
    if event == "CHAT_MSG_ADDON" then
        PT.OnAddonMessage(a, b, c, d)
    elseif event == "PLAYER_ENTERING_WORLD" then
        if started then return end
        started = true
        PT.ApplyShare()
        PT.HookTooltips()
        PT.Prune()
        if _G.C_Timer and _G.C_Timer.After then
            _G.C_Timer.After(10, function() PT.CheckCooldowns() end)
            _G.C_Timer.After(60, function()
                if not (PT.Sharing() and _G.IsInGuild and Plain(_G.IsInGuild())) then return end
                PT.QueueOwn()
                -- Eigene Haendler einmal nach dem Einloggen (hoechstens 40).
                local sd2, k = SD(), 0
                for vid, list in pairs(sd2 and sd2.vendorSeen or {}) do
                    for _, e in ipairs(list) do
                        if not e.s and k < 40 and PT.ShareVendor(vid, e) then k = k + 1 end
                    end
                end
                local cc = _G.C_ChatInfo
                if cc and cc.SendAddonMessage then queue[#queue + 1] = "Q" sender:Show() end
            end)
        end
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local spell = Plain(c)
        if a ~= "player" or type(spell) ~= "number" or not PRO.SpellIndex()[spell] then return end
        if _G.C_Timer and _G.C_Timer.After then _G.C_Timer.After(1, function() PT.CheckCooldowns(spell) end) end
    elseif event == "TRADE_SKILL_SHOW" or event == "CRAFT_SHOW" then
        -- Nach dem Lesen des Berufsfensters die eigenen Rezepte neu teilen
        -- (gebuendelt, hoechstens alle 10 Minuten).
        if shareQueued or Now() - lastQueued < PT.ANSWER_EVERY then return end
        shareQueued = true
        if _G.C_Timer and _G.C_Timer.After then
            _G.C_Timer.After(30, function() shareQueued = false PT.QueueOwn() PT.CheckCooldowns() end)
        end
    end
end)

--------------------------------------------------
-- Weg am Berufsfenster
--------------------------------------------------
-- 6.132.0.0 (Beta-Test: "am Berufsfenster selbst den Weg, was man am besten
-- skillen soll"): neben dem Berufsfenster des Spiels derselbe Plan wie auf
-- der Codex-Seite, fuer den offenen Beruf. Eigene Flaeche, nichts im
-- Fenster des Spiels geaendert; per Knopf ein- und ausklappbar.

PT.SIDE_ROWS = 14
local side

-- Welcher Beruf ist offen? Erst der Client, sonst der letzte Lesedurchgang.
function PT.OpenProfession()
    local ts = _G.C_TradeSkillUI
    if ts and ts.GetBaseProfessionInfo then
        local ok, info = pcall(ts.GetBaseProfessionInfo)
        if ok and type(info) == "table" then
            local id = Plain(info.professionID)
            for _, p in ipairs(P and P.PROFS or {}) do
                if p.line == id then return p.key end
            end
            local key = PRO.KeyByName(Plain(info.professionName))
            if key then return key end
        end
    end
    if _G.GetTradeSkillLine then
        local ok, name = pcall(_G.GetTradeSkillLine)
        local key = ok and PRO.KeyByName(Plain(name)) or nil
        if key then return key end
    end
    local seen = PRO.lastScan and PRO.lastScan.professions
    if seen then for k in pairs(seen) do return k end end
    return nil
end

local function SideHidden()
    local sd = SD()
    return sd and sd.profPathHidden and true or false
end

local function BuildSide(host)
    if side then return side end
    local f = CreateFrame("Frame", nil, host)
    f:SetWidth(300)
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(f)
    local c = C.bgDark or C.surface1
    bg:SetColorTexture(c[1], c[2], c[3], 0.94)
    -- 6.132.0.1: in der Optik der Oberflaeche (Transparent, Holz ...).
    local K = WeintCodex.UIKit
    if K and K.LookFill and K.Border then
        pcall(K.LookFill, bg, 0.94, K.Border(f, 1, 0, 0, 0, 1, "BORDER"))
    end
    f.title = WeintCodex.Label(f, "", { size = 13, color = "textBright", font = WeintCodex.Fonts.sansSemi })
    f.title:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -12)
    f.title:SetPoint("RIGHT", f, "RIGHT", -14, 0)
    f.rows = {}
    for i = 1, PT.SIDE_ROWS do
        local r = CreateFrame("Button", nil, f)
        r:SetHeight(20)
        r:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -36 - (i - 1) * 21)
        r:SetPoint("RIGHT", f, "RIGHT", -14, 0)
        r.right = WeintCodex.Label(r, "", { size = 11, justify = "RIGHT", font = WeintCodex.Fonts.mono })
        r.right:SetPoint("RIGHT", r, "RIGHT", 0, 0)
        r.left = WeintCodex.Label(r, "", { size = 11 })
        r.left:SetPoint("LEFT", r, "LEFT", 0, 0)
        r.left:SetPoint("RIGHT", r.right, "LEFT", -6, 0)
        r.left:SetWordWrap(false)
        r:SetScript("OnEnter", function(self)
            local gt = _G.GameTooltip
            if not (gt and self.hint) then return end
            gt:SetOwner(self, "ANCHOR_RIGHT")
            if self.spell and gt.SetSpellByID then pcall(gt.SetSpellByID, gt, self.spell) end
            gt:AddLine(self.hint, C.textMuted[1], C.textMuted[2], C.textMuted[3], true)
            gt:Show()
        end)
        r:SetScript("OnLeave", function() if _G.GameTooltip then _G.GameTooltip:Hide() end end)
        f.rows[i] = r
    end
    f.note = WeintCodex.Paragraph(f, "", { size = 10, color = "textDim" })
    f.note:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 14, 12)
    f.note:SetWidth(272)
    f.close = WeintCodex.CreateButton(f, { kind = "ghost", text = "×", height = 20, size = 13, padding = 10, radius = 0,
        onClick = function() local sd = SD() if sd then sd.profPathHidden = true end PT.RefreshSide() end })
    f.close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -6, -8)
    -- Knopf am Fenster des Spiels, um den Weg wieder zu zeigen.
    f.open = WeintCodex.CreateButton(host, { kind = "ghost", text = "Skill-Weg", height = 22, size = 11, padding = 14, radius = 0,
        onClick = function() local sd = SD() if sd then sd.profPathHidden = nil end PT.RefreshSide() end })
    f.open:SetPoint("BOTTOMRIGHT", host, "TOPRIGHT", 0, 4)
    side = f
    PT.side = f
    return f
end

local TONES = { orange = "skillOrange", yellow = "skillYellow", green = "skillGreen" }

function PT.FillSide(f, key)
    for _, r in ipairs(f.rows) do r:Hide() end
    local skills = PRO.Skills()
    local s = key and skills[key]
    if not s then
        f.title:SetText("Skill-Weg")
        f.note:SetText("Welcher Beruf offen ist, sagt das Spiel noch nicht – einmal blättern oder neu öffnen.")
        return false
    end
    local target, cap = PT.Goal(key, s)
    f.title:SetText(PRO.ProfName(key) .. " · " .. s.rank .. " → " .. target)
    if s.rank >= target then
        f.note:SetText("Nichts mehr zu planen.")
        return true
    end
    local plan = PT.Plan(key, s.rank, target, cap)
    local lines = PT.PlanLines(plan)
    local n = 0
    for _, l in ipairs(lines) do
        if n >= PT.SIDE_ROWS then break end
        n = n + 1
        local r = f.rows[n]
        r.left:SetText(l.left)
        local c = C[l.tone or "textNormal"] or C.textNormal
        r.left:SetTextColor(c[1], c[2], c[3])
        r.right:SetText(l.right)
        r.spell = l.recipe and l.recipe.spell or nil
        local hint = l.hint
        if l.crafts then
            local need = {}
            for _, e in ipairs(l.recipe.reagents) do need[#need + 1] = (e[2] * l.crafts) .. "× " .. PRO.ItemName(e[1]) end
            hint = hint .. "\nBraucht: " .. table.concat(need, ", ")
        end
        r.hint = hint
        r:Show()
    end
    plan.steps = lines
    local more = #plan.steps - n
    local note = more > 0 and (more .. " weitere Schritte auf der Codex-Seite „Berufe“ → Planer.") or ""
    if plan.gap then
        note = note .. (note ~= "" and " " or "") .. "Ab " .. plan.gap .. " ist jedes deiner Rezepte grau – neues Rezept beim Lehrer oder Händler holen."
    elseif n == 0 then
        note = "Kein Rezept bringt gerade Punkte."
    end
    f.note:SetText(note ~= "" and note or "Orange: sicher ein Punkt. Gelb: meist. Grün: Glückssache.")
    return true
end

-- 6.132.0.1 (Beta-Test: "die Liste muss rechts neben die Unterpunkte"):
-- rechts neben allem, was am Fenster heraussteht (Reiter der Berufe).
PT.TAB_W = 58
function PT.PlaceSide(f, host)
    local right = Plain(host:GetRight())
    local extra = 0
    if type(right) == "number" and host.GetChildren then
        for _, ch in ipairs({ host:GetChildren() }) do
            if ch ~= f and ch ~= f.open and ch.IsShown and ch:IsShown() and ch.GetRight then
                local r = Plain(ch:GetRight())
                if type(r) == "number" and r - right > extra and r - right < 150 then extra = r - right end
            end
        end
    end
    -- Haengen die Reiter nicht am Fenster, Platz fuer sie lassen (im Bild ~56 px).
    if extra < PT.TAB_W then extra = PT.TAB_W end
    f:ClearAllPoints()
    f:SetPoint("TOPLEFT", host, "TOPRIGHT", extra + 6, 0)
    f:SetPoint("BOTTOMLEFT", host, "BOTTOMRIGHT", extra + 6, 0)
    PT.sideOffset = extra + 6
end

function PT.RefreshSide()
    local host = _G.ProfessionsFrame or _G.TradeSkillFrame
    if type(host) ~= "table" or not host.IsShown then return end
    local f = BuildSide(host)
    PT.PlaceSide(f, host)
    local hidden = SideHidden()
    f.open:SetShown(hidden and host:IsShown())
    if hidden or not host:IsShown() then f:Hide() return end
    f:Show()
    PT.FillSide(f, PT.OpenProfession())
end

do
    local sev = CreateFrame("Frame")
    for _, e in ipairs({ "TRADE_SKILL_SHOW", "TRADE_SKILL_LIST_UPDATE", "SKILL_LINES_CHANGED" }) do
        pcall(sev.RegisterEvent, sev, e)
    end
    local queued = false
    sev:SetScript("OnEvent", function()
        if queued then return end
        queued = true
        local function run() queued = false PT.RefreshSide() end
        if _G.C_Timer and _G.C_Timer.After then _G.C_Timer.After(0.5, run) else run() end
    end)
end

--------------------------------------------------
-- Merkliste beim Haendler
--------------------------------------------------
-- 6.135.0.0 (Wunsch: "Handwerksmaterial vom Haendler im Haendlerfenster
-- markieren, damit man es nicht uebersieht"): was auf der Merkliste noch
-- fehlt, leuchtet im Haendlerfenster, und der Tooltip sagt, wie viele.

PT.MERCHANT_SLOTS = 12

-- [Gegenstand] = fehlende Menge (nur > 0).
function PT.Missing()
    local out = {}
    for _, e in ipairs(PT.Needs()) do
        if e.missing > 0 then out[e.id] = e.missing end
    end
    return out
end

local marks = {}
local function Mark(btn)
    local m = marks[btn]
    if m then return m end
    -- 6.137.0.0 (Beta-Test: "muesste noch besser zu sehen sein"): um den
    -- ganzen Platz (Symbol und Name), 3 px Rand, goldener Schimmer darin.
    local area = btn.wcArea or btn
    m = CreateFrame("Frame", nil, area)
    m:SetPoint("TOPLEFT", area, "TOPLEFT", -4, 4)
    m:SetPoint("BOTTOMRIGHT", area, "BOTTOMRIGHT", 4, -4)
    m:SetFrameLevel((area:GetFrameLevel() or 1) + 8)
    local c = C.goldBright or C.accent
    m.fill = m:CreateTexture(nil, "ARTWORK")
    m.fill:SetAllPoints(m)
    m.fill:SetColorTexture(c[1], c[2], c[3], 0.16)
    m.edges = {}
    for i, pt in ipairs({ { "TOPLEFT", "TOPRIGHT", 0, 2 }, { "BOTTOMLEFT", "BOTTOMRIGHT", 0, 2 },
                          { "TOPLEFT", "BOTTOMLEFT", 2, 0 }, { "TOPRIGHT", "BOTTOMRIGHT", 2, 0 } }) do
        local t = m:CreateTexture(nil, "OVERLAY")
        t:SetPoint(pt[1], m, pt[1], 0, 0)
        t:SetPoint(pt[2], m, pt[2], 0, 0)
        if pt[3] > 0 then t:SetWidth(3) else t:SetHeight(3) end
        t:SetColorTexture(c[1], c[2], c[3], 1)
        m.edges[i] = t
    end
    m.tagBg = m:CreateTexture(nil, "OVERLAY", nil, -1)
    m.tagBg:SetColorTexture(c[1], c[2], c[3], 1)
    m.tag = WeintCodex.Label(m, "", { size = 11, color = "bgDark", font = WeintCodex.Fonts.sansSemi })
    m.tag:SetTextColor(0.08, 0.06, 0.03)
    m.tag:SetPoint("TOPRIGHT", m, "TOPRIGHT", -4, -1)
    m.tagBg:SetPoint("TOPLEFT", m.tag, "TOPLEFT", -4, 2)
    m.tagBg:SetPoint("BOTTOMRIGHT", m.tag, "BOTTOMRIGHT", 4, -2)
    -- Pulsieren, damit es nicht uebersehen wird.
    if m.CreateAnimationGroup then
        local ag = m:CreateAnimationGroup()
        local a = ag:CreateAnimation("Alpha")
        if a and a.SetFromAlpha then
            a:SetFromAlpha(1) a:SetToAlpha(0.35) a:SetDuration(0.8) a:SetSmoothing("IN_OUT")
            ag:SetLooping("BOUNCE")
            m.anim = ag
        end
    end
    marks[btn] = m
    return m
end

-- 6.137.0.0 (Beta-Test: "rechts muesste stehen, wo das Holz gekauft
-- wurde, mit Map-Pin"): beim Oeffnen eines Haendlers merken, wer welche
-- Handwerkswaren (Reagenzien eines Rezepts oder Vorgemerktes) verkauft -
-- Name, Titel, Karte und Lage (deine Lage am Haendler), Preis.
PT.VENDOR_KEEP = 3
local reagentSet
local function IsReagent(id)
    if not reagentSet then
        reagentSet = {}
        for _, p in ipairs(P and P.PROFS or {}) do
            for _, r in ipairs(PRO.Recipes(p.key)) do
                for _, e in ipairs(r.reagents) do reagentSet[e[1]] = true end
            end
        end
    end
    return reagentSet[id] or (PT.WatchItems() or {})[id] ~= nil
end
PT.IsReagent = IsReagent

function PT.NpcTitle()
    local ti = _G.C_TooltipInfo
    if not (ti and ti.GetUnit) then return nil end
    local ok, data = pcall(ti.GetUnit, "npc")
    local lines = ok and type(data) == "table" and data.lines
    local l2 = type(lines) == "table" and lines[2] and Plain(lines[2].leftText)
    if type(l2) == "string" and l2 ~= "" and not l2:find("%d") then return l2 end
    return nil
end

function PT.RecordMerchant()
    local sd = SD()
    local name = _G.UnitName and Plain(_G.UnitName("npc"))
    if not (sd and type(name) == "string") then return 0 end
    local K = WeintCodex.UIKit
    local map, x, y
    if K and K.MapPosSlow then map, x, y = K.MapPosSlow() end
    local title = PT.NpcTitle()
    local num = _G.GetMerchantNumItems and Plain(_G.GetMerchantNumItems()) or 0
    sd.vendorSeen = sd.vendorSeen or {}
    local n = 0
    for i = 1, (type(num) == "number" and num or 0) do
        local id
        if _G.GetMerchantItemID then local ok, v = pcall(_G.GetMerchantItemID, i) id = ok and Plain(v) or nil end
        if type(id) == "number" and IsReagent(id) then
            local price, qty
            local cm = _G.C_MerchantFrame
            if cm and cm.GetItemInfo then
                local ok, info = pcall(cm.GetItemInfo, i)
                if ok and type(info) == "table" then price, qty = Plain(info.price), Plain(info.stackCount) end
            elseif _G.GetMerchantItemInfo then
                local ok, _, _, p, q = pcall(_G.GetMerchantItemInfo, i)
                if ok then price, qty = Plain(p), Plain(q) end
            end
            local e = { n = name, t = title, m = map, x = x and math.floor(x * 10000) / 10000,
                y = y and math.floor(y * 10000) / 10000, p = type(price) == "number" and price or nil,
                q = type(qty) == "number" and qty or nil, at = Now() }
            if PT.StoreVendor(id, e) then PT.ShareVendor(id, e) end
            n = n + 1
        end
    end
    return n
end

-- Einen Haendler zu einem Gegenstand ablegen. Eigenes ersetzt alles mit
-- demselben Namen; Geteiltes (e.s) ueberschreibt nie Eigenes. Gibt true
-- zurueck, wenn sich etwas Teilenswertes geaendert hat (neu, Lage, Preis).
function PT.StoreVendor(id, e)
    local sd = SD()
    if not sd then return false end
    sd.vendorSeen = sd.vendorSeen or {}
    local list = sd.vendorSeen[id] or {}
    local changed = true
    for k = #list, 1, -1 do
        local o = list[k]
        if o.n == e.n then
            if e.s and not o.s then return false end
            changed = not (o.m == e.m and o.p == e.p and o.x and e.x and math.abs(o.x - e.x) < 0.01
                and math.abs(o.y - e.y) < 0.01)
            table.remove(list, k)
        end
    end
    table.insert(list, 1, e)
    -- Eigene zuerst behalten, wenn es zu viele werden.
    while #list > PT.VENDOR_KEEP do
        local drop = #list
        for k = #list, 1, -1 do if list[k].s then drop = k break end end
        table.remove(list, drop)
    end
    sd.vendorSeen[id] = list
    return changed
end

-- 6.143.0.0 (Wunsch: "die gefundenen Haendler still auch den anderen
-- mitteilen"): Prefix WCPR wie die Berufe, nur Gilde, mit demselben
-- Schalter (profShare). Nur Gegenstand, Karte, Lage, Preis, Menge, Name
-- und Titel des Haendlers.
PT.VENDOR_QUEUE_MAX = 60
function PT.EncodeVendor(id, e)
    if not (e.m and e.x and e.y and e.n) then return nil end
    if e.n:find("[|%c]") or #e.n > 40 or (e.t and (e.t:find("[|%c]") or #e.t > 40)) then return nil end
    return "V|" .. id .. "|" .. e.m .. "|" .. math.floor(e.x * 10000 + 0.5) .. "|" .. math.floor(e.y * 10000 + 0.5)
        .. "|" .. (e.p or "") .. "|" .. (e.q or "") .. "|" .. e.n .. "|" .. (e.t or "")
end

function PT.DecodeVendor(text)
    if type(text) ~= "string" or #text > 255 then return nil end
    local id, m, x, y, p, q, n, t = text:match("^V|(%d+)|(%d+)|(%d+)|(%d+)|(%d*)|(%d*)|([^|]+)|([^|]*)$")
    id, m, x, y = tonumber(id), tonumber(m), tonumber(x), tonumber(y)
    if not (id and m and x and y) or x > 10000 or y > 10000 or #n > 40 or #t > 40 or n:find("%c") or t:find("%c") then return nil end
    if id > 10000000 or m > 100000 then return nil end
    return id, { n = n, t = t ~= "" and t or nil, m = m, x = x / 10000, y = y / 10000,
        p = tonumber(p), q = tonumber(q), at = Now() }
end

function PT.ShareVendor(id, e)
    if not (PT.Sharing() and _G.IsInGuild and Plain(_G.IsInGuild())) then return false end
    if #queue >= PT.VENDOR_QUEUE_MAX then return false end
    local line = PT.EncodeVendor(id, e)
    if not line then return false end
    queue[#queue + 1] = line
    if PT.sender then PT.sender:Show() end
    return true
end

function PT.Vendors(id)
    local sd = SD()
    return sd and sd.vendorSeen and sd.vendorSeen[id] or {}
end

function PT.MarkMerchant()
    local missing = PT.Missing()
    local n = 0
    for i = 1, PT.MERCHANT_SLOTS do
        local slot = _G["MerchantItem" .. i]
        local btn = _G["MerchantItem" .. i .. "ItemButton"] or slot
        local id
        if type(btn) == "table" and slot and slot.IsShown and slot:IsShown() and btn.GetID then
            local index = Plain(btn:GetID())
            if type(index) ~= "number" or index < 1 then index = i end
            if _G.GetMerchantItemID then
                local ok, v = pcall(_G.GetMerchantItemID, index)
                id = ok and Plain(v) or nil
            end
            if not id and _G.GetMerchantItemLink then
                local ok, link = pcall(_G.GetMerchantItemLink, index)
                link = ok and Plain(link) or nil
                id = type(link) == "string" and tonumber(link:match("item:(%d+)")) or nil
            end
        end
        local need = id and missing[id]
        if type(btn) == "table" and type(slot) == "table" and btn ~= slot then btn.wcArea = slot end
        if type(btn) == "table" then
            if need then
                local m = Mark(btn)
                m.tag:SetText("Merkliste · fehlt " .. need)
                m:Show()
                if m.anim then m.anim:Play() end
                n = n + 1
            elseif marks[btn] then
                if marks[btn].anim then marks[btn].anim:Stop() end
                marks[btn]:Hide()
            end
        end
    end
    PT.merchantMarks = n
    return n
end

do
    local mev = CreateFrame("Frame")
    for _, e in ipairs({ "MERCHANT_SHOW", "MERCHANT_UPDATE", "BAG_UPDATE_DELAYED" }) do pcall(mev.RegisterEvent, mev, e) end
    local hooked = false
    mev:SetScript("OnEvent", function(_, event)
        if not hooked and _G.hooksecurefunc and type(_G.MerchantFrame_UpdateMerchantInfo) == "function" then
            hooked = true
            _G.hooksecurefunc("MerchantFrame_UpdateMerchantInfo", function() pcall(PT.MarkMerchant) end)
        end
        if event == "BAG_UPDATE_DELAYED" and not (_G.MerchantFrame and _G.MerchantFrame:IsShown()) then return end
        if event == "MERCHANT_SHOW" then pcall(PT.RecordMerchant) end
        if _G.C_Timer and _G.C_Timer.After then _G.C_Timer.After(0.1, function() pcall(PT.MarkMerchant) end)
        else pcall(PT.MarkMerchant) end
    end)
end
