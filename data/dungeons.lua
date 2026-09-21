--------------------------------------------------
-- WeintCodex :: Dungeons von Forever
--
-- DIESE TABELLE TRÄGT SEIT 5.2.0.0 BOSSLISTEN - ABER NICHT NEUN.
--
-- Blizzard hat die neun Dungeons auf der BlizzCon mit Namen, Ort und
-- Stufenbereich vorgestellt. Das sind belegte Angaben. Was auf
-- derselben Ankündigung nicht stand, waren die Bosslisten, und daran
-- hat sich bis heute (20.09.2026) wenig geändert: veröffentlicht hat
-- Blizzard bis jetzt keine einzige.
--
-- WAS SICH GEÄNDERT HAT, IST NICHT DIE QUELLENLAGE, SONDERN DER
-- UMGANG DAMIT. Seit dem Beta-Start am 17.09.2026 spielen Leute die
-- ersten beiden Dungeons und berichten, was darin steht. Das ist eine
-- benennbare Herkunft - die schwächste, die dieses Repository
-- zulässt, aber eine. Sie heisst `community` (siehe
-- data/sources.lua), und alles, was daran hängt, wird auf jeder
-- Oberfläche als unbestätigt ausgewiesen.
--
-- NIEMAND IN DIESEM PROJEKT HAT DEN FOREVER-CLIENT GELESEN. Was hier
-- als „aus dem Beta-Client" berichtet wird, ist ein Bericht ÜBER den
-- Client, kein Blick hinein. Deshalb trägt keine einzige Zeile dieser
-- Datei `kind = "beta"` - das wäre eine Prüfung, die nie
-- stattgefunden hat.
--
-- ZUM BUILD 1.60.1.69913, NACH DEM GEFRAGT WURDE: er ist vom
-- 18.09.2026, das erste Client-Update nach dem Beta-Start, und hat
-- nach allem, was berichtet wird, an Talenten, Zaubern und
-- Gegenständen NICHTS geändert - Starter, Absturzmeldung, ein paar
-- Grafikdateien. Für die Bosslisten hat er nichts gebracht. Wer
-- hierher kommt, weil eine neue Buildnummer draussen ist, findet
-- deshalb dasselbe vor wie bei 1.60.1.69876.
--
-- DREI ZUSTÄNDE STATT ZWEI, und sie sind der ganze Punkt:
--
--   `bosses` gefüllt, `bossesComplete = true`
--       Die Liste ist so vollständig, wie die Quelle sie hergibt.
--   `bosses` gefüllt, `bossesComplete = false`
--       Es sind Bosse bekannt, aber nicht alle. Die Oberfläche sagt
--       „unvollständig" - sonst läse sich eine Zweierliste wie ein
--       Dungeon mit zwei Bossen.
--   `bosses` leer, `bossCount` gesetzt
--       Die ANZAHL der Kämpfe ist berichtet, die Namen nicht. Das ist
--       kein Rückstand, sondern eine Auskunft: „neun Kämpfe, Namen
--       unbekannt" ist mehr als „nichts bekannt" und weniger als eine
--       Liste.
--
-- `order` STEHT NUR DA, WO DIE REIHENFOLGE BEKANNT IST. In der Hall
-- of Thanes stimmen mehrere Berichte über die Pullreihenfolge
-- überein; in den Ruins of Lordaeron liegen sieben Namen vor und
-- keine Reihenfolge. Eine durchnummerierte Liste wäre dort eine
-- Behauptung - `orderKnown = false`, und die Seite schreibt keine
-- Pullnummer hin.
--
-- DEUTSCHE NAMEN: keine. Forever hat keine deutsche Lokalisierung
-- veröffentlicht. Ein selbst übersetzter Boss- oder Dungeonname
-- stünde später anders im Client, und die Zuordnung der Bossnotizen
-- des Bots (über den Namen, siehe modules/sync.lua) liefe daneben.
--
-- `journalId` bleibt nil: welche Encounter-Journal-Kennungen Forever
-- vergibt, ist unbekannt, und eine geratene Kennung liest sich im
-- Code wie eine belegte.
--------------------------------------------------

local SRC = WeintCodex.Sources

--------------------------------------------------
-- BESCHWÖREN GEHT IN FOREVER NUR AUF EINE ART
--------------------------------------------------
-- Danach war ausdrücklich gefragt, und die Antwort ist zweigeteilt.
--
-- SPIELER beschwören: nur der Hexenmeister, mit zwei weiteren
-- Gruppenmitgliedern vor Ort. Forever hat KEINE Rufsteine
-- (Meeting Stones) freigeschaltet und keinen automatischen
-- Gruppenfinder - man läuft zum Eingang, wie in Vanilla.
--
-- BOSSE beschwören: das gibt es, und es ist etwas ganz anderes -
-- optionale Gegner, die nur erscheinen, wenn die Gruppe etwas dafür
-- tut. In Forever ist einer davon berichtet (Viktor the Vile), aus
-- Classic kommen drei weitere mit (siehe data/dungeons_classic.lua).
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.DungeonData = {}

WeintCodex.DungeonData.SUMMONING = {
    players = "Forever hat keine Rufsteine freigeschaltet und keinen "
           .. "automatischen Gruppenfinder. Spieler beschwört nur der "
           .. "Hexenmeister, mit zwei Helfern vor Ort - zum Eingang läuft "
           .. "man selbst.",
    source  = SRC.COMMUNITY,
}

WeintCodex_Dungeons = {

    {
        id       = "hall_of_thanes",
        name     = "Hall of Thanes",
        zone     = "Ironforge",
        zoneDe   = "Eisenschmiede",
        size     = 5,
        minLevel = 13,
        maxLevel = 18,
        release  = "Erscheinungsinhalt",
        journalId = nil,

        -- Grabmal der früheren Könige von Eisenschmiede, nur für die
        -- Allianz - das Gegenstück zum Ragefire Chasm der Horde.
        theme    = "Grabmal der Könige von Eisenschmiede. Allianzseite; das "
                .. "Gegenstück zum Ragefire Chasm der Horde.",
        mapArt   = true,

        -- Der am besten belegte Dungeon von allen neun: seit dem
        -- Beta-Start spielbar, und die Berichte über die vier Kämpfe
        -- und ihre Reihenfolge decken sich.
        bossSource     = SRC.COMMUNITY,
        bossesComplete = true,
        orderKnown     = true,
        bossCount      = 4,

        bosses = {
            {
                id    = "faldrim_anvilmar",
                name  = "Faldrim Anvilmar",
                order = 1,
                position = "Patrouilliert durch den großen Mittelsaal, "
                        .. "erreichbar über den Westflügel gleich hinter dem "
                        .. "Eingang.",
            },
            {
                id      = "magmatus",
                name    = "Magmatus",
                order   = 2,
                -- DER NAMENSKONFLIKT, DER IN DIESEM REPOSITORY SEIT
                -- ZWEI FASSUNGEN ALS BEISPIEL HERHÄLT. Dasselbe
                -- Encounter wird mal als „Magmatus", mal als
                -- „Infurnus" berichtet. Beide Namen stehen hier, weil
                -- die Zuordnung der Bossnotizen über den Namen läuft:
                -- schickt der Bot Notizen unter dem anderen Namen,
                -- sollen sie ankommen.
                nameAlt = "Infurnus",
                position = "Feuerkammer im Ostflügel.",
            },
            {
                id    = "plunder",
                name  = "Plunder",
                order = 3,
                position = "Weg vom umliegenden Gesindel pullen - der Kampf "
                        .. "wandert.",
            },
            {
                id    = "durgen_dirgehammer",
                name  = "Durgen Dirgehammer",
                order = 4,
                position = "Endkammer, zusammen mit zwei Steingolems.",
            },
        },
    },

    {
        id       = "ruins_of_lordaeron",
        name     = "Ruins of Lordaeron",
        zone     = "Tirisfal Glades",
        zoneDe   = "Tirisfal-Wälder",
        size     = 5,
        minLevel = 15,
        maxLevel = 20,
        release  = "Erscheinungsinhalt",
        journalId = nil,

        theme    = "Die gefallene Hauptstadt, zurückerobert an der Seite der "
                .. "Verlassenen.",
        mapArt   = true,

        -- SIEBEN NAMEN, KEINE REIHENFOLGE. Aus den Beta-Berichten
        -- lassen sich sieben Encounter benennen; wie sie aufeinander
        -- folgen, sagt keiner davon vollständig. Eine
        -- durchnummerierte Liste wäre hier erfunden - `orderKnown`
        -- ist deshalb false, und die Seite schreibt keine Pullnummer
        -- hin. Ob es genau sieben sind, ist ebenfalls offen: eine
        -- Darstellung zählt sechs.
        bossSource     = SRC.COMMUNITY,
        bossesComplete = false,
        orderKnown     = false,
        bossCount      = nil,

        bosses = {
            {
                id   = "witherfang",
                name = "Witherfang",
                position = "Patrouilliert den ersten langen Gang hinter dem "
                        .. "Eingang, auf einer sehr weiten Route - die Patrouille "
                        .. "abwarten, sonst läuft sie in den Kampf.",
            },
            {
                id   = "the_abandoned",
                name = "The Abandoned",
            },
            {
                id   = "the_butcher",
                name = "The Butcher",
                position = "Am Ende des ersten Gangs, in der ersten Biegung.",
            },
            {
                id   = "lordaeron_captain",
                name = "Lordaeron Captain",
            },
            {
                id   = "bjork",
                name = "Bjork",
            },
            {
                id   = "rathmael",
                name = "Rath'mael",
                position = "Innerer Sanktumsbereich, am Altar. Letzter Kampf "
                        .. "des Dungeons, Stufe 20.",
                last = true,
            },
            {
                -- DER BESCHWÖRBARE ZUSATZBOSS. Genau danach war
                -- gefragt, und er ist der einzige in den neun
                -- Forever-Dungeons, über den etwas berichtet wird.
                id       = "viktor_the_vile",
                name     = "Viktor the Vile",
                optional = true,
                position = "Hinter dem Eisentor an der südwestlichen "
                        .. "Kanalisation - ohne Beschwörung steht dort niemand.",
                summon = {
                    text = "Erst Rath'mael legen. Danach das unbeleuchtete "
                        .. "Kohlenbecken hinter seinem Altar benutzen: das gibt "
                        .. "drei Minuten lang eine Flamme. Mit der Flamme zum "
                        .. "Gitter im Südwesten laufen und dort das Grabbecken "
                        .. "anzünden. Viktor erscheint mit zwei Begleitern.",
                    source = SRC.COMMUNITY,
                },
            },
        },
    },

    {
        id       = "excavation_site",
        name     = "Excavation Site",
        zone     = "Wetlands",
        zoneDe   = "Sumpfland",
        size     = 5,
        minLevel = 24,
        maxLevel = 29,
        release  = "Erscheinungsinhalt",
        journalId = nil,

        theme    = "Grabung der Forscherliga oberhalb von Whelgars Ausgrabung; "
                .. "Titanenkonstrukte bewachen den Fund.",
        mapArt   = true,

        -- HIER STEHT ABSICHTLICH NICHTS, OBWOHL VIER NAMEN KURSIEREN.
        -- Eine Darstellung nennt vier Bosse und schreibt sie dem
        -- Beta-Client zu; eine andere sagt ausdrücklich, für diesen
        -- Dungeon sei keine Liste bekannt. Zwei Quellen, die einander
        -- widersprechen, ergeben keine Liste - sie ergeben einen
        -- offenen Punkt, und der steht hier als solcher.
        bossSource     = nil,
        bossesComplete = nil,
        orderKnown     = nil,
        bossCount      = nil,
        conflict = "Vier Bossnamen kursieren (Saltspine, Shadetooth, Highland "
                .. "Horror, Relic Guardian), eine andere Darstellung sagt "
                .. "ausdrücklich, für diesen Dungeon sei keine Liste bekannt. "
                .. "WeintCodex trägt sie nicht ein, solange sich das "
                .. "widerspricht.",
        bosses = {},
    },

    {
        id       = "city_of_dalaran",
        name     = "City of Dalaran",
        zone     = "Alterac Mountains",
        zoneDe   = "Alteracgebirge",
        size     = 5,
        minLevel = 28,
        maxLevel = 33,
        release  = "Erscheinungsinhalt",
        journalId = nil,

        theme    = "Dalaran ist zurück im Alteracgebirge, und die Magie darin "
                .. "ist außer Kontrolle. Der längste der neun - und der "
                .. "einzige mit Händlern.",
        mapArt   = true,

        -- DER FALL, FÜR DEN `bossCount` OHNE `bosses` ERFUNDEN WURDE.
        -- Berichtet wird übereinstimmend: neun Kämpfe. Von den neun
        -- Namen sind fünf zu bekommen, die Reihenfolge von keinem.
        -- Fünf Namen als Liste einzutragen hiesse, einen Dungeon mit
        -- neun Kämpfen als Dungeon mit fünf zu führen - die Anzahl zu
        -- nennen und die Namen als das auszuweisen, was sie sind, ist
        -- die ehrlichere Auskunft.
        bossSource     = nil,
        bossesComplete = nil,
        orderKnown     = nil,
        bossCount      = 9,
        countSource    = SRC.COMMUNITY,
        partial = {
            names  = { "Arcane Anomaly", "Unstable Sentinel",
                       "Shade of the Archmage", "Atrexis the Grave Knight",
                       "Lyn the Ignored" },
            source = SRC.COMMUNITY,
        },
        bosses = {},
    },

    {
        id       = "drowned_city",
        name     = "The Drowned City",
        zone     = "Stranglethorn Vale",
        zoneDe   = "Schlingendorntal",
        size     = 5,
        minLevel = 35,
        maxLevel = 40,
        release  = "Erscheinungsinhalt",
        journalId = nil,

        theme    = "Versunkene Trollstadt vor der Küste des Schlingendorntals, "
                .. "wieder aufgetaucht.",
        mapArt   = false,

        -- ZWEI BOSSE VON UNBEKANNT VIELEN, und sie sind die einzigen
        -- auf dieser Seite, die Blizzard selbst gezeigt hat: die
        -- Drowned City war auf der BlizzCon 2026 spielbar. Das ist
        -- eine festere Quelle als ein Beta-Bericht - aber es sind
        -- eben zwei Kämpfe aus einer Messeversion und nicht die
        -- Liste. `bossesComplete = false` ist hier keine Formalie:
        -- ohne sie läse sich das wie ein Dungeon mit zwei Bossen.
        bossSource     = SRC.BLIZZCON,
        bossesComplete = false,
        orderKnown     = false,
        bossCount      = nil,

        bosses = {
            {
                id   = "zulalai",
                name = "Zul'Alai",
                position = "Auf der BlizzCon-Fassung der erste der beiden "
                        .. "gezeigten Kämpfe.",
            },
            {
                id   = "zinaka",
                name = "Zin'aka",
                position = "Höherstufig als Zul'Alai, also später im Dungeon.",
            },
        },
    },

    {
        -- Neues Gebiet, deshalb kein deutscher Gebietsname.
        id       = "kroldok_stronghold",
        name     = "Krol'dok Stronghold",
        zone     = "Riverglades",
        zoneDe   = nil,
        size     = 5,
        minLevel = 40,
        maxLevel = 45,
        release  = "Erscheinungsinhalt",
        journalId = nil,

        -- Kein Gewölbe im Berg, sondern eine Festung unter freiem
        -- Himmel, in Abschnitten mit unterschiedlichen Gegnerstufen.
        theme    = "Ogerfestung unter freiem Himmel, die Reisende verschleppt. "
                .. "Mehrere Wege, Abschnitte mit unterschiedlichen "
                .. "Gegnerstufen.",
        mapArt   = false,

        -- Keine Encounterdaten, keine Karte. Der Stufenbereich ist
        -- ausserdem der eine, bei dem Blizzard nachkorrigiert hat:
        -- 40-55 stand in der Präsentation, 40-45 ist der korrigierte
        -- Wert - und ältere Darstellungen tragen bis heute 40-55.
        bossSource = nil,
        bosses     = {},
    },

    {
        id       = "alcaz_island_prison",
        name     = "Alcaz Island Prison",
        zone     = "Dustwallow Marsh",
        zoneDe   = "Düstermarschen",
        size     = 5,
        minLevel = 48,
        maxLevel = 53,
        release  = "Erscheinungsinhalt",
        journalId = nil,

        theme    = "Das bisher verschlossene Gefängnis auf der Alcaz-Insel. "
                .. "Defias und Naga kämpfen darin gegeneinander.",
        mapArt   = false,

        bossSource = nil,
        bosses     = {},
    },

    {
        id       = "blackmaw_hold",
        name     = "Blackmaw Hold",
        zone     = "Azshara",
        zoneDe   = "Azshara",
        size     = 5,
        minLevel = 55,
        maxLevel = 60,
        release  = "Erscheinungsinhalt",
        journalId = nil,

        theme    = "Furbolgstadt hinter dem Tor im Norden Azsharas, von "
                .. "Verderbnis bedroht. Ihre Tunnel führen weiter zu den "
                .. "Barrow Deeps.",
        mapArt   = false,

        -- FÜR DIESEN DUNGEON KURSIERT EINE BOSSLISTE, DIE NACHWEISLICH
        -- FALSCH IST: eine Darstellung führt hier „Zul'Alai" und
        -- „Zin'aka" auf - das sind die beiden Bosse, die Blizzard in
        -- der Drowned City gezeigt hat. Sie steht hier als Warnung:
        -- eine Liste, die sich einem anderen Dungeon zuordnen lässt,
        -- ist kein schwacher Beleg, sondern gar keiner.
        conflict = "Eine kursierende Liste nennt für Blackmaw Hold „Zul'Alai“ "
                .. "und „Zin'aka“ - das sind die beiden Bosse der Drowned "
                .. "City, die Blizzard auf der BlizzCon gezeigt hat. Für "
                .. "Blackmaw Hold ist nichts bekannt.",

        bossSource = nil,
        bosses     = {},
    },

    {
        id       = "shapers_terrace",
        name     = "Shaper's Terrace",
        zone     = "Un'Goro Crater",
        zoneDe   = "Krater von Un'Goro",
        size     = 5,
        minLevel = 58,
        maxLevel = 60,
        release  = "Erscheinungsinhalt",
        journalId = nil,

        theme    = "Titanenanlage im Krater von Un'Goro: alte Maschinen, "
                .. "Kraftkristalle, entglittene Fauna.",
        mapArt   = false,

        -- Titanenthema heisst NICHT Uldaman-Bosse. Forever erzählt
        -- seine eigene Geschichte, und ein Boss, den man aus einem
        -- anderen Spiel erwartet, ist kein Beleg.
        bossSource = nil,
        bosses     = {},
    },

}

--------------------------------------------------
-- Zugriff
--------------------------------------------------
-- Absichtlich Funktionen statt direkter Tabellenzugriffe: sie sind
-- die eine Stelle, an der „leer", „unvollständig" und „vollständig"
-- auseinandergehalten werden. Wer `#dungeon.bosses` selbst zählt,
-- bekommt 2 für die Drowned City und weiss nicht, dass das die zwei
-- von einer Messe sind.
--------------------------------------------------

local D = WeintCodex.DungeonData

function D.All()
    return WeintCodex_Dungeons
end

function D.Get(dungeonId)
    for _, dungeon in ipairs(WeintCodex_Dungeons) do
        if dungeon.id == dungeonId then return dungeon end
    end
    return nil
end

-- Kennt das Addon Bosse dieses Dungeons? `false` heisst „nichts
-- bekannt" und darf nirgends als „hat keine Bosse" gelesen werden.
function D.HasBosses(dungeon)
    return type(dungeon) == "table"
        and type(dungeon.bosses) == "table"
        and #dungeon.bosses > 0
end

-- Ist die Liste so vollständig, wie die Quelle sie hergibt? `nil`
-- ohne Liste - „unvollständig" wäre über etwas, das gar nicht da
-- ist, eine merkwürdige Aussage.
function D.BossesComplete(dungeon)
    if not D.HasBosses(dungeon) then return nil end
    return dungeon.bossesComplete == true
end

-- Steht die Pullreihenfolge fest? Im Zweifel nein.
function D.OrderKnown(dungeon)
    if not D.HasBosses(dungeon) then return nil end
    return dungeon.orderKnown == true
end

function D.BossSource(dungeon)
    if not D.HasBosses(dungeon) then return nil end
    return dungeon.bossSource
end

function D.BossesConfirmed(dungeon)
    return WeintCodex.Sources.IsConfirmed(D.BossSource(dungeon))
end

function D.BossSourceLabel(dungeon)
    return WeintCodex.Sources.Label(D.BossSource(dungeon))
end

-- WIE VIELE KÄMPFE ES GIBT, und das ist etwas anderes als wie viele
-- benannt sind. Für die City of Dalaran sind neun berichtet und
-- keiner eingetragen; `KnownBossCount` zählt Einträge, `BossCount`
-- die Kämpfe. Beide dürfen nil sein.
function D.BossCount(dungeon)
    if type(dungeon) ~= "table" then return nil end
    if type(dungeon.bossCount) == "number" and dungeon.bossCount > 0 then
        return dungeon.bossCount
    end
    if D.HasBosses(dungeon) and D.BossesComplete(dungeon) then
        return #dungeon.bosses
    end
    return nil
end

-- Wie viele Bosse insgesamt NAMENTLICH bekannt sind. `nil` (nicht 0),
-- solange kein einziger Dungeon eine Liste hat.
function D.KnownBossCount()
    local total = 0
    for _, dungeon in ipairs(WeintCodex_Dungeons) do
        total = total + #(dungeon.bosses or {})
    end
    if total == 0 then return nil end
    return total
end

-- Bosse, die nur durch Zutun der Gruppe erscheinen. Eine eigene
-- Abfrage, weil sie auf der Seite auch einen eigenen Platz haben:
-- wer wissen will, was sich beschwören lässt, soll es nicht aus der
-- Liste heraussuchen müssen.
function D.SummonableBosses(dungeon)
    local found = {}
    for _, boss in ipairs((type(dungeon) == "table" and dungeon.bosses) or {}) do
        if type(boss.summon) == "table" then found[#found + 1] = boss end
    end
    return found
end

-- „13 – 18" oder nil. Ein halber Bereich ist kein Bereich.
function D.LevelRange(dungeon)
    if type(dungeon) ~= "table" then return nil end
    if type(dungeon.minLevel) ~= "number" or type(dungeon.maxLevel) ~= "number" then
        return nil
    end
    return dungeon.minLevel .. " – " .. dungeon.maxLevel
end

-- Der Gebietsname, den die Oberfläche anzeigt: deutsch, wo es einen
-- etablierten deutschen gibt, sonst der englische. Nie beide.
function D.ZoneLabel(dungeon)
    if type(dungeon) ~= "table" then return nil end
    return dungeon.zoneDe or dungeon.zone
end

-- Passt die eigene Stufe zu diesem Dungeon? `nil`, wenn der Client
-- keine Stufe liefert - „passt nicht" wäre dann eine Behauptung.
function D.FitsLevel(dungeon, level)
    if type(level) ~= "number" or level <= 0 then return nil end
    if type(dungeon) ~= "table" then return nil end
    if type(dungeon.minLevel) ~= "number" or type(dungeon.maxLevel) ~= "number" then
        return nil
    end
    return level >= dungeon.minLevel and level <= dungeon.maxLevel
end
