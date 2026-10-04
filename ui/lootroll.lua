--------------------------------------------------
-- WeintCodex :: Oberflaeche - Wuerfeln um Beute (6.10.3.1)
--------------------------------------------------
-- Das kleine Fenster, in dem eine Gruppe um einen Gegenstand wuerfelt
-- (GroupLootFrame1..4: Symbol, Name, Bedarf/Gier/Passen, Zeitleiste).
-- Beute gehoert nicht zur Klasse: GOLD (S.CALM), wie das Beutefenster und
-- die Dialoge des Spiels. Beta-Test 6.10.3.0: "Das muss noch anders" -
-- dunkler Toast mit Namensschild, Rahmen und Zierecke in der Farbe der
-- Qualitaet, die Zeitleiste als olivgruener Balken in einer Rinne.
--
--   Grund      .Background und .Border (beide "Interface\LootFrame\
--              LootToast", nur andere Ausschnitte) weg, eine Kachel wie
--              jedes Fenster, oben Licht und eine feine Kante in Gold.
--   Symbol     beschnitten, der leuchtende Rahmen des Spiels
--              (IconFrame.Border, Atlas "loottoast-itemborder-*") weg, statt
--              seiner 1 px in der Farbe der Qualitaet - wie in den Taschen
--              (ab "Selten"; darunter schwarz).
--   Name       Schrift der Oberflaeche; die Farbe der Qualitaet setzt das
--              Spiel selbst und behaelt sie.
--   Zeit       flacher Balken in Gold auf dunklem Grund mit 1 px Rand.
--              Das Spiel legt die Leiste bei jedem Zeigen UNTER das Fenster
--              (dort schnitt der Toast ein Loch fuer sie) - unter einer
--              Kachel waere sie unsichtbar. Sie kommt bei jedem Zeigen
--              wieder darueber.
--
-- Unveraendert: Bedarf, Gier, Passen und Transmog (Symbole mit Bedeutung,
-- grau, wenn das Spiel sie sperrt), die Wuerfel-Animation, Klick, Tooltip,
-- jede Position. Geaendert werden nur Bilder und Schrift - kein Skript am
-- Fenster des Spiels ausser einem angehaengten OnShow.
--
-- NICHT GEMESSEN: /wcui fenster ueber dem Wurf meldete im Beta-Test nur
-- "BottomManagedFrameContainer" ohne ein Bild - der Wurf war schon vorbei.
-- Gebaut nach dem Quelltext des Spiels (Blizzard_UIPanels_Game/Mainline/
-- GroupLootFrame.xml, GroupLootFrameTemplate) und dem Bildschirmfoto, das
-- genau diesen Aufbau zeigt. Was dort noch anders aussieht, sagt
-- /wcui fenster mit der Maus ueber einem laufenden Wurf.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UILootRoll = {}

local LR = WeintCodex.UILootRoll
local K = WeintCodex.UIKit
local C = WeintCodex.Colors
local GC = WeintCodex.GameColors
local W = WeintCodex.UIWindows
local S = WeintCodex.UIStyle

LR.LABEL = "Würfeln um Beute"
LR.FRAMES = { "GroupLootFrame1", "GroupLootFrame2", "GroupLootFrame3", "GroupLootFrame4" }
LR.STYLE = S.CALM
LR.LIGHT = 40               -- Hoehe des Lichts von oben (der Toast ist 67 hoch)
LR.EDGE = 0.5               -- Deckkraft der Kante in Gold
LR.NAME_W = 134             -- Name bis kurz vor Bedarf (Spiel: 125)
LR.QUALITY_MIN = 2          -- ab "Selten" farbiger Rand, wie in den Taschen

local done = setmetatable({}, { __mode = "k" })
LR.done = done

local function Usable(r)
    return type(r) == "table" and not (r.IsForbidden and r:IsForbidden())
end

-- Farbe der Qualitaet des Wurfs, oder nil (darunter, oder unbekannt).
function LR.QualityColor(f)
    local id = f and f.rollID
    if type(id) ~= "number" or type(_G.GetLootRollItemInfo) ~= "function" then return nil end
    local ok, _, _, _, q = pcall(_G.GetLootRollItemInfo, id)
    q = ok and K.Plain(q) or nil
    if type(q) ~= "number" or q < LR.QUALITY_MIN then return nil end
    if _G.C_Item and type(_G.C_Item.GetItemQualityColor) == "function" then
        local cok, r, g, b = pcall(_G.C_Item.GetItemQualityColor, q)
        if cok and type(r) == "number" then return r, g, b end
    end
    local t = type(_G.ITEM_QUALITY_COLORS) == "table" and _G.ITEM_QUALITY_COLORS[q]
    if type(t) == "table" and type(t.r) == "number" then return t.r, t.g, t.b end
    return nil
end

-- Bei jedem Zeigen (nach dem OnShow des Spiels): Rand des Symbols in der
-- Qualitaet, Zeitleiste ueber die Kachel.
function LR.Refresh(f)
    local d = done[f]
    if not d then return end
    if d.quality then
        local r, g, b = LR.QualityColor(f)
        if r then d.quality:SetColor(r, g, b, 1) else d.quality:SetColor(0, 0, 0, 1) end
        d.qualityColored = r and true or false
    end
    local timer = f.Timer
    if Usable(timer) and timer.SetFrameLevel and f.GetFrameLevel then
        local lvl = K.Plain(f:GetFrameLevel())
        if type(lvl) == "number" then timer:SetFrameLevel(lvl + 1) end
    end
end

function LR.Skin(f)
    if not Usable(f) or done[f] or not f.CreateTexture then return done[f] end
    local d = {}
    done[f] = d
    local own = W.own
    W.Hide(f.Background)
    W.Hide(f.Border)
    d.kachel = K.Kachel(f, { alpha = 0.96 })
    own[d.kachel.bg], own[d.kachel.light] = true, true
    S.Scope(f, LR.STYLE)
    local accent = S.Accent(LR.STYLE.accent)
    local l = GC.atmosLight
    d.light = S.TopLight(f, f, l, l[4], LR.LIGHT, -5)
    d.edge = S.Under(S.Divider(f, accent, LR.EDGE, 0), -3)
    S.PlaceTop(d.edge, f, 10, -1)

    local icf = f.IconFrame
    if Usable(icf) then
        local icon = icf.Icon
        if Usable(icon) and icon.SetTexCoord then icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) end
        W.Hide(icf.Border)
        if icf.CreateTexture then
            d.quality = K.Border(icf, 1, 0, 0, 0, 1, "OVERLAY")
        end
    end

    local name = f.Name
    if Usable(name) and name.SetWidth then
        K.SetFont(name, 12)
        name:SetWidth(LR.NAME_W)
        d.name = true
    end

    local timer = f.Timer
    if Usable(timer) and timer.SetStatusBarTexture then
        timer:SetStatusBarTexture(K.BAR_TEXTURE)
        K.PaintBar(timer, accent[1], accent[2], accent[3])
        local bg = timer.Background
        if Usable(bg) and bg.SetColorTexture then
            local c = C.bgDark
            bg:SetColorTexture(c[1], c[2], c[3], 1)
        end
        if timer.CreateTexture then d.timerEdge = K.Border(timer, 1, 0, 0, 0, 1, "OVERLAY") end
        d.timer = true
    end

    if f.HookScript then
        f:HookScript("OnShow", function(self) LR.Refresh(self) end)
    end
    LR.Refresh(f)
    return d
end

-- Aus W.Apply (nur mit "Fenster im Stil"): die vier Wuerfe des Spiels.
function LR.Apply()
    for _, n in ipairs(LR.FRAMES) do LR.Skin(_G[n]) end
end

-- Fuer /wcui fenster und die Selbstpruefung.
function LR.Report(out)
    local n, colored = 0, 0
    for _, name in ipairs(LR.FRAMES) do
        local d = done[_G[name]]
        if d then
            n = n + 1
            if d.qualityColored then colored = colored + 1 end
        end
    end
    out[#out + 1] = string.format("   %s (Stil %s): %d von %d gestaltet, %d mit Rand in der Qualität",
        LR.LABEL, LR.STYLE.name, n, #LR.FRAMES, colored)
    return out
end
