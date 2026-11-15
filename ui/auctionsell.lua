--------------------------------------------------
-- WeintCodex :: Oberflaeche - Verkaufen im Auktionshaus
--------------------------------------------------
-- 1.0.7.0 (Wunsch nach dem Vergleich mit Naowh Forever "The Market",
-- Verhalten nachgebaut, eigener Code - dort "All Rights Reserved").
--
-- LISTE: neben dem Auktionshaus deine Taschen, die wertvollsten zuerst
-- (Preis aus den Auktionspreisen, ui/auctionprices.lua; ohne bekannten
-- Preis hinten, nie als 0). Klick legt den Gegenstand in den Verkauf des
-- Spiels (AuctionHouseFrame:SetPostItem) - eingestellt wird weiter mit
-- dem Knopf des Spiels.
--
-- UNTERBIETEN: zeigt das Spiel die Angebote zu dem Gegenstand, der gerade
-- im Verkauf liegt, setzt WeintCodex den Preis eine Stufe unter das
-- guenstigste Angebot, das nicht deins ist (eine Stufe = 1 Silber, das
-- Auktionshaus nimmt nur ganze Silber). Ungemessen auf Forever: wie das
-- Preisfeld des Verkaufs heisst - gefunden wird es ueber die Namen aus
-- Retail, sonst bleibt der Preis, wie das Spiel ihn setzt.
--
-- Schalter `ahSell`, `ahUndercut` auf der Seite Auktionshaus (Komfort).
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIAuctionSell = {}

local AS = WeintCodex.UIAuctionSell
local K = WeintCodex.UIKit
local C = WeintCodex.Colors
local KEY = "comfort"

AS.DEFAULTS = { ahSell = true, ahUndercut = true }
AS.ROWS = 14
AS.ROW_H = 24
AS.W = 250
AS.STEP = 100     -- 1 Silber

local function Get(k) return K.IsActive(KEY) and K.Get(KEY, k) and true or false end
local function AP() return WeintCodex.UIAuctionPrices end

-- Eine Stufe unter p, auf ganze Silber, nie unter 1 Silber.
function AS.Undercut(p)
    if type(p) ~= "number" or p <= 0 then return nil end
    local u = math.floor((p - 1) / AS.STEP) * AS.STEP
    if u < AS.STEP then u = AS.STEP end
    return u
end

-- Guenstigstes fremdes Angebot je Stueck aus den Ergebnissen des Spiels.
function AS.Cheapest(event, arg)
    local ah = _G.C_AuctionHouse
    if not ah then return nil end
    local id, best
    if event == "COMMODITY_SEARCH_RESULTS_UPDATED" then
        id = K.Plain(arg)
        if type(id) ~= "number" or not ah.GetNumCommoditySearchResults then return nil end
        local ok, n = pcall(ah.GetNumCommoditySearchResults, id)
        for i = 1, (ok and tonumber(K.Plain(n)) or 0) do
            local ok2, r = pcall(ah.GetCommoditySearchResultInfo, id, i)
            if ok2 and type(r) == "table" and not K.Plain(r.containsOwnerItem) then
                local p = K.Plain(r.unitPrice)
                if type(p) == "number" and p > 0 and (not best or p < best) then best = p end
            end
        end
    elseif event == "ITEM_SEARCH_RESULTS_UPDATED" then
        id = type(arg) == "table" and K.Plain(arg.itemID)
        if type(id) ~= "number" or not ah.GetNumItemSearchResults then return nil end
        local ok, n = pcall(ah.GetNumItemSearchResults, arg)
        for i = 1, (ok and tonumber(K.Plain(n)) or 0) do
            local ok2, r = pcall(ah.GetItemSearchResultInfo, arg, i)
            if ok2 and type(r) == "table" and not K.Plain(r.containsOwnerItem) then
                local b, q = K.Plain(r.buyoutAmount), K.Plain(r.quantity)
                q = (type(q) == "number" and q > 0) and q or 1
                if type(b) == "number" and b > 0 then
                    local p = math.floor(b / q + 0.5)
                    if not best or p < best then best = p end
                end
            end
        end
    end
    return id, best
end

-- Welcher Verkauf gerade offen ist und welcher Gegenstand darin liegt.
local function SellFrames()
    local f = _G.rawget(_G, "AuctionHouseFrame")
    if not f then return nil end
    return _G.rawget(f, "CommoditiesSellFrame"), _G.rawget(f, "ItemSellFrame")
end
local function ItemIn(sf)
    if not (sf and sf.GetItem and sf.IsShown and sf:IsShown()) then return nil end
    local ok, loc = pcall(sf.GetItem, sf)
    if not (ok and loc) then return nil end
    local ci = _G.C_Item
    if ci and ci.GetItemID then
        local ok2, id = pcall(ci.GetItemID, loc)
        if ok2 then return K.Plain(id) end
    end
    return nil
end

-- Preis ins Feld des Spiels. true, wenn ein Feld es nahm.
function AS.SetPrice(sf, copper)
    if not (sf and copper) then return false end
    if sf.SetPrice and pcall(sf.SetPrice, sf, copper) then return true end
    local pi = sf.PriceInput
    if pi and pi.SetAmount and pcall(pi.SetAmount, pi, copper) then return true end
    local mi = pi and pi.MoneyInputFrame
    if mi and mi.SetAmount and pcall(mi.SetAmount, mi, copper) then return true end
    return false
end

AS.lastSet = nil
function AS.OnResults(event, arg)
    if not Get("ahUndercut") then return nil end
    local id, best = AS.Cheapest(event, arg)
    if not (id and best) then return nil end
    local u = AS.Undercut(best)
    for _, sf in ipairs({ SellFrames() }) do
        if ItemIn(sf) == id and AS.SetPrice(sf, u) then
            AS.lastSet = u
            return u
        end
    end
    return nil
end

--------------------------------------------------
-- Liste der Taschen
--------------------------------------------------

-- { bag, slot, id, link, icon, count, price (je Stueck oder nil) }, sortiert.
local listBuf = {}
function AS.BagItems()
    for i = #listBuf, 1, -1 do listBuf[i] = nil end
    local ci = _G.C_Container
    if not (ci and ci.GetContainerNumSlots and ci.GetContainerItemInfo) then return listBuf end
    local ap = AP()
    for bag = 0, 4 do
        local ok, n = pcall(ci.GetContainerNumSlots, bag)
        for slot = 1, (ok and tonumber(n) or 0) do
            local ok2, info = pcall(ci.GetContainerItemInfo, bag, slot)
            if ok2 and type(info) == "table" and info.itemID and not info.isBound then
                local e = ap and ap.Lookup and ap.Lookup(info.itemID)
                listBuf[#listBuf + 1] = { bag = bag, slot = slot, id = info.itemID, link = info.hyperlink,
                    icon = info.iconFileID, count = info.stackCount or 1, price = e and e.price or nil }
            end
        end
    end
    table.sort(listBuf, function(a, b)
        local va = a.price and a.price * a.count or -1
        local vb = b.price and b.price * b.count or -1
        if va ~= vb then return va > vb end
        return a.id < b.id
    end)
    return listBuf
end

local panel
local function Row(i)
    local r = CreateFrame("Button", nil, panel)
    r:SetSize(AS.W - 16, AS.ROW_H)
    r:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -32 - (i - 1) * AS.ROW_H)
    local hl = r:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints(r)
    local t = C.textBright
    hl:SetColorTexture(t[1], t[2], t[3], 0.06)
    r.icon = r:CreateTexture(nil, "ARTWORK")
    r.icon:SetSize(20, 20)
    r.icon:SetPoint("LEFT", r, "LEFT", 0, 0)
    r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    r.value = K.NewText(r, 10)
    r.value:SetPoint("RIGHT", r, "RIGHT", -2, 0)
    r.value:SetJustifyH("RIGHT")
    r.name = K.NewText(r, 11)
    r.name:SetPoint("LEFT", r.icon, "RIGHT", 6, 0)
    r.name:SetPoint("RIGHT", r.value, "LEFT", -6, 0)
    r.name:SetJustifyH("LEFT")
    r.name:SetWordWrap(false)
    r:SetScript("OnClick", function(self) AS.Post(self.bag, self.slot) end)
    r:SetScript("OnEnter", function(self)
        if not (_G.GameTooltip and self.bag) then return end
        _G.GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        _G.GameTooltip:SetBagItem(self.bag, self.slot)
        _G.GameTooltip:Show()
    end)
    r:SetScript("OnLeave", function() if _G.GameTooltip then _G.GameTooltip:Hide() end end)
    return r
end

-- In den Verkauf des Spiels legen.
function AS.Post(bag, slot)
    local f = _G.rawget(_G, "AuctionHouseFrame")
    local IL = _G.rawget(_G, "ItemLocation")
    if not (f and f.SetPostItem and IL and IL.CreateFromBagAndSlot) then return false end
    local ok, loc = pcall(IL.CreateFromBagAndSlot, IL, bag, slot)
    return ok and pcall(f.SetPostItem, f, loc) and true or false
end

local rows = {}
function AS.Refresh()
    if not panel then return end
    local f = _G.rawget(_G, "AuctionHouseFrame")
    local show = Get("ahSell") and f and f.IsShown and f:IsShown()
    panel:SetShown(show and true or false)
    if not show then return end
    local list = AS.BagItems()
    local ap = AP()
    for i = 1, AS.ROWS do
        local r = rows[i] or Row(i)
        rows[i] = r
        local e = list[i]
        if e then
            r.bag, r.slot = e.bag, e.slot
            r.icon:SetTexture(e.icon or 134400)
            r.name:SetText((e.link or "") .. (e.count > 1 and (" ×" .. e.count) or ""))
            r.value:SetText(e.price and ap and ap.Money and ap.Money(e.price * e.count) or "Preis unbekannt")
            r:Show()
        else
            r.bag = nil
            r:Hide()
        end
    end
    panel.empty:SetShown(#list == 0)
end

local function Build()
    if panel then return end
    local f = _G.rawget(_G, "AuctionHouseFrame")
    if not f then return end
    panel = CreateFrame("Frame", "WeintCodexAuctionSell", f)
    panel:SetSize(AS.W, 40 + AS.ROWS * AS.ROW_H)
    panel:SetPoint("TOPLEFT", f, "TOPRIGHT", 4, 0)
    local bg = panel:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(panel)
    local b = C.bgPanel
    bg:SetColorTexture(b[1], b[2], b[3], 0.95)
    K.Border(panel, 1, 0, 0, 0, 1, "BORDER")
    local title = K.NewText(panel, 12)
    title:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -10)
    title:SetText("Verkaufen – wertvollste zuerst")
    panel.empty = K.NewText(panel, 11)
    panel.empty:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -36)
    panel.empty:SetText("Nichts zu verkaufen.")
end

local ev = CreateFrame("Frame")
local function OnEvent(_, event, arg)
    if event == "AUCTION_HOUSE_SHOW" then
        Build()
        AS.Refresh()
        if not panel and _G.C_Timer and _G.C_Timer.After then
            _G.C_Timer.After(0, function() Build() AS.Refresh() end)
        end
    elseif event == "AUCTION_HOUSE_CLOSED" then
        if panel then panel:Hide() end
    elseif event == "BAG_UPDATE_DELAYED" then
        if panel and panel:IsShown() then AS.Refresh() end
    else
        AS.OnResults(event, arg)
    end
end
ev:SetScript("OnEvent", K.Measured("Verkaufen", OnEvent))
AS.OnEvent = OnEvent

function AS.Apply()
    local on = Get("ahSell") or Get("ahUndercut")
    for _, e in ipairs({ "AUCTION_HOUSE_SHOW", "AUCTION_HOUSE_CLOSED", "BAG_UPDATE_DELAYED",
        "COMMODITY_SEARCH_RESULTS_UPDATED", "ITEM_SEARCH_RESULTS_UPDATED" }) do
        if on then pcall(ev.RegisterEvent, ev, e) else pcall(ev.UnregisterEvent, ev, e) end
    end
    AS.Refresh()
end

local mod = K.Module(KEY)
if mod then
    for k, v in pairs(AS.DEFAULTS) do
        if mod.defaults[k] == nil then mod.defaults[k] = v end
    end
end
K.Listen(function(kind, key)
    if (kind == "active" or kind == "setting") and key == KEY then AS.Apply() end
end)
