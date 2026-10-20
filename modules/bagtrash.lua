--------------------------------------------------
-- WeintCodex :: Taschen, Reiter "Ausmisten"
--------------------------------------------------
-- Die guenstigsten Plaetze der eigenen Taschen (Bewertung in
-- ui/bagtriage.lua, WeintCodex.UIBagTriage - laedt spaeter, nur zur
-- Laufzeit gelesen): Symbol, Name, Anzahl, Wert mit Herkunft, Grund und je
-- Zeile "Behalten". Oben die Belegung frei/gesamt und der Gesamtwert der
-- Vorschlaege. Kein Rollen: so viele Zeilen, wie die Karte traegt, der Rest
-- als Zahl ("und 12 weitere"). Geloescht wird hier nichts.
--------------------------------------------------

WeintCodex.BagTrash = {}
local BTP = WeintCodex.BagTrash
local C = WeintCodex.Colors

BTP.ROW = 30
BTP.HEAD = 84
BTP.TOP = 50            -- Kopf der Karte (Belegung, Summe)
BTP.FOOT = 34

local page
local rows = {}

local function T() return WeintCodex.UIBagTriage end
local function Plain(v)
    local K = WeintCodex.UIKit
    if K and K.Plain then return K.Plain(v) end
    return v
end

local function Row(i)
    local r = rows[i]
    if r then return r end
    r = CreateFrame("Button", nil, page.Card)
    r:SetHeight(BTP.ROW - 2)
    r.bg = r:CreateTexture(nil, "BACKGROUND")
    r.bg:SetAllPoints(r)
    local s = C.surface2
    r.bg:SetColorTexture(s[1], s[2], s[3], 1)
    r.icon = r:CreateTexture(nil, "ARTWORK")
    r.icon:SetSize(22, 22)
    r.icon:SetPoint("LEFT", r, "LEFT", 4, 0)
    r.name = WeintCodex.Label(r, "", { size = 12, color = "textBright" })
    r.name:SetPoint("LEFT", r.icon, "RIGHT", 8, 0)
    r.keep = CreateFrame("Button", nil, r)
    r.keep:SetSize(76, 22)
    r.keep:SetPoint("RIGHT", r, "RIGHT", -4, 0)
    r.keep.bg = r.keep:CreateTexture(nil, "BACKGROUND")
    r.keep.bg:SetAllPoints(r.keep)
    local a = C.accent
    r.keep.bg:SetColorTexture(a[1], a[2], a[3], 0.22)
    r.keep.t = WeintCodex.Label(r.keep, "Behalten", { size = 11, color = "textBright" })
    r.keep.t:SetPoint("CENTER", r.keep, "CENTER", 0, 0)
    r.keep:SetScript("OnClick", function(self)
        local bt = T()
        if bt and self.id then bt.SetKept(self.id, true) end
        BTP.Draw()
    end)
    r.why = WeintCodex.Label(r, "", { size = 11, color = "textMuted" })
    r.why:SetPoint("RIGHT", r.keep, "LEFT", -10, 0)
    r.value = WeintCodex.Label(r, "", { size = 12, color = "textBright", justify = "RIGHT" })
    r.value:SetPoint("RIGHT", r.why, "LEFT", -12, 0)
    r:SetScript("OnEnter", function(self)
        local gt = _G.GameTooltip
        if not (gt and self.bag) then return end
        gt:SetOwner(self, "ANCHOR_RIGHT")
        if gt.SetBagItem then pcall(gt.SetBagItem, gt, self.bag, self.slot) end
        gt:Show()
    end)
    r:SetScript("OnLeave", function() if _G.GameTooltip then _G.GameTooltip:Hide() end end)
    rows[i] = r
    return r
end

local function BuildPage()
    if page then return page end
    local cp = WeintCodex.ContentPanel
    local f = CreateFrame("Frame", nil, cp)
    f:SetAllPoints(cp)
    local M = WeintCodex.Metrics
    f.Head = WeintCodex.PageHead(f, {
        eyebrow = "Taschen",
        title   = "Ausmisten",
        sub     = "Was in deinen Taschen am wenigsten wert ist – und was beim Looten Platz machen könnte. Gelöscht wird nur von dir.",
        height  = BTP.HEAD,
    })
    local card = WeintCodex.CreateSurface(f, { tone = "plain", radius = 14, backdrop = "bgDark" })
    card:SetPoint("TOPLEFT", f, "TOPLEFT", M.PAD_X, -(M.PAD_Y + BTP.HEAD))
    card:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -M.PAD_X, M.PAD_Y)
    f.Card = card
    f.Slots = WeintCodex.Label(card, "", { size = 13, color = "textBright" })
    f.Slots:SetPoint("TOPLEFT", card, "TOPLEFT", 20, -18)
    f.Sum = WeintCodex.Label(card, "", { size = 13, color = "gold", justify = "RIGHT" })
    f.Sum:SetPoint("TOPRIGHT", card, "TOPRIGHT", -20, -18)
    f.Foot = WeintCodex.Label(card, "", { size = 11, color = "textFaint" })
    f.Foot:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 20, 12)
    page = f
    BTP.page = f
    return f
end

-- So viele Zeilen, wie die Karte traegt (nichts muss rollen).
function BTP.Capacity(height)
    height = type(height) == "number" and height or 360
    return math.max(1, math.floor((height - BTP.TOP - BTP.FOOT) / BTP.ROW))
end

local function Toggle(k)
    local K = WeintCodex.UIKit
    if K then K.Set("comfort", k, not K.Get("comfort", k)) end
    local bt = T()
    if bt then bt.dirty = true end
    BTP.Draw()
end

function BTP.Inspector()
    local K = WeintCodex.UIKit
    local function on(k) return K and K.Get("comfort", k) and "an" or "aus" end
    local bt = T()
    local blocks = {
        { type = "header", text = "Einstellungen" },
        { type = "button", label = "Ausmisten: " .. on("triageOn"), onClick = function() Toggle("triageOn") end },
        { type = "button", label = "Auch Grünes vorschlagen: " .. on("triageGreens"), onClick = function() Toggle("triageGreens") end },
        { type = "button", label = "Auktionspreis zählen: " .. on("triageAuction"), onClick = function() Toggle("triageAuction") end },
        { type = "divider" },
        { type = "header", text = "Behalten" },
    }
    local keep = bt and bt.KeepStore(false)
    local ids = {}
    for id in _G.next, keep or {} do ids[#ids + 1] = id end
    table.sort(ids)
    if #ids == 0 then
        blocks[#blocks + 1] = { type = "text", text = "Nichts gemerkt – „Behalten“ an einer Zeile schützt den Gegenstand." }
    end
    for i = 1, math.min(5, #ids) do
        local id = ids[i]
        local nm = bt.ItemInfo(id) or ("#" .. id)
        blocks[#blocks + 1] = { type = "button", label = "Nicht mehr: " .. WeintCodex.Truncate(nm, 26),
            onClick = function() bt.SetKept(id, false) BTP.Draw() end }
    end
    if #ids > 5 then blocks[#blocks + 1] = { type = "text", text = "und " .. (#ids - 5) .. " weitere" } end
    blocks[#blocks + 1] = { type = "divider" }
    blocks[#blocks + 1] = { type = "card", lines = {
        "Vorgeschlagen wird Graues, dazu Weißes",
        "mit Händlerpreis. Nie: Questgegenstände,",
        "Verbrauchbares, Material, Behälter, Munition,",
        "Rezepte, Schlüssel, alles ohne Händlerpreis.",
        "Beim Looten mit vollen Taschen: Münze an der",
        "Beute, die mehr wert ist; der Platz leuchtet.",
    }}
    return blocks
end

function BTP.Draw()
    local cp = WeintCodex.ContentPanel
    for _, child in pairs({ cp:GetChildren() }) do child:Hide() end
    local f = BuildPage()
    f:Show()
    WeintCodex.SetBreadcrumb("Taschen", "Ausmisten")
    WeintCodex.Navigation.SetInspector(BTP.Inspector())
    local bt = T()
    if not bt then
        f.Slots:SetText("Die Bewertung ist nicht geladen.")
        f.Sum:SetText("")
        f.Foot:SetText("")
        for _, r in ipairs(rows) do r:Hide() end
        return
    end
    if not bt.Active() then
        f.Slots:SetText("Ausmisten ist aus – rechts einschalten.")
        f.Sum:SetText("")
        f.Foot:SetText("")
        for _, r in ipairs(rows) do r:Hide() end
        return
    end
    bt.dirty = true
    local cand = bt.Candidates()
    local st = bt.stats
    if st.known then
        f.Slots:SetText("Taschenplätze: " .. st.free .. " frei von " .. st.total
            .. (st.free <= bt.NEAR_FULL and "  · fast voll" or ""))
    else
        f.Slots:SetText("Taschenplätze: unbekannt")
    end
    f.Sum:SetText(#cand > 0 and ("Vorschläge zusammen: " .. bt.Money(bt.TotalValue())) or "")
    local w = Plain(f.Card:GetWidth())
    local h = Plain(f.Card:GetHeight())
    w = (type(w) == "number" and w or 460) - 40
    local cap = BTP.Capacity(h)
    local n = math.min(cap, #cand)
    local maxName = math.max(12, math.floor((w - 380) / 7))
    for i = 1, n do
        local e, r = cand[i], Row(i)
        r:ClearAllPoints()
        r:SetPoint("TOPLEFT", f.Card, "TOPLEFT", 20, -(BTP.TOP + (i - 1) * BTP.ROW))
        r:SetWidth(w)
        r.bag, r.slot, r.keep.id = e.bag, e.slot, e.id
        r.icon:SetTexture(e.icon)
        r.name:SetText(WeintCodex.Truncate(e.name, maxName) .. (e.count > 1 and ("  ×" .. e.count) or ""))
        r.value:SetText(bt.Money(e.value))
        r.why:SetText(e.reason)
        r:Show()
    end
    for i = n + 1, #rows do rows[i]:Hide() end
    local foot = {}
    if #cand == 0 then foot[#foot + 1] = "Nichts zum Ausmisten – kein Grau, nichts Billiges ohne Schutz." end
    if #cand > n then foot[#foot + 1] = "und " .. (#cand - n) .. " weitere" end
    if st.unknown > 0 then foot[#foot + 1] = st.unknown .. " ohne Preisangabe – Wert unbekannt, nie vorgeschlagen" end
    f.Foot:SetText(table.concat(foot, " · "))
end

-- Neu zeichnen, wenn sich die Taschen aendern und die Seite offen ist.
function BTP.Redraw()
    if not (page and page:IsShown()) then return end
    local main = WeintCodex.MainFrame
    if type(main) == "table" and main.IsShown and not main:IsShown() then return end
    BTP.Draw()
end
