--------------------------------------------------
-- WeintCodex :: Komfort - Talentplaner
--------------------------------------------------
-- 1.0.7.0 (Wunsch nach dem Vergleich mit Naowh Forever "Builds":
-- "Talentbuilds - Stufe fuer Stufe planen, teilen und beim Leveln folgen").
-- Verhalten nachgebaut, eigener Code; die Baeume sind Daten aus dem Client
-- (data/talenttrees.lua, erzeugt). Naowhs eigene Builds sind NICHT dabei -
-- sie sind seine Arbeit, und WeintCodex schreibt keine Taktik vor.
--
-- PLANEN: /wcui talente oeffnet das Fenster: drei Baeume, Linksklick setzt
-- den naechsten Punkt (Stufe 10, 11, ... in dieser Reihenfolge), Rechtsklick
-- nimmt den letzten Punkt dieses Talents zurueck, wenn der Rest gueltig
-- bleibt. Regeln wie im Spiel: Raenge, 5 Punkte je Reihe im Baum,
-- Vorbedingung voll, hoechstens 51 Punkte.
-- SPEICHERN: je Konto und Klasse (WeintCodex_SavedData.talentBuilds),
-- mehrere Builds mit Namen. TEILEN: ein Text "WCTB1:KLASSE:Talent,Talent,..."
-- zum Kopieren und Einfuegen (nichts geht ins Netz).
-- FOLGEN: je Charakter ein Build; hast du freie Punkte, nennt ein Hinweis
-- das naechste Talent laut Plan (verteilte Punkte vom Client).
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UITalentBuilds = {}

local TB = WeintCodex.UITalentBuilds
local K = WeintCodex.UIKit
local C = WeintCodex.Colors

TB.MAX_POINTS, TB.ROW_POINTS, TB.FIRST_LEVEL = 51, 5, 10
TB.PREFIX = "WCTB1"
local SPELL, RANKS, ROW, TREE, COL, NEEDS = 1, 2, 3, 4, 5, 6

local function Class()
    if not _G.UnitClass then return nil end
    local _, c = _G.UnitClass("player")
    c = K.Plain(c)
    return type(c) == "string" and c or nil
end
function TB.Tree(class) return (WeintCodex.TalentTrees or {})[class or Class() or ""] end

-- nil, wenn die Reihenfolge gueltig ist, sonst der Grund (Text).
function TB.Check(class, points)
    local tree = TB.Tree(class)
    if not tree then return "Für diese Klasse gibt es keinen Talentbaum." end
    if #points > TB.MAX_POINTS then return "Mehr als " .. TB.MAX_POINTS .. " Punkte." end
    local count, spent = {}, {}
    for _, node in ipairs(points) do
        local t = tree[node]
        if not t then return "Unbekanntes Talent " .. tostring(node) .. "." end
        local rank = (count[node] or 0) + 1
        if rank > t[RANKS] then return "Schon auf höchstem Rang." end
        local need = t[NEEDS]
        if need and (count[need] or 0) < (tree[need] and tree[need][RANKS] or 1) then
            return "Erst das Talent darüber voll ausbauen."
        end
        if (spent[t[TREE]] or 0) < TB.ROW_POINTS * (t[ROW] - 1) then
            return "Erst " .. TB.ROW_POINTS * (t[ROW] - 1) .. " Punkte in diesem Baum."
        end
        count[node], spent[t[TREE]] = rank, (spent[t[TREE]] or 0) + 1
    end
    return nil
end

function TB.Ranks(points)
    local count, spent = {}, {}
    local tree = TB.Tree(TB.class)
    for _, node in ipairs(points) do
        count[node] = (count[node] or 0) + 1
        local t = tree and tree[node]
        if t then spent[t[TREE]] = (spent[t[TREE]] or 0) + 1 end
    end
    return count, spent
end

function TB.Add(class, points, node)
    points[#points + 1] = node
    local why = TB.Check(class, points)
    if why then points[#points] = nil return false, why end
    return true
end

-- Den letzten Punkt dieses Talents nehmen - nur wenn der Rest gueltig bleibt.
function TB.Remove(class, points, node)
    for i = #points, 1, -1 do
        if points[i] == node then
            table.remove(points, i)
            local why = TB.Check(class, points)
            if why then table.insert(points, i, node) return false, "Andere Punkte hängen daran." end
            return true
        end
    end
    return false
end

function TB.Export(class, points)
    local ids = {}
    for i, n in ipairs(points) do ids[i] = tostring(n) end
    return TB.PREFIX .. ":" .. class .. ":" .. table.concat(ids, ",")
end
-- class, points oder nil, Grund.
function TB.Import(text)
    if type(text) ~= "string" then return nil, "Kein Text." end
    local class, list = text:match("^%s*" .. TB.PREFIX .. ":(%u+):([%d,]*)%s*$")
    if not class then return nil, "Das ist kein Talentbuild von WeintCodex." end
    if not TB.Tree(class) then return nil, "Unbekannte Klasse." end
    local points = {}
    for id in list:gmatch("%d+") do points[#points + 1] = tonumber(id) end
    local why = TB.Check(class, points)
    if why then return nil, "Ungültig: " .. why end
    return class, points
end

--------------------------------------------------
-- Gespeichert
--------------------------------------------------

function TB.Builds(class)
    local sd = _G.WeintCodex_SavedData
    if type(sd) ~= "table" then return nil end
    sd.talentBuilds = sd.talentBuilds or {}
    sd.talentBuilds[class] = sd.talentBuilds[class] or {}
    return sd.talentBuilds[class]
end
function TB.Save(class, name, points)
    local list = TB.Builds(class)
    if not list then return false end
    local copy = {}
    for i, n in ipairs(points) do copy[i] = n end
    for _, b in ipairs(list) do
        if b.name == name then b.points = copy return true end
    end
    list[#list + 1] = { name = name, points = copy }
    return true
end
function TB.Follow(name)
    local st = K.CharState and K.CharState()
    if st then st.followBuild = name end
end
function TB.Followed()
    local st = K.CharState and K.CharState()
    local name = st and st.followBuild
    if not name then return nil end
    for _, b in ipairs(TB.Builds(Class() or "") or {}) do
        if b.name == name then return b end
    end
    return nil
end

-- Verteilte Punkte vom Client (alle drei Baeume) oder nil.
function TB.SpentPoints()
    if type(_G.GetTalentTabInfo) ~= "function" then return nil end
    local sum, any = 0, false
    for t = 1, 3 do
        local ok, _, _, c, _, e = pcall(_G.GetTalentTabInfo, t)
        c, e = ok and K.Plain(c), ok and K.Plain(e)
        local n = type(c) == "number" and c or (type(e) == "number" and e or nil)
        if n then sum, any = sum + n, true end
    end
    return any and sum or nil
end
function TB.Unspent()
    local f = _G.GetUnspentTalentPoints or _G.UnitCharacterPoints
    if not f then return nil end
    local ok, n = pcall(f, f == _G.UnitCharacterPoints and "player" or nil)
    n = ok and K.Plain(n)
    return type(n) == "number" and n or nil
end

-- Das naechste Talent laut gefolgtem Build: node, Name oder nil.
function TB.Next()
    local b = TB.Followed()
    local spent = TB.SpentPoints()
    if not (b and spent) then return nil end
    local node = b.points[spent + 1]
    local tree = TB.Tree()
    if not (node and tree and tree[node]) then return nil end
    local cs = _G.C_Spell
    local name = cs and cs.GetSpellName and K.Plain(cs.GetSpellName(tree[node][SPELL]))
    return node, type(name) == "string" and name or ("Talent " .. node)
end

--------------------------------------------------
-- Fenster
--------------------------------------------------

local win
TB.ICON, TB.GAP = 30, 8
local buttons = {}
TB.class, TB.points = nil, {}

local function Say(t) print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " " .. t) end

local function Paint()
    if not win then return end
    local count, spent = TB.Ranks(TB.points)
    local tree = TB.Tree(TB.class) or {}
    for node, b in pairs(buttons) do
        local t = tree[node]
        local r = count[node] or 0
        b.rank:SetText(r .. "/" .. t[RANKS])
        b.icon:SetDesaturated(r == 0)
        b.icon:SetAlpha(r == 0 and 0.55 or 1)
    end
    for i = 1, 3 do win.heads[i]:SetText((win.specs and win.specs[i] or ("Baum " .. i)) .. " (" .. (spent[i] or 0) .. ")") end
    local n = #TB.points
    win.info:SetText(n .. " / " .. TB.MAX_POINTS .. " Punkte · bis Stufe " .. (n > 0 and (n + TB.FIRST_LEVEL - 1) or "–"))
end

local function Build()
    if win then return end
    win = CreateFrame("Frame", "WeintCodexTalentPlanner", UIParent)
    win:SetSize(3 * (4 * (TB.ICON + TB.GAP)) + 60, 7 * (TB.ICON + TB.GAP) + 120)
    win:SetPoint("CENTER")
    win:SetFrameStrata("DIALOG")
    win:EnableMouse(true)
    win:SetMovable(true)
    win:RegisterForDrag("LeftButton")
    win:SetScript("OnDragStart", win.StartMoving)
    win:SetScript("OnDragStop", win.StopMovingOrSizing)
    local bg = win:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(win)
    local p = C.bgPanel
    bg:SetColorTexture(p[1], p[2], p[3], 0.97)
    K.Border(win, 1, 0, 0, 0, 1, "BORDER")
    local title = K.NewText(win, 14)
    title:SetPoint("TOPLEFT", win, "TOPLEFT", 12, -10)
    title:SetText("Talentplaner")
    win.info = K.NewText(win, 11)
    win.info:SetPoint("TOPRIGHT", win, "TOPRIGHT", -36, -12)
    local close = CreateFrame("Button", nil, win, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", win, "TOPRIGHT", 0, 0)
    win.heads = {}
    for i = 1, 3 do
        local h = K.NewText(win, 12)
        h:SetPoint("TOPLEFT", win, "TOPLEFT", 20 + (i - 1) * (4 * (TB.ICON + TB.GAP) + 10), -36)
        win.heads[i] = h
    end
    -- Knoepfe unten
    local function Btn(text, x, fn)
        local b = CreateFrame("Button", nil, win, "UIPanelButtonTemplate")
        b:SetSize(110, 22)
        b:SetPoint("BOTTOMLEFT", win, "BOTTOMLEFT", x, 10)
        b:SetText(text)
        b:SetScript("OnClick", fn)
        return b
    end
    Btn("Leeren", 12, function() for i = #TB.points, 1, -1 do TB.points[i] = nil end Paint() end)
    Btn("Speichern …", 128, function() TB.AskName() end)
    Btn("Teilen", 244, function() K.ShowReport("Talentbuild teilen", { TB.Export(TB.class, TB.points) }) end)
    Btn("Laden / Folgen …", 360, function(self) TB.BuildMenu(self) end)
    win:Hide()
end

local function Layout()
    for _, b in pairs(buttons) do b:Hide() end
    wipe(buttons)
    local tree = TB.Tree(TB.class) or {}
    win.specs = nil
    for node, t in pairs(tree) do
        local b = win.pool and win.pool[node]
        if not b then
            b = CreateFrame("Button", nil, win)
            b:SetSize(TB.ICON, TB.ICON)
            b.icon = b:CreateTexture(nil, "ARTWORK")
            b.icon:SetAllPoints(b)
            b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            K.Border(b, 1, 0, 0, 0, 1, "OVERLAY")
            b.rank = K.NewText(b, 9)
            b.rank:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", 2, -2)
            b.rank:SetShadowOffset(1, -1)
            b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            b:SetScript("OnClick", function(self, button)
                local ok, why
                if button == "RightButton" then ok, why = TB.Remove(TB.class, TB.points, self.node)
                else ok, why = TB.Add(TB.class, TB.points, self.node) end
                if not ok and why then Say(why) end
                Paint()
            end)
            b:SetScript("OnEnter", function(self)
                if not _G.GameTooltip then return end
                _G.GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                pcall(_G.GameTooltip.SetSpellByID, _G.GameTooltip, self.spell)
                _G.GameTooltip:AddLine("Linksklick: Punkt setzen · Rechtsklick: zurücknehmen", 0.7, 0.7, 0.7)
                _G.GameTooltip:Show()
            end)
            b:SetScript("OnLeave", function() if _G.GameTooltip then _G.GameTooltip:Hide() end end)
            win.pool = win.pool or {}
            win.pool[node] = b
        end
        b.node, b.spell = node, t[SPELL]
        local cs = _G.C_Spell
        local tex = cs and cs.GetSpellTexture and K.Plain(cs.GetSpellTexture(t[SPELL]))
        b.icon:SetTexture(tex or 134400)
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", win, "TOPLEFT", 20 + (t[TREE] - 1) * (4 * (TB.ICON + TB.GAP) + 10) + (t[COL] - 1) * (TB.ICON + TB.GAP),
            -56 - (t[ROW] - 1) * (TB.ICON + TB.GAP))
        b:Show()
        buttons[node] = b
    end
    -- Namen der Baeume vom Client, sonst aus data/specs.lua, sonst Nummer.
    win.specs = {}
    for i = 1, 3 do
        local ok, name = pcall(_G.GetTalentTabInfo or function() end, i)
        name = ok and K.Plain(name)
        win.specs[i] = type(name) == "string" and name or nil
    end
end

function TB.Open(class)
    Build()
    TB.class = class or Class()
    if not TB.Tree(TB.class) then Say("Für deine Klasse gibt es keinen Talentbaum.") return end
    Layout()
    Paint()
    win:Show()
end

function TB.AskName()
    local SP = _G.StaticPopupDialogs
    if not (SP and _G.StaticPopup_Show) then return end
    SP.WEINTCODEX_TALENTBUILD = SP.WEINTCODEX_TALENTBUILD or {
        text = "Name des Builds (oder einen geteilten Text einfügen):", button1 = "Speichern", button2 = "Abbrechen",
        hasEditBox = true, timeout = 0, whileDead = true, hideOnEscape = true,
        OnAccept = function(self)
            local eb = self.editBox or (self.GetEditBox and self:GetEditBox())
            local text = eb and eb:GetText() or ""
            if text:find("^%s*" .. TB.PREFIX .. ":") then
                local class, points = TB.Import(text)
                if not class then Say(points) return end
                TB.class, TB.points = class, points
                if win and win:IsShown() then Layout() Paint() end
                Say("Build übernommen – noch nicht gespeichert.")
                return
            end
            if text == "" then return end
            if TB.Save(TB.class, text, TB.points) then Say("Gespeichert: " .. text) end
        end,
    }
    _G.StaticPopup_Show("WEINTCODEX_TALENTBUILD")
end

function TB.BuildMenu(owner)
    local MU = _G.MenuUtil
    if not (MU and MU.CreateContextMenu) then return end
    local list = TB.Builds(TB.class) or {}
    local followed = TB.Followed()
    MU.CreateContextMenu(owner, function(_, root)
        if root.CreateTitle then root:CreateTitle("Gespeicherte Builds") end
        if #list == 0 then root:CreateButton("Noch keine – erst „Speichern …“", function() end) end
        for _, b in ipairs(list) do
            local sub = root:CreateButton(b.name .. (followed == b and " (gefolgt)" or ""))
            sub:CreateButton("Laden", function()
                TB.points = {}
                for i, n in ipairs(b.points) do TB.points[i] = n end
                Paint()
            end)
            sub:CreateButton("Beim Leveln folgen", function() TB.Follow(b.name) TB.Hint() end)
            sub:CreateButton("Löschen", function()
                for i, x in ipairs(list) do if x == b then table.remove(list, i) break end end
            end)
        end
        if followed then root:CreateButton("Nicht mehr folgen", function() TB.Follow(nil) TB.Hint() end) end
    end)
end

--------------------------------------------------
-- Folgen: Hinweis bei freien Punkten
--------------------------------------------------

local hint
function TB.Hint()
    if not hint then
        hint = CreateFrame("Button", "WeintCodexTalentHint", UIParent)
        hint:SetSize(300, 24)
        hint.text = K.NewText(hint, 13)
        hint.text:SetPoint("CENTER", hint, "CENTER", 0, 0)
        hint.text:SetShadowOffset(1, -1)
        hint:SetScript("OnClick", function() TB.Open() end)
        hint:Hide()
        hint.WCShowForUnlock = function(self, on) self._unlock = on and true or nil TB.Hint() end
        K.RegisterMover(hint, "talenthint", "Talent-Hinweis", K.Layout("talenthint"))
    end
    local free = TB.Unspent()
    local node, name = TB.Next()
    if hint._unlock then hint.text:SetText("Nächstes Talent: …") hint:Show() return end
    if free and free > 0 and node then
        hint.text:SetText("Nächstes Talent laut Plan: " .. name)
        hint:Show()
    else
        hint:Hide()
    end
end

function TB.Enable()
    if TB.enabled then return end
    TB.enabled = true
    local ev = CreateFrame("Frame")
    for _, e in ipairs({ "PLAYER_LEVEL_UP", "CHARACTER_POINTS_CHANGED", "PLAYER_TALENT_UPDATE", "PLAYER_ENTERING_WORLD" }) do
        pcall(ev.RegisterEvent, ev, e)
    end
    ev:SetScript("OnEvent", K.Measured("Talentplaner", function() TB.Hint() end))
end

do
    local m = K.Module("comfort")
    if m then
        local enable = m.Enable
        m.Enable = function(...)
            if enable then enable(...) end
            local ok, err = pcall(TB.Enable)
            if not ok then K.Report("talentplaner", err) end
        end
    end
end

-- /wcui speicher: interne Tabellen dieser Datei (1.0.8.27).
WeintCodex.Hold("ui/talentbuilds.lua", function() return { buttons = buttons } end)
