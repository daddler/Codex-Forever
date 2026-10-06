--------------------------------------------------
-- WeintCodex :: Oberflaeche - Namensplaketten
--------------------------------------------------
-- Eigene Plaketten fuer Gegner - und seit 6.0.0.3 fuer Freunde (nur der
-- Name in Klassenfarbe, wahlweise mit Balken). In Instanzen sind
-- freundliche Plaketten fuer Addons gesperrt ("forbidden"); dort bleiben
-- die des Spiels. Das ist der eine Ort, an dem die Plakette je nach Ort
-- anders aussieht, und die Einstellungsseite sagt es.
--
-- Auren ueber gegnerischen Plaketten kommen aus ui/auras.lua (Auren-
-- Container des Spiels, wo es ihn gibt).
--
-- WIE. Die Plakette ist ein eigener Rahmen, der an der Blizzard-Plakette
-- haengt (SetParent: Abstandsskalierung und Sichtbarkeit erbt er so
-- mit). Der Blizzard-Inhalt wird unsichtbar gestellt und von seinen
-- Ereignissen getrennt - er bleibt aber, wo er ist: der Klick auf eine
-- Plakette waehlt im Client das Ziel ueber den Blizzard-Rahmen aus, und
-- den darf man nicht wegnehmen. Das Verfahren folgt der Vorlage
-- (EllesmereUI); der Code ist eigener.
--
-- WAS DER CLIENT VERSCHWEIGT. Ab 12.0 sind Lebenspunkte, Stufe und
-- manches mehr im Kampf "secret" (siehe ui/kit.lua). Balken und Texte
-- bekommen die Werte durchgereicht, verglichen wird nur, was nicht
-- geheim ist. Eine Stufe, die der Client nicht nennt, steht als "??" da -
-- nie als 0.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UINameplates = {}

local NP = WeintCodex.UINameplates
local K  = WeintCodex.UIKit
local CB = WeintCodex.UICastBar
local KEY = "nameplates"

--------------------------------------------------
-- Voreinstellungen (Zahlen nach EllesmereUI 9.2.6, Forever-Zweig)
--------------------------------------------------

-- Seit 6.1.0.0 (UI 2.0, docs/design/ui-2.0.md): 150 x 14, Tiefe ueber
-- einen weichen Schatten statt eines harten Rahmens, Grund im dunklen Ton
-- der Gegnerfarbe. Das Ziel bekommt Leuchten und Zielmarken, die Maus
-- hellt eine Plakette auf (wie Plater), und mit Ziel treten die anderen
-- auf 70 % zurueck.
local defaults = {
    width  = 150,
    height = 14,
    targetScale    = 110,      -- Prozent
    nonTargetAlpha = 70,       -- Prozent; 100 = nichts abblenden
    showBorder  = true,
    borderColor = K.ColorDefault("plateBorder"),
    bgColor     = K.ColorDefault("plateBg"),
    tintedBg    = true,        -- Grund im dunklen Ton der Balkenfarbe
    shadow      = true,        -- weicher Schatten unter dem Balken
    targetStyle = "glow",      -- glow | ring | both | none
    hover       = true,        -- Maus darueber hellt auf
    executeMark = false,       -- fester Strich bei executeAt % im Balken
    executeAt   = 20,
    -- Bewegung (6.8.1.0, Beta-Test: "es fehlt noch etwas Cooles, ein
    -- Wow-Effekt"; Entwurf "Namensplaketten 3.0", Variante B + C).
    damageTrail = true,        -- Schadensspur: was ein Treffer nahm, bleibt kurz hell stehen
    smoothBars  = true,        -- Leben gleitet (wenn der Client es kann)
    targetPulse = true,        -- Leuchten des Ziels atmet
    targetEdge  = true,        -- feine Kante in der Klassenfarbe am Ziel
    targetSheen = true,        -- Glanz laeuft alle paar Sekunden ueber den Balken des Ziels
    hitFlash    = true,        -- Treffer am Ziel blitzt kurz auf
    markMotion  = true,        -- Zielmarken atmen nach aussen
    -- 6.10.0.0 (Selbsteinschaetzung: "Ruhige Oberflaeche und Wow-Effekt
    -- beissen sich - fuenfzehn Gegner mit atmendem Ziel, Glanz, Marken und
    -- Blitzen ist viel Bewegung"): eine Stufe ueber den vier lauten
    -- Bewegungen. calm = alle vier aus (Standard), lively = alle an,
    -- custom = die Schalter einzeln. Schadensspur, weiche Balken und Kante
    -- bleiben eigene Schalter - sie sagen etwas und sind leise.
    motion      = "calm",      -- calm | lively | custom

    enemyInCombat = K.ColorDefault("enemyInCombat"),
    hostile       = K.ColorDefault("hostile"),
    darkenOOC     = true,      -- Vorlage: darkenEnemiesOOC = true
    neutral       = K.ColorDefault("neutral"),
    tapped        = K.ColorDefault("tapped"),
    boss          = K.ColorDefault("boss"),
    elite         = K.ColorDefault("elite"),
    eliteColoring = true,
    -- 6.6.2.2: Zaubernde eigens (ui/npccolors.lua) - wer unterbrochen
    -- werden will, soll auffallen.
    casterColoring = true,
    caster         = K.ColorDefault("caster"),
    focusColorEnabled  = true,  -- Vorlage: true
    focus              = K.ColorDefault("focus"),
    targetColorEnabled = false, -- Vorlage: false
    target             = K.ColorDefault("target"),
    classColorPlayers  = true,
    -- 6.10.3.3: ab Werk an (Beta-Test: "farblich erkennen"). Allein ohne
    -- Begleiter faerbt nichts (NP.Contested).
    threatColors = true,
    -- Eigene Bedrohung in Prozent an der Plakette (Beta-Test 6.3.2.5:
    -- "wie viel Threat ich gerade habe"). none | topleft | right. Rechts:
    -- oben links kollidiert mit langen Namen und den Symbolen des Spiels.
    threatText = "right",
    -- 6.9.0.8: Bedrohung als Leiste unter dem Leben und wer die Aggro hat.
    -- aggroName: problem (nur wenn sie nicht beim Tank liegt) | always | none.
    threatBar  = true,
    threatBarHeight = 3,
    aggroName  = "problem",
    tankAggro  = K.ColorDefault("tankAggro"),
    tankLosing = K.ColorDefault("tankLosing"),
    dpsAggro   = K.ColorDefault("dpsAggro"),
    dpsNear    = K.ColorDefault("dpsNear"),
    -- 6.10.3.4 (Beta-Test: "die Bedrohungsleiste in den Einstellungen
    -- einstellen - Farbe, Prozent etc."): was bis dahin fest war.
    threatLow  = K.ColorDefault("threatLow"),  -- Leiste: weit weg
    threatWarn = 80,       -- ab hier "kurz davor" (DD) bzw. "der Naechste ist nah" (Tank)
    threatSolo = false,    -- auch allein ohne Begleiter (dann immer 100 %)
    tankLead   = true,     -- als Tank den Naechsten zeigen statt der eigenen

    -- Textplaetze. Auf Forever steht links die Stufe (Vorlage:
    -- textSlotLeft = "level" nur auf Forever) - in einer Welt mit
    -- Stufenunterschieden ist sie die wichtigste Zahl auf der Plakette.
    textTop    = "name",
    textLeft   = "level",
    textRight  = "healthPercent",
    textCenter = "none",
    nameSize = 12,
    textSize = 10,
    levelColor = true,
    eliteMark  = true,
    raidMarker = "topright",
    raidMarkerSize = 20,

    castEnabled = true,
    castHeight  = 14,
    castIcon    = true,
    castTimer   = true,
    castTarget  = true,        -- auf wen der Zauber geht, rechts im Balken
    castShield  = true,
    castColor   = K.ColorDefault("cast"),
    castLocked  = K.ColorDefault("castLocked"),

    -- Auren ueber der Plakette (Vorlage: debuffSlot "top", Symbol 26,
    -- maxDebuffs 5). Von Haus aus nur die eigenen - auf einer Plakette,
    -- die zwanzig Spieler gleichzeitig bearbeiten, waeren alle Debuffs
    -- ein Muster, keine Auskunft.
    auraEnabled = true,
    -- Woher die Symbole kommen. "game": die Debuff-Symbole der Plakette des
    -- Spiels an ihrem Platz, der Rest der Spielplakette ausgeblendet (seit
    -- 6.3.0.1; vorher umgehaengt) - das Spiel pflegt sie selbst, auch mit
    -- geheimen Werten. "own": die eigenen Symbole
    -- (ui/auras.lua). Seit 6.3.0.0 ist "game" der Standard: mit den
    -- eigenen erschienen im Beta-Client in drei Fassungen keine Debuffs.
    auraSource = "game",
    gameAuraScale = 100,
    auraOnlyMine = true,
    auraSize = 22,
    auraMax = 5,
    auraTimer = true,          -- Restzeit oben links am Symbol
    -- Ausrichtung der Debuffs ueber der Plakette (Beta-Test 6.3.1.8:
    -- "mittig, rechts, links - Stand jetzt nur links").
    auraAlign = "left",        -- left | center | right

    -- Questfortschritt links vom Namen ("8/10"), wenn der Gegner zu einer
    -- deiner Quests gehoert - aus dem Tooltip des Spiels, nur draussen.
    questProgress = true,

    -- Freundliche Plaketten: nur der Name, in Klassenfarbe (Vorlage:
    -- friendlyNameOnly = true, classColorFriendly = true). In Instanzen
    -- gesperrt das Spiel sie fuer Addons - dort bleiben die des Spiels.
    friendlyEnabled = true,
    friendlyHealth = false,
    friendlyClassColor = true,
    friendlyNameSize = 12,
    friendlyColor = K.ColorDefault("friendly"),
}

local S = {}   -- aufgeloeste Einstellungen, neu gelesen bei jeder Aenderung
-- Die vier lauten Bewegungen, die die Stufe (motion) schaltet.
NP.MOTION_KEYS = { "targetPulse", "targetSheen", "hitFlash", "markMotion" }
local function Resolve()
    for k in pairs(defaults) do S[k] = K.Get(KEY, k) end
    -- Die Stufe gilt, ohne die eigenen Schalter zu ueberschreiben: wer auf
    -- "Eigene" zurueckwechselt, findet seine Wahl wieder.
    if S.motion ~= "custom" then
        local on = (S.motion == "lively")
        for _, k in ipairs(NP.MOTION_KEYS) do S[k] = on end
    end
end
NP.Resolved = function(k) return S[k] end

-- UEBERNAHME (6.10.1.0, Selbsteinschaetzung: "wer sich eine Mischung
-- eingestellt hatte, verliert sie stillschweigend"). Bis 6.9 waren die vier
-- Bewegungen einzeln an; gespeichert ist nur, was vom Standard abweicht -
-- also nur ein `false`. Liegt ohne gespeicherte Stufe eine MISCHUNG vor
-- (manche aus, nicht alle), war das eine bewusste Wahl: sie wird "Eigene".
-- Alle vier aus ist "Ruhig" und bleibt es; nichts gespeichert hiess
-- "alles an" als Standard - dort gilt der neue Standard (Changelog 6.10).
-- Einmal je Konto (ui.migrated.npMotion): wer in 6.10 selbst von "Eigene"
-- auf "Ruhig" zurueckgeht, wird nicht wieder umgestellt.
function NP.MigrateMotion()
    local ui = K.Root()
    if not ui then return nil end
    ui.migrated = ui.migrated or {}
    if ui.migrated.npMotion then return nil end
    ui.migrated.npMotion = true
    local prof = K.Profile()
    local store = prof and prof.modules[KEY]
    if type(store) ~= "table" or type(store.motion) ~= "nil" then return nil end
    local off = 0
    for _, k in ipairs(NP.MOTION_KEYS) do
        if store[k] == false then off = off + 1 end
    end
    if off == 0 or off == #NP.MOTION_KEYS then return nil end
    K.Set(KEY, "motion", "custom")
    return "custom"
end

--------------------------------------------------
-- Blizzard-Inhalt unsichtbar stellen
--------------------------------------------------

local hidden = CreateFrame("Frame")
hidden:Hide()
local parked = {}    -- [Blizzard-Aurenrahmen] = urspruenglicher Elternrahmen
local dimmed = {}    -- [Teil der Blizzard-Plakette] = seine Deckkraft vorher
local partsOf = {}   -- [Blizzard-Plakette] = { Teile, die WeintCodex ausgeblendet hat }
local inPlace = {}   -- [Blizzard-Aurenrahmen] = true, solange seine Symbole gelten
local dimHooked = {} -- [Teil] = true: Haken gesetzt (nie ein Feld am Blizzard-Rahmen)

local function AurasOf(uf)
    local auras = uf.AurasFrame
    if type(auras) ~= "table" then auras = uf.BuffFrame end
    if type(auras) ~= "table" or (auras.IsProtected and auras:IsProtected()) then return nil end
    return auras
end

-- Die Symbole des Spiels bleiben, wo das Spiel sie hinsetzt. 6.3.0.0 hat
-- sie an die WeintCodex-Plakette umgehaengt und sich dafuer ihre Anker
-- gemerkt - im Beta-Client ist das Auslesen verboten ("Can't measure
-- restricted regions"), und umgehaengt zeichnete der Rahmen einen weissen
-- Balken ueber den Namen. Jetzt bleibt die Plakette des Spiels sichtbar,
-- und WeintCodex blendet alles an ihr aus AUSSER den Symbolen. Kein Anker
-- wird gelesen oder gesetzt, kein Elternrahmen gewechselt.
local guard = false
local function Dim(part)
    if dimmed[part] then return end
    local a = K.Plain(part.GetAlpha and part:GetAlpha())
    dimmed[part] = type(a) == "number" and a or 1
    if not dimHooked[part] and _G.hooksecurefunc then
        dimHooked[part] = true
        -- Setzt das Spiel die Deckkraft zurueck, gilt der neue Wert fuer
        -- spaeter, sichtbar bleibt der Teil trotzdem nicht.
        _G.hooksecurefunc(part, "SetAlpha", function(self, v)
            if guard or not dimmed[self] then return end
            local plain = K.Plain(v)
            if type(plain) == "number" then dimmed[self] = plain end
            guard = true
            self:SetAlpha(0)
            guard = false
        end)
    end
    guard = true
    part:SetAlpha(0)
    guard = false
end

local function Undim(uf)
    local list = partsOf[uf]
    if not list then return end
    partsOf[uf] = nil
    for _, part in ipairs(list) do
        local a = dimmed[part]
        dimmed[part] = nil
        if a then
            guard = true
            part:SetAlpha(a)
            guard = false
        end
    end
end

-- Alle Teile der Blizzard-Plakette ausser den Symbolen. nil, wenn der
-- Client die Frage nicht beantwortet - dann bleibt es beim Ausblenden
-- der ganzen Plakette.
local function OtherParts(uf, auras)
    local ok, list = pcall(function()
        local out = {}
        for _, ch in ipairs({ uf:GetChildren() }) do
            if ch ~= auras and type(ch) == "table" and ch.SetAlpha then out[#out + 1] = ch end
        end
        for _, rg in ipairs({ uf:GetRegions() }) do
            if type(rg) == "table" and rg.SetAlpha then out[#out + 1] = rg end
        end
        return out
    end)
    if ok then return list end
    return nil
end

-- Ausrichtung der Symbole des Spiels (6.3.1.9). Links laesst sie, wo
-- das Spiel sie hinsetzt - kein Anker wird angefasst. Mitte und rechts
-- setzen die Debuff-Liste (DebuffListFrame, im 11.x-Client eine
-- Layout-Liste, die sich ihrem Inhalt anpasst) mittig bzw. rechts ueber
-- die WeintCodex-Plakette (seit 6.3.2.0, siehe unten). Gelesen wird nichts (GetPoint ist verboten),
-- nur gesetzt, in pcall. Ob die Liste auf Forever so heisst und mit dem
-- Inhalt waechst, ist nicht gemessen - /wcui auren nennt das Ergebnis.
local movedList = setmetatable({}, { __mode = "k" })
NP.gameAlign = "noch nicht versucht"
-- 6.3.2.0: an UNSERE Plakette, nicht an den Aurenrahmen des Spiels. An
-- dessen Unterkante gesetzt standen die Symbole im Beta-Test UNTER der
-- Plakette - der Rahmen reicht offenbar bis unter sie, und seine Masse
-- lassen sich nicht lesen. Unsere Plakette kennen wir: die Symbole
-- stehen ueber ihr, ueber dem Namen, wenn er oben steht.
local function AlignGameAuras(auras, p)
    local align = S.auraAlign or "left"
    local list = auras.DebuffListFrame
    if type(list) ~= "table" or not list.SetPoint or (list.IsProtected and list:IsProtected()) then
        if align ~= "left" then NP.gameAlign = "die Debuff-Liste des Spiels heißt hier anders" end
        return
    end
    if align == "left" and not movedList[list] then return end
    if type(p) ~= "table" then return end
    local pt = (align == "right" and "BOTTOMRIGHT") or (align == "center" and "BOTTOM") or "BOTTOMLEFT"
    local rel = (align == "right" and "TOPRIGHT") or (align == "center" and "TOP") or "TOPLEFT"
    -- Der Versatz gilt im Massstab der Liste (Groesse der Symbole des
    -- Spiels), gemeint ist er im Massstab der Plakette.
    local scale = (S.gameAuraScale or 100) / 100
    local y = ((S.textTop ~= "none" and S.nameSize or 0) + 6) / scale
    local ok, err = pcall(function()
        list:ClearAllPoints()
        list:SetPoint(pt, p, rel, 0, y)
    end)
    movedList[list] = true
    NP.gameAlign = ok and ("gesetzt: " .. pt) or ("vom Spiel abgelehnt: " .. tostring(err))
end

local function ShowGameAuras(uf, auras, p)
    local parts = OtherParts(uf, auras)
    if not parts then return false end
    Undim(uf)
    for _, part in ipairs(parts) do Dim(part) end
    partsOf[uf] = parts
    if parked[auras] then
        auras:SetParent(parked[auras])
        parked[auras] = nil
    end
    auras:SetScale((S.gameAuraScale or 100) / 100)
    auras:SetAlpha(1)
    auras:Show()
    AlignGameAuras(auras, p)
    uf:SetAlpha(1)
    inPlace[auras] = true
    return true
end

local function Suppress(nameplate, unit, p)
    local uf = nameplate and nameplate.UnitFrame
    if type(uf) ~= "table" then return end
    if uf.IsForbidden and uf:IsForbidden() then return end
    local auras = AurasOf(uf)
    local useGame = auras and p and not p._friendly and S.auraEnabled and S.auraSource == "game"
        and ShowGameAuras(uf, auras, p)
    if not useGame then
        Undim(uf)
        uf:SetAlpha(0)
        if auras then
            -- Die Auren der Blizzard-Plakette sind Knoepfe mit Tooltip: bei
            -- Alpha 0 waeren sie eine unsichtbare Tooltipfalle ueber jeder
            -- Plakette. Sie ziehen in einen versteckten Rahmen um.
            inPlace[auras] = nil
            parked[auras] = parked[auras] or auras:GetParent()
            auras:SetParent(hidden)
        end
    end
    -- Die Blizzard-Plakette arbeitet sonst unsichtbar weiter, bei jedem
    -- Treffer. Der Client meldet sie beim naechsten Zuweisen einer
    -- Einheit (CompactUnitFrame_SetUnit) von selbst wieder an.
    uf:UnregisterAllEvents()
    -- Nur die Auren bleiben ihr - wenn ihre Symbole hier gebraucht werden.
    if useGame and unit then
        if not pcall(uf.RegisterUnitEvent, uf, "UNIT_AURA", unit) then pcall(uf.RegisterEvent, uf, "UNIT_AURA") end
    end
    local cast = uf.castBar
    if type(cast) ~= "table" then cast = uf.CastBar end
    if type(cast) == "table" and cast.UnregisterAllEvents then cast:UnregisterAllEvents() end
end

local function Restore(nameplate)
    local uf = nameplate and nameplate.UnitFrame
    if type(uf) ~= "table" then return end
    if uf.IsForbidden and uf:IsForbidden() then return end
    Undim(uf)
    local auras = AurasOf(uf)
    if auras then
        inPlace[auras] = nil
        if parked[auras] then
            auras:SetParent(parked[auras])
            parked[auras] = nil
        end
        auras:SetScale(1)
    end
    uf:SetAlpha(1)
end

-- Fuer /wcui auren: wie viele Symbole des Spiels haengen an der Plakette?
function NP.GameAuraInfo(unit)
    local p = NP.plates and NP.plates[unit]
    if not p or not p.nameplate or not p.nameplate.UnitFrame then return nil end
    local auras = AurasOf(p.nameplate.UnitFrame)
    if not auras then return "die Plakette des Spiels hat keinen Aurenrahmen" end
    local shown = 0
    local function Walk(f, depth)
        if depth > 4 or not f.GetChildren then return end
        for _, ch in ipairs({ f:GetChildren() }) do
            if not (ch.IsForbidden and ch:IsForbidden()) then
                local ok, vis = pcall(ch.IsVisible, ch)
                if ok and K.Bool(vis, false) and ch.GetObjectType and ch:GetObjectType() ~= "Frame" then shown = shown + 1 end
                Walk(ch, depth + 1)
            end
        end
    end
    pcall(Walk, auras, 1)
    return string.format("Symbole des Spiels: %s, %d sichtbare Knöpfe · Ausrichtung %s · Markierung %s",
        inPlace[auras] and "sichtbar an ihrem Platz" or "ausgeblendet", shown, NP.gameAlign, NP.raidInfo)
end

--------------------------------------------------
-- Aufbau einer Plakette
--------------------------------------------------

local pool, plates = {}, {}
-- [Plakette des Spiels] = Einheit, der unsere Plakette dort gehoert.
local byPlate = {}
NP.plates = plates

local SLOTS = { "top", "left", "right", "center" }

--------------------------------------------------
-- Bewegung (6.8.1.0): Schadensspur, weiche Balken, das Ziel lebt
--------------------------------------------------
-- Alles, was sich bewegt, ist eine Animation des Spiels (AnimationGroup)
-- oder ein Wert, den der Balken selbst gleiten laesst - kein Lua je Bild.
-- Einziger Takt: die Schadensspur wartet NP.TRAIL_DELAY s, dann ein
-- SetValue; der Takt laeuft nur, solange eine Spur wartet. Keine Closure,
-- keine Tabelle je Treffer.

NP.TRAIL_DELAY = 0.35      -- so lange bleibt, was ein Treffer nahm, hell stehen
NP.SHEEN_W     = 36        -- Breite des Glanzes in px
NP.SHEEN_RUN   = 0.9       -- s fuer einen Lauf ueber den Balken ...
NP.SHEEN_PAUSE = 3.6       -- ... dann so lange Ruhe
NP.MARK_SWAY   = 3         -- px, um die die Zielmarken nach aussen atmen
NP.MARK_BREATH = 0.8       -- s je Richtung
NP.PULSE_LOW   = 0.45      -- Leuchten des Ziels atmet zwischen 100 % und diesem Wert
NP.PULSE_HALF  = 1.2       -- s je Richtung

-- Eine Animation an `region` (ein Rahmen oder eine Textur). setup(a, ag)
-- stellt sie ein. nil, wenn der Client keine Animationen anbietet.
function NP.Anim(region, kind, setup, looping)
    if type(region) ~= "table" or type(region.CreateAnimationGroup) ~= "function" then return nil end
    local ok, ag = pcall(region.CreateAnimationGroup, region)
    if not ok or type(ag) ~= "table" or type(ag.CreateAnimation) ~= "function" then return nil end
    local a = ag:CreateAnimation(kind)
    if type(a) ~= "table" then return nil end
    pcall(setup, a, ag)
    if looping and ag.SetLooping then ag:SetLooping(looping) end
    return ag
end

local function Run(ag, on)
    if not ag then return end
    if on then ag:Play() else ag:Stop() end
end

-- Gleiten: neuere Clients lassen einen Balken selbst zum neuen Wert laufen
-- (SetValue mit Enum.StatusBarInterpolation) - auch mit geheimem Wert.
-- Ungemessen fuer Forever: fehlt es oder lehnt der Client ab, springt der
-- Balken wie bisher (NP.smoothBroken), die Spur wirkt trotzdem.
function NP.Interp()
    if NP.smoothBroken then return nil end
    local E = _G.Enum
    local I = E and E.StatusBarInterpolation
    return I and I.ExponentialEaseOut or nil
end

function NP.SetBar(bar, value, smooth)
    if smooth and S.smoothBars then
        local interp = NP.Interp()
        if interp then
            if pcall(bar.SetValue, bar, value, interp) then return end
            NP.smoothBroken = true
        end
    end
    bar:SetValue(value)
end

-- Schadensspur: der erste Treffer startet die Uhr, weitere schreiben nur
-- den neuesten Wert. So schmilzt die Spur auch in einem langen Kampf
-- immer wieder, statt zu warten, bis keiner mehr trifft.
NP.trailPending = {}
local pending = NP.trailPending
local trailDriver = CreateFrame("Frame")
local function Now() return K.Plain(_G.GetTime and _G.GetTime()) or 0 end
local TrailTick
TrailTick = K.Measured("Plaketten", function()
    local now = Now()
    for p in pairs(pending) do
        if now >= (p._trailAt or 0) then
            NP.SetBar(p.trail, p._trailVal, true)
            pending[p] = nil
        end
    end
    if _G.next(pending) == nil then trailDriver:SetScript("OnUpdate", nil) end
end)
NP.TrailTick = TrailTick

function NP.Trail(p, cur, snap)
    if snap or not S.damageTrail then
        pending[p] = nil
        p.trail:SetValue(cur)
        return
    end
    p._trailVal = cur
    if not pending[p] then
        p._trailAt = Now() + NP.TRAIL_DELAY
        pending[p] = true
        trailDriver:SetScript("OnUpdate", TrailTick)
    end
end

-- Ziel: Leuchten atmet, Glanz, Kante in der Klassenfarbe, Zielmarken.
-- Gesetzt nur, wenn sich etwas aendert (p._fx*).
function NP.Motion(p, isTarget, glow)
    isTarget = isTarget and true or false
    local pulse = isTarget and glow and S.targetPulse and true or false
    local sheen = isTarget and S.targetSheen and true or false
    local marks = isTarget and glow and S.markMotion and true or false
    local edge = isTarget and S.targetEdge and true or false
    if p._fxPulse ~= pulse then
        p._fxPulse = pulse
        for _, ag in pairs(p.pulseAnims) do Run(ag, pulse) end
    end
    if p._fxSheen ~= sheen then
        p._fxSheen = sheen
        p.sheen:SetShown(sheen)
        Run(p.sheenAnim, sheen)
    end
    if p._fxMarks ~= marks then
        p._fxMarks = marks
        for _, ag in pairs(p.markAnims) do Run(ag, marks) end
    end
    if p._fxEdge ~= edge then
        p._fxEdge = edge
        if edge then
            local c = K.Highlight()
            p.border:SetColor(c[1], c[2], c[3], 1)
            p.border:SetShown(true)
        else
            local bc = S.borderColor or defaults.borderColor
            p.border:SetColor(bc.r, bc.g, bc.b, 1)
            p.border:SetShown(S.showBorder and not p._friendly or (p._friendly and S.friendlyHealth and S.showBorder))
        end
    end
end

local function Build(parent)
    local p = CreateFrame("Frame", nil, parent or UIParent)
    p:SetSize(defaults.width, defaults.height)

    local health = K.NewBar(p)
    health:SetAllPoints(p)
    health:SetMinMaxValues(0, 1)
    health:SetValue(1)
    p.health = health

    -- Grund am Plakettenrahmen (seit 6.8.1.0), nicht am Balken: zwischen
    -- beiden liegt die Schadensspur, ein eigener Balken. Ganz oben in der
    -- untersten Ebene - ueber den Scheinen, unter Spur und Leben.
    local bg = p:CreateTexture(nil, "BACKGROUND", nil, 7)
    bg:SetAllPoints(health)
    p.bg = bg

    -- SCHADENSSPUR. Ein zweiter Balken hinter dem Leben, derselbe Wert -
    -- nur NP.TRAIL_DELAY s spaeter (und, wo der Client es kann, gleitend).
    -- Was ein Treffer nahm, steht so einen Moment hell da. Keine Rechnung,
    -- kein Vergleich: der Wert darf geheim sein, er wird nur weitergereicht.
    local trail = CreateFrame("StatusBar", nil, p)
    trail:SetStatusBarTexture(K.BarTexture())
    trail:SetAllPoints(health)
    trail:SetMinMaxValues(0, 1)
    trail:SetValue(1)
    local GCt = WeintCodex.GameColors.damageTrail
    trail:SetStatusBarColor(GCt[1], GCt[2], GCt[3], GCt[4])
    p.trail = trail
    local base = p:GetFrameLevel()
    trail:SetFrameLevel(base + 1)
    health:SetFrameLevel(base + 2)

    p.border = K.Border(health, 1, 0, 0, 0, 1, "BORDER")
    p.ring = K.Border(health, 2, 1, 1, 1, 1, "OVERLAY")
    p.ring:SetShown(false)

    -- Tiefe statt Rahmen. Alle Scheine haengen am Plakettenrahmen selbst
    -- (unter dem Balken, der ein Kindrahmen ist) und reichen ueber ihn
    -- hinaus. Ohne Neunteiler im Client bleiben sie aus (K.Glow).
    local GC = WeintCodex.GameColors
    -- Zielleuchten in der Farbe der Hervorhebung (6.6.2.4: Klassenfarbe),
    -- Staerke wie bisher.
    local hc = K.Highlight()
    p.shadow = K.Glow(health, { host = p, spread = 5, color = GC.shadow })
    p.glowWide = K.Glow(health, { host = p, wide = true, spread = 16, sublevel = -7,
        color = { hc[1], hc[2], hc[3], 0.35 }, shown = false })
    p.glow = K.Glow(health, { host = p, spread = 7, sublevel = -6,
        color = { hc[1], hc[2], hc[3], GC.targetGlow[4] }, shown = false })
    p.hoverGlow = K.Glow(health, { host = p, spread = 6, sublevel = -5, color = GC.hoverGlow, shown = false })

    -- Maus darueber: der Balken hellt auf. Additiv, damit jede Farbe
    -- heller wird statt weisslich.
    local hf = health:CreateTexture(nil, "OVERLAY", nil, 1)
    hf:SetAllPoints(health)
    hf:SetColorTexture(GC.hoverFill[1], GC.hoverFill[2], GC.hoverFill[3], GC.hoverFill[4])
    if hf.SetBlendMode then hf:SetBlendMode("ADD") end
    hf:Hide()
    p.hoverFill = hf

    -- Treffer am Ziel: kurzes Aufblitzen (additiv, Animation des Spiels -
    -- kein Lua je Bild).
    local fl = health:CreateTexture(nil, "OVERLAY", nil, 3)
    fl:SetAllPoints(health)
    fl:SetColorTexture(1, 1, 1, 1)
    if fl.SetBlendMode then fl:SetBlendMode("ADD") end
    fl:SetAlpha(0)
    p.flash = fl
    p.flashAnim = NP.Anim(fl, "Alpha", function(a)
        local c = GC.hitFlash
        a:SetFromAlpha(c[4]) a:SetToAlpha(0) a:SetDuration(0.25)
    end)

    -- Glanz: ein heller Streifen laeuft ueber den Balken des Ziels, dann
    -- Pause. Abgeschnitten an einem Rahmen (SetClipsChildren), der genau
    -- so gross ist wie der Balken; bewegt wird der Rahmen darin.
    local clip = CreateFrame("Frame", nil, health)
    clip:SetAllPoints(health)
    if clip.SetClipsChildren then pcall(clip.SetClipsChildren, clip, true) end
    local sheen = CreateFrame("Frame", nil, clip)
    sheen:SetSize(NP.SHEEN_W, 1)
    sheen:SetPoint("TOPRIGHT", clip, "TOPLEFT", 0, 0)
    sheen:SetPoint("BOTTOMRIGHT", clip, "BOTTOMLEFT", 0, 0)
    local sc = GC.plateSheen
    for i, half in ipairs({ "l", "r" }) do
        local t = sheen:CreateTexture(nil, "OVERLAY")
        t:SetColorTexture(1, 1, 1, 1)
        if t.SetBlendMode then t:SetBlendMode("ADD") end
        t:SetPoint("TOP", sheen, "TOP", 0, 0)
        t:SetPoint("BOTTOM", sheen, "BOTTOM", 0, 0)
        t:SetWidth(NP.SHEEN_W / 2)
        if i == 1 then t:SetPoint("LEFT", sheen, "LEFT", 0, 0) else t:SetPoint("RIGHT", sheen, "RIGHT", 0, 0) end
        if t.SetGradient and _G.CreateColor then
            local a0, a1 = (i == 1) and 0 or sc[4], (i == 1) and sc[4] or 0
            t:SetGradient("HORIZONTAL", _G.CreateColor(sc[1], sc[2], sc[3], a0), _G.CreateColor(sc[1], sc[2], sc[3], a1))
        else
            t:SetVertexColor(sc[1], sc[2], sc[3], sc[4] * 0.5)
        end
        sheen[half] = t
    end
    sheen:Hide()
    p.sheen = sheen
    p.sheenAnim = NP.Anim(sheen, "Translation", function(a, ag)
        a:SetDuration(NP.SHEEN_RUN)
        if a.SetSmoothing then a:SetSmoothing("IN_OUT") end
        a:SetOrder(1)
        -- Pause: eine Animation, die nichts tut, als Zeit zu brauchen.
        local wait = ag:CreateAnimation("Alpha")
        if type(wait) == "table" and wait.SetFromAlpha then
            wait:SetFromAlpha(1) wait:SetToAlpha(1) wait:SetDuration(NP.SHEEN_PAUSE) wait:SetOrder(2)
        end
        p.sheenMove = a
    end, "REPEAT")

    -- Hinrichtungsmarke: ein fester Strich im Balken. Keine Rechnung mit
    -- dem Leben (das kann geheim sein) - der Strich steht, der Balken
    -- laeuft an ihm vorbei.
    local ex = health:CreateTexture(nil, "OVERLAY", nil, 2)
    local ec = GC.executeMark
    ex:SetColorTexture(ec[1], ec[2], ec[3], ec[4])
    ex:SetWidth(1)
    ex:Hide()
    p.exec = ex

    -- Texte liegen auf einem eigenen Rahmen ueber dem Balken, damit der
    -- Rand sie nicht ueberdeckt.
    local textHost = CreateFrame("Frame", nil, p)
    textHost:SetAllPoints(p)
    textHost:SetFrameLevel(health:GetFrameLevel() + 3)
    p.texts = {}
    for _, slot in ipairs(SLOTS) do
        local fs = K.NewText(textHost)
        fs:SetWordWrap(false)
        p.texts[slot] = fs
    end

    local raid = K.NewRaidIcon(textHost, defaults.raidMarkerSize)
    p.raid = raid

    -- Zielmarken: zwei gestaffelte Winkel links und rechts, die auf den
    -- Balken zeigen. Eine Datei, rechts gespiegelt.
    p.marks = {}
    p.markAnims = {}
    for i, side in ipairs({ "left", "right" }) do
        local m = textHost:CreateTexture(nil, "OVERLAY")
        m:SetTexture(K.MARK_TEXTURE)
        if side == "right" then m:SetTexCoord(1, 0, 0, 1) end
        local c = GC.targetMark
        m:SetVertexColor(c[1], c[2], c[3], c[4])
        m:Hide()
        p.marks[i] = m
        -- Atmen nach aussen (6.8.1.0): ein paar Pixel hin und zurueck.
        p.markAnims[i] = NP.Anim(m, "Translation", function(a)
            a:SetOffset(i == 1 and -NP.MARK_SWAY or NP.MARK_SWAY, 0)
            a:SetDuration(NP.MARK_BREATH)
            if a.SetSmoothing then a:SetSmoothing("IN_OUT") end
        end, "BOUNCE")
    end
    -- Leuchten des Ziels atmet (6.8.1.0).
    p.pulseAnims = {}
    for i, g in ipairs({ p.glow, p.glowWide }) do
        if g.tex then
            p.pulseAnims[i] = NP.Anim(g.tex, "Alpha", function(a)
                a:SetFromAlpha(1) a:SetToAlpha(NP.PULSE_LOW) a:SetDuration(NP.PULSE_HALF)
                if a.SetSmoothing then a:SetSmoothing("IN_OUT") end
            end, "BOUNCE")
        end
    end

    p.cast = CB.Create(p)
    p.auras = WeintCodex.UIAuras.Create(p, { filter = "HARMFUL|INCLUDE_NAME_PLATE_ONLY|PLAYER", max = defaults.auraMax,
        size = defaults.auraSize, spacing = 2, anchor = "BOTTOMLEFT", growth = "RIGHT",
        growthV = "UP", perRow = defaults.auraMax, timer = defaults.auraTimer })
    p.quest = K.NewText(textHost, 13)
    p.quest:SetJustifyH("RIGHT")
    p.quest:Hide()
    p.threat = K.NewText(textHost, 10)
    p.threat:Hide()
    -- Bedrohungsleiste (6.9.0.8, Beta-Test: "besser an den Plaketten
    -- anzeigen, nicht nur die Prozentzahl"): duenn unter dem Leben, voll =
    -- du ziehst die Aggro. Der Wert geht nur an SetValue (darf geheim sein).
    local tb = K.NewBar(p, true)
    tb:SetMinMaxValues(0, 100)
    tb:SetValue(0)
    local tbg = tb:CreateTexture(nil, "BACKGROUND")
    tbg:SetAllPoints(tb)
    local tgc = GC.threatBarBg
    tbg:SetColorTexture(tgc[1], tgc[2], tgc[3], tgc[4])
    -- 6.10.3.2: 1 px Schwarz wie das Leben - oben teilt sie sich die Linie
    -- mit dessen Rand, unten liegt sie in der Luecke zum Zauberbalken.
    -- Vorher stand die Leiste ohne Abschluss im Spiel.
    tb.edge = K.Border(tb, 1, 0, 0, 0, 1, "OVERLAY")
    tb:Hide()
    p.threatBar = tb
    -- Wer die Aggro hat ("Aggro: Tamsin"), unter der Plakette rechts.
    p.aggro = K.NewText(textHost, 10)
    p.aggro:SetJustifyH("RIGHT")
    p.aggro:SetWordWrap(false)
    p.aggro:Hide()
    return p
end

-- INCLUDE_NAME_PLATE_ONLY: dieselbe Filtermarke wie Blizzards eigene
-- Plaketten - sonst fehlen Debuffs, die das Spiel nur fuer Plaketten
-- vorsieht. Reihenfolge fest (das Spiel vergleicht Filter als Text).
local function AuraFilter()
    return S.auraOnlyMine and "HARMFUL|INCLUDE_NAME_PLATE_ONLY|PLAYER" or "HARMFUL|INCLUDE_NAME_PLATE_ONLY"
end

-- Nur Name: kein Balken, kein Rand, der Name in der Mitte. Freundliche
-- Plaketten brauchen keine Lebenspunkte, um lesbar zu sein - und wer sie
-- will, schaltet den Balken zu.
local function LayoutFriendly(p)
    local bar = S.friendlyHealth
    p:SetSize(S.width, bar and S.height or 1)
    if bar then p.health:Show() else p.health:Hide() end
    p.border:SetShown(bar and S.showBorder)
    p.bg:SetShown(bar and true or false)
    p.trail:SetShown(bar and S.damageTrail and true or false)
    NP.Motion(p, false)
    p.ring:SetShown(false)
    p.shadow:SetShown(bar and S.shadow)
    p.glow:SetShown(false)
    p.glowWide:SetShown(false)
    p.hoverGlow:SetShown(false)
    p.hoverFill:Hide()
    p.exec:Hide()
    for _, m in ipairs(p.marks) do m:Hide() end
    for _, slot in ipairs(SLOTS) do p.texts[slot]:Hide() end
    local t = p.texts.top
    K.SetFont(t, S.friendlyNameSize)
    t:ClearAllPoints()
    if bar then t:SetPoint("BOTTOM", p, "TOP", 0, 3) else t:SetPoint("CENTER", p, "CENTER", 0, 0) end
    t:SetWidth(S.width + 40)
    t:SetJustifyH("CENTER")
    p.cast:Hide()
    p.auras:SetShown(false)
    p.quest:Hide()
    p.raid:ClearAllPoints()
    K.SetRaidIconSize(p.raid, S.raidMarkerSize)
    p.raid:SetPoint("BOTTOM", t, "TOP", 0, 2)
end

-- Wo die Markierung steht - fuer unser Symbol und fuer die Markierung
-- des Spiels, wenn der Index geheim ist (UpdateRaidIcon).
function NP.RaidAnchor(p)
    local pos = S.raidMarker
    if pos == "top" then return "BOTTOM", p.texts.top, "TOP", 0, 2 end
    if pos == "left" then return "RIGHT", p, "LEFT", -4, 0 end
    if pos == "right" then return "LEFT", p, "RIGHT", 4, 0 end
    return "BOTTOMLEFT", p, "TOPRIGHT", -(S.raidMarkerSize or 20) * 0.5, 2
end

local function Layout(p)
    if p._friendly then return LayoutFriendly(p) end
    p.health:Show()
    p.bg:Show()
    p.trail:SetShown(S.damageTrail and true or false)
    p:SetSize(S.width, S.height)
    -- Der Glanz laeuft ueber die ganze Breite und ein Stueck hinaus.
    if p.sheenMove and p.sheenMove.SetOffset then p.sheenMove:SetOffset(S.width + NP.SHEEN_W, 0) end

    local bgc = S.bgColor or defaults.bgColor
    p.bg:SetColorTexture(bgc.r, bgc.g, bgc.b, 1)
    p._bgR = nil
    p.shadow:SetShown(S.shadow)
    local ms = math.floor(S.height * 1.35 + 0.5)
    for i, m in ipairs(p.marks) do
        m:SetSize(ms, ms)
        m:ClearAllPoints()
        if i == 1 then
            m:SetPoint("RIGHT", p.health, "LEFT", -2, 0)
        else
            m:SetPoint("LEFT", p.health, "RIGHT", 2, 0)
        end
    end
    p.exec:ClearAllPoints()
    p.exec:SetPoint("TOP", p.health, "TOPLEFT", S.width * S.executeAt / 100, 0)
    p.exec:SetPoint("BOTTOM", p.health, "BOTTOMLEFT", S.width * S.executeAt / 100, 0)
    p.exec:SetShown(S.executeMark)
    p.border:SetShown(S.showBorder)
    local bc = S.borderColor or defaults.borderColor
    p.border:SetColor(bc.r, bc.g, bc.b, 1)
    local rc = K.Highlight()
    p.ring:SetColor(rc[1], rc[2], rc[3], 1)
    -- Rand neu gesetzt: Kante und Bewegung beim naechsten UpdateTarget neu.
    p._fxEdge, p._fxPulse, p._fxSheen, p._fxMarks = nil, nil, nil, nil

    local t = p.texts
    for _, slot in ipairs(SLOTS) do
        local fs = t[slot]
        K.SetFont(fs, slot == "top" and S.nameSize or S.textSize)
        fs:ClearAllPoints()
    end
    t.top:SetPoint("BOTTOM", p, "TOP", 0, 3)
    t.top:SetWidth(S.width + 20)
    t.top:SetJustifyH("CENTER")
    -- Steht der Name im Balken, bekommt seine Seite den meisten Platz;
    -- die Zahl daneben braucht wenig.
    local function IsName(k) return k == "name" or k == "levelName" end
    local leftShare = IsName(S.textLeft) and 0.7 or (IsName(S.textRight) and 0.3 or 0.5)
    t.left:SetPoint("LEFT", p, "LEFT", 4, 0)
    t.left:SetWidth(S.width * leftShare - 6)
    t.left:SetJustifyH("LEFT")
    t.right:SetPoint("RIGHT", p, "RIGHT", -3, 0)
    t.right:SetWidth(S.width * (1 - leftShare) - 6)
    t.right:SetJustifyH("RIGHT")
    t.center:SetPoint("CENTER", p, "CENTER", 0, 0)
    -- Mit Texten links und rechts nur die Mitte, sonst ueberlappen sie.
    local sides = (S.textLeft ~= "none" and 1 or 0) + (S.textRight ~= "none" and 1 or 0)
    t.center:SetWidth(sides > 0 and S.width * 0.55 or S.width - 8)
    t.center:SetJustifyH("CENTER")

    local raid = p.raid
    raid:ClearAllPoints()
    K.SetRaidIconSize(raid, S.raidMarkerSize)
    raid:SetPoint(NP.RaidAnchor(p))

    -- Auren ueber dem Namen, linksbuendig.
    local align = S.auraAlign or "left"
    local anchor = align == "right" and "BOTTOMRIGHT" or "BOTTOMLEFT"
    p.auras:ApplyLayout({ filter = AuraFilter(), max = S.auraMax, size = S.auraSize,
        spacing = 2, anchor = anchor, growth = align == "right" and "LEFT" or "RIGHT", growthV = "UP",
        perRow = S.auraMax, timer = S.auraTimer })
    -- Questfortschritt links neben der Namenszeile, ausserhalb des Balkens:
    -- so ueberdeckt er weder Namen noch Stufe.
    K.SetFont(p.threat, S.textSize)
    p.threat:ClearAllPoints()
    if S.threatText == "right" then
        -- Rechts neben dem Balken, hinter der Zielmarke.
        p.threat:SetPoint("LEFT", p, "RIGHT", math.floor(S.height * 1.35 + 0.5) + 4, 0)
        p.threat:SetJustifyH("LEFT")
    else
        p.threat:SetPoint("BOTTOMLEFT", p, "TOPLEFT", 1, 2)
        p.threat:SetJustifyH("LEFT")
    end
    K.SetFont(p.quest, S.nameSize + 2)
    p.quest:ClearAllPoints()
    p.quest:SetPoint("BOTTOMRIGHT", p, "TOPLEFT", -2, 2)
    local qc = WeintCodex.GameColors.questObjective
    p.quest:SetTextColor(qc[1], qc[2], qc[3], 1)
    p.auras:ClearAllPoints()
    local auraY = (S.textTop ~= "none" and S.nameSize or 0) + 8
    if align == "right" then
        p.auras:SetPoint("BOTTOMRIGHT", p, "TOPRIGHT", 0, auraY)
    elseif align == "center" then
        -- Der Block (Platz fuer alle Symbole) mittig; weniger Symbole als
        -- Plaetze beginnen links in ihm.
        p.auras:SetPoint("BOTTOM", p, "TOP", 0, auraY)
    else
        p.auras:SetPoint("BOTTOMLEFT", p, "TOPLEFT", 0, auraY)
    end
    p.auras:SetShown(S.auraEnabled and S.auraSource == "own")

    -- Bedrohungsleiste direkt unter dem Leben; der Zauberbalken rueckt um
    -- ihre Hoehe nach unten - immer, nicht nur wenn sie zu sehen ist: eine
    -- Plakette, deren Zauberbalken im Kampf springt, liest sich schlechter.
    local tbh = S.threatBar and (S.threatBarHeight or 3) or 0
    p.threatBar:ClearAllPoints()
    p.threatBar:SetPoint("TOPLEFT", p, "BOTTOMLEFT", 0, -1)
    p.threatBar:SetPoint("TOPRIGHT", p, "BOTTOMRIGHT", 0, -1)
    p.threatBar:SetHeight(math.max(1, tbh))
    if not S.threatBar then p.threatBar:Hide() end
    K.SetFont(p.aggro, S.textSize)
    p.aggro:SetWidth(S.width)
    p._aggroAt = nil
    local cast = p.cast
    cast:ClearAllPoints()
    cast:SetPoint("TOPLEFT", p, "BOTTOMLEFT", 0, -2 - (tbh > 0 and tbh + 1 or 0))
    cast:SetPoint("TOPRIGHT", p, "BOTTOMRIGHT", 0, -2 - (tbh > 0 and tbh + 1 or 0))
    cast:ApplyStyle({
        height = S.castHeight, icon = S.castIcon, timer = S.castTimer,
        shield = S.castShield, cast = S.castColor, locked = S.castLocked,
        bg = S.bgColor, border = S.showBorder, target = S.castTarget,
    })
end

--------------------------------------------------
-- Inhalte
--------------------------------------------------

local function IsUnit(unit, other)
    return K.Bool(_G.UnitIsUnit and _G.UnitIsUnit(unit, other), false)
end

local function LevelText(unit)
    -- Kein `a and b or c`: das `or` prueft b auf Wahrheit, und b kann
    -- geheim sein.
    local lvl
    if _G.UnitEffectiveLevel then
        lvl = _G.UnitEffectiveLevel(unit)
    elseif _G.UnitLevel then
        lvl = _G.UnitLevel(unit)
    end
    local plain = K.Plain(lvl)
    local cls = K.Plain(_G.UnitClassification and _G.UnitClassification(unit))
    if type(plain) ~= "number" or plain < 0 then
        -- Boss (-1) oder vom Client verschwiegen: beides "??", wie im
        -- Spiel selbst. Eine 0 waere eine Behauptung.
        return "??", 1, 0.2, 0.2
    end
    local text = tostring(plain)
    if S.eliteMark and (cls == "elite" or cls == "rareelite" or cls == "worldboss") then
        text = text .. "+"
    end
    local r, g, b = 1, 0.82, 0
    if S.levelColor and _G.GetCreatureDifficultyColor then
        local c = _G.GetCreatureDifficultyColor(plain)
        if type(c) == "table" and K.Plain(c.r) then r, g, b = c.r, c.g, c.b end
    end
    return text, r, g, b
end

-- Lebenspunkte als Text. Mit UnitHealthPercent (12.0+) rechnet der
-- Client den Anteil selbst - auch wenn er ihn Lua gegenueber geheim
-- haelt, nimmt ihn string.format entgegen.
local function HealthTexts(unit)
    local cur = _G.UnitHealth and _G.UnitHealth(unit)
    local max = _G.UnitHealthMax and _G.UnitHealthMax(unit)
    local pct
    if _G.UnitHealthPercent and _G.CurveConstants and _G.CurveConstants.ScaleTo100 then
        local ok, v = pcall(_G.UnitHealthPercent, unit, true, _G.CurveConstants.ScaleTo100)
        if ok then pct = v end
    end
    if type(pct) == "nil" then
        local c, m = K.Plain(cur), K.Plain(max)
        if type(c) == "number" and type(m) == "number" and m > 0 then
            pct = c / m * 100
        end
    end
    -- `type()` statt `~= nil`: ein Vergleich mit einem geheimen Wert ist
    -- im 12.x-Client ein Fehler, `type` nicht.
    local pctText = (type(pct) ~= "nil") and string.format("%d%%", pct) or ""
    local numText = ""
    if type(cur) ~= "nil" then
        if _G.AbbreviateNumbers then
            numText = _G.AbbreviateNumbers(cur)
        elseif type(K.Plain(cur)) == "number" then
            numText = WeintCodex.FormatAmount and WeintCodex.FormatAmount(cur) or tostring(cur)
        end
    end
    return pctText, numText
end

local TEXT_KEYS = { top = "textTop", left = "textLeft", right = "textRight", center = "textCenter" }
local function FillTexts(p, onlyHealth)
    local unit = p.unit
    if not unit then return end
    if p._friendly then
        if onlyHealth then return end
        local t = p.texts.top
        t:SetText(_G.UnitName and (_G.UnitName(unit)))
        local r, g, b = 1, 1, 1
        local c = S.friendlyColor
        if c then r, g, b = c.r, c.g, c.b end
        if S.friendlyClassColor and K.Bool(_G.UnitIsPlayer and _G.UnitIsPlayer(unit), false) then
            local _, class = _G.UnitClass(unit)
            class = K.Plain(class)
            local cc = class and _G.RAID_CLASS_COLORS and _G.RAID_CLASS_COLORS[class]
            if cc then r, g, b = cc.r, cc.g, cc.b end
        end
        t:SetTextColor(r, g, b, 1)
        t:Show()
        return
    end
    local pctText, numText
    -- Ohne neue Tabelle: FillTexts laeuft bei jedem UNIT_HEALTH (6.14.0.2,
    -- /wcui speicher: Plaketten 11 KB/s).
    for slot, key in pairs(TEXT_KEYS) do
        local kind = S[key]
        local fs = p.texts[slot]
        if kind == "none" then
            fs:Hide()
        elseif kind == "healthPercent" or kind == "healthNumber" or kind == "healthBoth" then
            if not pctText then pctText, numText = HealthTexts(unit) end
            if kind == "healthPercent" then
                fs:SetText(pctText)
            elseif kind == "healthNumber" then
                fs:SetText(numText)
            else
                -- SetFormattedText statt `..`: beide Teile koennen geheim
                -- sein, und formatieren darf der Client sie.
                fs:SetFormattedText("%s  %s", numText, pctText)
            end
            fs:SetTextColor(1, 1, 1, 1)
            fs:Show()
        elseif not onlyHealth then
            if kind == "name" then
                -- Kein `or ""`: ein Wahrheitstest auf einem geheimen Namen
                -- (Schlachtfelder) waere ein Fehler, SetText(nil) nicht.
                fs:SetText(_G.UnitName and (_G.UnitName(unit)))
                -- Ruhiger Ton; hell nur Ziel und Maus (UpdateTarget).
                local c = p._hl and WeintCodex.Colors.textBright or WeintCodex.GameColors.plateName
                fs:SetTextColor(c[1], c[2], c[3], 1)
            elseif kind == "level" then
                local text, r, g, b = LevelText(unit)
                fs:SetText(text)
                fs:SetTextColor(r, g, b, 1)
            elseif kind == "levelName" then
                -- Stufe in ihrer Farbe vor dem Namen, beides in einer
                -- Zeile. SetFormattedText: der Name kann geheim sein.
                local text, r, g, b = LevelText(unit)
                local hex = string.format("%02x%02x%02x", math.floor(r * 255 + 0.5),
                    math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5))
                fs:SetFormattedText("|cff" .. hex .. "%s|r  %s", text or "", _G.UnitName and (_G.UnitName(unit)))
                local c = p._hl and WeintCodex.Colors.textBright or WeintCodex.GameColors.plateName
                fs:SetTextColor(c[1], c[2], c[3], 1)
            end
            fs:Show()
        end
    end
end

-- `hit`: ein Ereignis UNIT_HEALTH (Aufblitzen am Ziel); `snap`: neue
-- Einheit an der Plakette - Spur sofort, ohne Verzoegerung.
local function UpdateHealth(p, hit, snap)
    local unit = p.unit
    if not unit then return end
    local max = _G.UnitHealthMax and _G.UnitHealthMax(unit)
    if type(max) ~= "nil" then
        p.health:SetMinMaxValues(0, max)
        p.trail:SetMinMaxValues(0, max)
    end
    local cur = _G.UnitHealth and _G.UnitHealth(unit)
    if type(cur) ~= "nil" then
        NP.SetBar(p.health, cur, not snap)
        NP.Trail(p, cur, snap)
    end
    -- Ob das Leben sank oder stieg, darf Lua nicht fragen (geheim): auch
    -- eine Heilung blitzt. Bei Gegnern selten, deshalb abschaltbar.
    if hit and p._isTarget == true and S.hitFlash and p.flashAnim then
        p.flashAnim:Stop()
        p.flashAnim:Play()
    end
    FillTexts(p, true)
end

-- Die Farbe des Balkens, in Rangfolge. Jede Frage, die der Client geheim
-- beantwortet, zaehlt als "nein" - die Plakette faellt dann auf die
-- naechste Stufe zurueck, statt mit einem Fehler stehen zu bleiben.
local function C3(c) return c.r, c.g, c.b end
local function BarColor(p)
    local unit = p.unit

    if p._friendly then
        if S.friendlyClassColor and K.Bool(_G.UnitIsPlayer and _G.UnitIsPlayer(unit), false) then
            local _, class = _G.UnitClass(unit)
            class = K.Plain(class)
            local cc = class and _G.RAID_CLASS_COLORS and _G.RAID_CLASS_COLORS[class]
            if cc then return cc.r, cc.g, cc.b end
        end
        return C3(S.friendlyColor)
    end

    if K.Bool(_G.UnitIsTapDenied and _G.UnitIsTapDenied(unit), false) then
        return C3(S.tapped)
    end
    if S.targetColorEnabled and IsUnit(unit, "target") then return C3(S.target) end
    if S.focusColorEnabled and IsUnit(unit, "focus") then return C3(S.focus) end

    -- Eigene Farbe fuer genau diesen NPC (6.6.2.2) - vor allem anderen,
    -- was der Spieler nicht ausdruecklich gewaehlt hat.
    local NC = WeintCodex.UINpcColors
    if NC then
        local r, g, b = NC.RuleColor(p)
        if r then return r, g, b end
    end

    if S.classColorPlayers and K.Bool(_G.UnitIsPlayer and _G.UnitIsPlayer(unit), false) then
        local _, class = _G.UnitClass(unit)
        class = K.Plain(class)
        local cc = class and _G.RAID_CLASS_COLORS and _G.RAID_CLASS_COLORS[class]
        if cc then return cc.r, cc.g, cc.b end
    end

    local inCombat = K.Bool(_G.UnitAffectingCombat and _G.UnitAffectingCombat(unit), true)

    -- Die Lage aus UpdateThreatText (NP.ThreatTint) - dieselbe Farbe wie
    -- Leiste und Prozentzahl, und wie dort nicht allein ohne Begleiter.
    local tint = p._threatTint
    if S.threatColors and inCombat and tint then return C3(tint) end

    local reaction = K.Plain(_G.UnitReaction and _G.UnitReaction(unit, "player"))
    if reaction == 4 then return C3(S.neutral) end

    local cls = K.Plain(_G.UnitClassification and _G.UnitClassification(unit))
    local lvl = K.Plain(_G.UnitLevel and _G.UnitLevel(unit))
    if cls == "worldboss" or lvl == -1 then return C3(S.boss) end
    -- Zaubernde vor Elite: "muss unterbrochen werden" ist die dringendere
    -- Auskunft.
    if S.casterColoring and p._caster then return C3(S.caster) end
    if S.eliteColoring and (cls == "elite" or cls == "rareelite") then return C3(S.elite) end

    if inCombat or not S.darkenOOC then return C3(S.enemyInCombat) end
    return C3(S.hostile)
end

-- Der Grund unter dem fehlenden Leben: ein dunkler Ton der Balkenfarbe
-- statt Schwarz. So bleibt auch eine fast leere Plakette als "Feind" oder
-- "Neutral" lesbar.
local TINT = 0.22
local function PaintBg(p, r, g, b)
    local bgc = S.bgColor or defaults.bgColor
    local br, bgg, bb = bgc.r, bgc.g, bgc.b
    if S.tintedBg then
        br, bgg, bb = br * (1 - TINT) + r * TINT, bgg * (1 - TINT) + g * TINT, bb * (1 - TINT) + b * TINT
    end
    if p._bgR == br and p._bgG == bgg and p._bgB == bb then return end
    p._bgR, p._bgG, p._bgB = br, bgg, bb
    p.bg:SetColorTexture(br, bgg, bb, 1)
end

local function UpdateColor(p)
    if not p.unit then return end
    local r, g, b = BarColor(p)
    K.PaintBar(p.health, r, g, b)
    if not p._friendly then PaintBg(p, r, g, b) end
end

local anyTarget = false
local hovered            -- die Plakette unter der Maus, oder nil

-- Ziel, Maus und Abdunkeln in einem: alle drei haengen voneinander ab (die
-- Maus holt eine abgedunkelte Plakette nach vorn, das Ziel leuchtet statt
-- aufzuhellen).
local function UpdateTarget(p)
    if not p.unit then return end
    local isTarget = IsUnit(p.unit, "target") and not p._friendly
    local isHover = (hovered == p) and S.hover and not p._friendly
    local style = S.targetStyle
    local glow = isTarget and (style == "glow" or style == "both")
    p.ring:SetShown(isTarget and (style == "ring" or style == "both"))
    p.glow:SetShown(glow)
    p.glowWide:SetShown(glow)
    for _, m in ipairs(p.marks) do m:SetShown(glow) end
    p.hoverFill:SetShown(isHover and not isTarget)
    p.hoverGlow:SetShown(isHover and not isTarget)
    p._isTarget = isTarget and true or false
    NP.Motion(p, isTarget, glow)

    p._hl = (isTarget or isHover) or nil
    if not p._friendly then
        local c = p._hl and WeintCodex.Colors.textBright or WeintCodex.GameColors.plateName
        for slot, kind in pairs({ top = S.textTop, left = S.textLeft, right = S.textRight, center = S.textCenter }) do
            if kind == "name" or kind == "levelName" then p.texts[slot]:SetTextColor(c[1], c[2], c[3], 1) end
        end
    end

    p:SetScale(isTarget and (S.targetScale / 100) or 1)
    if anyTarget and not isTarget and not isHover then
        p:SetAlpha(S.nonTargetAlpha / 100)
    else
        p:SetAlpha(1)
    end
    -- Ziel oben, dann die unter der Maus: sonst liegt die ausgewaehlte
    -- Plakette halb unter der naechsten.
    if p.SetFrameLevel then p:SetFrameLevel(isTarget and 20 or (isHover and 15 or 5)) end
end

-- Die Maus: das Spiel meldet, WENN eine Einheit unter die Maus kommt
-- (UPDATE_MOUSEOVER_UNIT), aber nicht, wenn sie wieder geht. Solange eine
-- Plakette hervorgehoben ist, fragt ein Takt zehnmal je Sekunde nach.
local hoverTicker = CreateFrame("Frame")
local hoverAcc = 0
local function SetHovered(p)
    if hovered == p then return end
    local old = hovered
    hovered = p
    if old then UpdateTarget(old) end
    if p then UpdateTarget(p) end
    if p then
        hoverAcc = 0
        hoverTicker:SetScript("OnUpdate", function(_, el)
            hoverAcc = hoverAcc + (el or 0)
            if hoverAcc < 0.1 then return end
            hoverAcc = 0
            if not (hovered and hovered.unit and IsUnit(hovered.unit, "mouseover")) then SetHovered(nil) end
        end)
    else
        hoverTicker:SetScript("OnUpdate", nil)
    end
end
NP.SetHovered = SetHovered

-- Die Markierung (Totenkopf, Kreuz ...), auch mit geheimem Index - siehe
-- UIKit.ShowRaidIndex. 6.3.2.6 liess dafuer die Markierung des Spiels
-- stehen; im Beta-Test blieb auch die unsichtbar.
NP.raidInfo = "noch keine Markierung gesehen"
local function UpdateRaidIcon(p)
    if not p.unit or S.raidMarker == "none" then p.raid:Hide() return end
    local shown, secret = K.ShowRaidIcon(p.raid, p.unit)
    if shown then
        NP.raidInfo = secret and "geheim, als Bild aus dem Text gezeigt" or "offen lesbar, gezeigt"
    end
end
NP.UpdateRaidIcon = UpdateRaidIcon

--------------------------------------------------
-- Questfortschritt
--------------------------------------------------
-- Gehoert der Gegner zu einer deiner Quests, steht links vom Namen, wie
-- weit du bist ("8/10", bei Gebietsquests "40%"). Die Auskunft kommt aus
-- den Tooltipdaten des Spiels (C_TooltipInfo.GetUnit): eine Zeile
-- "Questziel" traegt erledigt/noetig, eine Zeile "Questtitel" davor die
-- Quest. Nur Quests aus DEINEM Questlog zaehlen (C_QuestLog.IsOnQuest) -
-- sonst stuende das Ziel eines Gruppenmitglieds da. Geheime Werte
-- zaehlen als "unbekannt": dann steht nichts, statt einer geratenen Zahl.
--
-- Je Einheit einmal gelesen; neu bei jeder Aenderung des Questlogs. In
-- Instanzen nicht (dort gibt es keine Questgegner, und der Tooltip waere
-- je Plakette Arbeit ohne Ertrag).

local questCache = {}   -- [unit] = Text oder false

function NP.QuestProgress(unit)
    local ti = _G.C_TooltipInfo
    local LT = _G.Enum and _G.Enum.TooltipDataLineType
    if not (ti and ti.GetUnit and LT and LT.QuestObjective) then return nil end
    local ok, info = pcall(ti.GetUnit, unit)
    if not ok or type(info) ~= "table" or type(info.lines) ~= "table" then return nil end
    local ql = _G.C_QuestLog
    local questID
    for _, line in ipairs(info.lines) do
        local kind = K.Plain(line.type)
        if kind == LT.QuestTitle then
            local id = K.Plain(line.id)
            questID = type(id) == "number" and id or nil
        elseif kind == LT.QuestObjective then
            local mine = not questID or not (ql and ql.IsOnQuest) or K.Bool(ql.IsOnQuest(questID), true)
            local done = K.Plain(line.completed)
            local have, need = K.Plain(line.numFulfilled), K.Plain(line.numRequired)
            local text = K.Plain(line.leftText)
            if type(text) ~= "string" then text = nil end
            if done == nil and type(have) == "number" and type(need) == "number" then done = have >= need end
            if mine and done == false then
                local pct = text and text:match("(%d+)%s*%%")
                if pct then return pct .. "%" end
                if type(have) == "number" and type(need) == "number" and need > 0 then
                    return have .. "/" .. need
                end
                local a, b = nil, nil
                if text then a, b = text:match("(%d+)%s*/%s*(%d+)") end
                if a then return a .. "/" .. b end
                -- Ein Questgegner ohne lesbaren Stand: markieren, nicht raten.
                return "!"
            end
        end
    end
    return nil
end

local function InInstance()
    if not _G.IsInInstance then return false end
    local inside, kind = _G.IsInInstance()
    return K.Bool(inside, false) and kind ~= "none"
end

local function UpdateQuest(p)
    if p._friendly or not S.questProgress or not p.unit or InInstance() then
        p.quest:Hide()
        return
    end
    local text = questCache[p.unit]
    if text == nil then
        text = NP.QuestProgress(p.unit) or false
        questCache[p.unit] = text
    end
    if text then
        p.quest:SetText(text)
        p.quest:Show()
    else
        p.quest:Hide()
    end
end

-- Neu lesen nach einer Aenderung des Questlogs: gesammelt, hoechstens
-- einmal je NP.QUEST_DELAY s. C_TooltipInfo.GetUnit legt je Plakette eine
-- grosse Tabelle an - bei jedem QUEST_LOG_UPDATE fuer jede Plakette war das
-- der groesste Teil des Wegwerf-Speichers der Plaketten.
NP.QUEST_DELAY = 0.5
local questQueued = false
local function QuestRefresh()
    questQueued = false
    for _, p in pairs(plates) do UpdateQuest(p) end
end
function NP.QueueQuestRefresh()
    if questQueued then return end
    if _G.C_Timer and _G.C_Timer.After then
        questQueued = true
        _G.C_Timer.After(NP.QUEST_DELAY, QuestRefresh)
    else
        QuestRefresh()
    end
end
NP.QuestRefresh = QuestRefresh

-- Deine Bedrohung auf diesem Gegner: in Prozent (100 % = du hast oder
-- bekommst die Aggro) und seit 6.9.0.8 als Leiste unter dem Leben, dazu
-- wer die Aggro gerade hat. Nur solange du auf seiner Liste stehst. Der
-- Wert kann geheim sein: er geht nur an SetFormattedText und SetValue.
-- Die Farbe folgt der Lage wie die Bedrohungsfarben des Balkens - als Tank
-- gruen, solange du sie haeltst; sonst orange kurz davor, rot mit Aggro.
--
-- 6.10.3.3 (Beta-Test: "schoen waere es, wenn es auch farblich erkannt
-- werden kann"): EINE Farbe der Lage, fuer Leiste, Prozentzahl und - mit
-- "Bedrohungsfarben", seit dieser Fassung ab Werk an - den Lebensbalken.
-- Bis dahin wurde ein DD nur bei Status 1 orange; den gibt es in Classic
-- nur im schmalen Fenster ueber dem Tank, also: grau, grau, rot. Jetzt
-- orange ab NP.WARN % (Status 0, aber nah dran). Der Tank wird orange,
-- wenn der Naechste ab NP.WARN % liegt (oder Status 2), rot, wenn er sie
-- verloren hat. Nil = keine Lage, die eine Farbe verdient.
-- Seit 6.10.3.4 einstellbar ("Warnen ab", threatWarn); NP.WARN ist der
-- Rueckfall, falls die Einstellung fehlt.
NP.WARN = 80
NP.PREVIEW_THREAT = 84     -- das Beispiel in der Vorschau
local function Warn()
    local w = S.threatWarn
    return type(w) == "number" and w or NP.WARN
end
NP.Warn = Warn
function NP.ThreatTint(status, scaled, tank, lead)
    local st = K.Plain(status)
    if type(st) ~= "number" then return nil end
    if tank then
        if st < 2 then return S.dpsAggro end
        if st == 2 or (type(lead) == "number" and lead >= Warn()) then return S.tankLosing end
        return S.tankAggro
    end
    if st >= 2 then return S.dpsAggro end
    local v = K.Plain(scaled)
    if st == 1 or (type(v) == "number" and v >= Warn()) then return S.dpsNear end
    return nil
end

-- Wer den Gegner gerade haelt. In Classic ist das sein Ziel (waehrend
-- eines Zaubers kann es kurz ein anderes sein - dann steht kurz ein
-- anderer Name da, das Spiel sagt es nicht genauer). Nur Freunde unter
-- Spielerkontrolle: ein Gegner, der eine Wache angreift, hat niemandem aus
-- der Gruppe die Aggro genommen. Liefert Einheit, ob du es bist.
function NP.AggroHolder(p, iHold)
    if iHold then return "player", true end
    if p._ttFor ~= p.unit then p._tt, p._ttFor = p.unit .. "target", p.unit end
    local tu = p._tt
    if not K.Bool(_G.UnitExists and _G.UnitExists(tu), false) then return nil end
    if IsUnit(tu, "player") then return "player", true end
    if not K.Bool(_G.UnitPlayerControlled and _G.UnitPlayerControlled(tu), false) then return nil end
    if K.Bool(_G.UnitCanAttack and _G.UnitCanAttack("player", tu), true) then return nil end
    return tu, false
end

-- Unter die Plakette, oder unter den Zauberbalken, wenn er steht.
local function PlaceAggro(p)
    local at = (p.cast and p.cast:IsShown()) and p.cast or (S.threatBar and p.threatBar or p)
    if p._aggroAt == at then return end
    p._aggroAt = at
    p.aggro:ClearAllPoints()
    p.aggro:SetPoint("TOPRIGHT", at, "BOTTOMRIGHT", 0, -1)
end
NP.PlaceAggro = PlaceAggro

local function UpdateAggro(p, onList, iHold)
    local fs = p.aggro
    if S.aggroName == "none" or not onList
        or not K.Bool(_G.IsInGroup and _G.IsInGroup(), false) then
        fs:Hide()
        return
    end
    local u, me = NP.AggroHolder(p, iHold)
    if not u then fs:Hide() return end
    if S.aggroName == "problem" then
        -- Beim Tank liegt sie richtig - dann keine Zeile.
        local role = K.Plain(_G.UnitGroupRolesAssigned and _G.UnitGroupRolesAssigned(u))
        if role == "TANK" then fs:Hide() return end
    end
    local label = WeintCodex.ColorText("textMuted", "Aggro:")
    if me then
        fs:SetText(label .. " Du")
        local c = S.dpsAggro
        if K.Plain(_G.UnitGroupRolesAssigned and _G.UnitGroupRolesAssigned("player")) == "TANK" then c = S.tankAggro end
        fs:SetTextColor(c.r, c.g, c.b, 1)
    else
        local name = _G.UnitName and _G.UnitName(u)
        if type(name) == "nil" then fs:Hide() return end
        fs:SetFormattedText("%s %s", label, name)
        local _, class = _G.UnitClass and _G.UnitClass(u)
        class = K.Plain(class)
        local cc = class and _G.RAID_CLASS_COLORS and _G.RAID_CLASS_COLORS[class]
        if cc then fs:SetTextColor(cc.r, cc.g, cc.b, 1) else fs:SetTextColor(1, 1, 1, 1) end
    end
    PlaceAggro(p)
    fs:Show()
end

-- 6.10.3.2 (Beta-Test: "die Leiste unter der Plakette ist noch nicht
-- richtig gut wegen der Aggro"). Bis dahin zeigte sie immer DEINE
-- Bedrohung - zwei Faelle ohne jede Aussage:
--   allein    ohne Begleiter hast du immer 100 %: an jedem Gegner eine
--             volle rote Leiste. Jetzt keine Leiste, solange niemand da
--             ist, der dir die Aggro abnehmen koennte (Gruppe, Begleiter).
--   als Tank  hast du sie - immer voll gruen. Jetzt zeigt sie, wie nah der
--             Naechste dran ist (sein scaledPercentage auf diesem Gegner:
--             100 = er zieht sie), gruen, ab NP.WARN orange. Gemessen
--             (04.10.2026, Build 70205): die Bedrohung der Mitspieler kommt
--             offen. Ist sie geheim, bleibt es bei deiner eigenen.
local PARTY_UNITS = { "pet", "party1", "party2", "party3", "party4",
    "partypet1", "partypet2", "partypet3", "partypet4" }
local RAID_UNITS = { "pet" }
for i = 1, 40 do RAID_UNITS[#RAID_UNITS + 1] = "raid" .. i end
NP.PARTY_UNITS, NP.RAID_UNITS = PARTY_UNITS, RAID_UNITS

-- Kann dir jemand die Aggro abnehmen?
function NP.Contested()
    -- "Auch allein zeigen" (6.10.3.4): wer es will, bekommt es.
    if S.threatSolo then return true end
    if K.Bool(_G.IsInGroup and _G.IsInGroup(), false) then return true end
    return K.Bool(_G.UnitExists and _G.UnitExists("pet"), false)
end

-- Die hoechste Bedrohung eines anderen auf `unit` (0..100), 0 wenn
-- niemand sonst auf der Liste steht, nil wenn eine davon geheim ist.
function NP.RunnerUp(unit)
    local list = K.Bool(_G.IsInRaid and _G.IsInRaid(), false) and RAID_UNITS or PARTY_UNITS
    local best = 0
    for i = 1, #list do
        local u = list[i]
        if K.Bool(_G.UnitExists and _G.UnitExists(u), false) and not IsUnit(u, "player") then
            local ok, _, _, sc = pcall(_G.UnitDetailedThreatSituation, u, unit)
            if ok and type(sc) ~= "nil" then
                local v = K.Plain(sc)
                if type(v) ~= "number" then return nil end
                if v > best then best = v end
            end
        end
    end
    return best
end

local function UpdateThreatText(p)
    local fs, bar = p.threat, p.threatBar
    if p._friendly or not p.unit or not _G.UnitDetailedThreatSituation then
        fs:Hide() bar:Hide() p.aggro:Hide()
        p._threatTint, p._threatLead = nil, nil
        return
    end
    local ok, tanking, status, scaled = pcall(_G.UnitDetailedThreatSituation, "player", p.unit)
    local onList = ok and type(scaled) ~= "nil"
    local plain = onList and K.Plain(scaled)
    if type(plain) == "number" and plain <= 0 then onList = false end
    local holding = ok and K.Bool(tanking, false)
    -- Farbe nur, wenn dir jemand die Aggro abnehmen kann - allein waere
    -- jeder Gegner rot (immer 100 %).
    local contested = onList and NP.Contested()
    local tank = contested and K.Plain(_G.UnitGroupRolesAssigned and _G.UnitGroupRolesAssigned("player")) == "TANK"
    local lead = nil
    if tank and holding and S.tankLead then lead = NP.RunnerUp(p.unit) end
    local c = contested and NP.ThreatTint(status, scaled, tank, lead) or nil
    p._threatTint, p._threatLead = c, lead

    if onList and S.threatText ~= "none" then
        fs:SetFormattedText("%d%%", scaled)
        if c then fs:SetTextColor(c.r, c.g, c.b, 1) else fs:SetTextColor(1, 1, 1, 1) end
        fs:Show()
    else
        fs:Hide()
    end

    if contested and S.threatBar then
        if lead then bar:SetValue(math.min(lead, 100)) else bar:SetValue(scaled) end
        if c then
            K.PaintBar(bar, c.r, c.g, c.b)
        else
            local low = S.threatLow
            K.PaintBar(bar, low.r, low.g, low.b)
        end
        bar:Show()
    else
        bar:Hide()
    end

    UpdateAggro(p, onList, holding)
end
NP.UpdateThreatText = UpdateThreatText

local function FullUpdate(p)
    UpdateHealth(p, false, true)
    FillTexts(p, false)
    -- Die Lage vor der Farbe: der Lebensbalken nimmt sie (6.10.3.3).
    UpdateThreatText(p)
    UpdateColor(p)
    UpdateTarget(p)
    UpdateRaidIcon(p)
    UpdateQuest(p)
    if p._friendly then return end
    if S.castEnabled then p.cast:Update() else p.cast:Hide() end
end

--------------------------------------------------
-- Zuweisen und Freigeben
--------------------------------------------------

-- Jede Einheit und jede Plakette des Spiels traegt hoechstens eine von
-- uns. Kam ADDED doppelt (Neuladen: die Schleife in Enable UND das
-- Ereignis) oder ohne REMOVED dazwischen, ueberschrieb plates[unit] die
-- alte - die blieb sichtbar an der Plakette des Spiels haengen, bekam nie
-- wieder ein Update und wanderte mit ihr zum naechsten Gegner (Beta-Test:
-- "Geiferzahn" mit 20 % und Zielleuchten ueber einem unberuehrten Vogel).
-- Nur "nameplate1".."nameplateN" duerfen an GetNamePlateForUnit.
local function IsPlateToken(unit)
    return type(unit) == "string" and unit:find("^nameplate%d+$") ~= nil
end
NP.IsPlateToken = IsPlateToken

local Detach
local function Attach(unit)
    if not (_G.C_NamePlate and _G.C_NamePlate.GetNamePlateForUnit) or not IsPlateToken(unit) then return end
    if plates[unit] then Detach(unit) end
    local okNp, nameplate = pcall(_G.C_NamePlate.GetNamePlateForUnit, unit)
    if not okNp or not nameplate then return end
    local prev = byPlate[nameplate]
    if prev and plates[prev] then Detach(prev) end
    -- In Instanzen sind freundliche Plaketten fuer Addons gesperrt
    -- ("forbidden"): dann bleiben die des Spiels, ohne Fehler.
    if nameplate.IsForbidden and nameplate:IsForbidden() then return end
    local friendly = not K.Bool(_G.UnitCanAttack and _G.UnitCanAttack("player", unit), false)
    if friendly and not S.friendlyEnabled then return end

    local p = table.remove(pool) or Build(nameplate)
    p._friendly = friendly
    p:SetParent(nameplate)
    p:ClearAllPoints()
    p:SetPoint("CENTER", nameplate, "CENTER", 0, 0)
    p.unit, p.nameplate = unit, nameplate
    -- Welcher NPC (Kennung, Name, zaubert?) - einmal beim Erscheinen.
    local NC = WeintCodex.UINpcColors
    if NC and not friendly then NC.Identify(p, unit) end
    -- Erst einrichten, dann verbinden: SetUnit zeichnet sofort, wenn der
    -- Gegner schon zaubert.
    Layout(p)
    p.cast:SetUnit(unit)
    if not friendly then p.auras:SetUnit((S.auraEnabled and S.auraSource == "own") and unit or nil) end
    Suppress(nameplate, unit, p)
    plates[unit] = p
    byPlate[nameplate] = unit
    FullUpdate(p)
    p:Show()
end

function Detach(unit)
    local p = plates[unit]
    if not p then return end
    plates[unit] = nil
    if p.nameplate and byPlate[p.nameplate] == unit then byPlate[p.nameplate] = nil end
    questCache[unit] = nil
    if hovered == p then SetHovered(nil) end
    Restore(p.nameplate)
    p.cast:Stop(false)
    p.cast:SetUnit(nil)
    p.auras:SetUnit(nil)
    p.unit, p.nameplate, p._friendly = nil, nil, nil
    p._npcID, p._npcName, p._caster = nil, nil, nil
    NP.trailPending[p] = nil
    p._isTarget = false
    NP.Motion(p, false)
    p:Hide()
    p:SetParent(hidden)
    pool[#pool + 1] = p
end

--------------------------------------------------
-- Ereignisse
--------------------------------------------------

local events = CreateFrame("Frame")

local UNIT_EVENTS = {
    UNIT_HEALTH = function(p) UpdateHealth(p, true) end,
    UNIT_MAXHEALTH = function(p) UpdateHealth(p) end,
    UNIT_NAME_UPDATE = function(p) FillTexts(p, false) UpdateColor(p) end,
    UNIT_LEVEL = function(p) FillTexts(p, false) end,
    UNIT_CLASSIFICATION_CHANGED = function(p) FillTexts(p, false) UpdateColor(p) end,
    UNIT_FLAGS = function(p) UpdateColor(p) end,
    UNIT_THREAT_SITUATION_UPDATE = function(p) UpdateThreatText(p) UpdateColor(p) end,
    UNIT_THREAT_LIST_UPDATE = function(p) UpdateThreatText(p) UpdateColor(p) end,
}

local CAST_EVENTS = {
    UNIT_SPELLCAST_START = "update", UNIT_SPELLCAST_CHANNEL_START = "update",
    UNIT_SPELLCAST_CHANNEL_UPDATE = "update", UNIT_SPELLCAST_DELAYED = "update",
    UNIT_SPELLCAST_INTERRUPTIBLE = "update", UNIT_SPELLCAST_NOT_INTERRUPTIBLE = "update",
    UNIT_SPELLCAST_STOP = "stop", UNIT_SPELLCAST_CHANNEL_STOP = "stop",
    UNIT_SPELLCAST_INTERRUPTED = "failed", UNIT_SPELLCAST_FAILED = "failed",
}

local function OnEvent(_, event, unit)
    if event == "NAME_PLATE_UNIT_ADDED" then
        Attach(unit)
        return
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        Detach(unit)
        return
    elseif event == "UNIT_FACTION" then
        -- Wird ein Freund zum Feind (oder umgekehrt), wechselt die Plakette.
        -- UNIT_FACTION kommt fuer JEDE Einheit (auch "partypet4"), und
        -- GetNamePlateForUnit wirft bei Gruppen- und Schlachtzugskennungen
        -- einen Fehler (Beta-Test 6.3.2.2, 14x). Gefragt wird nur fuer
        -- "nameplateN".
        if IsPlateToken(unit) and _G.C_NamePlate and _G.C_NamePlate.GetNamePlateForUnit then
            local ok, np = pcall(_G.C_NamePlate.GetNamePlateForUnit, unit)
            if ok and np then
                Detach(unit)
                Attach(unit)
            end
        end
        return
    elseif event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_FOCUS_CHANGED" then
        anyTarget = K.Bool(_G.UnitExists and _G.UnitExists("target"), false)
        for _, p in pairs(plates) do
            UpdateTarget(p)
            UpdateColor(p)
        end
        return
    elseif event == "RAID_TARGET_UPDATE" then
        for _, p in pairs(plates) do UpdateRaidIcon(p) end
        return
    elseif event == "UPDATE_MOUSEOVER_UNIT" then
        local found
        if S.hover and K.Bool(_G.UnitExists and _G.UnitExists("mouseover"), false) then
            for _, p in pairs(plates) do
                if not p._friendly and IsUnit(p.unit, "mouseover") then found = p break end
            end
        end
        SetHovered(found)
        return
    elseif event == "QUEST_LOG_UPDATE" or event == "UNIT_QUEST_LOG_CHANGED" then
        -- Das Spiel meldet das in Schueben (Pluendern, jedes Questziel); je
        -- Schub liest der Tooltip jeder Plakette nur einmal neu.
        wipe(questCache)
        NP.QueueQuestRefresh()
        return
    end

    local p = unit and plates[unit]
    if not p then return end

    -- Der Gegner wechselt mitten im Zauber sein Ziel: das Ziel im Balken mit.
    if event == "UNIT_TARGET" then
        if not p._friendly and p.cast:IsShown() then p.cast:UpdateTarget() end
        -- Neues Ziel des Gegners: vielleicht hat jetzt jemand anderes die Aggro.
        if not p._friendly and S.aggroName ~= "none" then UpdateThreatText(p) end
        return
    end

    local handler = UNIT_EVENTS[event]
    if handler then handler(p) return end

    local cast = CAST_EVENTS[event]
    -- Wer einen Zauber mit Zauberzeit beginnt, zaehlt ab jetzt als
    -- Zaubernder (6.6.2.2) - auch ohne Zauberbalken.
    if (event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START") and not p._friendly then
        local NC = WeintCodex.UINpcColors
        if NC and NC.SawCast(p) then UpdateColor(p) end
    end
    if cast and S.castEnabled then
        if cast == "update" then
            p.cast:Update()
        else
            p.cast:Stop(cast == "failed")
        end
        -- "Aggro: …" weicht dem Zauberbalken aus.
        if p.aggro:IsShown() then PlaceAggro(p) end
    end
end

-- Ereignisse, die ein Client nicht kennt, wirft RegisterEvent als
-- Fehler. Forever ist ungeprueft, also wird jedes einzeln versucht.
local function Register(frame, name)
    local ok = pcall(frame.RegisterEvent, frame, name)
    return ok
end

--------------------------------------------------
-- Einstellungen, die das Spiel selbst haelt (CVars)
--------------------------------------------------
-- Diese drei schreibt die Seite direkt in die Spieleinstellungen - sie
-- gelten also auch, wenn das Modul aus ist, genau wie im Spielmenue.

local function GetCVar(name)
    if _G.C_CVar and _G.C_CVar.GetCVar then return _G.C_CVar.GetCVar(name) end
    if _G.GetCVar then return _G.GetCVar(name) end
    return nil
end

local function SetCVar(name, value)
    if K.InCombat() then return end
    if _G.C_CVar and _G.C_CVar.SetCVar then
        pcall(_G.C_CVar.SetCVar, name, value)
    elseif _G.SetCVar then
        pcall(_G.SetCVar, name, value)
    end
end

NP.GetCVar, NP.SetCVar = GetCVar, SetCVar

--------------------------------------------------
-- Vorschau im Einstellungsfenster
--------------------------------------------------

local preview
function NP.CreatePreview(parent)
    Resolve()
    local host = CreateFrame("Frame", nil, parent)
    host:SetHeight(92)
    local p = Build(host)
    p:SetPoint("CENTER", host, "CENTER", 0, 8)
    preview = p
    NP.RefreshPreview()
    return host, 92
end

NP.PreviewPlate = function() return preview end

function NP.RefreshPreview()
    local p = preview
    if not p then return end
    Resolve()
    Layout(p)
    p.health:SetMinMaxValues(0, 100)
    p.health:SetValue(64)
    local kinds = { top = S.textTop, left = S.textLeft, right = S.textRight, center = S.textCenter }
    local sample = {
        name = "Kobold-Tunnelgräber", level = S.eliteMark and "14+" or "14",
        healthPercent = "64%", healthNumber = "1,2 Tsd", healthBoth = "1,2 Tsd  64%",
    }
    sample.levelName = sample.level .. "  " .. sample.name
    for slot, kind in pairs(kinds) do
        local fs = p.texts[slot]
        if kind == "none" then
            fs:Hide()
        else
            fs:SetText(sample[kind] or "")
            if kind == "level" and S.levelColor then
                fs:SetTextColor(1, 0.82, 0, 1)
            else
                fs:SetTextColor(1, 1, 1, 1)
            end
            fs:Show()
        end
    end
    -- Das Beispiel: ein DD bei 84 %, gefaerbt wie im Kampf - so zeigt die
    -- Vorschau, was "Warnen ab" und die Farben tun (6.10.3.4).
    local sample = NP.ThreatTint(0, NP.PREVIEW_THREAT, false, nil)
    local low = S.threatLow
    if S.threatText ~= "none" then
        p.threat:SetText(NP.PREVIEW_THREAT .. "%")
        if sample then p.threat:SetTextColor(sample.r, sample.g, sample.b, 1) else p.threat:SetTextColor(1, 1, 1, 1) end
        p.threat:Show()
    else
        p.threat:Hide()
    end
    -- Bedrohungsleiste und "Aggro: …" im Beispiel (6.9.0.8).
    if S.threatBar then
        p.threatBar:SetValue(NP.PREVIEW_THREAT)
        local c = sample or low
        K.PaintBar(p.threatBar, c.r, c.g, c.b)
        p.threatBar:Show()
    else
        p.threatBar:Hide()
    end
    if S.aggroName ~= "none" then
        p.aggro:SetText(WeintCodex.ColorText("textMuted", "Aggro:") .. " Tamsin")
        local mc = _G.RAID_CLASS_COLORS and _G.RAID_CLASS_COLORS.MAGE
        if mc then p.aggro:SetTextColor(mc.r, mc.g, mc.b, 1) else p.aggro:SetTextColor(1, 1, 1, 1) end
        p._aggroAt = nil
        NP.PlaceAggro(p)
        p.aggro:Show()
    else
        p.aggro:Hide()
    end
    local c = S.eliteColoring and S.elite or S.enemyInCombat
    K.PaintBar(p.health, c.r, c.g, c.b)
    PaintBg(p, c.r, c.g, c.b)
    -- Die Vorschau zeigt die Plakette als Ziel: so sieht man, was die
    -- Einstellungen zu Leuchten, Marken und Rand tun.
    local style = S.targetStyle
    local glow = style == "glow" or style == "both"
    p.ring:SetShown(style == "ring" or style == "both")
    p.glow:SetShown(glow)
    p.glowWide:SetShown(glow)
    for _, m in ipairs(p.marks) do m:SetShown(glow) end
    -- Spur und Bewegung wie am Ziel: 64 % Leben, die Spur bei 78 %.
    p.trail:SetMinMaxValues(0, 100)
    p.trail:SetValue(S.damageTrail and 78 or 64)
    NP.Motion(p, true, glow)
    p:SetScale(S.targetScale / 100)
    if S.raidMarker ~= "none" then K.ShowRaidIndex(p.raid, 8) else p.raid:Hide() end
    if S.castEnabled then p.cast:ShowPreview(true) else p.cast:ShowPreview(false) end
end

--------------------------------------------------
-- Modul
--------------------------------------------------

local function Enable()
    NP.MigrateMotion()
    Resolve()
    for _, e in ipairs({
        "NAME_PLATE_UNIT_ADDED", "NAME_PLATE_UNIT_REMOVED", "UNIT_FACTION",
        "PLAYER_TARGET_CHANGED", "PLAYER_FOCUS_CHANGED", "RAID_TARGET_UPDATE",
        "QUEST_LOG_UPDATE", "UNIT_QUEST_LOG_CHANGED", "UPDATE_MOUSEOVER_UNIT", "UNIT_TARGET",
    }) do Register(events, e) end
    for e in pairs(UNIT_EVENTS) do Register(events, e) end
    for e in pairs(CAST_EVENTS) do Register(events, e) end
    events:SetScript("OnEvent", K.Measured("Plaketten", OnEvent))

    -- Plaketten, die beim Einschalten schon stehen (Neuladen mitten in
    -- der Welt), bekommen kein ADDED mehr.
    if _G.C_NamePlate and _G.C_NamePlate.GetNamePlates then
        for _, np in ipairs(_G.C_NamePlate.GetNamePlates() or {}) do
            local unit = np.namePlateUnitToken
                or (np.UnitFrame and np.UnitFrame.unit)
            if unit then Attach(unit) end
        end
    end
end

-- Farben aller Plaketten neu (NPC-Regeln geaendert).
function NP.RecolorAll()
    for _, p in pairs(plates) do UpdateColor(p) end
end

local function OnSetting()
    Resolve()
    for unit, p in pairs(plates) do
        Layout(p)
        FullUpdate(p)
        -- Quelle der Symbole kann gewechselt haben: neu verteilen.
        if not p._friendly then
            p.auras:SetUnit((S.auraEnabled and S.auraSource == "own") and unit or nil)
            Suppress(p.nameplate, unit, p)
        end
    end
    NP.RefreshPreview()
end

local function CVarToggle(label, cvar, onValue, offValue, tooltip)
    return {
        type = "toggle", label = label, tooltip = tooltip,
        get = function() return GetCVar(cvar) == onValue end,
        set = function(on) SetCVar(cvar, on and onValue or offValue) end,
        disabled = function() return GetCVar(cvar) == nil end,
        disabledHint = "Diese Spieleinstellung kennt der Client nicht.",
    }
end

local SLOT_ITEMS = {
    { value = "none",          text = "Nichts" },
    { value = "name",          text = "Name" },
    { value = "levelName",     text = "Stufe und Name" },
    { value = "level",         text = "Stufe" },
    { value = "healthPercent", text = "Leben in %" },
    { value = "healthNumber",  text = "Leben als Zahl" },
    { value = "healthBoth",    text = "Leben: Zahl und %" },
}

local function pct(v) return string.format("%d %%", v) end
local function px(v) return string.format("%d px", v) end

-- "Name steht": eine Voreinstellung fuer die vier Textplaetze (Beta-Test:
-- "den Namen auch in die Plakette statt darueber setzen").
local NAME_PRESETS = {
    above  = { textTop = "name", textLeft = "level",     textCenter = "none", textRight = "healthPercent" },
    left   = { textTop = "none", textLeft = "levelName", textCenter = "none", textRight = "healthPercent" },
    center = { textTop = "none", textLeft = "level",     textCenter = "name", textRight = "healthPercent" },
}
local NAME_PLACES = {
    { value = "above",  text = "Über der Plakette" },
    { value = "left",   text = "Im Balken, links (mit Stufe)" },
    { value = "center", text = "Im Balken, mittig" },
    { value = "custom", text = "Eigene Belegung" },
}
function NP.NamePlace()
    for place, preset in pairs(NAME_PRESETS) do
        local same = true
        for k, v in pairs(preset) do
            if K.Get(KEY, k) ~= v then same = false break end
        end
        if same then return place end
    end
    return "custom"
end
function NP.SetNamePlace(place)
    local preset = NAME_PRESETS[place]
    if not preset then return end
    for k, v in pairs(preset) do K.Set(KEY, k, v) end
end

K.Register({
    key = KEY, group = "ui", order = 10,
    title = "Namensplaketten",
    description = "Eigene Plaketten: Gegner mit Farben nach Lage, Stufe, Debuffs, Zauberbalken und Zielrahmen; Freunde als Name in Klassenfarbe.",
    defaults = defaults,
    Enable = Enable,
    OnSetting = OnSetting,
    preview = NP.CreatePreview,
    pages = {
        { key = "allgemein", label = "Allgemein", build = function(B)
            B:Section("Größe")
            B:Row({ type = "slider", label = "Breite", key = "width", min = 80, max = 250, step = 1, format = px },
                  { type = "slider", label = "Höhe", key = "height", min = 6, max = 30, step = 1, format = px })
            B:Section("Ziel")
            B:Row({ type = "slider", label = "Größe des Ziels", key = "targetScale", min = 100, max = 150, step = 5, format = pct },
                  { type = "slider", label = "Deckkraft der anderen", key = "nonTargetAlpha", min = 30, max = 100, step = 5, format = pct,
                    tooltip = "Wie sichtbar die übrigen Plaketten sind, solange du ein Ziel hast." })
            B:Row({ type = "dropdown", label = "Ziel hervorheben", key = "targetStyle", items = {
                        { value = "glow", text = "Leuchten und Zielmarken" },
                        { value = "ring", text = "Weißer Rand" },
                        { value = "both", text = "Beides" },
                        { value = "none", text = "Gar nicht" } } },
                  { type = "toggle", label = "Maus hebt hervor", key = "hover",
                    description = "Die Plakette unter der Maus hellt auf und kommt nach vorn." })
            B:Section("Bewegung", "Nur am Ziel und bei Treffern – alle anderen Plaketten bleiben still.")
            B:Row({ type = "dropdown", label = "Bewegung", key = "motion", items = {
                        { value = "calm",   text = "Ruhig" },
                        { value = "lively", text = "Lebendig" },
                        { value = "custom", text = "Eigene (unter „Erweitert“)" } },
                    description = "Ruhig: das Ziel leuchtet, aber nichts atmet, glänzt oder blitzt. Lebendig: Leuchten atmet, Glanz läuft, Treffer blitzen, Zielmarken bewegen sich." },
                  { type = "toggle", label = "Schadensspur", key = "damageTrail",
                    description = "Was ein Treffer nimmt, bleibt einen Moment hell stehen und schmilzt dann weg." })
            B:Row({ type = "toggle", label = "Weiche Balken", key = "smoothBars",
                    description = "Das Leben gleitet zum neuen Wert, statt zu springen – wenn der Client es kann." },
                  { type = "toggle", label = "Ziel: Kante in Klassenfarbe", key = "targetEdge" })
            B:Section("Spieleinstellungen",
                "Diese Schalter ändern die Einstellung des Spiels selbst und gelten deshalb auch ohne WeintCodex-Plaketten.")
            B:Row(CVarToggle("Plaketten stapeln", "nameplateMotion", "1", "0",
                    "An: Plaketten weichen einander aus. Aus: sie dürfen sich überlappen."),
                  CVarToggle("Gegnerische Begleiter", "nameplateShowEnemyPets", "1", "0"))
            B:Row(CVarToggle("Gegnerische Diener", "nameplateShowEnemyMinions", "1", "0"),
                  { type = "empty" })
            B:Advanced()
            B:Section("Bewegung einzeln", "Gilt nur mit „Bewegung: Eigene“.")
            local notCustom = function() return K.Get(KEY, "motion") ~= "custom" end
            local glowOff = function()
                local s = K.Get(KEY, "targetStyle")
                return notCustom() or (s ~= "glow" and s ~= "both")
            end
            B:Row({ type = "toggle", label = "Ziel: Leuchten atmet", key = "targetPulse", disabled = glowOff },
                  { type = "toggle", label = "Ziel: Glanz läuft über den Balken", key = "targetSheen", disabled = notCustom })
            B:Row({ type = "toggle", label = "Ziel: Treffer blitzt", key = "hitFlash", disabled = notCustom,
                    description = "Auch eine Heilung blitzt – ob das Leben sank oder stieg, verrät der Client nicht." },
                  { type = "toggle", label = "Zielmarken bewegen sich", key = "markMotion", disabled = glowOff })
            B:Section("Hinrichtungsmarke",
                "Ein fester Strich im Balken zeigt, ab wann Fähigkeiten wie Hinrichten wirken.")
            B:Row({ type = "toggle", label = "Anzeigen", key = "executeMark" },
                  { type = "slider", label = "Bei", key = "executeAt", min = 5, max = 50, step = 5, format = pct,
                    disabled = function() return not K.Get(KEY, "executeMark") end })
            B:Section("Fläche")
            B:Row({ type = "toggle", label = "Weicher Schatten", key = "shadow" },
                  { type = "toggle", label = "Grund in der Gegnerfarbe", key = "tintedBg",
                    description = "Fehlendes Leben dunkel in der Farbe des Balkens statt schwarz." })
            B:Row({ type = "toggle", label = "Rand anzeigen", key = "showBorder" },
                  { type = "color", label = "Randfarbe", key = "borderColor",
                    disabled = function() return not K.Get(KEY, "showBorder") end })
            B:Row({ type = "color", label = "Hintergrund", key = "bgColor" }, { type = "empty" })
        end },
        { key = "farben", label = "Bedrohung & Farben", build = function(B)
            B:Section("Bedrohung",
                "Ob du Tank bist, liest WeintCodex aus der zugewiesenen Gruppenrolle. Ohne zugewiesene Rolle gelten die Farben für Schaden und Heilung.")
            B:Row({ type = "toggle", label = "Bedrohungsfarben", key = "threatColors",
                    description = "Der Lebensbalken nimmt die Farbe der Lage an, sobald sie zählt – dieselbe wie Leiste und Prozentzahl (Farben unten)." },
                  { type = "dropdown", label = "Bedrohung in %", key = "threatText", items = {
                        { value = "right",   text = "Rechts neben dem Balken" },
                        { value = "topleft", text = "Oben links" },
                        { value = "none",    text = "Aus" } },
                    description = "Deine Bedrohung auf diesem Gegner; 100 % heißt: du hast die Aggro. Nur im Kampf und solange du auf seiner Liste stehst." })
            B:Row({ type = "dropdown", label = "Wer die Aggro hat", key = "aggroName", items = {
                        { value = "problem", text = "Wenn nicht beim Tank" },
                        { value = "always",  text = "Immer" },
                        { value = "none",    text = "Aus" } },
                    description = "Name unter der Plakette, nur in einer Gruppe. „Wenn nicht beim Tank“: nur wenn jemand ohne Tankrolle den Gegner hält – auch du selbst („Aggro: Du“). Ohne zugewiesene Rollen erscheint der Name immer." },
                  { type = "empty" })
            local noBar = function() return not K.Get(KEY, "threatBar") end
            B:Section("Bedrohungsleiste", "Dünne Leiste unter dem Leben: voll heißt, du ziehst die Aggro.")
            B:Row({ type = "toggle", label = "Bedrohungsleiste", key = "threatBar" },
                  { type = "slider", label = "Höhe der Leiste", key = "threatBarHeight", min = 2, max = 6, step = 1,
                    format = function(v) return string.format("%d px", v) end, disabled = noBar })
            B:Row({ type = "slider", label = "Warnen ab", key = "threatWarn", min = 50, max = 100, step = 5,
                    format = function(v) return string.format("%d %%", v) end,
                    description = "Ab hier „kurz davor“: als DD deine Bedrohung, als Tank die des Nächsten. Gilt für Leiste, Prozentzahl und Lebensbalken." },
                  { type = "toggle", label = "Auch allein zeigen", key = "threatSolo",
                    description = "Ohne Gruppe und Begleiter hast du die Aggro immer (100 %) – deshalb ab Werk aus. An: Leiste und Farben auch dann." })
            B:Row({ type = "toggle", label = "Als Tank: den Nächsten zeigen", key = "tankLead",
                    description = "An: die Leiste zeigt, wie nah der Nächste an deiner Aggro ist. Aus: deine eigene Bedrohung – als Tank meist voll." },
                  { type = "empty" })
            local noThreat = function() return not (K.Get(KEY, "threatColors") or K.Get(KEY, "threatBar") or K.Get(KEY, "threatText") ~= "none") end
            B:Section("Farben der Bedrohung", "Für Leiste, Prozentzahl und – mit Bedrohungsfarben – den Lebensbalken.")
            B:Row({ type = "color", label = "Aggro gezogen", key = "dpsAggro", disabled = noThreat },
                  { type = "color", label = "Kurz davor", key = "dpsNear", disabled = noThreat })
            B:Row({ type = "color", label = "Tank: hält die Aggro", key = "tankAggro", disabled = noThreat },
                  { type = "color", label = "Tank: der Nächste ist nah", key = "tankLosing", disabled = noThreat })
            B:Row({ type = "color", label = "Weit weg (nur Leiste)", key = "threatLow", disabled = noBar },
                  { type = "empty" })
            B:Advanced()
            B:Section("Gegner")
            B:Row({ type = "color", label = "Feind im Kampf", key = "enemyInCombat" },
                  { type = "color", label = "Feind außerhalb des Kampfes", key = "hostile",
                    disabled = function() return not K.Get(KEY, "darkenOOC") end })
            B:Row({ type = "toggle", label = "Feinde außer Kampf abdunkeln", key = "darkenOOC",
                    description = "Wer (noch) nicht kämpft, trägt die dunklere Farbe." },
                  { type = "color", label = "Neutral", key = "neutral" })
            B:Row({ type = "color", label = "Von anderen markiert", key = "tapped" },
                  { type = "color", label = "Boss", key = "boss" })
            B:Row({ type = "toggle", label = "Elite eigens färben", key = "eliteColoring" },
                  { type = "color", label = "Elite", key = "elite",
                    disabled = function() return not K.Get(KEY, "eliteColoring") end })
            B:Row({ type = "toggle", label = "Spieler in Klassenfarbe", key = "classColorPlayers" },
                  { type = "empty" })
            B:Section("Ziel und Fokus")
            B:Row({ type = "toggle", label = "Fokus eigens färben", key = "focusColorEnabled" },
                  { type = "color", label = "Fokus", key = "focus",
                    disabled = function() return not K.Get(KEY, "focusColorEnabled") end })
            B:Row({ type = "toggle", label = "Ziel eigens färben", key = "targetColorEnabled" },
                  { type = "color", label = "Ziel", key = "target",
                    disabled = function() return not K.Get(KEY, "targetColorEnabled") end })
        end },
        { key = "texte", label = "Texte", build = function(B)
            B:Section("Name")
            B:Row({ type = "dropdown", label = "Name steht", items = NAME_PLACES,
                    get = NP.NamePlace, set = NP.SetNamePlace,
                    description = "Stellt die Textplätze unten passend ein; dort lässt sich alles weiter einzeln belegen." },
                  { type = "empty" })
            B:Advanced()
            B:Section("Textplätze")
            B:Row({ type = "dropdown", label = "Oben", key = "textTop", items = SLOT_ITEMS },
                  { type = "dropdown", label = "Mitte", key = "textCenter", items = SLOT_ITEMS })
            B:Row({ type = "dropdown", label = "Links", key = "textLeft", items = SLOT_ITEMS },
                  { type = "dropdown", label = "Rechts", key = "textRight", items = SLOT_ITEMS })
            B:Row({ type = "slider", label = "Schriftgröße oben", key = "nameSize", min = 8, max = 18, step = 1, format = px },
                  { type = "slider", label = "Schriftgröße im Balken", key = "textSize", min = 7, max = 16, step = 1, format = px })
            B:Section("Stufe")
            B:Row({ type = "toggle", label = "Stufe nach Schwierigkeit färben", key = "levelColor" },
                  { type = "toggle", label = "Elite mit + kennzeichnen", key = "eliteMark" })
            B:Section("Schlachtzugsmarkierung")
            B:Row({ type = "dropdown", label = "Position", key = "raidMarker", items = {
                        { value = "topright", text = "Oben rechts" },
                        { value = "top",      text = "Über dem Namen" },
                        { value = "left",     text = "Links" },
                        { value = "right",    text = "Rechts" },
                        { value = "none",     text = "Aus" } } },
                  { type = "slider", label = "Größe", key = "raidMarkerSize", min = 12, max = 40, step = 1, format = px,
                    disabled = function() return K.Get(KEY, "raidMarker") == "none" end })
        end },
        { key = "auren", label = "Auren", build = function(B)
            local off = function() return not K.Get(KEY, "auraEnabled") end
            local own = function() return off() or K.Get(KEY, "auraSource") ~= "own" end
            B:Section("Debuffs über der Plakette")
            B:Row({ type = "dropdown", label = "Symbole", key = "auraSource", disabled = off, items = {
                        { value = "game", text = "Die des Spiels (verlässlich)" },
                        { value = "own",  text = "Eigene von WeintCodex" } } },
                  { type = "slider", label = "Größe der Symbole des Spiels", key = "gameAuraScale", min = 60, max = 160, step = 5,
                    format = pct, disabled = function() return off() or K.Get(KEY, "auraSource") ~= "game" end })
            B:Note("„Die des Spiels“ zeigt die Debuff-Symbole der Plakette des Spiels an ihrem Platz über der WeintCodex-Plakette – das Spiel pflegt sie selbst, WeintCodex blendet nur den Rest der Spielplakette aus. Die eigenen Symbole (mit Restzeit oben links) zeigten im Beta-Client bisher keine Debuffs; sie bleiben wählbar, bis klar ist, woran es liegt.")
            B:Row({ type = "toggle", label = "Debuffs anzeigen", key = "auraEnabled" },
                  { type = "toggle", label = "Nur meine", key = "auraOnlyMine", disabled = own,
                    description = "Aus: alle Debuffs, auch die anderer Spieler (nur eigene Symbole)." })
            B:Row({ type = "slider", label = "Symbolgröße", key = "auraSize", min = 14, max = 40, step = 1, format = px, disabled = own },
                  { type = "slider", label = "Höchstens", key = "auraMax", min = 1, max = 10, step = 1,
                    format = function(v) return tostring(v) end, disabled = own })
            B:Row({ type = "toggle", label = "Restzeit am Symbol", key = "auraTimer", disabled = own,
                    description = "Die verbleibenden Sekunden oben links." },
                  { type = "dropdown", label = "Ausrichtung", key = "auraAlign", disabled = off, items = {
                        { value = "left",   text = "Links" },
                        { value = "center", text = "Mittig" },
                        { value = "right",  text = "Rechts" } },
                    description = "Bei den Symbolen des Spiels ein Versuch: ob es klappt, sagt /wcui auren." })
            B:Section("Quests")
            B:Row({ type = "toggle", label = "Questfortschritt neben dem Namen", key = "questProgress",
                    description = "„8/10“, wenn der Gegner zu einer deiner Quests gehört. Nicht in Dungeons." },
                  { type = "empty" })
            B:Note("Auf dem neuen Client liest das Spiel die Auren selbst und reicht sie an die Plakette – WeintCodex sieht sie dabei nicht. Deshalb gibt es hier keine Liste einzelner Zauber zum Ein- und Ausblenden.")
            B:Advanced()
            B:Section("Zustand",
                "Gilt für alle Auren: Plaketten, Zielrahmen, Gruppe. Wirkt sofort. Erscheinen keine Debuffs, hier den anderen Weg wählen und mit einem Gegner als Ziel /wcui auren eingeben – die Zeilen im Chat sagen, woran es liegt.")
            B:Row({ type = "dropdown", label = "Weg", items = {
                        { value = "auto",   text = "Automatisch" },
                        { value = "engine", text = "Container des Spiels" },
                        { value = "legacy", text = "Selbst lesen (alter Weg)" } },
                    get = function() return WeintCodex.UIAuras.mode end,
                    set = function(v) WeintCodex.UIAuras.SetMode(v) end },
                  { type = "empty" })
            B:Note(WeintCodex.UIAuras.StatusText())
        end },
        { key = "freundlich", label = "Freundlich", build = function(B)
            local off = function() return not K.Get(KEY, "friendlyEnabled") end
            B:Section("Freundliche Plaketten",
                "In Dungeons und Schlachtzügen sperrt das Spiel freundliche Plaketten für Addons – dort bleiben die des Spiels.")
            B:Row({ type = "toggle", label = "WeintCodex-Plaketten auch für Freunde", key = "friendlyEnabled" },
                  { type = "toggle", label = "Mit Lebensbalken", key = "friendlyHealth", disabled = off,
                    description = "Aus: nur der Name." })
            B:Row({ type = "toggle", label = "Spieler in Klassenfarbe", key = "friendlyClassColor", disabled = off },
                  { type = "color", label = "Farbe sonst", key = "friendlyColor", disabled = off })
            B:Row({ type = "slider", label = "Schriftgröße", key = "friendlyNameSize", min = 8, max = 20, step = 1, format = px, disabled = off },
                  { type = "empty" })
            B:Row(CVarToggle("Freundliche Spieler zeigen", "nameplateShowFriends", "1", "0"),
                  CVarToggle("Freundliche NPCs zeigen", "nameplateShowFriendlyNPCs", "1", "0"))
        end },
        { key = "zauber", label = "Zauberbalken", build = function(B)
            local off = function() return not K.Get(KEY, "castEnabled") end
            B:Section("Zauberbalken")
            B:Row({ type = "toggle", label = "Zauberbalken anzeigen", key = "castEnabled" },
                  { type = "slider", label = "Höhe", key = "castHeight", min = 8, max = 30, step = 1, format = px, disabled = off })
            B:Row({ type = "toggle", label = "Zaubersymbol", key = "castIcon", disabled = off },
                  { type = "toggle", label = "Restzeit", key = "castTimer", disabled = off })
            B:Row({ type = "toggle", label = "Ziel des Zaubers", key = "castTarget", disabled = off,
                    description = "Rechts im Balken, auf wen der Gegner zaubert – „Dich“ in Rot, Spieler in Klassenfarbe." },
                  { type = "empty" })
            B:Advanced()
            B:Section("Unterbrechen")
            B:Row({ type = "color", label = "Unterbrechbar", key = "castColor", disabled = off },
                  { type = "color", label = "Nicht unterbrechbar", key = "castLocked", disabled = off })
            B:Row({ type = "toggle", label = "Rahmen, wenn nicht unterbrechbar", key = "castShield", disabled = off,
                    description = "Ein heller Rand zusätzlich zur Farbe." },
                  { type = "empty" })
        end },
    },
})
