--------------------------------------------------
-- WeintCodex :: UI Core (Forever Edition)
--
-- Designsprache "Graphit", uebernommen aus WeintCompanion 5 (Forever):
-- streng neutraler, kuehler Grund, Karten ohne Rahmen mit 1-px-Oberkante,
-- EIN Akzent (Violett), der ausschliesslich Bedeutung traegt, und drei
-- Schriften statt zwei - eine Serifenschrift fuer Ueberschriften, eine
-- humanistische Grotesk fuer alles Bedienbare, eine Monospace fuer Zahlen
-- und Rubriken.
--
-- Die Werte in `C` und `WeintCodex.Fonts` sind die Uebersetzung von
-- `gui/theme/tokens.py` der Companion in WoW-Gleitkommafarben. Es ist die
-- EINZIGE Stelle im Addon, an der ein Farbwert steht - wer eine Flaeche
-- faerbt, nennt einen Namen. Laeuft die Companion-Palette weiter, wird hier
-- nachgezogen und sonst nirgends.
--
-- Drei Dinge, die in WoW anders geloest werden muessen als im Entwurf:
--
--  * Radius. Frames koennen keinen haben. Statt die Karte rund zu zeichnen
--    legen wir vier Viertelkreis-Masken in der Farbe DAHINTER auf die Ecken
--    (CutCorners). Das setzt voraus, dass der Aufrufer weiss, worauf die
--    Karte liegt - deshalb nimmt jede Flaeche ein `backdrop`.
--  * Verlauf. SetGradient("VERTICAL", min, max) laeuft von UNTEN nach OBEN,
--    CSS-`linear-gradient(180deg, a, b)` von oben nach unten. Die beiden
--    Farben werden daher vertauscht uebergeben.
--  * Schrift. Kein OUTLINE. Der Entwurf lebt von duennen, ruhigen
--    Textstufen; eine schwarze Kontur macht daraus wieder das alte Bild.
--------------------------------------------------

local WHITE  = "Interface\\Buttons\\WHITE8X8"
local MEDIA  = "Interface\\AddOns\\WeintCodex\\media\\"
local CORNER = MEDIA .. "ui\\corner"

--------------------------------------------------
-- Farbtokens ("Graphit")
--------------------------------------------------
-- Die Namen der Palette aus der Mists-Fassung bleiben allesamt gueltig und
-- zeigen auf die neuen Werte. Das ist Absicht und kein Uebergangszustand:
-- ueber hundert ColorText-Aufrufe im Addon nennen Farben beim Namen, und ein
-- entfernter Name faellt nicht auf (ColorText gibt den Text dann ungefaerbt
-- zurueck) - also genau die Sorte Fehler, die man erst im Spiel sieht.
--
-- Was sich mit Graphit inhaltlich aendert: es gibt nur noch EINEN Akzent.
-- `violet`, `purple`, `accent` und `brandA/B` zeigen deshalb alle auf
-- denselben Ton. Bis 4.x standen hier zwei Farbbegriffe nebeneinander, von
-- denen einer (das violette "Flaechenlicht") nichts bedeutete.
--------------------------------------------------

local C = {
    -- Flaechen (Companion: base #0C0C0F, sunken #08080A, card #141419,
    -- raised #1C1C23; Kartenverlauf #17171C -> #101014)
    bgDark      = {0.047, 0.047, 0.059, 1.0},   -- 0C0C0F - Fenstergrund
    bgMid       = {0.063, 0.063, 0.078, 1.0},   -- 101014 - Kartenfuss
    bgPanel     = {0.031, 0.031, 0.039, 1.0},   -- 08080A - Navigation/Titelleiste
    bgCard      = {0.090, 0.090, 0.110, 1.0},   -- 17171C - Kartenkopf

    surface0    = {0.047, 0.047, 0.059, 1.0},   -- 0C0C0F
    surface1    = {0.031, 0.031, 0.039, 1.0},   -- 08080A
    surface2    = {0.078, 0.078, 0.098, 1.0},   -- 141419
    surface3    = {0.110, 0.110, 0.137, 1.0},   -- 1C1C23 - Hover/aktiv

    cardTop       = {0.090, 0.090, 0.110, 1.0}, -- 17171C
    cardBottom    = {0.063, 0.063, 0.078, 1.0}, -- 101014
    accentCardTop = {0.090, 0.086, 0.122, 1.0}, -- 17161F
    accentCardBot = {0.063, 0.063, 0.078, 1.0}, -- 101014

    -- Der eine Akzent: Violett #7C6CFF. Heisst historisch auch "purple" und
    -- "gold" - beide Namen bleiben, weil sie an Dutzenden Stellen stehen.
    purple      = {0.486, 0.424, 1.000, 1.0},   -- 7C6CFF - Primaerakzent
    purpleDim   = {0.318, 0.275, 0.667, 1.0},   -- 51469F - gedaempft
    purpleDeep  = {0.365, 0.310, 0.878, 1.0},   -- 5D4FE0 - gedrueckt
    accent      = {0.486, 0.424, 1.000, 1.0},   -- 7C6CFF
    accentBright= {0.545, 0.482, 1.000, 1.0},   -- 8B7BFF

    -- Zustaende. Je Ton ein Grundwert (Flaeche/Punkt) und ein heller Wert
    -- (Text auf dunklem Grund) - im Entwurf durchgaengig so gepaart. Sie
    -- sind in jedem Akzent identisch: der Akzent ist Geschmack, die
    -- Bedeutung ist es nicht.
    green         = {0.204, 0.780, 0.482, 1.0}, -- 34C77B
    greenDim      = {0.125, 0.478, 0.298, 1.0}, -- 207A4C
    successBright = {0.322, 0.847, 0.573, 1.0}, -- 52D892
    red           = {0.957, 0.388, 0.400, 1.0}, -- F46366
    redDim        = {0.588, 0.239, 0.247, 1.0}, -- 963D3F
    dangerBright  = {0.973, 0.549, 0.545, 1.0}, -- F88C8B
    gold          = {0.941, 0.651, 0.227, 1.0}, -- F0A63A
    goldDim       = {0.576, 0.400, 0.141, 1.0}, -- 936624
    blue          = {0.306, 0.659, 0.961, 1.0}, -- 4EA8F5
    blueDim       = {0.188, 0.404, 0.588, 1.0}, -- 306796
    infoBright    = {0.451, 0.729, 0.973, 1.0}, -- 73BAF8
    violet        = {0.486, 0.424, 1.000, 1.0}, -- 7C6CFF (= Akzent)
    violetBright  = {0.545, 0.482, 1.000, 1.0}, -- 8B7BFF

    success     = {0.204, 0.780, 0.482, 1.0},
    warning     = {0.941, 0.651, 0.227, 1.0},
    danger      = {0.957, 0.388, 0.400, 1.0},
    info        = {0.306, 0.659, 0.961, 1.0},

    -- Helle Varianten auch unter den Grundfarbnamen, damit
    -- `farbe .. "Bright"` fuer jeden der Toene aufgeht (z.B. Rollenkoepfe,
    -- die "blue"/"green"/"red" durchreichen).
    blueBright    = {0.451, 0.729, 0.973, 1.0},
    greenBright   = {0.322, 0.847, 0.573, 1.0},
    redBright     = {0.973, 0.549, 0.545, 1.0},
    goldBright    = {0.961, 0.741, 0.400, 1.0},
    warningBright = {0.961, 0.741, 0.400, 1.0},
    accentDim     = {0.318, 0.275, 0.667, 1.0},

    -- Textstufen (bright > normal > muted > dim > faint > ghost)
    textBright  = {0.969, 0.969, 0.980, 1.0},   -- F7F7FA
    textNormal  = {0.929, 0.929, 0.949, 1.0},   -- EDEDF2
    textMuted   = {0.627, 0.627, 0.675, 1.0},   -- A0A0AC
    textDim     = {0.541, 0.541, 0.596, 1.0},   -- 8A8A98
    textFaint   = {0.373, 0.373, 0.420, 1.0},   -- 5F5F6B
    textGhost   = {0.227, 0.227, 0.267, 1.0},   -- 3A3A44

    -- Linien
    border       = {0.149, 0.149, 0.180, 1.0},  -- 26262E
    borderStrong = {0.200, 0.200, 0.235, 1.0},  -- 33333C
    rowLine      = {0.118, 0.118, 0.145, 1.0},  -- 1E1E25 - Zeilentrenner
    hairline     = {0.149, 0.149, 0.180, 1.0},  -- 26262E
    hairlineSoft = {0.118, 0.118, 0.145, 1.0},  -- 1E1E25
    borderGlow   = {0.486, 0.424, 1.000, 0.30},

    -- ATMOSPHAERE. Vier Werte, die keine Farbe sind, sondern Tiefe: sie
    -- liegen so tief, dass sie sich nicht als Ton lesen lassen, und
    -- stehen deshalb nicht neben dem einen Akzent, sondern unter ihm.
    -- `washAccent` IST der Akzent, nur fast durchsichtig - eine
    -- Kopfflaeche, die nach hinten hin violett anlaeuft, behauptet
    -- keine zweite Bedeutung, sie gibt der Flaeche einen Raum.
    -- Gebraucht werden sie nur mit einem Verlauf (ApplyVertical/
    -- HorizontalGradient), nie als Flaechenfarbe.
    washNone     = {0.486, 0.424, 1.000, 0.00},
    washAccent   = {0.486, 0.424, 1.000, 0.08},
    washAccentUp = {0.486, 0.424, 1.000, 0.16},
    washDark     = {0.000, 0.000, 0.000, 0.22},

    -- DER SCHLEIER UEBER EINEM BILD. Seit 5.2.0.7 kann eine Flaeche ein
    -- Artwork tragen (WeintCodex.Artwork). Ein Bild ist heller und
    -- unruhiger als jede Flaeche dieses Addons, und darauf muss
    -- derselbe Text stehen wie sonst - diese vier Werte sind, was ihn
    -- dort haelt. Sie sind SCHWARZ und nicht violett: der Akzent
    -- traegt Bedeutung, ein Schleier traegt keine, und ein violett
    -- eingefaerbtes Bild waere eine zweite Aussage neben dem einen
    -- Akzent. `artNone` ist ihr gemeinsamer Nullpunkt - wer von
    -- `washNone` aus verliefe, mischte auf dem Weg Violett hinein.
    artNone      = {0.000, 0.000, 0.000, 0.00},
    artTop       = {0.000, 0.000, 0.000, 0.43},  -- Nummer, Kennzeichen
    artLeft      = {0.000, 0.000, 0.000, 0.67},  -- Name auf der Bosskarte
    artDeep      = {0.000, 0.000, 0.000, 0.84},  -- Kopfkarte: vier Zeilen Text
    artFoot      = {0.000, 0.000, 0.000, 0.66},  -- Sockel unter dem Namen
    artFade      = {0.000, 0.000, 0.000, 0.92},  -- Bild laeuft in die Karte aus

    headerBg     = {0.031, 0.031, 0.039, 1.0},  -- 08080A - Insets (Suchfeld)
    accentDot    = {0.486, 0.424, 1.000, 1.0},

    -- Markenverlauf (Logo, Avatar). Frueher ein eigener Lila-Verlauf neben
    -- dem Bernstein-Akzent; mit Graphit ist der Akzent selbst violett, also
    -- ist der Verlauf seine eigene helle Stufe und keine zweite Farbe mehr.
    brandA      = {0.486, 0.424, 1.000, 1.0},   -- 7C6CFF
    brandB      = {0.365, 0.310, 0.878, 1.0},   -- 5D4FE0

    -- Text auf der Akzentflaeche (Companion: TEXT.onAccent)
    ink         = {0.078, 0.071, 0.110, 1.0},   -- 14121C
}
WeintCodex.Colors = C

--------------------------------------------------
-- Farben der Spielwelt (optionale Oberflaeche, ui/)
--------------------------------------------------
-- Namensplaketten und Einheitenrahmen faerben nicht die Oberflaeche,
-- sondern die WELT: wer ist feindlich, wer neutral, wer gehoert schon
-- jemand anderem. Diese Farben sind deshalb KEIN Teil von "Graphit" und
-- stehen neben der Palette, nicht in ihr - ein Feind ist rot, weil jeder
-- WoW-Spieler ihn so liest, nicht weil der Entwurf es sagt.
--
-- Sie stehen trotzdem HIER und nirgends sonst (Regel aus CLAUDE.md: jeder
-- Farbwert lebt in core/ui.lua). Die Module unter ui/ holen sich ihre
-- Vorgaben mit WeintCodex.UIKit.ColorDefault(name) und speichern, was der
-- Spieler daraus macht, als { r, g, b } in seinen Einstellungen.
--
-- Zwei Ausnahmen tragen bewusst die Bedeutung des Akzents, weil sie genau
-- das sind, wofuer er steht: `cast` ist Fortschritt, `targetRing` ist der
-- Fokusrahmen. Boss und Elite sind deshalb ausdruecklich NICHT violett
-- (die Vorlage faerbt sie so) - eine violette Plakette laese sich als
-- "ausgewaehlt" statt als "gefaehrlich".
--------------------------------------------------

WeintCodex.GameColors = {
    enemyInCombat = {0.800, 0.180, 0.180, 1.0},
    hostile       = {0.450, 0.125, 0.110, 1.0},   -- Feind, der (noch) nicht kaempft
    neutral       = {0.850, 0.720, 0.220, 1.0},
    tapped        = {0.500, 0.500, 0.500, 1.0},
    friendly      = {0.300, 0.780, 0.420, 1.0},
    boss          = {0.860, 0.400, 0.120, 1.0},
    elite         = {0.620, 0.220, 0.460, 1.0},
    focus         = {0.250, 0.700, 0.850, 1.0},
    target        = {0.460, 0.890, 0.580, 1.0},

    tankAggro     = {0.204, 0.780, 0.482, 1.0},
    tankLosing    = {0.941, 0.651, 0.227, 1.0},
    dpsAggro      = {1.000, 0.500, 0.000, 1.0},
    dpsNear       = {0.941, 0.651, 0.227, 1.0},

    cast          = {0.486, 0.424, 1.000, 1.0},   -- = Akzent: Fortschritt
    castLocked    = {0.450, 0.450, 0.480, 1.0},   -- nicht unterbrechbar
    castFailed    = {0.800, 0.100, 0.100, 1.0},
    targetRing    = {0.486, 0.424, 1.000, 1.0},   -- = Akzent: Fokusrahmen

    plateBg       = {0.100, 0.100, 0.118, 1.0},
    plateBorder   = {0.000, 0.000, 0.000, 1.0},
    healthFallback= {0.240, 0.720, 0.360, 1.0},
    powerFallback = {0.300, 0.500, 0.900, 1.0},
    comboPoint    = {1.000, 0.820, 0.000, 1.0},
}

--------------------------------------------------
-- Schriften
--------------------------------------------------
-- Drei Familien, drei Aufgaben - dieselbe Aufteilung wie in der Companion
-- (`gui/theme/tokens.py`, FAMILY_DISPLAY/SANS/MONO):
--
--   display  Newsreader      Ueberschriften. Eine Ueberschrift steht einmal
--                            auf der Seite und soll Charakter haben.
--   sans     IBM Plex Sans   alles Bedienbare. Eine Beschriftung steht
--                            dreissigmal und soll dicht und ruhig sein.
--   mono     IBM Plex Mono   Zahlen, Kennzahlen, Rubriken (Eyebrow).
--
-- `serif`/`serifBold` bleiben als Namen bestehen und zeigen auf die
-- Display-Schrift - sie sind in der Vorgaengerfassung auf die Grotesk
-- gebogen worden, weil es keine Serifenschrift gab. Jetzt gibt es eine.
--------------------------------------------------

WeintCodex.Fonts = {
    sans        = MEDIA .. "fonts\\IBMPlexSans-Regular.ttf",
    sansMedium  = MEDIA .. "fonts\\IBMPlexSans-Medium.ttf",
    sansSemi    = MEDIA .. "fonts\\IBMPlexSans-SemiBold.ttf",
    sansBold    = MEDIA .. "fonts\\IBMPlexSans-Bold.ttf",
    mono        = MEDIA .. "fonts\\IBMPlexMono-Regular.ttf",
    monoMedium  = MEDIA .. "fonts\\IBMPlexMono-Medium.ttf",
    monoBold    = MEDIA .. "fonts\\IBMPlexMono-SemiBold.ttf",

    display     = MEDIA .. "fonts\\Newsreader-Medium.ttf",
    displaySemi = MEDIA .. "fonts\\Newsreader-SemiBold.ttf",
    displayQuiet= MEDIA .. "fonts\\Newsreader-MediumItalic.ttf",

    serif       = MEDIA .. "fonts\\Newsreader-Medium.ttf",
    serifBold   = MEDIA .. "fonts\\Newsreader-SemiBold.ttf",
}
local F = WeintCodex.Fonts
--------------------------------------------------
-- Icon-Helper
--------------------------------------------------
-- Das UI-Font unterstuetzt keine Unicode-Emoji - vorher verwendete Zeichen
-- wie ⚔ ✦ 📦 wurden als leere Kaestchen dargestellt. Es werden deshalb nur
-- echte Texturen ueber die |T...|t-Escape-Syntax verwendet.
--------------------------------------------------

function WeintCodex.Icon(iconPath, size)
    size = size or 14
    return "|T" .. iconPath .. ":" .. size .. "|t"
end

local CLASS_ICON_ATLAS = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes"

function WeintCodex.ClassIcon(classToken, size)
    size = size or 14
    local coords = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[classToken]
    if not coords then
        return ""
    end
    return string.format(
        "|T%s:%d:%d:0:0:256:256:%d:%d:%d:%d|t",
        CLASS_ICON_ATLAS, size, size,
        coords[1] * 256, coords[2] * 256, coords[3] * 256, coords[4] * 256
    )
end

--------------------------------------------------
-- Grundbausteine
--------------------------------------------------

local function Col(name)
    if type(name) == "table" then return name end
    return C[name] or C.textNormal
end

local function SetSolidBg(frame, r, g, b, a)
    local tex = frame:CreateTexture(nil, "BACKGROUND")
    tex:SetAllPoints(frame)
    tex:SetColorTexture(r, g, b, a or 1.0)
    return tex
end

-- Zwei-Punkt-verankert statt auf GetWidth()/GetHeight() gerechnet: der Rahmen
-- waechst mit dem Frame mit. Wichtig, weil mehrere Aufrufer (Chip, Danger-
-- Button) ihre Breite erst NACH dem Rahmen aus der Textbreite bestimmen - mit
-- Groessen aus der Bauzeit waeren die Kanten dort 0 breit.
-- Gibt die vier Kanten als Tabelle zurueck. Fast jeder Aufrufer ignoriert
-- das; wer einen Rahmen umfaerbt (ein Feld, das gesetzt/leer oder
-- ueberfahren/ruhend anzeigt), braucht sie und hat sonst keinen Zugriff
-- darauf - der Rahmen ist sonst nirgends greifbar.
local function DrawBorder(f, r, g, b, a, thick)
    thick = thick or 1
    local function T(p1, p2, w, h)
        local t = f:CreateTexture(nil, "OVERLAY")
        t:SetColorTexture(r, g, b, a)
        t:SetPoint(p1, f, p1, 0, 0)
        t:SetPoint(p2, f, p2, 0, 0)
        if w then t:SetWidth(w) end
        if h then t:SetHeight(h) end
        return t
    end
    return {
        T("TOPLEFT",    "TOPRIGHT",    nil,   thick),
        T("BOTTOMLEFT", "BOTTOMRIGHT", nil,   thick),
        T("TOPLEFT",    "BOTTOMLEFT",  thick, nil),
        T("TOPRIGHT",   "BOTTOMRIGHT", thick, nil),
    }
end

local function DrawHLine(parent, r, g, b, a, offsetY, layer)
    local t = parent:CreateTexture(nil, layer or "OVERLAY")
    t:SetHeight(1)
    t:SetPoint("TOPLEFT",  parent, "TOPLEFT",  0, offsetY)
    t:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, offsetY)
    t:SetColorTexture(r, g, b, a)
    return t
end

--------------------------------------------------
-- Runde Ecken
--------------------------------------------------
-- Vier Viertelkreis-Masken in der Farbe des Untergrunds stanzen die Ecken
-- aus. Die Maske (media/ui/corner.tga, 32x32) ist massstabsunabhaengig, ein
-- einziges Bild deckt jeden Radius ab. Zweierpotenz, weil der Client keine
-- andere Texturgroesse laedt.
--------------------------------------------------

local CORNER_UV = {
    TOPLEFT     = { 0, 1, 0, 1 },
    TOPRIGHT    = { 1, 0, 0, 1 },
    BOTTOMLEFT  = { 0, 1, 1, 0 },
    BOTTOMRIGHT = { 1, 0, 1, 0 },
}

function WeintCodex.CutCorners(frame, radius, backdrop, layer, sublevel)
    radius = radius or 14
    local col = Col(backdrop or "bgDark")
    local out = {}
    for point, uv in pairs(CORNER_UV) do
        local t = frame:CreateTexture(nil, layer or "OVERLAY", nil, sublevel or 6)
        t:SetTexture(CORNER)
        t:SetSize(radius, radius)
        t:SetPoint(point, frame, point, 0, 0)
        t:SetTexCoord(uv[1], uv[2], uv[3], uv[4])
        t:SetVertexColor(col[1], col[2], col[3], col[4] or 1.0)
        out[point] = t
    end
    frame._corners = out
    return out
end

-- Faerbt bereits gesetzte Eckmasken um (z.B. wenn eine Karte auf einer
-- anderen Flaeche landet als beim Bau angenommen).
function WeintCodex.RecolorCorners(frame, backdrop)
    if not frame._corners then return end
    local col = Col(backdrop)
    for _, t in pairs(frame._corners) do
        t:SetVertexColor(col[1], col[2], col[3], col[4] or 1.0)
    end
end

--------------------------------------------------
-- Flaechen mit Verlauf
--------------------------------------------------

-- CSS `linear-gradient(180deg, a, b)` -> oben a, unten b.
-- WoW `SetGradient("VERTICAL", min, max)` -> min unten, max oben.
local function ApplyVerticalGradient(tex, topCol, bottomCol)
    local t, b = Col(topCol), Col(bottomCol)
    tex:SetTexture(WHITE)
    tex:SetGradient("VERTICAL",
        CreateColor(b[1], b[2], b[3], b[4] or 1.0),
        CreateColor(t[1], t[2], t[3], t[4] or 1.0))
end
WeintCodex.ApplyVerticalGradient = ApplyVerticalGradient

-- CSS `linear-gradient(90deg, a, b)` -> links a, rechts b.
-- WoW `SetGradient("HORIZONTAL", min, max)` -> min links, max rechts.
--
-- Wofuer es das braucht: eine Flaeche, die nach einer Seite hin
-- anlaeuft, ist das Mittel, mit dem dieses Addon Atmosphaere
-- zeichnet, wo kein Bild da ist - und da ist fast nirgends eines
-- (siehe WeintCodex.Artwork weiter unten und
-- modules/dungeonpages.lua). Ein geratener Texturpfad zeichnet im
-- Spiel ein gruenes Rechteck; gezeichnet wird deshalb nur, was in
-- data/artwork.lua steht und im Ordner liegt.
local function ApplyHorizontalGradient(tex, leftCol, rightCol)
    local l, r = Col(leftCol), Col(rightCol)
    tex:SetTexture(WHITE)
    tex:SetGradient("HORIZONTAL",
        CreateColor(l[1], l[2], l[3], l[4] or 1.0),
        CreateColor(r[1], r[2], r[3], r[4] or 1.0))
end
WeintCodex.ApplyHorizontalGradient = ApplyHorizontalGradient

--------------------------------------------------
-- Artwork
--------------------------------------------------
-- DER EINE BAUSTEIN FUER BILDER, und es soll kein zweiter daneben
-- entstehen. Wer eine Flaeche bebildert, ruft WeintCodex.Artwork auf
-- und bekommt Bild UND Schleier - beides gehoert zusammen, weil ein
-- Bild ohne Schleier den Text darauf unlesbar macht und ein Schleier
-- ohne Bild nichts verdeckt.
--
-- DREI DINGE, DIE DIESER BAUSTEIN GARANTIERT:
--
--   1. KEIN BILD OHNE EINTRAG. `art = nil` heisst: es gibt keines,
--      und die Funktion gibt nil zurueck, ohne irgendetwas zu
--      zeichnen. Die Flaeche sieht dann aus wie vorher. Das ist der
--      Rueckfall, auf den sich jede Seite verlassen kann - und der
--      Grund, dass ein Dungeon ohne Artwork nicht anders behandelt
--      werden muss als einer mit.
--   2. KEINE VERZERRUNG. Ein Bild in einen Kasten anderer Form zu
--      spannen, staucht Gesichter. CoverCoords rechnet stattdessen
--      den AUSSCHNITT aus, der den Kasten fuellt: die kuerzere Seite
--      wird beschnitten, die laengere ganz genutzt, und beschnitten
--      wird um einen Fokuspunkt herum (`focusX`/`focusY`, Vorgabe
--      Mitte). Weil der Kasten seine Groesse erst im Spiel kennt,
--      haengt die Rechnung an OnSizeChanged UND laesst sich mit der
--      gerechneten Breite vorab setzen - so bauen Spiel und
--      Prueflauf dieselbe Seite.
--   3. KEIN GERATENER PFAD. `art.file` kommt aus data/artwork.lua,
--      und was dort steht, liegt im Ordner - data_test.lua prueft
--      genau das. Ein Pfad, den niemand geprueft hat, zeichnet im
--      Spiel ein gruenes Rechteck, und das sieht aus wie ein Bild.
--------------------------------------------------

-- Welcher Ausschnitt des Bildes den Kasten fuellt, ohne zu verzerren.
-- Gibt die vier Werte zurueck, die SetTexCoord erwartet.
function WeintCodex.CoverCoords(texW, texH, boxW, boxH, focusX, focusY)
    if type(texW) ~= "number" or type(texH) ~= "number"
        or type(boxW) ~= "number" or type(boxH) ~= "number"
        or texW <= 0 or texH <= 0 or boxW <= 0 or boxH <= 0 then
        return 0, 1, 0, 1
    end

    local box, tex = boxW / boxH, texW / texH
    local u, v = 1, 1
    if box > tex then
        v = tex / box            -- Kasten breiter als das Bild: Hoehe beschneiden
    elseif box < tex then
        u = box / tex            -- Kasten hoeher als das Bild: Breite beschneiden
    end

    local left = (focusX or 0.5) - u / 2
    if left < 0 then left = 0 elseif left > 1 - u then left = 1 - u end
    local top = (focusY or 0.5) - v / 2
    if top < 0 then top = 0 elseif top > 1 - v then top = 1 - v end

    return left, left + u, top, top + v
end

-- `art`  : Eintrag aus data/artwork.lua ({ file, w, h, focusX, focusY })
--          oder nil - dann passiert nichts.
-- `opts` : { width, height   = gerechnete Kastenmasse (Pflicht, damit der
--                              Prueflauf denselben Ausschnitt sieht),
--            band            = nur die obersten n px der Flaeche tragen
--                              das Bild; ohne Angabe die ganze,
--            dim             = Helligkeit 0..1 (Vorgabe 1),
--            inset           = Abstand zur Kante (Vorgabe 1, wegen der
--                              runden Ecken),
--            layer, sublevel,
--            top, foot       = Hoehe der beiden waagerechten Schleier,
--            left            = Farbton des senkrechten Schleiers,
--            footTone        = Farbton unten (Vorgabe artFoot) }
function WeintCodex.Artwork(frame, art, opts)
    if not art or not art.file then return nil end
    opts = opts or {}

    local inset  = opts.inset or 1
    local layer  = opts.layer or "BACKGROUND"
    local sub    = opts.sublevel or 1
    local band   = opts.band
    local focusX = opts.focusX or art.focusX or 0.5
    local focusY = opts.focusY or art.focusY or 0.5

    -- Ein Stueck der Flaeche, `offset` px unter ihrer Oberkante und
    -- `height` px hoch. Ohne `height` reicht es bis zur Unterkante.
    local function Region(sublevel, offset, height)
        local t = frame:CreateTexture(nil, layer, nil, sublevel)
        local y = -(inset + (offset or 0))
        t:SetPoint("TOPLEFT",  frame, "TOPLEFT",   inset, y)
        t:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -inset, y)
        if height then
            t:SetHeight(height)
        else
            t:SetPoint("BOTTOMLEFT",  frame, "BOTTOMLEFT",   inset, inset)
            t:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -inset, inset)
        end
        return t
    end

    -- Ein Stueck am unteren Ende des Bildes. Traegt die Flaeche das
    -- Bild nur als Band, haengt es am Bandende; sonst am Kartenfuss.
    local function Foot(sublevel, height)
        if band then return Region(sublevel, band - height, height) end
        local t = frame:CreateTexture(nil, layer, nil, sublevel)
        t:SetHeight(height)
        t:SetPoint("BOTTOMLEFT",  frame, "BOTTOMLEFT",   inset, inset)
        t:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -inset, inset)
        return t
    end

    -- WoW kennt nur Backslashes im Texturpfad; data/artwork.lua schreibt
    -- sie als Schraegstrich, damit der Eintrag lesbar bleibt und der
    -- Prueflauf daraus einen Dateinamen machen kann.
    local file = string.gsub(tostring(art.file), "/", "\\")
    local tex  = Region(sub, 0, band)
    tex:SetTexture(MEDIA .. file)
    local dim = opts.dim or 1.0
    tex:SetVertexColor(dim, dim, dim, 1.0)

    -- Oben gedaempft: dort stehen Nummer und Kennzeichen.
    if opts.top then
        ApplyVerticalGradient(Region(sub + 1, 0, opts.top), "artTop", "artNone")
    end
    -- Unten deutlich dunkler: dort steht der Name.
    if opts.foot then
        ApplyVerticalGradient(Foot(sub + 2, opts.foot),
            "artNone", opts.footTone or "artFoot")
    end
    -- Nach links hin ruhig: dort steht alles, was gelesen werden muss.
    if opts.left then
        ApplyHorizontalGradient(Region(sub + 3, 0, band), opts.left, "artNone")
    end

    local function Fit(w, h)
        h = band or h
        if type(w) ~= "number" or type(h) ~= "number" or w <= 0 or h <= 0 then return end
        tex:SetTexCoord(WeintCodex.CoverCoords(art.w, art.h, w, h, focusX, focusY))
    end
    Fit(opts.width, opts.height)

    -- Im Spiel kennt der Rahmen seine Breite erst, wenn er sie hat -
    -- und sie aendert sich mit dem Fenster, ohne dass die Seite neu
    -- gezeichnet wird (siehe PlaceGrid). Der Ausschnitt haengt
    -- deshalb an der WIRKLICHEN Groesse; die gerechnete oben ist die,
    -- mit der der Prueflauf arbeitet.
    if frame.HookScript then
        frame:HookScript("OnSizeChanged", function(_, w, h) Fit(w, h) end)
    end

    return {
        texture = tex,
        Fit     = Fit,
        Dim     = function(value)
            tex:SetVertexColor(value, value, value, 1.0)
        end,
    }
end

--------------------------------------------------
-- Karte
--------------------------------------------------
-- Der zentrale Baustein des Entwurfs: kein Rahmen, sondern Verlauf plus eine
-- 1-px-Oberkante, die links und rechts 8 px eingerueckt ist. `tone = "accent"`
-- macht daraus die hervorgehobene Variante (Verlauf mit einem Hauch Violett,
-- Oberkante in Akzentfarbe) - im Entwurf immer genau eine pro Seite.
--
-- opts: { width, height, radius = 14, tone = "plain"|"accent"|"flat",
--         backdrop = "bgDark", button = false, hover = false }
--------------------------------------------------

function WeintCodex.CreateSurface(parent, opts)
    opts = opts or {}
    local f = CreateFrame(opts.button and "Button" or "Frame", nil, parent)
    if opts.width  then f:SetWidth(opts.width)   end
    if opts.height then f:SetHeight(opts.height) end

    local tone   = opts.tone or "plain"
    local radius = opts.radius or 14

    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(f)
    f._bg = bg

    local topLine
    if tone == "flat" then
        bg:SetColorTexture(unpack(Col(opts.surface or "surface1")))
    else
        if tone == "accent" then
            ApplyVerticalGradient(bg, "accentCardTop", "accentCardBot")
        else
            ApplyVerticalGradient(bg, "cardTop", "cardBottom")
        end
        -- Oberkante: 8 px beidseitig eingerueckt, damit sie an den runden
        -- Ecken nicht ueber den Rand hinauslaeuft.
        topLine = f:CreateTexture(nil, "ARTWORK")
        topLine:SetHeight(1)
        topLine:SetPoint("TOPLEFT",  f, "TOPLEFT",   8, 0)
        topLine:SetPoint("TOPRIGHT", f, "TOPRIGHT", -8, 0)
        if tone == "accent" then
            topLine:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.34)
        else
            topLine:SetColorTexture(1, 1, 1, 0.06)
        end
    end
    f._topLine = topLine

    if radius > 0 then
        WeintCodex.CutCorners(f, radius, opts.backdrop or "bgDark")
    end

    f.SetTone = function(self, newTone)
        if newTone == "accent" then
            ApplyVerticalGradient(self._bg, "accentCardTop", "accentCardBot")
            if self._topLine then
                self._topLine:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.34)
            end
        else
            ApplyVerticalGradient(self._bg, "cardTop", "cardBottom")
            if self._topLine then self._topLine:SetColorTexture(1, 1, 1, 0.06) end
        end
    end

    -- Hover wie im Entwurf: die Flaeche wird eine Stufe heller, nicht umrandet.
    f.SetSurface = function(self, surfaceName)
        local col = C[surfaceName]
        if not col then return end
        self._bg:SetTexture(WHITE)
        self._bg:SetGradient("VERTICAL", CreateColor(col[1], col[2], col[3], col[4] or 1),
                                          CreateColor(col[1], col[2], col[3], col[4] or 1))
    end

    return f
end

--------------------------------------------------
-- UTF-8-Textwerkzeuge
--------------------------------------------------
-- Der Client liefert und erwartet UTF-8, Lua 5.1 kennt aber nur Bytes. Jede
-- Stelle, die Text ZEICHENWEISE anfasst - sperren, kuerzen, versalisieren -
-- muss deshalb selbst wissen, wo ein Zeichen anfaengt. Tut sie das nicht,
-- zerfaellt ein Umlaut in seine zwei Bytes, und der Client zeichnet fuer
-- jedes ein leeres Kaestchen: genau so wurde in 2.0.0.0 aus "ÜBERSICHT"
-- ein "<>BERSICHT" und aus "ENGPÄSSE" ein "ENGP<>SSE".
--
-- Deshalb hat jede dieser drei Operationen hier ihre eigene Fassung, und
-- kein Aufrufer darf string.upper/#/:sub direkt auf Anzeigetext anwenden.
--------------------------------------------------

-- Bytelaenge des UTF-8-Zeichens, das an Position i beginnt. Unbekannte
-- Bytes zaehlen als 1, damit eine kaputte Eingabe keine Endlosschleife
-- ausloest, sondern nur haesslich aussieht.
local function Utf8CharLen(s, i)
    local b = s:byte(i)
    if not b then return 0 end
    if b < 0xC0 then return 1
    elseif b < 0xE0 then return 2
    elseif b < 0xF0 then return 3
    else return 4 end
end

-- Laenge in Zeichen (nicht in Bytes).
function WeintCodex.Utf8Len(s)
    if not s then return 0 end
    s = tostring(s)
    local n, i = 0, 1
    while i <= #s do
        i = i + Utf8CharLen(s, i)
        n = n + 1
    end
    return n
end

-- Teilkette in Zeichen. `to = nil` heisst "bis zum Ende".
function WeintCodex.Utf8Sub(s, from, to)
    if not s then return "" end
    s = tostring(s)
    from = from or 1
    local i, n, startByte, endByte = 1, 0, nil, #s
    while i <= #s do
        n = n + 1
        if n == from then startByte = i end
        local nextI = i + Utf8CharLen(s, i)
        if to and n == to then endByte = nextI - 1; break end
        i = nextI
    end
    if not startByte then return "" end
    return s:sub(startByte, math.min(endByte, #s))
end

-- Versalien. string.upper faellt hier aus: es arbeitet byteweise und wuerde
-- bei gesetztem Gebietsschema auch die Folgebytes eines UTF-8-Zeichens
-- anfassen und es damit zerstoeren. ASCII geht deshalb ueber ein Muster,
-- der Rest ueber die Tabelle.
--
-- "ß" bleibt "ß": die Versalform waere "SS" und macht die Zeile laenger,
-- als der Aufrufer sie gemessen hat.
local UTF8_UPPER = {
    ["ä"] = "Ä", ["ö"] = "Ö", ["ü"] = "Ü",
    ["à"] = "À", ["á"] = "Á", ["â"] = "Â", ["ã"] = "Ã", ["å"] = "Å",
    ["è"] = "È", ["é"] = "É", ["ê"] = "Ê", ["ë"] = "Ë",
    ["ì"] = "Ì", ["í"] = "Í", ["î"] = "Î", ["ï"] = "Ï",
    ["ò"] = "Ò", ["ó"] = "Ó", ["ô"] = "Ô", ["õ"] = "Õ", ["ø"] = "Ø",
    ["ù"] = "Ù", ["ú"] = "Ú", ["û"] = "Û",
    ["ñ"] = "Ñ", ["ç"] = "Ç", ["æ"] = "Æ", ["ý"] = "Ý",
}

function WeintCodex.Upper(s)
    if not s then return "" end
    s = tostring(s):gsub("[a-z]+", string.upper)
    return (s:gsub("[\194-\244][\128-\191]*", function(ch)
        return UTF8_UPPER[ch]
    end))
end
local Upper = WeintCodex.Upper

-- Kuerzt auf hoechstens maxChars ZEICHEN und setzt ein Auslassungszeichen.
function WeintCodex.Truncate(text, maxChars)
    text = tostring(text or "")
    if WeintCodex.Utf8Len(text) <= maxChars then return text end
    return WeintCodex.Utf8Sub(text, 1, math.max(1, maxChars - 1)) .. "…"
end

--------------------------------------------------
-- Textbausteine
--------------------------------------------------

-- Eyebrow: mono, versal, weit gesperrt. WoW kennt kein letter-spacing, die
-- Sperrung wird deshalb durch eingefuegte Haarspatien nachgebildet - je
-- Zeichen eine, nicht je Byte (siehe oben).
local function Spaced(text)
    if not text then return "" end
    local s = tostring(text)
    local out, i = {}, 1
    while i <= #s do
        local n = Utf8CharLen(s, i)
        out[#out + 1] = s:sub(i, i + n - 1)
        i = i + n
    end
    return table.concat(out, "\194\160")
end
WeintCodex.Spaced = Spaced

function WeintCodex.Eyebrow(parent, text, opts)
    opts = opts or {}
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont(F.mono, opts.size or 10, "")
    fs:SetTextColor(unpack(Col(opts.color or "textDim")))
    fs:SetText(Spaced(Upper(text or "")))
    fs:SetJustifyH(opts.justify or "LEFT")
    return fs
end

function WeintCodex.PageTitle(parent, text, opts)
    opts = opts or {}
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont(opts.font or F.display, opts.size or 28, "")
    fs:SetTextColor(unpack(Col(opts.color or "textBright")))
    fs:SetText(text or "")
    fs:SetJustifyH(opts.justify or "LEFT")
    return fs
end

function WeintCodex.Label(parent, text, opts)
    opts = opts or {}
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont(opts.font or F.sans, opts.size or 13, "")
    fs:SetTextColor(unpack(Col(opts.color or "textMuted")))
    fs:SetText(text or "")
    fs:SetJustifyH(opts.justify or "LEFT")
    if opts.width then fs:SetWidth(opts.width) end
    return fs
end

-- Kennzahl in Mono, wie im Entwurf rechts im Kopf bzw. in den Kacheln.
function WeintCodex.MonoNumber(parent, text, opts)
    opts = opts or {}
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont(F.monoBold, opts.size or 24, "")
    fs:SetTextColor(unpack(Col(opts.color or "textNormal")))
    fs:SetText(text or "")
    fs:SetJustifyH(opts.justify or "LEFT")
    return fs
end

--------------------------------------------------
-- Fliesstext mit berechneter Hoehe
--------------------------------------------------
-- Ein umgebrochener Absatz ist so hoch, wie der Client ihn setzt - und
-- der Client ist im kopflosen Prueflauf nicht da. GetStringHeight()
-- antwortet dort mit einer Zeile, und eine Seite, die damit rechnet,
-- ist im Prueflauf kuerzer als im Spiel: genau der Fehler, den der
-- Lauf finden soll, bliebe unsichtbar.
--
-- Die Hoehe wird deshalb GESCHAETZT, aus Zeichen je Zeile bei der
-- schmalsten Breite, die der Aufrufer nennt - und zwar im Spiel und
-- im Prueflauf gleich. Die Schaetzung ist absichtlich knapp (0,60 em
-- je Zeichen, IBM Plex Sans liegt darunter): im Zweifel bleibt unter
-- dem Absatz Luft, nie laeuft er in den naechsten hinein.
--
-- Zeichen, nicht Bytes (Utf8Len), und ohne Farbcodes: ein |cffRRGGBB
-- ist zehn Bytes, die keine Breite haben.
--
-- opts:
--   width     schmalste Breite, in die der Absatz passen muss (Pflicht)
--   size      Schriftgrad (13), font, color, spacing (3), justify
--
-- Rueckgabe: der FontString (Hoehe gesetzt, noch nicht verankert) und
-- seine Hoehe.
--------------------------------------------------

local function PlainText(text)
    local s = tostring(text or "")
    s = s:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    return s
end

function WeintCodex.EstimateLines(text, cols)
    cols = math.max(1, cols or 1)
    local lines = 0
    for segment in (PlainText(text) .. "\n"):gmatch("(.-)\n") do
        local len = WeintCodex.Utf8Len(segment)
        lines = lines + math.max(1, math.ceil(len / cols))
    end
    return lines
end

function WeintCodex.Paragraph(parent, text, opts)
    opts = opts or {}
    local size    = opts.size or 13
    local spacing = opts.spacing or 3
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont(opts.font or F.sans, size, "")
    fs:SetJustifyH(opts.justify or "LEFT")
    fs:SetJustifyV("TOP")
    fs:SetSpacing(spacing)
    fs:SetWordWrap(true)
    fs:SetTextColor(unpack(Col(opts.color or "textMuted")))
    fs:SetText(text or "")

    local cols  = math.floor((opts.width or 300) / (size * 0.60))
    local lines = WeintCodex.EstimateLines(text, cols)
    local h     = lines * (size + spacing)
    fs:SetHeight(h)
    return fs, h
end

--------------------------------------------------
-- Seitenkopf
--------------------------------------------------
-- Das wiederkehrende Muster aller entworfenen Seiten: kleine Mono-Zeile
-- (Eyebrow), darunter die Ueberschrift, optional eine Unterzeile und rechts
-- Kennzahlen in Mono. Der einzige Ort, an dem ein Seitenkopf entsteht -
-- vorher baute ihn jede Seite selbst, und im selben Stand standen deshalb
-- drei Titelformen nebeneinander: akzentfarbene 19er, neutrale 22er und
-- neutrale 26er.
--
-- Die Bausteine haengen bewusst *aneinander* (Titel unter dem Eyebrow,
-- Unterzeile unter dem Titel) statt an gerechneten Y-Werten: eine
-- Ankerkette liefert bei gleichen Abstaenden exakt dasselbe Bild wie der
-- handgebaute Kopf, den sie ersetzt, ohne dass Schriftmetriken geschaetzt
-- werden muessen.
--
-- opts:
--   eyebrow, eyebrowSize   Mono-Versalie ueber dem Titel
--   title, titleSize       Ueberschrift (Newsreader, textBright)
--   titleGap               Abstand Eyebrow -> Titel (Vorgabe 6)
--   sub, subSize, subColor Unterzeile; subInline setzt sie neben den Titel
--   stats                  { { key=, label=, value=, tone= }, ... }, rechts
--   statWidth, statGap     Vorgabe 64 / 78 (Mass der Kennzahlenblocks)
--   height                 Hoehe, die der Kopf im Layout belegt
--   x, y                   Innenabstand (Vorgabe PAD_X / PAD_Y)
--
-- Rueckgabe: der Kopf-Frame mit .Title / .Sub / .Stats[key] zum Nachtragen
-- lebender Werte und .Height als belegte Hoehe.
--------------------------------------------------

function WeintCodex.PageHead(parent, opts)
    opts = opts or {}
    local x = opts.x or WeintCodex.Metrics.PAD_X
    local y = opts.y or WeintCodex.Metrics.PAD_Y

    local head = CreateFrame("Frame", nil, parent)
    head:SetPoint("TOPLEFT",  parent, "TOPLEFT",   x, -y)
    head:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -x, -y)

    local eyebrowSize = opts.eyebrowSize or 10
    local titleSize   = opts.titleSize or 26
    local subSize     = opts.subSize or 10

    local anchor
    if opts.eyebrow then
        local eb = WeintCodex.Eyebrow(head, opts.eyebrow, { size = eyebrowSize })
        eb:SetPoint("TOPLEFT", head, "TOPLEFT", 0, 0)
        head.EyebrowStr = eb
        anchor = eb
    end

    local title = WeintCodex.PageTitle(head, opts.title or "", { size = titleSize })
    if anchor then
        title:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -(opts.titleGap or 6))
    else
        title:SetPoint("TOPLEFT", head, "TOPLEFT", 0, 0)
    end
    head.Title = title

    -- Die Unterzeile traegt haeufig schon eingefaerbte Textstuecke (Spec,
    -- Warnungen). Sie wird deshalb nur angelegt und bleibt leer, wenn der
    -- Aufrufer sie selbst fuellt.
    if opts.sub ~= nil then
        local sub = head:CreateFontString(nil, "OVERLAY")
        sub:SetFont(F.sans, subSize, "")
        sub:SetTextColor(unpack(Col(opts.subColor or "textDim")))
        sub:SetJustifyH("LEFT")
        sub:SetText(opts.sub)
        if opts.subInline then
            sub:SetPoint("BOTTOMLEFT", title, "BOTTOMRIGHT", 12, 3)
        else
            sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -(opts.subGap or 4))
        end
        if opts.subWidth then sub:SetWidth(opts.subWidth) end
        head.Sub = sub
    end

    -- Kennzahlen rechts, von rechts nach links gesetzt: Label als gesperrte
    -- Versalie ueber der Mono-Zahl.
    head.Stats = {}
    local statW  = opts.statWidth or 64
    local statGap = opts.statGap or 78
    local sx = 0
    for i = #(opts.stats or {}), 1, -1 do
        local st = opts.stats[i]
        local box = CreateFrame("Frame", nil, head)
        box:SetSize(statW, 42)
        box:SetPoint("TOPRIGHT", head, "TOPRIGHT", sx, 0)

        local lbl = WeintCodex.Eyebrow(box, st.label or "", { size = 9, justify = "RIGHT" })
        lbl:SetPoint("TOPRIGHT", box, "TOPRIGHT", 0, 0)

        local val = box:CreateFontString(nil, "OVERLAY")
        val:SetFont(F.monoBold, opts.statSize or 22, "")
        val:SetPoint("TOPRIGHT", lbl, "BOTTOMRIGHT", 0, -4)
        val:SetJustifyH("RIGHT")
        val:SetTextColor(unpack(Col(st.tone or "textNormal")))
        val:SetText(st.value ~= nil and tostring(st.value) or "")

        head.Stats[st.key or i] = val
        sx = sx - statGap
    end

    head.Height = opts.height or 64
    head:SetHeight(head.Height)
    return head
end

--------------------------------------------------
-- Statuspunkt (7 px)
--------------------------------------------------
-- Im Entwurf durchgaengig der Traeger von "Zustand". Ein leerer Punkt
-- (tone = nil) ist "noch offen/unbekannt" und wird nur umrandet.
--------------------------------------------------

function WeintCodex.StatusDot(parent, tone, size)
    size = size or 7
    local d = parent:CreateTexture(nil, "OVERLAY")
    d:SetSize(size, size)
    if tone then
        local col = Col(tone)
        d:SetColorTexture(col[1], col[2], col[3], col[4] or 1.0)
    else
        local col = C.textFaint
        d:SetColorTexture(col[1], col[2], col[3], 0.55)
    end
    return d
end

--------------------------------------------------
-- Chip / Badge
--------------------------------------------------
-- Pille mit 13 % Fuellung und 38 % Rand derselben Farbe - die Werte stammen
-- eins zu eins aus dem Entwurf.
--------------------------------------------------

function WeintCodex.Chip(parent, opts)
    opts = opts or {}
    local tone = opts.tone or "textMuted"
    local col  = Col(tone)
    local textCol = Col(opts.textColor or tone)

    local h = opts.height or 26
    local chip = CreateFrame("Frame", nil, parent)
    chip:SetHeight(h)

    local bg = chip:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(chip)
    bg:SetColorTexture(col[1], col[2], col[3], opts.fill or 0.13)
    DrawBorder(chip, col[1], col[2], col[3], opts.borderAlpha or 0.38, 1)

    local lbl = chip:CreateFontString(nil, "OVERLAY")
    lbl:SetFont(F.monoBold, opts.size or 10, "")
    lbl:SetTextColor(textCol[1], textCol[2], textCol[3], 1.0)
    lbl:SetText(Spaced(Upper(opts.text or "")))
    lbl:SetPoint("CENTER", chip, "CENTER", 0, 0)
    chip._label = lbl

    chip:SetWidth((opts.width) or (lbl:GetStringWidth() + (opts.padding or 24)))

    -- Voll gerundet (Radius = halbe Hoehe) - im Entwurf sind Chips Pillen.
    -- Liegt spaeter im Zeichenstapel als der Rahmen und deckt dessen Ecken ab.
    WeintCodex.CutCorners(chip, math.floor(h / 2), opts.backdrop or "cardTop")

    chip.SetText = function(self, t)
        self._label:SetText(Spaced(Upper(t or "")))
        if not opts.width then
            self:SetWidth(self._label:GetStringWidth() + (opts.padding or 20))
        end
    end
    return chip
end

--------------------------------------------------
-- Schaltflaechen
--------------------------------------------------
-- Drei Auspraegungen aus dem Entwurf:
--   primary   - Akzentverlauf, dunkler Text, 40 hoch (eine pro Ansicht)
--   secondary - #17171C, heller Text, 34 hoch
--   ghost     - ohne Flaeche, nur Text
--   danger    - roter Rand auf 14-%-Fuellung (Loeschen)
--------------------------------------------------

function WeintCodex.CreateButton(parent, opts)
    opts = opts or {}
    local kind = opts.kind or "secondary"
    local b = CreateFrame("Button", nil, parent)
    b:SetHeight(opts.height or (kind == "primary" and 40 or 34))

    local bg = b:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(b)
    b._bg = bg

    local textCol
    local function paint(hovered)
        if kind == "primary" then
            if hovered then
                ApplyVerticalGradient(bg, "accentBright", "accentBright")
            else
                ApplyVerticalGradient(bg, "accentBright", "accent")
            end
        elseif kind == "ghost" then
            bg:SetColorTexture(1, 1, 1, hovered and 0.05 or 0)
        elseif kind == "danger" then
            bg:SetColorTexture(C.red[1], C.red[2], C.red[3], hovered and 0.22 or 0.14)
        else
            local s = hovered and C.borderStrong or C.surface3
            bg:SetColorTexture(s[1], s[2], s[3], 1.0)
        end
    end
    paint(false)

    if kind == "primary" then
        textCol = C.ink
    elseif kind == "danger" then
        textCol = C.dangerBright
        DrawBorder(b, C.red[1], C.red[2], C.red[3], 0.50, 1)
    elseif kind == "ghost" then
        textCol = C.textMuted
    else
        textCol = C.textNormal
    end

    local lbl = b:CreateFontString(nil, "OVERLAY")
    lbl:SetFont(F.sansSemi, opts.size or 12, "")
    lbl:SetTextColor(textCol[1], textCol[2], textCol[3], 1.0)
    lbl:SetText(opts.text or "")
    lbl:SetPoint("CENTER", b, "CENTER", 0, 0)
    b._label = lbl

    b:SetWidth(opts.width or (lbl:GetStringWidth() + (opts.padding or 36)))

    if opts.radius ~= 0 then
        WeintCodex.CutCorners(b, opts.radius or 6, opts.backdrop or "bgDark")
    end

    b:SetScript("OnEnter", function(self)
        paint(true)
        if opts.tooltip then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(opts.tooltip, 1, 1, 1, 1, true)
            GameTooltip:Show()
        end
    end)
    b:SetScript("OnLeave", function()
        paint(false)
        GameTooltip:Hide()
    end)
    if opts.onClick then b:SetScript("OnClick", opts.onClick) end

    b.SetText = function(self, t)
        self._label:SetText(t or "")
        if not opts.width then
            self:SetWidth(self._label:GetStringWidth() + (opts.padding or 36))
        end
    end
    return b
end

--------------------------------------------------
-- Segmented Control (Reiterleiste)
--------------------------------------------------
-- Ersetzt die frueheren Unternavigationen in der Seitenleiste. Muster aus dem
-- Entwurf: Behaelter #08080A mit 4 px Innenabstand, aktives Segment #17171C.
-- Ein Segment darf einen Statuspunkt tragen ({ text=, dot="danger" }).
--
-- opts: { items = { {text=, dot=, key=}, ... }, onSelect = function(key, i),
--         selected = 1, backdrop = "bgDark" }
--------------------------------------------------

function WeintCodex.CreateSegmentedControl(parent, opts)
    opts = opts or {}
    local items = opts.items or {}

    local bar = CreateFrame("Frame", nil, parent)
    bar:SetHeight(38)
    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(bar)
    bg:SetColorTexture(unpack(C.surface1))
    WeintCodex.CutCorners(bar, 10, opts.backdrop or "bgDark")

    local segs, total = {}, 8
    for i, item in ipairs(items) do
        local s = CreateFrame("Button", nil, bar)
        s:SetHeight(30)

        local sbg = s:CreateTexture(nil, "BACKGROUND")
        sbg:SetAllPoints(s)
        sbg:SetColorTexture(0, 0, 0, 0)

        local lbl = s:CreateFontString(nil, "OVERLAY")
        lbl:SetFont(F.sansSemi, 12, "")
        lbl:SetText(item.text or "")
        lbl:SetPoint("LEFT", s, "LEFT", 14, 0)

        local dot
        if item.dot then
            dot = WeintCodex.StatusDot(s, item.dot, 7)
            dot:SetPoint("LEFT", lbl, "RIGHT", 8, 0)
        end

        local w = lbl:GetStringWidth() + 28 + (dot and 15 or 0)
        s:SetWidth(w)
        s:SetPoint("LEFT", bar, "LEFT", total - 4, 0)
        total = total + w + 6

        s._bg, s._label, s._key, s._index = sbg, lbl, item.key or i, i
        segs[i] = s
    end
    bar:SetWidth(total - 6 + 8)

    local selected = opts.selected or 1

    local function apply()
        for i, s in ipairs(segs) do
            if i == selected then
                s._bg:SetColorTexture(unpack(C.surface3))
                s._label:SetTextColor(unpack(C.textBright))
                if not s._rounded then
                    WeintCodex.CutCorners(s, 6, "surface1")
                    s._rounded = true
                end
                if s._corners then
                    for _, t in pairs(s._corners) do t:Show() end
                end
            else
                s._bg:SetColorTexture(0, 0, 0, 0)
                s._label:SetTextColor(unpack(C.textMuted))
                if s._corners then
                    for _, t in pairs(s._corners) do t:Hide() end
                end
            end
        end
    end

    for i, s in ipairs(segs) do
        s:SetScript("OnEnter", function(self)
            if i ~= selected then self._label:SetTextColor(unpack(C.textNormal)) end
        end)
        s:SetScript("OnLeave", function(self)
            if i ~= selected then self._label:SetTextColor(unpack(C.textMuted)) end
        end)
        s:SetScript("OnClick", function(self)
            selected = i
            apply()
            if opts.onSelect then opts.onSelect(self._key, i) end
        end)
    end
    apply()

    bar.Select = function(_, i)
        selected = i
        apply()
    end
    bar.GetSelected = function() return selected end
    bar._segments = segs
    return bar
end

--------------------------------------------------
-- Schalter (Ein/Aus) und Regler
--------------------------------------------------
-- Beides gab es bis 2.6.0.0 nur als Eigenbau in modules/rotationtrainer.lua,
-- weil sonst nirgends etwas umzuschalten war: jede Option des Addons stand
-- allein hinter einem Slash-Befehl. Mit der Einstellungsseite ist der Schalter
-- die haeufigste Bedienform des Addons ueberhaupt - also gehoert er hierher
-- und nicht ein zweites Mal in die Seite, die ihn zuerst braucht.
--
-- Der Schalter liest seinen Zustand ueber `get` und schreibt ihn ueber `set`.
-- Bewusst kein eigener Speicher im Widget: die Wahrheit steht in den
-- SavedData des jeweiligen Moduls, und ein zweiter Stand daneben waere genau
-- die Sorte Abweichung, die man erst bemerkt, wenn beide sich widersprechen.
--
-- opts: { label=, description=, width=, height=,
--         get=function() end, set=function(on) end,
--         disabled=function() end, disabledHint=, onChange=function(on) end }
--------------------------------------------------

function WeintCodex.CreateToggle(parent, opts)
    opts = opts or {}

    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(opts.height or (opts.description and 46 or 34))
    -- Die Breite muss VOR dem ersten Sync stehen: die Erlaeuterung leitet ihre
    -- Breite von der Zeile ab, und ohne sie meldet GetStringHeight die Hoehe
    -- einer einzigen Zeile - der umbrochene Rest laege dann in der naechsten.
    if opts.width then row:SetWidth(opts.width) end

    local hover = row:CreateTexture(nil, "BACKGROUND")
    hover:SetAllPoints(row)
    hover:SetColorTexture(1, 1, 1, 0)

    -- Der Schalter selbst: Bahn plus Knauf. Beides eigene Texturen statt
    -- eines CheckButtons - das Blizzard-Kaestchen bringt seine eigene
    -- Grafiksprache mit und faellt in dieser Oberflaeche sofort auf. Beide
    -- bleiben eckig: CutCorners deckt Ecken mit der Farbe des Untergrunds ab
    -- und braucht dafuer einen Frame, eine Textur hat keine.
    local track = row:CreateTexture(nil, "ARTWORK")
    track:SetSize(34, 16)
    track:SetPoint("LEFT", row, "LEFT", 0, 0)

    local knob = row:CreateTexture(nil, "OVERLAY")
    knob:SetSize(12, 12)

    local label = row:CreateFontString(nil, "OVERLAY")
    label:SetFont(F.sans, 13, "")
    label:SetJustifyH("LEFT")
    label:SetText(opts.label or "")

    local hint
    if opts.description then
        label:SetPoint("TOPLEFT", row, "TOPLEFT", 46, -2)
        label:SetPoint("RIGHT",   row, "RIGHT",  -12, 0)
        hint = row:CreateFontString(nil, "OVERLAY")
        hint:SetFont(F.mono, 9, "")
        hint:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -4)
        hint:SetPoint("RIGHT",   row,   "RIGHT",    -12, 0)
        hint:SetJustifyH("LEFT")
        hint:SetTextColor(unpack(C.textFaint))
        hint:SetText(opts.description)
    else
        label:SetPoint("LEFT",  row, "LEFT",   46, 0)
        label:SetPoint("RIGHT", row, "RIGHT", -12, 0)
    end
    row._label, row._hint = label, hint

    local function Disabled()
        return opts.disabled and opts.disabled() and true or false
    end

    -- Die Erlaeuterung bricht um, sobald sie breiter ist als die Zeile. Mit
    -- fester Zeilenhoehe laege die naechste Zeile dann darin - dieselbe
    -- Ueberlegung wie bei TextHeight in modules/gearalert.lua, und
    -- gemessen wird erst, nachdem der Text steht.
    local baseH = opts.height or (opts.description and 46 or 34)
    local function FitHeight()
        if not hint then
            row:SetHeight(baseH)
            return
        end
        local ok, h = pcall(hint.GetStringHeight, hint)
        if not ok or type(h) ~= "number" or h <= 0 then h = 11 end
        row:SetHeight(math.max(baseH, 23 + math.ceil(h) + 6))
    end

    row.Sync = function(self)
        local off = Disabled()
        local on  = (not off) and opts.get and opts.get() and true or false
        knob:ClearAllPoints()
        if on then
            track:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.85)
            knob:SetColorTexture(unpack(C.ink))
            knob:SetPoint("RIGHT", track, "RIGHT", -2, 0)
            label:SetTextColor(unpack(C.textBright))
        else
            track:SetColorTexture(C.surface3[1], C.surface3[2], C.surface3[3], 1.0)
            knob:SetColorTexture(unpack(off and C.textGhost or C.textDim))
            knob:SetPoint("LEFT", track, "LEFT", 2, 0)
            label:SetTextColor(unpack(off and C.textDim or C.textMuted))
        end
        if hint then
            hint:SetText((off and opts.disabledHint) or opts.description or "")
            FitHeight()
        end
    end

    row:SetScript("OnEnter", function(self)
        if Disabled() then return end
        hover:SetColorTexture(1, 1, 1, 0.03)
    end)
    row:SetScript("OnLeave", function() hover:SetColorTexture(1, 1, 1, 0) end)
    row:SetScript("OnClick", function(self)
        if Disabled() then return end
        local nextValue = not (opts.get and opts.get())
        if opts.set then opts.set(nextValue) end
        self:Sync()
        if opts.onChange then opts.onChange(nextValue) end
    end)

    row:Sync()
    return row
end

--------------------------------------------------
-- Regler
--------------------------------------------------
-- opts: { label=, min=, max=, step=, get=, set=, format=function(v) end,
--         width= }
--
-- `set` bekommt den Wert schon gerastert; `format` liefert die Beschriftung
-- rechts. Der Regler schreibt bei jeder Bewegung - eine Fensterskalierung,
-- die erst beim Loslassen greift, laesst sich nicht einstellen, weil man
-- waehrend des Ziehens nicht sieht, was man tut.
--------------------------------------------------

function WeintCodex.CreateSlider(parent, opts)
    opts = opts or {}
    local minV  = opts.min or 0
    local maxV  = opts.max or 1
    local step  = opts.step or 0.05

    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(opts.height or 46)

    local label = row:CreateFontString(nil, "OVERLAY")
    label:SetFont(F.sans, 13, "")
    label:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -2)
    label:SetTextColor(unpack(C.textMuted))
    label:SetText(opts.label or "")

    local value = row:CreateFontString(nil, "OVERLAY")
    value:SetFont(F.monoMedium, 11, "")
    value:SetPoint("TOPRIGHT", row, "TOPRIGHT", -2, -2)
    value:SetTextColor(unpack(C.textNormal))

    local slider = CreateFrame("Slider", nil, row)
    slider:SetOrientation("HORIZONTAL")
    slider:EnableMouse(true)
    slider:SetHeight(16)
    slider:SetPoint("BOTTOMLEFT",  row, "BOTTOMLEFT",  0, 4)
    slider:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 4)
    slider:SetMinMaxValues(minV, maxV)
    slider:SetValueStep(step)
    if slider.SetObeyStepOnDrag then slider:SetObeyStepOnDrag(true) end

    local track = slider:CreateTexture(nil, "ARTWORK")
    track:SetHeight(4)
    track:SetPoint("LEFT",  slider, "LEFT",  0, 0)
    track:SetPoint("RIGHT", slider, "RIGHT", 0, 0)
    track:SetColorTexture(unpack(C.surface3))

    local fill = slider:CreateTexture(nil, "OVERLAY")
    fill:SetHeight(4)
    fill:SetPoint("LEFT", track, "LEFT", 0, 0)
    fill:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.85)

    local thumb = slider:CreateTexture(nil, "OVERLAY")
    thumb:SetTexture(WHITE)
    thumb:SetVertexColor(unpack(C.accentBright))
    thumb:SetSize(10, 14)
    slider:SetThumbTexture(thumb)

    local function Snap(v)
        v = math.max(minV, math.min(maxV, tonumber(v) or minV))
        return math.floor((v - minV) / step + 0.5) * step + minV
    end

    -- Der eingefaerbte Teil der Bahn haengt an der Breite, und die steht bei
    -- einem beidseitig verankerten Regler beim Bauen noch nicht fest. Deshalb
    -- eine eigene Funktion, die auch aus OnSizeChanged heraus laeuft - sonst
    -- bliebe die Fuellung bis zur ersten Bewegung des Reglers leer.
    local current = minV
    local function Paint(v)
        current = v
        value:SetText(opts.format and opts.format(v) or tostring(v))
        local w = slider:GetWidth() or 0
        fill:SetWidth(w > 1 and math.max(1, w * (v - minV) / (maxV - minV)) or 1)
        if v > minV then fill:Show() else fill:Hide() end
    end

    row.Sync = function()
        local v = Snap(opts.get and opts.get() or minV)
        slider:SetValue(v)
        Paint(v)
    end

    slider:SetScript("OnValueChanged", function(_, raw)
        local v = Snap(raw)
        Paint(v)
        if opts.set then opts.set(v) end
    end)
    slider:SetScript("OnSizeChanged", function() Paint(current) end)

    row._slider = slider
    row:SetScript("OnShow", function(self) self.Sync() end)
    row.Sync()
    return row
end

--------------------------------------------------
-- Fortschrittsbalken
--------------------------------------------------

function WeintCodex.CreateMeter(parent, opts)
    opts = opts or {}
    local h = opts.height or 6
    local m = CreateFrame("Frame", nil, parent)
    m:SetHeight(h)
    if opts.width then m:SetWidth(opts.width) end

    local track = m:CreateTexture(nil, "BACKGROUND")
    track:SetAllPoints(m)
    track:SetColorTexture(unpack(C.surface1))

    local fill = m:CreateTexture(nil, "ARTWORK")
    fill:SetPoint("TOPLEFT", m, "TOPLEFT", 0, 0)
    fill:SetPoint("BOTTOMLEFT", m, "BOTTOMLEFT", 0, 0)
    local col = Col(opts.tone or "accent")
    fill:SetColorTexture(col[1], col[2], col[3], 1.0)
    m._fill = fill

    m.SetValue = function(self, pct, tone)
        pct = math.max(0, math.min(1, pct or 0))
        local w = (self:GetWidth() or 0) * pct
        self._fill:SetWidth(math.max(pct > 0 and 1 or 0, w))
        if tone then
            local c = Col(tone)
            self._fill:SetColorTexture(c[1], c[2], c[3], 1.0)
        end
    end
    m:SetValue(opts.value or 0)
    return m
end

--------------------------------------------------
-- Zeilentrenner
--------------------------------------------------

function WeintCodex.RowLine(parent, offsetY, tone)
    local col = Col(tone or "rowLine")
    return DrawHLine(parent, col[1], col[2], col[3], col[4] or 1.0, offsetY or 0, "ARTWORK")
end

--------------------------------------------------
-- Hex-Helper
--------------------------------------------------

function WeintCodex.ColorText(colorName, text)
    local col = C[colorName]
    if not col then return text end
    return string.format("|cff%02x%02x%02x%s|r",
        (col[1] or 0) * 255, (col[2] or 0) * 255, (col[3] or 0) * 255, text)
end

--------------------------------------------------
-- Scrollbereich
--------------------------------------------------
-- Die Standard-Bildlaufleiste (UIPanelScrollFrameTemplate) frisst 26 px. Der
-- Entwurf zeichnet 8 px. `slim = true` blendet die Blizzard-Optik aus und
-- setzt einen schlanken Griff darueber - dieselbe Loesung wie bei den
-- Bossnotizen, nur an einer Stelle statt an zweien.
--------------------------------------------------

function WeintCodex.CreateScrollArea(parent, x, y, w, h, slim)
    local sf = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    sf:SetSize(w, h)
    sf:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)

    local inner = CreateFrame("Frame", nil, sf)
    inner:SetSize(w - (slim and 10 or 20), h)
    sf:SetScrollChild(inner)

    -- Mausrad. UIPanelScrollFrameTemplate bringt in dieser Clientfassung
    -- keinen eigenen Radhandler mit; ohne ihn bleibt allein das Ziehen des
    -- Reglers, und der ist in der schlanken Form 8 px breit. Ein
    -- Bildlauffeld, das auf das Rad nicht reagiert, gilt zu Recht als
    -- kaputt - und beim Changelog-Popup nach einem Update ist das Rad die
    -- einzige Geste, die der Nutzer dort ueberhaupt erwartet.
    sf:EnableMouseWheel(true)
    sf:SetScript("OnMouseWheel", function(self, delta)
        local range = self:GetVerticalScrollRange() or 0
        if range <= 0 then return end
        local target = (self:GetVerticalScroll() or 0) - (delta * 28)
        if target < 0 then target = 0 elseif target > range then target = range end
        self:SetVerticalScroll(target)
    end)

    local bar = _G[(sf:GetName() or "") .. "ScrollBar"] or sf.ScrollBar
    if not bar then
        for _, child in ipairs({ sf:GetChildren() }) do
            if child:GetObjectType() == "Slider" then bar = child break end
        end
    end
    -- Fuer Aufrufer, die die Leiste nur einblenden wollen, wenn es
    -- wirklich etwas zu rollen gibt (siehe core/onboarding.lua).
    sf.WCScrollBar = bar

    if slim then
        if bar then
            bar:SetWidth(8)
            for _, region in ipairs({ bar:GetRegions() }) do
                if region:GetObjectType() == "Texture" then region:SetTexture(nil) end
            end
            local up, down = bar:GetChildren()
            if up   then up:Hide()   ; up:SetHeight(1)   end
            if down then down:Hide() ; down:SetHeight(1) end
            local thumb = bar:GetThumbTexture()
            if thumb then
                thumb:SetTexture(WHITE)
                thumb:SetVertexColor(C.textFaint[1], C.textFaint[2], C.textFaint[3], 0.65)
                thumb:SetSize(4, 40)
            end
        end
    end
    return sf, inner
end

--------------------------------------------------
-- Zahlen-/Zeitformate
--------------------------------------------------
-- Spiegeln die Darstellung der Companion-App, damit dieselbe Auswertung
-- ingame und auf dem Desktop gleich aussieht. Dezimaltrennzeichen ist das
-- deutsche Komma.
--------------------------------------------------

function WeintCodex.FormatAmount(value)
    value = tonumber(value) or 0
    local sign = value < 0 and "-" or ""
    value = math.abs(value)
    local text
    if value >= 1000000 then
        text = string.format("%.2fM", value / 1000000)
    elseif value >= 1000 then
        text = string.format("%.1fk", value / 1000)
    else
        text = string.format("%d", value + 0.5)
    end
    return sign .. (text:gsub("%.", ","))
end

function WeintCodex.FormatClock(seconds)
    seconds = math.floor(tonumber(seconds) or 0)
    if seconds < 0 then seconds = 0 end
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = seconds % 60
    if h > 0 then return string.format("%d:%02d:%02d", h, m, s) end
    return string.format("%02d:%02d", m, s)
end

function WeintCodex.FormatPercent(value, decimals)
    value = tonumber(value) or 0
    local text = string.format("%." .. (decimals or 0) .. "f", value)
    return (text:gsub("%.", ",")) .. " %"
end

-- Tausenderpunkt wie im Entwurf ("+14 210" mit schmalem Leerzeichen).
-- Gruppiert wird rueckwaerts, das Trennzeichen aber erst NACH dem zweiten
-- reverse() eingesetzt: `string.reverse` dreht Bytes, nicht Zeichen. Ein
-- direkt eingefuegtes NBSP (\194\160) kam als \160\194 wieder heraus - eine
-- ungueltige UTF-8-Folge, die der Client als zwei Ersatzkaestchen zeichnet
-- ("+18<><>056" in den Werte-Summen der Charakteruebersicht). Der
-- Platzhalter \1 ist einbytig und uebersteht das Drehen unbeschadet.
function WeintCodex.FormatGrouped(value)
    local num = tonumber(value) or 0
    local s = tostring(math.floor(math.abs(num)))
    local out = s:reverse():gsub("(%d%d%d)", "%1\1"):reverse()
    out = out:gsub("^\1", ""):gsub("\1", "\194\160")
    return (num < 0 and "-" or "") .. out
end

--------------------------------------------------
-- Altlasten der v1-Oberflaeche
--------------------------------------------------
-- Bleiben erhalten, weil rund 40 Aufrufstellen sie nutzen. Rahmen und
-- Eck-Akzente sind in der neuen Sprache aber kein Gestaltungsmittel mehr:
-- CreateCard liefert deshalb eine Karte im neuen Sinn, egal welchen `style`
-- der Aufrufer noch mitgibt.
--------------------------------------------------

function WeintCodex.DrawSlimBorder(frame, colorName, alpha, thick)
    thick = thick or 1
    local col = C[colorName] or C.hairline
    alpha = alpha or col[4] or 1.0
    DrawBorder(frame, col[1], col[2], col[3], alpha, thick)
end

function WeintCodex.DrawCornerAccents(frame, colorName, size, thick)
    size  = size  or 12
    thick = thick or 2
    local col = C[colorName] or C.accent
    local function Corner(point, hx, hy)
        local h = frame:CreateTexture(nil, "OVERLAY")
        h:SetColorTexture(col[1], col[2], col[3], col[4] or 1.0)
        h:SetPoint(point, frame, point, hx, hy)
        h:SetSize(size, thick)
        local v = frame:CreateTexture(nil, "OVERLAY")
        v:SetColorTexture(col[1], col[2], col[3], col[4] or 1.0)
        v:SetPoint(point, frame, point, hx, hy)
        v:SetSize(thick, size)
    end
    Corner("TOPLEFT", 0, 0)     Corner("TOPRIGHT", 0, 0)
    Corner("BOTTOMLEFT", 0, 0)  Corner("BOTTOMRIGHT", 0, 0)
end

function WeintCodex.CreateCard(parent, opts)
    opts = opts or {}
    local card = WeintCodex.CreateSurface(parent, {
        width    = opts.width,
        height   = opts.height,
        tone     = opts.tone or (opts.surface == "surface1" and "flat" or "plain"),
        surface  = opts.surface,
        radius   = opts.radius or 14,
        backdrop = opts.backdrop or "bgDark",
        button   = opts.buttonStyle,
    })
    card._surface = opts.surface or "surface2"

    local titleStr
    if opts.title then
        titleStr = card:CreateFontString(nil, "OVERLAY")
        titleStr:SetFont(F.sansSemi, 14, "")
        titleStr:SetPoint("TOPLEFT", card, "TOPLEFT", 20, -16)
        titleStr:SetTextColor(unpack(Col(opts.titleColor or "textBright")))
        titleStr:SetText(opts.title)
    end
    card.SetTitle = function(self, text)
        if titleStr then titleStr:SetText(text) end
    end
    return card
end

--------------------------------------------------
-- Auswahlliste
--------------------------------------------------
-- Seit dem optionalen Oberflaechenpaket (ui/) gibt es Einstellungen mit
-- mehr als zwei Zustaenden (welcher Text in welcher Ecke einer Plakette
-- steht). Ein Schalter kann das nicht, und UIDropDownMenu bringt nicht
-- nur die Blizzard-Optik mit, sondern ist im modernen Client eine der
-- bekanntesten Quellen fuer Taint.
--
-- Aufbau wie der Regler: Beschriftung oben links, das Bedienelement
-- darunter in voller Breite. Die Liste selbst gibt es EINMAL fuer alle
-- Auswahlfelder - es kann ohnehin nur eine offen sein, und ein Rahmen je
-- Feld waere eine Sammlung, die nur waechst (WoW gibt Frames nie frei).
--
-- opts: { label=, items = { {value=, text=}, ... } | function() end,
--         get=, set=function(value) end, width=,
--         disabled=function() end, disabledHint= }
--------------------------------------------------

local ARROW_TEX = MEDIA .. "ui\\arrow"
local dropMenu, dropCatcher

local function EnsureDropMenu()
    if dropMenu then return dropMenu end

    -- Ein unsichtbarer Vollbildfaenger hinter der Liste: ein Klick
    -- daneben schliesst sie, wie jede Liste im Spiel.
    dropCatcher = CreateFrame("Button", nil, UIParent)
    dropCatcher:SetAllPoints(UIParent)
    dropCatcher:SetFrameStrata("FULLSCREEN_DIALOG")
    dropCatcher:Hide()

    dropMenu = CreateFrame("Frame", nil, UIParent)
    dropMenu:SetFrameStrata("FULLSCREEN_DIALOG")
    dropMenu:SetFrameLevel(dropCatcher:GetFrameLevel() + 10)
    dropMenu:EnableMouse(true)
    dropMenu:Hide()
    local bg = dropMenu:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(dropMenu)
    bg:SetColorTexture(unpack(C.surface2))
    DrawBorder(dropMenu, C.borderStrong[1], C.borderStrong[2], C.borderStrong[3], 1, 1)
    dropMenu._buttons = {}

    dropCatcher:SetScript("OnClick", function()
        dropMenu:Hide()
    end)
    dropMenu:SetScript("OnHide", function() dropCatcher:Hide() end)
    return dropMenu
end

local function OpenDropMenu(owner, items, current, onPick)
    local menu = EnsureDropMenu()
    local ITEM_H = 24
    local width = math.max(120, owner:GetWidth() or 120)

    for i, item in ipairs(items) do
        local b = menu._buttons[i]
        if not b then
            b = CreateFrame("Button", nil, menu)
            b:SetHeight(ITEM_H)
            local hl = b:CreateTexture(nil, "BACKGROUND")
            hl:SetAllPoints(b)
            hl:SetColorTexture(1, 1, 1, 0)
            b._hl = hl
            local mark = b:CreateTexture(nil, "ARTWORK")
            mark:SetSize(3, ITEM_H - 8)
            mark:SetPoint("LEFT", b, "LEFT", 0, 0)
            mark:SetColorTexture(unpack(C.accent))
            b._mark = mark
            local t = b:CreateFontString(nil, "OVERLAY")
            t:SetFont(F.sans, 12, "")
            t:SetPoint("LEFT", b, "LEFT", 12, 0)
            t:SetPoint("RIGHT", b, "RIGHT", -8, 0)
            t:SetJustifyH("LEFT")
            t:SetWordWrap(false)
            b._text = t
            b:SetScript("OnEnter", function(self) self._hl:SetColorTexture(1, 1, 1, 0.06) end)
            b:SetScript("OnLeave", function(self) self._hl:SetColorTexture(1, 1, 1, 0) end)
            menu._buttons[i] = b
        end
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT",  menu, "TOPLEFT",  1, -1 - (i - 1) * ITEM_H)
        b:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -1, -1 - (i - 1) * ITEM_H)
        b._text:SetText(item.text or tostring(item.value))
        local selected = (item.value == current)
        b._text:SetTextColor(unpack(selected and C.textBright or C.textMuted))
        if selected then b._mark:Show() else b._mark:Hide() end
        b:SetScript("OnClick", function()
            menu:Hide()
            onPick(item.value)
        end)
        b:Show()
    end
    for i = #items + 1, #menu._buttons do menu._buttons[i]:Hide() end

    menu:SetSize(width, #items * ITEM_H + 2)
    menu:ClearAllPoints()
    menu:SetPoint("TOPLEFT", owner, "BOTTOMLEFT", 0, -2)
    -- Die Liste gehoert zum Fenster, aus dem sie kommt: ist das skaliert
    -- (das Einstellungsfenster hat einen eigenen Regler), muss sie es auch
    -- sein, sonst stuende sie zu klein neben ihrem Feld.
    if owner.GetEffectiveScale and UIParent.GetEffectiveScale then
        local ok, s = pcall(function()
            return owner:GetEffectiveScale() / UIParent:GetEffectiveScale()
        end)
        if ok and type(s) == "number" and s > 0 then menu:SetScale(s) end
    end
    dropCatcher:Show()
    menu:Show()
end

function WeintCodex.CreateDropdown(parent, opts)
    opts = opts or {}

    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(opts.height or 52)
    if opts.width then row:SetWidth(opts.width) end

    local label = row:CreateFontString(nil, "OVERLAY")
    label:SetFont(F.sans, 13, "")
    label:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -2)
    label:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    label:SetJustifyH("LEFT")
    label:SetWordWrap(false)
    label:SetText(opts.label or "")

    local btn = CreateFrame("Button", nil, row)
    btn:SetHeight(26)
    btn:SetPoint("BOTTOMLEFT",  row, "BOTTOMLEFT",  0, 2)
    btn:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 2)
    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(btn)

    local value = btn:CreateFontString(nil, "OVERLAY")
    value:SetFont(F.sans, 12, "")
    value:SetPoint("LEFT",  btn, "LEFT",  10, 0)
    value:SetPoint("RIGHT", btn, "RIGHT", -26, 0)
    value:SetJustifyH("LEFT")
    value:SetWordWrap(false)

    local chevron = btn:CreateTexture(nil, "OVERLAY")
    chevron:SetTexture(ARROW_TEX)
    chevron:SetSize(10, 10)
    chevron:SetPoint("RIGHT", btn, "RIGHT", -9, 0)
    if chevron.SetRotation then chevron:SetRotation(math.pi) end

    local function Items()
        local items = opts.items
        if type(items) == "function" then items = items() end
        return items or {}
    end

    local function Disabled()
        return opts.disabled and opts.disabled() and true or false
    end

    local hovered = false
    local function Paint()
        local off = Disabled()
        local s = (hovered and not off) and C.borderStrong or C.surface3
        bg:SetColorTexture(s[1], s[2], s[3], 1.0)
        label:SetTextColor(unpack(off and C.textDim or C.textMuted))
        value:SetTextColor(unpack(off and C.textFaint or C.textNormal))
        chevron:SetVertexColor(unpack(off and C.textGhost or C.textDim))
    end

    row.Sync = function()
        local current = opts.get and opts.get()
        local text = (opts.disabled and Disabled() and opts.disabledHint) or nil
        if not text then
            for _, item in ipairs(Items()) do
                if item.value == current then text = item.text break end
            end
        end
        -- Ein gespeicherter Wert, den die Liste nicht (mehr) kennt, wird
        -- genannt statt verschwiegen - ein leeres Feld saehe aus wie "aus".
        value:SetText(text or tostring(current or "–"))
        Paint()
    end

    btn:SetScript("OnEnter", function(self)
        hovered = true
        Paint()
        if opts.tooltip then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(opts.tooltip, 1, 1, 1, 1, true)
            GameTooltip:Show()
        end
    end)
    btn:SetScript("OnLeave", function()
        hovered = false
        Paint()
        GameTooltip:Hide()
    end)
    btn:SetScript("OnClick", function(self)
        if Disabled() then return end
        OpenDropMenu(self, Items(), opts.get and opts.get(), function(v)
            if opts.set then opts.set(v) end
            row.Sync()
            if opts.onChange then opts.onChange(v) end
        end)
    end)

    row._button = btn
    row:SetScript("OnShow", function(self) self.Sync() end)
    row.Sync()
    return row
end

--------------------------------------------------
-- Farbfeld
--------------------------------------------------
-- Aufbau wie der Schalter: das Bedienelement links (34 x 16, dieselbe
-- Groesse wie die Schalterbahn), die Beschriftung daneben. Zwei Zeilen,
-- die in derselben Liste stehen, sollen sich nicht in der Form
-- unterscheiden, nur im Inhalt.
--
-- Das Farbfeld zeigt die gespeicherte Farbe - das ist der eine Ort in
-- diesem Addon, an dem eine Flaeche eine Farbe traegt, die NICHT aus
-- `C` kommt, sondern vom Spieler.
--
-- opts: { label=, description=, get=function() return {r=,g=,b=} end,
--         set=function(r, g, b) end, width=, disabled=function() end }
--------------------------------------------------

local function OpenColorPicker(r, g, b, onChange)
    local cpf = _G.ColorPickerFrame
    if not cpf then return false end

    local prev = { r, g, b }
    local function Current()
        if cpf.GetColorRGB then return cpf:GetColorRGB() end
        return r, g, b
    end

    -- Der moderne Client (10.2.5+) hat eine Einrichtungsfunktion; der
    -- aeltere Weg ueber Felder bleibt als Rueckfall, weil niemand weiss,
    -- welchen Stand der Forever-Client an dieser Stelle hat.
    if cpf.SetupColorPickerAndShow then
        cpf:SetupColorPickerAndShow({
            r = r, g = g, b = b,
            hasOpacity = false,
            swatchFunc = function() onChange(Current()) end,
            cancelFunc = function() onChange(prev[1], prev[2], prev[3]) end,
        })
        return true
    end

    cpf.func = function() onChange(Current()) end
    cpf.cancelFunc = function() onChange(prev[1], prev[2], prev[3]) end
    cpf.hasOpacity = false
    if cpf.SetColorRGB then cpf:SetColorRGB(r, g, b) end
    if _G.ShowUIPanel then _G.ShowUIPanel(cpf) else cpf:Show() end
    return true
end

function WeintCodex.CreateColorSwatch(parent, opts)
    opts = opts or {}

    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(opts.height or 34)
    if opts.width then row:SetWidth(opts.width) end

    local hover = row:CreateTexture(nil, "BACKGROUND")
    hover:SetAllPoints(row)
    hover:SetColorTexture(1, 1, 1, 0)

    local frameTex = row:CreateTexture(nil, "ARTWORK")
    frameTex:SetSize(34, 16)
    frameTex:SetPoint("LEFT", row, "LEFT", 0, 0)
    frameTex:SetColorTexture(unpack(C.borderStrong))

    local swatch = row:CreateTexture(nil, "OVERLAY")
    swatch:SetPoint("TOPLEFT", frameTex, "TOPLEFT", 1, -1)
    swatch:SetPoint("BOTTOMRIGHT", frameTex, "BOTTOMRIGHT", -1, 1)
    swatch:SetTexture(WHITE)

    local label = row:CreateFontString(nil, "OVERLAY")
    label:SetFont(F.sans, 13, "")
    label:SetPoint("LEFT", row, "LEFT", 46, 0)
    label:SetPoint("RIGHT", row, "RIGHT", -8, 0)
    label:SetJustifyH("LEFT")
    label:SetWordWrap(false)
    label:SetText(opts.label or "")

    local function Disabled()
        return opts.disabled and opts.disabled() and true or false
    end

    row.Sync = function()
        local col = opts.get and opts.get() or {}
        local off = Disabled()
        swatch:SetVertexColor(col.r or 1, col.g or 1, col.b or 1, off and 0.35 or 1)
        label:SetTextColor(unpack(off and C.textDim or C.textMuted))
    end

    row:SetScript("OnEnter", function(self)
        if Disabled() then return end
        hover:SetColorTexture(1, 1, 1, 0.03)
        if opts.tooltip then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(opts.tooltip, 1, 1, 1, 1, true)
            GameTooltip:Show()
        end
    end)
    row:SetScript("OnLeave", function()
        hover:SetColorTexture(1, 1, 1, 0)
        GameTooltip:Hide()
    end)
    row:SetScript("OnClick", function()
        if Disabled() then return end
        local col = opts.get and opts.get() or {}
        OpenColorPicker(col.r or 1, col.g or 1, col.b or 1, function(r, g, b)
            if opts.set then opts.set(r, g, b) end
            row.Sync()
        end)
    end)

    row:SetScript("OnShow", function(self) self.Sync() end)
    row.Sync()
    return row
end

--------------------------------------------------
-- Neu laden per Klick
--------------------------------------------------
-- AUF FOREVER IST NEULADEN GESCHUETZT. ReloadUI() bzw. C_UI.Reload() aus
-- Addon-Code endet dort in ADDON_ACTION_BLOCKED ("hat versucht die
-- geschuetzte Funktion 'Reload()' aufzurufen") - im Beta-Client
-- gemessen (6.0.0.0), nicht vermutet. Erlaubt ist, was der Spieler
-- selbst ausloest: ein Klick auf einen Aktionsknopf, der das Makro
-- "/reload" ausfuehrt. Dieselbe Loesung verwendet EllesmereUI auf
-- Forever.
--
-- AttachReload legt deshalb ueber einen vorhandenen Knopf einen
-- unsichtbaren InsecureActionButton, der den Klick als Makro ausfuehrt.
-- Der Knopf darunter behaelt Aussehen und Hover; sein eigenes OnClick
-- kommt nicht mehr an (der obere faengt den Klick), `onClick` laeuft
-- stattdessen VOR dem Neuladen.
--
-- Die Attribute werden einmal gesetzt und nie geaendert. Schreiben kann
-- man sie nur ausserhalb des Kampfes; wer den Knopf im Kampf bekommt,
-- bekommt ihn scharf, sobald der Kampf vorbei ist, und bis dahin einen
-- Hinweis im Chat statt eines blockierten Aufrufs.
--
-- Es gibt bewusst KEINE Funktion "jetzt neu laden" zum Aufrufen: jeder
-- Aufruf ohne Klick waere genau der blockierte Fall.
--------------------------------------------------

WeintCodex.RELOAD_HINT = "Zum Übernehmen /reload in den Chat eingeben."

local function ReloadHint()
    print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " " .. WeintCodex.RELOAD_HINT)
end

local function ArmReload(ov)
    ov:SetAttribute("useOnKeyDown", false)
    ov:SetAttribute("type", "macro")
    ov:SetAttribute("macrotext", "/reload")
    ov._armed = true
end

function WeintCodex.AttachReload(button, onClick)
    local ok, ov = pcall(CreateFrame, "Button", nil, button, "InsecureActionButtonTemplate")
    if not ok or not ov then
        -- Ohne die Vorlage gibt es keinen erlaubten Weg. Dann sagt der
        -- Knopf, was zu tun ist, statt einen Fehler auszuloesen.
        button:SetScript("OnClick", function()
            if onClick then onClick() end
            ReloadHint()
        end)
        return nil
    end

    ov:SetAllPoints(button)
    ov:SetFrameLevel((button:GetFrameLevel() or 1) + 5)
    -- Nur beim Loslassen, und das Attribut sagt es auch: ungesetzt folgt
    -- der Klick der Spieleinstellung "beim Druecken ausloesen", und die
    -- liefert ein Knopf, der nur auf Loslassen hoert, nie.
    if ov.RegisterForClicks then ov:RegisterForClicks("AnyUp") end

    if InCombatLockdown and InCombatLockdown() then
        local waiter = CreateFrame("Frame")
        waiter:RegisterEvent("PLAYER_REGEN_ENABLED")
        waiter:SetScript("OnEvent", function(self)
            self:UnregisterAllEvents()
            ArmReload(ov)
        end)
    else
        ArmReload(ov)
    end

    -- Maus und Tooltip an den sichtbaren Knopf darunter weiterreichen.
    ov:SetScript("OnEnter", function()
        local f = button:GetScript("OnEnter")
        if f then f(button) end
    end)
    ov:SetScript("OnLeave", function()
        local f = button:GetScript("OnLeave")
        if f then f(button) end
    end)
    ov:HookScript("OnClick", function()
        if onClick then onClick() end
        if not ov._armed then ReloadHint() end
    end)
    button._reloadOverlay = ov
    return ov
end

WeintCodex.SetSolidBg = SetSolidBg
WeintCodex.DrawBorder = DrawBorder
WeintCodex.SetBorder  = DrawBorder
WeintCodex.DrawHLine  = DrawHLine
WeintCodex.C          = C

--------------------------------------------------
-- Fenster
--------------------------------------------------
-- Aufbau nach Entwurf 1a: Titelleiste 40, Navigationsspalte 232 mit Gruppen,
-- Inhalt daneben. Die frueheren vier Spalten (Rail 64 | Sub-Nav 240 | Inhalt |
-- Inspector 340) sind damit auf zwei zusammengezogen.
--
-- Der Inspector verschwindet nicht als API: er wird zum Detailbereich INNERHALB
-- der Seite (rechte Spalte, 380 breit). Neun Module liefern ueber
-- Navigation.SetInspector Bloecke - die zeichnen jetzt dorthin, statt in eine
-- eigene Fensterspalte. ContentPanel schrumpft dabei automatisch, sodass die
-- vorhandene Positionierungslogik der Module unveraendert weiterlaeuft.
--------------------------------------------------

local FRAME_W, FRAME_H = 1500, 800
local FRAME_MIN_W, FRAME_MIN_H = 1180, 780
local FRAME_MAX_W, FRAME_MAX_H = 1700, 1000

local TITLEBAR_H = 40
local NAV_W      = 232
local DETAIL_W   = 372   -- Entwurf: Inhaltsraster "1fr 372px" auf 2c/2d
local DETAIL_GAP = 16

WeintCodex.Metrics = {
    TITLEBAR_H = TITLEBAR_H,
    NAV_W      = NAV_W,
    DETAIL_W   = DETAIL_W,
    DETAIL_GAP = DETAIL_GAP,
    PAD_X      = 32,   -- Innenabstand des Inhaltsbereichs, Entwurf: 24px 32px
    PAD_Y      = 24,
    GAP        = 16,
    CARD_R     = 14,
    ROW_H      = 30,
}

local frame = CreateFrame("Frame", "WeintCodexMainFrame", UIParent)
frame:SetSize(FRAME_W, FRAME_H)
frame:SetPoint("CENTER")
-- Ebene und ESC-Verhalten kommen aus den SavedData und werden von
-- ApplyWindowBehaviour() gesetzt (siehe unten). Der Anfangswert hier ist nur
-- der, mit dem das Fenster bis zum ADDON_LOADED dasteht.
frame:SetFrameStrata("HIGH")
frame:SetToplevel(true)
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop",  frame.StopMovingOrSizing)
frame:SetResizable(true)
if frame.SetResizeBounds then
    frame:SetResizeBounds(FRAME_MIN_W, FRAME_MIN_H, FRAME_MAX_W, FRAME_MAX_H)
end
frame:Hide()

local frameBg = frame:CreateTexture(nil, "BACKGROUND")
frameBg:SetAllPoints(frame)
frameBg:SetColorTexture(unpack(C.bgDark))
-- Das Fenster selbst bekommt bewusst KEINE runden Ecken. CutCorners deckt die
-- Ecke mit der Farbe des Untergrunds ab - hinter dem Hauptfenster liegt aber
-- die Spielwelt, deren Farbe wir nicht kennen. Der Entwurf zeigt hier einen
-- Radius, den WoW ohne echte Transparenz im Frame nicht liefern kann.

local function ApplySavedWindow()
    if WeintCodex.SavedData and WeintCodex.SavedData.window then
        local w = WeintCodex.SavedData.window
        if w.width  then frame:SetWidth(w.width)   end
        if w.height then frame:SetHeight(w.height)  end
        if w.scale  then frame:SetScale(w.scale)    end
    end
end

--------------------------------------------------
-- Fensterverhalten: ESC und Ebene
--------------------------------------------------
-- Bis 2.5.0.0 lag das Hauptfenster fest auf FULLSCREEN_DIALOG und stand damit
-- ueber allem, was der Client sonst oeffnet - Taschen, Charakterbogen,
-- Handelsfenster, sogar ueber Blizzards eigenen Bestaetigungsdialogen. Und es
-- reagierte auf ESC nicht, weil dafuer der GLOBALE Name des Frames in
-- UISpecialFrames stehen muss; er existiert ("WeintCodexMainFrame"), war dort
-- aber nie eingetragen. Beides zusammen ergab ein Fenster, das man nur ueber
-- sein eigenes Kreuz wieder loswird und das solange jede andere Oberflaeche
-- verdeckt.
--
-- Beides ist jetzt einstellbar und steht in SavedData.window:
--   escClose - ESC schliesst das Fenster (Vorgabe an)
--   topmost  - Fenster ueber allen anderen halten (Vorgabe aus)
--
-- Die Vorgabeebene ist HIGH: darueber liegen die Dialoge des Clients (DIALOG,
-- FULLSCREEN_DIALOG), darunter die Weltfenster. Das Suchergebnis-Feld bleibt
-- auf DIALOG und damit ueber dem eigenen Fenster - das ist auch der Grund,
-- warum es hier nicht mitgezogen wird.
--
-- UISpecialFrames traegt Namen, keine Frames: der Eintrag muss deshalb per
-- Zeichenkette gesucht und entfernt werden, und er darf nur EINMAL drinstehen
-- (CloseSpecialWindows laeuft die Liste sonst zweimal ueber denselben Frame).
--------------------------------------------------

local ESC_FRAME_NAME = "WeintCodexMainFrame"

local function SetEscapeClose(enabled)
    local list = _G.UISpecialFrames
    if type(list) ~= "table" then return end

    for i = #list, 1, -1 do
        if list[i] == ESC_FRAME_NAME then table.remove(list, i) end
    end
    if enabled then
        table.insert(list, ESC_FRAME_NAME)
    end
end

-- Vorgabewerte an einer Stelle, damit Einstellungsseite und Fenster
-- dieselbe Antwort geben, solange noch nichts gespeichert wurde.
function WeintCodex.WindowBehaviour()
    local w = (WeintCodex.SavedData and WeintCodex.SavedData.window) or {}
    local esc = w.escClose
    if esc == nil then esc = true end
    return (esc and true or false), (w.topmost and true or false)
end

function WeintCodex.ApplyWindowBehaviour()
    local esc, topmost = WeintCodex.WindowBehaviour()
    frame:SetFrameStrata(topmost and "FULLSCREEN_DIALOG" or "HIGH")
    SetEscapeClose(esc)
end

-- Vorgabegroesse zurueckholen. Die Zahlen stehen nur hier, damit ein
-- geaenderter Entwurf sie nicht an zwei Stellen braucht.
function WeintCodex.ResetWindowSize()
    local w = WeintCodex.SavedData and WeintCodex.SavedData.window
    if not w then return end
    w.width, w.height, w.scale = FRAME_W, FRAME_H, 1.0
    ApplySavedWindow()
end

WeintCodex.WindowLimits = {
    minW = FRAME_MIN_W, maxW = FRAME_MAX_W,
    minH = FRAME_MIN_H, maxH = FRAME_MAX_H,
    defW = FRAME_W,     defH = FRAME_H,
}

--------------------------------------------------
-- Titelleiste
--------------------------------------------------

local titleBar = CreateFrame("Frame", nil, frame)
titleBar:SetHeight(TITLEBAR_H)
titleBar:SetPoint("TOPLEFT",  frame, "TOPLEFT",  0, 0)
titleBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)

local tbBg = titleBar:CreateTexture(nil, "BACKGROUND")
tbBg:SetAllPoints(titleBar)
ApplyVerticalGradient(tbBg, "bgMid", "bgPanel")  -- 101014 -> 08080A (Companion: SURFACE_EXTRA.titleBar)

local tbLine = titleBar:CreateTexture(nil, "ARTWORK")
tbLine:SetHeight(1)
tbLine:SetPoint("BOTTOMLEFT",  titleBar, "BOTTOMLEFT",  0, 0)
tbLine:SetPoint("BOTTOMRIGHT", titleBar, "BOTTOMRIGHT", 0, 0)
tbLine:SetColorTexture(unpack(C.border))

-- Markenzeichen: einziger Ort, an dem der Lila-Verlauf der Companion bleibt.
local brand = CreateFrame("Frame", nil, titleBar)
brand:SetSize(26, 26)
brand:SetPoint("LEFT", titleBar, "LEFT", 12, 0)
local brandTex = brand:CreateTexture(nil, "ARTWORK")
brandTex:SetAllPoints(brand)
ApplyVerticalGradient(brandTex, "brandA", "brandB")
WeintCodex.CutCorners(brand, 8, "bgPanel")
local brandLbl = brand:CreateFontString(nil, "OVERLAY")
brandLbl:SetFont(F.monoBold, 12, "")
brandLbl:SetPoint("CENTER", brand, "CENTER", 0, 0)
brandLbl:SetTextColor(1, 1, 1, 1)
brandLbl:SetText("W")

local wordmark = titleBar:CreateFontString(nil, "OVERLAY")
wordmark:SetFont(F.sansSemi, 13, "")
wordmark:SetPoint("LEFT", brand, "RIGHT", 12, 0)
wordmark:SetTextColor(unpack(C.textNormal))
wordmark:SetText("WeintCodex")

local wordDiv = titleBar:CreateTexture(nil, "ARTWORK")
wordDiv:SetSize(1, 14)
wordDiv:SetPoint("LEFT", wordmark, "RIGHT", 12, 0)
wordDiv:SetColorTexture(unpack(C.borderStrong))

local breadcrumb = titleBar:CreateFontString(nil, "OVERLAY")
breadcrumb:SetFont(F.mono, 10, "")
breadcrumb:SetPoint("LEFT", wordDiv, "RIGHT", 12, 0)
breadcrumb:SetJustifyH("LEFT")
breadcrumb:SetTextColor(unpack(C.textFaint))
WeintCodex.Breadcrumb = breadcrumb

function WeintCodex.SetBreadcrumb(...)
    local parts = { ... }
    local segs = {}
    for i, p in ipairs(parts) do
        segs[#segs + 1] = Spaced(Upper(tostring(p)))
        if i < #parts then segs[#segs + 1] = " \194\183 " end
    end
    breadcrumb:SetText(table.concat(segs))
end

-- Schliessen
local closeBtn = CreateFrame("Button", nil, titleBar)
closeBtn:SetSize(28, 24)
closeBtn:SetPoint("RIGHT", titleBar, "RIGHT", -8, 0)
local closeX = closeBtn:CreateFontString(nil, "OVERLAY")
closeX:SetFont(F.sans, 14, "")
closeX:SetPoint("CENTER", closeBtn, "CENTER", 0, 0)
closeX:SetTextColor(unpack(C.textMuted))
closeX:SetText("\195\151")
closeBtn:SetScript("OnClick", function() frame:Hide() end)
closeBtn:SetScript("OnEnter", function() closeX:SetTextColor(unpack(C.textBright)) end)
closeBtn:SetScript("OnLeave", function() closeX:SetTextColor(unpack(C.textMuted)) end)

local versionLbl = titleBar:CreateFontString(nil, "OVERLAY")
versionLbl:SetFont(F.mono, 10, "")
versionLbl:SetPoint("RIGHT", closeBtn, "LEFT", -8, 0)
versionLbl:SetTextColor(unpack(C.textFaint))
versionLbl:SetText(Spaced("V" .. (WeintCodex.Version or "5.0.0.0")))
WeintCodex.VersionLabel = versionLbl

-- Aktionsbereich je Modul, links neben der Versionsmarke.
local titleActions = CreateFrame("Frame", nil, titleBar)
titleActions:SetHeight(TITLEBAR_H)
titleActions:SetPoint("RIGHT", versionLbl, "LEFT", -12, 0)
titleActions:SetWidth(1)
WeintCodex.TitleBarActions = titleActions

--------------------------------------------------
-- Suche
--------------------------------------------------
-- Logik/Datenindex/Strg+K sitzen in core/search.lua; hier nur das Feld.

local searchBox = CreateFrame("EditBox", nil, titleBar)
searchBox:SetSize(260, 26)
searchBox:SetPoint("CENTER", titleBar, "CENTER", 0, 0)
searchBox:SetAutoFocus(false)
searchBox:SetFontObject("ChatFontNormal")
searchBox:SetFont(F.sans, 12, "")
searchBox:SetTextColor(unpack(C.textNormal))
searchBox:SetTextInsets(28, 52, 0, 0)
searchBox:SetMaxLetters(80)

SetSolidBg(searchBox, C.bgPanel[1], C.bgPanel[2], C.bgPanel[3], 1.0)
DrawBorder(searchBox, C.borderStrong[1], C.borderStrong[2], C.borderStrong[3], 1.0, 1)
WeintCodex.CutCorners(searchBox, 8, "bgPanel")

local searchIcon = searchBox:CreateFontString(nil, "OVERLAY")
searchIcon:SetFont(F.sans, 12, "")
searchIcon:SetPoint("LEFT", searchBox, "LEFT", 10, 0)
searchIcon:SetText(WeintCodex.Icon("Interface\\Common\\UI-Searchbox-Icon", 12))

local searchPlaceholder = searchBox:CreateFontString(nil, "OVERLAY")
searchPlaceholder:SetFont(F.sans, 12, "")
searchPlaceholder:SetPoint("LEFT", searchBox, "LEFT", 28, 0)
searchPlaceholder:SetPoint("RIGHT", searchBox, "RIGHT", -52, 0)
searchPlaceholder:SetJustifyH("LEFT")
searchPlaceholder:SetTextColor(unpack(C.textDim))
searchPlaceholder:SetText("Suchen")

local searchChip = searchBox:CreateFontString(nil, "OVERLAY")
searchChip:SetFont(F.mono, 9, "")
searchChip:SetPoint("RIGHT", searchBox, "RIGHT", -10, 0)
searchChip:SetTextColor(unpack(C.textFaint))
searchChip:SetText(Spaced("STRG K"))

searchBox:SetScript("OnEscapePressed", searchBox.ClearFocus)
searchBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
searchBox:SetScript("OnTextChanged", function(self)
    searchPlaceholder:SetShown(self:GetText() == "")
    if WeintCodex.Search then WeintCodex.Search.OnTextChanged(self:GetText()) end
end)
searchBox:SetScript("OnEditFocusGained", function(self)
    searchChip:Hide()
    if WeintCodex.Search then WeintCodex.Search.OnFocusGained(self:GetText()) end
end)
searchBox:SetScript("OnEditFocusLost", function(self)
    searchChip:Show()
    if WeintCodex.Search then WeintCodex.Search.OnFocusLost() end
end)
WeintCodex.SearchBox = searchBox

local searchResults = CreateFrame("Frame", nil, frame)
searchResults:SetPoint("TOPLEFT",  searchBox, "BOTTOMLEFT",  0, -6)
searchResults:SetPoint("TOPRIGHT", searchBox, "BOTTOMRIGHT", 0, -6)
searchResults:SetFrameStrata("DIALOG")
SetSolidBg(searchResults, C.surface2[1], C.surface2[2], C.surface2[3], 1.0)
DrawBorder(searchResults, C.borderStrong[1], C.borderStrong[2], C.borderStrong[3], 1.0, 1)
searchResults:Hide()
WeintCodex.SearchResults = searchResults

--------------------------------------------------
-- Navigationsspalte
--------------------------------------------------
-- Befuellt wird sie von core/navigation.lua; hier entsteht nur die Flaeche.

local navColumn = CreateFrame("Frame", nil, frame)
navColumn:SetWidth(NAV_W)
navColumn:SetPoint("TOPLEFT",    titleBar, "BOTTOMLEFT", 0, 0)
navColumn:SetPoint("BOTTOMLEFT", frame,    "BOTTOMLEFT", 0, 0)
SetSolidBg(navColumn, C.bgPanel[1], C.bgPanel[2], C.bgPanel[3], 1.0)

local navDiv = navColumn:CreateTexture(nil, "OVERLAY")
navDiv:SetPoint("TOPRIGHT",    navColumn, "TOPRIGHT",    0, 0)
navDiv:SetPoint("BOTTOMRIGHT", navColumn, "BOTTOMRIGHT", 0, 0)
navDiv:SetWidth(1)
navDiv:SetColorTexture(unpack(C.border))

WeintCodex.NavColumn = navColumn
-- Altname: core/access.lua und core/search.lua sprechen die Leiste noch so an.
WeintCodex.IconRail = navColumn

--------------------------------------------------
-- Inhalt und Detailbereich
--------------------------------------------------

local contentHost = CreateFrame("Frame", nil, frame)
contentHost:SetPoint("TOPLEFT",     navColumn, "TOPRIGHT",    0, 0)
contentHost:SetPoint("BOTTOMRIGHT", frame,     "BOTTOMRIGHT", 0, 0)

local contentPanel = CreateFrame("Frame", nil, contentHost)
contentPanel:SetPoint("TOPLEFT", contentHost, "TOPLEFT", 0, 0)
contentPanel:SetPoint("BOTTOMRIGHT", contentHost, "BOTTOMRIGHT", 0, 0)

local inspector = CreateFrame("Frame", nil, contentHost)
inspector:SetWidth(DETAIL_W)
inspector:SetPoint("TOPRIGHT",    contentHost, "TOPRIGHT",    -WeintCodex.Metrics.PAD_X, -WeintCodex.Metrics.PAD_Y)
inspector:SetPoint("BOTTOMRIGHT", contentHost, "BOTTOMRIGHT", -WeintCodex.Metrics.PAD_X,  WeintCodex.Metrics.PAD_Y)
inspector:Hide()

--------------------------------------------------
-- Innenabstaende des Inhaltsbereichs
--------------------------------------------------
-- Drei Dinge koennen den Inhalt beschneiden: der Detailbereich rechts, eine
-- Unternavigation links (lange Listen wie die Bosse) und die Reiterleiste
-- oben. Alle drei laufen ueber EINEN Rechenweg, weil sie sich sonst
-- gegenseitig die Verankerung ueberschreiben - ClearAllPoints/SetPoint je
-- Aufrufer waere genau der Fehler, den man erst bei zwei gleichzeitig sieht.
--
-- Der Sinn dahinter: die Module rechnen unveraendert gegen ContentPanel. Sie
-- merken vom Umbau nichts, ihre Flaeche wird nur kleiner.

local detailShown, subNavW, subNavTop = false, 0, 0

local function UpdateContentInsets()
    contentPanel:ClearAllPoints()
    contentPanel:SetPoint("TOPLEFT", contentHost, "TOPLEFT", subNavW, -subNavTop)
    contentPanel:SetPoint("BOTTOMRIGHT", contentHost, "BOTTOMRIGHT",
        detailShown and -(DETAIL_W + DETAIL_GAP + WeintCodex.Metrics.PAD_X) or 0, 0)
end

function WeintCodex.SetDetailShown(shown)
    detailShown = shown and true or false
    if detailShown then inspector:Show() else inspector:Hide() end
    UpdateContentInsets()
end

-- Breite einer Unternavigationsspalte links im Inhalt (0 = keine).
function WeintCodex.SetSubNavWidth(w)
    subNavW = w or 0
    UpdateContentInsets()
end

-- Hoehe der Reiterleiste ueber dem Inhalt (0 = keine).
function WeintCodex.SetSubNavTop(h)
    subNavTop = h or 0
    UpdateContentInsets()
end

UpdateContentInsets()

WeintCodex.ContentHost  = contentHost
WeintCodex.ContentPanel = contentPanel
WeintCodex.Inspector    = inspector

--------------------------------------------------
-- Groessengriff
--------------------------------------------------

local resizeBtn = CreateFrame("Button", nil, frame)
resizeBtn:SetSize(16, 16)
resizeBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -3, 3)
resizeBtn:SetFrameLevel(frame:GetFrameLevel() + 10)

local gripMarks = {}
local function MakeGripLine(offsetX, offsetY, w, h)
    local t = resizeBtn:CreateTexture(nil, "OVERLAY")
    t:SetSize(w, h)
    t:SetPoint("BOTTOMRIGHT", resizeBtn, "BOTTOMRIGHT", offsetX, offsetY)
    t:SetColorTexture(C.textFaint[1], C.textFaint[2], C.textFaint[3], 0.80)
    gripMarks[#gripMarks + 1] = t
end
MakeGripLine(0, 0, 9, 1)  MakeGripLine(0, 4, 6, 1)  MakeGripLine(0, 8, 3, 1)
MakeGripLine(0, 0, 1, 9)  MakeGripLine(4, 0, 1, 6)  MakeGripLine(8, 0, 1, 3)

local function TintGrip(col, alpha)
    for _, t in ipairs(gripMarks) do
        t:SetColorTexture(col[1], col[2], col[3], alpha)
    end
end
resizeBtn:SetScript("OnEnter", function() TintGrip(C.accent, 0.90) end)
resizeBtn:SetScript("OnLeave", function() TintGrip(C.textFaint, 0.80) end)
resizeBtn:SetScript("OnMouseDown", function() frame:StartSizing("BOTTOMRIGHT") end)
resizeBtn:SetScript("OnMouseUp", function()
    frame:StopMovingOrSizing()
    if WeintCodex.SavedData and WeintCodex.SavedData.window then
        WeintCodex.SavedData.window.width  = math.floor(frame:GetWidth())
        WeintCodex.SavedData.window.height = math.floor(frame:GetHeight())
    end
end)

frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

--------------------------------------------------
-- Globale Referenzen
--------------------------------------------------

WeintCodex.MainFrame        = frame
WeintCodex.TitleBar         = titleBar
WeintCodex.ApplySavedWindow = ApplySavedWindow

-- Die frueheren Chrome-Spalten gibt es nicht mehr. Sidebar bleibt als leerer,
-- versteckter Frame bestehen, damit vereinzelte Alt-Zugriffe nicht auf nil
-- laufen - Unternavigation ist jetzt die Reiterleiste in der Seite.
local legacySidebar = CreateFrame("Frame", nil, frame)
legacySidebar:SetSize(1, 1)
legacySidebar:Hide()
WeintCodex.Sidebar = legacySidebar
WeintCodex.SidebarHeader = legacySidebar:CreateFontString(nil, "OVERLAY")

--------------------------------------------------
-- Universeller Export-Dialog (Overlay)
--------------------------------------------------

local exportFrame = nil
function WeintCodex.ShowExportDialog(titleText, exportStr)
    if not exportFrame then
        local parent = WeintCodex.MainFrame
        local f = WeintCodex.CreateSurface(parent, {
            width = 620, height = 280, tone = "plain", radius = 14, backdrop = "bgDark",
        })
        f:SetPoint("CENTER", parent, "CENTER", 0, 0)
        f:SetFrameStrata("TOOLTIP")
        f:EnableMouse(true)

        local eyebrow = WeintCodex.Eyebrow(f, "Export")
        eyebrow:SetPoint("TOPLEFT", f, "TOPLEFT", 24, -20)

        local t = f:CreateFontString(nil, "OVERLAY")
        t:SetFont(F.display, 22, "")
        t:SetPoint("TOPLEFT", eyebrow, "BOTTOMLEFT", 0, -6)
        t:SetTextColor(unpack(C.textBright))
        f._title = t

        local sub = WeintCodex.Label(f, "Kopiere diesen String (Strg+C) und füge ihn bei deinem Discord-Bot ein:",
            { color = "textMuted", size = 13 })
        sub:SetPoint("TOPLEFT", t, "BOTTOMLEFT", 0, -8)
        sub:SetWidth(560)

        local ebBg = WeintCodex.CreateSurface(f, {
            width = 572, height = 110, tone = "flat", surface = "surface1",
            radius = 10, backdrop = "cardTop",
        })
        ebBg:SetPoint("TOPLEFT", sub, "BOTTOMLEFT", 0, -12)

        local eb = CreateFrame("EditBox", nil, ebBg)
        eb:SetSize(552, 100)
        eb:SetPoint("TOPLEFT", ebBg, "TOPLEFT", 10, -6)
        eb:SetMultiLine(true)
        eb:SetMaxLetters(0)
        eb:SetAutoFocus(false)
        eb:SetFont(F.mono, 11, "")
        eb:SetTextColor(unpack(C.textNormal))
        eb:SetTextInsets(4, 4, 4, 4)

        local scroll = CreateFrame("ScrollFrame", nil, ebBg, "UIPanelScrollFrameTemplate")
        scroll:SetSize(552, 100)
        scroll:SetPoint("TOPLEFT", ebBg, "TOPLEFT", 0, 0)
        scroll:SetScrollChild(eb)

        eb:SetScript("OnEscapePressed", function() f:Hide() end)
        eb:SetScript("OnChar", function(self)
            C_Timer.After(0.01, function()
                self:SetText(f._exportStr or "")
                self:HighlightText()
            end)
        end)
        f.EditBox = eb

        local close = WeintCodex.CreateButton(f, {
            text = "Schließen", kind = "primary", width = 140,
            backdrop = "cardBottom",
            onClick = function() f:Hide() end,
        })
        close:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -24, 20)

        exportFrame = f
    end

    exportFrame._title:SetText(titleText or "Export")
    exportFrame._exportStr = exportStr
    exportFrame.EditBox:SetText(exportStr)
    exportFrame:Show()

    C_Timer.After(0.1, function()
        exportFrame.EditBox:SetFocus()
        exportFrame.EditBox:HighlightText()
    end)
end
