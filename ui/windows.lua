--------------------------------------------------
-- WeintCodex :: Oberflaeche - Fenster des Spiels
--------------------------------------------------
-- Das Charakterfenster (Taste C) mit seinen Reitern Ruf, Fertigkeiten,
-- PvP und Abzeichen im Stil der Oberflaeche (Beta-Test: "auch hier soll
-- das neue Design Einheit gebieten"): Kachel statt Holz und Metall, ohne
-- das runde Portraet, der Titel in unserer Schrift.
--
-- ERSTE STUFE (6.3.1.6) WAR NUR DIE HUELLE; die zweite (6.3.1.7, unten)
-- blendet im Inneren aus, was /wcui fenster im Beta-Test benannt hat.
-- Urspruenglich: Wie die Fenster dieses Clients
-- innen aufgebaut sind, hat niemand gemessen. Ausgeblendet werden deshalb
-- nur Teile, die in der Fenstervorlage des Spiels Schmuck sind
-- (NineSlice, Bg, Inset, Portraet) - nie Inhalte: Plaetze, Balken,
-- Listen und Modell bleiben unberuehrt. Was danach noch nach Holz
-- aussieht, nennt /wcui fenster (Maus ueber das Fenster).
--
-- Nur Aussehen, nur Deckkraft: nichts wird versteckt, umgehaengt oder
-- verschoben. Die Einstellung liegt beim Modul "general" (Seite
-- "Fenster"), wie der Tooltip - die Seitenleiste ist voll.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIWindows = {}

local W = WeintCodex.UIWindows
local K = WeintCodex.UIKit
local C = WeintCodex.Colors

W.DEFAULTS = {
    windowSkin = true,
}

local function Opt(k) return K.Get("general", k) end

-- Fenster und ihre Teilfenster. Was der Client nicht kennt, faellt heraus.
W.WINDOWS = { "CharacterFrame", "PVPFrame", "HonorFrame" }
W.PANELS  = { "PaperDollFrame", "ReputationFrame", "SkillFrame", "TokenFrame", "PVPFrame", "HonorFrame",
              "CharacterStatsPane" }

-- Schmuck in der Fenstervorlage des Spiels, als Schluessel am Rahmen.
local DECOR = { "NineSlice", "Bg", "Background", "TopTileStreaks", "Inset", "InsetBg",
                "PortraitContainer", "PortraitFrame", "portrait", "TitleBg", "TopBorder" }

local done = {}
W.done = done

-- Was die zweite Stufe tut, fuer /wcui fenster (6.3.1.8: im Beta-Test
-- blieb 6.3.1.7 ohne sichtbare Wirkung, und ohne Zahlen ist nicht zu
-- unterscheiden, ob sie nicht lief, nichts fand oder das Spiel die
-- Deckkraft zuruecksetzt).
local stats = { runs = 0, hidden = 0, stuck = 0, last = nil, err = nil }
W.stats = stats

local function Hide(r)
    if type(r) ~= "table" or not r.SetAlpha or (r.IsForbidden and r:IsForbidden()) then return end
    local AB = WeintCodex.UIActionBars
    if AB and AB.KeepHidden then AB.KeepHidden(r) else r:SetAlpha(0) end
    if K.Plain(r:GetAlpha()) ~= 0 then stats.stuck = stats.stuck + 1 end
end

-- Alle Texturen direkt an einem Rahmen (nicht an seinen Kindern).
local function HideOwnTextures(f)
    if type(f) ~= "table" or not f.GetRegions then return end
    local ok, regions = pcall(function() return { f:GetRegions() } end)
    for _, r in ipairs(ok and regions or {}) do
        local tok, isTex = pcall(function() return r:GetObjectType() == "Texture" end)
        if tok and isTex then Hide(r) end
    end
end

-- Ein Schmuckteil: ist es ein Rahmen, seine Texturen (und die seiner
-- NineSlice); ist es eine Textur, sie selbst.
local function HideDecor(part)
    if type(part) ~= "table" then return end
    local ok, kind = pcall(function() return part:GetObjectType() end)
    if not ok then return end
    if kind == "Texture" then
        Hide(part)
    else
        HideOwnTextures(part)
        if type(part.NineSlice) == "table" then HideOwnTextures(part.NineSlice) end
        if type(part.Bg) == "table" then Hide(part.Bg) end
        if type(part.portrait) == "table" then Hide(part.portrait) end
    end
end

local function HideDecorOf(f)
    for _, key in ipairs(DECOR) do HideDecor(f[key]) end
    local name = f.GetName and f:GetName()
    if type(name) == "string" then
        for _, suffix in ipairs({ "Bg", "Inset", "InsetRight", "InsetLeft", "Portrait", "TitleBg" }) do
            HideDecor(_G[name .. suffix])
        end
    end
end

local function StyleTitle(f)
    local title = (type(f.TitleContainer) == "table" and f.TitleContainer.TitleText) or f.TitleText
        or (f.GetName and f:GetName() and _G[f:GetName() .. "TitleText"])
    if type(title) == "table" and title.SetTextColor then
        K.SetFont(title, 13)
        title:SetTextColor(unpack(C.textBright))
    end
end

-- Ein Fenster: Schmuck weg, eine Kachel darunter, Titel in unserer
-- Schrift. `panel` = Teilfenster in einem anderen Fenster: keine eigene
-- Kachel, nur der Schmuck weg.
function W.Skin(f, panel)
    if type(f) ~= "table" or done[f] or (f.IsForbidden and f:IsForbidden()) then return done[f] end
    local d = {}
    done[f] = d
    HideDecorOf(f)
    if not panel then
        HideOwnTextures(f)
        d.kachel = K.Kachel(f, { alpha = 0.94, shadow = 8 })
        StyleTitle(f)
    end
    -- Innenflaechen (Inset): etwas heller als die Kachel, damit Spalten
    -- lesbar getrennt bleiben.
    for _, key in ipairs({ "Inset", "InsetRight", "InsetLeft" }) do
        local inset = f[key]
        if type(inset) ~= "table" and f.GetName and f:GetName() then inset = _G[f:GetName() .. key] end
        if type(inset) == "table" and inset.CreateTexture and not d[key] then
            local t = inset:CreateTexture(nil, "BACKGROUND", nil, -8)
            t:SetAllPoints(inset)
            local s = C.surface1
            t:SetColorTexture(s[1], s[2], s[3], 0.45)
            d[key] = t
        end
    end
    return d
end

--------------------------------------------------
-- Zweite Stufe: das Innere, nach Namen (6.3.1.7)
--------------------------------------------------
-- /wcui fenster im Beta-Test nannte, was im Charakterfenster nach Holz
-- und Stein aussieht - alles Atlanten des Spiels mit sprechenden Namen.
-- Ausgeblendet wird genau das, jeweils als Muster (Klassenhintergrund:
-- "UI-Character-Info-Warrior-BG" gibt es je Klasse). Der Hintergrund der
-- Modellszene (RaceBG) bleibt: er ist die Buehne des Modells, kein Rahmen.
W.HIDE_ATLAS = {
    "^UI%-Character%-Info%-General%-BG",     -- linke Haelfte
    "^UI%-Character%-Info%-Stat%-BG",        -- rechte Haelfte
    "^UI%-Character%-Info%-Stat%-StoneBG",
    "^UI%-Character%-Info%-%a+%-BG$",        -- Klassenhintergrund der Werte
    "^UI%-Character%-Info%-Title",           -- Holzbalken "Allgemein" usw.
    "^UI%-Character%-Info%-Line%-Bounce",    -- Streifen hinter den Werten
    "^UI%-Character%-Info%-GearSlot",        -- Metallrahmen der Plaetze
    "^UI%-Character%-Info%-Divider",
    "^UI%-Character%-Info%-ScrollLine",      -- Linien ueber/unter Listen
    "^common%-insideframe",
    "^common%-framedivider",                 -- senkrechte Trennlinie
    "^common%-stat%-bar%-BG",                -- Rahmen der Ruf-/Fertigkeitsbalken
    "^common%-sidetab",                      -- Goldrahmen der Reiter rechts
}
local KEEP_ATLAS = { "RaceBG" }

function W.HidesAtlas(atlas)
    if type(atlas) ~= "string" then return false end
    for _, k in ipairs(KEEP_ATLAS) do
        if atlas:find(k, 1, true) then return false end
    end
    for _, pat in ipairs(W.HIDE_ATLAS) do
        if atlas:find(pat) then return true end
    end
    return false
end

-- Alle Texturen mit einem dieser Atlanten, bis in die Tiefe. Zeilen einer
-- Liste legt das Spiel beim Blaettern neu an - deshalb laeuft das bei
-- jedem Zeigen und, solange das Fenster offen ist, zweimal je Sekunde.
-- Balken in Ruf und Fertigkeiten: statt des Rahmens des Spiels ein
-- flacher Grund mit 1 px Rand, wie jeder Balken der Oberflaeche.
local barDone = {}
local function FlatBar(bar)
    if type(bar) ~= "table" or barDone[bar] or not bar.CreateTexture then return end
    barDone[bar] = true
    local bg = bar:CreateTexture(nil, "BACKGROUND", nil, -8)
    bg:SetAllPoints(bar)
    local c = WeintCodex.GameColors.plateBg
    bg:SetColorTexture(c[1], c[2], c[3], 1)
    K.Border(bar, 1, 0, 0, 0, 1, "OVERLAY")
end

local seen = setmetatable({}, { __mode = "k" })
local function HideByAtlas(f, depth)
    if depth > 8 or type(f) ~= "table" or (f.IsForbidden and f:IsForbidden()) then return end
    local rok, regions = pcall(function() return { f:GetRegions() } end)
    for _, r in ipairs(rok and regions or {}) do
        local ok, atlas = pcall(function()
            if r:GetObjectType() ~= "Texture" then return nil end
            return r.GetAtlas and r:GetAtlas()
        end)
        if ok and W.HidesAtlas(atlas) then
            Hide(r)
            if not seen[r] then
                seen[r] = true
                stats.hidden = stats.hidden + 1
            end
            if atlas:find("^common%-stat%-bar%-BG") then FlatBar(f) end
        end
    end
    local cok, kids = pcall(function() return { f:GetChildren() } end)
    for _, ch in ipairs(cok and kids or {}) do HideByAtlas(ch, depth + 1) end
end
W.HideByAtlas = function(f) HideByAtlas(f, 0) end

-- Ausruestungsplaetze: flach wie die Aktionsknoepfe, 1 px schwarzer Rand.
-- Erkannt am Namen (Character...Slot), nicht an einer Liste: welche Plaetze
-- es gibt, sagt der Client.
local slotDone = {}
local function SkinSlots(f)
    local ok, kids = pcall(function() return { f:GetChildren() } end)
    for _, ch in ipairs(ok and kids or {}) do
        local n = type(ch) == "table" and ch.GetName and ch:GetName()
        if type(n) == "string" and n:find("^Character[%a%d]+Slot$") and not slotDone[ch] then
            slotDone[ch] = true
            local normal = ch.GetNormalTexture and ch:GetNormalTexture()
            if type(normal) == "table" then Hide(normal) end
            K.Border(ch, 1, 0, 0, 0, 1, "OVERLAY")
        end
        if type(ch) == "table" then SkinSlots(ch) end
    end
end
W.SkinSlots = SkinSlots

-- Die Reiter rechts am Charakterfenster (CharacterFrameModeTab1..):
-- eine kleine Kachel statt des Goldrahmens, der gewaehlte mit Rand im
-- Akzent, unter der Maus heller.
local tabDone = {}
local function SkinModeTabs()
    for i = 1, 10 do
        local tab = _G["CharacterFrameModeTab" .. i]
        if type(tab) == "table" and not (tab.IsForbidden and tab:IsForbidden()) then
            local d = tabDone[tab]
            if not d then
                d = { kachel = K.Kachel(tab, { shadow = 3 }) }
                local hl = tab:CreateTexture(nil, "HIGHLIGHT")
                hl:SetAllPoints(tab)
                local h = WeintCodex.GameColors.hoverFill
                hl:SetColorTexture(h[1], h[2], h[3], h[4])
                tabDone[tab] = d
            end
            local sel = tab.SelectedTexture
            local on = type(sel) == "table" and sel.IsShown and K.Bool(sel:IsShown(), false)
            local c = on and C.accent or { 0, 0, 0 }
            d.kachel.border:SetColor(c[1], c[2], c[3], 1)
        end
    end
end
W.SkinModeTabs = SkinModeTabs

function W.Inner()
    stats.runs = stats.runs + 1
    stats.last = _G.GetTime and K.Plain(_G.GetTime()) or nil
    for _, n in ipairs(W.WINDOWS) do
        local f = _G[n]
        if type(f) == "table" and done[f] then
            HideByAtlas(f, 0)
            SkinSlots(f)
        end
    end
    SkinModeTabs()
end

function W.Status()
    local now = _G.GetTime and K.Plain(_G.GetTime()) or nil
    local ago = (type(now) == "number" and type(stats.last) == "number") and string.format("vor %d s", now - stats.last) or "nie"
    return string.format("Fenster-Stil %s · innen: %d Läufe (zuletzt %s), %d Bilder ausgeblendet, %d ohne Wirkung%s",
        Opt("windowSkin") and "an" or "aus", stats.runs, ago, stats.hidden, stats.stuck,
        stats.err and (" · Fehler: " .. tostring(stats.err)) or "")
end

function W.Apply()
    if not Opt("windowSkin") then return end
    for _, n in ipairs(W.WINDOWS) do
        local f = _G[n]
        -- Ein Teilfenster eines schon gestalteten Fensters bekommt keine
        -- zweite Kachel.
        local parent = type(f) == "table" and f.GetParent and f:GetParent()
        W.Skin(f, parent and done[parent] and true or false)
    end
    for _, n in ipairs(W.PANELS) do
        local f = _G[n]
        if type(f) == "table" and not done[f] then W.Skin(f, true) end
    end
    W.Inner()
end

-- Die Fenster legt das Spiel beim Anmelden an; manche Teilfenster erst
-- beim ersten Oeffnen. Deshalb auch bei jedem Zeigen des Charakterfensters.
local boot = CreateFrame("Frame")
boot:RegisterEvent("PLAYER_LOGIN")
boot:SetScript("OnEvent", function()
    if not K.UIEnabled() or not Opt("windowSkin") then return end
    local ok, err = pcall(W.Apply)
    if not ok then stats.err = err K.Report("fenster", err) end
    local cf = _G.CharacterFrame
    if type(cf) == "table" and cf.HookScript then
        cf:HookScript("OnShow", function()
            local ok2, err2 = pcall(W.Apply)
            if not ok2 then stats.err = err2 K.Report("fenster", err2) end
        end)
        -- Solange es offen ist: neue Zeilen (Blaettern, Reiterwechsel)
        -- zweimal je Sekunde nachziehen. Geschlossen laeuft nichts.
        -- Ein eigener Kindrahmen, kein Skript am Fenster des Spiels: er
        -- laeuft nur, solange das Fenster sichtbar ist.
        local watch = CreateFrame("Frame", nil, cf)
        local acc = 0
        watch:SetScript("OnUpdate", function(_, elapsed)
            acc = acc + (elapsed or 0)
            if acc < 0.5 then return end
            acc = 0
            local ok3, err3 = pcall(W.Inner)
            if not ok3 then stats.err = err3 K.Report("fenster", err3) end
        end)
    end
end)
