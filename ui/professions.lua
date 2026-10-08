--------------------------------------------------
-- WeintCodex :: Oberflaeche - Berufe (6.7.5.0)
--------------------------------------------------
-- Das Berufsfenster (ProfessionsFrame) in derselben ruhigen
-- Informationsoberflaeche wie Ruf, Fertigkeiten, Abzeichen und
-- Statistiken - aber in GOLD (S.CALM): Berufe gehoeren nicht zur Klasse.
-- Das ist der Fall, fuer den das Gold (GameColors.frameAccent) seit 6.7.0.0
-- bereitliegt; ein Bereich, ein Akzent.
--
-- Die Rezeptseite (CraftingPage) ist ein Register (ui/register.lua), das
-- erste ausserhalb des Charakterfensters (cfg.host):
--   links   die Rezeptliste des Spiels: Kategorien als Abschnitte (Band,
--           Raute, Linie in Gold), Rezepte mit Haarlinie, Hervorhebung des
--           Spiels (Hover und gewaehlt) in Gold getoent, Auswahl-Strich.
--   rechts  das Rezept (SchematicForm) als Karte: Name groesser in SEINER
--           Farbe (Qualitaet), Beschreibung, darunter abgesetzt, was folgt
--           (Reagenzien, Werkzeug, ...); die Karte endet unter dem Inhalt.
--           Nichts davon wird bewegt - Knoepfe (Reagenzien) sperren das
--           Ruecken ohnehin.
--   Grund   Hintergrund der Seite, der Rezeptliste und das grosse Bild
--           hinter dem Rezept sind weg (ui/windows.lua, W.HIDE_ATLAS) - die
--           Flaechen des Registers liegen an ihrer Stelle.
-- Unveraendert: Rangbalken oben (Rahmen, animierte Fuellung, Text),
-- Symbol des Ergebnisses mit Qualitaetsrahmen, Plaetze der Reagenzien,
-- Filter, Knoepfe (Herstellen, Alle), Suchfeld, Seitenreiter.
--
-- GEMESSEN (6.7.4.0, /wcui fenster auf der Seite der Kochkunst):
--   ProfessionsFrame.CraftingPage                 Profession-Background-Template2
--   .CraftingPage.RecipeList                      Professions-background-summarylist
--   .RecipeList.ScrollBox.ScrollTarget.<Zeile>    Professions_Recipe_Hover/_Active
--   .RecipeList.ScrollBar                         minimal-scrollbar-*
--   .CraftingPage.SchematicForm                   Profession-background-card-Cooking
--   .SchematicForm.OutputIcon, .Reagents.<..>.Button, .CraftingPage.RankBar
--   Kategorien der Liste: Kopfzeilen des Spiels ("Alltaegliche Mahlzeiten").
-- UNGEMESSEN: Schluessel des Rezeptnamens (OutputText wie im Quelltext des
-- Spiels, sonst die oberste Zeile) und der Zeilen (Label).
--
-- Die UEBERSICHT (erster Seitenreiter, Karten je Beruf) bleibt, wie sie seit
-- 6.6.2.1 ist (Hintergrund weg, Bilder der Karten gedaempft) - bekommt aber
-- denselben Stil (Gold). Ihr Aufbau ist nicht gemessen.
--------------------------------------------------

WeintCodex = WeintCodex or {}

local S = WeintCodex.UIStyle

-- Das ganze Fenster in Gold: Kopfzeilen und Balken auch der Uebersicht.
S.SCOPES.ProfessionsFrame = S.CALM

WeintCodex.UIProfessions = WeintCodex.UIRegister.New({
    label          = "Berufe",
    key            = "prof",
    host           = "ProfessionsFrame",
    style          = S.CALM,
    frames         = { "ProfessionsFrame.CraftingPage" },
    listKeys       = { "RecipeList.ScrollBox", "ScrollBox" },
    scrollBarKeys  = { "RecipeList.ScrollBar", "ScrollBar" },
    highlightAtlas = "^Professions_Recipe_",
    detailKeys     = { "SchematicForm" },
    titleKeys      = { "OutputText", "RecipeName", "Title", "Name" },
    titleTop       = true,
    -- Der Rezeptname kann die Qualitaet tragen: seine Farbe bleibt.
    titleColor     = false,
    barKeys        = { "StatusBar", "Bar" },
    detailBarKeys  = { "StatusBar", "Bar" },
    barLine        = "below",
    tail           = true,
    compact        = true,
})

--------------------------------------------------
-- Symbol des Rezepts (6.25.3.0)
--------------------------------------------------
-- Client-Update Build 70291 (Beta-Test: "an der Optik des Icons oben
-- gearbeitet"): das Symbol des Rezepts (SchematicForm.OutputIcon) traegt
-- jetzt zusaetzlich die Bilder eines Gegenstandsknopfs - ein dunkles
-- Fach (Bild 130841, "ProfessionsFrameNormalTexture") und eine Farbflaeche
-- ("ProfessionsFrameIconTexture"), beide versetzt ueber dem Symbol. Weg
-- damit; Symbol (.Icon) und Rahmen (.IconBorder) bleiben.
local PR = WeintCodex.UIProfessions
local K = WeintCodex.UIKit

local function Ends(r, suffix)
    local ok, name = pcall(r.GetName, r)
    name = ok and K.Plain(name)
    return type(name) == "string" and name:sub(-#suffix) == suffix
end

function PR.CleanOutputIcon()
    local pf = _G.ProfessionsFrame
    local form = type(pf) == "table" and pf.CraftingPage and pf.CraftingPage.SchematicForm
    local oi = type(form) == "table" and form.OutputIcon
    if type(oi) ~= "table" or not oi.GetRegions then return 0 end
    local keep = { [oi.Icon or false] = true, [oi.IconBorder or false] = true }
    if oi.GetHighlightTexture then keep[oi:GetHighlightTexture() or false] = true end
    local normal = oi.GetNormalTexture and oi:GetNormalTexture()
    local n = 0
    local function Hide(r)
        if r and not keep[r] and r.SetAlpha then
            if K.Plain(r:GetAlpha()) ~= 0 then r:SetAlpha(0) end
            n = n + 1
        end
    end
    for _, r in ipairs({ oi:GetRegions() }) do
        if r.GetObjectType and r:GetObjectType() == "Texture"
           and (r == normal or Ends(r, "NormalTexture") or Ends(r, "IconTexture")) then
            Hide(r)
        end
    end
    -- Die beiden Bilder haengen unter dem Namen des Fensters; nur, wenn sie
    -- im Rezept liegen.
    for _, g in ipairs({ "ProfessionsFrameNormalTexture", "ProfessionsFrameIconTexture" }) do
        local r = _G[g]
        local p = type(r) == "table" and r.GetParent and r:GetParent()
        local inForm = false
        while type(p) == "table" do
            if p == form then inForm = true break end
            p = p.GetParent and p:GetParent()
        end
        if inForm then Hide(r) end
    end
    PR.outputHidden = n
    return n
end

do
    local update = PR.Update
    PR.Update = function(f, ...)
        local r = update(f, ...)
        pcall(PR.CleanOutputIcon)
        return r
    end
    local report = PR.Report
    PR.Report = function(f, out, ...)
        local o = report(f, out, ...)
        out[#out + 1] = "   Berufe, Symbol des Rezepts: " .. (PR.outputHidden and (PR.outputHidden .. " fremde Bilder ausgeblendet") or "noch nicht gesehen")
        return o
    end
end
