--------------------------------------------------
-- WeintCodex :: Oberflaeche - Handel (6.9.0.2)
--------------------------------------------------
-- Das Handelsfenster des Spiels (TradeFrame) in der ruhigen
-- Informationsoberflaeche. Handeln gehoert nicht zur Klasse: GOLD (S.CALM),
-- wie Haendler, Beute und Makros. Beta-Test 6.9.0.1: Metallrahmen, Marmor,
-- Leder, Steinplaetze, Namensfelder, rote Knoepfe, Portraets.
--
--   Huelle     Metallrahmen, Marmor, Trennleiste, Streifen und beide
--              Portraets weg (W.WINDOWS: W.Skin, HideOwnTextures), Kachel,
--              kein Schein der Klasse, oben eine feine Kante in Gold.
--              Die beiden Namen oben hell.
--   Flaechen   jede Innenflaeche (InsetFrameTemplate: .Bg Leder + .NineSlice)
--              und der Grund des Gelds beim Gegenueber werden Innenflaechen
--              (W.OwnBackground); Schatten und Kante in Gold: ui/calm.lua.
--   Plaetze    Stein, Goldrand und leerer Platz der sieben Plaetze je Seite
--              (Bilder TR.SLOT_FILES) weg, der Knopf flach mit 1 px Rand wie
--              die Aktionsknoepfe; das Namensfeld daneben (TR.NAME_FILES)
--              wird eine flache Leiste.
--   Knoepfe    "Handeln", "Abbrechen": flach (W.SkinPanelButtons im
--              allgemeinen Durchlauf).
--
-- DAS SYMBOL EINES GEGENSTANDS BLEIBT. Ausgeblendet wird ein Bild nur,
-- solange es eines der gemessenen ist; zeigt dieselbe Region spaeter etwas
-- anderes (ein Gegenstand liegt im Platz), wird sie wieder sichtbar - und
-- Symbolregionen (.icon, .Icon, "...IconTexture") werden nie angefasst.
-- Geaendert werden nur Bilder - kein Skript, kein Feld (Handeln ist
-- geschuetzt).
--
-- SEIT 6.10.0.0 nur noch Beschreibung: der Ablauf (Plaetze, Felder,
-- Innenflaechen, Wiederzeigen) steht einmal in ui/calmparts.lua.
--
-- GEMESSEN (6.9.0.1, /wcui fenster): TradeFrame (Bild 374155), sechs
-- Innenflaechen (Bild 374154, NineSlice "_UI-Frame-InnerTopTile/BotTile"),
-- "!UI-Frame-LeftTile", TradeFrame.NineSlice ("UI-Frame-Metal-*",
-- "UI-Frame-PortraitMetal-*"), "_UI-Frame-TopTileStreaks", RTPortrait1 (2x),
-- TradeRecipientItem1..7 (Bilder 136796, 130766, je 14x), ...ItemButton
-- (130841, 130718, je 14x), TradeRecipientItem7 (137072, 2x),
-- TradeRecipientMoneyBg (525911, 2x), TradeFrameTradeButton (130826, 130828).
-- UNGEMESSEN: welche der Bilder Rand, Stein oder leerer Platz ist - alle
-- drei gehen; und ob die Knoepfe Left/Middle/Right tragen (dann flach).
--------------------------------------------------

WeintCodex = WeintCodex or {}

local K = WeintCodex.UIKit
local C = WeintCodex.Colors
local CP = WeintCodex.UICalmParts

local NAMES = { "TradeFramePlayerNameText", "TradeFrameRecipientNameText" }

local TR = CP.New({
    label = "Handel", host = "TradeFrame", depth = 4,
    files = {
        -- Rand des Knopfs (der Knopf wird flach); Stein und leerer Platz
        -- (gemessen) nur weg - flach wird der Knopf, nicht der ganze Platz.
        [130718] = "slot", [130766] = "decor", [130841] = "decor", [137072] = "decor",
        -- Namensfeld neben dem Platz.
        [136796] = "strip",
    },
    -- Grund des Gelds beim Gegenueber (Rahmen, kein InsetFrameTemplate).
    money = { "TradeRecipientMoneyBg" },
    -- Die beiden Namen oben hell.
    after = function(_, m)
        local n = 0
        for _, key in ipairs(NAMES) do
            local t = _G[key]
            if type(t) == "table" and t.SetTextColor then
                t:SetTextColor(unpack(C.textBright))
                n = n + 1
            end
        end
        m.names = n
    end,
    report = function(_, m, H)
        local nf, ns = 0, 0
        for _ in pairs(H.flat) do nf = nf + 1 end
        for _ in pairs(H.strips) do ns = ns + 1 end
        return string.format("Plätze flach %d · Namensfelder %d · Innenflächen %d · Geld %s · Namen hell %d",
            nf, ns, m.insets, m.money > 0 and "auf Fläche" or "nicht gefunden", m.names or 0)
    end,
})
TR.NAMES = NAMES
WeintCodex.UITrade = TR
