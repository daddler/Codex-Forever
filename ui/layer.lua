--------------------------------------------------
-- WeintCodex :: Layer - auf welchem bin ich, und wechseln (6.62.0.0)
--------------------------------------------------
-- Wunsch des Spielers (mit dem Addon LayerSwap als Vorbild): "sowas haette
-- ich auch noch gerne drin" - gewaehlt: ANZEIGE + WECHSEL, kein Hosten.
-- Nach dem VERHALTEN von LayerSwap, ohne seinen Code (keine Lizenz
-- angegeben - dieselbe Regel wie bei MoveAny, WIM, DialogueUI). Uebernommen
-- sind nur Tatsachen ueber das Spiel und das Format im Kanal, damit Hosts
-- mit LayerSwap unsere Bitte verstehen.
--
-- WELCHER LAYER: das Spiel nennt keinen. Die Kennung eines Gegners
-- (Creature-0-[Server]-[Karte]-[Zone]-[NPC]-[Spawn]) traegt Server und
-- Zone des Layers; geglaubt wird ein Layer erst, wenn zwei verschiedene
-- Gegner ihn zeigen (Wechsel: 3 der letzten 5). Begleiter zaehlen nicht.
-- Nach Zonenwechsel/Layerwechsel (SHARD_TRANSFER) ist er wieder unbekannt.
-- Jeder Layer bekommt je Sitzung einen Buchstaben (A, B, ...).
--
-- WECHSELN: man wechselt den Layer, indem man der Gruppe eines Spielers
-- auf einem anderen Layer beitritt ("Host"); verlaesst man sie, geht es
-- zurueck. Ein KLICK auf die Kachel schreibt in den Kanal "layer":
--   "inv layer <LS [Zone] not [Layer]>"
-- davor, unsichtbar fuer Spieler, die Notizen "zone [Zone]" und
-- "not [Layer]" als Addon-Nachricht (Praefix "LayerSwap"). Das ist die
-- DRITTE Nachricht nach aussen (CLAUDE.md) - nur auf Klick, nie von selbst,
-- ohne Position oder Namen ausser dem, was die Zeile im Kanal ohnehin zeigt.
-- Einladung annehmen: der Spieler selbst.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UILayer = {}

local LY = WeintCodex.UILayer
local K  = WeintCodex.UIKit
local C  = WeintCodex.Colors
local KEY = "comfort"

LY.DEFAULTS = { layerShow = true }
LY.CHANNEL = "layer"
LY.PREFIX = "LayerSwap"
LY.VOTES = 5
LY.COOLDOWN = 30        -- s zwischen zwei Bitten
LY.ASK_TTL = 120        -- so lange wartet eine Bitte auf eine Einladung
LY.SAME_AFTER = 8       -- in der Gruppe, kein Wechsel nach so vielen s: Host auf unserem Layer

local frame
local votes, voted = {}, {}
local letters, count = {}, 0
LY.current = nil
LY.ask = nil            -- { at, from, joinedAt, moved }

function LY.Active()
    return K.IsActive(KEY) and K.Get(KEY, "layerShow") ~= false
end

local function Now() return _G.GetTime and K.Plain(_G.GetTime()) or 0 end

local function Say(text)
    print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " " .. text)
end

function LY.Letter(id)
    if not id then return nil end
    if not letters[id] then
        count = count + 1
        letters[id] = count <= 26 and string.char(64 + count) or tostring(count)
    end
    return letters[id]
end

-- Zone als Kartennummer (die Zone, nicht die Hoehle darin).
function LY.Zone()
    local cm = _G.C_Map
    if not (cm and cm.GetBestMapForUnit and cm.GetMapInfo) then return nil end
    local ok, id = pcall(cm.GetBestMapForUnit, "player")
    id = ok and K.Plain(id) or nil
    if type(id) ~= "number" or id <= 0 then return nil end
    local zoneType = (_G.Enum and _G.Enum.UIMapType and _G.Enum.UIMapType.Zone) or 3
    local m = id
    for _ = 1, 6 do
        local okI, info = pcall(cm.GetMapInfo, m)
        if not okI or type(info) ~= "table" then break end
        local t, up = K.Plain(info.mapType), K.Plain(info.parentMapID)
        if t == zoneType then return m end
        if type(t) ~= "number" or t < zoneType or type(up) ~= "number" or up <= 0 then break end
        m = up
    end
    return id
end

-- Eine Einheit ansehen: ihre Kennung ist eine Stimme fuer einen Layer.
function LY.Observe(unit)
    local guid = _G.UnitGUID and K.Plain(_G.UnitGUID(unit))
    if type(guid) ~= "string" or voted[guid] then return end
    local kind, _, server, _, zone = _G.strsplit("-", guid)
    if (kind ~= "Creature" and kind ~= "Vehicle") or not server or not zone then return end
    voted[guid] = true
    local id = server .. "-" .. zone
    votes[#votes + 1] = id
    if #votes > LY.VOTES then table.remove(votes, 1) end
    if id == LY.current then return end
    local n = 0
    for _, v in ipairs(votes) do if v == id then n = n + 1 end end
    if n >= (LY.current and 3 or 2) then LY.Set(id) end
end

function LY.Forget()
    wipe(votes) wipe(voted)
    LY.current = nil
    LY.Paint()
end

function LY.Set(id)
    local from = LY.current
    LY.current = id
    LY.Letter(id)
    local a = LY.ask
    if a and a.joinedAt and a.from and a.from ~= id then
        a.moved = true
        Say("Du bist jetzt auf Layer " .. LY.Letter(id) .. " – solange du in der Gruppe bleibst. Verlassen bringt dich zurück.")
        LY.ask = nil
    end
    LY.Paint()
    return from
end

--------------------------------------------------
-- Bitte um einen Wechsel (nur auf Klick)
--------------------------------------------------

local function InGroup()
    return (_G.IsInGroup and K.Bool(_G.IsInGroup(), false)) or false
end

function LY.AskText()
    local parts = { "<LS" }
    local z = LY.Zone()
    if z then parts[#parts + 1] = tostring(z) end
    if LY.current then parts[#parts + 1] = "not " .. LY.current end
    return "inv layer " .. table.concat(parts, " ") .. ">"
end

local blocked = false
function LY.Ask()
    local now = Now()
    if InGroup() then Say("Du bist in einer Gruppe – verlasse sie, um den Layer zu wechseln.") return "group" end
    if K.InCombat() then return "combat" end
    if LY.ask and now - LY.ask.at < LY.COOLDOWN then
        Say("Deine Bitte läuft noch – warte einen Moment.") return "cooldown"
    end
    if not LY.current then
        Say("Erst den Layer lesen: nimm einen Gegner ins Ziel oder fahr mit der Maus darüber, dann noch einmal.")
        return "unknown"
    end
    local ch = _G.GetChannelName and K.Plain(_G.GetChannelName(LY.CHANNEL)) or 0
    if type(ch) ~= "number" or ch == 0 then
        if _G.JoinChannelByName then pcall(_G.JoinChannelByName, LY.CHANNEL) end
        Say("Kanal „" .. LY.CHANNEL .. "“ betreten – klick noch einmal, um zu bitten.")
        return "joined"
    end
    local ci = _G.C_ChatInfo
    if ci and ci.SendAddonMessage then
        local z = LY.Zone()
        if z then pcall(ci.SendAddonMessage, LY.PREFIX, "zone " .. z, "CHANNEL", ch) end
        pcall(ci.SendAddonMessage, LY.PREFIX, "not " .. LY.current, "CHANNEL", ch)
    end
    local send = (ci and ci.SendChatMessage) or _G.SendChatMessage
    blocked = false
    LY.sending = true
    local ok = send and pcall(send, LY.AskText(), "CHANNEL", nil, ch)
    LY.sending = false
    if not ok or blocked then
        Say("Das Spiel hat die Bitte zurückgehalten – klick noch einmal.")
        return "held"
    end
    LY.ask = { at = now, from = LY.current }
    Say("Bitte um einen anderen Layer gesendet. Nimm die Einladung an, die kommt.")
    LY.Paint()
    return "sent"
end

--------------------------------------------------
-- Anzeige
--------------------------------------------------

function LY.Text()
    local a = LY.ask
    if a and a.joinedAt and not a.moved then return "Layer " .. (LY.Letter(LY.current) or "?") .. " · Gruppe …" end
    if a and not a.joinedAt and Now() - a.at < LY.ASK_TTL then return "Layer " .. (LY.Letter(LY.current) or "?") .. " · bittet …" end
    if not LY.current then return "Layer ?" end
    return "Layer " .. LY.Letter(LY.current)
end

-- 6.62.0.0 (Wunsch: "die Layer-Anzeige an der Minimap; mit Klick auf den
-- Layer oeffnet sich die Option"): ein kleines Schild oben mittig auf der
-- Minikarte (links stehen die Koordinaten, rechts die Uhr). Klick oeffnet
-- die Komfortseite "Karte"; dort der Knopf zum Wechseln.
function LY.OpenOptions()
    local O = WeintCodex.UIOptions
    local mod = K.Module(KEY)
    if not (O and O.Show and mod) then return false end
    local idx
    for i, page in ipairs(mod.pages) do if page.key == "karte" then idx = i end end
    O.Show(KEY, idx)
    return true
end

local function Build()
    if frame then return frame end
    local mm = _G.Minimap
    if type(mm) ~= "table" then return nil end
    frame = CreateFrame("Button", "WeintCodexLayer", mm)
    frame:SetSize(64, 16)
    frame:SetPoint("TOP", mm, "TOP", 0, -3)
    frame:SetFrameLevel((K.Plain(mm:GetFrameLevel()) or 1) + 10)
    frame.kachel = K.Kachel(frame, { shadow = 0 })
    frame.text = K.NewText(frame, 10, "OVERLAY")
    frame.text:SetPoint("CENTER", frame, "CENTER", 0, 0)
    if frame.RegisterForClicks then frame:RegisterForClicks("LeftButtonUp") end
    frame:SetScript("OnClick", function() LY.OpenOptions() end)
    frame:SetScript("OnEnter", function(self)
        local gt = _G.GameTooltip
        gt:SetOwner(self, "ANCHOR_BOTTOM")
        gt:SetText(LY.Text(), 1, 1, 1)
        local m = C.textMuted
        if LY.current then gt:AddLine("Kennung " .. LY.current, m[1], m[2], m[3]) end
        gt:AddLine(LY.current and "Gelesen an den Gegnern um dich herum." or
            "Noch unbekannt – nimm einen Gegner ins Ziel oder fahr mit der Maus darüber.", m[1], m[2], m[3], true)
        gt:AddLine("Klick: Einstellungen – dort um einen anderen Layer bitten.", m[1], m[2], m[3], true)
        gt:Show()
    end)
    frame:SetScript("OnLeave", function() if _G.GameTooltip then _G.GameTooltip:Hide() end end)
    frame:Hide()
    LY.frame = frame
    return frame
end

function LY.Paint()
    if not frame then return end
    frame.text:SetText(LY.Text())
    local c = LY.current and C.textBright or C.textMuted
    frame.text:SetTextColor(c[1], c[2], c[3])
    frame:SetShown(LY.Active())
end

--------------------------------------------------
-- Ereignisse
--------------------------------------------------

local ev = CreateFrame("Frame")
LY.events = ev
for _, e in ipairs({ "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA", "SHARD_TRANSFER",
                     "NAME_PLATE_UNIT_ADDED", "PLAYER_TARGET_CHANGED", "UPDATE_MOUSEOVER_UNIT",
                     "GROUP_JOINED", "GROUP_LEFT", "ADDON_ACTION_BLOCKED", "ADDON_ACTION_FORBIDDEN" }) do
    pcall(ev.RegisterEvent, ev, e)
end
ev:SetScript("OnEvent", function(_, event, a1)
    if event == "PLAYER_LOGIN" then
        if _G.C_ChatInfo and _G.C_ChatInfo.RegisterAddonMessagePrefix then
            pcall(_G.C_ChatInfo.RegisterAddonMessagePrefix, LY.PREFIX)
        end
        if LY.Active() then Build() LY.Paint() end
    elseif event == "NAME_PLATE_UNIT_ADDED" then
        if type(K.Plain(a1)) == "string" then LY.Observe(a1) end
    elseif event == "PLAYER_TARGET_CHANGED" then LY.Observe("target")
    elseif event == "UPDATE_MOUSEOVER_UNIT" then LY.Observe("mouseover")
    elseif event == "SHARD_TRANSFER" or event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_ENTERING_WORLD" then
        LY.Forget()
    elseif event == "GROUP_JOINED" then
        local a = LY.ask
        if a and not a.joinedAt and Now() - a.at < LY.ASK_TTL then
            a.joinedAt = Now()
            if _G.C_Timer and _G.C_Timer.After then
                _G.C_Timer.After(LY.SAME_AFTER, function()
                    if LY.ask == a and not a.moved then
                        Say("Der Spieler, der dich eingeladen hat, steht auf deinem Layer – nichts gewechselt. Gruppe verlassen und noch einmal bitten.")
                        LY.ask = nil
                        LY.Paint()
                    end
                end)
            end
        end
        LY.Paint()
    elseif event == "GROUP_LEFT" then
        LY.ask = nil
        LY.Paint()
    elseif LY.sending then
        blocked = true
    end
end)

--------------------------------------------------
-- Einstellungen: Komfortseite "Karte"
--------------------------------------------------

local function BuildSection(B)
    B:Section("Layer", "Auf welchem Layer du bist – und auf Klick um einen anderen bitten.")
    B:Row({ type = "button", label = "Wechseln", text = "Um anderen Layer bitten",
            onClick = function() LY.Ask() end,
            description = "Schreibt „inv layer“ in den Kanal „layer“ – nur auf diesen Klick. Ein Spieler auf einem anderen Layer lädt dich ein; solange du in seiner Gruppe bist, bist du dort." },
          { type = "empty" })
    B:Advanced()
    B:Row({ type = "toggle", label = "Layer an der Minikarte", key = "layerShow",
            description = "Oben mittig auf der Minikarte. Klick darauf öffnet diese Seite." },
          { type = "empty" })
end
LY.BuildSection = BuildSection

local mod = K.Module(KEY)
if mod then
    for k, v in pairs(LY.DEFAULTS) do
        if mod.defaults[k] == nil then mod.defaults[k] = v end
    end
    for _, page in ipairs(mod.pages) do
        if page.key == "karte" then
            local orig = page.build
            page.build = function(B, ...)
                if orig then orig(B, ...) end
                BuildSection(B)
            end
        end
    end
end

K.Listen(function(kind, key)
    if (kind == "active" or kind == "setting") and key == KEY then
        if LY.Active() then Build() end
        LY.Paint()
    end
end)
