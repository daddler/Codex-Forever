--------------------------------------------------
-- WeintCodex :: Oberflaeche - Karte & Questlog (6.7.9.0)
--------------------------------------------------
-- Die Weltkarte mit dem Questlog (WorldMapFrame) in der ruhigen
-- Informationsoberflaeche, in GOLD (S.CALM) - sie gehoert nicht zur Klasse.
--
--   Karte     BLEIBT, WIE SIE IST: der weiche Rand um die Karte (W.SoftMap,
--             Maske an den Bildern des Kartenausschnitts, 6.6.2.1) ist
--             ausdruecklich gewuenscht und wird hier nicht beruehrt - keine
--             Flaeche, kein Licht, keine Vignette ueber oder unter ihr.
--   Questlog  die Spalte rechts (QuestScrollFrame) liegt auf der
--             angehobenen Flaeche des Registers mit weichem Schatten und
--             feiner Kante in Gold; aus, wenn die Seitenleiste zu ist.
--   Abschnitte die Zonen ("Die Todesminen", "Dunkelkueste" ...) sind
--             Kopfzeilen des Spiels: mit dem Stil des Fensters werden sie
--             Abschnitte wie im Ruf (Text links, Raute, Linie, Band, Gold)
--             statt mittig mit Lichthof (ui/windows.lua, W.SkinMap).
--   Grund     der Schein der Klasse oben ist in Gold aus (W.HoldGlow).
--
-- Unveraendert: Farben der Quests (Schwierigkeit: gelb, gruen, grau - sie
-- sagen etwas), Ziele, Symbole (Quest, Abgabe), Haekchen zum Verfolgen,
-- Suche, "Quests: 19/40", Filter, die Karte samt Markierungen.
--
-- GEMESSEN (6.7.8.0, /wcui fenster): WorldMapFrame, QuestScrollFrame mit
-- .Contents (Zeilen mit .Display, .Checkbox, Kopfzeilen mit
-- .CollapseButton "common-button-list-minus/-plus"), .ScrollBar,
-- .BorderFrame (QuestLog-Frame-Gradient-bottom), .SettingsDropdown;
-- "Weicher Rand (Karte): Maske an 27 Bildern".
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIQuestLog = {}

local QL = WeintCodex.UIQuestLog
local GC = WeintCodex.GameColors
local W = WeintCodex.UIWindows
local S = WeintCodex.UIStyle
local RG = WeintCodex.UIRegister

local Visible, IsFrame = RG.Visible, RG.IsFrame

QL.LABEL = "Questlog"
QL.HOST = "WorldMapFrame"
QL.STYLE = S.CALM
QL.PAD = 6                  -- Flaeche so weit ueber die Spalte hinaus
QL.SHADOW_PAD = 8           -- klein: links liegt die Karte mit ihrem weichen Rand
QL.EDGE = 0.45              -- Kante oben in Gold

S.SCOPES[QL.HOST] = QL.STYLE
W.HOSTED[QL.HOST] = W.HOSTED[QL.HOST] or {}
table.insert(W.HOSTED[QL.HOST], QL)

local cols = setmetatable({}, { __mode = "k" })
QL.cols = cols

function QL.List()
    local l = _G.QuestScrollFrame
    return IsFrame(l) and l or nil
end

local function Build(f, list)
    local accent = S.Accent(QL.STYLE.accent)
    local c = GC.surfaceRaised
    local sb = list.ScrollBar
    local corner = IsFrame(sb) and sb or nil
    local col = { anchor = list, on = true }
    col.body = S.SoftPanel(f, list, c, c[4], QL.PAD, -4, corner)
    col.shadow = S.Shadow(f, list, QL.PAD + QL.SHADOW_PAD, -5, corner)
    col.edge = S.Under(S.Divider(f, accent, QL.EDGE, 0), -3)
    S.PlaceTop(col.edge, list, 12, QL.PAD)
    col.parts = { col.body, col.shadow, col.edge.l, col.edge.r }
    cols[f] = col
    return col
end

function QL.Update(f)
    local list = QL.List()
    if not list then return nil end
    local col = cols[f] or Build(f, list)
    local on = Visible(list)
    if col.on ~= on then
        col.on = on
        for _, t in ipairs(col.parts) do t:SetShown(on) end
    end
    return col
end

function QL.Report(f, out)
    local col = cols[f]
    out[#out + 1] = string.format("   %s (Stil %s): Spalte %s · Karte unberührt (weicher Rand bleibt)", QL.LABEL, QL.STYLE.name,
        col and (col.on and "auf Fläche" or "zu") or "nicht gefunden")
    return out
end
