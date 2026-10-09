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
               SocialUIFrame = "Kontakte", ClassTrainerFrame = "Lehrer",
               LegacySystemFrame = "Vermächtnis", CalendarFrame = "Kalender",
               CooldownViewerSettings = "Abklingzeiten" }
LF.HOSTS = { "LFGParentFrame", "PVEFrame", "CollectionsJournal", "SettingsPanel", "MacroFrame", "TradeFrame",
             "AuctionHouseFrame", "BankFrame", "GuildBankFrame", "MailFrame", "OpenMailFrame", "FriendsFrame",
             "SocialUIFrame", "ClassTrainerFrame", "LegacySystemFrame", "CalendarFrame",
             "CooldownViewerSettings" }
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

-- VERMAECHTNIS (6.25.4.0, gemessen mit /wcui fenster): Rahmen und Reiter
-- weg reichte nicht - jede der drei Seiten traegt eigenes Leder, Metall und
-- Karten. 6.25.5.0 (Beta-Test: "unterer Teil besser", Herausforderungen
-- "komplett anders", Baum "angleichen"): eine Regel je Bild des Spiels
-- (Atlas, gemessen auf allen drei Seiten), angewandt auf das ganze Fenster:
--   hide  Leder und Metallrahmen weg (Kachel darunter)
--   dark  Karten, Zeilen, Leistengrund: entsaettigt und dunkel
--   gold  Erreichtes, Fuellungen, gewaehlte Zeile, Trenner: Gold
-- Symbole, Krone, Haken, Rauten und Pfeile bleiben - sie tragen Bedeutung.
LF.LEGACY_ATLAS = {
    ["Legacy-Rewards-Tracker-background"] = "hide",
    ["Legacy-Challenge-BG"]               = "hide",
    ["Legacy-Tree-Frame-background"]      = "hide",
    ["Legacy-Progressbar-Frame"]          = "hide",
    ["Legacy-Progressbar-BG"]             = "dark",
    ["Legacy-Rewards-Tracker-Cards-Disable"] = "dark",
    ["Legacy-Rewards-Tracker-Icons-Frame-Disable"] = "dark",
    ["Legacy-Challenge-Left-Sub-Tab"]     = "dark",
    ["Legacy-Tree-Frame-Card"]            = "dark",
    ["Legacy-Tree-Frame-Points-Bar"]      = "dark",
    ["Legacy-Rewards-Tracker-Cards"]      = "gold",
    ["Legacy-Rewards-Tracker-Icons-Frame"] = "gold",
    ["Legacy-Progressbar-Fill"]           = "gold",
    ["Legacy-Challenge-Left-Sub-Tab-selected"] = "gold",
    ["Legacy-Tree-Frame-divider-Vertical"] = "gold",
}
LF.LEGACY_DEPTH = 7
LF.DARK = 0.32              -- Helligkeit der entsaettigten Teile
LF.legacy = { hide = 0, dark = 0, gold = 0 }

-- KALENDER (6.26.3.0, gemessen mit /wcui fenster): Pergament, Holzrahmen
-- und orange Wochentage, alles Bilder per Nummer statt Atlas. Dieselben
-- drei Regeln wie beim Vermaechtnis; Feiertage (Kuerbis, Angel, Fledermaus-
-- Rahmen) und Termine bleiben - sie tragen Bedeutung.
LF.CALENDAR_FILE = {
    [235431] = "hide",      -- Rahmen oben/unten
    [235430] = "hide",      -- Rahmen links/rechts
    [235428] = "dark",      -- Pergament: Tage, Monat, Jahr
    [235438] = "gold",      -- Kante je Tag
    [235433] = "gold",      -- heute
}
-- Wochentage: Pergament in gedaempftem Gold statt dunkel - die Kopfzeile.
LF.CALENDAR_HEAD = "^CalendarWeekday%dBackground$"
LF.HEAD = 0.55              -- Helligkeit des Golds der Kopfzeile
LF.CALENDAR_DEPTH = 4

local function LegacyAtlas(r)
    local ok, a = pcall(r.GetAtlas, r)
    a = ok and K.Plain(a)
    return type(a) == "string" and a or nil
end

local function LegacyApply(r, how, L)
    L = L or LF.legacy
    if how == "hide" then
        if K.Plain(r:GetAlpha()) ~= 0 then r:SetAlpha(0) end
    else
        if r.SetDesaturated then r:SetDesaturated(true) end
        if how == "gold" then
            local g = GC.frameAccent
            r:SetVertexColor(g[1], g[2], g[3])
        else
            r:SetVertexColor(LF.DARK, LF.DARK, LF.DARK)
        end
    end
    L[how] = L[how] + 1
end

local function LegacyWalk(f, depth)
    local regs = W.Regions(f, "legacy", depth)
    for i = 1, #regs do
        local r = regs[i]
        if r.GetAtlas then
            local how = LF.LEGACY_ATLAS[LegacyAtlas(r)]
            if how then LegacyApply(r, how) end
        end
    end
    if depth >= LF.LEGACY_DEPTH then return end
    local kids = W.Children(f, "legacy", depth)
    for i = 1, #kids do LegacyWalk(kids[i], depth + 1) end
end

-- ABKLINGZEIT-EINSTELLUNGEN (6.26.10.0, gemessen mit /wcui fenster:
-- CooldownViewerSettings). Rahmen, Seitenreiter und Suche nimmt der
-- allgemeine Durchgang (W.WINDOWS); hier das Leder dahinter und die
-- Kopfzeilen der Gruppen (aufklappbare Balken des Spiels) - dunkel wie die
-- Zeilen beim Vermaechtnis. Symbole der Zauber bleiben.
LF.COOLDOWN_ATLAS = {
    ["character-panel-background"]       = "hide",
    ["Options_ListExpand_Left"]          = "dark",
    ["_Options_ListExpand_Middle"]       = "dark",
    ["Options_ListExpand_Right_Expanded"] = "dark",
    ["Options_ListExpand_Right"]         = "dark",
}
LF.COOLDOWN_DEPTH = 7
LF.cooldown = { hide = 0, dark = 0, gold = 0 }

local function CooldownWalk(f, depth)
    local regs = W.Regions(f, "cooldown", depth)
    for i = 1, #regs do
        local r = regs[i]
        if r.GetAtlas then
            local how = LF.COOLDOWN_ATLAS[LegacyAtlas(r)]
            if how then LegacyApply(r, how, LF.cooldown) end
        end
    end
    if depth >= LF.COOLDOWN_DEPTH then return end
    local kids = W.Children(f, "cooldown", depth)
    for i = 1, #kids do CooldownWalk(kids[i], depth + 1) end
end

function LF.Cooldown(f)
    local L = LF.cooldown
    L.hide, L.dark, L.gold = 0, 0, 0
    CooldownWalk(f, 0)
    return L
end

LF.calendar = { hide = 0, dark = 0, gold = 0 }

local function CalendarApply(r)
    local ok, file = pcall(r.GetTexture, r)
    file = ok and K.Plain(file)
    local how = type(file) == "number" and LF.CALENDAR_FILE[file]
    if not how then return end
    local L = LF.calendar
    if how == "hide" then
        if K.Plain(r:GetAlpha()) ~= 0 then r:SetAlpha(0) end
    else
        if r.SetDesaturated then r:SetDesaturated(true) end
        local nok, name = pcall(r.GetName, r)
        name = nok and K.Plain(name)
        if how == "dark" and type(name) == "string" and name:find(LF.CALENDAR_HEAD) then
            local g, h = GC.frameAccent, LF.HEAD
            r:SetVertexColor(g[1] * h, g[2] * h, g[3] * h)
            how = "gold"
        elseif how == "gold" then
            local g = GC.frameAccent
            r:SetVertexColor(g[1], g[2], g[3])
        else
            r:SetVertexColor(LF.DARK, LF.DARK, LF.DARK)
        end
    end
    L[how] = L[how] + 1
end

local function CalendarWalk(f, depth)
    local regs = W.Regions(f, "calendar", depth)
    for i = 1, #regs do
        local r = regs[i]
        if r.GetTexture then CalendarApply(r) end
    end
    if depth >= LF.CALENDAR_DEPTH then return end
    local kids = W.Children(f, "calendar", depth)
    for i = 1, #kids do CalendarWalk(kids[i], depth + 1) end
end

function LF.Calendar(f)
    local L = LF.calendar
    L.hide, L.dark, L.gold = 0, 0, 0
    CalendarWalk(f, 0)
    return L
end

function LF.Legacy(f)
    local L = LF.legacy
    L.hide, L.dark, L.gold = 0, 0, 0
    LegacyWalk(f, 0)
    return L
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
    if ok and name == "LegacySystemFrame" then LF.Legacy(f) end
    if ok and name == "CalendarFrame" then LF.Calendar(f) end
    if ok and name == "CooldownViewerSettings" then LF.Cooldown(f) end
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
    if ok and name == "LegacySystemFrame" then
        local L = LF.legacy
        out[#out + 1] = string.format("   Vermächtnis: ausgeblendet %d · dunkel %d · Gold %d",
            L.hide or 0, L.dark or 0, L.gold or 0)
    end
    if ok and name == "CooldownViewerSettings" then
        local L = LF.cooldown
        out[#out + 1] = string.format("   Abklingzeiten: ausgeblendet %d · dunkel %d", L.hide or 0, L.dark or 0)
    end
    if ok and name == "CalendarFrame" then
        local L = LF.calendar
        out[#out + 1] = string.format("   Kalender: ausgeblendet %d · dunkel %d · Gold %d",
            L.hide or 0, L.dark or 0, L.gold or 0)
    end
    return out
end
