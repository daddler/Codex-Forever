--------------------------------------------------
-- WeintCodex :: Oberflaeche - Bank nach Kategorien
--------------------------------------------------
-- Seit 6.126.0.0 (Wunsch: "die persoenliche Bank fehlt noch"). Wie
-- ui/guildbankcats.lua: neben dem Fenster der Bank ein eigenes Fenster mit
-- ALLEM in der Bank (Hauptfach und Bankfaecher bzw. -taschen), nach den
-- Kategorien der Taschen. Rechtsklick nimmt in die Taschen (Benutzen bei
-- offener Bank, UseContainerItem), Linksklick hebt auf
-- (PickupContainerItem); Rechtsklick auf eine Ueberschrift nimmt die ganze
-- Kategorie. Die Bank des Spiels bleibt (Faecher kaufen, Geld). Nie im Kampf.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIBankCats = {}

local GB = WeintCodex.UIBankCats
local K  = WeintCodex.UIKit
local C  = WeintCodex.Colors
local F  = WeintCodex.Fonts
local BG = WeintCodex.UIBags

GB.SIZE, GB.GAP, GB.COLS = 34, 3, 10
local win, cells, heads = nil, {}, {}

local function On() return K.IsActive("bags") and K.Get("bags", "categories") and K.Get("bags", "bankCats") end

-- Die Behaelter der Bank: neue Clients haben Bankfaecher
-- (Enum.BagIndex.CharacterBankTab_1..), alte das Hauptfach (-1) und
-- Banktaschen hinter den eigenen Taschen. Was 0 Plaetze hat, faellt weg.
function GB.BagIDs()
    local ids = {}
    local E = _G.Enum and _G.Enum.BagIndex
    if E and E.CharacterBankTab_1 then
        for i = 1, 8 do
            local id = E["CharacterBankTab_" .. i]
            if id then ids[#ids + 1] = id end
        end
    else
        ids[1] = _G.BANK_CONTAINER or -1
        local first = (_G.NUM_BAG_SLOTS or 4) + 1
        for b = first, first + (_G.NUM_BANKBAGSLOTS or 6) - 1 do ids[#ids + 1] = b end
    end
    return ids
end

-- { bag, slot, id, count, quality, icon } je belegtem Platz der Bank.
function GB.Items()
    local out = {}
    local cc = _G.C_Container
    if not (cc and cc.GetContainerNumSlots and cc.GetContainerItemInfo) then return out end
    for _, bag in ipairs(GB.BagIDs()) do
        local okN, n = pcall(cc.GetContainerNumSlots, bag)
        n = okN and K.Plain(n) or 0
        for slot = 1, (type(n) == "number" and n or 0) do
            local ok, info = pcall(cc.GetContainerItemInfo, bag, slot)
            if ok and type(info) == "table" and K.Plain(info.iconFileID) then
                out[#out + 1] = { bag = bag, slot = slot, id = K.Plain(info.itemID), icon = K.Plain(info.iconFileID),
                                  count = K.Plain(info.stackCount) or 1, quality = K.Plain(info.quality) }
            end
        end
    end
    return out
end

-- Ueber die Warteschlange der Taschen (BG.Transfer): ein Gegenstand je
-- Schritt - auf einmal verwarf das Spiel die meisten (6.126.1.0).
function GB.Take(list)
    return BG.Transfer(list)
end

local function Cell(i)
    local b = cells[i]
    if b then return b end
    b = CreateFrame("Button", nil, win)
    b:SetSize(GB.SIZE, GB.SIZE)
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetAllPoints(b)
    if b.icon.SetTexCoord then b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) end
    b.edge = K.Border(b, 1, 0, 0, 0, 1, "OVERLAY")
    b.count = K.NewText(b, 11)
    b.count:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -1, 1)
    if b.RegisterForClicks then b:RegisterForClicks("LeftButtonUp", "RightButtonUp") end
    b:SetScript("OnClick", function(self, button)
        if K.InCombat() or not self.e then return end
        if button == "RightButton" then GB.Take({ self.e })
        else
            local cc = _G.C_Container
            if cc and cc.PickupContainerItem then pcall(cc.PickupContainerItem, self.e.bag, self.e.slot) end
        end
    end)
    b:SetScript("OnEnter", function(self)
        local tt = _G.GameTooltip
        if not (tt and self.e) then return end
        tt:SetOwner(self, "ANCHOR_RIGHT")
        if tt.SetBagItem then pcall(tt.SetBagItem, tt, self.e.bag, self.e.slot) end
        tt:AddLine("Rechtsklick: in die Taschen", 0.4, 1, 0.4)
        tt:Show()
    end)
    b:SetScript("OnLeave", function() if _G.GameTooltip then _G.GameTooltip:Hide() end end)
    cells[i] = b
    return b
end

local function Head(i)
    local h = heads[i]
    if h then return h end
    h = CreateFrame("Button", nil, win)
    h.text = K.NewText(h)
    h.text:SetFont(F.sans, 11, "")
    h.text:SetPoint("LEFT", h, "LEFT", 0, 0)
    if h.RegisterForClicks then h:RegisterForClicks("RightButtonUp") end
    h:SetScript("OnClick", function(self) GB.Take(self.items) end)
    h:SetScript("OnEnter", function(self)
        local tt = _G.GameTooltip
        tt:SetOwner(self, "ANCHOR_TOP")
        tt:SetText(self.label or "", 1, 1, 1)
        tt:AddLine("Rechtsklick: alles in die Taschen", 0.4, 1, 0.4)
        tt:Show()
    end)
    h:SetScript("OnLeave", function() if _G.GameTooltip then _G.GameTooltip:Hide() end end)
    heads[i] = h
    return h
end

local function Build()
    win = CreateFrame("Frame", "WeintCodexBankCats", UIParent)
    win:SetFrameStrata("HIGH")
    win:SetClampedToScreen(true)
    win:EnableMouse(true)
    win.kachel = K.Kachel(win, { shadow = 8 })
    win.title = K.NewText(win, 13)
    win.title:SetPoint("TOPLEFT", win, "TOPLEFT", 12, -10)
    win.title:SetTextColor(unpack(C.textBright))
    win:Hide()
end

-- Neu zeichnen. Gibt die Bloecke zurueck ({ key, n }) - fuer den Test.
function GB.Refresh()
    local gb = _G.BankFrame
    local open = type(gb) == "table" and gb.IsShown and K.Bool(gb:IsShown(), false)
    if not (On() and open) then
        if win then win:Hide() end
        return nil
    end
    if not win then Build() end
    local byCat = {}
    for _, e in ipairs(GB.Items()) do
        local k = type(e.id) == "number" and BG.CategoryOfItem(e.id, e.quality, false) or "misc"
        byCat[k] = byCat[k] or {}
        table.insert(byCat[k], e)
    end
    local cell = GB.SIZE + GB.GAP
    local x, y, rowH, ci, hi = 0, 34, 0, 0, 0
    local blocks = {}
    for _, c in ipairs(BG.AllCategories()) do
        local items = byCat[c.key]
        if items and #items > 0 then
            local w = math.min(#items, GB.COLS)
            local rows = math.ceil(#items / w)
            if x > 0 and x + w > GB.COLS then x, y, rowH = 0, y + rowH, 0 end
            hi = hi + 1
            local h = Head(hi)
            h:ClearAllPoints()
            h:SetPoint("TOPLEFT", win, "TOPLEFT", 12 + x * cell, -y)
            h:SetSize(math.max(w * cell - GB.GAP, 40), 16)
            h.label, h.items = c.label, items
            h.text:SetText(c.label)
            h.text:SetTextColor(unpack(C.textMuted))
            h:Show()
            for i, e in ipairs(items) do
                ci = ci + 1
                local b = Cell(ci)
                b.e = e
                b.icon:SetTexture(e.icon)
                b.count:SetText(e.count and e.count > 1 and tostring(e.count) or "")
                b:ClearAllPoints()
                b:SetPoint("TOPLEFT", win, "TOPLEFT", 12 + (x + (i - 1) % w) * cell, -(y + 16 + math.floor((i - 1) / w) * cell))
                b:Show()
            end
            blocks[#blocks + 1] = { key = c.key, n = #items }
            rowH = math.max(rowH, 16 + rows * cell + 10)
            x = x + w + 1
            if x >= GB.COLS then x, y, rowH = 0, y + rowH, 0 end
        end
    end
    for i = ci + 1, #cells do cells[i]:Hide() cells[i].e = nil end
    for i = hi + 1, #heads do heads[i]:Hide() end
    win.title:SetText("Bank  ·  nach Kategorien")
    win:SetSize(24 + GB.COLS * cell - GB.GAP, math.max(80, y + rowH + 4))
    win:ClearAllPoints()
    win:SetPoint("TOPLEFT", gb, "TOPRIGHT", 8, 0)
    win:Show()
    GB.blocks = blocks
    return blocks
end

local ev = CreateFrame("Frame")
for _, e in ipairs({ "BANKFRAME_OPENED", "BANKFRAME_CLOSED", "BAG_UPDATE_DELAYED", "PLAYERBANKSLOTS_CHANGED",
    "PLAYER_INTERACTION_MANAGER_FRAME_SHOW", "PLAYER_INTERACTION_MANAGER_FRAME_HIDE" }) do
    pcall(ev.RegisterEvent, ev, e)
end
ev:SetScript("OnEvent", function()
    if _G.C_Timer and _G.C_Timer.After then
        _G.C_Timer.After(0, function() pcall(GB.Refresh) end)
    else
        pcall(GB.Refresh)
    end
end)
