--------------------------------------------------
-- WeintCodex :: Oberflaeche - Selbstpruefung im Spiel (6.10.2.0)
--------------------------------------------------
-- /wcui pruefen. Seit 6.9.0.8 steht eine Liste von Fragen offen, die nur der
-- Client beantworten kann: Gibt er die Bedrohung offen oder geheim heraus?
-- Heissen die Messarten der Schadensanzeige so, wie WeintCodex sie nennt?
-- Darf ein Addon in den Chat schreiben? Ist das Mikromenue geschuetzt?
-- Welche Fenster in Gold gibt es im Client unter ihrem Namen? Bis hierher
-- fielen Antworten nur nebenbei auf - jetzt fragt ein Befehl sie ab und
-- schreibt einen Bericht zum Kopieren (K.ShowReport). Jedes Release wird
-- so zur Messung; die Pruefliste im Spiel bleibt fuer das, was nur ein
-- Auge sieht (Aussehen, Bedienung).
--
-- Jede Zeile beginnt mit ihrem Stand:
--   [ok]  der Client antwortet, wie WeintCodex es erwartet
--   [!]   der Client antwortet anders - das ist ein Befund
--   [?]   nicht zu beantworten, gerade (kein Ziel, nicht geladen) - die
--         Zeile sagt, was zu tun ist
-- Jede Pruefung laeuft fuer sich (pcall): eine, die scheitert, steht als
-- [!] im Bericht und nimmt die anderen nicht mit.
-- Geaendert wird nichts - nur gelesen. Insbesondere wird KEINE Nachricht
-- in den Chat geschickt, um das Senden zu pruefen.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UISelfCheck = {}

local SC = WeintCodex.UISelfCheck
local K = WeintCodex.UIKit

SC.OK, SC.BAD, SC.OPEN = "[ok]", "[!]", "[?]"

-- Ein Wert des Clients in Worten: geheim, leer oder er selbst.
local function Show(v)
    if K.IsSecret(v) then return "geheim" end
    if type(v) == "nil" then return "leer" end
    return tostring(v)
end
SC.Show = Show

local CHECKS = {}
SC.CHECKS = CHECKS
local function Check(name, fn) CHECKS[#CHECKS + 1] = { name = name, fn = fn } end

-- Jede Pruefung bekommt `add(stand, text)` und schreibt beliebig viele Zeilen.

Check("Speichern", function(add)
    local h = WeintCodex.SaveHealth and WeintCodex.SaveHealth() or "unknown"
    if h == "ok" then
        add(SC.OK, "Einstellungen wurden beim letzten Neuladen gespeichert.")
    elseif h == "failed" then
        add(SC.BAD, "Einstellungen wurden beim letzten Neuladen NICHT gespeichert (Fehler des Clients).")
    else
        add(SC.OPEN, "Speichern noch nicht geprüft – einmal /reload, dann wiederholen.")
    end
end)

Check("Fehler", function(add)
    local errs = K.errors or {}
    if #errs == 0 then
        add(SC.OK, "Seit dem Laden hat kein Teil der Oberfläche einen Fehler gemeldet.")
    else
        add(SC.BAD, string.format("%d Fehler seit dem Laden:", #errs))
        for _, e in ipairs(errs) do add("", "   " .. e) end
    end
end)

Check("Geheime Werte", function(add)
    if type(_G.issecretvalue) == "function" then
        add(SC.OK, "Der Client kennt geheime Werte (issecretvalue) – WeintCodex rechnet nur mit offenen.")
    else
        add(SC.OPEN, "Kein issecretvalue – der Client ist älter als erwartet; alles gilt als offen.")
    end
end)

local THREAT_FIELDS = { "isTanking", "status", "scaledPercent", "rawPercent", "threatValue" }
SC.THREAT_FIELDS = THREAT_FIELDS
-- Die fuenf Werte einer Einheit am Ziel: wie viele geheim, wie viele da,
-- und die Zeile "isTanking=..., status=...".
local threatVals = { n = 0 }
local function PackThreat(...)
    threatVals.n = select("#", ...)
    for i = 1, #THREAT_FIELDS do threatVals[i] = (select(i, ...)) end
end
function SC.ThreatOf(unit)
    PackThreat(_G.UnitDetailedThreatSituation(unit, "target"))
    local parts, secret, filled = {}, 0, 0
    for i, name in ipairs(THREAT_FIELDS) do
        local v = threatVals[i]
        if K.IsSecret(v) then secret = secret + 1 end
        if type(v) ~= "nil" then filled = filled + 1 end
        parts[#parts + 1] = name .. "=" .. Show(v)
    end
    return secret, filled, table.concat(parts, ", ")
end

-- Ein anderer Spieler aus der Gruppe (nicht du), oder nil.
function SC.GroupMate()
    local raid = _G.IsInRaid and K.Bool(_G.IsInRaid(), false)
    local group = raid or (_G.IsInGroup and K.Bool(_G.IsInGroup(), false))
    if not group then return nil end
    local prefix, count = raid and "raid" or "party", raid and 40 or 4
    for i = 1, count do
        local u = prefix .. i
        if _G.UnitExists and K.Bool(_G.UnitExists(u), false)
            and not (_G.UnitIsUnit and K.Bool(_G.UnitIsUnit(u, "player"), false)) then
            return u
        end
    end
    return nil
end

Check("Bedrohung", function(add)
    local fn = _G.UnitDetailedThreatSituation
    if type(fn) ~= "function" then
        add(SC.BAD, "UnitDetailedThreatSituation fehlt – Bedrohungsleiste und Messart 'Bedrohung' bleiben aus.")
        return
    end
    local exists = _G.UnitExists and K.Bool(_G.UnitExists("target"), false)
    local hostile = exists and _G.UnitCanAttack and K.Bool(_G.UnitCanAttack("player", "target"), false)
    if not hostile then
        add(SC.OPEN, "Kein angreifbares Ziel – einen Gegner anvisieren (am besten im Kampf) und /wcui prüfen wiederholen.")
        return
    end
    local combat = _G.InCombatLockdown and K.Bool(_G.InCombatLockdown(), false)
    local where = combat and "im Kampf" or "außerhalb des Kampfes"
    -- Deine eigene, dann (6.10.2.1) die eines anderen aus der Gruppe: der
    -- Client kann die Werte anderer Spieler anders behandeln als deine.
    local function Judge(who, unit)
        local secret, filled, parts = SC.ThreatOf(unit)
        if secret > 0 then
            add(SC.BAD, string.format("%s %s: %d von %d Werten geheim – Rangfolge nur nach Gruppe, ohne Zahlen. %s",
                who, where, secret, #THREAT_FIELDS, parts))
        elseif filled == 0 then
            add(SC.OPEN, string.format("%s %s: keine Werte – nicht auf der Bedrohungsliste dieses Ziels. Im Kampf wiederholen, wenn %s angreift.",
                who, where, unit == "player" and "du" or "er oder sie"))
        else
            add(SC.OK, string.format("%s %s offen: %s", who, where, parts))
        end
    end
    Judge("Bedrohung", "player")
    local mate = SC.GroupMate()
    if mate then
        Judge("Bedrohung von " .. mate, mate)
    else
        add(SC.OPEN, "Allein: ob der Client die Bedrohung anderer Spieler offen herausgibt, zeigt erst ein Lauf in einer Gruppe – dort im Kampf wiederholen.")
    end
end)

Check("Messarten", function(add)
    local DM = WeintCodex.UIDamageMeter
    local cdm = _G.C_DamageMeter
    if type(cdm) ~= "table" then
        add(SC.BAD, "C_DamageMeter fehlt – die Schadensanzeige hat keine Quelle.")
        return
    end
    local e = _G.Enum and _G.Enum.DamageMeterType
    if type(e) ~= "table" then
        add(SC.BAD, "Enum.DamageMeterType fehlt – nur die Grundarten werden gezeigt.")
        return
    end
    local known, have, missing = {}, {}, {}
    for _, m in ipairs(DM and DM.MODES or {}) do
        if not m.threat then
            known[m.key] = true
            if type(e[m.key]) ~= "nil" then have[#have + 1] = m.key else missing[#missing + 1] = m.key end
        end
    end
    local extra = {}
    for name in pairs(e) do
        if type(name) == "string" and not known[name] then extra[#extra + 1] = name end
    end
    table.sort(extra)
    if #missing == 0 then
        add(SC.OK, string.format("Alle %d Messarten kennt der Client.", #have))
    else
        add(SC.BAD, string.format("Der Client kennt %d von %d Messarten. Fehlen (bleiben ausgeblendet): %s",
            #have, #have + #missing, table.concat(missing, ", ")))
    end
    if #extra > 0 then
        add(SC.OPEN, "Der Client hat Messarten, die WeintCodex nicht zeigt: " .. table.concat(extra, ", "))
    end
end)

Check("Chat", function(add)
    local send = (_G.C_ChatInfo and _G.C_ChatInfo.SendChatMessage) or _G.SendChatMessage
    if type(send) ~= "function" then
        add(SC.BAD, "Keine Funktion zum Senden – 'In den Chat melden' kann nichts schicken.")
        return
    end
    local lock = _G.C_ChatInfo and _G.C_ChatInfo.InChatMessagingLockdown
    if type(lock) == "function" then
        local ok, v = pcall(lock)
        local locked = ok and K.Bool(v, false)
        add(locked and SC.BAD or SC.OK, "Chat gesperrt für Addons gerade: " .. (ok and Show(v) or "Abfrage scheiterte"))
    end
    -- Gemessen 04.10.2026 (Client 1.60.1, Build 70205): eine Meldung an die
    -- Gruppe kommt an. Kein [?] mehr bei jedem Lauf - nur noch ein Hinweis.
    add("", "   Gemessen: eine Meldung an die Gruppe kommt an (Client 1.60.1, Build 70205).")
end)

Check("Mikromenü", function(add)
    local found = false
    for _, name in ipairs({ "MicroMenuContainer", "MicroMenu" }) do
        local f = _G[name]
        if type(f) == "table" and f.IsProtected then
            found = true
            local ok, prot, explicit = pcall(f.IsProtected, f)
            local p = ok and K.Bool(prot, false)
            add(p and SC.BAD or SC.OK, string.format("%s: geschützt %s%s", name, ok and Show(prot) or "?",
                (ok and K.Bool(explicit, false)) and " (ausdrücklich)" or "")
                .. (p and " – Verschieben geht nur außerhalb des Kampfes" or ""))
        end
    end
    if not found then add(SC.OPEN, "Kein Mikromenü unter MicroMenuContainer/MicroMenu gefunden.") end
end)

-- Fenster, von denen der Client immer nur EINES hat (je nach Fassung des
-- Spiels) - fehlen die anderen, ist das richtig so.
SC.ALTERNATIVES = {
    { "PlayerSpellsFrame", "SpellBookFrame" },
    { "PlayerTalentFrame", "TalentFrame", "ClassTalentFrame" },
    { "PVPFrame", "HonorFrame" },
    { "LFGParentFrame", "PVEFrame" },
}
-- Fenster, die das Spiel erst beim ersten Oeffnen laedt, und ihr Paket.
-- Ob es das Paket gibt, sagt der Client (GetAddOnInfo); ein falscher Name
-- hier faellt als "nicht gefunden" auf, nicht als gefundenes Fenster.
SC.ADDON_OF = {
    PlayerSpellsFrame = "Blizzard_PlayerSpells",
    PlayerTalentFrame = "Blizzard_TalentUI", TalentFrame = "Blizzard_TalentUI",
    ClassTalentFrame = "Blizzard_ClassTalentUI",
    ProfessionsFrame = "Blizzard_Professions",
    CommunitiesFrame = "Blizzard_Communities",
    CollectionsJournal = "Blizzard_Collections",
    MacroFrame = "Blizzard_MacroUI",
    AuctionHouseFrame = "Blizzard_AuctionHouseUI",
    GuildBankFrame = "Blizzard_GuildBankUI",
    ClassTrainerFrame = "Blizzard_TrainerUI",
}

-- "loaded", "ondemand" oder "missing" - was der Client ueber ein Paket sagt.
function SC.AddonState(name)
    local A = type(_G.C_AddOns) == "table" and _G.C_AddOns or nil
    local info = (A and A.GetAddOnInfo) or _G.GetAddOnInfo
    if type(info) ~= "function" then return "missing" end
    local ok, n, _, _, _, reason = pcall(info, name)
    if not ok or type(n) == "nil" or reason == "MISSING" then return "missing" end
    local isLoaded = (A and A.IsAddOnLoaded) or _G.IsAddOnLoaded
    local lok, loaded = false, false
    if type(isLoaded) == "function" then lok, loaded = pcall(isLoaded, name) end
    return (lok and K.Bool(loaded, false)) and "loaded" or "ondemand"
end

Check("Fenster in Gold", function(add)
    local W = WeintCodex.UIWindows
    if not (W and W.WINDOWS) then
        add(SC.OPEN, "Fenster des Spiels nicht geladen (Oberfläche aus?).")
        return
    end
    local function Present(n) return type(_G[n]) == "table" end
    local groupOf = {}
    for _, g in ipairs(SC.ALTERNATIVES) do for _, n in ipairs(g) do groupOf[n] = g end end
    local styled, waiting, later, alt, broken, unknown = {}, {}, {}, {}, {}, {}
    local seen = {}
    for _, n in ipairs(W.WINDOWS) do
        local f = _G[n]
        local g = groupOf[n]
        if Present(n) then
            if W.done and W.done[f] then styled[#styled + 1] = n else waiting[#waiting + 1] = n end
        elseif g and not seen[g] then
            seen[g] = true
            local have
            for _, m in ipairs(g) do if Present(m) then have = m end end
            if have then
                alt[#alt + 1] = have
            else
                -- Keins aus der Gruppe da: ueber die Pakete der Mitglieder.
                local state, pkg = "missing", nil
                for _, m in ipairs(g) do
                    local a = SC.ADDON_OF[m]
                    local st = a and SC.AddonState(a) or "missing"
                    if st == "loaded" then state, pkg = "loaded", a break end
                    if st == "ondemand" and state == "missing" then state, pkg = "ondemand", a end
                end
                local label = table.concat(g, "/")
                if state == "ondemand" then later[#later + 1] = label .. " (" .. pkg .. ")"
                elseif state == "loaded" then broken[#broken + 1] = label .. " (" .. pkg .. " geladen)"
                else unknown[#unknown + 1] = label end
            end
        elseif not g then
            local a = SC.ADDON_OF[n]
            local st = a and SC.AddonState(a) or "missing"
            if st == "ondemand" then later[#later + 1] = n .. " (" .. a .. ")"
            elseif st == "loaded" then broken[#broken + 1] = n .. " (" .. a .. " geladen)"
            else unknown[#unknown + 1] = n end
        end
    end
    add(SC.OK, string.format("Gestaltet %d · noch nicht geöffnet %d · lädt beim ersten Öffnen %d · Alternative im Client %d",
        #styled, #waiting, #later, #alt))
    if #waiting > 0 then add("", "   Noch nicht geöffnet: " .. table.concat(waiting, ", ")) end
    if #later > 0 then add("", "   Lädt beim ersten Öffnen: " .. table.concat(later, ", ")) end
    if #alt > 0 then add("", "   Aus einer Gruppe von Alternativen da: " .. table.concat(alt, ", ")) end
    if #broken > 0 then
        add(SC.BAD, "Paket geladen, aber kein Fenster unter diesem Namen – heißt im Client anders: " .. table.concat(broken, ", "))
    end
    if #unknown > 0 then
        add(SC.OPEN, "Nicht gefunden und kein Paket des Spiels dazu bekannt – heißt anders oder gibt es nicht: "
            .. table.concat(unknown, ", "))
    end
    if W.Status then add("", "   " .. W.Status()) end
end)

Check("Speicherbedarf", function(add)
    local kb = K.AddonKB and K.AddonKB()
    if type(kb) == "number" then
        add(SC.OK, string.format("WeintCodex belegt gerade %.1f MB (Schwankung ist normal; /wcui speicher misst je Teil).", kb / 1024))
    else
        add(SC.OPEN, "Speicher nicht messbar.")
    end
end)

-- Der Kopf: Fassung, Client, Lage. Dann jede Pruefung, dann die Summe.
function SC.Run()
    local out = {}
    local v, build, date, toc
    if type(_G.GetBuildInfo) == "function" then v, build, date, toc = _G.GetBuildInfo() end
    out[1] = string.format("WeintCodex %s · Client %s (Build %s, %s, TOC %s)", tostring(WeintCodex.Version),
        Show(v), Show(build), Show(date), Show(toc))
    local class = _G.UnitClass and select(2, _G.UnitClass("player"))
    local level = _G.UnitLevel and _G.UnitLevel("player")
    local combat = _G.InCombatLockdown and K.Bool(_G.InCombatLockdown(), false)
    local group = (_G.IsInRaid and K.Bool(_G.IsInRaid(), false) and "Schlachtzug")
        or (_G.IsInGroup and K.Bool(_G.IsInGroup(), false) and "Gruppe") or "allein"
    out[2] = string.format("%s Stufe %s · %s · %s · Oberfläche %s", Show(class), Show(level), group,
        combat and "im Kampf" or "außer Kampf", (K.UIEnabled and K.UIEnabled()) and "an" or "aus")
    out[3] = ""
    local bad, open = 0, 0
    for _, c in ipairs(CHECKS) do
        local function add(mark, text)
            if mark == SC.BAD then bad = bad + 1 elseif mark == SC.OPEN then open = open + 1 end
            -- Folgezeilen (ohne Stand) stehen eingerueckt unter ihrer Pruefung.
            out[#out + 1] = mark == "" and text or (mark .. " " .. c.name .. ": " .. text)
        end
        local ok, err = pcall(c.fn, add)
        if not ok then add(SC.BAD, "Prüfung selbst scheiterte – " .. tostring(err)) end
    end
    out[#out + 1] = ""
    out[#out + 1] = string.format("Summe: %d Befunde [!], %d offen [?].", bad, open)
    SC.last = { bad = bad, open = open }
    return out
end
