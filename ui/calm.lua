--------------------------------------------------
-- WeintCodex :: Oberflaeche - Fenster in Gold mit Innenflaechen (6.8.0.2)
--------------------------------------------------
-- Fenster, die nicht zur Klasse gehoeren und deren Inhalt auf
-- Innenflaechen liegt, in der ruhigen Informationsoberflaeche, in GOLD
-- (S.CALM). Bis 6.8.0.1 hiess das Modul ui/lfg.lua und kannte nur die
-- Suche nach Gruppe; die Sammlung (6.8.0.2) braucht genau dasselbe.
--
--   Grund      der Schein der Klasse oben ist in Gold aus (W.HoldGlow),
--              statt dessen ein Hauch neutrales Licht.
--   Flaechen   jede Innenflaeche des Fensters (W.Insets - von W.SkinInsets
--              oder W.OwnBackground gestaltet) bekommt, was die Flaechen der
--              Register tragen: weichen Schatten und oben eine feine Kante
--              in Gold; aus mit ihr. Gefunden ueber W.Insets und InTree,
--              nicht ueber Namen.
--   Akzent     Gold am gewaehlten Seitenreiter (SkinSideTabs) und an
--              gewaehlten Reitern oben (SkinTabSystems) - Stil des Fensters.
--
-- Fenster (gemessen, /wcui fenster):
--   Suche nach Gruppe  LFGParentFrame (Quelltext: PVEFrame) - Innenflaechen:
--                      der Bereich des ersten Reiters, LFGBrowseFrame und
--                      LFGWhoListFrame (W.OWN_BG_PATHS, 6.8.0.1)
--   Optionen           SettingsPanel (6.9.0.0, Esc -> Optionen) - Innenflaechen:
--                      die Kategorien links (CategoryList) und die
--                      Einstellungen rechts (Container), LF.INSETS. Der
--                      Rahmen um beide ("Options_InnerFrame") ist weg, die
--                      Kategorien Gameplay / Zugaenglichkeit / System
--                      ("Options_CategoryHeader_1..3", brauner Balken) sind
--                      Abschnitte mit Raute und Linie in Gold (W.HEADER_ATLAS),
--                      der Titel "Optionen" (NineSlice.Text) hell.
--                      Schalter, Haken, Regler, Auswahl, Suche, Tastenbelegung
--                      und die Wahl links (Options_List_Active) bleiben.
--   Makros             MacroFrame (6.9.0.0) - Innenflaechen: Makroliste und
--                      Textfeld (LF.INSETS); Plaetze und Reiter: ui/macroframe.lua
--   Handel             TradeFrame (6.9.0.2) - Innenflaechen findet ui/trade.lua
--                      (InsetFrameTemplate); Plaetze und Namensfelder dort
--   Auktionshaus       AuctionHouseFrame (6.9.0.4) - Listen, Geld: ui/auction.lua
--   Bank               BankFrame (6.9.1.1) - Grund, Plaetze, Geld: ui/bank.lua
--   Gildenbank         GuildBankFrame (6.9.1.1) - Reiter, Geld, Wappen: ui/bank.lua (6.10.4.2)
--   Post               MailFrame (6.9.1.2) - Pergament, Zeilen, Plaetze, Felder,
--                      Geld, Reiter: ui/mail.lua
--   Brief              OpenMailFrame (6.9.1.2) - nur Huelle und Gold, ungemessen
--   Sammlung           CollectionsJournal - Innenflaeche:
--                      WardrobeCollectionFrame.ItemsCollectionFrame
--                      (W.OWN_BG_PATHS seit 6.6.3.3); Plaetze der Vorlagen
--                      (transmog-nav-slot-*, der gewaehlte mit Goldring des
--                      Spiels), Klassenauswahl, Suche, Filter, Blaettern;
--                      Reiter oben flach (LF.TABS, 6.10.4.2)
-- Unveraendert jeweils: Symbole, Ringe, Auswahl, Texte, Knoepfe.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UICalm = {}

local LF = WeintCodex.UICalm
local K = WeintCodex.UIKit
local C = WeintCodex.Colors
local GC = WeintCodex.GameColors
local W = WeintCodex.UIWindows
local S = WeintCodex.UIStyle
local RG = WeintCodex.UIRegister

local Visible, IsFrame, InTree = RG.Visible, RG.IsFrame, RG.InTree

-- Fenster -> Name im Bericht.
LF.WINDOWS = { LFGParentFrame = "Suche nach Gruppe", PVEFrame = "Suche nach Gruppe",
               CollectionsJournal = "Sammlung", SettingsPanel = "Optionen", MacroFrame = "Makros",
               TradeFrame = "Handel", AuctionHouseFrame = "Auktionshaus",
               BankFrame = "Bank", GuildBankFrame = "Gildenbank",
               MailFrame = "Post", OpenMailFrame = "Brief", FriendsFrame = "Kontakte",
               SocialUIFrame = "Kontakte", ClassTrainerFrame = "Lehrer" }
LF.HOSTS = { "LFGParentFrame", "PVEFrame", "CollectionsJournal", "SettingsPanel", "MacroFrame", "TradeFrame",
             "AuctionHouseFrame", "BankFrame", "GuildBankFrame", "MailFrame", "OpenMailFrame", "FriendsFrame",
             "SocialUIFrame", "ClassTrainerFrame" }
-- Innenflaechen, die das Fenster selbst nicht als solche baut: Feld am
-- Fenster oder globaler Name -> W.OwnBackground (eigene Bilder weg,
-- Innenflaeche). Makros (6.9.0.0, ui/macroframe.lua): die Liste (Leder)
-- und das Textfeld (Rahmen des Tooltips).
LF.INSETS = { SettingsPanel = { "CategoryList", "Container" },
              MacroFrame = { "MacroFrameInset", "MacroFrameTextBackground" } }
-- Reiter oben in einem Teilfenster (6.10.4.2, gemessen 05.10.2026): die
-- Sammlung trug am Reiter "Gegenstaende" noch das Gold des Spiels
-- (uiframe-activetab-*). Flach wie ueberall (W.SkinTab); welcher gewaehlt
-- ist, merkt sich das Teilfenster (PanelTemplates: selectedTab).
LF.TABS = { CollectionsJournal = { owner = "WardrobeCollectionFrame",
                                   names = { "WardrobeCollectionFrameTab1", "WardrobeCollectionFrameTab2" } } }
LF.STYLE = S.CALM
LF.LIGHT_HEIGHT = 120
LF.SHADOW_PAD = 10
LF.EDGE = 0.45              -- Kante oben in Gold

for _, host in ipairs(LF.HOSTS) do
    S.SCOPES[host] = LF.STYLE
    W.HOSTED[host] = W.HOSTED[host] or {}
    table.insert(W.HOSTED[host], LF)
end

local windows = setmetatable({}, { __mode = "k" })
local decks = setmetatable({}, { __mode = "k" })
LF.windows, LF.decks = windows, decks

local function Deck(f, inset, accent)
    local d = { on = true }
    d.shadow = S.Shadow(f, inset, LF.SHADOW_PAD, -5)
    d.edge = S.Under(S.Divider(inset, accent, LF.EDGE, 0), 2)
    S.PlaceTop(d.edge, inset, 12, 0)
    d.parts = { d.shadow, d.edge.l, d.edge.r }
    decks[inset] = d
    return d
end

-- Titel im Rahmen (SettingsPanel: NineSlice.Text) hell statt Gold.
local function Title(f)
    local ns = f.NineSlice
    local t = type(ns) == "table" and ns.Text
    if type(t) == "table" and t.SetTextColor then
        K.SetFont(t, 13)
        t:SetTextColor(unpack(C.textBright))
        return true
    end
    return false
end

function LF.Update(f)
    local w = windows[f]
    if not w then
        local l = GC.atmosLight
        w = { light = S.TopLight(f, f, l, l[4], LF.LIGHT_HEIGHT, -5) }
        local ok, name = pcall(f.GetName, f)
        local keys = ok and LF.INSETS[name]
        if keys then
            for _, key in ipairs(keys) do
                local inset = f[key]
                if not IsFrame(inset) then inset = _G[key] end
                if IsFrame(inset) then W.OwnBackground(inset) end
            end
            w.title = Title(f)
        end
        windows[f] = w
    end
    local accent = S.Accent(LF.STYLE.accent)
    local n = 0
    for inset in pairs(W.Insets) do
        if IsFrame(inset) and InTree(inset, f) then
            local d = decks[inset] or Deck(f, inset, accent)
            local on = Visible(inset)
            if d.on ~= on then
                d.on = on
                for _, t in ipairs(d.parts) do t:SetShown(on) end
            end
            if on then n = n + 1 end
        end
    end
    w.decks = n
    w.tabs = 0
    local ok, name = pcall(f.GetName, f)
    local spec = ok and LF.TABS[name]
    if spec then
        local owner = _G[spec.owner]
        local selected = IsFrame(owner) and K.Plain(owner.selectedTab) or nil
        for i, tabName in ipairs(spec.names) do
            local tab = _G[tabName]
            if IsFrame(tab) and tab.CreateTexture then
                -- Nicht `x and (a == b) or nil` - das macht aus false nil
                -- (die Falle `x and false or nil`, docs/systems/ui.md).
                local sel
                if type(selected) == "number" then sel = (selected == i) end
                W.SkinTab(tab, accent, sel)
                w.tabs = w.tabs + 1
            end
        end
    end
    return w
end

function LF.Report(f, out)
    local w = windows[f]
    if not w then return out end
    local ok, name = pcall(function() return f:GetName() end)
    local label = ok and LF.WINDOWS[name] or "Fenster in Gold"
    out[#out + 1] = string.format("   %s (Stil %s): %d Innenflächen mit Kante in Gold%s%s", label, LF.STYLE.name,
        w.decks or 0, (w.decks or 0) == 0 and " (keine gefunden)" or "",
        (ok and LF.TABS[name]) and (" · Reiter oben " .. (w.tabs or 0)) or "")
    return out
end
