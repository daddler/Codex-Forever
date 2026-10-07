--------------------------------------------------
-- WeintCodex :: Auktionspreise von anderen Spielern
--------------------------------------------------
-- Seit 6.18.0.0 (Beta-Test: ForeverGuide zeigte Preise "vor 6 Minuten",
-- ohne dass der Spieler am Auktionshaus war - das Spielernetz von
-- ForeverGuide). Zwei Wege, beide einzeln schaltbar, ab Werk AUS, beide
-- nur mit eingeschalteten Auktionspreisen (ui/auctionprices.lua):
--
--   GILDE (ahShareGuild): Addon-Nachrichten an die Gilde, eigenes Format
--   (Kennung AS.PREFIX). Nach einem eigenen vollstaendigen Scan bietet
--   WeintCodex ihn an ("O"); alle AS.QUERY_EVERY fragt es, wer frischere
--   Preise hat ("Q"); wer mindestens AS.FRESH_GAP frischer ist, bietet an
--   (nach kurzer Zufallspause; wer ein gleich gutes Angebot hoert,
--   schweigt); der Fragende nennt den Besten ("W"), und der schickt seinen
--   Scan in Stuecken an die Gilde ("B") - alle, die ihn brauchen, auf
--   einmal. Gesendet wird nur, was der eigene letzte vollstaendige Scan
--   gesehen hat, nie Weitergereichtes.
--
--   FOREVERGUIDE (ahListenFG): NUR ZUHOEREN. WeintCodex tritt dem
--   versteckten Kanal von ForeverGuide bei (AS.FG_CHANNEL) und liest die
--   Scans, die dort ohnehin fuer alle verschickt werden (Kennung
--   AS.FG_PREFIX, Nachricht "B:1:Seite:Zeit:Nr:id,preis,menge;..." in
--   Basis 36, Zeit nach der Uhr des Servers). Das Format steht im Kopf
--   von ForeverGuide/Net.lua (Stand 1.25.6) - uebernommen ist das Format,
--   kein Code. WeintCodex sendet dort NIE etwas. Aendert ForeverGuide das
--   Format, kommt still nichts mehr an - /wcui pruefen zeigt es.
--
-- REGELN FUER FREMDE PREISE (beide Wege):
--   * Nur vom eigenen Realm (Name-Realm des Absenders) und nie von dir.
--   * Ein ganzer Scan, der nicht frischer ist als deiner, zaehlt nicht.
--   * Je Gegenstand: dein eigener Preis vom selben Tag geht vor; ein
--     neuerer Tag schlaegt einen aelteren.
--   * Mehr als AS.OUTLIER-mal so hoch oder niedrig wie der bekannte Preis:
--     erst, wenn ein zweiter Spieler etwas Aehnliches meldet.
--   * Zeitstempel aus der Zukunft (mehr als 5 Minuten): verworfen.
--   * Im Tooltip "von Spielern"; wer und wann: /wcui auktion.
--
-- GEMESSEN (6.18.0.1, Beta-Test, /wcui auktion): der Kanal antwortet;
-- 3.750 Preise von zwei Spielern in einer Sitzung, 10 Ausreisser
-- zurueckgehalten, Empfang abgeschlossen. UNGEMESSEN: die Gilde (niemand
-- sonst mit WeintCodex), die Drosselung beim Senden, ob der Beitritt eine
-- Zeile im Chat zeigt.
--------------------------------------------------

local K = WeintCodex.UIKit
local KEY = "comfort"
local next = _G.next

WeintCodex.UIAuctionShare = {}
local AS = WeintCodex.UIAuctionShare
local AP = WeintCodex.UIAuctionPrices

AS.PREFIX        = "WCAH"
AS.PROTO         = "1"
AS.FG_PREFIX     = "FGD"
AS.FG_CHANNEL    = "FGLayers"
-- Wie der Kanal im Bericht heisst (6.21.0.0: keine fremden Addons als
-- Quelle nennen). Gemerkt war bis dahin "ForeverGuide" - so steht es noch
-- in gespeicherten Preisen und wird beim Zeigen uebersetzt.
AS.VIA_CHANNEL     = "andere Auktions-Addons"
function AS.ViaName(via)
    if via == "ForeverGuide" then return AS.VIA_CHANNEL end
    return type(via) == "string" and via or "?"
end
AS.FRESH_GAP     = 20 * 60     -- so viel frischer muss ein Angebot sein
AS.OFFER_MAX_AGE = 6 * 3600    -- aeltere eigene Scans bietet niemand an
AS.QUERY_EVERY   = 20 * 60     -- so oft fragt WeintCodex die Gilde
AS.BROADCAST_GAP = 30 * 60     -- dieselbe Seite hoechstens so oft senden
AS.WANT_WAIT     = 4           -- nach dem ersten Angebot so lange auf bessere warten
AS.IDLE          = 12          -- so lange ohne Stueck: Empfang fertig
AS.SEND_GAP      = 1.0         -- eine Nachricht je Sekunde
AS.BUSY_GAP      = 5           -- Spiel nimmt nichts an: so lange warten
AS.OUTLIER       = 3
AS.JOIN_DELAY    = 12          -- nach dem Einloggen erst dann dem Kanal beitreten
AS.FIRST_QUERY   = 20          -- nach dem Einloggen erst dann die Gilde fragen
AS.MAX_HELD      = 2000
AS.TICK          = 0.25

local SIDE_CODE = { Alliance = "A", Horde = "H", Neutral = "N" }
local CODE_SIDE = { A = "Alliance", H = "Horde", N = "Neutral" }

function AS.Guild() return AP.Active() and K.Get(KEY, "ahShareGuild") and true or false end
function AS.Listen() return AP.Active() and K.Get(KEY, "ahListenFG") and true or false end

local function Clock() return (_G.GetTime and K.Plain(_G.GetTime())) or 0 end
local function Time() return (_G.time and _G.time()) or 0 end
local function ServerTime()
    local t = _G.GetServerTime and K.Plain(_G.GetServerTime())
    return type(t) == "number" and t or Time()
end
local function ToLocal(stamp) return Time() - (ServerTime() - stamp) end
local function ToServer(t) return ServerTime() - (Time() - t) end
AS.ToLocal, AS.ToServer = ToLocal, ToServer

AS.log = {}
local function Log(msg)
    if #AS.log >= 12 then table.remove(AS.log, 1) end
    AS.log[#AS.log + 1] = msg
end

AS.stats = { sent = 0, guildIn = 0, fgIn = 0, held = 0, ignored = 0 }
local stats = AS.stats

--------------------------------------------------
-- Basis 36
--------------------------------------------------

local DIGITS = "0123456789abcdefghijklmnopqrstuvwxyz"
function AS.E(n)
    n = math.floor(tonumber(n) or 0)
    if n <= 0 then return "0" end
    local out = ""
    while n > 0 do
        local r = n % 36
        out = DIGITS:sub(r + 1, r + 1) .. out
        n = math.floor(n / 36)
    end
    return out
end
function AS.D(s) return type(s) == "string" and s ~= "" and tonumber(s, 36) or nil end
local E, D = AS.E, AS.D

--------------------------------------------------
-- Absender
--------------------------------------------------

local function Squash(r) return (r:gsub("[%s%-]", "")) end
local function Short(name) return type(name) == "string" and (name:match("^([^%-]+)") or name) or "?" end
AS.Short = Short

-- Von einem anderen Realm (verbundene Realms teilen Kanaele, nicht das
-- Auktionshaus)? Ohne Realm im Namen: der eigene.
function AS.OtherRealm(sender)
    local r = type(sender) == "string" and sender:match("%-(.+)$")
    if not r or r == "" then return false end
    return Squash(r) ~= Squash(AP.Realm())
end

local function MyName()
    local n = _G.UnitName and K.Plain(_G.UnitName("player"))
    return type(n) == "string" and n or "?"
end

function AS.IsMe(sender)
    return Short(sender) == MyName() and not AS.OtherRealm(sender)
end

--------------------------------------------------
-- Wie frisch sind meine Preise? (Uhr des Servers)
--------------------------------------------------

function AS.MyStamp(side)
    local st = AP.Store(side)
    if not st then return 0 end
    local own = st.full and ToServer(st.full) or 0
    local sh = type(st.shared) == "table" and st.shared.stamp or 0
    return math.max(own, sh)
end

-- Eigene vollstaendige Scans, wie frisch (Uhr des Servers) - nur die
-- werden angeboten, nie Weitergereichtes.
local function OwnStamp(side)
    local st = AP.Store(side)
    return st and st.full and ToServer(st.full) or 0
end

--------------------------------------------------
-- Senden: eine Schlange, eine Nachricht je AS.SEND_GAP
--------------------------------------------------

local queue, qHead = {}, 1
local nextSend = 0
AS.queue = queue

local function Queue(msg)
    queue[#queue + 1] = msg
end

function AS.QueueSize() return #queue - qHead + 1 end

local function SendNext(now)
    if qHead > #queue then
        for i = #queue, 1, -1 do queue[i] = nil end
        qHead = 1
        return
    end
    if now < nextSend then return end
    if _G.InCombatLockdown and K.Bool(_G.InCombatLockdown(), true) then return end
    local cc = _G.C_ChatInfo
    if not (cc and cc.SendAddonMessage) or not AS.Guild() then
        for i = #queue, 1, -1 do queue[i] = nil end
        qHead = 1
        return
    end
    local ok, res = pcall(cc.SendAddonMessage, AS.PREFIX, queue[qHead], "GUILD")
    -- Aeltere Clients antworten nichts oder true, neuere mit einer Zahl
    -- (0 = angenommen).
    if ok and (res == nil or res == true or res == 0) then
        queue[qHead] = false
        qHead = qHead + 1
        stats.sent = stats.sent + 1
        nextSend = now + AS.SEND_GAP
    else
        nextSend = now + AS.BUSY_GAP
    end
end

--------------------------------------------------
-- Gilde: fragen, anbieten, waehlen, senden
--------------------------------------------------

local pendingOffer = {}   -- [side] = { at, stamp } - eigenes Angebot, falls keiner zuvorkommt
local offers = {}         -- [side] = { from, stamp } - bestes gehoertes Angebot
local wantAt = {}         -- [side] = Zeitpunkt der Wahl
local lastBroadcast = {}
local lastQuery = 0
AS.pendingOffer, AS.offers = pendingOffer, offers

local function InGuild()
    return _G.IsInGuild and K.Bool(_G.IsInGuild(), false) or false
end

local function Head(kind, side, stamp)
    return kind .. ":" .. AS.PROTO .. ":" .. SIDE_CODE[side] .. ":" .. E(stamp)
end

function AS.Query(side, now)
    if not (AS.Guild() and InGuild()) then return false end
    local stamp = AS.MyStamp(side)
    if stamp > 0 and ServerTime() - stamp < AS.FRESH_GAP then return false end
    lastQuery = now or Clock()
    Queue(Head("Q", side, stamp))
    Log("Gilde gefragt (" .. side .. ")")
    return true
end

local function CountOwn(st, since)
    local n = 0
    for _, v in pairs(st.items) do
        local _, _, day, shared = AP.Unpack(v)
        if not shared and day >= since then n = n + 1 end
    end
    return n
end

function AS.Offer(side)
    if not (AS.Guild() and InGuild()) then return false end
    local st = AP.Store(side)
    local stamp = OwnStamp(side)
    if not st or stamp <= 0 or ServerTime() - stamp > AS.OFFER_MAX_AGE then return false end
    local n = CountOwn(st, AP.Day(st.full))
    if n == 0 then return false end
    Queue(Head("O", side, stamp) .. ":" .. E(n))
    Log("Angeboten (" .. side .. "): " .. n .. " Gegenstände")
    return true
end

-- Den eigenen Scan in Stuecken an die Gilde.
function AS.Broadcast(side, now)
    local st = AP.Store(side)
    local stamp = OwnStamp(side)
    if not st or stamp <= 0 then return 0 end
    now = now or Clock()
    if now - (lastBroadcast[side] or -1e9) < AS.BROADCAST_GAP then return 0 end
    lastBroadcast[side] = now
    local since = AP.Day(st.full)
    local head = Head("B", side, stamp) .. ":"
    local maxLen = 255 - #head - 6
    local seq, parts, len, total = 0, {}, 0, 0
    local function flush()
        if #parts == 0 then return end
        seq = seq + 1
        Queue(head .. E(seq) .. ":" .. table.concat(parts, ";"))
        for i = #parts, 1, -1 do parts[i] = nil end
        len = 0
    end
    for id, v in pairs(st.items) do
        local price, qty, day, shared = AP.Unpack(v)
        if not shared and day >= since and price > 0 then
            local part = E(id) .. "," .. E(price) .. "," .. E(qty)
            if len + #part + 1 > maxLen then flush() end
            parts[#parts + 1] = part
            len = len + #part + 1
            total = total + 1
        end
    end
    flush()
    Log("Gesendet (" .. side .. "): " .. total .. " Gegenstände in " .. seq .. " Nachrichten")
    return total
end

-- Eigener vollstaendiger Scan (aus ui/auctionprices.lua): gleich anbieten.
function AS.OnOwnScan(side)
    if not AS.Guild() then return end
    pendingOffer[side] = { at = Clock() + 5, stamp = OwnStamp(side) }
end
AP.OnOwnScanHook = AS.OnOwnScan

local function OnQuery(side, stamp, now)
    local mine = OwnStamp(side)
    if mine - stamp < AS.FRESH_GAP or ServerTime() - mine > AS.OFFER_MAX_AGE then return end
    if now - (lastBroadcast[side] or -1e9) < AS.BROADCAST_GAP then return end
    pendingOffer[side] = { at = now + 1 + 3 * math.random(), stamp = mine }
end

local function OnOffer(sender, side, stamp, now)
    local p = pendingOffer[side]
    if p and stamp >= p.stamp then pendingOffer[side] = nil end
    if stamp - AS.MyStamp(side) < AS.FRESH_GAP then return end
    local best = offers[side]
    if not best or stamp > best.stamp then offers[side] = { from = sender, stamp = stamp } end
    wantAt[side] = wantAt[side] or (now + AS.WANT_WAIT)
end

local function OnWant(side, name, now)
    if not AS.IsMe(name) then return end
    AS.Broadcast(side, now)
end

--------------------------------------------------
-- Empfangen (Gilde und ForeverGuide)
--------------------------------------------------

local inbound = {}        -- [via .. side .. stamp .. Absender] = { from, via, side, stamp, n, last }
local held, heldN = {}, 0 -- [id] = { p, from } - Ausreisser, wartet auf einen zweiten
AS.inbound, AS.held = inbound, held

-- Ein fremder Preis. true = uebernommen.
function AS.ApplyPrice(st, id, price, qty, day, from)
    if not (id and price and id > 0 and price > 0 and price < 2e9) then return false end
    local v = st.items[id]
    if v then
        local p0, _, day0, shared0 = AP.Unpack(v)
        if day0 > day or (day0 == day and not shared0) then return false end
        if p0 > 0 and (price > p0 * AS.OUTLIER or price * AS.OUTLIER < p0) then
            local h = held[id]
            if h and h.from ~= from and price <= h.p * 2 and price * 2 >= h.p then
                held[id] = nil
                heldN = heldN - 1
            else
                if not h and heldN < AS.MAX_HELD then
                    heldN = heldN + 1
                    held[id] = { p = price, from = from }
                end
                stats.held = stats.held + 1
                return false
            end
        end
    end
    st.items[id] = AP.Pack(price, qty or 0, day, true)
    return true
end

function AS.OnBulk(sender, via, side, stamp, payload, now)
    if AS.OtherRealm(sender) or AS.IsMe(sender) then return 0 end
    if stamp <= AS.MyStamp(side) - 60 then
        stats.ignored = stats.ignored + 1
        return 0
    end
    local t = ToLocal(stamp)
    if t > Time() + 300 then return 0 end
    local st = AP.Store(side, true)
    if not st then return 0 end
    local day = AP.Day(t)
    -- Je Absender: derselbe Scan kann von zweien kommen, und nur ein
    -- zweiter Absender bestaetigt einen Ausreisser.
    local from = Short(sender)
    local key = via .. side .. stamp .. from
    local ib = inbound[key]
    if not ib then
        ib = { from = from, via = via, side = side, stamp = stamp, n = 0 }
        inbound[key] = ib
    end
    ib.last = type(now) == "number" and now or Clock()
    local n = 0
    for a, b, c in payload:gmatch("(%w+),(%w+),(%w+)") do
        if AS.ApplyPrice(st, D(a), D(b), D(c), day, from) then n = n + 1 end
    end
    ib.n = ib.n + n
    if via == AS.VIA_CHANNEL then stats.fgIn = stats.fgIn + n else stats.guildIn = stats.guildIn + n end
    return n
end

local function FinishInbound(now)
    for key, ib in pairs(inbound) do
        if now - ib.last > AS.IDLE then
            inbound[key] = nil
            local st = AP.Store(ib.side)
            if st and ib.n > 0 then
                local sh = type(st.shared) == "table" and st.shared or {}
                -- Unabhaengig von der Reihenfolge, in der pairs() die
                -- Empfaenge liefert: neuer schlaegt aelter, bei gleicher
                -- Zeit mehr Preise, dann der Name.
                local s0, n0 = sh.stamp or 0, sh.n or 0
                if ib.stamp > s0 or (ib.stamp == s0 and (ib.n > n0
                    or (ib.n == n0 and ib.from < (sh.from or "\255")))) then
                    st.shared = { stamp = ib.stamp, at = ToLocal(ib.stamp), from = ib.from, via = ib.via, n = ib.n }
                end
                AS.last = { from = ib.from, via = ib.via, side = ib.side, n = ib.n, at = ToLocal(ib.stamp) }
                Log(ib.via .. ": " .. ib.n .. " Preise von " .. ib.from .. " (" .. ib.side .. ")")
            end
        end
    end
end
AS.FinishInbound = FinishInbound

--------------------------------------------------
-- Kanal von ForeverGuide: beitreten, nur zuhoeren
--------------------------------------------------

AS.joined = false
local joinAt

local function ChannelId()
    if not _G.GetChannelName then return nil end
    local ok, id = pcall(_G.GetChannelName, AS.FG_CHANNEL)
    id = ok and K.Plain(id)
    return (type(id) == "number" and id > 0) and id or nil
end

function AS.Join()
    local cc = _G.C_ChatInfo
    if cc and cc.RegisterAddonMessagePrefix then pcall(cc.RegisterAddonMessagePrefix, AS.FG_PREFIX) end
    if not ChannelId() then
        local fn = _G.JoinTemporaryChannel or _G.JoinChannelByName
        if fn then pcall(fn, AS.FG_CHANNEL) end
    end
    AS.joined = ChannelId() ~= nil
    Log(AS.joined and "Kanal der anderen Auktions-Addons verbunden" or "Kanal der anderen Auktions-Addons: Beitritt ohne Erfolg")
    return AS.joined
end

-- Verlassen nur, wenn ForeverGuide selbst nicht laeuft - sonst gehoert der
-- Kanal ihm.
function AS.Leave()
    if not AS.joined then return end
    AS.joined = false
    local loaded = _G.C_AddOns and _G.C_AddOns.IsAddOnLoaded
    local fg = loaded and K.Bool(loaded("ForeverGuide"), true)
    if not fg and _G.LeaveChannelByName then pcall(_G.LeaveChannelByName, AS.FG_CHANNEL) end
    Log("Kanal der anderen Auktions-Addons verlassen")
end

--------------------------------------------------
-- Nachrichten
--------------------------------------------------

function AS.OnAddonMessage(prefix, text, channel, sender, now)
    prefix, text, channel, sender = K.Plain(prefix), K.Plain(text), K.Plain(channel), K.Plain(sender)
    if type(prefix) ~= "string" or type(text) ~= "string" or type(sender) ~= "string" then return end
    if type(now) ~= "number" then now = Clock() end
    if prefix == AS.FG_PREFIX then
        if channel ~= "CHANNEL" or not AS.Listen() then return end
        local code, stamp, _, payload = text:match("^B:1:([AHN]):(%w+):(%w+):(.*)$")
        if code then AS.OnBulk(sender, AS.VIA_CHANNEL, CODE_SIDE[code], D(stamp) or 0, payload, now) end
        return
    end
    if prefix ~= AS.PREFIX or channel ~= "GUILD" or not AS.Guild() or AS.IsMe(sender) then return end
    local kind, code, stamp36, rest = text:match("^(%u):1:([AHN]):(%w+):?(.*)$")
    local side, stamp = CODE_SIDE[code or ""], D(stamp36)
    if not (side and stamp) then return end
    if kind == "Q" then OnQuery(side, stamp, now)
    elseif kind == "O" then OnOffer(sender, side, stamp, now)
    elseif kind == "W" then OnWant(side, rest, now)
    elseif kind == "B" then
        local payload = rest:match("^%w+:(.*)$")
        if payload then AS.OnBulk(sender, "Gilde", side, stamp, payload, now) end
    end
end

--------------------------------------------------
-- Taktgeber
--------------------------------------------------

local nextQuery
local acc = 0

function AS.Step(now)
    now = now or Clock()
    SendNext(now)
    for side, p in pairs(pendingOffer) do
        if now >= p.at then
            pendingOffer[side] = nil
            AS.Offer(side)
        end
    end
    for side, at in pairs(wantAt) do
        if now >= at then
            wantAt[side] = nil
            local best = offers[side]
            offers[side] = nil
            if best and AS.Guild() then
                Queue(Head("W", side, best.stamp) .. ":" .. best.from)
                Log("Preise von " .. Short(best.from) .. " erbeten (" .. side .. ")")
            end
        end
    end
    if next(inbound) then FinishInbound(now) end
    if AS.Guild() and nextQuery and now >= nextQuery then
        nextQuery = now + AS.QUERY_EVERY
        AS.Query(AP.Faction(), now)
    end
    if AS.Listen() and not AS.joined and joinAt and now >= joinAt then
        joinAt = now + 60
        AS.Join()
    end
end

local drv = CreateFrame("Frame")
drv:Hide()
AS.driver = drv
drv:SetScript("OnUpdate", K.Measured("Auktionspreise teilen", function(_, el)
    acc = acc + (el or 0)
    if acc < AS.TICK then return end
    acc = 0
    AS.Step()
end))

--------------------------------------------------
-- Bericht
--------------------------------------------------

function AS.Lines()
    local out = {}
    out[#out + 1] = "Mit der Gilde teilen: " .. (AS.Guild() and "an" or "aus")
        .. " · gesendet " .. stats.sent .. " Nachrichten · empfangen " .. stats.guildIn .. " Preise"
    out[#out + 1] = "Von anderen Auktions-Addons übernehmen: " .. (AS.Listen() and "an" or "aus")
        .. " · Kanal " .. (AS.joined and "verbunden" or "nicht verbunden")
        .. " · empfangen " .. stats.fgIn .. " Preise"
    if stats.held > 0 or stats.ignored > 0 then
        out[#out + 1] = "Zurückgehalten (Ausreißer): " .. stats.held .. " · verworfen, weil älter als dein Scan: " .. stats.ignored .. " Nachrichten"
    end
    if #AS.log > 0 then
        out[#out + 1] = "Spielernetz, Schritte:"
        for _, m in ipairs(AS.log) do out[#out + 1] = "  " .. m end
    end
    return out
end
AP.ShareLines = AS.Lines

--------------------------------------------------
-- Modul
--------------------------------------------------

local ev = CreateFrame("Frame")
AS.events = ev
ev:SetScript("OnEvent", K.Measured("Auktionspreise teilen", function(_, event, ...)
    if event == "CHAT_MSG_ADDON" then
        -- Nur die ersten vier: das fuenfte ist das Ziel (im Kanal sein Name,
        -- "5. FGLayers") - 6.18.0.0 reichte es als Uhrzeit weiter, und jeder
        -- Takt danach brach ab (Beta-Test, 125x).
        local prefix, text, channel, sender = ...
        AS.OnAddonMessage(prefix, text, channel, sender)
    elseif event == "PLAYER_ENTERING_WORLD" then
        AS.Apply(true)
    end
end))

local function LoggedIn()
    return _G.IsLoggedIn and K.Bool(_G.IsLoggedIn(), false) or false
end

function AS.Apply(entering)
    local guild, listen = AS.Guild(), AS.Listen()
    local on = guild or listen
    local cc = _G.C_ChatInfo
    if on then
        pcall(ev.RegisterEvent, ev, "CHAT_MSG_ADDON")
        pcall(ev.RegisterEvent, ev, "PLAYER_ENTERING_WORLD")
        drv:Show()
    else
        pcall(ev.UnregisterEvent, ev, "CHAT_MSG_ADDON")
        pcall(ev.UnregisterEvent, ev, "PLAYER_ENTERING_WORLD")
        drv:Hide()
    end
    local now = Clock()
    if guild then
        if cc and cc.RegisterAddonMessagePrefix then pcall(cc.RegisterAddonMessagePrefix, AS.PREFIX) end
        if entering or not nextQuery then nextQuery = now + AS.FIRST_QUERY end
    else
        nextQuery = nil
        for k in pairs(pendingOffer) do pendingOffer[k] = nil end
        for k in pairs(offers) do offers[k] = nil end
        for k in pairs(wantAt) do wantAt[k] = nil end
    end
    if listen then
        if not AS.joined then joinAt = now + ((entering or not LoggedIn()) and AS.JOIN_DELAY or 1) end
    else
        joinAt = nil
        AS.Leave()
    end
end

K.Listen(function(kind, key)
    if (kind == "active" or kind == "setting") and key == KEY then AS.Apply() end
end)
