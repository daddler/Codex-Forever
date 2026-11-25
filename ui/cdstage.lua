--------------------------------------------------
-- WeintCodex :: Oberflaeche - Buehne des Abklingzeitmanagers (1.0.9.0)
--------------------------------------------------
-- Wunsch des Spielers: "Ich mache den Abklingzeitenmanager auf und sehe
-- erstmal, wie es bisher aufgebaut ist und was zur Zeit angezeigt wird.
-- Per Drag & Drop einzelne Faehigkeiten direkt in die jeweilige Leiste
-- ziehen - das wird so uebernommen." Und nach dem ersten Wurf: "grund-
-- saetzlich neu. Alles individuell einstellbar. Faehigkeiten in die Leiste
-- ziehen und/oder den Ausloeser und die Laufzeit per Balken noch mal
-- separat. Alles soll oben einsehbar sein, wie es gerade aussieht. Bisher
-- ist das Einzustellende viel zu weit unten. Auch die Balken in Groesse,
-- senkrecht oder waagerecht etc." Vorbild fuer die Vorschau: die der
-- Namensplaketten; fuer Auswahl und Einstellen: WeakAuras (Verhalten,
-- kein Code).
--
-- DREI TEILE, eine Seite (ui/cooldowns.lua):
--   Buehne   - fest OBEN ueber dem Bildlauf (Vorschau je Seite,
--              ui/options.lua): jede Reihe GENAU SO, wie sie im Spiel
--              steht, mit laufenden Uhren; dieselben Teile, gezeichnet von
--              OC.DrawSpells (row._preview: kein Ton, nichts gemerkt).
--              Passt sie nicht, wird sie als Ganzes verkleinert.
--   Auswahl  - gleich darunter: Klick auf eine Faehigkeit oder den Kopf
--              einer Reihe, und hier stehen ALLE ihre Einstellungen.
--   Vorrat   - was gerade nicht gezeigt wird.
--
-- BEDIENUNG. Ziehen: an eine Stelle einer Reihe (eine Marke zeigt, wo es
-- landet) oder in den Vorrat (ausblenden). Mit gedrueckter Umschalttaste
-- ziehen: nur einen Laufzeit-Balken dorthin legen - das Symbol bleibt.
-- Einen Laufzeit-Balken ziehen: ihn verlegen; in den Vorrat: weg.
-- Klick: auswaehlen. Rechtsklick: Schnellmenue. Aus Zauberbuch oder
-- Taschen auf eine Reihe ziehen: hinzufuegen, genau dorthin.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UICooldownStage = {}

local ST = WeintCodex.UICooldownStage
local OC = WeintCodex.UIOwnCooldowns
local K = WeintCodex.UIKit
local C = WeintCodex.Colors

ST.PAD = 10
ST.HEAD = 24
ST.GAP = 6          -- zwischen den Bahnen
ST.POOL_ICON = 30
ST.POOL_GAP = 4
ST.MIN_ROW = 24     -- Hoehe einer leeren Reihe
ST.MIN_SCALE = 0.5
ST.OFF_H = 44       -- Hoehe der Buehne, wenn ein anderer Manager gewaehlt ist

local function Say(msg) print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " " .. msg) end

-- Reihen mit Zaubern (ohne "Aus").
local slotsOut = {}
function ST.SpellSlots()
    for i = #slotsOut, 1, -1 do slotsOut[i] = nil end
    for _, sl in ipairs(OC.Slots()) do
        if sl ~= "off" then slotsOut[#slotsOut + 1] = sl end
    end
    return slotsOut
end

function ST.Entries(slot)
    local out = {}
    for _, e in ipairs(OC.known) do
        if OC.Slot(e) == slot then out[#out + 1] = e end
    end
    return out
end

function ST.EntryByKey(key)
    if not key then return nil end
    for _, e in ipairs(OC.known) do if e.key == key then return e end end
    return nil
end

function ST.Scale(w, avail)
    if not (w and w > 0) then return 1 end
    return math.min(1, avail / w)
end

function ST.PoolPer(width)
    return math.max(1, math.floor((width - 2 * ST.PAD + ST.POOL_GAP) / (ST.POOL_ICON + ST.POOL_GAP)))
end

function ST.PoolHeight(width)
    local n = #ST.Entries("off")
    local lines = math.max(1, math.ceil(n / ST.PoolPer(width)))
    return ST.HEAD + lines * (ST.POOL_ICON + ST.POOL_GAP) + ST.PAD
end

--------------------------------------------------
-- Auswahl
--------------------------------------------------
-- ST.sel = { kind = "row", id = Reihe } oder { kind = "entry", id = Schluessel }.
ST.sel = { kind = "row", id = "big" }

function ST.SelEntry()
    if ST.sel.kind ~= "entry" then return nil end
    return ST.EntryByKey(ST.sel.id)
end

function ST.SelRow()
    if ST.sel.kind ~= "row" then return nil end
    local id = ST.sel.id
    for _, sl in ipairs(ST.SpellSlots()) do if sl == id then return id end end
    return nil
end

function ST.Select(kind, id)
    if kind == "entry" and not ST.EntryByKey(id) then kind, id = "row", "big" end
    if kind == "row" then
        local ok = false
        for _, sl in ipairs(ST.SpellSlots()) do if sl == id then ok = true end end
        if not ok then id = "big" end
    end
    ST.sel.kind, ST.sel.id = kind, id
    if ST.current then ST.ShowSelection(ST.current) end
    if ST.inspector then ST.inspector.Sync() end
end

--------------------------------------------------
-- Treffer und Ziel beim Ziehen
--------------------------------------------------

local function Cursor(fr)
    local x, y = _G.GetCursorPosition()
    local sc = fr:GetEffectiveScale() or 1
    return x / sc, y / sc
end

local function Hit(fr)
    if not (fr and fr:IsShown() and _G.GetCursorPosition) then return false end
    local x, y = Cursor(fr)
    local l, r, t, b = fr:GetLeft(), fr:GetRight(), fr:GetTop(), fr:GetBottom()
    if not (l and r and t and b) then return false end
    return x >= l and x <= r and y >= b and y <= t
end
ST.Hit = Hit

-- Liegt der Vorrat dort, wo die Maus ist, und ist er dort auch zu sehen
-- (nicht aus dem Bildlauf gerollt)?
local function PoolHit(pool)
    if not Hit(pool) then return false end
    local clip = pool.clip
    if clip and not Hit(clip) then return false end
    return true
end

-- Wohin faellt, was gerade gezogen wird? slot, beforeKey, Teil fuer die
-- Marke, "vor"/"nach". Naechstes Teil der Reihe nach Abstand; links bzw.
-- oberhalb seiner Mitte: davor, sonst dahinter (vor dem naechsten).
-- track: ein Laufzeit-Balken wird gezogen - dann zaehlen nur Laufzeit-
-- Balken als Nachbarn, sonst nur Symbole und Balken der Reihe.
function ST.Target(stage, dragKey, track)
    if not stage then return nil end
    for _, lane in ipairs(stage.lanes) do
        if Hit(lane) then
            local row = lane.row
            local items = row.items or {}
            local vert = OC.RowOpt(lane.slot, "vertical") and true or false
            local rev = OC.RowOpt(lane.slot, "reverse") and true or false
            local function fits(b)
                return b:IsShown() and b._e and b._e.key ~= dragKey and ((b._track and true or false) == (track and true or false))
            end
            local best, bestD, bestI
            local x, y = Cursor(row)
            for i, b in ipairs(items) do
                if fits(b) then
                    local l, r, t, bo = b:GetLeft(), b:GetRight(), b:GetTop(), b:GetBottom()
                    if l and r and t and bo then
                        local cx, cy = (l + r) / 2, (t + bo) / 2
                        local d = (x - cx) ^ 2 + (y - cy) ^ 2
                        if not bestD or d < bestD then best, bestD, bestI = b, d, i end
                    end
                end
            end
            if not best then return lane.slot, nil, nil, nil end
            local l, r, t, bo = best:GetLeft(), best:GetRight(), best:GetTop(), best:GetBottom()
            local before
            if vert then before = y > (t + bo) / 2 else before = x < (l + r) / 2 end
            if rev then before = not before end
            if before then return lane.slot, best._e.key, best, "before" end
            -- dahinter: vor dem naechsten der Reihe (nicht dem gezogenen)
            for j = bestI + 1, #items do
                local o = items[j]
                if fits(o) and o._e.key ~= best._e.key then return lane.slot, o._e.key, best, "after" end
            end
            return lane.slot, nil, best, "after"
        end
    end
    if stage.pool and PoolHit(stage.pool) then return "off", nil, nil, nil end
    return nil
end

--------------------------------------------------
-- Aenderungen je Faehigkeit
--------------------------------------------------

function OC.SetRank(e, r)
    local m = OC.Mem()
    if not (m and e.ranks) then return end
    m.rank[e.key] = (r ~= e.ranks[#e.ranks]) and r or nil
    e.id = r
    OC.Scan()
    OC.Refresh()
end
function OC.SetGlow(e, v)
    local m = OC.Mem()
    if not m then return end
    m.glowOf[e.key] = v
    OC.Refresh()
end
function OC.SetSoundWhen(e, v)
    local m = OC.Mem()
    if not m then return end
    m.soundWhen = m.soundWhen or {}
    m.soundWhen[e.key] = v
end

-- Wo Laufzeit-Balken stehen koennen: "daneben" und jede Reihe.
function ST.TrackItems(e)
    local out = { { value = "none", text = "Nein" } }
    if e and OC.Slot(e) ~= "off" then out[#out + 1] = { value = "self", text = "Direkt neben der Fähigkeit" } end
    for _, sl in ipairs(ST.SpellSlots()) do
        out[#out + 1] = { value = sl, text = "In Reihe „" .. OC.SlotText(sl) .. "“" }
    end
    return out
end

function ST.WhatItems(e)
    if e and OC.HasEffect(e) then
        return { { value = "effect", text = OC.TRACK_WHAT_TEXT.effect }, { value = "both", text = OC.TRACK_WHAT_TEXT.both },
                 { value = "cd", text = OC.TRACK_WHAT_TEXT.cd } }
    end
    return { { value = "cd", text = OC.TRACK_WHAT_TEXT.cd } }
end

-- Schnellmenue (Rechtsklick auf der Buehne).
function ST.Menu(owner, e)
    local MU = _G.MenuUtil
    if not (MU and MU.CreateContextMenu and e) then return false end
    MU.CreateContextMenu(owner, function(_, root)
        if root.CreateTitle then root:CreateTitle(e.rank and (e.name .. " (" .. e.rank .. ")") or e.name) end
        local disp = root:CreateButton("Darstellung: " .. OC.DISPLAY_TEXT[OC.Display(e)])
        for _, v in ipairs({ "icon", "bar" }) do
            disp:CreateRadio(OC.DISPLAY_TEXT[v], function() return OC.Display(e) == v end,
                function() OC.SetDisplay(e, v) OC.Relayout() end)
        end
        local tr = root:CreateButton("Laufzeit als eigener Balken")
        for _, it in ipairs(ST.TrackItems(e)) do
            local v = it.value
            tr:CreateRadio(it.text, function() return (OC.Track(e) or "none") == v end,
                function() OC.SetTrack(e, v ~= "none" and v or nil) OC.Relayout() ST.Select("entry", e.key) end)
        end
        local rw = root:CreateButton("Reihe: " .. OC.SlotText(OC.Slot(e)))
        for _, sl in ipairs(OC.Slots()) do
            local s2 = sl
            rw:CreateRadio(OC.SlotText(s2), function() return OC.Slot(e) == s2 end,
                function() OC.Place(e.key, s2, nil) OC.Relayout() end)
        end
        root:CreateButton("Alle Einstellungen …", function() ST.Select("entry", e.key) end)
        if e.custom then root:CreateButton("Entfernen", function() OC.Remove(e) OC.Relayout() end) end
    end)
    return true
end

--------------------------------------------------
-- Ziehen
--------------------------------------------------

local drag = { key = nil, stage = nil, track = false }
ST.drag = drag

-- track: einen Laufzeit-Balken ziehen (oder mit Umschalttaste einen anlegen).
function ST.Begin(stage, e, track)
    if not (stage and e) then return end
    drag.key, drag.stage, drag.track = e.key, stage, track and true or false
    OC.GhostStart(e, nil)
    stage.mark:Hide()
end

-- Marke und Hervorhebung, waehrend gezogen wird (OnUpdate der Buehne).
function ST.Track(stage)
    if not drag.key then return end
    local slot, _, item, side = ST.Target(stage, drag.key, drag.track)
    local mark = stage.mark
    mark:ClearAllPoints()
    if item then
        local vert = OC.RowOpt(slot, "vertical") and true or false
        if OC.RowOpt(slot, "reverse") then side = (side == "before") and "after" or "before" end
        if vert then
            mark:SetHeight(2)
            if side == "before" then
                mark:SetPoint("BOTTOMLEFT", item, "TOPLEFT", 0, 1)
                mark:SetPoint("BOTTOMRIGHT", item, "TOPRIGHT", 0, 1)
            else
                mark:SetPoint("TOPLEFT", item, "BOTTOMLEFT", 0, -1)
                mark:SetPoint("TOPRIGHT", item, "BOTTOMRIGHT", 0, -1)
            end
        else
            mark:SetWidth(2)
            if side == "before" then
                mark:SetPoint("TOPRIGHT", item, "TOPLEFT", -1, 0)
                mark:SetPoint("BOTTOMRIGHT", item, "BOTTOMLEFT", -1, 0)
            else
                mark:SetPoint("TOPLEFT", item, "TOPRIGHT", 1, 0)
                mark:SetPoint("BOTTOMLEFT", item, "BOTTOMRIGHT", 1, 0)
            end
        end
        mark:Show()
    else
        mark:Hide()
    end
    for _, lane in ipairs(stage.lanes) do lane.hot:SetShown(slot == lane.slot) end
    if stage.pool then stage.pool.hot:SetShown(slot == "off") end
end

function ST.Finish()
    local stage, key, track = drag.stage, drag.key, drag.track
    drag.key, drag.stage, drag.track = nil, nil, false
    OC.GhostStop()
    if not (stage and key) then return false end
    stage.mark:Hide()
    for _, lane in ipairs(stage.lanes) do lane.hot:Hide() end
    if stage.pool then stage.pool.hot:Hide() end
    local slot, before = ST.Target(stage, key, track)
    if not slot then return false end
    if track then
        OC.PlaceTrack(key, slot, before)
    else
        OC.Place(key, slot, before)
    end
    OC.Relayout()
    ST.Select("entry", key)
    return true
end

-- Aus Zauberbuch oder Taschen auf die Buehne: hinzufuegen und dorthin.
function ST.DropCursor(stage)
    local c = OC.FromCursor()
    if not c then return false end
    local key
    for _, e in ipairs(OC.known) do
        local same = (e.item and true or false) == (c.kind == "item") and e.id == c.id
        if not same and e.ranks and c.kind == "spell" then
            for _, r in ipairs(e.ranks) do if r == c.id then same = true end end
        end
        if same then key = e.key break end
    end
    if not key then
        if not OC.Add(c) then Say("Konnte nicht hinzugefügt werden.") return false end
        key = (c.kind == "item" and "i:" or "s:") .. c.id
    end
    if _G.ClearCursor then _G.ClearCursor() end
    local slot, before = ST.Target(stage, key)
    OC.Place(key, slot or "small", before)
    OC.Relayout()
    ST.Select("entry", key)
    return true
end

local function Shift()
    return _G.IsShiftKeyDown and K.Bool(_G.IsShiftKeyDown(), false) or false
end

-- Jedes Teil der Buehne (Symbol, Balken, Vorrat) nimmt die Maus.
function ST.Attach(stage, b)
    b:EnableMouse(true)
    if b.RegisterForDrag then b:RegisterForDrag("LeftButton") end
    b:SetScript("OnDragStart", function(self)
        if not self._e then return end
        self:SetAlpha(0.35)
        local track = self._track and true or Shift()
        ST.Begin(stage, self._e, track)
    end)
    b:SetScript("OnDragStop", function(self)
        self:SetAlpha(1)
        ST.Finish()
    end)
    b:SetScript("OnMouseUp", function(self, button)
        if drag.key or not self._e then return end
        if OC.FromCursor() then ST.DropCursor(stage) return end
        if button == "RightButton" then ST.Menu(self, self._e) return end
        ST.Select("entry", self._e.key)
    end)
    b:SetScript("OnReceiveDrag", function() ST.DropCursor(stage) end)
    b:SetScript("OnEnter", function(self)
        local tt, e = _G.GameTooltip, self._e
        if not (tt and e) then return end
        tt:SetOwner(self, "ANCHOR_RIGHT")
        if e.item then pcall(tt.SetItemByID, tt, e.id) else pcall(tt.SetSpellByID, tt, e.id) end
        tt:AddLine(" ")
        if self._track then
            tt:AddLine("Laufzeit-Balken (" .. OC.TRACK_WHAT_TEXT[self._track] .. ")", 1, 1, 1)
            tt:AddLine("Ziehen: in eine andere Reihe oder an eine andere Stelle · in den Vorrat: entfernen · Klick: Einstellungen", 0.6, 0.6, 0.65, true)
        else
            tt:AddLine("Klick: auswählen, Einstellungen darunter · Ziehen: verschieben · Umschalt + Ziehen: nur einen Laufzeit-Balken dorthin · Rechtsklick: Schnellmenü", 0.6, 0.6, 0.65, true)
        end
        tt:Show()
    end)
    b:SetScript("OnLeave", function() if _G.GameTooltip then _G.GameTooltip:Hide() end end)
end

--------------------------------------------------
-- Bahnen
--------------------------------------------------

local function Lane(stage, slot)
    local lane = CreateFrame("Button", nil, stage)
    lane.slot = slot
    local bg = lane:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(lane)
    bg:SetColorTexture(unpack(C.surface1))
    local a = C.accent
    lane.sel = lane:CreateTexture(nil, "BORDER")
    lane.sel:SetAllPoints(lane)
    lane.sel:SetColorTexture(a[1], a[2], a[3], 0.07)
    lane.sel:Hide()
    lane.edge = lane:CreateTexture(nil, "ARTWORK")
    lane.edge:SetPoint("TOPLEFT", lane, "TOPLEFT", 0, 0)
    lane.edge:SetPoint("BOTTOMLEFT", lane, "BOTTOMLEFT", 0, 0)
    lane.edge:SetWidth(2)
    lane.edge:SetColorTexture(a[1], a[2], a[3], 1)
    lane.edge:Hide()
    lane.hot = lane:CreateTexture(nil, "BORDER")
    lane.hot:SetAllPoints(lane)
    lane.hot:SetColorTexture(a[1], a[2], a[3], 0.14)
    lane.hot:Hide()
    lane.head = K.NewText(lane, 12)
    lane.head:SetPoint("TOPLEFT", lane, "TOPLEFT", ST.PAD, -6)
    lane.head:SetTextColor(unpack(C.textBright))
    lane.menu = K.NewText(lane, 11)
    lane.menu:SetPoint("TOPRIGHT", lane, "TOPRIGHT", -ST.PAD, -7)
    lane.menu:SetTextColor(unpack(C.textMuted))
    lane.menu:SetText("Reihe einstellen ›")
    lane:EnableMouse(true)
    lane:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    lane:SetScript("OnClick", function(self, button)
        if OC.FromCursor() then ST.DropCursor(stage) return end
        if button == "RightButton" then OC.RowMenu(self, slot) return end
        ST.Select("row", slot)
    end)
    lane:SetScript("OnReceiveDrag", function() ST.DropCursor(stage) end)
    lane.empty = K.NewText(lane, 11)
    lane.empty:SetPoint("TOP", lane, "TOP", 0, -ST.HEAD - 4)
    lane.empty:SetTextColor(unpack(C.textMuted))
    lane.empty:SetText("Leer – zieh Fähigkeiten hierher.")
    lane.empty:Hide()
    -- Die Reihe selbst - gezeichnet wie im Spiel.
    local row = CreateFrame("Frame", nil, lane)
    row.icons, row.items, row.bars = {}, {}, {}
    row._preview = true
    row.onNew = function(b) ST.Attach(stage, b) end
    row:SetFrameLevel(lane:GetFrameLevel() + 2)
    lane.row = row
    return lane
end

-- Bahn zeichnen; liefert ihre Hoehe bei dieser Breite.
function ST.DrawLane(lane, width)
    local slot, row = lane.slot, lane.row
    local size = tonumber(OC.RowOpt(slot, "size")) or 32
    OC.DrawSpells(row, slot, size, true)
    local nMain, nTrack = 0, 0
    for _, b in ipairs(row.items) do
        if b._e then if b._track then nTrack = nTrack + 1 else nMain = nMain + 1 end end
    end
    local n = nMain + nTrack
    local w = n > 0 and (row:GetWidth() or size) or size
    local h = n > 0 and (row:GetHeight() or size) or 0
    local sc = ST.Scale(w, width - 2 * ST.PAD)
    if row._sc ~= sc then row._sc = sc row:SetScale(sc) end
    row:ClearAllPoints()
    row:SetPoint("TOP", lane, "TOP", 0, -ST.HEAD / sc)
    local label = OC.SlotText(slot) .. "  ·  " .. nMain .. (nMain == 1 and " Fähigkeit" or " Fähigkeiten")
    if nTrack > 0 then label = label .. "  ·  " .. nTrack .. " Laufzeit-Balken" end
    if sc < 1 then label = label .. string.format("  ·  verkleinert (%d %%)", math.floor(sc * 100 + 0.5)) end
    if lane._label ~= label then lane._label = label lane.head:SetText(label) end
    lane.empty:SetShown(n == 0)
    return ST.HEAD + math.max(ST.MIN_ROW, math.ceil(h * sc)) + ST.PAD
end

-- Bahnen an ihren Platz, fehlende anlegen, die geloeschter Reihen
-- verbergen (Rahmen werden wiederverwendet). Liefert die Hoehe.
function ST.Layout(stage, width)
    stage.width = width
    if not OC.Active() then
        for _, lane in pairs(stage.bySlot) do lane:Hide() end
        for i = #stage.lanes, 1, -1 do stage.lanes[i] = nil end
        stage.off:Show()
        stage:SetSize(width, ST.OFF_H)
        return ST.OFF_H
    end
    stage.off:Hide()
    local y, used = 0, {}
    local slots = ST.SpellSlots()
    for i, slot in ipairs(slots) do
        local lane = stage.bySlot[slot]
        if not lane then lane = Lane(stage, slot) stage.bySlot[slot] = lane end
        stage.lanes[i] = lane
        lane:SetWidth(width)
        lane:Show()
        local h = ST.DrawLane(lane, width)
        lane:ClearAllPoints()
        lane:SetPoint("TOPLEFT", stage, "TOPLEFT", 0, -y)
        lane:SetSize(width, h)
        used[slot] = true
        y = y + h + ST.GAP
    end
    for i = #slots + 1, #stage.lanes do stage.lanes[i] = nil end
    for slot, lane in pairs(stage.bySlot) do if not used[slot] then lane:Hide() end end
    y = math.max(ST.MIN_ROW, y - ST.GAP)
    stage:SetSize(width, y)
    return y
end

-- Auswahl auf der Buehne zeigen: Rahmen um das Teil bzw. Bahn hell.
function ST.ShowSelection(stage)
    local box = stage.selBox
    local sel = ST.sel
    for _, lane in ipairs(stage.lanes) do
        local on = sel.kind == "row" and sel.id == lane.slot
        lane.sel:SetShown(on)
        lane.edge:SetShown(on)
        lane.menu:SetTextColor(unpack(on and C.textBright or C.textMuted))
    end
    local target
    if sel.kind == "entry" then
        for _, lane in ipairs(stage.lanes) do
            for _, b in ipairs(lane.row.items) do
                if b._e and b._e.key == sel.id and b:IsShown() then
                    if not b._track then target = b break end
                    target = target or b
                end
            end
            if target and not target._track then break end
        end
        if not target and stage.pool then
            for _, b in ipairs(stage.pool.btns) do
                if b._e and b._e.key == sel.id and b:IsShown() then target = b break end
            end
        end
    end
    if target then
        box:SetParent(target)
        box:ClearAllPoints()
        box:SetPoint("TOPLEFT", target, "TOPLEFT", -3, 3)
        box:SetPoint("BOTTOMRIGHT", target, "BOTTOMRIGHT", 3, -3)
        box:SetFrameLevel((target:GetFrameLevel() or 1) + 6)
        box:Show()
    else
        box:Hide()
    end
end

--------------------------------------------------
-- Vorrat
--------------------------------------------------

local function PoolButton(stage, parent)
    local b = CreateFrame("Frame", nil, parent)
    b:SetSize(ST.POOL_ICON, ST.POOL_ICON)
    b._pool = true
    b._track = false
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetAllPoints(b)
    b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    K.Border(b, 1, 0, 0, 0, 1, "OVERLAY")
    ST.Attach(stage, b)
    return b
end

function ST.DrawPool(stage, width)
    local pool = stage.pool
    if not (pool and width) then return end
    local list = ST.Entries("off")
    local per = ST.PoolPer(width)
    for i, e in ipairs(list) do
        local b = pool.btns[i]
        if not b then b = PoolButton(stage, pool) pool.btns[i] = b end
        b._e = e
        b.icon:SetTexture(e.tex)
        if b.icon.SetDesaturated then b.icon:SetDesaturated(true) end
        local line, pos = math.floor((i - 1) / per), (i - 1) % per
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", pool, "TOPLEFT", ST.PAD + pos * (ST.POOL_ICON + ST.POOL_GAP),
            -ST.HEAD - line * (ST.POOL_ICON + ST.POOL_GAP))
        b:Show()
    end
    for j = #list + 1, #pool.btns do pool.btns[j]:Hide() pool.btns[j]._e = nil end
    pool.head:SetText(#list .. " ausgeblendet  ·  hierher ziehen = nicht zeigen  ·  von hier nach oben ziehen = zeigen")
end

local function BuildPool(stage)
    local pool = CreateFrame("Frame", nil, stage)
    local bg = pool:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(pool)
    bg:SetColorTexture(unpack(C.surface1))
    pool.hot = pool:CreateTexture(nil, "BORDER")
    pool.hot:SetAllPoints(pool)
    local a = C.accent
    pool.hot:SetColorTexture(a[1], a[2], a[3], 0.14)
    pool.hot:Hide()
    pool.head = K.NewText(pool, 11)
    pool.head:SetPoint("TOPLEFT", pool, "TOPLEFT", ST.PAD, -6)
    pool.head:SetTextColor(unpack(C.textMuted))
    pool:EnableMouse(true)
    pool:SetScript("OnReceiveDrag", function() ST.DropCursor(stage) end)
    pool:SetScript("OnMouseUp", function() if OC.FromCursor() then ST.DropCursor(stage) end end)
    pool.btns = {}
    pool.width, pool.clip = false, false
    return pool
end

-- Der Vorrat als Zeile der Einstellungsseite (unter der Auswahl).
function ST.CreatePool(parent, width)
    local stage = ST.current or ST.Build()
    ST.current = stage
    local pool = stage.pool
    pool:SetParent(parent)
    pool:ClearAllPoints()
    pool:SetSize(width, ST.PoolHeight(width))
    pool.width = width
    -- Rollt der Vorrat aus dem Bild, nimmt er nichts an (ST.Target).
    local p, clip = parent, nil
    for _ = 1, 6 do
        if not p then break end
        if _G.rawget(p, "WCScrollBar") then clip = p break end
        p = p.GetParent and p:GetParent() or nil
    end
    pool.clip = clip
    pool:Show()
    ST.DrawPool(stage, width)
    pool.Sync = function() ST.DrawPool(stage, width) end
    return pool
end

--------------------------------------------------
-- Auswahl: alle Einstellungen der gewaehlten Faehigkeit oder Reihe
--------------------------------------------------

ST.INSP_HEAD = 48
ST.INSP_STEP = 60
ST.INSP_ROWS = 6
function ST.InspectorHeight()
    return ST.INSP_HEAD + ST.INSP_ROWS * ST.INSP_STEP + 4
end

local function Px(v) return string.format("%d px", v) end

local function ButtonCell(parent, cellW, spec)
    local w = CreateFrame("Frame", nil, parent)
    w:SetSize(cellW, 52)
    local lbl = K.NewText(w, 13)
    lbl:SetPoint("TOPLEFT", w, "TOPLEFT", 0, -2)
    lbl:SetTextColor(unpack(C.textMuted))
    lbl:SetText(spec.label or "")
    local b = WeintCodex.CreateButton(w, {
        text = spec.text(), kind = "secondary", height = 26, size = 11, backdrop = "bgDark",
        tooltip = spec.tooltip, onClick = function(self) spec.onClick(self) end,
    })
    b:SetPoint("BOTTOMLEFT", w, "BOTTOMLEFT", 0, 2)
    b:SetPoint("BOTTOMRIGHT", w, "BOTTOMRIGHT", 0, 2)
    w.button = b
    w.Sync = function()
        b:SetText(spec.text())
        local show = not spec.shown or spec.shown()
        w:SetAlpha(show and 1 or 0)
        b:EnableMouse(show and true or false)
    end
    return w
end

local function Refresh()
    OC.Relayout()
    if ST.inspector then ST.inspector.Sync() end
end

-- Einstellungen der Faehigkeit. Jede Zelle fragt die Auswahl zum
-- Zeitpunkt ihres Gebrauchs - die Zellen werden einmal gebaut.
local function EntryCells()
    local function e() return ST.SelEntry() end
    local function noTrack() local x = e() return not (x and OC.Track(x)) end
    return {
        { type = "dropdown", label = "Steht in Reihe",
          items = function()
              local out = {}
              for _, sl in ipairs(OC.Slots()) do
                  out[#out + 1] = { value = sl, text = sl == "off" and "Nicht zeigen (Vorrat)" or OC.SlotText(sl) }
              end
              return out
          end,
          get = function() local x = e() return x and OC.Slot(x) end,
          set = function(v) local x = e() if x then OC.Place(x.key, v, nil) Refresh() end end },
        { type = "dropdown", label = "Darstellung in der Reihe",
          items = { { value = "icon", text = "Symbol mit Uhr" }, { value = "bar", text = "Balken (Wirkung, dann Abklingzeit)" } },
          get = function() local x = e() return x and OC.Display(x) end,
          set = function(v) local x = e() if x then OC.SetDisplay(x, v) Refresh() end end,
          disabled = function() local x = e() return not x or OC.Slot(x) == "off" end,
          disabledHint = "– nicht gezeigt –" },
        { type = "dropdown", label = "Laufzeit zusätzlich als eigener Balken",
          items = function() return ST.TrackItems(e()) end,
          get = function() local x = e() return x and (OC.Track(x) or "none") end,
          set = function(v) local x = e() if x then OC.SetTrack(x, v ~= "none" and v or nil) Refresh() end end,
          tooltip = "Unabhängig vom Symbol: die Laufzeit (z. B. je Falke) als Balken – direkt daneben oder in einer Reihe deiner Wahl, auch einer eigenen nur für Balken. Geht auch mit Umschalt + Ziehen auf der Bühne." },
        { type = "dropdown", label = "Dieser Balken zeigt",
          items = function() return ST.WhatItems(e()) end,
          get = function() local x = e() return x and OC.TrackWhat(x) end,
          set = function(v) local x = e() if x then OC.SetTrackWhat(x, v) Refresh() end end,
          disabled = noTrack, disabledHint = "– kein Laufzeit-Balken –" },
        { type = "dropdown", label = "Wenn nichts läuft",
          items = { { value = "hide", text = "Balken ausblenden" }, { value = "show", text = "Leer stehen lassen" } },
          get = function() local x = e() return x and (OC.TrackIdle(x) and "show" or "hide") end,
          set = function(v) local x = e() if x then OC.SetTrackIdle(x, v == "show") Refresh() end end,
          disabled = noTrack, disabledHint = "– kein Laufzeit-Balken –" },
        { type = "dropdown", label = "Farbe der Wirkung im Balken", items = OC.GLOW_COLORS,
          get = function() local x = e() return x and OC.BarColor(x) end,
          set = function(v) local x = e() if x then OC.SetBarColor(x, v) end end,
          disabled = function() local x = e() return not (x and OC.HasEffect(x) and (OC.Display(x) == "bar" or OC.Track(x))) end,
          disabledHint = "– keine Wirkung im Balken –" },
        { type = "dropdown", label = "Leuchten",
          items = function()
              local x = e()
              local modes = (x and OC.DotDuration(x.name)) and { "ready", "dot", "off" } or { "ready", "off" }
              local out = {}
              for _, v in ipairs(modes) do out[#out + 1] = { value = v, text = OC.GLOW_TEXT[v] } end
              return out
          end,
          get = function() local x = e() return x and OC.GlowMode(x) end,
          set = function(v) local x = e() if x then OC.SetGlow(x, v) end end },
        { type = "dropdown", label = "Rang",
          items = function()
              local x, out = e(), {}
              for _, r in ipairs((x and x.ranks) or {}) do out[#out + 1] = { value = r, text = OC.SpellRank(r) or ("Nummer " .. r) } end
              return out
          end,
          get = function() local x = e() return x and x.id end,
          set = function(v) local x = e() if x then OC.SetRank(x, v) end end,
          disabled = function() local x = e() return not (x and x.ranks and #x.ranks > 1) end,
          disabledHint = "– nur ein Rang –" },
        { type = "button", label = "Ton",
          text = function() local x = e() return "Ton: " .. (x and OC.SoundText(OC.SoundOf(x)) or "–") .. " …" end,
          onClick = function(btn) local x = e() if x then OC.SoundMenu(btn, x, function() ST.inspector.Sync() end) end end },
        { type = "dropdown", label = "Ton wann",
          items = { { value = "ready", text = OC.WHEN_TEXT.ready }, { value = "dot", text = OC.WHEN_TEXT.dot } },
          get = function() local x = e() return x and OC.SoundWhen(x) end,
          set = function(v) local x = e() if x then OC.SetSoundWhen(x, v) end end,
          disabled = function() local x = e() return not (x and OC.DotDuration(x.name)) end,
          disabledHint = OC.WHEN_TEXT.ready },
        { type = "button", label = "Liste",
          text = function() local x = e() return (x and x.custom) and "Aus der Liste entfernen" or "Nicht zeigen (in den Vorrat)" end,
          onClick = function()
              local x = e()
              if not x then return end
              if x.custom then OC.Remove(x) ST.Select("row", "big") else OC.Place(x.key, "off", nil) end
              Refresh()
          end },
        { type = "button", label = "Reihe",
          text = function() return "Zur Reihe dieser Fähigkeit" end,
          shown = function() local x = e() return x and OC.Slot(x) ~= "off" end,
          onClick = function() local x = e() if x then ST.Select("row", OC.Slot(x)) end end },
    }
end

local function RowCells()
    local function r() return ST.SelRow() end
    local function opt(k) local id = r() return id and OC.RowOpt(id, k) end
    local function set(k, v) local id = r() if id then OC.SetRowOpt(id, k, v) end end
    return {
        { type = "slider", label = "Symbolgröße", min = 16, max = 64, step = 2, format = Px,
          get = function() return tonumber(opt("size")) or 32 end, set = function(v) set("size", v) end },
        { type = "dropdown", label = "Richtung", items = OC.DIRECTIONS,
          get = function() local id = r() return id and OC.Direction(id) end,
          set = function(v) local id = r() if id then OC.SetDirection(id, v) end end },
        { type = "slider", label = "Je Zeile", min = 0, max = 16, step = 1,
          format = function(v) return v == 0 and "alle" or tostring(v) end,
          get = function() return tonumber(opt("perLine")) or 0 end, set = function(v) set("perLine", v) end },
        { type = "slider", label = "Abstand", min = 0, max = 20, step = 1, format = Px,
          get = function() return tonumber(opt("gap")) or 4 end, set = function(v) set("gap", v) end },
        { type = "slider", label = "Balkenlänge", min = 40, max = 400, step = 10, format = Px,
          get = function() return tonumber(opt("barWidth")) or 180 end, set = function(v) set("barWidth", v) end },
        { type = "slider", label = "Balkendicke", min = 8, max = 48, step = 1, format = Px,
          get = function()
              local v = tonumber(opt("barHeight"))
              if v then return v end
              return math.max(14, math.floor((tonumber(opt("size")) or 32) * 0.6 + 0.5))
          end,
          set = function(v) set("barHeight", v) end },
        { type = "dropdown", label = "Balken liegen oder stehen",
          items = { { value = "h", text = "Liegend (waagerecht)" }, { value = "v", text = "Stehend (senkrecht)" } },
          get = function() return opt("barVertical") and "v" or "h" end, set = function(v) set("barVertical", v == "v") end },
        { type = "dropdown", label = "Balken laufen",
          items = { { value = "drain", text = "Leeren sich (Restzeit)" }, { value = "fill", text = "Füllen sich (bis fertig)" } },
          get = function() return opt("barFill") == "fill" and "fill" or "drain" end, set = function(v) set("barFill", v) end },
        { type = "toggle", label = "Symbol am Balken",
          get = function() return opt("barIcon") ~= false end, set = function(v) set("barIcon", v and true or false) end },
        { type = "toggle", label = "Name am Balken",
          get = function() return opt("barName") ~= false end, set = function(v) set("barName", v and true or false) end,
          disabled = function() return opt("barVertical") and true or false end, disabledHint = "stehend ohne Namen" },
        { type = "toggle", label = "Nur im Kampf zeigen",
          get = function() return opt("combatOnly") and true or false end, set = function(v) set("combatOnly", v and true or false) end },
        { type = "button", label = "Eigene Reihe",
          text = function() return "Umbenennen …" end,
          shown = function() local id = r() return id and OC.ExtraDef(id) and true or false end,
          onClick = function() local id = r() if id then OC.AskRename(id) end end },
    }
end
ST.EntryCells, ST.RowCells = EntryCells, RowCells

local function MakeCell(parent, cellW, spec)
    local w
    if spec.type == "dropdown" then
        w = WeintCodex.CreateDropdown(parent, { label = spec.label, items = spec.items, width = cellW,
            get = spec.get, set = spec.set, disabled = spec.disabled, disabledHint = spec.disabledHint, tooltip = spec.tooltip })
    elseif spec.type == "slider" then
        w = WeintCodex.CreateSlider(parent, { label = spec.label, min = spec.min, max = spec.max, step = spec.step,
            get = spec.get, set = spec.set, format = spec.format })
        w:SetWidth(cellW)
    elseif spec.type == "toggle" then
        w = WeintCodex.CreateToggle(parent, { label = spec.label, width = cellW, get = spec.get, set = spec.set,
            disabled = spec.disabled, disabledHint = spec.disabledHint })
    elseif spec.type == "button" then
        w = ButtonCell(parent, cellW, spec)
    end
    return w
end

local function Panel(insp, width, cells)
    local p = CreateFrame("Frame", nil, insp)
    p:SetPoint("TOPLEFT", insp, "TOPLEFT", 0, -ST.INSP_HEAD)
    p:SetSize(width, ST.INSP_ROWS * ST.INSP_STEP)
    local O = WeintCodex.UIOptions
    local cellW = (O and O.CELL_W) or math.floor((width - 32) / 2)
    local gap = width - 2 * cellW
    p.widgets, p.specs = {}, cells
    for i, spec in ipairs(cells) do
        local w = MakeCell(p, cellW, spec)
        if w then
            local col, line = (i - 1) % 2, math.floor((i - 1) / 2)
            w:SetPoint("TOPLEFT", p, "TOPLEFT", col * (cellW + gap), -line * ST.INSP_STEP)
            p.widgets[#p.widgets + 1] = w
        end
    end
    p.Sync = function() for _, w in ipairs(p.widgets) do if w.Sync then w:Sync() end end end
    return p
end

function ST.BuildInspector(width)
    local insp = CreateFrame("Frame", nil, UIParent)
    insp:SetSize(width, ST.InspectorHeight())
    -- Kopf: Symbol, Name, ein Satz dazu.
    insp.icon = insp:CreateTexture(nil, "ARTWORK")
    insp.icon:SetSize(32, 32)
    insp.icon:SetPoint("TOPLEFT", insp, "TOPLEFT", 0, -2)
    insp.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    insp.title = K.NewText(insp, 15)
    insp.title:SetTextColor(unpack(C.textBright))
    insp.sub = K.NewText(insp, 11)
    insp.sub:SetTextColor(unpack(C.textDim))
    insp.sub:SetJustifyH("LEFT")
    if insp.sub.SetWordWrap then insp.sub:SetWordWrap(false) end
    local line = insp:CreateTexture(nil, "ARTWORK")
    line:SetHeight(1)
    line:SetPoint("TOPLEFT", insp, "TOPLEFT", 0, -ST.INSP_HEAD + 8)
    line:SetPoint("TOPRIGHT", insp, "TOPRIGHT", 0, -ST.INSP_HEAD + 8)
    line:SetColorTexture(unpack(C.rowLine))
    insp.entry = Panel(insp, width, EntryCells())
    insp.row = Panel(insp, width, RowCells())
    insp.Sync = function()
        local e = ST.SelEntry()
        insp.title:ClearAllPoints()
        insp.sub:ClearAllPoints()
        if e then
            insp.icon:SetTexture(e.tex)
            insp.icon:Show()
            insp.title:SetPoint("TOPLEFT", insp.icon, "TOPRIGHT", 10, 0)
            insp.title:SetText(e.rank and (e.name .. "  ·  " .. e.rank) or (e.name or "?"))
            insp.sub:SetPoint("TOPLEFT", insp.title, "BOTTOMLEFT", 0, -3)
            insp.sub:SetPoint("RIGHT", insp, "RIGHT", 0, 0)
            insp.sub:SetText(ST.EffectLine(e))
            insp.entry:Show() insp.row:Hide()
            insp.entry.Sync()
        else
            local slot = ST.SelRow() or "big"
            insp.icon:Hide()
            insp.title:SetPoint("TOPLEFT", insp, "TOPLEFT", 0, -2)
            insp.title:SetText("Reihe „" .. OC.SlotText(slot) .. "“")
            insp.sub:SetPoint("TOPLEFT", insp.title, "BOTTOMLEFT", 0, -3)
            insp.sub:SetPoint("RIGHT", insp, "RIGHT", 0, 0)
            insp.sub:SetText("Gilt für Symbole und Balken dieser Reihe. Verschieben im Spiel: Gestaltungsmodus.")
            insp.row:Show() insp.entry:Hide()
            insp.row.Sync()
        end
    end
    return insp
end

-- Ein Satz zur Wirkdauer der gewaehlten Faehigkeit.
function ST.EffectLine(e)
    local dd = OC.DotDuration(e.name)
    if dd then return "Wirkt " .. dd .. " s auf dem Ziel – Uhr aus dem eigenen Wirken." end
    local g = OC.BuffGroup(e)
    if g and g.duration then
        if g.stack and g.stack > 1 then
            return "Wirkt " .. g.duration .. " s, bis zu " .. g.stack .. " zugleich – je einer ein eigener Balken."
        end
        return "Wirkt " .. g.duration .. " s – Uhr aus dem eigenen Wirken."
    end
    if e.item then return "Gegenstand – Balken zeigen die Abklingzeit." end
    return "Keine Wirkdauer bekannt – Balken zeigen die Abklingzeit."
end

-- Die Auswahl als Zeile der Einstellungsseite (gleich unter der Buehne).
function ST.CreateInspector(parent, width)
    local insp = ST.inspector
    if not insp then insp = ST.BuildInspector(width) ST.inspector = insp end
    insp:SetParent(parent)
    insp:ClearAllPoints()
    insp:Show()
    ST.Select(ST.sel.kind, ST.sel.id)
    return insp
end

--------------------------------------------------
-- Bau der Buehne
--------------------------------------------------

function ST.Build()
    local stage = CreateFrame("Frame", nil, UIParent)
    stage.lanes, stage.bySlot = {}, {}
    stage.pool = BuildPool(stage)
    stage.pool:Hide()
    local a = C.accent
    -- Marke: wo das Gezogene landet.
    stage.mark = stage:CreateTexture(nil, "OVERLAY")
    stage.mark:SetColorTexture(a[1], a[2], a[3], 1)
    stage.mark:Hide()
    -- Rahmen um das gewaehlte Teil.
    stage.selBox = CreateFrame("Frame", nil, stage)
    K.Border(stage.selBox, 2, a[1], a[2], a[3], 1, "OVERLAY")
    stage.selBox:EnableMouse(false)
    stage.selBox:Hide()
    -- Anderer Manager gewaehlt: ein Satz statt der Reihen.
    stage.off = K.NewText(stage, 12)
    stage.off:SetPoint("TOPLEFT", stage, "TOPLEFT", ST.PAD, -14)
    stage.off:SetPoint("RIGHT", stage, "RIGHT", -ST.PAD, 0)
    stage.off:SetJustifyH("LEFT")
    stage.off:SetTextColor(unpack(C.textMuted))
    stage.off:SetText("Hier steht die Vorschau des WeintCodex-Abklingzeitmanagers – darunter bei „Welcher Abklingzeitmanager?“ „WeintCodex“ wählen.")
    stage.off:Hide()
    stage.Sync = function()
        ST.Fit(stage)
        if stage.pool:IsShown() and stage.pool.width then ST.DrawPool(stage, stage.pool.width) end
        ST.ShowSelection(stage)
    end
    -- Lebendig: die Uhren laufen wie im Spiel (zweimal je Sekunde neu
    -- gezeichnet, nur solange die Seite offen ist); beim Ziehen jedes Bild
    -- die Marke.
    local acc = 0
    stage:SetScript("OnUpdate", K.Measured("Abklingzeitmanager: Bühne", function(self, el)
        if drag.key then ST.Track(self) end
        acc = acc + (el or 0)
        if acc < 0.5 then return end
        acc = 0
        if not drag.key then self.Sync() end
    end))
    stage:SetScript("OnHide", function()
        if drag.stage == stage then ST.Finish() end
    end)
    return stage
end

-- Buehne in ihre Breite legen; ist sie hoeher als der Platz oben, wird
-- sie als Ganzes verkleinert (nie abgeschnitten). Liefert die sichtbare Hoehe.
function ST.Fit(stage)
    local width = stage.baseWidth or stage.width or 560
    local h = ST.Layout(stage, width)
    local O = WeintCodex.UIOptions
    local host = _G.rawget(stage, "host")
    local room = (host and O and O.PreviewRoom) and O.PreviewRoom() or h
    local sc = 1
    if h > room then
        sc = math.max(ST.MIN_SCALE, room / h)
        h = ST.Layout(stage, width / sc)
    end
    if stage._sc ~= sc then stage._sc = sc stage:SetScale(sc) end
    local vis = math.ceil(h * sc)
    if host and O and O.SetPreviewHeight then O.SetPreviewHeight(host, vis) end
    return vis
end

-- Eine Buehne je Sitzung: die Einstellungsseite baut bei jeder groesseren
-- Aenderung neu und holt sie sich wieder (kein neuer Satz Rahmen je Zug).
function ST.Create(parent, width)
    local stage = ST.current or ST.Build()
    ST.current = stage
    stage:SetParent(parent)
    stage:ClearAllPoints()
    stage:Show()
    stage.baseWidth = width
    stage.Sync()
    return stage
end

-- Vorschau je Seite (ui/options.lua): fest oben, Hoehe folgt den Reihen.
function ST.CreatePreview(host, width)
    local stage = ST.current or ST.Build()
    stage.host = host
    ST.Create(host, width)
    return stage, ST.Fit(stage)
end

-- Nach einer Aenderung: Buehne neu anordnen und zeichnen. Aendert sich
-- die Hoehe des Vorrats, muss die Seite neu gebaut werden (false).
function ST.Refit()
    local stage = ST.current
    if not (stage and stage:IsVisible()) then return false end
    ST.Fit(stage)
    ST.ShowSelection(stage)
    local pool = stage.pool
    if pool:IsShown() and pool.width then
        if math.abs(ST.PoolHeight(pool.width) - (pool:GetHeight() or 0)) >= 0.5 then return false end
        ST.DrawPool(stage, pool.width)
    end
    if ST.inspector and ST.inspector:IsVisible() then ST.inspector.Sync() end
    return true
end

-- /wcui speicher: interne Tabellen dieser Datei (1.0.9.0).
WeintCodex.Hold("ui/cdstage.lua", function() return { slotsOut = slotsOut, drag = drag, sel = ST.sel } end)
