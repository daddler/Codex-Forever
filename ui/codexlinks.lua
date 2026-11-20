--------------------------------------------------
-- WeintCodex :: Verweise zu Codex aus den Fenstern des Spiels
--------------------------------------------------
-- 1.0.8.0 (Wunsch: "Immer erst Codex aufmachen und dann sehen, wo was ist,
-- ist auf Dauer muehsam. Im Berufsfenster z. B. eine Verlinkung direkt zu
-- der jeweiligen Kategorie in Codex - und wo es passt, beim Oeffnen eines
-- Fensters ein direkter Weg zu Codex").
--
-- Ein kleiner Knopf an einem Fenster des Spiels oeffnet Codex genau dort,
-- wo es zu diesem Fenster etwas weiss - der Beruf, der gerade offen ist,
-- der Dungeon, in dem man steht. Eigener Knopf an UIParent, nur an das
-- Fenster verankert und mit ihm gezeigt/verborgen: nichts Geschuetztes wird
-- beruehrt, nichts am Fenster des Spiels geaendert. Fenster, die das Spiel
-- erst spaeter laedt (Berufe, Kompendium, Gruppensuche), kommen ueber
-- ADDON_LOADED dazu.
--
-- Was Codex nicht weiss, behauptet der Knopf nicht: ohne erkannten Beruf
-- oeffnet er die Berufe ohne Vorauswahl, ausserhalb eines bekannten
-- Dungeons die Dungeons ohne Vorauswahl.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UICodexLinks = {}

local CL = WeintCodex.UICodexLinks
local K  = WeintCodex.UIKit
local KEY = "comfort"

CL.H = 22
CL.TITLE_H = 22       -- Knopf in der Titelleiste (where = "title")
CL.TITLE_GAP = 6      -- Abstand zum Kreuz
CL.TITLE_ICON = 16
-- Naechsthoehere Schicht fuer Knoepfe, die auf dem Fenster liegen.
CL.ABOVE = { BACKGROUND = "LOW", LOW = "MEDIUM", MEDIUM = "HIGH", HIGH = "DIALOG",
             DIALOG = "FULLSCREEN", FULLSCREEN = "FULLSCREEN_DIALOG" }

local function Plain(v) return K.Plain(v) end

-- Codex oeffnen, auf einem Bereich (tab) - vorher waehlt `pre` aus.
function CL.Open(tab, pre)
    local main, nav = WeintCodex.MainFrame, WeintCodex.Navigation
    if not (main and nav) then return false end
    if pre then pcall(pre) end
    main:Show()
    if nav.GoToTab then nav.GoToTab(tab) elseif nav.SwitchTo then nav.SwitchTo(tab) end
    return true
end

--------------------------------------------------
-- Was gerade offen ist
--------------------------------------------------
-- Der offene Beruf (Schluessel aus data/professions.lua) oder nil.
-- 1.0.8.0 (Bild: "Erste Hilfe gewaehlt, Codex oeffnet den ersten Beruf"):
-- zuerst das Fenster selbst fragen - was es ueber den Beruf weiss, sonst
-- sein Titel ("Erste Hilfe") -, erst dann die allgemeine Suche. Deren
-- letzter Ausweg (irgendein gescannter Beruf) wird hier nie genommen.
local function KeyByName(name)
    local PRO = WeintCodex.Professions
    name = Plain(name)
    if type(name) ~= "string" or name == "" or not (PRO and PRO.KeyByName) then return nil end
    return PRO.KeyByName(name)
end

local function KeyByLine(id)
    local PRO = WeintCodex.Professions
    id = Plain(id)
    if type(id) ~= "number" or not (PRO and PRO.byKey) then return nil end
    for key, p in pairs(PRO.byKey) do if p.line == id then return key end end
    return nil
end

function CL.ProfessionOfWindow(host)
    if type(host) ~= "table" then return nil end
    local info
    if type(host.GetProfessionInfo) == "function" then
        local ok, v = pcall(host.GetProfessionInfo, host)
        if ok and type(v) == "table" then info = v end
    end
    if not info and type(host.professionInfo) == "table" then info = host.professionInfo end
    if info then
        local key = KeyByLine(info.parentProfessionID) or KeyByLine(info.professionID)
            or KeyByName(info.parentProfessionName) or KeyByName(info.professionName)
        if key then return key end
    end
    local title
    if type(host.GetTitleText) == "function" then
        local ok, fs = pcall(host.GetTitleText, host)
        if ok and type(fs) == "table" then title = fs end
    end
    title = title or (type(host.TitleContainer) == "table" and host.TitleContainer.TitleText) or host.TitleText
    if type(title) == "table" and title.GetText then
        local key = KeyByName(title:GetText())
        if key then return key end
    end
    return nil
end

function CL.Profession(host)
    local key = CL.ProfessionOfWindow(host)
    if key then return key end
    local ts = _G.C_TradeSkillUI
    if ts and ts.GetBaseProfessionInfo then
        local ok, info = pcall(ts.GetBaseProfessionInfo)
        if ok and type(info) == "table" then
            key = KeyByLine(info.professionID) or KeyByName(info.professionName)
            if key then return key end
        end
    end
    if _G.GetTradeSkillLine then
        local ok, name = pcall(_G.GetTradeSkillLine)
        key = ok and KeyByName(name) or nil
        if key then return key end
    end
    return nil
end

-- Codex auf genau diesem Beruf: Rezepte, keine Suche, kein Werkzeug-Reiter.
-- Nach dem Wechsel noch einmal zeichnen - war "Berufe" schon offen, tat
-- der Klick auf den Bereich nichts, und die Vorauswahl ging verloren.
function CL.OpenProfession(key)
    local ok = CL.Open("berufe")
    local PRO = WeintCodex.Professions
    if not (ok and key and PRO and PRO.Select and PRO.Show) then return ok end
    PRO.view, PRO.query, PRO.campAll, PRO.selRecipe = nil, "", false, nil
    PRO.Select(key)
    PRO.Show()
    return true
end

-- Der Dungeon, in dem der Spieler steht (Kennung aus data/dungeons.lua)
-- oder nil: Instanznummer -> englischer Name (data/dungeonmaps.lua) ->
-- gleicher Name im Bestand.
function CL.CurrentDungeon()
    local DM = WeintCodex.UIDungeonMap
    if not (DM and DM.Current) then return nil end
    local ok, m = pcall(DM.Current)
    local name = ok and type(m) == "table" and m.name or nil
    local D = WeintCodex.DungeonData
    if type(name) ~= "string" or not (D and D.All) then return nil end
    for _, d in ipairs(D.All()) do
        if d.name == name then return d.id end
    end
    return nil
end

local function IsTradeTrainer()
    if not _G.IsTradeskillTrainer then return nil end
    local ok, v = pcall(_G.IsTradeskillTrainer)
    if not ok then return nil end
    return K.Bool(Plain(v), false)
end

--------------------------------------------------
-- Welche Fenster wohin
--------------------------------------------------
-- host: Name des Fensters; label(): Beschriftung; go(): oeffnen;
-- where: "below" (unter dem Fenster, rechts), "belowleft", "above" oder
-- "title" (Titelleiste neben dem Kreuz, in Gold mit Logo).
CL.LINKS = {
    -- 1.0.8.0 (Rueckmeldung: "Der Button unten beim Berufefenster ist zu
    -- unscheinbar. Lieber oben im Reiter und besser zu sehen"): in der
    -- Titelleiste links neben dem Kreuz, in Gold mit Logo (where = "title").
    { host = "ProfessionsFrame", where = "title", label = function() return "Codex: Berufe" end,
      tip = "Rezepte nach deiner Fertigkeit, Lehrer und Herkunft der Rezepte – für den offenen Beruf.",
      go = function() return CL.OpenProfession(CL.Profession(_G.ProfessionsFrame)) end },
    { host = "TradeSkillFrame", where = "title", label = function() return "Codex: Berufe" end,
      tip = "Rezepte nach deiner Fertigkeit, Lehrer und Herkunft der Rezepte – für den offenen Beruf.",
      go = function() return CL.OpenProfession(CL.Profession(_G.TradeSkillFrame)) end },
    { host = "ClassTrainerFrame", where = "title",
      label = function() return IsTradeTrainer() and "Codex: Berufe" or "Codex: Lehrer" end,
      tip = "Was du hier lernen kannst, was es kostet und was als Nächstes kommt.",
      go = function()
          if IsTradeTrainer() then return CL.Open("berufe") end
          return CL.Open("lehrer")
      end },
    { host = "CharacterFrame", where = "title", label = function() return "Codex: Charakter" end,
      tip = "Ausrüstung, Twinks und Fortschritt deiner Charaktere.",
      go = function() return CL.Open("charakter") end },
    { host = "SpellBookFrame", where = "title", label = function() return "Codex: Lehrer" end,
      tip = "Welche Zauber du bei deinem Lehrer lernen kannst und was sie kosten.",
      go = function() return CL.Open("lehrer") end },
    { host = "PlayerSpellsFrame", where = "title", label = function() return "Codex: Lehrer" end,
      tip = "Welche Zauber du bei deinem Lehrer lernen kannst und was sie kosten.",
      go = function() return CL.Open("lehrer") end },
    { host = "BankFrame", where = "title", label = function() return "Codex: Taschen" end,
      tip = "Was alle deine Charaktere tragen – Taschen, Bank, Ausrüstung.",
      go = function() return CL.Open("taschen") end },
    { host = "ContainerFrameCombinedBags", where = "above", label = function() return "Codex: Taschen" end,
      tip = "Was alle deine Charaktere tragen – Taschen, Bank, Ausrüstung.",
      go = function() return CL.Open("taschen") end },
    { host = "LFGParentFrame", where = "title", label = function() return "Codex: Dungeons" end,
      tip = "Alle Dungeons mit Stufen, Bossen, Beute und Quests.",
      go = function() return CL.Open("dungeons") end },
    { host = "PVEFrame", where = "title", label = function() return "Codex: Dungeons" end,
      tip = "Alle Dungeons mit Stufen, Bossen, Beute und Quests.",
      go = function() return CL.Open("dungeons") end },
    { host = "EncounterJournal", where = "title", label = function() return "Codex: Dungeons" end,
      tip = "Alle Dungeons mit Stufen, Bossen, Beute und Quests.",
      go = function()
          local id = CL.CurrentDungeon()
          return CL.Open("dungeons", function()
              local DP = WeintCodex.DungeonPages
              if id and DP and DP.Select then DP.Select(id) end
          end)
      end },
    -- Nur in einem Dungeon, den Codex kennt: Weltkarte -> dieser Dungeon.
    { host = "WorldMapFrame", where = "title", when = function() return CL.CurrentDungeon() ~= nil end,
      label = function() return "Codex: dieser Dungeon" end,
      tip = "Bosse, Beute und Quests des Dungeons, in dem du gerade bist.",
      go = function()
          local id = CL.CurrentDungeon()
          return CL.Open("dungeons", function()
              local DP = WeintCodex.DungeonPages
              if id and DP and DP.Select then DP.Select(id) end
          end)
      end },
    -- Weitere Fenster (1.0.8.0, Wunsch: "bind zuerst noch die weiteren
    -- Fenster an"). Talentplaner, Ruf-Belohnungen und Feldbuch sind eigene
    -- Fenster von WeintCodex, keine Seiten im Codex.
    { host = "PlayerTalentFrame", where = "title", label = function() return "WeintCodex: Talentplaner" end,
      tip = "Talente Stufe für Stufe planen, teilen und beim Leveln folgen.",
      go = function() local TB = WeintCodex.UITalentBuilds if TB and TB.Open then TB.Open() return true end end },
    { host = "TalentFrame", where = "title", label = function() return "WeintCodex: Talentplaner" end,
      tip = "Talente Stufe für Stufe planen, teilen und beim Leveln folgen.",
      go = function() local TB = WeintCodex.UITalentBuilds if TB and TB.Open then TB.Open() return true end end },
    -- Reiter Ruf im Charakterfenster: links, der Knopf zum Charakter steht rechts.
    { host = "ReputationFrame", where = "title", titleHost = "CharacterFrame", fallback = "belowleft", label = function() return "WeintCodex: Ruf-Belohnungen" end,
      tip = "Was jede Fraktion bei welcher Rufstufe anbietet, mit deinem Stand.",
      go = function()
          local FJ = WeintCodex.UIFieldJournal
          if FJ and FJ.RepReport and K.ShowReport then K.ShowReport("Ruf-Belohnungen", FJ.RepReport()) return true end
      end },
    { host = "AuctionHouseFrame", where = "title", label = function() return "Codex: Berufe" end,
      tip = "Rezepte auf die Einkaufsliste setzen – die Liste steht dann hier im Auktionshaus.",
      go = function() return CL.Open("berufe") end },
    -- Betrachten in einer Gruppe: der Gruppencheck zeigt alle zusammen.
    { host = "InspectFrame", where = "title", when = function()
          local ok, v = pcall(_G.IsInGroup or function() return false end)
          return ok and K.Bool(Plain(v), false)
      end,
      label = function() return "Codex: Gruppencheck" end,
      tip = "Ausrüstung aller in deiner Gruppe auf einen Blick.",
      go = function() return CL.Open("gruppe") end },
    -- Beute beim Angeln: das Feldbuch (Fische, Gebiete, Fertigkeit).
    { host = "LootFrame", when = function()
          if not _G.IsFishingLoot then return false end
          local ok, v = pcall(_G.IsFishingLoot)
          return ok and K.Bool(Plain(v), false)
      end,
      where = "belowleft", label = function() return "WeintCodex: Feldbuch" end,
      tip = "Fische und Kräuter: wo sie am meisten bringen und ab welcher Fertigkeit.",
      go = function()
          local FJ = WeintCodex.UIFieldJournal
          if FJ and FJ.Report and K.ShowReport then K.ShowReport("Feldbuch", FJ.Report()) return true end
      end },
    { host = "LootFrame", when = function() return CL.CurrentDungeon() ~= nil end,
      label = function() return "Codex: Beute" end,
      tip = "Was in diesem Dungeon fällt, mit deiner Wunschliste.",
      go = function() return CL.Open("beute") end },
}

--------------------------------------------------
-- Knoepfe
--------------------------------------------------
CL.buttons = {}   -- [Eintrag aus CL.LINKS] = Knopf (ein Fenster kann mehrere tragen)
CL.order = {}     -- angehaengte Eintraege, in der Reihenfolge von CL.LINKS (Titelleiste: rechts zuerst)
local function Rank(link)
    for i, l in ipairs(CL.LINKS) do if l == link then return i end end
    return math.huge
end

function CL.On() return K.IsActive(KEY) and K.Get(KEY, "codexLinks") ~= false end

-- Das Kreuz eines Fensters (je nach Fenster an anderer Stelle) oder nil.
function CL.CloseOf(host)
    if type(host) ~= "table" then return nil end
    local c = host.CloseButton
    if type(c) ~= "table" and type(host.BorderFrame) == "table" then c = host.BorderFrame.CloseButton end
    if type(c) ~= "table" and host.GetName then
        local n = host:GetName()
        if type(n) == "string" then c = _G[n .. "CloseButton"] end
    end
    return type(c) == "table" and c.GetObjectType and c or nil
end

-- Der Titel des Fensters (FontString) oder nil.
function CL.TitleOf(host)
    if type(host.GetTitleText) == "function" then
        local ok, fs = pcall(host.GetTitleText, host)
        if ok and type(fs) == "table" then return fs end
    end
    local t = (type(host.TitleContainer) == "table" and host.TitleContainer.TitleText) or host.TitleText
    if type(t) ~= "table" and host.GetName then
        local n = host:GetName()
        if type(n) == "string" then t = _G[n .. "TitleText"] end
    end
    return type(t) == "table" and t or nil
end

-- Passt ein Knopf der Breite `w` neben das Kreuz, wenn rechts davon schon
-- `used` Bildpunkte belegt sind - ohne den mittigen Titel zu verdecken?
-- Ohne Masse (Fenster nicht gezeichnet) gilt: passt.
CL.TITLE_CLEAR = 10       -- so viel Luft bleibt zum Titel
function CL.TitleFits(host, close, w, used)
    local W = Plain(host.GetWidth and host:GetWidth())
    if type(W) ~= "number" or W <= 0 then return true end
    local right = W - 30
    local cl, hl = Plain(close and close.GetLeft and close:GetLeft()), Plain(host.GetLeft and host:GetLeft())
    if type(cl) == "number" and type(hl) == "number" then right = cl - hl end
    local tw = 0
    local fs = CL.TitleOf(host)
    if fs and fs.GetStringWidth then
        local v = Plain(fs:GetStringWidth())
        if type(v) == "number" then tw = v end
    end
    local left = right - CL.TITLE_GAP - (used or 0) - (w or 0)
    return left >= W / 2 + tw / 2 + CL.TITLE_CLEAR
end

function CL.Place(b, host, where)
    b:ClearAllPoints()
    if where == "title" then
        -- Links neben dem Kreuz des Fensters, auf seiner Mitte; ohne Kreuz
        -- oben rechts in der Titelleiste.
        local close = CL.CloseOf(host)
        if close then
            b:SetPoint("RIGHT", close, "LEFT", -CL.TITLE_GAP, 0)
        else
            b:SetPoint("TOPRIGHT", host, "TOPRIGHT", -34, -4)
        end
    elseif where == "above" then
        b:SetPoint("BOTTOMRIGHT", host, "TOPRIGHT", 0, 4)
    elseif where == "belowleft" then
        b:SetPoint("TOPLEFT", host, "BOTTOMLEFT", 0, -4)
    else
        b:SetPoint("TOPRIGHT", host, "BOTTOMRIGHT", 0, -4)
    end
end

-- Alle sichtbaren Titelknoepfe eines Fensters der Reihe nach vom Kreuz
-- nach links (Reihenfolge wie in CL.LINKS). Was nicht mehr passt, ohne den
-- Titel zu verdecken, geht an seinen Platz ausserhalb (fallback, sonst
-- unter das Fenster). 1.0.8.0 (Wunsch: "diesen Button fuer die anderen
-- Fenster nachziehen").
function CL.Arrange(frame)
    if type(frame) ~= "table" then return end
    local close = CL.CloseOf(frame)
    local used, prev, full = 0, nil, false
    for _, link in ipairs(CL.order) do
        local b = CL.buttons[link]
        if b and link.where == "title" and _G[link.titleHost or link.host] == frame
            and b.IsShown and b:IsShown() then
            local w = Plain(b:GetWidth()) or 0
            local mode
            if not full and CL.TitleFits(frame, close, w, used) then
                b:ClearAllPoints()
                if prev then
                    b:SetPoint("RIGHT", prev, "LEFT", -CL.TITLE_GAP, 0)
                else
                    CL.Place(b, frame, "title")
                end
                used, prev, mode = used + w + (prev and CL.TITLE_GAP or 0), b, "title"
            else
                full = true   -- danach nichts mehr oben: die Reihe bleibt in Ordnung
                mode = link.fallback or "below"
                CL.Place(b, _G[link.host], mode)
            end
            b._mode = mode
            local host = _G[link.host]
            local strata = Plain(host.GetFrameStrata and host:GetFrameStrata()) or "HIGH"
            -- 1.0.8.0 (Bild: Knopf in der Titelleiste blass, nicht anklickbar):
            -- die Titelleiste des Spiels liegt ueber Fensterebene + 20. Auf
            -- dem Fenster eine Schicht hoeher - darunter bleibt er unsichtbar.
            if mode == "title" then strata = CL.ABOVE[strata] or strata end
            b:SetFrameStrata(strata)
            b:SetFrameLevel((Plain(host.GetFrameLevel and host:GetFrameLevel()) or 1) + 20)
        end
    end
end

-- Gold wie das Fenster (GameColors.frameAccent, Stil S.CALM). 1.0.8.0
-- (Rueckmeldung: "muss noch etwas schoener aussehen"): rechteckig - die
-- abgeschnittenen Ecken waren in der Flaeche von Codex gefuellt, nicht in
-- der des Fensters -, Flaeche leicht golden getoent, Rand in Gold, Logo
-- davor; mit der Maus darueber heller, Schrift hell.
CL.GOLD_FILL, CL.GOLD_FILL_HOT = 0.14, 0.30
CL.GOLD_EDGE, CL.GOLD_EDGE_HOT = 0.70, 1.00
function CL.Gold(b)
    local g = WeintCodex.GameColors.frameAccent
    local base = WeintCodex.Colors.bgDark or WeintCodex.Colors.surface3
    local hi = WeintCodex.Colors.textBright
    local function paint(hot)
        local k = hot and CL.GOLD_FILL_HOT or CL.GOLD_FILL
        b._bg:SetColorTexture(base[1] + (g[1] - base[1]) * k, base[2] + (g[2] - base[2]) * k,
            base[3] + (g[3] - base[3]) * k, 0.95)
        local e = hot and CL.GOLD_EDGE_HOT or CL.GOLD_EDGE
        for _, t in ipairs(b._edges) do t:SetColorTexture(g[1], g[2], g[3], e) end
        local c = hot and hi or g
        b._label:SetTextColor(c[1], c[2], c[3], 1)
        if b._icon then b._icon:SetAlpha(hot and 1 or 0.9) end
    end
    -- Rand: vier Linien von 1 px (eigene, damit sie mit der Maus heller werden).
    b._edges = {}
    for i, pt in ipairs({ { "TOPLEFT", "TOPRIGHT" }, { "BOTTOMLEFT", "BOTTOMRIGHT" },
                          { "TOPLEFT", "BOTTOMLEFT" }, { "TOPRIGHT", "BOTTOMRIGHT" } }) do
        local t = b:CreateTexture(nil, "BORDER")
        t:SetPoint(pt[1], b, pt[1], 0, 0)
        t:SetPoint(pt[2], b, pt[2], 0, 0)
        if i <= 2 then t:SetHeight(1) else t:SetWidth(1) end
        b._edges[i] = t
    end
    b._label:ClearAllPoints()
    b._label:SetPoint("CENTER", b, "CENTER", (CL.TITLE_ICON + 4) / 2, 0)
    local icon = b:CreateTexture(nil, "OVERLAY")
    icon:SetSize(CL.TITLE_ICON, CL.TITLE_ICON)
    icon:SetTexture(K.MEDIA .. "logo_32")
    icon:SetPoint("RIGHT", b._label, "LEFT", -5, 0)
    b._icon = icon
    local tip = b._tip
    b:SetScript("OnEnter", function(self)
        paint(true)
        if tip then
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
            GameTooltip:SetText(tip, 1, 1, 1, 1, true)
            GameTooltip:Show()
        end
    end)
    b:SetScript("OnLeave", function() paint(false) GameTooltip:Hide() end)
    paint(false)
    b._gold = true
    b._paintGold = paint
    return b
end

function CL.Refresh(link)
    local b = CL.buttons[link]
    local host = _G[link.host]
    if not (b and type(host) == "table") then return end
    local show = CL.On() and host.IsShown and K.Bool(host:IsShown(), false)
        and (not link.when or link.when()) and true or false
    if show then b:SetText(link.label()) end   -- passt die Breite an
    b:SetShown(show)
    if link.where == "title" then
        CL.Arrange(_G[link.titleHost or link.host])
    elseif show then
        b:SetFrameStrata(Plain(host.GetFrameStrata and host:GetFrameStrata()) or "HIGH")
        b:SetFrameLevel((Plain(host.GetFrameLevel and host:GetFrameLevel()) or 1) + 20)
    end
end

function CL.Attach(link)
    if CL.buttons[link] then return CL.buttons[link] end
    local host = _G[link.host]
    if type(host) ~= "table" or not host.HookScript then return nil end
    if host.IsForbidden and host:IsForbidden() then return nil end
    -- Alle Knoepfe in Gold mit Logo - auch die ausserhalb der Titelleiste
    -- (Taschen, Beute): ein Aussehen fuer "Codex: ...".
    local b = WeintCodex.CreateButton(UIParent, { text = link.label(), kind = "secondary",
        height = CL.TITLE_H, size = 11, padding = 30 + CL.TITLE_ICON, radius = 0,
        backdrop = "surface2", tooltip = link.tip, onClick = function() link.go() end })
    b._tip = link.tip
    CL.Gold(b)
    b:SetText(link.label())
    CL.Place(b, host, link.where)
    b:Hide()
    CL.buttons[link] = b
    CL.order[#CL.order + 1] = link
    table.sort(CL.order, function(a, c) return Rank(a) < Rank(c) end)
    host:HookScript("OnShow", function() CL.Refresh(link) end)
    host:HookScript("OnHide", function()
        b:Hide()
        -- Ein Reiter im Fenster (Ruf im Charakterfenster) geht: die anderen
        -- Titelknoepfe ruecken nach.
        if link.where == "title" and link.titleHost then CL.Arrange(_G[link.titleHost]) end
    end)
    CL.Refresh(link)
    return b
end

function CL.AttachAll()
    local n = 0
    for _, link in ipairs(CL.LINKS) do
        if CL.Attach(link) then n = n + 1 end
    end
    return n
end

function CL.RefreshAll()
    for _, link in ipairs(CL.LINKS) do CL.Refresh(link) end
end

do
    local ev = CreateFrame("Frame")
    for _, e in ipairs({ "PLAYER_LOGIN", "ADDON_LOADED", "PLAYER_ENTERING_WORLD", "TRAINER_SHOW", "LOOT_OPENED", "INSPECT_READY", "GROUP_ROSTER_UPDATE" }) do
        pcall(ev.RegisterEvent, ev, e)
    end
    ev:SetScript("OnEvent", WeintCodex.Measured("Verweise zu Codex", function(_, event)
        CL.AttachAll()
        if event ~= "ADDON_LOADED" then CL.RefreshAll() end
    end))
    CL.events = ev
end

K.Listen(function(kind, module, key)
    if (kind == "setting" and module == KEY and key == "codexLinks") or (kind == "active" and module == KEY) then
        CL.RefreshAll()
    end
end)
