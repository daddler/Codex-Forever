--------------------------------------------------
-- WeintCodex :: "Was ist aus?" (1.0.8.11)
--------------------------------------------------
-- Wunsch: "Unter Allgemein einen Button, der auflistet, was zur Zeit nicht
-- aktiviert ist - und in der Auflistung kann man es auch aktivieren."
--
-- Gelistet wird, was eine eigene Funktion ist und gerade aus:
--   * die Oberflaeche selbst (Hauptschalter), wenn sie aus ist - dann stehen
--     ihre Module nicht einzeln da, sie liefen ohne sie ohnehin nicht;
--   * Module (Schalter oben rechts im Einstellungsfenster);
--   * die HAUPTschalter auf den Seiten laufender Module: Schalter, die von
--     keinem anderen abhaengen (ohne `disabled`) und nicht unter
--     "Erweitert" stehen. Unterschalter ("im Kampf ausblenden",
--     "auch allein") waeren Rauschen - sie stehen auf ihrer Seite.
-- Schalter, die etwas ABschalten ("... ausblenden", "... abschalten"),
-- gehoeren nicht in eine Liste von Funktionen zum Einschalten; ebenso
-- Einschraenkungen ("Nur ...", "Auch ...", "Für alle ...").
-- 1.0.8.14 (Wunsch: "die neuen Funktionen muessen auch in Ausgeschaltetes
-- zeigen drin sein"): ein Schalter mit `feature = true` ist eine eigene
-- Funktion, auch wenn er mit "Nur" beginnt ("Nur Quests des Gebiets").
--
-- "Einschalten" setzt genau den Schalter, den die Seite auch setzt (gleiche
-- Lese-/Schreibwege aus dem Mitschrieb der Einstellungen, O.SearchIndex);
-- was ein Neuladen braucht, sagt das Fenster und bietet den Knopf dafuer.
-- Klick auf eine Zeile oeffnet ihre Seite.
--------------------------------------------------

local K = WeintCodex.UIKit
local C = WeintCodex.Colors

WeintCodex.UIOffList = {}
local OL = WeintCodex.UIOffList

OL.ROW_H = 46
-- Beschriftungen, die etwas abschalten - keine Funktion zum Einschalten.
OL.NEGATIVE = { "ausblenden", "abschalten", "verbergen", "verstecken", "unterdruecken", "nicht ", "ohne " }

local function O() return WeintCodex.UIOptions end
local function ST() return WeintCodex.SearchText end

-- Beschriftungen, die eine Funktion nur einschraenken oder ausweiten
-- ("Nur volle Stapel", "Auch die der anderen Fraktion", "Für alle
-- Charaktere") - Feinheiten, keine eigene Funktion.
OL.QUALIFIER = { "nur ", "auch ", "fuer alle " }

local function Negative(label)
    local f = ST() and ST().Fold(label) or tostring(label):lower()
    for _, w in ipairs(OL.NEGATIVE) do
        if f:find(w, 1, true) then return true end
    end
    for _, w in ipairs(OL.QUALIFIER) do
        if f:sub(1, #w) == w then return true end
    end
    return false
end

local function ModTitle(key)
    local m = K.Module(key)
    return (m and m.title) or key
end

-- Wert eines mitgeschriebenen Schalters (true/false) oder nil.
local function ToggleValue(e)
    local spec = e.spec
    local ok, v
    if spec.get then ok, v = pcall(spec.get)
    elseif spec.key then ok, v = pcall(K.Get, e.store, spec.key)
    else return nil end
    if not ok then return nil end
    if K.Plain then v = K.Plain(v) end
    return v and true or false
end

local function ToggleOn(e)
    local spec = e.spec
    if spec.set then pcall(spec.set, true)
    elseif spec.key then K.Set(e.store, spec.key, true)
    else return false end
    if spec.reload then K.MarkReload() end
    return true
end

-- Alles, was gerade aus ist: { kind, label, path, text, on = fn, open = fn }.
function OL.Collect()
    local out = {}
    local o = O()
    -- Die Oberflaeche selbst.
    local uiOff = K.OPT_IN and not K.UIEnabled()
    if uiOff then
        out[#out + 1] = { kind = "ui", label = "WeintCodex-Oberfläche",
            path = "Allgemein · Hauptschalter",
            text = "Plaketten, Rahmen, Leisten, Karte, Chat, Taschen und Fenster von WeintCodex. Wirkt nach dem Neuladen.",
            reload = true,
            on = function() K.SetUIEnabled(true) end,
            open = function() if o and o.Show then o.Show("general", 1) end end }
    end
    -- Module.
    for _, key in ipairs(K.order or {}) do
        local m = K.Module(key)
        if key ~= "general" and m and not (uiOff and m.group == "ui") and not K.ModuleEnabled(key) then
            out[#out + 1] = { kind = "module", label = m.title or key, path = "Modul",
                text = m.description or m.subtitle,
                reload = (m.group == "ui" or m.reload) and true or false,
                on = function() K.SetModuleEnabled(key, true) end,
                open = function() if o and o.Show then o.Show(key, 1) end end }
        end
    end
    -- Hauptschalter auf den Seiten laufender Module.
    if o and o.SearchIndex then
        local ok, idx = pcall(o.SearchIndex)
        local seen = {}
        for _, e in ipairs(ok and idx or {}) do
            local spec = e.spec
            if type(spec) == "table" and spec.type == "toggle" and not spec.disabled and not e.advanced
               and (spec.key or spec.get) and (spec.feature or not Negative(e.label))
               and e.module ~= "general" and K.ModuleEnabled(e.module)
               and not (uiOff and K.Module(e.module) and K.Module(e.module).group == "ui") then
                local id = e.store .. "/" .. tostring(spec.key or e.label)
                if not seen[id] and ToggleValue(e) == false then
                    seen[id] = true
                    out[#out + 1] = { kind = "toggle", label = e.label,
                        path = ModTitle(e.module) .. " › " .. tostring(e.pageLabel or ""),
                        text = e.description, reload = spec.reload and true or false,
                        on = function() ToggleOn(e) end,
                        open = function() if o.OpenHit then o.OpenHit(e) end end }
                end
            end
        end
    end
    return out
end

--------------------------------------------------
-- Fenster
--------------------------------------------------

local win

local function Btn(parent, text, width)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(width or 96, 24)
    b.bg = b:CreateTexture(nil, "BACKGROUND")
    b.bg:SetAllPoints(b)
    b.bg:SetColorTexture(unpack(C.surface3))
    b.text = K.NewText(b, 11, "OVERLAY")
    b.text:SetPoint("CENTER", b, "CENTER", 0, 0)
    b.text:SetTextColor(unpack(C.textBright))
    b.text:SetText(text)
    b:SetScript("OnEnter", function(self) self.bg:SetColorTexture(unpack(C.borderStrong)) end)
    b:SetScript("OnLeave", function(self) self.bg:SetColorTexture(unpack(C.surface3)) end)
    return b
end

local function Row(i)
    local r = win.rows[i]
    if r then return r end
    r = CreateFrame("Button", nil, win.body)
    r:SetHeight(OL.ROW_H - 4)
    r:SetPoint("TOPLEFT", win.body, "TOPLEFT", 0, -(i - 1) * OL.ROW_H)
    r:SetPoint("RIGHT", win.body, "RIGHT", 0, 0)
    -- Hover-Fläche HINTER dem Text: die Ebene "HIGHLIGHT" liegt ueber
    -- OVERLAY und hat Titel und Pfad verdeckt (1.0.8.12).
    r.hl = r:CreateTexture(nil, "BACKGROUND")
    r.hl:SetAllPoints(r)
    r.hl:SetColorTexture(unpack(C.surface2))
    r.hl:Hide()
    r:SetScript("OnEnter", function(self) self.hl:Show() end)
    r:SetScript("OnLeave", function(self) self.hl:Hide() end)
    r.title = K.NewText(r, 12, "OVERLAY")
    r.title:SetPoint("TOPLEFT", r, "TOPLEFT", 6, -5)
    r.title:SetPoint("RIGHT", r, "RIGHT", -112, 0)
    r.title:SetJustifyH("LEFT")
    r.title:SetTextColor(unpack(C.textBright))
    r.sub = K.NewText(r, 10, "OVERLAY")
    r.sub:SetPoint("TOPLEFT", r.title, "BOTTOMLEFT", 0, -3)
    r.sub:SetPoint("RIGHT", r, "RIGHT", -112, 0)
    r.sub:SetJustifyH("LEFT")
    r.sub:SetTextColor(unpack(C.textMuted))
    if r.sub.SetWordWrap then r.sub:SetWordWrap(false) end
    r.go = Btn(r, "Einschalten", 96)
    r.go:SetPoint("RIGHT", r, "RIGHT", -6, 0)
    r.go:SetScript("OnClick", function(self)
        local item = self:GetParent().item
        if item and item.on then
            item.on()
            OL.Fill()
        end
    end)
    r:SetScript("OnClick", function(self) if self.item and self.item.open then self.item.open() end end)
    if r.title.SetWordWrap then r.title:SetWordWrap(false) end
    win.rows[i] = r
    return r
end

local function Build()
    if win then return win end
    win = CreateFrame("Frame", "WeintCodexOffList", UIParent)
    win:SetSize(460, 520)
    win:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
    win:SetFrameStrata("FULLSCREEN_DIALOG")
    win:SetClampedToScreen(true)
    win:EnableMouse(true)
    win.kachel = K.Kachel(win, { shadow = 6, solid = true })   -- auch im Aussehen „Transparent“ deckend
    win.head = K.NewText(win, 14, "OVERLAY")
    win.head:SetPoint("TOPLEFT", win, "TOPLEFT", 14, -12)
    win.head:SetTextColor(unpack(C.textBright))
    win.head:SetText("Was ist aus?")
    if K.DragToMove then K.DragToMove(win, "offlist") end
    local close = CreateFrame("Button", nil, win)
    close:SetSize(24, 22)
    close:SetPoint("TOPRIGHT", win, "TOPRIGHT", -6, -6)
    local x = K.NewText(close, 14, "OVERLAY")
    x:SetPoint("CENTER", close, "CENTER", 0, 0)
    x:SetTextColor(unpack(C.textMuted))
    x:SetText("\195\151")
    close:SetScript("OnClick", function() win:Hide() end)

    win.count = K.NewText(win, 11, "OVERLAY")
    win.count:SetPoint("TOPLEFT", win.head, "BOTTOMLEFT", 0, -6)
    win.count:SetPoint("RIGHT", win, "RIGHT", -14, 0)
    win.count:SetJustifyH("LEFT")
    win.count:SetTextColor(unpack(C.textMuted))

    -- Filter
    local eb = CreateFrame("EditBox", nil, win)
    eb:SetHeight(24)
    eb:SetPoint("TOPLEFT", win, "TOPLEFT", 14, -58)
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
    hint:SetText("Filtern, z. B. „Karte“, „Kampf“, „Taschen“")
    eb:SetScript("OnTextChanged", function(self)
        hint:SetShown((self:GetText() or "") == "")
        OL.Fill()
    end)
    eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() win:Hide() end)
    eb:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    win.filter = eb

    win.scroll, win.body = WeintCodex.CreateScrollArea(win, 14, -92, 432, 370, true)
    win.empty = K.NewText(win, 11, "OVERLAY")
    win.empty:SetPoint("TOPLEFT", win, "TOPLEFT", 20, -100)
    win.empty:SetPoint("RIGHT", win, "RIGHT", -14, 0)
    win.empty:SetJustifyH("LEFT")
    win.empty:SetTextColor(unpack(C.textDim))

    -- Neuladen, wenn etwas erst danach wirkt.
    win.reloadNote = K.NewText(win, 11, "OVERLAY")
    win.reloadNote:SetPoint("BOTTOMLEFT", win, "BOTTOMLEFT", 14, 18)
    win.reloadNote:SetTextColor(unpack(C.gold or C.textBright))
    win.reloadNote:SetText("Einiges wirkt erst nach dem Neuladen.")
    win.reload = Btn(win, "Jetzt neu laden", 120)
    win.reload:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", -14, 12)
    if WeintCodex.AttachReload then WeintCodex.AttachReload(win.reload) end

    win.rows = {}
    win:Hide()
    if type(_G.UISpecialFrames) == "table" then table.insert(_G.UISpecialFrames, "WeintCodexOffList") end
    OL.win = win
    return win
end

-- Liste neu fuellen (nach jedem Einschalten und beim Filtern).
function OL.Fill()
    local w = Build()
    local all = OL.Collect()
    local q = ST() and ST().Parse(w.filter:GetText() or "")
    local list = {}
    for _, item in ipairs(all) do
        if not q or ST().Matches(q, item.label .. " " .. item.path .. " " .. tostring(item.text or "")) then
            list[#list + 1] = item
        end
    end
    for i, item in ipairs(list) do
        local r = Row(i)
        r.item = item
        r.title:SetText(item.label)
        r.sub:SetText(item.path .. (item.reload and " · nach dem Neuladen" or "")
            .. ((item.text and item.text ~= "") and (" – " .. item.text) or ""))
        r:Show()
    end
    for i = #list + 1, #w.rows do w.rows[i].item = nil w.rows[i]:Hide() end
    w.body:SetHeight(math.max(1, #list * OL.ROW_H))
    w.count:SetText(#all == 0 and "Alles ist an." or (#all .. (#all == 1 and " Funktion ist aus" or " Funktionen sind aus")
        .. (#list ~= #all and (", " .. #list .. " passen zum Filter") or "") .. ". Klick auf eine Zeile öffnet ihre Seite."))
    if #list == 0 then
        w.empty:SetText(#all == 0 and "Alles, was WeintCodex kann, ist eingeschaltet." or "Nichts passt zu diesem Filter.")
        w.empty:Show()
    else
        w.empty:Hide()
    end
    local pending = K.ReloadPending and K.ReloadPending()
    w.reloadNote:SetShown(pending and true or false)
    w.reload:SetShown(pending and true or false)
    return list, all
end

function OL.Show()
    local w = Build()
    w.filter:SetText("")
    OL.Fill()
    w:Show()
    if w.Raise then w:Raise() end
    return w
end
