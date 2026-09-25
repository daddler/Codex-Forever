--------------------------------------------------
-- WeintCodex :: Oberflaeche - Fundament
--------------------------------------------------
-- Das optionale Oberflaechenpaket. Alles unter ui/ ist ZUSATZ: wer es nie
-- einschaltet, hat dasselbe WeintCodex wie vorher, und kein Blizzard-
-- Rahmen wird angefasst.
--
-- ZWEI ARTEN VON MODULEN, und der Unterschied ist die ganze Idee:
--
--   group = "ui"    Namensplaketten, Einheitenrahmen. Sie ERSETZEN
--                   Blizzard-Rahmen und laufen nur, wenn der Hauptschalter
--                   "WeintCodex-Oberflaeche" an ist UND das Modul selbst.
--                   Aendern verlangt ein Neuladen: einen ersetzten
--                   Blizzard-Rahmen sauber zurueckzugeben ist im laufenden
--                   Spiel nicht zu haben, ohne Taint zu riskieren.
--   group = "qol"   Questpfeil, Komfortfunktionen. Sie haengen NICHT am
--                   Hauptschalter - wer die Oberflaeche nicht will, soll
--                   den Pfeil trotzdem haben koennen. Sie schalten sofort.
--
-- VORBILD UND GRENZE. Aufbau, Funktionsumfang und Voreinstellungen folgen
-- EllesmereUI (Stand 9.2.6). Uebernommen sind Ideen, Optionsnamen und
-- Zahlen, KEIN Code und KEINE Grafik: die Vorlage steht unter "all rights
-- reserved". Farben und Schriften sind die von WeintCodex.
--
-- SPEICHER. Ausschliesslich WeintCodex_SavedData.ui - dieselbe Tabelle,
-- die in der .toc steht (Regel aus CLAUDE.md). Gespeichert wird nur, was
-- vom Standard abweicht; der Standard steht beim Modul. Ein Modul, dessen
-- Voreinstellung sich aendert, zieht damit bei allen nach, die den Wert nie
-- angefasst haben.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIKit = {}

local K = WeintCodex.UIKit
local C = WeintCodex.Colors
local F = WeintCodex.Fonts

local modules, order = {}, {}
K.modules, K.order = modules, order

--------------------------------------------------
-- Geheime Werte
--------------------------------------------------
-- Ab Client 12.0 liefert das Spiel im Kampf viele Einheitenwerte als
-- "secret": sie lassen sich an StatusBar:SetValue und FontString:SetText
-- weiterreichen, aber nicht vergleichen und nicht rechnen - ein `<` darauf
-- ist ein Lua-Fehler. Forever laeuft nach allem, was bekannt ist, auf
-- diesem Unterbau. Jede Stelle, die einen Wert VERGLEICHT, fragt vorher.
--------------------------------------------------

function K.IsSecret(v)
    local f = _G.issecretvalue
    return f ~= nil and f(v) and true or false
end

-- Ein Wert, mit dem Lua rechnen darf - oder nil, wenn nicht.
function K.Plain(v)
    if K.IsSecret(v) then return nil end
    return v
end

-- Ein Wahrheitswert, der geheim sein koennte, als `true`/`false`. Geheim
-- zaehlt als `fallback` - der Aufrufer sagt, welcher Irrtum der billigere ist.
function K.Bool(v, fallback)
    if K.IsSecret(v) then return fallback and true or false end
    return v and true or false
end

--------------------------------------------------
-- Speicher
--------------------------------------------------

local function Root()
    local sv = WeintCodex.SavedData
    if not sv then return nil end
    sv.ui = sv.ui or {}
    local ui = sv.ui
    ui.modules   = ui.modules or {}
    ui.positions = ui.positions or {}
    return ui
end

function K.Root() return Root() end

-- Die gespeicherten Abweichungen eines Moduls (nie nil, sobald SavedData
-- steht; davor eine leere Tabelle, die nie gespeichert wird - gelesen wird
-- davor nur der Standard).
local EMPTY = {}
local function Store(key)
    local ui = Root()
    if not ui then return EMPTY end
    ui.modules[key] = ui.modules[key] or {}
    return ui.modules[key]
end

local function CopyValue(v)
    if type(v) ~= "table" then return v end
    local out = {}
    for k, x in pairs(v) do out[k] = x end
    return out
end

-- Farbvorgabe aus core/ui.lua als { r, g, b }.
function K.ColorDefault(name)
    local col = (WeintCodex.GameColors and WeintCodex.GameColors[name])
        or C[name] or C.textNormal
    return { r = col[1], g = col[2], b = col[3] }
end

function K.Get(moduleKey, key)
    local v = Store(moduleKey)[key]
    if v ~= nil then return v end
    local m = modules[moduleKey]
    return m and m.defaults and m.defaults[key]
end

function K.Set(moduleKey, key, value)
    local m = modules[moduleKey]
    local store = Store(moduleKey)
    local default = m and m.defaults and m.defaults[key]

    -- Gleich dem Standard -> Eintrag entfernen. Sonst hielte die Datei
    -- einen Wert fest, der beim naechsten Standardwechsel nicht mitzoege.
    local same = (value == default)
    if not same and type(value) == "table" and type(default) == "table" then
        same = true
        for k, x in pairs(value) do
            if default[k] ~= x then same = false break end
        end
    end
    -- Kein `(not same) and CopyValue(value) or nil`: fuer value == false
    -- ergibt das nil, und ein Schalter, der von "an" (Standard) auf "aus"
    -- gestellt wird, waere nie gespeichert worden. Genau so war es bis
    -- 6.0.0.3 - keine standardmaessig eingeschaltete Option liess sich
    -- abschalten.
    if same then
        store[key] = nil
    else
        store[key] = CopyValue(value)
    end

    if m and m.OnSetting then
        local ok, err = pcall(m.OnSetting, key, value)
        if not ok then K.Report(moduleKey, err) end
    end
    K.Fire("setting", moduleKey, key)
end

-- Farbe: immer eine frische Tabelle zurueck, nie die gespeicherte -
-- ein Aufrufer, der darin schreibt, schriebe sonst am Speicher vorbei in
-- ihn hinein.
function K.GetColor(moduleKey, key)
    local c = K.Get(moduleKey, key)
    if type(c) ~= "table" then return { r = 1, g = 1, b = 1 } end
    return { r = c.r or 1, g = c.g or 1, b = c.b or 1 }
end

function K.ResetModule(moduleKey)
    local ui = Root()
    if not ui then return end
    local enabled = ui.modules[moduleKey] and ui.modules[moduleKey].enabled
    ui.modules[moduleKey] = { enabled = enabled }
    local m = modules[moduleKey]
    if m and m.OnSetting then pcall(m.OnSetting, "*") end
    K.Fire("setting", moduleKey, "*")
end

--------------------------------------------------
-- Hauptschalter
--------------------------------------------------

-- DER HAUPTSCHALTER IST SEIT 6.0.0.3 AUSGESETZT - UND BEREIT FUER DIE
-- RUECKKEHR.
--
-- Die Oberflaeche war freiwillig: Frage beim Einloggen (ui/welcome.lua),
-- Hauptschalter in /wcui und in den Einstellungen. Das setzt voraus, dass
-- der Client die Antwort speichert. Der Forever-Beta-Client tut das nicht
-- (gemeldet mit 6.0.0.1, bestaetigt mit 6.0.0.2: auch "Mit Esc schliessen"
-- ueberlebt kein /reload). Eine Wahl, die nach jedem Neuladen vergessen
-- ist, ist keine - also ist die Oberflaeche jetzt fuer alle an.
--
-- K.OPT_IN ist die EINE Stelle, an der das zurueckgedreht wird. Steht es
-- auf true, gilt wieder alles von vorher, ohne weitere Aenderung:
--   * K.UIEnabled() liest wieder den gespeicherten Hauptschalter,
--   * die Frage beim Einloggen kommt wieder (ui/welcome.lua),
--   * der Hauptschalter in /wcui und in den Einstellungen ist wieder
--     bedienbar, die Einfuehrung spricht wieder von "freiwillig".
-- Alle drei Stellen fragen K.OPT_IN, und load_test.lua prueft beide
-- Zustaende. Wann umschalten: sobald WeintCodex.SaveHealth() nach einem
-- /reload "ok" meldet (Einstellungen -> Diagnose -> Speichern).
K.OPT_IN = false

function K.UIEnabled()
    if not K.OPT_IN then return true end
    local ui = Root()
    return ui ~= nil and ui.enabled == true
end

-- Wird der Hauptschalter umgelegt, ist ein Neuladen faellig (siehe oben).
-- Ohne OPT_IN gibt es nichts umzulegen.
function K.SetUIEnabled(on)
    if not K.OPT_IN then return end
    local ui = Root()
    if not ui then return end
    ui.enabled = on and true or false
    K.MarkReload()
    K.Fire("setting", "general", "enabled")
end

function K.ModuleEnabled(moduleKey)
    local m = modules[moduleKey]
    if not m then return false end
    local v = Store(moduleKey).enabled
    if v == nil then v = m.defaultEnabled ~= false end
    return v and true or false
end

-- Laeuft das Modul in DIESER Sitzung? Fuer ui-Module ist das der Stand
-- beim Anmelden, nicht der gespeicherte - der gilt erst nach dem Neuladen.
function K.IsActive(moduleKey)
    local m = modules[moduleKey]
    return m ~= nil and m._active == true
end

-- Wuerde das Modul nach dem naechsten Laden laufen?
function K.WantsActive(moduleKey)
    local m = modules[moduleKey]
    if not m then return false end
    if m.group == "ui" and not K.UIEnabled() then return false end
    return K.ModuleEnabled(moduleKey)
end

local reloadPending = false
function K.MarkReload() reloadPending = true K.Fire("reload") end
function K.ReloadPending() return reloadPending end

function K.SetModuleEnabled(moduleKey, on)
    local m = modules[moduleKey]
    if not m then return end
    Store(moduleKey).enabled = on and true or false

    if m.group == "ui" or m.reload then
        K.MarkReload()
    elseif on then
        K.Activate(moduleKey)
    else
        K.Deactivate(moduleKey)
    end
    K.Fire("setting", moduleKey, "enabled")
end

--------------------------------------------------
-- Modulregister
--------------------------------------------------
-- def = {
--   key, group = "ui"|"qol", title, description, order,
--   defaults = { ... }, defaultEnabled = true|false,
--   Enable = function() end,   -- beim Anmelden bzw. beim Einschalten
--   Disable = function() end,  -- nur qol: beim Ausschalten
--   OnSetting = function(key, value) end,
--   pages = { { key, label, build = function(B) end }, ... },
--   preview = function(parent) return frame, height end,  -- optional
--   status = function() return text, tone end,             -- optional
-- }
--------------------------------------------------

function K.Register(def)
    assert(type(def) == "table" and def.key, "UIKit.Register: key fehlt")
    def.defaults = def.defaults or {}
    def.pages = def.pages or {}
    if not modules[def.key] then order[#order + 1] = def.key end
    modules[def.key] = def
    table.sort(order, function(a, b)
        return (modules[a].order or 100) < (modules[b].order or 100)
    end)
    return def
end

function K.Module(key) return modules[key] end

-- Ein Fehler in einem Modul darf die anderen nicht mitnehmen. Gemeldet
-- wird er trotzdem - einmal, in den Chat, mit dem Modulnamen: still
-- verschluckt saehe er aus wie ein Modul, das nichts tut.
local reported = {}
function K.Report(moduleKey, err)
    local key = tostring(moduleKey) .. tostring(err)
    if reported[key] then return end
    reported[key] = true
    print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " "
        .. WeintCodex.ColorText("warning", "Oberfläche/" .. tostring(moduleKey)
        .. ": ") .. tostring(err))
end

function K.Activate(moduleKey)
    local m = modules[moduleKey]
    if not m or m._active then return end
    if m.Enable then
        local ok, err = pcall(m.Enable)
        if not ok then K.Report(moduleKey, err) return end
    end
    m._active = true
    K.Fire("active", moduleKey)
end

function K.Deactivate(moduleKey)
    local m = modules[moduleKey]
    if not m or not m._active then return end
    if m.Disable then
        local ok, err = pcall(m.Disable)
        if not ok then K.Report(moduleKey, err) end
    end
    m._active = false
    K.Fire("active", moduleKey)
end

--------------------------------------------------
-- Rueckrufe (fuer das Einstellungsfenster)
--------------------------------------------------

local listeners = {}
function K.Listen(fn) listeners[#listeners + 1] = fn end
function K.Fire(kind, ...)
    for _, fn in ipairs(listeners) do pcall(fn, kind, ...) end
end

--------------------------------------------------
-- Kampfsperre
--------------------------------------------------
-- Geschuetzte Rahmen (Einheitenrahmen, Blizzard-Rahmen, die wir
-- verstecken) duerfen im Kampf weder bewegt noch umgehaengt werden. Was
-- in den Kampf faellt, wird danach nachgeholt statt verworfen.
--------------------------------------------------

local afterCombat = {}
function K.InCombat()
    return _G.InCombatLockdown ~= nil and _G.InCombatLockdown() and true or false
end

function K.AfterCombat(fn)
    if not K.InCombat() then
        fn()
        return
    end
    afterCombat[#afterCombat + 1] = fn
end

--------------------------------------------------
-- Schriften und Balken
--------------------------------------------------
-- In der Spielwelt gilt eine Ausnahme von der Regel "kein OUTLINE" aus
-- core/ui.lua: das Fenster steht auf einer ruhigen, dunklen Flaeche, eine
-- Namensplakette ueber Gras, Schnee und Zauberwirkungen. Ohne Kontur ist
-- sie dort nicht lesbar. Die Kontur ist deshalb einstellbar und
-- standardmaessig duenn.
--------------------------------------------------

-- Seit 6.1.0.0 ist die schmale Plex (Condensed) der Standard: Namen und
-- Zahlen auf Plaketten und Rahmen brauchen Breite, nicht Hoehe. Wer die
-- breite Plex von vorher will, stellt sie unter Allgemein ein.
function K.FontPath()
    local choice = K.Get("general", "font")
    if choice == "game" then
        return _G.STANDARD_TEXT_FONT or F.hudSemi
    elseif choice == "plex" then
        return F.sansMedium
    elseif choice == "plexsemi" then
        return F.sansSemi
    end
    return F.hudSemi
end

function K.FontFlags()
    local o = K.Get("general", "outline")
    if o == "none" then return "" end
    if o == "thick" then return "THICKOUTLINE" end
    return "OUTLINE"
end

-- Die Schrift des Spiels als letzter Rueckfall: sie ist immer geladen.
local FALLBACK_FONT = "Fonts\\FRIZQT__.TTF"

function K.SetFont(fs, size)
    -- type() und nicht nur `fs and`: ein Feld, das es nicht gibt oder das
    -- etwas anderes ist als eine Schriftzeile, soll uebersprungen werden,
    -- nicht beim Indizieren abstuerzen.
    if type(fs) ~= "table" or type(fs.SetFont) ~= "function" then return end
    -- SetFont meldet false, wenn die Datei nicht geladen werden konnte -
    -- und dann hat die Zeile KEINE Schrift mehr. Jedes spaetere SetText
    -- bricht ab, auch das des Spiels auf dessen eigenen Knoepfen. Also
    -- nie ohne Schrift zuruecklassen.
    local ok = fs:SetFont(K.FontPath(), size or 11, K.FontFlags())
    if ok == false then
        ok = fs:SetFont(_G.STANDARD_TEXT_FONT or FALLBACK_FONT, size or 11, K.FontFlags())
        if ok == false then fs:SetFont(FALLBACK_FONT, size or 11, "") end
    end
    -- Mit Kontur braucht es keinen Schatten; ohne Kontur ist er das
    -- Einzige, was den Text vom Hintergrund trennt.
    if fs.SetShadowOffset then
        if K.FontFlags() == "" then
            fs:SetShadowOffset(1, -1)
            fs:SetShadowColor(0, 0, 0, 1)
        else
            fs:SetShadowOffset(0, 0)
        end
    end
end

-- Jede Textzeile der Oberflaeche entsteht HIER, mit Schrift. Text ohne
-- Schrift ist im Client ein Fehler ("Font not set"), und bis 6.0.0.5
-- bekam manche Zeile ihre Schrift erst in einem spaeteren Layout - wer
-- vorher schrieb (ein Zauberbalken, dessen Gegner schon zauberte), brach
-- ab. load_test.lua verbietet CreateFontString ausserhalb dieser Datei.
function K.NewText(parent, size, layer, sublevel)
    local fs = parent:CreateFontString(nil, layer or "OVERLAY", nil, sublevel)
    K.SetFont(fs, size or 11)
    return fs
end

K.MEDIA = "Interface\\AddOns\\WeintCodex\\media\\ui\\"
K.BAR_TEXTURE = "Interface\\Buttons\\WHITE8X8"     -- flach, und fuer Flaechen
K.GLOSS_TEXTURE = K.MEDIA .. "bar"                     -- Balken mit Glanz (Standard)
K.GLOW_TEXTURE = K.MEDIA .. "glow"                     -- weicher Schein, 8 px
K.GLOW_WIDE_TEXTURE = K.MEDIA .. "glow_wide"           -- weicher Schein, 24 px
K.MARK_TEXTURE = K.MEDIA .. "targetmark"               -- Zielmarke der Plakette
K.ARROW_TEXTURE = K.MEDIA .. "arrow"

--------------------------------------------------
-- Stil 2.0: Balken, Schein, Kachel
--------------------------------------------------
-- docs/design/ui-2.0.md, Grundsatz 3: jede Flaeche ist dieselbe Kachel,
-- jeder Balken hat denselben Glanz. Die Module bauen Balken und Flaechen
-- nur noch hier - eine zweite Formensprache entsteht sonst von selbst.
--------------------------------------------------

-- Welche Textur ein Balken traegt. "glanz" (Standard): die eigene
-- Verlaufstextur; "flat": eine Farbe; "gradient": die Stufe von vorher.
function K.BarTexture()
    local style = K.Get("general", "barStyle")
    if style == "flat" or style == "gradient" then return K.BAR_TEXTURE end
    return K.GLOSS_TEXTURE
end

-- Jeder Balken der Oberflaeche entsteht HIER: mit Textur und einer feinen
-- Lichtkante oben. Schwach gemerkt, damit ein Wechsel des Balkenstils sie
-- alle erreicht (K.RestyleBars), ohne dass jemand sie festhaelt.
local bars = setmetatable({}, { __mode = "k" })

local function BarLight(sb)
    local l = sb._wcLight
    if not l then return end
    local c = WeintCodex.GameColors.barLight
    l:SetColorTexture(c[1], c[2], c[3], c[4])
    if K.Get("general", "barStyle") == "flat" then l:Hide() else l:Show() end
end

function K.NewBar(parent, noLight)
    local sb = CreateFrame("StatusBar", nil, parent)
    sb:SetStatusBarTexture(K.BarTexture())
    if not noLight then
        local l = sb:CreateTexture(nil, "OVERLAY", nil, -1)
        l:SetPoint("TOPLEFT", sb, "TOPLEFT", 0, 0)
        l:SetPoint("TOPRIGHT", sb, "TOPRIGHT", 0, 0)
        l:SetHeight(1)
        sb._wcLight = l
        BarLight(sb)
    end
    bars[sb] = true
    return sb
end

function K.RestyleBars()
    local tex = K.BarTexture()
    for sb in pairs(bars) do
        sb:SetStatusBarTexture(tex)
        -- Neue Textur, neue Farbe: der Zwischenspeicher in PaintBar gilt
        -- nicht mehr.
        sb._wcR, sb._wcStyle = nil, nil
        BarLight(sb)
    end
end

-- Ob der Client Neunteiler aus EINER Textur kann (SetTextureSliceMargins).
-- Ohne ihn waere der Schein ein gestrecktes Rechteck mit breiigen Kanten -
-- dann lieber keiner, und die Flaechen behalten ihren schwarzen Rand.
K.canSlice = nil

-- Weicher Schein um einen Rahmen: schwarz als Schatten, im Akzent als
-- Leuchten, weiss unter der Maus. `spread` = wie weit er nach aussen
-- reicht. Liefert { tex, SetColor, SetShown, SetSpread, ok }.
--
-- Der Schein ist INNEN voll deckend (dort liegt der Rahmen darueber). Er
-- muss deshalb UNTER dem Rahmen liegen: auf dem Rahmen selbst in der
-- untersten Ebene, oder auf einem Rahmen darunter (opts.host).
--
-- opts.shadow = true: ein Schatten, den der Schalter "Weiche Schatten"
-- (Allgemein) mit abschaltet.
local shadows = setmetatable({}, { __mode = "k" })

function K.ShadowsOn()
    return K.Get("general", "shadows") ~= false
end

function K.ApplyShadows()
    for o in pairs(shadows) do o:SetShown(o._want) end
end

function K.Glow(frame, opts)
    opts = opts or {}
    local host = opts.host or frame
    local wide = opts.wide and true or false
    local margin = wide and 24 or 8
    local t = host:CreateTexture(nil, opts.layer or "BACKGROUND", nil, opts.sublevel or -8)
    t:SetTexture(wide and K.GLOW_WIDE_TEXTURE or K.GLOW_TEXTURE)
    local ok = type(t.SetTextureSliceMargins) == "function"
        and pcall(t.SetTextureSliceMargins, t, margin, margin, margin, margin)
    if ok and t.SetTextureSliceMode and _G.Enum and _G.Enum.UITextureSliceMode then
        pcall(t.SetTextureSliceMode, t, _G.Enum.UITextureSliceMode.Stretched)
    end
    if K.canSlice == nil then K.canSlice = ok and true or false end
    if opts.blend and t.SetBlendMode then t:SetBlendMode(opts.blend) end

    local o = { tex = t, ok = ok and true or false }
    function o:SetSpread(s)
        t:ClearAllPoints()
        t:SetPoint("TOPLEFT", frame, "TOPLEFT", -s, s)
        t:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", s, -s)
    end
    function o:SetColor(r, g, b, a) t:SetVertexColor(r, g, b, a or 1) end
    function o:SetShown(v)
        self._want = v and true or false
        if v and self.ok and (not self._isShadow or K.ShadowsOn()) then t:Show() else t:Hide() end
    end
    if opts.shadow then
        o._isShadow = true
        shadows[o] = true
    end
    o:SetSpread(opts.spread or margin)
    local c = opts.color or WeintCodex.GameColors.shadow
    o:SetColor(c[1], c[2], c[3], c[4])
    o:SetShown(opts.shown ~= false)
    return o
end

-- Die Kachel (Grundsatz 3): Graphit 88 %, 1 px Schwarz, Lichtkante oben,
-- weicher Schatten. opts = { alpha = 0..1, shadow = px (0 = keiner),
-- border = false }.
function K.Kachel(frame, opts)
    opts = opts or {}
    local GC = WeintCodex.GameColors
    local o = {}
    local f = GC.kachelFill
    o.bg = frame:CreateTexture(nil, "BACKGROUND", nil, -7)
    o.bg:SetAllPoints(frame)
    o.bg:SetColorTexture(f[1], f[2], f[3], opts.alpha or f[4])
    local l = GC.lightEdge
    o.light = frame:CreateTexture(nil, "BORDER", nil, 1)
    o.light:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    o.light:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    o.light:SetHeight(1)
    o.light:SetColorTexture(l[1], l[2], l[3], l[4])
    o.border = K.Border(frame, 1, 0, 0, 0, 1, "BORDER")
    if opts.border == false then o.border:SetShown(false) end
    if (opts.shadow or 6) > 0 then
        o.shadow = K.Glow(frame, { spread = opts.shadow or 6, shadow = true })
    end
    function o:SetAlpha(a) self.bg:SetAlpha(1) local c = GC.kachelFill self.bg:SetColorTexture(c[1], c[2], c[3], a) end
    function o:SetShown(v)
        if v then self.bg:Show() self.light:Show() else self.bg:Hide() self.light:Hide() end
        self.border:SetShown(v)
        if self.shadow then self.shadow:SetShown(v) end
    end
    return o
end

-- Flach oder mit leichtem Verlauf. Der Verlauf ist eine Helligkeitsstufe
-- derselben Farbe, keine zweite Farbe.
function K.PaintBar(bar, r, g, b)
    local tex = bar.GetStatusBarTexture and bar:GetStatusBarTexture()
    if not tex then return end
    -- Jeder Treffer faerbt neu ein, die Farbe aendert sich fast nie. Der
    -- Verlauf legt je Aufruf zwei Farbobjekte an - bei zwanzig Plaketten
    -- im Kampf ist das Muell fuer den Speicherbereiniger ohne jeden Nutzen.
    -- r/g/b stammen immer aus Einstellungen oder Klassenfarben, nie aus
    -- einem geheimen Wert; der Vergleich ist also erlaubt.
    local style = K.Get("general", "barStyle")
    if bar._wcR == r and bar._wcG == g and bar._wcB == b and bar._wcStyle == style then return end
    bar._wcR, bar._wcG, bar._wcB, bar._wcStyle = r, g, b, style
    if style == "gradient" and tex.SetGradient
       and _G.CreateColor then
        tex:SetVertexColor(1, 1, 1, 1)
        tex:SetGradient("VERTICAL",
            _G.CreateColor(r * 0.72, g * 0.72, b * 0.72, 1),
            _G.CreateColor(r, g, b, 1))
    else
        if tex.SetGradient and _G.CreateColor and tex._wcGradient then
            tex:SetGradient("VERTICAL", _G.CreateColor(1, 1, 1, 1), _G.CreateColor(1, 1, 1, 1))
        end
        tex:SetVertexColor(r, g, b, 1)
    end
    tex._wcGradient = (K.Get("general", "barStyle") == "gradient") or nil
end

-- 1-px-Rahmen um einen Frame, in vier Texturen. Liefert ein Objekt mit
-- SetColor/Show/Hide - Namensplakette und Einheitenrahmen teilen ihn.
function K.Border(frame, size, r, g, b, a, layer)
    size = size or 1
    local o = {}
    local function Edge()
        local t = frame:CreateTexture(nil, layer or "BORDER")
        t:SetColorTexture(r or 0, g or 0, b or 0, a or 1)
        return t
    end
    o.top, o.bottom, o.left, o.right = Edge(), Edge(), Edge(), Edge()
    function o:SetSize(s)
        self.top:ClearAllPoints()
        self.top:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", -s, 0)
        self.top:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", s, 0)
        self.top:SetHeight(s)
        self.bottom:ClearAllPoints()
        self.bottom:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", -s, 0)
        self.bottom:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", s, 0)
        self.bottom:SetHeight(s)
        self.left:ClearAllPoints()
        self.left:SetPoint("TOPRIGHT", frame, "TOPLEFT", 0, 0)
        self.left:SetPoint("BOTTOMRIGHT", frame, "BOTTOMLEFT", 0, 0)
        self.left:SetWidth(s)
        self.right:ClearAllPoints()
        self.right:SetPoint("TOPLEFT", frame, "TOPRIGHT", 0, 0)
        self.right:SetPoint("BOTTOMLEFT", frame, "BOTTOMRIGHT", 0, 0)
        self.right:SetWidth(s)
    end
    function o:SetColor(cr, cg, cb, ca)
        for _, t in ipairs({ self.top, self.bottom, self.left, self.right }) do
            t:SetColorTexture(cr, cg, cb, ca or 1)
        end
    end
    function o:SetShown(v)
        for _, t in ipairs({ self.top, self.bottom, self.left, self.right }) do
            if v then t:Show() else t:Hide() end
        end
    end
    o:SetSize(size)
    return o
end

--------------------------------------------------
-- Blizzard-Rahmen verstecken
--------------------------------------------------
-- Ein ersetzter Blizzard-Rahmen zieht in einen versteckten Rahmen um und
-- verliert seine Ereignisse - einmal, nie im Kampf. Der Bearbeitungsmodus
-- des Spiels haengt seine Rahmen gelegentlich selbst wieder ein; dann
-- eben noch einmal, nach dem Kampf. Zurueck bekommt man ihn mit einem
-- Neuladen, nachdem das Modul abgeschaltet wurde.
--
-- keepEvents: nur verstecken, Ereignisse behalten (fuer Rahmen, deren
-- Ereignisse andere Teile des Spiels mitbenutzen).
--------------------------------------------------

local hiddenParent = CreateFrame("Frame")
hiddenParent:Hide()
K.hiddenParent = hiddenParent
local hookedParents = {}

function K.HideBlizzard(frame, keepEvents)
    if type(frame) == "string" then frame = _G[frame] end
    if type(frame) ~= "table" then return end
    if frame.IsForbidden and frame:IsForbidden() then return end
    K.AfterCombat(function()
        if not keepEvents and frame.UnregisterAllEvents then frame:UnregisterAllEvents() end
        frame:Hide()
        frame:SetParent(hiddenParent)
    end)
    if not hookedParents[frame] and _G.hooksecurefunc then
        hookedParents[frame] = true
        _G.hooksecurefunc(frame, "SetParent", function(self, parent)
            if parent ~= hiddenParent then
                K.AfterCombat(function() self:SetParent(hiddenParent) end)
            end
        end)
    end
end

--------------------------------------------------
-- Verschieben ("Rahmen entsperren")
--------------------------------------------------
-- Das Gegenstueck zum Entsperrmodus der Vorlage, auf das Noetige
-- reduziert: jeder bewegliche Rahmen bekommt eine Flaeche mit seinem
-- Namen, die sich ziehen laesst. Rechtsklick setzt ihn zurueck.
--
-- Geschuetzte Rahmen (Einheitenrahmen) lassen sich im Kampf nicht
-- bewegen - das Entsperren wird dann verweigert, nicht halb ausgefuehrt.
--------------------------------------------------

local movers = {}
local unlocked = false
local selected           -- Schluessel des angewaehlten Rahmens (Gestaltungsmodus)
K.movers = movers

-- Einrasten (ui/editmode.lua setzt es): nach dem Ziehen die linke untere
-- Ecke aufs Raster, die Mitte auf die Mittelachse, wenn sie nahe ist.
-- Liefert die Verschiebung dx, dy in Einheiten von UIParent.
K.SnapOffset = nil

local function SavePosition(key, frame)
    local ui = Root()
    if not ui then return end
    local point, _, relPoint, x, y = frame:GetPoint(1)
    if not point then return end
    ui.positions[key] = {
        point = point, relPoint = relPoint or point,
        x = math.floor((x or 0) + 0.5), y = math.floor((y or 0) + 0.5),
    }
end

function K.ApplyPosition(key)
    local m = movers[key]
    if not m then return end
    local ui = Root()
    local pos = ui and ui.positions[key] or m.default
    local frame = m.frame
    local function apply()
        frame:ClearAllPoints()
        frame:SetPoint(pos.point, UIParent, pos.relPoint or pos.point, pos.x or 0, pos.y or 0)
    end
    if m.secure then K.AfterCombat(apply) else apply() end
end

function K.RegisterMover(frame, key, label, default, opts)
    opts = opts or {}
    local m = movers[key] or {}
    m.frame, m.label, m.default = frame, label, default
    m.secure = opts.secure and true or false
    movers[key] = m

    if not m.overlay then
        local ov = CreateFrame("Button", nil, UIParent)
        ov:SetFrameStrata("DIALOG")
        ov:SetAllPoints(frame)
        ov:EnableMouse(true)
        ov:RegisterForDrag("LeftButton")
        if ov.RegisterForClicks then ov:RegisterForClicks("RightButtonUp") end
        local bg = ov:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(ov)
        bg:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.22)
        ov.bg = bg
        ov.edge = K.Border(ov, 1, C.accent[1], C.accent[2], C.accent[3], 0.9, "ARTWORK")
        local t = K.NewText(ov, 11)
        t:SetFont(F.sansSemi, 11, "OUTLINE")
        t:SetPoint("CENTER", ov, "CENTER", 0, 0)
        t:SetTextColor(unpack(C.textBright))
        t:SetText(label)
        ov:SetScript("OnDragStart", function()
            if m.secure and K.InCombat() then return end
            frame:SetMovable(true)
            frame:StartMoving()
        end)
        ov:SetScript("OnDragStop", function()
            frame:StopMovingOrSizing()
            SavePosition(key, frame)
            -- Einrasten: die gespeicherte Stelle um den Rest zum Raster bzw.
            -- zur Mittelachse verschieben (derselbe Anker, nur genauer).
            local ui = Root()
            local pos = ui and ui.positions[key]
            if pos and K.SnapOffset then
                local ok, dx, dy = pcall(K.SnapOffset, frame)
                if ok and type(dx) == "number" and type(dy) == "number" then
                    pos.x = math.floor(pos.x + dx + 0.5)
                    pos.y = math.floor(pos.y + dy + 0.5)
                end
            end
            -- StartMoving haengt den Rahmen an den naechstgelegenen Punkt
            -- des Bildschirms um; gespeichert ist er jetzt, und neu
            -- angelegt wird er aus dem Gespeicherten.
            K.ApplyPosition(key)
            K.SelectMover(key)
        end)
        ov:SetScript("OnMouseDown", function(_, button)
            if button == "LeftButton" then K.SelectMover(key) end
        end)
        if ov.SetScript then
            ov:SetScript("OnDoubleClick", function() K.Fire("moverOpen", key) end)
        end
        ov:SetScript("OnClick", function(_, button)
            if button ~= "RightButton" then return end
            local ui = Root()
            if ui then ui.positions[key] = nil end
            K.ApplyPosition(key)
        end)
        ov:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(label, 1, 1, 1)
            GameTooltip:AddLine("Ziehen verschiebt, Pfeiltasten schieben genau (Umschalt: 8). Doppelklick: Einstellungen. Rechtsklick: zurück an den Standardplatz.", 0.7, 0.7, 0.75, true)
            GameTooltip:Show()
        end)
        ov:SetScript("OnLeave", function() GameTooltip:Hide() end)
        ov:Hide()
        m.overlay = ov
    end

    m.enabled = true
    K.ApplyPosition(key)
    if unlocked then m.overlay:Show() end
end

-- Ein Rahmen, dessen Modul aus ist, soll im Entsperrmodus nicht als
-- leere Flaeche herumstehen.
function K.SetMoverEnabled(key, on)
    local m = movers[key]
    if not m then return end
    m.enabled = on and true or false
    if unlocked and m.enabled then m.overlay:Show() else m.overlay:Hide() end
end

-- Angewaehlt: heller Grund, weisser Rand. Genau einer.
local function PaintMover(key)
    local m = movers[key]
    local ov = m and m.overlay
    if not (ov and ov.bg) then return end
    local on = (key == selected)
    local a = C.accent
    ov.bg:SetColorTexture(a[1], a[2], a[3], on and 0.4 or 0.22)
    if on then ov.edge:SetColor(1, 1, 1, 1) else ov.edge:SetColor(a[1], a[2], a[3], 0.9) end
end

function K.SelectMover(key)
    local old = selected
    selected = key
    if old then PaintMover(old) end
    if key then PaintMover(key) end
    K.Fire("moverSelect", key)
end

function K.SelectedMover() return selected end

-- Den angewaehlten Rahmen um dx, dy verschieben (Pfeiltasten).
function K.NudgeMover(dx, dy)
    local m = selected and movers[selected]
    if not m or (m.secure and K.InCombat()) then return false end
    local ui = Root()
    if not ui then return false end
    local cur = ui.positions[selected] or m.default
    ui.positions[selected] = { point = cur.point, relPoint = cur.relPoint or cur.point,
        x = (cur.x or 0) + dx, y = (cur.y or 0) + dy }
    K.ApplyPosition(selected)
    K.Fire("moverSelect", selected)
    return true
end

-- Wo der Rahmen gerade steht, fuer die Anzeige im Gestaltungsmodus.
function K.MoverPosition(key)
    local m = movers[key]
    if not m then return nil end
    local ui = Root()
    return (ui and ui.positions[key]) or m.default, m.label
end

function K.IsUnlocked() return unlocked end

function K.SetUnlocked(on)
    if on and K.InCombat() then
        print(WeintCodex.ColorText("accent", "[WeintCodex]")
            .. " Im Kampf lassen sich Rahmen nicht verschieben.")
        return false
    end
    unlocked = on and true or false
    if not unlocked then K.SelectMover(nil) end
    for _, m in pairs(movers) do
        if unlocked and m.enabled then
            -- Ein Rahmen, der gerade nichts zeigt (kein Ziel, keine Quest),
            -- hat trotzdem einen Platz - den soll man sehen koennen.
            if m.frame.WCShowForUnlock then m.frame:WCShowForUnlock(true) end
            m.overlay:Show()
        else
            if m.frame.WCShowForUnlock then m.frame:WCShowForUnlock(false) end
            m.overlay:Hide()
        end
    end
    K.Fire("unlock", unlocked)
    return true
end

function K.ResetAllPositions()
    local ui = Root()
    if not ui then return end
    wipe(ui.positions)
    for key in pairs(movers) do K.ApplyPosition(key) end
end

--------------------------------------------------
-- Neu laden per Knopf
--------------------------------------------------
-- Neuladen ist auf Forever geschuetzt; der Knopf fuehrt "/reload" als
-- Makro aus, ausgeloest vom Klick selbst. Die Begruendung steht bei
-- WeintCodex.AttachReload in core/ui.lua - hier nur die Form, die das
-- Oberflaechenpaket braucht.
--
-- opts: wie WeintCodex.CreateButton (text, kind, height, size,
--       backdrop, tooltip), dazu onClick = was VOR dem Neuladen noch
--       geschehen soll.
--------------------------------------------------

function K.ReloadButton(parent, opts)
    opts = opts or {}
    local b = WeintCodex.CreateButton(parent, {
        text = opts.text or "Jetzt neu laden", kind = opts.kind or "primary",
        height = opts.height, size = opts.size, backdrop = opts.backdrop,
        tooltip = opts.tooltip,
    })
    WeintCodex.AttachReload(b, opts.onClick)
    return b
end

--------------------------------------------------
-- Nachsehen: was ist dieser Rahmen?
--------------------------------------------------
-- Im Beta-Client heissen Rahmen oft anders, als WeintCodex annimmt
-- (Tageszeit auf der Minikarte: drei Fassungen lang nicht gefunden).
-- K.Describe beschreibt einen Rahmen in einer Zeile, K.InspectMouse alle
-- Rahmen unter der Maus samt Elternkette und Ankern (/wcui maus). Alles
-- in pcall: auch geschuetzte oder geheime Rahmen duerfen hier nichts
-- ausloesen.
--------------------------------------------------

local function Num(v)
    v = K.Plain(v)
    return type(v) == "number" and string.format("%.2f", v) or tostring(v)
end

local function NameOf(f)
    if type(f) ~= "table" then return "keiner" end
    local ok, n = pcall(function()
        return (f.GetDebugName and f:GetDebugName()) or (f.GetName and f:GetName())
    end)
    if ok and type(n) == "string" and n ~= "" then return n end
    return "(ohne Namen)"
end
K.NameOf = NameOf

function K.Describe(f)
    if type(f) ~= "table" then return "fehlt" end
    local ok, out = pcall(function()
        local parent = f.GetParent and f:GetParent()
        local pname = parent and NameOf(parent) or "keiner"
        local ea = f.GetEffectiveAlpha and f:GetEffectiveAlpha()
        return string.format("gezeigt %s, sichtbar %s, Alpha %s (wirksam %s), %s/%s, links %s oben %s, Eltern %s",
            tostring(K.Bool(f:IsShown(), false)), tostring(K.Bool(f:IsVisible(), false)),
            Num(f:GetAlpha()), Num(ea), tostring(f.GetFrameStrata and f:GetFrameStrata()),
            Num(f.GetFrameLevel and f:GetFrameLevel()), Num(f.GetLeft and f:GetLeft()), Num(f.GetTop and f:GetTop()), pname)
    end)
    return ok and out or ("nicht lesbar: " .. tostring(out))
end

local function Anchors(f)
    local ok, out = pcall(function()
        local n = f.GetNumPoints and K.Plain(f:GetNumPoints())
        if type(n) ~= "number" or n < 1 then return "keine Anker" end
        local parts = {}
        for i = 1, math.min(n, 4) do
            local p, rel, rp, x, y = f:GetPoint(i)
            parts[#parts + 1] = string.format("%s an %s %s (%s, %s)", tostring(p), NameOf(rel), tostring(rp), Num(x), Num(y))
        end
        return table.concat(parts, "; ")
    end)
    return ok and out or "Anker nicht lesbar"
end

function K.InspectMouse()
    local foci = {}
    if type(_G.GetMouseFoci) == "function" then
        local ok, t = pcall(_G.GetMouseFoci)
        if ok and type(t) == "table" then foci = t end
    elseif type(_G.GetMouseFocus) == "function" then
        local ok, f = pcall(_G.GetMouseFocus)
        if ok and type(f) == "table" then foci = { f } end
    end
    local out = {}
    for _, f in ipairs(foci) do
        if #out >= 12 then break end
        if type(f) == "table" and not (f.IsForbidden and f:IsForbidden()) then
            local chain, p = {}, f.GetParent and f:GetParent()
            for _ = 1, 5 do
                if type(p) ~= "table" then break end
                chain[#chain + 1] = NameOf(p)
                p = p.GetParent and p:GetParent()
            end
            local kind = f.GetObjectType and f:GetObjectType()
            out[#out + 1] = NameOf(f) .. " (" .. tostring(kind) .. "): " .. K.Describe(f)
            out[#out + 1] = "   Eltern: " .. (#chain > 0 and table.concat(chain, " < ") or "keine")
                .. " · Anker: " .. Anchors(f)
        end
    end
    -- Was keine Maus annimmt (Texturen, Rahmen ohne Mausklick), steht nicht
    -- in GetMouseFoci - die Tageszeit-Sonne im Beta-Test meldete dort nur
    -- "Minimap". Deshalb alle sichtbaren Rahmen und ihre Texturen, die die
    -- Mausposition ueberdecken, die kleinsten zuerst.
    local hits = K.UnderCursor()
    if #hits > 0 then
        out[#out + 1] = "Alles unter der Maus, das Kleinste zuerst:"
        for i = 1, math.min(#hits, 10) do out[#out + 1] = "   " .. hits[i].line end
    end
    if #out == 0 then
        out[1] = "Unter der Maus liegt kein Rahmen. Maus über das Ding halten und den Befehl mit Enter abschicken."
    end
    return out
end

-- Liegt die Mausposition in der Flaeche von r? Koordinaten von Rahmen und
-- Texturen stehen in ihrer wirksamen Skalierung, die Maus in Bildpunkten.
local function Covers(r, cx, cy, scale)
    local ok, hit, area = pcall(function()
        local s = K.Plain(r.GetEffectiveScale and r:GetEffectiveScale())
        if type(s) ~= "number" or s <= 0 then s = scale end
        local l, rt = K.Plain(r:GetLeft()), K.Plain(r:GetRight())
        local t, b = K.Plain(r:GetTop()), K.Plain(r:GetBottom())
        if type(l) ~= "number" or type(rt) ~= "number" or type(t) ~= "number" or type(b) ~= "number" then
            return false, 0
        end
        local x, y = cx / s, cy / s
        return x >= l and x <= rt and y >= b and y <= t, (rt - l) * (t - b)
    end)
    return ok and hit or false, ok and area or 0
end

local function TextureOf(r)
    local ok, v = pcall(function()
        local atlas = r.GetAtlas and r:GetAtlas()
        if type(atlas) == "string" and atlas ~= "" then return "Atlas " .. atlas end
        local tex = r.GetTexture and r:GetTexture()
        if type(tex) == "string" or type(tex) == "number" then return "Bild " .. tostring(tex) end
        return nil
    end)
    return ok and v or nil
end

function K.UnderCursor()
    local hits = {}
    if type(_G.EnumerateFrames) ~= "function" or type(_G.GetCursorPosition) ~= "function" then return hits end
    local cx, cy = _G.GetCursorPosition()
    cx, cy = K.Plain(cx), K.Plain(cy)
    if type(cx) ~= "number" or type(cy) ~= "number" then return hits end
    local skip = { [_G.UIParent or false] = true, [_G.WorldFrame or false] = true }
    local f = _G.EnumerateFrames()
    local guard = 0
    while f and guard < 50000 do
        guard = guard + 1
        local ok, usable = pcall(function()
            return not skip[f] and not (f.IsForbidden and f:IsForbidden()) and K.Bool(f:IsVisible(), false)
        end)
        if ok and usable then
            local scale = K.Plain(f.GetEffectiveScale and f:GetEffectiveScale())
            if type(scale) ~= "number" or scale <= 0 then scale = 1 end
            local hit, area = Covers(f, cx, cy, scale)
            if hit then
                local kind = f.GetObjectType and f:GetObjectType()
                hits[#hits + 1] = { area = area, line = string.format("%s (%s, %s/%s, Maus %s)",
                    NameOf(f), tostring(kind), tostring(f.GetFrameStrata and f:GetFrameStrata()),
                    Num(f.GetFrameLevel and f:GetFrameLevel()),
                    tostring(K.Bool(f.IsMouseEnabled and f:IsMouseEnabled(), false))) }
                local rok, regions = pcall(function() return { f:GetRegions() } end)
                for _, r in ipairs(rok and regions or {}) do
                    local vok, vis = pcall(function()
                        return r:GetObjectType() == "Texture" and K.Bool(r:IsVisible(), false)
                    end)
                    if vok and vis then
                        local rhit, rarea = Covers(r, cx, cy, scale)
                        local tex = TextureOf(r)
                        if rhit and tex then
                            local rname = NameOf(r)
                            if rname == "(ohne Namen)" then rname = "Textur in " .. NameOf(f) end
                            hits[#hits + 1] = { area = rarea, line = rname .. ": " .. tex }
                        end
                    end
                end
            end
        end
        local nok, nxt = pcall(_G.EnumerateFrames, f)
        f = nok and nxt or nil
    end
    table.sort(hits, function(a, b) return a.area < b.area end)
    return hits
end

--------------------------------------------------
-- Einmal-Ereignisse
--------------------------------------------------
-- PLAYER_LOGIN: SavedData stehen seit ADDON_LOADED (core/main.lua); die
-- Einheiten gibt es erst jetzt. Hier werden die Module gestartet.
--------------------------------------------------

local boot = CreateFrame("Frame")
boot:RegisterEvent("PLAYER_LOGIN")
boot:RegisterEvent("PLAYER_REGEN_ENABLED")
boot:RegisterEvent("PLAYER_REGEN_DISABLED")
boot:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_REGEN_DISABLED" then
        -- Entsperrt in den Kampf: die Flaechen verschwinden, statt einen
        -- geschuetzten Rahmen halb gezogen stehen zu lassen.
        if unlocked then K.SetUnlocked(false) end
        return
    end
    if event == "PLAYER_REGEN_ENABLED" then
        local queue = afterCombat
        afterCombat = {}
        for _, fn in ipairs(queue) do
            local ok, err = pcall(fn)
            if not ok then K.Report("kampf", err) end
        end
        return
    end

    -- PLAYER_LOGIN
    for _, key in ipairs(order) do
        if K.WantsActive(key) then K.Activate(key) end
    end
end)
