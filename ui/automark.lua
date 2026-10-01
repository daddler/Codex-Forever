--------------------------------------------------
-- WeintCodex :: Komfort - Automark (6.8.1.0)
--------------------------------------------------
-- Beta-Test: "Wenn eine Instanz betreten wird, soll der Tank und Heiler
-- einen Mark ueber den Kopf bekommen. Einstellbar, welches Mark."
--
-- WER TANK IST, SAGT DAS SPIEL - ODER NIEMAND. Gelesen wird nur die Rolle,
-- die das Spiel vergeben hat (UnitGroupRolesAssigned: Suche nach Gruppe,
-- Rollenwahl). In einer Gruppe ohne Rollen wird NICHT markiert und nicht
-- geraten - weder aus der Ausruestung noch aus dem Talentbaum: was der
-- Client nicht beantwortet, wird nicht hergeleitet. Die Einstellungen und
-- der Chat sagen dann, warum nichts geschah.
--
-- WER MARKIERT. SetRaidTarget mit derselben Markierung auf demselben Ziel
-- nimmt sie WIEDER AB - und der Forever-Client haelt den Index geheim (siehe
-- ui/kit.lua, "Markierung geheim"), Lua kann also nicht nachsehen, ob die
-- Markierung schon sitzt. Deshalb:
--   * nur der Gruppenleiter markiert (abschaltbar) - zwei Spieler mit
--     WeintCodex nehmen sich sonst gegenseitig die Markierung ab;
--   * je Instanz und Spieler einmal: wer schon markiert wurde, wird nicht
--     noch einmal markiert, bis die Rolle oder die gewaehlte Markierung
--     wechselt oder die Instanz neu betreten wird - auch nicht, wenn eine
--     andere Einstellung geaendert wird (das nahm im Test die Markierung ab);
--   * ist der Index doch lesbar und stimmt schon, bleibt es dabei.
--   * nie im Kampf: erst danach (PLAYER_REGEN_ENABLED).
--
-- NUR AUF KLICK (6.9.0.2). GEMESSEN (Beta-Test 6.9.0.1, BugGrabber beim
-- Betreten eines Dungeons): "ADDON_ACTION_FORBIDDEN ... UNKNOWN()" aus
-- pcall(SetRaidTarget) - Markieren ist fuer Addons GESCHUETZT. pcall fing
-- das nicht ab: das Spiel blockiert, pcall meldet Erfolg, und die
-- Einstellungen zeigten "markiert". Erlaubt ist es nur aus einem Klick des
-- Spielers - ein geschuetzter Knopf mit einem Makro (/tm [@einheit] n),
-- derselbe Weg wie beim Neuladen (WeintCodex.AttachReload). Deshalb:
-- beim Betreten fragt Automark ("Tank und Heiler markieren?"); "Markieren"
-- setzt beide, "Nicht jetzt" laesst Ruhe bis zum naechsten Betreten. Kein
-- Code hier ruft SetRaidTarget. Seit 12.0 gilt das auch in Retail.
-- UNGEMESSEN: ob /tm aus einem Makro auf Forever markiert.
--
-- WO. Eine Seite des Komforts ("Automark"), kein eigenes Modul: ein
-- weiterer Eintrag haette der Seitenleiste der Einstellungen die Luft fuer
-- einen naechsten genommen (load_test.lua, "Nichts muss scrollen").
-- Gespeichert unter "comfort"; wie jeder Komfort-Helfer von Haus aus AUS.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIAutoMark = {}

local AM = WeintCodex.UIAutoMark
local K = WeintCodex.UIKit
local KEY = "comfort"

-- Markierungen des Spiels, Index 1 bis 8.
AM.MARKS = { "Stern", "Kreis", "Diamant", "Dreieck", "Mond", "Quadrat", "Kreuz", "Totenkopf" }
AM.ROLES = { "TANK", "HEALER" }
AM.ROLE_LABEL = { TANK = "Tank", HEALER = "Heiler" }
AM.SETTING = { TANK = "markTank", HEALER = "markHealer" }

-- Einstellungen im Komfort (Namen mit "mark", damit sie dort nicht mit
-- anderen Helfern zusammenstossen).
AM.DEFAULTS = {
    autoMark       = false,
    markTank       = 6,      -- Quadrat
    markHealer     = 4,      -- Dreieck
    markDungeons   = true,
    markRaids      = true,
    markOnlyLeader = true,
    markChat       = true,
}

local function Say(text)
    print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " " .. text)
end

function AM.Icon(index, size)
    size = size or 14
    return string.format("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_%d:%d:%d|t", index, size, size)
end

local function Call(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b = pcall(fn, ...)
    if not ok then return nil end
    return K.Plain(a), K.Plain(b)
end

-- Zustand dieser Sitzung (nichts davon wird gespeichert). offer: was der
-- Knopf gerade markieren wuerde; dismissed: Instanz, in der er weg soll.
AM.state = { instance = nil, done = {}, last = nil, pending = false, offer = nil, dismissed = nil }
local state = AM.state

-- In welcher Instanz sind wir, und soll dort markiert werden?
function AM.Instance()
    local inside, kind = Call(_G.IsInInstance)
    if not inside then return nil end
    if kind == "party" and not K.Get(KEY, "markDungeons") then return nil end
    if kind == "raid" and not K.Get(KEY, "markRaids") then return nil end
    if kind ~= "party" and kind ~= "raid" then return nil end
    -- Kennung der Instanz: Name und Nummer, soweit der Client sie nennt.
    local id = kind
    if type(_G.GetInstanceInfo) == "function" then
        local ok, name, _, _, _, _, _, _, instanceID = pcall(_G.GetInstanceInfo)
        name, instanceID = ok and K.Plain(name) or nil, ok and K.Plain(instanceID) or nil
        id = tostring(instanceID or name or kind)
    end
    return id, kind
end

-- Darf dieser Spieler markieren?
function AM.MayMark(kind)
    local leader = Call(_G.UnitIsGroupLeader, "player")
    if leader then return true end
    if K.Get(KEY, "markOnlyLeader") then return false, "nur der Gruppenleiter markiert" end
    if kind == "raid" then
        local assist = Call(_G.UnitIsGroupAssistant, "player")
        if not assist then return false, "im Schlachtzug markieren nur Leiter und Assistenten" end
    end
    return true
end

-- Einheiten der Gruppe in fester Reihenfolge.
local PARTY = { "player", "party1", "party2", "party3", "party4" }
local RAID = {}
for i = 1, 40 do RAID[i] = "raid" .. i end

local function Exists(unit)
    return Call(_G.UnitExists, unit) and true or false
end

-- Der erste Spieler je Rolle (nur die Rolle, die das Spiel vergeben hat).
function AM.Holders(kind)
    local list = (kind == "raid") and RAID or PARTY
    local out = {}
    for _, unit in ipairs(list) do
        if Exists(unit) then
            local role = Call(_G.UnitGroupRolesAssigned, unit)
            if (role == "TANK" or role == "HEALER") and not out[role] then out[role] = unit end
        end
    end
    return out
end

local function Who(unit)
    local guid = Call(_G.UnitGUID, unit)
    if type(guid) == "string" then return guid end
    local name = Call(_G.UnitName, unit)
    return type(name) == "string" and name or unit
end

local function NameOf(unit)
    local name = Call(_G.UnitName, unit)
    return type(name) == "string" and name or unit
end

-- Schon richtig markiert? Nur wenn der Client den Index offen nennt.
local function Already(unit, index)
    if type(_G.GetRaidTargetIndex) ~= "function" then return false end
    local ok, v = pcall(_G.GetRaidTargetIndex, unit)
    if not ok or K.IsSecret(v) then return false end
    return K.Plain(v) == index
end

-- Ein Durchlauf: markiert, was noch nicht markiert ist. Gibt eine Zeile
-- fuer die Einstellungen zurueck (und merkt sie sich).
function AM.On()
    return K.IsActive(KEY) and K.Get(KEY, "autoMark") and true or false
end

function AM.Run()
    if not AM.On() then return nil end
    local id, kind = AM.Instance()
    if Call(_G.InCombatLockdown) then
        -- Der Knopf ist geschuetzt: im Kampf weder zeigen noch aendern.
        state.pending = true
        state.last = "Im Kampf – markiert wird danach."
        return state.last
    end
    state.pending = false
    if not id then
        state.instance, state.done, state.dismissed = nil, {}, nil
        AM.Withdraw()
        state.last = "Nicht in einer Instanz, in der markiert wird."
        return state.last
    end
    if state.instance ~= id then
        state.instance, state.done, state.told, state.dismissed = id, {}, nil, nil
    end
    local may, why = AM.MayMark(kind)
    if not may then
        AM.Withdraw()
        state.last = "Nicht markiert: " .. why .. "."
        return state.last
    end
    local holders = AM.Holders(kind)
    local parts, used, plan = {}, {}, {}
    for _, role in ipairs(AM.ROLES) do
        local index = tonumber(K.Get(KEY, AM.SETTING[role])) or 0
        local unit = holders[role]
        local label = AM.ROLE_LABEL[role]
        if index < 1 or index > 8 then
            parts[#parts + 1] = label .. ": keine Markierung gewählt"
        elseif used[index] then
            parts[#parts + 1] = label .. ": dieselbe Markierung wie oben – ausgelassen"
        elseif not unit then
            parts[#parts + 1] = label .. ": keine Rolle vergeben"
        else
            used[index] = true
            -- Spieler UND Markierung: neu gesetzt wird nur, wenn sich eines
            -- davon aendert - dieselbe noch einmal naehme sie ab.
            local who = Who(unit) .. "#" .. index
            if state.done[role] ~= who and Already(unit, index) then state.done[role] = who end
            local done = state.done[role] == who
            if not done then
                plan[#plan + 1] = { role = role, unit = unit, index = index, who = who }
            end
            parts[#parts + 1] = string.format("%s: %s %s%s", label, NameOf(unit), AM.Icon(index),
                done and "" or " (wartet auf Klick)")
        end
    end
    state.last = table.concat(parts, " · ")
    if #plan > 0 and state.dismissed ~= id then
        AM.Offer(plan)
        -- Einmal je Angebot im Chat: was ein Klick tut und warum es einen braucht.
        local sig = AM.Macro(plan)
        if K.Get(KEY, "markChat") and state.told ~= sig then
            state.told = sig
            Say("Automark: " .. state.last .. " – bestätige oben mit „Markieren“"
                .. " (das Spiel lässt Addons nur auf deinen Klick markieren).")
        end
    else
        AM.Withdraw()
    end
    return state.last
end

--------------------------------------------------
-- Die Abfrage (6.9.0.2)
--------------------------------------------------
-- Beta-Test: "beim Dungeoneintritt eine Abfrage, ich bestaetige, dann
-- werden die Marks gesetzt". Ein kleines Fenster unter den Erinnerungen:
-- wer welche Markierung bekaeme, darunter "Markieren" und "Nicht jetzt".
--
-- Ueber "Markieren" liegt ein geschuetzter Knopf (SecureActionButtonTemplate,
-- AM.BUTTON) mit einem Makro: je Rolle "/tm [@einheit] n" - derselbe Weg
-- wie beim Neuladen (WeintCodex.AttachReload): das Spiel fuehrt das Makro
-- aus, weil der Spieler klickt. Gesetzt, gezeigt und versteckt wird nur
-- ausserhalb des Kampfes. Rechtsklick auf "Markieren" oder "Nicht jetzt":
-- bis zum naechsten Betreten Ruhe. Mit Namen laesst sich der Knopf auch
-- per "/click WeintCodexAutoMarkButton" auf eine Taste legen.
-- Seit 12.0 ist SetRaidTarget fuer Addons geschuetzt, auch in Retail; ein
-- Klick des Spielers ist der Weg, den das Spiel offen laesst.
AM.BUTTON = "WeintCodexAutoMarkButton"
AM.CMD = "/tm"
AM.W, AM.PAD, AM.LINE = 300, 14, 18
AM.BTN_W, AM.BTN_H = 124, 30

-- Makrotext: Einheiten der Gruppe (party1, raid7), nie Namen.
function AM.Macro(plan)
    local lines = {}
    for _, p in ipairs(plan) do
        lines[#lines + 1] = string.format("%s [@%s] %d", AM.CMD, p.unit, p.index)
    end
    return table.concat(lines, "\n")
end

local dialog
function AM.Dialog()
    if dialog then return dialog end
    if K.InCombat() then return nil end
    local d = CreateFrame("Frame", nil, UIParent)
    local p = K.Layout("automark")
    d:SetPoint(p.point, UIParent, p.relPoint, p.x, p.y)
    d:SetWidth(AM.W)
    d:SetFrameStrata("DIALOG")
    K.Kachel(d, { alpha = 0.96, shadow = 8 })
    d.title = K.NewText(d, 14, "OVERLAY")
    d.title:SetPoint("TOPLEFT", d, "TOPLEFT", AM.PAD, -AM.PAD)
    d.title:SetText(WeintCodex.AC .. "Automark|r  Tank und Heiler markieren?")
    d.body = K.NewText(d, 12, "OVERLAY")
    d.body:SetPoint("TOPLEFT", d.title, "BOTTOMLEFT", 0, -8)
    d.body:SetJustifyH("LEFT")
    -- Sichtbarer Knopf, darueber der geschuetzte (er nimmt den Klick).
    d.yes = WeintCodex.CreateButton(d, { text = "Markieren", kind = "primary", height = AM.BTN_H, size = 12 })
    d.yes:SetWidth(AM.BTN_W)
    d.yes:SetPoint("BOTTOMRIGHT", d, "BOTTOMRIGHT", -AM.PAD, AM.PAD)
    d.no = WeintCodex.CreateButton(d, { text = "Nicht jetzt", kind = "secondary", height = AM.BTN_H, size = 12,
        backdrop = "surface2", onClick = function() AM.Clicked("RightButton") end })
    d.no:SetWidth(AM.BTN_W)
    d.no:SetPoint("RIGHT", d.yes, "LEFT", -10, 0)
    local ok, b = pcall(CreateFrame, "Button", AM.BUTTON, d, "SecureActionButtonTemplate")
    if not ok or not b then return nil end
    b:SetAllPoints(d.yes)
    b:SetFrameLevel((d.yes:GetFrameLevel() or 1) + 5)
    if b.RegisterForClicks then b:RegisterForClicks("AnyUp") end
    b:SetAttribute("useOnKeyDown", false)
    b:SetAttribute("type1", "macro")       -- nur links; rechts tut das Spiel nichts
    b:HookScript("OnClick", function(_, which) AM.Clicked(which) end)
    b:SetScript("OnEnter", function(self)
        if not GameTooltip then return end
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:AddLine("Automark")
        GameTooltip:AddLine("Setzt die Markierungen. Das Spiel lässt Addons nur auf deinen Klick markieren.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    d.secure = b
    d:Hide()
    dialog = d
    AM.dialog = d
    return d
end

function AM.Offer(plan)
    local d = AM.Dialog()
    if not d then return end
    state.offer = plan
    d.secure:SetAttribute("macrotext1", AM.Macro(plan))
    local lines = {}
    for _, p in ipairs(plan) do
        lines[#lines + 1] = string.format("%s:  %s %s", AM.ROLE_LABEL[p.role], NameOf(p.unit), AM.Icon(p.index, 16))
    end
    d.body:SetText(table.concat(lines, "\n"))
    d:SetHeight(AM.PAD * 3 + 14 + 8 + #lines * AM.LINE + AM.BTN_H + 6)
    d:Show()
end

function AM.Withdraw()
    state.offer = nil
    if not dialog then return end
    if K.InCombat() then K.AfterCombat(AM.Withdraw) return end
    dialog.secure:SetAttribute("macrotext1", nil)
    dialog:Hide()
end

function AM.IsOffered() return dialog ~= nil and dialog:IsShown() and state.offer ~= nil end

-- Nach dem Klick (das Makro lief schon): als markiert merken. Ob das Spiel
-- wirklich markiert hat, sagt es nicht (Index geheim) - die Abfrage geht.
-- "RightButton" heisst hier: Nicht jetzt.
function AM.Clicked(which)
    if which == "RightButton" then
        state.dismissed = state.instance
        AM.Withdraw()
        state.last = "Nicht jetzt – bis zum nächsten Betreten."
        return
    end
    for _, p in ipairs(state.offer or {}) do state.done[p.role] = p.who end
    AM.Withdraw()
    if K.InCombat() then return end
    AM.Run()
end

--------------------------------------------------
-- Ereignisse
--------------------------------------------------

AM.EVENTS = { "PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA", "GROUP_ROSTER_UPDATE",
              "PLAYER_ROLES_ASSIGNED", "PARTY_LEADER_CHANGED", "PLAYER_REGEN_ENABLED" }

local events = CreateFrame("Frame")
events:SetScript("OnEvent", K.Measured("Automark", function(_, event)
    if event == "PLAYER_REGEN_ENABLED" and not state.pending then return end
    AM.Run()
end))

local function Apply()
    events:UnregisterAllEvents()
    if not AM.On() then
        state.last = nil
        AM.Withdraw()
        return
    end
    for _, e in ipairs(AM.EVENTS) do pcall(events.RegisterEvent, events, e) end
    AM.Run()
end

--------------------------------------------------
-- Seite im Komfort
--------------------------------------------------

local function MarkItems()
    local items = { { value = 0, text = "Keine" } }
    for i, name in ipairs(AM.MARKS) do
        items[#items + 1] = { value = i, text = AM.Icon(i) .. "  " .. name }
    end
    return items
end

function AM.Status()
    if not AM.On() then return "Aus." end
    return state.last or "Noch nichts zu tun."
end

local function Build(B)
    local off = function() return not K.Get(KEY, "autoMark") end
    B:Section("Automark")
    B:Row({ type = "toggle", label = "Tank und Heiler markieren", key = "autoMark",
            description = "Beim Betreten einer Instanz fragt Automark nach – „Markieren“ setzt beide. Ohne deinen Klick lässt das Spiel Addons nicht markieren." },
          { type = "toggle", label = "Im Chat melden", key = "markChat", disabled = off })
    B:Section("Wer bekommt welche Markierung")
    B:Row({ type = "dropdown", label = "Tank", key = "markTank", items = MarkItems(), disabled = off },
          { type = "dropdown", label = "Heiler", key = "markHealer", items = MarkItems(), disabled = off })
    B:Section("Wann")
    B:Row({ type = "toggle", label = "In Dungeons", key = "markDungeons", disabled = off },
          { type = "toggle", label = "In Schlachtzügen", key = "markRaids", disabled = off })
    B:Row({ type = "toggle", label = "Nur als Gruppenleiter", key = "markOnlyLeader", disabled = off,
            description = "Empfohlen. Markieren zwei Spieler mit WeintCodex, nimmt der zweite die Markierung wieder ab." },
          { type = "empty" })
    B:Note("Markiert wird nur, wer vom Spiel eine Rolle bekommen hat (Suche nach Gruppe, Rollenwahl). "
        .. "Ohne Rolle wird nichts geraten – weder aus Ausrüstung noch aus Talenten. "
        .. "Je Instanz einmal; neu, wenn eine Rolle oder die Markierung wechselt. Nie im Kampf. "
        .. "Der Knopf heißt " .. AM.BUTTON .. " – mit /click " .. AM.BUTTON .. " in einem Makro auch auf eine Taste.")
    B:Note("Zuletzt: " .. AM.Status())
end

-- An den Komfort haengen: Standardwerte und eine Seite.
local mod = K.Module(KEY)
if mod then
    for k, v in pairs(AM.DEFAULTS) do
        if mod.defaults[k] == nil then mod.defaults[k] = v end
    end
    mod.pages[#mod.pages + 1] = { key = "automark", label = "Automark", build = Build }
end

-- Kein Zuruecksetzen bei einer Einstellung: eine neu gewaehlte Markierung
-- erkennt Run selbst (Spieler#Markierung); jede andere Einstellung setzt
-- nichts neu.
K.Listen(function(kind, key)
    if (kind == "active" or kind == "setting") and key == KEY then Apply() end
end)
