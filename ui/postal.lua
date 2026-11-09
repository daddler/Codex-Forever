--------------------------------------------------
-- WeintCodex :: Komfort - Post (1.0.5.29)
--------------------------------------------------
-- Wunsch des Projektinhabers (mit dem Addon "Kerzo Postal Suite" als
-- Vorbild): Posteingang, Posttasche, Schreiben und Versandregeln im Addon.
-- Nach dem VERHALTEN, ohne Code oder Grafik daraus - die Vorlage traegt
-- keine Lizenz (= alle Rechte vorbehalten; dieselbe Regel wie MoveAny).
--
--   Posteingang  "Alle öffnen" und "Ausgewählte öffnen" (Haken je Brief)
--                mit Fortschritt, Umschalt-Klick nimmt einen Brief ganz,
--                Filter und Suche (dimmt, was nicht passt), Tooltip mit
--                Anhaengen, Gold, Nachnahme und Ablauf, Zusammenfassung im
--                Chat. Briefe mit Nachnahme nimmt WeintCodex nie von selbst.
--   Posttasche   alles im Postfach als eine Ansicht neben dem Briefkasten:
--                je Gegenstand die Summe, Klick holt alle Stapel davon;
--                "Alles", "Nur Gold", "Nur Gegenstände"; Verlauf je Tag.
--   Schreiben    Kontakte (eigene Twinks auf dem Realm und Fraktion,
--                zuletzt Angeschriebene), Entwuerfe, "Gesendet", an
--                mehrere Empfaenger (nur Text und Gold - Gegenstaende gibt
--                es nur einmal).
--   Regeln       Gegenstaende automatisch an Twinks: je Gegenstand oder
--                Art (Handwerkswaren, Verbrauchbares, Grau, ungebundene
--                Ausruestung), "behalten" und "nur volle Stapel". Am
--                Briefkasten ein Hinweis mit Vorschau; JEDER Brief braucht
--                einen Klick ("Senden 1/3") - nichts geht von selbst raus.
--
-- NICHT uebernommen: Taschen automatisch oeffnen (Taint - siehe
-- ui/bags.lua 1.0.5.7), Markdown in Briefen (beim Empfaenger ohne Addon nur
-- Zeichen), Papierkorb (WeintCodex loescht keine Briefe).
--
-- Was im Postfach liegt, merkt sich der Bestand aller Charaktere
-- (ui/inventory.lua, IV.SetMail) - der Tooltip nennt "Post".
--------------------------------------------------

local K = WeintCodex.UIKit
local C = WeintCodex.Colors
local KEY = "comfort"

WeintCodex.UIPostal = {}
local PO = WeintCodex.UIPostal

PO.DEFAULTS = {
    postOn = false,         -- ab Werk aus (Wunsch); an: Knoepfe, Haken, Tooltip, Filter
    postSpeed = 0.5,        -- Sekunden zwischen zwei Schritten beim Oeffnen
    postSummary = true,     -- Zusammenfassung im Chat
    postBag = true,         -- Posttasche neben dem Briefkasten
    postCompose = true,     -- Kontakte, Entwuerfe, mehrere Empfaenger
    postRules = true,       -- Versandregeln
}

PO.HISTORY_DAYS = 30
PO.SENT_MAX = 100
PO.RECENT_MAX = 15
PO.DRAFTS_MAX = 10
PO.MULTI_MAX = 5
PO.SEND_MAX = 12          -- Anhaenge je Brief (ATTACHMENTS_MAX_SEND)

local function Opt(k) return K.Get(KEY, k) end
local function Active() return K.IsActive(KEY) and Opt("postOn") and true or false end
PO.Active = Active
local function Plain(v) return K.Plain(v) end
local function Say(text) print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " " .. text) end
PO.Say = Say

local function Money(c)
    local IV = WeintCodex.UIInventory
    if IV and IV.MoneyText then return IV.MoneyText(c) end
    return tostring(c)
end

-- Gespeichertes (kontoweit, in WeintCodex_SavedData - nie eine Ersatztabelle).
function PO.Store()
    local sd = _G.WeintCodex_SavedData
    if type(sd) ~= "table" then return nil end
    sd.postal = sd.postal or {}
    local p = sd.postal
    p.history = p.history or {}
    p.recent = p.recent or {}
    p.drafts = p.drafts or {}
    p.sent = p.sent or {}
    p.rules = p.rules or {}
    return p
end

local function Today()
    local ok, d = pcall(_G.date, "%Y-%m-%d")
    return ok and d or "?"
end

--------------------------------------------------
-- Briefkasten lesen
--------------------------------------------------

PO.mailOpen = false

-- Ein Brief: was der Client sagt, sonst nil.
function PO.Header(i)
    local f = _G.GetInboxHeaderInfo
    if not f then return nil end
    local ok, _, _, sender, subject, money, cod, days, count, wasRead, wasReturned, _, canReply, isGM = pcall(f, i)
    if not ok then return nil end
    return {
        index = i,
        sender = Plain(sender), subject = Plain(subject),
        money = tonumber(Plain(money)) or 0, cod = tonumber(Plain(cod)) or 0,
        days = tonumber(Plain(days)), count = tonumber(Plain(count)) or 0,
        read = Plain(wasRead) == true, returned = Plain(wasReturned) == true,
        canReply = Plain(canReply) == true, gm = Plain(isGM) == true,
    }
end

-- Schluessel eines Briefs - Nummern verschieben sich, wenn einer verschwindet.
function PO.Key(h)
    if not h then return nil end
    return table.concat({ tostring(h.sender), tostring(h.subject), tostring(h.money),
        tostring(h.cod), string.format("%.2f", h.days or -1) }, "\1")
end

function PO.Count()
    local n = _G.GetInboxNumItems and Plain(_G.GetInboxNumItems())
    return type(n) == "number" and n or 0
end

-- Anhaenge eines Briefs: { { slot, id, name, count, icon } }.
function PO.Items(i)
    local out = {}
    local f = _G.GetInboxItem
    if not f then return out end
    local max = tonumber(_G.ATTACHMENTS_MAX_RECEIVE) or 16
    for j = 1, max do
        local ok, name, id, icon, count = pcall(f, i, j)
        if ok and Plain(name) then
            out[#out + 1] = { slot = j, id = tonumber(Plain(id)), name = Plain(name), icon = Plain(icon),
                count = tonumber(Plain(count)) or 1 }
        end
    end
    return out
end

-- Freie Taschenplaetze (nil = weiss nicht).
function PO.FreeSlots()
    local cc = _G.C_Container
    if not (cc and cc.GetContainerNumFreeSlots) then return nil end
    local free = 0
    for bag = 0, tonumber(_G.NUM_BAG_SLOTS) or 4 do
        local ok, n = pcall(cc.GetContainerNumFreeSlots, bag)
        n = ok and Plain(n)
        if type(n) == "number" then free = free + n end
    end
    return free
end

-- Inhalt fuer den Bestand und die Posttasche.
function PO.Scan()
    local items, gold, letters = {}, 0, {}
    for i = 1, PO.Count() do
        local h = PO.Header(i)
        if h then
            gold = gold + (h.cod > 0 and 0 or h.money)
            h.items = PO.Items(i)
            letters[#letters + 1] = h
            for _, it in ipairs(h.items) do
                if it.id then
                    local e = items[it.id]
                    if not e then
                        e = { id = it.id, name = it.name, icon = it.icon, count = 0, letters = 0, cod = false, days = h.days }
                        items[it.id] = e
                    end
                    e.count = e.count + it.count
                    e.letters = e.letters + 1
                    if h.cod > 0 then e.cod = true end
                    if h.days and (not e.days or h.days < e.days) then e.days = h.days end
                end
            end
        end
    end
    PO.content = { items = items, gold = gold, letters = letters }
    local IV = WeintCodex.UIInventory
    if IV and IV.SetMail then
        local counts = {}
        for id, e in pairs(items) do counts[id] = e.count end
        IV.SetMail(counts)
    end
    return PO.content
end

--------------------------------------------------
-- Abholen: eine Schlange, ein Schritt je Takt
--------------------------------------------------
-- want(h) entscheidet je Brief, was genommen wird: "all", "money",
-- "items", { id = Gegenstand } oder nil. Je Takt EIN Aufruf ans Spiel,
-- dann warten (MAIL_INBOX_UPDATE oder postSpeed) - Briefe verschwinden,
-- Nummern verschieben sich, also wird jedes Mal neu gesucht.

local queue
PO.stats = { started = 0 }

local function Record(gold, id, count)
    local p = PO.Store()
    if not p then return end
    local day = Today()
    local d = p.history[day]
    if not d then d = { gold = 0, items = {} } p.history[day] = d end
    d.gold = d.gold + (gold or 0)
    if id then d.items[id] = (d.items[id] or 0) + (count or 1) end
end

function PO.PruneHistory()
    local p = PO.Store()
    if not p then return end
    local keep = {}
    for day in pairs(p.history) do keep[#keep + 1] = day end
    table.sort(keep)
    for i = 1, #keep - PO.HISTORY_DAYS do p.history[keep[i]] = nil end
end

local function Step()
    if not queue then return end
    if not PO.mailOpen then PO.Stop("Briefkasten geschlossen") return end
    local free = PO.FreeSlots()
    for i = PO.Count(), 1, -1 do
        local h = PO.Header(i)
        local w = h and h.cod == 0 and queue.want(h)
        if w then
            local takeMoney = (w == "all" or w == "money") and h.money > 0
            if takeMoney and _G.TakeInboxMoney then
                pcall(_G.TakeInboxMoney, i)
                queue.gold = queue.gold + h.money
                Record(h.money)
                return true
            end
            if w ~= "money" and h.count > 0 then
                if free and free <= 0 then
                    queue.full = true
                else
                    for _, it in ipairs(PO.Items(i)) do
                        if type(w) ~= "table" or w.id == it.id then
                            if _G.TakeInboxItem then
                                pcall(_G.TakeInboxItem, i, it.slot)
                                queue.items = queue.items + it.count
                                Record(0, it.id, it.count)
                                return true
                            end
                        end
                    end
                end
            end
            queue.skip[PO.Key(h)] = true
        end
    end
    PO.Stop()
end

PO._Step = Step

local driver = CreateFrame("Frame")
driver:Hide()
local acc = 0
driver:SetScript("OnUpdate", function(self, el)
    acc = acc + (el or 0)
    if acc < (tonumber(Opt("postSpeed")) or 0.5) then return end
    acc = 0
    local ok = pcall(Step)
    if not ok then PO.Stop("Fehler beim Abholen") end
    if PO.progress then PO.progress() end
end)

function PO.Run(label, want)
    if queue then return false end
    local skip = {}
    queue = { label = label, gold = 0, items = 0, full = false, skip = skip,
        want = function(h) if skip[PO.Key(h)] then return nil end return want(h) end }
    PO.stats.started = PO.stats.started + 1
    acc = 99
    driver:Show()
    return true
end

function PO.Busy() return queue ~= nil end

function PO.Stop(why)
    local q = queue
    queue = nil
    driver:Hide()
    PO.selected = {}
    if PO.Refresh then PO.Refresh() end
    if not q then return end
    PO.PruneHistory()
    if Opt("postSummary") and (q.gold > 0 or q.items > 0 or q.full or why) then
        local parts = {}
        if q.gold > 0 then parts[#parts + 1] = Money(q.gold) end
        if q.items > 0 then parts[#parts + 1] = q.items .. " Gegenstände" end
        local msg = "Post: " .. (#parts > 0 and table.concat(parts, " und ") .. " abgeholt" or "nichts abgeholt")
        if q.full then msg = msg .. " – Taschen voll, der Rest bleibt im Briefkasten" end
        if why then msg = msg .. " (" .. why .. ")" end
        Say(msg .. ".")
    end
end

-- Die fertigen Wuensche.
function PO.OpenAll() return PO.Run("Alle", function() return "all" end) end
function PO.OpenSelected()
    local sel = PO.selected or {}
    return PO.Run("Ausgewählte", function(h) return sel[PO.Key(h)] and "all" or nil end)
end
function PO.TakeGold() return PO.Run("Gold", function() return "money" end) end
function PO.TakeItems() return PO.Run("Gegenstände", function() return "items" end) end
function PO.TakeItem(id) return PO.Run("Gegenstand", function() return { id = id } end) end

--------------------------------------------------
-- Posteingang: Haken, Tooltip, Umschalt-Klick, Filter
--------------------------------------------------

PO.selected = {}
PO.filter = { text = "", unread = false, attach = false, cod = false, system = false }

function PO.Matches(h)
    local f = PO.filter
    if f.unread and h.read then return false end
    if f.attach and h.count == 0 and h.money == 0 then return false end
    if f.cod and h.cod == 0 then return false end
    if f.system and not (h.gm or not h.canReply) then return false end
    local t = f.text and f.text:lower() or ""
    if t ~= "" then
        local hay = ((h.sender or "") .. " " .. (h.subject or "")):lower()
        if not hay:find(t, 1, true) then
            local found = false
            for _, it in ipairs(PO.Items(h.index)) do
                if (it.name or ""):lower():find(t, 1, true) then found = true break end
            end
            if not found then return false end
        end
    end
    return true
end

local function RowIndex(row)
    local idx = row and (row.index or (row:GetID() ~= 0 and row:GetID()))
    return type(idx) == "number" and idx or nil
end

function PO.Tooltip(row)
    local gt = _G.GameTooltip
    local i = RowIndex(row)
    local h = i and PO.Header(i)
    if not (gt and h and gt.AddLine) then return end
    local m, g, r = C.textMuted, C.gold, C.red
    gt:AddLine(" ")
    if h.money > 0 then gt:AddLine("Gold: " .. Money(h.money), g[1], g[2], g[3]) end
    if h.cod > 0 then gt:AddLine("Nachnahme: " .. Money(h.cod) .. " – nur von Hand", r[1], r[2], r[3]) end
    local items = PO.Items(i)
    for n, it in ipairs(items) do
        if n > 8 then gt:AddLine("… und " .. (#items - 8) .. " weitere", m[1], m[2], m[3]) break end
        gt:AddLine((it.icon and ("|T" .. it.icon .. ":14|t ") or "") .. (it.name or "?")
            .. (it.count > 1 and (" ×" .. it.count) or ""), 1, 1, 1)
    end
    if h.days then
        local d = h.days >= 1 and string.format("%d Tage", math.floor(h.days))
            or string.format("%d Stunden", math.max(0, math.floor(h.days * 24)))
        gt:AddLine((h.returned and "Wird gelöscht in " or "Läuft ab in ") .. d, m[1], m[2], m[3])
    end
    if h.cod == 0 and (h.count > 0 or h.money > 0) then
        gt:AddLine("Umschalt-Klick: alles aus diesem Brief nehmen", m[1], m[2], m[3])
    end
    gt:Show()
end

local hooked = {}
local function HookRow(row, n)
    if hooked[row] then return end
    hooked[row] = true
    row:HookScript("OnEnter", function(self) if Active() then PO.Tooltip(self) end end)
    row:HookScript("OnClick", function(self)
        if not (Active() and _G.IsShiftKeyDown and _G.IsShiftKeyDown()) then return end
        local i = RowIndex(self)
        local h = i and PO.Header(i)
        if h and h.cod == 0 then
            local key = PO.Key(h)
            PO.Run("Brief", function(x) return PO.Key(x) == key and "all" or nil end)
        end
    end)
    local cb = CreateFrame("CheckButton", nil, row:GetParent() or row, "UICheckButtonTemplate")
    cb:SetSize(20, 20)
    cb:SetPoint("RIGHT", row, "LEFT", -2, 0)
    cb:SetScript("OnClick", function(self)
        local i = RowIndex(row)
        local h = i and PO.Header(i)
        if h then PO.selected[PO.Key(h)] = self:GetChecked() and true or nil end
        if PO.Refresh then PO.Refresh() end
    end)
    cb:SetScript("OnEnter", function(self)
        local gt = _G.GameTooltip
        if gt then gt:SetOwner(self, "ANCHOR_RIGHT") gt:SetText("Für „Ausgewählte öffnen“ markieren") gt:Show() end
    end)
    cb:SetScript("OnLeave", function() if _G.GameTooltip then _G.GameTooltip:Hide() end end)
    row._wcCheck = cb
    row._wcSlot = n
end

-- Nach jedem Neuzeichnen des Posteingangs: Haken setzen, Filter dimmen.
function PO.PaintRows()
    local per = tonumber(_G.INBOXITEMS_TO_DISPLAY) or 7
    local page = tonumber(_G.InboxFrame and _G.InboxFrame.pageNum) or 1
    local shown, match = 0, 0
    for n = 1, per do
        local row = _G["MailItem" .. n .. "Button"]
        local item = _G["MailItem" .. n]
        if type(row) == "table" then
            HookRow(row, n)
            local i = (page - 1) * per + n
            if not row.index then row.index = i end
            local h = Active() and PO.Header(row.index or i)
            local on = h and row:IsShown()
            row._wcCheck:SetShown(on and true or false)
            if on then
                shown = shown + 1
                row._wcCheck:SetChecked(PO.selected[PO.Key(h)] and true or false)
                local ok = PO.Matches(h)
                if ok then match = match + 1 end
                if type(item) == "table" and item.SetAlpha then item:SetAlpha(ok and 1 or 0.3) end
            elseif type(item) == "table" and item.SetAlpha then
                item:SetAlpha(1)
            end
        end
    end
    PO.lastPaint = { shown = shown, match = match }
end

--------------------------------------------------
-- Leiste am Posteingang
--------------------------------------------------

local bar
local function Btn(parent, text, w, onClick, tip)
    local b = WeintCodex.CreateButton(parent, { text = text, kind = "secondary", width = w, height = 22, size = 11,
        tooltip = tip, onClick = onClick })
    return b
end

-- Alles, was die Post-Hilfe mitbringt, steht in einer Leiste NEBEN dem
-- Postfenster – nie darüber (überlappte Felder und Knöpfe des Spiels).
PO.SIDE_W, PO.SIDE_BTN = 196, 176
local side
function PO.BuildSide()
    if side then return side end
    local mf = _G.MailFrame
    if type(mf) ~= "table" then return nil end
    side = CreateFrame("Frame", "WeintCodexPostSide", mf)
    side:SetSize(PO.SIDE_W, 300)
    side:SetPoint("TOPLEFT", mf, "TOPRIGHT", 6, 0)
    side:EnableMouse(true)
    K.Kachel(side, { shadow = 6 })
    side.title = K.NewText(side, 12)
    side.title:SetPoint("TOPLEFT", side, "TOPLEFT", 10, -10)
    side.title:SetTextColor(unpack(C.gold))
    side.title:SetText("Post-Hilfe")
    PO.side = side
    return side
end

function PO.BuildBar()
    if bar then return bar end
    local inbox = _G.InboxFrame
    local sd = PO.BuildSide()
    if type(inbox) ~= "table" or not sd then return nil end
    -- Kind des Posteingangs: sichtbar nur auf dessen Reiter.
    bar = CreateFrame("Frame", "WeintCodexPostBar", inbox)
    bar:SetPoint("TOPLEFT", sd, "TOPLEFT", 10, -30)
    bar:SetPoint("BOTTOMRIGHT", sd, "BOTTOMRIGHT", -10, 10)
    bar:SetFrameLevel((sd:GetFrameLevel() or 1) + 5)
    local W = PO.SIDE_BTN

    bar.all = Btn(bar, "Alle öffnen", W, function() PO.OpenAll() end,
        "Nimmt Gold und Gegenstände aus allen Briefen – Nachnahme nie.")
    bar.all:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 0)
    bar.sel = Btn(bar, "Ausgewählte", W, function() PO.OpenSelected() end,
        "Nur die Briefe mit Haken.")
    bar.sel:SetPoint("TOPLEFT", bar.all, "BOTTOMLEFT", 0, -4)
    bar.stop = Btn(bar, "Stopp", W, function() PO.Stop("angehalten") end)
    bar.stop:SetPoint("TOPLEFT", bar.sel, "BOTTOMLEFT", 0, -4)
    bar.bag = Btn(bar, "Posttasche", W, function() PO.ShowPostBag() end,
        "Alles im Postfach auf einen Blick, abholen per Klick.")
    bar.bag:SetPoint("TOPLEFT", bar.stop, "BOTTOMLEFT", 0, -4)

    bar.searchLabel = K.NewText(bar, 10)
    bar.searchLabel:SetPoint("TOPLEFT", bar.bag, "BOTTOMLEFT", 0, -12)
    bar.searchLabel:SetTextColor(unpack(C.textMuted))
    bar.searchLabel:SetText("Suchen und filtern")
    local search = CreateFrame("EditBox", nil, bar, "InputBoxTemplate")
    search:SetSize(W - 6, 18)
    search:SetPoint("TOPLEFT", bar.searchLabel, "BOTTOMLEFT", 6, -4)
    search:SetAutoFocus(false)
    search:SetScript("OnTextChanged", function(self)
        PO.filter.text = self:GetText() or ""
        PO.PaintRows()
    end)
    search:SetScript("OnEscapePressed", function(self) self:SetText("") self:ClearFocus() end)
    bar.search = search

    bar.chips = {}
    for i, f in ipairs({ { "unread", "Ungelesen" }, { "attach", "Anhang" }, { "cod", "Nachnahme" }, { "system", "System" } }) do
        local key = f[1]
        local chip = Btn(bar, f[2], (W - 4) / 2, nil)
        chip:SetHeight(18)
        local col, row = (i - 1) % 2, math.floor((i - 1) / 2)
        chip:SetPoint("TOPLEFT", search, "BOTTOMLEFT", -6 + col * (W / 2 + 2), -6 - row * 22)
        chip:SetScript("OnClick", function(self)
            PO.filter[key] = not PO.filter[key]
            self:SetAlpha(PO.filter[key] and 1 or 0.6)
            PO.PaintRows()
        end)
        chip:SetAlpha(0.6)
        bar.chips[key] = chip
    end

    bar.status = K.NewText(bar, 10)
    bar.status:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", 0, 0)
    bar.status:SetTextColor(unpack(C.textMuted))
    PO.bar = bar
    return bar
end

function PO.Refresh()
    if side then side:SetShown(Active()) end
    if not bar then return end
    local busy = PO.Busy()
    local nsel = 0
    for _ in pairs(PO.selected) do nsel = nsel + 1 end
    bar.all:SetEnabled(not busy)
    bar.sel:SetEnabled(not busy and nsel > 0)
    bar.stop:SetShown(busy)
    if bar.sel.SetText then bar.sel:SetText(nsel > 0 and ("Ausgewählte (" .. nsel .. ")") or "Ausgewählte") end
    PO.PaintRows()
    if PO.RefreshBag then PO.RefreshBag() end
    if PO.RefreshRules then PO.RefreshRules() end
end

PO.progress = function()
    if bar and queue then
        local left = 0
        for i = 1, PO.Count() do local h = PO.Header(i) if h and (h.money > 0 or h.count > 0) and h.cod == 0 then left = left + 1 end end
        bar.status:SetText(string.format("Hole ab … noch %d Briefe", left))
    elseif bar then
        bar.status:SetText("")
    end
end

--------------------------------------------------
-- Posttasche
--------------------------------------------------

local bag
PO.BAG_COLS, PO.BAG_SLOT = 6, 34

function PO.BuildBag()
    if bag then return bag end
    local mf = _G.MailFrame
    if type(mf) ~= "table" then return nil end
    bag = CreateFrame("Frame", "WeintCodexPostBag", mf)
    bag:SetSize(PO.BAG_COLS * (PO.BAG_SLOT + 4) + 20, 330)
    local sd = PO.BuildSide()
    bag:SetPoint("TOPLEFT", sd or mf, "TOPRIGHT", 6, 0)
    bag:EnableMouse(true)
    K.Kachel(bag, { shadow = 6 })
    bag.title = K.NewText(bag, 13)
    bag.title:SetPoint("TOPLEFT", bag, "TOPLEFT", 10, -10)
    bag.title:SetTextColor(unpack(C.textBright))
    bag.title:SetText("Posttasche")
    bag.info = K.NewText(bag, 10)
    bag.info:SetPoint("TOPLEFT", bag.title, "BOTTOMLEFT", 0, -3)
    bag.info:SetTextColor(unpack(C.textMuted))
    bag.slots = {}
    bag.gold = Btn(bag, "Nur Gold", 70, function() PO.TakeGold() end)
    bag.gold:SetPoint("BOTTOMLEFT", bag, "BOTTOMLEFT", 10, 10)
    bag.items = Btn(bag, "Nur Gegenst.", 80, function() PO.TakeItems() end)
    bag.items:SetPoint("LEFT", bag.gold, "RIGHT", 4, 0)
    bag.all = Btn(bag, "Alles", 50, function() PO.OpenAll() end)
    bag.all:SetPoint("LEFT", bag.items, "RIGHT", 4, 0)
    bag.hist = Btn(bag, "Verlauf", 56, function() PO.ShowHistory() end)
    bag.hist:SetPoint("LEFT", bag.all, "RIGHT", 4, 0)
    bag:Hide()
    PO.bag = bag
    return bag
end

local function BagSlot(i)
    local s = bag.slots[i]
    if s then return s end
    s = CreateFrame("Button", nil, bag)
    s:SetSize(PO.BAG_SLOT, PO.BAG_SLOT)
    local col, row = (i - 1) % PO.BAG_COLS, math.floor((i - 1) / PO.BAG_COLS)
    s:SetPoint("TOPLEFT", bag, "TOPLEFT", 10 + col * (PO.BAG_SLOT + 4), -44 - row * (PO.BAG_SLOT + 4))
    s.icon = s:CreateTexture(nil, "ARTWORK")
    s.icon:SetAllPoints(s)
    s.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    K.Border(s, 1, 0, 0, 0, 1, "OVERLAY")
    s.count = K.NewText(s, 11)
    s.count:SetPoint("BOTTOMRIGHT", s, "BOTTOMRIGHT", -2, 2)
    s:SetScript("OnClick", function(self)
        if self.entry and not self.entry.cod then PO.TakeItem(self.entry.id) end
    end)
    s:SetScript("OnEnter", function(self)
        local e, gt = self.entry, _G.GameTooltip
        if not (e and gt) then return end
        gt:SetOwner(self, "ANCHOR_RIGHT")
        if gt.SetItemByID then pcall(gt.SetItemByID, gt, e.id) else gt:SetText(e.name or "?") end
        local m = C.textMuted
        gt:AddLine(" ")
        gt:AddLine(string.format("%d Stück in %d Brief(en)", e.count, e.letters), m[1], m[2], m[3])
        if e.days then gt:AddLine(string.format("Nächster Ablauf: %.1f Tage", e.days), m[1], m[2], m[3]) end
        if e.cod then gt:AddLine("Nachnahme – nur von Hand", C.red[1], C.red[2], C.red[3])
        else gt:AddLine("Klick: alle Stapel abholen", C.green[1], C.green[2], C.green[3]) end
        gt:Show()
    end)
    s:SetScript("OnLeave", function() if _G.GameTooltip then _G.GameTooltip:Hide() end end)
    bag.slots[i] = s
    return s
end

function PO.RefreshBag()
    if not (bag and bag:IsShown()) then return end
    local c = PO.Scan()
    local list = {}
    for _, e in pairs(c.items) do list[#list + 1] = e end
    table.sort(list, function(a, b) return (a.name or "") < (b.name or "") end)
    local max = PO.BAG_COLS * 7
    for i = 1, math.max(#list, #bag.slots) do
        local e = list[i]
        if e and i <= max then
            local s = BagSlot(i)
            s.entry = e
            s.icon:SetTexture(e.icon)
            s.icon:SetDesaturated(e.cod and true or false)
            s.count:SetText(e.count > 1 and tostring(e.count) or "")
            s:Show()
        elseif bag.slots[i] then
            bag.slots[i]:Hide()
            bag.slots[i].entry = nil
        end
    end
    local more = #list > max and ("  •  +" .. (#list - max) .. " weitere") or ""
    bag.info:SetText(#list == 0 and c.gold == 0 and "Keine Gegenstände oder Gold im Postfach"
        or string.format("%d Gegenstände  •  Gold: %s%s", #list, Money(c.gold), more))
    local busy = PO.Busy()
    bag.gold:SetEnabled(not busy and c.gold > 0)
    bag.items:SetEnabled(not busy and #list > 0)
    bag.all:SetEnabled(not busy)
end

function PO.ShowPostBag(on)
    local b = PO.BuildBag()
    if not b then return end
    if on == nil then on = not b:IsShown() end
    b:SetShown(on)
    PO.RefreshBag()
end

function PO.HistoryLines()
    local p = PO.Store()
    local days = {}
    for day in pairs(p and p.history or {}) do days[#days + 1] = day end
    table.sort(days, function(a, b) return a > b end)
    local out = { "Abgeholte Post der letzten " .. PO.HISTORY_DAYS .. " Tage", "" }
    local IV = WeintCodex.UIInventory
    local names = IV and IV.Store and IV.Store(false)
    names = names and names.names or {}
    for _, day in ipairs(days) do
        local d = p.history[day]
        out[#out + 1] = day .. "  ·  Gold: " .. Money(d.gold)
        local items = {}
        for id, n in pairs(d.items) do items[#items + 1] = string.format("   %s ×%d", names[id] or ("#" .. id), n) end
        table.sort(items)
        for _, l in ipairs(items) do out[#out + 1] = l end
    end
    if #days == 0 then out[#out + 1] = "Noch nichts über WeintCodex abgeholt." end
    return out
end

function PO.ShowHistory()
    if K.ShowReport then K.ShowReport("Post – Verlauf", PO.HistoryLines()) end
end

--------------------------------------------------
-- Schreiben: Kontakte, Entwuerfe, Gesendet, mehrere Empfaenger
--------------------------------------------------

local function MyRealm()
    local r = _G.GetRealmName and Plain(_G.GetRealmName())
    return type(r) == "string" and r or nil
end

-- Eigene Twinks auf diesem Realm und in dieser Fraktion (aus dem Bestand).
function PO.Alts()
    local IV = WeintCodex.UIInventory
    local st = IV and IV.Store and IV.Store(false)
    local out = {}
    if not st then return out end
    local me = _G.UnitName and Plain(_G.UnitName("player"))
    local realm = MyRealm()
    local fac = _G.UnitFactionGroup and Plain(_G.UnitFactionGroup("player"))
    for _, c in pairs(st.chars) do
        if c.name and c.name ~= me and c.realm == realm and (not c.faction or c.faction == fac) then
            out[#out + 1] = c.name
        end
    end
    table.sort(out)
    return out
end

function PO.IsAlt(name)
    for _, n in ipairs(PO.Alts()) do if n == name then return true end end
    return false
end

function PO.NoteRecent(name)
    local p = PO.Store()
    if not (p and type(name) == "string" and name ~= "") then return end
    for i = #p.recent, 1, -1 do if p.recent[i] == name then table.remove(p.recent, i) end end
    table.insert(p.recent, 1, name)
    while #p.recent > PO.RECENT_MAX do table.remove(p.recent) end
end

-- Was gerade im Brief steht (Anhaenge), fuer "Gesendet" und den Bestand.
function PO.SendAttachments()
    local out = {}
    local f = _G.GetSendMailItem
    if not f then return out end
    for j = 1, tonumber(_G.ATTACHMENTS_MAX_SEND) or PO.SEND_MAX do
        local ok, name, id, _, count = pcall(f, j)
        if ok and Plain(name) then
            out[#out + 1] = { id = tonumber(Plain(id)), name = Plain(name), count = tonumber(Plain(count)) or 1 }
        end
    end
    return out
end

-- Vom Spiel aufgerufen (hooksecurefunc auf SendMail): nur mitschreiben.
function PO.OnSend(name, subject)
    if not Active() then return end
    local p = PO.Store()
    if not p then return end
    local money = _G.GetSendMailMoney and tonumber(Plain(_G.GetSendMailMoney())) or 0
    local items = PO.SendAttachments()
    table.insert(p.sent, 1, { to = name, subject = subject, money = money, items = items,
        at = _G.time and _G.time() or 0 })
    while #p.sent > PO.SENT_MAX do table.remove(p.sent) end
    PO.NoteRecent(name)
    local IV = WeintCodex.UIInventory
    if IV and IV.AddMail and PO.IsAlt(name) then
        for _, it in ipairs(items) do if it.id then IV.AddMail(name, MyRealm(), it.id, it.count) end end
    end
end

function PO.SentLines()
    local p = PO.Store()
    local out = { "Gesendete Briefe (die letzten " .. PO.SENT_MAX .. ")", "" }
    for _, s in ipairs(p and p.sent or {}) do
        local when = "?"
        pcall(function() when = date("%d.%m. %H:%M", s.at) end)
        local items = {}
        for _, it in ipairs(s.items or {}) do items[#items + 1] = (it.name or "?") .. (it.count > 1 and (" ×" .. it.count) or "") end
        out[#out + 1] = string.format("%s  an %s  ·  %s%s%s", when, tostring(s.to), tostring(s.subject or ""),
            (s.money or 0) > 0 and ("  ·  " .. Money(s.money)) or "",
            #items > 0 and ("  ·  " .. table.concat(items, ", ")) or "")
    end
    if not (p and #p.sent > 0) then out[#out + 1] = "Noch nichts über diesen Briefkasten gesendet." end
    return out
end

function PO.SaveDraft()
    local p = PO.Store()
    if not p then return false end
    local name = _G.SendMailNameEditBox and _G.SendMailNameEditBox:GetText() or ""
    local subject = _G.SendMailSubjectEditBox and _G.SendMailSubjectEditBox:GetText() or ""
    local body = _G.SendMailBodyEditBox and _G.SendMailBodyEditBox:GetText() or ""
    if subject == "" and body == "" then Say("Der Brief ist leer – nichts gespeichert.") return false end
    table.insert(p.drafts, 1, { to = name, subject = subject, body = body, at = _G.time and _G.time() or 0 })
    while #p.drafts > PO.DRAFTS_MAX do table.remove(p.drafts) end
    Say("Entwurf gespeichert.")
    return true
end

function PO.LoadDraft(d)
    if not d then return end
    if _G.SendMailNameEditBox then _G.SendMailNameEditBox:SetText(d.to or "") end
    if _G.SendMailSubjectEditBox then _G.SendMailSubjectEditBox:SetText(d.subject or "") end
    if _G.SendMailBodyEditBox then _G.SendMailBodyEditBox:SetText(d.body or "") end
end

-- Eine kleine Liste zum Auswaehlen (Kontakte, Entwuerfe).
local menu
function PO.Menu(anchor, entries)
    if not menu then
        menu = CreateFrame("Frame", "WeintCodexPostMenu", UIParent)
        menu:SetFrameStrata("FULLSCREEN_DIALOG")
        menu:EnableMouse(true)
        K.Kachel(menu, { shadow = 6 })
        menu.rows = {}
        if type(_G.UISpecialFrames) == "table" then table.insert(_G.UISpecialFrames, "WeintCodexPostMenu") end
    end
    for _, r in ipairs(menu.rows) do r:Hide() end
    local y = -6
    for i, e in ipairs(entries) do
        local r = menu.rows[i]
        if not r then
            r = CreateFrame("Button", nil, menu)
            r:SetHeight(18)
            r.text = K.NewText(r, 11)
            r.text:SetPoint("LEFT", r, "LEFT", 8, 0)
            local hl = r:CreateTexture(nil, "HIGHLIGHT")
            hl:SetAllPoints(r)
            hl:SetColorTexture(1, 1, 1, 0.06)
            menu.rows[i] = r
        end
        r:SetPoint("TOPLEFT", menu, "TOPLEFT", 4, y)
        r:SetPoint("RIGHT", menu, "RIGHT", -4, 0)
        r.text:SetText(e.text)
        r.text:SetTextColor(unpack(e.header and C.textMuted or C.textNormal))
        r:SetEnabled(not e.header)
        r:SetScript("OnClick", function() menu:Hide() if e.onClick then e.onClick() end end)
        r:Show()
        y = y - 18
    end
    menu:SetSize(200, -y + 6)
    menu:ClearAllPoints()
    menu:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
    menu:Show()
    return menu
end

function PO.ContactEntries()
    local out = {}
    local function pick(n) return function() if _G.SendMailNameEditBox then _G.SendMailNameEditBox:SetText(n) end end end
    local alts = PO.Alts()
    if #alts > 0 then
        out[#out + 1] = { text = "Eigene Twinks", header = true }
        for _, n in ipairs(alts) do out[#out + 1] = { text = n, onClick = pick(n) } end
    end
    local p = PO.Store()
    if p and #p.recent > 0 then
        out[#out + 1] = { text = "Zuletzt angeschrieben", header = true }
        for i, n in ipairs(p.recent) do if i <= 8 then out[#out + 1] = { text = n, onClick = pick(n) } end end
    end
    if #out == 0 then out[1] = { text = "Noch keine Kontakte", header = true } end
    return out
end

function PO.DraftEntries()
    local p = PO.Store()
    local out = { { text = "Entwurf speichern", onClick = function() PO.SaveDraft() end } }
    for _, d in ipairs(p and p.drafts or {}) do
        local s = (d.subject ~= "" and d.subject or "(ohne Betreff)") .. (d.to ~= "" and ("  → " .. d.to) or "")
        out[#out + 1] = { text = WeintCodex.Truncate and WeintCodex.Truncate(s, 30) or s, onClick = function() PO.LoadDraft(d) end }
    end
    return out
end

-- Mehrere Empfaenger: derselbe Text (und dasselbe Gold) an jeden, ein
-- Brief je Klick-Takt. Mit Anhaengen nicht - die gibt es nur einmal.
function PO.SplitNames(text)
    local out, seen = {}, {}
    for n in tostring(text or ""):gmatch("[^,;%s]+") do
        if not seen[n] then seen[n] = true out[#out + 1] = n end
    end
    return out
end

local multi
function PO.SendMulti(names)
    if multi then return false, "Läuft schon." end
    if #names < 2 then return false, "Mindestens zwei Namen, durch Komma getrennt." end
    if #names > PO.MULTI_MAX then return false, "Höchstens " .. PO.MULTI_MAX .. " Empfänger auf einmal." end
    if #PO.SendAttachments() > 0 then return false, "Mit Anhängen geht das nicht – Gegenstände gibt es nur einmal." end
    local subject = _G.SendMailSubjectEditBox and _G.SendMailSubjectEditBox:GetText() or ""
    local body = _G.SendMailBodyEditBox and _G.SendMailBodyEditBox:GetText() or ""
    if subject == "" then return false, "Bitte einen Betreff eingeben." end
    local money = _G.GetSendMailMoney and tonumber(Plain(_G.GetSendMailMoney())) or 0
    local postage = (_G.GetSendMailPrice and tonumber(Plain(_G.GetSendMailPrice()))) or 30
    local total = (money + postage) * #names
    local have = _G.GetMoney and tonumber(Plain(_G.GetMoney())) or 0
    if total > have then return false, "Nicht genug Gold: nötig " .. Money(total) .. "." end
    multi = { names = names, i = 0, subject = subject, body = body, money = money }
    return true, string.format("Sende an %d Empfänger (zusammen %s) …", #names, Money(total))
end

local multiTick = CreateFrame("Frame")
local macc = 0
multiTick:SetScript("OnUpdate", function(_, el)
    if not multi then return end
    macc = macc + (el or 0)
    if macc < 1.2 then return end
    macc = 0
    multi.i = multi.i + 1
    local n = multi.names[multi.i]
    if not n or not PO.mailOpen then
        Say(n and "Briefkasten geschlossen – Versand an mehrere abgebrochen." or
            ("Brief an " .. #multi.names .. " Empfänger gesendet."))
        multi = nil
        return
    end
    if multi.money > 0 and _G.SetSendMailMoney then pcall(_G.SetSendMailMoney, multi.money) end
    if _G.SendMail then pcall(_G.SendMail, n, multi.subject, multi.body) end
end)

--------------------------------------------------
-- Versandregeln
--------------------------------------------------
-- rule = { id = Gegenstand oder nil, kind = Art oder nil, to = Name,
--          keep = behalten (Stueck), full = nur volle Stapel,
--          scope = "account" oder Charakterschluessel, on = true }

PO.KINDS = {
    { value = "item",    text = "Bestimmter Gegenstand" },
    { value = "trade",   text = "Handwerkswaren" },
    { value = "consume", text = "Verbrauchbares & Essen" },
    { value = "gray",    text = "Graues (Händlerplunder)" },
    { value = "boe",     text = "Ungebundene Ausrüstung" },
}

local function CharKey()
    local n = _G.UnitName and Plain(_G.UnitName("player"))
    return tostring(n) .. "-" .. tostring(MyRealm())
end
PO.CharKey = CharKey

function PO.Rules()
    local p = PO.Store()
    local out = {}
    local me = CharKey()
    for _, r in ipairs(p and p.rules or {}) do
        if r.on ~= false and (r.scope == "account" or r.scope == me) then out[#out + 1] = r end
    end
    return out
end

-- Gehoert ein Taschengegenstand zur Regel?
function PO.RuleMatches(r, it)
    if it.bound then return false end
    if r.kind == "item" or (not r.kind and r.id) then return it.id == r.id end
    if r.kind == "trade" then return it.classID == 7 end
    if r.kind == "consume" then return it.classID == 0 end
    if r.kind == "gray" then return it.quality == 0 end
    if r.kind == "boe" then return (it.classID == 2 or it.classID == 4) and (it.quality or 0) >= 2 end
    return false
end

-- Taschen lesen: { { bag, slot, id, count, bound, quality, classID, max } }
function PO.BagItems()
    local out = {}
    local cc = _G.C_Container
    if not (cc and cc.GetContainerNumSlots and cc.GetContainerItemInfo) then return out end
    for bag = 0, tonumber(_G.NUM_BAG_SLOTS) or 4 do
        local ok, n = pcall(cc.GetContainerNumSlots, bag)
        n = ok and Plain(n)
        for slot = 1, type(n) == "number" and n or 0 do
            local ok2, info = pcall(cc.GetContainerItemInfo, bag, slot)
            if ok2 and type(info) == "table" and type(Plain(info.itemID)) == "number" then
                local id = Plain(info.itemID)
                local classID, maxStack
                if _G.GetItemInfoInstant then
                    local r = { pcall(_G.GetItemInfoInstant, id) }
                    if r[1] then classID = Plain(r[7]) end
                end
                if _G.GetItemInfo then
                    local r = { pcall(_G.GetItemInfo, id) }
                    if r[1] then maxStack = Plain(r[9]) end
                end
                out[#out + 1] = { bag = bag, slot = slot, id = id, count = Plain(info.stackCount) or 1,
                    bound = Plain(info.isBound) == true, quality = Plain(info.quality),
                    classID = classID, max = tonumber(maxStack), link = Plain(info.hyperlink) }
            end
        end
    end
    return out
end

-- Plan: { [Empfaenger] = { Taschenplaetze ... } } - erste passende Regel
-- gewinnt, "behalten" ohne Stapel zu teilen (nur ganze Stapel gehen).
function PO.Plan()
    local plan, count = {}, 0
    local me = _G.UnitName and Plain(_G.UnitName("player"))
    local items = PO.BagItems()
    local used = {}
    for _, r in ipairs(PO.Rules()) do
        if r.to and r.to ~= "" and r.to ~= me then
            local cand, total = {}, 0
            for _, it in ipairs(items) do
                if not used[it] and PO.RuleMatches(r, it) and (not r.full or (it.max and it.count >= it.max)) then
                    cand[#cand + 1] = it
                    total = total + it.count
                end
            end
            table.sort(cand, function(a, b) return a.count > b.count end)
            local keep = tonumber(r.keep) or 0
            for _, it in ipairs(cand) do
                if total - it.count >= keep then
                    plan[r.to] = plan[r.to] or {}
                    table.insert(plan[r.to], it)
                    used[it] = true
                    total = total - it.count
                    count = count + 1
                end
            end
        end
    end
    return plan, count
end

function PO.PlanLines()
    local plan, n = PO.Plan()
    local out = { n == 0 and "Kein Gegenstand in deinen Taschen passt zu einer Versandregel."
        or string.format("%d Stapel bereit zum Senden:", n), "" }
    for to, list in pairs(plan) do
        local letters = math.ceil(#list / PO.SEND_MAX)
        out[#out + 1] = string.format("an %s (%d Brief%s):", to, letters, letters == 1 and "" or "e")
        for _, it in ipairs(list) do
            out[#out + 1] = "   " .. (it.link and K.PlainText(it.link) or ("#" .. it.id)) .. " ×" .. it.count
        end
    end
    return out
end

-- EIN Brief je Klick: die ersten bis zu 12 Stapel fuer den ersten
-- Empfaenger anhaengen und senden. Liefert, was gesendet wurde, oder nil
-- und einen Satz.
function PO.SendNextRuleLetter()
    if not PO.mailOpen then return nil, "Erst einen Briefkasten öffnen." end
    if K.InCombat and K.InCombat() then return nil, "Nicht im Kampf." end
    local plan = PO.Plan()
    local to, list
    for k, v in pairs(plan) do to, list = k, v break end
    if not to then return nil, "Nichts mehr zu senden." end
    if #PO.SendAttachments() > 0 then return nil, "Im Brief liegen schon Anhänge – erst leeren." end
    local cc = _G.C_Container
    if not (cc and cc.PickupContainerItem and _G.ClickSendMailItemButton and _G.SendMail) then
        return nil, "Das Spiel lässt Anhänge nicht setzen."
    end
    local n = 0
    for _, it in ipairs(list) do
        if n >= PO.SEND_MAX then break end
        n = n + 1
        pcall(cc.PickupContainerItem, it.bag, it.slot)
        pcall(_G.ClickSendMailItemButton, n)
        if _G.ClearCursor then pcall(_G.ClearCursor) end
    end
    local got = #PO.SendAttachments()
    if got == 0 then return nil, "Anhängen hat nicht geklappt." end
    local ok = pcall(_G.SendMail, to, "WeintCodex: " .. got .. " Stapel", "Automatisch nach deinen Versandregeln gesendet.")
    if not ok then return nil, "Senden abgelehnt." end
    return to, got
end

local rulesBar
function PO.BuildRulesBar()
    if rulesBar then return rulesBar end
    local sf = _G.SendMailFrame
    local sd = PO.BuildSide()
    if type(sf) ~= "table" or not sd then return nil end
    local W = PO.SIDE_BTN
    -- Kind von „Post versenden“: sichtbar nur auf dessen Reiter.
    local host = CreateFrame("Frame", nil, sf)
    host:SetPoint("TOPLEFT", sd, "TOPLEFT", 10, -30)
    host:SetPoint("BOTTOMRIGHT", sd, "BOTTOMRIGHT", -10, 10)
    host:SetFrameLevel((sd:GetFrameLevel() or 1) + 5)
    rulesBar = CreateFrame("Frame", nil, host)
    rulesBar:SetSize(W, 84)
    rulesBar:SetPoint("TOPLEFT", host, "TOPLEFT", 0, -130)
    rulesBar.text = K.NewText(rulesBar, 11)
    rulesBar.text:SetPoint("TOPLEFT", rulesBar, "TOPLEFT", 0, 0)
    rulesBar.text:SetTextColor(unpack(C.gold))
    rulesBar.send = Btn(rulesBar, "Nach Regeln senden", W, function()
        local to, got = PO.SendNextRuleLetter()
        if to then Say(string.format("Versandregel: %d Stapel an %s gesendet.", got, to))
        else Say(tostring(got)) end
        if _G.C_Timer and _G.C_Timer.After then _G.C_Timer.After(1, PO.RefreshRules) end
    end, "Sendet den nächsten Brief nach deinen Regeln – ein Brief je Klick.")
    rulesBar.send:SetPoint("TOPLEFT", rulesBar.text, "BOTTOMLEFT", 0, -6)
    rulesBar.preview = Btn(rulesBar, "Vorschau", W, function()
        if K.ShowReport then K.ShowReport("Versandregeln – Vorschau", PO.PlanLines()) end
    end)
    rulesBar.preview:SetPoint("TOPLEFT", rulesBar.send, "BOTTOMLEFT", 0, -4)

    rulesBar.contacts = Btn(host, "Kontakte", W, function(self) PO.Menu(self, PO.ContactEntries()) end)
    rulesBar.contacts:SetPoint("TOPLEFT", host, "TOPLEFT", 0, 0)
    rulesBar.drafts = Btn(host, "Entwürfe", W, function(self) PO.Menu(self, PO.DraftEntries()) end)
    rulesBar.drafts:SetPoint("TOPLEFT", rulesBar.contacts, "BOTTOMLEFT", 0, -4)
    rulesBar.multi = Btn(host, "An mehrere", W, function()
        local names = PO.SplitNames(_G.SendMailNameEditBox and _G.SendMailNameEditBox:GetText())
        local ok, msg = PO.SendMulti(names)
        Say(msg)
    end, "Namen durch Komma getrennt ins Feld „An“ schreiben – derselbe Brief (ohne Anhänge) an jeden.")
    rulesBar.multi:SetPoint("TOPLEFT", rulesBar.drafts, "BOTTOMLEFT", 0, -4)
    rulesBar.sent = Btn(host, "Gesendet", W, function()
        if K.ShowReport then K.ShowReport("Post – Gesendet", PO.SentLines()) end
    end)
    rulesBar.sent:SetPoint("TOPLEFT", rulesBar.multi, "BOTTOMLEFT", 0, -4)
    PO.rulesBar = rulesBar
    return rulesBar
end

function PO.RefreshRules()
    if not rulesBar then return end
    local compose = Active() and Opt("postCompose")
    for _, b in ipairs({ rulesBar.contacts, rulesBar.drafts, rulesBar.multi, rulesBar.sent }) do b:SetShown(compose and true or false) end
    if not (Active() and Opt("postRules")) then rulesBar:Hide() return end
    local _, n = PO.Plan()
    rulesBar:SetShown(n > 0)
    rulesBar.text:SetText(string.format("Versandregeln: %d Stapel bereit", n))
end

-- Regeln verwalten (Seite im Komfort).
function PO.AddRule(r)
    local p = PO.Store()
    if not p then return false, "Kein Speicher." end
    if not (type(r.to) == "string" and r.to:match("%S")) then return false, "Bitte einen Empfänger angeben." end
    if r.kind == "item" and not r.id then return false, "Gegenstand nicht gefunden – Name (aus den Taschen) oder Nummer eingeben." end
    r.to = r.to:gsub("^%s+", ""):gsub("%s+$", "")
    r.on = true
    table.insert(p.rules, r)
    return true
end

function PO.RemoveRule(i)
    local p = PO.Store()
    if p and p.rules[i] then table.remove(p.rules, i) return true end
    return false
end

-- Name oder Nummer eines Gegenstands -> Nummer (aus den Taschen oder dem Spiel).
function PO.ResolveItem(text)
    text = tostring(text or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if text == "" then return nil end
    local id = tonumber(text) or tonumber(text:match("item:(%d+)"))
    if id then return id end
    local low = text:lower()
    for _, it in ipairs(PO.BagItems()) do
        local nm = it.link and it.link:match("%[(.-)%]")
        if nm and nm:lower() == low then return it.id end
    end
    if _G.GetItemInfoInstant then
        local ok, got = pcall(_G.GetItemInfoInstant, text)
        if ok and type(Plain(got)) == "number" then return Plain(got) end
    end
    return nil
end

function PO.RuleText(r)
    local kind = r.kind or "item"
    local what = kind
    for _, k in ipairs(PO.KINDS) do if k.value == kind then what = k.text end end
    if kind == "item" then
        local IV = WeintCodex.UIInventory
        local st = IV and IV.Store and IV.Store(false)
        what = (st and st.names[r.id]) or ("Gegenstand #" .. tostring(r.id))
    end
    local extra = {}
    if (tonumber(r.keep) or 0) > 0 then extra[#extra + 1] = r.keep .. " behalten" end
    if r.full then extra[#extra + 1] = "nur volle Stapel" end
    extra[#extra + 1] = r.scope == "account" and "alle Charaktere" or "nur dieser Charakter"
    return string.format("%s → %s  (%s)", what, tostring(r.to), table.concat(extra, ", "))
end

--------------------------------------------------
-- Ereignisse
--------------------------------------------------

local function OnMailShow()
    PO.mailOpen = true
    if not Active() then return end
    PO.BuildBar()
    PO.BuildRulesBar()
    if bar then bar:Show() end
    if Opt("postBag") then PO.ShowPostBag(false) end
    PO.Scan()
    PO.Refresh()
end

local ev = CreateFrame("Frame")
for _, e in ipairs({ "MAIL_SHOW", "MAIL_CLOSED", "MAIL_INBOX_UPDATE", "BAG_UPDATE_DELAYED", "MAIL_SEND_SUCCESS" }) do
    pcall(ev.RegisterEvent, ev, e)
end
ev:SetScript("OnEvent", function(_, event)
    if event == "MAIL_SHOW" then return OnMailShow() end
    if event == "MAIL_CLOSED" then
        PO.mailOpen = false
        if queue then PO.Stop("Briefkasten geschlossen") end
        multi = nil
        if bag then bag:Hide() end
        return
    end
    if not PO.mailOpen then return end
    if event == "MAIL_INBOX_UPDATE" then
        PO.Scan()
        if queue then acc = 99 end
    end
    if Active() then PO.Refresh() end
end)
PO.events = ev

if _G.hooksecurefunc then
    if _G.InboxFrame_Update then
        pcall(_G.hooksecurefunc, "InboxFrame_Update", function() if Active() then PO.PaintRows() end end)
    end
    if _G.SendMail then
        pcall(_G.hooksecurefunc, "SendMail", function(name, subject) PO.OnSend(name, subject) end)
    end
end

K.Listen(function(kind, key)
    if (kind == "active" or kind == "setting") and key == KEY then
        if bar then bar:SetShown(Active() and true or false) end
        if bag and not (Active() and Opt("postBag")) then bag:Hide() end
        if PO.mailOpen then PO.Refresh() end
    end
end)

--------------------------------------------------
-- Seite im Komfort
--------------------------------------------------

local draft = { to = "", item = "", kind = "item", keep = 0, full = false, account = false }

local function Build(B)
    local off = function() return not Opt("postOn") end
    B:Section("Posteingang", "Am Briefkasten: „Alle öffnen“, Haken für „Ausgewählte“, Umschalt-Klick auf einen Brief, Suche und Filter, Tooltip mit Anhängen und Ablauf. Briefe mit Nachnahme nimmt WeintCodex nie von selbst.")
    B:Row({ type = "toggle", label = "Post-Hilfen", key = "postOn" },
          { type = "slider", label = "Tempo beim Öffnen", key = "postSpeed", min = 0.2, max = 1.5, step = 0.1, disabled = off,
            format = function(v) return string.format("%.1f s", v) end,
            tooltip = "Pause zwischen zwei Schritten. Zu schnell, und der Server lehnt ab." })
    B:Row({ type = "toggle", label = "Zusammenfassung im Chat", key = "postSummary", disabled = off },
          { type = "toggle", label = "Posttasche", key = "postBag", disabled = off,
            description = "Alles im Postfach als eine Ansicht neben dem Briefkasten." })
    B:Row({ type = "toggle", label = "Schreiben: Kontakte, Entwürfe, an mehrere", key = "postCompose", disabled = off },
          { type = "toggle", label = "Versandregeln", key = "postRules", disabled = off })
    B:Section("Versandregeln", "Gegenstände an deine Twinks: am Briefkasten erscheint „Versandregeln: N Stapel bereit“ – jeder Brief geht erst mit deinem Klick. Seelengebundenes nie.")
    B:Row({ type = "dropdown", label = "Was", items = PO.KINDS,
            get = function() return draft.kind end, set = function(v) draft.kind = v end },
          { type = "input", label = "Gegenstand (Name oder Nummer)",
            get = function() return draft.item end, set = function(v) draft.item = v or "" end,
            disabled = function() return draft.kind ~= "item" end })
    B:Row({ type = "input", label = "An (Twink)", get = function() return draft.to end, set = function(v) draft.to = v or "" end },
          { type = "slider", label = "Behalten", min = 0, max = 200, step = 5,
            get = function() return draft.keep end, set = function(v) draft.keep = v end,
            format = function(v) return v == 0 and "nichts" or (v .. " Stück") end })
    B:Row({ type = "toggle", label = "Nur volle Stapel", get = function() return draft.full end, set = function(v) draft.full = v end },
          { type = "toggle", label = "Für alle Charaktere", get = function() return draft.account end, set = function(v) draft.account = v end })
    B:Row({ type = "button", label = " ", text = "Regel hinzufügen", onClick = function()
              local r = { kind = draft.kind, to = draft.to, keep = draft.keep, full = draft.full,
                  scope = draft.account and "account" or CharKey() }
              if draft.kind == "item" then r.id = PO.ResolveItem(draft.item) end
              local ok, why = PO.AddRule(r)
              if ok then draft.item = "" Say("Regel angelegt: " .. PO.RuleText(r))
              else Say(why) end
              if WeintCodex.UIOptions and WeintCodex.UIOptions.Rebuild then WeintCodex.UIOptions.Rebuild() end
          end },
          { type = "button", label = " ", text = "Vorschau", onClick = function()
              if K.ShowReport then K.ShowReport("Versandregeln – Vorschau", PO.PlanLines()) end
          end })
    local p = PO.Store()
    if p and #p.rules > 0 then
        B:Advanced()
        B:Section("Deine Regeln")
        for i, r in ipairs(p.rules) do
            B:Row({ type = "button", label = PO.RuleText(r), text = "Löschen", onClick = function()
                PO.RemoveRule(i)
                if WeintCodex.UIOptions and WeintCodex.UIOptions.Rebuild then WeintCodex.UIOptions.Rebuild() end
            end }, { type = "empty" })
        end
    end
end

local mod = K.Module(KEY)
if mod then
    for k, v in pairs(PO.DEFAULTS) do
        if mod.defaults[k] == nil then mod.defaults[k] = v end
    end
    mod.pages[#mod.pages + 1] = { key = "post", label = "Post", build = Build }
    if mod.pageOrder then mod.pageOrder.post = 30.5 end
end
