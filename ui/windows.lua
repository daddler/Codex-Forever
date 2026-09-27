--------------------------------------------------
-- WeintCodex :: Oberflaeche - Fenster des Spiels
--------------------------------------------------
-- Das Charakterfenster (Taste C) mit seinen Reitern Ruf, Fertigkeiten,
-- PvP und Abzeichen im Stil der Oberflaeche (Beta-Test: "auch hier soll
-- das neue Design Einheit gebieten"): Kachel statt Holz und Metall, ohne
-- das runde Portraet, der Titel in unserer Schrift.
--
-- ERSTE STUFE (6.3.1.6) WAR NUR DIE HUELLE; die zweite (6.3.1.7, unten)
-- blendet im Inneren aus, was /wcui fenster im Beta-Test benannt hat.
-- Urspruenglich: Wie die Fenster dieses Clients
-- innen aufgebaut sind, hat niemand gemessen. Ausgeblendet werden deshalb
-- nur Teile, die in der Fenstervorlage des Spiels Schmuck sind
-- (NineSlice, Bg, Inset, Portraet) - nie Inhalte: Plaetze, Balken,
-- Listen und Modell bleiben unberuehrt. Was danach noch nach Holz
-- aussieht, nennt /wcui fenster (Maus ueber das Fenster).
--
-- 6.4.1.2: auch das Zauberbuch (Beta-Test: "auch hier soll das UI
-- einheitlich mit WeintCodex sein"). Wie es im Forever-Client heisst und
-- aufgebaut ist, hat niemand gemessen - der Screenshot sieht anders aus
-- als das Zauberbuch im Quelltext des Spiels. Deshalb dieselbe Vorsicht:
-- beide Namen des Spiels (PlayerSpellsFrame, SpellBookFrame), die Atlanten
-- des Quelltexts als Muster, und was allgemein gilt, allgemein: dunkle
-- Schrift fuer Pergament wird auf der dunklen Kachel hell, Zaubersymbole
-- bekommen den eckigen Rand der Aktionsleisten. Was danach noch nach
-- Pergament aussieht, nennt /wcui fenster.
--
-- Nur Aussehen, nur Deckkraft: nichts wird versteckt, umgehaengt oder
-- verschoben. Die Einstellung liegt beim Modul "general" (Seite
-- "Fenster"), wie der Tooltip - die Seitenleiste ist voll.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIWindows = {}

local W = WeintCodex.UIWindows
local K = WeintCodex.UIKit
local C = WeintCodex.Colors

W.DEFAULTS = {
    windowSkin = true,
    -- 6.4.1.4: Talent-Landschaften gedaempft statt weg, Schein in der
    -- Klassenfarbe oben in jedem Fenster ("nur schwarz ist langweilig").
    windowArt  = true,
}

local function Opt(k) return K.Get("general", k) end

-- Fenster und ihre Teilfenster. Was der Client nicht kennt, faellt heraus.
W.WINDOWS = { "CharacterFrame", "PVPFrame", "HonorFrame", "PlayerSpellsFrame", "SpellBookFrame",
              "PlayerTalentFrame", "TalentFrame", "ClassTalentFrame" }

-- Zauberbuch und Talente (6.4.1.3): ihre Hintergruende heissen im
-- Forever-Client anders als im Quelltext des Spiels (Beta-Test 6.4.1.2:
-- das Pergament blieb). Dort werden deshalb zusaetzlich GROSSE Bilder
-- ausgeblendet - erkannt an der Flaeche, nicht am Namen: Pergament,
-- Buchseiten, die Landschaften hinter den Talentbaeumen. Symbole, Pfeile,
-- Reiter und Knoepfe sind klein und bleiben. Gefunden werden die Fenster
-- auch ueber ihren Namen, wenn der nicht in der Liste steht (Haken auf
-- ShowUIPanel).
local LARGE_PATTERNS = { "Spell", "Talent" }
function W.WantsLarge(name)
    if type(name) ~= "string" then return false end
    for _, pat in ipairs(LARGE_PATTERNS) do
        if name:find(pat, 1, true) then return true end
    end
    return false
end
W.LARGE_SHARE = 0.15   -- ab diesem Anteil an der Fensterflaeche ist ein Bild Hintergrund
W.PANELS  = { "PaperDollFrame", "ReputationFrame", "SkillFrame", "TokenFrame", "PVPFrame", "HonorFrame",
              "CharacterStatsPane" }

-- Schmuck in der Fenstervorlage des Spiels, als Schluessel am Rahmen.
local DECOR = { "NineSlice", "Bg", "Background", "TopTileStreaks", "Inset", "InsetBg",
                "PortraitContainer", "PortraitFrame", "PortraitButton", "portrait", "TitleBg", "TopBorder" }

local done = {}
W.done = done
local own = setmetatable({}, { __mode = "k" })   -- unsere eigenen Flaechen
W.own = own

-- Was die zweite Stufe tut, fuer /wcui fenster (6.3.1.8: im Beta-Test
-- blieb 6.3.1.7 ohne sichtbare Wirkung, und ohne Zahlen ist nicht zu
-- unterscheiden, ob sie nicht lief, nichts fand oder das Spiel die
-- Deckkraft zuruecksetzt).
local stats = { runs = 0, hidden = 0, stuck = 0, last = nil, err = nil }
W.stats = stats

local function Hide(r)
    if type(r) ~= "table" or not r.SetAlpha or (r.IsForbidden and r:IsForbidden()) then return end
    local AB = WeintCodex.UIActionBars
    if AB and AB.KeepHidden then AB.KeepHidden(r) else r:SetAlpha(0) end
    if K.Plain(r:GetAlpha()) ~= 0 then stats.stuck = stats.stuck + 1 end
end

-- Alle Texturen direkt an einem Rahmen (nicht an seinen Kindern).
local function HideOwnTextures(f)
    if type(f) ~= "table" or not f.GetRegions then return end
    local ok, regions = pcall(function() return { f:GetRegions() } end)
    for _, r in ipairs(ok and regions or {}) do
        local tok, isTex = pcall(function() return r:GetObjectType() == "Texture" end)
        if tok and isTex then Hide(r) end
    end
end

-- Ein Schmuckteil: ist es ein Rahmen, seine Texturen (und die seiner
-- NineSlice); ist es eine Textur, sie selbst.
local function HideDecor(part)
    if type(part) ~= "table" then return end
    local ok, kind = pcall(function() return part:GetObjectType() end)
    if not ok then return end
    if kind == "Texture" then
        Hide(part)
    else
        HideOwnTextures(part)
        if type(part.NineSlice) == "table" then HideOwnTextures(part.NineSlice) end
        if type(part.Bg) == "table" then Hide(part.Bg) end
        if type(part.portrait) == "table" then Hide(part.portrait) end
    end
end

-- Portraet-Rahmen ganz ausblenden, nicht nur ihre Texturen: im
-- Talentfenster blieb das runde Symbol oben links stehen (Beta-Test
-- 6.4.1.4) - es liegt tiefer als eine Textur des Rahmens.
local WHOLE = { PortraitContainer = true, PortraitFrame = true, PortraitButton = true }

local function HideDecorOf(f)
    for _, key in ipairs(DECOR) do
        HideDecor(f[key])
        if WHOLE[key] and type(f[key]) == "table" and f[key].GetObjectType then Hide(f[key]) end
    end
    local name = f.GetName and f:GetName()
    if type(name) == "string" then
        for _, suffix in ipairs({ "Bg", "Inset", "InsetRight", "InsetLeft", "Portrait", "TitleBg" }) do
            HideDecor(_G[name .. suffix])
        end
    end
end

local function StyleTitle(f)
    local title = (type(f.TitleContainer) == "table" and f.TitleContainer.TitleText) or f.TitleText
        or (f.GetName and f:GetName() and _G[f:GetName() .. "TitleText"])
    if type(title) == "table" and title.SetTextColor then
        K.SetFont(title, 13)
        title:SetTextColor(unpack(C.textBright))
    end
end

-- Ein Fenster: Schmuck weg, eine Kachel darunter, Titel in unserer
-- Schrift. `panel` = Teilfenster in einem anderen Fenster: keine eigene
-- Kachel, nur der Schmuck weg.
function W.Skin(f, panel)
    if type(f) ~= "table" or done[f] or (f.IsForbidden and f:IsForbidden()) then return done[f] end
    local d = {}
    done[f] = d
    HideDecorOf(f)
    if not panel then
        HideOwnTextures(f)
        d.kachel = K.Kachel(f, { alpha = 0.94, shadow = 8 })
        own[d.kachel.bg], own[d.kachel.light] = true, true
        if d.kachel.shadow and d.kachel.shadow.tex then own[d.kachel.shadow.tex] = true end
        W.AddGlow(f, d)
        StyleTitle(f)
    end
    -- Innenflaechen (Inset): etwas heller als die Kachel, damit Spalten
    -- lesbar getrennt bleiben.
    for _, key in ipairs({ "Inset", "InsetRight", "InsetLeft" }) do
        local inset = f[key]
        if type(inset) ~= "table" and f.GetName and f:GetName() then inset = _G[f:GetName() .. key] end
        if type(inset) == "table" and inset.CreateTexture and not d[key] then
            local t = inset:CreateTexture(nil, "BACKGROUND", nil, -8)
            t:SetAllPoints(inset)
            local s = C.surface1
            t:SetColorTexture(s[1], s[2], s[3], 0.45)
            own[t] = true
            d[key] = t
        end
    end
    return d
end

--------------------------------------------------
-- Zweite Stufe: das Innere, nach Namen (6.3.1.7)
--------------------------------------------------
-- /wcui fenster im Beta-Test nannte, was im Charakterfenster nach Holz
-- und Stein aussieht - alles Atlanten des Spiels mit sprechenden Namen.
-- Ausgeblendet wird genau das, jeweils als Muster (Klassenhintergrund:
-- "UI-Character-Info-Warrior-BG" gibt es je Klasse). Der Hintergrund der
-- Modellszene (RaceBG) bleibt: er ist die Buehne des Modells, kein Rahmen.
W.HIDE_ATLAS = {
    "^UI%-Character%-Info%-General%-BG",     -- linke Haelfte
    "^UI%-Character%-Info%-Stat%-BG",        -- rechte Haelfte
    "^UI%-Character%-Info%-Stat%-StoneBG",
    "^UI%-Character%-Info%-%a+%-BG$",        -- Klassenhintergrund der Werte
    "^UI%-Character%-Info%-Title",           -- Holzbalken "Allgemein" usw.
    "^UI%-Character%-Info%-Line%-Bounce",    -- Streifen hinter den Werten
    "^UI%-Character%-Info%-GearSlot",        -- Metallrahmen der Plaetze
    "^UI%-Character%-Info%-Divider",
    "^UI%-Character%-Info%-ScrollLine",      -- Linien ueber/unter Listen
    "^common%-insideframe",
    "^common%-framedivider",                 -- senkrechte Trennlinie
    "^common%-stat%-bar%-BG",                -- Rahmen der Ruf-/Fertigkeitsbalken
    "^common%-sidetab",                      -- Goldrahmen der Reiter rechts
    -- Zauberbuch (Blizzard_PlayerSpells, Quelltext des Spiels 12.x):
    "^spellbook%-background",                -- Pergament, Buchseiten, Band
    "^spellbook%-corner",                    -- Eselsohr zum Blaettern
    "^spellbook%-divider",
    "^spellbook%-list%-backplate",
    "^spellbook%-item%-backplate",           -- Schatten hinter jedem Zauber
    "^UI%-HUD%-RotationHelper%-SpellbookDivider",
    -- Gemessen im Beta-Client mit /wcui fenster (6.4.1.3): Goldschmuck.
    "^spellbook%-Tab%-Frame%-C60$",          -- Goldrahmen der Kategorie-Reiter (der Schein bleibt: er zeigt die Wahl)
    "^Talents%-Main%-Ring",                  -- Goldring um die Spezialisierungen
    "^Talents%-divider",                     -- Goldlinien links/rechts
    "^Talents%-small%-divider",
    "^Talents%-Square%-Box",                 -- Goldkasten "Unverteilte Talentpunkte"
}
local KEEP_ATLAS = { "RaceBG" }

function W.HidesAtlas(atlas)
    if type(atlas) ~= "string" then return false end
    for _, k in ipairs(KEEP_ATLAS) do
        if atlas:find(k, 1, true) then return false end
    end
    for _, pat in ipairs(W.HIDE_ATLAS) do
        if atlas:find(pat) then return true end
    end
    return false
end

-- Alle Texturen mit einem dieser Atlanten, bis in die Tiefe. Zeilen einer
-- Liste legt das Spiel beim Blaettern neu an - deshalb laeuft das bei
-- jedem Zeigen und, solange das Fenster offen ist, zweimal je Sekunde.
-- Balken in Ruf und Fertigkeiten: statt des Rahmens des Spiels ein
-- flacher Grund mit 1 px Rand, wie jeder Balken der Oberflaeche.
local barDone = {}
local function FlatBar(bar)
    if type(bar) ~= "table" or barDone[bar] or not bar.CreateTexture then return end
    barDone[bar] = true
    local bg = bar:CreateTexture(nil, "BACKGROUND", nil, -8)
    bg:SetAllPoints(bar)
    local c = WeintCodex.GameColors.plateBg
    bg:SetColorTexture(c[1], c[2], c[3], 1)
    K.Border(bar, 1, 0, 0, 0, 1, "OVERLAY")
end

local seen = setmetatable({}, { __mode = "k" })
local function HideByAtlas(f, depth)
    if depth > 8 or type(f) ~= "table" or (f.IsForbidden and f:IsForbidden()) then return end
    local rok, regions = pcall(function() return { f:GetRegions() } end)
    for _, r in ipairs(rok and regions or {}) do
        local ok, atlas = pcall(function()
            if r:GetObjectType() ~= "Texture" then return nil end
            return r.GetAtlas and r:GetAtlas()
        end)
        if ok and W.HidesAtlas(atlas) then
            Hide(r)
            if not seen[r] then
                seen[r] = true
                stats.hidden = stats.hidden + 1
            end
            if atlas:find("^common%-stat%-bar%-BG") then FlatBar(f) end
        end
    end
    local cok, kids = pcall(function() return { f:GetChildren() } end)
    for _, ch in ipairs(cok and kids or {}) do HideByAtlas(ch, depth + 1) end
end
W.HideByAtlas = function(f) HideByAtlas(f, 0) end

-- Ausruestungsplaetze: flach wie die Aktionsknoepfe, 1 px schwarzer Rand.
-- Erkannt am Namen (Character...Slot), nicht an einer Liste: welche Plaetze
-- es gibt, sagt der Client.
local slotDone = {}
local function SkinSlots(f)
    local ok, kids = pcall(function() return { f:GetChildren() } end)
    for _, ch in ipairs(ok and kids or {}) do
        local n = type(ch) == "table" and ch.GetName and ch:GetName()
        if type(n) == "string" and n:find("^Character[%a%d]+Slot$") and not slotDone[ch] then
            slotDone[ch] = true
            local normal = ch.GetNormalTexture and ch:GetNormalTexture()
            if type(normal) == "table" then Hide(normal) end
            K.Border(ch, 1, 0, 0, 0, 1, "OVERLAY")
        end
        if type(ch) == "table" then SkinSlots(ch) end
    end
end
W.SkinSlots = SkinSlots

-- Die Reiter rechts am Charakterfenster (CharacterFrameModeTab1..):
-- eine kleine Kachel statt des Goldrahmens, der gewaehlte mit Rand im
-- Akzent, unter der Maus heller.
local tabDone = {}
local function SkinModeTabs()
    for i = 1, 10 do
        local tab = _G["CharacterFrameModeTab" .. i]
        if type(tab) == "table" and not (tab.IsForbidden and tab:IsForbidden()) then
            local d = tabDone[tab]
            if not d then
                d = { kachel = K.Kachel(tab, { shadow = 3 }) }
                local hl = tab:CreateTexture(nil, "HIGHLIGHT")
                hl:SetAllPoints(tab)
                local h = WeintCodex.GameColors.hoverFill
                hl:SetColorTexture(h[1], h[2], h[3], h[4])
                tabDone[tab] = d
            end
            local sel = tab.SelectedTexture
            local on = type(sel) == "table" and sel.IsShown and K.Bool(sel:IsShown(), false)
            local c = on and C.accent or { 0, 0, 0 }
            d.kachel.border:SetColor(c[1], c[2], c[3], 1)
        end
    end
end
W.SkinModeTabs = SkinModeTabs

-- Schrift fuer Pergament (dunkelbraun, SPELLBOOK_FONT_COLOR) ist auf der
-- dunklen Kachel unlesbar. Jede dunkle Schriftzeile im Fenster wird hell;
-- setzt das Spiel sie wieder dunkel, zieht ein Haken nach. Helle und
-- farbige Schrift (Gold, Gruen, Rot) bleibt, wie sie ist - sie traegt
-- Bedeutung.
local function IsDark(r, g, b)
    r, g, b = K.Plain(r), K.Plain(g), K.Plain(b)
    if type(r) ~= "number" or type(g) ~= "number" or type(b) ~= "number" then return false end
    return (0.299 * r + 0.587 * g + 0.114 * b) < 0.4
end
W.IsDark = IsDark

local lit = setmetatable({}, { __mode = "k" })
local litGuard = false
local function Lighten(fs)
    if lit[fs] then return end
    local ok, r, g, b = pcall(fs.GetTextColor, fs)
    if not ok or not IsDark(r, g, b) then return end
    lit[fs] = true
    local c = C.textNormal
    litGuard = true
    fs:SetTextColor(c[1], c[2], c[3])
    litGuard = false
    if _G.hooksecurefunc then
        _G.hooksecurefunc(fs, "SetTextColor", function(self, nr, ng, nb)
            if litGuard or not IsDark(nr, ng, nb) then return end
            litGuard = true
            self:SetTextColor(c[1], c[2], c[3])
            litGuard = false
        end)
    end
end

local function LightenText(f, depth)
    if depth > 10 or type(f) ~= "table" or (f.IsForbidden and f:IsForbidden()) then return end
    local rok, regions = pcall(function() return { f:GetRegions() } end)
    for _, r in ipairs(rok and regions or {}) do
        local ok, isText = pcall(function() return r:GetObjectType() == "FontString" end)
        if ok and isText then Lighten(r) end
    end
    local cok, kids = pcall(function() return { f:GetChildren() } end)
    for _, ch in ipairs(cok and kids or {}) do LightenText(ch, depth + 1) end
end
W.LightenText = function(f) LightenText(f, 0) end

-- Zaubersymbole im Zauberbuch (SpellBookItemTemplate: Button mit Icon,
-- Border und IconMask): Zierrahmen weg, Maske ab (Passive waren rund),
-- 1 px schwarzer Rand wie auf den Aktionsleisten. Erkannt an diesen drei
-- Teilen, nicht an einem Namen - die Eintraege legt das Spiel beim
-- Blaettern neu an.
local spellDone = setmetatable({}, { __mode = "k" })
local function SkinSpellButton(b)
    if spellDone[b] then return end
    spellDone[b] = true
    Hide(b.Border)
    local icon = b.Icon
    if type(b.IconMask) == "table" and icon.RemoveMaskTexture then pcall(icon.RemoveMaskTexture, icon, b.IconMask) end
    if icon.SetTexCoord then icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) end
    local border = K.Border(b, 1, 0, 0, 0, 1, "OVERLAY")
    if border.top and border.top.SetDrawLayer then
        for _, t in ipairs({ border.top, border.bottom, border.left, border.right }) do
            t:ClearAllPoints()
        end
        -- Rand am Bild, nicht am Knopf: der Knopf ist groesser als das Bild.
        border.top:SetPoint("BOTTOMLEFT", icon, "TOPLEFT", -1, 0)
        border.top:SetPoint("BOTTOMRIGHT", icon, "TOPRIGHT", 1, 0)
        border.top:SetHeight(1)
        border.bottom:SetPoint("TOPLEFT", icon, "BOTTOMLEFT", -1, 0)
        border.bottom:SetPoint("TOPRIGHT", icon, "BOTTOMRIGHT", 1, 0)
        border.bottom:SetHeight(1)
        border.left:SetPoint("TOPRIGHT", icon, "TOPLEFT", 0, 0)
        border.left:SetPoint("BOTTOMRIGHT", icon, "BOTTOMLEFT", 0, 0)
        border.left:SetWidth(1)
        border.right:SetPoint("TOPLEFT", icon, "TOPRIGHT", 0, 0)
        border.right:SetPoint("BOTTOMLEFT", icon, "BOTTOMRIGHT", 0, 0)
        border.right:SetWidth(1)
    end
end

local function SkinSpellItems(f, depth)
    if depth > 10 or type(f) ~= "table" or (f.IsForbidden and f:IsForbidden()) then return end
    local b = f.Button
    if type(b) == "table" and type(b.Icon) == "table" and type(b.Border) == "table" and b.Icon.SetTexCoord then
        pcall(SkinSpellButton, b)
    end
    local cok, kids = pcall(function() return { f:GetChildren() } end)
    for _, ch in ipairs(cok and kids or {}) do SkinSpellItems(ch, depth + 1) end
end
W.SkinSpellItems = function(f) SkinSpellItems(f, 0) end

-- Grosse Bilder im Fenster (siehe LARGE_PATTERNS). Nur sichtbare, nur
-- Texturen, nie unsere eigenen.
-- Ein Bild des Spiels gedaempft statt ausgeblendet: entsaettigt, dunkler,
-- halb durchsichtig - Stimmung ohne Konkurrenz zur Schrift. Setzt das
-- Spiel die Deckkraft neu, zieht ein Haken nach.
local toned = setmetatable({}, { __mode = "k" })
local toneGuard = false
local function Tone(r)
    if toned[r] then return end
    toned[r] = true
    local t = WeintCodex.GameColors.artTone
    if r.SetDesaturation then pcall(r.SetDesaturation, r, 0.6)
    elseif r.SetDesaturated then pcall(r.SetDesaturated, r, true) end
    if r.SetVertexColor then r:SetVertexColor(t[1], t[2], t[3]) end
    toneGuard = true
    r:SetAlpha(t[4])
    toneGuard = false
    if _G.hooksecurefunc then
        _G.hooksecurefunc(r, "SetAlpha", function(self)
            if toneGuard then return end
            toneGuard = true
            self:SetAlpha(t[4])
            toneGuard = false
        end)
    end
end
W.toned = toned

local function HideLarge(f, limit, depth, toneRoot, tone)
    if depth > 10 or type(f) ~= "table" or (f.IsForbidden and f:IsForbidden()) then return end
    tone = tone or (toneRoot ~= nil and f == toneRoot)
    local rok, regions = pcall(function() return { f:GetRegions() } end)
    for _, r in ipairs(rok and regions or {}) do
        if not own[r] and not toned[r] then
            local ok, big = pcall(function()
                if r:GetObjectType() ~= "Texture" then return false end
                if not K.Bool(r:IsShown(), false) or K.Plain(r:GetAlpha()) == 0 then return false end
                local w, h = K.Plain(r:GetWidth()), K.Plain(r:GetHeight())
                return type(w) == "number" and type(h) == "number" and w * h >= limit
            end)
            if ok and big then
                if tone then Tone(r) else Hide(r) end
                if not seen[r] then
                    seen[r] = true
                    stats.hidden = stats.hidden + 1
                end
            end
        end
    end
    local cok, kids = pcall(function() return { f:GetChildren() } end)
    for _, ch in ipairs(cok and kids or {}) do HideLarge(ch, limit, depth + 1, toneRoot, tone) end
end
-- Pergament des Zauberbuchs: weg (entsaettigt waere es graues Papier).
-- Landschaften hinter den Talentbaeumen: gedaempft, wenn windowArt an ist.
function W.HideLarge(f)
    local w, h = K.Plain(f:GetWidth()), K.Plain(f:GetHeight())
    if type(w) ~= "number" or type(h) ~= "number" or w * h <= 0 then return end
    local toneRoot
    if Opt("windowArt") then
        local name = f.GetName and f:GetName()
        if type(f.TalentsFrame) == "table" then toneRoot = f.TalentsFrame
        elseif type(name) == "string" and name:find("Talent", 1, true) then toneRoot = f end
    end
    HideLarge(f, w * h * W.LARGE_SHARE, 0, toneRoot, false)
end

-- Schein in der Klassenfarbe oben im Fenster, nach unten auslaufend: das
-- Fenster gehoert dem Charakter. Die Farbe nennt das Spiel
-- (RAID_CLASS_COLORS); ohne Antwort bleibt der Schein aus.
local function ClassRGB()
    local _, class = nil, nil
    if _G.UnitClass then _, class = _G.UnitClass("player") end
    class = K.Plain(class)
    local cc = type(class) == "string" and _G.RAID_CLASS_COLORS and _G.RAID_CLASS_COLORS[class]
    if type(cc) ~= "table" then return nil end
    return cc.r, cc.g, cc.b
end

function W.AddGlow(f, d)
    if d.glow or not Opt("windowArt") or not f.CreateTexture then return end
    local r, g, b = ClassRGB()
    if not r then return end
    local a = WeintCodex.GameColors.windowGlow[4]
    local t = f:CreateTexture(nil, "BACKGROUND", nil, -6)
    t:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
    t:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -1)
    t:SetHeight(260)
    t:SetColorTexture(1, 1, 1, 1)
    if t.SetGradient and _G.CreateColor then
        t:SetGradient("VERTICAL", _G.CreateColor(r, g, b, 0), _G.CreateColor(r, g, b, a))
    else
        t:SetColorTexture(r, g, b, a * 0.4)
    end
    own[t] = true
    d.glow = t
end

--------------------------------------------------
-- Dritte Stufe: Bedienelemente (6.4.1.5)
--------------------------------------------------
-- Was neben der Kachel noch nach Gold aussah (Beta-Test 6.4.1.4): Reiter
-- ("Primaer/Sekundaer"), Knoepfe ("Aenderungen anwenden"), die gelben
-- Pfeilknoepfe und die roten Schliessen-Knoepfe.

-- Rot und Gelb des Spiels an Knoepfen werden grau: die Form bleibt, die
-- Bedeutung (schliessen, aufklappen) auch.
local DESAT_ATLAS = { "^[Rr]ed[Bb]utton%-", "^common%-dropdown%-a%-button" }
local desat = setmetatable({}, { __mode = "k" })
function W.Desaturates(atlas)
    if type(atlas) ~= "string" then return false end
    for _, pat in ipairs(DESAT_ATLAS) do
        if atlas:find(pat) then return true end
    end
    return false
end

local function Grey(f, depth)
    if depth > 10 or type(f) ~= "table" or (f.IsForbidden and f:IsForbidden()) then return end
    local rok, regions = pcall(function() return { f:GetRegions() } end)
    for _, r in ipairs(rok and regions or {}) do
        if not desat[r] then
            local ok, atlas = pcall(function()
                if r:GetObjectType() ~= "Texture" then return nil end
                return r.GetAtlas and r:GetAtlas()
            end)
            if ok and W.Desaturates(K.Plain(atlas)) and r.SetDesaturated then
                desat[r] = true
                r:SetDesaturated(true)
            end
        end
    end
    local cok, kids = pcall(function() return { f:GetChildren() } end)
    for _, ch in ipairs(cok and kids or {}) do Grey(ch, depth + 1) end
end
W.Grey = function(f) Grey(f, 0) end

-- Reiter einer Reiterleiste (TabSystem des Spiels: .tabs, jeder mit
-- Left/Middle/Right, *Active und *Highlight): eine kleine Kachel, der
-- gewaehlte mit Rand im Akzent - wie die Reiter am Charakterfenster.
local TAB_PARTS = { "Left", "Middle", "Right", "LeftActive", "MiddleActive", "RightActive",
                    "LeftHighlight", "MiddleHighlight", "RightHighlight" }
local tabSkin = setmetatable({}, { __mode = "k" })
-- Reiter mit Bild statt Text (Kategorien im Zauberbuch des Forever-
-- Clients, Beta-Test 6.4.1.5: die Bilder stiessen aneinander, der
-- gewaehlte trug Goldschein UND unseren Rand). Das Bild ist die
-- groesste Textur ohne Atlas; ihr Rahmen und Schein des Spiels
-- (spellbook-Tab-Frame-*) gehen, ein Rand INNEN am Bild trennt die
-- Nachbarn und zeigt die Wahl.
local function TabIcon(tab)
    local best, area = nil, 0
    local ok, regions = pcall(function() return { tab:GetRegions() } end)
    for _, r in ipairs(ok and regions or {}) do
        local tok, a = pcall(function()
            if r:GetObjectType() ~= "Texture" then return 0 end
            local atlas = K.Plain(r.GetAtlas and r:GetAtlas())
            if type(atlas) == "string" and atlas ~= "" then return 0 end
            if type(K.Plain(r:GetTexture())) ~= "number" then return 0 end
            local w, h = K.Plain(r:GetWidth()), K.Plain(r:GetHeight())
            if type(w) ~= "number" or type(h) ~= "number" then return 0 end
            return w * h
        end)
        if tok and a > area then best, area = r, a end
    end
    return best
end
W.TabIcon = TabIcon

local function InnerRim(host, region)
    local r = {}
    for _, side in ipairs({ "top", "bottom", "left", "right" }) do
        local t = host:CreateTexture(nil, "OVERLAY", nil, 7)
        own[t] = true
        r[side] = t
    end
    function r:Set(width, c)
        self.top:ClearAllPoints()
        self.top:SetPoint("TOPLEFT", region, "TOPLEFT", 0, 0)
        self.top:SetPoint("TOPRIGHT", region, "TOPRIGHT", 0, 0)
        self.top:SetHeight(width)
        self.bottom:ClearAllPoints()
        self.bottom:SetPoint("BOTTOMLEFT", region, "BOTTOMLEFT", 0, 0)
        self.bottom:SetPoint("BOTTOMRIGHT", region, "BOTTOMRIGHT", 0, 0)
        self.bottom:SetHeight(width)
        self.left:ClearAllPoints()
        self.left:SetPoint("TOPLEFT", region, "TOPLEFT", 0, 0)
        self.left:SetPoint("BOTTOMLEFT", region, "BOTTOMLEFT", 0, 0)
        self.left:SetWidth(width)
        self.right:ClearAllPoints()
        self.right:SetPoint("TOPRIGHT", region, "TOPRIGHT", 0, 0)
        self.right:SetPoint("BOTTOMRIGHT", region, "BOTTOMRIGHT", 0, 0)
        self.right:SetWidth(width)
        for _, t in ipairs({ self.top, self.bottom, self.left, self.right }) do
            t:SetColorTexture(c[1], c[2], c[3], 1)
        end
    end
    return r
end

local function HideTabArt(tab)
    local ok, regions = pcall(function() return { tab:GetRegions() } end)
    for _, r in ipairs(ok and regions or {}) do
        local aok, atlas = pcall(function() return K.Plain(r.GetAtlas and r:GetAtlas()) end)
        if aok and type(atlas) == "string" and atlas:find("^spellbook%-Tab%-Frame") then Hide(r) end
    end
end

local function SkinTab(tab)
    local d = tabSkin[tab]
    if not d then
        for _, k in ipairs(TAB_PARTS) do Hide(tab[k]) end
        local icon = TabIcon(tab)
        if icon then
            HideTabArt(tab)
            if icon.SetTexCoord then icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) end
            d = { icon = icon, rim = InnerRim(tab, icon) }
        else
            d = { kachel = K.Kachel(tab, { shadow = 0 }) }
            own[d.kachel.bg], own[d.kachel.light] = true, true
            -- Eine Stufe heller als die Fensterkachel, sonst verschwindet er darin.
            local s1 = C.surface1
            d.kachel.bg:SetColorTexture(s1[1], s1[2], s1[3], 0.95)
        end
        local hl = tab:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints(d.icon or tab)
        local h = WeintCodex.GameColors.hoverFill
        hl:SetColorTexture(h[1], h[2], h[3], h[4] * 0.5)
        own[hl] = true
        tabSkin[tab] = d
    end
    if d.icon then HideTabArt(tab) end   -- Schein des Spiels kommt beim Wechsel wieder
    local on = tab.isSelected
    if type(tab.IsSelected) == "function" then
        local ok, v = pcall(tab.IsSelected, tab)
        if ok and type(v) ~= "nil" then on = v end
    end
    on = K.Bool(on, false)
    local c = on and C.accent or { 0, 0, 0 }
    if d.rim then
        if d.sel ~= on then
            d.sel = on
            d.rim:Set(on and 2 or 1, c)
        end
    else
        d.kachel.border:SetColor(c[1], c[2], c[3], 1)
    end
end
W.TabSkin = tabSkin

local function SkinTabSystems(f, depth)
    if depth > 8 or type(f) ~= "table" or (f.IsForbidden and f:IsForbidden()) then return end
    if type(f.tabs) == "table" and type(f.AddTab) == "function" then
        for _, tab in ipairs(f.tabs) do
            if type(tab) == "table" and tab.CreateTexture then pcall(SkinTab, tab) end
        end
    end
    local cok, kids = pcall(function() return { f:GetChildren() } end)
    for _, ch in ipairs(cok and kids or {}) do SkinTabSystems(ch, depth + 1) end
end
W.SkinTabSystems = function(f) SkinTabSystems(f, 0) end

-- Knoepfe der Vorlage UIPanelButtonTemplate (Left/Middle/Right, Text):
-- flache Kachel, heller unter der Maus. Zustaende (gedrueckt, gesperrt)
-- tauschen die Bilder des Spiels - die bleiben unsichtbar, der Text zeigt
-- den gesperrten Zustand weiter grau.
local btnSkin = setmetatable({}, { __mode = "k" })
local function SkinPanelButton(b)
    if btnSkin[b] then return end
    btnSkin[b] = true
    for _, k in ipairs({ "Left", "Middle", "Right" }) do Hide(b[k]) end
    local hl = b.GetHighlightTexture and b:GetHighlightTexture()
    if type(hl) == "table" then Hide(hl) end
    local d = K.Kachel(b, { shadow = 0 })
    own[d.bg], own[d.light] = true, true
    local s1 = C.surface1
    d.bg:SetColorTexture(s1[1], s1[2], s1[3], 0.95)
    local mine = b:CreateTexture(nil, "HIGHLIGHT")
    mine:SetAllPoints(b)
    local h = WeintCodex.GameColors.hoverFill
    mine:SetColorTexture(h[1], h[2], h[3], h[4] * 0.5)
    own[mine] = true
end

local function SkinPanelButtons(f, depth)
    if depth > 10 or type(f) ~= "table" or (f.IsForbidden and f:IsForbidden()) then return end
    local ok, isButton = pcall(function() return f:GetObjectType() == "Button" end)
    if ok and isButton and type(f.Left) == "table" and type(f.Middle) == "table" and type(f.Right) == "table"
       and not (type(f.LeftActive) == "table") and f.CreateTexture then
        pcall(SkinPanelButton, f)
    end
    local cok, kids = pcall(function() return { f:GetChildren() } end)
    for _, ch in ipairs(cok and kids or {}) do SkinPanelButtons(ch, depth + 1) end
end
W.SkinPanelButtons = function(f) SkinPanelButtons(f, 0) end

-- Werte im Charakterfenster: Name links, Zahl rechts. Blizzard laesst den
-- Namen frei laufen - "Bewegungsgeschwindigkeit" lief in "125%" hinein
-- (Beta-Test 6.4.1.4). Der Name endet jetzt vor der Zahl und wird dort
-- gekuerzt. Erkannt an Label und Value, nicht an einer Liste.
local statDone = setmetatable({}, { __mode = "k" })
local function FitStats(f, depth)
    if depth > 8 or type(f) ~= "table" or (f.IsForbidden and f:IsForbidden()) then return end
    local label, value = f.Label, f.Value
    if not statDone[f] and type(label) == "table" and type(value) == "table"
       and label.SetPoint and value.GetObjectType then
        statDone[f] = true
        pcall(function()
            label:SetPoint("RIGHT", value, "LEFT", -6, 0)
            if label.SetWordWrap then label:SetWordWrap(false) end
            if label.SetJustifyH then label:SetJustifyH("LEFT") end
        end)
    end
    local cok, kids = pcall(function() return { f:GetChildren() } end)
    for _, ch in ipairs(cok and kids or {}) do FitStats(ch, depth + 1) end
end
W.FitStats = function(f) FitStats(f, 0) end

function W.Inner()
    stats.runs = stats.runs + 1
    stats.last = _G.GetTime and K.Plain(_G.GetTime()) or nil
    for _, n in ipairs(W.WINDOWS) do
        local f = _G[n]
        if type(f) == "table" and done[f] then
            HideByAtlas(f, 0)
            SkinSlots(f)
            Grey(f, 0)
            SkinTabSystems(f, 0)
            SkinPanelButtons(f, 0)
            if n == "CharacterFrame" then FitStats(f, 0) end
            if W.WantsLarge(n) then
                SkinSpellItems(f, 0)
                LightenText(f, 0)
                W.HideLarge(f)
            end
        end
    end
    SkinModeTabs()
end

function W.Status()
    local now = _G.GetTime and K.Plain(_G.GetTime()) or nil
    local ago = (type(now) == "number" and type(stats.last) == "number") and string.format("vor %d s", now - stats.last) or "nie"
    return string.format("Fenster-Stil %s · innen: %d Läufe (zuletzt %s), %d Bilder ausgeblendet, %d ohne Wirkung%s",
        Opt("windowSkin") and "an" or "aus", stats.runs, ago, stats.hidden, stats.stuck,
        stats.err and (" · Fehler: " .. tostring(stats.err)) or "")
end

function W.Apply()
    if not Opt("windowSkin") then return end
    for _, n in ipairs(W.WINDOWS) do
        local f = _G[n]
        -- Ein Teilfenster eines schon gestalteten Fensters bekommt keine
        -- zweite Kachel.
        local parent = type(f) == "table" and f.GetParent and f:GetParent()
        W.Skin(f, parent and done[parent] and true or false)
    end
    for _, n in ipairs(W.PANELS) do
        local f = _G[n]
        if type(f) == "table" and not done[f] then W.Skin(f, true) end
    end
    W.Inner()
end

-- Die Fenster legt das Spiel beim Anmelden an; manche Teilfenster erst
-- beim ersten Oeffnen, das Zauberbuch erst beim ersten Druecken von P
-- (Blizzard_PlayerSpells laedt bei Bedarf). Deshalb: beim Anmelden, bei
-- jedem nachgeladenen Teil des Spiels und bei jedem Zeigen eines Fensters.
local hookedWin = {}
local function Run(fn)
    local ok, err = pcall(fn)
    if not ok then stats.err = err K.Report("fenster", err) end
end

local function HookWindow(f)
    if type(f) ~= "table" or hookedWin[f] or not f.HookScript or (f.IsForbidden and f:IsForbidden()) then return end
    hookedWin[f] = true
    f:HookScript("OnShow", function() Run(W.Apply) end)
    -- Solange es offen ist: neue Zeilen (Blaettern, Reiterwechsel)
    -- zweimal je Sekunde nachziehen. Geschlossen laeuft nichts.
    -- Ein eigener Kindrahmen, kein Skript am Fenster des Spiels: er
    -- laeuft nur, solange das Fenster sichtbar ist.
    local watch = CreateFrame("Frame", nil, f)
    local acc = 0
    watch:SetScript("OnUpdate", function(_, elapsed)
        acc = acc + (elapsed or 0)
        if acc < 0.5 then return end
        acc = 0
        Run(W.Inner)
    end)
end

function W.HookAll()
    for _, n in ipairs(W.WINDOWS) do HookWindow(_G[n]) end
end

-- Ein Fenster des Spiels, das in keiner Liste steht, aber nach Zauberbuch
-- oder Talenten heisst: aufnehmen, gestalten, beobachten.
function W.Adopt(f)
    if type(f) ~= "table" or (f.IsForbidden and f:IsForbidden()) or not f.GetName then return false end
    local ok, name = pcall(f.GetName, f)
    if not ok or not W.WantsLarge(name) then return false end
    local known = false
    for _, n in ipairs(W.WINDOWS) do if n == name then known = true break end end
    if not known then W.WINDOWS[#W.WINDOWS + 1] = name end
    HookWindow(f)
    Run(W.Apply)
    return true
end

if _G.hooksecurefunc and type(_G.ShowUIPanel) == "function" then
    _G.hooksecurefunc("ShowUIPanel", function(f)
        if not K.UIEnabled() or not Opt("windowSkin") then return end
        W.Adopt(f)
    end)
end

local boot = CreateFrame("Frame")
boot:RegisterEvent("PLAYER_LOGIN")
boot:RegisterEvent("ADDON_LOADED")
boot:SetScript("OnEvent", function(_, event, name)
    if not K.UIEnabled() or not Opt("windowSkin") then return end
    if event == "ADDON_LOADED" and not (type(name) == "string" and name:find("^Blizzard_")) then return end
    -- Vor dem Anmelden gibt es nichts zu gestalten; PLAYER_LOGIN kommt noch.
    if event == "ADDON_LOADED" and not (_G.IsLoggedIn and K.Bool(_G.IsLoggedIn(), false)) then return end
    Run(W.Apply)
    W.HookAll()
end)
