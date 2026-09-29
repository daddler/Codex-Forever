--------------------------------------------------
-- WeintCodex :: Oberflaeche - Talente (6.8.0.3 - 6.8.0.5)
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
--              in der Klassenfarbe - wie im Zauberbuch. Seit 6.8.0.4 liegen
--              beide UEBER den Wolken und Landschaften (Ebene OVERLAY des
--              Talentfensters; die Talente selbst liegen in einem Kindrahmen
--              und damit darueber): darunter war das Licht im Spiel nicht zu
--              sehen. Deshalb auch kraeftiger als im Zauberbuch (TL.LIGHT_ALPHA
--              statt GC.classLight) - es faerbt Nebel, keine dunkle Flaeche.
--              Seit 6.8.0.5 additiv ("ADD"): auf hellgrauem Nebel war ein
--              deckender Hauch Klassenfarbe auch mit 16 % kaum zu sehen.
--   Baeume     die Namen der drei Baeume ("Waffen", "Furor", "Schutz")
--              bekommen Raute und Linie in der Klassenfarbe hinter dem Text
--              - wie die Ueberschriften im Zauberbuch. Seit 6.8.0.5 liegt die
--              Zeile (Symbol, Name, Linie) auf einem dunklen weichen Grund,
--              damit sie auf dem Nebel steht wie ein Abschnitt auf einer
--              Flaeche; die Linie ist kraeftiger (0.9 statt 0.55). Welche Zeile ein Name
--              ist, sagt das Spiel (GetTalentTabInfo, GetSpecializationInfo)
--              und, wo es schweigt, data/specs.lua fuer die eigene Klasse -
--              keine Lage. GEMESSEN (6.8.0.3): der Forever-Client liefert
--              ueber GetTalentTabInfo keine Namen ("Baeume keine gefunden").
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
TL.LIGHT_HEIGHT = 220
TL.LIGHT_ALPHA = 0.16       -- ueber Nebel: kraeftiger als GameColors.classLight auf dunkler Flaeche
TL.EDGE = 0.5               -- Kante oben in der Klassenfarbe
TL.GAP = 8                  -- Text -> Raute -> Linie
TL.LINE_WIDTH = 200         -- Linie hinter dem Namen eines Baums (laeuft aus)
TL.LINE = 0.9               -- ueber Nebel: 0.55 (Zauberbuch) war im Spiel nicht zu sehen (6.8.0.4)
TL.BACK = 0.6               -- dunkler weicher Grund unter der Zeile eines Baums (Anteil an shadowSoft)
TL.BACK_LEFT = 64           -- so weit links vom Namen: das Symbol des Baums liegt mit darauf
TL.BACK_HALF = 20           -- halbe Hoehe des Grunds
TL.SCANS = 30               -- so oft wird nach den Namen gesucht, bis alle da sind
TL.DEPTH = 6
TL.SAMPLE = 6              -- so viele Schriftzeilen nennt der Bericht, wenn kein Name passt

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

-- Die Namen der Baeume. Zuerst das Spiel: GetTalentTabInfo (je nach
-- Fassung (name, ...) oder (id, name, ...)) und GetSpecializationInfo
-- ((id, name, ...)) - beide ersten Werte, wenn sie Text sind. Dazu die
-- Baeume der eigenen Klasse aus data/specs.lua: dort stehen sie fest, und
-- der Forever-Client nennt sie nicht (gemessen 6.8.0.3). Einmal je Fenster.
-- Rueckgabe: Menge der Namen, Liste der Quellen fuer den Bericht.
local function Add(names, v)
    v = K.Plain(v)
    if type(v) == "string" and v ~= "" and not names[v] then names[v] = true return true end
    return false
end

local function FromClient(names, fn, n)
    local got = false
    for i = 1, n do
        local ok, a, b = pcall(fn, i)
        if ok then
            if Add(names, a) then got = true end
            if Add(names, b) then got = true end
        end
    end
    return got
end

function TL.Names()
    local names, from = {}, {}
    local n = 3
    if type(_G.GetNumTalentTabs) == "function" then
        local ok, v = pcall(_G.GetNumTalentTabs)
        v = ok and K.Plain(v) or nil
        if type(v) == "number" and v > 0 then n = v end
    end
    if type(_G.GetTalentTabInfo) == "function" and FromClient(names, _G.GetTalentTabInfo, n) then
        from[#from + 1] = "GetTalentTabInfo"
    end
    if type(_G.GetSpecializationInfo) == "function" and FromClient(names, _G.GetSpecializationInfo, n) then
        from[#from + 1] = "GetSpecializationInfo"
    end
    local Specs = WeintCodex.Specs
    if Specs and _G.UnitClass then
        local ok, _, token = pcall(_G.UnitClass, "player")
        token = ok and K.Plain(token) or nil
        local got = false
        for _, spec in ipairs(Specs.ForClass(token)) do
            if Add(names, spec.name) then got = true end
        end
        if got then from[#from + 1] = "data/specs.lua" end
    end
    return names, from
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
    -- Dunkler weicher Grund unter Symbol, Name und Linie - ganz unten in
    -- der Ebene der Raute, damit er ueber dem Nebel und unter dem Text liegt.
    local c = GC.shadowSoft
    h.back = S.SoftPanel(p, fs, c, TL.BACK, 0, -8, h.line)
    h.back:SetDrawLayer("ARTWORK", -8)
    h.back:ClearAllPoints()
    h.back:SetPoint("TOPLEFT", fs, "LEFT", -TL.BACK_LEFT, TL.BACK_HALF)
    h.back:SetPoint("BOTTOMRIGHT", h.line, "RIGHT", 0, -TL.BACK_HALF)
    h.parent = p
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
    t.light = S.Own(tf:CreateTexture(nil, "OVERLAY", nil, 6))
    t.light:SetPoint("TOPLEFT", tf, "TOPLEFT", 0, 0)
    t.light:SetPoint("TOPRIGHT", tf, "TOPRIGHT", 0, 0)
    t.light:SetHeight(TL.LIGHT_HEIGHT)
    S.Gradient(t.light, "VERTICAL", accent, 0, TL.LIGHT_ALPHA)
    if t.light.SetBlendMode then pcall(t.light.SetBlendMode, t.light, "ADD") end
    t.edge = S.Divider(tf, accent, TL.EDGE, 7)
    t.edge.l:SetDrawLayer("OVERLAY", 7)
    t.edge.r:SetDrawLayer("OVERLAY", 7)
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
    if not t.names then t.names, t.from = TL.Names() t.want = 0 end
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

-- Schriftzeilen mit Text, die kein Name sind (nur im Bericht, wenn keiner
-- passt): damit die naechste Messung sagt, wie die Baeume heissen.
local function Sample(f, depth, out)
    if not f or depth > TL.DEPTH or #out >= TL.SAMPLE then return end
    for _, r in ipairs(W.Regions(f, "tlSample", depth)) do
        if #out >= TL.SAMPLE then return end
        if Kind(r) == "FontString" and Visible(r) then
            local txt = TextOf(r)
            if txt and txt ~= "" and not tonumber(txt) then
                out[#out + 1] = "„" .. txt .. "“ (" .. K.NameOf(f) .. ")"
            end
        end
    end
    for _, ch in ipairs(W.Children(f, "tlSample", depth)) do
        if IsFrame(ch) then Sample(ch, depth + 1, out) end
    end
end

function TL.Report(f, out)
    local tf = TL.Talents(f)
    local t = tf and frames[tf]
    if not t or not Visible(tf) then return out end
    local names = ""
    for _, fs in ipairs(t.order) do
        names = names .. (names == "" and "" or ", ") .. "„" .. (TextOf(fs) or "?") .. "“"
    end
    local first = t.order[1] and t.marks[t.order[1]]
    out[#out + 1] = string.format("   %s (Stil %s): Bäume %s%s · Licht und Kante in der Klassenfarbe über den Wolken, Animation unberührt",
        TL.LABEL, TL.STYLE.name, names ~= "" and names or "keine gefunden",
        first and (" auf dunklem Grund (am Rahmen " .. K.NameOf(first.parent) .. ")") or "")
    if #t.order < (t.want or 0) or names == "" then
        local want = {}
        for n in pairs(t.names or {}) do want[#want + 1] = n end
        table.sort(want)
        out[#out + 1] = string.format("      gesucht: %s (aus %s)",
            #want > 0 and table.concat(want, ", ") or "nichts",
            (t.from and #t.from > 0) and table.concat(t.from, ", ") or "keiner Quelle")
        local seen = {}
        Sample(tf, 0, seen)
        out[#out + 1] = "      Schrift im Fenster: " .. (#seen > 0 and table.concat(seen, ", ") or "keine")
    end
    return out
end
