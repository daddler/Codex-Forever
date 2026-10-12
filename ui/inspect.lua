--------------------------------------------------
-- WeintCodex :: Oberflaeche - Betrachten (6.30.40.0)
--------------------------------------------------
-- Wunsch: "Das Gleiche (wie Transmogrifizieren) muss fuer den Inspect von
-- anderen Spielern passieren." 6.30.41.0 (Beta-Test: "ich inspiziere einen
-- Magier, aber das Fenster ist gruen - das macht keinen Sinn"): der Akzent
-- der Klasse ist immer der EIGENE (C.accent); ein fremder Charakter traegt
-- deshalb Gold (S.CALM). Seine Klasse zeigen Name und Klassenbild.
--
--   Huelle     Metallrahmen, Streifen, Seitenreiter: allgemeiner Durchlauf
--              (W.WINDOWS, "InspectFrame").
--   Plaetze    flach mit 1 px Rand wie im Charakterfenster (W.SkinSlots,
--              Inspect...Slot); Rahmen "UI-Character-Info-GearSlot" weg.
--   Szene      Grund und Rahmen der Modellflaeche weg, dahinter das Bild
--              der Klasse des BETRACHTETEN Spielers (data/classthemes.lua).
--
-- GEMESSEN (6.30.38.0, /wcui fenster, Beta-Test): InspectModelFrame-
-- BackgroundTopLeft/TopRight/BotLeft/BotRight (Bilder 131093-131096),
-- InspectModelFrameBorder* (410247, 410248, 410249), leere Plaetze 130841.
--------------------------------------------------

WeintCodex = WeintCodex or {}

local K = WeintCodex.UIKit
local CP = WeintCodex.UICalmParts
local S = WeintCodex.UIStyle
local TM = WeintCodex.UITransmog

local IN = CP.New({
    label = "Betrachten", host = "InspectFrame", depth = 4, style = S.CALM,
    files = {
        [131093] = "decor", [131094] = "decor", [131095] = "decor", [131096] = "decor",
        [410247] = "decor", [410248] = "decor", [410249] = "decor",
        [130841] = "slot",     -- Grund des Platzes: flach wie die Aktionsknoepfe
    },
    after = function(f, m) m.scene = WeintCodex.UIInspect.Scene(f) and true or false end,
    report = function(_, m, H)
        local nh = 0
        for _ in pairs(H.hidden) do nh = nh + 1 end
        return string.format("Bilder weg %d · Innenflächen %d · Klassenbild %s (%s)",
            nh, m.insets + m.bg, m.scene and "ja" or "nein", tostring(WeintCodex.UIInspect.lastClass or "?"))
    end,
})
WeintCodex.UIInspect = IN

-- Welche Klasse wird betrachtet? Die Einheit sagt das Fenster selbst.
function IN.Class(f)
    local unit = K.Plain(f and f.unit) or "target"
    if type(unit) ~= "string" then unit = "target" end
    local ok, _, token = pcall(_G.UnitClass, unit)
    token = ok and K.Plain(token) or nil
    return type(token) == "string" and token or nil
end

function IN.Scene(f)
    local host = _G.InspectModelFrame
    if type(host) ~= "table" then return nil end
    local token = IN.Class(f)
    IN.lastClass = token
    -- Schwarze Flaeche ueber dem Grund (gemessen: Overlay, Bild 0) weg,
    -- sonst liegt sie ueber dem Klassenbild.
    local ov = _G.InspectModelFrameBackgroundOverlay
    if type(ov) == "table" and ov.SetAlpha and K.Plain(ov:GetAlpha()) ~= 0 then ov:SetAlpha(0) end
    return TM.ClassScene(host, token)
end
