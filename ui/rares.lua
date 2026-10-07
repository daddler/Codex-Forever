--------------------------------------------------
-- WeintCodex :: Seltene Gegner - Hinweis, wenn einer auftaucht
--------------------------------------------------
-- Seit 6.16.0.0 (Abgleich mit dem Addon ForeverGuide): erscheint ein
-- seltener Gegner als Plakette, im Ziel, unter der Maus oder als Symbol
-- auf der Minikarte (Vignette), meldet WeintCodex ihn - mit Ton, Zeile im
-- Chat und einem Hinweis oben. Eine Seite im Komfort (wie Automark),
-- gespeichert unter "comfort", wie jeder Komfort-Helfer von Haus aus AUS;
-- geht ohne Oberflaeche.
--
-- ZWEI WEGE ZU WISSEN, DASS ER SELTEN IST - beide gemessen, nichts geraten:
--   * der CLIENT sagt es (UnitClassification "rare"/"rareelite") - auch
--     fuer Gegner, die nicht im Bestand stehen;
--   * der BESTAND kennt ihn (data/rares.lua, `community`; Wiederkehr aus
--     Classic, `classic`) und sagt dazu Stufe, Elite, zaehmbar, Wiederkehr.
-- Was der Client geheim haelt (GUID, Name), zaehlt als "weiss nicht" -
-- dann keine Meldung, nie eine geratene.
-- Gemerkt wird je Realm, wann und wo (deine Lage) er zuletzt gesehen
-- wurde - nie, wann er wiederkommt: das waere eine Zahl aus Classic.
--------------------------------------------------

local K = WeintCodex.UIKit
local C = WeintCodex.Colors
local KEY = "comfort"

WeintCodex.UIRares = {}
local RA = WeintCodex.UIRares
local RD = WeintCodex.RareData

RA.DEFAULTS = {
    rareAlert     = false,   -- der Helfer selbst
    rareSound     = true,    -- Ton beim Auftauchen
    rareChat      = true,    -- Zeile im Chat
    rareToast     = true,    -- Hinweis oben
    rareInstances = false,   -- auch in Dungeons und Schlachtzuegen
    rareDead      = false,   -- auch, wenn er schon tot ist
}

RA.REALERT = 300     -- derselbe Gegner meldet sich hoechstens alle 5 Minuten
RA.TOAST_TIME = 12   -- so lange steht der Hinweis (s)

local SETTING = { sound = "rareSound", chat = "rareChat", toast = "rareToast",
                  instances = "rareInstances", dead = "rareDead" }
local function Get(k) return K.Get(KEY, SETTING[k] or k) end
function RA.Active() return K.IsActive(KEY) and K.Get(KEY, "rareAlert") and true or false end
local function Now() return (_G.GetTime and K.Plain(_G.GetTime())) or 0 end

--------------------------------------------------
-- Bestand
--------------------------------------------------

local FLAGS = { e = "elite", p = "placeholder", t = "tame", n = "night", s = "summoned",
                a = "approx", r = "rsForever", d = "dungeon", f = "forever" }
local cache = {}

-- { id, name, lv1, lv2, elite, ..., rs1, rs2, pos = { { map, x, y }, ... } } oder nil.
function RA.Info(id)
    if type(id) ~= "number" then return nil end
    local c = cache[id]
    if c ~= nil then return c or nil end
    local raw = RD and RD.RAW and RD.RAW[id]
    if type(raw) ~= "string" then cache[id] = false return nil end
    local name, lv1, lv2, flags, rs1, rs2, pos = raw:match("^([^|]*)|([^|]*)|([^|]*)|([^|]*)|([^|]*)|([^|]*)|(.*)$")
    local info = { id = id, name = name, lv1 = tonumber(lv1), lv2 = tonumber(lv2),
                   rs1 = tonumber(rs1), rs2 = tonumber(rs2), pos = {} }
    for ch in (flags or ""):gmatch(".") do
        if FLAGS[ch] then info[FLAGS[ch]] = true end
    end
    for m, x, y in (pos or ""):gmatch("(%d+),([%d%.]+),([%d%.]+)") do
        info.pos[#info.pos + 1] = { tonumber(m), tonumber(x), tonumber(y) }
    end
    cache[id] = info
    return info
end

-- Die seltenen Gegner einer Karte (nach Stufe).
function RA.OnMap(map)
    local out = {}
    for id in pairs(RD and RD.RAW or {}) do
        local info = RA.Info(id)
        for _, p in ipairs(info.pos) do
            if p[1] == map then out[#out + 1] = info break end
        end
    end
    table.sort(out, function(a, b)
        if (a.lv1 or 0) ~= (b.lv1 or 0) then return (a.lv1 or 0) < (b.lv1 or 0) end
        return a.name < b.name
    end)
    return out
end

-- NPC-Nummer aus einer GUID ("Creature-0-1465-0-2105-61-0000..."), oder nil.
function RA.NpcId(guid)
    guid = K.Plain(guid)
    if type(guid) ~= "string" then return nil end
    local kind, id = guid:match("^(%a+)%-%d+%-%d+%-%d+%-%d+%-(%d+)")
    if kind ~= "Creature" and kind ~= "Vehicle" then return nil end
    return tonumber(id)
end

local function Duration(s)
    if not s then return nil end
    local h, m = math.floor(s / 3600), math.floor(s % 3600 / 60)
    if h > 0 then return string.format("%d:%02d h", h, m) end
    return m .. " min"
end

-- "Stufe 12 · Elite · zaehmbar" (nur, was bekannt ist).
function RA.Describe(info, level, elite)
    local parts = {}
    local lv
    if info and info.lv1 then
        lv = (info.lv2 and info.lv2 ~= info.lv1) and (info.lv1 .. "–" .. info.lv2) or tostring(info.lv1)
        if info.approx then lv = "≈ " .. lv end
    elseif type(level) == "number" and level > 0 then
        lv = tostring(level)
    end
    if lv then parts[#parts + 1] = "Stufe " .. lv end
    if (info and info.elite) or elite then parts[#parts + 1] = "Elite" end
    if info and info.tame then parts[#parts + 1] = "zähmbar" end
    if info and info.night then parts[#parts + 1] = "nur nachts" end
    return table.concat(parts, " · ")
end

-- "Wiederkehr in Classic 1:30–2:30 h" oder nil.
function RA.RespawnText(info)
    if not (info and info.rs1) then return nil end
    local a, b = Duration(info.rs1), Duration(info.rs2)
    local span = a
    if b and b ~= a then
        -- Gleiche Einheit nur einmal: "1:30–2:30 h", nicht "1:30 h–2:30 h".
        local ua, ub = a:match("(%S+)$"), b:match("(%S+)$")
        span = (ua == ub and a:gsub("%s+%S+$", "") or a) .. "–" .. b
    end
    return (info.rsForever and "Wiederkehr " or "Wiederkehr in Classic ") .. span
end

--------------------------------------------------
-- Gedaechtnis: zuletzt gesehen (je Realm)
--------------------------------------------------

function RA.Memory()
    local sd = WeintCodex.SavedData
    if type(sd) ~= "table" then return nil end
    local realm = _G.GetRealmName and K.Plain(_G.GetRealmName())
    realm = type(realm) == "string" and realm or "?"
    sd.rares = sd.rares or {}
    sd.rares[realm] = sd.rares[realm] or {}
    return sd.rares[realm]
end

--------------------------------------------------
-- Hinweis
--------------------------------------------------

local toast
local function EnsureToast()
    if toast then return toast end
    toast = CreateFrame("Frame", "WeintCodexRareAlert", UIParent)
    toast:SetSize(300, 52)
    toast:SetFrameStrata("HIGH")
    K.Kachel(toast)
    toast.mark = toast:CreateTexture(nil, "ARTWORK")
    toast.mark:SetSize(3, 52)
    toast.mark:SetPoint("LEFT", toast, "LEFT", 0, 0)
    local w = C.warningBright
    toast.mark:SetColorTexture(w[1], w[2], w[3], 1)
    toast.title = K.NewText(toast, 13)
    toast.title:SetPoint("TOPLEFT", toast, "TOPLEFT", 14, -9)
    toast.title:SetPoint("RIGHT", toast, "RIGHT", -10, 0)
    toast.title:SetWordWrap(false)
    toast.sub = K.NewText(toast, 11)
    toast.sub:SetPoint("TOPLEFT", toast.title, "BOTTOMLEFT", 0, -4)
    toast.sub:SetPoint("RIGHT", toast, "RIGHT", -10, 0)
    toast.sub:SetWordWrap(false)
    toast:Hide()
    toast:SetScript("OnUpdate", K.Measured("Seltene Gegner", function(self, el)
        if self._unlock then return end
        self._t = (self._t or 0) + (el or 0)
        if self._t > RA.TOAST_TIME then
            local a = 1 - (self._t - RA.TOAST_TIME) / 0.6
            if a <= 0 then self:Hide() else self:SetAlpha(a) end
        end
    end))
    toast:EnableMouse(true)
    toast:SetScript("OnMouseUp", function(self) self:Hide() end)
    toast.WCShowForUnlock = function(self, on)
        self._unlock = on and true or nil
        if on then
            RA.FillToast("Seltener Gegner", "Stufe 12 · Elite")
            self:SetAlpha(1)
            self:Show()
        else
            self:Hide()
        end
    end
    K.RegisterMover(toast, "rarealert", "Seltene Gegner", K.Layout("rarealert"))
    RA.toast = toast
    return toast
end

function RA.FillToast(title, sub)
    local t = EnsureToast()
    t.title:SetText(title)
    local tb = C.textBright
    t.title:SetTextColor(tb[1], tb[2], tb[3])
    t.sub:SetText(sub or "")
    local tm = C.textMuted
    t.sub:SetTextColor(tm[1], tm[2], tm[3])
end

local function Zone()
    local K2 = K
    local map = K2.BestMap and K2.BestMap()
    local QM = WeintCodex.QuestMap
    return map, (map and QM and QM.MapName and QM.MapName(map)) or nil
end

-- Meldet einen Gegner: Ton, Chat, Hinweis - je nach Einstellung.
function RA.Alert(name, info, level, elite, how)
    local desc = RA.Describe(info, level, elite)
    local rs = RA.RespawnText(info)
    local _, zone = Zone()
    RA.last = { name = name, desc = desc, how = how, at = Now(), known = info ~= nil }
    if Get("chat") then
        local line = WeintCodex.ColorText("warningBright", "Seltener Gegner: ") .. name
            .. (desc ~= "" and (" (" .. desc .. ")") or "")
            .. (zone and (" – " .. zone) or "")
            .. (info and "" or " – nicht im Bestand, der Client nennt ihn selten")
        print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " " .. line)
        RA.last.chat = line
    end
    if Get("sound") and _G.PlaySound and _G.SOUNDKIT and _G.SOUNDKIT.RAID_WARNING then
        pcall(_G.PlaySound, _G.SOUNDKIT.RAID_WARNING, "Master")
        RA.last.sound = true
    end
    if Get("toast") then
        local t = EnsureToast()
        if not t._unlock then
            local sub = desc
            if rs then sub = (sub ~= "" and (sub .. "  ·  ") or "") .. rs end
            RA.FillToast("Seltener Gegner: " .. name, sub)
            t._t = 0
            t:SetAlpha(1)
            t:Show()
        end
    end
end

--------------------------------------------------
-- Erkennen
--------------------------------------------------

local lastAlert = {}
RA.lastAlert = lastAlert

local function InInstance()
    if not _G.IsInInstance then return false end
    local inside, kind = _G.IsInInstance()
    kind = K.Plain(kind)
    if type(kind) == "string" then return kind ~= "none" end
    return K.Bool(inside, false)
end

-- Gesehen: merken, und melden, wenn es Zeit ist. `key` ist die NPC-Nummer
-- oder (ohne Bestand) der Name.
function RA.Seen(key, name, info, level, elite, dead, how)
    local mem = RA.Memory()
    if mem then
        local map, x, y = K.BestMap and K.BestMap()
        if map and K.PlayerMapXY then x, y = K.PlayerMapXY(map) end
        local e = mem[key] or {}
        e.name, e.at, e.dead = name, (_G.time and _G.time()) or 0, dead or nil
        e.map, e.x, e.y = map, x and math.floor(x * 1000 + 0.5) / 10 or nil, y and math.floor(y * 1000 + 0.5) / 10 or nil
        mem[key] = e
    end
    if dead and not Get("dead") then return false end
    local now = Now()
    if lastAlert[key] and now - lastAlert[key] < RA.REALERT then return false end
    lastAlert[key] = now
    RA.Alert(name, info, level, elite, how)
    return true
end

-- Eine Einheit pruefen (Plakette, Ziel, Maus).
function RA.CheckUnit(unit, how)
    if not RA.Active() then return false end
    if not (_G.UnitExists and K.Bool(_G.UnitExists(unit), false)) then return false end
    if _G.UnitIsPlayer and K.Bool(_G.UnitIsPlayer(unit), true) then return false end
    if not Get("instances") and InInstance() then return false end
    local id = RA.NpcId(_G.UnitGUID and _G.UnitGUID(unit))
    local info = id and RA.Info(id)
    local cls = K.Plain(_G.UnitClassification and _G.UnitClassification(unit))
    local rare = cls == "rare" or cls == "rareelite"
    if not info and not rare then return false end
    local name = K.Plain(_G.UnitName and _G.UnitName(unit))
    if type(name) ~= "string" then name = info and info.name or nil end
    if not name then return false end
    local level = K.Plain(_G.UnitLevel and _G.UnitLevel(unit))
    local dead = _G.UnitIsDead and K.Bool(_G.UnitIsDead(unit), false) or false
    return RA.Seen(id or name, name, info, level, cls == "rareelite", dead, how)
end

-- Symbole auf der Minikarte (Vignetten): nur Gegner aus dem Bestand oder
-- solche, die das Spiel als Kill-Vignette fuehrt.
function RA.ScanVignettes()
    if not RA.Active() then return 0 end
    local vi = _G.C_VignetteInfo
    if not (vi and vi.GetVignettes and vi.GetVignetteInfo) then return 0 end
    if not Get("instances") and InInstance() then return 0 end
    local ok, list = pcall(vi.GetVignettes)
    if not ok or type(list) ~= "table" then return 0 end
    local n = 0
    for _, vg in ipairs(list) do
        local ok2, info = pcall(vi.GetVignetteInfo, vg)
        if ok2 and type(info) == "table" then
            local id = RA.NpcId(info.objectGUID)
            local data = id and RA.Info(id)
            local atlas = K.Plain(info.atlasName)
            local kill = type(atlas) == "string" and atlas:find("VignetteKill", 1, true) ~= nil
            local name = K.Plain(info.name)
            if type(name) ~= "string" then name = data and data.name or nil end
            if name and (data or kill) then
                n = n + 1
                RA.Seen(id or name, name, data, nil, atlas == "VignetteKillElite", false, "vignette")
            end
        end
    end
    RA.lastVignettes = n
    return n
end

--------------------------------------------------
-- Bericht: /wcui selten
--------------------------------------------------

function RA.Report()
    local map, zone = Zone()
    local out = {}
    if not map then
        out[1] = "Deine Karte nennt der Client gerade nicht (Instanz?)."
        return out
    end
    local list = RA.OnMap(map)
    out[#out + 1] = (zone or ("Karte " .. map)) .. ": " .. #list .. " seltene Gegner im Bestand"
    local mem = RA.Memory() or {}
    for _, info in ipairs(list) do
        local line = "  " .. info.name
        local desc = RA.Describe(info)
        if desc ~= "" then line = line .. " (" .. desc .. ")" end
        local rs = RA.RespawnText(info)
        if rs then line = line .. " · " .. rs end
        local seen = mem[info.id]
        if seen and seen.at and _G.date then
            line = line .. " · zuletzt gesehen " .. _G.date("%d.%m. %H:%M", seen.at) .. (seen.dead and " (tot)" or "")
        end
        out[#out + 1] = line
    end
    out[#out + 1] = "Herkunft: " .. (RD and RD.SOURCE and RD.SOURCE.label or "?") .. "; Wiederkehr aus Classic."
    return out
end

--------------------------------------------------
-- Modul
--------------------------------------------------

local ev = CreateFrame("Frame")
RA.events = ev
local function OnEvent(_, event, unit)
    if event == "NAME_PLATE_UNIT_ADDED" then RA.CheckUnit(unit, "nameplate")
    elseif event == "PLAYER_TARGET_CHANGED" then RA.CheckUnit("target", "target")
    elseif event == "UPDATE_MOUSEOVER_UNIT" then RA.CheckUnit("mouseover", "mouseover")
    else RA.ScanVignettes() end
end

local function Apply()
    local on = RA.Active()
    for _, e in ipairs({ "NAME_PLATE_UNIT_ADDED", "PLAYER_TARGET_CHANGED", "UPDATE_MOUSEOVER_UNIT",
                         "VIGNETTES_UPDATED", "VIGNETTE_MINIMAP_UPDATED" }) do
        if on then pcall(ev.RegisterEvent, ev, e) else pcall(ev.UnregisterEvent, ev, e) end
    end
    if on then EnsureToast() end
    if toast and K.SetMoverEnabled then K.SetMoverEnabled("rarealert", on and Get("toast")) end
    if not on and toast then toast:Hide() end
end
RA.Apply = Apply
ev:SetScript("OnEvent", K.Measured("Seltene Gegner", OnEvent))

local function Build(B)
    local off = function() return not K.Get(KEY, "rareAlert") end
    B:Section("Seltene Gegner", "Selten ist ein Gegner, wenn das Spiel es sagt oder wenn er im Bestand steht (404 aus dem Wissensstand der Beta). Derselbe meldet sich höchstens alle fünf Minuten.")
    B:Row({ type = "toggle", label = "Seltene Gegner melden", key = "rareAlert",
            description = "Sobald einer als Plakette, im Ziel, unter der Maus oder als Symbol auf der Minikarte auftaucht." },
          { type = "toggle", label = "Ton", key = "rareSound", disabled = off })
    B:Row({ type = "toggle", label = "Zeile im Chat", key = "rareChat", disabled = off },
          { type = "toggle", label = "Hinweis oben", key = "rareToast", disabled = off,
            description = "Verschiebst du im Gestaltungsmodus; ein Klick schließt ihn." })
    B:Row({ type = "toggle", label = "Auch in Dungeons", key = "rareInstances", disabled = off },
          { type = "toggle", label = "Auch tote melden", key = "rareDead", disabled = off,
            description = "Gemerkt wird jeder gesehene, auch ohne Meldung." })
    B:Note("Welche es in deinem Gebiet gibt, wann du sie zuletzt gesehen hast und wie lange sie in Classic zum Wiederkommen brauchten: /wcui selten.")
end

-- An den Komfort haengen: Standardwerte und eine Seite.
local mod = K.Module(KEY)
if mod then
    for k, v in pairs(RA.DEFAULTS) do
        if mod.defaults[k] == nil then mod.defaults[k] = v end
    end
    mod.pages[#mod.pages + 1] = { key = "selten", label = "Seltene Gegner", build = Build }
end

K.Listen(function(kind, key)
    if (kind == "active" or kind == "setting") and key == KEY then Apply() end
end)
