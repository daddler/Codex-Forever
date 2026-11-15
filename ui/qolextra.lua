--------------------------------------------------
-- WeintCodex :: Komfort - Kampf- und Alltagshelfer (Seite "Helfer")
--------------------------------------------------
-- 1.0.7.0 (Wunsch nach dem Vergleich mit Naowh Forever, Verhalten
-- nachgebaut, eigener Code - dort "All Rights Reserved"). Jeder Helfer hat
-- einen eigenen Schalter beim Komfort (Seite "Helfer", Kampf & Gruppe),
-- ALLE AB WERK AUS: wer seine Oberflaeche eingerichtet hat, findet sie
-- nach dem Update unveraendert vor.
--
--   Fadenkreuz        kleines Kreuz in der Bildmitte, nur im Kampf
--   Mausring          Ring um den Mauszeiger (immer oder nur im Kampf)
--   Kampftimer        Dauer des laufenden Kampfes, danach kurz die letzte
--   Heiler-Mana       Mana der Heiler deiner Gruppe als kleine Leisten
--                     (Werte gehen ungelesen an die Leisten - im Kampf
--                     darf der Client sie geheim liefern)
--   Zauber-Warteschlange  Spieleinstellung SpellQueueWindow, nur wenn du
--                     einen Wert waehlst - ueber PF.SetCVar (Wert von
--                     vorher gemerkt, beim Abschalten zurueck)
--   Beute-Feed        was du bekommst, kurz am Rand (aus den Chatmeldungen
--                     des Spiels gelesen, nie umgeschrieben)
--   Schliesskassetten Tooltip: noetige Fertigkeit im Schlossknacken
--   Flugpunkte        Hinweis, wenn ein Flugpunkt in diesem Gebiet noch
--                     nicht entdeckt ist - erst, nachdem du einmal eine
--                     Flugkarte geoeffnet hast (vorher weiss es niemand)
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIQoLExtra = {}

local QX = WeintCodex.UIQoLExtra
local K = WeintCodex.UIKit
local C = WeintCodex.Colors
local KEY = "comfort"

QX.DEFAULTS = {
    crosshair = false, mouseRing = false, mouseRingCombat = true, combatTimer = false,
    healerMana = false, spellQueue = 0, lootFeed = false, lockboxTip = true, flightRemind = false,
    pickpocketMsg = true,
}

local function Get(k) return K.IsActive(KEY) and K.Get(KEY, k) end
local function Now() return _G.GetTime and _G.GetTime() or 0 end
local function Say(t) print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " " .. t) end

--------------------------------------------------
-- Fadenkreuz
--------------------------------------------------

local cross
local function BuildCross()
    cross = CreateFrame("Frame", "WeintCodexCrosshair", UIParent)
    cross:SetSize(24, 24)
    cross:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    cross:SetFrameStrata("BACKGROUND")
    cross:EnableMouse(false)
    local t = C.textBright
    local h = cross:CreateTexture(nil, "OVERLAY")
    h:SetSize(24, 2)
    h:SetPoint("CENTER")
    h:SetColorTexture(t[1], t[2], t[3], 0.7)
    local v = cross:CreateTexture(nil, "OVERLAY")
    v:SetSize(2, 24)
    v:SetPoint("CENTER")
    v:SetColorTexture(t[1], t[2], t[3], 0.7)
    cross:Hide()
end
function QX.UpdateCross()
    if not cross then return end
    cross:SetShown(Get("crosshair") and K.InCombat() and true or false)
end

--------------------------------------------------
-- Mausring
--------------------------------------------------

local ring
local function BuildRing()
    ring = CreateFrame("Frame", "WeintCodexMouseRing", UIParent)
    ring:SetSize(48, 48)
    ring:SetFrameStrata("TOOLTIP")
    ring:EnableMouse(false)
    local tex = ring:CreateTexture(nil, "OVERLAY")
    tex:SetAllPoints(ring)
    tex:SetTexture(K.MEDIA .. "ring")
    local a = C.accentBright or C.accent
    tex:SetVertexColor(a[1], a[2], a[3], 0.8)
    ring:SetScript("OnUpdate", function(self)
        local x, y = _G.GetCursorPosition()
        local s = UIParent:GetEffectiveScale()
        self:ClearAllPoints()
        self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / s, y / s)
    end)
    ring:Hide()
end
function QX.UpdateRing()
    if not ring then return end
    local on = Get("mouseRing") and (not Get("mouseRingCombat") or K.InCombat())
    ring:SetShown(on and true or false)
end

--------------------------------------------------
-- Kampftimer
--------------------------------------------------

local timer
function QX.FormatTime(sec)
    sec = math.max(0, math.floor(sec))
    return string.format("%d:%02d", math.floor(sec / 60), sec % 60)
end
local function BuildTimer()
    timer = CreateFrame("Frame", "WeintCodexCombatTimer", UIParent)
    timer:SetSize(80, 22)
    timer.text = K.NewText(timer, 14)
    timer.text:SetPoint("CENTER", timer, "CENTER", 0, 0)
    timer.text:SetShadowOffset(1, -1)
    timer:Hide()
    timer.WCShowForUnlock = function(self, on) self._unlock = on and true or nil if on then self.text:SetText("0:42") self:Show() else QX.UpdateTimer() end end
    K.RegisterMover(timer, "combattimer", "Kampftimer", K.Layout("combattimer"))
    local shown = -1
    timer:SetScript("OnUpdate", function(self)
        if not self.start then return end
        local t = math.floor(Now() - self.start)
        if t ~= shown then shown = t self.text:SetText(QX.FormatTime(t)) end
    end)
end
function QX.UpdateTimer(event)
    if not timer or timer._unlock then return end
    if not Get("combatTimer") then timer.start = nil timer:Hide() return end
    if event == "PLAYER_REGEN_DISABLED" then
        timer.start = Now()
        local m = C.textBright
        timer.text:SetTextColor(m[1], m[2], m[3])
        timer:Show()
    elseif event == "PLAYER_REGEN_ENABLED" and timer.start then
        local d = Now() - timer.start
        timer.start = nil
        local m = C.textMuted
        timer.text:SetTextColor(m[1], m[2], m[3])
        timer.text:SetText(QX.FormatTime(d))
        if _G.C_Timer and _G.C_Timer.After then
            _G.C_Timer.After(5, function() if timer and not timer.start and not timer._unlock then timer:Hide() end end)
        end
    end
end

--------------------------------------------------
-- Heiler-Mana
--------------------------------------------------

local hm
local hmBars = {}
QX.HM_MAX = 8
function QX.Healers()
    local out = {}
    if not (_G.GetNumGroupMembers and _G.UnitGroupRolesAssigned) then return out end
    local n = tonumber(K.Plain(_G.GetNumGroupMembers())) or 0
    if n < 2 then return out end
    local raid = _G.IsInRaid and K.Bool(_G.IsInRaid(), false)
    local function add(u)
        if K.Plain(_G.UnitGroupRolesAssigned(u)) == "HEALER" then out[#out + 1] = u end
    end
    if raid then for i = 1, n do add("raid" .. i) end
    else add("player") for i = 1, n - 1 do add("party" .. i) end end
    return out
end
local function BuildHM()
    hm = CreateFrame("Frame", "WeintCodexHealerMana", UIParent)
    hm:SetSize(140, 16)
    hm:Hide()
    hm.WCShowForUnlock = function(self, on) self._unlock = on and true or nil QX.UpdateHM() end
    K.RegisterMover(hm, "healermana", "Heiler-Mana", K.Layout("healermana"))
end
function QX.UpdateHM()
    if not hm then return end
    local list = (Get("healerMana") and QX.Healers()) or {}
    if hm._unlock and #list == 0 then list = { "player" } end
    local mc = WeintCodex.GameColors.mana or C.info
    for i = 1, math.min(#list, QX.HM_MAX) do
        local b = hmBars[i]
        if not b then
            b = CreateFrame("Frame", nil, hm)
            b:SetSize(140, 14)
            b:SetPoint("TOPLEFT", hm, "TOPLEFT", 0, -(i - 1) * 16)
            b.bar = K.NewBar(b)
            b.bar:SetAllPoints(b)
            K.PaintBar(b.bar, mc[1], mc[2], mc[3])
            local bg = b:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints(b)
            local p = C.bgPanel
            bg:SetColorTexture(p[1], p[2], p[3], 0.85)
            local top = CreateFrame("Frame", nil, b)
            top:SetAllPoints(b)
            top:SetFrameLevel((b.bar:GetFrameLevel() or 1) + 2)
            b.name = K.NewText(top, 10)
            b.name:SetPoint("LEFT", b, "LEFT", 3, 0)
            b.name:SetShadowOffset(1, -1)
            hmBars[i] = b
        end
        local u = list[i]
        b.unit = u
        pcall(b.name.SetText, b.name, _G.UnitName(u))
        pcall(b.bar.SetMinMaxValues, b.bar, 0, _G.UnitPowerMax(u, 0))
        pcall(b.bar.SetValue, b.bar, _G.UnitPower(u, 0))
        b:Show()
    end
    for i = math.min(#list, QX.HM_MAX) + 1, #hmBars do hmBars[i]:Hide() hmBars[i].unit = nil end
    hm:SetHeight(math.max(16, math.min(#list, QX.HM_MAX) * 16))
    hm:SetShown(#list > 0)
end
function QX.PowerHM(unit)
    for _, b in ipairs(hmBars) do
        if b.unit and b:IsShown() and _G.UnitIsUnit and K.Bool(_G.UnitIsUnit(b.unit, unit), false) then
            pcall(b.bar.SetMinMaxValues, b.bar, 0, _G.UnitPowerMax(b.unit, 0))
            pcall(b.bar.SetValue, b.bar, _G.UnitPower(b.unit, 0))
        end
    end
end

--------------------------------------------------
-- Zauber-Warteschlange (SpellQueueWindow)
--------------------------------------------------

function QX.ApplyQueue()
    local PF = WeintCodex.UIProfile
    if not (PF and PF.SetCVar) then return end
    local v = tonumber(Get("spellQueue")) or 0
    if K.InCombat() then K.AfterCombat(QX.ApplyQueue) return end
    if v > 0 then PF.SetCVar("SpellQueueWindow", tostring(v), "spellqueue")
    elseif PF.ReleaseOwner then PF.ReleaseOwner("spellqueue") end
end

--------------------------------------------------
-- Beute-Feed
--------------------------------------------------

local feed
local feedLines = {}
QX.FEED_MAX, QX.FEED_HOLD = 6, 6
local function BuildFeed()
    feed = CreateFrame("Frame", "WeintCodexLootFeed", UIParent)
    feed:SetSize(240, QX.FEED_MAX * 20)
    feed.WCShowForUnlock = function(self, on) self._unlock = on and true or nil if on then QX.AddFeed(134400, "Beispiel ×3") end end
    K.RegisterMover(feed, "lootfeed", "Beute-Feed", K.Layout("lootfeed"))
    feed:SetScript("OnUpdate", function()
        local now = Now()
        for _, l in ipairs(feedLines) do
            if l:IsShown() then
                local age = now - (l.at or 0)
                if age > QX.FEED_HOLD then l:Hide() elseif age > QX.FEED_HOLD - 1 then l:SetAlpha(QX.FEED_HOLD - age) end
            end
        end
    end)
end
function QX.AddFeed(icon, text)
    if not feed then return end
    -- nach oben schieben: aelteste faellt raus
    for i = QX.FEED_MAX, 2, -1 do
        local a, b = feedLines[i], feedLines[i - 1]
        if a and b and b:IsShown() then
            a.icon:SetTexture(b.icon:GetTexture())
            a.text:SetText(b.text:GetText())
            a.at = b.at
            a:SetAlpha(b:GetAlpha())
            a:Show()
        end
    end
    local l = feedLines[1]
    if not l then
        for i = 1, QX.FEED_MAX do
            local f = CreateFrame("Frame", nil, feed)
            f:SetSize(240, 20)
            f:SetPoint("BOTTOMLEFT", feed, "BOTTOMLEFT", 0, (i - 1) * 20)
            f.icon = f:CreateTexture(nil, "ARTWORK")
            f.icon:SetSize(18, 18)
            f.icon:SetPoint("LEFT", f, "LEFT", 0, 0)
            f.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            f.text = K.NewText(f, 11)
            f.text:SetPoint("LEFT", f.icon, "RIGHT", 5, 0)
            f.text:SetShadowOffset(1, -1)
            f:Hide()
            feedLines[i] = f
        end
        l = feedLines[1]
    end
    l.icon:SetTexture(icon or 134400)
    l.text:SetText(text)
    l.at = Now()
    l:SetAlpha(1)
    l:Show()
end
-- Chatmeldung des Spiels lesen: Gegenstandslink und Anzahl. nil, wenn
-- es nicht die eigene Beute ist oder der Text geheim ist.
function QX.ParseLoot(msg)
    if type(msg) ~= "string" or K.IsSecret(msg) then return nil end
    local self1 = _G.rawget(_G, "LOOT_ITEM_SELF")
    local self2 = _G.rawget(_G, "LOOT_ITEM_SELF_MULTIPLE")
    local push1 = _G.rawget(_G, "LOOT_ITEM_PUSHED_SELF")
    local push2 = _G.rawget(_G, "LOOT_ITEM_PUSHED_SELF_MULTIPLE")
    local function pat(s) return s and ("^" .. s:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1"):gsub("%%%%s", "(.+)"):gsub("%%%%d", "(%%d+)") .. "$") end
    for _, f in ipairs({ self2, push2 }) do
        local p = pat(f)
        if p then
            local link, n = msg:match(p)
            if link then return link, tonumber(n) or 1 end
        end
    end
    for _, f in ipairs({ self1, push1 }) do
        local p = pat(f)
        if p then
            local link = msg:match(p)
            if link then return link, 1 end
        end
    end
    return nil
end

--------------------------------------------------
-- Taschendiebstahl (1.0.7.2, Wunsch: "bei Fehlschlag kommt die rote
-- Meldung, beim Erfolg nichts - toll waere eine Meldung in gruen")
--------------------------------------------------
-- Nach dem eigenen Taschendiebstahl (Zauber 921 oder gleicher Name) zeigt,
-- was binnen QX.PP_WINDOW Sekunden an Beute und Geld kommt, die Leiste des
-- Spiels fuer Meldungen (UIErrorsFrame) in Gruen - dieselbe Stelle wie die
-- rote Meldung beim Fehlschlag. Nur Schurken; Schalter pickpocketMsg.
QX.PP_SPELL, QX.PP_WINDOW = 921, 10
QX.ppAt = -100
function QX.IsPickpocket(id)
    if K.IsSecret(id) or type(id) ~= "number" then return false end
    if id == QX.PP_SPELL then return true end
    local cs = _G.C_Spell
    local a = cs and cs.GetSpellName and K.Plain(cs.GetSpellName(id))
    local b = cs and cs.GetSpellName and K.Plain(cs.GetSpellName(QX.PP_SPELL))
    return type(a) == "string" and a == b
end
function QX.PickpocketShow(text)
    local ef = _G.UIErrorsFrame
    local g = C.successBright or C.success
    if ef and ef.AddMessage then ef:AddMessage(text, g[1], g[2], g[3], 1) end
end
function QX.PickpocketLoot(link, n, now)
    if not Get("pickpocketMsg") or (now or Now()) - QX.ppAt > QX.PP_WINDOW then return false end
    QX.PickpocketShow("Taschendiebstahl: " .. link .. (n and n > 1 and (" ×" .. n) or ""))
    return true
end

--------------------------------------------------
-- Schliesskassetten (Tooltip)
--------------------------------------------------

local function OnItem(tt, data)
    if not Get("lockboxTip") then return end
    if tt ~= _G.GameTooltip and tt ~= _G.ItemRefTooltip then return end
    if tt.IsForbidden and tt:IsForbidden() then return end
    local AP = WeintCodex.UIAuctionPrices
    local id = AP and AP.ItemIdOf and AP.ItemIdOf(tt, data)
    local need = id and WeintCodex.LockboxData and WeintCodex.LockboxData[id]
    if not need then return end
    local m, b = C.textMuted, C.textBright
    tt:AddDoubleLine("Schlossknacken nötig", tostring(need), m[1], m[2], m[3], b[1], b[2], b[3])
end

--------------------------------------------------
-- Flugpunkte
--------------------------------------------------

local function FlightStore()
    local st = K.CharState and K.CharState()
    if not st then return nil end
    st.flights = st.flights or { known = {}, all = {} }
    return st.flights
end
-- Beim Oeffnen einer Flugkarte: alle Punkte mit Stand merken.
function QX.ReadTaxi()
    local tm = _G.C_TaxiMap
    local s = FlightStore()
    if not (tm and tm.GetAllTaxiNodes and s and _G.GetTaxiMapID) then return 0 end
    local ok, nodes = pcall(tm.GetAllTaxiNodes, K.Plain(_G.GetTaxiMapID()))
    if not (ok and type(nodes) == "table") then return 0 end
    local E = _G.Enum and _G.Enum.FlightPathState
    local n = 0
    for _, nd in ipairs(nodes) do
        local name = K.Plain(nd.name)
        if type(name) == "string" then
            s.all[name] = true
            local st = K.Plain(nd.state)
            if E and (st == E.Current or st == E.Reachable) then s.known[name] = true n = n + 1 end
        end
    end
    s.read = true
    return n
end
-- Ein noch nicht entdeckter Punkt, dessen Name mit dem Ort beginnt.
function QX.MissingFlight(zone, sub)
    local s = FlightStore()
    if not (s and s.read) then return nil end
    for name in pairs(s.all) do
        if not s.known[name] then
            local head = name:match("^([^,]+)")
            if head and ((sub and sub ~= "" and head == sub) or (zone and head == zone) or (zone and name:find(zone, 1, true))) then
                return name
            end
        end
    end
    return nil
end
local reminded = {}
function QX.CheckFlight()
    if not Get("flightRemind") then return end
    local zone = _G.GetZoneText and K.Plain(_G.GetZoneText())
    local sub = _G.GetSubZoneText and K.Plain(_G.GetSubZoneText())
    local name = QX.MissingFlight(type(zone) == "string" and zone or nil, type(sub) == "string" and sub or nil)
    if name and not reminded[name] then
        reminded[name] = true
        Say("Flugpunkt hier noch nicht entdeckt: " .. name .. " – sprich mit dem Flugmeister.")
    end
end

--------------------------------------------------
-- Start und Seite
--------------------------------------------------

function QX.Enable()
    if QX.enabled then return end
    QX.enabled = true
    BuildCross() BuildRing() BuildTimer() BuildHM() BuildFeed()
    local tdp, e = _G.TooltipDataProcessor, _G.Enum and _G.Enum.TooltipDataType
    if tdp and tdp.AddTooltipPostCall and e and e.Item then
        pcall(tdp.AddTooltipPostCall, e.Item, K.Measured("Schließkassetten", OnItem))
    end
    local ev = CreateFrame("Frame")
    for _, n in ipairs({ "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "GROUP_ROSTER_UPDATE",
        "PLAYER_ROLES_ASSIGNED", "UNIT_POWER_UPDATE", "CHAT_MSG_LOOT", "TAXIMAP_OPENED",
        "ZONE_CHANGED", "ZONE_CHANGED_NEW_AREA", "PLAYER_ENTERING_WORLD",
        "UNIT_SPELLCAST_SUCCEEDED", "CHAT_MSG_MONEY" }) do
        pcall(ev.RegisterEvent, ev, n)
    end
    ev:SetScript("OnEvent", K.Measured("Helfer", function(_, event, a1, _, a3)
        if event == "UNIT_SPELLCAST_SUCCEEDED" then
            if a1 == "player" and QX.IsPickpocket(a3) then QX.ppAt = Now() end
            return
        end
        if event == "CHAT_MSG_MONEY" then
            if Get("pickpocketMsg") and Now() - QX.ppAt <= QX.PP_WINDOW and type(a1) == "string" and not K.IsSecret(a1) then
                local amount = a1:match(":%s*(.-)%.?$") or a1
                QX.PickpocketShow("Taschendiebstahl: " .. amount)
            end
            return
        end
        if event == "UNIT_POWER_UPDATE" then if hm and hm:IsShown() then QX.PowerHM(a1) end return end
        if event == "CHAT_MSG_LOOT" then
            local link, n = QX.ParseLoot(a1)
            if link then QX.PickpocketLoot(link, n) end
            if not Get("lootFeed") then return end
            if link then
                local id = tonumber(link:match("item:(%d+)"))
                local icon = id and _G.C_Item and _G.C_Item.GetItemIconByID and _G.C_Item.GetItemIconByID(id)
                QX.AddFeed(icon, link .. (n > 1 and (" ×" .. n) or ""))
            end
            return
        end
        if event == "TAXIMAP_OPENED" then QX.ReadTaxi() return end
        if event:find("^ZONE_CHANGED") then QX.CheckFlight() return end
        QX.UpdateCross() QX.UpdateRing() QX.UpdateTimer(event) QX.UpdateHM()
        if event == "PLAYER_ENTERING_WORLD" then QX.ApplyQueue() QX.CheckFlight() end
    end))
    QX.Apply()
end

function QX.Apply()
    QX.UpdateCross() QX.UpdateRing() QX.UpdateHM() QX.ApplyQueue()
    if timer and not Get("combatTimer") and not timer._unlock then timer:Hide() end
end

local function Build(B)
    B:Section("Im Kampf", "Kleine Anzeigen – alle ab Werk aus. Verschieben im Gestaltungsmodus.")
    B:Row({ type = "toggle", label = "Fadenkreuz", key = "crosshair",
            description = "Ein kleines Kreuz in der Bildmitte, nur im Kampf." },
          { type = "toggle", label = "Kampftimer", key = "combatTimer",
            description = "Wie lange der Kampf schon läuft; danach kurz die Dauer des letzten." })
    B:Row({ type = "toggle", label = "Mausring", key = "mouseRing",
            description = "Ein Ring um den Mauszeiger, damit du ihn schneller findest." },
          { type = "toggle", label = "Mausring nur im Kampf", key = "mouseRingCombat",
            disabled = function() return not K.Get(KEY, "mouseRing") end })
    B:Row({ type = "toggle", label = "Mana der Heiler", key = "healerMana",
            description = "Das Mana der Heiler deiner Gruppe als kleine Leisten." },
          { type = "slider", label = "Zauber-Warteschlange", key = "spellQueue", min = 0, max = 400, step = 10,
            format = function(v) return v == 0 and "wie im Spiel" or (v .. " ms") end,
            description = "Wie früh du den nächsten Zauber drücken darfst. „Wie im Spiel“ lässt die Einstellung des Spiels unberührt." })
    B:Section("Unterwegs")
    B:Row({ type = "toggle", label = "Beute-Feed", key = "lootFeed",
            description = "Was du bekommst, kurz mit Symbol am Bildschirmrand." },
          { type = "toggle", label = "Schließkassetten im Tooltip", key = "lockboxTip",
            description = "Welche Fertigkeit im Schlossknacken eine Kassette braucht." })
    B:Row({ type = "toggle", label = "Flugpunkte erinnern", key = "flightRemind",
            description = "Hinweis im Chat, wenn ein Flugpunkt in diesem Gebiet noch nicht entdeckt ist. Erst, nachdem du einmal eine Flugkarte geöffnet hast." },
          { type = "toggle", label = "Instanzen zählen", key = "instTracker",
            description = "Beim Betreten: wie viele neue Instanzen du in der letzten Stunde betreten hast (Grenze 10 je Konto). Beim Verlassen: wie lange. Liste: /wcui instanzen." })
    B:Row({ type = "toggle", label = "Taschendiebstahl melden", key = "pickpocketMsg",
            description = "Schurke: was du gestohlen hast, groß in Grün in der Bildschirmmitte – wo bei Fehlschlag die rote Meldung steht." },
          { type = "empty" })
    B:Note("Gruppe betrachten – Stufe und Gegenstandsstufe aller in der Gruppe: /wcui inspekt.")
end

local mod = K.Module(KEY)
if mod then
    for k, v in pairs(QX.DEFAULTS) do
        if mod.defaults[k] == nil then mod.defaults[k] = v end
    end
    mod.pages[#mod.pages + 1] = { key = "helfer", label = "Helfer", build = Build }
    local enable = mod.Enable
    mod.Enable = function(...)
        if enable then enable(...) end
        local ok, err = pcall(QX.Enable)
        if not ok then K.Report("helfer", err) end
    end
end
K.Listen(function(kind, key)
    if (kind == "active" or kind == "setting") and key == KEY and QX.enabled then QX.Apply() end
end)
