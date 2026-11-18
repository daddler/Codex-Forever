--------------------------------------------------
-- WeintCodex :: Oberflaeche - Leisten des Spiels verschieben
--------------------------------------------------
-- Seit 6.115.0.0 (Wunsch: "Aktionsleisten auch mit Codex verschieben -
-- dann waere ich komplett unabhaengig vom Bearbeitungsmodus").
--
-- WeintCodex fasst die Leisten dabei NICHT an: 6.3.0.4/.5 haben sie
-- direkt verschoben, und das Spiel blockierte danach im Kampf sein eigenes
-- Neustapeln (ADDON_ACTION_BLOCKED). Stattdessen liegt im Gestaltungsmodus
-- ueber jeder Leiste ein Platzhalter in ihrer Groesse. Gezogen wird der
-- Platzhalter; beim Loslassen (und bei Pfeiltasten, Zahlen, Zuruecksetzen)
-- schreibt WeintCodex den Platz in sein Layout „WeintCodex“ und laesst das
-- Spiel es neu anwenden (ES.SetBarAnchors) - als haette man die Leiste im
-- Bearbeitungsmodus gezogen. Nur ausserhalb des Kampfes, nur im eigenen
-- Layout. UNGEMESSEN: ob der Forever-Client das neu angewandte Layout
-- sofort zeigt.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIBarMover = {}

local BM = WeintCodex.UIBarMover
local K  = WeintCodex.UIKit

BM.PREFIX = "gbar_"
BM.ghosts = {}

local function Say(text)
    print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " " .. text)
end

-- Was so verschoben wird: alle Leisten, seit 6.116.0.0 auch Chat und
-- Minikarte (Wunsch: "das gleiche fuer Chatfenster und Minimap").
BM.SYSTEMS = { ActionBar = true, ChatFrame = true, Minimap = true }

function BM.Entries()
    local out = {}
    for _, e in ipairs(K.GAME_LAYOUT or {}) do
        if BM.SYSTEMS[e.sys] and not (e.sys == "Minimap" and BM.ForeignMinimap and BM.ForeignMinimap()) then out[#out + 1] = e end
    end
    return out
end

local function BarFrame(e)
    for _, name in ipairs(e.frames or {}) do
        local f = _G[name]
        if type(f) == "table" and f.GetWidth then return f end
    end
    return nil
end

-- Groesse der Leiste in Einheiten von UIParent; nil, wenn unbekannt.
function BM.Size(f)
    local w, h = K.Plain(f:GetWidth()), K.Plain(f:GetHeight())
    if type(w) ~= "number" or type(h) ~= "number" or w < 4 or h < 4 then return nil end
    local s = f.GetEffectiveScale and K.Plain(f:GetEffectiveScale())
    local u = UIParent.GetEffectiveScale and K.Plain(UIParent:GetEffectiveScale())
    if type(s) == "number" and type(u) == "number" and u > 0 then w, h = w * s / u, h * s / u end
    return w, h
end

BM.BUTTON = 38
function BM.PlannedSize(e)
    local n = tonumber(type(e.key) == "string" and e.key:match("^bar(%d)$"))
    local SH = WeintCodex.UIShare
    if not (n and n >= 2 and SH and SH.BarOn and SH.BarOn(n)) then return nil end
    local long, short = 12 * BM.BUTTON, BM.BUTTON
    if e.set and e.set.Orientation == 1 then return short, long end
    return long, short
end

-- Der Spieler hat einen Platzhalter bewegt: Platz ins Layout.
function BM.OnPlaced(key)
    local barKey = key:sub(#BM.PREFIX + 1)
    local ui = K.Profile()
    local g = BM.ghosts[barKey]
    local pos = (ui and ui.positions[key]) or (g and g.default)
    if not pos then return false end
    local ES = WeintCodex.UISetup
    local ok, why = ES.SetBarAnchors({ [barKey] = pos })
    if not ok then Say("Leiste nicht verschoben: " .. tostring(why) .. ".") end
    return ok
end

-- 1.0.7.19 (Bild: "Minimap laesst sich nicht ganz nach unten ziehen"): der
-- Bereich des Spiels (MinimapCluster) ist groesser als die Karte - unten
-- bleibt leerer Platz, und am Bildschirmrand haelt der Bereich, nicht die
-- Karte. Der leere Rand darf deshalb aus dem Bild ragen: Platzhalter und
-- Bereich bekommen Klemm-Abstaende in genau seiner Groesse (nach innen:
-- links/unten positiv, rechts/oben negativ). Nie im Kampf.
function BM.MinimapGaps()
    local cl, mm = _G.MinimapCluster, _G.Minimap
    if type(cl) ~= "table" or type(mm) ~= "table" or not cl.GetTop or not mm.GetTop then return nil end
    local function v(x) x = K.Plain(x) return type(x) == "number" and x or nil end
    -- Lagen in Bildschirmeinheiten, dann in die des Bereichs.
    local cs, ms = v(cl:GetEffectiveScale()), v(mm:GetEffectiveScale())
    local ct, cb, cL, cR = v(cl:GetTop()), v(cl:GetBottom()), v(cl:GetLeft()), v(cl:GetRight())
    local mt, mb, mL, mR = v(mm:GetTop()), v(mm:GetBottom()), v(mm:GetLeft()), v(mm:GetRight())
    if not (cs and ms and ct and cb and cL and cR and mt and mb and mL and mR) or cs <= 0 then return nil end
    local f = ms / cs
    local function gap(a) return math.max(0, a) end
    return gap(mL * f - cL), gap(cR - mR * f), gap(ct - mt * f), gap(mb * f - cb), cs
end
-- 1.0.7.38 (Spielerin mit SpartanUI: "Minimap auf einmal verschwunden,
-- egal ob das Modul an oder aus ist"): eine andere Oberflaeche (SpartanUI,
-- ElvUI, ...) haengt die Karte in ihren eigenen Rahmen. Dann liegen Bereich
-- und Karte weit auseinander, und die "Luecken" waeren riesige Klemm-
-- Abstaende. Nur, wenn die Karte wirklich im Bereich des Spiels sitzt -
-- sonst die Abstaende des Spiels (0) zurueck.
BM.FOREIGN_MINIMAP = { "SpartanUI", "ElvUI", "TukUI", "SexyMap", "BasicMinimap", "Chinchilla", "LUI", "NDui", "GW2_UI" }
function BM.ForeignMinimap()
    local ca = _G.C_AddOns
    local loaded = (ca and ca.IsAddOnLoaded) or _G.IsAddOnLoaded
    if not loaded then return nil end
    for _, n in ipairs(BM.FOREIGN_MINIMAP) do
        local ok, on = pcall(loaded, n)
        if ok and K.Bool(on, false) then return n end
    end
    return nil
end
function BM.MinimapInCluster()
    local cl, mm = _G.MinimapCluster, _G.Minimap
    if type(cl) ~= "table" or type(mm) ~= "table" or not mm.GetParent then return false end
    local p = mm:GetParent()
    for _ = 1, 3 do
        if p == cl then return true end
        p = p and p.GetParent and p:GetParent() or nil
    end
    return false
end
function BM.MinimapInsets(g)
    if K.InCombat() then return false end
    local cl = _G.MinimapCluster
    if BM.ForeignMinimap() or not BM.MinimapInCluster() then
        if BM.mmInsets and type(cl) == "table" and cl.SetClampRectInsets then pcall(cl.SetClampRectInsets, cl, 0, 0, 0, 0) end
        BM.mmInsets = nil
        return false
    end
    local l, r, t, b, cs = BM.MinimapGaps()
    if not l then return false end
    if cl.SetClampRectInsets then pcall(cl.SetClampRectInsets, cl, l, -r, -t, b) end
    if g and g.SetClampRectInsets then
        local u = K.Plain(UIParent:GetEffectiveScale())
        local k = (type(u) == "number" and u > 0) and cs / u or 1
        pcall(g.SetClampRectInsets, g, l * k, -r * k, -t * k, b * k)
    end
    BM.mmInsets = { l, r, t, b }
    return true
end

-- Platzhalter bauen bzw. auf die Leiste legen (beim Entsperren).
function BM.Prepare()
    if K.InCombat() then return 0 end
    local ES = WeintCodex.UISetup
    if not (ES and ES.LayoutActive() == true) then return 0 end
    local n = 0
    for _, e in ipairs(BM.Entries()) do
        local bar = BarFrame(e)
        local shown = bar and bar.IsShown and bar:IsShown()
        local w, h = nil, nil
        if bar and shown then w, h = BM.Size(bar) end
        -- 1.0.1.5: eine Leiste, die WeintCodex gerade eingeschaltet hat,
        -- zeigt das Spiel erst nach dem Neuladen - ihr Platzhalter kommt
        -- trotzdem, in der Groesse von zwoelf Knoepfen.
        if not w then w, h = BM.PlannedSize(e) end
        local g = BM.ghosts[e.key]
        if w then
            if not g then
                g = CreateFrame("Frame", nil, UIParent)
                g:SetFrameStrata("DIALOG")
                BM.ghosts[e.key] = g
            end
            g:SetSize(w, h)
            -- Standard = wo die Leiste im Layout steht (auch von frueher
            -- aus dem Bearbeitungsmodus); sonst der Platz von WeintCodex.
            g.default = ES.BarAnchor(e.key) or ES.Target(e)
            -- Der gemerkte Platz gilt nur, solange er im Layout steht -
            -- sonst haette der Platzhalter einen anderen als die Leiste.
            local ui = K.Profile()
            if ui then ui.positions[BM.PREFIX .. e.key] = nil end
            K.RegisterMover(g, BM.PREFIX .. e.key, e.label, g.default, { onPlaced = BM.OnPlaced })
            if e.sys == "Minimap" then BM.MinimapInsets(g) end
            K.SetMoverEnabled(BM.PREFIX .. e.key, true)
            n = n + 1
        elseif g then
            K.SetMoverEnabled(BM.PREFIX .. e.key, false)
        end
    end
    return n
end

function BM.Active()
    return K.UIEnabled() and K.IsActive("actionbars") and true or false
end

K.Listen(function(kind, on)
    if kind ~= "unlock" then return end
    if on and BM.Active() then
        BM.Prepare()
    else
        for key in pairs(BM.ghosts) do K.SetMoverEnabled(BM.PREFIX .. key, false) end
    end
end)
