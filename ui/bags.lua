--------------------------------------------------
-- WeintCodex :: Oberflaeche - Taschen
--------------------------------------------------
-- Alle Taschen in einem Fenster, als ein Raster: Rucksack zuerst, dann
-- Tasche 1 bis 4 (und die Reagenzientasche, wo es sie gibt). Suche,
-- Sortieren, Gold, Gegenstandsstufe auf Ausruestung.
--
-- DIE KNOEPFE SIND DIE DES SPIELS (ContainerFrameItemButtonTemplate).
-- Benutzen, Anlegen, Verkaufen, Ziehen und der Tooltip laufen dadurch
-- ueber den geschuetzten Code des Spiels, nicht ueber dieses Addon. Die
-- Tasche eines Knopfs ist die ID seines Elternrahmens, der Platz seine
-- eigene ID - so erwartet es die Vorlage (dasselbe Verfahren wie in
-- EllesmereUI; der Code ist eigener).
--
-- NIE IM KAMPF ANLEGEN. Ein Gegenstandsknopf, der im Kampf entsteht, ist
-- "tainted": ein Klick darauf endet in ADDON_ACTION_FORBIDDEN. Alle
-- Knoepfe werden deshalb beim Anmelden auf Vorrat angelegt, ausserhalb
-- des Kampfes. Reicht der Vorrat (bei sehr grossen Taschen) einmal nicht,
-- fehlen die letzten Plaetze bis nach dem Kampf - sichtbar, mit Hinweis.
--
-- Die Bank bleibt die des Spiels.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIBags = {}

local BG = WeintCodex.UIBags
local K  = WeintCodex.UIKit
local C  = WeintCodex.Colors
local F  = WeintCodex.Fonts
local KEY = "bags"

local defaults = {
    columns    = 12,
    slotSize   = 36,
    spacing    = 4,
    itemLevel  = true,
    qualityBorder = true,
    dimJunk    = true,
    scale      = 100,
}

local function Opt(k) return K.Get(KEY, k) end

local POOL = 180   -- Vorrat an Knoepfen; vier 36er-Taschen plus Rucksack sind 160

local win, grid, gold, search, note
local slots = {}   -- { holder, button } je Platz im Vorrat
local used = 0

--------------------------------------------------
-- Welche Taschen?
--------------------------------------------------

local function BagIDs()
    local ids = {}
    local first = _G.BACKPACK_CONTAINER or 0
    local last = _G.NUM_BAG_SLOTS or 4
    for b = first, last do ids[#ids + 1] = b end
    -- Reagenzientasche (moderner Client). Auf Forever unbekannt - fehlt
    -- sie, meldet der Client 0 Plaetze, und sie faellt von selbst weg.
    if _G.Enum and _G.Enum.BagIndex and _G.Enum.BagIndex.ReagentBag then
        ids[#ids + 1] = _G.Enum.BagIndex.ReagentBag
    end
    return ids
end

local function NumSlots(bag)
    local cc = _G.C_Container
    if cc and cc.GetContainerNumSlots then return cc.GetContainerNumSlots(bag) or 0 end
    return 0
end

local function Info(bag, slot)
    local cc = _G.C_Container
    return cc and cc.GetContainerItemInfo and cc.GetContainerItemInfo(bag, slot) or nil
end

--------------------------------------------------
-- Knoepfe
--------------------------------------------------

local function CreateSlot()
    local holder = CreateFrame("Frame", nil, grid)
    local ok, btn = pcall(CreateFrame, "ItemButton", nil, holder, "ContainerFrameItemButtonTemplate")
    if not ok or type(btn) ~= "table" then
        -- Aeltere Clients kennen den Objekttyp "ItemButton" nicht.
        ok, btn = pcall(CreateFrame, "Button", nil, holder, "ContainerFrameItemButtonTemplate")
    end
    if not ok or type(btn) ~= "table" then return nil end
    btn:SetAllPoints(holder)
    if btn.RegisterForClicks then btn:RegisterForClicks("LeftButtonUp", "RightButtonUp") end
    if btn.RegisterForDrag then btn:RegisterForDrag("LeftButton") end

    local d = {}
    d.bg = holder:CreateTexture(nil, "BACKGROUND")
    d.bg:SetAllPoints(holder)
    local s = C.surface1
    d.bg:SetColorTexture(s[1], s[2], s[3], 1)
    d.border = K.Border(holder, 1, 0, 0, 0, 1, "OVERLAY")
    local top = CreateFrame("Frame", nil, btn)
    top:SetAllPoints(btn)
    top:SetFrameLevel((btn:GetFrameLevel() or 1) + 3)
    top:EnableMouse(false)
    d.ilvl = top:CreateFontString(nil, "OVERLAY")
    d.ilvl:SetPoint("TOPLEFT", btn, "TOPLEFT", 2, -2)
    d.quality = K.Border(top, 1, 1, 1, 1, 1, "OVERLAY")
    d.quality:SetShown(false)
    -- Der Steinrahmen des Knopfs weg; das Symbol beschnitten und auf die
    -- volle Flaeche gezogen. Die Maske der Vorlage ist fuer 37 px gebaut;
    -- auf einem anders grossen Knopf blieb das Symbol in 6.0.0.3 im Spiel
    -- unsichtbar - EllesmereUI nimmt sie aus demselben Grund ab.
    local normal = btn.GetNormalTexture and btn:GetNormalTexture()
    if normal then normal:SetAlpha(0) end
    local icon = btn.icon or btn.Icon
    if type(icon) ~= "table" or not icon.SetTexture then icon = nil end
    if icon then
        if icon.SetTexCoord then icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) end
        icon:ClearAllPoints()
        icon:SetAllPoints(btn)
        local mask = btn.IconMask
        if type(mask) == "table" and icon.RemoveMaskTexture then
            pcall(icon.RemoveMaskTexture, icon, mask)
            if mask.Hide then mask:Hide() end
        end
    end
    if type(btn.IconBorder) == "table" then btn.IconBorder:SetAlpha(0) end
    for _, k in ipairs({ "NewItemTexture", "BattlepayItemTexture", "flash" }) do
        local r = btn[k]
        if type(r) == "table" and r.SetAlpha then r:SetAlpha(0) end
    end
    holder:Hide()
    return { holder = holder, button = btn, d = d, icon = icon }
end

local function EnsurePool()
    if K.InCombat() then return end
    while #slots < POOL do
        local s = CreateSlot()
        if not s then break end
        slots[#slots + 1] = s
    end
end

local function ItemLevel(bag, slot, info)
    if not (info and info.hyperlink) then return nil end
    local equip
    if _G.C_Item and _G.C_Item.GetItemInventoryTypeByID and info.itemID then
        equip = _G.C_Item.GetItemInventoryTypeByID(info.itemID)
        -- 0 = kein Ausruestungsteil (Enum.InventoryType.IndexNonEquipType)
        if type(equip) ~= "number" or equip == 0 then return nil end
    else
        local loc = _G.GetItemInfo and select(9, _G.GetItemInfo(info.hyperlink))
        if type(loc) ~= "string" or loc == "" or loc == "INVTYPE_NON_EQUIP_IGNORE" then return nil end
    end
    local lvl
    if _G.C_Item and _G.C_Item.GetCurrentItemLevel and _G.ItemLocation and _G.ItemLocation.CreateFromBagAndSlot then
        local ok, v = pcall(_G.C_Item.GetCurrentItemLevel, _G.ItemLocation:CreateFromBagAndSlot(bag, slot))
        if ok then lvl = v end
    end
    if type(lvl) ~= "number" and _G.GetDetailedItemLevelInfo then
        lvl = _G.GetDetailedItemLevelInfo(info.hyperlink)
    end
    -- Keine Stufe gemeldet ist keine Stufe 0.
    if type(lvl) ~= "number" or lvl <= 1 then return nil end
    return lvl
end

local function PaintSlot(s, bag, slot)
    local btn, d = s.button, s.d
    s.holder:SetID(bag)
    btn:SetID(slot)
    local info = Info(bag, slot)

    local tex = info and info.iconFileID or nil
    if btn.SetItemButtonTexture then btn:SetItemButtonTexture(tex)
    elseif _G.SetItemButtonTexture then _G.SetItemButtonTexture(btn, tex) end
    -- Zusaetzlich unmittelbar: das Symbol zeigen, auch wenn die Vorlage
    -- des Clients es anders verwaltet als erwartet.
    if s.icon then
        s.icon:SetTexture(tex)
        s.icon:SetShown(tex ~= nil)
    end
    local count = info and info.stackCount or 0
    if btn.SetItemButtonCount then btn:SetItemButtonCount(count)
    elseif _G.SetItemButtonCount then _G.SetItemButtonCount(btn, count) end

    local junk = info and info.quality == 0 and Opt("dimJunk")
    if _G.SetItemButtonDesaturated then
        _G.SetItemButtonDesaturated(btn, info and (info.isLocked or junk) and true or false)
    end
    btn:SetAlpha(info and info.isFiltered and 0.2 or 1)

    -- Abklingzeit (Traenke, Steine): gelesen, nicht gerechnet.
    local cdFrame = btn.Cooldown or _G[(btn:GetName() or "") .. "Cooldown"]
    local cc = _G.C_Container
    if type(cdFrame) == "table" and info and cc and cc.GetContainerItemCooldown and _G.CooldownFrame_Set then
        local start, duration, enable = cc.GetContainerItemCooldown(bag, slot)
        _G.CooldownFrame_Set(cdFrame, start, duration, enable)
    elseif type(cdFrame) == "table" and cdFrame.Clear then
        cdFrame:Clear()
    end

    local q = info and info.quality
    if Opt("qualityBorder") and type(q) == "number" and q >= 2 and _G.C_Item and _G.C_Item.GetItemQualityColor then
        local r, g, b = _G.C_Item.GetItemQualityColor(q)
        if type(r) == "number" then
            d.quality:SetColor(r, g, b, 1)
            d.quality:SetShown(true)
        else
            d.quality:SetShown(false)
        end
    else
        d.quality:SetShown(false)
    end

    local lvl = Opt("itemLevel") and info and ItemLevel(bag, slot, info)
    d.ilvl:SetText(lvl and tostring(lvl) or "")
    if lvl and type(q) == "number" and _G.C_Item and _G.C_Item.GetItemQualityColor then
        local r, g, b = _G.C_Item.GetItemQualityColor(q)
        if type(r) == "number" then d.ilvl:SetTextColor(r, g, b, 1) end
    end
    s.holder:Show()
    btn:Show()
    return info ~= nil
end

--------------------------------------------------
-- Fenster
--------------------------------------------------

function BG.Refresh()
    if not win or not win:IsShown() then return end
    EnsurePool()
    local size, sp, cols = Opt("slotSize"), Opt("spacing"), Opt("columns")
    local n = 0
    local missing = 0
    local filled = 0
    for _, bag in ipairs(BagIDs()) do
        for slot = 1, NumSlots(bag) do
            n = n + 1
            local s = slots[n]
            if s then
                s.holder:SetSize(size, size)
                s.holder:ClearAllPoints()
                local col = (n - 1) % cols
                local row = math.floor((n - 1) / cols)
                s.holder:SetPoint("TOPLEFT", grid, "TOPLEFT", col * (size + sp), -row * (size + sp))
                K.SetFont(s.d.ilvl, math.max(8, math.floor(size * 0.3)))
                if PaintSlot(s, bag, slot) then filled = filled + 1 end
            else
                missing = missing + 1
            end
        end
    end
    for i = n + 1, #slots do slots[i].holder:Hide() end
    used = n

    local rows = math.max(1, math.ceil(n / cols))
    grid:SetSize(cols * (size + sp) - sp, rows * (size + sp) - sp)
    win:SetSize(cols * (size + sp) - sp + 24, rows * (size + sp) - sp + 92)

    local money = _G.GetMoney and _G.GetMoney() or 0
    if _G.GetMoneyString then gold:SetText(_G.GetMoneyString(money, true))
    elseif _G.GetCoinTextureString then gold:SetText(_G.GetCoinTextureString(money)) end

    if missing > 0 then
        note:SetText(missing .. " Plätze erscheinen nach dem Kampf.")
        note:SetTextColor(unpack(C.warningBright))
    else
        -- Belegt laut Client. Steht hier eine Zahl, aber die Plaetze sind
        -- leer, liefert das Spiel die Gegenstaende und nur das Zeichnen
        -- scheitert - fuer eine Fehlermeldung aus dem Spiel Gold wert.
        note:SetFormattedText("%d von %d Plätzen belegt", filled, n)
        note:SetTextColor(unpack(C.textMuted))
    end
    note:Show()
    BG._filled = filled
end

local function Build()
    win = CreateFrame("Frame", "WeintCodexBags", UIParent)
    win:SetSize(400, 300)
    win:SetFrameStrata("HIGH")
    win:SetToplevel(true)
    win:SetClampedToScreen(true)
    win:EnableMouse(true)
    win:Hide()
    local bg = win:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(win)
    bg:SetColorTexture(unpack(C.bgDark))
    WeintCodex.DrawBorder(win, C.border[1], C.border[2], C.border[3], 1, 1)
    if type(_G.UISpecialFrames) == "table" then table.insert(_G.UISpecialFrames, "WeintCodexBags") end

    local title = win:CreateFontString(nil, "OVERLAY")
    title:SetFont(F.display, 16, "")
    title:SetTextColor(unpack(C.textBright))
    title:SetPoint("TOPLEFT", win, "TOPLEFT", 12, -12)
    title:SetText("Taschen")

    local close = CreateFrame("Button", nil, win)
    close:SetSize(24, 22)
    close:SetPoint("TOPRIGHT", win, "TOPRIGHT", -6, -8)
    local x = close:CreateFontString(nil, "OVERLAY")
    x:SetFont(F.sans, 14, "")
    x:SetPoint("CENTER", close, "CENTER", 0, 0)
    x:SetTextColor(unpack(C.textMuted))
    x:SetText("\195\151")
    close:SetScript("OnClick", function() win:Hide() end)

    local sort = WeintCodex.CreateButton(win, {
        text = "Sortieren", kind = "ghost", height = 22, size = 11, backdrop = "bgDark",
        tooltip = "Sortiert alle Taschen, wie es das Spiel selbst tut.",
        onClick = function()
            local cc = _G.C_Container
            if cc and cc.SortBags then cc.SortBags() elseif _G.SortBags then _G.SortBags() end
        end,
    })
    sort:SetPoint("RIGHT", close, "LEFT", -6, 0)

    search = CreateFrame("EditBox", nil, win)
    search:SetSize(160, 22)
    search:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    search:SetAutoFocus(false)
    search:SetFont(F.sans, 12, "")
    search:SetTextInsets(6, 6, 0, 0)
    local sbg = search:CreateTexture(nil, "BACKGROUND")
    sbg:SetAllPoints(search)
    sbg:SetColorTexture(unpack(C.surface1))
    search:SetScript("OnTextChanged", function(self)
        local cc = _G.C_Container
        if cc and cc.SetItemSearch then cc.SetItemSearch(self:GetText() or "") end
    end)
    search:SetScript("OnEscapePressed", function(self) self:SetText("") self:ClearFocus() end)

    gold = win:CreateFontString(nil, "OVERLAY")
    gold:SetFont(F.monoMedium, 11, "")
    gold:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", -12, 10)
    gold:SetTextColor(unpack(C.textNormal))

    note = win:CreateFontString(nil, "OVERLAY")
    note:SetFont(F.sans, 10, "")
    note:SetPoint("BOTTOMLEFT", win, "BOTTOMLEFT", 12, 10)
    note:SetTextColor(unpack(C.warningBright))
    note:Hide()

    grid = CreateFrame("Frame", nil, win)
    grid:SetPoint("TOPLEFT", win, "TOPLEFT", 12, -68)
    grid:SetSize(100, 100)

    win:SetScript("OnShow", function() BG.Refresh() end)
    win:SetScript("OnHide", function()
        local cc = _G.C_Container
        if search and search:GetText() ~= "" then
            search:SetText("")
            if cc and cc.SetItemSearch then cc.SetItemSearch("") end
        end
    end)
    win.WCShowForUnlock = function(self, on) if on then self:Show() end end
    K.RegisterMover(win, "bags", "Taschen",
        { point = "BOTTOMRIGHT", relPoint = "BOTTOMRIGHT", x = -20, y = 110 })
end

function BG.Toggle()
    if not win then return end
    if win:IsShown() then win:Hide() else win:Show() end
end
function BG.Open() if win then win:Show() end end
function BG.Close() if win then win:Hide() end end
function BG.UsedSlots() return used end

--------------------------------------------------
-- Modul
--------------------------------------------------

local function Enable()
    Build()
    win:SetScale((Opt("scale") or 100) / 100)
    K.AfterCombat(EnsurePool)

    -- Die Taschen des Spiels verstecken (Ereignisse behalten: andere
    -- Teile des Spiels fragen sie nach ihrem Zustand).
    K.HideBlizzard("ContainerFrameCombinedBags", true)
    for i = 1, (_G.NUM_CONTAINER_FRAMES or 13) do
        K.HideBlizzard("ContainerFrame" .. i, true)
    end

    -- OEFFNEN SPIEGELT DIE TASCHEN DES SPIELS. Deren Fenster gehen weiter
    -- auf und zu (nur unsichtbar, im versteckten Elternrahmen) - dieses
    -- folgt ihnen. Die Funktionen selbst (ToggleAllBags & Co.) mit Haken zu
    -- versehen geht schief: sie rufen sich gegenseitig auf, und ein
    -- "Umschalten" nach einem inneren "Oeffnen" machte die Tasche sofort
    -- wieder zu.
    local watched = {}
    local function AnyBlizzardOpen()
        for _, f in ipairs(watched) do
            if f:IsShown() then return true end
        end
        return false
    end
    -- An die METHODEN Show/Hide/SetShown, nicht an OnShow/OnHide: die
    -- Rahmen des Spiels stehen im versteckten Elternrahmen, und dort feuert
    -- OnShow nie - sie werden ja nie sichtbar. Show() wird trotzdem
    -- aufgerufen, und IsShown() sagt, was das Spiel meint.
    local function Mirror()
        if AnyBlizzardOpen() then BG.Open() else BG.Close() end
    end
    local function Watch(f)
        if type(f) ~= "table" or not _G.hooksecurefunc then return end
        watched[#watched + 1] = f
        for _, m in ipairs({ "Show", "Hide", "SetShown" }) do
            if type(f[m]) == "function" then _G.hooksecurefunc(f, m, Mirror) end
        end
    end
    Watch(_G.ContainerFrameCombinedBags)
    for i = 1, (_G.NUM_CONTAINER_FRAMES or 13) do Watch(_G["ContainerFrame" .. i]) end

    -- Schliesst man dieses Fenster (Kreuz, Esc), gehen auch die des Spiels
    -- zu - sonst oeffnete die Taschentaste beim naechsten Mal nichts, weil
    -- das Spiel sie noch fuer offen haelt.
    win:HookScript("OnHide", function()
        if AnyBlizzardOpen() and _G.CloseAllBags then _G.CloseAllBags() end
    end)

    local ev = CreateFrame("Frame")
    for _, e in ipairs({ "BAG_UPDATE_DELAYED", "ITEM_LOCK_CHANGED", "BAG_UPDATE_COOLDOWN",
        "PLAYER_MONEY", "INVENTORY_SEARCH_UPDATE", "PLAYER_REGEN_ENABLED" }) do
        pcall(ev.RegisterEvent, ev, e)
    end
    ev:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_ENABLED" then EnsurePool() end
        BG.Refresh()
    end)
end

local function px(v) return string.format("%d px", v) end

K.Register({
    key = KEY, group = "ui", order = 50,
    title = "Taschen",
    description = "Alle Taschen in einem Fenster: Suche, Sortieren, Gold, Gegenstandsstufe und Qualitätsrand. Benutzen und Verkaufen erledigt weiter das Spiel.",
    defaults = defaults,
    Enable = Enable,
    OnSetting = function()
        if win then
            win:SetScale((Opt("scale") or 100) / 100)
            BG.Refresh()
        end
    end,
    pages = {
        { key = "allgemein", label = "Allgemein", build = function(B)
            B:Section("Raster")
            B:Row({ type = "slider", label = "Spalten", key = "columns", min = 6, max = 24, step = 1,
                    format = function(v) return tostring(v) end },
                  { type = "slider", label = "Platzgröße", key = "slotSize", min = 24, max = 52, step = 1, format = px })
            B:Row({ type = "slider", label = "Abstand", key = "spacing", min = 0, max = 10, step = 1, format = px },
                  { type = "slider", label = "Fenstergröße", key = "scale", min = 60, max = 150, step = 5,
                    format = function(v) return string.format("%d %%", v) end })
            B:Section("Anzeigen")
            B:Row({ type = "toggle", label = "Gegenstandsstufe auf Ausrüstung", key = "itemLevel",
                    description = "Nennt das Spiel keine Stufe, bleibt das Feld leer – nie 0." },
                  { type = "toggle", label = "Rand in Qualitätsfarbe", key = "qualityBorder" })
            B:Row({ type = "toggle", label = "Graue Gegenstände abdunkeln", key = "dimJunk" },
                  { type = "empty" })
            B:Note("Die Bank bleibt die des Spiels. Öffnen mit der Taschentaste (B) oder einem Klick auf den Rucksack.")
        end },
    },
})
