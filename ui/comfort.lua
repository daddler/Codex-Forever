--------------------------------------------------
-- WeintCodex :: Komfort - kleine Helfer
--------------------------------------------------
-- Ein Bestand kleiner Funktionen nach dem Vorbild der "Quality of Life"-
-- Seite von EllesmereUI - ohne die, die auf Forever nichts zu tun haetten
-- (Schluesselsteine, Aufwertungsrechner, sprechende Koepfe).
--
-- Jede ist EINZELN abschaltbar und von Haus aus AUS: ein Addon, das nach
-- dem Einspielen ungefragt Gegenstaende verkauft, ist eines, dem man
-- danach nicht mehr traut. Keine haengt am Hauptschalter der Oberflaeche.
--
-- Jede Funktion registriert ihre Ereignisse nur, solange sie an ist. Ein
-- ausgeschalteter Helfer kostet damit nichts ausser seinem Eintrag in der
-- Liste.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIComfort = {}

local QoL = WeintCodex.UIComfort
local K   = WeintCodex.UIKit
local C   = WeintCodex.Colors
local KEY = "comfort"

local defaults = {
    autoRepair     = false,
    repairGuild    = true,
    sellJunk       = false,
    fastLoot       = false,
    deleteFill     = false,
    skipCinematics = false,
    hideErrorsInCombat = false,
    combatAlert    = false,
    fps            = false,
    durability     = false,
    durabilityThreshold = 20,
    mapCoords      = false,
}

local function Say(text)
    print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " " .. text)
end

local function On(key)
    return K.IsActive(KEY) and K.Get(KEY, key) and true or false
end

local function Money(copper)
    if _G.GetCoinTextureString then return _G.GetCoinTextureString(copper) end
    if _G.GetMoneyString then return _G.GetMoneyString(copper) end
    return tostring(copper) .. " Kupfer"
end

--------------------------------------------------
-- Haendler: reparieren und Schrott verkaufen
--------------------------------------------------

local function Repair()
    if not (_G.CanMerchantRepair and _G.CanMerchantRepair()) then return end
    if not _G.GetRepairAllCost then return end
    local cost, can = _G.GetRepairAllCost()
    if not can or type(cost) ~= "number" or cost <= 0 then return end

    local guild = false
    if K.Get(KEY, "repairGuild") and _G.CanGuildBankRepair and _G.CanGuildBankRepair() then
        local limit = _G.GetGuildBankWithdrawMoney and _G.GetGuildBankWithdrawMoney()
        guild = (limit == -1) or (type(limit) == "number" and limit >= cost)
    end
    if not guild and _G.GetMoney and _G.GetMoney() < cost then
        Say("Nicht genug Gold für die Reparatur (" .. Money(cost) .. ").")
        return
    end
    _G.RepairAllItems(guild)
    Say("Repariert für " .. Money(cost) .. (guild and " aus der Gildenbank." or "."))
end

local function SellJunk()
    local cc = _G.C_Container
    if not (cc and cc.GetContainerNumSlots and cc.GetContainerItemInfo and cc.UseContainerItem) then
        if _G.C_MerchantFrame and _G.C_MerchantFrame.SellAllJunkItems then
            _G.C_MerchantFrame.SellAllJunkItems()
        end
        return
    end
    local poor = (_G.Enum and _G.Enum.ItemQuality and _G.Enum.ItemQuality.Poor) or 0
    local total, count = 0, 0
    for bag = 0, (_G.NUM_BAG_SLOTS or 4) do
        for slot = 1, (cc.GetContainerNumSlots(bag) or 0) do
            local info = cc.GetContainerItemInfo(bag, slot)
            if info and info.quality == poor and not info.hasNoValue and not info.isLocked then
                local price = 0
                if info.hyperlink and _G.GetItemInfo then
                    price = select(11, _G.GetItemInfo(info.hyperlink)) or 0
                end
                total = total + price * (info.stackCount or 1)
                count = count + 1
                cc.UseContainerItem(bag, slot)
            end
        end
    end
    if count > 0 then
        Say(count .. " graue Gegenstände verkauft"
            .. (total > 0 and (" für " .. Money(total)) or "") .. ".")
    end
end

--------------------------------------------------
-- Pluendern, Loeschen, Filmsequenzen
--------------------------------------------------

local function FastLoot()
    if not (_G.GetNumLootItems and _G.LootSlot) then return end
    local auto = _G.GetCVarBool and _G.GetCVarBool("autoLootDefault")
    local toggle = _G.IsModifiedClick and _G.IsModifiedClick("AUTOLOOTTOGGLE")
    if auto == toggle then return end   -- Spieler will gerade NICHT automatisch
    for i = _G.GetNumLootItems(), 1, -1 do _G.LootSlot(i) end
end

local function FillDelete()
    local word = _G.DELETE_ITEM_CONFIRM_STRING
    if not word then return end
    for i = 1, (_G.STATICPOPUP_NUMDIALOGS or 4) do
        local p = _G["StaticPopup" .. i]
        if p and p:IsShown() and (p.which == "DELETE_GOOD_ITEM" or p.which == "DELETE_GOOD_QUEST_ITEM") then
            local box = p.editBox or p.EditBox or _G["StaticPopup" .. i .. "EditBox"]
            if box and box.SetText then box:SetText(word) end
        end
    end
end

local function SkipCinematic(event)
    if event == "CINEMATIC_START" then
        if _G.CinematicFrame_CancelCinematic then
            pcall(_G.CinematicFrame_CancelCinematic)
        elseif _G.StopCinematic then
            pcall(_G.StopCinematic)
        end
    elseif event == "PLAY_MOVIE" then
        local mf = _G.MovieFrame
        if mf and mf.StopMovie then pcall(mf.StopMovie, mf) end
    end
end

--------------------------------------------------
-- Fehlermeldungen im Kampf
--------------------------------------------------
-- "Ziel ist ausser Reichweite" zehnmal je Kampf ist Laerm. Aus dem
-- Kampf heraus kommen die Meldungen wieder - sie sind ausserhalb oft die
-- einzige Erklaerung, warum etwas nicht geht.

local errorsMuted = false
local function MuteErrors(mute)
    local ef = _G.UIErrorsFrame
    if not ef then return end
    if mute and not errorsMuted then
        ef:UnregisterEvent("UI_ERROR_MESSAGE")
        errorsMuted = true
    elseif not mute and errorsMuted then
        ef:RegisterEvent("UI_ERROR_MESSAGE")
        errorsMuted = false
    end
end

--------------------------------------------------
-- Anzeigen: Kampfhinweis, Bildrate, Haltbarkeit
--------------------------------------------------

local alert, fpsFrame, durFrame

local function Text(frame, size)
    local fs = K.NewText(frame)
    fs:SetPoint("CENTER", frame, "CENTER", 0, 0)
    K.SetFont(fs, size)
    return fs
end

local function EnsureAlert()
    if alert then return alert end
    alert = CreateFrame("Frame", "WeintCodexCombatAlert", UIParent)
    alert:SetSize(220, 34)
    alert.text = Text(alert, 20)
    alert:Hide()
    alert:SetScript("OnUpdate", function(self, el)
        if self._unlock then return end
        self._t = (self._t or 0) + (el or 0)
        if self._t > 1.2 then
            local a = 1 - (self._t - 1.2) / 0.4
            if a <= 0 then self:Hide() else self:SetAlpha(a) end
        end
    end)
    alert.WCShowForUnlock = function(self, on)
        self._unlock = on and true or nil
        if on then
            self.text:SetText("Kampfhinweis")
            self.text:SetTextColor(unpack(C.textBright))
            self:SetAlpha(1)
            self:Show()
        else
            self:Hide()
        end
    end
    K.RegisterMover(alert, "combatalert", "Kampfhinweis",
        { point = "CENTER", relPoint = "CENTER", x = 0, y = 220 })
    return alert
end

local function ShowAlert(entering)
    local a = EnsureAlert()
    if a._unlock then return end
    K.SetFont(a.text, 20)
    -- Rot und Gruen tragen hier ihre feste Bedeutung aus der Palette:
    -- Gefahr beginnt, Gefahr vorbei.
    if entering then
        a.text:SetText("+ Kampf")
        a.text:SetTextColor(unpack(C.dangerBright))
    else
        a.text:SetText("− Kampf")
        a.text:SetTextColor(unpack(C.successBright))
    end
    a._t = 0
    a:SetAlpha(1)
    a:Show()
end

local function EnsureFps()
    if fpsFrame then return fpsFrame end
    fpsFrame = CreateFrame("Frame", "WeintCodexFps", UIParent)
    fpsFrame:SetSize(130, 18)
    fpsFrame.text = Text(fpsFrame, 11)
    fpsFrame:Hide()
    local acc = 1
    fpsFrame:SetScript("OnUpdate", function(self, el)
        acc = acc + (el or 0)
        if acc < 1 then return end
        acc = 0
        local fps = _G.GetFramerate and _G.GetFramerate() or 0
        local home, world = 0, 0
        if _G.GetNetStats then home, world = select(3, _G.GetNetStats()) end
        local ms = math.max(home or 0, world or 0)
        local tone = (fps < 30 or ms > 250) and "warning" or "textNormal"
        self.text:SetText(WeintCodex.ColorText(tone,
            string.format("%d fps · %d ms", math.floor(fps + 0.5), ms)))
    end)
    fpsFrame.WCShowForUnlock = function(self, on)
        if on then self:Show() elseif not On("fps") then self:Hide() end
    end
    K.RegisterMover(fpsFrame, "fps", "Bildrate",
        { point = "TOPLEFT", relPoint = "TOPLEFT", x = 12, y = -12 })
    return fpsFrame
end

local function EnsureDurability()
    if durFrame then return durFrame end
    durFrame = CreateFrame("Frame", "WeintCodexDurability", UIParent)
    durFrame:SetSize(220, 20)
    durFrame.text = Text(durFrame, 13)
    durFrame:Hide()
    durFrame.WCShowForUnlock = function(self, on)
        self._unlock = on and true or nil
        if on then
            self.text:SetText("Ausrüstung bei 18 %")
            self.text:SetTextColor(unpack(C.warningBright))
            self:Show()
        else
            QoL.UpdateDurability()
        end
    end
    K.RegisterMover(durFrame, "durability", "Haltbarkeit",
        { point = "TOP", relPoint = "TOP", x = 0, y = -90 })
    return durFrame
end

-- Kleinste Haltbarkeit ueber alle Plaetze in Prozent - oder nil, wenn
-- der Client zu keinem Platz etwas sagt. nil ist NICHT 100 und nicht 0.
function QoL.LowestDurability()
    if not _G.GetInventoryItemDurability then return nil end
    local lowest
    for slot = 1, 19 do
        local cur, max = _G.GetInventoryItemDurability(slot)
        if type(cur) == "number" and type(max) == "number" and max > 0 then
            local p = cur / max * 100
            if not lowest or p < lowest then lowest = p end
        end
    end
    return lowest
end

local warnedBelow = false
function QoL.UpdateDurability()
    local f = durFrame
    if not f or f._unlock then return end
    if not On("durability") then f:Hide() return end
    local p = QoL.LowestDurability()
    local limit = K.Get(KEY, "durabilityThreshold") or 20
    if not p or p > limit then
        f:Hide()
        warnedBelow = false
        return
    end
    local tone = (p <= 5) and C.dangerBright or C.warningBright
    f.text:SetText(string.format("Ausrüstung bei %d %%", math.floor(p + 0.5)))
    f.text:SetTextColor(unpack(tone))
    f:Show()
    if not warnedBelow then
        warnedBelow = true
        Say(string.format("Deine Ausrüstung ist bei %d %% Haltbarkeit.", math.floor(p + 0.5)))
    end
end

--------------------------------------------------
-- Koordinaten auf der Weltkarte
--------------------------------------------------

local coords
local function FormatCoord(x, y)
    if type(x) ~= "number" or type(y) ~= "number" then return "–" end
    -- Dezimalkomma, getrennt durch einen Mittelpunkt: "45,2 · 67,8".
    return (string.format("%.1f · %.1f", x * 100, y * 100):gsub("%.(%d)", ",%1"))
end

local function EnsureCoords()
    if coords then return coords end
    local wm = _G.WorldMapFrame
    if not wm then return nil end
    coords = CreateFrame("Frame", nil, wm)
    coords:SetSize(360, 18)
    coords:SetPoint("BOTTOM", wm.ScrollContainer or wm, "BOTTOM", 0, 6)
    coords:SetFrameStrata("HIGH")
    coords.text = K.NewText(coords)
    coords.text:SetPoint("CENTER", coords, "CENTER", 0, 0)
    local acc = 0
    coords:SetScript("OnUpdate", function(self, el)
        acc = acc + (el or 0)
        if acc < 0.1 then return end
        acc = 0
        if not On("mapCoords") then self.text:SetText("") return end
        K.SetFont(self.text, 12)
        local mapID = wm.GetMapID and wm:GetMapID()
        local px, py
        if mapID and _G.C_Map and _G.C_Map.GetPlayerMapPosition then
            local pos = _G.C_Map.GetPlayerMapPosition(mapID, "player")
            if pos then px, py = pos.x, pos.y end
            px, py = K.Plain(px), K.Plain(py)
        end
        local cx, cy
        local sc = wm.ScrollContainer
        if sc and sc.IsMouseOver and sc:IsMouseOver() and sc.GetNormalizedCursorPosition then
            cx, cy = sc:GetNormalizedCursorPosition()
            if type(cx) == "number" and (cx < 0 or cx > 1 or cy < 0 or cy > 1) then cx, cy = nil, nil end
        end
        self.text:SetText(WeintCodex.ColorText("textMuted", "Du ") .. FormatCoord(px, py)
            .. "     " .. WeintCodex.ColorText("textMuted", "Zeiger ") .. FormatCoord(cx, cy))
    end)
    return coords
end

--------------------------------------------------
-- Ereignisse
--------------------------------------------------
-- Je Funktion die Ereignisse, die sie braucht. Registriert wird nur,
-- was eine eingeschaltete Funktion verlangt.

local FEATURE_EVENTS = {
    autoRepair     = { "MERCHANT_SHOW" },
    sellJunk       = { "MERCHANT_SHOW" },
    fastLoot       = { "LOOT_READY" },
    deleteFill     = { "DELETE_ITEM_CONFIRM" },
    skipCinematics = { "CINEMATIC_START", "PLAY_MOVIE" },
    hideErrorsInCombat = { "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED" },
    combatAlert    = { "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED" },
    durability     = { "UPDATE_INVENTORY_DURABILITY", "PLAYER_ENTERING_WORLD" },
}

local events = CreateFrame("Frame")

local function OnEvent(_, event)
    if event == "MERCHANT_SHOW" then
        if On("sellJunk") then SellJunk() end
        if On("autoRepair") then Repair() end
    elseif event == "LOOT_READY" then
        if On("fastLoot") then FastLoot() end
    elseif event == "DELETE_ITEM_CONFIRM" then
        if On("deleteFill") then
            -- Das Eingabefeld steht erst nach diesem Ereignis.
            if _G.C_Timer and _G.C_Timer.After then _G.C_Timer.After(0, FillDelete) else FillDelete() end
        end
    elseif event == "CINEMATIC_START" or event == "PLAY_MOVIE" then
        if On("skipCinematics") then SkipCinematic(event) end
    elseif event == "PLAYER_REGEN_DISABLED" then
        if On("hideErrorsInCombat") then MuteErrors(true) end
        if On("combatAlert") then ShowAlert(true) end
    elseif event == "PLAYER_REGEN_ENABLED" then
        MuteErrors(false)
        if On("combatAlert") then ShowAlert(false) end
    elseif event == "UPDATE_INVENTORY_DURABILITY" or event == "PLAYER_ENTERING_WORLD" then
        QoL.UpdateDurability()
    end
end

local function Apply()
    events:UnregisterAllEvents()
    local active = K.IsActive(KEY)
    if active then
        local want = {}
        for feature, list in pairs(FEATURE_EVENTS) do
            if K.Get(KEY, feature) then
                for _, e in ipairs(list) do want[e] = true end
            end
        end
        for e in pairs(want) do pcall(events.RegisterEvent, events, e) end
    end
    events:SetScript("OnEvent", OnEvent)

    if not (active and K.Get(KEY, "hideErrorsInCombat")) then MuteErrors(false) end

    if active and K.Get(KEY, "combatAlert") then EnsureAlert() end
    if alert then K.SetMoverEnabled("combatalert", active and K.Get(KEY, "combatAlert")) end

    if active and K.Get(KEY, "fps") then
        EnsureFps():Show()
    elseif fpsFrame and not K.IsUnlocked() then
        fpsFrame:Hide()
    end
    if fpsFrame then K.SetMoverEnabled("fps", active and K.Get(KEY, "fps")) end

    if active and K.Get(KEY, "durability") then EnsureDurability() end
    if durFrame then
        K.SetMoverEnabled("durability", active and K.Get(KEY, "durability"))
        QoL.UpdateDurability()
    end

    if active and K.Get(KEY, "mapCoords") then EnsureCoords() end
end

--------------------------------------------------
-- Modul
--------------------------------------------------

local function Row2(a, b) return a, b or { type = "empty" } end

K.Register({
    key = KEY, group = "qol", order = 60,
    title = "Komfort",
    description = "Kleine Helfer für den Alltag: reparieren, Schrott verkaufen, schneller plündern, Hinweise. Jeder einzeln, jeder von Haus aus aus.",
    defaultEnabled = true,
    defaults = defaults,
    -- Verteilt wird ueber den Rueckruf "active" unten: K.Activate setzt
    -- _active erst NACH Enable, und Apply fragt genau danach.
    Enable = function() end,
    OnSetting = function() Apply() end,
    pages = {
        { key = "automatik", label = "Automatik", build = function(B)
            B:Section("Händler")
            B:Row({ type = "toggle", label = "Automatisch reparieren", key = "autoRepair" },
                  { type = "toggle", label = "Zuerst aus der Gildenbank", key = "repairGuild",
                    disabled = function() return not K.Get(KEY, "autoRepair") end })
            B:Row(Row2({ type = "toggle", label = "Graue Gegenstände verkaufen", key = "sellJunk",
                         description = "Nur Qualität „Schlecht“ (grau). Nichts, was einen Wert hat, den du übersehen könntest." }))
            B:Section("Beute und Taschen")
            B:Row({ type = "toggle", label = "Schneller plündern", key = "fastLoot",
                    description = "Nimmt alles sofort, wenn automatisches Plündern an ist." },
                  { type = "toggle", label = "Löschbestätigung ausfüllen", key = "deleteFill",
                    description = "Schreibt das Bestätigungswort vor. Klicken musst du selbst." })
            B:Section("Spiel")
            B:Row({ type = "toggle", label = "Filmsequenzen überspringen", key = "skipCinematics" },
                  { type = "toggle", label = "Fehlermeldungen im Kampf ausblenden", key = "hideErrorsInCombat",
                    description = "„Außer Reichweite“ und Co. — außerhalb des Kampfes kommen sie wieder." })
        end },
        { key = "anzeigen", label = "Anzeigen", build = function(B)
            B:Section("Hinweise")
            B:Row({ type = "toggle", label = "Kampfhinweis", key = "combatAlert",
                    description = "„+ Kampf“ und „− Kampf“ kurz in der Bildschirmmitte." },
                  { type = "toggle", label = "Bildrate und Latenz", key = "fps" })
            B:Row({ type = "toggle", label = "Haltbarkeitswarnung", key = "durability" },
                  { type = "slider", label = "Warnen ab", key = "durabilityThreshold", min = 5, max = 50, step = 5,
                    format = function(v) return string.format("%d %%", v) end,
                    disabled = function() return not K.Get(KEY, "durability") end })
            B:Section("Karte")
            B:Row(Row2({ type = "toggle", label = "Koordinaten auf der Weltkarte", key = "mapCoords",
                         description = "Deine Position und die des Mauszeigers." }))
            B:Note("Kampfhinweis, Bildrate und Haltbarkeitswarnung lassen sich mit „Rahmen entsperren“ verschieben.")
        end },
    },
})

-- Nach dem Einschalten (K.Activate setzt _active erst nach Enable) die
-- Ereignisse einmal nach Lage verteilen.
K.Listen(function(kind, key)
    if kind == "active" and key == KEY then Apply() end
end)
