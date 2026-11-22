--------------------------------------------------
-- WeintCodex :: Oberflaeche - Wappenrock (1.0.8.12)
--------------------------------------------------
-- Wunsch mit /wcui fenster (Gildenwappenrock entwerfen): "Das Fenster muss
-- auch noch ins Codex Design." Wie der Stall (ui/petstable.lua): Huelle aus
-- dem allgemeinen Durchlauf (W.WINDOWS, "TabardFrame"), Gold (S.CALM - das
-- Wappen gehoert der Gilde, nicht der Klasse), die gemessenen Bilder aus
-- Bausteinen.
--
-- GEMESSEN (1.0.8.11, /wcui fenster, Forever): Metallrahmen (NineSlice,
-- nimmt der allgemeine Durchlauf), Grund 374155, Innenflaechen 374154
-- (TabardFrameInset/-MoneyInset), Zierrahmen 136862
-- (TabardFrameCustomizationBorder) und 136863 (TabardFrameOuterFrame*,
-- 10 Teile), Leisten der fuenf Auswahlen 131143 (Customization1-5
-- Left/Middle/Right), Geld 525911 (TabardFrameMoneyBg*).
-- Bleibt: Wappen (GetUpper/LowerEmblemTexture), Modell, Pfeile der
-- Auswahl, Drehknoepfe, Preis, Geld, Knoepfe (flach im allgemeinen
-- Durchlauf).
--------------------------------------------------

WeintCodex = WeintCodex or {}

local CP = WeintCodex.UICalmParts
local S = WeintCodex.UIStyle

WeintCodex.UITabard = CP.New({
    label = "Wappenrock", host = "TabardFrame", depth = 4, style = S.CALM,
    files = {
        [374155] = "bg", [374154] = "bg",
        [136862] = "decor", [136863] = "decor",
        [131143] = "strip",
        [525911] = "strip",
    },
})
