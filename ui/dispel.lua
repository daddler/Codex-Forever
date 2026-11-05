--------------------------------------------------
-- WeintCodex :: Oberflaeche - Entfluchen auf Klick (6.8.1.0)
--------------------------------------------------
-- Beta-Test: "ein Feature wie Decursive - so haben Spieler, die sonst
-- nicht mit Klickzaubern zu tun haben, direkt eine Moeglichkeit zu
-- entfluchen."
--
-- WAS ES IST. Ein Schalter. Er legt die Zauber deiner Klasse, die Flueche,
-- Gifte, Krankheiten oder Magie entfernen, auf die Klickzauber (ui/
-- clickcast.lua): Zusatztaste + Links der erste, Zusatztaste + Rechts der
-- zweite. Ein Klick auf einen Gruppenrahmen entflucht diesen Spieler -
-- ohne ihn anzuwaehlen, ohne Makro.
--
-- WAS ES NICHT IST: Decursive. Decursive liest die Debuffs der Gruppe und
-- sagt, wer zuerst dran ist. Im Kampf gibt der 12.x-Client Addons die
-- Auren anderer nicht heraus (gemessen 6.6.0.1 - 6.6.0.3, siehe
-- docs/systems/ui.md) - welche Debuffs bannbar sind, zeigen die
-- Gruppenrahmen des Spiels selbst ("Nur bannbare"). Was der Client zu
-- Debuffs der Gruppe herausgibt, ist fuer Forever noch zu messen.
--
-- DEINE BELEGUNG GEWINNT. Liegt auf der Taste schon etwas von dir, bleibt
-- es dabei (CC.Effective); die Seite sagt dann, welche Taste besetzt ist.
--
-- WELCHE ZAUBER. Die Klickzauber kommen ohne eingebaute Zauberliste aus -
-- hier geht es nicht ohne: der Client sagt nicht, welcher Zauber bannt.
-- Deshalb eine kleine Liste mit benannter Herkunft: Zauber-IDs aus WoW
-- Classic (Fassung 1.12, Herkunft "classic"). Angeboten wird ein Zauber nur,
-- wenn der Client unter dieser ID einen Namen nennt UND dieser Name in deinem
-- Zauberbuch steht (oder IsPlayerSpell ja sagt) - eine falsche oder in
-- Forever geaenderte ID fuehrt zu nichts, nie zu einem falschen Zauber.
-- Gewirkt wird ueber den Namen: hoechster Rang, steigt mit.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIDispel = {}

local DP = WeintCodex.UIDispel
local K = WeintCodex.UIKit
local CC = WeintCodex.UIClickCast
local KEY = "groupframes"

DP.SOURCE = "classic"
-- Je Klasse Gruppen; je Gruppe die Alternativen, die bessere zuerst
-- (Aufheben vor Heilen: wirkt laenger, entfernt mehr). Gruppe 1 = Links,
-- Gruppe 2 = Rechts.
DP.SPELLS = {
    PRIEST  = { { label = "Magie",               ids = { 527, 988 },   types = { Magic = true } },        -- Magiebannung
                { label = "Krankheit",           ids = { 552, 528 },   types = { Disease = true } } },    -- Krankheit aufheben / heilen
    PALADIN = { { label = "Gift, Krankheit, Magie", ids = { 4987, 1152 }, types = { Poison = true, Disease = true, Magic = true } } }, -- Reinigung des Glaubens / Laeutern
    DRUID   = { { label = "Fluch",               ids = { 2782 },       types = { Curse = true } },        -- Fluch aufheben
                { label = "Gift",                ids = { 2893, 8946 }, types = { Poison = true } } },     -- Vergiftung aufheben / heilen
    MAGE    = { { label = "Fluch",               ids = { 475 },        types = { Curse = true } } },      -- Geringen Fluch aufheben
    SHAMAN  = { { label = "Gift",                ids = { 526 },        types = { Poison = true } },       -- Gift heilen
                { label = "Krankheit",           ids = { 2870 },       types = { Disease = true } } },    -- Krankheit heilen
}
DP.BUTTONS = { 1, 2 }
DP.TYPE_LABEL = { Magic = "Magie", Curse = "Fluch", Disease = "Krankheit", Poison = "Gift" }
DP.TYPE_ITEMS = {
    { value = "Magic", text = "Magie" }, { value = "Curse", text = "Fluch" },
    { value = "Disease", text = "Krankheit" }, { value = "Poison", text = "Gift" },
}

DP.DEFAULTS = {
    clickDispel    = false,
    clickDispelMod = "ctrl-",
    dispelBar      = true,     -- 1.10.24.0: Felder zum Anklicken (wie Decursive)
    dispelBarSize  = 16,
    dispelBarGroup = false,    -- nur in einer Gruppe
    dispelOwnSpell = "",       -- 1.10.25.0: eigener Bannzauber aus dem Zauberbuch
    dispelOwnType  = "Magic",
}

local function Opt(k) return K.Get(KEY, k) end

local function Plain(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a = pcall(fn, ...)
    return ok and K.Plain(a) or nil
end

-- Name eines Zaubers nach ID, wie der Client ihn nennt.
function DP.NameOf(id)
    local cs = _G.C_Spell
    local n = cs and Plain(cs.GetSpellName, id)
    if type(n) ~= "string" or n == "" then n = Plain(_G.GetSpellInfo, id) end
    return (type(n) == "string" and n ~= "") and n or nil
end

-- Kann der Charakter diesen Zauber? Zauberbuch (Name) oder IsPlayerSpell.
function DP.Known(id, name, book)
    if Plain(_G.IsPlayerSpell, id) == true then return true end
    if name and book then
        for _, sp in ipairs(book) do if sp.name == name then return true end end
    end
    return false
end

-- Je Gruppe der beste gelernte Zauber: { { label, spell, button } ... }
-- und die Gruppen, fuer die noch nichts gelernt ist.
function DP.Resolve(class)
    class = class or (CC._class and CC._class())
    local groups = class and DP.SPELLS[class]
    local found, missing = {}, {}
    local book = (CC.Spellbook and CC.Spellbook(false)) or {}
    -- 1.10.25.0 (Wunsch: "auch Magie bannen"): was die Liste nicht kennt
    -- (Forever kann Klassen neue Bannzauber geben), waehlt der Spieler
    -- selbst - ein Zauber aus SEINEM Zauberbuch und die Art, die er entfernt.
    local own = Opt("dispelOwnSpell")
    local ownType = DP.TYPE_LABEL[Opt("dispelOwnType") or ""] and Opt("dispelOwnType") or "Magic"
    local function AddOwn()
        if type(own) ~= "string" or own == "" then return end
        for _, f in ipairs(found) do if f.spell == own then return end end
        for _, sp in ipairs(book) do
            if sp.name == own then
                found[#found + 1] = { label = DP.TYPE_LABEL[ownType], spell = own, button = #found + 1,
                                      types = { [ownType] = true }, own = true }
                return
            end
        end
    end
    if not groups then
        AddOwn()
        return found, missing, #found > 0
    end
    for i, g in ipairs(groups) do
        local pick
        for _, id in ipairs(g.ids) do
            local name = DP.NameOf(id)
            if name and DP.Known(id, name, book) then pick = name break end
        end
        if pick then
            found[#found + 1] = { label = g.label, spell = pick, button = DP.BUTTONS[i], types = g.types }
        else
            missing[#missing + 1] = g.label
        end
    end
    AddOwn()
    return found, missing, true
end

-- Fuer die Klickzauber: die Belegungen, solange der Schalter an ist.
function DP.Bindings()
    if not Opt("clickDispel") then return {} end
    local mod = Opt("clickDispelMod") or "ctrl-"
    if mod == "" then mod = "ctrl-" end    -- ohne Zusatztaste wuerde Links nicht mehr anwaehlen
    local out = {}
    for _, f in ipairs((DP.Resolve())) do
        if f.button <= #DP.BUTTONS then
            out[#out + 1] = { button = f.button, mod = mod, action = "spell", spell = f.spell, note = "Entfluchen" }
        end
    end
    return out
end
CC.ExtraBindings = DP.Bindings

-- Eine Zeile fuer die Seite: was liegt wo, was fehlt, was ist besetzt.
function DP.Summary()
    local found, missing, hasClass = DP.Resolve()
    if not hasClass then return "Deine Klasse hat keinen Zauber zum Entfluchen." end
    local mod = Opt("clickDispelMod") or "ctrl-"
    if mod == "" then mod = "ctrl-" end
    local mine = {}
    for _, b in ipairs(CC.Bindings()) do mine[b.mod .. b.button] = b end
    local parts = {}
    for _, f in ipairs(found) do
        if f.button > #DP.BUTTONS then
            parts[#parts + 1] = string.format("%s (%s): nur über die Felder", f.spell, f.label)
        else
        local key = CC.KeyText({ button = f.button, mod = mod })
        local own = mine[mod .. f.button]
        if own then
            parts[#parts + 1] = string.format("%s: besetzt (%s) – %s bleibt frei", key, CC.ActionText(own), f.spell)
        else
            parts[#parts + 1] = string.format("%s: %s (%s)", key, f.spell, f.label)
        end
        end
    end
    for _, label in ipairs(missing) do
        parts[#parts + 1] = string.format("%s: noch nicht gelernt", label)
    end
    if #parts == 0 then return "Noch kein Zauber zum Entfluchen gelernt." end
    return table.concat(parts, " · ")
end

local MODS = {}
for _, m in ipairs(CC.MODS) do if m.value ~= "" then MODS[#MODS + 1] = m end end

-- 1.10.24.0 (Beta-Test: "Strg eingestellt, Klick auf meine Plakette tut
-- nichts"): was nicht klappt, sagt die Seite in Rot und einmal der Chat -
-- kein Zauber gelernt, Taste schon belegt.
function DP.Problems()
    local out = {}
    local found, missing, hasClass = DP.Resolve()
    if not hasClass then
        out[#out + 1] = "Deine Klasse hat keinen Zauber zum Entfluchen – hier passiert nichts."
        return out, found
    end
    if #found == 0 then
        out[#out + 1] = "Noch kein Zauber zum Entfluchen gelernt (" .. table.concat(missing, ", ") .. ") – hier passiert noch nichts."
        return out, found
    end
    if Opt("clickDispel") then
        local mod = Opt("clickDispelMod") or "ctrl-"
        if mod == "" then mod = "ctrl-" end
        local mine = {}
        for _, b in ipairs(CC.Bindings()) do mine[b.mod .. b.button] = b end
        for _, f in ipairs(found) do
            local own = f.button <= #DP.BUTTONS and mine[mod .. f.button]
            if own then
                out[#out + 1] = string.format("%s ist schon mit „%s“ belegt (Klickzauber) – %s geht über diese Taste nicht. Andere Zusatztaste wählen oder die Belegung löschen.",
                    CC.KeyText({ button = f.button, mod = mod }), CC.ActionText(own), f.spell)
            end
        end
    end
    return out, found
end

-- explicit: der Spieler hat gerade etwas umgestellt - dann alles. Beim
-- Einloggen nur, was er selbst eingeschaltet hat und nicht klappt (die
-- Felder sind ab Werk an - ein Krieger soll dafuer keine Meldung bekommen).
local said = {}
function DP.Warn(explicit)
    if not Opt("clickDispel") and not explicit then return 0 end
    if not (Opt("clickDispel") or Opt("dispelBar")) then return 0 end
    local n = 0
    for _, text in ipairs((DP.Problems())) do
        if not said[text] then
            said[text] = true
            n = n + 1
            print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " Entfluchen: " .. text)
        end
    end
    return n
end

--------------------------------------------------
-- Felder zum Anklicken (1.10.24.0, Wunsch: "wie bei Decursive kleine
-- Rechtecke, farbig markiert, ein Klick entflucht")
--------------------------------------------------
-- Je Mitglied ein Feld je Zauber deiner Klasse. Ein Feld leuchtet in der
-- Farbe des Debuffs, den DIESER Zauber entfernt; Linksklick wirkt ihn auf
-- das Mitglied. Geschuetzte Knoepfe (SecureUnitButtonTemplate): Zauber und
-- Einheit werden nur ausserhalb des Kampfes gesetzt, gezeigt wird ueber
-- RegisterUnitWatch/RegisterStateDriver - das geht auch im Kampf.
-- Farbe: aus den Debuffs (dispelName). Gibt der Client sie im Kampf nur
-- geheim heraus (12.x), bleibt das Feld grau - klicken geht trotzdem.
DP.COLORS = {
    Magic   = { 0.20, 0.60, 1.00 },
    Curse   = { 0.60, 0.00, 1.00 },
    Disease = { 0.60, 0.40, 0.00 },
    Poison  = { 0.00, 0.60, 0.00 },
}
DP.MAX_RAID = 40
DP.MAX_SQ = 3      -- bis zu zwei Zauber der Klasse und ein eigener
local bar, cells, pendingApply = nil, {}, false
DP.cells = cells

local function InCombat() return _G.InCombatLockdown and K.Bool(_G.InCombatLockdown(), true) or false end

local function NewCell(parent, unit)
    local c = CreateFrame("Frame", nil, parent)
    c.unit = unit
    c.sq = {}
    for i = 1, DP.MAX_SQ do
        local ok, b = pcall(CreateFrame, "Button", nil, c, "SecureUnitButtonTemplate")
        if not ok then b = CreateFrame("Button", nil, c) end
        b:SetAttribute("unit", unit)
        -- 1.0.0.9 (Bericht: "Rechtsklick auf den Indikator geht nicht"):
        -- beide Maustasten. Wie Automark und Totems (im Spiel gemessen,
        -- 6.27.2.1): auf Loslassen, nie beim Druecken - ohne useOnKeyDown =
        -- false loest der Client geschuetzte Knoepfe beim Druecken aus,
        -- registriert war nur das Loslassen, also nie.
        if b.RegisterForClicks then b:RegisterForClicks("AnyUp") end
        b:SetAttribute("useOnKeyDown", false)
        b.bg = b:CreateTexture(nil, "BACKGROUND")
        b.bg:SetAllPoints()
        b.bg:SetColorTexture(0.12, 0.12, 0.14, 0.85)
        b.fill = b:CreateTexture(nil, "ARTWORK")
        b.fill:SetPoint("TOPLEFT", b, "TOPLEFT", 1, -1)
        b.fill:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -1, 1)
        b.fill:SetColorTexture(1, 1, 1, 1)
        b.fill:Hide()
        b._cell = c
        b:SetScript("OnEnter", function(self)
            local tip = _G.GameTooltip
            if not tip then return end
            tip:SetOwner(self, "ANCHOR_TOP")
            local name = _G.UnitName and K.Plain(_G.UnitName(c.unit))
            tip:AddLine(type(name) == "string" and name or c.unit)
            if self._spell then tip:AddLine("Links- oder Rechtsklick: " .. self._spell, 1, 1, 1) end
            tip:Show()
        end)
        b:SetScript("OnLeave", function() if _G.GameTooltip then _G.GameTooltip:Hide() end end)
        c.sq[i] = b
    end
    if _G.RegisterUnitWatch and unit ~= "player" then pcall(_G.RegisterUnitWatch, c) end
    return c
end

function DP.BarFrame()
    if bar then return bar end
    bar = CreateFrame("Frame", "WeintCodexDispelBar", UIParent)
    bar:SetSize(120, 20)
    bar.party = CreateFrame("Frame", nil, bar, "SecureHandlerStateTemplate")
    bar.raid = CreateFrame("Frame", nil, bar, "SecureHandlerStateTemplate")
    bar.party:SetAllPoints(bar)
    bar.raid:SetAllPoints(bar)
    local units = { "player", "party1", "party2", "party3", "party4" }
    for i, u in ipairs(units) do cells[#cells + 1] = NewCell(bar.party, u) cells[#cells]._i, cells[#cells]._raid = i, false end
    for i = 1, DP.MAX_RAID do cells[#cells + 1] = NewCell(bar.raid, "raid" .. i) cells[#cells]._i, cells[#cells]._raid = i, true end
    if _G.RegisterStateDriver then
        pcall(_G.RegisterStateDriver, bar.party, "visibility", "[group:raid] hide; show")
        pcall(_G.RegisterStateDriver, bar.raid, "visibility", "[group:raid] show; hide")
    end
    K.RegisterMover(bar, "dispelbar", "Entfluchen: Felder", K.Layout("dispelbar"), { secure = true })
    return bar
end

-- Zauber, Groesse, Plaetze - nur ausserhalb des Kampfes.
function DP.ApplyBar()
    if InCombat() then pendingApply = true return false end
    pendingApply = false
    local _, found = DP.Problems()
    local want = Opt("dispelBar") and K.IsActive("comfort") and #found > 0
    if not want then
        if bar then
            if _G.UnregisterStateDriver then pcall(_G.UnregisterStateDriver, bar, "visibility") end
            bar:Hide()
        end
        return false
    end
    local f = DP.BarFrame()
    local size = tonumber(Opt("dispelBarSize")) or 16
    local n = #found
    local cw = n * size + (n - 1) * 1
    for _, c in ipairs(cells) do
        c:SetSize(cw, size)
        c:ClearAllPoints()
        local i = c._i - 1
        local col, row = i % 5, math.floor(i / 5)
        c:SetPoint("TOPLEFT", c:GetParent(), "TOPLEFT", col * (cw + 4), -row * (size + 4))
        for k, b in ipairs(c.sq) do
            local fnd = found[k]
            b:SetSize(size, size)
            b:ClearAllPoints()
            b:SetPoint("LEFT", c, "LEFT", (k - 1) * (size + 1), 0)
            if fnd then
                -- 1.0.0.9: jede Maustaste wirkt den Zauber dieses Feldes
                -- (vorher nur Links - Rechts tat nichts).
                b:SetAttribute("type1", nil)
                b:SetAttribute("spell1", nil)
                b:SetAttribute("type", "spell")
                b:SetAttribute("spell", fnd.spell)
                b._spell, b._types = fnd.spell, fnd.types
                b:Show()
            else
                b:SetAttribute("type1", nil)
                b:SetAttribute("type", nil)
                b:SetAttribute("spell", nil)
                b._spell, b._types = nil, nil
                b:Hide()
            end
        end
    end
    f:SetSize(5 * (cw + 4), 8 * (size + 4))
    if _G.RegisterStateDriver then
        pcall(_G.RegisterStateDriver, f, "visibility", Opt("dispelBarGroup") and "[group] show; hide" or "show")
    end
    f:Show()
    DP.PaintAll()
    return true
end

-- Welche Debuff-Arten traegt die Einheit? Geheim/unbekannt = keine.
local typesBuf = {}
function DP.UnitTypes(unit)
    for k in pairs(typesBuf) do typesBuf[k] = nil end
    local cu = _G.C_UnitAuras
    if not (cu and cu.GetAuraDataByIndex) then return typesBuf end
    for i = 1, 40 do
        local ok, a = pcall(cu.GetAuraDataByIndex, unit, i, "HARMFUL")
        if not ok or type(a) ~= "table" then break end
        local t = K.Plain(a.dispelName)
        if type(t) == "string" then typesBuf[t] = true end
    end
    return typesBuf
end

function DP.PaintCell(c)
    if not c or not c.sq then return end
    local exists = _G.UnitExists and K.Bool(_G.UnitExists(c.unit), false)
    local types = exists and DP.UnitTypes(c.unit) or typesBuf
    for _, b in ipairs(c.sq) do
        local col
        if b._types then
            for t in pairs(types) do
                if b._types[t] then col = DP.COLORS[t] break end
            end
        end
        if col then
            b.fill:SetVertexColor(col[1], col[2], col[3], 1)
            b.fill:Show()
        else
            b.fill:Hide()
        end
    end
end

function DP.PaintAll()
    if not bar then return end
    for _, c in ipairs(cells) do DP.PaintCell(c) end
end

function DP.OnAura(unit)
    if not bar or not bar:IsShown() or type(unit) ~= "string" then return end
    for _, c in ipairs(cells) do
        if c.unit == unit then DP.PaintCell(c) end
    end
end

--------------------------------------------------
-- Seite "Entfluchen" (1.10.24.0: eigener Reiter neben den Klickzaubern)
--------------------------------------------------
function DP.BuildPage(B)
    local problems, found = DP.Problems()
    if #found > 0 then
        local can = {}
        for _, f in ipairs(found) do can[#can + 1] = f.label end
        B:Note("Du kannst entfernen: " .. table.concat(can, ", ") .. ". Was deine Klasse nicht kann (z. B. Magie beim Schamanen in Classic), zeigt kein Feld – dafür ist „Eigener Bannzauber“ unten.")
    end
    if #problems > 0 then
        B:Note(WeintCodex.ColorText("red", table.concat(problems, "\n")))
    end
    B:Section("Felder zum Anklicken",
        "Kleine Felder je Gruppenmitglied, eins je Zauber deiner Klasse. Leuchtet eins (Magie blau, Fluch lila, Krankheit braun, Gift grün), entfernt ein Linksklick genau das. Verschieben im Gestaltungsmodus.")
    B:Row({ type = "toggle", label = "Felder zeigen", key = "dispelBar" },
          { type = "toggle", label = "Nur in einer Gruppe", key = "dispelBarGroup",
            disabled = function() return not Opt("dispelBar") end })
    B:Row({ type = "slider", label = "Größe", key = "dispelBarSize", min = 10, max = 28, step = 1, suffix = " px",
            disabled = function() return not Opt("dispelBar") end }, { type = "empty" })
    B:Section("Eigener Bannzauber",
        "Fehlt ein Zauber – etwa einer gegen Magie, den deine Klasse in Forever neu hat –, wähle ihn hier aus deinem Zauberbuch und sag, was er entfernt. Er bekommt ein eigenes Feld.")
    local items = { { value = "", text = "Keiner" } }
    for _, sp in ipairs((CC.Spellbook and CC.Spellbook(true)) or {}) do
        if type(sp.name) == "string" then items[#items + 1] = { value = sp.name, text = sp.name } end
    end
    B:Row({ type = "dropdown", label = "Zauber", key = "dispelOwnSpell", items = items },
          { type = "dropdown", label = "Entfernt", key = "dispelOwnType", items = DP.TYPE_ITEMS,
            disabled = function() local v = Opt("dispelOwnSpell") return type(v) ~= "string" or v == "" end })
    B:Section("Zusatztaste + Klick auf einen Rahmen",
        "Legt die Zauber auf Zusatztaste + Links und Rechts – auf Gruppen- und Einheitenrahmen. Auf Namensplaketten geht das nicht: dort lässt das Spiel keine Klickzauber zu.")
    B:Row({ type = "toggle", label = "Entfluchen auf Klick", key = "clickDispel" },
          { type = "dropdown", label = "Zusatztaste", key = "clickDispelMod", items = MODS,
            disabled = function() return not Opt("clickDispel") end })
    B:Note(DP.Summary())
    B:Note("Im Kampf gibt das Spiel Addons die Art eines Debuffs womöglich nicht heraus – dann bleiben die Felder grau, ein Klick wirkt trotzdem.")
end
DP.BuildSection = nil

do
    local m = K.Module(KEY)
    if m then
        for k, v in pairs(DP.DEFAULTS) do if m.defaults[k] == nil then m.defaults[k] = v end end
    end
end

-- Neu gelernt (Lehrer, Stufe): neu anwenden, solange der Schalter an ist.
local ev = CreateFrame("Frame")
for _, e in ipairs({ "SPELLS_CHANGED", "LEARNED_SPELL_IN_TAB" }) do pcall(ev.RegisterEvent, ev, e) end
ev:SetScript("OnEvent", function()
    if Opt("clickDispel") and CC.Apply then CC.Apply() end
end)

-- Felder: Debuffs, Gruppe, Kampfende.
local bev = CreateFrame("Frame")
for _, e in ipairs({ "UNIT_AURA", "GROUP_ROSTER_UPDATE", "PLAYER_REGEN_ENABLED", "PLAYER_ENTERING_WORLD", "SPELLS_CHANGED" }) do
    pcall(bev.RegisterEvent, bev, e)
end
bev:SetScript("OnEvent", function(_, event, unit)
    if event == "UNIT_AURA" then DP.OnAura(unit) return end
    if event == "PLAYER_REGEN_ENABLED" then
        if pendingApply then DP.ApplyBar() else DP.PaintAll() end
        return
    end
    if event == "PLAYER_ENTERING_WORLD" then DP.ApplyBar() DP.Warn(false) return end
    if event == "SPELLS_CHANGED" then DP.ApplyBar() return end
    DP.PaintAll()
end)
K.Listen(function(kind, module, key)
    if kind ~= "setting" then return end
    if module == KEY and type(key) == "string" and (key:find("ispel", 1, true) or key:sub(1, 5) == "click") then
        DP.ApplyBar()
        -- Eigene Klickbelegung kann Entfluchen verdecken - dann melden.
        DP.Warn(key:find("ispel", 1, true) ~= nil)
    end
end)
