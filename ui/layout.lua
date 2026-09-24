--------------------------------------------------
-- WeintCodex :: Oberflaeche - Wo alles steht
--------------------------------------------------
-- EINE Tabelle fuer die Standardpositionen aller beweglichen Rahmen
-- (docs/design/ui-2.0.md, Grundsatz 2). Bis 6.0.0.6 stand jede Position in
-- ihrem Modul, und keine wusste von der anderen - daher die Kanten, die
-- nicht fluchteten.
--
-- DAS COCKPIT. Was im Kampf zaehlt, liegt um die Bildschirmmitte:
-- Spieler- und Zielrahmen als Spiegelbild, je 100 Einheiten links und
-- rechts der Mittelachse; darunter mittig Kombopunkte und der eigene
-- Zauberbalken, darunter die Aktionsleisten des Spiels. Die Gruppe steht
-- links neben dem Spielerrahmen, die Schadensanzeige unten rechts.
--
-- EINHEITEN. Gerechnet ist fuer das Grundmass des Spiels: UIParent ist
-- 768 Einheiten hoch (Skalierung aus). Der Entwurf ist in 1080 px
-- gezeichnet; 1 Einheit = 1,406 px. Wer die Skalierung des Spiels
-- aendert, bekommt dieselbe Anordnung groesser oder kleiner - die
-- Abstaende zur Mitte bleiben im selben Verhaeltnis zu den Rahmen.
--
-- Gespeicherte Positionen (Rahmen entsperren, ziehen) gehen vor; diese
-- Tabelle ist nur, was ohne sie gilt.
--------------------------------------------------

WeintCodex = WeintCodex or {}
local K = WeintCodex.UIKit

-- Masse, die mehrere Eintraege teilen.
local AXIS   = 100   -- Abstand der Cockpit-Rahmen zur Mittelachse
local COCKPIT_Y = 189   -- Unterkante von Spieler und Ziel
local UF_W, UF_H = 200, 31   -- Spieler/Ziel: 24 Leben + 1 + 6 Kraft

K.LAYOUT_METRICS = {
    axis = AXIS, cockpitY = COCKPIT_Y, unitWidth = UF_W, unitHeight = UF_H,
}

K.LAYOUT = {
    -- Cockpit
    uf_player       = { point = "BOTTOMRIGHT", relPoint = "BOTTOM", x = -AXIS, y = COCKPIT_Y },
    uf_target       = { point = "BOTTOMLEFT",  relPoint = "BOTTOM", x = AXIS,  y = COCKPIT_Y },
    uf_targettarget = { point = "TOPLEFT",     relPoint = "BOTTOM", x = AXIS + UF_W + 6, y = COCKPIT_Y + UF_H },
    uf_focus        = { point = "BOTTOMRIGHT", relPoint = "BOTTOM", x = -AXIS, y = COCKPIT_Y + UF_H + 10 },
    uf_pet          = { point = "TOPRIGHT",    relPoint = "BOTTOM", x = -AXIS, y = COCKPIT_Y - 6 },
    uf_combo        = { point = "BOTTOM",      relPoint = "BOTTOM", x = 0, y = 165 },
    uf_playercast   = { point = "BOTTOM",      relPoint = "BOTTOM", x = 0, y = 138 },

    -- Gruppe links neben dem Spielerrahmen; der Schlachtzug braucht die
    -- Breite und steht oben links.
    gf_party        = { point = "TOPRIGHT",    relPoint = "BOTTOM", x = -(AXIS + UF_W + 18), y = 373 },
    gf_raid         = { point = "TOPLEFT",     relPoint = "TOPLEFT", x = 20, y = -260 },

    -- Rand
    damagemeter     = { point = "BOTTOMRIGHT", relPoint = "BOTTOMRIGHT", x = -12, y = 52 },
    bags            = { point = "BOTTOMRIGHT", relPoint = "BOTTOMRIGHT", x = -20, y = 110 },
    questarrow      = { point = "TOP",         relPoint = "TOP", x = 0, y = -8 },
    combatalert     = { point = "CENTER",      relPoint = "CENTER", x = 0, y = 220 },
    fps             = { point = "TOPLEFT",     relPoint = "TOPLEFT", x = 12, y = -12 },
    durability      = { point = "TOP",         relPoint = "TOP", x = 0, y = -90 },
}

-- Eine frische Kopie: wer sie veraendert (weitere Fenster der
-- Schadensanzeige versetzt), veraendert nicht die Tabelle.
function K.Layout(key, dx, dy)
    local p = K.LAYOUT[key]
    assert(p, "UIKit.Layout: unbekannter Rahmen '" .. tostring(key) .. "'")
    return { point = p.point, relPoint = p.relPoint, x = p.x + (dx or 0), y = p.y + (dy or 0) }
end
