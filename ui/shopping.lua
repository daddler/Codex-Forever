--------------------------------------------------
-- WeintCodex :: Einkaufsliste fuer Rezepte
--------------------------------------------------
-- 1.0.7.0 (Wunsch nach dem Vergleich mit Naowh Forever "Shopping List",
-- Verhalten nachgebaut, eigener Code). Auf der Berufsseite kommt ein Rezept
-- (so oft du es herstellen willst) auf die Liste; die Liste rechnet die
-- Reagenzien zusammen und zieht ab, was der Charakter hat (Taschen und
-- Bank, wie der Client es zaehlt). Gezeigt wird sie am Auktionshaus
-- (ui/auctionsell.lua, Ansicht "Einkaufsliste"), ein Klick sucht dort.
--
-- Gespeichert je Charakter (K.CharState().shop = { [Zauber] = Anzahl }),
-- nie in einer Ersatztabelle.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIShopping = {}

local SL = WeintCodex.UIShopping

local function K() return WeintCodex.UIKit end
local function Store()
    local k = K()
    local st = k and k.CharState and k.CharState()
    if not st then return nil end
    st.shop = st.shop or {}
    return st.shop
end

function SL.Count(spell)
    local s = Store()
    return s and s[spell] or 0
end
function SL.Add(spell, n)
    local s = Store()
    if not (s and type(spell) == "number") then return false end
    s[spell] = math.max(0, (s[spell] or 0) + (n or 1))
    if s[spell] == 0 then s[spell] = nil end
    return true
end
function SL.Clear(spell)
    local s = Store()
    if s then s[spell] = nil end
end

-- Rezept zu einer Zaubernummer (ueber alle Berufe).
function SL.Recipe(spell)
    local PRO = WeintCodex.Professions
    if not (PRO and PRO.SpellIndex and PRO.Recipes) then return nil end
    local key = PRO.SpellIndex()[spell]
    if not key then return nil end
    for _, r in ipairs(PRO.Recipes(key)) do
        if r.spell == spell then return r end
    end
    return nil
end

local function Have(id)
    local ci = _G.C_Item
    if ci and ci.GetItemCount then
        local ok, n = pcall(ci.GetItemCount, id, true)
        if ok and type(n) == "number" then return n end
    end
    return 0
end

-- { {id, need, have, missing}, ... } nach Fehlendem sortiert; dazu die
-- Rezepte { {spell, count, name} }.
function SL.Needs(have)
    have = have or Have
    local s = Store() or {}
    local need, order, recipes = {}, {}, {}
    for spell, n in pairs(s) do
        local r = SL.Recipe(spell)
        recipes[#recipes + 1] = { spell = spell, count = n, name = r and r.name or ("Rezept " .. spell) }
        for _, e in ipairs(r and r.reagents or {}) do
            if not need[e[1]] then need[e[1]] = 0 order[#order + 1] = e[1] end
            need[e[1]] = need[e[1]] + e[2] * n
        end
    end
    local out = {}
    for _, id in ipairs(order) do
        local h = have(id)
        out[#out + 1] = { id = id, need = need[id], have = h, missing = math.max(0, need[id] - h) }
    end
    table.sort(out, function(a, b)
        if a.missing ~= b.missing then return a.missing > b.missing end
        return a.id < b.id
    end)
    table.sort(recipes, function(a, b) return a.spell < b.spell end)
    return out, recipes
end
