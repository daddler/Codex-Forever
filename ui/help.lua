--------------------------------------------------
-- WeintCodex :: Hilfe - "?" je Seite und Hilfesuche (1.0.5.5)
--------------------------------------------------
-- Wunsch (Spieler): die Tour erzaehlt alles am Stueck, beim vierten Punkt
-- ist der erste vergessen; gesucht wird minutenlang in den Einstellungen.
-- Darum:
--   * "?" im Codex-Fenster und im Einstellungsfenster: zwei, drei Saetze nur
--     zur offenen Seite (data/help.lua).
--   * /wc hilfe [Wort] (auch /wcui hilfe): ein Fenster mit Suchfeld, das
--     Hilfetexte UND Einstellungen durchsucht; jedes Wort zaehlt einzeln,
--     Schlagwoerter ("Aggro" -> Bedrohung) helfen mit. Klick oeffnet die
--     Seite.
-- Laeuft ohne Hauptschalter (wie die Einstellungen).
--------------------------------------------------

local K = WeintCodex.UIKit
local C = WeintCodex.Colors
local F = WeintCodex.Fonts

WeintCodex.UIHelp = {}
local H = WeintCodex.UIHelp
local D = WeintCodex.HelpData or { PAGES = {}, SYNONYMS = {} }
H.MAX = 8

local function O() return WeintCodex.UIOptions end
local function Fold(t)
    local o = O()
    if o and o.Fold then return o.Fold(t) end
    return tostring(t or ""):lower()
end

-- Seite oeffnen, zu der ein Hilfetext gehoert.
function H.OpenKey(key)
    if type(key) ~= "string" then return false end
    local tab = key:match("^nav:(.+)$")
    if tab then
        if WeintCodex.MainFrame and WeintCodex.Navigation and WeintCodex.Navigation.GoToTab then
            WeintCodex.MainFrame:Show()
            WeintCodex.Navigation.GoToTab(tab)
            return true
        end
        return false
    end
    local mod, page = key:match("^([^/]+)/(.+)$")
    local o = O()
    if mod and o and o.Show then
        o.Show(mod, o.PageIndex and o.PageIndex(mod, page) or 1)
        return true
    end
    return false
end

-- Hilfetexte und Einstellungen zu `text`: { title, text, path, open }.
function H.Search(text, limit)
    limit = limit or H.MAX
    local out = {}
    local o = O()
    local q = Fold(text):gsub("^%s+", ""):gsub("%s+$", "")
    if #q < 2 then return out end
    local match = o and o.MatchWords
    if not match then return out end
    local keys = {}
    for k in pairs(D.PAGES) do keys[#keys + 1] = k end
    table.sort(keys)
    for _, k in ipairs(keys) do
        local p = D.PAGES[k]
        local hay = Fold(p.title) .. " " .. Fold(p.text) .. " " .. Fold(p.words)
        if match(hay, q) then
            out[#out + 1] = { key = k, title = p.title, text = p.text, path = k:find("^nav:") and "Codex-Fenster" or "Einstellungen",
                              open = function() H.OpenKey(k) end }
            if #out >= limit then return out end
        end
    end
    if o and o.Search then
        for _, e in ipairs(o.Search(text, limit - #out)) do
            local m = K.Module(e.module)
            out[#out + 1] = { title = e.label, text = e.description,
                              path = "Einstellung · " .. ((m and m.title) or e.module) .. " › " .. tostring(e.pageLabel or ""),
                              open = function() if o.OpenHit then o.OpenHit(e) end end }
        end
    end
    return out
end

-- Welche Seite ist offen? Einstellungsfenster vor Codex-Fenster.
function H.CurrentKey(prefer)
    local o = O()
    if prefer ~= "codex" and o and o.Where and o.IsOpen and o.IsOpen() then
        local w = o.Where()
        local m = K.Module(w.module)
        local def = m and m.pages and m.pages[w.page]
        if def and def.key then return w.module .. "/" .. def.key end
        return w.module .. "/allgemein"
    end
    local tab = WeintCodex.Navigation and WeintCodex.Navigation.CurrentTab and WeintCodex.Navigation.CurrentTab()
    if tab then return "nav:" .. tab end
    return nil
end

--------------------------------------------------
-- Fenster
--------------------------------------------------

local win
local ROW_H = 44

local function Row(i)
    local r = win.rows[i]
    if r then return r end
    r = CreateFrame("Button", nil, win)
    r:SetHeight(ROW_H - 4)
    r:SetPoint("TOPLEFT", win.list, "TOPLEFT", 0, -(i - 1) * ROW_H)
    r:SetPoint("RIGHT", win, "RIGHT", -12, 0)
    local hl = r:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints(r)
    hl:SetColorTexture(unpack(C.surface2))
    r.title = K.NewText(r, 12, "OVERLAY")
    r.title:SetPoint("TOPLEFT", r, "TOPLEFT", 6, -4)
    r.title:SetPoint("RIGHT", r, "RIGHT", -6, 0)
    r.title:SetJustifyH("LEFT")
    r.title:SetWordWrap(false)
    r.title:SetTextColor(unpack(C.textBright))
    r.sub = K.NewText(r, 10, "OVERLAY")
    r.sub:SetPoint("TOPLEFT", r.title, "BOTTOMLEFT", 0, -3)
    r.sub:SetPoint("RIGHT", r, "RIGHT", -6, 0)
    r.sub:SetJustifyH("LEFT")
    r.sub:SetWordWrap(false)
    r.sub:SetTextColor(unpack(C.textMuted))
    r:SetScript("OnClick", function(self)
        if self.hit and self.hit.open then
            if self.hit.key then H.ShowKey(self.hit.key) end
            self.hit.open()
        end
    end)
    win.rows[i] = r
    return r
end

local function Build()
    if win then return win end
    win = CreateFrame("Frame", "WeintCodexHelp", UIParent)
    win:SetSize(420, 470)
    win:SetPoint("CENTER", UIParent, "CENTER", 0, 60)
    win:SetFrameStrata("FULLSCREEN_DIALOG")
    win:SetClampedToScreen(true)
    win:EnableMouse(true)
    win.kachel = K.Kachel(win, { shadow = 6 })
    win.head = K.NewText(win, 14, "OVERLAY")
    win.head:SetPoint("TOPLEFT", win, "TOPLEFT", 14, -12)
    win.head:SetTextColor(unpack(C.textBright))
    win.head:SetText("Hilfe")
    if K.DragToMove then K.DragToMove(win, "help") end
    local close = CreateFrame("Button", nil, win)
    close:SetSize(24, 22)
    close:SetPoint("TOPRIGHT", win, "TOPRIGHT", -6, -6)
    local x = K.NewText(close, 14, "OVERLAY")
    x:SetPoint("CENTER", close, "CENTER", 0, 0)
    x:SetTextColor(unpack(C.textMuted))
    x:SetText("\195\151")
    close:SetScript("OnClick", function() win:Hide() end)

    -- Hilfe zur Seite
    win.pageTitle = K.NewText(win, 12, "OVERLAY")
    win.pageTitle:SetPoint("TOPLEFT", win.head, "BOTTOMLEFT", 0, -12)
    win.pageTitle:SetPoint("RIGHT", win, "RIGHT", -14, 0)
    win.pageTitle:SetJustifyH("LEFT")
    win.pageTitle:SetTextColor(unpack(C.accent or C.textBright))
    win.pageText = K.NewText(win, 11, "OVERLAY")
    win.pageText:SetPoint("TOPLEFT", win.pageTitle, "BOTTOMLEFT", 0, -6)
    win.pageText:SetPoint("RIGHT", win, "RIGHT", -14, 0)
    win.pageText:SetJustifyH("LEFT")
    win.pageText:SetJustifyV("TOP")
    win.pageText:SetHeight(70)
    win.pageText:SetTextColor(unpack(C.textNormal))

    -- Suchfeld
    local eb = CreateFrame("EditBox", nil, win)
    eb:SetHeight(24)
    eb:SetPoint("TOPLEFT", win, "TOPLEFT", 14, -150)
    eb:SetPoint("RIGHT", win, "RIGHT", -14, 0)
    eb:SetAutoFocus(false)
    K.SetFont(eb, 12)
    if eb.SetTextInsets then eb:SetTextInsets(8, 8, 0, 0) end
    local bg = eb:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(eb)
    bg:SetColorTexture(unpack(C.surface3))
    local hint = K.NewText(eb, 12, "OVERLAY")
    hint:SetPoint("LEFT", eb, "LEFT", 8, 0)
    hint:SetTextColor(unpack(C.textFaint))
    hint:SetText("Wonach suchst du? z. B. „Aggro“, „Taschen sortieren“")
    eb:SetScript("OnTextChanged", function(self)
        local t = self:GetText() or ""
        hint:SetShown(t == "")
        H.Fill(t)
    end)
    eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() win:Hide() end)
    eb:SetScript("OnEnterPressed", function(self)
        local r = win.rows[1]
        if r and r:IsShown() and r.hit then r:Click() else self:ClearFocus() end
    end)
    win.search = eb

    win.list = CreateFrame("Frame", nil, win)
    win.list:SetPoint("TOPLEFT", eb, "BOTTOMLEFT", 0, -10)
    win.list:SetSize(10, 10)
    win.empty = K.NewText(win, 11, "OVERLAY")
    win.empty:SetPoint("TOPLEFT", win.list, "TOPLEFT", 6, -4)
    win.empty:SetPoint("RIGHT", win, "RIGHT", -14, 0)
    win.empty:SetJustifyH("LEFT")
    win.empty:SetTextColor(unpack(C.textDim))
    win.rows = {}
    win:Hide()
    if type(_G.UISpecialFrames) == "table" then table.insert(_G.UISpecialFrames, "WeintCodexHelp") end
    H.win = win
    return win
end

-- Treffer in die Liste.
function H.Fill(text)
    local w = Build()
    local hits = H.Search(text, H.MAX)
    for i, hit in ipairs(hits) do
        local r = Row(i)
        r.hit = hit
        r.title:SetText(hit.title or "")
        r.sub:SetText((hit.text and hit.text ~= "" and hit.text) or hit.path or "")
        r:Show()
    end
    for i = #hits + 1, #w.rows do w.rows[i].hit = nil w.rows[i]:Hide() end
    local q = Fold(text):gsub("%s", "")
    if #hits == 0 then
        w.empty:SetText(#q < 2 and "Ein Wort tippen – Treffer aus Hilfe und Einstellungen erscheinen hier."
            or "Nichts gefunden. Ein anderes Wort probieren, z. B. eines aus dem Spiel.")
        w.empty:Show()
    else
        w.empty:Hide()
    end
    return hits
end

-- Hilfe zu einer Seite oben im Fenster.
function H.ShowKey(key)
    local w = Build()
    local p = key and D.PAGES[key]
    if p then
        w.pageTitle:SetText(p.title)
        w.pageText:SetText(p.text)
    else
        w.pageTitle:SetText("Hilfe")
        w.pageText:SetText("Zu dieser Seite gibt es noch keinen Hilfetext. Unten kannst du nach einem Stichwort suchen.")
    end
    return p ~= nil
end

-- Fenster zeigen: mit Suchtext (Befehl) oder mit der Hilfe zur offenen Seite ("?").
function H.Show(text, prefer)
    local w = Build()
    H.ShowKey(H.CurrentKey(prefer))
    w.search:SetText(text or "")
    H.Fill(text or "")
    w:Show()
    if text and text ~= "" then w.search:SetFocus() end
    return w
end

-- Ein "?"-Knopf (Einstellungsfenster, Codex-Fenster).
function H.Button(parent, prefer)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(24, 24)
    local t = K.NewText(b, 14, "OVERLAY")
    t:SetPoint("CENTER", b, "CENTER", 0, 0)
    t:SetTextColor(unpack(C.textMuted))
    t:SetText("?")
    b:SetScript("OnClick", function() H.Show(nil, prefer) end)
    b:SetScript("OnEnter", function(self)
        t:SetTextColor(unpack(C.textBright))
        if _G.GameTooltip then
            _G.GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
            _G.GameTooltip:SetText("Hilfe zu dieser Seite und Suche")
            _G.GameTooltip:Show()
        end
    end)
    b:SetScript("OnLeave", function()
        t:SetTextColor(unpack(C.textMuted))
        if _G.GameTooltip then _G.GameTooltip:Hide() end
    end)
    return b
end

-- "?" im Codex-Fenster: core/ui.lua legt den Platz an (WeintCodex.HelpSlot).
if WeintCodex.HelpSlot then
    local b = H.Button(WeintCodex.HelpSlot, "codex")
    b:SetAllPoints(WeintCodex.HelpSlot)
    H.codexButton = b
end
