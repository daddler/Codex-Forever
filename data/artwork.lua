--------------------------------------------------
-- WeintCodex :: Artwork
--
-- EIN BILD IST HIER KEINE AUSKUNFT.
--
-- Diese Datei ist die einzige Stelle, an der das Addon einen
-- Bildpfad kennt, und sie steht unter denselben zwei Regeln wie
-- jede andere Bestandsdatei - nur beantworten sie hier etwas
-- anderes.
--
--   KEIN PFAD OHNE DATEI. Ein Texturpfad, hinter dem nichts liegt,
--   zeichnet im Spiel ein gruenes Rechteck, und ein gruenes Rechteck
--   sieht aus wie ein Bild. Was hier steht, liegt in media/ -
--   .github/tests/data_test.lua prueft jede Zeile dieser Tabelle
--   gegen den Ordner. Deshalb steht hier kein Pfad in den
--   Spielclient: welche Texturen Forever vergibt, weiss niemand in
--   diesem Projekt, und geraten wird nicht.
--
--   KEIN BILD, DAS ETWAS BEHAUPTET. Was in media/dungeons liegt,
--   ist eigenes Material und KEINE Abbildung des Spiels: so sieht
--   der Boss im Client nicht aus, so sieht die Instanz im Client
--   nicht aus, und keine Zeile dieser Tabelle sagt etwas darueber.
--   Ein Bild ist hier Atmosphaere und nichts sonst. Alles, was die
--   Seite BEHAUPTET - wie viele Bosse, in welcher Reihenfolge, wo
--   einer steht -, steht weiter in data/dungeons.lua und traegt dort
--   seine Herkunft (data/sources.lua). Ein bebilderter Dungeon ist
--   deshalb kein besser belegter: die Hall of Thanes bleibt
--   `community`, mit Bild wie ohne.
--
-- WARUM DAS NICHT IM WIDERSPRUCH ZU "KEINE BILDER" STEHT. Bis
-- 5.2.0.6 stand in modules/dungeonpages.lua, dass dieses Addon keine
-- Bilder liefern kann, und die zwei Gruende dort gelten unveraendert:
-- Blizzards Kartenmaterial ist nicht veroeffentlicht, und es gehoert
-- uns nicht. Beides betrifft BLIZZARDS Material. Eigenes Material
-- faellt unter keinen der beiden Gruende - es behauptet nur nichts,
-- und genau deshalb steht hier, dass es nichts behauptet.
--
-- WIE EIN EINTRAG AUSSIEHT:
--
--   file    Pfad unterhalb von media/, ohne Endung (WoW sucht sich
--           .blp/.tga selbst). Schraegstriche; core/ui.lua macht
--           daraus Backslashes.
--   w, h    Die Masse der Datei. Sie stehen hier und werden nicht
--           gemessen: der Prueflauf hat keinen Client, der eine
--           Textur vermessen koennte, und der Ausschnitt muss in
--           Spiel und Lauf derselbe sein (WeintCodex.CoverCoords).
--   focusX  Wo das Motiv liegt, 0..1. Wird nur gebraucht, wenn der
--   focusY  Kasten SCHMALER ist als das Bild - dann entscheidet der
--           Fokus, welcher Teil stehen bleibt. Fehlt er, ist es die
--           Mitte.
--
-- WIE DIE DATEIEN GEMACHT SIND (damit sie sich nachbauen lassen):
-- aus den Originalen 1983x793 bzw. 1672x941, mit einem von Hand
-- gesetzten 4:1-Ausschnitt (das Motiv RECHTS der Mitte, weil links
-- Nummer und Name stehen), auf 1024x256 skaliert und als BLP2/DXT1
-- mit Mipmaps abgelegt - 175 KB je Bild statt 2,3 MB. Der Ausschnitt
-- steht je Datei darunter.
--
-- HALL OF THANES UND RAGEFIRE CHASM SIND DIE ERSTEN BEIDEN BEBILDERTEN
-- DUNGEON. Das ist kein Zwischenstand, der aufzufuellen waere:
-- Material gibt es fuer diese beiden, und fuer die anderen
-- siebenundzwanzig gibt es keines. Eine Seite ohne Eintrag sieht aus
-- wie vor 5.2.0.7 (siehe WeintCodex.Artwork, Punkt 1) - es braucht
-- dafuer keine Zeile hier und keine Fallunterscheidung dort.
--------------------------------------------------

WeintCodex = WeintCodex or {}

local ART = "dungeons/"

WeintCodex.Artworks = {

    hall_of_thanes = {

        -- Der Thronsaal, Blick zum Sitz der Thane. Schnitt aus
        -- header.png (1983x793): x 0, y 69, 1983x496.
        --
        -- Der Fokus liegt RECHTS und nicht in der Mitte: wird die
        -- Kopfkarte schmal, soll der Thron stehen bleiben und nicht
        -- der Treppenaufgang - und die linke Haelfte ist die dunkle,
        -- auf der Kennzeichnung, Name und Themensatz stehen.
        header = {
            file = ART .. "hall_of_thanes/header",
            w = 1024, h = 256, focusX = 0.58,
        },

        bosses = {
            -- Schnitt aus faldrim_anvilmar.png (1672x941):
            -- x 0, y 8, 1300x325.
            faldrim_anvilmar = {
                file = ART .. "hall_of_thanes/faldrim_anvilmar",
                w = 1024, h = 256, focusX = 0.58,
            },
            -- Schnitt aus magmatus.png: x 0, y 110, 1300x325.
            magmatus = {
                file = ART .. "hall_of_thanes/magmatus",
                w = 1024, h = 256, focusX = 0.56,
            },
            -- Schnitt aus plunder.png: x 100, y 40, 1300x325.
            plunder = {
                file = ART .. "hall_of_thanes/plunder",
                w = 1024, h = 256, focusX = 0.66,
            },
            -- Schnitt aus durgen_dirgehammer.png: x 100, y 25, 1400x350.
            durgen_dirgehammer = {
                file = ART .. "hall_of_thanes/durgen_dirgehammer",
                w = 1024, h = 256, focusX = 0.60,
            },
        },
    },

    ragefire_chasm = {
        header = {
            file = ART .. "ragefire_chasm/header",
            w = 1024, h = 256, focusX = 0.58,
        },
        bosses = {
            oggleflint = {
                file = ART .. "ragefire_chasm/oggleflint",
                w = 1024, h = 256, focusX = 0.60,
            },
            taragaman = {
                file = ART .. "ragefire_chasm/taragaman",
                w = 1024, h = 256, focusX = 0.62,
            },
            jergosh = {
                file = ART .. "ragefire_chasm/jergosh",
                w = 1024, h = 256, focusX = 0.60,
            },
            bazzalan = {
                file = ART .. "ragefire_chasm/bazzalan",
                w = 1024, h = 256, focusX = 0.58,
            },
        },
    },
}

--------------------------------------------------
-- Zugriff
--------------------------------------------------
-- Zwei Funktionen, und beide geben nil zurueck, wo es nichts gibt.
-- Das ist der ganze Rueckfall: eine Seite fragt, bekommt nil und
-- zeichnet sich wie immer.

WeintCodex.Art = {}

function WeintCodex.Art.Dungeon(dungeonId)
    if not dungeonId then return nil end
    local entry = WeintCodex.Artworks[dungeonId]
    return entry and entry.header or nil
end

function WeintCodex.Art.Boss(dungeonId, bossId)
    if not dungeonId or not bossId then return nil end
    local entry = WeintCodex.Artworks[dungeonId]
    if not entry or not entry.bosses then return nil end
    return entry.bosses[bossId]
end
