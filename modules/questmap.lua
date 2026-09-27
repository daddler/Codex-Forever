--------------------------------------------------
-- WeintCodex :: Questgeber auf der Weltkarte
--------------------------------------------------
-- Seit 6.5.1.0: ein Klick im Dungeonkompendium oeffnet die Weltkarte
-- auf der Zone des Questgebers und setzt dort eine Marke.
--
-- EIGENE MARKE, KEIN WEGPUNKT DES SPIELS. C_Map.SetUserWaypoint gibt es
-- im Beta-Client, laut Beta-Berichten setzt es aber nicht verlaesslich
-- einen Punkt. Die Marke ist deshalb ein eigener Rahmen auf der Flaeche
-- der Weltkarte (GetCanvas), dessen Lage wir selbst rechnen: Flaeche und
-- Marke haengen am Zoom, die Marke gleicht ihn aus und bleibt gleich gross.
-- Wir schreiben nichts in Rahmen des Spiels (Taint); die Marke und ihr
-- Taktgeber sind eigene Rahmen, ihr Zustand steht hier.
--
-- Die Marke zeigt nur auf der Karte, fuer die sie gesetzt ist. Wechselt
-- der Spieler die Zone, verschwindet sie und kommt beim Zurueckwechseln
-- wieder. Rechtsklick auf die Marke entfernt sie.
--
-- ZURUECK ZUM CODEX (6.5.1.2, Beta-Test: "die Karte bleibt hinter dem
-- WeintCodex"): der Codex geht beim Klick zu, auf der Karte steht ein
-- Knopf, der die Karte schliesst und den Codex auf derselben Seite
-- wieder oeffnet - fuer den naechsten Questgeber. Der Knopf zeigt sich
-- nur, wenn die Karte aus dem Codex geoeffnet wurde; schliesst der
-- Spieler die Karte anders (M, Esc), ist er beim naechsten Mal weg.
--
-- Die Lagen stehen in data/dungeon_journal.lua (J.PLACES) und sind
-- `community` - die Marke sagt das im Tooltip.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.QuestMap = {}

local QM = WeintCodex.QuestMap
local C  = WeintCodex.Colors

local target      -- { map, x, y, who, item, quest }
local pin, driver, back
local fromCodex = false

local function Say(text)
    print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " " .. text)
end

local function Plain(v)
    local K = WeintCodex.UIKit
    if K and K.Plain then return K.Plain(v) end
    return v
end

local function Canvas()
    local wm = _G.WorldMapFrame
    if type(wm) ~= "table" then return nil end
    if type(wm.GetCanvas) == "function" then
        local ok, c = pcall(wm.GetCanvas, wm)
        if ok and type(c) == "table" then return c end
    end
    local sc = wm.ScrollContainer
    if type(sc) == "table" then return sc.Child or sc end
    return nil
end

-- Name der Zone, wie der Client ihn nennt (deutsch auf deutschem Client).
function QM.MapName(mapID)
    local cm = _G.C_Map
    if cm and cm.GetMapInfo then
        local ok, info = pcall(cm.GetMapInfo, mapID)
        if ok and type(info) == "table" and type(info.name) == "string" and info.name ~= "" then
            return info.name
        end
    end
    return nil
end

local function CurrentMap()
    local wm = _G.WorldMapFrame
    if type(wm) ~= "table" or type(wm.GetMapID) ~= "function" then return nil end
    local ok, id = pcall(wm.GetMapID, wm)
    id = ok and Plain(id) or nil
    return type(id) == "number" and id or nil
end

local function BuildPin(canvas)
    pin = CreateFrame("Button", "WeintCodexQuestMapPin", canvas)
    pin:SetSize(22, 22)
    pin:EnableMouse(true)
    if pin.RegisterForClicks then pin:RegisterForClicks("LeftButtonUp", "RightButtonUp") end
    -- Gezeichnet, keine Grafik des Spiels: dunkler Rand, Akzent innen,
    -- als Raute gedreht - hebt sich von Pergament und Gelaende ab.
    local rim = pin:CreateTexture(nil, "ARTWORK", nil, 1)
    rim:SetSize(18, 18)
    rim:SetPoint("CENTER")
    rim:SetColorTexture(C.bgPanel[1], C.bgPanel[2], C.bgPanel[3], 1)
    local fill = pin:CreateTexture(nil, "ARTWORK", nil, 2)
    fill:SetSize(13, 13)
    fill:SetPoint("CENTER")
    fill:SetColorTexture(C.accentBright[1], C.accentBright[2], C.accentBright[3], 1)
    local dot = pin:CreateTexture(nil, "ARTWORK", nil, 3)
    dot:SetSize(4, 4)
    dot:SetPoint("CENTER")
    dot:SetColorTexture(C.textBright[1], C.textBright[2], C.textBright[3], 1)
    for _, t in ipairs({ rim, fill, dot }) do
        if t.SetRotation then pcall(t.SetRotation, t, math.pi / 4) end
    end
    pin.label = WeintCodex.Label(pin, "", { size = 12, color = "textBright",
        font = WeintCodex.Fonts and WeintCodex.Fonts.sansSemi })
    pin.label:SetPoint("TOP", pin, "BOTTOM", 0, -1)
    if pin.label.SetShadowOffset then
        pin.label:SetShadowOffset(1, -1)
        pin.label:SetShadowColor(C.bgPanel[1], C.bgPanel[2], C.bgPanel[3], 1)
    end

    pin:SetScript("OnClick", function(_, button)
        if button == "RightButton" then QM.Clear() end
    end)
    pin:SetScript("OnEnter", function(self)
        local gt = _G.GameTooltip
        if not (gt and target) then return end
        gt:SetOwner(self, "ANCHOR_RIGHT")
        gt:SetText(target.who, C.textBright[1], C.textBright[2], C.textBright[3])
        local what = target.line or (target.quest and ((target.item and "Fundort für: " or "Beginnt: ") .. target.quest))
        if what then
            gt:AddLine(what, C.textNormal[1], C.textNormal[2], C.textNormal[3], true)
        end
        gt:AddLine("Lage aus Beta-Berichten – unbestätigt.", C.textMuted[1], C.textMuted[2], C.textMuted[3], true)
        gt:AddLine("Rechtsklick: Marke entfernen", C.textMuted[1], C.textMuted[2], C.textMuted[3])
        gt:Show()
    end)
    pin:SetScript("OnLeave", function()
        if _G.GameTooltip then _G.GameTooltip:Hide() end
    end)
    pin:Hide()
end

-- Marke an ihre Stelle. Die Flaeche der Karte ist beim Zoomen skaliert;
-- die Marke nimmt den Kehrwert, damit sie gleich gross bleibt, und
-- rechnet ihren Abstand in ihre eigene Skala um.
function QM.Place()
    local wm = _G.WorldMapFrame
    if not target or type(wm) ~= "table" or not (wm.IsShown and wm:IsShown()) then
        if pin then pin:Hide() end
        return false
    end
    if CurrentMap() ~= target.map then
        if pin then pin:Hide() end
        return false
    end
    local canvas = Canvas()
    if not canvas then return false end
    if not pin then BuildPin(canvas) end
    if pin:GetParent() ~= canvas then pin:SetParent(canvas) end
    local w, h = Plain(canvas:GetWidth()), Plain(canvas:GetHeight())
    if type(w) ~= "number" or type(h) ~= "number" or w <= 1 or h <= 1 then return false end
    local s = 1
    local cs = Plain(canvas.GetEffectiveScale and canvas:GetEffectiveScale())
    local ms = Plain(wm.GetEffectiveScale and wm:GetEffectiveScale())
    if type(cs) == "number" and type(ms) == "number" and cs > 0 and ms > 0 then s = cs / ms end
    pin:SetScale(1 / s)
    local lvl = Plain(canvas.GetFrameLevel and canvas:GetFrameLevel())
    pin:SetFrameLevel(math.min(9000, (type(lvl) == "number" and lvl or 0) + 2000))
    pin:ClearAllPoints()
    pin:SetPoint("CENTER", canvas, "TOPLEFT", w * target.x * s, -h * target.y * s)
    pin.label:SetText(target.who)
    pin:Show()
    return true
end

-- Karte zu, Codex auf - auf der Seite, auf der er zuging.
function QM.Back()
    fromCodex = false
    if back then back:Hide() end
    local wm = _G.WorldMapFrame
    if type(wm) == "table" and wm.IsShown and wm:IsShown() then
        local ok = type(_G.HideUIPanel) == "function" and pcall(_G.HideUIPanel, wm)
        if not ok or wm:IsShown() then pcall(wm.Hide, wm) end
    end
    local main = WeintCodex.MainFrame
    if type(main) == "table" and main.Show then main:Show() end
end

local function EnsureBack()
    if back then return back end
    local wm = _G.WorldMapFrame
    if type(wm) ~= "table" then return nil end
    back = WeintCodex.CreateButton(wm, { kind = "primary", text = "Zurück zum Codex",
        height = 30, radius = 0, onClick = function() QM.Back() end })
    local area = wm.ScrollContainer or wm
    back:SetPoint("TOPLEFT", area, "TOPLEFT", 12, -12)
    local lvl = Plain(wm.GetFrameLevel and wm:GetFrameLevel())
    back:SetFrameLevel(math.min(9500, (type(lvl) == "number" and lvl or 0) + 3000))
    back:Hide()
    return back
end
QM.BackButton = function() return back end

-- Taktgeber als Kind der Weltkarte: laeuft nur, solange sie offen ist.
local function EnsureDriver()
    if driver then return end
    local wm = _G.WorldMapFrame
    if type(wm) ~= "table" then return end
    driver = CreateFrame("Frame", nil, wm)
    -- Karte anders geschlossen (M, Esc): kein Rueckweg mehr anbieten.
    driver:SetScript("OnHide", function()
        fromCodex = false
        if back then back:Hide() end
    end)
    local acc = 0
    driver:SetScript("OnUpdate", function(_, el)
        acc = acc + (el or 0)
        if acc < 0.05 then return end
        acc = 0
        QM.Place()
    end)
end

local function OpenMap(mapID)
    local wm = _G.WorldMapFrame
    if type(wm) ~= "table" then return false end
    if not (wm.IsShown and wm:IsShown()) then
        if type(_G.OpenWorldMap) == "function" then
            pcall(_G.OpenWorldMap, mapID)
        elseif _G.C_Map and type(_G.C_Map.OpenWorldMap) == "function" then
            pcall(_G.C_Map.OpenWorldMap, mapID)
        elseif type(_G.ShowUIPanel) == "function" then
            pcall(_G.ShowUIPanel, wm)
        end
    end
    if type(wm.SetMapID) == "function" then pcall(wm.SetMapID, wm, mapID) end
    return wm.IsShown and wm:IsShown() and true or false
end

-- Weltkarte auf der Zone oeffnen und die Marke setzen. `place` aus
-- J.PLACES, `questName` fuer Tooltip und Meldung.
-- `line` ersetzt die Zeile "Beginnt: <Quest>" im Tooltip der Marke
-- (Lehrer: "Lehrt: Dolche").
function QM.Show(place, questName, line)
    if type(place) ~= "table" or type(place.map) ~= "number" then return false end
    target = { map = place.map, x = place.x, y = place.y, who = place.who,
               item = place.item, quest = questName, line = line }
    EnsureDriver()
    -- Der Codex liegt ueber der Karte: er geht zu, der Knopf holt ihn zurueck.
    local main = WeintCodex.MainFrame
    local codexOpen = type(main) == "table" and main.IsShown and main:IsShown()
    local opened = OpenMap(place.map)
    if opened and codexOpen then
        main:Hide()
        fromCodex = true
        local b = EnsureBack()
        if b then b:Show() end
    end
    -- Das Spiel stellt beim Oeffnen kurz die zuletzt gezeigte Zone wieder
    -- her; ein paar Takte lang die Zone nachsetzen.
    if _G.C_Timer and _G.C_Timer.After then
        for _, d in ipairs({ 0.05, 0.15, 0.3, 0.6 }) do
            _G.C_Timer.After(d, function()
                if not target or target.map ~= place.map then return end
                local wm = _G.WorldMapFrame
                if CurrentMap() ~= place.map and type(wm) == "table" and type(wm.SetMapID) == "function" then
                    pcall(wm.SetMapID, wm, place.map)
                end
                QM.Place()
            end)
        end
    end
    QM.Place()
    local zone = QM.MapName(place.map)
    if opened then
        Say("Auf der Karte: " .. place.who .. (zone and (" (" .. zone .. ")") or "")
            .. ". Rechtsklick auf die Marke entfernt sie" .. (fromCodex and ", „Zurück zum Codex“ oben links auf der Karte bringt dich zurück." or "."))
    else
        Say("Die Weltkarte ließ sich nicht öffnen – die Marke steht auf der Karte, sobald du sie öffnest ("
            .. (zone or "Zone " .. place.map) .. ").")
    end
    return true
end

function QM.Clear()
    target = nil
    if pin then pin:Hide() end
    if _G.GameTooltip then _G.GameTooltip:Hide() end
end

function QM.Target() return target end
function QM.FromCodex() return fromCodex end
function QM.Pin() return pin end
