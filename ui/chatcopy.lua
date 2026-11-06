--------------------------------------------------
-- WeintCodex :: Komfort - Chat kopieren (6.68.0.0)
--------------------------------------------------
-- Beta-Test (Frage einer Spielerin): "wie kann ich Text aus Allgemein
-- raus kopieren, oder Handel?" - das Spiel kann es nicht.
--
-- An jedem Chatfenster oben rechts (ueber dem Fenster, auf Hoehe der
-- Reiter) ein kleiner Knopf "Kopieren", gedaempft, deutlich unter der Maus. Ein Klick legt den Verlauf DIESES
-- Fensters (Reiter Allgemein, Handel, ... - was gerade offen ist) in das
-- Fenster zum Kopieren (K.ShowReport): markiert, Strg+C. Nur gelesen,
-- nichts umgeschrieben; Farben, Symbole und Links als blosser Text.
-- Zeilen, die der Client geheim haelt (12.x, in Instanzen), fehlen -
-- gezaehlt in der Kopfzeile, nie still verschluckt.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIChatCopy = {}

local CC = WeintCodex.UIChatCopy
local K = WeintCodex.UIKit
local C = WeintCodex.Colors
local KEY = "comfort"

CC.MAX = 500            -- hoechstens so viele Zeilen (die neuesten)
CC.IDLE, CC.HOVER = 0.6, 1

function CC.Active() return K.IsActive(KEY) and K.Get(KEY, "chatCopy") ~= false end

-- Links |Hitem:...|h[Name]|h -> [Name]
function CC.Clean(s)
    s = s:gsub("|H.-|h(.-)|h", "%1")
    return K.PlainText(s)
end

function CC.Lines(cf)
    local out, hidden = {}, 0
    local n = cf and cf.GetNumMessages and K.Plain(cf:GetNumMessages())
    if type(n) ~= "number" then return out, 0 end
    for i = math.max(1, n - CC.MAX + 1), n do
        local ok, text = pcall(cf.GetMessageInfo, cf, i)
        text = ok and K.Plain(text) or nil
        if type(text) == "string" then out[#out + 1] = CC.Clean(text) else hidden = hidden + 1 end
    end
    return out, hidden
end

function CC.Copy(cf)
    local lines, hidden = CC.Lines(cf)
    local tab = cf and cf.GetName and _G[(cf:GetName() or "") .. "Tab"]
    local name = tab and tab.GetText and K.Plain(tab:GetText())
    local title = "Chat kopieren · " .. (type(name) == "string" and name or "Chat")
        .. " · " .. #lines .. " Zeilen" .. (hidden > 0 and (" (" .. hidden .. " vom Spiel verborgen)") or "")
    if #lines == 0 then lines[1] = "Keine Zeilen in diesem Fenster." end
    return K.ShowReport(title, lines)
end

local buttons = {}
CC.buttons = buttons

local function Make(cf)
    if buttons[cf] or not cf.CreateTexture then return buttons[cf] end
    local b = CreateFrame("Button", nil, cf)
    b:SetSize(56, 16)
    -- 6.69.1.0 (Beta-Test: "man sieht es nicht, weil der Text von den
    -- Leuten drueber schwappt"): nicht mehr IM Fenster, sondern darueber,
    -- rechts auf Hoehe der Reiter - dort schreibt kein Chat hin.
    -- 1.0.4.3 (Bild eines Spielers: "Kopieren" lag ueber dem letzten Reiter
    -- "Raid/Group"): bei vielen Reitern ist rechts in der Reiterzeile kein
    -- Platz. Jetzt IM Fenster oben rechts, aber nur sichtbar, solange die
    -- Maus ueber dem Chat ist - dann liest man nicht, sondern will kopieren.
    b:SetPoint("TOPRIGHT", cf, "TOPRIGHT", -2, -2)
    b:SetFrameLevel((cf:GetFrameLevel() or 1) + 5)
    local bg = b:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(b)
    local s = C.surface2 or C.surface1
    bg:SetColorTexture(s[1], s[2], s[3], 0.85)
    b.text = K.NewText(b, 10)
    b.text:SetPoint("CENTER")
    b.text:SetText("Kopieren")
    local t = C.textNormal
    b.text:SetTextColor(t[1], t[2], t[3])
    b:SetAlpha(0)
    local function Over()
        local over = _G.MouseIsOver
        if type(over) ~= "function" then return false end
        local ok1, a = pcall(over, cf)
        local ok2, c = pcall(over, b)
        return (ok1 and a) or (ok2 and c) or false
    end
    b.Fade = function()
        if b:IsMouseOver() then return end
        b:SetAlpha(Over() and CC.IDLE or 0)
    end
    if cf.HookScript then
        pcall(cf.HookScript, cf, "OnEnter", function() b:SetAlpha(CC.IDLE) end)
        pcall(cf.HookScript, cf, "OnLeave", function()
            if _G.C_Timer and _G.C_Timer.After then _G.C_Timer.After(0.1, b.Fade) else b:SetAlpha(0) end
        end)
    end
    b:SetScript("OnEnter", function(self)
        self:SetAlpha(CC.HOVER)
        local tip = _G.GameTooltip
        if tip then
            tip:SetOwner(self, "ANCHOR_TOPLEFT")
            tip:SetText("Chat kopieren")
            tip:AddLine("Verlauf dieses Fensters zum Kopieren öffnen – markiert, dann Strg+C.", 1, 1, 1, true)
            tip:Show()
        end
    end)
    b:SetScript("OnLeave", function(self)
        self:SetAlpha(Over() and CC.IDLE or 0)
        if _G.GameTooltip then _G.GameTooltip:Hide() end
    end)
    b:SetScript("OnClick", function() CC.Copy(cf) end)
    buttons[cf] = b
    return b
end
CC.Make = Make

function CC.Apply()
    local on = CC.Active()
    for i = 1, (_G.NUM_CHAT_WINDOWS or 10) do
        local cf = _G["ChatFrame" .. i]
        if type(cf) == "table" then
            local b = on and Make(cf) or buttons[cf]
            if b then b:SetShown(on) end
        end
    end
end

local ev = CreateFrame("Frame")
CC.events = ev
for _, e in ipairs({ "PLAYER_LOGIN", "UPDATE_CHAT_WINDOWS", "UPDATE_FLOATING_CHAT_WINDOWS" }) do
    pcall(ev.RegisterEvent, ev, e)
end
ev:SetScript("OnEvent", function() pcall(CC.Apply) end)

local mod = K.Module(KEY)
if mod then
    if mod.defaults.chatCopy == nil then mod.defaults.chatCopy = true end
    local page = mod.pages and mod.pages[1]
    if page then
        local build = page.build
        page.build = function(B)
            build(B)
            B:Section("Chat")
            B:Row({ type = "toggle", label = "Chat kopieren", key = "chatCopy",
                    set = function(v) K.Set(KEY, "chatCopy", v) pcall(CC.Apply) end,
                    description = "Knopf „Kopieren“ oben rechts im Chatfenster, sobald die Maus darüber ist: der Verlauf (Allgemein, Handel …) zum Markieren und Kopieren." },
                  { type = "empty" })
        end
    end
end
