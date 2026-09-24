--------------------------------------------------
-- Ein World of Warcraft, so weit es zum LADEN reicht.
--
-- Fuer diese Fassung des Addons gibt es kein Spiel, an dem sich etwas
-- ausprobieren liesse: World of Warcraft: Forever erscheint erst, und
-- niemand kann vorher nachsehen, ob eine Datei ueberhaupt durchlaeuft.
-- Genau diese Luecke schliesst diese Attrappe.
--
-- Sie ist bewusst DUMM. Sie bildet kein Verhalten nach und beantwortet
-- keine Spielfrage - sie sorgt nur dafuer, dass jeder Aufruf an den
-- Client zurueckkehrt, statt das Laden abzubrechen. Was sie damit
-- findet, ist genau eine Fehlerklasse, und zwar die, die im Spiel am
-- teuersten ist:
--
--   * eine Datei, die in WeintCodex.toc fehlt oder zu frueh steht
--     ("attempt to index a nil value (field 'Colors')"),
--   * ein Zugriff auf ein Modul, das es nicht mehr gibt,
--   * ein Tippfehler in einem Namen, den erst die Laufzeit aufloest.
--
-- Alle drei aeussern sich im Spiel gleich: das Addon laedt, und eine
-- Seite bleibt leer oder wirft mitten im Raid einen Lua-Fehler.
--
-- WAS SIE NICHT LEISTET, damit niemand mehr darin sieht als drin ist:
-- sie sagt nichts darueber, ob eine Seite richtig aussieht, ob eine
-- Rechnung stimmt oder ob der echte Client dieselben Antworten gibt.
-- Ein gruener Lauf heisst "es laedt", nicht "es funktioniert".
--------------------------------------------------

local M = {}

--------------------------------------------------
-- Der universelle Frame
--------------------------------------------------
-- Jede Methode, die nicht ausdruecklich unten steht, ist eine Funktion,
-- die nichts tut und nichts liefert. Das ist der ganze Trick: eine
-- Attrappe, die jede Methode kennt, muss nicht gepflegt werden, wenn
-- das Addon eine neue benutzt.
--
-- Ausdruecklich aufgefuehrt sind nur die Methoden, deren RUECKGABEWERT
-- das Addon weiterverwendet. Gaeben sie nil zurueck, braeche der
-- Aufrufer an einer Stelle, die mit dem echten Fehler nichts zu tun hat
-- - und der Lauf meldete etwas anderes, als er gefunden hat.

local FrameMeta = {}

local function NewObject(objectType, name)

    local obj = {
        _type     = objectType or "Frame",
        _name     = name,
        _width    = 800,
        _height   = 600,
        _points   = {},
        _shown    = true,
        _scripts  = {},
    }

    return setmetatable(obj, FrameMeta)

end

M.NewObject = NewObject

local function Noop() end

-- Methoden mit Rueckgabewert. Alles andere faellt auf Noop.
local Methods = {}

function Methods:GetObjectType()  return self._type end
function Methods:GetName()        return self._name end
function Methods:GetWidth()       return self._width end
function Methods:GetHeight()      return self._height end
function Methods:GetScale()       return 1.0 end
function Methods:GetFrameLevel()  return 1 end
function Methods:GetFrameStrata() return "MEDIUM" end
function Methods:IsShown()        return self._shown and true or false end
function Methods:IsVisible()      return self._shown and true or false end
function Methods:HasFocus()       return false end
function Methods:GetText()        return self._text or "" end
function Methods:GetNumLines()    return 0 end
function Methods:NumLines()       return 0 end

function Methods:SetWidth(v)  self._width  = tonumber(v) or self._width  end
function Methods:SetHeight(v) self._height = tonumber(v) or self._height end
function Methods:SetSize(w, h)
    self._width  = tonumber(w) or self._width
    self._height = tonumber(h) or self._height
end

function Methods:Show() self._shown = true  end
function Methods:Hide() self._shown = false end
function Methods:SetShown(v) self._shown = v and true or false end

-- OHNE SCHRIFT KEIN TEXT. Der Client bricht SetText auf einem
-- FontString ohne Schrift ab ("Font not set"). Bis 6.0.0.3 liess die
-- Attrappe das durchgehen - und die Schadensanzeige brach im Spiel beim
-- Aufbau ab, weil ein Knopf seinen Text vor seiner Schrift bekam. Eine
-- Schrift hat ein FontString, wenn er mit Vorlage angelegt wurde oder
-- SetFont/SetFontObject bekam.
local function RequireFont(self, method)
    if self._type == "FontString" and not self._font then
        error("FontString:" .. method .. "(): Font not set", 3)
    end
end

function Methods:SetText(text)
    RequireFont(self, "SetText")
    self._text = text
end
function Methods:SetFormattedText(fmt, ...)
    RequireFont(self, "SetFormattedText")
    self._text = string.format(fmt, ...)
end
function Methods:SetFont(path, size, flags)
    self._font = path ~= nil
    return self._font
end
function Methods:SetFontObject(obj) self._font = obj ~= nil end
function Methods:GetFont()
    if self._font then return "Fonts\\FRIZQT__.TTF", 12, "" end
end

-- Attribute werden gemerkt (Kopfrahmen, geschuetzte Knoepfe).
function Methods:SetAttribute(key, value)
    self._attrs = self._attrs or {}
    self._attrs[key] = value
end
function Methods:GetAttribute(key)
    return self._attrs and self._attrs[key]
end

-- Die Textbreite waechst mit dem Text. Bis 5.2.0.0 antwortete die
-- Attrappe mit festen 100 px - eine Bosszeile aus Pillen, deren
-- Breite aus dem Text kommt, war damit weder zu kurz noch zu lang,
-- sondern beliebig. Sechs Pixel je ZEICHEN (nicht je Byte: ein
-- Umlaut ist zwei Bytes und ein Zeichen) sind keine Messung, aber
-- eine, die in dieselbe Richtung zeigt wie der Client.
function Methods:GetStringWidth()
    local s = tostring(self._text or "")
    local n = 0
    for _ in s:gmatch("[^\128-\191]") do n = n + 1 end
    return n * 6
end
function Methods:GetStringHeight() return 12  end

function Methods:GetVerticalScroll()      return 0 end
function Methods:GetVerticalScrollRange() return 0 end

-- Texturen und Schriftzeilen koennen im Client nichts anlegen; die
-- Methode gibt es dort nicht. Bis 6.0.0.4 konnten sie es hier - und der
-- Chat haengte seinen Rand an eine Textur, was im Spiel abbrach.
local function RequireFrame(self, method)
    if self._type == "Texture" or self._type == "FontString" then
        error("attempt to call method '" .. method .. "' (a nil value) on a " .. self._type, 3)
    end
end

function Methods:CreateTexture(_, layer)
    RequireFrame(self, "CreateTexture")
    local tex = NewObject("Texture")
    tex._parent = self
    return tex
end

function Methods:CreateFontString(_, layer, inherits)
    RequireFrame(self, "CreateFontString")
    local fs = NewObject("FontString")
    fs._parent = self
    fs._font = inherits ~= nil
    return fs
end

function Methods:GetThumbTexture()
    return NewObject("Texture")
end

-- Animationen. Gebraucht von LibDBIcon (Ein- und Ausblenden des
-- Minikarten-Knopfes): es legt das Ergebnis in ein Feld und indiziert
-- es danach, eine Noop-Funktion reicht dafuer nicht.
function Methods:CreateAnimationGroup()
    return NewObject("AnimationGroup")
end

function Methods:CreateAnimation()
    return NewObject("Animation")
end

-- Absichtlich LEER: Aufrufer laufen ueber `pairs({ f:GetChildren() })`
-- und muessen mit "kein Kind" zurechtkommen.
function Methods:GetChildren() end
function Methods:GetRegions()  end

function Methods:SetScript(event, handler)
    self._scripts[event] = handler
end

-- Ereignisse werden nur GEMERKT, nicht zugestellt. Zugestellt wird
-- ausschliesslich, was der Testlauf ausdruecklich ausloest (siehe
-- M.FireEvent) - ein Spiel, das im Hintergrund feuert, waere eine
-- Umgebung, die der Lauf nicht mehr beherrscht.
local registry = {}
M._registry = registry

function Methods:RegisterEvent(event)
    self._events = self._events or {}
    self._events[event] = true

    -- Nur EINMAL eintragen, auch wenn ein Frame mehrere Ereignisse
    -- anmeldet. Sonst liefe sein Behandler je Ereignis mehrfach, und
    -- core/main.lua legte die SavedVariables zweimal an.
    if not self._registered then
        self._registered = true
        registry[#registry + 1] = self
    end
end

function Methods:HookScript(event, handler)
    self._scripts[event] = handler
end

function Methods:GetScript(event)
    return self._scripts[event]
end

-- CLICK MUSS WIRKLICH KLICKEN, und bis 5.2.0.0 tat es das nicht.
--
-- Die Attrappe faellt fuer jede unbekannte Methode auf Noop zurueck
-- (siehe FrameMeta.__index weiter unten). `btn:Click()` lief damit
-- ins Leere - lautlos. Folge: Navigation.ActivateIndex() aktivierte
-- im Prueflauf NIE einen Eintrag, und damit lief keine einzige
-- Seitenzeichnung. Der Lauf war gruen, weil er die Haelfte des
-- Addons nie angefasst hat.
--
-- Das ist genau die Sorte Fehler, gegen die dieser Prueflauf gebaut
-- wurde: etwas, das nichts ausloest.
function Methods:Click(button, down)
    local handler = self._scripts and self._scripts["OnClick"]
    if handler then handler(self, button or "LeftButton", down or false) end
end

-- Dasselbe fuer die Maus: einige Seiten haengen ihre Auskunft an
-- OnEnter/OnLeave, und ohne Ausloeser bliebe auch die ungeprueft.
function Methods:Enter()
    local handler = self._scripts and self._scripts["OnEnter"]
    if handler then handler(self) end
end

function Methods:Leave()
    local handler = self._scripts and self._scripts["OnLeave"]
    if handler then handler(self) end
end

function Methods:SetPoint(...) end
function Methods:ClearAllPoints() end

-- GetParent muss ein ECHTES Objekt liefern: LibDBIcon liest
-- `self:GetParent().dataObject`, und eine Noop-Funktion laesst sich
-- nicht indizieren.
function Methods:GetParent() return self._parent or _G.UIParent end
function Methods:SetParent(parent) self._parent = parent end

FrameMeta.__index = function(tbl, key)

    -- Eigene Felder der Attrappe (und die, die das Addon selbst auf
    -- einen Frame legt) beginnen mit einem Unterstrich. Sie duerfen
    -- NICHT auf Noop fallen: `if self._corners then` waere sonst
    -- immer wahr, und `self._events[event]` indizierte eine Funktion.
    if type(key) == "string" and key:sub(1, 1) == "_" then
        return nil
    end

    local explicit = Methods[key]
    if explicit then return explicit end

    return Noop
end

--------------------------------------------------
-- Die Umgebung aufsetzen
--------------------------------------------------

function M.Install()

    local G = _G

    G.UIParent        = NewObject("Frame", "UIParent")
    G.UISpecialFrames = {}

    G.GameTooltip = NewObject("Frame", "GameTooltip")

    -- LibDBIcon haengt seinen Knopf an die Minikarte und fragt sie nach
    -- ihrer Groesse. Ohne sie bricht die Bibliothek beim Laden ab.
    G.Minimap = NewObject("Frame", "Minimap")
    G.MinimapCluster = NewObject("Frame", "MinimapCluster")
    G.MinimapBackdrop = NewObject("Frame", "MinimapBackdrop")

    G.CreateFrame = function(kind, name, parent, template)
        local frame = NewObject(kind or "Frame", name)
        frame._parent = parent

        -- UIPanelScrollFrameTemplate bringt eine Bildlaufleiste mit. Im
        -- modernen Client haengt sie als Feld am Rahmen, in Classic als
        -- globaler "<Name>ScrollBar"; core/ui.lua sucht beides ab. Die
        -- Attrappe legt sie deshalb genauso an - eine Leiste, die es
        -- hier nicht gaebe, liesse den Aufrufer an einer Stelle brechen,
        -- die mit dem echten Fehler nichts zu tun hat.
        if type(template) == "string" and template:find("ScrollFrame", 1, true) then
            frame.ScrollBar = NewObject("Slider", name and (name .. "ScrollBar"))
        end

        -- Ein Gruppen-Kopfrahmen ordnet seine Knoepfe beim Zeigen an und
        -- liest dafuer das Attribut "point" - ohne Rueckfall: fehlt es,
        -- bricht der Client in SecureGroupHeaders.lua ab (gemeldet aus
        -- dem Beta-Client zu 6.0.0.3).
        if type(template) == "string" and template:find("SecureGroupHeaderTemplate", 1, true) then
            frame.Show = function(self)
                if type(self:GetAttribute("point")) ~= "string" then
                    error("SecureGroupHeaders.lua:79: attempt to index local 'point' (a nil value)", 2)
                end
                self._shown = true
            end
        end

        if name then
            G[name] = frame
            if frame.ScrollBar then
                G[name .. "ScrollBar"] = frame.ScrollBar
            end
        end

        return frame
    end

    G.CreateColor = function(r, g, b, a)
        return { r = r, g = g, b = b, a = a }
    end

    -- Zeichenketten- und Tabellenhelfer des Clients
    G.wipe = function(t)
        for key in pairs(t) do t[key] = nil end
        return t
    end
    -- WoW legt os.date und os.time als globale `date`/`time` aus.
    G.date = os.date
    G.time = os.time
    G.debugprofilestop = function() return 0 end

    G.strmatch = string.match
    G.strfind  = string.find
    G.strsub   = string.sub
    G.strrep   = string.rep
    G.strjoin  = function(sep, ...) return table.concat({ ... }, sep) end
    G.format   = string.format
    G.gsub     = string.gsub
    G.tinsert  = table.insert
    G.tremove  = table.remove
    G.sort     = table.sort
    G.max      = math.max
    G.min      = math.min
    G.floor    = math.floor
    G.ceil     = math.ceil
    G.abs      = math.abs
    G.strlower = string.lower
    G.strupper = string.upper
    G.strtrim  = function(s) return (tostring(s or ""):gsub("^%s*(.-)%s*$", "%1")) end
    G.strsplit = function(sep, str)
        local out = {}
        for part in tostring(str or ""):gmatch("([^" .. sep .. "]*)") do
            out[#out + 1] = part
        end
        return unpack(out)
    end
    G.tContains = function(list, value)
        for _, entry in ipairs(list or {}) do
            if entry == value then return true end
        end
        return false
    end

    -- C_Timer.After feuert NIE. Das ist Absicht: dieser Lauf prueft das
    -- Laden, nicht das Verhalten - ein sofort ausgefuehrter Rueckruf
    -- liefe in einer Umgebung, die es so nie gibt.
    G.C_Timer = { After = function() end, NewTicker = function() return {} end }

    G.C_Item = {}

    -- Spielerauskuenfte. Bewusst plausible Werte statt nil: eine
    -- Attrappe, die ueberall nil sagt, findet Ladefehler - erzeugt aber
    -- auch welche, die es im Spiel nicht gibt.
    G.UnitName  = function() return "Testchar" end
    G.UnitClass = function() return "Krieger", "WARRIOR" end
    G.UnitLevel = function() return 60 end
    G.UnitIsVisible = function() return false end
    G.UnitGUID  = function() return "Player-0000-00000000" end
    G.GetRealmName = function() return "Testrealm" end
    G.GetSpecialization = function() return nil end
    G.GetSpecializationInfo = function() return nil end
    G.GetPrimaryTalentTree = function() return nil end
    G.GetAverageItemLevel = function() return 0, 0 end
    G.GetInventorySlotInfo = function(name)
        local ids = {
            HeadSlot = 1, NeckSlot = 2, ShoulderSlot = 3, ShirtSlot = 4,
            ChestSlot = 5, WaistSlot = 6, LegsSlot = 7, FeetSlot = 8,
            WristSlot = 9, HandsSlot = 10, Finger0Slot = 11, Finger1Slot = 12,
            Trinket0Slot = 13, Trinket1Slot = 14, BackSlot = 15,
            MainHandSlot = 16, SecondaryHandSlot = 17, RangedSlot = 18,
            TabardSlot = 19,
        }
        return ids[name]
    end
    G.GetInventoryItemLink = function() return nil end
    G.GetInventoryItemDurability = function() return nil end
    G.GetItemInfo = function() return nil end
    G.GetDetailedItemLevelInfo = function() return nil end

    G.IsInRaid    = function() return false end
    G.IsInGroup   = function() return false end
    G.IsInInstance = function() return false, "none" end
    G.GetNumGroupMembers = function() return 0 end
    G.GetNumSavedInstances = function() return 0 end
    G.GetSavedInstanceInfo = function() return nil end
    G.GetSavedInstanceEncounterInfo = function() return nil end
    G.RequestRaidInfo = function() end
    G.CanInspect = function() return false end
    G.NotifyInspect = function() end
    G.GetTime = function() return 0 end
    G.IsControlKeyDown = function() return false end
    G.IsShiftKeyDown = function() return false end
    G.GetLootMethod = function() return "freeforall" end
    G.GetGuildInfo = function() return nil end
    G.GetNumGuildMembers = function() return 0 end
    G.GetCurrentGuildBankTab = function() return 1 end
    G.GetGuildBankTabInfo = function() return nil end
    G.PlaySound = function() end
    G.PlaySoundFile = function() end

    G.RAID_CLASS_COLORS = {
        WARRIOR = { r = 0.78, g = 0.61, b = 0.43 },
        PALADIN = { r = 0.96, g = 0.55, b = 0.73 },
        HUNTER  = { r = 0.67, g = 0.83, b = 0.45 },
        ROGUE   = { r = 1.00, g = 0.96, b = 0.41 },
        PRIEST  = { r = 1.00, g = 1.00, b = 1.00 },
        SHAMAN  = { r = 0.00, g = 0.44, b = 0.87 },
        MAGE    = { r = 0.41, g = 0.80, b = 0.94 },
        WARLOCK = { r = 0.58, g = 0.51, b = 0.79 },
        DRUID   = { r = 1.00, g = 0.49, b = 0.04 },
    }
    G.CLASS_ICON_TCOORDS = {}
    G.LOCALIZED_CLASS_NAMES_MALE = {}

    G.SlashCmdList = {}
    G.StaticPopupDialogs = {}
    G.StaticPopup_Show = function() end
    G.StaticPopup_Hide = function() end

    -- Die GlobalStrings, die modules/loot.lua in Muster uebersetzt.
    G.LOOT_ITEM             = "%s erhält Beute: %s."
    G.LOOT_ITEM_MULTIPLE    = "%s erhält Beute: %sx%d."
    G.LOOT_ITEM_SELF        = "Ihr erhaltet Beute: %s."
    G.LOOT_ITEM_SELF_MULTIPLE = "Ihr erhaltet Beute: %sx%d."
    G.LOOT_ITEM_PUSHED      = "%s erhält Gegenstand: %s."
    G.LOOT_ITEM_PUSHED_SELF = "Ihr erhaltet Gegenstand: %s."
    G.LOOT_ITEM_PUSHED_MULTIPLE = "%s erhält Gegenstand: %sx%d."
    G.LOOT_ITEM_PUSHED_SELF_MULTIPLE = "Ihr erhaltet Gegenstand: %sx%d."

    G.EMPTY_SOCKET_RED    = "Roter Sockel"
    G.EMPTY_SOCKET_YELLOW = "Gelber Sockel"
    G.EMPTY_SOCKET_BLUE   = "Blauer Sockel"
    G.EMPTY_SOCKET_META   = "Meta-Sockel"

    G.CALENDAR_OPEN_EVENT = nil

end

--------------------------------------------------
-- Ein Ereignis zustellen
--------------------------------------------------
-- Nur ADDON_LOADED und PLAYER_LOGIN werden im Lauf gebraucht: sie sind
-- der Weg, auf dem core/main.lua die SavedVariables anlegt. Ohne sie
-- stuende WeintCodex.SavedData nach dem Laden auf nil, und jede
-- Pruefung darauf meldete ein Modul, das nur noch nicht dran war.

function M.FireEvent(event, ...)

    local delivered = 0

    -- Ueber eine Kopie laufen: ein Behandler darf weitere Frames
    -- anlegen, ohne die Schleife zu veraendern.
    local frames = {}
    for index, frame in ipairs(M._registry) do frames[index] = frame end

    for _, frame in ipairs(frames) do
        if frame._events and frame._events[event] then
            local handler = frame._scripts and frame._scripts["OnEvent"]
            if handler then
                local ok, err = pcall(handler, frame, event, ...)
                if not ok then
                    error("FEHLER im Behandler fuer " .. event .. ":\n  "
                        .. tostring(err), 0)
                end
                delivered = delivered + 1
            end
        end
    end

    return delivered

end

--------------------------------------------------
-- Dateien in der Reihenfolge der .toc laden
--------------------------------------------------

function M.LoadToc(root)

    local path  = (root or ".") .. "/WeintCodex.toc"
    local file  = assert(io.open(path, "r"),
        "WeintCodex.toc nicht gefunden unter " .. path)

    local loaded = {}

    for line in file:lines() do

        local trimmed = line:gsub("^%s*(.-)%s*$", "%1")

        -- Kommentar, Metadatenzeile und Leerzeile ueberspringen.
        if trimmed ~= ""
            and trimmed:sub(1, 1) ~= "#"
            and not trimmed:match("^##") then

            if trimmed:match("%.lua$") then

                local chunk, err = loadfile((root or ".") .. "/" .. trimmed)
                if not chunk then
                    error("LADEFEHLER in " .. trimmed .. ":\n  " .. tostring(err), 0)
                end

                local ok, runErr = pcall(chunk)
                if not ok then
                    error("LAUFZEITFEHLER beim Laden von " .. trimmed
                        .. ":\n  " .. tostring(runErr), 0)
                end

                loaded[#loaded + 1] = trimmed

            elseif trimmed:match("%.xml$") then

                -- Die XML-Dateien der Bibliotheken binden nur Lua-Dateien
                -- ein (<Script file="..."/>). Sie zu ueberspringen waere
                -- bequem und falsch: LibDataBroker bricht ab, wenn
                -- CallbackHandler nicht geladen ist, und genau diese
                -- Reihenfolge soll der Lauf ja pruefen. Deshalb wird die
                -- eine Zeile, die darin steht, herausgelesen - ein
                -- XML-Parser ist dafuer nicht noetig und waere hier eine
                -- eigene Fehlerquelle.
                local folder = trimmed:match("^(.*)/[^/]+$") or ""
                local xml = assert(io.open((root or ".") .. "/" .. trimmed, "r"),
                    "XML nicht gefunden: " .. trimmed)
                local body = xml:read("*a")
                xml:close()

                local scripts = 0
                for scriptFile in body:gmatch('<Script%s+file="([^"]+)"') do
                    scripts = scripts + 1
                    local target = (folder ~= "" and (folder .. "/") or "") .. scriptFile

                    local chunk, err = loadfile((root or ".") .. "/" .. target)
                    if not chunk then
                        error("LADEFEHLER in " .. target .. " (aus " .. trimmed
                            .. "):\n  " .. tostring(err), 0)
                    end

                    local ok, runErr = pcall(chunk)
                    if not ok then
                        error("LAUFZEITFEHLER beim Laden von " .. target
                            .. " (aus " .. trimmed .. "):\n  "
                            .. tostring(runErr), 0)
                    end

                    loaded[#loaded + 1] = target
                end

                if scripts == 0 then
                    error("Die XML-Datei " .. trimmed
                        .. " bindet keine Lua-Datei ein - dann steht sie zu"
                        .. " Unrecht in der .toc.", 0)
                end

            end

        end

    end

    file:close()

    return loaded

end

return M
