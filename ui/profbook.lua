--------------------------------------------------
-- WeintCodex :: Oberflaeche - Berufe, Uebersicht (6.7.6.0)
--------------------------------------------------
-- Der erste Seitenreiter des Berufsfensters: eine Karte je Beruf (zwei
-- Hauptberufe breit, darunter drei Nebenberufe). Kein Register - keine
-- Liste, keine Detailansicht -, aber dieselbe Sprache wie die Rezeptseite
-- (ui/professions.lua) und in derselben Farbe (Gold, S.CALM):
--
--   Karte   die braune Flaeche des Spiels und das Bild dahinter sind weg
--           (ui/windows.lua, W.HIDE_ATLAS); an ihrer Stelle die angehobene
--           Flaeche des Registers mit weichem Schatten und Lichtkante.
--   Titel   der Name des Berufs oben in der Karte wird Abschnitt: hell,
--           14 pt, und steht er links, folgt ihm Raute und Linie in Gold
--           (wie die Kopfzeilen im Ruf); steht er mittig (Nebenberufe),
--           darunter eine Linie mit Raute.
--   Balken  Tiefe an der Fuellung wie bei den Fertigkeiten; Farbe, Glanz
--           ("Flare") und Text des Spiels bleiben.
--   Grund   Vignette und neutrales Licht auf dem Fenster wie im Register.
--
-- Unveraendert: Symbole, Namen und Rang ("Lehrling"), Zauberknoepfe
-- (Verhuettung, Mineraliensuche), der rote Knopf zum Verlernen, Texte
-- ("Besucht einen Lehrer ...") und ihre Lage.
--
-- GEMESSEN (6.7.5.0, /wcui fenster auf der Uebersicht):
--   ProfessionsFrame.BookPage.ProfessionsContentFrame
--     .PrimaryProfession1/2      Profession-overview-Card (braune Flaeche)
--     .SecondaryProfession1..3   Profession-overview-card-generic-Cooking/
--                                Fishing/FirstAid (Bild hinter dem Text)
--     .<Karte>.StatusBar         Skillbar_Fill_Flipbook_<Beruf>, Skillbar_Flare_<Beruf>
--     .<Karte>.SpellButton1/2, .UnlearnButton (Profession-button-red-crossmark)
-- UNGEMESSEN: wo der Titel steht (die oberste Schriftzeile der Karte) und
-- woher die abgerundeten Kaesten um die Nebenberufe kommen (Rahmen der
-- Karte: .NineSlice/.Border werden ausgeblendet, falls es sie gibt).
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIProfessionBook = {}

local PB = WeintCodex.UIProfessionBook
local K = WeintCodex.UIKit
local C = WeintCodex.Colors
local GC = WeintCodex.GameColors
local W = WeintCodex.UIWindows
local S = WeintCodex.UIStyle
local RG = WeintCodex.UIRegister

local Visible, Kind, IsFrame, Edge = RG.Visible, RG.Kind, RG.IsFrame, RG.Edge

PB.LABEL = "Berufe, Übersicht"
PB.HOST = "ProfessionsFrame"
PB.STYLE = S.CALM
PB.CARDS = { "PrimaryProfession1", "PrimaryProfession2",
             "SecondaryProfession1", "SecondaryProfession2", "SecondaryProfession3", "SecondaryProfession4" }
PB.DECOR = { "NineSlice", "Border", "Bg", "Background" }
PB.VIGNETTE, PB.VIGNETTE_SIZE = 0.35, 48
PB.LIGHT_HEIGHT = 140
PB.PAD = -2                 -- Flaeche 2 px innerhalb der Karte (Karten stehen dicht)
PB.SHADOW_PAD = 10
PB.EDGE = 0.07              -- Lichtkante oben (weiss)
PB.TITLE_SIZE = 14
PB.GAP = 8                  -- Titel -> Raute -> Linie (wie W.LIST_GAP)
PB.INSET = 12               -- Linie endet so weit vor dem Rand der Karte
PB.UNDER = 7                -- mittiger Titel: Linie so weit unter ihm
PB.LINE = 0.55              -- Deckkraft der Linie (Gold)

W.HOSTED[PB.HOST] = W.HOSTED[PB.HOST] or {}
table.insert(W.HOSTED[PB.HOST], PB)

local WHITE = { 1, 1, 1 }
local pages = setmetatable({}, { __mode = "k" })
local cards = setmetatable({}, { __mode = "k" })
PB.pages, PB.cards = pages, cards

local function Accent() return S.Accent(PB.STYLE.accent) end

-- Die Seite: ProfessionsFrame.BookPage.ProfessionsContentFrame (ohne Anlage).
function PB.Content(f)
    local book = f and f.BookPage
    local c = IsFrame(book) and book.ProfessionsContentFrame
    return IsFrame(c) and c or nil
end

--------------------------------------------------
-- Eine Karte
--------------------------------------------------
local function Build(card, accent)
    local k = { frame = card }
    for _, key in ipairs(PB.DECOR) do
        local part = card[key]
        if IsFrame(part) then W.HideDecor(part) end
    end
    local c = GC.surfaceRaised
    k.body = S.SoftPanel(card, card, c, c[4], PB.PAD, -7)
    k.shadow = S.Shadow(card, card, PB.SHADOW_PAD, -8)
    k.edge = S.Under(S.Divider(card, WHITE, PB.EDGE, 0), -6)
    S.PlaceTop(k.edge, card, 12, PB.PAD)
    -- Titel: die oberste Schriftzeile der Karte.
    k.title = (RG.Topmost(card, 0, nil, nil))
    if k.title then
        S.Title(k.title, PB.TITLE_SIZE, C.textBright)
        k.dot = S.Diamond(card, 6, accent, 0.9, 2)
        k.hole = S.Diamond(card, 2, C.surface1, 1, 3)
        k.hole:SetPoint("CENTER", k.dot, "CENTER", 0, 0)
        k.line = S.Own(card:CreateTexture(nil, "ARTWORK", nil, 1))
        k.line:SetHeight(1)
        S.Fade(k.line, accent, PB.LINE, "RIGHT")
        k.orn = S.Ornament(card, accent, 0.45)
    end
    -- Balken: Tiefe an der Fuellung (Statusbalken, gemessen .StatusBar).
    local bar = card.StatusBar
    if IsFrame(bar) and bar.CreateTexture then
        local fill, how = RG.BarFill(bar)
        k.bar = S.BarFinish(bar, fill)
        k.bar.how = how
    end
    cards[card] = k
    return k
end

local function JustifyOf(fs)
    local ok, j = pcall(fs.GetJustifyH, fs)
    j = ok and K.Plain(j) or nil
    return type(j) == "string" and j or "LEFT"
end

-- Titel links: Raute und Linie hinter dem TEXT. Titel mittig: Linie mit
-- Raute darunter. Neu gelegt nur, wenn Breite oder Lage sich aendern.
local function PlaceTitle(k)
    local fs = k.title
    if not fs then return end
    local ok, tw = pcall(fs.GetStringWidth, fs)
    tw = ok and K.Plain(tw) or nil
    tw = type(tw) == "number" and tw or 0
    local top, bottom = Edge(k.frame, "GetTop"), Edge(fs, "GetBottom")
    local fl, cr = Edge(fs, "GetLeft"), Edge(k.frame, "GetRight")
    local centered = JustifyOf(fs) == "CENTER"
    local y = (top and bottom) and math.floor(bottom - top - PB.UNDER + 0.5) or false
    if k.tw == tw and k.centered == centered and k.y == y and k.fl == fl and k.cr == cr then return end
    k.tw, k.centered, k.y, k.fl, k.cr = tw, centered, y, fl, cr
    k.dot:SetShown(not centered)
    k.hole:SetShown(not centered)
    k.line:SetShown(not centered)
    for _, t in ipairs(k.orn.parts) do t:SetShown(centered and y and true or false) end
    if centered then
        if y then S.PlaceOrnament(k.orn, k.frame, PB.INSET, y) end
    else
        k.dot:ClearAllPoints()
        k.dot:SetPoint("CENTER", fs, "LEFT", tw + PB.GAP + 3, 0)
        -- Nur links verankert, die Breite gerechnet (6.7.8.0): rechts an
        -- der Karte ("RIGHT" = deren halbe Hoehe) lag das Ende nicht auf
        -- der Zeile des Titels.
        k.line:ClearAllPoints()
        k.line:SetPoint("LEFT", k.dot, "CENTER", PB.GAP, 0)
        local w = (fl and cr) and (cr - PB.INSET - (fl + tw + 2 * PB.GAP + 3)) or 0
        k.width = w > 0 and math.floor(w + 0.5) or 0
        k.line:SetWidth(k.width)
        k.line:SetShown(k.width > 0)
    end
end

--------------------------------------------------
-- Atmosphaere und Durchlauf
--------------------------------------------------
local function Show(p, on)
    if p.on == on then return end
    p.on = on
    for _, t in ipairs(p.parts) do t:SetShown(on) end
end

local function Atmosphere(f, content)
    local p = pages[content]
    if p then return p end
    p = { parts = {}, host = f }
    local v = S.Vignette(f, content, PB.VIGNETTE, PB.VIGNETTE_SIZE, -6)
    for _, side in ipairs(S.SIDES) do p.parts[#p.parts + 1] = v[side] end
    p.vignette = v
    local l = GC.atmosLight
    p.light = S.TopLight(f, content, l, l[4], PB.LIGHT_HEIGHT, -5)
    p.parts[#p.parts + 1] = p.light
    pages[content] = p
    if content.HookScript then
        content:HookScript("OnShow", function() Show(p, true) end)
        content:HookScript("OnHide", function() Show(p, false) end)
    end
    return p
end

function PB.Update(f)
    local content = PB.Content(f)
    if not content then return nil end
    local p = pages[content]
    if not Visible(content) then
        if p then Show(p, false) end
        return nil
    end
    S.Scope(content, PB.STYLE)
    p = Atmosphere(f, content)
    Show(p, true)
    local accent = Accent()
    for _, key in ipairs(PB.CARDS) do
        local card = content[key]
        if IsFrame(card) and Visible(card) and card.CreateTexture then
            local k = cards[card] or Build(card, accent)
            PlaceTitle(k)
        end
    end
    return p
end

--------------------------------------------------
-- /wcui fenster
--------------------------------------------------
function PB.Report(f, out)
    local content = PB.Content(f)
    if not content or not Visible(content) then return out end
    local n, titled, bars, how = 0, 0, 0, nil
    local names, centered = "", 0
    for _, key in ipairs(PB.CARDS) do
        local card = content[key]
        local k = IsFrame(card) and Visible(card) and cards[card]
        if k then
            n = n + 1
            if k.title then
                titled = titled + 1
                if k.centered then centered = centered + 1 end
                names = names .. (names == "" and "" or ", ") .. "„" .. (RG.TextOf(k.title) or "?") .. "“"
            end
            if k.bar then
                bars = bars + 1
                how = how or k.bar.how
            end
        end
    end
    out[#out + 1] = string.format("   %s (Stil %s): %d Karten, %d mit Titel (%d mittig), %d Balken (Füllung %s)",
        PB.LABEL, PB.STYLE.name, n, titled, centered, bars, tostring(how or "–"))
    out[#out + 1] = string.format("   %s, Titel: %s", PB.LABEL, names ~= "" and names or "keine")
    return out
end
