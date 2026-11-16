--------------------------------------------------
-- WeintCodex :: Oberflaeche - Ausruestungssets und Schmuckleiste
--------------------------------------------------
-- 1.0.7.0 (Wunsch nach dem Vergleich mit Naowh Forever "Gear & Trinkets",
-- Verhalten nachgebaut, eigener Code - dort "All Rights Reserved").
--
-- SETS: die des Ausruestungsmanagers des Spiels (C_EquipmentSet) - also
-- dieselben, die das Charakterfenster zeigt. Klick legt an; im Kampf kann
-- niemand Ruestung wechseln, dann wartet der Wunsch bis zum Kampfende.
-- "+" speichert, was du traegst, als neues Set; Rechtsklick auf ein Set:
-- mit dem Getragenen ueberschreiben oder loeschen.
--
-- SCHMUCK: zwei sichere Knoepfe fuer Platz 13 und 14 (benutzen per Klick,
-- auch im Kampf), mit Abklingzeit. Rechtsklick ausserhalb des Kampfes:
-- anderen Schmuck aus den Taschen anlegen.
--
-- Schalter `gearBar`/`trinketBar` auf der Seite des Abklingzeitmanagers
-- (Erweitert), je Charakter. Verschieben im Gestaltungsmodus.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIGearSets = {}

local GS = WeintCodex.UIGearSets
local K = WeintCodex.UIKit
local C = WeintCodex.Colors

GS.SIZE = 30
GS.GAP = 4
GS.MAX = 10
GS.TRINKETS = { 13, 14 }
GS.EMPTY = 134400

local function Opt(k)
    local OC = WeintCodex.UIOwnCooldowns
    return OC and OC.Get and OC.Get(k) and true or false
end
local function Say(text) print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " " .. text) end
local function ES() return _G.C_EquipmentSet end

-- { {id, name, icon, equipped}, ... } oder leer.
function GS.Sets()
    local out = {}
    local es = ES()
    if not (es and es.GetEquipmentSetIDs and es.GetEquipmentSetInfo) then return out end
    local ok, ids = pcall(es.GetEquipmentSetIDs)
    if not (ok and type(ids) == "table") then return out end
    for _, id in ipairs(ids) do
        local ok2, name, icon, _, equipped = pcall(es.GetEquipmentSetInfo, id)
        if ok2 and type(name) == "string" then
            out[#out + 1] = { id = id, name = name, icon = icon, equipped = equipped and true or false }
        end
    end
    return out
end

GS.pending = nil
function GS.Use(id)
    local es = ES()
    if not (es and es.UseEquipmentSet) then return false end
    if K.InCombat() then
        GS.pending = id
        Say("Im Kampf lässt sich keine Rüstung wechseln – das Set kommt nach dem Kampf.")
        return "later"
    end
    GS.pending = nil
    return pcall(es.UseEquipmentSet, id) and true or false
end

function GS.SaveNew(name)
    local es = ES()
    name = type(name) == "string" and name:gsub("^%s+", ""):gsub("%s+$", "") or ""
    if name == "" or not (es and es.CreateEquipmentSet) then return false end
    local icon = _G.GetInventoryItemTexture and _G.GetInventoryItemTexture("player", 5) or GS.EMPTY
    return pcall(es.CreateEquipmentSet, name, icon) and true or false
end

function GS.Overwrite(id)
    local es = ES()
    if es and es.SaveEquipmentSet and not K.InCombat() then pcall(es.SaveEquipmentSet, id) end
end
function GS.Delete(id)
    local es = ES()
    if es and es.DeleteEquipmentSet and not K.InCombat() then pcall(es.DeleteEquipmentSet, id) end
end

--------------------------------------------------
-- Leiste der Sets
--------------------------------------------------

local gearBar
local setButtons, trinketButtons = {}, {}
local function SetButton(i)
    local b = CreateFrame("Button", nil, gearBar)
    b:SetSize(GS.SIZE, GS.SIZE)
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetAllPoints(b)
    b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    b.edge = K.Border(b, 1, 0, 0, 0, 1, "BORDER")
    local a = C.accent
    b.on = K.Border(b, 2, a[1], a[2], a[3], 1, "OVERLAY")
    b.on:SetShown(false)
    b.plus = K.NewText(b, 18)
    b.plus:SetPoint("CENTER", b, "CENTER", 0, 0)
    b.plus:SetText("+")
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    b:SetScript("OnClick", function(self, button)
        if self.add then GS.AskName() return end
        if button == "RightButton" then GS.SetMenu(self, self.setID, self.setName) return end
        GS.Use(self.setID)
    end)
    b:SetScript("OnEnter", function(self)
        if not _G.GameTooltip then return end
        _G.GameTooltip:SetOwner(self, "ANCHOR_TOP")
        _G.GameTooltip:SetText(self.add and "Neues Set aus dem, was du trägst" or (self.setName or ""))
        if not self.add then _G.GameTooltip:AddLine("Klick: anlegen · Rechtsklick: speichern oder löschen", 0.7, 0.7, 0.7) end
        _G.GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() if _G.GameTooltip then _G.GameTooltip:Hide() end end)
    return b
end

function GS.SetMenu(owner, id, name)
    local MU = _G.MenuUtil
    if not (MU and MU.CreateContextMenu) then return end
    MU.CreateContextMenu(owner, function(_, root)
        if root.CreateTitle then root:CreateTitle(name or "Set") end
        root:CreateButton("Mit dem Getragenen überschreiben", function() GS.Overwrite(id) GS.Update() end)
        root:CreateButton("Löschen", function() GS.Delete(id) GS.Update() end)
    end)
end

function GS.AskName()
    if K.InCombat() then Say("Nach dem Kampf.") return end
    local SP = _G.StaticPopupDialogs
    if not (SP and _G.StaticPopup_Show) then return end
    SP.WEINTCODEX_GEARSET = SP.WEINTCODEX_GEARSET or {
        text = "Name des neuen Sets:", button1 = "Speichern", button2 = "Abbrechen",
        hasEditBox = true, timeout = 0, whileDead = true, hideOnEscape = true,
        OnAccept = function(self)
            local eb = self.editBox or (self.GetEditBox and self:GetEditBox())
            local text = eb and eb:GetText()
            if not GS.SaveNew(text) then Say("Set nicht gespeichert – Name leer oder schon vergeben?") end
            GS.Update()
        end,
    }
    _G.StaticPopup_Show("WEINTCODEX_GEARSET")
end

function GS.Update()
    if not gearBar then return end
    local show = Opt("gearBar") or gearBar._unlock
    local sets = show and GS.Sets() or {}
    local n = math.min(#sets, GS.MAX)
    for i = 1, n + 1 do
        local b = setButtons[i] or SetButton(i)
        setButtons[i] = b
        b:ClearAllPoints()
        b:SetPoint("LEFT", gearBar, "LEFT", (i - 1) * (GS.SIZE + GS.GAP), 0)
        local s = sets[i]
        if s then
            b.add, b.setID, b.setName = nil, s.id, s.name
            b.icon:SetTexture(s.icon or GS.EMPTY)
            b.icon:SetDesaturated(false)
            b.icon:SetAlpha(1)
            b.plus:Hide()
            b.on:SetShown(s.equipped)
        else
            b.add, b.setID, b.setName = true, nil, nil
            -- Kein geratener Texturpfad: ein dunkles Feld mit "+".
            local d = C.surface3 or C.bgPanel
            b.icon:SetColorTexture(d[1], d[2], d[3], 1)
            b.plus:Show()
            b.on:SetShown(false)
        end
        b:SetShown(show and true or false)
    end
    for i = n + 2, #setButtons do setButtons[i]:Hide() end
    gearBar:SetSize(math.max(GS.SIZE, (n + 1) * (GS.SIZE + GS.GAP) - GS.GAP), GS.SIZE)
end

--------------------------------------------------
-- Schmuckleiste
--------------------------------------------------

local trinketBar
local function TrinketButton(slot, i)
    local b = CreateFrame("Button", "WeintCodexTrinket" .. slot, trinketBar, "SecureActionButtonTemplate")
    b:SetSize(GS.SIZE + 6, GS.SIZE + 6)
    b:SetPoint("LEFT", trinketBar, "LEFT", (i - 1) * (GS.SIZE + 6 + GS.GAP), 0)
    b:RegisterForClicks("AnyUp", "AnyDown")
    b:SetAttribute("type1", "item")
    b:SetAttribute("item1", tostring(slot))
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetAllPoints(b)
    b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    K.Border(b, 1, 0, 0, 0, 1, "OVERLAY")
    b.cd = CreateFrame("Cooldown", nil, b, "CooldownFrameTemplate")
    b.cd:SetAllPoints(b)
    b.slot = slot
    b:HookScript("OnClick", function(self, button)
        if button == "RightButton" then GS.TrinketMenu(self, self.slot) end
    end)
    b:SetScript("OnEnter", function(self)
        if not _G.GameTooltip then return end
        _G.GameTooltip:SetOwner(self, "ANCHOR_TOP")
        _G.GameTooltip:SetInventoryItem("player", self.slot)
        _G.GameTooltip:AddLine("Rechtsklick: anderen Schmuck anlegen", 0.7, 0.7, 0.7)
        _G.GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() if _G.GameTooltip then _G.GameTooltip:Hide() end end)
    return b
end

-- Schmuck in den Taschen: { {link, icon, name}, ... }
function GS.BagTrinkets()
    local out = {}
    local ci = _G.C_Container
    if not (ci and ci.GetContainerNumSlots and ci.GetContainerItemInfo) then return out end
    for bag = 0, 4 do
        local ok, n = pcall(ci.GetContainerNumSlots, bag)
        for slot = 1, (ok and tonumber(n) or 0) do
            local ok2, info = pcall(ci.GetContainerItemInfo, bag, slot)
            if ok2 and type(info) == "table" and info.hyperlink then
                local loc = _G.C_Item and _G.C_Item.GetItemInventoryTypeByID and _G.C_Item.GetItemInventoryTypeByID(info.itemID)
                local trinket = (_G.Enum and _G.Enum.InventoryType and loc == _G.Enum.InventoryType.IndexTrinketType)
                if not trinket and _G.GetItemInfoInstant then
                    local _, _, _, equip = _G.GetItemInfoInstant(info.itemID)
                    trinket = equip == "INVTYPE_TRINKET"
                end
                if trinket then out[#out + 1] = { link = info.hyperlink, icon = info.iconFileID } end
            end
        end
    end
    return out
end

function GS.TrinketMenu(owner, slot)
    if K.InCombat() then return end
    local MU = _G.MenuUtil
    if not (MU and MU.CreateContextMenu) then return end
    local list = GS.BagTrinkets()
    MU.CreateContextMenu(owner, function(_, root)
        if root.CreateTitle then root:CreateTitle(slot == 13 and "Oberer Schmuck" or "Unterer Schmuck") end
        if #list == 0 then root:CreateButton("Kein Schmuck in den Taschen", function() end) return end
        for _, t in ipairs(list) do
            local link = t.link
            root:CreateButton(link, function()
                if not K.InCombat() and _G.EquipItemByName then pcall(_G.EquipItemByName, link, slot) end
            end)
        end
    end)
end

function GS.UpdateTrinkets()
    if not trinketBar then return end
    local show = Opt("trinketBar") or trinketBar._unlock
    trinketBar:SetAlpha(show and 1 or 0)
    -- Sichere Knoepfe: zeigen/verbergen nur ausserhalb des Kampfes.
    if not K.InCombat() then trinketBar:SetShown(show and true or false) end
    for _, b in ipairs(trinketButtons) do
        local tex = _G.GetInventoryItemTexture and _G.GetInventoryItemTexture("player", b.slot)
        b.icon:SetTexture(tex or GS.EMPTY)
        b.icon:SetDesaturated(not tex)
        if _G.GetInventoryItemCooldown then
            local ok, st, du, en = pcall(_G.GetInventoryItemCooldown, "player", b.slot)
            if ok then pcall(b.cd.SetCooldown, b.cd, st, du, en) end
        end
    end
end

--------------------------------------------------
-- Start
--------------------------------------------------

function GS.Enable()
    if gearBar then return end
    gearBar = CreateFrame("Frame", "WeintCodexGearBar", UIParent)
    gearBar:SetSize(GS.SIZE, GS.SIZE)
    gearBar.WCShowForUnlock = function(self, on) self._unlock = on and true or nil GS.Update() end
    K.RegisterMover(gearBar, "gearbar", "Ausrüstungssets", K.Layout("gearbar"))
    trinketBar = CreateFrame("Frame", "WeintCodexTrinketBar", UIParent)
    trinketBar:SetSize(2 * (GS.SIZE + 6) + GS.GAP, GS.SIZE + 6)
    for i, slot in ipairs(GS.TRINKETS) do trinketButtons[i] = TrinketButton(slot, i) end
    trinketBar.WCShowForUnlock = function(self, on) self._unlock = on and true or nil GS.UpdateTrinkets() end
    K.RegisterMover(trinketBar, "trinketbar", "Schmuckleiste", K.Layout("trinketbar"), { secure = true })
    local ev = CreateFrame("Frame")
    for _, e in ipairs({ "EQUIPMENT_SETS_CHANGED", "PLAYER_EQUIPMENT_CHANGED", "PLAYER_REGEN_ENABLED",
        "BAG_UPDATE_COOLDOWN", "PLAYER_ENTERING_WORLD", "EQUIPMENT_SWAP_FINISHED" }) do
        pcall(ev.RegisterEvent, ev, e)
    end
    ev:SetScript("OnEvent", K.Measured("Ausrüstungssets", function(_, event)
        if event == "PLAYER_REGEN_ENABLED" and GS.pending then GS.Use(GS.pending) end
        GS.Update()
        GS.UpdateTrinkets()
    end))
    GS.Update()
    GS.UpdateTrinkets()
end

do
    local m = K.Module("reminders")
    if m then
        local enable = m.Enable
        m.Enable = function(...)
            if enable then enable(...) end
            local ok, err = pcall(GS.Enable)
            if not ok then K.Report("ausrüstungssets", err) end
        end
    end
end
