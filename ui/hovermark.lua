--------------------------------------------------
-- WeintCodex :: Komfort - Markieren per Mouseover (6.10.4.1)
--------------------------------------------------
-- Beta-Test: "In einer Instanz einfach nur per Mouseover ueber die
-- Namensplakette die NPCs markieren. Einstellbar in den Einstellungen."
--
-- NUR DRUEBERFAHREN GEHT NICHT. Markieren ist fuer Addons geschuetzt
-- (gemessen 6.9.0.1: SetRaidTarget -> ADDON_ACTION_FORBIDDEN, siehe
-- ui/automark.lua) - erlaubt nur aus einem Tastendruck oder Klick des
-- Spielers. Deshalb: Maus ueber den Gegner, EINE Taste (Standard: mittlere
-- Maustaste). Die Taste liegt auf einem geschuetzten Knopf mit einem Makro
-- "/tm [@mouseover,harm,nodead] n"; die Zahl n waehlt WeintCodex vorher,
-- beim Ueberfahren (UPDATE_MOUSEOVER_UNIT):
--
--   * die erste freie Markierung in der Reihenfolge Totenkopf, Kreuz,
--     Quadrat, Mond, Dreieck, Diamant, Kreis, Stern - jede abwaehlbar, die
--     von Automark fuer Tank und Heiler ausgelassen;
--   * ein Gegner, den WeintCodex schon markiert hat, bekommt KEIN Makro:
--     /tm mit derselben Markierung naehme sie wieder ab. Ob ein ANDERER ihn
--     markiert hat, weiss Lua nicht - der Index ist im Forever-Client geheim
--     (ui/kit.lua, "Markierung geheim");
--   * nur Gegner, die man angreifen kann, keine Spieler, keine Toten.
--
-- IM KAMPF NICHT. Den Makrotext darf ein Addon im Kampf nicht aendern; mit
-- dem zuletzt vorbereiteten markierte jeder Druck einen neuen Gegner mit
-- DERSELBEN Markierung (sie wanderte). Beim Kampfbeginn wird er geleert
-- (PLAYER_REGEN_DISABLED - dort ist es noch erlaubt); ein Druck im Kampf
-- sagt einmal im Chat, warum nichts geschieht. Gedacht ist es fuer das
-- Markieren vor dem Pull.
--
-- WAS WELCHE MARKIERUNG TRAEGT, merkt sich WeintCodex je Gegner (GUID) fuer
-- diese Sitzung. Nach dem Kampf bleibt nur, wer noch lebt und eine Plakette
-- hat - die Markierungen der Toten sind wieder frei. Beim Wechsel des
-- Gebiets alles frei.
--
-- DIE TASTE gilt nur dort, wo markiert wird (Standard: Dungeons und
-- Schlachtzuege), als Vorrang-Belegung (SetOverrideBindingClick) - dort
-- ueberdeckt sie, was du selbst auf die Taste gelegt hast; draussen ist sie
-- wieder deine. Gesetzt und entfernt nur ausserhalb des Kampfes.
--
-- UNGEMESSEN: ob /tm aus einem Makro auf Forever markiert (wie bei
-- Automark) und ob eine Belegung der mittleren Maustaste dort greift.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIHoverMark = {}

local HM = WeintCodex.UIHoverMark
local AM = WeintCodex.UIAutoMark
local K = WeintCodex.UIKit
local KEY = "comfort"

HM.BUTTON = "WeintCodexHoverMarkButton"
HM.ORDER = { 8, 7, 6, 5, 4, 3, 2, 1 }   -- Totenkopf zuerst
HM.MACRO = "/tm [@mouseover,harm,nodead] %d"
HM.KEYS = {
    { value = "BUTTON3",       text = "Mittlere Maustaste" },
    { value = "BUTTON4",       text = "Maustaste 4" },
    { value = "BUTTON5",       text = "Maustaste 5" },
    { value = "SHIFT-BUTTON3", text = "Umschalt + mittlere Maustaste" },
    { value = "CTRL-BUTTON3",  text = "Strg + mittlere Maustaste" },
    { value = "ALT-BUTTON3",   text = "Alt + mittlere Maustaste" },
}
HM.WHERE = {
    { value = "instance", text = "Dungeons und Schlachtzüge" },
    { value = "party",    text = "Nur Dungeons" },
    { value = "always",   text = "Überall" },
}
HM.DEFAULTS = { markHover = false, markHoverKey = "BUTTON3", markHoverWhere = "instance" }
for _, i in ipairs(HM.ORDER) do HM.DEFAULTS["markHoverUse" .. i] = true end

local PLATES = {}
for i = 1, 40 do PLATES[i] = "nameplate" .. i end

-- Diese Sitzung: GUID -> Markierung, Markierung -> GUID (oder true).
HM.state = { byGuid = {}, byMark = {}, told = false, zone = nil, bound = nil }
local state = HM.state

local function Say(text)
    print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " " .. text)
end

local function Call(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b = pcall(fn, ...)
    if not ok then return nil end
    return K.Plain(a), K.Plain(b)
end

function HM.On()
    return K.IsActive(KEY) and K.Get(KEY, "markHover") and true or false
end

-- Wird hier markiert?
function HM.Allowed()
    local where = K.Get(KEY, "markHoverWhere")
    if where == "always" then return true end
    local inside, kind = Call(_G.IsInInstance)
    if not inside then return false end
    if where == "party" then return kind == "party" end
    return kind == "party" or kind == "raid"
end

-- Die Markierungen von Tank und Heiler (Automark) bleiben frei.
local function Reserved(i)
    if not (AM and AM.On and AM.On()) then return false end
    return tonumber(K.Get(KEY, "markTank")) == i or tonumber(K.Get(KEY, "markHealer")) == i
end

function HM.Free()
    for _, i in ipairs(HM.ORDER) do
        if K.Get(KEY, "markHoverUse" .. i) and not state.byMark[i] and not Reserved(i) then return i end
    end
    return nil
end

function HM.Eligible(unit)
    if not Call(_G.UnitExists, unit) then return false end
    if not Call(_G.UnitCanAttack, "player", unit) then return false end
    if Call(_G.UnitPlayerControlled, unit) then return false end
    if Call(_G.UnitIsDead, unit) then return false end
    return true
end

local button
function HM.Button()
    if button then return button end
    if K.InCombat() then return nil end
    local ok, b = pcall(CreateFrame, "Button", HM.BUTTON, UIParent, "SecureActionButtonTemplate")
    if not ok or not b then return nil end
    if b.RegisterForClicks then b:RegisterForClicks("AnyUp") end
    b:SetAttribute("useOnKeyDown", false)
    b:SetAttribute("type", "macro")
    b:SetAttribute("macrotext", "")
    b:SetScript("PostClick", function() HM.Clicked() end)
    button = b
    HM.button = b
    return b
end

-- Den Makrotext fuer den Gegner unter der Maus vorbereiten.
function HM.Prepare()
    local b = HM.Button()
    if not b or K.InCombat() then return nil end
    local text, plan = "", nil
    if HM.On() and HM.Allowed() and HM.Eligible("mouseover") then
        local guid = Call(_G.UnitGUID, "mouseover")
        guid = type(guid) == "string" and guid or nil
        if not (guid and state.byGuid[guid]) then
            local i = HM.Free()
            if i then
                text = string.format(HM.MACRO, i)
                plan = { guid = guid, index = i }
            end
        end
    end
    b:SetAttribute("macrotext", text)
    HM.text, HM.plan = text, plan
    return text
end

-- Nach dem Druck (das Makro lief schon): merken, was gesetzt wurde.
function HM.Clicked()
    if K.InCombat() then
        if not state.told then
            state.told = true
            Say("Markieren per Mouseover geht nur außerhalb des Kampfes – im Kampf lässt das Spiel die Markierung nicht wechseln.")
        end
        return
    end
    local p = HM.plan
    if p and HM.text ~= "" then
        state.byMark[p.index] = p.guid or true
        if p.guid then state.byGuid[p.guid] = p.index end
    end
    HM.Prepare()
end

-- Nach dem Kampf: frei ist, wessen Gegner tot ist oder keine Plakette mehr hat.
function HM.Prune()
    local alive = {}
    for _, unit in ipairs(PLATES) do
        if Call(_G.UnitExists, unit) and not Call(_G.UnitIsDead, unit) then
            local guid = Call(_G.UnitGUID, unit)
            if type(guid) == "string" then alive[guid] = true end
        end
    end
    for guid, i in pairs(state.byGuid) do
        if not alive[guid] then
            state.byGuid[guid] = nil
            state.byMark[i] = nil
        end
    end
    for i, v in pairs(state.byMark) do
        if v == true then state.byMark[i] = nil end   -- ohne GUID: nicht nachpruefbar
    end
end

function HM.Clear()
    for k in pairs(state.byGuid) do state.byGuid[k] = nil end
    for k in pairs(state.byMark) do state.byMark[k] = nil end
end

-- Die Taste: nur wo markiert wird, nur ausserhalb des Kampfes zu aendern.
function HM.Bind()
    if K.InCombat() then K.AfterCombat(HM.Bind) return false end
    local b = HM.Button()
    if not b then return false end
    if type(_G.ClearOverrideBindings) == "function" then _G.ClearOverrideBindings(b) end
    state.bound = nil
    if HM.On() and HM.Allowed() and type(_G.SetOverrideBindingClick) == "function" then
        local key = K.Get(KEY, "markHoverKey")
        if type(key) == "string" and key ~= "" then
            _G.SetOverrideBindingClick(b, true, key, HM.BUTTON, "LeftButton")
            state.bound = key
        end
    end
    HM.Prepare()
    return state.bound ~= nil
end

function HM.Status()
    if not HM.On() then return "Aus." end
    if not state.bound then return "An – die Taste gilt erst dort, wo markiert wird." end
    local n = 0
    for _ in pairs(state.byMark) do n = n + 1 end
    local label = state.bound
    for _, k in ipairs(HM.KEYS) do if k.value == state.bound then label = k.text end end
    return string.format("Bereit: Maus über den Gegner, %s. Vergeben: %d.", label, n)
end

--------------------------------------------------
-- Ereignisse
--------------------------------------------------

local events = CreateFrame("Frame")
HM.events = events
events:SetScript("OnEvent", K.Measured("Mouseover-Markieren", function(_, event)
    if event == "UPDATE_MOUSEOVER_UNIT" then
        if not K.InCombat() then HM.Prepare() end
    elseif event == "PLAYER_REGEN_DISABLED" then
        -- Letzter Moment, in dem der Text sich aendern laesst.
        if button then pcall(button.SetAttribute, button, "macrotext", "") end
        HM.text, HM.plan = "", nil
    elseif event == "PLAYER_REGEN_ENABLED" then
        state.told = false
        HM.Prune()
        HM.Prepare()
    else   -- Gebiet gewechselt
        HM.Clear()
        HM.Bind()
    end
end))

local function Apply()
    events:UnregisterAllEvents()
    if not HM.On() then
        HM.Clear()
        if button and not K.InCombat() then
            if type(_G.ClearOverrideBindings) == "function" then _G.ClearOverrideBindings(button) end
            button:SetAttribute("macrotext", "")
            state.bound = nil
        elseif button then
            K.AfterCombat(Apply)
        end
        return
    end
    for _, e in ipairs({ "UPDATE_MOUSEOVER_UNIT", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED",
                         "PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA" }) do
        pcall(events.RegisterEvent, events, e)
    end
    HM.Bind()
end
HM.Apply = Apply

--------------------------------------------------
-- Auf der Seite "Automark" im Komfort
--------------------------------------------------

function HM.Build(B)
    local off = function() return not K.Get(KEY, "markHover") end
    B:Section("Per Mouseover markieren",
        "Maus über einen Gegner (Plakette oder Gegner selbst) und die Taste drücken – er bekommt die nächste freie Markierung. "
        .. "Nur Drüberfahren geht nicht: das Spiel lässt Addons nur auf einen Tastendruck markieren.")
    B:Row({ type = "toggle", label = "Per Mouseover markieren", key = "markHover",
            description = "Nur außerhalb des Kampfes – gedacht für das Markieren vor dem Pull." },
          { type = "dropdown", label = "Taste", key = "markHoverKey", items = HM.KEYS, disabled = off,
            description = "Gilt nur dort, wo markiert wird, und hat dort Vorrang vor deiner eigenen Belegung." })
    B:Row({ type = "dropdown", label = "Wo", key = "markHoverWhere", items = HM.WHERE, disabled = off },
          { type = "empty" })
    B:Note("Zuletzt: " .. HM.Status())
    B:Advanced()
    B:Section("Welche Markierungen, in dieser Reihenfolge",
        "Die von Automark für Tank und Heiler bleiben frei. Wer schon markiert ist, wird nicht noch einmal markiert – dieselbe Markierung nähme sie wieder ab.")
    for n = 1, #HM.ORDER, 2 do
        local a, b = HM.ORDER[n], HM.ORDER[n + 1]
        B:Row({ type = "toggle", label = AM.Icon(a) .. "  " .. AM.MARKS[a], key = "markHoverUse" .. a, disabled = off },
              { type = "toggle", label = AM.Icon(b) .. "  " .. AM.MARKS[b], key = "markHoverUse" .. b, disabled = off })
    end
end

local mod = K.Module(KEY)
if mod then
    for k, v in pairs(HM.DEFAULTS) do
        if mod.defaults[k] == nil then mod.defaults[k] = v end
    end
    for _, page in ipairs(mod.pages) do
        if page.key == "automark" then
            local inner = page.build
            page.build = function(B)
                inner(B)
                HM.Build(B)
            end
        end
    end
end

K.Listen(function(kind, key)
    if (kind == "active" or kind == "setting") and key == KEY then Apply() end
end)
