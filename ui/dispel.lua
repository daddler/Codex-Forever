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
    PRIEST  = { { label = "Magie",               ids = { 527, 988 } },        -- Magiebannung
                { label = "Krankheit",           ids = { 552, 528 } } },      -- Krankheit aufheben / heilen
    PALADIN = { { label = "Gift, Krankheit, Magie", ids = { 4987, 1152 } } }, -- Reinigung des Glaubens / Laeutern
    DRUID   = { { label = "Fluch",               ids = { 2782 } },            -- Fluch aufheben
                { label = "Gift",                ids = { 2893, 8946 } } },    -- Vergiftung aufheben / heilen
    MAGE    = { { label = "Fluch",               ids = { 475 } } },           -- Geringen Fluch aufheben
    SHAMAN  = { { label = "Gift",                ids = { 526 } },             -- Gift heilen
                { label = "Krankheit",           ids = { 2870 } } },          -- Krankheit heilen
}
DP.BUTTONS = { 1, 2 }

DP.DEFAULTS = {
    clickDispel    = false,
    clickDispelMod = "ctrl-",
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
    if not groups then return found, missing, false end
    local book = (CC.Spellbook and CC.Spellbook(false)) or {}
    for i, g in ipairs(groups) do
        local pick
        for _, id in ipairs(g.ids) do
            local name = DP.NameOf(id)
            if name and DP.Known(id, name, book) then pick = name break end
        end
        if pick then
            found[#found + 1] = { label = g.label, spell = pick, button = DP.BUTTONS[i] }
        else
            missing[#missing + 1] = g.label
        end
    end
    return found, missing, true
end

-- Fuer die Klickzauber: die Belegungen, solange der Schalter an ist.
function DP.Bindings()
    if not Opt("clickDispel") then return {} end
    local mod = Opt("clickDispelMod") or "ctrl-"
    if mod == "" then mod = "ctrl-" end    -- ohne Zusatztaste wuerde Links nicht mehr anwaehlen
    local out = {}
    for _, f in ipairs((DP.Resolve())) do
        out[#out + 1] = { button = f.button, mod = mod, action = "spell", spell = f.spell, note = "Entfluchen" }
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
        local key = CC.KeyText({ button = f.button, mod = mod })
        local own = mine[mod .. f.button]
        if own then
            parts[#parts + 1] = string.format("%s: besetzt (%s) – %s bleibt frei", key, CC.ActionText(own), f.spell)
        else
            parts[#parts + 1] = string.format("%s: %s (%s)", key, f.spell, f.label)
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

function DP.BuildSection(B)
    B:Section("Entfluchen auf Klick",
        "Ein Schalter legt die Zauber deiner Klasse gegen Flüche, Gifte, Krankheiten und Magie auf Zusatztaste + Links und Rechts. "
        .. "Klick auf einen Rahmen entflucht diesen Spieler. Deine eigene Belegung bleibt immer, wie sie ist.")
    B:Row({ type = "toggle", label = "Entfluchen auf Klick", key = "clickDispel" },
          { type = "dropdown", label = "Zusatztaste", key = "clickDispelMod", items = MODS,
            disabled = function() return not Opt("clickDispel") end })
    B:Note(DP.Summary())
end

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
