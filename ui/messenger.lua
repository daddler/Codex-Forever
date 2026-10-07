--------------------------------------------------
-- WeintCodex :: Fluestern als Messenger
--------------------------------------------------
-- Seit 6.19.0.0 (Wunsch des Spielers, nach dem Verhalten von WIM - kein
-- Code und keine Bilder daraus, WIM ist "All Rights Reserved"): wird dir
-- etwas zugefluestert, geht ein Fenster auf wie bei einem Messenger -
-- links die Gespraeche, rechts der Verlauf, unten antworten. Eine Seite im
-- Komfort, gespeichert unter "comfort", wie jeder Komfort-Helfer von Haus
-- aus AUS; geht ohne Oberflaeche.
--
-- ENTSCHIEDEN MIT DEM SPIELER (07.10.2026):
--   * Der Chat bleibt, wie er ist - jedes Gefluesterte steht AUCH dort.
--     Kein Chatfilter, keine Zeile wird veraendert oder versteckt.
--   * Verlauf nur fuer diese Sitzung: nichts davon landet in den
--     gespeicherten Daten - die Datei liest auch die Companion-App, und
--     private Nachrichten gehoeren da nicht hinein.
--   * Nur Fluestern und Battle.net-Fluestern, nicht Gilde oder Gruppe.
--
-- ANTWORTEN: Selbst fluestern darf ein Addon auf Forever vielleicht nicht -
-- an die Gilde ist es gemessen gesperrt (ADDON_ACTION_BLOCKED, 6.10.4.6).
-- Darum oeffnet ein Klick in die Antwortzeile ab Werk die Chatzeile des
-- Spiels mit "/w Name" - dort schreibst du, Enter sendet, und das Spiel
-- sendet selbst. "Direkt aus dem Fenster senden" (msgDirect, ab Werk aus,
-- UNGEMESSEN) versucht es selbst; meldet das Spiel ADDON_ACTION_BLOCKED,
-- schaltet WeintCodex es ab, merkt sich die Messung und gibt den Text an
-- die Chatzeile weiter.
--
-- MARKIEREN (6.19.0.1, Beta-Test: "Saetze markieren und kopieren"): das
-- Nachrichtenfeld des Spiels (ScrollingMessageFrame) kann keinen Text
-- markieren. Der Knopf "Markieren" tauscht den Verlauf gegen ein Textfeld
-- nur zum Lesen, ohne Farben und Link-Kodes - mit der Maus markieren,
-- Strg+C kopiert, Esc oder der Knopf kehrt zurueck.
--
-- SPERRE DES SPIELS: Im Kampf gegen Bosse u. a. kann der Client
-- Chatnachrichten fuer Addons geheim halten. Geheimes wird nie gelesen -
-- es steht im Chat, und das Fenster zaehlt nur, wie viele es waren.
--------------------------------------------------

local K = WeintCodex.UIKit
local C = WeintCodex.Colors
local F = WeintCodex.Fonts
local KEY = "comfort"

WeintCodex.UIMessenger = {}
local MS = WeintCodex.UIMessenger

MS.DEFAULTS = {
    msgOn       = false,  -- der Helfer
    msgCombat   = false,  -- auch im Kampf aufgehen (sonst danach)
    msgOutgoing = true,   -- auch aufgehen, wenn du selbst jemandem fluesterst
    msgStamps   = true,   -- Uhrzeit vor jeder Zeile
    msgDirect   = false,  -- selbst senden (ungemessen)
}

MS.MAX_LINES = 200        -- je Gespraech, nur diese Sitzung
MS.MAX_CONV  = 8          -- so viele Gespraeche in der Liste
MS.W, MS.H   = 420, 260
MS.LIST_W    = 120
MS.ROW_H     = 24
MS.BLOCK_WINDOW = 1       -- so lange nach einem Sendeversuch zaehlt eine Sperrmeldung (s)

local SETTING = { combat = "msgCombat", outgoing = "msgOutgoing", stamps = "msgStamps", direct = "msgDirect" }
local function Get(k) return K.Get(KEY, SETTING[k] or k) end
function MS.Active() return K.IsActive(KEY) and K.Get(KEY, "msgOn") and true or false end

local function Clock() return (_G.GetTime and K.Plain(_G.GetTime())) or 0 end
local function Time() return (_G.time and _G.time()) or 0 end
local function Say(text) print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " " .. text) end

--------------------------------------------------
-- Gespraeche (nur im Speicher dieser Sitzung)
--------------------------------------------------

local conv = {}           -- [key] = { key, name, target, bn, class, lines, unread }
local order = {}          -- Schluessel, neuestes zuerst
MS.conv, MS.order = conv, order
MS.locked = 0             -- geheim gebliebene Nachrichten (nur im Chat)

local function MyRealm()
    local r = _G.GetNormalizedRealmName and K.Plain(_G.GetNormalizedRealmName())
    return type(r) == "string" and r or nil
end

-- "Name-Realm" -> "Name", wenn es der eigene Realm ist.
function MS.Short(name)
    if type(name) ~= "string" then return nil end
    local n, r = name:match("^([^%-]+)%-(.+)$")
    if n and (r == MyRealm() or (MyRealm() == nil)) then return n end
    return name
end

local function Touch(key)
    for i = #order, 1, -1 do
        if order[i] == key then table.remove(order, i) end
    end
    table.insert(order, 1, key)
    while #order > MS.MAX_CONV do
        local old = table.remove(order)
        conv[old] = nil
    end
end

function MS.Ensure(key, name, target, bn)
    local c = conv[key]
    if not c then
        c = { key = key, name = name, target = target, bn = bn, lines = {}, unread = 0 }
        conv[key] = c
    end
    if name then c.name = name end
    Touch(key)
    return c
end

-- kind: "in", "out", "sys"
function MS.Add(c, kind, text)
    local lines = c.lines
    lines[#lines + 1] = { t = Time(), kind = kind, text = text }
    while #lines > MS.MAX_LINES do table.remove(lines, 1) end
end

function MS.Close(key)
    conv[key] = nil
    for i = #order, 1, -1 do
        if order[i] == key then table.remove(order, i) end
    end
    if MS.current == key then MS.current = order[1] end
    MS.Redraw()
end

local function ClassOf(guid)
    guid = K.Plain(guid)
    if type(guid) ~= "string" or not _G.GetPlayerInfoByGUID then return nil end
    local ok, _, class = pcall(_G.GetPlayerInfoByGUID, guid)
    class = ok and K.Plain(class) or nil
    return type(class) == "string" and class or nil
end

--------------------------------------------------
-- Zeilen
--------------------------------------------------

local function Hex(col) return string.format("ff%02x%02x%02x", col[1] * 255, col[2] * 255, col[3] * 255) end

function MS.NameText(c)
    local cc = c.class and _G.RAID_CLASS_COLORS and _G.RAID_CLASS_COLORS[c.class]
    if cc and cc.colorStr then return "|c" .. cc.colorStr .. c.name .. "|r" end
    return c.name
end

function MS.Format(c, line)
    local out = ""
    if Get("stamps") and _G.date then
        out = "|c" .. Hex(C.textMuted) .. _G.date("%H:%M", line.t) .. "|r  "
    end
    if line.kind == "sys" then
        return out .. "|c" .. Hex(C.textMuted) .. line.text .. "|r"
    end
    local who = line.kind == "out" and ("|c" .. Hex(C.accent) .. "Du|r") or MS.NameText(c)
    local col = line.kind == "out" and C.textNormal or C.textBright
    return out .. who .. ": |c" .. Hex(col) .. line.text .. "|r"
end

--------------------------------------------------
-- Fenster
--------------------------------------------------

local win, list, smf, input, title, sub, foot, copy, copyEdit, markBtn
local rows = {}
MS.copyMode = false

-- Eine Zeile als reiner Text (zum Kopieren): ohne Farben, Bilder, Link-Kodes.
function MS.PlainLine(c, line)
    local t = ""
    if Get("stamps") and _G.date then t = _G.date("%H:%M", line.t) .. " " end
    local text = (line.text or ""):gsub("|H.-|h(.-)|h", "%1")
    if line.kind == "sys" then return K.PlainText(t .. text) end
    return K.PlainText(t .. (line.kind == "out" and "Du" or c.name) .. ": " .. text)
end

function MS.PlainHistory(c)
    if not c then return "" end
    local out = {}
    for i, line in ipairs(c.lines) do out[i] = MS.PlainLine(c, line) end
    return table.concat(out, "\n")
end

local function NewRow(i)
    local r = CreateFrame("Button", nil, list)
    r:SetSize(MS.LIST_W, MS.ROW_H)
    r:SetPoint("TOPLEFT", list, "TOPLEFT", 0, -(i - 1) * MS.ROW_H)
    r.bg = r:CreateTexture(nil, "BACKGROUND")
    r.bg:SetAllPoints(r)
    r.mark = r:CreateTexture(nil, "ARTWORK")
    r.mark:SetSize(2, MS.ROW_H)
    r.mark:SetPoint("LEFT", r, "LEFT", 0, 0)
    local a = C.accent
    r.mark:SetColorTexture(a[1], a[2], a[3], 1)
    r.label = K.NewText(r, 12)
    r.label:SetPoint("LEFT", r, "LEFT", 8, 0)
    r.label:SetPoint("RIGHT", r, "RIGHT", -34, 0)
    r.label:SetJustifyH("LEFT")
    r.label:SetWordWrap(false)
    r.badge = K.NewText(r, 11)
    r.badge:SetPoint("RIGHT", r, "RIGHT", -20, 0)
    r.x = CreateFrame("Button", nil, r)
    r.x:SetSize(16, 16)
    r.x:SetPoint("RIGHT", r, "RIGHT", -2, 0)
    r.x.t = K.NewText(r.x, 12)
    r.x.t:SetPoint("CENTER", r.x, "CENTER", 0, 0)
    r.x.t:SetText("\195\151")
    local m = C.textMuted
    r.x.t:SetTextColor(m[1], m[2], m[3])
    r.x:SetScript("OnClick", function(self) MS.Close(self:GetParent().key) end)
    r:SetScript("OnClick", function(self) MS.Select(self.key) end)
    rows[i] = r
    return r
end

local function OpenGameReply(c, text)
    if not c then return false end
    if c.bn then
        local f = (_G.ChatFrameUtil and _G.ChatFrameUtil.SendBNetTell) or _G.ChatFrame_SendBNetTell
        if f and pcall(f, c.target) then
            if text and text ~= "" then
                local eb = (_G.ChatFrameUtil and _G.ChatFrameUtil.GetActiveWindow and _G.ChatFrameUtil.GetActiveWindow())
                    or (_G.ChatEdit_GetActiveWindow and _G.ChatEdit_GetActiveWindow())
                if eb and eb.Insert then eb:Insert(text) end
            end
            return true
        end
        return false
    end
    local line = "/w " .. c.target .. " " .. (text or "")
    local open = (_G.ChatFrameUtil and _G.ChatFrameUtil.OpenChat) or _G.ChatFrame_OpenChat
    if open then return pcall(open, line) end
    return false
end
MS.OpenGameReply = OpenGameReply

local function Build()
    if win then return win end
    win = CreateFrame("Frame", "WeintCodexMessenger", UIParent)
    win:SetSize(MS.W, MS.H)
    win:SetFrameStrata("HIGH")
    win:SetToplevel(true)
    win:SetClampedToScreen(true)
    win:EnableMouse(true)
    win:Hide()
    K.Kachel(win, { alpha = 0.96, shadow = 10 })
    if type(_G.UISpecialFrames) == "table" then table.insert(_G.UISpecialFrames, "WeintCodexMessenger") end

    list = CreateFrame("Frame", nil, win)
    list:SetPoint("TOPLEFT", win, "TOPLEFT", 1, -1)
    list:SetPoint("BOTTOMLEFT", win, "BOTTOMLEFT", 1, 1)
    list:SetWidth(MS.LIST_W)
    local lb = list:CreateTexture(nil, "BACKGROUND")
    lb:SetAllPoints(list)
    local s1 = C.surface1
    lb:SetColorTexture(s1[1], s1[2], s1[3], 0.9)

    title = K.NewText(win, 14)
    title:SetPoint("TOPLEFT", win, "TOPLEFT", MS.LIST_W + 12, -10)
    title:SetPoint("RIGHT", win, "RIGHT", -120, 0)   -- Platz fuer "Markieren" und x
    title:SetJustifyH("LEFT")
    title:SetWordWrap(false)
    sub = K.NewText(win, 10)
    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -2)
    local m = C.textMuted
    sub:SetTextColor(m[1], m[2], m[3])

    local close = CreateFrame("Button", nil, win)
    close:SetSize(24, 22)
    close:SetPoint("TOPRIGHT", win, "TOPRIGHT", -6, -6)
    local x = K.NewText(close, 14)
    x:SetPoint("CENTER", close, "CENTER", 0, 0)
    x:SetTextColor(m[1], m[2], m[3])
    x:SetText("\195\151")
    close:SetScript("OnClick", function() win:Hide() end)

    markBtn = CreateFrame("Button", nil, win)
    markBtn:SetSize(78, 20)
    markBtn:SetPoint("RIGHT", close, "LEFT", -4, 0)
    markBtn.t = K.NewText(markBtn, 11)
    markBtn.t:SetPoint("CENTER", markBtn, "CENTER", 0, 0)
    markBtn.t:SetTextColor(m[1], m[2], m[3])
    markBtn.t:SetText("Markieren")
    markBtn:SetScript("OnClick", function() MS.SetCopyMode(not MS.copyMode) end)

    smf = CreateFrame("ScrollingMessageFrame", nil, win)
    smf:SetPoint("TOPLEFT", win, "TOPLEFT", MS.LIST_W + 12, -44)
    smf:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", -10, 58)
    smf:SetFont(F.sans, 12, "")
    smf:SetJustifyH("LEFT")
    smf:SetFading(false)
    smf:SetMaxLines(MS.MAX_LINES)
    if smf.SetHyperlinksEnabled then smf:SetHyperlinksEnabled(true) end
    smf:SetScript("OnHyperlinkClick", function(_, link, text, button)
        if _G.SetItemRef then pcall(_G.SetItemRef, link, text, button) end
    end)
    smf:EnableMouseWheel(true)
    smf:SetScript("OnMouseWheel", function(self, d)
        if d > 0 then self:ScrollUp() else self:ScrollDown() end
    end)

    -- Markieren: ein Textfeld nur zum Lesen an derselben Stelle.
    copy = CreateFrame("ScrollFrame", nil, win, "UIPanelScrollFrameTemplate")
    copy:SetPoint("TOPLEFT", smf, "TOPLEFT", 0, 0)
    copy:SetPoint("BOTTOMRIGHT", smf, "BOTTOMRIGHT", -20, 0)
    copy:Hide()
    copyEdit = CreateFrame("EditBox", nil, copy)
    copyEdit:SetMultiLine(true)
    copyEdit:SetMaxLetters(0)
    copyEdit:SetAutoFocus(false)
    copyEdit:SetWidth(MS.W - MS.LIST_W - 52)
    copyEdit:SetFont(F.sans, 12, "")
    local tn = C.textNormal
    copyEdit:SetTextColor(tn[1], tn[2], tn[3])
    copy:SetScrollChild(copyEdit)
    copyEdit:SetScript("OnTextChanged", function(self, user)
        if user then self:SetText(MS.PlainHistory(conv[MS.current])) end
    end)
    copyEdit:SetScript("OnEscapePressed", function() MS.SetCopyMode(false) end)

    input = CreateFrame("EditBox", nil, win)
    input:SetPoint("BOTTOMLEFT", win, "BOTTOMLEFT", MS.LIST_W + 10, 26)
    input:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", -10, 26)
    input:SetHeight(24)
    input:SetAutoFocus(false)
    input:SetMaxLetters(255)
    input:SetFont(F.sans, 12, "")
    input:SetTextInsets(6, 6, 0, 0)
    local ib = input:CreateTexture(nil, "BACKGROUND")
    ib:SetAllPoints(input)
    ib:SetColorTexture(s1[1], s1[2], s1[3], 1)
    input:SetScript("OnEditFocusGained", function(self)
        -- Ohne "direkt senden": gleich die Chatzeile des Spiels.
        if not Get("direct") then
            self:ClearFocus()
            OpenGameReply(conv[MS.current])
        end
    end)
    input:SetScript("OnEnterPressed", function(self)
        local text = self:GetText() or ""
        self:SetText("")
        if text ~= "" then MS.Send(MS.current, text) end
    end)
    input:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    foot = K.NewText(win, 10)
    foot:SetPoint("BOTTOMLEFT", win, "BOTTOMLEFT", MS.LIST_W + 12, 8)
    foot:SetPoint("RIGHT", win, "RIGHT", -10, 0)
    foot:SetJustifyH("LEFT")
    foot:SetWordWrap(false)
    foot:SetTextColor(m[1], m[2], m[3])

    K.RegisterMover(win, "messenger", "Flüstern", K.Layout("messenger"))
    MS.win, MS.smf, MS.input, MS.title, MS.sub, MS.foot, MS.rows = win, smf, input, title, sub, foot, rows
    MS.copy, MS.copyEdit, MS.markBtn = copy, copyEdit, markBtn
    return win
end
MS.Build = Build

function MS.Redraw()
    if not win then return end
    for i, key in ipairs(order) do
        local c = conv[key]
        local r = rows[i] or NewRow(i)
        r.key = key
        r.label:SetText(WeintCodex.Truncate and WeintCodex.Truncate(c.name, 14) or c.name)
        local sel = key == MS.current
        local s = sel and C.surface3 or C.surface1
        r.bg:SetColorTexture(s[1], s[2], s[3], sel and 1 or 0)
        r.mark:SetShown(sel)
        local t = sel and C.textBright or C.textNormal
        r.label:SetTextColor(t[1], t[2], t[3])
        if c.unread > 0 then
            r.badge:SetText(tostring(c.unread))
            local a = C.accentBright or C.accent
            r.badge:SetTextColor(a[1], a[2], a[3])
        else
            r.badge:SetText("")
        end
        r:Show()
    end
    for i = #order + 1, #rows do rows[i]:Hide() end

    local c = conv[MS.current]
    smf:Clear()
    if not c then
        title:SetText("Flüstern")
        sub:SetText("Noch kein Gespräch in dieser Sitzung.")
    else
        title:SetText(MS.NameText(c))
        sub:SetText(c.bn and "Battle.net" or "")
        for _, line in ipairs(c.lines) do smf:AddMessage(MS.Format(c, line)) end
    end
    if MS.copyMode then
        copyEdit:SetText(MS.PlainHistory(c))
        local a = C.accent
        markBtn.t:SetTextColor(a[1], a[2], a[3])
        foot:SetText("Mit der Maus markieren, Strg+C kopiert  ·  Esc zurück")
        return
    end
    local m = C.textMuted
    markBtn.t:SetTextColor(m[1], m[2], m[3])
    local hint = Get("direct") and "Enter sendet" or "Klick: antworten in der Chatzeile"
    if MS.locked > 0 then
        hint = hint .. "  ·  " .. MS.locked .. " während einer Sperre nur im Chat"
    end
    foot:SetText(hint)
end

function MS.SetCopyMode(on)
    Build()
    MS.copyMode = on and true or false
    smf:SetShown(not MS.copyMode)
    copy:SetShown(MS.copyMode)
    if MS.copyMode then
        MS.Redraw()
        copyEdit:SetFocus()
    else
        copyEdit:ClearFocus()
        copyEdit:HighlightText(0, 0)
        MS.Redraw()
    end
end

function MS.Select(key)
    if not conv[key] then return end
    MS.current = key
    conv[key].unread = 0
    MS.Redraw()
end

function MS.Show(key)
    Build()
    if key then MS.current = key end
    if not conv[MS.current or ""] then MS.current = order[1] end
    if MS.current and conv[MS.current] then conv[MS.current].unread = 0 end
    MS.pending = nil
    win:Show()
    MS.Redraw()
end

function MS.Toggle()
    Build()
    if win:IsShown() then win:Hide() else MS.Show() end
end

-- Aufgehen - oder, im Kampf, bis danach warten.
local function Pop(key)
    if win and win:IsShown() then
        MS.Redraw()
        return
    end
    if K.InCombat() and not Get("combat") then
        MS.pending = key
        return
    end
    MS.Show(key)
end

--------------------------------------------------
-- Senden
--------------------------------------------------

local sendAt = -1e9

function MS.Send(key, text)
    local c = conv[key]
    if not c or type(text) ~= "string" or text == "" then return false end
    if not Get("direct") then return OpenGameReply(c, text) end
    sendAt = Clock()
    MS.blockedNow = nil
    local ok
    if c.bn then
        local f = _G.BNSendWhisper or (_G.C_BattleNet and _G.C_BattleNet.SendWhisper)
        ok = f and pcall(f, c.target, text)
    else
        local f = (_G.C_ChatInfo and _G.C_ChatInfo.SendChatMessage) or _G.SendChatMessage
        ok = f and pcall(f, text, "WHISPER", nil, c.target)
    end
    if MS.blockedNow or not ok then
        -- Das Spiel laesst es nicht: zurueck auf die Chatzeile, mit dem Text.
        OpenGameReply(c, text)
        return false
    end
    MS.lastDirect = "gesendet"
    return true
end

-- ADDON_ACTION_BLOCKED/FORBIDDEN kurz nach einem eigenen Sendeversuch:
-- gemessen gesperrt. Abschalten und merken.
function MS.OnBlocked(addon)
    addon = K.Plain(addon)
    if addon ~= "WeintCodex" or Clock() - sendAt > MS.BLOCK_WINDOW then return false end
    MS.blockedNow = true
    MS.lastDirect = "gesperrt"
    local ui = WeintCodex.SavedData and WeintCodex.SavedData.ui
    if type(ui) == "table" then ui.msgDirectBlocked = Time() end
    K.Set(KEY, "msgDirect", false)
    Say("Das Spiel lässt WeintCodex nicht selbst flüstern – Antworten gehen ab jetzt über die Chatzeile (Enter sendet).")
    return true
end

--------------------------------------------------
-- Ereignisse
--------------------------------------------------

local notFound   -- Muster aus ERR_CHAT_PLAYER_NOT_FOUND_S
local function NotFoundPattern()
    if notFound ~= nil then return notFound end
    local s = K.Plain(_G.ERR_CHAT_PLAYER_NOT_FOUND_S)
    if type(s) ~= "string" then notFound = false return false end
    s = s:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1"):gsub("%%%%s", "(.+)")
    notFound = "^" .. s .. "$"
    return notFound
end

local function KeyFor(sender, bnID)
    if bnID then return "bn:" .. bnID end
    return "w:" .. (MS.Short(sender) or sender)
end

-- Ein- oder ausgehendes Fluestern. Geheim: nur zaehlen.
function MS.OnWhisper(event, text, sender, guid, bnID)
    if not MS.Active() then return end
    text, sender, bnID = K.Plain(text), K.Plain(sender), K.Plain(bnID)
    local bn = event == "CHAT_MSG_BN_WHISPER" or event == "CHAT_MSG_BN_WHISPER_INFORM"
    if type(text) ~= "string" or type(sender) ~= "string" or (bn and type(bnID) ~= "number") then
        MS.locked = MS.locked + 1
        if win and win:IsShown() then MS.Redraw() end
        return
    end
    local out = event == "CHAT_MSG_WHISPER_INFORM" or event == "CHAT_MSG_BN_WHISPER_INFORM"
    local key = KeyFor(sender, bn and bnID or nil)
    local c = MS.Ensure(key, bn and sender or (MS.Short(sender) or sender), bn and bnID or sender, bn)
    if not bn then c.class = c.class or ClassOf(guid) end
    MS.Add(c, out and "out" or "in", text)
    local visible = win and win:IsShown()
    if not out and not (visible and MS.current == key) then c.unread = c.unread + 1 end
    if out and not visible and not Get("outgoing") then return end
    if not visible then MS.current = key end
    Pop(key)
end

-- Abwesend/Beschaeftigt-Antworten und "nicht online": in ein offenes Gespraech.
function MS.OnSystem(event, text, sender)
    if not MS.Active() then return end
    text, sender = K.Plain(text), K.Plain(sender)
    if type(text) ~= "string" then return end
    local c, line
    if event == "CHAT_MSG_SYSTEM" then
        local pat = NotFoundPattern()
        local who = pat and text:match(pat)
        c = who and conv[KeyFor(who)]
        line = c and (c.name .. " ist nicht online.")
    elseif type(sender) == "string" then
        c = conv[KeyFor(sender)]
        line = c and ((event == "CHAT_MSG_AFK" and "Abwesend" or "Beschäftigt") .. (text ~= "" and (": " .. text) or ""))
    end
    if not c then return end
    MS.Add(c, "sys", line)
    if win and win:IsShown() then MS.Redraw() end
end

local ev = CreateFrame("Frame")
MS.events = ev
local EVENTS = { "CHAT_MSG_WHISPER", "CHAT_MSG_WHISPER_INFORM", "CHAT_MSG_BN_WHISPER", "CHAT_MSG_BN_WHISPER_INFORM",
                 "CHAT_MSG_AFK", "CHAT_MSG_DND", "CHAT_MSG_SYSTEM", "PLAYER_REGEN_ENABLED",
                 "ADDON_ACTION_BLOCKED", "ADDON_ACTION_FORBIDDEN" }

local function OnEvent(_, event, a1, a2, ...)
    if event == "CHAT_MSG_WHISPER" or event == "CHAT_MSG_WHISPER_INFORM" then
        -- Angaben des Spiels: Text, Absender, ..., an 12. Stelle die GUID.
        local guid = select(10, ...)
        MS.OnWhisper(event, a1, a2, guid)
    elseif event == "CHAT_MSG_BN_WHISPER" or event == "CHAT_MSG_BN_WHISPER_INFORM" then
        -- ... an 13. Stelle die Nummer des Battle.net-Kontos.
        local bnID = select(11, ...)
        MS.OnWhisper(event, a1, a2, nil, bnID)
    elseif event == "PLAYER_REGEN_ENABLED" then
        if MS.pending and MS.Active() then MS.Show(MS.pending) end
    elseif event == "ADDON_ACTION_BLOCKED" or event == "ADDON_ACTION_FORBIDDEN" then
        MS.OnBlocked(a1)
    else
        MS.OnSystem(event, a1, a2)
    end
end
ev:SetScript("OnEvent", K.Measured("Flüstern", OnEvent))
MS.OnEvent = OnEvent

local function Apply()
    local on = MS.Active()
    if not on and MS.copyMode then MS.SetCopyMode(false) end
    for _, e in ipairs(EVENTS) do
        if on then pcall(ev.RegisterEvent, ev, e) else pcall(ev.UnregisterEvent, ev, e) end
    end
    if K.SetMoverEnabled and win then K.SetMoverEnabled("messenger", on) end
    if not on then
        MS.pending = nil
        if win then win:Hide() end
    elseif win and win:IsShown() then
        MS.Redraw()
    end
end
MS.Apply = Apply

--------------------------------------------------
-- Bericht (/wcui prüfen)
--------------------------------------------------

function MS.StatusLines()
    local out = {}
    local function has(f) return type(f) == "function" and "ja" or "nein" end
    local ci = type(_G.C_ChatInfo) == "table" and _G.C_ChatInfo or {}
    out[#out + 1] = "SendChatMessage: " .. has(ci.SendChatMessage or _G.SendChatMessage)
        .. " · BNSendWhisper: " .. has(_G.BNSendWhisper) .. " · Chatzeile öffnen: "
        .. has((_G.ChatFrameUtil and _G.ChatFrameUtil.OpenChat) or _G.ChatFrame_OpenChat)
    local ui = WeintCodex.SavedData and WeintCodex.SavedData.ui
    local blocked = type(ui) == "table" and ui.msgDirectBlocked
    out[#out + 1] = "Direkt senden: " .. (Get("direct") and "an" or "aus")
        .. (blocked and _G.date and (" · gemessen gesperrt am " .. _G.date("%d.%m. %H:%M", blocked)) or "")
        .. (MS.lastDirect and (" · zuletzt " .. MS.lastDirect) or "")
    out[#out + 1] = "Gespräche dieser Sitzung: " .. #order .. (MS.locked > 0 and (" · " .. MS.locked .. " während einer Sperre nur im Chat") or "")
    return out
end

--------------------------------------------------
-- Seite im Komfort
--------------------------------------------------

local function BuildPage(B)
    local off = function() return not K.Get(KEY, "msgOn") end
    B:Section("Flüstern", "Wird dir etwas zugeflüstert, geht ein Fenster auf wie bei einem Messenger. Im Chat steht es trotzdem – nichts wird dort versteckt. Der Verlauf gilt nur bis zum Ausloggen.")
    B:Row({ type = "toggle", label = "Flüstern im eigenen Fenster", key = "msgOn",
            description = "Auch Battle.net-Flüstern. /wcui flüstern öffnet es jederzeit." },
          { type = "toggle", label = "Auch im Kampf aufgehen", key = "msgCombat", disabled = off,
            description = "Sonst geht es nach dem Kampf auf." })
    B:Row({ type = "toggle", label = "Auch bei eigenem Flüstern", key = "msgOutgoing", disabled = off,
            description = "Flüsterst du jemandem im Chat, geht das Gespräch ebenfalls auf." },
          { type = "toggle", label = "Uhrzeit", key = "msgStamps", disabled = off })
    B:Row({ type = "toggle", label = "Direkt aus dem Fenster senden", key = "msgDirect", disabled = off,
            description = "Ungetestet: ob das Spiel es WeintCodex erlaubt. Sperrt es, schaltet sich das ab, und Antworten gehen wieder über die Chatzeile." })
    B:Note("Verschieben im Gestaltungsmodus. Esc schließt das Fenster, die Gespräche bleiben bis zum Ausloggen.")
end
MS.BuildPage = BuildPage

local mod = K.Module(KEY)
if mod then
    for k, v in pairs(MS.DEFAULTS) do
        if mod.defaults[k] == nil then mod.defaults[k] = v end
    end
    mod.pages[#mod.pages + 1] = { key = "fluestern", label = "Flüstern", build = BuildPage }
end

K.Listen(function(kind, key)
    if (kind == "active" or kind == "setting") and key == KEY then Apply() end
end)
