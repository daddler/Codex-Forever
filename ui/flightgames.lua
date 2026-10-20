--------------------------------------------------
-- WeintCodex :: Komfort - Spiele waehrend des Flugs (6.78.0.0)
--------------------------------------------------
-- Wunsch: "waehrend der Flugzeit eine Abfrage, ob man ein Spiel spielen
-- will - Candy Crush, Mahjong, Moorhuhn. Am Ende des Fluges der Highscore,
-- und man kann ihn der Gilde mitteilen. Alles optional."
--
-- Drei eigene Spiele nach bekannten Spielideen - Namen und Bilder der
-- Vorbilder sind geschuetzte Marken und kommen hier nicht vor:
--   Juwelen     Drei gleiche in eine Reihe tauschen (Match-3).
--   Mahjong     Paare freier Steine abraeumen (Mahjong-Solitaer).
--   Huehnerjagd Ueber den Himmel flatternde Huehner anklicken.
-- Farben aus core/ui.lua (GameColors.raidMark1..8), das Huhn ist das
-- Symbol des Spiels (Interface\Icons, nichts mitgeliefert).
--
-- ABLAUF. Beim Abflug (PLAYER_CONTROL_LOST, danach UnitOnTaxi) fragt ein
-- kleines Fenster, ob und was man spielen will - "Nein" und "Nicht mehr
-- fragen" inklusive. Beim Landen (PLAYER_CONTROL_GAINED, nicht mehr
-- UnitOnTaxi) schliesst das Spiel, und ein Ergebnis nennt die Punkte des
-- Flugs und den Bestwert. "Der Gilde zeigen" schreibt eine Zeile in die
-- Chatzeile ("/g ..."), gesendet wird erst mit Enter durch den Spieler -
-- Addons duerfen nicht selbst in die Gilde schreiben (gemessen, 6.10.4.6).
-- Bestwerte kontoweit in WeintCodex_SavedData.flightGames, nie vor dem
-- Laden in eine Ersatztabelle. /wcui spiele oeffnet die Auswahl jederzeit.
--
-- Kein Takt ausser bei der Huehnerjagd, und der legt nichts je Bild an.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIFlightGames = {}

local FG = WeintCodex.UIFlightGames
local K = WeintCodex.UIKit
local C = WeintCodex.Colors
local GC = WeintCodex.GameColors
local KEY = "comfort"

FG.DEFAULTS = { flightGames = true, flightGamesShare = true }
FG.GAMES = {
    { key = "jewels",  name = "Juwelen",     hint = "Zwei Nachbarn tauschen – drei Gleiche in einer Reihe verschwinden." },
    { key = "mahjong", name = "Mahjong",     hint = "Zwei gleiche freie Steine anklicken. Frei ist ein Stein ohne Stein darauf und mit freier linker oder rechter Seite." },
    { key = "hunt",    name = "Hühnerjagd",  hint = "Hühner anklicken: Küken und Goldhuhn bringen viel, Zombiehühner brauchen zwei Treffer – Finger weg vom roten Bombenhuhn!" },
}
FG.W, FG.WIN_H = 440, 544   -- nicht FG.H: das ist die Huehnerjagd
FG.BOARD = 400
FG.HUHN = "Interface\\Icons\\Spell_Magic_PolymorphChicken"

local win, views = nil, {}
local Build   -- Fenster (weiter unten)
FG.views = views
FG.flight = { on = false, scores = {}, game = nil, to = nil }

local function Rand(n) return math.random(1, n) end

function FG.Active() return K.IsActive(KEY) and K.Get(KEY, "flightGames") ~= false end

-- Bestwerte, kontoweit. nil vor dem Laden.
function FG.Best(create)
    local sd = _G.WeintCodex_SavedData
    if type(sd) ~= "table" then return nil end
    if type(sd.flightGames) ~= "table" then
        if not create then return nil end
        sd.flightGames = { best = {} }
    end
    if type(sd.flightGames.best) ~= "table" then sd.flightGames.best = {} end
    return sd.flightGames.best
end

function FG.NameOf(key)
    for _, g in ipairs(FG.GAMES) do if g.key == key then return g.name end end
    return key
end

-- Punkte im laufenden Spiel; merkt sich je Flug das Beste je Spiel.
function FG.AddScore(n)
    local f = FG.flight
    f.points = (f.points or 0) + n
    if f.game and (f.scores[f.game] or 0) < f.points then f.scores[f.game] = f.points end
    if win and win.score then win.score:SetText(tostring(f.points) .. " Punkte") end
end

--------------------------------------------------
-- Bausteine
--------------------------------------------------

local function Button(parent, text, w, h, onClick)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(w or 120, h or 26)
    local bg = b:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(b)
    local s = C.surface2 or C.surface1
    bg:SetColorTexture(s[1], s[2], s[3], 0.95)
    b.bg = bg
    local hl = b:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints(b)
    hl:SetColorTexture(1, 1, 1, 0.08)
    b.text = K.NewText(b, 12)
    b.text:SetPoint("CENTER")
    b.text:SetText(text or "")
    if onClick then b:SetScript("OnClick", onClick) end
    return b
end
FG.Button = Button

local function View(name)
    local v = CreateFrame("Frame", nil, win)
    v:SetPoint("TOPLEFT", win, "TOPLEFT", 20, -68)
    v:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", -20, 20)
    v:Hide()
    views[name] = v
    return v
end

local function Show(name)
    for k, v in pairs(views) do v:SetShown(k == name) end
    if win.score then win.score:SetShown(name == "jewels" or name == "mahjong" or name == "hunt") end
end
FG.ShowView = Show

--------------------------------------------------
-- Juwelen (Match-3)
--------------------------------------------------

local J = { N = 8, KINDS = 6, grid = {}, cells = {}, sel = nil }
J.GEMS = { "gem1", "gem2", "gem3", "gem4", "gem5", "gem6" }
FG.J = J


-- Darstellung je Feld: Versatz (dx, dy), Groesse und Deckkraft des Steins
-- - nur die Animation aendert sie, JPaint setzt sie auf Ruhe zurueck.
local function JPlace(cell)
    cell.gem:ClearAllPoints()
    cell.gem:SetPoint("CENTER", cell, "CENTER", cell.dx or 0, cell.dy or 0)
    local s = (J.GEM or 38) * (cell.scale or 1)
    cell.gem:SetSize(s, s)
    cell.gem:SetAlpha(cell.alpha or 1)
end

local function JPaint()
    for r = 1, J.N do
        for c = 1, J.N do
            local cell, kind = J.cells[r][c], J.grid[r][c]
            -- 6.81.0.0 (Wunsch: "sollen nach Kristallen aussehen"): je Art ein
            -- eigener geschliffener Stein (media/ui/gem1..6.tga, gebaut mit
            -- .github/scripts/make_gems.py), Farbe im Bild - kein Einfaerben.
            if kind ~= 0 and cell.kind ~= kind then
                cell.gem:SetTexture(K.MEDIA .. J.GEMS[kind])
                cell.kind = kind
            end
            cell.gem:SetShown(kind ~= 0)
            cell.sel:SetShown(J.sel ~= nil and J.sel[1] == r and J.sel[2] == c)
            cell.dx, cell.dy, cell.scale, cell.alpha = 0, 0, 1, 1
            JPlace(cell)
        end
    end
end

-- Alle Steine, die in einer Dreierreihe (oder laenger) liegen.
function J.Matches(g)
    g = g or J.grid
    local hit, n = {}, 0
    local function Mark(r, c)
        local k = r * 100 + c
        if not hit[k] then hit[k] = true n = n + 1 end
    end
    for r = 1, J.N do
        for c = 1, J.N - 2 do
            local k = g[r][c]
            if k ~= 0 and g[r][c + 1] == k and g[r][c + 2] == k then Mark(r, c) Mark(r, c + 1) Mark(r, c + 2) end
        end
    end
    for c = 1, J.N do
        for r = 1, J.N - 2 do
            local k = g[r][c]
            if k ~= 0 and g[r + 1][c] == k and g[r + 2][c] == k then Mark(r, c) Mark(r + 1, c) Mark(r + 2, c) end
        end
    end
    return hit, n
end

local function Swap(r1, c1, r2, c2)
    J.grid[r1][c1], J.grid[r2][c2] = J.grid[r2][c2], J.grid[r1][c1]
end

-- Gibt es noch einen Zug?
function J.HasMove()
    for r = 1, J.N do
        for c = 1, J.N do
            for _, d in ipairs({ { 0, 1 }, { 1, 0 } }) do
                local r2, c2 = r + d[1], c + d[2]
                if r2 <= J.N and c2 <= J.N then
                    Swap(r, c, r2, c2)
                    local _, n = J.Matches()
                    Swap(r, c, r2, c2)
                    if n > 0 then return true end
                end
            end
        end
    end
    return false
end

function J.Fill()
    for r = 1, J.N do
        J.grid[r] = J.grid[r] or {}
        for c = 1, J.N do
            local k
            repeat
                k = Rand(J.KINDS)
            until not ((c > 2 and J.grid[r][c - 1] == k and J.grid[r][c - 2] == k)
                    or (r > 2 and J.grid[r - 1][c] == k and J.grid[r - 2][c] == k))
            J.grid[r][c] = k
        end
    end
    if not J.HasMove() then return J.Fill() end
end

-- Abraeumen, nachrutschen, auffuellen - bis nichts mehr passt.
function J.Resolve()
    local combo, total = 0, 0
    while true do
        local hit, n = J.Matches()
        if n == 0 then break end
        combo = combo + 1
        total = total + n * 10 * combo
        for k in pairs(hit) do J.grid[math.floor(k / 100)][k % 100] = 0 end
        for c = 1, J.N do
            local w = J.N
            for r = J.N, 1, -1 do
                if J.grid[r][c] ~= 0 then
                    J.grid[w][c] = J.grid[r][c]
                    if w ~= r then J.grid[r][c] = 0 end
                    w = w - 1
                end
            end
            for r = w, 1, -1 do J.grid[r][c] = Rand(J.KINDS) end
        end
    end
    if total > 0 then FG.AddScore(total) end
    if not J.HasMove() then J.Fill() end
    return total
end

--------------------------------------------------
-- Juwelen: Animation (6.78.1.0, Wunsch: "Animationen wie bei Candy Crush")
--------------------------------------------------
-- Tauschen gleitet, Treffer blaehen sich auf und verblassen, Steine fallen
-- nach, neue fallen von oben herein, Ketten zaehlen hoch ("Kette x2!").
-- Ein Takt nur, solange etwas laeuft; je Bild keine neue Tabelle. Waehrend
-- einer Animation nimmt das Brett keinen Klick an.
J.anim = { phase = nil, t = 0, dur = 0 }
J.SWAP, J.POP, J.FALL = 0.14, 0.2, 0.24
local pop = { t = 9, dur = 0.9 }

local function Ease(p) return p * p * (3 - 2 * p) end

function J.PopText(text)
    if not J.popText then return end
    J.popText:SetText(text)
    pop.t = 0
    J.popText:Show()
    J.board:SetScript("OnUpdate", J.Tick)
end

local function StartPhase(phase, dur)
    local a = J.anim
    a.phase, a.t, a.dur = phase, 0, dur
    J.board:SetScript("OnUpdate", J.Tick)
end

-- Treffer suchen und, wenn welche da sind, aufblaehen lassen.
local function TryPop()
    local hit, n = J.Matches()
    if n == 0 then
        J.anim.phase = nil
        if not J.HasMove() then
            J.Fill()
            JPaint()
            J.PopText("Neu gemischt")
        end
        return false
    end
    local a = J.anim
    a.combo = (a.combo or 0) + 1
    a.hit, a.n = hit, n
    StartPhase("pop", J.POP)
    return true
end

-- Treffer weg, Punkte, nachrutschen: jede Zelle weiss, wie weit ihr Stein faellt.
local function Collapse()
    local a = J.anim
    local pts = a.n * 10 * a.combo
    FG.AddScore(pts)
    J.PopText((a.combo > 1) and ("+" .. pts .. "   Kette x" .. a.combo .. "!") or ("+" .. pts))
    for k in pairs(a.hit) do J.grid[math.floor(k / 100)][k % 100] = 0 end
    local size = J.SIZE
    for c = 1, J.N do
        local w = J.N
        for r = J.N, 1, -1 do
            if J.grid[r][c] ~= 0 then
                J.grid[w][c] = J.grid[r][c]
                J.cells[w][c].fall = w - r
                if w ~= r then J.grid[r][c] = 0 end
                w = w - 1
            end
        end
        for r = w, 1, -1 do
            J.grid[r][c] = Rand(J.KINDS)
            J.cells[r][c].fall = w
        end
    end
    JPaint()
    for r = 1, J.N do
        for c = 1, J.N do
            local cell = J.cells[r][c]
            cell.dy = (cell.fall or 0) * size
            JPlace(cell)
        end
    end
    StartPhase("fall", J.FALL)
end

function J.Tick(self, el)
    el = el or 0
    if pop.t < pop.dur then
        pop.t = pop.t + el
        local p = math.min(1, pop.t / pop.dur)
        J.popText:SetAlpha(1 - p * p)
        J.popText:ClearAllPoints()
        J.popText:SetPoint("CENTER", self, "CENTER", 0, 20 + 30 * p)
        if p >= 1 then J.popText:Hide() end
    end
    local a = J.anim
    if a.phase then
        a.t = a.t + el
        local p = math.min(1, a.t / a.dur)
        local e = Ease(p)
        if a.phase == "swap" or a.phase == "unswap" then
            local k = (a.phase == "swap") and e or (1 - e)
            a.c1.dx, a.c1.dy = a.vx * k, a.vy * k
            a.c2.dx, a.c2.dy = -a.vx * k, -a.vy * k
            JPlace(a.c1) JPlace(a.c2)
        elseif a.phase == "pop" then
            for key in pairs(a.hit) do
                local cell = J.cells[math.floor(key / 100)][key % 100]
                cell.scale, cell.alpha = 1 + 0.5 * e, 1 - e
                JPlace(cell)
            end
        elseif a.phase == "fall" then
            for r = 1, J.N do
                for c = 1, J.N do
                    local cell = J.cells[r][c]
                    if (cell.fall or 0) > 0 then
                        cell.dy = cell.fall * J.SIZE * (1 - p * p)
                        JPlace(cell)
                    end
                end
            end
        end
        if p >= 1 then
            local ph = a.phase
            a.phase = nil
            if ph == "swap" then
                Swap(a.r1, a.c1r, a.r2, a.c2r)
                JPaint()
                a.combo = 0
                if not TryPop() then
                    -- Kein Treffer: zurueck tauschen, sichtbar zurueckgleiten.
                    Swap(a.r1, a.c1r, a.r2, a.c2r)
                    JPaint()
                    a.c1.dx, a.c1.dy, a.c2.dx, a.c2.dy = a.vx, a.vy, -a.vx, -a.vy
                    JPlace(a.c1) JPlace(a.c2)
                    StartPhase("unswap", J.SWAP)
                end
            elseif ph == "unswap" then
                JPaint()
            elseif ph == "pop" then
                Collapse()
            elseif ph == "fall" then
                for r = 1, J.N do for c = 1, J.N do J.cells[r][c].fall = 0 end end
                JPaint()
                TryPop()
            end
        end
    end
    if not J.anim.phase and pop.t >= pop.dur then self:SetScript("OnUpdate", nil) end
end

function J.Busy() return J.anim.phase ~= nil end

function J.Click(r, c)
    if J.Busy() then return end
    local s = J.sel
    if not s then J.sel = { r, c } JPaint() return end
    J.sel = nil
    if math.abs(s[1] - r) + math.abs(s[2] - c) ~= 1 then
        J.sel = { r, c }
        JPaint()
        return
    end
    JPaint()
    local a = J.anim
    a.r1, a.c1r, a.r2, a.c2r = s[1], s[2], r, c
    a.c1, a.c2 = J.cells[s[1]][s[2]], J.cells[r][c]
    -- Weg von Stein 1 zu Stein 2 in Bildpunkten (y nach oben positiv).
    a.vx, a.vy = (c - s[2]) * J.SIZE, -(r - s[1]) * J.SIZE
    StartPhase("swap", J.SWAP)
end

local function BuildJewels()
    local v = View("jewels")
    local size = FG.BOARD / J.N
    J.SIZE, J.GEM = size, size - 12
    local board = CreateFrame("Frame", nil, v)
    board:SetSize(FG.BOARD, FG.BOARD)
    board:SetPoint("TOP", v, "TOP", 0, -30)
    if board.SetClipsChildren then board:SetClipsChildren(true) end
    J.board = board
    for r = 1, J.N do
        J.cells[r] = {}
        for c = 1, J.N do
            local b = CreateFrame("Button", nil, board)
            b:SetSize(size, size)
            b:SetPoint("TOPLEFT", board, "TOPLEFT", (c - 1) * size, -(r - 1) * size)
            local bg = b:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints(b)
            local s = ((r + c) % 2 == 0) and (C.surface1 or C.bgPanel) or (C.surface2 or C.bgPanel)
            bg:SetColorTexture(s[1], s[2], s[3], 1)
            b.gem = b:CreateTexture(nil, "ARTWORK")
            b.gem:SetTexture(K.MEDIA .. "gem1")
            b.gem:SetSize(size - 12, size - 12)
            b.gem:SetPoint("CENTER")
            b.sel = b:CreateTexture(nil, "OVERLAY")
            b.sel:SetAllPoints(b)
            b.sel:SetColorTexture(1, 1, 1, 0.22)
            b.sel:Hide()
            local rr, cc = r, c
            b:SetScript("OnClick", function() J.Click(rr, cc) end)
            J.cells[r][c] = b
        end
    end
    local top = CreateFrame("Frame", nil, board)
    top:SetAllPoints(board)
    top:SetFrameLevel(board:GetFrameLevel() + 20)
    J.popText = K.NewText(top, 22)
    J.popText:SetPoint("CENTER", board, "CENTER", 0, 20)
    local g = C.textBright
    J.popText:SetTextColor(g[1], g[2], g[3])
    J.popText:Hide()
end

function J.Start()
    J.sel = nil
    J.anim.phase = nil
    J.Fill()
    JPaint()
end

--------------------------------------------------
-- Mahjong (Solitaer)
--------------------------------------------------

local M = { tiles = {}, sel = nil, TW = 52, TH = 64 }
FG.M = M

-- 36 Steine in drei Lagen: 6 x 4, darauf 4 x 2, darauf 2 x 2.
M.LAYOUT = {}
for y = 0, 3 do for x = 0, 5 do M.LAYOUT[#M.LAYOUT + 1] = { x = x, y = y, z = 0 } end end
for y = 1, 2 do for x = 1, 4 do M.LAYOUT[#M.LAYOUT + 1] = { x = x, y = y, z = 1 } end end
for y = 1, 2 do for x = 2, 3 do M.LAYOUT[#M.LAYOUT + 1] = { x = x, y = y, z = 2 } end end

local function At(list, x, y, z)
    for _, t in ipairs(list) do
        if t.alive and t.x == x and t.y == y and t.z == z then return t end
    end
    return nil
end

function M.Free(t, list)
    list = list or M.tiles
    if not t.alive then return false end
    if At(list, t.x, t.y, t.z + 1) then return false end
    return not At(list, t.x - 1, t.y, t.z) or not At(list, t.x + 1, t.y, t.z)
end

-- Ein loesbares Spiel: rueckwaerts abraeumen und dabei Paare vergeben.
function M.Deal()
    for _ = 1, 60 do
        local list = {}
        for i, p in ipairs(M.LAYOUT) do list[i] = { x = p.x, y = p.y, z = p.z, alive = true } end
        local faces, ok = {}, true
        for i = 1, #list / 2 do faces[i] = ((i - 1) % 18) + 1 end
        for i = #faces, 2, -1 do local j = Rand(i) faces[i], faces[j] = faces[j], faces[i] end
        for pair = 1, #list / 2 do
            local free = {}
            for _, t in ipairs(list) do if M.Free(t, list) then free[#free + 1] = t end end
            if #free < 2 then ok = false break end
            local a = table.remove(free, Rand(#free))
            local b = free[Rand(#free)]
            a.face, b.face = faces[pair], faces[pair]
            a.alive, b.alive = false, false
        end
        if ok then
            for _, t in ipairs(list) do t.alive = true end
            return list
        end
    end
    return nil
end

-- Zwei Farben (rot, blau) je 1-9, dazu ein Zeichen: Kreis oder Raute.
local function MFace(face)
    local red = face <= 9
    return tostring(((face - 1) % 9) + 1), GC["raidMark" .. (red and 7 or 6)], red and "diamond" or "disc"
end

local function MPaint()
    for _, t in ipairs(M.tiles) do
        local b = t.btn
        b:SetShown(t.alive or b.fading or false)
        if t.alive then
            local free = M.Free(t)
            b.face:SetTextColor(t.col[1], t.col[2], t.col[3], 1)
            b.suit:SetVertexColor(t.col[1], t.col[2], t.col[3], 1)
            b.dim:SetShown(not free)
            local on = (M.sel == t)
            b.sel:SetShown(on)
            b.top:ClearAllPoints()
            b.top:SetPoint("TOPLEFT", b, "TOPLEFT", on and -2 or 0, on and 2 or 0)
            b.top:SetSize(M.TW - 6, M.TH - 6)
        end
    end
end

function M.HasPair()
    local seen = {}
    for _, t in ipairs(M.tiles) do
        if M.Free(t) then
            if seen[t.face] then return true end
            seen[t.face] = true
        end
    end
    return false
end

function M.Click(t)
    if not M.Free(t) then return end
    local s = M.sel
    if not s or s == t then M.sel = (s == t) and nil or t MPaint() return end
    if s.face == t.face then
        s.alive, t.alive, M.sel = false, false, nil
        for _, x in ipairs({ s, t }) do
            local bb = x.btn
            if bb.fade then
                bb.fading = true
                pcall(bb.fade.Play, bb.fade)
            end
        end
        FG.AddScore(20)
        local left = 0
        for _, x in ipairs(M.tiles) do if x.alive then left = left + 1 end end
        if left == 0 then
            FG.AddScore(200)
            M.Start()
            return
        end
        if not M.HasPair() then M.Shuffle() end
    else
        M.sel = t
    end
    MPaint()
end

-- Kein Paar mehr frei: die Gesichter der uebrigen Steine neu mischen.
function M.Shuffle()
    local alive, faces = {}, {}
    for _, t in ipairs(M.tiles) do if t.alive then alive[#alive + 1] = t faces[#faces + 1] = t.face end end
    for _ = 1, 20 do
        for i = #faces, 2, -1 do local j = Rand(i) faces[i], faces[j] = faces[j], faces[i] end
        for i, t in ipairs(alive) do
            t.face = faces[i]
            t.label, t.col, t.icon = MFace(t.face)
            t.btn.face:SetText(t.label)
            t.btn.suit:SetTexture(K.MEDIA .. t.icon)
        end
        if M.HasPair() then break end
    end
    if win and win.note then win.note:SetText("Keine Paare mehr frei – neu gemischt.") end
end

-- 6.78.2.0 (Wunsch: "Mahjong schoener"): Steine mit Schatten, Seitenkante
-- (Dicke), Elfenbeinflaeche mit Verlauf, feinem Rand in der Farbe der
-- Sorte, Zahl und Zeichen; gesperrte Steine abgedunkelt, der gewaehlte
-- hebt sich an und leuchtet; abgeraeumte verblassen. Brett auf Filz.
local function BuildMahjong()
    local v = View("mahjong")
    local felt = CreateFrame("Frame", nil, v)
    felt:SetSize(6 * M.TW + 40, 4 * M.TH + 40)
    felt:SetPoint("TOP", v, "TOP", 0, -40)
    local fb = felt:CreateTexture(nil, "BACKGROUND")
    fb:SetAllPoints(felt)
    local fc = GC.tileFelt
    fb:SetColorTexture(fc[1], fc[2], fc[3], 1)
    local glow = felt:CreateTexture(nil, "BORDER")
    glow:SetTexture(K.MEDIA .. "halo")
    glow:SetAllPoints(felt)
    glow:SetVertexColor(fc[1] * 3, fc[2] * 3, fc[3] * 3, 0.35)
    local side = GC.tileSide
    K.Border(felt, 2, side[1], side[2], side[3], 0.9)
    local board = CreateFrame("Frame", nil, felt)
    board:SetSize(6 * M.TW, 4 * M.TH)
    board:SetPoint("CENTER", felt, "CENTER", 4, -2)
    M.board = board
    local face, top, acc = GC.tileFace, GC.tileFaceTop, C.accentBright or C.accent
    for i = 1, #M.LAYOUT do
        local b = CreateFrame("Button", nil, board)
        b:SetSize(M.TW, M.TH)
        -- Schatten und Seitenkante (die Dicke des Steins)
        local sh = b:CreateTexture(nil, "BACKGROUND", nil, 1)
        sh:SetColorTexture(0, 0, 0, 0.45)
        sh:SetPoint("TOPLEFT", b, "TOPLEFT", 5, -5)
        sh:SetSize(M.TW - 4, M.TH - 4)
        local sd = b:CreateTexture(nil, "BACKGROUND", nil, 2)
        sd:SetColorTexture(side[1], side[2], side[3], 1)
        sd:SetPoint("TOPLEFT", b, "TOPLEFT", 3, -3)
        sd:SetSize(M.TW - 5, M.TH - 5)
        -- Flaeche als eigener Rahmen: hebt sich beim Waehlen an.
        local t = CreateFrame("Frame", nil, b)
        t:SetSize(M.TW - 6, M.TH - 6)
        t:SetPoint("TOPLEFT", b, "TOPLEFT", 0, 0)
        t:EnableMouse(false)
        b.top = t
        local f = t:CreateTexture(nil, "BACKGROUND")
        f:SetAllPoints(t)
        f:SetColorTexture(1, 1, 1, 1)
        if f.SetGradient and _G.CreateColor then
            pcall(f.SetGradient, f, "VERTICAL", _G.CreateColor(face[1], face[2], face[3], 1), _G.CreateColor(top[1], top[2], top[3], 1))
        else
            f:SetVertexColor(face[1], face[2], face[3], 1)
        end
        local inner = CreateFrame("Frame", nil, t)
        inner:SetPoint("TOPLEFT", t, "TOPLEFT", 3, -3)
        inner:SetPoint("BOTTOMRIGHT", t, "BOTTOMRIGHT", -3, 3)
        b.ring = K.Border(inner, 1, side[1], side[2], side[3], 0.8)
        b.face = K.NewText(t, 22)
        b.face:SetPoint("CENTER", t, "CENTER", 0, 7)
        b.suit = t:CreateTexture(nil, "ARTWORK")
        b.suit:SetSize(13, 13)
        b.suit:SetPoint("BOTTOM", t, "BOTTOM", 0, 7)
        b.dim = t:CreateTexture(nil, "OVERLAY", nil, 1)
        b.dim:SetAllPoints(t)
        b.dim:SetColorTexture(0, 0, 0, 0.38)
        b.sel = CreateFrame("Frame", nil, t)
        b.sel:SetPoint("TOPLEFT", t, "TOPLEFT", -2, 2)
        b.sel:SetPoint("BOTTOMRIGHT", t, "BOTTOMRIGHT", 2, -2)
        K.Border(b.sel, 2, acc[1], acc[2], acc[3], 1)
        local sg = b.sel:CreateTexture(nil, "OVERLAY")
        sg:SetAllPoints(t)
        sg:SetColorTexture(acc[1], acc[2], acc[3], 0.12)
        b.sel:Hide()
        local hl = t:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints(t)
        hl:SetColorTexture(1, 1, 1, 0.12)
        b:SetHighlightTexture(hl)
        pcall(function()
            local ag = b:CreateAnimationGroup()
            local al = ag:CreateAnimation("Alpha")
            al:SetFromAlpha(1)
            al:SetToAlpha(0)
            al:SetDuration(0.22)
            ag:SetScript("OnFinished", function() if not b.fading then return end b.fading = nil b:Hide() b:SetAlpha(1) end)
            b.fade = ag
        end)
        M.btns = M.btns or {}
        M.btns[i] = b
    end
end

function M.Start()
    local list = M.Deal()
    if not list then return false end
    M.tiles, M.sel = list, nil
    for i, t in ipairs(list) do
        local b = M.btns[i]
        t.btn = b
        t.label, t.col, t.icon = MFace(t.face)
        b.face:SetText(t.label)
        b.suit:SetTexture(K.MEDIA .. t.icon)
        if b.fade then pcall(b.fade.Stop, b.fade) end  -- 6.80.5.0: alte Ausblendung trifft sonst Steine des neuen Spiels
        b.fading = nil
        b:SetAlpha(1)
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", M.board, "TOPLEFT", t.x * M.TW - t.z * 5, -(t.y * M.TH) + t.z * 5)
        b:SetFrameLevel(M.board:GetFrameLevel() + 1 + t.z * 3)
        local tt = t
        b:SetScript("OnClick", function() M.Click(tt) end)
    end
    if win and win.note then win.note:SetText("") end
    MPaint()
    return true
end

--------------------------------------------------
-- Huehnerjagd
--------------------------------------------------

local H = { birds = {}, POOL = 7, spawnIn = 0, texts = {}, streak = 0 }
FG.H = H

-- 6.78.1.0 (Wunsch: "verschiedene witzige Huehner"): jedes Huhn hat seine
-- Art - Farbe, Groesse, Tempo, Flugbahn, Punkte, Spruch. Gewichte = wie oft.
H.KINDS = {
    { key = "huhn",    w = 46, tint = nil, min = 34, max = 52, v1 = 60,  v2 = 140, pts = 10, words = { "Gack!", "Bwaak!", "Pock pock!" }, sounds = { "gack", "bwaak", "pock" } },
    { key = "kueken",  w = 16, tint = 1,   min = 22, max = 28, v1 = 170, v2 = 240, pts = 40, words = { "Piep!", "Piiiep?" }, sounds = { "piep" } },
    { key = "flatter", w = 12, tint = 3,   min = 30, max = 42, v1 = 90,  v2 = 140, pts = 30, zig = 46, words = { "Wuiii!", "Huiii!" }, sounds = { "bwaak", "gack" } },
    { key = "zombie",  w = 10, tint = 4,   min = 40, max = 54, v1 = 45,  v2 = 70,  pts = 35, hp = 2, words = { "Grrbwak?", "Hirrrn…", "Gaaarg!" }, sounds = { "zombie" } },
    { key = "bombe",   w = 10, tint = 7,   min = 34, max = 46, v1 = 80,  v2 = 130, pts = -50, words = { "BUMM!", "Autsch!" }, sounds = { "bumm" } },
    { key = "gold",    w = 4,  tint = 2,   min = 36, max = 40, v1 = 230, v2 = 300, pts = 150, words = { "GOLDHUHN!", "Kikeriki – Jackpot!" }, sounds = { "gold" } },
}
local weightSum = 0
for _, k in ipairs(H.KINDS) do weightSum = weightSum + k.w end

local function PickKind()
    local x = math.random() * weightSum
    for _, k in ipairs(H.KINDS) do
        x = x - k.w
        if x <= 0 then return k end
    end
    return H.KINDS[1]
end

-- 6.78.3.0 (Beta-Test: "die Gackertoene gehen noch nicht"): eigene,
-- gerechnete Toene (media/sounds/huhn_*.ogg, .github/scripts/make_chicken_sounds.py).
FG.SOUND_PATH = "Interface\\AddOns\\WeintCodex\\media\\sounds\\huhn_"
-- 6.79.2.0 (Beta-Test: "klingt nicht nach Huhn"): zuerst die echten
-- Huehner des Spiels - Buschhuhn, sound/creature/bushchicken (FileDataIDs
-- vom Spieler aus wago.tools). WeintCodex spielt sie nur ab, liefert nichts
-- aus. Kennt der Client eine Nummer nicht (PlaySoundFile: willPlay false),
-- springen die eigenen gerechneten Toene ein.
H.GAME_SOUNDS = {
    huhn    = { 545686, 545688, 545685, 545698, 545703, 545700, 545701, 545704, 545705 },
    kueken  = { 545698, 545703, 545685 },
    flatter = { 545700, 545701, 545704, 545705 },
    zombie  = { 545692, 545695, 545699, 545694, 545702 },
    bombe   = { 545690, 545691, 545693 },
    gold    = { 545684, 545697 },
    wound   = { 545687, 545689, 545696 },
}
H.gameSounds = nil   -- zuletzt: hat der Client das Huhn des Spiels gespielt?

function H.Sound(kind, which)
    if K.Get(KEY, "flightGamesSound") == false or not _G.PlaySoundFile then return false end
    local ids = H.GAME_SOUNDS[which or (kind and kind.key) or ""]
    if ids then
        local ok, willPlay = pcall(_G.PlaySoundFile, ids[math.random(1, #ids)], "Master")
        willPlay = ok and K.Plain(willPlay)
        H.gameSounds = willPlay and true or false
        if willPlay then return true end
    end
    local list = kind and kind.sounds
    if not list or #list == 0 then return false end
    local name = list[math.random(1, #list)]
    return pcall(_G.PlaySoundFile, FG.SOUND_PATH .. name .. ".ogg", "Master")
end

-- Ein Wort, das kurz aufsteigt und verblasst (Pool, keine neuen Tabellen).
function H.Say(x, y, text, good)
    local t
    for _, f in ipairs(H.texts) do if not f.live then t = f break end end
    t = t or H.texts[1]
    if not t then return end
    t.live, t.t, t.x, t.y = true, 0, x, y
    t:SetText(text)
    local c = good and (C.textBright) or GC.raidMark7
    t:SetTextColor(c[1], c[2], c[3], 1)
    t:Show()
end

local function Spawn(b)
    local k = PickKind()
    b.kind = k
    local s = math.random(k.min, k.max)
    b.size, b.hp = s, k.hp or 1
    b:SetSize(s, s)
    b:SetAlpha(1)
    b.dir = (math.random() < 0.5) and 1 or -1
    b.speed = math.random(k.v1, k.v2)
    b.x = b.dir > 0 and -s or FG.BOARD
    b.y = math.random(20, FG.BOARD - s - 60)
    b.wob = math.random() * 6
    b.icon:SetTexCoord(b.dir > 0 and 0.92 or 0.08, b.dir > 0 and 0.08 or 0.92, 0.08, 0.92)
    local c = k.tint and GC["raidMark" .. k.tint]
    if c then b.icon:SetVertexColor(c[1], c[2], c[3], 1) else b.icon:SetVertexColor(1, 1, 1, 1) end
    b.live = true
    b:Show()
end

function H.Hit(b)
    if not b.live then return end
    local k = b.kind or H.KINDS[1]
    b.hp = (b.hp or 1) - 1
    local bx, by = b.x + b.size / 2, b.y
    if b.hp > 0 then
        H.Sound(k, "wound")
        b:SetAlpha(0.55)
        b.speed = b.speed * 1.8
        H.Say(bx, by, "Noch nicht tot!", true)
        return
    end
    H.Sound(k)
    b.live = false
    b:Hide()
    local pts = k.pts
    if pts > 0 then
        H.streak = H.streak + 1
        pts = pts + (b.kind.key == "huhn" and (52 - b.size) or 0)
        if H.streak >= 3 then pts = pts + 5 * H.streak end
    else
        H.streak = 0
    end
    FG.AddScore(pts)
    local word = k.words[math.random(1, #k.words)]
    H.Say(bx, by, word .. "  " .. (pts > 0 and "+" or "") .. pts .. (H.streak >= 3 and ("  Serie " .. H.streak) or ""), pts > 0)
end

local function Tick(_, el)
    el = el or 0
    H.spawnIn = H.spawnIn - el
    if H.spawnIn <= 0 then
        H.spawnIn = 0.5 + math.random() * 0.8
        for _, b in ipairs(H.birds) do
            if not b.live then Spawn(b) break end
        end
    end
    for _, b in ipairs(H.birds) do
        if b.live then
            b.x = b.x + b.dir * b.speed * el
            b.wob = b.wob + el * ((b.kind and b.kind.zig) and 6 or 4)
            local y = b.y + math.sin(b.wob) * ((b.kind and b.kind.zig) or 8)
            if b.x < -b.size - 2 or b.x > FG.BOARD + 2 then
                b.live = false
                b:Hide()
                if b.kind and b.kind.pts > 0 then H.streak = 0 end
            else
                b:SetPoint("TOPLEFT", H.sky, "TOPLEFT", b.x, -y)
            end
        end
    end
    for _, t in ipairs(H.texts) do
        if t.live then
            t.t = t.t + el
            local p = t.t / 1.1
            if p >= 1 then
                t.live = false
                t:Hide()
            else
                t:SetAlpha(1 - p * p)
                t:ClearAllPoints()
                t:SetPoint("CENTER", H.sky, "TOPLEFT", t.x, -t.y + 24 * p)
            end
        end
    end
end
H.Tick = Tick

local function BuildHunt()
    local v = View("hunt")
    local sky = CreateFrame("Frame", nil, v)
    sky:SetSize(FG.BOARD, FG.BOARD)
    sky:SetPoint("TOP", v, "TOP", 0, -30)
    if sky.SetClipsChildren then sky:SetClipsChildren(true) end
    local bg = sky:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(sky)
    local b6, b5 = GC.raidMark6, GC.raidMark5
    bg:SetColorTexture(b6[1] * 0.35, b6[2] * 0.35, b6[3] * 0.45, 1)
    local hill = sky:CreateTexture(nil, "BORDER")
    hill:SetPoint("BOTTOMLEFT", sky, "BOTTOMLEFT")
    hill:SetPoint("BOTTOMRIGHT", sky, "BOTTOMRIGHT")
    hill:SetHeight(40)
    local g4 = GC.raidMark4
    hill:SetColorTexture(g4[1] * 0.3, g4[2] * 0.35, g4[3] * 0.3, 1)
    local cloud = sky:CreateTexture(nil, "BORDER")
    cloud:SetTexture(K.MEDIA .. "halo")
    cloud:SetSize(160, 60)
    cloud:SetPoint("TOPLEFT", sky, "TOPLEFT", 40, -50)
    cloud:SetVertexColor(b5[1], b5[2], b5[3], 0.25)
    H.sky = sky
    for i = 1, H.POOL do
        local b = CreateFrame("Button", nil, sky)
        b.icon = b:CreateTexture(nil, "ARTWORK")
        b.icon:SetAllPoints(b)
        b.icon:SetTexture(FG.HUHN)
        b:SetScript("OnMouseDown", function(self) H.Hit(self) end)
        b:SetFrameLevel(sky:GetFrameLevel() + 2)
        b:Hide()
        H.birds[i] = b
    end
    -- Daneben geschossen: die Serie reisst.
    sky:EnableMouse(true)
    sky:SetScript("OnMouseDown", function() H.streak = 0 end)
    local over = CreateFrame("Frame", nil, sky)
    over:SetAllPoints(sky)
    over:SetFrameLevel(sky:GetFrameLevel() + 10)
    for i = 1, 5 do
        local t = K.NewText(over, 14)
        t:Hide()
        H.texts[i] = t
    end
    v:SetScript("OnShow", function() sky:SetScript("OnUpdate", Tick) end)
    v:SetScript("OnHide", function() sky:SetScript("OnUpdate", nil) end)
end

function H.Start()
    H.spawnIn, H.streak = 0.3, 0
    for _, t in ipairs(H.texts) do t.live = false t:Hide() end
    for _, b in ipairs(H.birds) do b.live = false b:Hide() end
end

--------------------------------------------------
-- Bestenliste der Gilde (6.89.0.0)
--------------------------------------------------
-- Wunsch: "Bestenlisten - best erreichte Punkte und pro Flug innerhalb der
-- Gilde." Fuenfte Ausnahme nach aussen (CLAUDE.md): Addon-Nachrichten mit
-- dem Praefix WCFG, nur an die Gilde, nur Spiel, Punkte, Knoten der
-- Flugstrecke und Flugdauer - kein freier Text. Der Name kommt aus dem
-- Absenderfeld, nie aus der Nachricht. Schalter flightGamesShare (ab Werk
-- an, nur mit den Flugspielen).
--   s,<g>,<Punkte>,<von|0>,<nach|0>,<Sekunden|0>  nach jedem Spiel eines Flugs
--   q                                            Bitte um Bestwerte (Einloggen +40 s, alle 30 min)
--   b,<g>,<Punkte>                               eigener Bestwert je Spiel (Antwort)
--   r,<g>,<Punkte>,<von>,<nach>                  eigener Bestwert je Strecke (Antwort)
-- Gespeichert in WeintCodex_SavedData.flightGames.board.

FG.PREFIX = "WCFG"
FG.CODE = { jewels = "j", mahjong = "m", hunt = "h" }
FG.GAME_OF = { j = "jewels", m = "mahjong", h = "hunt" }
FG.SCORE_MAX = 5000000
FG.NODE_MAX = 99999
FG.SECS_MAX = 7200
FG.MSG_MAX = 64
FG.SEND_GAP = 1.0
FG.QUEUE_MAX = 40
FG.ANSWER_MAX = 20
FG.ANSWER_GAP = 600
FG.REQUEST_EVERY = 1800
FG.RATE_WINDOW, FG.RATE_MAX, FG.SENDER_MAX = 60, 30, 300
FG.NAMES_MAX, FG.ROUTES_MAX, FG.NODES_MAX = 200, 300, 600
FG.stats = { sent = 0, received = 0, rejected = 0, answered = 0 }

local bqueue = {}
FG.queue = bqueue
local fgSenders, fgSenderN = {}, 0

function FG.Sharing() return FG.Active() and K.Get(KEY, "flightGamesShare") ~= false end

local function Epoch()
    local t = _G.time and K.Plain(_G.time())
    return type(t) == "number" and t or 0
end
local function Clock()
    local t = _G.GetTime and K.Plain(_G.GetTime())
    return type(t) == "number" and t or 0
end
local function FGInGuild() return _G.IsInGuild and K.Bool(_G.IsInGuild(), false) or false end
local function FGInCombat() return _G.InCombatLockdown and K.Bool(_G.InCombatLockdown(), true) or false end

local function Realm()
    local r = _G.GetNormalizedRealmName and K.Plain(_G.GetNormalizedRealmName())
    return (type(r) == "string" and r ~= "") and r or nil
end
-- "Name-Realm" wie das Absenderfeld; nil ohne Antwort des Clients.
function FG.Me()
    local n = _G.UnitName and K.Plain(_G.UnitName("player"))
    if type(n) ~= "string" or n == "" then return nil end
    local r = Realm()
    return r and (n .. "-" .. r) or n
end
function FG.FullName(sender)
    sender = K.Plain(sender)
    if type(sender) ~= "string" or sender == "" or #sender > 60 or sender:find("[%c|,]") then return nil end
    if not sender:find("-", 1, true) then
        local r = Realm()
        if r then sender = sender .. "-" .. r end
    end
    return sender
end

function FG.Board(create)
    local sd = _G.WeintCodex_SavedData
    if type(sd) ~= "table" then return nil end
    local fg = sd.flightGames
    if type(fg) ~= "table" then
        if not create then return nil end
        fg = { best = {} }
        sd.flightGames = fg
    end
    local b = fg.board
    if type(b) ~= "table" then
        if not create then return nil end
        b = {}
        fg.board = b
    end
    if type(b.all) ~= "table" then b.all = {} end
    if type(b.route) ~= "table" then b.route = {} end
    if type(b.nodes) ~= "table" then b.nodes = {} end
    return b
end

function FG.RouteKey(from, to)
    if type(from) ~= "number" or type(to) ~= "number" or from < 1 or to < 1 or from == to then return nil end
    return from .. ">" .. to
end

-- Ein Eintrag je Name und Spiel: nur Besseres ersetzt. Voll -> der aelteste geht.
local function Put(list, name, score, t)
    local e = list[name]
    if e then
        if e[1] >= score then return false end
        e[1], e[2] = score, t
        return true
    end
    local n, oldK, oldT = 0, nil, nil
    for k, v in pairs(list) do
        n = n + 1
        if not oldT or (v[2] or 0) < oldT then oldK, oldT = k, v[2] or 0 end
    end
    if n >= FG.NAMES_MAX and oldK then list[oldK] = nil end
    list[name] = { score, t }
    return true
end

local function Newest(r)
    local m = 0
    for _, list in pairs(r) do for _, v in pairs(list) do if (v[2] or 0) > m then m = v[2] or 0 end end end
    return m
end

function FG.Enter(game, name, score, routeKey, t)
    local b = FG.Board(true)
    if not (b and FG.CODE[game] and type(name) == "string" and type(score) == "number" and score > 0) then return false end
    t = t or Epoch()
    b.all[game] = b.all[game] or {}
    local changed = Put(b.all[game], name, score, t)
    if routeKey then
        local r = b.route[routeKey]
        if not r then
            local n, oldK, oldT = 0, nil, nil
            for k, v in pairs(b.route) do
                n = n + 1
                local nt = Newest(v)
                if not oldT or nt < oldT then oldK, oldT = k, nt end
            end
            if n >= FG.ROUTES_MAX and oldK then b.route[oldK] = nil end
            r = {}
            b.route[routeKey] = r
        end
        r[game] = r[game] or {}
        changed = Put(r[game], name, score, t) or changed
    end
    return changed
end

function FG.NoteNode(id, name)
    if type(id) ~= "number" or type(name) ~= "string" or name == "" then return end
    local b = FG.Board(true)
    if not b then return end
    if not b.nodes[id] then
        local n = 0
        for _ in pairs(b.nodes) do n = n + 1 end
        if n >= FG.NODES_MAX then return end
    end
    b.nodes[id] = name
end

function FG.RouteName(key)
    if type(key) ~= "string" then return nil end
    local a, z = key:match("^(%d+)>(%d+)$")
    if not a then return nil end
    local b = FG.Board()
    local na, nz = b and b.nodes[tonumber(a)], b and b.nodes[tonumber(z)]
    if na and nz then return na .. " → " .. nz end
    return "Strecke " .. (na or a) .. " → " .. (nz or z)
end

-- Strecke des laufenden, sonst des letzten Flugs.
function FG.CurrentRouteKey()
    local f = FG.flight
    return FG.RouteKey(f.fromID, f.toID) or FG.lastRouteKey
end

-- Rangliste: { {name, score, t, own}, ... } absteigend, Gleichstand: frueher vorn.
function FG.Ranking(game, routeKey)
    local b = FG.Board()
    local list
    if b then
        if routeKey then list = b.route[routeKey] and b.route[routeKey][game]
        else list = b.all[game] end
    end
    local out, me = {}, FG.Me()
    for name, v in pairs(list or {}) do
        out[#out + 1] = { name = name, score = v[1], t = v[2] or 0, own = (name == me) }
    end
    table.sort(out, function(x, y)
        if x.score ~= y.score then return x.score > y.score end
        if x.t ~= y.t then return x.t < y.t end
        return x.name < y.name
    end)
    return out
end

function FG.RankOf(game, routeKey, name)
    name = name or FG.Me()
    for i, e in ipairs(FG.Ranking(game, routeKey)) do if e.name == name then return i end end
    return nil
end

-- Bestwerte von vor der Bestenliste nachtragen (eigener Name).
function FG.SeedOwn()
    local me, best = FG.Me(), FG.Best()
    if not (me and best) then return end
    for g in pairs(FG.CODE) do
        if type(best[g]) == "number" and best[g] > 0 then FG.Enter(g, me, best[g], nil, nil) end
    end
end

-- Nachrichten bauen und strikt pruefen ------------------------------

function FG.FormatScore(game, score, from, to, secs)
    return "s," .. FG.CODE[game] .. "," .. math.floor(score) .. "," .. math.floor(from or 0) .. ","
        .. math.floor(to or 0) .. "," .. math.floor(secs or 0)
end

local function Num(s, max)
    if type(s) ~= "string" or #s > 8 then return nil end
    local n = tonumber(s)
    if not n or n < 0 or n > max or n ~= math.floor(n) then return nil end
    return n
end

-- Liefert kind, game, score, from, to, secs - oder nil.
function FG.Parse(text)
    if type(text) ~= "string" or #text > FG.MSG_MAX then return nil end
    if text == "q" then return "q" end
    local g, s, a, z, d = text:match("^s,(%l),(%d+),(%d+),(%d+),(%d+)$")
    if g then
        local game = FG.GAME_OF[g]
        s, a, z, d = Num(s, FG.SCORE_MAX), Num(a, FG.NODE_MAX), Num(z, FG.NODE_MAX), Num(d, FG.SECS_MAX)
        if not (game and s and s > 0 and a and z and d) then return nil end
        if (a == 0) ~= (z == 0) or (a > 0 and a == z) then return nil end
        return "s", game, s, a, z, d
    end
    g, s = text:match("^b,(%l),(%d+)$")
    if g then
        local game = FG.GAME_OF[g]
        s = Num(s, FG.SCORE_MAX)
        if not (game and s and s > 0) then return nil end
        return "b", game, s
    end
    g, s, a, z = text:match("^r,(%l),(%d+),(%d+),(%d+)$")
    if g then
        local game = FG.GAME_OF[g]
        s, a, z = Num(s, FG.SCORE_MAX), Num(a, FG.NODE_MAX), Num(z, FG.NODE_MAX)
        if not (game and s and s > 0 and a and z and a > 0 and z > 0 and a ~= z) then return nil end
        return "r", game, s, a, z
    end
    return nil
end

function FG.Push(line)
    if not (FG.Sharing() and FGInGuild()) or #bqueue >= FG.QUEUE_MAX then return false end
    bqueue[#bqueue + 1] = line
    if FG.sendFrame then FG.sendFrame:Show() end
    return true
end

-- Eigenes Ergebnis: in die eigene Liste und (wenn geteilt) an die Gilde.
function FG.Submit(game, score, from, to, secs)
    local me = FG.Me()
    local rk = FG.RouteKey(from, to)
    if me then FG.Enter(game, me, score, rk, nil) end
    if not rk then from, to = 0, 0 end
    if type(secs) ~= "number" or secs < 0 then secs = 0 end
    if secs > FG.SECS_MAX then secs = FG.SECS_MAX end
    score = math.min(score, FG.SCORE_MAX)
    return FG.Push(FG.FormatScore(game, score, from, to, secs))
end

local fgNextSend = 0
function FG.SendNext(now)
    if #bqueue == 0 then return true end
    if now < fgNextSend or FGInCombat() then return false end
    local cc = _G.C_ChatInfo
    if not (cc and cc.SendAddonMessage and FG.Sharing()) then
        for i = #bqueue, 1, -1 do bqueue[i] = nil end
        return true
    end
    local ok, res = pcall(cc.SendAddonMessage, FG.PREFIX, bqueue[1], "GUILD")
    if ok and (res == nil or res == true or res == 0) then
        table.remove(bqueue, 1)
        FG.stats.sent = FG.stats.sent + 1
        fgNextSend = now + FG.SEND_GAP
    else
        fgNextSend = now + 5
    end
    return #bqueue == 0
end

local sendFrame = CreateFrame("Frame")
sendFrame:Hide()
local fgAcc = 0
sendFrame:SetScript("OnUpdate", function(self, el)
    fgAcc = fgAcc + (el or 0)
    if fgAcc < 0.25 then return end
    fgAcc = 0
    if FG.SendNext(Clock()) then self:Hide() end
end)
FG.sendFrame = sendFrame

-- Antwort auf "q": hoechstens einmal je FG.ANSWER_GAP s, hoechstens
-- FG.ANSWER_MAX Zeilen - Bestwerte je Spiel, dann die besten Strecken.
function FG.AnswerLines()
    local lines, best, me = {}, FG.Best(), FG.Me()
    for _, g in ipairs(FG.GAMES) do
        local s = best and best[g.key]
        if type(s) == "number" and s > 0 then lines[#lines + 1] = "b," .. FG.CODE[g.key] .. "," .. math.min(math.floor(s), FG.SCORE_MAX) end
    end
    local b, mine = FG.Board(), {}
    for key, r in pairs(b and b.route or {}) do
        local a, z = key:match("^(%d+)>(%d+)$")
        for game, list in pairs(r) do
            local e = me and list[me]
            if e and FG.CODE[game] and a then mine[#mine + 1] = { game = game, score = e[1], a = a, z = z } end
        end
    end
    table.sort(mine, function(x, y) return x.score > y.score end)
    for _, e in ipairs(mine) do
        if #lines >= FG.ANSWER_MAX then break end
        lines[#lines + 1] = "r," .. FG.CODE[e.game] .. "," .. math.min(math.floor(e.score), FG.SCORE_MAX) .. "," .. e.a .. "," .. e.z
    end
    return lines
end

FG.lastAnswer = nil
function FG.QueueAnswer()
    local n = 0
    for _, l in ipairs(FG.AnswerLines()) do if FG.Push(l) then n = n + 1 end end
    if n > 0 then FG.stats.answered = FG.stats.answered + 1 end
    return n
end

function FG.OnQuery(now)
    if FG.lastAnswer and now - FG.lastAnswer < FG.ANSWER_GAP then return false end
    FG.lastAnswer = now
    local later = _G.C_Timer and _G.C_Timer.After
    if later then later(math.random() * 5, FG.QueueAnswer) else FG.QueueAnswer() end
    return true
end

FG.lastRequest = nil
function FG.Request()
    if not (FG.Sharing() and FGInGuild()) then return false end
    local now = Clock()
    if FG.lastRequest and now - FG.lastRequest < 60 then return false end
    FG.lastRequest = now
    return FG.Push("q")
end

function FG.Allow(sender, now)
    local r = fgSenders[sender]
    if not r then
        if fgSenderN >= FG.SENDER_MAX then return false end
        r = { now, 0 }
        fgSenders[sender] = r
        fgSenderN = fgSenderN + 1
    end
    if now - r[1] > FG.RATE_WINDOW then r[1], r[2] = now, 0 end
    r[2] = r[2] + 1
    return r[2] <= FG.RATE_MAX
end

function FG.OnAddonMessage(prefix, text, channel, sender, now)
    prefix, text, channel = K.Plain(prefix), K.Plain(text), K.Plain(channel)
    if prefix ~= FG.PREFIX then return false end
    if channel ~= "GUILD" or not FG.Sharing() then FG.stats.rejected = FG.stats.rejected + 1 return false end
    local name = FG.FullName(sender)
    if not name then FG.stats.rejected = FG.stats.rejected + 1 return false end
    if name == FG.Me() then return false end
    now = type(now) == "number" and now or Clock()
    if not FG.Allow(name, now) then FG.stats.rejected = FG.stats.rejected + 1 return false end
    local kind, game, score, a, z = FG.Parse(text)
    if not kind then FG.stats.rejected = FG.stats.rejected + 1 return false end
    FG.stats.received = FG.stats.received + 1
    if kind == "q" then return FG.OnQuery(now) or true end
    if kind == "b" then FG.Enter(game, name, score, nil, nil)
    else FG.Enter(game, name, score, FG.RouteKey(a, z), nil) end
    if FG.views and FG.views.board and FG.views.board:IsShown() then FG.PaintBoard() end
    return true
end

-- Klassen aus der Gildenliste (fuer die Farbe des Namens).
FG.roster = {}
function FG.ScanRoster()
    if not (_G.GetNumGuildMembers and _G.GetGuildRosterInfo) then return 0 end
    local ok, n = pcall(_G.GetNumGuildMembers)
    n = ok and K.Plain(n) or 0
    if type(n) ~= "number" then return 0 end
    for i = 1, math.min(n, 1000) do
        local ok2, name, _, _, _, _, _, _, _, _, _, class = pcall(_G.GetGuildRosterInfo, i)
        name, class = ok2 and K.Plain(name), ok2 and K.Plain(class)
        if type(name) == "string" and type(class) == "string" then
            FG.roster[FG.FullName(name) or name] = class
        end
    end
    return n
end
function FG.ClassColor(name)
    local class = FG.roster[name]
    if not class then return nil end
    local cc
    if _G.C_ClassColor and _G.C_ClassColor.GetClassColor then
        local ok, col = pcall(_G.C_ClassColor.GetClassColor, class)
        if ok and type(col) == "table" then cc = col end
    end
    if not cc and type(_G.RAID_CLASS_COLORS) == "table" then cc = _G.RAID_CLASS_COLORS[class] end
    if type(cc) ~= "table" or type(cc.r) ~= "number" then return nil end
    return cc
end

function FG.StatusLines()
    local b, n, r = FG.Board(), 0, 0
    for _, list in pairs(b and b.all or {}) do for _ in pairs(list) do n = n + 1 end end
    for _ in pairs(b and b.route or {}) do r = r + 1 end
    return {
        string.format("Gilde: %s · gesendet %d · empfangen %d · abgewiesen %d · beantwortet %d",
            FG.Sharing() and "teilen an" or "teilen aus", FG.stats.sent, FG.stats.received, FG.stats.rejected, FG.stats.answered),
        string.format("Bestenliste: %d Einträge (alle Zeiten) · %d Strecken", n, r),
    }
end

-- Pillen mit runden Enden (wie die Farm-Leiste des Sammel-Atlas).
FG.PILL_H = 22
local function PaintPill(b, on, hot)
    local a, base = K.Highlight(), GC.kachelFill
    local r, g, bl
    if on then
        local k = hot and 0.55 or 0.40
        r, g, bl = base[1] + (a[1] - base[1]) * k, base[2] + (a[2] - base[2]) * k, base[3] + (a[3] - base[3]) * k
    else
        local s1 = hot and (C.borderStrong or C.surface3) or C.surface3
        r, g, bl = s1[1], s1[2], s1[3]
    end
    b.fill:SetColorTexture(r, g, bl, 1)
    b.capL:SetVertexColor(r, g, bl, 1)
    b.capR:SetVertexColor(r, g, bl, 1)
    local tc = on and C.textBright or C.textNormal
    b.text:SetTextColor(tc[1], tc[2], tc[3], on and 1 or 0.85)
    b.on = on
end
FG.PaintPill = PaintPill

local function Pill(parent, text, w, onClick)
    local H = FG.PILL_H
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(w, H)
    b.fill = b:CreateTexture(nil, "BACKGROUND")
    b.fill:SetPoint("TOPLEFT", b, "TOPLEFT", H / 2, 0)
    b.fill:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -H / 2, 0)
    b.capL = b:CreateTexture(nil, "BACKGROUND")
    b.capL:SetSize(H, H)
    b.capL:SetPoint("LEFT", b, "LEFT", 0, 0)
    b.capL:SetTexture(K.MEDIA .. "disc")
    b.capR = b:CreateTexture(nil, "BACKGROUND")
    b.capR:SetSize(H, H)
    b.capR:SetPoint("RIGHT", b, "RIGHT", 0, 0)
    b.capR:SetTexture(K.MEDIA .. "disc")
    b.text = K.NewText(b, 12)
    b.text:SetPoint("CENTER", b, "CENTER", 0, 0)
    b.text:SetText(text)
    b:SetScript("OnEnter", function(self) self._hot = true PaintPill(self, self.on, true) end)
    b:SetScript("OnLeave", function(self) self._hot = nil PaintPill(self, self.on, false) end)
    if onClick then b:SetScript("OnClick", onClick) end
    PaintPill(b, false, false)
    return b
end
FG.Pill = Pill

-- Masse der Ansicht (Breite der Ansicht = FG.W - 40). Spalten: Platz,
-- Name, Punkte, Datum - nichts reicht ueber die Ansicht hinaus.
FG.BL = {
    GAME_W = 120, SCOPE_W = 130, GAP = 10,
    Y_GAMES = -4, Y_SCOPE = -36, Y_LABEL = -68, Y_HEAD = -92, Y_ROWS = -112, ROW_H = 28, ROWS = 10,
    COLS = { { x = 8, w = 28 }, { x = 42, w = 176 }, { x = 224, w = 84 }, { x = 314, w = 78 } },
    BACK_W = 140, BACK_H = 28,
}
FG.bstate = { game = "jewels", scope = "all", from = "ask" }

local function DateText(t)
    if type(t) ~= "number" or t <= 0 or not _G.date then return "" end
    local ok, s = pcall(_G.date, "%d.%m.%y", t)
    return ok and type(s) == "string" and s or ""
end

local function BuildBoardView()
    local v = View("board")
    local L, vw = FG.BL, FG.W - 40
    v.games = {}
    local gx = (vw - (#FG.GAMES * L.GAME_W + (#FG.GAMES - 1) * L.GAP)) / 2
    for i, g in ipairs(FG.GAMES) do
        local key = g.key
        local p = Pill(v, g.name, L.GAME_W, function() FG.bstate.game = key FG.PaintBoard() end)
        p:SetPoint("TOPLEFT", v, "TOPLEFT", gx + (i - 1) * (L.GAME_W + L.GAP), L.Y_GAMES)
        p.key = key
        v.games[i] = p
    end
    local sx = (vw - (2 * L.SCOPE_W + L.GAP)) / 2
    v.scopeAll = Pill(v, "Alle Zeiten", L.SCOPE_W, function() FG.bstate.scope = "all" FG.PaintBoard() end)
    v.scopeAll:SetPoint("TOPLEFT", v, "TOPLEFT", sx, L.Y_SCOPE)
    v.scopeRoute = Pill(v, "Dieser Flug", L.SCOPE_W, function() FG.bstate.scope = "route" FG.PaintBoard() end)
    v.scopeRoute:SetPoint("TOPLEFT", v, "TOPLEFT", sx + L.SCOPE_W + L.GAP, L.Y_SCOPE)
    local m, tb = C.textMuted, C.textBright
    v.label = K.NewText(v, 12)
    v.label:SetPoint("TOPLEFT", v, "TOPLEFT", 0, L.Y_LABEL)
    v.label:SetWidth(vw)
    v.label:SetJustifyH("CENTER")
    v.label:SetWordWrap(false)
    v.label:SetTextColor(m[1], m[2], m[3])
    local function Cell(parent, i, size, y, right)
        local c = L.COLS[i]
        local t = K.NewText(parent, size)
        t:SetPoint("TOPLEFT", parent, "TOPLEFT", c.x, y)
        t:SetWidth(c.w)
        t:SetJustifyH(right and "RIGHT" or "LEFT")
        t:SetWordWrap(false)
        return t
    end
    v.head = {}
    for i, h in ipairs({ "#", "Name", "Punkte", "Datum" }) do
        local t = Cell(v, i, 11, L.Y_HEAD, i >= 3)
        t:SetText(h)
        t:SetTextColor(m[1], m[2], m[3])
        v.head[i] = t
    end
    v.rows = {}
    local s1, acc = C.surface1 or C.bgCard, C.accent
    for i = 1, L.ROWS do
        local r = CreateFrame("Frame", nil, v)
        r:SetSize(vw, L.ROW_H - 2)
        r:SetPoint("TOPLEFT", v, "TOPLEFT", 0, L.Y_ROWS - (i - 1) * L.ROW_H)
        r.bg = r:CreateTexture(nil, "BACKGROUND")
        r.bg:SetAllPoints(r)
        r.bg:SetColorTexture(s1[1], s1[2], s1[3], (i % 2 == 1) and 0.9 or 0.55)
        r.mark = r:CreateTexture(nil, "BORDER")
        r.mark:SetAllPoints(r)
        r.mark:SetColorTexture(acc[1], acc[2], acc[3], 0.18)
        r.mark:Hide()
        r.strip = r:CreateTexture(nil, "ARTWORK")
        r.strip:SetPoint("TOPLEFT") r.strip:SetPoint("BOTTOMLEFT")
        r.strip:SetWidth(3)
        r.strip:SetColorTexture(acc[1], acc[2], acc[3], 1)
        r.strip:Hide()
        r.cells = {}
        for c = 1, 4 do
            local t = Cell(r, c, 12, -7, c >= 3)
            t:SetTextColor(tb[1], tb[2], tb[3])
            r.cells[c] = t
        end
        r:Hide()
        v.rows[i] = r
    end
    v.empty = K.NewText(v, 13)
    v.empty:SetPoint("TOP", v, "TOP", 0, L.Y_ROWS - 60)
    v.empty:SetWidth(vw - 40)
    v.empty:SetJustifyH("CENTER")
    v.empty:SetTextColor(m[1], m[2], m[3])
    v.back = Button(v, "Zurück", L.BACK_W, L.BACK_H, function() FG.BoardBack() end)
    v.back:SetPoint("BOTTOM", v, "BOTTOM", 0, 0)
end

function FG.PaintBoard()
    local v = views.board
    if not v then return end
    local st = FG.bstate
    for _, p in ipairs(v.games) do PaintPill(p, p.key == st.game, p._hot) end
    local rk = FG.CurrentRouteKey()
    PaintPill(v.scopeAll, st.scope == "all", v.scopeAll._hot)
    PaintPill(v.scopeRoute, st.scope == "route", v.scopeRoute._hot)
    local list, empty = {}, nil
    if st.scope == "route" then
        if rk then
            v.label:SetText(FG.RouteName(rk) or "")
            list = FG.Ranking(st.game, rk)
        else
            v.label:SetText("Strecke unbekannt")
            empty = "Für diesen Flug ist die Strecke nicht bekannt – sie steht fest, wenn du am Flugmeister ein Ziel wählst."
        end
    else
        v.label:SetText(FG.NameOf(st.game) .. " · beste Punkte aller Zeiten")
        list = FG.Ranking(st.game, nil)
    end
    if not empty and #list == 0 then
        empty = "Noch keine Ergebnisse aus der Gilde."
            .. (FG.Sharing() and "" or "\nTeilen ist aus (Komfort → Flugspiele).")
    end
    local tb, acc = C.textBright, C.accentBright or C.accent
    for i, r in ipairs(v.rows) do
        local e = list[i]
        if e and not empty then
            r.cells[1]:SetText(tostring(i))
            r.cells[2]:SetText(WeintCodex.Truncate and WeintCodex.Truncate(e.name, 24) or e.name)
            r.cells[3]:SetText(tostring(e.score))
            r.cells[4]:SetText(DateText(e.t))
            local cc = (not e.own) and FG.ClassColor(e.name)
            if e.own then r.cells[2]:SetTextColor(acc[1], acc[2], acc[3])
            elseif cc then r.cells[2]:SetTextColor(cc.r, cc.g, cc.b)
            else r.cells[2]:SetTextColor(tb[1], tb[2], tb[3]) end
            r.mark:SetShown(e.own)
            r.strip:SetShown(e.own)
            r.own = e.own
            r:Show()
        else
            r.own = nil
            r:Hide()
        end
    end
    for _, h in ipairs(v.head) do h:SetShown(not empty) end
    v.empty:SetText(empty or "")
    v.empty:SetShown(empty ~= nil)
    v.list = list
end

function FG.ShowBoard(from, game)
    Build()
    FG.SeedOwn()
    local st = FG.bstate
    st.from = from or "ask"
    if game and FG.CODE[game] then st.game = game end
    win.title:SetText("Flugspiele – Bestenliste")
    win.back:Hide()
    win.note:SetText("")
    Show("board")
    FG.PaintBoard()
    win:Show()
    return true
end

function FG.BoardBack()
    if FG.bstate.from == "result" and FG.lastResult then
        win.title:SetText("Flugspiele – Ergebnis")
        Show("result")
    else
        FG.Ask(true)
    end
end

--------------------------------------------------
-- Fenster, Frage, Ergebnis
--------------------------------------------------

Build = function()
    if win then return win end
    win = CreateFrame("Frame", "WeintCodexFlightGames", UIParent)
    win:SetSize(FG.W, FG.WIN_H)
    win:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
    win:SetFrameStrata("DIALOG")
    -- 6.80.6.0 (Wunsch): fest an seinem Platz - beim Spielen verschob ein
    -- Ziehen auf dem Brett das ganze Fenster.
    win:EnableMouse(true)
    win:SetClampedToScreen(true)
    local bg = win:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(win)
    local p = C.bgPanel
    bg:SetColorTexture(p[1], p[2], p[3], 0.97)
    local a = C.accent
    K.Border(win, 1, a[1], a[2], a[3], 0.6)
    win.title = K.NewText(win, 14)
    win.title:SetPoint("TOPLEFT", win, "TOPLEFT", 16, -14)
    local t = C.textBright
    win.title:SetTextColor(t[1], t[2], t[3])
    -- 6.80.6.0 (Wunsch: Flugzeit erkennbar, nichts ueberlappt): zweite
    -- Kopfzeile nur fuer Flug und Punkte, eigene Plaetze, kein Teilen mit
    -- Hinweisen der Spiele (win.note unten).
    win.flight = K.NewText(win, 12)
    win.flight:SetPoint("TOPLEFT", win, "TOPLEFT", 16, -42)
    win.flight:SetWidth(FG.W - 150)
    win.flight:SetJustifyH("LEFT")
    win.flight:SetWordWrap(false)
    local ac = C.accent
    win.flight:SetTextColor(ac[1], ac[2], ac[3])
    win.score = K.NewText(win, 13)
    win.score:SetPoint("TOPRIGHT", win, "TOPRIGHT", -16, -42)
    win.score:SetJustifyH("RIGHT")
    local line = win:CreateTexture(nil, "ARTWORK")
    line:SetPoint("TOPLEFT", win, "TOPLEFT", 16, -60)
    line:SetPoint("TOPRIGHT", win, "TOPRIGHT", -16, -60)
    line:SetHeight(1)
    line:SetColorTexture(ac[1], ac[2], ac[3], 0.25)
    win.title:SetWidth(FG.W - 260)
    win.title:SetJustifyH("LEFT")
    win.title:SetWordWrap(false)
    win.close = Button(win, "×", 26, 22, function() FG.Close() end)
    win.close:SetPoint("TOPRIGHT", win, "TOPRIGHT", -12, -10)

    -- Frage
    local ask = View("ask")
    -- 6.79.1.0 (Beta-Test mit Bild: Erklaerungen liefen in die Knoepfe):
    -- je Spiel eine Karte - Bild, Name, Erklaerung, die ganze Karte klickbar.
    ask.text = K.NewText(ask, 15)
    ask.text:SetPoint("TOP", ask, "TOP", 0, -4)
    ask.text:SetText("Lust auf ein Spiel, bis du landest?")
    local CARD_H, GAP = 92, 10
    local m, tb, acc = C.textMuted, C.textBright, C.accent
    for i, g in ipairs(FG.GAMES) do
        local card = CreateFrame("Button", nil, ask)
        card:SetSize(FG.BOARD, CARD_H)
        card:SetPoint("TOP", ask, "TOP", 0, -36 - (i - 1) * (CARD_H + GAP))
        local bg = card:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(card)
        local s1 = C.surface1 or C.bgCard
        bg:SetColorTexture(s1[1], s1[2], s1[3], 1)
        local strip = card:CreateTexture(nil, "BORDER")
        strip:SetPoint("TOPLEFT") strip:SetPoint("BOTTOMLEFT")
        strip:SetWidth(3)
        strip:SetColorTexture(acc[1], acc[2], acc[3], 1)
        local hl = card:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints(card)
        hl:SetColorTexture(1, 1, 1, 0.06)
        local pic = CreateFrame("Frame", nil, card)
        pic:SetSize(60, 60)
        pic:SetPoint("LEFT", card, "LEFT", 16, 0)
        local pbg = pic:CreateTexture(nil, "BACKGROUND")
        pbg:SetAllPoints(pic)
        local s2 = C.surface2 or C.bgPanel
        pbg:SetColorTexture(s2[1], s2[2], s2[3], 1)
        if g.key == "jewels" then
            for j, mk in ipairs({ 7, 6, 4, 1 }) do
                local d = pic:CreateTexture(nil, "ARTWORK")
                d:SetTexture(K.MEDIA .. "diamond")
                d:SetSize(24, 24)
                d:SetPoint("TOPLEFT", pic, "TOPLEFT", 5 + ((j - 1) % 2) * 26, -5 - math.floor((j - 1) / 2) * 26)
                local c = GC["raidMark" .. mk]
                d:SetVertexColor(c[1], c[2], c[3], 1)
            end
        elseif g.key == "mahjong" then
            local face, side = GC.tileFace, GC.tileSide
            local sd = pic:CreateTexture(nil, "ARTWORK", nil, 1)
            sd:SetColorTexture(side[1], side[2], side[3], 1)
            sd:SetSize(36, 46) sd:SetPoint("CENTER", pic, "CENTER", 3, -3)
            local tf = pic:CreateTexture(nil, "ARTWORK", nil, 2)
            tf:SetColorTexture(face[1], face[2], face[3], 1)
            tf:SetSize(36, 46) tf:SetPoint("CENTER", pic, "CENTER", 0, 0)
            local n = K.NewText(pic, 22)
            n:SetPoint("CENTER", pic, "CENTER", 0, 2)
            n:SetText("8")
            local r = GC.raidMark7
            n:SetTextColor(r[1], r[2], r[3])
        else
            local h = pic:CreateTexture(nil, "ARTWORK")
            h:SetTexture(FG.HUHN)
            h:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            h:SetPoint("TOPLEFT", pic, "TOPLEFT", 4, -4)
            h:SetPoint("BOTTOMRIGHT", pic, "BOTTOMRIGHT", -4, 4)
        end
        local name = K.NewText(card, 15)
        name:SetPoint("TOPLEFT", pic, "TOPRIGHT", 14, -2)
        name:SetText(g.name)
        name:SetTextColor(tb[1], tb[2], tb[3])
        local hint = K.NewText(card, 11)
        hint:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -6)
        hint:SetWidth(FG.BOARD - 106)
        hint:SetJustifyH("LEFT")
        hint:SetText(g.hint)
        hint:SetTextColor(m[1], m[2], m[3])
        card:SetScript("OnClick", function() FG.Play(g.key) end)
    end
    ask.best = K.NewText(ask, 11)
    ask.best:SetPoint("TOP", ask, "TOP", 0, -36 - 3 * (CARD_H + GAP) - 6)
    ask.best:SetWidth(FG.BOARD)
    local no = Button(ask, "Nein danke", 150, 28, function() FG.Close() end)
    no:SetPoint("BOTTOMLEFT", ask, "BOTTOMLEFT", 0, 0)
    local never = Button(ask, "Nicht mehr fragen", 170, 28, function()
        K.Set(KEY, "flightGamesAsk", false)
        FG.Close()
        print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " Keine Frage mehr beim Fliegen. Spielen geht weiter mit /wcui spiele; wieder fragen: Komfort → Flugspiele.")
    end)
    never:SetPoint("BOTTOMRIGHT", ask, "BOTTOMRIGHT", 0, 0)
    -- 6.89.0.0: eigene Zeile ueber "Nein danke" / "Nicht mehr fragen".
    ask.board = Button(ask, "Bestenliste der Gilde", 180, 28, function() FG.ShowBoard("ask") end)
    ask.board:SetPoint("BOTTOM", ask, "BOTTOM", 0, 40)

    -- Ergebnis
    local res = View("result")
    res.text = K.NewText(res, 14)
    res.text:SetPoint("TOP", res, "TOP", 0, -30)
    res.text:SetWidth(FG.W - 60)
    res.text:SetSpacing(6)
    res.guild = Button(res, "Der Gilde zeigen", 180, 30, function() FG.ToGuild() end)
    res.guild:SetPoint("BOTTOM", res, "BOTTOM", -100, 20)
    res.ok = Button(res, "Schließen", 140, 30, function() FG.Close() end)
    res.ok:SetPoint("BOTTOM", res, "BOTTOM", 100, 20)
    -- 6.89.0.0: eigene Zeile ueber den beiden Knoepfen.
    res.board = Button(res, "Bestenliste", 160, 28, function()
        local first = FG.lastResult and FG.lastResult[1]
        FG.ShowBoard("result", first and first.key)
    end)
    res.board:SetPoint("BOTTOM", res, "BOTTOM", 0, 60)

    BuildJewels()
    BuildMahjong()
    BuildHunt()
    BuildBoardView()
    win.note = K.NewText(win, 11)
    win.note:SetPoint("BOTTOM", win, "BOTTOM", 0, 14)

    -- 6.79.0.0 (Wunsch: "Ton muten"): Knopf unten links, gleicher Schalter
    -- wie in den Einstellungen (Komfort -> Flugspiele -> Toene).
    win.mute = Button(win, "", 72, 22, function()
        K.Set(KEY, "flightGamesSound", K.Get(KEY, "flightGamesSound") == false)
        FG.PaintMute()
    end)
    win.mute:SetPoint("TOPRIGHT", win, "TOPRIGHT", -44, -10)
    -- Zurueck zur Auswahl waehrend des Spiels.
    win.back = Button(win, "Anderes Spiel", 120, 22, function() FG.Ask(true) end)
    win.back:SetSize(108, 22)
    win.back:SetPoint("TOPRIGHT", win, "TOPRIGHT", -122, -10)
    local acc = 1
    win:SetScript("OnUpdate", function(_, el)
        acc = acc + el
        if acc < 1 then return end
        acc = 0
        FG.PaintFlight()
    end)
    win:Hide()
    table.insert(_G.UISpecialFrames or {}, "WeintCodexFlightGames")
    FG.win = win
    return win
end

-- Kopfzeile: "Flug nach Eisenschmiede · 1:23 min" (live, einmal je Sekunde).
function FG.FlightLine(now)
    local f = FG.flight
    if not (f and f.on) then return "" end
    local secs = (type(now) == "number" and type(f.start) == "number") and (now - f.start) or nil
    local d = FG.Duration(secs)
    local where = f.to and ("Flug nach " .. f.to) or "Im Flug"
    return d and (where .. " · " .. d) or where
end
function FG.PaintFlight()
    if not (win and win.flight) then return end
    win.flight:SetText(FG.FlightLine(_G.GetTime and K.Plain(_G.GetTime()) or nil))
end

function FG.PaintMute()
    if win and win.mute then
        win.mute.text:SetText(K.Get(KEY, "flightGamesSound") == false and "Ton: aus" or "Ton: an")
    end
end

function FG.Ask(force)
    Build()
    local best = FG.Best()
    local parts = {}
    for _, g in ipairs(FG.GAMES) do
        if best and best[g.key] then parts[#parts + 1] = g.name .. " " .. best[g.key] end
    end
    views.ask.best:SetText(#parts > 0 and ("Bestwerte: " .. table.concat(parts, " · ")) or "")
    win.title:SetText("Flugspiele")
    FG.PaintFlight()
    win.back:Hide()
    win.note:SetText("")
    FG.PaintMute()
    Show("ask")
    win:Show()
    return true
end

function FG.Play(key)
    Build()
    local f = FG.flight
    f.game, f.points = key, 0
    win.title:SetText(FG.NameOf(key))
    FG.PaintFlight()
    win.score:SetText("0 Punkte")
    win.back:Show()
    win.note:SetText("")
    Show(key)
    if key == "jewels" then J.Start() elseif key == "mahjong" then M.Start() else H.Start() end
    win:Show()
end

function FG.Close()
    if win then win:Hide() end
    if FG.flight.game and not FG.flight.on then FG.Record() end
end

-- Bestwerte eintragen. Liefert die Liste fuer das Ergebnis.
function FG.Record()
    local best = FG.Best(true)
    local out = {}
    for _, g in ipairs(FG.GAMES) do
        local s = FG.flight.scores[g.key]
        if s and s > 0 then
            local rec = best and (best[g.key] or 0) < s
            if rec then best[g.key] = s end
            out[#out + 1] = { key = g.key, name = g.name, score = s, record = rec, best = best and best[g.key] }
            pcall(FG.Submit, g.key, s, FG.flight.fromID, FG.flight.toID, FG.flight.secs)
        end
    end
    FG.flight.scores, FG.flight.game, FG.flight.points = {}, nil, 0
    return out
end

function FG.Result(list)
    Build()
    FG.lastResult = list
    local lines = {}
    for _, r in ipairs(list) do
        lines[#lines + 1] = r.name .. ": " .. r.score .. " Punkte" .. (r.record and "  – neuer Bestwert!" or ("  (Bestwert " .. tostring(r.best) .. ")"))
        local rank = FG.RankLine(r.key)
        if rank then lines[#lines + 1] = rank end
    end
    local f = FG.flight
    local route = FG.Route()
    views.result.text:SetText("Gelandet" .. (f.to and (" in " .. f.to) or "") .. "!"
        .. (route and ("\n" .. route) or "") .. "\n\n" .. table.concat(lines, "\n"))
    local guild = _G.IsInGuild and K.Bool(_G.IsInGuild(), false)
    views.result.guild:SetShown(guild and true or false)
    win.title:SetText("Flugspiele – Ergebnis")
    win.back:Hide()
    win.score:SetText("")
    Show("result")
    win:Show()
end

-- "Platz 2 in der Gilde (alle Zeiten) · Platz 1 auf dieser Strecke" -
-- nur, was bekannt ist; allein ohne andere Eintraege nichts.
function FG.RankLine(game)
    local a = FG.RankOf(game, nil)
    local rk = FG.CurrentRouteKey()
    local b = rk and FG.RankOf(game, rk)
    local nA, nB = #FG.Ranking(game, nil), rk and #FG.Ranking(game, rk) or 0
    local parts = {}
    if a and nA > 1 then parts[#parts + 1] = "Platz " .. a .. " in der Gilde (alle Zeiten)" end
    if b and nB > 1 then parts[#parts + 1] = "Platz " .. b .. " auf dieser Strecke" end
    if #parts == 0 then return nil end
    return "   " .. table.concat(parts, " · ")
end

-- Eine Zeile in die Chatzeile - Enter schickt sie, der Spieler entscheidet.
-- "Flug Sturmwind nach Eisenschmiede, 2:31 min" - was bekannt ist.
function FG.Route()
    local f = FG.flight
    local out
    if f.from and f.to and f.from ~= f.to then out = "Flug " .. f.from .. " nach " .. f.to
    elseif f.to then out = "Flug nach " .. f.to end
    local d = FG.Duration(f.secs)
    if d then out = (out or "Flug") .. ", " .. d end
    return out
end

function FG.GuildLine(list)
    local parts = {}
    for _, r in ipairs(list or {}) do
        parts[#parts + 1] = r.score .. " Punkte in " .. r.name .. (r.record and " (neuer Bestwert)" or "")
    end
    if #parts == 0 then return nil end
    local route = FG.Route()
    return "/g " .. (route and (route .. " – ") or "") .. "Flugspiele: " .. table.concat(parts, ", ") .. "!"
end

function FG.ToGuild()
    local line = FG.GuildLine(FG.lastResult)
    if not line then return false end
    local open = (_G.ChatFrameUtil and _G.ChatFrameUtil.OpenChat) or _G.ChatFrame_OpenChat
    if open then pcall(open, line) end
    FG.Close()
    return true
end

--------------------------------------------------
-- Abflug und Landung
--------------------------------------------------

local function OnTaxi() return _G.UnitOnTaxi and K.Bool(_G.UnitOnTaxi("player"), false) or false end

-- 6.78.2.0 (Wunsch: "im Gildenpost von wo nach wo, Flugzeit, Punkte"):
-- Start und Ziel aus der Flugkarte, wenn der Spieler dort klickt
-- (TakeTaxiNode, nur mitgelesen), sonst der Ort beim Abheben und Landen.
local function Place(name)
    name = K.Plain(name)
    if type(name) ~= "string" or name == "" then return nil end
    return (name:gsub(",.*$", ""))
end
FG.Place = Place

local function HereName()
    local f = _G.GetMinimapZoneText or _G.GetSubZoneText
    local n = f and Place(f())
    if not n and _G.GetZoneText then n = Place(_G.GetZoneText()) end
    return n
end

function FG.NoteTaxi(index)
    local from, to
    if _G.TaxiNodeName then to = Place(select(2, pcall(_G.TaxiNodeName, index))) end
    if _G.NumTaxiNodes and _G.TaxiNodeGetType and _G.TaxiNodeName then
        local ok, n = pcall(_G.NumTaxiNodes)
        for i = 1, (ok and K.Plain(n) or 0) do
            if K.Plain(_G.TaxiNodeGetType(i)) == "CURRENT" then from = Place(_G.TaxiNodeName(i)) break end
        end
    end
    local okI, fromID, toID = pcall(FG.TaxiIDs, index)
    if not okI then fromID, toID = nil, nil end
    FG.pending = { from = from, to = to, fromID = fromID, toID = toID, at = _G.GetTime and K.Plain(_G.GetTime()) or 0 }
end
if type(_G.TakeTaxiNode) == "function" and _G.hooksecurefunc then
    pcall(_G.hooksecurefunc, "TakeTaxiNode", function(i) pcall(FG.NoteTaxi, i) end)
end

-- 6.89.0.0: Knotennummern der Flugkarte (fuer die Bestenliste je Strecke);
-- Namen der Knoten merkt sich die Bestenliste. Ohne Antwort nil.
function FG.TaxiIDs(index)
    local TM = _G.C_TaxiMap
    if not (TM and TM.GetAllTaxiNodes and _G.GetTaxiMapID) then return nil end
    local okM, mid = pcall(_G.GetTaxiMapID)
    mid = okM and K.Plain(mid)
    if type(mid) ~= "number" then return nil end
    local ok, nodes = pcall(TM.GetAllTaxiNodes, mid)
    if not ok or type(nodes) ~= "table" then return nil end
    local from, to
    for _, n in ipairs(nodes) do
        local id, slot, st = K.Plain(n.nodeID), K.Plain(n.slotIndex), K.Plain(n.state)
        if type(id) == "number" and id >= 1 and id <= FG.NODE_MAX then
            FG.NoteNode(id, Place(n.name))
            if slot == index then to = id end
            if st == 0 then from = id end   -- Enum.FlightPathState.Current
        end
    end
    return from, to
end

-- "2:31 min" bzw. "45 s".
function FG.Duration(sec)
    if type(sec) ~= "number" or sec < 0 then return nil end
    sec = math.floor(sec + 0.5)
    if sec < 60 then return sec .. " s" end
    return string.format("%d:%02d min", math.floor(sec / 60), sec % 60)
end

function FG.Takeoff()
    if FG.flight.on or not OnTaxi() then return false end
    local f = FG.flight
    f.on, f.scores, f.game, f.points = true, {}, nil, 0
    local now = _G.GetTime and K.Plain(_G.GetTime()) or 0
    local pend = FG.pending
    local fresh = pend and type(now) == "number" and now - (pend.at or 0) < 30
    f.from = (fresh and pend.from) or HereName()
    f.to = fresh and pend.to or nil
    f.fromID, f.toID = fresh and pend.fromID or nil, fresh and pend.toID or nil
    FG.lastRouteKey = FG.RouteKey(f.fromID, f.toID)
    f.start = now
    FG.pending = nil
    if not FG.Active() or K.Get(KEY, "flightGamesAsk") == false then return false end
    return FG.Ask()
end

function FG.Landing()
    if not FG.flight.on or OnTaxi() then return false end
    local f = FG.flight
    f.on = false
    f.to = f.to or HereName()
    local now = _G.GetTime and K.Plain(_G.GetTime()) or nil
    f.secs = (type(now) == "number" and type(f.start) == "number") and (now - f.start) or nil
    local played = FG.flight.game ~= nil or _G.next(FG.flight.scores) ~= nil
    if not played then
        if win then win:Hide() end
        return false
    end
    local list = FG.Record()
    f.fromID, f.toID = nil, nil   -- spaeter Gespieltes (/wcui spiele) zaehlt nicht fuer diese Strecke
    if #list == 0 then
        if win then win:Hide() end
        return false
    end
    FG.Result(list)
    return true
end

local ev = CreateFrame("Frame")
FG.events = ev
for _, e in ipairs({ "PLAYER_CONTROL_LOST", "PLAYER_CONTROL_GAINED", "PLAYER_ENTERING_WORLD", "CHAT_MSG_ADDON", "GUILD_ROSTER_UPDATE" }) do
    pcall(ev.RegisterEvent, ev, e)
end
ev:SetScript("OnEvent", function(_, event, a, b, c, d)
    if event == "CHAT_MSG_ADDON" then
        if a == FG.PREFIX then pcall(FG.OnAddonMessage, a, b, c, d) end
        return
    elseif event == "GUILD_ROSTER_UPDATE" then
        pcall(FG.ScanRoster)
        return
    end
    local later = _G.C_Timer and _G.C_Timer.After
    if event == "PLAYER_ENTERING_WORLD" and not FG.requestTimer then
        FG.requestTimer = true
        local cc = _G.C_ChatInfo
        if cc and cc.RegisterAddonMessagePrefix then pcall(cc.RegisterAddonMessagePrefix, FG.PREFIX) end
        if later then later(40, function() pcall(FG.Request) end) end
        if _G.C_Timer and _G.C_Timer.NewTicker then
            _G.C_Timer.NewTicker(FG.REQUEST_EVERY, function() pcall(FG.Request) end)
        end
    end
    if event == "PLAYER_CONTROL_LOST" then
        if later then later(1, function() pcall(FG.Takeoff) end) else pcall(FG.Takeoff) end
    else
        if later then later(0.5, function() pcall(FG.Landing) end) else pcall(FG.Landing) end
    end
end)

--------------------------------------------------
-- Seite im Komfort
--------------------------------------------------

local function BuildPage(B)
    B:Section("Flugspiele", "Während du mit dem Greifen, Hippogryphen oder Windreiter fliegst: ein kleines Spiel. Am Ende des Fluges stehen deine Punkte und dein Bestwert da – auf Wunsch als Zeile für den Gildenchat.")
    B:Row({ type = "toggle", label = "Flugspiele", key = "flightGames",
            description = "Aus: kein Fenster, keine Frage. /wcui spiele öffnet die Auswahl jederzeit." },
          { type = "toggle", label = "Beim Abflug fragen", key = "flightGamesAsk",
            disabled = function() return K.Get(KEY, "flightGames") == false end,
            description = "Beim Abheben fragt ein kleines Fenster, ob du spielen willst. Aus: nur über /wcui spiele." })
    B:Row({ type = "button", label = "Ausprobieren", text = "Spiele jetzt öffnen", onClick = function() FG.Ask(true) end },
          { type = "toggle", label = "Töne", key = "flightGamesSound",
            disabled = function() return K.Get(KEY, "flightGames") == false end,
            description = "Gackern, Piepen und Bumm in der Hühnerjagd." })
    B:Row({ type = "toggle", label = "Bestenliste mit der Gilde teilen", key = "flightGamesShare",
            disabled = function() return K.Get(KEY, "flightGames") == false end,
            description = "Schickt nach jedem Spiel nur Spiel, Punkte, Flugstrecke und Flugdauer an die Gilde und empfängt deren Bestwerte. Aus: die Bestenliste zeigt nur dich." })
    B:Note("„Der Gilde zeigen“ schreibt die Zeile nur in die Chatzeile – erst Enter schickt sie ab.")
end
FG.BuildPage = BuildPage

local mod = K.Module(KEY)
if mod then
    if mod.defaults.flightGames == nil then mod.defaults.flightGames = true end
    if mod.defaults.flightGamesAsk == nil then mod.defaults.flightGamesAsk = true end
    if mod.defaults.flightGamesSound == nil then mod.defaults.flightGamesSound = true end
    if mod.defaults.flightGamesShare == nil then mod.defaults.flightGamesShare = true end
    mod.pages[#mod.pages + 1] = { key = "flugspiele", label = "Flugspiele", build = BuildPage }
    if type(mod.pageOrder) == "table" then mod.pageOrder.flugspiele = 33 end
end
