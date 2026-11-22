--------------------------------------------------
-- WeintCodex :: Suche, die Saetze versteht (1.0.8.11)
--------------------------------------------------
-- Wunsch: "Das Addon ist sehr umfangreich geworden, vieles ist versteckt.
-- Die Suche soll intelligenter werden und auch Saetze verstehen."
--
-- Bis 1.0.8.10 gab es drei Suchen mit drei Regeln: die Titelleiste des
-- Codex fand nur den ganzen Text am Stueck, Einstellungen und Hilfe
-- verlangten JEDES Wort - "Wie kann ich meine Taschen sortieren?" fand
-- nirgends etwas, weil "wie", "kann", "ich" in keinem Eintrag stehen.
--
-- Hier ist die eine Regel fuer alle drei:
--   * Fuellwoerter fallen weg (FILL): Fragewoerter, Artikel, "ich",
--     "kann", "einstellen", "finden" ... - was in jeder Frage steht, sagt
--     nichts darueber, was gesucht ist.
--   * Jedes Wort darf passen als ganzes Wort, als Stamm ("sortieren" ->
--     "sortier", "Taschen" -> "tasch"), ueber ein Schlagwort
--     (data/help.lua: "aggro" -> "bedrohung") oder mit einem Tippfehler
--     (ein Buchstabe falsch, zu viel oder zu wenig; ab 5 Buchstaben).
--   * Nicht mehr jedes Wort muss passen: bei einem oder zwei Suchwoertern
--     alle, sonst drei von fuenf (ST.NEED). Wer viel tippt, findet mehr,
--     nicht weniger.
--   * Treffer werden GEWERTET: im Namen zaehlt mehr als in der
--     Beschreibung, ganze Woerter mehr als Staemme, Tippfehler am
--     wenigsten; die ganze Frage am Stueck im Namen gibt einen Bonus.
-- Umlaute und Gross/Klein spielen keine Rolle ("Ruestung" = "rüstung").
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.SearchText = {}
local ST = WeintCodex.SearchText

ST.NEED = 0.6          -- Anteil der Suchwoerter, die passen muessen (ab drei)
ST.FUZZY_MIN = 5       -- Tippfehler erst ab so vielen Buchstaben
ST.STEM_MIN = 4        -- kuerzere Staemme passen zu vielem

-- Gewicht je Art, wie ein Wort passt.
ST.HIT = { word = 1.0, syn = 0.9, stem = 0.75, fuzzy = 0.5 }

--------------------------------------------------
-- Text vereinheitlichen
--------------------------------------------------
local FOLD = { ["ä"] = "ae", ["ö"] = "oe", ["ü"] = "ue", ["Ä"] = "ae", ["Ö"] = "oe", ["Ü"] = "ue", ["ß"] = "ss" }

-- Klein, Umlaute ausgeschrieben, Satzzeichen zu Leerraum. Byteweise
-- sicher: ersetzt werden nur ganze UTF-8-Folgen; andere Zeichen (z. B.
-- Anfuehrungszeichen „“) werden Leerraum.
function ST.Fold(text)
    text = tostring(text or ""):gsub("\195[\132\150\156\164\182\188\159]", FOLD):lower()
    text = text:gsub("|c%x%x%x%x%x%x%x%x", " "):gsub("|r", " ")
    text = text:gsub("[\226][\128-\191][\128-\191]", " ")   -- Typografie (– „ “ …)
    text = text:gsub("[%p]", function(c) return (c == "'" or c == "-") and c or " " end)
    return text
end

-- Woerter, die in jeder Frage stehen und nichts sagen. Schon gefaltet.
-- FILL faellt immer weg (Fragewoerter, Artikel, Fuerwoerter, Hilfsverben).
-- SOFT nur, wenn sonst noch etwas uebrig bleibt: "Einstellungen" allein
-- sucht die Einstellungen, "Taschen einstellen" sucht die Taschen.
ST.FILL, ST.SOFT = {}, {}
for w in ([[
wie wo was wann warum wieso weshalb wer wen wem welche welcher welches welchen welchem
kann kannst koennen konnte koennte koenntest muss musst muessen soll sollte will willst moechte moechtest
ich du er sie es man wir ihr mir mich dir dich uns euch sich
mein meine meinen meinem meiner meines dein deine deinen deinem deiner deines sein seine unser
der die das den dem des ein eine einen einem einer eines kein keine keinen
und oder aber auch noch schon mal bitte gerne gern denn dass ob wenn als so da hier dort
mit von vom zu zum zur im in ins an am auf aus fuer bei beim nach ueber unter um durch gegen ohne bis
ist sind war bin bist wird werden wurde hat habe hab haben hast gibt gab geht gehen gehts
nicht nur alle alles etwas irgendwo irgendwie eigentlich jetzt immer lassen
]]):gmatch("%S+") do ST.FILL[w] = true end
for w in ([[
einstellen einstelle einstellung einstellungen aendern aendere finde finden findet suche suchen sehe sehen sieht
mache machen macht tun tut stelle stellen bekomme bekommen kriege kriegen brauche brauchen
zeigen zeige zeigt anzeigen anzeige anzuzeigen anlassen
]]):gmatch("%S+") do ST.SOFT[w] = true end

-- Endungen, die fuer den Stamm wegfallen (laengste zuerst).
local ENDINGS = { "ungen", "ern", "en", "er", "es", "em", "e", "n", "s" }
function ST.Stem(w)
    for _, e in ipairs(ENDINGS) do
        if #w - #e >= ST.STEM_MIN and w:sub(-#e) == e then return w:sub(1, -#e - 1) end
    end
    return w
end

--------------------------------------------------
-- Suchfrage zerlegen
--------------------------------------------------
-- { tokens = { { w, stem, syn = {...} } }, phrase = "gefaltete frage" }
-- oder nil, wenn nichts Suchbares uebrig bleibt.
function ST.Parse(text)
    local f = ST.Fold(text)
    local syn = WeintCodex.HelpData and WeintCodex.HelpData.SYNONYMS or {}
    local tokens, words, seen = {}, {}, {}
    local soft = {}
    for w in f:gmatch("%S+") do
        if ST.SOFT[w] and not seen[w] then seen[w] = true soft[#soft + 1] = w end
    end
    local list = {}
    for w in f:gmatch("%S+") do
        if not ST.FILL[w] and not ST.SOFT[w] then list[#list + 1] = w end
    end
    if #list == 0 then list = soft end
    for _, w in ipairs(list) do
        if #w >= 2 and not seen[w .. "\0"] then
            seen[w .. "\0"] = true
            seen[w] = true
            local alts = {}
            for k, list in pairs(syn) do
                if ST.Fold(k) == w or ST.Fold(k) == ST.Stem(w) then
                    for _, a in ipairs(list) do alts[#alts + 1] = ST.Fold(a) end
                end
            end
            tokens[#tokens + 1] = { w = w, stem = ST.Stem(w), syn = alts }
            words[#words + 1] = w
        end
    end
    if #tokens == 0 then return nil end
    return { tokens = tokens, phrase = table.concat(words, " "), raw = f }
end

-- Wie viele Suchwoerter muessen passen?
function ST.Need(n)
    if n <= 2 then return n end
    return math.ceil(n * ST.NEED)
end

--------------------------------------------------
-- Tippfehler: hoechstens ein Buchstabe falsch, zu viel oder zu wenig.
--------------------------------------------------
local function OneEdit(a, b)
    local la, lb = #a, #b
    if math.abs(la - lb) > 1 then return false end
    if la == lb then
        local diff = 0
        for i = 1, la do
            if a:byte(i) ~= b:byte(i) then
                diff = diff + 1
                if diff > 1 then
                    -- zwei vertauschte Buchstaben zaehlen als ein Fehler
                    if diff == 2 and a:byte(i - 1) == b:byte(i) and a:byte(i) == b:byte(i - 1) then
                        return a:sub(i + 1) == b:sub(i + 1)
                    end
                    return false
                end
            end
        end
        return true
    end
    if la > lb then a, b, la, lb = b, a, lb, la end
    local i, j, skipped = 1, 1, false
    while i <= la and j <= lb do
        if a:byte(i) == b:byte(j) then i, j = i + 1, j + 1
        else
            if skipped then return false end
            skipped = true
            j = j + 1
        end
    end
    return true
end
ST.OneEdit = OneEdit

local function FuzzyIn(w, hay)
    if #w < ST.FUZZY_MIN then return false end
    for hw in hay:gmatch("%S+") do
        if math.abs(#hw - #w) <= 1 and OneEdit(w, hw) then return true end
        -- Wortanfang mit Tippfehler ("bedrohng" in "bedrohungsanzeige")
        if #hw > #w + 1 and OneEdit(w, hw:sub(1, #w)) then return true end
    end
    return false
end

-- Wie gut passt ein Suchwort in diesen (gefalteten) Text? 0 = gar nicht.
function ST.Hit(tok, hay, fuzzy)
    if hay == "" then return 0 end
    if hay:find(tok.w, 1, true) then return ST.HIT.word end
    for _, a in ipairs(tok.syn) do
        if hay:find(a, 1, true) then return ST.HIT.syn end
    end
    if tok.stem ~= tok.w and hay:find(tok.stem, 1, true) then return ST.HIT.stem end
    if fuzzy and FuzzyIn(tok.w, hay) then return ST.HIT.fuzzy end
    return 0
end

--------------------------------------------------
-- Wertung eines Eintrags
--------------------------------------------------
-- fields: Liste { gefalteter Text, Gewicht } - der erste ist der Name.
-- Gibt die Punkte zurueck oder nil, wenn zu wenige Woerter passen.
function ST.Score(q, fields, fuzzy)
    local total, matched = 0, 0
    for _, tok in ipairs(q.tokens) do
        local best = 0
        for _, f in ipairs(fields) do
            local h = ST.Hit(tok, f[1], fuzzy) * f[2]
            if h > best then best = h end
        end
        if best > 0 then matched = matched + 1 total = total + best end
    end
    if matched < ST.Need(#q.tokens) then return nil end
    local name = fields[1] and fields[1][1] or ""
    -- Die Frage am Stueck im Namen, oder der Name beginnt mit dem ersten
    -- Suchwort: das ist meist genau der gesuchte Eintrag.
    if #q.tokens > 1 and name:find(q.phrase, 1, true) then total = total + 3 end
    if name:sub(1, #q.tokens[1].w) == q.tokens[1].w then total = total + 1 end
    -- Alle Woerter getroffen schlaegt "fast alle".
    if matched == #q.tokens then total = total + 1 end
    return total
end

-- Bequem fuer einen einzelnen Text (Rueckfall fuer alte Aufrufer).
function ST.Matches(q, hay)
    if type(q) ~= "table" then q = ST.Parse(q) end
    if not q then return false end
    return ST.Score(q, { { ST.Fold(hay), 1 } }, true) ~= nil
end

-- Treffer sortieren: { score, order, ... } - Punkte absteigend, bei
-- Gleichstand die kleinere Ordnungszahl (Art und alte Reihenfolge).
function ST.Rank(list)
    table.sort(list, function(a, b)
        if a.score ~= b.score then return a.score > b.score end
        return a.order < b.order
    end)
    return list
end
