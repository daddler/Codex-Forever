--------------------------------------------------
-- WeintCodex :: Seelensplitter begrenzen (Hexenmeister, 6.99.0.0)
--------------------------------------------------
-- Wunsch: "wie viele Seelensplitter sie sammeln wollen und alles darueber
-- hinaus soll direkt geloescht werden. Mit einem Regler" - nach dem
-- Verhalten von Necrosis, eigener Code.
--
-- WIE: nach jeder Aenderung der Taschen (BAG_UPDATE_DELAYED, nie im
-- Kampf) zaehlt WeintCodex die Splitter (Gegenstand 6265, Classic). Sind
-- es mehr als eingestellt, nimmt es EINEN Splitter auf und loescht ihn -
-- die naechste Aenderung der Taschen loest den naechsten aus.
-- SPERRE: verbietet der Client das Loeschen ohne Klick
-- (ADDON_ACTION_BLOCKED), schaltet das selbsttaetige Loeschen ab und ein
-- kleiner Knopf "Splitter loeschen" erscheint - ein Klick, ein Splitter.
-- Nie etwas anderes als Seelensplitter, nie bei belegtem Mauszeiger.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UISoulShards = {}

local SS = WeintCodex.UISoulShards
local K  = WeintCodex.UIKit
local KEY = "comfort"

SS.ITEM = 6265
SS.DEFAULTS = { shardLimit = false, shardMax = 20 }
SS.blocked = false

local function Plain(v) return K.Plain(v) end
local function Num(v) v = Plain(v) return type(v) == "number" and v or nil end

function SS.IsWarlock()
    if not _G.UnitClass then return false end
    local _, c = _G.UnitClass("player")
    return Plain(c) == "WARLOCK"
end

function SS.Active()
    return SS.IsWarlock() and K.IsActive(KEY) and K.Get(KEY, "shardLimit") and true or false
end

function SS.Max()
    local v = tonumber(K.Get(KEY, "shardMax")) or 20
    return math.max(1, math.min(40, math.floor(v)))
end

-- Alle Plaetze mit Splittern: Anzahl, letzter Platz (bag, slot).
function SS.Scan()
    local cc = _G.C_Container
    if not (cc and cc.GetContainerNumSlots and cc.GetContainerItemInfo) then return 0 end
    local n, lb, ls = 0, nil, nil
    for bag = 0, (tonumber(_G.NUM_BAG_SLOTS) or 4) do
        local ok, slots = pcall(cc.GetContainerNumSlots, bag)
        for slot = 1, (ok and Num(slots) or 0) do
            local ok2, info = pcall(cc.GetContainerItemInfo, bag, slot)
            if ok2 and type(info) == "table" and Num(info.itemID) == SS.ITEM then
                n = n + (Num(info.stackCount) or 1)
                if not Plain(info.isLocked) then lb, ls = bag, slot end
            end
        end
    end
    return n, lb, ls
end

-- Einen Splitter loeschen. true, wenn ein Versuch gemacht wurde.
function SS.DeleteOne()
    if K.InCombat() then return false end
    if _G.GetCursorInfo and Plain(_G.GetCursorInfo()) then return false end
    local n, bag, slot = SS.Scan()
    if n <= SS.Max() or not bag then return false end
    local cc = _G.C_Container
    local pick = cc and cc.PickupContainerItem or _G.PickupContainerItem
    if not (pick and _G.DeleteCursorItem) then return false end
    pick(bag, slot)
    -- Nur loeschen, was wirklich ein Splitter ist.
    local kind, id = nil, nil
    if _G.GetCursorInfo then kind, id = _G.GetCursorInfo() end
    if Plain(kind) ~= "item" or Num(id) ~= SS.ITEM then
        if _G.ClearCursor then _G.ClearCursor() end
        return false
    end
    SS.trying = true
    _G.DeleteCursorItem()
    SS.trying = false
    return true
end

--------------------------------------------------
-- Knopf, wenn das Spiel selbsttaetiges Loeschen sperrt
--------------------------------------------------
local btn
local function Button()
    if btn then return btn end
    btn = WeintCodex.CreateButton(UIParent, { text = "", kind = "primary", height = 26, size = 12,
        tooltip = "Das Spiel erlaubt das Löschen nur auf einen Klick: jeder Klick löscht einen Seelensplitter über deiner Grenze.",
        onClick = function() SS.DeleteOne() end })
    btn:SetWidth(220)
    btn:SetPoint("TOP", UIParent, "TOP", 0, -220)
    btn:SetFrameStrata("DIALOG")
    btn:Hide()
    return btn
end

function SS.Check()
    if not SS.Active() then if btn then btn:Hide() end return end
    local n = SS.Scan()
    local over = n - SS.Max()
    if over <= 0 then if btn then btn:Hide() end return end
    if SS.blocked then
        if K.InCombat() then return end
        Button():SetText(over .. " Seelensplitter zu viel – löschen")
        btn:Show()
        return
    end
    SS.DeleteOne()
end

local ev = CreateFrame("Frame")
SS.events = ev
for _, e in ipairs({ "PLAYER_LOGIN", "BAG_UPDATE_DELAYED", "PLAYER_REGEN_ENABLED", "ADDON_ACTION_BLOCKED" }) do
    pcall(ev.RegisterEvent, ev, e)
end
ev:SetScript("OnEvent", function(_, event, addon, fn)
    if event == "ADDON_ACTION_BLOCKED" then
        if SS.trying or Plain(fn) == "DeleteCursorItem()" or Plain(fn) == "DeleteCursorItem" then
            if Plain(addon) == "WeintCodex" or SS.trying then
                SS.blocked = true
                if _G.ClearCursor then _G.ClearCursor() end
            end
        end
        return
    end
    SS.Check()
end)

--------------------------------------------------
-- Einstellungen: Komfort -> Automatik, nur fuer Hexenmeister
--------------------------------------------------
local mod = K.Module(KEY)
if mod then
    for k, v in pairs(SS.DEFAULTS) do
        if mod.defaults[k] == nil then mod.defaults[k] = v end
    end
    for _, page in ipairs(mod.pages) do
        if page.key == "automatik" then
            local orig = page.build
            page.build = function(B, ...)
                if orig then orig(B, ...) end
                if not SS.IsWarlock() then return end
                B:Section("Seelensplitter", "Hexenmeister: so viele Seelensplitter behältst du – jeder weitere wird gleich gelöscht. Nur Seelensplitter, nie im Kampf. Erlaubt das Spiel das Löschen nur auf Klick, erscheint stattdessen ein Knopf.")
                B:Row({ type = "toggle", label = "Seelensplitter begrenzen", key = "shardLimit" },
                      { type = "slider", label = "Höchstens behalten", key = "shardMax", min = 1, max = 40, step = 1,
                        disabled = function() return not K.Get(KEY, "shardLimit") end })
            end
        end
    end
end

K.Listen(function(kind, key)
    if (kind == "active" or kind == "setting") and key == KEY then SS.Check() end
end)
