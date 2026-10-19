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

FG.DEFAULTS = { flightGames = true }
FG.GAMES = {
    { key = "jewels",  name = "Juwelen",     hint = "Zwei Nachbarn tauschen – drei Gleiche in einer Reihe verschwinden." },
    { key = "mahjong", name = "Mahjong",     hint = "Zwei gleiche freie Steine anklicken. Frei ist ein Stein ohne Stein darauf und mit freier linker oder rechter Seite." },
    { key = "hunt",    name = "Hühnerjagd",  hint = "Hühner anklicken: Küken und Goldhuhn bringen viel, Zombiehühner brauchen zwei Treffer – Finger weg vom roten Bombenhuhn!" },
}
FG.W, FG.WIN_H = 440, 544   -- nicht FG.H: das ist die Huehnerjagd
FG.BOARD = 400
FG.HUHN = "Interface\\Icons\\Spell_Magic_PolymorphChicken"

local win, views = nil, {}
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
FG.J = J

local function JColor(kind) return GC["raidMark" .. ({ 7, 2, 1, 4, 6, 3 })[kind]] end

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
            local col = JColor(kind)
            if col then cell.gem:SetVertexColor(col[1], col[2], col[3], 1) end
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
            b.gem:SetTexture(K.MEDIA .. "diamond")
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
-- Fenster, Frage, Ergebnis
--------------------------------------------------

local function Build()
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

    BuildJewels()
    BuildMahjong()
    BuildHunt()
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
    FG.pending = { from = from, to = to, at = _G.GetTime and K.Plain(_G.GetTime()) or 0 }
end
if type(_G.TakeTaxiNode) == "function" and _G.hooksecurefunc then
    pcall(_G.hooksecurefunc, "TakeTaxiNode", function(i) pcall(FG.NoteTaxi, i) end)
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
    if #list == 0 then
        if win then win:Hide() end
        return false
    end
    FG.Result(list)
    return true
end

local ev = CreateFrame("Frame")
FG.events = ev
for _, e in ipairs({ "PLAYER_CONTROL_LOST", "PLAYER_CONTROL_GAINED", "PLAYER_ENTERING_WORLD" }) do
    pcall(ev.RegisterEvent, ev, e)
end
ev:SetScript("OnEvent", function(_, event)
    local later = _G.C_Timer and _G.C_Timer.After
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
    B:Note("„Der Gilde zeigen“ schreibt die Zeile nur in die Chatzeile – erst Enter schickt sie ab.")
end
FG.BuildPage = BuildPage

local mod = K.Module(KEY)
if mod then
    if mod.defaults.flightGames == nil then mod.defaults.flightGames = true end
    if mod.defaults.flightGamesAsk == nil then mod.defaults.flightGamesAsk = true end
    if mod.defaults.flightGamesSound == nil then mod.defaults.flightGamesSound = true end
    mod.pages[#mod.pages + 1] = { key = "flugspiele", label = "Flugspiele", build = BuildPage }
    if type(mod.pageOrder) == "table" then mod.pageOrder.flugspiele = 33 end
end
