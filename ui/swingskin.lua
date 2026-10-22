--------------------------------------------------
-- WeintCodex :: Oberflaeche - Schwungtimer des Spiels im WeintCodex-Stil (6.38.1.0)
--------------------------------------------------
-- Forever bringt einen eigenen Schwungtimer mit (Optionen des Spiels,
-- erweitert): je Waffe ein Balken mit Namen ("Waffenhand") und Restzeit.
-- Hier bekommt er das Aussehen der Balken von WeintCodex: Textur der
-- Oberflaeche, dunkler Grund, feiner Rand, Schrift von WeintCodex. Der
-- Zierrahmen des Spiels wird unsichtbar (nicht versteckt - das Spiel darf
-- ihn weiter setzen).
--
-- Name des Fensters UNBEKANNT (er nimmt keine Maus an, /wcui fenster fand
-- ihn nicht). Gefunden wird er daher ueber seine Beschriftung: der Text
-- der Waffenhand/Schildhand/Distanz, wie der Client ihn selbst nennt
-- (INVTYPE_*), gesucht nur, wenn der Kampf oder der automatische Angriff
-- beginnt, hoechstens alle 10 s, und nur bis alle gefunden sind.
--
-- Seite "Allgemein" der Einheitenrahmen, Schalter `swingSkin`.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UISwingSkin = {}

local SW = WeintCodex.UISwingSkin
local K  = WeintCodex.UIKit
local GC = WeintCodex.GameColors
local KEY = "unitframes"

SW.TEXT_SIZE = 11
SW.WAIT = 10        -- Sekunden zwischen zwei Suchen
SW.MAX = 3          -- Waffenhand, Schildhand, Distanz

local done = setmetatable({}, { __mode = "k" })
SW.done = done
local st = { found = 0, last = -100, scans = 0 }
SW.state = st

function SW.Active()
    return K.IsActive(KEY) and K.Get(KEY, "swingSkin") ~= false
end

-- Beschriftungen, wie der Client sie nennt; die deutschen als Rueckfall.
function SW.Labels()
    local set = {}
    for _, g in ipairs({ "INVTYPE_WEAPONMAINHAND", "INVTYPE_WEAPONOFFHAND", "INVTYPE_RANGED", "INVTYPE_RANGEDRIGHT" }) do
        local t = _G[g]
        if type(t) == "string" and t ~= "" then set[t] = true end
    end
    for _, t in ipairs({ "Waffenhand", "Schildhand", "Distanz" }) do set[t] = true end
    return set
end

local function Kind(f)
    local ok, t = pcall(f.GetObjectType, f)
    return ok and t or nil
end

-- Der Balken zur Beschriftung: der Rahmen selbst, ein Kind (bis zwei
-- Ebenen tief) oder der Elternrahmen.
function SW.BarOf(f)
    if Kind(f) == "StatusBar" then return f end
    local function Down(fr, depth)
        for i = 1, select("#", fr:GetChildren()) do
            local c = select(i, fr:GetChildren())
            if Kind(c) == "StatusBar" then return c end
            if depth > 1 then
                local d = Down(c, depth - 1)
                if d then return d end
            end
        end
    end
    local hit = Down(f, 2)
    if hit then return hit end
    local p = f:GetParent()
    if p and Kind(p) == "StatusBar" then return p end
    return nil
end

local function QuietTextures(fr, keep)
    for i = 1, select("#", fr:GetRegions()) do
        local r = select(i, fr:GetRegions())
        if r ~= keep and Kind(r) == "Texture" then r:SetAlpha(0) end
    end
end

local function Fonts(fr)
    for i = 1, select("#", fr:GetRegions()) do
        local r = select(i, fr:GetRegions())
        if Kind(r) == "FontString" then
            K.SetFont(r, SW.TEXT_SIZE)
            if r.SetShadowOffset then r:SetShadowOffset(1, -1) end
        end
    end
end

function SW.Skin(holder)
    local sb = SW.BarOf(holder)
    if not sb or done[sb] then return done[sb] end
    local d = {}
    sb:SetStatusBarTexture(K.BarTexture())
    local fill = sb:GetStatusBarTexture()
    d.fill = fill
    -- Zierrahmen und Grund des Spiels: am Balken, am Rahmen der
    -- Beschriftung und an seinem NineSlice.
    QuietTextures(sb, fill)
    if holder ~= sb then QuietTextures(holder, nil) end
    for _, fr in ipairs({ sb, holder }) do
        for _, key in ipairs({ "NineSlice", "Border", "BorderFrame", "Background" }) do
            local x = fr[key]
            if type(x) == "table" and x.SetAlpha then x:SetAlpha(0) end
        end
    end
    local f = GC.kachelFill
    d.bg = sb:CreateTexture(nil, "BACKGROUND", nil, -7)
    d.bg:SetAllPoints(sb)
    d.border = K.Border(sb, 1, 0, 0, 0, 1, "OVERLAY")
    K.LookFill(d.bg, f[4], d.border)
    Fonts(sb)
    if holder ~= sb then Fonts(holder) end
    -- Setzt das Spiel die Textur neu, wieder die eigene (nur dann).
    if _G.hooksecurefunc then
        _G.hooksecurefunc(sb, "SetStatusBarTexture", function(bar, tex)
            if d.busy or tex == K.BarTexture() then return end
            d.busy = true
            bar:SetStatusBarTexture(K.BarTexture())
            d.busy = nil
        end)
    end
    done[sb] = d
    st.found = st.found + 1
    return d
end

-- Alle sichtbaren Rahmen nach einer Beschriftung durchsuchen.
function SW.Scan()
    if not SW.Active() or st.found >= SW.MAX then return end
    if type(_G.EnumerateFrames) ~= "function" then return end
    local now = _G.GetTime and _G.GetTime() or 0
    if now - st.last < SW.WAIT then return end
    st.last = now
    st.scans = st.scans + 1
    local labels = SW.Labels()
    local f = _G.EnumerateFrames()
    while f do
        local ok, hit = pcall(function()
            if f:IsForbidden() or not f:IsVisible() then return false end
            for i = 1, select("#", f:GetRegions()) do
                local r = select(i, f:GetRegions())
                if Kind(r) == "FontString" then
                    local t = r:GetText()
                    if type(t) == "string" and labels[t] then return true end
                end
            end
            return false
        end)
        if ok and hit then pcall(SW.Skin, f) end
        f = _G.EnumerateFrames(f)
    end
end

local function Soon()
    if not SW.Active() then return end
    if _G.C_Timer and _G.C_Timer.After then _G.C_Timer.After(0.3, SW.Scan) else SW.Scan() end
end

local ev = CreateFrame("Frame")
for _, e in ipairs({ "PLAYER_ENTER_COMBAT", "START_AUTOREPEAT_SPELL", "PLAYER_REGEN_DISABLED", "PLAYER_ENTERING_WORLD" }) do
    pcall(ev.RegisterEvent, ev, e)
end
ev:SetScript("OnEvent", Soon)

function SW.StatusLine()
    return string.format("Schwungtimer: %s · gefunden %d Balken · gesucht %d×%s",
        SW.Active() and "an" or "aus", st.found, st.scans,
        st.found == 0 and " (erscheint im Kampf – einmal angreifen)" or "")
end

local mod = K.Module(KEY)
if mod then
    if mod.defaults.swingSkin == nil then mod.defaults.swingSkin = true end
    local page = mod.pages and mod.pages[1]
    if page then
        local build = page.build
        page.build = function(B)
            build(B)
            B:Section("Schwungtimer")
            B:Row({ type = "toggle", label = "Schwungtimer im WeintCodex-Stil", key = "swingSkin", reload = true,
                    description = "Die Balken des Spiels (erweiterte Optionen) mit Textur, Rand und Schrift von WeintCodex." },
                  { type = "empty" })
        end
    end
end
