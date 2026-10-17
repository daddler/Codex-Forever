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
