--------------------------------------------------
-- WeintCodex :: Glitzern - Questgegenstaende, Kraeuter und Erz
--------------------------------------------------
-- Seit 6.29.0.0 (Wunsch des Spielers: "ForeverLootSparkles als
-- Komfortfunktion"). Nach dem VERHALTEN dieses Addons, ohne seinen Code -
-- es steht unter GPL-3.0, WeintCodex unter MIT (dieselbe Regel wie bei
-- WIM, DialogueUI, MoveAny). Uebernommen sind nur Tatsachen ueber das
-- Spiel: welche Spieleinstellungen das Glitzern steuern.
--
-- ZWEI TEILE, beide Seite "Glitzern" im Komfort, geht ohne Oberflaeche:
--
--   Questgegenstaende  Das Spiel zeigt das Glitzern auf pluenderbaren
--                      Questgegenstaenden nur ohne Umrisse. Grafikstufen
--                      schalten die Umrisse wieder an - WeintCodex setzt die
--                      Werte beim Einloggen und eine Sekunde nach jeder
--                      Grafikaenderung neu (nie im Kampf).
--   Kraeuter und Erz   Dafuer hat das Spiel kein Glitzern. Die "weiche
--                      Zielerfassung" (SoftTarget) waehlt das naechste
--                      Objekt, mit dem man interagieren kann; ist es ein
--                      Kraut oder eine Erzader (erkannt am Mauszeiger des
--                      Spiels fuer dieses Objekt), haengt WeintCodex eigene
--                      Funken an seine Plakette - golden, grau wenn du es
--                      (noch) nicht sammeln kannst.
--
-- Jede Spieleinstellung geht ueber PF.SetCVar (ui/profile.lua): der Wert von
-- vorher wird gemerkt und beim Ausschalten zurueckgegeben, wenn noch unserer
-- steht. Die Umrisse kommen erst nach einem Neustart des Spiels zurueck
-- (/reload reicht laut dem Vorbild nicht) - die Seite sagt es.
--------------------------------------------------

local K  = WeintCodex.UIKit
local C  = WeintCodex.Colors
local KEY = "comfort"

WeintCodex.UISparkles = {}
local SP = WeintCodex.UISparkles

SP.DEFAULTS = {
    sparkleLoot  = false,   -- Questgegenstaende glitzern immer
    sparkleNodes = false,   -- Kraeuter und Erz glitzern beim Naehern
}

-- Was das Glitzern auf Questgegenstaenden braucht.
SP.LOOT_CVARS = {
    outlineModeShowLootEffectWhenDisabled = "1",
    graphicsOutlineMode = "0",
    OutlineEngineMode = "0",
    raidGraphicsOutlineMode = "0",
    RAIDOutlineEngineMode = "0",
}
-- Weiche Zielerfassung fuer Objekte, mit Symbol des Spiels darueber.
SP.NODE_CVARS = {
    SoftTargetInteract = "3",
    SoftTargetInteractRange = "60",       -- das Spiel bricht bei etwa 15 m ab
    SoftTargetInteractArc = "2",
    SoftTargetInteractOnlyInRange = "0",
    SoftTargetIconInteract = "1",
    SoftTargetIconGameObject = "1",
    SoftTargetLowPriorityIcons = "1",
}
SP.GATE = "SoftTargetNameplateInteract"    -- Plakette des Objekts: nur bei Kraut/Erz an
SP.UNIT = "softinteract"
SP.TICK = 0.12
SP.TEXTURE = "Interface\\Cooldown\\star4"   -- Funke des Spiels
local stats = { looks = 0, herb = 0, ore = 0, other = 0, applied = 0, noplate = 0, bytip = 0 }
SP.stats = stats

local function PF() return WeintCodex.UIProfile end
local function Get(k) return K.Get(KEY, k) end
function SP.LootActive() return K.IsActive(KEY) and Get("sparkleLoot") and true or false end
function SP.NodesActive() return K.IsActive(KEY) and Get("sparkleNodes") and true or false end

local function SetAll(t)
    local P = PF()
    if not (P and P.SetCVar) then return 0 end
    local n = 0
    for name, value in pairs(t) do
        if not P.Same(P.GetCVar(name), value) and P.SetCVar(name, value, KEY) then n = n + 1 end
    end
    return n
end

local function ReleaseAll(t)
    local P = PF()
    if not (P and P.Release) then return end
    for name in pairs(t) do P.Release(name) end
end

--------------------------------------------------
-- Questgegenstaende
--------------------------------------------------

function SP.ApplyLoot()
    if not SP.LootActive() then return false end
    if K.InCombat() then K.AfterCombat(SP.ApplyLoot) return false end
    stats.applied = stats.applied + SetAll(SP.LOOT_CVARS)
    return true
end

local WATCH = { graphicsquality = true, raidgraphicsquality = true }
for name in pairs(SP.LOOT_CVARS) do WATCH[name:lower()] = true end
SP.WATCH = WATCH

local again = 0
local later = CreateFrame("Frame")
later:Hide()
later:SetScript("OnUpdate", WeintCodex.Measured("sparkles", function(self, el)
    again = again - (el or 0)
    if again > 0 then return end
    self:Hide()
    SP.ApplyLoot()
end))
function SP.ApplyLater(delay) again = delay or 1 later:Show() end

--------------------------------------------------
-- Kraeuter und Erz
--------------------------------------------------

-- Art des weichen Ziels aus dem Mauszeiger des Spiels: "herb", "ore",
-- "other" oder nil, und ob er ausgegraut ist ("Unable...").
local probe = UIParent:CreateTexture(nil, "BACKGROUND")
probe:Hide()
function SP.ReadCursor(name)
    if type(name) ~= "string" then return nil, false end
    name = name:lower()
    local blocked = name:find("unable", 1, true) ~= nil
    if name:find("herb", 1, true) or name:find("gather", 1, true) then return "herb", blocked end
    if name:find("mine", 1, true) then return "ore", blocked end
    return "other", blocked
end

local fileKind = {}
if _G.GetFileIDFromPath then
    for _, n in ipairs({ "GatherHerbs", "Mine", "UnableGatherHerbs", "UnableMine" }) do
        local ok, id = pcall(_G.GetFileIDFromPath, "Interface\\Cursor\\" .. n)
        id = ok and K.Plain(id) or nil
        if type(id) == "number" then fileKind[id] = n end
    end
end

-- 6.29.29.0 (Beta-Test: "Glitzern beim Kraeutern ohne Effekt"): der
-- Mauszeiger ist nicht der einzige Weg. Der Tooltip eines Krauts oder einer
-- Ader nennt den Beruf ("Kraeuterkunde"/"Bergbau", rot wenn zu niedrig).
SP.TIP_WORDS = {
    { "kräuterkunde", "herb" }, { "herbalism", "herb" },
    { "bergbau", "ore" }, { "mining", "ore" },
}
function SP.ReadTooltip(unit)
    local TI = _G.C_TooltipInfo
    if not (TI and TI.GetUnit) then return nil, false end
    local ok, data = pcall(TI.GetUnit, unit)
    if not ok or type(data) ~= "table" or type(data.lines) ~= "table" then return nil, false end
    for _, line in ipairs(data.lines) do
        local text = K.Plain(line.leftText)
        if type(text) == "string" then
            local low = text:lower()
            for _, w in ipairs(SP.TIP_WORDS) do
                if low:find(w[1], 1, true) then
                    local c = line.leftColor
                    local r = type(c) == "table" and K.Plain(c.r) or nil
                    local g = type(c) == "table" and K.Plain(c.g) or nil
                    local blocked = type(r) == "number" and type(g) == "number" and r > 0.9 and g < 0.3
                    return w[2], blocked
                end
            end
        end
    end
    return nil, false
end

function SP.Classify(unit)
    local kind, blocked = SP.ClassifyCursor(unit)
    if kind == "herb" or kind == "ore" then return kind, blocked end
    local k2, b2 = SP.ReadTooltip(unit)
    if k2 then stats.bytip = stats.bytip + 1 return k2, b2 end
    return kind, blocked
end

function SP.ClassifyCursor(unit)
    if type(_G.SetUnitCursorTexture) ~= "function" then return nil, false end
    local ok, set = pcall(_G.SetUnitCursorTexture, probe, unit, nil, true)
    if not ok or not K.Plain(set) then return nil, false end
    local tex = K.Plain(probe:GetTexture())
    if type(tex) == "number" and fileKind[tex] then return SP.ReadCursor(fileKind[tex]) end
    local kind, blocked = SP.ReadCursor(type(tex) == "string" and tex or nil)
    if kind == "other" or not kind then
        local atlas = probe.GetAtlas and K.Plain(probe:GetAtlas())
        local k2, b2 = SP.ReadCursor(type(atlas) == "string" and atlas or nil)
        if k2 and k2 ~= "other" then return k2, b2 end
    end
    return kind, blocked
end

-- Die Funken (1.0.5.66, Wunsch mit Bildern: "genauso schoen wie das
-- Glitzern von Questgebern und Gegenstaenden"). Bis hierher sechs grosse
-- Sterne an festen Plaetzen, die an- und ausgingen. Das Glitzern des Spiels
-- sieht anders aus: viele kleine, weiche Lichtpunkte, die am Boden
-- entstehen, langsam aufsteigen, leicht zur Seite treiben und verglimmen -
-- dazwischen ab und zu ein kurzes Aufblitzen. Genau so:
--   * SP.MOTES weiche Punkte (media/ui/halo, 5-10 px), jeder mit eigenem
--     Leben: Ort in einer flachen Ellipse am Boden, Steighoehe, Drift,
--     Dauer. Hell beim Entstehen, dann langsam aus; am Ende neu gewuerfelt.
--   * SP.TWINKLES kleine Sterne des Spiels, die kurz aufblitzen.
-- Ein Takt je Bild, solange die Funken zu sehen sind - ohne Tabelle oder
-- Closure je Bild; die Werte je Punkt stehen an seinem Bild.
SP.MOTES, SP.TWINKLES = 14, 4
SP.SPREAD_X, SP.SPREAD_Y = 30, 10      -- halbe Achsen der Ellipse am Boden
local glow = CreateFrame("Frame", nil, UIParent)
glow:SetSize(80, 60)
glow:Hide()
glow.dots = {}
local rnd = math.random
-- Ein Punkt beginnt sein Leben neu (age < 0 = wartet noch).
local function Reborn(t, wait)
    local a, r = rnd() * 2 * math.pi, math.sqrt(rnd())
    t.x0, t.y0 = math.cos(a) * r * SP.SPREAD_X, math.sin(a) * r * SP.SPREAD_Y
    t.age = -(wait or 0)
    if t.star then
        t.life = 0.35 + rnd() * 0.3
        t.rise, t.drift = 0, 0
        t.size = 9 + rnd() * 7
        t.y0 = t.y0 + rnd() * 18
    else
        t.life = 1.3 + rnd() * 1.2
        t.rise = 14 + rnd() * 22
        t.drift = (rnd() - 0.5) * 12
        t.size = 5 + rnd() * 5
    end
    t.peak = 0.55 + rnd() * 0.45
end
SP.Reborn = Reborn
for i = 1, SP.MOTES + SP.TWINKLES do
    local t = glow:CreateTexture(nil, "OVERLAY")
    t.star = i > SP.MOTES
    t:SetTexture(t.star and SP.TEXTURE or (K.MEDIA .. "halo"))
    if t.SetBlendMode then t:SetBlendMode("ADD") end
    t:SetAlpha(0)
    -- Gestaffelt beginnen, damit nicht alle zugleich aufsteigen.
    Reborn(t, t.star and (0.4 + rnd() * 2.5) or (rnd() * 2))
    glow.dots[i] = t
end
SP.glow = glow
-- Ein Schritt fuer einen Punkt (rein gerechnet, fuer den Ladetest): gibt
-- Lage (x, y), Deckkraft und Groesse zum Alter zurueck.
function SP.Mote(t)
    local u = t.age / t.life
    if u < 0 then return t.x0, t.y0, 0, t.size end
    if u > 1 then u = 1 end
    -- Schnell hell (erstes Fuenftel), dann lang aus.
    local alpha = u < 0.2 and (u / 0.2) or (1 - (u - 0.2) / 0.8)
    alpha = alpha * t.peak
    -- Steigt erst zuegig, dann langsamer (weiches Auslaufen).
    local e = 1 - (1 - u) * (1 - u)
    local size = t.star and t.size * (0.6 + 0.4 * math.sin(u * math.pi)) or t.size * (1 - 0.35 * u)
    return t.x0 + t.drift * e, t.y0 + t.rise * e, alpha, size
end
glow:SetScript("OnUpdate", WeintCodex.Measured("sparkles", function(self, el)
    el = el or 0
    if el > 0.1 then el = 0.1 end
    local dots = self.dots
    for i = 1, #dots do
        local t = dots[i]
        t.age = t.age + el
        if t.age >= t.life then Reborn(t, t.star and (0.6 + rnd() * 2.2) or (rnd() * 0.5)) end
        local x, y, alpha, size = SP.Mote(t)
        t:SetAlpha(alpha)
        if alpha > 0 then
            t:SetSize(size, size)
            t:SetPoint("CENTER", self, "CENTER", x, y)
        end
    end
end))

-- Warmes Weissgold wie beim Spiel; grau, wenn du es (noch) nicht sammeln
-- kannst. Sterne heller als die weichen Punkte.
local function Paint(blocked)
    local c, w = blocked and C.textMuted or C.warningBright, C.textBright
    for _, t in ipairs(glow.dots) do
        local k = blocked and 0 or (t.star and 0.7 or 0.35)   -- Anteil Weiss
        t:SetVertexColor(c[1] + (w[1] - c[1]) * k, c[2] + (w[2] - c[2]) * k, c[3] + (w[3] - c[3]) * k)
    end
end

local gate     -- was SP.GATE gerade sagt (unserer)
local function SetGate(on, force)
    if gate == on or (K.InCombat() and not force) then return end
    gate = on
    local P = PF()
    if P and P.SetCVar then P.SetCVar(SP.GATE, on and "1" or "0", KEY) end
end

-- Gibt es ein weiches Ziel? 6.35.3.1 (Beta-Test: Spitzhacke ueber der Ader,
-- aber /wcui pruefen "kein Objekt"): UnitExists sagt bei Objekten (Erz,
-- Kraut sind keine Einheiten) offenbar nein - die Kennung (UnitGUID) gibt es
-- trotzdem. Eines von beiden reicht.
function SP.HasSoft(u)
    if _G.UnitExists and K.Bool(_G.UnitExists(u), false) then return true end
    local guid = _G.UnitGUID and _G.UnitGUID(u)
    return type(guid) ~= "nil" and (type(K.Plain(guid)) ~= "string" or K.Plain(guid) ~= "")
end

-- Die Plakette des weichen Ziels. 6.35.2.0 (Beta-Test: Erz glitzert nicht,
-- obwohl an): GetNamePlateForUnit kennt nicht jede Kennung - fuer
-- "softinteract" kann es nichts liefern oder einen Fehler werfen. Dann die
-- Plaketten durchgehen und die nehmen, deren Einheit das weiche Ziel ist.
function SP.PlateFor(u)
    local NPm = _G.C_NamePlate
    if not NPm then return nil end
    if NPm.GetNamePlateForUnit then
        local ok, plate = pcall(NPm.GetNamePlateForUnit, u)
        if ok and type(plate) == "table" then return plate, "direkt" end
    end
    if NPm.GetNamePlates and _G.UnitIsUnit then
        local ok, list = pcall(NPm.GetNamePlates)
        if ok and type(list) == "table" then
            for _, plate in ipairs(list) do
                local token = type(plate) == "table" and (plate.namePlateUnitToken
                    or (plate.UnitFrame and plate.UnitFrame.unit))
                if type(token) == "string" then
                    local ok2, same = pcall(_G.UnitIsUnit, token, u)
                    if ok2 and K.Bool(same, false) then return plate, "gesucht" end
                end
            end
        end
    end
    return nil
end

-- Ein Blick: Funken an die Plakette des weichen Ziels, wenn es Kraut/Erz ist.
function SP.Look()
    if not SP.NodesActive() or K.InCombat() then glow:Hide() return nil end
    stats.looks = stats.looks + 1
    local u = SP.UNIT
    if not SP.HasSoft(u) then
        glow:Hide()
        SetGate(false)
        SP.lastGuid = nil
        return nil
    end
    -- 6.30.18.0 (Messung /wcui speicher: "Glitzern" 8,6 KB/s): dasselbe
    -- Objekt nicht bei jedem Blick neu einordnen - Mauszeiger und vor allem
    -- der Tooltip (eine grosse Tabelle) nur, wenn ein anderes davorsteht.
    local guid = _G.UnitGUID and K.Plain(_G.UnitGUID(u))
    local kind, blocked
    if type(guid) == "string" and guid == SP.lastGuid then
        kind, blocked = SP.lastKind, SP.lastBlocked
    else
        kind, blocked = SP.Classify(u)
        SP.lastGuid, SP.lastKind, SP.lastBlocked = type(guid) == "string" and guid or nil, kind, blocked
    end
    if kind == "herb" or kind == "ore" then
        stats[kind] = stats[kind] + 1
        SetGate(true)
        -- Dieselbe Plakette fuer dasselbe Objekt: nicht bei jedem Blick suchen.
        local plate = SP.lastPlateGuid == SP.lastGuid and SP.lastPlate or nil
        if not (plate and plate.IsShown and plate:IsShown()) then
            plate = SP.PlateFor(u)
            SP.lastPlate, SP.lastPlateGuid = plate, SP.lastGuid
        end
        if type(plate) == "table" then
            glow:SetParent(plate)
            glow:ClearAllPoints()
            glow:SetPoint("CENTER", plate, "CENTER", 0, -46)
            Paint(blocked)
            glow:Show()
        else
            -- Ohne Plakette (das Spiel baut sie erst nach dem Schalter):
            -- mitten auf dem Bildschirm waere falsch - im naechsten Blick.
            stats.noplate = stats.noplate + 1
            glow:Hide()
        end
        return kind
    end
    stats.other = stats.other + 1
    SetGate(false)
    glow:Hide()
    return kind
end

local acc = 0
local ticker = CreateFrame("Frame")
ticker:Hide()
ticker:SetScript("OnUpdate", K.Measured("Glitzern", function(_, el)
    acc = acc + (el or 0)
    if acc < SP.TICK then return end
    acc = 0
    SP.Look()
end))
SP.ticker = ticker

--------------------------------------------------
-- Schalten
--------------------------------------------------

function SP.Apply()
    if K.InCombat() then K.AfterCombat(SP.Apply) return end
    if SP.LootActive() then SP.ApplyLoot() else ReleaseAll(SP.LOOT_CVARS) end
    if SP.NodesActive() then
        SetAll(SP.NODE_CVARS)
        gate = nil
        ticker:Show()
    else
        ticker:Hide()
        glow:Hide()
        ReleaseAll(SP.NODE_CVARS)
        local P = PF()
        if P and P.Release then P.Release(SP.GATE) end
        gate = nil
    end
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:RegisterEvent("PLAYER_REGEN_DISABLED")
pcall(ev.RegisterEvent, ev, "CVAR_UPDATE")
ev:SetScript("OnEvent", WeintCodex.Measured("sparkles", function(_, event, name)
    if event == "PLAYER_LOGIN" then
        SP.Apply()
        SP.ApplyLater(5)
    elseif event == "PLAYER_REGEN_DISABLED" then
        -- 6.41.6.0: Plakette des weichen Ziels zu, bevor der Kampf sperrt -
        -- sonst behielt ein getoeteter Gegner (pluenderbar = weiches Ziel)
        -- bis zum Pluendern eine Plakette mit 0 % Leben. Nach dem Kampf
        -- oeffnet SP.Tick sie wieder fuer Kraut und Erz.
        glow:Hide()
        if gate then SetGate(false, true) end
    elseif SP.LootActive() and type(name) == "string" and WATCH[name:lower()] then
        SP.ApplyLater(1)
    end
end))
SP.events = ev

-- Was jetzt vor dir steht (6.30.9.0): fuer /wcui prüfen, damit ein Bericht
-- zeigt, woran Glitzern und Plakette haengen - nur Fakten.
function SP.Probe()
    local u = SP.UNIT
    if not SP.HasSoft(u) then
        local P = PF()
        local cv = P and P.GetCVar and P.GetCVar("SoftTargetInteract")
        local np = P and P.GetCVar and P.GetCVar(SP.GATE)
        return string.format("Vor dir: kein Objekt der weichen Zielerfassung (UnitExists und UnitGUID leer) · SoftTargetInteract=%s · %s=%s – direkt vor ein Kraut stellen, dann prüfen",
            tostring(cv), SP.GATE, tostring(np))
    end
    local name = _G.UnitName and K.Plain(_G.UnitName(u))
    local guid = _G.UnitGUID and K.Plain(_G.UnitGUID(u))
    local hm = _G.UnitHealthMax and K.Plain(_G.UnitHealthMax(u))
    local kindC, blC = SP.ClassifyCursor(u)
    local kindT, blT = SP.ReadTooltip(u)
    local tex = K.Plain(probe:GetTexture())
    local plate, how = SP.PlateFor(u)
    local NP = WeintCodex.UINameplates
    local ours = false
    if type(plate) == "table" and NP and NP.plates then
        for _, p in pairs(NP.plates) do if p.nameplate == plate and p:IsShown() then ours = true end end
    end
    local pw = type(plate) == "table" and K.Plain(plate:GetWidth())
    local ph = type(plate) == "table" and K.Plain(plate:GetHeight())
    return string.format("Vor dir: %s · Kennung %s · Leben %s · Mauszeiger %s (%s) · Tooltip %s · Plakette %s%s · von WeintCodex bemalt: %s",
        tostring(name), type(guid) == "string" and (guid:match("^[^%-]+") or guid) or "geheim/keine",
        tostring(hm), tostring(kindC), tostring(tex), tostring(kindT),
        type(plate) == "table" and ("da (" .. tostring(how) .. ")") or "keine",
        type(pw) == "number" and string.format(" %dx%d", pw, ph or 0) or "",
        ours and "ja" or "nein")
end

function SP.StatusLines()
    return { string.format("Glitzern: Quest %s · Kraut/Erz %s · Blicke %d · Kraut %d · Erz %d · anderes %d · über Tooltip %d · ohne Plakette %d · Werte gesetzt %d · Mauszeiger-Abfrage %s",
        SP.LootActive() and "an" or "aus", SP.NodesActive() and "an" or "aus",
        stats.looks, stats.herb, stats.ore, stats.other, stats.bytip, stats.noplate, stats.applied,
        type(_G.SetUnitCursorTexture) == "function" and "da" or "fehlt"), SP.Probe() }
end

local function Build(B)
    B:Section("Glitzern", "Nach dem Vorbild von ForeverLootSparkles, eigener Code. Was WeintCodex dafür am Spiel umstellt, bekommst du beim Ausschalten zurück.")
    B:Row({ type = "toggle", label = "Questgegenstände glitzern immer", key = "sparkleLoot",
            description = "Schaltet die Umrisse aus und das Glitzern des Spiels an – auch nach einem Wechsel der Grafikstufe. Aus: die Umrisse kommen erst nach einem Neustart des Spiels zurück." },
          { type = "toggle", label = "Kräuter und Erz glitzern", key = "sparkleNodes",
            description = "Golden über dem nächsten Kraut oder der nächsten Erzader (bis etwa 15 m), grau, wenn deine Fertigkeit noch zu niedrig ist. Nur mit Kräuterkunde bzw. Bergbau – ohne den Beruf zeigt das Spiel das Objekt nicht an. Im Kampf nicht." })
    B:Note("Kräuter und Erz nutzen die weiche Zielerfassung des Spiels. Nicht zusammen mit ForeverLootSparkles oder Lueur benutzen – sie stellen dieselben Werte um.")
end

local mod = K.Module(KEY)
if mod then
    for k, v in pairs(SP.DEFAULTS) do
        if mod.defaults[k] == nil then mod.defaults[k] = v end
    end
    mod.pages[#mod.pages + 1] = { key = "glitzern", label = "Glitzern", build = Build }
end

K.Listen(function(kind, key)
    if (kind == "active" or kind == "setting") and key == KEY then SP.Apply() end
end)
