--------------------------------------------------
-- WeintCodex :: Neues beim Lehrer nach dem Stufenaufstieg
--------------------------------------------------
-- Seit 6.26.7.0 (Beta-Test: "Wenn ich ein Level Up bekomme und neue Zauber
-- und Faehigkeiten lernen kann, soll WeintCodex ein Pop-up zeigen. Egal ob
-- mit UI oder ohne"). Komfort, Seite "Anzeigen", von Haus aus AN; geht
-- ohne Oberflaeche (Modul "comfort", group = "qol").
--
-- WOHER: dieselbe Rechnung wie die Seite "Lehrer" (modules/trainer.lua,
-- TR.Categorize) - Klasse, Rasse und Fraktion vom Client, gelernt fragt
-- den Client. Gezeigt wird nur, was JETZT lernbar ist; was davon mit
-- dieser Stufe neu ist, steht oben. Nichts lernbar: kein Fenster. Kennt
-- der Client Klasse oder Stufe nicht: kein Fenster, keine geratene Liste.
--
-- WANN: eine Sekunde nach PLAYER_LEVEL_UP (die Stufe kommt mit dem
-- Ereignis, UnitLevel zieht manchmal erst nach). Bleibt, bis man es
-- schliesst oder "Zum Lehrer" klickt - ein Hinweis, der von selbst
-- verschwindet, ist im Kampf nach dem Aufstieg verpasst.
--------------------------------------------------

local K = WeintCodex.UIKit
local C = WeintCodex.Colors
local KEY = "comfort"

WeintCodex.UILevelUp = {}
local LU = WeintCodex.UILevelUp

LU.DEFAULTS = { levelUpPopup = true }
LU.MAX_LINES = 6
LU.W = 340
LU.DELAY = 1

function LU.Active() return K.IsActive(KEY) and K.Get(KEY, "levelUpPopup") and true or false end

-- Was mit Stufe `level` beim Lehrer lernbar ist: { fresh = {..}, older = {..},
-- cost = Kupfer, weapons = n } oder nil, wenn der Client zu wenig sagt.
function LU.Learnable(level)
    local TR = WeintCodex.Trainer
    if not (TR and TR.PlayerState and TR.Categorize) then return nil end
    local state = TR.PlayerState()
    if type(level) == "number" then state.level = level end
    if not (state.class and state.level) then return nil end
    local cat = TR.Categorize(state)
    local out = { fresh = {}, older = {}, cost = cat.total.now or 0, weapons = 0, level = state.level }
    for _, sp in ipairs(cat.sections.now or {}) do
        if sp.level == state.level then out.fresh[#out.fresh + 1] = sp else out.older[#out.older + 1] = sp end
    end
    if TR.WeaponState then
        for _, w in ipairs(TR.WeaponState(state)) do
            if w.key == "now" and w.level == state.level then out.weapons = out.weapons + 1 end
        end
    end
    out.count = #out.fresh + #out.older
    return out
end

-- Zeilen fuer das Fenster: neue zuerst, dann was von frueher noch offen ist.
function LU.Lines(info)
    local TR = WeintCodex.Trainer
    local lines = {}
    local function add(sp, fresh)
        if #lines >= LU.MAX_LINES then return end
        local name, sub = TR.SpellInfo(sp.id)
        name = name or ("Zauber " .. sp.id)
        if sub then name = name .. " (" .. sub .. ")" end
        lines[#lines + 1] = { text = name, cost = TR.Money(sp.cost), fresh = fresh }
    end
    for _, sp in ipairs(info.fresh) do add(sp, true) end
    for _, sp in ipairs(info.older) do add(sp, false) end
    return lines
end

local pop

local function Build()
    pop = CreateFrame("Frame", "WeintCodexLevelUp", UIParent)
    pop:SetWidth(LU.W)
    pop:SetPoint("TOP", UIParent, "TOP", 0, -140)
    pop:SetFrameStrata("HIGH")
    pop:EnableMouse(true)
    K.Kachel(pop)
    pop.mark = pop:CreateTexture(nil, "ARTWORK")
    pop.mark:SetPoint("TOPLEFT", pop, "TOPLEFT", 0, 0)
    pop.mark:SetPoint("BOTTOMLEFT", pop, "BOTTOMLEFT", 0, 0)
    pop.mark:SetWidth(3)
    local s = C.successBright
    pop.mark:SetColorTexture(s[1], s[2], s[3], 1)
    pop.title = K.NewText(pop, 14)
    pop.title:SetPoint("TOPLEFT", pop, "TOPLEFT", 16, -12)
    pop.title:SetTextColor(unpack(C.textBright))
    pop.sub = K.NewText(pop, 11)
    pop.sub:SetPoint("TOPLEFT", pop.title, "BOTTOMLEFT", 0, -4)
    pop.sub:SetWidth(LU.W - 32)
    pop.sub:SetJustifyH("LEFT")
    pop.sub:SetTextColor(unpack(C.textMuted))
    pop.rows = {}
    for i = 1, LU.MAX_LINES do
        local l = K.NewText(pop, 11)
        l:SetJustifyH("LEFT")
        l:SetWidth(LU.W - 110)
        if l.SetWordWrap then l:SetWordWrap(false) end
        local r = K.NewText(pop, 11)
        r:SetJustifyH("RIGHT")
        r:SetTextColor(unpack(C.textMuted))
        pop.rows[i] = { l, r }
    end
    pop.more = K.NewText(pop, 10)
    pop.more:SetTextColor(unpack(C.textDim))
    pop.go = WeintCodex.CreateButton(pop, { text = "Zum Lehrer", kind = "primary", height = 26, size = 11,
        onClick = function() LU.OpenTrainer() end })
    pop.close = WeintCodex.CreateButton(pop, { text = "Schließen", height = 26, size = 11,
        onClick = function() pop:Hide() end })
    pop:Hide()
    LU.popup = pop
end

function LU.OpenTrainer()
    if pop then pop:Hide() end
    if WeintCodex.MainFrame and WeintCodex.Navigation and WeintCodex.Navigation.GoToTab then
        WeintCodex.MainFrame:Show()
        WeintCodex.Navigation.GoToTab("lehrer")
    end
end

-- Zeigt das Fenster fuer `info` (aus LU.Learnable). Gibt true zurueck,
-- wenn es etwas zu zeigen gab.
function LU.Show(info)
    if not (info and info.count and info.count > 0) then return false end
    if not pop then Build() end
    local TR = WeintCodex.Trainer
    pop.title:SetText("Stufe " .. info.level .. " – neu beim Lehrer")
    local parts = {}
    if #info.fresh > 0 then parts[#parts + 1] = #info.fresh .. " neu mit dieser Stufe" end
    if #info.older > 0 then parts[#parts + 1] = #info.older .. " von früher noch offen" end
    if info.weapons > 0 then parts[#parts + 1] = info.weapons .. " Waffenfertigkeit" .. (info.weapons > 1 and "en" or "") end
    local money = K.Plain(_G.GetMoney and _G.GetMoney())
    local bill = "Zusammen " .. TR.Money(info.cost)
    if type(money) == "number" then
        bill = bill .. (money >= info.cost and " – dein Gold reicht" or (" – es fehlen " .. TR.Money(info.cost - money)))
    end
    pop.sub:SetText(table.concat(parts, " · ") .. "\n" .. bill)
    local lines = LU.Lines(info)
    local y = 12 + 18 + 4 + 30 + 10
    local gb, gm = C.successBright, C.textNormal
    for i, row in ipairs(pop.rows) do
        local l = lines[i]
        local a, b = row[1], row[2]
        a:ClearAllPoints()
        b:ClearAllPoints()
        if l then
            a:SetPoint("TOPLEFT", pop, "TOPLEFT", 16, -y)
            b:SetPoint("TOPRIGHT", pop, "TOPRIGHT", -16, -y)
            a:SetText(l.text)
            local c = l.fresh and gb or gm
            a:SetTextColor(c[1], c[2], c[3])
            b:SetText(l.cost)
            a:Show() b:Show()
            y = y + 16
        else
            a:Hide() b:Hide()
        end
    end
    local rest = info.count - #lines
    pop.more:ClearAllPoints()
    if rest > 0 then
        pop.more:SetPoint("TOPLEFT", pop, "TOPLEFT", 16, -(y + 2))
        pop.more:SetText("… und " .. rest .. " weitere")
        pop.more:Show()
        y = y + 16
    else
        pop.more:Hide()
    end
    y = y + 10
    pop.go:ClearAllPoints()
    pop.go:SetPoint("TOPRIGHT", pop, "TOPRIGHT", -16, -y)
    pop.close:ClearAllPoints()
    pop.close:SetPoint("RIGHT", pop.go, "LEFT", -8, 0)
    pop:SetHeight(y + 26 + 14)
    pop:Show()
    LU.shown = info
    return true
end

-- Nach dem Aufstieg: rechnen, zeigen. Testbar ohne Zeitgeber.
function LU.OnLevelUp(level)
    if not LU.Active() then return false end
    local info = LU.Learnable(K.Plain(level))
    LU.last = info
    return LU.Show(info)
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LEVEL_UP")
ev:SetScript("OnEvent", function(_, _, level)
    if not LU.Active() then return end
    if _G.C_Timer and _G.C_Timer.After then
        _G.C_Timer.After(LU.DELAY, function() LU.OnLevelUp(level) end)
    else
        LU.OnLevelUp(level)
    end
end)
LU.events = ev

local mod = K.Module(KEY)
if mod then
    for k, v in pairs(LU.DEFAULTS) do
        if mod.defaults[k] == nil then mod.defaults[k] = v end
    end
end
