--------------------------------------------------
-- WeintCodex :: Oberflaeche - Chat
--------------------------------------------------
-- Die Chatfenster des Spiels im Stil von WeintCodex: eigene Schrift,
-- ruhiger dunkler Grund statt des Blizzard-Rahmens, flache Reiter, eine
-- Eingabezeile mit feinem Rand, die Knoepfe am Rand wahlweise weg.
--
-- WAS BEWUSST FEHLT: jedes Umschreiben von Nachrichten (kurze Kanal-
-- namen, anklickbare Links, Zeitstempel im Text). Dafuer muesste man
-- jede Nachricht per AddMessage abfangen und bearbeiten - und ab Client
-- 12.0 koennen Chatnachrichten in Kaempfen "secret" sein. Ein gsub auf
-- einer geheimen Zeichenkette ist ein Fehler, und ein Fehler in
-- AddMessage verschluckt die Nachricht. Zeitstempel bietet das Spiel
-- selbst an (Optionen -> Soziales).
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIChat = {}

local CH = WeintCodex.UIChat
local K  = WeintCodex.UIKit
local KEY = "chat"

-- Seit 6.3.0.0 (UI 2.0): der Chat ist EINE Kachel - Reiterzeile oben mit
-- feiner Linie, Text darunter, die Eingabezeile buendig angedockt. Die
-- Reiter bleiben sichtbar (das Spiel blendete sie aus, bis die Maus kam -
-- im Beta-Test "komisch, nicht clean"), die Knoepfe des Spiels stehen
-- klein rechts in der Reiterzeile statt in einer eigenen Spalte.
local defaults = {
    fontSize    = 13,
    bgAlpha     = 60,       -- Prozent
    buttons     = "tabrow", -- tabrow | column | hide | game: die Knoepfe des Spiels
    flatTabs    = true,
    tabsVisible = true,     -- Reiter nicht ausblenden, wenn die Maus weg ist
    editBoxSkin = true,
    editBoxTop  = false,
    -- Seit 6.3.0.7 (Beta-Test: "noch nicht gut, ElvUI-Style"): eine
    -- Infozeile unter dem Chat - Uhrzeit, Gold, freie Taschenplaetze,
    -- Haltbarkeit, Bildrate, Latenz. Beim Schreiben legt sich die
    -- Eingabezeile darueber (wie bei ElvUI).
    infoBar     = true,
    -- Die Bildlaufleiste und der "nach unten"-Knopf am rechten Rand:
    -- halbdurchsichtige Striche, die im Beta-Test stoerten (6.3.0.8).
    -- Blaettern geht weiter mit dem Mausrad.
    hideScrollBar = true,
}
local INFO_H = 22

local TAB_H = 24    -- Hoehe der Reiterzeile ueber dem Text
local PAD = 6       -- Rand der Kachel um den Text

local function Opt(k) return K.Get(KEY, k) end

local done = {}       -- [chatframe] = unsere Teile

local function name_of(f) return (f.GetName and f:GetName()) or "" end

-- Teile des Spiels, die unsichtbar bleiben sollen, auch wenn das Spiel
-- sie beim Ueberfahren wieder einblendet.
local keepHooked, keepGuard = {}, false
local function KeepHidden(r)
    if not keepHooked[r] and _G.hooksecurefunc then
        keepHooked[r] = true
        _G.hooksecurefunc(r, "SetAlpha", function(self)
            if keepGuard or not Opt("hideScrollBar") then return end
            keepGuard = true
            self:SetAlpha(0)
            keepGuard = false
        end)
    end
    keepGuard = true
    r:SetAlpha(0)
    keepGuard = false
end

local function Hide(r)
    if type(r) == "table" and r.SetAlpha then r:SetAlpha(0) end
end

-- Alle Texturen eines Rahmens, ausser den genannten. Die Namen der
-- Reiter-Teile wechseln zwischen den Clients; die Regionen selbst nicht.
local function HideTextures(frame, keep)
    if type(frame) ~= "table" or not frame.GetRegions then return end
    for _, r in ipairs({ frame:GetRegions() }) do
        if type(r) == "table" and r.GetObjectType and r:GetObjectType() == "Texture" and not keep[r] then
            r:SetAlpha(0)
        end
    end
end

local function SkinFrame(cf)
    if type(cf) ~= "table" or done[cf] then return done[cf] end
    local name = cf.GetName and cf:GetName()
    if not name then return nil end
    local d = {}

    -- Der eigene Grund liegt hinter dem Text; die Blizzard-Texturen des
    -- Fensterhintergrunds werden unsichtbar (nicht versteckt: das Spiel
    -- blendet sie beim Ueberfahren selbst wieder ein).
    -- Der Grund reicht ueber die Reiter: Reiter und Text sind eine Flaeche.
    -- Auf einem eigenen Rahmen UNTER Chat und Reitern: auf dem Chatrahmen
    -- selbst lag die Flaeche ueber den Reitern (die eine Stufe tiefer
    -- stehen) - im Beta-Test waren sie deshalb unsichtbar (6.3.0.7).
    d.back = CreateFrame("Frame", nil, cf)
    local host = d.back
    d.bg = host:CreateTexture(nil, "BACKGROUND", nil, -7)
    d.bg:SetPoint("TOPLEFT", cf, "TOPLEFT", -PAD, TAB_H + 4)
    d.bg:SetPoint("BOTTOMRIGHT", cf, "BOTTOMRIGHT", PAD, -PAD)
    -- Reiterzeile: etwas dunkler, darunter eine feine Linie.
    d.strip = host:CreateTexture(nil, "BACKGROUND", nil, -6)
    d.strip:SetPoint("TOPLEFT", d.bg, "TOPLEFT", 0, 0)
    d.strip:SetPoint("TOPRIGHT", d.bg, "TOPRIGHT", 0, 0)
    d.strip:SetHeight(TAB_H)
    d.hair = host:CreateTexture(nil, "BACKGROUND", nil, -5)
    d.hair:SetPoint("TOPLEFT", d.strip, "BOTTOMLEFT", 0, 0)
    d.hair:SetPoint("TOPRIGHT", d.strip, "BOTTOMRIGHT", 0, 0)
    d.hair:SetHeight(1)
    -- Rand um die ganze Kachel (an der Grundflaeche, nicht am Chatrahmen:
    -- sie reicht ueber die Reiter).
    d.edges = {}
    for i = 1, 4 do
        local t = host:CreateTexture(nil, "BORDER")
        t:SetColorTexture(0, 0, 0, 1)
        d.edges[i] = t
    end
    d.edges[1]:SetPoint("BOTTOMLEFT", d.bg, "TOPLEFT", -1, 0)
    d.edges[1]:SetPoint("BOTTOMRIGHT", d.bg, "TOPRIGHT", 1, 0)
    d.edges[1]:SetHeight(1)
    d.edges[2]:SetPoint("TOPLEFT", d.bg, "BOTTOMLEFT", -1, 0)
    d.edges[2]:SetPoint("TOPRIGHT", d.bg, "BOTTOMRIGHT", 1, 0)
    d.edges[2]:SetHeight(1)
    d.edges[3]:SetPoint("TOPRIGHT", d.bg, "TOPLEFT", 0, 0)
    d.edges[3]:SetPoint("BOTTOMRIGHT", d.bg, "BOTTOMLEFT", 0, 0)
    d.edges[3]:SetWidth(1)
    d.edges[4]:SetPoint("TOPLEFT", d.bg, "TOPRIGHT", 0, 0)
    d.edges[4]:SetPoint("BOTTOMLEFT", d.bg, "BOTTOMRIGHT", 0, 0)
    d.edges[4]:SetWidth(1)
    d.shadow = K.Glow(d.bg, { host = host, spread = 7, shadow = true })
    for _, suffix in ipairs({ "Background", "TopLeftTexture", "TopRightTexture", "BottomLeftTexture",
        "BottomRightTexture", "TopTexture", "BottomTexture", "LeftTexture", "RightTexture" }) do
        Hide(_G[name .. suffix])
    end

    d.tab = _G[name .. "Tab"]
    if type(d.tab) ~= "table" then d.tab = nil end
    if d.tab then
        -- Der aktive Reiter bekommt einen Strich darunter.
        d.line = d.tab:CreateTexture(nil, "OVERLAY")
        d.line:SetHeight(2)
        d.line:SetPoint("BOTTOMLEFT", d.tab, "BOTTOMLEFT", 6, 2)
        d.line:SetPoint("BOTTOMRIGHT", d.tab, "BOTTOMRIGHT", -6, 2)
        local a = WeintCodex.Colors.accent
        d.line:SetColorTexture(a[1], a[2], a[3], 1)
        d.line:Hide()
        for _, suffix in ipairs({ "Left", "Middle", "Right", "SelectedLeft", "SelectedMiddle",
            "SelectedRight", "HighlightLeft", "HighlightMiddle", "HighlightRight",
            "ActiveLeft", "ActiveMiddle", "ActiveRight" }) do
            d[suffix] = _G[name .. "Tab" .. suffix] or d.tab[suffix]
        end
    end

    d.edit = _G[name .. "EditBox"]
    if type(d.edit) ~= "table" then d.edit = nil end
    if d.edit then
        d.editParts = {}
        for _, suffix in ipairs({ "Left", "Mid", "Right", "FocusLeft", "FocusMid", "FocusRight" }) do
            d.editParts[#d.editParts + 1] = _G[name .. "EditBox" .. suffix] or d.edit[suffix]
        end
        d.editBg = d.edit:CreateTexture(nil, "BACKGROUND")
        d.editBg:SetAllPoints(d.edit)
        -- Der Rand haengt am Eingabefeld selbst: eine Textur kann keine
        -- Texturen anlegen (in 6.0.0.3 brach der Chat genau daran ab).
        d.editBorder = K.Border(d.edit, 1, 0, 0, 0, 1, "BORDER")
        d.editKeep = { [d.editBg] = true, [d.editBorder.top] = true, [d.editBorder.bottom] = true,
                       [d.editBorder.left] = true, [d.editBorder.right] = true }
    end

    d.buttonFrame = _G[name .. "ButtonFrame"]
    if type(d.buttonFrame) ~= "table" then d.buttonFrame = cf.buttonFrame end
    if type(d.buttonFrame) ~= "table" then d.buttonFrame = nil end
    done[cf] = d
    return d
end

-- Frame-Stufe einer Flaeche, oder nil, wenn der Client sie nicht offen nennt.
local function Level(f)
    local v = f and f.GetFrameLevel and K.Plain(f:GetFrameLevel())
    return type(v) == "number" and v or nil
end

local function ApplyFrame(cf, d)
    -- Die Flaeche eine Stufe unter Chat und Reiter (ein Kind darf tiefer
    -- stehen als sein Elternrahmen).
    local low = Level(cf) or 1
    local tl = Level(d.tab)
    if tl and tl < low then low = tl end
    d.back:SetFrameStrata(cf.GetFrameStrata and cf:GetFrameStrata() or "LOW")
    d.back:SetFrameLevel(math.max(0, low - 1))
    d.back:SetAllPoints(cf)
    local path = K.FontPath()
    -- Chat ohne Kontur: lange Zeilen lesen sich mit Schatten ruhiger.
    cf:SetFont(path, Opt("fontSize"), "")
    if cf.SetShadowOffset then
        cf:SetShadowOffset(1, -1)
        cf:SetShadowColor(0, 0, 0, 1)
    end
    local a = (Opt("bgAlpha") or 60) / 100
    local fill = WeintCodex.GameColors.kachelFill
    d.bg:SetColorTexture(fill[1], fill[2], fill[3], a)
    local panel = WeintCodex.Colors.bgPanel
    d.strip:SetColorTexture(panel[1], panel[2], panel[3], math.min(1, a + 0.15))
    local hair = WeintCodex.Colors.border
    d.hair:SetColorTexture(hair[1], hair[2], hair[3], 1)

    if d.tab and Opt("flatTabs") then
        for _, suffix in ipairs({ "Left", "Middle", "Right", "SelectedLeft", "SelectedMiddle",
            "SelectedRight", "HighlightLeft", "HighlightMiddle", "HighlightRight",
            "ActiveLeft", "ActiveMiddle", "ActiveRight" }) do
            Hide(d[suffix])
        end
        -- Das Aufleuchten bei neuen Fluesternachrichten bleibt.
        HideTextures(d.tab, { [d.tab.glow or false] = true, [d.tab.conversationIcon or false] = true,
                              [d.line or false] = true })
        -- Die Schrift des Reiters bleibt die des Spiels: es misst die
        -- Reiterbreite an ihr, und eine andere Schrift schnitt die Namen
        -- ab ("Allge...", 6.0.0.5). Gefaerbt wird nur (UpdateTabs).
    end

    if d.edit and Opt("editBoxSkin") then
        for _, r in ipairs(d.editParts) do Hide(r) end
        HideTextures(d.edit, d.editKeep)
        local s = WeintCodex.Colors.surface1
        d.editBg:SetColorTexture(s[1], s[2], s[3], 0.9)
        local b = WeintCodex.Colors.borderStrong
        d.editBorder:SetColor(b[1], b[2], b[3], 1)
        d.editBg:Show()
        K.SetFont(d.edit, Opt("fontSize"))
        if d.edit.header then K.SetFont(d.edit.header, Opt("fontSize")) end
        -- Buendig an der Kachel: gleiche Breite, direkt darunter (bzw.
        -- ueber der Reiterzeile).
        K.AfterCombat(function()
            d.edit:ClearAllPoints()
            if Opt("editBoxTop") then
                d.edit:SetPoint("BOTTOMLEFT", cf, "TOPLEFT", -PAD, TAB_H + 6)
                d.edit:SetPoint("BOTTOMRIGHT", cf, "TOPRIGHT", PAD, TAB_H + 6)
            elseif Opt("infoBar") then
                -- Genau ueber der Infozeile: beim Schreiben ersetzt sie sie.
                d.edit:SetPoint("TOPLEFT", cf, "BOTTOMLEFT", -PAD, -PAD - 2)
                d.edit:SetPoint("TOPRIGHT", cf, "BOTTOMRIGHT", PAD, -PAD - 2)
                d.edit:SetHeight(INFO_H)
            else
                d.edit:SetPoint("TOPLEFT", cf, "BOTTOMLEFT", -PAD, -PAD - 2)
                d.edit:SetPoint("TOPRIGHT", cf, "BOTTOMRIGHT", PAD, -PAD - 2)
            end
        end)
    end

    if Opt("hideScrollBar") then
        for _, part in ipairs({ cf.ScrollBar, cf.ScrollToBottomButton, _G[name_of(cf) .. "ScrollToBottomButton"],
            d.buttonFrame and d.buttonFrame.ScrollToBottomButton or nil }) do
            if type(part) == "table" and part.SetAlpha and not (part.IsForbidden and part:IsForbidden()) then
                KeepHidden(part)
                if part.EnableMouse then pcall(part.EnableMouse, part, false) end
            end
        end
    end

    -- Versteckt, nicht nur durchsichtig: das Spiel blendet die Knopfleiste
    -- beim Ueberfahren selbst wieder ein (in 6.0.0.3 blieben die Knoepfe
    -- deshalb sichtbar). Die Knoepfe, die zaehlen, stehen dann in der
    -- Spalte (siehe unten).
    if d.buttonFrame and Opt("buttons") ~= "game" then K.HideBlizzard(d.buttonFrame, true) end
end

-- Reiter sichtbar halten. Das Spiel blendet sie ein paar Sekunden nach
-- der Maus aus; die Werte dafuer (CHAT_FRAME_TAB_*_NOMOUSE_ALPHA) setzt
-- ApplyAll, aber im Beta-Test waren die Reiter trotzdem weg (6.3.0.6) -
-- der Client liest sie offenbar nicht mehr. Ein Haken auf SetAlpha haelt
-- jeden Reiter bei mindestens seiner Deckkraft.
local tabHooked, tabGuard = {}, false
local function TabFloor(tab)
    for cf, d in pairs(done) do
        if d.tab == tab then
            local cur = _G.SELECTED_CHAT_FRAME
            if _G.FCF_GetCurrentChatFrame then
                local ok, f = pcall(_G.FCF_GetCurrentChatFrame)
                if ok and f then cur = f end
            end
            return cf == cur and 1 or 0.8
        end
    end
    return 0.8
end
local function KeepTabVisible(tab)
    if tabHooked[tab] or not _G.hooksecurefunc then return end
    tabHooked[tab] = true
    _G.hooksecurefunc(tab, "SetAlpha", function(self, a)
        if tabGuard or not Opt("tabsVisible") then return end
        local want = TabFloor(self)
        local plain = K.Plain(a)
        if type(plain) == "number" and plain >= want then return end
        tabGuard = true
        self:SetAlpha(want)
        tabGuard = false
    end)
end

-- Reiter: flach, der aktive hell mit Strich, die anderen gedaempft.
local function CurrentFrame()
    if _G.FCF_GetCurrentChatFrame then
        local ok, f = pcall(_G.FCF_GetCurrentChatFrame)
        if ok and f then return f end
    end
    return _G.SELECTED_CHAT_FRAME or _G.DEFAULT_CHAT_FRAME
end

local function UpdateTabs()
    if not Opt("flatTabs") then return end
    local cur = CurrentFrame()
    local C = WeintCodex.Colors
    for cf, d in pairs(done) do
        if d.tab and d.line then
            local on = (cf == cur)
            d.line:SetShown(on)
            local fs = d.tab.Text or (d.tab.GetFontString and d.tab:GetFontString())
            if type(fs) == "table" and fs.SetTextColor then
                fs:SetTextColor(unpack(on and C.textBright or C.textMuted))
            end
            if Opt("tabsVisible") and d.tab:IsShown() then
                tabGuard = true
                d.tab:SetAlpha(on and 1 or 0.8)
                tabGuard = false
            end
        end
    end
end
CH.UpdateTabs = UpdateTabs

--------------------------------------------------
-- Knopfspalte
--------------------------------------------------
-- Freunde, Sprachkanaele, Menue: eine schmale Spalte links neben dem
-- Chat statt ueber den Rand verteilt - so ordnet es auch EllesmereUI.
-- Die Knoepfe bleiben die des Spiels; nur ihr Platz aendert sich.

local COLUMN_BUTTONS = { "QuickJoinToastButton", "ChatFrameChannelButton", "ChatFrameMenuButton",
    "TextToSpeechButtonFrame", "ChatFrameToggleVoiceDeafenButton", "ChatFrameToggleVoiceMuteButton" }
local column, tabrow

-- Die Knoepfe klein rechts in der Reiterzeile, von rechts nach links.
local function LayoutTabRow()
    local cf = _G.ChatFrame1
    if type(cf) ~= "table" then return end
    if not tabrow then tabrow = CreateFrame("Frame", "WeintCodexChatTabRow", UIParent) end
    tabrow:ClearAllPoints()
    tabrow:SetPoint("TOPRIGHT", cf, "TOPRIGHT", PAD - 2, TAB_H + 2)
    tabrow:SetSize(120, TAB_H - 2)
    tabrow:SetFrameStrata(cf:GetFrameStrata() or "LOW")
    tabrow:SetFrameLevel((cf:GetFrameLevel() or 1) + 5)
    local x = 0
    for _, n in ipairs(COLUMN_BUTTONS) do
        local b = _G[n]
        if type(b) == "table" and b.SetParent and not (b.IsForbidden and b:IsForbidden()) then
            local scale = 0.62
            b:SetParent(tabrow)
            b:ClearAllPoints()
            b:SetPoint("RIGHT", tabrow, "RIGHT", -x / scale, 0)
            if b.SetScale then b:SetScale(scale) end
            local w = b.GetWidth and b:GetWidth() or 24
            if type(w) ~= "number" or w <= 0 or w > 60 then w = 24 end
            x = x + w * scale + 3
        end
    end
    tabrow:Show()
end
CH.LayoutTabRow = LayoutTabRow

local function LayoutColumn()
    local cf = _G.ChatFrame1
    if type(cf) ~= "table" then return end
    if not column then
        column = CreateFrame("Frame", "WeintCodexChatButtons", UIParent)
        column.bg = column:CreateTexture(nil, "BACKGROUND")
        column.bg:SetAllPoints(column)
    end
    local bg = WeintCodex.Colors.bgDark
    column.bg:SetColorTexture(bg[1], bg[2], bg[3], (Opt("bgAlpha") or 70) / 100)
    column:ClearAllPoints()
    column:SetPoint("TOPRIGHT", cf, "TOPLEFT", -6, 28)
    column:SetPoint("BOTTOMRIGHT", cf, "BOTTOMLEFT", -6, -4)
    column:SetWidth(26)
    local y = 4
    for _, n in ipairs(COLUMN_BUTTONS) do
        local b = _G[n]
        if type(b) == "table" and b.SetParent and not (b.IsForbidden and b:IsForbidden()) then
            b:SetParent(column)
            b:ClearAllPoints()
            b:SetPoint("TOP", column, "TOP", 0, -y)
            if b.SetScale then b:SetScale(0.75) end
            local h = b.GetHeight and b:GetHeight() or 24
            if type(h) ~= "number" or h <= 0 or h > 60 then h = 24 end
            y = y + h * 0.75 + 4
        end
    end
    column:Show()
end

--------------------------------------------------
-- Infozeile unter dem Chat
--------------------------------------------------
-- Wie die Datenleiste von ElvUI: eine schmale Kachel unter dem Chat mit
-- dem, was man zwischendurch wissen will. Links Uhrzeit und Gold, rechts
-- Taschen, Haltbarkeit, Bildrate und Latenz. Jeder Wert nur, wenn der
-- Client ihn offen nennt - sonst "–", nie eine erfundene Null. Klick auf
-- Uhrzeit: Kalender, auf Gold oder Taschen: alle Taschen.
--
-- Die Eingabezeile legt sich beim Schreiben darueber und verdeckt sie;
-- steht sie immer offen (Chatstil "klassisch"), bleibt die Infozeile weg.

local info
local function Money()
    local m = K.Plain(_G.GetMoney and _G.GetMoney())
    if type(m) ~= "number" then return "–" end
    local g = math.floor(m / 10000)
    local sv = math.floor((m % 10000) / 100)
    local big = (_G.BreakUpLargeNumbers and _G.BreakUpLargeNumbers(g)) or tostring(g)
    return WeintCodex.ColorText("gold", big) .. " g  " .. sv .. " s"
end
CH.Money = Money

local function FreeSlots()
    local cc = _G.C_Container
    local fn = cc and cc.GetContainerNumFreeSlots or _G.GetContainerNumFreeSlots
    if not fn then return nil end
    local free, any = 0, false
    for bag = 0, 4 do
        local ok, n = pcall(fn, bag)
        n = ok and K.Plain(n) or nil
        if type(n) == "number" then free, any = free + n, true end
    end
    return any and free or nil
end
CH.FreeSlots = FreeSlots

local function Durability()
    if not _G.GetInventoryItemDurability then return nil end
    local low
    for slot = 1, 19 do
        local ok, cur, max = pcall(_G.GetInventoryItemDurability, slot)
        cur, max = ok and K.Plain(cur) or nil, ok and K.Plain(max) or nil
        if type(cur) == "number" and type(max) == "number" and max > 0 then
            local pct = cur / max * 100
            if not low or pct < low then low = pct end
        end
    end
    return low
end
CH.Durability = Durability

local function InfoCell(parent, onClick, tip)
    local b = CreateFrame("Button", nil, parent)
    b:SetHeight(INFO_H)
    b.text = K.NewText(b, 11)
    b.text:SetPoint("CENTER", b, "CENTER", 0, 0)
    b.text:SetTextColor(unpack(WeintCodex.Colors.textMuted))
    if onClick then b:SetScript("OnClick", onClick) end
    b:SetScript("OnEnter", function(self)
        self.text:SetTextColor(unpack(WeintCodex.Colors.textBright))
        if tip then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(tip, 1, 1, 1)
            GameTooltip:Show()
        end
    end)
    b:SetScript("OnLeave", function(self)
        self.text:SetTextColor(unpack(WeintCodex.Colors.textMuted))
        GameTooltip:Hide()
    end)
    return b
end

local function Set(cell, text)
    cell.text:SetText(text)
    local w = cell.text.GetStringWidth and K.Plain(cell.text:GetStringWidth())
    cell:SetWidth((type(w) == "number" and w or 40) + 12)
end

function CH.UpdateInfoBar()
    if not info then return end
    local dim = WeintCodex.ColorText
    local h
    if _G.date then
        local ok, t = pcall(_G.date, "%H:%M")
        if ok then h = t end
    end
    Set(info.clock, h or "–")
    Set(info.money, Money())
    local free = FreeSlots()
    Set(info.bags, free and (dim("textDim", "Taschen ") .. free) or (dim("textDim", "Taschen ") .. "–"))
    local dur = Durability()
    if dur then
        local tone = dur < 20 and "danger" or (dur < 50 and "warning" or nil)
        local v = string.format("%d%%", math.floor(dur + 0.5))
        Set(info.dur, dim("textDim", "Rüstung ") .. (tone and dim(tone, v) or v))
    else
        Set(info.dur, dim("textDim", "Rüstung ") .. "–")
    end
    local fps = K.Plain(_G.GetFramerate and _G.GetFramerate())
    Set(info.fps, type(fps) == "number" and (string.format("%d", math.floor(fps + 0.5)) .. dim("textDim", " fps")) or "–")
    local lat
    if _G.GetNetStats then
        local ok, _, _, home, world = pcall(_G.GetNetStats)
        home, world = ok and K.Plain(home) or nil, ok and K.Plain(world) or nil
        lat = type(world) == "number" and world or (type(home) == "number" and home or nil)
    end
    Set(info.ms, type(lat) == "number" and (tostring(lat) .. dim("textDim", " ms")) or "–")
end

local function BuildInfoBar()
    local cf = _G.ChatFrame1
    if type(cf) ~= "table" then return end
    if not info then
        info = CreateFrame("Frame", "WeintCodexChatInfo", UIParent)
        info.kachel = K.Kachel(info, { shadow = 6 })
        local function Bags() if _G.ToggleAllBags then _G.ToggleAllBags() end end
        info.clock = InfoCell(info, function() if _G.ToggleCalendar then pcall(_G.ToggleCalendar) end end, "Kalender")
        info.money = InfoCell(info, Bags, "Taschen öffnen")
        info.bags = InfoCell(info, Bags, "Freie Taschenplätze")
        info.dur = InfoCell(info, nil, "Niedrigste Haltbarkeit deiner Ausrüstung")
        info.fps = InfoCell(info, nil, "Bildrate")
        info.ms = InfoCell(info, nil, "Latenz (Welt)")
        info.clock:SetPoint("LEFT", info, "LEFT", 2, 0)
        info.money:SetPoint("LEFT", info.clock, "RIGHT", 2, 0)
        info.ms:SetPoint("RIGHT", info, "RIGHT", -2, 0)
        info.fps:SetPoint("RIGHT", info.ms, "LEFT", -2, 0)
        info.dur:SetPoint("RIGHT", info.fps, "LEFT", -2, 0)
        info.bags:SetPoint("RIGHT", info.dur, "LEFT", -2, 0)
        local acc = 0
        info:SetScript("OnUpdate", function(_, el)
            acc = acc + (el or 0)
            if acc < 1 then return end
            acc = 0
            CH.UpdateInfoBar()
        end)
        for _, e in ipairs({ "PLAYER_MONEY", "BAG_UPDATE", "UPDATE_INVENTORY_DURABILITY", "PLAYER_ENTERING_WORLD" }) do
            pcall(info.RegisterEvent, info, e)
        end
        info:SetScript("OnEvent", function() CH.UpdateInfoBar() end)
        -- Die Eingabezeile ersetzt sie beim Schreiben.
        local eb = _G.ChatFrame1EditBox
        if type(eb) == "table" and eb.HookScript then
            eb:HookScript("OnShow", function() if Opt("infoBar") then info:SetAlpha(0) end end)
            eb:HookScript("OnHide", function() if Opt("infoBar") then info:SetAlpha(1) end end)
        end
    end
    info:ClearAllPoints()
    info:SetPoint("TOPLEFT", cf, "BOTTOMLEFT", -PAD, -PAD - 2)
    info:SetPoint("TOPRIGHT", cf, "BOTTOMRIGHT", PAD, -PAD - 2)
    info:SetHeight(INFO_H)
    info:SetFrameStrata(cf:GetFrameStrata() or "LOW")
    local eb = _G.ChatFrame1EditBox
    local always = type(eb) == "table" and eb.IsShown and eb:IsShown() and not (eb.HasFocus and eb:HasFocus())
    info:SetAlpha(always and 0 or 1)
    info:Show()
    CH.UpdateInfoBar()
end
CH.info = function() return info end

--------------------------------------------------
-- Nachsehen: /wcui chat
--------------------------------------------------
-- Im Beta-Client blieben die Reiter in drei Fassungen unsichtbar, und die
-- Knoepfe standen links statt in der Reiterzeile - die Annahmen ueber den
-- Chat dieses Clients stimmen nicht. Diese Zeilen sagen, was wirklich da
-- ist: Reiter, ihr Elternrahmen, Deckkraft, Stufe, Lage.

local function Describe(f)
    if type(f) ~= "table" then return "fehlt" end
    local function P(v) v = K.Plain(v) return type(v) == "number" and string.format("%.2f", v) or tostring(v) end
    local ok, out = pcall(function()
        local parent = f.GetParent and f:GetParent()
        local pname = parent and parent.GetName and parent:GetName() or (parent and "(ohne Namen)" or "keiner")
        local ea = f.GetEffectiveAlpha and f:GetEffectiveAlpha()
        return string.format("gezeigt %s, sichtbar %s, Alpha %s (wirksam %s), %s/%s, links %s oben %s, Eltern %s",
            tostring(K.Bool(f:IsShown(), false)), tostring(K.Bool(f:IsVisible(), false)),
            P(f:GetAlpha()), P(ea), tostring(f.GetFrameStrata and f:GetFrameStrata()),
            P(f.GetFrameLevel and f:GetFrameLevel()), P(f.GetLeft and f:GetLeft()), P(f.GetTop and f:GetTop()), pname)
    end)
    return ok and out or ("nicht lesbar: " .. tostring(out))
end
CH.Describe = Describe

function CH.Inspect()
    local out = {}
    local cf = _G.ChatFrame1
    out[#out + 1] = "Chatfenster 1: " .. Describe(cf)
    local d = cf and done[cf]
    out[#out + 1] = "Unsere Fläche: " .. (d and d.back and Describe(d.back) or "fehlt")
    local tab = _G.ChatFrame1Tab
    out[#out + 1] = "Reiter 1: " .. Describe(tab)
    if type(tab) == "table" then
        local fs = tab.Text
        if type(fs) ~= "table" and tab.GetFontString then fs = tab:GetFontString() end
        if type(fs) ~= "table" then fs = nil end
        local text = fs and fs.GetText and K.Plain(fs:GetText())
        out[#out + 1] = "Reiter 1 Text: " .. tostring(text) .. " · Schrift " .. (fs and Describe(fs) or "fehlt")
        if fs and fs.GetTextColor then
            local ok, r, g, b, a = pcall(fs.GetTextColor, fs)
            if ok then
                out[#out + 1] = string.format("Reiter 1 Textfarbe: %.2f %.2f %.2f %.2f",
                    K.Plain(r) or -1, K.Plain(g) or -1, K.Plain(b) or -1, K.Plain(a) or -1)
            end
        end
        -- Eine laufende Blendanimation aendert, was man sieht, aber nicht
        -- GetAlpha - und eine beschneidende Andockleiste versteckt Reiter,
        -- die IsVisible fuer sichtbar haelt.
        local function Anims(f)
            if not (f and f.GetAnimationGroups) then return "keine Abfrage" end
            local ok, groups = pcall(function() return { f:GetAnimationGroups() } end)
            if not ok then return "nicht lesbar" end
            local n, playing = 0, 0
            for _, g in ipairs(groups) do
                n = n + 1
                if g.IsPlaying and K.Bool(g:IsPlaying(), false) then playing = playing + 1 end
            end
            return string.format("%d, davon laufend %d", n, playing)
        end
        out[#out + 1] = "Reiter 1 Animationen: " .. Anims(tab) .. " · Text: " .. Anims(fs)
        local dock = _G.GeneralDockManager
        local function Clips(f)
            if not (f and f.DoesClipChildren) then return "?" end
            local ok, v = pcall(f.DoesClipChildren, f)
            return ok and tostring(K.Bool(v, false)) or "?"
        end
        out[#out + 1] = "Beschneidet: Andockleiste " .. Clips(dock) .. ", Chatfenster " .. Clips(cf)
            .. ", Reiter-Elternrahmen " .. Clips(tab.GetParent and tab:GetParent())
        local b = K.Plain(tab.GetBottom and tab:GetBottom())
        local r = K.Plain(tab.GetRight and tab:GetRight())
        out[#out + 1] = "Reiter 1 unten " .. tostring(b) .. ", rechts " .. tostring(r)
            .. " · Andockleiste unten " .. tostring(dock and K.Plain(dock:GetBottom()))
    end
    for i = 2, 4 do
        local t = _G["ChatFrame" .. i .. "Tab"]
        if type(t) == "table" then out[#out + 1] = "Reiter " .. i .. ": " .. Describe(t) end
    end
    out[#out + 1] = "Andockleiste: " .. Describe(_G.GeneralDockManager)
    for _, n in ipairs(COLUMN_BUTTONS) do
        if type(_G[n]) == "table" then out[#out + 1] = n .. ": " .. Describe(_G[n]) end
    end
    out[#out + 1] = "Knopfleiste des Spiels: " .. Describe(d and d.buttonFrame)
    local eb = _G.ChatFrame1EditBox
    out[#out + 1] = "Eingabezeile: " .. Describe(eb)
    out[#out + 1] = "Infozeile: " .. (info and Describe(info) or "nicht angelegt")
    return out
end

local function ApplyAll()
    for i = 1, (_G.NUM_CHAT_WINDOWS or 10) do
        local cf = _G["ChatFrame" .. i]
        local d = SkinFrame(cf)
        if d then ApplyFrame(cf, d) end
    end
    local mode = Opt("buttons")
    if mode == "hide" then
        for _, n in ipairs(COLUMN_BUTTONS) do K.HideBlizzard(n, true) end
    elseif mode == "column" then
        K.AfterCombat(LayoutColumn)
    elseif mode == "tabrow" then
        K.AfterCombat(LayoutTabRow)
    end
    if Opt("infoBar") then BuildInfoBar() elseif info then info:Hide() end
    -- Reiter sichtbar lassen: das Spiel blendet sie nach ein paar Sekunden
    -- ohne Maus auf diese Werte ab. Nur Zahlen, die sein Chatcode liest.
    if Opt("tabsVisible") then
        _G.CHAT_FRAME_TAB_SELECTED_NOMOUSE_ALPHA = 1
        _G.CHAT_FRAME_TAB_NORMAL_NOMOUSE_ALPHA = 0.75
        _G.CHAT_FRAME_TAB_ALERTING_NOMOUSE_ALPHA = 1
    end
    for _, d in pairs(done) do
        if d.tab then KeepTabVisible(d.tab) end
    end
    UpdateTabs()
    CH.UpdateInfoBar()
end
CH.ApplyAll = ApplyAll

local function Enable()
    ApplyAll()
    -- Fluesterfenster und neue Reiter legt das Spiel spaeter an.
    if _G.hooksecurefunc and _G.FCF_OpenTemporaryWindow then
        _G.hooksecurefunc("FCF_OpenTemporaryWindow", function() ApplyAll() end)
    end
    if _G.hooksecurefunc and _G.FCF_OpenNewWindow then
        _G.hooksecurefunc("FCF_OpenNewWindow", function() ApplyAll() end)
    end
    -- Reiterwechsel: das Spiel faerbt die Reiter selbst neu, danach wir.
    for _, fn in ipairs({ "FCF_Tab_OnClick", "FCFDock_SelectWindow", "FCFTab_UpdateColors" }) do
        if _G.hooksecurefunc and _G[fn] then _G.hooksecurefunc(fn, UpdateTabs) end
    end
end

local function px(v) return string.format("%d px", v) end

K.Register({
    key = KEY, group = "ui", order = 45,
    title = "Chat",
    description = "Die Chatfenster im Stil von WeintCodex: eigene Schrift, ruhiger Grund, flache Reiter, schlichte Eingabezeile.",
    defaults = defaults,
    Enable = Enable,
    OnSetting = function() if K.IsActive(KEY) then ApplyAll() end end,
    pages = {
        { key = "allgemein", label = "Allgemein", build = function(B)
            B:Section("Fenster")
            B:Row({ type = "slider", label = "Schriftgröße", key = "fontSize", min = 9, max = 20, step = 1, format = px },
                  { type = "slider", label = "Deckkraft des Hintergrunds", key = "bgAlpha", min = 0, max = 100, step = 5,
                    format = function(v) return string.format("%d %%", v) end })
            B:Row({ type = "toggle", label = "Flache Reiter", key = "flatTabs", reload = true },
                  { type = "dropdown", label = "Knöpfe des Spiels", key = "buttons", reload = true, items = {
                        { value = "tabrow", text = "Klein in der Reiterzeile" },
                        { value = "column", text = "In einer Spalte links" },
                        { value = "hide",   text = "Ausblenden" },
                        { value = "game",   text = "Wie im Spiel" } } })
            B:Row({ type = "toggle", label = "Reiter immer sichtbar", key = "tabsVisible", reload = true,
                    description = "Das Spiel blendet die Reiter aus, wenn die Maus nicht über dem Chat ist." },
                  { type = "empty" })
            B:Row({ type = "toggle", label = "Bildlaufleiste ausblenden", key = "hideScrollBar", reload = true,
                    description = "Die Leiste und der Pfeil nach unten am rechten Rand. Blättern geht mit dem Mausrad." },
                  { type = "empty" })
            B:Section("Infozeile")
            B:Row({ type = "toggle", label = "Infozeile unter dem Chat", key = "infoBar",
                    description = "Uhrzeit, Gold, freie Taschenplätze, Haltbarkeit, Bildrate und Latenz. Beim Schreiben liegt die Eingabezeile darüber." },
                  { type = "empty" })
            B:Section("Eingabezeile")
            B:Row({ type = "toggle", label = "Eingabezeile im WeintCodex-Stil", key = "editBoxSkin", reload = true },
                  { type = "toggle", label = "Über dem Chat statt darunter", key = "editBoxTop",
                    disabled = function() return not K.Get(KEY, "editBoxSkin") end })
            B:Section("Was es hier nicht gibt")
            B:Note("Kurze Kanalnamen, anklickbare Links und Zeitstempel im Text bräuchten das Umschreiben jeder Nachricht. Auf dem neuen Client können Nachrichten im Kampf für Addons gesperrt sein, und ein Fehler dabei würde die Nachricht verschlucken. Zeitstempel bietet das Spiel selbst an: Optionen → Soziales.")
        end },
    },
})
