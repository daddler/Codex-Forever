--------------------------------------------------
-- WeintCodex :: Buecher der Bibliothek (Seite im Codex, 6.59.0.0)
--------------------------------------------------
-- Wunsch: "eine Kategorie direkt im Codex unter Lehrer, Berufe etc., wo die
-- Buecher aufgelistet sind, mit kleiner Kartendarstellung und Questpfeil -
-- und geprueft auf Standort und Stufe, wo ich sie am besten sammle und was
-- abgeraten wird."
--
-- Links in der Unternavigation die Gruppen (Abgeben, Empfohlen, Moeglich,
-- Abgeraten, Abgegeben) - nie die 37 Buecher selbst, die Spalte darf nicht
-- ueberlaufen. Rechts oben der Stand mit den Schwellen der Belohnungen,
-- darunter die Liste (die eine Flaeche der Seite, die rollt). Ein Klick auf
-- ein Buch: im Detailbereich der Ausschnitt der Gebietskarte mit Punkt,
-- die Angaben und der Knopf fuer den Questpfeil.
--
-- Bewertung: modules/library.lua (LB.Rate) - Stufe vom Client, Stufen-
-- bereich des Gebiets (classic), Luftlinie. Mehr weiss niemand.
-- Die Karte: Kacheln, die der Client fuer die Gebietskarte nennt
-- (C_Map.GetMapArtLayerTextures) - kein geratener Pfad. Nennt er keine,
-- steht dort "Karte nicht verfuegbar".
--------------------------------------------------

WeintCodex.BooksPage = {}
local BP = WeintCodex.BooksPage
local C = WeintCodex.Colors

BP.HEAD = 84
BP.ROW_H = 44
BP.MAP_RATIO = 668 / 1002
BP.cat = "all"
-- Kurz unter den Marken: 20 und 25 liegen nah beieinander (Bild: die
-- Beschriftungen liefen ineinander).
BP.SHORT = { neck = "Halskette", ring = "Ring", library25 = "Bonus" }
BP.sel = nil            -- Abgabequest des gewaehlten Buches

local page
local rows = {}

local function LB() return WeintCodex.Library end
local function Plain(v)
    local K = WeintCodex.UIKit
    if K and K.Plain then return K.Plain(v) end
    return v
end
local function Col(name) return C[name] or C.textNormal end

function BP.Meters(yards)
    if not yards then return nil end
    if yards >= 1000 then return string.format("%.1f km", yards * 0.9144 / 1000) end
    return string.format("%d m", math.floor(yards * 0.9144 / 10 + 0.5) * 10)
end

local function CatOf(key)
    for _, c in ipairs(LB().CATS) do if c.key == key then return c end end
end

--------------------------------------------------
-- Pillen-Knopf (6.60.1.0, Beta-Test: "die Buttons fuer den Questpfeil
-- sehen noch nicht gut aus"). Die Knoepfe aus core/ui.lua runden ihre
-- Ecken mit der Farbe EINES Untergrunds ab - auf der hervorgehobenen Zeile
-- stimmte die nicht, die Ecken standen eckig da. Hier: zwei runde Kappen
-- und ein Mittelstueck, deckend - auf jedem Untergrund gleich.
--------------------------------------------------

local DISC = "Interface\\AddOns\\WeintCodex\\media\\ui\\disc"

local function Mix(a, b, k) return { a[1] + (b[1] - a[1]) * k, a[2] + (b[2] - a[2]) * k, a[3] + (b[3] - a[3]) * k } end

function BP.Pill(parent, text, opts)
    opts = opts or {}
    local h = opts.height or 24
    local b = CreateFrame("Button", nil, parent)
    b:SetHeight(h)
    b.mid = b:CreateTexture(nil, "BACKGROUND")
    b.mid:SetPoint("TOPLEFT", b, "TOPLEFT", h / 2, 0)
    b.mid:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -h / 2, 0)
    b.capL = b:CreateTexture(nil, "BACKGROUND")
    b.capL:SetTexture(DISC)
    b.capL:SetSize(h, h)
    b.capL:SetPoint("LEFT")
    b.capR = b:CreateTexture(nil, "BACKGROUND")
    b.capR:SetTexture(DISC)
    b.capR:SetSize(h, h)
    b.capR:SetPoint("RIGHT")
    b.label = WeintCodex.Label(b, text, { size = opts.size or 11, color = "textBright" })
    b.label:SetPoint("CENTER", b, "CENTER", 0, 0)
    b.primary = opts.primary
    function b:Paint(hot)
        local c
        if self.primary then
            c = Mix(C.bgDark, C.accent, hot and 0.55 or 0.40)
        else
            c = hot and C.borderStrong or C.surface3
        end
        self.mid:SetColorTexture(c[1], c[2], c[3], 1)
        self.capL:SetVertexColor(c[1], c[2], c[3], 1)
        self.capR:SetVertexColor(c[1], c[2], c[3], 1)
        local t = (hot or self.primary) and C.textBright or C.textNormal
        self.label:SetTextColor(t[1], t[2], t[3], 1)
    end
    b:SetScript("OnEnter", function(self) self:Paint(true) end)
    b:SetScript("OnLeave", function(self) self:Paint(false) end)
    b:Paint(false)
    return b
end

--------------------------------------------------
-- Kartenausschnitt
--------------------------------------------------

local map
function BP.MapWidget(parent, width)
    if not map then
        map = CreateFrame("Frame", nil, parent)
        map.tiles = {}
        map.bg = map:CreateTexture(nil, "BACKGROUND")
        map.bg:SetAllPoints(map)
        local s = C.surface2
        map.bg:SetColorTexture(s[1], s[2], s[3], 1)
        map.edge = WeintCodex.UIKit and WeintCodex.UIKit.Border(map, 1, 0, 0, 0, 1, "OVERLAY")
        map.ring = map:CreateTexture(nil, "OVERLAY", nil, 1)
        map.ring:SetTexture("Interface\\AddOns\\WeintCodex\\media\\ui\\disc")
        map.ring:SetSize(16, 16)
        map.dot = map:CreateTexture(nil, "OVERLAY", nil, 2)
        map.dot:SetTexture("Interface\\AddOns\\WeintCodex\\media\\ui\\disc")
        map.dot:SetSize(10, 10)
        map.none = WeintCodex.Label(map, "Karte nicht verfügbar", { size = 11, color = "textMuted" })
        map.none:SetPoint("CENTER")
    end
    map:SetParent(parent)
    map:SetSize(width, math.floor(width * BP.MAP_RATIO + 0.5))
    return map
end

-- Kacheln der Gebietskarte legen; true, wenn der Client sie genannt hat.
BP.mapExtra = {}
function BP.PaintMap(w, mapID, x, y)
    for _, t in ipairs(w.tiles) do t:Hide() end
    -- 6.144.0.1 (Beta-Test: Punkte der Haendler der Merkliste erschienen auf
    -- der Karte eines Rezepts): die Karte gibt es nur einmal. Zusaetzliche
    -- Punkte (w.extra) gelten nur bis zum naechsten Zeichnen; der eigene
    -- Punkt ist wieder da.
    for _, p in ipairs(BP.mapExtra) do p:Hide() end
    for i = #BP.mapExtra, 1, -1 do BP.mapExtra[i] = nil end
    w.ring:Show()
    w.dot:Show()
    local cm = _G.C_Map
    local W, H = Plain(w:GetWidth()) or 0, Plain(w:GetHeight()) or 0
    local ok = false
    if cm and cm.GetMapArtLayers and cm.GetMapArtLayerTextures and W > 0 then
        local okL, layers = pcall(cm.GetMapArtLayers, mapID)
        local L = okL and type(layers) == "table" and layers[1]
        local okT, tex = pcall(cm.GetMapArtLayerTextures, mapID, 1)
        if L and okT and type(tex) == "table" and #tex > 0 then
            local lw, lh = Plain(L.layerWidth), Plain(L.layerHeight)
            local tw, th = Plain(L.tileWidth), Plain(L.tileHeight)
            if type(lw) == "number" and type(tw) == "number" and lw > 0 and tw > 0 then
                local cols = math.ceil(lw / tw)
                local sx, sy = W / lw, H / lh
                for i, file in ipairs(tex) do
                    local col, row = (i - 1) % cols, math.floor((i - 1) / cols)
                    local x0, y0 = col * tw, row * th
                    if x0 < lw and y0 < lh then
                        local t = w.tiles[i]
                        if not t then
                            t = w:CreateTexture(nil, "ARTWORK")
                            w.tiles[i] = t
                        end
                        local cw, ch = math.min(tw, lw - x0), math.min(th, lh - y0)
                        t:SetTexture(file)
                        t:SetTexCoord(0, cw / tw, 0, ch / th)
                        t:ClearAllPoints()
                        t:SetPoint("TOPLEFT", w, "TOPLEFT", x0 * sx, -y0 * sy)
                        t:SetSize(cw * sx, ch * sy)
                        t:Show()
                    end
                end
                ok = true
            end
        end
    end
    w.none:SetShown(not ok)
    local g, ink = C.gold, C.bgDark or C.surface1
    w.ring:SetVertexColor(ink[1], ink[2], ink[3], 1)
    w.dot:SetVertexColor(g[1], g[2], g[3], 1)
    w.ring:ClearAllPoints()
    w.ring:SetPoint("CENTER", w, "TOPLEFT", W * x, -H * y)
    w.dot:ClearAllPoints()
    w.dot:SetPoint("CENTER", w.ring, "CENTER")
    BP.mapOk = ok
    return ok
end

--------------------------------------------------
-- Seite
--------------------------------------------------

local function Row(i, body)
    local r = rows[i]
    if r then return r end
    r = CreateFrame("Button", nil, body)
    r:SetHeight(BP.ROW_H)
    r.bg = r:CreateTexture(nil, "BACKGROUND")
    r.bg:SetAllPoints(r)
    r.dot = r:CreateTexture(nil, "ARTWORK")
    r.dot:SetTexture("Interface\\AddOns\\WeintCodex\\media\\ui\\disc")
    r.dot:SetSize(8, 8)
    r.dot:SetPoint("LEFT", r, "LEFT", 12, 0)
    r.name = WeintCodex.Label(r, "", { size = 13, color = "textBright" })
    r.name:SetPoint("TOPLEFT", r, "TOPLEFT", 28, -7)
    r.name:SetPoint("RIGHT", r, "RIGHT", -110, 0)
    r.name:SetJustifyH("LEFT")
    r.sub = WeintCodex.Label(r, "", { size = 11, color = "textMuted" })
    r.sub:SetPoint("TOPLEFT", r.name, "BOTTOMLEFT", 0, -3)
    r.sub:SetPoint("RIGHT", r, "RIGHT", -110, 0)
    r.sub:SetJustifyH("LEFT")
    r.go = BP.Pill(r, "Pfeil hierhin", { height = 24 })
    r.go:SetWidth(96)
    r.go:SetPoint("RIGHT", r, "RIGHT", -10, 0)
    r:SetScript("OnEnter", function(self) self._hot = true BP.PaintRow(self) end)
    r:SetScript("OnLeave", function(self) self._hot = nil BP.PaintRow(self) end)
    r:SetScript("OnClick", function(self)
        if self.stepIndex then
            BP.selStep = self.stepIndex
        else
            BP.sel = self.entry and self.entry.b[1]
        end
        BP.Show()
    end)
    rows[i] = r
    return r
end

function BP.PaintRow(r)
    local on
    if r.stepIndex then on = r.stepIndex == BP.selStep else on = r.entry and r.entry.b[1] == BP.sel end
    local s = (on and C.surface3) or (r._hot and C.surface2) or C.surface1
    r.bg:SetColorTexture(s[1], s[2], s[3], (on or r._hot) and 1 or 0)
end

local function BuildPage()
    if page then return page end
    local cp = WeintCodex.ContentPanel
    local f = CreateFrame("Frame", nil, cp)
    f:SetAllPoints(cp)
    local M = WeintCodex.Metrics
    f.Head = WeintCodex.PageHead(f, {
        eyebrow = "Leveln",
        title   = "Bücher der Bibliothek",
        sub     = "Wo sie liegen, was zu deiner Stufe passt – und wie weit es bis zur nächsten Belohnung ist.",
        height  = BP.HEAD,
    })
    local card = WeintCodex.CreateSurface(f, { tone = "plain", radius = 14, backdrop = "bgDark" })
    card:SetPoint("TOPLEFT", f, "TOPLEFT", M.PAD_X, -(M.PAD_Y + BP.HEAD))
    card:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -M.PAD_X, M.PAD_Y)
    f.Card = card

    -- Stand: Zahl, Leiste, Marken der Schwellen.
    f.Count = WeintCodex.Label(card, "", { size = 15, color = "textBright" })
    f.Count:SetPoint("TOPLEFT", card, "TOPLEFT", 20, -18)
    f.Goal = WeintCodex.Label(card, "", { size = 12, color = "textMuted" })
    f.Goal:SetPoint("LEFT", f.Count, "RIGHT", 12, 0)
    f.Track = card:CreateTexture(nil, "ARTWORK")
    f.Track:SetPoint("TOPLEFT", card, "TOPLEFT", 20, -46)
    f.Track:SetPoint("TOPRIGHT", card, "TOPRIGHT", -20, -46)
    f.Track:SetHeight(6)
    local s = C.surface3
    f.Track:SetColorTexture(s[1], s[2], s[3], 1)
    f.Fill = card:CreateTexture(nil, "ARTWORK", nil, 1)
    f.Fill:SetPoint("TOPLEFT", f.Track, "TOPLEFT")
    f.Fill:SetHeight(6)
    f.Ticks = {}

    f.ListScroll, f.ListBody = WeintCodex.CreateScrollArea(card, 12, -84, 400, 300, true)
    f.Foot = WeintCodex.Label(card, "", { size = 11, color = "textFaint" })
    f.Foot:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 20, 12)
    f:SetScript("OnSizeChanged", function(self, width)
        width = Plain(width)
        if self:IsShown() and type(width) == "number" and type(self.drawnWidth) == "number"
           and math.abs(width - self.drawnWidth) > 2 then
            BP.Show()
        end
    end)
    page = f
    BP.page = f
    return f
end

local function PaintProgress(f, p)
    local lb = LB()
    if not p then
        f.Count:SetText("Stand unbekannt")
        f.Goal:SetText("Das Spiel nennt nicht, welche Bücher abgegeben sind.")
        f.Fill:Hide()
        for _, t in ipairs(f.Ticks) do t:Hide() end
        return
    end
    f.Count:SetText(p.done .. " von " .. p.total .. " abgegeben")
    f.Goal:SetText(lb.Line(p) or "")
    local w = Plain(f.Track:GetWidth()) or 0
    local max = math.max(p.total, 1)
    local a = C.accent
    f.Fill:SetColorTexture(a[1], a[2], a[3], 1)
    f.Fill:SetWidth(math.max(1, w * math.min(p.done, max) / max))
    f.Fill:SetShown(p.done > 0)
    for i, r in ipairs(WeintCodex.BooksData.rewards) do
        local t = f.Ticks[i]
        if not t then
            t = { mark = f.Card:CreateTexture(nil, "OVERLAY"), text = WeintCodex.Label(f.Card, "", { size = 10, color = "textMuted" }) }
            f.Ticks[i] = t
        end
        local x = w * math.min(r.goal, max) / max
        t.mark:SetSize(2, 12)
        local got = p.done >= r.goal
        local c = got and C.gold or C.textMuted
        t.mark:SetColorTexture(c[1], c[2], c[3], 1)
        t.mark:ClearAllPoints()
        t.mark:SetPoint("CENTER", f.Track, "LEFT", x, 0)
        t.text:SetText(r.goal .. " " .. (BP.SHORT[r.key] or ""))
        t.text:ClearAllPoints()
        t.text:SetPoint("TOP", t.mark, "BOTTOM", 0, -2)
        t.mark:Show()
        t.text:Show()
    end
end

local function SidebarItems(list)
    local n = { all = #list }
    for _, e in ipairs(list) do n[e.cat] = (n[e.cat] or 0) + 1 end
    local items, order = {}, {}
    items[1] = { label = "Alle Bücher", status = { text = tostring(#list), color = "textMuted" },
                 onClick = function() BP.cat = "all" BP.Show() end }
    order[1] = "all"
    for _, c in ipairs(LB().CATS) do
        if (n[c.key] or 0) > 0 then
            local key = c.key
            items[#items + 1] = { label = c.label, status = { text = tostring(n[key]), color = c.color },
                                  onClick = function() BP.cat = key BP.Show() end }
            order[#order + 1] = key
        end
    end
    -- 1.4.0.0: der Gemuetliche Schlafsack, eine versteckte Questreihe.
    local SB = WeintCodex.SleepingBag
    if SB and WeintCodex.SleepingBagData then
        local p = SB.Progress()
        items[#items + 1] = { label = "Schlafsack",
            status = { text = p and (p.done .. "/" .. p.total) or "?", color = (p and not p.current) and "success" or "textMuted" },
            onClick = function() BP.cat = "sleepingbag" BP.Show() end }
        order[#order + 1] = "sleepingbag"
    end
    return items, order
end

local function Inspector(e, p)
    local lb = LB()
    if not e then
        return {
            { type = "header", text = "So wird bewertet" },
            { type = "card", lines = {
                "Empfohlen: Gebiet passt zu deiner Stufe,",
                "auf deinem Kontinent – das nächste zuerst.",
                "Abgeraten: das Gebiet beginnt mehr als",
                lb.TOO_HIGH .. " Stufen über dir.",
                "Möglich: passt, aber anderer Kontinent.",
            }},
            { type = "divider" },
            { type = "header", text = "Woher das stammt" },
            { type = "card", lines = {
                "Was abgegeben ist, sagt das Spiel.",
                "Fundorte und Belohnungen: unbestätigt,",
                "Wissensstand aus der Beta. Stufen der",
                "Gebiete aus Classic.",
            }},
        }
    end
    local b = e.b
    local cat = CatOf(e.cat)
    local zone = lb.ZoneName(b[5]) or "Gebiet unbekannt"
    local lo, hi = lb.ZoneLevel(b[5])
    local rowsI = {
        { label = "Gebiet", value = zone },
        { label = "Fundort", value = string.format("%.1f, %.1f", b[6], b[7]) },
        { label = "Stufe des Gebiets", value = lo and (lo .. "–" .. hi) or "unbekannt" },
    }
    if e.dist then rowsI[#rowsI + 1] = { label = "Luftlinie", value = BP.Meters(e.dist) } end
    rowsI[#rowsI + 1] = { label = "Einschätzung", value = cat and cat.label or "?" }
    local blocks = {
        { type = "header", text = lb.BookName(b) },
        { type = "custom", create = function(parent, width)
            local w = BP.MapWidget(parent, width)
            BP.PaintMap(w, b[5], b[6] / 100, b[7] / 100)
            return w
        end },
        { type = "rows", rows = rowsI },
        { type = "text", text = e.why },
    }
    if e.cat ~= "done" and e.cat ~= "bag" then
        blocks[#blocks + 1] = { type = "custom", create = function(parent, width)
            if not BP.guideBtn then BP.guideBtn = BP.Pill(parent, "Questpfeil hierhin", { height = 32, size = 12, primary = true }) end
            local g = BP.guideBtn
            g:SetWidth(width)
            g:SetScript("OnClick", function() lb.Guide(b) end)
            g:Paint(false)
            return g
        end }
    elseif e.cat == "bag" then
        local who, place = lb.Librarian()
        if who then blocks[#blocks + 1] = { type = "text", text = "Abgeben bei " .. who .. ", " .. place .. "." } end
    end
    blocks[#blocks + 1] = { type = "divider" }
    blocks[#blocks + 1] = { type = "text", text = "Unbestätigt – Wissensstand aus der Beta." }
    return blocks
end

function BP.Show()
    local cp = WeintCodex.ContentPanel
    for _, child in pairs({ cp:GetChildren() }) do child:Hide() end
    local nav = WeintCodex.Navigation
    local f = BuildPage()
    f:Show()
    WeintCodex.SetBreadcrumb("Bücher")
    local lb = LB()
    if not (lb and WeintCodex.BooksData) then
        f.Foot:SetText("Der Bestand der Bücher ist nicht geladen.")
        return
    end
    local p = lb.Progress()
    local all = lb.Rated()
    local items, order = SidebarItems(all)
    local known = false
    for _, k in ipairs(order) do if k == BP.cat then known = true end end
    if not known then BP.cat = "all" end
    nav.BuildSidebar("Bücher", items)
    for i, key in ipairs(order) do
        if key == BP.cat and nav.SidebarButtons then
            local btn = nav.SidebarButtons()[i]
            if btn and btn.SetActive then btn:SetActive(true) end
            if key ~= "all" then WeintCodex.SetBreadcrumb("Bücher", items[i].label) end
        end
    end
    if BP.cat == "sleepingbag" then
        BP.ShowBag(f)
        return
    end
    local list, chosen = {}, nil
    for _, e in ipairs(all) do
        if BP.cat == "all" or e.cat == BP.cat then list[#list + 1] = e end
        if e.b[1] == BP.sel then chosen = e end
    end
    nav.SetInspector(Inspector(chosen, p))

    PaintProgress(f, p)
    local w = Plain(f.Card:GetWidth()) or 460
    local h = Plain(f.Card:GetHeight()) or 360
    w = (type(w) == "number" and w or 460) - 24
    h = (type(h) == "number" and h or 360) - 84 - 34
    f.ListScroll:SetSize(w, math.max(60, h))
    f.ListBody:SetWidth(w - 10)
    for i, e in ipairs(list) do
        local r = Row(i, f.ListBody)
        r.entry, r.stepIndex = e, nil
        r:ClearAllPoints()
        r:SetPoint("TOPLEFT", f.ListBody, "TOPLEFT", 0, -(i - 1) * BP.ROW_H)
        r:SetPoint("RIGHT", f.ListBody, "RIGHT", 0, 0)
        local cat = CatOf(e.cat)
        local c = Col(cat and cat.color or "textMuted")
        r.dot:SetVertexColor(c[1], c[2], c[3], 1)
        r.name:SetText(lb.BookName(e.b))
        local zone = lb.ZoneName(e.b[5]) or "?"
        local sub = zone .. " · " .. e.why
        if e.dist then sub = sub .. " · " .. BP.Meters(e.dist) end
        r.sub:SetText(sub)
        local book = e.b
        r.go:SetShown(e.cat ~= "done" and e.cat ~= "bag")
        r.go:SetScript("OnClick", function() lb.Guide(book) end)
        BP.PaintRow(r)
        r:Show()
    end
    for i = #list + 1, #rows do rows[i]:Hide() end
    f.ListBody:SetHeight(math.max(1, #list * BP.ROW_H))
    f.Foot:SetText(#list == 0 and "Hier ist nichts." or "Klick auf ein Buch: Karte und Angaben rechts.")
    f.drawnWidth = Plain(f:GetWidth())
end

--------------------------------------------------
-- Gemuetlicher Schlafsack (1.4.0.0): dieselbe Seite, die Schritte statt
-- der Buecher - Stand oben, Liste in Reihenfolge, rechts Karte, Hinweis
-- und Questpfeil. Bestand data/sleepingbag.lua, Stand modules/sleepingbag.lua.
--------------------------------------------------

local function BagInspector(step, i, state)
    local SB, lb = WeintCodex.SleepingBag, LB()
    local d = WeintCodex.SleepingBagData
    if not step then
        return {
            { type = "header", text = "Gemütlicher Schlafsack" },
            { type = "card", lines = {
                "Eine versteckte Questreihe quer durch",
                "Azeroth: an jedem Ort etwas anklicken,",
                "am Ende liegt der Schlafsack in der",
                "Tasche. Ab Stufe " .. d.level .. ".",
            }},
            { type = "divider" },
            { type = "header", text = "Woher das stammt" },
            { type = "card", lines = {
                "Was erledigt ist, sagt das Spiel.",
                "Orte und Wege: unbestätigt,",
                "Wissensstand aus der Beta.",
            }},
        }
    end
    local zone = lb.ZoneName(step.map) or "Gebiet unbekannt"
    local blocks = {
        { type = "header", text = (i and (i .. ". ") or "") .. SB.Name(step) },
        { type = "custom", create = function(parent, width)
            local w = BP.MapWidget(parent, width)
            BP.PaintMap(w, step.map, step.x / 100, step.y / 100)
            return w
        end },
        { type = "rows", rows = {
            { label = "Gebiet", value = zone },
            { label = "Ort", value = step.place },
            { label = "Fundort", value = string.format("%.1f, %.1f", step.x, step.y) },
            { label = "Stand", value = state },
        }},
        { type = "text", text = step.tip },
    }
    if state ~= "erledigt" then
        blocks[#blocks + 1] = { type = "custom", create = function(parent, width)
            if not BP.bagGuideBtn then BP.bagGuideBtn = BP.Pill(parent, "Questpfeil hierhin", { height = 32, size = 12, primary = true }) end
            local g = BP.bagGuideBtn
            g:SetWidth(width)
            g:SetScript("OnClick", function() SB.Guide(step) end)
            g:Paint(false)
            return g
        end }
    end
    blocks[#blocks + 1] = { type = "divider" }
    blocks[#blocks + 1] = { type = "text", text = "Unbestätigt – Wissensstand aus der Beta." }
    return blocks
end

function BP.ShowBag(f)
    local SB, lb = WeintCodex.SleepingBag, LB()
    local d = WeintCodex.SleepingBagData
    local nav = WeintCodex.Navigation
    local steps = SB.Steps()
    local p = SB.Progress()
    local list = {}
    for i, st in ipairs(steps) do list[#list + 1] = { step = st, index = i } end
    if d.optional then list[#list + 1] = { step = d.optional, index = #steps + 1, optional = true } end

    local function State(e)
        local v = SB.StepDone(e.step)
        if v == nil then return "unbekannt" end
        if v then return "erledigt" end
        if e.optional then return "nebenbei" end
        if p and p.current == e.index then return "als Nächstes" end
        return "offen"
    end

    -- Stand oben: Zahl und Leiste, keine Marken.
    for _, t in ipairs(f.Ticks) do t.mark:Hide() t.text:Hide() end
    if not p then
        f.Count:SetText("Stand unbekannt")
        f.Goal:SetText("Das Spiel nennt nicht, welche Schritte erledigt sind.")
        f.Fill:Hide()
    else
        f.Count:SetText(p.current and ("Schritt " .. p.current .. " von " .. p.total) or "Schlafsack erhalten")
        local lvl = SB.LevelOk()
        f.Goal:SetText(p.current and (lvl == false and ("Ab Stufe " .. d.level .. " – noch zu früh.") or (p.done .. " von " .. p.total .. " erledigt"))
            or "Alle Schritte erledigt.")
        local w = Plain(f.Track:GetWidth()) or 0
        local a = C.accent
        f.Fill:SetColorTexture(a[1], a[2], a[3], 1)
        f.Fill:SetWidth(math.max(1, w * p.done / math.max(1, p.total)))
        f.Fill:SetShown(p.done > 0)
    end

    local chosen
    for _, e in ipairs(list) do if e.index == BP.selStep then chosen = e end end
    nav.SetInspector(BagInspector(chosen and chosen.step, chosen and not chosen.optional and chosen.index or nil,
        chosen and State(chosen)))

    local w = Plain(f.Card:GetWidth()) or 460
    local h = Plain(f.Card:GetHeight()) or 360
    w = (type(w) == "number" and w or 460) - 24
    h = (type(h) == "number" and h or 360) - 84 - 34
    f.ListScroll:SetSize(w, math.max(60, h))
    f.ListBody:SetWidth(w - 10)
    for i, e in ipairs(list) do
        local r = Row(i, f.ListBody)
        r.entry, r.stepIndex = nil, e.index
        r:ClearAllPoints()
        r:SetPoint("TOPLEFT", f.ListBody, "TOPLEFT", 0, -(i - 1) * BP.ROW_H)
        r:SetPoint("RIGHT", f.ListBody, "RIGHT", 0, 0)
        local state = State(e)
        local c = Col((state == "erledigt" and "success") or (state == "als Nächstes" and "accent") or "textMuted")
        r.dot:SetVertexColor(c[1], c[2], c[3], 1)
        r.name:SetText(e.optional and ("Nebenbei: " .. SB.Name(e.step) .. (e.step.quest and (" („" .. e.step.quest .. "“)") or ""))
            or (e.index .. ". " .. SB.Name(e.step)))
        r.sub:SetText((lb.ZoneName(e.step.map) or "?") .. " · " .. e.step.place .. " · " .. state)
        local step = e.step
        r.go:SetShown(state ~= "erledigt")
        r.go:SetScript("OnClick", function() SB.Guide(step) end)
        BP.PaintRow(r)
        r:Show()
    end
    for i = #list + 1, #rows do rows[i]:Hide() end
    f.ListBody:SetHeight(math.max(1, #list * BP.ROW_H))
    f.Foot:SetText("Klick auf einen Schritt: Karte, Weg und Questpfeil rechts.")
    f.drawnWidth = Plain(f:GetWidth())
end
