--------------------------------------------------
-- WeintCodex :: Komfort - Seite "Glanz" (6.43.0.0)
--------------------------------------------------
-- Einstellungen zu ui/glanz.lua: an/aus, wo, was, wie stark, wie oft.
--------------------------------------------------

local GZ = WeintCodex.UIGlanz
local K  = WeintCodex.UIKit
local KEY = "comfort"

local function Build(B)
    local off = function() return not GZ.On() end
    B:Section("Glanz", "Balken leben: ein Schimmer läuft ab und zu darüber, Werte gleiten statt zu springen, und was ein Treffer nahm, bleibt kurz hell stehen – wie an den Namensplaketten.")
    B:Row({ type = "toggle", label = "Glanz einschalten", key = "glanz" },
          { type = "empty" })
    B:Section("Wo")
    local a = GZ.AREAS
    for i = 1, #a, 2 do
        local x, y = a[i], a[i + 1]
        B:Row({ type = "toggle", label = x.label, key = x.opt, disabled = off },
              y and { type = "toggle", label = y.label, key = y.opt, disabled = off } or { type = "empty" })
    end
    B:Section("Was")
    B:Row({ type = "toggle", label = "Schimmer", key = "glanzSheen", disabled = off,
            description = "Ein heller Streifen läuft über den Balken, dann Ruhe." },
          { type = "toggle", label = "Gleiten", key = "glanzSmooth", disabled = off,
            description = "Der Balken läuft zum neuen Wert." })
    B:Row({ type = "toggle", label = "Schadensspur", key = "glanzTrail", disabled = off,
            description = "Bei Leben: was ein Treffer nahm, bleibt kurz hell stehen." },
          { type = "empty" })
    B:Section("Wie")
    B:Row({ type = "slider", label = "Stärke des Schimmers", key = "glanzStrength", min = 10, max = 100, step = 10, disabled = off,
            format = function(v) return string.format("%d %%", v) end },
          { type = "slider", label = "Ruhe zwischen zwei Läufen", key = "glanzPause", min = 1, max = 15, step = 1, disabled = off,
            format = function(v) return string.format("%d s", v) end })
    B:Row({ type = "slider", label = "Dauer eines Laufs", key = "glanzRun", min = 4, max = 20, step = 1, disabled = off,
            format = function(v) return (string.format("%.1f s", v / 10):gsub("%.", ",")) end },
          { type = "empty" })
end

local mod = K.Module(KEY)
if mod and GZ then
    for k, v in pairs(GZ.DEFAULTS) do
        if mod.defaults[k] == nil then mod.defaults[k] = v end
    end
    mod.pages[#mod.pages + 1] = { key = "glanz", label = "Glanz", build = Build }
end
