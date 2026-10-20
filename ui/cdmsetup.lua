--------------------------------------------------
-- WeintCodex :: Oberflaeche - Abklingzeitmanager je Klasse einrichten
--------------------------------------------------
-- Wunsch des Besitzers (Bild seines Jaegers): "Mach mir fuer alle Klassen
-- einen vernuenftigen Abklingzeitenmanager, der so aufgebaut ist wie hier
-- bei meinem Jaeger. Wer schon einen hat, soll seinen behalten - es darf
-- nichts ueberschrieben werden. Beim Paladin sind z. B. die Siegel
-- wichtig."
--
-- WAS DAS SPIEL ANBIETET (Blizzard_CooldownViewer, gelesen in
-- Gethe/wow-ui-source, Zweig live, Oktober 2026):
--   * C_CooldownViewer.GetCooldownViewerCategorySet(Kategorie, true) und
--     GetCooldownViewerCooldownInfo(id) nennen, welche Abklingzeiten der
--     Client ueberhaupt anbietet (spellID, overrideSpellID,
--     linkedSpellIDs, isKnown, category).
--   * Die Zuordnung "welcher Zauber in welche Reihe" steht in Layouts des
--     Managers (CooldownViewerLayoutManagerMixin, je Charakter, je
--     Klasse+Spezialisierung, hoechstens 5). Ohne Layout gilt die Vorgabe
--     des Spiels ("Default", Layoutnummer 0). Gespeichert wird alles als
--     EINE Zeichenkette ueber C_CooldownViewer.GetLayoutData/SetLayoutData
--     (CooldownViewerDataStoreSerializationMixin).
--   * Der Code des Fensters laeuft NICHT gesichert (nur
--     CooldownViewerSecure.lua ist es); kein Aufruf ist als geschuetzt
--     markiert. Trotzdem fasst WeintCodex den laufenden Manager des Spiels
--     nicht an: jeder Wert, den ein Addon dort schreibt, ist "tainted",
--     und die Anzeigen lesen ihn im Kampf - mit geheimen Werten.
--
-- WIE WEINTCODEX ES MACHT: eine eigene, kurzlebige Kopie aus den Mixins
-- des Spiels (Layoutverwaltung, Datenquelle, Serialisierer), die die
-- gespeicherte Zeichenkette liest, ein Layout "WeintCodex" anlegt, die
-- Zauber zuordnet und die neue Zeichenkette ueber SetLayoutData
-- zurueckschreibt. Benachrichtigungen der Kopie sind stumm (sonst liefen
-- die Anzeigen des Spiels aus Addon-Code neu). Der Manager des Spiels
-- liest die Zeichenkette erst beim naechsten Laden - deshalb "Neu laden".
--
-- NICHTS UEBERSCHREIBEN (wie ui/profile.lua beim Bearbeitungsmodus):
--   * Gibt es irgendein Layout, das nicht von WeintCodex ist, oder ist ein
--     fremdes aktiv: nichts veraendert ("eigene Einstellung erkannt").
--   * Eingerichtet wird nur von der Vorgabe des Spiels aus; die Nummer des
--     eigenen Layouts merkt sich der Charakter (K.CharState().cdm).
--   * Von selbst nur EINMAL je Charakter und Spezialisierung. Hat der
--     Spieler das WeintCodex-Layout geloescht, bleibt es geloescht - bis
--     er "Jetzt einrichten" drueckt.
--   * Ausschalten: steht "WeintCodex" noch aktiv, wird es entfernt und die
--     Vorgabe des Spiels gilt wieder (die war vorher aktiv, sonst haette
--     WeintCodex nichts getan). Ist ein anderes aktiv: nichts.
--   * Nie im Kampf.
--
-- HERKUNFT der Listen: Zaubernummern aus Classic, dieselben wie im
-- Lehrerbestand (data/trainer.lua; load_test.lua prueft je Klasse). Art
-- `classic`. Sie behaupten nicht, dass Forever sie anbietet: zugeordnet
-- wird nur, was der Client im Abklingzeitmanager nennt und der Charakter
-- kennt; alles andere wird uebersprungen, nie geraten.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UICooldownSetup = {}

local CS = WeintCodex.UICooldownSetup
local K = WeintCodex.UIKit
local KEY = "reminders"
local NAME = "WeintCodex"

CS.SOURCE = { kind = "classic", label = "Zaubernummern aus Classic, wie im Lehrerbestand" }
CS.NAME = NAME
CS.MAX = { essential = 8, utility = 6, buffs = 12 }   -- 6.87.1.0: 12 Buffs (Siegel des Furors)

-- Je Klasse: Reihe "Wichtig" (Rotation, kurze Abklingzeiten), "Hilfreich"
-- (laengere, Verteidigung, Unterbrechen) und "Buffs" (eigene Dauerbuffs,
-- Siegel, Auren, Aspekte, Formen). Eine ID steht fuer ihre ganze
-- Rangkette (data/trainer.lua, T.RankChain).
CS.LISTS = {
    WARRIOR = {
        essential = { 7384, 6572, 23923, 21551, 23892, 6343, 100, 20252 }, -- Ueberwaeltigen, Rache, Schildschlag, Toedlicher Stoss, Blutdurst, Donnerknall, Sturmangriff, Abfangen
        utility   = { 6552, 72, 18499, 2687, 871, 1719 },                  -- Zuschlagen, Schildhieb, Berserkerwut, Blutrausch, Schildwall, Tollkuehnheit
        buffs     = { 6673, 2565 },                                         -- Schlachtruf, Schildblock
    },
    PALADIN = {
        essential = { 20271, 879, 853, 26573, 24275, 2812, 20929 },         -- Richturteil, Exorzismus, Hammer der Gerechtigkeit, Weihe, Hammer des Zorns, Heiliger Zorn, Heiliger Schock
        utility   = { 498, 642, 1022, 633, 1044, 19752 },                   -- Goettlicher Schutz, Gottesschild, Segen des Schutzes, Handauflegung, Segen der Freiheit, Goettliches Eingreifen
        buffs     = { 20287, 20164, 20165, 20166, 21082, 20915, 20163,      -- Siegel: Rechtschaffenheit, Gerechtigkeit, Licht, Weisheit, Kreuzfahrer, Befehl, Furor (Forever, 6.87.1.0)
                      465, 7294, 19746, 25780 },                            -- Aura der Hingabe, Vergeltungsaura, Aura der Konzentration, Zorn der Gerechtigkeit
    },
    HUNTER = {
        essential = { 3044, 2643, 20900, 5116, 1495, 1499, 13813, 13795 },  -- Arkaner Schuss, Mehrfachschuss, Gezielter Schuss, Erschuetternder Schuss, Mungobiss, Eiskaeltefalle, Sprengfalle, Feuerbrandfalle
        utility   = { 3045, 781, 5384, 20736, 1543, 1513 },                 -- Schnellfeuer, Rueckzug, Totstellen, Ablenkender Schuss, Leuchtfeuer, Wildtier veraengstigen
        buffs     = { 13165, 13163, 5118, 13159, 20043, 13161, 20905, 3045 }, -- Aspekte: Falke, Affe, Gepard, Rudel, Wildnis, Wildtier; Aura des Volltreffers; Schnellfeuer
    },
    ROGUE = {
        essential = { 1766, 1776, 408, 1966 },                              -- Tritt, Solarplexus, Nierenhieb, Finte
        utility   = { 5277, 2983, 1856, 2094, 1725 },                       -- Entrinnen, Sprinten, Verschwinden, Blenden, Ablenken
        buffs     = { 5171, 5277, 2983, 1784 },                             -- Zerhaecksln, Entrinnen, Sprinten, Verstohlenheit
    },
    PRIEST = {
        essential = { 8092, 17, 14914, 8122, 586, 15430, 2944 },            -- Gedankenschlag, Machtwort: Schild, Heiliges Feuer, Psychischer Schrei, Verblassen, Heilige Nova, Verschlingende Seuche
        utility   = { 6346 },                                               -- Furchtzauberschutz
        buffs     = { 588, 1243, 976, 14752, 17 },                          -- Inneres Feuer, Machtwort: Seelenstaerke, Schattenschutz, Goettlicher Willen, Machtwort: Schild
    },
    MAGE = {
        essential = { 2136, 122, 120, 2139, 1953, 13018, 13031 },           -- Feuerschlag, Frostnova, Kaeltekegel, Gegenzauber, Blinzeln, Druckwelle, Eisbarriere
        utility   = { 12051, 1463, 543, 6143 },                             -- Hervorrufung, Manaschild, Feuerzauberschutz, Frostzauberschutz
        buffs     = { 6117, 7302, 1459, 1463, 543, 6143, 604, 1008 },        -- Magische Ruestung, Eisruestung, Arkane Intelligenz, Manaschild, Zauberschutz, Magie daempfen, Magie verstaerken
    },
    WARLOCK = {
        essential = { 18867, 6353, 18930, 6789, 5484, 603 },                -- Schattenbrand, Seelenfeuer, Feuersbrunst, Todesmantel, Schreckensgeheul, Fluch der Verdammnis
        utility   = { 6229, 698, 693 },                                     -- Schattenzauberschutz, Ritual der Beschwoerung, Seelenstein herstellen
        buffs     = { 706, 6229, 5697 },                                    -- Daemonenruestung, Schattenzauberschutz, Unendlicher Atem
    },
    DRUID = {
        essential = { 5211, 6807, 5209, 16689 },                            -- Hieb, Zermalmen, Herausforderndes Gebruell, Griff der Natur
        utility   = { 1850, 22812, 29166, 20484, 5229, 22842 },             -- Spurt, Baumrinde, Anregen, Wiedergeburt, Wutanfall, Rasende Regeneration
        buffs     = { 9634, 783, 1126, 467, 22812, 1850 },                  -- Terrorbaerengestalt, Reisegestalt, Mal der Wildnis, Dornen, Baumrinde, Spurt
    },
    SHAMAN = {
        essential = { 8042, 8050, 8056, 421, 8177, 2484 },                  -- Erdschock, Flammenschock, Frostschock, Kettenblitzschlag, Totem der Erdung, Totem der Erdbindung
        utility   = { 20608, 8143, 5730, 556 },                             -- Reinkarnation, Totem des Erdstoss, Totem der Steinklaue, Astraler Rueckruf
        buffs     = { 324, 8017, 8024, 8033, 8232, 2645 },                  -- Blitzschlagschild, Waffe des Felsbeissers, Flammenzunge, Frostbrand, Windzorn, Geisterwolf
    },
}

CS.defaults = { cdmClassSetup = true }

local function Opt(k) return K.Get(KEY, k) end

-- Was zuletzt geschah - fuer die Seite und /wcui pruefen.
CS.last = { code = "none", text = "Noch nicht versucht." }

local function Say(code, text, extra)
    CS.last = { code = code, text = text, extra = extra }
    local st = K.CharState and K.CharState()
    if st then
        st.cdm = st.cdm or {}
        st.cdm.lastText = text
    end
    return code, text
end

local function Mem()
    local st = K.CharState and K.CharState()
    if not st then return nil end
    st.cdm = st.cdm or {}
    st.cdm.layouts = st.cdm.layouts or {}   -- [Klasse+Spez.] = Layoutnummer
    st.cdm.done = st.cdm.done or {}         -- [Klasse+Spez.] = einmal von selbst eingerichtet
    st.cdm.before = st.cdm.before or {}     -- [Klasse+Spez.] = vorher aktives eigenes Layout (6.87.1.0)
    return st.cdm
end
CS.Mem = Mem

--------------------------------------------------
-- Was der Client anbietet
--------------------------------------------------

-- Alles, was gebraucht wird, oder nil und warum nicht.
function CS.Api()
    local cv = _G.C_CooldownViewer
    if type(cv) ~= "table" then return nil, "C_CooldownViewer fehlt" end
    for _, fn in ipairs({ "GetCooldownViewerCategorySet", "GetCooldownViewerCooldownInfo", "GetLayoutData", "SetLayoutData" }) do
        if type(cv[fn]) ~= "function" then return nil, "C_CooldownViewer." .. fn .. " fehlt" end
    end
    local need = { "CooldownViewerLayoutManagerMixin", "CooldownViewerDataStoreSerializationMixin",
                   "CooldownViewerSettingsDataProviderMixin", "CreateFromMixins", "CooldownManagerLayout_GetName",
                   "CooldownManagerLayout_GetID" }
    for _, g in ipairs(need) do
        if type(_G[g]) == "nil" then return nil, g .. " fehlt (Blizzard_CooldownViewer nicht geladen?)" end
    end
    local E = _G.Enum and _G.Enum.CooldownViewerCategory
    if type(E) ~= "table" or type(E.Essential) ~= "number" then return nil, "Enum.CooldownViewerCategory fehlt" end
    if type(cv.IsCooldownViewerAvailable) == "function" then
        local ok, avail = pcall(cv.IsCooldownViewerAvailable)
        if ok and K.Bool(avail, true) == false then return nil, "Der Client meldet den Abklingzeitmanager als nicht verfügbar" end
    end
    return { cv = cv, cat = E }
end

-- Alle Zaubernummern, fuer die eine Liste steht (ganze Rangkette).
function CS.Expand(class, id)
    local T = WeintCodex.TrainerData
    local chain = T and T.RankChain and T.RankChain(class, id)
    local out = { [id] = true }
    for _, x in ipairs(chain or {}) do out[x] = true end
    return out
end

--------------------------------------------------
-- Die Kopie des Managers
--------------------------------------------------

-- Eine Layoutverwaltung aus den Mixins des Spiels, die nur liest, was
-- gespeichert ist, und erst auf Wunsch schreibt. Nichts davon beruehrt den
-- laufenden Manager.
function CS.Shadow(A)
    local G = _G
    local out = { data = nil }
    local persist = {
        GetSerializedData = function()
            local ok, s = pcall(A.cv.GetLayoutData)
            s = ok and K.Plain(s) or nil
            return type(s) == "string" and s or ""
        end,
        SetSerializedData = function(_, s) out.data = s end,
        ClearSerializedData = function() out.data = "" end,
    }
    local mgr = G.CreateFromMixins(G.CooldownViewerLayoutManagerMixin)
    local ser = G.CreateFromMixins(G.CooldownViewerDataStoreSerializationMixin)
    local dp = G.CreateFromMixins(G.CooldownViewerSettingsDataProviderMixin)
    -- Stumm: keine Ereignisse an das Fenster und die Anzeigen des Spiels.
    mgr.NotifyListeners = function() end
    mgr.SetHasPendingChanges = function(self, p) self.hasPendingChanges = p end
    mgr:Init(dp, ser)
    ser:Init(mgr, persist)
    dp:SetLayoutManager(mgr)   -- nicht dp:Init: das meldet Ereignisse an
    dp:MarkDirty()
    mgr:SwitchToBestLayoutForSpec()
    return { mgr = mgr, ser = ser, dp = dp, out = out }
end

local function LayoutName(l) return K.Plain(_G.CooldownManagerLayout_GetName(l)) end
local function LayoutID(l) return K.Plain(_G.CooldownManagerLayout_GetID(l)) end

-- Wem gehoert, was da ist? ours = unser Layout fuer diese Spezialisierung.
function CS.Inspect(sh, mem)
    local mgr = sh.mgr
    local tag = mgr:GetCurrentSpecTag()
    local mine = {}
    for _, id in pairs(mem and mem.layouts or {}) do mine[id] = true end
    local own, ours = 0, nil
    for id, l in mgr:EnumerateLayouts() do
        if mine[id] and LayoutName(l) == NAME then
            if mem.layouts[tag] == id then ours = l end
        else
            own = own + 1
        end
    end
    local active = mgr:GetActiveLayoutID()
    local activeOurs = ours ~= nil and active == LayoutID(ours)
    return { tag = tag, own = own, ours = ours, active = active, activeOurs = activeOurs,
             foreignActive = active ~= nil and not activeOurs }
end

-- Zauber zuordnen: nur, was der Client anbietet, in der passenden Art
-- (aktive Faehigkeit vs. Buff - das Spiel laesst nur so verschieben) und
-- was der Charakter kennt.
function CS.Assign(sh, A, class)
    local list = CS.LISTS[class]
    if not list then return 0, {} end
    local dp, cat = sh.dp, A.cat
    dp:CheckBuildDisplayData()
    local data = dp:GetDisplayData()
    local infos = data and data.cooldownInfoByID or {}
    local function Family(id)
        local ok, raw = pcall(A.cv.GetCooldownViewerCooldownInfo, id)
        local c = ok and type(raw) == "table" and K.Plain(raw.category)
        if c == cat.Essential or c == cat.Utility then return "active" end
        if c == cat.TrackedBuff or c == cat.TrackedBar then return "passive" end
        return nil
    end
    local bySpell = {}   -- [Zauber] = { cooldownID ... }
    for cdID, info in pairs(infos) do
        if K.Bool(info.isKnown, false) then
            local ids = { K.Plain(info.spellID), K.Plain(info.overrideSpellID) }
            for _, x in ipairs(info.linkedSpellIDs or {}) do ids[#ids + 1] = K.Plain(x) end
            for _, s in ipairs(ids) do
                if type(s) == "number" then
                    bySpell[s] = bySpell[s] or {}
                    table.insert(bySpell[s], cdID)
                end
            end
        end
    end
    local plan = {
        { key = "essential", cat = cat.Essential, fam = "active" },
        { key = "utility", cat = cat.Utility, fam = "active" },
        { key = "buffs", cat = cat.TrackedBuff, fam = "passive" },
    }
    local used, order, counts, n = {}, {}, {}, 0
    for _, p in ipairs(plan) do
        counts[p.key] = 0
        for _, id in ipairs(list[p.key] or {}) do
            if counts[p.key] >= CS.MAX[p.key] then break end
            local found
            for s in pairs(CS.Expand(class, id)) do
                for _, cdID in ipairs(bySpell[s] or {}) do
                    if not used[cdID] and Family(cdID) == p.fam then found = cdID break end
                end
                if found then break end
            end
            if found then
                used[found] = true
                local ok, status = pcall(dp.SetCooldownToCategory, dp, found, p.cat)
                if ok and (status == nil or status == 0) then
                    order[#order + 1] = found
                    counts[p.key] = counts[p.key] + 1
                    n = n + 1
                end
            end
        end
    end
    -- Reihenfolge wie in der Liste: unsere vorn, der Rest wie gehabt.
    if n > 0 then
        local all = dp:GetOrderedCooldownIDs() or {}
        local seq, seen = {}, {}
        for _, id in ipairs(order) do seq[#seq + 1] = id seen[id] = true end
        for _, id in ipairs(all) do if not seen[id] then seq[#seq + 1] = id end end
        pcall(sh.mgr.WriteCooldownOrderToActiveLayout, sh.mgr, seq)
    end
    return n, counts
end

-- Die neue Zeichenkette dem Client geben und zuruecklesen.
local function Commit(sh, A)
    sh.ser:WriteData()
    local s = sh.out.data
    if type(s) ~= "string" then return false, "Serialisierer lieferte nichts" end
    local ok, err = pcall(A.cv.SetLayoutData, s)
    if not ok then return false, "SetLayoutData gesperrt: " .. tostring(err) end
    local ok2, back = pcall(A.cv.GetLayoutData)
    back = ok2 and K.Plain(back) or nil
    if back ~= s then return false, "SetLayoutData angenommen, aber nicht gespeichert" end
    if K.MarkReload then K.MarkReload() end
    return true
end

--------------------------------------------------
-- Einrichten und zuruecknehmen
--------------------------------------------------

-- explicit: Knopf "Jetzt einrichten" (darf ein geloeschtes eigenes Layout
-- neu anlegen und das eigene auffrischen).
function CS.Apply(explicit)
    if K.InCombat() then return Say("combat", "Im Kampf – nichts verändert. Nach dem Kampf noch einmal.") end
    local A, why = CS.Api()
    if not A then return Say("unavailable", "Im Client nicht verfügbar: " .. why) end
    local class = _G.UnitClass and select(2, _G.UnitClass("player"))
    if not CS.LISTS[class] then return Say("noclass", "Für diese Klasse gibt es keine Liste.") end
    local mem = Mem()
    if not mem then return Say("nochar", "Charakter noch nicht bekannt – später noch einmal.") end
    local live = _G.CooldownViewerSettings
    local lm = type(live) == "table" and live.GetLayoutManager and live:GetLayoutManager()
    if type(lm) == "table" and lm.HasPendingChanges and lm:HasPendingChanges() then
        return Say("pending", "Im Fenster des Spiels sind Änderungen offen – nichts verändert.")
    end
    local ok, sh = pcall(CS.Shadow, A)
    if not ok then return Say("error", "Layouts nicht lesbar: " .. tostring(sh)) end
    local info = CS.Inspect(sh, mem)
    if type(info.tag) ~= "number" then return Say("nospec", "Klasse/Spezialisierung vom Client nicht genannt – nichts verändert.") end
    -- 6.87.1.0 (Wunsch: "wer die Voreinstellung will, bekommt ein NEUES
    -- Profil, das alte wird nicht ueberschrieben"): von selbst nie, auf
    -- "Jetzt einrichten" legt WeintCodex sein Layout NEBEN die eigenen und
    -- merkt sich, welches vorher aktiv war (Ausschalten kehrt dorthin zurueck).
    if (info.own > 0 or info.foreignActive) and not explicit then
        return Say("own", "Eigene Einstellung erkannt – nichts verändert. „Jetzt einrichten“ legt ein eigenes Profil „" .. NAME .. "“ daneben an.")
    end
    if info.foreignActive and info.active ~= nil and not info.activeOurs then
        mem.before[info.tag] = info.active
    end
    if info.ours and not info.activeOurs and not explicit then
        return Say("own", "Layout „" .. NAME .. "“ ist nicht aktiv – nichts verändert.")
    end
    if not info.ours and mem.done[info.tag] and not explicit then
        return Say("removed", "Layout „" .. NAME .. "“ wurde entfernt – nichts verändert („Jetzt einrichten“ legt es neu an).")
    end
    if info.ours and not explicit then
        return Say("applied", "Eingerichtet (Layout „" .. NAME .. "“ aktiv).")
    end
    local mgr = sh.mgr
    local layout = info.ours
    if not layout then
        local okAdd, l, status = pcall(mgr.AddLayout, mgr, NAME, info.tag)
        if not okAdd or type(l) ~= "table" then
            return Say("error", "Layout nicht angelegt (" .. tostring(okAdd and status or l) .. ").")
        end
        layout = l
    end
    mgr:SetActiveLayout(layout)
    sh.dp:MarkDirty()
    local okA, n, counts = pcall(CS.Assign, sh, A, class)
    if not okA then return Say("error", "Zuordnen gescheitert: " .. tostring(n)) end
    if n == 0 then
        return Say("nomatch", "Der Client bietet keinen Zauber aus der Liste an, den du kennst – nichts verändert.")
    end
    local okC, err = Commit(sh, A)
    if not okC then return Say("error", err) end
    mem.layouts[info.tag] = LayoutID(layout)
    mem.done[info.tag] = true
    return Say("applied", string.format("Eingerichtet: %d wichtig, %d hilfreich, %d Buffs – wirkt nach dem Neuladen.",
        counts.essential or 0, counts.utility or 0, counts.buffs or 0), counts)
end

-- Ausschalten: nur, wenn "WeintCodex" noch aktiv ist.
function CS.Restore()
    if K.InCombat() then return Say("combat", "Im Kampf – nichts verändert.") end
    local A, why = CS.Api()
    if not A then return Say("unavailable", "Im Client nicht verfügbar: " .. why) end
    local mem = Mem()
    if not mem then return Say("nochar", "Charakter noch nicht bekannt.") end
    local ok, sh = pcall(CS.Shadow, A)
    if not ok then return Say("error", "Layouts nicht lesbar: " .. tostring(sh)) end
    local info = CS.Inspect(sh, mem)
    if not info.ours then return Say("off", "Aus – kein Layout „" .. NAME .. "“ da.") end
    if not info.activeOurs then return Say("off", "Aus – „" .. NAME .. "“ ist nicht aktiv, nichts zurückgesetzt.") end
    sh.mgr:RemoveLayout(LayoutID(info.ours))
    -- Vorher aktives eigenes Layout zurueck, sonst die Vorgabe des Spiels.
    local back, prev = nil, mem.before[info.tag]
    if prev then
        for id, l in sh.mgr:EnumerateLayouts() do if id == prev then back = l end end
    end
    if back then sh.mgr:SetActiveLayout(back) else sh.mgr:UseDefaultLayout() end
    mem.before[info.tag] = nil
    local okC, err = Commit(sh, A)
    if not okC then return Say("error", err) end
    mem.layouts[info.tag] = nil
    return Say("restored", "Aus – Vorgabe des Spiels wieder aktiv (wirkt nach dem Neuladen).")
end

function CS.SetEnabled(on)
    K.Set(KEY, "cdmClassSetup", on and true or false)
    if on then CS.Apply(true) else CS.Restore() end
end

-- Beim Betreten der Welt, sobald der Manager des Spiels geladen hat.
function CS.Auto()
    if not Opt("cdmClassSetup") then return end
    -- Eigener Manager gewaehlt: der des Spiels wird nicht eingerichtet.
    local OC = WeintCodex.UIOwnCooldowns
    if OC and OC.Mode and OC.Mode() ~= "blizzard" then return end
    K.AfterCombat(function() CS.Apply(false) end)
end

function CS.Enable()
    local ev = CreateFrame("Frame")
    ev:RegisterEvent("PLAYER_ENTERING_WORLD")
    ev:SetScript("OnEvent", K.Measured("Abklingzeitmanager", function(self)
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
        if _G.C_Timer and _G.C_Timer.After then
            _G.C_Timer.After(5, function() pcall(CS.Auto) end)
        else
            pcall(CS.Auto)
        end
    end))
end

-- Fuer /wcui pruefen.
function CS.StatusLines()
    local out = {}
    local A, why = CS.Api()
    out[#out + 1] = "Schnittstellen: " .. (A and "vorhanden" or ("fehlt – " .. why))
    local mem = Mem()
    if A and mem then
        local ok, sh = pcall(CS.Shadow, A)
        if ok then
            local info = CS.Inspect(sh, mem)
            out[#out + 1] = string.format("Layout „%s“: %s · eigene Layouts: %d · Spez.-Kennung: %s",
                NAME, info.ours and (info.activeOurs and "da, aktiv" or "da, nicht aktiv") or "keins",
                info.own, tostring(info.tag))
        else
            out[#out + 1] = "Layouts nicht lesbar: " .. tostring(sh)
        end
    end
    out[#out + 1] = "Zuletzt: " .. CS.last.text
    return out
end

--------------------------------------------------
-- Abschnitt auf der Seite "Abklingzeitmanager" der Erinnerungen
--------------------------------------------------

function CS.BuildSection(B)
    B:Section("Je Klasse einrichten", "Stellt Wichtig, Hilfreich und Buffs für deine Klasse zusammen (beim Paladin z. B. die Siegel, beim Jäger die Aspekte) – in einem eigenen Layout „" .. NAME .. "“. Hast du im Abklingzeitmanager schon etwas eingestellt, bleibt alles, wie es ist.")
    B:Row({ type = "toggle", label = "Abklingzeitmanager je Klasse einrichten",
            get = function() return Opt("cdmClassSetup") and true or false end,
            set = function(v) CS.SetEnabled(v) end,
            description = "Aus: entfernt „" .. NAME .. "“, wenn es noch aktiv ist." },
          { type = "button", label = "Einrichten", text = "Jetzt einrichten",
            tooltip = "Legt das Layout an oder frischt es auf – nur, wenn du keine eigene Einstellung hast. Außerhalb des Kampfes.",
            onClick = function() CS.Apply(true) end })
    B:Note("Stand: " .. CS.last.text .. " Zugeordnet wird nur, was das Spiel im Abklingzeitmanager anbietet und du gelernt hast.")
end

do
    local m = K.Module(KEY)
    if m then
        for k, v in pairs(CS.defaults) do m.defaults[k] = v end
        local enable = m.Enable
        m.Enable = function(...)
            if enable then enable(...) end
            local ok, err = pcall(CS.Enable)
            if not ok then K.Report("abklingzeitmanager", err) end
        end
    end
end
