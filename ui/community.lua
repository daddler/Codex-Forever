--------------------------------------------------
-- WeintCodex :: Oberflaeche - Gilde & Communitys (6.7.8.0)
--------------------------------------------------
-- Gilde & Communitys (CommunitiesFrame) in der ruhigen
-- Informationsoberflaeche, in GOLD (S.CALM): die Gilde gehoert nicht zur
-- Klasse. Kein Register - drei Spalten nebeneinander -, aber dieselben
-- Bausteine wie Berufe und Zauberbuch:
--
--   Grund     Vignette und neutrales Licht; der Schein der Klasse oben ist
--             in einem Fenster in Gold aus (W.HoldGlow).
--   Spalten   links die Liste (Gilde, Communitys, "beitreten oder
--             gruenden"), in der Mitte der Chat samt Eingabezeile, rechts
--             die Mitgliederliste - jede auf der angehobenen Flaeche des
--             Registers mit weichem Schatten und feiner Kante in Gold. Eine
--             Spalte, die das Spiel ausblendet (andere Ansicht), nimmt ihre
--             Flaeche mit.
--   Akzent    Gold am gewaehlten Eintrag links (W.NavEntry) und am
--             gewaehlten Seitenreiter (SkinSideTabs) - ueber den Stil des
--             Fensters, keine Klassenfarbe daneben.
--
-- Unveraendert: Namen im Chat und in der Mitgliederliste in den Farben des
-- Spiels (Klasse, Kanal - sie sagen etwas), Zeiten, Wappen der Gilde,
-- Kronen, "8/22 online", Auswahl des Kanals, Knoepfe. Die Mitgliederliste
-- behaelt innen ihren Grund (6.6.3.3, Beta-Test: "im Normalzustand") -
-- die Flaeche liegt darunter, zu sehen sind Schatten und Kante.
--
-- GEMESSEN (6.7.7.0, /wcui fenster): CommunitiesFrame mit .MemberList
-- (.InsetFrame.NineSlice, Zeilen .ScrollBox.ScrollTarget.<Zeile>),
-- .ChatEditBox, .StreamDropdown, .ChatTab, .PortraitOverlay; Liste links
-- CommunitiesFrameCommunitiesList (.ScrollBox.ScrollTarget.<Eintrag>,
-- communities-guildbanner-*).
-- UNGEMESSEN: der Chat selbst (.Chat wie im Quelltext des Spiels, sonst
-- .ChatFrame/.MessageFrame) - /wcui fenster nennt, was gefunden wurde.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UICommunity = {}

local CO = WeintCodex.UICommunity
local GC = WeintCodex.GameColors
local W = WeintCodex.UIWindows
local S = WeintCodex.UIStyle
local RG = WeintCodex.UIRegister

local Visible, IsFrame = RG.Visible, RG.IsFrame
local K = WeintCodex.UIKit

CO.LABEL = "Gilde & Communitys"
CO.HOST = "CommunitiesFrame"
CO.STYLE = S.CALM
CO.VIGNETTE, CO.VIGNETTE_SIZE = 0.35, 48
CO.LIGHT_HEIGHT = 140
CO.PAD = 6                  -- Flaeche so weit ueber die Spalte hinaus
CO.SHADOW_PAD = 14
CO.EDGE = 0.45              -- Kante oben in Gold
CO.CHAT_KEYS = { "Chat", "ChatFrame", "MessageFrame" }
-- Eingabezeile (6.10.4.2, gemessen 05.10.2026): .ChatEditBox mit Left/Mid/
-- Right (375507, 389190, 375508) - der helle runde Rahmen des Spiels. Weg,
-- das Feld flach wie die Felder der Post (CP.Flat).
CO.EDIT_PARTS = { "Left", "Mid", "Middle", "Right" }
CO.EDIT_ALPHA = 0.55
CO.fields = setmetatable({}, { __mode = "k" })
-- Mitgliederliste (6.10.4.3, Beta-Test: "die Gildenmitgliederliste etwas
-- besser einarbeiten"). Gemessen 05.10.2026: grauer Rand des Spiels
-- (MemberList.InsetFrame.NineSlice, "UI-Frame-Inner*"), Leder hinter dem
-- Bildlauf (ScrollBar.Background, 374154) und je Zeile zwei Baender
-- (410251, 131128). Weg - die Liste steht auf ihrer Spalte wie der Chat.
-- NICHT dunkler (6.6.3.3: "etwas verdunkelt, gern wieder im
-- Normalzustand"): keine Innenflaeche darueber, W.INSET_KEEP bleibt.
-- Rang, Anwesenheit, Sprachchat, Namen in ihren Farben und das
-- Wasserzeichen der Gilde bleiben.
CO.ROW_FILES = { [410251] = true, [131128] = true }
-- Ansicht "Mitglieder gross" (6.10.4.4, gemessen 05.10.2026, Beta-Test:
-- "ein hellerer Rand"): die Spaltenkoepfe (MemberList.ColumnDisplay)
-- tragen einen zweiten grauen Rahmen (InsetBorder*, "UI-Frame-Inner*")
-- und Marmor (Background, 374155). Und der Rahmen der Liste
-- (InsetFrame.NineSlice) jetzt Bild fuer Bild - nur der Rahmen auf 0
-- reichte nicht sicher.
CO.COLUMN_PARTS = { "Background", "InsetBorderTop", "InsetBorderBottom", "InsetBorderLeft", "InsetBorderRight",
                    "InsetBorderTopLeft", "InsetBorderTopRight", "InsetBorderBottomLeft", "InsetBorderBottomRight" }
CO.rows = setmetatable({}, { __mode = "k" })

S.SCOPES[CO.HOST] = CO.STYLE
W.HOSTED[CO.HOST] = W.HOSTED[CO.HOST] or {}
table.insert(W.HOSTED[CO.HOST], CO)

local frames = setmetatable({}, { __mode = "k" })
CO.frames = frames

-- Die drei Spalten: Name im Bericht, Rahmen, rechte untere Ecke der Flaeche.
function CO.List(f)
    local l = f.CommunitiesList
    if not IsFrame(l) then l = _G.CommunitiesFrameCommunitiesList end
    return IsFrame(l) and l or nil
end

function CO.Chat(f)
    for _, key in ipairs(CO.CHAT_KEYS) do
        local c = f[key]
        if IsFrame(c) then return c end
    end
    return nil
end

function CO.Members(f)
    local m = f.MemberList
    return IsFrame(m) and m or nil
end

local function Gone(t)
    if IsFrame(t) and t.SetAlpha and K.Plain(t:GetAlpha()) ~= 0 then t:SetAlpha(0) end
end

-- Je Durchlauf: die Zeilen werden beim Blaettern weiterverwendet. Ohne
-- neue Tabelle (W.Regions/W.Children mit Kennung).
function CO.SkinMembers(m)
    local inset = m.InsetFrame
    if IsFrame(inset) and IsFrame(inset.NineSlice) then
        Gone(inset.NineSlice)
        for _, r in ipairs(W.Regions(inset.NineSlice, "coNine", 0)) do Gone(r) end
    end
    local cd = m.ColumnDisplay
    if IsFrame(cd) then
        for _, key in ipairs(CO.COLUMN_PARTS) do Gone(cd[key]) end
    end
    local bar = m.ScrollBar
    if IsFrame(bar) then Gone(bar.Background) end
    local box = m.ScrollBox
    local target = IsFrame(box) and box.ScrollTarget or nil
    if not IsFrame(target) then return 0 end
    local CP = WeintCodex.UICalmParts
    local n = 0
    for _, row in ipairs(W.Children(target, "coRows", 0)) do
        if IsFrame(row) then
            for _, r in ipairs(W.Regions(row, "coRow", 1)) do
                local id = CP and CP.FileOf(r)
                if id and CO.ROW_FILES[id] then
                    Gone(r)
                    if not CO.rows[r] then CO.rows[r] = true end
                    n = n + 1
                end
            end
        end
    end
    return n
end

local function Column(f, anchor, corner, accent)
    local c = GC.surfaceRaised
    local col = { anchor = anchor }
    col.body = S.SoftPanel(f, anchor, c, c[4], CO.PAD, -4, corner)
    col.shadow = S.Shadow(f, anchor, CO.PAD + CO.SHADOW_PAD, -5, corner)
    col.edge = S.Under(S.Divider(f, accent, CO.EDGE, 0), -3)
    S.PlaceTop(col.edge, anchor, 12, CO.PAD)
    col.parts = { col.body, col.shadow, col.edge.l, col.edge.r }
    col.on = true
    return col
end

local function ShowCol(col, on)
    if col.on == on then return end
    col.on = on
    for _, t in ipairs(col.parts) do t:SetShown(on) end
end

local function Build(f)
    local d = { parts = {}, cols = {}, names = {} }
    local v = S.Vignette(f, f, CO.VIGNETTE, CO.VIGNETTE_SIZE, -6)
    for _, side in ipairs(S.SIDES) do d.parts[#d.parts + 1] = v[side] end
    d.vignette = v
    local l = GC.atmosLight
    d.light = S.TopLight(f, f, l, l[4], CO.LIGHT_HEIGHT, -5)
    d.parts[#d.parts + 1] = d.light
    frames[f] = d
    return d
end

-- Spalten spaet anlegen: die Liste und der Chat entstehen erst, wenn das
-- Spiel sie braucht.
local function Ensure(f, d, key, anchor, corner, accent)
    if d.cols[key] or not anchor then return end
    d.cols[key] = Column(f, anchor, corner, accent)
    d.names[#d.names + 1] = key
end

function CO.Update(f)
    local d = frames[f] or Build(f)
    local accent = S.Accent(CO.STYLE.accent)
    local chat = CO.Chat(f)
    local edit = f.ChatEditBox
    Ensure(f, d, "Liste", CO.List(f), nil, accent)
    Ensure(f, d, "Chat", chat, IsFrame(edit) and edit or nil, accent)
    Ensure(f, d, "Mitglieder", CO.Members(f), nil, accent)
    local members = CO.Members(f)
    d.rows = members and CO.SkinMembers(members) or 0
    d.edit = false
    if IsFrame(edit) then
        for _, key in ipairs(CO.EDIT_PARTS) do
            local t = edit[key]
            if IsFrame(t) and t.SetAlpha then W.Hide(t) end
        end
        -- Laedt nach diesem Modul (ui/calmparts.lua) - erst im Durchlauf da.
        local CP = WeintCodex.UICalmParts
        if CP and CP.Flat then CP.Flat(CO.fields, edit, CO.EDIT_ALPHA) end
        d.edit = CO.fields[edit] ~= nil
    end
    -- Jede Flaeche folgt ihrer Spalte (andere Ansicht: Mitglieder gross,
    -- Gildeninfo ...).
    for _, key in ipairs(d.names) do
        local col = d.cols[key]
        ShowCol(col, Visible(col.anchor))
    end
    return d
end

function CO.Report(f, out)
    local d = frames[f]
    if not d then return out end
    local parts = ""
    for _, key in ipairs({ "Liste", "Chat", "Mitglieder" }) do
        local col = d.cols[key]
        parts = parts .. (parts == "" and "" or " · ") .. key .. " "
            .. (col and (col.on and "Fläche" or "Fläche (Spalte zu)") or "FEHLT")
    end
    out[#out + 1] = string.format("   %s (Stil %s): %s · Eingabe %s · Zeilen ohne Band %d", CO.LABEL, CO.STYLE.name, parts,
        d.edit and "flach" or "nicht gefunden", d.rows or 0)
    return out
end
