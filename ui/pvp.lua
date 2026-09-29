--------------------------------------------------
-- WeintCodex :: Oberflaeche - PvP (6.7.2.0)
--------------------------------------------------
-- Der Reiter "Spieler gegen Spieler" im Charakterfenster als PvP-Profil
-- (Beta-Test: Rang, Rangsymbol, Rangpunkte, naechste Belohnung - weniger
-- schwarze Standardflaeche, mehr strukturierte Ansicht). Kein Register:
-- keine Liste, sondern ein Profil mit einem Mittelpunkt.
--
--   links/Mitte  Rangsymbol als Mittelpunkt (S.Stage: dunkler Hof, Hauch
--                Licht), darum eine angehobene Flaeche um Symbol, Rang,
--                Rangpunkte und Balken, darueber ein Ornament. Rangpunkte
--                etwas groesser, FARBE DES SPIELS bleibt.
--   rechts       Detailansicht als Karte wie im Ruf: Titel (Rang) groesser
--                in seiner Farbe, Linie darunter, Beschreibung; vor den
--                naechsten Belohnungen ein Ornament; die Belohnung (Symbol,
--                Name in Qualitaetsfarbe, Beschreibung) auf eigener, leicht
--                vertiefter Flaeche; Karte endet unter dem Inhalt.
--   Atmosphaere  etwas mehr als Ruf/Fertigkeiten: kraeftigere Vignette,
--                zwei entfernte Fackeln unten am Rand (warmes Licht, 5,5 %).
--                Kein Bild - eine Arena-Silhouette gibt es unter den Grafiken
--                nicht, und keine wird erzwungen.
--
-- NICHTS DAVON IST GEMESSEN. Wie der Forever-Client den Reiter baut, hat
-- niemand gelesen; bekannt ist nur, dass er ein Reiter des
-- Charakterfensters ist (sein Titel stand 6.6.4.3 in der Kopfzeile). Alles
-- wird deshalb ueber Lage und Form gefunden, nicht ueber Namen:
--   Detailansicht  das Kind des Fensters mit dem laengsten Text
--   Rangsymbol     das groesste etwa quadratische Bild ausserhalb davon
--   Rangpunkte     die Schriftzeile ausserhalb davon mit "Zahl / Zahl"
--   Rang           die Schriftzeile, die dem Symbol am naechsten steht
--   Balken         ein Statusbalken/Balken mit Bild ausserhalb davon
--   Titel          die oberste Schriftzeile der Detailansicht
--   Belohnung      der Knopf mit Symbol in der Detailansicht; ihre
--                  Ueberschrift ist die Zeile direkt darueber
-- /wcui fenster ueber dem Reiter nennt, was gefunden wurde.
--
-- Nur Aussehen: eigene Flaechen dahinter (auf dem Charakterfenster oder
-- der Detailansicht, unterste Ebene), Schriftgroesse. Kein SetText, keine
-- Farbe des Spiels ueberschrieben (Rang, Qualitaet), nichts verschoben,
-- nichts ausgeblendet ausser dem Rahmen der Detailansicht.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIPvP = {}

local PV = WeintCodex.UIPvP
local K = WeintCodex.UIKit
local GC = WeintCodex.GameColors
local W = WeintCodex.UIWindows
local S = WeintCodex.UIStyle
local RG = WeintCodex.UIRegister

local Visible, Kind, TextOf, InTree = RG.Visible, RG.Kind, RG.TextOf, RG.InTree
local IsFrame, Edge = RG.IsFrame, RG.Edge

PV.LABEL = "PvP"
PV.FRAMES = { "PVPFrame", "HonorFrame", "CharacterFrame.PVPFrame", "CharacterFrame.HonorFrame" }
PV.STYLE = S.CHARACTER_INFO
for _, path in ipairs(PV.FRAMES) do S.SCOPES[path] = PV.STYLE end
W.TABS[#W.TABS + 1] = PV

PV.VIGNETTE, PV.VIGNETTE_SIZE = 0.45, 56
PV.LIGHT_HEIGHT = 140
PV.TORCH_SIZE = 220
PV.ICON_MIN = 40            -- kleiner ist kein Rangsymbol (px)
PV.ICON_SHARE = 0.30        -- groesser (Anteil am Fenster) ist ein Hintergrund
PV.POINTS = "%d+%s*/%s*%d+" -- "0 / 750" - nur die Form, kein Wort
PV.POINTS_SIZE = 13
PV.AREA_PAD = 18            -- Flaeche um den Rangbereich
PV.ORNAMENT_GAP = 12        -- Ornament ueber dem Rangbereich
PV.DETAIL_TITLE = 16
PV.DETAIL_PAD = 4
PV.DETAIL_INSET = 10
PV.DETAIL_LINE = 0.55
PV.DETAIL_DECOR = { "Border", "NineSlice", "Bg", "Background" }
PV.DESC_MIN = 40
PV.HEAD_REACH = 40          -- so weit ueber der Belohnung darf ihre Ueberschrift stehen
PV.REWARD_PAD = 6
PV.CARD_BOTTOM = 12

local layouts = setmetatable({}, { __mode = "k" })
PV.layouts = layouts

local WHITE = { 1, 1, 1 }
local function Accent() return S.Accent(PV.STYLE.accent) end

--------------------------------------------------
-- Finden
--------------------------------------------------
function PV.Frame()
    local first
    for _, path in ipairs(PV.FRAMES) do
        local f = path:find(".", 1, true) and W.Resolve(path) or _G[path]
        if IsFrame(f) then
            if Visible(f) then return f end
            first = first or f
        end
    end
    return first
end

-- Groesstes etwa quadratisches, sichtbares Bild unter `f` (nicht unter
-- `skip`, nicht unser eigenes, nicht groesser als `limit`).
local function Biggest(f, depth, skip, limit, best, area)
    if not f or depth > 3 then return best, area end
    for _, r in ipairs(W.Regions(f, "pvpIcon", depth)) do
        if Kind(r) == "Texture" and not S.own[r] and Visible(r) and K.Plain(r:GetAlpha()) ~= 0 then
            local w, h = Edge(r, "GetWidth"), Edge(r, "GetHeight")
            if w and h and w >= PV.ICON_MIN and h >= PV.ICON_MIN and w / h > 0.75 and w / h < 1.33 then
                local a = w * h
                if a > area and (not limit or a <= limit) then best, area = r, a end
            end
        end
    end
    for _, ch in ipairs(W.Children(f, "pvpIcon", depth)) do
        if IsFrame(ch) and ch ~= skip and Visible(ch) then
            best, area = Biggest(ch, depth + 1, skip, limit, best, area)
        end
    end
    return best, area
end

-- Erste sichtbare Schriftzeile unter `f` (nicht unter `skip`), deren Text
-- das Muster traegt.
local function FindText(f, depth, skip, pattern)
    if not f or depth > 3 then return nil end
    for _, r in ipairs(W.Regions(f, "pvpText", depth)) do
        if Kind(r) == "FontString" and Visible(r) then
            local t = TextOf(r)
            if t and t:find(pattern) then return r end
        end
    end
    for _, ch in ipairs(W.Children(f, "pvpText", depth)) do
        if IsFrame(ch) and ch ~= skip and Visible(ch) then
            local hit = FindText(ch, depth + 1, skip, pattern)
            if hit then return hit end
        end
    end
    return nil
end

-- Schriftzeile mit Text, deren Mitte der von `icon` am naechsten liegt
-- (senkrecht) - der Rang neben/unter dem Symbol.
local function Nearest(f, depth, skip, not1, cy, best, dist)
    if not f or depth > 3 then return best, dist end
    for _, r in ipairs(W.Regions(f, "pvpNear", depth)) do
        if Kind(r) == "FontString" and r ~= not1 and Visible(r) and TextOf(r) then
            local t, b = Edge(r, "GetTop"), Edge(r, "GetBottom")
            if t and b then
                local d = math.abs((t + b) / 2 - cy)
                if not dist or d < dist then best, dist = r, d end
            end
        end
    end
    for _, ch in ipairs(W.Children(f, "pvpNear", depth)) do
        if IsFrame(ch) and ch ~= skip and Visible(ch) then
            best, dist = Nearest(ch, depth + 1, skip, not1, cy, best, dist)
        end
    end
    return best, dist
end

-- Knopf mit Symbol (Belohnung) unter `f`: ein Knopf mit .Icon/.icon oder
-- einem etwa quadratischen Bild.
local function IconOf(b)
    local ic = b.Icon or b.icon
    if IsFrame(ic) and Kind(ic) == "Texture" then return ic end
    for _, r in ipairs(W.Regions(b, "pvpBtnIcon")) do
        if Kind(r) == "Texture" and not S.own[r] then
            local w, h = Edge(r, "GetWidth"), Edge(r, "GetHeight")
            if w and h and w >= 16 and w / h > 0.75 and w / h < 1.33 then return r end
        end
    end
    return nil
end

local function FindReward(f, depth, close)
    if not f or depth > 2 then return nil end
    for _, ch in ipairs(W.Children(f, "pvpReward", depth)) do
        if IsFrame(ch) and ch ~= close and Visible(ch) and (Kind(ch) == "Button" or Kind(ch) == "ItemButton")
           and IconOf(ch) then
            return ch
        end
    end
    for _, ch in ipairs(W.Children(f, "pvpReward", depth)) do
        if IsFrame(ch) and Visible(ch) and Kind(ch) ~= "Button" then
            local hit = FindReward(ch, depth + 1, close)
            if hit then return hit end
        end
    end
    return nil
end

-- Tiefste Unterkante sichtbarer Schriftzeilen/Knoepfe unter `f`, deren
-- Oberkante unter `yFrom` liegt (absolute Hoehen). Dazu die Zeile direkt
-- ueber `yFrom` (hoechstens PV.HEAD_REACH darueber): die Ueberschrift.
local function Below(f, depth, yFrom, low, head, headTop)
    if not f or depth > 2 then return low, head, headTop end
    for _, r in ipairs(W.Regions(f, "pvpBelow", depth)) do
        if Kind(r) == "FontString" and Visible(r) and TextOf(r) then
            local t, b = Edge(r, "GetTop"), Edge(r, "GetBottom")
            if t and b then
                if t <= yFrom + 2 then
                    if not low or b < low then low = b end
                elseif b >= yFrom and b - yFrom <= PV.HEAD_REACH and (not headTop or t < headTop) then
                    head, headTop = r, t
                end
            end
        end
    end
    for _, ch in ipairs(W.Children(f, "pvpBelow", depth)) do
        if IsFrame(ch) and Visible(ch) then
            local b = Edge(ch, "GetBottom")
            local t = Edge(ch, "GetTop")
            if t and b and t <= yFrom + 2 and (Kind(ch) == "Button" or Kind(ch) == "CheckButton") then
                if not low or b < low then low = b end
            end
            low, head, headTop = Below(ch, depth + 1, yFrom, low, head, headTop)
        end
    end
    return low, head, headTop
end

-- Einmal je Fenster (und so lange, bis es etwas findet): was ist wo.
function PV.Scan(L)
    local root = L.root
    if not L.detail then
        local best, blen = nil, PV.DESC_MIN - 1
        for _, ch in ipairs(W.Children(root, "pvpDetail")) do
            if IsFrame(ch) and Visible(ch) then
                local _, len = RG.Longest(ch, 0, nil, nil, 0)
                if len > blen then best, blen = ch, len end
            end
        end
        L.detail = best
    end
    if not L.icon then
        local w, h = Edge(root, "GetWidth"), Edge(root, "GetHeight")
        local limit = (w and h) and w * h * PV.ICON_SHARE or nil
        L.icon = (Biggest(root, 0, L.detail, limit, nil, 0))
    end
    if not L.points then L.points = FindText(root, 0, L.detail, PV.POINTS) end
    if not L.bar then L.bar = RG.FindBar(root, 0, L.detail) end
    if L.icon and not L.rank then
        local t, b = Edge(L.icon, "GetTop"), Edge(L.icon, "GetBottom")
        if t and b then L.rank = (Nearest(root, 0, L.detail, L.points, (t + b) / 2, nil, nil)) end
    end
    if L.detail and not L.title then L.title = (RG.Topmost(L.detail, 0, nil, nil)) end
    if L.detail and not L.reward then L.reward = FindReward(L.detail, 0, L.detail.CloseButton) end
end

--------------------------------------------------
-- Aufbau (einmal) und Lage (jeder Durchlauf, neu nur bei Aenderung)
--------------------------------------------------
function PV.Build(f, L)
    local root, accent = L.root, Accent()
    L.parts = {}
    -- Atmosphaere auf dem Charakterfenster (unter allem, was das Spiel zeichnet).
    local v = S.Vignette(f, root, PV.VIGNETTE, PV.VIGNETTE_SIZE, -6)
    for _, side in ipairs(S.SIDES) do L.parts[#L.parts + 1] = v[side] end
    local l = GC.atmosLight
    L.light = S.TopLight(f, root, l, l[4], PV.LIGHT_HEIGHT, -5)
    local g = GC.torchGlow
    L.torchL = S.Own(f:CreateTexture(nil, "BACKGROUND", nil, -5))
    L.torchR = S.Own(f:CreateTexture(nil, "BACKGROUND", nil, -5))
    for _, t in ipairs({ L.torchL, L.torchR }) do
        t:SetTexture(K.MEDIA .. "halo")
        t:SetVertexColor(g[1], g[2], g[3], g[4])
        t:SetSize(PV.TORCH_SIZE, PV.TORCH_SIZE)
    end
    L.torchL:SetPoint("CENTER", root, "BOTTOMLEFT", 24, 16)
    if L.detail then L.torchR:SetPoint("CENTER", L.detail, "BOTTOMLEFT", -24, 16)
    else L.torchR:SetPoint("CENTER", root, "BOTTOMRIGHT", -24, 16) end
    -- Rangbereich: ein unsichtbarer Anker, danach Flaeche, Schatten, Ornament.
    L.area = S.Own(f:CreateTexture(nil, "BACKGROUND", nil, -8))
    local c = GC.surfaceRaised
    L.areaBody = S.SoftPanel(f, L.area, c, c[4], PV.AREA_PAD, -4)
    L.areaShadow = S.Shadow(f, L.area, PV.AREA_PAD + 16, -5)
    L.areaEdge = S.Under(S.Divider(f, WHITE, 0.07, 0), -3)
    S.PlaceTop(L.areaEdge, L.areaBody, 14)
    L.ornament = S.Ornament(f, accent, 0.45)
    for _, t in ipairs({ L.light, L.torchL, L.torchR, L.areaBody, L.areaShadow, L.areaEdge.l, L.areaEdge.r,
                          L.ornament.line.l, L.ornament.line.r, L.ornament.dot, L.ornament.hole }) do
        L.parts[#L.parts + 1] = t
    end
    -- Rangpunkte: etwas groesser, Farbe des Spiels.
    if L.points then
        S.Title(L.points, PV.POINTS_SIZE, false)
        L.pointsDone = true
    end
    -- Sofort mit dem Reiter aus und an.
    if root.HookScript then
        root:HookScript("OnShow", function() RG.ShowAtmos(L, true) end)
        root:HookScript("OnHide", function() RG.ShowAtmos(L, false) end)
    end
    L.on = true
end

-- Der Rangbereich umfasst Symbol, Rang, Rangpunkte und Balken.
function PV.PlaceArea(L)
    local root = L.root
    local rl, rt = Edge(root, "GetLeft"), Edge(root, "GetTop")
    if not rl or not rt then return end
    -- Jeder Durchlauf: was bis jetzt gefunden ist (feste Plaetze, keine
    -- neue Tabelle).
    local m = L.members
    m[1], m[2], m[3], m[4] = L.icon, L.rank, L.points, L.bar
    local x1, y1, x2, y2
    for i = 1, 4 do
        local r = m[i]
        local l, t, rr, b
        if r then l, t, rr, b = Edge(r, "GetLeft"), Edge(r, "GetTop"), Edge(r, "GetRight"), Edge(r, "GetBottom") end
        if l and t and rr and b then
            x1 = x1 and math.min(x1, l) or l
            x2 = x2 and math.max(x2, rr) or rr
            y1 = y1 and math.max(y1, t) or t
            y2 = y2 and math.min(y2, b) or b
        end
    end
    if not x1 then
        if L.areaOn ~= false then
            L.areaOn = false
            RG.ShowZone(false, L.areaBody, L.areaShadow, L.areaEdge.l, L.areaEdge.r,
                L.ornament.line.l, L.ornament.line.r, L.ornament.dot, L.ornament.hole)
        end
        return
    end
    x1, x2, y1, y2 = x1 - rl, x2 - rl, y1 - rt, y2 - rt
    if L.ax1 == x1 and L.ay1 == y1 and L.ax2 == x2 and L.ay2 == y2 then return end
    L.ax1, L.ay1, L.ax2, L.ay2 = x1, y1, x2, y2
    S.PlaceRect(L.area, root, x1, y1, x2, y2)
    S.PlaceOrnament(L.ornament, L.area, 0, PV.AREA_PAD + PV.ORNAMENT_GAP)
    if L.areaOn ~= true then
        L.areaOn = true
        RG.ShowZone(L.on, L.areaBody, L.areaShadow, L.areaEdge.l, L.areaEdge.r,
            L.ornament.line.l, L.ornament.line.r, L.ornament.dot, L.ornament.hole)
    end
end

--------------------------------------------------
-- Detailansicht als Karte
--------------------------------------------------
function PV.Detail(f, L)
    local det = L.detail
    if not det or not Visible(det) then return nil end
    local d = L.card
    if not d then
        d = { frame = det }
        for _, key in ipairs(PV.DETAIL_DECOR) do
            local part = det[key]
            if IsFrame(part) then W.HideDecor(part) end
        end
        d.inTree = InTree(det, f)
        local c = GC.surfaceDetail
        if d.inTree then
            d.body = S.SoftPanel(det, det, c, c[4], PV.DETAIL_PAD, -7)
            d.shadow = S.Shadow(det, det, PV.DETAIL_PAD + 16, -8)
        else
            d.panel = S.Panel(det)
        end
        d.edge = S.Under(S.Divider(det, Accent(), PV.DETAIL_LINE, 0), -2)
        S.PlaceTop(d.edge, det, PV.DETAIL_INSET)
        d.titleLine = S.Under(S.Divider(det, Accent(), 0.4, 0), -1)
        d.rewardOrn = S.Ornament(det, Accent(), 0.45)
        local s = GC.surfaceSunken
        d.rewardBody = S.SoftPanel(det, det, s, s[4], 0, -6)
        d.zones = { d.titleLine.l, d.titleLine.r, d.rewardBody }
        for _, t in ipairs(d.zones) do t:Hide() end
        for _, t in ipairs(d.rewardOrn.parts) do t:Hide() end
        -- Titel (Rang): groesser, Farbe des Spiels (sie kann den Rang tragen).
        if L.title then S.Title(L.title, PV.DETAIL_TITLE, false) end
        L.card = d
    end
    PV.DetailLayout(L, d)
    if not d.inTree then
        W.HideByAtlas(det)
        W.Grey(det)
    end
    return d
end

function PV.DetailLayout(L, d)
    local det = d.frame
    local top = Edge(det, "GetTop")
    if not top then return end
    local tb = L.title and Edge(L.title, "GetBottom")
    local yTitle = tb and math.floor(tb - top + 0.5) or false
    local rt = L.reward and Edge(L.reward, "GetTop")
    local low, head, headTop
    if rt then low, head, headTop = Below(det, 0, rt, nil, nil, nil) end
    L.head = head
    local yReward = rt and math.floor(rt - top + 0.5) or false
    local yHead = headTop and math.floor(headTop - top + 0.5) or false
    local yLow = low and math.floor(low - top + 0.5) or false
    if d.yTitle == yTitle and d.yReward == yReward and d.yHead == yHead and d.yLow == yLow then return end
    d.yTitle, d.yReward, d.yHead, d.yLow = yTitle, yReward, yHead, yLow
    local inset = PV.DETAIL_INSET
    -- Linie unter dem Titel (Rang).
    if yTitle then S.PlaceTop(d.titleLine, det, inset, yTitle - 7) end
    RG.ShowZone(yTitle and true or false, d.titleLine.l, d.titleLine.r)
    -- Naechste Belohnungen: Ornament ueber der Ueberschrift (sonst ueber dem
    -- Knopf), die Belohnung selbst auf einer vertieften Flaeche.
    local yOrn = (yHead or yReward) and ((yHead or yReward) + PV.ORNAMENT_GAP) or false
    if yOrn then S.PlaceOrnament(d.rewardOrn, det, inset, yOrn) end
    RG.ShowZone(yOrn and true or false, d.rewardOrn.line.l, d.rewardOrn.line.r, d.rewardOrn.dot, d.rewardOrn.hole)
    if yReward and yLow then
        S.PlaceBand(d.rewardBody, det, PV.REWARD_PAD, yReward + PV.REWARD_PAD, yLow - PV.REWARD_PAD)
    end
    d.rewardBody:SetShown((yReward and yLow) and true or false)
    -- Karte endet unter dem Inhalt (Belohnung, sonst Beschreibung).
    local bottom = yLow
    if not bottom then
        local desc = RG.Longest(det, 0, nil, nil, 0)
        local t, h = desc and Edge(desc, "GetTop"), desc and Edge(desc, "GetStringHeight")
        bottom = (t and h) and math.floor(t - h - top + 0.5) or false
    end
    d.cardBottom = bottom and (bottom - PV.CARD_BOTTOM) or nil
    for _, part in ipairs({ { d.body, PV.DETAIL_PAD }, { d.shadow, PV.DETAIL_PAD + 16 } }) do
        local t, p = part[1], part[2]
        if t then
            t:ClearAllPoints()
            t:SetPoint("TOPLEFT", det, "TOPLEFT", -p, p)
            if d.cardBottom then t:SetPoint("BOTTOMRIGHT", det, "TOPRIGHT", p, d.cardBottom - p)
            else t:SetPoint("BOTTOMRIGHT", det, "BOTTOMRIGHT", p, -p) end
        end
    end
end

--------------------------------------------------
-- Ein Durchlauf (aus W.Inner, Charakterfenster offen)
--------------------------------------------------
function PV.Update(f)
    local root = PV.Frame()
    if not root then return nil end
    local L = layouts[root]
    if not Visible(root) or (root ~= f and not InTree(root, f)) then
        if L and L.parts then RG.ShowAtmos(L, false) end
        return nil
    end
    S.Scope(root, PV.STYLE)
    if not L then
        L = { root = root }
        layouts[root] = L
    end
    PV.Scan(L)
    if not L.parts then
        PV.Build(f, L)
        L.members = {}
    end
    -- Spaet gefunden: Buehne und Balken nachholen.
    if L.icon and not L.stage then
        L.stage = S.Stage(f, L.icon, -3)
        L.parts[#L.parts + 1] = L.stage.shade
        L.parts[#L.parts + 1] = L.stage.light
    end
    if L.bar and not L.barFinish then
        local fill, how = RG.BarFill(L.bar)
        L.barFinish = S.BarFinish(L.bar, fill)
        L.barFinish.how = how
    end
    RG.ShowAtmos(L, true)
    if L.stage and L.icon then
        S.FitStage(L.stage, Edge(L.icon, "GetWidth"), Edge(L.icon, "GetHeight"))
    end
    PV.PlaceArea(L)
    PV.Detail(f, L)
    return L
end

--------------------------------------------------
-- /wcui fenster
--------------------------------------------------
local function Describe(r)
    if not r then return "FEHLT" end
    local name = (r.GetDebugName and r:GetDebugName()) or (r.GetName and r:GetName())
    name = K.Plain(name)
    local what = type(name) == "string" and name ~= "" and name or Kind(r) or "?"
    if Kind(r) == "Texture" then
        local a = RG.AtlasOf(r)
        local ok, file = pcall(r.GetTexture, r)
        file = ok and K.Plain(file) or nil
        local w, h = Edge(r, "GetWidth"), Edge(r, "GetHeight")
        what = string.format("%s (%s, %dx%d)", what, a or tostring(file or "?"), w or 0, h or 0)
    elseif Kind(r) == "FontString" then
        what = "„" .. (TextOf(r) or "") .. "“"
    end
    return what
end

function PV.Report(f, out)
    local root = PV.Frame()
    if not root or not Visible(root) then return out end
    local L = layouts[root]
    local L_ = PV.LABEL
    out[#out + 1] = string.format("   %s (Stil %s): Fenster %s", L_, PV.STYLE.name, Describe(root))
    if not L then
        out[#out + 1] = string.format("   %s: noch nicht gestaltet", L_)
        return out
    end
    out[#out + 1] = string.format("   %s, Rang: Symbol %s · Rang %s · Punkte %s · Balken %s", L_,
        Describe(L.icon), Describe(L.rank), Describe(L.points),
        L.bar and (Describe(L.bar) .. ", Füllung " .. tostring(L.barFinish and L.barFinish.how)) or "keiner")
    out[#out + 1] = string.format("   %s, Rangbereich: %s", L_,
        L.ax1 and string.format("%.0f/%.0f bis %.0f/%.0f", L.ax1, L.ay1, L.ax2, L.ay2) or "nicht gelegt (keine Lage)")
    local d = L.card
    out[#out + 1] = string.format("   %s, Detail: %s · Titel %s · Belohnung %s · Überschrift %s · Karte endet %s", L_,
        L.detail and Describe(L.detail) or "nicht gefunden", Describe(L.title), Describe(L.reward), Describe(L.head),
        (d and d.cardBottom) and string.format("bei %.0f", d.cardBottom) or "am Rand")
    return out
end
