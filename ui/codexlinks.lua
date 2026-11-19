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
function CL.Profession()
    local PT = WeintCodex.ProfTools
    if PT and PT.OpenProfession then
        local ok, key = pcall(PT.OpenProfession)
        if ok and type(key) == "string" then return key end
    end
    return nil
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
-- where: "below" (unter dem Fenster, rechts) oder "above".
CL.LINKS = {
    { host = "ProfessionsFrame", label = function() return "Codex: Berufe" end,
      tip = "Rezepte nach deiner Fertigkeit, Lehrer und Herkunft der Rezepte – für den offenen Beruf.",
      go = function()
          local key = CL.Profession()
          return CL.Open("berufe", function()
              local PRO = WeintCodex.Professions
              if key and PRO and PRO.Select then PRO.Select(key) end
          end)
      end },
    { host = "TradeSkillFrame", label = function() return "Codex: Berufe" end,
      tip = "Rezepte nach deiner Fertigkeit, Lehrer und Herkunft der Rezepte – für den offenen Beruf.",
      go = function()
          local key = CL.Profession()
          return CL.Open("berufe", function()
              local PRO = WeintCodex.Professions
              if key and PRO and PRO.Select then PRO.Select(key) end
          end)
      end },
    { host = "ClassTrainerFrame",
      label = function() return IsTradeTrainer() and "Codex: Berufe" or "Codex: Lehrer" end,
      tip = "Was du hier lernen kannst, was es kostet und was als Nächstes kommt.",
      go = function()
          if IsTradeTrainer() then return CL.Open("berufe") end
          return CL.Open("lehrer")
      end },
    { host = "CharacterFrame", label = function() return "Codex: Charakter" end,
      tip = "Ausrüstung, Twinks und Fortschritt deiner Charaktere.",
      go = function() return CL.Open("charakter") end },
    { host = "SpellBookFrame", label = function() return "Codex: Lehrer" end,
      tip = "Welche Zauber du bei deinem Lehrer lernen kannst und was sie kosten.",
      go = function() return CL.Open("lehrer") end },
    { host = "PlayerSpellsFrame", label = function() return "Codex: Lehrer" end,
      tip = "Welche Zauber du bei deinem Lehrer lernen kannst und was sie kosten.",
      go = function() return CL.Open("lehrer") end },
    { host = "BankFrame", label = function() return "Codex: Taschen" end,
      tip = "Was alle deine Charaktere tragen – Taschen, Bank, Ausrüstung.",
      go = function() return CL.Open("taschen") end },
    { host = "ContainerFrameCombinedBags", where = "above", label = function() return "Codex: Taschen" end,
      tip = "Was alle deine Charaktere tragen – Taschen, Bank, Ausrüstung.",
      go = function() return CL.Open("taschen") end },
    { host = "LFGParentFrame", label = function() return "Codex: Dungeons" end,
      tip = "Alle Dungeons mit Stufen, Bossen, Beute und Quests.",
      go = function() return CL.Open("dungeons") end },
    { host = "PVEFrame", label = function() return "Codex: Dungeons" end,
      tip = "Alle Dungeons mit Stufen, Bossen, Beute und Quests.",
      go = function() return CL.Open("dungeons") end },
    { host = "EncounterJournal", label = function() return "Codex: Dungeons" end,
      tip = "Alle Dungeons mit Stufen, Bossen, Beute und Quests.",
      go = function()
          local id = CL.CurrentDungeon()
          return CL.Open("dungeons", function()
              local DP = WeintCodex.DungeonPages
              if id and DP and DP.Select then DP.Select(id) end
          end)
      end },
    -- Nur in einem Dungeon, den Codex kennt: Weltkarte -> dieser Dungeon.
    { host = "WorldMapFrame", when = function() return CL.CurrentDungeon() ~= nil end,
      label = function() return "Codex: dieser Dungeon" end,
      tip = "Bosse, Beute und Quests des Dungeons, in dem du gerade bist.",
      go = function()
          local id = CL.CurrentDungeon()
          return CL.Open("dungeons", function()
              local DP = WeintCodex.DungeonPages
              if id and DP and DP.Select then DP.Select(id) end
          end)
      end },
    { host = "LootFrame", when = function() return CL.CurrentDungeon() ~= nil end,
      label = function() return "Codex: Beute" end,
      tip = "Was in diesem Dungeon fällt, mit deiner Wunschliste.",
      go = function() return CL.Open("beute") end },
}

--------------------------------------------------
-- Knoepfe
--------------------------------------------------
CL.buttons = {}   -- [host] = Knopf

function CL.On() return K.IsActive(KEY) and K.Get(KEY, "codexLinks") ~= false end

local function Place(b, host, where)
    b:ClearAllPoints()
    if where == "above" then
        b:SetPoint("BOTTOMRIGHT", host, "TOPRIGHT", 0, 4)
    else
        b:SetPoint("TOPRIGHT", host, "BOTTOMRIGHT", 0, -4)
    end
end

function CL.Refresh(link)
    local b = CL.buttons[link.host]
    local host = _G[link.host]
    if not (b and type(host) == "table") then return end
    local show = CL.On() and host.IsShown and K.Bool(host:IsShown(), false)
        and (not link.when or link.when()) and true or false
    if show then
        b:SetText(link.label())   -- passt die Breite an
        b:SetFrameStrata(host.GetFrameStrata and host:GetFrameStrata() or "HIGH")
        b:SetFrameLevel((Plain(host.GetFrameLevel and host:GetFrameLevel()) or 1) + 20)
    end
    b:SetShown(show)
end

function CL.Attach(link)
    if CL.buttons[link.host] then return CL.buttons[link.host] end
    local host = _G[link.host]
    if type(host) ~= "table" or not host.HookScript then return nil end
    if host.IsForbidden and host:IsForbidden() then return nil end
    local b = WeintCodex.CreateButton(UIParent, { text = link.label(), kind = "secondary", height = CL.H, size = 11,
        backdrop = "surface2", tooltip = link.tip, onClick = function() link.go() end })
    b:SetText(link.label())
    Place(b, host, link.where)
    b:Hide()
    CL.buttons[link.host] = b
    host:HookScript("OnShow", function() CL.Refresh(link) end)
    host:HookScript("OnHide", function() b:Hide() end)
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
    for _, e in ipairs({ "PLAYER_LOGIN", "ADDON_LOADED", "PLAYER_ENTERING_WORLD", "TRAINER_SHOW" }) do
        pcall(ev.RegisterEvent, ev, e)
    end
    ev:SetScript("OnEvent", WeintCodex.Measured("Verweise zu Codex", function(_, event)
        CL.AttachAll()
        if event == "TRAINER_SHOW" or event == "PLAYER_ENTERING_WORLD" then CL.RefreshAll() end
    end))
    CL.events = ev
end

K.Listen(function(kind, module, key)
    if (kind == "setting" and module == KEY and key == "codexLinks") or (kind == "active" and module == KEY) then
        CL.RefreshAll()
    end
end)
