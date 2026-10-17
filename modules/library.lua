--------------------------------------------------
-- WeintCodex :: Buecher der Bibliothek - wie viele abgegeben? (6.56.0.0)
--------------------------------------------------
-- Wunsch: "angezeigt bekommen, wie viele man von diesen Buechern schon
-- abgegeben hat - bei 10 gibt's einen Hals, dann einen Ring usw."
--
-- Welche Buecher es gibt und welche Belohnungsquest bei wie vielen kommt,
-- steht in data/books.lua (erzeugt, Art `community`). OB ein Buch
-- abgegeben ist, sagt nur der Client: jedes Buch ist eine Abgabequest
-- (C_QuestLog.IsQuestFlaggedCompleted). Antwortet er nicht, gibt es keine
-- Zahl - "unbekannt" ist nicht "0 abgegeben".
--
-- Gezeigt wird es auf der Startseite (modules/home.lua, Karte
-- "Bibliothek") und im Tooltip jedes Buches.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.Library = {}

local LB = WeintCodex.Library

LB.REWARD_NAME = { neck = "Halskette", ring = "Ring", library25 = "Belohnung für 25 Bücher" }

local function Plain(v)
    local K = WeintCodex.UIKit
    if K and K.Plain then return K.Plain(v) end
    return v
end

local function Data() return WeintCodex.BooksData end

local function Faction()
    if not _G.UnitFactionGroup then return nil end
    local ok, f = pcall(_G.UnitFactionGroup, "player")
    f = ok and Plain(f) or nil
    return (f == "Alliance" and 1) or (f == "Horde" and 2) or nil
end

-- true / false / nil (Client antwortet nicht).
function LB.Done(quest)
    local ql = _G.C_QuestLog
    local f = (ql and ql.IsQuestFlaggedCompleted) or _G.IsQuestFlaggedCompleted
    if type(f) ~= "function" then return nil end
    local ok, v = pcall(f, quest)
    -- Nicht `ok and Plain(v) or nil`: das macht aus false ein nil.
    if not ok then return nil end
    v = Plain(v)
    if type(v) ~= "boolean" then return nil end
    return v
end

local function InBags(item)
    local ci = _G.C_Item
    local f = (ci and ci.GetItemCount) or _G.GetItemCount
    if type(f) ~= "function" then return false end
    local ok, n = pcall(f, item)
    n = ok and Plain(n) or nil
    return type(n) == "number" and n > 0
end

-- Buecher dieser Fraktion (ohne Fraktion: alle).
function LB.Mine()
    local d = Data()
    if not d then return {} end
    local me, out = Faction(), {}
    for _, b in ipairs(d.books) do
        if b[3] == 0 or not me or b[3] == me then out[#out + 1] = b end
    end
    return out
end

-- { done, total, bag, next = Belohnung, claim = Belohnung zum Abholen,
--   finished = alles abgeholt } oder nil, wenn der Client nichts sagt.
function LB.Progress()
    local d = Data()
    if not d then return nil end
    local done, bag, total = 0, 0, 0
    for _, b in ipairs(LB.Mine()) do
        total = total + 1
        local v = LB.Done(b[1])
        if v == nil then return nil end
        if v then done = done + 1 elseif InBags(b[2]) then bag = bag + 1 end
    end
    local p = { done = done, total = total, bag = bag }
    for _, r in ipairs(d.rewards) do
        local got = LB.Done(r.quest)
        if done >= r.goal and got == false and not p.claim then p.claim = r end
        if done < r.goal and not p.next then p.next = r end
    end
    p.finished = not p.next and not p.claim
    return p
end

function LB.RewardName(r) return r and (LB.REWARD_NAME[r.key] or "Belohnung") or nil end

-- Wo abgeben: Name des Bibliothekars (englisch, wie im Bestand) und Ort.
function LB.Librarian()
    local d = Data()
    local f = Faction()
    local l = d and d.librarians and d.librarians[f == 1 and "Alliance" or "Horde"]
    if not l then return nil end
    local place = f == 1 and "Sturmwind, Magierviertel" or "Unterstadt, Magierviertel"
    return l.name, place, l
end

-- Text "7 von 10 – noch 3 bis zur Halskette" (ohne Abholen).
function LB.Line(p)
    if not p then return nil end
    if p.claim then
        return p.done .. " abgegeben – " .. LB.RewardName(p.claim) .. " abholen"
    end
    if p.next then
        local left = p.next.goal - p.done
        return p.done .. " von " .. p.next.goal .. " – noch " .. left .. " bis "
            .. (p.next.key == "ring" and "zum " or "zur ") .. LB.RewardName(p.next)
    end
    return p.done .. " abgegeben – alle Belohnungen erhalten"
end

--------------------------------------------------
-- Wo liegen sie? (6.57.0.0)
--------------------------------------------------
-- Fundort je Buch aus dem Bestand (Karte, x, y in Prozent). Gezeigt nur,
-- was du noch nicht abgegeben hast und nicht schon in der Tasche traegst.

function LB.Missing()
    local out = {}
    for _, b in ipairs(LB.Mine()) do
        if LB.Done(b[1]) == false and not InBags(b[2]) and type(b[5]) == "number" and b[5] > 0 then
            out[#out + 1] = b
        end
    end
    return out
end

-- Naechstes fehlendes Buch auf deinem Kontinent (Luftlinie), oder nil.
function LB.Nearest()
    local K = WeintCodex.UIKit
    if not (K and K.PlayerWorld and K.ToWorld) then return nil end
    local pc, pn, pw = K.PlayerWorld()
    if not pc then return nil end
    local best, bestD
    for _, b in ipairs(LB.Missing()) do
        local c, n, w = K.ToWorld(b[5], b[6] / 100, b[7] / 100)
        if c == pc and n then
            local d = (n - pn) ^ 2 + (w - pw) ^ 2
            if not bestD or d < bestD then best, bestD = b, d end
        end
    end
    return best, bestD and math.sqrt(bestD) or nil
end

function LB.ZoneName(map)
    local cm = _G.C_Map
    if not (cm and cm.GetMapInfo) then return nil end
    local ok, info = pcall(cm.GetMapInfo, map)
    local n = ok and type(info) == "table" and Plain(info.name)
    return type(n) == "string" and n or nil
end

-- Name im Spiel (Client), sonst der englische aus dem Bestand.
function LB.BookName(b)
    local ci = _G.C_Item
    if ci and ci.GetItemNameByID then
        local ok, n = pcall(ci.GetItemNameByID, b[2])
        n = ok and Plain(n) or nil
        if type(n) == "string" and n ~= "" then return n end
    end
    return b[4]
end

-- 6.59.0.0 (Wunsch: "geprueft auf Standort und Stufe, wo ich die Buecher am
-- besten sammeln kann und was abgeraten wird"). Bewertet wird nur mit dem,
-- was feststeht: deine Stufe (Client), der Stufenbereich des Gebiets
-- (data/zoneinfo.lua, Art classic) und die Luftlinie auf deinem Kontinent.
-- Gefahr unterwegs, Wege und Feinde in der Naehe kennt kein Bestand.
LB.TOO_HIGH = 3       -- Gebiet beginnt mehr als so viele Stufen ueber dir
LB.CATS = {
    { key = "bag",   label = "Abgeben",     color = "green" },
    { key = "good",  label = "Empfohlen",   color = "accent" },
    { key = "far",   label = "Möglich",     color = "textNormal" },
    { key = "risky", label = "Abgeraten",   color = "danger" },
    { key = "done",  label = "Abgegeben",   color = "textMuted" },
}

local function Level()
    if not _G.UnitLevel then return nil end
    local ok, l = pcall(_G.UnitLevel, "player")
    l = ok and Plain(l) or nil
    return type(l) == "number" and l > 0 and l or nil
end

function LB.ZoneLevel(map)
    local z = WeintCodex.ZoneInfoData and WeintCodex.ZoneInfoData[map]
    return z and z.lvl and z.lvl[1], z and z.lvl and z.lvl[2]
end

-- Kategorie, Begruendung, Luftlinie (Meter) oder nil.
function LB.Rate(b, pc, pn, pw, level)
    local d = LB.Done(b[1])
    if d == true then return "done", "schon abgegeben" end
    if InBags(b[2]) then return "bag", "liegt in deiner Tasche" end
    local lo, hi = LB.ZoneLevel(b[5])
    if level and lo and lo > level + LB.TOO_HIGH then
        return "risky", "Gebiet Stufe " .. lo .. "–" .. hi .. ", du bist " .. level
    end
    local K = WeintCodex.UIKit
    local dist
    if pc and K and K.ToWorld then
        local c, n, w = K.ToWorld(b[5], b[6] / 100, b[7] / 100)
        if c == pc and n then dist = math.sqrt((n - pn) ^ 2 + (w - pw) ^ 2) end
    end
    local range = lo and ("Gebiet Stufe " .. lo .. "–" .. hi) or "Stufe des Gebiets unbekannt"
    if dist then return "good", range, dist end
    return "far", range .. " · anderer Kontinent"
end

-- Alle Buecher deiner Fraktion, bewertet und sortiert: { b, cat, why, dist }.
function LB.Rated()
    local K = WeintCodex.UIKit
    local pc, pn, pw
    if K and K.PlayerWorld then pc, pn, pw = K.PlayerWorld() end
    local level = Level()
    local out = {}
    for _, b in ipairs(LB.Mine()) do
        local cat, why, dist = LB.Rate(b, pc, pn, pw, level)
        out[#out + 1] = { b = b, cat = cat, why = why, dist = dist }
    end
    local rank = {}
    for i, c in ipairs(LB.CATS) do rank[c.key] = i end
    table.sort(out, function(x, y)
        if x.cat ~= y.cat then return rank[x.cat] < rank[y.cat] end
        if x.dist and y.dist then return x.dist < y.dist end
        if (LB.ZoneLevel(x.b[5]) or 99) ~= (LB.ZoneLevel(y.b[5]) or 99) then
            return (LB.ZoneLevel(x.b[5]) or 99) < (LB.ZoneLevel(y.b[5]) or 99)
        end
        return x.b[1] < y.b[1]
    end)
    return out
end

-- Questpfeil auf ein Buch (nil: auf das naechste). Der Pfeil zeigt dorthin,
-- bis das Buch in der Tasche liegt oder abgegeben ist.
function LB.Guide(b)
    b = b or LB.Nearest()
    local QA = WeintCodex.UIQuestArrow
    if not (b and QA and QA.SetCustom) then return false end
    QA.SetCustom({ map = b[5], x = b[6] / 100, y = b[7] / 100, title = "Buch: " .. LB.BookName(b),
        done = function() return InBags(b[2]) or LB.Done(b[1]) == true end })
    return true
end

--------------------------------------------------
-- Tooltip jedes Buches
--------------------------------------------------

local byItem
function LB.BookOf(item)
    local d = Data()
    if not d then return nil end
    if not byItem then
        byItem = {}
        for _, b in ipairs(d.books) do byItem[b[2]] = b end
    end
    return byItem[item]
end

function LB.TooltipLines(item)
    local b = LB.BookOf(item)
    if not b then return nil end
    local lines = {}
    local v = LB.Done(b[1])
    local head = "Buch der Bibliothek"
    if v == true then head = head .. " · schon abgegeben"
    elseif v == false then head = head .. " · noch nicht abgegeben" end
    lines[1] = head
    local line = LB.Line(LB.Progress())
    if line then lines[#lines + 1] = line end
    local name, place = LB.Librarian()
    if name and v == false then lines[#lines + 1] = "Abgabe: " .. name .. ", " .. place end
    lines[#lines + 1] = "Unbestätigt – Wissensstand aus der Beta."
    return lines
end

local function OnItem(tt, data)
    if tt ~= _G.GameTooltip and tt ~= _G.ItemRefTooltip then return end
    if tt.IsForbidden and tt:IsForbidden() then return end
    local AP = WeintCodex.UIAuctionPrices
    local id
    if AP and AP.ItemIdOf then id = AP.ItemIdOf(tt, data)
    else id = type(data) == "table" and Plain(data.id) end
    if type(id) ~= "number" then return end
    local lines = LB.TooltipLines(id)
    if not lines then return end
    local C = WeintCodex.Colors
    local a, m = C.infoBright, C.textMuted
    tt:AddLine(lines[1], a[1], a[2], a[3])
    for i = 2, #lines do tt:AddLine(lines[i], m[1], m[2], m[3], true) end
end
LB.OnItem = OnItem

function LB.Hook()
    if LB._hooked then return end
    LB._hooked = true
    local tdp, e = _G.TooltipDataProcessor, _G.Enum and _G.Enum.TooltipDataType
    if tdp and tdp.AddTooltipPostCall and e and e.Item then
        pcall(tdp.AddTooltipPostCall, e.Item, OnItem)
    elseif _G.GameTooltip and _G.GameTooltip.HookScript then
        _G.GameTooltip:HookScript("OnTooltipSetItem", function(self) OnItem(self) end)
    end
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function() LB.Hook() end)
LB.events = ev
