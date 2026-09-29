--------------------------------------------------
-- WeintCodex :: Oberflaeche - Fenster in Gold mit Innenflaechen (6.8.0.2)
--------------------------------------------------
-- Fenster, die nicht zur Klasse gehoeren und deren Inhalt auf
-- Innenflaechen liegt, in der ruhigen Informationsoberflaeche, in GOLD
-- (S.CALM). Bis 6.8.0.1 hiess das Modul ui/lfg.lua und kannte nur die
-- Suche nach Gruppe; die Sammlung (6.8.0.2) braucht genau dasselbe.
--
--   Grund      der Schein der Klasse oben ist in Gold aus (W.HoldGlow),
--              statt dessen ein Hauch neutrales Licht.
--   Flaechen   jede Innenflaeche des Fensters (W.Insets - von W.SkinInsets
--              oder W.OwnBackground gestaltet) bekommt, was die Flaechen der
--              Register tragen: weichen Schatten und oben eine feine Kante
--              in Gold; aus mit ihr. Gefunden ueber W.Insets und InTree,
--              nicht ueber Namen.
--   Akzent     Gold am gewaehlten Seitenreiter (SkinSideTabs) und an
--              gewaehlten Reitern oben (SkinTabSystems) - Stil des Fensters.
--
-- Fenster (gemessen, /wcui fenster):
--   Suche nach Gruppe  LFGParentFrame (Quelltext: PVEFrame) - Innenflaechen:
--                      der Bereich des ersten Reiters, LFGBrowseFrame und
--                      LFGWhoListFrame (W.OWN_BG_PATHS, 6.8.0.1)
--   Sammlung           CollectionsJournal - Innenflaeche:
--                      WardrobeCollectionFrame.ItemsCollectionFrame
--                      (W.OWN_BG_PATHS seit 6.6.3.3); Plaetze der Vorlagen
--                      (transmog-nav-slot-*, der gewaehlte mit Goldring des
--                      Spiels), Klassenauswahl, Suche, Filter, Blaettern
-- Unveraendert jeweils: Symbole, Ringe, Auswahl, Texte, Knoepfe.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UICalm = {}

local LF = WeintCodex.UICalm
local GC = WeintCodex.GameColors
local W = WeintCodex.UIWindows
local S = WeintCodex.UIStyle
local RG = WeintCodex.UIRegister

local Visible, IsFrame, InTree = RG.Visible, RG.IsFrame, RG.InTree

-- Fenster -> Name im Bericht.
LF.WINDOWS = { LFGParentFrame = "Suche nach Gruppe", PVEFrame = "Suche nach Gruppe",
               CollectionsJournal = "Sammlung" }
LF.HOSTS = { "LFGParentFrame", "PVEFrame", "CollectionsJournal" }
LF.STYLE = S.CALM
LF.LIGHT_HEIGHT = 120
LF.SHADOW_PAD = 10
LF.EDGE = 0.45              -- Kante oben in Gold

for _, host in ipairs(LF.HOSTS) do
    S.SCOPES[host] = LF.STYLE
    W.HOSTED[host] = W.HOSTED[host] or {}
    table.insert(W.HOSTED[host], LF)
end

local windows = setmetatable({}, { __mode = "k" })
local decks = setmetatable({}, { __mode = "k" })
LF.windows, LF.decks = windows, decks

local function Deck(f, inset, accent)
    local d = { on = true }
    d.shadow = S.Shadow(f, inset, LF.SHADOW_PAD, -5)
    d.edge = S.Under(S.Divider(inset, accent, LF.EDGE, 0), 2)
    S.PlaceTop(d.edge, inset, 12, 0)
    d.parts = { d.shadow, d.edge.l, d.edge.r }
    decks[inset] = d
    return d
end

function LF.Update(f)
    local w = windows[f]
    if not w then
        local l = GC.atmosLight
        w = { light = S.TopLight(f, f, l, l[4], LF.LIGHT_HEIGHT, -5) }
        windows[f] = w
    end
    local accent = S.Accent(LF.STYLE.accent)
    local n = 0
    for inset in pairs(W.Insets) do
        if IsFrame(inset) and InTree(inset, f) then
            local d = decks[inset] or Deck(f, inset, accent)
            local on = Visible(inset)
            if d.on ~= on then
                d.on = on
                for _, t in ipairs(d.parts) do t:SetShown(on) end
            end
            if on then n = n + 1 end
        end
    end
    w.decks = n
    return w
end

function LF.Report(f, out)
    local w = windows[f]
    if not w then return out end
    local ok, name = pcall(function() return f:GetName() end)
    local label = ok and LF.WINDOWS[name] or "Fenster in Gold"
    out[#out + 1] = string.format("   %s (Stil %s): %d Innenflächen mit Kante in Gold%s", label, LF.STYLE.name,
        w.decks or 0, (w.decks or 0) == 0 and " (keine gefunden)" or "")
    return out
end
