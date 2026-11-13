--------------------------------------------------
-- WeintCodex :: Bosskaempfe - Messdaten still teilen (1.10.13.0)
--------------------------------------------------
-- Wunsch des Besitzers: "Daten muessen still mit allen anderen Usern
-- geteilt werden. Hierbei nur die Messdaten und nicht die selbst
-- eingestellten oder angepassten." Siebte Ausnahme der Regel "nichts
-- verlaesst den Client" (CLAUDE.md), auf ausdruecklichen Wunsch.
--
-- WAS RAUSGEHT, und nur das: je Boss des Kompendiums (Schluessel
-- "Dungeon/Boss") und Faehigkeit (Zauber-NUMMER, damit ein englischer
-- Client "Wirbelwind" als "Whirlwind" versteht) die eigene Messung:
-- erster Einsatz und kuerzester Abstand in Zehntelsekunden, wie oft
-- gesehen. Nie eigene Einstellungen (rec.edit), nie Leben/Energie, nie
-- Namen von Spielern, nie Bosse ausserhalb des Kompendiums.
--
-- WOHIN: Addon-Nachrichten (still, nie im Chat) mit Kennung BS.PREFIX an
-- Gilde, Gruppe und einen versteckten eigenen Kanal (BS.CHANNEL), damit
-- es alle WeintCodex-Spieler erreicht. Nie im Kampf, nie waehrend eines
-- Bosskampfes, hoechstens eine Nachricht je BS.SEND_GAP. Schalter
-- bossShare (ab Werk an), Seite "Bosse".
--
-- WAS ANKOMMT: geprueft (Boss im Kompendium, Zahlen in Grenzen, nie von
-- dir), je Absender gemerkt (SavedData.bossShared[Boss][Zauber][Absender],
-- hoechstens BS.MAX_SENDERS). Gezeigt und genutzt wird der MEDIAN der
-- Absender - ein einzelner Ausreisser verschiebt nichts. Eigene Messung
-- und eigene Einstellung gehen immer vor.
--------------------------------------------------

local K = WeintCodex.UIKit
local KEY = "comfort"

WeintCodex.UIBossShare = {}
local BS = WeintCodex.UIBossShare
local BM = WeintCodex.UIBossMod

BS.PREFIX      = "WCBM"
BS.PROTO       = "1"
BS.CHANNEL     = "WCBossmod"
BS.SEND_GAP    = 1.2
BS.BUSY_GAP    = 5
BS.JOIN_DELAY  = 15
BS.LOGIN_DELAY = 60
BS.RECENT_DAYS = 7
BS.MAX_SENDERS = 20
BS.MAX_QUEUE   = 400
BS.stats = { sent = 0, got = 0, taken = 0, refused = 0, queued = 0 }

local function Plain(v) return K.Plain(v) end
local function Now() return (_G.GetTime and Plain(_G.GetTime())) or 0 end
function BS.On() return K.IsActive(KEY) and K.Get(KEY, "bossShare") and true or false end

--------------------------------------------------
-- Kodieren und pruefen
--------------------------------------------------

local function Tenth(v) return type(v) == "number" and math.floor(v * 10 + 0.5) or 0 end

-- "1|S|dungeon/boss|spellID|erst|abstand|n" (Zehntel; Abstand 0 = unbekannt)
function BS.Encode(code, spellID, rec)
    return table.concat({ BS.PROTO, "S", code, tostring(spellID), tostring(Tenth(rec.first)),
        tostring(Tenth(rec.gap)), tostring(math.min(rec.n or 0, 99999)) }, "|")
end

function BS.Decode(text)
    if type(text) ~= "string" or #text > 250 then return nil end
    local proto, kind, code, id, f, g, n = text:match("^(%d+)|(%u)|([%w_]+/[%w_]+)|(%d+)|(%d+)|(%d+)|(%d+)$")
    if proto ~= BS.PROTO or kind ~= "S" then return nil end
    id, f, g, n = tonumber(id), tonumber(f), tonumber(g), tonumber(n)
    if not (id and id > 0 and f and g and n) then return nil end
    -- Grenzen: erster Einsatz bis 15 min, Abstand 2 s bis 10 min, gesehen 1..99999.
    if f > 9000 or (g ~= 0 and (g < 20 or g > 6000)) or n < 1 or n > 99999 then return nil end
    if not (BM.EnglishName and BM.EnglishName(code)) then return nil end
    return { code = code, id = id, first = f / 10, gap = g > 0 and g / 10 or nil, n = n }
end

--------------------------------------------------
-- 1.10.18.0 (Wunsch): auch der ABLAUF eines Kampfes - welche Faehigkeit
-- (Zauber-Nummer) wann (Zehntel ab Pull). In Teilen zu BS.SEQ_PER
-- Eintraegen, hoechstens BS.SEQ_PARTS Teile:
-- "1|Q|dungeon/boss|dauer|teil|teile|id:t,id:t,..."
--------------------------------------------------
BS.SEQ_PER, BS.SEQ_PARTS = 14, 8   -- 14 x "123456:18000," + Kopf < 250 Zeichen

function BS.EncodeSeq(code, d, ids, ts)
    local out = {}
    local total = math.min(BS.SEQ_PARTS, math.ceil(#ids / BS.SEQ_PER))
    for part = 1, total do
        local items = {}
        for i = (part - 1) * BS.SEQ_PER + 1, math.min(#ids, part * BS.SEQ_PER) do
            items[#items + 1] = ids[i] .. ":" .. Tenth(ts[i])
        end
        out[#out + 1] = table.concat({ BS.PROTO, "Q", code, tostring(math.floor(d + 0.5)), tostring(part), tostring(total), table.concat(items, ",") }, "|")
    end
    return out
end

function BS.DecodeSeq(text)
    if type(text) ~= "string" or #text > 250 then return nil end
    local proto, code, d, part, total, body = text:match("^(%d+)|Q|([%w_]+/[%w_]+)|(%d+)|(%d+)|(%d+)|([%d:,]+)$")
    if proto ~= BS.PROTO then return nil end
    d, part, total = tonumber(d), tonumber(part), tonumber(total)
    if not (d and part and total) or d < 1 or d > 1800 or part < 1 or total < 1 or part > total or total > BS.SEQ_PARTS then return nil end
    if not (BM.EnglishName and BM.EnglishName(code)) then return nil end
    local ids, ts, last = {}, {}, -1
    for id, t in body:gmatch("(%d+):(%d+)") do
        id, t = tonumber(id), tonumber(t)
        if not (id and id > 0 and t and t <= 18000 and t >= last) then return nil end
        last = t
        ids[#ids + 1], ts[#ts + 1] = id, t / 10
    end
    if #ids == 0 or #ids > BS.SEQ_PER then return nil end
    return { code = code, d = d, part = part, total = total, ids = ids, ts = ts }
end

-- Teile sammeln (nur im Speicher); vollstaendig -> je Absender gemerkt.
local seqParts = {}
function BS.TakeSeq(d, sender)
    local store = BS.Store()
    if not store or not d or type(sender) ~= "string" then return false end
    local k = sender .. "@" .. d.code
    local p = seqParts[k]
    if not p or p.d ~= d.d or p.total ~= d.total then p = { d = d.d, total = d.total, got = 0, parts = {} } seqParts[k] = p end
    if not p.parts[d.part] then p.got = p.got + 1 end
    p.parts[d.part] = d
    if p.got < p.total then return false end
    seqParts[k] = nil
    local ids, ts = {}, {}
    for i = 1, p.total do
        local q = p.parts[i]
        for j = 1, #q.ids do ids[#ids + 1], ts[#ts + 1] = q.ids[j], q.ts[j] end
    end
    for i = 2, #ts do if ts[i] < ts[i - 1] then return false end end
    store[d.code] = store[d.code] or {}
    local all = store[d.code]
    all._seq = type(all._seq) == "table" and all._seq or {}
    local seqs = all._seq
    if not seqs[sender] then
        local count, oldest, oldestT = 0, nil, nil
        for who, v in pairs(seqs) do
            count = count + 1
            if not oldestT or (v.at or 0) < oldestT then oldest, oldestT = who, v.at or 0 end
        end
        if count >= BS.MAX_SENDERS and oldest then seqs[oldest] = nil end
    end
    seqs[sender] = { d = p.d, i = ids, t = ts, at = (_G.time and _G.time()) or 0 }
    return true
end

local function SpellName(id)
    if _G.C_Spell and _G.C_Spell.GetSpellName then
        local ok, nm = pcall(_G.C_Spell.GetSpellName, id)
        return ok and Plain(nm) or nil
    elseif _G.GetSpellInfo then
        local ok, nm = pcall(_G.GetSpellInfo, id)
        return ok and Plain(nm) or nil
    end
end

-- Der laengste geteilte Ablauf, mit den Namen DEINES Clients.
function BS.SharedSeq(code, st)
    local store = BS.Store()
    local all = store and type(code) == "string" and store[code]
    local seqs = type(all) == "table" and all._seq
    if type(seqs) ~= "table" then return nil end
    local best
    for _, v in pairs(seqs) do
        if type(v) == "table" and type(v.i) == "table" and type(v.t) == "table" and (not best or (v.d or 0) > (best.d or 0)) then best = v end
    end
    if not best then return nil end
    local byId = {}
    if type(st) == "table" then
        for name, rec in pairs(st) do if type(rec) == "table" and type(name) == "string" and rec.id then byId[rec.id] = name end end
    end
    local s, t = {}, {}
    for i = 1, #best.i do
        local name = byId[best.i[i]] or SpellName(best.i[i])
        if type(name) == "string" and name ~= "" then s[#s + 1], t[#t + 1] = name, best.t[i] end
    end
    if #s < (BM.SEQ_MIN or 3) then return nil end
    return { v = BM.SEQ_V, d = best.d, s = s, t = t, shared = true }
end

--------------------------------------------------
-- Gespeichertes von anderen
--------------------------------------------------

function BS.Store()
    local sd = WeintCodex.SavedData
    if type(sd) ~= "table" then return nil end
    sd.bossShared = sd.bossShared or {}
    return sd.bossShared
end

local function Short(sender) return type(sender) == "string" and sender:match("^[^-]+") or sender end
function BS.IsMe(sender)
    local me = _G.UnitName and Plain(_G.UnitName("player"))
    if type(sender) ~= "string" or type(me) ~= "string" then return false end
    local mine = K.CharKey and K.CharKey()
    return sender == me or sender == mine or (Short(sender) == me and not sender:find("-", 1, true))
end

function BS.Take(d, sender)
    local store = BS.Store()
    if not store or not d or type(sender) ~= "string" then return false end
    store[d.code] = store[d.code] or {}
    local bySpell = store[d.code]
    bySpell[d.id] = bySpell[d.id] or {}
    local senders = bySpell[d.id]
    local stamp = (_G.time and _G.time()) or 0
    if not senders[sender] then
        local count, oldest, oldestT = 0, nil, nil
        for who, v in pairs(senders) do
            count = count + 1
            if not oldestT or (v.t or 0) < oldestT then oldest, oldestT = who, v.t or 0 end
        end
        if count >= BS.MAX_SENDERS and oldest then senders[oldest] = nil end
    end
    senders[sender] = { f = d.first, g = d.gap, n = d.n, t = stamp }
    return true
end

local function Median(list)
    if #list == 0 then return nil end
    table.sort(list)
    local m = math.floor((#list + 1) / 2)
    if #list % 2 == 0 then return (list[m] + list[m + 1]) / 2 end
    return list[m]
end

-- Was andere fuer diesen Boss und Zauber gemessen haben: Median, Summe, Anzahl.
function BS.Shared(code, spellID)
    local store = BS.Store()
    local senders = store and type(code) == "string" and store[code] and store[code][spellID]
    if type(senders) ~= "table" then return nil end
    local fs, gs, n, who = {}, {}, 0, 0
    for _, v in pairs(senders) do
        who = who + 1
        if type(v.f) == "number" then fs[#fs + 1] = v.f end
        if type(v.g) == "number" then gs[#gs + 1] = v.g end
        n = n + (tonumber(v.n) or 0)
    end
    if who == 0 then return nil end
    return { first = Median(fs), gap = Median(gs), n = n, players = who }
end

-- Faehigkeiten, die nur andere gesehen haben, in die eigene Liste des
-- Bosses (unter dem Namen, den DEIN Client fuer die Zauber-Nummer kennt).
function BS.MergeInto(st)
    local store = BS.Store()
    local code = type(st) == "table" and st._codex
    if not store or type(code) ~= "string" or type(store[code]) ~= "table" then return 0 end
    local have, n = {}, 0
    for _, rec in pairs(st) do if type(rec) == "table" and rec.id then have[rec.id] = true end end
    for id in pairs(store[code]) do
        if type(id) == "number" and not have[id] then
            local name
            if _G.C_Spell and _G.C_Spell.GetSpellName then
                local ok, nm = pcall(_G.C_Spell.GetSpellName, id)
                name = ok and Plain(nm) or nil
            elseif _G.GetSpellInfo then
                local ok, nm = pcall(_G.GetSpellInfo, id)
                name = ok and Plain(nm) or nil
            end
            if type(name) == "string" and name ~= "" and name:sub(1, 1) ~= "_" and type(st[name]) ~= "table" then
                st[name] = { id = id }
                n = n + 1
            end
        end
    end
    return n
end

--------------------------------------------------
-- Senden
--------------------------------------------------

local queue, qHead, nextSend = {}, 1, 0
BS.queue = queue

local function ChannelId()
    if not _G.GetChannelName then return nil end
    local ok, id = pcall(_G.GetChannelName, BS.CHANNEL)
    id = ok and Plain(id)
    return (type(id) == "number" and id > 0) and id or nil
end

-- Wohin: Gilde, Gruppe, eigener Kanal - je eine Nachricht.
function BS.Targets(out)
    for i = #out, 1, -1 do out[i] = nil end
    if _G.IsInGuild and K.Bool(_G.IsInGuild(), false) then out[#out + 1] = "GUILD" end
    if _G.IsInRaid and K.Bool(_G.IsInRaid(), false) then out[#out + 1] = "RAID"
    elseif _G.IsInGroup and K.Bool(_G.IsInGroup(), false) then out[#out + 1] = "PARTY" end
    if ChannelId() then out[#out + 1] = "CHANNEL" end
    return out
end

local targets = {}
local function Queue(msg)
    if #queue - qHead + 1 >= BS.MAX_QUEUE then return false end
    for _, dist in ipairs(BS.Targets(targets)) do
        queue[#queue + 1] = { msg = msg, dist = dist }
        BS.stats.queued = BS.stats.queued + 1
    end
    return true
end

-- Die eigene Messung eines Bosses anbieten (nach dem Kampf, beim Einloggen).
function BS.ShareBoss(key)
    if not BS.On() or type(key) ~= "string" then return 0 end
    local st = BM.Bosses and BM.Bosses()[key]
    local code = type(st) == "table" and st._codex
    if type(code) ~= "string" or not (BM.EnglishName and BM.EnglishName(code)) then return 0 end
    local n = 0
    for spell, rec in pairs(st) do
        -- Nur eigene Messung: Faehigkeiten mit Nummer, die DU gesehen hast.
        if type(rec) == "table" and type(spell) == "string" and spell:sub(1, 1) ~= "_"
            and type(rec.id) == "number" and type(rec.first) == "number" and (rec.n or 0) > 0 then
            if Queue(BS.Encode(code, rec.id, rec)) then n = n + 1 end
        end
    end
    -- Der eigene Ablauf (nur gemessene, nur mit Zauber-Nummer).
    local q = st._seq
    if type(q) == "table" and q.v == BM.SEQ_V and type(q.s) == "table" and type(q.t) == "table" then
        local ids, ts = {}, {}
        for i = 1, #q.s do
            local rec = st[q.s[i]]
            if type(rec) == "table" and type(rec.id) == "number" and type(q.t[i]) == "number" then
                ids[#ids + 1], ts[#ts + 1] = rec.id, q.t[i]
            end
        end
        if #ids >= (BM.SEQ_MIN or 3) then
            for _, msg in ipairs(BS.EncodeSeq(code, q.d or 0, ids, ts)) do
                if Queue(msg) then n = n + 1 end
            end
        end
    end
    return n
end

function BS.ShareRecent()
    if not BS.On() then return 0 end
    local now = (_G.time and _G.time()) or 0
    local n = 0
    for key, st in pairs(BM.Bosses and BM.Bosses() or {}) do
        if type(st) == "table" and (now - (tonumber(st._last) or 0)) <= BS.RECENT_DAYS * 86400 then
            n = n + BS.ShareBoss(key)
        end
    end
    return n
end

function BS.SendNext(now)
    if qHead > #queue then
        for i = #queue, 1, -1 do queue[i] = nil end
        qHead = 1
        return nil
    end
    if now < nextSend or not BS.On() then return nil end
    -- Nie im Kampf, nie waehrend eines Bosskampfes (12.x sperrt dann ohnehin).
    if (_G.InCombatLockdown and K.Bool(_G.InCombatLockdown(), true)) or BM.fight then return nil end
    local cc = _G.C_ChatInfo
    local send = cc and cc.SendAddonMessage
    if not send then return nil end
    local item = queue[qHead]
    local ok, res
    if item.dist == "CHANNEL" then
        local id = ChannelId()
        if id then ok, res = pcall(send, BS.PREFIX, item.msg, "CHANNEL", tostring(id)) else ok, res = true, 0 end
    else
        ok, res = pcall(send, BS.PREFIX, item.msg, item.dist)
    end
    if ok and (res == nil or res == true or res == 0) then
        queue[qHead] = false
        qHead = qHead + 1
        BS.stats.sent = BS.stats.sent + 1
        nextSend = now + BS.SEND_GAP
        return true
    end
    nextSend = now + BS.BUSY_GAP
    return false
end

--------------------------------------------------
-- Empfangen
--------------------------------------------------

local OK_DIST = { GUILD = true, PARTY = true, RAID = true, INSTANCE_CHAT = true, CHANNEL = true }
function BS.OnMessage(prefix, text, dist, sender)
    prefix, text, dist, sender = Plain(prefix), Plain(text), Plain(dist), Plain(sender)
    if prefix ~= BS.PREFIX or not BS.On() then return nil end
    BS.stats.got = BS.stats.got + 1
    if not OK_DIST[dist] or type(sender) ~= "string" or BS.IsMe(sender) then return nil end
    local q = BS.DecodeSeq(text)
    if q then
        BS.TakeSeq(q, sender)
        BS.stats.taken = BS.stats.taken + 1
        return true
    end
    local d = BS.Decode(text)
    if not d then BS.stats.refused = BS.stats.refused + 1 return false end
    BS.Take(d, sender)
    BS.stats.taken = BS.stats.taken + 1
    return true
end

--------------------------------------------------
-- Kanal und Takt
--------------------------------------------------

-- Beitreten und in keinem Chatfenster zeigen.
function BS.Join()
    if not BS.On() then return false end
    if not ChannelId() then
        local fn = _G.JoinTemporaryChannel or _G.JoinChannelByName
        if fn then pcall(fn, BS.CHANNEL) end
    end
    if _G.ChatFrame_RemoveChannel then
        for i = 1, (_G.NUM_CHAT_WINDOWS or 10) do
            local cf = _G["ChatFrame" .. i]
            if cf then pcall(_G.ChatFrame_RemoveChannel, cf, BS.CHANNEL) end
        end
    end
    return ChannelId() ~= nil
end

function BS.StatusLine()
    local s = BS.stats
    return string.format("Bosskämpfe teilen: %s, Kanal %s · gesendet %d (in der Schlange %d) · empfangen %d, übernommen %d, verworfen %d",
        BS.On() and "an" or "aus", ChannelId() and "verbunden" or "nicht verbunden",
        s.sent, math.max(0, #queue - qHead + 1), s.got, s.taken, s.refused)
end

local ev = CreateFrame("Frame")
BS.ev = ev
local loginAt
pcall(ev.RegisterEvent, ev, "PLAYER_LOGIN")
pcall(ev.RegisterEvent, ev, "CHAT_MSG_ADDON")
ev:SetScript("OnEvent", WeintCodex.Measured("Bosskämpfe: teilen", function(_, event, a1, a2, a3, a4)
    if event == "PLAYER_LOGIN" then
        local cc = _G.C_ChatInfo
        local reg = (cc and cc.RegisterAddonMessagePrefix) or _G.RegisterAddonMessagePrefix
        if reg then pcall(reg, BS.PREFIX) end
        loginAt = Now()
        return
    end
    if event == "CHAT_MSG_ADDON" and a1 == BS.PREFIX then BS.OnMessage(a1, a2, a3, a4) end
end))
local acc, joined, shared = 0, false, false
ev:SetScript("OnUpdate", WeintCodex.Measured("Bosskämpfe: teilen", function(_, el)
    acc = acc + (el or 0)
    if acc < 0.25 then return end
    acc = 0
    local now = Now()
    if loginAt and BS.On() then
        if not joined and now - loginAt >= BS.JOIN_DELAY then joined = true BS.Join() end
        if not shared and now - loginAt >= BS.LOGIN_DELAY then shared = true BS.ShareRecent() end
    end
    BS.SendNext(now)
end))

local mod = K.Module(KEY)
if mod and mod.defaults.bossShare == nil then mod.defaults.bossShare = true end
