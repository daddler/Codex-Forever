--------------------------------------------------
-- WeintCodex :: Oberflaeche - Chat-Kanaele in Gold (6.62.3.0)
--------------------------------------------------
-- Das Fenster "Chat-Kanaele" des Spiels (ChannelFrame, Blizzard_Channels):
-- links die Kanaele nach Gruppen, rechts die Mitglieder.
--
-- GEMESSEN (6.62.2.0, /wcui fenster): Metallrahmen (NineSlice,
-- "_UI-Frame-TopTileStreaks"), Portraet 526421, ChannelFrameBg (374155),
-- drei Innenflaechen (374154: LeftInset, RightInset, ChannelFrameInset),
-- rote Knoepfe (130828/130826) - das alles nimmt der allgemeine
-- Durchlauf (W.WINDOWS) und die Innenflaechen.
-- Was nur dieses Fenster hat:
--   Gruppe     Kopf einer Gruppe ("voicechat-channellist-category-
--              background", Gruppe/Bis einer weint/Welt/Benutzerdefiniert)
--              wird eine Leiste ohne Rand; das Minus bleibt.
--   Zeilen     Hintergrund jeder Zeile ("voicechat-channellist-row-
--              background", 23x) weg - die Innenflaeche traegt. Leuchten
--              beim Zeigen und die gewaehlte Zeile bleiben.
--   Rang       Krone des Mitglieds (132061/132062) bleibt.
--------------------------------------------------

WeintCodex = WeintCodex or {}

local CP = WeintCodex.UICalmParts

WeintCodex.UIChannels = CP.New({
    label = "Chat-Kanäle", host = "ChannelFrame", depth = 4,
    files = {
        [526421] = "decor",  -- Symbol oben links (zwei Koepfe)
    },
    atlases = {
        { "^voicechat%-channellist%-category%-background", "strip" },
        { "^voicechat%-channellist%-row%-background", "decor" },
    },
})
