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
    dlgFocus = true,     -- Kamera schwenkt auf den NPC (6.23.4.0)
    dlgView  = true,     -- gemerkten Blick nutzen, sobald einer gemerkt ist (6.23.3.0)
    dlgViewSaved = false,
    dlgCamDist = 6,      -- so nah (Meter; 6.23.2.2: 6 statt 4)
    dlgShoulder = true,  -- NPC zur Seite (Schulterkamera, 6.23.1.0)
    dlgCamRepair = 0,    -- 6.26.1.0: einmalige Kamerareparatur gelaufen (Fassung)
    dlgSpeed = 35,       -- Zeichen je Sekunde beim Einlaufen (6.23.2.0)
    dlgFade  = true,     -- Oberflaeche ausblenden (6.23.2.0)
}
DL.W = 560
DL.TEXT_SIZE = 17        -- Erzaehltext (6.23.4.0: groesser, Serife)
DL.BODY_MAX = 300        -- hoechstens so hoch, dann rollt der Text
DL.PORTRAIT = 60         -- Bild des NPCs
DL.FADE_IN = 0.35        -- Fenster blendet ein (s)
DL.CAM_MAX = 3           -- (bis 6.23.3.0) so lange wartete der Text hoechstens
DL.TEXT_DELAY = 0.4      -- so lange nach dem Beginn der Kamerafahrt beginnt der Text (s)
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

local stats = { shown = 0, picked = 0, failed = 0, gameShown = 0, warnHidden = 0 }
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

local win, portrait, ring, head, sub, scroll, body, rowsTitle, foot, primary, secondary, close, tip
local rows, items = {}, {}
local reveal, revealLen = nil, 0
local fadeIn = nil                 -- Fenster blendet ein (0..1)
local camWait = nil                -- Sekunden, die der Text schon auf die Kamera wartet

local function Accent() local a = GC.frameAccent return a[1], a[2], a[3] end

-- Serifenschrift fuer Name und Erzaehltext (6.23.4.0, Beta-Test: "etwas
-- groesser und geschmeidiger"): Newsreader liegt seit Jahren in media/fonts
-- (freie Lizenz). Geht sie nicht, bleibt die Schrift von K.NewText.
local function Serif(fs, size, bold)
    local F = WeintCodex.Fonts or {}
    local path = bold and F.serifBold or F.serif
    if not (path and fs and fs.SetFont) then return fs end
    local ok = fs:SetFont(path, size, "")
    if ok == false then K.SetFont(fs, size) return fs end
    if fs.SetShadowOffset then
        fs:SetShadowOffset(1, -1)
        fs:SetShadowColor(0, 0, 0, 0.9)
    end
    return fs
end

-- Tempo des Einlaufens (Zeichen je Sekunde), einstellbar seit 6.23.2.0.
function DL.Speed()
    local v = tonumber(K.Get(KEY, "dlgSpeed")) or DL.DEFAULTS.dlgSpeed
    return math.max(5, v)
end

-- Linie, die zur Mitte hin in Gold aufleuchtet (oder umgekehrt).
local function Fade(tex, fromA, toA)
    local r, g, b = Accent()
    tex:SetColorTexture(1, 1, 1, 1)
    local CC = _G.CreateColor
    if tex.SetGradient and CC then
        local ok = pcall(tex.SetGradient, tex, "HORIZONTAL", CC(r, g, b, fromA), CC(r, g, b, toA))
        if ok then return end
    end
    tex:SetColorTexture(r, g, b, math.max(fromA, toA) * 0.6)
end

-- Zierlinie: Linie – Raute – Linie, in Gold.
local function Ornament(parent)
    local o = CreateFrame("Frame", nil, parent)
    o:SetHeight(9)
    o.l = o:CreateTexture(nil, "ARTWORK")
    o.l:SetHeight(1)
    o.l:SetPoint("LEFT", o, "LEFT", 0, 0)
    o.l:SetPoint("RIGHT", o, "CENTER", -7, 0)
    Fade(o.l, 0, 0.7)
    o.r = o:CreateTexture(nil, "ARTWORK")
    o.r:SetHeight(1)
    o.r:SetPoint("LEFT", o, "CENTER", 7, 0)
    o.r:SetPoint("RIGHT", o, "RIGHT", 0, 0)
    Fade(o.r, 0.7, 0)
    o.d = o:CreateTexture(nil, "ARTWORK")
    o.d:SetTexture(K.MEDIA .. "diamond")
    o.d:SetSize(9, 9)
    o.d:SetPoint("CENTER", o, "CENTER", 0, 0)
    local r, g, b = Accent()
    o.d:SetVertexColor(r, g, b, 0.9)
    return o
end

local function NewButton(parent, w, main)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(w, 30)
    b.bg = b:CreateTexture(nil, "BACKGROUND")
    b.bg:SetAllPoints(b)
    local r, g, bl = Accent()
    if main then b.bg:SetColorTexture(r, g, bl, 0.16) else
        local s = C.surface2
        b.bg:SetColorTexture(s[1], s[2], s[3], 0.9)
    end
    b.border = K.Border(b, 1, r, g, bl, main and 0.75 or 0.25, "BORDER")
    b.t = K.NewText(b, 13)
    b.t:SetPoint("CENTER", b, "CENTER", 0, 0)
    b.hl = b:CreateTexture(nil, "ARTWORK")
    b.hl:SetAllPoints(b)
    b.hl:SetColorTexture(r, g, bl, 0.12)
    b.hl:Hide()
    b:SetScript("OnEnter", function(self) if self.enabled then self.hl:Show() end end)
    b:SetScript("OnLeave", function(self) self.hl:Hide() end)
    return b
end

local function SetButton(b, text, enabled)
    if not text then b:Hide() return end
    b.t:SetText(text)
    local c = enabled and C.textBright or C.textFaint
    b.t:SetTextColor(c[1], c[2], c[3])
    b:SetAlpha(enabled and 1 or 0.55)
    b.enabled = enabled and true or false
    b:Show()
end

local function Row(i)
    local r = rows[i]
    if r then return r end
    r = CreateFrame("Button", nil, win)
    r:SetHeight(34)
    r.bg = r:CreateTexture(nil, "BACKGROUND")
    r.bg:SetAllPoints(r)
    local s = C.surface2
    r.bg:SetColorTexture(s[1], s[2], s[3], 0.55)
    r.hl = r:CreateTexture(nil, "BORDER")
    r.hl:SetAllPoints(r)
    local s3 = C.surface3
    r.hl:SetColorTexture(s3[1], s3[2], s3[3], 0.9)
    r.hl:Hide()
    local ar, ag, ab = Accent()
    r.bar = r:CreateTexture(nil, "ARTWORK")
    r.bar:SetPoint("TOPLEFT", r, "TOPLEFT", 0, 0)
    r.bar:SetPoint("BOTTOMLEFT", r, "BOTTOMLEFT", 0, 0)
    r.bar:SetWidth(2)
    r.bar:SetColorTexture(ar, ag, ab, 0.9)
    r.bar:Hide()
    r.box = CreateFrame("Frame", nil, r)
    r.box:SetSize(20, 20)
    r.box:SetPoint("LEFT", r, "LEFT", 8, 0)
    r.box.border = K.Border(r.box, 1, ar, ag, ab, 0.5, "BORDER")
    r.num = K.NewText(r.box, 11)
    r.num:SetPoint("CENTER", r.box, "CENTER", 0, 0)
    r.num:SetTextColor(ar, ag, ab)
    r.mark = K.NewText(r, 13)
    r.mark:SetPoint("LEFT", r.box, "RIGHT", 10, 0)
    r.mark:SetWidth(12)
    r.label = Serif(K.NewText(r, 15), 15)
    r.label:SetPoint("LEFT", r.mark, "RIGHT", 6, 0)
    r.tag = K.NewText(r, 11)
    r.tag:SetPoint("RIGHT", r, "RIGHT", -12, 0)
    r.tag:SetJustifyH("RIGHT")
    r.label:SetPoint("RIGHT", r.tag, "LEFT", -10, 0)
    r.label:SetJustifyH("LEFT")
    r.label:SetWordWrap(false)
    r:SetScript("OnEnter", function(self) self.hl:Show() self.bar:Show() end)
    r:SetScript("OnLeave", function(self) self.hl:Hide() self.bar:Hide() end)
    r:SetScript("OnClick", function(self) DL.Pick(self.index) end)
    rows[i] = r
    return r
end

local function Tip()
    if tip then return tip end
    -- Eigener Tooltip ohne Elternteil: bleibt sichtbar, wenn die Oberflaeche
    -- ausgeblendet ist (GameTooltip haengt an ihr).
    tip = CreateFrame("GameTooltip", "WeintCodexDialogueTip", nil, "GameTooltipTemplate")
    if tip.SetFrameStrata then tip:SetFrameStrata("TOOLTIP") end
    return tip
end

local function Item(i)
    local b = items[i]
    if b then return b end
    b = CreateFrame("Button", nil, win)
    b:SetSize(40, 40)
    local s = C.surface2
    b.bg = b:CreateTexture(nil, "BACKGROUND")
    b.bg:SetAllPoints(b)
    b.bg:SetColorTexture(s[1], s[2], s[3], 1)
    local r, g, bl = Accent()
    b.border = K.Border(b, 1, r, g, bl, 0.3, "BORDER")
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetPoint("TOPLEFT", b, "TOPLEFT", 2, -2)
    b.icon:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -2, 2)
    b.count = K.NewText(b, 11, "OVERLAY")
    b.count:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -3, 3)
    b.sel = K.Border(b, 2, r, g, bl, 1, "OVERLAY")
    b.sel:SetShown(false)
    b:SetScript("OnEnter", function(self)
        local gt = Tip()
        gt:SetOwner(self, "ANCHOR_RIGHT")
        if gt.SetQuestItem then pcall(gt.SetQuestItem, gt, self.kind, self.index) end
        gt:Show()
    end)
    b:SetScript("OnLeave", function() if tip then tip:Hide() end end)
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

function DL.ShowAll()
    if body and body.SetAlphaGradient then pcall(body.SetAlphaGradient, body, DL.ALL, 0) end
end
DL.ALL = 100000

local function Gradient(at)
    if body.SetAlphaGradient then pcall(body.SetAlphaGradient, body, at, 30) end
end

-- Kamera noch unterwegs? Der Text wartet, hoechstens DL.CAM_MAX Sekunden.
function DL.CamMoving()
    if DL.cam and DL.cam.view then
        local now = _G.GetTime and K.Plain(_G.GetTime())
        return type(now) == "number" and now - DL.cam.view < DL.VIEW_TIME
    end
    local target = DL.cam and DL.cam.target
    if not target then return false end
    local z = _G.GetCameraZoom and K.Plain(_G.GetCameraZoom())
    return type(z) == "number" and z > target + 0.4
end

local function OnUpdate(self, el)
    el = el or 0
    if fadeIn then
        fadeIn = fadeIn + el / DL.FADE_IN
        if fadeIn >= 1 then fadeIn = nil self:SetAlpha(1) else self:SetAlpha(fadeIn) end
    end
    DL.CamSample(el)
    if not reveal then return end
    if camWait then
        camWait = camWait + el
        -- 6.23.4.0 (Beta-Test: "Text soll schon starten waehrend des
        -- Kamerazooms"): nur noch ein kurzer Atemzug, nicht die ganze Fahrt.
        if camWait < DL.TEXT_DELAY then
            Gradient(0)                -- auch hier: nichts zeigen
            return
        end
        camWait = nil
    end
    -- Erst mit dem ersten Zeichen sichtbar (6.23.2.3, Beta-Test: nach
    -- einem zweiten Ansprechen stand der Text kurz ganz da, dann lief er
    -- neu ein - der Verlauf griff erst nach dem neuen Text).
    local ba = K.Plain(body:GetAlpha())
    if type(ba) ~= "number" or ba < 1 then body:SetAlpha(1) end
    reveal = reveal + el * DL.Speed()
    if reveal >= revealLen then
        reveal = nil
        -- Ganz zeigen: Verlauf HINTER dem letzten Zeichen. (0, 0) hiess
        -- "ab Zeichen 0 nichts" - 6.23.2.0 blieb nur der Anfang stehen.
        DL.ShowAll()
        return
    end
    Gradient(math.floor(reveal))
    DL.revealAt = reveal
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

-- Masstab: ohne Elternteil folgt das Fenster nicht von selbst der Oberflaeche.
local function Scale()
    local us = _G.UIParent and K.Plain(_G.UIParent:GetScale())
    us = type(us) == "number" and us > 0 and us or 1
    return us * ((tonumber(K.Get(KEY, "dlgScale")) or 100) / 100)
end

function DL.Build()
    if win then return win end
    -- 6.23.2.0: ohne Elternteil - blendet die Oberflaeche aus, bleibt das
    -- Gespraech stehen.
    win = CreateFrame("Frame", "WeintCodexDialogue", nil)
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
        local sc = K.Plain(self:GetScale())
        local us = _G.UIParent and K.Plain(_G.UIParent:GetScale())
        if type(l) == "number" and type(t) == "number" and type(sc) == "number" and type(us) == "number" and us > 0 then
            -- in Punkten der Oberflaeche merken
            K.Set(KEY, "dlgPos", { x = l * sc / us, y = t * sc / us })
            DL.Place()
        end
    end)
    win:Hide()
    if type(_G.UISpecialFrames) == "table" then table.insert(_G.UISpecialFrames, "WeintCodexDialogue") end
    K.Kachel(win, { alpha = 0.95, shadow = 14 })
    local r, g, b = Accent()
    -- Schimmer von oben und Kante in Gold
    local glow = win:CreateTexture(nil, "BACKGROUND", nil, -6)
    glow:SetPoint("TOPLEFT", win, "TOPLEFT", 1, -1)
    glow:SetPoint("TOPRIGHT", win, "TOPRIGHT", -1, -1)
    glow:SetHeight(110)
    glow:SetColorTexture(1, 1, 1, 1)
    local CC = _G.CreateColor
    if not (glow.SetGradient and CC and pcall(glow.SetGradient, glow, "VERTICAL", CC(r, g, b, 0), CC(r, g, b, 0.10))) then
        glow:SetColorTexture(r, g, b, 0.04)
    end
    local edge = win:CreateTexture(nil, "ARTWORK")
    edge:SetPoint("TOPLEFT", win, "TOPLEFT", 1, -1)
    edge:SetPoint("TOPRIGHT", win, "TOPRIGHT", -1, -1)
    edge:SetHeight(2)
    edge:SetColorTexture(r, g, b, 0.85)

    -- Bild des NPCs im goldenen Ring
    ring = win:CreateTexture(nil, "ARTWORK", nil, 1)
    ring:SetTexture(K.MEDIA .. "disc")
    ring:SetSize(DL.PORTRAIT + 6, DL.PORTRAIT + 6)
    ring:SetPoint("TOPLEFT", win, "TOPLEFT", 18, -18)
    ring:SetVertexColor(r, g, b, 0.9)
    portrait = win:CreateTexture(nil, "ARTWORK", nil, 2)
    portrait:SetSize(DL.PORTRAIT, DL.PORTRAIT)
    portrait:SetPoint("CENTER", ring, "CENTER", 0, 0)
    if win.CreateMaskTexture then
        local mask = win:CreateMaskTexture()
        mask:SetTexture(K.MEDIA .. "disc", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        mask:SetAllPoints(portrait)
        if portrait.AddMaskTexture then pcall(portrait.AddMaskTexture, portrait, mask) end
    end

    head = Serif(K.NewText(win, 22), 22, true)
    head:SetPoint("TOPLEFT", ring, "TOPRIGHT", 14, -8)
    head:SetPoint("RIGHT", win, "RIGHT", -44, 0)
    head:SetJustifyH("LEFT")
    head:SetWordWrap(false)
    local tb = C.textBright
    head:SetTextColor(tb[1], tb[2], tb[3])
    sub = K.NewText(win, 11)
    sub:SetPoint("TOPLEFT", head, "BOTTOMLEFT", 0, -5)
    sub:SetPoint("RIGHT", win, "RIGHT", -20, 0)
    sub:SetJustifyH("LEFT")
    sub:SetWordWrap(false)
    sub:SetTextColor(r, g, b)

    close = CreateFrame("Button", nil, win)
    close:SetSize(26, 24)
    close:SetPoint("TOPRIGHT", win, "TOPRIGHT", -10, -10)
    local x = K.NewText(close, 15)
    x:SetPoint("CENTER", close, "CENTER", 0, 0)
    local m = C.textMuted
    x:SetTextColor(m[1], m[2], m[3])
    x:SetText("\195\151")
    close:SetScript("OnClick", function() DL.Close() end)

    win.orn = Ornament(win)
    win.orn:SetPoint("TOPLEFT", win, "TOPLEFT", 20, -(18 + DL.PORTRAIT + 6 + 14))
    win.orn:SetPoint("RIGHT", win, "RIGHT", -20, 0)

    scroll = CreateFrame("ScrollFrame", nil, win)
    scroll:SetPoint("TOPLEFT", win.orn, "BOTTOMLEFT", 4, -14)
    scroll:SetWidth(DL.W - 48)
    scroll:EnableMouseWheel(true)
    local child = CreateFrame("Frame", nil, scroll)
    child:SetWidth(DL.W - 48)
    body = Serif(K.NewText(child, DL.TEXT_SIZE), DL.TEXT_SIZE)
    body:SetPoint("TOPLEFT", child, "TOPLEFT", 0, 0)
    body:SetWidth(DL.W - 48)
    body:SetJustifyH("LEFT")
    body:SetSpacing(6)
    local t = C.textNormal
    body:SetTextColor(t[1], t[2], t[3])
    scroll:SetScrollChild(child)
    scroll.child = child
    scroll:SetScript("OnMouseWheel", function(self, d)
        local max = K.Plain(self:GetVerticalScrollRange()) or 0
        local v = (K.Plain(self:GetVerticalScroll()) or 0) - d * 30
        self:SetVerticalScroll(math.max(0, math.min(type(max) == "number" and max or 0, v)))
    end)

    win.orn2 = Ornament(win)
    win.orn2:SetPoint("RIGHT", win, "RIGHT", -20, 0)
    rowsTitle = K.NewText(win, 11)
    rowsTitle:SetTextColor(r, g, b)
    rowsTitle:SetJustifyH("LEFT")
    foot = K.NewText(win, 10)
    foot:SetPoint("BOTTOMLEFT", win, "BOTTOMLEFT", 20, 22)
    local f = C.textFaint
    foot:SetTextColor(f[1], f[2], f[3])

    primary = NewButton(win, 140, true)
    primary:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", -20, 14)
    primary:SetScript("OnClick", function() DL.Primary() end)
    secondary = NewButton(win, 110, false)
    secondary:SetPoint("RIGHT", primary, "LEFT", -10, 0)
    secondary:SetScript("OnClick", function() DL.Secondary() end)

    win:SetScript("OnKeyDown", OnKey)
    win:SetScript("OnUpdate", OnUpdate)
    win:SetScript("OnHide", function()
        reveal, camWait, fadeIn = nil, nil, nil
        if tip then tip:Hide() end
        DL.CamLater()
        DL.FadeLater()
    end)
    DL.win, DL.body = win, body
    return win
end

--------------------------------------------------
-- Inhalt je Zustand
--------------------------------------------------

DL.list = {}             -- { { text, mark, kind, id, status }, ... } die gezeigten Zeilen
-- Aussehen je Status (6.23.2.2, Beta-Test: abgeschlossen und offen sahen
-- gleich aus). Abgabebereit: Gold und gruenes Etikett; laeuft: alles grau;
-- neu: Gold. Gruen ist Statusfarbe, kein zweiter Akzent.
DL.LOOK = {
    done = { mark = "accent", label = "textBright", tag = "Abgeben", tagColor = "green" },
    open = { mark = "textFaint", label = "textMuted", tag = "Läuft noch", tagColor = "textFaint" },
    new  = { mark = "accent", label = "textBright", tag = "Neu", tagColor = "accent" },
    none = { mark = "textMuted", label = "textBright" },
}
DL.rewards = {}          -- { { kind, index, name, tex, count }, ... }

-- status: "done" (abgabebereit), "open" (laeuft noch), "new" (angeboten),
-- nil (Antwort, oder der Client sagt es nicht - dann kein Etikett).
local function AddLine(text, mark, kind, id, status)
    local l = DL.list
    if #l >= DL.MAX_ROWS then return end
    l[#l + 1] = { text = text, mark = mark, kind = kind, id = id, status = status }
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
            local done = K.Bool(q.isComplete, false)
            AddLine(Str(q.title), "?", "active", Plain(q.questID), done and "done" or "open")
        end
        for _, q in ipairs(gi.GetAvailableQuests and gi.GetAvailableQuests() or {}) do
            AddLine(Str(q.title), "!", "available", Plain(q.questID), "new")
        end
        local opts = gi.GetOptions() or {}
        table.sort(opts, function(a, b) return (Plain(a.orderIndex) or 0) < (Plain(b.orderIndex) or 0) end)
        for _, o in ipairs(opts) do AddLine(Str(o.name), "›", "option", Plain(o.gossipOptionID)) end
    elseif state == "greeting" then
        c.text = Str(Call("GetGreetingText"))
        for i = 1, Num("GetNumActiveQuests") do
            local title, done = Call("GetActiveTitle", i)
            done = Plain(done)
            local st = done == true and "done" or done == false and "open" or nil
            AddLine(Str(title), "?", "gactive", i, st)
        end
        for i = 1, Num("GetNumAvailableQuests") do AddLine(Str(Call("GetAvailableTitle", i)), "!", "gavailable", i, "new") end
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
    local first = not win:IsShown()
    win:SetScale(Scale())
    if first then DL.Place() end
    head:SetText(c.npc)
    local subText = (c.title and c.title ~= "") and c.title or "Gespräch"
    sub:SetText(WeintCodex.Upper and WeintCodex.Upper(subText) or subText)
    if _G.SetPortraitTexture then pcall(_G.SetPortraitTexture, portrait, "npc") end
    body:SetText(c.text ~= "" and c.text or " ")
    local th = K.Plain(body:GetStringHeight())
    th = type(th) == "number" and th or 14
    scroll.child:SetHeight(th)
    local bh = math.min(DL.BODY_MAX, th)
    scroll:SetHeight(bh)
    scroll:SetVerticalScroll(0)
    local y = 18 + DL.PORTRAIT + 6 + 14 + 9 + 14 + bh + 18     -- Kopf, Zierlinie, Text

    -- Belohnungen / benoetigte Gegenstaende
    local shownItems = 0
    local label
    if #DL.rewards > 0 or c.extra then
        label = c.state == "progress" and "Benötigt" or (c.choices and c.choices > 1 and "Belohnung – wähle eine" or "Belohnung")
    end
    if label then
        rowsTitle:ClearAllPoints()
        rowsTitle:SetPoint("TOPLEFT", win, "TOPLEFT", 22, -y)
        local up = WeintCodex.Upper and WeintCodex.Upper(label) or label
        rowsTitle:SetText(up .. (c.extra and ("     " .. WeintCodex.ColorText("textNormal", c.extra)) or ""))
        rowsTitle:Show()
        y = y + 20
        for i, rw in ipairs(DL.rewards) do
            local b = Item(i)
            b.kind, b.index = rw.kind, rw.index
            b.icon:SetTexture(rw.tex)
            b.count:SetText((type(rw.count) == "number" and rw.count > 1) and rw.count or "")
            b.sel:SetShown(rw.kind == "choice" and DL.choice == rw.index)
            b:ClearAllPoints()
            b:SetPoint("TOPLEFT", win, "TOPLEFT", 22 + (i - 1) * 46, -y)
            b:Show()
            shownItems = i
        end
        if shownItems > 0 then y = y + 46 end
        y = y + 6
    else
        rowsTitle:Hide()
    end
    for i = shownItems + 1, #items do items[i]:Hide() end

    -- Zeilen (Antworten, Quests), mit Zierlinie davor
    if #DL.list > 0 then
        win.orn2:ClearAllPoints()
        win.orn2:SetPoint("TOPLEFT", win, "TOPLEFT", 20, -y)
        win.orn2:SetPoint("RIGHT", win, "RIGHT", -20, 0)
        win.orn2:Show()
        y = y + 9 + 12
    else
        win.orn2:Hide()
    end
    for i, l in ipairs(DL.list) do
        local r = Row(i)
        r.index = i
        r.num:SetText(i <= 9 and tostring(i) or "")
        r.box:SetShown(i <= 9)
        r.mark:SetText(l.mark)
        local ar, ag, ab = Accent()
        local m = C.textMuted
        local look = DL.LOOK[l.status or "none"]
        local mc = look.mark == "accent" and { ar, ag, ab } or C[look.mark]
        r.mark:SetTextColor(mc[1], mc[2], mc[3])
        r.label:SetText(l.text)
        local t = C[look.label]
        r.label:SetTextColor(t[1], t[2], t[3])
        r.tag:SetText(look.tag or "")
        local tc = look.tagColor == "accent" and { ar, ag, ab } or C[look.tagColor or "textMuted"]
        r.tag:SetTextColor(tc[1], tc[2], tc[3])
        r:ClearAllPoints()
        r:SetPoint("TOPLEFT", win, "TOPLEFT", 18, -y)
        r:SetPoint("RIGHT", win, "RIGHT", -18, 0)
        r:Show()
        y = y + 38
    end
    for i = #DL.list + 1, #rows do rows[i]:Hide() end

    SetButton(primary, c.primary, c.canPrimary)
    SetButton(secondary, c.secondary, true)
    local keys = K.Get(KEY, "dlgKeys")
    foot:SetText(keys and ((#DL.list > 0 and "1–9 wählen · " or "") .. (c.primary and "Leertaste: " .. c.primary .. " · " or "") .. "Esc schließt") or "")
    win:SetHeight(y + 8 + 52)

    -- Text laeuft ein - erst, wenn die Kamera angekommen ist.
    if K.Get(KEY, "dlgType") and body.SetAlphaGradient then
        revealLen = (WeintCodex.Utf8Len and WeintCodex.Utf8Len(c.text)) or #c.text
        reveal = 0
        camWait = 0
        body:SetAlpha(0)
        Gradient(0)
    else
        reveal, camWait = nil, nil
        body:SetAlpha(1)
        DL.ShowAll()
    end
    local combat = _G.InCombatLockdown and K.Bool(_G.InCombatLockdown(), false)
    win:EnableKeyboard(keys and not combat and true or false)
    if first then
        fadeIn = 0
        win:SetAlpha(0)
    end
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

-- GEMERKTER BLICK (6.23.3.0, Beta-Test: "Kamerawinkel aendern, immer
-- diese Position"): Addons erfahren weder die Lage des NPCs noch die
-- Richtung der Kamera - einen Winkel ausrechnen geht nicht. Die Ansichten
-- des Spiels aber schon: der Spieler stellt den Blick einmal ein und merkt
-- ihn (SaveView in Ansicht DL.VIEW_TALK); im Gespraech wird der Blick von
-- vorher in DL.VIEW_BACK gelegt und der gemerkte genommen (SetView, das
-- Spiel gleitet hinueber), danach zurueck. Die Ansicht gilt relativ zum
-- eigenen Charakter. Belegt die Ansichten 4 und 5 des Spiels.
DL.VIEW_TALK = 5
DL.VIEW_BACK = 4
DL.VIEW_TIME = 1.5       -- so lange gleitet die Kamera (Text wartet)

-- BLICK AUF DEN NPC (6.23.4.0, Beta-Test: gemerkter Blick "sieht komisch
-- aus, wenn ich mich anders positioniere"; Bild aus DialogueUI als Ziel).
-- Das Spiel hat eine eigene Kamera, die beim Ansprechen auf das Ziel
-- schwenkt (Testeinstellungen test_cameraTargetFocusInteract*). Sie greift
-- nur, wenn die beiden Schalter gegen Reiseuebelkeit aus sind
-- (CameraKeepCharacterCentered, CameraReduceUnexpectedMovement). Alle fuenf
-- ueber DL.QuietSet (Warnung still, Wert von vorher gemerkt), nach dem
-- Gespraech ueber PF.Release zurueck - auch nach einem Absturz beim
-- Einloggen. Hat Vorrang vor dem gemerkten Blick.
DL.FOCUS = {
    { "test_cameraTargetFocusInteractEnable", 1 },
    { "test_cameraTargetFocusInteractStrengthYaw", 1 },
    { "test_cameraTargetFocusInteractStrengthPitch", 0.6 },
    { "CameraKeepCharacterCentered", 0 },
    { "CameraReduceUnexpectedMovement", 0 },
}

local function FocusIn()
    if not K.Get(KEY, "dlgFocus") or DL.cam.focus then return false end
    local any = false
    for _, c in ipairs(DL.FOCUS) do
        if DL.QuietSet(c[1], c[2]) then any = true end
    end
    DL.cam.focus = any
    return any
end
local function FocusOut()
    if not DL.cam.focus then return end
    DL.cam.focus = false
    local PF = WeintCodex.UIProfile
    if not (PF and PF.Release) then return end
    for _, c in ipairs(DL.FOCUS) do PF.Release(c[1]) end
end
DL.FocusOut = FocusOut

function DL.ViewUsable()
    return K.Get(KEY, "dlgView") and K.Get(KEY, "dlgViewSaved") and not K.Get(KEY, "dlgFocus")
        and type(_G.SaveView) == "function" and type(_G.SetView) == "function" and true or false
end

function DL.RememberView()
    if type(_G.SaveView) ~= "function" then
        Say("Das Spiel kennt keine gespeicherten Ansichten – der Blick lässt sich nicht merken.")
        return false
    end
    _G.SaveView(DL.VIEW_TALK)
    K.Set(KEY, "dlgViewSaved", true)
    Say("Blick gemerkt – so schaut die Kamera ab jetzt bei jedem Gespräch.")
    return true
end

function DL.CamIn()
    if not K.Get(KEY, "dlgCam") or DL.cam.saved or DL.cam.view then return false end
    SpeedIn()
    FocusIn()
    if DL.ViewUsable() then
        _G.SaveView(DL.VIEW_BACK)
        _G.SetView(DL.VIEW_TALK)
        local now = _G.GetTime and K.Plain(_G.GetTime())
        DL.cam.view = type(now) == "number" and now or 0
        return true
    end
    ShoulderIn()                       -- nur ohne gemerkten Blick
    local z = Zoom()
    local target = tonumber(K.Get(KEY, "dlgCamDist")) or DL.DEFAULTS.dlgCamDist
    if not (z and _G.CameraZoomIn) or z <= target + 0.5 then return false end
    DL.cam.saved, DL.cam.target = z, target
    DL.CamStartLog(z)
    _G.CameraZoomIn(z - target)
    return true
end

-- Messung fuer /wcui pruefen: Abstand beim Start und nach 0,5/1/2/3 s.
DL.camLog = { start = nil, t = 0, at = {} }
DL.CAM_MARKS = { 0.5, 1, 2, 3 }
function DL.CamStartLog(z)
    local l = DL.camLog
    l.start, l.t = z, 0
    for i = 1, #DL.CAM_MARKS do l.at[i] = nil end
end
function DL.CamSample(el)
    local l = DL.camLog
    if not l.start or l.t > DL.CAM_MARKS[#DL.CAM_MARKS] then return end
    l.t = l.t + (el or 0)
    for i, m in ipairs(DL.CAM_MARKS) do
        if not l.at[i] and l.t >= m then
            local z = _G.GetCameraZoom and K.Plain(_G.GetCameraZoom())
            l.at[i] = type(z) == "number" and z or -1
        end
    end
end

function DL.CamOut()
    if win and win:IsShown() then return false end
    ShoulderOut()
    FocusOut()
    if DL.cam.view then
        DL.cam.view = nil
        _G.SetView(DL.VIEW_BACK)
        local t = _G.C_Timer
        if t and t.After then t.After(DL.SPEED_BACK, SpeedBack) end
        return true
    end
    local saved = DL.cam.saved
    if not saved then return false end
    DL.cam.saved, DL.cam.target = nil, nil
    local z = Zoom()
    local t = _G.C_Timer
    if t and t.After then t.After(DL.SPEED_BACK, SpeedBack) end
    if not (z and _G.CameraZoomOut) or z >= saved - 0.5 then return false end
    _G.CameraZoomOut(saved - z)
    return true
end

local function CamOutNow() DL.CamOut() end
function DL.CamLater()
    if not (DL.cam.saved or DL.cam.shoulder or DL.cam.view or DL.cam.focus) then return end
    local t = _G.C_Timer
    if t and t.After then t.After(DL.CAM_WAIT, CamOutNow) else DL.CamOut() end
end

function DL.Show(state)
    if not DL.Active() then return false end
    if state ~= "complete" then DL.choice = nil end
    DL.state = state
    DL.CamIn()                         -- sofort, vor dem Aufbau
    DL.FadeOut()
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
    DL.FadeBack(true)
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
        reveal, camWait = revealLen, nil
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
-- Oberflaeche ausblenden (6.23.2.0, Beta-Test: "langsam das Interface
-- ausblenden, ausser Questtext und Interaktion; danach alles wieder")
--------------------------------------------------
-- UIParent wird langsam durchsichtig; das Gespraechsfenster und sein
-- Tooltip haben KEIN Elternteil und bleiben. Nur ausserhalb des Kampfes;
-- beginnt ein Kampf oder erscheint ein Dialog des Spiels (StaticPopup,
-- etwa eine Rueckfrage zur Antwort), kommt die Oberflaeche sofort zurueck.
-- Mausklicks gehen weiter an die unsichtbaren Leisten - das ist der Preis
-- dafuer, nichts zu verstecken, was das Spiel im Kampf braucht.

DL.FADE_OUT = 0.8        -- so lange blendet die Oberflaeche aus (s)
DL.FADE_BACK = 0.5       -- und so lange wieder ein
DL.FADE_TO = 0           -- bis auf diese Deckkraft
DL.fade = { from = nil, to = nil, t = 0, dur = 1, orig = nil, on = false }

-- Was der Durchsichtigkeit nicht folgt (6.23.2.1, Beta-Test: Portraets,
-- Spielerpfeil und Symbole der Minikarte blieben stehen): 3D-Modelle
-- (K.models) und die Minikarte werden versteckt, solange ausgeblendet ist,
-- und nur die zurueckgezeigt, die vorher sichtbar waren.
DL.hidden = {}
DL.EXTRA = { "MinimapCluster", "Minimap" }
local function Take(f)
    local h = DL.hidden
    if type(f) == "table" and f.IsShown and f:IsShown() and not h[f] then
        h[f] = true
        f:Hide()
    end
end
function DL.HideExtras()
    if DL.fade.extras then return end
    DL.fade.extras = true
    for m in pairs(K.models or {}) do Take(m) end
    for _, name in ipairs(DL.EXTRA) do Take(_G[name]) end
end
function DL.ShowExtras()
    DL.fade.extras = false
    for f in pairs(DL.hidden) do
        if f.Show then pcall(f.Show, f) end
        DL.hidden[f] = nil
    end
end

local fader = CreateFrame("Frame")
fader:Hide()
fader:SetScript("OnUpdate", function(self, el)
    local f = DL.fade
    local up = _G.UIParent
    f.t = f.t + (el or 0)
    local k = math.min(1, f.t / f.dur)
    k = k * k * (3 - 2 * k)                -- weich an beiden Enden
    if up then up:SetAlpha(f.from + (f.to - f.from) * k) end
    -- Was nicht mitblendet, verschwindet auf halbem Weg.
    if DL.fade.on and k >= 0.5 then DL.HideExtras() end
    if k >= 1 then self:Hide() end
end)
DL.fader = fader

-- Ein Dialog des Spiels erscheint. Die Warnung zu Testeinstellungen kam
-- trotz abgemeldetem Ereignis (6.23.2.1, Beta-Test: beim ersten Gespraech
-- kurz da, danach nichts ausgeblendet) - sie wird hier geschlossen und
-- holt die Oberflaeche NICHT zurueck. Jeder andere Dialog schon.
function DL.IsWarning(pop)
    local which = type(pop) == "table" and K.Plain(pop.which)
    return type(which) == "string" and (which == DL.WARNING or which:find("EXPERIMENTAL", 1, true) ~= nil)
end
function DL.OnPopup(pop)
    if DL.IsWarning(pop) then
        stats.warnHidden = stats.warnHidden + 1
        if _G.StaticPopup_Hide then pcall(_G.StaticPopup_Hide, K.Plain(pop.which)) end
        if pop.IsShown and pop:IsShown() then pop:Hide() end
        return
    end
    DL.FadeBack(true)
end

local function Run(to, dur)
    local up = _G.UIParent
    if not up then return end
    local a = K.Plain(up:GetAlpha())
    local f = DL.fade
    f.from, f.to, f.t, f.dur = type(a) == "number" and a or 1, to, 0, dur
    fader:Show()
end

function DL.FadeOut()
    if not K.Get(KEY, "dlgFade") or DL.fade.on then return false end
    if _G.InCombatLockdown and K.Bool(_G.InCombatLockdown(), false) then return false end
    local up = _G.UIParent
    local a = up and K.Plain(up:GetAlpha())
    DL.fade.orig = type(a) == "number" and a or 1
    DL.fade.on = true
    Run(DL.FADE_TO, DL.FADE_OUT)
    return true
end

-- Zurueck: weich (Ende des Gespraechs) oder sofort (Kampf, Dialog).
function DL.FadeBack(now)
    if not DL.fade.on then return false end
    DL.fade.on = false
    DL.ShowExtras()
    local orig = DL.fade.orig or 1
    if now then
        fader:Hide()
        if _G.UIParent then _G.UIParent:SetAlpha(orig) end
    else
        Run(orig, DL.FADE_BACK)
    end
    return true
end

local function FadeBackSoft() if not (win and win:IsShown()) then DL.FadeBack(false) end end
function DL.FadeLater()
    if not DL.fade.on then return end
    local t = _G.C_Timer
    if t and t.After then t.After(DL.CAM_WAIT, FadeBackSoft) else FadeBackSoft() end
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
    if event == "PLAYER_REGEN_DISABLED" then DL.FadeBack(true) return end
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
    if on then pcall(ev.RegisterEvent, ev, "PLAYER_REGEN_DISABLED") end
    if on then DL.TakeOver() else
        DL.FadeBack(true)
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
    local PF = WeintCodex.UIProfile
    if PF and PF.GetCVar then
        local parts = {}
        local names = {}
        for _, name in ipairs(DL.REPAIR) do names[#names + 1] = name end
        for _, name in ipairs(DL.WATCH) do names[#names + 1] = name end
        for _, name in ipairs(names) do
            local now, def = PF.GetCVar(name), PF.GetCVarDefault and PF.GetCVarDefault(name)
            local mark = (now and def and not PF.Same(now, def)) and (" (ab Werk " .. def .. ")") or ""
            parts[#parts + 1] = name:gsub("^test_camera", "") .. "=" .. tostring(now) .. mark
        end
        out[#out + 1] = "Kamera: " .. table.concat(parts, " · ")
            .. " · Reparatur: " .. (DL.repaired and (DL.repaired .. " zurückgesetzt") or "nicht gelaufen")
    end
    local n = 0
    for _, took in pairs(DL.taken) do n = n + #took end
    out[#out + 1] = "Gesprächsdaten (C_GossipInfo): " .. (DL.Usable() and "ja" or "nein")
        .. " · Ereignisse übernommen: " .. n
    out[#out + 1] = string.format("Gezeigt %d · gewählt %d · gescheitert %d · Warnung zur Testeinstellung geschlossen %d",
        stats.shown, stats.picked, stats.failed, stats.warnHidden)
    if DL.lastError then out[#out + 1] = "Zuletzt gescheitert: " .. DL.lastError end
    local fv = {}
    for _, c in ipairs(DL.FOCUS) do
        local PF = WeintCodex.UIProfile
        local v = PF and PF.GetCVar and PF.GetCVar(c[1])
        fv[#fv + 1] = c[1]:gsub("^test_camera", ""):gsub("TargetFocusInteract", "Fokus") .. "=" .. tostring(v or "–")
    end
    out[#out + 1] = "Blick auf den NPC: " .. (K.Get(KEY, "dlgFocus") and "an" or "aus") .. " · " .. table.concat(fv, " · ")
    out[#out + 1] = "Gemerkter Blick: " .. (K.Get(KEY, "dlgViewSaved") and (K.Get(KEY, "dlgView") and "an" or "gemerkt, aber aus") or "keiner gemerkt")
        .. " · Ansichten des Spiels (SaveView/SetView): " .. ((type(_G.SaveView) == "function" and type(_G.SetView) == "function") and "ja" or "nein")
    local l = DL.camLog
    if l.start then
        local parts = {}
        for i, m in ipairs(DL.CAM_MARKS) do
            parts[#parts + 1] = string.format("%.1f s: %s", m, l.at[i] and string.format("%.1f", l.at[i]) or "–")
        end
        out[#out + 1] = string.format("Kamera zuletzt: von %.1f · ", l.start) .. table.concat(parts, " · ")
    end
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
            description = "Erst wenn die Kamera da ist. Leertaste zeigt ihn sofort ganz." },
          { type = "slider", label = "Tempo des Textes", key = "dlgSpeed", min = 10, max = 120, step = 5,
            disabled = function() return off() or not K.Get(KEY, "dlgType") end,
            format = function(v) return string.format("%d Zeichen/s", v) end })
    B:Row({ type = "toggle", label = "Oberfläche ausblenden", key = "dlgFade", disabled = off,
            description = "Leisten, Rahmen und Chat blenden langsam aus und danach wieder ein. Nicht im Kampf." },
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
    B:Row({ type = "toggle", label = "Kamera auf den NPC richten", key = "dlgFocus", disabled = camOff,
            description = "Die Kamera des Spiels schwenkt auf dein Gegenüber. Nutzt Testeinstellungen des Spiels und schaltet dafür kurz „Charakter zentriert halten“ aus; danach alles zurück." },
          { type = "empty" })
    B:Row({ type = "toggle", label = "Gemerkten Blick nutzen", key = "dlgView",
            disabled = function() return camOff() or K.Get(KEY, "dlgFocus") end,
            description = "Nur ohne „Kamera auf den NPC richten“: die Kamera gleitet in den Blick, den du gemerkt hast. Belegt die Ansichten 4 und 5 des Spiels." },
          { type = "button", label = "Blick", text = "Diesen Blick merken", disabled = camOff,
            onClick = function() DL.RememberView() end })
    B:Row({ type = "button", label = "Kamera", text = "Kamera zurücksetzen",
            onClick = function()
                local n = DL.RepairCamera(true)
                Say(n == nil and "Erst das Gespräch schließen." or
                    ("Kamera zurückgesetzt – " .. n .. " Einstellungen wieder ab Werk."))
            end },
          { type = "empty" })
    B:Note("Folgt die Kamera beim Laufen nicht mehr wie eingestellt, setzt „Kamera zurücksetzen“ die Kamera-Einstellungen, die das Folgen steuern, auf den Wert ab Werk – auch „Charakter zentriert halten“ und den Kamera-Verfolgungsstil.")
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
-- KAMERA REPARIEREN (6.26.1.0). Bis 6.26.0.0 konnte PF.Release einen
-- Wert stehen lassen (Textvergleich "-1" gegen "-1.000000", siehe
-- ui/profile.lua) - am haeufigsten die Schulter (test_cameraOverShoulder)
-- und die Staerke des Blicks. Testeinstellungen der Kamera schalten die
-- "Action Cam" des Spiels zu; mit ihr folgt die Kamera beim Laufen nicht
-- mehr wie eingestellt. Die Reparatur setzt die Testeinstellungen und das
-- Zoomtempo auf den Wert ab Werk, ausser mitten im Gespraech. Die beiden
-- Schalter gegen Reiseuebelkeit fasst sie NICHT an - die kann der Spieler
-- selbst gesetzt haben; der Bericht nennt sie.
DL.REPAIR = { "test_cameraOverShoulder", "test_cameraTargetFocusInteractEnable",
              "test_cameraTargetFocusInteractStrengthYaw", "test_cameraTargetFocusInteractStrengthPitch",
              "cameraZoomSpeed" }
DL.REPAIR_VERSION = 1
-- 6.26.2.0 (gemessen: alle aus DL.REPAIR ab Werk, die Kamera folgt trotzdem
-- nicht): was das Folgen beim Laufen steuert, steht im Bericht samt Wert ab
-- Werk. Der Knopf "Kamera zurücksetzen" (Wunsch des Spielers, kein
-- Automatismus) setzt auch diese zurueck - auch die Ansicht, die
-- SetView beim gemerkten Blick gewechselt hat (cameraView).
DL.WATCH = { "cameraView", "cameraSmoothStyle", "cameraSmoothTrackingStyle",
             "CameraKeepCharacterCentered", "CameraReduceUnexpectedMovement",
             "test_cameraDynamicPitch", "test_cameraHeadMovementStrength" }
DL.repaired = nil
function DL.RepairCamera(all)
    if win and win:IsShown() then return nil end
    local PF = WeintCodex.UIProfile
    if not (PF and PF.GetCVarDefault and PF.RawSet) then return nil end
    local n = 0
    local function One(name)
        local def, now = PF.GetCVarDefault(name), PF.GetCVar(name)
        if def and now and not PF.Same(def, now) and PF.RawSet(name, def) then n = n + 1 end
        if PF.ForgetCVar then PF.ForgetCVar(name) end
    end
    for _, name in ipairs(DL.REPAIR) do One(name) end
    if all then for _, name in ipairs(DL.WATCH) do One(name) end end
    DL.cam.shoulder, DL.cam.focus, DL.cam.speed = false, false, false
    DL.repaired = n
    return n
end

function DL.Boot()
    -- Einmal je Konto: was alte Fassungen stehen liessen (6.26.1.0).
    if (tonumber(K.Get(KEY, "dlgCamRepair")) or 0) < DL.REPAIR_VERSION then
        if DL.RepairCamera() then K.Set(KEY, "dlgCamRepair", DL.REPAIR_VERSION) end
    end
    -- Abgestuerzt mitten im Gespraech: die Schulter steht noch - zurueck.
    local PF = WeintCodex.UIProfile
    if PF and PF.Release then
        PF.Release(DL.SHOULDER)
        PF.Release(DL.ZOOM_SPEED_CVAR)
        for _, c in ipairs(DL.FOCUS) do PF.Release(c[1]) end
    end
    -- Ein Dialog des Spiels braucht die Oberflaeche: sofort zurueck.
    for i = 1, 4 do
        local pop = _G["StaticPopup" .. i]
        if type(pop) == "table" and pop.HookScript then
            pop:HookScript("OnShow", DL.OnPopup)
        end
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
end
boot:SetScript("OnEvent", function() DL.Boot() end)
