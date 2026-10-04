--------------------------------------------------
-- WeintCodex :: Abgleich mit dem Client (6.10.3.0)
--------------------------------------------------
-- /wc abgleich. "Niemand in diesem Projekt hat den Forever-Client
-- gelesen" (data/dungeons.lua, data/sources.lua) - deshalb tragen die
-- Bosslisten der Forever-Dungeons `community`: Berichte UEBER den
-- Client. Seit dem Beta-Start laeuft der Client aber beim Entwickler, und
-- er kennt die Dungeons selbst: die Gruppensuche nennt Name, Stufen,
-- Groesse und die Kaempfe in ihrer Reihenfolge, das Dungeonkompendium
-- (falls der Client eines hat) Instanzen und Kaempfe.
--
-- Dieser Befehl LIEST das und haelt es gegen den Codex - als Bericht zum
-- Kopieren (UIKit.ShowReport). ER SCHREIBT NICHTS IN DIE DATEN. Was
-- uebernommen wird, entscheidet ein Mensch am Bericht, Eintrag fuer
-- Eintrag, und traegt es mit einer Quelle `beta` (Build, Datum) ein -
-- "Kein Bestand ohne Herkunft" gilt weiter, nur dass die Herkunft jetzt
-- benennbar fester sein kann.
--
-- ZUORDNUNG. Der Codex fuehrt englische Namen, ein deutscher Client
-- nennt deutsche. Zugeordnet wird deshalb in zwei Stufen:
--   1. gleicher Name (ohne Gross/klein, Satzzeichen, "The") - sicher;
--      dann auch Boss fuer Boss;
--   2. sonst gleicher Stufenbereich - nur VERMUTLICH, mit allen
--      Kandidaten, und ohne Bossvergleich (die Namen sind andere).
-- Der vollstaendige Bestand des Clients steht am Ende des Berichts, damit
-- auch das zugeordnet werden kann, was keine der beiden Stufen fand.
--
-- NEBENWIRKUNG, die einzige: das Dungeonkompendium merkt sich die zuletzt
-- gewaehlte Erweiterung (EJ_SelectTier). Sie wird danach zurueckgesetzt.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.ClientCheck = {}

local CC = WeintCodex.ClientCheck

-- Die Gruppensuche hat keine Liste ihrer Kennungen fuer alle Dungeons -
-- gefragt wird jede Kennung bis hierher. Einmal je Befehl, nicht im Takt.
CC.MAX_LFG_ID = 3000

local function Plain(v)
    local K = WeintCodex.UIKit
    if K and K.Plain then return K.Plain(v) end
    return v
end

-- Name zum Vergleichen: klein, ohne Leerzeichen und Satzzeichen, ohne
-- fuehrendes "The ". Umlaute bleiben, wie sie sind (Bytes ueber 127).
function CC.Norm(name)
    if type(name) ~= "string" then return nil end
    local s = name:lower():gsub("^the%s+", "")
    s = s:gsub("[%s%p]", "")
    return s
end

--------------------------------------------------
-- Lesen
--------------------------------------------------

-- Die Gruppensuche: je Kennung Name, Art, Stufen, Groesse, Kaempfe.
function CC.ReadLFG()
    local info = _G.GetLFGDungeonInfo
    if type(info) ~= "function" then return nil, "GetLFGDungeonInfo fehlt" end
    local numEnc, encInfo = _G.GetLFGDungeonNumEncounters, _G.GetLFGDungeonEncounterInfo
    local out = {}
    for id = 1, CC.MAX_LFG_ID do
        local ok, name, typeID, subtypeID, minLevel, maxLevel, recLevel, minRec, maxRec,
              _, _, _, difficulty, maxPlayers = pcall(info, id)
        name = ok and Plain(name) or nil
        if type(name) == "string" and name ~= "" then
            local e = {
                id = id, name = name, typeID = Plain(typeID), subtypeID = Plain(subtypeID),
                minLevel = Plain(minLevel), maxLevel = Plain(maxLevel), recLevel = Plain(recLevel),
                minRec = Plain(minRec), maxRec = Plain(maxRec),
                difficulty = Plain(difficulty), size = Plain(maxPlayers), bosses = {},
            }
            if type(numEnc) == "function" and type(encInfo) == "function" then
                local nok, n = pcall(numEnc, id)
                n = nok and Plain(n) or nil
                if type(n) == "number" then
                    e.bossCount = n
                    for i = 1, n do
                        local bok, boss = pcall(encInfo, id, i)
                        boss = bok and Plain(boss) or nil
                        e.bosses[#e.bosses + 1] = type(boss) == "string" and boss or "?"
                    end
                end
            end
            out[#out + 1] = e
        end
    end
    return out
end

-- Das Dungeonkompendium: je Erweiterung die Instanzen (Dungeon, Schlachtzug)
-- und ihre Kaempfe. Setzt die gewaehlte Erweiterung danach zurueck.
function CC.ReadEJ()
    local numTiers, selectTier = _G.EJ_GetNumTiers, _G.EJ_SelectTier
    local byIndex, selectInst, encByIndex = _G.EJ_GetInstanceByIndex, _G.EJ_SelectInstance, _G.EJ_GetEncounterInfoByIndex
    if type(numTiers) ~= "function" or type(selectTier) ~= "function" or type(byIndex) ~= "function"
        or type(encByIndex) ~= "function" then
        return nil, "kein Dungeonkompendium (EJ_*) im Client"
    end
    local before = _G.EJ_GetCurrentTier and select(2, pcall(_G.EJ_GetCurrentTier)) or nil
    local out = {}
    local ok, tiers = pcall(numTiers)
    tiers = ok and Plain(tiers) or 0
    for t = 1, (type(tiers) == "number" and tiers or 0) do
        pcall(selectTier, t)
        for _, isRaid in ipairs({ false, true }) do
            for idx = 1, 200 do
                local iok, instanceID, name = pcall(byIndex, idx, isRaid)
                instanceID, name = iok and Plain(instanceID) or nil, iok and Plain(name) or nil
                if type(instanceID) ~= "number" then break end
                local e = { id = instanceID, name = name, raid = isRaid, tier = t, bosses = {} }
                if type(selectInst) == "function" then pcall(selectInst, instanceID) end
                for i = 1, 40 do
                    local eok, boss = pcall(encByIndex, i, instanceID)
                    boss = eok and Plain(boss) or nil
                    if type(boss) ~= "string" then break end
                    e.bosses[#e.bosses + 1] = boss
                end
                out[#out + 1] = e
            end
        end
    end
    if type(before) == "number" then pcall(selectTier, before) end
    return out
end

--------------------------------------------------
-- Vergleichen
--------------------------------------------------

-- Was der Codex behauptet: Forever- und Classic-Dungeons, Schlachtzuege.
function CC.CodexInstances()
    local out = {}
    local D = WeintCodex.DungeonData
    for _, d in ipairs(D and D.AllInstances and D.AllInstances() or {}) do out[#out + 1] = d end
    local R = WeintCodex.RaidData
    for _, r in ipairs(R and R.All and R.All() or {}) do out[#out + 1] = r end
    return out
end

local function SourceText(inst)
    local S = WeintCodex.Sources
    local src = inst.bossSource
    if not (S and S.IsValid and S.IsValid(src)) then return "ohne Liste" end
    return S.Prefix(src) or "bestätigt"
end

local function Levels(minL, maxL)
    if type(minL) ~= "number" then return "Stufe ?" end
    if type(maxL) ~= "number" or maxL == minL then return "Stufe " .. minL end
    return string.format("Stufe %d–%d", minL, maxL)
end

local function SameLevels(inst, e)
    if type(inst.minLevel) ~= "number" then return false end
    if inst.minLevel == e.minLevel and inst.maxLevel == e.maxLevel then return true end
    return inst.minLevel == e.minRec and inst.maxLevel == e.maxRec
end

-- Boss fuer Boss (nur bei gleichem Namen der Instanz - sonst sind es
-- andere Sprachen): gleich, nur im Codex, nur im Client; Reihenfolge,
-- wo der Codex eine behauptet.
function CC.CompareBosses(inst, clientBosses)
    local res = { same = {}, codexOnly = {}, clientOnly = {}, orderDiff = false }
    local client = {}
    for i, b in ipairs(clientBosses) do client[CC.Norm(b) or ""] = i end
    local codex = {}
    for _, b in ipairs(inst.bosses or {}) do
        local n = CC.Norm(b.name) or ""
        codex[n] = b
        if client[n] then
            res.same[#res.same + 1] = b.name
            if inst.orderKnown and b.order and b.order ~= client[n] then res.orderDiff = true end
        else
            res.codexOnly[#res.codexOnly + 1] = b.name
        end
    end
    for _, b in ipairs(clientBosses) do
        if not codex[CC.Norm(b) or ""] then res.clientOnly[#res.clientOnly + 1] = b end
    end
    return res
end

-- Der Bericht. `lfg`, `ej` sind die gelesenen Bestaende (oder nil und ein
-- Grund) - getrennt, damit der Pruflauf sie unterschieben kann.
function CC.Report(lfg, lfgWhy, ej, ejWhy)
    local out = {}
    local v, build = nil, nil
    if type(_G.GetBuildInfo) == "function" then v, build = _G.GetBuildInfo() end
    local locale = type(_G.GetLocale) == "function" and _G.GetLocale() or "?"
    out[#out + 1] = string.format("WeintCodex %s · Abgleich mit dem Client %s (Build %s) · Sprache %s · %s",
        tostring(WeintCodex.Version), tostring(Plain(v)), tostring(Plain(build)), tostring(locale),
        type(_G.date) == "function" and _G.date("%d.%m.%Y") or "")
    out[#out + 1] = "Liest nur. In die Daten des Codex wird nichts geschrieben."
    out[#out + 1] = lfg and string.format("Gruppensuche: %d Einträge", #lfg) or ("Gruppensuche: " .. tostring(lfgWhy))
    out[#out + 1] = ej and string.format("Dungeonkompendium: %d Instanzen", #ej) or ("Dungeonkompendium: " .. tostring(ejWhy))
    if locale ~= "enUS" and locale ~= "enGB" then
        out[#out + 1] = "Der Client ist nicht englisch: Namen passen selten wörtlich, zugeordnet wird dann nur vermutlich über den Stufenbereich."
    end
    out[#out + 1] = ""

    -- Alle Eintraege des Clients mit Namen, fuer die Zuordnung.
    local all = {}
    for _, e in ipairs(lfg or {}) do e.from = "Gruppensuche #" .. e.id all[#all + 1] = e end
    for _, e in ipairs(ej or {}) do e.from = "Kompendium #" .. e.id all[#all + 1] = e end
    local used = {}
    local counts = { name = 0, level = 0, none = 0 }

    out[#out + 1] = "== Codex gegen Client =="
    for _, inst in ipairs(CC.CodexInstances()) do
        local norm = CC.Norm(inst.name)
        local byName = {}
        for _, e in ipairs(all) do
            if CC.Norm(e.name) == norm then byName[#byName + 1] = e end
        end
        local head = string.format("%s (%s, %s Bosse im Codex, %s)", inst.name, Levels(inst.minLevel, inst.maxLevel),
            tostring(#(inst.bosses or {})), SourceText(inst))
        if #byName > 0 then
            counts.name = counts.name + 1
            out[#out + 1] = "[Name] " .. head
            for _, e in ipairs(byName) do
                used[e] = true
                out[#out + 1] = string.format("   %s „%s“ · %s · %s Kämpfe", e.from, e.name, Levels(e.minLevel, e.maxLevel),
                    tostring(e.bossCount or #e.bosses))
                if #e.bosses > 0 then
                    local r = CC.CompareBosses(inst, e.bosses)
                    out[#out + 1] = string.format("      gleich %d: %s", #r.same, table.concat(r.same, ", "))
                    if #r.codexOnly > 0 then out[#out + 1] = "      nur im Codex: " .. table.concat(r.codexOnly, ", ") end
                    if #r.clientOnly > 0 then out[#out + 1] = "      nur im Client: " .. table.concat(r.clientOnly, ", ") end
                    if r.orderDiff then out[#out + 1] = "      Reihenfolge weicht ab – Client: " .. table.concat(e.bosses, " › ") end
                end
            end
        else
            local cands = {}
            for _, e in ipairs(lfg or {}) do
                if SameLevels(inst, e) then cands[#cands + 1] = e end
            end
            if #cands > 0 then
                counts.level = counts.level + 1
                out[#out + 1] = "[Stufen, vermutlich] " .. head
                for _, e in ipairs(cands) do
                    out[#out + 1] = string.format("   %s „%s“ · %s · %s Kämpfe%s", e.from, e.name, Levels(e.minLevel, e.maxLevel),
                        tostring(e.bossCount or #e.bosses), #e.bosses > 0 and (": " .. table.concat(e.bosses, " › ")) or "")
                end
            else
                counts.none = counts.none + 1
                out[#out + 1] = "[kein Gegenstück] " .. head
            end
        end
    end
    out[#out + 1] = ""
    out[#out + 1] = string.format("Summe: %d über den Namen, %d nur über die Stufen (vermutlich), %d ohne Gegenstück.",
        counts.name, counts.level, counts.none)
    CC.last = counts

    -- Der ganze Bestand des Clients, damit auch Unzugeordnetes dasteht.
    out[#out + 1] = ""
    out[#out + 1] = "== Bestand des Clients =="
    for _, e in ipairs(all) do
        local kind
        if e.raid ~= nil then kind = e.raid and "Schlachtzug" or "Dungeon"
        else kind = string.format("Art %s/%s", tostring(e.typeID), tostring(e.subtypeID)) end
        out[#out + 1] = string.format("%s%s „%s“ · %s · %s%s · %s Kämpfe%s", used[e] and "" or "(nicht zugeordnet) ",
            e.from, tostring(e.name), kind, Levels(e.minLevel, e.maxLevel),
            type(e.size) == "number" and (" · " .. e.size .. " Spieler") or "",
            tostring(e.bossCount or #e.bosses), #e.bosses > 0 and (": " .. table.concat(e.bosses, " › ")) or "")
    end
    if #all == 0 then out[#out + 1] = "   (nichts gelesen)" end
    return out
end

function CC.Run()
    local lfg, lfgWhy = CC.ReadLFG()
    local ej, ejWhy = CC.ReadEJ()
    return CC.Report(lfg, lfgWhy, ej, ejWhy)
end
