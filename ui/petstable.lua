--------------------------------------------------
-- WeintCodex :: Oberflaeche - Stall (1.0.8.0)
--------------------------------------------------
-- Wunsch mit /wcui fenster (Jaeger): "Das Stallfenster muss auch im Codex
-- Design." Wie Betrachten (ui/inspect.lua): Huelle aus dem allgemeinen
-- Durchlauf (W.WINDOWS, "PetStableFrame"), Gold (S.CALM - der Begleiter ist
-- kein eigener Charakter), die gemessenen Bilder aus Bausteinen.
--
-- GEMESSEN (1.0.7.64, /wcui fenster, Forever): Rahmen alt 423809-423813
-- (Ecken, Kanten), Grund 374155, Innenflaeche der Szene 374154, Kopf und
-- Fuss ui-stables-subheader-bg / ui-stables-footer-bg, Trenner
-- ui-stables-horz-divider, Plaetze ui-stables-pet-frame-current/-stabled
-- und 130718/130724. Bleibt: Modell, Leiste der Erfahrung, Symbole der
-- Tiere, Laune, Knoepfe der Szene, Geld.
--------------------------------------------------

WeintCodex = WeintCodex or {}

local CP = WeintCodex.UICalmParts
local S = WeintCodex.UIStyle

WeintCodex.UIPetStable = CP.New({
    label = "Stall", host = "PetStableFrame", depth = 4, style = S.CALM,
    files = {
        [423809] = "decor", [423810] = "decor", [423811] = "decor", [423812] = "decor", [423813] = "decor",
        [374155] = "bg", [374154] = "bg",
        [130718] = "slot", [130724] = "slot",
    },
    atlases = {
        { "^ui%-stables%-subheader%-bg", "decor" },
        { "^ui%-stables%-footer%-bg", "decor" },
        { "^ui%-stables%-horz%-divider", "decor" },
        { "^ui%-stables%-pet%-model%-bg", "bg" },
        { "^ui%-stables%-pet%-frame%-current$", "slot" },
        { "^ui%-stables%-pet%-frame%-stabled", "slot" },
        { "^common%-insideframe", "decor" },
    },
})
