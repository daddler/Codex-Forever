--------------------------------------------------
-- WeintCodex :: Oberflaeche - Buffzeiten aus Zaubern
--------------------------------------------------
-- Beta-Test (Paladin): "Siegel des Kreuzfahrers" bietet der
-- Abklingzeitmanager des Spiels nicht an - "bau das fuer alle Klassen".
--
-- WARUM AUS ZAUBERN, NICHT AUS AUREN. Im Kampf gibt der Client die eigenen
-- Auren nicht heraus (CLAUDE.md, "Aurenleisten"). Was ein Addon weiter
-- sieht, ist das Wirken: UNIT_SPELLCAST_SUCCEEDED("player", guid, id).
-- Kennt WeintCodex den Zauber und seine Dauer, rechnet es die Uhr selbst -
-- eigene Zahlen, nie geheime. Ausserhalb des Kampfes wird gegen die echte
-- Aura abgeglichen (Rest korrigiert, Verschwundenes entfernt).
--
-- WAS NICHT GERATEN WIRD.
--   * Nennt der Client die Zauber-ID im Kampf nur geheim, wird der Zauber
--     NICHT verglichen - der letzte bekannte Stand bleibt, die Zaehlung
--     (BT.stats.secret) sagt es in /wcui pruefen.
--   * Haengt die Dauer an etwas Unbekanntem (Kombopunkte bei Zerhaeckseln),
--     zeigt das Symbol "laeuft" ohne Uhr.
--   * Ohne Dauer (Aspekte, Gestalten) heisst es "an", bis ein anderer
--     Zauber der Gruppe kommt.
--   * Buffs, die man auch auf andere wirkt (`others`), zaehlen nur, wenn
--     das Ziel klar man selbst ist (kein freundliches fremdes Ziel); kann
--     der Client es nicht sagen, zaehlt der Zauber nicht.
--
-- KEIN BESTAND OHNE HERKUNFT. IDs und Dauern aus Classic (Art `classic`);
-- jede ID steht im Lehrerbestand der Klasse (data/trainer.lua) - der
-- Ladetest haelt das fest. Rang 1, den kein Lehrer lehrt (Siegel der
-- Rechtschaffenheit 21084/20154, Frostruestung 168, Daemonenhaut 687,
-- Haltungen des Kriegers), fehlt deshalb bewusst: ihr Wirken bleibt ohne
-- Symbol, bis der Abgleich ausserhalb des Kampfes es findet - auch der
-- fragt nur nach IDs der Liste.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIBuffTimes = {}

local BT = WeintCodex.UIBuffTimes
local K = WeintCodex.UIKit
local C = WeintCodex.Colors
local KEY = "reminders"

local MIN, SEC = 60, 1

-- Je Klasse Gruppen. Eine Gruppe ist EIN Platz: ein neuer Zauber der
-- Gruppe ersetzt den alten (Siegel, Aspekte, Ruestungen, Schilde).
--   spells    IDs aller Raenge (Lehrerbestand der Klasse)
--   duration  Sekunden aus Classic; nil = ohne Ende ("an")
--   variable  Dauer haengt an Unbekanntem: "laeuft", keine Uhr
--   consumedBy  diese Zauber beenden die Gruppe (Richturteil)
--   toggle    derselbe Zauber noch einmal schaltet aus (Gestalten)
--   others    auch auf andere wirkbar - nur mit klarem Selbstziel
--   weapon    Waffenverzauberung: Abgleich ueber GetWeaponEnchantInfo
--   remind    im Kampf "fehlt" zeigen, wenn gelernt und nicht aktiv
BT.CLASSES = {
    PALADIN = {
        { key = "seal", label = "Siegel", remind = true,
          duration = 30 * SEC,          -- Siegel: 30 s (Classic)
          -- 6.87.3.0 (Beta-Test mit Bildern der Tooltips): auf Forever
          -- "entfesselt" Richturteil die Energie des Siegels - das Siegel
          -- bleibt 30 s stehen (Classic: verbraucht). Kein Verbraucher mehr.
          spells = {
            21082, 20162, 20305, 20306, 20307, 20308,          -- Siegel des Kreuzfahrers 1-6
            21084,                                             -- der Rechtschaffenheit 1 (Start)
            20287, 20288, 20289, 20290, 20291, 20292, 20293,   -- der Rechtschaffenheit 2-8
            20164,                                             -- der Gerechtigkeit
            20165, 20347, 20348, 20349,                        -- des Lichts 1-4
            20166, 20356, 20357,                               -- der Weisheit 1-3
            20915, 20918, 20919, 20920,                        -- des Befehls 2-5
            20163,                                             -- des Furors (Forever)
          } },
    },
    HUNTER = {
        { key = "aspect", label = "Aspekt", remind = true,   -- ohne Dauer (Classic)
          spells = {
            13165, 14318, 14319, 14320, 14321, 14322,   -- des Falken 1-6
            13163,                                      -- des Affen
            5118,                                       -- des Geparden
            13159,                                      -- des Rudels
            13161,                                      -- des Wildtiers
            20043, 20190,                               -- der Wildnis 1-2
          } },
    },
    MAGE = {
        { key = "armor", label = "Rüstung", remind = true,
          duration = 30 * MIN,          -- Frost-, Eis-, Magierruestung: 30 min
          spells = {
            168,                        -- Frostruestung 1 (Start)
            7300, 7301,                 -- Frostruestung 2-3
            7302, 7320, 10219, 10220,   -- Eisruestung 1-4
            6117, 22782, 22783,         -- Magische Ruestung 1-3
          } },
        { key = "intellect", label = "Arkane Intelligenz", others = true,
          duration = 30 * MIN,          -- 30 min
          spells = { 1459, 1460, 1461, 10156, 10157 } },
    },
    WARLOCK = {
        { key = "armor", label = "Dämonenrüstung", remind = true,
          duration = 30 * MIN,          -- Daemonenhaut/-ruestung: 30 min
          spells = {
            687,                                -- Daemonenhaut 1 (Start)
            696,                                -- Daemonenhaut 2
            706, 1086, 11733, 11734, 11735,     -- Daemonenruestung 1-5
          } },
    },
    PRIEST = {
        -- Ladungen unbekannt (im Kampf nicht lesbar) - nur die Zeit.
        { key = "innerfire", label = "Inneres Feuer", remind = true,
          duration = 10 * MIN,          -- 10 min
          spells = { 588, 7128, 602, 1006, 10951, 10952 } },
        { key = "fortitude", label = "Machtwort: Seelenstärke", others = true,
          duration = 30 * MIN,          -- 30 min
          spells = { 1243, 1244, 1245, 2791, 10937, 10938 } },
    },
    SHAMAN = {
        { key = "shield", label = "Blitzschlagschild", remind = true,
          duration = 10 * MIN,          -- 10 min (Ladungen unbekannt)
          spells = { 324, 325, 905, 945, 8134, 10431, 10432 } },
        -- Haupthand; die Nebenhand bleibt den Erinnerungen (Waffe).
        { key = "imbue", label = "Waffe (Haupthand)", remind = true, weapon = true,
          duration = 5 * MIN,           -- Waffenverzauberungen: 5 min
          spells = {
            8017, 8018, 8019, 10399, 16314, 16315, 16316,   -- Felsbeisser 1-7
            8024, 8027, 8030, 16339, 16341, 16342,          -- Flammenzunge 1-6
            8033, 8038, 10456, 16355, 16356,                -- Frostbrand 1-5
            8232, 8235, 10486, 16362,                       -- Windzorn 1-4
          } },
    },
    WARRIOR = {
        -- Haltungen lehrt kein Lehrer (Kampfhaltung angeboren, Verteidigung
        -- und Berserker aus Quests) - nicht im Bestand, darum BT.STARTER.
        { key = "stance", label = "Haltung", remind = true,   -- ohne Dauer
          spells = { 2457, 71, 2458 } },  -- Kampf-, Verteidigungs-, Berserkerhaltung (Start/Quest)
        { key = "shout", label = "Schlachtruf",
          duration = 2 * MIN,           -- 2 min
          spells = { 6673, 5242, 6192, 11549, 11550, 11551 } },
    },
    ROGUE = {
        { key = "snd", label = "Zerhäckseln", variable = true,  -- Dauer je Kombopunkt
          spells = { 5171, 6774 } },
    },
    DRUID = {
        -- Baer und Katze lehrt kein Lehrer (Quest) - BT.STARTER.
        { key = "form", label = "Gestalt", toggle = true,   -- ohne Dauer
          spells = { 9634, 783, 5487, 768, 1066 } },   -- Terrorbaer, Reise; Baer, Katze, Wasser (Quest)
        { key = "mark", label = "Mal der Wildnis", others = true,
          duration = 30 * MIN,          -- 30 min
          spells = { 1126, 5232, 6756, 5234, 8907, 9884, 9885 } },
        { key = "thorns", label = "Dornen", others = true,
          duration = 10 * MIN,          -- 10 min
          spells = { 467, 782, 1075, 8914, 9756, 9910 } },
    },
}

-- 6.87.0.0: Zauber, die kein Lehrer lehrt (angeboren oder aus Klassen-
-- quests) - Classic-IDs, Art `classic`. Ohne sie fehlte dem Paladin auf
-- Stufe 1 sein einziges Siegel, dem Krieger jede Haltung.
BT.STARTER = { [21084] = true, [168] = true, [687] = true, [2457] = true, [71] = true,
               [2458] = true, [5487] = true, [768] = true, [1066] = true }

-- Was gemessen wurde (fuer /wcui pruefen).
BT.stats = { casts = 0, tracked = 0, secret = 0, secretInCombat = 0, plainInCombat = 0,
             notSelf = 0, reconciled = 0, removed = 0, found = 0 }

-- Laufzeit: je Gruppe { spell, start, duration } oder nil.
BT.active = {}
BT.class = nil
BT.byId, BT.consumers = {}, {}

local function Opt(k) return K.Get(KEY, k) end
local function Now() return _G.GetTime and _G.GetTime() or 0 end

function BT.Groups(class) return BT.CLASSES[class or BT.class] or {} end

-- Nachschlagen aufbauen (einmal je Klasse).
function BT.SetClass(class)
    BT.class = class
    wipe(BT.byId) wipe(BT.consumers) wipe(BT.active)
    for _, g in ipairs(BT.Groups(class)) do
        for _, id in ipairs(g.spells) do BT.byId[id] = g end
        for _, id in ipairs(g.consumedBy or {}) do
            local list = BT.consumers[id] or {}
            list[#list + 1] = g
            BT.consumers[id] = list
        end
    end
end

-- Klar auf sich selbst gewirkt? true / false / nil (unbekannt).
function BT.SelfTarget()
    if not (_G.UnitExists and _G.UnitIsUnit and _G.UnitCanAssist) then return nil end
    local ex = _G.UnitExists("target")
    if K.IsSecret(ex) then return nil end
    if not ex then return true end
    local me = _G.UnitIsUnit("target", "player")
    if K.IsSecret(me) then return nil end
    if me then return true end
    local friend = _G.UnitCanAssist("player", "target")
    if K.IsSecret(friend) then return nil end
    return not friend
end

-- Ein Wirken. Gibt zurueck, was geschah ("secret", "start", "consume",
-- "off", nil = nicht verfolgt).
function BT.OnCast(spellID, now, fighting)
    local st = BT.stats
    st.casts = st.casts + 1
    if K.IsSecret(spellID) then
        st.secret = st.secret + 1
        if fighting then st.secretInCombat = st.secretInCombat + 1 end
        return "secret"
    end
    if fighting then st.plainInCombat = st.plainInCombat + 1 end
    if type(spellID) ~= "number" then return nil end
    now = now or Now()
    local result
    local eaten = BT.consumers[spellID]
    if eaten then
        for _, g in ipairs(eaten) do BT.active[g.key] = nil end
        result = "consume"
    end
    local g = BT.byId[spellID]
    if not g then return result end
    if g.others and BT.SelfTarget() ~= true then
        st.notSelf = st.notSelf + 1
        return result
    end
    local cur = BT.active[g.key]
    if g.toggle and cur and cur.spell == spellID then
        BT.active[g.key] = nil
        return "off"
    end
    st.tracked = st.tracked + 1
    cur = cur or {}
    cur.spell, cur.start = spellID, now
    cur.duration = (not g.variable) and g.duration or nil
    BT.active[g.key] = cur
    BT.last[g.key] = spellID
    return "start"
end

-- Abgelaufenes entfernen; Rest in Sekunden oder nil (ohne Uhr).
function BT.Remaining(key, now)
    local a = BT.active[key]
    if not a then return nil end
    if not a.duration then return nil end
    local left = a.start + a.duration - (now or Now())
    if left <= 0 then BT.active[key] = nil return nil end
    return left
end

function BT.Expire(now)
    now = now or Now()
    for _, g in ipairs(BT.Groups()) do BT.Remaining(g.key, now) end
end

function BT.Clear() wipe(BT.active) end

-- Aura des Spielers zu einer ID: Tabelle, false (sicher nicht da) oder
-- nil (nicht lesbar - geheim oder ohne Schnittstelle).
function BT.Aura(id)
    local ua = _G.C_UnitAuras
    if not (ua and ua.GetPlayerAuraBySpellID) then return nil end
    local ok, a = pcall(ua.GetPlayerAuraBySpellID, id)
    if not ok or K.IsSecret(a) then return nil end
    if type(a) ~= "table" then return false end
    return a
end

-- Haupthand verzaubert? Rest in Sekunden, false oder nil (unbekannt).
function BT.MainHandEnchant()
    if not _G.GetWeaponEnchantInfo then return nil end
    local ok, has, ms = pcall(_G.GetWeaponEnchantInfo)
    if not ok or K.IsSecret(has) or K.IsSecret(ms) then return nil end
    if not has then return false end
    return type(ms) == "number" and ms / 1000 or nil
end

-- Abgleich ausserhalb des Kampfes. Im Kampf: nichts (keine Auskunft ist
-- nicht "weg").
function BT.Reconcile(now, fighting)
    if fighting then return false end
    now = now or Now()
    local st = BT.stats
    for _, g in ipairs(BT.Groups()) do
        local a = BT.active[g.key]
        if g.weapon then
            local left = BT.MainHandEnchant()
            if left == false then
                if a then BT.active[g.key] = nil st.removed = st.removed + 1 end
            elseif type(left) == "number" and a then
                a.start, a.duration = now, left
                st.reconciled = st.reconciled + 1
            end
        else
            local seen, seenId, unknown = nil, nil, false
            for _, id in ipairs(g.spells) do
                local aura = BT.Aura(id)
                if aura == nil then unknown = true
                elseif aura then seen, seenId = aura, id break end
            end
            if seen then
                local d, e = K.Plain(seen.duration), K.Plain(seen.expirationTime)
                if not a then a = {} st.found = st.found + 1 end
                a.spell = seenId
                if type(d) == "number" and type(e) == "number" and d > 0 then
                    a.start, a.duration = e - d, d
                elseif g.variable or not g.duration then
                    -- Aura ohne lesbare Dauer: "laeuft"/"an", nie geraten.
                    a.start, a.duration = a.start or now, nil
                else
                    a.start = a.start or now
                    a.duration = a.duration or g.duration
                end
                BT.active[g.key] = a
                if a.spell then BT.last[g.key] = a.spell end
                st.reconciled = st.reconciled + 1
            elseif a and not unknown then
                BT.active[g.key] = nil
                st.removed = st.removed + 1
            end
        end
    end
    return true
end

-- Hat der Charakter einen Zauber der Gruppe? (Erinnerungen fragen den
-- Client; "weiss nicht" zaehlt nicht als gelernt - kein geratenes "fehlt".)
function BT.Learned(g)
    local R = WeintCodex.UIReminders
    if not (R and R.Learned) then return false end
    return R.Learned({ any = g.spells }) == true
end

-- Was die Reihe zeigt: Liste von { group, state = "time"|"on"|"runs"|"missing", left }.
-- Eintraege aus einem Vorrat (je Gruppe einer) - der Takt legt nichts neu an.
local entries, pool = {}, {}
BT.last = BT.last or {}     -- [Gruppe] = zuletzt gewirkter Zauber (fuer "fehlt")
local function Put(g, spell, state, left)
    local n = #entries + 1
    local e = pool[n] or {}
    pool[n] = e
    e.group, e.spell, e.state, e.left = g, spell, state, left
    entries[n] = e
end
function BT.Entries(now, fighting, showMissing, sample)
    for i = #entries, 1, -1 do entries[i] = nil end
    now = now or Now()
    for _, g in ipairs(BT.Groups()) do
        local left = BT.Remaining(g.key, now)
        local a = BT.active[g.key]
        if a then
            Put(g, a.spell, left and "time" or (g.variable and "runs") or "on", left)
        elseif fighting and showMissing and g.remind and BT.Learned(g) then
            -- 6.87.2.0 (Beta-Test mit Bild: nach Richturteil ein weisses
            -- Feld mit "!"): Rang 1 des Siegels hat der Charakter oft gar
            -- nicht, das Spiel liefert dafuer kein Bild. Jetzt das zuletzt
            -- gewirkte Siegel der Gruppe, grau mit "!".
            Put(g, BT.last[g.key] or g.spells[1], "missing", nil)
        elseif sample then
            Put(g, g.spells[1], "on", nil)
        end
    end
    return entries
end

--------------------------------------------------
-- Anzeige
--------------------------------------------------

local row
BT.fighting = false

local function Texture(id)
    local cs = _G.C_Spell
    if cs and cs.GetSpellTexture then
        local ok, t = pcall(cs.GetSpellTexture, id)
        if ok and not K.IsSecret(t) and t then return t end
    end
    if _G.GetSpellTexture then
        local ok, t = pcall(_G.GetSpellTexture, id)
        if ok and not K.IsSecret(t) and t then return t end
    end
    return 134400   -- Fragezeichen des Spiels
end

local function Icon(parent)
    local b = CreateFrame("Frame", nil, parent)
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetAllPoints(b)
    b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    b.cd = CreateFrame("Cooldown", nil, b, "CooldownFrameTemplate")
    b.cd:SetAllPoints(b)
    if b.cd.SetDrawEdge then b.cd:SetDrawEdge(false) end
    if b.cd.SetReverse then b.cd:SetReverse(true) end
    local top = CreateFrame("Frame", nil, b)
    top:SetAllPoints(b)
    top:SetFrameLevel((b.cd:GetFrameLevel() or 1) + 2)
    K.Border(top, 1, 0, 0, 0, 1, "OVERLAY")
    b.state = K.NewText(top, 10)
    b.state:SetPoint("BOTTOM", b, "BOTTOM", 0, 2)
    b.mark = K.NewText(top, 16)
    b.mark:SetPoint("CENTER", b, "CENTER", 0, 0)
    b.mark:SetTextColor(unpack(C.warning))
    b:Hide()
    return b
end

function BT.Update()
    if not row then return end
    local on = Opt("castTimes") ~= false
    -- Im Gestaltungsmodus zeigt jede Gruppe ein Symbol (wo die Reihe steht).
    local list = BT.Entries(Now(), BT.fighting or K.InCombat(), Opt("castMissing") ~= false, row._unlock)
    if not on and not row._unlock then for i = #list, 1, -1 do list[i] = nil end end
    local s = tonumber(Opt("castSize")) or 28
    local gap = 4
    for i = #row.icons + 1, #list do row.icons[i] = Icon(row) end
    row:SetSize(math.max(s, #list * s + math.max(0, #list - 1) * gap), s)
    local R = WeintCodex.UIReminders
    row:SetAlpha(R and R.Alpha and R.Alpha() or 1)
    for i, b in ipairs(row.icons) do
        local e = list[i]
        if e then
            b:SetSize(s, s)
            b:ClearAllPoints()
            b:SetPoint("LEFT", row, "LEFT", (i - 1) * (s + gap), 0)
            b.icon:SetTexture(Texture(e.spell))
            local a = BT.active[e.group.key]
            if e.state == "time" and a then
                b.cd:SetCooldown(a.start, a.duration)
            else
                b.cd:Clear()
            end
            b.icon:SetDesaturated(e.state == "missing")
            b.mark:SetText(e.state == "missing" and "!" or "")
            b.state:SetText(e.state == "on" and "an" or e.state == "runs" and "läuft" or "")
            b:Show()
        else
            b:Hide()
        end
    end
end

-- Ein ruhiger Takt (eine Sekunde): Ablauf und Abgleich. Keine Tabelle,
-- keine Closure je Lauf.
local acc = 0
local function Tick(_, el)
    acc = acc + (el or 0)
    if acc < 1 then return end
    acc = 0
    BT.Expire()
    BT.Update()
end

local function OnEvent(_, event, unit, _, spellID)
    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        if K.IsSecret(unit) or unit ~= "player" then return end
        BT.OnCast(spellID, Now(), BT.fighting or K.InCombat())
    elseif event == "PLAYER_REGEN_DISABLED" then
        BT.fighting = true
    elseif event == "PLAYER_REGEN_ENABLED" then
        BT.fighting = false
        BT.Reconcile(Now(), false)
    elseif event == "PLAYER_DEAD" then
        BT.Clear()
    elseif event == "UNIT_AURA" or event == "UNIT_INVENTORY_CHANGED" then
        if K.IsSecret(unit) or unit ~= "player" then return end
        BT.Reconcile(Now(), BT.fighting or K.InCombat())
    else
        BT.Reconcile(Now(), BT.fighting or K.InCombat())
    end
    BT.Update()
end

function BT.Enable()
    if row then return end
    local class
    if _G.UnitClass then
        local _, c = _G.UnitClass("player")
        class = K.Plain(c)
    end
    BT.SetClass(class)
    row = CreateFrame("Frame", "WeintCodexBuffTimes", UIParent)
    row:SetSize(28, 28)
    row.icons = {}
    row.WCShowForUnlock = function(self, on) self._unlock = on and true or nil BT.Update() end
    K.RegisterMover(row, "bufftimes", "Buffzeiten", K.Layout("bufftimes"))
    local ev = CreateFrame("Frame")
    for _, e in ipairs({ "UNIT_SPELLCAST_SUCCEEDED", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED",
        "PLAYER_DEAD", "UNIT_AURA", "UNIT_INVENTORY_CHANGED", "PLAYER_ENTERING_WORLD" }) do
        pcall(ev.RegisterEvent, ev, e)
    end
    ev:SetScript("OnEvent", K.Measured("Buffzeiten", OnEvent))
    ev:SetScript("OnUpdate", K.Measured("Buffzeiten", Tick))
    BT.Reconcile(Now(), K.InCombat())
    BT.Update()
end

-- Zeilen fuer /wcui pruefen.
function BT.StatusLines()
    local s = BT.stats
    local out = {}
    out[#out + 1] = string.format("Klasse %s: %d Gruppen", tostring(BT.class or "unbekannt"), #BT.Groups())
    out[#out + 1] = string.format("Zauber gesehen: %d, verfolgt: %d, nicht sicher auf dich: %d",
        s.casts, s.tracked, s.notSelf)
    local secret
    if s.secretInCombat > 0 then secret = "ja (" .. s.secretInCombat .. "×)"
    elseif s.plainInCombat > 0 then secret = "nein (" .. s.plainInCombat .. " offen gelesen)"
    else secret = "ungemessen – einmal im Kampf zaubern" end
    out[#out + 1] = "Zauber-ID im Kampf geheim: " .. secret
    out[#out + 1] = string.format("Abgleich mit Auren: %d, gefunden: %d, entfernt: %d",
        s.reconciled, s.found, s.removed)
    return out
end

function BT.BuildPage(B)
    B:Section("Buffzeiten aus Zaubern", "Eigene Buffs mit fester Dauer – Siegel, Aspekte, Rüstungen, Schilde – zeigt WeintCodex aus deinem Zauber, auch im Kampf, wo der Client die Aura nicht herausgibt. Dauern aus Classic; außerhalb des Kampfes wird mit der echten Aura abgeglichen.")
    B:Row({ type = "toggle", label = "Buffzeiten zeigen", key = "castTimes" },
          { type = "toggle", label = "Fehlt im Kampf zeigen", key = "castMissing",
            disabled = function() return Opt("castTimes") == false end,
            description = "Im Kampf grau mit „!“, wenn z. B. kein Siegel aktiv ist – nur für Zauber, die du gelernt hast." })
    B:Row({ type = "slider", label = "Größe", key = "castSize", min = 20, max = 56, step = 2,
            format = function(v) return string.format("%d px", v) end }, nil)
    B:Note("Verschieben im Gestaltungsmodus. Dauer unbekannt (Zerhäckseln): „läuft“ ohne Uhr; ohne Dauer (Aspekt, Gestalt): „an“.")
end
