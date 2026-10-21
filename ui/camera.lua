--------------------------------------------------
-- WeintCodex :: Komfort - Kameraabstand (6.111.0.0)
--------------------------------------------------
-- Wunsch: "Die Kameradistanz muss einstellbar sein, dass man mehr vom
-- Charakter wegscrollen kann als normal."
--
-- WIE: die Spieleinstellung cameraDistanceMaxZoomFactor (Vielfaches des
-- normalen Hoechstabstands). Immer ueber PF.SetCVar (ui/profile.lua): der
-- Wert von vorher ist gemerkt, "Wie im Spiel" (0) gibt ihn zurueck.
-- Wie weit der Client erlaubt, sagt er selbst: nach dem Setzen wird
-- zurueckgelesen; nimmt er weniger, steht das in der Einstellung.
-- Nie im Kampf.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UICamera = {}

local CA = WeintCodex.UICamera
local K  = WeintCodex.UIKit
local KEY = "comfort"

CA.CVAR = "cameraDistanceMaxZoomFactor"
CA.MIN, CA.MAX, CA.STEP = 1.0, 4.0, 0.1
CA.DEFAULTS = { camZoom = 0 }   -- 0 = wie im Spiel
CA.applied = nil                -- was der Client zuletzt angenommen hat

local function PF() return WeintCodex.UIProfile end

function CA.Want()
    if not K.IsActive(KEY) then return 0 end
    local v = tonumber(K.Get(KEY, "camZoom")) or 0
    if v <= 0 then return 0 end
    return math.max(CA.MIN, math.min(CA.MAX, v))
end

function CA.Apply()
    local P = PF()
    if not (P and P.SetCVar and P.Release and P.GetCVar) then return false end
    if K.InCombat() then K.AfterCombat(CA.Apply) return false end
    local v = CA.Want()
    if v == 0 then
        P.Release(CA.CVAR)
        CA.applied = nil
        return true
    end
    if not P.SetCVar(CA.CVAR, string.format("%.1f", v), KEY) then return false end
    local got = P.GetCVar(CA.CVAR)
    CA.applied = tonumber(got)
    -- Nahm das Spiel weniger, gilt SEIN Wert als unserer - sonst gaebe
    -- "Wie im Spiel" den alten Wert nie zurueck (PF.Release vergleicht).
    if got and CA.applied and math.abs(CA.applied - v) > 0.05 then P.SetCVar(CA.CVAR, got, KEY) end
    return true
end

local ev = CreateFrame("Frame")
pcall(ev.RegisterEvent, ev, "PLAYER_LOGIN")
ev:SetScript("OnEvent", function() CA.Apply() end)

K.Listen(function(kind, key, sub)
    if key ~= KEY then return end
    if kind == "active" or (kind == "setting" and (sub == "camZoom" or sub == "*" or sub == "enabled")) then CA.Apply() end
end)

--------------------------------------------------
-- Einstellung: Komfort -> Alltag -> Anzeigen
--------------------------------------------------
local mod = K.Module(KEY)
if mod then
    for k, v in pairs(CA.DEFAULTS) do
        if mod.defaults[k] == nil then mod.defaults[k] = v end
    end
    for _, page in ipairs(mod.pages) do
        if page.key == "anzeigen" then
            local orig = page.build
            page.build = function(B, ...)
                if orig then orig(B, ...) end
                B:Section("Kamera", "Wie weit du mit dem Mausrad vom Charakter wegzoomen kannst. „Wie im Spiel“ lässt die Einstellung des Spiels in Ruhe.")
                B:Row({ type = "slider", label = "Höchster Kameraabstand", key = "camZoom", min = 0, max = CA.MAX, step = CA.STEP,
                        format = function(v)
                            v = tonumber(v) or 0
                            if v <= 0 then return "Wie im Spiel" end
                            local got = CA.applied
                            if got and got + 0.05 < v then
                                return string.format("%.1f× (Spiel erlaubt %.1f×)", v, got)
                            end
                            return string.format("%.1f×", math.max(CA.MIN, v))
                        end,
                        tooltip = "1,0× ist der normale Abstand. Höher: weiter weg. Wie weit, entscheidet das Spiel – nimmt es weniger, steht das hier." },
                      { type = "empty" })
            end
        end
    end
end
