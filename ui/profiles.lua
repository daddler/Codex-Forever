--------------------------------------------------
-- WeintCodex :: Oberflaeche - Profile (6.11.0.4)
--------------------------------------------------
-- Beta-Test: "wcui braeuchte Profile - ein grosser Vorteil, wenn man
-- mehrere Charaktere hat". Ein Profil haelt alle Einstellungen der
-- Oberflaeche und des Komforts samt der Plaetze der Rahmen; jeder
-- Charakter nutzt eins, mehrere koennen eins teilen. Gespeichert wird in
-- ui/kit.lua (ui.profiles, ui.profileOf) - hier wird gewaehlt, angelegt,
-- umbenannt, uebernommen, zurueckgesetzt und geloescht.
--
-- REGELN
--   * "Standard" gibt es immer: neue Charaktere starten dort, und wessen
--     Profil geloescht wird, landet dort. Es laesst sich weder umbenennen
--     noch loeschen.
--   * Das Profil einer Sitzung steht bis zum Neuladen fest (K.Profile):
--     laufende Module lesen nie mitten im Spiel aus einem anderen. Was das
--     laufende Profil aendert (Wahl, Kopie, Zuruecksetzen), verlangt ein
--     Neuladen (K.MarkReload, Knopf unten im Fenster).
--   * Geloescht wird nur, was weder laeuft noch gewaehlt ist - sonst
--     stuende der Charakter mitten im Spiel ohne Profil da.
--   * Nicht im Profil (ganzes Konto): Hauptschalter, Willkommen, Layout
--     und Spieleinstellungen von vorher (ui/profile.lua), Minikartensymbol,
--     verfolgte Quests.
--
-- Nicht zu verwechseln mit ui/profile.lua: das merkt sich, was die
-- Oberflaeche am SPIEL aendert, und gibt es beim Ausschalten zurueck.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIProfiles = {}

local PR = WeintCodex.UIProfiles
local K  = WeintCodex.UIKit

PR.MAX_NAME = 32

local function DeepCopy(v)
    if type(v) ~= "table" then return v end
    local out = {}
    for k, x in pairs(v) do out[k] = DeepCopy(x) end
    return out
end
PR.DeepCopy = DeepCopy

local function Changed()
    K.Fire("setting", "general", "profile")
end

-- Alle Namen, "Standard" zuerst, dann nach dem Alphabet.
function PR.List()
    local ui = K.Root()
    local out = {}
    if not ui then return out end
    for name in pairs(ui.profiles) do
        if name ~= K.DEFAULT_PROFILE then out[#out + 1] = name end
    end
    table.sort(out, function(a, b) return a:lower() < b:lower() end)
    table.insert(out, 1, K.DEFAULT_PROFILE)
    return out
end

function PR.Chosen() return K.ChosenProfile() end
function PR.Active() return K.ActiveProfile() end

-- Wartet die Wahl auf ein Neuladen?
function PR.Pending()
    local chosen, active = PR.Chosen(), PR.Active()
    return chosen ~= nil and active ~= nil and chosen ~= active
end

-- Charaktere, die `name` gewaehlt haben ("Name" auf dem eigenen Realm,
-- sonst "Name-Realm").
function PR.Users(name)
    local ui = K.Root()
    local out = {}
    if not ui then return out end
    local me = K.CharKey()
    local realm = me and me:match("%-(.+)$")
    for char, prof in pairs(ui.profileOf) do
        if prof == name then
            local n, r = char:match("^(.-)%-(.+)$")
            out[#out + 1] = (n and r == realm) and n or char
        end
    end
    table.sort(out)
    return out
end

-- Ein Name, den es noch nicht gibt: "Shooty", sonst "Shooty 2", ...
function PR.FreeName(base)
    local ui = K.Root()
    base = (type(base) == "string" and base ~= "") and base or "Profil"
    if not (ui and ui.profiles[base]) then return base end
    local i = 2
    while ui.profiles[base .. " " .. i] do i = i + 1 end
    return base .. " " .. i
end

-- Ein Name ist gueltig: nicht leer, nicht zu lang, nicht vergeben.
function PR.Check(name)
    if type(name) ~= "string" then return false, "Kein Name." end
    name = name:match("^%s*(.-)%s*$")
    if name == "" then return false, "Der Name ist leer." end
    if WeintCodex.Utf8Len(name) > PR.MAX_NAME then return false, "Höchstens " .. PR.MAX_NAME .. " Zeichen." end
    local ui = K.Root()
    if ui and ui.profiles[name] then return false, "„" .. name .. "“ gibt es schon." end
    return true, name
end

-- Dieser Charakter nutzt `name`. Wirkt nach dem Neuladen.
function PR.Choose(name)
    local ui, key = K.Root(), K.CharKey()
    if not (ui and key and type(name) == "string" and ui.profiles[name]) then return false end
    -- "Standard" ist der Platz ohne Wahl - kein Eintrag noetig.
    ui.profileOf[key] = (name ~= K.DEFAULT_PROFILE) and name or nil
    if name ~= PR.Active() then K.MarkReload() end
    Changed()
    return true
end

-- Neues Profil als Kopie des gewaehlten, benannt nach dem Charakter, und
-- gleich gewaehlt.
function PR.New(name)
    local ui = K.Root()
    if not ui then return nil end
    if not name then
        local key = K.CharKey()
        name = PR.FreeName(key and key:match("^(.-)%-") or nil)
    end
    local ok, clean = PR.Check(name)
    if not ok then return nil, clean end
    ui.profiles[clean] = DeepCopy(ui.profiles[PR.Chosen()] or {})
    PR.Choose(clean)
    return clean
end

function PR.Rename(old, new)
    local ui = K.Root()
    if not (ui and type(old) == "string" and ui.profiles[old]) then return false, "Kein Profil." end
    if old == K.DEFAULT_PROFILE then return false, "„Standard“ behält seinen Namen." end
    if new == old then return true end
    local ok, clean = PR.Check(new)
    if not ok then return false, clean end
    -- VOR dem Umzug fragen: danach fehlt der alte Name, und K.Profile
    -- fiele auf das gewaehlte Profil zurueck.
    local running = (PR.Active() == old)
    ui.profiles[clean], ui.profiles[old] = ui.profiles[old], nil
    for char, prof in pairs(ui.profileOf) do
        if prof == old then ui.profileOf[char] = clean end
    end
    if running then K._SetActiveProfile(clean) end
    Changed()
    return true, clean
end

-- Alles aus `source` in das gewaehlte Profil uebernehmen (ersetzt es).
function PR.CopyFrom(source)
    local ui = K.Root()
    local target = PR.Chosen()
    if not (ui and type(source) == "string" and ui.profiles[source]) or source == target then return false end
    local p = ui.profiles[target]
    local copy = DeepCopy(ui.profiles[source])
    -- Dieselbe Tabelle behalten: K.Profile hat sie vielleicht schon in der Hand.
    for k in pairs(p) do p[k] = nil end
    for k, v in pairs(copy) do p[k] = v end
    if target == PR.Active() then K.MarkReload() end
    Changed()
    return true
end

-- Das gewaehlte Profil auf die Voreinstellungen zurueck (Plaetze auch).
function PR.Reset()
    local ui = K.Root()
    local target = PR.Chosen()
    if not (ui and ui.profiles[target]) then return false end
    local p = ui.profiles[target]
    -- Leer: K.Profile legt modules und positions beim naechsten Zugriff an.
    for k in pairs(p) do p[k] = nil end
    if target == PR.Active() then K.MarkReload() end
    Changed()
    return true
end

-- Was sich loeschen laesst: nicht "Standard", nicht das laufende, nicht
-- das gewaehlte.
function PR.Deletable(name)
    local ui = K.Root()
    return ui ~= nil and type(name) == "string" and ui.profiles[name] ~= nil
        and name ~= K.DEFAULT_PROFILE and name ~= PR.Active() and name ~= PR.Chosen()
end

function PR.Delete(name)
    if not PR.Deletable(name) then return false end
    local ui = K.Root()
    ui.profiles[name] = nil
    -- Wer es nutzte, landet bei "Standard" (kein Eintrag).
    for char, prof in pairs(ui.profileOf) do
        if prof == name then ui.profileOf[char] = nil end
    end
    Changed()
    return true
end

--------------------------------------------------
-- Rueckfrage
--------------------------------------------------

local POPUP = "WEINTCODEX_UI_PROFILE"
if _G.StaticPopupDialogs then
    _G.StaticPopupDialogs[POPUP] = {
        text = "%s", button1 = "Ja", button2 = "Abbrechen",
        OnAccept = function(_, data) if data and data.fn then data.fn() end end,
        timeout = 0, whileDead = true, hideOnEscape = true,
    }
end

-- Fragt nach; ohne Dialog des Spiels (Prueflauf) gilt es sofort.
function PR.Confirm(text, fn)
    if _G.StaticPopup_Show and _G.StaticPopupDialogs and _G.StaticPopupDialogs[POPUP] then
        _G.StaticPopup_Show(POPUP, text, nil, { fn = fn })
    else
        fn()
    end
end

--------------------------------------------------
-- Seite in /wcui (Allgemein -> Profile)
--------------------------------------------------

local PICK = "__pick"

local function Items(filter, placeholder)
    return function()
        local out = { { value = PICK, text = placeholder } }
        for _, name in ipairs(PR.List()) do
            if filter(name) then out[#out + 1] = { value = name, text = name } end
        end
        return out
    end
end

-- Satz unter den Knoepfen: wer das Profil nutzt, und ob ein Neuladen
-- aussteht.
function PR.StatusText()
    local chosen, active = PR.Chosen(), PR.Active()
    if not chosen then return "" end
    local users = PR.Users(chosen)
    local who
    if chosen == K.DEFAULT_PROFILE then
        who = #users > 0 and (table.concat(users, ", ") .. " und jeder Charakter ohne eigene Wahl")
            or "jeder Charakter ohne eigene Wahl"
    else
        who = #users > 0 and table.concat(users, ", ") or "noch niemand"
    end
    local text = "„" .. chosen .. "“ nutzen: " .. who .. "."
    if PR.Pending() then
        text = text .. "\n" .. WeintCodex.ColorText("warningBright",
            "Nach dem Neuladen gilt „" .. chosen .. "“ – bis dahin läuft „" .. active .. "“.")
    end
    return text
end

function PR.BuildPage(B)
    B:Section("Profil dieses Charakters",
        "Ein Profil hält alle Einstellungen der Oberfläche und des Komforts, dazu die Plätze deiner Rahmen. Mehrere Charaktere können eines teilen – was du dann änderst, gilt für alle, die es nutzen. Neue Charaktere starten mit „Standard“.")
    B:Row({ type = "dropdown", label = "Profil",
            items = function()
                local out = {}
                for _, name in ipairs(PR.List()) do out[#out + 1] = { value = name, text = name } end
                return out
            end,
            get = PR.Chosen, set = function(v) PR.Choose(v) end,
            tooltip = "Welches Profil dieser Charakter nutzt. Ein Wechsel wirkt nach dem Neuladen." },
          { type = "button", label = "Neues Profil", text = "Als Kopie anlegen",
            tooltip = "Legt ein Profil mit dem Namen dieses Charakters an – eine Kopie des gewählten – und wählt es. Wirkt nach dem Neuladen.",
            onClick = function() PR.New() end })
    B:Row({ type = "input", label = "Name des Profils",
            get = PR.Chosen,
            -- Bei jeder Eingabe: ein ungueltiger Name (leer, vergeben)
            -- aendert nichts, der naechste Buchstabe versucht es wieder.
            set = function(text) PR.Rename(PR.Chosen(), text) end,
            disabled = function() return PR.Chosen() == K.DEFAULT_PROFILE end },
          { type = "custom", height = 52, create = function(parent)
                local f = CreateFrame("Frame", nil, parent)
                local fs = K.NewText(f)
                fs:SetFont(WeintCodex.Fonts.sans, 12, "")
                fs:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -4)
                fs:SetWidth(WeintCodex.UIOptions.CELL_W)
                fs:SetJustifyH("LEFT")
                fs:SetTextColor(unpack(WeintCodex.Colors.textMuted))
                f.text, f.isProfileStatus = fs, true
                f.Sync = function() fs:SetText(PR.StatusText()) end
                return f
            end })
    B:Section("Übernehmen und aufräumen")
    B:Row({ type = "dropdown", label = "Einstellungen übernehmen von",
            items = Items(function(n) return n ~= PR.Chosen() end, "Profil wählen …"),
            get = function() return PICK end,
            set = function(v)
                if v == PICK then return end
                PR.Confirm("Alle Einstellungen und Plätze von „" .. v .. "“ in „" .. PR.Chosen() .. "“ übernehmen? Was dort steht, wird ersetzt.",
                    function() PR.CopyFrom(v) end)
            end },
          { type = "button", label = "Zurücksetzen", text = "Profil zurücksetzen",
            tooltip = "Alle Einstellungen und Plätze des gewählten Profils auf die Voreinstellung.",
            onClick = function()
                PR.Confirm("„" .. PR.Chosen() .. "“ auf die Voreinstellungen zurücksetzen – alle Einstellungen und Plätze?",
                    function() PR.Reset() end)
            end })
    B:Row({ type = "dropdown", label = "Profil löschen",
            items = Items(PR.Deletable, "Profil wählen …"),
            get = function() return PICK end,
            set = function(v)
                if v == PICK then return end
                PR.Confirm("Profil „" .. v .. "“ löschen? Wer es nutzt, bekommt „Standard“.", function() PR.Delete(v) end)
            end,
            tooltip = "„Standard“, das laufende und das gewählte Profil lassen sich nicht löschen." },
          { type = "empty" })
    B:Note("Hauptschalter, Willkommen, das Symbol an der Minikarte und was WeintCodex am Spiel geändert hat (Layout, Spieleinstellungen), gelten für alle Charaktere – sie sind nicht im Profil.")
end

--------------------------------------------------
-- Beim Einloggen fragen (6.12.0.1)
--------------------------------------------------
-- Beta-Test: "Gut waere, wenn man direkt darauf hingewiesen wird, ein
-- Profil anzulegen, beim Start vom Spiel." Einmal je Charakter, der noch
-- kein eigenes Profil gewaehlt hat:
--   "Eigenes Profil anlegen"  Kopie von dem, was laeuft, gewaehlt; danach
--                             derselbe Dialog mit "Jetzt neu laden".
--   "Profil wählen …"         nur, wenn es mehr als "Standard" gibt: die
--                             Seite in /wcui.
--   "Standard behalten"       gilt als Antwort - nie wieder gefragt.
--   "×" oben rechts, Esc       "Spaeter": bis zum naechsten Einloggen.
-- Gemerkt in ui.profileAsked["Name-Realm"] (ganzes Konto). Gefragt wird
-- nur mit Oberflaeche, nie zugleich mit dem Willkommen oder dem Hinweis
-- auf ein Update, nie im Kampf, nach /reload nur, wenn der Client
-- speichert (dieselbe Regel wie ui/welcome.lua - sonst kaeme die Frage
-- nach jedem Neuladen wieder).

PR.ASK_W, PR.ASK_H = 560, 214

local ask, later = nil, false

-- Hat dieser Charakter schon geantwortet (oder gewaehlt)?
function PR.Answered()
    local ui, key = K.Root(), K.CharKey()
    if not (ui and key) then return true end
    if ui.profileOf[key] then return true end
    return ui.profileAsked ~= nil and ui.profileAsked[key] == true
end

local function MarkAnswered()
    local ui, key = K.Root(), K.CharKey()
    if not (ui and key) then return end
    ui.profileAsked = ui.profileAsked or {}
    ui.profileAsked[key] = true
end

-- Soll jetzt gefragt werden? (Ohne Kampf - das prueft MaybeAsk.)
function PR.ShouldAsk()
    if later or PR.Answered() then return false end
    if not K.UIEnabled() then return false end
    local WL = WeintCodex.UIWelcome
    if WL then
        if WL.IsShown() then return false end
        if WL.ReloadBlocks() then return false end
        -- Das Willkommen kommt zuerst; gefragt wird beim naechsten Mal.
        if K.OPT_IN and not WL.Asked() then return false end
    end
    local OB = WeintCodex.Onboarding
    if OB and OB.IsShowing and OB.IsShowing() then return false end
    if ask and ask:IsShown() then return false end
    return true
end

local function Name()
    local key = K.CharKey()
    return key and key:match("^(.-)%-") or "dieser Charakter"
end

local function Label(parent, size, color)
    local fs = K.NewText(parent, size)
    fs:SetJustifyH("LEFT")
    fs:SetTextColor(unpack(WeintCodex.Colors[color]))
    return fs
end

local function BuildAsk()
    if ask then return ask end
    local f = CreateFrame("Frame", "WeintCodexProfileAsk", UIParent)
    f:SetSize(PR.ASK_W, PR.ASK_H)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
    f:SetFrameStrata("DIALOG")
    f:SetToplevel(true)
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetClampedToScreen(true)
    K.Kachel(f, { shadow = 8 })
    -- Esc schliesst - und heisst "Spaeter".
    if type(_G.UISpecialFrames) == "table" then table.insert(_G.UISpecialFrames, "WeintCodexProfileAsk") end
    f:SetScript("OnHide", function() if not f.decided then later = true end end)

    f.title = Label(f, 16, "textBright")
    f.title:SetPoint("TOPLEFT", f, "TOPLEFT", 22, -20)
    f.title:SetPoint("RIGHT", f, "RIGHT", -44, 0)
    f.body = Label(f, 12, "textMuted")
    f.body:SetPoint("TOPLEFT", f.title, "BOTTOMLEFT", 0, -10)
    f.body:SetPoint("RIGHT", f, "RIGHT", -22, 0)
    if f.body.SetWordWrap then f.body:SetWordWrap(true) end
    if f.body.SetSpacing then f.body:SetSpacing(3) end

    local function Button(text, kind, onClick)
        local b = WeintCodex.CreateButton(f, { text = text, kind = kind, height = 32, size = 12,
            backdrop = "surface2", onClick = onClick })
        return b
    end
    f.create = Button("Eigenes Profil anlegen", "primary", function() PR.AskCreate() end)
    f.pick = Button("Profil wählen …", "secondary", function() PR.AskPick() end)
    f.keep = Button("Standard behalten", "secondary", function() PR.AskKeep() end)
    f.later = Button("Später", "ghost", function() PR.AskLater() end)
    f.close = WeintCodex.CreateButton(f, { text = "×", kind = "ghost", height = 26, size = 14,
        backdrop = "surface2", tooltip = "Später – beim nächsten Einloggen wieder.", onClick = function() PR.AskLater() end })
    f.close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -10, -10)
    f.reload = K.ReloadButton(f, { text = "Jetzt neu laden", height = 32, size = 12, backdrop = "surface2",
        onClick = function() f.decided = true end })
    f.create:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 22, 20)
    f.reload:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 22, 20)
    f.later:SetPoint("LEFT", f.reload, "RIGHT", 10, 0)
    f:Hide()
    ask = f
    return f
end

-- Den Dialog in einem seiner zwei Zustaende zeigen: "frage" oder "angelegt".
function PR.ShowAsk(state, created)
    local f = BuildAsk()
    f.decided, f.state = false, state
    local name = Name()
    if state == "angelegt" then
        f.title:SetText("Profil „" .. tostring(created) .. "“ angelegt")
        f.body:SetText("Es ist eine Kopie deiner jetzigen Einstellungen und für " .. name
            .. " gewählt. Was du ab jetzt einstellst und verschiebst, gilt nur dort.\n"
            .. "Es gilt nach dem Neuladen – bis dahin läuft „" .. tostring(PR.Active()) .. "“.")
        f.create:Hide() f.pick:Hide() f.keep:Hide()
        f.reload:Show()
        f.later:Show()
    else
        f.title:SetText("Eigenes Profil für " .. name .. "?")
        f.body:SetText(name .. " nutzt „" .. tostring(PR.Chosen()) .. "“ – das teilen sich alle Charaktere ohne eigenes Profil."
            .. " Ein eigenes Profil beginnt als Kopie davon; danach ändert, was du einstellst und verschiebst, nur "
            .. name .. ".\nÄndern lässt sich das jederzeit unter /wcui profil.")
        f.reload:Hide()
        f.later:Hide()
        f.create:Show()
        f.keep:Show()
        local more = #PR.List() > 1
        f.pick:SetShown(more)
        f.keep:ClearAllPoints()
        if more then
            f.pick:ClearAllPoints()
            f.pick:SetPoint("LEFT", f.create, "RIGHT", 10, 0)
            f.keep:SetPoint("LEFT", f.pick, "RIGHT", 10, 0)
        else
            f.keep:SetPoint("LEFT", f.create, "RIGHT", 10, 0)
        end
    end
    f:Show()
    return f
end

function PR.AskCreate()
    -- Angelegt heisst gewaehlt (ui.profileOf) - damit beantwortet.
    local created = PR.New()
    if created then
        PR.ShowAsk("angelegt", created)
    elseif ask then
        ask.decided = true
        ask:Hide()
    end
    return created
end

function PR.AskPick()
    MarkAnswered()
    if ask then ask.decided = true ask:Hide() end
    local O = WeintCodex.UIOptions
    if O and O.Show and O.PageIndex then O.Show("general", O.PageIndex("general", "profile")) end
end

-- "Spaeter" (auch Esc ueber OnHide): bis zum naechsten Einloggen.
function PR.AskLater()
    later = true
    if ask then ask:Hide() end
end

function PR.AskKeep()
    MarkAnswered()
    if ask then ask.decided = true ask:Hide() end
end

function PR.MaybeAsk()
    if not PR.ShouldAsk() then return false end
    K.AfterCombat(function()
        if PR.ShouldAsk() then PR.ShowAsk("frage") end
    end)
    return true
end

-- Fuer den Prueflauf.
function PR.AskFrame() return ask end
function PR.ResetLater() later = false end

if WeintCodex.Onboarding and WeintCodex.Onboarding.OnClosed then
    WeintCodex.Onboarding.OnClosed(function() PR.MaybeAsk() end)
end

do
    local ev = CreateFrame("Frame")
    ev:RegisterEvent("PLAYER_ENTERING_WORLD")
    ev:SetScript("OnEvent", function(_, _, isInitialLogin, isReloadingUi)
        if not (isInitialLogin or isReloadingUi) then return end
        -- "Spaeter" endet mit dem Einloggen.
        if isInitialLogin then later = false end
        -- Nach dem Willkommen und dem Hinweis auf ein Update (1,5 s).
        if _G.C_Timer and _G.C_Timer.After then _G.C_Timer.After(2.5, PR.MaybeAsk) end
    end)
end
