--------------------------------------------------
-- WeintCodex :: Oberflaeche - Fenster verschieben (6.10.4.0)
--------------------------------------------------
-- Beta-Test: "Das Verschieben von Fenstern [wie in MoveAny] finde ich
-- richtig gut und das soll auch in Codex drin sein. Nur Fenster, die man
-- oeffnet. Keine Einstellungsoption, von vornherein drin."
--
-- MoveAny ist "All Rights Reserved" - wie bei EllesmereUI kein Code und
-- kein Medium von dort. Uebernommen ist nur das Verhalten:
--
--   ziehen     Linke Maustaste auf einer freien Stelle des Fensters
--              (Titel, Rand, Grund - ueber Knoepfen und Listen klickt man
--              weiter, was dort liegt). Das Fenster bleibt auf dem
--              Bildschirm.
--   solange    Der Platz gilt, solange das Fenster offen ist - auch wenn
--   offen      das Spiel beim Oeffnen eines zweiten Fensters neu anordnet
--              (UpdateUIPanelPositions: danach noch einmal).
--   zu         Beim Schliessen faellt er weg: das naechste Mal steht das
--              Fenster wieder dort, wo das Spiel es hinsetzt (6.10.4.1,
--              Beta-Test: "wenn ein Fenster geschlossen wurde, soll es
--              wieder dort auftauchen, wo es eigentlich sein sollte"). Bis
--              6.10.4.0 galt der Platz dauerhaft (ui.windowPos) - das wird
--              beim Start einmal geleert.
--   zurueck    Umschalt + Rechtsklick auf das Fenster: dieses Fenster an
--              den Platz des Spiels. /wcui fenster zurück: alle offenen.
--
-- Nur oberste Fenster (Eltern = UIParent): ein Reiter des Charakterfensters
-- (PVPFrame) darf sich nicht von seinem Fenster loesen. Geschuetzte Fenster
-- werden im Kampf weder angefasst noch eingerichtet - nachgeholt beim
-- Verlassen des Kampfes. Die Karte nur im Fenster, nicht vergroessert.
-- Laeuft MoveAny oder BlizzMove, tritt WeintCodex zurueck: zwei Addons,
-- die dasselbe Fenster setzen, kaempfen bei jedem Oeffnen.
--
-- Kein Modul mit Schalter (Wunsch: von vornherein drin) und unabhaengig vom
-- Hauptschalter der Oberflaeche - verschoben wird nur, was jemand zieht.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIMoveWindows = {}

local MW = WeintCodex.UIMoveWindows
local K = WeintCodex.UIKit

-- Fenster, die man oeffnet. Was der Client nicht kennt, faellt heraus;
-- was erst beim Oeffnen laedt (Blizzard_*), kommt mit ADDON_LOADED dazu.
MW.WINDOWS = {
    "CharacterFrame", "PlayerSpellsFrame", "SpellBookFrame", "PlayerTalentFrame", "ClassTalentFrame", "TalentFrame",
    "FriendsFrame", "SocialUIFrame", "CommunitiesFrame", "GuildFrame", "LFGParentFrame", "PVEFrame", "CollectionsJournal", "LegacySystemFrame",
    "ProfessionsFrame", "ProfessionsBookFrame", "TradeSkillFrame", "CraftFrame", "ClassTrainerFrame",
    "GossipFrame", "QuestFrame", "QuestLogFrame", "QuestLogPopupDetailFrame", "ItemTextFrame",
    "MerchantFrame", "MailFrame", "OpenMailFrame", "BankFrame", "GuildBankFrame", "AuctionHouseFrame",
    "TradeFrame", "LootFrame", "MacroFrame", "SettingsPanel", "AddonList", "WorldMapFrame",
    "TaxiFrame", "FlightMapFrame", "DressUpFrame", "TabardFrame", "InspectFrame", "TimeManagerFrame",
    "CalendarFrame", "ChannelFrame", "AchievementFrame", "EncounterJournal", "ItemSocketingFrame",
    "PetStableFrame", "StableFrame", "HelpFrame", "ChatConfigFrame", "KeyBindingFrame", "QuickKeybindFrame",
    "ClickBindingFrame", "CooldownViewerSettings",
}
MW.CONFLICTS = { "MoveAny", "BlizzMove" }
-- 6.29.8.0 (Beta-Test: "Das Beutefenster ... muss auch frei verschiebbar
-- sein"): Beute behaelt ihren Platz dauerhaft (je Profil), sonst stuende
-- sie bei jedem Pluendern wieder am Platz des Spiels. Auch dann, wenn das
-- Spiel sie nicht direkt an UIParent haengt.
MW.KEEP = { LootFrame = true }
-- Wuerfeln um Beute: GroupLootFrame1..4 haengen am GroupLootContainer;
-- gezogen wird der Behaelter, damit alle Wuerfe zusammen wandern.
MW.ROLLS = { "GroupLootFrame1", "GroupLootFrame2", "GroupLootFrame3", "GroupLootFrame4" }

local hooked = setmetatable({}, { __mode = "k" })    -- Fenster -> Name
local moving = setmetatable({}, { __mode = "k" })
local pending = setmetatable({}, { __mode = "k" })   -- im Kampf aufgeschoben
local default = setmetatable({}, { __mode = "k" })   -- Platz des Spiels (Anker 1)
local mine = setmetatable({}, { __mode = "k" })      -- zuletzt von uns gesetzt
local open = setmetatable({}, { __mode = "k" })      -- Platz, solange offen
MW.hooked, MW.pending, MW.default, MW.open = hooked, pending, default, open
MW.active, MW.reason = false, nil

-- Bis 6.10.4.0 dauerhaft gemerkte Plaetze: einmal weg.
function MW.Forget()
    local ui = K.Root()
    if ui and ui.windowPos ~= nil then ui.windowPos = nil return true end
    return false
end

local function Loaded(name)
    local A = _G.C_AddOns
    local f = (type(A) == "table" and A.IsAddOnLoaded) or _G.IsAddOnLoaded
    if type(f) ~= "function" then return false end
    local ok, v = pcall(f, name)
    return ok and K.Bool(v, false) or false
end

-- Darf dieses Fenster gerade angefasst werden?
local function Blocked(f)
    if not K.Bool(_G.InCombatLockdown and _G.InCombatLockdown(), false) then return false end
    return K.Bool(f.IsProtected and f:IsProtected(), true)
end
MW.Blocked = Blocked

-- Die Karte vergroessert: nicht ziehen, nicht setzen.
local function Maximized(f)
    return f == _G.WorldMapFrame and type(f.IsMaximized) == "function" and K.Bool(f:IsMaximized(), false)
end

local function Round(v) return math.floor(v + 0.5) end

-- Dauerhafte Plaetze (MW.KEEP, Wuerfe) im Profil.
local function KeepStore()
    local prof = K.Profile and K.Profile()
    if type(prof) ~= "table" then return nil end
    prof.positions = prof.positions or {}
    return prof.positions
end
function MW.KeepGet(name)
    local st = KeepStore()
    local v = st and st["win:" .. name]
    return type(v) == "table" and type(v.x) == "number" and type(v.y) == "number" and v or nil
end
function MW.KeepSet(name, x, y)
    local st = KeepStore()
    if not st then return false end
    st["win:" .. name] = (x and y) and { x = x, y = y } or nil
    return true
end

-- Ist der erste Anker der, den WeintCodex zuletzt gesetzt hat?
local function IsMine(f)
    local m = mine[f]
    if not m then return false end
    local ok, p, rel, rp, x, y = pcall(f.GetPoint, f, 1)
    return ok and p == "TOPLEFT" and rel == _G.UIParent and rp == "BOTTOMLEFT"
        and K.Plain(x) == m.x and K.Plain(y) == m.y
end

-- Den Platz des Spiels merken, solange er noch seiner ist.
local function RememberDefault(f)
    if IsMine(f) then return end
    local ok, p, rel, rp, x, y = pcall(f.GetPoint, f, 1)
    if ok and type(p) == "string" then
        local d = default[f] or {}
        d.p, d.rel, d.rp, d.x, d.y = p, rel, rp, K.Plain(x), K.Plain(y)
        default[f] = d
    end
end

-- Den gemerkten Platz setzen (beim Zeigen und nachdem das Spiel ordnet).
function MW.Apply(f)
    local pos = hooked[f] and open[f]
    if type(pos) ~= "table" or moving[f] or Maximized(f) then return false end
    if Blocked(f) then pending[f] = true return false end
    RememberDefault(f)
    f:ClearAllPoints()
    f:SetPoint("TOPLEFT", _G.UIParent, "BOTTOMLEFT", pos.x, pos.y)
    local m = mine[f] or {}
    m.x, m.y = pos.x, pos.y
    mine[f] = m
    return true
end

function MW.Save(f)
    if not hooked[f] then return false end
    local l, t = K.Plain(f:GetLeft()), K.Plain(f:GetTop())
    if type(l) ~= "number" or type(t) ~= "number" then return false end
    local pos = open[f] or {}
    pos.x, pos.y = Round(l), Round(t)
    open[f] = pos
    if MW.KEEP[hooked[f]] then MW.KeepSet(hooked[f], pos.x, pos.y) end
    -- Neu an den gemerkten Platz verankert (StopMovingOrSizing hinterlaesst
    -- einen Anker an der naechsten Ecke) - so ist er beim Zeigen "unserer".
    f:ClearAllPoints()
    f:SetPoint("TOPLEFT", _G.UIParent, "BOTTOMLEFT", pos.x, pos.y)
    local m = mine[f] or {}
    m.x, m.y = pos.x, pos.y
    mine[f] = m
    return true
end

local function StopMove(f)
    if not moving[f] then return end
    moving[f] = nil
    f:StopMovingOrSizing()
    -- Nicht im Layout des Spiels speichern: sonst setzte der Client das
    -- Fenster beim Anmelden selbst und naehme es aus seiner Anordnung.
    if f.SetUserPlaced then pcall(f.SetUserPlaced, f, false) end
    MW.Save(f)
end

-- Ein Fenster an den Platz des Spiels zurueck. Im Kampf ein geschuetztes:
-- nach dem Kampf.
function MW.Reset(f)
    if not hooked[f] then return false end
    local had = open[f] ~= nil
    open[f] = nil
    local d = default[f]
    if had and d then
        if Blocked(f) then pending[f] = "reset" return true end
        f:ClearAllPoints()
        f:SetPoint(d.p, d.rel, d.rp, d.x, d.y)
    end
    mine[f] = nil
    return had
end

function MW.ResetAll()
    local n = 0
    for f in pairs(hooked) do
        if MW.Reset(f) then n = n + 1 end
    end
    return n
end

local function OnDragStart(f)
    if Blocked(f) or Maximized(f) then return end
    RememberDefault(f)
    moving[f] = true
    f:StartMoving()
end

local function OnMouseUp(f, button)
    if button == "RightButton" and K.Bool(_G.IsShiftKeyDown and _G.IsShiftKeyDown(), false) then
        if MW.KEEP[hooked[f]] then MW.KeepSet(hooked[f], nil, nil) end
        MW.Reset(f)
    end
end

local function OnShow(f)
    local keep = MW.KEEP[hooked[f]] and MW.KeepGet(hooked[f])
    if keep then open[f] = { x = keep.x, y = keep.y } end
    MW.Apply(f)
end
-- Zu: der Platz gilt nur, solange das Fenster offen ist (Beute: dauerhaft).
local function OnHide(f)
    StopMove(f)
    if MW.KEEP[hooked[f]] then return end
    MW.Reset(f)
end
local function OnDragStop(f) StopMove(f) end

-- Ein Fenster einrichten (einmal). Nur oberste Fenster.
function MW.Hook(f, name)
    if type(f) ~= "table" or hooked[f] or not f.HookScript or not f.SetMovable then return false end
    if f.IsForbidden and f:IsForbidden() then return false end
    if f.GetParent and f:GetParent() ~= _G.UIParent and not MW.KEEP[name] then return false end
    if Blocked(f) then pending[f] = name return false end
    pending[f] = nil
    hooked[f] = name
    f:SetMovable(true)
    if f.SetClampedToScreen then f:SetClampedToScreen(true) end
    if f.RegisterForDrag then f:RegisterForDrag("LeftButton") end
    -- Ohne Maus kein Ziehen. Fenster nehmen sie fast alle schon an.
    if f.EnableMouse and f.IsMouseEnabled and not K.Bool(f:IsMouseEnabled(), true) then f:EnableMouse(true) end
    f:HookScript("OnDragStart", OnDragStart)
    f:HookScript("OnDragStop", OnDragStop)
    f:HookScript("OnMouseUp", OnMouseUp)
    f:HookScript("OnShow", OnShow)
    f:HookScript("OnHide", OnHide)
    if K.Bool(f.IsShown and f:IsShown(), false) then MW.Apply(f) end
    return true
end

-- Wuerfeln um Beute: ziehen an einem Wurf bewegt den Behaelter (oder, wo
-- es ihn nicht gibt, den Wurf selbst). Der Platz bleibt (Profil), weil ein
-- Wurf nur Sekunden steht. Umschalt + Rechtsklick: zurueck.
local function RollTarget(f)
    local c = _G.GroupLootContainer
    if type(c) == "table" and c.StartMoving and f.GetParent and f:GetParent() == c then return c end
    return f
end
MW.RollTarget = RollTarget

function MW.ApplyRoll(f)
    local t = RollTarget(f)
    local pos = MW.KeepGet("GroupLoot")
    if not pos or Blocked(t) then return false end
    if not default[t] then
        local ok, p, rel, rp, x, y = pcall(t.GetPoint, t, 1)
        if ok and type(p) == "string" then default[t] = { p = p, rel = rel, rp = rp, x = K.Plain(x), y = K.Plain(y) } end
    end
    t:ClearAllPoints()
    t:SetPoint("TOPLEFT", _G.UIParent, "BOTTOMLEFT", pos.x, pos.y)
    return true
end

function MW.HookRoll(f)
    if type(f) ~= "table" or hooked[f] or not f.HookScript then return false end
    if f.IsForbidden and f:IsForbidden() then return false end
    hooked[f] = "GroupLoot"
    local t = RollTarget(f)
    if t.SetMovable then t:SetMovable(true) end
    if t.SetClampedToScreen then t:SetClampedToScreen(true) end
    if f.RegisterForDrag then f:RegisterForDrag("LeftButton") end
    if f.EnableMouse then f:EnableMouse(true) end
    f:HookScript("OnDragStart", function(self)
        local tt = RollTarget(self)
        if Blocked(tt) then return end
        if tt.SetMovable then tt:SetMovable(true) end
        moving[tt] = true
        tt:StartMoving()
    end)
    f:HookScript("OnDragStop", function(self)
        local tt = RollTarget(self)
        if not moving[tt] then return end
        moving[tt] = nil
        tt:StopMovingOrSizing()
        if tt.SetUserPlaced then pcall(tt.SetUserPlaced, tt, false) end
        local l, top = K.Plain(tt:GetLeft()), K.Plain(tt:GetTop())
        if type(l) == "number" and type(top) == "number" then
            MW.KeepSet("GroupLoot", Round(l), Round(top))
            MW.ApplyRoll(self)
        end
    end)
    f:HookScript("OnMouseUp", function(self, button)
        if button == "RightButton" and K.Bool(_G.IsShiftKeyDown and _G.IsShiftKeyDown(), false) then
            MW.KeepSet("GroupLoot", nil, nil)
            local tt = RollTarget(self)
            local d = default[tt]
            if d and not Blocked(tt) then
                tt:ClearAllPoints()
                tt:SetPoint(d.p, d.rel, d.rp, d.x, d.y)
            end
        end
    end)
    f:HookScript("OnShow", function(self) MW.ApplyRoll(self) end)
    return true
end

function MW.HookAll()
    if not MW.active then return 0 end
    local n = 0
    for _, name in ipairs(MW.ROLLS) do
        if MW.HookRoll(_G[name]) then n = n + 1 end
    end
    for _, name in ipairs(MW.WINDOWS) do
        if MW.Hook(_G[name], name) then n = n + 1 end
    end
    return n
end

-- Nachdem das Spiel seine Fenster angeordnet hat: unsere wieder hin.
function MW.Reapply()
    for f in pairs(hooked) do
        if K.Bool(f:IsShown(), false) then MW.Apply(f) end
    end
end

function MW.Start()
    for _, a in ipairs(MW.CONFLICTS) do
        if Loaded(a) then
            MW.active, MW.reason = false, a
            return false
        end
    end
    MW.active, MW.reason = true, nil
    MW.Forget()
    if not MW._uiHook and type(_G.UpdateUIPanelPositions) == "function" and _G.hooksecurefunc then
        MW._uiHook = true
        _G.hooksecurefunc("UpdateUIPanelPositions", MW.Reapply)
    end
    -- Das Spiel ordnet die Wuerfe neu (neuer Wurf, einer faellt weg).
    for _, fn in ipairs({ "GroupLootContainer_Update", "GroupLootContainer_AddFrame", "GroupLootContainer_RemoveFrame" }) do
        if not MW["_h" .. fn] and type(_G[fn]) == "function" and _G.hooksecurefunc then
            MW["_h" .. fn] = true
            _G.hooksecurefunc(fn, function()
                local f = _G.GroupLootFrame1
                if type(f) == "table" then MW.ApplyRoll(f) end
            end)
        end
    end
    MW.HookAll()
    return true
end

-- Nach dem Kampf: Aufgeschobenes einrichten bzw. setzen.
function MW.Flush()
    for f, v in pairs(pending) do
        pending[f] = nil
        if hooked[f] then
            if v == "reset" then
                local d = default[f]
                if d and not open[f] then
                    f:ClearAllPoints()
                    f:SetPoint(d.p, d.rel, d.rp, d.x, d.y)
                    mine[f] = nil
                end
            elseif K.Bool(f:IsShown(), false) then MW.Apply(f) end
        elseif type(v) == "string" then
            MW.Hook(f, v)
        end
    end
end

-- Fuer /wcui fenster und die Selbstpruefung.
function MW.Status()
    if not MW.active then
        return MW.reason and ("Fenster verschieben: aus, " .. MW.reason .. " ist geladen") or "Fenster verschieben: noch nicht gestartet"
    end
    local n, moved = 0, 0
    for _ in pairs(hooked) do n = n + 1 end
    for _ in pairs(open) do moved = moved + 1 end
    return string.format("Fenster verschieben: %d Fenster ziehbar, %d gerade verschoben (bis zum Schließen)", n, moved)
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("PLAYER_REGEN_ENABLED")
ev:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        MW.Start()
    elseif event == "ADDON_LOADED" then
        -- Fenster, die das Spiel erst beim Oeffnen laedt (Blizzard_*).
        if MW.active then MW.HookAll() end
    elseif event == "PLAYER_REGEN_ENABLED" then
        if MW.active then MW.Flush() end
    end
end)
MW.events = ev
