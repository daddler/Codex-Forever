--------------------------------------------------
-- WeintCodex :: Oberflaeche - Bausteine fuer Fenster in Gold (6.10.0.0)
--------------------------------------------------
-- Handel (6.9.0.2), Bank (6.9.1.1) und Post (6.9.1.2) waren dreimal
-- derselbe Code: Fenster ablaufen, gemessene Bilder ausblenden, Knoepfe
-- flach, Felder als Leiste, Pergament als Innenflaeche, Ausgeblendetes
-- wieder zeigen, wenn die Region spaeter etwas anderes zeigt. Ein Fehler
-- darin waere dreimal zu beheben gewesen, und jedes neue Fenster haette
-- ihn ein viertes Mal kopiert.
--
-- Jetzt beschreibt ein Fenster nur noch, WAS es ist - eine Tabelle:
--
--   CP.New({
--       label = "Bank", host = "BankFrame", depth = 5,
--       files   = { [130718] = "slot", ... },          -- Bild -> Art
--       atlases = { { "^bank%-divider", "decor" }, ... },-- Muster -> Art
--       money   = { "SendMailMoneyBg" },                -- -> Innenflaeche
--       moneyOf = function(f) return f.Panel.Money end, -- oder ein Rahmen am Fenster
--       tabs    = { "MailFrameTab1", "MailFrameTab2" }, -- Reiter unten
--       after   = function(f, m, H) ... end,            -- was nur dieses Fenster hat
--       report  = function(f, m, H) return "..." end,   -- Zeile fuer /wcui fenster
--   })
--
-- Arten (was mit einem gemessenen Bild geschieht):
--   slot   weg, der Rahmen, dem es gehoert, flach mit 1 px Rand (Plaetze)
--   field  weg, der Rahmen eine flache Leiste mit 1 px Rand (Eingabefelder)
--   strip  weg, an seiner Stelle eine Leiste ohne Rand (Namensfelder)
--   bg     weg, an seiner Stelle eine Innenflaeche (Pergament, Leder) -
--          ui/calm.lua legt Schatten und Kante in Gold daran (W.Insets)
--   decor  weg (Trennleisten, Schatten, Symbole am Rahmen)
--
-- Regeln, die fuer jedes Fenster gelten - deshalb hier und nur hier:
--   * Symbol, Rand der Qualitaet und Ueberlagerung eines Gegenstands werden
--     nie angefasst, auch wenn sie (leer) dasselbe Bild tragen.
--   * Ausgeblendet ist ein Bild nur, solange es eines der gemessenen ist;
--     zeigt die Region spaeter etwas anderes, wird sie wieder sichtbar.
--   * Was schon ausgeblendet ist, wird im Takt nicht neu gesetzt.
--   * Innenflaechen des Spiels (InsetFrameTemplate: .Bg + .NineSlice)
--     werden ueberall Innenflaechen (W.OwnBackground).
--   * Geaendert werden nur Bilder - kein Skript, kein Feld.
-- Der Rahmen selbst (Metall, Marmor, Portraet, Seitenreiter, Knoepfe)
-- bleibt beim allgemeinen Durchlauf (W.WINDOWS), Licht und Kante in Gold
-- bei ui/calm.lua.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UICalmParts = {}

local CP = WeintCodex.UICalmParts
local K = WeintCodex.UIKit
local C = WeintCodex.Colors
local GC = WeintCodex.GameColors
local W = WeintCodex.UIWindows
local S = WeintCodex.UIStyle
local RG = WeintCodex.UIRegister

local IsFrame = RG.IsFrame

CP.FLAT_ALPHA = 0.9          -- Platz
CP.FIELD_ALPHA = 0.55        -- Eingabefeld
CP.STRIP_ALPHA = 0.55        -- Namensfeld
CP.SURFACE_ALPHA = 0.45      -- Innenflaeche an der Stelle des Pergaments
CP.EDGE = 0.5                -- Kante oben in Gold
CP.KINDS = { slot = true, field = true, strip = true, bg = true, decor = true }
-- Leer und geteilt: `x or {}` legte im Takt je Aufruf eine Tabelle an.
local NONE = {}

local function FileOf(r)
    if type(r) ~= "table" or not r.GetTexture then return nil end
    local ok, v = pcall(r.GetTexture, r)
    return ok and K.Plain(v) or nil
end
CP.FileOf = FileOf

local function AtlasOf(r)
    if type(r) ~= "table" or not r.GetAtlas then return nil end
    local ok, v = pcall(r.GetAtlas, r)
    v = ok and K.Plain(v) or nil
    return type(v) == "string" and v or nil
end
CP.AtlasOf = AtlasOf

-- Symbol, Qualitaet, Ueberlagerung? Dann nie anfassen.
local function IsIcon(owner, r)
    if r == owner.icon or r == owner.Icon or r == owner.IconTexture or r == owner.IconBorder
        or r == owner.IconOverlay then return true end
    local ok, name = pcall(r.GetName, r)
    name = ok and K.Plain(name) or nil
    return type(name) == "string" and name:find("IconTexture$") ~= nil
end
CP.IsIcon = IsIcon

-- Ein Rahmen flach: Grund und 1 px Rand, einmal. `store` merkt ihn.
local function Flat(store, b, alpha)
    if store[b] or not b.CreateTexture then return end
    local bg = b:CreateTexture(nil, "BACKGROUND", nil, -7)
    bg:SetAllPoints(b)
    local c = GC.plateBg
    bg:SetColorTexture(c[1], c[2], c[3], alpha)
    store[b] = { bg = bg, edge = K.Border(b, 1, 0, 0, 0, 1, "BORDER") }
end
CP.Flat = Flat

-- Eine Flaeche genau dort, wo das Bild lag (es traegt die Lage).
local function Patch(store, owner, r, color, alpha)
    if store[r] or not owner.CreateTexture then return nil end
    local t = owner:CreateTexture(nil, "BACKGROUND", nil, -8)
    t:SetAllPoints(r)
    t:SetColorTexture(color[1], color[2], color[3], alpha)
    store[r] = t
    return t
end

-- Eine Innenflaeche nie ueber das Fenster hinaus (6.10.4.2, gemessen
-- 05.10.2026): das Pergament des Posteingangs ist ein Bild von 512 x 512,
-- groesser als das Fenster - der Rest war durchsichtig, unsere Flaeche an
-- seiner Stelle nicht: ein dunkles Rechteck rechts und unten neben der Post.
-- Verankert bleibt sie am Bild; nur was ueber das Fenster ragt, wird
-- abgeschnitten. Abstaende statt Lage: beim Ziehen wandern beide mit.
local Edge = RG.Edge
local function Clamp(t, r, host)
    local rl, rr, rt, rb = Edge(r, "GetLeft"), Edge(r, "GetRight"), Edge(r, "GetTop"), Edge(r, "GetBottom")
    local hl, hr, ht, hb = Edge(host, "GetLeft"), Edge(host, "GetRight"), Edge(host, "GetTop"), Edge(host, "GetBottom")
    if not (rl and rr and rt and rb and hl and hr and ht and hb) then return end
    local l = math.floor(math.max(0, hl - rl) + 0.5)
    local rg = math.floor(math.min(0, hr - rr) - 0.5) + 1
    local tp = math.floor(math.min(0, ht - rt) - 0.5) + 1
    local bt = math.floor(math.max(0, hb - rb) + 0.5)
    if t.clampL == l and t.clampR == rg and t.clampT == tp and t.clampB == bt then return end
    t.clampL, t.clampR, t.clampT, t.clampB = l, rg, tp, bt
    t:ClearAllPoints()
    t:SetPoint("TOPLEFT", r, "TOPLEFT", l, tp)
    t:SetPoint("BOTTOMRIGHT", r, "BOTTOMRIGHT", rg, bt)
end
CP.Clamp = Clamp

-- Ein Fenster aus seiner Beschreibung. Liefert das Gastmodul fuer
-- W.HOSTED (Update, Report) samt seiner Tabellen fuer Pruefung und Bericht.
function CP.New(spec)
    assert(type(spec.host) == "string" and type(spec.label) == "string", "CalmParts: host und label")
    for _, kind in pairs(spec.files or {}) do assert(CP.KINDS[kind], "CalmParts: unbekannte Art " .. tostring(kind)) end
    for _, a in ipairs(spec.atlases or {}) do assert(CP.KINDS[a[2]], "CalmParts: unbekannte Art " .. tostring(a[2])) end

    local H = {
        LABEL = spec.label, HOST = spec.host, STYLE = spec.style or S.CALM,
        EDGE = spec.edge or CP.EDGE, DEPTH = spec.depth or 4,
        FILES = spec.files or {}, ATLASES = spec.atlases or {},
        frames = setmetatable({}, { __mode = "k" }),
        flat = setmetatable({}, { __mode = "k" }),      -- Platz -> { bg, edge }
        fields = setmetatable({}, { __mode = "k" }),    -- Eingabefeld -> { bg, edge }
        strips = setmetatable({}, { __mode = "k" }),    -- Namensfeld (Region) -> Leiste
        surfaces = setmetatable({}, { __mode = "k" }),  -- Pergament (Region) -> Flaeche
        hidden = setmetatable({}, { __mode = "k" }),    -- Region -> true
        spec = spec,
    }
    local tag = "calm:" .. spec.host

    local function Kind(r)
        local atlas = AtlasOf(r)
        if atlas then
            for _, a in ipairs(H.ATLASES) do
                if atlas:find(a[1]) then return a[2] end
            end
            return nil
        end
        local id = FileOf(r)
        return id and H.FILES[id] or nil
    end
    H.Kind = Kind

    local function Hide(r)
        if K.Plain(r:GetAlpha()) ~= 0 then r:SetAlpha(0) end
        H.hidden[r] = true
    end

    local function Release()
        for r in pairs(H.hidden) do
            if not Kind(r) then
                r:SetAlpha(1)
                H.hidden[r] = nil
            end
        end
    end

    local function Walk(f, depth, m)
        if depth > H.DEPTH or type(f) ~= "table" or (f.IsForbidden and f:IsForbidden()) then return end
        if depth > 0 and type(f.Bg) == "table" and type(f.NineSlice) == "table" then
            W.OwnBackground(f)
            m.insets = m.insets + 1
        end
        for _, r in ipairs(W.Regions(f, tag, depth)) do
            if not IsIcon(f, r) then
                local kind = Kind(r)
                if kind then
                    Hide(r)
                    if kind == "slot" then
                        Flat(H.flat, f, spec.flatAlpha or CP.FLAT_ALPHA)
                    elseif kind == "field" then
                        Flat(H.fields, f, spec.fieldAlpha or CP.FIELD_ALPHA)
                    elseif kind == "strip" then
                        Patch(H.strips, f, r, GC.plateBg, spec.stripAlpha or CP.STRIP_ALPHA)
                    elseif kind == "bg" then
                        Patch(H.surfaces, f, r, C.surface1, CP.SURFACE_ALPHA)
                        if H.surfaces[r] and m.root then Clamp(H.surfaces[r], r, m.root) end
                        W.Insets[f] = true
                        m.bg = m.bg + 1
                    end
                end
            end
        end
        for _, ch in ipairs(W.Children(f, tag, depth)) do Walk(ch, depth + 1, m) end
    end

    local function Tabs(f, m, accent)
        local selected = K.Plain(f.selectedTab)
        local n = 0
        for i, name in ipairs(spec.tabs or NONE) do
            local tab = _G[name]
            if IsFrame(tab) and tab.CreateTexture then
                local ok, id = pcall(tab.GetID, tab)
                id = ok and K.Plain(id) or i
                if type(id) ~= "number" or id == 0 then id = i end
                W.SkinTab(tab, accent, selected == id)
                n = n + 1
            end
        end
        m.tabs = n
    end

    function H.Update(f)
        local accent = S.Accent(H.STYLE.accent)
        local m = H.frames[f]
        if not m then
            m = { insets = 0, bg = 0, money = 0, tabs = 0 }
            m.edge = S.Under(S.Divider(f, accent, H.EDGE, 0), -3)
            S.PlaceTop(m.edge, f, 10, -1)
            H.frames[f] = m
        end
        -- Geld: Namen und ein Rahmen am Fenster (ohne neue Tabelle im Takt).
        local money = 0
        for _, key in ipairs(spec.money or NONE) do
            local part = _G[key]
            if IsFrame(part) then W.OwnBackground(part) money = money + 1 end
        end
        if spec.moneyOf then
            local part = spec.moneyOf(f)
            if IsFrame(part) then W.OwnBackground(part) money = money + 1 end
        end
        m.money = money
        m.root = f
        Release()
        m.insets, m.bg = 0, 0
        Walk(f, 0, m)
        if spec.tabs then Tabs(f, m, accent) end
        if spec.after then spec.after(f, m, H) end
        return m
    end

    function H.Report(f, out)
        local m = H.frames[f]
        if not m then return out end
        local line = spec.report and spec.report(f, m, H)
        if not line then
            local nf, nb, nh = 0, 0, 0
            for _ in pairs(H.flat) do nf = nf + 1 end
            for _ in pairs(H.fields) do nb = nb + 1 end
            for _ in pairs(H.hidden) do nh = nh + 1 end
            line = string.format("Plätze flach %d · Felder flach %d · Bilder weg %d · Innenflächen %d · Geld %d · Reiter %d",
                nf, nb, nh, m.insets + m.bg, m.money, m.tabs)
        end
        out[#out + 1] = string.format("   %s (Stil %s): Kante in Gold, kein Schein der Klasse · %s",
            H.LABEL, H.STYLE.name, line)
        return out
    end

    S.SCOPES[H.HOST] = H.STYLE
    W.HOSTED[H.HOST] = W.HOSTED[H.HOST] or {}
    table.insert(W.HOSTED[H.HOST], H)
    CP.hosts = CP.hosts or {}
    CP.hosts[H.HOST] = H
    return H
end

-- Fuer Pruefung und Bericht: alle Fenster, die aus Bausteinen bestehen.
CP.hosts = CP.hosts or {}
