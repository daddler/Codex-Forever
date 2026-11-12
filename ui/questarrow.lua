--------------------------------------------------
-- WeintCodex :: Komfort - Questpfeil
--------------------------------------------------
-- Ein Pfeil in der Bildschirmmitte, der zur ausgewaehlten Quest zeigt,
-- darunter die Entfernung. Haengt NICHT am Hauptschalter der Oberflaeche:
-- er ersetzt nichts, er kommt nur dazu.
--
-- WAS "AUSGEWAEHLT" HEISST. Seit 6.6.2.7 plant der Pfeil selbst: das
-- naechste lohnende Ziel aus dem Questlog (siehe "Planen" unten). Eine
-- Kartenmarkierung oder eine Quest, die der Spieler selbst anklickt, geht
-- vor. Der Pfeil erfindet kein Ziel: ohne Quest mit Ort und ohne
-- Markierung ist er nicht da. Mit plan = "tracked" folgt er wie bis
-- 6.6.2.6 nur der Quest, die das Spiel verfolgt (C_SuperTrack).
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
-- waehlt er die naechstgelegene Quest aus dem Questlog - wahlweise schon,
-- sobald ihre Ziele erfuellt sind, statt erst zur Abgabe zu fuehren.
-- SEIT 6.6.0.1 NUR FUER SICH SELBST (QA.Chosen), nicht mehr ueber
-- C_SuperTrack.SetSuperTrackedQuestID: ein Aufruf aus dem Addon laesst
-- Blizzards Questverfolgung und die Questmarken der Weltkarte "von
-- WeintCodex beruehrt" weiterlaufen, und im Kampf blockiert das Spiel dann
-- SetPassThroughButtons (Beta-Test, ADDON_ACTION_BLOCKED beim Umstellen
-- der Questprioritaet). Waehlt der Spieler selbst eine Quest, gilt wieder
-- seine Wahl.
--
-- HOEHE (6.6.0.1, Beta-Test: "der Pfeil muss unterschiedliche Hoehen
-- erkennen - Hoehle oder Berg"). Die Karte ist flach: Questorte haben dort
-- nur x und y. Die einzige Hoehe, die der Client einem Addon nennt, ist die
-- der Navigation zum verfolgten Ziel (C_Navigation): die Luftlinie im Raum
-- (GetDistance) und ein Punkt auf dem Bildschirm genau am Ziel (GetFrame),
-- dazu, ob das Ziel verdeckt ist (Occluded). Daraus:
--   * Hoehenunterschied = Wurzel(Luftlinie^2 - Abstand auf der Karte^2).
--     WIE GROSS, nicht in welche Richtung - das verraet der Client nicht.
--   * HOEHER ODER TIEFER (6.6.0.8, Beta-Test: "sagt mir nicht, ob nach
--     oben oder unten"). Nur, wenn der Client die eigene Hoehe nennt
--     (dritter Wert von UnitPosition - im normalen Spiel immer 0, auf
--     Forever ungeprueft, /wcui pfeil sagt es). Dann: steigt man und der
--     Unterschied schrumpft, liegt das Ziel hoeher; waechst er, tiefer
--     (QA.TrackHeight). Ohne eigene Hoehe bleibt es bei "wie gross" -
--     nie geraten. Erst mit der Richtung kippt ein kleiner Pfeil neben
--     dem grossen nach oben oder unten.
--   * "verdeckt": Hoehle, Gebaeude oder hinter einem Hang.
--   * Eine Zielmarke im Raum (QA.marker) am Bildschirmpunkt des Ziels:
--     sie steht oben am Berg oder unten am Hoehleneingang, wo das Ziel ist.
-- Nur, wenn der Pfeil auf dasselbe Ziel zeigt wie die Navigation des
-- Spiels (Kartenmarkierung oder vom Spiel verfolgte Quest) - bei einer
-- eigenen Wahl des Pfeils (QA.Chosen) zeigt die Navigation woandershin.
-- Zeigt das Spiel seine eigene Marke (SuperTrackedFrame), bleibt unsere weg.
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
    -- In Dungeons, Schlachtzuegen, Schlachtfeldern und Arenen aus (Beta-Test
    -- 6.3.2.7). Dort nennt das Spiel ohnehin keine Position - der Pfeil
    -- stand nur als "Position unbekannt" im Bild.
    hideInInstance = true,
    arriveDistance = 5,
    markerNear = 100,      -- Zielmarke im Raum erst ab dieser Naehe (6.74.0.0)
    showHeight  = true,    -- Hoehenunterschied und "verdeckt" (6.6.0.1)
    worldMarker = true,    -- Zielmarke im Raum am Ort des Ziels (6.6.0.1)
    corpse     = true,     -- als Geist zur Leiche
    ghostHealer = false,   -- als Geist zum Geistheiler, wenn der klar naeher ist
    -- Welches Ziel (6.6.2.7): "smart" plant selbst - das naechste lohnende
    -- Ziel aus dem ganzen Questlog; "tracked" folgt nur der Quest, die das
    -- Spiel verfolgt (alles vor 6.6.2.7).
    plan       = "smart",
    -- 1.0.5.63 (Feedback: "erst alle Quests des Gebiets, am Ende alle
    -- abgeben"): Abgaben erst, wenn im Gebiet nichts Offenes mehr liegt.
    collect    = false,
    -- 1.0.5.63 (Stream: die Symbole vor den Quests fehlten): die
    -- Spieleinstellung "questPOI" an - an ihr haengen die Symbole.
    questIcons = true,
    autoNext   = true,     -- nach dem Abgeben die naechste Quest
    onComplete = "turnin", -- turnin | next: was nach erfuellten Zielen kommt
    -- Routenplaner (6.31.0.0, ui/route.lua): zeigt auf den naechsten
    -- Wegpunkt - Flugmeister, Anleger, Portal -, wenn das schneller ist.
    routePlan  = true,
    terrain    = true,     -- Laufweg ueber das Gelaende (6.32.0.0, ui/navmesh.lua)
    shareTimes = true,     -- Abfahrtszeiten mit Gilde und Gruppe teilen (6.32.0.0)
    mapRoute   = true,     -- Route auf der Weltkarte (6.32.1.0, ui/maproute.lua)
    mapLines   = true,     -- Schiffs-, Zeppelin- und Bahnlinien auf der Weltkarte
    taxiReminder = true,   -- unbekannter Flugpunkt in der Naehe: erinnern (6.32.2.0)
    routeColor = "auto",   -- auto | yellow | alt: Farbe der Route auf der Weltkarte (6.32.3.0)
    -- Kompass (6.35.0.0, ui/compass.lua): Band mit Himmelsrichtungen.
    compass    = "off",    -- off | both (Pfeil und Kompass) | only (nur Kompass)
    compassScale = 100,
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

-- Texte, die fuenfmal je Sekunde gesetzt werden, nur neu bauen, wenn sich
-- die angezeigte Zahl aendert (6.32.2.0: /wcui speicher nannte den Pfeil
-- mit 2,9 KB/s den groessten Abfall). Je Feld ein Merker.
local memo = { dist = {}, eta = {}, title = {} }
QA._memo = memo
local function DistKey(yards, units)
    if units == "yards" then return math.floor(yards + 0.5) end
    local v = (units == "metric") and (yards * 0.9144) or yards
    if v >= 1000 then return 100000 + math.floor(v / 100 + 0.5) end
    return math.floor(v + 0.5)
end
function QA.DistText(yards, units, suffix)
    local m = memo.dist
    local key = DistKey(yards, units)
    if m.key ~= key or m.units ~= units or m.suffix ~= suffix then
        m.key, m.units, m.suffix = key, units, suffix
        m.text = QA.FormatDistance(yards, units) .. (suffix or "")
    end
    return m.text
end
function QA.EtaText(secs)
    local m = memo.eta
    if m.secs ~= secs then m.secs, m.text = secs, string.format("ca. %d:%02d", math.floor(secs / 60), secs % 60) end
    return m.text
end
local function ViaTitle(name, waypoint)
    local m = memo.title
    if m.name ~= name or m.waypoint ~= waypoint then
        m.name, m.waypoint, m.text = name, waypoint, (name or "") .. " – über " .. waypoint
    end
    return m.text
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

-- Eigene Lage ohne Wegwerf-Vektoren: K.BestMap, K.PlayerWorld (ui/kit.lua,
-- 6.14.0.2 - vorher fuenfmal je Sekunde zwei Vektoren, 26 KB/s).
local BestMap, PlayerWorld = K.BestMap, K.PlayerWorld
QA.PlayerWorld = PlayerWorld

local function QuestTitle(questID)
    local ql = _G.C_QuestLog
    if ql and ql.GetTitleForQuestID then return ql.GetTitleForQuestID(questID) end
    return nil
end

-- Wo liegt die Quest? Zuerst der naechste Wegpunkt (fuehrt ueber
-- Gebietsgrenzen), dann die Questmarkierung auf der Karte, auf der der
-- Spieler steht, dann auf der Karte der Quest selbst.
-- onMap: gemerkte GetQuestsOnMap je Karte fuer einen Planungslauf (eine
-- Abfrage je Karte statt je Quest). final: der Ort der Quest SELBST zuerst,
-- der Wegpunkt nur ersatzweise - zum Vergleichen von Entfernungen. Der
-- Wegpunkt liegt am Gebietsausgang und liesse eine Quest im Nachbargebiet
-- naeher aussehen, als sie ist.
local function OnMap(ql, mapID, onMap)
    if not ql.GetQuestsOnMap then return nil end
    if onMap then
        local list = onMap[mapID]
        if list == nil then
            list = ql.GetQuestsOnMap(mapID) or false
            onMap[mapID] = list
        end
        return list or nil
    end
    return ql.GetQuestsOnMap(mapID)
end

local function QuestLocation(questID, playerMap, onMap, final)
    local ql = _G.C_QuestLog
    if not ql then return nil end

    local wm, wx, wy
    if ql.GetNextWaypoint then
        wm, wx, wy = ql.GetNextWaypoint(questID)
        if not (wm and wx and wy) then wm = nil end
        if wm and not final then return wm, wx, wy, true end
    end

    local qm = _G.GetQuestUiMapID and _G.GetQuestUiMapID(questID)
    if qm == 0 or qm == playerMap then qm = nil end
    for i = 1, 2 do
        local mapID = (i == 1) and playerMap or qm
        local list = mapID and OnMap(ql, mapID, onMap)
        for _, info in ipairs(list or {}) do
            if info.questID == questID and info.x and info.y then
                return mapID, info.x, info.y, false
            end
        end
    end
    if wm then return wm, wx, wy, true end
    return nil
end

QA.QuestLocation = QuestLocation
QA.QuestTitle = QuestTitle

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

-- Als Geist zum Geistheiler (Verhalten wie RestedXP, eigener Code): nur
-- wenn er KLAR naeher ist als die Leiche (QA.GHOST_RATIO), sonst bleibt es
-- bei der Leiche. Die Lagen stehen in data/mapmarks.lua (erzeugt), auf der
-- Karte, auf der man steht.
QA.GHOST_RATIO = 0.6
function QA.PickGhost(corpseD, healerD, ratio)
    return type(corpseD) == "number" and type(healerD) == "number"
        and healerD < corpseD * (ratio or QA.GHOST_RATIO) or false
end
function QA.GhostHealer(playerMap, cmap, cx, cy)
    if not K.Get(KEY, "ghostHealer") or type(playerMap) ~= "number" then return nil end
    local d = WeintCodex.MapMarksData
    local list = d and d.spirit and d.spirit[playerMap]
    if type(list) ~= "table" then return nil end
    local pc, pN, pW = PlayerWorld()
    if not pc then return nil end
    local cc, cN, cW = ToWorld(cmap, cx, cy)
    if cc ~= pc then return nil end
    local corpseD = math.sqrt((cN - pN) ^ 2 + (cW - pW) ^ 2)
    local bestD, bx, by
    for i = 1, #list - 1, 2 do
        local c, n, w = ToWorld(playerMap, list[i], list[i + 1])
        if c == pc then
            local dd = math.sqrt((n - pN) ^ 2 + (w - pW) ^ 2)
            if not bestD or dd < bestD then bestD, bx, by = dd, list[i], list[i + 1] end
        end
    end
    QA.ghostLast = bestD and string.format("Leiche %.0f, Geistheiler %.0f", corpseD, bestD) or nil
    if QA.PickGhost(corpseD, bestD) then return playerMap, bx, by end
    return nil
end

local function IsComplete(questID)
    local ql = _G.C_QuestLog
    -- Dieselbe strenge Pruefung wie die Erfahrungsleiste (6.28.1.0).
    local XB = WeintCodex.UIXPBar
    if XB and XB.QuestReady then return XB.QuestReady(questID) end
    return ql and ql.IsComplete and K.Bool(ql.IsComplete(questID), false) or false
end

local function ResolveTarget(playerMap)
    local cs, cmap, cx, cy = CorpseTarget(playerMap)
    if cs then
        if cs == "ok" then
            local hm, hx, hy = QA.GhostHealer(playerMap, cmap, cx, cy)
            if hm then return "ok", hm, hx, hy, "Geistheiler", "healer" end
        end
        return cs, cmap, cx, cy, "Deine Leiche", "corpse"
    end

    -- 6.57.0.0: eigenes Ziel (Buch der Bibliothek, modules/library.lua) -
    -- bis es erledigt ist oder der Spieler es loest (QA.Skip).
    local cu = QA.custom
    if cu then
        if cu.done and cu.done() then
            QA.ClearCustom()
        else
            return "ok", cu.map, cu.x, cu.y, cu.title, "custom", QA.PinIsOurs()
        end
    end

    local st = _G.C_SuperTrack
    if not st then return "none" end

    if st.IsSuperTrackingUserWaypoint and K.Bool(st.IsSuperTrackingUserWaypoint(), false)
       and _G.C_Map and _G.C_Map.GetUserWaypoint then
        local wp = _G.C_Map.GetUserWaypoint()
        if wp and wp.uiMapID and wp.position then
            local x, y = wp.position.x, wp.position.y
            if wp.position.GetXY then x, y = wp.position:GetXY() end
            return "ok", wp.uiMapID, x, y, "Kartenmarkierung", "waypoint", true
        end
    end

    local game = st.GetSuperTrackedQuestID and st.GetSuperTrackedQuestID()
    if game == 0 then game = nil end
    -- Selbst gewaehlt schlaegt geplant schlaegt vom Spiel gewaehlt.
    local questID = QA.manual or QA.Chosen or game
    if not questID or questID == 0 then return "none" end
    -- Die Navigation des Spiels fuehrt zur Quest, die das SPIEL verfolgt.
    local nav = (questID == game)
    local title = QuestTitle(questID) or "Quest"
    -- Ziele erfuellt: der Ort ist jetzt der, an dem man abgibt (das Spiel
    -- verlegt Wegpunkt und Markierung dorthin).
    if IsComplete(questID) then title = "Abgeben: " .. title end
    QA.lastQuest = questID
    local mapID, x, y = QuestLocation(questID, playerMap)
    if not mapID then return "unknown", nil, nil, nil, title, "quest" end
    return "ok", mapID, x, y, title, "quest", nav
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

-- Die Wahl bleibt beim Pfeil (QA.Chosen) - kein C_SuperTrack, siehe oben.
local function TrackNext(skip, incompleteOnly)
    QA.Chosen = QA.NearestQuest(skip, incompleteOnly)
end

--------------------------------------------------
-- Planen (6.6.2.7)
--------------------------------------------------
-- Beta-Test: "nicht intelligent, schickt mich immer durch die
-- Weltgeschichte". Bis 6.6.2.6 folgte der Pfeil der Quest, die das SPIEL
-- verfolgt - und das Spiel waehlt sie selbst (beim Annehmen, nach dem
-- Abgeben), ohne auf die Entfernung zu schauen. Eine erfuellte Quest
-- fuehrte zur Abgabe ans andere Ende des Gebiets, waehrend drei offene
-- Ziele nebenan lagen.
-- Jetzt plant der Pfeil selbst, laufend: jede Quest im Questlog ist ein
-- Ziel - offene an ihrem Zielgebiet, erfuellte an ihrer Abgabe. Gewaehlt
-- wird das mit den geringsten Kosten:
--   Kosten = Luftlinie x Gewicht
--   Gewicht 4 fuer "rote" Quests (5+ Stufen ueber dir), 1,5 fuer orange
--   (3-4 Stufen), x3 fuer Gruppenquests. Alles andere 1.
-- Weil Abgaben und Ziele gleich zaehlen, sammelt das von selbst: erst was
-- nah ist, die Abgabe, wenn man in ihrer Naehe ist.
-- Nicht hin und her: ein neues Ziel loest das alte nur ab, wenn es
-- deutlich guenstiger ist (QA.KEEP_SHARE und QA.KEEP_MIN).
-- Wer selbst eine Quest anklickt, bekommt sie (QA.manual) bis zur Abgabe.
-- Das Spiel meldet eine eigene Wahl genauso wie seine - unterschieden
-- wird an der Zeit: kurz nach Annehmen, Abgeben oder Laden (QA.AUTO_WINDOW)
-- war es das Spiel.
-- Grenze: die Luftlinie. Wege um Berge oder Wasser kennt ein Addon nicht.
QA.KEEP_SHARE, QA.KEEP_MIN = 0.7, 40
QA.PLAN_EVERY, QA.AUTO_WINDOW = 5, 2
QA.skipped = {}          -- [questID] = bis wann ("/wcui pfeil weiter")
QA.plan = { list = {} }  -- letzter Lauf, fuer /wcui pfeil

function QA.Smart() return K.Get(KEY, "plan") ~= "tracked" end

function QA.Weight(level, playerLevel, group)
    local w = 1
    if type(level) == "number" and level > 0 and type(playerLevel) == "number" then
        local diff = level - playerLevel
        if diff >= 5 then w = 4 elseif diff >= 3 then w = 1.5 end
    end
    if type(group) == "number" and group > 1 then w = w * 3 end
    return w
end

-- Was der Planer je Quest braucht, haengt nicht an der eigenen Position:
-- Ort, Stufe, Gruppe, erfuellt. Es wird nur nach einem Ereignis des
-- Questlogs (QA.PlanDirty) und beim Kartenwechsel neu gelesen; der Lauf
-- alle QA.PLAN_EVERY s rechnet nur Entfernungen (6.14.0.2 - vorher je
-- Lauf GetInfo, GetQuestsOnMap und ein Vektor je Quest).
local planCache = { dirty = true, n = 0 }
QA._planCache = planCache
function QA.PlanDirty() planCache.dirty = true end

local function FillPlanCache(playerMap)
    local ql = _G.C_QuestLog
    local onMap = {}
    local n = 0
    for i = 1, (ql.GetNumQuestLogEntries() or 0) do
        local info = ql.GetInfo(i)
        local id = info and info.questID
        if id and id ~= 0 and not info.isHeader and not info.isHidden then
            local mapID, x, y = QuestLocation(id, playerMap, onMap, true)
            local tc, tN, tW
            if mapID then tc, tN, tW = ToWorld(mapID, x, y) end
            if tc then
                n = n + 1
                local e = planCache[n] or {}
                planCache[n] = e
                e.id, e.tc, e.tN, e.tW, e.map = id, tc, tN, tW, mapID
                e.level, e.group, e.done = info.difficultyLevel or info.level, info.suggestedGroup, IsComplete(id)
            end
        end
    end
    for i = n + 1, planCache.n do planCache[i] = nil end
    planCache.n, planCache.map, planCache.dirty = n, playerMap, false
end

local function ByCost(a, b) return a.cost < b.cost end

-- Das Ziel mit den geringsten Kosten; current bleibt, solange nichts
-- deutlich Guenstigeres da ist. Liefert questID (oder nil) und schreibt
-- die Kandidaten nach QA.plan.list (fuer /wcui pfeil).
function QA.Plan(current)
    local list = QA.plan.list
    local k = 0
    local ql = _G.C_QuestLog
    local playerMap = (ql and ql.GetNumQuestLogEntries and ql.GetInfo) and BestMap() or nil
    local pc, pN, pW
    if playerMap then pc, pN, pW = PlayerWorld() end
    if not pc then
        for i = #list, 1, -1 do list[i] = nil end
        return nil
    end
    if planCache.dirty or planCache.map ~= playerMap then FillPlanCache(playerMap) end
    local now = _G.GetTime and K.Plain(_G.GetTime()) or 0
    local plevel = _G.UnitLevel and K.Plain(_G.UnitLevel("player"))
    local best, bestCost, curCost
    -- Abgaben sammeln (1.0.5.63): liegt auf der Karte des Spielers noch
    -- eine offene, machbare Quest (nicht rot, keine Gruppenquest, nicht
    -- ausgelassen), sind erfuellte Quests kein Ziel. Unmachbares haelt die
    -- Abgaben so nie fest.
    local hold = false
    if K.Get(KEY, "collect") then
        for i = 1, planCache.n do
            local e = planCache[i]
            local until_ = QA.skipped[e.id]
            if e.tc == pc and not e.done and e.map == playerMap and not (until_ and until_ > now)
               and QA.Weight(e.level, plevel, e.group) < 3 then hold = true break end
        end
    end
    QA.plan.hold = hold
    for i = 1, planCache.n do
        local e = planCache[i]
        local until_ = QA.skipped[e.id]
        if e.tc == pc and not (until_ and until_ > now) and not (hold and e.done) then
            local d = QA.Solve(pN, pW, e.tN, e.tW, nil)
            local w = QA.Weight(e.level, plevel, e.group)
            local cost = d * w
            k = k + 1
            local c = list[k] or {}
            list[k] = c
            c.id, c.dist, c.weight, c.cost, c.done = e.id, d, w, cost, e.done
            if e.id == current then curCost = cost end
            if not bestCost or cost < bestCost then best, bestCost = e.id, cost end
        end
    end
    for i = #list, k + 1, -1 do list[i] = nil end
    table.sort(list, ByCost)
    QA.plan.at = now
    if curCost and best ~= current
       and not (bestCost < curCost * QA.KEEP_SHARE and curCost - bestCost > QA.KEEP_MIN) then
        return current
    end
    return best
end

-- Neu planen, wenn niemand selbst gewaehlt hat.
function QA.Replan()
    if not QA.Smart() or QA.manual then return end
    QA.Chosen = QA.Plan(QA.Chosen)
end

-- "/wcui pfeil weiter": das jetzige Ziel 10 Minuten auslassen.
--------------------------------------------------
-- Wegpunkt des Spiels fuer eigene Ziele (6.73.0.0)
--------------------------------------------------
-- Wunsch: "den Pin von der Karte auch auf dem Bildschirm sehen, wenn ich in
-- der Naehe bin - wie das Ping-System". Ein Addon kann nichts in die Welt
-- zeichnen und keinen Kartenpunkt auf den Bildschirm umrechnen. Das Spiel
-- kann es: setzt man seinen Kartenwegpunkt (C_Map.SetUserWaypoint) und
-- verfolgt ihn (C_SuperTrack), legt die Navigation einen Bildschirmpunkt
-- genau ans Ziel (C_Navigation.GetFrame) - daran haengt die Zielmarke im
-- Raum (PlaceMarker). Verhalten wie NaowhForever, eigener Code.
-- 6.5.1.0 stand hier noch "setzt laut Beta-Berichten nicht verlaesslich" -
-- darum: nur, wenn der Client die Karte annimmt, und wieder weg, sobald das
-- eigene Ziel geloest ist. Ein Wegpunkt, den der Spieler vorher selbst
-- hatte, kommt danach zurueck. Die verfolgte Quest stellen wir NICHT
-- zurueck: SetSuperTrackedQuestID ist seit 6.6.0.1 verboten (gemessen:
-- danach blockiert das Spiel im Kampf SetPassThroughButtons). Auch den
-- Wegpunkt nie im Kampf - dieselbe Sorte Schreiben, nur ungemessen.
QA.pin = nil       -- { map, x, y, before = UiMapPoint|nil }
QA.pinAt = -math.huge

local function Now() return _G.GetTime and K.Plain(_G.GetTime()) or 0 end

local function MapPoint(map, x, y)
    local P = _G.UiMapPoint
    if type(P) ~= "table" then return nil end
    if P.CreateFromCoordinates then return P.CreateFromCoordinates(map, x, y) end
    if P.CreateFromVector2D and _G.CreateVector2D then return P.CreateFromVector2D(map, _G.CreateVector2D(x, y)) end
    return nil
end

-- 1.0.1.9 (Fehlerbericht: "Verboten: CopyToClipboard()" aus
-- WaypointLocationDataProvider): setzt WeintCodex den Wegpunkt, waehrend
-- die Weltkarte offen ist, baut das Spiel seine Wegpunkt-Marke auf der
-- Karte in unserem Aufruf neu - danach ist jeder Klick darauf verunreinigt
-- und "In die Zwischenablage" verboten. Bei offener Karte deshalb erst nach
-- dem Schliessen; beim naechsten Oeffnen baut das Spiel die Marke selbst.
local function MapOpen()
    local w = _G.WorldMapFrame
    return type(w) == "table" and w.IsShown and K.Bool(w:IsShown(), false) or false
end
QA.MapOpen = MapOpen
local mapHooked = false
local function AfterMap(fn)
    QA.afterMap = fn
    if mapHooked then return end
    local w = _G.WorldMapFrame
    if type(w) ~= "table" or not w.HookScript then return end
    mapHooked = true
    w:HookScript("OnHide", function()
        local f = QA.afterMap
        QA.afterMap = nil
        if f and _G.C_Timer and _G.C_Timer.After then _G.C_Timer.After(0, f) elseif f then f() end
    end)
end

-- Den Wegpunkt des Spiels aufs eigene Ziel setzen. true, wenn gesetzt.
function QA.PinGame(t)
    if MapOpen() then
        QA.pinState = "wartet, bis die Karte zu ist"
        AfterMap(function() QA.PinGame(t) end)
        return false
    end
    local cm, st = _G.C_Map, _G.C_SuperTrack
    if not (t and type(t.map) == "number" and type(t.x) == "number" and type(t.y) == "number") then return false end
    if not (K.Get(KEY, "worldMarker") and cm and cm.SetUserWaypoint and st and st.SetSuperTrackedUserWaypoint) then return false end
    if cm.CanSetUserWaypointOnMap then
        local ok, can = pcall(cm.CanSetUserWaypointOnMap, t.map)
        if not ok or not K.Bool(can, false) then QA.pinState = "Karte nimmt keinen Wegpunkt" return false end
    end
    if _G.InCombatLockdown and K.Bool(_G.InCombatLockdown(), false) then QA.pinState = "im Kampf nicht gesetzt" return false end
    local point = MapPoint(t.map, t.x, t.y)
    if not point then QA.pinState = "UiMapPoint fehlt" return false end
    local pin = QA.pin
    if not pin then
        pin = {}
        local okB, before = pcall(cm.GetUserWaypoint or function() end)
        pin.before = okB and before or nil
    end
    QA.pinAt = Now()
    if not pcall(cm.SetUserWaypoint, point) then QA.pinState = "SetUserWaypoint abgelehnt" return false end
    pcall(st.SetSuperTrackedUserWaypoint, true)
    pin.map, pin.x, pin.y = t.map, t.x, t.y
    QA.pin, QA.pinState = pin, "gesetzt"
    return true
end

-- Ist der Wegpunkt des Spiels noch unserer, und wird er verfolgt?
function QA.PinIsOurs()
    local pin, cm, st = QA.pin, _G.C_Map, _G.C_SuperTrack
    if not (pin and cm and cm.GetUserWaypoint) then return false end
    local ok, wp = pcall(cm.GetUserWaypoint)
    if not ok or type(wp) ~= "table" or not wp.position then return false end
    local x, y = wp.position.x, wp.position.y
    if wp.position.GetXY then x, y = wp.position:GetXY() end
    x, y = K.Plain(x), K.Plain(y)
    if K.Plain(wp.uiMapID) ~= pin.map or type(x) ~= "number" or type(y) ~= "number"
       or math.abs(x - pin.x) > 0.0005 or math.abs(y - pin.y) > 0.0005 then return false end
    if st and st.IsSuperTrackingUserWaypoint then
        local okS, on = pcall(st.IsSuperTrackingUserWaypoint)
        return okS and K.Bool(on, false)
    end
    return true
end

-- Unseren Wegpunkt wieder abnehmen; was vorher war, zurueck. Ein Wegpunkt,
-- den der Spieler inzwischen selbst gesetzt hat, bleibt stehen.
function QA.UnpinGame()
    local pin = QA.pin
    if not pin then return false end
    if MapOpen() then
        AfterMap(function() QA.UnpinGame() end)
        return false
    end
    -- 1.0.4.4 (Fehlerbericht "Blockiert: SetPassThroughButtons" aus
    -- CacheCurrentSuperTrackInfo, 32x): ein Wegpunkt-Wechsel aus dem Addon
    -- loest den Neuaufbau der Kartennadeln aus - im Kampf als Addon-Code,
    -- und das Spiel sperrt jede Nadel. Im Kampf erst danach.
    if K.InCombat() then
        K.AfterCombat(function() QA.UnpinGame() end)
        return false
    end
    local ours = QA.PinIsOurs()
    QA.pin = nil
    if not ours then return false end
    local cm, st = _G.C_Map, _G.C_SuperTrack
    QA.pinAt = Now()
    if pin.before and cm.SetUserWaypoint then
        pcall(cm.SetUserWaypoint, pin.before)
    elseif cm.ClearUserWaypoint then
        pcall(cm.ClearUserWaypoint)
    end
    if st and not pin.before and st.SetSuperTrackedUserWaypoint then
        pcall(st.SetSuperTrackedUserWaypoint, false)
    end
    return true
end

-- Hat gerade WeintCodex selbst die Verfolgung geaendert? Dann ist das
-- SUPER_TRACKING_CHANGED keine Wahl des Spielers.
function QA.PinBusy() return Now() - QA.pinAt < 1.5 end

function QA.ClearCustom()
    QA.custom = nil
    QA.UnpinGame()
end

function QA.SetCustom(t)
    QA.custom = t
    if t then QA.PinGame(t) else QA.UnpinGame() end
    if QA.Update then pcall(QA.Update, true) end
end

function QA.Skip()
    if QA.custom then QA.ClearCustom() return end
    local now = _G.GetTime and K.Plain(_G.GetTime()) or 0
    local id = QA.manual or QA.Chosen
    if id then QA.skipped[id] = now + 600 end
    QA.manual, QA.Chosen = nil, nil
    QA.Replan()
    return id
end

-- "/wcui pfeil planen": die eigene Wahl aufgeben, wieder planen.
function QA.Resume()
    QA.manual, QA.Chosen = nil, nil
    QA.Replan()
end

--------------------------------------------------
-- Anzeige
--------------------------------------------------

local frame, arrow, title, dist, eta, height

-- Text nur setzen, wenn er sich aendert (wie RestedXP): ein Feld am
-- Textobjekt merkt den letzten Wert - keine Tabelle, kein Neuzeichnen.
local function SetTxt(fs, s)
    s = s or ""
    if fs._wcT ~= s then fs._wcT = s fs:SetText(s) end
end
QA.SetTxt = SetTxt

-- Totband des Pfeils: unter ~3 Grad Drehung bleibt die Textur stehen.
QA.TURN_EPS = math.pi / 60
function QA.AngleMoved(last, new, eps)
    if type(last) ~= "number" then return true end
    if type(new) ~= "number" then return false end
    return math.abs(Norm(new - last)) >= (eps or QA.TURN_EPS)
end

local function Is3D() return K.Get(KEY, "style") ~= "flat" end

-- Den Pfeil auf einen Winkel stellen: im 3D-Stil die passende Ansicht,
-- flach die gedrehte Pfeilform.
-- 1.0.5.64 (Wunsch: "den Pfeil dreidimensional kippen, um zu sehen, ob man
-- nach oben oder unten muss"): zwei weitere Bildtafeln desselben Pfeils,
-- Spitze angehoben (arrow3d_up) und gesenkt (arrow3d_down), je 64
-- Drehungen. QA.pitch ("up"/"down"/nil) waehlt die Tafel; gesetzt von
-- QA.SetClimb. Die Textur wechselt nur, wenn sich die Neigung aendert.
QA.SHEETS = { up = SHEET .. "_up", down = SHEET .. "_down" }
function QA.SheetFor(pitch) return QA.SHEETS[pitch or ""] or SHEET end
local function PointArrow(rotation)
    if Is3D() then
        local _, l, r, t, b = QA.Frame(rotation)
        local sheet = QA.SheetFor(QA.pitch)
        if QA.sheetShown ~= sheet then
            arrow:SetTexture(sheet)
            QA.sheetShown = sheet
        end
        arrow:SetRotation(0)
        arrow:SetTexCoord(l, r, t, b)
    else
        QA.sheetShown = nil
        arrow:SetTexCoord(0, 1, 0, 1)
        arrow:SetRotation(rotation)
    end
end


--------------------------------------------------
-- Navigation des Spiels: Hoehe und Zielmarke
--------------------------------------------------

-- { frame, dist (Luftlinie, Yards), occluded, onScreen } oder nil.
-- Eine Tabelle fuer alle Laeufe (6.14.0.2), nicht fuenf je Sekunde.
local navOut = {}
function QA.Nav()
    local cn = _G.C_Navigation
    if not (cn and cn.GetDistance) then return nil end
    local out = navOut
    local ok, d = pcall(cn.GetDistance)
    d = ok and K.Plain(d) or nil
    if type(d) ~= "number" or d <= 0 then return nil end
    out.dist, out.occluded, out.frame, out.inRange = d, nil, nil, nil
    if cn.GetTargetState then
        local okS, st = pcall(cn.GetTargetState)
        st = okS and K.Plain(st) or nil
        local E = _G.Enum and _G.Enum.NavigationState
        local occ = (E and E.Occluded) or 1
        out.occluded = (st == occ)
        -- 6.75.1.0 (Beta-Test mit Bild: "ich bin im Questgebiet, die Nadel ist
        -- immer noch da"): steht man im Zielgebiet einer Quest, meldet die
        -- Navigation des Spiels "InRange" - dann ist die Nadel ueberfluessig.
        local inr = (E and E.InRange) or 2
        out.inRange = (st == inr)
    end
    if cn.GetFrame then
        local okF, f = pcall(cn.GetFrame)
        if okF and type(f) == "table" then out.frame = f end
    end
    local valid = cn.HasValidScreenPosition and select(2, pcall(cn.HasValidScreenPosition))
    local clamped = cn.WasClampedToScreen and select(2, pcall(cn.WasClampedToScreen))
    out.onScreen = K.Bool(valid, false) and not K.Bool(clamped, false)
    return out
end

-- Hoehenunterschied aus Luftlinie und Abstand auf der Karte (beide Yards).
-- nil, wenn die Luftlinie kuerzer ist (Kartenort und Navigationspunkt
-- liegen nicht genau aufeinander) - dann ist nichts zu sagen.
-- 1.0.5.65 (Bild vom Spieler: "Hoehenunterschied ≈ 371 m" bei 12 m zum
-- Ziel): die Luftlinie des Spiels gilt SEINEM Navigationspunkt, der Abstand
-- auf der Karte UNSEREM Questort - liegen die beiden auseinander (das Spiel
-- fuehrt zu einem anderen Fundort oder zum Gebietsausgang), ist die
-- Differenz kein Hoehenunterschied. Glaubhaft ist nur, was nicht steiler
-- ist als QA.HEIGHT_SLOPE (Hoehe je Abstand, mindestens QA.HEIGHT_FREE
-- frei fuer Hoehle oder Turm direkt am Ziel) und unter QA.HEIGHT_MAX.
QA.HEIGHT_SLOPE, QA.HEIGHT_FREE, QA.HEIGHT_MAX = 1.5, 60, 150
function QA.Height(dist3d, flat)
    if type(dist3d) ~= "number" or type(flat) ~= "number" or dist3d <= flat then return nil end
    local dh = math.sqrt(dist3d * dist3d - flat * flat)
    if dh > QA.HEIGHT_MAX or dh > math.max(QA.HEIGHT_FREE, flat * QA.HEIGHT_SLOPE) then return nil end
    return dh
end

-- Die eigene Hoehe, wenn der Client sie nennt (nil sonst). UnitPosition
-- liefert y, x, z; ein z von genau 0 ist im normalen Spiel "nicht
-- gefuehrt" - zaehlt deshalb erst, wenn es sich einmal von 0 bewegt hat.
local zSeen = false
function QA.PlayerZ()
    if not _G.UnitPosition then return nil end
    local ok, _, _, z = pcall(_G.UnitPosition, "player")
    z = ok and K.Plain(z) or nil
    if type(z) ~= "number" then return nil end
    if z ~= 0 then zSeen = true end
    return zSeen and z or nil
end
QA._ResetZ = function() zSeen = false end

-- Hoeher oder tiefer? Liegt das Ziel auf Hoehe H, ist der Unterschied
-- |H - z|. Steigt z um dz und der Unterschied faellt um ungefaehr dz,
-- liegt das Ziel hoeher ("up"); steigt er um ungefaehr dz, tiefer
-- ("down"). Erst ab 3 Einheiten Hoehenaenderung, und nur wenn das
-- Verhaeltnis passt (Kartenort und Navigationspunkt rauschen).
local anchor, sign
function QA.TrackHeight(z, dh)
    if type(z) ~= "number" or type(dh) ~= "number" then return sign end
    if not anchor then anchor = { z = z, dh = dh } return sign end
    local dz = z - anchor.z
    if math.abs(dz) < 3 then return sign end
    local r = (anchor.dh - dh) / dz
    if r > 0.5 and r < 1.5 then sign = "up"
    elseif r < -0.5 and r > -1.5 then sign = "down" end
    anchor = { z = z, dh = dh }
    return sign
end
function QA.ResetHeight() anchor, sign = nil, nil end

-- Hoeher oder tiefer aus der Gelaendekarte (1.0.5.63, Wunsch: "Hoehen-
-- unterschiede wie bei Shortest Path Forever"). Der Client nennt die eigene
-- Hoehe nicht - aber die Gelaendekarte kennt zu jeder Zelle die Hoehe ihrer
-- begehbaren Flaechen (ui/navmesh.lua, NV.HeightsAt). Daraus, rein:
--   * liegt jede Flaeche am Ziel ueber jeder am eigenen Ort: "up" und um
--     wie viel mindestens; unter jeder: "down";
--   * ueberschneiden sie sich und liegen an einem der beiden Orte Ebenen
--     weit uebereinander (QA.TERRAIN_MIN): "stacked" - Ebene unklar;
--   * sonst nichts (gleiche Hoehe).
-- Unter QA.TERRAIN_MIN kein Wort: das Raster ist grob (Zellen von 8 m).
QA.TERRAIN_MIN, QA.TERRAIN_RANGE = 8, 600
-- was: die Richtung vom letzten Mal - sie bleibt bis QA.TERRAIN_KEEP
-- (kein Kippen des Pfeils im Sekundentakt an der Schwelle).
QA.TERRAIN_KEEP = 5
function QA.TerrainHeight(pLo, pHi, gLo, gHi, was)
    if type(pLo) ~= "number" or type(gLo) ~= "number" then return nil end
    pHi, gHi = pHi or pLo, gHi or gLo
    if gLo - pHi >= (was == "up" and QA.TERRAIN_KEEP or QA.TERRAIN_MIN) then return "up", gLo - pHi end
    if pLo - gHi >= (was == "down" and QA.TERRAIN_KEEP or QA.TERRAIN_MIN) then return "down", pLo - gHi end
    if gHi - gLo >= QA.TERRAIN_MIN or pHi - pLo >= QA.TERRAIN_MIN then return "stacked", 0 end
    return nil
end
-- Einmal je Sekunde und nur bei neuem Ort gelesen.
local terr = { at = -1e9 }
QA.terr = terr
function QA.TerrainLine(c, pN, pW, gN, gW, units)
    local NV = WeintCodex.UINav
    if not (NV and NV.HeightsAt and NV.Available and NV.Available(c)) then return nil end
    local now = Now()
    if now - terr.at >= 1 or terr.c ~= c or terr.gN ~= gN or terr.gW ~= gW then
        terr.at, terr.c, terr.gN, terr.gW = now, c, gN, gW
        local ok, pLo, pHi = pcall(NV.HeightsAt, c, pN, pW)
        local ok2, gLo, gHi = pcall(NV.HeightsAt, c, gN, gW)
        local was = terr.dir
        terr.dir, terr.dh = nil, nil
        if ok and ok2 then terr.dir, terr.dh = QA.TerrainHeight(pLo, pHi, gLo, gHi, was) end
        -- Beide Hoehen bekannt: die Gelaendekarte hat das Wort - auch wenn
        -- es "kein nennenswerter Unterschied" heisst.
        terr.known = ok and ok2 and type(pLo) == "number" and type(gLo) == "number" or false
    end
    if terr.dir == "up" or terr.dir == "down" then
        return "Ziel ≈ " .. QA.FormatDistance(terr.dh, units) .. (terr.dir == "up" and " höher" or " tiefer"), terr.dir
    elseif terr.dir == "stacked" then
        return "Ebenen übereinander – Höhle, Keller oder Obergeschoss?", nil
    end
    return nil, nil, terr.known
end

local marker
-- 6.74.0.0 (Wunsch: "erst in der Naehe, groesser, schoener - wie das
-- Ping-System"): eine Plakette mit Raute auf runder Scheibe, darunter ein
-- Lichtstrahl bis zum Boden, am Boden ein Schein - die Form des Pings, in
-- der Farbe des Akzents. Erst ab QA.MARK_NEAR sichtbar, davor blendet sie
-- ueber QA.MARK_FADE weich ein und waechst beim Naeherkommen etwas.
QA.MARK_BADGE, QA.MARK_BEAM = 44, 96
QA.MARK_FADE = 25
QA.AREA = 45           -- so nah an einem Fundort der Questziele gilt man als "drin" (Yards)
QA.areaMemo = { at = -1e9, quest = nil, map = nil, inside = false, spots = 0, nearN = nil, nearW = nil, nearD = nil }

-- Ein Schritt der Suche (rein, fuer den Ladetest): Punkt n, w gegen den
-- Spieler in s - drin? naeher als der bisher naechste?
function QA.SpotStep(s, n, w)
    local d2 = (n - s.pN) ^ 2 + (w - s.pW) ^ 2
    if d2 <= s.r2 then s.inside = true end
    if not s.bestD2 or d2 < s.bestD2 then s.bestD2, s.bN, s.bW = d2, n, w end
end
-- Zustand der Suche auf Dateiebene, damit kein Abschluss je Lauf entsteht.
local scan = { map = nil, pc = nil, pN = 0, pW = 0, r2 = 0, inside = false }
local function ScanSpot(x, y)
    if type(x) ~= "number" or type(y) ~= "number" then return end
    local c, n, w = ToWorld(scan.map, x, y)
    if c == scan.pc and n then QA.SpotStep(scan, n, w) end
end

-- Steht der Spieler nahe an einem Fundort der Ziele von questID? Einmal je
-- Sekunde gerechnet; die Fundorte liest die Questhilfe (ui/questhelper.lua).
-- Nebenbei: der naechste Fundort (QA.NearestSpot).
function QA.InArea(questID, playerMap)
    local QH = WeintCodex.UIQuestHelper
    local m = QA.areaMemo
    if not (QH and QH.TargetSpots and type(questID) == "number" and type(playerMap) == "number") then return false end
    local now = Now()
    if m.quest == questID and m.map == playerMap and now - m.at < 1 then return m.inside end
    m.at, m.quest, m.map, m.inside, m.spots = now, questID, playerMap, false, 0
    m.nearN, m.nearW, m.nearD = nil, nil, nil
    -- Eigene Lage ueber K.PlayerWorld (ohne Wegwerf-Vektoren je Abfrage).
    local pc, pN, pW = PlayerWorld()
    if not pc then return false end
    scan.map, scan.pc, scan.pN, scan.pW, scan.r2 = playerMap, pc, pN, pW, QA.AREA * QA.AREA
    scan.inside, scan.bestD2, scan.bN, scan.bW = false, nil, nil, nil
    m.spots = QH.TargetSpots(questID, playerMap, ScanSpot)
    m.inside = scan.inside
    if scan.bestD2 then m.nearN, m.nearW, m.nearD = scan.bN, scan.bW, math.sqrt(scan.bestD2) end
    return m.inside
end

-- Mehrere Fundorte: der naechste statt der Mitte des Gebiets (RestedXP-
-- Verhalten), erst ab QA.SPOT_NEAR an das Gebiet heran. Weltlage oder nil.
QA.SPOT_NEAR = 300
function QA.NearestSpot(questID, playerMap)
    QA.InArea(questID, playerMap)
    local m = QA.areaMemo
    if m.quest ~= questID or (m.spots or 0) < 2 then return nil end
    return m.nearN, m.nearW, m.nearD
end

-- Wechsel zum naechsten Abschnitt mit Hysterese: vorwaerts erst im Radius
-- der neuen Ecke, zurueck erst mit Abstand; nie haengen - ist der andere
-- Abschnitt laenger als QA.HOP_STUCK naeher, geht es trotzdem weiter.
QA.HOP_ENTER, QA.HOP_LEAVE, QA.HOP_STUCK = 8, 14, 2
function QA.HopSwitch(ahead, dEnter, dHeld, worseFor)
    if ahead and type(dEnter) == "number" and dEnter <= QA.HOP_ENTER then return true end
    if not ahead and type(dHeld) == "number" and dHeld >= QA.HOP_LEAVE then return true end
    return type(worseFor) == "number" and worseFor >= QA.HOP_STUCK
end
-- Drin bleiben mit Hysterese: hinein ab enter, hinaus erst ueber leave.
function QA.Within(was, d, enter, leave)
    if type(d) ~= "number" then return false end
    if was then return d <= leave end
    return d <= enter
end
local function SegD(aN, aW, bN, bW, pN, pW)
    local dN, dW = bN - aN, bW - aW
    local l2 = dN * dN + dW * dW
    local u = l2 > 0 and ((pN - aN) * dN + (pW - aW) * dW) / l2 or 0
    if u < 0 then u = 0 elseif u > 1 then u = 1 end
    return math.sqrt((aN + dN * u - pN) ^ 2 + (aW + dW * u - pW) ^ 2)
end
local hold = { path = nil, i = nil, since = nil, state = nil }
QA.hold = hold
-- Haelt den Abschnitt des Laufwegs, dem der Pfeil folgt (path flach:
-- n1, w1, n2, w2, ...; i = Anfang des Abschnitts wie NV.Steer).
-- ZIEL ZUERST (6.103.5.0, Beta-Test: "Der Pfeil ist nur am Zittern, sehr
-- viele Korrekturen auf langer Strecke. Lieber erstmal das Ziel, und wenn
-- man wirklich vom Kurs abweicht, korrigiert er sich"): der Laufweg aus
-- dem Raster hat viele kleine Knicke, und der Punkt voraus wanderte mit
-- jedem Schritt. Jetzt zeigt der Pfeil auf das ZIEL, solange der Weg
-- ungefaehr der Luftlinie folgt: kein Punkt des restlichen Wegs weiter als
-- QA.COURSE_MIN (oder QA.COURSE_RATIO der Entfernung) neben der Linie,
-- und der Weg hoechstens QA.COURSE_LONG mal so lang. Sonst (Berg, Wasser,
-- Mauer dazwischen) folgt er dem Weg. Hysterese: zurueck zum Ziel erst
-- unter QA.COURSE_BACK der Schwelle - kein Hin und Her an der Grenze.
-- Entfernung und Minikarte bleiben beim Laufweg.
QA.COURSE_MIN, QA.COURSE_RATIO, QA.COURSE_LONG, QA.COURSE_BACK = 35, 0.15, 1.3, 0.6
QA.COURSE_LONG_BACK = 1.15
QA.course = { follow = false }
function QA.OnCourse(path, segI, pN, pW, gN, gW, rest)
    local st = QA.course
    if type(path) ~= "table" or #path < 4 then st.follow = false return true end
    local dN, dW = gN - pN, gW - pW
    local len = math.sqrt(dN * dN + dW * dW)
    if len < 1 then st.follow = false return true end
    local limit = math.max(QA.COURSE_MIN, len * QA.COURSE_RATIO)
    if st.follow then limit = limit * QA.COURSE_BACK end
    local worst = 0
    for i = (type(segI) == "number" and segI or 1), #path - 1, 2 do
        -- Abstand des Wegpunkts von der Linie Spieler-Ziel (senkrecht).
        local d = math.abs((path[i] - pN) * dW - (path[i + 1] - pW) * dN) / len
        if d > worst then worst = d end
    end
    local tooLong = type(rest) == "number" and rest > len * (st.follow and QA.COURSE_LONG_BACK or QA.COURSE_LONG)
    st.follow = worst > limit or tooLong or false
    st.worst = worst
    return not st.follow
end

--------------------------------------------------
-- Dem Weg folgen (1.0.5.63)
--------------------------------------------------
-- Bericht: "Manchmal rastet der Pfeil ziemlich aus, wenn man 5 m neben der
-- Route laeuft." Bis hierher suchte jeder Durchlauf den naechsten Abschnitt
-- des ganzen Wegs neu und hielt bei einem Wechsel bis zu zwei Sekunden die
-- ECKE des alten Abschnitts fest (QA.HoldCorner). Lief man ein paar Meter
-- neben dem Weg an einer Ecke vorbei, zeigte der Pfeil so lange zurueck -
-- und der Weg aus dem Raster hat viele kleine Ecken.
-- Jetzt wie eine Fahrspur-Fuehrung:
--   * FORTSCHRITT statt naechster Abschnitt: wie weit man auf dem Weg ist
--     (Bogenlaenge), gesucht nur in einem Fenster um den letzten Stand
--     (QA.FOLLOW_BACK zurueck, QA.FOLLOW_AHEAD voraus). Der Pfeil springt
--     nie auf einen fernen Abschnitt, der zufaellig naeher liegt
--     (Serpentinen), und nie zurueck auf eine Ecke, die man passiert hat.
--     Nur wer wirklich weg ist (QA.FOLLOW_LOST), wird im ganzen Weg gesucht.
--   * VORAUS mit Abstand: der Zielpunkt liegt NV.LOOKAHEAD voraus, und je
--     weiter man neben dem Weg laeuft, desto weiter (QA.FOLLOW_GAIN je
--     Einheit daneben, hoechstens QA.FOLLOW_MAX) - der Pfeil fuehrt flach
--     zurueck auf den Weg statt quer.
--   * ECKEN: liegt eine Ecke weiter neben der Sichtlinie zum Zielpunkt als
--     NV.CUT plus der eigene Abstand zum Weg, ist dort etwas im Weg - dann
--     zeigt der Pfeil auf die Ecke. Ist die Ecke aber schon nah (naeher als
--     QA.FOLLOW_NEAR oder das Anderthalbfache des eigenen Abstands), gilt
--     sie als erreicht, und es geht den naechsten Abschnitt entlang.
-- Rueckgabe: Zielpunkt (N, W), Rest des Wegs, Anfang des Abschnitts,
-- Abstand zum Weg. Legt nur beim Wechsel des Wegs eine Tabelle neu an.
QA.FOLLOW_BACK, QA.FOLLOW_AHEAD, QA.FOLLOW_LOST = 15, 80, 30
QA.FOLLOW_GAIN, QA.FOLLOW_MAX, QA.FOLLOW_NEAR = 2, 90, 8
local follow = { path = nil, n = 0, s = 0, cum = {} }
QA.follow = follow
local function ProjectOn(path, i, pN, pW)
    local aN, aW, bN, bW = path[i], path[i + 1], path[i + 2], path[i + 3]
    local dN, dW = bN - aN, bW - aW
    local l2 = dN * dN + dW * dW
    local u = l2 > 0 and ((pN - aN) * dN + (pW - aW) * dW) / l2 or 0
    if u < 0 then u = 0 elseif u > 1 then u = 1 end
    local qN, qW = aN + dN * u - pN, aW + dW * u - pW
    return math.sqrt(qN * qN + qW * qW), u
end
-- Punkt auf dem Weg bei Bogenlaenge a (ab Abschnitt i gesucht).
local function PointAt(path, cum, a, i)
    local last = #path - 3
    while i < last and cum[(i + 1) / 2 + 1] < a do i = i + 2 end
    local k = (i + 1) / 2
    local l = cum[k + 1] - cum[k]
    local t = l > 0 and (a - cum[k]) / l or 0
    if t < 0 then t = 0 elseif t > 1 then t = 1 end
    return path[i] + (path[i + 2] - path[i]) * t, path[i + 1] + (path[i + 3] - path[i + 1]) * t, i
end
-- Naechster Abschnitt; mit lo/hi nur die im Fenster der Bogenlaenge.
local function FollowScan(path, n, pN, pW, lo, hi)
    local cum = follow.cum
    local bestD, bestI, bestU
    for i = 1, n - 3, 2 do
        local k = (i + 1) / 2
        if not lo or (cum[k + 1] >= lo and cum[k] <= hi) then
            local d, u = ProjectOn(path, i, pN, pW)
            if not bestD or d < bestD then bestD, bestI, bestU = d, i, u end
        end
    end
    return bestD, bestI, bestU
end
function QA.Follow(path, pN, pW)
    local n = #path
    if n < 4 then return path[1], path[2], 0, 1, 0 end
    local cum = follow.cum
    local fresh = follow.path ~= path or follow.n ~= n
    if fresh then
        cum[1] = 0
        local k = 1
        for i = 1, n - 3, 2 do
            k = k + 1
            cum[k] = cum[k - 1] + math.sqrt((path[i + 2] - path[i]) ^ 2 + (path[i + 3] - path[i + 1]) ^ 2)
        end
        for j = #cum, k + 1, -1 do cum[j] = nil end
        follow.path, follow.n, follow.s = path, n, 0
    end
    local total = cum[(n - 2) / 2 + 1]
    -- Fortschritt: im Fenster, sonst (neu oder verloren) im ganzen Weg.
    local bestD, bestI, bestU = FollowScan(path, n, pN, pW,
        (not fresh) and (follow.s - QA.FOLLOW_BACK) or nil, follow.s + QA.FOLLOW_AHEAD)
    if fresh or not bestD or bestD > QA.FOLLOW_LOST then bestD, bestI, bestU = FollowScan(path, n, pN, pW, nil, nil) end
    local kI = (bestI + 1) / 2
    local sNow = cum[kI] + (cum[kI + 1] - cum[kI]) * bestU
    follow.s, follow.off, follow.i = sNow, bestD, bestI
    local rest = total - sNow + bestD
    -- Voraus, weiter bei Abstand zum Weg.
    local look = (WeintCodex.UINav and WeintCodex.UINav.LOOKAHEAD or 30) + QA.FOLLOW_GAIN * bestD
    if look > QA.FOLLOW_MAX then look = QA.FOLLOW_MAX end
    local a = sNow + look
    if a > total then a = total end
    local tN, tW, endI = PointAt(path, cum, a, bestI)
    -- Ecken zwischen hier und dem Zielpunkt gegen die Sichtlinie pruefen.
    local tol = (WeintCodex.UINav and WeintCodex.UINav.CUT or 5) + bestD
    local near = math.max(QA.FOLLOW_NEAR, bestD * 1.5)
    local dN, dW = tN - pN, tW - pW
    local len = math.sqrt(dN * dN + dW * dW)
    if len > 0.01 then
        for j = bestI + 2, endI, 2 do
            local cN, cW = path[j], path[j + 1]
            local dev = math.abs((cN - pN) * dW - (cW - pW) * dN) / len
            if dev > tol then
                local dc = math.sqrt((cN - pN) ^ 2 + (cW - pW) ^ 2)
                if dc >= near then
                    follow.state = "Ecke"
                    return cN, cW, rest, bestI, bestD
                end
            end
        end
    end
    follow.state = "voraus"
    return tN, tW, rest, bestI, bestD
end

-- Weich drehen (1.0.5.63): die Richtung zum Zielpunkt aendert sich in
-- Spruengen (naechste Ecke, Wechsel zwischen Weg und Ziel). Der Pfeil
-- laeuft der neuen Richtung nach - Zeitkonstante QA.EASE_TAU - statt zu
-- springen. Nur die Richtung in der Welt wird geglaettet; drehst du dich
-- selbst, folgt der Pfeil sofort. Nach einer Pause (QA.EASE_GAP) oder
-- ohne Stand: sofort die neue Richtung.
QA.EASE_TAU, QA.EASE_GAP = 0.2, 1
local ease = { b = nil, at = nil }
QA.ease = ease
function QA.Ease(bearing, now)
    if type(bearing) ~= "number" then return bearing end
    if type(ease.b) ~= "number" or type(now) ~= "number" or type(ease.at) ~= "number"
       or now - ease.at > QA.EASE_GAP or now < ease.at then
        ease.b, ease.at = bearing, now
        return bearing
    end
    local dt = now - ease.at
    local k = 1 - math.exp(-dt / QA.EASE_TAU)
    ease.b = Norm(ease.b + Norm(bearing - ease.b) * k)
    ease.at = now
    return ease.b
end
function QA.EaseReset() ease.b, ease.at = nil, nil end

function QA.HoldCorner(path, i, pN, pW, sN, sW)
    if type(path) ~= "table" or type(i) ~= "number" then hold.path, hold.state = nil, nil return sN, sW end
    local h = hold.i
    if hold.path ~= path or type(h) ~= "number" or not path[h + 3] then
        hold.path, hold.i, hold.since, hold.state = path, i, nil, "folgt"
        return sN, sW
    end
    if i == h then hold.since, hold.state = nil, "folgt" return sN, sW end
    local now = Now()
    hold.since = hold.since or now
    local ahead = i > h
    local dEnter = math.sqrt((path[i] - pN) ^ 2 + (path[i + 1] - pW) ^ 2)
    local dHeld = SegD(path[h], path[h + 1], path[h + 2], path[h + 3], pN, pW)
    if QA.HopSwitch(ahead, dEnter, dHeld, now - hold.since) then
        hold.i, hold.since, hold.state = i, nil, "weiter"
        return sN, sW
    end
    hold.state = "hält"
    return path[h + 2], path[h + 3]
end
local function BuildMarker()
    local bs, beamH = QA.MARK_BADGE, QA.MARK_BEAM
    marker = CreateFrame("Frame", "WeintCodexQuestArrowMarker", UIParent)
    marker:SetSize(bs, bs + beamH)
    marker:SetFrameStrata("LOW")
    marker:EnableMouse(false)
    local a, d, bg = C.accentBright, C.accent or C.accentBright, C.bgPanel
    local M = K.MEDIA
    -- Schein am Boden
    local ground = marker:CreateTexture(nil, "BACKGROUND")
    ground:SetTexture(M .. "halo")
    ground:SetSize(bs * 1.3, bs * 0.45)
    ground:SetPoint("CENTER", marker, "BOTTOM", 0, 0)
    ground:SetVertexColor(a[1], a[2], a[3], 0.8)
    if ground.SetBlendMode then ground:SetBlendMode("ADD") end
    -- Strahl: weicher Schein und harter Kern
    local glowBeam = marker:CreateTexture(nil, "BORDER")
    glowBeam:SetColorTexture(a[1], a[2], a[3], 0.25)
    glowBeam:SetSize(6, beamH)
    glowBeam:SetPoint("BOTTOM", marker, "BOTTOM", 0, 0)
    local beam = marker:CreateTexture(nil, "ARTWORK")
    beam:SetColorTexture(a[1], a[2], a[3], 0.9)
    beam:SetSize(2, beamH)
    beam:SetPoint("BOTTOM", marker, "BOTTOM", 0, 0)
    if beam.SetGradient and _G.CreateColor then
        pcall(beam.SetGradient, beam, "VERTICAL", _G.CreateColor(a[1], a[2], a[3], 0.15), _G.CreateColor(a[1], a[2], a[3], 0.95))
        pcall(glowBeam.SetGradient, glowBeam, "VERTICAL", _G.CreateColor(a[1], a[2], a[3], 0), _G.CreateColor(a[1], a[2], a[3], 0.35))
    end
    -- Plakette oben
    local badge = CreateFrame("Frame", nil, marker)
    badge:SetSize(bs, bs)
    badge:SetPoint("TOP", marker, "TOP", 0, 0)
    local halo = badge:CreateTexture(nil, "BACKGROUND")
    halo:SetTexture(M .. "halo")
    halo:SetSize(bs * 1.7, bs * 1.7)
    halo:SetPoint("CENTER")
    halo:SetVertexColor(a[1], a[2], a[3], 0.55)
    if halo.SetBlendMode then halo:SetBlendMode("ADD") end
    local rim = badge:CreateTexture(nil, "ARTWORK", nil, 1)
    rim:SetTexture(M .. "disc")
    rim:SetAllPoints(badge)
    rim:SetVertexColor(a[1], a[2], a[3], 1)
    local face = badge:CreateTexture(nil, "ARTWORK", nil, 2)
    face:SetTexture(M .. "disc")
    face:SetPoint("TOPLEFT", badge, "TOPLEFT", 3, -3)
    face:SetPoint("BOTTOMRIGHT", badge, "BOTTOMRIGHT", -3, 3)
    face:SetVertexColor(bg[1], bg[2], bg[3], 0.95)
    local dia = badge:CreateTexture(nil, "ARTWORK", nil, 3)
    dia:SetTexture(M .. "diamond")
    dia:SetSize(bs * 0.56, bs * 0.56)
    dia:SetPoint("CENTER")
    dia:SetVertexColor(a[1], a[2], a[3], 1)
    local core = badge:CreateTexture(nil, "ARTWORK", nil, 4)
    core:SetTexture(M .. "diamond")
    core:SetSize(bs * 0.3, bs * 0.3)
    core:SetPoint("CENTER")
    core:SetVertexColor(bg[1], bg[2], bg[3], 1)
    local dot = badge:CreateTexture(nil, "ARTWORK", nil, 5)
    dot:SetTexture(M .. "diamond")
    dot:SetSize(bs * 0.14, bs * 0.14)
    dot:SetPoint("CENTER")
    dot:SetVertexColor(d[1], d[2], d[3], 1)
    -- Atmen des Scheins (Animation des Spiels, kein eigener Takt)
    pcall(function()
        local ag = halo:CreateAnimationGroup()
        ag:SetLooping("BOUNCE")
        local al = ag:CreateAnimation("Alpha")
        al:SetFromAlpha(0.25)
        al:SetToAlpha(0.75)
        al:SetDuration(0.9)
        ag:Play()
    end)
    marker.badge = badge
    marker.label = K.NewText(marker, 13)
    marker.label:SetPoint("BOTTOM", badge, "TOP", 0, 3)
    marker.label:SetTextColor(unpack(C.textBright))
    marker:Hide()
    QA.marker = marker
end

-- Sichtbarkeit und Groesse nach Entfernung (Yards). 0 = unsichtbar.
function QA.MarkerLook(dist, near)
    if type(dist) ~= "number" or type(near) ~= "number" or near <= 0 then return 0, 1 end
    if dist > near + QA.MARK_FADE then return 0, 1 end
    local alpha = dist <= near and 1 or (1 - (dist - near) / QA.MARK_FADE)
    -- nah: 1,15-fach, am Rand des Bereichs 0,85-fach
    local scale = 0.85 + 0.3 * (1 - math.min(1, dist / near))
    return alpha, scale
end

-- Die Zielmarke an den Bildschirmpunkt des Ziels. Der Strahl steht auf
-- dem Punkt. Verdeckt: halb durchsichtig.
-- 6.80.0.0 (auf Wunsch): erreicht man das Ziel ganz (Ankunftsabstand),
-- blendet die Marke langsam aus und kommt erst ab QA.MARK_BACK Yards
-- Abstand langsam wieder. Nur nach echter Ankunft; ein neues Ziel
-- setzt das zurueck. Ein- und Ausblenden mit QA.MARK_RATE je Sekunde.
QA.MARK_BACK, QA.MARK_RATE = 80, 1.2
-- Verdeckt: halb durchsichtig (6.80.1.0 kurz 0,8 - Fehldeutung, zurueck).
QA.MARK_HIDDEN = 0.5
QA.markShown, QA.markReached, QA.markKey, QA.markTime = 0, false, nil, nil

-- 6.139.0.0 (Wunsch: "habe ich eine Markierung selbst gesetzt und das Ziel
-- erreicht, will ich nicht noch mal hin, wenn ich weggehe"): eigene Ziele
-- (Kartenmarkierung, Haendler, Buch ...) gelten nach der Ankunft als
-- erledigt, sobald man QA.OWN_LEAVE Yards weiter weg ist - Pfeil und
-- Markierung verschwinden. Quests bleiben wie sie sind.
QA.OWN_LEAVE = 25
QA.ownKey, QA.ownReached = nil, false
function QA.OwnArrival(t, d)
    if not t or (t.kind ~= "custom" and t.kind ~= "waypoint") or type(d) ~= "number" then return false end
    local key = tostring(t.tm) .. ":" .. tostring(t.tx) .. ":" .. tostring(t.ty)
    if key ~= QA.ownKey then QA.ownKey, QA.ownReached = key, false end
    local arrive = math.max(K.Get(KEY, "arriveDistance") or 5, 8)
    if d <= arrive then QA.ownReached = true return false end
    if not (QA.ownReached and d >= arrive + QA.OWN_LEAVE) then return false end
    QA.ownKey, QA.ownReached = nil, false
    if t.kind == "custom" then
        QA.ClearCustom()
    else
        local function clear()
            local cm, st = _G.C_Map, _G.C_SuperTrack
            if cm and cm.ClearUserWaypoint then pcall(cm.ClearUserWaypoint) end
            if st and st.SetSuperTrackedUserWaypoint then pcall(st.SetSuperTrackedUserWaypoint, false) end
        end
        -- 1.0.4.4: nie im Kampf (s. QA.UnpinGame).
        if K.InCombat() then K.AfterCombat(clear) else clear() end
    end
    QA.ownDone = (QA.ownDone or 0) + 1
    return true
end

function QA.MarkerReach(key, dist, arrive)
    if key ~= QA.markKey then QA.markKey, QA.markReached = key, false end
    if type(dist) ~= "number" then return QA.markReached end
    if dist <= arrive then QA.markReached = true
    elseif QA.markReached and dist >= QA.MARK_BACK then QA.markReached = false end
    return QA.markReached
end

function QA.MarkerFade(want, now)
    -- Erstes Bild (neu im Blick): sofort, nur Uebergaenge blenden.
    if not QA.markTime then QA.markTime, QA.markShown = now, want return want end
    local dt = math.max(0, math.min(0.5, now - QA.markTime))
    QA.markTime = now
    local cur, step = QA.markShown, QA.MARK_RATE * dt
    if cur < want then cur = math.min(want, cur + step) else cur = math.max(want, cur - step) end
    QA.markShown = cur
    return cur
end

-- 6.80.4.0 (Beta-Test: neben dem Questgeber "2 m", beim Springen 1 m
-- weniger): die Navigation misst schraeg bis zum Punkt ueber dem Kopf. In
-- der Naehe zaehlt der Abstand am Boden (Kartenort), unter 2 m "hier".
QA.MARK_FLAT = 15
function QA.MarkerText(d3, flat, units)
    local d = d3
    if type(flat) == "number" and type(d3) == "number" and d3 <= QA.MARK_FLAT then d = math.min(d3, flat) end
    if type(d) == "number" and d < 2 then return "hier" end
    return QA.FormatDistance(d, units)
end

local function PlaceMarker(n, text, key)
    if not K.Get(KEY, "worldMarker") or not n or not n.frame or not n.onScreen then
        if marker then marker:Hide() end
        QA.markShown, QA.markTime = 0, nil
        return false
    end
    -- 6.73.3.0 (Beta-Test mit /wcui pfeil: "Wegpunkt gesetzt, verfolgt,
    -- auf dem Bildschirm ja" - und keine Marke zu sehen): bis hierher trat
    -- die eigene Marke zurueck, sobald SuperTrackedFrame des Spiels sichtbar
    -- war. Auf Forever ist er sichtbar, zeichnet aber nichts. Die eigene
    -- Marke steht jetzt immer; den Rahmen des Spiels beruehren wir nicht.
    local own = _G.SuperTrackedFrame
    QA.gameMarkerVisible = type(own) == "table" and own.IsVisible and K.Bool(own:IsVisible(), false) or false
    local alpha, scale = QA.MarkerLook(n.dist, K.Get(KEY, "markerNear") or 100)
    -- 6.80.2.0 (Beta-Test: blendete bei 57 m aus, "noch gar nicht am
    -- Gebiet"): das Questgebiet zaehlt nur noch als Ankunft, wenn auch das
    -- Ziel selbst nah ist (QA.AREA); dann gilt dieselbe Rueckkehr ab 80 m.
    local arrive = math.max(K.Get(KEY, "arriveDistance") or 5, 8)
    if n.inRange and type(n.dist) == "number" and n.dist <= QA.AREA then arrive = math.max(arrive, n.dist) end
    -- 6.80.3.0 (Wunsch): nur Questziele (Gegner, Objekte, Gebiet) blenden
    -- aus. Abgeben, Questgeber und eigene Wegpunkte bleiben stehen - im
    -- Gewirr soll man sehen, wo die Person steht. Ohne key: nie ausblenden.
    if key and QA.MarkerReach(key, n.dist, arrive) then alpha = 0 end
    alpha = QA.MarkerFade(alpha, Now())
    if alpha <= 0 then
        if marker then marker:Hide() end
        return false
    end
    if not marker then BuildMarker() end
    if marker._to ~= n.frame then
        marker:ClearAllPoints()
        if not pcall(marker.SetPoint, marker, "BOTTOM", n.frame, "CENTER", 0, 0) then
            marker:Hide()
            return false
        end
        marker._to = n.frame
    end
    marker:SetScale(scale)
    marker:SetAlpha(alpha * (n.occluded and QA.MARK_HIDDEN or 1))
    SetTxt(marker.label, text)
    marker:Show()
    return true
end

--------------------------------------------------
-- Ziel am Pfeil waehlen (1.0.5.63)
--------------------------------------------------
-- Feedback: "wie wird die jeweilige Quest angewaehlt?" - bisher nur ueber
-- die Symbole des Spiels in der Zielverfolgung, und die fehlten bei dem
-- Spieler. Ein Klick auf den Pfeil oeffnet darum eine eigene Liste: was
-- der Planer gerade zur Wahl hat, naechstes zuerst. Die Wahl bleibt beim
-- Pfeil (QA.manual) - nichts am Spiel wird angefasst, kein C_SuperTrack.
QA.MENU_MAX, QA.MENU_W, QA.MENU_ROW = 12, 280, 20
local menu
function QA.Pick(id)
    if QA.Smart() then QA.manual, QA.Chosen = id, nil else QA.manual, QA.Chosen = nil, id end
    QA.ClearCustom()
    if QA.Update then pcall(QA.Update, true) end
end
function QA.MenuItems()
    if QA.Smart() and not QA.manual then QA.Replan() else QA.Plan(QA.manual or QA.Chosen) end
    local out = {}
    for i, c in ipairs(QA.plan.list) do
        if i > QA.MENU_MAX then break end
        local t = QuestTitle(c.id)
        out[#out + 1] = { id = c.id, title = type(t) == "string" and t or ("Quest " .. c.id), dist = c.dist, done = c.done }
    end
    return out
end
local function MenuRow(i)
    local r = menu.rows[i]
    if r then return r end
    r = CreateFrame("Button", nil, menu)
    r:SetHeight(QA.MENU_ROW)
    r:SetPoint("TOPLEFT", menu, "TOPLEFT", 6, -6 - (i - 1) * QA.MENU_ROW)
    r:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -6, -6 - (i - 1) * QA.MENU_ROW)
    local hl = r:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints(r)
    hl:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.18)
    r.right = K.NewText(r, 11)
    r.right:SetPoint("RIGHT", r, "RIGHT", -4, 0)
    r.left = K.NewText(r, 12)
    r.left:SetPoint("LEFT", r, "LEFT", 4, 0)
    r.left:SetPoint("RIGHT", r.right, "LEFT", -6, 0)
    r.left:SetJustifyH("LEFT")
    r.left:SetWordWrap(false)
    r:SetScript("OnClick", function(self)
        menu:Hide()
        if self.act then self.act() end
    end)
    menu.rows[i] = r
    return r
end
function QA.ToggleMenu()
    if menu and menu:IsShown() then menu:Hide() return end
    if not frame then return end
    if not menu then
        menu = CreateFrame("Frame", "WeintCodexQuestArrowMenu", UIParent)
        menu:SetFrameStrata("DIALOG")
        menu:SetWidth(QA.MENU_W)
        menu:EnableMouse(true)
        K.Kachel(menu, { alpha = 0.95, shadow = 6 })
        menu.rows = {}
        QA.menu = menu
    end
    local items = QA.MenuItems()
    local n = 0
    local function Add(left, right, color, act)
        n = n + 1
        local r = MenuRow(n)
        r.left:SetText(left)
        r.right:SetText(right or "")
        r.left:SetTextColor(color[1], color[2], color[3])
        r.act = act
        r:Show()
    end
    local current = QA.manual or QA.Chosen
    for _, it in ipairs(items) do
        local id = it.id
        Add((id == current and "» " or "") .. it.title,
            (it.done and "Abgabe · " or "") .. QA.FormatDistance(it.dist, K.Get(KEY, "units")),
            id == current and C.accentBright or (it.done and C.successBright or C.textNormal),
            function() QA.Pick(id) end)
    end
    if #items == 0 then
        Add("Keine Quest mit bekanntem Ort auf diesem Kontinent.", nil, C.textDim, nil)
    end
    if QA.manual or not QA.Smart() then
        Add("Wieder selbst planen", nil, C.textMuted, function() QA.Resume() if QA.Update then pcall(QA.Update, true) end end)
    end
    if current then
        Add("Dieses Ziel 10 Minuten auslassen", nil, C.textMuted, function() QA.Skip() if QA.Update then pcall(QA.Update, true) end end)
    end
    for i = n + 1, #menu.rows do menu.rows[i]:Hide() end
    menu:SetHeight(12 + n * QA.MENU_ROW)
    menu:ClearAllPoints()
    menu:SetPoint("TOP", frame, "BOTTOM", 0, -4)
    menu:Show()
end

-- Die Symbole vor den Quests in der Zielverfolgung haengen an der
-- Spieleinstellung "questPOI" (Questziele auf der Karte). Gemerkt und
-- zurueckgegeben wie jede Spieleinstellung (ui/profile.lua). Nie im Kampf.
function QA.ApplyIcons()
    local PF = WeintCodex.UIProfile
    if not (PF and PF.SetCVar and PF.GetCVar) then return nil end
    if _G.InCombatLockdown and K.Bool(_G.InCombatLockdown(), false) then return nil end
    local now = PF.GetCVar("questPOI")
    if now == nil then return nil end           -- der Client kennt sie nicht
    if K.Get(KEY, "questIcons") then
        if tostring(now) ~= "1" then return PF.SetCVar("questPOI", "1", KEY) end
    elseif PF.ReleaseOwner then
        PF.ReleaseOwner(KEY)
    end
    return true
end

-- Kleiner Pfeil nach oben/unten mit Bewegung; nil = aus.
QA.CLIMB_PX = 14
function QA.SetClimb(dir)
    local ud = QA.updown
    if not ud then return end
    if dir ~= "up" and dir ~= "down" then
        -- Nur verbergen: jeder Durchlauf raeumt zuerst ab und zeigt dann
        -- neu - die Bewegung liefe sonst fuenfmal je Sekunde von vorn an.
        ud:Hide()
        QA.pitch = nil
        return
    end
    QA.pitch = dir
    ud:Show()
    if QA.climbDir == dir then return end
    QA.climbDir = dir
    ud:SetRotation(dir == "up" and 0 or math.pi)
    if QA.climbAnim and QA.climbMove then
        pcall(function()
            QA.climbAnim:Stop()
            QA.climbMove:SetOffset(0, dir == "up" and QA.CLIMB_PX or -QA.CLIMB_PX)
            QA.climbAnim:Play()
        end)
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

    -- Klick auf den Pfeil: Ziel waehlen (nur die Flaeche des Pfeils faengt
    -- Klicks, nicht der ganze Rahmen - dahinter liegt die Spielwelt).
    local click = CreateFrame("Button", nil, frame)
    click:SetAllPoints(arrow)
    click:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    click:SetScript("OnClick", function() if not frame._unlock then QA.ToggleMenu() end end)
    click:SetScript("OnEnter", function(self)
        local tt = _G.GameTooltip
        if not tt then return end
        tt:SetOwner(self, "ANCHOR_BOTTOM")
        tt:AddLine("Questpfeil")
        tt:AddLine("Klick: Ziel wählen", 1, 1, 1)
        tt:Show()
    end)
    click:SetScript("OnLeave", function() if _G.GameTooltip then _G.GameTooltip:Hide() end end)
    QA.click = click

    title = K.NewText(frame)
    title:SetPoint("BOTTOM", arrow, "TOP", 0, 2)
    title:SetWidth(260)
    title:SetWordWrap(false)

    dist = K.NewText(frame)
    dist:SetPoint("TOP", arrow, "BOTTOM", 0, -2)

    eta = K.NewText(frame)
    eta:SetPoint("TOP", dist, "BOTTOM", 0, -1)

    height = K.NewText(frame)
    height:SetPoint("TOP", eta, "BOTTOM", 0, -1)

    -- Kleiner Pfeil rechts neben dem grossen: nach oben = Ziel hoeher,
    -- nach unten = tiefer. Nur, wenn die Richtung bekannt ist.
    local updown = frame:CreateTexture(nil, "ARTWORK")
    updown:SetTexture(K.ARROW_TEXTURE)
    updown:SetSize(24, 24)
    updown:SetPoint("LEFT", arrow, "RIGHT", 2, 0)
    updown:SetVertexColor(unpack(C.accentBright))
    updown:Hide()
    QA.updown = updown
    -- 1.0.5.63 (Wunsch: "die Animation so, dass man erkennt, dass man nach
    -- oben oder unten muss"): der kleine Pfeil steigt (oder sinkt) immer
    -- wieder ein Stueck und verblasst dabei. Die Bewegung rechnet das Spiel
    -- (AnimationGroup) - kein eigener Takt je Bild.
    if updown.CreateAnimationGroup then
        local ok, ag = pcall(updown.CreateAnimationGroup, updown)
        if ok and type(ag) == "table" and ag.CreateAnimation then
            pcall(function()
                ag:SetLooping("REPEAT")
                local mv = ag:CreateAnimation("Translation")
                mv:SetDuration(0.9)
                mv:SetSmoothing("OUT")
                local fade = ag:CreateAnimation("Alpha")
                fade:SetFromAlpha(1)
                fade:SetToAlpha(0.15)
                fade:SetDuration(0.45)
                fade:SetStartDelay(0.45)
                QA.climbAnim, QA.climbMove = ag, mv
            end)
        end
    end

    -- Fuer den Prueflauf: was der Pfeil gerade anzeigt.
    QA.frame, QA.arrow = frame, arrow
    QA.texts = { title = title, dist = dist, eta = eta, height = height }

    frame.WCShowForUnlock = function(self, on)
        self._unlock = on and true or nil
        if on then
            SetTxt(title, "Questpfeil")
            SetTxt(dist, "120 m")
            SetTxt(eta, "")
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
    if QA._aim then QA._aim.lastRot = nil end
    if not frame then return end
    frame:SetScale((K.Get(KEY, "scale") or 100) / 100)
    if Is3D() then
        arrow:SetTexture(QA.SheetFor(QA.pitch))
        QA.sheetShown = QA.SheetFor(QA.pitch)
        arrow:SetSize(72, 72)
    else
        arrow:SetTexture(K.ARROW_TEXTURE)
        arrow:SetSize(52, 52)
    end
    K.SetFont(title, 12)
    K.SetFont(dist, 14)
    K.SetFont(eta, 10)
    K.SetFont(height, 10)
    title:SetTextColor(unpack(C.textNormal))
    dist:SetTextColor(unpack(C.textBright))
    eta:SetTextColor(unpack(C.textMuted))
    height:SetTextColor(unpack(C.infoBright))
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
-- Ohne Ereignis alle 3 s statt jede Sekunde (6.14.0.2): jede Suche legt
-- die Questliste der Karte neu an. Was den Ort aendert, meldet das Spiel
-- (Questlog, Wegpunkt, Leiche, Gebiet) und erzwingt die Suche sofort.
QA.RESOLVE_EVERY = 3
-- Zwischen zwei ganzen Durchlaeufen dreht sich nur der Pfeil (6.6.1.9):
-- die Blickrichtung aendert sich jedes Bild, die eigene Position kaum.
-- Ein ganzer Durchlauf fragt Karte, Weltposition, Navigation ab und
-- setzt Texte - zwanzigmal je Sekunde waren das im Beta-Test 28 KB/s
-- Wegwerf-Speicher. Jetzt fuenfmal ganz, dazwischen nur der Winkel aus
-- den gemerkten Punkten (reine Rechnung, keine neuen Tabellen).
local aim = { ok = false }
QA._aim = aim
-- Was der Kompass braucht (ui/compass.lua): eigener Ort, der Punkt voraus
-- (Laufweg oder Wegpunkt), das Ziel, der naechste Halt - alles auf dem
-- Kontinent, auf dem man steht. ok = false: nichts zu zeigen.
local cmp = { ok = false }
QA.cmp = cmp
function QA.Turn()
    if not aim.ok or not (arrow and arrow:IsShown()) then return false end
    local facing = _G.GetPlayerFacing and K.Plain(_G.GetPlayerFacing())
    if type(facing) ~= "number" then return false end
    local _, rotation, bearing = QA.Solve(aim.pN, aim.pW, aim.tN, aim.tW, facing)
    if not rotation then return false end
    rotation = Norm(QA.Ease(bearing, Now()) - facing)
    if QA.AngleMoved(aim.lastRot, rotation) then
        PointArrow(rotation)
        SetArrowColor(rotation)
        aim.lastRot = rotation
    end
    return true
end

local function Target(playerMap, force)
    local now = _G.GetTime and _G.GetTime() or 0
    if not force and cache.at >= 0 and cache.map == playerMap and (now - cache.at) < QA.RESOLVE_EVERY then
        return cache
    end
    local status, mapID, tx, ty, name, kind, nav = ResolveTarget(playerMap)
    cache.at, cache.map, cache.status, cache.title, cache.kind = now, playerMap, status, name, kind
    cache.nav = nav and true or false
    -- Derselbe Ort wie beim letzten Mal: die Weltlage steht schon da (ein
    -- Vektor weniger je Sekunde).
    if status == "ok" and cache.tc and cache.tm == mapID and cache.tx == tx and cache.ty == ty then return cache end
    cache.tc, cache.tN, cache.tW, cache.tm, cache.tx, cache.ty = nil, nil, nil, nil, nil, nil
    if status == "ok" then
        cache.tc, cache.tN, cache.tW = ToWorld(mapID, tx, ty)
        cache.tm, cache.tx, cache.ty = mapID, tx, ty
    end
    return cache
end

-- In einer Instanz (Dungeon, Schlachtzug, Schlachtfeld, Arena,
-- Szenario)? Die offene Welt ist "none".
function QA.InInstance()
    if not _G.IsInInstance then return false end
    local inside, kind = _G.IsInInstance()
    kind = K.Plain(kind)
    if type(kind) == "string" then return kind ~= "none" end
    return K.Bool(inside, false)
end

function QA.Update(force)
    aim.ok = false
    cmp.ok = false
    -- Die Linie auf der Minikarte zeigt sich nur, wenn dieser Lauf sie zieht.
    if WeintCodex.UIRoute then WeintCodex.UIRoute.HideMinimap() end
    -- Die Zielmarke zeigt sich nur, wenn dieser Durchlauf sie setzt.
    if marker then marker:Hide() end
    if not frame or frame._unlock then return end
    if not K.IsActive(KEY) then frame:Hide() return end
    if K.Get(KEY, "hideInCombat") and K.InCombat() then frame:Hide() return end
    if K.Get(KEY, "hideInInstance") and QA.InInstance() then frame:Hide() return end

    local playerMap = BestMap()
    -- Ohne Karte, aber mit Lage (Tiefenbahn, K.RAW_WORLD): das zuletzt
    -- gefundene Ziel gilt weiter - den Ort einer Quest sucht man ueber die
    -- Karte, auf der man steht, und die gibt es hier nicht.
    local rawC, rawN, rawW
    if not playerMap and K.PlayerWorldRaw then rawC, rawN, rawW = K.PlayerWorldRaw() end
    local t = (rawC and cache.status == "ok" and cache.tc) and cache or Target(playerMap, force)
    local status, name = t.status, t.title
    if status == "none" then frame:Hide() return end

    local showTitle = K.Get(KEY, "showTitle")
    SetTxt(title, showTitle and name or "")
    SetTxt(eta, "")
    SetTxt(height, "")
    QA.SetClimb(nil)

    -- Zuerst die eigene Position: ohne sie laesst sich auch der Ort der
    -- Quest nicht suchen (er haengt an der Karte, auf der man steht), und
    -- "Ort unbekannt" waere dann eine Behauptung ueber die Quest statt
    -- ueber den Client.
    if not playerMap and not rawC then
        arrow:Hide()
        SetTxt(dist, "Position unbekannt")
        frame:Show()
        return
    end
    if status == "unknown" then
        arrow:Hide()
        SetTxt(dist, "Ort unbekannt")
        frame:Show()
        return
    end

    local pc, pN, pW = PlayerWorld()
    if not pc and rawC then pc, pN, pW = rawC, rawN, rawW end
    local tc, tN, tW = t.tc, t.tN, t.tW
    if not pc then
        arrow:Hide()
        SetTxt(dist, "Position unbekannt")
        frame:Show()
        return
    end
    if not tc then
        arrow:Hide()
        SetTxt(dist, "Ort unbekannt")
        frame:Show()
        return
    end
    -- Mehrere Fundorte, offene Quest, nah am Gebiet: der naechste Fundort.
    local gN, gW = tN, tW
    QA.spotUsed = false
    if t.kind == "quest" and pc == tc and type(name) == "string" and not name:find("^Abgeben: ")
       and (tN - pN) ^ 2 + (tW - pW) ^ 2 <= QA.SPOT_NEAR * QA.SPOT_NEAR then
        local sN, sW = QA.NearestSpot(QA.lastQuest, playerMap)
        if sN then tN, tW, QA.spotUsed = sN, sW, true end
    end
    -- Routenplaner (ui/route.lua): schneller ueber Flug, Schiff, Portal
    -- oder Ruhestein? Dann zeigt der Pfeil auf den naechsten Wegpunkt, die
    -- Minikarte die Linie dorthin. Die Navigation des Spiels (Hoehe,
    -- Zielmarke) gilt dem Ziel, nicht dem Wegpunkt.
    local RT = WeintCodex.UIRoute
    local planning = RT and K.Get(KEY, "routePlan") ~= false
    local route, hop
    if planning then
        route = RT.Plan(pc, pN, pW, tc, tN, tW)
        hop = RT.Next(route)
    end
    QA.route, QA.hop = route, hop
    local routeLine = planning and (RT.Line(route, hop)
        or (not route or route.direct) and RT.NoTaxiHint(route, pc, tc,
            pc == tc and math.sqrt((tN - pN) ^ 2 + (tW - pW) ^ 2) or nil)) or nil
    if hop and hop.mode == "teleport" then
        arrow:Hide()
        SetTxt(dist, hop.hearth and "Ruhestein benutzen" or "Teleport wirken")
        SetTxt(eta, routeLine or "")
        frame:Show()
        return
    end
    if hop then
        tc, tN, tW = hop.node.c, hop.node.n, hop.node.w
        if showTitle then SetTxt(title, ViaTitle(name, hop.waypoint)) end
    end
    -- Gelaendekarte (ui/navmesh.lua): der Pfeil folgt dem Laufweg, die
    -- Minikarte zeichnet ihn. Bis er berechnet ist: Luftlinie.
    local NV = WeintCodex.UINav
    local navPath, navRest
    -- Luftlinie zum Ziel selbst: die Hoehe rechnet gegen sie, nicht gegen
    -- den Punkt voraus auf dem Weg (6.32.2.0, Beta-Test: "414 m
    -- Hoehenunterschied bei 570 m" - es war der Abstand zum Punkt voraus).
    local flatGoal = math.sqrt(((hop and tN or gN) - pN) ^ 2 + ((hop and tW or gW) - pW) ^ 2)
    if planning and NV and pc == tc and K.Get(KEY, "terrain") ~= false then
        navPath = NV.Path(pc, pN, pW, tN, tW)
        if navPath then
            -- 1.0.5.63: QA.Follow statt NV.Steer + QA.HoldCorner.
            local sN, sW, rest, segI = QA.Follow(navPath, pN, pW)
            navRest = rest
            -- 6.103.5.0: Ziel zuerst - dem Weg nur folgen, wenn er wirklich
            -- von der Luftlinie abweicht (QA.OnCourse).
            if not QA.OnCourse(navPath, segI, pN, pW, tN, tW, rest) then tN, tW = sN, sW end
        end
    end
    QA.navPath = navPath
    if planning then RT.DrawMinimap(pc, pN, pW, tc, tN, tW, navPath) end
    if _G.UnitOnTaxi and K.Bool(_G.UnitOnTaxi("player"), false) then
        arrow:Hide()
        SetTxt(dist, "Im Flug")
        SetTxt(eta, routeLine or "")
        frame:Show()
        return
    end
    if planning and RT.Riding() then
        arrow:Hide()
        SetTxt(dist, "An Bord")
        SetTxt(eta, routeLine or "")
        frame:Show()
        return
    end
    if pc ~= tc then
        arrow:Hide()
        SetTxt(dist, "Anderer Kontinent")
        SetTxt(eta, routeLine or "")
        frame:Show()
        return
    end

    local facing = _G.GetPlayerFacing and K.Plain(_G.GetPlayerFacing())
    local yards, rotation, bearing = QA.Solve(pN, pW, tN, tW, facing)
    if rotation then rotation = Norm(QA.Ease(bearing, Now()) - facing) end
    aim.ok, aim.pN, aim.pW, aim.tN, aim.tW = false, pN, pW, tN, tW
    cmp.ok, cmp.c, cmp.pN, cmp.pW, cmp.bN, cmp.bW = true, pc, pN, pW, tN, tW
    cmp.gN, cmp.gW = nil, nil
    if t.tc == pc then cmp.gN, cmp.gW = t.tN, t.tW end
    cmp.sN, cmp.sW, cmp.stop = nil, nil, nil
    if hop and hop.node and hop.node.c == pc then
        cmp.sN, cmp.sW, cmp.stop = hop.node.n, hop.node.w, hop.mode
    end
    cmp.dist = navRest or yards
    cmp.n = (cmp.n or 0) + 1

    -- 1.0.5.63: hoeher/tiefer aus der Gelaendekarte - fuer jedes Ziel auf
    -- dem eigenen Kontinent, nicht nur das der Navigation des Spiels.
    local terrLine, terrDir, terrKnown
    if K.Get(KEY, "showHeight") and K.Get(KEY, "terrain") ~= false and t.tc == pc and not hop
       and flatGoal <= QA.TERRAIN_RANGE then
        terrLine, terrDir, terrKnown = QA.TerrainLine(pc, pN, pW, t.tN, t.tW, K.Get(KEY, "units"))
        if terrLine then
            SetTxt(height, terrLine)
            QA.SetClimb(terrDir)
        end
    end

    -- Hoehe und Zielmarke aus der Navigation des Spiels (siehe Kopf).
    local nav = t.nav and not hop and QA.Nav() or nil
    if nav then
        -- 6.75.3.0 (Messung: "im Zielgebiet nein", obwohl mitten im Gebiet -
        -- Forever meldet InRange nicht; der Mittelpunkt allein war dem
        -- Spieler zu ungenau): bei einer offenen Quest gilt man als "drin",
        -- sobald man nahe an einem Fundort ihrer Ziele steht - Gegner,
        -- Objekte, wer die Gegenstaende fallen laesst (data/questdb.lua,
        -- dieselben Punkte wie die Questhilfe auf der Karte). Kennt der
        -- Bestand keine, bleibt die Nadel.
        if t.kind == "quest" and type(name) == "string" and not name:find("^Abgeben: ")
           and QA.InArea(QA.lastQuest, playerMap) then
            nav.inRange = true
        end
        local units = K.Get(KEY, "units")
        if K.Get(KEY, "showHeight") and not terrLine then
            local first, second
            -- Kennt die Gelaendekarte beide Hoehen und nennt keinen
            -- Unterschied, gibt es keinen - die Rechnung unten schweigt.
            local dh = (not terrKnown) and QA.Height(nav.dist, flatGoal) or nil
            local dir = QA.TrackHeight(QA.PlayerZ(), dh)
            -- Erst in der Naehe verlaesslich: Kartenort und Navigationspunkt
            -- liegen auf Entfernung nicht genau aufeinander.
            if dh and dh >= 8 and flatGoal <= 300 then
                local word = (dir == "up" and " höher") or (dir == "down" and " tiefer") or ""
                first = (word ~= "" and "Ziel " or "Höhenunterschied ") .. "≈ "
                    .. QA.FormatDistance(dh, units) .. word
                QA.SetClimb(dir)
            end
            if nav.occluded and nav.dist <= 150 then
                second = "verdeckt – Höhle, Gebäude oder Hang?"
            end
            SetTxt(height, first and second and (first .. " · " .. second) or first or second or "")
        end
        local fades = t.kind == "quest" and type(name) == "string" and not name:find("^Abgeben: ")
        PlaceMarker(nav, QA.MarkerText(nav.dist, flatGoal, units), fades and ("quest:" .. name) or nil)
    end

    local boardR = math.max(K.Get(KEY, "arriveDistance") or 5, 10)
    QA.boarding = hop and QA.Within(QA.boarding, navRest or yards, boardR, boardR + 6) or false
    if QA.boarding then
        arrow:Hide()
        SetTxt(dist, (hop.mode == "flight" and "Beim Flugmeister: " or "Hier einsteigen: ") .. hop.leg)
        SetTxt(eta, routeLine or "")
        frame:Show()
        return
    end
    -- 6.139.0.0: eigenes Ziel erreicht und wieder weggegangen -> erledigt.
    if QA.OwnArrival(t, navRest or yards) then
        frame:Hide()
        if _G.C_Timer and _G.C_Timer.After then _G.C_Timer.After(0, function() QA.Update(true) end) end
        return
    end
    if (navRest or yards) <= (K.Get(KEY, "arriveDistance") or 5) then
        arrow:Hide()
        SetTxt(dist, t.kind == "corpse" and "Bei deiner Leiche" or t.kind == "healer" and "Beim Geistheiler" or "Am Ziel")
        frame:Show()
        return
    end

    SetTxt(dist, QA.DistText(navRest or yards, K.Get(KEY, "units"), hop and hop.suffix or nil))
    if rotation then
        PointArrow(rotation)
        SetArrowColor(rotation)
        aim.lastRot = rotation
        -- "Nur Kompass": der Pfeil weicht, die Zeilen darunter bleiben.
        arrow:SetShown(K.Get(KEY, "compass") ~= "only")
        aim.ok = true
    else
        arrow:Hide()
        SetTxt(dist, QA.FormatDistance(yards, K.Get(KEY, "units")) .. " · " .. QA.Compass(bearing))
    end

    -- Ankunftszeit aus der tatsaechlichen Annaeherung, nicht aus der
    -- Laufgeschwindigkeit: wer im Zickzack um einen Berg laeuft, kommt
    -- nicht mit Laufgeschwindigkeit naeher.
    if routeLine and K.Get(KEY, "showEta") then
        SetTxt(eta, routeLine)
    elseif K.Get(KEY, "showEta") and _G.GetTime then
        local now = _G.GetTime()
        if lastYards and lastTime and now > lastTime then
            local speed = (lastYards - yards) / (now - lastTime)
            QA._speed = (QA._speed or speed) * 0.85 + speed * 0.15
            if QA._speed > 0.5 then
                local secs = math.floor(yards / QA._speed + 0.5)
                SetTxt(eta, QA.EtaText(secs))
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
-- kein Ereignis. Zwanzigmal je Sekunde dreht sich der Pfeil, fuenfmal
-- wird alles neu bestimmt (QA.Turn) - und nur solange etwas ausgewaehlt
-- ist; ohne Ziel laeuft der Takt nicht.

local ticker = CreateFrame("Frame")
local acc, full, planAcc = 0, 0, 0
QA.FULL_EVERY = 0.2
local function OnTick(_, elapsed)
    acc = acc + (elapsed or 0)
    if acc < 0.05 then return end
    full = full + acc
    planAcc = planAcc + acc
    acc = 0
    -- Unterwegs aendert sich, was am naechsten liegt.
    if planAcc >= QA.PLAN_EVERY then
        planAcc = 0
        QA.Replan()
    end
    if full >= QA.FULL_EVERY or not QA.Turn() then
        full = 0
        QA.Update()
        if WeintCodex.UICompass then WeintCodex.UICompass.Refresh() end
    end
    -- Auswahl weg (oder im Kampf ausgeblendet): der Takt steht, bis ein
    -- Ereignis ihn wieder anwirft.
    if not (frame and frame:IsShown()) then ticker:SetScript("OnUpdate", nil) end
end
OnTick = K.Measured("Questpfeil", OnTick)

local events = CreateFrame("Frame")
local function Refresh()
    lastYards, lastTime, QA._speed = nil, nil, nil
    QA.ResetHeight()
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

-- Planen nach Ereignissen: gesammelt, hoechstens einmal je halbe Sekunde.
-- Ein haengender Merker (Zeitgeber nie gelaufen) sperrt hoechstens 2 s.
local planPendingAt
local function SchedulePlan()
    local now = _G.GetTime and K.Plain(_G.GetTime()) or 0
    if planPendingAt and now - planPendingAt < 2 then return end
    planPendingAt = now
    Later(function()
        planPendingAt = nil
        QA.Replan()
        Refresh()
    end)
end

local autoAt = -math.huge   -- wann das Spiel zuletzt selbst gewaehlt haben kann
local REPLAN = { QUEST_LOG_UPDATE = true, QUEST_POI_UPDATE = true, QUEST_ACCEPTED = true,
                 QUEST_TURNED_IN = true, QUEST_REMOVED = true, ZONE_CHANGED = true,
                 ZONE_CHANGED_NEW_AREA = true, PLAYER_ENTERING_WORLD = true, SUPER_TRACKING_CHANGED = true }
local AUTO = { QUEST_ACCEPTED = true, QUEST_TURNED_IN = true, QUEST_REMOVED = true,
               PLAYER_ENTERING_WORLD = true }

local function OnSmartEvent(event, questID, game)
    local now = _G.GetTime and K.Plain(_G.GetTime()) or 0
    if AUTO[event] then autoAt = now end
    if event == "SUPER_TRACKING_CHANGED" and QA.PinBusy() then
        Refresh()
        return
    end
    if event == "SUPER_TRACKING_CHANGED" then
        if not game then
            QA.manual = nil
        elseif game ~= QA.Chosen then
            -- Erst kurz danach entscheiden: das Spiel meldet die neue
            -- Verfolgung womoeglich VOR dem Annehmen, das sie ausgeloest hat.
            local changedAt = now
            Later(function()
                local st = _G.C_SuperTrack
                local still = st and st.GetSuperTrackedQuestID and st.GetSuperTrackedQuestID()
                if still ~= game or math.abs(autoAt - changedAt) <= QA.AUTO_WINDOW then return end
                QA.manual, QA.Chosen = game, nil
                -- 6.60.1.0 (Beta-Test: "Buch gewaehlt, dann doch eine Quest
                -- angeklickt - der Pfeil aendert sich nicht mehr"): wer
                -- selbst eine Quest waehlt, loest das eigene Ziel.
                QA.ClearCustom()
                Refresh()
            end)
        end
    end
    if (event == "QUEST_TURNED_IN" or event == "QUEST_REMOVED") and questID then
        if questID == QA.manual then QA.manual = nil end
        if questID == QA.Chosen then QA.Chosen = nil end
    end
    if REPLAN[event] then SchedulePlan() end
    Refresh()
end

local function OnEvent(_, event, questID)
    if REPLAN[event] then QA.PlanDirty() end
    local st = _G.C_SuperTrack
    local game = st and st.GetSuperTrackedQuestID and st.GetSuperTrackedQuestID()
    if game == 0 then game = nil end
    if QA.Smart() then return OnSmartEvent(event, questID, game) end
    QA.manual = nil
    -- Waehlt der Spieler selbst eine Quest, gilt seine Wahl. Loescht das
    -- Spiel die Verfolgung (abgegeben), bleibt die des Pfeils.
    if event == "SUPER_TRACKING_CHANGED" and game then QA.Chosen = nil end
    local current = QA.Chosen or game

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

-- /wcui pfeil: was der Client fuer die Hoehe hergibt.
function QA.Inspect()
    local out = {}
    local function N(v) v = K.Plain(v) return type(v) == "number" and string.format("%.1f", v) or "–" end
    if _G.UnitPosition then
        local ok, y, x, z = pcall(_G.UnitPosition, "player")
        if ok then
            out[#out + 1] = "Eigene Position (UnitPosition): y " .. N(y) .. ", x " .. N(x) .. ", Höhe " .. N(z)
                .. (K.Plain(z) == 0 and " – 0 heißt meist: der Client nennt keine Höhe" or "")
        else
            out[#out + 1] = "UnitPosition: Fehler (" .. tostring(y) .. ")"
        end
    else
        out[#out + 1] = "UnitPosition: gibt es nicht"
    end
    local n = QA.Nav()
    if not n then
        out[#out + 1] = "Navigation des Spiels: kein Ziel (Quest im Questlog verfolgen oder Kartenmarkierung setzen)"
    else
        out[#out + 1] = string.format("Navigation: Luftlinie %s, verdeckt %s, auf dem Bildschirm %s, im Zielgebiet %s",
            N(n.dist), n.occluded and "ja" or "nein", n.onScreen and "ja" or "nein", n.inRange and "ja" or "nein")
        out[#out + 1] = string.format("Questgebiet aus Fundorten: %s (%d Fundorte der Ziele hier)",
            QA.areaMemo.inside and "drin" or "nicht drin", QA.areaMemo.spots or 0)
    end
    out[#out + 1] = "Ankunft ab " .. QA.FormatDistance(K.Get(KEY, "arriveDistance") or 5, K.Get(KEY, "units"))
        .. (QA.hop and (" · Einstieg ab " .. QA.FormatDistance(math.max(K.Get(KEY, "arriveDistance") or 5, 10), K.Get(KEY, "units"))
            .. (QA.boarding and " (dort)" or "")) or "")
    if QA.spotUsed and QA.areaMemo.nearD then
        out[#out + 1] = "Ziel: nächster von " .. (QA.areaMemo.spots or 0) .. " Fundorten, "
            .. QA.FormatDistance(QA.areaMemo.nearD, K.Get(KEY, "units"))
    end
    if follow.path and follow.state then
        out[#out + 1] = string.format("Laufweg: %s · Abschnitt %d · %d m neben dem Weg", follow.state,
            ((follow.i or 1) + 1) / 2, math.floor((follow.off or 0) + 0.5))
    end
    if QA.ghostLast then out[#out + 1] = "Als Geist: " .. QA.ghostLast end
    out[#out + 1] = "Zielmarke im Raum: " .. ((QA.marker and QA.marker:IsShown()) and "steht" or "nicht gezeigt")
        .. " · Marke des Spiels " .. (QA.gameMarkerVisible and "sichtbar" or "nicht sichtbar")
    out[#out + 1] = "Wegpunkt für eigene Ziele: " .. (QA.pinState or "noch nicht versucht")
        .. (QA.pin and (QA.PinIsOurs() and ", verfolgt" or ", nicht mehr unserer") or "")
    out[#out + 1] = "Richtung der Höhe: " .. ((sign == "up" and "höher") or (sign == "down" and "tiefer")
        or "unbekannt – erst, wenn der Client die eigene Höhe nennt und du bergauf oder bergab gehst")
    -- Planen (6.6.2.7): wer gewaehlt hat und was zur Wahl stand.
    -- 1.0.5.63: Symbole vor den Quests - was das Spiel dazu sagt.
    do
        local PF = WeintCodex.UIProfile
        local v = PF and PF.GetCVar and PF.GetCVar("questPOI")
        out[#out + 1] = "Symbole vor den Quests (questPOI): " .. (v == nil and "kennt der Client nicht" or tostring(v))
    end
    if not QA.Smart() then
        out[#out + 1] = "Ziel: nur die Quest, die das Spiel verfolgt (Einstellung „Welches Ziel“)"
    elseif QA.manual then
        out[#out + 1] = "Ziel: selbst gewählt – " .. (QuestTitle(QA.manual) or QA.manual)
            .. " (bis zur Abgabe; /wcui pfeil planen gibt die Wahl ab)"
    else
        QA.Chosen = QA.Plan(QA.Chosen)
        out[#out + 1] = "Ziel: geplant – " .. (QA.Chosen and (QuestTitle(QA.Chosen) or QA.Chosen) or "nichts im Questlog mit Ort")
        if QA.plan.hold then out[#out + 1] = "   Abgaben warten: im Gebiet liegt noch Offenes (Einstellung „Erst alles erledigen“)" end
        for i = 1, math.min(5, #QA.plan.list) do
            local c = QA.plan.list[i]
            out[#out + 1] = string.format("   %d. %s%s – %s%s", i, c.done and "Abgeben: " or "",
                tostring(QuestTitle(c.id) or c.id), QA.FormatDistance(c.dist, K.Get(KEY, "units")),
                c.weight ~= 1 and string.format(" (× %.1f)", c.weight):gsub("%.", ",") or "")
        end
    end
    if WeintCodex.UIRoute then WeintCodex.UIRoute.Inspect(out) end
    return out
end

local function Enable()
    if not frame then
        Build()
        -- Ganz oben (ui/layout.lua): darunter schreibt das Spiel seine
        -- roten Fehler ("Fähigkeit ist noch nicht bereit"), in 6.0.0.5
        -- mitten in den Pfeil.
        K.RegisterMover(frame, "questarrow", "Questpfeil", K.Layout("questarrow"))
    end
    K.SetMoverEnabled("questarrow", true)
    ApplyStyle()
    for _, e in ipairs({
        "SUPER_TRACKING_CHANGED", "QUEST_LOG_UPDATE", "QUEST_POI_UPDATE",
        "USER_WAYPOINT_UPDATED", "ZONE_CHANGED", "ZONE_CHANGED_NEW_AREA",
        "ZONE_CHANGED_INDOORS", "PLAYER_ENTERING_WORLD", "WAYPOINT_UPDATE",
        "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED",
        "QUEST_TURNED_IN", "QUEST_REMOVED", "QUEST_ACCEPTED",
        "PLAYER_DEAD", "PLAYER_ALIVE", "PLAYER_UNGHOST", "CORPSE_POSITION_UPDATE",
    }) do pcall(events.RegisterEvent, events, e) end
    events:SetScript("OnEvent", K.Measured("Questpfeil", OnEvent))
    if WeintCodex.UIRoute then WeintCodex.UIRoute.Start() end
    -- K.Activate setzt _active erst nach Enable; der erste Stand kommt
    -- deshalb einen Takt spaeter aus dem ersten Ereignis oder hier.
    if _G.C_Timer and _G.C_Timer.After then _G.C_Timer.After(0, Refresh) end
    if _G.C_Timer and _G.C_Timer.After then _G.C_Timer.After(2, QA.ApplyIcons) else QA.ApplyIcons() end
end

local function Disable()
    if menu then menu:Hide() end
    if WeintCodex.UIRoute then WeintCodex.UIRoute.Stop() end
    events:UnregisterAllEvents()
    ticker:SetScript("OnUpdate", nil)
    if frame then frame:Hide() end
    K.SetMoverEnabled("questarrow", false)
    if WeintCodex.UICompass then WeintCodex.UICompass.Refresh() end
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
        QA.ApplyIcons()
        QA.Replan()
        Refresh()
        if WeintCodex.UICompass then WeintCodex.UICompass.Refresh() end
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
                  { type = "toggle", label = "Zielmarke im Raum", key = "worldMarker",
                    description = "Eine Nadel genau am Ziel, auf dem Berg oder am Höhleneingang. Für die Quest, die das Spiel verfolgt, Kartenmarkierungen und eigene Ziele (Eingang, Händler, Buch) – dafür setzt WeintCodex den Wegpunkt des Spiels und nimmt ihn danach wieder ab." })
            B:Row({ type = "dropdown", label = "Kompass", key = "compass", items = {
                        { value = "off",  text = "Aus" },
                        { value = "both", text = "Pfeil und Kompass" },
                        { value = "only", text = "Nur Kompass" } },
                    tooltip = "Ein schmales Band mit den Himmelsrichtungen: das Ziel als Nadel, der nächste Halt, der Punkt voraus auf dem Weg mit Entfernung. Verschieben im Gestaltungsmodus." },
                  { type = "slider", label = "Größe des Kompasses", key = "compassScale", min = 50, max = 200, step = 10,
                    format = function(v) return string.format("%d %%", v) end,
                    disabled = function() return K.Get(KEY, "compass") == "off" end })
            B:Row({ type = "toggle", label = "Im Kampf ausblenden", key = "hideInCombat" },
                  { type = "toggle", label = "In Dungeons ausblenden", key = "hideInInstance",
                    description = "Auch in Schlachtzügen, auf Schlachtfeldern und in Arenen. Dort nennt das Spiel keine Position." })
            B:Section("Mitdenken")
            B:Row({ type = "dropdown", label = "Welches Ziel", key = "plan", items = {
                        { value = "smart",   text = "Selbst planen (nächstes lohnendes Ziel)" },
                        { value = "tracked", text = "Nur die Quest, die das Spiel verfolgt" } },
                    tooltip = "Selbst planen: aus deinem ganzen Questlog das Ziel mit dem kürzesten Weg – offene Quests an ihrem Zielgebiet, erfüllte an der Abgabe. Quests weit über deiner Stufe und Gruppenquests zählen weiter weg. Klickst du selbst eine Quest an, gilt sie bis zur Abgabe." },
                  { type = "toggle", label = "Als Geist zur Leiche", key = "corpse",
                    description = "Nach dem Tod zeigt der Pfeil von selbst zu deiner Leiche." })
            B:Row({ type = "toggle", label = "Als Geist: zum Geistheiler, wenn näher", key = "ghostHealer",
                    description = "Liegt ein Geistheiler deiner Karte deutlich näher als die Leiche, zeigt der Pfeil zu ihm." },
                  { type = "toggle", label = "Erst alles erledigen, dann abgeben", key = "collect",
                    disabled = function() return K.Get(KEY, "plan") == "tracked" end,
                    description = "Solange in deinem Gebiet noch eine offene, machbare Quest liegt, führt der Pfeil zu keiner Abgabe. Rote Quests und Gruppenquests halten die Abgaben nicht auf." })
            B:Row({ type = "toggle", label = "Symbole vor den Quests", key = "questIcons",
                    description = "Schaltet die Spieleinstellung für Questziele an: an ihr hängen die runden Symbole vor jeder Quest in der Zielverfolgung. Ein Klick darauf wählt die Quest für den Pfeil." },
                  { type = "empty" })
            -- 6.10.1.0: Aussehen des Pfeils und was nach einer Quest kommt, zugeklappt.
            B:Advanced()
            B:Section("Der Pfeil im Einzelnen")
            B:Row({ type = "dropdown", label = "Pfeil", key = "style", items = {
                        { value = "3d",   text = "Dreidimensional" },
                        { value = "flat", text = "Flach" } } },
                  { type = "toggle", label = "Farbe nach Richtung", key = "colorByCourse",
                    description = "Grün geradeaus, gelb quer, rot in die falsche Richtung." })
            B:Row({ type = "toggle", label = "Ankunftszeit", key = "showEta",
                    description = "Aus der tatsächlichen Annäherung der letzten Sekunden." },
                  { type = "toggle", label = "Höhenunterschied", key = "showHeight",
                    description = "Aus der Navigation des Spiels: wie viel höher oder tiefer das Ziel liegt und ob es verdeckt ist (Höhle, Gebäude). Ob höher oder tiefer, nur wenn der Client deine eigene Höhe nennt – /wcui pfeil sagt es." })
            B:Row({ type = "slider", label = "„Am Ziel“ ab", key = "arriveDistance", min = 2, max = 30, step = 1,
                    format = function(v) return string.format("%d m", v) end },
                  { type = "slider", label = "Zielmarke im Raum ab", key = "markerNear", min = 25, max = 400, step = 25,
                    format = function(v) return string.format("%d m", v) end,
                    disabled = function() return not K.Get(KEY, "worldMarker") end })
            B:Section("Routenplaner")
            B:Row({ type = "toggle", label = "Schnellsten Weg planen", key = "routePlan",
                    description = "Zeigt über Flugmeister, Schiffe, Zeppeline, Tiefenbahn, Portale und Ruhestein, wenn das schneller ist als laufen, mit Linie auf der Minikarte. Flugpunkte lernt er, wenn du eine Flugkarte öffnest; Abfahrtszeiten, wenn du mitfährst." },
                  { type = "toggle", label = "Laufweg übers Gelände", key = "terrain",
                    description = "Der Pfeil folgt dem echten Weg um Berge und Wasser herum, die Minikarte zeichnet ihn. Aus: Luftlinie." })
            B:Row({ type = "toggle", label = "Abfahrtszeiten teilen", key = "shareTimes",
                    description = "Gemessene Abfahrtszeiten von Schiffen, Zeppelinen und Tiefenbahn mit Gilde und Gruppe tauschen. Geteilt wird nur der Takt, nie dein Ort." },
                  { type = "toggle", label = "Route auf der Weltkarte", key = "mapRoute",
                    description = "Zeichnet den ganzen Weg auf der Weltkarte: zu Fuß dem Gelände nach, Flüge, Schiffe." })
            B:Row({ type = "dropdown", label = "Farbe der Route", key = "routeColor", items = {
                        { value = "auto",   text = "Selbst wählen (Gelb, auf Welt- und Kontinentkarte Türkis)" },
                        { value = "yellow", text = "Immer Gelb" },
                        { value = "alt",    text = "Immer Türkis" } },
                    tooltip = "Die Route hat immer eine dunkle Kontur, damit sie auch auf gelbem Grund zu sehen ist." },
                  { type = "empty" })
            B:Row({ type = "toggle", label = "Schiffslinien auf der Weltkarte", key = "mapLines",
                    description = "Schiffe und Zeppeline deiner Fraktion als gestrichelte Linien zwischen den Anlegern." },
                  { type = "toggle", label = "An Flugpunkte erinnern", key = "taxiReminder",
                    description = "Kommst du an einem Flugmeister vorbei, dessen Flugpunkt du noch nicht hast, sagt der Pfeil Bescheid – fürs spätere Reisenetz." })
            B:Section("Nach einer Quest")
            B:Row({ type = "dropdown", label = "Wenn die Ziele erfüllt sind", key = "onComplete", items = {
                        { value = "turnin", text = "Zur Abgabe führen" },
                        { value = "next",   text = "Gleich zur nächsten Quest" } } },
                  { type = "toggle", label = "Nach dem Abgeben weiter", key = "autoNext",
                    description = "Nur bei „Nur die Quest, die das Spiel verfolgt“: die nächstgelegene Quest aus deinem Questlog wird ausgewählt." })
            B:EndAdvanced()
            B:Section("So benutzt du ihn")
            B:Note("Von selbst zeigt der Pfeil auf das nächste lohnende Ziel aus deinem Questlog und plant unterwegs neu. Ein Klick auf den Pfeil öffnet die Liste deiner Quests – wähle dort, wohin er zeigen soll. Auch das runde Symbol vor einer Quest in der Zielverfolgung wählt sie. Die Wahl gilt bis zur Abgabe; eine Kartenmarkierung gilt, solange sie steht.")
            B:Note("/wcui pfeil zeigt, was zur Wahl stand. /wcui pfeil weiter lässt das jetzige Ziel zehn Minuten aus, /wcui pfeil planen gibt eine eigene Wahl wieder ab.")
            B:Note("In Dungeons nennt das Spiel Addons keine Position. Deshalb ist der Pfeil dort aus; wer ihn trotzdem will, sieht „Position unbekannt“ statt einer Zahl.")
            B:Note("„m“ ist die Spieleinheit, die der deutsche Client auch in Zauberreichweiten „Meter“ nennt. Echte Meter sind etwa 9 % weniger.")
        end },
    },
})
