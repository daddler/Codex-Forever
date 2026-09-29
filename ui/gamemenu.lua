--------------------------------------------------
-- WeintCodex :: Oberflaeche - Spielmenue (6.7.9.0)
--------------------------------------------------
-- Das Spielmenue (Esc, GameMenuFrame) in der ruhigen
-- Informationsoberflaeche. Es gehoert nicht zur Klasse: Gold (S.CALM), wie
-- Berufe, Gilde und die Dialoge des Spiels (ui/windows.lua, W.SkinPopup).
-- Seit 6.6.3.3 traegt es die Kachel und flache Knoepfe; neu:
--
--   Grund     statt des Scheins in der Klassenfarbe (W.HoldGlow: in einem
--             Fenster in Gold aus) ein Hauch neutrales Licht von oben und
--             oben eine feine Kante in Gold - wie die Karten der Register.
--   Titel     unter "Spielmenue" eine Linie mit Raute in Gold.
--   Gruppen   das Menue ordnet seine Knoepfe in Gruppen (Optionen | Addons
--             ... Makros | Ausloggen, Spiel verlassen | Zurueck zum Spiel)
--             mit einer Luecke dazwischen. In jeder Luecke eine Haarlinie
--             wie zwischen den Eintraegen einer Liste - gemessen je
--             Durchlauf an der Lage der Knoepfe, keine Liste von Namen.
--
-- Nichts am Menue wird bewegt, kein Skript, kein Feld: Ausloggen, Beenden
-- und der Bearbeitungsmodus laufen darueber (siehe W.EXTRA_DECOR).
--
-- GEMESSEN (6.7.8.0, /wcui fenster): GameMenuFrame, nur noch unsere
-- Flaechen sichtbar ("FileData ID 0"); Rahmen und Kopf seit 6.6.3.3 weg.
-- UNGEMESSEN: wo der Titel steht (.Header.Text wie im Quelltext des
-- Spiels, sonst die oberste Schriftzeile des Kopfes).
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIGameMenu = {}

local GM = WeintCodex.UIGameMenu
local GC = WeintCodex.GameColors
local W = WeintCodex.UIWindows
local S = WeintCodex.UIStyle
local RG = WeintCodex.UIRegister

local Visible, Kind, IsFrame, Edge = RG.Visible, RG.Kind, RG.IsFrame, RG.Edge

GM.LABEL = "Spielmenü"
GM.HOST = "GameMenuFrame"
GM.STYLE = S.CALM
GM.LIGHT_HEIGHT = 110
GM.EDGE = 0.5               -- Kante oben in Gold
GM.UNDER = 6                -- Linie so weit unter dem Titel
GM.INSET = 14               -- Linien so weit vom Rand
GM.GAP = 6                  -- groessere Luecke zwischen Knoepfen = neue Gruppe
GM.MAX_LINES = 6            -- so viele Gruppen hat das Menue hoechstens

S.SCOPES[GM.HOST] = GM.STYLE
W.HOSTED[GM.HOST] = W.HOSTED[GM.HOST] or {}
table.insert(W.HOSTED[GM.HOST], GM)

local menus = setmetatable({}, { __mode = "k" })
GM.menus = menus

local function Title(f)
    local h = f.Header
    if not IsFrame(h) then return nil end
    local t = h.Text
    if IsFrame(t) and Kind(t) == "FontString" then return t end
    return (RG.Topmost(h, 0, nil, nil))
end

local function Build(f)
    local accent = S.Accent(GM.STYLE.accent)
    local m = { lines = {} }
    local l = GC.atmosLight
    m.light = S.TopLight(f, f, l, l[4], GM.LIGHT_HEIGHT, -5)
    m.edge = S.Under(S.Divider(f, accent, GM.EDGE, 0), -3)
    S.PlaceTop(m.edge, f, 10, -1)
    m.orn = S.Ornament(f, accent, 0.45)
    for _, t in ipairs(m.orn.parts) do t:Hide() end
    local h = GC.hairline
    for i = 1, GM.MAX_LINES do
        local d = S.Under(S.Divider(f, h, h[4] * 2, 0), 1)
        d.l:Hide()
        d.r:Hide()
        m.lines[i] = d
    end
    menus[f] = m
    return m
end

-- Knoepfe des Menues, die gerade zu sehen sind.
local function IsMenuButton(ch)
    return IsFrame(ch) and Kind(ch) == "Button" and Visible(ch)
end

-- Unterkante von `b` und Oberkante des naechsten Knopfs darunter.
local function NextBelow(f, bottom)
    local best
    for _, c in ipairs(W.Children(f, "gmInner")) do
        if IsMenuButton(c) then
            local t = Edge(c, "GetTop")
            if t and t <= bottom + 1 and (not best or t > best) then best = t end
        end
    end
    return best
end

function GM.Update(f)
    local m = menus[f] or Build(f)
    local top = Edge(f, "GetTop")
    if not top then return m end
    -- Titel: Linie mit Raute darunter.
    local title = Title(f)
    local tb = title and Edge(title, "GetBottom")
    local y = tb and math.floor(tb - top - GM.UNDER + 0.5) or false
    if m.y ~= y then
        m.y = y
        if y then S.PlaceOrnament(m.orn, f, GM.INSET, y) end
        for _, t in ipairs(m.orn.parts) do t:SetShown(y and true or false) end
    end
    -- Gruppen: in jeder groesseren Luecke eine Haarlinie.
    local n = 0
    for _, b in ipairs(W.Children(f, "gmOuter")) do
        if n >= GM.MAX_LINES then break end
        if IsMenuButton(b) then
            local bottom = Edge(b, "GetBottom")
            local below = bottom and NextBelow(f, bottom)
            if below and bottom - below > GM.GAP then
                n = n + 1
                local ly = math.floor((bottom + below) / 2 - top + 0.5)
                local d = m.lines[n]
                if d.y ~= ly then
                    d.y = ly
                    S.PlaceTop(d, f, GM.INSET, ly)
                end
                if not d.on then
                    d.on = true
                    d.l:Show()
                    d.r:Show()
                end
            end
        end
    end
    for i = n + 1, GM.MAX_LINES do
        local d = m.lines[i]
        if d.on then
            d.on = false
            d.l:Hide()
            d.r:Hide()
        end
    end
    m.groups = n
    return m
end

function GM.Report(f, out)
    local m = menus[f]
    if not m then return out end
    out[#out + 1] = string.format("   %s (Stil %s): Titel %s, Trennlinien %d, Kante in Gold",
        GM.LABEL, GM.STYLE.name, m.y and "gefunden" or "FEHLT", m.groups or 0)
    return out
end
