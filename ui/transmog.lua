--------------------------------------------------
-- WeintCodex :: Oberflaeche - Transmogrifizieren (6.30.39.0)
--------------------------------------------------
-- Wunsch: "Das Fenster zum Transmogrifizieren im WeintCodex-Design - und
-- groesser das Klassenbild, wie im Charakterfenster."
--
--   Huelle     Metallrahmen, Streifen, rote Knoepfe: der allgemeine
--              Durchlauf (W.WINDOWS, "TransmogFrame"), Gold (S.CALM) wie
--              jedes Fenster, das nicht die Klasse zeigt.
--   Flaechen   Grund der Outfitliste und der Sammlung, Grund der Reiter:
--              Innenflaechen; Verlaeufe, Trennlinien, Rahmen der Reiter weg.
--   Szene      hinter der Figur das Bild der Klasse (data/classthemes.lua,
--              dasselbe wie im Charakterfenster) statt "transmog-locationBG",
--              randlos eingepasst, zu den Raendern hin dunkel.
--
-- Plaetze, Haken, Warnungen, Karten der Outfits und der Gegenstaende
-- BLEIBEN - sie sagen etwas (wie die Rahmen der Talente).
--
-- GEMESSEN (6.30.38.0, /wcui fenster, Beta-Test): TransmogFrameBg (Bild
-- 374155), Atlanten transmog-outfit-darkBG (OutfitCollection und
-- WardrobeCollection .Background), transmog-locationBG
-- (CharacterPreview.Background), transmog-tabs-frame(-BG),
-- transmog-outfit-darkBG-gradient (CharacterPreview.Gradients.*),
-- transmog-outfit-topTexture/-bottomTexture, transmog-outfit-darkBG-cornerLine,
-- transmog-outfit-dividerLine, transmog-tabs-header-line.
--------------------------------------------------

WeintCodex = WeintCodex or {}

local K = WeintCodex.UIKit
local CP = WeintCodex.UICalmParts
local S = WeintCodex.UIStyle

local BLACK = { 0, 0, 0 }

local TM = CP.New({
    label = "Transmogrifizieren", host = "TransmogFrame", depth = 6,
    atlases = {
        { "^transmog%-outfit%-darkBG%-gradient$", "decor" },
        { "^transmog%-outfit%-darkBG%-cornerLine$", "decor" },
        { "^transmog%-outfit%-darkBG$", "bg" },
        { "^transmog%-locationBG$", "decor" },          -- dort liegt das Klassenbild
        { "^transmog%-tabs%-frame%-BG$", "bg" },
        { "^transmog%-tabs%-frame$", "decor" },
        { "^transmog%-outfit%-topTexture$", "decor" },
        { "^transmog%-outfit%-bottomTexture$", "decor" },
        { "^transmog%-outfit%-dividerLine$", "decor" },
        { "^transmog%-tabs%-header%-line$", "decor" },
    },
    after = function(f, m) m.scene = WeintCodex.UITransmog.Scene(f) and true or false end,
    report = function(_, m, H)
        local nh = 0
        for _ in pairs(H.hidden) do nh = nh + 1 end
        return string.format("Bilder weg %d · Innenflächen %d · Klassenbild %s",
            nh, m.insets + m.bg, m.scene and "ja" or "nein (kein Bild für die Klasse oder keine Vorschau)")
    end,
})
WeintCodex.UITransmog = TM

TM.VIGNETTE = 0.75     -- Dunkel zu den Raendern
TM.EDGE_SHARE = 0.22   -- so breit laeuft es aus (Anteil der Flaeche)

local function Num(v)
    v = K.Plain(v)
    return type(v) == "number" and v or nil
end

-- Das Bild der Klasse hinter der Figur. Einmal je Fenster angelegt, bei
-- jeder Groessenaenderung neu eingepasst.
function TM.Scene(f)
    local preview = type(f) == "table" and f.CharacterPreview
    if type(preview) ~= "table" or not preview.CreateTexture then return nil end
    local token
    local ok, _, t = pcall(_G.UnitClass, "player")
    if ok then token = K.Plain(t) end
    local theme = WeintCodex.ClassTheme and WeintCodex.ClassTheme(token)
    local art = theme and theme.art
    if not art then return nil end
    local sc = TM.scene
    if not sc then
        sc = {}
        sc.art = preview:CreateTexture(nil, "BACKGROUND", nil, -6)
        sc.art:SetAllPoints(preview)
        sc.art:SetTexture("Interface\\AddOns\\WeintCodex\\media\\" .. string.gsub(art.file, "/", "\\"))
        local dim = art.dim or 1
        sc.art:SetVertexColor(dim, dim, dim, 1)
        sc.v = {}
        for _, side in ipairs({ "TOP", "BOTTOM", "LEFT", "RIGHT" }) do
            local v = preview:CreateTexture(nil, "BACKGROUND", nil, -5)
            if side == "TOP" then S.Gradient(v, "VERTICAL", BLACK, 0, TM.VIGNETTE)
            elseif side == "BOTTOM" then S.Gradient(v, "VERTICAL", BLACK, TM.VIGNETTE, 0)
            elseif side == "LEFT" then S.Gradient(v, "HORIZONTAL", BLACK, TM.VIGNETTE, 0)
            else S.Gradient(v, "HORIZONTAL", BLACK, 0, TM.VIGNETTE) end
            sc.v[side] = v
        end
        TM.scene = sc
    end
    local okW, w, h = pcall(function() return preview:GetWidth(), preview:GetHeight() end)
    w, h = okW and Num(w) or nil, okW and Num(h) or nil
    if w and h and w > 0 and h > 0 and (sc.w ~= w or sc.h ~= h) then
        sc.w, sc.h = w, h
        if WeintCodex.CoverCoords then
            sc.art:SetTexCoord(WeintCodex.CoverCoords(art.w, art.h, w, h, art.focusX, art.focusY))
        end
        for side, v in pairs(sc.v) do
            v:ClearAllPoints()
            if side == "TOP" or side == "BOTTOM" then
                v:SetPoint(side .. "LEFT", preview, side .. "LEFT", 0, 0)
                v:SetPoint(side .. "RIGHT", preview, side .. "RIGHT", 0, 0)
                v:SetHeight(h * TM.EDGE_SHARE)
            else
                v:SetPoint("TOP" .. side, preview, "TOP" .. side, 0, 0)
                v:SetPoint("BOTTOM" .. side, preview, "BOTTOM" .. side, 0, 0)
                v:SetWidth(w * TM.EDGE_SHARE)
            end
        end
    end
    return sc
end
