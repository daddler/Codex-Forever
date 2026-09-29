--------------------------------------------------
-- WeintCodex :: Oberflaeche - Suche nach Gruppe (6.8.0.0)
--------------------------------------------------
-- Der Dungeonbrowser ("Suche nach Gruppe", LFGParentFrame; im Quelltext
-- des Spiels PVEFrame) in der ruhigen Informationsoberflaeche, in GOLD
-- (S.CALM): er gehoert nicht zur Klasse - wie Spielmenue, Gilde und Karte.
--
--   Grund      der Schein der Klasse oben ist in Gold aus (W.HoldGlow),
--              statt dessen ein Hauch neutrales Licht.
--   Flaechen   die Innenflaechen des Fensters (seit 6.6.2.2 von
--              W.SkinInsets gestaltet - etwa der Bereich mit "Nur der
--              Gruppenfuehrer kann die Gruppe anmelden.") bekommen, was die
--              Flaechen der Register tragen: weichen Schatten und oben eine
--              feine Kante in Gold. Gefunden ueber W.Insets (die Innenflaechen,
--              die WeintCodex schon kennt), nicht ueber Namen - welcher
--              Rahmen es ist, hat die Messung nicht gezeigt.
--   Akzent     Gold am gewaehlten Seitenreiter (SkinSideTabs, Stil des
--              Fensters).
--
-- Unveraendert: Rollensymbole und ihre Ringe, die Fahne fuer neue Spieler,
-- Auswahl der Rolle, Texte (in der Farbe des Spiels), Knoepfe.
--
-- GEMESSEN (6.7.8.0, /wcui fenster): LFGParentFrame mit WhoListingTab,
-- ListingTab, BrowsingTab (Seitenreiter); LFGListingFrameGroupRoleButtons-
-- Role (Symbol 337499, Ring 340817), LFGListingFrameGroupRoleButtons-
-- RoleDropdown, LFGListingFrameNewPlayerFriendlyButton (Fahne).
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UILFG = {}

local LF = WeintCodex.UILFG
local GC = WeintCodex.GameColors
local W = WeintCodex.UIWindows
local S = WeintCodex.UIStyle
local RG = WeintCodex.UIRegister

local Visible, IsFrame, InTree = RG.Visible, RG.IsFrame, RG.InTree

LF.LABEL = "Suche nach Gruppe"
LF.HOSTS = { "LFGParentFrame", "PVEFrame" }
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
    out[#out + 1] = string.format("   %s (Stil %s): %d Innenflächen mit Kante in Gold%s", LF.LABEL, LF.STYLE.name,
        w.decks or 0, (w.decks or 0) == 0 and " (keine gefunden)" or "")
    return out
end
