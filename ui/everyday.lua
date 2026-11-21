--------------------------------------------------
-- WeintCodex :: Komfort - Seite "Bequem" (1.0.8.0)
--------------------------------------------------
-- Wunsch (grosses Update, nach dem Vergleich mit OneForAll - GPL-3.0, nur
-- das Verhalten nachgebaut, eigener Code). Alles ab Werk aus.
--   QUESTS     annehmen und abgeben ohne Klick. Mehrere Belohnungen zur
--              Wahl: nie - die Wahl bleibt beim Spieler. Umschalt beim
--              Ansprechen haelt alles an.
--   TOOLTIP    am Mauszeiger statt in der Ecke (wo das Spiel ihn selbst
--              setzt, GameTooltip_SetDefaultAnchor); auf Wunsch nicht in
--              Dungeon/Schlachtfeld.
--   GROESSE    Fenster des Spiels mit Strg + Mausrad groesser/kleiner,
--              gemerkt je Fenster (kontoweit). Geschuetzte nie im Kampf.
--   EINLADEN   Fluestert ein Freund oder Gildenmitglied das Schluesselwort,
--              laedt WeintCodex ein (nur ohne Gruppe oder als Leiter).
--   DUELLE     ablehnen - ausser von Freunden und der Gilde.
--   CHAT       Pfeiltasten holen gesendete Zeilen zurueck (ohne Alt, eigene
--              Liste seit 1.0.8.8, nur diese Sitzung);
--              ein Knopf blendet den Chat aus/ein, auf Wunsch von selbst
--              nach einer Zeit ohne neue Nachricht.
--   ENTZAUBERN im Tooltip gruener/blauer/epischer Ruestung und Waffen, was
--              Entzaubern im Mittel bringt - Ertrag nach Classic (Art
--              `classic`), Preise aus den eigenen Auktionspreisen. Fehlt ein
--              Preis, steht keine Zahl da.
--   FLUGKARTE  am Flugmeister gleich die Karte, wenn er nichts anderes hat.
--   TEILEN     im Dungeon mit Gruppe: welche Quests des Dungeons du hast
--              und wer sie noch braucht - mit "Teilen".
-- Nichts davon sendet etwas; "Teilen" nutzt das Teilen des Spiels.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIEveryday = {}

local EV = WeintCodex.UIEveryday
local K  = WeintCodex.UIKit
local C  = WeintCodex.Colors
local KEY = "comfort"

EV.DEFAULTS = {
    questAccept = false, questTurnIn = false,
    tipMouse = false, tipMousePos = "ANCHOR_CURSOR_RIGHT", tipMouseInst = true,
    winScale = false,
    inviteWord = false, inviteText = "inv",
    duelDecline = false,
    chatArrows = false, chatButton = false, chatAutoHide = 0,
    deValue = false,
    taxiDirect = false,
    questShare = false,
}

local function Opt(k) return K.IsActive(KEY) and K.Get(KEY, k) and true or false end
local function P(v) return K.Plain(v) end
local function Say(text) print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " " .. text) end
local function Shift() return _G.IsShiftKeyDown and K.Bool(P(_G.IsShiftKeyDown()), false) or false end
local function Later(sec, fn) if _G.C_Timer and _G.C_Timer.After then _G.C_Timer.After(sec, fn) else fn() end end
EV.Opt = Opt

--------------------------------------------------
-- Quests annehmen und abgeben
--------------------------------------------------
EV.quest = { accepted = 0, turned = 0, left = 0, stuck = 0, closed = 0 }

-- 1.0.8.8 (Rueckmeldung: "manchmal hakt die automatische Questannahme,
-- dann geht es nicht weiter"). Bis 1.0.8.7 rief WeintCodex AcceptQuest
-- genau einmal und schloss das Fenster 0,1 s spaeter blind - drei Wege,
-- haengen zu bleiben:
--   * nahm das Spiel die Annahme nicht (Quest noch nicht bereit), schloss
--     WeintCodex das Fenster trotzdem - Quest nicht angenommen, nichts zu
--     sehen;
--   * mit "Gespraeche im Codex-Stil" stand die Detailseite im eigenen
--     Fenster, nicht im QuestFrame - das Schliessen sah sie nicht, das
--     Fenster blieb mit der schon angenommenen Quest stehen;
--   * "Abgeben" und "Belohnung" fragten nur einmal - waren die Gegenstaende
--     beim Ereignis noch nicht geladen, blieb es beim Spieler.
-- Jetzt: annehmen, pruefen (Questlog oder QUEST_ACCEPTED), sonst bis zu
-- EV.ACCEPT_TRIES mal neu; geschlossen wird erst, wenn die Quest sicher im
-- Log ist. Klappt es nicht, bleibt das Fenster fuer den Spieler offen.
EV.ACCEPT_TRIES, EV.ACCEPT_WAIT = 3, 0.4
EV.RETRY = { 0.3, 1.0 }    -- Abgeben/Belohnung: noch einmal fragen nach ... s

local function Shown(f) return type(f) == "table" and f.IsShown and K.Bool(P(f:IsShown()), false) or false end
local function QuestID()
    if not _G.GetQuestID then return nil end
    local ok, id = pcall(_G.GetQuestID)
    id = ok and P(id) or nil
    return type(id) == "number" and id > 0 and id or nil
end
-- true/false, nil = der Client sagt es nicht
local function InLog(id)
    local ql = _G.C_QuestLog
    if not (id and ql) then return nil end
    if ql.GetLogIndexForQuestID then
        local ok, i = pcall(ql.GetLogIndexForQuestID, id)
        i = ok and P(i) or nil
        if type(i) == "number" then return i > 0 end
        if ok then return false end
    end
    if ql.IsOnQuest then
        local ok, on = pcall(ql.IsOnQuest, id)
        if ok then return K.Bool(P(on), false) end
    end
    return nil
end
-- Welche Seite des Questgebers steht gerade - im Fenster des Spiels oder im
-- Codex-Stil?
local PANELS = { detail = "QuestFrameDetailPanel", progress = "QuestFrameProgressPanel", complete = "QuestFrameRewardPanel" }
function EV.QuestPage(kind)
    if Shown(_G.QuestFrame) and Shown(_G[PANELS[kind]]) then return true end
    local DL = WeintCodex.UIDialogue
    return DL ~= nil and DL.state == kind
end
EV.InLog, EV.QuestID = InLog, QuestID

function EV.OnQuestDetail()
    if not Opt("questAccept") or Shift() then return false end
    if not _G.AcceptQuest then return false end
    EV.pending = { id = QuestID(), tries = 0 }
    -- Quests, die das Spiel selbst annimmt: nur bestaetigen und schliessen.
    local auto = _G.QuestGetAutoAccept and select(2, pcall(_G.QuestGetAutoAccept))
    if K.Bool(P(auto), false) then
        if _G.AcknowledgeAutoAcceptQuest then pcall(_G.AcknowledgeAutoAcceptQuest) end
        EV.Accepted(EV.pending.id)
        return true
    end
    EV.TryAccept()
    return true
end

function EV.TryAccept()
    local p = EV.pending
    if not p then return false end
    if InLog(p.id) then return EV.Accepted(p.id) end
    -- Spieler oder Spiel sind weiter: nichts mehr tun.
    local now = QuestID()
    if not EV.QuestPage("detail") or (p.id and now and now ~= p.id) then EV.pending = nil return false end
    if p.tries >= EV.ACCEPT_TRIES then
        EV.pending = nil
        EV.quest.stuck = EV.quest.stuck + 1
        return false
    end
    p.tries = p.tries + 1
    pcall(_G.AcceptQuest)
    Later(EV.ACCEPT_WAIT, EV.TryAccept)
    return true
end

-- QUEST_ACCEPTED (questID; im alten Format Logplatz, questID) oder im Log
-- gefunden.
function EV.Accepted(id)
    local p = EV.pending
    if not p then return false end
    if p.id and id and id ~= p.id and not InLog(p.id) then return false end
    EV.pending = nil
    EV.quest.accepted = EV.quest.accepted + 1
    -- Der Client schliesst nach der Annahme nicht selbst (1.0.8.0, Bild):
    -- kurz danach zu - aber nur, solange diese Detailseite noch steht.
    local want = p.id
    Later(EV.CLOSE_DELAY, function() EV.CloseDetail(want) end)
    return true
end

EV.CLOSE_DELAY = 0.1
function EV.CloseDetail(id)
    if not EV.QuestPage("detail") then return false end
    local now = QuestID()
    if id and now and now ~= id then return false end   -- schon die naechste Quest
    if _G.CloseQuest then pcall(_G.CloseQuest) end
    if Shown(_G.QuestFrame) and _G.HideUIPanel then pcall(_G.HideUIPanel, _G.QuestFrame) end
    EV.quest.closed = EV.quest.closed + 1
    return true
end

-- Abgeben: kann die Quest (noch) nicht abgegeben werden, spaeter noch
-- einmal fragen - die Gegenstaende laedt das Spiel manchmal erst danach.
local function Completable()
    if not _G.IsQuestCompletable then return false end
    local ok, can = pcall(_G.IsQuestCompletable)
    return ok and K.Bool(P(can), false)
end
function EV.OnQuestProgress(try)
    if not Opt("questTurnIn") or Shift() then return false end
    try = try or 0
    if try > 0 and not EV.QuestPage("progress") then return false end
    if Completable() and _G.CompleteQuest then pcall(_G.CompleteQuest) return true end
    local wait = EV.RETRY[try + 1]
    if wait then Later(wait, function() EV.OnQuestProgress(try + 1) end) end
    return false
end

-- Belohnung: nur ohne Wahl. Das Spiel fuellt die Liste manchmal erst nach
-- dem Ereignis - also erst nach einem Augenblick nehmen, und weiss es dann
-- noch nichts, noch einmal fragen.
function EV.Choices()
    local ok, n = pcall(_G.GetNumQuestChoices or function() return 0 end)
    n = ok and P(n) or nil
    return type(n) == "number" and n or nil
end
function EV.OnQuestComplete(try)
    if not Opt("questTurnIn") or Shift() then return false end
    try = try or 0
    if try > 0 and not EV.QuestPage("complete") then return false end
    local n = EV.Choices()
    if n ~= nil and n > 1 then EV.quest.left = EV.quest.left + 1 return false end
    local wait = EV.RETRY[try + 1]
    if not wait then EV.quest.left = EV.quest.left + 1 return false end
    Later(wait, function()
        if Shift() or not EV.QuestPage("complete") then return end
        local again = EV.Choices()
        if again == nil then EV.OnQuestComplete(try + 1) return end
        if again > 1 then EV.quest.left = EV.quest.left + 1 return end
        if _G.GetQuestReward then pcall(_G.GetQuestReward, again == 1 and 1 or 0) EV.quest.turned = EV.quest.turned + 1 end
    end)
    return true
end

-- Gespraech: zuerst eine fertige Quest abgeben, sonst eine neue nehmen -
-- je Gespraech eine Handlung (das Spiel oeffnet danach das naechste).
function EV.OnGossip()
    if Shift() then return nil end
    local gi = _G.C_GossipInfo
    if not gi then return nil end
    if Opt("questTurnIn") and gi.GetActiveQuests and gi.SelectActiveQuest then
        local ok, list = pcall(gi.GetActiveQuests)
        for _, q in ipairs(ok and type(list) == "table" and list or {}) do
            if K.Bool(P(q.isComplete), false) and type(P(q.questID)) == "number" then
                pcall(gi.SelectActiveQuest, q.questID)
                return "turnin"
            end
        end
    end
    if Opt("questAccept") and gi.GetAvailableQuests and gi.SelectAvailableQuest then
        local ok, list = pcall(gi.GetAvailableQuests)
        for _, q in ipairs(ok and type(list) == "table" and list or {}) do
            if type(P(q.questID)) == "number" then
                pcall(gi.SelectAvailableQuest, q.questID)
                return "accept"
            end
        end
    end
    if Opt("taxiDirect") then return EV.TaxiFromGossip() end
    return nil
end

-- Questgeber ohne Gespraech (mehrere Quests, eigenes Begruessungsfenster
-- des Spiels, QUEST_GREETING): dieselbe Reihenfolge - erst abgeben, dann
-- annehmen, je Fenster eine Handlung.
function EV.OnGreeting()
    if Shift() then return nil end
    local function N(fn)
        if type(fn) ~= "function" then return 0 end
        local ok, n = pcall(fn)
        n = ok and P(n) or nil
        return type(n) == "number" and n or 0
    end
    if Opt("questTurnIn") and _G.SelectActiveQuest then
        for i = 1, N(_G.GetNumActiveQuests) do
            local ok, _, done = pcall(_G.GetActiveTitle or function() end, i)
            if ok and K.Bool(P(done), false) then
                pcall(_G.SelectActiveQuest, i)
                return "turnin"
            end
        end
    end
    if Opt("questAccept") and _G.SelectAvailableQuest and N(_G.GetNumAvailableQuests) > 0 then
        pcall(_G.SelectAvailableQuest, 1)
        return "accept"
    end
    return nil
end

--------------------------------------------------
-- Flugkarte sofort
--------------------------------------------------
-- Nur wenn das Gespraech nichts anderes bietet als den Flug: keine Quests,
-- genau eine Auswahl, und die ist der Flug (Symbol des Spiels fuer Flug
-- oder "flug"/"flieg" im Text). Sonst entscheidet der Spieler.
EV.TAXI_ICON = 132057
function EV.TaxiFromGossip()
    local gi = _G.C_GossipInfo
    if not (gi and gi.GetOptions and gi.SelectOption) then return nil end
    local function Count(fn)
        if not fn then return 0 end
        local ok, l = pcall(fn)
        return ok and type(l) == "table" and #l or 0
    end
    if Count(gi.GetActiveQuests) + Count(gi.GetAvailableQuests) > 0 then return nil end
    local ok, opts = pcall(gi.GetOptions)
    if not ok or type(opts) ~= "table" or #opts ~= 1 then return nil end
    local o = opts[1]
    local name = P(o.name)
    local low = type(name) == "string" and name:lower() or ""
    local taxi = P(o.icon) == EV.TAXI_ICON or low:find("flug") ~= nil or low:find("flieg") ~= nil
    if not taxi then return nil end
    pcall(gi.SelectOption, o.gossipOptionID)
    return "taxi"
end

--------------------------------------------------
-- Tooltip am Mauszeiger
--------------------------------------------------
EV.TIP_POS = {
    { value = "ANCHOR_CURSOR_RIGHT", text = "Rechts unter dem Zeiger" },
    { value = "ANCHOR_CURSOR_LEFT",  text = "Links unter dem Zeiger" },
    { value = "ANCHOR_CURSOR",       text = "Über dem Zeiger" },
}
local function InInstance()
    if not _G.IsInInstance then return false end
    local ok, inside, kind = pcall(_G.IsInInstance)
    kind = ok and P(kind) or nil
    return K.Bool(P(inside), false) and (kind == "party" or kind == "raid" or kind == "pvp" or kind == "arena")
end
function EV.TipAnchor(tt, parent)
    if not Opt("tipMouse") then return false end
    if Opt("tipMouseInst") and InInstance() then return false end
    local pos = K.Get(KEY, "tipMousePos") or "ANCHOR_CURSOR_RIGHT"
    pcall(tt.SetOwner, tt, parent, pos)
    return true
end

--------------------------------------------------
-- Fenster groesser/kleiner (Strg + Mausrad)
--------------------------------------------------
EV.SCALE_MIN, EV.SCALE_MAX, EV.SCALE_STEP = 0.6, 1.5, 0.05
local scaled = {}
local function Scales()
    local root = K.Root()
    if not root then return nil end
    root.winScale = root.winScale or {}
    return root.winScale
end
local function Blocked(f)
    return K.InCombat() and K.Bool(f.IsProtected and f:IsProtected(), true)
end
function EV.ApplyScale(f, name)
    local s = Scales()
    local v = s and s[name]
    if type(v) ~= "number" or not Opt("winScale") or Blocked(f) then return false end
    pcall(f.SetScale, f, v)
    return true
end
function EV.Wheel(f, name, delta)
    if not Opt("winScale") or not (_G.IsControlKeyDown and K.Bool(P(_G.IsControlKeyDown()), false)) then return false end
    if Blocked(f) then return false end
    local s = Scales()
    if not s then return false end
    local cur = P(f.GetScale and f:GetScale()) or 1
    local v = math.max(EV.SCALE_MIN, math.min(EV.SCALE_MAX, cur + (delta > 0 and EV.SCALE_STEP or -EV.SCALE_STEP)))
    v = math.floor(v * 100 + 0.5) / 100
    s[name] = v
    pcall(f.SetScale, f, v)
    return true
end
function EV.HookScale()
    local MW = WeintCodex.UIMoveWindows
    local n = 0
    for _, name in ipairs(MW and MW.WINDOWS or {}) do
        local f = _G[name]
        if type(f) == "table" and not scaled[f] and f.HookScript and f.EnableMouseWheel
           and not (f.IsForbidden and f:IsForbidden()) and not Blocked(f) then
            scaled[f] = name
            f:HookScript("OnShow", function(self) EV.ApplyScale(self, name) end)
            f:HookScript("OnMouseWheel", function(self, delta) EV.Wheel(self, name, delta) end)
            if Opt("winScale") then pcall(f.EnableMouseWheel, f, true) end
            n = n + 1
        end
    end
    return n
end
function EV.ResetScales()
    local s = Scales()
    if s then for name in pairs(s) do s[name] = nil end end
    for f in pairs(scaled) do if not Blocked(f) then pcall(f.SetScale, f, 1) end end
end

--------------------------------------------------
-- Einladen auf ein Wort, Duelle ablehnen
--------------------------------------------------
local function IsFriendName(name)
    local fl = _G.C_FriendList
    if fl and fl.GetFriendInfo then
        local short = tostring(name):match("^[^-]+")
        for _, n in ipairs({ name, short }) do
            local ok, info = pcall(fl.GetFriendInfo, n)
            if ok and type(info) == "table" then return true end
        end
    end
    return false
end
local function IsGuildName(name)
    if not (_G.IsInGuild and K.Bool(P(_G.IsInGuild()), false)) or not _G.GetNumGuildMembers then return false end
    local n = P(_G.GetNumGuildMembers()) or 0
    local short = tostring(name):match("^[^-]+")
    for i = 1, type(n) == "number" and n or 0 do
        local gn = P(_G.GetGuildRosterInfo(i))
        if type(gn) == "string" and (gn == name or gn:match("^[^-]+") == short) then return true end
    end
    return false
end
EV.IsFriendName, EV.IsGuildName = IsFriendName, IsGuildName

function EV.OnWhisper(text, sender, guid)
    if not Opt("inviteWord") then return false end
    text, sender = P(text), P(sender)
    if type(text) ~= "string" or type(sender) ~= "string" then return false end
    local word = tostring(K.Get(KEY, "inviteText") or "inv"):lower():match("^%s*(.-)%s*$")
    if word == "" or text:lower():match("^%s*(.-)%s*$") ~= word then return false end
    local known = IsFriendName(sender) or IsGuildName(sender)
    if not known then return false end
    local grouped = _G.IsInGroup and K.Bool(P(_G.IsInGroup()), false)
    local lead = _G.UnitIsGroupLeader and K.Bool(P(_G.UnitIsGroupLeader("player")), false)
    if grouped and not lead then return false end
    local pi = _G.C_PartyInfo
    if pi and pi.InviteUnit then pcall(pi.InviteUnit, sender)
    elseif _G.InviteUnit then pcall(_G.InviteUnit, sender) end
    return true
end

function EV.OnDuel(name)
    if not Opt("duelDecline") then return false end
    name = P(name)
    if type(name) == "string" and (IsFriendName(name) or IsGuildName(name)) then return false end
    if _G.CancelDuel then pcall(_G.CancelDuel) end
    if _G.StaticPopup_Hide then pcall(_G.StaticPopup_Hide, "DUEL_REQUESTED") end
    return true
end

--------------------------------------------------
-- Chat
--------------------------------------------------
local function ChatCount() return tonumber(_G.NUM_CHAT_WINDOWS) or 10 end

-- Gesendetes zurueckholen. 1.0.8.8 (Rueckmeldung: "in die Gilde
-- geschrieben, abgesendet, Chat wieder auf, Pfeiltasten - es erscheint
-- nicht, was ich gesendet hatte"): bis 1.0.8.7 stellte WeintCodex nur beim
-- Anmelden die Pfeiltasten um und verliess sich auf den Verlauf des Spiels.
-- Beides traegt auf Forever nicht: der Verlauf des Spiels antwortet nicht,
-- und die Zeile stellt die Pfeiltasten beim Schreiben wieder zurueck (so
-- berichtet auch OneForAll, GPL-3.0 - nur das Verhalten, eigener Code).
-- Jetzt eine eigene Liste: die letzten EV.HIST_MAX gesendeten Zeilen mit
-- Art (Gilde, Gruppe, Fluestern an ...), nur fuer diese Sitzung, nie
-- gespeichert - was jemand schreibt, gehoert nicht in die Datei, die die
-- Companion liest. Befehle ("/...") kommen nicht hinein: zurueckgeholt
-- zaehlen sie fuer das Spiel als Addon-Aufruf und werden gesperrt. Im Kampf
-- holt WeintCodex nichts zurueck (Text und Art aus Addon-Code koennten das
-- Senden sperren), die Liste waechst aber weiter.
EV.HIST_MAX = 10
EV.hist = {}          -- neueste zuerst: { text, chatType, tell, chan }
EV.histPos = 0
EV.arrowMode = {}     -- Pfeil-Einstellung des Spiels je Zeile, vor uns
local histHooked, anyHooked = {}, false

local function Str(v)
    v = P(v)
    return type(v) == "string" and v or nil
end

function EV.HistPush(text, chatType, tell, chan)
    text = Str(text)
    if not text or not text:find("%S") or text:find("^%s*/") then return false end
    local h = EV.hist
    for i = #h, 1, -1 do if h[i].text == text then table.remove(h, i) end end
    table.insert(h, 1, { text = text, chatType = Str(chatType), tell = Str(tell), chan = Str(chan) })
    for i = #h, EV.HIST_MAX + 1, -1 do h[i] = nil end
    EV.histPos = 0
    return true
end

local function UpdateHeader(eb)
    if eb.UpdateHeader then pcall(eb.UpdateHeader, eb)
    elseif _G.ChatEdit_UpdateHeader then pcall(_G.ChatEdit_UpdateHeader, eb) end
end

-- Pfeil hoch: aelter, runter: neuer; ganz unten wieder leer.
function EV.HistRecall(eb, key)
    if key ~= "UP" and key ~= "DOWN" then return false end
    if not Opt("chatArrows") or #EV.hist == 0 or K.InCombat() then return false end
    if key == "UP" then EV.histPos = math.min(EV.histPos + 1, #EV.hist)
    else EV.histPos = math.max(EV.histPos - 1, 0) end
    local e = EV.hist[EV.histPos]
    if e and e.chatType and eb.SetAttribute then
        pcall(eb.SetAttribute, eb, "chatType", e.chatType)
        pcall(eb.SetAttribute, eb, "tellTarget", e.tell)
        pcall(eb.SetAttribute, eb, "channelTarget", e.chan)
        UpdateHeader(eb)
    end
    local text = e and e.text or ""
    pcall(eb.SetText, eb, text)
    if eb.SetCursorPosition then pcall(eb.SetCursorPosition, eb, #text) end
    return true
end

local function Arrows(eb)
    if not eb.SetAltArrowKeyMode then return end
    if Opt("chatArrows") then pcall(eb.SetAltArrowKeyMode, eb, false)
    elseif EV.arrowMode[eb] ~= nil then pcall(eb.SetAltArrowKeyMode, eb, EV.arrowMode[eb]) end
end

-- Was getippt wird, merkt sich die Zeile; nach dem Senden ist sie leer.
function EV.HookHistory(eb)
    if type(eb) ~= "table" or not eb.HookScript then return end
    if not histHooked[eb] then
        histHooked[eb], anyHooked = true, true
        if eb.GetAltArrowKeyMode then
            local ok, m = pcall(eb.GetAltArrowKeyMode, eb)
            m = ok and P(m)
            EV.arrowMode[eb] = type(m) == "boolean" and m or true
        end
        pcall(eb.HookScript, eb, "OnTextChanged", function(self, user)
            if not Opt("chatArrows") then return end
            local t = Str(self:GetText())
            if t and t:find("%S") then
                self.wcTyped = t
                self.wcType = self.GetAttribute and self:GetAttribute("chatType")
                self.wcTell = self.GetAttribute and self:GetAttribute("tellTarget")
                self.wcChan = self.GetAttribute and self:GetAttribute("channelTarget")
            elseif user then self.wcTyped = nil end
        end)
        pcall(eb.HookScript, eb, "OnEnterPressed", function(self)
            if Opt("chatArrows") and self.wcTyped then
                EV.HistPush(self.wcTyped, self.wcType, self.wcTell, self.wcChan)
            end
            self.wcTyped, EV.histPos = nil, 0
        end)
        pcall(eb.HookScript, eb, "OnEscapePressed", function(self) self.wcTyped, EV.histPos = nil, 0 end)
        pcall(eb.HookScript, eb, "OnEditFocusGained", function(self)
            self.wcTyped, EV.histPos = nil, 0
            Arrows(self)
        end)
        pcall(eb.HookScript, eb, "OnArrowPressed", function(self, key) EV.HistRecall(self, key) end)
    end
    Arrows(eb)
end

local activateHooked = false
function EV.ApplyArrows()
    if not Opt("chatArrows") and not anyHooked then return end
    for i = 1, ChatCount() + 10 do
        local eb = _G["ChatFrame" .. i .. "EditBox"]
        if type(eb) == "table" then EV.HookHistory(eb) end
    end
    -- Fluesterfenster bekommen ihre Zeile spaeter.
    if not activateHooked and Opt("chatArrows") and _G.hooksecurefunc and _G.ChatEdit_ActivateChat then
        activateHooked = true
        _G.hooksecurefunc("ChatEdit_ActivateChat", function(eb) if Opt("chatArrows") then EV.HookHistory(eb) end end)
    end
end

EV.chatHidden = false
EV.lastChat = 0
function EV.ChatHidden() return EV.chatHidden end
function EV.SetChatHidden(hide)
    EV.chatHidden = hide and true or false
    for i = 1, ChatCount() do
        for _, n in ipairs({ "ChatFrame" .. i, "ChatFrame" .. i .. "Tab" }) do
            local f = _G[n]
            if type(f) == "table" and f.SetAlpha then pcall(f.SetAlpha, f, hide and 0 or 1) end
            local CAm = WeintCodex.UICombatAids
            if CAm and CAm.faded then CAm.faded[n] = hide or nil end
        end
    end
    local dm = _G.GeneralDockManager
    if type(dm) == "table" and dm.SetAlpha then pcall(dm.SetAlpha, dm, hide and 0 or 1) end
    if EV.chatBtn then EV.chatBtn:SetText(hide and "+" or "–") end
    -- Im Kampf mit "Chat im Kampf ausblenden" bleibt er aus.
    local CA = WeintCodex.UICombatAids
    if not hide and CA and CA.ApplyHide and K.InCombat() then CA.ApplyHide(true) end
end

local function BuildChatButton()
    if EV.chatBtn then return EV.chatBtn end
    local host = _G.ChatFrame1
    if type(host) ~= "table" then return nil end
    local b = WeintCodex.CreateButton(UIParent, { text = "–", kind = "ghost", height = 18, size = 12, width = 22,
        backdrop = "surface2", tooltip = "Chat aus- und einblenden",
        onClick = function() EV.SetChatHidden(not EV.chatHidden) EV.lastChat = P(_G.GetTime and _G.GetTime()) or 0 end })
    b:SetPoint("BOTTOMRIGHT", host, "TOPRIGHT", 0, 26)
    b:SetFrameStrata("MEDIUM")
    EV.chatBtn = b
    return b
end
function EV.UpdateChatButton()
    local b = Opt("chatButton") and BuildChatButton() or EV.chatBtn
    if b then b:SetShown(Opt("chatButton")) end
    -- Gerade eingeschaltet: die Zeit beginnt jetzt, nicht beim Anmelden.
    if Opt("chatButton") and not EV.chatOn then EV.lastChat = P(_G.GetTime and _G.GetTime()) or 0 end
    EV.chatOn = Opt("chatButton")
    if not Opt("chatButton") and EV.chatHidden then EV.SetChatHidden(false) end
end

--------------------------------------------------
-- Entzaubern: was im Mittel herauskommt (Classic)
--------------------------------------------------
-- Gruen: Staub/Essenz/Splitter je Stufenband, Anteil (Ruestung; Waffen
-- tauschen Staub und Essenz). Blau: ein Splitter. Episch: Splitter/Kristall.
-- { bis Gegenstandsstufe, Staub, Anzahl Staub, Essenz, Anzahl Essenz, Splitter? }
-- Splitter: nur ob einer faellt; welcher, sagt EV.DE_BLUE fuer dieselbe Stufe.
EV.DE_GREEN = {
    { 15, 10940, 1.5, 10938, 1.5, nil },
    { 20, 10940, 2.5, 10939, 1.5, nil },
    { 25, 10940, 5.0, 10998, 1.5, 10978 },
    { 30, 11083, 1.5, 11082, 1.5, 10978 },
    { 35, 11083, 3.5, 11134, 1.5, 11084 },
    { 40, 11137, 1.5, 11135, 1.5, 11138 },
    { 45, 11137, 3.5, 11174, 1.5, 11139 },
    { 50, 11176, 1.5, 11175, 1.5, 11177 },
    { 55, 11176, 3.5, 16202, 1.5, 11178 },
    { 60, 16204, 1.5, 16203, 1.5, 14343 },
    { 65, 16204, 3.5, 16203, 2.5, 14344 },
}
EV.DE_BLUE = { { 25, 10978 }, { 30, 11084 }, { 35, 11138 }, { 40, 11139 }, { 45, 11177 }, { 50, 11178 }, { 55, 14343 }, { 999, 14344 } }
EV.DE_EPIC = { { 45, 11177, 3 }, { 50, 11178, 3 }, { 55, 14343, 3 }, { 60, 20725, 1 }, { 999, 20725, 1.5 } }

function EV.BlueShard(ilvl)
    for _, b in ipairs(EV.DE_BLUE) do if ilvl <= b[1] then return b[2] end end
    return nil
end

local function Price(id)
    local AP = WeintCodex.UIAuctionPrices
    local f = AP and AP.Lookup and AP.Lookup(id)
    return f and type(f.price) == "number" and f.price or nil
end

-- Erwarteter Wert in Kupfer oder nil (unbekannt: Preis fehlt, kein Treffer).
function EV.DisenchantValue(quality, ilvl, weapon)
    if type(quality) ~= "number" or type(ilvl) ~= "number" or ilvl < 5 then return nil end
    if quality == 2 then
        for _, b in ipairs(EV.DE_GREEN) do
            if ilvl <= b[1] then
                -- Splitter: derselbe wie bei Blau auf dieser Stufe (1.0.8.0
                -- korrigiert - die Spalte stand eine Stufe zu niedrig).
                local sid = b[6] and EV.BlueShard(ilvl)
                local dust, ess, shard = Price(b[2]), Price(b[4]), sid and Price(sid)
                if not (dust and ess) or (b[6] and not shard) then return nil end
                local pd, pe = weapon and 0.2 or 0.75, weapon and 0.75 or 0.2
                local ps = b[6] and 0.05 or 0
                return math.floor(pd * b[3] * dust + pe * b[5] * ess + ps * (shard or 0))
            end
        end
    elseif quality == 3 then
        for _, b in ipairs(EV.DE_BLUE) do
            if ilvl <= b[1] then local p = Price(b[2]) return p and math.floor(p) or nil end
        end
    elseif quality == 4 then
        if ilvl < 40 then return nil end
        for _, b in ipairs(EV.DE_EPIC) do
            if ilvl <= b[1] then local p = Price(b[2]) return p and math.floor(p * b[3]) or nil end
        end
    end
    return nil
end

local function OnTipItem(tt)
    if not Opt("deValue") or type(tt) ~= "table" or not tt.GetItem then return end
    local ok, _, link = pcall(tt.GetItem, tt)
    link = ok and P(link) or nil
    if type(link) ~= "string" or not _G.GetItemInfo then return end
    local ok2, _, _, quality, ilvl, _, _, _, _, _, _, _, classID = pcall(_G.GetItemInfo, link)
    if not ok2 then return end
    quality, ilvl, classID = P(quality), P(ilvl), P(classID)
    if classID ~= 2 and classID ~= 4 then return end
    local v = EV.DisenchantValue(quality, ilvl, classID == 2)
    if not v then return end
    local AP = WeintCodex.UIAuctionPrices
    local money = AP and AP.Money and AP.Money(v) or tostring(v)
    local col = C.textMuted
    tt:AddLine("Entzaubern: ~" .. money, col[1], col[2], col[3])
end
EV.OnTipItem = OnTipItem

--------------------------------------------------
-- Quests in der Gruppe teilen (Dungeon)
--------------------------------------------------
local function Faction()
    if not _G.UnitFactionGroup then return nil end
    local _, f = _G.UnitFactionGroup("player")
    f = P(f)
    return f == "Alliance" and "alliance" or f == "Horde" and "horde" or nil
end
local function InLog(qid)
    local ql = _G.C_QuestLog
    if not (ql and ql.GetLogIndexForQuestID) then return false end
    local ok, i = pcall(ql.GetLogIndexForQuestID, qid)
    return ok and type(P(i)) == "number"
end
local function UnitOn(unit, qid)
    local ql = _G.C_QuestLog
    if not (ql and ql.IsUnitOnQuest) then return nil end
    local ok, v = pcall(ql.IsUnitOnQuest, unit, qid)
    if not ok then return nil end
    return K.Bool(P(v), false)
end
local function Party()
    local out = {}
    local n = P(_G.GetNumSubgroupMembers and _G.GetNumSubgroupMembers()) or 0
    for i = 1, type(n) == "number" and n or 0 do out[#out + 1] = "party" .. i end
    return out
end

-- Quests des Dungeons, die du hast: { id, name, need = { Namen } }.
-- need: wer sie nachweislich nicht hat; unbekannt zaehlt nicht.
function EV.ShareList(dungeonId)
    local J = WeintCodex.DungeonJournal
    if not (J and J.Has and J.Has(dungeonId)) then return {} end
    local out, party = {}, Party()
    for _, q in ipairs(J.Quests(dungeonId, Faction())) do
        if type(q.id) == "number" and InLog(q.id) then
            local need = {}
            for _, u in ipairs(party) do
                if UnitOn(u, q.id) == false then
                    local nm = P(_G.UnitName and _G.UnitName(u))
                    need[#need + 1] = type(nm) == "string" and nm or u
                end
            end
            local name = J.QuestName and J.QuestName(q.id) or q.name
            out[#out + 1] = { id = q.id, name = name or q.name, need = need }
        end
    end
    return out
end

function EV.Push(qid)
    local ql = _G.C_QuestLog
    if K.InCombat() or not (ql and ql.SetSelectedQuest) or not _G.QuestLogPushQuest then return false end
    pcall(ql.SetSelectedQuest, qid)
    pcall(_G.QuestLogPushQuest)
    return true
end

local share
function EV.ShowShare(force)
    local CL = WeintCodex.UICodexLinks
    local did = CL and CL.CurrentDungeon and CL.CurrentDungeon()
    if not did then if force then Say("Teilen geht in einem Dungeon, den Codex kennt.") end return false end
    local list = EV.ShareList(did)
    local any = false
    for _, e in ipairs(list) do if #e.need > 0 then any = true end end
    if not any and not force then return false end
    -- Einmal geschlossen, kommt dasselbe Bild nicht wieder (Gruppe aendert
    -- sich oft); nur wenn sich etwas aendert - oder auf /wcui teilen.
    local sig = {}
    for _, e in ipairs(list) do sig[#sig + 1] = e.id .. ":" .. table.concat(e.need, ",") end
    sig = did .. "|" .. table.concat(sig, ";")
    if not force and sig == EV.shareClosed then return false end
    EV.shareSig = sig
    if not share then
        share = CreateFrame("Frame", "WeintCodexQuestShare", UIParent)
        share:SetSize(340, 60)
        share:SetPoint("TOP", UIParent, "TOP", 0, -220)
        share:SetFrameStrata("DIALOG")
        share:EnableMouse(true)
        share:SetMovable(true)
        share:RegisterForDrag("LeftButton")
        share:SetScript("OnDragStart", share.StartMoving)
        share:SetScript("OnDragStop", share.StopMovingOrSizing)
        K.Kachel(share, { shadow = 6, solid = true })
        share.title = K.NewText(share, 13)
        share.title:SetPoint("TOPLEFT", share, "TOPLEFT", 14, -12)
        share.title:SetTextColor(unpack(C.textBright))
        share.close = WeintCodex.CreateButton(share, { text = "×", kind = "ghost", height = 22, size = 14, width = 24,
            backdrop = "surface2", onClick = function() EV.shareClosed = EV.shareSig share:Hide() end })
        share.close:SetPoint("TOPRIGHT", share, "TOPRIGHT", -8, -8)
        share.rows = {}
    end
    for _, r in ipairs(share.rows) do r.text:Hide() r.btn:Hide() end
    share.title:SetText("Quests dieses Dungeons in der Gruppe")
    local y = -40
    if #list == 0 then
        share.rows[1] = share.rows[1] or { text = K.NewText(share, 11), btn = WeintCodex.CreateButton(share, { text = "Teilen", height = 20, size = 10 }) }
        local r = share.rows[1]
        r.text:SetPoint("TOPLEFT", share, "TOPLEFT", 14, y)
        r.text:SetText("Du hast keine Quest dieses Dungeons.")
        r.text:Show()
        y = y - 22
    end
    for i, e in ipairs(list) do
        local r = share.rows[i]
        if not r then
            r = { text = K.NewText(share, 11), btn = WeintCodex.CreateButton(share, { text = "Teilen", height = 20, size = 10, width = 64 }) }
            share.rows[i] = r
        end
        r.text:ClearAllPoints()
        r.text:SetPoint("TOPLEFT", share, "TOPLEFT", 14, y)
        r.text:SetWidth(240)
        r.text:SetJustifyH("LEFT")
        r.text:SetText(e.name .. (#e.need > 0 and ("\n" .. WeintCodex.ColorText("textMuted", "fehlt: " .. table.concat(e.need, ", "))) or ""))
        r.text:Show()
        r.btn:ClearAllPoints()
        r.btn:SetPoint("TOPRIGHT", share, "TOPRIGHT", -12, y)
        r.btn:SetScript("OnClick", function() EV.Push(e.id) end)
        r.btn:SetShown(#e.need > 0)
        y = y - (#e.need > 0 and 34 or 20)
    end
    share:SetHeight(-y + 10)
    share:Show()
    return true
end

--------------------------------------------------
-- Ereignisse
--------------------------------------------------
do
    local ev = CreateFrame("Frame")
    for _, e in ipairs({ "PLAYER_LOGIN", "ADDON_LOADED", "QUEST_DETAIL", "QUEST_PROGRESS", "QUEST_COMPLETE", "GOSSIP_SHOW", "QUEST_GREETING",
                         "QUEST_ACCEPTED", "QUEST_ITEM_UPDATE",
                         "CHAT_MSG_WHISPER", "DUEL_REQUESTED", "PLAYER_ENTERING_WORLD", "GROUP_ROSTER_UPDATE",
                         "CHAT_MSG_SAY", "CHAT_MSG_GUILD", "CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER", "CHAT_MSG_CHANNEL",
                         "CHAT_MSG_WHISPER_INFORM", "CHAT_MSG_RAID", "CHAT_MSG_SYSTEM" }) do
        pcall(ev.RegisterEvent, ev, e)
    end
    ev:SetScript("OnEvent", WeintCodex.Measured("Bequem", function(_, event, a1, a2, ...)
        if event == "QUEST_DETAIL" then EV.OnQuestDetail()
        elseif event == "QUEST_PROGRESS" then EV.OnQuestProgress()
        elseif event == "QUEST_COMPLETE" then EV.OnQuestComplete()
        elseif event == "GOSSIP_SHOW" then EV.OnGossip()
        elseif event == "QUEST_GREETING" then EV.OnGreeting()
        elseif event == "QUEST_ACCEPTED" then
            local id = P(a2)
            if type(id) ~= "number" then id = P(a1) end
            EV.Accepted(type(id) == "number" and id or nil)
        elseif event == "QUEST_ITEM_UPDATE" then
            -- Gegenstaende nachgeladen: Abgeben jetzt moeglich?
            if EV.QuestPage("progress") then EV.OnQuestProgress(#EV.RETRY) end
        elseif event == "CHAT_MSG_WHISPER" then
            EV.OnWhisper(a1, a2)
        elseif event == "DUEL_REQUESTED" then EV.OnDuel(a1)
        elseif event == "PLAYER_LOGIN" then
            EV.lastChat = P(_G.GetTime and _G.GetTime()) or 0
            EV.ApplyArrows()
            EV.UpdateChatButton()
            EV.HookScale()
            if _G.hooksecurefunc and _G.GameTooltip_SetDefaultAnchor then
                _G.hooksecurefunc("GameTooltip_SetDefaultAnchor", function(tt, parent) EV.TipAnchor(tt, parent) end)
            end
            local tdp, en = _G.TooltipDataProcessor, _G.Enum and _G.Enum.TooltipDataType
            if tdp and tdp.AddTooltipPostCall and en and en.Item then
                pcall(tdp.AddTooltipPostCall, en.Item, K.Measured("Bequem", OnTipItem))
            elseif _G.GameTooltip and _G.GameTooltip.HookScript then
                _G.GameTooltip:HookScript("OnTooltipSetItem", function(self) OnTipItem(self) end)
            end
        elseif event == "ADDON_LOADED" then
            EV.HookScale()
        elseif event == "PLAYER_ENTERING_WORLD" or event == "GROUP_ROSTER_UPDATE" then
            if Opt("questShare") and not K.InCombat() then Later(4, function() EV.ShowShare(false) end) end
        end
        if event:find("^CHAT_MSG_") then
            EV.lastChat = P(_G.GetTime and _G.GetTime()) or 0
            if EV.chatHidden and (tonumber(K.Get(KEY, "chatAutoHide")) or 0) > 0 then EV.SetChatHidden(false) end
        end
    end))
    -- Chat von selbst ausblenden: ruhiger Takt (einmal je Sekunde).
    local acc = 0
    ev:SetScript("OnUpdate", WeintCodex.Measured("Bequem", function(_, el)
        acc = acc + (el or 0)
        if acc < 1 then return end
        acc = 0
        local after = tonumber(K.Get(KEY, "chatAutoHide")) or 0
        if not Opt("chatButton") or after <= 0 or EV.chatHidden then return end
        local eb = _G.ChatFrame1EditBox
        if eb and eb.HasFocus and K.Bool(eb:HasFocus(), false) then EV.lastChat = P(_G.GetTime()) or 0 return end
        local now = P(_G.GetTime and _G.GetTime()) or 0
        if now - EV.lastChat >= after then EV.SetChatHidden(true) end
    end))
    EV.events = ev
end

--------------------------------------------------
-- Einstellungen
--------------------------------------------------
local function off(k) return function() return not K.Get(KEY, k) end end
local function Build(B)
    B:Section("Quests", "Annehmen und abgeben ohne Klick. Mehrere Belohnungen zur Wahl: nie – die Wahl bleibt bei dir. Umschalt beim Ansprechen hält alles an.")
    B:Row({ type = "toggle", label = "Quests automatisch annehmen", key = "questAccept" },
          { type = "toggle", label = "Quests automatisch abgeben", key = "questTurnIn" })
    B:Row({ type = "toggle", label = "Quests der Gruppe im Dungeon", key = "questShare",
            description = "Im Dungeon mit Gruppe: welche Quests des Dungeons du hast und wer sie noch braucht – mit „Teilen“. Auch mit /wcui teilen." },
          { type = "toggle", label = "Flugkarte sofort öffnen", key = "taxiDirect",
            description = "Am Flugmeister gleich die Karte – nur wenn er nichts anderes anbietet." })
    B:Section("Tooltip und Fenster")
    B:Row({ type = "toggle", label = "Tooltip am Mauszeiger", key = "tipMouse" },
          { type = "dropdown", label = "Wo", key = "tipMousePos", items = EV.TIP_POS, disabled = off("tipMouse") })
    B:Row({ type = "toggle", label = "In Dungeon und PvP wie im Spiel", key = "tipMouseInst", disabled = off("tipMouse") },
          { type = "toggle", label = "Entzaubern im Tooltip", key = "deValue",
            description = "Was Entzaubern im Mittel bringt – Ertrag wie in Classic, Preise aus deinen Auktionspreisen. Ohne Preis keine Zahl." })
    B:Row({ type = "toggle", label = "Fenstergröße mit Strg + Mausrad", key = "winScale",
            description = "Über einem Fenster des Spiels Strg halten und rollen – gemerkt je Fenster." },
          { type = "empty" })
    B:Section("Gruppe und Chat")
    B:Row({ type = "toggle", label = "Einladen auf ein Wort", key = "inviteWord",
            description = "Flüstert dir ein Freund oder jemand aus der Gilde genau dieses Wort, lädt WeintCodex ein." },
          { type = "input", label = "Wort", key = "inviteText", disabled = off("inviteWord") })
    B:Row({ type = "toggle", label = "Duelle ablehnen", key = "duelDecline",
            description = "Außer von Freunden und deiner Gilde." },
          { type = "toggle", label = "Pfeiltasten holen Gesendetes zurück", key = "chatArrows",
            description = "Pfeil hoch/runter in der Chatzeile: die letzten 10 gesendeten Zeilen, mit Gilde, Gruppe oder Flüsterziel. Nur bis zum Ausloggen, nicht im Kampf." })
    B:Row({ type = "toggle", label = "Knopf zum Ausblenden des Chats", key = "chatButton" },
          { type = "slider", label = "Von selbst ausblenden nach", key = "chatAutoHide", min = 0, max = 120, step = 10,
            disabled = off("chatButton"), format = function(v) return v == 0 and "nie" or (v .. " s") end })
    B:Advanced()
    B:Row({ type = "button", label = "Fenstergrößen", text = "Alle zurücksetzen", onClick = function() EV.ResetScales() end },
          { type = "empty" })
end
EV.BuildPage = Build

local mod = K.Module(KEY)
if mod then
    for k, v in pairs(EV.DEFAULTS) do
        if mod.defaults[k] == nil then mod.defaults[k] = v end
    end
    mod.pages[#mod.pages + 1] = { key = "bequem", label = "Bequem", build = Build }
    if type(mod.pageOrder) == "table" then mod.pageOrder.bequem = 3 end
end

K.Listen(function(kind, key, sub)
    if (kind == "active" or kind == "setting") and key == KEY then
        EV.ApplyArrows()
        EV.UpdateChatButton()
        if sub == "winScale" then
            EV.HookScale()
            for f in pairs(scaled) do if not Blocked(f) then pcall(f.EnableMouseWheel, f, Opt("winScale")) end end
        end
    end
end)
