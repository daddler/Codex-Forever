--------------------------------------------------
-- WeintCodex :: Oberflaeche - Profil exportieren und importieren
--------------------------------------------------
-- Seit 6.28.0.0 (Beta-Test: "mein komplettes Layout inkl. aller
-- Einstellungen exportieren und importieren - Backup und Teilen"). Eine
-- Zeile Text zum Kopieren: das gewaehlte Profil (alle Einstellungen der
-- Oberflaeche und des Komforts samt Plaetzen der Rahmen) und, wenn der
-- Client es kann, das eigene Layout "WeintCodex" des Bearbeitungsmodus
-- (C_EditMode.ConvertLayoutInfoToString - das Format des Spiels).
--
-- SICHERHEIT: ein geteilter Text kommt von Fremden. Er wird NIE als Code
-- ausgefuehrt (kein loadstring) - ein eigener Leser kennt nur Zahlen,
-- Text, Wahrheitswerte und Tabellen, mit Grenzen fuer Tiefe und Laenge.
-- Ein Import ersetzt nur das GEWAEHLTE Profil und nur das Layout
-- "WeintCodex" - nie ein Layout des Spielers -, nach Rueckfrage, und wirkt
-- nach dem Neuladen.
--
-- SEIT 6.30.38.0 (Wunsch: "Profilimport und Export muss ALLES enthalten,
-- damit das Interface komplett so nutzbar ist - auch Blizzards
-- Bearbeitungsmodus, saemtliche Einstellungen"), Fassung 2, zusaetzlich:
--   * der Hauptschalter der Oberflaeche (an/aus fuer diesen Charakter)
--   * das AKTIVE Layout des Bearbeitungsmodus, auch ein eigenes des Spielers
--     (ohne Oberflaeche) - beim Import als NEUES Layout "<Name> (Import)"
--     angelegt und aktiviert, nie ueber ein bestehendes geschrieben
--   * die Einstellungen des Spiels (CVars), die vom Standard abweichen -
--     nur Spiel, Kampf, Oberflaeche und Ton (C_Console-Kategorien), NIE
--     Grafik, Netz, Konto oder Debug (haengt am Rechner bzw. ist privat)
--   * die Tastenbelegung des Spiels (alle belegten Befehle)
--   * der Platz des Minikarten-Symbols
--   * seit 6.42.0.0: welche Aktionsleisten an sind (GetActionBarToggles) -
--     im Profil als `bars`; ein Charakter, der das Profil zum ersten Mal
--     nutzt (neu erstellt), bekommt sie beim Einloggen gesetzt
-- Nicht moeglich ohne Risiko und deshalb nicht dabei: was auf den
-- Aktionsleisten liegt (je Charakter, Zauber muessen gelernt sein) und
-- die Chatfenster des Spiels.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIShare = {}

local SH = WeintCodex.UIShare
local K  = WeintCodex.UIKit
local C  = WeintCodex.Colors
local error = _G.error
local next  = _G.next

SH.PREFIX = "WCUI1:"
SH.MAX_DEPTH = 32
SH.MAX_LEN = 2000000

--------------------------------------------------
-- Schreiben und Lesen (kein Code, nur Daten)
--------------------------------------------------

local function Ser(v, out, depth)
    local t = type(v)
    if t == "number" then
        if v ~= v or v == math.huge or v == -math.huge then return end
        out[#out + 1] = "n" .. string.format("%.17g", v) .. ";"
    elseif t == "string" then
        out[#out + 1] = "s" .. #v .. ":" .. v
    elseif t == "boolean" then
        out[#out + 1] = v and "b1" or "b0"
    elseif t == "table" then
        if depth > SH.MAX_DEPTH then return end
        out[#out + 1] = "t"
        for k, x in pairs(v) do
            local tk, tx = type(k), type(x)
            if (tk == "string" or tk == "number") and (tx == "string" or tx == "number" or tx == "boolean" or tx == "table") then
                Ser(k, out, depth + 1)
                Ser(x, out, depth + 1)
            end
        end
        out[#out + 1] = "e"
    end
end

function SH.Serialize(v)
    local out = {}
    Ser(v, out, 0)
    return table.concat(out)
end

-- Gibt den Wert zurueck oder nil, Grund.
function SH.Deserialize(s)
    if type(s) ~= "string" then return nil, "kein Text" end
    local pos, n = 1, #s
    local function Read(depth)
        if depth > SH.MAX_DEPTH then error("zu tief") end
        local tag = s:sub(pos, pos)
        pos = pos + 1
        if tag == "n" then
            local e = s:find(";", pos, true)
            if not e then error("Zahl ohne Ende") end
            local v = tonumber(s:sub(pos, e - 1))
            if not v then error("keine Zahl") end
            pos = e + 1
            return v
        elseif tag == "s" then
            local e = s:find(":", pos, true)
            local len = e and tonumber(s:sub(pos, e - 1))
            if not len or len < 0 or e + len > n then error("Text kaputt") end
            local v = s:sub(e + 1, e + len)
            pos = e + len + 1
            return v
        elseif tag == "b" then
            local v = s:sub(pos, pos) == "1"
            pos = pos + 1
            return v
        elseif tag == "t" then
            local t = {}
            while true do
                if pos > n then error("Tabelle ohne Ende") end
                if s:sub(pos, pos) == "e" then pos = pos + 1 return t end
                local k = Read(depth + 1)
                if type(k) ~= "string" and type(k) ~= "number" then error("Schluessel kaputt") end
                t[k] = Read(depth + 1)
            end
        end
        error("unbekanntes Zeichen")
    end
    local ok, v = pcall(Read, 0)
    if not ok then return nil, tostring(v):gsub("^.-:%d+: ", "") end
    if pos <= n then return nil, "Rest nach dem Ende" end
    return v
end

-- Base64 (Lua 5.1, ohne Bit-Bibliothek): nur Zeichen, die der Chat und
-- Discord unveraendert lassen - kein "|", keine Zeilenumbrueche.
local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local DEC = {}
for i = 1, 64 do DEC[B64:sub(i, i)] = i - 1 end

function SH.Encode(s)
    local out = {}
    for i = 1, #s, 3 do
        local a, b, c = s:byte(i, i + 2)
        local n = a * 65536 + (b or 0) * 256 + (c or 0)
        local c1 = math.floor(n / 262144) % 64
        local c2 = math.floor(n / 4096) % 64
        local c3 = math.floor(n / 64) % 64
        local c4 = n % 64
        out[#out + 1] = B64:sub(c1 + 1, c1 + 1) .. B64:sub(c2 + 1, c2 + 1)
            .. (b and B64:sub(c3 + 1, c3 + 1) or "=") .. (c and B64:sub(c4 + 1, c4 + 1) or "=")
    end
    return table.concat(out)
end

function SH.Decode(s)
    s = s:gsub("[^%w%+/=]", "")
    if #s % 4 ~= 0 then return nil end
    local out = {}
    for i = 1, #s, 4 do
        local q = { s:byte(i, i + 3) }
        local v, pad = 0, 0
        for j = 1, 4 do
            local ch = string.char(q[j])
            local d
            if ch == "=" then d, pad = 0, pad + 1 else d = DEC[ch] end
            if not d then return nil end
            v = v * 64 + d
        end
        local a, b, c = math.floor(v / 65536) % 256, math.floor(v / 256) % 256, v % 256
        out[#out + 1] = string.char(a) .. (pad < 2 and string.char(b) or "") .. (pad < 1 and string.char(c) or "")
    end
    return table.concat(out)
end

--------------------------------------------------
-- Layout des Bearbeitungsmodus
--------------------------------------------------

local function OwnLayout()
    local em = _G.C_EditMode
    if not (em and em.GetLayouts) then return nil end
    local ok, info = pcall(em.GetLayouts)
    if not ok or type(info) ~= "table" or type(info.layouts) ~= "table" then return nil end
    local name = WeintCodex.UISetup and WeintCodex.UISetup.LAYOUT_NAME
    for i, l in ipairs(info.layouts) do
        if l.layoutName == name then return l, info, i end
    end
    return nil, info
end

function SH.LayoutString()
    local em = _G.C_EditMode
    local l = OwnLayout()
    if not (l and em and em.ConvertLayoutInfoToString) then return nil end
    local ok, s = pcall(em.ConvertLayoutInfoToString, l)
    return ok and type(s) == "string" and s ~= "" and s or nil
end

-- Schreibt das Layout als "WeintCodex" (ersetzt nur dieses). true / false, Grund.
-- activate (6.48.3.0, Beta-Test: "beim neuen Charakter wird das Layout von
-- Blizzard nicht mit uebernommen"): auch gleich aktiv setzen - vorher stand
-- es nur in der Liste, und ein neuer Charakter blieb auf der Vorlage des
-- Spiels. Das Layout von vorher wird gemerkt (PF.Remember), wie beim
-- Einrichten.
function SH.ImportLayout(str, activate)
    local em = _G.C_EditMode
    if not (em and em.ConvertStringToLayoutInfo and em.SaveLayouts) then return false, "Bearbeitungsmodus kann nicht einlesen" end
    local ok, l = pcall(em.ConvertStringToLayoutInfo, str)
    if not ok or type(l) ~= "table" then return false, "Layout nicht lesbar" end
    local _, info, slot = OwnLayout()
    if type(info) ~= "table" then return false, "Layouts nicht lesbar" end
    l.layoutName = WeintCodex.UISetup.LAYOUT_NAME
    local LT = _G.Enum and _G.Enum.EditModeLayoutType
    l.layoutType = LT and LT.Account or l.layoutType
    slot = slot or (#info.layouts + 1)
    info.layouts[slot] = l
    local PF = WeintCodex.UIProfile
    if activate and PF and PF.PresetCount then
        if PF.Remember then pcall(PF.Remember) end
        info.activeLayout = PF.PresetCount() + slot
    end
    local okS, err = pcall(em.SaveLayouts, info)
    if not okS then return false, "SaveLayouts: " .. tostring(err) end
    if activate and info.activeLayout and em.SetActiveLayout then pcall(em.SetActiveLayout, info.activeLayout) end
    return true
end

-- Ein Layout des Spielers als NEUES Layout "<Name> (Import)" (ein
-- frueheres gleichen Namens wird ersetzt), auf Wunsch aktiv. true, Name / false, Grund.
function SH.ImportGameLayout(str, name, activate)
    local em = _G.C_EditMode
    local PF = WeintCodex.UIProfile
    if not (em and em.ConvertStringToLayoutInfo and em.SaveLayouts and em.GetLayouts and PF and PF.PresetCount) then
        return false, "Bearbeitungsmodus kann nicht einlesen"
    end
    local ok, l = pcall(em.ConvertStringToLayoutInfo, str)
    if not ok or type(l) ~= "table" then return false, "Layout nicht lesbar" end
    local okI, info = pcall(em.GetLayouts)
    if not okI or type(info) ~= "table" or type(info.layouts) ~= "table" then return false, "Layouts nicht lesbar" end
    local target = tostring(name or "Layout"):gsub(" %(Import%)$", "") .. " (Import)"
    l.layoutName = target
    local LT = _G.Enum and _G.Enum.EditModeLayoutType
    l.layoutType = LT and LT.Account or l.layoutType
    local slot
    for i, x in ipairs(info.layouts) do if x.layoutName == target then slot = i end end
    slot = slot or (#info.layouts + 1)
    info.layouts[slot] = l
    if activate then info.activeLayout = PF.PresetCount() + slot end
    local okS, err = pcall(em.SaveLayouts, info)
    if not okS then return false, "SaveLayouts: " .. tostring(err) end
    if activate and em.SetActiveLayout then pcall(em.SetActiveLayout, info.activeLayout) end
    return true, target
end

function SH.ApplyCVars(list)
    local cv = _G.C_CVar
    local n, bad = 0, 0
    if not (cv and cv.SetCVar) then return 0, 0 end
    for name, v in pairs(list) do
        local skip = type(name) ~= "string" or type(v) ~= "string"
        for _, pat in ipairs(SH.CVAR_SKIP) do if not skip and name:find(pat) then skip = true end end
        if not skip then
            local ok, r = pcall(cv.SetCVar, name, v)
            if ok and r ~= false then n = n + 1 else bad = bad + 1 end
        end
    end
    return n, bad
end

-- Ersetzt die Tastenbelegung: erst alles Belegte loesen, dann setzen, dann
-- speichern (in den Satz, der gerade gilt: Konto oder Charakter).
function SH.ApplyBindings(list)
    local G = _G
    if type(G.SetBinding) ~= "function" or type(G.GetNumBindings) ~= "function" then return false, 0 end
    for _, b in ipairs(SH.Bindings() or {}) do
        for _, key in ipairs(b.k) do pcall(G.SetBinding, key) end
    end
    local n = 0
    for _, b in ipairs(list) do
        if type(b) == "table" and type(b.c) == "string" and type(b.k) == "table" then
            for _, key in ipairs(b.k) do
                if type(key) == "string" and pcall(G.SetBinding, key, b.c) then n = n + 1 end
            end
        end
    end
    if type(G.SaveBindings) == "function" then
        local set = type(G.GetCurrentBindingSet) == "function" and G.GetCurrentBindingSet() or 1
        pcall(G.SaveBindings, set)
    end
    return true, #list
end

--------------------------------------------------
-- Export und Import
--------------------------------------------------

-- Das aktive Layout des Spielers (wenn es nicht "WeintCodex" ist): Text, Name.
function SH.ActiveLayoutString()
    local em = _G.C_EditMode
    local PF = WeintCodex.UIProfile
    if not (em and em.GetLayouts and em.ConvertLayoutInfoToString and PF and PF.PresetCount) then return nil end
    local ok, info = pcall(em.GetLayouts)
    if not ok or type(info) ~= "table" or type(info.layouts) ~= "table" then return nil end
    local a = tonumber(K.Plain(info.activeLayout)) or 0
    local l = info.layouts[a - PF.PresetCount()]
    if type(l) ~= "table" or l.layoutName == WeintCodex.UISetup.LAYOUT_NAME then return nil end
    local okS, str = pcall(em.ConvertLayoutInfoToString, l)
    if not okS or type(str) ~= "string" or str == "" then return nil end
    return str, l.layoutName
end

-- C_Console-Kategorien, die mitgehen (Namen wie im Enum; fehlt das Enum,
-- gelten die Zahlen des heutigen Spiels).
SH.CVAR_CATS = { "Game", "Combat", "Default", "Sound" }
SH.CVAR_SKIP = { "^gx", "^graphics", "^raidGraphics", "^render", "^portal", "^realm", "^account",
                 "^lastCharacter", "^lastAddon", "^agentUID", "^telemetry", "^launcher", "^cache",
                 "^installLocale", "^textLocale", "^audioLocale", "^Sound_OutputDriver", "^Sound_.*Device",
                 "^lastSelected", "^seenTutorial", "^closedInfoFrames", "^flagged", "^moviePlayed",
                 "^trackedQuests", "^trackedAchievements", "^uiScale$", "^useUiScale$" }

function SH.CVarList()
    local cc, cv = _G.C_Console, _G.C_CVar
    if not (cc and cc.GetAllCommands and cv and cv.GetCVar and cv.GetCVarDefault) then return nil end
    local ok, all = pcall(cc.GetAllCommands)
    if not ok or type(all) ~= "table" then return nil end
    local E = _G.Enum and _G.Enum.ConsoleCategory
    local want = {}
    for _, n in ipairs(SH.CVAR_CATS) do if E and E[n] then want[E[n]] = true end end
    local CVAR = _G.Enum and _G.Enum.ConsoleCommandType and _G.Enum.ConsoleCommandType.Cvar
    local out = {}
    for _, c in ipairs(all) do
        local name = type(c) == "table" and K.Plain(c.command)
        local isVar = CVAR == nil or K.Plain(c.commandType) == CVAR
        if type(name) == "string" and isVar and (not E or want[K.Plain(c.category)]) then
            local skip = false
            for _, pat in ipairs(SH.CVAR_SKIP) do if name:find(pat) then skip = true break end end
            if not skip then
                local okV, v = pcall(cv.GetCVar, name)
                local okD, d = pcall(cv.GetCVarDefault, name)
                v, d = okV and K.Plain(v), okD and K.Plain(d)
                if type(v) == "string" and v ~= d then out[name] = v end
            end
        end
    end
    return out
end

function SH.Bindings()
    if type(_G.GetNumBindings) ~= "function" or type(_G.GetBinding) ~= "function" then return nil end
    local out = {}
    local ok, n = pcall(_G.GetNumBindings)
    for i = 1, (ok and tonumber(n) or 0) do
        local t = { pcall(_G.GetBinding, i, 1) }
        if t[1] and type(t[2]) == "string" and t[4] then
            local keys = {}
            for j = 4, #t do if type(t[j]) == "string" and t[j] ~= "" then keys[#keys + 1] = t[j] end end
            if #keys > 0 then out[#out + 1] = { c = t[2], k = keys } end
        end
    end
    return out
end

--------------------------------------------------
-- Aktionsleisten an/aus (6.42.0.0)
--------------------------------------------------
-- Wunsch: "erkennen, wie viele Leisten aktiv sind - beim neuen Charakter
-- mit dem Profil direkt die Aktionsleisten aktivieren". Der Client sagt es
-- mit GetActionBarToggles (je Leiste ab der zweiten ein Wahrheitswert),
-- gesetzt wird mit SetActionBarToggles - dieselben Aufrufe wie die
-- Optionen des Spiels. Nie im Kampf.

SH.NEW_LEVEL = 5   -- bis hier gilt ein Charakter ohne Eintrag als neu

-- Liste { true, false, ... } oder nil (Client kann es nicht).
function SH.BarToggles()
    local get = _G.GetActionBarToggles
    if type(get) ~= "function" then return nil end
    local res = { pcall(get) }
    if not res[1] then return nil end
    local out = {}
    for i = 2, #res do out[#out + 1] = K.Bool(res[i], false) end
    return #out > 0 and out or nil
end

function SH.CountBars(list)
    local n = 0
    for _, v in ipairs(list or {}) do if v then n = n + 1 end end
    return n
end

-- Setzt die Leisten. true / false, Grund.
function SH.ApplyBars(list)
    if type(list) ~= "table" or #list == 0 then return false, "nichts gespeichert" end
    if K.InCombat() then return false, "im Kampf" end
    local set = _G.SetActionBarToggles
    if type(set) ~= "function" then return false, "vom Spiel nicht angeboten" end
    local cur = SH.BarToggles() or {}
    local vals, same = {}, true
    for i = 1, math.max(#list, #cur) do
        local v = list[i]
        if v == nil then v = cur[i] or false end
        vals[i] = v and true or false
        if vals[i] ~= (cur[i] or false) then same = false end
    end
    if same then return true end
    local ok = pcall(set, unpack(vals))
    if not ok then return false, "vom Spiel abgelehnt" end
    if type(_G.MultiActionBar_Update) == "function" then pcall(_G.MultiActionBar_Update) end
    return true
end

-- Merkt die Leisten dieses Charakters im aktiven Profil.
function SH.RememberBars()
    local p = K.Profile and K.Profile()
    local bars = SH.BarToggles()
    if type(p) == "table" and bars then p.bars = bars end
end

-- Beim Einloggen: nutzt dieser Charakter das Profil zum ersten Mal (neu
-- erstellt oder gerade gewaehlt), bekommt er dessen Leisten.
function SH.OnLogin()
    local p = K.Profile and K.Profile()
    local st = K.CharState and K.CharState()
    if type(p) ~= "table" or type(st) ~= "table" then return end
    local name = K.ActiveProfile and K.ActiveProfile()
    if st.barsFrom == name then return end
    -- Charaktere von vor 6.42.0.0 (noch kein Eintrag, schon gespielt):
    -- nur merken, nichts umstellen - ihre Leisten hat der Spieler gesetzt.
    local lvl = K.Plain(_G.UnitLevel and _G.UnitLevel("player"))
    if st.barsFrom == nil and type(lvl) == "number" and lvl > SH.NEW_LEVEL then
        st.barsFrom = name
        return
    end
    if type(p.bars) == "table" and #p.bars > 0 then
        local ok = SH.ApplyBars(p.bars)
        if not ok then return end
        print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " Aktionsleisten aus dem Profil „" .. tostring(name)
            .. "“ eingeschaltet (" .. SH.CountBars(p.bars) .. " zusätzliche an).")
    end
    st.barsFrom = name
end

do
    local ev = CreateFrame("Frame")
    ev:RegisterEvent("PLAYER_ENTERING_WORLD")
    ev:RegisterEvent("PLAYER_LOGOUT")
    ev:SetScript("OnEvent", function(self, event)
        if event == "PLAYER_LOGOUT" then
            pcall(SH.RememberBars)
        else
            self:UnregisterEvent("PLAYER_ENTERING_WORLD")
            if _G.C_Timer and _G.C_Timer.After then _G.C_Timer.After(3, function() pcall(SH.OnLogin) end)
            else pcall(SH.OnLogin) end
        end
    end)
    SH.events = ev
end

function SH.Export()
    local ui = K.Root()
    local PR = WeintCodex.UIProfiles
    local name = PR.Chosen()
    local p = ui and ui.profiles[name]
    if type(p) ~= "table" then return nil end
    local gl, gln = SH.ActiveLayoutString()
    SH.RememberBars()
    local data = { v = 2, name = name, profile = p, layout = SH.LayoutString(),
                   addon = WeintCodex.Version,
                   uiEnabled = K.UIEnabled() and true or false,
                   gameLayout = gl, gameLayoutName = gln,
                   cvars = SH.CVarList(), bindings = SH.Bindings(),
                   launcher = type(ui.launcher) == "table" and ui.launcher or nil }
    return SH.PREFIX .. SH.Encode(SH.Serialize(data))
end

-- Was ein Text enthaelt, in Worten (fuer die Rueckfrage und den Bericht).
function SH.Contents(data)
    local parts = { "alle WeintCodex-Einstellungen und Plätze" }
    if data.layout then parts[#parts + 1] = "Layout „WeintCodex“" end
    if data.gameLayout then parts[#parts + 1] = "Layout „" .. tostring(data.gameLayoutName) .. "“ (als neues Layout)" end
    local n = 0
    for _ in pairs(type(data.cvars) == "table" and data.cvars or {}) do n = n + 1 end
    if n > 0 then parts[#parts + 1] = n .. " Spieleinstellungen" end
    if type(data.bindings) == "table" and #data.bindings > 0 then parts[#parts + 1] = "Tastenbelegung (" .. #data.bindings .. " Befehle)" end
    if data.uiEnabled ~= nil then parts[#parts + 1] = "Oberfläche " .. (data.uiEnabled and "an" or "aus") end
    if type(data.profile.bars) == "table" then parts[#parts + 1] = SH.CountBars(data.profile.bars) .. " zusätzliche Aktionsleisten an" end
    return table.concat(parts, ", ")
end

-- Liest einen Text: Tabelle oder nil, Grund. Aendert nichts.
function SH.Parse(text)
    if type(text) ~= "string" then return nil, "kein Text" end
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    if #text > SH.MAX_LEN then return nil, "zu lang" end
    if text:sub(1, #SH.PREFIX) ~= SH.PREFIX then return nil, "kein WeintCodex-Profil (beginnt nicht mit " .. SH.PREFIX .. ")" end
    local raw = SH.Decode(text:sub(#SH.PREFIX + 1))
    if not raw then return nil, "Text beschädigt" end
    local data, why = SH.Deserialize(raw)
    if type(data) ~= "table" then return nil, why or "Text beschädigt" end
    if (data.v ~= 1 and data.v ~= 2) or type(data.profile) ~= "table" then return nil, "unbekannte Fassung" end
    if data.layout ~= nil and type(data.layout) ~= "string" then data.layout = nil end
    if type(data.gameLayout) ~= "string" then data.gameLayout, data.gameLayoutName = nil, nil end
    if type(data.gameLayoutName) ~= "string" then data.gameLayoutName = "Layout" end
    if type(data.cvars) ~= "table" then data.cvars = nil end
    if type(data.bindings) ~= "table" then data.bindings = nil end
    if type(data.launcher) ~= "table" then data.launcher = nil end
    if type(data.uiEnabled) ~= "boolean" then data.uiEnabled = nil end
    if data.profile.bars ~= nil then
        local ok = type(data.profile.bars) == "table" and #data.profile.bars <= 16
        for _, v in ipairs(ok and data.profile.bars or {}) do if type(v) ~= "boolean" then ok = false end end
        if not ok then data.profile.bars = nil end
    end
    return data
end

-- Was ein Text enthaelt, als Liste zum Anhaken (6.30.55.0, Wunsch: "nach
-- dem Einfuegen eine Abfrage, was ich alles uebernehmen moechte - gerade
-- beim Teilen, Tastaturbelegungen sind individuell"). Je Eintrag
-- { id, label, game, on }: on = vorausgewaehlt. Die Tastenbelegung ist
-- NIE vorausgewaehlt - sie gehoert zur Hand, nicht zum Aussehen.
function SH.Items(data)
    local out = {}
    local src = data.profile
    local mods = type(src.modules) == "table" and src.modules or {}
    local keys = {}
    for key, v in pairs(mods) do
        if type(key) == "string" and type(v) == "table" and next(v) ~= nil then keys[#keys + 1] = key end
    end
    local function Title(key)
        local m = K.Module(key)
        return m and type(m.title) == "string" and m.title or key
    end
    table.sort(keys, function(x, y) return Title(x):lower() < Title(y):lower() end)
    for _, key in ipairs(keys) do
        out[#out + 1] = { id = "mod:" .. key, label = Title(key), on = true }
    end
    if type(src.positions) == "table" and next(src.positions) ~= nil then
        out[#out + 1] = { id = "positions", label = "Plätze der WeintCodex-Rahmen", on = true }
    end
    for k in pairs(src) do
        if k ~= "modules" and k ~= "positions" and k ~= "bars" then
            out[#out + 1] = { id = "rest", label = "Weitere Profilwerte", on = true }
            break
        end
    end
    if type(src.bars) == "table" then
        out[#out + 1] = { id = "bars", label = "Aktionsleisten (" .. SH.CountBars(src.bars) .. " zusätzliche an)", game = true, on = true }
    end
    if data.layout then out[#out + 1] = { id = "layout", label = "Layout „WeintCodex“ (Bearbeitungsmodus)", game = true, on = true } end
    if data.gameLayout then
        out[#out + 1] = { id = "gameLayout", label = "Layout „" .. tostring(data.gameLayoutName) .. "“ (als neues Layout)", game = true, on = true }
    end
    local n = 0
    for _ in pairs(data.cvars or {}) do n = n + 1 end
    if n > 0 then out[#out + 1] = { id = "cvars", label = "Spieleinstellungen (" .. n .. ")", game = true, on = true } end
    if data.bindings and #data.bindings > 0 then
        out[#out + 1] = { id = "bindings", label = "Tastenbelegung (" .. #data.bindings .. " Befehle) – ersetzt deine", game = true, on = false }
    end
    if data.launcher then out[#out + 1] = { id = "launcher", label = "Platz des Minikarten-Symbols", game = true, on = true } end
    if data.uiEnabled ~= nil then
        out[#out + 1] = { id = "uiEnabled", label = "Oberfläche " .. (data.uiEnabled and "an" or "aus") .. " (Hauptschalter)", game = true, on = true }
    end
    return out
end

-- Vorauswahl als Menge { [id] = true }.
function SH.DefaultSelection(data)
    local sel = {}
    for _, it in ipairs(SH.Items(data)) do if it.on then sel[it.id] = true end end
    return sel
end

-- Uebernimmt einen gelesenen Text ins gewaehlte Profil. true / false, Grund, Layout-Hinweis.
-- sel: Menge der Eintraege aus SH.Items; nil = alles (wie vor 6.30.55.0).
-- Nicht Gewaehltes bleibt, wie es ist.
function SH.Apply(data, sel)
    local ui = K.Root()
    local PR = WeintCodex.UIProfiles
    local target = PR.Chosen()
    local p = ui and ui.profiles[target]
    if type(p) ~= "table" then return false, "kein Profil gewählt" end
    local function Want(id) return sel == nil or sel[id] == true end
    local src = data.profile
    if sel == nil then
        -- Dieselbe Tabelle behalten (K.Profile hat sie vielleicht in der Hand).
        for k in pairs(p) do p[k] = nil end
        for k, v in pairs(PR.DeepCopy(src)) do p[k] = v end
    else
        if type(p.modules) ~= "table" then p.modules = {} end
        for key, v in pairs(type(src.modules) == "table" and src.modules or {}) do
            if Want("mod:" .. tostring(key)) then p.modules[key] = PR.DeepCopy(v) end
        end
        if Want("positions") and type(src.positions) == "table" then p.positions = PR.DeepCopy(src.positions) end
        if Want("rest") then
            for k, v in pairs(src) do
                if k ~= "modules" and k ~= "positions" and k ~= "bars" then p[k] = PR.DeepCopy(v) end
            end
        end
        if Want("bars") and type(src.bars) == "table" then p.bars = PR.DeepCopy(src.bars) end
        if type(p.positions) ~= "table" then p.positions = {} end
    end
    local notes = {}
    local uiOn = data.uiEnabled
    if not Want("uiEnabled") or uiOn == nil then uiOn = K.UIEnabled() and true or false end
    if data.layout and Want("layout") then
        local ok, why = SH.ImportLayout(data.layout, uiOn)
        notes[#notes + 1] = ok and ("Layout „WeintCodex“ übernommen" .. (uiOn and " und aktiv." or ".")) or ("Layout nicht übernommen: " .. tostring(why) .. ".")
    end
    if data.gameLayout and Want("gameLayout") then
        local ok, why = SH.ImportGameLayout(data.gameLayout, data.gameLayoutName, not uiOn)
        notes[#notes + 1] = ok and ("Layout „" .. why .. "“ angelegt.") or ("Layout nicht übernommen: " .. tostring(why) .. ".")
    end
    if type(src.bars) == "table" and Want("bars") then
        local ok, why = SH.ApplyBars(src.bars)
        notes[#notes + 1] = ok and (SH.CountBars(src.bars) .. " zusätzliche Aktionsleisten an.") or ("Aktionsleisten nicht gesetzt: " .. tostring(why) .. ".")
        -- Dieser Charakter hat sie schon - beim Einloggen nicht noch einmal.
        local st = K.CharState and K.CharState()
        if ok and type(st) == "table" and target == PR.Active() then st.barsFrom = target end
    end
    if data.cvars and Want("cvars") then
        local n, bad = SH.ApplyCVars(data.cvars)
        notes[#notes + 1] = n .. " Spieleinstellungen gesetzt" .. (bad > 0 and (", " .. bad .. " nicht") or "") .. "."
    end
    if data.bindings and Want("bindings") then
        local ok, n = SH.ApplyBindings(data.bindings)
        notes[#notes + 1] = ok and ("Tastenbelegung übernommen (" .. n .. " Befehle).") or "Tastenbelegung nicht übernommen."
    end
    if data.launcher and Want("launcher") and type(ui.launcher) == "table" then
        for k, v in pairs(PR.DeepCopy(data.launcher)) do ui.launcher[k] = v end
    end
    if data.uiEnabled ~= nil and Want("uiEnabled") and K.SetUIEnabled then pcall(K.SetUIEnabled, data.uiEnabled) end
    local layoutNote = #notes > 0 and table.concat(notes, " ") or nil
    if target == PR.Active() then K.MarkReload() end
    K.Fire("setting", "general", "profile")
    return true, target, layoutNote
end

local function Say(text)
    print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " " .. text)
end

function SH.ShowExport()
    local s = SH.Export()
    if not s then Say("Kein Profil zum Exportieren.") return end
    local PR = WeintCodex.UIProfiles
    K.ShowReport("Profil „" .. PR.Chosen() .. "“ exportieren – kopieren und sicher ablegen oder teilen", s)
end

--------------------------------------------------
-- Fenster zum Einfuegen
--------------------------------------------------

local win
local function BuildImport()
    local f = CreateFrame("Frame", "WeintCodexImportProfile", UIParent)
    f:SetSize(K.REPORT_W, 300)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
    f:SetFrameStrata("FULLSCREEN_DIALOG")   -- ueber /wcui (6.28.0.1)
    f:SetToplevel(true)
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetClampedToScreen(true)
    K.Kachel(f, { shadow = 8 })
    if type(_G.UISpecialFrames) == "table" then table.insert(_G.UISpecialFrames, "WeintCodexImportProfile") end
    local title = K.NewText(f, 14)
    title:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -14)
    title:SetTextColor(unpack(C.textBright))
    f.title = title
    local hint = K.NewText(f, 11)
    hint:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    hint:SetPoint("RIGHT", f, "RIGHT", -16, 0)
    hint:SetJustifyH("LEFT")
    hint:SetTextColor(unpack(C.textMuted))
    f.hint = hint
    local box = CreateFrame("Frame", nil, f)
    box:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -60)
    box:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -14, 52)
    local bg = box:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(box)
    bg:SetColorTexture(unpack(C.bgDark))
    K.Border(box, 1, 0, 0, 0, 1, "BORDER")
    local scroll = CreateFrame("ScrollFrame", nil, box, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", box, "TOPLEFT", 6, -6)
    scroll:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -26, 6)
    local eb = CreateFrame("EditBox", nil, scroll)
    eb:SetMultiLine(true)
    eb:SetMaxLetters(0)
    eb:SetAutoFocus(false)
    eb:SetWidth(K.REPORT_W - 60)
    K.SetFont(eb, 11)
    eb:SetTextColor(unpack(C.textNormal))
    eb:SetScript("OnEscapePressed", function() f:Hide() end)
    scroll:SetScrollChild(eb)
    f.edit = eb
    local close = WeintCodex.CreateButton(f, { text = "Abbrechen", kind = "secondary", width = 120, height = 28,
        onClick = function() f:Hide() end })
    close:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -14, 14)
    local go = WeintCodex.CreateButton(f, { text = "Weiter", kind = "primary", width = 150, height = 28,
        onClick = function() SH.ImportFrom(eb:GetText()) end })
    go:SetPoint("RIGHT", close, "LEFT", -8, 0)
    f.go, f.close = go, close
    f.box = box

    -- Zweiter Schritt: Auswahl, was uebernommen wird (6.30.55.0).
    local pick = CreateFrame("Frame", nil, f)
    pick:SetPoint("TOPLEFT", box, "TOPLEFT", 0, 0)
    pick:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", 0, 0)
    local pbg = pick:CreateTexture(nil, "BACKGROUND")
    pbg:SetAllPoints(pick)
    pbg:SetColorTexture(unpack(C.bgDark))
    K.Border(pick, 1, 0, 0, 0, 1, "BORDER")
    local ps = CreateFrame("ScrollFrame", nil, pick, "UIPanelScrollFrameTemplate")
    ps:SetPoint("TOPLEFT", pick, "TOPLEFT", 8, -8)
    ps:SetPoint("BOTTOMRIGHT", pick, "BOTTOMRIGHT", -26, 8)
    local list = CreateFrame("Frame", nil, ps)
    list:SetSize(K.REPORT_W - 70, 10)
    ps:SetScrollChild(list)
    pick.list, pick.rows, pick.heads = list, {}, {}
    pick:Hide()
    f.pick = pick
    local apply = WeintCodex.CreateButton(f, { text = "Übernehmen", kind = "primary", width = 150, height = 28,
        onClick = function() SH.ApplyChoice() end })
    apply:SetPoint("RIGHT", close, "LEFT", -8, 0)
    local all = WeintCodex.CreateButton(f, { text = "Alle", kind = "secondary", width = 80, height = 28,
        onClick = function() SH.SelectAll(true) end })
    all:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 14, 14)
    local none = WeintCodex.CreateButton(f, { text = "Keine", kind = "secondary", width = 80, height = 28,
        onClick = function() SH.SelectAll(false) end })
    none:SetPoint("LEFT", all, "RIGHT", 8, 0)
    f.apply, f.all, f.none = apply, all, none
    apply:Hide() all:Hide() none:Hide()
    return f
end

-- Schritt umschalten: "paste" (Text einfuegen) oder "pick" (anhaken).
local function Step(step)
    local pickMode = step == "pick"
    win.box:SetShown(not pickMode)
    win.go:SetShown(not pickMode)
    win.pick:SetShown(pickMode)
    win.apply:SetShown(pickMode)
    win.all:SetShown(pickMode)
    win.none:SetShown(pickMode)
    win:SetHeight(pickMode and 480 or 300)
end

local function Head(i, text)
    local h = win.pick.heads[i]
    if not h then
        h = K.NewText(win.pick.list, 10)
        h:SetTextColor(unpack(C.textMuted))
        win.pick.heads[i] = h
    end
    h:SetText(text)
    h:Show()
    return h
end

-- Baut die Liste zum Anhaken.
function SH.ShowChoice(data)
    win = win or BuildImport()
    SH.win = win
    SH.pending = data
    SH.sel = SH.DefaultSelection(data)
    local items = SH.Items(data)
    local from = type(data.name) == "string" and data.name or "?"
    local PR = WeintCodex.UIProfiles
    win.title:SetText("Profil „" .. from .. "“ – was übernehmen?")
    win.hint:SetText("Angehakt wird übernommen, der Rest bleibt, wie er ist. WeintCodex-Teile landen in „"
        .. PR.Chosen() .. "“. Die Tastenbelegung ist bewusst nicht vorgewählt.")
    local list = win.pick.list
    for _, r in ipairs(win.pick.rows) do r:Hide() end
    for _, h in ipairs(win.pick.heads) do h:Hide() end
    local y, n, hn, lastGame = 0, 0, 0, nil
    local W = K.REPORT_W - 70
    for _, it in ipairs(items) do
        if it.game ~= lastGame then
            hn = hn + 1
            local h = Head(hn, it.game and "SPIEL" or "WEINTCODEX")
            h:ClearAllPoints()
            h:SetPoint("TOPLEFT", list, "TOPLEFT", 2, -y - (y > 0 and 8 or 0))
            y = y + (y > 0 and 8 or 0) + 16
            lastGame = it.game
        end
        n = n + 1
        local id = it.id
        local row = win.pick.rows[n]
        if not row then
            local r
            r = WeintCodex.CreateToggle(list, { label = "", width = W, height = 24,
                get = function() return r and SH.sel and SH.sel[r._id] == true or false end,
                set = function(on) if r and SH.sel then SH.sel[r._id] = on or nil end end })
            row = r
            win.pick.rows[n] = row
        end
        row._id = id
        row._label:SetText(it.label)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", list, "TOPLEFT", 0, -y)
        if row.Sync then row:Sync() end
        row:Show()
        y = y + 26
    end
    list:SetHeight(math.max(y, 10))
    Step("pick")
    win:Show()
    if win.Raise then win:Raise() end
    return win
end

function SH.SelectAll(on)
    if not SH.pending then return end
    for _, it in ipairs(SH.Items(SH.pending)) do SH.sel[it.id] = on or nil end
    for _, r in ipairs(win.pick.rows) do if r:IsShown() and r.Sync then r:Sync() end end
end

function SH.ApplyChoice()
    local data, sel = SH.pending, SH.sel
    if not data then return false end
    if K.InCombat() then Say("Import nicht im Kampf – Tastenbelegung und Spieleinstellungen sind dann gesperrt.") return false end
    if not next(sel) then Say("Nichts angehakt – nichts übernommen.") return false end
    local ok, target, note = SH.Apply(data, sel)
    if ok then
        Say("Profil in „" .. target .. "“ importiert. " .. (note and (note .. " ") or "") .. "Neu laden, damit es gilt.")
        SH.pending, SH.sel = nil, nil
        if win then win:Hide() end
    else
        Say("Import nicht möglich: " .. tostring(target) .. ".")
    end
    return ok
end

function SH.ShowImport()
    win = win or BuildImport()
    local PR = WeintCodex.UIProfiles
    win.title:SetText("Profil importieren")
    win.hint:SetText("Text einfügen (Strg+V) und „Weiter“ – danach wählst du, was übernommen wird (Ziel: „" .. PR.Chosen() .. "“).")
    win.edit:SetText("")
    Step("paste")
    win:Show()
    if win.Raise then win:Raise() end
    win.edit:SetFocus()
    SH.win = win
    return win
end

function SH.ImportFrom(text)
    local data, why = SH.Parse(text)
    if not data then Say("Import nicht möglich: " .. tostring(why) .. ".") return false end
    if K.InCombat() then Say("Import nicht im Kampf – Tastenbelegung und Spieleinstellungen sind dann gesperrt.") return false end
    SH.ShowChoice(data)
    return true
end
