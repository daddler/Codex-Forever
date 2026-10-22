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
    for i = #queue, 1, -1 do queue[i] = nil end
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
            if learned or r.trainer then out[#out + 1] = r end
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
function PT.Plan(key, rank, target)
    local usable = PT.Usable(key)
    local steps, shop = {}, {}
    local cur
    local function costOf(r)
        if r._cost == nil then r._cost = PT.CraftCost(r) or false end
        return r._cost or nil
    end
    for _, r in ipairs(usable) do r._cost = nil end
    local gap
    local function pick(s, allowGreen)
        local best, bestScore, bestKnown
        for _, r in ipairs(usable) do
            local col = PT.Color(r, s)
            if col == "orange" or col == "yellow" or (allowGreen and col == "green") then
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
    for s = rank, target - 1 do
        local best = pick(s, false) or pick(s, true)
        if not best then gap = s break end
        local col = PT.Color(best, s)
        local ch = PT.Chance(best, s)
        if cur and cur.recipe == best and cur.color == col then
            cur.to, cur.crafts = s + 1, cur.crafts + 1 / ch
            cur.minChance = math.min(cur.minChance, ch)
        else
            cur = { from = s, to = s + 1, recipe = best, crafts = 1 / ch, color = col, minChance = ch, risky = col == "green" }
            steps[#steps + 1] = cur
        end
    end
    local total, unknown = 0, 0
    for _, st in ipairs(steps) do
        st.crafts = math.ceil(st.crafts - 0.001)
        for _, e in ipairs(st.recipe.reagents) do shop[e[1]] = (shop[e[1]] or 0) + e[2] * st.crafts end
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
    y = Note(body, y - 6, w, "Wer ein bestimmtes Rezept kann, steht im Tooltip des Gegenstands („Herstellbar von …“) und in den Details eines Rezepts. Geteilt werden nur Beruf, Fertigkeit und gelernte Rezepte.")
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
    PT.planKey = (PT.planKey and skills[PT.planKey]) and PT.planKey or order[1]
    if #order > 1 then
        f.Action:SetText("Beruf wechseln")
        f.Action.run = function()
            local i = 1
            for k, key in ipairs(order) do if key == PT.planKey then i = k end end
            PT.planKey = order[i % #order + 1]
            PT.Draw("planer")
        end
        f.Action:Show()
    end
    local key = PT.planKey
    local s = skills[key]
    local target = s.max or s.rank
    local note
    if s.rank >= target then
        target = math.min(300, s.rank + 75)
        note = "Du bist an der Obergrenze – geplant bis " .. target .. ", nach dem nächsten Rang beim Lehrer."
    end
    f.Title:SetText("Planer · " .. PRO.ProfName(key) .. "  " .. s.rank .. " → " .. target)
    if note then y = Note(body, y, w, note) end
    if s.rank >= target then return Note(body, y, w, "Nichts mehr zu planen.") end
    local plan = PT.Plan(key, s.rank, target)
    y = Head(body, y, w, "Weg", #plan.steps .. " Schritte")
    local TONE = { orange = "skillOrange", yellow = "skillYellow", green = "skillGreen" }
    local risky = false
    for _, st in ipairs(plan.steps) do
        local cost = PT.CraftCost(st.recipe)
        local count = (st.color == "orange" and "" or "ca. ") .. st.crafts .. "× "
        local hint = st.color == "orange" and "Orange: jedes Herstellen bringt einen Punkt."
            or st.color == "yellow" and ("Gelb: meist ein Punkt, zuletzt etwa " .. math.floor(st.minChance * 100 + 0.5) .. " % – die Anzahl ist geschätzt.")
            or ("Grün: nur noch etwa " .. math.floor(st.minChance * 100 + 0.5) .. " % je Herstellen – kein Punkt garantiert, es gibt hier kein oranges oder gelbes Rezept.")
        if st.risky then risky = true end
        y = Row(body, y, w, count .. PRO.RecipeName(st.recipe) .. (st.risky and "  (Glückssache)" or ""),
            st.from .. "–" .. st.to .. "   " .. (cost and Money(cost * st.crafts) or "Preis unbekannt"),
            { recipe = st.recipe, tone = TONE[st.color], hint = hint .. "\nKlick: auf die Merkliste (" .. st.crafts .. "×)",
              onClick = function() PT.AddWatch(st.recipe.spell, st.crafts) end })
    end
    if risky then
        y = Note(body, y, w, "Grüne Schritte sind Glückssache: die Zahl ist der Durchschnitt, es können deutlich mehr werden. Besser: ein neues Rezept beim Lehrer oder Händler suchen, das dort noch orange oder gelb ist.")
    end
    if plan.gap then
        y = Note(body, y, w, "Ab " .. plan.gap .. " ist jedes deiner Rezepte grau und bringt keinen Punkt mehr – vielleicht gibt es eins beim Händler oder als Fundstück (siehe Rezepte des Berufs).")
    end
    y = y - 8
    y = Head(body, y, w, "Einkaufsliste", plan.unknown > 0 and ("ab " .. Money(plan.total)) or Money(plan.total))
    for _, e in ipairs(plan.shop) do
        local mine = PT.Have(e.id)
        y = Row(body, y, w, e.count .. "× " .. PRO.ItemName(e.id),
            (mine > 0 and ("hast " .. mine .. "   ") or "") .. (e.price and Money(e.price * e.count) or "Preis unbekannt"),
            { item = e.id })
    end
    y = Note(body, y - 6, w, "Gerechnet wird mit Rezepten, die du kannst oder beim Lehrer lernst, und der Chance auf einen Punkt wie in Classic: orange immer, gelb meist, grün selten, grau nie. Orange und Gelb gehen vor; Grün nur, wenn es nichts anderes gibt. Preise nur aus deinen Auktionspreisen – „Preis unbekannt“ heißt: nie gesehen, nicht umsonst. Klick auf einen Schritt setzt ihn auf die Merkliste.")
    return y
end

function PT.DrawWatch(body, w)
    local y = 0
    local f = page
    f.Title:SetText("Merkliste")
    local watch = PT.Watch() or {}
    f.Action:SetText("Leeren")
    f.Action.run = function() local sd = SD() if sd then sd.profWatch = {} end PT.Draw("merkliste") end
    f.Action:SetShown(next(watch) ~= nil)
    if next(watch) == nil then
        return Note(body, y, w, "Noch nichts vorgemerkt. In den Details eines Rezepts (Seite des Berufs) oder im Planer mit einem Klick hinzufügen.")
    end
    local list = {}
    for spell, n in pairs(watch) do
        local r = PT.RecipeBySpell(spell)
        if r then list[#list + 1] = { r = r, n = n } end
    end
    table.sort(list, function(a, b) return a.r.spell < b.r.spell end)
    y = Head(body, y, w, "Rezepte", #list .. "")
    for _, e in ipairs(list) do
        y = Row(body, y, w, e.n .. "× " .. PRO.RecipeName(e.r), PRO.ProfName(e.r.key),
            { recipe = e.r, hint = "Linksklick: eins mehr · Rechtsklick: eins weniger",
              onClick = function(button)
                  PT.AddWatch(e.r.spell, button == "RightButton" and -1 or 1)
                  PT.Draw("merkliste")
              end })
    end
    y = y - 8
    local needs = PT.Needs()
    local cost, unknown = 0, 0
    for _, e in ipairs(needs) do
        if e.missing > 0 then
            if e.price then cost = cost + e.price * e.missing else unknown = unknown + 1 end
        end
    end
    y = Head(body, y, w, "Reagenzien", unknown > 0 and ("fehlt: ab " .. Money(cost)) or ("fehlt: " .. Money(cost)))
    for _, e in ipairs(needs) do
        local right = e.mine .. " / " .. e.need
        if e.others > 0 then right = right .. "  (+" .. e.others .. " Twinks)" end
        if e.missing > 0 then right = right .. "   " .. (e.price and Money(e.price * e.missing) or "Preis unbekannt") end
        y = Row(body, y, w, PRO.ItemName(e.id), right,
            { item = e.id, tone = e.missing > 0 and "textNormal" or "textDim", rightTone = e.missing > 0 and "dangerBright" or "successBright" })
    end
    y = Note(body, y - 6, w, "Gezählt: Taschen und Bank dieses Charakters; was deine anderen Charaktere haben, steht in Klammern (Bestand aller Charaktere muss dafür an sein).")
    return y
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
