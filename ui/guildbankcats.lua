--------------------------------------------------
-- WeintCodex :: Oberflaeche - Gildenbank nach Kategorien
--------------------------------------------------
-- Seit 6.125.0.0 (Wunsch: "die Gildenbank genau so wie die Taschen").
-- Neben dem Fenster der Gildenbank ein eigenes Fenster mit dem OFFENEN
-- Fach, nach denselben Kategorien und in derselben Reihenfolge wie die
-- Taschen (ui/bags.lua: BG.AllCategories, BG.CategoryOfItem).
--
-- Die Gildenbank selbst bleibt die des Spiels - Faecher, Rechte, Protokoll,
-- Geld. Hier nur zeigen und nehmen: Rechtsklick nimmt den Gegenstand in die
-- Taschen (AutoStoreGuildBankItem, im Klick), Linksklick hebt ihn auf
-- (PickupGuildBankItem) - ablegen wie gewohnt. Rechtsklick auf eine
-- Ueberschrift nimmt alles aus der Kategorie, soweit die Rechte reichen;
-- was das Spiel ablehnt, bleibt liegen. Nie im Kampf.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIGuildBankCats = {}

local GB = WeintCodex.UIGuildBankCats
local K  = WeintCodex.UIKit
local C  = WeintCodex.Colors
local F  = WeintCodex.Fonts
local BG = WeintCodex.UIBags

GB.SLOTS = 98
GB.SIZE, GB.GAP, GB.COLS = 34, 3, 10
local win, cells, heads = nil, {}, {}

local function On() return K.IsActive("bags") and K.Get("bags", "categories") and K.Get("bags", "guildCats") end

local function Tab()
    local f = _G.GetCurrentGuildBankTab
    return f and K.Plain(f()) or nil
end

-- { slot, id, count, quality, icon } je belegtem Platz des offenen Fachs.
function GB.Items(tab)
    local out = {}
    tab = tab or Tab()
    if type(tab) ~= "number" or not _G.GetGuildBankItemInfo then return out end
    for slot = 1, GB.SLOTS do
        local ok, icon, count, _, _, quality = pcall(_G.GetGuildBankItemInfo, tab, slot)
        icon = ok and K.Plain(icon) or nil
        if icon then
            local link = _G.GetGuildBankItemLink and K.Plain(_G.GetGuildBankItemLink(tab, slot))
            local id = type(link) == "string" and tonumber(link:match("item:(%d+)")) or nil
            out[#out + 1] = { tab = tab, slot = slot, id = id, icon = icon,
                              count = K.Plain(count) or 1, quality = K.Plain(quality) }
        end
    end
    return out
end

function GB.Take(list)
    if K.InCombat() or not _G.AutoStoreGuildBankItem then return 0 end
    local n = 0
    for _, e in ipairs(list or {}) do
        if pcall(_G.AutoStoreGuildBankItem, e.tab, e.slot) then n = n + 1 end
    end
    return n
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
        elseif _G.PickupGuildBankItem then pcall(_G.PickupGuildBankItem, self.e.tab, self.e.slot) end
    end)
    b:SetScript("OnEnter", function(self)
        local tt = _G.GameTooltip
        if not (tt and self.e) then return end
        tt:SetOwner(self, "ANCHOR_RIGHT")
        if tt.SetGuildBankItem then pcall(tt.SetGuildBankItem, tt, self.e.tab, self.e.slot) end
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
    win = CreateFrame("Frame", "WeintCodexGuildBankCats", UIParent)
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
    local gb = _G.GuildBankFrame
    local open = type(gb) == "table" and gb.IsShown and K.Bool(gb:IsShown(), false)
    if not (On() and open) then
        if win then win:Hide() end
        return nil
    end
    if not win then Build() end
    local tab = Tab()
    local byCat = {}
    for _, e in ipairs(GB.Items(tab)) do
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
    local name = _G.GetGuildBankTabInfo and K.Plain((_G.GetGuildBankTabInfo(tab or 1)))
    win.title:SetText((type(name) == "string" and name ~= "" and name or "Gildenbank") .. "  ·  nach Kategorien")
    win:SetSize(24 + GB.COLS * cell - GB.GAP, math.max(80, y + rowH + 4))
    win:ClearAllPoints()
    win:SetPoint("TOPLEFT", gb, "TOPRIGHT", 8, 0)
    win:Show()
    GB.blocks = blocks
    return blocks
end

local ev = CreateFrame("Frame")
for _, e in ipairs({ "GUILDBANKFRAME_OPENED", "GUILDBANKFRAME_CLOSED", "GUILDBANKBAGSLOTS_CHANGED",
    "GUILDBANK_UPDATE_TABS", "PLAYER_INTERACTION_MANAGER_FRAME_SHOW", "PLAYER_INTERACTION_MANAGER_FRAME_HIDE" }) do
    pcall(ev.RegisterEvent, ev, e)
end
ev:SetScript("OnEvent", function()
    if _G.C_Timer and _G.C_Timer.After then
        _G.C_Timer.After(0, function() pcall(GB.Refresh) end)
    else
        pcall(GB.Refresh)
    end
end)
-- Fachwechsel in der Gildenbank: neu zeichnen.
if _G.hooksecurefunc and type(_G.SetCurrentGuildBankTab) == "function" then
    _G.hooksecurefunc("SetCurrentGuildBankTab", function() pcall(GB.Refresh) end)
end
