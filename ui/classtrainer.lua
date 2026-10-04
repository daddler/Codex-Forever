--------------------------------------------------
-- WeintCodex :: Oberflaeche - Lehrer (6.10.1.0)
--------------------------------------------------
-- Das Fenster des Lehrers (ClassTrainerFrame, Blizzard_TrainerUI: Zauber
-- und Berufe lernen) in der ruhigen Informationsoberflaeche. Lehrer
-- gehoeren nicht zur Klasse: GOLD (S.CALM), wie Haendler und Post.
-- Beta-Test 6.10.0.0: "das Lehrerfenster muss auch noch gemacht werden" -
-- Metallrahmen, Pergament, rotbraune Zeilen, roter Knopf.
--
-- EIN BILD, VIER ROLLEN. Pergament, Grund jeder Zeile, Schein unter der
-- Maus und die Markierung der gewaehlten Zeile sind alle dieselbe Datei
-- (404984, "classtrainerframe/trainertextures", nur andere Ausschnitte -
-- Quelltext des Spiels, Blizzard_TrainerUI.xml). Nach Bild sortieren wie
-- an der Post ginge hier also nicht: es naehme auch die Markierung weg.
-- Deshalb nach Rolle, im `after`:
--
--   Pergament  ClassTrainerFrame.BG: weg. Darunter liegt die Innenflaeche
--              (ClassTrainerFrameInset, wie ueberall).
--   Zeilen     der Grund (NormalTexture) weg, die Zeile flach mit 1 px Rand
--              - die Zeilen der Liste (ScrollBox, im Spiel wiederverwendet)
--              und die Zeile oben (skillStepButton).
--   bleibt     Markierung der gewaehlten Zeile (selectedTex, Gold - passt zum
--              Fenster), Schein unter der Maus, Grau fuer Unlernbares
--              (disabledBG), Symbol, Schloss.
--   Geld       Rahmen unten links (ClassTrainerFrameMoneyBg, 237619
--              "moneyframe/ui-moneyframe-border") weg, an seiner Stelle eine
--              Leiste. Sie liegt am Fenster selbst - eine Leiste der Bausteine
--              (Ebene -8) laege dort unter der Kachel (-7) und waere
--              unsichtbar; diese liegt auf -6.
-- Metall, Ring und Portraet, Streifen, der rote Knopf "Ausbilden": der
-- allgemeine Durchlauf (W.WINDOWS); Licht und Kante in Gold: ui/calm.lua.
--
-- GEMESSEN (6.10.0.0, /wcui fenster, Magierlehrer): ClassTrainerFrame
-- (404984 10x, 374155, 237619, NineSlice "UI-Frame-Metal-*",
-- "UI-Frame-PortraitMetal-*", Streifen), ClassTrainerFrameInset (374154),
-- PortraitContainer (RTPortrait1), FilterDropdown
-- ("common-dropdown-b-button"), ScrollBar ("!minimal-scrollbar-track-*"),
-- ClassTrainerTrainButton (130828/130826), Zeilen in der ScrollBox
-- (Zaubersymbole 135807 u. a.). Die Dateinummern sind mit der Dateiliste
-- der Community (wowdev/wow-listfile) aufgeloest.
-- UNGEMESSEN: ein Berufslehrer (Leiste der Fertigkeit, ClassTrainerStatusBar)
-- - Huelle und Gold; was dort alt aussieht, sagt /wcui fenster.
-- Der Knopf "Optionen" (Filter) bleibt wie in den anderen Fenstern.
--------------------------------------------------

WeintCodex = WeintCodex or {}

local K = WeintCodex.UIKit
local W = WeintCodex.UIWindows
local CP = WeintCodex.UICalmParts
local RG = WeintCodex.UIRegister

local GC = WeintCodex.GameColors

local IsFrame = RG.IsFrame
local FileOf = CP.FileOf

local TRAINER_TEX = 404984     -- interface/classtrainerframe/trainertextures
-- Eigene Liste fuer die Zeilen. Noetig ist sie heute nicht (`after` laeuft
-- erst, wenn der Durchlauf der Bausteine fertig ist), sie haelt aber, falls
-- `after` je mitten im Durchlauf gerufen wird.
local ROWS_TAG = "calm:ClassTrainerFrame:rows"

-- Bilder, die WIR wegen ihrer Rolle ausgeblendet haben (nicht H.hidden:
-- dort gibt CalmParts alles frei, was kein gemessenes Bild nach Nummer ist).
local own = setmetatable({}, { __mode = "k" })

local function Off(r)
    if type(r) ~= "table" or not r.SetAlpha then return false end
    if FileOf(r) ~= TRAINER_TEX then
        -- Zeigt die Region etwas anderes: wieder sichtbar.
        if own[r] then r:SetAlpha(1) own[r] = nil end
        return false
    end
    if K.Plain(r:GetAlpha()) ~= 0 then r:SetAlpha(0) end
    own[r] = true
    return true
end

local function NormalOf(b)
    if not b.GetNormalTexture then return nil end
    local ok, t = pcall(b.GetNormalTexture, b)
    return ok and t or nil
end

local function Row(b, H)
    if not IsFrame(b) then return 0 end
    if Off(NormalOf(b)) then
        CP.Flat(H.flat, b, CP.FLAT_ALPHA)
        return 1
    end
    return 0
end

local CT
CT = CP.New({
    label = "Lehrer", host = "ClassTrainerFrame", depth = 3,
    files = {
        [237619] = "decor",  -- Rahmen des Gelds unten links (Leiste: after)
    },
    after = function(f, m, H)
        m.parchment = Off(f.BG) and 1 or 0
        -- Geld: eine Leiste, wo der Rahmen war - nur, solange er weg ist.
        local border = _G.ClassTrainerFrameMoneyBg
        if type(border) == "table" and border.GetAlpha then
            local gone = H.hidden[border] and true or false
            if gone and not m.money_bar and f.CreateTexture then
                local t = f:CreateTexture(nil, "BACKGROUND", nil, -6)
                t:SetAllPoints(border)
                local c = GC.plateBg
                t:SetColorTexture(c[1], c[2], c[3], CP.STRIP_ALPHA)
                m.money_bar = t
            end
            if m.money_bar then
                local shown = K.Bool(m.money_bar:IsShown(), false)
                if gone and not shown then m.money_bar:Show()
                elseif not gone and shown then m.money_bar:Hide() end
            end
        end
        local rows = Row(f.skillStepButton, H)
        local box = f.ScrollBox
        local target = type(box) == "table" and box.ScrollTarget or nil
        if IsFrame(target) then
            for _, b in ipairs(W.Children(target, ROWS_TAG, 0)) do
                rows = rows + Row(b, H)
            end
        end
        m.rows = rows
    end,
    report = function(_, m, H)
        local bar = m.money_bar and K.Bool(m.money_bar:IsShown(), false) and 1 or 0
        return string.format("Pergament weg %d · Zeilen flach %d · Geld als Leiste %d · Innenflächen %d",
            m.parchment or 0, m.rows or 0, bar, m.insets)
    end,
})
CT.TRAINER_TEX, CT.own = TRAINER_TEX, own
WeintCodex.UIClassTrainer = CT
