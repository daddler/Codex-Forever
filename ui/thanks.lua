--------------------------------------------------
-- WeintCodex :: Komfort - Danke fuer den Buff (6.39.0.0)
--------------------------------------------------
-- Wunsch aus dem Forum: gibt dir draussen in der Welt ein Fremder einen
-- Buff, fluestert WeintCodex ihm einen Dank - mit einem Augenzwinkern,
-- passend zum Buff (Ausdauer, Willenskraft, Intelligenz, Segen) oder
-- allgemein. Eigene deutsche Saetze, keine Uebersetzung.
--
-- Wann: ein neuer hilfreicher Buff auf dir (UNIT_AURA, addedAuras) mit
-- mindestens einer Minute Dauer (keine Heilung, kein Proc), von einem
-- Spieler, der nicht du ist, nicht in deiner Gruppe, ausserhalb von
-- Instanzen und ausserhalb des Kampfes. Gilde nur auf Wunsch. Derselbe
-- Spieler hoechstens alle 15 Minuten, insgesamt hoechstens alle 20 s.
--
-- GRENZE: wer gebufft hat, nennt der Client nur, wenn er ihn als Einheit
-- kennt (Ziel, Maus, Namensplakette sichtbar ...). Kennt er ihn nicht,
-- bleibt der Dank aus - geraten wird nie.
--
-- SENDEN: ob Forever ein Addon fluestern laesst, ist ungemessen (an die
-- Gilde gesperrt, 6.10.4.6). WeintCodex versucht es; meldet das Spiel eine
-- Sperre, merkt es sich das und legt den Dank ab dann in die Chatzeile -
-- Enter sendet.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIThanks = {}

local TH = WeintCodex.UIThanks
local K  = WeintCodex.UIKit
local C  = WeintCodex.Colors
local KEY = "comfort"

TH.MIN_DURATION = 60
TH.PER_PLAYER = 15 * 60
TH.GLOBAL = 20
TH.BLOCK_WINDOW = 1

TH.LINES = {
    general = {
        "Danke! Möge deine Beute episch und dein Wurf hoch sein.",
        "Danke! Mögen deine Taschen leer und deine Reparaturen billig sein.",
        "Buff erhalten. Gehirnzellen weiterhin optional.",
        "Vielen Dank, edle Seele. Mein nächstes graues Item trägt deinen Namen.",
        "Danke! Möge deine nächste Gruppe die Mechaniken kennen.",
        "Segen über deine Beutetabelle!",
        "Danke! Möge deine Bedrohung niedrig und dein Schaden hoch sein.",
        "Du hast meinen Dank – und meinen nächsten Ruhestein-Moment.",
    },
    stamina = {
        "Danke! Ich fühle mich schon gesünder. Glaube ich.",
        "Mehr Ausdauer! Jetzt halte ich sogar den nächsten Patrouillengegner aus. Vielleicht.",
        "Danke! Meine Lebensleiste hat dich gerade lieb gewonnen.",
    },
    spirit = {
        "Danke! Möge dein Geist niemals gebannt werden.",
        "Willenskraft erhalten. Der Wille war da, jetzt auch die Kraft.",
    },
    intellect = {
        "Danke für die Intelligenz – ich war fast leer.",
        "Hirn-Buff erhalten. Gedanken folgen in Kürze.",
        "Intelligenz erhöht. Gesunder Menschenverstand unverändert.",
    },
    blessing = {
        "Gesegnet seist du. Wortwörtlich.",
        "Möge das Licht deine Segen segnen.",
        "Danke, glänzender Ritter!",
        "Dein Segen ist ein Geschenk. Deine Bubble ein Lebensstil.",
    },
}

TH.KINDS = {
    { value = "general",   text = "Allgemein (jeder andere Buff)" },
    { value = "stamina",   text = "Ausdauer" },
    { value = "spirit",    text = "Willenskraft" },
    { value = "intellect", text = "Intelligenz" },
    { value = "blessing",  text = "Segen" },
}

-- Welche Sorte: nach dem Namen des Buffs, wie der Client ihn nennt.
TH.WORDS = {
    { "stamina",   { "seelenstärke", "ausdauer", "fortitude", "stamina" } },
    { "spirit",    { "göttlicher wille", "willenskraft", "divine spirit", "spirit" } },
    { "intellect", { "intelligenz", "brillanz", "intellect", "brilliance" } },
    { "blessing",  { "segen", "blessing" } },
}

local function Now() return (_G.GetTime and _G.GetTime()) or 0 end

local st = { last = {}, at = -1e9, sendAt = -1e9, sent = 0, queued = 0 }
TH.state = st

-- Fehlerbericht (6.69.0.0, Wunsch: "wenn ein Buff kommt und kein Whisper
-- rausgeht, soll ein Fehler aufploppen wie bei /wcui fenster, den der
-- Nutzer mir schicken kann"). Mitgeschrieben wird jeder Buff, den das
-- Spiel meldet, mit dem, was daraus wurde. Ein FEHLER ist nur, was nicht
-- gewollt ist: Spender oder Name nicht lesbar, keine Saetze, Fluestern
-- gesperrt oder vom Spiel nicht bestaetigt. Gewollte Gruende (Gruppe,
-- Gilde, Kampf, 15 Minuten ...) stehen im Protokoll, ploppen aber nie auf.
TH.TRACE_MAX = 25
TH.REPORT_GAP = 120         -- Sekunden zwischen zwei Berichten
TH.REPORT_MAX = 3           -- Berichte je Sitzung
TH.ECHO_WAIT = 4            -- so lange auf die Bestaetigung des Spiels warten
st.trace, st.reports, st.reportAt = {}, 0, -1e9

local function Clock() return _G.date and _G.date("%H:%M:%S") or "" end
local function Str(v)
    v = K.Plain(v)
    if type(v) == "nil" then return "nil" end
    return tostring(v)
end

function TH.Trace(text)
    local t = st.trace
    t[#t + 1] = Clock() .. "  " .. text
    while #t > TH.TRACE_MAX do table.remove(t, 1) end
end

function TH.AuraText(a)
    if type(a) ~= "table" then return "?" end
    return string.format("%s (ID %s) · Dauer %s · hilfreich %s · Spender %s",
        Str(a.name), Str(a.spellId), Str(a.duration), Str(a.isHelpful), Str(a.sourceUnit))
end

function TH.ReportLines(problem)
    local v, b = "?", "?"
    if _G.GetBuildInfo then
        local ok, ver, build = pcall(_G.GetBuildInfo)
        if ok then v, b = tostring(ver), tostring(build) end
    end
    local cls = _G.UnitClass and select(2, _G.UnitClass("player"))
    local out = {
        "WeintCodex " .. tostring(WeintCodex.Version) .. " · Spiel " .. v .. " (" .. b .. ") · "
            .. tostring(_G.GetLocale and _G.GetLocale() or "?") .. " · Danke für Buffs",
        "Klasse " .. Str(cls) .. " · Stufe " .. Str(_G.UnitLevel and _G.UnitLevel("player"))
            .. " · " .. Str(_G.GetZoneText and _G.GetZoneText())
            .. " · Kampf " .. tostring(K.InCombat() and true or false),
        "Einstellungen: an " .. tostring(TH.Active()) .. " · immer " .. tostring(TH.Always())
            .. " · Gilde " .. tostring(K.Get(KEY, "thanksGuild") and true or false)
            .. " · Instanz " .. tostring(K.Get(KEY, "thanksInstance") and true or false)
            .. " · Wartezeit " .. Str(K.Get(KEY, "thanksDelay"))
            .. " · Flüstern gesperrt " .. tostring(K.Get(KEY, "thanksBlocked") and true or false),
        "Gedankt in dieser Sitzung: " .. st.sent,
        "",
        "PROBLEM: " .. tostring(problem or "keins – Bericht von Hand"),
        "",
        "Letzte Buffs (neueste unten):",
    }
    if #st.trace == 0 then out[#out + 1] = "   keine seit dem Laden" end
    for _, l in ipairs(st.trace) do out[#out + 1] = "   " .. l end
    return out
end

function TH.HintUnknown()
    if st.hinted then return end
    st.hinted = true
    print(WeintCodex.ColorText("accent", "[WeintCodex]")
        .. " Danke: das Spiel hat nicht verraten, wer dich gebufft hat. Fahr in den 90 s danach mit der Maus"
        .. " über den Spieler oder klick ihn an – dann geht der Dank noch raus. Mit Namensplaketten für"
        .. " freundliche Spieler (Einstellungen → Namensplaketten) klappt es von selbst öfter.")
end

function TH.Report(problem)
    return K.ShowReport("Danke für Buffs – Fehlerbericht", TH.ReportLines(problem))
end

-- Ein ungewollter Grund: protokollieren und (gedrosselt) aufploppen.
function TH.Fail(problem)
    TH.Trace("FEHLER: " .. problem)
    if K.Get(KEY, "thanksReport") == false then return false end
    local now = Now()
    if st.reports >= TH.REPORT_MAX or now - st.reportAt < TH.REPORT_GAP then return false end
    st.reports, st.reportAt = st.reports + 1, now
    pcall(TH.Report, problem)
    print(WeintCodex.ColorText("accent", "[WeintCodex]")
        .. " Danke ging nicht raus – Bericht im Fenster, Strg+C kopiert. Schick ihn an WeintCodex.")
    return true
end

function TH.Active()
    return K.IsActive(KEY) and K.Get(KEY, "thanks") ~= false
end


-- 6.41.0.0 (Wunsch: "einsehen, was zu was eingestellt ist, bearbeiten,
-- loeschen, hinzufuegen"): Saetze und Erkennungswoerter je Sorte gehoeren
-- dem Spieler (thanksLines/thanksWords); bis zur ersten Aenderung gelten
-- die von WeintCodex.
-- 6.41.2.0: "Blase" heisst unter Spielern "Bubble" - auch in schon
-- uebernommenen eigenen Listen berichtigt (nur genau dieser Satz).
TH.FIXES = { ["Dein Segen ist ein Geschenk. Deine Blase ein Lebensstil."] = "Dein Segen ist ein Geschenk. Deine Bubble ein Lebensstil." }
function TH.Lines(kind)
    local own = K.Get(KEY, "thanksLines")
    if type(own) == "table" and type(own[kind]) == "table" then
        local list = own[kind]
        for i, t in ipairs(list) do
            if TH.FIXES[t] then list[i] = TH.FIXES[t] end
        end
        return list
    end
    return TH.LINES[kind] or {}
end

-- Zum Bearbeiten: eigene Kopie anlegen (einmal je Sorte).
function TH.OwnLines(kind)
    local own = K.Get(KEY, "thanksLines")
    if type(own) ~= "table" then K.Set(KEY, "thanksLines", {}) own = K.Get(KEY, "thanksLines") end
    if type(own[kind]) ~= "table" then
        own[kind] = {}
        for i, t in ipairs(TH.LINES[kind] or {}) do own[kind][i] = t end
    end
    return own[kind]
end

function TH.Words(kind)
    local own = K.Get(KEY, "thanksWords")
    if type(own) == "table" and type(own[kind]) == "table" then return own[kind] end
    for _, w in ipairs(TH.WORDS) do if w[1] == kind then return w[2] end end
    return {}
end

function TH.SetWords(kind, text)
    local own = K.Get(KEY, "thanksWords")
    if type(own) ~= "table" then K.Set(KEY, "thanksWords", {}) own = K.Get(KEY, "thanksWords") end
    local list = {}
    for w in tostring(text or ""):gmatch("[^,]+") do
        w = w:gsub("^%s+", ""):gsub("%s+$", ""):lower()
        if w ~= "" then list[#list + 1] = w end
    end
    own[kind] = list
end

function TH.Kind(name)
    if type(name) ~= "string" then return "general" end
    local low = name:lower()
    for _, w in ipairs(TH.WORDS) do
        for _, word in ipairs(TH.Words(w[1])) do
            if low:find(word, 1, true) then return w[1] end
        end
    end
    return "general"
end

function TH.Pick(kind, roll)
    local list = TH.Lines(kind)
    -- Ab und zu ein allgemeiner Satz (einstellbar): sonst hoert ein Priester
    -- immer dieselben drei.
    local mix = (tonumber(K.Get(KEY, "thanksMix")) or 30) / 100
    if kind ~= "general" and ((roll or math.random()) < mix or #list == 0) then list = TH.Lines("general") end
    if #list == 0 then return nil end
    return list[math.random(#list)]
end

local function Bool(fn, ...)
    if type(fn) ~= "function" then return false end
    local ok, v = pcall(fn, ...)
    return ok and K.Bool(v, false) or false
end

-- Soll dieser Buff einen Dank bekommen? Liefert den Namen des Spielers.
-- 6.61.25.0 (Beta-Test: "die Danke-Funktion klappt manchmal nicht"): jeder
-- Grund, warum ein Buff keinen Dank bekam, wird gemerkt (TH.state.why) und
-- in der Statuszeile genannt - "manchmal" laesst sich sonst nicht klaeren.
local function No(why) st.why = why return nil end
function TH.Eligible(aura)
    if type(aura) ~= "table" then return nil end
    local helpful = K.Plain(aura.isHelpful)
    if helpful == false then return nil end
    local dur = K.Plain(aura.duration)
    if type(dur) ~= "number" or dur < TH.MIN_DURATION then return nil end
    local src = K.Plain(aura.sourceUnit)
    if type(src) ~= "string" or src == "" then
        No("Spender unbekannt – das Spiel nennt ihn nur, wenn er sichtbar ist (Ziel, Maus, Namensplakette)")
        -- Nur Buffs, die nach Spieler aussehen (eine eigene Sorte: Ausdauer,
        -- Willenskraft, Intelligenz, Segen), sind ein Fehler - Buffs von
        -- NPCs und Gegenstaenden kommen oft ohne Spender.
        -- 6.69.3.0: kein Fehler mehr, sondern eine Grenze des Spiels (Bericht
        -- eines Spielers: "Spender nil" bei Seelenstaerke und Arkaner
        -- Intelligenz). Einmal je Sitzung ein Hinweis, was hilft.
        -- 6.70.0.0: vormerken - das Spiel nennt den Spender spaeter, sobald
        -- er fuer dich eine Einheit wird (TH.Recheck).
        TH.Remember(aura)
        return nil
    end
    if Bool(_G.UnitIsUnit, src, "player") then return nil end
    if not Bool(_G.UnitIsPlayer, src) then return nil end
    if Bool(_G.UnitInParty, src) or Bool(_G.UnitInRaid, src) then return No("Spender in deiner Gruppe") end
    if not K.Get(KEY, "thanksGuild") and Bool(_G.UnitIsInMyGuild, src) then return No("Spender in deiner Gilde (Gilde ist aus)") end
    local name = _G.GetUnitName and K.Plain(_G.GetUnitName(src, true))
    if type(name) ~= "string" or name == "" then
        No("Name des Spenders nicht lesbar")
        st.fail = st.why
        return nil
    end
    return name
end

-- 6.62.1.0 (Wunsch: "Schalter, ob immer gedankt werden soll, auch im
-- Kampf, jedes Buffen"): thanksAlways hebt Kampf, die 20-s-Pause und die
-- 15 Minuten je Spieler auf. Gruppe, Gilde, Instanz und Dauer bleiben.
function TH.Always() return K.Get(KEY, "thanksAlways") and true or false end

function TH.Where()
    if K.InCombat() and not TH.Always() then st.why = "im Kampf" return false end
    if _G.IsInInstance then
        local ok, inside = pcall(_G.IsInInstance)
        -- 6.53.3.0 (Wunsch: "in Instanzen ein-/ausschaltbar, voreingestellt
        -- aus"): bis dahin fest aus.
        if ok and K.Bool(inside, false) and not K.Get(KEY, "thanksInstance") then st.why = "in einer Instanz (dort aus)" return false end
    end
    return true
end

local function OpenChat(text)
    if _G.ChatFrame_OpenChat then pcall(_G.ChatFrame_OpenChat, text) end
end

function TH.Send(name, text)
    local now = Now()
    st.last[name], st.at = now, now
    local whisper = text
    if K.Get(KEY, "thanksBlocked") then
        OpenChat("/w " .. name .. " " .. whisper)
        return "chat"
    end
    st.sendAt = now
    st.blockedNow, st.sysMsg = nil, nil
    local f = (_G.C_ChatInfo and _G.C_ChatInfo.SendChatMessage) or _G.SendChatMessage
    local ok = f and pcall(f, whisper, "WHISPER", nil, name)
    if not ok or st.blockedNow then
        TH.Trace("Flüstern gesperrt – Dank in die Chatzeile gelegt (Enter sendet)")
        OpenChat("/w " .. name .. " " .. whisper)
        return "chat"
    end
    st.sent = st.sent + 1
    TH.Trace("geflüstert an " .. name .. ": " .. whisper)
    st.echo = { name = name, text = whisper, at = now }
    if _G.C_Timer and _G.C_Timer.After then
        local mine = st.echo
        _G.C_Timer.After(TH.ECHO_WAIT, function()
            if st.echo == mine then
                st.echo = nil
                TH.Fail("Flüstern an " .. name .. " abgeschickt, aber das Spiel hat es nicht bestätigt"
                    .. (st.sysMsg and (" – Meldung des Spiels: " .. st.sysMsg) or ""))
            end
        end)
    end
    return "sent"
end

-- Erneuerte Buffs (6.61.25.0): bufft ein Fremder einen Buff, den du schon
-- hast, meldet das Spiel ihn nicht als neu (addedAuras), sondern als
-- geaendert (updatedAuraInstanceIDs). Neu aufgelegt ist er, wenn er wieder
-- (fast) die volle Dauer vor sich hat.
TH.REFRESH_SLACK = 3
function TH.Refreshed(info)
    local out = {}
    local ids = info.updatedAuraInstanceIDs
    local ua = _G.C_UnitAuras
    if type(ids) ~= "table" or not (ua and ua.GetAuraDataByAuraInstanceID) then return out end
    local now = Now()
    for _, id in ipairs(ids) do
        local ok, a = pcall(ua.GetAuraDataByAuraInstanceID, "player", id)
        if ok and type(a) == "table" then
            local dur, exp = K.Plain(a.duration), K.Plain(a.expirationTime)
            if type(dur) == "number" and type(exp) == "number" and dur >= TH.MIN_DURATION
               and exp - now >= dur - TH.REFRESH_SLACK then
                out[#out + 1] = a
            end
        end
    end
    return out
end

function TH.Try(list, now, how)
    for _, aura in ipairs(list) do
        st.why, st.fail = nil, nil
        local name = TH.Eligible(aura)
        local helpful, src = K.Plain(aura.isHelpful), K.Plain(aura.sourceUnit)
        local own = type(src) == "string" and src ~= "" and Bool(_G.UnitIsUnit, src, "player")
        if helpful ~= false and not own and (name or st.why) then
            TH.Trace((how or "neu") .. ": " .. TH.AuraText(aura) .. (name and (" -> " .. name) or (" -> kein Dank: " .. tostring(st.why))))
        end
        if st.fail then TH.Fail(st.fail .. " · " .. TH.AuraText(aura)) end
        if name and not TH.Always() and now - (st.last[name] or -1e9) < TH.PER_PLAYER then
            st.why = name .. " wurde vor weniger als 15 Minuten schon gedankt"
            name = nil
        end
        if name then
            local text = TH.Pick(TH.Kind(K.Plain(aura.name)))
            if not text then
                st.why = "keine Sätze für diese Sorte"
                TH.Fail(st.why .. " · " .. TH.AuraText(aura))
                return true
            end
            st.last[name], st.at = now, now
            st.why = nil
            -- Wartezeit (6.41.0.0, einstellbar): nicht im selben Augenblick
            -- wie der Buff - wirkt menschlicher.
            local delay = tonumber(K.Get(KEY, "thanksDelay")) or 2
            if delay > 0 and _G.C_Timer and _G.C_Timer.After then
                st.queued = st.queued + 1
                _G.C_Timer.After(delay, function()
                    st.queued = st.queued - 1
                    if TH.Active() and (TH.Always() or not K.InCombat()) then TH.Send(name, text)
                    else st.why = "Kampf begann in der Wartezeit" end
                end)
            else
                TH.Send(name, text)
            end
            return true
        end
    end
    return false
end

-- 6.69.3.0 (Fehlerbericht direkt nach dem Login): beim Anmelden, Neuladen
-- und Zonenwechsel meldet das Spiel die Buffs, die man schon traegt, als
-- "neu" (addedAuras). Frisch ist ein Buff nur, wenn er (fast) noch seine
-- volle Dauer vor sich hat - wie bei den erneuerten.
function TH.Fresh(a)
    local dur, exp = K.Plain(a.duration), K.Plain(a.expirationTime)
    if type(dur) ~= "number" or type(exp) ~= "number" or exp == 0 then return true end
    return exp - Now() >= dur - TH.REFRESH_SLACK
end

function TH.OnAura(info)
    if not (TH.Active() and type(info) == "table") then return end
    if K.Plain(info.isFullUpdate) == true then return end
    local added = info.addedAuras
    if type(added) == "table" then
        local fresh = {}
        for _, a in ipairs(added) do
            if type(a) == "table" and TH.Fresh(a) then fresh[#fresh + 1] = a end
        end
        added = fresh
    end
    local fresh = TH.Refreshed(info)
    if type(added) ~= "table" and #fresh == 0 then return end
    if not TH.Where() then TH.Trace("Buff übergangen: " .. tostring(st.why)) return end
    local now = Now()
    if not TH.Always() and now - st.at < TH.GLOBAL then
        st.why = "gerade erst gedankt (höchstens alle 20 s)"
        TH.Trace("Buff übergangen: " .. st.why)
        return
    end
    if type(added) == "table" and TH.Try(added, now, "neu") then return end
    TH.Try(fresh, now, "erneuert")
end

-- Sperre kurz nach dem eigenen Versuch: gemessen, merken.
function TH.OnBlocked(addon)
    if K.Plain(addon) ~= "WeintCodex" or Now() - st.sendAt > TH.BLOCK_WINDOW then return false end
    st.blockedNow = true
    K.Set(KEY, "thanksBlocked", true)
    TH.Fail("das Spiel hat das Flüstern gesperrt (" .. tostring(K.Plain(addon)) .. ") – ab jetzt über die Chatzeile")
    print(WeintCodex.ColorText("accent", "[WeintCodex]")
        .. " Das Spiel lässt WeintCodex nicht selbst flüstern – der Dank steht ab jetzt in der Chatzeile, Enter sendet.")
    return true
end


-- Spaeter danken (6.70.0.0, Wunsch: "wenn man mit der Maus ueber den Buff
-- geht, von wem man das bekommen hat - und das Danke-System zieht sich den
-- Namen raus"). Der Tooltip eines Buffs nennt den Spender nicht; das Spiel
-- merkt ihn sich aber am Buff und nennt ihn (sourceUnit), sobald er fuer
-- dich eine Einheit ist - Ziel, Maus, Namensplakette, Gruppe. Darum wird
-- ein Buff ohne Spender TH.PENDING_TTL Sekunden vorgemerkt und bei jeder
-- Gelegenheit neu gefragt: Zielwechsel, Maus ueber einem Spieler, neue
-- Namensplakette, Maus ueber dem Buff, und einmal je Sekunde.
TH.PENDING_TTL = 90
st.pending = {}

function TH.Remember(aura)
    local id = K.Plain(aura.auraInstanceID)
    if type(id) ~= "number" or st.pending[id] then return end
    st.pending[id] = Now() + TH.PENDING_TTL
    TH.Trace("vorgemerkt: " .. Str(aura.name) .. " – Spender noch unbekannt, wird bis zu " .. TH.PENDING_TTL .. " s nachgefragt")
    TH.StartTicker()
end

function TH.Recheck()
    local ua = _G.C_UnitAuras
    if not (ua and ua.GetAuraDataByAuraInstanceID) then return end
    local now = Now()
    for id, untilAt in pairs(st.pending) do
        local ok, a = pcall(ua.GetAuraDataByAuraInstanceID, "player", id)
        if not ok or type(a) ~= "table" then
            st.pending[id] = nil
        else
            local src = K.Plain(a.sourceUnit)
            if type(src) == "string" and src ~= "" then
                st.pending[id] = nil
                if TH.Active() and TH.Where() then
                    if not TH.Always() and now - st.at < TH.GLOBAL then
                        TH.Trace("Spender erkannt, aber gerade erst gedankt (höchstens alle 20 s)")
                    else
                        TH.Try({ a }, now, "später erkannt")
                    end
                end
            elseif now > untilAt then
                st.pending[id] = nil
                TH.Trace("Spender blieb unbekannt: " .. Str(a.name))
                if TH.Kind(K.Plain(a.name)) ~= "general" then TH.HintUnknown() end
            end
        end
    end
    if not _G.next(st.pending) and st.ticker then
        if st.ticker.Cancel then st.ticker:Cancel() end
        st.ticker = nil
    end
end

function TH.StartTicker()
    if st.ticker or not (_G.C_Timer and _G.C_Timer.NewTicker) then return end
    st.ticker = _G.C_Timer.NewTicker(1, function() pcall(TH.Recheck) end)
end

-- Tooltip eines eigenen Buffs: "Von: Name", wenn das Spiel ihn kennt -
-- und gleich nachfragen, ob ein vorgemerkter Dank jetzt raus kann.
function TH.TipSource(tip, unit, id)
    if K.Plain(unit) ~= "player" or type(K.Plain(id)) ~= "number" then return end
    local ua = _G.C_UnitAuras
    local ok, a = pcall(ua.GetAuraDataByAuraInstanceID, "player", K.Plain(id))
    if not ok or type(a) ~= "table" or K.Plain(a.isHelpful) == false then return end
    local src = K.Plain(a.sourceUnit)
    if type(src) == "string" and src ~= "" and not Bool(_G.UnitIsUnit, src, "player") then
        local n = _G.GetUnitName and K.Plain(_G.GetUnitName(src, true))
        if type(n) == "string" and n ~= "" then
            local m = C and C.textMuted or { 0.7, 0.7, 0.7 }
            tip:AddLine("Von: " .. n, m[1], m[2], m[3])
            tip:Show()
        end
    end
    if st.pending[K.Plain(id)] then pcall(TH.Recheck) end
end

function TH.HookTips()
    local gt = _G.GameTooltip
    if TH._tips or not (gt and _G.hooksecurefunc) then return end
    TH._tips = true
    if gt.SetUnitBuffByAuraInstanceID then
        _G.hooksecurefunc(gt, "SetUnitBuffByAuraInstanceID", function(tip, unit, id) pcall(TH.TipSource, tip, unit, id) end)
    end
    if gt.SetUnitAura then
        _G.hooksecurefunc(gt, "SetUnitAura", function(tip, unit, index, filter)
            local ua = _G.C_UnitAuras
            if not (ua and ua.GetAuraDataByIndex) then return end
            local ok, a = pcall(ua.GetAuraDataByIndex, unit, index, filter)
            if ok and type(a) == "table" then pcall(TH.TipSource, tip, unit, a.auraInstanceID) end
        end)
    end
end

local ev = CreateFrame("Frame")
pcall(ev.RegisterUnitEvent, ev, "UNIT_AURA", "player")
for _, e in ipairs({ "PLAYER_TARGET_CHANGED", "UPDATE_MOUSEOVER_UNIT", "NAME_PLATE_UNIT_ADDED",
                     "GROUP_ROSTER_UPDATE", "PLAYER_LOGIN" }) do
    pcall(ev.RegisterEvent, ev, e)
end
pcall(ev.RegisterEvent, ev, "ADDON_ACTION_BLOCKED")
pcall(ev.RegisterEvent, ev, "ADDON_ACTION_FORBIDDEN")
pcall(ev.RegisterEvent, ev, "CHAT_MSG_WHISPER_INFORM")
pcall(ev.RegisterEvent, ev, "CHAT_MSG_SYSTEM")
ev:SetScript("OnEvent", function(_, event, a1, a2)
    if event == "UNIT_AURA" then
        if a1 == "player" then pcall(TH.OnAura, a2) end
    elseif event == "PLAYER_LOGIN" then
        TH.HookTips()
    elseif event == "PLAYER_TARGET_CHANGED" or event == "UPDATE_MOUSEOVER_UNIT"
        or event == "NAME_PLATE_UNIT_ADDED" or event == "GROUP_ROSTER_UPDATE" then
        if _G.next(st.pending) then pcall(TH.Recheck) end
    elseif event == "CHAT_MSG_WHISPER_INFORM" then
        -- Bestaetigung des Spiels: der Text kam bei ihm an.
        local e = st.echo
        if e and K.Plain(a1) == e.text then st.echo = nil TH.Trace("vom Spiel bestätigt") end
    elseif event == "CHAT_MSG_SYSTEM" then
        -- "Spieler nicht gefunden" u. ae. gleich nach dem Versuch merken.
        if st.echo then
            local m = K.Plain(a1)
            if type(m) == "string" then st.sysMsg = m TH.Trace("Meldung des Spiels: " .. m) end
        end
    else
        TH.OnBlocked(a1)
    end
end)

function TH.StatusLine()
    return string.format("Danke für Buffs: %s · gedankt %d× · %s%s",
        TH.Active() and "an" or "aus", st.sent,
        K.Get(KEY, "thanksBlocked") and "Flüstern gesperrt, über die Chatzeile" or "flüstert selbst",
        st.why and (" · zuletzt kein Dank: " .. st.why) or "")
end

--------------------------------------------------
-- Einstellungen: eigene Seite "Danke" (6.41.0.0)
--------------------------------------------------

local edit = { kind = "general", line = 1, input = "", top = 0 }
TH.edit = edit

local ROWS = 8
local function LineList(parent, width)
    local w = CreateFrame("Frame", nil, parent)
    local rows = {}
    for i = 1, ROWS do
        local r = CreateFrame("Frame", nil, w)
        r:SetSize(width, 22)
        r:SetPoint("TOPLEFT", w, "TOPLEFT", 0, -(i - 1) * 24)
        r.sel = r:CreateTexture(nil, "BACKGROUND")
        r.sel:SetAllPoints(r)
        local ac = WeintCodex.Colors.accent
        r.sel:SetColorTexture(ac[1], ac[2], ac[3], 0.18)
        r.text = K.NewText(r, 12)
        r.text:SetPoint("LEFT", r, "LEFT", 6, 0)
        r.text:SetPoint("RIGHT", r, "RIGHT", -30, 0)
        r.text:SetJustifyH("LEFT")
        r:EnableMouse(true)
        r:SetScript("OnMouseDown", function()
            if r.index then edit.line = r.index edit.input = TH.Lines(edit.kind)[r.index] or "" K.Fire("setting", KEY, "thanksEdit") end
        end)
        r.del = WeintCodex.CreateButton(r, { text = "×", kind = "secondary", height = 20, size = 12, backdrop = "bgDark",
            onClick = function()
                local list = TH.OwnLines(edit.kind)
                if r.index then table.remove(list, r.index) K.Fire("setting", KEY, "thanksLines") end
            end })
        r.del:SetWidth(22)
        r.del:SetPoint("RIGHT", r, "RIGHT", 0, 0)
        rows[i] = r
    end
    -- Blaettern (6.41.1.0): Mausrad ueber der Liste oder die Pfeile.
    local function Scroll(delta)
        local n = #TH.Lines(edit.kind)
        edit.top = math.max(0, math.min(math.max(0, n - ROWS), edit.top - delta))
        w.Sync()
    end
    w:EnableMouseWheel(true)
    w:SetScript("OnMouseWheel", function(_, delta) Scroll(delta) end)
    w.up = WeintCodex.CreateButton(w, { text = "▲", kind = "secondary", height = 20, size = 10, backdrop = "bgDark",
        onClick = function() Scroll(ROWS) end })
    w.up:SetWidth(28)
    w.up:SetPoint("TOPRIGHT", w, "TOPLEFT", width - 0, -ROWS * 24 - 2)
    w.down = WeintCodex.CreateButton(w, { text = "▼", kind = "secondary", height = 20, size = 10, backdrop = "bgDark",
        onClick = function() Scroll(-ROWS) end })
    w.down:SetWidth(28)
    w.down:SetPoint("RIGHT", w.up, "LEFT", -4, 0)
    w.more = K.NewText(w, 11)
    w.more:SetPoint("TOPLEFT", w, "TOPLEFT", 6, -ROWS * 24 - 4)
    w.Sync = function()
        local list = TH.Lines(edit.kind)
        edit.top = math.max(0, math.min(edit.top, math.max(0, #list - ROWS)))
        for i, r in ipairs(rows) do
            local idx = edit.top + i
            local t = list[idx]
            if t then
                r.index = idx
                r.text:SetText(t)
                r.sel:SetShown(idx == edit.line)
                r:Show()
            else
                r.index = nil
                r:Hide()
            end
        end
        local many = #list > ROWS
        w.up:SetShown(many)
        w.down:SetShown(many)
        w.more:SetText(many and string.format("%d–%d von %d · Mausrad oder Pfeile", edit.top + 1, math.min(#list, edit.top + ROWS), #list)
            or (#list == 0 and "Keine Sprüche – dann gilt ein allgemeiner." or ""))
    end
    w.Sync()
    return w
end

local function Build(B)
    local off = function() return K.Get(KEY, "thanks") == false end
    B:Section("Danke für Buffs", "Draußen in der Welt, außerhalb von Gruppe und Kampf: ein Flüstern mit Augenzwinkern, passend zum Buff. Nur wenn das Spiel sagt, wer gebufft hat.")
    B:Row({ type = "toggle", label = "Fremden für Buffs danken", key = "thanks" },
          { type = "toggle", label = "Auch der Gilde", key = "thanksGuild", disabled = off })
    B:Row({ type = "toggle", label = "Auch in Instanzen", key = "thanksInstance", disabled = off,
            description = "Dungeons, Schlachtzüge, Schlachtfelder. Aus: nur in der freien Welt." },
          { type = "toggle", label = "Immer danken", key = "thanksAlways", disabled = off,
            description = "Auch im Kampf und für jeden Buff – ohne Pause zwischen zwei Danksagungen und auch, wenn derselbe Spieler gerade erst gebufft hat." })
    B:Row({ type = "slider", label = "Warten vor dem Flüstern", key = "thanksDelay", min = 0, max = 30, step = 1, disabled = off,
            format = function(v) return v == 0 and "sofort" or string.format("%d s", v) end },
          { type = "slider", label = "Allgemeine Sprüche beimischen", key = "thanksMix", min = 0, max = 100, step = 10, disabled = off,
            format = function(v) return string.format("%d %%", v) end })
    B:Row({ type = "toggle", label = "Fehlerbericht, wenn kein Dank rausgeht", key = "thanksReport", disabled = off,
            description = "Geht bei einem Buff kein Flüstern raus, obwohl es sollte, öffnet sich ein Bericht zum Kopieren (höchstens dreimal je Sitzung). Auch mit /wcui danke." },
          { type = "button", label = "Protokoll", text = "Bericht jetzt zeigen", onClick = function() TH.Report() end })
    B:Section("Sprüche", "Sorte wählen: darunter, woran der Buff erkannt wird, und ihre Sprüche. Anklicken bearbeitet, × löscht.")
    B:Row({ type = "dropdown", label = "Sorte", items = TH.KINDS,
            get = function() return edit.kind end,
            set = function(v) edit.kind, edit.line, edit.input, edit.top = v, 1, "", 0 K.Fire("setting", KEY, "thanksEdit") end },
          { type = "input", label = "Erkannt an (Wörter im Buffnamen, mit Komma)",
            disabled = function() return edit.kind == "general" end,
            get = function() return edit.kind == "general" and "– alles andere –" or table.concat(TH.Words(edit.kind), ", ") end,
            set = function(v) if edit.kind ~= "general" then TH.SetWords(edit.kind, v) end end })
    B:Row({ type = "custom", height = ROWS * 24 + 26, create = function(parent, width) return LineList(parent, width) end }, nil)
    B:Row({ type = "input", label = "Spruch (anklicken zum Bearbeiten, oder neu schreiben)",
            get = function() return edit.input end, set = function(v) edit.input = v end },
          { type = "button", label = "Neuer Spruch", text = "Hinzufügen", onClick = function()
                local t = (edit.input or ""):gsub("^%s+", ""):gsub("%s+$", "")
                if t == "" then return end
                local list = TH.OwnLines(edit.kind)
                list[#list + 1] = t
                edit.line, edit.input = #list, ""
                edit.top = math.max(0, #list - ROWS)
                K.Fire("setting", KEY, "thanksLines")
            end })
    B:Row({ type = "button", label = "Ausgewählter Spruch", text = "Ersetzen durch den Text oben", onClick = function()
                local t = (edit.input or ""):gsub("^%s+", ""):gsub("%s+$", "")
                local list = TH.OwnLines(edit.kind)
                if t ~= "" and list[edit.line] then list[edit.line] = t K.Fire("setting", KEY, "thanksLines") end
            end },
          { type = "button", label = "Diese Sorte", text = "Sprüche von WeintCodex zurück", onClick = function()
                local own = K.Get(KEY, "thanksLines")
                if type(own) == "table" then own[edit.kind] = nil end
                local ow = K.Get(KEY, "thanksWords")
                if type(ow) == "table" then ow[edit.kind] = nil end
                K.Fire("setting", KEY, "thanksLines")
            end })
end

local mod = K.Module(KEY)
if mod then
    if mod.defaults.thanks == nil then mod.defaults.thanks = true end
    if mod.defaults.thanksGuild == nil then mod.defaults.thanksGuild = false end
    if mod.defaults.thanksInstance == nil then mod.defaults.thanksInstance = false end
    if mod.defaults.thanksAlways == nil then mod.defaults.thanksAlways = false end
    if mod.defaults.thanksReport == nil then mod.defaults.thanksReport = true end
    if mod.defaults.thanksDelay == nil then mod.defaults.thanksDelay = 2 end
    if mod.defaults.thanksMix == nil then mod.defaults.thanksMix = 30 end
    mod.pages[#mod.pages + 1] = { key = "danke", label = "Danke", build = Build }
    if type(mod.pageOrder) == "table" then mod.pageOrder.danke = 31.5 end
    local view = mod.pages and mod.pages[2]
    if view then
        local build = view.build
        view.build = function(B)
            build(B)
            B:Section("Zauber")
            B:Row({ type = "toggle", label = "Manaeffizienz im Tooltip", key = "spellEfficiency",
                    description = "Heilung oder Schaden je Mana und je Sekunde – aus den Zahlen des Tooltips, für niedrigere Ränge gut zum Vergleichen." },
                  { type = "empty" })
        end
    end
end
