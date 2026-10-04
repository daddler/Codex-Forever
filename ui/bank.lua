--------------------------------------------------
-- WeintCodex :: Oberflaeche - Bank (6.9.1.1)
--------------------------------------------------
-- Die Bank des Spiels (BankFrame) in der ruhigen Informationsoberflaeche.
-- Die Bank gehoert nicht zur Klasse: GOLD (S.CALM), wie Haendler, Handel
-- und Auktionshaus. Beta-Test 6.9.1.0: Metallrahmen, Portraet, Steinplaetze,
-- Holzleisten, Grund aus Leder.
--
--   Huelle     Metallrahmen, Marmor, Streifen, Portraet weg (W.WINDOWS,
--              Muster in W.HIDE_ATLAS), Kachel, kein Schein der Klasse,
--              Licht und Kante in Gold (ui/calm.lua, Gast "Bank").
--   Grund      "bank-frame-background" weg, an seiner Stelle eine
--              Innenflaeche (W.Insets: Schatten und Kante in Gold aus
--              ui/calm.lua); Trennleiste und Schatten am Rand weg.
--   Plaetze    Stein ("bags-item-bankslot64"), Rahmen
--              ("bank-frame-item-slotframe") und Rand des Knopfs (Bild
--              BK.BUTTON_FILE) der 48 Plaetze weg, der Knopf flach mit 1 px
--              Rand wie die Aktionsknoepfe. Dasselbe fuer die acht
--              Taschenplaetze ("bank-frame-bag-slotframe", "-slot-bg").
--              Das Schloss eines ungekauften Platzes bleibt - es sagt etwas.
--   Geld       der Rahmen unten rechts (BankPanel.MoneyFrame.Border, Bild
--              525911) als Innenflaeche.
--   Reiter     rechts (Gold des Spiels "common-sidetab"): kleine Kacheln, der
--              gewaehlte in Gold (W.SkinSideTabs im allgemeinen Durchlauf).
--   Knoepfe    "Kaufen": flach (W.SkinPanelButtons im Durchlauf).
--
-- DAS SYMBOL EINES GEGENSTANDS BLEIBT, ebenso der Rand in der Farbe der
-- Qualitaet (IconBorder), die Suche und das Sortieren. Ausgeblendet wird
-- ein Bild nur, solange es eines der gemessenen ist; zeigt dieselbe Region
-- spaeter etwas anderes, wird sie wieder sichtbar. Geaendert werden nur
-- Bilder - kein Skript, kein Feld.
--
-- SEIT 6.10.0.0 nur noch Beschreibung: der Ablauf steht einmal in
-- ui/calmparts.lua.
--
-- GEMESSEN (6.9.1.0, /wcui fenster): BankFrame (Bild 374155,
-- "bank-frame-background", "bank-divider", NineSlice "UI-Frame-Metal-*",
-- "UI-Frame-PortraitMetal-*", "_UI-Frame-TopTileStreaks", RTPortrait1),
-- BankPanel.EdgeShadows ("_bank-frame-horiz-shadow" 2x,
-- "!bank-frame-vert-shadow" 2x), 48 Plaetze ("bags-item-bankslot64",
-- "bank-frame-item-slotframe"), Bild 130718 (57x), acht Taschenplaetze
-- ("bank-frame-bag-slot-bg", "bank-frame-bag-slotframe",
-- "bankslot-icon-lock"), BankPanel.MoneyFrame.Border (525911, 3x),
-- Seitenreiter ("common-sidetab", "common-sidetab-selected").
-- UNGEMESSEN: die Gildenbank (GuildBankFrame, erst beim Oeffnen geladen) -
-- sie bekommt Huelle und Gold, ihre Plaetze sagt erst /wcui fenster.
--------------------------------------------------

WeintCodex = WeintCodex or {}

local CP = WeintCodex.UICalmParts
local RG = WeintCodex.UIRegister

local IsFrame = RG.IsFrame

local BK = CP.New({
    label = "Bank", host = "BankFrame", depth = 5,
    -- Rand des Knopfs (Bild, gemessen - dasselbe wie im Handel).
    files = { [130718] = "slot" },
    atlases = {
        -- Stein und Rahmen der Plaetze und Taschenplaetze.
        { "^bags%-item%-bankslot", "slot" },
        { "^bank%-frame%-item%-slotframe", "slot" },
        { "^bank%-frame%-bag%-slotframe", "slot" },
        { "^bank%-frame%-bag%-slot%-bg", "slot" },
        -- Grund der Bank: wird Innenflaeche.
        { "^bank%-frame%-background", "bg" },
        -- Schmuck: Trennleiste und Schatten am Rand.
        { "^bank%-divider", "decor" },
        { "^[_!]?bank%-frame%-%a+%-shadow", "decor" },
    },
    -- Geldrahmen unten: BankPanel.MoneyFrame.Border.
    moneyOf = function(f)
        local panel = f.BankPanel
        if not IsFrame(panel) then panel = _G.BankPanel end
        local mf = IsFrame(panel) and panel.MoneyFrame or nil
        return IsFrame(mf) and mf.Border or nil
    end,
    report = function(_, m, H)
        local nf, nh = 0, 0
        for _ in pairs(H.flat) do nf = nf + 1 end
        for _ in pairs(H.hidden) do nh = nh + 1 end
        return string.format("Plätze flach %d · Bilder weg %d · Grund %s · Geld %s", nf, nh,
            m.bg > 0 and "auf Fläche" or "nicht gefunden", m.money > 0 and "auf Fläche" or "nicht gefunden")
    end,
})
WeintCodex.UIBank = BK
