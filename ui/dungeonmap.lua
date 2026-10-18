--------------------------------------------------
-- WeintCodex :: Komfort - Dungeonkarten (6.72.0.0)
--------------------------------------------------
-- Wunsch: "Dungeonkarten, wenn ich einen Dungeon betrete - normales
-- Verhalten wie sonst auch in WoW". Der Forever-Client zeigt in den
-- klassischen Instanzen keine Karte, obwohl die Bilder dazu in ihm liegen
-- (je Ebene 4 x 3 Kacheln zu 256 px, Bild 1002 x 668). Welche Nummern zu
-- welcher Instanz gehoeren, steht in data/dungeonmaps.lua (erzeugt, aus
-- OpenMap, MIT - siehe dort).
--
-- Verhalten: in einer Instanz, fuer die der Bestand eine Karte kennt, liegt
-- beim Oeffnen der Weltkarte (M) die Dungeonkarte ueber der Karte des
-- Spiels - wie in jeder anderen WoW-Fassung. Ebenen mit den Pfeilen oder
-- dem Mausrad, "Weltkarte" blendet sie aus, bis die Karte neu geoeffnet
-- wird. Kein eigener Punkt fuer den Spieler: in Instanzen nennt der Client
-- keine Lage.
--
-- Nie, wo das Spiel selbst eine Dungeonkarte zeigt (C_Map: Kartenart
-- Dungeon). Laesst sich eine Kachel nicht setzen (SetTexture false), bleibt
-- die Karte des Spiels - lieber keine Karte als ein gruenes Rechteck.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIDungeonMap = {}

local DM = WeintCodex.UIDungeonMap
local K = WeintCodex.UIKit
local C = WeintCodex.Colors
local KEY = "comfort"

DM.PIC_W, DM.PIC_H = 1002, 668
DM.HEAD = 30
DM.DEFAULTS = { dungeonMaps = true }

local view, hiddenFor
DM.floorOf = {}          -- [Instanz] = zuletzt gezeigte Ebene (diese Sitzung)

function DM.Active() return K.IsActive(KEY) and K.Get(KEY, "dungeonMaps") ~= false end

local function Data() return WeintCodex.DungeonMapData end

-- Die Instanz, in der der Spieler steht, und ihre Karte (oder nil).
function DM.Current()
    if not (_G.IsInInstance and _G.GetInstanceInfo) then return nil end
    local ok, inside = pcall(_G.IsInInstance)
    if not ok or not K.Bool(inside, false) then return nil end
    local id = select(8, _G.GetInstanceInfo())
    id = K.Plain(id)
    local d = Data()
    local m = type(id) == "number" and d and d.MAPS and d.MAPS[id]
    return m or nil, id
end

-- Zeigt das Spiel hier selbst eine Dungeonkarte? Dann nichts darueber legen.
function DM.GameHasMap()
    local cm = _G.C_Map
    if not (cm and cm.GetBestMapForUnit and cm.GetMapInfo) then return false end
    local ok, id = pcall(cm.GetBestMapForUnit, "player")
    id = ok and K.Plain(id) or nil
    if type(id) ~= "number" then return false end
    local ok2, info = pcall(cm.GetMapInfo, id)
    local kind = ok2 and type(info) == "table" and K.Plain(info.mapType)
    local dungeon = _G.Enum and _G.Enum.UIMapType and _G.Enum.UIMapType.Dungeon
    return type(dungeon) == "number" and kind == dungeon
end

local function Layout()
    if not (view and view:IsShown()) then return end
    local w, h = K.Plain(view.port:GetWidth()), K.Plain(view.port:GetHeight())
    if type(w) ~= "number" or type(h) ~= "number" or w <= 0 or h <= 0 then return end
    local s = math.min(w / DM.PIC_W, h / DM.PIC_H)
    view.page:SetSize(DM.PIC_W * s, DM.PIC_H * s)
    for i, t in ipairs(view.tiles) do
        local col, row = (i - 1) % 4, math.floor((i - 1) / 4)
        local tw, th = math.min(256, DM.PIC_W - col * 256), math.min(256, DM.PIC_H - row * 256)
        t:SetSize(tw * s, th * s)
        t:ClearAllPoints()
        t:SetPoint("TOPLEFT", view.page, "TOPLEFT", col * 256 * s, -row * 256 * s)
        t:SetTexCoord(0, tw / 256, 0, th / 256)
    end
end
DM.Layout = Layout

-- Ebene i zeigen. false, wenn der Client ein Bild nicht kennt.
function DM.ShowFloor(i)
    local m, id = view.map, view.inst
    local n = #m.floors
    i = ((i - 1) % n) + 1
    DM.floorOf[id] = i
    view.floor = i
    local f = m.floors[i]
    for k, t in ipairs(view.tiles) do
        local ok, res = pcall(t.SetTexture, t, f.tiles[k])
        if not ok or res == false then return false end
    end
    view.title:SetText((f.name or m.name or "Dungeon") .. (n > 1 and ("   " .. i .. " / " .. n) or ""))
    view.prev:SetShown(n > 1)
    view.next:SetShown(n > 1)
    Layout()
    return true
end

local function Button(parent, text, onClick)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(28, 22)
    local bg = b:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(b)
    local s = C.surface2 or C.surface1
    bg:SetColorTexture(s[1], s[2], s[3], 0.9)
    local hl = b:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints(b)
    hl:SetColorTexture(1, 1, 1, 0.08)
    b.text = K.NewText(b, 12)
    b.text:SetPoint("CENTER")
    b.text:SetText(text)
    b:SetScript("OnClick", onClick)
    return b
end

local function Build(wm)
    local host = type(wm.ScrollContainer) == "table" and wm.ScrollContainer or wm
    local f = CreateFrame("Frame", "WeintCodexDungeonMap", host)
    f:SetAllPoints(host)
    f:SetFrameLevel((K.Plain(host:GetFrameLevel()) or 1) + 40)
    f:EnableMouse(true)
    f:EnableMouseWheel(true)
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(f)
    local s0 = C.surface0 or C.surface1
    bg:SetColorTexture(s0[1], s0[2], s0[3], 1)

    f.port = CreateFrame("Frame", nil, f)
    f.port:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -DM.HEAD)
    f.port:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
    f.page = CreateFrame("Frame", nil, f.port)
    f.page:SetPoint("CENTER")
    f.tiles = {}
    for i = 1, 12 do f.tiles[i] = f.page:CreateTexture(nil, "ARTWORK") end

    f.title = K.NewText(f, 13)
    f.title:SetPoint("TOP", f, "TOP", 0, -8)
    local t = C.textBright or C.textNormal
    f.title:SetTextColor(t[1], t[2], t[3])
    f.prev = Button(f, "<", function() DM.ShowFloor(view.floor - 1) end)
    f.prev:SetPoint("RIGHT", f.title, "LEFT", -12, 0)
    f.next = Button(f, ">", function() DM.ShowFloor(view.floor + 1) end)
    f.next:SetPoint("LEFT", f.title, "RIGHT", 12, 0)
    f.world = Button(f, "Weltkarte", function() hiddenFor = view.inst f:Hide() end)
    f.world:SetSize(84, 22)
    f.world:SetPoint("TOPRIGHT", f, "TOPRIGHT", -8, -4)

    f:SetScript("OnMouseWheel", function(_, delta) DM.ShowFloor(view.floor + (delta > 0 and -1 or 1)) end)
    f:SetScript("OnSizeChanged", Layout)
    f:SetScript("OnShow", Layout)
    f:Hide()
    return f
end

-- Beim Oeffnen der Weltkarte: zeigen oder nicht.
function DM.Refresh()
    local wm = _G.WorldMapFrame
    if type(wm) ~= "table" then return false end
    local m, id = nil, nil
    if DM.Active() and not DM.GameHasMap() then m, id = DM.Current() end
    if not m or hiddenFor == id then
        if view then view:Hide() end
        return false
    end
    view = view or Build(wm)
    DM.view = view
    view.map, view.inst = m, id
    view:Show()
    if not DM.ShowFloor(DM.floorOf[id] or 1) then
        view:Hide()
        DM.missing = id
        return false
    end
    return true
end

function DM.Hook()
    local wm = _G.WorldMapFrame
    if DM._hooked or type(wm) ~= "table" or not wm.HookScript then return end
    DM._hooked = true
    wm:HookScript("OnShow", function() pcall(DM.Refresh) end)
    wm:HookScript("OnHide", function() hiddenFor = nil end)
end

local ev = CreateFrame("Frame")
DM.events = ev
for _, e in ipairs({ "PLAYER_LOGIN", "ADDON_LOADED", "PLAYER_ENTERING_WORLD" }) do pcall(ev.RegisterEvent, ev, e) end
ev:SetScript("OnEvent", function(_, event)
    DM.Hook()
    if event == "PLAYER_ENTERING_WORLD" then
        hiddenFor = nil
        local wm = _G.WorldMapFrame
        if type(wm) == "table" and wm.IsShown and wm:IsShown() then pcall(DM.Refresh) end
    end
end)

-- Zeile auf der Seite "Karte" im Komfort (ui/mapentrances.lua ruft sie).
function DM.BuildRows(B)
    B:Row({ type = "toggle", label = "Dungeonkarten", key = "dungeonMaps",
            description = "In den klassischen Dungeons und Schlachtzügen zeigt die Weltkarte (M) die Karte der Instanz, mit Ebenen. Die Bilder liegen im Spiel; welche Karte zu welcher Instanz gehört, ist unbestätigt." },
          { type = "empty" })
end

local mod = K.Module(KEY)
if mod then
    for k, v in pairs(DM.DEFAULTS) do
        if mod.defaults[k] == nil then mod.defaults[k] = v end
    end
end
