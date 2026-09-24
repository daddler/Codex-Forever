--------------------------------------------------
-- WeintCodex :: Oberflaeche - die Frage beim Einloggen
--------------------------------------------------
-- SEIT 6.0.0.3 RUHT DIESE DATEI. Die Frage setzt voraus, dass der Client
-- die Antwort speichert; der Forever-Beta-Client tut das nicht. Solange
-- UIKit.OPT_IN (ui/kit.lua) false ist, fragt MaybeAsk nie, und die
-- Oberflaeche ist fuer alle an. Die Datei bleibt vollstaendig und
-- geprueft (load_test.lua spielt sie mit OPT_IN = true durch), damit sie
-- mit einer einzigen Zeile zurueckkommt.
--------------------------------------------------
-- Einmal je Konto fragt WeintCodex: "Moechtest du die WeintCodex-
-- Oberflaeche verwenden?" Die Oberflaeche ist freiwillig, und wer nicht
-- gefragt wird, erfaehrt nie, dass es sie gibt - ein Schalter, den
-- niemand findet, ist eine Funktion, die es nicht gibt.
--
-- Ja   -> Hauptschalter an, und das Angebot, sofort neu zu laden (die
--         Oberflaeche ersetzt Blizzard-Rahmen und startet erst dann).
-- Nein -> nichts wird angefasst, und der Hinweis, WO man es spaeter
--         einschaltet. Ein "Nein" ohne diesen Satz waere endgueltig,
--         obwohl es das nicht ist.
--
-- Wann: nach der Einfuehrung bzw. dem Changelog-Popup, nie darueber.
-- Zwei Fenster uebereinander sind eine Frage, die man wegklickt, ohne
-- sie gelesen zu haben.
--
-- Wer die Oberflaeche schon eingeschaltet hat (etwa ueber /wcui), wird
-- nicht mehr gefragt.
--
-- BEKANNT: Der Forever-Beta-Client speichert SavedVariables laut der
-- Vorlage (EllesmereUI) nur manchmal. Dann kommt die Frage wieder -
-- das ist der Client, nicht dieses Fenster.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIWelcome = {}

local WL = WeintCodex.UIWelcome
local K  = WeintCodex.UIKit
local C  = WeintCodex.Colors
local F  = WeintCodex.Fonts

local WIN_W, WIN_H = 500, 300

-- Ist diese Sitzung ein /reload? Gesetzt beim ersten PLAYER_ENTERING_WORLD
-- (siehe unten). Steht hier oben, weil MaybeAsk sie liest - ein `local`
-- unterhalb der Funktion waere darin eine (leere) globale Variable.
local reloadSession = false

local dimmer, win, eyebrow, title, body
local buttons = {}

local function Asked()
    local ui = K.Root()
    return ui == nil or ui.asked == true
end

local function MarkAsked()
    local ui = K.Root()
    if ui then ui.asked = true end
end

local function Say(text)
    print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " " .. text)
end

local function Close()
    if dimmer then dimmer:Hide() end
end

--------------------------------------------------
-- Aufbau (dieselbe Form wie Einfuehrung und Changelog-Popup)
--------------------------------------------------

local function Build()
    if dimmer then return end

    dimmer = CreateFrame("Frame", "WeintCodexUIWelcome", UIParent)
    dimmer:SetAllPoints(UIParent)
    dimmer:SetFrameStrata("DIALOG")
    dimmer:EnableMouse(true)
    local shade = dimmer:CreateTexture(nil, "BACKGROUND")
    shade:SetAllPoints(dimmer)
    shade:SetColorTexture(0, 0, 0, 0.6)
    dimmer:Hide()

    win = CreateFrame("Frame", nil, dimmer)
    win:SetSize(WIN_W, WIN_H)
    win:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
    win:SetFrameLevel(dimmer:GetFrameLevel() + 10)
    local bg = win:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(win)
    bg:SetColorTexture(unpack(C.surface2))
    WeintCodex.DrawBorder(win, C.borderStrong[1], C.borderStrong[2], C.borderStrong[3], 1, 1)
    local top = win:CreateTexture(nil, "ARTWORK")
    top:SetHeight(1)
    top:SetPoint("TOPLEFT", win, "TOPLEFT", 8, 0)
    top:SetPoint("TOPRIGHT", win, "TOPRIGHT", -8, 0)
    top:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.34)

    eyebrow = K.NewText(win)
    eyebrow:SetFont(F.mono, 10, "")
    eyebrow:SetTextColor(unpack(C.accent))
    eyebrow:SetPoint("TOPLEFT", win, "TOPLEFT", 28, -26)

    title = K.NewText(win)
    title:SetFont(F.sansBold, 20, "")
    title:SetTextColor(unpack(C.textBright))
    title:SetPoint("TOPLEFT", eyebrow, "BOTTOMLEFT", 0, -8)
    title:SetWidth(WIN_W - 56)
    title:SetJustifyH("LEFT")

    body = K.NewText(win)
    body:SetFont(F.sans, 13, "")
    body:SetTextColor(unpack(C.textNormal))
    body:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -14)
    body:SetWidth(WIN_W - 56)
    body:SetJustifyH("LEFT")
    body:SetJustifyV("TOP")
    body:SetSpacing(4)

    -- ESC ist hier keine Antwort: die Frage bleibt offen und kommt beim
    -- naechsten Einloggen wieder. Deshalb steht das Fenster NICHT in
    -- UISpecialFrames - ein versehentliches ESC soll nicht "Nein" heissen.
end

-- Ein Satz Knoepfe unten rechts, von rechts nach links gesetzt.
-- Jeder Knopf wird EINMAL gebaut und danach nur gezeigt oder versteckt:
-- WoW gibt Frames nie frei, und der Neuladeknopf bekommt seine Attribute
-- nur ausserhalb des Kampfes - ein neuer je Anzeige waere beides.
local byKey = {}

local function SetButtons(defs)
    for _, b in ipairs(buttons) do b:Hide() end
    wipe(buttons)
    local anchor
    for i = #defs, 1, -1 do
        local d = defs[i]
        local b = byKey[d.key]
        if not b then
            if d.reload then
                -- Neuladen ist auf Forever geschuetzt: der Klick selbst
                -- fuehrt "/reload" aus (UIKit.ReloadButton).
                b = K.ReloadButton(win, {
                    text = d.text, height = 34, size = 12, backdrop = "surface2",
                    onClick = d.onClick,
                })
            else
                b = WeintCodex.CreateButton(win, {
                    text = d.text, kind = d.kind or "secondary", height = 34, size = 12,
                    backdrop = "surface2", onClick = d.onClick,
                })
            end
            byKey[d.key] = b
        end
        b:ClearAllPoints()
        b:Show()
        if anchor then
            b:SetPoint("RIGHT", anchor, "LEFT", -10, 0)
        else
            b:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", -28, 24)
        end
        anchor = b
        b._key = d.key
        buttons[#buttons + 1] = b
    end
end

local function SetText(eb, t, text)
    eyebrow:SetText(WeintCodex.Spaced(WeintCodex.Upper(eb)))
    title:SetText(t)
    body:SetText(text)
    -- Das Fenster waechst mit dem Text: oben Rubrik und Titel (rund 90 px),
    -- unten die Knopfzeile (rund 80 px). Mit fester Hoehe liefe ein
    -- laengerer Absatz unter die Knoepfe.
    local ok, h = pcall(body.GetStringHeight, body)
    if not ok or type(h) ~= "number" then h = 0 end
    win:SetHeight(math.max(WIN_H, math.ceil(h) + 176))
end

--------------------------------------------------
-- Die drei Zustaende: Frage, "Ja", "Nein"
--------------------------------------------------

local ShowYes, ShowNo

local function ShowQuestion()
    SetText("Neu in WeintCodex",
        "Möchtest du die WeintCodex-Oberfläche verwenden?",
        "WeintCodex bringt ein eigenes, schlichtes Interface mit: Namensplaketten"
        .. " und Einheitenrahmen im Stil von WeintCodex, einstellbar bis ins"
        .. " Detail.\n\n"
        .. "Es ist ganz freiwillig. Bei „Nein“ bleibt alles, wie das Spiel es"
        .. " zeigt. Questpfeil und Komfortfunktionen kannst du in beiden Fällen"
        .. " nutzen.")
    SetButtons({
        { key = "no",  text = "Nein, danke", kind = "secondary", onClick = function() ShowNo() end },
        { key = "yes", text = "Ja, verwenden", kind = "primary", onClick = function() ShowYes() end },
    })
end

ShowYes = function()
    MarkAsked()
    K.SetUIEnabled(true)
    SetText("WeintCodex-Oberfläche",
        "Die Oberfläche ist eingeschaltet.",
        "Sie startet nach dem Neuladen — sie ersetzt Rahmen des Spiels, und das"
        .. " geht nur beim Laden.\n\n"
        .. "Ändert sich nach dem Neuladen nichts, hat der Client die Einstellung"
        .. " nicht gespeichert — ein bekannter Fehler der Forever-Beta. Dann"
        .. " schalte sie mit /wcui erneut ein und lade noch einmal neu.\n\n"
        .. "Einstellen, verschieben oder wieder ausschalten: /wcui, oder in den"
        .. " Einstellungen von WeintCodex unter „Oberfläche“.")
    SetButtons({
        { key = "later",  text = "Später", kind = "secondary", onClick = function()
            Close()
            Say("Die Oberfläche startet beim nächsten Neuladen (/reload).")
        end },
        { key = "reload", text = "Jetzt neu laden", reload = true, onClick = function()
            Close()
        end },
    })
end

ShowNo = function()
    MarkAsked()
    SetText("WeintCodex-Oberfläche",
        "Alles bleibt, wie es ist.",
        "Du kannst die WeintCodex-Oberfläche jederzeit nachträglich aktivieren:"
        .. " in den Einstellungen von WeintCodex unter „Oberfläche“"
        .. " (/wc einstellungen) oder direkt mit /wcui.\n\n"
        .. "Questpfeil und Komfortfunktionen findest du an derselben Stelle —"
        .. " sie funktionieren auch ohne die Oberfläche.")
    SetButtons({
        { key = "settings", text = "Einstellungen öffnen", kind = "secondary", onClick = function()
            Close()
            if WeintCodex.Settings and WeintCodex.Settings.Open then
                WeintCodex.Settings.Open("oberflaeche")
            end
        end },
        { key = "ok", text = "Verstanden", kind = "primary", onClick = function() Close() end },
    })
    Say("Die WeintCodex-Oberfläche kannst du jederzeit in den Einstellungen"
        .. " (/wc einstellungen → Oberfläche) oder mit /wcui aktivieren.")
end

--------------------------------------------------
-- Einstieg
--------------------------------------------------

-- Die Frage zeigen, egal ob schon gefragt (fuer den Prueflauf und fuer
-- den, der sie noch einmal sehen will).
function WL.Ask()
    Build()
    ShowQuestion()
    dimmer:Show()
end

-- Fragen, wenn es noch nicht geschehen ist und gerade nichts anderes
-- davor steht.
function WL.MaybeAsk()
    -- Ohne OPT_IN gibt es nichts zu fragen: die Oberflaeche ist fuer alle
    -- an, bis der Client wieder speichert (UIKit.OPT_IN, ui/kit.lua).
    if not K.OPT_IN then return end
    if Asked() or K.UIEnabled() then return end
    if reloadSession then return end   -- siehe unten: keine Schleife nach /reload
    if dimmer and dimmer:IsShown() then return end
    if WeintCodex.Onboarding and WeintCodex.Onboarding.IsShowing
       and WeintCodex.Onboarding.IsShowing() then
        return   -- kommt ueber OnClosed bzw. das Schliessen des Hauptfensters wieder
    end
    -- Nie mitten im Kampf: wer nach einem /reload kaempft, hat anderes zu tun.
    K.AfterCombat(function()
        if Asked() or K.UIEnabled() then return end
        WL.Ask()
    end)
end

-- Fuer den Prueflauf: die Knoepfe des Fensters nach ihrer Rolle.
function WL.Button(key)
    for _, b in ipairs(buttons) do
        if b._key == key then return b end
    end
    return nil
end
function WL.IsShown() return dimmer ~= nil and dimmer:IsShown() end
function WL.BodyText() return body and body:GetText() or "" end

if WeintCodex.Onboarding and WeintCodex.Onboarding.OnClosed then
    WeintCodex.Onboarding.OnClosed(function() WL.MaybeAsk() end)
end

-- NACH EINEM /reload WIRD NICHT GEFRAGT, nur beim echten Einloggen.
--
-- Mit 6.0.0.1 gemeldet: "Ja, verwenden" -> "Jetzt neu laden" -> die
-- Frage kam wieder, immer wieder. Der Forever-Beta-Client hatte die
-- Antwort nicht gespeichert (siehe WeintCodex.SaveHealth in
-- core/main.lua). Speichern kann dieses Addon nicht erzwingen - aber die
-- Schleife darf es nicht bauen: wer gerade neu geladen hat, hat die
-- Frage fast immer eben beantwortet. Beim naechsten echten Einloggen
-- kommt sie wieder, falls die Antwort verloren ging.

function WL.IsReloadSession() return reloadSession end

local hooked = false
local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:SetScript("OnEvent", function(_, _, isInitialLogin, isReloadingUi)
    -- Nur das erste PLAYER_ENTERING_WORLD einer Sitzung traegt eins der
    -- beiden Flags; Zonenwechsel tragen keins.
    if not (isInitialLogin or isReloadingUi) then return end
    reloadSession = isReloadingUi and true or false

    -- Schliesst jemand das Hauptfenster samt Popup, ohne das Popup selbst
    -- wegzuklicken, soll die Frage trotzdem kommen.
    local main = WeintCodex.MainFrame
    if not hooked and main and main.HookScript then
        hooked = true
        main:HookScript("OnHide", function() WL.MaybeAsk() end)
    end

    -- Das Einfuehrungs-Popup wird beim Anmelden geoeffnet; einen
    -- Augenblick warten, damit es sicher steht, bevor gefragt wird.
    if not reloadSession and _G.C_Timer and _G.C_Timer.After then
        _G.C_Timer.After(1.5, WL.MaybeAsk)
    end
end)
