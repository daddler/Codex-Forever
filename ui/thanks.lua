--------------------------------------------------
-- WeintCodex :: Komfort - Danke fuer den Buff (6.39.0.0)
--------------------------------------------------
-- Wunsch aus dem Forum: gibt dir draussen in der Welt ein Fremder einen
-- Buff, fluestert WeintCodex ihm einen Dank - mit einem Augenzwinkern,
-- passend zum Buff (Ausdauer, Willenskraft, Intelligenz, Segen) oder
-- allgemein. Eigene deutsche Saetze, keine Uebersetzung.
--
-- Wann: ein neuer hilfreicher Buff auf dir (UNIT_AURA, addedAuras) mit
-- mindestens einer Minute Dauer (keine Heilung, kein Proc), von einem
-- Spieler, der nicht du ist, nicht in deiner Gruppe, ausserhalb von
-- Instanzen und ausserhalb des Kampfes. Gilde nur auf Wunsch. Derselbe
-- Spieler hoechstens alle 15 Minuten, insgesamt hoechstens alle 20 s.
--
-- GRENZE: wer gebufft hat, nennt der Client nur, wenn er ihn als Einheit
-- kennt (Ziel, Maus, Namensplakette sichtbar ...). Kennt er ihn nicht,
-- bleibt der Dank aus - geraten wird nie.
--
-- SENDEN: ob Forever ein Addon fluestern laesst, ist ungemessen (an die
-- Gilde gesperrt, 6.10.4.6). WeintCodex versucht es; meldet das Spiel eine
-- Sperre, merkt es sich das und legt den Dank ab dann in die Chatzeile -
-- Enter sendet.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIThanks = {}

local TH = WeintCodex.UIThanks
local K  = WeintCodex.UIKit
local KEY = "comfort"

TH.MIN_DURATION = 60
TH.PER_PLAYER = 15 * 60
TH.GLOBAL = 20
TH.BLOCK_WINDOW = 1

TH.LINES = {
    general = {
        "Danke! Möge deine Beute episch und dein Wurf hoch sein.",
        "Danke! Mögen deine Taschen leer und deine Reparaturen billig sein.",
        "Buff erhalten. Gehirnzellen weiterhin optional.",
        "Vielen Dank, edle Seele. Mein nächstes graues Item trägt deinen Namen.",
        "Danke! Möge deine nächste Gruppe die Mechaniken kennen.",
        "Segen über deine Beutetabelle!",
        "Danke! Möge deine Bedrohung niedrig und dein Schaden hoch sein.",
        "Du hast meinen Dank – und meinen nächsten Ruhestein-Moment.",
    },
    stamina = {
        "Danke! Ich fühle mich schon gesünder. Glaube ich.",
        "Mehr Ausdauer! Jetzt halte ich sogar den nächsten Patrouillengegner aus. Vielleicht.",
        "Danke! Meine Lebensleiste hat dich gerade lieb gewonnen.",
    },
    spirit = {
        "Danke! Möge dein Geist niemals gebannt werden.",
        "Willenskraft erhalten. Der Wille war da, jetzt auch die Kraft.",
    },
    intellect = {
        "Danke für die Intelligenz – ich war fast leer.",
        "Hirn-Buff erhalten. Gedanken folgen in Kürze.",
        "Intelligenz erhöht. Gesunder Menschenverstand unverändert.",
    },
    blessing = {
        "Gesegnet seist du. Wortwörtlich.",
        "Möge das Licht deine Segen segnen.",
        "Danke, glänzender Ritter!",
        "Dein Segen ist ein Geschenk. Deine Bubble ein Lebensstil.",
    },
}

TH.KINDS = {
    { value = "general",   text = "Allgemein (jeder andere Buff)" },
    { value = "stamina",   text = "Ausdauer" },
    { value = "spirit",    text = "Willenskraft" },
    { value = "intellect", text = "Intelligenz" },
    { value = "blessing",  text = "Segen" },
}

-- Welche Sorte: nach dem Namen des Buffs, wie der Client ihn nennt.
TH.WORDS = {
    { "stamina",   { "seelenstärke", "ausdauer", "fortitude", "stamina" } },
    { "spirit",    { "göttlicher wille", "willenskraft", "divine spirit", "spirit" } },
    { "intellect", { "intelligenz", "brillanz", "intellect", "brilliance" } },
    { "blessing",  { "segen", "blessing" } },
}

local st = { last = {}, at = -1e9, sendAt = -1e9, sent = 0, queued = 0 }
TH.state = st

function TH.Active()
    return K.IsActive(KEY) and K.Get(KEY, "thanks") ~= false
end

local function Now() return (_G.GetTime and _G.GetTime()) or 0 end

-- 6.41.0.0 (Wunsch: "einsehen, was zu was eingestellt ist, bearbeiten,
-- loeschen, hinzufuegen"): Saetze und Erkennungswoerter je Sorte gehoeren
-- dem Spieler (thanksLines/thanksWords); bis zur ersten Aenderung gelten
-- die von WeintCodex.
-- 6.41.2.0: "Blase" heisst unter Spielern "Bubble" - auch in schon
-- uebernommenen eigenen Listen berichtigt (nur genau dieser Satz).
TH.FIXES = { ["Dein Segen ist ein Geschenk. Deine Blase ein Lebensstil."] = "Dein Segen ist ein Geschenk. Deine Bubble ein Lebensstil." }
function TH.Lines(kind)
    local own = K.Get(KEY, "thanksLines")
    if type(own) == "table" and type(own[kind]) == "table" then
        local list = own[kind]
        for i, t in ipairs(list) do
            if TH.FIXES[t] then list[i] = TH.FIXES[t] end
        end
        return list
    end
    return TH.LINES[kind] or {}
end

-- Zum Bearbeiten: eigene Kopie anlegen (einmal je Sorte).
function TH.OwnLines(kind)
    local own = K.Get(KEY, "thanksLines")
    if type(own) ~= "table" then K.Set(KEY, "thanksLines", {}) own = K.Get(KEY, "thanksLines") end
    if type(own[kind]) ~= "table" then
        own[kind] = {}
        for i, t in ipairs(TH.LINES[kind] or {}) do own[kind][i] = t end
    end
    return own[kind]
end

function TH.Words(kind)
    local own = K.Get(KEY, "thanksWords")
    if type(own) == "table" and type(own[kind]) == "table" then return own[kind] end
    for _, w in ipairs(TH.WORDS) do if w[1] == kind then return w[2] end end
    return {}
end

function TH.SetWords(kind, text)
    local own = K.Get(KEY, "thanksWords")
    if type(own) ~= "table" then K.Set(KEY, "thanksWords", {}) own = K.Get(KEY, "thanksWords") end
    local list = {}
    for w in tostring(text or ""):gmatch("[^,]+") do
        w = w:gsub("^%s+", ""):gsub("%s+$", ""):lower()
        if w ~= "" then list[#list + 1] = w end
    end
    own[kind] = list
end

function TH.Kind(name)
    if type(name) ~= "string" then return "general" end
    local low = name:lower()
    for _, w in ipairs(TH.WORDS) do
        for _, word in ipairs(TH.Words(w[1])) do
            if low:find(word, 1, true) then return w[1] end
        end
    end
    return "general"
end

function TH.Pick(kind, roll)
    local list = TH.Lines(kind)
    -- Ab und zu ein allgemeiner Satz (einstellbar): sonst hoert ein Priester
    -- immer dieselben drei.
    local mix = (tonumber(K.Get(KEY, "thanksMix")) or 30) / 100
    if kind ~= "general" and ((roll or math.random()) < mix or #list == 0) then list = TH.Lines("general") end
    if #list == 0 then return nil end
    return list[math.random(#list)]
end

local function Bool(fn, ...)
    if type(fn) ~= "function" then return false end
    local ok, v = pcall(fn, ...)
    return ok and K.Bool(v, false) or false
end

-- Soll dieser Buff einen Dank bekommen? Liefert den Namen des Spielers.
function TH.Eligible(aura)
    if type(aura) ~= "table" then return nil end
    local helpful = K.Plain(aura.isHelpful)
    if helpful == false then return nil end
    local src = K.Plain(aura.sourceUnit)
    if type(src) ~= "string" or src == "" then return nil end
    local dur = K.Plain(aura.duration)
    if type(dur) ~= "number" or dur < TH.MIN_DURATION then return nil end
    if Bool(_G.UnitIsUnit, src, "player") then return nil end
    if not Bool(_G.UnitIsPlayer, src) then return nil end
    if Bool(_G.UnitInParty, src) or Bool(_G.UnitInRaid, src) then return nil end
    if not K.Get(KEY, "thanksGuild") and Bool(_G.UnitIsInMyGuild, src) then return nil end
    local name = _G.GetUnitName and K.Plain(_G.GetUnitName(src, true))
    if type(name) ~= "string" or name == "" then return nil end
    return name
end

function TH.Where()
    if K.InCombat() then return false end
    if _G.IsInInstance then
        local ok, inside = pcall(_G.IsInInstance)
        -- 6.53.3.0 (Wunsch: "in Instanzen ein-/ausschaltbar, voreingestellt
        -- aus"): bis dahin fest aus.
        if ok and K.Bool(inside, false) and not K.Get(KEY, "thanksInstance") then return false end
    end
    return true
end

local function OpenChat(text)
    if _G.ChatFrame_OpenChat then pcall(_G.ChatFrame_OpenChat, text) end
end

function TH.Send(name, text)
    local now = Now()
    st.last[name], st.at = now, now
    local whisper = text
    if K.Get(KEY, "thanksBlocked") then
        OpenChat("/w " .. name .. " " .. whisper)
        return "chat"
    end
    st.sendAt = now
    st.blockedNow = nil
    local f = (_G.C_ChatInfo and _G.C_ChatInfo.SendChatMessage) or _G.SendChatMessage
    local ok = f and pcall(f, whisper, "WHISPER", nil, name)
    if not ok or st.blockedNow then
        OpenChat("/w " .. name .. " " .. whisper)
        return "chat"
    end
    st.sent = st.sent + 1
    return "sent"
end

function TH.OnAura(info)
    if not (TH.Active() and type(info) == "table") then return end
    local added = info.addedAuras
    if type(added) ~= "table" or not TH.Where() then return end
    local now = Now()
    if now - st.at < TH.GLOBAL then return end
    for _, aura in ipairs(added) do
        local name = TH.Eligible(aura)
        if name and now - (st.last[name] or -1e9) >= TH.PER_PLAYER then
            local text = TH.Pick(TH.Kind(K.Plain(aura.name)))
            if not text then return end
            st.last[name], st.at = now, now
            -- Wartezeit (6.41.0.0, einstellbar): nicht im selben Augenblick
            -- wie der Buff - wirkt menschlicher.
            local delay = tonumber(K.Get(KEY, "thanksDelay")) or 2
            if delay > 0 and _G.C_Timer and _G.C_Timer.After then
                st.queued = st.queued + 1
                _G.C_Timer.After(delay, function()
                    st.queued = st.queued - 1
                    if TH.Active() and not K.InCombat() then TH.Send(name, text) end
                end)
            else
                TH.Send(name, text)
            end
            return
        end
    end
end

-- Sperre kurz nach dem eigenen Versuch: gemessen, merken.
function TH.OnBlocked(addon)
    if K.Plain(addon) ~= "WeintCodex" or Now() - st.sendAt > TH.BLOCK_WINDOW then return false end
    st.blockedNow = true
    K.Set(KEY, "thanksBlocked", true)
    print(WeintCodex.ColorText("accent", "[WeintCodex]")
        .. " Das Spiel lässt WeintCodex nicht selbst flüstern – der Dank steht ab jetzt in der Chatzeile, Enter sendet.")
    return true
end

local ev = CreateFrame("Frame")
pcall(ev.RegisterUnitEvent, ev, "UNIT_AURA", "player")
pcall(ev.RegisterEvent, ev, "ADDON_ACTION_BLOCKED")
pcall(ev.RegisterEvent, ev, "ADDON_ACTION_FORBIDDEN")
ev:SetScript("OnEvent", function(_, event, a1, a2)
    if event == "UNIT_AURA" then
        if a1 == "player" then pcall(TH.OnAura, a2) end
    else
        TH.OnBlocked(a1)
    end
end)

function TH.StatusLine()
    return string.format("Danke für Buffs: %s · gedankt %d× · %s",
        TH.Active() and "an" or "aus", st.sent,
        K.Get(KEY, "thanksBlocked") and "Flüstern gesperrt, über die Chatzeile" or "flüstert selbst")
end

--------------------------------------------------
-- Einstellungen: eigene Seite "Danke" (6.41.0.0)
--------------------------------------------------

local edit = { kind = "general", line = 1, input = "", top = 0 }
TH.edit = edit

local ROWS = 8
local function LineList(parent, width)
    local w = CreateFrame("Frame", nil, parent)
    local rows = {}
    for i = 1, ROWS do
        local r = CreateFrame("Frame", nil, w)
        r:SetSize(width, 22)
        r:SetPoint("TOPLEFT", w, "TOPLEFT", 0, -(i - 1) * 24)
        r.sel = r:CreateTexture(nil, "BACKGROUND")
        r.sel:SetAllPoints(r)
        local ac = WeintCodex.Colors.accent
        r.sel:SetColorTexture(ac[1], ac[2], ac[3], 0.18)
        r.text = K.NewText(r, 12)
        r.text:SetPoint("LEFT", r, "LEFT", 6, 0)
        r.text:SetPoint("RIGHT", r, "RIGHT", -30, 0)
        r.text:SetJustifyH("LEFT")
        r:EnableMouse(true)
        r:SetScript("OnMouseDown", function()
            if r.index then edit.line = r.index edit.input = TH.Lines(edit.kind)[r.index] or "" K.Fire("setting", KEY, "thanksEdit") end
        end)
        r.del = WeintCodex.CreateButton(r, { text = "×", kind = "secondary", height = 20, size = 12, backdrop = "bgDark",
            onClick = function()
                local list = TH.OwnLines(edit.kind)
                if r.index then table.remove(list, r.index) K.Fire("setting", KEY, "thanksLines") end
            end })
        r.del:SetWidth(22)
        r.del:SetPoint("RIGHT", r, "RIGHT", 0, 0)
        rows[i] = r
    end
    -- Blaettern (6.41.1.0): Mausrad ueber der Liste oder die Pfeile.
    local function Scroll(delta)
        local n = #TH.Lines(edit.kind)
        edit.top = math.max(0, math.min(math.max(0, n - ROWS), edit.top - delta))
        w.Sync()
    end
    w:EnableMouseWheel(true)
    w:SetScript("OnMouseWheel", function(_, delta) Scroll(delta) end)
    w.up = WeintCodex.CreateButton(w, { text = "▲", kind = "secondary", height = 20, size = 10, backdrop = "bgDark",
        onClick = function() Scroll(ROWS) end })
    w.up:SetWidth(28)
    w.up:SetPoint("TOPRIGHT", w, "TOPLEFT", width - 0, -ROWS * 24 - 2)
    w.down = WeintCodex.CreateButton(w, { text = "▼", kind = "secondary", height = 20, size = 10, backdrop = "bgDark",
        onClick = function() Scroll(-ROWS) end })
    w.down:SetWidth(28)
    w.down:SetPoint("RIGHT", w.up, "LEFT", -4, 0)
    w.more = K.NewText(w, 11)
    w.more:SetPoint("TOPLEFT", w, "TOPLEFT", 6, -ROWS * 24 - 4)
    w.Sync = function()
        local list = TH.Lines(edit.kind)
        edit.top = math.max(0, math.min(edit.top, math.max(0, #list - ROWS)))
        for i, r in ipairs(rows) do
            local idx = edit.top + i
            local t = list[idx]
            if t then
                r.index = idx
                r.text:SetText(t)
                r.sel:SetShown(idx == edit.line)
                r:Show()
            else
                r.index = nil
                r:Hide()
            end
        end
        local many = #list > ROWS
        w.up:SetShown(many)
        w.down:SetShown(many)
        w.more:SetText(many and string.format("%d–%d von %d · Mausrad oder Pfeile", edit.top + 1, math.min(#list, edit.top + ROWS), #list)
            or (#list == 0 and "Keine Sprüche – dann gilt ein allgemeiner." or ""))
    end
    w.Sync()
    return w
end

local function Build(B)
    local off = function() return K.Get(KEY, "thanks") == false end
    B:Section("Danke für Buffs", "Draußen in der Welt, außerhalb von Gruppe und Kampf: ein Flüstern mit Augenzwinkern, passend zum Buff. Nur wenn das Spiel sagt, wer gebufft hat.")
    B:Row({ type = "toggle", label = "Fremden für Buffs danken", key = "thanks" },
          { type = "toggle", label = "Auch der Gilde", key = "thanksGuild", disabled = off })
    B:Row({ type = "toggle", label = "Auch in Instanzen", key = "thanksInstance", disabled = off,
            description = "Dungeons, Schlachtzüge, Schlachtfelder. Aus: nur in der freien Welt." },
          { type = "empty" })
    B:Row({ type = "slider", label = "Warten vor dem Flüstern", key = "thanksDelay", min = 0, max = 30, step = 1, disabled = off,
            format = function(v) return v == 0 and "sofort" or string.format("%d s", v) end },
          { type = "slider", label = "Allgemeine Sprüche beimischen", key = "thanksMix", min = 0, max = 100, step = 10, disabled = off,
            format = function(v) return string.format("%d %%", v) end })
    B:Section("Sprüche", "Sorte wählen: darunter, woran der Buff erkannt wird, und ihre Sprüche. Anklicken bearbeitet, × löscht.")
    B:Row({ type = "dropdown", label = "Sorte", items = TH.KINDS,
            get = function() return edit.kind end,
            set = function(v) edit.kind, edit.line, edit.input, edit.top = v, 1, "", 0 K.Fire("setting", KEY, "thanksEdit") end },
          { type = "input", label = "Erkannt an (Wörter im Buffnamen, mit Komma)",
            disabled = function() return edit.kind == "general" end,
            get = function() return edit.kind == "general" and "– alles andere –" or table.concat(TH.Words(edit.kind), ", ") end,
            set = function(v) if edit.kind ~= "general" then TH.SetWords(edit.kind, v) end end })
    B:Row({ type = "custom", height = ROWS * 24 + 26, create = function(parent, width) return LineList(parent, width) end }, nil)
    B:Row({ type = "input", label = "Spruch (anklicken zum Bearbeiten, oder neu schreiben)",
            get = function() return edit.input end, set = function(v) edit.input = v end },
          { type = "button", label = "Neuer Spruch", text = "Hinzufügen", onClick = function()
                local t = (edit.input or ""):gsub("^%s+", ""):gsub("%s+$", "")
                if t == "" then return end
                local list = TH.OwnLines(edit.kind)
                list[#list + 1] = t
                edit.line, edit.input = #list, ""
                edit.top = math.max(0, #list - ROWS)
                K.Fire("setting", KEY, "thanksLines")
            end })
    B:Row({ type = "button", label = "Ausgewählter Spruch", text = "Ersetzen durch den Text oben", onClick = function()
                local t = (edit.input or ""):gsub("^%s+", ""):gsub("%s+$", "")
                local list = TH.OwnLines(edit.kind)
                if t ~= "" and list[edit.line] then list[edit.line] = t K.Fire("setting", KEY, "thanksLines") end
            end },
          { type = "button", label = "Diese Sorte", text = "Sprüche von WeintCodex zurück", onClick = function()
                local own = K.Get(KEY, "thanksLines")
                if type(own) == "table" then own[edit.kind] = nil end
                local ow = K.Get(KEY, "thanksWords")
                if type(ow) == "table" then ow[edit.kind] = nil end
                K.Fire("setting", KEY, "thanksLines")
            end })
end

local mod = K.Module(KEY)
if mod then
    if mod.defaults.thanks == nil then mod.defaults.thanks = true end
    if mod.defaults.thanksGuild == nil then mod.defaults.thanksGuild = false end
    if mod.defaults.thanksInstance == nil then mod.defaults.thanksInstance = false end
    if mod.defaults.thanksDelay == nil then mod.defaults.thanksDelay = 2 end
    if mod.defaults.thanksMix == nil then mod.defaults.thanksMix = 30 end
    mod.pages[#mod.pages + 1] = { key = "danke", label = "Danke", build = Build }
    if type(mod.pageOrder) == "table" then mod.pageOrder.danke = 31.5 end
    local view = mod.pages and mod.pages[2]
    if view then
        local build = view.build
        view.build = function(B)
            build(B)
            B:Section("Zauber")
            B:Row({ type = "toggle", label = "Manaeffizienz im Tooltip", key = "spellEfficiency",
                    description = "Heilung oder Schaden je Mana und je Sekunde – aus den Zahlen des Tooltips, für niedrigere Ränge gut zum Vergleichen." },
                  { type = "empty" })
        end
    end
end
