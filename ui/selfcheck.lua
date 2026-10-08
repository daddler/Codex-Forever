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

-- Laune des Begleiters (6.13.2.0). Beta-Test 6.13.1.0: kein Punkt am
-- Begleiterrahmen, obwohl das Charakterfenster des Spiels das Gesicht zeigt
-- - GetPetHappiness (Classic) antwortet auf Forever offenbar nicht. Statt
-- eine andere Abfrage zu raten, sammelt diese Pruefung, wo der Client die
-- Laune fuehrt: Funktionen mit "Happiness" im Namen (global und in C_*),
-- eine Energieart, das Ereignis UNIT_HAPPINESS und was der Rahmen des
-- Spiels (PetPaperDollPetHappinessInfo) an Werten traegt.
SC.HAPPY_FRAME = "PetPaperDollPetHappinessInfo"
SC.HAPPY_MAX = 12

-- Namen mit "appiness" (Happiness/happiness), global und in C_*-Tabellen.
function SC.HappinessNames()
    local out = {}
    for k, v in pairs(_G) do
        if type(k) == "string" then
            if k:find("appiness", 1, true) and type(v) == "function" then
                out[#out + 1] = k
            elseif k:sub(1, 2) == "C_" and type(v) == "table" then
                for m, f in pairs(v) do
                    if type(m) == "string" and m:find("appiness", 1, true) and type(f) == "function" then
                        out[#out + 1] = k .. "." .. m
                    end
                end
            end
        end
    end
    table.sort(out)
    return out
end

Check("Begleiter", function(add)
    local has = K.Bool(_G.UnitExists and _G.UnitExists("pet"), false)
    if not has then
        add(SC.OPEN, "Kein Begleiter – mit Begleiter (Jäger) wiederholen.")
        return
    end
    local h = K.PetHappiness()
    if h then
        add(SC.OK, "Laune gelesen: " .. h .. " (" .. K.HAPPINESS[h].text .. ").")
    else
        add(SC.BAD, "Laune nicht lesbar – kein Punkt am Begleiterrahmen, keine Erinnerung.")
    end
    -- Was jede bekannte Abfrage zurueckgibt - ohne Argument und mit "pet".
    local function Answer(label, f)
        if type(f) ~= "function" then
            add("", "   " .. label .. ": gibt es nicht")
            return
        end
        for _, arg in ipairs({ false, "pet" }) do
            local ok, a, b, c, d
            if arg then ok, a, b, c, d = pcall(f, arg) else ok, a, b, c, d = pcall(f) end
            add("", string.format("   %s(%s): %s", label, arg and '"pet"' or "",
                ok and (Show(a) .. ", " .. Show(b) .. ", " .. Show(c) .. ", " .. Show(d)) or ("Fehler " .. tostring(a))))
        end
    end
    Answer("GetPetHappiness", _G.GetPetHappiness)
    Answer("C_PetInfo.GetPetHappiness", type(_G.C_PetInfo) == "table" and _G.C_PetInfo.GetPetHappiness or nil)
    local _, src = K.PetHappinessSource()
    add("", "   Quelle: " .. (src or "keine"))
    local names = SC.HappinessNames()
    add("", "   Funktionen mit „Happiness“: " .. (#names > 0 and table.concat(names, ", ") or "keine"))
    local pt = type(_G.Enum) == "table" and type(_G.Enum.PowerType) == "table" and _G.Enum.PowerType.Happiness
    if type(pt) ~= "nil" and _G.UnitPower then
        local okP, p = pcall(_G.UnitPower, "pet", pt)
        local okM, m = pcall(_G.UnitPowerMax, "pet", pt)
        add("", string.format("   Energieart Happiness = %s: %s von %s", Show(pt),
            okP and Show(p) or "Fehler", okM and Show(m) or "Fehler"))
    else
        add("", "   Energieart Happiness: gibt es nicht")
    end
    local probe = CreateFrame("Frame")
    local okE = pcall(probe.RegisterEvent, probe, "UNIT_HAPPINESS")
    if okE and probe.UnregisterEvent then pcall(probe.UnregisterEvent, probe, "UNIT_HAPPINESS") end
    add("", "   Ereignis UNIT_HAPPINESS: " .. (okE and "bekannt" or "unbekannt"))
    -- Was der Rahmen des Spiels traegt: einfache Werte, Bild, Tooltip.
    local f = _G[SC.HAPPY_FRAME]
    if type(f) ~= "table" then
        add("", "   " .. SC.HAPPY_FRAME .. ": nicht da – Charakterfenster einmal mit dem Begleiter-Reiter öffnen, dann wiederholen")
    else
        local fields = {}
        for k, v in pairs(f) do
            local t = type(v)
            if type(k) == "string" and (t == "string" or t == "number" or t == "boolean") and #fields < SC.HAPPY_MAX then
                fields[#fields + 1] = k .. "=" .. Show(v)
            end
        end
        table.sort(fields)
        add("", "   " .. SC.HAPPY_FRAME .. ": " .. (#fields > 0 and table.concat(fields, ", ") or "keine einfachen Werte"))
        local tex = f.Texture
        if type(tex) == "table" then
            local okA, atlas = false, nil
            if tex.GetAtlas then okA, atlas = pcall(tex.GetAtlas, tex) end
            if not okA then atlas = nil end
            local coords = tex.GetTexCoord and { pcall(tex.GetTexCoord, tex) } or { false }
            local cs = {}
            for i = 2, (coords[1] and #coords or 1) do cs[#cs + 1] = type(coords[i]) == "number" and string.format("%.3f", coords[i]) or Show(coords[i]) end
            add("", "   Bild: Atlas " .. Show(atlas) .. " · Ausschnitt " .. (#cs > 0 and table.concat(cs, " ") or "leer"))
        end
    end
    local UF = WeintCodex.UIUnitFrames
    local pf = UF and UF.frames and UF.frames.pet
    if pf and pf._happy then
        add("", "   Punkt am Begleiterrahmen: " .. (pf._happy:IsShown() and "sichtbar" or "aus"))
    end
end)

-- Berufe (6.14.0.0): woher die Berufe-Seite Fertigkeit und Gelerntes
-- nimmt. Ungemessen auf Forever ist, welche der Abfragen antwortet -
-- ForeverGuide nutzt GetSkillLineInfo und GetTradeSkillRecipeLink, der
-- Codex fragt zuerst GetProfessions und C_TradeSkillUI.
-- Seltene Gegner (6.16.0.0): woran WeintCodex sie erkennt. Ungemessen auf
-- Forever ist, ob GUIDs und Vignetten offen sind.
Check("Seltene Gegner", function(add)
    local RA, RD = WeintCodex.UIRares, WeintCodex.RareData
    if not (RA and RD) then
        add(SC.OPEN, "Seltene Gegner nicht geladen.")
        return
    end
    local n = 0
    for _ in pairs(RD.RAW or {}) do n = n + 1 end
    local active = RA.Active()
    add(active and SC.OK or SC.OPEN, (active and "An" or "Aus (Komfort → Seltene Gegner)") .. " · " .. n .. " im Bestand")
    local function has(f) return type(f) == "function" and "ja" or "nein" end
    local vi = _G.C_VignetteInfo
    add("", "   UnitClassification: " .. has(_G.UnitClassification) .. " · UnitGUID: " .. has(_G.UnitGUID)
        .. " · C_VignetteInfo.GetVignettes: " .. has(type(vi) == "table" and vi.GetVignettes or nil))
    local g = _G.UnitGUID and _G.UnitGUID("target")
    if type(g) ~= "nil" then
        local plain = K.Plain(g)
        add("", "   GUID des Ziels: " .. (type(plain) == "string" and ("offen, NPC " .. tostring(RA.NpcId(plain) or "–")) or "geheim"))
    end
    if RA.lastVignettes then add("", "   Letzter Blick auf die Minikarte: " .. RA.lastVignettes .. " seltene als Symbol") end
    if RA.last then
        add("", "   Zuletzt gemeldet: " .. RA.last.name .. " (über " .. (RA.last.how or "?") .. (RA.last.known and ", im Bestand)" or ", nur vom Client)"))
    else
        add("", "   Seit dem Laden keiner gemeldet")
    end
end)

-- Auktionspreise (6.17.0.0): welche Wege das Spiel anbietet und welcher
-- zuletzt lief. Ungemessen auf Forever ist, ob der Server den Vollscan
-- beantwortet (laut ForeverGuide nicht immer) und ob die Suche alles schickt.
Check("Auktionspreise", function(add)
    local AP = WeintCodex.UIAuctionPrices
    if not AP then
        add(SC.OPEN, "Auktionspreise nicht geladen.")
        return
    end
    local active = AP.Active()
    add(active and SC.OK or SC.OPEN, active and "An" or "Aus (Komfort → Auktionshaus)")
    local function has(f) return type(f) == "function" and "ja" or "nein" end
    local ah = type(_G.C_AuctionHouse) == "table" and _G.C_AuctionHouse or {}
    add("", "   Vollscan (ReplicateItems): " .. has(ah.ReplicateItems) .. " · Suche (SendBrowseQuery): "
        .. has(ah.SendBrowseQuery) .. " · Tooltip über " .. (AP.hookedVia or "– (noch nicht eingehängt)"))
    for _, line in ipairs(AP.StatusLines(AP.Faction())) do add("", "   " .. line) end
    local last = AP.last
    if last then
        add("", "   Letzter Scan: " .. (last.ok and ((last.full and "vollständig" or "unvollständig") .. " über " .. last.via
            .. ", " .. last.n .. " Gegenstände") or ("ohne Ergebnis (" .. (last.why or last.via) .. ")")))
    end
    if AP.lastTooltip then add("", "   Zuletzt im Tooltip: Gegenstand " .. AP.lastTooltip) end
    -- 6.18.0.0: Preise von anderen Spielern. Ungemessen, ob Nachrichten
    -- an die Gilde und im Kanal von ForeverGuide ankommen.
    if AP.ShareLines then
        local cc = type(_G.C_ChatInfo) == "table" and _G.C_ChatInfo or {}
        add("", "   SendAddonMessage: " .. has(cc.SendAddonMessage) .. " · JoinTemporaryChannel: " .. has(_G.JoinTemporaryChannel))
        for _, line in ipairs(AP.ShareLines()) do
            if line:sub(1, 2) ~= "  " then add("", "   " .. line) end
        end
    end
end)

-- Fluestern (6.19.0.0): welche Wege zum Antworten der Client anbietet und
-- ob "direkt senden" gemessen gesperrt ist.
Check("Flüstern", function(add)
    local MS = WeintCodex.UIMessenger
    if not MS then
        add(SC.OPEN, "Flüstern nicht geladen.")
        return
    end
    local active = MS.Active()
    add(active and SC.OK or SC.OPEN, active and "An" or "Aus (Komfort → Flüstern)")
    for _, line in ipairs(MS.StatusLines()) do add("", "   " .. line) end
end)

-- Karte (6.20.0.0): Eingaenge im Bestand, ob der Client Kontinent und
-- eigene Eingaenge kennt.
Check("Karte", function(add)
    local ME = WeintCodex.UIMapEntrances
    if not ME then
        add(SC.OPEN, "Karte nicht geladen.")
        return
    end
    local active = ME.Active()
    add(active and SC.OK or SC.OPEN, active and "Instanzeingänge an" or "Instanzeingänge aus (Komfort → Karte)")
    for _, line in ipairs(ME.StatusLines()) do add("", "   " .. line) end
    local MK = WeintCodex.UIMapMarks
    if MK then
        local sp, cr = MK.Wants("spirit"), MK.Wants("crossing")
        add((sp or cr) and SC.OK or SC.OPEN, "Geistheiler " .. (sp and "an" or "aus") .. " · Übergänge " .. (cr and "an" or "aus"))
        for _, line in ipairs(MK.StatusLines()) do add("", "   " .. line) end
    end
    local MR = WeintCodex.UIMapReveal
    if MR then
        add(MR.Active() and SC.OK or SC.OPEN, MR.Active() and "Ganze Karte an" or "Ganze Karte aus")
        for _, line in ipairs(MR.StatusLines()) do add("", "   " .. line) end
    end
end)

-- Feuer (6.21.1.0): kommt die eigene Summe offen oder geheim?
Check("Raus da", function(add)
    local FA = WeintCodex.UIFireAlarm
    if not FA then add(SC.OPEN, "Warnton nicht geladen.") return end
    add(FA.Active() and SC.OK or SC.OPEN, FA.Active() and "Warnton an" or "Warnton aus (Komfort → Raus da)")
    for _, line in ipairs(FA.StatusLines()) do add("", "   " .. line) end
end)

-- Suche wechseln (6.22.0.0): darf ein Addon die Suche selbst setzen?
Check("Sammeln", function(add)
    local GT = WeintCodex.UIGatherTrack
    if not GT then add(SC.OPEN, "Suche wechseln nicht geladen.") return end
    local bad = GT.stopped or GT.stats.blocked > 0
    add(bad and SC.BAD or (GT.Active() and SC.OK or SC.OPEN),
        GT.Active() and "Kräuter/Erz wechseln an" or "Kräuter/Erz wechseln aus (Komfort → Sammeln)")
    for _, line in ipairs(GT.StatusLines()) do add("", "   " .. line) end
end)

Check("Berufe", function(add)
    local PRO = WeintCodex.Professions
    if not (PRO and PRO.Skills) then
        add(SC.OPEN, "Berufe-Seite nicht geladen.")
        return
    end
    local skills, answered = PRO.Skills()
    local names = {}
    for key, s in pairs(skills) do
        names[#names + 1] = PRO.ProfName(key) .. " " .. s.rank .. (s.max and ("/" .. s.max) or "")
    end
    table.sort(names)
    if #names > 0 then
        add(SC.OK, "Fertigkeit gelesen: " .. table.concat(names, ", ") .. ".")
    elseif answered then
        add(SC.OPEN, "Der Client nennt keinen Beruf – keiner gelernt?")
    else
        add(SC.BAD, "Fertigkeit nicht lesbar – die Seite zeigt Rezepte nur nach Rängen.")
    end
    local function has(f) return type(f) == "function" and "ja" or "nein" end
    add("", "   GetProfessions: " .. has(_G.GetProfessions) .. " · GetSkillLineInfo: " .. has(_G.GetSkillLineInfo))
    local ts = _G.C_TradeSkillUI
    add("", "   C_TradeSkillUI.GetAllRecipeIDs: " .. has(type(ts) == "table" and ts.GetAllRecipeIDs or nil)
        .. " · GetTradeSkillRecipeLink: " .. has(_G.GetTradeSkillRecipeLink)
        .. " · GetCraftRecipeLink: " .. has(_G.GetCraftRecipeLink))
    local mem = PRO.Memory and PRO.Memory()
    local scanned, known = {}, 0
    for key in pairs(mem and mem.scanned or {}) do scanned[#scanned + 1] = PRO.ProfName(key) end
    for _ in pairs(mem and mem.known or {}) do known = known + 1 end
    table.sort(scanned)
    if #scanned > 0 then
        add("", "   Aus dem Berufsfenster gemerkt: " .. table.concat(scanned, ", ") .. " (" .. known .. " Rezepte)")
    else
        add("", "   Noch kein Berufsfenster gelesen – einmal öffnen (Rezepte), dann wiederholen")
    end
    local ls = PRO.lastScan
    if ls then
        add("", "   Letzter Blick ins Berufsfenster: " .. ls.ids .. " Nummern vom Client (" .. (#ls.via > 0 and table.concat(ls.via, ", ") or "keine Abfrage")
            .. "), " .. ls.matched .. " im Bestand, " .. ls.count .. " gelernt")
        if ls.ids > 0 and ls.matched == 0 then
            add(SC.BAD, "Die Rezeptnummern des Clients passen nicht zum Bestand – „gelernt“ bleibt unbekannt.")
        end
    else
        add("", "   Seit dem Laden kein Blick ins Berufsfenster")
    end
    local evs = {}
    for _, e in ipairs({ "TRADE_SKILL_SHOW", "TRADE_SKILL_LIST_UPDATE", "CRAFT_SHOW", "NEW_RECIPE_LEARNED" }) do
        evs[#evs + 1] = e .. " " .. ((PRO.eventCount and PRO.eventCount[e]) or 0)
    end
    add("", "   Ereignisse seit dem Laden: " .. table.concat(evs, " · "))
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
