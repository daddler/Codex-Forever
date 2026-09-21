--------------------------------------------------
-- WeintCodex :: Schlachtzüge von Forever
--
-- DIESE TABELLE WAR ABSICHTLICH LEER. SIE IST ES NICHT MEHR, UND DAS
-- IST KEIN BRUCH DER REGEL, SONDERN IHR ERGEBNIS.
--
-- Die Regel lautete nie "hier darf nichts stehen", sondern: es darf
-- nichts dastehen, dessen Herkunft sich nicht benennen lässt. Genau
-- deshalb durften die Listen aus Mists of Pandaria nicht hierher -
-- sie hätten über Forever nichts ausgesagt.
--
-- Seit dem Beta-Start am 17.09.2026 liegen die Encounter-Listen für
-- zwei der drei Schlachtzüge im Client (Build 1.60.1.69876). Das ist
-- eine Forever-Quelle, benennbar und nachprüfbar - aber es ist NICHT
-- dasselbe wie eine veröffentlichte Liste. Datamining ändert sich von
-- Build zu Build, und Blizzard hat weder Namen noch Reihenfolge
-- bestätigt.
--
-- Das Addon führt diesen Unterschied deshalb im Bestand mit, statt
-- ihn zu verschweigen:
--
--   `bossSource = nil`   keine Liste. Die Oberfläche sagt "noch nicht
--                        bekannt" - wie bisher.
--   `bossSource.kind`    "beta"    aus dem Beta-Client, vorläufig.
--                        "release" von Blizzard bestätigt.
--
-- Eine vorläufige Liste wird überall als vorläufig ausgewiesen. Sie
-- zu zeigen und dabei so zu tun, als stünde sie fest, wäre genau der
-- Fehler, den die leere Tabelle vermeiden sollte.
--
-- WER EINE LISTE EINTRÄGT, TRÄGT IHRE HERKUNFT MIT EIN. Eine
-- Bossliste ohne `bossSource` lässt `.github/tests/data_test.lua`
-- durchfallen - eine unbelegte Liste ist der eine Zustand, den es
-- hier nie geben soll.
--
--   bosses = {
--       { id = "...", name = "...", order = 1 },
--       ...
--   }
--
--   `id`    stabiler Schlüssel (Fortschritt, Notizen hängen daran)
--   `name`  Anzeigename
--   `order` Pullreihenfolge
--
-- ZU DEN NAMEN: sie bleiben englisch. Forever hat keine deutsche
-- Lokalisierung veröffentlicht; ein selbst übersetzter Bossname
-- stünde später anders im Client als hier, und die Zuordnung der
-- Bossnotizen des Bots liefe daneben.
--
-- `journalId` bleibt weiterhin nil: welche Encounter-Journal-
-- Kennungen Forever vergibt, ist unbekannt, und eine geratene Kennung
-- liest sich im Code wie eine belegte.
--------------------------------------------------

-- DIE EINE HERKUNFTSANGABE, AUF DIE BEIDE LISTEN ZEIGEN.
-- Seit 5.2.0.0 steht sie nicht mehr hier, sondern in
-- data/sources.lua: die Dungeons brauchen dieselbe Angabe, und
-- zweimal dasselbe halb gepflegt ist der Zustand, den diese
-- Umstellung abschafft. Der Bezug bleibt derselbe Build - das
-- spaetere Client-Update 1.60.1.69913 hat an den Encounterdaten
-- nichts geaendert, und eine hochgezaehlte Buildnummer waere eine
-- Pruefung, die nie stattgefunden hat.
local BETA_CLIENT = WeintCodex.Sources.BETA_69876

WeintCodex_Raids = {

    {
        id       = "barrow_deeps",
        name     = "Barrow Deeps",
        size     = 10,
        release  = "Erscheinungsinhalt",
        opensAt  = "09.12.2026",
        journalId = nil,
        bossSource = BETA_CLIENT,
        bosses   = {
            { id = "deepscar_matriarch",   name = "Deepscar Matriarch",     order = 1 },
            { id = "khalith_dreadspinner", name = "Khalith the Dreadspinner", order = 2 },
            { id = "amethrax",             name = "Amethrax",               order = 3 },
            { id = "ravus_and_darlissa",   name = "Ravus and Darlissa",     order = 4 },
            { id = "elder_tangleclaw",     name = "Elder Tangleclaw",       order = 5 },
            { id = "well_of_sorrow",       name = "Well of Sorrow",         order = 6 },
            { id = "dellynar_songwood",    name = "Del'lynar Songwood",     order = 7 },
            { id = "sonya_darkhallow",     name = "Sonya Darkhallow",       order = 8 },
        },
    },

    {
        id       = "hyjal_summit",
        name     = "Hyjal Summit",
        size     = 20,
        release  = "Erscheinungsinhalt",
        opensAt  = "09.12.2026",
        journalId = nil,
        bossSource = BETA_CLIENT,
        bosses   = {
            { id = "bandalar",             name = "Bandalar",              order = 1 },
            { id = "time_lost_battalion",  name = "Time-Lost Battalion",   order = 2 },
            { id = "old_gloomlurker",      name = "Old Gloomlurker",       order = 3 },
            { id = "kathris_the_haunted",  name = "Kathris the Haunted",   order = 4 },
            { id = "elder_minderel",       name = "Elder Minderel",        order = 5 },
            { id = "council_of_thorns",    name = "Council of Thorns",     order = 6 },
            { id = "the_wild_king",        name = "The Wild King",         order = 7 },
            { id = "ancient_of_decay",     name = "Ancient of Decay",      order = 8 },
            { id = "sylvesteris_dusksong", name = "Sylvesteris Dusksong",  order = 9 },
            { id = "gharalis_the_abyssal", name = "Gharalis the Abyssal",  order = 10 },
            { id = "anara_chillwind",      name = "Anara Chillwind",       order = 11 },
            { id = "tracker_stillwind",    name = "Tracker Stillwind",     order = 12 },
            { id = "nythus_the_dreambound", name = "Nythus the Dreambound", order = 13 },
        },
    },

    {
        -- ONYXIAS HORT BLEIBT LEER, und das ist die Probe aufs Exempel.
        -- Dass Onyxia die einzige Bossin ihres Horts ist, weiss jeder
        -- aus zwanzig Jahren Azeroth - im Beta-Client steht für diese
        -- Instanz aber keine Encounter-Liste, und Blizzard hat zu
        -- Änderungen am Kampf nichts gesagt. "Weiss man doch" ist
        -- keine Quelle. Sobald der Client eine Liste führt, steht sie
        -- hier, mit ihrer Herkunft daneben.
        id       = "onyxias_hort",
        name     = "Onyxias Hort",
        size     = 40,
        release  = "Erscheinungsinhalt",
        opensAt  = "09.12.2026",
        journalId = nil,
        bossSource = nil,
        bosses   = {},
    },

}

--------------------------------------------------
-- Zugriff
--------------------------------------------------
-- Absichtlich Funktionen statt direkter Tabellenzugriffe: sie sind die
-- eine Stelle, an der "leer" von "unbekannt" - und inzwischen auch
-- "vorläufig" von "bestätigt" - unterschieden wird. Wer `#raid.bosses`
-- selbst zählt, bekommt 8 und weiss nicht, wie fest die 8 steht.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.RaidData = {}

function WeintCodex.RaidData.All()
    return WeintCodex_Raids
end

function WeintCodex.RaidData.Get(raidId)
    for _, raid in ipairs(WeintCodex_Raids) do
        if raid.id == raidId then return raid end
    end
    return nil
end

-- Kennt das Addon die Bosse dieses Schlachtzugs? `false` heisst "noch
-- nicht veröffentlicht" und darf nirgends als "hat keine Bosse"
-- gelesen werden.
function WeintCodex.RaidData.HasBosses(raid)
    return type(raid) == "table"
        and type(raid.bosses) == "table"
        and #raid.bosses > 0
end

-- Woher die Bossliste dieses Schlachtzugs stammt. `nil`, wenn es
-- keine gibt.
function WeintCodex.RaidData.BossSource(raid)
    if not WeintCodex.RaidData.HasBosses(raid) then return nil end
    return raid.bossSource
end

-- Steht die Liste fest? Alles ausser einer ausdrücklich als
-- "release" gekennzeichneten Quelle gilt als vorläufig - im Zweifel
-- also NICHT bestätigt. Das ist die Richtung, in die ein Irrtum
-- harmlos ist.
function WeintCodex.RaidData.BossesConfirmed(raid)
    local source = WeintCodex.RaidData.BossSource(raid)
    return source ~= nil and source.kind == "release"
end

-- Die Herkunft als Anzeigetext, oder nil. Die Oberfläche hängt ihn
-- an jede vorläufige Liste - eine vorläufige Liste ohne diesen
-- Zusatz wäre eine Behauptung.
-- Seit 5.2.0.0 rechnet WeintCodex.Sources den Text aus - dieselbe
-- Stelle, die auch die Dungeons benutzen. Vorher stand die Formel
-- hier und dort dieselbe Formel noch einmal.
function WeintCodex.RaidData.BossSourceLabel(raid)
    return WeintCodex.Sources.Label(WeintCodex.RaidData.BossSource(raid))
end

-- Wie viele Bosse insgesamt bekannt sind. `nil` (nicht 0), solange
-- kein einziger Schlachtzug eine Liste hat - sonst stünde im Tooltip
-- eine gemessene Null, wo nichts gemessen wurde.
function WeintCodex.RaidData.KnownBossCount()
    local total = 0
    for _, raid in ipairs(WeintCodex_Raids) do
        total = total + #(raid.bosses or {})
    end
    if total == 0 then return nil end
    return total
end

-- Der Zustand des gesamten Bestands, für Übersicht und Diagnose:
--
--   "none"        keine einzige Liste
--   "provisional" mindestens eine Liste, keine davon bestätigt
--   "partial"     bestätigte und vorläufige Listen nebeneinander
--   "confirmed"   jede vorhandene Liste ist bestätigt
--
-- Vier Zustände statt zwei, weil ein "Bosslisten hinterlegt" über
-- einem Bestand aus dem Beta-Client mehr verspricht, als der Bestand
-- hält.
function WeintCodex.RaidData.BossListState()
    local any, confirmed, provisional = false, 0, 0
    for _, raid in ipairs(WeintCodex_Raids) do
        if WeintCodex.RaidData.HasBosses(raid) then
            any = true
            if WeintCodex.RaidData.BossesConfirmed(raid) then
                confirmed = confirmed + 1
            else
                provisional = provisional + 1
            end
        end
    end
    if not any then return "none" end
    if provisional == 0 then return "confirmed" end
    if confirmed == 0 then return "provisional" end
    return "partial"
end
