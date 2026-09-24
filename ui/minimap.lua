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
    add(_G.GameTimeFrame)
    local ind = type(cl) == "table" and cl.IndicatorFrame or nil
    add(type(ind) == "table" and ind.MailFrame or nil)
    add(_G.MiniMapMailFrame)
    add(type(ind) == "table" and ind.CraftingOrderFrame or nil)
    add(type(cl) == "table" and cl.InstanceDifficulty or nil)
    add(_G.MiniMapInstanceDifficulty)
    add(_G.ExpansionLandingPageMinimapButton)
    return list
end

local laying = false
function MM.LayoutButtons()
    local mm = _G.Minimap
    if laying or type(mm) ~= "table" or not frame or not Opt("buttonColumn") then return end
    laying = true
    local y = 0
    for _, b in ipairs(ColumnButtons()) do
        b:ClearAllPoints()
        b:SetPoint("TOPRIGHT", mm, "TOPLEFT", -4, -y)
        local h = b.GetHeight and b:GetHeight() or 20
        if type(h) ~= "number" or h <= 0 or h > 60 then h = 20 end
        y = y + h + 2
    end
    laying = false
end
MM.ColumnButtons = ColumnButtons

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
    UpdateTexts()
end

local function Enable()
    local mm = _G.Minimap
    if type(mm) ~= "table" then return end

    frame = CreateFrame("Frame", nil, mm)
    frame:SetAllPoints(mm)
    frame:SetFrameLevel((mm:GetFrameLevel() or 1) + 5)
    border = K.Border(mm, 1, 0, 0, 0, 1, "OVERLAY")

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

    local acc = 1
    frame:SetScript("OnUpdate", function(_, el)
        acc = acc + (el or 0)
        if acc < 0.5 then return end
        acc = 0
        UpdateTexts()
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
            B:Row({ type = "toggle", label = "Uhrzeit", key = "clock" },
                  { type = "toggle", label = "Kalenderknopf ausblenden", key = "hideCalendar" })
            B:Section("Bedienung")
            B:Row({ type = "toggle", label = "Zoom mit dem Mausrad", key = "wheelZoom" },
                  { type = "toggle", label = "Zoomknöpfe ausblenden", key = "hideZoomButtons" })
            B:Row({ type = "toggle", label = "Knöpfe in einer Spalte links", key = "buttonColumn", reload = true,
                    description = "Verfolgung, Kalender, Post und Schwierigkeit neben der Karte statt auf ihrem Rand." },
                  { type = "empty" })
            B:Note("Wo die Minikarte steht, stellst du im Bearbeitungsmodus des Spiels ein (Esc → Bearbeitungsmodus).")
        end },
    },
})
