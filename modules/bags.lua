--------------------------------------------------
-- WeintCodex :: Taschen (Seite im Codex)
--------------------------------------------------
-- Seit 6.25.0.0 (Beta-Test: "die Taschen nicht als Komfortfunktion in der
-- UI, sondern standardmaessig in WeintCodex ... kein neues Fenster,
-- sondern ein interaktives Fenster direkt in der Rubrik"). Vorher (6.24)
-- ein eigenes Fenster ui/bagswin.lua - es lag hinter dem Codex.
--
-- Die Seite zeigt den Bestand aus ui/inventory.lua (WeintCodex.UIInventory,
-- laedt spaeter; nur zur Laufzeit gelesen): links in der Unternavigation die
-- Charaktere (oder alle zusammen), oben Suche (mit Loeschknopf) und die
-- Filter Taschen / Bank / Angelegt, darunter die Gegenstaende als Raster
-- mit Anzahl - so viele Spalten, wie die Breite traegt. Das Raster ist die
-- eine Flaeche der Seite, die rollt. Rechts der Detailbereich: was gezeigt
-- wird, ob die Bank bekannt ist, die Schalter.
--
-- Nur Anzeige: verschieben, sortieren oder verschicken kann ein Addon fuer
-- andere Charaktere nichts. Stand, nicht live: letztes Einloggen, Bank
-- letzter Besuch - "Bank unbekannt", nie 0.
--------------------------------------------------

WeintCodex.Bags = {}
local BG = WeintCodex.Bags
local C = WeintCodex.Colors

BG.CELL = 40
BG.GAP = 4
BG.ALL = "*"                 -- Auswahl "Alle Charaktere"
BG.HEAD = 84

BG.sel = BG.ALL
BG.filter = { bags = true, bank = true, worn = true }
BG.query = ""
BG.cols = 0

local page
local cells, filterBtns = {}, {}

local function IV() return WeintCodex.UIInventory end
local function Plain(v)
    local K = WeintCodex.UIKit
    if K and K.Plain then return K.Plain(v) end
    return v
end
local function Get(k) local K = WeintCodex.UIKit return K and K.Get("comfort", k) end
local function Set(k, v) local K = WeintCodex.UIKit if K then K.Set("comfort", k, v) end end

--------------------------------------------------
-- Daten
--------------------------------------------------

-- Charaktere: { key, name, realm, class }, sortiert (eigener Realm, sonst alle).
function BG.Chars()
    local iv = IV()
    if not iv then return {} end
    local st = iv.Store(false)
    local _, _, myRealm = iv.Me()      -- nicht "iv and iv.Me()": das kappt auf einen Wert
    local all = Get("invAllRealms")
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

-- Summe eines Charakters ueber die eingeschalteten Filter.
local function Count(c)
    local n = 0
    for _, part in ipairs({ "bags", "bank", "worn" }) do
        if BG.filter[part] then for _, x in pairs(c[part] or {}) do n = n + x end end
    end
    return n
end

-- Gegenstaende fuer das Raster: { { id, count, name } } nach Auswahl,
-- Filter und Suche; sortiert nach Name.
function BG.Items()
    local iv = IV()
    local st = iv and iv.Store(false)
    if not st then return {} end
    local sum = {}
    local function Add(t) for id, n in pairs(t or {}) do sum[id] = (sum[id] or 0) + n end end
    for _, ch in ipairs(BG.Chars()) do
        if BG.sel == BG.ALL or BG.sel == ch.key then
            local c = st.chars[ch.key]
            if BG.filter.bags then Add(c.bags) end
            if BG.filter.bank then Add(c.bank) end
            if BG.filter.worn then Add(c.worn) end
        end
    end
    local q = (BG.query or ""):lower()
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
        if ok and Plain(t) then return Plain(t) end
    end
    if _G.GetItemIcon then
        local ok, t = pcall(_G.GetItemIcon, id)
        if ok then return Plain(t) end
    end
    return nil
end

--------------------------------------------------
-- Seite
--------------------------------------------------

local function Cell(i)
    local b = cells[i]
    if b then return b end
    b = CreateFrame("Button", nil, page.GridBody)
    b:SetSize(BG.CELL, BG.CELL)
    local s = C.surface2
    b.bg = b:CreateTexture(nil, "BACKGROUND")
    b.bg:SetAllPoints(b)
    b.bg:SetColorTexture(s[1], s[2], s[3], 1)
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetPoint("TOPLEFT", b, "TOPLEFT", 2, -2)
    b.icon:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -2, 2)
    b.count = WeintCodex.Label(b, "", { size = 11, color = "textBright" })
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

local FILTERS = { { "bags", "Taschen" }, { "bank", "Bank" }, { "worn", "Angelegt" } }

-- Suche leeren: Text weg, Fokus weg, Raster neu.
function BG.ClearSearch()
    BG.query = ""
    if page and page.Search then
        page.Search:SetText("")
        page.Search:ClearFocus()
    end
    BG.DrawGrid()
end

local function BuildPage()
    if page then return page end
    local cp = WeintCodex.ContentPanel
    local f = CreateFrame("Frame", nil, cp)
    f:SetAllPoints(cp)
    local M = WeintCodex.Metrics
    f.Head = WeintCodex.PageHead(f, {
        eyebrow = "Leveln",
        title   = "Taschen",
        sub     = "Was deine Charaktere in Taschen, auf der Bank und am Leib tragen – Stand ihres letzten Besuchs.",
        height  = BG.HEAD,
    })
    local card = WeintCodex.CreateSurface(f, { tone = "plain", radius = 14, backdrop = "bgDark" })
    card:SetPoint("TOPLEFT", f, "TOPLEFT", M.PAD_X, -(M.PAD_Y + BG.HEAD))
    card:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -M.PAD_X, M.PAD_Y)
    f.Card = card

    -- Suche mit Loeschknopf (Beta-Test: "man kann den Suchbegriff nicht
    -- direkt loeschen"). Esc leert ebenfalls.
    local box = CreateFrame("Frame", nil, card)
    box:SetPoint("TOPLEFT", card, "TOPLEFT", 20, -16)
    box:SetSize(260, 28)
    local bb = box:CreateTexture(nil, "BACKGROUND")
    bb:SetAllPoints(box)
    local s2 = C.surface2
    bb:SetColorTexture(s2[1], s2[2], s2[3], 1)
    local eb = CreateFrame("EditBox", nil, box)
    eb:SetPoint("TOPLEFT", box, "TOPLEFT", 0, 0)
    eb:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -26, 0)
    eb:SetAutoFocus(false)
    eb:SetMaxLetters(60)
    eb:SetFont(WeintCodex.Fonts.sans, 12, "")
    eb:SetTextInsets(10, 4, 0, 0)
    local tc = C.textBright
    eb:SetTextColor(tc[1], tc[2], tc[3])
    eb.hint = WeintCodex.Label(box, "Gegenstand suchen …", { size = 12, color = "textMuted" })
    eb.hint:SetPoint("LEFT", box, "LEFT", 10, 0)
    local clear = CreateFrame("Button", nil, box)
    clear:SetSize(24, 24)
    clear:SetPoint("RIGHT", box, "RIGHT", -2, 0)
    clear.x = WeintCodex.Label(clear, "\195\151", { size = 15, color = "textMuted" })
    clear.x:SetPoint("CENTER", clear, "CENTER", 0, 1)
    clear:SetScript("OnClick", BG.ClearSearch)
    clear:SetScript("OnEnter", function(self) local c = C.textBright self.x:SetTextColor(c[1], c[2], c[3]) end)
    clear:SetScript("OnLeave", function(self) local c = C.textMuted self.x:SetTextColor(c[1], c[2], c[3]) end)
    clear:Hide()
    eb:SetScript("OnTextChanged", function(self)
        local t = self:GetText() or ""
        self.hint:SetShown(t == "")
        clear:SetShown(t ~= "")
        if t == BG.query then return end
        BG.query = t
        BG.DrawGrid()
    end)
    eb:SetScript("OnEscapePressed", function() BG.ClearSearch() end)
    eb:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    f.Search, f.Clear = eb, clear

    local prev = box
    for i, fl in ipairs(FILTERS) do
        local fb = CreateFrame("Button", nil, card)
        fb:SetSize(88, 28)
        fb:SetPoint("LEFT", prev, "RIGHT", i == 1 and 12 or 6, 0)
        fb.bg = fb:CreateTexture(nil, "BACKGROUND")
        fb.bg:SetAllPoints(fb)
        fb.t = WeintCodex.Label(fb, fl[2], { size = 12 })
        fb.t:SetPoint("CENTER", fb, "CENTER", 0, 0)
        fb.key = fl[1]
        fb:SetScript("OnClick", function(self)
            BG.filter[self.key] = not BG.filter[self.key]
            BG.Show()
        end)
        filterBtns[i] = fb
        prev = fb
    end

    f.GridScroll, f.GridBody = WeintCodex.CreateScrollArea(card, 20, -58, 400, 300, true)
    f.Foot = WeintCodex.Label(card, "", { size = 11, color = "textFaint" })
    f.Foot:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 20, 12)

    f:SetScript("OnSizeChanged", function(self, width)
        width = Plain(width)
        if self:IsShown() and type(width) == "number" and type(self.drawnWidth) == "number"
           and math.abs(width - self.drawnWidth) > 2 then
            BG.Show()
        end
    end)
    page = f
    BG.page = f
    return f
end

-- Spalten aus der echten Breite, nie fest.
function BG.Columns(width)
    local step = BG.CELL + BG.GAP
    return math.max(1, math.floor(((width or 0) + BG.GAP) / step))
end

-- Nur das Raster und der Fuss (Suche tippt, Liste bleibt).
function BG.DrawGrid()
    if not page then return end
    local iv = IV()
    local st = iv and iv.Store(false)
    local items = BG.Items()
    BG.shown = items
    local cols = BG.cols > 0 and BG.cols or 1
    local step = BG.CELL + BG.GAP
    for i, it in ipairs(items) do
        local b = Cell(i)
        b.id, b.name = it.id, it.name
        b.icon:SetTexture(Icon(it.id))
        b.count:SetText(it.count > 1 and tostring(it.count) or "")
        local col, row = (i - 1) % cols, math.floor((i - 1) / cols)
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", page.GridBody, "TOPLEFT", col * step, -row * step)
        b:Show()
    end
    for i = #items + 1, #cells do cells[i]:Hide() end
    page.GridBody:SetHeight(math.max(10, math.ceil(#items / cols) * step))
    local total = 0
    for _, it in ipairs(items) do total = total + it.count end
    local note = ""
    local c = BG.sel ~= BG.ALL and st and st.chars[BG.sel]
    if c and not c.bank and BG.filter.bank then
        note = " · Bank unbekannt – einmal mit diesem Charakter öffnen"
    end
    local text
    if #items == 0 then
        if #BG.Chars() == 0 then text = "Noch kein Charakter erfasst – einmal einloggen."
        elseif BG.query ~= "" then text = "Nichts gefunden für „" .. BG.query .. "“."
        else text = "Nichts zu zeigen – Filter prüfen." end
    else
        text = #items .. " Gegenstände · " .. total .. " Stück"
    end
    page.Foot:SetText(text .. note)
end

local function SidebarItems(chars, myRealm)
    local st = IV() and IV().Store(false)
    local items, order = {}, {}
    local sum = 0
    for _, ch in ipairs(chars) do sum = sum + Count(st.chars[ch.key]) end
    items[1] = { label = "Alle Charaktere", status = { text = sum .. " Stück", color = "textMuted" },
                 onClick = function() BG.sel = BG.ALL BG.Show() end }
    order[1] = BG.ALL
    for _, ch in ipairs(chars) do
        local c = st.chars[ch.key]
        local label = ch.name or "?"
        if ch.realm ~= myRealm then label = label .. "-" .. tostring(ch.realm) end
        local status = c.bank and { text = Count(c) .. " Stück", color = "textMuted" }
            or { text = Count(c) .. " · Bank unbekannt", color = "gold" }
        local key = ch.key
        items[#items + 1] = { label = label, status = status,
                              onClick = function() BG.sel = key BG.Show() end }
        order[#order + 1] = key
    end
    return items, order
end

local function Toggle(k) Set(k, not Get(k)) BG.Show() end

local function Inspector(chars)
    local iv = IV()
    local st = iv.Store(false)
    local rows = {}
    if BG.sel == BG.ALL then
        rows[#rows + 1] = { label = "Charaktere", value = tostring(#chars) }
        local unknown = 0
        for _, ch in ipairs(chars) do if not st.chars[ch.key].bank then unknown = unknown + 1 end end
        rows[#rows + 1] = { label = "Bank unbekannt", value = tostring(unknown) }
    else
        local c = st.chars[BG.sel]
        local function n(t) local x = 0 for _, v in pairs(t or {}) do x = x + v end return x end
        rows[#rows + 1] = { label = "Taschen", value = n(c.bags) .. " Stück" }
        rows[#rows + 1] = { label = "Angelegt", value = n(c.worn) .. " Stück" }
        rows[#rows + 1] = { label = "Bank", value = c.bank and (n(c.bank) .. " Stück") or "unbekannt" }
    end
    return {
        { type = "header", text = BG.sel == BG.ALL and "Alle Charaktere" or "Charakter" },
        { type = "rows", rows = rows },
        { type = "divider" },
        { type = "header", text = "Einstellungen" },
        { type = "button", label = "Im Tooltip zeigen: " .. (Get("invTooltip") and "an" or "aus"),
          onClick = function() Toggle("invTooltip") end },
        { type = "button", label = "Andere Realms: " .. (Get("invAllRealms") and "an" or "aus"),
          onClick = function() Toggle("invAllRealms") end },
        { type = "divider" },
        { type = "header", text = "Woher das stammt" },
        { type = "card", lines = {
            "Jeder Charakter merkt sich beim Einloggen",
            "Taschen und Ausrüstung, die Bank nur,",
            "solange sie offen ist. Post und Auktionen",
            "zählen nicht. Nur Anzeige: Gegenstände",
            "anderer Charaktere bewegt kein Addon.",
        }},
    }
end
BG.Inspector = Inspector

function BG.Show()
    local cp = WeintCodex.ContentPanel
    for _, child in pairs({ cp:GetChildren() }) do child:Hide() end
    local nav = WeintCodex.Navigation
    local iv = IV()
    local f = BuildPage()
    f:Show()
    WeintCodex.SetBreadcrumb("Taschen")
    if not iv then
        f.Foot:SetText("Der Bestand ist nicht geladen.")
        return
    end
    iv.ScanBags()
    local _, _, myRealm = iv.Me()
    local chars = BG.Chars()
    local known = BG.sel == BG.ALL
    for _, ch in ipairs(chars) do if ch.key == BG.sel then known = true end end
    if not known then BG.sel = BG.ALL end
    local items, order = SidebarItems(chars, myRealm)
    nav.BuildSidebar("Taschen", items)
    for i, key in ipairs(order) do
        if key == BG.sel and nav.SidebarButtons then
            local btn = nav.SidebarButtons()[i]
            if btn and btn.SetActive then btn:SetActive(true) end
        end
    end
    if BG.sel ~= BG.ALL then
        for i, key in ipairs(order) do
            if key == BG.sel then WeintCodex.SetBreadcrumb("Taschen", items[i].label) end
        end
    end
    nav.SetInspector(Inspector(chars))

    -- Filter: an = Akzent, aus = Flaeche.
    local a = C.accent
    for _, fb in ipairs(filterBtns) do
        local on = BG.filter[fb.key]
        if on then fb.bg:SetColorTexture(a[1], a[2], a[3], 0.25) else
            local s = C.surface2
            fb.bg:SetColorTexture(s[1], s[2], s[3], 1)
        end
        local c = on and C.textBright or C.textMuted
        fb.t:SetTextColor(c[1], c[2], c[3])
    end

    -- Raster: Breite und Hoehe aus der Karte.
    local w = Plain(f.Card:GetWidth()) or 460
    local h = Plain(f.Card:GetHeight()) or 360
    w = (type(w) == "number" and w or 460) - 40
    h = (type(h) == "number" and h or 360) - 58 - 34
    f.GridScroll:SetSize(w, math.max(60, h))
    f.GridBody:SetWidth(w - 10)
    BG.cols = BG.Columns(w - 14)
    if f.Search:GetText() ~= BG.query then f.Search:SetText(BG.query) end
    BG.DrawGrid()
    f.drawnWidth = Plain(f:GetWidth())
end

-- Neu zeichnen, wenn sich der Bestand aendert und die Seite offen ist.
function BG.Redraw()
    if not (page and page:IsShown()) then return end
    local main = WeintCodex.MainFrame
    if type(main) == "table" and main.IsShown and not main:IsShown() then return end
    BG.DrawGrid()
end
