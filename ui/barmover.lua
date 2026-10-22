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

-- Die verschiebbaren Leisten: alle ActionBar-Eintraege des Layouts.
function BM.Entries()
    local out = {}
    for _, e in ipairs(K.GAME_LAYOUT or {}) do
        if e.sys == "ActionBar" then out[#out + 1] = e end
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
