--------------------------------------------------
-- WeintCodex :: Onboarding & Update-Changelog
-- Zeigt neuen Nutzern eine kurze Feature-Tour beim ersten Login und
-- informiert bestehende Nutzer nach einem Update per Popup ueber die
-- Aenderungen (data/changelog.lua). Beide Modi teilen sich dasselbe
-- Fenster - siehe EnsureFrame().
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.Onboarding = {}

local C          = WeintCodex.C
local SetSolidBg = WeintCodex.SetSolidBg
local DrawBorder = WeintCodex.DrawBorder

--------------------------------------------------
-- Fenstermasse
--
-- WINDOW_H ist die Grundhoehe (sie traegt jede Tourseite), WINDOW_H_MAX
-- die Grenze, ab der stattdessen gescrollt wird. Die Grenze liegt unter
-- der kleinsten zulaessigen Hoehe des Hauptfensters (780, siehe
-- core/ui.lua), damit das Popup auch dort vollstaendig darin liegt.
--
-- Warum ueberhaupt beides: der Changelog eines Updates ist beliebig lang.
-- Bisher war der Text ein fester FontString auf dem Fenster - was nicht
-- hineinpasste, wurde nicht abgeschnitten, sondern lief unten heraus und
-- war unerreichbar. Sichtbar wurde das erst bei einem Sammelupdate ueber
-- mehrere Versionen, also genau dann, wenn es am meisten zu lesen gibt.
--------------------------------------------------

local WINDOW_W, WINDOW_H = 520, 380
local WINDOW_H_MAX = 620

-- Der Textbereich sitzt zwischen Trennlinie (BODY_TOP unter der
-- Fensterkante) und Knopfzeile (BODY_BOTTOM ueber der Unterkante).
local BODY_TOP, BODY_BOTTOM, BODY_X = 130, 64, 28

local overlay, window
local iconStr, titleStr, stepStr, bodyStr
local bodyScroll, bodyInner
local buttonRow = {}
local currentStep = 1

--------------------------------------------------
-- DIE TOUR
--
-- Sie ist fuer Forever neu geschrieben. Die Tour der MoP-Fassung sprach zur
-- Haelfte von Dingen, die es hier nicht gibt (Sockel, Umschmieden, Simmen,
-- WeakAuras, Rotationshelfer) - wer sie gesehen haette, kennte danach ein
-- Addon, das es so nicht gibt. Und sie sagte nichts ueber das, was diese
-- Fassung ausmacht: dass ein leeres Feld hier nicht "nichts" heisst,
-- sondern "noch nicht bekannt".
--
-- Drei Regeln fuer jeden Text hier, und sie sind dieselben, nach denen
-- auch die Patchnotes geschrieben werden (siehe CLAUDE.md):
--
--   * Kein Dateiname, kein Funktionsname, kein SavedVariables-Schluessel.
--     Seitennamen und Slash-Befehle sind ausdruecklich erlaubt - sie sind
--     Bedienung, nicht Innenleben.
--   * Wirkung vor Ursache. Was bringt mir das, was sehe ich, was muss ich
--     tun. Warum es so gerechnet wird, steht auf der Seite selbst.
--   * Hervorgehoben (Akzentfarbe) wird nur, worauf man klicken oder was man
--     tippen kann. Eine Farbe, die auch Fliesstext trifft, sagt nichts mehr.
--
-- `chapter` gruppiert die Seiten; die Kopfzeile nennt Kapitel und Schritt.
-- `feature` laesst eine Seite aus, wenn das Zugriffsprofil den Bereich
-- nicht freigibt (siehe core/access.lua) - sonst bewirbt die Tour Bereiche,
-- die der Spieler gar nicht oeffnen kann.
--------------------------------------------------

-- Fassung der Tour. Wird sie neu geschrieben, steigt diese Zahl - und
-- alle bekommen die Einfuehrung noch einmal, auch wer das Addon seit
-- Jahren benutzt. Siehe Check() ganz unten.
local TOUR_EDITION = 1

-- ZWEI HERVORHEBUNGEN, ZWEI BEDEUTUNGEN.
--
-- A() ist die Akzentfarbe und heisst ausschliesslich: das kann man anklicken
-- oder tippen (Seiten, Reiter, Knoepfe, Slash-Befehle). E() ist Weiss und
-- betont einen Satz. Beides in einer Farbe zu fuehren waere das Ende
-- dieser Auskunft - eine Farbe, die auch Fliesstext trifft, sagt nichts
-- mehr darueber, worauf man zeigen kann.
local function A(text)
    return WeintCodex.ColorText("accent", text)
end

local function E(text)
    return WeintCodex.ColorText("textBright", text)
end

local ICON = "Interface\\Icons\\"

local TOUR_STEPS = {

    --------------------------------------------------
    -- ERSTE SCHRITTE
    --------------------------------------------------

    { chapter = "Erste Schritte", icon = ICON .. "INV_Misc_Book_09",
      title = "Willkommen bei WeintCodex",
      body =
        "WeintCodex ist das Addon der Gilde für " .. E("World of Warcraft: Forever")
        .. ": Schlachtzüge, Raidplanung, deine Charaktere, der Gruppencheck "
        .. "vor dem Pull und die Gildenmaterialien — an einem Ort.\n\n"
        .. "Diese Einführung dauert ein paar Minuten. Du kannst sie jederzeit "
        .. "abbrechen und später mit " .. A("/wc tour") .. " erneut aufrufen — "
        .. "es geht dabei nichts verloren.\n\n"
        .. "Das Fenster öffnest und schließt du mit " .. A("/wc") .. " oder "
        .. A("/weintcodex") .. ", oder mit einem Klick auf das Symbol an "
        .. "deiner Minikarte." },

    { chapter = "Erste Schritte", icon = ICON .. "INV_Misc_Map_01",
      title = "So ist das Fenster aufgebaut",
      body =
        "Links steht die Navigationsspalte, in vier Gruppen: " .. A("Raid")
        .. " (Übersicht, Schlachtzüge, Dungeons, Anmeldung, Kalender, "
        .. "Gruppencheck), "
        .. A("Charakter") .. ", " .. A("Gilde") .. " (Materialien, Import) "
        .. "und " .. A("System") .. " (Companion, Einstellungen).\n\n"
        .. "In der Mitte steht die Seite. Rechts erscheint ein schmales Feld, "
        .. "sobald es zur Seite etwas zu sagen gibt — die Begründung zu dem, "
        .. "was links steht. Wenn dich etwas wundert, steht die Antwort "
        .. "meistens dort.\n\n"
        .. "Oben in der Titelleiste sitzt die Suche — mit " .. A("Strg+K")
        .. " auch ohne Mausklick." },

    { chapter = "Erste Schritte", icon = ICON .. "INV_Misc_Key_03",
      title = "Instanzen: Dungeons und Schlachtzüge",
      body =
        "Unter " .. A("Dungeons") .. " stehen die neun Instanzen von Forever, "
        .. "mit Gebiet und Stufenbereich — von " .. E("Hall of Thanes")
        .. " unter Eisenschmiede bis zu " .. E("Shaper's Terrace")
        .. " im Krater von Un'Goro. Ob deine Stufe passt, steht rechts "
        .. "daneben.\n\n"
        .. "Unter " .. A("Schlachtzüge") .. " stehen die drei großen: Barrow "
        .. "Deeps, Hyjal Summit und Onyxias Hort. Trägst du diese Woche schon "
        .. "eine gespeicherte ID, steht das ganz oben.\n\n"
        .. "Zu jeder Instanz gibt es eine " .. A("Aufstellung") .. ": wie "
        .. "viele Plätze Tank, Heiler und Schaden haben und welche "
        .. "Talentbäume sie tragen können. Ein Klick auf einen Boss zeigt, "
        .. "was für deine Rolle an ihm zu beachten ist — sofern der Bot dazu "
        .. "etwas geliefert hat." },

    { chapter = "Erste Schritte", icon = ICON .. "INV_Misc_PocketWatch_01",
      title = "Was WeintCodex noch nicht weiß",
      body =
        E("Die Bosslisten stehen noch nicht fest.") .. " "
        .. "Bei Barrow Deeps und Hyjal Summit siehst du Bosse — die stammen "
        .. "aus den Dateien der Beta und sind von Blizzard nicht bestätigt. "
        .. "Deshalb steht überall " .. E("\"vorläufig\"") .. " dabei, wo sie "
        .. "auftauchen. Namen und Reihenfolge können sich bis zum Erscheinen "
        .. "noch ändern.\n\n"
        .. "Bei " .. A("Onyxias Hort") .. " und bei den Dungeons steht "
        .. "\"noch nicht bekannt\" — dazu liegt nichts vor, auch nicht "
        .. "vorläufig. Das ist kein Fehler und keine halbfertige Fassung: "
        .. "Listen aus einem anderen Spiel zu übernehmen hätte bedeutet, dir "
        .. "Bosse anzuzeigen, die es in deinem Spiel nicht gibt.\n\n"
        .. "Und was ein Tank oder ein Heiler an einem bestimmten Boss zu tun "
        .. "hat, weiß dieses Addon nur, wenn es jemand geschickt hat. "
        .. "Erfundene Taktik gibt es hier nicht.\n\n"
        .. "Aus demselben Grund gibt es in dieser Fassung " .. E("kein")
        .. " Simmen, keine WeakAuras, keine Sockelsteine und keine "
        .. "Verzauberungsempfehlungen. Sie hingen alle an Zahlen, die für "
        .. "dieses Spiel nichts aussagen." },

    --------------------------------------------------
    -- DER ABEND
    --------------------------------------------------

    { chapter = "Der Abend", icon = ICON .. "INV_Misc_Note_01",
      title = "Die Übersicht beantwortet den Abend",
      body =
        "Die Startseite ist kein zweites Menü. Sie beantwortet eine Frage: "
        .. E("was ist jetzt zu tun?") .. "\n\n"
        .. "Ganz oben steht der nächste Raid mit der Zahl der Anmeldungen. "
        .. "Darunter drei Spalten: was an deiner Ausrüstung offen ist, welche "
        .. "Schlachtzüge es gibt und ob du für einen davon schon eine "
        .. "gespeicherte ID trägst, und wie es um die Gildenbank steht.\n\n"
        .. "Ganz unten läuft eine Zeile mit dem Zustand der Brücke zu "
        .. A("WeintCompanion") .. ". Steht dort \"keine Lieferung\", ist das "
        .. "der Grund, wenn eine Seite leer bleibt." },

    { chapter = "Der Abend", icon = ICON .. "INV_Misc_GroupLooking",
      title = "Anmeldung und Kalender",
      body =
        "Unter " .. A("Anmeldung") .. " steht, wer sich für Mittwoch und "
        .. "Donnerstag eingetragen hat — mit Rolle, Klasse und Notiz. Die "
        .. "Liste kommt vom Discord-Bot, entweder über " .. A("WeintCompanion")
        .. " oder über einen String, den du unter " .. A("Import")
        .. " einfügst.\n\n"
        .. "Unter " .. A("Kalender") .. " steht der Termin selbst. Wer die "
        .. "Raidleitung hat, kann von dort aus die Ingame-Einladungen "
        .. "verschicken — WeintCodex gleicht dafür ab, welcher deiner "
        .. "Charaktere zur angemeldeten Klasse gehört.\n\n"
        .. "Welche das sind, entscheidest du unter " .. A("Charakter") .. "." },

    { chapter = "Der Abend", icon = ICON .. "INV_Shield_06",
      title = "Der Gruppencheck vor dem Pull",
      body =
        "Der " .. A("Gruppencheck") .. " sieht sich die Ausrüstung der ganzen "
        .. "Gruppe an: trägt jeder etwas auf jedem Platz, ist etwas "
        .. "zerbrochen, und wie weit liegen die Gegenstandsstufen "
        .. "auseinander?\n\n"
        .. E("Er bewertet nicht, er zählt.") .. " Ob eine Ausrüstung gut ist, "
        .. "sagt er nicht — dafür bräuchte es Zahlen, die für Forever niemand "
        .. "kennt. \"Platz leer\" ist unstrittig, alles darüber hinaus wäre "
        .. "ein Vorwurf.\n\n"
        .. "Wer zu weit weg oder offline ist, lässt sich nicht untersuchen. "
        .. "Solche Zeilen zählen als " .. E("ungeprüft") .. ", nicht als "
        .. "fehlerfrei — sonst wäre die Übersicht schlimmer als keine.\n\n"
        .. A("/wc gruppe") .. " öffnet ihn direkt, " .. A("/wc gruppe prüfen")
        .. " startet den Durchlauf." },

    --------------------------------------------------
    -- DEIN CHARAKTER
    --------------------------------------------------

    { chapter = "Dein Charakter", icon = ICON .. "INV_Misc_Armorkit_17",
      title = "Ausrüstung und Twinks",
      body =
        "Die Seite " .. A("Charakter") .. " zeigt links, was angelegt ist: je "
        .. "Platz der Gegenstand, seine Stufe und ob er zerbrochen ist. Ein "
        .. "Gedankenstrich heißt " .. E("unbekannt") .. " — der Client hat die "
        .. "Frage nicht beantwortet. Er heißt nie \"null\".\n\n"
        .. "Rechts steht jeder Charakter dieses Kontos, den WeintCodex gesehen "
        .. "hat. Jeder trägt sich beim Einloggen selbst ein. Mit dem Schalter "
        .. "entscheidest du, welche davon der Bot kennen soll — er braucht sie "
        .. "für die Kalender-Einladung.\n\n"
        .. "Ein abgewählter Charakter verschwindet nicht; er wird nur nicht "
        .. "mehr gemeldet." },

    --------------------------------------------------
    -- DIE GILDE
    --------------------------------------------------

    { chapter = "Die Gilde", icon = ICON .. "INV_Crate_01",
      title = "Materialien und Import",
      feature = "materials.view",
      body =
        "Unter " .. A("Materialien") .. " steht, was in der Gildenbank liegt. "
        .. "Öffne die Gildenbank einmal, und WeintCodex nimmt auf, was es "
        .. "sieht.\n\n"
        .. E("Sollbestände sind noch keine hinterlegt.") .. " Welche "
        .. "Verbrauchsgüter Forever kennt und wie viele ein Raid braucht, ist "
        .. "nicht veröffentlicht — ein Posten ohne Soll bekommt deshalb keinen "
        .. "Statuspunkt und keinen Balken.\n\n"
        .. "Unter " .. A("Import") .. " fügst du ein, was der Discord-Bot "
        .. "ausgibt: Anmeldungen, Materialien, Bossnotizen. Mehrere Zeilen "
        .. "dürfen zusammen hinein." },

    --------------------------------------------------
    -- SYSTEM
    --------------------------------------------------

    { chapter = "System", icon = ICON .. "INV_Misc_Gear_01",
      title = "Companion und Discord-Bot",
      body =
        "WeintCodex arbeitet mit zwei Programmen zusammen.\n\n"
        .. A("WeintCompanion") .. " ist die Desktop-App. Sie installiert und "
        .. "aktualisiert dieses Addon, legt vor jedem Update eine Sicherung an "
        .. "und schiebt die Daten zwischen Addon und Discord hin und her.\n\n"
        .. "Der " .. A("WeintCodex Bot") .. " läuft auf Discord. Mit ihm "
        .. "meldest du dich zum Raid an; seine Exportbefehle erzeugen die "
        .. "Strings für " .. A("Import") .. ".\n\n"
        .. E("Das Addon selbst geht nie ins Netz.") .. " Alles kommt über eine "
        .. "Datei im Spielordner oder über einen eingefügten Text. Die Seite "
        .. A("Companion") .. " zeigt dir, was zuletzt ankam." },

    { chapter = "System", icon = ICON .. "INV_Misc_Key_03",
      title = "Warum manches gesperrt ist",
      body =
        "Manche Bereiche zeigen \"für dich gesperrt\". Das hängt an deiner "
        .. "Discord-Rolle: WeintCompanion stellt dem Addon beim Verknüpfen ein "
        .. "Profil zu, und dieses Profil entscheidet, welche gildeninternen "
        .. "Daten du siehst.\n\n"
        .. E("Das ist Datenhygiene, keine Verschwiegenheit.") .. " Es sorgt "
        .. "dafür, dass ein Client die Daten genau einer Gilde führt und "
        .. "niemand eine Seite voller Zahlen sieht, die ihn nichts angehen.\n\n"
        .. A("/wc access") .. " zeigt dir dein Profil mit jeder einzelnen "
        .. "Freigabe." },

    { chapter = "System", icon = ICON .. "INV_Misc_Note_02",
      title = "Alles Weitere",
      body =
        "Unter " .. A("Einstellungen") .. " stellst du ein, wie sich das "
        .. "Fenster verhält: ob " .. A("Esc") .. " es schließt, ob es über "
        .. "anderen Fenstern liegt, wie groß es ist und ob das Symbol an der "
        .. "Minikarte steht.\n\n"
        .. "Dort findest du auch die " .. A("Diagnose") .. ": Ausgaben in den "
        .. "Chat, die zeigen, was der Client wirklich geantwortet hat. Wenn "
        .. "eine Zeile im Addon etwas Falsches behauptet, ist das die Ausgabe, "
        .. "die das klärt.\n\n"
        .. E("Und wenn dir etwas fehlt oder schieflaufen sollte, sag Bescheid.")
        .. " Ein gemeldeter Fehler mit einem Satz dazu, was du erwartet hast, "
        .. "ist meistens in einer Fassung erledigt.\n\n"
        .. "Viel Erfolg im Raid." },
}

--------------------------------------------------
-- Buttons
--------------------------------------------------

-- Nutzt die gemeinsame Schaltflaeche der neuen Sprache. Das Popup ist das
-- Erste, was nach einem Update zu sehen ist - es waere die falsche Stelle,
-- eine eigene Knopfform zu pflegen.
local function CreateButton(parent, text, width, onClick, kind)
    return WeintCodex.CreateButton(parent, {
        text = text, width = width, kind = kind or "primary",
        height = 32, backdrop = "surface2", onClick = onClick,
    })
end

local function ClearButtons()
    for _, b in ipairs(buttonRow) do
        b:Hide()
        b:SetParent(nil)
    end
    wipe(buttonRow)
end

local function AddButton(text, width, onClick, kind)
    local btn = CreateButton(window, text, width, onClick, kind)
    table.insert(buttonRow, btn)
    return btn
end

--------------------------------------------------
-- Schliessen: merkt sich die aktuelle Version, damit das Popup
-- nicht bei jedem Login erneut erscheint.
--------------------------------------------------

local closedListeners = {}

local function Dismiss()
    if overlay then overlay:Hide() end

    local sd = WeintCodex.SavedData
    if sd then
        sd.onboarding = sd.onboarding or {}
        sd.onboarding.lastSeenVersion = WeintCodex.Version
    end

    -- Wer nach der Einfuehrung etwas fragen will (die optionale
    -- Oberflaeche, ui/welcome.lua), fragt danach - nicht darueber.
    for _, fn in ipairs(closedListeners) do pcall(fn) end
end

-- Steht die Einfuehrung oder das Changelog-Popup gerade sichtbar da?
-- IsVisible und nicht IsShown: das Popup liegt im Hauptfenster, und wird
-- das geschlossen, ist das Popup weg, ohne selbst versteckt zu sein.
function WeintCodex.Onboarding.IsShowing()
    return overlay ~= nil and overlay:IsVisible() and true or false
end

function WeintCodex.Onboarding.OnClosed(fn)
    closedListeners[#closedListeners + 1] = fn
end

-- Das Popup schliessen, als haette der Spieler es weggeklickt.
WeintCodex.Onboarding.Dismiss = Dismiss

--------------------------------------------------
-- Gemeinsames Fenster fuer Tour und Changelog-Popup
--------------------------------------------------

local function EnsureFrame()
    if overlay then return end

    local parent = WeintCodex.MainFrame
    if not parent then return end

    overlay = CreateFrame("Frame", nil, parent)
    overlay:SetAllPoints(parent)
    overlay:SetFrameLevel(parent:GetFrameLevel() + 100)
    overlay:EnableMouse(true)
    SetSolidBg(overlay, 0, 0, 0, 0.75)
    overlay:Hide()

    window = CreateFrame("Frame", nil, overlay)
    window:SetSize(WINDOW_W, WINDOW_H)
    window:SetPoint("CENTER")
    SetSolidBg(window, C.surface2[1], C.surface2[2], C.surface2[3], 1.0)
    DrawBorder(window, C.borderStrong[1], C.borderStrong[2], C.borderStrong[3], 1.0, 1)
    -- Bernstein nur als Oberkante, wie an jeder Karte der neuen Sprache -
    -- ein umlaufender Akzentrahmen ist die alte Ornamentik.
    local topEdge = window:CreateTexture(nil, "ARTWORK")
    topEdge:SetHeight(1)
    topEdge:SetPoint("TOPLEFT",  window, "TOPLEFT",   8, 0)
    topEdge:SetPoint("TOPRIGHT", window, "TOPRIGHT", -8, 0)
    topEdge:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.34)
    WeintCodex.CutCorners(window, 14, "bgDark")

    local closeBtn = CreateFrame("Button", nil, window)
    closeBtn:SetSize(22, 22)
    closeBtn:SetPoint("TOPRIGHT", window, "TOPRIGHT", -10, -10)
    local closeX = closeBtn:CreateFontString(nil, "OVERLAY")
    closeX:SetAllPoints(closeBtn)
    closeX:SetFont(WeintCodex.Fonts.sansSemi, 15, "")
    closeX:SetText(WeintCodex.ColorText("textMuted", "\195\151"))
    closeBtn:SetScript("OnClick", Dismiss)

    iconStr = window:CreateFontString(nil, "OVERLAY")
    iconStr:SetPoint("TOP", window, "TOP", 0, -22)
    iconStr:SetFont(WeintCodex.Fonts.sansSemi, 30, "")

    titleStr = window:CreateFontString(nil, "OVERLAY")
    titleStr:SetPoint("TOP", iconStr, "BOTTOM", 0, -10)
    titleStr:SetFont(WeintCodex.Fonts.sansBold, 20, "")
    titleStr:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3])

    stepStr = window:CreateFontString(nil, "OVERLAY")
    stepStr:SetPoint("TOP", titleStr, "BOTTOM", 0, -6)
    stepStr:SetFont(WeintCodex.Fonts.mono, 10, "")

    local divider = window:CreateTexture(nil, "ARTWORK")
    divider:SetColorTexture(C.border[1], C.border[2], C.border[3], 1.0)
    divider:SetPoint("TOPLEFT", window, "TOPLEFT", 24, -112)
    divider:SetPoint("TOPRIGHT", window, "TOPRIGHT", -24, -112)
    divider:SetHeight(1)

    -- Der Text liegt in einem Bildlauffeld, nicht direkt auf dem Fenster.
    -- Die schlanke Leiste ist die Hausform (siehe CLAUDE.md), das Mausrad
    -- bringt WeintCodex.CreateScrollArea mit.
    bodyScroll, bodyInner = WeintCodex.CreateScrollArea(
        window, BODY_X, -BODY_TOP,
        WINDOW_W - 2 * BODY_X, WINDOW_H - BODY_TOP - BODY_BOTTOM, true)
    -- Zweiter Ankerpunkt: damit folgt die Hoehe des Feldes der des
    -- Fensters, das SetBody() an den Text anpasst.
    bodyScroll:SetPoint("BOTTOMLEFT", window, "BOTTOMLEFT", BODY_X, BODY_BOTTOM)
    -- Ohne dieses Flag blendet ScrollFrame_OnScrollRangeChanged die Leiste
    -- bei Bildlaufweite 0 wieder ein (nur ohne Griff) und wuerde damit das
    -- Ausblenden in SetBody() rueckgaengig machen.
    bodyScroll.scrollBarHideable = true

    bodyStr = bodyInner:CreateFontString(nil, "OVERLAY")
    bodyStr:SetPoint("TOPLEFT", bodyInner, "TOPLEFT", 0, 0)
    bodyStr:SetWidth(bodyInner:GetWidth())
    bodyStr:SetJustifyH("LEFT")
    bodyStr:SetJustifyV("TOP")
    bodyStr:SetFont(WeintCodex.Fonts.sans, 13, "")
    bodyStr:SetSpacing(4)
    bodyStr:SetTextColor(C.textNormal[1], C.textNormal[2], C.textNormal[3])
end

--------------------------------------------------
-- Text setzen und das Fenster darauf einstellen.
--
-- Reihenfolge ist hier tragend: erst der Text, dann seine gemessene Hoehe,
-- daraus die Fensterhoehe, und erst danach die Hoehe des Bildlaufinhalts -
-- die Sichtbarkeit der Leiste haengt von der Differenz beider ab.
--------------------------------------------------

local function SetBody(text)
    bodyStr:SetText(text or "")

    local needed  = math.ceil(bodyStr:GetStringHeight() or 0) + 8
    local height  = BODY_TOP + BODY_BOTTOM + needed
    if height < WINDOW_H     then height = WINDOW_H     end
    if height > WINDOW_H_MAX then height = WINDOW_H_MAX end
    window:SetHeight(height)

    local visible = height - BODY_TOP - BODY_BOTTOM
    bodyInner:SetHeight(needed > visible and needed or visible)

    bodyScroll:SetVerticalScroll(0)
    if bodyScroll.UpdateScrollChildRect then
        bodyScroll:UpdateScrollChildRect()
    end

    -- Eine Leiste ohne Bildlauf ist ein Bedienelement, das nichts tut.
    local bar = bodyScroll.WCScrollBar
    if bar then
        if needed > visible then bar:Show() else bar:Hide() end
    end
end

local function ShowFrame()
    local main = WeintCodex.MainFrame
    if main and not main:IsShown() then
        if WeintCodex.ResetToHome then WeintCodex.ResetToHome() end
        main:Show()
    end
    overlay:Show()
end

--------------------------------------------------
-- Tour (Erststart)
--------------------------------------------------

-- Tatsaechlich gezeigte Seiten. Die Konstante TOUR_STEPS bleibt unangetastet,
-- damit ein spaeter eintreffendes Zugriffsprofil die uebersprungenen Seiten
-- beim naechsten Aufruf wieder einblenden kann.
local visibleSteps = {}

local function BuildVisibleSteps()
    wipe(visibleSteps)

    for _, step in ipairs(TOUR_STEPS) do
        local allowed = true
        if step.feature and WeintCodex.Access and WeintCodex.Access.Can then
            allowed = WeintCodex.Access.Can(step.feature)
        end
        if allowed then
            visibleSteps[#visibleSteps + 1] = step
        end
    end
end

local function RenderTourStep()
    local step = visibleSteps[currentStep]
    if not step then return end

    iconStr:SetText(WeintCodex.Icon(step.icon, 30))
    titleStr:SetText(step.title)

    -- KAPITEL UND SCHRITT IN EINER ZEILE.
    -- Eine reine Schrittzahl beantwortet die Frage nicht, die man bei
    -- Seite 9 von 22 hat: wo bin ich, und wovon handelt das hier gerade.
    -- Das Kapitel steht deshalb davor - es ist die Gliederung, die die
    -- Tour ohnehin hat, und ohne sie ist sie eine lange Liste.
    stepStr:SetText(WeintCodex.ColorText("gold", step.chapter or "")
        .. WeintCodex.ColorText("textDim", "  ·  Schritt " .. currentStep
            .. " von " .. #visibleSteps))

    SetBody(step.body)

    ClearButtons()

    local isLast  = currentStep == #visibleSteps
    local nextBtn = AddButton(isLast and "Los geht's!" or "Weiter", 140, function()
        if currentStep < #visibleSteps then
            currentStep = currentStep + 1
            RenderTourStep()
        else
            Dismiss()
        end
    end)
    nextBtn:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", -20, 20)

    if currentStep > 1 then
        local backBtn = AddButton("Zurück", 100, function()
            currentStep = currentStep - 1
            RenderTourStep()
        end)
        backBtn:SetPoint("BOTTOMRIGHT", nextBtn, "BOTTOMLEFT", -10, 0)
    end

    -- EIN AUSGANG, DER VON ANFANG AN SICHTBAR IST.
    -- Die Tour ist mit 3.0.0.0 vollstaendig und damit lang. Wer sie nicht
    -- jetzt lesen will, darf nicht 22-mal auf "Weiter" klicken muessen -
    -- sonst klickt er einmal auf das Kreuz und findet nie wieder her.
    -- Deshalb steht daneben, wie man sie zurueckholt.
    if not isLast then
        local skipBtn = AddButton("Später (/wc tour)", 150, Dismiss, "ghost")
        skipBtn:SetPoint("BOTTOMLEFT", window, "BOTTOMLEFT", 16, 20)
    end
end

function WeintCodex.Onboarding.ShowTour()
    EnsureFrame()
    if not overlay then return end

    BuildVisibleSteps()
    if #visibleSteps == 0 then return end

    -- Gesehen ist gesehen: die Fassung wird beim Zeigen vermerkt und nicht
    -- erst beim Durchklicken bis zur letzten Seite. Wer nach drei Seiten
    -- genug hat, hat die Tour trotzdem bekommen - und bekaeme sie sonst bei
    -- jedem Anmelden erneut, was genau die Sorte Fenster ist, die man
    -- irgendwann ungelesen wegklickt.
    local sd = WeintCodex.SavedData
    if sd then
        sd.onboarding = sd.onboarding or {}
        sd.onboarding.tourEdition = TOUR_EDITION
    end

    currentStep = 1
    RenderTourStep()
    ShowFrame()
end

--------------------------------------------------
-- Update-Changelog-Popup
--------------------------------------------------

function WeintCodex.Onboarding.ShowChangelog(entries)
    if not entries or #entries == 0 then return end
    EnsureFrame()
    if not overlay then return end

    iconStr:SetText(WeintCodex.Icon("Interface\\Icons\\INV_Misc_Note_02", 30))
    titleStr:SetText("Was gibt's Neues?")

    if #entries == 1 then
        stepStr:SetText(WeintCodex.ColorText("textDim", "Version " .. entries[1].version .. " · " .. (entries[1].date or "")))
    else
        stepStr:SetText(WeintCodex.ColorText("textDim", #entries .. " Updates seit eurem letzten Login"))
    end

    local lines = {}
    for _, entry in ipairs(entries) do
        if #entries > 1 then
            table.insert(lines, WeintCodex.ColorText("textBright",
                "Version " .. entry.version .. (entry.date and (" (" .. entry.date .. ")") or "")))
        end
        for _, note in ipairs(entry.notes) do
            table.insert(lines, "• " .. note)
        end
        table.insert(lines, "")
    end
    SetBody(table.concat(lines, "\n"))

    ClearButtons()
    local okBtn = AddButton("Verstanden", 160, Dismiss)
    okBtn:SetPoint("BOTTOM", window, "BOTTOM", 0, 20)

    ShowFrame()
end

--------------------------------------------------
-- Sammelt alle Changelog-Eintraege, die neuer sind als die zuletzt
-- gesehene Version (WeintCodex_ChangelogData ist neueste-zuerst
-- sortiert - siehe data/changelog.lua).
--------------------------------------------------

local function CollectChangelogSince(lastVersion)
    local data = WeintCodex_ChangelogData
    if not data or #data == 0 then return nil end

    local collected, found = {}, false
    for _, entry in ipairs(data) do
        if entry.version == lastVersion then
            found = true
            break
        end
        table.insert(collected, entry)
    end

    -- lastVersion nicht in der Liste (z.B. mehrere uebersprungene
    -- Releases oder gekuerzte Historie) - sicherheitshalber alles zeigen.
    if not found then
        collected = data
    end

    if #collected == 0 then return nil end
    return collected
end

--------------------------------------------------
-- Wird einmal pro Login aus core/main.lua (PLAYER_LOGIN) aufgerufen.
--------------------------------------------------

function WeintCodex.Onboarding.Check()
    local sd = WeintCodex.SavedData
    if not sd then return end

    sd.onboarding = sd.onboarding or {}
    local last = sd.onboarding.lastSeenVersion

    -- NOCH NIE HIER GEWESEN - ODER DIE TOUR IST NEU GESCHRIEBEN WORDEN.
    --
    -- Der zweite Fall ist der Grund fuer TOUR_EDITION. Zwischen 1.0 und
    -- 2.10 ist ungefaehr die Haelfte dieses Addons dazugekommen, ohne dass
    -- die Einfuehrung je davon gesprochen haette: wer sie 2024 gesehen hat,
    -- kannte danach ein Addon, das es so nicht mehr gibt. Ein Changelog-
    -- Popup traegt das nicht - es beantwortet "was ist neu" und nicht
    -- "was gibt es hier eigentlich alles".
    --
    -- Die Fassungsnummer steht bewusst NEBEN lastSeenVersion und nicht
    -- darin: nicht jede Version schreibt die Tour um, und die meisten
    -- sollen weiterhin das kurze Popup zeigen.
    local seenEdition = tonumber(sd.onboarding.tourEdition) or 0

    if (not last) or seenEdition < TOUR_EDITION then
        WeintCodex.Onboarding.ShowTour()
        return
    end

    if last == WeintCodex.Version then
        return
    end

    local entries = CollectChangelogSince(last)
    if entries then
        WeintCodex.Onboarding.ShowChangelog(entries)
    else
        -- Version hat sich geaendert, aber keine passenden Changelog-
        -- Eintraege vorhanden - trotzdem als gesehen markieren.
        sd.onboarding.lastSeenVersion = WeintCodex.Version
    end
end
