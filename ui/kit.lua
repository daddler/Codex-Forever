--------------------------------------------------
-- WeintCodex :: Oberflaeche - Fundament
--------------------------------------------------
-- Das optionale Oberflaechenpaket. Alles unter ui/ ist ZUSATZ: wer es nie
-- einschaltet, hat dasselbe WeintCodex wie vorher, und kein Blizzard-
-- Rahmen wird angefasst.
--
-- ZWEI ARTEN VON MODULEN, und der Unterschied ist die ganze Idee:
--
--   group = "ui"    Namensplaketten, Einheitenrahmen. Sie ERSETZEN
--                   Blizzard-Rahmen und laufen nur, wenn der Hauptschalter
--                   "WeintCodex-Oberflaeche" an ist UND das Modul selbst.
--                   Aendern verlangt ein Neuladen: einen ersetzten
--                   Blizzard-Rahmen sauber zurueckzugeben ist im laufenden
--                   Spiel nicht zu haben, ohne Taint zu riskieren.
--   group = "qol"   Questpfeil, Komfortfunktionen, Schadensanzeige,
--                   Erinnerungen (seit 6.9.0.0 auch Klickzauber und
--                   Makro-Helfer als Seiten im Komfort). Sie haengen NICHT
--                   am Hauptschalter - wer die Oberflaeche nicht will, soll
--                   das trotzdem haben koennen. Sie schalten sofort, es sei
--                   denn, das Modul sagt `reload = true` (eigene Fenster,
--                   die sich im laufenden Spiel nicht sauber abbauen).
--   Die Regel dahinter: ERSETZT oder KLEIDET ein Teil etwas des Spiels
--   (Rahmen, Leisten, Karte, Chat, Taschen, Fenster), ist es Oberflaeche.
--   FUEGT es etwas hinzu, das dem Spiel fehlt, ist es Komfort.
--
-- VORBILD UND GRENZE. Aufbau, Funktionsumfang und Voreinstellungen folgen
-- EllesmereUI (Stand 9.2.6). Uebernommen sind Ideen, Optionsnamen und
-- Zahlen, KEIN Code und KEINE Grafik: die Vorlage steht unter "all rights
-- reserved". Farben und Schriften sind die von WeintCodex.
--
-- SPEICHER. Ausschliesslich WeintCodex_SavedData.ui - dieselbe Tabelle,
-- die in der .toc steht (Regel aus CLAUDE.md). Gespeichert wird nur, was
-- vom Standard abweicht; der Standard steht beim Modul. Ein Modul, dessen
-- Voreinstellung sich aendert, zieht damit bei allen nach, die den Wert nie
-- angefasst haben.
--
-- PROFILE (6.11.0.4, Beta-Test: "ein grosser Vorteil, wenn man mehrere
-- Charaktere hat"). Einstellungen der Module und Plaetze der Rahmen stehen
-- in ui.profiles[name] = { modules, positions }; welcher Charakter welches
-- nutzt, in ui.profileOf["Name-Realm"]. Ohne Eintrag gilt "Standard" -
-- dorthin ist beim ersten Laden gezogen, was bis 6.11.0.3 fuer alle galt
-- (ui.modules/ui.positions). Fuer das ganze Konto bleiben: Hauptschalter,
-- Willkommen, was ui/profile.lua am Spiel geaendert hat (Layout, CVars),
-- Minikartensymbol, verfolgte Quests. Das Profil einer Sitzung steht fest
-- bis zum Neuladen (K.Profile); gewaehlt, angelegt, kopiert wird in
-- ui/profiles.lua.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIKit = {}

local K = WeintCodex.UIKit
local C = WeintCodex.Colors
local F = WeintCodex.Fonts

local modules, order = {}, {}
K.modules, K.order = modules, order

--------------------------------------------------
-- Geheime Werte
--------------------------------------------------
-- Ab Client 12.0 liefert das Spiel im Kampf viele Einheitenwerte als
-- "secret": sie lassen sich an StatusBar:SetValue und FontString:SetText
-- weiterreichen, aber nicht vergleichen und nicht rechnen - ein `<` darauf
-- ist ein Lua-Fehler. Forever laeuft nach allem, was bekannt ist, auf
-- diesem Unterbau. Jede Stelle, die einen Wert VERGLEICHT, fragt vorher.
--------------------------------------------------

function K.IsSecret(v)
    local f = _G.issecretvalue
    return f ~= nil and f(v) and true or false
end

-- Ein Wert, mit dem Lua rechnen darf - oder nil, wenn nicht.
function K.Plain(v)
    if K.IsSecret(v) then return nil end
    return v
end

-- Ein Wahrheitswert, der geheim sein koennte, als `true`/`false`. Geheim
-- zaehlt als `fallback` - der Aufrufer sagt, welcher Irrtum der billigere ist.
function K.Bool(v, fallback)
    if K.IsSecret(v) then return fallback and true or false end
    return v and true or false
end

--------------------------------------------------
-- Eigene Lage ohne Wegwerf-Vektoren (6.14.0.2)
--------------------------------------------------
-- /wcui speicher: Questpfeil 26 KB/s, Minikarte 3,6 KB/s. GetPlayerMapPosition
-- und GetWorldPosFromMapPos legen je Aufruf einen Vektor an (eine Tabelle
-- mit allen Methoden des Mixins); der Pfeil fragte fuenfmal je Sekunde, die
-- Minikarte zweimal, die Weltkarte zehnmal. UnitPosition nennt nur Zahlen.
-- Genommen wird es erst, wenn es mit dem Weg ueber die Karte uebereinstimmt
-- (gleicher Kontinent, auf 2 Einheiten genau, nicht auf der Diagonale, wo
-- vertauschte Achsen gleich aussaehen) - geprueft beim ersten Mal und
-- wieder alle K.POS_CHECK_EVERY s. Stimmt es nicht oder schweigt der Client
-- (Instanzen, geheime Werte), bleibt es beim Weg ueber die Karte.
K.POS_CHECK_EVERY = 10
local posFast = { ok = false, at = -math.huge }
K._posFast = posFast
local vec   -- ein Vektor fuer alle eigenen Umrechnungen

function K.BestMap()
    local cm = _G.C_Map
    if not (cm and cm.GetBestMapForUnit) then return nil end
    local ok, m = pcall(cm.GetBestMapForUnit, "player")
    m = ok and K.Plain(m) or nil
    return type(m) == "number" and m or nil
end

-- Weltlage eines Kartenpunkts: Kontinent, Norden, Westen (oder nil).
function K.ToWorld(mapID, x, y)
    local cm = _G.C_Map
    if not (cm and cm.GetWorldPosFromMapPos and _G.CreateVector2D) then return nil end
    if vec and vec.SetXY then vec:SetXY(x, y) else vec = _G.CreateVector2D(x, y) end
    local ok, continent, world = pcall(cm.GetWorldPosFromMapPos, mapID, vec)
    if not ok or type(world) ~= "table" then return nil end
    local n, w = world.x, world.y
    if world.GetXY then n, w = world:GetXY() end
    continent, n, w = K.Plain(continent), K.Plain(n), K.Plain(w)
    if type(n) ~= "number" or type(w) ~= "number" then return nil end
    return continent, n, w
end

-- Der Weg ueber die Karte (legt Vektoren an): Karte, x, y.
function K.MapPosSlow(map)
    local cm = _G.C_Map
    map = map or K.BestMap()
    if not (map and cm and cm.GetPlayerMapPosition) then return nil end
    local ok, pos = pcall(cm.GetPlayerMapPosition, map, "player")
    if not ok or type(pos) ~= "table" then return nil end
    local x, y = pos.x, pos.y
    if pos.GetXY then x, y = pos:GetXY() end
    x, y = K.Plain(x), K.Plain(y)
    if type(x) ~= "number" or type(y) ~= "number" then return nil end
    return map, x, y
end

local function UnitWorld()
    if not _G.UnitPosition then return nil end
    local ok, n, w, _, inst = pcall(_G.UnitPosition, "player")
    if not ok then return nil end
    n, w, inst = K.Plain(n), K.Plain(w), K.Plain(inst)
    if type(n) ~= "number" or type(w) ~= "number" or type(inst) ~= "number" then return nil end
    return inst, n, w
end

local function Now() return (_G.GetTime and K.Plain(_G.GetTime())) or 0 end
local function FastNow(now) return posFast.ok and now - posFast.at < K.POS_CHECK_EVERY end

-- Ueber die Karte und dabei abgleichen. Liefert Kontinent, Norden, Westen.
local function WorldSlow(now)
    local map, px, py = K.MapPosSlow()
    if not map then return nil end
    local pc, pN, pW = K.ToWorld(map, px, py)
    if not pc then return nil end
    local uc, un, uw = UnitWorld()
    posFast.ok = uc ~= nil and uc == pc and math.abs(un - pN) < 2 and math.abs(uw - pW) < 2
        and math.abs(pN - pW) > 10
    posFast.at = now
    return pc, pN, pW
end

-- Kontinent, Norden, Westen des Spielers - oder nil.
function K.PlayerWorld()
    local now = Now()
    if FastNow(now) then
        local c, n, w = UnitWorld()
        if c then return c, n, w end
    end
    return WorldSlow(now)
end

-- Die Ecken einer Karte in der Welt, je Karte einmal gerechnet.
local rects = {}
local function Rect(map)
    local r = rects[map]
    if r == nil then
        local c0, n0, w0 = K.ToWorld(map, 0, 0)
        local c1, n1, w1 = K.ToWorld(map, 1, 1)
        if c0 and c0 == c1 and n1 ~= n0 and w1 ~= w0 then
            r = { c = c0, n0 = n0, w0 = w0, dn = n1 - n0, dw = w1 - w0 }
        else
            r = false
        end
        rects[map] = r
    end
    return r or nil
end

-- Wo auf Karte `map` (Standard: die eigene) der Spieler steht, 0..1 -
-- oder nil (andere Karte, Instanz, Client schweigt).
function K.PlayerMapXY(map)
    map = map or K.BestMap()
    if not map then return nil end
    local now = Now()
    if not FastNow(now) then
        WorldSlow(now)
        if not FastNow(now) then
            local _, x, y = K.MapPosSlow(map)
            return x, y
        end
    end
    local r = Rect(map)
    local c, n, w = UnitWorld()
    if not (r and c) then
        local _, x, y = K.MapPosSlow(map)
        return x, y
    end
    if c ~= r.c then return nil end
    local x, y = (w - r.w0) / r.dw, (n - r.n0) / r.dn
    if x < 0 or x > 1 or y < 0 or y > 1 then return nil end
    return x, y
end

--------------------------------------------------
-- Laune des Begleiters (6.13.1.0)
--------------------------------------------------
-- Beta-Test: "Ich brauche als Hunter die Moeglichkeit, dass ich sehen
-- kann, wie gluecklich mein Pet ist." Der Rahmen des Spiels zeigt sie als
-- Gesicht - die Oberflaeche versteckt ihn. Gemessen ist nur, dass der
-- Client die Laune kennt (`PetPaperDollPetHappinessInfo` im
-- Charakterfenster, /wcui fenster); GetPetHappiness ist die Abfrage der
-- Classic-Clients: 1 ungluecklich, 2 zufrieden, 3 gluecklich. Ohne die
-- Funktion, ohne Jaegerbegleiter (Wichtel: nil) oder geheim: nil - dann
-- zeigt nichts eine Laune an, nie "ungluecklich".
--
-- GEMESSEN MIT 6.13.2.0 (/wcui pruefen, Client 1.60.1): GetPetHappiness
-- gibt es auf Forever nicht, wohl aber C_PetInfo.GetPetHappiness; die
-- Energieart Happiness (27, hoechstens 1000) ist selbst ausser Kampf
-- geheim. GEMESSEN MIT 6.13.3.0: C_PetInfo.GetPetHappiness() ausser Kampf
-- offen "3, 125, 20" - Laune, Schaden in Prozent, Treuerate wie in Classic;
-- mit und ohne "pet" gleich. Die Gegenprobe bleibt: liefert die Abfrage wie in Classic
-- als zweiten Wert den Schaden in Prozent, muss er zur Laune passen
-- (75/100/125). Passt er nicht, ist die Bedeutung eine andere - dann
-- lieber kein Punkt als eine falsche Farbe. Ohne Antwort ohne Argument
-- wird einmal mit "pet" gefragt.
K.HAPPINESS = {
    [1] = { text = "unglücklich", color = "danger" },
    [2] = { text = "zufrieden",   color = "warning" },
    [3] = { text = "glücklich",   color = "success" },
}
K.HAPPY_DAMAGE = { [1] = 75, [2] = 100, [3] = 125 }

-- Eine Antwort pruefen: Laune 1-3, offen, und - wenn mitgeliefert - der
-- passende Schaden. Sonst nil.
local function HappyFrom(ok, h, dmg)
    if not ok then return nil end
    h, dmg = K.Plain(h), K.Plain(dmg)
    if type(h) ~= "number" or not K.HAPPINESS[h] then return nil end
    if type(dmg) == "number" and dmg ~= K.HAPPY_DAMAGE[h] then return nil end
    return h
end
K._HappyFrom = HappyFrom

local function AskHappiness(f)
    if type(f) ~= "function" then return nil end
    return HappyFrom(pcall(f)) or HappyFrom(pcall(f, "pet"))
end

-- Die Quellen, in dieser Reihenfolge: Classic, dann Forever.
function K.PetHappinessSource()
    if type(_G.GetPetHappiness) == "function" then return _G.GetPetHappiness, "GetPetHappiness" end
    local pi = _G.C_PetInfo
    if type(pi) == "table" and type(pi.GetPetHappiness) == "function" then
        return pi.GetPetHappiness, "C_PetInfo.GetPetHappiness"
    end
    return nil
end

function K.PetHappiness()
    return AskHappiness((K.PetHappinessSource()))
end

--------------------------------------------------
-- Speicher
--------------------------------------------------

K.DEFAULT_PROFILE = "Standard"

local function Root()
    local sv = WeintCodex.SavedData
    if not sv then return nil end
    sv.ui = sv.ui or {}
    local ui = sv.ui
    if type(ui.profiles) ~= "table" then
        -- Umzug (einmal): was bis 6.11.0.3 fuer alle galt, ist "Standard".
        ui.profiles = { [K.DEFAULT_PROFILE] = { modules = ui.modules or {}, positions = ui.positions or {} } }
        ui.modules, ui.positions = nil, nil
    end
    -- "Standard" gibt es immer: der Platz jedes Charakters ohne Wahl.
    ui.profiles[K.DEFAULT_PROFILE] = ui.profiles[K.DEFAULT_PROFILE] or {}
    ui.profileOf = ui.profileOf or {}
    return ui
end

function K.Root() return Root() end

-- "Name-Realm" des Spielers; nil, solange der Client ihn nicht nennt.
function K.CharKey()
    local okN, name = pcall(_G.UnitName, "player")
    local okR, realm = pcall(_G.GetRealmName)
    if okN and okR and type(name) == "string" and name ~= "" and type(realm) == "string" and realm ~= "" then
        return name .. "-" .. realm
    end
    return nil
end

-- Das Profil, das dieser Charakter gewaehlt hat; ohne Wahl (oder wenn
-- seins geloescht ist) "Standard".
function K.ChosenProfile(ui)
    ui = ui or Root()
    if not ui then return nil end
    local key = K.CharKey()
    local name = key and ui.profileOf[key]
    if type(name) == "string" and ui.profiles[name] then return name end
    return K.DEFAULT_PROFILE
end

-- Das Profil dieser Sitzung: beim ersten Zugriff gewaehlt, danach fest
-- bis zum Neuladen - laufende Module lesen nie mitten im Spiel aus einem
-- anderen. Nur festgehalten, wenn der Client den Charakter nennt.
local active
function K.Profile()
    local ui = Root()
    if not ui then return nil end
    local name = active
    if not (name and ui.profiles[name]) then
        name = K.ChosenProfile(ui)
        if K.CharKey() then active = name end
    end
    local p = ui.profiles[name]
    p.modules = p.modules or {}
    p.positions = p.positions or {}
    return p, name
end

function K.ActiveProfile() return select(2, K.Profile()) end

-- Nur fuer ui/profiles.lua (Umbenennen des laufenden Profils) und den
-- Prueflauf (neue Sitzung).
function K._SetActiveProfile(name) active = name end

-- Die gespeicherten Abweichungen eines Moduls (nie nil, sobald SavedData
-- steht; davor eine leere Tabelle, die nie gespeichert wird - gelesen wird
-- davor nur der Standard).
local EMPTY = {}
local function Store(key)
    local p = K.Profile()
    if not p then return EMPTY end
    p.modules[key] = p.modules[key] or {}
    return p.modules[key]
end

local function CopyValue(v)
    if type(v) ~= "table" then return v end
    local out = {}
    for k, x in pairs(v) do out[k] = x end
    return out
end

-- RAHMEN UND HERVORHEBUNGEN (6.6.2.4, Beta-Test: "statt der lila Rahmen
-- ueberall lieber Rahmen in der Farbe der Klasse"). Seit 6.6.3.1 ist der
-- Akzent selbst die Klassenfarbe (core/ui.lua, WeintCodex.SetAccent) -
-- im ganzen Addon, nicht nur in Rahmen. K.Highlight ist damit der Akzent;
-- der Name bleibt, weil ihn Dutzende Stellen rufen.
-- "general.highlight = accent" schaltet auf Violett zurueck. Die
-- Einstellungen gibt es erst nach dem Laden (ADDON_LOADED); bis dahin
-- steht die Klassenfarbe, und die Oberflaeche baut sich erst danach auf.
-- Ein Wechsel gilt nach dem Neuladen.
function K.Highlight()
    return WeintCodex.Colors.accent
end

-- 6.21.1.0 (Beta-Test: "nach seinen eigenen Praeferenzen, als dritte
-- Option"): "custom" nimmt die Farbe aus highlightColor - weiter EIN
-- Akzent, nur einer, den der Spieler waehlt.
function K.ResetHighlight()
    local h = K.Get("general", "highlight")
    if h == "accent" then WeintCodex.SetVioletAccent()
    elseif h == "custom" then
        local c = K.GetColor("general", "highlightColor")
        WeintCodex.SetAccent(c.r, c.g, c.b)
    else WeintCodex.ApplyClassAccent() end
end

-- Farbvorgabe aus core/ui.lua als { r, g, b }.
function K.ColorDefault(name)
    local col = (WeintCodex.GameColors and WeintCodex.GameColors[name])
        or C[name] or C.textNormal
    return { r = col[1], g = col[2], b = col[3] }
end

function K.Get(moduleKey, key)
    local v = Store(moduleKey)[key]
    if v ~= nil then return v end
    local m = modules[moduleKey]
    return m and m.defaults and m.defaults[key]
end

function K.Set(moduleKey, key, value)
    local m = modules[moduleKey]
    local store = Store(moduleKey)
    local default = m and m.defaults and m.defaults[key]

    -- Gleich dem Standard -> Eintrag entfernen. Sonst hielte die Datei
    -- einen Wert fest, der beim naechsten Standardwechsel nicht mitzoege.
    local same = (value == default)
    if not same and type(value) == "table" and type(default) == "table" then
        same = true
        for k, x in pairs(value) do
            if default[k] ~= x then same = false break end
        end
    end
    -- Kein `(not same) and CopyValue(value) or nil`: fuer value == false
    -- ergibt das nil, und ein Schalter, der von "an" (Standard) auf "aus"
    -- gestellt wird, waere nie gespeichert worden. Genau so war es bis
    -- 6.0.0.3 - keine standardmaessig eingeschaltete Option liess sich
    -- abschalten.
    if same then
        store[key] = nil
    else
        store[key] = CopyValue(value)
    end

    if m and m.OnSetting then
        local ok, err = pcall(m.OnSetting, key, value)
        if not ok then K.Report(moduleKey, err) end
    end
    K.Fire("setting", moduleKey, key)
end

-- Farbe: immer eine frische Tabelle zurueck, nie die gespeicherte -
-- ein Aufrufer, der darin schreibt, schriebe sonst am Speicher vorbei in
-- ihn hinein.
function K.GetColor(moduleKey, key)
    local c = K.Get(moduleKey, key)
    if type(c) ~= "table" then return { r = 1, g = 1, b = 1 } end
    return { r = c.r or 1, g = c.g or 1, b = c.b or 1 }
end

function K.ResetModule(moduleKey)
    local p = K.Profile()
    if not p then return end
    local enabled = p.modules[moduleKey] and p.modules[moduleKey].enabled
    p.modules[moduleKey] = { enabled = enabled }
    local m = modules[moduleKey]
    if m and m.OnSetting then pcall(m.OnSetting, "*") end
    K.Fire("setting", moduleKey, "*")
end

--------------------------------------------------
-- Hauptschalter
--------------------------------------------------

-- DER HAUPTSCHALTER (seit 6.9.0.0 wieder in Kraft).
--
-- Die Oberflaeche ist freiwillig: Frage beim Einloggen (ui/welcome.lua),
-- Hauptschalter in /wcui und in den Einstellungen. Von 6.0.0.3 bis 6.8.1.0
-- war sie fuer alle an, weil der Forever-Beta-Client die SavedVariables
-- nicht speicherte - eine Wahl, die nach jedem Neuladen vergessen ist, ist
-- keine. Seit der Client wieder speichert (Beta-Test nach 6.8.1.0), gilt
-- die Wahl wieder.
--
-- K.OPT_IN ist die EINE Stelle, an der das umgeschaltet wird. Steht es
-- auf false, ist die Oberflaeche wieder fuer alle an, ohne weitere
-- Aenderung (keine Frage, kein Hauptschalter); load_test.lua prueft beide
-- Zustaende.
--
-- Was die Oberflaeche am Spiel aendert (Layout des Bearbeitungsmodus,
-- Spieleinstellungen), merkt sich ui/profile.lua vorher und gibt es beim
-- Ausschalten zurueck - der Hauptschalter ruft es (PF.OnSwitch).
K.OPT_IN = true

-- JE CHARAKTER (6.26.8.0, Beta-Test: "Nutzer sollen fuer jeden einzelnen
-- Charakter entscheiden, ob sie die Oberflaeche nutzen"). Der Schalter, das
-- gemerkte Layout von vorher und die gemerkten Spieleinstellungen
-- (ui/profile.lua) liegen in `ui.chars[Name-Realm]`. Die Werte von vorher
-- (`ui.enabled`, `ui.before`, `ui.cvars`, bis 6.26.7.0 fuer den Account)
-- uebernimmt ein Charakter beim ersten Einloggen nach dem Update - aber nur
-- einer, den WeintCodex schon kennt (K.KnownChar). Ein neuer beginnt ohne
-- Oberflaeche und wird gefragt (ui/welcome.lua).
local function DeepCopy(t)
    if type(t) ~= "table" then return t end
    local c = {}
    for k, v in pairs(t) do c[k] = DeepCopy(v) end
    return c
end

function K.KnownChar(key)
    local ui = Root()
    if not (ui and key) then return false end
    if (ui.welcomed and ui.welcomed[key]) or (ui.profileAsked and ui.profileAsked[key])
       or (ui.profileOf and ui.profileOf[key]) then
        return true
    end
    local sd = WeintCodex.SavedData
    local inv = type(sd) == "table" and sd.inventory
    for _, c in pairs(inv and inv.chars or {}) do
        if type(c) == "table" and c.name and c.realm and (c.name .. "-" .. c.realm) == key then return true end
    end
    if key == K.CharKey() then
        local lvl = _G.UnitLevel and K.Plain(_G.UnitLevel("player"))
        if type(lvl) == "number" and lvl > 1 then return true end
        -- Stufe noch unbekannt (sehr frueh beim Laden): nicht entscheiden.
        if type(lvl) ~= "number" or lvl < 1 then return nil end
    end
    return false
end

-- Der Stand dieses Charakters, oder nil ohne Charakterschluessel.
function K.CharState()
    local ui = Root()
    local key = K.CharKey()
    if not (ui and key) then return nil end
    ui.chars = ui.chars or {}
    local st = ui.chars[key]
    if not st then
        local known = ui.enabled ~= nil and K.KnownChar(key)
        -- Unentschieden: noch nichts anlegen, bis dahin gilt der alte Wert.
        if ui.enabled ~= nil and known == nil then return nil end
        st = {}
        if known then
            st.enabled = ui.enabled == true
            st.before = DeepCopy(ui.before)
            st.cvars = DeepCopy(ui.cvars)
        end
        ui.chars[key] = st
    end
    return st
end

function K.UIEnabled()
    if not K.OPT_IN then return true end
    local st = K.CharState()
    if st then return st.enabled == true end
    local ui = Root()
    return ui ~= nil and ui.enabled == true
end

-- Wird der Hauptschalter umgelegt, ist ein Neuladen faellig (siehe oben).
-- Ohne OPT_IN gibt es nichts umzulegen. Auch ein "aus", das schon aus
-- war, laeuft durch das Profil: wer die Oberflaeche vor 6.9.0.0 hatte,
-- steht noch im Layout "WeintCodex" und bekommt seins zurueck.
function K.SetUIEnabled(on)
    if not K.OPT_IN then return end
    local ui = Root()
    if not ui then return end
    on = on and true or false
    local was = K.UIEnabled()
    local st = K.CharState()
    if st then st.enabled = on else ui.enabled = on end
    if was ~= on then K.MarkReload() end
    K.Fire("setting", "general", "enabled")
    local PF = WeintCodex.UIProfile
    if PF and PF.OnSwitch then
        local ok, err = pcall(PF.OnSwitch, on)
        if not ok then K.Report("profil", err) end
    end
end

function K.ModuleEnabled(moduleKey)
    local m = modules[moduleKey]
    if not m then return false end
    local v = Store(moduleKey).enabled
    if v == nil then
        -- defaultEnabled = "ui": von Haus aus an, wenn die Oberflaeche an ist
        -- (das Komplettpaket), sonst aus - wer "Nein" zur Oberflaeche sagt,
        -- bekommt kein Fenster, das er nicht gewaehlt hat (6.9.0.0).
        if m.defaultEnabled == "ui" then v = K.UIEnabled()
        else v = m.defaultEnabled ~= false end
    end
    return v and true or false
end

-- Laeuft das Modul in DIESER Sitzung? Fuer ui-Module ist das der Stand
-- beim Anmelden, nicht der gespeicherte - der gilt erst nach dem Neuladen.
function K.IsActive(moduleKey)
    local m = modules[moduleKey]
    return m ~= nil and m._active == true
end

-- Wuerde das Modul nach dem naechsten Laden laufen?
function K.WantsActive(moduleKey)
    local m = modules[moduleKey]
    if not m then return false end
    if m.group == "ui" and not K.UIEnabled() then return false end
    return K.ModuleEnabled(moduleKey)
end

local reloadPending = false
function K.MarkReload() reloadPending = true K.Fire("reload") end
function K.ReloadPending() return reloadPending end

function K.SetModuleEnabled(moduleKey, on)
    local m = modules[moduleKey]
    if not m then return end
    Store(moduleKey).enabled = on and true or false

    if m.group == "ui" or m.reload then
        K.MarkReload()
    elseif on then
        K.Activate(moduleKey)
    else
        K.Deactivate(moduleKey)
    end
    K.Fire("setting", moduleKey, "enabled")
    K.SweepProfile()
end

-- Spieleinstellungen, die kein laufender Teil mehr braucht, zurueck
-- (ui/profile.lua).
function K.SweepProfile()
    local PF = WeintCodex.UIProfile
    if PF and PF.Sweep then
        local ok, err = pcall(PF.Sweep)
        if not ok then K.Report("profil", err) end
    end
end

--------------------------------------------------
-- Modulregister
--------------------------------------------------
-- def = {
--   key, group = "ui"|"qol", title, description, order,
--   defaults = { ... }, defaultEnabled = true|false|"ui",
--   reload = true,             -- qol: Schalten wirkt erst nach dem Neuladen
--   Enable = function() end,   -- beim Anmelden bzw. beim Einschalten
--   Disable = function() end,  -- nur qol: beim Ausschalten
--   OnSetting = function(key, value) end,
--   pages = { { key, label, build = function(B) end }, ... },
--   preview = function(parent) return frame, height end,  -- optional
--   status = function() return text, tone end,             -- optional
-- }
--------------------------------------------------

function K.Register(def)
    assert(type(def) == "table" and def.key, "UIKit.Register: key fehlt")
    def.defaults = def.defaults or {}
    def.pages = def.pages or {}
    if not modules[def.key] then order[#order + 1] = def.key end
    modules[def.key] = def
    table.sort(order, function(a, b)
        return (modules[a].order or 100) < (modules[b].order or 100)
    end)
    return def
end

function K.Module(key) return modules[key] end

-- Ein Fehler in einem Modul darf die anderen nicht mitnehmen. Gemeldet
-- wird er trotzdem - einmal, in den Chat, mit dem Modulnamen: still
-- verschluckt saehe er aus wie ein Modul, das nichts tut.
local reported = {}
K.errors = {}
--------------------------------------------------
-- Messen: wer erzeugt wie viel Wegwerf-Speicher? (/wcui speicher)
--------------------------------------------------
-- Beta-Test 6.6.1.7: "Das Addon verbraucht zwischen 10 und 30-40 MB,
-- danach ein kleiner Reset, und es faengt ab 8 MB wieder an." Das ist
-- kein Leck, sondern Wegwerf-Speicher: Tabellen und Texte, die bei jedem
-- Ereignis entstehen und die die Speicherbereinigung spaeter einsammelt.
-- Welcher Teil wie viel erzeugt, sagt der Client nicht - nur die Summe
-- (GetAddOnMemoryUsage). K.Measured legt sich um die Takte und
-- Ereignisse der Teile, die oft laufen, und zaehlt, solange eine Messung
-- laeuft: Aufrufe, neu belegten Speicher (collectgarbage "count" davor
-- und danach) und Zeit. Ohne Messung kostet die Huelle eine Abfrage.
-- Ungenau nach unten: raeumt die Bereinigung mitten in einem Aufruf auf,
-- zaehlt der nichts. Fuer eine Rangfolge reicht es.
K.prof = { on = false, data = {}, started = nil }

local function GcCount()
    local f = _G.collectgarbage
    if type(f) ~= "function" then return nil end
    local ok, v = pcall(f, "count")
    return ok and type(v) == "number" and v or nil
end
K.GcCount = GcCount

local function Clock()
    local f = _G.debugprofilestop
    return type(f) == "function" and f() or nil
end

local function Account(name, m0, t0, ...)
    local m1, t1 = GcCount(), Clock()
    local e = K.prof.data[name]
    if not e then
        e = { calls = 0, kb = 0, ms = 0 }
        K.prof.data[name] = e
    end
    e.calls = e.calls + 1
    if m0 and m1 and m1 > m0 then e.kb = e.kb + (m1 - m0) end
    if t0 and t1 then e.ms = e.ms + (t1 - t0) end
    return ...
end

function K.Measured(name, fn)
    return function(...)
        if not K.prof.on then return fn(...) end
        local m0, t0 = GcCount(), Clock()
        return Account(name, m0, t0, fn(...))
    end
end

local function AddonKB()
    if _G.UpdateAddOnMemoryUsage then pcall(_G.UpdateAddOnMemoryUsage) end
    local get = (_G.C_AddOns and _G.C_AddOns.GetAddOnMemoryUsage) or _G.GetAddOnMemoryUsage
    if type(get) ~= "function" then return nil end
    local ok, v = pcall(get, "WeintCodex")
    return ok and type(v) == "number" and v or nil
end
K.AddonKB = AddonKB

-- Messung starten; nach `secs` Sekunden ruft sie done(zeilen).
function K.ProfileRun(secs, done)
    local P = K.prof
    wipe(P.data)
    P.on = true
    P.started = _G.GetTime and _G.GetTime() or 0
    P.kb0 = AddonKB()
    P.inCombat = K.InCombat()
    local function Finish()
        P.on = false
        done(K.ProfileReport(secs))
    end
    if _G.C_Timer and _G.C_Timer.After then _G.C_Timer.After(secs, Finish) else Finish() end
end

-- Zeilen fuer den Chat: Gesamtbild, dann die groessten Erzeuger je Sekunde.
function K.ProfileReport(secs)
    local P = K.prof
    local out = {}
    local kb1 = AddonKB()
    out[#out + 1] = string.format("Speicher jetzt %s", type(kb1) == "number"
        and string.format("%.1f MB", kb1 / 1024) or "unbekannt")
    if type(P.kb0) == "number" and type(kb1) == "number" then
        local d = kb1 - P.kb0
        out[#out + 1] = string.format("In %d s %s um %.0f KB (%.1f KB/s)%s", secs,
            d >= 0 and "gewachsen" or "gefallen (Bereinigung lief)", math.abs(d), d / secs,
            P.inCombat and ", im Kampf gestartet" or "")
    end
    -- Was davon Abfall war (6.14.0.2): einmal ganz aufraeumen und neu
    -- messen. "Speicher jetzt" zaehlt Abfall mit, bis die Bereinigung des
    -- Spiels ihn holt - erst der Wert danach ist, was WeintCodex wirklich haelt.
    if type(kb1) == "number" and P.collect ~= false and type(_G.collectgarbage) == "function"
       and pcall(_G.collectgarbage, "collect") then
        local kb2 = AddonKB()
        if type(kb2) == "number" then
            out[#out + 1] = string.format("Nach dem Aufräumen %.1f MB (%.1f MB waren Abfall)", kb2 / 1024,
                math.max(0, kb1 - kb2) / 1024)
        end
    end
    local list, sum = {}, 0
    for name, e in pairs(P.data) do
        list[#list + 1] = { name = name, e = e }
        sum = sum + e.kb
    end
    table.sort(list, function(a, b) return a.e.kb > b.e.kb end)
    if #list == 0 then
        out[#out + 1] = "Kein gemessener Teil lief."
        return out
    end
    if not GcCount() then out[#out + 1] = "Speicher je Teil nicht messbar (collectgarbage fehlt) – nur Zeit." end
    out[#out + 1] = string.format("Gemessene Teile zusammen: %.1f KB/s", sum / secs)
    for i = 1, math.min(8, #list) do
        local e = list[i].e
        out[#out + 1] = string.format("%d. %s: %.1f KB/s, %.0f Aufrufe/s, %.2f ms/s", i, list[i].name,
            e.kb / secs, e.calls / secs, e.ms / secs)
    end
    return out
end

function K.Report(moduleKey, err)
    local key = tostring(moduleKey) .. tostring(err)
    if reported[key] then return end
    reported[key] = true
    -- Fuer /wcui pruefen (6.10.2.0): was seit dem Laden schiefging.
    K.errors[#K.errors + 1] = tostring(moduleKey) .. ": " .. tostring(err)
    print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " "
        .. WeintCodex.ColorText("warning", "Oberfläche/" .. tostring(moduleKey)
        .. ": ") .. tostring(err))
end

function K.Activate(moduleKey)
    local m = modules[moduleKey]
    if not m or m._active then return end
    if m.Enable then
        local ok, err = pcall(m.Enable)
        if not ok then K.Report(moduleKey, err) return end
    end
    m._active = true
    K.Fire("active", moduleKey)
end

function K.Deactivate(moduleKey)
    local m = modules[moduleKey]
    if not m or not m._active then return end
    if m.Disable then
        local ok, err = pcall(m.Disable)
        if not ok then K.Report(moduleKey, err) end
    end
    m._active = false
    K.Fire("active", moduleKey)
end

--------------------------------------------------
-- Rueckrufe (fuer das Einstellungsfenster)
--------------------------------------------------

local listeners = {}
function K.Listen(fn) listeners[#listeners + 1] = fn end

-- 3D-Modelle (Portraets) folgen der Durchsichtigkeit ihrer Eltern nicht -
-- wer die Oberflaeche ausblendet (ui/dialogue.lua), muss sie kennen.
K.models = setmetatable({}, { __mode = "k" })
function K.TrackModel(m) if type(m) == "table" then K.models[m] = true end end
function K.Fire(kind, ...)
    for _, fn in ipairs(listeners) do pcall(fn, kind, ...) end
end

--------------------------------------------------
-- Kampfsperre
--------------------------------------------------
-- Geschuetzte Rahmen (Einheitenrahmen, Blizzard-Rahmen, die wir
-- verstecken) duerfen im Kampf weder bewegt noch umgehaengt werden. Was
-- in den Kampf faellt, wird danach nachgeholt statt verworfen.
--------------------------------------------------

local afterCombat = {}
function K.InCombat()
    return _G.InCombatLockdown ~= nil and _G.InCombatLockdown() and true or false
end

function K.AfterCombat(fn)
    if not K.InCombat() then
        fn()
        return
    end
    afterCombat[#afterCombat + 1] = fn
end

--------------------------------------------------
-- Schriften und Balken
--------------------------------------------------
-- In der Spielwelt gilt eine Ausnahme von der Regel "kein OUTLINE" aus
-- core/ui.lua: das Fenster steht auf einer ruhigen, dunklen Flaeche, eine
-- Namensplakette ueber Gras, Schnee und Zauberwirkungen. Ohne Kontur ist
-- sie dort nicht lesbar. Die Kontur ist deshalb einstellbar und
-- standardmaessig duenn.
--------------------------------------------------

-- Seit 6.1.0.0 ist die schmale Plex (Condensed) der Standard: Namen und
-- Zahlen auf Plaketten und Rahmen brauchen Breite, nicht Hoehe. Wer die
-- breite Plex von vorher will, stellt sie unter Allgemein ein.
-- 6.26.5.0: weitere Schriften (Schluessel = Feld in WeintCodex.Fonts).
K.EXTRA_FONTS = { barlow = true, roboto = true, fira = true, rajdhani = true, exo = true, oswald = true, inter = true }
-- Mit dem Spiel ausgeliefert, keine eigene Datei. Fehlt sie im Client,
-- faellt K.SetFont auf die Schrift des Spiels zurueck.
K.GAME_FONTS = { arialn = "Fonts\\ARIALN.TTF" }
function K.FontPath()
    local choice = K.Get("general", "font")
    if choice == "game" then
        return _G.STANDARD_TEXT_FONT or F.hudSemi
    elseif choice == "plex" then
        return F.sansMedium
    elseif choice == "plexsemi" then
        return F.sansSemi
    elseif choice == "arialn" then
        return K.GAME_FONTS.arialn
    elseif type(choice) == "string" and K.EXTRA_FONTS[choice] then
        return F[choice] or F.hudSemi
    end
    return F.hudSemi
end

function K.FontFlags()
    local o = K.Get("general", "outline")
    if o == "none" then return "" end
    if o == "thick" then return "THICKOUTLINE" end
    return "OUTLINE"
end

-- Die Schrift des Spiels als letzter Rueckfall: sie ist immer geladen.
local FALLBACK_FONT = "Fonts\\FRIZQT__.TTF"

function K.SetFont(fs, size)
    -- type() und nicht nur `fs and`: ein Feld, das es nicht gibt oder das
    -- etwas anderes ist als eine Schriftzeile, soll uebersprungen werden,
    -- nicht beim Indizieren abstuerzen.
    if type(fs) ~= "table" or type(fs.SetFont) ~= "function" then return end
    -- SetFont meldet false, wenn die Datei nicht geladen werden konnte -
    -- und dann hat die Zeile KEINE Schrift mehr. Jedes spaetere SetText
    -- bricht ab, auch das des Spiels auf dessen eigenen Knoepfen. Also
    -- nie ohne Schrift zuruecklassen.
    local ok = fs:SetFont(K.FontPath(), size or 11, K.FontFlags())
    if ok == false then
        ok = fs:SetFont(_G.STANDARD_TEXT_FONT or FALLBACK_FONT, size or 11, K.FontFlags())
        if ok == false then fs:SetFont(FALLBACK_FONT, size or 11, "") end
    end
    -- Mit Kontur braucht es keinen Schatten; ohne Kontur ist er das
    -- Einzige, was den Text vom Hintergrund trennt.
    if fs.SetShadowOffset then
        if K.FontFlags() == "" then
            fs:SetShadowOffset(1, -1)
            fs:SetShadowColor(0, 0, 0, 1)
        else
            fs:SetShadowOffset(0, 0)
        end
    end
end

-- Schrift neu anmelden (6.26.5.0, Beta-Test: "beim ersten Einloggen kein
-- Name am Ziel, erst nach ein paar Zielen"). Beim kalten Einloggen ist die
-- eigene Schriftdatei beim ersten SetFont oft noch nicht geladen: die Zeile
-- zeichnet dann nichts, auch nicht bei neuem SetText. Erst ein neues
-- SetFont weckt sie - mit anderer Groesse, sonst ignoriert der Client es.
function K.Refont(fs)
    if type(fs) ~= "table" or type(fs.GetFont) ~= "function" then return false end
    local path, size, flags = fs:GetFont()
    if type(path) ~= "string" or type(size) ~= "number" or size <= 0 then return false end
    fs:SetFont(path, size + 1, flags or "")
    fs:SetFont(path, size, flags or "")
    return true
end

-- Jede Textzeile der Oberflaeche entsteht HIER, mit Schrift. Text ohne
-- Schrift ist im Client ein Fehler ("Font not set"), und bis 6.0.0.5
-- bekam manche Zeile ihre Schrift erst in einem spaeteren Layout - wer
-- vorher schrieb (ein Zauberbalken, dessen Gegner schon zauberte), brach
-- ab. load_test.lua verbietet CreateFontString ausserhalb dieser Datei.
function K.NewText(parent, size, layer, sublevel)
    local fs = parent:CreateFontString(nil, layer or "OVERLAY", nil, sublevel)
    K.SetFont(fs, size or 11)
    return fs
end

K.MEDIA = "Interface\\AddOns\\WeintCodex\\media\\ui\\"
K.BAR_TEXTURE = "Interface\\Buttons\\WHITE8X8"     -- flach, und fuer Flaechen
K.GLOSS_TEXTURE = K.MEDIA .. "bar"                     -- Balken mit Glanz (Standard)
K.GLOW_TEXTURE = K.MEDIA .. "glow"                     -- weicher Schein, 8 px
K.GLOW_WIDE_TEXTURE = K.MEDIA .. "glow_wide"           -- weicher Schein, 24 px
K.MARK_TEXTURE = K.MEDIA .. "targetmark"               -- Zielmarke der Plakette
K.ARROW_TEXTURE = K.MEDIA .. "arrow"

--------------------------------------------------
-- Stil 2.0: Balken, Schein, Kachel
--------------------------------------------------
-- docs/design/ui-2.0.md, Grundsatz 3: jede Flaeche ist dieselbe Kachel,
-- jeder Balken hat denselben Glanz. Die Module bauen Balken und Flaechen
-- nur noch hier - eine zweite Formensprache entsteht sonst von selbst.
--------------------------------------------------

-- Welche Textur ein Balken traegt. "glanz" (Standard): die eigene
-- Verlaufstextur; "flat": eine Farbe; "gradient": die Stufe von vorher.
function K.BarTexture()
    local style = K.Get("general", "barStyle")
    if style == "flat" or style == "gradient" then return K.BAR_TEXTURE end
    return K.GLOSS_TEXTURE
end

-- Jeder Balken der Oberflaeche entsteht HIER: mit Textur und einer feinen
-- Lichtkante oben. Schwach gemerkt, damit ein Wechsel des Balkenstils sie
-- alle erreicht (K.RestyleBars), ohne dass jemand sie festhaelt.
local bars = setmetatable({}, { __mode = "k" })

local function BarLight(sb)
    local l = sb._wcLight
    if not l then return end
    local c = WeintCodex.GameColors.barLight
    l:SetColorTexture(c[1], c[2], c[3], c[4])
    if K.Get("general", "barStyle") == "flat" then l:Hide() else l:Show() end
end

function K.NewBar(parent, noLight)
    local sb = CreateFrame("StatusBar", nil, parent)
    sb:SetStatusBarTexture(K.BarTexture())
    if not noLight then
        local l = sb:CreateTexture(nil, "OVERLAY", nil, -1)
        l:SetPoint("TOPLEFT", sb, "TOPLEFT", 0, 0)
        l:SetPoint("TOPRIGHT", sb, "TOPRIGHT", 0, 0)
        l:SetHeight(1)
        sb._wcLight = l
        BarLight(sb)
    end
    bars[sb] = true
    return sb
end

function K.RestyleBars()
    local tex = K.BarTexture()
    for sb in pairs(bars) do
        sb:SetStatusBarTexture(tex)
        -- Neue Textur, neue Farbe: der Zwischenspeicher in PaintBar gilt
        -- nicht mehr.
        sb._wcR, sb._wcStyle = nil, nil
        BarLight(sb)
    end
end

-- Ob der Client Neunteiler aus EINER Textur kann (SetTextureSliceMargins).
-- Ohne ihn waere der Schein ein gestrecktes Rechteck mit breiigen Kanten -
-- dann lieber keiner, und die Flaechen behalten ihren schwarzen Rand.
K.canSlice = nil

-- Weicher Schein um einen Rahmen: schwarz als Schatten, im Akzent als
-- Leuchten, weiss unter der Maus. `spread` = wie weit er nach aussen
-- reicht. Liefert { tex, SetColor, SetShown, SetSpread, ok }.
--
-- Der Schein ist INNEN voll deckend (dort liegt der Rahmen darueber). Er
-- muss deshalb UNTER dem Rahmen liegen: auf dem Rahmen selbst in der
-- untersten Ebene, oder auf einem Rahmen darunter (opts.host).
--
-- opts.shadow = true: ein Schatten, den der Schalter "Weiche Schatten"
-- (Allgemein) mit abschaltet.
local shadows = setmetatable({}, { __mode = "k" })

function K.ShadowsOn()
    return K.Get("general", "shadows") ~= false
end

function K.ApplyShadows()
    for o in pairs(shadows) do o:SetShown(o._want) end
end

function K.Glow(frame, opts)
    opts = opts or {}
    local host = opts.host or frame
    local wide = opts.wide and true or false
    local margin = wide and 24 or 8
    local t = host:CreateTexture(nil, opts.layer or "BACKGROUND", nil, opts.sublevel or -8)
    t:SetTexture(wide and K.GLOW_WIDE_TEXTURE or K.GLOW_TEXTURE)
    local ok = type(t.SetTextureSliceMargins) == "function"
        and pcall(t.SetTextureSliceMargins, t, margin, margin, margin, margin)
    if ok and t.SetTextureSliceMode and _G.Enum and _G.Enum.UITextureSliceMode then
        pcall(t.SetTextureSliceMode, t, _G.Enum.UITextureSliceMode.Stretched)
    end
    if K.canSlice == nil then K.canSlice = ok and true or false end
    if opts.blend and t.SetBlendMode then t:SetBlendMode(opts.blend) end

    local o = { tex = t, ok = ok and true or false }
    function o:SetSpread(s)
        t:ClearAllPoints()
        t:SetPoint("TOPLEFT", frame, "TOPLEFT", -s, s)
        t:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", s, -s)
    end
    function o:SetColor(r, g, b, a) t:SetVertexColor(r, g, b, a or 1) end
    function o:SetShown(v)
        self._want = v and true or false
        if v and self.ok and (not self._isShadow or K.ShadowsOn()) then t:Show() else t:Hide() end
    end
    if opts.shadow then
        o._isShadow = true
        shadows[o] = true
    end
    o:SetSpread(opts.spread or margin)
    local c = opts.color or WeintCodex.GameColors.shadow
    o:SetColor(c[1], c[2], c[3], c[4])
    o:SetShown(opts.shown ~= false)
    return o
end

-- Die Kachel (Grundsatz 3): Graphit 88 %, 1 px Schwarz, Lichtkante oben,
-- weicher Schatten. opts = { alpha = 0..1, shadow = px (0 = keiner),
-- border = false }.
function K.Kachel(frame, opts)
    opts = opts or {}
    local GC = WeintCodex.GameColors
    local o = {}
    local f = GC.kachelFill
    o.bg = frame:CreateTexture(nil, "BACKGROUND", nil, -7)
    o.bg:SetAllPoints(frame)
    o.bg:SetColorTexture(f[1], f[2], f[3], opts.alpha or f[4])
    local l = GC.lightEdge
    o.light = frame:CreateTexture(nil, "BORDER", nil, 1)
    o.light:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    o.light:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    o.light:SetHeight(1)
    o.light:SetColorTexture(l[1], l[2], l[3], l[4])
    o.border = K.Border(frame, 1, 0, 0, 0, 1, "BORDER")
    if opts.border == false then o.border:SetShown(false) end
    if (opts.shadow or 6) > 0 then
        o.shadow = K.Glow(frame, { spread = opts.shadow or 6, shadow = true })
    end
    function o:SetAlpha(a) self.bg:SetAlpha(1) local c = GC.kachelFill self.bg:SetColorTexture(c[1], c[2], c[3], a) end
    function o:SetShown(v)
        if v then self.bg:Show() self.light:Show() else self.bg:Hide() self.light:Hide() end
        self.border:SetShown(v)
        if self.shadow then self.shadow:SetShown(v) end
    end
    return o
end

-- Flach oder mit leichtem Verlauf. Der Verlauf ist eine Helligkeitsstufe
-- derselben Farbe, keine zweite Farbe.
function K.PaintBar(bar, r, g, b)
    local tex = bar.GetStatusBarTexture and bar:GetStatusBarTexture()
    if not tex then return end
    -- Jeder Treffer faerbt neu ein, die Farbe aendert sich fast nie. Der
    -- Verlauf legt je Aufruf zwei Farbobjekte an - bei zwanzig Plaketten
    -- im Kampf ist das Muell fuer den Speicherbereiniger ohne jeden Nutzen.
    -- r/g/b stammen immer aus Einstellungen oder Klassenfarben, nie aus
    -- einem geheimen Wert; der Vergleich ist also erlaubt.
    local style = K.Get("general", "barStyle")
    if bar._wcR == r and bar._wcG == g and bar._wcB == b and bar._wcStyle == style then return end
    bar._wcR, bar._wcG, bar._wcB, bar._wcStyle = r, g, b, style
    if style == "gradient" and tex.SetGradient
       and _G.CreateColor then
        tex:SetVertexColor(1, 1, 1, 1)
        tex:SetGradient("VERTICAL",
            _G.CreateColor(r * 0.72, g * 0.72, b * 0.72, 1),
            _G.CreateColor(r, g, b, 1))
    else
        if tex.SetGradient and _G.CreateColor and tex._wcGradient then
            tex:SetGradient("VERTICAL", _G.CreateColor(1, 1, 1, 1), _G.CreateColor(1, 1, 1, 1))
        end
        tex:SetVertexColor(r, g, b, 1)
    end
    tex._wcGradient = (K.Get("general", "barStyle") == "gradient") or nil
end

-- 1-px-Rahmen um einen Frame, in vier Texturen. Liefert ein Objekt mit
-- SetColor/Show/Hide - Namensplakette und Einheitenrahmen teilen ihn.
function K.Border(frame, size, r, g, b, a, layer)
    size = size or 1
    local o = {}
    local function Edge()
        local t = frame:CreateTexture(nil, layer or "BORDER")
        t:SetColorTexture(r or 0, g or 0, b or 0, a or 1)
        return t
    end
    o.top, o.bottom, o.left, o.right = Edge(), Edge(), Edge(), Edge()
    -- Einmal gebaut (6.8.0.6): SetColor laeuft im Takt (Reiter je Durchlauf,
    -- W.SkinTab) und legte vorher bei jedem Aufruf eine Liste an.
    o.parts = { o.top, o.bottom, o.left, o.right }
    function o:SetSize(s)
        self.top:ClearAllPoints()
        self.top:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", -s, 0)
        self.top:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", s, 0)
        self.top:SetHeight(s)
        self.bottom:ClearAllPoints()
        self.bottom:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", -s, 0)
        self.bottom:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", s, 0)
        self.bottom:SetHeight(s)
        self.left:ClearAllPoints()
        self.left:SetPoint("TOPRIGHT", frame, "TOPLEFT", 0, 0)
        self.left:SetPoint("BOTTOMRIGHT", frame, "BOTTOMLEFT", 0, 0)
        self.left:SetWidth(s)
        self.right:ClearAllPoints()
        self.right:SetPoint("TOPLEFT", frame, "TOPRIGHT", 0, 0)
        self.right:SetPoint("BOTTOMLEFT", frame, "BOTTOMRIGHT", 0, 0)
        self.right:SetWidth(s)
    end
    function o:SetColor(cr, cg, cb, ca)
        for _, t in ipairs(self.parts) do
            t:SetColorTexture(cr, cg, cb, ca or 1)
        end
    end
    function o:SetShown(v)
        for _, t in ipairs(self.parts) do
            if v then t:Show() else t:Hide() end
        end
    end
    function o:SetAlpha(v)
        for _, t in ipairs(self.parts) do t:SetAlpha(v) end
    end
    o:SetSize(size)
    return o
end

--------------------------------------------------
-- Blizzard-Rahmen verstecken
--------------------------------------------------
-- Ein ersetzter Blizzard-Rahmen zieht in einen versteckten Rahmen um und
-- verliert seine Ereignisse - einmal, nie im Kampf. Der Bearbeitungsmodus
-- des Spiels haengt seine Rahmen gelegentlich selbst wieder ein; dann
-- eben noch einmal, nach dem Kampf. Zurueck bekommt man ihn mit einem
-- Neuladen, nachdem das Modul abgeschaltet wurde.
--
-- keepEvents: nur verstecken, Ereignisse behalten (fuer Rahmen, deren
-- Ereignisse andere Teile des Spiels mitbenutzen).
--------------------------------------------------

local hiddenParent = CreateFrame("Frame")
hiddenParent:Hide()
K.hiddenParent = hiddenParent
local hookedParents = {}

function K.HideBlizzard(frame, keepEvents)
    if type(frame) == "string" then frame = _G[frame] end
    if type(frame) ~= "table" then return end
    if frame.IsForbidden and frame:IsForbidden() then return end
    K.AfterCombat(function()
        if not keepEvents and frame.UnregisterAllEvents then frame:UnregisterAllEvents() end
        frame:Hide()
        frame:SetParent(hiddenParent)
    end)
    if not hookedParents[frame] and _G.hooksecurefunc then
        hookedParents[frame] = true
        _G.hooksecurefunc(frame, "SetParent", function(self, parent)
            if parent ~= hiddenParent then
                K.AfterCombat(function() self:SetParent(hiddenParent) end)
            end
        end)
    end
end

--------------------------------------------------
-- Verschieben ("Rahmen entsperren")
--------------------------------------------------
-- Das Gegenstueck zum Entsperrmodus der Vorlage, auf das Noetige
-- reduziert: jeder bewegliche Rahmen bekommt eine Flaeche mit seinem
-- Namen, die sich ziehen laesst. Rechtsklick setzt ihn zurueck.
--
-- Geschuetzte Rahmen (Einheitenrahmen) lassen sich im Kampf nicht
-- bewegen - das Entsperren wird dann verweigert, nicht halb ausgefuehrt.
--------------------------------------------------

local movers = {}
local unlocked = false
local selected           -- Schluessel des angewaehlten Rahmens (Gestaltungsmodus)
K.movers = movers

-- Einrasten (ui/editmode.lua setzt es): nach dem Ziehen die linke untere
-- Ecke aufs Raster, die Mitte auf die Mittelachse, wenn sie nahe ist.
-- Liefert die Verschiebung dx, dy in Einheiten von UIParent.
K.SnapOffset = nil

local function SavePosition(key, frame)
    local ui = K.Profile()
    if not ui then return end
    local point, _, relPoint, x, y = frame:GetPoint(1)
    if not point then return end
    ui.positions[key] = {
        point = point, relPoint = relPoint or point,
        x = math.floor((x or 0) + 0.5), y = math.floor((y or 0) + 0.5),
    }
end

function K.ApplyPosition(key)
    local m = movers[key]
    if not m then return end
    local ui = K.Profile()
    local pos = ui and ui.positions[key] or m.default
    local frame = m.frame
    local function apply()
        frame:ClearAllPoints()
        -- 6.26.10.0: ein Standardplatz darf an einem Rahmen des Spiels
        -- haengen (`rel`, z. B. die Minikarte); gespeicherte nie.
        local rel = pos.rel and type(_G[pos.rel]) == "table" and _G[pos.rel] or UIParent
        frame:SetPoint(pos.point, rel, pos.relPoint or pos.point, pos.x or 0, pos.y or 0)
    end
    if m.secure then K.AfterCombat(apply) else apply() end
end

function K.RegisterMover(frame, key, label, default, opts)
    opts = opts or {}
    local m = movers[key] or {}
    m.frame, m.label, m.default = frame, label, default
    m.secure = opts.secure and true or false
    movers[key] = m

    if not m.overlay then
        local ov = CreateFrame("Button", nil, UIParent)
        ov:SetFrameStrata("DIALOG")
        ov:SetAllPoints(frame)
        ov:EnableMouse(true)
        ov:RegisterForDrag("LeftButton")
        if ov.RegisterForClicks then ov:RegisterForClicks("RightButtonUp") end
        local bg = ov:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(ov)
        local hc = K.Highlight()
        bg:SetColorTexture(hc[1], hc[2], hc[3], 0.22)
        ov.bg = bg
        ov.edge = K.Border(ov, 1, hc[1], hc[2], hc[3], 0.9, "ARTWORK")
        local t = K.NewText(ov, 11)
        t:SetFont(F.sansSemi, 11, "OUTLINE")
        t:SetPoint("CENTER", ov, "CENTER", 0, 0)
        t:SetTextColor(unpack(C.textBright))
        t:SetText(label)
        -- Immer der zuletzt angemeldete Rahmen (m.frame), nicht der beim
        -- ersten Anmelden: Rahmen des Spiels koennen neu entstehen (6.9.1.0).
        ov:SetScript("OnDragStart", function()
            if m.secure and K.InCombat() then return end
            m.frame:SetMovable(true)
            m.frame:StartMoving()
            K.dragging = key
            K.Fire("moverDrag", key)
        end)
        ov:SetScript("OnDragStop", function()
            local frame = m.frame
            frame:StopMovingOrSizing()
            K.dragging = nil
            SavePosition(key, frame)
            -- Einrasten: die gespeicherte Stelle um den Rest zum Raster bzw.
            -- zur Mittelachse verschieben (derselbe Anker, nur genauer).
            local ui = K.Profile()
            local pos = ui and ui.positions[key]
            if pos and K.SnapOffset then
                local ok, dx, dy = pcall(K.SnapOffset, m.frame)
                if ok and type(dx) == "number" and type(dy) == "number" then
                    pos.x = math.floor(pos.x + dx + 0.5)
                    pos.y = math.floor(pos.y + dy + 0.5)
                end
            end
            -- StartMoving haengt den Rahmen an den naechstgelegenen Punkt
            -- des Bildschirms um; gespeichert ist er jetzt, und neu
            -- angelegt wird er aus dem Gespeicherten.
            K.ApplyPosition(key)
            K.SelectMover(key)
        end)
        ov:SetScript("OnMouseDown", function(_, button)
            if button == "LeftButton" then K.SelectMover(key) end
        end)
        if ov.SetScript then
            ov:SetScript("OnDoubleClick", function() K.Fire("moverOpen", key) end)
        end
        -- 6.26.16.0 (Beta-Test: "mit Rechtsklick in die Optionen des
        -- Fensters"): Rechtsklick oeffnet die Einstellungen, Umschalt+
        -- Rechtsklick setzt zurueck (bis dahin tat das der Rechtsklick).
        ov:SetScript("OnClick", function(_, button)
            if button ~= "RightButton" then return end
            if not (_G.IsShiftKeyDown and _G.IsShiftKeyDown()) then
                K.Fire("moverOpen", key)
                return
            end
            local ui = K.Profile()
            if ui then ui.positions[key] = nil end
            K.ApplyPosition(key)
        end)
        ov:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(label, 1, 1, 1)
            GameTooltip:AddLine("Ziehen verschiebt, Pfeiltasten schieben genau (Umschalt: 8). Rechtsklick oder Doppelklick: Einstellungen. Umschalt+Rechtsklick: zurück an den Standardplatz.", 0.7, 0.7, 0.75, true)
            GameTooltip:Show()
        end)
        ov:SetScript("OnLeave", function() GameTooltip:Hide() end)
        ov:Hide()
        m.overlay = ov
    end
    -- Die Flaeche liegt ueber dem Rahmen, der gerade angemeldet ist.
    m.overlay:ClearAllPoints()
    m.overlay:SetAllPoints(frame)

    m.enabled = true
    K.ApplyPosition(key)
    if unlocked then m.overlay:Show() end
end

-- Ziehen ohne Gestaltungsmodus (6.19.1.0, Fluestern: "das Fenster ist
-- nicht verschiebbar"): der Rahmen selbst laesst sich ziehen, die Stelle
-- landet am selben Ort wie die aus dem Gestaltungsmodus.
function K.DragToMove(handle, key)
    handle:EnableMouse(true)
    handle:RegisterForDrag("LeftButton")
    handle:SetScript("OnDragStart", function()
        local m = movers[key]
        if not m or (m.secure and K.InCombat()) then return end
        m.frame:SetMovable(true)
        m.frame:StartMoving()
    end)
    handle:SetScript("OnDragStop", function()
        local m = movers[key]
        if not m then return end
        m.frame:StopMovingOrSizing()
        SavePosition(key, m.frame)
        K.ApplyPosition(key)
    end)
end

-- Ein Rahmen, dessen Modul aus ist, soll im Entsperrmodus nicht als
-- leere Flaeche herumstehen.
function K.SetMoverEnabled(key, on)
    local m = movers[key]
    if not m then return end
    m.enabled = on and true or false
    if unlocked and m.enabled then m.overlay:Show() else m.overlay:Hide() end
end

-- Angewaehlt: heller Grund, weisser Rand. Genau einer.
local function PaintMover(key)
    local m = movers[key]
    local ov = m and m.overlay
    if not (ov and ov.bg) then return end
    local on = (key == selected)
    local a = K.Highlight()
    ov.bg:SetColorTexture(a[1], a[2], a[3], on and 0.4 or 0.22)
    if on then ov.edge:SetColor(1, 1, 1, 1) else ov.edge:SetColor(a[1], a[2], a[3], 0.9) end
end

function K.SelectMover(key)
    local old = selected
    selected = key
    if old then PaintMover(old) end
    if key then PaintMover(key) end
    K.Fire("moverSelect", key)
end

function K.SelectedMover() return selected end

-- Den angewaehlten Rahmen um dx, dy verschieben (Pfeiltasten).
function K.NudgeMover(dx, dy)
    local m = selected and movers[selected]
    if not m or (m.secure and K.InCombat()) then return false end
    local ui = K.Profile()
    if not ui then return false end
    local cur = ui.positions[selected] or m.default
    ui.positions[selected] = { point = cur.point, relPoint = cur.relPoint or cur.point,
        x = (cur.x or 0) + dx, y = (cur.y or 0) + dy }
    K.ApplyPosition(selected)
    K.Fire("moverSelect", selected)
    return true
end

-- X/Y von Hand (6.26.15.0, Beta-Test: "x und y Koordinaten wie bei ElvUI").
-- Derselbe Anker wie gespeichert, nur andere Zahlen.
function K.SetMoverPosition(key, x, y)
    local m = movers[key]
    if not m or (m.secure and K.InCombat()) then return false end
    if type(x) ~= "number" or type(y) ~= "number" then return false end
    local ui = K.Profile()
    if not ui then return false end
    local cur = ui.positions[key] or m.default
    ui.positions[key] = { point = cur.point, relPoint = cur.relPoint or cur.point,
        x = math.floor(x + 0.5), y = math.floor(y + 0.5) }
    K.ApplyPosition(key)
    K.Fire("moverSelect", key)
    return true
end

function K.MoverFrame(key) local m = movers[key] return m and m.frame or nil end

-- Die anderen sichtbaren Rahmen (fuer das Einrasten aneinander). Eine
-- Liste, die wiederverwendet wird - gerufen nur beim Loslassen.
local others = {}
function K.OtherMoverFrames(exclude)
    for i = #others, 1, -1 do others[i] = nil end
    for key, m in pairs(movers) do
        local f = m.frame
        if key ~= exclude and m.enabled and f and f ~= exclude and f.IsShown and f:IsShown() then
            others[#others + 1] = f
        end
    end
    return others
end

-- Wo der Rahmen gerade steht, fuer die Anzeige im Gestaltungsmodus.
function K.MoverPosition(key)
    local m = movers[key]
    if not m then return nil end
    local ui = K.Profile()
    return (ui and ui.positions[key]) or m.default, m.label
end

function K.IsUnlocked() return unlocked end

function K.SetUnlocked(on)
    if on and K.InCombat() then
        print(WeintCodex.ColorText("accent", "[WeintCodex]")
            .. " Im Kampf lassen sich Rahmen nicht verschieben.")
        return false
    end
    unlocked = on and true or false
    if not unlocked then K.SelectMover(nil) end
    for _, m in pairs(movers) do
        if unlocked and m.enabled then
            -- Ein Rahmen, der gerade nichts zeigt (kein Ziel, keine Quest),
            -- hat trotzdem einen Platz - den soll man sehen koennen.
            if m.frame.WCShowForUnlock then m.frame:WCShowForUnlock(true) end
            m.overlay:Show()
        else
            if m.frame.WCShowForUnlock then m.frame:WCShowForUnlock(false) end
            m.overlay:Hide()
        end
    end
    K.Fire("unlock", unlocked)
    return true
end

function K.ResetAllPositions()
    local ui = K.Profile()
    if not ui then return end
    wipe(ui.positions)
    for key in pairs(movers) do K.ApplyPosition(key) end
end

--------------------------------------------------
-- Neu laden per Knopf
--------------------------------------------------
-- Neuladen ist auf Forever geschuetzt; der Knopf fuehrt "/reload" als
-- Makro aus, ausgeloest vom Klick selbst. Die Begruendung steht bei
-- WeintCodex.AttachReload in core/ui.lua - hier nur die Form, die das
-- Oberflaechenpaket braucht.
--
-- opts: wie WeintCodex.CreateButton (text, kind, height, size,
--       backdrop, tooltip), dazu onClick = was VOR dem Neuladen noch
--       geschehen soll.
--------------------------------------------------

function K.ReloadButton(parent, opts)
    opts = opts or {}
    local b = WeintCodex.CreateButton(parent, {
        text = opts.text or "Jetzt neu laden", kind = opts.kind or "primary",
        height = opts.height, size = opts.size, backdrop = opts.backdrop,
        tooltip = opts.tooltip,
    })
    WeintCodex.AttachReload(b, opts.onClick)
    return b
end

--------------------------------------------------
-- Zielmarkierungen (Totenkopf, Kreuz ...)
--------------------------------------------------
-- Der Beta-Client (12.x) nennt den Index der Markierung GEHEIM (/wcui
-- auren im Beta-Test: "Markierung geheim"). SetRaidTargetIconTexture
-- rechnet mit ihm (Kacheln einer Sammeldatei) - mit einem geheimen Wert
-- darf Lua das nicht, das Symbol blieb aus. Ein Text dagegen darf ihn
-- formatieren: "|T...UI-RaidTargetingIcon_%d:gross|t" setzt der Client
-- selbst zusammen, und die Einzeldateien je Markierung liefert das Spiel
-- (dieselben wie {rt8} im Chat). Eine Schriftzeile statt einer Textur -
-- sie zeigt ein Bild, ohne dass Lua die Zahl je sieht.
--------------------------------------------------

function K.NewRaidIcon(parent, size)
    local fs = K.NewText(parent, 10, "OVERLAY")
    fs._raidSize = size or 16
    fs:Hide()
    return fs
end

function K.SetRaidIconSize(fs, size)
    fs._raidSize = size or fs._raidSize or 16
    if fs.SetSize then fs:SetSize(fs._raidSize, fs._raidSize) end
end

-- Zeigt die Markierung fuer einen Index (offen oder geheim). false, wenn
-- es keine gibt oder der Client den Text ablehnt.
function K.ShowRaidIndex(fs, idx)
    if type(idx) == "nil" then fs:Hide() return false end
    local plain = K.Plain(idx)
    if not K.IsSecret(idx) and (type(plain) ~= "number" or plain < 1 or plain > 8) then
        fs:Hide()
        return false
    end
    local n = fs._raidSize or 16
    local ok = pcall(fs.SetFormattedText, fs,
        "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_%d:" .. n .. ":" .. n .. "|t", idx)
    if ok then fs:Show() else fs:Hide() end
    return ok
end

function K.ShowRaidIcon(fs, unit)
    local idx = unit and _G.GetRaidTargetIndex and _G.GetRaidTargetIndex(unit)
    return K.ShowRaidIndex(fs, idx), K.IsSecret(idx)
end

--------------------------------------------------
-- Nachsehen: was ist dieser Rahmen?
--------------------------------------------------
-- Im Beta-Client heissen Rahmen oft anders, als WeintCodex annimmt
-- (Tageszeit auf der Minikarte: drei Fassungen lang nicht gefunden).
-- K.Describe beschreibt einen Rahmen in einer Zeile, K.InspectMouse alle
-- Rahmen unter der Maus samt Elternkette und Ankern (/wcui maus). Alles
-- in pcall: auch geschuetzte oder geheime Rahmen duerfen hier nichts
-- ausloesen.
--------------------------------------------------

local function Num(v)
    v = K.Plain(v)
    return type(v) == "number" and string.format("%.2f", v) or tostring(v)
end

local function NameOf(f)
    if type(f) ~= "table" then return "keiner" end
    local ok, n = pcall(function()
        return (f.GetDebugName and f:GetDebugName()) or (f.GetName and f:GetName())
    end)
    if ok and type(n) == "string" and n ~= "" then return n end
    return "(ohne Namen)"
end
K.NameOf = NameOf

function K.Describe(f)
    if type(f) ~= "table" then return "fehlt" end
    local ok, out = pcall(function()
        local parent = f.GetParent and f:GetParent()
        local pname = parent and NameOf(parent) or "keiner"
        local ea = f.GetEffectiveAlpha and f:GetEffectiveAlpha()
        return string.format("gezeigt %s, sichtbar %s, Alpha %s (wirksam %s), %s/%s, links %s oben %s, Eltern %s",
            tostring(K.Bool(f:IsShown(), false)), tostring(K.Bool(f:IsVisible(), false)),
            Num(f:GetAlpha()), Num(ea), tostring(f.GetFrameStrata and f:GetFrameStrata()),
            Num(f.GetFrameLevel and f:GetFrameLevel()), Num(f.GetLeft and f:GetLeft()), Num(f.GetTop and f:GetTop()), pname)
    end)
    return ok and out or ("nicht lesbar: " .. tostring(out))
end

local function Anchors(f)
    local ok, out = pcall(function()
        local n = f.GetNumPoints and K.Plain(f:GetNumPoints())
        if type(n) ~= "number" or n < 1 then return "keine Anker" end
        local parts = {}
        for i = 1, math.min(n, 4) do
            local p, rel, rp, x, y = f:GetPoint(i)
            parts[#parts + 1] = string.format("%s an %s %s (%s, %s)", tostring(p), NameOf(rel), tostring(rp), Num(x), Num(y))
        end
        return table.concat(parts, "; ")
    end)
    return ok and out or "Anker nicht lesbar"
end

function K.InspectMouse()
    local foci = {}
    if type(_G.GetMouseFoci) == "function" then
        local ok, t = pcall(_G.GetMouseFoci)
        if ok and type(t) == "table" then foci = t end
    elseif type(_G.GetMouseFocus) == "function" then
        local ok, f = pcall(_G.GetMouseFocus)
        if ok and type(f) == "table" then foci = { f } end
    end
    local out = {}
    for _, f in ipairs(foci) do
        if #out >= 12 then break end
        if type(f) == "table" and not (f.IsForbidden and f:IsForbidden()) then
            local chain, p = {}, f.GetParent and f:GetParent()
            for _ = 1, 5 do
                if type(p) ~= "table" then break end
                chain[#chain + 1] = NameOf(p)
                p = p.GetParent and p:GetParent()
            end
            local kind = f.GetObjectType and f:GetObjectType()
            out[#out + 1] = NameOf(f) .. " (" .. tostring(kind) .. "): " .. K.Describe(f)
            out[#out + 1] = "   Eltern: " .. (#chain > 0 and table.concat(chain, " < ") or "keine")
                .. " · Anker: " .. Anchors(f)
        end
    end
    -- Was keine Maus annimmt (Texturen, Rahmen ohne Mausklick), steht nicht
    -- in GetMouseFoci - die Tageszeit-Sonne im Beta-Test meldete dort nur
    -- "Minimap". Deshalb alle sichtbaren Rahmen und ihre Texturen, die die
    -- Mausposition ueberdecken, die kleinsten zuerst.
    local hits = K.UnderCursor()
    if #hits > 0 then
        out[#out + 1] = "Alles unter der Maus, das Kleinste zuerst:"
        for i = 1, math.min(#hits, 18) do out[#out + 1] = "   " .. hits[i].line end
    end
    if #out == 0 then
        out[1] = "Unter der Maus liegt kein Rahmen. Maus über das Ding halten und den Befehl mit Enter abschicken."
    end
    return out
end

-- Liegt die Mausposition in der Flaeche von r? Koordinaten von Rahmen und
-- Texturen stehen in ihrer wirksamen Skalierung, die Maus in Bildpunkten.
local function Covers(r, cx, cy, scale)
    local ok, hit, area = pcall(function()
        local s = K.Plain(r.GetEffectiveScale and r:GetEffectiveScale())
        if type(s) ~= "number" or s <= 0 then s = scale end
        local l, rt = K.Plain(r:GetLeft()), K.Plain(r:GetRight())
        local t, b = K.Plain(r:GetTop()), K.Plain(r:GetBottom())
        if type(l) ~= "number" or type(rt) ~= "number" or type(t) ~= "number" or type(b) ~= "number" then
            return false, 0
        end
        local x, y = cx / s, cy / s
        return x >= l and x <= rt and y >= b and y <= t, (rt - l) * (t - b)
    end)
    return ok and hit or false, ok and area or 0
end

local function TextureOf(r)
    local ok, v = pcall(function()
        local atlas = r.GetAtlas and r:GetAtlas()
        if type(atlas) == "string" and atlas ~= "" then return "Atlas " .. atlas end
        local tex = r.GetTexture and r:GetTexture()
        if type(tex) == "string" or type(tex) == "number" then return "Bild " .. tostring(tex) end
        return nil
    end)
    return ok and v or nil
end

-- Ein Name ohne die Adressen namenloser Rahmen ("...ScrollTarget.63f74260"
-- -> "...ScrollTarget.*"): so fallen die Zeilen einer Liste, die das Spiel
-- wiederverwendet, in EINE Zeile des Berichts.
function K.PatternName(name)
    if type(name) ~= "string" then return "(ohne Namen)" end
    return (name:gsub("%.%x%x%x%x%x%x%x%x+", ".*"))
end

-- /wcui fenster: das oberste Fenster unter der Maus (bis unter UIParent)
-- und alles Sichtbare darin, nach Bild zusammengefasst, das Groesste
-- zuerst. So heisst, was im Fenster eines Clients nach Holz aussieht.
--
-- Seit 6.10.2.0 (Lehrer, 6.10.1.0: "404984 · 10× · in ClassTrainerFrame"
-- waren in Wahrheit Pergament, Zeilengrund und Markierung der gewaehlten
-- Zeile - verteilt, nicht am Fenster): je Bild JEDER Fundort mit Anzahl,
-- als Name des Bildes selbst (".BG", ".NormalTexture", ".selectedTex"),
-- ohne Grenze bei 24 Zeilen, und die Art, unter der die Bausteine des
-- Fensters (ui/calmparts.lua) das Bild kennen. Die Ausgabe geht in ein
-- Fenster zum Kopieren (K.ShowReport) statt in den Chat.
function K.InspectWindow()
    local out = {}
    local focus
    if type(_G.GetMouseFoci) == "function" then
        local ok, t = pcall(_G.GetMouseFoci)
        if ok and type(t) == "table" then focus = t[1] end
    elseif type(_G.GetMouseFocus) == "function" then
        local ok, f = pcall(_G.GetMouseFocus)
        if ok then focus = f end
    end
    local top = focus
    for _ = 1, 20 do
        local ok, p = pcall(function() return top:GetParent() end)
        if not ok or type(p) ~= "table" or p == _G.UIParent or p == _G.WorldFrame then break end
        top = p
    end
    if type(top) ~= "table" or top == _G.WorldFrame or top == _G.UIParent then
        out[1] = "Unter der Maus liegt kein Fenster. Maus über das Fenster halten und den Befehl mit Enter abschicken."
        return out
    end
    -- Fassung vorneweg: ein Test mit einer alten Fassung sieht genauso aus
    -- wie ein Fehler in der neuen (Beta-Test 6.3.1.7: "nichts geaendert").
    out[1] = "WeintCodex " .. tostring(WeintCodex.Version) .. " · Fenster: " .. NameOf(top)
    local W = WeintCodex.UIWindows
    if W and W.Status then
        local ok, line = pcall(W.Status)
        if ok and line then out[#out + 1] = line end
    end
    local MW = WeintCodex.UIMoveWindows
    if MW and MW.Status then
        local ok, line = pcall(MW.Status)
        if ok and line then out[#out + 1] = line end
    end
    -- Bausteine dieses Fensters: welche Art sie einem Bild geben.
    local CP = WeintCodex.UICalmParts
    local okName, topName = pcall(function() return top:GetName() end)
    local host = (CP and CP.hosts and okName and type(topName) == "string") and CP.hosts[topName] or nil
    local groups, list = {}, {}
    local invisible = 0
    -- Die Kartenkacheln der Weltkarte sind Inhalt, keine Gestaltung - und
    -- so gross, dass sie jede andere Zeile aus der Liste draengten
    -- (Beta-Test 6.6.2.0). Sie werden ausgelassen, dafuer geht die Suche
    -- tiefer (Questliste).
    local map = _G.WorldMapFrame
    local canvas = type(map) == "table" and map.ScrollContainer or nil
    local skipped = false
    local function Walk(f, depth)
        if depth > 10 or (f.IsForbidden and f:IsForbidden()) then return end
        if canvas and f == canvas then skipped = true return end
        local vok, vis = pcall(function() return K.Bool(f:IsVisible(), false) end)
        if not vok or not vis then return end
        local owner = K.PatternName(NameOf(f))
        local rok, regions = pcall(function() return { f:GetRegions() } end)
        for _, r in ipairs(rok and regions or {}) do
            local ok, info = pcall(function()
                if r:GetObjectType() ~= "Texture" or not K.Bool(r:IsShown(), false) then return nil end
                if K.Plain(r:GetAlpha()) == 0 then return "invisible" end
                local w, h = K.Plain(r:GetWidth()), K.Plain(r:GetHeight())
                if type(w) ~= "number" or type(h) ~= "number" then return nil end
                -- Wo: der Name des Bildes selbst (traegt seinen Schluessel am
                -- Rahmen), sonst der Rahmen.
                local rn = NameOf(r)
                local where = rn ~= "(ohne Namen)" and K.PatternName(rn) or owner
                local kind = host and host.Kind and host.Kind(r) or nil
                return { key = TextureOf(r) or "Farbfläche", area = w * h, where = where, kind = kind }
            end)
            if ok and info == "invisible" then
                invisible = invisible + 1
            elseif ok and info then
                local g = groups[info.key]
                if not g then
                    g = { key = info.key, n = 0, area = 0, places = {}, order = {}, kinds = {} }
                    groups[info.key] = g
                    list[#list + 1] = g
                end
                g.n, g.area = g.n + 1, g.area + info.area
                if not g.places[info.where] then
                    g.places[info.where] = 0
                    g.order[#g.order + 1] = info.where
                end
                g.places[info.where] = g.places[info.where] + 1
                if info.kind then g.kinds[info.kind] = true end
            end
        end
        local cok, kids = pcall(function() return { f:GetChildren() } end)
        for _, ch in ipairs(cok and kids or {}) do
            if type(ch) == "table" then Walk(ch, depth + 1) end
        end
    end
    Walk(top, 0)
    table.sort(list, function(a, b) return a.area > b.area end)
    out[#out + 1] = string.format("Sichtbar: %d verschiedene Bilder · unsichtbar (Deckkraft 0, auch die von WeintCodex): %d%s",
        #list, invisible, host and (" · Bausteine: " .. tostring(host.LABEL)) or "")
    if skipped then out[#out + 1] = "   (Kartenbild ausgelassen)" end
    -- Wuerfeln um Beute (ui/lootroll.lua): kein Fenster aus W.WINDOWS.
    local LR = WeintCodex.UILootRoll
    if LR and okName and type(topName) == "string" and topName:match("^GroupLootFrame%d$") then
        pcall(LR.Report, out)
    end
    for _, g in ipairs(list) do
        local marks = ""
        local atlas = g.key:match("^Atlas (.+)$")
        if atlas and W and W.HidesAtlas and W.HidesAtlas(atlas) then
            marks = " · SOLLTE WEG SEIN"
        end
        local kinds = {}
        for kind in pairs(g.kinds) do kinds[#kinds + 1] = kind end
        if #kinds > 0 then
            table.sort(kinds)
            marks = marks .. " · Baustein: " .. table.concat(kinds, "/") .. " (sichtbar - Symbol oder Fehler?)"
        end
        out[#out + 1] = string.format("%s · %d×%s", g.key, g.n, marks)
        table.sort(g.order, function(a, b)
            if g.places[a] ~= g.places[b] then return g.places[a] > g.places[b] end
            return a < b
        end)
        for _, where in ipairs(g.order) do
            out[#out + 1] = string.format("   %d× %s", g.places[where], where)
        end
    end
    if #list == 0 then out[#out + 1] = "   keine sichtbaren Bilder" end
    if W and W.SoftReport then
        local ok, lines = pcall(W.SoftReport, top)
        if ok and type(lines) == "table" then
            for _, l in ipairs(lines) do out[#out + 1] = l end
        end
    end
    -- Kategorien (6.6.2.7): welche Kopfzeilen gestaltet sind.
    if W and W.HeaderReport then
        local ok, lines = pcall(W.HeaderReport)
        if ok and type(lines) == "table" then
            for _, l in ipairs(lines) do out[#out + 1] = l end
        end
    end
    -- Seitenreiter (6.6.2.2): woran der gewaehlte zu erkennen ist.
    if W and W.SideTabReport then
        local ok, lines = pcall(W.SideTabReport, top)
        if ok and type(lines) == "table" and #lines > 0 then
            out[#out + 1] = "   Seitenreiter:"
            for _, l in ipairs(lines) do out[#out + 1] = l end
        end
    end
    return out
end

function K.UnderCursor()
    local hits = {}
    if type(_G.EnumerateFrames) ~= "function" or type(_G.GetCursorPosition) ~= "function" then return hits end
    local cx, cy = _G.GetCursorPosition()
    cx, cy = K.Plain(cx), K.Plain(cy)
    if type(cx) ~= "number" or type(cy) ~= "number" then return hits end
    local skip = { [_G.UIParent or false] = true, [_G.WorldFrame or false] = true }
    local f = _G.EnumerateFrames()
    local guard = 0
    while f and guard < 50000 do
        guard = guard + 1
        local ok, usable = pcall(function()
            return not skip[f] and not (f.IsForbidden and f:IsForbidden()) and K.Bool(f:IsVisible(), false)
        end)
        if ok and usable then
            local scale = K.Plain(f.GetEffectiveScale and f:GetEffectiveScale())
            if type(scale) ~= "number" or scale <= 0 then scale = 1 end
            local hit, area = Covers(f, cx, cy, scale)
            if hit then
                local kind = f.GetObjectType and f:GetObjectType()
                hits[#hits + 1] = { area = area, line = string.format("%s (%s, %s/%s, Maus %s, Alpha %s)",
                    NameOf(f), tostring(kind), tostring(f.GetFrameStrata and f:GetFrameStrata()),
                    Num(f.GetFrameLevel and f:GetFrameLevel()),
                    tostring(K.Bool(f.IsMouseEnabled and f:IsMouseEnabled(), false)),
                    Num(f.GetEffectiveAlpha and f:GetEffectiveAlpha())) }
                local rok, regions = pcall(function() return { f:GetRegions() } end)
                for _, r in ipairs(rok and regions or {}) do
                    -- Durchsichtige (Alpha 0) fallen weg: jeder Reiter traegt ein
                    -- Dutzend ausgeblendeter Texturen.
                    local vok, rtype = pcall(function()
                        if K.Plain(r:GetAlpha()) == 0 then return nil end
                        return K.Bool(r:IsVisible(), false) and r:GetObjectType() or nil
                    end)
                    if vok and (rtype == "Texture" or rtype == "FontString") then
                        local rhit, rarea = Covers(r, cx, cy, scale)
                        if rhit then
                            local what
                            if rtype == "Texture" then
                                what = TextureOf(r) or "Farbfläche"
                            else
                                local tok, txt = pcall(function() return K.Plain(r:GetText()) end)
                                what = "Text „" .. (tok and type(txt) == "string" and txt or "?") .. "“"
                            end
                            local rname = NameOf(r)
                            if rname == "(ohne Namen)" then rname = rtype .. " in " .. NameOf(f) end
                            local lok, layer = pcall(function() return r:GetDrawLayer() end)
                            hits[#hits + 1] = { area = rarea, line = rname .. ": " .. what
                                .. " (" .. tostring(lok and layer or "?") .. ", Alpha " .. Num(r.GetAlpha and r:GetAlpha()) .. ")" }
                        end
                    end
                end
            end
        end
        local nok, nxt = pcall(_G.EnumerateFrames, f)
        f = nok and nxt or nil
    end
    table.sort(hits, function(a, b) return a.area < b.area end)
    return hits
end

--------------------------------------------------
-- Einmal-Ereignisse
--------------------------------------------------
-- PLAYER_LOGIN: SavedData stehen seit ADDON_LOADED (core/main.lua); die
-- Einheiten gibt es erst jetzt. Hier werden die Module gestartet.
--------------------------------------------------

local boot = CreateFrame("Frame")
boot:RegisterEvent("PLAYER_LOGIN")
boot:RegisterEvent("PLAYER_REGEN_ENABLED")
boot:RegisterEvent("PLAYER_REGEN_DISABLED")
boot:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_REGEN_DISABLED" then
        -- Entsperrt in den Kampf: die Flaechen verschwinden, statt einen
        -- geschuetzten Rahmen halb gezogen stehen zu lassen.
        if unlocked then K.SetUnlocked(false) end
        return
    end
    if event == "PLAYER_REGEN_ENABLED" then
        local queue = afterCombat
        afterCombat = {}
        for _, fn in ipairs(queue) do
            local ok, err = pcall(fn)
            if not ok then K.Report("kampf", err) end
        end
        return
    end

    -- PLAYER_LOGIN. Zuerst der Akzent: Klassenfarbe oder, so eingestellt,
    -- Violett - bevor die Module ihre Flaechen faerben.
    K.ResetHighlight()
    for _, key in ipairs(order) do
        if K.WantsActive(key) then K.Activate(key) end
    end
    K.SweepProfile()
end)
