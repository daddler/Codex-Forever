--------------------------------------------------
-- WeintCodex :: Tier-0.5-Questreihe (Dungeon-Set 2)
--------------------------------------------------
-- ERZEUGT von .github/scripts/import_naowh_tier05.lua aus Naowh Forever
-- 1.4.11 (Discovery) - nicht von Hand aendern. Herkunft `community`.
--   steps: Schritte in Reihenfolge. Zahl = Quest; { A, H } = je Fraktion;
--          { any = {..} } = einer davon (Bodleys Wahl); Text = Quest der
--          Klasse (class[Fraktion][Klasse][Text] = Nummern, die erste
--          die von Forever).
-- Namen, Stufen, Geber: data/questdb.lua und der Client.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.Tier05Data = {
    SOURCE = { kind = "community", label = "Von Spielern gesammelt" },
    steps = {
        "proposition",
        { A = 8922, H = 8923 },
        8921,
        8924,
        8925,
        8928,
        { A = 8977, H = 8978 },
        "compensation",
        { A = 8929, H = 8930 },
        8945,
        8946,
        8947,
        8948,
        8949,
        8950,
        9015,
        "parting",
        { A = 8960, H = 9032 },
        8961,
        { any = { 8962, 8963, 8964, 8965 } },
        { any = { 8966, 8967, 8968, 8969 } },
        8970,
        { any = { 8985, 8986, 8987, 8988 } },
        { any = { 8989, 8990, 8991, 8992 } },
        8994,
        8995,
        8996,
        { A = 8997, H = 8998 },
        "best",
    },
    class = {
        A = {
            DRUID = { best = { 84195, 8999 }, compensation = { 84163, 8926 }, parting = { 84179, 8951 }, proposition = { 84147, 8905 } },
            HUNTER = { best = { 84196, 9000 }, compensation = { 84164, 8931 }, parting = { 84180, 8952 }, proposition = { 84148, 8906 } },
            MAGE = { best = { 84197, 9001 }, compensation = { 84165, 8932 }, parting = { 84181, 8953 }, proposition = { 84149, 8907 } },
            PALADIN = { best = { 84198, 9002 }, compensation = { 84166, 8933 }, parting = { 84182, 8954 }, proposition = { 84150, 8908 } },
            PRIEST = { best = { 84199, 9003 }, compensation = { 84167, 8934 }, parting = { 84183, 8955 }, proposition = { 84151, 8909 } },
            ROGUE = { best = { 84200, 9004 }, compensation = { 84168, 8935 }, parting = { 84184, 8956 }, proposition = { 84152, 8910 } },
            SHAMAN = { best = { 97450 }, compensation = { 97448 }, parting = { 97449 }, proposition = { 97447 } },
            WARLOCK = { best = { 84201, 9005 }, compensation = { 84169, 8936 }, parting = { 84185, 8958 }, proposition = { 84153, 8911 } },
            WARRIOR = { best = { 84202, 9006 }, compensation = { 84170, 8937 }, parting = { 84186, 8959 }, proposition = { 84154, 8912 } },
        },
        H = {
            DRUID = { best = { 84203, 9007 }, compensation = { 84171, 8927 }, parting = { 84187, 9016 }, proposition = { 84155, 8913 } },
            HUNTER = { best = { 84204, 9008 }, compensation = { 84172, 8938 }, parting = { 84188, 9017 }, proposition = { 84156, 8914 } },
            MAGE = { best = { 84205, 9014 }, compensation = { 84173, 8939 }, parting = { 84189, 9018 }, proposition = { 84157, 8915 } },
            PALADIN = { best = { 97414 }, compensation = { 97412 }, parting = { 97413 }, proposition = { 97411 } },
            PRIEST = { best = { 84206, 9009 }, compensation = { 84174, 8940 }, parting = { 84190, 9019 }, proposition = { 84158, 8916 } },
            ROGUE = { best = { 84207, 9010 }, compensation = { 84175, 8941 }, parting = { 84191, 9020 }, proposition = { 84159, 8917 } },
            SHAMAN = { best = { 84208, 9011 }, compensation = { 84176, 8942 }, parting = { 84192, 8957 }, proposition = { 84160, 8918 } },
            WARLOCK = { best = { 84209, 9012 }, compensation = { 84177, 8943 }, parting = { 84193, 9021 }, proposition = { 84161, 8919 } },
            WARRIOR = { best = { 84210, 9013 }, compensation = { 84178, 8944 }, parting = { 84194, 9022 }, proposition = { 84162, 8920 } },
        },
    },
}
