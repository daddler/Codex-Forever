--------------------------------------------------
-- WeintCodex :: Oberflaeche - Gespraeche (6.8.0.4)
--------------------------------------------------
-- Die Gespraechsfenster des Spiels - Gespraech mit einem NPC (GossipFrame:
-- Stadtwachen, Gastwirte, Lehrer ...), Questtext (QuestFrame), Buecher und
-- Briefe (ItemTextFrame) - in der ruhigen Informationsoberflaeche. Sie
-- gehoeren nicht zur Klasse: GOLD (S.CALM), wie Spielmenue und Dialoge.
-- Seit 6.6.1.4 ohne Pergament und mit heller Schrift (ui/windows.lua,
-- W.DIALOGS); neu:
--
--   Grund      der Schein der Klasse oben ist in Gold aus (W.HoldGlow) -
--              im Spiel lag er als brauner Verlauf ueber dem Gespraech
--              (Beta-Test 6.8.0.3, Krieger). Statt dessen ein Hauch
--              neutrales Licht und oben eine feine Kante in Gold.
--   Gespraech  Begruessung und Optionen (GreetingPanel.ScrollBox) liegen auf
--              der angehobenen Flaeche der Register mit weichem Schatten und
--              feiner Kante in Gold; die Bildlaufleiste gehoert dazu.
--
-- Unveraendert: Texte, Symbole der Optionen (Sprechblase, Quest, Lehrer
-- ...), Farben der Quests, Bildlaufleiste, "Lebt wohl".
--
-- GEMESSEN (6.8.0.3, /wcui fenster): GossipFrame mit .GreetingPanel
-- (.ScrollBox.ScrollTarget: die Optionen, Sprechblase Bild 136810;
-- .ScrollBar: minimal-scrollbar-*), GossipFrameCloseButton.
-- UNGEMESSEN: Questtext und Buecher - dort nur Grund und Kante, keine Flaeche.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIGossip = {}

local GS = WeintCodex.UIGossip
local GC = WeintCodex.GameColors
local W = WeintCodex.UIWindows
local S = WeintCodex.UIStyle
local RG = WeintCodex.UIRegister

local Visible, IsFrame = RG.Visible, RG.IsFrame

-- Fenster -> Name im Bericht.
GS.WINDOWS = { GossipFrame = "Gespräch", QuestFrame = "Questtext", ItemTextFrame = "Buch/Brief" }
GS.HOSTS = { "GossipFrame", "QuestFrame", "ItemTextFrame" }
GS.STYLE = S.CALM
GS.LIGHT_HEIGHT = 90
GS.EDGE = 0.5               -- Kante oben am Fenster in Gold
GS.PAD = 6                  -- Flaeche so weit ueber das Gespraech hinaus
GS.SHADOW_PAD = 10
GS.LIST_EDGE = 0.45         -- Kante oben an der Flaeche in Gold

for _, host in ipairs(GS.HOSTS) do
    S.SCOPES[host] = GS.STYLE
    W.HOSTED[host] = W.HOSTED[host] or {}
    table.insert(W.HOSTED[host], GS)
end

local windows = setmetatable({}, { __mode = "k" })
GS.windows = windows

-- Begruessung und Optionen des Gespraechs, wenn es sie gibt.
function GS.List(f)
    local p = f and f.GreetingPanel
    local l = IsFrame(p) and p.ScrollBox
    return IsFrame(l) and l or nil
end

local function Card(f, list, accent)
    local c = GC.surfaceRaised
    local sb = f.GreetingPanel.ScrollBar
    local corner = IsFrame(sb) and sb or nil
    local card = { on = true }
    card.body = S.SoftPanel(f, list, c, c[4], GS.PAD, -4, corner)
    card.shadow = S.Shadow(f, list, GS.PAD + GS.SHADOW_PAD, -5, corner)
    card.edge = S.Under(S.Divider(f, accent, GS.LIST_EDGE, 0), -3)
    S.PlaceTop(card.edge, list, 12, GS.PAD)
    card.parts = { card.body, card.shadow, card.edge.l, card.edge.r }
    return card
end

local function Build(f)
    local accent = S.Accent(GS.STYLE.accent)
    local w = {}
    local l = GC.atmosLight
    w.light = S.TopLight(f, f, l, l[4], GS.LIGHT_HEIGHT, -5)
    w.edge = S.Under(S.Divider(f, accent, GS.EDGE, 0), -3)
    S.PlaceTop(w.edge, f, 10, -1)
    local list = GS.List(f)
    if list then w.card = Card(f, list, accent) end
    windows[f] = w
    return w
end

function GS.Update(f)
    local w = windows[f] or Build(f)
    local card = w.card
    if card then
        local on = Visible(GS.List(f))
        if card.on ~= on then
            card.on = on
            for _, t in ipairs(card.parts) do t:SetShown(on) end
        end
    end
    return w
end

function GS.Report(f, out)
    local w = windows[f]
    if not w then return out end
    local ok, name = pcall(function() return f:GetName() end)
    local label = ok and GS.WINDOWS[name] or "Gespräch"
    local card = w.card and (w.card.on and ", Gespräch auf Fläche" or ", Fläche zu") or ""
    out[#out + 1] = string.format("   %s (Stil %s): Kante in Gold, kein Schein der Klasse%s", label, GS.STYLE.name, card)
    return out
end
