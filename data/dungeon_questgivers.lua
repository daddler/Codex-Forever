--------------------------------------------------
-- WeintCodex :: Questgeber der Dungeonquests (1.0.8.23)
--------------------------------------------------
-- ERZEUGT von .github/scripts/import_questgivers.lua - nicht von Hand.
-- Herkunft (nur fuer Betreuer): data/questdb.lua (QuestieDB Forever) -
-- Geber je Quest und ihre Lagen in Forever. NEW: Quests des Journals ohne
-- Kartenpunkt. MOVED: Punkte aus Classic-Berichten, deren Geber in Forever
-- woanders steht (anderes Gebiet oder mehr als 5 % der Kartenbreite).
-- Art `community`. Geber in Instanzen und Quests aus Beute bleiben ohne.
--------------------------------------------------

local J = WeintCodex and WeintCodex.DungeonJournal
if not (J and J.PLACES and J.DATA) then return end
local NEW = {
    [1394] = { map = 1458, x = 0.578, y = 0.654, who = "Parqual Fintallas" }, -- scarlet_monastery: Final Passage
    [1442] = { map = 1439, x = 0.374, y = 0.401, who = "Thundris Windwirker" }, -- blackfathom_deeps: Seeking the Kor Gem
    [1654] = { map = 1426, x = 0.525, y = 0.369, who = "Jordan Stilwell" }, -- shadowfang_keep: The Test of Righteousness
    [1951] = { map = 1441, x = 0.783, y = 0.757, who = "Magus Tirth" }, -- scarlet_monastery: Rituals of Power
    [1956] = { map = 1445, x = 0.461, y = 0.571, who = "Tabetha" }, -- uldaman: Power in Uldaman
    [2769] = { map = 1455, x = 0.679, y = 0.461, who = "Klockmort Spannerspan" }, -- zulfarrak: The Brassbolts Brothers
    [2948] = { map = 1455, x = 0.364, y = 0.036, who = "Talvash del Kissel" }, -- gnomeregan: Gnome Improvement
    [2950] = { map = 1454, x = 0.76, y = 0.254, who = "Nogg" }, -- gnomeregan: Nogg's Ring Redo
    [3369] = { map = 1413, x = 0.482, y = 0.328, who = "Falla Sagewind" }, -- wailing_caverns: In Nightmares
    [3370] = { map = 1413, x = 0.482, y = 0.328, who = "Falla Sagewind" }, -- wailing_caverns: In Nightmares
    [3906] = { map = 1418, x = 0.033, y = 0.483, who = "Thunderheart" }, -- blackrock_depths: Disharmony of Flame
    [4143] = { map = 1444, x = 0.451, y = 0.256, who = "Gregan Brewspewer" }, -- sunken_temple: Haze of Evil
    [4262] = { map = 1428, x = 0.854, y = 0.701, who = "Jalinda Sprig" }, -- blackrock_depths: Overmaster Pyron
    [5281] = { map = 1423, x = 0.699, y = 0.537, who = "Verwalter Alen" }, -- stratholme: The Restless Souls
    [5305] = { map = 1452, x = 0.613, y = 0.371, who = "Lilith die Liebliche" }, -- stratholme: Sweet Serenity
    [5306] = { map = 1452, x = 0.613, y = 0.371, who = "Kilram" }, -- lower_blackrock_spire: Snakestone of the Shadow Huntress
    [5307] = { map = 1452, x = 0.613, y = 0.372, who = "Seril Scourgebane" }, -- stratholme: Corruption
    [5505] = { map = 1422, x = 0.427, y = 0.838, who = "Alchimist Arbington" }, -- scholomance: The Key to Scholomance
    [5511] = { map = 1420, x = 0.831, y = 0.689, who = "Hochexekutor Derrington" }, -- scholomance: The Key to Scholomance
    [5526] = { map = 1450, x = 0.517, y = 0.451, who = "Rabine Saturna" }, -- dire_maul: Shards of the Felvine
    [6821] = { map = 1447, x = 0.793, y = 0.737, who = "Fürst Hydraxis" }, -- upper_blackrock_spire: Eye of the Emberseer
    [7581] = { map = 1419, x = 0.341, y = 0.501, who = "Daio der Klapprige" }, -- dire_maul: The Prison's Bindings
    [7629] = { map = 1428, x = 0.124, y = 0.316, who = "Gorzeeki Wildeyes" }, -- scholomance: Imp Delivery
    [7631] = { map = 1428, x = 0.127, y = 0.316, who = "Mor'zul Bloodbringer" }, -- dire_maul: Dreadsteed of Xoroth
    [7647] = { map = 1453, x = 0.484, y = 0.502, who = "Lord Grayson Shadowbreaker" }, -- scholomance: Judgment and Redemption
    [7848] = { map = 1427, x = 0.321, y = 0.947, who = "Lothos Riftwaker" }, -- blackrock_depths: Attunement to the Core
    [8232] = { map = 1447, x = 0.424, y = 0.426, who = "Ogtinc" }, -- sunken_temple: The Green Drake
    [8236] = { map = 1447, x = 0.292, y = 0.402, who = "Erzmagier Xylem" }, -- sunken_temple: The Azure Key
    [8253] = { map = 1447, x = 0.292, y = 0.402, who = "Erzmagier Xylem" }, -- sunken_temple: Destroy Morphaz
    [8257] = { map = 1447, x = 0.424, y = 0.426, who = "Ogtinc" }, -- sunken_temple: Blood of Morphaz
    [8258] = { map = 1454, x = 0.387, y = 0.359, who = "Sagorne Creststrider" }, -- scholomance: The Darkreaver Menace
    [8413] = { map = 1416, x = 0.805, y = 0.669, who = "Bath'rah der Windbehüter" }, -- sunken_temple: Da Voodoo
    [8415] = { map = 1453, x = 0.484, y = 0.502, who = "Lord Grayson Shadowbreaker" }, -- sunken_temple: Chillwind Point
    [8417] = { map = 1456, x = 0.572, y = 0.874, who = "Torm Ragetotem" }, -- sunken_temple: A Troubled Spirit
    [8418] = { map = 1422, x = 0.427, y = 0.84, who = "Kommandant Ashlam Valorfist" }, -- sunken_temple: Forging the Mightstone
    [8422] = { map = 1448, x = 0.414, y = 0.45, who = "Impsy" }, -- sunken_temple: Trolls of a Feather
    [8425] = { map = 1435, x = 0.343, y = 0.661, who = "Gefallener Held der Horde" }, -- sunken_temple: Voodoo Feathers
    [9053] = { map = 1449, x = 0.716, y = 0.76, who = "Torwa Pathfinder" }, -- sunken_temple: A Better Ingredient
    [78261] = { map = 1421, x = 0.471, y = 0.71, who = "Toter Briefkasten" }, -- shadowfang_keep: The Horn of Xelthos
    [78307] = { map = 1421, x = 0.471, y = 0.71, who = "Toter Briefkasten" }, -- shadowfang_keep: The Horn of Xelthos
    [78676] = { map = 1421, x = 0.471, y = 0.71, who = "Toter Briefkasten" }, -- scarlet_monastery: The Eye of Bhossca
    [78699] = { map = 1421, x = 0.471, y = 0.71, who = "Toter Briefkasten" }, -- scarlet_monastery: The Eye of Bhossca
    [79360] = { map = 1441, x = 0.461, y = 0.517, who = "Rau Cliffrunner" }, -- razorfen_kraul: Elemental Aid
    [79946] = { map = 1453, x = 0.485, y = 0.491, who = "Katharina die Reine" }, -- scarlet_monastery: A Brother In Need
    [80411] = { map = 1416, x = 0.845, y = 0.803, who = "Fahrad" }, -- zulfarrak: The Talisman of Kazdor
    [84330] = { map = 1423, x = 0.534, y = 0.585, who = "Orthas" }, -- stratholme: A Wee Bit O' Necromancy
    [92065] = { map = 1447, x = 0.423, y = 0.201, who = "Torhüter Donnerschrei" }, -- blackmaw_hold: Blackmaw Reclamation
    [92066] = { map = 1447, x = 0.413, y = 0.201, who = "Hüter des Wissens Nok" }, -- blackmaw_hold: The Twin Bears
    [92069] = { map = 1447, x = 0.424, y = 0.426, who = "Ogtinc" }, -- blackmaw_hold: Claws That Rend, Tusks that Gore
    [92343] = { map = 1456, x = 0.757, y = 0.316, who = "Nara Wildmane" }, -- blackmaw_hold: Get to the Roots of It
    [92344] = { map = 1457, x = 0.354, y = 0.084, who = "Mathrengyl Bearwalker" }, -- blackmaw_hold: Get to the Roots of It
    [92432] = { map = 1424, x = 0.483, y = 0.6, who = "Abgesandter Jacques" }, -- city_of_dalaran: An Alarming Request
    [92459] = { map = 1421, x = 0.686, y = 0.451, who = "Abbild der Erzmagierin Modera" }, -- city_of_dalaran: Friend of the Kirin Tor
    [92753] = { map = 1436, x = 0.525, y = 0.53, who = "Alba Fairmoon" }, -- the_deadmines: Destruction in Deadmines
    [93404] = { map = 2652, x = 0.697, y = 0.718, who = "Waldemar" }, -- maraudon: Rot and Regret
    [93604] = { map = 2652, x = 0.727, y = 0.312, who = "Kog'thug der Tapfere" }, -- razorfen_downs: Agamaggan's Blood
    [94968] = { map = 2548, x = 0.594, y = 0.456, who = "Krom'rosh" }, -- kroldok_stronghold: Eye of Mugg
    [94972] = { map = 2548, x = 0.595, y = 0.44, who = "Tran'gul" }, -- kroldok_stronghold: Tome of Twilight
    [94975] = { map = 2548, x = 0.335, y = 0.379, who = "Da'grosh" }, -- kroldok_stronghold: A Token of Vengeance
    [94982] = { map = 2548, x = 0.667, y = 0.81, who = "Demar Brant" }, -- kroldok_stronghold: Eye of Mugg
    [94983] = { map = 2548, x = 0.307, y = 0.491, who = "Sergeant Riftan" }, -- kroldok_stronghold: Twilight Mementos
    [94984] = { map = 2548, x = 0.667, y = 0.811, who = "Ashe Amberhall" }, -- kroldok_stronghold: Tome of Twilight
    [94998] = { map = 2548, x = 0.667, y = 0.811, who = "Ashe Amberhall" }, -- kroldok_stronghold: Curios of Curiosity
    [95036] = { map = 1421, x = 0.434, y = 0.41, who = "Lumina Windsinger" }, -- blackfathom_deeps: A Moon-Kissed Blade
    [95140] = { map = 1421, x = 0.434, y = 0.41, who = "Lumina Windsinger" }, -- blackfathom_deeps: Old Fire-Eye
    [95161] = { map = 1453, x = 0.563, y = 0.54, who = "Waisenmatrone Nightingale" }, -- ruins_of_lordaeron: Remember That I Love You
    [95262] = { map = 1445, x = 0.635, y = 0.423, who = "Sully McCleary" }, -- alcaz_island_prison: The Secret Prison
    [95309] = { map = 1445, x = 0.703, y = 0.189, who = "Sergeant Ulka" }, -- alcaz_island_prison: No Orc Left Behind
    [95647] = { map = 1437, x = 0.119, y = 0.588, who = "Caitlin Grassman" }, -- excavation_site: Lost in the Thicket Things
    [95663] = { map = 1417, x = 0.745, y = 0.356, who = "Zaruk" }, -- excavation_site: Dragonmaw Rumors
    [95737] = { map = 1440, x = 0.35, y = 0.485, who = "Llana" }, -- excavation_site: Seeking Caitlin
    [95770] = { map = 1434, x = 0.323, y = 0.277, who = "Kin'weelay" }, -- drowned_city: Locating the Lost City
    [95775] = { map = 1434, x = 0.323, y = 0.277, who = "Kin'weelay" }, -- drowned_city: The Drowned City
    [95776] = { map = 1434, x = 0.322, y = 0.289, who = "Kommandant Aggro'gosh" }, -- drowned_city: The Only Good Brinescale...
    [95787] = { map = 1424, x = 0.506, y = 0.571, who = "Meister der Lehren Dibbs" }, -- drowned_city: Take Two With Water
    [95788] = { map = 1424, x = 0.506, y = 0.571, who = "Meister der Lehren Dibbs" }, -- drowned_city: Magics of the Drowned City
    [95789] = { map = 1434, x = 0.27, y = 0.772, who = "Krazek" }, -- drowned_city: Shady Saltseers
    [95791] = { map = 1434, x = 0.27, y = 0.772, who = "Krazek" }, -- drowned_city: The Saltseer Captain
    [95798] = { map = 1424, x = 0.506, y = 0.571, who = "Meister der Lehren Dibbs" }, -- drowned_city: The Web of Magic
    [95799] = { map = 1424, x = 0.506, y = 0.571, who = "Meister der Lehren Dibbs" }, -- drowned_city: Findings for the Explorer's League
    [95924] = { map = 1455, x = 0.715, y = 0.157, who = "Kurator Thorius" }, -- shapers_terrace: Panic at the Digsite
    [95925] = { map = 1455, x = 0.715, y = 0.157, who = "Kurator Thorius" }, -- shapers_terrace: Mapping the Way Forward
    [95926] = { map = 1458, x = 0.488, y = 0.693, who = "Apothekermeister Faranell" }, -- shapers_terrace: The Dark Crystal
    [95928] = { map = 1412, x = 0.35, y = 0.221, who = "Mayena Earthseeker" }, -- shapers_terrace: Crystalline Elements
    [96076] = { map = 1434, x = 0.285, y = 0.759, who = "Pix Xizzix" }, -- dire_maul: In Demand - Ancient Elven Curiosities
    [96078] = { map = 1434, x = 0.323, y = 0.277, who = "Kin'weelay" }, -- drowned_city: A Tale Spun Around the Fire
    [96264] = { map = 1455, x = 0.471, y = 0.138, who = "Veyric Thunderhame" }, -- razorfen_kraul: Elemental Aid
    [96332] = { map = 1445, x = 0.703, y = 0.189, who = "Sergeant Ulka" }, -- alcaz_island_prison: A Little Payback
    [96334] = { map = 1445, x = 0.703, y = 0.189, who = "Sergeant Ulka" }, -- alcaz_island_prison: Blood Red Bandanas
    [96377] = { map = 1453, x = 0.783, y = 0.711, who = "Renzik \"Das Messer\"" }, -- alcaz_island_prison: State Secrets
    [96381] = { map = 1445, x = 0.635, y = 0.423, who = "Sully McCleary" }, -- alcaz_island_prison: A Bit of Wet Work
    [96394] = { map = 1455, x = 0.33, y = 0.482, who = "Afadra Dunwall" }, -- hall_of_thanes: The Restless Dead
    [96403] = { map = 1455, x = 0.322, y = 0.445, who = "Thom Filch" }, -- hall_of_thanes: Important Heirlooms
    [96770] = { map = 1416, x = 0.153, y = 0.739, who = "Erzmagier Lan'dalock" }, -- zulfarrak: The Witch Doctor's Head
    [96771] = { map = 1416, x = 0.178, y = 0.659, who = "Ranath Nightstride" }, -- kroldok_stronghold: Vengeance of the Highborne
    [96772] = { map = 1416, x = 0.153, y = 0.739, who = "Erzmagier Lan'dalock" }, -- alcaz_island_prison: The Dragon's Journal
    [96773] = { map = 1416, x = 0.153, y = 0.739, who = "Erzmagier Lan'dalock" }, -- razorfen_downs: The Coldbringer's Eye
    [96774] = { map = 1412, x = 0.325, y = 0.207, who = "Mazu'kon" }, -- drowned_city: Ancient Gurubashi Idol
    [96775] = { map = 1412, x = 0.325, y = 0.207, who = "Mazu'kon" }, -- zulfarrak: Zum'rah's Head
    [96776] = { map = 1412, x = 0.326, y = 0.242, who = "Olana Brighthoof" }, -- maraudon: An'she's Radiance
    [97049] = { map = 1458, x = 0.475, y = 0.733, who = "Chemiker Fuely" }, -- shapers_terrace: Essence of Seeping Slimes
    [97130] = { map = 1416, x = 0.154, y = 0.741, who = "Erzmagier Timear" }, -- drowned_city: Ancient Gurubashi Secrets
    [97173] = { map = 1416, x = 0.154, y = 0.741, who = "Erzmagier Timear" }, -- blackmaw_hold: Blackmaw Magic
    [97196] = { map = 1412, x = 0.346, y = 0.23, who = "Sutara Plainstalker" }, -- razorfen_downs: The Coldbringer's Eye
    [97197] = { map = 1412, x = 0.334, y = 0.226, who = "Alaana Stormwalker" }, -- blackrock_depths: Fragment of the Firelands
    [97198] = { map = 1412, x = 0.334, y = 0.226, who = "Muln Earthfury" }, -- blackmaw_hold: Blackmaw Magic
    [97289] = { map = 1458, x = 0.488, y = 0.693, who = "Apothekermeister Faranell" }, -- ruins_of_lordaeron: Unending Torment
    [97290] = { map = 1458, x = 0.459, y = 0.617, who = "Unfertige Monstrosität" }, -- ruins_of_lordaeron: Unending Torment
    [97291] = { map = 1458, x = 0.488, y = 0.693, who = "Apothekermeister Faranell" }, -- ruins_of_lordaeron: Unending Torment
    [97292] = { map = 1458, x = 0.488, y = 0.693, who = "Apothekermeister Faranell" }, -- ruins_of_lordaeron: Unending Torment
    [97327] = { map = 1447, x = 0.42, y = 0.389, who = "Ekkal" }, -- blackmaw_hold: Blackmaw Pouches
    [98824] = { map = 1437, x = 0.388, y = 0.524, who = "Ausgrabungsleiter Whelgar" }, -- excavation_site: Prehistoric Prism
    [99187] = { map = 1420, x = 0.176, y = 0.676, who = "Ritter der Trauer" }, -- blackmaw_hold: The Reliquary of Tyr
}
local MOVED = {
    [386] = { map = 1433, x = 0.212, y = 0.466, who = "Wache Berton" }, -- the_stockade: vorher 1433 0.266,0.468
    [388] = { map = 1453, x = 0.764, y = 0.637, who = "Nikova Raskol" }, -- the_stockade: vorher 1453 0.736,0.466
    [92457] = { map = 1421, x = 0.686, y = 0.451, who = "Abbild der Erzmagierin Modera" }, -- city_of_dalaran: vorher 1416 0.092,0.6
    [92458] = { map = 1421, x = 0.686, y = 0.451, who = "Abbild der Erzmagierin Modera" }, -- city_of_dalaran: vorher 1416 0.092,0.6
    [96984] = { map = 1421, x = 0.686, y = 0.451, who = "Abbild der Erzmagierin Modera" }, -- city_of_dalaran: vorher 1416 0.092,0.6
}
for id, p in pairs(NEW) do if not J.PLACES[id] then p.forever = true J.PLACES[id] = p end end
for id, p in pairs(MOVED) do p.forever = true J.PLACES[id] = p end
for _, d in pairs(J.DATA) do for _, q in ipairs(d.quests or {}) do
    local p = NEW[q.id] or MOVED[q.id]
    if p and not q.giver and not q.giverNpc then q.giverNpc = { name = p.who, map = p.map, x = p.x, y = p.y } end
end end
J.GIVERS_NEW, J.GIVERS_MOVED = 113, 5
