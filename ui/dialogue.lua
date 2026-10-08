--------------------------------------------------
-- WeintCodex :: Gespraeche im Codex-Stil (Komfort, Seite "Gespräche")
--------------------------------------------------
-- Seit 6.23.0.0 (Beta-Test: "sowas wie DialogueUI, nur im Codex-Stil").
-- Nach dem VERHALTEN von DialogueUI, ohne dessen Code, Bilder oder Klaenge
-- (das Paket nennt keine Lizenz - also alle Rechte beim Urheber).
--
-- Was es tut: Gespraech mit einem NPC (Optionen, Quests) und die Quest-
-- texte (Annehmen, Fortschritt, Abschliessen mit Belohnung) erscheinen in
-- EINEM ruhigen Fenster rechts neben der Mitte statt in den Fenstern des
-- Spiels. Zahlen 1-9 waehlen, Leertaste nimmt an / geht weiter, Esc
-- schliesst. Der Text laeuft auf Wunsch Zeichen fuer Zeichen ein.
--
-- WIE: die Fenster des Spiels (GossipFrame, QuestFrame) bekommen ihre
-- Ereignisse nicht mehr - DL.TakeOver meldet sie dort ab, DL.Release
-- meldet genau diese wieder an (auch beim Ausschalten, ohne Neuladen).
-- Nichts wird umgeschrieben; gewaehlt wird ueber dieselben Aufrufe wie
-- in den Fenstern des Spiels (C_GossipInfo.SelectOption, AcceptQuest ...).
--
-- FARBE: Gespraeche gehoeren nicht zur Klasse - Gold (GameColors.
-- frameAccent), wie die Gespraechsfenster in ui/gossip.lua.
--
-- Bricht der Aufbau ab, gibt DL.Fail die Fenster des Spiels zurueck und
-- sagt es; im Kampf keine Tasten (das Spiel sperrt das Weiterreichen).
--------------------------------------------------

local K = WeintCodex.UIKit
local C = WeintCodex.Colors
local GC = WeintCodex.GameColors
local KEY = "comfort"

WeintCodex.UIDialogue = {}
local DL = WeintCodex.UIDialogue

DL.DEFAULTS = {
    dlgOn    = false,    -- Gespraeche im Codex-Stil
    dlgKeys  = true,     -- 1-9, Leertaste, Esc
    dlgType  = true,     -- Text laeuft ein
    dlgScale = 100,      -- Groesse in %
    dlgCam   = true,     -- Kamera heran, danach zurueck (6.23.1.0)
    dlgCamDist = 4,      -- so nah (Meter)
    dlgShoulder = true,  -- NPC zur Seite (Schulterkamera, 6.23.1.0)
}
DL.W = 460
DL.BODY_MAX = 230        -- hoechstens so hoch, dann rollt der Text
DL.SPEED = 90            -- Zeichen je Sekunde beim Einlaufen
DL.MAX_ROWS = 12
DL.MAX_ITEMS = 10

-- Ereignisse, die den Fenstern des Spiels genommen werden.
-- 6.23.1.1 (Beta-Test: altes Fenster UND neues): auf dem neuen Client
-- oeffnet nicht GossipFrame das Gespraech, sondern CustomGossipFrameManager.
DL.EVENTS = {
    CustomGossipFrameManager = { "GOSSIP_SHOW", "GOSSIP_CLOSED" },
    GossipFrame = { "GOSSIP_SHOW", "GOSSIP_CLOSED" },
    QuestFrame = { "QUEST_GREETING", "QUEST_DETAIL", "QUEST_PROGRESS", "QUEST_COMPLETE",
                   "QUEST_FINISHED", "QUEST_ITEM_UPDATE" },
}

local stats = { shown = 0, picked = 0, failed = 0, gameShown = 0 }
DL.stats = stats
DL.taken = {}            -- [Fenster] = { Ereignis, ... }, was abgemeldet ist
DL.state = nil           -- "gossip", "greeting", "detail", "progress", "complete"
DL.choice = nil          -- gewaehlte Belohnung beim Abschliessen
DL.lastError = nil

local function Say(text) print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " " .. text) end
local function Call(name, ...)
    local f = _G[name]
    if type(f) == "function" then return f(...) end
end
local function Plain(v) return K.Plain(v) end
local function Str(v) v = Plain(v) return type(v) == "string" and v or "" end

function DL.Active() return K.IsActive(KEY) and K.Get(KEY, "dlgOn") and true or false end
function DL.Usable()
    local gi = _G.C_GossipInfo
    return type(gi) == "table" and type(gi.GetOptions) == "function" and type(gi.SelectOption) == "function"
end

--------------------------------------------------
-- Fenster des Spiels: abmelden und zurueckgeben
--------------------------------------------------

function DL.TakeOver()
    for name, events in pairs(DL.EVENTS) do
        local f = _G[name]
        if type(f) == "table" and f.UnregisterEvent and not DL.taken[name] then
            local took = {}
            for _, e in ipairs(events) do
                local reg = f.IsEventRegistered and K.Bool(f:IsEventRegistered(e), false)
                if reg then
                    f:UnregisterEvent(e)
                    took[#took + 1] = e
                end
            end
            DL.taken[name] = took
            if f.IsShown and f:IsShown() and f.Hide then f:Hide() end
        end
    end
end

function DL.Release()
    for name, took in pairs(DL.taken) do
        local f = _G[name]
        if type(f) == "table" and f.RegisterEvent then
            for _, e in ipairs(took) do pcall(f.RegisterEvent, f, e) end
        end
        DL.taken[name] = nil
    end
end

--------------------------------------------------
-- Fenster
--------------------------------------------------

local win, head, sub, scroll, body, rowsTitle, foot, primary, secondary, close
local rows, items = {}, {}
local reveal, revealLen = nil, 0

local function Accent() local a = GC.frameAccent return a[1], a[2], a[3] end

local function NewButton(parent, w)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(w, 26)
    K.Kachel(b, { shadow = 0, alpha = 0.9 })
    b.t = K.NewText(b, 12)
    b.t:SetPoint("CENTER", b, "CENTER", 0, 0)
    b.edge = b:CreateTexture(nil, "ARTWORK")
    b.edge:SetPoint("BOTTOMLEFT", b, "BOTTOMLEFT", 1, 1)
    b.edge:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -1, 1)
    b.edge:SetHeight(2)
    local r, g, bl = Accent()
    b.edge:SetColorTexture(r, g, bl, 0.9)
    return b
end

local function SetButton(b, text, enabled)
    if not text then b:Hide() return end
    b.t:SetText(text)
    local c = enabled and C.textBright or C.textFaint
    b.t:SetTextColor(c[1], c[2], c[3])
    b.edge:SetShown(enabled and true or false)
    b.enabled = enabled and true or false
    b:Show()
end

local function Row(i)
    local r = rows[i]
    if r then return r end
    r = CreateFrame("Button", nil, win)
    r:SetHeight(22)
    r.hl = r:CreateTexture(nil, "BACKGROUND")
    r.hl:SetAllPoints(r)
    local s = C.surface3
    r.hl:SetColorTexture(s[1], s[2], s[3], 0.8)
    r.hl:Hide()
    r.num = K.NewText(r, 12)
    r.num:SetPoint("LEFT", r, "LEFT", 6, 0)
    r.num:SetWidth(18)
    r.mark = K.NewText(r, 12)
    r.mark:SetPoint("LEFT", r, "LEFT", 26, 0)
    r.mark:SetWidth(12)
    r.label = K.NewText(r, 12)
    r.label:SetPoint("LEFT", r, "LEFT", 42, 0)
    r.label:SetPoint("RIGHT", r, "RIGHT", -6, 0)
    r.label:SetJustifyH("LEFT")
    r.label:SetWordWrap(false)
    r:SetScript("OnEnter", function(self) self.hl:Show() end)
    r:SetScript("OnLeave", function(self) self.hl:Hide() end)
    r:SetScript("OnClick", function(self) DL.Pick(self.index) end)
    rows[i] = r
    return r
end

local function Item(i)
    local b = items[i]
    if b then return b end
    b = CreateFrame("Button", nil, win)
    b:SetSize(36, 36)
    K.Kachel(b, { shadow = 0 })
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetPoint("TOPLEFT", b, "TOPLEFT", 2, -2)
    b.icon:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -2, 2)
    b.count = K.NewText(b, 10, "OVERLAY")
    b.count:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -2, 2)
    b.sel = b:CreateTexture(nil, "OVERLAY")
    b.sel:SetPoint("TOPLEFT", b, "TOPLEFT", -2, 2)
    b.sel:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", 2, -2)
    local r, g, bl = Accent()
    b.sel:SetColorTexture(r, g, bl, 0.35)
    b.sel:Hide()
    b:SetScript("OnEnter", function(self)
        local gt = _G.GameTooltip
        if not gt then return end
        gt:SetOwner(self, "ANCHOR_RIGHT")
        if gt.SetQuestItem then pcall(gt.SetQuestItem, gt, self.kind, self.index) end
        gt:Show()
    end)
    b:SetScript("OnLeave", function() if _G.GameTooltip then _G.GameTooltip:Hide() end end)
    b:SetScript("OnClick", function(self) if self.kind == "choice" then DL.Choose(self.index) end end)
    items[i] = b
    return b
end

local function OnKey(self, key)
    local take = false
    if key == "ESCAPE" then
        DL.Close()
        take = true
    elseif key == "SPACE" or key == "ENTER" then
        take = DL.Primary()
    else
        local n = tonumber(key)
        if n and n >= 1 and n <= 9 then take = DL.Pick(n) or DL.Choose(n) end
    end
    if self.SetPropagateKeyboardInput and not (_G.InCombatLockdown and K.Bool(_G.InCombatLockdown(), false)) then
        self:SetPropagateKeyboardInput(not take)
    end
end

local function OnUpdate(_, el)
    if not reveal then return end
    reveal = reveal + (el or 0) * DL.SPEED
    if reveal >= revealLen then
        reveal = nil
        if body.SetAlphaGradient then pcall(body.SetAlphaGradient, body, 0, 0) end
        return
    end
    if body.SetAlphaGradient then pcall(body.SetAlphaGradient, body, math.floor(reveal), 30) end
end

-- Platz: gemerkt, sonst wo das Questfenster des Spiels steht (oben links).
DL.HOME = { x = 16, y = -116 }
function DL.Place()
    if not win then return end
    win:ClearAllPoints()
    local p = K.Get(KEY, "dlgPos")
    if type(p) == "table" and type(p.x) == "number" and type(p.y) == "number" then
        win:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", p.x, p.y)
    else
        win:SetPoint("TOPLEFT", UIParent, "TOPLEFT", DL.HOME.x, DL.HOME.y)
    end
end

function DL.Build()
    if win then return win end
    win = CreateFrame("Frame", "WeintCodexDialogue", UIParent)
    win:SetWidth(DL.W)
    win:SetFrameStrata("HIGH")
    win:SetToplevel(true)
    win:SetClampedToScreen(true)
    win:EnableMouse(true)
    win:SetMovable(true)
    win:RegisterForDrag("LeftButton")
    win:SetScript("OnDragStart", win.StartMoving)
    win:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local l, t = K.Plain(self:GetLeft()), K.Plain(self:GetTop())
        if type(l) == "number" and type(t) == "number" then K.Set(KEY, "dlgPos", { x = l, y = t }) end
    end)
    DL.Place()
    win:Hide()
    K.Kachel(win, { alpha = 0.95, shadow = 10 })
    local r, g, b = Accent()
    local edge = win:CreateTexture(nil, "ARTWORK")
    edge:SetPoint("TOPLEFT", win, "TOPLEFT", 1, -1)
    edge:SetPoint("TOPRIGHT", win, "TOPRIGHT", -1, -1)
    edge:SetHeight(2)
    edge:SetColorTexture(r, g, b, 0.8)

    head = K.NewText(win, 16)
    head:SetPoint("TOPLEFT", win, "TOPLEFT", 16, -14)
    head:SetPoint("RIGHT", win, "RIGHT", -40, 0)
    head:SetJustifyH("LEFT")
    head:SetWordWrap(false)
    sub = K.NewText(win, 12)
    sub:SetPoint("TOPLEFT", head, "BOTTOMLEFT", 0, -4)
    sub:SetPoint("RIGHT", win, "RIGHT", -16, 0)
    sub:SetJustifyH("LEFT")
    sub:SetTextColor(r, g, b)

    close = CreateFrame("Button", nil, win)
    close:SetSize(24, 22)
    close:SetPoint("TOPRIGHT", win, "TOPRIGHT", -8, -8)
    local x = K.NewText(close, 14)
    x:SetPoint("CENTER", close, "CENTER", 0, 0)
    local m = C.textMuted
    x:SetTextColor(m[1], m[2], m[3])
    x:SetText("\195\151")
    close:SetScript("OnClick", function() DL.Close() end)

    scroll = CreateFrame("ScrollFrame", nil, win)
    scroll:SetPoint("TOPLEFT", sub, "BOTTOMLEFT", 0, -10)
    scroll:SetWidth(DL.W - 32)
    scroll:EnableMouseWheel(true)
    local child = CreateFrame("Frame", nil, scroll)
    child:SetWidth(DL.W - 32)
    body = K.NewText(child, 13)
    body:SetPoint("TOPLEFT", child, "TOPLEFT", 0, 0)
    body:SetWidth(DL.W - 32)
    body:SetJustifyH("LEFT")
    body:SetSpacing(3)
    local t = C.textNormal
    body:SetTextColor(t[1], t[2], t[3])
    scroll:SetScrollChild(child)
    scroll.child = child
    scroll:SetScript("OnMouseWheel", function(self, d)
        local max = K.Plain(self:GetVerticalScrollRange()) or 0
        local v = (K.Plain(self:GetVerticalScroll()) or 0) - d * 30
        self:SetVerticalScroll(math.max(0, math.min(type(max) == "number" and max or 0, v)))
    end)

    rowsTitle = K.NewText(win, 11)
    rowsTitle:SetTextColor(m[1], m[2], m[3])
    rowsTitle:SetJustifyH("LEFT")
    foot = K.NewText(win, 10)
    foot:SetPoint("BOTTOMLEFT", win, "BOTTOMLEFT", 16, 14)
    local f = C.textFaint
    foot:SetTextColor(f[1], f[2], f[3])

    primary = NewButton(win, 130)
    primary:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", -16, 10)
    primary:SetScript("OnClick", function() DL.Primary() end)
    secondary = NewButton(win, 110)
    secondary:SetPoint("RIGHT", primary, "LEFT", -8, 0)
    secondary:SetScript("OnClick", function() DL.Secondary() end)

    win:SetScript("OnKeyDown", OnKey)
    win:SetScript("OnUpdate", OnUpdate)
    win:SetScript("OnHide", function()
        reveal = nil
        DL.CamLater()
    end)
    DL.win = win
    return win
end

--------------------------------------------------
-- Inhalt je Zustand
--------------------------------------------------

DL.list = {}             -- { { text, mark, kind, id }, ... } die gezeigten Zeilen
DL.rewards = {}          -- { { kind, index, name, tex, count }, ... }

local function AddLine(text, mark, kind, id)
    local l = DL.list
    if #l >= DL.MAX_ROWS then return end
    l[#l + 1] = { text = text, mark = mark, kind = kind, id = id }
end

local function AddItems(kind, n)
    for i = 1, n do
        local name, tex, count = Call("GetQuestItemInfo", kind, i)
        if #DL.rewards < DL.MAX_ITEMS then
            DL.rewards[#DL.rewards + 1] = { kind = kind, index = i, name = Plain(name), tex = Plain(tex), count = Plain(count) }
        end
    end
end

local function Num(name) local v = Plain(Call(name)) return type(v) == "number" and v or 0 end

-- Sammelt Text, Zeilen und Belohnungen des Zustands.
function DL.Collect(state)
    DL.list, DL.rewards = {}, {}
    local c = { state = state, title = "", text = "", extra = nil, primary = nil, secondary = "Tschüss" }
    local npc = _G.UnitName and Str(_G.UnitName("npc"))
    c.npc = npc ~= "" and npc or "Gespräch"
    if state == "gossip" then
        local gi = _G.C_GossipInfo
        c.text = Str(gi.GetText and gi.GetText())
        for _, q in ipairs(gi.GetActiveQuests and gi.GetActiveQuests() or {}) do
            AddLine(Str(q.title), K.Bool(q.isComplete, false) and "?" or "·", "active", Plain(q.questID))
        end
        for _, q in ipairs(gi.GetAvailableQuests and gi.GetAvailableQuests() or {}) do
            AddLine(Str(q.title), "!", "available", Plain(q.questID))
        end
        local opts = gi.GetOptions() or {}
        table.sort(opts, function(a, b) return (Plain(a.orderIndex) or 0) < (Plain(b.orderIndex) or 0) end)
        for _, o in ipairs(opts) do AddLine(Str(o.name), "›", "option", Plain(o.gossipOptionID)) end
    elseif state == "greeting" then
        c.text = Str(Call("GetGreetingText"))
        for i = 1, Num("GetNumActiveQuests") do AddLine(Str(Call("GetActiveTitle", i)), "?", "gactive", i) end
        for i = 1, Num("GetNumAvailableQuests") do AddLine(Str(Call("GetAvailableTitle", i)), "!", "gavailable", i) end
    elseif state == "detail" then
        c.title = Str(Call("GetTitleText"))
        c.text = Str(Call("GetQuestText"))
        local obj = Str(Call("GetObjectiveText"))
        if obj ~= "" then c.text = c.text .. "\n\n" .. WeintCodex.ColorText("textBright", "Ziele") .. "\n" .. obj end
        AddItems("reward", Num("GetNumQuestRewards"))
        AddItems("choice", Num("GetNumQuestChoices"))
        c.primary, c.canPrimary, c.secondary = "Annehmen", true, "Ablehnen"
    elseif state == "progress" then
        c.title = Str(Call("GetTitleText"))
        c.text = Str(Call("GetProgressText"))
        AddItems("required", Num("GetNumQuestItems"))
        c.primary, c.canPrimary, c.secondary = "Weiter", K.Bool(Call("IsQuestCompletable"), false), "Schließen"
    elseif state == "complete" then
        c.title = Str(Call("GetTitleText"))
        c.text = Str(Call("GetRewardText"))
        AddItems("reward", Num("GetNumQuestRewards"))
        local choices = Num("GetNumQuestChoices")
        AddItems("choice", choices)
        c.choices = choices
        c.primary, c.canPrimary, c.secondary = "Abschließen", choices <= 1 or DL.choice ~= nil, "Schließen"
    end
    if state == "detail" or state == "complete" then
        local money, xp = Num("GetRewardMoney"), Num("GetRewardXP")
        local parts = {}
        if money > 0 and _G.GetCoinTextureString then parts[#parts + 1] = _G.GetCoinTextureString(money) end
        if xp > 0 then parts[#parts + 1] = xp .. " Erfahrung" end
        c.extra = #parts > 0 and table.concat(parts, "   ") or nil
    end
    DL.current = c
    return c
end

-- Zeichnen: was Collect gesammelt hat.
function DL.Draw(c)
    DL.Build()
    local scale = (tonumber(K.Get(KEY, "dlgScale")) or 100) / 100
    win:SetScale(scale)
    head:SetText(c.npc)
    sub:SetText(c.title or "")
    body:SetText(c.text ~= "" and c.text or " ")
    local th = K.Plain(body:GetStringHeight())
    th = type(th) == "number" and th or 14
    scroll.child:SetHeight(th)
    local bh = math.min(DL.BODY_MAX, th)
    scroll:SetHeight(bh)
    scroll:SetVerticalScroll(0)
    local y = 14 + 20 + 4 + 16 + 10 + bh + 12        -- Kopf, Titel, Text

    -- Belohnungen / benoetigte Gegenstaende
    local shownItems = 0
    local label
    if #DL.rewards > 0 or c.extra then
        label = c.state == "progress" and "Benötigt" or (c.choices and c.choices > 1 and "Belohnung – wähle eine" or "Belohnung")
    end
    if label then
        rowsTitle:ClearAllPoints()
        rowsTitle:SetPoint("TOPLEFT", win, "TOPLEFT", 16, -y)
        rowsTitle:SetText(label .. (c.extra and ("   " .. c.extra) or ""))
        rowsTitle:Show()
        y = y + 18
        for i, rw in ipairs(DL.rewards) do
            local b = Item(i)
            b.kind, b.index = rw.kind, rw.index
            b.icon:SetTexture(rw.tex)
            b.count:SetText((type(rw.count) == "number" and rw.count > 1) and rw.count or "")
            b.sel:SetShown(rw.kind == "choice" and DL.choice == rw.index)
            b:ClearAllPoints()
            b:SetPoint("TOPLEFT", win, "TOPLEFT", 16 + (i - 1) * 42, -y)
            b:Show()
            shownItems = i
        end
        if shownItems > 0 then y = y + 42 end
    else
        rowsTitle:Hide()
    end
    for i = shownItems + 1, #items do items[i]:Hide() end

    -- Zeilen (Optionen, Quests)
    for i, l in ipairs(DL.list) do
        local r = Row(i)
        r.index = i
        r.num:SetText(i <= 9 and tostring(i) or "")
        local m = C.textMuted
        r.num:SetTextColor(m[1], m[2], m[3])
        r.mark:SetText(l.mark)
        local ar, ag, ab = Accent()
        if l.mark == "!" or l.mark == "?" then r.mark:SetTextColor(ar, ag, ab) else r.mark:SetTextColor(m[1], m[2], m[3]) end
        r.label:SetText(l.text)
        local t = C.textBright
        r.label:SetTextColor(t[1], t[2], t[3])
        r:ClearAllPoints()
        r:SetPoint("TOPLEFT", win, "TOPLEFT", 10, -y)
        r:SetPoint("RIGHT", win, "RIGHT", -10, 0)
        r:Show()
        y = y + 24
    end
    for i = #DL.list + 1, #rows do rows[i]:Hide() end

    SetButton(primary, c.primary, c.canPrimary)
    SetButton(secondary, c.secondary, true)
    local keys = K.Get(KEY, "dlgKeys")
    foot:SetText(keys and ((#DL.list > 0 and "1–9 wählen · " or "") .. (c.primary and "Leertaste: " .. c.primary .. " · " or "") .. "Esc schließt") or "")
    win:SetHeight(y + 12 + 36)

    -- Text laeuft ein
    if K.Get(KEY, "dlgType") and body.SetAlphaGradient then
        revealLen = (WeintCodex.Utf8Len and WeintCodex.Utf8Len(c.text)) or #c.text
        reveal = 0
        pcall(body.SetAlphaGradient, body, 0, 30)
    else
        reveal = nil
    end
    local combat = _G.InCombatLockdown and K.Bool(_G.InCombatLockdown(), false)
    win:EnableKeyboard(keys and not combat and true or false)
    win:Show()
end

--------------------------------------------------
-- Kamera (6.23.1.0, Beta-Test: "reinzoomen und automatisch rauszoomen")
--------------------------------------------------
-- Beim ersten Fenster eines Gespraechs naeher heran (CameraZoomIn), beim
-- Ende zurueck auf den gemerkten Abstand. Wechselt das Gespraech nur den
-- Zustand (Gespraech -> Questtext), schliesst sich das Fenster kurz -
-- darum erst nach DL.CAM_WAIT zurueck, und nur, wenn kein neues Fenster
-- offen ist. Hat der Spieler selbst weiter herausgezoomt, bleibt es so.
--
-- SCHULTER (Wunsch des Spielers): die Kamera rueckt nach rechts, der NPC
-- steht links neben dem Fenster. Das geht nur ueber die Testeinstellung
-- test_cameraOverShoulder; setzt ein Addon sie, zeigt das Spiel einmal die
-- Warnung zu Testfunktionen (EXPERIMENTAL_CVAR_WARNING an UIParent). Die
-- wird fuer diesen einen Aufruf abgemeldet und danach wieder angemeldet -
-- andere Addons bekommen sie weiter. Gesetzt ueber PF.SetCVar (Wert von
-- vorher gemerkt), zurueck ueber PF.Release; die Seite sagt, dass es eine
-- Testeinstellung ist.

DL.CAM_WAIT = 0.3
DL.SHOULDER = "test_cameraOverShoulder"
-- Negativ: die Kamera rueckt nach links, der NPC nach rechts - weg vom
-- Fenster, das seit 6.23.1.1 links steht (Platz des Questfensters).
DL.SHOULDER_VALUE = -1.0
-- Langsamer heran (6.23.1.1, Beta-Test: "direkt und langsamer"):
-- cameraZoomSpeed fuer die Dauer des Gespraechs, danach zurueck.
DL.ZOOM_SPEED_CVAR = "cameraZoomSpeed"
DL.ZOOM_SPEED = 8
DL.SPEED_BACK = 2.0
DL.WARNING = "EXPERIMENTAL_CVAR_WARNING"
DL.cam = { saved = nil, shoulder = false }

-- Eine Testeinstellung setzen, ohne dass die Warnung erscheint.
local quietHad = false
local function QuietDone()
    if _G.StaticPopup_Hide then pcall(_G.StaticPopup_Hide, DL.WARNING) end
    local up = _G.UIParent
    if quietHad and up and up.RegisterEvent then pcall(up.RegisterEvent, up, DL.WARNING) end
    quietHad = false
end
function DL.QuietSet(name, value)
    local PF = WeintCodex.UIProfile
    if not (PF and PF.SetCVar) then return false end
    local up = _G.UIParent
    if not quietHad and up and up.IsEventRegistered and K.Bool(up:IsEventRegistered(DL.WARNING), false) then
        up:UnregisterEvent(DL.WARNING)
        quietHad = true
    end
    local ok = PF.SetCVar(name, value, KEY)
    local t = _G.C_Timer
    if t and t.After then t.After(0.5, QuietDone) else QuietDone() end
    return ok
end

local function ShoulderIn()
    if not K.Get(KEY, "dlgShoulder") or DL.cam.shoulder then return end
    DL.cam.shoulder = DL.QuietSet(DL.SHOULDER, DL.SHOULDER_VALUE) and true or false
end
local function ShoulderOut()
    if not DL.cam.shoulder then return end
    DL.cam.shoulder = false
    local PF = WeintCodex.UIProfile
    if PF and PF.Release then PF.Release(DL.SHOULDER) end
end
DL.ShoulderOut = ShoulderOut

local function Zoom()
    local z = _G.GetCameraZoom and K.Plain(_G.GetCameraZoom())
    return type(z) == "number" and z or nil
end

local function SpeedIn()
    if DL.cam.speed then return end
    local PF = WeintCodex.UIProfile
    DL.cam.speed = PF and PF.SetCVar and PF.SetCVar(DL.ZOOM_SPEED_CVAR, DL.ZOOM_SPEED, KEY) and true or false
end
local function SpeedBack()
    if not DL.cam.speed or (win and win:IsShown()) then return end
    DL.cam.speed = false
    local PF = WeintCodex.UIProfile
    if PF and PF.Release then PF.Release(DL.ZOOM_SPEED_CVAR) end
end
DL.SpeedBack = SpeedBack

function DL.CamIn()
    if not K.Get(KEY, "dlgCam") or DL.cam.saved then return false end
    SpeedIn()
    ShoulderIn()
    local z = Zoom()
    local target = tonumber(K.Get(KEY, "dlgCamDist")) or 4
    if not (z and _G.CameraZoomIn) or z <= target + 0.5 then return false end
    DL.cam.saved = z
    _G.CameraZoomIn(z - target)
    return true
end

function DL.CamOut()
    if win and win:IsShown() then return false end
    ShoulderOut()
    local saved = DL.cam.saved
    if not saved then return false end
    DL.cam.saved = nil
    local z = Zoom()
    local t = _G.C_Timer
    if t and t.After then t.After(DL.SPEED_BACK, SpeedBack) end
    if not (z and _G.CameraZoomOut) or z >= saved - 0.5 then return false end
    _G.CameraZoomOut(saved - z)
    return true
end

local function CamOutNow() DL.CamOut() end
function DL.CamLater()
    if not (DL.cam.saved or DL.cam.shoulder) then return end
    local t = _G.C_Timer
    if t and t.After then t.After(DL.CAM_WAIT, CamOutNow) else DL.CamOut() end
end

function DL.Show(state)
    if not DL.Active() then return false end
    if state ~= "complete" then DL.choice = nil end
    DL.state = state
    DL.CamIn()                         -- sofort, vor dem Aufbau
    local ok, err = pcall(function() DL.Draw(DL.Collect(state)) end)
    if not ok then DL.Fail(err) return false end
    stats.shown = stats.shown + 1
    return true
end

-- Aufbau gescheitert: Fenster des Spiels zurueck, Bescheid geben.
function DL.Fail(err)
    stats.failed = stats.failed + 1
    DL.lastError = tostring(err)
    DL.Release()
    if win then win:Hide() end
    K.Set(KEY, "dlgOn", false)
    Say("Das Gesprächsfenster konnte nicht aufgebaut werden – die Fenster des Spiels sind zurück. Bitte neu ansprechen. (" .. DL.lastError .. ")")
end

--------------------------------------------------
-- Handeln
--------------------------------------------------

-- Zeile n waehlen. true, wenn es eine gab.
function DL.Pick(n)
    local l = DL.list[n]
    if not (l and win and win:IsShown()) then return false end
    local gi = _G.C_GossipInfo
    stats.picked = stats.picked + 1
    if l.kind == "option" then gi.SelectOption(l.id)
    elseif l.kind == "available" then gi.SelectAvailableQuest(l.id)
    elseif l.kind == "active" then gi.SelectActiveQuest(l.id)
    elseif l.kind == "gavailable" then Call("SelectAvailableQuest", l.id)
    elseif l.kind == "gactive" then Call("SelectActiveQuest", l.id) end
    return true
end

-- Belohnung n waehlen (nur beim Abschliessen mit Auswahl).
function DL.Choose(n)
    local c = DL.current
    if not (c and c.state == "complete" and c.choices and n <= c.choices) then return false end
    DL.choice = n
    DL.Draw(DL.Collect("complete"))
    return true
end

function DL.Primary()
    local c = DL.current
    if not (c and win and win:IsShown()) then return false end
    if reveal then                     -- erst den Text ganz zeigen
        reveal = revealLen
        return true
    end
    if not (c.primary and c.canPrimary) then return false end
    if c.state == "detail" then Call("AcceptQuest")
    elseif c.state == "progress" then Call("CompleteQuest")
    elseif c.state == "complete" then Call("GetQuestReward", c.choices and c.choices > 1 and DL.choice or 1) end
    return true
end

function DL.Secondary()
    local c = DL.current
    if c and c.state == "detail" then Call("DeclineQuest") return end
    DL.Close()
end

function DL.Close()
    local gi = _G.C_GossipInfo
    if DL.state == "gossip" then
        if gi and gi.CloseGossip then pcall(gi.CloseGossip) end
    elseif DL.state then
        Call("CloseQuest")
    end
    DL.state = nil
    if win then win:Hide() end
end

--------------------------------------------------
-- Ereignisse
--------------------------------------------------

local STATE = {
    GOSSIP_SHOW = "gossip", QUEST_GREETING = "greeting", QUEST_DETAIL = "detail",
    QUEST_PROGRESS = "progress", QUEST_COMPLETE = "complete",
}

local ev = CreateFrame("Frame")
ev:SetScript("OnEvent", function(_, event)
    if not DL.Active() then return end
    local st = STATE[event]
    if st then DL.Show(st) return end
    if event == "QUEST_ITEM_UPDATE" then
        if DL.state and DL.state ~= "gossip" and DL.state ~= "greeting" then DL.Show(DL.state) end
    elseif event == "GOSSIP_CLOSED" then
        if DL.state == "gossip" then DL.state = nil if win then win:Hide() end end
    elseif event == "QUEST_FINISHED" then
        if DL.state and DL.state ~= "gossip" then DL.state = nil if win then win:Hide() end end
    end
end)
DL.events = ev

local function Apply()
    local on = DL.Active() and DL.Usable()
    for _, events in pairs(DL.EVENTS) do
        for _, e in ipairs(events) do
            if on then pcall(ev.RegisterEvent, ev, e) else pcall(ev.UnregisterEvent, ev, e) end
        end
    end
    if on then DL.TakeOver() else
        DL.Release()
        if win then win:Hide() end
        DL.state = nil
    end
end
DL.Apply = Apply

--------------------------------------------------
-- Bericht und Seite
--------------------------------------------------

function DL.StatusLines()
    local out = {}
    local n = 0
    for _, took in pairs(DL.taken) do n = n + #took end
    out[#out + 1] = "Gesprächsdaten (C_GossipInfo): " .. (DL.Usable() and "ja" or "nein")
        .. " · Ereignisse übernommen: " .. n
    out[#out + 1] = string.format("Gezeigt %d · gewählt %d · gescheitert %d", stats.shown, stats.picked, stats.failed)
    if DL.lastError then out[#out + 1] = "Zuletzt gescheitert: " .. DL.lastError end
    if stats.gameShown > 0 then
        out[#out + 1] = "Fenster des Spiels trotzdem offen: " .. stats.gameShown .. "× (zuletzt " .. tostring(DL.gameShownName) .. ")"
    end
    return out
end

local function Build(B)
    local off = function() return not K.Get(KEY, "dlgOn") end
    B:Section("Gespräche", "Gespräche mit NPCs und Questtexte in einem ruhigen Fenster neben der Mitte statt in den Fenstern des Spiels – mit Tasten und Belohnungen auf einen Blick.")
    B:Row({ type = "toggle", label = "Gespräche im Codex-Stil", key = "dlgOn",
            description = "Ausschalten gibt die Fenster des Spiels sofort zurück." },
          { type = "toggle", label = "Tasten 1–9, Leertaste, Esc", key = "dlgKeys", disabled = off,
            description = "Nicht im Kampf – dort sperrt das Spiel die Tasten." })
    B:Row({ type = "toggle", label = "Text läuft ein", key = "dlgType", disabled = off,
            description = "Leertaste zeigt ihn sofort ganz." },
          { type = "slider", label = "Größe", key = "dlgScale", min = 80, max = 130, step = 5, disabled = off,
            format = function(v) return string.format("%d %%", v) end })
    local camOff = function() return off() or not K.Get(KEY, "dlgCam") end
    B:Row({ type = "toggle", label = "Kamera heranholen", key = "dlgCam", disabled = off,
            description = "Beim Gespräch näher heran, danach zurück auf deinen Abstand." },
          { type = "slider", label = "Abstand im Gespräch", key = "dlgCamDist", min = 2, max = 10, step = 1, disabled = camOff,
            format = function(v) return string.format("%d m", v) end })
    B:Row({ type = "toggle", label = "NPC zur Seite rücken", key = "dlgShoulder", disabled = camOff,
            description = "Nutzt eine Testeinstellung des Spiels (Schulterkamera); danach zurück auf deinen Wert." },
          { type = "button", label = "Platz", text = "Zurück an den Platz des Questfensters", disabled = off,
            onClick = function() K.Set(KEY, "dlgPos", nil) DL.Place() end })
end

local mod = K.Module(KEY)
if mod then
    for k, v in pairs(DL.DEFAULTS) do
        if mod.defaults[k] == nil then mod.defaults[k] = v end
    end
    mod.pages[#mod.pages + 1] = { key = "gespraeche", label = "Gespräche", build = Build }
end

K.Listen(function(kind, key)
    if (kind == "active" or kind == "setting") and key == KEY then Apply() end
end)

local boot = CreateFrame("Frame")
boot:RegisterEvent("PLAYER_LOGIN")
boot:SetScript("OnEvent", function()
    -- Abgestuerzt mitten im Gespraech: die Schulter steht noch - zurueck.
    local PF = WeintCodex.UIProfile
    if PF and PF.Release then
        PF.Release(DL.SHOULDER)
        PF.Release(DL.ZOOM_SPEED_CVAR)
    end
    -- Zeigt sich ein Fenster des Spiels trotzdem, steht es im Bericht.
    for _, name in ipairs({ "GossipFrame", "QuestFrame" }) do
        local f = _G[name]
        if type(f) == "table" and f.HookScript then
            f:HookScript("OnShow", function()
                if DL.Active() then stats.gameShown = stats.gameShown + 1 DL.gameShownName = name end
            end)
        end
    end
    Apply()
end)
