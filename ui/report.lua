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
    f:SetFrameStrata("DIALOG")
    f:SetToplevel(true)
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetClampedToScreen(true)
    K.Kachel(f, { shadow = 8 })
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
    text = K.PlainText(text)
    report.text = text
    report.title:SetText(K.PlainText(title or "Bericht"))
    report.edit:SetText(text)
    report:Show()
    report.edit:SetFocus()
    report.edit:HighlightText()
    K.report = report
    return report
end
