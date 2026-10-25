--------------------------------------------------
-- WeintCodex :: Auftraege aus der Gilde
--
-- Jemand hat im Discord gesehen, dass einer deiner Charaktere ein Rezept
-- kann, und einen Auftrag erstellt ("stell mir 4x Runenstoffbeutel her").
-- Der Bot haelt ihn, die Companion holt ihn ab und stellt ihn hier zu
-- (Inbox-Typ craft_orders, modules/companion.lua). Vertrag:
-- ../Companion-Forever/docs/craft-orders-bridge.md
--
-- WANN ER ERSCHEINT. Beim Einloggen oder nach /reload - frueher liest
-- das Spiel die Datei der Companion nicht, und daran kommt kein Addon
-- vorbei. Die Companion sagt einen neuen Auftrag deshalb sofort selbst
-- an; der Knopf "Neue Auftraege holen" macht das /reload, wenn man
-- gerade spielt.
--
-- WIE DER STATUS ZURUECKGEHT. Annehmen/Erledigt/Ablehnen reiht eine
-- Nachricht craft_order_status ("id|status") in die Warteschlange an die
-- Companion. Das Spiel schreibt sie beim Ausloggen oder /reload; erst
-- dann geht sie weiter an den Bot und an den Besteller. Bis dahin steht
-- der Auftrag hier mit "wird gemeldet" - nie so, als waere er schon
-- angekommen.
--
-- Ein eigenes Fenster am Bildschirm, nicht im Hauptfenster: es soll
-- nach dem Einloggen erscheinen, auch wenn WeintCodex zu ist.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.CraftOrders = {}

local CO = WeintCodex.CraftOrders
local C  = WeintCodex.C

local WINDOW_W   = 460
local ROW_H      = 64
local MAX_ROWS   = 5
local HEAD_H     = 64
local FOOT_H     = 60

CO.LABELS = {
    open = "offen", accepted = "angenommen", declined = "abgelehnt",
    done = "erledigt", cancelled = "storniert",
}

-- Was wer darf - dieselben Regeln wie im Bot (services/craft_orders.py);
-- hier nur, um keine Knoepfe zu zeigen, die der Bot ablehnen wuerde.
CO.MOVES = {
    crafter   = { open = { "accepted", "done", "declined" }, accepted = { "done", "declined" } },
    requester = { open = { "cancelled" }, accepted = { "cancelled" } },
}

CO.BUTTONS = {
    accepted  = { "Annehmen", "primary" },
    done      = { "Erledigt", "secondary" },
    declined  = { "Ablehnen", "danger" },
    cancelled = { "Stornieren", "danger" },
}

local frame, rows, footer, moreStr = nil, {}, nil, nil

--------------------------------------------------
-- Bestand
--------------------------------------------------

local function Store()
    WeintCodex.SavedData = WeintCodex.SavedData or {}
    local sd = WeintCodex.SavedData
    sd.craftOrders = sd.craftOrders or { list = {}, pending = {}, seen = {} }
    sd.craftOrders.list    = sd.craftOrders.list or {}
    sd.craftOrders.pending = sd.craftOrders.pending or {}
    sd.craftOrders.seen    = sd.craftOrders.seen or {}
    return sd.craftOrders
end

-- Aus der Inbox: immer der volle Stand. Ein Klick, der noch auf dem Weg
-- ist, bleibt stehen, bis der Bot denselben Status meldet.
function CO.Receive(payload)
    if type(payload) ~= "table" then return end

    local store = Store()
    local list = {}

    for _, o in ipairs(type(payload.orders) == "table" and payload.orders or {}) do
        if type(o) == "table" and type(o.id) == "number" and type(o.recipe) == "string" then
            list[#list + 1] = o
        end
    end

    store.list = list
    store.receivedAt = time()

    for id, status in pairs(store.pending) do
        local found
        for _, o in ipairs(list) do
            if o.id == id then found = o end
        end
        if not found or found.status == status then store.pending[id] = nil end
    end
end

function CO.List()
    return Store().list
end

-- Status, wie der Spieler ihn sehen soll: ein noch nicht gemeldeter
-- Klick gilt hier schon, traegt aber "wird gemeldet".
function CO.StatusOf(order)
    local pending = Store().pending[order.id]
    return pending or order.status, pending ~= nil
end

function CO.Moves(order)
    local status, pending = CO.StatusOf(order)
    if pending then return {} end
    local byRole = CO.MOVES[order.role == "crafter" and "crafter" or "requester"]
    return byRole[status] or {}
end

function CO.Unseen()
    local store, out = Store(), {}
    for _, o in ipairs(store.list) do
        if o.role == "crafter" and o.status == "open" and not store.seen[o.id] then
            out[#out + 1] = o
        end
    end
    return out
end

function CO.SetStatus(order, status)
    local store = Store()
    store.pending[order.id] = status
    if WeintCodex.Companion and WeintCodex.Companion.Send then
        WeintCodex.Companion.Send("craft_order_status", order.id .. "|" .. status)
    end
    print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " Auftrag #" .. order.id .. ": "
        .. (CO.LABELS[status] or status) .. " – geht beim Ausloggen oder /reload an die Gilde.")
    CO.Refresh()
end

--------------------------------------------------
-- Zeilen
--------------------------------------------------

function CO.Line(order)
    local head = order.quantity .. "× " .. order.recipe
    local who
    if order.role == "crafter" then
        who = "für " .. (order.character or "?")
            .. ((order.from and order.from ~= "") and (" · von " .. order.from) or "")
    else
        who = "bei " .. (order.character or "?")
    end
    local mats = order.mats and "Material gestellt" or "Material vom Hersteller"
    local status, pending = CO.StatusOf(order)
    local state = (CO.LABELS[status] or status) .. (pending and " · wird gemeldet" or "")
    return head, who .. " · " .. mats, state
end

local function NewText(parent, size, fontKey, color)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont(WeintCodex.Fonts[fontKey or "sans"], size, "")
    local c = C[color or "textNormal"]
    fs:SetTextColor(c[1], c[2], c[3])
    fs:SetJustifyH("LEFT")
    fs:SetWordWrap(false)
    return fs
end

local function BuildRow(index)
    local row = CreateFrame("Frame", nil, frame)
    row:SetSize(WINDOW_W - 32, ROW_H - 6)
    row:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -HEAD_H - (index - 1) * ROW_H)
    WeintCodex.SetSolidBg(row, C.surface3[1], C.surface3[2], C.surface3[3], 1.0)

    row.title = NewText(row, 13, "sansSemi", "textBright")
    row.title:SetPoint("TOPLEFT", row, "TOPLEFT", 10, -8)
    row.title:SetPoint("RIGHT", row, "RIGHT", -10, 0)

    row.sub = NewText(row, 11, "sans", "textDim")
    row.sub:SetPoint("TOPLEFT", row.title, "BOTTOMLEFT", 0, -4)
    row.sub:SetPoint("RIGHT", row, "RIGHT", -10, 0)

    row.state = NewText(row, 10, "mono", "textMuted")
    row.state:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 10, 7)

    row.buttons = {}
    return row
end

local function FillRow(row, order)
    local head, sub, state = CO.Line(order)
    if order.note and order.note ~= "" then sub = sub .. " · „" .. order.note .. "“" end
    row.title:SetText(WeintCodex.Truncate(head, 52))
    row.sub:SetText(WeintCodex.Truncate(sub, 70))
    row.state:SetText(state)

    for _, b in ipairs(row.buttons) do b:Hide() b:SetParent(nil) end
    wipe(row.buttons)

    local right = -8
    local moves = CO.Moves(order)
    for i = #moves, 1, -1 do
        local status = moves[i]
        local look = CO.BUTTONS[status]
        local b = WeintCodex.CreateButton(row, {
            text = look[1], width = 86, height = 22, kind = look[2],
            onClick = function() CO.SetStatus(order, status) end,
        })
        b:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", right, 6)
        right = right - 92
        row.buttons[#row.buttons + 1] = b
    end
    row:Show()
end

--------------------------------------------------
-- Fenster
--------------------------------------------------

local function EnsureFrame()
    if frame then return end

    frame = CreateFrame("Frame", "WeintCodexCraftOrders", UIParent)
    frame:SetSize(WINDOW_W, HEAD_H + FOOT_H + ROW_H)
    frame:SetPoint("TOP", UIParent, "TOP", 0, -140)
    frame:SetFrameStrata("DIALOG")
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetClampedToScreen(true)
    WeintCodex.SetSolidBg(frame, C.surface2[1], C.surface2[2], C.surface2[3], 0.97)
    WeintCodex.DrawBorder(frame, C.borderStrong[1], C.borderStrong[2], C.borderStrong[3], 1.0, 1)
    tinsert(UISpecialFrames, "WeintCodexCraftOrders")
    frame:Hide()

    local edge = frame:CreateTexture(nil, "ARTWORK")
    edge:SetHeight(1)
    edge:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, 0)
    edge:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, 0)
    edge:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.5)

    local title = NewText(frame, 16, "sansBold", "textBright")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -16)
    title:SetText("Aufträge aus der Gilde")

    local hint = NewText(frame, 10, "sans", "textMuted")
    hint:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    hint:SetText("Status geht beim Ausloggen oder /reload an die Gilde.")

    local close = CreateFrame("Button", nil, frame)
    close:SetSize(22, 22)
    close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -10)
    local x = close:CreateFontString(nil, "OVERLAY")
    x:SetAllPoints(close)
    x:SetFont(WeintCodex.Fonts.sansSemi, 15, "")
    x:SetText(WeintCodex.ColorText("textMuted", "\195\151"))
    close:SetScript("OnClick", function() frame:Hide() end)

    moreStr = NewText(frame, 10, "sans", "textDim")

    footer = WeintCodex.CreateButton(frame, {
        text = "Neue Aufträge holen", width = 170, height = 28, kind = "secondary",
    })
    footer:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 16, 16)
    -- /reload ist fuer Addons gesperrt - nur ueber den sicheren Makroknopf.
    WeintCodex.AttachReload(footer)

    local done = WeintCodex.CreateButton(frame, {
        text = "Schließen", width = 110, height = 28, kind = "ghost",
        onClick = function() frame:Hide() end,
    })
    done:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -16, 16)
end

function CO.Refresh()
    if not frame or not frame:IsShown() then return end

    local list = CO.List()
    local shown = math.min(#list, MAX_ROWS)

    for i = 1, shown do
        rows[i] = rows[i] or BuildRow(i)
        FillRow(rows[i], list[i])
    end
    for i = shown + 1, #rows do rows[i]:Hide() end

    local body = math.max(shown, 1) * ROW_H
    frame:SetHeight(HEAD_H + body + FOOT_H)

    moreStr:ClearAllPoints()
    moreStr:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -HEAD_H - body + 2)
    if #list == 0 then
        moreStr:SetText("Keine offenen Aufträge. Neue entstehen im Discord: #berufe → Rezept suchen.")
    elseif #list > MAX_ROWS then
        moreStr:SetText("+ " .. (#list - MAX_ROWS) .. " weitere – alle stehen in der Companion unter Berufe.")
    else
        moreStr:SetText("")
    end
end

function CO.Show()
    EnsureFrame()
    frame:Show()
    local store = Store()
    for _, o in ipairs(store.list) do store.seen[o.id] = true end
    CO.Refresh()
end

function CO.Hide()
    if frame then frame:Hide() end
end

-- Nach dem Einloggen: nur wenn ein noch nicht gezeigter Auftrag wartet.
-- Kurz verzoegert, damit das Fenster nicht unter dem Ladebildschirm
-- aufgeht; im Kampf erst danach.
function CO.ShowIfNew()
    if #CO.Unseen() == 0 then return end

    local function open()
        if InCombatLockdown and InCombatLockdown() then
            local waiter = CreateFrame("Frame")
            waiter:RegisterEvent("PLAYER_REGEN_ENABLED")
            waiter:SetScript("OnEvent", function(self)
                self:UnregisterAllEvents()
                CO.Show()
            end)
            return
        end
        CO.Show()
    end

    if C_Timer and C_Timer.After then C_Timer.After(4, open) else open() end
end
