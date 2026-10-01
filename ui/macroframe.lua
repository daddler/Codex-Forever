--------------------------------------------------
-- WeintCodex :: Oberflaeche - Makrofenster (6.9.0.0)
--------------------------------------------------
-- Das Makrofenster des Spiels (/m, MacroFrame aus Blizzard_MacroUI, erst
-- beim ersten Oeffnen geladen) in der ruhigen Informationsoberflaeche.
-- Makros gehoeren nicht zur Klasse: GOLD (S.CALM), wie die Optionen.
-- Beta-Test 6.9.0.0: Metallrahmen, Marmor, Leder, Steinplaetze, rote
-- Knoepfe, Reiter des Spiels.
--
--   Huelle     Metallrahmen, Marmor, Streifen, Portraet weg (W.WINDOWS),
--              Kachel, kein Schein der Klasse, Licht und Kante in Gold.
--   Flaechen   die Makroliste (MacroFrameInset, Leder) und das Textfeld
--              (MacroFrameTextBackground, Rahmen des Tooltips) werden
--              Innenflaechen mit Kante in Gold (ui/calm.lua, LF.INSETS).
--   Plaetze    jeder Makroplatz und das gewaehlte Makro oben: der Stein
--              des Spiels (Bilder MF.SLOT_FILES) weg, statt dessen flach
--              mit 1 px Rand - wie die Aktionsknoepfe. Das Symbol eines
--              Makros und der Goldrahmen der Wahl bleiben.
--   Reiter     "Allgemeine Makros" / "Makros von <Name>" (MacroFrameTab1/2)
--              flach, der gewaehlte in Gold (W.SkinTab).
--   Knoepfe    Speichern, Abbrechen, Name/Symbol aendern, Loeschen, Neu,
--              Verlassen: flach wie im Spielmenue (W.SkinPanelButtons im
--              allgemeinen Durchlauf).
--
-- Unveraendert: Symbole, Text, Zeichenzaehler, Bildlaufleisten, das
-- Fenster zur Symbolwahl. Geaendert werden nur Bilder - kein Skript und
-- kein Feld am Fenster (Makros anlegen ist geschuetzt).
--
-- GEMESSEN (6.8.1.0, /wcui fenster): MacroFrame (Bild 374155),
-- MacroFrameInset (Bild 374154), MacroFrame.NineSlice ("UI-Frame-Metal-*",
-- "UI-Frame-PortraitMetal-*"), "_UI-Frame-TopTileStreaks", Plaetze mit den
-- Bildern 130764 und 130718 (je 19: 18 Plaetze und das gewaehlte Makro),
-- MacroFrameTextBackground.NineSlice ("Tooltip-NineSlice-*"),
-- MacroFrameTab1 ("uiframe-tab-*"), MacroEditButton.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIMacroFrame = {}

local MF = WeintCodex.UIMacroFrame
local K = WeintCodex.UIKit
local C = WeintCodex.Colors
local GC = WeintCodex.GameColors
local W = WeintCodex.UIWindows
local S = WeintCodex.UIStyle
local RG = WeintCodex.UIRegister

local IsFrame = RG.IsFrame

MF.LABEL = "Makros"
MF.HOST = "MacroFrame"
MF.STYLE = S.CALM
MF.EDGE = 0.5
MF.TABS = 2
MF.DEPTH = 7                -- Plaetze liegen in MacroSelector.ScrollBox.ScrollTarget
-- Der Stein unter jedem Platz (gemessen). Symbole haben andere Bilder.
MF.SLOT_FILES = { [130764] = true, [130718] = true }

MF.TAB_NAMES = {}
for i = 1, MF.TABS do MF.TAB_NAMES[i] = "MacroFrameTab" .. i end

S.SCOPES[MF.HOST] = MF.STYLE
W.HOSTED[MF.HOST] = W.HOSTED[MF.HOST] or {}
table.insert(W.HOSTED[MF.HOST], MF)

local frames = setmetatable({}, { __mode = "k" })
local slots = setmetatable({}, { __mode = "k" })    -- Platz -> { bg, edge }
MF.frames, MF.slots = frames, slots

local function FileOf(r)
    if type(r) ~= "table" or not r.GetTexture then return nil end
    local ok, v = pcall(r.GetTexture, r)
    return ok and K.Plain(v) or nil
end

-- Ein Platz: flacher Grund und 1 px Rand, einmal je Platz.
local function Flat(slot)
    if slots[slot] or not slot.CreateTexture then return end
    local bg = slot:CreateTexture(nil, "BACKGROUND", nil, -7)
    bg:SetAllPoints(slot)
    local c = GC.plateBg
    bg:SetColorTexture(c[1], c[2], c[3], 0.9)
    slots[slot] = { bg = bg, edge = K.Border(slot, 1, 0, 0, 0, 1, "BORDER") }
end

-- Alle Plaetze bis in die Tiefe (gepoolte Listen, nichts Neues im Takt).
local function Slots(f, depth, m)
    if depth > MF.DEPTH or type(f) ~= "table" or (f.IsForbidden and f:IsForbidden()) then return end
    for _, r in ipairs(W.Regions(f, "macroSlot", depth)) do
        local id = FileOf(r)
        if id and MF.SLOT_FILES[id] then
            if K.Plain(r:GetAlpha()) ~= 0 then W.Hide(r) end
            Flat(f)
            m.seen = m.seen + 1
        end
    end
    for _, ch in ipairs(W.Children(f, "macroSlot", depth)) do Slots(ch, depth + 1, m) end
end

local function Tabs(f, m, accent)
    local selected = K.Plain(f.selectedTab)
    local n = 0
    for i = 1, MF.TABS do
        local tab = _G[MF.TAB_NAMES[i]]
        if IsFrame(tab) and tab.CreateTexture then
            W.SkinTab(tab, accent, selected == i)
            n = n + 1
        end
    end
    m.tabs = n
end

function MF.Update(f)
    local accent = S.Accent(MF.STYLE.accent)
    local m = frames[f]
    if not m then
        m = { tabs = 0, seen = 0 }
        m.edge = S.Under(S.Divider(f, accent, MF.EDGE, 0), -3)
        S.PlaceTop(m.edge, f, 10, -1)
        frames[f] = m
    end
    m.seen = 0
    Slots(f, 0, m)
    Tabs(f, m, accent)
    return m
end

function MF.Report(f, out)
    local m = frames[f]
    if not m then return out end
    local n = 0
    for _ in pairs(slots) do n = n + 1 end
    out[#out + 1] = string.format("   %s (Stil %s): Kante in Gold, kein Schein der Klasse · Plätze flach %d · Reiter %d",
        MF.LABEL, MF.STYLE.name, n, m.tabs or 0)
    return out
end
