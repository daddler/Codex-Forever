--------------------------------------------------
-- WeintCodex :: Oberflaeche - Totems am Spielerrahmen
--------------------------------------------------
-- Seit 6.27.0.6 (Beta-Test: "Im Original kann ich gestellte Totems mit
-- Rechtsklick an meiner Spielerleiste entfernen - im Addon nicht"). Der
-- Spielerrahmen des Spiels ist mit der Oberflaeche ausgeblendet, und mit
-- ihm seine Totemleiste. Hier vier eigene Knoepfe unter dem eigenen
-- Spielerrahmen: Symbol und Restzeit aus GetTotemInfo, Rechtsklick
-- entfernt das Totem.
--
-- Entfernen ist geschuetzt (DestroyTotem nur auf Klick des Spielers):
-- jeder Knopf ist ein SecureActionButton mit type2 = "destroytotem" und
-- "totem-slot" - das Spiel selbst entfernt, WeintCodex ruft nichts.
-- Geschuetzte Knoepfe lassen sich im Kampf nicht zeigen/verstecken: sie
-- bleiben stehen, ein leerer Platz ist nur unsichtbar (Alpha 0).
--------------------------------------------------

local K = WeintCodex.UIKit
local KEY = "unitframes"

WeintCodex.UITotems = {}
local TT = WeintCodex.UITotems

TT.SLOTS = 4
TT.SIZE = 26
TT.GAP = 3
local buttons = {}
TT.buttons = buttons

local function PlayerClass()
    if not _G.UnitClass then return nil end
    local _, class = _G.UnitClass("player")
    return K.Plain(class)
end

-- Ein Platz: hat, Name, Ende (GetTime), Symbol - oder nil.
function TT.Info(slot)
    if not _G.GetTotemInfo then return nil end
    local ok, have, name, start, duration, icon = pcall(_G.GetTotemInfo, slot)
    if not ok then return nil end
    have, start, duration = K.Plain(have), K.Plain(start), K.Plain(duration)
    if not have then return false end
    local finish = (type(start) == "number" and type(duration) == "number" and duration > 0) and (start + duration) or nil
    return true, K.Plain(name), finish, K.Plain(icon)
end

local function Left(b)
    if not b._finish or not _G.GetTime then return "" end
    local now = K.Plain(_G.GetTime())
    if type(now) ~= "number" then return "" end
    local s = b._finish - now
    if s <= 0 then return "" end
    if s >= 60 then return math.floor(s / 60 + 0.5) .. "m" end
    return tostring(math.floor(s))
end

function TT.Update()
    for i, b in ipairs(buttons) do
        local have, name, finish, icon = TT.Info(b.slot)
        if have then
            b.icon:SetTexture(icon)
            b._finish, b._name = finish, name
            b.time:SetText(Left(b))
            b:SetAlpha(1)
        else
            b._finish, b._name = nil, nil
            b:SetAlpha(0)
        end
    end
end

local function Build(anchor)
    for i = 1, TT.SLOTS do
        local ok, b = pcall(CreateFrame, "Button", "WeintCodexTotem" .. i, UIParent, "SecureActionButtonTemplate")
        if not ok or not b then return false end
        b.slot = i
        b:SetSize(TT.SIZE, TT.SIZE)
        b:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", (i - 1) * (TT.SIZE + TT.GAP), -4)
        -- Wie Automark (im Spiel gemessen): auf Loslassen, nie beim Druecken.
        -- Ohne useOnKeyDown = false loest der Client geschuetzte Knoepfe beim
        -- Druecken aus - registriert war nur das Loslassen, also nie (6.27.2.1).
        if b.RegisterForClicks then b:RegisterForClicks("AnyUp") end
        b:SetAttribute("useOnKeyDown", false)
        b:SetAttribute("type2", "destroytotem")
        b:SetAttribute("totem-slot", i)
        b.border = K.Border(b, 1, 0, 0, 0, 1, "BORDER")
        b.icon = b:CreateTexture(nil, "ARTWORK")
        b.icon:SetPoint("TOPLEFT", b, "TOPLEFT", 1, -1)
        b.icon:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -1, 1)
        b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        b.time = K.NewText(b, 11, "OVERLAY")
        b.time:SetPoint("CENTER", b, "CENTER", 0, 0)
        b:SetScript("OnEnter", function(self)
            if not (self._name and GameTooltip) then return end
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
            if GameTooltip.SetTotem then pcall(GameTooltip.SetTotem, GameTooltip, self.slot)
            else GameTooltip:AddLine(self._name) end
            GameTooltip:AddLine("Rechtsklick: entfernen", 0.7, 0.7, 0.7)
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
        b:SetAlpha(0)
        buttons[i] = b
    end
    return true
end

local acc = 0
local ticker = CreateFrame("Frame")
ticker:SetScript("OnUpdate", K.Measured("Totems", function(_, el)
    acc = acc + (el or 0)
    if acc < 0.5 then return end
    acc = 0
    for _, b in ipairs(buttons) do
        if b._finish then b.time:SetText(Left(b)) end
    end
end))
ticker:Hide()

function TT.Enable()
    if #buttons > 0 then return true end
    if PlayerClass() ~= "SHAMAN" or not _G.GetTotemInfo then return false end
    if not (K.IsActive(KEY) and K.Get(KEY, "player_totems")) then return false end
    local anchor = _G.WeintCodexUF_player
    if type(anchor) ~= "table" then return false end
    if not Build(anchor) then return false end
    local ev = CreateFrame("Frame")
    pcall(ev.RegisterEvent, ev, "PLAYER_TOTEM_UPDATE")
    pcall(ev.RegisterEvent, ev, "PLAYER_ENTERING_WORLD")
    ev:SetScript("OnEvent", function() TT.Update() end)
    TT.events = ev
    ticker:Show()
    TT.Update()
    return true
end

local boot = CreateFrame("Frame")
boot:RegisterEvent("PLAYER_LOGIN")
boot:RegisterEvent("PLAYER_ENTERING_WORLD")
boot:SetScript("OnEvent", function()
    if K.InCombat() then K.AfterCombat(TT.Enable) else TT.Enable() end
end)
TT.boot = boot

-- Fuer /wcui prüfen: gebaut? und was der Client zu den Plaetzen sagt.
function TT.StatusLines()
    local out = { "Totemleiste: " .. (#buttons > 0 and "gebaut" or "nicht gebaut")
        .. " · Klasse " .. tostring(PlayerClass()) .. " · Schalter " .. tostring(K.Get(KEY, "player_totems"))
        .. " · Spielerrahmen " .. (type(_G.WeintCodexUF_player) == "table" and "da" or "fehlt") }
    for i = 1, TT.SLOTS do
        local have, name = TT.Info(i)
        out[#out + 1] = "  Platz " .. i .. ": " .. (have and tostring(name) or (have == false and "leer" or "weiß nicht"))
    end
    return out
end
