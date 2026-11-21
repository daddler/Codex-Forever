--------------------------------------------------
-- WeintCodex :: Ruf-Belohnungen (Seite "Entdecken", 1.0.8.10)
--------------------------------------------------
-- Rueckmeldung (Bild des Berichts): der Knopf am Ruffenster oeffnete ein
-- Kopierfenster mit Gegenstandsnummern statt Namen ("#274745"), Preisen als
-- nackte Zahlen ("1 10 42" - die Muenzbilder fallen im Kopiertext weg), der
-- Rufstufe als Zahl ("du: 1") und den Fraktionen der anderen Seite. Das war
-- ein Bericht, keine Ansicht.
--
-- Jetzt eine Seite unter "Entdecken", gebaut wie Buecher und Schlafsack:
-- oben der Stand, darunter die Fraktionen; ein Klick klappt die
-- Belohnungen der Fraktion auf - mit Symbol, Name in der Farbe der
-- Qualitaet, Rufstufe, Preis und Tooltip. Gruen: mit deinem Ruf schon
-- kaeuflich. Rechts der Ruestmeister mit Karte und Questpfeil.
--
-- Bestand: data/reprewards.lua (erzeugt, `community`). Namen, Symbole,
-- Qualitaet und der eigene Ruf nur vom Client (Namen ueber
-- WeintCodex.LootBook.Info, das schon mit langsam ladenden Gegenstaenden
-- umgehen kann). Fraktionen, bei denen du "Hasserfuellt" bist, sind die der
-- anderen Seite - sie stehen nicht in der Liste (die Zahl steht unten).
--------------------------------------------------

local BP = WeintCodex.BooksPage
local C = WeintCodex.Colors

BP.repSel = nil         -- gewaehlte Fraktion (aufgeklappt)
BP.REP_HIDE_BELOW = 2   -- Rufstufe 1 (Hasserfuellt): andere Seite

local function Plain(v)
    local K = WeintCodex.UIKit
    if K and K.Plain then return K.Plain(v) end
    return v
end
local function Col(name) return C[name] or C.textNormal end
local function FJ() return WeintCodex.UIFieldJournal end
local function Data() return WeintCodex.RepRewardsData end

-- Deine Rufstufe bei der Fraktion (1..8) oder nil.
function BP.RepStanding(fid)
    local cr = _G.C_Reputation
    if not (cr and cr.GetFactionDataByID) then return nil end
    local ok, d = pcall(cr.GetFactionDataByID, fid)
    local r = ok and type(d) == "table" and Plain(d.reaction) or nil
    return type(r) == "number" and r or nil
end

function BP.StandingName(n)
    local f = FJ()
    return (f and f.STANDING and f.STANDING[n]) or (n and ("Stufe " .. n)) or "unbekannt"
end

local function Money(c)
    local AP = WeintCodex.UIAuctionPrices
    if type(c) ~= "number" then return nil end
    return AP and AP.Money and AP.Money(c) or (c .. " Kupfer")
end

-- Fraktionen der eigenen Seite, bekannte zuerst (hoechster Ruf oben).
function BP.RepFactions()
    local d = Data()
    local list, hidden = {}, 0
    if not d then return list, hidden end
    for fid, f in pairs(d.factions) do
        local st = BP.RepStanding(fid)
        if st and st < BP.REP_HIDE_BELOW then
            hidden = hidden + 1
        else
            local total, reach = 0, 0
            for _, tier in ipairs(f.tiers) do
                total = total + #tier[2]
                if st and st >= tier[1] then reach = reach + #tier[2] end
            end
            local fj = FJ()
            list[#list + 1] = { fid = fid, f = f, standing = st, total = total, reach = reach,
                                name = fj and fj.FactionName and fj.FactionName(fid) or f.name }
        end
    end
    table.sort(list, function(a, b)
        local sa, sb = a.standing or 0, b.standing or 0
        if sa ~= sb then return sa > sb end
        return a.name < b.name
    end)
    return list, hidden
end

local function Info(id)
    local LBk = WeintCodex.LootBook
    return LBk and LBk.Info and LBk.Info(id) or {}
end

local function QmText(f)
    if not f.qm then return nil end
    local lb = WeintCodex.Library
    local zone = lb and lb.ZoneName and lb.ZoneName(f.qm[2])
    return f.qm[1] .. (zone and (", " .. zone) or "")
end

function BP.RepGuide(f, name)
    local QA = WeintCodex.UIQuestArrow
    if not (f and f.qm and QA and QA.SetCustom) then return false end
    QA.SetCustom({ map = f.qm[2], x = f.qm[3] / 100, y = f.qm[4] / 100,
                   title = "Rüstmeister: " .. f.qm[1] .. (name and (" (" .. name .. ")") or "") })
    return true
end

-- Zeilen der Liste: Fraktionen, unter der gewaehlten ihre Belohnungen.
function BP.RepRows()
    local list, hidden = BP.RepFactions()
    local out = {}
    for _, e in ipairs(list) do
        out[#out + 1] = { faction = e }
        if e.fid == BP.repSel then
            for _, tier in ipairs(e.f.tiers) do
                for _, id in ipairs(tier[2]) do
                    out[#out + 1] = { item = id, tier = tier[1], faction = e,
                                      price = e.f.prices and e.f.prices[id] }
                end
            end
        end
    end
    return out, list, hidden
end

local function Inspector(e)
    if not e then
        return {
            { type = "header", text = "Ruf-Belohnungen" },
            { type = "card", lines = {
                "Was jede Fraktion beim Rüstmeister",
                "anbietet – ab welcher Rufstufe und",
                "für wie viel. Grün: mit deinem Ruf",
                "schon zu kaufen.",
                "Klick auf eine Fraktion: Belohnungen",
                "aufklappen, Rüstmeister rechts.",
            }},
            { type = "divider" },
            { type = "header", text = "Woher das stammt" },
            { type = "card", lines = {
                "Dein Ruf, Namen und Symbole sagt",
                "das Spiel. Belohnungen, Preise und",
                "Rüstmeister: von Spielern gesammelt.",
            }},
        }
    end
    local f = e.f
    local rows = {
        { label = "Dein Ruf", value = e.standing and BP.StandingName(e.standing) or "unbekannt" },
        { label = "Belohnungen", value = e.reach .. " von " .. e.total .. " schon zu kaufen" },
    }
    local blocks = { { type = "header", text = e.name } }
    if f.qm then
        local lb = WeintCodex.Library
        rows[#rows + 1] = { label = "Rüstmeister", value = f.qm[1] }
        rows[#rows + 1] = { label = "Gebiet", value = (lb and lb.ZoneName and lb.ZoneName(f.qm[2])) or "unbekannt" }
        rows[#rows + 1] = { label = "Ort", value = string.format("%.1f, %.1f", f.qm[3], f.qm[4]) }
        blocks[#blocks + 1] = { type = "custom", create = function(parent, width)
            local w = BP.MapWidget(parent, width)
            BP.PaintMap(w, f.qm[2], f.qm[3] / 100, f.qm[4] / 100)
            return w
        end }
    end
    blocks[#blocks + 1] = { type = "rows", rows = rows }
    if f.qm then
        blocks[#blocks + 1] = { type = "custom", create = function(parent, width)
            if not BP.repGuideBtn then BP.repGuideBtn = BP.Pill(parent, "Questpfeil zum Rüstmeister", { height = 32, size = 12, primary = true }) end
            local g = BP.repGuideBtn
            g:SetWidth(width)
            g:SetScript("OnClick", function() BP.RepGuide(f, e.name) end)
            g:Paint(false)
            return g
        end }
    else
        blocks[#blocks + 1] = { type = "text", text = "Wo der Rüstmeister steht, ist nicht gesammelt." }
    end
    blocks[#blocks + 1] = { type = "divider" }
    blocks[#blocks + 1] = { type = "text", text = "Von Spielern gesammelt." }
    return blocks
end

-- Zeile fuer Buecher/Schlafsack zuruecksetzen (kein Symbol, kein Einzug).
function BP.RowPlain(r)
    if r.wcIcon then r.wcIcon:Hide() end
    r.repFaction, r.repItem = false, false
    if r.indent ~= 28 then
        r.indent = 28
        r.name:ClearAllPoints()
        r.name:SetPoint("TOPLEFT", r, "TOPLEFT", 28, -7)
        r.name:SetPoint("RIGHT", r, "RIGHT", -110, 0)
    end
end

local function RowIndent(r, x)
    if r.indent == x then return end
    r.indent = x
    r.name:ClearAllPoints()
    r.name:SetPoint("TOPLEFT", r, "TOPLEFT", x, -7)
    r.name:SetPoint("RIGHT", r, "RIGHT", -110, 0)
end

local redrawSoon = false
local function RedrawLater()
    if redrawSoon or not (_G.C_Timer and _G.C_Timer.After) then return end
    redrawSoon = true
    _G.C_Timer.After(2, function()
        redrawSoon = false
        if BP.cat == "rep" and BP.page and BP.page:IsShown() then BP.Show() end
    end)
end

function BP.ShowRep(f)
    local nav = WeintCodex.Navigation
    for _, t in ipairs(f.Ticks) do t.mark:Hide() t.text:Hide() end
    f.Fill:Hide()
    local list, factions, hidden = BP.RepRows()
    if not Data() then
        f.Count:SetText("Ruf-Belohnungen")
        f.Goal:SetText("Der Bestand ist nicht geladen.")
    else
        local reach, total = 0, 0
        for _, e in ipairs(factions) do reach, total = reach + e.reach, total + e.total end
        f.Count:SetText(#factions .. " Fraktionen")
        f.Goal:SetText(reach .. " von " .. total .. " Belohnungen kannst du mit deinem Ruf schon kaufen")
    end
    local chosen
    for _, e in ipairs(factions) do if e.fid == BP.repSel then chosen = e end end
    if not chosen then BP.repSel = nil end
    nav.SetInspector(Inspector(chosen))

    local w = Plain(f.Card:GetWidth()) or 460
    local h = Plain(f.Card:GetHeight()) or 360
    w = (type(w) == "number" and w or 460) - 24
    h = (type(h) == "number" and h or 360) - 84 - 34
    f.ListScroll:SetSize(w, math.max(60, h))
    f.ListBody:SetWidth(w - 10)
    local loading = false
    for i, row in ipairs(list) do
        local r = BP.Row(i, f.ListBody)
        r.entry, r.stepIndex = nil, nil
        r:ClearAllPoints()
        r:SetPoint("TOPLEFT", f.ListBody, "TOPLEFT", 0, -(i - 1) * BP.ROW_H)
        r:SetPoint("RIGHT", f.ListBody, "RIGHT", 0, 0)
        if row.item then
            local e, id = row.faction, row.item
            r.repFaction, r.repItem = false, id
            if not r.wcIcon then
                r.wcIcon = r:CreateTexture(nil, "ARTWORK")
                r.wcIcon:SetSize(26, 26)
                r.wcIcon:SetPoint("LEFT", r, "LEFT", 44, 0)
            end
            local inf = Info(id)
            if inf.loading then loading = true end
            r.wcIcon:SetTexture(inf.icon or 134400)
            r.wcIcon:Show()
            RowIndent(r, 78)
            r.name:SetText(inf.name or (inf.loading and "lädt …" or ("Gegenstand " .. id)))
            local LBk = WeintCodex.LootBook
            if inf.name and LBk and LBk.QualityRGB then r.name:SetTextColor(LBk.QualityRGB(inf.quality))
            else local t = C.textMuted r.name:SetTextColor(t[1], t[2], t[3], 1) end
            local ok = e.standing and e.standing >= row.tier
            local parts = { "ab " .. BP.StandingName(row.tier) }
            local m = Money(row.price)
            if m then parts[#parts + 1] = m end
            if inf.kind and inf.kind ~= "" then parts[#parts + 1] = inf.kind end
            r.sub:SetText(table.concat(parts, " · "))
            local c = Col(ok and "success" or "textFaint")
            r.dot:SetVertexColor(c[1], c[2], c[3], 1)
            r.go:Hide()
        else
            local e = row.faction
            r.repFaction, r.repItem = e.fid, false
            if r.wcIcon then r.wcIcon:Hide() end
            RowIndent(r, 28)
            local t = C.textBright
            r.name:SetTextColor(t[1], t[2], t[3], 1)
            r.name:SetText((e.fid == BP.repSel and "– " or "+ ") .. e.name)
            local parts = { e.standing and ("du: " .. BP.StandingName(e.standing)) or "noch nicht entdeckt" }
            local qm = QmText(e.f)
            if qm then parts[#parts + 1] = "Rüstmeister " .. qm end
            parts[#parts + 1] = e.reach .. "/" .. e.total
            r.sub:SetText(table.concat(parts, " · "))
            local c = Col(e.reach > 0 and "success" or "textMuted")
            r.dot:SetVertexColor(c[1], c[2], c[3], 1)
            local f2, nm = e.f, e.name
            r.go:SetShown(e.f.qm ~= nil)
            r.go:SetScript("OnClick", function() BP.RepGuide(f2, nm) end)
        end
        BP.PaintRow(r)
        r:Show()
    end
    for i = #list + 1, #BP.rows do BP.rows[i]:Hide() end
    f.ListBody:SetHeight(math.max(1, #list * BP.ROW_H))
    local foot = #factions == 0 and "Hier ist nichts." or "Klick auf eine Fraktion: Belohnungen aufklappen. Maus über einen Gegenstand: Tooltip."
    if hidden > 0 then foot = foot .. " " .. hidden .. " Fraktionen der anderen Seite ausgeblendet." end
    f.Foot:SetText(foot)
    f.drawnWidth = Plain(f:GetWidth())
    if loading then RedrawLater() end
    return list
end

-- Vom Ruffenster und /wcui ruf: Codex auf dieser Seite oeffnen.
function BP.OpenRep(fid)
    local main, nav = WeintCodex.MainFrame, WeintCodex.Navigation
    if not (main and nav) then return false end
    BP.cat = "rep"
    if fid then BP.repSel = fid end
    main:Show()
    if nav.GoToTab then nav.GoToTab("buecher") elseif nav.SwitchTo then nav.SwitchTo("buecher") end
    return true
end
