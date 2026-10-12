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
--   Szene      Rahmen der Modellflaeche weg, der Grund des Spiels (Volk)
--              bleibt - das Klassenbild gehoert nur dem eigenen Charakter.
--
-- GEMESSEN (6.30.38.0, /wcui fenster, Beta-Test): InspectModelFrame-
-- BackgroundTopLeft/TopRight/BotLeft/BotRight (Bilder 131093-131096),
-- InspectModelFrameBorder* (410247, 410248, 410249), leere Plaetze 130841.
--------------------------------------------------

WeintCodex = WeintCodex or {}

local K = WeintCodex.UIKit
local CP = WeintCodex.UICalmParts
local S = WeintCodex.UIStyle

local IN = CP.New({
    label = "Betrachten", host = "InspectFrame", depth = 4, style = S.CALM,
    files = {
        [410247] = "decor", [410248] = "decor", [410249] = "decor",
        [130841] = "slot",     -- Grund des Platzes: flach wie die Aktionsknoepfe
    },
    after = function(f, m) m.scene = WeintCodex.UIInspect.Scene(f) and true or false end,
    report = function(_, m, H)
        local nh = 0
        for _ in pairs(H.hidden) do nh = nh + 1 end
        return string.format("Bilder weg %d · Innenflächen %d · Klassenbild %s (%s, nur beim eigenen)",
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

-- 6.30.42.0 (Beta-Test: "das epische Klassenbild sollte einem selbst
-- vorbehalten bleiben"): beim Betrachten kein Klassenbild - der Grund des
-- Spiels (je Volk, gemessen: Gnom im Schnee) bleibt, nur die schwarze
-- Flaeche darueber geht.
function IN.Scene(f)
    local token = IN.Class(f)
    IN.lastClass = token
    local ov = _G.InspectModelFrameBackgroundOverlay
    if type(ov) == "table" and ov.SetAlpha and K.Plain(ov:GetAlpha()) ~= 0 then ov:SetAlpha(0) end
    return false
end
