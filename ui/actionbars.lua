--------------------------------------------------
-- WeintCodex :: Oberflaeche - Aktionsleisten
--------------------------------------------------
-- DIE KNOEPFE DES SPIELS IN DER SPRACHE VON WEINTCODEX - KEINE EIGENEN
-- LEISTEN. Das ist eine bewusste Grenze:
--
--   * Eigene Aktionsleisten brauchen fuers Umblaettern (Haltung,
--     Gestalt, Fahrzeug) "Secure Snippets". Dem Forever-Beta-Client fehlt
--     laut EllesmereUI der Uebersetzer dafuer (loadstring_untainted) -
--     dort laufen deren Leisten nur eingeschraenkt.
--   * Lage und Groesse der Leisten verwaltet der Bearbeitungsmodus des
--     Spiels. Wer sie von aussen verschiebt, bekommt Taint.
--
-- Was bleibt, ist, was man sieht und was sicher ist: flache Knoepfe mit
-- 1-px-Rand statt der Steinrahmen, beschnittene Symbole, Tastenkuerzel
-- und Stapelzahl in der WeintCodex-Schrift, Makronamen wahlweise weg,
-- Symbol rot, wenn das Ziel ausser Reichweite ist, und die Greifen an den
-- Enden weg. Lage und Groesse: Bearbeitungsmodus des Spiels (Esc ->
-- Bearbeitungsmodus).
--
-- Texturen an geschuetzten Knoepfen umzufaerben ist erlaubt, auch im
-- Kampf; die Knoepfe selbst werden nie angefasst.
--
-- MIKROMENUE UND TASCHENLEISTE sind die Ausnahme vom "nicht verschieben":
-- keine geschuetzten Rahmen, und ihre Lage ist, was die Oberflaeche von
-- EllesmereUI ausmacht (Menue klein unten links, Taschen unten rechts).
-- Gesetzt wird nur, wenn der Bearbeitungsmodus des Spiels sie gerade
-- selbst angeordnet hat (danach per Haken) und nie im Kampf. Ob das den
-- Bearbeitungsmodus auf Forever unberuehrt laesst, ist nicht geprueft -
-- deshalb abschaltbar ("Wie im Spiel").
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIActionBars = {}

local AB = WeintCodex.UIActionBars
local K  = WeintCodex.UIKit
local KEY = "actionbars"

local defaults = {
    border       = true,
    borderColor  = K.ColorDefault("plateBorder"),
    hotkeys      = true,
    hotkeySize   = 11,
    shortHotkeys = true,     -- "Maustaste 4" -> "M4", "s-1" -> "S1"
    -- Seit 6.3.0.0 (Beta-Test: "gefaellt mir noch gar nicht"): leere Plaetze
    -- weg statt Kaesten mit Tastenzahl, flache Hervorhebung, Schatten am
    -- Symbol, Abklingzahl in der WeintCodex-Schrift, kein Reichweitenpunkt.
    emptySlots   = "hide",   -- hide | faint | game
    iconShade    = true,
    cooldownFont = true,
    cooldownSize = 16,
    hideRangeDot = true,
    macroNames   = false,
    countSize    = 12,
    rangeColor   = true,
    hideEndCaps  = true,
    microMenu    = "left",   -- left | game
    microScale   = 85,
    bagsBar      = "right",  -- right | game
    -- Seit 6.3.0.3 (Beta-Test: "sieht nach wenig aus - bei ElvUI richtig
    -- schick"): eine Kachel hinter jeder Leiste, die Blaetterpfeile der
    -- Hauptleiste weg, Tastenkuerzel oben rechts, Stapelzahl unten rechts.
    barBackdrop  = true,
    hidePaging   = true,
}

local function Opt(k) return K.Get(KEY, k) end

-- Die Knopffamilien des modernen Clients. Was es auf Forever nicht gibt,
-- wird still uebersprungen (_G[name] ist dann nil).
local FAMILIES = {
    { "ActionButton", 12 },
    { "MultiBarBottomLeftButton", 12 },
    { "MultiBarBottomRightButton", 12 },
    { "MultiBarRightButton", 12 },
    { "MultiBarLeftButton", 12 },
    { "MultiBar5Button", 12 },
    { "MultiBar6Button", 12 },
    { "MultiBar7Button", 12 },
    { "PetActionButton", 10 },
    { "StanceButton", 10 },
}

local skinned = {}
AB.skinned = skinned

local function Region(b, key)
    local r = b[key]
    if type(r) == "table" then return r end
    local name = b.GetName and b:GetName()
    if name then
        r = _G[name .. key]
        if type(r) == "table" then return r end
    end
    return nil
end

-- Ein Teil des Spiels, der unsichtbar bleiben soll, auch wenn das Spiel
-- seine Deckkraft neu setzt.
local hiddenParts, keepGuard = {}, false
local function KeepHidden(r)
    if not hiddenParts[r] then
        hiddenParts[r] = true
        if _G.hooksecurefunc and type(r.SetAlpha) == "function" then
            _G.hooksecurefunc(r, "SetAlpha", function(self)
                if keepGuard then return end
                keepGuard = true
                self:SetAlpha(0)
                keepGuard = false
            end)
        end
    end
    keepGuard = true
    r:SetAlpha(0)
    keepGuard = false
end
AB.KeepHidden = KeepHidden

local function Skin(b)
    if skinned[b] then return skinned[b] end
    if b.IsForbidden and b:IsForbidden() then return nil end
    local d = {}

    -- Der Symbolrahmen des Spiels ("UI-HUD-ActionBar-IconFrame"): nicht
    -- entfernen, sondern unsichtbar halten. Bis 6.3.0.1 nur einmal auf
    -- Alpha 0 gesetzt - das Spiel setzt ihn bei jedem Aktualisieren neu
    -- (SetNormalAtlas), und im Beta-Test stand er als zweiter, innerer
    -- Rahmen wieder da. Jetzt haelt ein Haken ihn unsichtbar.
    local function HideNormal()
        local normal = b.GetNormalTexture and b:GetNormalTexture()
        if normal then KeepHidden(normal) end
        if type(b.NormalTexture) == "table" then KeepHidden(b.NormalTexture) end
    end
    HideNormal()
    if _G.hooksecurefunc then
        for _, m in ipairs({ "SetNormalAtlas", "SetNormalTexture" }) do
            if type(b[m]) == "function" then _G.hooksecurefunc(b, m, HideNormal) end
        end
    end
    for _, key in ipairs({ "SlotArt", "SlotBackground", "IconMask", "Border", "FloatingBG", "RightDivider", "BottomDivider" }) do
        local r = Region(b, key)
        if r and r.SetAlpha then KeepHidden(r) end
    end
    local icon = Region(b, "icon") or Region(b, "Icon")
    if icon then
        if icon.SetTexCoord then icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) end
        -- Das Symbol fuellt den Knopf: der moderne Client setzt es ein paar
        -- Pixel nach innen, und der dunkle Streifen dazwischen wirkte wie
        -- ein zweiter Rahmen. Der eine Rahmen liegt ueber dem Rand.
        if not K.InCombat() then
            icon:ClearAllPoints()
            icon:SetAllPoints(b)
        end
        -- Die runde Maske des modernen Clients weg: sonst bleibt das
        -- beschnittene Symbol trotzdem rund.
        local mask = Region(b, "IconMask")
        if mask and icon.RemoveMaskTexture then pcall(icon.RemoveMaskTexture, icon, mask) end
        d.icon = icon
    end

    -- Reichweite als eigene Schicht ueber dem Symbol, nicht als Faerbung
    -- des Symbols: die gehoert dem Spiel (blau = keine Kraft, grau = nicht
    -- benutzbar), und wer sie ueberschreibt, loescht diese Auskunft.
    if icon then
        local danger = WeintCodex.Colors.danger
        d.range = b:CreateTexture(nil, "OVERLAY")
        d.range:SetAllPoints(icon)
        d.range:SetColorTexture(danger[1], danger[2], danger[3], 0.45)
        d.range:Hide()
    end

    d.bg = b:CreateTexture(nil, "BACKGROUND", nil, -7)
    d.bg:SetAllPoints(b)
    d.bg:SetColorTexture(0, 0, 0, 0.5)
    d.border = K.Border(b, 1, 0, 0, 0, 1, "OVERLAY")
    d.shadow = K.Glow(b, { spread = 3, shadow = true })

    -- Tiefe: unten am Symbol ein leichter Schatten - die Stapelzahl steht
    -- darauf lesbar, und das Symbol wirkt nicht mehr wie ausgeschnitten.
    if icon then
        d.shade = b:CreateTexture(nil, "ARTWORK", nil, 2)
        d.shade:SetPoint("BOTTOMLEFT", icon, "BOTTOMLEFT", 0, 0)
        d.shade:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 0, 0)
        d.shade:SetHeight(18)
        d.shade:SetTexture(K.BAR_TEXTURE)
        local c = WeintCodex.GameColors.iconShade
        if d.shade.SetGradient and _G.CreateColor then
            d.shade:SetGradient("VERTICAL", _G.CreateColor(c[1], c[2], c[3], c[4]), _G.CreateColor(c[1], c[2], c[3], 0))
        else
            d.shade:SetVertexColor(c[1], c[2], c[3], c[4] * 0.5)
        end
    end

    -- Hervorhebung, gedrueckt, aktiv: flach statt der Glanzrahmen des Spiels.
    local GC = WeintCodex.GameColors
    local hl = b.GetHighlightTexture and b:GetHighlightTexture()
    if hl and hl.SetColorTexture then
        hl:SetColorTexture(GC.hoverFill[1], GC.hoverFill[2], GC.hoverFill[3], GC.hoverFill[4])
        if icon then hl:ClearAllPoints() hl:SetAllPoints(icon) end
    end
    local pushed = b.GetPushedTexture and b:GetPushedTexture()
    if pushed and pushed.SetColorTexture then
        pushed:SetColorTexture(0, 0, 0, 0.35)
        if icon then pushed:ClearAllPoints() pushed:SetAllPoints(icon) end
    end
    local checked = b.GetCheckedTexture and b:GetCheckedTexture()
    if checked and checked.SetColorTexture then
        local a = WeintCodex.Colors.accent
        checked:SetColorTexture(a[1], a[2], a[3], 0.35)
        if icon then checked:ClearAllPoints() checked:SetAllPoints(icon) end
    end
    d.cooldown = Region(b, "cooldown") or Region(b, "Cooldown")
    -- Die Abklingspirale deckt das ganze Symbol, nicht den alten Einsatz.
    if d.cooldown and icon and not K.InCombat() and d.cooldown.ClearAllPoints then
        d.cooldown:ClearAllPoints()
        d.cooldown:SetAllPoints(icon)
    end

    d.hotkey = Region(b, "HotKey")
    d.count  = Region(b, "Count")
    d.name   = Region(b, "Name")
    -- Feste Plaetze: Taste oben rechts, Stapel unten rechts, Makroname
    -- unten mittig - jeder Knopf gleich, auch auf Begleiter- und
    -- Haltungsleiste.
    if not K.InCombat() then
        if d.hotkey and d.hotkey.ClearAllPoints then
            d.hotkey:ClearAllPoints()
            d.hotkey:SetPoint("TOPRIGHT", b, "TOPRIGHT", -2, -3)
            if d.hotkey.SetJustifyH then d.hotkey:SetJustifyH("RIGHT") end
        end
        if d.count and d.count.ClearAllPoints then
            d.count:ClearAllPoints()
            d.count:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -2, 3)
        end
        if d.name and d.name.ClearAllPoints then
            d.name:ClearAllPoints()
            d.name:SetPoint("BOTTOMLEFT", b, "BOTTOMLEFT", 2, 3)
            d.name:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -2, 3)
        end
    end
    skinned[b] = d
    return d
end

-- Leerer Platz? Nur fuer Knoepfe mit Aktionsnummer; Begleiter- und
-- Haltungsknoepfe gelten als belegt.
local function IsEmpty(b)
    local action = b.action
    if type(action) ~= "number" and b.GetAttribute then action = b:GetAttribute("action") end
    action = K.Plain(action)
    if type(action) ~= "number" or not _G.HasAction then return false end
    return not K.Bool(_G.HasAction(action), true)
end

-- Kurze Tastenkuerzel. Das Spiel schreibt die Belegung aus ("Maustaste 4",
-- "s-1") und schneidet sie auf einem 40-px-Knopf ab ("Mau...", im Beta-
-- Test gesehen). Die Reihenfolge zaehlt: erst ganze Namen, dann Teile.
local HOTKEY_SUBS = {
    { "Mittlere Maustaste", "M3" },
    { "Maustaste%s*", "M" },
    { "Mausrad[%s%a]*[Hh]och", "MU" }, { "Mausrad[%s%a]*[Oo]ben", "MU" },
    { "Mausrad[%s%a]*[Rr]unter", "MD" }, { "Mausrad[%s%a]*[Uu]nten", "MD" },
    { "Num[%s%-]*[Pp]ad%s*", "N" }, { "Ziffernblock%s*", "N" },
    { "Leertaste", "Lt" }, { "Rücktaste", "Rt" },
    { "SHIFT%-", "S" }, { "STRG%-", "C" }, { "CTRL%-", "C" }, { "ALT%-", "A" },
    { "^s%-", "S" }, { "^c%-", "C" }, { "^a%-", "A" },
    { "([SCA])s%-", "%1S" }, { "([SCA])c%-", "%1C" }, { "([SCA])a%-", "%1A" },
}
function AB.ShortHotkey(text)
    if type(text) ~= "string" or text == "" then return text end
    if _G.RANGE_INDICATOR and text == _G.RANGE_INDICATOR then return text end
    for _, sub in ipairs(HOTKEY_SUBS) do text = text:gsub(sub[1], sub[2]) end
    return text
end

local function ShortenHotkey(b)
    local d = skinned[b]
    local hk = d and d.hotkey
    if not hk or not Opt("shortHotkeys") then return end
    local t = hk:GetText()
    if type(t) ~= "string" then return end
    -- Der Punkt ohne Tastenbelegung zeigt Reichweite - das tut schon die
    -- rote Schicht ueber dem Symbol.
    if Opt("hideRangeDot") and _G.RANGE_INDICATOR and t == _G.RANGE_INDICATOR then
        hk:SetText("")
        return
    end
    local short = AB.ShortHotkey(t)
    if short ~= t then hk:SetText(short) end
end

local hotkeyHooked = {}
local function HookHotkeys(b)
    if hotkeyHooked[b] or not _G.hooksecurefunc then return end
    if type(b.UpdateHotkeys) == "function" then
        hotkeyHooked[b] = true
        _G.hooksecurefunc(b, "UpdateHotkeys", ShortenHotkey)
    end
end

-- Die Abklingzahl in der WeintCodex-Schrift. Ein Schriftobjekt fuer alle
-- Knoepfe: das Spiel setzt die Zahl selbst, man sagt ihm nur, womit.
local cdFont
local function CooldownFont()
    if not _G.CreateFont then return nil end
    cdFont = cdFont or _G.CreateFont("WeintCodexCooldownFont")
    if cdFont and cdFont.SetFont then
        cdFont:SetFont(K.FontPath(), Opt("cooldownSize") or 16, "OUTLINE")
    end
    return cdFont
end

-- Leere Plaetze. Zieht man einen Zauber (das Spiel meldet
-- ACTIONBAR_SHOWGRID), erscheinen sie, damit man ihn ablegen kann.
local gridShown = false
local function ApplyEmpty(b, d, empty)
    local mode = Opt("emptySlots")
    if mode == "game" then
        if d._hiddenEmpty then b:SetAlpha(1) d._hiddenEmpty = nil end
        return
    end
    if mode == "hide" and empty and not gridShown then
        b:SetAlpha(0)
        d._hiddenEmpty = true
    else
        if d._hiddenEmpty then b:SetAlpha(1) d._hiddenEmpty = nil end
    end
end
AB.GridShown = function() return gridShown end

local function Apply(b, d)
    d.border:SetShown(Opt("border"))
    local c = K.GetColor(KEY, "borderColor")
    -- Leere Plaetze nur angedeutet: zwoelf schwarze Kaesten je Leiste
    -- sahen in 6.0.0.5 nach Baustelle aus.
    local empty = IsEmpty(b)
    ApplyEmpty(b, d, empty)
    d.border:SetColor(c.r, c.g, c.b, empty and 0.35 or 1)
    if d.shade then d.shade:SetShown(Opt("iconShade") and not empty) end
    if d.cooldown and d.cooldown.SetCountdownFont and Opt("cooldownFont") then
        local fo = CooldownFont()
        if fo then pcall(d.cooldown.SetCountdownFont, d.cooldown, "WeintCodexCooldownFont") end
    end
    -- Leere Plaetze werfen keinen Schatten: sie sollen kaum auffallen.
    if d.shadow then d.shadow:SetShown(not empty) end
    d.bg:SetColorTexture(0, 0, 0, empty and 0.15 or 0.5)
    if d.hotkey then
        K.SetFont(d.hotkey, Opt("hotkeySize"))
        d.hotkey:SetAlpha(Opt("hotkeys") and 1 or 0)
    end
    if d.count then K.SetFont(d.count, Opt("countSize")) end
    if d.name then d.name:SetAlpha(Opt("macroNames") and 1 or 0) end
    HookHotkeys(b)
    ShortenHotkey(b)
end

local function SkinAll()
    for _, fam in ipairs(FAMILIES) do
        for i = 1, fam[2] do
            local b = _G[fam[1] .. i]
            if type(b) == "table" then
                local d = Skin(b)
                if d then Apply(b, d) end
            end
        end
    end
    if Opt("hideEndCaps") then
        -- Die Greifen/Loewen am Ende der Hauptleiste. Namen je nach
        -- Clientstand verschieden; was fehlt, fehlt.
        local bar = _G.MainMenuBar or _G.MainActionBar
        local caps = bar and bar.EndCaps
        if type(caps) == "table" and caps.Hide then caps:Hide() end
        local art = bar and bar.BorderArt
        if type(art) == "table" and art.SetAlpha then art:SetAlpha(0) end
    end
end
AB.SkinAll = SkinAll

-- Rot, wenn ausser Reichweite: das Spiel meldet es selbst an den Knopf,
-- dieser Haken blendet nur die rote Schicht ein. Der Wert kann nicht geheim sein (er ist
-- der, mit dem das Spiel selbst den Punkt faerbt) - geprueft wird trotzdem.
local function OnRange(self, checksRange, inRange)
    local d = skinned[self]
    if not (d and d.range) then return end
    local checks = K.Bool(checksRange, false)
    local inR = K.Bool(inRange, true)
    d.range:SetShown(Opt("rangeColor") and checks and not inR)
end

--------------------------------------------------
-- Flaeche hinter jeder Leiste
--------------------------------------------------
-- Was ElvUI-Leisten "schick" macht, ist vor allem das: die Knoepfe stehen
-- auf einer gemeinsamen Flaeche, statt einzeln im Bild zu schwimmen. Die
-- Kachel haengt an der Leiste (blendet mit ihr ab, Ruhe und Kampf) und ist
-- an ihrer linken oberen und rechten unteren Taste verankert - so folgt sie
-- jeder Anordnung aus dem Bearbeitungsmodus. Gemessen wird nur ausserhalb
-- des Kampfes; laesst der Client nicht messen, bleibt die Flaeche weg.

local BAR_BUTTONS = {
    { bars = { "MainMenuBar", "MainActionBar" }, family = "ActionButton", n = 12 },
    { bars = { "MultiBarBottomLeft" }, family = "MultiBarBottomLeftButton", n = 12 },
    { bars = { "MultiBarBottomRight" }, family = "MultiBarBottomRightButton", n = 12 },
    { bars = { "MultiBarRight" }, family = "MultiBarRightButton", n = 12 },
    { bars = { "MultiBarLeft" }, family = "MultiBarLeftButton", n = 12 },
    { bars = { "MultiBar5" }, family = "MultiBar5Button", n = 12 },
    { bars = { "MultiBar6" }, family = "MultiBar6Button", n = 12 },
    { bars = { "MultiBar7" }, family = "MultiBar7Button", n = 12 },
    { bars = { "StanceBar" }, family = "StanceButton", n = 10 },
    { bars = { "PetActionBar" }, family = "PetActionButton", n = 10 },
}
local BACKDROP_PAD = 4
AB.backdrops = {}

local function Num(f, method)
    local ok, v = pcall(f[method], f)
    v = ok and K.Plain(v) or nil
    return type(v) == "number" and v or nil
end

-- Linke obere und rechte untere Taste der sichtbaren Knoepfe; nil, wenn
-- es keine gibt oder die Anordnung kein Raster ist.
local function Corners(entry)
    local list = {}
    for i = 1, entry.n do
        local b = _G[entry.family .. i]
        if type(b) == "table" and b.IsShown and b:IsShown() then
            local l, t = Num(b, "GetLeft"), Num(b, "GetTop")
            local r, bt = Num(b, "GetRight"), Num(b, "GetBottom")
            if not (l and t and r and bt) then return nil end
            list[#list + 1] = { b = b, l = l, t = t, r = r, bt = bt }
        end
    end
    if #list == 0 then return nil end
    local minL, maxT, maxR, minB = math.huge, -math.huge, -math.huge, math.huge
    for _, e in ipairs(list) do
        minL, maxT = math.min(minL, e.l), math.max(maxT, e.t)
        maxR, minB = math.max(maxR, e.r), math.min(minB, e.bt)
    end
    local tl, br
    for _, e in ipairs(list) do
        if math.abs(e.l - minL) <= 1 and math.abs(e.t - maxT) <= 1 then tl = e.b end
        if math.abs(e.r - maxR) <= 1 and math.abs(e.bt - minB) <= 1 then br = e.b end
    end
    return tl, br
end

local function UpdateBackdrops()
    if K.InCombat() then return end
    local on = Opt("barBackdrop")
    for _, entry in ipairs(BAR_BUTTONS) do
        local bar
        for _, n in ipairs(entry.bars) do
            if type(_G[n]) == "table" then bar = _G[n] break end
        end
        if bar and not (bar.IsForbidden and bar:IsForbidden()) then
            local bd = AB.backdrops[bar]
            local tl, br
            if on then tl, br = Corners(entry) end
            if tl and br then
                if not bd then
                    bd = CreateFrame("Frame", nil, bar)
                    bd.kachel = K.Kachel(bd, { shadow = 6 })
                    AB.backdrops[bar] = bd
                end
                local lvl = Num(bar, "GetFrameLevel") or 1
                bd:SetFrameLevel(math.max(0, lvl))
                bd:ClearAllPoints()
                bd:SetPoint("TOPLEFT", tl, "TOPLEFT", -BACKDROP_PAD, BACKDROP_PAD)
                bd:SetPoint("BOTTOMRIGHT", br, "BOTTOMRIGHT", BACKDROP_PAD, -BACKDROP_PAD)
                bd:Show()
            elseif bd then
                bd:Hide()
            end
        end
    end
end
AB.UpdateBackdrops = UpdateBackdrops

-- Die Blaetterpfeile und die Seitenzahl der Hauptleiste. Umblaettern geht
-- weiter ueber die Tasten des Spiels (Umschalt+Mausrad, Umschalt+1..6).
local function HidePaging()
    if not Opt("hidePaging") then return end
    local main = _G.MainActionBar or _G.MainMenuBar
    local parts = {
        main and main.ActionBarPageNumber, _G.ActionBarUpButton, _G.ActionBarDownButton,
        _G.MainMenuBarPageNumber, _G.MainMenuBarArtFrame and _G.MainMenuBarArtFrame.PageNumber,
    }
    for i = 1, 5 do
        local f = parts[i]
        if type(f) == "table" and f.SetAlpha and not (f.IsForbidden and f:IsForbidden()) then
            KeepHidden(f)
            if f.EnableMouse and not K.InCombat() then pcall(f.EnableMouse, f, false) end
        end
    end
end
AB.HidePaging = HidePaging

local function Arrange()
    UpdateBackdrops()
    HidePaging()
end

--------------------------------------------------
-- Mikromenue und Taschenleiste
--------------------------------------------------

local function Frame(...)
    for _, n in ipairs({ ... }) do
        local f = _G[n]
        if type(f) == "table" and f.SetPoint and not (f.IsForbidden and f:IsForbidden()) then return f end
    end
    return nil
end

local placing = false
local function Place()
    if placing or K.InCombat() then return end
    placing = true
    local micro = Frame("MicroMenuContainer", "MicroMenu")
    if micro and Opt("microMenu") == "left" then
        micro:SetScale((Opt("microScale") or 85) / 100)
        micro:ClearAllPoints()
        micro:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 4, 4)
    end
    local bags = Frame("BagsBar")
    if bags and Opt("bagsBar") == "right" then
        bags:ClearAllPoints()
        bags:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -4, 4)
    end
    placing = false
end
AB.Place = Place

-- Ruhe und Kampf (ui/presence.lua): Leiste 1 und die weiteren Leisten
-- getrennt - wer in Ruhe nur die Hauptleiste sehen will, soll es koennen.
local MAIN_BARS = { "MainMenuBar", "MainActionBar" }
local OTHER_BARS = { "MultiBarBottomLeft", "MultiBarBottomRight", "MultiBarRight", "MultiBarLeft",
    "MultiBar5", "MultiBar6", "MultiBar7", "StanceBar", "PetActionBar" }
local function Named(list)
    return function()
        local out = {}
        for _, n in ipairs(list) do
            if type(_G[n]) == "table" then out[#out + 1] = _G[n] end
        end
        return out
    end
end

local function Enable()
    SkinAll()
    K.AfterCombat(Place)
    K.AfterCombat(Arrange)
    WeintCodex.UIPresence.Register("mainbar", Named(MAIN_BARS), "fade_mainbar")
    WeintCodex.UIPresence.Register("bars", Named(OTHER_BARS), "fade_bars")
    -- Der Bearbeitungsmodus setzt beide beim Laden eines Layouts und beim
    -- Verlassen neu; danach wieder an unseren Platz.
    if _G.hooksecurefunc then
        for _, names in ipairs({ { "MicroMenuContainer", "MicroMenu" }, { "BagsBar" } }) do
            local f = Frame(unpack(names))
            if f and type(f.ApplySystemAnchor) == "function" then
                _G.hooksecurefunc(f, "ApplySystemAnchor", function() K.AfterCombat(Place) end)
            end
        end
        local emf = _G.EditModeManagerFrame
        if type(emf) == "table" and type(emf.ExitEditMode) == "function" then
            _G.hooksecurefunc(emf, "ExitEditMode", function() K.AfterCombat(Place) K.AfterCombat(Arrange) end)
        end
    end
    -- Aeltere Clients setzen die Tastenkuerzel ueber eine globale Funktion.
    if _G.hooksecurefunc and _G.ActionButton_UpdateHotkeys then
        _G.hooksecurefunc("ActionButton_UpdateHotkeys", function(b) ShortenHotkey(b) end)
    end
    if _G.hooksecurefunc and _G.ActionButton_UpdateRangeIndicator then
        _G.hooksecurefunc("ActionButton_UpdateRangeIndicator", OnRange)
    end
    -- Leisten, die das Spiel spaeter anlegt oder umbaut (Bearbeitungsmodus,
    -- Haltungen), bekommen ihr Aussehen beim naechsten Aktualisieren.
    local ev = CreateFrame("Frame")
    for _, e in ipairs({ "PLAYER_ENTERING_WORLD", "UPDATE_BONUS_ACTIONBAR",
        "UPDATE_SHAPESHIFT_FORMS", "PET_BAR_UPDATE", "ACTIONBAR_SLOT_CHANGED",
        "ACTIONBAR_SHOWGRID", "ACTIONBAR_HIDEGRID" }) do
        pcall(ev.RegisterEvent, ev, e)
    end
    ev:SetScript("OnEvent", function(_, event)
        if event == "ACTIONBAR_SHOWGRID" then gridShown = true
        elseif event == "ACTIONBAR_HIDEGRID" then gridShown = false end
        SkinAll()
        if event == "PLAYER_ENTERING_WORLD" then K.AfterCombat(Place) K.AfterCombat(Arrange) end
    end)
end

local function px(v) return string.format("%d px", v) end

K.Register({
    key = KEY, group = "ui", order = 30,
    title = "Aktionsleisten",
    description = "Die Knöpfe des Spiels im Stil von WeintCodex: flach, mit feinem Rand, eigener Schrift und rotem Symbol außer Reichweite.",
    defaults = defaults,
    Enable = Enable,
    OnSetting = function() if K.IsActive(KEY) then SkinAll() K.AfterCombat(Place) K.AfterCombat(Arrange) end end,
    pages = {
        { key = "allgemein", label = "Allgemein", build = function(B)
            B:Section("Knöpfe")
            B:Row({ type = "toggle", label = "Rand anzeigen", key = "border" },
                  { type = "color", label = "Randfarbe", key = "borderColor",
                    disabled = function() return not K.Get(KEY, "border") end })
            B:Row({ type = "toggle", label = "Symbol rot außer Reichweite", key = "rangeColor" },
                  { type = "toggle", label = "Greifen an den Enden ausblenden", key = "hideEndCaps", reload = true })
            B:Section("Leisten")
            B:Row({ type = "toggle", label = "Fläche hinter jeder Leiste", key = "barBackdrop",
                    description = "Die Knöpfe stehen auf einer gemeinsamen dunklen Fläche mit feinem Rand." },
                  { type = "toggle", label = "Blätterpfeile ausblenden", key = "hidePaging", reload = true,
                    description = "Pfeile und Seitenzahl neben Leiste 1. Umblättern geht weiter mit Umschalt+Mausrad." })
            B:Section("Aussehen")
            B:Row({ type = "dropdown", label = "Leere Plätze", key = "emptySlots", items = {
                        { value = "hide",  text = "Ausblenden (beim Ziehen sichtbar)" },
                        { value = "faint", text = "Nur angedeutet" },
                        { value = "game",  text = "Wie im Spiel" } } },
                  { type = "toggle", label = "Schatten am Symbol", key = "iconShade" })
            B:Row({ type = "toggle", label = "Abklingzahl in WeintCodex-Schrift", key = "cooldownFont", reload = true },
                  { type = "slider", label = "Größe der Abklingzahl", key = "cooldownSize", min = 10, max = 24, step = 1, format = px,
                    disabled = function() return not K.Get(KEY, "cooldownFont") end })
            B:Row({ type = "toggle", label = "Reichweitenpunkt ausblenden", key = "hideRangeDot",
                    description = "Der Punkt auf Knöpfen ohne Taste – die rote Schicht zeigt die Reichweite schon." },
                  { type = "empty" })
            B:Section("Texte")
            B:Row({ type = "toggle", label = "Tastenkürzel", key = "hotkeys" },
                  { type = "slider", label = "Größe der Tastenkürzel", key = "hotkeySize", min = 8, max = 18, step = 1, format = px,
                    disabled = function() return not K.Get(KEY, "hotkeys") end })
            B:Row({ type = "toggle", label = "Kurze Tastenkürzel", key = "shortHotkeys",
                    description = "„M4“ statt „Maustaste 4“, „S1“ statt „s-1“." },
                  { type = "empty" })
            B:Row({ type = "toggle", label = "Makronamen", key = "macroNames" },
                  { type = "slider", label = "Größe der Stapelzahl", key = "countSize", min = 8, max = 20, step = 1, format = px })
            B:Section("Anordnung")
            B:Row({ type = "dropdown", label = "Mikromenü", key = "microMenu", reload = true, items = {
                        { value = "left", text = "Klein unten links" },
                        { value = "game", text = "Wie im Spiel" } } },
                  { type = "slider", label = "Größe des Mikromenüs", key = "microScale", min = 60, max = 120, step = 5,
                    format = function(v) return string.format("%d %%", v) end,
                    disabled = function() return K.Get(KEY, "microMenu") ~= "left" end })
            B:Row({ type = "dropdown", label = "Taschenleiste", key = "bagsBar", reload = true, items = {
                        { value = "right", text = "Unten rechts" },
                        { value = "game",  text = "Wie im Spiel" } } },
                  { type = "empty" })
            B:Note("Solange hier nicht „Wie im Spiel“ steht, bestimmt WeintCodex den Platz von Mikromenü und Taschenleiste – auch nach dem Bearbeitungsmodus.")
            B:Section("Lage und Größe")
            B:Note("Wo die Leisten stehen, wie groß sie sind, wie viele es gibt und wie weit die Knöpfe auseinanderstehen („Symbolabstand“), stellst du im Bearbeitungsmodus des Spiels ein (Esc → Bearbeitungsmodus). Tipp: alle Leisten auf dieselbe Symbolgröße und Symbolabstand 2 – dann stehen die Flächen bündig übereinander. Eigene Leisten baut WeintCodex bewusst nicht: fürs Umblättern bei Haltung, Gestalt und Fahrzeug bräuchten sie eine Funktion, die dem Forever-Client derzeit fehlt.")
        end },
    },
})
