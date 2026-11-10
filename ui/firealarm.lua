--------------------------------------------------
-- WeintCodex :: Warnton bei vermeidbarem Schaden ("Raus aus dem Feuer")
--------------------------------------------------
-- Seit 6.21.1.0 (Beta-Test: "als zusaetzliche Komfortfunktion GTFO -
-- Sound, wenn man in Feuer oder Schaden steht"). Nach dem Verhalten von
-- GTFO, ohne dessen Code und ohne seine Liste von Zaubern.
--
-- WOHER DAS WISSEN KOMMT: Addons bekommen auf Forever kein Kampflog
-- (docs/systems/ui.md). GTFO erkennt Feuer an den Zaubern im Kampflog -
-- das geht hier nicht. Was der Client stattdessen zaehlt, ist der
-- VERMEIDBARE SCHADEN je Spieler (C_DamageMeter, Messart
-- "AvoidableDamageTaken" - dieselbe wie in der Schadensanzeige). Waechst
-- die eigene Summe, hat einen etwas getroffen, dem man haette ausweichen
-- koennen: Ton. Welche Zauber "vermeidbar" sind, entscheidet das Spiel.
--
-- DIE GRENZE: im Kampf kann der Client die Summe GEHEIM geben (gemessen
-- 6.6.2.3 an der Schadensanzeige). Mit einem geheimen Wert laesst sich
-- nicht vergleichen - dann schweigt der Ton, statt zu raten, und
-- /wcui prüfen sagt "geheim". Ob das auf Forever so ist, ist ungemessen.
--
-- Seite "Raus da" im Komfort (6.21.2.0: nicht nur Feuer - "allgemein in
-- der Schei... stehen"; vermeidbar ist alles, was das Spiel so zaehlt), ab Werk aus, geht ohne Oberflaeche. Gefragt
-- wird nur im Kampf, fuenfmal je Sekunde.
--------------------------------------------------

local K = WeintCodex.UIKit
local KEY = "comfort"

WeintCodex.UIFireAlarm = {}
local FA = WeintCodex.UIFireAlarm

FA.DEFAULTS = {
    fireAlarm = false,
    fireSound = "raus",
    fireOutside = true,     -- 6.25.1.0: auch ausserhalb des Kampfes (Lagerfeuer, Lava)
    -- 6.27.0.0 (Beta-Test: "Gift-Dot beim Leveln ... jeder Gegner verpasst
    -- mir einen Dot - NOWAY"): Unterpunkte zum Ein- und Ausschalten.
    fireInCombat  = true,   -- im Kampf (vermeidbarer Schaden des Spiels)
    fireNoDots    = true,   -- nicht, solange ein schaedlicher Effekt auf dir liegt
    fireWhere     = "all",  -- all | group | instance
}
FA.TICK = 0.2        -- so oft im Kampf gefragt (s)
FA.GAP = 1.0         -- hoechstens ein Ton je Sekunde
-- 1.10.1.0: ein langer Ton (Memes, `len`) wird nicht ueberspielt - der
-- naechste Alarm wartet, bis er zu Ende ist, sonst stapeln sie sich im Feuer.
function FA.Gap()
    local s = FA.SOUNDS[K.Get(KEY, "fireSound")]
    local len = s and tonumber(s.len)
    return (len and len > FA.GAP) and len or FA.GAP
end
-- Toene des Spiels (SOUNDKIT), Zahl als Rueckfall.
-- 6.24.0.0 (Beta-Test: "mehr Sounds"): alles Toene des Spiels, keine
-- eigenen Dateien. Kennt der Client einen Namen nicht, gilt die Zahl.
-- 6.25.0.0 (Beta-Test: "praegnantere Toene, so wie GTFO"): fuenf eigene,
-- gerechnete Alarme (media/sounds, .github/scripts/make_sounds.py) - keine
-- Dateien aus GTFO. Sie stehen vorn; "hoch" ist der neue Standard.
FA.SOUND_PATH = "Interface\\AddOns\\WeintCodex\\media\\sounds\\"
-- 6.25.1.0 (Beta-Test: "etwas aehnliches wie GTFO", nachgebaut, nicht
-- kopiert): vier Arten wie dort - Raus!, Achtung, Fehler, Trillern.
-- "raus" ist der neue Standard.
FA.SOUNDS = {
    raus     = { file = "raus.ogg", text = "Raus! (steigend, hart)" },
    achtung  = { file = "achtung.ogg", text = "Achtung (tiefes Brummen)" },
    fehler   = { file = "fehler.ogg", text = "Fehler (fallend)" },
    trill    = { file = "trill.ogg", text = "Trillern" },
    hoch     = { file = "hoch.ogg", text = "Alarm hoch (zweifach)" },
    tief     = { file = "tief.ogg", text = "Alarm tief (Brummen)" },
    dreifach = { file = "dreifach.ogg", text = "Alarm dreifach" },
    hupe     = { file = "hupe.ogg", text = "Hupe" },
    sirene   = { file = "sirene.ogg", text = "Sirene" },
    -- 1.10.1.0 (Wunsch des Besitzers): drei Memes, geschnitten von
    -- .github/scripts/make_meme_sounds.py - nur der Spruch, ohne Vor- und Nachlauf.
    meme_raus = { file = "meme_raus.ogg", len = 1.75, text = "Meme: „Ich muss raus!“" },
    meme_fahr = { file = "meme_fahr.ogg", len = 4.7, text = "Meme: „Fahr weiter!“" },
    meme_rose = { file = "meme_rose.ogg", len = 5.39, text = "Meme: „Aua, hat mich gebissen, die Rose!“" },
    meme_hallo = { file = "meme_hallo.ogg", len = 3.3, text = "Meme: „Hallo, was machen Sachen?“" },
    meme_alarm = { file = "meme_alarm.ogg", len = 4.0, text = "Meme: Alarm" },
    -- 1.10.6.0 (Wunsch: "die Toene von DBM nutzen"): Dateien DES SPIELS ueber
    -- ihre Nummer - WeintCodex liefert keine davon aus. Welche Nummern das
    -- sind, steht oeffentlich in den Dateilisten des Clients; die Auswahl
    -- folgt der von DBM (nur Betreuer). Die Dateien von DBM selbst sind
    -- "All Rights Reserved" bzw. nur fuer DBM freigegeben und bleiben draussen.
    -- Ob ein Client die Datei hat, sagt erst PlaySoundFile (willPlay) - die
    -- Warntoene 767xxxx gibt es nur in Clients ab 12.x, die Stimmen je nach
    -- Fassung; fehlt eine, bleibt es still und die Probe sagt es.
    warn_low   = { fid = 7670699, text = "Warnton des Spiels: niedrig" },
    warn_mid   = { fid = 7670701, text = "Warnton des Spiels: mittel" },
    warn_crit  = { fid = 7670697, text = "Warnton des Spiels: kritisch" },
    nebell     = { fid = 566558, text = "Glocke der Nachtelfen" },
    pvpflag    = { fid = 569200, text = "PvP-Flagge" },
    vo_illidan = { fid = 552503, text = "Stimme: Illidan – nicht vorbereitet" },
    vo_illidan2 = { fid = 1412178, text = "Stimme: Illidan – nicht vorbereitet (neu)" },
    vo_kj      = { fid = 553193, text = "Stimme: Kil'jaeden – Zerstörung" },
    vo_algalon = { fid = 543587, text = "Stimme: Algalon – Vorsicht" },
    vo_wolf    = { fid = 552035, text = "Stimme: Großer böser Wolf – lauf" },
    vo_loatheb = { fid = 554236, text = "Stimme: Loatheb – ich sehe dich" },
    vo_horseman = { fid = 551703, text = "Stimme: Kopfloser Reiter – Lachen" },
    vo_kazrogal = { fid = 553050, text = "Stimme: Kaz'rogal – markiert" },
    vo_malande = { fid = 553566, text = "Stimme: Lady Malande – fliehen" },
    vo_milhouse = { fid = 555337, text = "Stimme: Milhouse" },
    vo_voidreaver = { fid = 563787, text = "Stimme: Leerhäscher – markiert" },
    vo_yogg    = { fid = 564859, text = "Stimme: Yogg-Saron – Lachen" },
    raid    = { kit = "RAID_WARNING", id = 8959, text = "Schlachtzugswarnung" },
    ready   = { kit = "READY_CHECK", id = 8960, text = "Bereitschaftscheck" },
    alarm   = { kit = "ALARM_CLOCK_WARNING_3", id = 12889, text = "Wecker" },
    alarm2  = { kit = "ALARM_CLOCK_WARNING_2", id = 12867, text = "Wecker, kurz" },
    whisper = { kit = "TELL_MESSAGE", id = 3081, text = "Flüstern" },
    boss    = { kit = "UI_RAID_BOSS_WHISPER_WARNING", id = 37666, text = "Bosswarnung" },
    invite  = { kit = "IG_PLAYER_INVITE", id = 880, text = "Einladung" },
    queue   = { kit = "PVP_THROUGH_QUEUE", id = 8459, text = "Warteschlange" },
    toast   = { kit = "UI_BNET_TOAST", id = 18019, text = "Battle.net-Hinweis" },
}
FA.ORDER = { "raus", "achtung", "fehler", "trill", "hoch", "tief", "dreifach", "hupe", "sirene", "meme_raus", "meme_fahr", "meme_rose", "meme_hallo", "meme_alarm", "warn_low", "warn_mid", "warn_crit", "nebell", "pvpflag", "vo_illidan", "vo_illidan2", "vo_kj", "vo_algalon", "vo_wolf", "vo_loatheb", "vo_horseman", "vo_kazrogal", "vo_malande", "vo_milhouse", "vo_voidreaver", "vo_yogg", "raid", "boss", "ready", "alarm", "alarm2", "whisper", "invite", "queue", "toast" }

-- 6.146.0.0 (Wunsch: eigene Toene ueber die Companion): eigene Dateien des
-- Spielers. Die Companion schreibt sie in ein eigenes Addon WeintCodex_Sounds
-- (ein Update von WeintCodex ersetzt diesen Ordner nie) und dort sounds.lua
-- mit WeintCodex_CustomSounds = { { key, file, text }, ... }. Gelesen wird
-- erst beim Gebrauch, nie beim Laden: WeintCodex_Sounds laedt nach uns.
-- Neue Dateien kennt das Spiel erst nach einem Neustart des Spiels.
-- Vertrag: ../Companion-Forever/docs/custom-sounds-bridge.md
FA.CUSTOM_PATH = "Interface\\AddOns\\WeintCodex_Sounds\\"
local customSeen
function FA.MergeCustom()
    local list = _G.WeintCodex_CustomSounds
    if type(list) ~= "table" or list == customSeen then return end
    customSeen = list
    for _, e in ipairs(list) do
        local key, file = type(e) == "table" and e.key, type(e) == "table" and e.file
        if type(key) == "string" and key:match("^eigen%d+$") and type(file) == "string"
            and file:match("^[%w_]+%.ogg$") and not FA.SOUNDS[key] then
            -- 1.10.2.0: Laenge von der Companion (ab 1.4.1), damit FA.Gap
            -- einen langen eigenen Ton nicht ueberspielt; sonst unbekannt.
            local len = type(e.len) == "number" and e.len > 0 and e.len <= 60 and e.len or nil
            FA.SOUNDS[key] = { path = FA.CUSTOM_PATH .. file, len = len,
                text = "Eigener Ton: " .. (type(e.text) == "string" and e.text ~= "" and e.text or key) }
            table.insert(FA.ORDER, 1, key)
        end
    end
end

-- Der volle Pfad einer Datei-Eintragung (eigene oder mitgelieferte).
function FA.FileOf(s)
    if type(s) ~= "table" then return nil end
    return s.path or (s.file and FA.SOUND_PATH .. s.file) or s.fid or nil
end

local stats = { checks = 0, plain = 0, secret = 0, none = 0, alarms = 0 }
FA.stats = stats
local last            -- letzte offene Summe des eigenen vermeidbaren Schadens
local lastAlarm = -math.huge

function FA.Active() return K.IsActive(KEY) and K.Get(KEY, "fireAlarm") and true or false end

local function Now()
    local t = _G.GetTime and K.Plain(_G.GetTime())
    return type(t) == "number" and t or 0
end

-- Einen Ton aus der Liste spielen (1.10.3.0 auch fuer die Bosskaempfe,
-- ui/bossmod.lua). Gibt die Laenge zurueck, soweit bekannt (Memes, eigene
-- Toene mit `len`), sonst 0; nil, wenn es den Ton nicht gibt.
function FA.PlayKey(key, channel)
    FA.MergeCustom()
    local s = FA.SOUNDS[key]
    if type(s) ~= "table" then return nil end
    channel = channel or "Master"
    local path = FA.FileOf(s)
    local ok, will
    if path then
        if _G.PlaySoundFile then ok, will = pcall(_G.PlaySoundFile, path, channel) end
    else
        local kit = _G.SOUNDKIT and _G.SOUNDKIT[s.kit] or s.id
        if _G.PlaySound and kit then ok, will = pcall(_G.PlaySound, kit, channel) end
    end
    -- Zweiter Wert: false = der Client hat den Ton nicht (oder Ton aus),
    -- nil = er sagt es nicht.
    local played = nil
    if ok and K.Plain(will) == false then played = false elseif ok and K.Plain(will) then played = true end
    return tonumber(s.len) or 0, played
end

-- Probe auf einer Einstellungsseite: spielen und sagen, wenn der Client den
-- Ton nicht kennt - statt Stille ohne Grund.
function FA.Preview(key, channel)
    local len, played = FA.PlayKey(key, channel)
    if played == false and FA.SOUNDS[key] then
        print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " „" .. FA.SOUNDS[key].text
            .. "“ spielt dein Spiel nicht ab – diese Fassung hat den Ton nicht, oder die Lautstärke dafür ist aus.")
    end
    return len, played
end

local function Chosen()
    FA.MergeCustom()
    local key = K.Get(KEY, "fireSound")
    if not FA.SOUNDS[key] then key = "raus" end
    return key
end
-- Der Alarm selbst: still, wenn der Client den Ton nicht hat (keine
-- Chatzeile je Treffer).
function FA.Play() return FA.PlayKey(Chosen(), "Master") end
-- Der Knopf "Ton abspielen": sagt es, wenn nichts kommt.
function FA.PlayProbe() return FA.Preview(Chosen(), "Master") end

-- Die Auswahl fuer eine Liste der Toene (Einstellungsseiten).
function FA.Items(withNone)
    FA.MergeCustom()
    local items = {}
    if withNone then items[1] = { value = "none", text = "Kein Ton" } end
    for _, k in ipairs(FA.ORDER) do
        if FA.SOUNDS[k] then items[#items + 1] = { value = k, text = FA.SOUNDS[k].text } end
    end
    return items
end

-- Die eigene Summe: Zahl, "secret" (geheim) oder nil (keine Zeile).
function FA.Mine()
    local DM = WeintCodex.UIDamageMeter
    if not (DM and DM.Available and DM.Available()) then return nil end
    local e = _G.Enum and _G.Enum.DamageMeterType
    if not (e and e.AvoidableDamageTaken ~= nil) then return nil end
    local ok, data = DM.Fetch("Current", "AvoidableDamageTaken")
    local list = ok and type(data) == "table" and data.combatSources
    if type(list) ~= "table" then return nil end
    local me = _G.UnitGUID and K.Plain(_G.UnitGUID("player"))
    for _, src in ipairs(list) do
        if K.Bool(src.isLocalPlayer, false) or (me and K.Plain(src.sourceGUID) == me) then
            local v = K.Plain(src.totalAmount)
            if type(v) == "number" then return v end
            if type(src.totalAmount) ~= "nil" then return "secret" end
            return nil
        end
    end
    return nil
end

-- Ein Blick: Ton, wenn die Summe gewachsen ist. Liefert true bei Ton.
function FA.Check()
    if not FA.Active() or not K.Get(KEY, "fireInCombat") or not FA.Here() then return false end
    stats.checks = stats.checks + 1
    local v = FA.Mine()
    if v == "secret" then
        stats.secret = stats.secret + 1
        return false
    elseif type(v) ~= "number" then
        stats.none = stats.none + 1
        return false
    end
    stats.plain = stats.plain + 1
    local grew = type(last) == "number" and v > last
    last = v
    if not grew then return false end
    local now = Now()
    if now - lastAlarm < FA.Gap() then return false end
    lastAlarm = now
    stats.alarms = stats.alarms + 1
    FA.Play()
    return true
end

-- Wo der Ton gilt (6.27.0.0): ueberall, nur in einer Gruppe, nur in
-- Dungeons und Schlachtzuegen. Beim Leveln allein ist er sonst Laerm.
function FA.Here()
    local where = K.Get(KEY, "fireWhere")
    if where == "group" then
        return K.Bool(_G.IsInGroup and _G.IsInGroup(), false) or K.Bool(_G.IsInRaid and _G.IsInRaid(), false)
    elseif where == "instance" then
        if not _G.IsInInstance then return false end
        local _, kind = _G.IsInInstance()
        kind = K.Plain(kind)
        return type(kind) == "string" and kind ~= "none"
    end
    return true
end

-- Liegt ein schaedlicher Effekt auf dir (Gift, Krankheit, Fluch, Blutung)?
-- true, false oder nil (der Client sagt es nicht - dann zaehlt der Treffer
-- wie bisher). Ein Dot trifft wiederholt und sieht fuer "Leben sinkt
-- zweimal" aus wie ein Lagerfeuer - nur dass man aus ihm nicht
-- herausgehen kann. Lagerfeuer und Lava legen keinen Effekt auf einen.
function FA.HasDebuff()
    local ua = _G.C_UnitAuras
    local ok, a
    if ua and ua.GetAuraDataByIndex then
        ok, a = pcall(ua.GetAuraDataByIndex, "player", 1, "HARMFUL")
    elseif _G.UnitDebuff then
        ok, a = pcall(_G.UnitDebuff, "player", 1)
    else
        return nil
    end
    if not ok or K.IsSecret(a) then return nil end
    return a ~= nil
end

-- Kampfbeginn: was vorher war, zaehlt nicht.
function FA.Reset()
    last, lastAlarm = nil, -math.huge
end

--------------------------------------------------
-- Takt: nur im Kampf
--------------------------------------------------

local ticker = CreateFrame("Frame")
ticker:Hide()
local acc = 0
ticker:SetScript("OnUpdate", K.Measured("Raus da", function(_, el)
    acc = acc + (el or 0)
    if acc < FA.TICK then return end
    acc = 0
    FA.Check()
end))
FA.ticker = ticker

local ev = CreateFrame("Frame")
ev:SetScript("OnEvent", WeintCodex.Measured("Raus da", function(_, event)
    if event == "PLAYER_REGEN_DISABLED" then
        FA.Reset()
        local v = FA.Mine()
        if type(v) == "number" then last = v end
        if FA.Active() then ticker:Show() end
    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Noch ein Blick: der letzte Treffer vor dem Kampfende.
        FA.Check()
        ticker:Hide()
    end
end))

--------------------------------------------------
-- Ausserhalb des Kampfes: Leben sinkt wiederholt
--------------------------------------------------
-- 6.25.1.0 (Beta-Test: "im Lagerfeuer kommt der Ton nicht"). Lagerfeuer,
-- Lava, Schleim setzen einen nicht in den Kampf, und das Spiel fuehrt den
-- vermeidbaren Schaden nur im Kampf. Ersatz: sinkt das eigene Leben
-- ausserhalb des Kampfes ZWEIMAL binnen FA.OUT_WINDOW Sekunden, steht man
-- in etwas. Einmal (Sturz) zaehlt nicht. Was es ist, weiss WeintCodex
-- nicht - nur dass es wiederholt trifft.
-- 6.25.2.0 (gemessen 6.25.1.0: "außerhalb des Kampfes 0" im Lagerfeuer):
-- UNIT_HEALTH wurde nur beim Umschalten angemeldet, nie beim Einloggen.
-- Jetzt ein eigener Takt (FA.OUT_TICK) ausserhalb des Kampfes, gestartet
-- beim Einloggen; /wcui prüfen zaehlt Blicke, offene/verdeckte Werte und
-- Verluste - so sieht man, woran es haengt.
-- 6.26.4.0 (gemessen 6.26.3.0: "Treffer gemeldet 4", kein Ton): das
-- Lagerfeuer trifft womoeglich seltener als alle 3 s. Fenster 5 s; der
-- Bericht nennt jetzt die Art des letzten Treffers und den kuerzesten
-- Abstand, damit die naechste Messung sagt, woran es lag.
FA.OUT_WINDOW = 5.0
FA.OUT_TICK = 0.25
local lastHealth, lastDrop = nil, -math.huge

function FA.OnHealth()
    if not (FA.Active() and K.Get(KEY, "fireOutside")) then return false end
    if _G.InCombatLockdown and K.Bool(_G.InCombatLockdown(), false) then lastHealth = nil return false end
    stats.hpLooks = (stats.hpLooks or 0) + 1
    local hp = _G.UnitHealth and K.Plain(_G.UnitHealth("player"))
    if type(hp) ~= "number" then
        stats.hpHidden = (stats.hpHidden or 0) + 1
        lastHealth = nil
        return false
    end
    local dropped = type(lastHealth) == "number" and hp < lastHealth
    lastHealth = hp
    if not dropped then return false end
    stats.hpDrops = (stats.hpDrops or 0) + 1
    return FA.Hit()
end

-- Ein Treffer ausserhalb des Kampfes (Leben gesunken oder Ereignis des
-- Spiels): zweiter binnen FA.OUT_WINDOW -> Ton.
-- Wirkst oder kanalisierst du gerade? (6.27.2.1, Beta-Test: "dauerhafter
-- Ton, wenn ich meinen Daemon per Lebenslinie heile".) Lebenslinie,
-- Aderlass und Co. kosten eigenes Leben - das ist kein Feuer. Solange ein
-- eigener Zauber laeuft, zaehlt ein Treffer ausserhalb des Kampfes nicht.
-- Auch ein verdeckter Wert heisst "es laeuft etwas".
function FA.Casting()
    for _, f in ipairs({ _G.UnitChannelInfo, _G.UnitCastingInfo }) do
        if type(f) == "function" then
            local ok, name = pcall(f, "player")
            if ok and type(name) ~= "nil" then return true end
        end
    end
    return false
end

-- Nach einem eigenen Zauber noch kurz still: der letzte Abzug kommt oft
-- erst nach dem Ende des Kanals.
FA.CAST_GRACE = 1.5
local lastCast = -math.huge

function FA.Hit()
    if not FA.Here() then return false end
    if FA.Casting() then
        lastCast = Now()
        stats.castSkips = (stats.castSkips or 0) + 1
        return false
    end
    if Now() - lastCast < FA.CAST_GRACE then
        stats.castSkips = (stats.castSkips or 0) + 1
        return false
    end
    if K.Get(KEY, "fireNoDots") and FA.HasDebuff() then
        stats.dotSkips = (stats.dotSkips or 0) + 1
        return false
    end
    local now = Now()
    local gap = now - lastDrop
    if gap < (stats.minGap or math.huge) then stats.minGap = gap end
    local again = gap <= FA.OUT_WINDOW
    lastDrop = now
    if not again or now - lastAlarm < FA.Gap() then return false end
    lastAlarm = now
    stats.outside = (stats.outside or 0) + 1
    stats.alarms = stats.alarms + 1
    FA.Play()
    return true
end

-- 6.25.3.0 (gemessen 6.25.2.0: "Blicke aufs Leben 228 · verdeckt 228"):
-- Forever gibt das eigene Leben auch ausserhalb des Kampfes nur verdeckt
-- heraus. UNIT_COMBAT meldet einen Treffer ("WOUND") ohne dass man eine
-- Zahl vergleichen muss - die Art kommt offen oder verdeckt; verdeckt
-- zaehlt als Treffer, offen nur "WOUND".
function FA.OnUnitCombat(unit, action)
    if K.Plain(unit) ~= "player" then return false end
    if not (FA.Active() and K.Get(KEY, "fireOutside")) then return false end
    if _G.InCombatLockdown and K.Bool(_G.InCombatLockdown(), false) then return false end
    stats.wounds = (stats.wounds or 0) + 1
    local a = K.Plain(action)
    stats.lastAction = type(a) == "string" and a or (type(action) == "nil" and "keine" or "verdeckt")
    if type(a) == "string" and a ~= "WOUND" then
        stats.otherActions = (stats.otherActions or 0) + 1
        return false
    end
    return FA.Hit()
end

local cev = CreateFrame("Frame")
cev:SetScript("OnEvent", WeintCodex.Measured("Raus da", function(_, _, unit, action) FA.OnUnitCombat(unit, action) end))
FA.combatEvents = cev

local outTicker = CreateFrame("Frame")
outTicker:Hide()
local outAcc = 0
outTicker:SetScript("OnUpdate", K.Measured("Raus da außerhalb", function(_, el)
    outAcc = outAcc + (el or 0)
    if outAcc < FA.OUT_TICK then return end
    outAcc = 0
    FA.OnHealth()
end))
FA.outTicker = outTicker

local function Apply()
    if FA.Active() and K.Get(KEY, "fireOutside") then
        outTicker:Show()
        pcall(cev.RegisterEvent, cev, "UNIT_COMBAT")
    else
        outTicker:Hide()
        pcall(cev.UnregisterEvent, cev, "UNIT_COMBAT")
        lastHealth = nil
    end
    if FA.Active() then
        pcall(ev.RegisterEvent, ev, "PLAYER_REGEN_DISABLED")
        pcall(ev.RegisterEvent, ev, "PLAYER_REGEN_ENABLED")
        local inCombat = _G.InCombatLockdown and K.Bool(_G.InCombatLockdown(), false)
        if inCombat then ticker:Show() end
    else
        pcall(ev.UnregisterEvent, ev, "PLAYER_REGEN_DISABLED")
        pcall(ev.UnregisterEvent, ev, "PLAYER_REGEN_ENABLED")
        ticker:Hide()
    end
end
FA.Apply = Apply

--------------------------------------------------
-- Bericht und Seite
--------------------------------------------------

function FA.StatusLines()
    local DM = WeintCodex.UIDamageMeter
    local e = _G.Enum and _G.Enum.DamageMeterType
    local out = {}
    out[#out + 1] = "Vermeidbarer Schaden im Client: "
        .. ((DM and DM.Available() and e and e.AvoidableDamageTaken ~= nil) and "ja" or "nein")
    out[#out + 1] = string.format("Gefragt %d · offen %d · geheim %d · keine Zeile %d · Töne %d",
        stats.checks, stats.plain, stats.secret, stats.none, stats.alarms)
        .. " · außerhalb des Kampfes " .. (stats.outside or 0)
        .. " · wegen Effekt still " .. (stats.dotSkips or 0)
        .. " · wegen eigenem Zauber still " .. (stats.castSkips or 0)
    out[#out + 1] = string.format("Außerhalb des Kampfes: Takt %s · Blicke aufs Leben %d · verdeckt %d · Verluste %d · Treffer gemeldet %d",
        outTicker:IsShown() and "läuft" or "steht", stats.hpLooks or 0, stats.hpHidden or 0, stats.hpDrops or 0, stats.wounds or 0)
    if (stats.wounds or 0) > 0 then
        out[#out + 1] = string.format("Letzte Art: %s · andere Arten %d · kürzester Abstand %s (Fenster %.0f s)",
            stats.lastAction or "?", stats.otherActions or 0,
            stats.minGap and stats.minGap < math.huge and string.format("%.1f s", stats.minGap) or "–", FA.OUT_WINDOW)
    end
    if stats.secret > 0 and stats.plain == 0 then
        out[#out + 1] = "Im Kampf nur geheime Summen – dann kann WeintCodex nicht warnen."
    end
    return out
end

local function Build(B)
    local off = function() return not K.Get(KEY, "fireAlarm") end
    B:Section("Raus da!", "Ein Ton, sobald du in etwas stehst, das dir schadet und dem man ausweichen kann – nicht nur Feuer: alles am Boden (Gift, Leere, Eis, Blitze, Wirbel), Kegel und Wellen vor dem Gegner. Was vermeidbar ist, sagt das Spiel; ein Kampflog gibt es für Addons nicht.")
    local items = FA.Items(false)
    B:Row({ type = "toggle", label = "Warnton, wenn du in etwas stehst", key = "fireAlarm",
            description = "Höchstens einmal je Sekunde." },
          { type = "dropdown", label = "Ton", key = "fireSound", items = items, disabled = off })
    B:Row({ type = "button", label = "Probe", text = "Ton abspielen", onClick = FA.PlayProbe },
          { type = "dropdown", label = "Wo", key = "fireWhere", disabled = off, items = {
                { value = "all",      text = "Überall" },
                { value = "group",    text = "Nur in einer Gruppe" },
                { value = "instance", text = "Nur in Dungeons und Schlachtzügen" } } })
    B:Section("Wann")
    B:Row({ type = "toggle", label = "Im Kampf", key = "fireInCombat", disabled = off,
            description = "Wenn das Spiel vermeidbaren Schaden zählt." },
          { type = "toggle", label = "Auch außerhalb des Kampfes", key = "fireOutside", disabled = off,
            description = "Lagerfeuer, Lava und Ähnliches: Ton, wenn dein Leben zweimal kurz hintereinander sinkt. Ein einzelner Sturz zählt nicht." })
    B:Row({ type = "toggle", label = "Still bei Gift, Krankheit, Fluch", key = "fireNoDots", disabled = off,
            description = "Außerhalb des Kampfes kein Ton, solange ein schädlicher Effekt auf dir liegt – aus einem Dot kannst du nicht herausgehen, ob du ihn entfernen kannst oder nicht." }, nil)
    B:Note("Gibt das Spiel die Summe im Kampf nur verdeckt heraus, bleibt der Ton stumm – /wcui prüfen sagt dann „geheim“.")
end

local mod = K.Module(KEY)
if mod then
    for k, v in pairs(FA.DEFAULTS) do
        if mod.defaults[k] == nil then mod.defaults[k] = v end
    end
    mod.pages[#mod.pages + 1] = { key = "rausda", label = "Raus da", build = Build }
end

K.Listen(function(kind, key)
    if (kind == "active" or kind == "setting") and key == KEY then Apply() end
end)

-- Beim Einloggen einmal anwenden (fehlte bis 6.25.1.0).
local boot = CreateFrame("Frame")
boot:RegisterEvent("PLAYER_LOGIN")
boot:SetScript("OnEvent", WeintCodex.Measured("Raus da", function() Apply() end))
FA.boot = boot
