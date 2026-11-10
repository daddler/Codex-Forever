--------------------------------------------------
-- WeintCodex :: Komfort - Mauszeiger und Spielerpfeil (1.0.5.12)
--------------------------------------------------
-- Wunsch: "Mauscursor besser anzeigen - Einfaerbung, groesser, Kreis drum
-- herum" und "Spielerpfeil auf der Minikarte einstellbar, groesserer Pfeil".
--
-- MAUSZEIGER: den Zeiger selbst kann ein Addon nicht einfaerben. WeintCodex
-- legt deshalb einen Ring und/oder Schein unter den Zeiger, der ihm folgt
-- (GetCursorPosition je Bild, nur solange er an ist). Die Groesse des
-- Zeigers selbst ist eine Spieleinstellung (CVar cursorSizePreferred, wie
-- in den Optionen des Spiels) - gesetzt ueber PF.SetCVar, beim Ausschalten
-- zurueck. Ob Forever sie kennt, ist nicht gemessen; kennt es sie nicht,
-- passiert nichts.
--
-- SPIELERPFEIL: den Pfeil der Minikarte zeichnet das Spiel; einfaerben
-- laesst er sich nicht. WeintCodex legt einen eigenen Pfeil (media/ui/arrow,
-- eigenes Bild) in Farbe und Groesse darueber, gedreht nach GetPlayerFacing.
-- Wo das Spiel die Blickrichtung nicht nennt (in Instanzen moeglich), ist
-- der eigene Pfeil weg und der des Spiels zu sehen - nie ein geratener.
-- Dreht sich die Minikarte mit (rotateMinimap), zeigt er nach oben.
-- Optional ein Ring um die eigene Position.
--------------------------------------------------

local K = WeintCodex.UIKit
local C = WeintCodex.Colors
local KEY = "comfort"

WeintCodex.UICursor = {}
local CU = WeintCodex.UICursor

CU.DEFAULTS = {
    cursorOn = false, cursorStyle = "ring", cursorSize = 48, cursorAlpha = 80,
    cursorColorMode = "class", cursorColor = { r = 1, g = 0.82, b = 0 }, cursorCombat = false,
    cursorGameSize = "keep",
    pArrowOn = false, pArrowSize = 28, pArrowColorMode = "class", pArrowColor = { r = 1, g = 0.82, b = 0 },
    pArrowRing = false,
}

local function Opt(k) return K.Get(KEY, k) end
local function Active() return K.IsActive(KEY) end

function CU.Color(prefix)
    if Opt(prefix .. "ColorMode") == "custom" then
        local c = K.GetColor(KEY, prefix .. "Color")
        return c.r, c.g, c.b
    end
    local a = C.accent or { 1, 1, 1 }
    return a[1], a[2], a[3]
end

--------------------------------------------------
-- Mauszeiger
--------------------------------------------------

local cur
local function BuildCursor()
    if cur then return cur end
    cur = CreateFrame("Frame", "WeintCodexCursor", UIParent)
    cur:SetFrameStrata("TOOLTIP")
    cur:SetFrameLevel(100)
    cur:EnableMouse(false)
    cur.glow = cur:CreateTexture(nil, "BACKGROUND")
    cur.glow:SetTexture(K.MEDIA .. "halo")
    cur.glow:SetPoint("CENTER")
    if cur.glow.SetBlendMode then cur.glow:SetBlendMode("ADD") end
    cur.ring = cur:CreateTexture(nil, "ARTWORK")
    cur.ring:SetTexture(K.MEDIA .. "ring")
    cur.ring:SetAllPoints(cur)
    cur:Hide()
    cur:SetScript("OnUpdate", function(self)
        local x, y = _G.GetCursorPosition()
        local s = UIParent:GetEffectiveScale()
        if type(x) ~= "number" or type(s) ~= "number" or s <= 0 then return end
        self:ClearAllPoints()
        self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / s, y / s)
    end)
    CU.cursorFrame = cur
    return cur
end

function CU.ApplyCursor()
    local on = Active() and Opt("cursorOn")
    if on and Opt("cursorCombat") then
        on = _G.InCombatLockdown and K.Bool(_G.InCombatLockdown(), false) or false
    end
    if not on then
        if cur then cur:Hide() end
        return false
    end
    local f = BuildCursor()
    local size = tonumber(Opt("cursorSize")) or 48
    f:SetSize(size, size)
    local r, g, b = CU.Color("cursor")
    local a = (tonumber(Opt("cursorAlpha")) or 80) / 100
    local style = Opt("cursorStyle")
    f.ring:SetShown(style ~= "glow")
    f.ring:SetVertexColor(r, g, b, a)
    f.glow:SetShown(style ~= "ring")
    f.glow:SetSize(size * 1.6, size * 1.6)
    f.glow:SetVertexColor(r, g, b, a * 0.6)
    f:Show()
    return true
end

-- Groesse des Zeigers selbst (Spieleinstellung): "keep" = nicht anfassen.
CU.GAME_SIZES = { { value = "keep", text = "Wie im Spiel" }, { value = "0", text = "32" },
    { value = "1", text = "48" }, { value = "2", text = "64" }, { value = "3", text = "96" }, { value = "4", text = "128" } }
function CU.ApplyGameSize()
    local PF = WeintCodex.UIProfile
    if not PF then return end
    local v = Active() and Opt("cursorGameSize") or "keep"
    if v == "keep" or v == nil then
        if PF.ReleaseOwner then pcall(PF.ReleaseOwner, "cursor") end
    elseif PF.SetCVar then
        pcall(PF.SetCVar, "cursorSizePreferred", v, "cursor")
    end
end

--------------------------------------------------
-- Spielerpfeil der Minikarte
--------------------------------------------------

local arrow
local function BuildArrow()
    if arrow then return arrow end
    local mm = _G.Minimap
    if type(mm) ~= "table" then return nil end
    arrow = CreateFrame("Frame", "WeintCodexPlayerArrow", mm)
    arrow:SetPoint("CENTER", mm, "CENTER", 0, 0)
    arrow:SetFrameLevel((mm:GetFrameLevel() or 1) + 20)
    arrow:EnableMouse(false)
    arrow.ring = arrow:CreateTexture(nil, "ARTWORK")
    arrow.ring:SetTexture(K.MEDIA .. "ring")
    arrow.ring:SetPoint("CENTER")
    arrow.tex = arrow:CreateTexture(nil, "OVERLAY")
    arrow.tex:SetTexture(K.ARROW_TEXTURE or (K.MEDIA .. "arrow"))
    arrow.tex:SetAllPoints(arrow)
    arrow:Hide()
    local acc = 1
    arrow:SetScript("OnUpdate", function(self, el)
        acc = acc + (el or 0)
        if acc < 0.02 then return end
        acc = 0
        CU.TurnArrow(self)
    end)
    CU.arrowFrame = arrow
    return arrow
end

-- Blickrichtung oder nil (vom Client verschwiegen).
function CU.Facing()
    local f = _G.GetPlayerFacing and K.Plain(_G.GetPlayerFacing())
    return type(f) == "number" and f or nil
end

function CU.TurnArrow(self)
    local face = CU.Facing()
    if not face then
        self.tex:Hide()
        return false
    end
    local rot = _G.GetCVar and K.Plain(_G.GetCVar("rotateMinimap"))
    self.tex:SetRotation((rot == "1") and 0 or face)
    self.tex:Show()
    return true
end

function CU.ApplyArrow()
    local on = Active() and Opt("pArrowOn")
    if not on then
        if arrow then arrow:Hide() end
        return false
    end
    local f = BuildArrow()
    if not f then return false end
    local size = tonumber(Opt("pArrowSize")) or 28
    f:SetSize(size, size)
    local r, g, b = CU.Color("pArrow")
    f.tex:SetVertexColor(r, g, b, 1)
    f.ring:SetShown(Opt("pArrowRing") and true or false)
    f.ring:SetSize(size * 1.7, size * 1.7)
    f.ring:SetVertexColor(r, g, b, 0.7)
    f:Show()
    CU.TurnArrow(f)
    return true
end

function CU.Apply()
    CU.ApplyCursor()
    CU.ApplyGameSize()
    CU.ApplyArrow()
end

local ev = CreateFrame("Frame")
for _, e in ipairs({ "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED" }) do
    pcall(ev.RegisterEvent, ev, e)
end
ev:SetScript("OnEvent", WeintCodex.Measured("Mauszeiger", function(_, event)
    if event == "PLAYER_ENTERING_WORLD" then CU.Apply() else CU.ApplyCursor() end
end))
CU.events = ev

K.Listen(function(kind, key)
    if (kind == "active" or kind == "setting") and key == KEY then CU.Apply() end
end)

--------------------------------------------------
-- Seite im Komfort
--------------------------------------------------

local function Build(B)
    local function off() return not K.Get(KEY, "cursorOn") end
    local function aoff() return not K.Get(KEY, "pArrowOn") end
    local pct = function(v) return string.format("%d %%", v) end
    local px = function(v) return string.format("%d px", v) end
    B:Section("Mauszeiger")
    B:Row({ type = "toggle", label = "Mauszeiger hervorheben", key = "cursorOn",
            description = "Ein Ring und/oder Schein folgt dem Zeiger – so findest du ihn schneller wieder." },
          { type = "dropdown", label = "Form", key = "cursorStyle", disabled = off, items = {
                { value = "ring", text = "Ring" }, { value = "glow", text = "Schein" }, { value = "both", text = "Ring und Schein" } } })
    B:Row({ type = "slider", label = "Größe", key = "cursorSize", min = 20, max = 128, step = 4, format = px, disabled = off },
          { type = "slider", label = "Deckkraft", key = "cursorAlpha", min = 20, max = 100, step = 5, format = pct, disabled = off })
    B:Row({ type = "dropdown", label = "Farbe", key = "cursorColorMode", disabled = off, items = {
                { value = "class", text = "Klassenfarbe" }, { value = "custom", text = "Eigene Farbe" } } },
          { type = "color", label = "Eigene Farbe", key = "cursorColor",
            disabled = function() return off() or K.Get(KEY, "cursorColorMode") ~= "custom" end })
    B:Row({ type = "toggle", label = "Nur im Kampf", key = "cursorCombat", disabled = off },
          { type = "dropdown", label = "Größe des Zeigers selbst", key = "cursorGameSize", items = CU.GAME_SIZES,
            description = "Einstellung des Spiels (Bildpunkte). Einfärben kann ein Addon den Zeiger selbst nicht – dafür der Ring." })
    B:Section("Spielerpfeil auf der Minikarte")
    B:Row({ type = "toggle", label = "Eigener Spielerpfeil", key = "pArrowOn",
            description = "Ein größerer, farbiger Pfeil über dem des Spiels. Wo das Spiel die Blickrichtung nicht verrät, siehst du wieder seinen." },
          { type = "slider", label = "Größe", key = "pArrowSize", min = 14, max = 64, step = 2, format = px, disabled = aoff })
    B:Row({ type = "dropdown", label = "Farbe", key = "pArrowColorMode", disabled = aoff, items = {
                { value = "class", text = "Klassenfarbe" }, { value = "custom", text = "Eigene Farbe" } } },
          { type = "color", label = "Eigene Farbe", key = "pArrowColor",
            disabled = function() return aoff() or K.Get(KEY, "pArrowColorMode") ~= "custom" end })
    B:Row({ type = "toggle", label = "Kreis um den Pfeil", key = "pArrowRing", disabled = aoff }, { type = "empty" })
end

local mod = K.Module(KEY)
if mod then
    for k, v in pairs(CU.DEFAULTS) do
        if mod.defaults[k] == nil then mod.defaults[k] = v end
    end
    mod.pages[#mod.pages + 1] = { key = "zeiger", label = "Maus & Pfeil", build = Build }
    if mod.pageOrder then mod.pageOrder.zeiger = 3 end
end
