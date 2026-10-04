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
    local r = { n = 0 }
    local function Pack(...) r.n = select("#", ...) for i = 1, r.n do r[i] = (select(i, ...)) end end
    Pack(fn("player", "target"))
    local parts, secret, filled = {}, 0, 0
    for i, name in ipairs(THREAT_FIELDS) do
        local v = r[i]
        if K.IsSecret(v) then secret = secret + 1 end
        if type(v) ~= "nil" then filled = filled + 1 end
        parts[#parts + 1] = name .. "=" .. Show(v)
    end
    local combat = _G.InCombatLockdown and K.Bool(_G.InCombatLockdown(), false)
    local where = combat and "im Kampf" or "außerhalb des Kampfes"
    if secret > 0 then
        add(SC.BAD, string.format("Bedrohung %s: %d von %d Werten geheim – Rangfolge nur nach Gruppe, ohne Zahlen. %s",
            where, secret, #THREAT_FIELDS, table.concat(parts, ", ")))
    elseif filled == 0 then
        add(SC.OPEN, string.format("Bedrohung %s: keine Werte – du stehst auf keiner Bedrohungsliste dieses Ziels. Im Kampf wiederholen.", where))
    else
        add(SC.OK, string.format("Bedrohung %s offen: %s", where, table.concat(parts, ", ")))
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
    add(SC.OPEN, "Ob eine Meldung ankommt, zeigt nur ein Versuch: nach einem Kampf in der Schadensanzeige 'In den Chat melden' → Gruppe oder Sagen.")
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

Check("Fenster in Gold", function(add)
    local W = WeintCodex.UIWindows
    if not (W and W.WINDOWS) then
        add(SC.OPEN, "Fenster des Spiels nicht geladen (Oberfläche aus?).")
        return
    end
    local styled, waiting, absent = {}, {}, {}
    for _, n in ipairs(W.WINDOWS) do
        local f = _G[n]
        if type(f) ~= "table" then
            absent[#absent + 1] = n
        elseif W.done and W.done[f] then
            styled[#styled + 1] = n
        else
            waiting[#waiting + 1] = n
        end
    end
    add(SC.OK, string.format("Gestaltet: %d · vorhanden, noch nicht geöffnet: %d · nicht im Client: %d (von %d)",
        #styled, #waiting, #absent, #W.WINDOWS))
    if #waiting > 0 then add("", "   Noch nicht geöffnet: " .. table.concat(waiting, ", ")) end
    if #absent > 0 then
        add(SC.OPEN, "Nicht im Client (manche lädt das Spiel erst beim ersten Öffnen – danach wiederholen): "
            .. table.concat(absent, ", "))
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
