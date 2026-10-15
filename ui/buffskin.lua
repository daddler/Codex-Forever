--------------------------------------------------
-- WeintCodex :: Oberflaeche - Buffs und Debuffs am Bildschirmrand (6.36.0.0)
--------------------------------------------------
-- Die Symbole des Spiels oben rechts (BuffFrame, DebuffFrame, Waffen-
-- verzauberungen) im Stil der Aktionsknoepfe: Symbol beschnitten, feiner
-- dunkler Rand, Restzeit klein in der Schrift von WeintCodex darunter,
-- Stapel unten rechts. Debuffs behalten die Farbe ihrer Art (Magie,
-- Fluch ...) - am eigenen Rand statt am Rahmen des Spiels.
--
-- Die Knoepfe bleiben die des Spiels (Rechtsklick entfernt den Buff, Tooltip
-- und Restzeit rechnet das Spiel). Nichts wird bewegt, nichts neu angelegt
-- ausser einem Rand je Knopf, einmal.
--
-- Gehoert zur Seite "Minikarte" (Schalter `buffSkin`), weil die Buffs dort
-- stehen; neu laden zum Abschalten.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIBuffSkin = {}

local BS = WeintCodex.UIBuffSkin
local K  = WeintCodex.UIKit
local C  = WeintCodex.Colors
local KEY = "minimap"

BS.CROP = 0.08
BS.TIME_SIZE, BS.COUNT_SIZE = 10, 11

local done = setmetatable({}, { __mode = "k" })
BS.done = done

local function Field(b, key)
    local r = b[key]
    if type(r) == "table" then return r end
    local name = b.GetName and b:GetName()
    if name then
        r = _G[name .. key]
        if type(r) == "table" then return r end
    end
end

-- Den Rand des Spiels ausblenden, ohne ihn zu verstecken: seine Farbe
-- (Debuff-Art) wird weiter gesetzt und hier gelesen.
local function Quiet(r)
    if r and r.SetAlpha then r:SetAlpha(0) end
end

function BS.Skin(b)
    if type(b) ~= "table" or done[b] then return done[b] end
    if b.IsForbidden and b:IsForbidden() then return nil end
    local icon = Field(b, "Icon") or Field(b, "icon")
    if not (icon and icon.SetTexCoord) then return nil end
    local d = { icon = icon }
    icon:SetTexCoord(BS.CROP, 1 - BS.CROP, BS.CROP, 1 - BS.CROP)
    d.host = CreateFrame("Frame", nil, b)
    d.host:SetAllPoints(icon)
    d.border = K.Border(d.host, 1, 0, 0, 0, 1, "OVERLAY")
    d.typed = Field(b, "DebuffBorder") or Field(b, "Border")
    Quiet(d.typed)
    Quiet(Field(b, "TempEnchantBorder"))
    local dur = Field(b, "Duration") or Field(b, "duration")
    if dur and dur.SetFont then
        K.SetFont(dur, BS.TIME_SIZE)
        local m = C.textMuted
        dur:SetTextColor(m[1], m[2], m[3], 1)
        if dur.SetShadowOffset then dur:SetShadowOffset(1, -1) end
        d.dur = dur
    end
    local count = Field(b, "Count") or Field(b, "count")
    if count and count.SetFont then
        K.SetFont(count, BS.COUNT_SIZE, "OUTLINE")
        count:ClearAllPoints()
        count:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 1, 1)
    end
    done[b] = d
    return d
end

-- Randfarbe: die Debuff-Art, die das Spiel seinem Rand gibt; sonst dunkel.
function BS.Tint(b)
    local d = done[b]
    if not d then return end
    local r, g, bl = 0, 0, 0
    local t = d.typed
    if t and t.IsShown and K.Bool(t:IsShown(), false) and t.GetVertexColor then
        local ok, vr, vg, vb = pcall(t.GetVertexColor, t)
        vr, vg, vb = K.Plain(vr), K.Plain(vg), K.Plain(vb)
        if ok and type(vr) == "number" and type(vg) == "number" and type(vb) == "number" then
            r, g, bl = vr, vg, vb
        end
        Quiet(t)
    end
    d.border:SetColor(r, g, bl, 1)
end

local function EachOf(...)
    for i = 1, select("#", ...) do
        local b = select(i, ...)
        if BS.Skin(b) then BS.Tint(b) end
    end
end
local function Each(frame)
    if type(frame) ~= "table" or not frame.GetChildren then return end
    EachOf(frame:GetChildren())
end

-- Alle Knoepfe: neue Clients (AuraContainer) und alte (BuffButtonN ...).
function BS.Scan()
    if not BS.Active() then return end
    for _, host in ipairs({ _G.BuffFrame, _G.DebuffFrame }) do
        if type(host) == "table" then
            Each(host.AuraContainer)
            Each(host)
        end
    end
    Each(_G.TemporaryEnchantFrame)
    for _, fam in ipairs(BS.FAMILIES) do
        for i = 1, fam[2] do
            local b = _G[fam[1] .. i]
            if type(b) == "table" and BS.Skin(b) then BS.Tint(b) end
        end
    end
end
BS.FAMILIES = { { "BuffButton", 32 }, { "DebuffButton", 16 }, { "TempEnchant", 3 } }

function BS.Active()
    return K.IsActive(KEY) and K.Get(KEY, "buffSkin") ~= false
end

-- Nach jedem Aktualisieren der Leisten des Spiels, und bei neuen Auren;
-- hoechstens fuenfmal je Sekunde.
local pending = CreateFrame("Frame")
pending:Hide()
local wait = 0
pending:SetScript("OnUpdate", K.Measured("Buffs", function(self, el)
    wait = wait - (el or 0)
    if wait > 0 then return end
    self:Hide()
    BS.Scan()
end))
function BS.Soon()
    if pending:IsShown() then return end
    wait = 0.2
    pending:Show()
end

local hooked = false
function BS.Start()
    if hooked or not BS.Active() then return end
    hooked = true
    if _G.hooksecurefunc then
        for _, host in ipairs({ _G.BuffFrame, _G.DebuffFrame }) do
            if type(host) == "table" then
                for _, m in ipairs({ "UpdateAuraButtons", "Update", "RefreshAuras" }) do
                    if type(host[m]) == "function" then _G.hooksecurefunc(host, m, BS.Soon) end
                end
            end
        end
        for _, fn in ipairs({ "BuffFrame_Update", "AuraButton_Update" }) do
            if type(_G[fn]) == "function" then _G.hooksecurefunc(fn, BS.Soon) end
        end
    end
    local ev = CreateFrame("Frame")
    pcall(ev.RegisterUnitEvent, ev, "UNIT_AURA", "player")
    pcall(ev.RegisterEvent, ev, "PLAYER_ENTERING_WORLD")
    ev:SetScript("OnEvent", BS.Soon)
    BS.Scan()
end

local mod = K.Module(KEY)
if mod then
    if mod.defaults.buffSkin == nil then mod.defaults.buffSkin = true end
    local enable = mod.Enable
    mod.Enable = function(...)
        if enable then enable(...) end
        BS.Start()
    end
    local page = mod.pages and mod.pages[1]
    if page then
        local build = page.build
        page.build = function(B)
            build(B)
            B:Section("Buffs")
            B:Row({ type = "toggle", label = "Buffs im WeintCodex-Stil", key = "buffSkin", reload = true,
                    description = "Die Symbole oben rechts beschnitten, mit feinem Rand und kleiner Restzeit darunter. Debuffs behalten die Farbe ihrer Art." },
                  { type = "empty" })
        end
    end
end
