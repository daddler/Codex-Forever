--------------------------------------------------
-- WeintCodex :: Charakter
--
-- Zwei Fragen, und nur diese zwei:
--
--   1. Was hat dieser Charakter an - und fehlt oder zerbricht davon
--      gerade etwas?
--   2. Welche Charaktere dieses Kontos sollen dem Bot als "meine"
--      gemeldet werden (Kalender-Einladung, Rosterabgleich)?
--
-- WAS DIESE DATEI FUER FOREVER NICHT TUT, und warum:
--
-- In der Fassung fuer Mists of Pandaria stand hier die Bewertung von
-- Verzauberungen, Sockelsteinen, Umschmieden, Tempo-Schwellen und
-- BiS-Listen - knapp achttausend Zeilen. Kein Satz davon ist
-- uebertragbar: welche Verzauberungen es in Forever gibt, welche
-- Werte etwas bringen und ob es ueberhaupt Sockel gibt, ist nicht
-- veroeffentlicht. Eine uebernommene Bewertung haette nicht
-- geschwiegen, sondern jedem Spieler Maengel vorgeworfen, die es in
-- seinem Spiel gar nicht gibt.
--
-- Was bleibt, ist, was der Client selbst beantwortet: belegt oder
-- leer, heil oder zerbrochen, welche Gegenstandsstufe. Das ist wenig -
-- aber es ist wahr, und es wird nicht mit der Zeit falsch.
--
-- DIE AUSRUESTUNGSPLAETZE KOMMEN VOM CLIENT, NICHT VON UNS. Forever
-- laeuft auf der modernen Client-API, und ob es dort einen
-- Distanzplatz gibt, wissen wir nicht. Deshalb wird jeder Platz ueber
-- GetInventorySlotInfo aufgeloest; was der Client nicht kennt, faellt
-- aus der Liste. Ein fest verdrahteter Platz 18 wuerde sonst auf
-- jedem Charakter als "leer" dastehen.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.Charakter = {}

local C = WeintCodex.Colors

--------------------------------------------------
-- Client-Aufrufe, defensiv
--------------------------------------------------
-- Es gibt keine laufende Forever-Instanz, an der sich Signatur oder
-- Verhalten pruefen liessen. Jeder Aufruf geht deshalb durch pcall,
-- und ein Fehlschlag liefert nil - "nicht beantwortet" und nicht
-- "nichts da".

local function Safe(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b = pcall(fn, ...)
    if not ok then return nil end
    return a, b
end

--------------------------------------------------
-- Ausruestungsplaetze
--------------------------------------------------

local SLOT_DEFS = {
    { key = "HeadSlot",          name = "Kopf" },
    { key = "NeckSlot",          name = "Hals" },
    { key = "ShoulderSlot",      name = "Schultern" },
    { key = "BackSlot",          name = "Umhang" },
    { key = "ChestSlot",         name = "Brust" },
    { key = "WristSlot",         name = "Handgelenke" },
    { key = "HandsSlot",         name = "Hände" },
    { key = "WaistSlot",         name = "Taille" },
    { key = "LegsSlot",          name = "Beine" },
    { key = "FeetSlot",          name = "Füße" },
    { key = "Finger0Slot",       name = "Finger 1" },
    { key = "Finger1Slot",       name = "Finger 2" },
    { key = "Trinket0Slot",      name = "Schmuck 1" },
    { key = "Trinket1Slot",      name = "Schmuck 2" },
    { key = "MainHandSlot",      name = "Haupthand" },
    { key = "SecondaryHandSlot", name = "Nebenhand" },

    -- Der Distanzplatz. In Classic gibt es ihn, im modernen Client
    -- nicht mehr. Welche der beiden Welten Forever ist, entscheidet
    -- der Client - nicht diese Liste.
    { key = "RangedSlot",        name = "Distanz" },
}

-- Einmalig aufgeloest, aber erst beim ersten Zugriff: zur Ladezeit
-- der Datei ist GetInventorySlotInfo noch nicht zwingend brauchbar.
local resolvedSlots = nil

local function EquipSlots()
    if resolvedSlots then return resolvedSlots end

    local out = {}
    for _, def in ipairs(SLOT_DEFS) do
        local id = Safe(GetInventorySlotInfo, def.key)
        if type(id) == "number" then
            out[#out + 1] = { id = id, key = def.key, name = def.name }
        end
    end

    -- Nur zwischenspeichern, wenn ueberhaupt etwas herauskam. Sonst
    -- friert ein zu frueher Aufruf die leere Antwort fuer die ganze
    -- Sitzung ein.
    if #out > 0 then resolvedSlots = out end
    return out
end

WeintCodex.Charakter.EquipSlots = EquipSlots

--------------------------------------------------
-- Spezialisierung
--------------------------------------------------
-- Drei Wege, in dieser Reihenfolge, und ein ehrliches nil am Ende.
-- Geraten wird nichts: eine falsche Spezialisierung wandert ueber die
-- Companion-Bruecke bis in den Bot und ordnet den Spieler dort der
-- falschen Rolle zu.

local function CurrentSpec()
    local _, classFile = Safe(UnitClass, "player")
    if type(classFile) ~= "string" then return nil, nil end

    -- 1. Moderner Client: GetSpecialization liefert den Index des
    --    aktiven Baums.
    local index = Safe(GetSpecialization)
    if type(index) == "number" and index > 0 then
        local spec = WeintCodex.Specs.ByIndex(classFile, index)
        if spec then return spec, classFile end

        -- Der Client kennt einen Baum, den unsere Tabelle nicht
        -- fuehrt. Dann wenigstens seinen Namen nehmen - aber nicht
        -- unsere Tabelle danach biegen.
        local _, name = Safe(GetSpecializationInfo, index)
        if type(name) == "string" and name ~= "" then
            local byName = WeintCodex.Specs.ByName(classFile, name)
            if byName then return byName, classFile end
        end
    end

    -- 2. Classic-Weg: der Baum mit den meisten Punkten.
    local primary = Safe(GetPrimaryTalentTree)
    if type(primary) == "number" and primary > 0 then
        local spec = WeintCodex.Specs.ByIndex(classFile, primary)
        if spec then return spec, classFile end
    end

    -- 3. Keine Antwort. Das ist eine Antwort.
    return nil, classFile
end

-- Der Profilschluessel, wie ihn die Companion-Bruecke fuehrt
-- (CLASSFILE_ENGLISCHERBAUM). Leer, solange die Spezialisierung nicht
-- feststeht - die Gegenseite nimmt ein leeres Feld hin, eine geratene
-- Spezialisierung nicht.
function WeintCodex.Charakter.GetProfileKey()
    local spec = CurrentSpec()
    if not spec then return nil end
    return WeintCodex.Specs.Key(spec)
end

function WeintCodex.Charakter.GetSpec()
    return CurrentSpec()
end

--------------------------------------------------
-- Der Ausruestungsstand
--------------------------------------------------
-- Rueckgabe oder nil. `nil` heisst "der Client hat nicht geantwortet"
-- und ist etwas anderes als eine leere Ausruestung - die Startseite
-- unterscheidet das.
--
--   specDisplay  Anzeigename der Spezialisierung, oder nil
--   specKey      CLASSFILE_BAUM, oder nil
--   itemLevel    Gegenstandsstufe angelegt, oder nil (NIE 0)
--   itemLevelAll Gegenstandsstufe gesamt, oder nil
--   slots        { { id, name, link, itemLevel, broken }, ... }
--   empty        Namen der leeren Plaetze
--   broken       Namen der zerbrochenen Plaetze

local function SlotItemLevel(link, slotId)
    if type(link) ~= "string" then return nil end

    -- Der moderne Weg zuerst, dann der aeltere. Beides kann fehlen;
    -- dann bleibt die Stufe unbekannt und wird nirgends als 0 gezeigt.
    local detailed = C_Item and C_Item.GetDetailedItemLevelInfo
    local level = Safe(detailed or GetDetailedItemLevelInfo, link)
    if type(level) == "number" and level > 0 then return level end

    local _, _, _, baseLevel = Safe(GetItemInfo, link)
    if type(baseLevel) == "number" and baseLevel > 0 then return baseLevel end

    return nil
end

function WeintCodex.Charakter.Snapshot()
    local slots = EquipSlots()
    if #slots == 0 then return nil end

    local spec, classFile = CurrentSpec()

    local out = {
        classFile   = classFile,
        specDisplay = spec and spec.name or nil,
        specKey     = spec and WeintCodex.Specs.Key(spec) or nil,
        role        = spec and spec.role or nil,
        slots       = {},
        empty       = {},
        broken      = {},
    }

    for _, slot in ipairs(slots) do
        local link = Safe(GetInventoryItemLink, "player", slot.id)

        local entry = {
            id        = slot.id,
            name      = slot.name,
            link      = type(link) == "string" and link or nil,
            itemLevel = SlotItemLevel(link, slot.id),
        }

        if not entry.link then
            -- Nebenhand und Distanz duerfen leer sein: ein
            -- Zweihandkaempfer traegt keine Nebenhand, und das ist
            -- kein Mangel. Sie werden aufgefuehrt, aber nicht
            -- angemahnt.
            if slot.key ~= "SecondaryHandSlot" and slot.key ~= "RangedSlot" then
                out.empty[#out.empty + 1] = slot.name
            end
        else
            local current, maximum = Safe(GetInventoryItemDurability, slot.id)
            if type(current) == "number" and current <= 0 then
                entry.broken = true
                out.broken[#out.broken + 1] = slot.name
            end
        end

        out.slots[#out.slots + 1] = entry
    end

    -- GetAverageItemLevel gibt (gesamt, angelegt) zurueck. Eine 0 ist
    -- hier keine Messung, sondern eine ausgebliebene Antwort.
    local overall, equipped = Safe(GetAverageItemLevel)
    if type(equipped) == "number" and equipped > 0 then out.itemLevel = equipped end
    if type(overall)  == "number" and overall  > 0 then out.itemLevelAll = overall end

    return out
end

--------------------------------------------------
-- Twinks
--------------------------------------------------
-- SavedData.twinks[<Name>] = { class, level, realm, selected }
--
-- Gefuellt wird die Tabelle bei jedem Login durch
-- Companion.ReportCharacter(); hier steht nur, was der Spieler daran
-- aendern kann - naemlich ob ein Charakter dem Bot gemeldet wird.

local function Twinks()
    WeintCodex.SavedData = WeintCodex.SavedData or {}
    WeintCodex.SavedData.twinks = WeintCodex.SavedData.twinks or {}
    return WeintCodex.SavedData.twinks
end

WeintCodex.Charakter.Twinks = Twinks

-- Alphabetisch, damit die Liste zwischen zwei Aufrufen nicht springt:
-- pairs() ueber eine Tabelle hat keine Reihenfolge.
local function SortedTwinks()
    local out = {}
    for name, data in pairs(Twinks()) do
        out[#out + 1] = { name = name, data = data }
    end
    table.sort(out, function(a, b) return a.name < b.name end)
    return out
end

function WeintCodex.Charakter.SetSelected(name, selected)
    local entry = Twinks()[name]
    if not entry then return end
    entry.selected = selected and true or false

    -- Sofort melden: wer einen Twink abwaehlt, erwartet, dass der
    -- naechste Kalender-Invite ihn nicht mehr kennt - und nicht erst
    -- der uebernaechste Login.
    if WeintCodex.Companion and WeintCodex.Companion.ReportCharacter then
        WeintCodex.Companion.ReportCharacter()
    end
end

function WeintCodex.Charakter.Forget(name)
    Twinks()[name] = nil
    if WeintCodex.Companion and WeintCodex.Companion.ReportCharacter then
        WeintCodex.Companion.ReportCharacter()
    end
end

local function ClassColor(classFile)
    local colors = _G.RAID_CLASS_COLORS
    local col = colors and classFile and colors[classFile]
    if not col then return C.textNormal end
    return { col.r, col.g, col.b, 1.0 }
end

--------------------------------------------------
-- Seite
--------------------------------------------------
-- Zwei Spalten im Inhalt: links die Ausruestungsplaetze, rechts die
-- Charaktere dieses Kontos mit ihrem Schalter. Der Detailbereich
-- traegt nur Tatsachen - was man umstellen kann, steht dort, wo man
-- es sieht.
--------------------------------------------------

local page      = nil
local slotRows  = {}
local twinkRows = {}

local function ClearRows(list)
    for _, row in ipairs(list) do row:Hide() end
    wipe(list)
end

local function BuildPage()
    if page then return page end

    local cp = WeintCodex.ContentPanel
    local f  = CreateFrame("Frame", nil, cp)
    f:SetAllPoints(cp)

    local PAD_X = WeintCodex.Metrics.PAD_X
    local PAD_Y = WeintCodex.Metrics.PAD_Y

    f.Head = WeintCodex.PageHead(f, {
        eyebrow = "Charakter",
        title   = UnitName("player") or "Charakter",
        sub     = "Was angelegt ist – und welche Charaktere der Bot kennt.",
        height  = 84,
    })

    --------------------------------------------------
    -- Linke Spalte: Ausruestung
    --------------------------------------------------

    local gearCard = WeintCodex.CreateSurface(f, {
        tone = "plain", radius = 14, backdrop = "bgDark",
    })
    gearCard:SetPoint("TOPLEFT",    f, "TOPLEFT",     PAD_X, -(PAD_Y + 84))
    gearCard:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT",  PAD_X,  PAD_Y)
    gearCard:SetWidth(460)
    f.GearCard = gearCard

    local gearTitle = gearCard:CreateFontString(nil, "OVERLAY")
    gearTitle:SetFont(WeintCodex.Fonts.sansSemi, 14, "")
    gearTitle:SetPoint("TOPLEFT", gearCard, "TOPLEFT", 20, -16)
    gearTitle:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3])
    gearTitle:SetText("Angelegt")

    -- Die Hoehe des Bildlauffelds steht erst nach dem Layout fest; sie
    -- wird deshalb in Show() nachgezogen.
    f.GearScroll, f.GearBody =
        WeintCodex.CreateScrollArea(gearCard, 20, -46, 420, 300, true)

    --------------------------------------------------
    -- Rechte Spalte: Charaktere
    --------------------------------------------------

    local twinkCard = WeintCodex.CreateSurface(f, {
        tone = "plain", radius = 14, backdrop = "bgDark",
    })
    twinkCard:SetPoint("TOPLEFT",     gearCard, "TOPRIGHT", WeintCodex.Metrics.GAP, 0)
    twinkCard:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -PAD_X, PAD_Y)
    f.TwinkCard = twinkCard

    local twinkTitle = twinkCard:CreateFontString(nil, "OVERLAY")
    twinkTitle:SetFont(WeintCodex.Fonts.sansSemi, 14, "")
    twinkTitle:SetPoint("TOPLEFT", twinkCard, "TOPLEFT", 20, -16)
    twinkTitle:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3])
    twinkTitle:SetText("Meine Charaktere")

    local twinkHint = WeintCodex.Label(twinkCard,
        "Nur die eingeschalteten meldet WeintCodex an den Bot – er braucht "
        .. "sie für die Kalender-Einladung.",
        { color = "textMuted", size = 12 })
    twinkHint:SetPoint("TOPLEFT",  twinkCard, "TOPLEFT",  20, -42)
    twinkHint:SetPoint("TOPRIGHT", twinkCard, "TOPRIGHT", -20, -42)

    f.TwinkScroll, f.TwinkBody =
        WeintCodex.CreateScrollArea(twinkCard, 20, -82, 300, 260, true)

    page = f
    return f
end

--------------------------------------------------

local function DrawSlots(body, snapshot)
    ClearRows(slotRows)

    if not snapshot then
        -- "Nicht gelesen" ist etwas anderes als "nichts angelegt", und
        -- genau das steht hier auch.
        local note = WeintCodex.Label(body,
            "Die Ausrüstung konnte nicht gelesen werden. Das heißt nicht, "
            .. "dass nichts angelegt ist – nur, dass der Client gerade keine "
            .. "Auskunft gibt.",
            { color = "textMuted", size = 13 })
        note:SetPoint("TOPLEFT",  body, "TOPLEFT",  0, -8)
        note:SetPoint("TOPRIGHT", body, "TOPRIGHT", 0, -8)
        slotRows[#slotRows + 1] = note
        body:SetHeight(90)
        return
    end

    local y = 0

    for _, slot in ipairs(snapshot.slots) do
        local row = CreateFrame("Frame", nil, body)
        row:SetHeight(32)
        row:SetPoint("TOPLEFT",  body, "TOPLEFT",  0, y)
        row:SetPoint("TOPRIGHT", body, "TOPRIGHT", 0, y)

        -- Kein Punkt, wo es keinen Zustand gibt: ein leerer Platz an
        -- Nebenhand oder Distanz ist kein Mangel.
        local tone
        if slot.broken then
            tone = "warning"
        elseif slot.link then
            tone = "success"
        end

        local dot = WeintCodex.StatusDot(row, tone, 7)
        dot:SetPoint("LEFT", row, "LEFT", 0, 0)

        local name = WeintCodex.Label(row, slot.name, { color = "textMuted", size = 12 })
        name:SetPoint("LEFT", dot, "RIGHT", 10, 0)
        name:SetWidth(92)

        local item = WeintCodex.Label(row,
            slot.link or WeintCodex.ColorText("textFaint", "— leer —"),
            { color = "textNormal", size = 13 })
        item:SetPoint("LEFT",  name, "RIGHT", 8, 0)
        item:SetPoint("RIGHT", row,  "RIGHT", -62, 0)
        item:SetWordWrap(false)

        local lvl = row:CreateFontString(nil, "OVERLAY")
        lvl:SetFont(WeintCodex.Fonts.monoBold, 11, "")
        lvl:SetPoint("RIGHT", row, "RIGHT", 0, 0)
        if slot.broken then
            lvl:SetTextColor(C.warningBright[1], C.warningBright[2], C.warningBright[3])
            lvl:SetText(WeintCodex.Spaced("DEFEKT"))
        elseif slot.itemLevel then
            lvl:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3])
            lvl:SetText(tostring(slot.itemLevel))
        else
            -- Ausdruecklich kein "0": die Stufe ist unbekannt, nicht null.
            lvl:SetTextColor(C.textFaint[1], C.textFaint[2], C.textFaint[3])
            lvl:SetText(WeintCodex.Spaced("—"))
        end

        WeintCodex.RowLine(row, -31)

        slotRows[#slotRows + 1] = row
        y = y - 34
    end

    body:SetHeight(math.max(1, -y))
end

--------------------------------------------------

local function DrawTwinks(body)
    ClearRows(twinkRows)

    local list = SortedTwinks()

    if #list == 0 then
        local note = WeintCodex.Label(body,
            "Noch kein Charakter erfasst. Jeder Charakter trägt sich beim "
            .. "Einloggen selbst ein.",
            { color = "textFaint", size = 12 })
        note:SetPoint("TOPLEFT",  body, "TOPLEFT",  0, 0)
        note:SetPoint("TOPRIGHT", body, "TOPRIGHT", 0, 0)
        twinkRows[#twinkRows + 1] = note
        body:SetHeight(60)
        return
    end

    local y = 0
    local me = UnitName("player")

    for _, entry in ipairs(list) do
        local name, data = entry.name, entry.data

        local toggle = WeintCodex.CreateToggle(body, {
            label       = name .. (name == me and "  (hier)" or ""),
            description = (data.realm and data.realm ~= "" and (data.realm .. " · ") or "")
                          .. "Stufe " .. tostring(data.level or "?"),
            get = function() return data.selected and true or false end,
            set = function(value)
                WeintCodex.Charakter.SetSelected(name, value)
            end,
        })
        toggle:SetPoint("TOPLEFT",  body, "TOPLEFT",  0, y)
        toggle:SetPoint("TOPRIGHT", body, "TOPRIGHT", 0, y)
        toggle:Sync()

        -- Der Klassenton faerbt den Namen. RAID_CLASS_COLORS kann in
        -- diesem Client fehlen; dann bleibt der Name neutral, statt
        -- eine Farbe zu raten.
        local col = ClassColor(data.class)
        if toggle._label then
            toggle._label:SetTextColor(col[1], col[2], col[3])
        end

        twinkRows[#twinkRows + 1] = toggle
        y = y - (toggle:GetHeight() or 46) - 4
    end

    body:SetHeight(math.max(1, -y))
end

--------------------------------------------------

local function InspectorBlocks(snapshot)
    local level = UnitLevel("player")

    return {
        { type = "header", text = "Dieser Charakter" },
        { type = "rows", rows = {
            { label = "Name",  value = UnitName("player") or "—" },
            { label = "Stufe", value = (type(level) == "number" and level > 0)
                  and tostring(level) or "—" },
            { label = "Spezialisierung",
              value = (snapshot and snapshot.specDisplay) or "noch nicht bekannt",
              valueColor = (snapshot and snapshot.specDisplay) and "textNormal" or "textFaint" },
            -- Eine fehlende Gegenstandsstufe bleibt ein Gedankenstrich.
            -- Eine 0 waere die Behauptung, es sei gemessen worden.
            { label = "Stufe angelegt",
              value = (snapshot and snapshot.itemLevel)
                  and string.format("%.1f", snapshot.itemLevel) or "—",
              valueColor = (snapshot and snapshot.itemLevel) and "textNormal" or "textFaint" },
            { label = "Stufe gesamt",
              value = (snapshot and snapshot.itemLevelAll)
                  and string.format("%.1f", snapshot.itemLevelAll) or "—",
              valueColor = (snapshot and snapshot.itemLevelAll) and "textNormal" or "textFaint" },
        }},
        { type = "divider" },
        { type = "header", text = "Was hier nicht steht" },
        { type = "card", lines = {
            "Verzauberungen, Sockel und Umschmieden bewertet WeintCodex",
            "in dieser Fassung nicht. Was Forever davon überhaupt kennt",
            "und was etwas bringt, ist nicht veröffentlicht – eine aus",
            "Mists of Pandaria übernommene Bewertung hätte jedem",
            "Mängel vorgeworfen, die es in seinem Spiel nicht gibt.",
        }},
    }
end

--------------------------------------------------

function WeintCodex.Charakter.Show()
    local cp = WeintCodex.ContentPanel
    for _, child in pairs({ cp:GetChildren() }) do child:Hide() end

    local f = BuildPage()
    f:Show()

    WeintCodex.SetBreadcrumb("Charakter", UnitName("player") or "")

    local snapshot = WeintCodex.Charakter.Snapshot()

    if f.Head and f.Head.Title then
        f.Head.Title:SetText(UnitName("player") or "Charakter")
    end

    -- Die Bildlauffelder an die tatsaechliche Kartenhoehe anpassen: die
    -- Karten haengen an zwei Kanten und sind deshalb erst nach dem
    -- Layout so hoch, wie sie hier gebraucht werden.
    local gearH = (f.GearCard:GetHeight() or 360) - 70
    if gearH > 60 then f.GearScroll:SetHeight(gearH) end

    local twinkH = (f.TwinkCard:GetHeight() or 320) - 104
    if twinkH > 60 then f.TwinkScroll:SetHeight(twinkH) end

    DrawSlots(f.GearBody, snapshot)
    DrawTwinks(f.TwinkBody)

    WeintCodex.Navigation.SetInspector(InspectorBlocks(snapshot))
end
