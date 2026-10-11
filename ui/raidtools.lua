--------------------------------------------------
-- WeintCodex :: Oberflaeche - Gruppenwerkzeuge
--------------------------------------------------
-- 6.29.13.0, Spieler: "In einer Gruppe habe ich links dieses ausklappbare
-- Menue (CompactRaidFrameManager). Ich will ein eigenes mit den gleichen
-- Funktionen, Mouseover, im Gestaltungsmodus frei verschiebbar, gern ein-
-- und ausklappbar. Dafuer darf das von Blizzard weichen."
--
-- WAS ES KANN, wie das Menue des Spiels:
--   * Bereitschaftscheck, Rollenabfrage, Countdown (10 s, Rechtsklick
--     bricht ab) - Funktionen des Clients, die nicht geschuetzt sind.
--   * Ziel markieren (8 Zeichen + entfernen) und Boden markieren (8 +
--     alle entfernen). Markieren ist fuer Addons gesperrt (SetRaidTarget
--     -> ADDON_ACTION_FORBIDDEN, gemessen 6.9.0.1): jeder Knopf ist ein
--     geschuetzter Makroknopf mit /tm bzw. /wm und /cwm - das Spiel
--     markiert, ausgeloest vom Klick (wie Automark).
--   * Pings beschraenken (nur Anfuehrer), Gruppe / Instanzgruppe verlassen
--     (zweiter Klick bestaetigt - die Flaeche erscheint beim Drueberfahren,
--     ein Fehlklick waere sonst schnell passiert).
-- WAS FEHLT: die Auswahl "Gruppe/Schlachtzug" fuer die Rahmen des Spiels
-- (die stellen die Gruppenrahmen bzw. der Bearbeitungsmodus) und der Knopf
-- in den Bearbeitungsmodus (hat der Gestaltungsmodus).
--
-- SICHTBAR nur in einer Gruppe und im Gestaltungsmodus. "Mouseover": die
-- Flaeche ist blass, bis die Maus darueber ist - nur Deckkraft, denn die
-- geschuetzten Knoepfe darin duerfen im Kampf nicht gezeigt oder versteckt
-- werden. Einklappen (der Griff am Rand) deshalb nur ausserhalb des Kampfes.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIRaidTools = {}

local RT = WeintCodex.UIRaidTools
local K  = WeintCodex.UIKit
local C  = WeintCodex.Colors
-- Kein eigenes Modul: die Seitenleiste des Einstellungsfensters fasst
-- keinen Eintrag mehr (load_test.lua rechnet nach). Die Einstellungen
-- liegen bei den Gruppenrahmen, die Seite ist dort ein Reiter; laufen tut
-- es mit der Oberflaeche, unabhaengig davon, ob die Gruppenrahmen an sind.
local KEY = "groupframes"
local MOVER = "raidtools"

RT.DEFAULTS = {
    rtEnabled      = true,
    rtHover        = true,    -- blass, bis die Maus darueber ist
    rtFadeAlpha    = 15,      -- Prozent, ohne Maus
    rtCollapsed    = false,
    rtHideBlizzard = true,    -- das Menue des Spiels weicht
}

local function Opt(k) return K.Get(KEY, k) end

RT.ICON, RT.GAP, RT.PAD = 22, 3, 8
RT.W = RT.PAD * 2 + 9 * RT.ICON + 8 * RT.GAP
-- Bodenmarkierung n -> Symbol (Reihenfolge des Spiels: Quadrat, Dreieck,
-- Raute, Kreuz, Stern, Kreis, Mond, Totenkopf).
RT.WORLD_ICON = { 6, 4, 3, 7, 1, 2, 5, 8 }
RT.PINGS = {
    { value = "None",       text = "Nichts" },
    { value = "Lead",       text = "Anführer" },
    { value = "Assist",     text = "Anführer und Assistenten" },
    { value = "TankHealer", text = "Tanks und Heiler" },
}

local panel, content, handle
local secure = {}   -- [n] = geschuetzter Knopf (fuer den Prueflauf)
RT.secure = secure
local armed

local function Say(text)
    print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " " .. text)
end

local function Call(fn, ...)
    if type(fn) ~= "function" then return false end
    return pcall(fn, ...)
end

function RT.InGroup()
    local f = _G.IsInGroup
    return type(f) == "function" and K.Bool(f(), false) or false
end

function RT.InInstanceGroup()
    local f = _G.IsInGroup
    local cat = _G.LE_PARTY_CATEGORY_INSTANCE
    return type(f) == "function" and cat ~= nil and K.Bool(f(cat), false) or false
end

function RT.IsLeader()
    local f = _G.UnitIsGroupLeader
    return type(f) == "function" and K.Bool(f("player"), false) or false
end

--------------------------------------------------
-- Was die Knoepfe tun
--------------------------------------------------

function RT.ReadyCheck() return Call(_G.DoReadyCheck) end
function RT.RolePoll() return Call(_G.InitiateRolePoll) end
function RT.Countdown(secs)
    local P = _G.C_PartyInfo
    return Call(P and P.DoCountdown, secs)
end

function RT.UnitMacro(i) return i == 0 and "/tm 0" or ("/tm " .. i) end
-- "Alle entfernen": "/cwm all" tat im Spiel nichts (Spielerbericht
-- 6.29.16.0) - jetzt jede der acht einzeln, das geht sicher, wo /cwm n geht.
function RT.WorldMacro(i)
    if i ~= 0 then return "/wm " .. i end
    local t = {}
    for n = 1, 8 do t[n] = "/cwm " .. n end
    return table.concat(t, "\n")
end
-- Rechtsklick auf ein Bodenzeichen: nur dieses entfernen.
function RT.WorldClear(i) return "/cwm " .. i end

function RT.PingValue()
    local P, E = _G.C_PartyInfo, _G.Enum and _G.Enum.RestrictPingsTo
    if not (P and P.GetRestrictPings and E) then return nil end
    local ok, v = pcall(P.GetRestrictPings)
    if not ok then return nil end
    for name, n in pairs(E) do if n == v then return name end end
    return nil
end

function RT.SetPings(name)
    local P, E = _G.C_PartyInfo, _G.Enum and _G.Enum.RestrictPingsTo
    if not (P and P.SetRestrictPings and E and E[name] ~= nil) then return false end
    return (pcall(P.SetRestrictPings, E[name]))
end

function RT.Leave(instance)
    local P = _G.C_PartyInfo
    local fn = (P and P.LeaveParty) or _G.LeaveParty
    if instance then return Call(fn, _G.LE_PARTY_CATEGORY_INSTANCE) end
    return Call(fn)
end

-- Verlassen braucht einen zweiten Klick (3 s).
function RT.ArmOrLeave(which)
    if armed == which then
        armed = nil
        RT.Sync()
        return RT.Leave(which == "instance")
    end
    armed = which
    if _G.C_Timer and _G.C_Timer.After then
        _G.C_Timer.After(3, function() if armed == which then armed = nil RT.Sync() end end)
    end
    RT.Sync()
    return false
end

--------------------------------------------------
-- Flaeche
--------------------------------------------------

local function Label(parent, text, y)
    local t = K.NewText(parent, 11)
    t:SetPoint("TOPLEFT", parent, "TOPLEFT", RT.PAD, y)
    t:SetTextColor(unpack(C.textMuted))
    t:SetText(text)
    return t
end

local function Tooltip(owner, title, line)
    local tip = _G.GameTooltip
    if not tip then return end
    tip:SetOwner(owner, "ANCHOR_RIGHT")
    tip:SetText(title, 1, 1, 1)
    if line then
        local d = C.textMuted
        tip:AddLine(line, d[1], d[2], d[3], true)
    end
    tip:Show()
end

-- Ein Symbolknopf, darauf ein geschuetzter Makroknopf.
local function MarkerButton(parent, x, y, icon, macro, title, line, macro2)
    local b = CreateFrame("Frame", nil, parent)
    b:SetSize(RT.ICON, RT.ICON)
    b:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    b.bg = b:CreateTexture(nil, "BACKGROUND")
    b.bg:SetAllPoints(b)
    b.bg:SetColorTexture(unpack(C.surface2))
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetPoint("TOPLEFT", b, "TOPLEFT", 2, -2)
    b.icon:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -2, 2)
    b.icon:SetTexture(icon)
    local ok, s = pcall(CreateFrame, "Button", nil, b, "SecureActionButtonTemplate")
    if not (ok and s) then return b end
    s:SetAllPoints(b)
    if s.RegisterForClicks then s:RegisterForClicks("AnyUp") end
    s:SetAttribute("useOnKeyDown", false)
    s:SetAttribute("type", "macro")
    s:SetAttribute("macrotext", macro)
    -- Rechts eine eigene Aktion: macrotext2 geht vor macrotext.
    if macro2 then s:SetAttribute("macrotext2", macro2) end
    s:SetScript("OnEnter", function(self) Tooltip(self, title, line) end)
    s:SetScript("OnLeave", function() if _G.GameTooltip then _G.GameTooltip:Hide() end end)
    secure[#secure + 1] = s
    b.secure = s
    return b
end

local function TextButton(parent, text, w, onClick, tip)
    local b = WeintCodex.CreateButton(parent, { text = text, kind = "secondary", height = 22, size = 11,
        tooltip = tip, onClick = onClick })
    b:SetWidth(w)
    return b
end

local function Build()
    if panel then return panel end
    panel = CreateFrame("Frame", "WeintCodexRaidTools", UIParent)
    panel:SetFrameStrata("MEDIUM")
    panel:SetWidth(RT.W)
    K.Kachel(panel)
    content = CreateFrame("Frame", nil, panel)
    content:SetAllPoints(panel)

    local title = K.NewText(content, 12)
    title:SetPoint("TOPLEFT", content, "TOPLEFT", RT.PAD, -RT.PAD)
    title:SetTextColor(unpack(C.textBright))
    panel.title = title

    local y = -RT.PAD - 20
    local tw = math.floor((RT.W - RT.PAD * 2 - 2 * 4) / 3)
    panel.ready = TextButton(content, "Bereit?", tw, function() RT.ReadyCheck() end,
        "Bereitschaftscheck – nur als Anführer oder Assistent.")
    panel.ready:SetPoint("TOPLEFT", content, "TOPLEFT", RT.PAD, y)
    panel.roles = TextButton(content, "Rollen", tw, function() RT.RolePoll() end,
        "Rollenabfrage – jeder wählt Tank, Heiler oder Schaden.")
    panel.roles:SetPoint("LEFT", panel.ready, "RIGHT", 4, 0)
    panel.count = TextButton(content, "Countdown", tw, nil,
        "Links: 10 Sekunden Countdown für alle. Rechts: abbrechen.")
    panel.count:SetPoint("LEFT", panel.roles, "RIGHT", 4, 0)
    if panel.count.RegisterForClicks then panel.count:RegisterForClicks("LeftButtonUp", "RightButtonUp") end
    panel.count:SetScript("OnClick", function(_, which) RT.Countdown(which == "RightButton" and 0 or 10) end)

    y = y - 30
    Label(content, "Ziel markieren", y)
    y = y - 16
    for i = 1, 9 do
        local n = i <= 8 and i or 0
        local icon = n > 0 and ("Interface\\TargetingFrame\\UI-RaidTargetingIcon_" .. n)
            or "Interface\\Buttons\\UI-GroupLoot-Pass-Up"
        MarkerButton(content, RT.PAD + (i - 1) * (RT.ICON + RT.GAP), y, icon, RT.UnitMacro(n),
            n > 0 and "Ziel markieren" or "Markierung entfernen",
            n > 0 and "Setzt dieses Zeichen auf dein Ziel." or "Nimmt das Zeichen von deinem Ziel.")
    end
    y = y - RT.ICON - 8
    Label(content, "Boden markieren", y)
    y = y - 16
    for i = 1, 9 do
        local n = i <= 8 and i or 0
        local icon = n > 0 and ("Interface\\TargetingFrame\\UI-RaidTargetingIcon_" .. RT.WORLD_ICON[n])
            or "Interface\\Buttons\\UI-GroupLoot-Pass-Up"
        MarkerButton(content, RT.PAD + (i - 1) * (RT.ICON + RT.GAP), y, icon, RT.WorldMacro(n),
            n > 0 and "Boden markieren" or "Alle Bodenmarkierungen entfernen",
            n > 0 and "Links: danach auf den Boden klicken, wo das Zeichen liegen soll. Rechts: dieses Zeichen entfernen."
                or nil, n > 0 and RT.WorldClear(n) or nil)
    end
    y = y - RT.ICON - 10
    local fw = RT.W - RT.PAD * 2
    panel.pings = TextButton(content, "", fw, function(self)
        if not RT.IsLeader() then Say("Pings beschränken kann nur der Anführer.") return end
        WeintCodex.OpenDropMenu(self, RT.PINGS, RT.PingValue(), function(v) RT.SetPings(v) RT.Sync() end, fw)
    end, "Wer in der Gruppe pingen darf – nur der Anführer stellt das ein.")
    panel.pings:SetPoint("TOPLEFT", content, "TOPLEFT", RT.PAD, y)
    y = y - 26
    panel.leave = TextButton(content, "", fw, function() RT.ArmOrLeave("party") end)
    panel.leave:SetPoint("TOPLEFT", content, "TOPLEFT", RT.PAD, y)
    y = y - 26
    panel.leaveInst = TextButton(content, "", fw, function() RT.ArmOrLeave("instance") end)
    panel.leaveInst:SetPoint("TOPLEFT", content, "TOPLEFT", RT.PAD, y)
    y = y - 22 - RT.PAD
    RT.FULL_H = -y
    panel:SetHeight(RT.FULL_H)

    -- Der Griff am rechten Rand: ein- und ausklappen.
    handle = CreateFrame("Button", nil, panel)
    handle:SetSize(14, 40)
    K.Kachel(handle)
    handle.text = K.NewText(handle, 12)
    handle.text:SetPoint("CENTER", handle, "CENTER", 0, 0)
    handle:SetScript("OnClick", function() RT.Toggle() end)
    handle:SetScript("OnEnter", function(self)
        Tooltip(self, "Gruppenwerkzeuge", Opt("rtCollapsed") and "Klick: aufklappen" or "Klick: einklappen")
    end)
    handle:SetScript("OnLeave", function() if _G.GameTooltip then _G.GameTooltip:Hide() end end)
    panel.handle = handle

    K.RegisterMover(panel, MOVER, "Gruppenwerkzeuge", K.Layout(MOVER), { secure = true })
    return panel
end
RT.Build = Build

function RT.Toggle()
    if K.InCombat() then Say("Im Kampf lässt sich das nicht ein- oder ausklappen.") return false end
    K.Set(KEY, "rtCollapsed", not Opt("rtCollapsed"))
    return true
end

-- Texte und Zustand; aendert keine geschuetzten Rahmen.
function RT.Sync()
    if not panel then return end
    local n = (_G.GetNumGroupMembers and K.Plain(_G.GetNumGroupMembers())) or 0
    panel.title:SetText((K.Bool(_G.IsInRaid and _G.IsInRaid(), false) and "Schlachtzug" or "Gruppe")
        .. (type(n) == "number" and n > 0 and ("  ·  " .. n) or ""))
    local pv = RT.PingValue()
    local label = "unbekannt"
    for _, e in ipairs(RT.PINGS) do if e.value == pv then label = e.text end end
    panel.pings:SetText("Pings: " .. label)
    panel.leave:SetText(armed == "party" and "Wirklich verlassen?" or "Gruppe verlassen")
    panel.leaveInst:SetText(armed == "instance" and "Wirklich verlassen?" or "Instanzgruppe verlassen")
    if panel.leaveInst.SetEnabled then panel.leaveInst:SetEnabled(RT.InInstanceGroup()) end
    -- Der Pfeil zeigt, wohin es aufklappt bzw. wohin es einklappt.
    local toward = RT.horiz == "RIGHT" and "<" or ">"
    local back = RT.horiz == "RIGHT" and ">" or "<"
    handle.text:SetText(Opt("rtCollapsed") and toward or back)
end

--------------------------------------------------
-- Aufklappen zur Bildschirmmitte (6.29.15.0)
--------------------------------------------------
-- Spieler: "an den unteren Rand gezogen soll es nach oben aufklappen, am
-- rechten Rand nach links, oben nach unten". Die Flaeche haengt deshalb
-- immer an der Ecke, die dem naechsten Bildschirmrand zugewandt ist: in
-- der unteren Haelfte unten, in der rechten Haelfte rechts. Ein- und
-- Ausklappen aendert die Groesse - die angehaengte Ecke bleibt stehen,
-- die Flaeche waechst zur Mitte. Der Griff sitzt auf der Seite zur Mitte.

-- Ecke fuer eine Flaeche mit diesen Kanten auf einem Bildschirm W x H.
function RT.Corner(l, b, r, t, W, H)
    local horiz = ((l + r) / 2 > W / 2) and "RIGHT" or "LEFT"
    local vert = ((b + t) / 2 < H / 2) and "BOTTOM" or "TOP"
    local x = horiz == "LEFT" and l or (r - W)
    local y = vert == "TOP" and (t - H) or b
    return vert .. horiz, math.floor(x + 0.5), math.floor(y + 0.5), vert, horiz
end

local function Num(f, m)
    local ok, v = pcall(f[m], f)
    v = ok and K.Plain(v) or nil
    return type(v) == "number" and v or nil
end

-- Den gespeicherten Platz auf die passende Ecke umrechnen (dieselbe Stelle).
function RT.Reanchor()
    if not panel or K.InCombat() then return false end
    local l, b, r, t = Num(panel, "GetLeft"), Num(panel, "GetBottom"), Num(panel, "GetRight"), Num(panel, "GetTop")
    local W, H = Num(UIParent, "GetWidth"), Num(UIParent, "GetHeight")
    if not (l and b and r and t and W and H) then return false end
    local point, x, y, vert, horiz = RT.Corner(l, b, r, t, W, H)
    RT.vert, RT.horiz = vert, horiz
    local ui = K.Profile()
    if not ui then return false end
    local cur = ui.positions[MOVER]
    if not (cur and cur.point == point and cur.x == x and cur.y == y) then
        ui.positions[MOVER] = { point = point, relPoint = point, x = x, y = y }
        K.ApplyPosition(MOVER)
    end
    return true
end

-- Griff auf der Seite zur Mitte, oben oder unten buendig.
function RT.PlaceHandle()
    if not handle then return end
    local right, bottom = RT.horiz == "RIGHT", RT.vert == "BOTTOM"
    local v = bottom and "BOTTOM" or "TOP"
    local dy = bottom and RT.PAD or -RT.PAD
    handle:ClearAllPoints()
    if right then
        handle:SetPoint(v .. "RIGHT", panel, v .. "LEFT", -1, dy)
    else
        handle:SetPoint(v .. "LEFT", panel, v .. "RIGHT", 1, dy)
    end
end

-- Zeigen, einklappen: nur ausserhalb des Kampfes (geschuetzte Knoepfe).
function RT.Apply()
    if not panel then return end
    if K.InCombat() then K.AfterCombat(RT.Apply) return end
    local show = RT.InGroup() or K.IsUnlocked()
    panel:SetShown(show)
    local open = not Opt("rtCollapsed") or K.IsUnlocked()
    if show then RT.Reanchor() end
    RT.PlaceHandle()
    content:SetShown(open)
    panel:SetHeight(open and RT.FULL_H or 56)
    panel:SetWidth(open and RT.W or 14)
    RT.Sync()
    RT.Fade()
end

-- Maus ueber der Flaeche? Wie die Leisten (ui/actionbars.lua):
-- IsMouseOver des Rahmens mit etwas Luft, Antwort ueber K.Bool (kann
-- geheim sein). 6.29.13.0 fragte das globale MouseIsOver - die Flaeche
-- blieb im Spiel blass (Spielerbericht 6.29.14.0).
local HOVER_MARGIN = 6
function RT.MouseOver(f)
    if type(f) ~= "table" or type(f.IsMouseOver) ~= "function" then return false end
    local m = HOVER_MARGIN
    local ok, v = pcall(f.IsMouseOver, f, m, -m, -m, m)
    return ok and K.Bool(v, false) or false
end

-- Mouseover: nur Deckkraft (geht auch im Kampf).
function RT.Fade()
    if not panel then return end
    local over = K.IsUnlocked() or not Opt("rtHover") or RT.MouseOver(panel) or RT.MouseOver(handle)
    local a = over and 1 or (Opt("rtFadeAlpha") or 15) / 100
    if panel.GetAlpha and math.abs((panel:GetAlpha() or 1) - a) > 0.01 then panel:SetAlpha(a) end
end

-- Das Menue des Spiels weicht. Haengen die Schlachtzugsrahmen des Spiels
-- an ihm (CompactRaidFrameContainer als Kind - in aelteren Clients so),
-- verschwinden sie mit; dann nur unsichtbar und ohne Maus, die Rahmen
-- bleiben. Sonst wie jedes ersetzte Teil des Spiels (K.HideBlizzard,
-- Ereignisse bleiben: es steuert die Rahmen des Spiels mit).
function RT.HideBlizzard()
    if not Opt("rtHideBlizzard") then return false end
    local m, cont = _G.CompactRaidFrameManager, _G.CompactRaidFrameContainer
    if type(m) ~= "table" then return false end
    local p = type(cont) == "table" and cont.GetParent and cont:GetParent()
    if p ~= nil and p == m then
        K.AfterCombat(function()
            m:SetAlpha(0)
            if m.EnableMouse then m:EnableMouse(false) end
            local tb = m.toggleButton or _G.CompactRaidFrameManagerToggleButton
            if type(tb) == "table" and tb.EnableMouse then tb:EnableMouse(false) end
        end)
        RT.blizzardWay = "unsichtbar (trägt die Rahmen des Spiels)"
    else
        K.HideBlizzard(m, true)
        RT.blizzardWay = "ausgeblendet"
    end
    return true
end

local ticker, enabled = nil, false
local function Enable()
    if enabled then return end
    enabled = true
    Build()
    RT.HideBlizzard()
    local ev = CreateFrame("Frame")
    for _, e in ipairs({ "GROUP_ROSTER_UPDATE", "PLAYER_ENTERING_WORLD", "PARTY_LEADER_CHANGED" }) do
        pcall(ev.RegisterEvent, ev, e)
    end
    ev:SetScript("OnEvent", K.Measured("Gruppenwerkzeuge", function() RT.Apply() end))
    -- Ein Takt ueber OnUpdate (wie die Leisten), gedrosselt, ohne
    -- Tabellen je Bild.
    if not ticker then
        ticker = CreateFrame("Frame")
        local acc = 0
        ticker:SetScript("OnUpdate", function(_, el)
            acc = acc + (el or 0)
            if acc < 0.1 then return end
            acc = 0
            if panel and panel:IsShown() then RT.Fade() end
        end)
    end
    RT.Apply()
end
RT.Enable = Enable

-- Aus (Schalter): versteckt, das Menue des Spiels kommt nach dem Neuladen.
function RT.Disable()
    if not panel then return end
    if K.InCombat() then K.AfterCombat(RT.Disable) return end
    panel:Hide()
end

function RT.BuildPage(B)
    B:Section("Gruppenwerkzeuge",
        "Markieren, Bereitschaftscheck, Countdown, Pings und Verlassen – statt des ausklappbaren Menüs des Spiels links. Nur in einer Gruppe und im Gestaltungsmodus, dort frei verschiebbar.")
    B:Row({ type = "toggle", label = "Gruppenwerkzeuge", key = "rtEnabled" },
          { type = "toggle", label = "Menü des Spiels ausblenden", key = "rtHideBlizzard", reload = true })
    local off = function() return not Opt("rtEnabled") end
    B:Row({ type = "toggle", label = "Erst bei Mausberührung", key = "rtHover", disabled = off,
            description = "Ohne Maus blass, mit Maus voll da." },
          { type = "slider", label = "Deckkraft ohne Maus", key = "rtFadeAlpha", min = 0, max = 100, step = 5,
            format = function(v) return string.format("%d %%", v) end,
            disabled = function() return off() or not Opt("rtHover") end })
    B:Row({ type = "toggle", label = "Eingeklappt", key = "rtCollapsed", disabled = off,
            description = "Nur der Griff am Rand – ein Klick klappt auf. Nicht im Kampf." },
          { type = "empty" })
    B:Note("Markieren übernimmt das Spiel selbst (/tm, /wm) – Addons dürfen nicht markieren. Bodenmarkierung: Zeichen anklicken, dann auf den Boden. Blass heißt nicht aus: was du anklickst, wirkt.")
end

do
    local m = K.Module(KEY)
    if m then
        for k, v in pairs(RT.DEFAULTS) do m.defaults[k] = v end
        m.pages[#m.pages + 1] = { key = "gruppenwerkzeuge", label = "Gruppenwerkzeuge", build = RT.BuildPage }
    end
end

function RT.Start()
    if not (K.UIEnabled and K.UIEnabled()) then return false end
    if Opt("rtEnabled") then
        Enable()
        RT.HideBlizzard()   -- das Menue kann spaeter entstehen
    else
        RT.Disable()
    end
    return true
end

K.Listen(function(kind, module, key)
    if kind == "unlock" then RT.Apply() return end
    -- Nach dem Ziehen (das Ziehen waehlt den Rahmen an): neue Ecke.
    if kind == "moverSelect" and module == MOVER then
        if RT.Reanchor() then RT.PlaceHandle() RT.Sync() end
        return
    end
    if kind == "setting" and module == KEY and type(key) == "string" and key:sub(1, 2) == "rt" then
        if key == "rtHideBlizzard" then return end   -- Neuladen
        if key == "rtEnabled" then RT.Start() return end
        RT.Apply()
    end
end)

local boot = CreateFrame("Frame")
boot:RegisterEvent("PLAYER_LOGIN")
boot:SetScript("OnEvent", function() RT.Start() end)
