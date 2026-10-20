--------------------------------------------------
-- WeintCodex :: Beute - was wo faellt
--------------------------------------------------
-- Wunsch des Besitzers: ein Beutebuch im Stil des Codex, dort, wo Lehrer,
-- Berufe und Dungeons stehen (Gruppe "Leveln", Eintrag "Beute" direkt
-- unter "Dungeons"). Er nimmt den Platz, den 6.61.1.0 in der Spalte
-- freigegeben hatte; die Spalte ist damit wieder voll. Die Unternavigation
-- traegt die Rubriken (Wunschliste, Dungeons, Schlachtzuege, Ruf, PvP,
-- Sets), die Seite links die Bereiche der Rubrik, rechts die Beute.
--
-- DREI BESTAENDE, NIE VERMISCHT:
--   * WAS WO FAELLT: data/loot.lua (erzeugt von .github/scripts/import_loot.py,
--     Art `classic`, neue Inhalte von Forever `community`). Nur Nummern.
--   * WIE EIN GEGENSTAND HEISST, AUSSIEHT, WAS ER IST: allein der Client
--     (C_Item.GetItemInfo), in dieser Sitzung gemerkt, nie gespeichert.
--     Solange er nicht antwortet: "lädt …", nie leer, nie geraten.
--   * WAS DU DIR WUENSCHST: WeintCodex_SavedData.loot.wish (je Konto).
-- Eine Dropchance stammt aus Classic; fehlt sie, steht keine da (nie 0 %).
-- Keine Wertung, keine Bestenliste (CLAUDE.md: keine BiS-Listen).
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.LootBook = {}

local LB = WeintCodex.LootBook
local D  = WeintCodex.LootData
local C  = WeintCodex.Colors

LB.MAX_CELLS = 240        -- mehr Gegenstaende baut die Seite nicht; Suche grenzt ein
LB.CELL_H = 40
LB.CELL_MIN_W = 250

LB.CATEGORIES = {
    { key = "wish", label = "Wunschliste" },
    { key = "d",    label = "Dungeons" },
    { key = "r",    label = "Schlachtzüge" },
    { key = "f",    label = "Ruf" },
    { key = "p",    label = "PvP" },
    { key = "s",    label = "Sets" },
}

local function Plain(v)
    local K = WeintCodex.UIKit
    if K and K.Plain then return K.Plain(v) end
    return v
end

local function Split(s, sep)
    local out, i = {}, 1
    while true do
        local j = s:find(sep, i, true)
        if not j then out[#out + 1] = s:sub(i) break end
        out[#out + 1] = s:sub(i, j - 1)
        i = j + 1
    end
    return out
end

--------------------------------------------------
-- Bestand (Text bleibt Text, bis er gebraucht wird)
--------------------------------------------------

local instCache = {}
function LB.Instance(n)
    if instCache[n] then return instCache[n] end
    local s = D and D.i and D.i[n]
    if type(s) ~= "string" then return nil end
    local f = Split(s, "\t")
    local inst = { index = n, key = f[1], cat = f[2], kind = f[3], area = tonumber(f[4]) or 0,
                   fallback = f[5], levels = (f[6] ~= "" and f[6]) or nil }
    instCache[n] = inst
    return inst
end

function LB.Count() return #(D and D.i or {}) end

-- Anzeigename: der Client, wenn er die Gebiets- oder Fraktionsnummer kennt.
function LB.InstanceName(inst)
    if not inst then return "" end
    if inst.name then return inst.name end
    local name
    if (inst.cat == "d" or inst.cat == "r") and inst.area > 0 and _G.C_Map and _G.C_Map.GetAreaInfo then
        local ok, n = pcall(_G.C_Map.GetAreaInfo, inst.area)
        n = ok and Plain(n) or nil
        if type(n) == "string" and n ~= "" then name = n end
    elseif inst.cat == "f" and inst.area > 0 then
        local cr = _G.C_Reputation
        if cr and cr.GetFactionDataByID then
            local ok, d = pcall(cr.GetFactionDataByID, inst.area)
            local n = ok and type(d) == "table" and Plain(d.name) or nil
            if type(n) == "string" and n ~= "" then name = n end
        elseif _G.GetFactionInfoByID then
            local ok, n = pcall(_G.GetFactionInfoByID, inst.area)
            n = ok and Plain(n) or nil
            if type(n) == "string" and n ~= "" then name = n end
        end
    end
    inst.name = name or inst.fallback
    return inst.name
end

-- Bosse einer Instanz: { { name, npc, set, items = { {id, rate, only}, ... } } }
local bossCache = {}
function LB.Bosses(n)
    if bossCache[n] then return bossCache[n] end
    local out = {}
    for bi, s in ipairs(D and D.b and D.b[n] or {}) do
        local f = Split(s, "\t")
        local b = { index = bi, name = f[1], items = {} }
        local extra = f[2] or ""
        if extra:sub(1, 1) == "s" then b.set = tonumber(extra:sub(2)) else b.npc = tonumber(extra) end
        for _, part in ipairs(Split(f[3] or "", ",")) do
            local id, rate, only = part:match("^(%d+):?([%d%.]*)([ah]?)$")
            id = tonumber(id)
            if id then
                b.items[#b.items + 1] = { id = id, rate = tonumber(rate), only = only ~= "" and only or nil }
            end
        end
        out[#out + 1] = b
    end
    bossCache[n] = out
    return out
end

function LB.BossName(b)
    if b.set and _G.C_Item and _G.C_Item.GetItemSetInfo then
        local ok, n = pcall(_G.C_Item.GetItemSetInfo, b.set)
        n = ok and Plain(n) or nil
        if type(n) == "string" and n ~= "" then return n end
    end
    return b.name
end

function LB.FindInstance(key)
    for n = 1, LB.Count() do
        local inst = LB.Instance(n)
        if inst.key == key then return n end
    end
    return nil
end

-- Die erste Stelle, an der ein Gegenstand steht (fuer die Wunschliste).
local sourceOf
function LB.SourceOf(id)
    if not sourceOf then
        sourceOf = {}
        for n = 1, LB.Count() do
            for bi, b in ipairs(LB.Bosses(n)) do
                for _, it in ipairs(b.items) do
                    if not sourceOf[it.id] then sourceOf[it.id] = { n, bi, it } end
                end
            end
        end
    end
    local s = sourceOf[id]
    if s then return s[1], s[2], s[3] end
    return nil
end

-- Herkunft: Instanz von Forever oder Gegenstand neu in Forever = community.
function LB.KindOf(inst, id)
    if inst and inst.kind == "community" then return "community" end
    if id and D and id >= (D.FOREVER_ITEM_MIN or 100000) then return "community" end
    return "classic"
end

function LB.Source(kind)
    local S = WeintCodex.Sources
    if not S then return nil end
    return kind == "community" and S.COMMUNITY or S.CLASSIC
end

--------------------------------------------------
-- Was der Client ueber einen Gegenstand sagt
--------------------------------------------------

local info = {}          -- [id] = { name, link, quality, icon, slot, kind } - nur diese Sitzung
local pending = {}       -- [id] = true, solange der Client nachlaedt
LB.names = {}            -- [id] = Name (fuer die Suche: nur, was schon da ist)
LB.pending = pending

local function IconOf(id)
    local ci = _G.C_Item
    if ci and ci.GetItemIconByID then
        local ok, tex = pcall(ci.GetItemIconByID, id)
        tex = ok and Plain(tex) or nil
        if type(tex) ~= "nil" then return tex end
    end
    return nil
end

LB.RETRY = 4
LB.diag = { byInfo = 0, byName = 0, byTooltip = 0, byObject = 0 }
local asked, loadedName, tries = {}, {}, {}
LB.TRIES = 4
LB.REQ_MAX = 20
local reqSec, reqN = -1, 0
local waiting = false
function LB.WaitForNames()
    if waiting or not (_G.C_Timer and _G.C_Timer.After) then return end
    waiting = true
    _G.C_Timer.After(2, function()
        waiting = false
        if LB.Redraw then LB.Redraw() end
    end)
end

function LB.Info(id)
    local have = info[id]
    if have then return have end
    local ci = _G.C_Item
    local fn = (ci and ci.GetItemInfo) or _G.GetItemInfo
    local name, link, quality, itype, isub, equip, icon
    if fn then
        local ok, n, l, q, _, _, t, st, _, eq, tex = pcall(fn, id)
        if ok then
            name, link, quality, itype, isub, equip, icon = Plain(n), Plain(l), Plain(q), Plain(t), Plain(st), Plain(eq), Plain(tex)
        end
    end
    -- 6.84.9.0 (Beta-Test mit Bild: Sets laden auch nach 6.84.8.0 nie,
    -- obwohl die Symbole da sind): GetItemInfo antwortet auf Forever fuer
    -- diese Gegenstaende nicht. Weitere Wege des Clients, der Reihe nach:
    -- Name je Nummer, Tooltipdaten, Gegenstand-Objekt mit Rueckruf.
    if (type(name) ~= "string" or name == "") and ci and ci.GetItemNameByID then
        local ok, n = pcall(ci.GetItemNameByID, id)
        n = ok and Plain(n) or nil
        if type(n) == "string" and n ~= "" then name = n LB.diag.byName = LB.diag.byName + 1 end
    end
    if (type(name) ~= "string" or name == "") and _G.C_TooltipInfo and _G.C_TooltipInfo.GetItemByID then
        local ok, d = pcall(_G.C_TooltipInfo.GetItemByID, id)
        local line = ok and type(d) == "table" and type(d.lines) == "table" and d.lines[1]
        local n = type(line) == "table" and Plain(line.leftText) or nil
        if type(n) == "string" and n ~= "" and n ~= _G.RETRIEVING_ITEM_INFO then name = n LB.diag.byTooltip = LB.diag.byTooltip + 1 end
    end
    if (type(quality) ~= "number") and ci and ci.GetItemQualityByID then
        local ok, q = pcall(ci.GetItemQualityByID, id)
        q = ok and Plain(q) or nil
        if type(q) == "number" then quality = q end
    end
    if (type(name) ~= "string" or name == "") and not asked[id] and _G.Item and _G.Item.CreateFromItemID then
        asked[id] = true
        local ok, obj = pcall(_G.Item.CreateFromItemID, _G.Item, id)
        if ok and type(obj) == "table" and obj.ContinueOnItemLoad then
            pcall(obj.ContinueOnItemLoad, obj, function()
                local okn, n = pcall(obj.GetItemName, obj)
                n = okn and Plain(n) or nil
                if type(n) == "string" and n ~= "" then
                    LB.names[id] = n
                    loadedName[id] = n
                    LB.diag.byObject = LB.diag.byObject + 1
                    if LB.Redraw then LB.Redraw() end
                end
            end)
        end
    end
    if (type(name) ~= "string" or name == "") and loadedName[id] then name = loadedName[id] end
    if type(name) ~= "string" or name == "" then
        -- 6.84.8.0 (Beta-Test mit Bild: Sets "laden und laden"): bei vielen
        -- Gegenstaenden auf einmal laesst der Server Anfragen fallen - die
        -- blieben fuer immer "unterwegs". Jetzt nach LB.RETRY s erneut fragen,
        -- und solange etwas laedt, malt die Seite alle 2 s nach.
        local now = _G.GetTime and Plain(_G.GetTime()) or 0
        -- Hoechstens LB.REQ_MAX Anfragen je Sekunde - grosse Listen (Sets)
        -- fluteten den Server, eingegrenzt ("Platte") kam alles an.
        if reqSec ~= math.floor(now) then reqSec, reqN = math.floor(now), 0 end
        if (not pending[id] or now - pending[id] > LB.RETRY) and reqN < LB.REQ_MAX then
            reqN = reqN + 1
            pending[id] = now
            tries[id] = (tries[id] or 0) + 1
            if ci and ci.RequestLoadItemDataByID then pcall(ci.RequestLoadItemDataByID, id) end
        end
        -- Nach LB.TRIES Anfragen ohne Antwort: ehrlich "unbekannt" statt
        -- ewig "laedt" (unknown ist nicht loading).
        if (tries[id] or 0) >= LB.TRIES then
            LB.diag.missing = (LB.diag.missing or 0) + (tries[id] == LB.TRIES and 1 or 0)
            tries[id] = LB.TRIES + 1
            return { icon = IconOf(id), missing = true }
        end
        LB.WaitForNames()
        return { icon = IconOf(id), loading = true }
    end
    pending[id] = nil
    if type(Plain(fn and select(2, pcall(fn, id)))) == "string" then LB.diag.byInfo = LB.diag.byInfo + 1 end
    local slot = type(equip) == "string" and equip ~= "" and _G[equip]
    local kind = {}
    if type(slot) == "string" and slot ~= "" then kind[#kind + 1] = slot end
    if type(isub) == "string" and isub ~= "" and isub ~= slot then kind[#kind + 1] = isub
    elseif type(itype) == "string" and itype ~= "" and #kind == 0 then kind[#kind + 1] = itype end
    have = { name = name, link = type(link) == "string" and link or nil,
             quality = type(quality) == "number" and quality or nil,
             icon = icon or IconOf(id), kind = table.concat(kind, " · ") }
    info[id] = have
    LB.names[id] = name
    return have
end

function LB.QualityRGB(q)
    local t = _G.ITEM_QUALITY_COLORS and type(q) == "number" and _G.ITEM_QUALITY_COLORS[q]
    if type(t) == "table" and type(t.r) == "number" then return t.r, t.g, t.b end
    return C.textNormal[1], C.textNormal[2], C.textNormal[3]
end

--------------------------------------------------
-- Wunschliste (je Konto)
--------------------------------------------------

function LB.Store()
    local sv = _G.WeintCodex_SavedData
    if type(sv) ~= "table" then
        -- Nie in eine frische Ersatztabelle schreiben: ohne SavedData nur lesen.
        return { wish = {}, readonly = true }
    end
    local l = sv.loot
    if type(l) ~= "table" then l = {} sv.loot = l end
    l.wish = type(l.wish) == "table" and l.wish or {}
    return l
end

function LB.IsWished(id) return LB.Store().wish[id] ~= nil end

function LB.ToggleWish(id)
    local st = LB.Store()
    if st.readonly or type(id) ~= "number" then return false end
    if st.wish[id] then
        st.wish[id] = nil
        LB.SyncSidebar()
        return false
    end
    local n, bi = LB.SourceOf(id)
    local inst = n and LB.Instance(n)
    local b = n and LB.Bosses(n)[bi]
    local t = _G.time and Plain(_G.time())
    st.wish[id] = { k = inst and inst.key or nil, b = b and b.name or nil, t = type(t) == "number" and t or 0 }
    LB.SyncSidebar()
    return true
end

local function WishStatus()
    local n = 0
    for id in pairs(LB.Store().wish) do if type(id) == "number" then n = n + 1 end end
    return { text = n == 0 and "leer" or (n == 1 and "1 Gegenstand" or (n .. " Gegenstände")), color = n > 0 and "goldBright" or "textFaint" }
end
LB.WishStatus = WishStatus

function LB.WishIds()
    local out = {}
    for id in pairs(LB.Store().wish) do
        if type(id) == "number" then out[#out + 1] = id end
    end
    table.sort(out)
    return out
end

--------------------------------------------------
-- Fraktion: Belohnungen nur einer Seite zeigt die Seite nur dieser Seite
--------------------------------------------------

local function PlayerFaction()
    if not _G.UnitFactionGroup then return nil end
    local ok, f = pcall(_G.UnitFactionGroup, "player")
    f = ok and Plain(f) or nil
    if f == "Alliance" then return "a" elseif f == "Horde" then return "h" end
    return nil
end
LB.PlayerFaction = PlayerFaction

local function Visible(it, faction)
    return not (it.only and faction and it.only ~= faction)
end

--------------------------------------------------
-- Suche: Instanzen, Bosse, Gegenstaende (nur schon geladene Namen)
--------------------------------------------------

local Fold = function(s)
    local SR = WeintCodex.Search
    if SR and SR.Fold then return SR.Fold(s) end
    return tostring(s or ""):lower()
end
LB.Fold = Fold

-- Ergebnis: Liste von Abschnitten { title, inst, boss, items = { it, ... } }
function LB.Sections(cat, instIndex, query)
    local faction = PlayerFaction()
    local q = Fold(query or ""):gsub("^%s+", ""):gsub("%s+$", "")
    local out, total = {}, 0
    local function Push(title, inst, boss, items)
        local vis = {}
        for _, it in ipairs(items) do
            if Visible(it, faction) then vis[#vis + 1] = it end
        end
        if #vis > 0 then
            out[#out + 1] = { title = title, inst = inst, boss = boss, items = vis }
            total = total + #vis
        end
    end
    if q ~= "" then
        for n = 1, LB.Count() do
            local inst = LB.Instance(n)
            local iname = LB.InstanceName(inst)
            local instHit = Fold(iname):find(q, 1, true) or Fold(inst.fallback):find(q, 1, true)
            for _, b in ipairs(LB.Bosses(n)) do
                local bname = LB.BossName(b)
                if instHit or Fold(bname):find(q, 1, true) or Fold(b.name):find(q, 1, true) then
                    Push(iname .. " · " .. bname, inst, b, b.items)
                else
                    local hits = {}
                    for _, it in ipairs(b.items) do
                        local nm = LB.names[it.id]
                        if nm and Fold(nm):find(q, 1, true) then hits[#hits + 1] = it end
                    end
                    if #hits > 0 then Push(iname .. " · " .. bname, inst, b, hits) end
                end
            end
        end
        return out, total
    end
    if cat == "wish" then
        for _, id in ipairs(LB.WishIds()) do
            local n, bi, it = LB.SourceOf(id)
            local inst = n and LB.Instance(n)
            local b = n and LB.Bosses(n)[bi]
            local title = inst and (LB.InstanceName(inst) .. " · " .. LB.BossName(b)) or "Ohne bekannte Herkunft"
            local last = out[#out]
            if last and last.title == title then
                last.items[#last.items + 1] = it or { id = id }
                total = total + 1
            else
                Push(title, inst, b, { it or { id = id } })
            end
        end
        return out, total
    end
    if instIndex then
        local inst = LB.Instance(instIndex)
        for _, b in ipairs(LB.Bosses(instIndex)) do
            Push(LB.BossName(b), inst, b, b.items)
        end
    end
    return out, total
end

-- 6.85.0.0 (Beta-Test: "die Forever-Dungeons stehen ganz unten"): Dungeons
-- nach Stufe sortiert, die neuen dazwischen an ihrem Platz; sonst wie im
-- Bestand.
local function MinLevel(inst)
    return tonumber(tostring(inst and inst.levels or ""):match("^(%d+)")) or 999
end
LB.MinLevel = MinLevel
function LB.InstancesOf(cat)
    local out = {}
    for n = 1, LB.Count() do
        local inst = LB.Instance(n)
        if inst.cat == cat then out[#out + 1] = n end
    end
    if cat == "d" then
        table.sort(out, function(a, b)
            local la, lb = MinLevel(LB.Instance(a)), MinLevel(LB.Instance(b))
            if la ~= lb then return la < lb end
            return a < b
        end)
    end
    return out
end

-- Passender Dungeon des Codex (modules/dungeonpages.lua), ueber den Namen.
function LB.CodexDungeon(inst)
    local DD = WeintCodex.DungeonData
    if not (inst and DD and DD.AllInstances) then return nil end
    local function Norm(s) return (tostring(s or ""):lower():gsub("[^%a]", "")) end
    local k = Norm(inst.key)
    local ok, all = pcall(DD.AllInstances)
    for _, d in ipairs(ok and all or {}) do
        local nm = Norm(d.name)
        if nm ~= "" and (nm == k or nm:sub(1, #k) == k or k:sub(1, #nm) == nm) then return d end
    end
    return nil
end

--------------------------------------------------
-- Seite
--------------------------------------------------

local page
LB.cat, LB.inst, LB.query, LB.selected = "d", nil, "", nil
local LIST_H, HEAD_H = 30, 28
local listPool, cellPool, headPool = {}, {}, {}
local usedList, usedCells, usedHeads = 0, 0, 0

local function ResetPools()
    for _, r in ipairs(listPool) do r:Hide() end
    for _, r in ipairs(cellPool) do r:Hide() end
    for _, r in ipairs(headPool) do r:Hide() end
    usedList, usedCells, usedHeads = 0, 0, 0
end

-- 6.89.1.0 (Beta-Test: "das Suchfeld ist ziemlich unscheinbar"): eine
-- deutliche Pille ueber die ganze Breite, Lupe vorn, Rand in der Akzent-
-- farbe, sobald man tippt. Breite setzt der Aufrufer (TOPLEFT/TOPRIGHT).
local MEDIA_UI = "Interface\\AddOns\\WeintCodex\\media\\ui\\"
local function SearchBox(parent, hintText, onChange)
    local H = 32
    local box = CreateFrame("Frame", nil, parent)
    box:SetHeight(H)
    local function Part(layer, sub)
        local t = box:CreateTexture(nil, layer, nil, sub)
        return t
    end
    -- Rand (eine Spur groesser) und Flaeche, beide als Pille.
    local rim, fill = {}, {}
    for i, set in ipairs({ rim, fill }) do
        local inset = (i == 1) and 0 or 1
        set.mid = Part("BACKGROUND", i)
        set.mid:SetPoint("TOPLEFT", box, "TOPLEFT", H / 2, -inset)
        set.mid:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -H / 2, inset)
        set.l = Part("BACKGROUND", i)
        set.l:SetTexture(MEDIA_UI .. "disc")
        set.l:SetSize(H - 2 * inset, H - 2 * inset)
        set.l:SetPoint("LEFT", box, "LEFT", inset, 0)
        set.r = Part("BACKGROUND", i)
        set.r:SetTexture(MEDIA_UI .. "disc")
        set.r:SetSize(H - 2 * inset, H - 2 * inset)
        set.r:SetPoint("RIGHT", box, "RIGHT", -inset, 0)
    end
    local function Paint(set, c, a)
        set.mid:SetColorTexture(c[1], c[2], c[3], a or 1)
        set.l:SetVertexColor(c[1], c[2], c[3], a or 1)
        set.r:SetVertexColor(c[1], c[2], c[3], a or 1)
    end
    Paint(fill, C.surface2)
    local function Rim(active)
        local c = active and (C.accent or C.borderStrong) or (C.borderStrong or C.surface3)
        Paint(rim, c, active and 1 or 0.9)
    end
    Rim(false)
    local glass = box:CreateTexture(nil, "ARTWORK")
    glass:SetSize(14, 14)
    glass:SetPoint("LEFT", box, "LEFT", 12, 0)
    glass:SetTexture(MEDIA_UI .. "icon_search")
    glass:SetVertexColor(C.textMuted[1], C.textMuted[2], C.textMuted[3])
    local eb = CreateFrame("EditBox", nil, box)
    eb:SetPoint("TOPLEFT", box, "TOPLEFT", 30, 0)
    eb:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -30, 0)
    eb:SetAutoFocus(false)
    eb:SetMaxLetters(40)
    eb:SetFont(WeintCodex.Fonts.sans, 13, "")
    eb:SetTextInsets(4, 4, 0, 0)
    eb:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3])
    eb.hint = WeintCodex.Label(box, hintText, { size = 13, color = "textDim" })
    eb.hint:SetPoint("LEFT", box, "LEFT", 34, 0)
    local clear = CreateFrame("Button", nil, box)
    clear:SetSize(24, 24)
    clear:SetPoint("RIGHT", box, "RIGHT", -6, 0)
    clear.x = WeintCodex.Label(clear, "\195\151", { size = 15, color = "textMuted" })
    clear.x:SetPoint("CENTER", clear, "CENTER", 0, 1)
    clear:SetScript("OnClick", function() eb:SetText("") eb:ClearFocus() end)
    clear:Hide()
    eb:SetScript("OnTextChanged", function(self)
        local t = self:GetText() or ""
        self.hint:SetShown(t == "")
        clear:SetShown(t ~= "")
        Rim(t ~= "" or self:HasFocus())
        onChange(t)
    end)
    eb:SetScript("OnEditFocusGained", function() Rim(true) end)
    eb:SetScript("OnEditFocusLost", function(self) Rim((self:GetText() or "") ~= "") end)
    eb:SetScript("OnEscapePressed", function(self) self:SetText("") self:ClearFocus() end)
    eb:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    -- Klick irgendwo in die Pille setzt den Cursor.
    box:EnableMouse(true)
    box:SetScript("OnMouseDown", function() eb:SetFocus() end)
    return box, eb
end

local function BuildPage()
    if page then return page end
    local cp = WeintCodex.ContentPanel
    local f = CreateFrame("Frame", nil, cp)
    f:SetAllPoints(cp)
    local M = WeintCodex.Metrics
    f.Head = WeintCodex.PageHead(f, {
        eyebrow = "Leveln",
        title   = "Beute",
        sub     = "Was in Dungeons, Schlachtzügen, beim Ruf und im PvP zu holen ist – mit Wunschliste.",
        height  = 84,
    })
    local lc = WeintCodex.CreateSurface(f, { tone = "plain", radius = 14, backdrop = "bgDark" })
    lc:SetPoint("TOPLEFT",    f, "TOPLEFT",    M.PAD_X, -(M.PAD_Y + 84))
    lc:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", M.PAD_X, M.PAD_Y)
    lc:SetWidth(220)
    f.ListCard = lc
    f.ListScroll, f.ListBody = WeintCodex.CreateScrollArea(lc, 12, -14, 196, 300, true)

    local ic = WeintCodex.CreateSurface(f, { tone = "plain", radius = 14, backdrop = "bgDark" })
    ic:SetPoint("TOPLEFT",     lc, "TOPRIGHT", M.GAP, 0)
    ic:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -M.PAD_X, M.PAD_Y)
    f.ItemCard = ic
    local box, eb = SearchBox(ic, "Gegenstand, Boss oder Instanz suchen …", function(t)
        if t == LB.query then return end
        LB.query = t
        LB.Draw()
    end)
    box:SetPoint("TOPLEFT", ic, "TOPLEFT", 18, -14)
    box:SetPoint("TOPRIGHT", ic, "TOPRIGHT", -18, -14)
    f.Search = eb
    -- 6.84.8.0 (Beta-Test mit Bild: der Hinweis lief ueber Suche und Liste):
    -- eigene Zeile unter der Suche, links und rechts begrenzt, einzeilig.
    f.Count = WeintCodex.Label(ic, "", { size = 11, color = "textDim", justify = "LEFT" })
    f.Count:SetPoint("TOPLEFT", ic, "TOPLEFT", 26, -54)
    f.Count:SetPoint("TOPRIGHT", ic, "TOPRIGHT", -18, -54)
    f.Count:SetWordWrap(false)
    f.ItemScroll, f.ItemBody = WeintCodex.CreateScrollArea(ic, 20, -74, 420, 300, true)

    f:SetScript("OnSizeChanged", function(self, width)
        width = Plain(width)
        if self:IsShown() and type(width) == "number" and type(self.drawnWidth) == "number"
           and math.abs(width - self.drawnWidth) > 2 then
            LB.Redraw()
        end
    end)
    page = f
    return f
end

local function ListRow(body, y, w, label, count, active, onClick, indent)
    usedList = usedList + 1
    local r = listPool[usedList]
    if not r then
        r = CreateFrame("Button", nil, body)
        r:SetHeight(LIST_H)
        r.sel = r:CreateTexture(nil, "BACKGROUND")
        r.sel:SetAllPoints(r)
        r.sel:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.16)
        local hl = r:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints(r)
        hl:SetColorTexture(C.textBright[1], C.textBright[2], C.textBright[3], 0.05)
        r.label = WeintCodex.Label(r, "", { size = 12, font = WeintCodex.Fonts.sansMedium })
        r.label:SetWordWrap(false)
        r.count = WeintCodex.Label(r, "", { size = 10, color = "textDim", justify = "RIGHT", font = WeintCodex.Fonts.mono })
        r.count:SetPoint("RIGHT", r, "RIGHT", -6, 0)
        r:SetScript("OnClick", function(self) if self.onClick then self.onClick() end end)
        listPool[usedList] = r
    end
    r:SetParent(body)
    r:ClearAllPoints()
    r:SetPoint("TOPLEFT", body, "TOPLEFT", 0, y)
    r:SetWidth(w)
    r.label:ClearAllPoints()
    r.label:SetPoint("LEFT", r, "LEFT", indent and 16 or 6, 0)
    r.label:SetPoint("RIGHT", r.count, "LEFT", -6, 0)
    r.sel:SetShown(active and true or false)
    r.label:SetText(label)
    local c = active and C.textBright or (indent and C.textNormal or C.textMuted)
    r.label:SetTextColor(c[1], c[2], c[3])
    r.count:SetText(count and tostring(count) or "")
    r.onClick = onClick
    r:Show()
    return y - LIST_H
end

local function Head(body, y, w, text, sub)
    usedHeads = usedHeads + 1
    local h = headPool[usedHeads]
    if not h then
        h = CreateFrame("Frame", nil, body)
        h:SetHeight(HEAD_H)
        h.label = WeintCodex.Label(h, "", { size = 13, color = "textBright", font = WeintCodex.Fonts.sansSemi })
        h.label:SetPoint("BOTTOMLEFT", h, "BOTTOMLEFT", 2, 6)
        h.label:SetWordWrap(false)
        h.sub = WeintCodex.Label(h, "", { size = 10, color = "textFaint", justify = "RIGHT" })
        h.sub:SetPoint("BOTTOMRIGHT", h, "BOTTOMRIGHT", -2, 7)
        h.label:SetPoint("RIGHT", h.sub, "LEFT", -8, 0)
        h.rule = h:CreateTexture(nil, "ARTWORK")
        h.rule:SetHeight(1)
        h.rule:SetPoint("BOTTOMLEFT", h, "BOTTOMLEFT", 0, 0)
        h.rule:SetPoint("BOTTOMRIGHT", h, "BOTTOMRIGHT", 0, 0)
        h.rule:SetColorTexture(C.border[1], C.border[2], C.border[3], C.border[4] or 1)
        headPool[usedHeads] = h
    end
    h:SetParent(body)
    h:ClearAllPoints()
    h:SetPoint("TOPLEFT", body, "TOPLEFT", 0, y)
    h:SetWidth(w)
    h.label:SetText(text)
    h.sub:SetText(sub or "")
    h:Show()
    return y - HEAD_H - 4
end

local QUESTION_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

function LB.PaintCell(r)
    local it = r.item
    local inf = LB.Info(it.id)
    r.icon:SetTexture(inf.icon or QUESTION_ICON)
    if inf.missing then
        r.title:SetText("vom Spiel nicht genannt")
        r.title:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3])
    elseif inf.loading then
        r.title:SetText("lädt …")
        r.title:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3])
    else
        r.title:SetText(inf.name)
        r.title:SetTextColor(LB.QualityRGB(inf.quality))
    end
    local parts = {}
    if inf.kind and inf.kind ~= "" then parts[#parts + 1] = inf.kind end
    if it.rate then parts[#parts + 1] = (tostring(it.rate):gsub("%.", ",")) .. " %" end
    if it.only then parts[#parts + 1] = it.only == "a" and "nur Allianz" or "nur Horde" end
    if LB.KindOf(r.inst, it.id) == "community" then parts[#parts + 1] = WeintCodex.ColorText("textMuted", "neu in Forever") end
    r.sub:SetText(table.concat(parts, "  ·  "))
    local wished = LB.IsWished(it.id)
    local sc = wished and C.goldBright or C.textGhost
    r.star.tex:SetVertexColor(sc[1], sc[2], sc[3], wished and 1 or 0.6)
    r.sel:SetShown(LB.selected == it.id)
    return not inf.loading
end

local function ItemTooltip(self)
    local gt = _G.GameTooltip
    if not gt then return end
    gt:SetOwner(self, "ANCHOR_RIGHT")
    if gt.SetItemByID then
        gt:SetItemByID(self.item.id)
    else
        gt:SetText(LB.names[self.item.id] or "lädt …")
    end
    if self.item.rate then
        gt:AddLine("Dropchance aus Classic: " .. (tostring(self.item.rate):gsub("%.", ",")) .. " %",
            C.textMuted[1], C.textMuted[2], C.textMuted[3])
    end
    gt:AddLine("Umschalt: in den Chat · Strg: anprobieren · Rechtsklick: Wunschliste",
        C.textFaint[1], C.textFaint[2], C.textFaint[3], true)
    gt:Show()
end

function LB.Click(item, button)
    if button == "RightButton" then
        LB.ToggleWish(item.id)
        LB.Draw()
        return "wish"
    end
    local inf = LB.Info(item.id)
    local link = inf.link
    if link and _G.IsModifiedClick and _G.IsModifiedClick("CHATLINK") and _G.ChatEdit_InsertLink then
        _G.ChatEdit_InsertLink(link)
        return "link"
    end
    if link and _G.IsModifiedClick and _G.IsModifiedClick("DRESSUP") and _G.DressUpItemLink then
        _G.DressUpItemLink(link)
        return "dressup"
    end
    LB.selected = item.id
    LB.Draw()
    return "select"
end

local function Cell(body, x, y, w, it, inst)
    usedCells = usedCells + 1
    local r = cellPool[usedCells]
    if not r then
        r = CreateFrame("Button", nil, body)
        r:SetHeight(LB.CELL_H)
        r.sel = r:CreateTexture(nil, "BACKGROUND")
        r.sel:SetAllPoints(r)
        r.sel:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.14)
        local hl = r:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints(r)
        hl:SetColorTexture(C.textBright[1], C.textBright[2], C.textBright[3], 0.05)
        r.icon = r:CreateTexture(nil, "ARTWORK")
        r.icon:SetSize(28, 28)
        r.icon:SetPoint("LEFT", r, "LEFT", 4, 0)
        r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        r.star = CreateFrame("Button", nil, r)
        r.star:SetSize(22, 22)
        r.star:SetPoint("RIGHT", r, "RIGHT", -4, 0)
        -- 6.84.8.0 (Beta-Test mit Bild: "?" statt Stern - die Schrift kennt
        -- das Zeichen nicht): eigenes Bild media/ui/star.tga.
        r.star.tex = r.star:CreateTexture(nil, "ARTWORK")
        r.star.tex:SetSize(14, 14)
        r.star.tex:SetPoint("CENTER", r.star, "CENTER", 0, 0)
        r.star.tex:SetTexture("Interface\\AddOns\\WeintCodex\\media\\ui\\star")
        r.star:SetScript("OnClick", function(self)
            LB.ToggleWish(self:GetParent().item.id)
            LB.Draw()
        end)
        r.title = WeintCodex.Label(r, "", { size = 12, font = WeintCodex.Fonts.sansMedium })
        r.title:SetPoint("TOPLEFT", r.icon, "TOPRIGHT", 8, 0)
        r.title:SetPoint("RIGHT", r.star, "LEFT", -6, 0)
        r.title:SetWordWrap(false)
        r.sub = WeintCodex.Label(r, "", { size = 10, color = "textFaint" })
        r.sub:SetPoint("TOPLEFT", r.title, "BOTTOMLEFT", 0, -3)
        r.sub:SetPoint("RIGHT", r.star, "LEFT", -6, 0)
        r.sub:SetWordWrap(false)
        if r.RegisterForClicks then r:RegisterForClicks("LeftButtonUp", "RightButtonUp") end
        r:SetScript("OnClick", function(self, button) LB.Click(self.item, button) end)
        r:SetScript("OnEnter", ItemTooltip)
        r:SetScript("OnLeave", function() if _G.GameTooltip then _G.GameTooltip:Hide() end end)
        cellPool[usedCells] = r
    end
    r:SetParent(body)
    r:ClearAllPoints()
    r:SetPoint("TOPLEFT", body, "TOPLEFT", x, y)
    r:SetWidth(w)
    r.item, r.inst = it, inst
    LB.PaintCell(r)
    r:Show()
    return r
end

-- Detailbereich: der gewaehlte Gegenstand, sonst die Instanz.
function LB.InspectorBlocks()
    local S = WeintCodex.Sources
    local id = LB.selected
    if id then
        local n, bi, it = LB.SourceOf(id)
        local inst = n and LB.Instance(n)
        local b = n and LB.Bosses(n)[bi]
        local inf = LB.Info(id)
        local src = LB.Source(LB.KindOf(inst, id))
        local rows = {
            { label = "Fundort", value = inst and LB.InstanceName(inst) or "unbekannt" },
            { label = "Boss / Gruppe", value = b and LB.BossName(b) or "unbekannt" },
            { label = "Dropchance", value = (it and it.rate) and ((tostring(it.rate):gsub("%.", ",")) .. " % (Classic)") or "unbekannt" },
            { label = "Herkunft", value = src and S.Prefix(src) or "—" },
        }
        if inf.kind and inf.kind ~= "" then table.insert(rows, 1, { label = "Art", value = inf.kind }) end
        local blocks = {
            { type = "header", text = inf.name or "lädt …" },
            { type = "rows", rows = rows },
            { type = "button", label = LB.IsWished(id) and "Von der Wunschliste nehmen" or "Auf die Wunschliste",
              style = "primary", onClick = function() LB.ToggleWish(id) LB.Draw() end },
        }
        if inf.link and _G.DressUpItemLink then
            blocks[#blocks + 1] = { type = "button", label = "Anprobieren", onClick = function() _G.DressUpItemLink(inf.link) end }
        end
        blocks[#blocks + 1] = { type = "button", label = "Auswahl aufheben", onClick = function() LB.selected = nil LB.Draw() end }
        blocks[#blocks + 1] = { type = "divider" }
        blocks[#blocks + 1] = { type = "text", text = (src and S.Why and S.Why(src)) or "" }
        return blocks
    end
    local inst = LB.inst and LB.Instance(LB.inst)
    local blocks = {
        { type = "header", text = "Beute" },
        { type = "rows", rows = {
            { label = "Bereiche im Bestand", value = tostring(LB.Count()) },
            { label = "Auf deiner Wunschliste", value = tostring(#LB.WishIds()) },
            -- 6.84.9.0: welcher Weg des Clients Namen liefert (zum Messen).
            { label = "Namen vom Client", value = string.format("Info %d · Nummer %d · Tooltip %d · Objekt %d · keine %d",
                LB.diag.byInfo, LB.diag.byName, LB.diag.byTooltip, LB.diag.byObject, LB.diag.missing or 0) },
        }},
    }
    if inst and LB.cat ~= "wish" then
        local bosses = LB.Bosses(LB.inst)
        local n = 0
        for _, b in ipairs(bosses) do n = n + #b.items end
        local src = LB.Source(inst.kind)
        blocks[#blocks + 1] = { type = "header", text = LB.InstanceName(inst) }
        local rows = {
            { label = (inst.cat == "f" and "Stufen") or (inst.cat == "s" and "Sets") or "Bosse / Gruppen", value = tostring(#bosses) },
            { label = "Gegenstände", value = tostring(n) },
            { label = "Herkunft", value = src and S.Prefix(src) or "—" },
        }
        if inst.levels then table.insert(rows, 1, { label = "Stufenbereich", value = inst.levels }) end
        blocks[#blocks + 1] = { type = "rows", rows = rows }
        local cd = inst.cat == "d" and LB.CodexDungeon(inst)
        local DP = WeintCodex.DungeonPages
        if cd and DP and DP.Select then
            blocks[#blocks + 1] = { type = "button", label = "Zum Dungeon im Codex",
                onClick = function()
                    DP.Select(cd.id)
                    local nav = WeintCodex.Navigation
                    if nav and nav.GoToTab then nav.GoToTab("dungeons") end
                end }
        end
        blocks[#blocks + 1] = { type = "divider" }
        blocks[#blocks + 1] = { type = "text", text = (src and S.Why and S.Why(src)) or "" }
    end
    blocks[#blocks + 1] = { type = "header", text = "Woher das stammt" }
    blocks[#blocks + 1] = { type = "card", lines = {
        "Aus Classic: Bosse, Beute und Dropchancen – Forever",
        "hat die Beute überarbeitet. Neue Inhalte von Forever:",
        "unbestätigt. Namen, Bilder und Werte liefert dein Client.",
    }}
    return blocks
end

function LB.Draw()
    local f = BuildPage()
    local cp = WeintCodex.ContentPanel
    for _, child in pairs({ cp:GetChildren() }) do if child ~= f then child:Hide() end end
    f:Show()
    local inst = LB.inst and LB.Instance(LB.inst)
    if inst and inst.cat ~= LB.cat then LB.inst, inst = nil, nil end
    if not inst and LB.cat ~= "wish" then
        LB.inst = LB.InstancesOf(LB.cat)[1]
        inst = LB.inst and LB.Instance(LB.inst)
    end
    local catLabel
    for _, c in ipairs(LB.CATEGORIES) do if c.key == LB.cat then catLabel = c.label end end
    if inst and LB.cat ~= "wish" then
        WeintCodex.SetBreadcrumb("Beute", catLabel, LB.InstanceName(inst))
    else
        WeintCodex.SetBreadcrumb("Beute", catLabel)
    end
    WeintCodex.Navigation.SetInspector(LB.InspectorBlocks())

    local total = Plain(f:GetWidth())
    local lh = (Plain(f.ListCard:GetHeight()) or 360) - 28
    local iw = (Plain(f.ItemCard:GetWidth()) or 460) - 40
    local ih = (Plain(f.ItemCard:GetHeight()) or 360) - 90
    f.ListScroll:SetSize(196, math.max(60, lh))
    f.ListBody:SetWidth(186)
    f.ItemScroll:SetSize(iw, math.max(60, ih))
    f.ItemBody:SetWidth(iw - 10)

    ResetPools()
    -- Links: die Bereiche der Rubrik (Rubriken stehen in der Unternavigation).
    local y = 0
    if LB.cat == "wish" then
        y = ListRow(f.ListBody, y, 186, "Alle Wünsche", #LB.WishIds(), LB.query == "", function()
            LB.selected = nil
            if f.Search and LB.query ~= "" then LB.query = "" f.Search:SetText("") end
            LB.Draw()
        end)
    else
        for _, n in ipairs(LB.InstancesOf(LB.cat)) do
            local i2 = LB.Instance(n)
            local sub = i2.levels
            if i2.kind == "community" then
                sub = ((sub and sub ~= "") and (sub .. " · ") or "") .. "Forever neu"
            end
            y = ListRow(f.ListBody, y, 186, LB.InstanceName(i2), sub, LB.inst == n and LB.query == "", function()
                LB.inst, LB.selected = n, nil
                if f.Search and LB.query ~= "" then LB.query = "" f.Search:SetText("") end
                LB.Draw()
            end)
        end
    end
    f.ListBody:SetHeight(math.max(1, -y))

    -- Rechts: Abschnitte je Boss, darin ein Raster, Spalten aus der Breite.
    local sections, count = LB.Sections(LB.cat, LB.inst, LB.query)
    local bw = iw - 14
    local cols = math.max(1, math.floor((bw + 8) / (LB.CELL_MIN_W + 8)))
    local cw = math.floor((bw - (cols - 1) * 8) / cols)
    local by, drawn = 0, 0
    for _, sec in ipairs(sections) do
        if drawn >= LB.MAX_CELLS then break end
        local src = LB.Source(sec.inst and sec.inst.kind or "classic")
        local S = WeintCodex.Sources
        by = Head(f.ItemBody, by, bw, sec.title, src and S and S.Prefix(src) or nil)
        local col = 0
        for _, it in ipairs(sec.items) do
            if drawn >= LB.MAX_CELLS then break end
            Cell(f.ItemBody, col * (cw + 8), by, cw, it, sec.inst)
            drawn = drawn + 1
            col = col + 1
            if col >= cols then col = 0 by = by - LB.CELL_H - 4 end
        end
        if col > 0 then by = by - LB.CELL_H - 4 end
        by = by - 8
    end
    f.ItemBody:SetHeight(math.max(1, -by))
    if count == 0 then
        f.Count:SetText(LB.query ~= "" and "Nichts gefunden – Namen kennt die Suche erst, wenn der Client sie geladen hat"
            or LB.cat == "wish" and "Noch nichts gewünscht – Rechtsklick oder Stern setzt einen Gegenstand drauf"
            or "Für diesen Bereich ist keine Beute hinterlegt")
    elseif count > drawn then
        f.Count:SetText(drawn .. " von " .. count .. " – Suche grenzt ein")
    else
        f.Count:SetText(count == 1 and "1 Gegenstand" or (count .. " Gegenstände"))
    end
    f.drawnWidth = total
    LB.lastDraw = { cells = usedCells, sections = #sections, total = count, cols = cols, list = usedList }
end

function LB.Page() return page end

-- Unternavigation: die Rubriken. Die Wunschliste zaehlt mit.
function LB.SyncSidebar()
    local nav = WeintCodex.Navigation
    if page and page:IsShown() and nav and nav.UpdateSidebarStatus then
        nav.UpdateSidebarStatus(1, WishStatus())
    end
end

function LB.SidebarItems()
    local items = {}
    for _, c in ipairs(LB.CATEGORIES) do
        local status
        if c.key == "wish" then
            status = WishStatus()
        else
            local n = #LB.InstancesOf(c.key)
            status = n == 1 and "1 Bereich" or (n .. " Bereiche")
        end
        items[#items + 1] = { label = c.label, status = status, onClick = function()
            if LB.cat ~= c.key then LB.inst = nil end
            LB.cat, LB.selected = c.key, nil
            if page and page.Search and LB.query ~= "" then LB.query = "" page.Search:SetText("") end
            LB.Draw()
        end }
    end
    return items
end

function LB.Show()
    local nav = WeintCodex.Navigation
    nav.BuildSidebar("Beute", LB.SidebarItems())
    local active = 1
    for i, c in ipairs(LB.CATEGORIES) do if c.key == LB.cat then active = i end end
    -- ActivateIndex klickt die Rubrik: die setzt die Suche zurueck. Eine
    -- Auswahl von aussen (LB.Open) bleibt erhalten.
    local keepInst, keepSel = LB.inst, LB.selected
    nav.ActivateIndex(active)
    LB.inst, LB.selected = keepInst, keepSel
    LB.Draw()
end

-- Von aussen: Bereich (Schluessel) aufschlagen, optional einen Gegenstand.
function LB.Open(key, itemID)
    local n = key and LB.FindInstance(key)
    if n then LB.cat, LB.inst = LB.Instance(n).cat, n end
    LB.query, LB.selected = "", itemID
    if page and page.Search then page.Search:SetText("") end
end

local queued = false
function LB.Redraw()
    if queued or not (page and page:IsShown()) then return end
    queued = true
    local function run() queued = false if page and page:IsShown() then LB.Draw() end end
    if _G.C_Timer and _G.C_Timer.After then _G.C_Timer.After(0.3, run) else run() end
end

-- Der Client hat einen Namen nachgeliefert: die sichtbaren Zellen neu
-- malen (gebuendelt, nie je Ereignis eine ganze Zeichnung).
local ev = CreateFrame("Frame")
pcall(ev.RegisterEvent, ev, "GET_ITEM_INFO_RECEIVED")
ev:SetScript("OnEvent", function(_, _, itemID)
    itemID = Plain(itemID)
    if not pending[itemID] then return end
    pending[itemID] = nil
    if page and page:IsShown() then LB.Redraw() end
end)
LB.events = ev
