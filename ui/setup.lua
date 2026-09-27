--------------------------------------------------
-- WeintCodex :: Oberflaeche - Einrichtung beim ersten Mal
--------------------------------------------------
-- Beta-Test 6.6.1.0: "Wenn man das UI das erste Mal nutzt, sollen die
-- Fenster direkt voreingestellt sein wie bei Ellesmere. Ein Reload danach
-- packt alle Fenster auf die richtige Position. Danach kann man immer noch
-- im Bearbeitungs- oder Gestaltungsmodus verschieben."
--
-- ZWEI ARTEN VON FENSTERN. Die eigenen Rahmen von WeintCodex stehen ohne
-- Zutun richtig: ihre Standardplaetze kommen aus ui/layout.lua. Die Rahmen
-- des Spiels (seit 6.6.0.9 vor allem Gruppe und Schlachtzug) stellt der
-- Bearbeitungsmodus des Spiels - und dessen Layouts gehoeren dem Spiel.
-- Dafuer legt WeintCodex EINMAL ein eigenes Layout "WeintCodex" an:
--   * Grundlage ist das Layout, das der Spieler gerade nutzt (seit
--     6.6.1.2, siehe ES.Base) - alles ausser Gruppe und Schlachtzug
--     bleibt, wo es war,
--   * Gruppenrahmen schlachtzugsartig (nur die zeigen HoTs), ohne
--     Blizzards Rahmenlinien (den Rand zeichnet WeintCodex),
--   * Gruppe und Schlachtzug an den Plaetzen der WeintCodex-Kacheln
--     (ui/layout.lua, gf_party / gf_raid),
-- und macht es zum aktiven Layout. Danach NEU LADEN - zwei Gruende: erst
-- dann stellt das Spiel alles nach dem neuen Layout, und erst dann liest
-- es das Layout frisch vom Server. Bis dahin gilt es als "von WeintCodex
-- beruehrt", und das Spiel koennte im Kampf Aktionen sperren.
--
-- WOHER WEISS WEINTCODEX, DASS ES SCHON EINGERICHTET IST? Am Layout
-- selbst: gibt es eins namens "WeintCodex", fragt nichts mehr. Das liegt
-- auf dem Server und kommt auch dann mit, wenn der Beta-Client die
-- SavedVariables vergisst.
--
-- Ob C_EditMode im Forever-Client genauso heisst und funktioniert, ist
-- ungeprueft. Fehlt etwas, sagt das Fenster es und nennt die Handgriffe
-- im Bearbeitungsmodus - nie ein stilles "fertig".
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UISetup = {}

local ES = WeintCodex.UISetup
local K  = WeintCodex.UIKit
local C  = WeintCodex.Colors
local F  = WeintCodex.Fonts

ES.LAYOUT_NAME = "WeintCodex"

local function Say(text)
    print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " " .. text)
end

local function Copy(t)
    if type(t) ~= "table" then return t end
    local out = {}
    for k, v in pairs(t) do out[k] = Copy(v) end
    return out
end

--------------------------------------------------
-- Das Layout
--------------------------------------------------

-- Die Layouts des Spiels oder nil, Grund.
local function Layouts()
    local em = _G.C_EditMode
    if not (em and em.GetLayouts and em.SaveLayouts) then return nil, "C_EditMode fehlt" end
    local ok, info = pcall(em.GetLayouts)
    if not ok or type(info) ~= "table" or type(info.layouts) ~= "table" then
        return nil, "GetLayouts antwortet nicht"
    end
    return info
end

-- Gibt es das Layout schon? true / false / nil (der Client sagt es nicht).
function ES.HasLayout()
    local info = Layouts()
    if not info then return nil end
    for _, l in ipairs(info.layouts) do
        if l.layoutName == ES.LAYOUT_NAME then return true end
    end
    return false
end

-- Die Vorlagen des Spiels ("Modern", "Klassisch") - nur ihre Zahl zaehlt
-- fuer den Index des aktiven Layouts, und "Modern" ist die Grundlage.
local function Presets()
    local pm = _G.EditModePresetLayoutManager
    if type(pm) == "table" and type(pm.GetCopyOfPresetLayouts) == "function" then
        local ok, list = pcall(pm.GetCopyOfPresetLayouts, pm)
        if ok and type(list) == "table" and #list > 0 then return list end
    end
    return nil
end

local function SetSetting(sys, setting, value)
    if type(setting) ~= "number" then return false end
    sys.settings = sys.settings or {}
    for _, s in ipairs(sys.settings) do
        if s.setting == setting then s.value = value return true end
    end
    sys.settings[#sys.settings + 1] = { setting = setting, value = value }
    return true
end

local function Anchor(sys, key)
    local p = K.LAYOUT[key]
    if not p then return end
    sys.anchorInfo = { point = p.point, relativeTo = "UIParent", relativePoint = p.relPoint,
                       offsetX = p.x, offsetY = p.y }
    sys.isInDefaultPosition = false
end

-- Die Systeme des Layouts auf WeintCodex stellen. Gibt zurueck, was
-- gesetzt wurde (fuer Auskunft und Prueflauf).
function ES.Adjust(systems)
    local E = _G.Enum or {}
    local SYS = E.EditModeSystem and E.EditModeSystem.UnitFrame
    local IDX = E.EditModeUnitFrameSystemIndices or {}
    local SET = E.EditModeUnitFrameSetting or {}
    local done = {}
    for _, sys in ipairs(systems or {}) do
        if sys.system == SYS and sys.systemIndex == IDX.Party then
            if SetSetting(sys, SET.UseRaidStylePartyFrames, 1) then done.raidStyle = true end
            if SetSetting(sys, SET.DisplayBorder, 0) then done.partyBorder = true end
            Anchor(sys, "gf_party")
            done.party = true
        elseif sys.system == SYS and sys.systemIndex == IDX.Raid then
            if SetSetting(sys, SET.DisplayBorder, 0) then done.raidBorder = true end
            Anchor(sys, "gf_raid")
            done.raid = true
        end
    end
    return done
end

-- WORAUF WIRD AUFGEBAUT? Auf dem Layout, das der Spieler gerade nutzt -
-- nur Gruppe und Schlachtzug aendern sich. 6.6.1.1 nahm die Vorlage
-- "Modern" des Spiels: Aktionsleisten und Questliste sprangen auf die
-- Standardplaetze von Forever (Beta-Test: Leisten unten links statt
-- mittig). Ist das aktive Layout schon "WeintCodex" (neu einrichten),
-- zaehlt das erste andere eigene Layout, sonst die Vorlage.
-- Gibt das Layout und seinen Namen zurueck.
function ES.Base(info, presets)
    local nPre = presets and #presets or 2
    local active = tonumber(info.activeLayout) or 0
    if active > nPre then
        local l = info.layouts[active - nPre]
        if l and l.layoutName ~= ES.LAYOUT_NAME and type(l.systems) == "table" then return l, l.layoutName end
        for _, o in ipairs(info.layouts) do
            if o.layoutName ~= ES.LAYOUT_NAME and type(o.systems) == "table" then return o, o.layoutName end
        end
        local p = presets and presets[1]
        return p, p and p.layoutName
    end
    local p = presets and (presets[active] or presets[1])
    return p, p and p.layoutName
end

function ES.BaseName()
    local info = Layouts()
    if not info then return nil end
    local _, name = ES.Base(info, Presets())
    return name
end

-- Das Layout anlegen und aktiv setzen. true oder false, Grund.
function ES.Apply()
    if K.InCombat() then return false, "im Kampf" end
    local info, why = Layouts()
    if not info then return false, why end
    local presets = Presets()
    local base = ES.Base(info, presets)
    if not (base and type(base.systems) == "table") then return false, "keine Grundlage (kein Layout lesbar)" end

    local layout = Copy(base)
    layout.layoutName = ES.LAYOUT_NAME
    local LT = _G.Enum and _G.Enum.EditModeLayoutType
    layout.layoutType = LT and LT.Account or layout.layoutType
    local done = ES.Adjust(layout.systems)
    if not done.party then return false, "Gruppenrahmen im Layout nicht gefunden" end

    -- Ein altes "WeintCodex" (von einem abgebrochenen Versuch) ersetzen.
    local slot
    for i, l in ipairs(info.layouts) do
        if l.layoutName == ES.LAYOUT_NAME then slot = i end
    end
    slot = slot or (#info.layouts + 1)
    info.layouts[slot] = layout
    info.activeLayout = (presets and #presets or 2) + slot

    local em = _G.C_EditMode
    local ok, err = pcall(em.SaveLayouts, info)
    if not ok then return false, "SaveLayouts: " .. tostring(err) end
    if em.SetActiveLayout then pcall(em.SetActiveLayout, info.activeLayout) end
    ES.done = done
    return true
end

--------------------------------------------------
-- Das Fenster (dieselbe Form wie die Frage beim Einloggen)
--------------------------------------------------

local WIN_W, WIN_H = 520, 300
local dimmer, win, eyebrow, title, body
local buttons, byKey = {}, {}

local function Close() if dimmer then dimmer:Hide() end end

local function Build()
    if dimmer then return end
    dimmer = CreateFrame("Frame", "WeintCodexUISetup", UIParent)
    dimmer:SetAllPoints(UIParent)
    dimmer:SetFrameStrata("DIALOG")
    dimmer:EnableMouse(true)
    local shade = dimmer:CreateTexture(nil, "BACKGROUND")
    shade:SetAllPoints(dimmer)
    shade:SetColorTexture(0, 0, 0, 0.6)
    dimmer:Hide()

    win = CreateFrame("Frame", nil, dimmer)
    win:SetSize(WIN_W, WIN_H)
    win:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
    win:SetFrameLevel(dimmer:GetFrameLevel() + 10)
    local bg = win:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(win)
    bg:SetColorTexture(unpack(C.surface2))
    WeintCodex.DrawBorder(win, C.borderStrong[1], C.borderStrong[2], C.borderStrong[3], 1, 1)
    local top = win:CreateTexture(nil, "ARTWORK")
    top:SetHeight(1)
    top:SetPoint("TOPLEFT", win, "TOPLEFT", 8, 0)
    top:SetPoint("TOPRIGHT", win, "TOPRIGHT", -8, 0)
    top:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.34)

    eyebrow = K.NewText(win)
    eyebrow:SetFont(F.mono, 10, "")
    eyebrow:SetTextColor(unpack(C.accent))
    eyebrow:SetPoint("TOPLEFT", win, "TOPLEFT", 28, -26)
    title = K.NewText(win)
    title:SetFont(F.sansBold, 20, "")
    title:SetTextColor(unpack(C.textBright))
    title:SetPoint("TOPLEFT", eyebrow, "BOTTOMLEFT", 0, -8)
    title:SetWidth(WIN_W - 56)
    title:SetJustifyH("LEFT")
    body = K.NewText(win)
    body:SetFont(F.sans, 13, "")
    body:SetTextColor(unpack(C.textNormal))
    body:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -14)
    body:SetWidth(WIN_W - 56)
    body:SetJustifyH("LEFT")
    body:SetJustifyV("TOP")
    body:SetSpacing(4)
end

local function SetButtons(defs)
    for _, b in ipairs(buttons) do b:Hide() end
    wipe(buttons)
    local anchor
    for i = #defs, 1, -1 do
        local d = defs[i]
        local b = byKey[d.key]
        if not b then
            if d.reload then
                b = K.ReloadButton(win, { text = d.text, height = 34, size = 12, backdrop = "surface2",
                    onClick = d.onClick })
            else
                b = WeintCodex.CreateButton(win, { text = d.text, kind = d.kind or "secondary", height = 34,
                    size = 12, backdrop = "surface2", onClick = d.onClick })
            end
            byKey[d.key] = b
        end
        b:ClearAllPoints()
        b:Show()
        if anchor then b:SetPoint("RIGHT", anchor, "LEFT", -10, 0)
        else b:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", -28, 24) end
        anchor = b
        b._key = d.key
        buttons[#buttons + 1] = b
    end
end

local function SetText(eb, t, text)
    eyebrow:SetText(WeintCodex.Spaced(WeintCodex.Upper(eb)))
    title:SetText(t)
    body:SetText(text)
    local ok, h = pcall(body.GetStringHeight, body)
    if not ok or type(h) ~= "number" then h = 0 end
    win:SetHeight(math.max(WIN_H, math.ceil(h) + 176))
end

local ShowDone, ShowFailed

local function ShowQuestion()
    local baseName = ES.BaseName()
    local basis = baseName and ("Grundlage ist dein Layout „" .. tostring(baseName) .. "“ – Aktionsleisten und alles"
        .. " andere bleiben, wo sie sind; nur Gruppe und Schlachtzug ändern sich.")
        or "Welches Layout du gerade nutzt, sagt das Spiel nicht – dann baut WeintCodex auf der Vorlage des Spiels auf."
    SetText("Einrichtung",
        "WeintCodex einrichten?",
        "WeintCodex legt im Bearbeitungsmodus des Spiels ein Layout „WeintCodex“ an: Gruppe und Schlachtzug als"
        .. " schlachtzugsartige Rahmen mit HoTs, Buffs und Schilden, ohne Blizzards Linien, an den Plätzen von"
        .. " WeintCodex. " .. basis .. "\n\n"
        .. "Danach einmal neu laden. Verschieben kannst du hinterher alles: eigene Rahmen im Gestaltungsmodus,"
        .. " die des Spiels im Bearbeitungsmodus. Dein bisheriges Layout bleibt erhalten und lässt sich dort"
        .. " jederzeit wieder wählen.")
    SetButtons({
        { key = "later", text = "Später", kind = "secondary", onClick = function()
            Close()
            Say("Einrichten geht jederzeit mit /wcui einrichten.")
        end },
        { key = "apply", text = "Einrichten", kind = "primary", onClick = function()
            local ok, why = ES.Apply()
            if ok then ShowDone() else ShowFailed(why) end
        end },
    })
end

ShowDone = function()
    SetText("Einrichtung",
        "Fertig – jetzt neu laden",
        "Das Layout „WeintCodex“ ist angelegt und aktiv. Nach dem Neuladen stehen alle Fenster an ihrem Platz."
        .. "\n\nBis dahin bitte nicht in den Kampf: das Spiel stellt erst nach dem Neuladen alles sauber.")
    SetButtons({
        { key = "reload", text = "Jetzt neu laden", reload = true },
    })
end

ShowFailed = function(why)
    SetText("Einrichtung",
        "Das Layout ließ sich nicht anlegen",
        "Grund: " .. tostring(why) .. ".\n\nDeine eigenen WeintCodex-Rahmen stehen trotzdem richtig. Für die Gruppe"
        .. " bitte von Hand: Esc → Bearbeitungsmodus → Gruppenrahmen anklicken → „Schlachtzugsartige"
        .. " Gruppenrahmen verwenden“ an, „Rahmen anzeigen“ aus, speichern.")
    SetButtons({
        { key = "close", text = "Schließen", kind = "secondary", onClick = Close },
    })
end

function ES.Show()
    if K.InCombat() then
        Say("Nach dem Kampf – im Kampf lässt sich die Oberfläche nicht einrichten.")
        K.AfterCombat(ES.Show)
        return
    end
    Build()
    ShowQuestion()
    dimmer:Show()
end

function ES.IsShown() return dimmer ~= nil and dimmer:IsShown() end
function ES.Button(key)
    for _, b in ipairs(buttons) do if b._key == key then return b end end
    return nil
end
function ES.BodyText() return body and body:GetText() or "" end

-- Beim ersten echten Einloggen fragen, wenn es noch kein Layout gibt -
-- nie nach einem /reload (sonst stuende die Frage nach "Später" bei jedem
-- Neuladen wieder da), nie ueber der Einfuehrung, nie im Kampf.
local asked = false
function ES.MaybeAsk()
    if asked or ES.HasLayout() ~= false then return end
    if WeintCodex.Onboarding and WeintCodex.Onboarding.IsShowing and WeintCodex.Onboarding.IsShowing() then
        return   -- kommt ueber OnClosed wieder
    end
    local WL = WeintCodex.UIWelcome
    if WL and WL.IsShown and WL.IsShown() then return end
    asked = true
    K.AfterCombat(ES.Show)
end
ES._ResetAsked = function() asked = false end

if WeintCodex.Onboarding and WeintCodex.Onboarding.OnClosed then
    WeintCodex.Onboarding.OnClosed(function() if not ES._reload then ES.MaybeAsk() end end)
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:SetScript("OnEvent", function(_, _, isInitialLogin, isReloadingUi)
    if not (isInitialLogin or isReloadingUi) then return end
    ES._reload = isReloadingUi and true or false
    if isReloadingUi or not K.UIEnabled() then return end
    if _G.C_Timer and _G.C_Timer.After then _G.C_Timer.After(2, ES.MaybeAsk) end
end)
