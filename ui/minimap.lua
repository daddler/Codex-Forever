--------------------------------------------------
-- WeintCodex :: Oberflaeche - Minikarte
--------------------------------------------------
-- Die Minikarte des Spiels, eckig und schlicht: 1-px-Rand statt des
-- Steinrings, Zoom mit dem Mausrad. In der Karte oben links die
-- Koordinaten, oben rechts die Uhrzeit, unten auf einem dunklen Streifen
-- das Gebiet. Die Knoepfe des Spiels (Verfolgung, Kalender, Post,
-- Schwierigkeit) stehen in einer Spalte links neben der Karte statt
-- verstreut auf ihrem Rand - so ordnet es auch EllesmereUI.
--
-- Die Karte selbst bleibt die des Spiels, samt Lage (Bearbeitungsmodus).
-- Geaendert werden nur Maske, Groesse und die Verzierung. Die Kompass-
-- TEXTUR wird versteckt, nie ihr Elternrahmen: laut EllesmereUI lesen
-- Kampfhilfen in Instanzen die Blickrichtung aus deren Drehung, und ein
-- versteckter Elternrahmen haelt sie an.
--
-- Addon-Knoepfe am Rand (auch der von WeintCodex) fragen GetMinimapShape,
-- um auf einer eckigen Karte eckig zu laufen - die Funktion meldet
-- "SQUARE", solange die Karte eckig ist.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIMinimap = {}

local MM = WeintCodex.UIMinimap
local K  = WeintCodex.UIKit
local C  = WeintCodex.Colors
local KEY = "minimap"

-- Masken als Datei-IDs des Spiels: eckig (weisses Quadrat) und rund
-- (die Maske der Standardkarte). Dieselben Werte nutzt die Vorlage.
local MASK_SQUARE = 130937
local MASK_ROUND  = 186178

local defaults = {
    square      = true,
    size        = 200,           -- Vorlage: Forever-Groesse 200
    borderColor = K.ColorDefault("plateBorder"),
    zoneText    = true,
    zoneInside  = true,          -- unten in der Karte statt darueber
    coords      = true,
    coordDecimals = false,
    buttonColumn = true,
    clock       = true,
    wheelZoom   = true,
    hideZoomButtons = true,
    hideCalendar = false,
    -- Seit 6.3.0.9 (Beta-Test: "sehr viel verschwendeter Platz nach
    -- oben"): die Karte sitzt oben in ihrem Bereich, wo die ausgeblendete
    -- Kopfleiste des Spiels stand.
    atTop       = true,
    -- Fremde Koordinaten an der Karte (Beta-Test: "2x Koordinaten") -
    -- WeintCodex zeigt sie selbst, eine zweite Zeile ist doppelt.
    hideOtherCoords = true,
    -- Alle Addon-Knoepfe hinter einem Knopf unten links (6.3.1.1).
    addonBag    = true,
}

local function Opt(k) return K.Get(KEY, k) end

local DECORATIONS = { "MinimapBorder", "MinimapBorderTop", "MinimapNorthTag", "MinimapCompassTexture" }

local frame, zone, coords, clock, border, strip

local function PlayerCoords()
    local cm = _G.C_Map
    if not (cm and cm.GetBestMapForUnit and cm.GetPlayerMapPosition) then return nil end
    local map = cm.GetBestMapForUnit("player")
    local pos = map and cm.GetPlayerMapPosition(map, "player")
    if not pos then return nil end
    local x, y = K.Plain(pos.x), K.Plain(pos.y)
    if type(x) ~= "number" or type(y) ~= "number" then return nil end
    return x, y
end

local function UpdateTexts()
    if not frame then return end
    if Opt("zoneText") and _G.GetMinimapZoneText then
        zone:SetText(_G.GetMinimapZoneText())
        zone:Show()
    else
        zone:Hide()
    end
    if Opt("coords") then
        local x, y = PlayerCoords()
        -- Ohne Position (Instanz): ein Strich, keine 0,0.
        if not x then
            coords:SetText("–")
        elseif Opt("coordDecimals") then
            coords:SetText((string.format("%.1f · %.1f", x * 100, y * 100):gsub("%.(%d)", ",%1")))
        else
            coords:SetText(string.format("%d, %d", math.floor(x * 100 + 0.5), math.floor(y * 100 + 0.5)))
        end
        coords:Show()
    else
        coords:Hide()
    end
    if Opt("clock") then
        clock:SetText(date("%H:%M"))
        clock:Show()
    else
        clock:Hide()
    end
end

--------------------------------------------------
-- Knopfspalte
--------------------------------------------------
-- Welche Knoepfe es gibt und wie sie heissen, wechselt zwischen den
-- Clients; was fehlt, faellt heraus. Gesetzt wird nur der Ankerpunkt -
-- keiner der Knoepfe ist geschuetzt. Das Spiel ordnet sie beim Anpassen
-- der Minikarte neu (MinimapCluster:Layout); danach setzt ein Haken sie
-- wieder in die Spalte.

local laying = false

-- Die Knoepfe des Spiels in der Spalte links neben der Karte.
local function ColumnButtons()
    local cl = _G.MinimapCluster
    local list, seen = {}, {}
    local function add(f)
        if type(f) == "table" and f.SetPoint and f.ClearAllPoints and not seen[f]
           and not (f.IsForbidden and f:IsForbidden()) then
            seen[f] = true
            list[#list + 1] = f
        end
    end
    add(type(cl) == "table" and cl.Tracking or nil)
    add(_G.MiniMapTracking)
    local ind = type(cl) == "table" and cl.IndicatorFrame or nil
    add(type(ind) == "table" and ind.MailFrame or nil)
    add(_G.MiniMapMailFrame)
    add(type(ind) == "table" and ind.CraftingOrderFrame or nil)
    add(type(cl) == "table" and cl.InstanceDifficulty or nil)
    add(_G.MiniMapInstanceDifficulty)
    add(_G.ExpansionLandingPageMinimapButton)
    -- Ohne Sammelknopf stehen die Addon-Knoepfe mit in der Spalte.
    if not Opt("addonBag") then
        for _, b in ipairs(MM.AddonButtons()) do add(b) end
    end
    return list
end

--------------------------------------------------
-- Addon-Knoepfe
--------------------------------------------------
-- Knoepfe anderer Addons an der Karte sind fast immer LibDBIcon-Knoepfe
-- ("LibDBIcon10_<Name>"). Nur die werden gesammelt: die breitere Suche
-- aus 6.3.1.0 (jeder kleine Knopf auf der Karte) haette auch
-- Kartenmarkierungen anderer Addons erwischt - Wegpunkte und Fundorte sind
-- ebenfalls kleine Knoepfe auf der Minikarte, und die gehoeren auf sie.

function MM.AddonButtons()
    local list, seen = {}, {}
    local function add(b)
        if type(b) == "table" and not seen[b] and b.SetPoint and not (b.IsForbidden and b:IsForbidden()) then
            seen[b] = true
            list[#list + 1] = b
        end
    end
    local ls = _G.LibStub
    if type(ls) == "table" and ls.GetLibrary then
        local ok, lib = pcall(ls.GetLibrary, ls, "LibDBIcon-1.0", true)
        if ok and type(lib) == "table" and type(lib.objects) == "table" then
            for _, b in pairs(lib.objects) do add(b) end
        end
    end
    local mm = _G.Minimap
    if type(mm) == "table" and mm.GetChildren then
        local ok, kids = pcall(function() return { mm:GetChildren() } end)
        for _, ch in ipairs(ok and kids or {}) do
            local n = type(ch) == "table" and ch.GetName and ch:GetName()
            if type(n) == "string" and n:find("^LibDBIcon10_") then add(ch) end
        end
    end
    -- Im Addon selbst ausgeblendete Knoepfe (Hide) bleiben draussen.
    local shown = {}
    for _, b in ipairs(list) do
        if not b.IsShown or K.Bool(b:IsShown(), true) then shown[#shown + 1] = b end
    end
    list = shown
    table.sort(list, function(x, y)
        return tostring(x.GetName and x:GetName() or "") < tostring(y.GetName and y:GetName() or "")
    end)
    return list
end

-- Das Spiel setzt manche Knoepfe nach uns wieder an ihren alten Platz
-- (6.0.0.5: die Tageszeit-Sonne auf der Karte). Jeder Knopf der Spalte
-- meldet deshalb, wenn ihn jemand anderes verschiebt - dann ordnen wir
-- einen Takt spaeter neu. Eigene Verschiebungen (laying) zaehlen nicht.
local watched = {}
local function Watch(b)
    if watched[b] or not _G.hooksecurefunc then return end
    watched[b] = true
    _G.hooksecurefunc(b, "SetPoint", function()
        if laying then return end
        if _G.C_Timer and _G.C_Timer.After then _G.C_Timer.After(0, MM.LayoutButtons) end
    end)
end

-- Die Tageszeit (Sonne/Mond, zugleich der Kalender): unten rechts an der
-- Karte, ueber dem Gebietsstreifen (Beta-Test: "mitten drin", "gerne unten
-- rechts"). Welcher Rahmen das ist, heisst je nach Client anders.
function MM.TimeButton()
    local cl, mm = _G.MinimapCluster, _G.Minimap
    for _, f in ipairs({ _G.GameTimeFrame, type(cl) == "table" and cl.GameTimeFrame or nil,
        type(mm) == "table" and mm.GameTimeFrame or nil }) do
        if type(f) == "table" and f.SetPoint and not (f.IsForbidden and f:IsForbidden()) then return f end
    end
    return nil
end

function MM.LayoutButtons()
    local mm = _G.Minimap
    if laying or type(mm) ~= "table" or not frame then return end
    laying = true
    local tb = MM.TimeButton()
    if tb and not Opt("hideCalendar") then
        Watch(tb)
        tb:ClearAllPoints()
        local up = (Opt("zoneText") and Opt("zoneInside")) and 22 or 3
        tb:SetPoint("BOTTOMRIGHT", mm, "BOTTOMRIGHT", -3, up)
    end
    MM.LayoutBag()
    if not Opt("buttonColumn") then
        laying = false
        return
    end

    -- Von oben nach unten; reicht die Hoehe der Karte nicht, beginnt links
    -- daneben eine zweite Spalte.
    local limit = Opt("size") or 200
    local x, y, colW = 0, 0, 0
    for _, b in ipairs(ColumnButtons()) do
        Watch(b)
        local h = K.Plain(b.GetHeight and b:GetHeight())
        local w = K.Plain(b.GetWidth and b:GetWidth())
        if type(h) ~= "number" or h <= 0 or h > 60 then h = 20 end
        if type(w) ~= "number" or w <= 0 or w > 60 then w = 20 end
        if y > 0 and y + h > limit then
            x, y, colW = x + colW + 2, 0, 0
        end
        b:ClearAllPoints()
        b:SetPoint("TOPRIGHT", mm, "TOPLEFT", -4 - x, -y)
        y = y + h + 2
        colW = math.max(colW, w)
    end
    laying = false
end
MM.ColumnButtons = ColumnButtons

--------------------------------------------------
-- Sammelknopf
--------------------------------------------------
-- Ein Knopf unten links neben der Karte; ein Klick klappt eine Kachel mit
-- allen Addon-Knoepfen auf (Beta-Test: "ein Symbol unten links, das alle
-- Addons zusammenfasst"). Das Zeichen ist gezeichnet (neun Punkte), keine
-- Grafik des Spiels - ein geratener Pfad waere ein gruenes Rechteck.

local bag, flyout
local BAG_PER_ROW, BAG_CELL = 4, 30

local function BuildBag()
    if bag then return end
    local mm = _G.Minimap
    bag = CreateFrame("Button", "WeintCodexMinimapAddons", mm)
    bag:SetSize(22, 22)
    bag.kachel = K.Kachel(bag, { shadow = 4 })
    bag.dots = {}
    for i = 0, 8 do
        local d = bag:CreateTexture(nil, "ARTWORK")
        d:SetSize(3, 3)
        d:SetPoint("CENTER", bag, "CENTER", ((i % 3) - 1) * 5, (1 - math.floor(i / 3)) * 5)
        bag.dots[#bag.dots + 1] = d
    end
    local function Tint(col)
        for _, d in ipairs(bag.dots) do d:SetColorTexture(col[1], col[2], col[3], 1) end
    end
    Tint(C.textMuted)
    bag:SetScript("OnEnter", function(self)
        Tint(C.textBright)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("Addons", 1, 1, 1)
        GameTooltip:AddLine("Klick: alle Addon-Knöpfe der Minikarte", 0.7, 0.7, 0.75, true)
        GameTooltip:Show()
    end)
    bag:SetScript("OnLeave", function() Tint(C.textMuted) GameTooltip:Hide() end)
    flyout = CreateFrame("Frame", "WeintCodexMinimapAddonList", bag)
    flyout:SetFrameStrata("DIALOG")
    flyout.kachel = K.Kachel(flyout, { shadow = 6 })
    flyout:Hide()
    bag:SetScript("OnClick", function()
        flyout:SetShown(not flyout:IsShown())
        MM.LayoutBag()
    end)
end

function MM.LayoutBag()
    local mm = _G.Minimap
    if type(mm) ~= "table" then return end
    if not Opt("addonBag") then
        if bag then bag:Hide() end
        return
    end
    BuildBag()
    bag:ClearAllPoints()
    bag:SetPoint("BOTTOMRIGHT", mm, "BOTTOMLEFT", -4, 0)
    local list = MM.AddonButtons()
    bag:SetShown(#list > 0)
    -- Die Kachel waechst ueber dem Knopf nach oben, rechtsbuendig mit ihm.
    local rows = math.max(1, math.ceil(#list / BAG_PER_ROW))
    local cols = math.max(1, math.min(BAG_PER_ROW, #list))
    flyout:ClearAllPoints()
    flyout:SetPoint("BOTTOMRIGHT", bag, "TOPRIGHT", 0, 4)
    flyout:SetSize(cols * BAG_CELL + 8, rows * BAG_CELL + 8)
    local inset = (BAG_CELL - 26) / 2
    for i, b in ipairs(list) do
        Watch(b)
        if b:GetParent() ~= flyout then b:SetParent(flyout) end
        b:ClearAllPoints()
        local c, r = (i - 1) % BAG_PER_ROW, math.floor((i - 1) / BAG_PER_ROW)
        b:SetPoint("TOPLEFT", flyout, "TOPLEFT", 4 + c * BAG_CELL + inset, -4 - r * BAG_CELL - inset)
    end
end
MM.Bag = function() return bag, flyout end

--------------------------------------------------
-- Karte nach oben
--------------------------------------------------
-- Die Karte haengt im Bereich des Spiels (MinimapCluster) unter dessen
-- Kopfleiste. Die Kopfleiste blendet WeintCodex aus (Gebiet und Uhr
-- stehen auf der Karte) - der Platz blieb leer. Die Karte ist kein
-- geschuetzter Rahmen; das Spiel setzt sie beim Anordnen neu, ein Haken
-- holt sie einen Takt spaeter zurueck.

local placingMap = false
function MM.PlaceMap()
    local mm, cl = _G.Minimap, _G.MinimapCluster
    if placingMap or type(mm) ~= "table" or type(cl) ~= "table" or not Opt("atTop") then return end
    placingMap = true
    -- Steht das Gebiet ueber der Karte, braucht es seine Zeile.
    local top = (Opt("zoneText") and not Opt("zoneInside")) and 22 or 6
    mm:ClearAllPoints()
    mm:SetPoint("TOPRIGHT", cl, "TOPRIGHT", -6, -top)
    placingMap = false
end

local mapHooked = false
local function HookMap()
    local mm = _G.Minimap
    if mapHooked or type(mm) ~= "table" or not _G.hooksecurefunc then return end
    mapHooked = true
    _G.hooksecurefunc(mm, "SetPoint", function()
        if placingMap or not Opt("atTop") then return end
        if _G.C_Timer and _G.C_Timer.After then _G.C_Timer.After(0, MM.PlaceMap) end
    end)
end

--------------------------------------------------
-- Fremde Koordinaten
--------------------------------------------------
-- Eine zweite Koordinatenzeile an der Karte ("56.3, 30.6") stammt nicht
-- von WeintCodex - vom Spiel oder einem anderen Addon. Gesucht wird nur
-- im Kartenbereich (MinimapCluster, Minimap, drei Ebenen tief) nach einer
-- Schrift, die genau wie Koordinaten aussieht; gefunden, wird sie
-- unsichtbar. Eigene Schriften zaehlen nicht.

local foreign = {}
MM.foreignCoords = foreign
local COORD_PATTERN = "^%s*%d+[%.,]?%d*%s*[,·/|]%s*%d+[%.,]?%d*%s*$"

function MM.LooksLikeCoords(text)
    text = K.Plain(text)
    return type(text) == "string" and text:find(COORD_PATTERN) ~= nil
end

function MM.HideOtherCoords()
    if not Opt("hideOtherCoords") then return 0 end
    local found = 0
    local mine = { [zone or false] = true, [coords or false] = true, [clock or false] = true }
    local seen = {}
    local function Check(r)
        if mine[r] or foreign[r] or type(r) ~= "table" then return end
        if not (r.GetObjectType and r:GetObjectType() == "FontString" and r.GetText) then return end
        local ok, text = pcall(r.GetText, r)
        if ok and MM.LooksLikeCoords(text) then
            foreign[r] = true
            r:SetAlpha(0)
            found = found + 1
        end
    end
    local function Walk(f, depth)
        if type(f) ~= "table" or seen[f] or depth > 3 or (f.IsForbidden and f:IsForbidden()) then return end
        seen[f] = true
        if f.GetRegions then for _, r in ipairs({ f:GetRegions() }) do Check(r) end end
        if f.GetChildren then for _, ch in ipairs({ f:GetChildren() }) do Walk(ch, depth + 1) end end
    end
    pcall(Walk, _G.MinimapCluster, 0)
    pcall(Walk, _G.Minimap, 0)
    -- Schon gefundene bleiben unsichtbar, auch wenn ihr Besitzer sie neu setzt.
    for r in pairs(foreign) do if r.SetAlpha then r:SetAlpha(0) end end
    return found
end

local function Apply()
    local mm = _G.Minimap
    if type(mm) ~= "table" then return end
    local size = Opt("size")
    local square = Opt("square")

    mm:SetSize(size, size)
    if mm.SetMaskTexture then mm:SetMaskTexture(square and MASK_SQUARE or MASK_ROUND) end
    -- Die runden Quest- und Grabungsringe passen nicht auf eine eckige Karte.
    if mm.SetArchBlobRingScalar then mm:SetArchBlobRingScalar(square and 0 or 1) end
    if mm.SetQuestBlobRingScalar then mm:SetQuestBlobRingScalar(square and 0 or 1) end

    for _, n in ipairs(DECORATIONS) do
        local t = _G[n]
        if type(t) == "table" and t.SetAlpha then t:SetAlpha(square and 0 or 1) end
    end

    border:SetShown(square)
    local c = K.GetColor(KEY, "borderColor")
    border:SetColor(c.r, c.g, c.b, 1)

    for _, b in ipairs({ mm.ZoomIn, mm.ZoomOut, _G.MinimapZoomIn, _G.MinimapZoomOut }) do
        if type(b) == "table" and b.SetAlpha then
            b:SetAlpha(Opt("hideZoomButtons") and 0 or 1)
            if b.EnableMouse then b:EnableMouse(not Opt("hideZoomButtons")) end
        end
    end
    -- Texte: Koordinaten oben links, Uhr oben rechts, Gebiet unten auf
    -- einem Streifen (oder wie bisher ueber der Karte).
    coords:ClearAllPoints()
    coords:SetPoint("TOPLEFT", mm, "TOPLEFT", 4, -4)
    clock:ClearAllPoints()
    clock:SetPoint("TOPRIGHT", mm, "TOPRIGHT", -4, -4)
    zone:ClearAllPoints()
    local inside = Opt("zoneInside")
    if inside then
        zone:SetPoint("BOTTOM", mm, "BOTTOM", 0, 4)
    else
        zone:SetPoint("BOTTOM", mm, "TOP", 0, 4)
    end
    strip:SetShown(inside and Opt("zoneText"))
    MM.LayoutButtons()

    -- Die Kopfleiste des Spiels ueber der Karte (Gebiet, Uhrzeit) stand in
    -- 6.0.0.3 doppelt neben unseren Texten. Sie geht, soweit unsere
    -- Texte ihren Teil uebernehmen.
    local cluster = _G.MinimapCluster
    local function Fade(f, off)
        if type(f) ~= "table" or not f.SetAlpha then return end
        f:SetAlpha(off and 0 or 1)
        if f.EnableMouse then f:EnableMouse(not off) end
    end
    if type(cluster) == "table" then
        Fade(cluster.BorderTop, square)
        Fade(cluster.ZoneTextButton, Opt("zoneText"))
    end
    Fade(_G.MinimapZoneTextButton, Opt("zoneText"))
    Fade(_G.TimeManagerClockButton, Opt("clock"))

    local cal = _G.GameTimeFrame
    if type(cal) == "table" and cal.SetAlpha then
        cal:SetAlpha(Opt("hideCalendar") and 0 or 1)
        if cal.EnableMouse then cal:EnableMouse(not Opt("hideCalendar")) end
    end

    K.SetFont(zone, 12)
    K.SetFont(coords, 10)
    K.SetFont(clock, 10)
    zone:SetWidth(size - 8)
    HookMap()
    MM.PlaceMap()
    MM.LayoutButtons()
    UpdateTexts()
end

local function Enable()
    local mm = _G.Minimap
    if type(mm) ~= "table" then return end

    frame = CreateFrame("Frame", nil, mm)
    frame:SetAllPoints(mm)
    frame:SetFrameLevel((mm:GetFrameLevel() or 1) + 5)
    border = K.Border(mm, 1, 0, 0, 0, 1, "OVERLAY")
    -- Der Schatten liegt auf einem eigenen Rahmen UNTER der Karte: auf ihr
    -- selbst deckte seine volle Mitte die Karte zu.
    local under = CreateFrame("Frame", nil, mm:GetParent() or UIParent)
    under:SetAllPoints(mm)
    under:SetFrameStrata(mm:GetFrameStrata() or "LOW")
    under:SetFrameLevel(math.max(0, (mm:GetFrameLevel() or 1) - 1))
    K.Glow(mm, { host = under, spread = 8, shadow = true })

    strip = frame:CreateTexture(nil, "BACKGROUND")
    strip:SetPoint("BOTTOMLEFT", mm, "BOTTOMLEFT", 0, 0)
    strip:SetPoint("BOTTOMRIGHT", mm, "BOTTOMRIGHT", 0, 0)
    strip:SetHeight(20)
    strip:SetColorTexture(0, 0, 0, 0.55)
    zone = K.NewText(frame)
    zone:SetWordWrap(false)
    zone:SetTextColor(unpack(C.textBright))
    coords = K.NewText(frame)
    coords:SetTextColor(unpack(C.textNormal))
    clock = K.NewText(frame)
    clock:SetTextColor(unpack(C.textNormal))

    -- Eckig fuer alle, die am Rand Knoepfe setzen (LibDBIcon & Co.).
    _G.GetMinimapShape = function() return Opt("square") and "SQUARE" or "ROUND" end

    if mm.EnableMouseWheel then mm:EnableMouseWheel(true) end
    mm:SetScript("OnMouseWheel", function(self, delta)
        if not Opt("wheelZoom") or not self.GetZoom then return end
        local z = self:GetZoom() or 0
        local maxZ = (self.GetZoomLevels and self:GetZoomLevels() or 6) - 1
        z = math.max(0, math.min(maxZ, z + (delta > 0 and 1 or -1)))
        self:SetZoom(z)
    end)

    local acc, scans, scanAcc = 1, 0, 0
    frame:SetScript("OnUpdate", function(_, el)
        acc = acc + (el or 0)
        if acc < 0.5 then return end
        scanAcc = scanAcc + acc
        acc = 0
        UpdateTexts()
        -- Fremde Koordinaten entstehen oft erst nach dem Laden: in der
        -- ersten Minute alle fuenf Sekunden nachsehen, danach nicht mehr.
        if scans < 12 and scanAcc >= 5 then
            scanAcc, scans = 0, scans + 1
            MM.HideOtherCoords()
            -- Addons legen ihre Kartenknoepfe oft erst spaeter an.
            MM.LayoutButtons()
        end
    end)
    local ev = CreateFrame("Frame")
    for _, e in ipairs({ "ZONE_CHANGED", "ZONE_CHANGED_INDOORS", "ZONE_CHANGED_NEW_AREA", "PLAYER_ENTERING_WORLD" }) do
        pcall(ev.RegisterEvent, ev, e)
    end
    ev:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_ENTERING_WORLD" then MM.LayoutButtons() end
        UpdateTexts()
    end)
    local cl = _G.MinimapCluster
    if _G.hooksecurefunc and type(cl) == "table" and type(cl.Layout) == "function" then
        _G.hooksecurefunc(cl, "Layout", function() MM.LayoutButtons() end)
    end
    local emf = _G.EditModeManagerFrame
    if _G.hooksecurefunc and type(emf) == "table" and type(emf.ExitEditMode) == "function" then
        _G.hooksecurefunc(emf, "ExitEditMode", function() MM.LayoutButtons() end)
    end
    Apply()
end

local function px(v) return string.format("%d px", v) end

K.Register({
    key = KEY, group = "ui", order = 40,
    title = "Minikarte",
    description = "Eckig und schlicht: feiner Rand, Zoom mit dem Mausrad, darüber das Gebiet, darunter Koordinaten und Uhrzeit.",
    defaults = defaults,
    Enable = Enable,
    OnSetting = function() if frame then Apply() end end,
    pages = {
        { key = "allgemein", label = "Allgemein", build = function(B)
            B:Section("Form")
            B:Row({ type = "toggle", label = "Eckig", key = "square",
                    description = "Aus: die runde Karte des Spiels." },
                  { type = "slider", label = "Größe", key = "size", min = 120, max = 320, step = 2, format = px })
            B:Row({ type = "color", label = "Randfarbe", key = "borderColor",
                    disabled = function() return not K.Get(KEY, "square") end },
                  { type = "empty" })
            B:Section("Anzeigen")
            B:Row({ type = "toggle", label = "Gebiet", key = "zoneText" },
                  { type = "toggle", label = "Gebiet unten in der Karte", key = "zoneInside",
                    description = "Aus: über der Karte.",
                    disabled = function() return not K.Get(KEY, "zoneText") end })
            B:Row({ type = "toggle", label = "Koordinaten", key = "coords",
                    description = "In Instanzen nennt das Spiel keine Position – dann steht ein Strich." },
                  { type = "toggle", label = "Koordinaten mit Nachkommastelle", key = "coordDecimals",
                    disabled = function() return not K.Get(KEY, "coords") end })
            B:Row({ type = "toggle", label = "Andere Koordinaten ausblenden", key = "hideOtherCoords", reload = true,
                    description = "Eine zweite Koordinatenzeile an der Karte, die nicht von WeintCodex stammt (Spiel oder anderes Addon)." },
                  { type = "toggle", label = "Karte oben im Bereich", key = "atTop", reload = true,
                    description = "Die Karte rückt nach oben, wo die ausgeblendete Kopfleiste des Spiels stand." })
            B:Row({ type = "toggle", label = "Uhrzeit", key = "clock" },
                  { type = "toggle", label = "Kalenderknopf ausblenden", key = "hideCalendar" })
            B:Section("Bedienung")
            B:Row({ type = "toggle", label = "Zoom mit dem Mausrad", key = "wheelZoom" },
                  { type = "toggle", label = "Zoomknöpfe ausblenden", key = "hideZoomButtons" })
            B:Row({ type = "toggle", label = "Knöpfe in einer Spalte links", key = "buttonColumn", reload = true,
                    description = "Verfolgung, Post und Schwierigkeit neben der Karte statt auf ihrem Rand." },
                  { type = "toggle", label = "Addon-Knöpfe sammeln", key = "addonBag", reload = true,
                    description = "Ein Knopf unten links neben der Karte klappt alle Addon-Knöpfe auf." })
            B:Note("Wo die Minikarte steht, stellst du im Bearbeitungsmodus des Spiels ein (Esc → Bearbeitungsmodus).")
        end },
    },
})
