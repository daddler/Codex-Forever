--------------------------------------------------
-- WeintCodex :: Oberflaeche - Abklingzeitmanager
--------------------------------------------------
-- Der Abklingzeitmanager des Spiels (seit 11.1, im Forever-Client 12.x)
-- zeigt ausgewaehlte Abklingzeiten und eigene Buffs als Symbole und
-- Balken: "Wichtig", "Hilfreich", "Buffs als Symbole", "Buffs als Balken".
-- Beta-Test 6.4.0.4: "soll auch komplett in WeintCodex UI rein. Also einen
-- eigenen."
--
-- EIGENES AUSSEHEN, NICHT EIGENE DATEN. Im Kampf nennt der Client
-- Abklingzeiten und Auren nur verschluesselt; welche Aura zu welchem
-- Symbol gehoert, ordnet der Manager des Spiels in geschuetztem Code zu.
-- Ein nachgebauter Manager bliebe im Kampf leer - genau das ist den
-- eigenen Symbolen am Zielrahmen passiert (6.3.0.2 gemessen, 6.4.0.3
-- behoben). Deshalb bleiben Zaehlwerk und Auswahl die des Spiels, und
-- WeintCodex zeichnet jedes Symbol und jeden Balken neu:
--   * eckig statt der runden Maske, Rand und Grund wie die Aktionsleisten,
--   * der Rahmenschmuck (Atlas UI-HUD-CoolDownManager-IconOverlay) weg,
--   * Abklingzahl, Ladungen und Stapel in der WeintCodex-Schrift,
--   * Buff-Balken mit der Balkentextur der Oberflaeche.
-- Kein Feld am Rahmen des Spiels wird geschrieben (Blizzard-Code, der
-- einen von uns gesetzten Wert liest, liefe unsicher weiter und
-- scheiterte an geheimen Werten); nur Methoden werden gerufen, und neue
-- Symbole meldet ein hooksecurefunc auf OnAcquireItemFrame.
--
-- Kein eigener Eintrag in der Seitenleiste: die ist voll (load_test.lua,
-- "Nichts muss scrollen"). Der Manager ist ein Reiter der Erinnerungen -
-- dasselbe Thema, Symbole fuer Buffs und Abklingzeiten - und hat einen
-- eigenen Befehl, /wcui abklingzeiten.
--
-- Welche Zauber erscheinen, waehlt der Spieler im Fenster des Spiels
-- (Knopf "Zauber auswählen"); die Lage bestimmt der Bearbeitungsmodus des
-- Spiels. Beides bleibt dort, weil es dort gespeichert wird - ein
-- Addon, das die Einstellungen des Bearbeitungsmodus schreibt, macht ihn
-- unsicher.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UICooldowns = {}

local CD = WeintCodex.UICooldowns
local K = WeintCodex.UIKit
local KEY = "reminders"   -- Reiter der Erinnerungen, siehe unten

-- "cdm" vorneweg: die Erinnerungen haben schon ein cdSize.
local defaults = {
    cdmSkin      = true,   -- im WeintCodex-Stil zeichnen
    cdmFontSize  = 16,     -- Abklingzahl auf den Symbolen
    cdmCountSize = 12,     -- Ladungen und Stapel
    cdmBarFontSize = 11,   -- Name und Restzeit auf den Balken
}
CD.DEFAULTS = defaults

local function Opt(k) return K.Get(KEY, k) end

-- Die vier Anzeigen des Spiels (Blizzard_CooldownViewer, CooldownViewer.xml).
CD.VIEWERS = { "EssentialCooldownViewer", "UtilityCooldownViewer", "BuffIconCooldownViewer", "BuffBarCooldownViewer" }

-- Schmuck, der zur runden Form gehoert und auf einem eckigen Symbol stoert.
local DECOR_ATLAS = {
    ["UI-HUD-CoolDownManager-IconOverlay"] = true,
    ["UI-HUD-CoolDownManager-Bar-BG"] = true,
}

local skinned = setmetatable({}, { __mode = "k" })   -- [Symbol des Spiels] = unsere Teile
CD.skinned = skinned
CD.state = "noch nicht angewendet"

local function Hide(r)
    if type(r) ~= "table" or not r.SetAlpha then return end
    local AB = WeintCodex.UIActionBars
    if AB and AB.KeepHidden then AB.KeepHidden(r) else r:SetAlpha(0) end
end

-- Die runde Maske vom Symbol nehmen und den Rand des Bildes abschneiden
-- (wie auf den Aktionsleisten).
local function Unmask(tex)
    if type(tex) ~= "table" then return end
    if tex.GetNumMaskTextures and tex.GetMaskTexture and tex.RemoveMaskTexture then
        pcall(function()
            local n = K.Plain(tex:GetNumMaskTextures())
            for i = (type(n) == "number" and n or 0), 1, -1 do
                local m = tex:GetMaskTexture(i)
                if m then tex:RemoveMaskTexture(m) end
            end
        end)
    end
    if tex.SetTexCoord then tex:SetTexCoord(0.08, 0.92, 0.08, 0.92) end
end

local function HideDecor(frame)
    if type(frame) ~= "table" or not frame.GetRegions then return end
    local ok, regions = pcall(function() return { frame:GetRegions() } end)
    if not ok then return end
    for _, r in ipairs(regions) do
        local atlas = r.GetAtlas and K.Plain(r:GetAtlas())
        if type(atlas) == "string" and DECOR_ATLAS[atlas] then Hide(r) end
    end
end

-- Grund und 1-px-Rand um ein Symbol.
local function IconFrame(host)
    local bg = host:CreateTexture(nil, "BACKGROUND", nil, -8)
    bg:SetAllPoints(host)
    bg:SetColorTexture(0, 0, 0, 1)
    local border = K.Border(host, 1, 0, 0, 0, 1, "OVERLAY")
    return bg, border
end

-- Ein Schriftobjekt fuer alle Abklingzahlen: das Spiel setzt die Zahl
-- selbst, man sagt ihm nur, womit (Cooldown:SetCountdownFont).
local cdFont
local function CooldownFont()
    if not _G.CreateFont then return nil end
    cdFont = cdFont or _G.CreateFont("WeintCodexCooldownManagerFont")
    if cdFont and cdFont.SetFont then
        cdFont:SetFont(K.FontPath(), Opt("cdmFontSize") or 16, "OUTLINE")
    end
    return cdFont
end

local function StyleCooldown(cd)
    if type(cd) ~= "table" then return end
    -- Eckige Abdeckung: die des Spiels ist rund zugeschnitten. Die Farbe
    -- setzt das Spiel selbst (Abklingzeit dunkel, laufende Aura hell).
    if cd.SetSwipeTexture then pcall(cd.SetSwipeTexture, cd, K.BAR_TEXTURE) end
    if cd.SetCountdownFont and CooldownFont() then pcall(cd.SetCountdownFont, cd, "WeintCodexCooldownManagerFont") end
end

-- Schriften, die sich mit den Einstellungen aendern.
local function ApplyFonts(item, d)
    local count = Opt("cdmCountSize") or 12
    if d.kind == "bar" then
        local bar = item.Bar
        if type(bar) == "table" then
            K.SetFont(bar.Name, Opt("cdmBarFontSize") or 11)
            K.SetFont(bar.Duration, Opt("cdmBarFontSize") or 11)
        end
        local icon = item.Icon
        if type(icon) == "table" then K.SetFont(icon.Applications, count) end
    else
        local charge = item.ChargeCount
        if type(charge) == "table" then K.SetFont(charge.Current, count) end
        local apps = item.Applications
        if type(apps) == "table" then K.SetFont(apps.Applications, count) end
    end
end

-- ABSTAND. Das Spiel setzt seine Symbole 4 px enger, als der Abstand im
-- Bearbeitungsmodus sagt (CooldownViewerMixin:GetAdditionalPaddingOffset):
-- die runde Maske laesst am Rand Luft, die Symbole sollen sich optisch
-- beruehren. Eckig und bis zum Rand gefuellt, ueberlappten sie
-- (Beta-Test 6.4.1.0). Das Bild ruecken wir deshalb nach innen, so dass
-- zwischen zwei Raendern 2 px bleiben:
--   Luecke = (Abstand - 4) + 2 * Einzug - 2 * Rand  =>  Einzug = (8 - Abstand) / 2
-- Den Abstand liest die Anzeige des Spiels selbst (iconPadding, nur
-- gelesen); ohne Antwort gilt der Standard des Spiels.
local GAP, RIM = 2, 1
function CD.Inset(viewer)
    local pad = type(viewer) == "table" and K.Plain(viewer.iconPadding) or nil
    if type(pad) ~= "number" then pad = 2 end
    return math.max(RIM, math.ceil((GAP + 2 * RIM + 4 - pad) / 2))
end

-- Rand um eine Flaeche (Textur), nicht um einen Rahmen: das Symbol sitzt
-- eingerueckt im Rahmen des Spiels.
local function Rim(host, region)
    local r = {}
    for _, side in ipairs({ "top", "bottom", "left", "right" }) do
        local t = host:CreateTexture(nil, "OVERLAY", nil, 7)
        t:SetColorTexture(0, 0, 0, 1)
        r[side] = t
    end
    r.top:SetPoint("BOTTOMLEFT", region, "TOPLEFT", -RIM, 0)
    r.top:SetPoint("BOTTOMRIGHT", region, "TOPRIGHT", RIM, 0)
    r.top:SetHeight(RIM)
    r.bottom:SetPoint("TOPLEFT", region, "BOTTOMLEFT", -RIM, 0)
    r.bottom:SetPoint("TOPRIGHT", region, "BOTTOMRIGHT", RIM, 0)
    r.bottom:SetHeight(RIM)
    r.left:SetPoint("TOPRIGHT", region, "TOPLEFT", 0, 0)
    r.left:SetPoint("BOTTOMRIGHT", region, "BOTTOMLEFT", 0, 0)
    r.left:SetWidth(RIM)
    r.right:SetPoint("TOPLEFT", region, "TOPRIGHT", 0, 0)
    r.right:SetPoint("BOTTOMLEFT", region, "BOTTOMRIGHT", 0, 0)
    r.right:SetWidth(RIM)
    return r
end

-- Bild, Abdeckung und Reichweiten-Schatten auf die eingerueckte Flaeche.
local function PlaceInset(item, d, inset)
    if d.inset == inset then return end
    d.inset = inset
    for _, part in ipairs({ item.Icon, item.Cooldown, item.OutOfRange }) do
        if type(part) == "table" and part.ClearAllPoints then
            pcall(function()
                part:ClearAllPoints()
                part:SetPoint("TOPLEFT", item, "TOPLEFT", inset, -inset)
                part:SetPoint("BOTTOMRIGHT", item, "BOTTOMRIGHT", -inset, inset)
            end)
        end
    end
end

local function SkinIconItem(item, viewer)
    local d = { kind = "icon" }
    Unmask(item.Icon)
    HideDecor(item)
    if type(item.Icon) == "table" then
        d.bg = item:CreateTexture(nil, "BACKGROUND", nil, -8)
        d.bg:SetAllPoints(item.Icon)
        d.bg:SetColorTexture(0, 0, 0, 1)
        d.rim = Rim(item, item.Icon)
    end
    StyleCooldown(item.Cooldown)
    PlaceInset(item, d, CD.Inset(viewer))
    return d
end

local function SkinBarItem(item)
    local d = { kind = "bar" }
    local iconFrame = item.Icon
    if type(iconFrame) == "table" then
        Unmask(iconFrame.Icon)
        HideDecor(iconFrame)
        d.iconBg, d.iconBorder = IconFrame(iconFrame)
    end
    local bar = item.Bar
    if type(bar) == "table" then
        Hide(bar.BarBG)
        Hide(bar.Pip)
        HideDecor(bar)
        if bar.SetStatusBarTexture then bar:SetStatusBarTexture(K.BarTexture()) end
        local c = WeintCodex.GameColors and WeintCodex.GameColors.cooldownBar
        if c and bar.SetStatusBarColor then bar:SetStatusBarColor(c[1], c[2], c[3], c[4] or 1) end
        d.barBg = bar:CreateTexture(nil, "BACKGROUND", nil, -8)
        d.barBg:SetAllPoints(bar)
        d.barBg:SetColorTexture(0, 0, 0, 0.55)
        d.barBorder = K.Border(bar, 1, 0, 0, 0, 1, "OVERLAY")
    end
    return d
end

-- Ein Symbol oder Balken des Spiels, einmal je Rahmen (das Spiel nimmt sie
-- aus einem Vorrat und gibt sie wieder zurueck).
function CD.SkinItem(item, viewer)
    if type(item) ~= "table" then return end
    if item.IsForbidden and item:IsForbidden() then return end
    local d = skinned[item]
    if not d then
        local ok, res = pcall(function()
            if type(item.Bar) == "table" then return SkinBarItem(item) end
            return SkinIconItem(item, viewer)
        end)
        if not ok then
            CD.state = "Symbol nicht umgestaltet: " .. tostring(res)
            return
        end
        d = res
        skinned[item] = d
    elseif d.kind == "icon" then
        -- Aus dem Vorrat zurueck, womoeglich mit neuem Abstand.
        PlaceInset(item, d, CD.Inset(viewer))
    end
    ApplyFonts(item, d)
end

local function ItemsOf(viewer)
    local list = {}
    local pool = viewer.itemFramePool
    if type(pool) == "table" and pool.EnumerateActive then
        pcall(function() for item in pool:EnumerateActive() do list[#list + 1] = item end end)
    end
    if #list == 0 and viewer.GetItemFrames then
        pcall(function() for _, item in ipairs(viewer:GetItemFrames() or {}) do list[#list + 1] = item end end)
    end
    return list
end

local hooked = setmetatable({}, { __mode = "k" })
CD.found = {}

-- Alle Anzeigen, die es gibt: vorhandene Symbole jetzt, neue per Haken.
function CD.SkinAll()
    if not Opt("cdmSkin") then
        CD.state = "Aussehen des Spiels gewählt"
        return
    end
    local n, items = 0, 0
    CD.found = {}
    for _, name in ipairs(CD.VIEWERS) do
        local v = _G[name]
        if type(v) == "table" and not (v.IsForbidden and v:IsForbidden()) then
            n = n + 1
            CD.found[#CD.found + 1] = name
            if not hooked[v] and _G.hooksecurefunc and type(v.OnAcquireItemFrame) == "function" then
                hooked[v] = true
                _G.hooksecurefunc(v, "OnAcquireItemFrame", K.Measured("Abklingzeitmanager", function(viewer, item) CD.SkinItem(item, viewer) end))
            end
            for _, item in ipairs(ItemsOf(v)) do
                CD.SkinItem(item, v)
                items = items + 1
            end
        end
    end
    if n == 0 then
        CD.state = "Abklingzeitmanager des Spiels nicht gefunden"
    else
        CD.state = string.format("%d Anzeigen im WeintCodex-Stil, %d Symbole", n, items)
    end
end

-- Einstellungen: Schriften neu, alles andere bleibt.
function CD.Refresh()
    CooldownFont()
    for item, d in pairs(skinned) do ApplyFonts(item, d) end
end

--------------------------------------------------
-- Schalter des Spiels
--------------------------------------------------

local CVAR = "cooldownViewerEnabled"

function CD.GameEnabled()
    local cv = _G.C_CVar
    if cv and cv.GetCVarBool then return K.Bool(cv.GetCVarBool(CVAR), false) end
    return false
end

function CD.SetGameEnabled(on)
    local cv = _G.C_CVar
    if cv and cv.SetCVar then pcall(cv.SetCVar, CVAR, on and "1" or "0") end
end

-- Das Auswahlfenster des Spiels (CooldownViewerSettings:TogglePanel, wie
-- der Schraegstrich-Befehl des Spiels).
function CD.OpenSettings()
    local s = _G.CooldownViewerSettings
    if type(s) == "table" and type(s.TogglePanel) == "function" then
        local ok = pcall(s.TogglePanel, s)
        if ok then return true end
    end
    print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " Das Auswahlfenster des Abklingzeitmanagers ist in diesem Client nicht zu finden.")
    return false
end

--------------------------------------------------
-- Reiter der Erinnerungen
--------------------------------------------------

function CD.Enable()
    CD.SkinAll()
    -- Der Manager des Spiels kann spaeter laden (Blizzard_CooldownViewer)
    -- oder seine Anzeigen erst beim Betreten der Welt fuellen.
    local ev = CreateFrame("Frame")
    ev:RegisterEvent("ADDON_LOADED")
    ev:RegisterEvent("PLAYER_ENTERING_WORLD")
    ev:SetScript("OnEvent", K.Measured("Abklingzeitmanager", function(_, event, name)
        if event == "ADDON_LOADED" and name ~= "Blizzard_CooldownViewer" then return end
        CD.SkinAll()
    end))
end

local function px(v) return string.format("%d px", v) end

function CD.BuildPage(B)
    B:Section("Abklingzeitmanager", "Der Manager des Spiels im WeintCodex-Stil. Welche Zauber und Buffs erscheinen, wählst du im Fenster des Spiels; verschieben: Bearbeitungsmodus des Spiels.")
    B:Row({ type = "toggle", label = "Abklingzeitmanager aktivieren",
            get = function() return CD.GameEnabled() end, set = function(v) CD.SetGameEnabled(v) end },
          { type = "toggle", label = "Im WeintCodex-Stil", key = "cdmSkin", reload = true,
            description = "Aus: das Aussehen des Spiels. Wirkt nach dem Neuladen." })
    B:Row({ type = "button", label = "Zauber", text = "Zauber auswählen",
            tooltip = "Öffnet das Auswahlfenster des Abklingzeitmanagers des Spiels.",
            onClick = function() CD.OpenSettings() end },
          { type = "empty" })
    B:Section("Schrift")
    B:Row({ type = "slider", label = "Abklingzahl", key = "cdmFontSize", min = 10, max = 28, step = 1, format = px },
          { type = "slider", label = "Ladungen und Stapel", key = "cdmCountSize", min = 8, max = 20, step = 1, format = px })
    B:Row({ type = "slider", label = "Balken: Name und Zeit", key = "cdmBarFontSize", min = 8, max = 18, step = 1, format = px },
          { type = "empty" })
    B:Note("Eigene Zählwerke gibt es hier bewusst nicht: im Kampf nennt der Client Abklingzeiten und Buffs nur dem Manager des Spiels. Symbolgröße, Abstand und Reihen stellt dessen Bearbeitungsmodus ein – dort werden sie gespeichert.")
end

-- An das Modul "Erinnerungen" haengen (es laedt vorher, siehe .toc).
do
    local m = K.Module(KEY)
    if m then
        for k, v in pairs(defaults) do m.defaults[k] = v end
        m.pages[#m.pages + 1] = { key = "abklingzeitmanager", label = "Abklingzeitmanager", build = CD.BuildPage }
        CD.PAGE = #m.pages
        local enable, onSetting = m.Enable, m.OnSetting
        m.Enable = function(...)
            if enable then enable(...) end
            local ok, err = pcall(CD.Enable)
            if not ok then K.Report("abklingzeitmanager", err) end
        end
        m.OnSetting = function(key, ...)
            if type(key) == "string" and key:sub(1, 3) == "cdm" then
                CD.Refresh()
                return
            end
            if onSetting then onSetting(key, ...) end
            if key == "*" then CD.Refresh() end
        end
    end
end
