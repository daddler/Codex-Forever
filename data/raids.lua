--------------------------------------------------
-- WeintCodex :: Schlachtzüge von Forever
--
-- DIESE TABELLE IST ABSICHTLICH FAST LEER, UND DAS IST EIN ZUSTAND,
-- KEIN RÜCKSTAND.
--
-- Bekannt sind heute genau drei Dinge je Schlachtzug: sein Name, seine
-- Gruppengrösse und dass er zum Erscheinungsinhalt gehört. Die
-- Bosslisten sind nicht veröffentlicht. Sie aus Mists of Pandaria zu
-- übernehmen wäre der schlechteste der drei möglichen Zustände
-- gewesen: eine gefüllte Liste schweigt nicht, sie sagt etwas
-- Falsches - "noch 8 Bosse offen" über einen Schlachtzug, dessen
-- Bosse niemand kennt.
--
-- Dieselbe Entscheidung hat die Companion für ihre Tabellen getroffen,
-- mit derselben Begründung; nachzulesen in
-- `../Companion-Forever/docs/systems/forever-data.md`.
--
-- Die Oberfläche trägt das: eine leere `bosses`-Liste heisst überall
-- im Addon "noch nicht bekannt" und nirgends "keine Bosse" oder "0 von
-- 0 erledigt". Wer hier etwas einträgt, ändert damit nichts am Code -
-- Seiten, Fortschritt und Suche greifen den Bestand von selbst auf.
--
-- EINTRAGEN, WENN DIE LISTEN DA SIND:
--
--   bosses = {
--       { id = "...", name = "...", order = 1 },
--       ...
--   }
--
--   `id`    stabiler Schlüssel (Fortschritt, Notizen hängen daran)
--   `name`  Anzeigename, deutsch
--   `order` Pullreihenfolge
--
-- `journalId` bleibt vorerst nil: welche Encounter-Journal-Kennungen
-- Forever vergibt, ist unbekannt, und eine geratene Kennung liest sich
-- im Code wie eine belegte.
--------------------------------------------------

WeintCodex_Raids = {

    {
        id       = "barrow_deeps",
        name     = "Barrow Deeps",
        size     = 10,
        release  = "Erscheinungsinhalt",
        opensAt  = "09.12.2026",
        journalId = nil,
        bosses   = {},
    },

    {
        id       = "hyjal_summit",
        name     = "Hyjal Summit",
        size     = 20,
        release  = "Erscheinungsinhalt",
        opensAt  = "09.12.2026",
        journalId = nil,
        bosses   = {},
    },

    {
        id       = "onyxias_hort",
        name     = "Onyxias Hort",
        size     = 40,
        release  = "Erscheinungsinhalt",
        opensAt  = "09.12.2026",
        journalId = nil,
        bosses   = {},
    },

}

--------------------------------------------------
-- Zugriff
--------------------------------------------------
-- Absichtlich Funktionen statt direkter Tabellenzugriffe: sie sind die
-- eine Stelle, an der "leer" von "unbekannt" unterschieden wird. Wer
-- `#raid.bosses` selbst zählt, bekommt 0 und weiss nicht, was die 0
-- bedeutet.
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
