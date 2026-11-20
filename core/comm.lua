--------------------------------------------------
-- WeintCodex :: Ein Takt fuer alles, was still gesendet wird
--------------------------------------------------
-- 1.0.8.1 (Bild eines Spielers nach dem Update: viermal "Die Anzahl der
-- Nachrichten, die versendet werden koennen, ist begrenzt"): Berufe,
-- Auktionspreise, Sammel-Atlas, Flugspiele, Routen und Bossdaten senden
-- je eine eigene Schlange - jede fuer sich hoechstens etwa eine Nachricht
-- je Sekunde, zusammen aber mehrere. Kurz nach dem Anmelden, wenn alle
-- gleichzeitig teilen, war das mehr, als der Server annimmt, und jede
-- abgewiesene Nachricht stand gelb im Chat.
--
-- Jetzt geht jede stille Nachricht hier durch:
--   * hoechstens COMM.RATE Bytes je Sekunde (mit kleinem Vorrat COMM.BURST)
--     und nie zwei Nachrichten dichter als COMM.GAP;
--   * in einen Kanal (Bossdaten) nur alle COMM.CHANNEL_GAP Sekunden;
--   * sagt das Spiel "zu viel" (Rueckgabewert der Drosselung oder die
--     Meldung ERR_CHAT_THROTTLED), schweigt alles COMM.PAUSE Sekunden.
-- Wer nicht darf, bekommt "warten" zurueck und versucht es spaeter - die
-- Schlangen der Teile bleiben, wie sie sind.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.Comm = {}

local COMM = WeintCodex.Comm

COMM.RATE        = 500    -- Bytes je Sekunde, alle Teile zusammen
COMM.BURST       = 1000   -- so viel darf auf einmal (nach Ruhe)
COMM.GAP         = 0.75   -- Abstand zwischen zwei Nachrichten (s)
COMM.CHANNEL_GAP = 4      -- Abstand fuer Nachrichten in einen Kanal (s)
COMM.PAUSE       = 20     -- Stille nach einer Drosselung durch das Spiel (s)
COMM.OVERHEAD    = 40     -- Bytes, die eine Nachricht ausser dem Text kostet
-- Rueckgabewerte von C_ChatInfo.SendAddonMessage, die "zu viel" heissen:
-- AddonMessageThrottle, ChannelThrottle, GeneralError.
COMM.THROTTLED   = { [3] = true, [8] = true, [9] = true }

COMM.stats = { sent = 0, held = 0, throttled = 0 }

local tokens, lastFill = COMM.BURST, nil
local nextAny, nextChannel, quietUntil = 0, 0, 0

local function Now() return (_G.GetTime and _G.GetTime()) or 0 end
COMM.Now = Now

local function Fill(now)
    if lastFill then
        tokens = math.min(COMM.BURST, tokens + (now - lastFill) * COMM.RATE)
    end
    lastFill = now
end

-- Duerfte jetzt eine Nachricht dieser Laenge gehen?
function COMM.Can(len, dist, now)
    now = now or Now()
    Fill(now)
    if now < quietUntil or now < nextAny then return false end
    if dist == "CHANNEL" and now < nextChannel then return false end
    return tokens >= (len or 0) + COMM.OVERHEAD
end

-- Das Spiel hat gedrosselt: alle still.
function COMM.Quiet(now)
    now = now or Now()
    quietUntil = math.max(quietUntil, now + COMM.PAUSE)
    COMM.stats.throttled = COMM.stats.throttled + 1
end

-- Wie pcall(C_ChatInfo.SendAddonMessage, ...): ok, Ergebnis. Darf gerade
-- nichts gehen, ist das Ergebnis "wait" (fuer die Schlangen: spaeter).
function COMM.Send(prefix, msg, dist, target)
    local cc = _G.C_ChatInfo
    local send = cc and cc.SendAddonMessage
    if not send then return false, "missing" end
    local now = Now()
    local len = type(msg) == "string" and #msg or 0
    if not COMM.Can(len, dist, now) then
        COMM.stats.held = COMM.stats.held + 1
        return true, "wait"
    end
    local ok, res
    if target ~= nil then ok, res = pcall(send, prefix, msg, dist, target)
    else ok, res = pcall(send, prefix, msg, dist) end
    if ok and type(res) == "number" and COMM.THROTTLED[res] then
        COMM.Quiet(now)
        return ok, res
    end
    if ok and (res == nil or res == true or res == 0) then
        tokens = tokens - len - COMM.OVERHEAD
        nextAny = now + COMM.GAP
        if dist == "CHANNEL" then nextChannel = now + COMM.CHANNEL_GAP end
        COMM.stats.sent = COMM.stats.sent + 1
    end
    return ok, res
end

-- Fuer Pruefungen: Takt zuruecksetzen.
function COMM.Reset()
    tokens, lastFill, nextAny, nextChannel, quietUntil = COMM.BURST, nil, 0, 0, 0
    COMM.stats.sent, COMM.stats.held, COMM.stats.throttled = 0, 0, 0
end

function COMM.StatusLine()
    local s = COMM.stats
    return string.format("Stilles Senden: %d gesendet, %d aufgeschoben, %d mal gedrosselt%s",
        s.sent, s.held, s.throttled, Now() < quietUntil and " (gerade still)" or "")
end

-- Meldet das Spiel die Drosselung im Chat, schweigt ebenfalls alles.
do
    local ev = CreateFrame("Frame")
    pcall(ev.RegisterEvent, ev, "CHAT_MSG_SYSTEM")
    ev:SetScript("OnEvent", function(_, _, text)
        -- 1.0.8.2 (Fehlerbericht eines Spielers, Bosskampf): im Kampf ist der
        -- Text geheim - vergleichen verboten. Dann nichts tun.
        local secret = _G.issecretvalue
        if secret and secret(text) then return end
        if type(text) ~= "string" then return end
        local want = _G.ERR_CHAT_THROTTLED
        if type(want) == "string" and want ~= "" and text == want then COMM.Quiet() end
    end)
    COMM.events = ev
end
