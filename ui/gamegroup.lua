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
    return out
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
        local bg = f.background
        if type(bg) == "table" and bg.SetColorTexture then
            local c = WeintCodex.GameColors.plateBg
            bg:SetColorTexture(c[1], c[2], c[3], 1)
        end
        for _, k in ipairs({ "horizTopBorder", "horizBottomBorder", "vertLeftBorder", "vertRightBorder" }) do
            Hide(f[k])
        end
        local size = Opt("nameSize") or 11
        if type(f.name) == "table" and f.name.SetFont then K.SetFont(f.name, size) end
        if type(f.statusText) == "table" and f.statusText.SetFont then K.SetFont(f.statusText, math.max(8, size - 1)) end
        Crop(f.buffFrames)
        Crop(f.debuffFrames)
        Crop(f.dispelDebuffFrames)
        local s = styled[f]
        if not s then
            s = { border = K.Border(f, 1, 0, 0, 0, 1, "OVERLAY") }
            styled[f] = s
        end
        s.border:SetShown(Opt("showBorder") and true or false)
    end)
    if not ok then K.Report("gruppe", err) end
    return ok
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
        .. "Bearbeitungsmodus öffnen → Gruppenrahmen → „Schlachtzugsartige Gruppenrahmen verwenden“ einschalten.")
end

local pending = false
local function Later()
    if pending then return end
    pending = true
    local function run()
        pending = false
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
                _G.hooksecurefunc(fn, function(f) GG.Style(f) end)
            end
        end
    end
    local ev = CreateFrame("Frame")
    for _, e in ipairs({ "GROUP_ROSTER_UPDATE", "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_ENABLED" }) do
        pcall(ev.RegisterEvent, ev, e)
    end
    ev:SetScript("OnEvent", Later)
    GG.state = "Rahmen des Spiels im WeintCodex-Stil"
    Later()
end

-- /wcui gruppe
function GG.Inspect()
    local out = { "Gruppenrahmen: " .. (GG.active and "des Spiels im WeintCodex-Stil" or "eigene von WeintCodex") }
    local frames = GG.Frames()
    local n = 0
    for _ in pairs(styled) do n = n + 1 end
    out[#out + 1] = string.format("Rahmen des Spiels gefunden: %d, im WeintCodex-Stil: %d", #frames, n)
    local rs = GG.RaidStyleParty()
    out[#out + 1] = "Schlachtzugsartige Gruppenrahmen: "
        .. (rs == true and "an" or rs == false and "aus – dann zeigt die Gruppe keine HoTs" or "unbekannt")
    return out
end
