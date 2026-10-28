--------------------------------------------------
-- WeintCodex :: Wer wuerfelt worauf (Komfort, Seite "Anzeigen", 1.6.0.0)
--------------------------------------------------
-- Wunsch aus der Gilde: "ein Addon, da konnte man sehen, wer in der
-- Instanz auf was gewuerfelt hat - einfacher, um auf Second Gear zu
-- wuerfeln, ohne jedes Mal zu fragen". Nur in Dungeons (Instanzart
-- "party"), im Schlachtzug wuerfelt man ohnehin anders.
--
-- QUELLE: die Beutezeilen im Chat (CHAT_MSG_LOOT). Das Spiel schreibt
-- dort jede Wahl ("… wählt Bedarf für: …"), jeden Wurf und den Gewinner.
-- Die Muster entstehen beim Laden aus den Texten des Spiels selbst
-- (LOOT_ROLL_NEED, LOOT_ROLL_ROLLED_NEED, LOOT_ROLL_WON, …) - darum
-- passen sie in jeder Sprache des Clients, und WeintCodex errät keinen
-- Satz. Fehlt ein Text im Client, fehlt nur dieses Muster.
--
-- Eine Zeile, die der Client geheim haelt (12.x, im Kampf), wird nicht
-- gelesen - die Wahl erscheint dann nicht, statt falsch.
--
-- Ein Gegenstand beginnt mit START_LOOT_ROLL (Link vom Client) oder mit
-- der ersten Chatzeile, die ihn nennt. Gezeigt werden die letzten
-- ROWS Gegenstaende; 30 s nach dem letzten Gewinner geht das Fenster zu.
--------------------------------------------------

local K = WeintCodex.UIKit
local C = WeintCodex.Colors
local KEY = "comfort"

WeintCodex.UIRollWatch = {}
local RW = WeintCodex.UIRollWatch

RW.DEFAULTS = { rollWatch = true }
RW.ROWS = 4
RW.LINGER = 30
RW.W, RW.ROW_H = 300, 46

-- Art der Wahl -> Beschriftung und Reihenfolge
RW.KINDS = {
    need     = { label = "Bedarf",   order = 1, color = "green" },
    greed    = { label = "Gier",     order = 2, color = "gold" },
    de       = { label = "Entzaubern", order = 3, color = "blue" },
    transmog = { label = "Transmog", order = 4, color = "blue" },
    pass     = { label = "Passen",   order = 5, color = "textMuted" },
}

-- Texte des Spiels: Name -> { Art, Rollen der Platzhalter }
-- who = Spieler, item = Gegenstand, roll = Zahl
RW.STRINGS = {
    { "LOOT_ROLL_NEED",            "need",     { "who", "item" } },
    { "LOOT_ROLL_GREED",           "greed",    { "who", "item" } },
    { "LOOT_ROLL_DISENCHANT",      "de",       { "who", "item" } },
    { "LOOT_ROLL_TRANSMOG",        "transmog", { "who", "item" } },
    { "LOOT_ROLL_PASSED",          "pass",     { "who", "item" } },
    { "LOOT_ROLL_PASSED_AUTO",     "pass",     { "who", "item" } },
    { "LOOT_ROLL_PASSED_AUTO_FEMALE", "pass",  { "who", "item" } },
    { "LOOT_ROLL_NEED_SELF",       "need",     { "item" }, self = true },
    { "LOOT_ROLL_GREED_SELF",      "greed",    { "item" }, self = true },
    { "LOOT_ROLL_DISENCHANT_SELF", "de",       { "item" }, self = true },
    { "LOOT_ROLL_TRANSMOG_SELF",   "transmog", { "item" }, self = true },
    { "LOOT_ROLL_PASSED_SELF",     "pass",     { "item" }, self = true },
    { "LOOT_ROLL_PASSED_SELF_AUTO", "pass",    { "item" }, self = true },
    { "LOOT_ROLL_ROLLED_NEED",     "need",     { "roll", "item", "who" }, rolled = true },
    { "LOOT_ROLL_ROLLED_NEED_ROLE_BONUS", "need", { "roll", "item", "who" }, rolled = true },
    { "LOOT_ROLL_ROLLED_GREED",    "greed",    { "roll", "item", "who" }, rolled = true },
    { "LOOT_ROLL_ROLLED_DE",       "de",       { "roll", "item", "who" }, rolled = true },
    { "LOOT_ROLL_ROLLED_TRANSMOG", "transmog", { "roll", "item", "who" }, rolled = true },
    { "LOOT_ROLL_WON",             "won",      { "who", "item" } },
    { "LOOT_ROLL_YOU_WON",         "won",      { "item" }, self = true },
    { "LOOT_ROLL_ALL_PASSED",      "allpass",  { "item" } },
}

-- Formatstring des Spiels -> Lua-Muster und Reihenfolge der Fangstellen.
-- "%s"/"%d" der Reihe nach, "%2$s" an seiner Stelle.
function RW.Pattern(fmt, roles)
    if type(fmt) ~= "string" or fmt == "" then return nil end
    local order, n = {}, 0
    local marked = fmt:gsub("%%(%d?)%$?([sd])", function(pos, kind)
        n = n + 1
        order[#order + 1] = roles[tonumber(pos) or n]
        return "\001" .. kind
    end)
    if n == 0 then return nil end
    local pat = marked:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
    pat = pat:gsub("\001s", "(.-)"):gsub("\001d", "(%%d+)")
    return "^" .. pat .. "$", order
end

RW.patterns = {}
function RW.BuildPatterns()
    wipe(RW.patterns)
    for _, s in ipairs(RW.STRINGS) do
        local pat, order = RW.Pattern(_G[s[1]], s[3])
        if pat then
            RW.patterns[#RW.patterns + 1] = { pat = pat, order = order, kind = s[2], self = s.self, rolled = s.rolled }
        end
    end
    -- Laengere Muster zuerst: "Bedarfswurf (%d) für …" vor "… für: %s".
    table.sort(RW.patterns, function(a, b) return #a.pat > #b.pat end)
end

-- Eine Chatzeile -> Art, Spieler, Gegenstand, Wurf (oder nil).
function RW.Parse(msg)
    if type(msg) ~= "string" then return nil end
    for _, p in ipairs(RW.patterns) do
        local c = { msg:match(p.pat) }
        if c[1] then
            local out = { kind = p.kind, rolled = p.rolled }
            for i, role in ipairs(p.order) do out[role] = c[i] end
            if p.self then out.who = (_G.UnitName and K.Plain(_G.UnitName("player"))) or "Du" end
            if out.roll then out.roll = tonumber(out.roll) end
            if out.item and out.who then return out end
            if out.item and (p.kind == "allpass") then return out end
        end
    end
    return nil
end

--------------------------------------------------
-- Stand
--------------------------------------------------

RW.items = {}           -- { link, name, icon, picks = { [who] = { kind, roll } }, winner, t }

local function Now() return (_G.GetTime and _G.GetTime()) or 0 end

local function ItemKey(link)
    return type(link) == "string" and (link:match("|H(item:[^|]+)|h") or link) or nil
end

function RW.Item(link)
    local key = ItemKey(link)
    if not key then return nil end
    for _, it in ipairs(RW.items) do
        if it.key == key and not it.winner then return it end
    end
    local it = { key = key, link = link, picks = {}, order = {}, t = Now() }
    if _G.C_Item and _G.C_Item.GetItemIconByID then
        local ok, icon = pcall(_G.C_Item.GetItemIconByID, link)
        it.icon = ok and icon or nil
    end
    table.insert(RW.items, 1, it)
    while #RW.items > RW.ROWS do table.remove(RW.items) end
    return it
end

function RW.Apply(info)
    local it = RW.Item(info.item)
    if not it then return end
    it.t = Now()
    if info.kind == "won" then
        it.winner = info.who
    elseif info.kind == "allpass" then
        it.winner = false
    else
        local p = it.picks[info.who]
        if not p then
            p = {}
            it.picks[info.who] = p
            it.order[#it.order + 1] = info.who
        end
        p.kind = info.kind
        if info.roll then p.roll = info.roll end
    end
    RW.lastChange = Now()
end

-- "Bedarf: Lena 87, Bruni · Gier: Ole" - nach Art, innerhalb nach Wurf.
function RW.Summary(it)
    local by = {}
    for _, who in ipairs(it.order) do
        local p = it.picks[who]
        local list = by[p.kind] or {}
        by[p.kind] = list
        list[#list + 1] = { who = who, roll = p.roll }
    end
    local kinds = {}
    for kind in pairs(by) do kinds[#kinds + 1] = kind end
    table.sort(kinds, function(a, b) return RW.KINDS[a].order < RW.KINDS[b].order end)
    local parts = {}
    for _, kind in ipairs(kinds) do
        local list = by[kind]
        table.sort(list, function(a, b) return (a.roll or -1) > (b.roll or -1) end)
        local names = {}
        for _, e in ipairs(list) do
            names[#names + 1] = e.who .. (e.roll and (" " .. e.roll) or "")
        end
        parts[#parts + 1] = WeintCodex.ColorText(RW.KINDS[kind].color, RW.KINDS[kind].label .. ":") .. " " .. table.concat(names, ", ")
    end
    if #parts == 0 then return "Noch keine Wahl" end
    return table.concat(parts, "  ·  ")
end

--------------------------------------------------
-- Anzeige
--------------------------------------------------

local frame
local function Build()
    if frame then return frame end
    frame = CreateFrame("Frame", "WeintCodexRollWatch", UIParent)
    frame:SetSize(RW.W, 24 + RW.ROWS * RW.ROW_H)
    frame:SetFrameStrata("MEDIUM")
    frame.kachel = K.Kachel(frame, { shadow = 4 })
    frame.head = K.NewText(frame, 12, "OVERLAY")
    frame.head:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -7)
    frame.head:SetText("Würfe in der Gruppe")
    frame.rows = {}
    for i = 1, RW.ROWS do
        local r = CreateFrame("Frame", nil, frame)
        r:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -24 - (i - 1) * RW.ROW_H)
        r:SetPoint("RIGHT", frame, "RIGHT", -8, 0)
        r:SetHeight(RW.ROW_H - 4)
        r.icon = r:CreateTexture(nil, "ARTWORK")
        r.icon:SetSize(26, 26)
        r.icon:SetPoint("TOPLEFT", r, "TOPLEFT", 0, -2)
        r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        r.name = K.NewText(r, 11, "OVERLAY")
        r.name:SetPoint("TOPLEFT", r.icon, "TOPRIGHT", 6, 0)
        r.name:SetPoint("RIGHT", r, "RIGHT", 0, 0)
        r.name:SetJustifyH("LEFT")
        r.name:SetWordWrap(false)
        r.picks = K.NewText(r, 10, "OVERLAY")
        r.picks:SetPoint("TOPLEFT", r.name, "BOTTOMLEFT", 0, -2)
        r.picks:SetPoint("RIGHT", r, "RIGHT", 0, 0)
        r.picks:SetJustifyH("LEFT")
        r.picks:SetJustifyV("TOP")
        r.picks:SetHeight(26)
        frame.rows[i] = r
    end
    frame:Hide()
    frame.WCShowForUnlock = function(self, on)
        self._unlock = on and true or nil
        if on then
            RW.Fill({ { link = "Erbstück der Gruppe", picks = { Lena = { kind = "need", roll = 87 }, Ole = { kind = "greed" } },
                        order = { "Lena", "Ole" } } })
            self:Show()
        else
            RW.Refresh()
        end
    end
    frame:SetScript("OnUpdate", function(self, el)
        self._acc = (self._acc or 0) + (el or 0)
        if self._acc < 1 then return end
        self._acc = 0
        if not self._unlock and RW.lastChange and Now() - RW.lastChange > RW.LINGER then self:Hide() end
    end)
    K.RegisterMover(frame, "rollwatch", "Würfe in der Gruppe", K.Layout("rollwatch"))
    RW.frame = frame
    return frame
end

function RW.Fill(items)
    local f = Build()
    local shown = 0
    for i, r in ipairs(f.rows) do
        local it = items[i]
        if it then
            shown = i
            r.icon:SetTexture(it.icon or 134400)
            local text = it.link or "?"
            if it.winner then
                text = text .. "  " .. WeintCodex.ColorText("green", "→ " .. it.winner)
            elseif it.winner == false then
                text = text .. "  " .. WeintCodex.ColorText("textMuted", "alle gepasst")
            end
            r.name:SetText(text)
            r.picks:SetText(RW.Summary(it))
            r:Show()
        else
            r:Hide()
        end
    end
    f:SetHeight(24 + math.max(shown, 1) * RW.ROW_H)
end

function RW.On() return K.IsActive(KEY) and K.Get(KEY, "rollWatch") and true or false end

function RW.InDungeon()
    if not _G.IsInInstance then return false end
    local _, kind = _G.IsInInstance()
    return K.Plain(kind) == "party"
end

function RW.Refresh()
    if not frame or frame._unlock then return end
    if #RW.items == 0 then frame:Hide() return end
    RW.Fill(RW.items)
end

local ev = CreateFrame("Frame")
pcall(ev.RegisterEvent, ev, "CHAT_MSG_LOOT")
pcall(ev.RegisterEvent, ev, "START_LOOT_ROLL")
pcall(ev.RegisterEvent, ev, "PLAYER_LOGIN")
pcall(ev.RegisterEvent, ev, "PLAYER_ENTERING_WORLD")
ev:SetScript("OnEvent", function(_, event, a1)
    if event == "PLAYER_LOGIN" then RW.BuildPatterns() return end
    if event == "PLAYER_ENTERING_WORLD" then
        wipe(RW.items)
        if frame and not frame._unlock then frame:Hide() end
        return
    end
    if not RW.On() or not RW.InDungeon() then return end
    if event == "START_LOOT_ROLL" then
        local link = _G.GetLootRollItemLink and K.Plain(_G.GetLootRollItemLink(a1))
        if type(link) ~= "string" then return end
        RW.Item(link)
        RW.lastChange = Now()
    else
        local msg = K.Plain(a1)
        local info = RW.Parse(msg)
        if not info then return end
        RW.Apply(info)
    end
    Build():Show()
    RW.Refresh()
end)
RW.ev = ev

local mod = K.Module(KEY)
if mod then
    for k, v in pairs(RW.DEFAULTS) do
        if mod.defaults[k] == nil then mod.defaults[k] = v end
    end
end
