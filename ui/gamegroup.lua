--------------------------------------------------
-- WeintCodex :: Oberflaeche - Gruppenrahmen des Spiels im WeintCodex-Stil
--------------------------------------------------
-- Beta-Test 6.6.0.8: "Schilde, Buffs, Heilung, HoTs werden im Gruppenframe
-- nicht angezeigt." Das liegt nicht an einem vergessenen Schalter: Forever
-- gibt Addons im Kampf keine Auren heraus ("Auras cannot be accessed when
-- secret while tainted", gemessen 6.6.0.2/6.6.0.3), und ein eigener
-- Aurenbehaelter bleibt sogar ausserhalb des Kampfes leer. Eigene Rahmen
-- koennen HoTs im Kampf also nicht zeigen - nur die Rahmen des Spiels, die
-- ihre Auren in geschuetztem Code lesen.
--
-- DESHALB (Wahl des Spielers): die Gruppen- und Schlachtzugsrahmen des
-- Spiels (CompactUnitFrame) bleiben an, und WeintCodex zeichnet sie neu -
-- wie den Abklingzeitmanager (ui/cooldowns.lua):
--   * Lebens- und Kraftbalken mit der Balkentextur der Oberflaeche,
--   * Grund dunkel wie die Kacheln, Blizzards Rahmenlinien weg, 1-px-Rand,
--   * Name und Status in der WeintCodex-Schrift,
--   * Aurensymbole eckig beschnitten.
-- Was die Rahmen zeigen (HoTs, Buffs, Schilde, bannbare Debuffs,
-- eingehende Heilung, Rolle), bleibt das Spiel - genau das ist der Sinn.
-- Kein Feld am Rahmen des Spiels wird geschrieben, nur Methoden gerufen;
-- neue Rahmen meldet ein hooksecurefunc auf die Einrichtung des Spiels.
-- Die Lage und Groesse bestimmt der Bearbeitungsmodus des Spiels.
--
-- IN DER GRUPPE braucht das Spiel "Schlachtzugsartige Gruppenrahmen"
-- (Bearbeitungsmodus -> Gruppenrahmen): die klassischen Gruppenrahmen
-- zeigen keine HoTs. Das stellt WeintCodex nicht selbst um - wer die
-- Einstellungen des Bearbeitungsmodus aus einem Addon schreibt, macht ihn
-- unsicher -, sondern sagt es einmal im Chat.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIGameGroup = {}

local GG = WeintCodex.UIGameGroup
local K = WeintCodex.UIKit
local KEY = "groupframes"

local function Opt(k) return K.Get(KEY, k) end

local styled = setmetatable({}, { __mode = "k" })   -- [Rahmen des Spiels] = unsere Teile
GG.styled = styled
GG.state = "nicht verwendet"

-- Die Rahmen des Spiels, die gerade existieren (sie entstehen erst, wenn
-- eine Gruppe sie braucht).
function GG.Frames()
    local out, seen = {}, {}
    local function add(f)
        if type(f) == "table" and not seen[f] and f.GetObjectType
           and not (f.IsForbidden and f:IsForbidden()) then
            seen[f] = true
            out[#out + 1] = f
        end
    end
    for i = 1, 5 do
        add(_G["CompactPartyFrameMember" .. i])
        add(_G["CompactPartyFramePet" .. i])
    end
    for i = 1, 80 do add(_G["CompactRaidFrame" .. i]) end
    for g = 1, 8 do
        for m = 1, 5 do add(_G["CompactRaidGroup" .. g .. "Member" .. m]) end
    end
    -- Heissen die Rahmen im Forever-Client anders: in den Behaeltern des
    -- Spiels suchen, was einen Lebensbalken hat (6.6.1.0).
    local function walk(parent, depth)
        if depth > 3 or type(parent) ~= "table" or not parent.GetChildren then return end
        if parent.IsForbidden and parent:IsForbidden() then return end
        local ok, kids = pcall(function() return { parent:GetChildren() } end)
        if not ok then return end
        for _, ch in ipairs(kids) do
            if type(ch) == "table" and type(ch.healthBar) == "table" then add(ch) else walk(ch, depth + 1) end
        end
    end
    walk(_G.CompactPartyFrame, 1)
    walk(_G.CompactRaidFrameContainer, 1)
    return out
end

-- Klassenfarbe wie auf den eigenen Kacheln (6.6.1.0, Beta-Test: "sieht
-- nicht so aus wie bei meinem Krieger" - das Spiel faerbt ohne seine
-- Einstellung "Klassenfarben anzeigen" alles gruen). Nur ueber die
-- Methode des Balkens; die Zwischenablage des Spiels (healthBar.r/g/b)
-- bleibt unberuehrt - aendert das Spiel die Farbe (offline, tot), setzt
-- es sie selbst, und der Haken faerbt danach wieder ein.
function GG.Color(f)
    if type(f) ~= "table" or (f.IsForbidden and f:IsForbidden()) then return end
    local hb = f.healthBar
    if type(hb) ~= "table" or not hb.SetStatusBarColor then return end
    local unit = f.displayedUnit
    if type(unit) ~= "string" then unit = f.unit end
    if type(unit) ~= "string" then return end
    if not K.Bool(_G.UnitIsPlayer and _G.UnitIsPlayer(unit), false) then return end
    if not K.Bool(_G.UnitIsConnected and _G.UnitIsConnected(unit), true) then return end
    if K.Bool(_G.UnitIsDeadOrGhost and _G.UnitIsDeadOrGhost(unit), false) then return end
    local r, g, b
    if Opt("classColor") then
        local _, class = _G.UnitClass(unit)
        class = K.Plain(class)
        local cc = class and _G.RAID_CLASS_COLORS and _G.RAID_CLASS_COLORS[class]
        if cc then r, g, b = cc.r, cc.g, cc.b end
    end
    if not r then
        local c = K.GetColor(KEY, "healthColor")
        r, g, b = c.r, c.g, c.b
    end
    pcall(hb.SetStatusBarColor, hb, r, g, b)
end

local function Hide(r)
    if type(r) ~= "table" or not r.SetAlpha then return end
    local AB = WeintCodex.UIActionBars
    if AB and AB.KeepHidden then AB.KeepHidden(r) else r:SetAlpha(0) end
end

local function Crop(list)
    if type(list) ~= "table" then return end
    for _, b in ipairs(list) do
        local icon = type(b) == "table" and b.icon
        if type(icon) == "table" and icon.SetTexCoord then icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) end
    end
end

-- Einen Rahmen des Spiels im WeintCodex-Stil zeichnen. Wiederholbar: das
-- Spiel richtet seine Rahmen bei jeder Einstellungsaenderung neu ein.
function GG.Style(f)
    if type(f) ~= "table" or (f.IsForbidden and f:IsForbidden()) then return false end
    local ok, err = pcall(function()
        local tex = K.BarTexture()
        local hb, pb = f.healthBar, f.powerBar
        if type(hb) == "table" and hb.SetStatusBarTexture then hb:SetStatusBarTexture(tex) end
        if type(pb) == "table" and pb.SetStatusBarTexture then pb:SetStatusBarTexture(tex) end
        -- Grund in der Hintergrundfarbe der Kacheln (Einstellung der Gruppenrahmen).
        local bg = f.background
        if type(bg) == "table" and bg.SetColorTexture then
            local c = K.GetColor(KEY, "bgColor")
            bg:SetColorTexture(c.r, c.g, c.b, 1)
        end
        -- Blizzards Linien und Trenner weg (6.6.1.1: "sieht nicht aus wie
        -- bei meinem Krieger").
        for _, k in ipairs({ "horizTopBorder", "horizBottomBorder", "vertLeftBorder", "vertRightBorder",
                             "horizDivider" }) do
            Hide(f[k])
        end
        -- Texte wie auf den Kacheln: Name oben mittig, Zustand in der Mitte,
        -- WeintCodex-Schrift, hell. Nur Methoden an den Texten des Spiels.
        local size = Opt("nameSize") or 11
        local name, st = f.name, f.statusText
        if type(name) == "table" and name.SetFont then
            K.SetFont(name, size)
            name:ClearAllPoints()
            name:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -4)
            name:SetPoint("TOPRIGHT", f, "TOPRIGHT", -16, -4)
            if name.SetJustifyH then name:SetJustifyH("CENTER") end
            if name.SetShadowOffset then name:SetShadowOffset(1, -1) end
        end
        if type(st) == "table" and st.SetFont then
            K.SetFont(st, math.max(8, size - 1))
            st:ClearAllPoints()
            st:SetPoint("CENTER", f, "CENTER", 0, -6)
            if st.SetJustifyH then st:SetJustifyH("CENTER") end
        end
        GG.Color(f)
        Crop(f.buffFrames)
        Crop(f.debuffFrames)
        Crop(f.dispelDebuffFrames)
        local s = styled[f]
        if not s then
            s = { border = K.Border(f, 1, 0, 0, 0, 1, "OVERLAY"),
                  shadow = K.Glow(f, { spread = 4, shadow = true }) }
            styled[f] = s
        end
        local bc = K.GetColor(KEY, "borderColor")
        s.border:SetColor(bc.r, bc.g, bc.b, 1)
        s.border:SetShown(Opt("showBorder") and true or false)
    end)
    if not ok then K.Report("gruppe", err) end
    return ok
end

-- Die Behaelter des Spiels: Ueberschrift ("Gruppe") und Rahmen weg - die
-- Kacheln stehen fuer sich, wie die eigenen.
function GG.StyleContainers()
    for _, name in ipairs({ "CompactPartyFrame", "CompactRaidFrameContainer" }) do
        local box = _G[name]
        if type(box) == "table" and not (box.IsForbidden and box:IsForbidden()) then
            Hide(box.title)
            Hide(box.borderFrame)
        end
    end
end

function GG.StyleAll()
    local n = 0
    for _, f in ipairs(GG.Frames()) do
        if GG.Style(f) then n = n + 1 end
    end
    GG.count = n
    return n
end

-- Nutzt die Gruppe die schlachtzugsartigen Rahmen? true / false / nil
-- (der Client sagt es nicht).
function GG.RaidStyleParty()
    local em = _G.EditModeManagerFrame
    if type(em) == "table" and type(em.UseRaidStylePartyFrames) == "function" then
        local ok, v = pcall(em.UseRaidStylePartyFrames, em)
        if ok then return K.Bool(v, nil) end
    end
    return nil
end

local hinted = false
local function HintRaidStyle()
    if hinted then return end
    local inGroup = K.Bool(_G.IsInGroup and _G.IsInGroup(), false)
    local inRaid = K.Bool(_G.IsInRaid and _G.IsInRaid(), false)
    if not inGroup or inRaid or GG.RaidStyleParty() ~= false then return end
    hinted = true
    print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " Für HoTs, Buffs und Schilde in der Gruppe: "
        .. "/wcui einrichten – oder von Hand im Bearbeitungsmodus → Gruppenrahmen → „Schlachtzugsartige Gruppenrahmen verwenden“.")
end

local pending = false
local function Later()
    if pending then return end
    pending = true
    local function run()
        pending = false
        GG.StyleContainers()
        GG.StyleAll()
        HintRaidStyle()
        local CC = WeintCodex.UIClickCast
        if CC and CC.Apply then CC.Apply() end
    end
    if _G.C_Timer and _G.C_Timer.After then _G.C_Timer.After(0.3, run) else run() end
end
GG.Later = Later

local hooked = false
function GG.Enable()
    GG.active = true
    if not hooked and _G.hooksecurefunc then
        hooked = true
        for _, fn in ipairs({ "DefaultCompactUnitFrameSetup", "DefaultCompactMiniFrameSetup", "CompactUnitFrame_SetUpFrame" }) do
            if type(_G[fn]) == "function" then
                _G.hooksecurefunc(fn, K.Measured("Gruppenrahmen des Spiels", function(f) GG.Style(f) end))
                GG.hooks = (GG.hooks or 0) + 1
            end
        end
        -- Das Spiel faerbt bei jedem Einheitenwechsel neu ein.
        for _, fn in ipairs({ "CompactUnitFrame_UpdateHealthColor", "CompactUnitFrame_UpdateAll" }) do
            if type(_G[fn]) == "function" then
                _G.hooksecurefunc(fn, K.Measured("Gruppenrahmen des Spiels", function(f) GG.Color(f) end))
                GG.hooks = (GG.hooks or 0) + 1
            end
        end
    end
    local ev = CreateFrame("Frame")
    for _, e in ipairs({ "GROUP_ROSTER_UPDATE", "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_ENABLED" }) do
        pcall(ev.RegisterEvent, ev, e)
    end
    ev:SetScript("OnEvent", K.Measured("Gruppenrahmen des Spiels", Later))
    GG.state = "Rahmen des Spiels im WeintCodex-Stil"
    Later()
end

-- /wcui gruppe
function GG.Inspect()
    local out = { "Gruppenrahmen: " .. (GG.active and "des Spiels im WeintCodex-Stil" or "eigene von WeintCodex") }
    local frames = GG.Frames()
    local n = 0
    for _ in pairs(styled) do n = n + 1 end
    out[#out + 1] = string.format("Rahmen des Spiels gefunden: %d, im WeintCodex-Stil: %d, Haken ins Spiel: %d",
        #frames, n, GG.hooks or 0)
    if frames[1] then
        local ok, name = pcall(frames[1].GetName, frames[1])
        out[#out + 1] = "Erster Rahmen: " .. tostring(ok and name or "?")
    end
    local rs = GG.RaidStyleParty()
    out[#out + 1] = "Schlachtzugsartige Gruppenrahmen: "
        .. (rs == true and "an" or rs == false and "aus – dann zeigt die Gruppe keine HoTs" or "unbekannt")
    return out
end
