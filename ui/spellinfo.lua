--------------------------------------------------
-- WeintCodex :: Komfort - Manaeffizienz im Zauber-Tooltip (6.39.0.0)
--------------------------------------------------
-- Wunsch aus dem Forum: "Heilung/Schaden je Mana und je Sekunde - gerade
-- fuer niedrigere Ränge eines Heilzaubers". Unter den Tooltip eines
-- Zaubers kommt eine Zeile:
--   Heilung je Mana 2,4 · je Sekunde 38
-- Nur aus dem, was der Client sagt:
--   * Menge: die Zahlen im Tooltip selbst ("47 bis 58" -> Mittel 52,5);
--     bei Wirkung ueber Zeit ("ueber 15 Sek.") je Sekunde der Wirkung;
--   * Kosten: GetSpellPowerCost, nur Mana;
--   * Zeit: Zauberzeit des Clients, sofort = globale Abklingzeit 1,5 s.
-- Steht keine Zahl im Text oder kostet der Zauber kein Mana: keine Zeile,
-- nie eine geratene. Kritische Treffer, Talente und Zaubermacht zaehlen
-- nur, soweit der Tooltip sie schon einrechnet.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UISpellInfo = {}

local SI = WeintCodex.UISpellInfo
local K  = WeintCodex.UIKit
local C  = WeintCodex.Colors
local KEY = "comfort"

SI.GCD = 1.5

-- Je Tooltip der Zauber, dessen Zeile schon steht (nicht als Feld am
-- Tooltip: das gehoert dem Spiel).
local shown = setmetatable({}, { __mode = "k" })
SI.shown = shown

function SI.Active()
    return K.IsActive(KEY) and K.Get(KEY, "spellEfficiency") ~= false
end

local function Num(s)
    return tonumber((s:gsub("%.", ""):gsub(",", ".")))
end

-- Text des Tooltips -> { amount, kind = "heal"|"damage", over = Sekunden }
-- oder nil.
function SI.Parse(text)
    if type(text) ~= "string" or text == "" then return nil end
    local low = text:lower()
    local kind
    if low:find("schaden", 1, true) or low:find("damage", 1, true) then kind = "damage"
    elseif low:find("heil", 1, true) or low:find("gesundheit", 1, true) or low:find("heal", 1, true)
        or low:find("health", 1, true) then kind = "heal" end
    if not kind then return nil end
    local a, b = low:match("(%d[%d%.]*)%s*bis%s*(%d[%d%.]*)")
    if not a then a, b = low:match("(%d[%d%.]*)%s*to%s*(%d[%d%.]*)") end
    local amount
    if a then
        amount = (Num(a) + Num(b)) / 2
    else
        local one = low:match("(%d[%d%.]*)%s+[%a\128-\255]*%s*schaden")
            or low:match("(%d[%d%.]*)%s+[%a\128-\255]*%s*damage")
            or low:match("um%s+(%d[%d%.]*)")
            or low:match("(%d[%d%.]*)%s+gesundheit")
            or low:match("for%s+(%d[%d%.]*)")
            or low:match("(%d[%d%.]*)%s+health")
        amount = one and Num(one)
    end
    if not amount or amount <= 0 then return nil end
    local over = low:match("über%s+(%d+[,%.]?%d*)%s*sek") or low:match("over%s+(%d+[,%.]?%d*)%s*sec")
    return { amount = amount, kind = kind, over = over and Num(over) or nil }
end

function SI.ManaCost(id)
    local f = (_G.C_Spell and _G.C_Spell.GetSpellPowerCost) or _G.GetSpellPowerCost
    if not f then return nil end
    local ok, list = pcall(f, id)
    if not ok or type(list) ~= "table" then return nil end
    for _, c in ipairs(list) do
        local t, cost = K.Plain(c.type), K.Plain(c.cost)
        if t == 0 and type(cost) == "number" and cost > 0 then return cost end
    end
    return nil
end

function SI.CastTime(id)
    local cs = _G.C_Spell
    local ms
    if cs and cs.GetSpellInfo then
        local ok, info = pcall(cs.GetSpellInfo, id)
        if ok and type(info) == "table" then ms = K.Plain(info.castTime) end
    elseif _G.GetSpellInfo then
        local ok, _, _, _, t = pcall(_G.GetSpellInfo, id)
        if ok then ms = K.Plain(t) end
    end
    if type(ms) ~= "number" then return nil end
    return math.max(SI.GCD, ms / 1000)
end

local function Fmt(v)
    local s = v >= 10 and string.format("%d", math.floor(v + 0.5)) or string.format("%.1f", v)
    return (s:gsub("%.", ","))
end

-- Die Zeile, oder nil.
function SI.Line(id, text)
    local p = SI.Parse(text)
    if not p then return nil end
    local cost = SI.ManaCost(id)
    if not cost then return nil end
    local cast = SI.CastTime(id)
    local what = p.kind == "heal" and "Heilung" or "Schaden"
    local parts = { string.format("%s je Mana %s", what, Fmt(p.amount / cost)) }
    if p.over and p.over > 0 then
        parts[#parts + 1] = string.format("je Sek. Wirkung %s", Fmt(p.amount / p.over))
    elseif cast then
        parts[#parts + 1] = string.format("je Sek. %s", Fmt(p.amount / cast))
    end
    if cast and not p.over then
        parts[#parts + 1] = string.format("Mana je Sek. %s", Fmt(cost / cast))
    end
    return table.concat(parts, " · ")
end

-- Beschreibung aus dem Tooltip: alle linken Zeilen ab der dritten.
local function TipText(tt)
    local name = tt.GetName and tt:GetName()
    if not name then return nil end
    local parts = {}
    for i = 2, tt:NumLines() do
        local fs = _G[name .. "TextLeft" .. i]
        local t = fs and K.Plain(fs:GetText())
        if type(t) == "string" then parts[#parts + 1] = t end
    end
    return table.concat(parts, " ")
end

function SI.OnSpell(tt, id)
    if not SI.Active() or type(id) ~= "number" then return end
    if shown[tt] == id then return end
    local line = SI.Line(id, TipText(tt))
    if not line then return end
    shown[tt] = id
    local m = C.textMuted
    tt:AddLine(line, m[1], m[2], m[3], true)
    tt:Show()
end

local function Hook()
    local TDP = _G.TooltipDataProcessor
    local E = _G.Enum and _G.Enum.TooltipDataType
    if TDP and TDP.AddTooltipPostCall and E and E.Spell then
        TDP.AddTooltipPostCall(E.Spell, function(tt, data)
            if tt ~= _G.GameTooltip then return end
            local id = data and K.Plain(data.id)
            pcall(SI.OnSpell, tt, id)
        end)
    elseif _G.GameTooltip and _G.GameTooltip.HookScript then
        _G.GameTooltip:HookScript("OnTooltipSetSpell", function(tt)
            local ok, _, id = pcall(tt.GetSpell, tt)
            if ok then pcall(SI.OnSpell, tt, K.Plain(id)) end
        end)
    end
    if _G.GameTooltip and _G.GameTooltip.HookScript then
        _G.GameTooltip:HookScript("OnTooltipCleared", function(tt) shown[tt] = nil end)
    end
end
Hook()

local mod = K.Module(KEY)
if mod then
    if mod.defaults.spellEfficiency == nil then mod.defaults.spellEfficiency = true end
end
