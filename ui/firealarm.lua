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
}
FA.TICK = 0.2        -- so oft im Kampf gefragt (s)
FA.GAP = 1.0         -- hoechstens ein Ton je Sekunde
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
FA.ORDER = { "raus", "achtung", "fehler", "trill", "hoch", "tief", "dreifach", "hupe", "sirene", "raid", "boss", "ready", "alarm", "alarm2", "whisper", "invite", "queue", "toast" }

local stats = { checks = 0, plain = 0, secret = 0, none = 0, alarms = 0 }
FA.stats = stats
local last            -- letzte offene Summe des eigenen vermeidbaren Schadens
local lastAlarm = -math.huge

function FA.Active() return K.IsActive(KEY) and K.Get(KEY, "fireAlarm") and true or false end

local function Now()
    local t = _G.GetTime and K.Plain(_G.GetTime())
    return type(t) == "number" and t or 0
end

function FA.Play()
    local s = FA.SOUNDS[K.Get(KEY, "fireSound")] or FA.SOUNDS.hoch
    if s.file then
        if _G.PlaySoundFile then pcall(_G.PlaySoundFile, FA.SOUND_PATH .. s.file, "Master") end
        return
    end
    local kit = _G.SOUNDKIT and _G.SOUNDKIT[s.kit] or s.id
    if _G.PlaySound then pcall(_G.PlaySound, kit, "Master") end
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
    if not FA.Active() then return false end
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
    if now - lastAlarm < FA.GAP then return false end
    lastAlarm = now
    stats.alarms = stats.alarms + 1
    FA.Play()
    return true
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
ev:SetScript("OnEvent", function(_, event)
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
end)

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
function FA.Hit()
    local now = Now()
    local gap = now - lastDrop
    if gap < (stats.minGap or math.huge) then stats.minGap = gap end
    local again = gap <= FA.OUT_WINDOW
    lastDrop = now
    if not again or now - lastAlarm < FA.GAP then return false end
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
cev:SetScript("OnEvent", function(_, _, unit, action) FA.OnUnitCombat(unit, action) end)
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
    local items = {}
    for _, k in ipairs(FA.ORDER) do items[#items + 1] = { value = k, text = FA.SOUNDS[k].text } end
    B:Row({ type = "toggle", label = "Warnton, wenn du in etwas stehst", key = "fireAlarm",
            description = "Höchstens einmal je Sekunde." },
          { type = "dropdown", label = "Ton", key = "fireSound", items = items, disabled = off })
    B:Row({ type = "button", label = "Probe", text = "Ton abspielen", onClick = FA.Play },
          { type = "toggle", label = "Auch außerhalb des Kampfes", key = "fireOutside", disabled = off,
            description = "Lagerfeuer, Lava und Ähnliches: Ton, wenn dein Leben zweimal kurz hintereinander sinkt. Ein einzelner Sturz zählt nicht." })
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
boot:SetScript("OnEvent", function() Apply() end)
FA.boot = boot
