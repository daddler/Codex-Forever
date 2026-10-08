--------------------------------------------------
-- WeintCodex :: Taschen aller Charaktere (Fenster)
--------------------------------------------------
-- Seit 6.24.0.0 (Beta-Test: "eine Option Taschen in WeintCodex, die das
-- managed"). Zeigt den Bestand aus ui/inventory.lua als Fenster: links die
-- Charaktere (oder alle zusammen), oben Suche und Filter Taschen / Bank /
-- Angelegt, rechts die Gegenstaende als Symbolraster mit Anzahl. Maus
-- darauf: der Tooltip des Spiels - mit den Zeilen des Bestands darunter.
--
-- Nur Anzeige: verschieben, sortieren oder verschicken kann ein Addon fuer
-- andere Charaktere nichts. Stand wie im Bestand (letztes Einloggen, Bank
-- letzter Besuch).
--
-- /wcui taschen, Knopf auf der Seite "Bestand", Esc schliesst.
--------------------------------------------------

local K = WeintCodex.UIKit
local C = WeintCodex.Colors
local KEY = "comfort"
local IV = WeintCodex.UIInventory

WeintCodex.UIBagsWindow = {}
local BW = WeintCodex.UIBagsWindow

BW.W, BW.H = 720, 480
BW.LIST_W = 170
BW.CELL = 40
BW.GAP = 4
BW.COLS = 12
BW.ALL = "*"                 -- Auswahl "Alle Charaktere"

BW.sel = BW.ALL              -- gewaehlter Charakter (Schluessel) oder BW.ALL
BW.filter = { bags = true, bank = true, worn = true }
BW.query = ""

local win, list, grid, gridChild, search, foot
local charBtns, cells, filterBtns = {}, {}, {}

local function Accent() local a = WeintCodex.GameColors.frameAccent return a[1], a[2], a[3] end

--------------------------------------------------
-- Daten
--------------------------------------------------

-- Charaktere fuer die linke Liste: { key, name, realm, class }, sortiert.
function BW.Chars()
    local st = IV.Store(false)
    local _, _, myRealm = IV.Me()
    local all = K.Get(KEY, "invAllRealms")
    local out = {}
    for key, c in pairs(st and st.chars or {}) do
        if all or c.realm == myRealm then
            out[#out + 1] = { key = key, name = c.name, realm = c.realm, class = c.class }
        end
    end
    table.sort(out, function(a, b)
        if a.realm ~= b.realm then return tostring(a.realm) < tostring(b.realm) end
        return tostring(a.name) < tostring(b.name)
    end)
    return out
end

-- Gegenstaende fuer das Raster: { { id, count, name }, ... } nach Auswahl,
-- Filter und Suche; sortiert nach Name.
function BW.Items()
    local st = IV.Store(false)
    if not st then return {} end
    local sum = {}
    local function Add(t)
        for id, n in pairs(t or {}) do sum[id] = (sum[id] or 0) + n end
    end
    for _, ch in ipairs(BW.Chars()) do
        if BW.sel == BW.ALL or BW.sel == ch.key then
            local c = st.chars[ch.key]
            if BW.filter.bags then Add(c.bags) end
            if BW.filter.bank then Add(c.bank) end
            if BW.filter.worn then Add(c.worn) end
        end
    end
    local q = (BW.query or ""):lower()
    local out = {}
    for id, n in pairs(sum) do
        local nm = st.names[id]
        if q == "" or (type(nm) == "string" and nm:lower():find(q, 1, true)) then
            out[#out + 1] = { id = id, count = n, name = nm }
        end
    end
    table.sort(out, function(a, b)
        local an, bn = a.name or "~", b.name or "~"
        if an ~= bn then return an < bn end
        return a.id < b.id
    end)
    return out
end

local function Icon(id)
    local ci = _G.C_Item
    if ci and ci.GetItemIconByID then
        local ok, t = pcall(ci.GetItemIconByID, id)
        if ok and K.Plain(t) then return K.Plain(t) end
    end
    if _G.GetItemIcon then
        local ok, t = pcall(_G.GetItemIcon, id)
        if ok then return K.Plain(t) end
    end
    return nil
end

--------------------------------------------------
-- Fenster
--------------------------------------------------

local function Cell(i)
    local b = cells[i]
    if b then return b end
    b = CreateFrame("Button", nil, gridChild)
    b:SetSize(BW.CELL, BW.CELL)
    local s = C.surface2
    b.bg = b:CreateTexture(nil, "BACKGROUND")
    b.bg:SetAllPoints(b)
    b.bg:SetColorTexture(s[1], s[2], s[3], 1)
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetPoint("TOPLEFT", b, "TOPLEFT", 2, -2)
    b.icon:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -2, 2)
    b.count = K.NewText(b, 11, "OVERLAY")
    b.count:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -3, 3)
    b:SetScript("OnEnter", function(self)
        local gt = _G.GameTooltip
        if not (gt and self.id) then return end
        gt:SetOwner(self, "ANCHOR_RIGHT")
        if gt.SetItemByID then pcall(gt.SetItemByID, gt, self.id)
        else gt:SetText(self.name or ("#" .. self.id)) end
        gt:Show()
    end)
    b:SetScript("OnLeave", function() if _G.GameTooltip then _G.GameTooltip:Hide() end end)
    cells[i] = b
    return b
end

local function CharBtn(i)
    local b = charBtns[i]
    if b then return b end
    b = CreateFrame("Button", nil, list)
    b:SetHeight(26)
    b:SetPoint("LEFT", list, "LEFT", 6, 0)
    b:SetPoint("RIGHT", list, "RIGHT", -6, 0)
    b.hl = b:CreateTexture(nil, "BACKGROUND")
    b.hl:SetAllPoints(b)
    local s = C.surface3
    b.hl:SetColorTexture(s[1], s[2], s[3], 1)
    b.hl:Hide()
    local r, g, bl = Accent()
    b.bar = b:CreateTexture(nil, "ARTWORK")
    b.bar:SetPoint("TOPLEFT", b, "TOPLEFT", 0, 0)
    b.bar:SetPoint("BOTTOMLEFT", b, "BOTTOMLEFT", 0, 0)
    b.bar:SetWidth(2)
    b.bar:SetColorTexture(r, g, bl, 1)
    b.t = K.NewText(b, 12)
    b.t:SetPoint("LEFT", b, "LEFT", 10, 0)
    b.t:SetPoint("RIGHT", b, "RIGHT", -4, 0)
    b.t:SetJustifyH("LEFT")
    b.t:SetWordWrap(false)
    b:SetScript("OnClick", function(self) BW.sel = self.key BW.Refresh() end)
    charBtns[i] = b
    return b
end

local FILTERS = { { "bags", "Taschen" }, { "bank", "Bank" }, { "worn", "Angelegt" } }

function BW.Build()
    if win then return win end
    win = CreateFrame("Frame", "WeintCodexBags", UIParent)
    win:SetSize(BW.W, BW.H)
    win:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
    win:SetFrameStrata("HIGH")
    win:SetToplevel(true)
    win:SetClampedToScreen(true)
    win:EnableMouse(true)
    win:SetMovable(true)
    win:RegisterForDrag("LeftButton")
    win:SetScript("OnDragStart", win.StartMoving)
    win:SetScript("OnDragStop", win.StopMovingOrSizing)
    win:Hide()
    K.Kachel(win, { alpha = 0.96, shadow = 10 })
    if type(_G.UISpecialFrames) == "table" then table.insert(_G.UISpecialFrames, "WeintCodexBags") end
    local r, g, b = Accent()
    local edge = win:CreateTexture(nil, "ARTWORK")
    edge:SetPoint("TOPLEFT", win, "TOPLEFT", 1, -1)
    edge:SetPoint("TOPRIGHT", win, "TOPRIGHT", -1, -1)
    edge:SetHeight(2)
    edge:SetColorTexture(r, g, b, 0.85)

    local title = K.NewText(win, 15)
    title:SetPoint("TOPLEFT", win, "TOPLEFT", 14, -12)
    title:SetText("Taschen aller Charaktere")
    local close = CreateFrame("Button", nil, win)
    close:SetSize(24, 22)
    close:SetPoint("TOPRIGHT", win, "TOPRIGHT", -8, -8)
    local x = K.NewText(close, 14)
    x:SetPoint("CENTER", close, "CENTER", 0, 0)
    local m = C.textMuted
    x:SetTextColor(m[1], m[2], m[3])
    x:SetText("\195\151")
    close:SetScript("OnClick", function() win:Hide() end)

    -- Links: Charaktere
    list = CreateFrame("Frame", nil, win)
    list:SetPoint("TOPLEFT", win, "TOPLEFT", 1, -40)
    list:SetPoint("BOTTOMLEFT", win, "BOTTOMLEFT", 1, 1)
    list:SetWidth(BW.LIST_W)
    local lb = list:CreateTexture(nil, "BACKGROUND")
    lb:SetAllPoints(list)
    local s1 = C.surface1
    lb:SetColorTexture(s1[1], s1[2], s1[3], 0.9)

    -- Oben: Suche und Filter
    search = CreateFrame("EditBox", nil, win)
    search:SetPoint("TOPLEFT", win, "TOPLEFT", BW.LIST_W + 12, -44)
    search:SetSize(220, 24)
    search:SetAutoFocus(false)
    search:SetMaxLetters(60)
    local F = WeintCodex.Fonts or {}
    search:SetFont(F.sans or _G.STANDARD_TEXT_FONT, 12, "")
    search:SetTextInsets(8, 8, 0, 0)
    local sb = search:CreateTexture(nil, "BACKGROUND")
    sb:SetAllPoints(search)
    local s2 = C.surface2
    sb:SetColorTexture(s2[1], s2[2], s2[3], 1)
    search.hint = K.NewText(search, 12)
    search.hint:SetPoint("LEFT", search, "LEFT", 8, 0)
    search.hint:SetTextColor(m[1], m[2], m[3])
    search.hint:SetText("Suchen …")
    search:SetScript("OnTextChanged", function(self)
        local t = self:GetText() or ""
        self.hint:SetShown(t == "")
        BW.query = t
        BW.Refresh()
    end)
    search:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    search:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)

    local prev = search
    for i, f in ipairs(FILTERS) do
        local fb = CreateFrame("Button", nil, win)
        fb:SetSize(84, 24)
        fb:SetPoint("LEFT", prev, "RIGHT", i == 1 and 12 or 6, 0)
        fb.bg = fb:CreateTexture(nil, "BACKGROUND")
        fb.bg:SetAllPoints(fb)
        fb.t = K.NewText(fb, 12)
        fb.t:SetPoint("CENTER", fb, "CENTER", 0, 0)
        fb.t:SetText(f[2])
        fb.key = f[1]
        fb:SetScript("OnClick", function(self)
            BW.filter[self.key] = not BW.filter[self.key]
            BW.Refresh()
        end)
        filterBtns[i] = fb
        prev = fb
    end

    -- Raster, rollbar
    grid = CreateFrame("ScrollFrame", nil, win)
    grid:SetPoint("TOPLEFT", win, "TOPLEFT", BW.LIST_W + 12, -78)
    grid:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", -12, 30)
    grid:EnableMouseWheel(true)
    gridChild = CreateFrame("Frame", nil, grid)
    gridChild:SetSize(BW.COLS * (BW.CELL + BW.GAP), 10)
    grid:SetScrollChild(gridChild)
    grid:SetScript("OnMouseWheel", function(self, d)
        local max = K.Plain(self:GetVerticalScrollRange()) or 0
        local v = (K.Plain(self:GetVerticalScroll()) or 0) - d * (BW.CELL + BW.GAP)
        self:SetVerticalScroll(math.max(0, math.min(type(max) == "number" and max or 0, v)))
    end)

    foot = K.NewText(win, 11)
    foot:SetPoint("BOTTOMLEFT", win, "BOTTOMLEFT", BW.LIST_W + 12, 10)
    foot:SetPoint("RIGHT", win, "RIGHT", -12, 0)
    foot:SetJustifyH("LEFT")
    local f = C.textFaint
    foot:SetTextColor(f[1], f[2], f[3])

    BW.win = win
    return win
end

-- Alles neu zeichnen: Liste, Filter, Raster.
function BW.Refresh()
    if not (win and win:IsShown()) then return end
    local _, _, myRealm = IV.Me()
    local st = IV.Store(false)
    -- Liste
    local chars = BW.Chars()
    local entries = { { key = BW.ALL, label = "Alle Charaktere" } }
    for _, c in ipairs(chars) do
        local label = c.name or "?"
        if c.realm ~= myRealm then label = label .. "-" .. tostring(c.realm) end
        entries[#entries + 1] = { key = c.key, label = label, class = c.class }
    end
    local selKnown = false
    for _, e in ipairs(entries) do if e.key == BW.sel then selKnown = true end end
    if not selKnown then BW.sel = BW.ALL end
    for i, e in ipairs(entries) do
        local b = CharBtn(i)
        b.key = e.key
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", list, "TOPLEFT", 6, -8 - (i - 1) * 28)
        b:SetPoint("RIGHT", list, "RIGHT", -6, 0)
        b.t:SetText(e.label)
        local cr, cg, cb = IV.ClassColor(e.class)
        if e.key == BW.ALL then local t = C.textBright cr, cg, cb = t[1], t[2], t[3] end
        b.t:SetTextColor(cr, cg, cb)
        local on = e.key == BW.sel
        b.hl:SetShown(on)
        b.bar:SetShown(on)
        b:Show()
    end
    for i = #entries + 1, #charBtns do charBtns[i]:Hide() end
    -- Filter
    local r, g, bl = Accent()
    for _, fb in ipairs(filterBtns) do
        local on = BW.filter[fb.key]
        if on then fb.bg:SetColorTexture(r, g, bl, 0.25) else
            local s = C.surface2
            fb.bg:SetColorTexture(s[1], s[2], s[3], 1)
        end
        local c = on and C.textBright or C.textMuted
        fb.t:SetTextColor(c[1], c[2], c[3])
    end
    -- Raster
    local items = BW.Items()
    BW.shown = items
    local step = BW.CELL + BW.GAP
    for i, it in ipairs(items) do
        local b = Cell(i)
        b.id, b.name = it.id, it.name
        b.icon:SetTexture(Icon(it.id))
        b.count:SetText(it.count > 1 and it.count or "")
        local col, row = (i - 1) % BW.COLS, math.floor((i - 1) / BW.COLS)
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", gridChild, "TOPLEFT", col * step, -row * step)
        b:Show()
    end
    for i = #items + 1, #cells do cells[i]:Hide() end
    gridChild:SetHeight(math.max(10, math.ceil(#items / BW.COLS) * step))
    -- Fuss: was gezeigt wird, und ob die Bank bekannt ist
    local total = 0
    for _, it in ipairs(items) do total = total + it.count end
    local note = ""
    if BW.sel ~= BW.ALL and st and st.chars[BW.sel] and not st.chars[BW.sel].bank and BW.filter.bank then
        note = " · Bank unbekannt – einmal mit diesem Charakter öffnen"
    end
    if #items == 0 then
        foot:SetText((#chars == 0 and "Noch kein Charakter erfasst – einmal einloggen." or "Nichts gefunden.") .. note)
    else
        foot:SetText(#items .. " Gegenstände · " .. total .. " Stück" .. note)
    end
end

function BW.Show()
    if not IV.Active() then
        print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " Der Bestand ist aus (Komfort → Bestand).")
        return false
    end
    IV.ScanBags()
    BW.Build()
    win:Show()
    BW.Refresh()
    return true
end

function BW.Toggle()
    if win and win:IsShown() then win:Hide() return false end
    return BW.Show()
end
