--------------------------------------------------
-- WeintCodex :: Oberflaeche - Profil exportieren und importieren
--------------------------------------------------
-- Seit 6.28.0.0 (Beta-Test: "mein komplettes Layout inkl. aller
-- Einstellungen exportieren und importieren - Backup und Teilen"). Eine
-- Zeile Text zum Kopieren: das gewaehlte Profil (alle Einstellungen der
-- Oberflaeche und des Komforts samt Plaetzen der Rahmen) und, wenn der
-- Client es kann, das eigene Layout "WeintCodex" des Bearbeitungsmodus
-- (C_EditMode.ConvertLayoutInfoToString - das Format des Spiels).
--
-- SICHERHEIT: ein geteilter Text kommt von Fremden. Er wird NIE als Code
-- ausgefuehrt (kein loadstring) - ein eigener Leser kennt nur Zahlen,
-- Text, Wahrheitswerte und Tabellen, mit Grenzen fuer Tiefe und Laenge.
-- Ein Import ersetzt nur das GEWAEHLTE Profil und nur das Layout
-- "WeintCodex" - nie ein Layout des Spielers -, nach Rueckfrage, und wirkt
-- nach dem Neuladen.
--
-- Nicht im Text (ganzes Konto, wie bei den Profilen): Hauptschalter,
-- Willkommen, was WeintCodex am Spiel geaendert hat.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIShare = {}

local SH = WeintCodex.UIShare
local K  = WeintCodex.UIKit
local C  = WeintCodex.Colors
local error = _G.error

SH.PREFIX = "WCUI1:"
SH.MAX_DEPTH = 32
SH.MAX_LEN = 2000000

--------------------------------------------------
-- Schreiben und Lesen (kein Code, nur Daten)
--------------------------------------------------

local function Ser(v, out, depth)
    local t = type(v)
    if t == "number" then
        if v ~= v or v == math.huge or v == -math.huge then return end
        out[#out + 1] = "n" .. string.format("%.17g", v) .. ";"
    elseif t == "string" then
        out[#out + 1] = "s" .. #v .. ":" .. v
    elseif t == "boolean" then
        out[#out + 1] = v and "b1" or "b0"
    elseif t == "table" then
        if depth > SH.MAX_DEPTH then return end
        out[#out + 1] = "t"
        for k, x in pairs(v) do
            local tk, tx = type(k), type(x)
            if (tk == "string" or tk == "number") and (tx == "string" or tx == "number" or tx == "boolean" or tx == "table") then
                Ser(k, out, depth + 1)
                Ser(x, out, depth + 1)
            end
        end
        out[#out + 1] = "e"
    end
end

function SH.Serialize(v)
    local out = {}
    Ser(v, out, 0)
    return table.concat(out)
end

-- Gibt den Wert zurueck oder nil, Grund.
function SH.Deserialize(s)
    if type(s) ~= "string" then return nil, "kein Text" end
    local pos, n = 1, #s
    local function Read(depth)
        if depth > SH.MAX_DEPTH then error("zu tief") end
        local tag = s:sub(pos, pos)
        pos = pos + 1
        if tag == "n" then
            local e = s:find(";", pos, true)
            if not e then error("Zahl ohne Ende") end
            local v = tonumber(s:sub(pos, e - 1))
            if not v then error("keine Zahl") end
            pos = e + 1
            return v
        elseif tag == "s" then
            local e = s:find(":", pos, true)
            local len = e and tonumber(s:sub(pos, e - 1))
            if not len or len < 0 or e + len > n then error("Text kaputt") end
            local v = s:sub(e + 1, e + len)
            pos = e + len + 1
            return v
        elseif tag == "b" then
            local v = s:sub(pos, pos) == "1"
            pos = pos + 1
            return v
        elseif tag == "t" then
            local t = {}
            while true do
                if pos > n then error("Tabelle ohne Ende") end
                if s:sub(pos, pos) == "e" then pos = pos + 1 return t end
                local k = Read(depth + 1)
                if type(k) ~= "string" and type(k) ~= "number" then error("Schluessel kaputt") end
                t[k] = Read(depth + 1)
            end
        end
        error("unbekanntes Zeichen")
    end
    local ok, v = pcall(Read, 0)
    if not ok then return nil, tostring(v):gsub("^.-:%d+: ", "") end
    if pos <= n then return nil, "Rest nach dem Ende" end
    return v
end

-- Base64 (Lua 5.1, ohne Bit-Bibliothek): nur Zeichen, die der Chat und
-- Discord unveraendert lassen - kein "|", keine Zeilenumbrueche.
local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local DEC = {}
for i = 1, 64 do DEC[B64:sub(i, i)] = i - 1 end

function SH.Encode(s)
    local out = {}
    for i = 1, #s, 3 do
        local a, b, c = s:byte(i, i + 2)
        local n = a * 65536 + (b or 0) * 256 + (c or 0)
        local c1 = math.floor(n / 262144) % 64
        local c2 = math.floor(n / 4096) % 64
        local c3 = math.floor(n / 64) % 64
        local c4 = n % 64
        out[#out + 1] = B64:sub(c1 + 1, c1 + 1) .. B64:sub(c2 + 1, c2 + 1)
            .. (b and B64:sub(c3 + 1, c3 + 1) or "=") .. (c and B64:sub(c4 + 1, c4 + 1) or "=")
    end
    return table.concat(out)
end

function SH.Decode(s)
    s = s:gsub("[^%w%+/=]", "")
    if #s % 4 ~= 0 then return nil end
    local out = {}
    for i = 1, #s, 4 do
        local q = { s:byte(i, i + 3) }
        local v, pad = 0, 0
        for j = 1, 4 do
            local ch = string.char(q[j])
            local d
            if ch == "=" then d, pad = 0, pad + 1 else d = DEC[ch] end
            if not d then return nil end
            v = v * 64 + d
        end
        local a, b, c = math.floor(v / 65536) % 256, math.floor(v / 256) % 256, v % 256
        out[#out + 1] = string.char(a) .. (pad < 2 and string.char(b) or "") .. (pad < 1 and string.char(c) or "")
    end
    return table.concat(out)
end

--------------------------------------------------
-- Layout des Bearbeitungsmodus
--------------------------------------------------

local function OwnLayout()
    local em = _G.C_EditMode
    if not (em and em.GetLayouts) then return nil end
    local ok, info = pcall(em.GetLayouts)
    if not ok or type(info) ~= "table" or type(info.layouts) ~= "table" then return nil end
    local name = WeintCodex.UISetup and WeintCodex.UISetup.LAYOUT_NAME
    for i, l in ipairs(info.layouts) do
        if l.layoutName == name then return l, info, i end
    end
    return nil, info
end

function SH.LayoutString()
    local em = _G.C_EditMode
    local l = OwnLayout()
    if not (l and em and em.ConvertLayoutInfoToString) then return nil end
    local ok, s = pcall(em.ConvertLayoutInfoToString, l)
    return ok and type(s) == "string" and s ~= "" and s or nil
end

-- Schreibt das Layout als "WeintCodex" (ersetzt nur dieses). true / false, Grund.
function SH.ImportLayout(str)
    local em = _G.C_EditMode
    if not (em and em.ConvertStringToLayoutInfo and em.SaveLayouts) then return false, "Bearbeitungsmodus kann nicht einlesen" end
    local ok, l = pcall(em.ConvertStringToLayoutInfo, str)
    if not ok or type(l) ~= "table" then return false, "Layout nicht lesbar" end
    local _, info, slot = OwnLayout()
    if type(info) ~= "table" then return false, "Layouts nicht lesbar" end
    l.layoutName = WeintCodex.UISetup.LAYOUT_NAME
    local LT = _G.Enum and _G.Enum.EditModeLayoutType
    l.layoutType = LT and LT.Account or l.layoutType
    slot = slot or (#info.layouts + 1)
    info.layouts[slot] = l
    local okS, err = pcall(em.SaveLayouts, info)
    if not okS then return false, "SaveLayouts: " .. tostring(err) end
    return true
end

--------------------------------------------------
-- Export und Import
--------------------------------------------------

function SH.Export()
    local ui = K.Root()
    local PR = WeintCodex.UIProfiles
    local name = PR.Chosen()
    local p = ui and ui.profiles[name]
    if type(p) ~= "table" then return nil end
    local data = { v = 1, name = name, profile = p, layout = SH.LayoutString(),
                   addon = WeintCodex.Version }
    return SH.PREFIX .. SH.Encode(SH.Serialize(data))
end

-- Liest einen Text: Tabelle oder nil, Grund. Aendert nichts.
function SH.Parse(text)
    if type(text) ~= "string" then return nil, "kein Text" end
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    if #text > SH.MAX_LEN then return nil, "zu lang" end
    if text:sub(1, #SH.PREFIX) ~= SH.PREFIX then return nil, "kein WeintCodex-Profil (beginnt nicht mit " .. SH.PREFIX .. ")" end
    local raw = SH.Decode(text:sub(#SH.PREFIX + 1))
    if not raw then return nil, "Text beschädigt" end
    local data, why = SH.Deserialize(raw)
    if type(data) ~= "table" then return nil, why or "Text beschädigt" end
    if data.v ~= 1 or type(data.profile) ~= "table" then return nil, "unbekannte Fassung" end
    if data.layout ~= nil and type(data.layout) ~= "string" then data.layout = nil end
    return data
end

-- Uebernimmt einen gelesenen Text ins gewaehlte Profil. true / false, Grund, Layout-Hinweis.
function SH.Apply(data)
    local ui = K.Root()
    local PR = WeintCodex.UIProfiles
    local target = PR.Chosen()
    local p = ui and ui.profiles[target]
    if type(p) ~= "table" then return false, "kein Profil gewählt" end
    -- Dieselbe Tabelle behalten (K.Profile hat sie vielleicht in der Hand).
    for k in pairs(p) do p[k] = nil end
    for k, v in pairs(PR.DeepCopy(data.profile)) do p[k] = v end
    local layoutNote
    if data.layout then
        local ok, why = SH.ImportLayout(data.layout)
        layoutNote = ok and "Layout „WeintCodex“ übernommen." or ("Layout nicht übernommen: " .. tostring(why) .. ".")
    end
    if target == PR.Active() then K.MarkReload() end
    K.Fire("setting", "general", "profile")
    return true, target, layoutNote
end

local function Say(text)
    print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " " .. text)
end

function SH.ShowExport()
    local s = SH.Export()
    if not s then Say("Kein Profil zum Exportieren.") return end
    local PR = WeintCodex.UIProfiles
    K.ShowReport("Profil „" .. PR.Chosen() .. "“ exportieren – kopieren und sicher ablegen oder teilen", s)
end

--------------------------------------------------
-- Fenster zum Einfuegen
--------------------------------------------------

local win
local function BuildImport()
    local f = CreateFrame("Frame", "WeintCodexImportProfile", UIParent)
    f:SetSize(K.REPORT_W, 300)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
    f:SetFrameStrata("FULLSCREEN_DIALOG")   -- ueber /wcui (6.28.0.1)
    f:SetToplevel(true)
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetClampedToScreen(true)
    K.Kachel(f, { shadow = 8 })
    if type(_G.UISpecialFrames) == "table" then table.insert(_G.UISpecialFrames, "WeintCodexImportProfile") end
    local title = K.NewText(f, 14)
    title:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -14)
    title:SetTextColor(unpack(C.textBright))
    f.title = title
    local hint = K.NewText(f, 11)
    hint:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    hint:SetPoint("RIGHT", f, "RIGHT", -16, 0)
    hint:SetJustifyH("LEFT")
    hint:SetTextColor(unpack(C.textMuted))
    f.hint = hint
    local box = CreateFrame("Frame", nil, f)
    box:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -60)
    box:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -14, 52)
    local bg = box:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(box)
    bg:SetColorTexture(unpack(C.bgDark))
    K.Border(box, 1, 0, 0, 0, 1, "BORDER")
    local scroll = CreateFrame("ScrollFrame", nil, box, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", box, "TOPLEFT", 6, -6)
    scroll:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -26, 6)
    local eb = CreateFrame("EditBox", nil, scroll)
    eb:SetMultiLine(true)
    eb:SetMaxLetters(0)
    eb:SetAutoFocus(false)
    eb:SetWidth(K.REPORT_W - 60)
    K.SetFont(eb, 11)
    eb:SetTextColor(unpack(C.textNormal))
    eb:SetScript("OnEscapePressed", function() f:Hide() end)
    scroll:SetScrollChild(eb)
    f.edit = eb
    local close = WeintCodex.CreateButton(f, { text = "Abbrechen", kind = "secondary", width = 120, height = 28,
        onClick = function() f:Hide() end })
    close:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -14, 14)
    local go = WeintCodex.CreateButton(f, { text = "Importieren", kind = "primary", width = 150, height = 28,
        onClick = function() SH.ImportFrom(eb:GetText()) end })
    go:SetPoint("RIGHT", close, "LEFT", -8, 0)
    f.go, f.close = go, close
    return f
end

function SH.ShowImport()
    win = win or BuildImport()
    local PR = WeintCodex.UIProfiles
    win.title:SetText("Profil importieren")
    win.hint:SetText("Text einfügen (Strg+V) und „Importieren“. Ersetzt alle Einstellungen von „" .. PR.Chosen() .. "“ – wirkt nach dem Neuladen.")
    win.edit:SetText("")
    win:Show()
    if win.Raise then win:Raise() end
    win.edit:SetFocus()
    SH.win = win
    return win
end

function SH.ImportFrom(text)
    local data, why = SH.Parse(text)
    if not data then Say("Import nicht möglich: " .. tostring(why) .. ".") return false end
    local PR = WeintCodex.UIProfiles
    local from = type(data.name) == "string" and data.name or "?"
    -- Die Rueckfrage des Spiels liegt in einer tieferen Schicht - das
    -- Fenster weicht ihr, der Text ist schon gelesen.
    if win then win:Hide() end
    PR.Confirm("Profil „" .. from .. "“ importieren? Alle Einstellungen und Plätze von „" .. PR.Chosen() .. "“ werden ersetzt"
        .. (data.layout and ", dazu das Layout „WeintCodex“ des Bearbeitungsmodus." or "."), function()
        local ok, target, note = SH.Apply(data)
        if ok then
            Say("Profil in „" .. target .. "“ importiert. " .. (note and (note .. " ") or "") .. "Neu laden, damit es gilt.")
            if win then win:Hide() end
        end
    end)
    return true
end
