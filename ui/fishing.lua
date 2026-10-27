--------------------------------------------------
-- WeintCodex :: Angeln mit einer Taste (Komfort, Seite "Sammeln")
--------------------------------------------------
-- Seit 1.3.0.0, auf Wunsch ("wie SKTools Easy Fishing"). Verhalten nach
-- SKTools, eigener Code - SKTools nennt keine Lizenz, also gilt dasselbe
-- wie bei MoveAny: Verhalten ja, Code nein.
--
-- EINE Taste, die der Spieler waehlt, tut je nach Lage das Richtige:
--   * Beute offen (Angelbeute, Automatisch pluendern aus): alles nehmen;
--   * der Schwimmer ist das weiche Interaktionsziel: einholen
--     (INTERACTTARGET - die Interaktionstaste des Spiels);
--   * sonst: Angeln auswerfen (geschuetzter Makroknopf, "/cast Angeln" -
--     das Spiel nimmt den hoechsten gelernten Rang).
-- Jeder Druck ist der des Spielers: dass ein Fisch beisst, sagt das Spiel
-- keinem Addon, und hier passiert nichts von selbst.
--
-- Die Taste ist eine VORRANG-Belegung an einem eigenen Rahmen
-- (SetOverrideBinding). Die Tastenbelegung des Spielers wird nie
-- geschrieben; ohne Angel in der Hand gilt seine eigene Belegung, denn
-- auf Forever geht Angeln nur mit Angel. Belegungen aendern geht nur
-- ausserhalb des Kampfes - im Kampf bleibt, was war, bis er vorbei ist.
--
-- Eine SITZUNG ist ein Wurf: sie beginnt beim Druck auf den Auswurf
-- (oder mit jedem Angel-Kanal) und endet mit dem Kanal, spaetestens
-- WAIT s nach einem Druck, aus dem kein Wurf wurde. Waehrend einer Sitzung
-- stehen einige Spieleinstellungen anders (Reichweite der Interaktion,
-- auf Wunsch Ton), ueber PF.SetCVar mit dem Besitzer "fishing" - danach
-- und nach einem Absturz beim naechsten Einloggen kommen die alten Werte
-- zurueck, aber nur, wo noch UNSER Wert steht. Was ein anderer Teil schon
-- gesetzt hat (Glitzern setzt dieselbe Reichweite dauerhaft), bleibt ihm.
--
-- Der Schwimmer: Spielobjekt 35591 (in allen Fassungen). Weit draussen
-- (Forever: 10-20 m) reicht die Interaktion des Spiels ab Werk nicht -
-- darum die groessere Reichweite waehrend des Wurfs.
--------------------------------------------------

local K = WeintCodex.UIKit
local C = WeintCodex.Colors
local KEY = "comfort"
local OWNER = "fishing"

WeintCodex.UIFishing = {}
local FI = WeintCodex.UIFishing

FI.DEFAULTS = {
    fishKeyOn   = false,
    fishKey     = "",
    fishLoud    = true,     -- Platschen lauter: Effekte auf voll
    fishBg      = true,     -- Ton auch, wenn das Spiel im Hintergrund ist
    fishIcon    = true,     -- Symbol ueber dem Schwimmer
}

FI.BOBBER = 35591
FI.SPELL = 7620                         -- Angeln (Rang 1); der Name gilt fuer alle Raenge
FI.CHANNELS = { [7620] = true, [7731] = true, [7732] = true, [18248] = true }
FI.CAST_BUTTON = "WeintCodexFishingCast"
FI.LOOT_BUTTON = "WeintCodexFishingLoot"
FI.CONDITIONS = "[nocombat,noflying,nostealth,noswimming]"
FI.WAIT = 3
FI.MAIN_HAND = 16
FI.POLE = { class = 2, subclass = 20 }  -- Waffe / Angelrute

-- Was eine Sitzung braucht: Name -> Wert. "min" heisst: nur anheben.
FI.SESSION = {
    { name = "SoftTargetInteract",      value = "3" },
    { name = "SoftTargetInteractRange", value = "30", min = true },
    { name = "SoftTargetInteractArc",   value = "2",  min = true },
}
FI.LOUD = {
    { name = "Sound_EnableSFX",  value = "1" },
    { name = "Sound_SFXVolume",  value = "1", min = true },
}
FI.BG = { { name = "Sound_EnableSoundWhenGameIsInBG", value = "1" } }
FI.ICON = {
    { name = "SoftTargetIconGameObject", value = "1" },
    { name = "SoftTargetIconInteract",   value = "1" },
}

local state = { channeling = false, inReach = false, lootOpen = false, session = false,
                applied = nil, appliedKey = nil, waitCombat = false }
FI.state = state
local owner, castBtn, lootBtn, endTimer
local ev = CreateFrame("Frame")
FI.events = ev

local function PF() return WeintCodex.UIProfile end
local function Plain(v) return K.Plain and K.Plain(v) or v end

function FI.On() return K.IsActive(KEY) and K.Get(KEY, "fishKeyOn") and true or false end
function FI.Key()
    local k = K.Get(KEY, "fishKey")
    return (type(k) == "string" and k ~= "") and k or nil
end

local function InCombat()
    return _G.InCombatLockdown and _G.InCombatLockdown() and true or false
end

function FI.SpellName()
    local cs = _G.C_Spell
    if cs and cs.GetSpellName then
        local ok, n = pcall(cs.GetSpellName, FI.SPELL)
        n = Plain(n)
        if ok and type(n) == "string" and n ~= "" then return n end
    end
    if _G.GetSpellInfo then
        local ok, n = pcall(_G.GetSpellInfo, FI.SPELL)
        n = Plain(n)
        if ok and type(n) == "string" and n ~= "" then return n end
    end
end

function FI.IsFishing(spellID)
    spellID = Plain(spellID)
    if type(spellID) ~= "number" then return false end
    if FI.CHANNELS[spellID] then return true end
    local cs = _G.C_Spell
    local name = cs and cs.GetSpellName and Plain(cs.GetSpellName(spellID))
    return name ~= nil and name == FI.SpellName()
end

function FI.PoleEquipped()
    local id = _G.GetInventoryItemID and Plain(_G.GetInventoryItemID("player", FI.MAIN_HAND))
    if type(id) ~= "number" then return false end
    local info = (_G.C_Item and _G.C_Item.GetItemInfoInstant) or _G.GetItemInfoInstant
    if type(info) ~= "function" then return false end
    local _, _, _, _, _, classID, subclassID = info(id)
    return Plain(classID) == FI.POLE.class and Plain(subclassID) == FI.POLE.subclass
end

function FI.IsBobber(guid)
    guid = Plain(guid)
    if type(guid) ~= "string" then return false end
    local kind, id = guid:match("^(%a+)%-%d+%-%d+%-%d+%-%d+%-(%d+)")
    return kind == "GameObject" and tonumber(id) == FI.BOBBER
end

--------------------------------------------------
-- Spieleinstellungen waehrend eines Wurfs
--------------------------------------------------

local function Wants(entry, cur)
    if entry.min then
        return (tonumber(cur) or 0) < tonumber(entry.value)
    end
    return tostring(cur) ~= entry.value
end

local function SetList(list)
    local pf = PF()
    if not (pf and pf.SetCVar and pf.GetCVar) then return end
    for _, e in ipairs(list) do
        local rec = pf.Record and pf.Record(e.name)
        if not rec or rec.owner == OWNER then
            local cur = pf.GetCVar(e.name)
            if cur ~= nil and Wants(e, cur) then pf.SetCVar(e.name, e.value, OWNER) end
        end
    end
end

function FI.BeginSession()
    if InCombat() then return end
    SetList(FI.SESSION)
    if K.Get(KEY, "fishIcon") then SetList(FI.ICON) end
    if K.Get(KEY, "fishLoud") then SetList(FI.LOUD) end
    if K.Get(KEY, "fishBg") then SetList(FI.BG) end
    state.session = true
end

function FI.EndSession()
    if endTimer then endTimer:Cancel(); endTimer = nil end
    if InCombat() then FI.WatchCombat() return end
    local pf = PF()
    if pf and pf.ReleaseOwner then pf.ReleaseOwner(OWNER) end
    state.session = false
end

local function EndIfIdle()
    endTimer = nil
    if not state.channeling then FI.EndSession() end
end

--------------------------------------------------
-- Die Taste
--------------------------------------------------

function FI.Wanted()
    local key = FI.Key()
    if not FI.On() or not key then return nil end
    if not FI.PoleEquipped() then return nil end
    if state.lootOpen then return "loot", key end
    if state.channeling and state.inReach then return "reel", key end
    return "cast", key
end

local function EnsureOwner()
    if not owner then owner = CreateFrame("Frame", "WeintCodexFishingKeys") end
    return owner
end

local function EnsureCast()
    if not castBtn then
        castBtn = CreateFrame("Button", FI.CAST_BUTTON, nil, "SecureActionButtonTemplate")
        castBtn:RegisterForClicks("AnyDown")
        castBtn:SetAttribute("useOnKeyDown", true)
        castBtn:SetAttribute("type", "macro")
        castBtn:SetScript("PreClick", function()
            local can = not _G.SecureCmdOptionParse or _G.SecureCmdOptionParse(FI.CONDITIONS .. " 1")
            if FI.On() and can then
                FI.BeginSession()
                if not state.channeling then
                    if endTimer then endTimer:Cancel() end
                    endTimer = _G.C_Timer and _G.C_Timer.NewTimer and _G.C_Timer.NewTimer(FI.WAIT, EndIfIdle)
                end
            end
        end)
    end
    local name = FI.SpellName()
    local text = name and ("/cast " .. FI.CONDITIONS .. " " .. name)
    if text and castBtn:GetAttribute("macrotext") ~= text then castBtn:SetAttribute("macrotext", text) end
end

-- Beute nehmen ist nicht geschuetzt: ein einfacher Knopf.
function FI.LootAll()
    local n = _G.GetNumLootItems and Plain(_G.GetNumLootItems()) or 0
    for i = n, 1, -1 do pcall(_G.LootSlot, i) end
end

local function EnsureLoot()
    if lootBtn then return end
    lootBtn = CreateFrame("Button", FI.LOOT_BUTTON)
    lootBtn:RegisterForClicks("AnyDown")
    lootBtn:SetScript("OnClick", FI.LootAll)
end

function FI.WatchCombat()
    if state.waitCombat then return end
    state.waitCombat = true
    pcall(ev.RegisterEvent, ev, "PLAYER_REGEN_ENABLED")
end

function FI.Apply()
    local want, key = FI.Wanted()
    if want == state.applied and key == state.appliedKey then return end
    if InCombat() then FI.WatchCombat() return end
    local o = EnsureOwner()
    if _G.ClearOverrideBindings then _G.ClearOverrideBindings(o) end
    if want == "reel" then
        _G.SetOverrideBinding(o, true, key, "INTERACTTARGET")
    elseif want == "loot" then
        EnsureLoot()
        _G.SetOverrideBindingClick(o, true, key, FI.LOOT_BUTTON, "LeftButton")
    elseif want == "cast" then
        EnsureCast()
        _G.SetOverrideBindingClick(o, true, key, FI.CAST_BUTTON, "LeftButton")
    end
    state.applied, state.appliedKey = want, want and key or nil
end

--------------------------------------------------
-- Ereignisse
--------------------------------------------------

local function SoftTarget()
    local ok, guid = pcall(_G.UnitGUID, "softinteract")
    return ok and guid or nil
end

local function OnEvent(_, event, ...)
    if event == "UNIT_SPELLCAST_CHANNEL_START" then
        local unit, _, spellID = ...
        if Plain(unit) == "player" and FI.IsFishing(spellID) then
            state.channeling = true
            if endTimer then endTimer:Cancel(); endTimer = nil end
            if InCombat() then FI.WatchCombat() else FI.BeginSession() end
            state.inReach = FI.IsBobber(SoftTarget())
            FI.Apply()
        end
    elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" then
        local unit = ...
        if Plain(unit) == "player" and state.channeling then
            state.channeling, state.inReach = false, false
            FI.Apply()
            FI.EndSession()
        end
    elseif event == "PLAYER_SOFT_INTERACT_CHANGED" then
        if state.channeling then
            local _, new = ...
            state.inReach = FI.IsBobber(new)
            FI.Apply()
        end
    elseif event == "LOOT_OPENED" then
        local auto = ...
        if Plain(auto) == true or not FI.On() then return end
        local ok, fishing = pcall(_G.IsFishingLoot)
        if not (ok and Plain(fishing)) then return end
        state.lootOpen = true
        FI.Apply()
    elseif event == "LOOT_CLOSED" then
        if state.lootOpen then state.lootOpen = false FI.Apply() end
    elseif event == "PLAYER_EQUIPMENT_CHANGED" then
        if Plain((...)) == FI.MAIN_HAND then FI.Apply() end
    elseif event == "PLAYER_REGEN_ENABLED" then
        state.waitCombat = false
        pcall(ev.UnregisterEvent, ev, "PLAYER_REGEN_ENABLED")
        FI.Apply()
        if state.channeling then FI.BeginSession() elseif state.session then FI.EndSession() end
    elseif event == "PLAYER_LOGIN" then
        -- Nach einem Absturz mitten im Wurf: die alten Werte zurueck.
        local pf = PF()
        if pf and pf.ReleaseOwner then pf.ReleaseOwner(OWNER) end
        FI.Apply()
    elseif event == "PLAYER_ENTERING_WORLD" then
        FI.Apply()
    elseif event == "PLAYER_LOGOUT" then
        local pf = PF()
        if pf and pf.ReleaseOwner then pf.ReleaseOwner(OWNER) end
    end
end

for _, e in ipairs({ "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "PLAYER_LOGOUT", "PLAYER_EQUIPMENT_CHANGED",
                     "UNIT_SPELLCAST_CHANNEL_START", "UNIT_SPELLCAST_CHANNEL_STOP",
                     "PLAYER_SOFT_INTERACT_CHANGED", "LOOT_OPENED", "LOOT_CLOSED" }) do
    pcall(ev.RegisterEvent, ev, e)
end
ev:SetScript("OnEvent", OnEvent)
FI.OnEvent = OnEvent

--------------------------------------------------
-- Einstellungen: Komfortseite "Sammeln"
--------------------------------------------------

-- Lesbarer Name einer Taste ("SHIFT-BUTTON4" -> "Umschalt + Maustaste 4").
local MOUSE = { BUTTON1 = "Linke Maustaste", BUTTON2 = "Rechte Maustaste", BUTTON3 = "Mittlere Maustaste",
                MOUSEWHEELUP = "Mausrad hoch", MOUSEWHEELDOWN = "Mausrad runter" }
local MODS = { SHIFT = "Umschalt", CTRL = "Strg", ALT = "Alt" }
function FI.KeyText(key)
    if type(key) ~= "string" or key == "" then return nil end
    local parts = {}
    for p in key:gmatch("[^-]+") do parts[#parts + 1] = p end
    for i, p in ipairs(parts) do
        parts[i] = MODS[p] or MOUSE[p] or (p:match("^BUTTON(%d+)$") and ("Maustaste " .. p:match("^BUTTON(%d+)$"))) or p
    end
    return table.concat(parts, " + ")
end

-- Belegt die Taste schon etwas im Spiel? (Zur Warnung, nie geaendert.)
function FI.BoundTo(key)
    if not key or not _G.GetBindingAction then return nil end
    local ok, action = pcall(_G.GetBindingAction, key)
    action = ok and Plain(action) or nil
    if type(action) ~= "string" or action == "" then return nil end
    local label = _G.GetBindingName and Plain(_G.GetBindingName(action))
    return (type(label) == "string" and label ~= "") and label or action
end

-- Feld: anklicken, Taste druecken. Esc bricht ab, Entf loescht.
-- Maustasten: waehrend das Feld lauscht, zaehlt auch ein Klick darauf.
local function KeyField(parent, width)
    local w = CreateFrame("Frame", nil, parent)
    local lbl = K.NewText(w, 13)
    lbl:SetPoint("TOPLEFT", w, "TOPLEFT", 0, -2)
    local m = C.textMuted
    lbl:SetTextColor(m[1], m[2], m[3], 1)
    lbl:SetText("Taste zum Angeln")
    local hint = K.NewText(w, 11)
    local b
    local function Locked() return not K.Get(KEY, "fishKeyOn") end
    local function Take(key)
        if key == "LSHIFT" or key == "RSHIFT" or key == "LCTRL" or key == "RCTRL" or key == "LALT" or key == "RALT" then return end
        w.listening = false
        b:EnableKeyboard(false)
        if key ~= "ESCAPE" then
            if key == "DELETE" or key == "BACKSPACE" then
                K.Set(KEY, "fishKey", "")
            else
                local mods = ""
                if _G.IsAltKeyDown and _G.IsAltKeyDown() then mods = mods .. "ALT-" end
                if _G.IsControlKeyDown and _G.IsControlKeyDown() then mods = mods .. "CTRL-" end
                if _G.IsShiftKeyDown and _G.IsShiftKeyDown() then mods = mods .. "SHIFT-" end
                K.Set(KEY, "fishKey", mods .. key)
            end
        end
        w.Sync()
    end
    b = WeintCodex.CreateButton(w, { text = "", kind = "secondary", height = 26, size = 11, backdrop = "bgDark",
        onClick = function(self, mouse)
            if Locked() then return end
            if w.listening then
                local map = { LeftButton = "BUTTON1", RightButton = "BUTTON2", MiddleButton = "BUTTON3",
                              Button4 = "BUTTON4", Button5 = "BUTTON5" }
                if map[mouse] and mouse ~= "LeftButton" then Take(map[mouse]) end
                return
            end
            w.listening = true
            self:EnableKeyboard(true)
            w.Sync()
        end })
    if b.RegisterForClicks then b:RegisterForClicks("AnyUp") end
    b:SetPoint("TOPLEFT", w, "TOPLEFT", 0, -20)
    b:SetWidth(math.min(width, 300))
    b:SetScript("OnKeyDown", function(_, key) if w.listening then Take(key) end end)
    hint:SetPoint("TOPLEFT", b, "BOTTOMLEFT", 0, -4)
    hint:SetWidth(width)
    w.Sync = function()
        local key = FI.Key()
        if w.listening then
            b:SetText("Taste drücken … (Esc: abbrechen, Entf: löschen)")
        else
            b:SetText(FI.KeyText(key) or "Keine – anklicken und Taste drücken")
        end
        local other = FI.BoundTo(key)
        hint:SetText(other and ("Im Spiel liegt darauf „" .. other .. "“ – mit Angel in der Hand gilt WeintCodex, sonst wieder deine Belegung.") or "")
    end
    w.Sync()
    return w
end
FI.KeyField = KeyField

function FI.BuildSection(B)
    local off = function() return not K.Get(KEY, "fishKeyOn") end
    B:Section("Angeln mit einer Taste", "Eine Taste für alles: auswerfen, den Schwimmer einholen, wenn er anbeißt, und – ist „Automatisch plündern“ aus – die Beute nehmen. Jeder Schritt ist dein Tastendruck; dass ein Fisch beißt, hörst du am Platschen. Gilt nur mit Angel in der Hand und außerhalb des Kampfes; deine eigene Tastenbelegung bleibt unangetastet.")
    B:Row({ type = "toggle", label = "Angeln mit einer Taste", key = "fishKeyOn",
            description = "Ohne Angel in der Hand gilt die Taste wieder für das, was du selbst darauf gelegt hast." },
          { type = "custom", height = 64, create = function(parent) return KeyField(parent, 300) end })
    B:Advanced()
    B:Row({ type = "toggle", label = "Platschen lauter", key = "fishLoud", disabled = off,
            description = "Während des Wurfs Effekte an und auf voll – danach wie vorher." },
          { type = "toggle", label = "Ton im Hintergrund", key = "fishBg", disabled = off,
            description = "Das Platschen auch hören, wenn ein anderes Fenster vorn ist." })
    B:Row({ type = "toggle", label = "Symbol über dem Schwimmer", key = "fishIcon", disabled = off,
            description = "Zeigt, wann die Taste den Schwimmer erreicht." },
          { type = "empty" })
    B:EndAdvanced()
end

local mod = K.Module(KEY)
if mod then
    for k, v in pairs(FI.DEFAULTS) do
        if mod.defaults[k] == nil then mod.defaults[k] = v end
    end
    for _, page in ipairs(mod.pages) do
        if page.key == "sammeln" then
            local orig = page.build
            page.build = function(B, ...)
                if orig then orig(B, ...) end
                FI.BuildSection(B)
            end
        end
    end
end

K.Listen(function(kind, key)
    if (kind == "active" or kind == "setting") and key == KEY then
        FI.Apply()
        if not FI.On() and state.session then FI.EndSession() end
    end
end)
