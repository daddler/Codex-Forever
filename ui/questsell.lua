--------------------------------------------------
-- WeintCodex :: Komfort - Questgegenstand verkauft? (1.0.5.3)
--------------------------------------------------
-- Wunsch: "Wenn jemand einen Questgegenstand versehentlich verkaufen will,
-- muss eine Meldung kommen, mit dem Hinweis, fuer welche Quest er wichtig
-- waere."
--
-- VORHER ANHALTEN GEHT NICHT SICHER: der Rechtsklick beim Haendler laeuft
-- durch geschuetzten Code des Spiels (ContainerFrameItemButton_OnClick ->
-- UseContainerItem). Ihn abzufangen hiesse, den Klick des Spiels zu
-- ersetzen - genau das brachte die Taschen mehrfach zu "Verboten:
-- UseContainerItem()". Deshalb DANACH: nach jedem Verkauf liest WeintCodex
-- die Rueckkaufliste des Haendlers (MERCHANT_UPDATE). Braucht eine Quest im
-- Questlog den zuletzt verkauften Gegenstand, erscheint ein Fenster mit der
-- Quest und einem Knopf "Zurueckkaufen" (BuybackItem - ohne Verlust, solange
-- der Haendler offen ist).
--
-- Welche Quest was braucht: der Questbestand (data/questdb.lua, Feld
-- "Gegenstand") fuer die Quests im Log, sonst die Ziele des Spiels
-- (C_QuestLog.GetQuestObjectives, Art "item", per Name). Nichts geraten:
-- weiss keiner davon etwas, kommt keine Meldung.
--------------------------------------------------

local K = WeintCodex.UIKit
local C = WeintCodex.Colors
local KEY = "comfort"

WeintCodex.UIQuestSell = {}
local QS = WeintCodex.UIQuestSell

QS.DEFAULTS = { questSellWarn = true }

function QS.Active() return K.IsActive(KEY) and K.Get(KEY, "questSellWarn") ~= false end

local function Plain(v) return K.Plain and K.Plain(v) or v end

local function ItemID(link)
    if type(link) ~= "string" then return nil end
    return tonumber(link:match("item:(%d+)"))
end

local function ItemName(link)
    return type(link) == "string" and link:match("%[(.-)%]") or nil
end

-- Quests im Log (ohne Kopfzeilen, nicht abgeschlossen): { {id, name} }.
function QS.LogQuests()
    local out = {}
    local ql = _G.C_QuestLog
    if not (ql and ql.GetNumQuestLogEntries and ql.GetInfo) then return out end
    local n = Plain(ql.GetNumQuestLogEntries())
    if type(n) ~= "number" then return out end
    for i = 1, n do
        local ok, info = pcall(ql.GetInfo, i)
        if ok and type(info) == "table" and not info.isHeader then
            local id = Plain(info.questID)
            local done = ql.IsComplete and Plain(ql.IsComplete(id)) == true
            if type(id) == "number" and not done then
                out[#out + 1] = { id = id, name = Plain(info.title) }
            end
        end
    end
    return out
end

-- Name des Gegenstands aus einem Questziel ("Große Geiferzahnschnauze: 1/5",
-- englisch auch "1/5 Name"). 1.0.5.5: vorher reichte ein Teil des Textes -
-- "Geiferzahnschnauze" meldete die Quest für "Große Geiferzahnschnauze".
function QS.ObjectiveName(text)
    if type(text) ~= "string" then return nil end
    local name = text:match("^%s*(.-)%s*:%s*%d+%s*/%s*%d+%s*$")
        or text:match("^%s*%d+%s*/%s*%d+%s+(.-)%s*$")
        or text:match("^%s*(.-)%s*$")
    return name
end

-- Welche Quests im Log brauchen diesen Gegenstand? Liste von Questnamen.
function QS.QuestsFor(itemID, itemName)
    local out = {}
    if type(itemID) ~= "number" then return out end
    local QH = WeintCodex.UIQuestHelper
    local ql = _G.C_QuestLog
    for _, q in ipairs(QS.LogQuests()) do
        local hit = false
        local rec = QH and QH.Quest and QH.Quest(q.id)
        if type(rec) == "table" and type(rec[12]) == "table" then
            for _, id in ipairs(rec[12]) do if id == itemID then hit = true break end end
        end
        if not hit and itemName and ql and ql.GetQuestObjectives then
            local ok, objs = pcall(ql.GetQuestObjectives, q.id)
            for _, o in ipairs(ok and type(objs) == "table" and objs or {}) do
                local text = Plain(o.text)
                if Plain(o.type) == "item" and QS.ObjectiveName(text) == itemName then
                    hit = true
                    break
                end
            end
        end
        if hit then out[#out + 1] = q.name or ("Quest " .. q.id) end
    end
    return out
end

--------------------------------------------------
-- Fenster
--------------------------------------------------

local win
local function Build()
    if win then return win end
    win = CreateFrame("Frame", "WeintCodexQuestSell", UIParent)
    win:SetSize(340, 120)
    win:SetPoint("TOP", UIParent, "TOP", 0, -160)
    win:SetFrameStrata("DIALOG")
    win:SetClampedToScreen(true)
    win:EnableMouse(true)
    win.kachel = K.Kachel(win, { shadow = 4 })
    win.head = K.NewText(win, 13, "OVERLAY")
    win.head:SetPoint("TOPLEFT", win, "TOPLEFT", 12, -10)
    win.head:SetPoint("RIGHT", win, "RIGHT", -12, 0)
    win.head:SetJustifyH("LEFT")
    win.head:SetTextColor(unpack(C.warningBright or C.textBright))
    win.body = K.NewText(win, 11, "OVERLAY")
    win.body:SetPoint("TOPLEFT", win.head, "BOTTOMLEFT", 0, -6)
    win.body:SetPoint("RIGHT", win, "RIGHT", -12, 0)
    win.body:SetJustifyH("LEFT")
    win.body:SetJustifyV("TOP")
    win.buy = WeintCodex.CreateButton(win, { text = "Zurückkaufen", kind = "primary", height = 24, size = 11,
        onClick = function() QS.Buyback() end })
    win.buy:SetWidth(130)
    win.buy:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", -10, 10)
    win.keep = WeintCodex.CreateButton(win, { text = "Verkauft lassen", kind = "secondary", height = 24, size = 11,
        onClick = function() win:Hide() end })
    win.keep:SetWidth(130)
    win.keep:SetPoint("RIGHT", win.buy, "LEFT", -8, 0)
    win:Hide()
    if type(_G.UISpecialFrames) == "table" then table.insert(_G.UISpecialFrames, "WeintCodexQuestSell") end
    QS.win = win
    return win
end

function QS.Show(link, quests)
    local w = Build()
    w.head:SetText("Questgegenstand verkauft: " .. (ItemName(link) or "?"))
    w.body:SetText("Wichtig für: " .. table.concat(quests, ", ")
        .. "\nWillst du ihn zurückkaufen? Das geht, solange der Händler offen ist.")
    w.link = link
    w:Show()
end

-- Den zuletzt verkauften Gegenstand zurueckkaufen (gleiche Stelle in der
-- Rueckkaufliste, und nur, wenn dort noch derselbe liegt).
function QS.Buyback()
    local w = win
    if not w then return false end
    w:Hide()
    local n = _G.GetNumBuybackItems and Plain(_G.GetNumBuybackItems())
    if type(n) ~= "number" or n < 1 or not _G.BuybackItem then return false end
    for i = n, 1, -1 do
        local link = _G.GetBuybackItemLink and Plain(_G.GetBuybackItemLink(i))
        if link and ItemID(link) == ItemID(w.link) then
            pcall(_G.BuybackItem, i)
            return true
        end
    end
    return false
end

--------------------------------------------------
-- Nach dem Verkauf
--------------------------------------------------

QS.lastCount = nil
function QS.Check()
    local n = _G.GetNumBuybackItems and Plain(_G.GetNumBuybackItems())
    if type(n) ~= "number" then return end
    local before = QS.lastCount
    QS.lastCount = n
    if not before or n <= before and not QS.changedTop(n) then return end
    if not QS.Active() then return end
    local link = _G.GetBuybackItemLink and Plain(_G.GetBuybackItemLink(n))
    local quests = QS.QuestsFor(ItemID(link), ItemName(link))
    if #quests > 0 then QS.Show(link, quests) end
end

-- Die Rueckkaufliste ist voll (12): die Zahl bleibt, der letzte Platz
-- wechselt. Dann zaehlt ein neuer Gegenstand dort.
QS.topLink = nil
function QS.changedTop(n)
    local link = _G.GetBuybackItemLink and Plain(_G.GetBuybackItemLink(n))
    local changed = link ~= nil and link ~= QS.topLink
    return changed
end

local ev = CreateFrame("Frame")
for _, e in ipairs({ "MERCHANT_SHOW", "MERCHANT_UPDATE", "MERCHANT_CLOSED" }) do pcall(ev.RegisterEvent, ev, e) end
ev:SetScript("OnEvent", function(_, event)
    if event == "MERCHANT_SHOW" then
        QS.lastCount = _G.GetNumBuybackItems and Plain(_G.GetNumBuybackItems()) or nil
        QS.topLink = QS.lastCount and _G.GetBuybackItemLink and Plain(_G.GetBuybackItemLink(QS.lastCount)) or nil
    elseif event == "MERCHANT_UPDATE" then
        pcall(QS.Check)
        local n = QS.lastCount
        QS.topLink = n and _G.GetBuybackItemLink and Plain(_G.GetBuybackItemLink(n)) or nil
    elseif event == "MERCHANT_CLOSED" then
        QS.lastCount, QS.topLink = nil, nil
        if win then win:Hide() end
    end
end)
QS.events = ev

local mod = K.Module(KEY)
if mod then
    if mod.defaults.questSellWarn == nil then mod.defaults.questSellWarn = true end
    local page = mod.pages and mod.pages[1]
    if page then
        local build = page.build
        page.build = function(B)
            build(B)
            B:Section("Händler")
            B:Row({ type = "toggle", label = "Warnung: Questgegenstand verkauft", key = "questSellWarn",
                    description = "Verkaufst du etwas, das eine Quest in deinem Log braucht, nennt ein Fenster die Quest und bietet „Zurückkaufen“ an." },
                  { type = "empty" })
        end
    end
end
