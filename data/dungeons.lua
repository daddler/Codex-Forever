--------------------------------------------------
-- WeintCodex :: Dungeons von Forever
--
-- DIESE TABELLE IST GEFÜLLT, UND ZWAR AUS DEM GEGENTEIL DES GRUNDES,
-- AUS DEM data/raids.lua LANGE LEER WAR.
--
-- Blizzard hat die neun Dungeons auf der BlizzCon mit Namen, Ort und
-- Stufenbereich vorgestellt. Das sind belegte Angaben, keine
-- Vermutungen - sie dürfen deshalb hier stehen. Was auf derselben
-- Ankündigung NICHT stand, steht hier auch nicht:
--
--   * DIE BOSSLISTEN. Für fünf der neun Dungeons liegen Bossnamen im
--     Beta-Client, aber unvollständig, untereinander widersprüchlich
--     (dasselbe Encounter einmal als "Magmatus", einmal als
--     "Infurnus") und für vier Dungeons überhaupt nicht. Eine Liste,
--     die vier Dungeons stillschweigend als bosslos führt, wäre
--     schlechter als gar keine. `bosses` bleibt deshalb durchgehend
--     leer - dieselbe Regel wie in data/raids.lua.
--   * DEUTSCHE NAMEN. Forever hat noch keine deutsche Lokalisierung
--     veröffentlicht. "Ruins of Lordaeron" hier als "Ruinen von
--     Lordaeron" zu führen hiesse, einen Namen zu erfinden, den der
--     Client später anders schreibt - und die Zuordnung über den
--     Namen (modules/encounter_tracking.lua) liefe daneben. Die
--     Dungeonnamen bleiben englisch, so wie sie angekündigt wurden.
--   * `journalId`. Welche Encounter-Journal-Kennungen Forever
--     vergibt, ist unbekannt. Eine geratene Kennung liest sich im
--     Code wie eine belegte.
--
-- ZU DEN GEBIETSNAMEN: `zone` ist der englische Name aus der
-- Ankündigung, `zoneDe` der etablierte deutsche Name des Gebiets -
-- "Eisenschmiede", "Sumpfland", "Schlingendorntal" heissen seit
-- zwanzig Jahren so, das ist keine Vermutung. Riverglades ist ein
-- NEUES Gebiet und trägt deshalb `zoneDe = nil`: für ein Gebiet, das
-- es bisher nicht gab, gibt es auch keinen etablierten deutschen
-- Namen. Die Oberfläche zeigt dann den englischen.
--
-- ZUM STUFENBEREICH: `minLevel`/`maxLevel` sind die angekündigten
-- Bereiche. Krol'dok Stronghold stand zunächst mit 40-55 in der
-- Präsentation; Blizzard hat das auf 40-45 korrigiert, und das ist
-- der Wert hier.
--
-- Stand: 19.09.2026, Beta-Client 1.60.1.69876.
--------------------------------------------------

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
        bosses   = {},
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
        bosses   = {},
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
        bosses   = {},
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
        bosses   = {},
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
        bosses   = {},
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
        bosses   = {},
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
        bosses   = {},
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
        bosses   = {},
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
        bosses   = {},
    },

}

--------------------------------------------------
-- Zugriff
--------------------------------------------------
-- Dieselben Funktionen wie bei den Schlachtzügen, und aus demselben
-- Grund: sie sind die eine Stelle, an der "leer" von "unbekannt"
-- unterschieden wird.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.DungeonData = {}

function WeintCodex.DungeonData.All()
    return WeintCodex_Dungeons
end

function WeintCodex.DungeonData.Get(dungeonId)
    for _, dungeon in ipairs(WeintCodex_Dungeons) do
        if dungeon.id == dungeonId then return dungeon end
    end
    return nil
end

-- Kennt das Addon die Bosse dieses Dungeons? `false` heisst "noch
-- nicht veröffentlicht" und darf nirgends als "hat keine Bosse"
-- gelesen werden.
function WeintCodex.DungeonData.HasBosses(dungeon)
    return type(dungeon) == "table"
        and type(dungeon.bosses) == "table"
        and #dungeon.bosses > 0
end

-- Wie viele Dungeonbosse insgesamt bekannt sind. `nil` (nicht 0),
-- solange kein einziger Dungeon eine Liste hat.
function WeintCodex.DungeonData.KnownBossCount()
    local total = 0
    for _, dungeon in ipairs(WeintCodex_Dungeons) do
        total = total + #(dungeon.bosses or {})
    end
    if total == 0 then return nil end
    return total
end

-- "13 – 18" oder nil. Ein halber Bereich ist kein Bereich: fehlt eine
-- der beiden Stufen, ist die ehrliche Antwort keine Angabe und nicht
-- die eine Zahl, die da ist.
function WeintCodex.DungeonData.LevelRange(dungeon)
    if type(dungeon) ~= "table" then return nil end
    if type(dungeon.minLevel) ~= "number" or type(dungeon.maxLevel) ~= "number" then
        return nil
    end
    return dungeon.minLevel .. " – " .. dungeon.maxLevel
end

-- Der Gebietsname, den die Oberfläche anzeigt: deutsch, wo es einen
-- etablierten deutschen gibt, sonst der englische. Nie beide.
function WeintCodex.DungeonData.ZoneLabel(dungeon)
    if type(dungeon) ~= "table" then return nil end
    return dungeon.zoneDe or dungeon.zone
end

-- Passt die eigene Stufe zu diesem Dungeon? `nil`, wenn der Client
-- keine Stufe liefert - "passt nicht" waere dann eine Behauptung.
function WeintCodex.DungeonData.FitsLevel(dungeon, level)
    if type(level) ~= "number" or level <= 0 then return nil end
    if type(dungeon) ~= "table" then return nil end
    if type(dungeon.minLevel) ~= "number" or type(dungeon.maxLevel) ~= "number" then
        return nil
    end
    return level >= dungeon.minLevel and level <= dungeon.maxLevel
end
