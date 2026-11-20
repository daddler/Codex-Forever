--------------------------------------------------
-- WeintCodex :: Kampfhilfen (1.0.8.0; Einstellungen auf "Helfer" und "PvP")
--------------------------------------------------
-- Wunsch (grosses Update, nach dem Vergleich mit dem Addon "All in One" -
-- ohne Lizenz, darum nur das Verhalten nachgebaut, eigener Code):
--   VERLAUF    die letzten eigenen Zauber als Symbole, das neueste links;
--              aeltere verblassen. Im Kampf kann die Zaubernummer geheim
--              sein - das Symbol geht dann ungelesen an das Spiel.
--   HEILER     wird ein Heiler der eigenen Gruppe kontrolliert (betaeubt,
--              verwandelt, gefuerchtet ...), eine Leiste oben mit Name,
--              Zauber und Restzeit. Heiler ist, wen die Gruppenrolle so
--              nennt - ohne Rolle keiner, nie geraten. Was kontrolliert,
--              sagt die Liste CC unten (Zauber aus Classic, Art `classic`).
--              Sind die Auren im Kampf geheim, zeigt die Leiste nichts.
--   ABKLING    zuendet ein gegnerischer Spieler einen grossen Zauber
--              (Liste BIG unten, Classic), eine Meldung in der Mitte.
--   SPEZ       an der Plakette gegnerischer Spieler der Talentbaum, sobald
--              sie einen Zauber wirken, den nur dieser Baum lehrt (Namen
--              vom Client gegen data/talenttrees.lua). Nie geraten: wer
--              nichts Eindeutiges wirkt, bekommt nichts.
--   AUSBLENDEN Questliste bzw. Chat des Spiels im Kampf durchsichtig
--              (nur Deckkraft - beides traegt geschuetzte Knoepfe).
-- Alles ab Werk aus (neue Elemente auf dem Bildschirm). Nichts wird
-- gesendet.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UICombatAids = {}

local CA = WeintCodex.UICombatAids
local K  = WeintCodex.UIKit
local C  = WeintCodex.Colors
local KEY = "comfort"

CA.DEFAULTS = {
    caHistory = false, caHistoryCount = 6,
    caHealerCC = false, caHealerSound = true,
    caEnemyCD = false, caEnemyCDSound = false,
    caEnemySpec = false,
    caHideQuests = false, caHideChat = false,
}
CA.HISTORY_FADE = 12      -- Sekunden, bis ein Symbol ganz verblasst
CA.HISTORY_SIZE = 30
CA.CD_AGAIN = 20          -- gleiche Meldung je Gegner und Zauber hoechstens alle 20 s

-- Kontrolle (Classic-IDs aller Raenge; Art `classic`).
CA.CC = {}
for _, id in ipairs({
    118, 12824, 12825, 12826, 28271, 28272,              -- Verwandlung
    5782, 6213, 6215, 5484, 17928, 6358,                 -- Furcht, Schreckensgeheul, Verfuehrung
    6789, 17925, 17926,                                  -- Todesmantel
    8122, 8124, 10888, 10890, 605, 10911, 10912, 15487,  -- Psychischer Schrei, Gedankenkontrolle, Stille
    853, 5588, 5589, 10308, 20066,                       -- Hammer der Gerechtigkeit, Buße
    6770, 2070, 11297, 1776, 1777, 8629, 11285, 11286,   -- Kopfnuss, Solarplexus
    2094, 408, 8643, 1833,                               -- Blenden, Nierenhieb, Fieser Trick
    5246, 12809, 7922, 20253, 20614, 20615,              -- Drohruf, Erschütternder Schlag, Sturmangriff, Abfangen
    3355, 14308, 14309, 19503, 19386, 24132, 24133, 24394, -- Eiskältefalle, Streuschuss, Wyverngift, Einschüchterung
    2637, 18657, 18658, 5211, 6798, 8983, 9005,          -- Winterschlaf, Hieb, Anspringen
    20549, 18469, 24259,                                 -- Kriegsdonner, Gegenzauber, Zaubersperre
}) do CA.CC[id] = true end

-- Grosse Abklingzeiten (Classic-IDs; Art `classic`).
CA.BIG = {}
for _, id in ipairs({
    642, 1020, 1022, 5599, 10278, 633, 2800, 10310, 20216,   -- Gottesschild, Segen des Schutzes, Handauflegung, Göttliche Gunst
    11958, 12472, 12042, 11129, 12043, 11426,                -- Eisblock, Kälteeinbruch, Arkane Macht, Verbrennung, Geistesgegenwart, Eisbarriere
    1719, 871, 20230, 12328, 18499, 12292,                   -- Tollkühnheit, Schildwall, Gegenschlag, Todeswunsch, Berserkerwut, Rage
    5277, 13877, 13750, 1856, 1857, 2983, 8696, 11305,       -- Entrinnen, Klingenwirbel, Adrenalinrausch, Verschwinden, Sprinten
    29166, 17116, 16188, 10060, 14751, 6346,                 -- Anregen, Schnelligkeit der Natur, Seele der Macht, Innerer Fokus, Furchtschutz
    19574, 3045, 19263,                                      -- Zorn des Wildtiers, Schnellfeuer, Abschreckung
    7744, 20600, 20589, 20594, 20549,                        -- Wille der Verlassenen, Wahrnehmung, Entfesselungskünstler, Steingestalt, Kriegsdonner
}) do CA.BIG[id] = true end

local function Opt(k) return K.IsActive(KEY) and K.Get(KEY, k) and true or false end
local function Now() local t = _G.GetTime and K.Plain(_G.GetTime()) return type(t) == "number" and t or 0 end
CA.Opt = Opt

local function SpellName(id)
    local cs = _G.C_Spell
    if cs and cs.GetSpellName then
        local ok, n = pcall(cs.GetSpellName, id)
        n = ok and K.Plain(n) or nil
        if type(n) == "string" then return n end
    end
    if _G.GetSpellInfo then
        local ok, n = pcall(_G.GetSpellInfo, id)
        n = ok and K.Plain(n) or nil
        if type(n) == "string" then return n end
    end
    return nil
end

local function SpellIcon(id)
    local cs = _G.C_Spell
    if cs and cs.GetSpellTexture then
        local ok, t = pcall(cs.GetSpellTexture, id)
        if ok then return t end           -- auch geheim: geht ungelesen an SetTexture
    end
    return nil
end

local function Big(text)
    local col = C.warning
    if _G.RaidNotice_AddMessage and _G.RaidWarningFrame then
        pcall(_G.RaidNotice_AddMessage, _G.RaidWarningFrame, text, { r = col[1], g = col[2], b = col[3] })
    end
end

local function Sound(key)
    local FA = WeintCodex.UIFireAlarm
    if FA and FA.PlayKey then pcall(FA.PlayKey, key or "alarm", "Master") end
end

--------------------------------------------------
-- Zauberverlauf
--------------------------------------------------
-- Ein Ring aus festen Eintraegen - je Wirken keine neue Tabelle.
CA.ring = {}
for i = 1, 10 do CA.ring[i] = { id = nil, at = 0 } end
CA.head = 0
CA.SKIP = { [6603] = true, [75] = true, [5019] = true }   -- Angriff, Autoschuss, Schießen (Zauberstab)

function CA.Push(spellID, now)
    if not K.IsSecret(spellID) and (type(spellID) ~= "number" or CA.SKIP[spellID]) then return false end
    CA.head = CA.head % #CA.ring + 1
    local e = CA.ring[CA.head]
    e.id, e.at = spellID, now or Now()
    return true
end

-- i-tes Neueste (1 = zuletzt) oder nil.
function CA.Entry(i)
    if i > #CA.ring then return nil end
    local idx = (CA.head - i) % #CA.ring + 1
    local e = CA.ring[idx]
    if e.id == nil then return nil end
    return e
end

local hist
local function BuildHistory()
    if hist then return hist end
    hist = CreateFrame("Frame", "WeintCodexSpellHistory", UIParent)
    hist:SetSize(CA.HISTORY_SIZE, CA.HISTORY_SIZE)
    hist.icons = {}
    hist.WCShowForUnlock = function(self, on) self._unlock = on and true or nil CA.DrawHistory() end
    K.RegisterMover(hist, "spellhistory", "Zauberverlauf", K.Layout("spellhistory"))
    return hist
end

function CA.DrawHistory()
    if not hist then return end
    local on = Opt("caHistory") or hist._unlock
    local n = math.max(3, math.min(10, tonumber(K.Get(KEY, "caHistoryCount")) or 6))
    local s, gap, now = CA.HISTORY_SIZE, 4, Now()
    hist:SetSize(n * s + (n - 1) * gap, s)
    for i = 1, n do
        local b = hist.icons[i]
        if not b then
            b = CreateFrame("Frame", nil, hist)
            b:SetSize(s, s)
            b.icon = b:CreateTexture(nil, "ARTWORK")
            b.icon:SetAllPoints(b)
            b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            K.Border(b, 1, 0, 0, 0, 1, "OVERLAY")
            hist.icons[i] = b
        end
        b:ClearAllPoints()
        b:SetPoint("LEFT", hist, "LEFT", (i - 1) * (s + gap), 0)
        local e = on and CA.Entry(i)
        local age = e and (now - e.at) or nil
        if e and (hist._unlock or age < CA.HISTORY_FADE) then
            b.icon:SetTexture(SpellIcon(e.id))
            b:SetAlpha(hist._unlock and 1 or math.max(0.15, 1 - age / CA.HISTORY_FADE) * (i == 1 and 1 or 0.85))
            b:Show()
        elseif hist._unlock then
            b.icon:SetColorTexture(0.2, 0.2, 0.22, 0.8)
            b:SetAlpha(1)
            b:Show()
        else
            b:Hide()
        end
    end
    for i = n + 1, #hist.icons do hist.icons[i]:Hide() end
end

--------------------------------------------------
-- Heiler unter Kontrolle
--------------------------------------------------
-- Einheiten der Gruppe mit der Rolle Heiler (ohne den Spieler selbst).
function CA.Healers(out)
    out = out or {}
    for i = #out, 1, -1 do out[i] = nil end
    if not _G.UnitGroupRolesAssigned then return out end
    local raid = _G.IsInRaid and K.Bool(K.Plain(_G.IsInRaid()), false)
    local n = _G.GetNumGroupMembers and K.Plain(_G.GetNumGroupMembers()) or 0
    if type(n) ~= "number" or n <= 1 then return out end
    for i = 1, raid and n or (n - 1) do
        local u = (raid and "raid" or "party") .. i
        if not (_G.UnitIsUnit and K.Bool(K.Plain(_G.UnitIsUnit(u, "player")), false)) then
            local r = K.Plain(_G.UnitGroupRolesAssigned(u))
            if r == "HEALER" then out[#out + 1] = u end
        end
    end
    return out
end

-- Erste Kontrolle auf einer Einheit: spellId, Ende (oder nil), Symbol -
-- oder nil (keine / nicht lesbar).
function CA.ControlOf(unit)
    local ua = _G.C_UnitAuras
    if not (ua and ua.GetAuraDataByIndex) then return nil end
    for i = 1, 40 do
        local ok, a = pcall(ua.GetAuraDataByIndex, unit, i, "HARMFUL")
        if not ok or type(a) ~= "table" then return nil end
        local id = K.Plain(a.spellId)
        if type(id) == "number" and CA.CC[id] then
            local e = K.Plain(a.expirationTime)
            return id, (type(e) == "number" and e > 0) and e or nil, K.Plain(a.icon)
        end
    end
    return nil
end

local ccBar
local healers, ccShown = {}, nil
local function BuildCC()
    if ccBar then return ccBar end
    ccBar = CreateFrame("Frame", "WeintCodexHealerCC", UIParent)
    ccBar:SetSize(300, 30)
    K.Kachel(ccBar, { shadow = 4 })
    ccBar.icon = ccBar:CreateTexture(nil, "ARTWORK")
    ccBar.icon:SetSize(22, 22)
    ccBar.icon:SetPoint("LEFT", ccBar, "LEFT", 4, 0)
    ccBar.text = K.NewText(ccBar, 12)
    ccBar.text:SetPoint("LEFT", ccBar.icon, "RIGHT", 8, 0)
    ccBar.text:SetPoint("RIGHT", ccBar, "RIGHT", -8, 0)
    ccBar.text:SetJustifyH("LEFT")
    ccBar.text:SetTextColor(unpack(C.textBright))
    ccBar.WCShowForUnlock = function(self, on)
        self._unlock = on and true or nil
        if on then self.text:SetText("Heiler: Verwandlung 6 s") self:Show() else CA.UpdateCC() end
    end
    K.RegisterMover(ccBar, "healercc", "Heiler unter Kontrolle", K.Layout("healercc"))
    ccBar:Hide()
    return ccBar
end

function CA.UpdateCC()
    if not ccBar or ccBar._unlock then return end
    if not Opt("caHealerCC") then ccBar:Hide() ccShown = nil return end
    local now = Now()
    for _, u in ipairs(CA.Healers(healers)) do
        local id, ends, icon = CA.ControlOf(u)
        if id then
            local name = _G.UnitName and K.Plain(_G.UnitName(u)) or nil
            local left = ends and math.max(0, ends - now) or nil
            ccBar.icon:SetTexture(icon or SpellIcon(id))
            ccBar.text:SetText((type(name) == "string" and name or "Heiler") .. ": " .. (SpellName(id) or "Kontrolle")
                .. (left and string.format(" %d s", math.ceil(left)) or ""))
            ccBar:Show()
            local key = tostring(u) .. ":" .. id
            if ccShown ~= key then
                ccShown = key
                if Opt("caHealerSound") then Sound("alarm") end
            end
            return true
        end
    end
    ccBar:Hide()
    ccShown = nil
    return false
end

--------------------------------------------------
-- Grosse Abklingzeiten und Spezialisierung gegnerischer Spieler
--------------------------------------------------
CA.cdSeen = {}
local function EnemyPlayer(unit)
    if type(unit) ~= "string" or not (unit:find("^nameplate%d+$") or unit:find("^arena%d$") or unit == "target" or unit == "focus") then
        return false
    end
    if not K.Bool(K.Plain(_G.UnitIsPlayer and _G.UnitIsPlayer(unit)), false) then return false end
    return K.Bool(K.Plain(_G.UnitCanAttack and _G.UnitCanAttack("player", unit)), false)
end

function CA.OnEnemyCast(unit, spellID, now)
    if K.IsSecret(spellID) or type(spellID) ~= "number" then return nil end
    if not EnemyPlayer(unit) then return nil end
    now = now or Now()
    local guid = _G.UnitGUID and K.Plain(_G.UnitGUID(unit))
    local result
    if Opt("caEnemyCD") and CA.BIG[spellID] then
        local key = tostring(guid) .. ":" .. spellID
        if not CA.cdSeen[key] or now - CA.cdSeen[key] > CA.CD_AGAIN then
            CA.cdSeen[key] = now
            local name = _G.UnitName and K.Plain(_G.UnitName(unit))
            Big((type(name) == "string" and name or "Gegner") .. ": " .. (SpellName(spellID) or "großer Zauber"))
            if Opt("caEnemyCDSound") then Sound("alarm") end
            result = "cd"
        end
    end
    if Opt("caEnemySpec") and type(guid) == "string" then
        local spec = CA.SpecOfSpell(unit, spellID)
        if spec then
            CA.specOf[guid] = spec
            CA.MarkSpec(unit)
            result = result or "spec"
        end
    end
    return result
end

-- Talentbaum zu einem gewirkten Zauber: ueber den Namen (alle Raenge)
-- gegen die Talente der Klasse (data/talenttrees.lua). Name des Baums aus
-- data/specs.lua (Reihenfolge = Baum 1..3).
CA.specOf = {}
local treeByName = {}   -- [Klasse] = { [Zaubername] = Baum }
function CA.TreeOf(class, spellID)
    local trees = WeintCodex.TalentTrees and WeintCodex.TalentTrees[class]
    if not trees then return nil end
    local map = treeByName[class]
    if not map then
        map = {}
        for _, t in pairs(trees) do
            local n = SpellName(t[1])
            if n and t[2] == 1 then map[n] = t[4] end   -- einrangig: aktive Faehigkeiten
        end
        treeByName[class] = map
    end
    local n = SpellName(spellID)
    return n and map[n] or nil
end
function CA.SpecName(class, tree)
    local i = 0
    for _, s in ipairs(_G.WeintCodex_Specs or {}) do
        if s.class == class then
            i = i + 1
            if i == tree then return s.name end
        end
    end
    return nil
end
function CA.SpecOfSpell(unit, spellID)
    if not _G.UnitClass then return nil end
    local _, class = _G.UnitClass(unit)
    class = K.Plain(class)
    if type(class) ~= "string" then return nil end
    local tree = CA.TreeOf(class, spellID)
    return tree and CA.SpecName(class, tree) or nil
end

local tags = setmetatable({}, { __mode = "k" })
function CA.MarkSpec(unit)
    if type(unit) ~= "string" or not unit:find("^nameplate%d+$") then return end
    local np = _G.C_NamePlate
    if not (np and np.GetNamePlateForUnit) then return end
    local ok, plate = pcall(np.GetNamePlateForUnit, unit)
    if not ok or not plate or (plate.IsForbidden and plate:IsForbidden()) then return end
    local guid = _G.UnitGUID and K.Plain(_G.UnitGUID(unit))
    local spec = Opt("caEnemySpec") and type(guid) == "string" and EnemyPlayer(unit) and CA.specOf[guid] or nil
    local t = tags[plate]
    if not spec then if t then t:Hide() end return end
    if not t then
        t = CreateFrame("Frame", nil, plate)
        t:SetSize(80, 14)
        t:SetPoint("BOTTOM", plate, "TOP", 0, 18)
        t:SetFrameStrata("HIGH")
        t.text = K.NewText(t, 10)
        t.text:SetPoint("CENTER")
        t.text:SetTextColor(unpack(C.textBright))
        tags[plate] = t
    end
    t.text:SetText(spec)
    t:Show()
end

--------------------------------------------------
-- Oberflaeche im Kampf ausblenden
--------------------------------------------------
CA.QUEST_FRAMES = { "ObjectiveTrackerFrame", "QuestWatchFrame", "WatchFrame" }
-- Nur Rahmen, die WeintCodex selbst ausgeblendet hat (oder jetzt
-- ausblendet), bekommen ihre Deckkraft zurueck - sonst nichts anfassen
-- (1.0.8.0: setzte vorher nach jedem Kampf alles auf 1, auch ganz ohne
-- diese Schalter).
CA.faded = {}
function CA.ApplyHide(fighting)
    local function Fade(name, hide)
        if not hide and not CA.faded[name] then return end
        CA.faded[name] = hide or nil
        local f = _G[name]
        if type(f) == "table" and f.SetAlpha then pcall(f.SetAlpha, f, hide and 0 or 1) end
    end
    for _, n in ipairs(CA.QUEST_FRAMES) do Fade(n, fighting and Opt("caHideQuests")) end
    local n = tonumber(_G.NUM_CHAT_WINDOWS) or 10
    for i = 1, n do
        -- 1.0.8.0: selbst ausgeblendet (Knopf am Chat) bleibt ausgeblendet.
        local EVm = WeintCodex.UIEveryday
        local hide = (fighting and Opt("caHideChat")) or (EVm and EVm.ChatHidden and EVm.ChatHidden())
        Fade("ChatFrame" .. i, hide)
        Fade("ChatFrame" .. i .. "Tab", hide)
        Fade("ChatFrame" .. i .. "EditBox", hide and not (_G["ChatFrame" .. i .. "EditBox"] and _G["ChatFrame" .. i .. "EditBox"].HasFocus and _G["ChatFrame" .. i .. "EditBox"]:HasFocus()))
    end
end

--------------------------------------------------
-- Ereignisse
--------------------------------------------------
do
    local ev = CreateFrame("Frame")
    for _, e in ipairs({ "PLAYER_LOGIN", "UNIT_SPELLCAST_SUCCEEDED", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED",
                         "NAME_PLATE_UNIT_ADDED", "GROUP_ROSTER_UPDATE" }) do
        pcall(ev.RegisterEvent, ev, e)
    end
    ev:SetScript("OnEvent", WeintCodex.Measured("Kampfhilfen", function(_, event, unit, _, spellID)
        if event == "UNIT_SPELLCAST_SUCCEEDED" then
            if unit == "player" then
                if Opt("caHistory") and CA.Push(spellID) then CA.DrawHistory() end
            elseif Opt("caEnemyCD") or Opt("caEnemySpec") then
                CA.OnEnemyCast(unit, spellID)
            end
        elseif event == "NAME_PLATE_UNIT_ADDED" then
            CA.MarkSpec(unit)
        elseif event == "PLAYER_REGEN_DISABLED" then
            CA.ApplyHide(true)
        elseif event == "PLAYER_REGEN_ENABLED" then
            CA.ApplyHide(false)
        elseif event == "PLAYER_LOGIN" then
            BuildHistory()
            BuildCC()
            CA.DrawHistory()
        end
    end))
    -- Ruhiger Takt: Verblassen und Kontrolle (4x je Sekunde, ohne Tabellen).
    local acc = 0
    ev:SetScript("OnUpdate", WeintCodex.Measured("Kampfhilfen", function(_, el)
        acc = acc + (el or 0)
        if acc < 0.25 then return end
        acc = 0
        if Opt("caHistory") then CA.DrawHistory() end
        if ccBar and (Opt("caHealerCC") or ccBar:IsShown()) then CA.UpdateCC() end
    end))
    CA.events = ev
end

--------------------------------------------------
-- Einstellungen
--------------------------------------------------
-- Keine eigene Seite (die Reiterleiste "Kampf & Gruppe" ist voll):
-- Verlauf und Ausblenden auf "Helfer", Heiler und Gegner auf "PvP".
local function off(k) return function() return not K.Get(KEY, k) end end
function CA.BuildHelpers(B)
    B:Section("Zauberverlauf & Ausblenden", "Deine letzten Zauber als Symbole (das neueste links, ältere verblassen nach 12 s) – zum Lernen einer Rotation und gegen Fehlklicks. Questliste und Chat im Kampf nur durchsichtig: beide tragen Knöpfe, die das Spiel im Kampf schützt.")
    B:Row({ type = "toggle", label = "Zauberverlauf zeigen", key = "caHistory" },
          { type = "slider", label = "Symbole", key = "caHistoryCount", min = 3, max = 10, step = 1, disabled = off("caHistory") })
    B:Row({ type = "toggle", label = "Questliste im Kampf ausblenden", key = "caHideQuests" },
          { type = "toggle", label = "Chat im Kampf ausblenden", key = "caHideChat" })
end
function CA.BuildPvP(B)
    B:Section("Heiler unter Kontrolle", "Wird ein Heiler deiner Gruppe betäubt, verwandelt oder gefürchtet, steht oben eine Leiste mit Name, Zauber und Restzeit. Heiler ist, wen die Gruppenrolle so nennt. Liest das Spiel die Auren im Kampf nicht heraus, bleibt die Leiste leer.")
    B:Row({ type = "toggle", label = "Heiler unter Kontrolle zeigen", key = "caHealerCC" },
          { type = "toggle", label = "Mit Ton", key = "caHealerSound", disabled = off("caHealerCC") })
    B:Section("Gegnerische Spieler", "Große Abklingzeiten (Gottesschild, Eisblock, Schildwall, Entrinnen …) als Meldung in der Mitte; an der Plakette der Talentbaum, sobald ein Gegner einen Zauber wirkt, den nur dieser Baum lehrt.")
    B:Row({ type = "toggle", label = "Große Abklingzeiten melden", key = "caEnemyCD" },
          { type = "toggle", label = "Mit Ton", key = "caEnemyCDSound", disabled = off("caEnemyCD") })
    B:Row({ type = "toggle", label = "Talentbaum an der Plakette", key = "caEnemySpec" },
          { type = "empty" })
end

local mod = K.Module(KEY)
if mod then
    for k, v in pairs(CA.DEFAULTS) do
        if mod.defaults[k] == nil then mod.defaults[k] = v end
    end
    for _, p in ipairs(mod.pages) do
        local extra = (p.key == "helfer" and CA.BuildHelpers) or (p.key == "pvp" and CA.BuildPvP) or nil
        if extra then
            local base = p.build
            p.build = function(B) base(B) extra(B) end
        end
    end
end

K.Listen(function(kind, key)
    if (kind == "active" or kind == "setting") and key == KEY then
        CA.DrawHistory()
        CA.UpdateCC()
        CA.ApplyHide(K.InCombat())
    end
end)
