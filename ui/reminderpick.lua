--------------------------------------------------
-- WeintCodex :: Komfort - Erinnerung anklicken, Ring zur Auswahl (6.39.0.0)
--------------------------------------------------
-- Wunsch aus dem Forum: "fehlt das Gift, zeig die Gifte zur Auswahl -
-- Linksklick Haupthand, Rechtsklick Nebenhand". Allgemein fuer jede
-- Erinnerung, die etwas aus der Tasche anbietet (R.Check/R.BagBuffs setzen
-- `pick = { items, hand }`):
--   * eine Sorte: Klick auf die Zeile benutzt sie gleich;
--   * mehrere: Klick oeffnet einen Ring um den Mauszeiger (nach dem
--     Verhalten von OPie, "All rights reserved" - kein Code uebernommen),
--     ein Klick auf ein Symbol benutzt es, Esc oder Wegfahren schliesst.
--   * Waffe: links Haupthand, rechts Nebenhand ("/use item" + "/use 16|17").
--
-- Benutzen ist geschuetzt: nur ueber sichere Knoepfe (Makro), und deren
-- Werte duerfen sich im Kampf nicht aendern. Darum gibt es den Klick nur
-- ausserhalb des Kampfes; mit Kampfbeginn verschwinden Knoepfe und Ring,
-- Erinnerungen sind im Kampf ohnehin nur Anzeige. Die Knoepfe haengen an
-- UIParent, nicht an der Leiste - sonst waere die Leiste im Kampf selbst
-- geschuetzt und liesse sich nicht mehr ausblenden.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIReminderPick = {}

local RP = WeintCodex.UIReminderPick
local R  = WeintCodex.UIReminders
local K  = WeintCodex.UIKit
local C  = WeintCodex.Colors
local KEY = "reminders"

RP.SLOT = 36            -- Symbol im Ring
RP.RADIUS = 58          -- Abstand der Symbole zur Mitte
RP.MAX = 8

local lines, ring = {}, nil
local st = { open = nil }
RP.state = st

function RP.Enabled()
    return K.Get(KEY, "clickPick") ~= false
end

local function Locked()
    return (_G.InCombatLockdown and _G.InCombatLockdown()) and true or false
end

-- Makro fuer einen Gegenstand; hand: nil (benutzen), "main", "off".
function RP.Macro(id, hand)
    local m = "/use item:" .. id
    if hand == "main" then m = m .. "\n/use 16"
    elseif hand == "off" then m = m .. "\n/use 17" end
    return m
end

-- Linke/rechte Taste: bei Waffen Haupt-/Nebenhand, sonst beide benutzen.
local function Arm(b, id, weapon)
    b:SetAttribute("type1", "macro")
    b:SetAttribute("type2", "macro")
    b:SetAttribute("macrotext1", RP.Macro(id, weapon and "main" or nil))
    b:SetAttribute("macrotext2", RP.Macro(id, weapon and "off" or nil))
end

local function Disarm(b)
    b:SetAttribute("type1", nil)
    b:SetAttribute("type2", nil)
end

local function Tip(owner, pick, id)
    local tt = _G.GameTooltip
    if not tt then return end
    tt:SetOwner(owner, "ANCHOR_RIGHT")
    if id and tt.SetItemByID then tt:SetItemByID(id) end
    local weapon = pick and pick.hand ~= nil
    local g = C.textMuted or { 0.7, 0.7, 0.7 }
    if id then
        tt:AddLine(weapon and "Links: Haupthand · Rechts: Nebenhand" or "Klick: benutzen", g[1], g[2], g[3])
    else
        tt:AddLine("Klick: Auswahl öffnen", g[1], g[2], g[3])
    end
    tt:Show()
end

local function NewSecure(parent, size)
    local b = CreateFrame("Button", nil, parent, "SecureActionButtonTemplate")
    b:RegisterForClicks("AnyUp", "AnyDown")
    if size then b:SetSize(size, size) end
    b:SetFrameStrata("DIALOG")
    return b
end

--------------------------------------------------
-- Der Ring
--------------------------------------------------

local function BuildRing()
    ring = CreateFrame("Frame", "WeintCodexPickRing", UIParent)
    ring:SetSize(RP.RADIUS * 2 + RP.SLOT, RP.RADIUS * 2 + RP.SLOT)
    ring:SetFrameStrata("DIALOG")
    ring:EnableMouse(false)
    local hub = ring:CreateTexture(nil, "BACKGROUND")
    hub:SetSize(RP.RADIUS * 2 - 10, RP.RADIUS * 2 - 10)
    hub:SetPoint("CENTER")
    hub:SetTexture("Interface\\Common\\CommonMaskCircle")
    local f = WeintCodex.GameColors.kachelFill
    hub:SetVertexColor(f[1], f[2], f[3], 0.55)
    ring.hub = hub
    ring.title = K.NewText(ring, 11)
    ring.title:SetPoint("CENTER")
    ring.title:SetWidth(RP.RADIUS * 2 - 30)
    ring.slots = {}
    for i = 1, RP.MAX do
        local b = NewSecure(ring, RP.SLOT)
        b.icon = b:CreateTexture(nil, "ARTWORK")
        b.icon:SetAllPoints(b)
        b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        b.border = K.Border(b, 1, 0, 0, 0, 1, "OVERLAY")
        b.count = K.NewText(b, 11)
        b.count:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -1, 2)
        b.hl = b:CreateTexture(nil, "HIGHLIGHT")
        b.hl:SetAllPoints(b)
        local a = C.accent
        b.hl:SetColorTexture(a[1], a[2], a[3], 0.25)
        b:SetScript("OnEnter", function(self)
            local a2 = C.accent
            self.border:SetColor(a2[1], a2[2], a2[3], 1)
            local item = self._item
            if item and ring.title then ring.title:SetText(R.ItemName(item) or "") end
            Tip(self, st.pick, item)
        end)
        b:SetScript("OnLeave", function(self)
            self.border:SetColor(0, 0, 0, 1)
            if _G.GameTooltip then _G.GameTooltip:Hide() end
        end)
        -- Nach dem Benutzen schliessen (der Klick selbst laeuft sicher).
        b:HookScript("OnClick", function() RP.Close() end)
        b:Hide()
        ring.slots[i] = b
    end
    -- Wegfahren schliesst: ausserhalb des Rings, eine halbe Sekunde lang.
    ring:SetScript("OnUpdate", function(self, el)
        if self:IsMouseOver(10, -10, -10, 10) then self._away = 0 return end
        self._away = (self._away or 0) + (el or 0)
        if self._away > 0.5 then RP.Close() end
    end)
    -- Esc schliesst (wie ein Fenster des Spiels).
    if _G.UISpecialFrames then table.insert(_G.UISpecialFrames, "WeintCodexPickRing") end
    ring:SetScript("OnHide", function() st.open = nil end)
    ring:Hide()
end

local function Count(id)
    local ci = _G.C_Item
    local f = (ci and ci.GetItemCount) or _G.GetItemCount
    local ok, n = pcall(f, id)
    n = ok and K.Plain(n)
    return type(n) == "number" and n or nil
end

function RP.Open(pick)
    if Locked() or not pick or not pick.items or #pick.items == 0 then return end
    if not ring then BuildRing() end
    st.pick = pick
    local x, y = _G.GetCursorPosition()
    local s = UIParent:GetEffectiveScale()
    ring:ClearAllPoints()
    ring:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / s, y / s)
    local n = math.min(#pick.items, RP.MAX)
    local weapon = pick.hand ~= nil
    for i = 1, RP.MAX do
        local b = ring.slots[i]
        local id = pick.items[i]
        if i <= n then
            -- Oben beginnen, im Uhrzeigersinn.
            local a = math.pi / 2 - (i - 1) * 2 * math.pi / n
            b:ClearAllPoints()
            b:SetPoint("CENTER", ring, "CENTER", math.cos(a) * RP.RADIUS, math.sin(a) * RP.RADIUS)
            b._item = id
            local ci = _G.C_Item
            local icon = (ci and ci.GetItemIconByID) or _G.GetItemIcon
            local ok, tex = pcall(icon, id)
            b.icon:SetTexture(ok and K.Plain(tex) or nil)
            local c = Count(id)
            b.count:SetText(c and c > 1 and tostring(c) or "")
            Arm(b, id, weapon)
            b:Show()
        else
            b._item = nil
            Disarm(b)
            b:Hide()
        end
    end
    ring.title:SetText(weapon and "Links: Haupthand\nRechts: Nebenhand" or "Auswählen")
    ring._away = 0
    st.open = true
    ring:Show()
end

function RP.Close()
    if ring and not Locked() then ring:Hide() end
    st.open = nil
end

--------------------------------------------------
-- Knoepfe auf den Zeilen der Erinnerungen
--------------------------------------------------

local function Line(i)
    local b = lines[i]
    if b then return b end
    b = NewSecure(UIParent)
    b:SetScript("OnEnter", function(self) Tip(self, self._pick, self._single) end)
    b:SetScript("OnLeave", function() if _G.GameTooltip then _G.GameTooltip:Hide() end end)
    -- Mehrere Sorten: der sichere Klick tut nichts (kein Typ), der Haken
    -- oeffnet den Ring.
    b:HookScript("OnClick", function(self)
        if not self._single and self._pick then RP.Open(self._pick) end
    end)
    b:Hide()
    lines[i] = b
    return b
end

-- Von R.UpdateBanner: Knoepfe passend zu den sichtbaren Zeilen.
function RP.Sync(banner, list, n)
    if Locked() then return end
    local on = RP.Enabled() and not banner._unlock and n > 0
    for i = 1, math.max(#lines, n) do
        local item = list[i]
        local pick = on and i <= n and item and item.pick
        if pick and pick.items and #pick.items > 0 then
            local b = Line(i)
            local row = banner.lines[i]
            b:ClearAllPoints()
            b:SetPoint("TOPLEFT", row.icon, "TOPLEFT", -4, 3)
            b:SetPoint("BOTTOMLEFT", row.icon, "BOTTOMLEFT", -4, -3)
            b:SetPoint("RIGHT", banner, "RIGHT", 0, 0)
            b._pick = pick
            if #pick.items == 1 then
                b._single = pick.items[1]
                Arm(b, pick.items[1], pick.hand ~= nil)
            else
                b._single = nil
                Disarm(b)
            end
            b:Show()
        elseif lines[i] then
            lines[i]._pick, lines[i]._single = nil, nil
            Disarm(lines[i])
            lines[i]:Hide()
        end
    end
end

function RP.HideAll()
    if Locked() then return end
    for _, b in ipairs(lines) do Disarm(b) b:Hide() end
    if ring then ring:Hide() end
end

R.OnBanner = function(banner, list, n)
    if not banner:IsShown() and n == 0 then RP.HideAll() return end
    RP.Sync(banner, list, n)
end

-- Vor dem Kampf (PLAYER_REGEN_DISABLED kommt vor der Sperre): alles weg.
local ev = CreateFrame("Frame")
pcall(ev.RegisterEvent, ev, "PLAYER_REGEN_DISABLED")
ev:SetScript("OnEvent", function()
    for _, b in ipairs(lines) do Disarm(b) b:Hide() end
    if ring then ring:Hide() end
end)

local mod = K.Module(KEY)
if mod then
    if mod.defaults.clickPick == nil then mod.defaults.clickPick = true end
end
