--------------------------------------------------
-- WeintCodex :: Komfort - Ringe (6.40.0.0)
--------------------------------------------------
-- Ringmenues auf einer Taste, nach dem Verhalten von OPie ("All rights
-- reserved" - kein Code, keine Bilder uebernommen):
--   * Taste halten: der Ring erscheint um den Mauszeiger; Maus in eine
--     Richtung, Taste loslassen - das Ziel in dieser Richtung wird benutzt.
--     Loslassen in der Mitte tut nichts.
--   * oder "Klicken": Taste oeffnet/schliesst, ein Klick auf ein Symbol
--     benutzt es.
-- Vier Ringe sind dabei (ohne Taste - die legst du fest): Reittiere,
-- Reisen (Ruhestein, Teleporte, Portale), Markierungen, Berufe. Jeder
-- laesst sich in einen eigenen Ring umwandeln; eigene Ringe nehmen Zauber,
-- Gegenstaende, Reittiere und Makros - hineinziehen aus Zauberbuch, Tasche
-- oder Reittiersammlung, oder Name/ID/Makrotext eintippen.
--
-- SICHER: benutzt wird ueber sichere Knoepfe. Der Ring ist ein sicherer
-- Rahmen (SecureHandler); Zeigen, Waehlen und Benutzen laufen in seinem
-- geschuetzten Schnipsel - auch im Kampf. Was in einem Ring steht, kann
-- sich nur ausserhalb des Kampfes aendern; Aenderungen im Kampf warten.
-- Die Richtung waehlt der Schnipsel ohne Winkelrechnung: je Platz eine
-- Richtung (Einheitsvektor), gewaehlt wird der mit dem groessten
-- Skalarprodukt.
--
-- HERKUNFT der festen IDs (Reisen, Berufe): Classic, Art `classic` - im
-- Ring steht nur, was der Client als gelernt/vorhanden meldet.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIRings = {}

local RG = WeintCodex.UIRings
local K  = WeintCodex.UIKit
local C  = WeintCodex.Colors
local KEY = "comfort"

RG.MAX = 12             -- Plaetze je Ring
RG.RINGS = 8            -- Ringe hoechstens
RG.SLOT = 38
RG.RADIUS = 78
RG.DEAD = 22            -- Mitte: so nah am Zentrum waehlt nichts

-- Feste Ringe. Reisen und Berufe: Classic-IDs, gezeigt nur, was gelernt
-- (IsPlayerSpell) oder in der Tasche ist.
RG.HEARTH_ITEMS = { 6948 }                         -- Ruhestein
RG.TRAVEL_SPELLS = {
    556,                                           -- Astraler Rueckruf
    18960,                                         -- Teleportieren: Mondlichtung
    3561, 3562, 3565, 3567, 3563, 3566,            -- Magier: Teleportieren
    10059, 11416, 11419, 11417, 11418, 11420,      -- Magier: Portale
}
-- Je Beruf alle Raenge, der hoechste gelernte zaehlt.
RG.PROFESSIONS = {
    { 2259, 3101, 3464, 11611 },    -- Alchemie
    { 2018, 3100, 3538, 9785 },     -- Schmiedekunst
    { 7411, 7412, 7413, 13920 },    -- Verzauberkunst
    { 13262 },                      -- Entzaubern
    { 4036, 4037, 4038, 12656 },    -- Ingenieurskunst
    { 2108, 3104, 3811, 10662 },    -- Lederverarbeitung
    { 3908, 3909, 3910, 12180 },    -- Schneiderei
    { 2656 },                       -- Verhuetten
    { 2550, 3102, 3413, 18260 },    -- Kochkunst
    { 3273, 3274, 7924, 10846 },    -- Erste Hilfe
    { 7620, 7731, 7732, 18248 },    -- Angeln
    { 2383 },                       -- Kraeutersuche
    { 2580 },                       -- Mineraliensuche
}
RG.MARK_NAMES = { "Stern", "Kreis", "Diamant", "Dreieck", "Mond", "Quadrat", "Kreuz", "Totenkopf" }

RG.PRESETS = {
    { value = "custom",  text = "Eigener Ring" },
    { value = "mounts",  text = "Reittiere" },
    { value = "travel",  text = "Reisen (Ruhestein, Teleporte)" },
    { value = "marks",   text = "Markierungen" },
    { value = "prof",    text = "Berufe" },
}
-- Bedingungen je Eintrag: Makrobedingungen des Spiels, geprueft beim
-- Oeffnen (auch im Kampf). Eigene gehen als Text ("[combat,group]").
RG.CONDS = {
    { value = "",            text = "Immer" },
    { value = "[combat]",    text = "Nur im Kampf" },
    { value = "[nocombat]",  text = "Nur außerhalb des Kampfes" },
    { value = "[outdoors]",  text = "Nur im Freien" },
    { value = "[indoors]",   text = "Nur drinnen" },
    { value = "[mounted]",   text = "Nur beritten" },
    { value = "[nomounted]", text = "Nicht beritten" },
    { value = "[swimming]",  text = "Beim Schwimmen" },
    { value = "[group]",     text = "In einer Gruppe" },
    { value = "[nogroup]",   text = "Allein" },
    { value = "[exists]",    text = "Mit Ziel" },
    { value = "[harm]",      text = "Ziel feindlich" },
    { value = "[help]",      text = "Ziel freundlich" },
    { value = "[mod:shift]", text = "Mit Umschalt gedrückt" },
}

RG.MODES = {
    { value = "hold",  text = "Halten, zielen, loslassen" },
    { value = "click", text = "Drücken öffnet, Klick benutzt" },
}

local function Default()
    return {
        { name = "Reittiere",    preset = "mounts", mode = "hold" },
        { name = "Reisen",       preset = "travel", mode = "hold" },
        { name = "Markierungen", preset = "marks",  mode = "hold" },
        { name = "Berufe",       preset = "prof",   mode = "hold" },
    }
end

function RG.Active() return K.IsActive(KEY) and K.Get(KEY, "rings") ~= false end

-- Die Ringe dieses Profils (beim ersten Mal die vier festen).
function RG.List()
    local list = K.Get(KEY, "ringList")
    if type(list) ~= "table" then
        -- K.Set speichert eine Kopie: danach die gespeicherte holen, damit
        -- Aenderungen an der Liste auch dort landen.
        K.Set(KEY, "ringList", Default())
        list = K.Get(KEY, "ringList")
    end
    return list
end

local function Changed()
    K.Fire("setting", KEY, "ringList")
    RG.Schedule()
end
RG.Changed = Changed

--------------------------------------------------
-- Eintraege: was der Client kennt
--------------------------------------------------

local function SpellInfo(v)
    local cs = _G.C_Spell
    if cs and cs.GetSpellInfo then
        local ok, info = pcall(cs.GetSpellInfo, v)
        if ok and type(info) == "table" then
            return K.Plain(info.name), K.Plain(info.iconID or info.originalIconID), K.Plain(info.spellID)
        end
        return nil
    end
    if _G.GetSpellInfo then
        local ok, name, _, icon, _, _, _, id = pcall(_G.GetSpellInfo, v)
        if ok and name then return K.Plain(name), K.Plain(icon), K.Plain(id) end
    end
    return nil
end
RG.SpellInfo = SpellInfo

local function Known(id)
    local f = _G.IsPlayerSpell or _G.IsSpellKnown
    if not f then return false end
    local ok, v = pcall(f, id)
    return ok and K.Bool(v, false) or false
end

local function ItemInfo(id)
    local ci = _G.C_Item
    local name
    local f = (ci and ci.GetItemNameByID) or _G.GetItemInfo
    if f then local ok, n = pcall(f, id) name = ok and K.Plain(n) or nil end
    local icon
    local g = (ci and ci.GetItemIconByID) or _G.GetItemIcon
    if g then local ok, i = pcall(g, id) icon = ok and K.Plain(i) or nil end
    return name, icon
end

local function ItemCount(id)
    local ci = _G.C_Item
    local f = (ci and ci.GetItemCount) or _G.GetItemCount
    if not f then return nil end
    local ok, n = pcall(f, id)
    n = ok and K.Plain(n)
    return type(n) == "number" and n or nil
end

-- Ein Eintrag -> { type, spell|item|macrotext, icon, label, count } oder nil.
function RG.Resolve(e)
    if type(e) ~= "table" then return nil end
    if e.kind == "spell" then
        local name, icon, id = SpellInfo(e.value)
        if not name then return nil end
        return { type = "spell", spell = id or name, icon = icon, label = name }
    elseif e.kind == "item" then
        local id = tonumber(e.value)
        if not id then return nil end
        local name, icon = ItemInfo(id)
        return { type = "item", item = "item:" .. id, icon = icon, label = name or ("Gegenstand " .. id),
                 count = ItemCount(id) }
    elseif e.kind == "macro" then
        return { type = "macro", macrotext = e.value, icon = e.icon or 134400,
                 label = e.label or (type(e.value) == "string" and e.value:match("^[^\n]*") or "Makro") }
    elseif e.kind == "mark" then
        local n = tonumber(e.value) or 0
        return { type = "macro", macrotext = "/tm " .. n,
                 icon = n > 0 and ("Interface\\TargetingFrame\\UI-RaidTargetingIcon_" .. n) or "Interface\\Buttons\\UI-GroupLoot-Pass-Up",
                 label = n > 0 and RG.MARK_NAMES[n] or "Markierung entfernen" }
    end
    return nil
end

-- Reittiere: Sammlung des Spiels, sonst Reittier-Gegenstaende der Tasche.
function RG.Mounts()
    local out = {}
    local mj = _G.C_MountJournal
    if mj and mj.GetMountIDs and mj.GetMountInfoByID then
        local ok, ids = pcall(mj.GetMountIDs)
        for _, mid in ipairs(ok and type(ids) == "table" and ids or {}) do
            local ok2, name, spellID, icon, _, usable, _, _, _, _, hidden, collected = pcall(mj.GetMountInfoByID, mid)
            if ok2 and K.Bool(collected, false) and K.Bool(usable, false) and not K.Bool(hidden, false) then
                out[#out + 1] = { type = "spell", spell = K.Plain(spellID), icon = K.Plain(icon), label = K.Plain(name) }
                if #out >= RG.MAX then break end
            end
        end
    end
    if #out == 0 then
        local cc, ci = _G.C_Container, _G.C_Item
        local instant = (ci and ci.GetItemInfoInstant) or _G.GetItemInfoInstant
        if cc and cc.GetContainerNumSlots and instant then
            local seen = {}
            for bag = 0, tonumber(_G.NUM_BAG_SLOTS) or 4 do
                local okN, n = pcall(cc.GetContainerNumSlots, bag)
                for slot = 1, okN and type(K.Plain(n)) == "number" and K.Plain(n) or 0 do
                    local okI, id = pcall(cc.GetContainerItemID, bag, slot)
                    id = okI and K.Plain(id)
                    if type(id) == "number" and not seen[id] then
                        seen[id] = true
                        local ok, _, _, _, _, _, classID, subID = pcall(instant, id)
                        -- 15/5: Verschiedenes, Reittier
                        if ok and K.Plain(classID) == 15 and K.Plain(subID) == 5 then
                            local r = RG.Resolve({ kind = "item", value = id })
                            if r then out[#out + 1] = r end
                        end
                    end
                end
            end
        end
    end
    return out
end

function RG.Travel()
    local out = {}
    for _, id in ipairs(RG.HEARTH_ITEMS) do
        local n = ItemCount(id)
        if n and n > 0 then out[#out + 1] = RG.Resolve({ kind = "item", value = id }) end
    end
    for _, id in ipairs(RG.TRAVEL_SPELLS) do
        if Known(id) then
            local r = RG.Resolve({ kind = "spell", value = id })
            if r then out[#out + 1] = r end
        end
    end
    return out
end

function RG.Marks()
    local out = {}
    for n = 1, 8 do out[#out + 1] = RG.Resolve({ kind = "mark", value = n }) end
    out[#out + 1] = RG.Resolve({ kind = "mark", value = 0 })
    return out
end

function RG.Professions()
    local out = {}
    for _, ranks in ipairs(RG.PROFESSIONS) do
        for i = #ranks, 1, -1 do
            if Known(ranks[i]) then
                local r = RG.Resolve({ kind = "spell", value = ranks[i] })
                if r then out[#out + 1] = r end
                break
            end
        end
    end
    return out
end

-- Was ein Ring jetzt zeigt.
function RG.Slots(ring)
    local p = ring.preset
    local out
    if p == "mounts" then out = RG.Mounts()
    elseif p == "travel" then out = RG.Travel()
    elseif p == "marks" then out = RG.Marks()
    elseif p == "prof" then out = RG.Professions()
    else
        out = {}
        for _, e in ipairs(ring.entries or {}) do
            local r = RG.Resolve(e)
            if r then r.cond = e.cond out[#out + 1] = r end
        end
    end
    while #out > RG.MAX do table.remove(out) end
    return out
end

-- Fester Ring -> eigener Ring mit denselben Eintraegen (frei bearbeitbar).
function RG.Convert(ring)
    if not ring.preset or ring.preset == "custom" then return end
    local entries = {}
    for _, s in ipairs(RG.Slots(ring)) do
        if s.type == "spell" then entries[#entries + 1] = { kind = "spell", value = s.spell, cond = s.cond }
        elseif s.type == "item" then entries[#entries + 1] = { kind = "item", value = tonumber(s.item:match("%d+")), cond = s.cond }
        elseif s.type == "macro" then
            local n = s.macrotext:match("^/tm (%d+)$")
            if n then entries[#entries + 1] = { kind = "mark", value = tonumber(n) }
            else entries[#entries + 1] = { kind = "macro", value = s.macrotext, label = s.label } end
        end
    end
    ring.preset, ring.entries = "custom", entries
end

-- Eingetippt: "/..." Makro, sonst Zauber, sonst Gegenstand (Name oder ID).
function RG.Parse(text)
    if type(text) ~= "string" then return nil end
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    if text == "" then return nil end
    if text:sub(1, 1) == "/" then return { kind = "macro", value = text:gsub("\\n", "\n") } end
    local num = tonumber(text)
    local name, _, id = SpellInfo(num or text)
    if name and not (num and select(2, ItemInfo(num)) and not Known(num)) then
        return { kind = "spell", value = id or name }
    end
    local ci = _G.C_Item
    local instant = (ci and ci.GetItemInfoInstant) or _G.GetItemInfoInstant
    if instant then
        local ok, iid = pcall(instant, num or text)
        iid = ok and K.Plain(iid)
        if type(iid) == "number" then return { kind = "item", value = iid } end
    end
    return nil
end

-- Am Mauszeiger (aus Zauberbuch, Tasche, Reittiersammlung gezogen).
function RG.FromCursor()
    if not _G.GetCursorInfo then return nil end
    local kind, a, b, c = _G.GetCursorInfo()
    kind = K.Plain(kind)
    if kind == "item" then return { kind = "item", value = K.Plain(a) } end
    if kind == "spell" then
        local id = K.Plain(c) or K.Plain(a)
        if type(b) == "string" and _G.GetSpellBookItemInfo and not K.Plain(c) then
            local ok, _, sid = pcall(_G.GetSpellBookItemInfo, a, b)
            if ok and sid then id = K.Plain(sid) end
        end
        return id and { kind = "spell", value = id } or nil
    end
    if kind == "mount" then
        local mj = _G.C_MountJournal
        if mj and mj.GetMountInfoByID then
            local ok, _, spellID = pcall(mj.GetMountInfoByID, a)
            if ok and spellID then return { kind = "spell", value = K.Plain(spellID) } end
        end
    end
    if kind == "macro" and _G.GetMacroInfo then
        local ok, name, icon, body = pcall(_G.GetMacroInfo, a)
        if ok and body then return { kind = "macro", value = body, label = name, icon = icon } end
    end
    return nil
end

--------------------------------------------------
-- Die sicheren Rahmen
--------------------------------------------------

local frames = {}   -- [i] = { ring, trigger, slots, zones }
RG.frames = frames
local owner          -- Tastenbelegungen

RG.ZONES = 13        -- Raster unsichtbarer Felder je Seite (6.41.0.0)
RG.REACH = 1.9       -- so weit reicht das Raster, in Ringradien

-- 6.41.0.0 (Beta-Test: "man muss immer mit der Maus auf dem Symbol sein"):
-- die Mausposition gibt der geschuetzte Schnipsel im Client nicht heraus.
-- Darum liegt ein Raster unsichtbarer Felder ueber dem ganzen Ring; jedes
-- kennt seine Lage zur Mitte (Attribute zx/zy). Gewaehlt wird das Symbol
-- unter der Maus, sonst die Richtung des Feldes unter der Maus: der
-- sichtbare Platz mit dem groessten Skalarprodukt. Bedingungen ([combat],
-- [mounted] ...) prueft der Schnipsel beim Oeffnen mit
-- SecureCmdOptionParse und ordnet die sichtbaren Plaetze neu im Kreis -
-- die Richtungen je Anzahl stehen vorberechnet als Attribute (u<n>_<i>).
local OPEN = [[
    local total = self:GetAttribute("count") or 0
    local n = 0
    for i = 1, total do
        local s = self:GetFrameRef("s" .. i)
        local cond = s:GetAttribute("cond")
        if not cond or cond == "" or SecureCmdOptionParse(cond) then
            n = n + 1
            s:SetAttribute("vis", n)
        else
            s:SetAttribute("vis", 0)
        end
    end
    self:SetAttribute("shown", n)
    local r = self:GetAttribute("radius") or 80
    for i = 1, total do
        local s = self:GetFrameRef("s" .. i)
        local v = s:GetAttribute("vis")
        if v > 0 then
            local x = self:GetAttribute("u" .. n .. "_" .. v .. "x")
            local y = self:GetAttribute("u" .. n .. "_" .. v .. "y")
            s:ClearAllPoints()
            s:SetPoint("CENTER", self, "CENTER", x * r, y * r)
            s:Show()
        else
            s:Hide()
        end
    end
    self:ClearAllPoints()
    self:SetPoint("CENTER", "$cursor")
    self:Show()
]]

local PICK = [[
    local total = self:GetAttribute("count") or 0
    local n = self:GetAttribute("shown") or 0
    if n == 0 then return nil end
    for i = 1, total do
        local s = self:GetFrameRef("s" .. i)
        if s:IsShown() and s:IsUnderMouse(true) then return i end
    end
    local zx, zy
    for z = 1, self:GetAttribute("zones") or 0 do
        local f = self:GetFrameRef("z" .. z)
        if f:IsUnderMouse() then
            zx, zy = f:GetAttribute("zx"), f:GetAttribute("zy")
            break
        end
    end
    if not zx then return nil end
    local dead = self:GetAttribute("dead") or 0
    if zx * zx + zy * zy < dead * dead then return nil end
    local best, bi
    for i = 1, total do
        local s = self:GetFrameRef("s" .. i)
        local v = s:GetAttribute("vis")
        if v and v > 0 then
            local d = zx * self:GetAttribute("u" .. n .. "_" .. v .. "x") + zy * self:GetAttribute("u" .. n .. "_" .. v .. "y")
            if not best or d > best then best, bi = d, i end
        end
    end
    return bi
]]

local TRIGGER = [[
    local mode = owner:GetAttribute("mode")
    if mode == "click" then
        if down then
            if owner:IsShown() then owner:Hide() else owner:RunAttribute("open") end
        end
        return false
    end
    if down then
        owner:RunAttribute("open")
        return false
    end
    if not owner:IsShown() then return false end
    local i = owner:RunAttribute("pick")
    owner:Hide()
    if not i then return false end
    local s = owner:GetFrameRef("s" .. i)
    self:SetAttribute("type", s:GetAttribute("type"))
    self:SetAttribute("spell", s:GetAttribute("spell"))
    self:SetAttribute("item", s:GetAttribute("item"))
    self:SetAttribute("macrotext", s:GetAttribute("macrotext"))
]]

local function Locked() return (_G.InCombatLockdown and _G.InCombatLockdown()) and true or false end

local CIRCLE = "Interface\\Common\\CommonMaskCircle"

local function Disc(parent, layer, sub, size, col, alpha)
    local t = parent:CreateTexture(nil, layer, nil, sub)
    t:SetTexture(CIRCLE)
    t:SetSize(size, size)
    t:SetPoint("CENTER")
    t:SetVertexColor(col[1], col[2], col[3], alpha or col[4] or 1)
    return t
end

local function BuildRing(i)
    local GC = WeintCodex.GameColors
    local f = { slots = {}, zones = {} }
    local R, S = RG.RADIUS, RG.SLOT
    local size = math.floor(R * RG.REACH * 2)
    local ring = CreateFrame("Frame", "WeintCodexRing" .. i, UIParent, "SecureHandlerBaseTemplate")
    ring:SetSize(size, size)
    ring:SetFrameStrata("DIALOG")
    ring:SetClampedToScreen(true)
    ring:SetAttribute("dead", RG.DEAD)
    ring:SetAttribute("radius", R)
    ring:SetAttribute("open", OPEN)
    ring:SetAttribute("pick", PICK)
    -- Vorberechnete Richtungen je Anzahl: oben beginnen, im Uhrzeigersinn.
    for n = 1, RG.MAX do
        for k = 1, n do
            local a = math.pi / 2 - (k - 1) * 2 * math.pi / n
            ring:SetAttribute("u" .. n .. "_" .. k .. "x", math.cos(a))
            ring:SetAttribute("u" .. n .. "_" .. k .. "y", math.sin(a))
        end
    end
    -- Aussehen: Halo, Neonband in zwei Farben (oben Cyan, unten Magenta),
    -- dunkler Kern, Zeiger zur Wahl.
    local A, B, core = GC.ringNeonA, GC.ringNeonB, GC.ringCore
    f.halo = Disc(ring, "BACKGROUND", -8, R * 2 + S + 46, A, 0.10)
    f.bandA = Disc(ring, "BACKGROUND", -7, R * 2 + S + 14, A, 0.55)
    f.bandA:SetTexCoord(0, 1, 0, 0.5)
    f.bandA:SetHeight((R * 2 + S + 14) / 2)
    f.bandA:ClearAllPoints()
    f.bandA:SetPoint("BOTTOM", ring, "CENTER", 0, 0)
    f.bandB = Disc(ring, "BACKGROUND", -7, R * 2 + S + 14, B, 0.55)
    f.bandB:SetTexCoord(0, 1, 0.5, 1)
    f.bandB:SetHeight((R * 2 + S + 14) / 2)
    f.bandB:ClearAllPoints()
    f.bandB:SetPoint("TOP", ring, "CENTER", 0, 0)
    f.core = Disc(ring, "BACKGROUND", -6, R * 2 + S + 8, core)
    f.inner = Disc(ring, "BORDER", 0, R * 2 - S - 6, A, 0.10)
    f.hub = Disc(ring, "BORDER", 1, RG.DEAD * 2, core, 1)
    f.hubEdge = Disc(ring, "BORDER", 0, RG.DEAD * 2 + 4, B, 0.6)
    f.pointer = ring:CreateTexture(nil, "ARTWORK")
    f.pointer:SetTexture(CIRCLE)
    f.pointer:SetSize(10, 10)
    f.pointer:Hide()
    f.label = K.NewText(ring, 13)
    f.label:SetPoint("TOP", ring, "CENTER", 0, -RG.DEAD - 8)
    f.label:SetWidth(R * 2 - S)
    f.title = K.NewText(ring, 12)
    f.title:SetPoint("BOTTOM", ring, "CENTER", 0, RG.DEAD + 8)
    f.title:SetTextColor(A[1], A[2], A[3], 1)
    for s = 1, RG.MAX do
        local b = CreateFrame("Button", nil, ring, "SecureActionButtonTemplate")
        b:SetSize(S, S)
        b:RegisterForClicks("AnyUp")
        b:SetAttribute("useOnKeyDown", false)
        b.plate = Disc(b, "BACKGROUND", 0, S + 10, GC.ringSlot)
        b.edge = Disc(b, "BACKGROUND", 1, S + 4, A, 0.7)
        b.glow = Disc(b, "BACKGROUND", -1, S + 30, A, 0.0)
        b.icon = b:CreateTexture(nil, "ARTWORK")
        b.icon:SetSize(S - 4, S - 4)
        b.icon:SetPoint("CENTER")
        local mask = b:CreateMaskTexture()
        mask:SetTexture(CIRCLE, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        mask:SetAllPoints(b.icon)
        b.icon:AddMaskTexture(mask)
        b.cd = CreateFrame("Cooldown", nil, b, "CooldownFrameTemplate")
        b.cd:SetAllPoints(b.icon)
        if b.cd.SetSwipeTexture then b.cd:SetSwipeTexture(CIRCLE) end
        if b.cd.SetDrawEdge then b.cd:SetDrawEdge(false) end
        b.count = K.NewText(b, 11)
        b.count:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", 2, -2)
        _G.SecureHandlerSetFrameRef(ring, "s" .. s, b)
        -- Ein Klick auf ein Symbol benutzt es und schliesst den Ring.
        _G.SecureHandlerWrapScript(b, "OnClick", ring, "return nil, true", "owner:Hide()")
        b:Hide()
        f.slots[s] = b
    end
    -- Raster unsichtbarer Felder (keine Maus noetig: IsUnderMouse misst).
    local Z = RG.ZONES
    local cell = size / Z
    local nz = 0
    for zx = 1, Z do
        for zy = 1, Z do
            nz = nz + 1
            local z = CreateFrame("Frame", nil, ring)
            z:SetSize(cell, cell)
            local ox, oy = (zx - 0.5) * cell - size / 2, (zy - 0.5) * cell - size / 2
            z:SetPoint("CENTER", ring, "CENTER", ox, oy)
            z:SetAttribute("zx", ox)
            z:SetAttribute("zy", oy)
            _G.SecureHandlerSetFrameRef(ring, "z" .. nz, z)
            f.zones[nz] = z
        end
    end
    ring:SetAttribute("zones", nz)
    local trig = CreateFrame("Button", "WeintCodexRingKey" .. i, UIParent, "SecureActionButtonTemplate")
    trig:RegisterForClicks("AnyUp", "AnyDown")
    trig:SetAttribute("useOnKeyDown", false)
    _G.SecureHandlerWrapScript(trig, "OnClick", ring, TRIGGER)
    -- Waehrend der Ring steht: Wahl hervorheben, Band drehen, Abklingzeiten
    -- (nur Anzeige - Texturen und Text, keine geschuetzten Aufrufe).
    ring:SetScript("OnUpdate", function(_, el) RG.Tick(i, el or 0) end)
    ring:SetScript("OnShow", function() RG.Refresh(i) end)
    ring:SetScript("OnHide", function()
        for _, b in ipairs(f.slots) do b.glow:SetAlpha(0) end
        f.pointer:Hide()
        f.shown = nil
    end)
    ring:Hide()
    f.ring, f.trigger = ring, trig
    frames[i] = f
    return f
end
RG.BuildRing = BuildRing

-- Abklingzeit eines Platzes: start, dauer oder nil.
local function Cooldown(e)
    if e.type == "spell" and e.spell then
        local cs = _G.C_Spell
        if cs and cs.GetSpellCooldown then
            local ok, info = pcall(cs.GetSpellCooldown, e.spell)
            if ok and type(info) == "table" then return info.startTime, info.duration end
        elseif _G.GetSpellCooldown then
            local ok, st0, dur = pcall(_G.GetSpellCooldown, e.spell)
            if ok then return st0, dur end
        end
    elseif e.type == "item" and e.item then
        local id = tonumber(e.item:match("%d+"))
        local cc = _G.C_Container
        local f = (cc and cc.GetItemCooldown) or _G.GetItemCooldown
        if id and f then
            local ok, st0, dur = pcall(f, id)
            if ok then return st0, dur end
        end
    end
    return nil
end

-- Beim Oeffnen: Abklingzeiten und Zahl aktuell (auch im Kampf - nur Anzeige).
function RG.Refresh(i)
    local f = frames[i]
    if not f or not f.entries then return end
    for s, e in ipairs(f.entries) do
        local b = f.slots[s]
        local st0, dur = Cooldown(e)
        local ok = pcall(function()
            if st0 and dur and dur > 1.5 then b.cd:SetCooldown(st0, dur) b.icon:SetDesaturated(true)
            else b.cd:Clear() b.icon:SetDesaturated(false) end
        end)
        if not ok then pcall(b.cd.Clear, b.cd) end
        if e.type == "item" then
            local n = ItemCount(tonumber(e.item:match("%d+")) or 0)
            b.count:SetText(n and n > 1 and tostring(n) or "")
        end
    end
end

-- Hervorheben wie der Schnipsel waehlt; die Wahl pulsiert.
function RG.Tick(i, el)
    local f = frames[i]
    if not f then return end
    local x, y = _G.GetCursorPosition()
    local cx, cy = f.ring:GetCenter()
    local sc = f.ring:GetEffectiveScale()
    if not (cx and x) then return end
    local dx, dy = x / sc - cx, y / sc - cy
    local pick, best
    for k = 1, f.count or 0 do
        local b = f.slots[k]
        if b:IsShown() and b:IsMouseOver() then pick = k break end
    end
    if not pick and dx * dx + dy * dy >= RG.DEAD * RG.DEAD then
        for k = 1, f.count or 0 do
            local b = f.slots[k]
            if b:IsShown() then
                local bx, by = b:GetCenter()
                if bx then
                    local vx, vy = bx - cx, by - cy
                    local l = math.sqrt(vx * vx + vy * vy)
                    local d = l > 0 and (dx * vx + dy * vy) / l or 0
                    if not best or d > best then best, pick = d, k end
                end
            end
        end
    end
    local pulse = 0.55 + 0.25 * math.sin(((_G.GetTime and _G.GetTime()) or 0) * 6)
    for k = 1, f.count or 0 do f.slots[k].glow:SetAlpha(k == pick and pulse or 0) end
    if f.shown ~= pick then
        f.shown = pick
        f.label:SetText(pick and f.labels[pick] or "")
        if pick then
            local bx, by = f.slots[pick]:GetCenter()
            local vx, vy = bx - cx, by - cy
            local l = math.sqrt(vx * vx + vy * vy)
            if l > 0 then
                f.pointer:ClearAllPoints()
                f.pointer:SetPoint("CENTER", f.ring, "CENTER", vx / l * (RG.DEAD + 7), vy / l * (RG.DEAD + 7))
                local B = WeintCodex.GameColors.ringNeonB
                f.pointer:SetVertexColor(B[1], B[2], B[3], 1)
                f.pointer:Show()
            end
        else
            f.pointer:Hide()
        end
    end
end

-- Einen Ring mit Inhalt fuellen (nur ausserhalb des Kampfes).
function RG.Fill(i, ring)
    local f = frames[i] or BuildRing(i)
    local slots = RG.Slots(ring)
    local n = #slots
    f.count, f.labels, f.entries, f.shown = n, {}, slots, nil
    f.ring:SetAttribute("count", n)
    f.ring:SetAttribute("mode", ring.mode or "hold")
    f.ring:SetScale(math.max(0.5, math.min(2, (tonumber(K.Get(KEY, "ringScale")) or 100) / 100)))
    f.title:SetText(ring.name or "")
    for s = 1, RG.MAX do
        local b, e = f.slots[s], slots[s]
        if e then
            local a = math.pi / 2 - (s - 1) * 2 * math.pi / n
            b:ClearAllPoints()
            b:SetPoint("CENTER", f.ring, "CENTER", math.cos(a) * RG.RADIUS, math.sin(a) * RG.RADIUS)
            b:SetAttribute("type", e.type)
            b:SetAttribute("spell", e.spell)
            b:SetAttribute("item", e.item)
            b:SetAttribute("macrotext", e.macrotext)
            b:SetAttribute("cond", e.cond)
            b:SetAttribute("vis", s)
            b.icon:SetTexture(e.icon or 134400)
            b.count:SetText(e.count and e.count > 1 and tostring(e.count) or "")
            f.labels[s] = e.label or ""
            b:Show()
        else
            b:SetAttribute("type", nil)
            b:SetAttribute("cond", nil)
            b:SetAttribute("vis", 0)
            b:Hide()
        end
    end
    f.ring:SetAttribute("shown", n)
    return f
end

-- Alles neu: Inhalte und Tasten. Im Kampf: danach.
local pending = false
function RG.Apply()
    if Locked() then pending = true return end
    pending = false
    -- Ohne die sicheren Bausteine des Spiels (Pruefung) kein Ring.
    if not (_G.SecureHandlerWrapScript and _G.SecureHandlerSetFrameRef) then return end
    if not owner then owner = CreateFrame("Frame", "WeintCodexRingKeys", UIParent) end
    if _G.ClearOverrideBindings then _G.ClearOverrideBindings(owner) end
    local list = RG.Active() and RG.List() or {}
    for i = 1, math.max(#frames, #list) do
        local ring = list[i]
        if ring then
            local f = RG.Fill(i, ring)
            if ring.key and ring.key ~= "" and _G.SetOverrideBindingClick then
                _G.SetOverrideBindingClick(owner, true, ring.key, "WeintCodexRingKey" .. i, "LeftButton")
            end
            f.ring:Hide()
        elseif frames[i] then
            frames[i].ring:SetAttribute("count", 0)
            frames[i].ring:Hide()
        end
    end
end

-- Viele Ereignisse (Taschen, Zauber) auf einmal: einmal nach kurzer Zeit.
local queued = false
function RG.Schedule()
    if queued then return end
    queued = true
    local function run() queued = false RG.Apply() end
    if _G.C_Timer and _G.C_Timer.After then _G.C_Timer.After(0.5, run) else run() end
end

local ev = CreateFrame("Frame")
for _, e in ipairs({ "PLAYER_LOGIN", "PLAYER_REGEN_ENABLED", "SPELLS_CHANGED", "BAG_UPDATE_DELAYED",
    "NEW_MOUNT_ADDED", "COMPANION_LEARNED", "LEARNED_SPELL_IN_TAB" }) do
    pcall(ev.RegisterEvent, ev, e)
end
ev:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_REGEN_ENABLED" and not pending then return end
    RG.Schedule()
end)

function RG.StatusLine()
    local list = RG.List()
    local keys = 0
    for _, r in ipairs(list) do if r.key and r.key ~= "" then keys = keys + 1 end end
    return string.format("Ringe: %s · %d Ringe, %d mit Taste", RG.Active() and "an" or "aus", #list, keys)
end

--------------------------------------------------
-- Einstellungen
--------------------------------------------------

local edit = { index = 1, input = "", entry = 1 }
RG.edit = edit

local function Current()
    local list = RG.List()
    if edit.index > #list then edit.index = #list end
    if edit.index < 1 then edit.index = 1 end
    return list[edit.index], list
end
RG.Current = Current

local function RingItems()
    local items = {}
    for i, r in ipairs(RG.List()) do
        items[#items + 1] = { value = i, text = (r.name or ("Ring " .. i)) .. ((r.key and r.key ~= "") and ("  ·  " .. r.key) or "") }
    end
    return items
end

-- Taste festlegen: Feld anklicken, Taste druecken (mit Zusatztasten).
-- Esc bricht ab, Entf loescht die Belegung.
local function KeyField(parent, width)
    local w = CreateFrame("Frame", nil, parent)
    local lbl = K.NewText(w, 13)
    lbl:SetPoint("TOPLEFT", w, "TOPLEFT", 0, -2)
    local m = C.textMuted
    lbl:SetTextColor(m[1], m[2], m[3], 1)
    lbl:SetText("Taste")
    local b = WeintCodex.CreateButton(w, { text = "", kind = "secondary", height = 26, size = 11, backdrop = "bgDark",
        onClick = function(self)
            if Locked() then return end
            w.listening = true
            self:EnableKeyboard(true)
            w.Sync()
        end })
    b:SetPoint("BOTTOMLEFT", w, "BOTTOMLEFT", 0, 2)
    b:SetWidth(math.min(width, 240))
    b:SetScript("OnKeyDown", function(self, key)
        if not w.listening then return end
        if key == "LSHIFT" or key == "RSHIFT" or key == "LCTRL" or key == "RCTRL" or key == "LALT" or key == "RALT" then return end
        local ring = Current()
        w.listening = false
        self:EnableKeyboard(false)
        if key ~= "ESCAPE" and ring then
            if key == "DELETE" or key == "BACKSPACE" then ring.key = nil
            else
                local mods = ""
                if _G.IsAltKeyDown and _G.IsAltKeyDown() then mods = mods .. "ALT-" end
                if _G.IsControlKeyDown and _G.IsControlKeyDown() then mods = mods .. "CTRL-" end
                if _G.IsShiftKeyDown and _G.IsShiftKeyDown() then mods = mods .. "SHIFT-" end
                ring.key = mods .. key
            end
            Changed()
        end
        w.Sync()
    end)
    w.Sync = function()
        local ring = Current()
        if w.listening then b:SetText("Taste drücken … (Esc: abbrechen, Entf: löschen)")
        else b:SetText(ring and ring.key and ring.key ~= "" and ring.key or "Keine – anklicken und Taste drücken") end
    end
    w.Sync()
    return w
end

-- Liste der Eintraege eines eigenen Rings, je Zeile Symbol, Name, nach
-- vorn, entfernen. Feste Ringe zeigen, was sie gerade enthalten.
local ROWS, COLS, ROW_H = 6, 2, 26
local function EntryList(parent, width)
    local w = CreateFrame("Frame", nil, parent)
    local cw = math.floor(width / COLS) - 8
    local rows = {}
    for i = 1, ROWS * COLS do
        local r = CreateFrame("Frame", nil, w)
        r:SetSize(cw, ROW_H - 4)
        r:SetPoint("TOPLEFT", w, "TOPLEFT", math.floor((i - 1) / ROWS) * (cw + 16), -((i - 1) % ROWS) * ROW_H)
        r.sel = r:CreateTexture(nil, "BACKGROUND")
        r.sel:SetAllPoints(r)
        local ac = C.accent
        r.sel:SetColorTexture(ac[1], ac[2], ac[3], 0.18)
        r.sel:Hide()
        r:EnableMouse(true)
        r:SetScript("OnMouseDown", function()
            if r.index then edit.entry = r.index K.Fire("setting", KEY, "ringEdit") end
        end)
        r.cond = K.NewText(r, 10)
        r.cond:SetPoint("RIGHT", r, "RIGHT", -48, 0)
        local gm = C.textMuted
        r.cond:SetTextColor(gm[1], gm[2], gm[3], 1)
        r.icon = r:CreateTexture(nil, "ARTWORK")
        r.icon:SetSize(20, 20)
        r.icon:SetPoint("LEFT")
        r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        r.text = K.NewText(r, 12)
        r.text:SetPoint("LEFT", r.icon, "RIGHT", 6, 0)
        r.text:SetPoint("RIGHT", r.cond, "LEFT", -4, 0)
        r.text:SetJustifyH("LEFT")
        r.up = WeintCodex.CreateButton(r, { text = "▲", kind = "secondary", height = 20, size = 10, backdrop = "bgDark",
            onClick = function()
                local ring = Current()
                if ring and ring.entries and r.index and r.index > 1 then
                    local e = ring.entries
                    e[r.index], e[r.index - 1] = e[r.index - 1], e[r.index]
                    Changed()
                end
            end })
        r.up:SetWidth(20)
        r.up:SetPoint("RIGHT", r, "RIGHT", -24, 0)
        r.del = WeintCodex.CreateButton(r, { text = "×", kind = "secondary", height = 20, size = 12, backdrop = "bgDark",
            onClick = function()
                local ring = Current()
                if ring and ring.entries and r.index then
                    table.remove(ring.entries, r.index)
                    Changed()
                end
            end })
        r.del:SetWidth(20)
        r.del:SetPoint("RIGHT", r, "RIGHT", 0, 0)
        rows[i] = r
    end
    w.empty = K.NewText(w, 12)
    w.empty:SetPoint("TOPLEFT", w, "TOPLEFT", 0, -4)
    w.empty:SetWidth(width)
    w.empty:SetJustifyH("LEFT")
    local m = C.textMuted
    w.empty:SetTextColor(m[1], m[2], m[3], 1)
    w.Sync = function()
        local ring = Current()
        local custom = ring and (ring.preset == nil or ring.preset == "custom")
        local shown = ring and RG.Slots(ring) or {}
        local entries = custom and (ring.entries or {}) or nil
        local n = custom and #entries or #shown
        for i, r in ipairs(rows) do
            if i <= n then
                local e = custom and RG.Resolve(entries[i]) or shown[i]
                r.index = custom and i or nil
                r.icon:SetTexture(e and e.icon or 134400)
                r.text:SetText(e and e.label or "(nicht verfügbar)")
                r.up:SetShown(custom and i > 1)
                local cond = custom and entries[i].cond or nil
                r.cond:SetText(cond and cond ~= "" and cond or "")
                r.sel:SetShown(custom and i == edit.entry)
                r.del:SetShown(custom)
                r:Show()
            else
                r:Hide()
            end
        end
        if n == 0 then
            w.empty:SetText(custom and "Noch leer – unten etwas hineinziehen oder eintippen."
                or "Gerade nichts verfügbar (nichts gelernt oder in der Tasche).")
            w.empty:Show()
        else
            w.empty:Hide()
        end
    end
    w.Sync()
    return w
end

-- Ablage: aus Zauberbuch, Tasche oder Reittiersammlung hierher ziehen.
local function DropBox(parent, width)
    local w = CreateFrame("Button", nil, parent)
    local bg = w:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(w)
    local d = C.bgDark
    bg:SetColorTexture(d[1], d[2], d[3], d[4] or 1)
    K.Border(w, 1, 0, 0, 0, 1, "BORDER")
    local t = K.NewText(w, 12)
    t:SetPoint("CENTER")
    t:SetText("Zauber, Gegenstand, Reittier oder Makro hierher ziehen")
    local function Take()
        local ring = Current()
        local e = RG.FromCursor()
        if not (ring and e) then return end
        if ring.preset and ring.preset ~= "custom" then RG.Convert(ring) end
        ring.entries = ring.entries or {}
        if #ring.entries < RG.MAX then ring.entries[#ring.entries + 1] = e end
        if _G.ClearCursor then _G.ClearCursor() end
        Changed()
    end
    w:SetScript("OnReceiveDrag", Take)
    w:SetScript("OnClick", Take)
    w.Sync = function() end
    return w
end

local function Build(B)
    local off = function() return not K.Get(KEY, "rings") end
    B:Section("Ringe", "Taste halten, Maus in eine Richtung, loslassen – oder umstellen auf Drücken und Klicken. Benutzt wird auch im Kampf; ändern kannst du einen Ring nur außerhalb.")
    B:Row({ type = "toggle", label = "Ringe benutzen", key = "rings" },
          { type = "slider", label = "Größe", key = "ringScale", min = 50, max = 200, step = 10, disabled = off,
            format = function(v) return string.format("%d %%", v) end })
    B:Row({ type = "dropdown", label = "Ring bearbeiten", items = RingItems,
            get = function() return edit.index end, set = function(v) edit.index = v K.Fire("setting", KEY, "ringEdit") end },
          { type = "button", label = "Ringe", text = "Neuer Ring", onClick = function()
                local list = RG.List()
                if #list >= RG.RINGS then return end
                list[#list + 1] = { name = "Ring " .. (#list + 1), preset = "custom", mode = "hold", entries = {} }
                edit.index = #list
                Changed()
            end })
    B:Row({ type = "input", label = "Name",
            get = function() local r = Current() return r and r.name or "" end,
            set = function(v) local r = Current() if r then r.name = v Changed() end end },
          { type = "custom", height = 52, create = function(parent) return KeyField(parent, 300) end })
    B:Row({ type = "dropdown", label = "Inhalt", items = RG.PRESETS,
            get = function() local r = Current() return r and (r.preset or "custom") end,
            set = function(v)
                local r = Current()
                if not r then return end
                if v == "custom" then RG.Convert(r) else r.preset = v end
                Changed()
            end },
          { type = "dropdown", label = "Bedienung", items = RG.MODES,
            get = function() local r = Current() return r and (r.mode or "hold") end,
            set = function(v) local r = Current() if r then r.mode = v Changed() end end })
    B:Row({ type = "custom", height = ROWS * ROW_H + 4, create = function(parent, width) return EntryList(parent, width) end }, nil)
    B:Row({ type = "custom", height = 40, create = function(parent, width) return DropBox(parent, width) end }, nil)
    B:Row({ type = "input", label = "Oder eintippen: Zauber, Gegenstand (Name/ID) oder /Makro",
            get = function() return edit.input end, set = function(v) edit.input = v end },
          { type = "button", label = "Hinzufügen", text = "Hinzufügen", onClick = function()
                local r = Current()
                local e = RG.Parse(edit.input)
                if not (r and e) then
                    print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " Nicht gefunden – Zauber und Gegenstände kennt das Spiel nur, wenn du sie gelernt oder schon gesehen hast.")
                    return
                end
                if r.preset and r.preset ~= "custom" then RG.Convert(r) end
                r.entries = r.entries or {}
                if #r.entries < RG.MAX then r.entries[#r.entries + 1] = e end
                edit.input = ""
                Changed()
            end })
    local function Entry()
        local r = Current()
        return r and (r.preset == nil or r.preset == "custom") and r.entries and r.entries[edit.entry] or nil
    end
    B:Row({ type = "dropdown", label = "Bedingung des gewählten Eintrags", items = RG.CONDS,
            disabled = function() return Entry() == nil end,
            get = function() local e = Entry() return e and (e.cond or "") or "" end,
            set = function(v) local e = Entry() if e then e.cond = v ~= "" and v or nil Changed() end end },
          { type = "input", label = "Oder eigene, z. B. [combat,group]",
            get = function() local e = Entry() return e and e.cond or "" end,
            set = function(v) local e = Entry() if e then e.cond = (v ~= "" and v) or nil Changed() end end })
    B:Row({ type = "button", label = "Fester Ring", text = "In eigenen Ring umwandeln", onClick = function()
                local r = Current()
                if r then RG.Convert(r) Changed() end
            end },
          { type = "button", label = "Diesen Ring", text = "Löschen", onClick = function()
                local _, list = Current()
                if #list > 0 then table.remove(list, edit.index) edit.index = 1 Changed() end
            end })
end

local mod = K.Module(KEY)
if mod then
    if mod.defaults.rings == nil then mod.defaults.rings = true end
    if mod.defaults.ringScale == nil then mod.defaults.ringScale = 100 end
    mod.pages[#mod.pages + 1] = { key = "ringe", label = "Ringe", build = Build }
    if type(mod.pageOrder) == "table" then mod.pageOrder.ringe = 14 end
end

K.Listen(function(kind, key, what)
    if (kind == "active" or kind == "setting") and key == KEY and what ~= "ringEdit" then RG.Schedule() end
end)
