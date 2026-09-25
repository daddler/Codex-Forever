--------------------------------------------------
-- WeintCodex :: Start (Forever Edition)
--
-- Drei Dinge, und sonst nichts: die Fassung, die Slash-Befehle und was
-- beim Laden zu geschehen hat.
--------------------------------------------------

WeintCodex = WeintCodex or {}

-- MUSS mit "## Version" in WeintCodex.toc und dem obersten Eintrag in
-- data/changelog.lua uebereinstimmen, und der Release-Tag muss genau
-- "v" plus diese Zahl sein. Die CI prueft alle vier gegeneinander und
-- bricht sonst ab - siehe .github/scripts/release_notes.py und
-- docs/development/releases.md.
WeintCodex.Version = "6.3.0.1"

SLASH_WEINTCODEX1 = "/wc"
SLASH_WEINTCODEX2 = "/weintcodex"

--------------------------------------------------
-- Slash-Befehle
--------------------------------------------------
-- Jeder davon hat eine Entsprechung in der Oberflaeche. Der Befehl ist
-- der schnelle Weg mitten in der Aufstellung, nicht die einzige
-- Bedienung - eine Einstellung, die es nur als Befehl gibt, kennt nur,
-- wer sie schon kennt (siehe modules/settings.lua).

local function Open(tabId)
    if not (WeintCodex.MainFrame and WeintCodex.Navigation) then return end
    WeintCodex.MainFrame:Show()
    if WeintCodex.Navigation.GoToTab then
        WeintCodex.Navigation.GoToTab(tabId)
    end
end

SlashCmdList["WEINTCODEX"] = function(msg)
    local cmd = msg and msg:lower() or ""

    -- Erstes Wort plus Rest: die Befehle unten vergleichen exakt, nur
    -- "access" und "gruppe" nehmen ein Argument.
    local verb, rest = cmd:match("^(%S+)%s*(.-)$")
    verb = verb or ""
    rest = rest or ""

    -- Zugriffsprofil anzeigen / Verknuepfung aufheben
    if verb == "access" or verb == "zugriff" then
        if not WeintCodex.Access then return end
        if rest == "reset" then
            WeintCodex.Access.Reset(false)
        elseif rest == "reset bestaetigen" or rest == "reset bestätigen" then
            WeintCodex.Access.Reset(true)
        else
            WeintCodex.Access.Print()
        end
        return
    end

    -- Gruppencheck sofort oeffnen: der schnelle Weg mitten in der
    -- Aufstellung, wenn niemand erst durch die Navigation klicken will.
    if verb == "gruppe" or verb == "gruppencheck" then
        Open("gruppe")
        if rest == "pruefen" or rest == "prüfen" then
            if WeintCodex.GroupCheck and WeintCodex.GroupCheck.Run then
                WeintCodex.GroupCheck.Run()
            end
        end
        return
    end

    if verb == "raids" or verb == "schlachtzug" or verb == "schlachtzüge"
       or verb == "schlachtzuege" then
        Open("raids")
        return
    end

    if verb == "dungeons" or verb == "dungeon" or verb == "inis"
       or verb == "ini" then
        Open("dungeons")
        return
    end

    if verb == "anmeldung" or verb == "anmeldungen" then
        Open("anmeldung")
        return
    end

    if verb == "charakter" or verb == "char" then
        Open("charakter")
        return
    end

    if verb == "material" or verb == "materialien" then
        Open("materialien")
        return
    end

    if verb == "companion" or verb == "bruecke" or verb == "brücke" then
        Open("companion")
        return
    end

    if verb == "import" then
        if WeintCodex.Sync and WeintCodex.Sync.ShowImportDialog then
            Open("import")
        end
        return
    end

    -- Kalender-Diagnose: was gibt der Client an Einladungsfunktionen her,
    -- welchen Realm vergleicht das Addon, und welcher Name wuerde je
    -- Spieler angefragt? Eigener Befehl, weil "24 von 25 nicht gefunden"
    -- bei einer fehlenden Client-Funktion, einem falsch verglichenen
    -- Realm und einem wirklich falschen Charakternamen identisch aussieht.
    if verb == "kalender" or verb == "calendar" then
        if rest == "pruefen" or rest == "prüfen" or rest == "dump" then
            if WeintCodex.Calendar and WeintCodex.Calendar.Dump then
                WeintCodex.Calendar.Dump()
            end
            return
        end
        Open("kalender")
        return
    end

    -- Einstellungsseite. Sie ist der Ort, an dem jeder Befehl hier oben
    -- auch als Schaltflaeche steht - deshalb ist dieser eine Befehl der
    -- einzige, den man sich merken muesste.
    if verb == "einstellungen" or verb == "optionen" or verb == "settings"
       or verb == "config" then
        Open("settings")
        return
    end

    -- Die optionale Oberflaeche (ui/options.lua). /wcui fuehrt ebenfalls
    -- dorthin; hier steht sie, damit /wc der eine Befehl bleibt, den man
    -- sich merken muss.
    if verb == "ui" or verb == "oberflaeche" or verb == "oberfläche" then
        if WeintCodex.UIOptions then WeintCodex.UIOptions.Show("general") end
        return
    end
    if verb == "pfeil" or verb == "questpfeil" then
        if WeintCodex.UIOptions then WeintCodex.UIOptions.Show("questarrow") end
        return
    end

    -- Einfuehrung erneut aufrufen
    if verb == "tour" or verb == "einfuehrung" or verb == "einführung" then
        if WeintCodex.Onboarding and WeintCodex.Onboarding.ShowTour then
            WeintCodex.Onboarding.ShowTour()
        end
        return
    end

    if WeintCodex.MainFrame:IsShown() then
        WeintCodex.MainFrame:Hide()
    else
        if WeintCodex.ResetToHome then
            WeintCodex.ResetToHome()
        end
        WeintCodex.MainFrame:Show()
    end
end

--------------------------------------------------
-- Laden
--------------------------------------------------

local function OnEvent(self, event, addonName)

    if event == "PLAYER_LOGIN" then

        -- Meldet den eingeloggten Charakter an die Companion, damit der
        -- Bot den echten WoW-Namen statt des Discord-Namens fuers
        -- Kalender-Invite kennt (siehe modules/companion.lua).
        if WeintCodex.Companion and WeintCodex.Companion.ReportCharacter then
            WeintCodex.Companion.ReportCharacter()
        end

        -- Und getrennt davon: WER von diesen Charakteren gerade spielt.
        -- Die obige Meldung ist die ganze Twinkliste ohne Kennzeichnung -
        -- die Companion koennte daraus nicht ablesen, wer angemeldet ist,
        -- und muesste die Frage raten. Diese Nachricht bleibt auf dem
        -- Rechner des Spielers.
        if WeintCodex.Companion and WeintCodex.Companion.ReportLoggedInCharacter then
            WeintCodex.Companion.ReportLoggedInCharacter()
        end

        -- Bereits importierte Rosterdaten erneut aufloesen: UnitClass und
        -- UnitName sind bei ADDON_LOADED (dem Zeitpunkt des urspruenglichen
        -- Imports ueber ProcessInbox) noch nicht zuverlaessig verfuegbar.
        if WeintCodex.Signup and WeintCodex.Signup.ResolveNames and WeintCodex.SavedData then
            WeintCodex.Signup.ResolveNames(WeintCodex.SavedData.raidWednesday)
            WeintCodex.Signup.ResolveNames(WeintCodex.SavedData.raidThursday)
        end

        -- Erststart-Tour bzw. Update-Changelog (core/onboarding.lua).
        if WeintCodex.Onboarding and WeintCodex.Onboarding.Check then
            WeintCodex.Onboarding.Check()
        end

        return
    end

    if addonName ~= "WeintCodex" then return end

    ------------------------------------------------------
    -- SavedVariables
    ------------------------------------------------------
    -- WICHTIG: hier wird ausschliesslich in WeintCodex_SavedData
    -- geschrieben, niemals in eine frisch angelegte Ersatztabelle. WoW
    -- speichert nur, was in der .toc unter SavedVariables steht; eine
    -- Ersatztabelle verlaere die Daten beim Abmelden, ohne dass
    -- irgendetwas fehlschlaegt.
    ------------------------------------------------------

    if not WeintCodex_SavedData then
        WeintCodex_SavedData = {
            raidData          = {},
            materialData      = {},
            twinks            = {},
            encounterProgress = {},

            window = {
                scale  = 1.0,
                width  = 1500,
                height = 800,
            },

            minimap = {
                angle = 225,
                hide  = false,
            },
        }
    end

    WeintCodex_SavedData.window =
        WeintCodex_SavedData.window or { scale = 1.0, width = 1500, height = 800 }
    WeintCodex_SavedData.window.width  = WeintCodex_SavedData.window.width  or 1500
    WeintCodex_SavedData.window.height = WeintCodex_SavedData.window.height or 800

    -- Ausdruecklich `== nil` und nicht `or`: sonst liesse sich escClose
    -- nie abschalten.
    if WeintCodex_SavedData.window.escClose == nil then
        WeintCodex_SavedData.window.escClose = true
    end
    if WeintCodex_SavedData.window.topmost == nil then
        WeintCodex_SavedData.window.topmost = false
    end

    -- Die Navigationsspalte und der Detailbereich brauchen Breite. Eine
    -- zu klein gespeicherte Groesse einmalig anheben.
    if WeintCodex_SavedData.window.width < 1180 then
        WeintCodex_SavedData.window.width = 1500
    end
    if WeintCodex_SavedData.window.height < 780 then
        WeintCodex_SavedData.window.height = 800
    end

    WeintCodex_SavedData.twinks            = WeintCodex_SavedData.twinks or {}
    WeintCodex_SavedData.encounterProgress = WeintCodex_SavedData.encounterProgress or {}
    WeintCodex_SavedData.minimap           = WeintCodex_SavedData.minimap or {
        angle = 225,
        hide  = false,
    }

    WeintCodex.SavedData = WeintCodex_SavedData

    -- Zugriffsprofil bereitstellen, BEVOR die Inbox verarbeitet wird: die
    -- Herkunftspruefung der Nachrichten haengt daran (core/access.lua).
    if WeintCodex.Access and WeintCodex.Access.Init then
        WeintCodex.Access.Init()
    end

    -- Companion-Inbox verarbeiten (z. B. der automatisch abgerufene
    -- Raid-Roster-Export von einem verknuepften Raidlead).
    if WeintCodex.Companion and WeintCodex.Companion.ProcessInbox then
        WeintCodex.Companion.ProcessInbox()
    end

    -- Sperren aus dem Zugriffsprofil anwenden. Muss nach ProcessInbox
    -- laufen (das Profil kann in genau diesem Login angekommen sein) und
    -- vor ResetToHome, damit die Uebersicht nicht einmal mit Zahlen
    -- aufblitzt, die der Spieler nicht sehen darf.
    if WeintCodex.Access and WeintCodex.Access.Apply then
        WeintCodex.Access.Apply()
    end

    if WeintCodex.ApplySavedWindow then
        WeintCodex.ApplySavedWindow()
    end

    -- ESC-Verhalten und Fensterebene aus denselben SavedData (core/ui.lua).
    if WeintCodex.ApplyWindowBehaviour then
        WeintCodex.ApplyWindowBehaviour()
    end

    if WeintCodex.ResetToHome then
        WeintCodex.ResetToHome()
    end

    print("|cff7C6CFF[WeintCodex]|r |cff34C77Bv" .. WeintCodex.Version
        .. "|r geladen. |cff8A8A98/wc zum Öffnen, /wc einstellungen für die Optionen.|r")
end

--------------------------------------------------
-- Hat der Client beim letzten Neuladen gespeichert?
--------------------------------------------------
-- Der Forever-Beta-Client schreibt SavedVariables laut EllesmereUI nur
-- manchmal. Mit 6.0.0.1 gemeldet: "WeintCodex-Oberflaeche verwenden? Ja"
-- und neu laden - danach war die Antwort weg und die Frage kam wieder.
-- Ohne diese Pruefung sieht das aus wie ein Fehler des Addons.
--
-- Beim Abmelden bzw. Neuladen (PLAYER_LOGOUT kommt vor dem Schreiben)
-- steht die Uhrzeit in SavedData. Nach einem NEULADEN muss sie Sekunden
-- alt sein. Ist sie viel aelter, stammt die Datei aus einer frueheren
-- Sitzung: der Client hat nicht geschrieben. Fehlt sie ganz, weiss
-- niemand etwas (erste Sitzung mit dieser Fassung) - "unbekannt", nicht
-- "in Ordnung" und nicht "kaputt".

local SAVE_STALE_AFTER = 300   -- Sekunden; ein Neuladen dauert keine fuenf Minuten

local saveHealth = "unknown"   -- "ok" | "failed" | "unknown"
function WeintCodex.SaveHealth() return saveHealth end

local saveProbe = CreateFrame("Frame")
saveProbe:RegisterEvent("PLAYER_LOGOUT")
saveProbe:RegisterEvent("PLAYER_ENTERING_WORLD")
saveProbe:SetScript("OnEvent", function(_, event, isInitialLogin, isReloadingUi)
    local sd = WeintCodex.SavedData
    if not sd then return end
    if event == "PLAYER_LOGOUT" then
        sd.saveProbe = time()
        return
    end
    if not isReloadingUi then return end
    local stamp = sd.saveProbe
    if type(stamp) ~= "number" then
        saveHealth = "unknown"
    elseif time() - stamp > SAVE_STALE_AFTER then
        saveHealth = "failed"
        print("|cff7C6CFF[WeintCodex]|r |cffF0A63ADer Client hat die Einstellungen"
            .. " beim letzten Neuladen nicht gespeichert.|r Das ist ein bekannter"
            .. " Fehler der Forever-Beta, kein Fehler von WeintCodex – was du vor"
            .. " dem Neuladen geändert hast, ist verloren.")
    else
        saveHealth = "ok"
    end
end)

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", OnEvent)
