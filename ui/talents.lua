--------------------------------------------------
-- WeintCodex :: Oberflaeche - Talente (6.8.0.3)
--------------------------------------------------
-- Die Talente (PlayerSpellsFrame.TalentsFrame) in der ruhigen
-- Informationsoberflaeche. Sie gehoeren zur Klasse: Stil
-- S.CHARACTER_INFO, Akzent die Klassenfarbe - wie das Zauberbuch daneben.
--
--   BLEIBT     die Animation (talents-animations-clouds/-particles) und die
--              Landschaften der Baeume (talent-background-<Klasse>, seit
--              6.4.1.2 gedaempft) - Beta-Test: "Die Animation bei dem
--              Talentbaum soll so bleiben". Nichts davon wird angefasst.
--   Grund      statt des grossen Scheins der Klasse (W.AddGlow) ein Hauch
--              Licht in der Klassenfarbe von oben und oben eine feine Kante
--              in der Klassenfarbe - wie im Zauberbuch. Beides liegt AUF dem
--              Talentfenster (unter dem Fenster waere es von den
--              Landschaften verdeckt), ueber dessen Grund.
--   Baeume     die Namen der drei Baeume ("Waffen", "Furor", "Schutz")
--              bekommen Raute und Linie in der Klassenfarbe hinter dem Text
--              - wie die Ueberschriften im Zauberbuch. Welche Zeile ein Name
--              ist, sagt das Spiel (GetTalentTabInfo), nicht eine Liste und
--              keine Lage.
--
-- Unveraendert: Talente (Rahmen gruen/gelb/grau/gesperrt - sie sagen etwas),
-- Pfeile, Symbole der Baeume, Punkte je Baum, "Unverteilte Talentpunkte",
-- Primaer/Sekundaer, Suche, "Aenderungen anwenden".
--
-- GEMESSEN (6.8.0.0, /wcui fenster): PlayerSpellsFrame.TalentsFrame mit
-- talents-animations-clouds (2x), talent-background-warrior (3x),
-- talents-animations-particles (2x), Talents-Background-c60,
-- Talents-inner-frame-c60; .ButtonsParent mit den Talenten
-- (talents-node-square-shadow/-locked/-gray/-green/-yellow, talents-sheen-node,
-- talents-arrow-head-locked).
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UITalents = {}

local TL = WeintCodex.UITalents
local K = WeintCodex.UIKit
local C = WeintCodex.Colors
local GC = WeintCodex.GameColors
local W = WeintCodex.UIWindows
local S = WeintCodex.UIStyle
local RG = WeintCodex.UIRegister

local Visible, Kind, IsFrame, TextOf = RG.Visible, RG.Kind, RG.IsFrame, RG.TextOf

TL.LABEL = "Talente"
TL.HOST = "PlayerSpellsFrame"
TL.STYLE = S.CHARACTER_INFO
TL.LIGHT_HEIGHT = 180
TL.EDGE = 0.5               -- Kante oben in der Klassenfarbe
TL.GAP = 8                  -- Text -> Raute -> Linie
TL.LINE_WIDTH = 140         -- Linie hinter dem Namen eines Baums (laeuft aus)
TL.LINE = 0.55
TL.SCANS = 30               -- so oft wird nach den Namen gesucht, bis alle da sind
TL.DEPTH = 4

S.SCOPES["PlayerSpellsFrame.TalentsFrame"] = TL.STYLE
W.HOSTED[TL.HOST] = W.HOSTED[TL.HOST] or {}
table.insert(W.HOSTED[TL.HOST], TL)

local frames = setmetatable({}, { __mode = "k" })
TL.frames = frames

function TL.Talents(f)
    local t = f and f.TalentsFrame
    return IsFrame(t) and t or nil
end

function TL.GlowOff(f)
    local t = TL.Talents(f)
    return t ~= nil and Visible(t)
end

-- Die Namen der Baeume, wie das Spiel sie nennt. GetTalentTabInfo gibt je
-- nach Fassung (name, ...) oder (id, name, ...) zurueck: beide ersten
-- Werte, wenn sie Text sind. Einmal je Fenster.
function TL.Names()
    local names = {}
    if type(_G.GetTalentTabInfo) ~= "function" then return names end
    local n = 3
    if type(_G.GetNumTalentTabs) == "function" then
        local ok, v = pcall(_G.GetNumTalentTabs)
        v = ok and K.Plain(v) or nil
        if type(v) == "number" and v > 0 then n = v end
    end
    for i = 1, n do
        local ok, a, b = pcall(_G.GetTalentTabInfo, i)
        if ok then
            a, b = K.Plain(a), K.Plain(b)
            if type(a) == "string" and a ~= "" then names[a] = true end
            if type(b) == "string" and b ~= "" then names[b] = true end
        end
    end
    return names
end

-- Schriftzeilen unter `f`, deren Text ein Name ist.
local function Find(t, f, depth)
    if not f or depth > TL.DEPTH then return end
    for _, r in ipairs(W.Regions(f, "tlFind", depth)) do
        if Kind(r) == "FontString" and not t.heads[r] then
            local txt = TextOf(r)
            if txt and t.names[txt] then
                t.heads[r] = true
                t.order[#t.order + 1] = r
            end
        end
    end
    for _, ch in ipairs(W.Children(f, "tlFind", depth)) do
        if IsFrame(ch) then Find(t, ch, depth + 1) end
    end
end

local function Head(fs, accent)
    local ok, p = pcall(fs.GetParent, fs)
    if not ok or not IsFrame(p) or not p.CreateTexture then return nil end
    local h = { fs = fs }
    h.dot = S.Diamond(p, 6, accent, 0.9, 2)
    h.hole = S.Diamond(p, 2, C.surface1, 1, 3)
    h.hole:SetPoint("CENTER", h.dot, "CENTER", 0, 0)
    h.line = S.Own(p:CreateTexture(nil, "ARTWORK", nil, 1))
    h.line:SetHeight(1)
    h.line:SetWidth(TL.LINE_WIDTH)
    S.Fade(h.line, accent, TL.LINE, "RIGHT")
    -- Nur links verankert (6.7.8.0: nie an einen Rahmen anderer Hoehe).
    h.line:SetPoint("LEFT", h.dot, "CENTER", TL.GAP, 0)
    return h
end

local function Place(h)
    local ok, tw = pcall(h.fs.GetStringWidth, h.fs)
    tw = ok and K.Plain(tw) or nil
    tw = type(tw) == "number" and tw or 0
    if h.tw == tw then return end
    h.tw = tw
    h.dot:ClearAllPoints()
    h.dot:SetPoint("CENTER", h.fs, "LEFT", tw + TL.GAP + 3, 0)
end

local function Build(tf)
    local accent = S.Accent(TL.STYLE.accent)
    local t = { heads = {}, order = {}, marks = {}, scans = 0 }
    t.light = S.Own(tf:CreateTexture(nil, "BORDER", nil, 7))
    t.light:SetPoint("TOPLEFT", tf, "TOPLEFT", 0, 0)
    t.light:SetPoint("TOPRIGHT", tf, "TOPRIGHT", 0, 0)
    t.light:SetHeight(TL.LIGHT_HEIGHT)
    S.Gradient(t.light, "VERTICAL", accent, 0, GC.classLight[4])
    t.edge = S.Divider(tf, accent, TL.EDGE, 7)
    S.PlaceTop(t.edge, tf, 12, -1)
    t.parts = { t.light, t.edge.l, t.edge.r }
    t.on = true
    frames[tf] = t
    return t
end

local function Show(t, on)
    if t.on == on then return end
    t.on = on
    for _, x in ipairs(t.parts) do x:SetShown(on) end
end

function TL.Update(f)
    local tf = TL.Talents(f)
    if not tf then return nil end
    local t = frames[tf]
    if not Visible(tf) then
        if t then Show(t, false) end
        return nil
    end
    S.Scope(tf, TL.STYLE)
    t = t or Build(tf)
    Show(t, true)
    -- Namen suchen, bis alle gefunden sind (hoechstens TL.SCANS Mal: ein
    -- Name, der nie auftaucht, kostet sonst jeden Durchlauf eine Suche).
    if not t.names then t.names, t.want = TL.Names(), 0 end
    if t.want == 0 then for _ in pairs(t.names) do t.want = t.want + 1 end end
    if #t.order < t.want and t.scans < TL.SCANS then
        t.scans = t.scans + 1
        Find(t, tf, 0)
    end
    local accent = S.Accent(TL.STYLE.accent)
    for _, fs in ipairs(t.order) do
        local h = t.marks[fs]
        if not h then
            h = Head(fs, accent)
            t.marks[fs] = h or false
        end
        if h then Place(h) end
    end
    return t
end

function TL.Report(f, out)
    local tf = TL.Talents(f)
    local t = tf and frames[tf]
    if not t or not Visible(tf) then return out end
    local names = ""
    for _, fs in ipairs(t.order) do
        names = names .. (names == "" and "" or ", ") .. "„" .. (TextOf(fs) or "?") .. "“"
    end
    out[#out + 1] = string.format("   %s (Stil %s): Bäume %s · Licht und Kante in der Klassenfarbe, Animation unberührt",
        TL.LABEL, TL.STYLE.name, names ~= "" and names or "keine gefunden")
    return out
end
