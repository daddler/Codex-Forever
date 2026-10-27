--------------------------------------------------
-- WeintCodex :: Gemütlicher Schlafsack - Stand der Questreihe (1.4.0.0)
--------------------------------------------------
-- Wunsch: "der Schlafsack mit sämtlichen Schritten und Markierungen", wie
-- im Discovery-Bereich von Naowh Forever (eigener Code). Bestand:
-- data/sleepingbag.lua. Gezeigt auf der Seite "Bücher" (modules/books.lua)
-- als eigener Eintrag der Unternavigation.
--
-- Was erledigt ist, sagt nur der Client. Antwortet er nicht, ist der Stand
-- unbekannt - nie "0 von 7".
--------------------------------------------------

WeintCodex.SleepingBag = {}
local SB = WeintCodex.SleepingBag

local function Plain(v)
    local K = WeintCodex.UIKit
    if K and K.Plain then return K.Plain(v) end
    return v
end

local function Data() return WeintCodex.SleepingBagData end

local function Side()
    if not _G.UnitFactionGroup then return nil end
    local ok, f = pcall(_G.UnitFactionGroup, "player")
    f = ok and Plain(f) or nil
    return (f == "Alliance" or f == "Horde") and f or nil
end

-- Schritte der eigenen Fraktion (ohne Fraktion: die der Allianz).
function SB.Steps()
    local d = Data()
    if not d then return {} end
    return d.steps[Side() or "Alliance"]
end

-- true / false / nil (Client antwortet nicht).
local function Flag(fn, quest)
    if type(fn) ~= "function" then return nil end
    local ok, v = pcall(fn, quest)
    if not ok then return nil end
    v = Plain(v)
    if type(v) ~= "boolean" then return nil end
    return v
end

function SB.StepDone(step)
    local ql = _G.C_QuestLog
    local done = Flag((ql and ql.IsQuestFlaggedCompleted) or _G.IsQuestFlaggedCompleted, step.started or step.done)
    if done == nil or done or not step.started then return done end
    local on = Flag(ql and ql.IsOnQuest, step.started)
    return on == true
end

-- { done = n, total = n, current = Index oder nil (alles erledigt) },
-- oder nil, wenn der Client nichts sagt.
function SB.Progress()
    local steps = SB.Steps()
    local done, current = 0, nil
    for i, st in ipairs(steps) do
        local v = SB.StepDone(st)
        if v == nil then return nil end
        if v then done = done + 1 elseif not current then current = i end
    end
    return { done = done, total = #steps, current = current }
end

-- Reicht die Stufe? nil: unbekannt.
function SB.LevelOk()
    local d = Data()
    local lvl = _G.UnitLevel and Plain(_G.UnitLevel("player"))
    if not d or type(lvl) ~= "number" then return nil end
    return lvl >= d.level
end

-- Gleicher Name an zwei Orten: der Ort gehört dazu.
function SB.Name(step)
    local LB = WeintCodex.Library
    for _, other in ipairs(SB.Steps()) do
        if other ~= step and other.object == step.object and other.map ~= step.map then
            local zone = LB and LB.ZoneName(step.map)
            return step.object .. " (" .. (zone or step.place) .. ")"
        end
    end
    return step.object
end

-- Questpfeil auf einen Schritt (nil: auf den aktuellen).
function SB.Guide(step)
    if not step then
        local p = SB.Progress()
        step = p and p.current and SB.Steps()[p.current]
    end
    local QA = WeintCodex.UIQuestArrow
    if not (step and QA and QA.SetCustom) then return false end
    QA.SetCustom({ map = step.map, x = step.x / 100, y = step.y / 100, title = "Schlafsack: " .. SB.Name(step),
        done = function() return SB.StepDone(step) == true end })
    return true
end
