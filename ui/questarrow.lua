--------------------------------------------------
-- WeintCodex :: Komfort - Questpfeil
--------------------------------------------------
-- Ein Pfeil in der Bildschirmmitte, der zur ausgewaehlten Quest zeigt,
-- darunter die Entfernung. Haengt NICHT am Hauptschalter der Oberflaeche:
-- er ersetzt nichts, er kommt nur dazu.
--
-- WAS "AUSGEWAEHLT" HEISST. Die Quest, die das Spiel verfolgt
-- (C_SuperTrack - ein Klick auf eine Quest im Questlog oder in der
-- Zielverfolgung), oder die Kartenmarkierung, die man selbst gesetzt hat.
-- Der Pfeil erfindet kein Ziel: ist nichts ausgewaehlt, ist er nicht da.
--
-- WIE GERECHNET WIRD. Spieler und Ziel werden aus Kartenkoordinaten in
-- Weltkoordinaten umgerechnet (C_Map.GetWorldPosFromMapPos). Dort ist
-- x "Norden" und y "Westen", in Spieleinheiten. Die Richtung zum Ziel
-- ist atan2(Westen, Norden) - dieselbe Zaehlweise wie GetPlayerFacing
-- (0 = Norden, gegen den Uhrzeigersinn). Die Differenz beider ist der
-- Winkel, um den die Pfeiltextur gedreht wird (SetRotation dreht
-- ebenfalls gegen den Uhrzeigersinn; die Textur zeigt nach oben).
-- Die Rechnung steht in NP.Solve und wird von load_test.lua geprueft.
--
-- WAS DER CLIENT VERSCHWEIGT. In Instanzen gibt es keine Spielerposition
-- und keine Blickrichtung. Dann steht dort "Position unbekannt" - nie
-- "0 m". Ohne Blickrichtung, aber mit Position, gibt es die Entfernung
-- und eine Himmelsrichtung in Worten statt des Pfeils.
--
-- DER PFEIL IST DREIDIMENSIONAL, aber kein Modell: media/ui/arrow3d.tga
-- haelt 64 vorgerechnete Ansichten eines facettierten Pfeils (von hinten
-- oben gesehen, erzeugt von .github/scripts/make_ui_media.py). Gezeigt
-- wird die Ansicht, die dem Winkel am naechsten liegt (QA.Frame). Die
-- Farbe laeuft mit der Abweichung von Gruen (geradeaus) ueber Gelb (quer)
-- nach Rot (entgegengesetzt).
--
-- DER PFEIL DENKT MIT. Als Geist zeigt er zur eigenen Leiche, ohne dass
-- man etwas auswaehlt (C_DeathInfo). Ist die verfolgte Quest abgegeben,
-- waehlt er die naechstgelegene Quest aus dem Questlog und verfolgt sie
-- (C_SuperTrack) - wahlweise schon, sobald ihre Ziele erfuellt sind,
-- statt erst zur Abgabe zu fuehren.
--
-- METER. Das Spiel rechnet in Yards. Der deutsche Client nennt dieselbe
-- Einheit "Meter" (eine Zauberreichweite von 40 Yards steht dort als
-- "40 m Reichweite"), OHNE umzurechnen. Der Pfeil folgt dem: "m" heisst
-- hier Spieleinheit, damit "30 m" auf dem Pfeil zu "30 m Reichweite" im
-- Zauberbuch passt. Wer echte Meter will (x 0,9144), stellt es um.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIQuestArrow = {}

local QA = WeintCodex.UIQuestArrow
local K  = WeintCodex.UIKit
local C  = WeintCodex.Colors
local KEY = "questarrow"

local defaults = {
    scale      = 100,
    units      = "game",   -- game | metric | yards
    style      = "3d",     -- 3d | flat
    showTitle  = true,
    showEta    = true,
    colorByCourse = true,
    hideInCombat  = false,
    arriveDistance = 5,
    corpse     = true,     -- als Geist zur Leiche
    autoNext   = true,     -- nach dem Abgeben die naechste Quest
    onComplete = "turnin", -- turnin | next: was nach erfuellten Zielen kommt
}

local SHEET = "Interface\\AddOns\\WeintCodex\\media\\ui\\arrow3d"
local SHEET_GRID = 8                 -- 8 x 8 Ansichten
local SHEET_FRAMES = SHEET_GRID * SHEET_GRID

--------------------------------------------------
-- Rechnung (rein, ohne Client - fuer den Prueflauf)
--------------------------------------------------
-- p/t: Weltpositionen als (Norden, Westen). facing: Blickrichtung im
-- Bogenmass oder nil. Liefert Entfernung, Drehung der Pfeiltextur (nil
-- ohne Blickrichtung) und die absolute Richtung zum Ziel.

local TWO_PI = math.pi * 2

local function Norm(a)
    a = a % TWO_PI
    if a > math.pi then a = a - TWO_PI end
    return a
end

-- atan2 fehlt in manchen Lua-Fassungen als math.atan2; math.atan(y, x)
-- kann es in 5.3, in 5.1 nicht. Beides abfangen.
local function Atan2(y, x)
    if math.atan2 then return math.atan2(y, x) end
    if x > 0 then return math.atan(y / x) end
    if x < 0 then return math.atan(y / x) + (y >= 0 and math.pi or -math.pi) end
    if y > 0 then return math.pi / 2 end
    if y < 0 then return -math.pi / 2 end
    return 0
end

function QA.Solve(pN, pW, tN, tW, facing)
    local dN, dW = tN - pN, tW - pW
    local dist = math.sqrt(dN * dN + dW * dW)
    local bearing = Atan2(dW, dN)          -- 0 = Norden, + = nach Westen
    local rotation = nil
    if type(facing) == "number" then rotation = Norm(bearing - facing) end
    return dist, rotation, Norm(bearing)
end

-- Welche der 64 Ansichten zeigt den Winkel? Ansicht i ist um i*360/64
-- Grad gegen den Uhrzeigersinn gedreht, wie die Rotation. Liefert den
-- Index (0-63) und die Texturkoordinaten links, rechts, oben, unten.
function QA.Frame(rotation)
    local step = TWO_PI / SHEET_FRAMES
    local idx = math.floor((rotation % TWO_PI) / step + 0.5) % SHEET_FRAMES
    local col, row = idx % SHEET_GRID, math.floor(idx / SHEET_GRID)
    local u = 1 / SHEET_GRID
    return idx, col * u, (col + 1) * u, row * u, (row + 1) * u
end

-- Farbe nach Abweichung: 0 = geradeaus (gruen), pi/2 = quer (gelb),
-- pi = entgegengesetzt (rot). Die drei Farben kommen aus core/ui.lua.
local function Mix(a, b, t)
    return a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t, a[3] + (b[3] - a[3]) * t
end
function QA.CourseColor(rotation)
    local t = math.min(1, math.abs(Norm(rotation)) / math.pi)
    if t <= 0.5 then return Mix(C.successBright, C.warningBright, t * 2) end
    return Mix(C.warningBright, C.dangerBright, (t - 0.5) * 2)
end

-- Himmelsrichtung in Worten, fuer den Fall ohne Blickrichtung. Die
-- Richtung zaehlt gegen den Uhrzeigersinn (Westen positiv).
local COMPASS = { "Norden", "Nordwesten", "Westen", "Südwesten", "Süden", "Südosten", "Osten", "Nordosten" }
function QA.Compass(bearing)
    local idx = math.floor(((bearing % TWO_PI) + math.pi / 8) / (math.pi / 4)) % 8
    return COMPASS[idx + 1]
end

function QA.FormatDistance(yards, units)
    if units == "yards" then
        return string.format("%d yd", math.floor(yards + 0.5))
    end
    local v = (units == "metric") and (yards * 0.9144) or yards
    if v >= 1000 then
        -- Komma, nicht Punkt: deutsche Oberflaeche.
        return (string.format("%.1f km", v / 1000):gsub("%.", ","))
    end
    return string.format("%d m", math.floor(v + 0.5))
end

--------------------------------------------------
-- Ziel ermitteln
--------------------------------------------------

local function PlayerMapPos()
    local cm = _G.C_Map
    if not (cm and cm.GetBestMapForUnit and cm.GetPlayerMapPosition) then return nil end
    local mapID = cm.GetBestMapForUnit("player")
    if not mapID then return nil end
    local pos = cm.GetPlayerMapPosition(mapID, "player")
    if not pos then return nil end
    local x, y = pos.x, pos.y
    if pos.GetXY then x, y = pos:GetXY() end
    if type(K.Plain(x)) ~= "number" or type(K.Plain(y)) ~= "number" then return nil end
    return mapID, x, y
end

-- Ein Vektor fuer alle Umrechnungen statt eines neuen je Takt.
local vec
local function ToWorld(mapID, x, y)
    local cm = _G.C_Map
    if not (cm and cm.GetWorldPosFromMapPos and _G.CreateVector2D) then return nil end
    if vec and vec.SetXY then vec:SetXY(x, y) else vec = _G.CreateVector2D(x, y) end
    local ok, continent, world = pcall(cm.GetWorldPosFromMapPos, mapID, vec)
    if not ok or not world then return nil end
    local n, w = world.x, world.y
    if world.GetXY then n, w = world:GetXY() end
    if type(n) ~= "number" or type(w) ~= "number" then return nil end
    return continent, n, w
end

local function QuestTitle(questID)
    local ql = _G.C_QuestLog
    if ql and ql.GetTitleForQuestID then return ql.GetTitleForQuestID(questID) end
    return nil
end

-- Wo liegt die Quest? Zuerst der naechste Wegpunkt (fuehrt ueber
-- Gebietsgrenzen), dann die Questmarkierung auf der Karte, auf der der
-- Spieler steht, dann auf der Karte der Quest selbst.
local function QuestLocation(questID, playerMap)
    local ql = _G.C_QuestLog
    if not ql then return nil end

    if ql.GetNextWaypoint then
        local mapID, x, y = ql.GetNextWaypoint(questID)
        if mapID and x and y then return mapID, x, y, true end
    end

    local maps = { playerMap }
    if _G.GetQuestUiMapID then
        local qm = _G.GetQuestUiMapID(questID)
        if qm and qm ~= 0 and qm ~= playerMap then maps[#maps + 1] = qm end
    end
    if ql.GetQuestsOnMap then
        for _, mapID in ipairs(maps) do
            for _, info in ipairs(ql.GetQuestsOnMap(mapID) or {}) do
                if info.questID == questID and info.x and info.y then
                    return mapID, info.x, info.y, false
                end
            end
        end
    end
    return nil
end

-- Liefert: status, mapID, x, y, title
--   "none"     nichts ausgewaehlt
--   "ok"       Ziel bekannt
--   "unknown"  ausgewaehlt, aber der Client nennt keinen Ort
-- Die eigene Leiche, solange man Geist ist. Das Spiel nennt ihre Lage
-- auf einer bestimmten Karte; gesucht wird auf der eigenen und ihren
-- Elternkarten (die Leiche liegt oft im Nachbargebiet).
local function CorpseTarget(playerMap)
    if not K.Get(KEY, "corpse") then return nil end
    if not (_G.UnitIsGhost and K.Bool(_G.UnitIsGhost("player"), false)) then return nil end
    local di, cm = _G.C_DeathInfo, _G.C_Map
    if not (di and di.GetCorpseMapPosition) or not playerMap then return "unknown" end
    local map = playerMap
    for _ = 1, 4 do
        local ok, pos = pcall(di.GetCorpseMapPosition, map)
        if ok and pos then
            local x, y = pos.x, pos.y
            if pos.GetXY then x, y = pos:GetXY() end
            if type(x) == "number" and type(y) == "number" then return "ok", map, x, y end
        end
        local info = cm and cm.GetMapInfo and cm.GetMapInfo(map)
        map = info and info.parentMapID
        if not map or map == 0 then break end
    end
    return "unknown"
end

local function IsComplete(questID)
    local ql = _G.C_QuestLog
    return ql and ql.IsComplete and K.Bool(ql.IsComplete(questID), false) or false
end

local function ResolveTarget(playerMap)
    local cs, cmap, cx, cy = CorpseTarget(playerMap)
    if cs then return cs, cmap, cx, cy, "Deine Leiche", "corpse" end

    local st = _G.C_SuperTrack
    if not st then return "none" end

    if st.IsSuperTrackingUserWaypoint and st.IsSuperTrackingUserWaypoint()
       and _G.C_Map and _G.C_Map.GetUserWaypoint then
        local wp = _G.C_Map.GetUserWaypoint()
        if wp and wp.uiMapID and wp.position then
            local x, y = wp.position.x, wp.position.y
            if wp.position.GetXY then x, y = wp.position:GetXY() end
            return "ok", wp.uiMapID, x, y, "Kartenmarkierung"
        end
    end

    local questID = st.GetSuperTrackedQuestID and st.GetSuperTrackedQuestID()
    if not questID or questID == 0 then return "none" end
    local title = QuestTitle(questID) or "Quest"
    -- Ziele erfuellt: der Ort ist jetzt der, an dem man abgibt (das Spiel
    -- verlegt Wegpunkt und Markierung dorthin).
    if IsComplete(questID) then title = "Abgeben: " .. title end
    local mapID, x, y = QuestLocation(questID, playerMap)
    if not mapID then return "unknown", nil, nil, nil, title, "quest" end
    return "ok", mapID, x, y, title, "quest"
end

--------------------------------------------------
-- Die naechste Quest
--------------------------------------------------
-- Die naechstgelegene Quest im Questlog, die einen Ort auf dem eigenen
-- Kontinent hat. `skip` wird ausgelassen (die gerade abgegebene), mit
-- `incompleteOnly` auch alle, deren Ziele schon erfuellt sind.

function QA.NearestQuest(skip, incompleteOnly)
    local ql = _G.C_QuestLog
    if not (ql and ql.GetNumQuestLogEntries and ql.GetInfo) then return nil end
    local playerMap, px, py = PlayerMapPos()
    if not playerMap then return nil end
    local pc, pN, pW = ToWorld(playerMap, px, py)
    if not pc then return nil end
    local best, bestDist
    for i = 1, (ql.GetNumQuestLogEntries() or 0) do
        local info = ql.GetInfo(i)
        local id = info and info.questID
        if id and id ~= 0 and id ~= skip and not info.isHeader and not info.isHidden
           and not (incompleteOnly and IsComplete(id)) then
            local mapID, x, y = QuestLocation(id, playerMap)
            if mapID then
                local tc, tN, tW = ToWorld(mapID, x, y)
                if tc == pc then
                    local d = QA.Solve(pN, pW, tN, tW, nil)
                    if not bestDist or d < bestDist then best, bestDist = id, d end
                end
            end
        end
    end
    return best, bestDist
end

local function TrackNext(skip, incompleteOnly)
    local st = _G.C_SuperTrack
    if not (st and st.SetSuperTrackedQuestID) then return end
    local id = QA.NearestQuest(skip, incompleteOnly)
    if id then pcall(st.SetSuperTrackedQuestID, id) end
end

--------------------------------------------------
-- Anzeige
--------------------------------------------------

local frame, arrow, title, dist, eta

local function Is3D() return K.Get(KEY, "style") ~= "flat" end

-- Den Pfeil auf einen Winkel stellen: im 3D-Stil die passende Ansicht,
-- flach die gedrehte Pfeilform.
local function PointArrow(rotation)
    if Is3D() then
        local _, l, r, t, b = QA.Frame(rotation)
        arrow:SetRotation(0)
        arrow:SetTexCoord(l, r, t, b)
    else
        arrow:SetTexCoord(0, 1, 0, 1)
        arrow:SetRotation(rotation)
    end
end


local function Build()
    frame = CreateFrame("Frame", "WeintCodexQuestArrow", UIParent)
    frame:SetSize(120, 96)
    frame:SetFrameStrata("MEDIUM")
    frame:Hide()

    arrow = frame:CreateTexture(nil, "ARTWORK")
    arrow:SetTexture(K.ARROW_TEXTURE)
    arrow:SetSize(52, 52)
    arrow:SetPoint("TOP", frame, "TOP", 0, -14)

    title = K.NewText(frame)
    title:SetPoint("BOTTOM", arrow, "TOP", 0, 2)
    title:SetWidth(260)
    title:SetWordWrap(false)

    dist = K.NewText(frame)
    dist:SetPoint("TOP", arrow, "BOTTOM", 0, -2)

    eta = K.NewText(frame)
    eta:SetPoint("TOP", dist, "BOTTOM", 0, -1)

    -- Fuer den Prueflauf: was der Pfeil gerade anzeigt.
    QA.frame, QA.arrow = frame, arrow
    QA.texts = { title = title, dist = dist, eta = eta }

    frame.WCShowForUnlock = function(self, on)
        self._unlock = on and true or nil
        if on then
            title:SetText("Questpfeil")
            dist:SetText("120 m")
            eta:SetText("")
            PointArrow(0)
            arrow:SetVertexColor(unpack(C.successBright))
            arrow:Show()
            self:Show()
        else
            QA.Update()
        end
    end
end

local function ApplyStyle()
    if not frame then return end
    frame:SetScale((K.Get(KEY, "scale") or 100) / 100)
    if Is3D() then
        arrow:SetTexture(SHEET)
        arrow:SetSize(72, 72)
    else
        arrow:SetTexture(K.ARROW_TEXTURE)
        arrow:SetSize(52, 52)
    end
    K.SetFont(title, 12)
    K.SetFont(dist, 14)
    K.SetFont(eta, 10)
    title:SetTextColor(unpack(C.textNormal))
    dist:SetTextColor(unpack(C.textBright))
    eta:SetTextColor(unpack(C.textMuted))
end

local lastYards, lastTime

local function SetArrowColor(rotation)
    if K.Get(KEY, "colorByCourse") then
        arrow:SetVertexColor(QA.CourseColor(rotation))
    else
        arrow:SetVertexColor(unpack(C.textBright))
    end
end

-- Das Ziel aendert sich selten, die eigene Position staendig. Das Ziel
-- wird deshalb nur bei einem Ereignis (force), beim Kartenwechsel oder
-- einmal je Sekunde neu gesucht - GetQuestsOnMap legt bei jedem Aufruf
-- eine Tabelle an, und zwanzigmal je Sekunde waere das reiner Muell.
local cache = { at = -1 }
local function Target(playerMap, force)
    local now = _G.GetTime and _G.GetTime() or 0
    if not force and cache.at >= 0 and cache.map == playerMap and (now - cache.at) < 1 then
        return cache
    end
    local status, mapID, tx, ty, name, kind = ResolveTarget(playerMap)
    cache.at, cache.map, cache.status, cache.title, cache.kind = now, playerMap, status, name, kind
    cache.tc, cache.tN, cache.tW = nil, nil, nil
    if status == "ok" then cache.tc, cache.tN, cache.tW = ToWorld(mapID, tx, ty) end
    return cache
end

function QA.Update(force)
    if not frame or frame._unlock then return end
    if not K.IsActive(KEY) then frame:Hide() return end
    if K.Get(KEY, "hideInCombat") and K.InCombat() then frame:Hide() return end

    local playerMap, px, py = PlayerMapPos()
    local t = Target(playerMap, force)
    local status, name = t.status, t.title
    if status == "none" then frame:Hide() return end

    local showTitle = K.Get(KEY, "showTitle")
    title:SetText(showTitle and name or "")
    eta:SetText("")

    -- Zuerst die eigene Position: ohne sie laesst sich auch der Ort der
    -- Quest nicht suchen (er haengt an der Karte, auf der man steht), und
    -- "Ort unbekannt" waere dann eine Behauptung ueber die Quest statt
    -- ueber den Client.
    if not playerMap then
        arrow:Hide()
        dist:SetText("Position unbekannt")
        frame:Show()
        return
    end
    if status == "unknown" then
        arrow:Hide()
        dist:SetText("Ort unbekannt")
        frame:Show()
        return
    end

    local pc, pN, pW = ToWorld(playerMap, px, py)
    local tc, tN, tW = t.tc, t.tN, t.tW
    if not pc then
        arrow:Hide()
        dist:SetText("Position unbekannt")
        frame:Show()
        return
    end
    if not tc then
        arrow:Hide()
        dist:SetText("Ort unbekannt")
        frame:Show()
        return
    end
    if pc ~= tc then
        arrow:Hide()
        dist:SetText("Anderer Kontinent")
        frame:Show()
        return
    end

    local facing = _G.GetPlayerFacing and K.Plain(_G.GetPlayerFacing())
    local yards, rotation, bearing = QA.Solve(pN, pW, tN, tW, facing)

    if yards <= (K.Get(KEY, "arriveDistance") or 5) then
        arrow:Hide()
        dist:SetText(t.kind == "corpse" and "Bei deiner Leiche" or "Am Ziel")
        frame:Show()
        return
    end

    dist:SetText(QA.FormatDistance(yards, K.Get(KEY, "units")))
    if rotation then
        PointArrow(rotation)
        SetArrowColor(rotation)
        arrow:Show()
    else
        arrow:Hide()
        dist:SetText(QA.FormatDistance(yards, K.Get(KEY, "units")) .. " · " .. QA.Compass(bearing))
    end

    -- Ankunftszeit aus der tatsaechlichen Annaeherung, nicht aus der
    -- Laufgeschwindigkeit: wer im Zickzack um einen Berg laeuft, kommt
    -- nicht mit Laufgeschwindigkeit naeher.
    if K.Get(KEY, "showEta") and _G.GetTime then
        local now = _G.GetTime()
        if lastYards and lastTime and now > lastTime then
            local speed = (lastYards - yards) / (now - lastTime)
            QA._speed = (QA._speed or speed) * 0.85 + speed * 0.15
            if QA._speed > 0.5 then
                local secs = math.floor(yards / QA._speed + 0.5)
                eta:SetText(string.format("ca. %d:%02d", math.floor(secs / 60), secs % 60))
            end
        end
        lastYards, lastTime = yards, now
    end
    frame:Show()
end

--------------------------------------------------
-- Takt und Ereignisse
--------------------------------------------------
-- Der Pfeil muss der Kamera folgen, und fuer die Blickrichtung gibt es
-- kein Ereignis. Zwanzigmal je Sekunde, und nur solange etwas
-- ausgewaehlt ist - ohne Ziel laeuft der Takt nicht.

local ticker = CreateFrame("Frame")
local acc = 0
local function OnTick(_, elapsed)
    acc = acc + (elapsed or 0)
    if acc < 0.05 then return end
    acc = 0
    QA.Update()
    -- Auswahl weg (oder im Kampf ausgeblendet): der Takt steht, bis ein
    -- Ereignis ihn wieder anwirft.
    if not (frame and frame:IsShown()) then ticker:SetScript("OnUpdate", nil) end
end

local events = CreateFrame("Frame")
local function Refresh()
    lastYards, lastTime, QA._speed = nil, nil, nil
    QA.Update(true)
    if frame and frame:IsShown() and not frame._unlock then
        ticker:SetScript("OnUpdate", OnTick)
    else
        ticker:SetScript("OnUpdate", nil)
    end
end

-- Die Quest, die gerade verfolgt wird - damit beim Abgeben klar ist, ob
-- es DIE war (dann die naechste waehlen) oder irgendeine andere.
local tracked
local advanced = {}   -- [questID] = true: nach erfuellten Zielen schon weitergeschaltet

local function Later(fn)
    if _G.C_Timer and _G.C_Timer.After then _G.C_Timer.After(0.3, fn) else fn() end
end

local function OnEvent(_, event, questID)
    local st = _G.C_SuperTrack
    local current = st and st.GetSuperTrackedQuestID and st.GetSuperTrackedQuestID()
    if current == 0 then current = nil end

    if event == "QUEST_TURNED_IN" or event == "QUEST_REMOVED" then
        -- Abgegeben (oder abgebrochen): war es die verfolgte Quest, und
        -- verfolgt das Spiel jetzt nichts mehr oder sie noch, geht es
        -- zur naechsten.
        if K.Get(KEY, "autoNext") and questID and questID == tracked
           and (not current or current == questID) then
            Later(function() TrackNext(questID, false) Refresh() end)
        end
    elseif event == "QUEST_LOG_UPDATE" and current and K.Get(KEY, "onComplete") == "next"
           and not advanced[current] and IsComplete(current) then
        advanced[current] = true
        local done = current
        Later(function() TrackNext(done, true) Refresh() end)
    end
    tracked = current or tracked
    if event == "SUPER_TRACKING_CHANGED" then tracked = current end
    Refresh()
end

local function Enable()
    if not frame then
        Build()
        K.RegisterMover(frame, "questarrow", "Questpfeil",
            -- Ganz oben: darunter schreibt das Spiel seine roten Fehler
            -- ("Fähigkeit ist noch nicht bereit"), in 6.0.0.5 mitten in
            -- den Pfeil.
            { point = "TOP", relPoint = "TOP", x = 0, y = -8 })
    end
    K.SetMoverEnabled("questarrow", true)
    ApplyStyle()
    for _, e in ipairs({
        "SUPER_TRACKING_CHANGED", "QUEST_LOG_UPDATE", "QUEST_POI_UPDATE",
        "USER_WAYPOINT_UPDATED", "ZONE_CHANGED", "ZONE_CHANGED_NEW_AREA",
        "ZONE_CHANGED_INDOORS", "PLAYER_ENTERING_WORLD", "WAYPOINT_UPDATE",
        "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED",
        "QUEST_TURNED_IN", "QUEST_REMOVED",
        "PLAYER_DEAD", "PLAYER_ALIVE", "PLAYER_UNGHOST", "CORPSE_POSITION_UPDATE",
    }) do pcall(events.RegisterEvent, events, e) end
    events:SetScript("OnEvent", OnEvent)
    -- K.Activate setzt _active erst nach Enable; der erste Stand kommt
    -- deshalb einen Takt spaeter aus dem ersten Ereignis oder hier.
    if _G.C_Timer and _G.C_Timer.After then _G.C_Timer.After(0, Refresh) end
end

local function Disable()
    events:UnregisterAllEvents()
    ticker:SetScript("OnUpdate", nil)
    if frame then frame:Hide() end
    K.SetMoverEnabled("questarrow", false)
end

--------------------------------------------------
-- Modul
--------------------------------------------------

K.Register({
    key = KEY, group = "qol", order = 50,
    title = "Questpfeil",
    description = "Zeigt zur ausgewählten Quest oder Kartenmarkierung, mit Entfernung und ungefährer Ankunftszeit.",
    defaultEnabled = true,
    defaults = defaults,
    Enable = Enable,
    Disable = Disable,
    OnSetting = function()
        ApplyStyle()
        Refresh()
    end,
    pages = {
        { key = "allgemein", label = "Allgemein", build = function(B)
            B:Section("Anzeige")
            B:Row({ type = "slider", label = "Größe", key = "scale", min = 50, max = 200, step = 5,
                    format = function(v) return string.format("%d %%", v) end },
                  { type = "dropdown", label = "Einheit", key = "units", items = {
                        { value = "game",   text = "m (wie der deutsche Client)" },
                        { value = "metric", text = "echte Meter (× 0,9144)" },
                        { value = "yards",  text = "Yards" } } })
            B:Row({ type = "toggle", label = "Name der Quest", key = "showTitle" },
                  { type = "toggle", label = "Ankunftszeit", key = "showEta",
                    description = "Aus der tatsächlichen Annäherung der letzten Sekunden." })
            B:Row({ type = "dropdown", label = "Pfeil", key = "style", items = {
                        { value = "3d",   text = "Dreidimensional" },
                        { value = "flat", text = "Flach" } } },
                  { type = "toggle", label = "Farbe nach Richtung", key = "colorByCourse",
                    description = "Grün geradeaus, gelb quer, rot in die falsche Richtung." })
            B:Row({ type = "toggle", label = "Im Kampf ausblenden", key = "hideInCombat" },
                  { type = "empty" })
            B:Row({ type = "slider", label = "„Am Ziel“ ab", key = "arriveDistance", min = 2, max = 30, step = 1,
                    format = function(v) return string.format("%d m", v) end },
                  { type = "empty" })
            B:Section("Mitdenken")
            B:Row({ type = "toggle", label = "Als Geist zur Leiche", key = "corpse",
                    description = "Nach dem Tod zeigt der Pfeil von selbst zu deiner Leiche." },
                  { type = "toggle", label = "Nach dem Abgeben weiter", key = "autoNext",
                    description = "Die nächstgelegene Quest aus deinem Questlog wird ausgewählt." })
            B:Row({ type = "dropdown", label = "Wenn die Ziele erfüllt sind", key = "onComplete", items = {
                        { value = "turnin", text = "Zur Abgabe führen" },
                        { value = "next",   text = "Gleich zur nächsten Quest" } } },
                  { type = "empty" })
            B:Section("So benutzt du ihn")
            B:Note("Klicke im Questlog oder in der Zielverfolgung auf eine Quest, um sie auszuwählen — oder setze auf der Weltkarte eine Markierung. Der Pfeil erscheint, sobald etwas ausgewählt ist, und verschwindet wieder, wenn nichts ausgewählt ist.")
            B:Note("In Dungeons nennt das Spiel Addons keine Position. Dort steht „Position unbekannt“ statt einer Zahl.")
            B:Note("„m“ ist die Spieleinheit, die der deutsche Client auch in Zauberreichweiten „Meter“ nennt. Echte Meter sind etwa 9 % weniger.")
        end },
    },
})
