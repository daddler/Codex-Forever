--------------------------------------------------
-- WeintCodex :: Oberflaeche - Buehne des Abklingzeitmanagers (1.0.9.0)
--------------------------------------------------
-- Wunsch des Spielers: "Ich mache den Abklingzeitenmanager auf und sehe
-- erstmal, wie es bisher aufgebaut ist und was zur Zeit angezeigt wird.
-- Per Drag & Drop einzelne Faehigkeiten direkt in die jeweilige Leiste
-- ziehen - das wird so uebernommen." Vorbild fuer die Vorschau: die der
-- Namensplaketten; fuer Balken je Faehigkeit: WeakAuras (Verhalten, kein
-- Code).
--
-- AUFBAU. Jede Reihe mit Zaubern (Wichtig, Weitere, eigene) ist eine Bahn:
-- Kopf mit Name und "Einstellungen", darunter die Reihe GENAU SO, wie sie
-- im Spiel steht - dieselben Teile (Symbol oder Balken), dieselbe Groesse,
-- Anordnung und Uhr; ui/owncooldowns.lua zeichnet sie (OC.DrawSpells mit
-- row._preview: kein Ton, nichts gemerkt). Ist eine Reihe breiter als die
-- Seite, wird sie verkleinert gezeigt, nie abgeschnitten. Unten der
-- Vorrat: alles, was gerade nicht gezeigt wird ("Aus").
--
-- BEDIENUNG. Ziehen: an eine Stelle einer Reihe (eine Marke zeigt, wo es
-- landet) oder in den Vorrat (ausblenden). Klick: Menue der Faehigkeit
-- (Darstellung, Balkenfarbe, Rang, Leuchten, Ton, Reihe). Rechtsklick:
-- Symbol <-> Balken. Klick auf den Kopf einer Bahn: Einstellungen der
-- Reihe. Aus Zauberbuch oder Taschen auf eine Bahn ziehen: hinzufuegen,
-- genau dorthin.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UICooldownStage = {}

local ST = WeintCodex.UICooldownStage
local OC = WeintCodex.UIOwnCooldowns
local K = WeintCodex.UIKit
local C = WeintCodex.Colors

ST.PAD = 10
ST.HEAD = 24
ST.GAP = 8          -- zwischen den Bahnen
ST.POOL_ICON = 30
ST.POOL_GAP = 4
ST.MIN_ROW = 24     -- Hoehe einer leeren Reihe

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

-- Groesse einer Reihe, wie sie im Spiel steht (ohne Rahmen zu bauen).
function ST.RowSize(slot)
    local s = tonumber(OC.RowOpt(slot, "size")) or 32
    local list = ST.Entries(slot)
    if #list == 0 then return s, s, 0 end
    local bw, bh = OC.BarSize(slot, s)
    local function sizeOf(i)
        if OC.Display(list[i]) == "bar" then return bw, bh end
        return s, s
    end
    local w, h = OC.Layout(#list, sizeOf, tonumber(OC.RowOpt(slot, "gap")) or 4,
        tonumber(OC.RowOpt(slot, "perLine")) or 0, OC.RowOpt(slot, "vertical") and true or false)
    return w, h, #list
end

function ST.Scale(w, avail)
    if not (w and w > 0) then return 1 end
    return math.min(1, avail / w)
end

function ST.LaneHeight(slot, width)
    local w, h = ST.RowSize(slot)
    local sc = ST.Scale(w, width - 2 * ST.PAD)
    return ST.HEAD + math.max(ST.MIN_ROW, math.ceil(h * sc)) + ST.PAD
end

function ST.PoolPer(width)
    return math.max(1, math.floor((width - 2 * ST.PAD + ST.POOL_GAP) / (ST.POOL_ICON + ST.POOL_GAP)))
end

function ST.PoolHeight(width)
    local n = #ST.Entries("off")
    local lines = math.max(1, math.ceil(n / ST.PoolPer(width)))
    return ST.HEAD + lines * (ST.POOL_ICON + ST.POOL_GAP) + ST.PAD
end

function ST.Height(width)
    local h = 0
    for _, sl in ipairs(ST.SpellSlots()) do h = h + ST.LaneHeight(sl, width) + ST.GAP end
    return h + ST.PoolHeight(width)
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

-- Wohin faellt, was gerade gezogen wird? slot, beforeKey, Teil fuer die
-- Marke, "vor"/"nach". Naechstes Teil der Reihe nach Abstand; links bzw.
-- oberhalb seiner Mitte: davor, sonst dahinter (vor dem naechsten).
function ST.Target(stage, dragKey)
    if not stage then return nil end
    if Hit(stage.pool) then return "off", nil, nil, nil end
    for _, lane in ipairs(stage.lanes) do
        if Hit(lane) then
            local row = lane.row
            local items = row.items or {}
            local vert = OC.RowOpt(lane.slot, "vertical") and true or false
            local best, bestD, bestI
            local x, y = Cursor(row)
            for i, b in ipairs(items) do
                if b:IsShown() and b._e and b._e.key ~= dragKey then
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
            if before then return lane.slot, best._e.key, best, "before" end
            -- dahinter: vor dem naechsten der Reihe (nicht dem gezogenen)
            for j = bestI + 1, #items do
                local o = items[j]
                if o._e and o._e.key ~= dragKey then return lane.slot, o._e.key, best, "after" end
            end
            return lane.slot, nil, best, "after"
        end
    end
    return nil
end

--------------------------------------------------
-- Menue einer Faehigkeit
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
        if OC.Display(e) == "bar" then
            local col = root:CreateButton(OC.HasEffect(e) and "Farbe der Wirkung" or "Farbe (ohne bekannte Wirkdauer)")
            for _, c in ipairs(OC.GLOW_COLORS) do
                local v = c.value
                col:CreateRadio(c.text, function() return OC.BarColor(e) == v end, function() OC.SetBarColor(e, v) end)
            end
        end
        if e.ranks and #e.ranks > 1 then
            local rk = root:CreateButton("Rang")
            for _, r in ipairs(e.ranks) do
                local rr = r
                rk:CreateRadio(OC.SpellRank(rr) or ("Nummer " .. rr), function() return e.id == rr end,
                    function() OC.SetRank(e, rr) end)
            end
        end
        local gl = root:CreateButton("Leuchten: " .. OC.GLOW_TEXT[OC.GlowMode(e)])
        local modes = OC.DotDuration(e.name) and { "ready", "dot", "off" } or { "ready", "off" }
        for _, v in ipairs(modes) do
            gl:CreateRadio(OC.GLOW_TEXT[v], function() return OC.GlowMode(e) == v end, function() OC.SetGlow(e, v) end)
        end
        root:CreateButton("Ton: " .. OC.SoundText(OC.SoundOf(e)) .. " …", function() OC.SoundMenu(owner, e) end)
        if OC.DotDuration(e.name) then
            local w = root:CreateButton("Ton wann: " .. OC.WHEN_TEXT[OC.SoundWhen(e)])
            for _, v in ipairs({ "ready", "dot" }) do
                w:CreateRadio(OC.WHEN_TEXT[v], function() return OC.SoundWhen(e) == v end, function() OC.SetSoundWhen(e, v) end)
            end
        end
        local rw = root:CreateButton("Reihe: " .. OC.SlotText(OC.Slot(e)))
        for _, sl in ipairs(OC.Slots()) do
            local s2 = sl
            rw:CreateRadio(OC.SlotText(s2), function() return OC.Slot(e) == s2 end,
                function() OC.Place(e.key, s2, nil) OC.Relayout() end)
        end
        if e.custom then root:CreateButton("Entfernen", function() OC.Remove(e) OC.Relayout() end) end
    end)
    return true
end

--------------------------------------------------
-- Ziehen
--------------------------------------------------

local drag = { key = nil, stage = nil }
ST.drag = drag

function ST.Begin(stage, e)
    if not (stage and e) then return end
    drag.key, drag.stage = e.key, stage
    OC.GhostStart(e, nil)
    stage.mark:Hide()
end

-- Marke und Hervorhebung, waehrend gezogen wird (OnUpdate der Buehne).
function ST.Track(stage)
    if not drag.key then return end
    local slot, _, item, side = ST.Target(stage, drag.key)
    local mark = stage.mark
    mark:ClearAllPoints()
    if item then
        local vert = OC.RowOpt(slot, "vertical") and true or false
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
    stage.pool.hot:SetShown(slot == "off")
end

function ST.Finish()
    local stage, key = drag.stage, drag.key
    drag.key, drag.stage = nil, nil
    OC.GhostStop()
    if not (stage and key) then return false end
    stage.mark:Hide()
    for _, lane in ipairs(stage.lanes) do lane.hot:Hide() end
    stage.pool.hot:Hide()
    local slot, before = ST.Target(stage, key)
    if not slot then return false end
    OC.Place(key, slot, before)
    OC.Relayout()
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
    return true
end

-- Jedes Teil der Buehne (Symbol, Balken, Vorrat) nimmt die Maus.
function ST.Attach(stage, b)
    b:EnableMouse(true)
    if b.RegisterForDrag then b:RegisterForDrag("LeftButton") end
    b:SetScript("OnDragStart", function(self)
        if self._e then self:SetAlpha(0.35) ST.Begin(stage, self._e) end
    end)
    b:SetScript("OnDragStop", function(self)
        self:SetAlpha(1)
        ST.Finish()
    end)
    b:SetScript("OnMouseUp", function(self, button)
        if drag.key or not self._e then return end
        if OC.FromCursor() then ST.DropCursor(stage) return end
        if button == "RightButton" then
            OC.SetDisplay(self._e, OC.Display(self._e) == "bar" and "icon" or "bar")
            OC.Relayout()
            return
        end
        ST.Menu(self, self._e)
    end)
    b:SetScript("OnReceiveDrag", function() ST.DropCursor(stage) end)
    b:SetScript("OnEnter", function(self)
        local tt, e = _G.GameTooltip, self._e
        if not (tt and e) then return end
        tt:SetOwner(self, "ANCHOR_RIGHT")
        if e.item then pcall(tt.SetItemByID, tt, e.id) else pcall(tt.SetSpellByID, tt, e.id) end
        tt:AddLine(" ")
        tt:AddLine("Ziehen: in eine Reihe oder in den Vorrat · Klick: Einstellungen · Rechtsklick: "
            .. (OC.Display(e) == "bar" and "als Symbol" or "als Balken"), 0.6, 0.6, 0.65, true)
        if OC.Display(e) == "bar" and not OC.HasEffect(e) then
            tt:AddLine("Für diese Fähigkeit kennt WeintCodex keine Wirkdauer – der Balken zeigt nur die Abklingzeit.", 0.6, 0.6, 0.65, true)
        end
        tt:Show()
    end)
    b:SetScript("OnLeave", function() if _G.GameTooltip then _G.GameTooltip:Hide() end end)
end

--------------------------------------------------
-- Bau
--------------------------------------------------

local function Lane(stage, slot)
    local lane = CreateFrame("Button", nil, stage)
    lane.slot = slot
    local bg = lane:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(lane)
    bg:SetColorTexture(unpack(C.surface1))
    lane.hot = lane:CreateTexture(nil, "BORDER")
    lane.hot:SetAllPoints(lane)
    local a = C.accent
    lane.hot:SetColorTexture(a[1], a[2], a[3], 0.12)
    lane.hot:Hide()
    lane.head = K.NewText(lane, 12)
    lane.head:SetPoint("TOPLEFT", lane, "TOPLEFT", ST.PAD, -6)
    lane.head:SetTextColor(unpack(C.textBright))
    lane.menu = K.NewText(lane, 11)
    lane.menu:SetPoint("TOPRIGHT", lane, "TOPRIGHT", -ST.PAD, -7)
    lane.menu:SetTextColor(unpack(C.textMuted))
    lane.menu:SetText("Einstellungen der Reihe ›")
    lane:EnableMouse(true)
    lane:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    lane:SetScript("OnClick", function(self)
        if OC.FromCursor() then ST.DropCursor(stage) return end
        local _, cy = Cursor(self)
        local top = self:GetTop()
        if top and cy < top - ST.HEAD then return end
        OC.RowMenu(self, slot)
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

function ST.DrawLane(lane, width)
    local slot, row = lane.slot, lane.row
    local size = tonumber(OC.RowOpt(slot, "size")) or 32
    OC.DrawSpells(row, slot, size, true)
    local n = #ST.Entries(slot)
    local w = n > 0 and (row:GetWidth() or size) or size
    local sc = ST.Scale(w, width - 2 * ST.PAD)
    if row._sc ~= sc then row._sc = sc row:SetScale(sc) end
    row:ClearAllPoints()
    row:SetPoint("TOP", lane, "TOP", 0, -ST.HEAD / sc)
    local label = OC.SlotText(slot) .. "  ·  " .. n .. (n == 1 and " Fähigkeit" or " Fähigkeiten")
    if sc < 1 then label = label .. string.format("  ·  verkleinert (%d %%)", math.floor(sc * 100 + 0.5)) end
    if lane._label ~= label then lane._label = label lane.head:SetText(label) end
    lane.empty:SetShown(n == 0)
end

local function PoolButton(stage, parent)
    local b = CreateFrame("Frame", nil, parent)
    b:SetSize(ST.POOL_ICON, ST.POOL_ICON)
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetAllPoints(b)
    b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    K.Border(b, 1, 0, 0, 0, 1, "OVERLAY")
    ST.Attach(stage, b)
    return b
end

function ST.DrawPool(stage, width)
    local pool = stage.pool
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
    pool.head:SetText("Vorrat  ·  " .. #list .. " ausgeblendet  ·  hierher ziehen = nicht zeigen")
end

-- Bahnen und Vorrat an ihren Platz; fehlende Bahnen anlegen, Bahnen
-- geloeschter Reihen verbergen. Rahmen werden wiederverwendet.
function ST.Layout(stage, width)
    stage.width = width
    local y, used = 0, {}
    local slots = ST.SpellSlots()
    for i, slot in ipairs(slots) do
        local lane = stage.bySlot[slot]
        if not lane then lane = Lane(stage, slot) stage.bySlot[slot] = lane end
        stage.lanes[i] = lane
        local h = ST.LaneHeight(slot, width)
        lane:ClearAllPoints()
        lane:SetPoint("TOPLEFT", stage, "TOPLEFT", 0, -y)
        lane:SetSize(width, h)
        lane:Show()
        used[slot] = true
        y = y + h + ST.GAP
    end
    for i = #slots + 1, #stage.lanes do stage.lanes[i] = nil end
    for slot, lane in pairs(stage.bySlot) do if not used[slot] then lane:Hide() end end
    local ph = ST.PoolHeight(width)
    stage.pool:ClearAllPoints()
    stage.pool:SetPoint("TOPLEFT", stage, "TOPLEFT", 0, -y)
    stage.pool:SetSize(width, ph)
    stage:SetSize(width, y + ph)
end

local function Build()
    local stage = CreateFrame("Frame", nil, UIParent)
    stage.lanes, stage.bySlot = {}, {}
    local pool = CreateFrame("Frame", nil, stage)
    local bg = pool:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(pool)
    bg:SetColorTexture(unpack(C.surface1))
    pool.hot = pool:CreateTexture(nil, "BORDER")
    pool.hot:SetAllPoints(pool)
    local a = C.accent
    pool.hot:SetColorTexture(a[1], a[2], a[3], 0.12)
    pool.hot:Hide()
    pool.head = K.NewText(pool, 12)
    pool.head:SetPoint("TOPLEFT", pool, "TOPLEFT", ST.PAD, -6)
    pool.head:SetTextColor(unpack(C.textMuted))
    pool:EnableMouse(true)
    pool:SetScript("OnReceiveDrag", function() ST.DropCursor(stage) end)
    pool:SetScript("OnMouseUp", function() if OC.FromCursor() then ST.DropCursor(stage) end end)
    pool.btns = {}
    stage.pool = pool
    -- Marke: wo das Gezogene landet.
    stage.mark = stage:CreateTexture(nil, "OVERLAY")
    stage.mark:SetColorTexture(a[1], a[2], a[3], 1)
    stage.mark:Hide()
    stage.Sync = function()
        for _, lane in ipairs(stage.lanes) do ST.DrawLane(lane, stage.width) end
        ST.DrawPool(stage, stage.width)
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

-- Eine Buehne je Sitzung: die Einstellungsseite baut bei jeder groesseren
-- Aenderung neu und holt sie sich wieder (kein neuer Satz Rahmen je Zug).
function ST.Create(parent, width)
    local stage = ST.current or Build()
    ST.current = stage
    stage:SetParent(parent)
    stage:ClearAllPoints()
    stage:Show()
    ST.Layout(stage, width)
    stage.Sync()
    return stage
end

-- Nach einer Aenderung: bleibt die Hoehe der Buehne gleich, genuegt neu
-- anordnen und zeichnen - die Seite muss nicht neu gebaut werden.
function ST.Refit()
    local stage = ST.current
    if not (stage and stage:IsVisible() and stage.width) then return false end
    local h = ST.Height(stage.width)
    if math.abs(h - (stage:GetHeight() or 0)) >= 0.5 then return false end
    ST.Layout(stage, stage.width)
    stage.Sync()
    return true
end

-- /wcui speicher: interne Tabellen dieser Datei (1.0.9.0).
WeintCodex.Hold("ui/cdstage.lua", function() return { slotsOut = slotsOut, drag = drag } end)
