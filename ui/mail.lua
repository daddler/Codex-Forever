--------------------------------------------------
-- WeintCodex :: Oberflaeche - Post (6.9.1.2)
--------------------------------------------------
-- Der Briefkasten des Spiels (MailFrame: Posteingang und "Post
-- versenden") in der ruhigen Informationsoberflaeche. Post gehoert nicht
-- zur Klasse: GOLD (S.CALM), wie Bank, Handel und Auktionshaus. Beta-Test
-- 6.9.1.1: Metallrahmen, Marmor, Pergament, Steinplaetze, Eingabefelder
-- mit Goldrand, Holzleisten.
--
--   Huelle     Metallrahmen, Marmor, Streifen weg (W.WINDOWS), das Symbol
--              des Briefkastens oben links weg (wie die Portraets), Kachel,
--              kein Schein der Klasse, Licht und Kante in Gold (ui/calm.lua,
--              Gast "Post").
--   Pergament  im Posteingang (Bild 530419) und hinter dem Brief beim
--              Versenden (136859, 136860) weg, an seiner Stelle eine
--              Innenflaeche. Die Schrift des Briefs ist auf Pergament
--              dunkelbraun - auf der Flaeche wird sie hell (ML.TEXTS).
--   Zeilen     im Posteingang: Rahmen der Zeile (Bild 136383) weg, der
--              Knopf mit dem Symbol flach mit 1 px Rand.
--   Plaetze    die Anhaenge beim Versenden: Stein (130862) und Rand (130718)
--              weg, flach wie im Handel.
--   Felder     "An", "Betreff" und die drei Geldfelder: Goldrand (130975)
--              weg, eine flache Leiste.
--   Leisten    die Trennleisten beim Versenden (130968) weg.
--   Geld       Grund unten (SendMailMoneyBg, 525911) als Innenflaeche; die
--              Innenflaeche des Fensters (MailFrameInset) wie ueberall.
--   Reiter     "Posteingang", "Post versenden" flach, der gewaehlte in Gold.
--   Knoepfe    "Alle oeffnen", "Senden", "Abbrechen": flach (W.SkinPanelButtons
--              im Durchlauf). Blaettern, Geld oder Nachnahme bleiben.
--
-- DAS SYMBOL EINES GEGENSTANDS ODER BRIEFS BLEIBT, ebenso der Rand der
-- Qualitaet. Ausgeblendet wird ein Bild nur, solange es eines der
-- gemessenen ist; zeigt dieselbe Region spaeter etwas anderes, wird sie
-- wieder sichtbar. Geaendert werden nur Bilder und Schriftfarben - kein
-- Skript, kein Feld.
--
-- SEIT 6.10.0.0 nur noch Beschreibung: der Ablauf steht einmal in
-- ui/calmparts.lua.
--
-- GEMESSEN (6.9.1.0, /wcui fenster, beide Reiter): MailFrame (374155,
-- NineSlice "UI-Frame-Metal-*", "UI-Frame-PortraitMetal-*", Streifen),
-- MailFrame.PortraitContainer (136382), MailFrameInset (374154,
-- "!UI-Frame-InnerLeftTile"), InboxFrame (530419), MailItem1 (136383 14x,
-- leeres Symbol 7x), OpenAllMail (130828/130826), PrevPageButton (130757),
-- MailFrameTab1 ("uiframe-tab-*", "uiframe-activetab-*"),
-- SendMailScrollFrame (136859, 136860), SendMailNameEditBox (130975 15x),
-- SendMailAttachment1 (130862 7x, 130718 7x), SendMailFrame (130968 4x),
-- SendMailMoneyBg (525911 3x), SendMailMailButton (130824).
-- UNGEMESSEN: ein geoeffneter Brief (OpenMailFrame) - er bekommt Huelle und
-- Gold, sein Pergament sagt erst /wcui fenster bei offenem Brief.
--------------------------------------------------

WeintCodex = WeintCodex or {}

local C = WeintCodex.Colors
local CP = WeintCodex.UICalmParts
local RG = WeintCodex.UIRegister

local IsFrame = RG.IsFrame

-- Schrift, die auf Pergament dunkel war und auf der Flaeche hell sein muss.
local TEXTS = { "SendMailBodyEditBox", "MailEditBox" }
local ROW_BUTTON, ROWS = "MailItem%dButton", 7

local ML
ML = CP.New({
    label = "Post", host = "MailFrame", depth = 5,
    files = {
        [530419] = "bg",     -- Pergament des Posteingangs
        [136859] = "bg",     -- Pergament hinter dem Brief, oben
        [136860] = "bg",     -- und unten
        [136383] = "decor",  -- Rahmen einer Zeile im Posteingang
        [130862] = "slot",   -- Stein eines Anhangs
        [130718] = "slot",   -- Rand des Knopfs
        [130975] = "field",  -- Goldrand der Eingabefelder
        [130968] = "decor",  -- Trennleisten beim Versenden
        [136382] = "decor",  -- Symbol des Briefkastens oben links
    },
    money = { "SendMailMoneyBg" },
    tabs = { "MailFrameTab1", "MailFrameTab2" },
    after = function(_, m, H)
        -- Die Knoepfe der Zeilen im Posteingang (das Symbol eines Briefs).
        local rows = 0
        for i = 1, ROWS do
            local b = _G[ROW_BUTTON:format(i)]
            if IsFrame(b) then
                CP.Flat(H.flat, b, CP.FLAT_ALPHA)
                rows = rows + 1
            end
        end
        m.rows = rows
        -- Die Schrift erst, wenn das Pergament weg ist - vorher waere helle
        -- Schrift auf hellem Pergament unlesbar.
        local texts = 0
        if m.bg > 0 then
            for _, key in ipairs(TEXTS) do
                local t = _G[key]
                if type(t) == "table" and t.SetTextColor then
                    t:SetTextColor(unpack(C.textBright))
                    texts = texts + 1
                end
            end
        end
        m.texts = texts
    end,
    report = function(_, m, H)
        local nf, nb = 0, 0
        for _ in pairs(H.flat) do nf = nf + 1 end
        for _ in pairs(H.fields) do nb = nb + 1 end
        return string.format("Pergament auf Fläche %d · Plätze und Zeilen flach %d · Felder flach %d · Innenflächen %d · Geld %d · Schrift hell %d · Reiter %d",
            m.bg, nf, nb, m.insets, m.money, m.texts or 0, m.tabs)
    end,
})
ML.TEXTS, ML.ROWS = TEXTS, ROWS
WeintCodex.UIMail = ML
