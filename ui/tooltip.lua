--------------------------------------------------
-- WeintCodex :: Oberflaeche - Tooltip
--------------------------------------------------
-- Die Tooltips des Spiels im Stil von WeintCodex (seit 6.3.0.9; im
-- Beta-Test "noch nicht auf dem neuen Design"): eine Kachel statt des
-- Blizzard-Rahmens, der Name eines Spielers in Klassenfarbe, der Rand in
-- Klassen- bzw. Qualitaetsfarbe, der Lebensbalken flach und angedockt.
--
-- Nur Aussehen. Kein Text wird gelesen oder umgeschrieben - Tooltips
-- tragen im 12.x-Client geheime Werte, und ein Fehler hier liesse den
-- Tooltip leer. Farben werden nur gesetzt, wenn Einheit bzw. Gegenstand
-- offen bekannt sind; sonst bleibt der Rand schwarz.
--
-- Die Einstellungen liegen beim Modul "general" (Seite "Tooltip"): ein
-- eigenes Modul haette die Seitenleiste des Fensters ueberfuellt.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UITooltip = {}

local T = WeintCodex.UITooltip
local K = WeintCodex.UIKit

T.DEFAULTS = {
    tooltipStyle     = true,
    tooltipClassName = true,   -- Spielername in Klassenfarbe
    tooltipBorder    = true,   -- Rand in Klassen- / Qualitaetsfarbe
    tooltipHealth    = true,   -- Lebensbalken flach und angedockt
}

local function Opt(k) return K.Get("general", k) end

local TIPS = { "GameTooltip", "ItemRefTooltip", "ShoppingTooltip1", "ShoppingTooltip2",
    "EmbeddedItemTooltip", "ItemRefShoppingTooltip1", "ItemRefShoppingTooltip2" }

local styled = {}   -- [Tooltip] = eigene Flaeche
T.styled = styled

local function Level(f)
    local v = f.GetFrameLevel and K.Plain(f:GetFrameLevel())
    return type(v) == "number" and v or 1
end

local function ResetBorder(tt)
    local bd = styled[tt]
    if bd then bd.kachel.border:SetColor(0, 0, 0, 1) end
end

local function HideNineSlice(tt)
    local ns = tt.NineSlice
    if type(ns) == "table" and ns.SetAlpha then ns:SetAlpha(0) end
end

local function Style(tt)
    if type(tt) ~= "table" or (tt.IsForbidden and tt:IsForbidden()) then return end
    if styled[tt] then return styled[tt] end
    local bd = CreateFrame("Frame", nil, tt)
    bd:SetAllPoints(tt)
    -- Unter dem Text des Tooltips (ein Kind darf tiefer stehen).
    bd:SetFrameLevel(math.max(0, Level(tt) - 1))
    bd.kachel = K.Kachel(bd, { alpha = 0.94, shadow = 8 })
    styled[tt] = bd
    HideNineSlice(tt)
    if tt.HookScript then
        tt:HookScript("OnShow", function(self)
            HideNineSlice(self)
            bd:SetFrameLevel(math.max(0, Level(self) - 1))
        end)
        tt:HookScript("OnTooltipCleared", ResetBorder)
    end
    return bd
end
T.Style = Style

-- Der Lebensbalken unter dem Tooltip: flach, 5 px, mit Rand, buendig.
local function StyleHealthBar()
    local sb = _G.GameTooltipStatusBar
    if type(sb) ~= "table" or T._healthDone or not Opt("tooltipHealth") then return end
    T._healthDone = true
    if sb.SetStatusBarTexture then sb:SetStatusBarTexture(K.BarTexture()) end
    sb:SetHeight(5)
    sb:ClearAllPoints()
    sb:SetPoint("TOPLEFT", _G.GameTooltip, "BOTTOMLEFT", 1, -3)
    sb:SetPoint("TOPRIGHT", _G.GameTooltip, "BOTTOMRIGHT", -1, -3)
    local bg = sb:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(sb)
    local f = WeintCodex.GameColors.kachelFill
    bg:SetColorTexture(f[1], f[2], f[3], 0.94)
    K.Border(sb, 1, 0, 0, 0, 1, "BORDER")
    for _, key in ipairs({ "BorderLeft", "BorderRight", "BorderMid", "Border" }) do
        local r = sb[key]
        if type(r) == "table" and r.SetAlpha then r:SetAlpha(0) end
    end
end

-- Spieler: Name in Klassenfarbe, Rand in Klassenfarbe.
local function OnUnit(tt)
    if tt ~= _G.GameTooltip or not styled[tt] then return end
    local ok, _, unit = pcall(tt.GetUnit, tt)
    unit = ok and K.Plain(unit) or nil
    if type(unit) ~= "string" then return end
    if not K.Bool(_G.UnitIsPlayer and _G.UnitIsPlayer(unit), false) then return end
    local _, class = _G.UnitClass(unit)
    class = K.Plain(class)
    local cc = class and _G.RAID_CLASS_COLORS and _G.RAID_CLASS_COLORS[class]
    if not cc then return end
    if Opt("tooltipClassName") then
        local line = _G.GameTooltipTextLeft1
        if type(line) == "table" and line.SetTextColor then line:SetTextColor(cc.r, cc.g, cc.b) end
    end
    if Opt("tooltipBorder") then styled[tt].kachel.border:SetColor(cc.r, cc.g, cc.b, 0.9) end
end

-- Gegenstaende: Rand in Qualitaetsfarbe (ab "selten" - graue und weisse
-- Gegenstaende behalten den schwarzen Rand, sonst waere jeder Rand bunt).
local function OnItem(tt)
    local bd = styled[tt]
    if not bd or not Opt("tooltipBorder") or not tt.GetItem then return end
    local ok, _, link = pcall(tt.GetItem, tt)
    link = ok and K.Plain(link) or nil
    if type(link) ~= "string" then return end
    local q
    if _G.C_Item and _G.C_Item.GetItemQualityByID then
        local okq, v = pcall(_G.C_Item.GetItemQualityByID, link)
        if okq then q = K.Plain(v) end
    end
    if type(q) ~= "number" and _G.GetItemInfo then
        local okq, _, _, v = pcall(_G.GetItemInfo, link)
        if okq then q = K.Plain(v) end
    end
    local qc = type(q) == "number" and q >= 2 and _G.ITEM_QUALITY_COLORS and _G.ITEM_QUALITY_COLORS[q]
    if qc then bd.kachel.border:SetColor(qc.r, qc.g, qc.b, 0.9) end
end
T.OnUnit, T.OnItem = OnUnit, OnItem

function T.Enable()
    if T._enabled or not Opt("tooltipStyle") then return end
    T._enabled = true
    for _, n in ipairs(TIPS) do Style(_G[n]) end
    StyleHealthBar()
    local tdp, e = _G.TooltipDataProcessor, _G.Enum and _G.Enum.TooltipDataType
    if tdp and tdp.AddTooltipPostCall and e then
        if e.Unit then pcall(tdp.AddTooltipPostCall, e.Unit, OnUnit) end
        if e.Item then pcall(tdp.AddTooltipPostCall, e.Item, OnItem) end
    elseif _G.GameTooltip and _G.GameTooltip.HookScript then
        _G.GameTooltip:HookScript("OnTooltipSetUnit", OnUnit)
        _G.GameTooltip:HookScript("OnTooltipSetItem", OnItem)
    end
end

local boot = CreateFrame("Frame")
boot:RegisterEvent("PLAYER_LOGIN")
boot:SetScript("OnEvent", function()
    if K.UIEnabled() then
        local ok, err = pcall(T.Enable)
        if not ok then K.Report("tooltip", err) end
    end
end)
