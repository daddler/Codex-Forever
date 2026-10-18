--------------------------------------------------
-- WeintCodex :: Komfort - Haendlerfenster gross ziehen (6.38.0.0)
--------------------------------------------------
-- Der Haendler (MerchantFrame) laesst sich unten rechts an einem Griff
-- groesser ziehen; so viele Waren, wie hineinpassen, stehen nebeneinander
-- und untereinander - kein Blaettern mehr, solange alles passt. Die Groesse
-- merkt sich der Komfort (vendorW/vendorH); kleiner als das Fenster des
-- Spiels wird es nie.
--
-- Gewuenscht nach dem Vorbild von Extended Vendor Forever (ohne Lizenz,
-- also "alle Rechte vorbehalten"): Verhalten nachgebaut, kein Code
-- uebernommen.
--
-- Wie: das Spiel zeigt je Seite MERCHANT_ITEMS_PER_PAGE Waren an den
-- Plaetzen MerchantItem1..n. Vor jedem Aufbau setzt dieses Modul die Zahl
-- passend zur Groesse, legt fehlende Plaetze aus der Vorlage des Spiels an
-- und ordnet sie danach als Raster. Kaufen, Tooltip, Preise, Rueckkauf
-- bleiben die des Spiels. Abstaende und Fuss werden beim ersten Oeffnen am
-- Fenster des Spiels gemessen, nicht geraten.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIMerchantSize = {}

local MS = WeintCodex.UIMerchantSize
local K  = WeintCodex.UIKit
local KEY = "comfort"

MS.MAX = 60                 -- so viele Plaetze hoechstens
MS.BUYBACK = 12             -- Rueckkauf: immer zwoelf, wie im Spiel
MS.GAP = 8                  -- Luft zwischen zwei Plaetzen
MS.FALLBACK = { dx = 165, dy = 45, x = 11, y = -69 }

local st = { cols = 2, per = nil }
MS.state = st

function MS.Active()
    return K.IsActive(KEY) and K.Get(KEY, "vendorGrow") ~= false
end

local function F() return _G.MerchantFrame end
local function Item(i) return _G["MerchantItem" .. i] end

-- Einmal am Fenster des Spiels messen: Groesse, Lage der ersten Ware,
-- Abstand zur naechsten Spalte und Zeile, Fuss unter den Waren.
function MS.Measure()
    if st.native then return st.native end
    local f, a, b, c = F(), Item(1), Item(2), Item(3)
    if not (f and a) then return nil end
    local n = { w = f:GetWidth(), h = f:GetHeight() }
    local fl, ft = f:GetLeft(), f:GetTop()
    local al, at = a:GetLeft(), a:GetTop()
    if type(fl) == "number" and type(al) == "number" and type(ft) == "number" and type(at) == "number" then
        n.x, n.y = al - fl, at - ft
    else
        n.x, n.y = MS.FALLBACK.x, MS.FALLBACK.y
    end
    local bl, ct = b and b:GetLeft(), c and c:GetTop()
    n.dx = (type(bl) == "number" and type(al) == "number" and bl - al > 20) and (bl - al) or MS.FALLBACK.dx
    n.dy = (type(ct) == "number" and type(at) == "number" and at - ct > 20) and (at - ct) or MS.FALLBACK.dy
    -- 6.38.2.0 (Beta-Test: Zeilen lagen aufeinander): nie enger als der
    -- Platz selbst plus Luft, Spalten ebenso.
    n.rawDy = n.dy
    local ih, iw = a:GetHeight(), a:GetWidth()
    if type(ih) == "number" and ih > 0 then n.dy = math.max(n.dy, ih + MS.GAP) end
    if type(iw) == "number" and iw > 0 then n.dx = math.max(n.dx, iw + MS.GAP) end
    n.iw, n.ih = a:GetWidth(), a:GetHeight()
    if not (type(n.w) == "number" and n.w > 100 and type(n.h) == "number" and n.h > 100) then return nil end
    -- Fuss: was unter fuenf Zeilen bleibt (Rueckkauf-Platz, Geld, Reiter).
    n.foot = n.h + n.y - 5 * n.rawDy
    -- Feste Teile unten: an der Ecke halten, an der sie stehen.
    n.pins = {}
    for _, name in ipairs({ "MerchantBuyBackItem", "MerchantPrevPageButton", "MerchantNextPageButton", "MerchantPageText" }) do
        local r = _G[name]
        if r and r.GetCenter then
            local x, y = r:GetCenter()
            local fx, fb = f:GetLeft(), f:GetBottom()
            if type(x) == "number" and type(y) == "number" and type(fx) == "number" and type(fb) == "number" then
                local right = (x - fx) > n.w * 0.6
                -- Nur, was wirklich im Fuss steht: der Rueckkauf-Platz hing im
                -- Spiel an Ware 10 und landete gross gezogen mitten im Fenster.
                if y - fb > n.foot + 10 then y = fb + n.foot - 20 end
                n.pins[#n.pins + 1] = { r = r, right = right, x = right and (x - fx - n.w) or (x - fx), y = y - fb }
            end
        end
    end
    st.native = n
    return n
end

-- Spalten und Zeilen fuer die jetzige Groesse.
function MS.Grid()
    local n, f = st.native, F()
    if not (n and f) then return 2, 5 end
    -- Rand rechts wie im Spiel: dort stehen zwei Spalten.
    local margin = n.w - n.x - n.dx - n.iw
    local cols = math.max(2, math.floor((f:GetWidth() - n.x - n.iw - margin) / n.dx + 1e-6) + 1)
    local rows = math.max(5, math.floor((f:GetHeight() + n.y - n.foot) / n.dy))
    return cols, rows
end

-- Vor dem Aufbau des Spiels: Zahl je Seite setzen, Plaetze anlegen.
function MS.Prepare()
    if not (MS.Active() and MS.Measure()) then return end
    local cols, rows = MS.Grid()
    local per = math.min(MS.MAX, cols * rows)
    st.cols, st.per = cols, per
    for i = 1, math.max(per, MS.BUYBACK) do
        if not Item(i) then
            local ok = pcall(CreateFrame, "Frame", "MerchantItem" .. i, F(), "MerchantItemTemplate")
            if not ok then st.per = i - 1 break end
        end
    end
    -- 6.67.1.0: nur schreiben, wenn sich die Zahl wirklich aendert - jede
    -- Zuweisung macht die Zahl "tainted", und der Code des Haendlers, der
    -- sie liest, laeuft danach als Addon-Code. In Spielgroesse (10) bleibt
    -- sie so unberuehrt.
    if K.Plain(_G.MERCHANT_ITEMS_PER_PAGE) ~= st.per then _G.MERCHANT_ITEMS_PER_PAGE = st.per end
    -- 6.67.1.0: MerchantFrame.page nicht mehr selbst setzen - ein Feld des
    -- Haendlers, aus Addon-Code geschrieben, ist "tainted", und der Klick in
    -- die Tasche liest den Haendler (Verdacht beim Fehlerbericht
    -- "Verboten: UseContainerItem()"). Eine Seite hinter dem Ende zeigt das
    -- Spiel leer; die Pfeile fuehren zurueck.
end

-- Nach dem Aufbau: Raster ab der ersten Ware, ueberzaehlige verbergen.
function MS.Layout()
    local n, f = st.native, F()
    if not (n and f and st.per and MS.Active()) then return end
    local buyback = K.Plain(f.selectedTab) == 2
    local shown = buyback and MS.BUYBACK or st.per
    if not buyback then
        -- Leere Plaetze am Ende nicht zeigen: im Raster sahen sie aus wie
        -- verstreute Kaesten (Beta-Test 6.38.0.0).
        local total = K.Plain(_G.GetMerchantNumItems and _G.GetMerchantNumItems())
        local page = K.Plain(f.page)
        if type(total) == "number" then
            local first = ((type(page) == "number" and page or 1) - 1) * st.per
            shown = math.max(0, math.min(shown, total - first))
        end
    end
    local cols = st.cols
    for i = 1, MS.MAX do
        local it = Item(i)
        if not it then break end
        local col, row = (i - 1) % cols, math.floor((i - 1) / cols)
        it:ClearAllPoints()
        it:SetPoint("TOPLEFT", f, "TOPLEFT", n.x + col * n.dx, n.y - row * n.dy)
        -- 6.38.3.0 (Beta-Test: nach "Weiter" und "Zurueck" nur noch zwei
        -- Waren): das Spiel zeigt verborgene Plaetze nie wieder - also selbst.
        if i > shown then it:Hide() else it:Show() end
    end
    for _, p in ipairs(n.pins) do
        p.r:ClearAllPoints()
        p.r:SetPoint("CENTER", f, p.right and "BOTTOMRIGHT" or "BOTTOMLEFT", p.x, p.y)
    end
end

-- Spalten fuer die Flaeche hinter den Waren (ui/merchant.lua).
function MS.Columns() return (MS.Active() and st.per) and st.cols or 2 end

local function Refresh()
    if _G.MerchantFrame_Update then _G.MerchantFrame_Update() end
end

local function Save()
    local f = F()
    if not f then return end
    K.Set(KEY, "vendorW", math.floor(f:GetWidth() + 0.5))
    K.Set(KEY, "vendorH", math.floor(f:GetHeight() + 0.5))
end

local grip
local function Grip(f)
    grip = CreateFrame("Button", nil, f)
    grip:SetSize(16, 16)
    grip:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -3, 3)
    grip:SetFrameLevel(f:GetFrameLevel() + 20)
    grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    local function Stop()
        if not st.sizing then return end
        st.sizing = nil
        f:StopMovingOrSizing()
        Save()
        Refresh()
    end
    grip:SetScript("OnMouseDown", function(_, button)
        if button ~= "LeftButton" or not MS.Active() then return end
        st.sizing = true
        f:StartSizing("BOTTOMRIGHT")
    end)
    grip:SetScript("OnMouseUp", Stop)
    grip:SetScript("OnHide", Stop)
end

-- Beim Ziehen neu ordnen, sobald eine Spalte oder Zeile dazukommt.
local function OnSize()
    if not (st.sizing and st.native) then return end
    local cols, rows = MS.Grid()
    if math.min(MS.MAX, cols * rows) ~= st.per or cols ~= st.cols then Refresh() end
end

local hooked = false
function MS.Start()
    local f = F()
    if hooked or not (f and MS.Active()) then return end
    if not MS.Measure() then return end
    hooked = true
    local n = st.native
    f:SetResizable(true)
    local maxW = (UIParent and UIParent:GetWidth() or 1600) - 40
    local maxH = (UIParent and UIParent:GetHeight() or 900) - 40
    if f.SetResizeBounds then
        f:SetResizeBounds(n.w, n.h, math.max(n.w, maxW), math.max(n.h, maxH))
    elseif f.SetMinResize then
        f:SetMinResize(n.w, n.h)
    end
    Grip(f)
    f:HookScript("OnSizeChanged", OnSize)
    if _G.hooksecurefunc then
        for _, fn in ipairs({ "MerchantFrame_UpdateMerchantInfo", "MerchantFrame_UpdateBuybackInfo" }) do
            if type(_G[fn]) == "function" then _G.hooksecurefunc(fn, MS.Layout) end
        end
    end
    MS.Apply()
end

-- Gemerkte Groesse anlegen (nie kleiner als das Fenster des Spiels).
function MS.Apply()
    local f, n = F(), st.native
    if not (f and n and hooked) then return end
    if not MS.Active() then return end
    local w = math.max(n.w, tonumber(K.Get(KEY, "vendorW")) or n.w)
    local h = math.max(n.h, tonumber(K.Get(KEY, "vendorH")) or n.h)
    f:SetSize(w, h)
end

-- MERCHANT_SHOW kommt vor dem Aufbau des Spiels? Nicht verlassen: das
-- Spiel baut in OnShow auf. Darum vor jedem Aufbau ueber den Haken an
-- MerchantFrame_Update vorbereiten - und danach noch einmal aufbauen.
local ev = CreateFrame("Frame")
pcall(ev.RegisterEvent, ev, "MERCHANT_SHOW")
ev:SetScript("OnEvent", function()
    if not MS.Active() then return end
    MS.Start()
    if not hooked then return end
    MS.Apply()
    MS.Prepare()
    Refresh()
end)

-- Jede Aenderung der Groesse oder Seite laeuft ueber MerchantFrame_Update;
-- die Zahl je Seite muss davor stimmen. Ein Haken danach setzt sie fuer den
-- naechsten Aufbau und baut nur neu, wenn sie sich geaendert hat.
if _G.hooksecurefunc and type(_G.MerchantFrame_Update) == "function" then
    _G.hooksecurefunc("MerchantFrame_Update", function()
        if not (hooked and MS.Active()) then return end
        local before = st.per
        MS.Prepare()
        if st.per ~= before and not st.again then
            st.again = true
            Refresh()
            st.again = nil
        else
            MS.Layout()
        end
    end)
end

function MS.StatusLine()
    local n = st.native
    return string.format("Händlerfenster: %s · gemessen %s · %d Spalten · %s Waren je Seite",
        MS.Active() and "groß ziehbar" or "aus", n and "ja" or "noch nicht", st.cols or 0, tostring(st.per or "-"))
end

local mod = K.Module(KEY)
if mod then
    -- 6.79.0.0: ab Werk aus. Zweiter Fehlerbericht "Verboten: UseContainerItem()"
    -- mit Taint-Bericht: MerchantFrame.itemIndex und .selectedTab "tainted
    -- (WeintCodex)" - der Klick in die Tasche liest sie. Das Vergroessern
    -- muss die Seite des Haendlers neu aufbauen (MerchantFrame_Update aus
    -- Addon-Code), und alles, was der Aufbau dann schreibt, ist tainted.
    -- Wer es will, schaltet es ein - mit Hinweis.
    if mod.defaults.vendorGrow == nil then mod.defaults.vendorGrow = false end
    local page = mod.pages and mod.pages[1]
    if page then
        local build = page.build
        page.build = function(B)
            build(B)
            B:Section("Händlerfenster")
            B:Row({ type = "toggle", label = "Händlerfenster groß ziehen", key = "vendorGrow", reload = true,
                    description = "Am Griff unten rechts größer ziehen: alle Waren auf einen Blick, ohne Blättern. Achtung: solange ein Händler offen war, kann ein Klick in die Taschen „Verboten“ melden – dann bitte ausschalten und neu laden." },
                  { type = "empty" })
        end
    end
end
