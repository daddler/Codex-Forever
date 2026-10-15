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
        "Dein Segen ist ein Geschenk. Deine Blase ein Lebensstil.",
    },
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
    return K.IsActive(KEY) and K.Get(KEY, "thanks") == true
end

local function Now() return (_G.GetTime and _G.GetTime()) or 0 end

function TH.Kind(name)
    if type(name) ~= "string" then return "general" end
    local low = name:lower()
    for _, w in ipairs(TH.WORDS) do
        for _, word in ipairs(w[2]) do
            if low:find(word, 1, true) then return w[1] end
        end
    end
    return "general"
end

function TH.Pick(kind, roll)
    local list = TH.LINES[kind] or TH.LINES.general
    -- Haeufig auch ein allgemeiner Satz: sonst hoert ein Priester immer
    -- dieselben drei.
    if kind ~= "general" and (roll or math.random()) < 0.3 then list = TH.LINES.general end
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
        if ok and K.Bool(inside, false) then return false end
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
            TH.Send(name, TH.Pick(TH.Kind(K.Plain(aura.name))))
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

local mod = K.Module(KEY)
if mod then
    if mod.defaults.thanks == nil then mod.defaults.thanks = false end
    if mod.defaults.thanksGuild == nil then mod.defaults.thanksGuild = false end
    local page = mod.pages and mod.pages[1]
    if page then
        local build = page.build
        page.build = function(B)
            build(B)
            B:Section("Danke für Buffs")
            B:Row({ type = "toggle", label = "Fremden für Buffs danken", key = "thanks",
                    description = "Draußen in der Welt, außerhalb von Gruppe und Kampf: ein Flüstern mit Augenzwinkern, passend zum Buff. Nur wenn das Spiel sagt, wer gebufft hat." },
                  { type = "toggle", label = "Auch der Gilde", key = "thanksGuild",
                    disabled = function() return not K.Get(KEY, "thanks") end })
        end
    end
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
