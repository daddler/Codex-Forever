--------------------------------------------------
-- WeintCodex :: Oberflaeche - Verbrauchsleiste
--------------------------------------------------
-- 1.0.7.0 (Wunsch nach dem Vergleich mit Naowh Forever "Consumable Bar",
-- Verhalten nachgebaut, eigener Code - dort "All Rights Reserved").
--
-- Was in den Taschen liegt und das Spiel als Verbrauchsgut fuehrt (Klasse 0:
-- Tranke, Elixiere, Flaeschchen, Rollen, Essen und Trinken, Verbaende),
-- eine Taste je Gegenstand, mit Anzahl und Abklingzeit. Sichere Knoepfe:
-- benutzen geht auch im Kampf; welche Knoepfe es gibt und wo sie stehen,
-- aendert sich nur ausserhalb des Kampfes (danach sofort). Die Anzahl und
-- die Abklingzeit laufen auch im Kampf weiter.
--
-- Schalter `consumables` auf der Seite des Abklingzeitmanagers (Erweitert).
-- Verschieben im Gestaltungsmodus ("Verbrauchsleiste").
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIConsumables = {}

local CB = WeintCodex.UIConsumables
local K = WeintCodex.UIKit

CB.SIZE, CB.GAP, CB.MAX = 30, 3, 12
-- Unterklassen von "Verbrauchsgut" (Classic): Reihenfolge auf der Leiste.
CB.ORDER = { [1] = 1, [2] = 2, [3] = 3, [5] = 4, [7] = 5, [4] = 6 }
CB.SUBCLASS_TEXT = { [1] = "Trank", [2] = "Elixier", [3] = "Fläschchen", [4] = "Rolle", [5] = "Essen und Trinken", [7] = "Verband" }

local function On()
    local OC = WeintCodex.UIOwnCooldowns
    return OC and OC.Get and OC.Get("consumables") and true or false
end

-- Unterklasse eines Verbrauchsguts oder nil.
function CB.Kind(itemID)
    if not (_G.GetItemInfoInstant and type(itemID) == "number") then return nil end
    local ok, _, _, _, _, _, classID, subID = pcall(_G.GetItemInfoInstant, itemID)
    if not ok or classID ~= 0 then return nil end
    return CB.ORDER[subID] and subID or nil
end

-- { {id, kind, icon}, ... } ohne Doppelte, sortiert nach Art, dann Nummer.
local found, seen = {}, {}
function CB.Scan()
    for i = #found, 1, -1 do found[i] = nil end
    for k in pairs(seen) do seen[k] = nil end
    local ci = _G.C_Container
    if not (ci and ci.GetContainerNumSlots and ci.GetContainerItemInfo) then return found end
    for bag = 0, 4 do
        local ok, n = pcall(ci.GetContainerNumSlots, bag)
        for slot = 1, (ok and tonumber(n) or 0) do
            local ok2, info = pcall(ci.GetContainerItemInfo, bag, slot)
            local id = ok2 and type(info) == "table" and info.itemID
            if id and not seen[id] then
                local kind = CB.Kind(id)
                if kind then
                    seen[id] = true
                    found[#found + 1] = { id = id, kind = kind, icon = info.iconFileID }
                end
            end
        end
    end
    table.sort(found, function(a, b)
        if a.kind ~= b.kind then return CB.ORDER[a.kind] < CB.ORDER[b.kind] end
        return a.id < b.id
    end)
    return found
end

local bar
local buttons = {}

local function Button(i)
    local b = CreateFrame("Button", "WeintCodexConsumable" .. i, bar, "SecureActionButtonTemplate")
    b:SetSize(CB.SIZE, CB.SIZE)
    b:RegisterForClicks("AnyUp", "AnyDown")
    b:SetAttribute("type", "item")
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetAllPoints(b)
    b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    K.Border(b, 1, 0, 0, 0, 1, "OVERLAY")
    b.cd = CreateFrame("Cooldown", nil, b, "CooldownFrameTemplate")
    b.cd:SetAllPoints(b)
    local top = CreateFrame("Frame", nil, b)
    top:SetAllPoints(b)
    top:SetFrameLevel((b.cd:GetFrameLevel() or 1) + 2)
    b.count = K.NewText(top, 11)
    b.count:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -1, 1)
    b.count:SetShadowOffset(1, -1)
    b:SetScript("OnEnter", function(self)
        if not (_G.GameTooltip and self.itemID) then return end
        _G.GameTooltip:SetOwner(self, "ANCHOR_TOP")
        _G.GameTooltip:SetItemByID(self.itemID)
        _G.GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() if _G.GameTooltip then _G.GameTooltip:Hide() end end)
    buttons[i] = b
    return b
end

-- Anzahl und Abklingzeit: auch im Kampf.
function CB.Paint()
    for _, b in ipairs(buttons) do
        if b.itemID then
            local n = _G.C_Item and _G.C_Item.GetItemCount and K.Plain(_G.C_Item.GetItemCount(b.itemID)) or nil
            b.count:SetText(type(n) == "number" and n > 1 and tostring(n) or "")
            b.icon:SetDesaturated(type(n) == "number" and n == 0)
            local ci = _G.C_Container
            if ci and ci.GetItemCooldown then
                local ok, st, du, en = pcall(ci.GetItemCooldown, b.itemID)
                if ok then pcall(b.cd.SetCooldown, b.cd, st, du, en) end
            end
        end
    end
end

-- Knoepfe neu verteilen: nur ausserhalb des Kampfes.
function CB.Layout()
    if not bar then return end
    if K.InCombat() then CB.dirty = true return end
    CB.dirty = nil
    local show = On() or bar._unlock
    local list = show and CB.Scan() or {}
    local n = math.min(#list, CB.MAX)
    for i = 1, n do
        local b = buttons[i] or Button(i)
        local e = list[i]
        b.itemID = e.id
        b:SetAttribute("item", "item:" .. e.id)
        b.icon:SetTexture(e.icon or 134400)
        b:ClearAllPoints()
        b:SetPoint("LEFT", bar, "LEFT", (i - 1) * (CB.SIZE + CB.GAP), 0)
        b:Show()
    end
    for i = n + 1, #buttons do buttons[i].itemID = nil buttons[i]:Hide() end
    bar:SetSize(math.max(CB.SIZE, n * (CB.SIZE + CB.GAP) - CB.GAP), CB.SIZE)
    bar:SetShown(show and true or false)
    CB.Paint()
end

function CB.Enable()
    if bar then return end
    bar = CreateFrame("Frame", "WeintCodexConsumableBar", UIParent)
    bar:SetSize(CB.SIZE, CB.SIZE)
    bar.WCShowForUnlock = function(self, on) self._unlock = on and true or nil CB.Layout() end
    K.RegisterMover(bar, "consumables", "Verbrauchsleiste", K.Layout("consumables"))
    local ev = CreateFrame("Frame")
    for _, e in ipairs({ "BAG_UPDATE_DELAYED", "PLAYER_REGEN_ENABLED", "BAG_UPDATE_COOLDOWN",
        "PLAYER_ENTERING_WORLD" }) do
        pcall(ev.RegisterEvent, ev, e)
    end
    ev:SetScript("OnEvent", K.Measured("Verbrauchsleiste", function(_, event)
        if event == "BAG_UPDATE_COOLDOWN" then CB.Paint() return end
        if event == "PLAYER_REGEN_ENABLED" and not CB.dirty then CB.Paint() return end
        CB.Layout()
        if K.InCombat() then CB.Paint() end
    end))
    CB.Layout()
end

do
    local m = K.Module("reminders")
    if m then
        local enable = m.Enable
        m.Enable = function(...)
            if enable then enable(...) end
            local ok, err = pcall(CB.Enable)
            if not ok then K.Report("verbrauchsleiste", err) end
        end
    end
end
