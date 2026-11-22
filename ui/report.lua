--------------------------------------------------
-- WeintCodex :: Oberflaeche - Bericht zum Kopieren (6.10.2.0)
--------------------------------------------------
-- /wcui fenster und /wcui pruefen schrieben bis 6.10.1.0 in den Chat: der
-- Bericht kam als Bildschirmfoto an, lange Zeilen brachen um, und nach 24
-- Bildern war Schluss. Jetzt ein Fenster mit einem Textfeld ohne Grenze:
-- markiert, Strg+C, in den Discord oder ins Gespraech mit Claude.
--
-- Eigenes Fenster an UIParent (der Export-Dialog in core/ui.lua haengt am
-- Hauptfenster des Codex und verschwindet mit ihm). Nur lesen: wer im Feld
-- tippt, bekommt den Bericht zurueck. Farbcodes und Symbole fallen weg -
-- kopiert waeren sie Zeichensalat ("|cff7C6CFF").
--------------------------------------------------

WeintCodex = WeintCodex or {}

local K = WeintCodex.UIKit
local C = WeintCodex.Colors
local F = WeintCodex.Fonts

K.REPORT_W, K.REPORT_H = 640, 440

-- Text ohne Farbcodes und Symbole - so, wie er kopiert ankommen soll.
function K.PlainText(s)
    if type(s) ~= "string" then return tostring(s) end
    s = s:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    s = s:gsub("|T.-|t", ""):gsub("|A.-|a", "")
    return s
end

local report

local function Build()
    local f = CreateFrame("Frame", "WeintCodexReport", UIParent)
    f:SetSize(K.REPORT_W, K.REPORT_H)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
    -- Ueber den Einstellungen (/wcui, Schicht DIALOG): sonst lag der
    -- Export dahinter (6.28.0.1, Beta-Test).
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetToplevel(true)
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetClampedToScreen(true)
    -- 1.0.8.13: deckend, auch im Aussehen „Transparent“ (ein Bericht wird gelesen).
    f.kachel = K.Kachel(f, { shadow = 8, solid = true })
    -- Esc schliesst, wie jedes Fenster des Spiels.
    if type(_G.UISpecialFrames) == "table" then table.insert(_G.UISpecialFrames, "WeintCodexReport") end

    local title = K.NewText(f, 14)
    title:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -14)
    title:SetPoint("RIGHT", f, "RIGHT", -16, 0)
    title:SetJustifyH("LEFT")
    title:SetTextColor(unpack(C.textBright))
    f.title = title

    local hint = K.NewText(f, 11)
    hint:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    hint:SetTextColor(unpack(C.textMuted))
    hint:SetText("Alles ist markiert: Strg+C kopiert. Esc schließt.")
    f.hint = hint

    local box = CreateFrame("Frame", nil, f)
    box:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -56)
    box:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -14, 52)
    local bg = box:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(box)
    bg:SetColorTexture(unpack(C.bgDark))
    K.Border(box, 1, 0, 0, 0, 1, "BORDER")

    local scroll = CreateFrame("ScrollFrame", nil, box, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", box, "TOPLEFT", 6, -6)
    scroll:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -26, 6)

    local eb = CreateFrame("EditBox", nil, scroll)
    eb:SetMultiLine(true)
    eb:SetMaxLetters(0)
    eb:SetAutoFocus(false)
    eb:SetWidth(K.REPORT_W - 28 - 32)
    K.SetFont(eb, 11)
    if F and F.mono and eb.SetFont then pcall(eb.SetFont, eb, F.mono, 11, "") end
    eb:SetTextColor(unpack(C.textNormal))
    scroll:SetScrollChild(eb)
    -- Nur lesen: getippt wird nichts, der Bericht kommt zurueck.
    eb:SetScript("OnTextChanged", function(self, user)
        if user then
            self:SetText(f.text or "")
            self:HighlightText()
        end
    end)
    eb:SetScript("OnEscapePressed", function() f:Hide() end)
    f.edit = eb

    local close = WeintCodex.CreateButton(f, {
        text = "Schließen", kind = "secondary", width = 120, height = 28,
        onClick = function() f:Hide() end,
    })
    close:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -14, 14)
    local mark = WeintCodex.CreateButton(f, {
        text = "Alles markieren", kind = "primary", width = 150, height = 28,
        onClick = function() eb:SetFocus() eb:HighlightText() end,
    })
    mark:SetPoint("RIGHT", close, "LEFT", -8, 0)
    f.mark, f.close = mark, close
    return f
end

-- Zeigt `lines` (Liste oder Text) unter `title`, alles markiert.
function K.ShowReport(title, lines)
    report = report or Build()
    local text = type(lines) == "table" and table.concat(lines, "\n") or tostring(lines or "")
    -- Laeuft gerade ein Befehl (K.RunCommand), merkt er sich, dass er
    -- schon einen Bericht hat - seine Chatzeilen kommen dann oben dazu.
    local cap = K.capture
    if cap then
        cap.report = true
        if #cap.lines > 0 then
            text = table.concat(cap.lines, "\n") .. "\n\n" .. text
            cap.lines = {}
        end
    end
    text = K.PlainText(text)
    report.text = text
    report.title:SetText(K.PlainText(title or "Bericht"))
    report.edit:SetText(text)
    -- Fehlerfenster (ui/errors.lua) setzen Hinweis und Knopf selbst; jeder
    -- andere Bericht bekommt den Standard zurueck.
    if report.hint then report.hint:SetText("Alles ist markiert: Strg+C kopiert. Esc schließt.") end
    if report._wcErrors then
        report._wcErrors = nil
        local ER = WeintCodex.UIErrors
        if ER and ER.sendButton then ER.sendButton:Hide() end
    end
    report:Show()
    if report.Raise then report:Raise() end
    report.edit:SetFocus()
    report.edit:HighlightText()
    K.report = report
    return report
end

--------------------------------------------------
-- Ausgabe der Befehle im Fenster (1.0.8.13)
--------------------------------------------------
-- Wunsch: "Alle Befehle, die es in Codex gibt, sollen nun, wenn sie eine
-- Ausgabe geben, in einem Popup kommen wie wcui pruefen."
--
-- Jede Ausgabe der Befehle lief ueber das globale print (139 Stellen).
-- Statt jede umzubauen, faengt K.RunCommand print ein, solange der Befehl
-- LAEUFT, und zeigt das Gesammelte danach in diesem Fenster:
--   * kein print            -> kein Fenster (Befehle, die nur etwas oeffnen)
--   * Befehl oeffnet selbst einen Bericht -> seine Zeilen stehen oben darin
--   * Fehler im Befehl      -> print ist wieder das des Spiels, Fehler geht weiter
-- Was ein Befehl SPAETER schreibt (nach einem Timer, nach einer Messung),
-- landet weiter im Chat - dann laeuft er nicht mehr.
-- Ersetzt wird print nur fuer die Dauer des Aufrufs, und nur, wenn es noch
-- unseres ist (ein anderes Addon, das print waehrenddessen tauscht, bleibt).
K.COMMAND_PREFIX = "^%s*%[WeintCodex%]%s*"

function K.RunCommand(title, fn, ...)
    if K.capture then return fn(...) end          -- verschachtelt: aeusserer sammelt
    local cap = { lines = {} }
    local orig = _G.print
    local function grab(...)
        local parts = {}
        for i = 1, select("#", ...) do parts[#parts + 1] = tostring((select(i, ...))) end
        local line = K.PlainText(table.concat(parts, " ")):gsub(K.COMMAND_PREFIX, "")
        cap.lines[#cap.lines + 1] = line
    end
    K.capture = cap
    _G.print = grab
    local ok, err = pcall(fn, ...)
    if _G.print == grab then _G.print = orig end
    K.capture = nil
    if not ok then _G.error(err, 0) end
    if #cap.lines > 0 then
        if cap.report and report and report:IsShown() then
            -- Nach dem Bericht noch geschrieben: oben anfuegen.
            K.ShowReport(report.title:GetText(), { table.concat(cap.lines, "\n"), "", report.text or "" })
        else
            K.ShowReport(title, cap.lines)
        end
    end
    return cap
end
