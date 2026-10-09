--------------------------------------------------
-- WeintCodex :: Oberflaeche - Willkommen (der Assistent beim ersten Mal)
--------------------------------------------------
-- Beta-Test (6.9.0.0): "Ein Willkommensbildschirm, wo dem Nutzer alles
-- erklaert wird, ggf. auch mit kleinen Screenshots, wie es ungefaehr
-- aussieht, was der Vorteil waere, die UI zu nutzen. Wenn man sich gegen
-- das UI entscheidet, soll dennoch eine Abfrage kommen, ob man die
-- Komfortfunktionen haben moechte. Ein komplettes An-die-Hand-Nehmen."
--
-- SCHRITTE (bis 6.26.6.0 fuenf, seit 6.26.7.0 acht: statt "Helfer" je
-- Thema einer - Alltag, Kampf und Gruppe, Welt und Karte, Handel und
-- Gespraeche, siehe WL.GROUPS). Urspruenglich:
--   1 Willkommen   was WeintCodex ist, was jetzt gefragt wird
--   2 Oberflaeche  Bilder, Vorteile, "dein Profil bleibt deins" -> ja/nein
--   3 Anzeigen     Schadensanzeige, Erinnerungen, Questpfeil
--   4 Helfer       reparieren, Graues verkaufen, pluendern, Automark,
--                  Entfluchen (nur, wenn die Klasse es kann)
--   5 Bereit       Zusammenfassung -> "Uebernehmen" -> neu laden
-- Mit Oberflaeche sind die Anzeigen vorgewaehlt (das Komplettpaket), ohne
-- sie stehen sie, wie sie sind - abwaehlen und waehlen geht in beiden
-- Faellen.
--
-- NICHTS GESCHIEHT VOR "UEBERNEHMEN". Vor- und Zurueckblaettern, "Spaeter"
-- oder das Kreuz lassen alles, wie es war; wer abbricht, wird beim
-- naechsten Einloggen wieder gefragt. Erst "Uebernehmen" schaltet, und mit
-- Oberflaeche richtet es auch gleich das Layout ein (ui/setup.lua) - ein
-- Neuladen statt zwei.
--
-- DIE BILDER sind eigene Zeichnungen im Stil von WeintCodex, keine
-- Bildschirmfotos aus dem Spiel (Spielwelt und Symbole gehoeren Blizzard,
-- siehe CLAUDE.md). Quelle und Bau: .github/scripts/welcome/shots.html,
-- .github/scripts/make_welcome.py -> media/welcome/*.blp.
--
-- Wann: nach der Einfuehrung bzw. dem Changelog-Popup, nie darueber, nie
-- im Kampf, nie nach einem /reload (6.0.0.1: sonst die Frageschleife).
-- Wieder zeigen: /wcui willkommen.
--
-- Solange UIKit.OPT_IN (ui/kit.lua) false ist, fragt MaybeAsk nie - dann
-- ist die Oberflaeche fuer alle an.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIWelcome = {}

local WL = WeintCodex.UIWelcome
local K  = WeintCodex.UIKit
local C  = WeintCodex.Colors
local F  = WeintCodex.Fonts

WL.W, WL.H = 820, 580
WL.PAD = 28
WL.LOGO, WL.LOGO_GAP = 64, 14   -- Logo oben links (media/ui/logo_64)
WL.COL_W = 360                    -- linke Spalte: Text bzw. Schalter
WL.IMG_W, WL.IMG_H = 400, 200     -- rechte Spalte: Bild (Textur 512x256)
WL.TEXT_SIZE, WL.TEXT_SPACING = 13, 4
WL.BODY_TOP = 112                 -- Unterkante des Kopfes
WL.FOOT_H = 78                    -- Knopfzeile

local MEDIA = "Interface\\AddOns\\WeintCodex\\media\\welcome\\"

-- Die Bilder (Namen wie in make_welcome.py).
WL.SHOTS = {
    overview  = { file = MEDIA .. "overview",  caption = "Alles auf einen Blick – der Akzent trägt deine Klassenfarbe (hier: Magier)." },
    plates    = { file = MEDIA .. "plates",    caption = "Namensplaketten: Schadensspur, Zielleuchten, Zauberbalken, deine Auren." },
    group     = { file = MEDIA .. "group",     caption = "Gruppenrahmen mit HoTs, Schilden und Debuffs – Klickzauber direkt darauf." },
    windows   = { file = MEDIA .. "windows",   caption = "Die Fenster des Spiels ruhig, ohne Holz und Pergament." },
    damage    = { file = MEDIA .. "damage",    caption = "Schadensanzeige: wer wie viel macht – ein Klick schlüsselt auf." },
    reminders = { file = MEDIA .. "reminders", caption = "Erinnerungen vor dem Kampf, Procs und Abklingzeiten im Kampf." },
    arrow     = { file = MEDIA .. "arrow",     caption = "Questpfeil: Richtung, Entfernung, Ankunftszeit." },
    helpers   = { file = MEDIA .. "helpers",   caption = "Kleine Helfer melden sich kurz im Chat; Makros klickst du zusammen." },
}
WL.GALLERY = { "overview", "plates", "group", "windows" }

-- 6.26.7.0 (Beta-Test: "alle Komfortfunktionen aufgefuehrt, kurz
-- angesprochen, an- oder abwaehlbar"): statt eines Schritts "Helfer" je
-- Thema ein Schritt - dieselben Themen und dieselbe Reihenfolge wie die
-- Seiten unter Komfort (WL.GROUPS, ui/comfort.lua COMFORT_ORDER). Alles
-- dort geht auch ohne Oberflaeche; mit Oberflaeche ist alles vorgewaehlt
-- (das komplette Programm), ohne steht es, wie es ist.
WL.STEPS = { "start", "ui", "anzeigen", "alltag", "kampf", "welt", "handel", "bereit" }

WL.GROUPS = {
    { key = "alltag", eyebrow = "Komfort · Alltag", title = "Was dir unterwegs Klicks spart", shot = "helpers" },
    { key = "kampf",  eyebrow = "Komfort · Kampf und Gruppe", title = "Im Kampf und in der Gruppe", shot = "group" },
    { key = "welt",   eyebrow = "Komfort · Welt und Karte", title = "Auf der Karte und unterwegs", shot = "arrow" },
    { key = "handel", eyebrow = "Komfort · Handel und Gespräche", title = "Handeln und miteinander reden", shot = "helpers" },
}

-- Die Anzeigen (Module) und Helfer (Einstellungen) zum Waehlen.
WL.SHOWS = {
    { key = "damagemeter", shot = "damage", label = "Schadensanzeige",
      text = "Wer wie viel Schaden und Heilung macht – mit Aufschlüsselung per Klick." },
    { key = "reminders", shot = "reminders", label = "Erinnerungen",
      text = "Fehlender Buff, Waffe, Begleiter – vor dem Kampf. Dazu Procs und Abklingzeiten." },
    { key = "questarrow", shot = "arrow", label = "Questpfeil",
      text = "Zeigt zur gewählten Quest, mit Entfernung und Ankunftszeit." },
}
-- `keys`: ein Schalter fuer mehrere Einstellungen (an, wenn eine an ist).
WL.HELPERS = {
    -- Alltag
    { group = "alltag", module = "comfort", key = "autoRepair", label = "Automatisch reparieren",
      text = "Beim Händler, ohne Klick. Die Summe steht im Chat." },
    { group = "alltag", module = "comfort", key = "sellJunk", label = "Graue Gegenstände verkaufen",
      text = "Nur Qualität „Schlecht“ – nichts, was einen Wert hat." },
    { group = "alltag", module = "comfort", key = "fastLoot", label = "Schneller plündern",
      text = "Nimmt alles sofort, wenn automatisches Plündern an ist." },
    { group = "alltag", module = "comfort", key = "skipCinematics", label = "Filmsequenzen überspringen",
      text = "Zwischensequenzen enden von selbst." },
    { group = "alltag", module = "comfort", key = "levelUpPopup", label = "Neues beim Lehrer",
      text = "Nach dem Stufenaufstieg: was du jetzt lernen kannst." },
    { group = "alltag", module = "comfort", key = "durability", label = "Haltbarkeitswarnung",
      text = "Meldet sich, bevor deine Ausrüstung bricht." },
    { group = "alltag", module = "comfort", key = "mapCoords", label = "Koordinaten auf der Karte",
      text = "Deine Position und die des Mauszeigers." },
    -- Kampf und Gruppe
    { group = "kampf", module = "comfort", key = "fireAlarm", label = "Raus da!",
      text = "Ein Ton, sobald du in etwas stehst, das dir schadet." },
    { group = "kampf", module = "comfort", key = "autoMark", label = "Automark",
      text = "Als Gruppenleiter: ein Klick beim Betreten markiert Tank und Heiler." },
    { group = "kampf", module = "comfort", key = "markHover", label = "Markieren per Maus und Taste",
      text = "Maus über den Gegner, Taste drücken – nächste freie Markierung." },
    { group = "kampf", module = "groupframes", key = "clickDispel", label = "Entfluchen auf Klick", dispel = true, shot = "group",
      text = "Strg + Klick auf einen Gruppenrahmen entfernt, was deine Klasse entfernen kann." },
    { group = "kampf", module = "comfort", key = "combatAlert", label = "Kampfhinweis",
      text = "„+ Kampf“ und „− Kampf“ kurz in der Bildschirmmitte." },
    { group = "kampf", module = "comfort", key = "hideErrorsInCombat", label = "Fehlermeldungen im Kampf aus",
      text = "„Außer Reichweite“ und Co. – danach kommen sie wieder." },
    -- Welt und Karte
    { group = "welt", module = "comfort", key = "mapEntrances", label = "Instanzeingänge auf der Karte",
      text = "Ein Symbol an jedem Eingang, den der Codex kennt." },
    { group = "welt", module = "comfort", key = "mapMarks", keys = { "mapSpirit", "mapCrossings", "mapFlight", "mapTravel" },
      label = "Geistheiler, Wege, Flugmeister", text = "Dazu Schiffe, Zeppeline und Portale – Maus darauf: wohin." },
    { group = "welt", module = "comfort", key = "mapReveal", label = "Ganze Karte zeigen",
      text = "Auch Unerkundetes, etwas dunkler." },
    { group = "welt", module = "comfort", key = "mapZoneInfo", label = "Stufen und Sammelberufe",
      text = "Für welche Stufe ein Gebiet ist, Angeln, Kräuter, Erze." },
    { group = "welt", module = "comfort", key = "gatherSwap", label = "Kräuter und Erz im Wechsel",
      text = "Beide Suchen auf der Minikarte – außerhalb des Kampfes." },
    { group = "welt", module = "comfort", key = "rareAlert", label = "Seltene Gegner melden",
      text = "Ton und Hinweis, sobald ein seltener Gegner in der Nähe ist." },
    -- Handel und Gespraeche
    { group = "handel", module = "comfort", key = "ahPrices", label = "Auktionspreise",
      text = "Merkt sich Preise im Auktionshaus und zeigt sie im Tooltip." },
    { group = "handel", module = "comfort", key = "msgOn", label = "Flüstern als Messenger",
      text = "Jedes Gespräch in einem eigenen Fenster." },
    { group = "handel", module = "comfort", key = "dlgOn", label = "Gespräche im Codex-Stil",
      text = "Questgeber und Händler in einem ruhigen Fenster, mit Kamera." },
}

function WL.HelperGet(h)
    if h.keys then
        for _, k in ipairs(h.keys) do if K.Get(h.module, k) then return true end end
        return false
    end
    return K.Get(h.module, h.key) and true or false
end

function WL.HelperSet(h, v)
    for _, k in ipairs(h.keys or { h.key }) do
        if (K.Get(h.module, k) and true or false) ~= v then K.Set(h.module, k, v) end
    end
end

function WL.Offered(h) return not h.dispel or WL.CanDispel() end

-- Ist diese Sitzung ein /reload? Gesetzt beim ersten PLAYER_ENTERING_WORLD
-- (siehe unten). Steht hier oben, weil MaybeAsk sie liest.
local reloadSession = false

-- JE CHARAKTER (6.26.8.0, Beta-Test: "wenn ich einen neuen Charakter
-- erstelle, soll der Willkommensbildschirm kommen"). Bis 6.26.7.0 galt
-- die Antwort fuer den ganzen Account (`ui.asked`). Jetzt merkt sich
-- `ui.welcomed[Charakter]`, wer gefragt wurde; `ui.asked` bleibt als
-- "der Account hat schon einmal geantwortet". Beim ersten Einloggen nach
-- dem Update (WL.Migrate) gelten alle Charaktere, die WeintCodex schon
-- kennt (Bestand, Profilfrage), als gefragt - gefragt wird nur ein neuer.
local function Asked()
    local ui = K.Root()
    if ui == nil then return true end
    if ui.asked ~= true then return false end
    local key = K.CharKey()
    if not key or type(ui.welcomed) ~= "table" then return true end
    return ui.welcomed[key] == true
end
WL.Asked = Asked

local function MarkAsked()
    local ui = K.Root()
    if not ui then return end
    ui.asked = true
    local key = K.CharKey()
    if key then
        ui.welcomed = ui.welcomed or {}
        ui.welcomed[key] = true
    end
end

-- Einmal je Account: die Charaktere von vorher als gefragt eintragen.
-- Der Charakter, der gerade einloggt, zaehlt nur dazu, wenn WeintCodex ihn
-- schon kennt oder er ueber Stufe 1 ist - ein frischer Charakter wird gefragt.
function WL.Migrate()
    local ui = K.Root()
    if not ui or type(ui.welcomed) == "table" then return false end
    ui.welcomed = {}
    if ui.asked ~= true then return true end
    for key in pairs(ui.profileAsked or {}) do ui.welcomed[key] = true end
    for key in pairs(ui.profileOf or {}) do ui.welcomed[key] = true end
    local sd = WeintCodex.SavedData
    local inv = type(sd) == "table" and sd.inventory
    for _, c in pairs(inv and inv.chars or {}) do
        if type(c) == "table" and type(c.name) == "string" and type(c.realm) == "string" then
            ui.welcomed[c.name .. "-" .. c.realm] = true
        end
    end
    local key = K.CharKey()
    local lvl = _G.UnitLevel and K.Plain(_G.UnitLevel("player"))
    if key and type(lvl) == "number" and lvl > 1 then ui.welcomed[key] = true end
    return true
end

local function Say(text)
    print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " " .. text)
end

--------------------------------------------------
-- Die Wahl (erst "Uebernehmen" schreibt sie)
--------------------------------------------------

local choice = { ui = nil, shows = {}, helpers = {}, picked = nil }
WL.choice = choice

local function PlayerClass()
    if type(_G.UnitClass) ~= "function" then return nil end
    local ok, _, token = pcall(_G.UnitClass, "player")
    return ok and token or nil
end

-- Kann die Klasse entfluchen? (ui/dispel.lua kennt die Zauber je Klasse)
function WL.CanDispel()
    local DP = WeintCodex.UIDispel
    local class = PlayerClass()
    return DP ~= nil and class ~= nil and DP.SPELLS[class] ~= nil
end

-- Was eine Anzeige nach der Wahl "Oberflaeche ja/nein" waere: eine
-- ausdrueckliche Wahl von frueher gilt, sonst der Standard des Moduls -
-- "ui" heisst: mit Oberflaeche an (das Komplettpaket).
local function ShowDefault(key, ui)
    local prof = K.Profile()
    local st = prof and prof.modules[key]
    if st and st.enabled ~= nil then return st.enabled and true or false end
    local m = K.Module(key)
    if not m then return false end
    if m.defaultEnabled == "ui" then return ui and true or false end
    return m.defaultEnabled ~= false
end

-- Oberflaeche gewaehlt: die Anzeigen auf das passende Paket setzen (nur,
-- wenn sich die Wahl aendert - wer zurueckblaettert, behaelt seine Haken).
-- Mit Oberflaeche ist auch jeder Helfer vorgewaehlt (6.26.7.0: "die Nutzer
-- der Oberflaeche bekommen das komplette Programm"); ohne steht er, wie
-- er gespeichert ist.
function WL.Decide(ui)
    ui = ui and true or false
    if choice.picked ~= ui then
        for _, s in ipairs(WL.SHOWS) do choice.shows[s.key] = ShowDefault(s.key, ui) end
        for _, h in ipairs(WL.HELPERS) do
            choice.helpers[h.key] = ui or WL.HelperGet(h)
        end
        choice.picked = ui
    end
    choice.ui = ui
end

local function ResetChoice()
    choice.ui, choice.picked = nil, nil
    wipe(choice.shows)
    wipe(choice.helpers)
    for _, h in ipairs(WL.HELPERS) do
        choice.helpers[h.key] = WL.HelperGet(h)
    end
    -- Wer schon geantwortet hat (/wcui willkommen), sieht seinen Stand.
    if Asked() and K.OPT_IN then WL.Decide(K.UIEnabled()) end
end

-- Die Wahl in Worten (Schritt 5 und Prueflauf).
function WL.Summary()
    local lines = {}
    if choice.ui then
        lines[#lines + 1] = "•  Oberfläche: ja (dieser Charakter) – mit eigenem Layout „WeintCodex“. Dein Layout, deine Chatreiter"
            .. " und Einstellungen bleiben und kommen beim Ausschalten zurück."
    else
        lines[#lines + 1] = "•  Oberfläche: nein (dieser Charakter) – das Spiel zeigt seine Rahmen wie bisher."
    end
    local on = {}
    for _, s in ipairs(WL.SHOWS) do if choice.shows[s.key] then on[#on + 1] = s.label end end
    lines[#lines + 1] = "•  Anzeigen: " .. (#on > 0 and table.concat(on, ", ") or "keine")
    for _, g in ipairs(WL.GROUPS) do
        local help, all = {}, 0
        for _, h in ipairs(WL.HELPERS) do
            if h.group == g.key and WL.Offered(h) then
                all = all + 1
                if choice.helpers[h.key] then help[#help + 1] = h.label end
            end
        end
        local name = g.eyebrow:gsub("^Komfort · ", "")
        lines[#lines + 1] = "•  " .. name .. ": " .. (#help == 0 and "nichts"
            or #help == all and "alles" or table.concat(help, ", "))
    end
    return lines
end

-- Uebernehmen. Gibt einen Bericht zurueck: { layout = true|"Grund"|nil, reload = bool }.
function WL.Apply()
    local report = {}
    MarkAsked()
    local ui = choice.ui and true or false
    -- Zuerst der Hauptschalter: davon haengt ab, was "Standard" ist.
    K.SetUIEnabled(ui)
    for _, s in ipairs(WL.SHOWS) do
        local want = choice.shows[s.key] and true or false
        if K.ModuleEnabled(s.key) ~= want then K.SetModuleEnabled(s.key, want) end
    end
    local anyHelper = false
    for _, h in ipairs(WL.HELPERS) do
        if WL.Offered(h) then
            local want = choice.helpers[h.key] and true or false
            if WL.HelperGet(h) ~= want then WL.HelperSet(h, want) end
            if want and h.module == "comfort" then anyHelper = true end
        end
    end
    if anyHelper and not K.ModuleEnabled("comfort") then K.SetModuleEnabled("comfort", true) end
    -- Mit Oberflaeche gleich einrichten: ein Neuladen statt zwei.
    local ES = WeintCodex.UISetup
    if ui and ES and ES.HasLayout() == false then
        local ok, why = ES.Apply()
        report.layout = ok and true or tostring(why)
    end
    report.reload = K.ReloadPending()
    WL.report = report
    return report
end

--------------------------------------------------
-- Aufbau
--------------------------------------------------

local dimmer, win, eyebrow, title, body, closeBtn
local img, caption, thumbs, dots = nil, nil, {}, {}
local rowsHost, rows = nil, {}
local buttons, byKey = {}, {}
local step = "start"
local applied = false
local shown = "overview"

-- 6.26.9.4 (Beta-Test: "bei einem neuen Charakter MUSS nach dem Willkommen
-- die Frage nach dem Profil kommen"): beim Einloggen steht der Assistent
-- noch, die Profilfrage wartet - also fragt sie, sobald er schliesst.
-- Nicht vor "Jetzt neu laden": dann kommt sie nach dem Neuladen.
local function Close(reloading)
    if dimmer then dimmer:Hide() end
    local PR = WeintCodex.UIProfiles
    if not reloading and PR and PR.MaybeAsk and Asked() then PR.MaybeAsk() end
end
WL.Close = Close

local function Edge(frame)
    if K.Border then return K.Border(frame, 1, C.border[1], C.border[2], C.border[3], 1) end
    return nil
end

local function Thumb(parent, key, w, h)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(w, h)
    local t = b:CreateTexture(nil, "ARTWORK")
    t:SetAllPoints(b)
    t:SetTexture(WL.SHOTS[key].file)
    b.edge = Edge(b)
    b.key = key
    b:SetScript("OnClick", function() WL.ShowShot(key) end)
    return b
end

function WL.ShowShot(key)
    local s = WL.SHOTS[key]
    if not (s and img) then return end
    shown = key
    img:SetTexture(s.file)
    caption:SetText(s.caption)
    local hi = K.Highlight()
    for _, t in ipairs(thumbs) do
        if type(t.edge) == "table" and t.edge.SetColor then
            if t.key == key then t.edge:SetColor(hi[1], hi[2], hi[3], 1)
            else t.edge:SetColor(C.border[1], C.border[2], C.border[3], 1) end
        end
    end
end
function WL.ShownShot() return shown end

local function Build()
    if dimmer then return end

    dimmer = CreateFrame("Frame", "WeintCodexUIWelcome", UIParent)
    dimmer:SetAllPoints(UIParent)
    dimmer:SetFrameStrata("DIALOG")
    dimmer:EnableMouse(true)
    local shade = dimmer:CreateTexture(nil, "BACKGROUND")
    shade:SetAllPoints(dimmer)
    shade:SetColorTexture(0, 0, 0, 0.65)
    dimmer:Hide()

    win = CreateFrame("Frame", nil, dimmer)
    win:SetSize(WL.W, WL.H)
    win:SetPoint("CENTER", UIParent, "CENTER", 0, 20)
    win:SetFrameLevel(dimmer:GetFrameLevel() + 10)
    local bg = win:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(win)
    bg:SetColorTexture(unpack(C.surface2))
    WeintCodex.DrawBorder(win, C.borderStrong[1], C.borderStrong[2], C.borderStrong[3], 1, 1)
    local top = win:CreateTexture(nil, "ARTWORK")
    top:SetHeight(2)
    top:SetPoint("TOPLEFT", win, "TOPLEFT", 8, 0)
    top:SetPoint("TOPRIGHT", win, "TOPRIGHT", -8, 0)
    top:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.5)

    -- Das Logo der Oberflaeche (6.9.0.2) links neben Ueberschrift und Titel.
    WL.logo = win:CreateTexture(nil, "ARTWORK")
    WL.logo:SetSize(WL.LOGO, WL.LOGO)
    WL.logo:SetPoint("TOPLEFT", win, "TOPLEFT", WL.PAD - 4, -20)
    WL.logo:SetTexture(K.MEDIA .. "logo_64")

    eyebrow = K.NewText(win)
    eyebrow:SetFont(F.mono, 10, "")
    eyebrow:SetTextColor(unpack(C.accent))
    eyebrow:SetPoint("TOPLEFT", win, "TOPLEFT", WL.PAD + WL.LOGO + WL.LOGO_GAP - 4, -26)

    title = K.NewText(win)
    title:SetFont(F.display, 24, "")
    title:SetTextColor(unpack(C.textBright))
    title:SetPoint("TOPLEFT", eyebrow, "BOTTOMLEFT", 0, -10)
    title:SetWidth(WL.W - WL.PAD * 2 - 120 - WL.LOGO - WL.LOGO_GAP)
    title:SetJustifyH("LEFT")

    -- Fortschritt: ein Strich je Schritt oben rechts.
    for i = 1, #WL.STEPS do
        local d = win:CreateTexture(nil, "ARTWORK")
        d:SetSize(8, 4)
        d:SetPoint("TOPRIGHT", win, "TOPRIGHT", -WL.PAD - (#WL.STEPS - i) * 26 - 30, -30)
        dots[i] = d
    end

    closeBtn = CreateFrame("Button", nil, win)
    closeBtn:SetSize(22, 22)
    closeBtn:SetPoint("TOPRIGHT", win, "TOPRIGHT", -14, -14)
    local x = closeBtn:CreateTexture(nil, "ARTWORK")
    x:SetAllPoints(closeBtn)
    x:SetTexture(K.MEDIA .. "icon_close")
    x:SetVertexColor(unpack(C.textDim))
    closeBtn:SetScript("OnClick", function() WL.Later() end)
    WL.closeButton = closeBtn

    body = K.NewText(win)
    body:SetFont(F.sans, WL.TEXT_SIZE, "")
    body:SetTextColor(unpack(C.textNormal))
    body:SetPoint("TOPLEFT", win, "TOPLEFT", WL.PAD, -WL.BODY_TOP)
    body:SetWidth(WL.COL_W)
    body:SetJustifyH("LEFT")
    body:SetJustifyV("TOP")
    body:SetSpacing(WL.TEXT_SPACING)

    -- Rechte Spalte: Bild, Unterschrift, darunter (Schritt 2) die Galerie.
    local frame = CreateFrame("Frame", nil, win)
    frame:SetSize(WL.IMG_W, WL.IMG_H)
    frame:SetPoint("TOPRIGHT", win, "TOPRIGHT", -WL.PAD, -WL.BODY_TOP)
    img = frame:CreateTexture(nil, "ARTWORK")
    img:SetAllPoints(frame)
    Edge(frame)
    WL.imageFrame = frame

    caption = K.NewText(win)
    caption:SetFont(F.sans, 11, "")
    caption:SetTextColor(unpack(C.textDim))
    caption:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 0, -8)
    caption:SetWidth(WL.IMG_W)
    caption:SetJustifyH("LEFT")

    local tw = math.floor((WL.IMG_W - 3 * 8) / 4)
    for i, key in ipairs(WL.GALLERY) do
        local t = Thumb(win, key, tw, math.floor(tw / 2))
        t:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", (i - 1) * (tw + 8), -40)
        thumbs[i] = t
    end

    rowsHost = CreateFrame("Frame", nil, win)
    rowsHost:SetPoint("TOPLEFT", win, "TOPLEFT", WL.PAD, -WL.BODY_TOP)
    rowsHost:SetSize(WL.COL_W, WL.H - WL.BODY_TOP - WL.FOOT_H)

    -- ESC ist keine Antwort: kein UISpecialFrames. Das Kreuz heisst "Spaeter".
end

-- Ein Satz Knoepfe unten: links (Zurueck/Spaeter), rechts die Antworten.
-- Jeder Knopf wird EINMAL gebaut (WoW gibt Frames nie frei; der Neuladeknopf
-- bekommt seine Attribute nur ausserhalb des Kampfes).
local function SetButtons(left, right)
    for _, b in ipairs(buttons) do b:Hide() end
    wipe(buttons)
    local function make(d)
        local b = byKey[d.key]
        if not b then
            local function click() local x = byKey[d.key] if x and x._onClick then x._onClick() end end
            if d.reload then
                b = K.ReloadButton(win, { text = d.text, height = 36, size = 12, backdrop = "surface2", onClick = click })
            else
                b = WeintCodex.CreateButton(win, { text = d.text, kind = d.kind or "secondary", height = 36, size = 12,
                    backdrop = "surface2", onClick = click })
            end
            byKey[d.key] = b
        end
        b._onClick = d.onClick
        b._key = d.key
        b:ClearAllPoints()
        b:Show()
        buttons[#buttons + 1] = b
        return b
    end
    local anchor
    for _, d in ipairs(left or {}) do
        local b = make(d)
        if anchor then b:SetPoint("LEFT", anchor, "RIGHT", 10, 0)
        else b:SetPoint("BOTTOMLEFT", win, "BOTTOMLEFT", WL.PAD, 24) end
        anchor = b
    end
    anchor = nil
    for i = #(right or {}), 1, -1 do
        local b = make(right[i])
        if anchor then b:SetPoint("RIGHT", anchor, "LEFT", -10, 0)
        else b:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", -WL.PAD, 24) end
        anchor = b
    end
end

-- Schalterzeilen (Schritte 3 und 4). Je Eintrag eine Zeile, einmal gebaut.
local function Rows(list, kind)
    for _, r in pairs(rows) do r:Hide() end
    local y = 0
    for _, e in ipairs(list) do
        local id = kind .. ":" .. e.key
        local r = rows[id]
        if not r then
            r = WeintCodex.CreateToggle(rowsHost, {
                label = e.label, description = e.text, width = WL.COL_W,
                get = function()
                    if kind == "show" then return choice.shows[e.key] end
                    return choice.helpers[e.key]
                end,
                set = function(v)
                    if kind == "show" then choice.shows[e.key] = v and true or false
                    else choice.helpers[e.key] = v and true or false end
                end,
                onChange = function() if e.shot then WL.ShowShot(e.shot) end end,
            })
            r:HookScript("OnEnter", function() if e.shot then WL.ShowShot(e.shot) end end)
            rows[id] = r
        end
        r:ClearAllPoints()
        r:SetPoint("TOPLEFT", rowsHost, "TOPLEFT", 0, -y)
        r:Sync()
        r:Show()
        local ok, h = pcall(r.GetHeight, r)
        y = y + ((ok and type(h) == "number" and h > 0) and h or 46) + 6
    end
    return y
end

-- Fuer den Prueflauf: die Schalterzeile eines Eintrags.
function WL.Row(kind, key) return rows[kind .. ":" .. key] end

--------------------------------------------------
-- Die Schritte
--------------------------------------------------

local Go

local function Head(n, eb, t)
    eyebrow:SetText(WeintCodex.Spaced(WeintCodex.Upper(eb .. " · Schritt " .. n .. " von " .. #WL.STEPS)))
    title:SetText(t)
    local hi = K.Highlight()
    for i, d in ipairs(dots) do
        d:SetWidth(i == n and 18 or 8)
        if i <= n then d:SetColorTexture(hi[1], hi[2], hi[3], i == n and 1 or 0.45)
        else d:SetColorTexture(C.surface3[1], C.surface3[2], C.surface3[3], 1) end
    end
end

local function ShowGallery(on)
    for _, t in ipairs(thumbs) do t:SetShown(on) end
end

-- Die Texte der Schritte (fuer den Aufbau UND fuer die Platzpruefung im
-- Prueflauf - beide lesen dieselbe Quelle).
function WL.Text(key)
    if key == "start" then
        return "WeintCodex ist dein Begleiter für Forever: Dungeons und Schlachtzüge mit dem, was deine Rolle"
            .. " wissen muss, Hilfe beim Leveln, Lehrer, Gruppencheck und die Brücke zu Discord.\n\n"
            .. "Dazu bringt es zwei Pakete mit, die du jetzt in Ruhe wählst:\n"
            .. "•  die WeintCodex-Oberfläche – ein eigenes, ruhiges Interface,\n"
            .. "•  Komfort – Helfer, die es auch ohne die Oberfläche gibt.\n\n"
            .. "Nichts geschieht, bevor du am Ende „Übernehmen“ klickst. Alles lässt sich später mit /wcui"
            .. " ändern, und diesen Assistenten zeigt /wcui willkommen wieder."
    elseif key == "ui" then
        return "•  Plaketten, Rahmen, Leisten, Karte, Chat und Taschen in einem ruhigen Stil.\n"
            .. "•  Ziel und Gefahr springen ins Auge: Schadensspur, Zielleuchten, Zauberbalken.\n"
            .. "•  Gruppenrahmen mit HoTs, Schilden und bannbaren Debuffs – auch im Kampf.\n"
            .. "•  Außerhalb des Kampfes tritt alles zurück.\n"
            .. "•  Die Fenster des Spiels ohne Holz und Pergament.\n"
            .. "•  Dazu das Komplettpaket: Schadensanzeige und Erinnerungen sind gleich an.\n\n"
            .. "Dein Profil bleibt deins: Die Oberfläche bekommt im Bearbeitungsmodus ein eigenes Layout."
            .. " Dein jetziges, deine Chatreiter und deine Einstellungen werden nicht überschrieben –"
            .. " ausschalten bringt alles zurück. Die Wahl gilt nur für diesen Charakter."
    elseif key == "kampf" then
        return "Klickzauber und Makros richtest du später unter /wcui → Komfort ein."
    end
    return ""
end

local function StepStart()
    Head(1, "Willkommen", "Schön, dass du da bist.")
    body:SetText(WL.Text("start"))
    body:Show()
    rowsHost:Hide()
    ShowGallery(false)
    WL.ShowShot("overview")
    SetButtons({ { key = "later", text = "Später", onClick = function() WL.Later() end } },
        { { key = "next", text = "Los geht’s", kind = "primary", onClick = function() Go("ui") end } })
end

local function StepUI()
    Head(2, "Die Oberfläche", "Ein Interface aus einem Guss")
    body:SetText(WL.Text("ui"))
    body:Show()
    rowsHost:Hide()
    ShowGallery(true)
    WL.ShowShot("overview")
    SetButtons({ { key = "back", text = "Zurück", onClick = function() Go("start") end } },
        { { key = "no", text = "Ohne Oberfläche", onClick = function() WL.Decide(false) Go("anzeigen") end },
          { key = "yes", text = "Oberfläche verwenden", kind = "primary", onClick = function() WL.Decide(true) Go("anzeigen") end } })
end

local function StepShows()
    Head(3, "Komfort · Anzeigen",
        choice.ui and "Dein Komplettpaket: Anzeigen" or "Was darf WeintCodex dir zeigen?")
    body:Hide()
    rowsHost:Show()
    ShowGallery(false)
    WL.rowsHeight = Rows(WL.SHOWS, "show")
    WL.ShowShot("damage")
    SetButtons({ { key = "back", text = "Zurück", onClick = function() Go("ui") end } },
        { { key = "next", text = "Weiter", kind = "primary", onClick = function() Go(WL.STEPS[4]) end } })
end

local function StepIndex(key)
    for i, k in ipairs(WL.STEPS) do if k == key then return i end end
    return 1
end

-- Die Helfer eines Themas (nur, was die Klasse kann).
function WL.GroupList(key)
    local list = {}
    for _, h in ipairs(WL.HELPERS) do
        if h.group == key and WL.Offered(h) then list[#list + 1] = h end
    end
    return list
end

local function StepGroup(g)
    local n = StepIndex(g.key)
    Head(n, g.eyebrow, g.title)
    rowsHost:Show()
    ShowGallery(false)
    local y = Rows(WL.GroupList(g.key), "help")
    WL.rowsHeight = y
    local hint = WL.Text(g.key)
    if hint ~= "" then
        body:ClearAllPoints()
        body:SetPoint("TOPLEFT", win, "TOPLEFT", WL.PAD, -(WL.BODY_TOP + y + 6))
        body:SetText(hint)
        body:SetTextColor(unpack(C.textDim))
        body:Show()
    else
        body:Hide()
    end
    WL.ShowShot(g.shot)
    SetButtons({ { key = "back", text = "Zurück", onClick = function() Go(WL.STEPS[n - 1]) end } },
        { { key = "next", text = "Weiter", kind = "primary", onClick = function() Go(WL.STEPS[n + 1]) end } })
end

function WL.ReadyText()
    return table.concat(WL.Summary(), "\n")
        .. "\n\nNach „Übernehmen“ " .. (choice.ui and "richtet WeintCodex sein Layout ein; danach einmal neu laden."
            or "gilt das meiste sofort; Anzeigen kommen nach dem Neuladen.")
        .. "\n\nÄndern kannst du alles jederzeit mit /wcui oder unter Einstellungen → Oberfläche."
end

local function StepReady()
    Head(#WL.STEPS, "Zusammenfassung", "Bereit")
    rowsHost:Hide()
    ShowGallery(false)
    body:SetText(WL.ReadyText())
    body:Show()
    WL.ShowShot(choice.ui and "overview" or "helpers")
    SetButtons({ { key = "back", text = "Zurück", onClick = function() Go(WL.STEPS[#WL.STEPS - 1]) end } },
        { { key = "apply", text = "Übernehmen", kind = "primary", onClick = function() WL.Finish() end } })
end

-- Nach "Uebernehmen": was geschah, und das Neuladen.
local function StepDone(report)
    Head(#WL.STEPS, "Fertig", report.reload and "Fertig – jetzt neu laden" or "Fertig")
    local lines = {}
    if report.layout == true then
        lines[#lines + 1] = "•  Layout „WeintCodex“ im Bearbeitungsmodus angelegt und aktiv. Dein bisheriges ist gemerkt."
    elseif type(report.layout) == "string" then
        lines[#lines + 1] = "•  Das Layout ließ sich nicht anlegen (" .. report.layout
            .. "). Nach dem Neuladen fragt WeintCodex noch einmal."
    end
    for _, l in ipairs(WL.Summary()) do lines[#lines + 1] = l end
    lines[#lines + 1] = ""
    lines[#lines + 1] = report.reload
        and "Erst nach dem Neuladen steht alles an seinem Platz – bis dahin bitte nicht in den Kampf."
        or "Alles gilt ab sofort."
    body:SetText(table.concat(lines, "\n"))
    if report.reload then
        SetButtons(nil, { { key = "close", text = "Später", onClick = function()
                              Close()
                              Say("Deine Wahl gilt nach dem nächsten Neuladen (/reload).")
                          end },
                          { key = "reload", text = "Jetzt neu laden", reload = true, onClick = function() Close(true) end } })
    else
        SetButtons(nil, { { key = "done", text = "Schließen", kind = "primary", onClick = function() Close() end } })
    end
end

Go = function(key)
    step = key
    body:ClearAllPoints()
    body:SetPoint("TOPLEFT", win, "TOPLEFT", WL.PAD, -WL.BODY_TOP)
    body:SetTextColor(unpack(C.textNormal))
    if key == "start" then StepStart()
    elseif key == "ui" then StepUI()
    elseif key == "anzeigen" then StepShows()
    elseif key == "bereit" then StepReady()
    else
        for _, g in ipairs(WL.GROUPS) do
            if g.key == key then StepGroup(g) return end
        end
        StepReady()
    end
end

function WL.Step() return applied and "fertig" or step end

function WL.Finish()
    if K.InCombat() then
        Say("Nach dem Kampf – im Kampf lässt sich nichts umstellen.")
        return false
    end
    local report = WL.Apply()
    applied = true
    StepDone(report)
    return true
end

-- Abbrechen: nichts angefasst, beim naechsten Einloggen wieder gefragt.
function WL.Later()
    Close()
    if not applied and not Asked() then
        -- Gilt bis zum naechsten Einloggen - auch ueber ein /reload hinweg.
        local ui = K.Root()
        if ui then ui.later = true end
        Say("Kein Problem – beim nächsten Einloggen fragt WeintCodex wieder. Oder jetzt: /wcui willkommen.")
    end
end

--------------------------------------------------
-- Einstieg
--------------------------------------------------

-- Den Assistenten zeigen, egal ob schon gefragt (/wcui willkommen,
-- Prueflauf).
function WL.Ask()
    Build()
    applied = false
    ResetChoice()
    Go("start")
    dimmer:Show()
end

-- Fragen, wenn es noch nicht geschehen ist und gerade nichts anderes
-- davor steht.
function WL.MaybeAsk()
    if not K.OPT_IN then return end
    -- Seit 6.26.8.0 auch mit Oberflaeche: ein neuer Charakter waehlt
    -- seinen Komfort (Oberflaeche ja/nein gilt fuer den Account).
    if Asked() then return end
    if WL.ReloadBlocks() then return end   -- siehe unten: keine Schleife nach /reload
    local ui = K.Root()
    if ui and ui.later then return end     -- "Spaeter" gilt bis zum Einloggen
    if dimmer and dimmer:IsShown() then return end
    if WeintCodex.Onboarding and WeintCodex.Onboarding.IsShowing
       and WeintCodex.Onboarding.IsShowing() then
        return   -- kommt ueber OnClosed bzw. das Schliessen des Hauptfensters wieder
    end
    -- Nie mitten im Kampf: wer nach einem /reload kaempft, hat anderes zu tun.
    K.AfterCombat(function()
        if Asked() then return end
        WL.Ask()
    end)
end

-- Fuer den Prueflauf.
function WL.Button(key)
    for _, b in ipairs(buttons) do
        if b._key == key and b:IsShown() then return b end
    end
    return nil
end
function WL.IsShown() return dimmer ~= nil and dimmer:IsShown() end
function WL.BodyText() return body and body:GetText() or "" end
function WL.TitleText() return title and title:GetText() or "" end

if WeintCodex.Onboarding and WeintCodex.Onboarding.OnClosed then
    WeintCodex.Onboarding.OnClosed(function() WL.MaybeAsk() end)
end

-- NACH EINEM /reload WIRD NUR GEFRAGT, WENN DER CLIENT GESPEICHERT HAT.
--
-- Mit 6.0.0.1 gemeldet: "Ja, verwenden" -> "Jetzt neu laden" -> die
-- Frage kam wieder, immer wieder. Der Forever-Beta-Client hatte die
-- Antwort nicht gespeichert (siehe WeintCodex.SaveHealth in
-- core/main.lua). Speichern kann dieses Addon nicht erzwingen - aber die
-- Schleife darf es nicht bauen. Bis 6.9.0.0 hiess das: nach einem
-- /reload nie fragen. Beta-Test zu 6.9.0.0, geaendert in 6.9.0.1:
-- "6.9.0.0 geladen, /reload -
-- sollte nicht der Willkommensbildschirm kommen?" - wer das Addon
-- mitten in der Sitzung aktualisiert, laedt neu und sah ihn nie.
-- Jetzt: nach einem /reload fragen, wenn die Speicherpruefung "ok"
-- sagt (der Client hat beim Neuladen geschrieben - eine Antwort waere
-- also erhalten geblieben, eine Schleife gibt es nicht). Bei "verloren"
-- oder "unbekannt" wie bisher erst beim naechsten echten Einloggen.

function WL.IsReloadSession() return reloadSession end
function WL.ReloadBlocks()
    if not reloadSession then return false end
    local health = WeintCodex.SaveHealth and WeintCodex.SaveHealth() or "unknown"
    return health ~= "ok"
end

local hooked = false
local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:SetScript("OnEvent", function(_, _, isInitialLogin, isReloadingUi)
    -- Nur das erste PLAYER_ENTERING_WORLD einer Sitzung traegt eins der
    -- beiden Flags; Zonenwechsel tragen keins.
    if not (isInitialLogin or isReloadingUi) then return end
    reloadSession = isReloadingUi and true or false
    -- "Spaeter" endet mit dem Einloggen.
    if isInitialLogin then
        local ui = K.Root()
        if ui then ui.later = nil end
    end
    WL.Migrate()

    -- Schliesst jemand das Hauptfenster samt Popup, ohne das Popup selbst
    -- wegzuklicken, soll der Assistent trotzdem kommen.
    local main = WeintCodex.MainFrame
    if not hooked and main and main.HookScript then
        hooked = true
        main:HookScript("OnHide", function() WL.MaybeAsk() end)
    end

    -- Das Einfuehrungs-Popup wird beim Anmelden geoeffnet; einen
    -- Augenblick warten, damit es sicher steht, bevor gefragt wird.
    -- Immer verzoegert und erst DANN die Speicherpruefung lesen: sie
    -- entsteht im selben Ereignis (core/main.lua), die Reihenfolge der
    -- Empfaenger sagt das Spiel nicht zu.
    if _G.C_Timer and _G.C_Timer.After then
        _G.C_Timer.After(1.5, WL.MaybeAsk)
    end
end)
