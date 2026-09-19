--------------------------------------------------
-- WeintCodex :: Einstellungen
--------------------------------------------------
-- Jede Option des Addons an einer Stelle, als Schalter statt als Befehl.
--
-- **Warum es das gibt.** Ein Slash-Befehl ist die Bedienung fuer den, der
-- ihn schon kennt; wer ihn nicht kennt, erfaehrt nie, dass es die
-- Einstellung ueberhaupt gibt. In der Vorgaengerfassung hing jede einzelne
-- Einstellung an einem Befehl oder an einem Fenster, das man erst oeffnen
-- musste, um es abschalten zu koennen.
--
-- Die Befehle bleiben allesamt bestehen - sie sind der schnelle Weg mitten
-- im Raid und die einzige Form, in der eine *Diagnoseausgabe* Sinn ergibt.
-- Was sich aendert: es gibt zu jedem eine Schaltflaeche, und die Seite ist
-- der Ort, an dem man erfaehrt, dass es ihn gibt.
--
-- Bewusst KEIN `feature` am Navigationseintrag: die Einstellungen sind die
-- Bedienung des Addons selbst, keine gildeninterne Lieferung. Eine
-- gesperrte Einstellungsseite wuerde ausserdem genau den Weg versperren,
-- ueber den man abstellt, was einen gestoert hat.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.Settings = {}

local S = WeintCodex.Settings
local C = WeintCodex.Colors
local F = WeintCodex.Fonts

local PAD_X  = 16
local HEAD_H = 74   -- Eyebrow + 20er Titel + Unterzeile; der Inhalt setzt darunter an
local ROW_W_MAX = 620   -- Lesebreite: eine Schalterzeile ueber 1400 px waere unlesbar

local pageFrame   = nil
local pageHead    = nil
local scroller    = nil
local body        = nil
local currentView = "fenster"

-- Zweistufige Bestaetigung des Profil-Ruecksetzens (siehe unten). Steht
-- ausserhalb der Zeichenfunktion, damit ein Neuaufbau der Seite die
-- Bestaetigung wieder entschaerft statt sie stehen zu lassen.
local resetArmed = false

-- Refresh() ist fuer Aenderungen von AUSSEN da (ein Slash-Befehl, waehrend
-- die Seite offen steht). Aus einem Schalter dieser Seite heraus waere er
-- ein Neuaufbau mitten im Klick: das eigene Widget wuerde dabei versteckt,
-- und die Zeile, die man gerade umgelegt hat, gaebe es nicht mehr. Der
-- Schalter zieht seinen eigenen Zustand ohnehin selbst nach.
local suppressRefresh = false

-- SavedData.window wird in core/main.lua bei ADDON_LOADED angelegt. Die Seite
-- ist erst danach erreichbar; der Umweg hier kostet nichts und macht die
-- Reihenfolge nicht zur Voraussetzung.
local function WindowStore()
    WeintCodex.SavedData = WeintCodex.SavedData or {}
    WeintCodex.SavedData.window = WeintCodex.SavedData.window or {}
    return WeintCodex.SavedData.window
end

local function Say(text)
    print(WeintCodex.ColorText("gold", "[WeintCodex]") .. " " .. text)
end

--------------------------------------------------
-- Bausteine
--------------------------------------------------
-- Alle bauen in `body` (das Bildlaufkind) und geben die neue y-Position
-- zurueck. y ist durchgehend negativ, wie ueberall sonst im Addon.
--------------------------------------------------

local widgets    = {}
local toggleRows = {}

local function Track(w)
    widgets[#widgets + 1] = w
    return w
end

-- Ein Schalter kann einen anderen sperren ("Signalton" nur bei aktivem
-- Alarm). Statt die ganze Seite dafuer neu aufzubauen - WoW gibt Frames nie
-- wieder frei - lesen alle Schalter ihren Zustand einfach noch einmal.
local function SyncToggles()
    for _, row in ipairs(toggleRows) do row:Sync() end
end

-- Gemessene statt geschaetzter Texthoehe, mit derselben Absicherung wie in
-- modules/gearalert.lua: die Beschreibungen brechen um, und mit festen
-- Abstaenden laege die naechste Zeile darunter darin.
local function TextHeight(fs, minimum)
    local ok, h = pcall(fs.GetStringHeight, fs)
    if not ok or type(h) ~= "number" or h <= 0 then return minimum end
    return math.max(minimum, math.ceil(h))
end

local function Group(y, title, subtitle)
    local eyebrow = WeintCodex.Eyebrow(body, title, { color = "accent", size = 10 })
    eyebrow:SetPoint("TOPLEFT", body, "TOPLEFT", 0, y)
    Track(eyebrow)
    y = y - 18

    if subtitle then
        local sub = body:CreateFontString(nil, "OVERLAY")
        sub:SetFont(F.sans, 11, "")
        sub:SetPoint("TOPLEFT", body, "TOPLEFT", 0, y)
        sub:SetWidth(ROW_W_MAX)
        sub:SetJustifyH("LEFT")
        sub:SetTextColor(unpack(C.textDim))
        sub:SetText(subtitle)
        Track(sub)
        y = y - TextHeight(sub, 14) - 6
    end

    local line = body:CreateTexture(nil, "ARTWORK")
    line:SetHeight(1)
    line:SetPoint("TOPLEFT",  body, "TOPLEFT", 0, y - 4)
    line:SetWidth(ROW_W_MAX)
    line:SetColorTexture(unpack(C.rowLine))
    Track(line)

    return y - 14
end

local function Toggle(y, opts)
    opts.width = ROW_W_MAX
    local row = WeintCodex.CreateToggle(body, opts)
    row:SetPoint("TOPLEFT", body, "TOPLEFT", 0, y)
    Track(row)
    toggleRows[#toggleRows + 1] = row
    return y - row:GetHeight() - 4
end

-- Gibt zusaetzlich das Widget zurueck: eine Schaltflaeche daneben kann den
-- Wert aendern ("Groesse zuruecksetzen"), und der Regler muss das mitbekommen.
local function Slider(y, opts)
    local row = WeintCodex.CreateSlider(body, opts)
    row:SetWidth(ROW_W_MAX)
    row:SetPoint("TOPLEFT", body, "TOPLEFT", 0, y)
    Track(row)
    return y - row:GetHeight() - 6, row
end

-- Schaltflaechenreihe, die selbst umbricht. Die Breite einer Schaltflaeche
-- steht erst fest, wenn ihr Text darin sitzt (siehe CreateButton), also wird
-- hier nach dem Bauen gemessen und dann angesetzt.
local function Buttons(y, defs)
    local x, lineH = 0, 0
    for _, def in ipairs(defs) do
        local b = WeintCodex.CreateButton(body, {
            text     = def.text,
            kind     = def.kind or "secondary",
            height   = 30,
            size     = 11,
            tooltip  = def.tooltip,
            backdrop = "bgDark",
            onClick  = def.onClick,
        })
        local w = b:GetWidth()
        if x > 0 and (x + w) > ROW_W_MAX then
            y = y - lineH - 8
            x, lineH = 0, 0
        end
        b:SetPoint("TOPLEFT", body, "TOPLEFT", x, y)
        Track(b)
        x = x + w + 8
        lineH = math.max(lineH, b:GetHeight())
        def.frame = b
    end
    return y - lineH - 10
end

local function Note(y, text, tone)
    local fs = body:CreateFontString(nil, "OVERLAY")
    fs:SetFont(F.sans, 11, "")
    fs:SetPoint("TOPLEFT", body, "TOPLEFT", 0, y)
    fs:SetWidth(ROW_W_MAX)
    fs:SetJustifyH("LEFT")
    fs:SetTextColor(unpack(C[tone or "textDim"] or C.textDim))
    fs:SetText(text)
    Track(fs)
    return y - TextHeight(fs, 14) - 12
end

-- Zeile "Bezeichnung .... Wert" fuer Zustaende, an denen es nichts zu
-- schalten gibt (Rang des Zugriffsprofils, Zahl der Warteschlange).
local function Info(y, label, value, tone)
    local l = body:CreateFontString(nil, "OVERLAY")
    l:SetFont(F.sans, 12, "")
    l:SetPoint("TOPLEFT", body, "TOPLEFT", 0, y)
    l:SetTextColor(unpack(C.textMuted))
    l:SetText(label)
    Track(l)

    local v = body:CreateFontString(nil, "OVERLAY")
    v:SetFont(F.monoMedium, 11, "")
    v:SetPoint("TOPLEFT", body, "TOPLEFT", 240, y - 1)
    v:SetWidth(ROW_W_MAX - 240)
    v:SetJustifyH("LEFT")
    v:SetTextColor(unpack(C[tone or "textNormal"] or C.textNormal))
    v:SetText(value)
    Track(v)

    return y - 22
end

local function Spacer(y, h)
    return y - (h or 14)
end

--------------------------------------------------
-- Abschnitt: Fenster & Ansicht
--------------------------------------------------

local function ViewWindow(y)
    y = Group(y, "Hauptfenster",
        "Wie sich das WeintCodex-Fenster gegenüber der Oberfläche des Spiels"
        .. " verhält.")

    y = Toggle(y, {
        label = "Mit Esc schließen",
        description = "Die Esc-Taste schließt das Fenster, wie bei den Fenstern des Spiels.",
        get = function() return (WeintCodex.WindowBehaviour()) end,
        set = function(on)
            WindowStore().escClose = on and true or false
            WeintCodex.ApplyWindowBehaviour()
        end,
    })

    y = Toggle(y, {
        label = "Über allen anderen Fenstern halten",
        description = "Aus: Taschen, Charakterbogen und die Dialoge des Spiels liegen wieder darüber.",
        get = function()
            local _, topmost = WeintCodex.WindowBehaviour()
            return topmost
        end,
        set = function(on)
            WindowStore().topmost = on and true or false
            WeintCodex.ApplyWindowBehaviour()
        end,
    })

    local scaleRow
    y, scaleRow = Slider(y, {
        label  = "Fenstergröße",
        min    = 0.70, max = 1.20, step = 0.05,
        get    = function() return WindowStore().scale or 1.0 end,
        set    = function(v)
            WindowStore().scale = v
            WeintCodex.MainFrame:SetScale(v)
        end,
        format = function(v) return string.format("%d %%", math.floor(v * 100 + 0.5)) end,
    })

    y = Buttons(y, {
        { text = "Größe zurücksetzen",
          tooltip = "Setzt Breite, Höhe und Skalierung auf die Vorgabe zurück.",
          onClick = function()
              if WeintCodex.ResetWindowSize then WeintCodex.ResetWindowSize() end
              if scaleRow then scaleRow.Sync() end
          end },
    })

    y = Spacer(y, 8)
    y = Group(y, "Minimap")

    y = Toggle(y, {
        label = "Minimap-Symbol anzeigen",
        description = "Linksklick öffnet WeintCodex, Rechtsklick die Schlachtzüge.",
        -- Nicht nur auf die Tabelle pruefen: core/minimap.lua legt sie ganz
        -- oben an und bricht danach ab, wenn LibDBIcon fehlt - dann gaebe es
        -- WeintCodex.Minimap, aber keine einzige Funktion darin.
        get = function()
            return WeintCodex.Minimap and WeintCodex.Minimap.IsShown
                and WeintCodex.Minimap.IsShown()
        end,
        set = function(on)
            if WeintCodex.Minimap and WeintCodex.Minimap.SetShown then
                WeintCodex.Minimap.SetShown(on)
            end
        end,
    })

    y = Spacer(y, 8)
    y = Spacer(y, 8)
    y = Group(y, "Einführung",
        "Der Rundgang durch alle Bereiche des Addons — in Kapiteln, mit den"
        .. " Slash-Befehlen dazu.")

    y = Buttons(y, {
        { text = "Einführung erneut ansehen",
          tooltip = "Der vollständige Rundgang, wie beim ersten Login (/wc tour).",
          onClick = function()
              if WeintCodex.Onboarding and WeintCodex.Onboarding.ShowTour then
                  WeintCodex.Onboarding.ShowTour()
              end
          end },
        { text = "Was ist neu in " .. (WeintCodex.Version or "?") .. "?",
          tooltip = "Der Changelog-Eintrag dieser Version.",
          onClick = function()
              local data = WeintCodex_ChangelogData
              if not (data and data[1] and WeintCodex.Onboarding
                      and WeintCodex.Onboarding.ShowChangelog) then
                  Say("Für diese Version ist kein Changelog hinterlegt.")
                  return
              end
              -- Gesucht ist der Eintrag DIESER Fassung, nicht der oberste:
              -- die Liste ist zwar neueste-zuerst, aber wenn jemand das
              -- Addon eine Version zurueckdreht, waere der oberste ein
              -- Changelog fuer etwas, das gar nicht installiert ist.
              local entry = data[1]
              for _, e in ipairs(data) do
                  if e.version == WeintCodex.Version then entry = e break end
              end
              WeintCodex.Onboarding.ShowChangelog({ entry })
          end },
    })

    return y
end

local function ViewDiagnose(y)
    y = Group(y, "Diagnose",
        "Diese Knöpfe schreiben ihre Ausgabe in den Chat. Sie sind für"
        .. " Fehlermeldungen gedacht: wenn eine Zeile im Addon etwas"
        .. " Falsches behauptet, ist das die Ausgabe, aus der sich das"
        .. " korrigieren lässt.")

    y = Buttons(y, {
        { text = "Ausrüstung im Chat ausgeben",
          tooltip = "Je Platz: was angelegt ist, welche Gegenstandsstufe der"
              .. " Client meldet und ob er die Frage überhaupt beantwortet"
              .. " hat.",
          onClick = function()
              local CH = WeintCodex.Charakter
              if not (CH and CH.Snapshot) then
                  Say("Charaktermodul nicht bereit.")
                  return
              end

              local snapshot = CH.Snapshot()
              if not snapshot then
                  -- Das ist die wichtigste Ausgabe dieser Seite: sie
                  -- unterscheidet "der Client schweigt" von "es ist
                  -- nichts angelegt".
                  Say("Der Client hat auf die Ausrüstungsfrage nicht"
                      .. " geantwortet. Das heißt NICHT, dass nichts"
                      .. " angelegt ist.")
                  return
              end

              Say("Spezialisierung: "
                  .. (snapshot.specDisplay or "nicht ermittelbar")
                  .. "  (" .. (snapshot.specKey or "-") .. ")")

              for _, slot in ipairs(snapshot.slots) do
                  print("  " .. slot.name .. ": "
                      .. (slot.link or "|cff8A8A98leer|r")
                      .. "  "
                      .. (slot.itemLevel
                          and ("ilvl " .. slot.itemLevel)
                          or "|cff5F5F6Bilvl unbekannt|r")
                      .. (slot.broken and "  |cffF0A63Adefekt|r" or ""))
              end
          end },

        { text = "Gespeicherte IDs ausgeben",
          tooltip = "Welche Schlachtzug-IDs der Server für diesen Charakter"
              .. " meldet und wie sie den Einträgen aus data/raids.lua"
              .. " zugeordnet werden.",
          onClick = function()
              local ET = WeintCodex.EncounterTracking
              if not (ET and ET.SavedLockouts) then
                  Say("Fortschrittsmodul nicht bereit.")
                  return
              end

              local locks = ET.SavedLockouts()
              local count = 0

              for raidId, info in pairs(locks) do
                  count = count + 1
                  print("  " .. raidId .. ": " .. tostring(info.name)
                      .. "  " .. tostring(info.difficulty or "?")
                      .. "  noch " .. math.floor((info.reset or 0) / 3600)
                      .. " h")
              end

              if count == 0 then
                  -- Vor dem 09.12.2026 ist das der Normalfall und
                  -- kein Befund: geschlossene Schlachtzuege vergeben
                  -- keine IDs.
                  Say("Keine gespeicherte Schlachtzug-ID. Solange die"
                      .. " Schlachtzuege nicht geoeffnet haben, ist das"
                      .. " der Normalfall.")
              end
          end },
    })

    y = Spacer(y, 8)
    y = Group(y, "Spieldaten",
        "Was WeintCodex über Forever weiß — und was nicht.")

    local bosses = WeintCodex.RaidData and WeintCodex.RaidData.KnownBossCount()
    local state  = (WeintCodex.RaidData and WeintCodex.RaidData.BossListState
        and WeintCodex.RaidData.BossListState()) or "none"

    y = Info(y, "Schlachtzüge",
        tostring(#((WeintCodex.RaidData and WeintCodex.RaidData.All()) or {})))

    y = Info(y, "Dungeons",
        tostring(#((WeintCodex.DungeonData and WeintCodex.DungeonData.All()) or {})))

    -- Ausdrücklich ein Text und keine Null: "noch nicht veröffentlicht"
    -- ist die Auskunft, eine 0 wäre eine Behauptung. Und eine Zahl
    -- allein wäre hier inzwischen auch eine: die Listen stammen aus
    -- dem Beta-Client, also steht der Vorbehalt in derselben Zeile.
    local bossValue
    if not bosses then
        bossValue = WeintCodex.ColorText("textDim", "noch nicht veröffentlicht")
    elseif state == "confirmed" then
        bossValue = tostring(bosses)
    else
        bossValue = bosses .. " "
            .. WeintCodex.ColorText("textDim", "(vorläufig)")
    end
    y = Info(y, "Bosse", bossValue)

    -- Die Dungeonbosse stehen getrennt, weil sie einen anderen Zustand
    -- haben: zu ihnen liegt nichts vor, auch nicht vorläufig.
    local dungeonBosses = WeintCodex.DungeonData
        and WeintCodex.DungeonData.KnownBossCount()
    y = Info(y, "Dungeonbosse",
        dungeonBosses and tostring(dungeonBosses)
            or WeintCodex.ColorText("textDim", "noch nicht veröffentlicht"))

    y = Info(y, "Spezialisierungen",
        tostring(#(WeintCodex_Specs or {})))

    y = Note(y, "Die Bosslisten der Schlachtzüge stammen aus dem"
        .. " Beta-Client und sind von Blizzard nicht bestätigt — Namen"
        .. " und Reihenfolge können sich bis zum Erscheinen ändern. Zu"
        .. " den Dungeonbossen und zu Onyxias Hort liegt nichts vor;"
        .. " WeintCodex trägt sie nach und erfindet sie bis dahin"
        .. " nicht. Was eine Rolle an einem Boss zu tun hat, weiß das"
        .. " Addon nur, wenn der Bot es geliefert hat. Verzauberungen,"
        .. " Sockel, Umschmieden, Simmen und WeakAuras gibt es in"
        .. " dieser Fassung gar nicht.", "textDim")

    return y
end

--------------------------------------------------
-- Abschnitt: Zugriff & Daten
--------------------------------------------------

local function ViewAccess(y)
    local A = WeintCodex.Access

    y = Group(y, "Zugriffsprofil",
        "Das Profil sorgt dafür, dass ein Client die Daten genau einer"
        .. " Community führt und niemand eine Oberfläche voller Zahlen sieht,"
        .. " die ihn nichts angehen. Es ist Datenhygiene, keine"
        .. " Vertraulichkeit — die gespeicherten Daten liegen als lesbare"
        .. " Datei auf deiner Festplatte.")

    if not (A and A.HasProfile and A.HasProfile()) then
        y = Note(y, "Diesem Client wurde noch kein Profil zugestellt. Er"
            .. " verhält sich damit, als wäre alles freigegeben — das ist so"
            .. " gewollt.", "textMuted")
    else
        local profile = A.Profile() or {}
        local state, overdue = A.IsStale()
        local stateText = ({
            fresh   = WeintCodex.ColorText("success", "aktuell"),
            grace   = WeintCodex.ColorText("warning", "läuft ab, " .. tostring(overdue) .. " Tag(e) fällig"),
            expired = WeintCodex.ColorText("danger",  "abgelaufen, nur noch lesbar"),
            skew    = WeintCodex.ColorText("warning", "Systemzeit weicht ab"),
        })[state] or tostring(state)

        y = Info(y, "Community", A.CommunityName() or "unbekannt")
        y = Info(y, "Rang", WeintCodex.ColorText(A.TierColor(), A.TierLabel() or "?"))
        y = Info(y, "Zustand", stateText)
        y = Info(y, "Companion", tostring(profile.companionVersion or "?"))

        local rejected = A.RejectionCount and A.RejectionCount() or 0
        if rejected > 0 then
            y = Info(y, "Verworfen",
                rejected .. " Nachricht(en) einer anderen Community", "warning")
        end
        y = Spacer(y, 6)
    end

    y = Buttons(y, {
        { text = "Profil im Chat ausgeben",
          tooltip = "/wc access — Rang, Gültigkeit und jede einzelne Freigabe.",
          onClick = function()
              if A and A.Print then A.Print() end
          end },
    })

    if A and A.HasProfile and A.HasProfile() then
        y = Spacer(y, 6)
        y = Note(y, "Das Aufheben der Verknüpfung löscht zusätzlich die"
            .. " gildeninternen Daten dieses Clients (Rosterlisten,"
            .. " Materialien, Taktiken). Ohne das lägen sie noch da, wenn"
            .. " der Client sich bei einer anderen Gilde neu verknüpft —"
            .. " genau die Vermischung, die dieses System verhindern soll.",
            "textDim")

        local defs
        defs = {
            { text = "Verknüpfung aufheben", kind = "danger",
              onClick = function()
                  if not resetArmed then
                      resetArmed = true
                      if defs[1].frame then
                          defs[1].frame:SetText("Wirklich aufheben? Erneut klicken")
                      end
                      return
                  end
                  resetArmed = false
                  A.Reset(true)
              end },
        }
        y = Buttons(y, defs)
    end

    y = Spacer(y, 8)
    y = Group(y, "Companion-Brücke",
        "Addon und Companion tauschen sich nur über eine Datei aus. Die"
        .. " Zustellung wird beim Anmelden gelesen — was hier steht, ist"
        .. " immer der Stand der letzten Lieferung, nie eine Live-Verbindung.")

    local inbox = _G.WeintCompanionInboxDB
    y = Info(y, "Letzte Lieferung von",
        inbox and inbox.companionVersion
            and ("Companion " .. tostring(inbox.companionVersion))
            or WeintCodex.ColorText("textDim", "keine Lieferung"))

    local queued = (WeintCodex.Companion and WeintCodex.Companion.GetQueueSize
        and WeintCodex.Companion.GetQueueSize()) or 0
    y = Info(y, "Ausgehende Nachrichten", tostring(queued),
        queued > 0 and "warning" or "textNormal")

    return y
end

--------------------------------------------------
-- Seitenaufbau
--------------------------------------------------

local VIEWS = {
    { key = "fenster",  label = "Fenster & Ansicht", title = "Fenster & Ansicht",
      sub = "Wie sich das Addon verhält, bevor es irgendetwas anzeigt.",
      render = ViewWindow },
    { key = "diagnose", label = "Diagnose",          title = "Diagnose",
      sub = "Ausgaben für Fehlermeldungen, und was das Addon über Forever weiß.",
      render = ViewDiagnose },
    { key = "zugriff",  label = "Zugriff & Daten",   title = "Zugriff & Daten",
      sub = "Zugriffsprofil und Zustand der Companion-Brücke.",
      render = ViewAccess },
}

local function ViewByKey(key)
    for _, v in ipairs(VIEWS) do
        if v.key == key then return v end
    end
    return VIEWS[1]
end

local function ClearBody()
    for _, w in ipairs(widgets) do w:Hide() end
    wipe(widgets)
    wipe(toggleRows)
end

-- Seitengeruest genau einmal. WoW gibt Frames nie wieder frei, und diese
-- Seite wird bei jedem Reiterwechsel neu gezeichnet - ein frischer
-- Bildlaufrahmen je Klick waere eine Sammlung, die nur waechst.
local function EnsurePage()
    if pageFrame then return end

    local cp = WeintCodex.ContentPanel
    if not cp then return end

    pageFrame = CreateFrame("Frame", nil, cp)
    pageFrame:SetAllPoints(cp)

    pageHead = WeintCodex.PageHead(pageFrame, {
        eyebrow = "System",
        title   = "Einstellungen", titleSize = 20,
        sub     = "", subSize = 10,
        x = PAD_X, y = 14, height = HEAD_H,
    })

    -- Bildlauffeld: die Groesse kommt aus den Ankern, nicht aus einer
    -- Messung. ContentPanel wird beim Aufbau der Seite gerade erst um die
    -- Reiterleiste eingerueckt; wer davor misst, legt die Seite zu gross an
    -- (dieselbe Falle wie beim Detailbereich, siehe CLAUDE.md).
    -- CreateScrollArea verlangt Pixelmasse, also wird danach umgehaengt -
    -- die schlanke Leiste und das Mausrad bleiben so erhalten.
    local sf, inner = WeintCodex.CreateScrollArea(pageFrame, PAD_X, -(14 + HEAD_H),
        100, 100, true)
    sf:ClearAllPoints()
    sf:SetPoint("TOPLEFT",     pageFrame, "TOPLEFT",      PAD_X, -(14 + HEAD_H))
    sf:SetPoint("BOTTOMRIGHT", pageFrame, "BOTTOMRIGHT", -PAD_X, 16)
    sf:SetScript("OnSizeChanged", function(self, w)
        if w and w > 20 then inner:SetWidth(w - 10) end
    end)
    -- Ohne das blendet ScrollFrame_OnScrollRangeChanged die Leiste bei
    -- Bildlaufweite 0 wieder ein (dieselbe Stelle wie in core/onboarding.lua).
    sf.scrollBarHideable = true

    scroller, body = sf, inner
end

local function Render()
    EnsurePage()
    if not (pageFrame and body) then return end

    local view = ViewByKey(currentView)

    -- Jeder Neuaufbau entschaerft die Bestaetigung wieder. Ohne das bliebe
    -- `resetArmed` ueber einen Reiterwechsel hinweg stehen, und der frisch
    -- gezeichnete Knopf - der wieder "Verknuepfung aufheben" liest - wuerde
    -- beim ERSTEN Klick loeschen.
    resetArmed = false

    ClearBody()
    pageFrame:Show()
    scroller:SetVerticalScroll(0)

    WeintCodex.SetBreadcrumb("Einstellungen", view.label)
    pageHead.Title:SetText(view.title)
    pageHead.Sub:SetText(view.sub or "")

    local endY = view.render(-4)
    local needed = math.max(1, -endY + 20)
    body:SetHeight(needed)

    -- Eine Leiste ohne Bildlauf ist ein Bedienelement, das nichts tut
    -- (dieselbe Regel wie in core/onboarding.lua).
    local bar = scroller.WCScrollBar
    if bar then
        if needed > (scroller:GetHeight() or 0) then bar:Show() else bar:Hide() end
    end
end

--------------------------------------------------
-- Einstieg
--------------------------------------------------

function WeintCodex.Settings.Show()
    resetArmed = false

    local items, index = {}, 1
    for i, v in ipairs(VIEWS) do
        items[i] = {
            label = v.label,
            onClick = function()
                currentView = v.key
                Render()
            end,
        }
        if v.key == currentView then index = i end
    end

    WeintCodex.Navigation.BuildSidebar("Einstellungen", items)

    -- Die zuletzt gewaehlte Seite wieder oeffnen statt der ersten: wer
    -- gerade am Alarm schraubt und zwischendurch woanders nachsieht, ist
    -- beim Zurueckkommen wieder dort gemeint.
    WeintCodex.Navigation.ActivateIndex(index)
end

-- Neu zeichnen, ohne die Reiterleiste anzufassen: eine Schaltflaeche, deren
-- Beschriftung von einem Zustand abhaengt ("Weggeklicktes vergessen (3)",
-- "Helfer schliessen"), muss nach dem Klick neu gesetzt werden.
function WeintCodex.Settings.Refresh()
    if suppressRefresh then return end
    if WeintCodex.Navigation.CurrentTab
       and WeintCodex.Navigation.CurrentTab() ~= "settings" then
        return
    end
    Render()
end
