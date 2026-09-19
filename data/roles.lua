--------------------------------------------------
-- WeintCodex :: Rollen (Tank, Heiler, Schadensausteiler)
--
-- WAS ÜBER ROLLEN IN FOREVER WIRKLICH FESTSTEHT - UND WAS NICHT.
--
-- Diese Datei ist der Versuch, eine Frage ehrlich zu beantworten, auf
-- die es drei sehr verschiedene Antworten gibt, je nachdem, wen man
-- fragt:
--
--   1. WELCHE SPEZIALISIERUNG WELCHE ROLLE TRÄGT. Steht fest.
--      data/specs.lua führt sie, und sie ändert sich mit Forever
--      nicht: ein Schutzkrieger tankt, ein Heiligpriester heilt. Das
--      ist keine Vermutung, sondern die Aufstellung des Spiels.
--
--   2. WIE VIELE VON JEDER ROLLE IN EINE GRUPPE GEHÖREN. Steht für
--      Fünfergruppen fest (einer tankt, einer heilt, drei teilen aus -
--      dafür ist die Gruppe gebaut) und für Schlachtzüge NICHT. Wie
--      viele Tanks Barrow Deeps braucht, hängt an Bossmechaniken, die
--      niemand kennt. `Frame()` liefert deshalb für 10, 20 und 40
--      ausdrücklich nil und nicht die Aufstellung, die man aus einem
--      anderen Spiel kennt.
--
--   3. WAS EINE ROLLE AN EINEM BESTIMMTEN BOSS ZU TUN HAT. Steht für
--      KEINEN einzigen Kampf in Forever fest. Die Bossmechaniken sind
--      nicht veröffentlicht, die Beutetabellen im Beta-Client sind
--      leer. Diese Datei erfindet dafür nichts - sie reicht durch,
--      was der Discord-Bot geliefert hat (WCIMPORT:BOSS trägt genau
--      diese drei Rollenfelder), und sagt sonst, dass nichts da ist.
--
-- Die Trennung dieser drei Bestände ist der ganze Zweck der Datei.
-- Sie zusammenzuziehen hiesse, eine gesicherte Auskunft (1) und eine
-- erfundene (3) in derselben Schrift nebeneinanderzustellen.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.Roles = {}

-- Reihenfolge, in der Rollen überall erscheinen. Tank, Heiler,
-- Schaden - die Reihenfolge, in der eine Gruppe aufgestellt wird.
WeintCodex.Roles.ORDER = { "tank", "healer", "dps" }

local LABEL = {
    tank   = "Tank",
    healer = "Heiler",
    dps    = "Schadensausteiler",
}

-- Kurzform für enge Stellen (Kennzahlen im Seitenkopf, Chips).
local SHORT = {
    tank   = "Tank",
    healer = "Heiler",
    dps    = "DD",
}

function WeintCodex.Roles.Label(role)
    return LABEL[role] or "Rolle"
end

function WeintCodex.Roles.Short(role)
    return SHORT[role] or "?"
end

-- DIE FARBE EINER ROLLE IST KEINE NEUE BEDEUTUNGSFARBE. Blau, Grün
-- und Rot stehen in dieser Fassung bereits für Tank, Heiler und
-- Schaden - modules/signup.lua färbt die Anmeldeliste seit jeher so.
-- Sie stehen hier, damit es EINE Quelle dafür gibt und nicht zwei;
-- der violette Akzent bleibt unangetastet.
local TONE = {
    tank   = "infoBright",
    healer = "successBright",
    dps    = "dangerBright",
}

function WeintCodex.Roles.Tone(role)
    return TONE[role] or "textNormal"
end

--------------------------------------------------
-- 1. Der Rollenrahmen einer Gruppengrösse
--------------------------------------------------
-- Fünf Spieler: einer tankt, einer heilt, drei teilen aus. Das ist
-- die Aufstellung, für die eine Fünfergruppe gebaut ist, und sie gilt
-- in Forever wie überall.
--
-- Zehn, zwanzig, vierzig: NICHT BEKANNT. Wie viele Tanks und Heiler
-- ein Schlachtzug braucht, entscheiden seine Bosse, und die sind
-- nicht veröffentlicht. Hier "2 Tanks, 3 Heiler" hinzuschreiben wäre
-- eine Zahl aus einem anderen Spiel - genau der Fehler, den diese
-- Fassung an den Bosslisten vermieden hat.
--
-- `nil` heisst "nicht bekannt" und wird von der Oberfläche auch so
-- angezeigt. Es heisst NICHT "keine Rollen nötig".

local FRAMES = {
    [5] = { tank = 1, healer = 1, dps = 3 },
}

function WeintCodex.Roles.Frame(size)
    if type(size) ~= "number" then return nil end
    return FRAMES[size]
end

-- Der Rahmen als Text, z.B. "1 Tank · 1 Heiler · 3 DD". `nil`, wenn
-- es keinen gibt.
function WeintCodex.Roles.FrameLabel(size)
    local frame = WeintCodex.Roles.Frame(size)
    if not frame then return nil end
    local parts = {}
    for _, role in ipairs(WeintCodex.Roles.ORDER) do
        local count = frame[role]
        if count and count > 0 then
            parts[#parts + 1] = count .. " " .. WeintCodex.Roles.Short(role)
        end
    end
    return table.concat(parts, " · ")
end

--------------------------------------------------
-- 2. Welche Spezialisierungen eine Rolle tragen
--------------------------------------------------
-- Aus data/specs.lua, ohne eigene Liste daneben: eine zweite Liste
-- wäre eine zweite Wahrheit.
--
-- DER EINE BAUM OHNE ROLLE: "Wilder Kampf" des Druiden trägt Katze
-- UND Bär; welche davon jemand gerade ist, entscheidet die Gestalt
-- und nicht der Baum (deshalb `role = nil` drüben). Er erscheint hier
-- folgerichtig unter BEIDEN Rollen, mit `formDependent = true` - die
-- Oberfläche schreibt "je nach Gestalt" dazu. Ihn nur bei den
-- Schadensausteilern zu führen wäre ein Vorwurf an jeden Bärtank; ihn
-- ganz wegzulassen wäre eine Lücke.

local FORM_DEPENDENT_ROLES = { tank = true, dps = true }

function WeintCodex.Roles.Specs(role)
    local out = {}
    if not LABEL[role] then return out end

    for _, spec in ipairs(WeintCodex_Specs or {}) do
        if spec.role == role then
            out[#out + 1] = { spec = spec, formDependent = false }
        elseif spec.role == nil and FORM_DEPENDENT_ROLES[role] then
            out[#out + 1] = { spec = spec, formDependent = true }
        end
    end

    return out
end

-- Wie viele Spezialisierungen diese Rolle tragen können. Immer eine
-- Zahl: sie zählt eine vollständige Tabelle, nicht eine Lieferung.
function WeintCodex.Roles.SpecCount(role)
    return #WeintCodex.Roles.Specs(role)
end

--------------------------------------------------
-- 3. Die Rollen-Tipps des Bots
--------------------------------------------------
-- WCIMPORT:BOSS liefert je Boss bis zu drei Listen - tank, healer,
-- dps (siehe ParseBossImport in modules/sync.lua). Sie liegen unter
-- SavedData.bossData[<Bossname>][<rolle>] und sind der EINZIGE
-- Bestand an Rollenhinweisen, den dieses Addon hat. Es erfindet
-- keinen zweiten.
--
-- GILDENINTERN: die Tipps hängen an der Freigabe `bossguides.tips`
-- (core/access.lua: "Die vom Bot gelieferten Rollen-Tipps sind
-- gildeninterne Taktiknotizen"). Ohne Freigabe liefert `Tips` nil -
-- ausdrücklich nil und nicht eine leere Liste, damit die Oberfläche
-- "gesperrt" von "nichts geliefert" unterscheiden kann.

local function TipsAllowed()
    if not (WeintCodex.Access and WeintCodex.Access.Can) then return true end
    return WeintCodex.Access.Can("bossguides.tips")
end

WeintCodex.Roles.TipsAllowed = TipsAllowed

-- Die Tipps zu einem Boss und einer Rolle.
--
--   nil            gesperrt oder gar nichts zu diesem Boss geliefert
--   leere Tabelle  der Bot kennt den Boss, hat zu DIESER Rolle aber
--                  nichts gesagt
--
-- Die beiden auseinanderzuhalten ist der Punkt: "zu dieser Rolle
-- steht nichts drin" ist eine Auskunft, "es wurde nie etwas
-- importiert" ist keine.
function WeintCodex.Roles.Tips(bossName, role)
    if type(bossName) ~= "string" or not LABEL[role] then return nil end
    if not TipsAllowed() then return nil end

    local sd   = WeintCodex.SavedData
    local data = sd and sd.bossData
    if type(data) ~= "table" then return nil end

    local entry = data[bossName]
    if type(entry) ~= "table" then return nil end

    local tips = entry[role]
    if type(tips) ~= "table" then return {} end
    return tips
end

-- Hat der Bot zu diesem Boss überhaupt etwas geliefert? Beantwortet
-- die Frage, ohne die Freigabe zu umgehen: ohne Freigabe ist die
-- Antwort false, weil der Bestand dann nicht zu lesen ist.
function WeintCodex.Roles.HasTips(bossName)
    if type(bossName) ~= "string" then return false end
    if not TipsAllowed() then return false end

    local sd   = WeintCodex.SavedData
    local data = sd and sd.bossData
    if type(data) ~= "table" then return false end

    local entry = data[bossName]
    if type(entry) ~= "table" then return false end

    for _, role in ipairs(WeintCodex.Roles.ORDER) do
        local tips = entry[role]
        if type(tips) == "table" and #tips > 0 then return true end
    end
    return false
end

-- Zu wie vielen Bossen einer Instanz Rollen-Tipps vorliegen. Immer
-- eine Zahl, weil über eine bekannte Bossliste gezählt wird - eine
-- leere Bossliste liefert 0, und das ist hier richtig: null von null
-- bekannten Bossen.
function WeintCodex.Roles.TippedBossCount(instance)
    if type(instance) ~= "table" then return 0 end
    local count = 0
    for _, boss in ipairs(instance.bosses or {}) do
        if WeintCodex.Roles.HasTips(boss.name) then count = count + 1 end
    end
    return count
end
