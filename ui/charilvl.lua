--------------------------------------------------
-- WeintCodex :: Gegenstandsstufe im Charakterfenster (6.52.0.0)
--------------------------------------------------
-- Wunsch: "Itemlevel im Charakterfenster sollte auch an den Items
-- einsehbar sein" - wie in den Taschen: Zahl oben links in der Farbe der
-- Qualitaet. Die Stufe kommt vom Client (GetCurrentItemLevel am
-- Ausruestungsplatz), nie geschaetzt; meldet er keine, steht keine Zahl.
--
-- Die Knoepfe gehoeren dem Spiel. Kein Feld wird in sie geschrieben (das
-- macht Klicks des Spiels "tainted", siehe Taschen 6.30.51.0): die Schrift
-- liegt auf einem eigenen Kind-Rahmen, gemerkt in einer eigenen Tabelle.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UICharItemLevel = {}

local CI = WeintCodex.UICharItemLevel
local K  = WeintCodex.UIKit

CI.SLOTS = { "Head", "Neck", "Shoulder", "Back", "Chest", "Shirt", "Tabard", "Wrist",
    "Hands", "Waist", "Legs", "Feet", "Finger0", "Finger1", "Trinket0", "Trinket1",
    "MainHand", "SecondaryHand", "Ranged" }
-- Hemd und Wappenrock haben keine Stufe, die etwas sagt.
CI.SKIP = { Shirt = true, Tabard = true }

local labels = {}   -- [Knopf] = Schrift
CI.labels = labels

function CI.Level(slotId)
    if not (_G.C_Item and _G.C_Item.GetCurrentItemLevel and _G.ItemLocation
            and _G.ItemLocation.CreateFromEquipmentSlot) then return nil end
    local okL, loc = pcall(_G.ItemLocation.CreateFromEquipmentSlot, _G.ItemLocation, slotId)
    if not okL or not loc then return nil end
    if loc.IsValid and not loc:IsValid() then return nil end
    if _G.C_Item.DoesItemExist and not _G.C_Item.DoesItemExist(loc) then return nil end
    local ok, v = pcall(_G.C_Item.GetCurrentItemLevel, loc)
    v = ok and K.Plain(v) or nil
    -- Keine Stufe gemeldet ist keine Stufe 0.
    if type(v) ~= "number" or v <= 1 then return nil end
    return v
end

local function Label(btn)
    local t = labels[btn]
    if t then return t end
    local top = CreateFrame("Frame", nil, btn)
    top:SetAllPoints(btn)
    top:SetFrameLevel((btn:GetFrameLevel() or 1) + 3)
    top:EnableMouse(false)
    t = K.NewText(top, 11, "OVERLAY")
    t:SetPoint("TOPLEFT", btn, "TOPLEFT", 2, -2)
    labels[btn] = t
    return t
end

function CI.Update()
    if not K.UIEnabled() then return end
    for _, name in ipairs(CI.SLOTS) do
        local btn = _G["Character" .. name .. "Slot"]
        if type(btn) == "table" and btn.GetID and not CI.SKIP[name] then
            local id = K.Plain(btn:GetID())
            local lvl = type(id) == "number" and CI.Level(id) or nil
            local t = Label(btn)
            t:SetText(lvl and tostring(lvl) or "")
            if lvl and _G.GetInventoryItemQuality and _G.C_Item and _G.C_Item.GetItemQualityColor then
                local q = K.Plain(_G.GetInventoryItemQuality("player", id))
                local r, g, b
                if type(q) == "number" then r, g, b = _G.C_Item.GetItemQualityColor(q) end
                if type(r) == "number" then t:SetTextColor(r, g, b, 1) else t:SetTextColor(1, 1, 1, 1) end
            end
        end
    end
end

local ev = CreateFrame("Frame")
for _, e in ipairs({ "PLAYER_LOGIN", "PLAYER_EQUIPMENT_CHANGED" }) do pcall(ev.RegisterEvent, ev, e) end
local hooked = false
ev:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" and not hooked then
        local cf = _G.CharacterFrame
        if type(cf) == "table" and cf.HookScript then
            hooked = true
            cf:HookScript("OnShow", CI.Update)
        end
    end
    CI.Update()
end)
CI.events = ev
