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
    macroNames   = false,
    countSize    = 12,
    rangeColor   = true,
    hideEndCaps  = true,
    microMenu    = "left",   -- left | game
    microScale   = 85,
    bagsBar      = "right",  -- right | game
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

local function Skin(b)
    if skinned[b] then return skinned[b] end
    if b.IsForbidden and b:IsForbidden() then return nil end
    local d = {}

    -- Der Steinrahmen: nicht entfernen (das Spiel setzt ihn bei jedem
    -- Aktualisieren neu), sondern unsichtbar machen.
    local normal = b.GetNormalTexture and b:GetNormalTexture()
    if normal then normal:SetAlpha(0) end
    for _, key in ipairs({ "SlotArt", "SlotBackground", "IconMask", "Border", "FloatingBG", "RightDivider", "BottomDivider" }) do
        local r = Region(b, key)
        if r and r.SetAlpha then r:SetAlpha(0) end
    end
    local icon = Region(b, "icon") or Region(b, "Icon")
    if icon then
        if icon.SetTexCoord then icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) end
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

    d.bg = b:CreateTexture(nil, "BACKGROUND", nil, -8)
    d.bg:SetAllPoints(b)
    d.bg:SetColorTexture(0, 0, 0, 0.5)
    d.border = K.Border(b, 1, 0, 0, 0, 1, "OVERLAY")

    d.hotkey = Region(b, "HotKey")
    d.count  = Region(b, "Count")
    d.name   = Region(b, "Name")
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

local function Apply(b, d)
    d.border:SetShown(Opt("border"))
    local c = K.GetColor(KEY, "borderColor")
    -- Leere Plaetze nur angedeutet: zwoelf schwarze Kaesten je Leiste
    -- sahen in 6.0.0.5 nach Baustelle aus.
    local empty = IsEmpty(b)
    d.border:SetColor(c.r, c.g, c.b, empty and 0.35 or 1)
    d.bg:SetColorTexture(0, 0, 0, empty and 0.15 or 0.5)
    if d.hotkey then
        K.SetFont(d.hotkey, Opt("hotkeySize"))
        d.hotkey:SetAlpha(Opt("hotkeys") and 1 or 0)
    end
    if d.count then K.SetFont(d.count, Opt("countSize")) end
    if d.name then d.name:SetAlpha(Opt("macroNames") and 1 or 0) end
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

local function Enable()
    SkinAll()
    K.AfterCombat(Place)
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
            _G.hooksecurefunc(emf, "ExitEditMode", function() K.AfterCombat(Place) end)
        end
    end
    if _G.hooksecurefunc and _G.ActionButton_UpdateRangeIndicator then
        _G.hooksecurefunc("ActionButton_UpdateRangeIndicator", OnRange)
    end
    -- Leisten, die das Spiel spaeter anlegt oder umbaut (Bearbeitungsmodus,
    -- Haltungen), bekommen ihr Aussehen beim naechsten Aktualisieren.
    local ev = CreateFrame("Frame")
    for _, e in ipairs({ "PLAYER_ENTERING_WORLD", "UPDATE_BONUS_ACTIONBAR",
        "UPDATE_SHAPESHIFT_FORMS", "PET_BAR_UPDATE", "ACTIONBAR_SLOT_CHANGED" }) do
        pcall(ev.RegisterEvent, ev, e)
    end
    ev:SetScript("OnEvent", function(_, event)
        SkinAll()
        if event == "PLAYER_ENTERING_WORLD" then K.AfterCombat(Place) end
    end)
end

local function px(v) return string.format("%d px", v) end

K.Register({
    key = KEY, group = "ui", order = 30,
    title = "Aktionsleisten",
    description = "Die Knöpfe des Spiels im Stil von WeintCodex: flach, mit feinem Rand, eigener Schrift und rotem Symbol außer Reichweite.",
    defaults = defaults,
    Enable = Enable,
    OnSetting = function() if K.IsActive(KEY) then SkinAll() K.AfterCombat(Place) end end,
    pages = {
        { key = "allgemein", label = "Allgemein", build = function(B)
            B:Section("Knöpfe")
            B:Row({ type = "toggle", label = "Rand anzeigen", key = "border" },
                  { type = "color", label = "Randfarbe", key = "borderColor",
                    disabled = function() return not K.Get(KEY, "border") end })
            B:Row({ type = "toggle", label = "Symbol rot außer Reichweite", key = "rangeColor" },
                  { type = "toggle", label = "Greifen an den Enden ausblenden", key = "hideEndCaps", reload = true })
            B:Section("Texte")
            B:Row({ type = "toggle", label = "Tastenkürzel", key = "hotkeys" },
                  { type = "slider", label = "Größe der Tastenkürzel", key = "hotkeySize", min = 8, max = 18, step = 1, format = px,
                    disabled = function() return not K.Get(KEY, "hotkeys") end })
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
            B:Note("Wo die Leisten stehen, wie groß sie sind und wie viele es gibt, stellst du im Bearbeitungsmodus des Spiels ein (Esc → Bearbeitungsmodus). Eigene Leisten baut WeintCodex bewusst nicht: fürs Umblättern bei Haltung, Gestalt und Fahrzeug bräuchten sie eine Funktion, die dem Forever-Client derzeit fehlt.")
        end },
    },
})
