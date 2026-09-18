WeintCodex = WeintCodex or {}
WeintCodex.Companion = {}

----------------------------------------------------------
-- Nachrichtentypen
----------------------------------------------------------

local STATE_MESSAGES = {

    materials = true,
    character = true,
    calendar  = true,

    -- Wer ist gerade angemeldet? Immer nur der letzte Stand.
    character_report = true,

    -- Ausruestungsstand des angemeldeten Charakters. Ebenfalls nur der
    -- letzte Stand: die Companion sammelt die Twinks ueber die Zeit
    -- auf ihrer Seite ein, hier liegt immer nur der aktuelle.
    character_sheet = true,

}

-- Ausgangsseitige Freigaben: welche Nachrichtenart welche Rolle braucht.
-- "character" (der Bot braucht den echten WoW-Namen fuer Kalender-Invites)
-- und "character_sheet" (die eigene Ausruestung, bleibt lokal) sind
-- absichtlich nicht gelistet.
local FEATURE_BY_MESSAGE = {

    loot      = "loot.report",
    materials = "materials.scan",

}

-- Gebundene Community-ID oder nil. Wird an jede ausgehende Nachricht
-- gestempelt, damit die Desktop-Seite Verkehr einer anderen Community
-- verwerfen kann (siehe core/access.lua).
local function BoundCommunityId()

    if not (WeintCodex.Access and WeintCodex.Access.Community) then return nil end

    local community = WeintCodex.Access.Community()
    if not community then return nil end

    return WeintCodex.Access.NormalizeId(community.id)

end

----------------------------------------------------------
-- Initialisierung
----------------------------------------------------------

local function Initialize()

WeintCompanionDB = WeintCompanionDB or {}

WeintCompanionDB.version =
WeintCompanionDB.version or 1

WeintCompanionDB.lastId =
WeintCompanionDB.lastId or 0

WeintCompanionDB.queue =
WeintCompanionDB.queue or {}

end

----------------------------------------------------------
-- Nachricht senden
----------------------------------------------------------

function WeintCodex.Companion.Send(
    messageType,
    payload
)

Initialize()

------------------------------------------------------
-- Freigabe pruefen
------------------------------------------------------
-- Ein Client ohne die passende Rolle soll nichts Gildeninternes
-- hinausschicken - z. B. keine Gildenbank einer fremden Gilde und
-- keine Loot-Meldungen in unseren Discord. Still, weil "loot" pro
-- Drop feuert; die Begruendung steht in der jeweiligen Oberflaeche.
------------------------------------------------------

local requiredFeature = FEATURE_BY_MESSAGE[messageType]

if requiredFeature and WeintCodex.Access
    and not WeintCodex.Access.Can(requiredFeature) then
    return nil
end

local community = BoundCommunityId()

------------------------------------------------------
-- Zustandsnachrichten ersetzen
------------------------------------------------------

if STATE_MESSAGES[messageType] then

    for _, message in ipairs(
        WeintCompanionDB.queue
    ) do

    if message.type == messageType then

        message.created = time()
        message.version = 1
        message.payload = payload

        -- Auch hier mitfuehren: trifft das Zugriffsprofil zwischen
        -- zwei Sends ein, behielte eine bereits eingereihte
        -- Nachricht sonst eine fehlende oder veraltete ID.
        message.community = community

        print(
            "|cff34C77BWeintCompanion|r: "
            .. messageType ..
            " aktualisiert."
        )

        return message.id

        end

        end

        end

        ------------------------------------------------------
        -- Neue Nachricht
        ------------------------------------------------------

        WeintCompanionDB.lastId =
        WeintCompanionDB.lastId + 1

        local message = {

            id = WeintCompanionDB.lastId,

            version = 1,

            type = messageType,

            created = time(),

            payload = payload,

            community = community,

        }

        table.insert(
            WeintCompanionDB.queue,
            message
        )

        print(
            "|cff34C77BWeintCompanion|r: "
            .. messageType ..
            " zur Warteschlange hinzugefügt."
        )

        return message.id

        end

        ----------------------------------------------------------
        -- Warteschlange
        ----------------------------------------------------------

        function WeintCodex.Companion.GetQueue()

        Initialize()

        return WeintCompanionDB.queue

        end

        ----------------------------------------------------------
        -- Anzahl
        ----------------------------------------------------------

        function WeintCodex.Companion.GetQueueSize()

        Initialize()

        return #WeintCompanionDB.queue

        end

        ----------------------------------------------------------
        -- Nachricht löschen
        ----------------------------------------------------------

        function WeintCodex.Companion.Remove(id)

        Initialize()

        for index, message in ipairs(
            WeintCompanionDB.queue
        ) do

        if message.id == id then

            table.remove(
                WeintCompanionDB.queue,
                index
            )

            return true

            end

            end

            return false

            end

            ----------------------------------------------------------
            -- Warteschlange leeren
            ----------------------------------------------------------

            function WeintCodex.Companion.Clear()

            Initialize()

            wipe(
                WeintCompanionDB.queue
            )

            end

----------------------------------------------------------
-- Inbox (Bot -> Companion -> Addon)
----------------------------------------------------------
-- Gegenrichtung zur obigen Warteschlange: Hier schreibt die
-- Companion-App Nachrichten hinein (z. B. den Raid-Roster-Export,
-- den ein per Discord-Login verknüpfter Raidlead automatisch vom Bot
-- abgerufen hat). ProcessInbox() wird beim Addon-Login aufgerufen
-- (siehe core/main.lua) und reicht jede Nachricht an den bereits
-- bestehenden Import-Parser weiter - identisch zum manuellen
-- Copy-Paste über /wc import, nur automatisch ausgelöst.
----------------------------------------------------------

local function InitializeInbox()

WeintCompanionInboxDB = WeintCompanionInboxDB or {}

WeintCompanionInboxDB.queue =
WeintCompanionInboxDB.queue or {}

end

----------------------------------------------------------
-- Welche Companion-Version schreibt hier?
----------------------------------------------------------
-- WeintCompanion 1.7.0 schreibt companionVersion bei jedem
-- Schreibvorgang in WeintCompanionInboxDB. Wir brauchen die Angabe
-- fuer genau eine Entscheidung: ob wir "character_report" senden
-- duerfen. Eine aeltere Companion kennt den Typ nicht, wuerde ihn an
-- den Bot schicken, dort scheitern, die Nachricht liegen lassen und
-- alle fuenf Sekunden einen Fehler ins Log schreiben.
--
-- Fehlt die Marke, gilt "zu alt" - der Normalfall vor 1.7.0.
--
-- `patch` ist optional und kam mit "character_sheet" dazu: die
-- Nachricht gibt es erst ab Companion 2.0.1, und 2.0.0 war bereits
-- draussen. Ohne die dritte Stelle waere "mindestens 2.0" wahr fuer
-- eine Companion, die den Typ noch nicht kennt - also genau der
-- Fehler, gegen den diese Funktion ueberhaupt existiert.
----------------------------------------------------------

local function CompanionAtLeast(major, minor, patch)

    InitializeInbox()

    -- Die Live-Bruecke (data/companion_live.lua) traegt dieselbe Marke
    -- und ist der verlaesslichere Zeuge: sie steht in einer Datei, die
    -- WoW nur liest. Die Inbox daneben kann ein /reload ueberschrieben
    -- haben, bevor das Addon sie je gesehen hat - dann stuende dort die
    -- Version vom letzten Login statt der laufenden.
    local version

    if type(WeintCodex_CompanionLive) == "table"
        and type(WeintCodex_CompanionLive.companionVersion) == "string"
        and WeintCodex_CompanionLive.companionVersion ~= "" then

        version = WeintCodex_CompanionLive.companionVersion

    else

        version = WeintCompanionInboxDB.companionVersion

    end

    if type(version) ~= "string" then return false end

    local gotMajor, gotMinor = version:match("^v?(%d+)%.(%d+)")
    if not gotMajor then return false end

    gotMajor, gotMinor = tonumber(gotMajor), tonumber(gotMinor)

    if gotMajor ~= major then return gotMajor > major end
    if gotMinor ~= minor then return gotMinor > minor end

    if not patch then return true end

    -- Eine fehlende dritte Stelle ist eine Null ("2.0" = "2.0.0") und
    -- nicht "unbekannt": so schreibt core/version.py drueben es auch.
    local gotPatch = tonumber(version:match("^v?%d+%.%d+%.(%d+)") or 0) or 0

    return gotPatch >= patch

end

----------------------------------------------------------
-- Inbox (Bot/Companion -> Addon): Nachrichtentypen
----------------------------------------------------------
-- raid_import      payload = WCIMPORT-String (siehe modules/sync.lua)
--
-- Die folgenden vier erwarten eine TABELLE als payload, keinen String:
--
-- access_profile   { community = { id = "<Discord-Guild-ID>", name },
--                    identity  = { discordId, discordName },
--                    tier, tierLabel, roles = {...},
--                    features  = { ["raids.view"] = true, ... },
--                    issuedAt, expiresAt, companionVersion, notice }
--                  Das vollstaendige Schema und die Bindungsregeln stehen im
--                  Kopf von core/access.lua. Diese Nachricht bindet das Addon
--                  an eine Community und steuert alle Freigaben.
--
-- WAS ES IN DIESER FASSUNG NICHT GIBT, und warum:
--
--   academy_catalog / academy_state / weinttv_report
--       Die Academy und WeintTV rechnen drueben aus einem
--       Kampflog. Ob Forever eines hergibt, aus dem sich das
--       ableiten laesst, ist nicht bestaetigt (siehe
--       ../Companion-Forever/docs/systems/forever-data.md, letzter
--       Abschnitt). Solange das offen ist, waere eine Seite, die
--       Bewertungen anzeigt, eine Seite, die Bewertungen behauptet.
--
--   weakaura_library
--       WeakAuras werden fuer Forever zunaechst nicht unterstuetzt.
--
--   stat_weights / target_gear
--       Beide kommen aus einem Sim. Fuer Forever gibt es keinen.
--
-- Die Nachrichten werden nicht abgewiesen, sondern schlicht nicht
-- behandelt: ProcessQueue laeuft nur ueber Typen, fuer die es einen
-- Behandler gibt, und laesst den Rest liegen. Eine Companion, die
-- solche Nachrichten schickt, bekommt dadurch keinen Fehler.
--
-- Zwei Konventionen aus der Companion gelten hier genauso:
--   stars == 0  heisst "keine Daten", nicht "schlecht"
--   at    == -1 heisst "kein Zeitpunkt bekannt"
--
-- Jede Nachricht darf zusaetzlich ein message.community (Zeichenkette) auf
-- der Huelle tragen. Weicht es von der Bindung ab, wird die Nachricht
-- verworfen statt eingearbeitet - fuer access_profile wird das Feld
-- ignoriert, dort ist die Nutzlast maßgeblich.
--
-- Ausgehend traegt jede Nachricht in WeintCompanionDB.queue umgekehrt ein
-- community-Feld mit der gebundenen ID.
----------------------------------------------------------

local INBOX_HANDLERS = {}

INBOX_HANDLERS.access_profile = function(payload)

    if type(payload) ~= "table" then return end

    if WeintCodex.Access and WeintCodex.Access.ApplyProfile then
        WeintCodex.Access.ApplyProfile(payload)
    end

end

INBOX_HANDLERS.raid_import = function(payload)

    if type(payload) ~= "string" then return end

    if WeintCodex.Sync and WeintCodex.Sync.QuickImport then
        WeintCodex.Sync.QuickImport(payload)
    end

end

local function Dispatch(message)

    local handler = INBOX_HANDLERS[message.type]

    -- Eine fehlerhafte Nachricht darf die restliche Warteschlange
    -- nicht mitreissen: sonst bliebe z.B. der Raid-Import liegen,
    -- weil die Auswertung davor ein Feld anders benannt hat.
    local ok, err = pcall(handler, message.payload)
    if not ok then
        print(WeintCodex.ColorText("danger", "[WeintCodex]")
            .. " Companion-Nachricht \"" .. tostring(message.type)
            .. "\" konnte nicht verarbeitet werden: " .. tostring(err))
    end

end

----------------------------------------------------------
-- Zwei Quellen, eine Warteschlange
----------------------------------------------------------
-- WeintCompanionInboxDB ist eine SavedVariable, und das ist genau
-- ihr Problem: WoW schreibt SavedVariables bei /reload und beim
-- Abmelden aus dem Arbeitsspeicher zurueck und liest sie erst
-- danach wieder ein. Was die Companion waehrend der laufenden
-- Sitzung hineingeschrieben hat, wird von diesem Rueckschreiben
-- geloescht, bevor das Addon es sehen kann. Ein /reload konnte
-- deshalb nie neue Daten holen - und weil die Companion sich merkt,
-- was sie zuletzt zugestellt hat, kam ein unveraenderter Roster
-- danach auch kein zweites Mal.
--
-- Die Live-Bruecke (data/companion_live.lua, von der Companion
-- geschrieben) hat das Problem nicht: WoW fuehrt Addon-Dateien bei
-- jedem /reload neu aus und schreibt sie nie zurueck.
--
-- Beide Quellen tragen dieselben Nachrichtentypen. Liegt eine
-- Live-Zustellung vor, gilt sie - sie ist per Konstruktion der
-- juengere Stand, die Inbox daneben hoechstens gleich alt. Fehlt
-- sie (aeltere Companion, Addon frisch entpackt), bleibt es beim
-- bisherigen Weg.
--
-- Das Addon kann die Live-Datei nicht leeren - es schreibt keine
-- Dateien. Deshalb merkt es sich den Stand, den es zuletzt
-- eingearbeitet hat, und laesst eine unveraenderte Zustellung beim
-- naechsten /reload still liegen. Sonst meldete jeder Reload
-- denselben Import erneut im Chat.
----------------------------------------------------------

local function LiveDelivery()

    local live = WeintCodex_CompanionLive

    if type(live) ~= "table" then return nil end
    if type(live.queue) ~= "table" then return nil end
    if #live.queue == 0 then return nil end

    return live

end

function WeintCodex.Companion.LiveInfo()

    local live = LiveDelivery()

    if not live then return nil end

    return {
        writtenAt = tonumber(live.writtenAt) or 0,
        version   = live.companionVersion,
        count     = #live.queue,
    }

end

-- Nach einem "Loeschen" der Raiddaten soll dieselbe Zustellung beim
-- naechsten /reload wieder eingearbeitet werden - sonst waere sie
-- unerreichbar, bis die Companion von sich aus etwas Neues schickt.
function WeintCodex.Companion.ForgetLiveStamp()

    WeintCodex.SavedData = WeintCodex.SavedData or {}
    WeintCodex.SavedData.companionLive =
        WeintCodex.SavedData.companionLive or {}
    WeintCodex.SavedData.companionLive.lastStamp = nil

end

----------------------------------------------------------
-- Eine Warteschlange einarbeiten
----------------------------------------------------------

local function ProcessQueue(queue)

------------------------------------------------------
-- 1. Durchgang: nur Zugriffsprofile
------------------------------------------------------
-- Muss vor allem anderen laufen. Sonst wuerde beim erstmaligen
-- Verknuepfen genau der Schwung Daten noch durchrutschen, den das
-- gelieferte Profil eigentlich sperrt. Mehrere Profile werden in
-- Warteschlangen-Reihenfolge angewandt, das letzte gewinnt.
------------------------------------------------------

for _, message in ipairs(queue) do

    if message.type == "access_profile" and message.payload ~= nil then
        Dispatch(message)
    end

end

------------------------------------------------------
-- 2. Durchgang: alles andere, mit Herkunftspruefung
------------------------------------------------------

local rejected = 0

for _, message in ipairs(queue) do

    if message.type ~= "access_profile"
        and INBOX_HANDLERS[message.type]
        and message.payload ~= nil then

        if WeintCodex.Access and WeintCodex.Access.IsForeign(message.community) then

            rejected = rejected + 1
            WeintCodex.Access.NoteRejection(message.community)

        else

            Dispatch(message)

        end

    end

end

-- Eine gesammelte Warnung, nicht eine pro Nachricht.
if rejected > 0 then
    print(WeintCodex.ColorText("warning", "[WeintCodex]") .. " "
        .. string.format(WeintCodex.Access.MSG_FOREIGN_INBOX,
            rejected, WeintCodex.Access.CommunityName()))
end

end

function WeintCodex.Companion.ProcessInbox()

InitializeInbox()

WeintCodex.SavedData = WeintCodex.SavedData or {}
WeintCodex.SavedData.companionLive =
    WeintCodex.SavedData.companionLive or {}

local marker = WeintCodex.SavedData.companionLive
local live   = LiveDelivery()

------------------------------------------------------
-- Was ist einzuarbeiten?
------------------------------------------------------
-- Beide Quellen tragen dieselbe Zustellung; die Companion schreibt
-- sie aus derselben Liste. Trotzdem wird hier nicht die eine gegen
-- die andere ausgespielt, sondern zusammengefuehrt: die Live-Datei
-- kann fehlschlagen (Addon-Ordner verschoben, Rechte), waehrend die
-- Inbox geschrieben wurde. Die Inbox dann ungelesen zu leeren, weil
-- "die Live-Datei ist ja da", wuerde genau in diesem Fall eine
-- Zustellung wegwerfen.
--
-- Doppelt gemeldet wird deshalb trotzdem nichts: eine Nachricht mit
-- gleicher Zeichenketten-Nutzlast, die schon aus der Live-Zustellung
-- kam, wird uebersprungen. Nur die tragen eine Chatmeldung
-- (raid_import); die Tabellen-Nutzlasten schreiben still einen
-- Zustand und duerfen ruhig zweimal laufen - dann gewinnt die Inbox,
-- weil sie zuletzt laeuft, und das ist die sichere Richtung.
------------------------------------------------------

local queue = {}
local seen  = {}

if live then

    local stamp = tonumber(live.writtenAt) or 0
    local isNew = (stamp == 0) or (stamp ~= marker.lastStamp)

    for _, message in ipairs(live.queue) do

        if type(message.payload) == "string" then
            seen[tostring(message.type) .. "\1"
                .. tostring(message.community) .. "\1"
                .. message.payload] = true
        end

        -- Ein unveraenderter Stand wird nicht erneut eingearbeitet.
        -- Das Addon kann die Datei nicht leeren, sie liegt also bei
        -- jedem /reload wieder da - ohne diese Marke meldete jeder
        -- Reload denselben Import erneut.
        if isNew then
            queue[#queue + 1] = message
        end

    end

    if isNew then
        marker.lastStamp   = stamp
        marker.lastCount   = #live.queue
        marker.lastVersion = live.companionVersion
    end

end

for _, message in ipairs(WeintCompanionInboxDB.queue) do

    local fingerprint

    if type(message.payload) == "string" then
        fingerprint = tostring(message.type) .. "\1"
            .. tostring(message.community) .. "\1"
            .. message.payload
    end

    if not (fingerprint and seen[fingerprint]) then
        queue[#queue + 1] = message
    end

end

-- Die Inbox wird in jedem Fall geleert. Sie liegt zu lassen hiesse
-- dieselbe Warnung bei jedem Login - und schlimmer: nach einem
-- legitimen /wc access reset wuerden wochenalte Roster der
-- vorherigen Community ploetzlich angenommen.
wipe(WeintCompanionInboxDB.queue)

if #queue == 0 then
    return
end

ProcessQueue(queue)

end

----------------------------------------------------------
-- Charakter-Meldung (Companion -> Bot, für Kalender-Invites)
----------------------------------------------------------
-- Meldet den aktuell eingeloggten Charakter automatisch in
-- WeintCodex.SavedData.twinks (dieselbe kontoweite Twink-Liste wie in
-- der Twinkverwaltung) und schickt anschließend alle als "eigen"
-- markierten Charaktere über die Companion-Warteschlange an den Bot.
-- Der Bot gleicht sie beim Raid-Export gegen die bei der Anmeldung
-- gewählte Klasse ab, um den echten WoW-Namen statt des Discord-
-- Anzeigenamens für den Kalendereintrag zu finden.
----------------------------------------------------------

function WeintCodex.Companion.ReportCharacter()

    WeintCodex.SavedData = WeintCodex.SavedData or {}
    WeintCodex.SavedData.twinks = WeintCodex.SavedData.twinks or {}

    local twinks = WeintCodex.SavedData.twinks

    local playerName = UnitName("player")
    local _, classFileName = UnitClass("player")
    local level = UnitLevel("player")
    local realm = (GetRealmName() or ""):gsub("%s+", "")

    if playerName then

        twinks[playerName] = twinks[playerName] or {}
        twinks[playerName].class = classFileName or twinks[playerName].class
        twinks[playerName].level = tostring(level or twinks[playerName].level or 0)
        twinks[playerName].realm = realm ~= "" and realm or twinks[playerName].realm
        twinks[playerName].selected = true

    end

    local parts = {}

    -- Crossrealm-Raids (z. B. Everlook/Ook Ook): der Bot braucht den
    -- Realm jedes gemeldeten Charakters, damit der Kalender-Invite den
    -- richtigen Realm statt immer nur den des einladenden Spielers
    -- verwendet.
    for name, data in pairs(twinks) do

        if data.selected and data.class then
            table.insert(parts, name .. "|" .. data.class .. "|" .. (data.realm or ""))
        end

    end

    if #parts == 0 then
        return
    end

    table.sort(parts)

    WeintCodex.Companion.Send(
        "character",
        table.concat(parts, ",")
    )

end

----------------------------------------------------------
-- Wer spielt gerade? (Addon -> Companion, bleibt lokal)
----------------------------------------------------------
-- Bis WeintCodex 1.3.2.3 erfuhr die Companion NIE, welcher Charakter
-- ingame angemeldet ist. Sie musste die Frage "wer bin ich" aus einer
-- WarcraftLogs-Namensliste raten - im Zweifel wurde der alphabetisch
-- erste Raider genommen. Genau daher stammte der Fehler, dass in der
-- Academy und in WeintTV ein voellig fremder Charakter stand.
--
-- Bewusst ein EIGENER Nachrichtentyp und keine Erweiterung von
-- "character": jene Nachricht laeuft ueber den CharacterSyncClient
-- weiter an den Discord-Bot, alles daran Angehaengte waere damit ein
-- Bot-Vertrag. "character_report" wird von der Companion lokal
-- verarbeitet (core/character_report_sync.py) und verlaesst den
-- Rechner nie - dasselbe Muster wie "dummy_practice_session".
--
-- Format (flache Zeichenkette; Ausgangsnachrichten kann
-- addon/sync_reader.py der Companion nur als String lesen):
--
--   <Name>|<Realm>|<classFile>|<Level>|<specKey>
--
-- specKey darf leer bleiben - die Spezialisierung steht bei
-- PLAYER_LOGIN noch nicht verlaesslich fest. Die Companion nimmt
-- zwei bis fuenf Felder und ignoriert weitere, das Format kann also
-- wachsen, ohne die alte Gegenseite zu brechen.
----------------------------------------------------------

function WeintCodex.Companion.ReportLoggedInCharacter()

    -- Eine zu alte Companion kennt den Typ nicht und wuerde ihn an
    -- den Bot zu senden versuchen: das scheitert, die Nachricht
    -- bliebe liegen und erzeugte im Sync-Takt Fehlermeldungen.
    if not CompanionAtLeast(1, 7) then
        return
    end

    local name, realm = WeintCodex.Names.Me()
    if name == "" then return end

    local _, classFile = UnitClass("player")
    local level = UnitLevel("player")

    -- Derselbe Profilschluessel wie ueberall sonst (siehe
    -- data/spec_profiles.lua). Er darf leer bleiben: bei PLAYER_LOGIN
    -- ist die Spezialisierung noch nicht verlaesslich abfragbar, und
    -- die Companion braucht sie fuer die Charakterauswahl nicht.
    local specKey = ""
    if WeintCodex.Charakter and WeintCodex.Charakter.GetProfileKey then
        specKey = WeintCodex.Charakter.GetProfileKey() or ""
    end

    return WeintCodex.Companion.Send(
        "character_report",
        table.concat({
            name,
            realm or "",
            classFile or "",
            tostring(level or 0),
            specKey,
        }, "|")
    )

end

----------------------------------------------------------
-- Ausruestungsstand (Addon -> Companion, bleibt lokal)
----------------------------------------------------------
-- Die Companion-Seiten "Meine Charaktere" und "Vorbereitung" waren bis
-- 2.0.0 leer, und das war ehrlich: ueber Ausruestung wusste die App
-- schlicht nichts. Die Twinkliste ("character") traegt Name, Klasse und
-- Realm und wandert an den Bot; Gegenstandsstufe, Verzauberungen,
-- Sockel und offene BiS-Plaetze kamen nirgends vor. Ein Ring bei 0 %
-- haette eine Messung behauptet, die es nicht gab - deshalb stand dort
-- ein Leerzustand statt einer Null.
--
-- Diese Nachricht liefert die fehlende Messung. Sie bleibt wie
-- "character_report" und "dummy_practice_session" auf dem Rechner des
-- Spielers und geht den Bot nichts an: es ist die eigene Ausruestung,
-- kein Gildenwissen. Bewusst ein eigener Typ und keine Erweiterung von
-- "character" - jene Nachricht ist ein Bot-Vertrag.
--
-- Format (flache Zeichenkette; Ausgangsnachrichten kann
-- addon/sync_reader.py der Companion nur zeilenweise als String lesen,
-- verschachtelte Tabellen gibt es nur in der Gegenrichtung):
--
--   <KOPF> ~ <ZAEHLER> ~ <BIS> ~ <SLOTS> ~ <MAENGEL>
--
--   Abschnitte mit "~", Datensaetze mit ";", Felder mit "|".
--
--   KOPF     Name|Realm|classFile|Level|specKey|specName|
--            IlvlAngelegt|IlvlGesamt|Punkte|Note|Vollstaendigkeit|
--            Qualitaet|Zeitstempel
--   ZAEHLER  je ein Satz "ench" und "gem":
--            Art|optimal|ok|falsch|ueberCap|fehlt|gesamt
--   BIS      Satz 1: getragen|Variante|offen|gesamt
--            Satz 2: Namen der offenen Plaetze, mit "|" getrennt
--            (leerer Abschnitt = fuer diese Spec ist keine Liste
--            gepflegt; das ist etwas anderes als "nichts offen")
--   SLOTS    slotId|Slotname|Itemname|Ilvl|Verzauberung|Sockel
--            Status je: optimal|ok|wrong|overcap|missing|-
--            ("-" heisst: dieser Platz kennt so etwas nicht)
--   MAENGEL  prio|status|Text
--
-- Die Companion nimmt fehlende Abschnitte und fehlende Felder hin und
-- ignoriert zusaetzliche (siehe core/character_sheet_sync.py) - das
-- Format darf also wachsen, ohne eine aeltere Gegenseite zu brechen.
----------------------------------------------------------

-- Trennzeichen duerfen im Inhalt nicht vorkommen. Itemnamen kommen aus
-- dem Client und koennen theoretisch alles enthalten; ausserdem
-- schreibt sync_reader.py die Nutzlast in einen Lua-String zurueck, in
-- dem ein Backslash nicht entwertet wird.
local function CleanField(text)

    text = tostring(text or "")

    text = text:gsub("[|;~\"\\\r\n]", " ")

    return (text:gsub("%s+", " "):gsub("^%s*(.-)%s*$", "%1"))

end

local function BuildCharacterSheet()

    local Charakter = WeintCodex.Charakter
    if not (Charakter and Charakter.Snapshot) then return nil end

    local name, realm = WeintCodex.Names.Me()
    if name == "" then return nil end

    local snapshot = Charakter.Snapshot()
    if not snapshot then return nil end

    local _, classFile = UnitClass("player")
    local level = UnitLevel("player")

    ------------------------------------------------------
    -- KOPF
    ------------------------------------------------------
    -- Vier Felder bleiben LEER, und das ist der Punkt dieser Fassung:
    -- `score`, `grade` und `quality` setzen eine Bewertung der
    -- Ausruestung voraus (Verzauberungen, Sockel, Sim-Ziel), die es
    -- fuer Forever nicht gibt. Ein leeres Feld liest die Companion als
    -- "nicht gemessen"; eine 0 laese sie als Messung und faerbte den
    -- Vorbereitungsring dauerhaft rot fuer etwas, das der Spieler
    -- nicht abstellen kann.
    --
    -- `completeness` dagegen ist messbar: belegte Plaetze durch
    -- mahnbare Plaetze. Nebenhand und Distanz zaehlen dabei nicht mit
    -- (siehe Snapshot) - ein Zweihandkaempfer ist nicht zu 94 %
    -- angezogen.
    ------------------------------------------------------

    local mandatory = #snapshot.empty
    for _, slot in ipairs(snapshot.slots) do
        if slot.link then mandatory = mandatory + 1 end
    end

    local completeness = ""
    if mandatory > 0 then
        completeness = string.format("%.0f",
            ((mandatory - #snapshot.empty) / mandatory) * 100)
    end

    local header = table.concat({
        CleanField(name),
        CleanField(realm or ""),
        CleanField(classFile or ""),
        tostring(level or 0),
        CleanField(snapshot.specKey or ""),
        CleanField(snapshot.specDisplay or ""),
        snapshot.itemLevel    and string.format("%.1f", snapshot.itemLevel)    or "",
        snapshot.itemLevelAll and string.format("%.1f", snapshot.itemLevelAll) or "",
        "",             -- score:   nicht bewertbar
        "",             -- grade:   nicht bewertbar
        completeness,
        "",             -- quality: nicht bewertbar
        tostring(time()),
    }, "|")

    ------------------------------------------------------
    -- ZAEHLER und BIS: beide Abschnitte bleiben LEER
    ------------------------------------------------------
    -- Der Vertrag sieht das ausdruecklich vor: ein fehlender Abschnitt
    -- ist kein Fehler, und `readiness()` drueben liefert dann `None`
    -- statt 0.0 - ein leerer Ring statt eines roten. Genau dafuer ist
    -- die Regel da (siehe ../Companion-Forever/docs/character-sheet-bridge.md,
    -- Abschnitt "Toleranzregeln").
    ------------------------------------------------------

    ------------------------------------------------------
    -- SLOTS
    ------------------------------------------------------
    -- slotId|Slotname|Itemname|Ilvl|Verzauberung|Sockel
    --
    -- Die beiden Statusfelder tragen durchgaengig "-": "dieser Platz
    -- kennt so etwas nicht". Das ist nicht gelogen und nicht
    -- ausgelassen - Forever kennt hier nichts dergleichen.
    ------------------------------------------------------

    local slotRecords = {}

    for _, slot in ipairs(snapshot.slots) do

        local itemName = ""
        if slot.link then
            itemName = slot.link:match("%[(.-)%]") or ""
        end

        slotRecords[#slotRecords + 1] = table.concat({
            tostring(slot.id),
            CleanField(slot.name),
            CleanField(itemName),
            -- Ein leerer Platz meldet 0 und wird nicht ausgelassen -
            -- die Companion soll "hier haengt nichts" zeigen koennen.
            -- Eine UNBEKANNTE Stufe bei belegtem Platz meldet
            -- ebenfalls 0; sie ist dort nicht von "leer" zu
            -- unterscheiden, aber der Itemname steht daneben.
            string.format("%.0f", slot.itemLevel or 0),
            "-",
            "-",
        }, "|")

    end

    ------------------------------------------------------
    -- MAENGEL
    ------------------------------------------------------
    -- prio|status|Text, nach Dringlichkeit sortiert. Nur zwei Sorten,
    -- und beide sind unstrittig.
    ------------------------------------------------------

    local issueRecords = {}

    for _, slotName in ipairs(snapshot.empty) do
        issueRecords[#issueRecords + 1] = table.concat({
            "1", "missing",
            CleanField(slotName .. ": kein Gegenstand angelegt"),
        }, "|")
    end

    for _, slotName in ipairs(snapshot.broken) do
        issueRecords[#issueRecords + 1] = table.concat({
            "2", "wrong",
            CleanField(slotName .. ": Gegenstand ist zerbrochen"),
        }, "|")
    end

    return table.concat({
        header,
        "",     -- ZAEHLER
        "",     -- BIS
        table.concat(slotRecords, ";"),
        table.concat(issueRecords, ";"),
    }, "~")

end

-- Zuletzt gesendete Nutzlast. Der Scan laeuft bei jedem
-- Ausruestungswechsel, die Nachricht aber nur, wenn sich am Ergebnis
-- etwas geaendert hat - sonst schriebe jeder Ringtausch dieselbe
-- Zeichenkette erneut in die SavedVariables.
local lastSheet = nil

function WeintCodex.Companion.ReportCharacterSheet()

    -- Erst Companion 2.0.1 kennt den Typ. Eine aeltere wuerde ihn in
    -- ihren generischen Zweig geben, an den Bot POSTen, scheitern, die
    -- Nachricht liegen lassen und im Sync-Takt Fehler protokollieren.
    if not CompanionAtLeast(2, 0, 1) then
        return
    end

    local sheet = BuildCharacterSheet()

    if not sheet or sheet == lastSheet then
        return
    end

    lastSheet = sheet

    return WeintCodex.Companion.Send("character_sheet", sheet)

end

----------------------------------------------------------
-- Wann gemeldet wird
----------------------------------------------------------
-- Nicht bei PLAYER_LOGIN: dort ist weder die Spezialisierung
-- verlaesslich abfragbar noch sind die Item-Daten im Client-Cache, und
-- ein Scan zu diesem Zeitpunkt meldete eine halb leere Ausruestung als
-- Befund. PLAYER_ENTERING_WORLD plus eine kurze Wartezeit ist der
-- Zeitpunkt, zu dem auch die Charakterseite des Addons brauchbare
-- Werte liefert.
--
-- Danach bei jedem Ausruestungs- oder Spec-Wechsel, entprellt: ein
-- kompletter Scan liest je Item den Tooltip, und beim Umsockeln
-- feuert PLAYER_EQUIPMENT_CHANGED mehrfach hintereinander.
----------------------------------------------------------

local sheetWatcher = CreateFrame("Frame")

sheetWatcher._pending = false

local function ScheduleCharacterSheet(delay)

    if sheetWatcher._pending then return end

    if not (C_Timer and C_Timer.After) then
        WeintCodex.Companion.ReportCharacterSheet()
        return
    end

    sheetWatcher._pending = true

    C_Timer.After(delay or 3, function()
        sheetWatcher._pending = false
        pcall(WeintCodex.Companion.ReportCharacterSheet)
    end)

end

WeintCodex.Companion.ScheduleCharacterSheet = ScheduleCharacterSheet

sheetWatcher:RegisterEvent("PLAYER_ENTERING_WORLD")
sheetWatcher:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
sheetWatcher:RegisterEvent("SKILL_LINES_CHANGED")

-- Wie in modules/bis.lua ueber pcall: welche der Spec-Events ein
-- Classic-Build kennt, schwankt.
pcall(sheetWatcher.RegisterEvent, sheetWatcher, "PLAYER_SPECIALIZATION_CHANGED")
pcall(sheetWatcher.RegisterEvent, sheetWatcher, "ACTIVE_TALENT_GROUP_CHANGED")

sheetWatcher:SetScript("OnEvent", function(_, event)

    -- Beim ersten Betreten der Welt braucht der Client laenger, bis
    -- Item-Infos im Cache stehen.
    ScheduleCharacterSheet(event == "PLAYER_ENTERING_WORLD" and 8 or 3)

end)
