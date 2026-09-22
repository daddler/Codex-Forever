--------------------------------------------------
-- WeintCodex :: Herkunft von Bestandsdaten
--
-- DIESE DATEI IST DIE ANTWORT AUF DIE EINE FRAGE, DIE IN DIESEM
-- REPOSITORY ÜBER JEDEM EINTRAG STEHT: worauf stützt sich das?
--
-- Bis 5.1.0.0 gab es die Frage nur bei den Schlachtzügen, und die
-- Antwort stand als lokale Tabelle in data/raids.lua. Mit den
-- Dungeons sind es drei Bestände geworden - Forever-Dungeons,
-- klassische Dungeons, Schlachtzüge -, und sie stützen sich auf
-- unterschiedlich feste Dinge. Eine gemeinsame Stelle ist besser als
-- drei halbe.
--
-- FÜNF ARTEN VON HERKUNFT, NACH ABNEHMENDER FESTIGKEIT:
--
--   "release"    Blizzard hat es veröffentlicht. Das ist der einzige
--                Zustand, der als bestätigt gilt.
--   "announced"  Blizzard hat es öffentlich gezeigt (BlizzCon,
--                Vorschauartikel), aber nicht als Liste
--                veröffentlicht. Was auf einer Messe spielbar war,
--                kann bis zum Erscheinen anders heissen.
--   "beta"       Aus dem Beta-Client gelesen. Ändert sich von Build
--                zu Build.
--   "community"  Aus Berichten der Beta und aus Datamining-Seiten
--                zusammengetragen. NIEMAND IN DIESEM PROJEKT HAT DEN
--                CLIENT SELBST GELESEN. Das ist die schwächste Art
--                von Herkunft, die hier überhaupt eingetragen werden
--                darf, und sie wird auf jeder Oberfläche als solche
--                ausgewiesen.
--   "classic"    Aus World of Warcraft Classic (Classic Era). Die
--                Angabe selbst ist seit zwanzig Jahren nachprüfbar -
--                OB SIE FÜR FOREVER GILT, IST ES NICHT. Blizzard hat
--                angekündigt, die Beute jedes Bosses überarbeitet zu
--                haben; über die Bosse selbst ist nichts gesagt.
--
-- WARUM "community" ÜBERHAUPT ERLAUBT IST. Die Regel lautete nie
-- "nur Belegtes darf hier stehen", sondern: es darf nichts dastehen,
-- dessen Herkunft sich nicht benennen lässt. Ein Bossname aus einem
-- Beta-Bericht IST benennbar. Er ist nur schwach - und genau das
-- steht dann auch daneben. Der Fehler, den die leere Tabelle
-- vermeiden sollte, war nie "zu wenig Bestand", sondern ein Bestand,
-- der fester aussieht, als er ist.
--
-- WER EINE QUELLE ERGÄNZT, TRÄGT `kind` UND `label` MIT EIN.
-- `.github/tests/data_test.lua` lässt alles andere durchfallen.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.Sources = {}

local S = WeintCodex.Sources

-- Die erlaubten Arten, in der Reihenfolge abnehmender Festigkeit.
-- Die Reihenfolge ist nicht Kosmetik: Rank() vergleicht damit, und
-- eine Instanz mit gemischten Quellen wird nach der SCHWÄCHSTEN
-- ausgewiesen.
S.KINDS = { "release", "announced", "beta", "community", "classic" }

local RANK = {}
for index, kind in ipairs(S.KINDS) do RANK[kind] = index end

--------------------------------------------------
-- Die Quellen selbst
--------------------------------------------------
-- Sie stehen hier und nicht in den Datendateien, damit ein neuer
-- Build an EINER Stelle nachgezogen wird und nicht an dreien halb.
--------------------------------------------------

-- Der Build, aus dem die Schlachtzugslisten stammen. Er bleibt
-- stehen, auch wenn inzwischen ein neuerer Client draussen ist: die
-- Listen wurden aus DIESEM gelesen, und ein hochgezähltes
-- Buildkürzel wäre eine Prüfung, die nie stattgefunden hat.
S.BETA_69876 = {
    kind  = "beta",
    build = "1.60.1.69876",
    date  = "17.09.2026",
    label = "Beta-Client 1.60.1.69876",
}

-- Der Build, nach dem gefragt wurde. Er ist vom 18.09.2026 und war
-- das erste Client-Update nach dem Beta-Start - nach allem, was
-- berichtet wird, mit Korrekturen an Starter, Absturzmeldung und
-- Grafikdateien, OHNE Änderungen an Talenten, Zaubern und
-- Gegenständen. Für die Bosslisten hat er also nichts gebracht, und
-- deshalb hängt hier auch keine einzige daran.
S.BETA_69913 = {
    kind  = "beta",
    build = "1.60.1.69913",
    date  = "18.09.2026",
    label = "Beta-Client 1.60.1.69913",
}

-- Was Blizzard auf der BlizzCon 2026 gezeigt hat. Die neun Dungeons
-- mit Name, Gebiet und Stufenbereich stammen von dort; ebenso die
-- zwei Bosse der Drowned City, die auf dem Messeboden spielbar war.
S.BLIZZCON = {
    kind  = "announced",
    date  = "BlizzCon 2026",
    label = "BlizzCon 2026",
}

-- DIE SCHWÄCHSTE QUELLE, DIE HIER STEHEN DARF, und die häufigste.
-- Bossnamen, Reihenfolgen und Positionshinweise aus Beta-Berichten
-- und Datamining-Seiten, gegengelesen über mehrere voneinander
-- unabhängige Darstellungen. Nicht aus dem Client, nicht von
-- Blizzard.
S.COMMUNITY = {
    kind  = "community",
    date  = "20.09.2026",
    label = "Beta-Berichte der Community",
}

-- World of Warcraft Classic (Classic Era). Für die zwanzig
-- klassischen Dungeons, die Forever im Kern weiterführt.
S.CLASSIC = {
    kind  = "classic",
    label = "WoW Classic (Classic Era)",
}

--------------------------------------------------
-- Zugriff
--------------------------------------------------

function S.IsValid(source)
    return type(source) == "table"
        and RANK[source.kind] ~= nil
        and type(source.label) == "string"
        and source.label ~= ""
end

-- Bestätigt ist NUR "release". Alles andere gilt als vorläufig - das
-- ist die Richtung, in die ein Irrtum harmlos ist.
function S.IsConfirmed(source)
    return S.IsValid(source) and source.kind == "release"
end

function S.Rank(source)
    if not S.IsValid(source) then return nil end
    return RANK[source.kind]
end

-- Von zwei Quellen die SCHWÄCHERE. Trägt eine Instanz Bosse aus
-- verschiedenen Quellen, wird sie nach dieser ausgewiesen: die
-- Gesamtangabe darf nie fester klingen als ihr schwächster Teil.
function S.Weaker(a, b)
    local ra, rb = S.Rank(a), S.Rank(b)
    if not ra then return b end
    if not rb then return a end
    if rb > ra then return b end
    return a
end

-- Ein kurzer Vorsatz für die Kopfzeile einer Liste. `nil` für
-- "release": eine bestätigte Liste braucht keinen Zusatz.
local PREFIX = {
    announced = "Angekündigt",
    beta      = "Vorläufig",
    community = "Unbestätigt",
    classic   = "Aus Classic",
}

function S.Label(source)
    if not S.IsValid(source) then return nil end
    if source.kind == "release" then return nil end
    return PREFIX[source.kind] .. " · " .. source.label
end

-- Nur der Vorsatz, ohne die Quelle dahinter. Für Flächen, auf denen
-- beides nebeneinander keinen Platz hat und getrennt steht: der
-- Detailbereich der Dungeonseite führt die ART in einer
-- Kennzahlenzeile ("Herkunft: Aus Classic") und die QUELLE mit der
-- Begründung darunter. `S.Label` in eine solche Zeile zu schreiben
-- hiesse, sie über die Beschriftung daneben laufen zu lassen -
-- Kennzahlenzeilen brechen nicht um (InspectorRows in
-- core/navigation.lua).
function S.Prefix(source)
    if not S.IsValid(source) then return nil end
    return PREFIX[source.kind]
end

-- Der lange Satz darunter: WARUM das hier nicht feststeht. Er ist
-- der eigentliche Zweck dieser Datei - ein Hinweis "vorläufig" ohne
-- Begründung ist eine Fussnote, die niemand liest.
local WHY = {
    announced = "Blizzard hat diesen Kampf öffentlich gezeigt, aber keine "
             .. "Liste veröffentlicht. Namen und Reihenfolge können sich bis "
             .. "zum Erscheinen ändern.",
    beta      = "Aus dem Beta-Client gelesen. Blizzard hat weder Namen noch "
             .. "Reihenfolge bestätigt, und beides ändert sich zwischen den "
             .. "Builds.",
    community = "Aus Beta-Berichten zusammengetragen, nicht aus dem Client "
             .. "gelesen und nicht von Blizzard bestätigt. Namen, Anzahl und "
             .. "Reihenfolge können falsch sein.",
    classic   = "Aus WoW Classic. Dass es den Boss dort gibt, steht fest - "
             .. "dass Forever ihn unverändert übernimmt, nicht. Blizzard hat "
             .. "die Beute jedes Bosses überarbeitet und zu den Kämpfen "
             .. "selbst nichts gesagt.",
}

function S.Why(source)
    if not S.IsValid(source) then return nil end
    if source.kind == "release" then return nil end
    return WHY[source.kind]
end
