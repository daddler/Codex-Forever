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
-- rechts der Mittelachse; zwischen beiden der eigene Zauberbalken und
-- darueber die Kombopunkte (seit 6.6.1.3 - darunter brauchen drei
-- Aktionsleisten und die Reihe fuer Haltungen und Begleiter den Platz).
-- Der Zauberbalken ist so breit wie die Luecke zwischen beiden
-- (K.LAYOUT_METRICS.castWidth; 6.6.1.3 hatte 240 und lag auf beiden
-- Rahmen). Die Gruppe steht links neben dem Spielerrahmen, die
-- Schadensanzeige oben links (Beta-Test 6.6.1.4: "erstmal nach oben
-- links wieder").
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
    castWidth = 2 * AXIS - 12,   -- 6 Einheiten Luft zu Spieler und Ziel
}

K.LAYOUT = {
    -- Cockpit
    uf_player       = { point = "BOTTOMRIGHT", relPoint = "BOTTOM", x = -AXIS, y = COCKPIT_Y },
    uf_target       = { point = "BOTTOMLEFT",  relPoint = "BOTTOM", x = AXIS,  y = COCKPIT_Y },
    uf_targettarget = { point = "TOPLEFT",     relPoint = "BOTTOM", x = AXIS + UF_W + 6, y = COCKPIT_Y + UF_H },
    -- Fokus links ueber dem Begleiter (seit 6.6.1.6): ueber dem Spieler
    -- stehen seine Buffs, Spiegelbild zu den Auren ueber dem Ziel.
    uf_focus        = { point = "BOTTOMRIGHT", relPoint = "BOTTOM", x = -(AXIS + UF_W + 6), y = COCKPIT_Y + UF_H + 6 },
    -- Begleiter links neben dem Spieler, Spiegelbild zum Ziel des Ziels
    -- (bis 6.6.1.2 darunter - dort steht jetzt die Begleiterleiste).
    uf_pet          = { point = "TOPRIGHT",    relPoint = "BOTTOM", x = -(AXIS + UF_W + 6), y = COCKPIT_Y + UF_H },
    uf_combo        = { point = "BOTTOM",      relPoint = "BOTTOM", x = 0, y = COCKPIT_Y + 25 },
    uf_playercast   = { point = "BOTTOM",      relPoint = "BOTTOM", x = 0, y = COCKPIT_Y + 3 },

    -- Gruppe links neben dem Spielerrahmen; der Schlachtzug braucht die
    -- Breite und steht oben links.
    gf_party        = { point = "TOPRIGHT",    relPoint = "BOTTOM", x = -(AXIS + UF_W + 18), y = 440 },
    gf_raid         = { point = "TOPLEFT",     relPoint = "TOPLEFT", x = 20, y = -260 },

    -- Rand
    -- Erinnerungen (ui/reminders.lua): die Hinweise oben, die Symbole
    -- ueber dem Cockpit - Procs zuoberst, darunter die Abklingzeiten.
    reminders       = { point = "TOP",         relPoint = "TOP", x = 0, y = -130 },
    procs           = { point = "BOTTOM",      relPoint = "BOTTOM", x = 0, y = 268 },
    cooldowns       = { point = "BOTTOM",      relPoint = "BOTTOM", x = 0, y = 228 },
    xpbar           = { point = "BOTTOM",      relPoint = "BOTTOM", x = 0, y = 4 },
    damagemeter     = { point = "TOPLEFT",     relPoint = "TOPLEFT", x = 12, y = -36 },
    bags            = { point = "BOTTOMRIGHT", relPoint = "BOTTOMRIGHT", x = -20, y = 110 },
    questarrow      = { point = "TOP",         relPoint = "TOP", x = 0, y = -8 },
    combatalert     = { point = "CENTER",      relPoint = "CENTER", x = 0, y = 220 },
    fps             = { point = "TOPLEFT",     relPoint = "TOPLEFT", x = 12, y = -12 },
    durability      = { point = "TOP",         relPoint = "TOP", x = 0, y = -90 },
}

--------------------------------------------------
-- Die Rahmen des Spiels
--------------------------------------------------
-- Seit 6.6.1.3 stellt die Einrichtung (ui/setup.lua) JEDEN Rahmen des
-- Spiels, den WeintCodex nicht ersetzt, selbst - Beta-Test: "Chatfenster
-- bleibt so, wie das vorherige UI es eingestellt hatte. WeintCodex soll
-- erstmal ALLES komplett einstellen." Grundlage ist die Vorlage des
-- Spiels; was hier nicht steht (Sprechkopf, Beute, Haltbarkeit, die
-- ersetzten Einheitenrahmen), bleibt auf deren Platz.
--
-- UNTEN MITTE, von unten nach oben (Hoehen in Einheiten, Knopfgroessen
-- aus ui/actionbars.lua, je 4 Einheiten Kachel ringsum):
--   4-14 Erfahrung · 18-58 Leiste 1 (40) · 66-102 Leiste 2 (36)
--   110-146 Leiste 3 (36) · 154-184 Haltungen links, Begleiter rechts
--   189-220 Spieler und Ziel, dazwischen Zauberbalken und Kombopunkte
-- RECHTS: Minikarte oben, darunter buendig die Questliste; am Rand
-- senkrecht Leiste 4 und 5 (liegen unter einer langen Questliste, wenn
-- beide an sind); unten die Taschenleiste.
-- LINKS: Chat unten (Infozeile darunter, Mikromenue ganz unten), Gruppe
-- darueber links neben dem Spieler, oben die Schadensanzeige.
-- Alle Masse sind gerechnet, nicht im Spiel gesehen - wer etwas
-- ueberlappen sieht, meldet es, und es wird hier korrigiert.
--
-- sys/idx: Namen aus Enum.EditModeSystem und dem Enum der Indizes des
-- Systems; set: Einstellungen nach Namen aus dessen Setting-Enum (nur
-- Schalter und Werte, die das Spiel roh speichert); from: Platz aus
-- K.LAYOUT; frames: wie der Rahmen im Spiel heisst (fuer die Pruefung).
local BAR1_Y, BAR2_Y, BAR3_Y, ROW_Y = 18, 66, 110, 154
local EDGE = 4            -- Abstand zum Bildschirmrand unten/rechts
local SIDE_W = 34 + 4     -- eine senkrechte Leiste samt Luft
-- Minikarte und Questliste schliessen rechts buendig ab (Beta-Test
-- 6.6.1.4: "zu weit eingerueckt" - bis dahin stand die Liste links neben
-- Leiste 4 und 5). Die Karte haengt 6 Einheiten innerhalb ihres Bereichs
-- (ui/minimap.lua, MM.PlaceMap), die Flaeche der Questliste ragt 8 ueber
-- die Liste hinaus (ui/questtracker.lua, Standard "padding").
local MINIMAP_X = -12
local MAP_INSET, TRACK_PAD = 6, 8
local TRACK_X = MINIMAP_X - MAP_INSET - TRACK_PAD   -- Flaeche endet, wo die Karte endet
-- Unter der Minikarte haengt im Beta-Client der Knopf "Issue Reporter"
-- samt Kaefer - bei -262 lag er auf der Questliste (Beta-Test 6.6.1.3).
local TRACK_Y = -305
K.CHAT_SIZE = { w = 400, h = 160 }

K.GAME_LAYOUT = {
    { key = "bar1", label = "Aktionsleiste 1", sys = "ActionBar", idx = "MainBar",
      point = "BOTTOM", relPoint = "BOTTOM", x = 0, y = BAR1_Y,
      set = { HideBarArt = 1, HideBarScrolling = 1 }, frames = { "MainActionBar", "MainMenuBar" } },
    { key = "bar2", label = "Aktionsleiste 2", sys = "ActionBar", idx = "Bar2",
      point = "BOTTOM", relPoint = "BOTTOM", x = 0, y = BAR2_Y, frames = { "MultiBarBottomLeft" } },
    { key = "bar3", label = "Aktionsleiste 3", sys = "ActionBar", idx = "Bar3",
      point = "BOTTOM", relPoint = "BOTTOM", x = 0, y = BAR3_Y, frames = { "MultiBarBottomRight" } },
    { key = "bar4", label = "Aktionsleiste 4", sys = "ActionBar", idx = "RightBar1",
      point = "BOTTOMRIGHT", relPoint = "BOTTOMRIGHT", x = -EDGE, y = 60,
      set = { Orientation = 1 }, frames = { "MultiBarRight" } },
    { key = "bar5", label = "Aktionsleiste 5", sys = "ActionBar", idx = "RightBar2",
      point = "BOTTOMRIGHT", relPoint = "BOTTOMRIGHT", x = -(EDGE + SIDE_W), y = 60,
      set = { Orientation = 1 }, frames = { "MultiBarLeft" } },
    { key = "stance", label = "Haltungsleiste", sys = "ActionBar", idx = "StanceBar",
      point = "BOTTOMRIGHT", relPoint = "BOTTOM", x = -4, y = ROW_Y, frames = { "StanceBar" } },
    { key = "possess", label = "Besessenheitsleiste", sys = "ActionBar", idx = "PossessActionBar",
      point = "BOTTOMRIGHT", relPoint = "BOTTOM", x = -4, y = ROW_Y, frames = { "PossessActionBar" } },
    { key = "pet", label = "Begleiterleiste", sys = "ActionBar", idx = "PetActionBar",
      point = "BOTTOMLEFT", relPoint = "BOTTOM", x = 4, y = ROW_Y, frames = { "PetActionBar" } },
    { key = "vehicle", label = "Fahrzeug verlassen", sys = "VehicleLeaveButton",
      point = "BOTTOM", relPoint = "BOTTOM", x = 0, y = ROW_Y, frames = { "MainMenuBarVehicleLeaveButton" } },
    { key = "extra", label = "Zusatzfähigkeit", sys = "ExtraAbilities",
      point = "BOTTOMLEFT", relPoint = "BOTTOM", x = AXIS + UF_W + 10, y = COCKPIT_Y + UF_H + 10,
      frames = { "ExtraAbilityContainer" } },
    -- ABKLINGZEITMANAGER wie eine WeakAura unter dem Charakter (Beta-Test
    -- 6.6.1.4: "etwas kleiner, nicht doppelte Informationen, Ausdauer-
    -- Buffs, Debuffs brauchen nicht angezeigt werden - einzig die
    -- Faehigkeiten oder deren Laufzeiten"). Die Symbole von "Wichtig" und
    -- "Hilfreich" zeigen selbst, wie lange ihre Wirkung noch laeuft; die
    -- Buff-Anzeigen des Spiels zeigten dieselben Laufzeiten ein zweites
    -- Mal und dazu lange Buffs wie Ausdauer - sie sind aus (im
    -- Bearbeitungsmodus wieder einschaltbar). Beide Symbolreihen auf 80 %.
    -- personal: der PLATZ kommt aus dem bisherigen Layout, wenn es einen
    -- nennt (ui/setup.lua, ES.KeepPersonal); Groesse und Sichtbarkeit
    -- stellt WeintCodex.
    -- display: Werte, wie der Bearbeitungsmodus sie anzeigt (Prozent);
    -- ui/setup.lua rechnet sie in den gespeicherten Wert um.
    -- enum: { Name des Enums, Eintrag } fuer Auswahllisten.
    { key = "essential", label = "Abklingzeiten: Wichtig", sys = "CooldownViewer", idx = "Essential", personal = true,
      point = "BOTTOM", relPoint = "BOTTOM", x = 0, y = 316, frames = { "EssentialCooldownViewer" },
      display = { IconSize = 80 } },
    { key = "utility", label = "Abklingzeiten: Hilfreich", sys = "CooldownViewer", idx = "Utility", personal = true,
      point = "BOTTOM", relPoint = "BOTTOM", x = 0, y = 366, frames = { "UtilityCooldownViewer" },
      display = { IconSize = 80 } },
    { key = "bufficon", label = "Abklingzeiten: Buffs", sys = "CooldownViewer", idx = "BuffIcon", personal = true,
      point = "BOTTOM", relPoint = "BOTTOM", x = 0, y = 406, frames = { "BuffIconCooldownViewer" },
      enum = { VisibleSetting = { "CooldownViewerVisibleSetting", "Hidden" } } },
    { key = "buffbar", label = "Abklingzeiten: Buffleisten", sys = "CooldownViewer", idx = "BuffBar", personal = true,
      point = "BOTTOMRIGHT", relPoint = "BOTTOM", x = -(AXIS + UF_W + 10), y = 316, frames = { "BuffBarCooldownViewer" },
      enum = { VisibleSetting = { "CooldownViewerVisibleSetting", "Hidden" } } },
    { key = "encounter", label = "Begegnungsleiste", sys = "EncounterBar",
      point = "TOP", relPoint = "TOP", x = 0, y = -170, frames = { "EncounterBar" } },

    { key = "minimap", label = "Minikarte", sys = "Minimap",
      point = "TOPRIGHT", relPoint = "TOPRIGHT", x = MINIMAP_X, y = -12, frames = { "MinimapCluster" } },
    -- Buffs ueber dem Spielerrahmen (Beta-Test 6.6.1.5: "ich sehe an
    -- meinem Spielerfenster nicht, ob ich gebufft bin oder ein Schild
    -- habe"). Eigene Symbole kann WeintCodex nicht fuellen - im Kampf gibt
    -- der Client Addons keine Auren (siehe "Aurenleisten"). Die Buff-
    -- Anzeige des Spiels kann es, auch im Kampf; sie steht jetzt hier,
    -- rechts buendig mit dem Spieler, waechst nach links und nach oben.
    { key = "buffs", label = "Buffs", sys = "AuraFrame", idx = "BuffFrame",
      point = "BOTTOMRIGHT", relPoint = "BOTTOM", x = -AXIS, y = COCKPIT_Y + UF_H + 6, frames = { "BuffFrame" },
      enum = { IconWrap = { "AuraFrameIconWrap", "Up" }, IconDirection = { "AuraFrameIconDirection", "Left" } } },
    { key = "debuffs", label = "Debuffs", sys = "AuraFrame", idx = "DebuffFrame",
      point = "TOPRIGHT", relPoint = "TOPRIGHT", x = -270, y = -110, frames = { "DebuffFrame" } },
    { key = "tracker", label = "Questliste", sys = "ObjectiveTracker",
      point = "TOPRIGHT", relPoint = "TOPRIGHT", x = TRACK_X, y = TRACK_Y, frames = { "ObjectiveTrackerFrame" } },
    { key = "boss", label = "Bossrahmen", sys = "UnitFrame", idx = "Boss",
      point = "TOPRIGHT", relPoint = "TOPRIGHT", x = TRACK_X - 270, y = TRACK_Y, frames = { "BossTargetFrameContainer" } },
    { key = "arena", label = "Arenarahmen", sys = "UnitFrame", idx = "Arena",
      point = "TOPRIGHT", relPoint = "TOPRIGHT", x = TRACK_X - 270, y = TRACK_Y, frames = { "CompactArenaFrame", "ArenaEnemyFramesContainer" } },
    { key = "tooltip", label = "Tooltip", sys = "HudTooltip",
      point = "BOTTOMRIGHT", relPoint = "BOTTOMRIGHT", x = TRACK_X, y = 240, frames = { "GameTooltipDefaultContainer" } },
    { key = "bags", label = "Taschenleiste", sys = "Bags",
      point = "BOTTOMRIGHT", relPoint = "BOTTOMRIGHT", x = -EDGE, y = EDGE, frames = { "BagsBar" } },

    { key = "micro", label = "Mikromenü", sys = "MicroMenu",
      point = "BOTTOMLEFT", relPoint = "BOTTOMLEFT", x = EDGE, y = EDGE, frames = { "MicroMenuContainer", "MicroMenu" } },
    { key = "chat", label = "Chat", sys = "ChatFrame",
      point = "BOTTOMLEFT", relPoint = "BOTTOMLEFT", x = 14, y = 72, frames = { "ChatFrame1" },
      set = { WidthHundreds = math.floor(K.CHAT_SIZE.w / 100), WidthTensAndOnes = K.CHAT_SIZE.w % 100,
              HeightHundreds = math.floor(K.CHAT_SIZE.h / 100), HeightTensAndOnes = K.CHAT_SIZE.h % 100 } },
    -- Gruppe schlachtzugsartig (nur die zeigen HoTs), ohne Blizzards
    -- Linien - den Rand zeichnet WeintCodex (ui/gamegroup.lua).
    { key = "party", label = "Gruppe", sys = "UnitFrame", idx = "Party", from = "gf_party",
      set = { UseRaidStylePartyFrames = 1, DisplayBorder = 0 }, frames = { "CompactPartyFrame", "PartyFrame" } },
    { key = "raid", label = "Schlachtzug", sys = "UnitFrame", idx = "Raid", from = "gf_raid",
      set = { DisplayBorder = 0 }, frames = { "CompactRaidFrameContainer" } },
}

-- Eine frische Kopie: wer sie veraendert (weitere Fenster der
-- Schadensanzeige versetzt), veraendert nicht die Tabelle.
function K.Layout(key, dx, dy)
    local p = K.LAYOUT[key]
    assert(p, "UIKit.Layout: unbekannter Rahmen '" .. tostring(key) .. "'")
    return { point = p.point, relPoint = p.relPoint, x = p.x + (dx or 0), y = p.y + (dy or 0) }
end
