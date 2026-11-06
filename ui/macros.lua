--------------------------------------------------
-- WeintCodex :: Oberflaeche - Makro-Helfer (6.8.1.0, erweitert 1.7.0.0)
--------------------------------------------------
-- Beta-Test: "Viele wissen nicht, wie man ein Makro schreibt. Der Nutzer
-- kann auswaehlen, was das Makro machen soll, und es wird geschrieben."
--
-- DAS PRINZIP. Drei Fragen statt einer Sprache: WAS (einen Zauber wirken,
-- mit einer Zusatztaste einen zweiten, mehrere nacheinander), AUF WEN
-- (dein Ziel, das unter der Maus, Fokus, du selbst, der Mauszeiger) und
-- WELCHER Zauber (aus dem Zauberbuch angeklickt oder eingetippt). Daraus
-- entsteht der Text, Zeile fuer Zeile erklaert, mit Zaehler gegen die
-- 255 Zeichen des Spiels. Ein Knopf legt das Makro an (oder ersetzt eines
-- mit demselben Namen), ein zweiter nimmt es auf den Mauszeiger, damit es
-- auf eine Leiste gezogen werden kann.
--
-- KEINE EINGEBAUTE ZAUBERLISTE - wie bei den Klickzaubern: angeboten wird,
-- was das Zauberbuch nennt (WeintCodex.UIClickCast.Spellbook). Ein
-- eingetippter Name, den das Zauberbuch nicht kennt, wird nicht
-- abgelehnt (Gegenstaende, Gestalten), aber benannt.
--
-- GRENZEN. Anlegen und Aufnehmen nur ausserhalb des Kampfes. Ob der
-- Forever-Client einzelne Befehle oder Bedingungen fuer Makros sperrt,
-- ist ungemessen - der Text folgt der Makrosprache des Spiels.
-- Die 255 sind Bytes: ein Umlaut zaehlt doppelt - der Zaehler zaehlt
-- deshalb Bytes (#), mit Absicht, nicht Zeichen.
--
-- WO. Eine Seite im Komfort ("Makros", bis 6.8.1.0 bei den Aktionsleisten),
-- kein eigenes Modul: die Seitenleiste der Einstellungen hat keinen Platz
-- fuer einen weiteren Eintrag (load_test.lua, "Nichts muss scrollen").
-- Der Entwurf lebt nur in dieser Sitzung; angelegt ist angelegt.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIMacros = {}

local MH = WeintCodex.UIMacros
local K = WeintCodex.UIKit
local C = WeintCodex.Colors
local KEY = "actionbars"

MH.LIMIT = 255              -- Bytes je Makro (Spiel)
MH.NAME_MAX = 16            -- Zeichen im Namen (Spiel)
MH.ICON = 134400            -- Fragezeichen: mit #showtooltip zeigt das Spiel das Zaubersymbol

-- WAS
MH.KINDS = {
    { value = "cast",     text = "Einen Zauber wirken" },
    { value = "modifier", text = "Mit Zusatztaste einen zweiten Zauber" },
    -- 1.10.30.0 (Wunsch: "auch komplexe Makros"): bis zu drei Tasten,
    -- "erst A, sonst B", "in Verstohlenheit A, sonst B".
    { value = "mods",     text = "Ohne Taste, Umschalt, Strg, Alt – je ein Zauber" },
    { value = "fallback", text = "Erst A, wenn möglich – sonst B (sonst C, D)" },
    { value = "switch",   text = "Unter einer Bedingung A, sonst B" },
    { value = "sequence", text = "Zauber nacheinander (Abfolge)" },
    -- 1.0.4.0 (Wunsch: Sturmangriff aus jeder Haltung, danach zurueck):
    -- Haltung je Zeile - erst in die Haltung des Zaubers, dann der Zauber,
    -- dann in eine andere zurueck.
    { value = "stance",   text = "In Haltung wechseln, Zauber, zurück" },
}

-- Bedingung fuer "switch": A, wenn sie gilt, sonst B.
MH.SWITCH = {
    { value = "stealth", text = "Verstohlen / getarnt",     explain = "verstohlen",           neg = "nostealth" },
    { value = "combat",  text = "Im Kampf",                 explain = "im Kampf",             neg = "nocombat" },
    { value = "harm",    text = "Ziel ist ein Gegner",      explain = "auf einen Gegner",     neg = "help" },
    { value = "help",    text = "Ziel ist ein Verbündeter", explain = "auf einen Verbündeten", neg = "harm" },
    { value = "mounted", text = "Auf dem Reittier",         explain = "auf dem Reittier",     neg = "nomounted" },
    { value = "group",   text = "In einer Gruppe",          explain = "in einer Gruppe",      neg = "nogroup" },
    { value = "pet",     text = "Begleiter ist da",         explain = "mit Begleiter",        neg = "nopet" },
}

-- AUF WEN. conds: die Klammern der Reihe nach - die erste, die greift,
-- gilt ("" = dein Ziel als letzte Stufe). Ohne conds: keine Klammer.
-- 1.7.0.0 (Wunsch: "auch komplexe Makros inkl. Mouseover, Cursor"):
-- Ketten ueber mehrere Stufen, Gegner/Verbuendeter getrennt.
MH.TARGETS = {
    { value = "target",       text = "Dein Ziel",
      explain = "auf dein aktuelles Ziel" },
    { value = "mouseover",    text = "Maus-Ziel, sonst dein Ziel", conds = { "@mouseover,exists,nodead", "" },
      explain = "auf den, über dem deine Maus steht (Rahmen oder Spielwelt) – sonst auf dein Ziel" },
    { value = "mouseoverself", text = "Maus-Ziel, sonst du selbst", conds = { "@mouseover,help,nodead", "@player" },
      explain = "auf den Verbündeten unter deiner Maus – sonst auf dich selbst (zum Heilen)" },
    { value = "smartheal",    text = "Heilen: Maus, sonst Ziel, sonst du", conds = { "@mouseover,help,nodead", "@target,help,nodead", "@player" },
      explain = "auf den Verbündeten unter der Maus – sonst auf dein Ziel, wenn es ein Verbündeter ist – sonst auf dich" },
    { value = "smartharm",    text = "Angriff: Maus-Gegner, sonst dein Ziel", conds = { "@mouseover,harm,nodead", "harm,nodead" },
      explain = "auf den Gegner unter deiner Maus – sonst auf dein Ziel, wenn es ein Gegner ist" },
    { value = "focus",        text = "Fokus, sonst dein Ziel", conds = { "@focus,exists,nodead", "" },
      explain = "auf deinen Fokus – sonst auf dein Ziel" },
    { value = "targettarget", text = "Ziel deines Ziels", conds = { "@targettarget,exists,nodead" },
      explain = "auf das Ziel deines Ziels (z. B. den, den der Gegner angreift)" },
    { value = "pet",          text = "Dein Begleiter", conds = { "@pet,exists,nodead" },
      explain = "auf deinen Begleiter" },
    { value = "player",       text = "Du selbst", conds = { "@player" },
      explain = "immer auf dich selbst, egal was ausgewählt ist" },
    { value = "cursor",       text = "Am Mauszeiger (Flächenzauber)", conds = { "@cursor" },
      explain = "sofort dort, wo dein Mauszeiger steht – ohne Zielkreis" },
    { value = "mouseovercursor", text = "Fläche: auf Maus-Ziel, sonst Mauszeiger", conds = { "@mouseover,exists,nodead", "@cursor" },
      explain = "unter den, über dem deine Maus steht – sonst sofort am Mauszeiger" },
}

-- WANN: gilt fuer jede Klammer des Zaubers.
MH.WHEN = {
    { value = "",          text = "Immer" },
    { value = "combat",    text = "Nur im Kampf",          explain = "nur im Kampf" },
    { value = "nocombat",  text = "Nur außerhalb des Kampfes", explain = "nur außerhalb des Kampfes" },
    { value = "nomounted", text = "Nicht auf dem Reittier", explain = "nicht auf dem Reittier" },
    { value = "stealth",   text = "Nur verstohlen",         explain = "nur verstohlen" },
    { value = "nostealth", text = "Nur nicht verstohlen",   explain = "nur, wenn du nicht verstohlen bist" },
}

MH.MODS = {
    { value = "shift", text = "Umschalt" },
    { value = "ctrl",  text = "Strg" },
    { value = "alt",   text = "Alt" },
}

MH.RESETS = {
    { value = "target", text = "Bei neuem Ziel",                 word = "target", explain = "beginnt von vorn, wenn du ein neues Ziel wählst" },
    { value = "5",      text = "Nach 5 s ohne Tastendruck",      word = "5",      explain = "beginnt von vorn, wenn du 5 Sekunden nicht drückst" },
    { value = "combat", text = "Nach dem Kampf",                 word = "combat", explain = "beginnt nach jedem Kampf von vorn" },
    -- 1.10.30.0: eigene Sekunden, auch zusammen mit neuem Ziel (reset=8/target).
    { value = "secs",   text = "Nach eigenen Sekunden",          secs = true,     explain = "beginnt von vorn, wenn du so lange nicht drückst" },
    { value = "secstarget", text = "Nach eigenen Sekunden oder neuem Ziel", secs = true, target = true,
      explain = "beginnt von vorn nach dieser Zeit ohne Tastendruck oder bei neuem Ziel" },
    { value = "",       text = "Nie (läuft immer im Kreis)",     word = nil,      explain = "beginnt nach dem letzten Zauber wieder beim ersten" },
}

MH.SAVE = {
    { value = "account", text = "Für alle Charaktere" },
    { value = "char",    text = "Nur für diesen Charakter" },
}

local function Find(list, value)
    for _, e in ipairs(list) do if e.value == value then return e end end
    return list[1]
end

-- Der Entwurf (nur diese Sitzung).
MH.draft = {
    kind = "cast", target = "target", mod = "shift", reset = "target",
    spells = { "", "", "", "" }, slot = 1,
    tooltip = true, startattack = false, stopcasting = false,
    when = "", stance = "", trinkets = false, petattack = false, custom = "",
    switch = "stealth", resetSecs = "",
    cancelAura = "", useItem = "", extraMod = "shift",
    name = "", save = "account",
}
local draft = MH.draft

local function Trim(s)
    if type(s) ~= "string" then return "" end
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

--------------------------------------------------
-- Der Text
--------------------------------------------------

-- Bedingungen zu einer Klammer: Teile mit Komma, leere Teile weg.
local function Bracket(a, b)
    local parts = {}
    if a and a ~= "" then parts[#parts + 1] = a end
    if b and b ~= "" then parts[#parts + 1] = b end
    return "[" .. table.concat(parts, ",") .. "]"
end

-- Die Klammern fuer ein Ziel, optional mit einer weiteren Bedingung
-- (Zusatztaste, Kampf, Haltung). "" = keine Klammer noetig.
function MH.Conditions(targetValue, extra)
    if extra == "" then extra = nil end
    local t = Find(MH.TARGETS, targetValue)
    if not t.conds then
        return extra and Bracket(extra) or ""
    end
    local out = {}
    for i, c in ipairs(t.conds) do out[i] = Bracket(extra, c) end
    return table.concat(out)
end

-- Haltung/Gestalt: nur Ziffern, mehrere mit "/" (stance:1/3). nil = keine.
function MH.Stance(v)
    v = Trim(v)
    if v == "" then return nil end
    if not v:match("^%d+[/%d]*$") or v:match("//") or v:match("/$") then return false end
    return "stance:" .. v
end

-- Was fuer jede Klammer des Zaubers gilt (Kampf, Haltung), als Komma-Teil.
function MH.Base(d)
    local parts = {}
    local w = d.when or ""
    if w ~= "" then parts[#parts + 1] = w end
    local st = MH.Stance(d.stance)
    if st then parts[#parts + 1] = st end
    return table.concat(parts, ",")
end

local function With(a, b)
    if a == "" then return b end
    if b == "" then return a end
    return a .. "," .. b
end

local function Join(cond, spell)
    if cond == "" then return spell end
    return cond .. " " .. spell
end

function MH.IsHunter()
    if not _G.UnitClass then return false end
    local _, class = _G.UnitClass("player")
    return class == "HUNTER"
end

-- Name des Autoshots (Zauber 75) vom Client; ohne Antwort der deutsche.
MH.AUTO_SHOT = 75
function MH.AutoShotName()
    local cs = _G.C_Spell
    local n
    if cs and cs.GetSpellName then n = cs.GetSpellName(MH.AUTO_SHOT)
    elseif _G.GetSpellInfo then n = _G.GetSpellInfo(MH.AUTO_SHOT) end
    if type(n) == "string" and n ~= "" then return n end
    return "Automatischer Schuss"
end

-- Der Text des Makros fuer einen Entwurf. Rueckgabe: Text (oder nil),
-- Liste der Erklaerungen (je Zeile), Fehlermeldung.
function MH.Build(d)
    d = d or draft
    local s1, s2, s3, s4 = Trim(d.spells[1]), Trim(d.spells[2]), Trim(d.spells[3]), Trim(d.spells[4] or "")
    if s1 == "" then return nil, {}, "Wähle zuerst einen Zauber." end
    if MH.Stance(d.stance) == false then return nil, {}, "Haltung/Gestalt: nur Nummern, mehrere mit „/“ (z. B. 1/3)." end
    local t = Find(MH.TARGETS, d.target)
    local base = MH.Base(d)
    -- Extras mit Zusatztaste: Aura abbrechen / Gegenstand benutzen. Wird eine
    -- Aura mit der Taste abgebrochen, gilt der Rest nur OHNE Taste (nomod) -
    -- sonst wirkte der Zauber sie gleich wieder.
    local xm = Find(MH.MODS, d.extraMod)
    local cancel, item = Trim(d.cancelAura), Trim(d.useItem)
    if cancel ~= "" then base = With(base, "nomod") end
    local when = Find(MH.WHEN, d.when or "")
    local cond = ""
    if when.explain then cond = " (" .. when.explain end
    if MH.Stance(d.stance) then
        cond = (cond == "" and " (" or (cond .. ", ")) .. "in Haltung/Gestalt " .. Trim(d.stance)
    end
    if cond ~= "" then cond = cond .. ")" end
    local lines, explain = {}, {}
    local function Line(text, why)
        lines[#lines + 1] = text
        explain[#explain + 1] = why
    end
    if d.tooltip and d.kind == "stance" then
        -- Der Zauber, nicht die Haltung: sonst zeigte die Leiste die Haltung.
        Line("#showtooltip " .. s1, "zeigt auf der Leiste Symbol, Abklingzeit und Reichweite von " .. s1)
    elseif d.tooltip then Line("#showtooltip", "zeigt auf der Leiste Symbol, Abklingzeit und Reichweite des Zaubers") end
    if d.stopcasting then Line("/stopcasting", "bricht ab, was du gerade wirkst – der Zauber kommt sofort") end
    if d.trinkets then
        Line("/use 13", "benutzt dein oberes Schmuckstück (wenn es etwas kann und bereit ist)")
        Line("/use 14", "benutzt dein unteres Schmuckstück")
    end
    if cancel ~= "" then
        Line("/cancelaura [mod:" .. xm.value .. "] " .. cancel, string.format("mit %s: bricht %s ab – der Rest gilt nur ohne Taste", xm.text, cancel))
    end
    if item ~= "" then
        Line("/use [mod:" .. xm.value .. "] " .. item, string.format("mit %s: benutzt %s", xm.text, item))
    end
    if d.petattack then Line("/petattack", "schickt deinen Begleiter auf dein Ziel") end
    if d.startattack then
        -- 6.61.19.0 (Beta-Test: "nach Schlangengift oder Arkanem Schuss geht
        -- der Jaeger in den Autohit statt Autoshot"): /startattack ist der
        -- NAHKAMPF-Angriff und ersetzt den Autoshot. Beim Jaeger deshalb
        -- der Autoshot selbst, mit "!" - erneut gedrueckt schaltet er sich
        -- sonst wieder aus.
        local shot = MH.IsHunter() and MH.AutoShotName()
        -- Angriff nur, wo der Zauber auch gilt: nicht verstohlen (sonst
        -- bricht er die Verstohlenheit), nicht mit der Abbruchtaste.
        local ac = ""
        if d.kind == "switch" and d.switch == "stealth" then ac = "nostealth" end
        if d.when == "stealth" then ac = "" elseif d.when == "nostealth" then ac = "nostealth" end
        if cancel ~= "" then ac = With(ac, "nomod") end
        local acb = ac ~= "" and (" [" .. ac .. "]") or ""
        if shot then
            Line("/cast" .. (ac ~= "" and (" [" .. ac .. "]") or "") .. " !" .. shot, "startet den Autoshot auf dein Ziel und schaltet ihn nie aus")
        else
            Line("/startattack" .. acb, "beginnt den automatischen Nahkampfangriff auf dein Ziel" .. (ac:find("nostealth", 1, true) and " – nicht aus der Verstohlenheit" or ""))
        end
    end
    if d.kind == "modifier" then
        if s2 == "" then return nil, {}, "Wähle den zweiten Zauber (mit Zusatztaste)." end
        local m = Find(MH.MODS, d.mod)
        Line("/cast " .. Join(MH.Conditions(d.target, With("mod:" .. m.value, base)), s2) .. "; "
                .. Join(MH.Conditions(d.target, base), s1),
            string.format("mit %s: %s, sonst %s – jeweils %s%s", m.text, s2, s1, t.explain, cond))
    elseif d.kind == "mods" then
        local parts, why = {}, {}
        local keys = { { s2, "shift", "Umschalt" }, { s3, "ctrl", "Strg" }, { s4, "alt", "Alt" } }
        for _, k in ipairs(keys) do
            if k[1] ~= "" then
                parts[#parts + 1] = Join(MH.Conditions(d.target, With("mod:" .. k[2], base)), k[1])
                why[#why + 1] = k[3] .. ": " .. k[1]
            end
        end
        if #parts == 0 then return nil, {}, "Trag mindestens einen Zauber für Umschalt, Strg oder Alt ein (Feld 2 bis 4)." end
        parts[#parts + 1] = Join(MH.Conditions(d.target, base), s1)
        Line("/cast " .. table.concat(parts, "; "),
            string.format("ohne Taste %s, %s – jeweils %s%s", s1, table.concat(why, ", "), t.explain, cond))
    elseif d.kind == "fallback" then
        local list = { s1 }
        for _, x in ipairs({ s2, s3, s4 }) do if x ~= "" then list[#list + 1] = x end end
        if #list < 2 then return nil, {}, "„Erst A, sonst B“ braucht mindestens zwei Zauber." end
        local cc = MH.Conditions(d.target, base)
        for i, x in ipairs(list) do
            Line("/cast " .. Join(cc, x), i == 1 and string.format("versucht zuerst %s %s%s", x, t.explain, cond)
                or string.format("geht %s nicht (Abklingzeit, nicht bereit), dann %s", list[i - 1], x))
        end
    elseif d.kind == "switch" then
        if s2 == "" then return nil, {}, "Trag den Zauber für „sonst“ ein (Feld 2)." end
        local sw = Find(MH.SWITCH, d.switch)
        Line("/cast " .. Join(MH.Conditions(d.target, With(sw.value, base)), s1) .. "; "
                .. Join(MH.Conditions(d.target, base), s2),
            string.format("%s: %s, sonst %s – jeweils %s%s", sw.text, s1, s2, t.explain, cond))
    elseif d.kind == "stance" then
        if s2 == "" then return nil, {}, "Trag die Haltung ein, in der der Zauber geht (Feld 2)." end
        local n = s4:match("^%d+$") and tonumber(s4)
        if not n or n < 1 or n > 10 then
            return nil, {}, "Feld 4: die Nummer dieser Haltung auf deiner Haltungsleiste (z. B. 1 für die erste)."
        end
        Line("/cast " .. Bracket("nostance:" .. n, d.when or "") .. " " .. s2,
            string.format("bist du nicht in %s (Haltung %d), wechselt der Druck erst dorthin", s2, n))
        Line("/cast " .. Join(MH.Conditions(d.target, base), s1),
            string.format("wirkt %s %s%s – aus einer anderen Haltung erst beim zweiten Druck", s1, t.explain, cond))
        if s3 ~= "" then
            Line("/cast " .. Bracket("stance:" .. n, d.when or "") .. " " .. s3,
                string.format("danach zurück in %s", s3))
        end
    elseif d.kind == "sequence" then
        local list = { s1 }
        if s2 ~= "" then list[#list + 1] = s2 end
        if s3 ~= "" then list[#list + 1] = s3 end
        if s4 ~= "" then list[#list + 1] = s4 end
        if #list < 2 then return nil, {}, "Eine Abfolge braucht mindestens zwei Zauber." end
        local r = Find(MH.RESETS, d.reset)
        if r.secs then
            local n = tonumber(Trim(d.resetSecs))
            if not n or n < 1 or n > 600 or n ~= math.floor(n) then return nil, {}, "Sekunden zum Zurücksetzen: eine ganze Zahl von 1 bis 600." end
            r = { word = tostring(n) .. (r.target and "/target" or ""),
                  explain = string.format("beginnt von vorn nach %d s ohne Tastendruck%s", n, r.target and " oder bei neuem Ziel" or "") }
        end
        local cc = MH.Conditions(d.target, base)
        local head = "/castsequence " .. (cc ~= "" and (cc .. " ") or "") .. (r.word and ("reset=" .. r.word .. " ") or "")
        Line(head .. table.concat(list, ", "),
            string.format("jeder Druck wirkt den nächsten: %s – %s%s; %s", table.concat(list, ", dann "), t.explain, cond, r.explain))
    else
        Line("/cast " .. Join(MH.Conditions(d.target, base), s1), string.format("wirkt %s %s%s", s1, t.explain, cond))
    end
    -- Eigene Zeile: unveraendert ans Ende, nur ein Befehl ("/") oder "#".
    local own = Trim(d.custom)
    if own ~= "" then
        if not own:match("^[/#]") then return nil, {}, "Die eigene Zeile muss mit „/“ beginnen (z. B. /cleartarget)." end
        Line(own, "deine eigene Zeile – unverändert übernommen")
    end
    local text = table.concat(lines, "\n")
    if #text > MH.LIMIT then
        return text, explain, string.format("%d Zeichen – das Spiel erlaubt %d. Kürzer: Extras abwählen oder kürzere Zauber.", #text, MH.LIMIT)
    end
    return text, explain, nil
end

-- Kennt das Zauberbuch diesen Namen? nil = weiss nicht. `book`: schon
-- gelesen (die Vorschau fragt drei Felder auf einmal).
function MH.Book()
    local CC = WeintCodex.UIClickCast
    if not (CC and CC.Spellbook) then return nil end
    local ok, book = pcall(CC.Spellbook, false)
    return (ok and type(book) == "table") and book or nil
end

function MH.Known(name, book)
    name = Trim(name)
    if name == "" then return nil end
    book = book or MH.Book()
    if not book or #book == 0 then return nil end
    local base = name:gsub("%(.-%)%s*$", "")
    base = Trim(base)
    for _, sp in ipairs(book) do
        if sp.name == name or sp.name == base then return true end
    end
    return false
end

-- Vorschlag fuer den Namen: der erste Zauber, auf 16 Zeichen.
function MH.DefaultName(d)
    d = d or draft
    local s = Trim(d.spells[1])
    if s == "" then return "WeintCodex" end
    return WeintCodex.Utf8Sub(s, 1, MH.NAME_MAX)
end

function MH.Name(d)
    d = d or draft
    local n = Trim(d.name)
    if n == "" then n = MH.DefaultName(d) end
    if WeintCodex.Utf8Len(n) > MH.NAME_MAX then n = WeintCodex.Utf8Sub(n, 1, MH.NAME_MAX) end
    return n
end

--------------------------------------------------
-- Anlegen
--------------------------------------------------

local function Plain(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b = pcall(fn, ...)
    if not ok then return nil end
    return K.Plain(a), K.Plain(b)
end

MH.last = nil   -- Zeile fuer die Seite: was zuletzt geschah

-- Legt das Makro an oder ersetzt eines mit demselben Namen. Rueckgabe:
-- Index oder nil, Meldung.
function MH.Create(d)
    d = d or draft
    if Plain(_G.InCombatLockdown) then
        MH.last = "Im Kampf legt das Spiel keine Makros an – danach noch einmal."
        return nil, MH.last
    end
    local text, _, err = MH.Build(d)
    if not text or (err and #text > MH.LIMIT) then
        MH.last = err or "Kein Text."
        return nil, MH.last
    end
    if type(_G.CreateMacro) ~= "function" then
        MH.last = "Der Client bietet keine Makros an."
        return nil, MH.last
    end
    local name = MH.Name(d)
    local perChar = d.save == "char"
    local index = Plain(_G.GetMacroIndexByName, name)
    if type(index) == "number" and index > 0 and type(_G.EditMacro) == "function" then
        local ok = pcall(_G.EditMacro, index, name, MH.ICON, text)
        MH.last = ok and string.format("„%s“ ersetzt.", name) or "Das Spiel hat das Ändern abgelehnt."
        return ok and index or nil, MH.last
    end
    -- Platz? (Konto / Charakter)
    local global, char = Plain(_G.GetNumMacros)
    local maxA = tonumber(_G.MAX_ACCOUNT_MACROS) or 120
    local maxC = tonumber(_G.MAX_CHARACTER_MACROS) or 18
    if perChar and type(char) == "number" and char >= maxC then
        MH.last = string.format("Alle %d Plätze dieses Charakters sind belegt.", maxC)
        return nil, MH.last
    end
    if not perChar and type(global) == "number" and global >= maxA then
        MH.last = string.format("Alle %d Plätze für alle Charaktere sind belegt.", maxA)
        return nil, MH.last
    end
    local ok, idx = pcall(_G.CreateMacro, name, MH.ICON, text, perChar)
    idx = ok and K.Plain(idx) or nil
    if not ok or type(idx) ~= "number" then
        MH.last = "Das Spiel hat das Anlegen abgelehnt."
        return nil, MH.last
    end
    MH.last = string.format("„%s“ angelegt (%s). Mit „Aufnehmen“ auf eine Leiste ziehen.", name,
        perChar and "dieser Charakter" or "alle Charaktere")
    return idx, MH.last
end

function MH.Pickup(d)
    d = d or draft
    if Plain(_G.InCombatLockdown) then
        MH.last = "Im Kampf geht das nicht – danach noch einmal."
        return false
    end
    local index = Plain(_G.GetMacroIndexByName, MH.Name(d))
    if type(index) ~= "number" or index < 1 then
        MH.last = "Erst anlegen, dann aufnehmen."
        return false
    end
    local ok = type(_G.PickupMacro) == "function" and pcall(_G.PickupMacro, index)
    MH.last = ok and "Auf dem Mauszeiger – jetzt auf einen Platz einer Leiste ziehen." or "Das Spiel hat das Aufnehmen abgelehnt."
    return ok and true or false
end

--------------------------------------------------
-- Seite
--------------------------------------------------

local function Changed() K.Fire("setting", KEY, "macroDraft") end

MH.FIELD_LABELS = {
    "Zauber 1 – ohne Taste, zuerst, wenn",
    "Zauber 2 – Umschalt, sonst, zweiter",
    "Zauber 3 – Strg, sonst, dritter",
    "Zauber 4 – Alt, sonst, vierter",
}
-- Was ein Feld bei welcher Art bedeutet.
function MH.FieldLabel(i, kind)
    if kind == "mods" then return ({ "Ohne Taste", "Mit Umschalt", "Mit Strg", "Mit Alt" })[i] end
    if kind == "fallback" then return ({ "Zuerst (A)", "Sonst (B)", "Sonst (C)", "Sonst (D)" })[i] end
    if kind == "switch" then return ({ "Wenn die Bedingung gilt", "Sonst" })[i] or ("Zauber " .. i) end
    if kind == "stance" then return ({ "Zauber (z. B. Sturmangriff)", "Haltung davor (z. B. Kampfhaltung)",
        "Haltung danach (leer = bleiben)", "Nummer der Haltung davor (z. B. 1)" })[i] end
    if kind == "modifier" then return ({ "Ohne Taste", "Mit Zusatztaste" })[i] or ("Zauber " .. i) end
    return (i == 1) and "Zauber" or ("Zauber " .. i)
end

local function Field(i)
    return {
        -- Feste Beschriftung (die Suche der Einstellungen liest sie); was ein
        -- Feld bei der gewaehlten Art bedeutet, sagt die Erklaerung unten.
        type = "input", label = MH.FIELD_LABELS[i],
        get = function() return draft.spells[i] end,
        set = function(v) draft.spells[i] = v or "" Changed() end,
        disabled = function()
            local k = draft.kind
            if i == 2 then return k == "cast" end
            if i >= 3 then return not (k == "sequence" or k == "mods" or k == "fallback" or k == "stance") end
            return false
        end,
    }
end

local function SlotItems()
    return { { value = 1, text = "Feld 1" }, { value = 2, text = "Feld 2" }, { value = 3, text = "Feld 3" }, { value = 4, text = "Feld 4" } }
end

-- Die Tafel: Symbole aus dem Zauberbuch; ein Klick fuellt das gewaehlte Feld.
local TILE, GAP, ROWS = 30, 4, 4
function MH.PickerHeight() return 22 + ROWS * (TILE + GAP) + 16 end

function MH.BuildPicker(parent, width)
    local w = CreateFrame("Frame", nil, parent)
    local perRow = math.max(4, math.floor((width + GAP) / (TILE + GAP)))
    local cap = perRow * ROWS
    w.tiles = {}
    w.head = K.NewText(w, 12)
    w.head:SetPoint("TOPLEFT", w, "TOPLEFT", 0, 0)
    w.head:SetWidth(width)
    w.head:SetJustifyH("LEFT")
    w.more = K.NewText(w, 11)
    w.more:SetPoint("TOPLEFT", w, "TOPLEFT", 0, -(22 + ROWS * (TILE + GAP)))
    w.more:SetWidth(width)
    w.more:SetJustifyH("LEFT")
    w.more:SetTextColor(unpack(C.textDim))
    local function Tile(i)
        local t = CreateFrame("Button", nil, w)
        t:SetSize(TILE, TILE)
        local col, row = (i - 1) % perRow, math.floor((i - 1) / perRow)
        t:SetPoint("TOPLEFT", w, "TOPLEFT", col * (TILE + GAP), -(22 + row * (TILE + GAP)))
        t.bg = t:CreateTexture(nil, "BACKGROUND")
        t.bg:SetAllPoints(t)
        t.bg:SetColorTexture(unpack(C.surface2))
        t.icon = t:CreateTexture(nil, "ARTWORK")
        t.icon:SetPoint("TOPLEFT", t, "TOPLEFT", 1, -1)
        t.icon:SetPoint("BOTTOMRIGHT", t, "BOTTOMRIGHT", -1, 1)
        t.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        local hc = K.Highlight()
        t.ring = K.Border(t, 2, hc[1], hc[2], hc[3], 1, "OVERLAY")
        t:SetScript("OnClick", function(self)
            local e = self.entry
            if not e then return end
            MH.Pick(e.name)
        end)
        t:SetScript("OnEnter", function(self)
            local e = self.entry
            if not e then return end
            local tip = _G.GameTooltip
            tip:SetOwner(self, "ANCHOR_TOP")
            if e.id and tip.SetSpellByID then tip:SetSpellByID(e.id) else tip:SetText(e.name, 1, 1, 1) end
            local a = C.accent
            tip:AddLine("Klick: in „Zauber " .. draft.slot .. "“", a[1], a[2], a[3])
            tip:Show()
        end)
        t:SetScript("OnLeave", function() _G.GameTooltip:Hide() end)
        return t
    end
    w.Sync = function()
        w.head:SetText("Klick auf einen Zauber füllt „Zauber " .. draft.slot .. "“.")
        local CC = WeintCodex.UIClickCast
        local book = (CC and CC.Spellbook) and CC.Spellbook(false) or {}
        for i = 1, math.min(#book, cap) do
            local t = w.tiles[i] or Tile(i)
            w.tiles[i] = t
            local e = book[i]
            t.entry = e
            t.icon:SetTexture(e.icon)
            local on = false
            for _, s in ipairs(draft.spells) do if Trim(s) == e.name then on = true end end
            t.ring:SetShown(on)
            t:Show()
        end
        for i = math.min(#book, cap) + 1, #w.tiles do w.tiles[i]:Hide() end
        if #book == 0 then
            w.more:SetText("Im Zauberbuch steht noch nichts, das der Client nennt – Namen oben eintippen geht immer.")
        elseif #book > cap then
            w.more:SetText(string.format("… und %d weitere – die übrigen Namen oben eintippen.", #book - cap))
        else
            w.more:SetText("")
        end
    end
    return w
end

-- Klick in der Tafel: Name ins gewaehlte Feld, dann zum naechsten freien.
function MH.Pick(name)
    if type(name) ~= "string" or name == "" then return false end
    draft.spells[draft.slot] = name
    local k = draft.kind
    local max = (k == "sequence" or k == "mods" or k == "fallback") and 4 or (k == "modifier" or k == "switch") and 2 or 1
    if draft.slot < max then draft.slot = draft.slot + 1 end
    Changed()
    return true
end

MH.PREVIEW_H = 260
function MH.BuildPreview(parent, width)
    local w = CreateFrame("Frame", nil, parent)
    w.bg = w:CreateTexture(nil, "BACKGROUND")
    w.bg:SetAllPoints(w)
    w.bg:SetColorTexture(unpack(C.bgDark))
    K.Border(w, 1, 0, 0, 0, 1, "BORDER")
    w.code = K.NewText(w, 13)
    w.code:SetPoint("TOPLEFT", w, "TOPLEFT", 10, -10)
    w.code:SetWidth(width - 20)
    w.code:SetJustifyH("LEFT")
    w.code:SetJustifyV("TOP")
    w.count = K.NewText(w, 11)
    w.count:SetPoint("TOPRIGHT", w, "TOPRIGHT", -10, -10)
    w.explain = K.NewText(w, 11)
    -- 1.10.30.0: unter dem Text, wie lang er auch ist (komplexe Makros haben
    -- fuenf, sechs Zeilen - bei festen 86 lagen sie uebereinander).
    w.explain:SetPoint("TOPLEFT", w.code, "BOTTOMLEFT", 0, -10)
    w.explain:SetWidth(width - 20)
    w.explain:SetJustifyH("LEFT")
    w.explain:SetJustifyV("TOP")
    w.explain:SetTextColor(unpack(C.textDim))
    w.status = K.NewText(w, 11)
    w.status:SetPoint("BOTTOMLEFT", w, "BOTTOMLEFT", 10, 8)
    w.status:SetWidth(width - 20)
    w.status:SetJustifyH("LEFT")
    w.Sync = function()
        local text, explain, err = MH.Build()
        if text then
            w.code:SetText(text)
            w.code:SetTextColor(unpack(C.textBright))
            local n = #text
            w.count:SetText(string.format("%d / %d", n, MH.LIMIT))
            w.count:SetTextColor(unpack(n > MH.LIMIT and C.dangerBright or C.textMuted))
            local why = {}
            for i, e in ipairs(explain) do why[i] = "• " .. e end
            w.explain:SetText(table.concat(why, "\n"))
        else
            w.code:SetText(err or "")
            w.code:SetTextColor(unpack(C.textDim))
            w.count:SetText("")
            w.explain:SetText("")
        end
        -- Warnung, wenn ein Name nicht im Zauberbuch steht.
        local warn
        local book = MH.Book()
        for i = 1, 4 do
            local s = draft.spells[i]
            if draft.kind == "stance" and i == 4 then s = "" end   -- eine Nummer, kein Zauber
            if MH.Known(s, book) == false then warn = string.format("„%s“ steht nicht in deinem Zauberbuch – dann tut die Zeile nichts.", Trim(s)) break end
        end
        local line = (err and text) and err or warn or MH.last or ""
        w.status:SetText(line)
        w.status:SetTextColor(unpack(((err and text) or warn) and C.warningBright or C.textMuted))
    end
    return w
end

function MH.BuildPage(B)
    B:Section("Was soll das Makro tun?",
        "Drei Fragen statt Makrosprache: was, auf wen, welcher Zauber. Der Text entsteht unten – Zeile für Zeile erklärt.")
    B:Row({ type = "dropdown", label = "Was", items = MH.KINDS,
            get = function() return draft.kind end,
            set = function(v) draft.kind = v if draft.slot > 1 and v == "cast" then draft.slot = 1 end Changed() end },
          { type = "dropdown", label = "Auf wen", items = MH.TARGETS,
            get = function() return draft.target end, set = function(v) draft.target = v Changed() end })
    B:Row({ type = "dropdown", label = "Zusatztaste für den zweiten Zauber", items = MH.MODS,
            get = function() return draft.mod end, set = function(v) draft.mod = v Changed() end,
            disabled = function() return draft.kind ~= "modifier" end },
          { type = "dropdown", label = "Abfolge beginnt von vorn", items = MH.RESETS,
            get = function() return draft.reset end, set = function(v) draft.reset = v Changed() end,
            disabled = function() return draft.kind ~= "sequence" end })
    B:Row({ type = "dropdown", label = "Bedingung (A, wenn sie gilt)", items = MH.SWITCH,
            get = function() return draft.switch end, set = function(v) draft.switch = v Changed() end,
            disabled = function() return draft.kind ~= "switch" end },
          { type = "input", label = "Sekunden zum Zurücksetzen",
            get = function() return draft.resetSecs end, set = function(v) draft.resetSecs = v or "" Changed() end,
            disabled = function() return not (draft.kind == "sequence" and Find(MH.RESETS, draft.reset).secs) end })
    -- (Bedingung und Sekunden stehen in einer Zeile: hoechstens 15 sichtbare
    -- Einstellungen je Seite - "Klick fuellt" und "abbrechen" sind unter Erweitert.)
    B:Section("Welcher Zauber", "Feld wählen, dann einen Zauber anklicken – oder den Namen eintippen (auch Gegenstände).")
    B:Row(Field(1), Field(2))
    B:Row(Field(3), Field(4))
    B:Row({ type = "custom", height = MH.PickerHeight(), create = function(parent, width)
                return MH.BuildPicker(parent, width)
            end }, nil)
    B:Section("Extras")
    B:Row({ type = "toggle", label = "Symbol des Zaubers zeigen", description = "#showtooltip – Symbol, Abklingzeit, Reichweite.",
            get = function() return draft.tooltip end, set = function(v) draft.tooltip = v and true or false Changed() end },
          { type = "toggle", label = "Angriff starten", description = "Nahkampf: /startattack. Jäger: startet den Autoshot (/cast !Automatischer Schuss).",
            get = function() return draft.startattack end, set = function(v) draft.startattack = v and true or false Changed() end })
    B:Advanced()
    B:Row({ type = "dropdown", label = "Speichern", items = MH.SAVE,
            get = function() return draft.save end, set = function(v) draft.save = v Changed() end },
          { type = "empty" })
    B:Row({ type = "toggle", label = "Laufenden Zauber abbrechen", description = "/stopcasting – zum Unterbrechen und Notfallheilen.",
            get = function() return draft.stopcasting end, set = function(v) draft.stopcasting = v and true or false Changed() end },
          { type = "dropdown", label = "Klick in der Tafel füllt", items = SlotItems(),
            get = function() return draft.slot end, set = function(v) draft.slot = v Changed() end })
    B:Row({ type = "dropdown", label = "Wann", items = MH.WHEN,
            get = function() return draft.when end, set = function(v) draft.when = v or "" Changed() end },
          { type = "input", label = "Nur in Haltung/Gestalt (Nummer, z. B. 1 oder 1/3)",
            get = function() return draft.stance end, set = function(v) draft.stance = v or "" Changed() end })
    B:Row({ type = "toggle", label = "Begleiter greift an", description = "/petattack – schickt deinen Begleiter auf dein Ziel.",
            get = function() return draft.petattack end, set = function(v) draft.petattack = v and true or false Changed() end },
          { type = "input", label = "Eigene Zeile am Ende (z. B. /cleartarget)",
            get = function() return draft.custom end, set = function(v) draft.custom = v or "" Changed() end })
    B:Row({ type = "toggle", label = "Schmuckstücke benutzen", description = "/use 13 und /use 14 – beide Schmuckplätze, wenn sie etwas können.",
            get = function() return draft.trinkets end, set = function(v) draft.trinkets = v and true or false Changed() end },
          { type = "dropdown", label = "Zusatztaste für die Extras unten", items = MH.MODS,
            get = function() return draft.extraMod end, set = function(v) draft.extraMod = v Changed() end })
    B:Row({ type = "input", label = "Mit Taste: Aura abbrechen (Name, z. B. ein Buff)",
            get = function() return draft.cancelAura end, set = function(v) draft.cancelAura = v or "" Changed() end },
          { type = "input", label = "Mit Taste: Gegenstand benutzen (Name, z. B. ein Trank)",
            get = function() return draft.useItem end, set = function(v) draft.useItem = v or "" Changed() end })
    B:EndAdvanced()
    B:Section("Ergebnis")
    B:Row({ type = "custom", height = MH.PREVIEW_H, create = function(parent, width)
                return MH.BuildPreview(parent, width)
            end }, nil)
    B:Row({ type = "input", label = "Name (höchstens 16 Zeichen, leer = Zaubername)",
            get = function() return draft.name end, set = function(v) draft.name = v or "" Changed() end },
          { type = "empty" })
    B:Row({ type = "button", label = "Ins Spiel übernehmen", text = "Makro anlegen", kind = "primary",
            onClick = function() MH.Create() Changed() end },
          { type = "button", label = "Auf eine Leiste ziehen", text = "Aufnehmen",
            onClick = function() MH.Pickup() Changed() end })
    B:Note("Gibt es schon ein Makro mit demselben Namen, wird es ersetzt. Anlegen und Aufnehmen gehen nur außerhalb des Kampfes. "
        .. "Alle Makros findest du im Spiel mit /m.")
end

-- Die Seite steht seit 6.9.0.0 im Komfort (ui/comfort.lua haengt sie an):
-- Makros anlegen braucht die Oberflaeche nicht.
