--------------------------------------------------
-- WeintCodex :: Rollen-Baustein (Tank, Heiler, Schadensausteiler)
--
-- EINE Darstellung der drei Rollen, von der Dungeonseite und der
-- Schlachtzugseite gemeinsam benutzt. Zwei Fassungen desselben
-- Bausteins wären zwei Gelegenheiten, "nicht bekannt" beim nächsten
-- Mal als "0" zu schreiben.
--
-- Der Baustein zeigt drei Bestände, und er hält sie sichtbar
-- auseinander (siehe data/roles.lua, wo sie herkommen):
--
--   PLÄTZE       Wie viele von jeder Rolle in die Gruppe gehören.
--                Für Fünfergruppen bekannt, für Schlachtzüge nicht.
--   BÄUME        Welche Spezialisierungen die Rolle tragen können.
--                Vollständig bekannt, aus data/specs.lua.
--   TIPPS        Was die Rolle an einem Boss zu tun hat. Für KEINEN
--                Kampf in Forever bekannt - ausser der Discord-Bot
--                hat etwas geliefert (WCIMPORT:BOSS).
--
-- Der dritte Bestand ist der, an dem sich diese Fassung entscheidet.
-- Es wäre ein Leichtes, hier "Tank: Boss vom Raid wegdrehen" und
-- ähnliche Allgemeinplätze hinzuschreiben; sie würden zu jedem Spiel
-- passen und zu keinem Kampf in Forever. Statt dessen steht da, dass
-- nichts da ist, und woher etwas käme.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.RolePanel = {}

local C = WeintCodex.Colors

local ROW_H   = 34
local CARD_TOP = 46

--------------------------------------------------
-- Die Karte "Aufstellung" im Seitenkörper
--------------------------------------------------
-- Drei Zeilen, eine je Rolle. Zeilen und nicht Spalten, weil die
-- Breite des Inhaltsbereichs mit dem Fenster und mit dem
-- Detailbereich wandert - eine Drittelung müsste dafür rechnen, eine
-- Zeile nicht.
--
-- Rückgabe: die Karte und ihre Höhe.

function WeintCodex.RolePanel.Card(parent, instance)
    local frame = WeintCodex.Roles.Frame(instance and instance.size)
    local height = CARD_TOP + 3 * ROW_H + 14

    local card = WeintCodex.CreateSurface(parent, {
        height = height, tone = "plain", radius = 14, backdrop = "bgDark",
    })

    local title = card:CreateFontString(nil, "OVERLAY")
    title:SetFont(WeintCodex.Fonts.sansSemi, 14, "")
    title:SetPoint("TOPLEFT", card, "TOPLEFT", 20, -16)
    title:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3])
    title:SetText("Aufstellung")

    -- Der Rahmen als Ganzes, rechts im Kartenkopf. Steht er nicht
    -- fest, steht das da - nicht eine Aufstellung aus einem anderen
    -- Spiel.
    local frameLbl = WeintCodex.Eyebrow(card,
        WeintCodex.Roles.FrameLabel(instance and instance.size)
            or "Verteilung noch nicht bekannt",
        { color = frame and "textMuted" or "textFaint", size = 10, justify = "RIGHT" })
    frameLbl:SetPoint("TOPRIGHT", card, "TOPRIGHT", -20, -18)

    local y = -CARD_TOP

    for _, role in ipairs(WeintCodex.Roles.ORDER) do
        local row = CreateFrame("Frame", nil, card)
        row:SetHeight(ROW_H)
        row:SetPoint("TOPLEFT",  card, "TOPLEFT",  20, y)
        row:SetPoint("TOPRIGHT", card, "TOPRIGHT", -20, y)

        local name = WeintCodex.Label(row, WeintCodex.Roles.Label(role),
            { color = WeintCodex.Roles.Tone(role), size = 13 })
        name:SetPoint("LEFT", row, "LEFT", 0, 0)
        name:SetWidth(150)

        -- Die Bäume: eine vollständige Auskunft, deshalb eine Zahl.
        local specs = WeintCodex.Roles.SpecCount(role)
        local specLbl = WeintCodex.Label(row,
            specs .. " Talentbäume tragen die Rolle",
            { color = "textDim", size = 12 })
        specLbl:SetPoint("LEFT", name, "RIGHT", 12, 0)

        -- Die Plätze: bekannt oder ausdrücklich nicht.
        local slots = frame and frame[role]
        local mark = row:CreateFontString(nil, "OVERLAY")
        mark:SetFont(WeintCodex.Fonts.monoBold, 10, "")
        mark:SetPoint("RIGHT", row, "RIGHT", 0, 0)
        if slots then
            mark:SetTextColor(C.textNormal[1], C.textNormal[2], C.textNormal[3])
            mark:SetText(WeintCodex.Spaced(slots .. (slots == 1 and " PLATZ" or " PLÄTZE")))
        else
            mark:SetTextColor(C.textFaint[1], C.textFaint[2], C.textFaint[3])
            mark:SetText(WeintCodex.Spaced("PLÄTZE UNBEKANNT"))
        end

        WeintCodex.RowLine(row, -(ROW_H - 1))
        y = y - ROW_H
    end

    return card, height
end

--------------------------------------------------
-- Detailbereich: die Rollen einer Instanz
--------------------------------------------------
-- Was sich über die Rollen sagen lässt, OHNE einen bestimmten Boss zu
-- kennen: die Verteilung und die Bäume. Mehr ist es nicht, und das
-- steht auch so da.

function WeintCodex.RolePanel.InstanceBlocks(instance)
    local blocks = {}
    local size   = instance and instance.size
    local frame  = WeintCodex.Roles.Frame(size)

    blocks[#blocks + 1] = { type = "header", text = "Rollen" }

    if frame then
        blocks[#blocks + 1] = { type = "text",
            text = "Eine Fünfergruppe ist für einen Tank, einen Heiler und "
                .. "drei Schadensausteiler gebaut. Das gilt auch in Forever.",
            color = "textDim", size = 10 }
    else
        -- Der ehrliche Leerzustand, und zwar mit Begründung: eine
        -- Verteilung ohne Bossmechaniken wäre geraten.
        blocks[#blocks + 1] = { type = "text",
            text = "Wie viele Tanks und Heiler " .. (instance and instance.name or "dieser Schlachtzug")
                .. " braucht, entscheiden seine Bosse – und deren Mechaniken "
                .. "sind nicht veröffentlicht. WeintCodex trägt die Verteilung "
                .. "nach, sobald sie feststeht.",
            color = "textDim", size = 10 }
    end

    for _, role in ipairs(WeintCodex.Roles.ORDER) do
        local entries = WeintCodex.Roles.Specs(role)
        local lines   = {}
        for _, entry in ipairs(entries) do
            local spec = entry.spec
            local line = (WeintCodex.Names and WeintCodex.Names.ClassLabel
                    and WeintCodex.Names.ClassLabel(spec.class))
                or spec.class
            line = line .. " · " .. spec.name
            if entry.formDependent then
                line = line .. " (je nach Gestalt)"
            end
            lines[#lines + 1] = line
        end

        local slots = frame and frame[role]
        blocks[#blocks + 1] = { type = "card",
            title    = WeintCodex.Roles.Label(role),
            subtitle = slots and (slots .. (slots == 1 and " Platz" or " Plätze"))
                or "Plätze noch nicht bekannt",
            lines    = lines,
        }
    end

    return blocks
end

--------------------------------------------------
-- Detailbereich: die Rollen an EINEM Boss
--------------------------------------------------
-- Hier und nur hier stehen Taktikhinweise - und ausschliesslich die,
-- die der Discord-Bot geliefert hat. Die vier möglichen Zustände sind
-- vier verschiedene Auskünfte, und sie dürfen nicht zu einer
-- zusammenfallen:
--
--   gesperrt   Das Zugriffsprofil lässt die gildeninternen
--              Taktiknotizen nicht zu (core/access.lua).
--   nichts     Zu diesem Boss wurde nie etwas importiert.
--   leer       Der Bot kennt den Boss, hat zu DIESER Rolle aber
--              nichts gesagt.
--   Tipps      Es steht etwas da.

function WeintCodex.RolePanel.BossBlocks(instance, boss)
    local blocks = {}
    local bossName = boss and boss.name or "?"

    blocks[#blocks + 1] = { type = "header", text = "Boss" }
    blocks[#blocks + 1] = { type = "rows", rows = {
        { label = "Name",  value = bossName },
        { label = "Platz", value = (boss and boss.order or "?") .. ". Pull" },
        { label = "Instanz", value = instance and instance.name or "—" },
    }}

    -- Die Herkunft der Bossliste gehört an den Boss, nicht nur an die
    -- Instanz: wer hier einen Namen liest, soll wissen, wie fest er
    -- steht.
    --
    -- BossSourceLabel prüft nur die Form (`bosses`, `bossSource`) und
    -- funktioniert deshalb auf jeder Instanz - auch auf einem Dungeon,
    -- sobald dessen Liste einmal da ist. Es steht in RaidData, weil es
    -- dort entstanden ist, nicht weil es auf Schlachtzüge beschränkt
    -- wäre.
    local sourceLabel = instance and WeintCodex.RaidData
        and WeintCodex.RaidData.BossSourceLabel
        and WeintCodex.RaidData.BossSourceLabel(instance)
    if sourceLabel then
        blocks[#blocks + 1] = { type = "text",
            text = sourceLabel .. ". Namen und Reihenfolge sind von Blizzard "
                .. "nicht bestätigt und können sich bis zum Erscheinen ändern.",
            color = "textFaint", size = 10 }
    end

    blocks[#blocks + 1] = { type = "divider" }
    blocks[#blocks + 1] = { type = "header", text = "Was die Rollen tun" }

    if not WeintCodex.Roles.TipsAllowed() then
        blocks[#blocks + 1] = { type = "text",
            text = "Die Rollen-Tipps des Bots sind gildeninterne Taktiknotizen "
                .. "und für dein Zugriffsprofil gesperrt.",
            color = "textDim", size = 10 }
        return blocks
    end

    local anyTips = WeintCodex.Roles.HasTips(bossName)

    if not anyTips then
        blocks[#blocks + 1] = { type = "text",
            text = "Zu " .. bossName .. " liegt nichts vor. Die Mechaniken der "
                .. "Kämpfe in Forever sind nicht veröffentlicht – WeintCodex "
                .. "denkt sich keine aus.",
            color = "textDim", size = 10 }
        blocks[#blocks + 1] = { type = "card",
            title    = "Woher Tipps kommen",
            subtitle = "Discord-Bot",
            lines    = {
                "Der WeintCodex-Bot schickt Taktiknotizen je",
                "Rolle als WCIMPORT:BOSS-Zeile. Einfügen unter",
                "Import – danach stehen sie hier.",
            },
        }
        return blocks
    end

    for _, role in ipairs(WeintCodex.Roles.ORDER) do
        local tips = WeintCodex.Roles.Tips(bossName, role)

        blocks[#blocks + 1] = { type = "header", text = WeintCodex.Roles.Label(role) }

        if tips and #tips > 0 then
            for _, tip in ipairs(tips) do
                blocks[#blocks + 1] = { type = "text", text = "• " .. tip,
                    color = "textMuted", size = 11 }
            end
        else
            -- "Der Bot hat zu dieser Rolle nichts gesagt" ist eine
            -- Auskunft. Eine leere Stelle wäre keine.
            blocks[#blocks + 1] = { type = "text",
                text = "Der Bot hat zu dieser Rolle nichts geliefert.",
                color = "textFaint", size = 10 }
        end
    end

    return blocks
end

--------------------------------------------------
-- Eine Zeile für den Seitenkopf: wie viele Bosse Tipps tragen
--------------------------------------------------
-- Gibt nil zurück, wenn die Bossliste leer ist. "0 von 0" wäre keine
-- leere Auskunft, sondern eine falsche.

function WeintCodex.RolePanel.TipsSummary(instance)
    if type(instance) ~= "table" then return nil end
    local total = #(instance.bosses or {})
    if total == 0 then return nil end

    if not WeintCodex.Roles.TipsAllowed() then
        return "Rollen-Tipps gesperrt"
    end

    local tipped = WeintCodex.Roles.TippedBossCount(instance)
    if tipped == 0 then
        return "Noch keine Rollen-Tipps importiert"
    end
    return "Rollen-Tipps zu " .. tipped .. " von " .. total .. " Bossen"
end
