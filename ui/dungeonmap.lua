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
DM.DEFAULTS = { dungeonMaps = true, dungeonPinSize = 100 }
-- 1.0.8.20 (Wunsch: "auf den Dungeon Maps genau positioniert die Bosse; mit
-- Rechtsklick ins Dungeonjournal von Codex"): Bosspunkte aus
-- data/dungeonpins.lua (Tabellen des Spiels, nur auf denselben Bildern).
DM.pinList = {}     -- Bosspunkte (Knoepfe), wiederverwendet
DM.PIN = 26              -- Groesse eines Bosspunkts bei 100 %
-- Ueber Karten anderer Addons (die ihre Dungeonkarte bis Ebene 9200 legen).
DM.LEVEL = 9300

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

-- /wcui dungeonkarte (1.0.6.10): was sagt der Client in dieser Instanz ueber
-- Ort und Position? Nur gelesen. Gebraucht fuer zwei offene Fragen: gibt das
-- Spiel in (alten) Dungeons eine Position auf der Karte heraus, und welche
-- Unterzonen meldet es je Ebene? Messen statt raten.
local function Ask(fn, ...)
    if type(fn) ~= "function" then return "gibt es nicht" end
    local r = { pcall(fn, ...) }
    if not r[1] then return "Fehler: " .. tostring(r[2]) end
    local out = {}
    for i = 2, 9 do
        local v = r[i]
        if K.IsSecret(v) then out[#out + 1] = "geheim"
        elseif type(v) == "nil" then out[#out + 1] = "nil"
        elseif type(v) == "table" then out[#out + 1] = "Tabelle"
        else out[#out + 1] = tostring(v) end
    end
    while #out > 1 and out[#out] == "nil" do out[#out] = nil end
    return table.concat(out, ", ")
end
DM.Ask = Ask

function DM.Probe()
    local G, cm = _G, _G.C_Map
    local lines = {}
    local function add(k, v) lines[#lines + 1] = k .. ": " .. v end
    add("In einer Instanz", Ask(G.IsInInstance))
    add("Instanz (Name, Art, …, Nummer an 8. Stelle)", Ask(G.GetInstanceInfo))
    local m, id = DM.Current()
    add("Karte im Codex", m and ((m.name or "?") .. ", " .. #m.floors .. " Ebene(n)" .. (m.drawn and ", Zeichnung" or ", aus dem Client"))
        or ("keine für Nummer " .. tostring(id)))
    add("Gebiet", Ask(G.GetRealZoneText))
    add("Zone", Ask(G.GetZoneText))
    add("Unterzone", Ask(G.GetSubZoneText))
    add("Minikarte", Ask(G.GetMinimapZoneText))
    local best
    if cm and cm.GetBestMapForUnit then
        local ok, v = pcall(cm.GetBestMapForUnit, "player")
        best = ok and K.Plain(v) or nil
    end
    add("Karte des Spiels (Nummer)", type(best) == "number" and tostring(best) or "keine")
    if type(best) == "number" and cm.GetMapInfo then
        local ok, info = pcall(cm.GetMapInfo, best)
        if ok and type(info) == "table" then
            add("Karte des Spiels", tostring(K.Plain(info.name)) .. ", Art " .. tostring(K.Plain(info.mapType))
                .. ", darüber " .. tostring(K.Plain(info.parentMapID)))
        end
        local ok2, pos = pcall(cm.GetPlayerMapPosition, best, "player")
        if not ok2 then add("Position auf der Karte", "Fehler: " .. tostring(pos))
        elseif K.IsSecret(pos) then add("Position auf der Karte", "geheim")
        elseif type(pos) == "nil" then add("Position auf der Karte", "keine (nil)")
        else
            local okp, x, y = pcall(pos.GetXY, pos)
            x, y = okp and K.Plain(x) or nil, okp and K.Plain(y) or nil
            add("Position auf der Karte", (type(x) == "number" and type(y) == "number")
                and string.format("%.4f, %.4f", x, y) or "nicht lesbar")
        end
        add("Kartengruppe (Ebenen)", Ask(cm.GetMapGroupID, best))
    end
    add("Position in der Welt (y, x, z, Instanz)", Ask(G.UnitPosition, "player"))
    add("Blickrichtung", Ask(G.GetPlayerFacing))
    add("Spiel zeigt hier selbst eine Dungeonkarte", DM.GameHasMap() and "ja" or "nein")
    return lines
end

local function Layout()
    if not (view and view:IsShown()) then return end
    local w, h = K.Plain(view.port:GetWidth()), K.Plain(view.port:GetHeight())
    if type(w) ~= "number" or type(h) ~= "number" or w <= 0 or h <= 0 then return end
    local fl = view.map and view.floor and view.map.floors[view.floor]
    if fl and fl.files then
        -- 1.0.5.38: gezeichnete Karte, 1024 breit, in zwei Bildern (512 + 256 Zeilen).
        local ph = fl.h or 684
        local s = math.min(w / 1024, (h - 16) / ph)
        view.page:SetSize(1024 * s, ph * s)
        local a, b = view.tiles[1], view.tiles[2]
        a:SetSize(1024 * s, 512 * s)
        a:ClearAllPoints()
        a:SetPoint("TOPLEFT", view.page, "TOPLEFT", 0, 0)
        a:SetTexCoord(0, 1, 0, 1)
        b:SetSize(1024 * s, (ph - 512) * s)
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", view.page, "TOPLEFT", 0, -512 * s)
        b:SetTexCoord(0, 1, 0, (ph - 512) / 256)
        for _, p in ipairs(DM.pinList) do p:Hide() end
        return
    end
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
    if DM.PlacePins then DM.PlacePins() end
end
DM.Layout = Layout

-- Bosspunkte der Instanz je Ebene: { { dungeon, boss, Ebene, x, y }, ... }.
function DM.Pins(inst, floor)
    local all = WeintCodex.DungeonPins
    local out = {}
    for _, p in ipairs(type(all) == "table" and all[inst] or {}) do
        if p[3] == floor then out[#out + 1] = p end
    end
    return out
end

-- Der Boss im Codex (Name, Reihenfolge) oder nil.
function DM.Boss(dungeonId, bossId)
    local D = WeintCodex.DungeonData
    local d = D and D.Get and D.Get(dungeonId)
    for _, b in ipairs(d and d.bosses or {}) do
        if b.id == bossId then return b, d end
    end
    return nil
end

-- Rechtsklick: Codex auf diesem Boss.
function DM.OpenBoss(dungeonId, bossId)
    local CL = WeintCodex.UICodexLinks
    local function pre()
        local DP = WeintCodex.DungeonPages
        if DP and DP.Select then DP.Select(dungeonId, bossId) end
    end
    if CL and CL.Open then return CL.Open("dungeons", pre) end
    return false
end

local function PinSize()
    local v = tonumber(K.Get(KEY, "dungeonPinSize"))
    if not v then v = DM.DEFAULTS.dungeonPinSize end
    return math.max(0, math.min(150, v)) / 100
end
DM.PinSize = PinSize

local function Pin(i)
    local b = DM.pinList[i]
    if b then return b end
    b = CreateFrame("Button", nil, view.page)
    b:RegisterForClicks("RightButtonUp", "LeftButtonUp")
    local gold = (WeintCodex.GameColors or {}).frameAccent or { 0.76, 0.64, 0.44, 1 }
    b.ring = b:CreateTexture(nil, "ARTWORK")
    b.ring:SetAllPoints(b)
    b.ring:SetTexture(K.MEDIA .. "disc_hd")
    b.ring:SetVertexColor(gold[1], gold[2], gold[3], 1)
    b.disc = b:CreateTexture(nil, "ARTWORK", nil, 1)
    b.disc:SetPoint("TOPLEFT", b, "TOPLEFT", 3, -3)
    b.disc:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -3, 3)
    b.disc:SetTexture(K.MEDIA .. "disc_hd")
    local s0 = C.surface0 or C.surface1
    b.disc:SetVertexColor(s0[1], s0[2], s0[3], 1)
    b.num = K.NewText(b, 11)
    b.num:SetPoint("CENTER", b, "CENTER", 0, 0)
    b.num:SetTextColor(gold[1], gold[2], gold[3], 1)
    b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(self.label or "?", 1, 1, 1)
        GameTooltip:AddLine("Rechtsklick: im Codex öffnen", 0.7, 0.7, 0.75)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    b:SetScript("OnClick", function(self, button)
        if button == "RightButton" then DM.OpenBoss(self.dungeon, self.boss) end
    end)
    DM.pinList[i] = b
    return b
end

-- Bosspunkte der gezeigten Ebene setzen (nur auf Bildern des Clients).
function DM.PlacePins()
    if not view then return 0 end
    for _, b in ipairs(DM.pinList) do b:Hide() end
    local fl = view.map and view.floor and view.map.floors[view.floor]
    local scale = PinSize()
    if not fl or fl.files or scale <= 0 then return 0 end
    local w, h = K.Plain(view.page:GetWidth()), K.Plain(view.page:GetHeight())
    if type(w) ~= "number" or type(h) ~= "number" or w <= 0 or h <= 0 then return 0 end
    local n = 0
    for _, p in ipairs(DM.Pins(view.inst, view.floor)) do
        local boss = DM.Boss(p[1], p[2])
        if boss then
            n = n + 1
            local b = Pin(n)
            local size = math.floor(DM.PIN * scale + 0.5)
            b:SetSize(size, size)
            b:ClearAllPoints()
            b.x, b.y = p[4] * w, -p[5] * h
            b:SetPoint("CENTER", view.page, "TOPLEFT", b.x, b.y)
            b.dungeon, b.boss, b.label = p[1], p[2], boss.name
            b.num:SetText(boss.order and tostring(boss.order) or "")
            b.num:SetShown(scale >= 0.7)
            b:SetFrameLevel((K.Plain(view.page:GetFrameLevel()) or 1) + 5)
            b:Show()
        end
    end
    return n
end

-- Ebene i zeigen. false, wenn der Client ein Bild nicht kennt.
function DM.ShowFloor(i)
    local m, id = view.map, view.inst
    local n = #m.floors
    i = ((i - 1) % n) + 1
    DM.floorOf[id] = i
    view.floor = i
    local f = m.floors[i]
    local list = f.files or f.tiles
    for k, t in ipairs(view.tiles) do
        if list[k] then
            local ok, res = pcall(t.SetTexture, t, list[k])
            if not ok or res == false then return false end
            t:Show()
        else
            t:Hide()
        end
    end
    -- Nennung des Zeichners (Bedingung seiner Erlaubnis) unter der Karte.
    view.credit:SetText(f.credit or "")
    view.credit:SetShown(f.credit and true or false)
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
    f:SetFrameLevel(math.max((K.Plain(host:GetFrameLevel()) or 1) + 40, DM.LEVEL))
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

    f.credit = K.NewText(f, 10)
    f.credit:SetPoint("BOTTOM", f, "BOTTOM", 0, 4)
    local mt = C.textMuted or C.textNormal
    f.credit:SetTextColor(mt[1], mt[2], mt[3])
    f.credit:Hide()

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
ev:SetScript("OnEvent", WeintCodex.Measured("Dungeonkarten", function(_, event)
    DM.Hook()
    if event == "PLAYER_ENTERING_WORLD" then
        hiddenFor = nil
        local wm = _G.WorldMapFrame
        if type(wm) == "table" and wm.IsShown and wm:IsShown() then pcall(DM.Refresh) end
    end
end))

-- Zeile auf der Seite "Karte" im Komfort (ui/mapentrances.lua ruft sie).
function DM.BuildRows(B)
    B:Row({ type = "toggle", label = "Dungeonkarten", key = "dungeonMaps",
            description = "In Dungeons und Schlachtzügen zeigt die Weltkarte (M) die Karte der Instanz, mit Ebenen. Klassische Instanzen: Bilder aus dem Spiel. Neue Dungeons: Zeichnungen von Santiago Reyes (Atlas de Azeroth: Forever)." },
          { type = "slider", label = "Bosse auf der Karte", key = "dungeonPinSize", min = 0, max = 150, step = 10,
            format = function(v) return v == 0 and "aus" or string.format("%d %%", v) end,
            description = "Größe der Bosspunkte auf der Dungeonkarte. Rechtsklick auf einen Boss öffnet ihn im Codex." })
end

local mod = K.Module(KEY)
if mod then
    for k, v in pairs(DM.DEFAULTS) do
        if mod.defaults[k] == nil then mod.defaults[k] = v end
    end
end

-- Groesse der Bosspunkte geaendert: sofort neu setzen.
K.Listen(function(kind, moduleKey)
    if kind == "setting" and moduleKey == KEY and view and view:IsShown() then pcall(DM.PlacePins) end
end)
