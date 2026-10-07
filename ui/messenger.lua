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
--   * Verlauf nur fuer diese Sitzung: nichts davon landet in den
--     gespeicherten Daten - die Datei liest auch die Companion-App, und
--     private Nachrichten gehoeren da nicht hinein.
--   * Nur Fluestern und Battle.net-Fluestern, nicht Gilde oder Gruppe.
--
-- NEU ENTSCHIEDEN (6.19.1.0, Beta-Test: "Whisper sollen nicht parallel auch
-- im Chat zu sehen sein. Dafuer ist dann wirklich dieses Messenger
-- Fenster."): bis 6.19.0.1 stand alles auch im Chat. Jetzt blendet ein
-- Chatfilter des Spiels (AddMessageEventFilter) Gefluestertes im Chat aus -
-- ausgeblendet, nie umgeschrieben, und NUR, was das Fenster selbst lesen
-- konnte (MS.Capturable): Geheimes bleibt im Chat, sonst stuende es
-- nirgends. Folge, die das Spiel bestimmt: Die Taste "Antworten" (R) kennt
-- nur, was der Chat gezeigt hat - den Absender selbst eintragen hiesse,
-- die Chatzeile des Spiels zu "verunreinigen" (taint), und dann sperrt
-- das Spiel /cast & Co. aus ihr heraus. Darum antwortet man im Fenster.
--   * Im Kampf klappt das Fenster ein (versteckt) und geht danach wieder
--     auf; das Symbol zaehlt solange die Ungelesenen.
--   * "/w Name" in der Chatzeile oder ein Klick auf einen Namen oeffnet
--     das Gespraech im Fenster. Die Chatzeile bleibt dabei unberuehrt -
--     WeintCodex liest nur ihre Attribute (chatType, tellTarget).
--   * Ein eigenes Symbol (ziehbar) oeffnet das Fenster jederzeit.
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
    msgCombat   = false,  -- auch im Kampf offen (sonst einklappen, danach wieder auf)
    msgOutgoing = true,   -- auch aufgehen, wenn du selbst jemandem fluesterst
    msgStamps   = true,   -- Uhrzeit vor jeder Zeile
    msgDirect   = false,  -- selbst senden (ungemessen)
    msgHideChat = true,   -- Gefluestertes nur im Fenster, nicht im Chat (6.19.1.0)
    msgIcon     = true,   -- Symbol zum Oeffnen (6.19.1.0)
}

MS.MAX_LINES = 200        -- je Gespraech, nur diese Sitzung
MS.MAX_CONV  = 8          -- so viele Gespraeche in der Liste
MS.W, MS.H   = 420, 260
MS.LIST_W    = 120
MS.ROW_H     = 24
MS.BLOCK_WINDOW = 1       -- so lange nach einem Sendeversuch zaehlt eine Sperrmeldung (s)

local SETTING = { combat = "msgCombat", outgoing = "msgOutgoing", stamps = "msgStamps", direct = "msgDirect",
                  hide = "msgHideChat", icon = "msgIcon" }
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
    MS.UpdateIcon()
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
    -- Ziehen am Fenster selbst (6.19.1.0), nicht nur im Gestaltungsmodus.
    K.DragToMove(win, "messenger")
    win:SetScript("OnHide", function() MS.UpdateIcon() end)
    win:SetScript("OnShow", function() MS.UpdateIcon() end)
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
    MS.UpdateIcon()
end

function MS.Show(key)
    Build()
    if key then MS.current = key end
    if not conv[MS.current or ""] then MS.current = order[1] end
    if MS.current and conv[MS.current] then conv[MS.current].unread = 0 end
    MS.pending, MS.folded = nil, nil
    win:Show()
    MS.Redraw()
    MS.UpdateIcon()
end

function MS.Toggle()
    Build()
    if win:IsShown() then win:Hide() else MS.Show() end
end

--------------------------------------------------
-- Symbol (6.19.1.0, Beta-Test: "die Moeglichkeit eines Icons, damit ich
-- die Whisper auch so wieder oeffnen kann")
--------------------------------------------------
-- Eine kleine Kachel mit der Sprechblase aus media/ui (icon_report,
-- eigenes Bild), die Zahl der Ungelesenen oben rechts. Klick: Fenster
-- auf/zu; ziehen verschiebt. Auch ohne Oberflaeche - wie der Helfer.

local icon

function MS.Unread()
    local n = 0
    for _, c in pairs(conv) do n = n + (c.unread or 0) end
    return n
end

local function BuildIcon()
    if icon then return icon end
    icon = CreateFrame("Button", "WeintCodexMessengerIcon", UIParent)
    icon:SetSize(32, 32)
    icon:SetFrameStrata("MEDIUM")
    icon:SetClampedToScreen(true)
    K.Kachel(icon, { shadow = 4 })
    icon.tex = icon:CreateTexture(nil, "ARTWORK")
    icon.tex:SetSize(20, 20)
    icon.tex:SetPoint("CENTER", icon, "CENTER", 0, 0)
    icon.tex:SetTexture(K.MEDIA .. "icon_report")
    icon.badge = K.NewText(icon, 10)
    icon.badge:SetPoint("TOPRIGHT", icon, "TOPRIGHT", -2, -2)
    if icon.RegisterForClicks then icon:RegisterForClicks("LeftButtonUp") end
    icon:SetScript("OnClick", function() MS.Toggle() end)
    icon:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Flüstern", 1, 1, 1)
        local n = MS.Unread()
        if n > 0 then GameTooltip:AddLine(n .. " ungelesen", unpack(C.accent)) end
        GameTooltip:AddLine("Klick: Fenster auf/zu. Ziehen verschiebt.", 0.7, 0.7, 0.75, true)
        GameTooltip:Show()
    end)
    icon:SetScript("OnLeave", function() GameTooltip:Hide() end)
    icon:Hide()
    K.RegisterMover(icon, "messengerIcon", "Flüstern-Symbol", K.Layout("messengerIcon"))
    K.DragToMove(icon, "messengerIcon")
    MS.icon = icon
    return icon
end
MS.BuildIcon = BuildIcon

function MS.UpdateIcon()
    local want = MS.Active() and Get("icon")
    if not want then
        if icon then icon:Hide() end
        return
    end
    BuildIcon()
    local n = MS.Unread()
    icon.badge:SetText(n > 0 and tostring(n) or "")
    local a = C.accentBright or C.accent
    icon.badge:SetTextColor(a[1], a[2], a[3])
    -- Hell, solange etwas ungelesen ist oder das Fenster offen.
    local lit = n > 0 or (win and win:IsShown())
    local t = lit and C.textBright or C.textMuted
    icon.tex:SetVertexColor(t[1], t[2], t[3])
    icon:Show()
end

-- Aufgehen - oder, im Kampf, bis danach warten.
local function Pop(key)
    if win and win:IsShown() then
        MS.Redraw()
        MS.UpdateIcon()
        return
    end
    if K.InCombat() and not Get("combat") then
        MS.pending = key
        MS.UpdateIcon()
        return
    end
    MS.Show(key)
end

-- Im Kampf einklappen, danach wieder auf (6.19.1.0, Beta-Test: "Wenn ich
-- infight bin, soll sich das Fenster automatisch minimieren und wieder
-- aufploppen, sobald ich aus dem Kampf raus bin").
function MS.OnCombat(start)
    if not MS.Active() then return end
    if start then
        if Get("combat") or not (win and win:IsShown()) then return end
        if MS.copyMode then MS.SetCopyMode(false) end
        MS.folded = MS.current or true
        win:Hide()
        return
    end
    local key = MS.pending or MS.folded
    MS.pending, MS.folded = nil, nil
    if key then MS.Show(key ~= true and key or nil) end
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

local BN_EVENT = { CHAT_MSG_BN_WHISPER = true, CHAT_MSG_BN_WHISPER_INFORM = true }
local WHISPER_EVENT = { CHAT_MSG_WHISPER = true, CHAT_MSG_WHISPER_INFORM = true,
                        CHAT_MSG_BN_WHISPER = true, CHAT_MSG_BN_WHISPER_INFORM = true }

-- Kann das Fenster diese Nachricht lesen? Nur dann darf der Chat sie
-- verbergen - der Filter und das Fenster fragen dieselbe Stelle.
function MS.Capturable(event, text, sender, bnID)
    if type(K.Plain(text)) ~= "string" or type(K.Plain(sender)) ~= "string" then return false end
    if BN_EVENT[event] then return type(K.Plain(bnID)) == "number" end
    return true
end

-- Verbirgt der Chat gerade Gefluestertes?
function MS.Hiding()
    return MS.Active() and Get("hide") and MS.filterApi and true or false
end

-- Der Ton des Spiels kommt aus der Chatzeile, die jetzt nicht gezeigt
-- wird - also einer von hier, hoechstens alle paar Sekunden.
MS.PING_GAP = 3
local pingAt = -1e9
function MS.Ping()
    local now = Clock()
    if now - pingAt < MS.PING_GAP then return false end
    pingAt = now
    local kit = _G.SOUNDKIT
    if _G.PlaySound then pcall(_G.PlaySound, (type(kit) == "table" and kit.TELL_MESSAGE) or 3081) end
    if _G.FlashClientIcon then pcall(_G.FlashClientIcon) end
    return true
end

-- Ein- oder ausgehendes Fluestern. Geheim: nur zaehlen.
function MS.OnWhisper(event, text, sender, guid, bnID)
    if not MS.Active() then return end
    if not MS.Capturable(event, text, sender, bnID) then
        MS.locked = MS.locked + 1
        if win and win:IsShown() then MS.Redraw() end
        return
    end
    text, sender, bnID = K.Plain(text), K.Plain(sender), K.Plain(bnID)
    local bn = BN_EVENT[event] or false
    local out = event == "CHAT_MSG_WHISPER_INFORM" or event == "CHAT_MSG_BN_WHISPER_INFORM"
    local key = KeyFor(sender, bn and bnID or nil)
    local c = MS.Ensure(key, bn and sender or (MS.Short(sender) or sender), bn and bnID or sender, bn)
    if not bn then c.class = c.class or ClassOf(guid) end
    MS.Add(c, out and "out" or "in", text)
    if not out and MS.Hiding() then MS.Ping() end
    local visible = win and win:IsShown()
    if not out and not (visible and MS.current == key) then c.unread = c.unread + 1 end
    if out and not visible and not Get("outgoing") then
        MS.UpdateIcon()
        return
    end
    if not visible then MS.current = key end
    Pop(key)
end

-- Abwesend/Beschaeftigt-Antworten und "nicht online": in welches Gespraech?
-- (nil: in keines - dann bleibt es auch im Chat.)
function MS.SystemTarget(event, text, sender)
    text, sender = K.Plain(text), K.Plain(sender)
    if type(text) ~= "string" then return nil end
    if event == "CHAT_MSG_SYSTEM" then
        local pat = NotFoundPattern()
        local who = pat and text:match(pat)
        local c = who and conv[KeyFor(who)]
        return c, c and (c.name .. " ist nicht online.")
    elseif type(sender) == "string" then
        local c = conv[KeyFor(sender)]
        return c, c and ((event == "CHAT_MSG_AFK" and "Abwesend" or "Beschäftigt") .. (text ~= "" and (": " .. text) or ""))
    end
    return nil
end

function MS.OnSystem(event, text, sender)
    if not MS.Active() then return end
    local c, line = MS.SystemTarget(event, text, sender)
    if not c then return end
    MS.Add(c, "sys", line)
    if win and win:IsShown() then MS.Redraw() end
end

--------------------------------------------------
-- Nur im Fenster: der Chatfilter (6.19.1.0)
--------------------------------------------------
-- true heisst: diese Zeile zeigt der Chat nicht. Nie veraenderte Angaben
-- zurueck - nur verbergen, und nur, was das Fenster selbst hat.

local FILTER_EVENTS = { "CHAT_MSG_WHISPER", "CHAT_MSG_WHISPER_INFORM", "CHAT_MSG_BN_WHISPER",
                        "CHAT_MSG_BN_WHISPER_INFORM", "CHAT_MSG_AFK", "CHAT_MSG_DND", "CHAT_MSG_SYSTEM" }

function MS.ChatFilter(_, event, text, sender, ...)
    if not MS.Hiding() then return false end
    if WHISPER_EVENT[event] then
        -- an 13. Stelle die Nummer des Battle.net-Kontos (wie OnEvent)
        local bnID = BN_EVENT[event] and select(11, ...) or nil
        return MS.Capturable(event, text, sender, bnID)
    end
    return MS.SystemTarget(event, text, sender) ~= nil
end

local function AddFilter()
    if MS.filterApi then return end
    local util = _G.ChatFrameUtil
    local add, api
    if type(util) == "table" and type(util.AddMessageEventFilter) == "function" then
        add, api = util.AddMessageEventFilter, "ChatFrameUtil.AddMessageEventFilter"
    elseif type(_G.ChatFrame_AddMessageEventFilter) == "function" then
        add, api = _G.ChatFrame_AddMessageEventFilter, "ChatFrame_AddMessageEventFilter"
    end
    if not add then
        MS.filterApi = false
        return
    end
    for _, e in ipairs(FILTER_EVENTS) do pcall(add, e, MS.ChatFilter) end
    MS.filterApi = api
end
MS.AddFilter = AddFilter

--------------------------------------------------
-- "/w Name" und Klick auf einen Namen (6.19.1.0)
--------------------------------------------------
-- Die Chatzeile des Spiels bleibt unberuehrt: WeintCodex haengt sich nur
-- hinten an (HookScript) und LIEST, an wen sie gerade fluestert. Ein
-- Gespraech geht einmal je Ziel auf, bis die Zeile wieder zu ist.

local lastEdit = setmetatable({}, { __mode = "k" })

function MS.KeyForTarget(kind, target)
    if kind == "WHISPER" then
        local key = KeyFor(target)
        MS.Ensure(key, MS.Short(target) or target, target, nil)
        return key
    end
    for key, c in pairs(conv) do
        if c.bn and c.name == target then
            Touch(key)
            return key
        end
    end
    local f = _G.BNet_GetBNetIDAccount
    if type(f) ~= "function" then return nil end
    local ok, id = pcall(f, target)
    id = ok and K.Plain(id) or nil
    if type(id) ~= "number" then return nil end
    local key = KeyFor(nil, id)
    MS.Ensure(key, target, id, true)
    return key
end

function MS.OnChatEdit(eb)
    if not (MS.Active() and Get("outgoing")) or type(eb) ~= "table" or not eb.GetAttribute then return end
    local kind, target = K.Plain(eb:GetAttribute("chatType")), K.Plain(eb:GetAttribute("tellTarget"))
    if (kind ~= "WHISPER" and kind ~= "BN_WHISPER") or type(target) ~= "string" or target == "" then
        lastEdit[eb] = nil
        return
    end
    local sig = kind .. "\1" .. target
    if lastEdit[eb] == sig then return end
    lastEdit[eb] = sig
    local key = MS.KeyForTarget(kind, target)
    if not key then return end
    if win and win:IsShown() then
        MS.Select(key)
    else
        MS.current = key
        Pop(key)
    end
end

local editHooked, headerHooked = {}, false
local function HookChatEdit()
    local function Forget(self) lastEdit[self] = nil end
    for i = 1, (_G.NUM_CHAT_WINDOWS or 10) do
        local eb = _G["ChatFrame" .. i .. "EditBox"]
        if type(eb) == "table" and eb.HookScript and not editHooked[eb] then
            editHooked[eb] = true
            pcall(eb.HookScript, eb, "OnShow", MS.OnChatEdit)
            pcall(eb.HookScript, eb, "OnTextChanged", MS.OnChatEdit)
            pcall(eb.HookScript, eb, "OnHide", Forget)
        end
    end
    if not headerHooked and type(_G.hooksecurefunc) == "function" and type(_G.ChatEdit_UpdateHeader) == "function" then
        headerHooked = true
        pcall(_G.hooksecurefunc, "ChatEdit_UpdateHeader", MS.OnChatEdit)
    end
end
MS.HookChatEdit = HookChatEdit

local ev = CreateFrame("Frame")
MS.events = ev
local EVENTS = { "CHAT_MSG_WHISPER", "CHAT_MSG_WHISPER_INFORM", "CHAT_MSG_BN_WHISPER", "CHAT_MSG_BN_WHISPER_INFORM",
                 "CHAT_MSG_AFK", "CHAT_MSG_DND", "CHAT_MSG_SYSTEM", "PLAYER_REGEN_ENABLED", "PLAYER_REGEN_DISABLED",
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
    elseif event == "PLAYER_REGEN_DISABLED" then
        MS.OnCombat(true)
    elseif event == "PLAYER_REGEN_ENABLED" then
        MS.OnCombat(false)
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
    if on then
        AddFilter()
        HookChatEdit()
    end
    if K.SetMoverEnabled and win then K.SetMoverEnabled("messenger", on) end
    if K.SetMoverEnabled and icon then K.SetMoverEnabled("messengerIcon", on and Get("icon")) end
    if not on then
        MS.pending, MS.folded = nil, nil
        if win then win:Hide() end
    elseif win and win:IsShown() then
        MS.Redraw()
    end
    MS.UpdateIcon()
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
    -- Nur im Fenster: welcher Chatfilter des Spiels da ist (6.19.1.0).
    local api = MS.filterApi
    out[#out + 1] = "Nur im Fenster: " .. (Get("hide") and "an" or "aus") .. " · Chatfilter: "
        .. (api and api or (api == false and "fehlt – Flüstern bleibt im Chat" or "noch nicht angemeldet"))
    return out
end

--------------------------------------------------
-- Seite im Komfort
--------------------------------------------------

local function BuildPage(B)
    local off = function() return not K.Get(KEY, "msgOn") end
    B:Section("Flüstern", "Wird dir etwas zugeflüstert, geht ein Fenster auf wie bei einem Messenger. Der Verlauf gilt nur bis zum Ausloggen.")
    B:Row({ type = "toggle", label = "Flüstern im eigenen Fenster", key = "msgOn",
            description = "Auch Battle.net-Flüstern. Das Symbol oder /wcui flüstern öffnet es jederzeit." },
          { type = "toggle", label = "Nur im Fenster, nicht im Chat", key = "msgHideChat", disabled = off,
            description = "Was das Fenster nicht lesen darf (Sperre des Spiels), bleibt im Chat. Die Taste „Antworten“ (R) kennt dann nur, was der Chat gezeigt hat – antworte im Fenster." })
    B:Row({ type = "toggle", label = "Im Kampf offen lassen", key = "msgCombat", disabled = off,
            description = "Sonst klappt es im Kampf ein und geht danach wieder auf." },
          { type = "toggle", label = "Bei eigenem Flüstern aufgehen", key = "msgOutgoing", disabled = off,
            description = "„/w Name“ in der Chatzeile oder ein Klick auf einen Namen öffnet das Gespräch." })
    B:Row({ type = "toggle", label = "Symbol zeigen", key = "msgIcon", disabled = off,
            description = "Klick öffnet das Fenster, die Zahl zeigt Ungelesenes. Ziehen verschiebt." },
          { type = "toggle", label = "Uhrzeit", key = "msgStamps", disabled = off })
    B:Row({ type = "toggle", label = "Direkt aus dem Fenster senden", key = "msgDirect", disabled = off,
            description = "Ungetestet: ob das Spiel es WeintCodex erlaubt. Sperrt es, schaltet sich das ab, und Antworten gehen wieder über die Chatzeile." })
    B:Note("Fenster und Symbol lassen sich mit der Maus ziehen. Esc schließt das Fenster, die Gespräche bleiben bis zum Ausloggen.")
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
