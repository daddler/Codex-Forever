--------------------------------------------------
-- WeintCodex :: Stufen und Sammelberufe auf der Weltkarte
--------------------------------------------------
-- Seit 6.26.5.0 (Beta-Test: "einsehen, welcher Levelbereich das Land ist und
-- welche Berufe dort am besten ausgeuebt werden koennen wie Angeln,
-- Kraeuter, Erze"). Seite "Karte" im Komfort, geht ohne Oberflaeche.
--
-- WAS: unten links auf der Karte eine Tafel mit Stufenbereich, Angeln ab,
-- Kraeutern und Erzen des Gebiets. Auf der Zonenkarte fuer die Zone, auf
-- dem Kontinent fuer die Zone unter der Maus.
--
-- WOHER: data/zoneinfo.lua - aus Classic, fuer die neuen Gebiete
-- unbestaetigt. Das sagt die Tafel in jeder Zeile darunter; nie steht dort
-- ein Wert, den der Bestand nicht kennt (kein "Angeln ab 0").
--
-- WIE: ein eigener Rahmen am Bildausschnitt der Karte (nicht an der
-- Flaeche: er soll beim Zoomen nicht wachsen), nie AddDataProvider, nie in
-- die Karte des Spiels geschrieben. Ein Takt, nur solange die Karte offen
-- ist, nur bei anderer Karte oder anderer Zone unter der Maus neu gesetzt.
--------------------------------------------------

local K = WeintCodex.UIKit
local C = WeintCodex.Colors
local KEY = "comfort"

WeintCodex.UIZoneInfo = {}
local ZI = WeintCodex.UIZoneInfo

ZI.DEFAULTS = { mapZoneInfo = true }
ZI.TICK = 0.15
ZI.WIDTH = 300
ZI.CONTINENT = 2         -- Enum.UIMapType.Continent

function ZI.Active() return K.IsActive(KEY) and K.Get(KEY, "mapZoneInfo") and true or false end
local function Data() return WeintCodex.ZoneInfoData or {} end
ZI.KIND = { classic = "Stand aus Classic", community = "Wissensstand aus der Beta – unbestätigt" }

function ZI.Info(mapID) return type(mapID) == "number" and Data()[mapID] or nil end

-- Farbe des Stufenbereichs fuer die eigene Stufe: zu hoch rot, passend
-- gelb/gruen, darunter grau. Ohne Stufe neutral.
function ZI.LevelColor(lvl, me)
    if type(me) ~= "number" or type(lvl) ~= "table" then return C.textBright end
    if me < lvl[1] - 2 then return C.danger or { 1, 0.3, 0.3 } end
    if me <= lvl[2] then return C.success or { 0.3, 1, 0.3 } end
    return C.textMuted
end

-- Zeilen fuer ein Gebiet: { text, Farbe }. Nur, was der Bestand kennt.
function ZI.Lines(mapID, name, out)
    out = out or {}
    for i = #out, 1, -1 do out[i] = nil end
    local d = ZI.Info(mapID)
    if not d then return out end
    local me = _G.UnitLevel and K.Plain(_G.UnitLevel("player"))
    local head = name or "?"
    if d.lvl then
        local range = d.lvl[1] == d.lvl[2] and tostring(d.lvl[1]) or (d.lvl[1] .. "–" .. d.lvl[2])
        out[#out + 1] = { head .. " · Stufe " .. range, ZI.LevelColor(d.lvl, me) }
    else
        out[#out + 1] = { head, C.textBright }
    end
    if d.fish then
        local min, safe = d.fish:match("^(%d+)%s*%((%d+)%)$")
        out[#out + 1] = { min and ("Angeln ab " .. min .. ", sicher ab " .. safe) or ("Angeln ab " .. d.fish), C.textNormal }
    end
    if d.herbs then out[#out + 1] = { "Kräuter: " .. d.herbs, C.textNormal } end
    if d.ore then out[#out + 1] = { "Erz: " .. d.ore, C.textNormal } end
    out[#out + 1] = { ZI.KIND[d.kind] or ZI.KIND.community, C.textMuted }
    return out
end

local panel, texts
local lines = {}

local function Build(parent)
    panel = CreateFrame("Frame", nil, parent)
    panel:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 8, 28)
    panel:SetWidth(ZI.WIDTH)
    panel:SetFrameLevel((parent.GetFrameLevel and parent:GetFrameLevel() or 1) + 20)
    local bg = panel:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(panel)
    local s = C.surface1 or C.surface2
    bg:SetColorTexture(s[1], s[2], s[3], 0.82)
    texts = {}
    for i = 1, 6 do
        local fs = K.NewText(panel, i == 1 and 12 or 10)
        fs:SetJustifyH("LEFT")
        fs:SetWidth(ZI.WIDTH - 16)
        if fs.SetWordWrap then fs:SetWordWrap(true) end
        texts[i] = fs
    end
    panel:Hide()
    ZI.panel = panel
end

local function Show(mapID, name)
    ZI.Lines(mapID, name, lines)
    if #lines == 0 then panel:Hide() return false end
    local y, prev = 8, nil
    for i, fs in ipairs(texts) do
        local l = lines[i]
        fs:ClearAllPoints()
        if l then
            if prev then fs:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -3)
            else fs:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -8) end
            fs:SetText(l[1])
            fs:SetTextColor(l[2][1], l[2][2], l[2][3])
            fs:Show()
            local h = fs.GetStringHeight and K.Plain(fs:GetStringHeight())
            y = y + ((type(h) == "number" and h > 0) and h or 12) + 3
            prev = fs
        else
            fs:Hide()
        end
    end
    panel:SetHeight(y + 5)
    panel:Show()
    return true
end

-- Welche Karte die Tafel gerade zeigen soll: die Zone selbst, auf dem
-- Kontinent die Zone unter der Maus.
function ZI.Target(mapID)
    local cm = _G.C_Map
    if not (cm and cm.GetMapInfo) then return mapID end
    local ok, info = pcall(cm.GetMapInfo, mapID)
    if not (ok and type(info) == "table" and K.Plain(info.mapType) == ZI.CONTINENT) then return mapID end
    local wm = _G.WorldMapFrame
    local sc = wm and wm.ScrollContainer
    if not (sc and sc.IsMouseOver and sc:IsMouseOver() and sc.GetNormalizedCursorPosition and cm.GetMapInfoAtPosition) then
        return nil
    end
    local x, y = sc:GetNormalizedCursorPosition()
    local ok2, at = pcall(cm.GetMapInfoAtPosition, mapID, x, y)
    local id = ok2 and type(at) == "table" and K.Plain(at.mapID)
    return type(id) == "number" and id ~= mapID and id or nil
end

local shown = false
function ZI.Update()
    local wm = _G.WorldMapFrame
    if not (ZI.Active() and type(wm) == "table" and wm.IsShown and wm:IsShown()) then
        if panel then panel:Hide() end
        shown = false
        return false
    end
    local qm = WeintCodex.QuestMap
    local mapID = qm and qm.CurrentMap and qm.CurrentMap()
    local target = mapID and ZI.Target(mapID)
    if not panel then
        local parent = wm.ScrollContainer or wm
        Build(parent)
    end
    if target == shown then return panel:IsShown() end
    shown = target
    if not target then panel:Hide() return false end
    local name = (qm and qm.MapName and qm.MapName(target)) or nil
    return Show(target, name)
end

local ticker = CreateFrame("Frame")
ticker:Hide()
local acc = 0
ticker:SetScript("OnUpdate", K.Measured("Karte: Gebiete", function(_, el)
    acc = acc + (el or 0)
    if acc < ZI.TICK then return end
    acc = 0
    ZI.Update()
end))
ZI.ticker = ticker

local hooked = false
local function Apply()
    local wm = _G.WorldMapFrame
    if not hooked and type(wm) == "table" and wm.HookScript then
        hooked = true
        wm:HookScript("OnShow", function() if ZI.Active() then shown = false acc = ZI.TICK ticker:Show() end end)
        wm:HookScript("OnHide", function() ticker:Hide() if panel then panel:Hide() end shown = false end)
    end
    if ZI.Active() and type(wm) == "table" and wm.IsShown and wm:IsShown() then
        shown = false
        ticker:Show()
    else
        ticker:Hide()
        if panel then panel:Hide() end
    end
end
ZI.Apply = Apply

function ZI.BuildRows(B)
    B:Row({ type = "toggle", label = "Stufen und Sammelberufe der Gebiete", key = "mapZoneInfo",
            description = "Unten links auf der Karte: Stufenbereich, Angeln ab, Kräuter und Erze. Auf dem Kontinent für die Zone unter der Maus." })
end

local mod = K.Module(KEY)
if mod then
    for k, v in pairs(ZI.DEFAULTS) do
        if mod.defaults[k] == nil then mod.defaults[k] = v end
    end
end

K.Listen(function(kind, key)
    if (kind == "active" or kind == "setting") and key == KEY then Apply() end
end)

local boot = CreateFrame("Frame")
boot:RegisterEvent("PLAYER_LOGIN")
boot:SetScript("OnEvent", function() Apply() end)
ZI.boot = boot
