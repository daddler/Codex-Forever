--------------------------------------------------
-- WeintCodex :: Stufe 60 - Feuerwerk und Begruessung (1.0.10.0)
--------------------------------------------------
-- Wunsch: "Wenn man Level 60 erreicht hat, soll es ein kleines Feuerwerk
-- auf dem Monitor geben" und "mit Level 60 wird man abgeholt".
--
-- FEUERWERK. Sechs Raketen steigen nacheinander von unten auf, abwechselnd
-- links und rechts, platzen oben in je 48 Funken (Farben der Palette: Gold, Akzent = Klassenfarbe,
-- Gruen, Blau, Weiss, Rot), die Funken fallen mit Schwerkraft, werden
-- langsamer, funkeln zum Schluss und verblassen. Die Begruessung kommt nach
-- 2,6 s in die Mitte oben, wo keine Rakete platzt. Etwa fuenf Sekunden, dann ist alles weg. Nur
-- eigene Bilder (der runde Fleck media/ui/disc, additiv gemischt), keine
-- Grafik des Spiels; nimmt keine Maus, liegt ueber allem.
-- Die Bahn jedes Teils ist eine Formel der Zeit seit dem Start - der Takt
-- legt keine Tabellen an, die Teile werden einmal gebaut und wiederverwendet.
--
-- BEGRUESSUNG. Beim Aufstieg auf die Hoechststufe: Feuerwerk und ein Kasten
-- "Stufe 60!" mit dem Knopf "Endgame öffnen". Wer schon 60 ist, bekommt den
-- Kasten einmal je Charakter beim ersten Einloggen mit dieser Fassung (ohne
-- Feuerwerk). Gemerkt in WeintCodex_SavedData.endgame.greeted.
-- /wc feuerwerk spielt es zum Ansehen ab.
--------------------------------------------------

WeintCodex.Fireworks = {}
local FW = WeintCodex.Fireworks
local C = WeintCodex.Colors

FW.TEX = "Interface\\AddOns\\WeintCodex\\media\\ui\\disc"
FW.ROCKETS = 6
FW.SPARKS = 48
FW.TRAIL = 5
FW.RISE = 0.9          -- s bis zum Platzen
FW.LIFE = 1.9          -- s, die ein Funke lebt
FW.GRAVITY = 170       -- px/s^2
FW.DRAG = 1.6          -- Abbremsen der Funken (1/s)
FW.SPEED = { 210, 360 } -- px/s beim Platzen
FW.SPARK = 13          -- px, Groesse eines Funkens beim Platzen
FW.TOAST_DELAY = 2.6   -- s: die Begruessung kommt, wenn die ersten Raketen verglueht sind
FW.LAUNCH = { 0, 0.45, 0.9, 1.35, 1.8, 2.3 }
FW.COLORS = { "gold", "accent", "successBright", "infoBright", "textBright", "dangerBright" }
FW.DURATION = 2.3 + FW.RISE + FW.LIFE + 0.2

local host
local rockets = {}
FW.rockets = rockets
local elapsed = 0

local function Tex(parent, size)
    local t = parent:CreateTexture(nil, "OVERLAY")
    t:SetTexture(FW.TEX)
    if t.SetBlendMode then t:SetBlendMode("ADD") end
    t:SetSize(size, size)
    t:Hide()
    return t
end

local function Build()
    if host then return host end
    host = CreateFrame("Frame", "WeintCodexFireworks", UIParent)
    host:SetAllPoints(UIParent)
    host:SetFrameStrata("FULLSCREEN_DIALOG")
    host:EnableMouse(false)
    host:Hide()
    for i = 1, FW.ROCKETS do
        local r = { head = Tex(host, 10), flash = Tex(host, 90), trail = {}, sparks = {} }
        for j = 1, FW.TRAIL do r.trail[j] = Tex(host, 7) end
        for j = 1, FW.SPARKS do
            r.sparks[j] = Tex(host, FW.SPARK)
            r.sparks[j].phase = j * 1.7
        end
        rockets[i] = r
    end
    host:SetScript("OnUpdate", function(_, el) FW.Step(el or 0) end)
    return host
end

-- Neue Bahnen fuer alle Raketen (Zufall nur hier, nicht je Bild).
function FW.Plan(w, h)
    for i, r in ipairs(rockets) do
        r.t0 = FW.LAUNCH[i] + math.random() * 0.15
        -- abwechselnd links und rechts: die Mitte oben gehoert der Begruessung
        local left = i % 2 == 1
        r.x = w * ((left and 0.08 or 0.62) + 0.30 * math.random())
        r.top = h * (0.55 + 0.28 * math.random())
        local c = C[FW.COLORS[(i - 1) % #FW.COLORS + 1]] or C.gold
        r.cr, r.cg, r.cb = c[1], c[2], c[3]
        for j, s in ipairs(r.sparks) do
            local a = (j - 1) / FW.SPARKS * 2 * math.pi + (math.random() - 0.5) * 0.25
            local v = FW.SPEED[1] + (FW.SPEED[2] - FW.SPEED[1]) * math.random()
            s.vx, s.vy = math.cos(a) * v, math.sin(a) * v
            s.life = FW.LIFE * (0.75 + 0.25 * math.random())
        end
    end
end

-- Hoehe der Rakete beim Aufstieg (bremst zum Gipfel hin ab).
function FW.RiseY(r, a)
    local k = math.min(1, a / FW.RISE)
    return r.top * (1 - (1 - k) * (1 - k))
end

-- Lage eines Funkens a Sekunden nach dem Platzen, relativ zum Gipfel.
function FW.SparkPos(s, a)
    local f = (1 - math.exp(-FW.DRAG * a)) / FW.DRAG
    return s.vx * f, s.vy * f - 0.5 * FW.GRAVITY * a * a
end

local function Place(t, x, y, size, alpha, r, g, b)
    t:ClearAllPoints()
    t:SetPoint("CENTER", host, "BOTTOMLEFT", x, y)
    t:SetSize(size, size)
    t:SetVertexColor(r, g, b, alpha)
    t:Show()
end

function FW.Step(el)
    elapsed = elapsed + el
    if elapsed >= FW.DURATION then FW.Stop() return end
    for _, r in ipairs(rockets) do
        local a = elapsed - r.t0
        r.head:Hide() r.flash:Hide()
        for _, t in ipairs(r.trail) do t:Hide() end
        if a >= 0 and a < FW.RISE then
            local y = FW.RiseY(r, a)
            local hc = C.textBright
            Place(r.head, r.x, y, 10, 1, hc[1], hc[2], hc[3])
            for j, t in ipairs(r.trail) do
                local b = a - j * 0.035
                if b > 0 then
                    Place(t, r.x + (math.random() - 0.5) * 3, FW.RiseY(r, b), 8 - j, 0.7 - j * 0.12, r.cr, r.cg, r.cb)
                end
            end
        end
        local b = a - FW.RISE
        if b >= 0 and b < 0.3 then
            Place(r.flash, r.x, r.top, 90 + b * 220, 0.7 * (1 - b / 0.3), r.cr, r.cg, r.cb)
        end
        for _, s in ipairs(r.sparks) do
            if b >= 0 and b < s.life then
                local dx, dy = FW.SparkPos(s, b)
                local k = b / s.life
                -- im letzten Drittel funkeln die Funken (flackern)
                local tw = k > 0.6 and (0.55 + 0.45 * math.sin(b * 28 + s.phase)) or 1
                Place(s, r.x + dx, r.top + dy, FW.SPARK * (1 - 0.6 * k), ((1 - k) ^ 1.4 + 0.05) * tw, r.cr, r.cg, r.cb)
            else
                s:Hide()
            end
        end
    end
end

function FW.Play()
    Build()
    local w = UIParent:GetWidth() or 1920
    local h = UIParent:GetHeight() or 1080
    FW.Plan(type(w) == "number" and w or 1920, type(h) == "number" and h or 1080)
    elapsed = 0
    host:Show()
    FW.playing = true
    return true
end

function FW.Stop()
    if not host then return end
    host:Hide()
    for _, r in ipairs(rockets) do
        r.head:Hide() r.flash:Hide()
        for _, t in ipairs(r.trail) do t:Hide() end
        for _, s in ipairs(r.sparks) do s:Hide() end
    end
    FW.playing = false
end

--------------------------------------------------
-- Begruessung
--------------------------------------------------

FW.MAX_LEVEL = 60
function FW.MaxLevel()
    local f = _G.GetMaxPlayerLevel
    if type(f) == "function" then
        local ok, v = pcall(f)
        local K = WeintCodex.UIKit
        v = ok and (K and K.Plain and K.Plain(v) or v) or nil
        if type(v) == "number" and v > 0 then return v end
    end
    return FW.MAX_LEVEL
end

local function Store()
    local sv = _G.WeintCodex_SavedData
    if type(sv) ~= "table" then return nil end   -- nie in eine Ersatztabelle
    local e = sv.endgame
    if type(e) ~= "table" then e = {} sv.endgame = e end
    e.greeted = type(e.greeted) == "table" and e.greeted or {}
    return e
end
FW.Store = Store

local function Me()
    local n = _G.UnitName and _G.UnitName("player")
    local r = _G.GetRealmName and _G.GetRealmName()
    if type(n) ~= "string" then return nil end
    return n .. "-" .. (type(r) == "string" and r or "?")
end

local toast
local function Toast()
    if toast then return toast end
    local f = WeintCodex.CreateSurface(UIParent, { tone = "plain", radius = 14, backdrop = "bgDark" })
    f:SetSize(420, 150)
    f:SetPoint("TOP", UIParent, "TOP", 0, -150)
    f:SetFrameStrata("DIALOG")
    f:EnableMouse(true)
    f.title = WeintCodex.Label(f, "Stufe 60!", { size = 20, color = "gold" })
    f.title:SetPoint("TOPLEFT", f, "TOPLEFT", 20, -18)
    f.text = WeintCodex.Label(f, "", { size = 12, color = "textNormal", width = 380 })
    f.text:SetPoint("TOPLEFT", f.title, "BOTTOMLEFT", 0, -8)
    f.open = WeintCodex.CreateButton(f, { text = "Endgame öffnen", kind = "primary", height = 30,
        onClick = function() FW.HideToast() FW.OpenEndgame() end })
    f.open:SetWidth(170)
    f.open:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 20, 16)
    f.later = WeintCodex.CreateButton(f, { text = "Später", kind = "secondary", height = 30,
        onClick = function() FW.HideToast() end })
    f.later:SetWidth(110)
    f.later:SetPoint("LEFT", f.open, "RIGHT", 10, 0)
    f:Hide()
    toast = f
    FW.toast = f
    return f
end

FW.TOAST_TEXT = "Willkommen im Endgame. Was jetzt geht – Einstimmungen, Tier 0 und 0.5, die Dungeons ab 55 und dein Ruf – steht im Codex unter „Endgame“, mit dem nächsten Schritt ganz oben."
FW.TOAST_SECONDS = 60

function FW.ShowToast()
    local f = Toast()
    f.text:SetText(FW.TOAST_TEXT)
    f.shownAt = _G.GetTime and _G.GetTime() or 0
    f:Show()
    if _G.C_Timer and _G.C_Timer.After then
        local at = f.shownAt
        _G.C_Timer.After(FW.TOAST_SECONDS, function() if toast and toast.shownAt == at then FW.HideToast() end end)
    end
    return f
end

function FW.HideToast() if toast then toast:Hide() end end

function FW.OpenEndgame()
    local main, nav = WeintCodex.MainFrame, WeintCodex.Navigation
    if not (main and nav and nav.GoToTab) then return false end
    local EG = WeintCodex.Endgame
    if EG then EG.cat, EG.sel = "next", nil end
    main:Show()
    nav.GoToTab("endgame")
    return true
end

-- Feuerwerk, dann die Begruessung (auch fuer /wc feuerwerk).
function FW.Celebrate()
    FW.Play()
    if _G.C_Timer and _G.C_Timer.After then _G.C_Timer.After(FW.TOAST_DELAY, FW.ShowToast) else FW.ShowToast() end
end

-- Aufstieg: auf der Hoechststufe Feuerwerk und Kasten.
function FW.OnLevelUp(level)
    if type(level) ~= "number" or level < FW.MaxLevel() then return false end
    FW.Celebrate()
    local st, me = Store(), Me()
    if st and me then st.greeted[me] = true end
    return true
end

-- Einloggen: schon auf der Hoechststufe, aber noch nie begruesst.
function FW.OnLogin()
    local lvl = _G.UnitLevel and _G.UnitLevel("player")
    local K = WeintCodex.UIKit
    lvl = K and K.Plain and K.Plain(lvl) or lvl
    if type(lvl) ~= "number" or lvl < FW.MaxLevel() then return false end
    local st, me = Store(), Me()
    if not (st and me) or st.greeted[me] then return false end
    st.greeted[me] = true
    FW.ShowToast()
    return true
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LEVEL_UP")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:SetScript("OnEvent", WeintCodex.Measured("Stufe 60", function(self, event, a1)
    if event == "PLAYER_LEVEL_UP" then
        local K = WeintCodex.UIKit
        FW.OnLevelUp(K and K.Plain and K.Plain(a1) or a1)
    elseif event == "PLAYER_ENTERING_WORLD" then
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
        if _G.C_Timer and _G.C_Timer.After then _G.C_Timer.After(4, FW.OnLogin) else FW.OnLogin() end
    end
end))
FW.events = ev

-- /wcui speicher: interne Tabellen dieser Datei.
WeintCodex.Hold("modules/fireworks.lua", function() return { rockets = rockets } end)
