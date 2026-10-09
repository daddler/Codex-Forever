--------------------------------------------------
-- WeintCodex :: Stufen und Sammelberufe je Gebiet (6.26.5.0)
--------------------------------------------------
-- Beta-Test: "einsehen, welcher Levelbereich das Land ist und welche Berufe
-- dort am besten ausgeuebt werden koennen (Angeln, Kraeuter, Erze)".
--
-- HERKUNFT (nur fuer Betreuer, im Spiel steht nur die Art):
--   lvl, fish  Stufenbereich und Mindest-Angelfertigkeit aus der Tabelle
--              des Addons Leatrix Maps (Zone Levels). Fuer die alten Gebiete
--              sind das die Werte aus Classic (kind "classic"); fuer die
--              neuen Gebiete von Forever traegt Leatrix nur Stufen ein
--              (kind "community", unbestaetigt).
--   herbs, ore Kraeuter und Erze je Gebiet aus Classic, von Hand
--              zusammengestellt - nicht aus dem Forever-Client gelesen.
--              Ob Forever die Vorkommen verschoben hat, weiss niemand.
-- fish: Zeichenkette wie bei Leatrix, "130 (205)" = ab 130, sicher ab 205.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.ZoneInfoData = {
    [1411] = { lvl = { 1, 10 }, fish = "1", herbs = "Friedensblume, Silberblatt, Erdwurzel", ore = "Kupfer", kind = "classic" },
    [1412] = { lvl = { 1, 10 }, fish = "1", herbs = "Friedensblume, Silberblatt, Erdwurzel", ore = "Kupfer", kind = "classic" },
    [1413] = { lvl = { 10, 25 }, fish = "1", herbs = "Silberblatt, Erdwurzel, Maguskönigskraut, Wilddornrose, Beulengras, Würgetang", ore = "Kupfer, Zinn, Silber", kind = "classic" },
    [1416] = { lvl = { 30, 40 }, fish = "130", herbs = "Königsblut, Lebenswurz, Winterbiss", ore = "Eisen, Gold, Mithril", kind = "classic" },
    [1417] = { lvl = { 30, 40 }, fish = "130", herbs = "Königsblut, Lebenswurz, Blassblatt", ore = "Eisen, Gold, Mithril", kind = "classic" },
    [1418] = { lvl = { 35, 45 }, herbs = "Feuerblüte, Golddorn, Lila Lotus", ore = "Eisen, Gold, Mithril, Echtsilber", kind = "classic" },
    [1419] = { lvl = { 45, 55 }, herbs = "Feuerblüte", ore = "Mithril, Echtsilber, Thorium", kind = "classic" },
    [1420] = { lvl = { 1, 10 }, fish = "1", herbs = "Friedensblume, Silberblatt, Erdwurzel", ore = "Kupfer", kind = "classic" },
    [1421] = { lvl = { 10, 20 }, fish = "1", herbs = "Friedensblume, Silberblatt, Erdwurzel, Maguskönigskraut, Wilddornrose", ore = "Kupfer, Zinn", kind = "classic" },
    [1422] = { lvl = { 51, 58 }, fish = "205", herbs = "Sonnengras, Arthas' Tränen, Pestblüte", ore = "Mithril, Echtsilber, Thorium", kind = "classic" },
    [1423] = { lvl = { 53, 60 }, fish = "330", herbs = "Pestblüte, Traumblatt, Sonnengras, Bergsilbersalbei", ore = "Echtsilber, Thorium", kind = "classic" },
    [1424] = { lvl = { 20, 30 }, fish = "55", herbs = "Beulengras, Würgetang, Wildstahlblume, Königsblut", ore = "Zinn, Silber, Eisen, Gold", kind = "classic" },
    [1425] = { lvl = { 40, 50 }, fish = "205", herbs = "Golddorn, Khadgars Schnurrbart, Lila Lotus, Sonnengras", ore = "Gold, Mithril, Echtsilber", kind = "classic" },
    [1426] = { lvl = { 1, 10 }, fish = "1", herbs = "Friedensblume, Silberblatt, Erdwurzel", ore = "Kupfer", kind = "classic" },
    [1427] = { lvl = { 43, 50 }, herbs = "Feuerblüte", ore = "Gold, Mithril, Echtsilber, Thorium", kind = "classic" },
    [1428] = { lvl = { 50, 58 }, fish = "330", herbs = "Sonnengras", ore = "Mithril, Echtsilber, Thorium", kind = "classic" },
    [1429] = { lvl = { 1, 10 }, fish = "1", herbs = "Friedensblume, Silberblatt, Erdwurzel", ore = "Kupfer", kind = "classic" },
    [1430] = { lvl = { 55, 60 }, fish = "330", ore = "Thorium", kind = "classic" },
    [1431] = { lvl = { 18, 30 }, fish = "55", herbs = "Würgetang, Wildstahlblume, Grabmoos", ore = "Zinn, Silber, Eisen, Gold", kind = "classic" },
    [1432] = { lvl = { 10, 20 }, fish = "1", herbs = "Friedensblume, Silberblatt, Erdwurzel, Maguskönigskraut, Wilddornrose", ore = "Kupfer, Zinn", kind = "classic" },
    [1433] = { lvl = { 15, 25 }, fish = "55", herbs = "Maguskönigskraut, Wilddornrose, Beulengras, Würgetang", ore = "Kupfer, Zinn", kind = "classic" },
    [1434] = { lvl = { 30, 45 }, fish = "130 (205)", herbs = "Königsblut, Lebenswurz, Blassblatt, Golddorn, Khadgars Schnurrbart, Lila Lotus", ore = "Silber, Eisen, Gold, Mithril", kind = "classic" },
    [1435] = { lvl = { 35, 45 }, fish = "130", herbs = "Königsblut, Lebenswurz, Golddorn, Blindkraut", ore = "Eisen, Gold, Mithril", kind = "classic" },
    [1436] = { lvl = { 10, 20 }, fish = "1", herbs = "Friedensblume, Silberblatt, Erdwurzel, Maguskönigskraut", ore = "Kupfer, Zinn", kind = "classic" },
    [1437] = { lvl = { 20, 30 }, fish = "55", herbs = "Beulengras, Würgetang, Wildstahlblume, Königsblut", ore = "Zinn, Silber, Eisen", kind = "classic" },
    [1438] = { lvl = { 1, 10 }, fish = "1", herbs = "Friedensblume, Silberblatt, Erdwurzel", kind = "classic" },
    [1439] = { lvl = { 10, 20 }, fish = "1", herbs = "Friedensblume, Silberblatt, Erdwurzel, Maguskönigskraut, Wilddornrose, Beulengras", ore = "Kupfer, Zinn", kind = "classic" },
    [1440] = { lvl = { 18, 30 }, fish = "55", herbs = "Wilddornrose, Beulengras, Würgetang, Wildstahlblume", ore = "Zinn, Silber, Eisen, Gold", kind = "classic" },
    [1441] = { lvl = { 25, 35 }, fish = "130", herbs = "Wildstahlblume, Königsblut, Lebenswurz", ore = "Zinn, Silber, Eisen, Gold, Mithril", kind = "classic" },
    [1442] = { lvl = { 15, 27 }, fish = "55", herbs = "Maguskönigskraut, Wilddornrose, Beulengras, Würgetang", ore = "Kupfer, Zinn, Silber", kind = "classic" },
    [1443] = { lvl = { 30, 40 }, fish = "130", herbs = "Königsblut, Lebenswurz, Gromsblut", ore = "Eisen, Gold, Mithril", kind = "classic" },
    [1444] = { lvl = { 40, 50 }, fish = "205 (330)", herbs = "Golddorn, Khadgars Schnurrbart, Sonnengras, Lila Lotus", ore = "Gold, Mithril, Echtsilber", kind = "classic" },
    [1445] = { lvl = { 35, 45 }, fish = "130", herbs = "Königsblut, Lebenswurz, Blassblatt, Golddorn, Khadgars Schnurrbart", ore = "Eisen, Gold, Mithril", kind = "classic" },
    [1446] = { lvl = { 40, 50 }, fish = "205", herbs = "Feuerblüte", ore = "Gold, Mithril, Echtsilber", kind = "classic" },
    [1447] = { lvl = { 45, 55 }, fish = "205 (330)", herbs = "Goldener Sansam, Traumblatt, Bergsilbersalbei", ore = "Mithril, Echtsilber, Thorium", kind = "classic" },
    [1448] = { lvl = { 48, 55 }, fish = "205", herbs = "Sonnengras, Gromsblut, Goldener Sansam, Traumblatt", ore = "Mithril, Echtsilber, Thorium", kind = "classic" },
    [1449] = { lvl = { 48, 55 }, fish = "205", herbs = "Goldener Sansam, Traumblatt, Bergsilbersalbei, Sonnengras", ore = "Mithril, Echtsilber, Thorium", kind = "classic" },
    [1450] = { fish = "205", kind = "classic" },
    [1451] = { lvl = { 55, 60 }, fish = "330", herbs = "Sonnengras, Goldener Sansam", ore = "Echtsilber, Thorium", kind = "classic" },
    [1452] = { lvl = { 55, 60 }, fish = "330", herbs = "Eiskappe, Bergsilbersalbei", ore = "Echtsilber, Thorium", kind = "classic" },
    [1453] = { fish = "1", kind = "classic" },
    [1454] = { fish = "1", kind = "classic" },
    [1455] = { fish = "1", kind = "classic" },
    [1456] = { fish = "1", kind = "classic" },
    [1457] = { fish = "1", kind = "classic" },
    [1458] = { fish = "1", kind = "classic" },
    [2482] = { lvl = { 60, 60 }, kind = "community" },
    [2521] = { lvl = { 1, 12 }, kind = "community" },
    [2548] = { lvl = { 35, 45 }, kind = "community" },
    [2652] = { lvl = { 35, 45 }, kind = "community" },
}
