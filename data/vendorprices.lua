--------------------------------------------------
-- WeintCodex :: Händlerpreise für Handwerkswaren (1.4.0.0)
--------------------------------------------------
-- Was ein Händler für Fäden, Phiolen, Salz, Farbstoffe … verlangt (Kupfer je
-- Stück). Für den Gewinn je Rezept (modules/proftools.lua, Werkzeug
-- "Gewinn"): ohne diese Preise wäre jedes Rezept mit Faden "Preis unbekannt",
-- weil niemand Faden im Auktionshaus kauft.
--
-- HERKUNFT `community` (nur für Betreuer: aus Naowh Forever Professions,
-- dort aus den Clienttabellen erzeugt - übernommen sind nur die Zahlen).
-- Ein selbst gesehener Händlerpreis (SavedData.vendorSeen) geht immer vor.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.VendorPrices = {
    [159] = 5,
    [1179] = 25,
    [2320] = 10,
    [2321] = 100,
    [2324] = 25,
    [2325] = 1000,
    [2604] = 50,
    [2678] = 2,
    [2692] = 40,
    [2880] = 100,
    [3371] = 4,
    [3372] = 40,
    [3466] = 2000,
    [3713] = 160,
    [3857] = 500,
    [4289] = 50,
    [4291] = 500,
    [4340] = 350,
    [4341] = 500,
    [4342] = 2500,
    [4399] = 200,
    [4400] = 2000,
    [4470] = 38,
    [6217] = 124,
    [6260] = 50,
    [6261] = 1000,
    [8343] = 2000,
    [8925] = 500,
    [10290] = 2500,
    [14341] = 5000,
    [18256] = 6000,
}
