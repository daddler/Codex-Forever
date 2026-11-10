--------------------------------------------------
-- WeintCodex :: Neuer Rang, alter in der Leiste (1.10.28.0)
--------------------------------------------------
-- Wunsch: "Wenn ich einen neuen Rang gelernt habe, aber in der Leiste noch
-- den niedrigeren habe, moechte ich eine Erinnerung. Manche wollen genau
-- das (sparsamer) - also ein Verstanden direkt an der Erinnerung."
--
-- WIE: ausserhalb des Kampfes, nach dem Lernen und wenn sich die Leisten
-- aendern. Je Platz der Aktionsleisten (1..120) mit einem Zauber: Rang des
-- Zaubers (Untertext "Rang 4" vom Client) gegen den hoechsten Rang, den der
-- Client unter demselben Namen nennt. Sagt der Client einen der beiden
-- Raenge nicht, gilt der Platz als unbekannt - nie als veraltet.
--
-- DREI KNOEPFE:
--   Ersetzen   legt den hoechsten Rang auf genau diese Plaetze (nur
--              ausserhalb des Kampfes; geht das nicht, sagt es das).
--   Verstanden diesen Rang in der Leiste behalten - je Charakter gemerkt
--              (SavedData.rankKeep[Charakter][Zauber-ID]), kommt nie wieder.
--   Spaeter    bis zum naechsten gelernten Zauber nicht mehr fragen.
--------------------------------------------------

local K = WeintCodex.UIKit
local C = WeintCodex.Colors
local KEY = "comfort"

WeintCodex.UIRankCheck = {}
local RC = WeintCodex.UIRankCheck

RC.DEFAULTS = { rankCheck = true }
RC.SLOTS = 120
RC.MAX_LINES = 5
RC.W = 360
RC.DELAY = 1

local function Plain(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b = pcall(fn, ...)
    if not ok then return nil end
    return K.Plain(a), K.Plain(b)
end

function RC.Active() return K.IsActive(KEY) and K.Get(KEY, "rankCheck") and true or false end

local function InCombat() return _G.InCombatLockdown and K.Bool(_G.InCombatLockdown(), true) or false end

function RC.NameOf(id)
    local cs = _G.C_Spell
    local n = cs and Plain(cs.GetSpellName, id)
    if type(n) ~= "string" or n == "" then n = Plain(_G.GetSpellInfo, id) end
    return (type(n) == "string" and n ~= "") and n or nil
end

-- "Rang 4" / "Rank 4" -> 4; sonst nil.
function RC.RankOf(id)
    local cs = _G.C_Spell
    local sub = cs and Plain(cs.GetSpellSubtext, id)
    if type(sub) ~= "string" then sub = Plain(_G.GetSpellSubtext, id) end
    if type(sub) ~= "string" then return nil end
    return tonumber(sub:match("(%d+)"))
end

-- Hoechster Rang unter diesem Namen, den der Charakter kann.
function RC.BestId(name)
    local cs = _G.C_Spell
    if cs and cs.GetSpellInfo then
        local ok, info = pcall(cs.GetSpellInfo, name)
        local id = ok and type(info) == "table" and K.Plain(info.spellID)
        if type(id) == "number" then return id end
    end
    if _G.GetSpellInfo then
        local ok, _, _, _, _, _, _, id = pcall(_G.GetSpellInfo, name)
        id = ok and K.Plain(id)
        if type(id) == "number" then return id end
    end
    return nil
end

function RC.Keep()
    local sd = WeintCodex.SavedData
    if type(sd) ~= "table" then return nil end
    sd.rankKeep = sd.rankKeep or {}
    local me = (K.CharKey and K.CharKey()) or "?"
    sd.rankKeep[me] = sd.rankKeep[me] or {}
    return sd.rankKeep[me]
end

-- Liste der veralteten Plaetze: { { slot, old, new, name, oldRank, newRank } }
function RC.Scan()
    local out = {}
    if not _G.GetActionInfo then return out end
    local keep = RC.Keep() or {}
    for slot = 1, RC.SLOTS do
        local kind, id = Plain(_G.GetActionInfo, slot)
        if kind == "spell" and type(id) == "number" and not keep[id] then
            local name = RC.NameOf(id)
            local best = name and RC.BestId(name)
            if best and best ~= id then
                local have, can = RC.RankOf(id), RC.RankOf(best)
                if have and can and can > have then
                    out[#out + 1] = { slot = slot, old = id, new = best, name = name, oldRank = have, newRank = can }
                end
            end
        end
    end
    return out
end

--------------------------------------------------
-- Fenster
--------------------------------------------------
local pop, current, later = nil, nil, false

local function Build()
    pop = CreateFrame("Frame", "WeintCodexRankCheck", UIParent)
    pop:SetWidth(RC.W)
    pop:SetPoint("TOP", UIParent, "TOP", 0, -320)   -- unter "Neues beim Lehrer"
    pop:SetFrameStrata("HIGH")
    pop:EnableMouse(true)
    K.Kachel(pop)
    pop.mark = pop:CreateTexture(nil, "ARTWORK")
    pop.mark:SetPoint("TOPLEFT", pop, "TOPLEFT", 0, 0)
    pop.mark:SetPoint("BOTTOMLEFT", pop, "BOTTOMLEFT", 0, 0)
    pop.mark:SetWidth(3)
    local a = C.accent
    pop.mark:SetColorTexture(a[1], a[2], a[3], 1)
    pop.title = K.NewText(pop, 14)
    pop.title:SetPoint("TOPLEFT", pop, "TOPLEFT", 16, -12)
    pop.title:SetTextColor(unpack(C.textBright))
    pop.title:SetText("Neuer Rang – in der Leiste steht noch der alte")
    pop.rows = {}
    for i = 1, RC.MAX_LINES do
        local l = K.NewText(pop, 11)
        l:SetJustifyH("LEFT")
        l:SetWidth(RC.W - 32)
        if l.SetWordWrap then l:SetWordWrap(false) end
        l:SetPoint("TOPLEFT", pop, "TOPLEFT", 16, -36 - (i - 1) * 16)
        pop.rows[i] = l
    end
    pop.more = K.NewText(pop, 10)
    pop.more:SetTextColor(unpack(C.textDim))
    pop.fix = WeintCodex.CreateButton(pop, { text = "Ersetzen", kind = "primary", height = 26, size = 11,
        onClick = function() RC.Replace() end })
    pop.keep = WeintCodex.CreateButton(pop, { text = "Verstanden – so lassen", height = 26, size = 11,
        onClick = function() RC.KeepAll() end })
    pop.later = WeintCodex.CreateButton(pop, { text = "Später", height = 26, size = 11,
        onClick = function() later = true pop:Hide() end })
    pop:Hide()
    RC.popup = pop
end

function RC.Show(list)
    if not (list and #list > 0) then
        if pop then pop:Hide() end
        return false
    end
    if not pop then Build() end
    current = list
    local n = math.min(#list, RC.MAX_LINES)
    for i = 1, RC.MAX_LINES do
        local e = list[i]
        if i <= n then
            pop.rows[i]:SetText(string.format("%s: Rang %d in der Leiste, du kannst Rang %d", e.name, e.oldRank, e.newRank))
            pop.rows[i]:Show()
        else
            pop.rows[i]:Hide()
        end
    end
    local y = -36 - n * 16 - 4
    if #list > n then
        pop.more:SetText("… und " .. (#list - n) .. " weitere")
        pop.more:ClearAllPoints()
        pop.more:SetPoint("TOPLEFT", pop, "TOPLEFT", 16, y)
        pop.more:Show()
        y = y - 16
    else
        pop.more:Hide()
    end
    pop.fix:ClearAllPoints()
    pop.fix:SetPoint("TOPLEFT", pop, "TOPLEFT", 16, y - 6)
    pop.keep:ClearAllPoints()
    pop.keep:SetPoint("LEFT", pop.fix, "RIGHT", 8, 0)
    pop.later:ClearAllPoints()
    pop.later:SetPoint("LEFT", pop.keep, "RIGHT", 8, 0)
    pop:SetHeight(-y + 6 + 26 + 14)
    pop:Show()
    return true
end

-- Behalten: diese Raenge in der Leiste sind gewollt.
function RC.KeepAll()
    local keep = RC.Keep()
    if keep and current then
        for _, e in ipairs(current) do keep[e.old] = true end
    end
    if pop then pop:Hide() end
    current = nil
end

-- Hoechsten Rang auf die Plaetze legen (nur ausserhalb des Kampfes).
function RC.Replace()
    if InCombat() then
        print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " Im Kampf lassen sich Leisten nicht ändern – nach dem Kampf noch einmal.")
        return 0
    end
    local pick = (_G.C_Spell and _G.C_Spell.PickupSpell) or _G.PickupSpell
    local n = 0
    for _, e in ipairs(current or {}) do
        if pick and _G.PlaceAction then
            local ok = pcall(pick, e.new) and pcall(_G.PlaceAction, e.slot)
            if _G.ClearCursor then pcall(_G.ClearCursor) end
            if ok then n = n + 1 end
        end
    end
    if pop then pop:Hide() end
    current = nil
    if n == 0 then
        print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " Das Spiel lässt WeintCodex die Leisten nicht ändern – zieh den neuen Rang bitte selbst aus dem Zauberbuch.")
    end
    RC.Queue()
    return n
end

function RC.Check()
    if not RC.Active() or InCombat() then return nil end
    if later then return nil end
    local list = RC.Scan()
    return RC.Show(list)
end

local queued = false
function RC.Queue()
    if queued then return end
    queued = true
    local function run() queued = false RC.Check() end
    if _G.C_Timer and _G.C_Timer.After then _G.C_Timer.After(RC.DELAY, run) else run() end
end

local ev = CreateFrame("Frame")
for _, e in ipairs({ "PLAYER_ENTERING_WORLD", "LEARNED_SPELL_IN_TAB", "SPELLS_CHANGED",
                     "ACTIONBAR_SLOT_CHANGED", "PLAYER_REGEN_ENABLED" }) do
    pcall(ev.RegisterEvent, ev, e)
end
ev:SetScript("OnEvent", WeintCodex.Measured("Ränge prüfen", function(_, event)
    -- Neu gelernt: "Spaeter" gilt nicht mehr.
    if event == "LEARNED_SPELL_IN_TAB" then later = false end
    RC.Queue()
end))
RC.ev = ev

local mod = K.Module(KEY)
if mod then
    for k, v in pairs(RC.DEFAULTS) do
        if mod.defaults[k] == nil then mod.defaults[k] = v end
    end
end
