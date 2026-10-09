--------------------------------------------------
-- WeintCodex :: Oberflaeche - Einstellungsfenster
--------------------------------------------------
-- Ein eigenes Fenster (/wcui), aufgebaut wie das der Vorlage
-- (EllesmereUI): links die Module in Gruppen, oben Titel, Beschreibung
-- und der Schalter des Moduls, darunter Reiter, dann die Einstellungen
-- in zwei Spalten, unten eine Fussleiste mit "Rahmen entsperren" und
-- "Neu laden".
--
-- WARUM EIN EIGENES FENSTER und keine Seite im Hauptfenster: wer an
-- Namensplaketten dreht, will die Spielwelt dabei sehen. Das Hauptfenster
-- ist 1500 px breit und deckt sie zu; dieses ist 1000 und laesst sich
-- verkleinern. Die Einstellungsseite des Hauptfensters fuehrt hierher
-- (modules/settings.lua, Ansicht "Oberflaeche").
--
-- AUSSEHEN. Nur Bausteine aus core/ui.lua - Schalter, Regler,
-- Auswahlliste, Farbfeld, Knopf, Reiterleiste, Bildlauf. Der Aufbau ist
-- der der Vorlage, die Sprache die von WeintCodex ("Graphit").
--
-- BILDLAUF. Die Regel "nichts muss scrollen" gilt fuer die Spalten des
-- Hauptfensters. Hier rollt genau eine Flaeche, die dafuer gebaut ist:
-- der Einstellungsbereich. Die Seitenleiste rollt nie - sie traegt vier
-- feste Eintraege und hat Platz fuer mehr als doppelt so viele.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIOptions = {}

local O = WeintCodex.UIOptions
local K = WeintCodex.UIKit
local C = WeintCodex.Colors
local F = WeintCodex.Fonts

local W, H     = 1000, 680
local SIDE_W   = 224
local LOGO     = 40         -- Logo vor "WeintCodex" (media/ui/logo_64)
-- Seitenleiste: seit 6.0.0.3 elf Eintraege. 38 hoch, 40 Schritt - der
-- Prueflauf haelt die belegte Hoehe gegen die Fensterhoehe (nichts in der
-- Seitenleiste darf rollen muessen).
-- 36/34 statt 40/38 seit 6.4.0.0: zwoelf Module (Erinnerungen) und
-- trotzdem Luft fuer eins mehr (load_test.lua).
local SIDE_ROW_H, SIDE_ROW_STEP = 34, 36
local HEAD_H   = 96
local TABS_H   = 38
local FOOT_H   = 58
local PAD      = 28
local GAP      = 32
local SCROLL_W = 10

local CONTENT_W = W - SIDE_W - PAD * 2 - SCROLL_W
local CELL_W    = math.floor((CONTENT_W - GAP) / 2)

O.CONTENT_W, O.CELL_W = CONTENT_W, CELL_W
O.HEIGHT = H

local GROUPS = {
    { key = "general", label = "Allgemein" },
    { key = "ui",      label = "Oberfläche" },
    { key = "qol",     label = "Komfort" },
}

--------------------------------------------------
-- Modul "Allgemein" (Hauptschalter, Schrift, Balken)
--------------------------------------------------


K.Register({
    key = "general", group = "general", order = 0,
    title = "WeintCodex-Oberfläche",
    -- Die Beschreibung haengt an UIKit.OPT_IN (ui/kit.lua): solange der
    -- Client keine Einstellungen speichert, ist die Oberflaeche fuer alle an.
    description = K.OPT_IN
        and "Ein eigenes, schlichtes Interface zu WeintCodex – freiwillig, mit eigenem Layout. Aus bleibt alles, wie das Spiel es zeigt; „Komfort“ geht trotzdem."
        or "Das Interface von WeintCodex: Plaketten, Rahmen, Leisten, Karte, Chat, Taschen und Schadensanzeige. Jedes Modul lässt sich einzeln abschalten.",
    defaults = (function()
        -- highlight: die Farbe der Oberflaeche - Klasse (Standard) oder
        -- Violett (6.6.2.4 nur Rahmen, seit 6.6.3.1 der ganze Akzent).
        local d = { font = "cond", outline = "thin", barStyle = "glanz", shadows = true, windowScale = 100,
                    highlight = "class", highlightColor = WeintCodex.VioletRGB(),
                    -- 6.10.0.0: Feineinstellungen jeder Seite zugeklappt (Builder:Advanced).
                    showAdvanced = false }
        -- Ruhe und Kampf (ui/presence.lua): dort definiert, hier gespeichert.
        for k, v in pairs(WeintCodex.UIPresence.DEFAULTS) do d[k] = v end
        -- Tooltip (ui/tooltip.lua): ebenso.
        for k, v in pairs(WeintCodex.UITooltip.DEFAULTS) do d[k] = v end
        -- Fenster des Spiels (ui/windows.lua): ebenso.
        for k, v in pairs(WeintCodex.UIWindows.DEFAULTS) do d[k] = v end
        return d
    end)(),
    OnSetting = function(key)
        -- Nur die Ansicht dieses Fensters - kein Modul muss neu zeichnen.
        if key == "showAdvanced" then return end
        if key == "barStyle" or key == "*" then K.RestyleBars() end
        if key == "shadows" or key == "*" then K.ApplyShadows() end
        if key == "windowScale" then
            if O.frame then O.frame:SetScale((K.Get("general", "windowScale") or 100) / 100) end
            return
        end
        -- Schrift und Balken gelten fuer alle Module.
        for _, k in ipairs(K.order) do
            local m = K.Module(k)
            if k ~= "general" and m.OnSetting and K.IsActive(k) then pcall(m.OnSetting, "*") end
        end
        local np = WeintCodex.UINameplates
        if np and np.RefreshPreview then pcall(np.RefreshPreview) end
    end,
    pages = {
        { key = "allgemein", label = "Allgemein", build = function(B)
            B:Section("Hauptschalter")
            local unlock = { type = "button", label = "Gestaltungsmodus",
                text = function() return K.IsUnlocked() and "Gestaltung beenden" or "Rahmen verschieben" end,
                onClick = function() K.SetUnlocked(not K.IsUnlocked()) end }
            local game = { type = "button", label = "Rahmen des Spiels", text = "Bearbeitungsmodus des Spiels",
                tooltip = WeintCodex.UIEditMode.GAME_TOOLTIP, gameEditMode = true }
            if K.OPT_IN then
                B:Row({ type = "toggle", label = "WeintCodex-Oberfläche verwenden",
                        description = "Plaketten, Rahmen, Leisten, Karte, Chat, Taschen und Fenster von WeintCodex statt der des Spiels. Wirkt nach dem Neuladen.",
                        get = function() return K.UIEnabled() end,
                        set = function(on) K.SetUIEnabled(on) end },
                      { type = "toggle", label = "Symbol an der Minikarte",
                        description = "Links: diese Einstellungen. Rechts: Rahmen verschieben. Nur mit Oberfläche.",
                        get = function() return WeintCodex.UILauncher.IsShown() end,
                        set = function(on) WeintCodex.UILauncher.SetShown(on) end,
                        disabled = function() return not K.UIEnabled() end })
                -- Beide Wege zum Verschieben nebeneinander: die Rahmen von
                -- WeintCodex und die des Spiels.
                B:Row(unlock, game)
                B:Row({ type = "button", label = "Willkommen", text = "Assistenten zeigen",
                        tooltip = "Der Rundgang vom ersten Mal: Oberfläche ja oder nein, Komfort wählen, übernehmen (/wcui willkommen).",
                        onClick = function() WeintCodex.UIWelcome.Ask() end },
                      { type = "empty" })
                B:Note("Eigenes Profil: Die Oberfläche bekommt im Bearbeitungsmodus ein eigenes Layout „WeintCodex“. Dein Layout, deine Chatreiter und deine Spieleinstellungen bleiben – schaltest du aus, ist dein Layout wieder aktiv, und was WeintCodex an Einstellungen geändert hat, steht wie vorher.")
                B:Note("Alles links unter „Komfort“ — Schadensanzeige, Questpfeil, Erinnerungen, Klickzauber, Makro-Helfer, Automark und die kleinen Helfer — hängt nicht an diesem Schalter. Schadensanzeige und Erinnerungen sind mit der Oberfläche von Haus aus an; ohne sie schaltest du sie selbst ein.")
            else
                B:Row(unlock, game)
                B:Note("Die WeintCodex-Oberfläche ist derzeit für alle eingeschaltet. Der Forever-Beta-Client speichert Addon-Einstellungen nicht über ein Neuladen hinweg – eine Wahl „an“ oder „aus“ wäre nach jedem /reload vergessen. Sobald der Client wieder speichert, kommt der Hauptschalter zurück.")
                B:Note("Einzelne Module schaltest du links ab (Schalter oben rechts). Auch das gilt, solange der Client nicht speichert, nur bis zum nächsten Neuladen.")
            end
            B:Section("Schrift und Balken",
                "Gilt für Namensplaketten, Einheitenrahmen und die Hinweise auf dem Bildschirm — nicht für das WeintCodex-Fenster.")
            B:Row({ type = "dropdown", label = "Schrift", key = "font", items = {
                        { value = "cond",     text = "IBM Plex Sans Condensed (WeintCodex)" },
                        { value = "plexsemi", text = "IBM Plex Sans, breit" },
                        { value = "plex",     text = "IBM Plex Sans, breit und leichter" },
                        { value = "barlow",   text = "Barlow Condensed, schmal und kantig" },
                        { value = "roboto",   text = "Roboto Condensed, schmal" },
                        { value = "fira",     text = "Fira Sans Condensed, schmal und weich" },
                        { value = "oswald",   text = "Oswald, hoch und kräftig" },
                        { value = "rajdhani", text = "Rajdhani, technisch" },
                        { value = "exo",      text = "Exo 2, futuristisch" },
                        { value = "inter",    text = "Inter, breit und klar" },
                        { value = "arialn",   text = "Arial Narrow (aus dem Spiel)" },
                        { value = "game",     text = "Schrift des Spiels" } } },
                  { type = "dropdown", label = "Kontur", key = "outline", items = {
                        { value = "none",  text = "Keine (mit Schatten)" },
                        { value = "thin",  text = "Dünn" },
                        { value = "thick", text = "Dick" } } })
            B:Row({ type = "dropdown", label = "Balken", key = "barStyle", items = {
                        { value = "glanz",    text = "Mit Glanz (WeintCodex)" },
                        { value = "flat",     text = "Flach" },
                        { value = "gradient", text = "Mit leichtem Verlauf" } } },
                  { type = "toggle", label = "Weiche Schatten", key = "shadows",
                    description = "Rahmen, Leisten und Fenster heben sich mit einem Schatten von der Spielwelt ab." })
            B:Row({ type = "dropdown", label = "Farbe der Oberfläche", key = "highlight", reload = true, items = {
                        { value = "class",  text = "In der Farbe deiner Klasse" },
                        { value = "accent", text = "WeintCodex-Lila" },
                        { value = "custom", text = "Eigene Farbe" } },
                    tooltip = "Die eine Farbe, die WeintCodex überall trägt: Fenster, Einstellungen, gewählte Reiter, Rahmen, Zielleuchten, Zauber- und Erfahrungsbalken, Überschriften, Texte. Grün, Rot, Gold und Blau bleiben – sie bedeuten etwas (fertig, Fehler, Warnung, Hinweis)." },
                  { type = "color", label = "Eigene Farbe", key = "highlightColor", reload = true,
                    disabled = function() return K.Get("general", "highlight") ~= "custom" end,
                    tooltip = "Gilt mit „Eigene Farbe“ nach dem Neuladen. Sehr dunkle Farben machen Text in dieser Farbe schwer lesbar." })
            B:Section("Testmodus",
                "Zeigt Ziel, Fokus, Gruppe, Zauberbalken und Schadensanzeige mit Beispielwerten – so siehst du alles auf einem Bildschirm, ohne Gruppe und ohne Kampf. Auch mit /wcui test.")
            B:Row({ type = "button", label = "Beispieldaten",
                    text = function() return WeintCodex.UITestMode.IsOn() and "Testmodus beenden" or "Testmodus starten" end,
                    onClick = function() WeintCodex.UITestMode.Toggle() end },
                  { type = "empty" })
            B:Section("Dieses Fenster")
            B:Row({ type = "slider", label = "Größe", key = "windowScale", min = 70, max = 130, step = 5,
                    format = function(v) return string.format("%d %%", v) end },
                  { type = "button", label = "Positionen", text = "Alle Positionen zurücksetzen",
                    onClick = function() K.ResetAllPositions() end })
        end },
        { key = "ruhe", label = "Ruhe und Kampf", build = function(B)
            local off = function() return not K.Get("general", "presence") end
            local function pct(v) return string.format("%d %%", v) end
            B:Section("Die Oberfläche tritt zurück",
                "Ohne Ziel, bei vollem Leben und außerhalb des Kampfes werden Rahmen und Leisten leiser. Ein Ziel, ein Treffer oder die Maus holen sie sofort zurück.")
            B:Row({ type = "toggle", label = "Ruhe außerhalb des Kampfes", key = "presence" },
                  { type = "slider", label = "Nachlauf", key = "presenceDelay", min = 0, max = 15, step = 1, disabled = off,
                    format = function(v) return string.format("%d s", v) end,
                    tooltip = "So lange bleibt nach dem Kampf alles sichtbar." })
            B:Section("Deckkraft in Ruhe")
            B:Row({ type = "slider", label = "Spielerrahmen", key = "fade_player", min = 0, max = 100, step = 5, format = pct, disabled = off },
                  { type = "slider", label = "Schadensanzeige", key = "fade_damage", min = 0, max = 100, step = 5, format = pct, disabled = off })
            B:Row({ type = "slider", label = "Aktionsleiste 1", key = "fade_mainbar", min = 0, max = 100, step = 5, format = pct, disabled = off },
                  { type = "slider", label = "Weitere Leisten", key = "fade_bars", min = 0, max = 100, step = 5, format = pct, disabled = off })
            B:Note("Ausgeblendete Leisten bleiben benutzbar: Tastenkürzel wirken immer, und die Maus zeigt sie wieder.")
        end },
        -- 6.11.0.4: Profile je Charakter (ui/profiles.lua).
        { key = "profile", label = "Profile", build = function(B) WeintCodex.UIProfiles.BuildPage(B) end },
        { key = "tooltip", label = "Tooltip & Fenster", build = function(B)
            local off = function() return not K.Get("general", "tooltipStyle") end
            B:Section("Tooltip", "Die Hinweisfenster des Spiels als Kachel statt mit dem Blizzard-Rahmen.")
            B:Row({ type = "toggle", label = "Tooltip im WeintCodex-Stil", key = "tooltipStyle", reload = true },
                  { type = "toggle", label = "Lebensbalken flach", key = "tooltipHealth", reload = true, disabled = off })
            B:Row({ type = "toggle", label = "Spielername in Klassenfarbe", key = "tooltipClassName", disabled = off },
                  { type = "toggle", label = "Rand in Klassen- und Qualitätsfarbe", key = "tooltipBorder", disabled = off,
                    description = "Spieler in ihrer Klassenfarbe, Gegenstände ab „selten“ in ihrer Qualität." })
            B:Section("Fenster", "Charakterfenster (C), Zauberbuch und Talente (P, N), Weltkarte und Questlog (M), Berufe, Gilde & Communitys, Suche nach Gruppe, Gespräche mit NPCs, Quests, Händler, Bücher, Beute, das Würfeln um Beute, Makros, Handel, Auktionshaus, Bank, Post, Kontakte, Lehrer und die Optionen des Spiels als Kachel statt Holz, Metall und Pergament.")
            B:Row({ type = "toggle", label = "Fenster im WeintCodex-Stil", key = "windowSkin", reload = true },
                  { type = "toggle", label = "Stimmung statt Schwarz", key = "windowArt", reload = true,
                    disabled = function() return not K.Get("general", "windowSkin") end,
                    description = "Schein in der Klassenfarbe oben im Fenster, die Landschaften hinter den Talentbäumen gedämpft statt weg, ein weicher Rand um das Modell im Charakterfenster." })
            B:Row({ type = "toggle", label = "Weltkarte im WeintCodex-Stil", key = "mapSkin", reload = true,
                    disabled = function() return not K.Get("general", "windowSkin") end,
                    description = "Rahmen, Pergament und Holz der Karte (M) weg – die Karte selbst bleibt, wie sie ist." },
                  { type = "empty" })
            B:Note("Was in einem Fenster noch nach Holz aussieht, nennt /wcui fenster – Maus über das Fenster halten und abschicken. Der Bericht kommt in einem Fenster zum Kopieren.")
            -- 6.10.4.0: Verschieben ist immer an - hier steht nur, wie es geht.
            B:Note("Fenster verschieben: mit der linken Maustaste an einer freien Stelle ziehen (Titel, Rand). Der Platz gilt, bis du das Fenster schließt – danach öffnet es wieder an seinem gewohnten Platz. Umschalt + Rechtsklick setzt ein offenes Fenster sofort zurück.")
            -- 6.10.2.0: die Selbstpruefung auch ohne Befehl.
            B:Section("Selbstprüfung", "Fragt den Client, was nur er beantworten kann: Bedrohung offen oder geheim, welche Messarten es gibt, ob das Mikromenü geschützt ist, welche Fenster es gibt. Ändert nichts. Auch mit /wcui prüfen.")
            B:Row({ type = "button", label = "Bericht zum Kopieren", text = "Selbstprüfung",
                    onClick = function()
                        K.ShowReport("Selbstprüfung", WeintCodex.UISelfCheck.Run())
                    end },
                  { type = "empty" })
        end },
    },
})

--------------------------------------------------
-- Zustand eines Moduls in Worten (Seitenleiste)
--------------------------------------------------

function O.ModuleStatus(key)
    local m = K.Module(key)
    if not m then return "", "textDim" end
    if key == "general" then
        if K.ReloadPending() then return "Neu laden nötig", "warning" end
        if not K.OPT_IN then return "an (derzeit immer)", "success" end
        return K.UIEnabled() and "an" or "aus", K.UIEnabled() and "success" or "textDim"
    end
    local wants, active = K.WantsActive(key), K.IsActive(key)
    if (m.group == "ui" or m.reload) and wants ~= active then
        return "nach dem Neuladen " .. (wants and "an" or "aus"), "warning"
    end
    if m.group == "ui" then
        if active then return "an", "success" end
        if not K.UIEnabled() then return "Oberfläche aus", "textFaint" end
        return "aus", "textDim"
    end
    return active and "an" or "aus", active and "success" or "textDim"
end

--------------------------------------------------
-- Der Seitenbauer
--------------------------------------------------
-- Eine Seite beschreibt sich als Folge von Abschnitten und Zeilen; der
-- Bauer setzt sie untereinander und merkt sich jedes Bedienelement, damit
-- es nach einer Aenderung seinen Zustand neu lesen kann (eine Einstellung
-- sperrt eine andere: "Randfarbe" ohne "Rand anzeigen").
--------------------------------------------------

local Builder = {}
Builder.__index = Builder

local function TextHeight(fs, minimum)
    local ok, h = pcall(fs.GetStringHeight, fs)
    if not ok or type(h) ~= "number" or h <= 0 then return minimum end
    return math.max(minimum, math.ceil(h))
end

local function NewBuilder(moduleKey, parent)
    return setmetatable({ mod = moduleKey, parent = parent, y = -4, widgets = {} }, Builder)
end

-- ERWEITERT (6.10.0.0, Selbsteinschaetzung: "rund 340 Schalter - kaum ein
-- Spieler stellt die Farbe fuer 'Tank verliert Aggro' um, aber jeder muss
-- daran vorbeiscrollen"). Was auf einer Seite nach B:Advanced() steht (bis
-- B:EndAdvanced() oder zum Ende der Seite), ist Feineinstellung: von Haus
-- aus zugeklappt, an seiner Stelle ein Knopf, der sagt, wie viele
-- Einstellungen dahinter liegen. Ein Klick blendet sie auf JEDER Seite ein
-- (general.showAdvanced) - wer Feinheiten sucht, sucht sie selten nur
-- einmal. Verloren geht nichts: die Werte gelten weiter, auch zugeklappt.
O.ADV_HIDE = "Erweiterte Einstellungen ausblenden"
function O.AdvancedText(count)
    if count == 1 then return "Erweitert: 1 Einstellung einblenden" end
    return string.format("Erweitert: %d Einstellungen einblenden", count)
end

function Builder:Advanced()
    local open = K.Get("general", "showAdvanced") and true or false
    if self.y < -4 then self.y = self.y - 8 end
    local b = WeintCodex.CreateButton(self.parent, {
        text = open and O.ADV_HIDE or O.AdvancedText(0), kind = "secondary", height = 24, size = 11,
        backdrop = "bgDark",
        onClick = function() O.SetAdvanced(not open) end,
    })
    b:SetPoint("TOPLEFT", self.parent, "TOPLEFT", 0, self.y)
    b._advanced = true
    self.y = self.y - 24 - 12
    self.zones = self.zones or {}
    local zone = { button = b, count = 0, open = open }
    self.zones[#self.zones + 1] = zone
    self.zone = zone
    self.skip = not open
end

function Builder:EndAdvanced()
    self.skip, self.zone = false, nil
end

-- Nach dem Bau: die Knoepfe nennen, wie viel hinter ihnen liegt.
function Builder:FinishAdvanced()
    for _, z in ipairs(self.zones or {}) do
        if not z.open then z.button:SetText(O.AdvancedText(z.count)) end
    end
end

function Builder:Section(title, note)
    if self.skip then return end
    if self.y < -4 then self.y = self.y - 14 end
    local eb = WeintCodex.Eyebrow(self.parent, title, { color = "accent", size = 10 })
    eb:SetPoint("TOPLEFT", self.parent, "TOPLEFT", 0, self.y)
    self.y = self.y - 18
    if note then
        local fs = K.NewText(self.parent)
        fs:SetFont(F.sans, 11, "")
        fs:SetPoint("TOPLEFT", self.parent, "TOPLEFT", 0, self.y)
        fs:SetWidth(CONTENT_W)
        fs:SetJustifyH("LEFT")
        fs:SetTextColor(unpack(C.textDim))
        fs:SetText(note)
        self.y = self.y - TextHeight(fs, 14) - 6
    end
    local line = self.parent:CreateTexture(nil, "ARTWORK")
    line:SetHeight(1)
    line:SetWidth(CONTENT_W)
    line:SetPoint("TOPLEFT", self.parent, "TOPLEFT", 0, self.y - 2)
    line:SetColorTexture(unpack(C.rowLine))
    self.y = self.y - 12
end

function Builder:Note(text)
    if self.skip then return end
    local fs = K.NewText(self.parent)
    fs:SetFont(F.sans, 11, "")
    fs:SetPoint("TOPLEFT", self.parent, "TOPLEFT", 0, self.y)
    fs:SetWidth(CONTENT_W)
    fs:SetJustifyH("LEFT")
    fs:SetTextColor(unpack(C.textDim))
    fs:SetText(text)
    self.y = self.y - TextHeight(fs, 14) - 10
end

-- Eine Zelle nach ihrer Beschreibung bauen. Liefert den Rahmen oder nil.
function Builder:Cell(spec)
    local mod, parent = self.mod, self.parent
    local key = spec.key
    local t = spec.type

    local get = spec.get or function()
        if t == "color" then return K.GetColor(mod, key) end
        return K.Get(mod, key)
    end
    local rawSet = spec.set or function(...)
        if t == "color" then
            local r, g, b = ...
            K.Set(mod, key, { r = r, g = g, b = b })
        else
            K.Set(mod, key, (...))
        end
    end
    local set = function(...)
        rawSet(...)
        if spec.reload then K.MarkReload() end
    end
    local disabled = spec.disabled

    local w
    if t == "toggle" then
        w = WeintCodex.CreateToggle(parent, {
            label = spec.label, description = spec.description, width = CELL_W,
            get = get, set = set, disabled = disabled, disabledHint = spec.disabledHint,
        })
    elseif t == "slider" then
        w = WeintCodex.CreateSlider(parent, {
            label = spec.label, min = spec.min, max = spec.max, step = spec.step,
            get = get, set = set, format = spec.format,
        })
        w:SetWidth(CELL_W)
        -- Der Regler aus core/ui.lua kennt keinen gesperrten Zustand.
        -- Statt ihn fuer eine Stelle umzubauen: gedimmt und taub.
        local sync = w.Sync
        w.Sync = function()
            sync()
            local off = disabled and disabled() and true or false
            w:SetAlpha(off and 0.35 or 1)
            if w._slider and w._slider.EnableMouse then w._slider:EnableMouse(not off) end
        end
        w.Sync()
    elseif t == "dropdown" then
        w = WeintCodex.CreateDropdown(parent, {
            label = spec.label, items = spec.items, width = CELL_W,
            get = get, set = set, disabled = disabled, disabledHint = spec.disabledHint,
            tooltip = spec.tooltip,
        })
    elseif t == "color" then
        w = WeintCodex.CreateColorSwatch(parent, {
            label = spec.label, width = CELL_W, get = get, set = set,
            disabled = disabled, tooltip = spec.tooltip,
        })
    elseif t == "button" then
        -- Ueberschrift wie bei Regler und Liste, der Knopf darunter: so
        -- steht er in derselben Linie wie seine Nachbarzelle.
        w = CreateFrame("Frame", nil, parent)
        w:SetSize(CELL_W, 52)
        local lbl = K.NewText(w)
        lbl:SetFont(F.sans, 13, "")
        lbl:SetPoint("TOPLEFT", w, "TOPLEFT", 0, -2)
        lbl:SetTextColor(unpack(C.textMuted))
        lbl:SetText(spec.label or "")
        local function label()
            return type(spec.text) == "function" and spec.text() or spec.text or spec.label
        end
        local b = WeintCodex.CreateButton(w, {
            text = label(), kind = spec.kind or "secondary", height = 26, size = 11,
            backdrop = "bgDark", tooltip = spec.tooltip,
            onClick = function() if spec.onClick then spec.onClick() end ; w.Sync() end,
        })
        b:SetPoint("BOTTOMLEFT", w, "BOTTOMLEFT", 0, 2)
        -- Hinueber in den Bearbeitungsmodus des Spiels (ui/editmode.lua).
        if spec.gameEditMode then
            WeintCodex.UIEditMode.AttachGame(b)
            w._gameEditMode = b
        end
        w.Sync = function() b:SetText(label()) end
    elseif t == "input" then
        -- Ein Eingabefeld (Erinnerungen: Zauber mit Namen oder ID).
        -- Uebernommen wird bei jeder Eingabe - kein Enter noetig.
        w = CreateFrame("Frame", nil, parent)
        w:SetSize(CELL_W, 52)
        local lbl = K.NewText(w)
        lbl:SetFont(F.sans, 13, "")
        lbl:SetPoint("TOPLEFT", w, "TOPLEFT", 0, -2)
        lbl:SetTextColor(unpack(C.textMuted))
        lbl:SetText(spec.label or "")
        local eb = CreateFrame("EditBox", nil, w)
        eb:SetSize(CELL_W, 26)
        eb:SetPoint("BOTTOMLEFT", w, "BOTTOMLEFT", 0, 2)
        eb:SetAutoFocus(false)
        if eb.SetTextInsets then eb:SetTextInsets(8, 8, 0, 0) end
        K.SetFont(eb, 12)
        local bg = eb:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(eb)
        bg:SetColorTexture(unpack(C.bgDark))
        K.Border(eb, 1, 0, 0, 0, 1, "BORDER")
        eb:SetScript("OnTextChanged", function(self, user)
            if user then rawSet(self:GetText()) end
        end)
        eb:SetScript("OnEnterPressed", function(self) set(self:GetText()) self:ClearFocus() end)
        eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        w._edit = eb
        w.Sync = function()
            if not (eb.HasFocus and eb:HasFocus()) then eb:SetText(get() or "") end
            local off = disabled and disabled() and true or false
            w:SetAlpha(off and 0.35 or 1)
            eb:EnableMouse(not off)
        end
        w.Sync()
    elseif t == "custom" then
        -- Frei gebaut (Erinnerungen: die Liste der Regeln). spec.create
        -- liefert einen Rahmen mit Sync; die Hoehe steht fest, damit die
        -- Seite nicht springt.
        w = spec.create(parent, CONTENT_W)
        if w then
            w:SetSize(CONTENT_W, spec.height or 100)
            if w.Sync then w.Sync() end
        end
    end
    if w then self.widgets[#self.widgets + 1] = w end
    return w
end

function Builder:Row(a, b)
    if self.skip then
        local z = self.zone
        if a and a.type ~= "empty" then z.count = z.count + 1 end
        if b and b.type ~= "empty" then z.count = z.count + 1 end
        return
    end
    local wa = a and a.type ~= "empty" and self:Cell(a)
    local wb = b and b.type ~= "empty" and self:Cell(b)
    local h = 0
    if wa then
        wa:SetPoint("TOPLEFT", self.parent, "TOPLEFT", 0, self.y)
        h = math.max(h, wa:GetHeight() or 0)
    end
    if wb then
        wb:SetPoint("TOPLEFT", self.parent, "TOPLEFT", CELL_W + GAP, self.y)
        h = math.max(h, wb:GetHeight() or 0)
    end
    self.y = self.y - h - 10
end

-- Was das Spiel stellt, stellt sein Bearbeitungsmodus: der Satz dazu und
-- ein Knopf hinueber (ui/editmode.lua, Bruecke). Schliesst man ihn, ist
-- man wieder auf dieser Seite.
O.GAME_EDIT_TEXT = "Bearbeitungsmodus des Spiels öffnen"
function Builder:GameEditMode(note)
    if self.skip then return end
    if note then self:Note(note) end
    local E = WeintCodex.UIEditMode
    local b = WeintCodex.CreateButton(self.parent, {
        text = O.GAME_EDIT_TEXT, kind = "secondary", height = 26, size = 11,
        backdrop = "bgDark", tooltip = E.GAME_TOOLTIP,
    })
    b:SetPoint("TOPLEFT", self.parent, "TOPLEFT", 0, self.y)
    E.AttachGame(b)
    b._gameEditMode = b         -- wie bei der Zelle: so findet ihn der Prueflauf
    self.widgets[#self.widgets + 1] = b
    self.y = self.y - 26 - 14
    return b
end

O.NewBuilder = NewBuilder   -- fuer den Prueflauf

--------------------------------------------------
-- Fenster
--------------------------------------------------

local frame, sidebar, head, tabsHost, previewHost, scroller, inner, footer
local sideRows = {}
local current = { module = "general", page = 1 }
local built = {}       -- [modul] = { tabs = , preview = , pages = { [i] = { frame, height, widgets } } }
O.built = built        -- fuer den Prueflauf

local function Label(parent, font, size, tone)
    local fs = K.NewText(parent)
    fs:SetFont(font, size, "")
    fs:SetTextColor(unpack(C[tone] or C.textNormal))
    fs:SetJustifyH("LEFT")
    return fs
end

local headToggle, headEyebrow, headTitle, headDesc
local unlockBtn, resetBtn, reloadBtn, reloadNote

local function SyncChrome()
    if not frame then return end
    for key, row in pairs(sideRows) do
        local text, tone = O.ModuleStatus(key)
        row.status:SetText(text)
        row.status:SetTextColor(unpack(C[tone] or C.textDim))
        local active = (key == current.module)
        row.bg:SetColorTexture(unpack(active and C.surface3 or C.bgPanel))
        row.strip:SetShown(active)
        row.label:SetTextColor(unpack(active and C.textBright or C.textMuted))
    end
    if headToggle then headToggle:Sync() end
    unlockBtn:SetText(K.IsUnlocked() and "Gestaltung beenden" or "Gestaltungsmodus")
    if K.ReloadPending() then
        reloadBtn:Show()
        reloadNote:Show()
    else
        reloadBtn:Hide()
        reloadNote:Hide()
    end
    local b = built[current.module]
    local page = b and b.pages[current.page]
    if page then for _, w in ipairs(page.widgets) do if w.Sync then w:Sync() end end end
end
O.SyncChrome = SyncChrome

local function ShowPage()
    -- Eine Seite ersetzt die Treffer der Suche (Klick links waehrend der Suche).
    if O.HideSearch then O.HideSearch() end
    local key = current.module
    local m = K.Module(key)
    local b = built[key]

    for k, other in pairs(built) do
        if other.tabs then other.tabs:SetShown(k == key and #K.Module(k).pages > 1) end
        if other.preview then other.preview:SetShown(k == key) end
        for i, p in pairs(other.pages) do
            p.frame:SetShown(k == key and i == current.page)
        end
    end

    local page = b.pages[current.page]
    if not page then
        local def = m.pages[current.page]
        local host = CreateFrame("Frame", nil, inner)
        host:SetPoint("TOPLEFT", inner, "TOPLEFT", 0, 0)
        host:SetSize(CONTENT_W, 10)
        -- `store`: eine Seite, deren Einstellungen bei einem anderen Modul
        -- liegen (Klickzauber und Makros im Komfort, 6.9.0.0).
        local B = NewBuilder((def and def.store) or key, host)
        if def and def.build then
            local ok, err = pcall(def.build, B)
            if not ok then K.Report(key, err) end
        end
        B:FinishAdvanced()
        page = { frame = host, height = -B.y + 20, widgets = B.widgets, zones = B.zones }
        host:SetHeight(page.height)
        b.pages[current.page] = page
    end
    page.frame:Show()
    inner:SetHeight(page.height)
    scroller:SetVerticalScroll(0)
    local bar = scroller.WCScrollBar
    if bar then
        if page.height > (scroller:GetHeight() or 0) then bar:Show() else bar:Hide() end
    end
    SyncChrome()
end

-- Erweitert ein- oder ausblenden: alle gebauten Seiten verwerfen, die
-- aktuelle neu bauen - an derselben Stelle.
function O.SetAdvanced(on)
    K.Set("general", "showAdvanced", on and true or false)
    for _, b in pairs(built) do
        for _, p in pairs(b.pages) do p.frame:Hide() end
        wipe(b.pages)
    end
    if current.module and built[current.module] then
        local scroll = scroller and scroller:GetVerticalScroll()
        ShowPage()
        if type(scroll) == "number" and scroller then
            local maxScroll = math.max(0, (inner:GetHeight() or 0) - (scroller:GetHeight() or 0))
            scroller:SetVerticalScroll(math.min(scroll, maxScroll))
        end
    end
end

local function Layout()
    -- Hoehe des Bildlaufbereichs: was unter Kopf, Reitern und Vorschau
    -- uebrig bleibt.
    local key = current.module
    local b = built[key]
    local top = HEAD_H
    if b.tabs and #K.Module(key).pages > 1 then
        local th = b.tabs:GetHeight() or TABS_H
        tabsHost:SetHeight(th)
        top = top + th + 10
    end
    O.tabsBottom = top   -- fuer den Prueflauf: hier beginnt, was unter der Leiste steht
    if b.preview then
        b.preview:ClearAllPoints()
        b.preview:SetPoint("TOPLEFT", frame, "TOPLEFT", SIDE_W + PAD, -top)
        top = top + (b.previewHeight or 0) + 12
    end
    scroller:ClearAllPoints()
    scroller:SetPoint("TOPLEFT", frame, "TOPLEFT", SIDE_W + PAD, -top)
    scroller:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -PAD, FOOT_H + 8)
end

function O.Select(key, pageIndex)
    local m = K.Module(key)
    if not m then return false end
    O.Build()
    current.module = key
    current.page = pageIndex or 1

    if not built[key] then
        local b = { pages = {} }
        if #m.pages > 1 then
            local items = {}
            for i, p in ipairs(m.pages) do items[i] = { text = p.label, key = i } end
            b.tabs = WeintCodex.CreateSegmentedControl(tabsHost, {
                items = items, backdrop = "bgDark", maxWidth = CONTENT_W,
                onSelect = function(_, i)
                    current.page = i
                    ShowPage()
                end,
            })
            b.tabs:SetPoint("TOPLEFT", tabsHost, "TOPLEFT", 0, 0)
        end
        if m.preview then
            local host = CreateFrame("Frame", nil, frame)
            host:SetSize(CONTENT_W, 100)
            local bg = host:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints(host)
            bg:SetColorTexture(unpack(C.surface1))
            local ok, pv, ph = pcall(m.preview, host)
            if ok and pv then
                pv:SetPoint("TOPLEFT", host, "TOPLEFT", 0, -4)
                pv:SetPoint("TOPRIGHT", host, "TOPRIGHT", 0, -4)
                host:SetHeight((ph or 92) + 8)
                b.previewHeight = (ph or 92) + 8
                local tag = WeintCodex.Eyebrow(host, "Vorschau", { size = 9 })
                tag:SetPoint("TOPLEFT", host, "TOPLEFT", 10, -8)
            else
                if not ok then K.Report(key, pv) end
                host:Hide()
                host = nil
            end
            b.preview = host
        end
        built[key] = b
    end
    if built[key].tabs then built[key].tabs:Select(current.page) end

    -- Kopf
    local groupLabel = ""
    for _, g in ipairs(GROUPS) do if g.key == m.group then groupLabel = g.label end end
    headEyebrow:SetText(WeintCodex.Spaced(WeintCodex.Upper(groupLabel)))
    headTitle:SetText(m.title or key)
    headDesc:SetText(m.description or "")

    if headToggle then headToggle:Hide() end
    headToggle = O.HeadToggle(key)
    if headToggle then headToggle:Show() end

    Layout()
    ShowPage()
    return true
end

-- Der Schalter oben rechts. Einer je Modul, einmal gebaut.
local headToggles = {}
function O.HeadToggle(key)
    if headToggles[key] ~= nil then return headToggles[key] or nil end
    local m = K.Module(key)
    local opts
    if key == "general" and not K.OPT_IN then
        -- Kein Hauptschalter, solange er nichts schalten kann.
        headToggles[key] = false
        return nil
    elseif key == "general" then
        opts = {
            label = "Oberfläche an",
            get = function() return K.UIEnabled() end,
            set = function(on) K.SetUIEnabled(on) end,
        }
    elseif m.group == "ui" then
        opts = {
            label = "Modul an",
            get = function() return K.ModuleEnabled(key) end,
            set = function(on) K.SetModuleEnabled(key, on) end,
            disabled = function() return not K.UIEnabled() end,
        }
    else
        opts = {
            label = "Modul an",
            get = function() return K.ModuleEnabled(key) end,
            set = function(on) K.SetModuleEnabled(key, on) end,
        }
    end
    opts.width = 170
    local t = WeintCodex.CreateToggle(head, opts)
    t:SetPoint("TOPRIGHT", head, "TOPRIGHT", -PAD, -26)
    t:Hide()
    headToggles[key] = t
    return t
end

local function BuildSidebar()
    local y = -22
    -- Das Logo der Oberflaeche (6.9.0.2) vor dem Namen.
    local logo = sidebar:CreateTexture(nil, "ARTWORK")
    logo:SetSize(LOGO, LOGO)
    logo:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 14, y + 4)
    logo:SetTexture(K.MEDIA .. "logo_64")
    O.logo = logo
    local brand = Label(sidebar, F.display, 20, "textBright")
    brand:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 14 + LOGO + 8, y)
    brand:SetText("WeintCodex")
    local sub = WeintCodex.Eyebrow(sidebar, "Oberfläche", { color = "accent", size = 9 })
    sub:SetPoint("TOPLEFT", brand, "BOTTOMLEFT", 1, -4)
    y = y - 62

    for _, g in ipairs(GROUPS) do
        local members = {}
        for _, key in ipairs(K.order) do
            if K.Module(key).group == g.key then members[#members + 1] = key end
        end
        if #members > 0 then
            if g.key ~= "general" then
                local gh = WeintCodex.Eyebrow(sidebar, g.label, { size = 9 })
                gh:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 20, y - 12)
                y = y - 30
            end
            for _, key in ipairs(members) do
                local m = K.Module(key)
                local row = CreateFrame("Button", nil, sidebar)
                row:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 8, y)
                row:SetSize(SIDE_W - 16, SIDE_ROW_H)
                row.bg = row:CreateTexture(nil, "BACKGROUND")
                row.bg:SetAllPoints(row)
                row.strip = row:CreateTexture(nil, "ARTWORK")
                row.strip:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -8)
                row.strip:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 8)
                row.strip:SetWidth(3)
                row.strip:SetColorTexture(unpack(C.accent))
                row.label = Label(row, F.sansSemi, 13, "textMuted")
                row.label:SetPoint("TOPLEFT", row, "TOPLEFT", 14, -5)
                row.label:SetText(key == "general" and "Allgemein" or m.title)
                row.status = Label(row, F.mono, 9, "textDim")
                row.status:SetPoint("TOPLEFT", row.label, "BOTTOMLEFT", 0, -3)
                row.status:SetWidth(SIDE_W - 40)
                row.status:SetWordWrap(false)
                row:SetScript("OnClick", function() O.Select(key) end)
                sideRows[key] = row
                y = y - SIDE_ROW_STEP
            end
        end
    end
    O._sidebarUsed = -y
end

-- Das Suchfeld (weiter unten, "Suche").
local BuildSearch

function O.Build()
    if frame then return frame end

    frame = CreateFrame("Frame", "WeintCodexUIOptions", UIParent)
    frame:SetSize(W, H)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetToplevel(true)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:Hide()
    O.frame = frame
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(frame)
    bg:SetColorTexture(unpack(C.bgDark))
    WeintCodex.DrawBorder(frame, C.border[1], C.border[2], C.border[3], 1, 1)

    -- ESC schliesst, wie jedes Fenster des Spiels.
    if type(_G.UISpecialFrames) == "table" then
        table.insert(_G.UISpecialFrames, "WeintCodexUIOptions")
    end

    sidebar = CreateFrame("Frame", nil, frame)
    sidebar:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    sidebar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    sidebar:SetWidth(SIDE_W)
    local sbg = sidebar:CreateTexture(nil, "BACKGROUND")
    sbg:SetAllPoints(sidebar)
    sbg:SetColorTexture(unpack(C.bgPanel))

    -- Kopf: zugleich der Griff zum Verschieben.
    head = CreateFrame("Frame", nil, frame)
    head:SetPoint("TOPLEFT", frame, "TOPLEFT", SIDE_W, 0)
    head:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    head:SetHeight(HEAD_H)
    head:EnableMouse(true)
    head:RegisterForDrag("LeftButton")
    head:SetScript("OnDragStart", function() frame:StartMoving() end)
    head:SetScript("OnDragStop", function() frame:StopMovingOrSizing() end)
    local hbg = head:CreateTexture(nil, "BACKGROUND")
    hbg:SetAllPoints(head)
    WeintCodex.ApplyVerticalGradient(hbg, "washAccent", "washNone")

    headEyebrow = WeintCodex.Eyebrow(head, "Allgemein", { size = 9 })
    headEyebrow:SetPoint("TOPLEFT", head, "TOPLEFT", PAD, -20)
    headTitle = Label(head, F.display, 22, "textBright")
    headTitle:SetPoint("TOPLEFT", headEyebrow, "BOTTOMLEFT", 0, -4)
    headDesc = Label(head, F.sans, 12, "textMuted")
    headDesc:SetPoint("TOPLEFT", headTitle, "BOTTOMLEFT", 0, -6)
    headDesc:SetWidth(CONTENT_W - 200)
    headDesc:SetWordWrap(true)

    local close = CreateFrame("Button", nil, head)
    close:SetSize(28, 24)
    close:SetPoint("TOPRIGHT", head, "TOPRIGHT", -8, -8)
    local x = K.NewText(close)
    x:SetFont(F.sans, 14, "")
    x:SetPoint("CENTER", close, "CENTER", 0, 0)
    x:SetTextColor(unpack(C.textMuted))
    x:SetText("\195\151")
    close:SetScript("OnClick", function() frame:Hide() end)
    close:SetScript("OnEnter", function() x:SetTextColor(unpack(C.textBright)) end)
    close:SetScript("OnLeave", function() x:SetTextColor(unpack(C.textMuted)) end)
    BuildSearch(head, close)

    tabsHost = CreateFrame("Frame", nil, frame)
    tabsHost:SetPoint("TOPLEFT", frame, "TOPLEFT", SIDE_W + PAD, -HEAD_H)
    tabsHost:SetSize(CONTENT_W, TABS_H)

    scroller, inner = WeintCodex.CreateScrollArea(frame, SIDE_W + PAD, -(HEAD_H + TABS_H + 10),
        CONTENT_W + SCROLL_W, 300, true)
    inner:SetWidth(CONTENT_W)
    scroller.scrollBarHideable = true

    -- Fussleiste
    footer = CreateFrame("Frame", nil, frame)
    footer:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", SIDE_W, 0)
    footer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    footer:SetHeight(FOOT_H)
    local fbg = footer:CreateTexture(nil, "BACKGROUND")
    fbg:SetAllPoints(footer)
    fbg:SetColorTexture(unpack(C.surface1))

    unlockBtn = WeintCodex.CreateButton(footer, {
        text = "Gestaltungsmodus", kind = "secondary", height = 30, size = 11, backdrop = "surface1",
        tooltip = "Schließt dieses Fenster und zeigt alle beweglichen Rahmen mit Beispieldaten, Raster und Einrasten. „Fertig“ oben (oder Esc) bringt dich hierher zurück.",
        onClick = function() K.SetUnlocked(not K.IsUnlocked()) SyncChrome() end,
    })
    unlockBtn:SetPoint("LEFT", footer, "LEFT", PAD, 0)

    resetBtn = WeintCodex.CreateButton(footer, {
        text = "Standard", kind = "ghost", height = 30, size = 11, backdrop = "surface1",
        tooltip = "Setzt die Einstellungen dieses Moduls zurück. Ob es an oder aus ist, bleibt.",
        onClick = function()
            K.ResetModule(current.module)
            SyncChrome()
        end,
    })
    resetBtn:SetPoint("LEFT", unlockBtn, "RIGHT", 8, 0)

    -- Neuladen ist auf Forever geschuetzt: der Knopf fuehrt "/reload" als
    -- Makro aus, ausgeloest vom Klick selbst (UIKit.ReloadButton).
    reloadBtn = K.ReloadButton(footer, {
        text = "Jetzt neu laden", height = 30, size = 11, backdrop = "surface1",
    })
    reloadBtn:SetPoint("RIGHT", footer, "RIGHT", -PAD, 0)
    reloadNote = Label(footer, F.sans, 11, "warningBright")
    reloadNote:SetPoint("RIGHT", reloadBtn, "LEFT", -12, 0)
    reloadNote:SetText("Wirkt nach dem Neuladen.")

    BuildSidebar()

    frame:SetScale((K.Get("general", "windowScale") or 100) / 100)
    frame:SetScript("OnShow", SyncChrome)

    K.Listen(function(kind)
        if kind == "setting" or kind == "reload" or kind == "active" or kind == "unlock" then
            if frame:IsShown() then SyncChrome() end
        end
    end)
    return frame
end

-- Die Bedienelemente der offenen Seite (fuer den Prueflauf).
function O.CurrentWidgets()
    local b = built[current.module]
    local page = b and b.pages[current.page]
    return page and page.widgets or {}
end

-- Die Bereiche "Erweitert" der aktuellen Seite ({ button, count, open }).
function O.CurrentZones()
    local b = built[current.module]
    local page = b and b.pages[current.page]
    return page and page.zones or {}
end

-- Stelle einer Seite in einem Modul (nach ihrem Schluessel), sonst 1.
function O.PageIndex(moduleKey, pageKey)
    local m = K.Module(moduleKey)
    for i, p in ipairs(m and m.pages or {}) do
        if p.key == pageKey then return i end
    end
    return 1
end

function O.Show(key, pageIndex)
    O.Build()
    frame:Show()
    O.Select(key or current.module, pageIndex)
end

-- Wo das Fenster gerade steht: Modul, Seite, Bildlauf. Die Bruecke zum
-- Bearbeitungsmodus des Spiels (ui/editmode.lua) merkt sich das und kehrt
-- genau dorthin zurueck - nicht auf die erste Seite des Moduls.
function O.Where()
    local scroll = scroller and scroller.GetVerticalScroll and scroller:GetVerticalScroll()
    return { module = current.module, page = current.page, scroll = type(scroll) == "number" and scroll or 0 }
end

function O.Return(where)
    if type(where) ~= "table" then return O.Show() end
    O.Show(where.module, where.page)
    if scroller and where.scroll and where.scroll > 0 then
        local maxScroll = scroller.GetVerticalScrollRange and scroller:GetVerticalScrollRange()
        local s = where.scroll
        if type(maxScroll) == "number" and maxScroll >= 0 and s > maxScroll then s = maxScroll end
        scroller:SetVerticalScroll(s)
    end
end

--------------------------------------------------
-- Suche (6.10.0.0)
--------------------------------------------------
-- Rund 340 Einstellungen auf gut 40 Seiten: wer "Stapelzahl" sucht, soll
-- nicht raten muessen, ob sie bei den Leisten oder den Taschen steht. Die
-- Suche liest jede Seite einmal mit einem Mitschreiber (gleiche Methoden
-- wie der Seitenbauer, baut aber nichts) und findet auch, was unter
-- "Erweitert" zugeklappt ist. Ein Klick auf einen Treffer oeffnet die
-- Seite - und klappt "Erweitert" auf, wenn der Treffer dort steht.

local Recorder = {}
local function Nothing() end
Recorder.__index = function(_, k)
    if Recorder[k] then return Recorder[k] end
    -- Was eine Seite sonst noch aufruft (Methoden: Grossbuchstabe vorn),
    -- tut beim Mitschreiben nichts. Felder (section, adv) bleiben nil.
    if type(k) == "string" and k:find("^%u") then return Nothing end
    return nil
end
function Recorder:Section(title) self.section = title end
function Recorder:Advanced() self.adv = true end
function Recorder:EndAdvanced() self.adv = false end
function Recorder:Add(label, description)
    if type(label) ~= "string" or label == "" then return end
    local out = self.out
    out[#out + 1] = { module = self.module, page = self.page, pageLabel = self.pageLabel,
                      section = self.section, label = label, description = description,
                      advanced = self.adv and true or false }
end
function Recorder:Cell(spec)
    if type(spec) == "table" and spec.type ~= "empty" then self:Add(spec.label, spec.description) end
end
function Recorder:Row(a, b) self:Cell(a) self:Cell(b) end
function Recorder:GameEditMode() self:Add(O.GAME_EDIT_TEXT) end

-- Klein, auch Umlaute: string.lower kennt nur ASCII.
local UMLAUT = { ["\195\132"] = "\195\164", ["\195\150"] = "\195\182", ["\195\156"] = "\195\188" }
local function Fold(text)
    return (tostring(text or ""):lower():gsub("\195[\132\150\156]", UMLAUT))
end
O.Fold = Fold

local index
-- Alle Eintraege aller Seiten, einmal gelesen.
function O.SearchIndex()
    if index then return index end
    index = {}
    local scratch = CreateFrame("Frame", nil, UIParent)
    scratch:Hide()
    for _, key in ipairs(K.order) do
        local m = K.Module(key)
        for i, def in ipairs(m.pages or {}) do
            if def.build then
                local R = setmetatable({ out = index, module = key, page = i, pageLabel = def.label,
                                         parent = scratch, y = -4, widgets = {} }, Recorder)
                pcall(def.build, R)
            end
        end
    end
    return index
end

-- Treffer fuer `text` (ab zwei Zeichen), hoechstens `limit`.
function O.Search(text, limit)
    local q = Fold(text):gsub("^%s+", ""):gsub("%s+$", "")
    local hits = {}
    if #q < 2 then return hits end
    for _, e in ipairs(O.SearchIndex()) do
        local m = K.Module(e.module)
        local hay = Fold(e.label) .. " " .. Fold(e.section) .. " " .. Fold(e.pageLabel) .. " "
            .. Fold(m and m.title) .. " " .. Fold(e.description)
        if hay:find(q, 1, true) then
            hits[#hits + 1] = e
            if limit and #hits >= limit then break end
        end
    end
    return hits
end

O.SEARCH_MAX = 30
local results, resultRows, searchBox = nil, {}, nil

local function OpenHit(e)
    if searchBox then searchBox:SetText("") searchBox:ClearFocus() end
    if results then results:Hide() end
    if e.advanced and not K.Get("general", "showAdvanced") then O.SetAdvanced(true) end
    O.Show(e.module, e.page)
end
O.OpenHit = OpenHit

local function ResultRow(i)
    local r = resultRows[i]
    if r then return r end
    r = CreateFrame("Button", nil, results)
    r:SetSize(CONTENT_W, 40)
    r:SetPoint("TOPLEFT", results, "TOPLEFT", 0, -(i - 1) * 44)
    local bg = r:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(r)
    bg:SetColorTexture(unpack(C.surface1))
    local hl = r:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints(r)
    hl:SetColorTexture(unpack(C.surface2))
    r.label = Label(r, F.sans, 13, "textBright")
    r.label:SetPoint("TOPLEFT", r, "TOPLEFT", 10, -6)
    r.label:SetWidth(CONTENT_W - 20)
    r.label:SetWordWrap(false)
    r.path = Label(r, F.sans, 11, "textMuted")
    r.path:SetPoint("TOPLEFT", r.label, "BOTTOMLEFT", 0, -3)
    r.path:SetWidth(CONTENT_W - 20)
    r.path:SetWordWrap(false)
    r:SetScript("OnClick", function(self) if self._hit then OpenHit(self._hit) end end)
    resultRows[i] = r
    return r
end

-- Treffer statt der Seite zeigen; leerer Text: zurueck zur Seite.
function O.ShowSearch(text)
    O.Build()
    local hits = O.Search(text, O.SEARCH_MAX)
    if #Fold(text):gsub("%s", "") < 2 then
        if results and results:IsShown() then
            results:Hide()
            ShowPage()
        end
        return hits
    end
    if not results then
        results = CreateFrame("Frame", nil, inner)
        results:SetPoint("TOPLEFT", inner, "TOPLEFT", 0, 0)
        results:SetSize(CONTENT_W, 10)
        results.empty = Label(results, F.sans, 12, "textDim")
        results.empty:SetPoint("TOPLEFT", results, "TOPLEFT", 0, -4)
        results.empty:SetWidth(CONTENT_W)
        O.results = results
    end
    for _, b in pairs(built) do
        for _, p in pairs(b.pages) do p.frame:Hide() end
        if b.tabs then b.tabs:Hide() end
        if b.preview then b.preview:Hide() end
    end
    for i, e in ipairs(hits) do
        local r = ResultRow(i)
        local m = K.Module(e.module)
        r._hit = e
        r.label:SetText(e.label)
        local path = (m and m.title or e.module) .. "  ›  " .. (e.pageLabel or "")
        if e.section then path = path .. "  ›  " .. e.section end
        if e.advanced then path = path .. "  ·  Erweitert" end
        r.path:SetText(path)
        r:Show()
    end
    for i = #hits + 1, #resultRows do resultRows[i]._hit = nil resultRows[i]:Hide() end
    if #hits == 0 then
        results.empty:SetText("Keine Einstellung gefunden.")
        results.empty:Show()
    else
        results.empty:Hide()
    end
    local h = math.max(40, #hits * 44)
    results:SetHeight(h)
    results:Show()
    inner:SetHeight(h)
    scroller:SetVerticalScroll(0)
    return hits
end

function O.SearchRows() return resultRows end
function O.HideSearch()
    if results then results:Hide() end
end

-- Das Suchfeld oben rechts im Kopf.
BuildSearch = function(parent, anchor)
    local eb = CreateFrame("EditBox", nil, parent)
    eb:SetSize(180, 24)
    eb:SetPoint("RIGHT", anchor, "LEFT", -10, 0)
    eb:SetAutoFocus(false)
    if eb.SetTextInsets then eb:SetTextInsets(8, 8, 0, 0) end
    K.SetFont(eb, 12)
    local bg = eb:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(eb)
    bg:SetColorTexture(unpack(C.bgDark))
    K.Border(eb, 1, 0, 0, 0, 1, "BORDER")
    local hint = Label(eb, F.sans, 12, "textFaint")
    hint:SetPoint("LEFT", eb, "LEFT", 8, 0)
    hint:SetText("Einstellung suchen …")
    eb:SetScript("OnTextChanged", function(self)
        local t = self:GetText() or ""
        hint:SetShown(t == "")
        O.ShowSearch(t)
    end)
    eb:SetScript("OnEscapePressed", function(self) self:SetText("") self:ClearFocus() end)
    eb:SetScript("OnEnterPressed", function(self)
        local first = resultRows[1]
        if first and first:IsShown() and first._hit then OpenHit(first._hit) else self:ClearFocus() end
    end)
    searchBox = eb
    O.searchBox = eb
    return eb
end

function O.Toggle()
    O.Build()
    if frame:IsShown() then frame:Hide() else O.Show() end
end

SLASH_WEINTCODEXUI1 = "/wcui"
SlashCmdList["WEINTCODEXUI"] = function(msg)
    msg = (msg or ""):lower()
    if msg == "entsperren" or msg == "unlock" then
        K.SetUnlocked(not K.IsUnlocked())
        return
    end
    if msg == "test" then
        WeintCodex.UITestMode.Toggle()
        return
    end
    if msg == "chat" then
        for _, line in ipairs(WeintCodex.UIChat.Inspect()) do
            print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " " .. line)
        end
        return
    end
    -- Direkt zu einem Modul, ohne die Seitenleiste zu suchen.
    if msg == "erinnerungen" or msg == "reminders" then
        if not K.Module("reminders") then
            print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " Die Erinnerungen sind nicht geladen – läuft WeintCodex 6.4.0.0 oder neuer? Gerade: " .. tostring(WeintCodex.Version))
            return
        end
        O.Show("reminders")
        return
    end
    if msg == "abklingzeiten" or msg == "abklingzeitmanager" or msg == "cdm" then
        local CD = WeintCodex.UICooldowns
        if not (CD and CD.PAGE) then
            print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " Der Abklingzeitmanager ist nicht geladen – läuft WeintCodex 6.4.1.0 oder neuer? Gerade: " .. tostring(WeintCodex.Version))
            return
        end
        O.Show("reminders", CD.PAGE)
        return
    end
    -- 6.10.2.0: Berichte in ein Fenster zum Kopieren statt in den Chat.
    -- 6.10.4.0: verschobene Fenster an den Platz des Spiels.
    if msg == "fenster zurück" or msg == "fenster zurueck" or msg == "window reset" then
        local n = WeintCodex.UIMoveWindows.ResetAll()
        print(WeintCodex.ColorText("accent", "[WeintCodex]") .. string.format(
            " %d verschobene Fenster stehen wieder am Platz des Spiels.", n))
        return
    end
    if msg == "fenster" or msg == "window" then
        local lines = K.InspectWindow()
        K.ShowReport("Fenster unter der Maus", lines)
        print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " " .. lines[1]
            .. " – Bericht im Fenster, Strg+C kopiert.")
        return
    end
    if msg == "prüfen" or msg == "pruefen" or msg == "check" then
        local lines = WeintCodex.UISelfCheck.Run()
        K.ShowReport("Selbstprüfung", lines)
        local last = WeintCodex.UISelfCheck.last
        print(WeintCodex.ColorText("accent", "[WeintCodex]") .. string.format(
            " Selbstprüfung: %d Befunde, %d offen – Bericht im Fenster, Strg+C kopiert.", last.bad, last.open))
        return
    end
    if msg == "maus" or msg == "mouse" then
        for _, line in ipairs(K.InspectMouse()) do
            print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " " .. line)
        end
        return
    end
    if msg == "addons" then
        for _, line in ipairs(WeintCodex.UIMinimap.InspectAddons()) do
            print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " " .. line)
        end
        return
    end
    -- 6.11.0.4: Profile je Charakter.
    if msg == "profil" or msg == "profile" then
        O.Show("general", O.PageIndex("general", "profile"))
        return
    end
    if msg == "willkommen" or msg == "welcome" then
        WeintCodex.UIWelcome.Ask()
        return
    end
    if msg == "einrichten" or msg == "setup" then
        WeintCodex.UISetup.Show()
        return
    end
    if msg == "einrichten pruefen" or msg == "einrichten prüfen" or msg == "setup check" then
        local ok, lines = pcall(WeintCodex.UISetup.Check)
        if not ok then lines = { "Prüfung fehlgeschlagen: " .. tostring(lines) } end
        for _, line in ipairs(lines) do
            print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " " .. line)
        end
        return
    end
    if msg == "speicher" or msg == "memory" then
        local say = function(line) print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " " .. line) end
        if K.prof.on then say("Die Messung läuft schon.") return end
        say("Messe 30 Sekunden, wer wie viel Speicher belegt – spiel einfach weiter, am aussagekräftigsten im Kampf.")
        K.ProfileRun(30, function(lines) for _, line in ipairs(lines) do say(line) end end)
        return
    end
    if msg == "gruppe" or msg == "group" then
        for _, line in ipairs(WeintCodex.UIGameGroup.Inspect()) do
            print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " " .. line)
        end
        return
    end
    if msg == "pfeil weiter" or msg == "arrow skip" then
        local QA = WeintCodex.UIQuestArrow
        local skipped = QA.Skip()
        print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " "
            .. (skipped and "Ziel für zehn Minuten ausgelassen – der Pfeil plant neu." or "Der Pfeil hat gerade kein Ziel."))
        return
    end
    if msg == "pfeil planen" or msg == "arrow plan" then
        WeintCodex.UIQuestArrow.Resume()
        print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " Eigene Wahl abgegeben – der Pfeil plant wieder selbst.")
        return
    end
    if msg == "flüstern" or msg == "fluestern" or msg == "wim" or msg == "whisper" then
        local MS = WeintCodex.UIMessenger
        if MS and MS.Active() then MS.Toggle()
        else print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " Flüstern im eigenen Fenster ist aus (Komfort → Flüstern).") end
        return
    end
    if msg == "auktion" or msg == "ah" or msg == "auction" then
        local AP = WeintCodex.UIAuctionPrices
        if AP and AP.Report then K.ShowReport("Auktionspreise", AP.Report()) end
        return
    end
    if msg == "auktion scan" or msg == "ah scan" or msg == "auction scan" then
        local AP = WeintCodex.UIAuctionPrices
        if AP and AP.Start then AP.Start() end
        return
    end
    if msg == "taschen" or msg == "bags" then
        -- 6.25.0.0: eine Seite im Codex, kein eigenes Fenster mehr.
        if WeintCodex.MainFrame and WeintCodex.Navigation then
            WeintCodex.MainFrame:Show()
            WeintCodex.Navigation.GoToTab("taschen")
        end
        return
    end
    if msg == "bestand" or msg:match("^bestand%s") then
        local IV = WeintCodex.UIInventory
        local q = msg:match("^bestand%s+(.+)$")
        if IV then
            if q then K.ShowReport("Bestand", IV.SearchReport(q))
            else K.ShowReport("Bestand", IV.StatusLines()) end
        end
        return
    end
    if msg == "selten" or msg == "rares" or msg == "rare" then
        local RA = WeintCodex.UIRares
        if RA and RA.Report then K.ShowReport("Seltene Gegner", RA.Report()) end
        return
    end
    if msg == "pfeil" or msg == "arrow" then
        for _, line in ipairs(WeintCodex.UIQuestArrow.Inspect()) do
            print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " " .. line)
        end
        return
    end
    if msg == "auren" or msg == "auras" then
        for _, line in ipairs(WeintCodex.UIAuras.Inspect()) do
            print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " " .. line)
        end
        return
    end
    O.Toggle()
end
