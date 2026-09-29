--------------------------------------------------
-- WeintCodex :: Oberflaeche - Zauberbuch (6.7.7.0)
--------------------------------------------------
-- Das Zauberbuch (PlayerSpellsFrame.SpellBookFrame) in der ruhigen
-- Informationsoberflaeche. Die Zauber gehoeren zur Klasse: Stil
-- S.CHARACTER_INFO, Akzent die Klassenfarbe - wie die Reiter des
-- Charakterfensters. Kein Register (die Zauber stehen in einem Raster,
-- nicht in einer Liste mit Detailansicht), aber dieselben Bausteine:
--
--   Grund      statt des grossen Scheins in der Klassenfarbe (W.AddGlow,
--              bei Kriegern ein brauner Verlauf ueber die halbe Seite)
--              Vignette und neutrales Licht wie im Register; der Schein
--              ist aus, solange das Zauberbuch offen ist (GlowOff).
--   Flaeche    die Seite mit den Zaubern (PagedSpellsFrame) liegt auf der
--              angehobenen Flaeche mit weichem Schatten und Lichtkante.
--   Abschnitt  die Ueberschrift einer Gruppe ("Allgemein", der Name eines
--              Talentbaums) bekommt Raute und Linie in der Klassenfarbe
--              hinter dem Text - wie die Kopfzeilen im Ruf. Schrift, Groesse
--              und Lage bleiben (sie ist der Seitentitel).
--
-- Unveraendert: Zauber (Symbol, Name, "Passiv", "Volksfaehigkeit"), der
-- Schein an nicht zugewiesenen Zaubern (spellbook-item-unassigned-glow -
-- er sagt etwas), Reiter der Kategorien oben, Suchfeld, Blaettern.
-- Symbole tragen seit 6.4.1.2 den eckigen Rand der Aktionsleisten.
--
-- GEMESSEN (6.7.5.0, /wcui fenster): PlayerSpellsFrame.SpellBookFrame mit
-- .PagedSpellsFrame.View1.<Eintrag>.Button (Zauber), .PagingControls,
-- .CategoryTabSystem, .SettingsDropdown.
-- UNGEMESSEN: die Ueberschrift. Gesucht wird ein Eintrag in View1 OHNE
-- .Button mit einer Schriftzeile mit Text - die Zauber haben alle einen.
-- /wcui fenster nennt, was gefunden wurde ("Zauberbuch, …").
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UISpellBook = {}

local SB = WeintCodex.UISpellBook
local K = WeintCodex.UIKit
local C = WeintCodex.Colors
local GC = WeintCodex.GameColors
local W = WeintCodex.UIWindows
local S = WeintCodex.UIStyle
local RG = WeintCodex.UIRegister

local Visible, Kind, IsFrame, TextOf = RG.Visible, RG.Kind, RG.IsFrame, RG.TextOf

SB.LABEL = "Zauberbuch"
SB.HOST = "PlayerSpellsFrame"
SB.STYLE = S.CHARACTER_INFO
SB.VIGNETTE, SB.VIGNETTE_SIZE = 0.35, 48
SB.LIGHT_HEIGHT = 140
SB.PAD = 8                  -- Flaeche so weit ueber die Seite hinaus
SB.SHADOW_PAD = 16
SB.EDGE = 0.07
SB.GAP = 8                  -- Text -> Raute -> Linie (wie W.LIST_GAP)
SB.INSET = 16               -- Linie endet so weit vor dem Rand der Seite
SB.LINE = 0.55
SB.VIEWS = { "View1", "View2" }

-- Nur das Zauberbuch, nicht das ganze Fenster (die Talente liegen daneben).
S.SCOPES["PlayerSpellsFrame.SpellBookFrame"] = SB.STYLE
W.HOSTED[SB.HOST] = W.HOSTED[SB.HOST] or {}
table.insert(W.HOSTED[SB.HOST], SB)

local WHITE = { 1, 1, 1 }
local books = setmetatable({}, { __mode = "k" })
local heads = setmetatable({}, { __mode = "k" })
SB.books, SB.heads = books, heads

function SB.Book(f)
    local b = f and f.SpellBookFrame
    return IsFrame(b) and b or nil
end

function SB.Paged(book)
    local p = book.PagedSpellsFrame
    return IsFrame(p) and p or nil
end

function SB.GlowOff(f)
    local b = SB.Book(f)
    return b ~= nil and Visible(b)
end

-- Die Schriftzeile einer Ueberschrift: ein Eintrag ohne .Button, erste
-- Schriftzeile mit Text (bis eine Ebene tiefer).
local function HeadText(entry)
    if IsFrame(entry.Button) then return nil end
    local t = entry.Text or entry.Title or entry.Name
    if IsFrame(t) and Kind(t) == "FontString" and TextOf(t) then return t end
    for _, r in ipairs(W.Regions(entry, "sbHead")) do
        if Kind(r) == "FontString" and Visible(r) and TextOf(r) then return r end
    end
    for _, ch in ipairs(W.Children(entry, "sbHead")) do
        if IsFrame(ch) and Kind(ch) ~= "Button" then
            for _, r in ipairs(W.Regions(ch, "sbHead", 1)) do
                if Kind(r) == "FontString" and Visible(r) and TextOf(r) then return r end
            end
        end
    end
    return nil
end

-- Raute und Linie hinter dem Text, die Linie bis vor den Rand der Seite.
local function Head(entry, fs, paged, accent)
    local h = heads[entry]
    if not h then
        if not entry.CreateTexture then return nil end
        h = { fs = fs }
        h.dot = S.Diamond(entry, 6, accent, 0.9, 2)
        h.hole = S.Diamond(entry, 2, C.surface1, 1, 3)
        h.hole:SetPoint("CENTER", h.dot, "CENTER", 0, 0)
        h.line = S.Own(entry:CreateTexture(nil, "ARTWORK", nil, 1))
        h.line:SetHeight(1)
        S.Fade(h.line, accent, SB.LINE, "RIGHT")
        heads[entry] = h
    end
    -- Die Liste verwendet ihre Eintraege weiter: neu legen, wenn Text oder
    -- Breite sich aendern.
    local ok, tw = pcall(fs.GetStringWidth, fs)
    tw = ok and K.Plain(tw) or nil
    tw = type(tw) == "number" and tw or 0
    if h.fs == fs and h.tw == tw and h.paged == paged then return h end
    h.fs, h.tw, h.paged = fs, tw, paged
    h.dot:ClearAllPoints()
    h.dot:SetPoint("CENTER", fs, "LEFT", tw + SB.GAP + 3, 0)
    h.line:ClearAllPoints()
    h.line:SetPoint("LEFT", h.dot, "CENTER", SB.GAP, 0)
    h.line:SetPoint("RIGHT", paged, "RIGHT", -SB.INSET, 0)
    return h
end

local function Show(b, on)
    if b.on == on then return end
    b.on = on
    for _, t in ipairs(b.parts) do t:SetShown(on) end
end

local function Build(f, book, paged)
    local b = { parts = {}, host = f }
    local v = S.Vignette(f, book, SB.VIGNETTE, SB.VIGNETTE_SIZE, -6)
    for _, side in ipairs(S.SIDES) do b.parts[#b.parts + 1] = v[side] end
    b.vignette = v
    local l = GC.atmosLight
    b.light = S.TopLight(f, book, l, l[4], SB.LIGHT_HEIGHT, -5)
    b.parts[#b.parts + 1] = b.light
    if paged then
        local c = GC.surfaceRaised
        b.body = S.SoftPanel(f, paged, c, c[4], SB.PAD, -4)
        b.shadow = S.Shadow(f, paged, SB.PAD + SB.SHADOW_PAD, -5)
        b.edge = S.Under(S.Divider(f, WHITE, SB.EDGE, 0), -3)
        S.PlaceTop(b.edge, paged, 12, SB.PAD)
        for _, t in ipairs({ b.body, b.shadow, b.edge.l, b.edge.r }) do b.parts[#b.parts + 1] = t end
    end
    books[book] = b
    if book.HookScript then
        book:HookScript("OnShow", function() Show(b, true) end)
        book:HookScript("OnHide", function() Show(b, false) end)
    end
    b.on = true
    return b
end

function SB.Update(f)
    local book = SB.Book(f)
    if not book then return nil end
    local b = books[book]
    if not Visible(book) then
        if b then Show(b, false) end
        return nil
    end
    S.Scope(book, SB.STYLE)
    local paged = SB.Paged(book)
    b = b or Build(f, book, paged)
    Show(b, true)
    b.heads = 0
    if paged then
        local accent = S.Accent(SB.STYLE.accent)
        -- Eine Seite (View1, gemessen) oder zwei nebeneinander (View2).
        for _, key in ipairs(SB.VIEWS) do
            local view = paged[key]
            if IsFrame(view) and Visible(view) then
                for _, entry in ipairs(W.Children(view, "sbView")) do
                    if IsFrame(entry) and Visible(entry) then
                        local fs = HeadText(entry)
                        if fs and Head(entry, fs, paged, accent) then b.heads = b.heads + 1 end
                    end
                end
            end
        end
    end
    return b
end

function SB.Report(f, out)
    local book = SB.Book(f)
    if not book or not Visible(book) then return out end
    local b = books[book]
    local names = ""
    local paged = SB.Paged(book)
    for _, key in ipairs(SB.VIEWS) do
        local view = paged and paged[key]
        if IsFrame(view) then
            for _, entry in ipairs(W.Children(view, "sbView")) do
                local h = heads[entry]
                if h and Visible(entry) then names = names .. (names == "" and "" or ", ") .. "„" .. (TextOf(h.fs) or "?") .. "“" end
            end
        end
    end
    out[#out + 1] = string.format("   %s (Stil %s): Seite %s, Fläche %s, Schein der Klasse %s",
        SB.LABEL, SB.STYLE.name, paged and "gefunden" or "FEHLT", (b and b.body) and "ja" or "nein",
        SB.GlowOff(f) and "aus" or "an")
    out[#out + 1] = string.format("   %s, Überschriften: %s", SB.LABEL, names ~= "" and names or "keine gefunden")
    return out
end
