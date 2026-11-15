--------------------------------------------------
-- WeintCodex :: Komfort - Feldbuch und Ruf-Belohnungen
--------------------------------------------------
-- 1.0.7.0 (Wunsch nach dem Vergleich mit Naowh Forever "Field Journal" und
-- den Ruf-Belohnungen des Dungeon Journal, Verhalten nachgebaut, eigener
-- Code). Daten: data/fieldjournal.lua, data/reprewards.lua (erzeugt,
-- `community`).
--
-- TOOLTIP: ein Fisch nennt seine drei ergiebigsten Gebiete (Anteil am Fang)
-- und ab welcher Angelfertigkeit; ein Kraut die Gebiete und die Fertigkeit;
-- ein Gericht, wie man das Rezept lernt (Haendler mit Name und Gebiet,
-- Lehrer, Quest, Beute). Eine Ruf-Belohnung nennt Fraktion, Rufstufe und
-- Preis. Gebietsnamen vom Client (C_Map.GetMapInfo), nie geraten.
--
-- GEZAEHLT: was du selbst pluenderst (Fische und Kraeuter des Feldbuchs),
-- je Charakter in K.CharState().field - erst ab 1.0.7.0, nicht rueckwirkend.
--
-- /wcui feldbuch: das ganze Feldbuch als Liste; /wcui ruf: Belohnungen der
-- Fraktionen mit deinem Stand.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIFieldJournal = {}

local FJ = WeintCodex.UIFieldJournal
local K = WeintCodex.UIKit
local C = WeintCodex.Colors

local function D() return WeintCodex.FieldJournalData end
local function R() return WeintCodex.RepRewardsData end

-- Gegenstand -> { kind, entry } bzw. -> { faction, standing, price }
local byItem, byReward
local function Index()
    if byItem then return end
    byItem, byReward = {}, {}
    for _, part in ipairs({ "fish", "herbs", "dishes" }) do
        for _, e in ipairs(D() and D()[part] or {}) do
            if e.item then byItem[e.item] = { kind = part, e = e } end
        end
    end
    for fid, f in pairs(R() and R().factions or {}) do
        for _, tier in ipairs(f.tiers or {}) do
            for _, item in ipairs(tier[2] or {}) do
                byReward[item] = byReward[item] or { faction = fid, standing = tier[1], price = f.prices and f.prices[item] }
            end
        end
    end
end
function FJ.Of(id) Index() return byItem[id] end
function FJ.RewardOf(id) Index() return byReward[id] end

local mapNames = {}
function FJ.MapName(map)
    if mapNames[map] ~= nil then return mapNames[map] or nil end
    local cm = _G.C_Map
    local name
    if cm and cm.GetMapInfo then
        local ok, info = pcall(cm.GetMapInfo, map)
        name = ok and type(info) == "table" and K.Plain(info.name)
    end
    mapNames[map] = type(name) == "string" and name or false
    return mapNames[map] or nil
end

function FJ.FactionName(fid)
    local cr = _G.C_Reputation
    if cr and cr.GetFactionDataByID then
        local ok, d = pcall(cr.GetFactionDataByID, fid)
        local n = ok and type(d) == "table" and K.Plain(d.name)
        if type(n) == "string" and n ~= "" then return n end
    end
    local f = R() and R().factions[fid]
    return f and f.name or ("Fraktion " .. fid)
end

FJ.STANDING = { [4] = "Neutral", [5] = "Freundlich", [6] = "Wohlwollend", [7] = "Respektvoll", [8] = "Ehrfürchtig" }
FJ.HOW = { trainer = "beim Lehrer", quest = "über eine Quest", drop = "als Beute", world = "in der Welt" }

local function Money(c)
    local AP = WeintCodex.UIAuctionPrices
    return AP and AP.Money and AP.Money(c) or tostring(c)
end

-- Zeilen fuer den Tooltip: { text } oder { links, rechts }.
function FJ.Lines(id)
    local out = {}
    local hit = FJ.Of(id)
    if hit and hit.kind == "fish" then
        local z = hit.e.zones or {}
        local parts = {}
        for i = 1, math.min(#z, 6), 2 do
            local n = FJ.MapName(z[i])
            if n then parts[#parts + 1] = n .. (z[i + 1] and (" " .. math.floor(z[i + 1] + 0.5) .. " %") or "") end
        end
        if #parts > 0 then out[#out + 1] = { "Feldbuch: " .. table.concat(parts, ", ") } end
        if hit.e.skill then out[#out + 1] = { "Angeln ab", tostring(hit.e.skill) } end
        if hit.e.schools then out[#out + 1] = { "Auch aus Fischschwärmen" } end
    elseif hit and hit.kind == "herbs" then
        local parts = {}
        for _, m in ipairs(hit.e.zones or {}) do
            local n = FJ.MapName(m)
            if n then parts[#parts + 1] = n end
        end
        if #parts > 0 then out[#out + 1] = { "Feldbuch: " .. table.concat(parts, ", ") } end
        if hit.e.skill then out[#out + 1] = { "Kräuterkunde ab", tostring(hit.e.skill) } end
    elseif hit and hit.kind == "dishes" then
        local e = hit.e
        local fac = _G.UnitFactionGroup and K.Plain(_G.UnitFactionGroup("player"))
        local v = (fac == "Horde" and e.H) or (fac == "Alliance" and e.A) or e.B
        if e.how == "vendor" and v then
            local n = FJ.MapName(v[2])
            out[#out + 1] = { "Rezept beim Händler", v[1] .. (n and (", " .. n) or "") }
        elseif FJ.HOW[e.how] then
            out[#out + 1] = { "Rezept " .. FJ.HOW[e.how] }
        end
        if e.skill then out[#out + 1] = { "Kochkunst ab", tostring(e.skill) } end
    end
    local rw = FJ.RewardOf(id)
    if rw then
        out[#out + 1] = { "Ruf: " .. FJ.FactionName(rw.faction), (FJ.STANDING[rw.standing] or ("Stufe " .. rw.standing))
            .. (rw.price and (" · " .. Money(rw.price)) or "") }
    end
    local n = FJ.Caught(id)
    if n and n > 0 then out[#out + 1] = { "Selbst geplündert", tostring(n) } end
    return #out > 0 and out or nil
end

--------------------------------------------------
-- Gezaehlt (je Charakter)
--------------------------------------------------

local function Store()
    local st = K.CharState and K.CharState()
    if not st then return nil end
    st.field = st.field or {}
    return st.field
end
function FJ.Caught(id)
    local s = Store()
    return s and s[id] or nil
end
function FJ.Count(id, n)
    local hit = FJ.Of(id)
    if not (hit and (hit.kind == "fish" or hit.kind == "herbs")) then return false end
    local s = Store()
    if not s then return false end
    s[id] = (s[id] or 0) + (n or 1)
    return true
end

local function OnLoot()
    if not (_G.GetNumLootItems and _G.GetLootSlotLink and _G.GetLootSlotInfo) then return end
    local n = K.Plain(_G.GetNumLootItems()) or 0
    for i = 1, n do
        local link = K.Plain(_G.GetLootSlotLink(i))
        local id = type(link) == "string" and tonumber(link:match("item:(%d+)"))
        if id then
            local _, _, qty = _G.GetLootSlotInfo(i)
            FJ.Count(id, tonumber(K.Plain(qty)) or 1)
        end
    end
end

--------------------------------------------------
-- Tooltip und Befehle
--------------------------------------------------

local function OnItem(tt, data)
    if tt ~= _G.GameTooltip and tt ~= _G.ItemRefTooltip then return end
    if tt.IsForbidden and tt:IsForbidden() then return end
    local AP = WeintCodex.UIAuctionPrices
    local id = AP and AP.ItemIdOf and AP.ItemIdOf(tt, data)
    if not id then return end
    local lines = FJ.Lines(id)
    if not lines then return end
    local m, b = C.textMuted, C.textBright
    for _, l in ipairs(lines) do
        if l[2] then tt:AddDoubleLine(l[1], l[2], m[1], m[2], m[3], b[1], b[2], b[3])
        else tt:AddLine(l[1], m[1], m[2], m[3], true) end
    end
end

function FJ.Report()
    local out = { "Feldbuch (Wissensstand der Community, für Forever unbestätigt)", "" }
    local function name(id)
        local n = _G.C_Item and _G.C_Item.GetItemNameByID and _G.C_Item.GetItemNameByID(id)
        return type(n) == "string" and n or ("Gegenstand " .. id)
    end
    for _, part in ipairs({ { "fish", "Fische" }, { "herbs", "Kräuter" }, { "dishes", "Gerichte" } }) do
        out[#out + 1] = "== " .. part[2] .. " =="
        for _, e in ipairs(D()[part[1]] or {}) do
            local c = FJ.Caught(e.item)
            out[#out + 1] = string.format("%s (ab %s)%s", name(e.item), tostring(e.skill or "?"), c and (" – " .. c .. " geplündert") or "")
        end
        out[#out + 1] = ""
    end
    return out
end

function FJ.RepReport()
    local out = { "Ruf-Belohnungen (Wissensstand der Community, für Forever unbestätigt)", "" }
    local ids = {}
    for fid in pairs(R().factions) do ids[#ids + 1] = fid end
    table.sort(ids)
    for _, fid in ipairs(ids) do
        local f = R().factions[fid]
        local cur
        local cr = _G.C_Reputation
        if cr and cr.GetFactionDataByID then
            local ok, d = pcall(cr.GetFactionDataByID, fid)
            cur = ok and type(d) == "table" and K.Plain(d.reaction)
        end
        out[#out + 1] = "== " .. FJ.FactionName(fid) .. (type(cur) == "number" and (" – du: " .. (FJ.STANDING[cur] or cur)) or "")
            .. (f.qm and (" · Rüstmeister " .. f.qm[1]) or "")
        for _, tier in ipairs(f.tiers) do
            local names = {}
            for _, item in ipairs(tier[2]) do
                local n = _G.C_Item and _G.C_Item.GetItemNameByID and _G.C_Item.GetItemNameByID(item)
                names[#names + 1] = (type(n) == "string" and n or ("#" .. item)) .. (f.prices[item] and (" " .. Money(f.prices[item])) or "")
            end
            out[#out + 1] = "  " .. (FJ.STANDING[tier[1]] or tier[1]) .. ": " .. table.concat(names, ", ")
        end
    end
    return out
end

function FJ.Enable()
    if FJ.enabled then return end
    FJ.enabled = true
    local tdp, e = _G.TooltipDataProcessor, _G.Enum and _G.Enum.TooltipDataType
    if tdp and tdp.AddTooltipPostCall and e and e.Item then
        pcall(tdp.AddTooltipPostCall, e.Item, K.Measured("Feldbuch", OnItem))
    elseif _G.GameTooltip and _G.GameTooltip.HookScript then
        _G.GameTooltip:HookScript("OnTooltipSetItem", function(self) OnItem(self) end)
    end
    local ev = CreateFrame("Frame")
    pcall(ev.RegisterEvent, ev, "LOOT_READY")
    ev:SetScript("OnEvent", K.Measured("Feldbuch", OnLoot))
end

do
    local m = K.Module("comfort")
    if m then
        local enable = m.Enable
        m.Enable = function(...)
            if enable then enable(...) end
            local ok, err = pcall(FJ.Enable)
            if not ok then K.Report("feldbuch", err) end
        end
    end
end
