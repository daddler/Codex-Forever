--------------------------------------------------
-- WeintCodex :: Komfort - Schaden und Heilung an dir als schwebende Zahl
--------------------------------------------------
-- 1.0.5.69 (Frage eines Spielers: "wo stelle ich ein, dass Schaden und
-- Heilung, die ich bekomme, nicht am Charakterbild stehen, sondern so wie
-- die Schadenszahlen?" - Wunsch: "als optionale Moeglichkeit").
--
-- Was du abbekommst, steigt als Zahl von einem Ankerpunkt auf und
-- verblasst: Schaden rot mit Minus, Heilung gruen mit Plus, kritische
-- Treffer groesser. Ab Werk AUS (Komfort, Seite "Anzeigen").
--
-- WOHER. UNIT_COMBAT fuer "player" - dasselbe Ereignis, aus dem die Zahl im
-- Einheitenrahmen kommt (ui/unitframes.lua, Frame:CombatFeedback). Die Art
-- ("WOUND"/"HEAL") muss lesbar sein; ist sie geheim, gibt es keine Zahl
-- statt einer falschen Farbe. Die Zahl selbst darf geheim sein: sie geht
-- ueber UIDamageMeter.Format und SetFormattedText an den Client, Lua
-- rechnet nie damit.
--
-- BEWEGUNG rechnet das Spiel (AnimationGroup je Zeile): kein Takt je Bild,
-- kein Abfall je Treffer - die Zeilen kommen aus einem festen Vorrat
-- (ST.LINES) und werden reihum neu benutzt.
--------------------------------------------------

local K = WeintCodex.UIKit
local C = WeintCodex.Colors
local KEY = "comfort"

WeintCodex.UISelfText = {}
local ST = WeintCodex.UISelfText

ST.DEFAULTS = { selfText = false }
ST.LINES = 10            -- so viele Zahlen zugleich
ST.RISE, ST.TIME = 70, 1.4
ST.SPREAD = 44           -- Zahlen nebeneinander: links, Mitte, rechts
ST.stats = { shown = 0, secretKind = 0 }

function ST.Active() return K.IsActive(KEY) and K.Get(KEY, "selfText") and true or false end

local anchor, lines, nextLine = nil, {}, 0

local function Build()
    if anchor then return anchor end
    anchor = CreateFrame("Frame", "WeintCodexSelfText", UIParent)
    anchor:SetSize(140, 30)
    anchor:SetFrameStrata("HIGH")
    for i = 1, ST.LINES do
        local fs = K.NewText(anchor, 18, "OVERLAY")
        fs:SetPoint("BOTTOM", anchor, "BOTTOM", 0, 0)
        fs:SetAlpha(0)
        if fs.CreateAnimationGroup then
            local ok, ag = pcall(fs.CreateAnimationGroup, fs)
            if ok and type(ag) == "table" and ag.CreateAnimation then
                pcall(function()
                    local mv = ag:CreateAnimation("Translation")
                    mv:SetOffset(0, ST.RISE)
                    mv:SetDuration(ST.TIME)
                    mv:SetSmoothing("OUT")
                    local show = ag:CreateAnimation("Alpha")
                    show:SetFromAlpha(1)
                    show:SetToAlpha(1)
                    show:SetDuration(ST.TIME * 0.55)
                    local fade = ag:CreateAnimation("Alpha")
                    fade:SetFromAlpha(1)
                    fade:SetToAlpha(0)
                    fade:SetDuration(ST.TIME * 0.45)
                    fade:SetStartDelay(ST.TIME * 0.55)
                    ag:SetScript("OnFinished", function() fs:SetAlpha(0) end)
                    fs.anim = ag
                end)
            end
        end
        lines[i] = fs
    end
    anchor.WCShowForUnlock = function(self, on)
        self._unlock = on and true or nil
        if on then ST.Show("WOUND", nil, 123) ST.Show("HEAL", "CRITICAL", 456) end
    end
    K.RegisterMover(anchor, "selftext", "Schaden an dir", K.Layout("selftext"))
    ST.anchor, ST.lines = anchor, lines
    return anchor
end

-- Eine Zahl zeigen. action "WOUND"/"HEAL"; amount darf geheim sein.
function ST.Show(action, flag, amount)
    local act = K.Plain(action)
    if act ~= "WOUND" and act ~= "HEAL" then
        if type(action) ~= "nil" and type(act) == "nil" then ST.stats.secretKind = ST.stats.secretKind + 1 end
        return false
    end
    if type(amount) == "nil" then return false end
    local plain = K.Plain(amount)
    if type(plain) == "number" and plain <= 0 then return false end
    local DM = WeintCodex.UIDamageMeter
    local ok, text = pcall(DM and DM.Format or tostring, amount)
    if not ok or type(text) == "nil" then return false end
    Build()
    nextLine = nextLine % ST.LINES + 1
    local fs = lines[nextLine]
    local c = act == "WOUND" and C.danger or C.success
    local crit = K.Plain(flag) == "CRITICAL"
    K.SetFont(fs, crit and 24 or 18)
    fs:SetTextColor(c[1], c[2], c[3], 1)
    if not pcall(fs.SetFormattedText, fs, act == "WOUND" and "-%s" or "+%s", text) then return false end
    -- Reihum links, Mitte, rechts - zwei Treffer zugleich decken sich nicht.
    fs:ClearAllPoints()
    fs:SetPoint("BOTTOM", anchor, "BOTTOM", ((nextLine % 3) - 1) * ST.SPREAD, 0)
    fs:SetAlpha(1)
    fs:Show()
    if fs.anim then pcall(function() fs.anim:Stop() fs.anim:Play() end) end
    ST.stats.shown = ST.stats.shown + 1
    return true
end

local ev = CreateFrame("Frame")
ev:SetScript("OnEvent", K.Measured("Schaden an dir", function(_, _, unit, action, flag, amount)
    if K.IsSecret(unit) or unit ~= "player" then return end
    ST.Show(action, flag, amount)
end))
ST.events = ev

function ST.Apply()
    if ST.Active() then
        Build()
        pcall(ev.RegisterEvent, ev, "UNIT_COMBAT")
        ST.listening = true
        K.SetMoverEnabled("selftext", true)
    else
        ev:UnregisterAllEvents()
        ST.listening = false
        if anchor then K.SetMoverEnabled("selftext", false) end
        for _, fs in ipairs(lines) do fs:SetAlpha(0) end
    end
end

K.Listen(function(kind, key)
    if (kind == "active" or kind == "setting") and key == KEY then ST.Apply() end
end)
