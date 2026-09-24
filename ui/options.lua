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
-- Seitenleiste: seit 6.0.0.3 elf Eintraege. 38 hoch, 40 Schritt - der
-- Prueflauf haelt die belegte Hoehe gegen die Fensterhoehe (nichts in der
-- Seitenleiste darf rollen muessen).
local SIDE_ROW_H, SIDE_ROW_STEP = 38, 40
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
        and "Ein eigenes, schlichtes Interface zusätzlich zu WeintCodex — ganz freiwillig. Aus bleibt alles, wie das Spiel es zeigt; die Komfortfunktionen gehen trotzdem."
        or "Das Interface von WeintCodex: Plaketten, Rahmen, Leisten, Karte, Chat, Taschen und Schadensanzeige. Jedes Modul lässt sich einzeln abschalten.",
    defaults = {
        font = "plexsemi",
        outline = "thin",
        barStyle = "flat",
        windowScale = 100,
    },
    OnSetting = function(key)
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
            local unlock = { type = "button", label = "Rahmen entsperren",
                text = function() return K.IsUnlocked() and "Rahmen sperren" or "Rahmen entsperren" end,
                onClick = function() K.SetUnlocked(not K.IsUnlocked()) end }
            if K.OPT_IN then
                B:Row({ type = "toggle", label = "WeintCodex-Oberfläche verwenden",
                        description = "Namensplaketten und Einheitenrahmen von WeintCodex statt der des Spiels. Wirkt nach dem Neuladen.",
                        get = function() return K.UIEnabled() end,
                        set = function(on) K.SetUIEnabled(on) end },
                      unlock)
                B:Note("Die Komfortfunktionen links unter „Komfort“ — Questpfeil, Reparieren, Schrott verkaufen und Co. — hängen nicht an diesem Schalter. Du kannst sie ohne die Oberfläche benutzen.")
            else
                B:Row(unlock, { type = "empty" })
                B:Note("Die WeintCodex-Oberfläche ist derzeit für alle eingeschaltet. Der Forever-Beta-Client speichert Addon-Einstellungen nicht über ein Neuladen hinweg – eine Wahl „an“ oder „aus“ wäre nach jedem /reload vergessen. Sobald der Client wieder speichert, kommt der Hauptschalter zurück.")
                B:Note("Einzelne Module schaltest du links ab (Schalter oben rechts). Auch das gilt, solange der Client nicht speichert, nur bis zum nächsten Neuladen.")
            end
            B:Section("Schrift und Balken",
                "Gilt für Namensplaketten, Einheitenrahmen und die Hinweise auf dem Bildschirm — nicht für das WeintCodex-Fenster.")
            B:Row({ type = "dropdown", label = "Schrift", key = "font", items = {
                        { value = "plexsemi", text = "IBM Plex Sans (WeintCodex)" },
                        { value = "plex",     text = "IBM Plex Sans, leichter" },
                        { value = "game",     text = "Schrift des Spiels" } } },
                  { type = "dropdown", label = "Kontur", key = "outline", items = {
                        { value = "none",  text = "Keine (mit Schatten)" },
                        { value = "thin",  text = "Dünn" },
                        { value = "thick", text = "Dick" } } })
            B:Row({ type = "dropdown", label = "Balken", key = "barStyle", items = {
                        { value = "flat",     text = "Flach" },
                        { value = "gradient", text = "Mit leichtem Verlauf" } } },
                  { type = "empty" })
            B:Section("Dieses Fenster")
            B:Row({ type = "slider", label = "Größe", key = "windowScale", min = 70, max = 130, step = 5,
                    format = function(v) return string.format("%d %%", v) end },
                  { type = "button", label = "Positionen", text = "Alle Positionen zurücksetzen",
                    onClick = function() K.ResetAllPositions() end })
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
    if m.group == "ui" then
        if wants ~= active then return "nach dem Neuladen " .. (wants and "an" or "aus"), "warning" end
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

function Builder:Section(title, note)
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
            get = get, set = set, disabled = disabled, tooltip = spec.tooltip,
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
            onClick = function() spec.onClick() ; w.Sync() end,
        })
        b:SetPoint("BOTTOMLEFT", w, "BOTTOMLEFT", 0, 2)
        w.Sync = function() b:SetText(label()) end
    end
    if w then self.widgets[#self.widgets + 1] = w end
    return w
end

function Builder:Row(a, b)
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

O.NewBuilder = NewBuilder   -- fuer den Prueflauf

--------------------------------------------------
-- Fenster
--------------------------------------------------

local frame, sidebar, head, tabsHost, previewHost, scroller, inner, footer
local sideRows = {}
local current = { module = "general", page = 1 }
local built = {}       -- [modul] = { tabs = , preview = , pages = { [i] = { frame, height, widgets } } }

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
    unlockBtn:SetText(K.IsUnlocked() and "Rahmen sperren" or "Rahmen entsperren")
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
        local B = NewBuilder(key, host)
        if def and def.build then
            local ok, err = pcall(def.build, B)
            if not ok then K.Report(key, err) end
        end
        page = { frame = host, height = -B.y + 20, widgets = B.widgets }
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

local function Layout()
    -- Hoehe des Bildlaufbereichs: was unter Kopf, Reitern und Vorschau
    -- uebrig bleibt.
    local key = current.module
    local b = built[key]
    local top = HEAD_H
    if b.tabs and #K.Module(key).pages > 1 then top = top + TABS_H + 10 end
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
                items = items, backdrop = "bgDark",
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
    local brand = Label(sidebar, F.display, 20, "textBright")
    brand:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 20, y)
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
        text = "Rahmen entsperren", kind = "secondary", height = 30, size = 11, backdrop = "surface1",
        tooltip = "Zeigt alle beweglichen Rahmen als Flächen, die sich ziehen lassen. Rechtsklick auf eine Fläche setzt sie zurück.",
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

function O.Show(key, pageIndex)
    O.Build()
    frame:Show()
    O.Select(key or current.module, pageIndex)
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
    O.Toggle()
end
