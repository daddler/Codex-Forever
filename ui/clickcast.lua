--------------------------------------------------
-- WeintCodex :: Oberflaeche - Klickzauber
--------------------------------------------------
-- Beta-Test: "ein ganz einfaches Addon, womit ich Zauber auf Tasten binden
-- kann, fuers Heilen - aehnlich wie VuhDo, Clique, Healbot. Einfach, aber
-- es soll den Sinn erfuellen."
--
-- DAS PRINZIP. Eine Belegung ist Maustaste + Zusatztaste -> Aktion, und
-- sie gilt auf jedem Rahmen von WeintCodex, der eine Einheit zeigt
-- (Gruppe, Schlachtzug, Spieler, Ziel, Fokus, ...). Wer mit Umschalt +
-- Links auf Brunhild klickt, heilt Brunhild - ohne sie erst anzuwaehlen.
-- Die Maus zeigt beim Drueberfahren, was welche Taste gerade tut.
--
-- WIE. Nur die Klick-Attribute des geschuetzten Knopfes ("shift-type1" =
-- "spell", "shift-spell1" = Name) - der Client zaubert beim Klick selbst,
-- Lua ist nicht beteiligt. Keine Snippets: dem Forever-Client fehlt dafuer
-- der Uebersetzer (siehe ui/groupframes.lua), und alle Knoepfe entstehen
-- ohnehin ausserhalb des Kampfes. Attribute setzen darf Lua nur ausserhalb
-- des Kampfes - eine Aenderung im Kampf greift danach.
--
-- WAS ES NICHT KANN. Tastatur-Tasten beim Drueberfahren (wie Clique sie
-- anbietet) brauchen Snippets oder Tastenbelegungen, die im Kampf
-- gesperrt sind - beides geht hier nicht. Kombinationen (Strg + Umschalt)
-- auch nicht: ein Mausklick, eine Zusatztaste.
--
-- JE KLASSE. Die Einstellungen gelten fuer den ganzen Account; Zauber
-- aber gehoeren einer Klasse (gelernt aus den Erinnerungen, 6.6.0.5).
-- Die Belegung wird deshalb je Klasse gespeichert.
--
-- KEINE EINGEBAUTE ZAUBERLISTE. Wie bei den Erinnerungen nennt der
-- Spieler die Zauber selbst - niemand hier hat die Zauber des
-- Forever-Clients gelesen.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIClickCast = {}

local CC = WeintCodex.UIClickCast
local K = WeintCodex.UIKit
local C = WeintCodex.Colors
-- Die Einstellungen stehen im Modul der Gruppenrahmen (eigener Reiter):
-- die Seitenleiste des Einstellungsfensters hat keinen Platz fuer einen
-- weiteren Eintrag, und geheilt wird dort.
local KEY = "groupframes"
-- Die Belegung selbst liegt getrennt davon: "Standard" bei den
-- Gruppenrahmen setzt Groessen und Farben zurueck, nicht die Zauber
-- aller Klassen.
local STORE = "clickcast"

CC.BUTTONS = {
    { value = 1, text = "Linke Maustaste",   short = "Links" },
    { value = 2, text = "Rechte Maustaste",  short = "Rechts" },
    { value = 3, text = "Mittlere Maustaste", short = "Mitte" },
    { value = 4, text = "Maustaste 4",       short = "Maus 4" },
    { value = 5, text = "Maustaste 5",       short = "Maus 5" },
}
CC.MODS = {
    { value = "",       text = "ohne" },
    { value = "shift-", text = "Umschalt",  short = "Umschalt" },
    { value = "ctrl-",  text = "Strg",      short = "Strg" },
    { value = "alt-",   text = "Alt",       short = "Alt" },
}
CC.ACTIONS = {
    { value = "spell",  text = "Zauber" },
    { value = "target", text = "Ziel wählen" },
    { value = "menu",   text = "Menü" },
}
CC.DEFAULTS = {
    clickUnitFrames = true,   -- auch Spieler, Ziel, Fokus, ...
    clickTooltip    = true,   -- Belegung im Tooltip
}

local function Opt(k) return K.Get(KEY, k) end

local function Short(list, v)
    for _, e in ipairs(list) do if e.value == v then return e.short or e.text end end
    return tostring(v)
end

local function PlayerClass()
    if not _G.UnitClass then return nil end
    local _, class = _G.UnitClass("player")
    return K.Plain(class)
end
CC._class = PlayerClass

--------------------------------------------------
-- Belegung
--------------------------------------------------

local function Copy(list)
    local out = {}
    for i, b in ipairs(list or {}) do
        out[i] = { button = b.button, mod = b.mod, action = b.action, spell = b.spell }
    end
    return out
end

-- Die Belegung dieser Klasse (Kopie ist nicht noetig: nur gelesen).
function CC.Bindings(class)
    class = class or PlayerClass() or "?"
    local all = K.Get(STORE, "bindings")   -- [Klasse] = { { button, mod, action, spell }, ... }
    return type(all) == "table" and type(all[class]) == "table" and all[class] or {}
end

function CC.SetBindings(list, class)
    class = class or PlayerClass() or "?"
    local all = {}
    local old = K.Get(STORE, "bindings")
    if type(old) == "table" then
        for c, l in pairs(old) do all[c] = Copy(l) end
    end
    all[class] = Copy(list)
    K.Set(STORE, "bindings", all)   -- meldet "setting" -> CC.Apply
end

-- Taste + Zusatztaste gibt es einmal: eine neue Belegung ersetzt die alte.
function CC.Add(b)
    local list = Copy(CC.Bindings())
    for i = #list, 1, -1 do
        if list[i].button == b.button and list[i].mod == b.mod then table.remove(list, i) end
    end
    list[#list + 1] = b
    table.sort(list, function(x, y)
        if x.button ~= y.button then return x.button < y.button end
        return x.mod < y.mod
    end)
    CC.SetBindings(list)
end

function CC.Remove(i)
    local list = Copy(CC.Bindings())
    table.remove(list, i)
    CC.SetBindings(list)
end

-- "Umschalt + Links"
function CC.KeyText(b)
    local key = Short(CC.BUTTONS, b.button)
    if b.mod == "" then return key end
    return Short(CC.MODS, b.mod) .. " + " .. key
end

function CC.ActionText(b)
    if b.action == "spell" then return b.spell or "?" end
    return Short(CC.ACTIONS, b.action)
end

--------------------------------------------------
-- Auf die Rahmen
--------------------------------------------------

-- Was dieses Modul an einem Rahmen gesetzt hat - beim naechsten Mal wird
-- genau das wieder geloescht, dann greifen die Grundeinstellungen des
-- Rahmens ("*type1" = Ziel, "*type2" = Menue) von selbst.
local applied = setmetatable({}, { __mode = "k" })
local hooked = setmetatable({}, { __mode = "k" })

local ATTR_ACTION = { spell = "spell", target = "target", menu = "togglemenu" }

function CC.ApplyTo(f, list)
    if not (f and f.SetAttribute) then return end
    for _, key in ipairs(applied[f] or {}) do f:SetAttribute(key, nil) end
    local keys = {}
    for _, b in ipairs(list) do
        local kind = ATTR_ACTION[b.action]
        if kind and not (b.action == "spell" and not b.spell) then
            local t = b.mod .. "type" .. b.button
            f:SetAttribute(t, kind)
            keys[#keys + 1] = t
            if b.action == "spell" then
                local s = b.mod .. "spell" .. b.button
                f:SetAttribute(s, b.spell)
                keys[#keys + 1] = s
            end
        end
    end
    applied[f] = keys
    CC.HookTooltip(f)
end

-- Jeder Rahmen, der eine Einheit zeigt.
function CC.Frames()
    local out = {}
    local GF = WeintCodex.UIGroupFrames
    if GF and GF.buttons then
        for _, b in ipairs(GF.buttons) do out[#out + 1] = b end
    end
    local UF = WeintCodex.UIUnitFrames
    if Opt("clickUnitFrames") and UF and UF.frames then
        for _, f in pairs(UF.frames) do out[#out + 1] = f end
    end
    return out
end

local pendingApply = false
function CC.Apply()
    if K.InCombat() then
        if not pendingApply then
            pendingApply = true
            K.AfterCombat(function() pendingApply = false CC.Apply() end)
        end
        return false
    end
    local list = CC.Bindings()
    local seen = {}
    for _, f in ipairs(CC.Frames()) do
        seen[f] = true
        CC.ApplyTo(f, list)
    end
    -- Einheitenrahmen abgeschaltet: was dort stand, wieder weg.
    for f in pairs(applied) do
        if not seen[f] then CC.ApplyTo(f, {}) end
    end
    return true
end

--------------------------------------------------
-- Tooltip: was tut welche Taste hier?
--------------------------------------------------

function CC.TooltipLines()
    local out = {}
    for _, b in ipairs(CC.Bindings()) do
        if b.action == "spell" then out[#out + 1] = { CC.KeyText(b), CC.ActionText(b) } end
    end
    return out
end

function CC.HookTooltip(f)
    if hooked[f] or not f.HookScript then return end
    hooked[f] = true
    f:HookScript("OnEnter", function(self)
        if not Opt("clickTooltip") then return end
        local tip = _G.GameTooltip
        if not (tip and tip.IsOwned and tip:IsOwned(self)) then return end
        local lines = CC.TooltipLines()
        if #lines == 0 then return end
        local a, d = C.accent, C.textMuted
        tip:AddLine(" ")
        tip:AddLine("Klickzauber", a[1], a[2], a[3])
        for _, l in ipairs(lines) do
            tip:AddDoubleLine(l[1], l[2], d[1], d[2], d[3], 1, 1, 1)
        end
        tip:Show()
    end)
end

--------------------------------------------------
-- Einstellungen: Reiter "Klickzauber" der Gruppenrahmen
--------------------------------------------------

local draft = { button = 1, mod = "shift-", action = "spell", spell = "" }
CC.draft = draft

function CC.AddDraft()
    local b = { button = draft.button, mod = draft.mod, action = draft.action }
    if b.action == "spell" then
        local text = (draft.spell or ""):gsub("^%s+", ""):gsub("%s+$", "")
        if text == "" then return false, "Zauber fehlt" end
        b.spell = text
    end
    CC.Add(b)
    draft.spell = ""
    return true
end

local LIST_ROWS = 10
function CC.BuildList(parent, width)
    local w = CreateFrame("Frame", nil, parent)
    w.rows = {}
    for i = 1, LIST_ROWS do
        local row = CreateFrame("Frame", nil, w)
        row:SetSize(width, 24)
        row:SetPoint("TOPLEFT", w, "TOPLEFT", 0, -(i - 1) * 26)
        row.bg = row:CreateTexture(nil, "BACKGROUND")
        row.bg:SetAllPoints(row)
        local s = C.surface1
        row.bg:SetColorTexture(s[1], s[2], s[3], 0.6)
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(18, 18)
        row.icon:SetPoint("LEFT", row, "LEFT", 4, 0)
        row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        row.key = K.NewText(row, 12)
        row.key:SetPoint("LEFT", row.icon, "RIGHT", 8, 0)
        row.key:SetWidth(150)
        row.key:SetJustifyH("LEFT")
        row.key:SetWordWrap(false)
        row.key:SetTextColor(unpack(C.textMuted))
        row.text = K.NewText(row, 12)
        row.text:SetPoint("LEFT", row.key, "RIGHT", 8, 0)
        row.text:SetPoint("RIGHT", row, "RIGHT", -96, 0)
        row.text:SetJustifyH("LEFT")
        row.text:SetWordWrap(false)
        local idx = i
        row.remove = WeintCodex.CreateButton(row, { text = "Entfernen", kind = "secondary", height = 20, size = 10,
            onClick = function() CC.Remove(idx) end })
        row.remove:SetPoint("RIGHT", row, "RIGHT", -2, 0)
        w.rows[i] = row
    end
    w.more = K.NewText(w, 11)
    w.more:SetPoint("TOPLEFT", w, "TOPLEFT", 4, -LIST_ROWS * 26)
    w.empty = K.NewText(w, 12)
    w.empty:SetPoint("TOPLEFT", w, "TOPLEFT", 4, -6)
    w.empty:SetWidth(math.max(100, width - 8))
    w.empty:SetText("Noch nichts belegt. Unten Taste und Zauber wählen – zum Beispiel Umschalt + Links: dein kleiner Heilzauber.")
    w.empty:SetTextColor(unpack(C.textDim))
    w.Sync = function()
        local list = CC.Bindings()
        local R = WeintCodex.UIReminders
        for i, row in ipairs(w.rows) do
            local b = list[i]
            if b then
                row.key:SetText(CC.KeyText(b))
                row.text:SetText(CC.ActionText(b))
                local sp = b.action == "spell" and R and R.Resolve and R.Resolve(b.spell)
                if sp and sp.icon then row.icon:SetTexture(sp.icon) row.icon:Show() else row.icon:Hide() end
                row:Show()
            else
                row:Hide()
            end
        end
        local extra = #list - LIST_ROWS
        w.more:SetText(extra > 0 and ("… und " .. extra .. " weitere") or "")
        w.empty:SetShown(#list == 0)
    end
    return w
end

local function DraftChanged() K.Fire("setting", KEY, "clickDraft") end

function CC.BuildPage(B)
    local class = PlayerClass()
    local label = class and WeintCodex.Names and WeintCodex.Names.ClassLabel(class) or "deine Klasse"
    B:Section("Belegung – " .. tostring(label),
        "Klick mit Taste auf einen Rahmen von WeintCodex (Gruppe, Schlachtzug, Spieler, Ziel …) wirkt den Zauber auf diese Einheit – ohne sie erst anzuwählen. Gilt für diese Klasse. Im Kampf änderst du nichts; es greift danach.")
    B:Row({ type = "custom", height = LIST_ROWS * 26 + 18, create = function(parent, width)
                return CC.BuildList(parent, width)
            end }, nil)
    B:Section("Neue Belegung")
    B:Row({ type = "dropdown", label = "Maustaste", items = CC.BUTTONS,
            get = function() return draft.button end, set = function(v) draft.button = v DraftChanged() end },
          { type = "dropdown", label = "Zusatztaste", items = CC.MODS,
            get = function() return draft.mod end, set = function(v) draft.mod = v DraftChanged() end })
    B:Row({ type = "dropdown", label = "Aktion", items = CC.ACTIONS,
            get = function() return draft.action end, set = function(v) draft.action = v DraftChanged() end },
          { type = "input", label = "Zauber (Name oder ID)",
            get = function() return draft.spell end, set = function(v) draft.spell = v end,
            disabled = function() return draft.action ~= "spell" end })
    B:Row({ type = "button", label = "Hinzufügen", text = "Belegen",
            tooltip = "Dieselbe Taste noch einmal belegt ersetzt die alte Belegung.",
            onClick = function()
                local ok, why = CC.AddDraft()
                if not ok and why then
                    print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " Nicht belegt: " .. why .. ".")
                end
            end },
          { type = "empty" })
    B:Section("Wo")
    B:Row({ type = "toggle", label = "Auch Einheitenrahmen", key = "clickUnitFrames",
            description = "Spieler, Ziel, Fokus, Ziel des Ziels und Begleiter – nicht nur Gruppe und Schlachtzug." },
          { type = "toggle", label = "Belegung im Tooltip", key = "clickTooltip",
            description = "Maus über einem Rahmen zeigt, welche Taste welchen Zauber wirkt." })
    B:Note("Links ohne Zusatztaste wählt sonst das Ziel, Rechts öffnet das Menü – belegst du sie, gilt deine Belegung. Tastatur-Tasten beim Drüberfahren (wie in Clique) kann der Forever-Client für Addons nicht, ebenso keine Kombinationen wie Strg + Umschalt.")
end

-- An die Gruppenrahmen haengen: Standardwerte und Reiter.
do
    local m = K.Module(KEY)
    if m then
        for k, v in pairs(CC.DEFAULTS) do m.defaults[k] = v end
        m.pages[#m.pages + 1] = { key = "klickzauber", label = "Klickzauber", build = CC.BuildPage }
    end
end

-- Anwenden: nach dem Einloggen (die Rahmen stehen dann), bei jeder
-- Aenderung der Einstellungen und nach einem Klassenwechsel des Kontos
-- (neuer Charakter = neues Einloggen).
K.Listen(function(kind, module, key)
    if kind ~= "setting" then return end
    if module == STORE or (module == KEY and key ~= "clickDraft") then CC.Apply() end
end)
local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:SetScript("OnEvent", function()
    if K.UIEnabled and not K.UIEnabled() then return end
    CC.Apply()
end)
