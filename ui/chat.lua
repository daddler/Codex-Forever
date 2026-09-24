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

local defaults = {
    fontSize    = 13,
    bgAlpha     = 70,       -- Prozent
    buttons     = "column", -- column | hide | game: die Knoepfe des Spiels
    flatTabs    = true,
    editBoxSkin = true,
    editBoxTop  = false,
}

local function Opt(k) return K.Get(KEY, k) end

local done = {}       -- [chatframe] = unsere Teile

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
    d.bg = cf:CreateTexture(nil, "BACKGROUND", nil, -8)
    d.bg:SetPoint("TOPLEFT", cf, "TOPLEFT", -4, 28)
    d.bg:SetPoint("BOTTOMRIGHT", cf, "BOTTOMRIGHT", 4, -4)
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

local function ApplyFrame(cf, d)
    local path = K.FontPath()
    -- Chat ohne Kontur: lange Zeilen lesen sich mit Schatten ruhiger.
    cf:SetFont(path, Opt("fontSize"), "")
    if cf.SetShadowOffset then
        cf:SetShadowOffset(1, -1)
        cf:SetShadowColor(0, 0, 0, 1)
    end
    local bg = WeintCodex.Colors.bgDark
    d.bg:SetColorTexture(bg[1], bg[2], bg[3], (Opt("bgAlpha") or 45) / 100)

    if d.tab and Opt("flatTabs") then
        for _, suffix in ipairs({ "Left", "Middle", "Right", "SelectedLeft", "SelectedMiddle",
            "SelectedRight", "HighlightLeft", "HighlightMiddle", "HighlightRight",
            "ActiveLeft", "ActiveMiddle", "ActiveRight" }) do
            Hide(d[suffix])
        end
        -- Das Aufleuchten bei neuen Fluesternachrichten bleibt.
        HideTextures(d.tab, { [d.tab.glow or false] = true, [d.tab.conversationIcon or false] = true,
                              [d.line or false] = true })
        local fs = d.tab.Text or (d.tab.GetFontString and d.tab:GetFontString())
        if fs then K.SetFont(fs, 11) end
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
        K.AfterCombat(function()
            d.edit:ClearAllPoints()
            if Opt("editBoxTop") then
                d.edit:SetPoint("BOTTOMLEFT", cf, "TOPLEFT", -5, 24)
                d.edit:SetPoint("BOTTOMRIGHT", cf, "TOPRIGHT", 5, 24)
            else
                d.edit:SetPoint("TOPLEFT", cf, "BOTTOMLEFT", -5, -4)
                d.edit:SetPoint("TOPRIGHT", cf, "BOTTOMRIGHT", 5, -4)
            end
        end)
    end

    -- Versteckt, nicht nur durchsichtig: das Spiel blendet die Knopfleiste
    -- beim Ueberfahren selbst wieder ein (in 6.0.0.3 blieben die Knoepfe
    -- deshalb sichtbar). Die Knoepfe, die zaehlen, stehen dann in der
    -- Spalte (siehe unten).
    if d.buttonFrame and Opt("buttons") ~= "game" then K.HideBlizzard(d.buttonFrame, true) end
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
local column

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
    end
    UpdateTabs()
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
                        { value = "column", text = "In einer Spalte links" },
                        { value = "hide",   text = "Ausblenden" },
                        { value = "game",   text = "Wie im Spiel" } } })
            B:Section("Eingabezeile")
            B:Row({ type = "toggle", label = "Eingabezeile im WeintCodex-Stil", key = "editBoxSkin", reload = true },
                  { type = "toggle", label = "Über dem Chat statt darunter", key = "editBoxTop",
                    disabled = function() return not K.Get(KEY, "editBoxSkin") end })
            B:Section("Was es hier nicht gibt")
            B:Note("Kurze Kanalnamen, anklickbare Links und Zeitstempel im Text bräuchten das Umschreiben jeder Nachricht. Auf dem neuen Client können Nachrichten im Kampf für Addons gesperrt sein, und ein Fehler dabei würde die Nachricht verschlucken. Zeitstempel bietet das Spiel selbst an: Optionen → Soziales.")
        end },
    },
})
