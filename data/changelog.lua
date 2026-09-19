--------------------------------------------------
-- WeintCodex :: Changelog-Daten
--
-- Wird von core/onboarding.lua fuer das Update-Popup genutzt. Neueste
-- Version zuerst! Bei jedem Release hier einen Eintrag ergaenzen -
-- parallel zu CHANGELOG.md und zu den beiden Versionsangaben in
-- WeintCodex.toc und core/main.lua. Die CI prueft, dass alle vier
-- dieselbe Fassung nennen (siehe .github/scripts/release_notes.py).
--
-- Stil der Notizen (gilt auch fuer die Tour und jeden anderen Text,
-- den ein Spieler zu sehen bekommt):
--
--   * Was der Spieler MERKT, nicht was umgebaut wurde.
--   * Erster Halbsatz farbig hervorgehoben, Rest in Ruhe.
--   * Kein "wir", kein "Bugfix", keine Dateinamen, keine Versionen
--     im Fliesstext.
--
-- Die Hervorhebung ist |cff7C6CFF...|r - der Akzent der Palette
-- "Graphit" (core/ui.lua). Wer hier eine andere Farbe setzt, setzt
-- eine zweite Bedeutungsfarbe in die Welt.
--------------------------------------------------

WeintCodex_ChangelogData = {
    {
        version = "5.1.0.0",
        date    = "19.09.2026",
        notes   = {
            "|cff7C6CFFDie Dungeons sind da – alle neun.|r Ein eigener Punkt in der Navigation, mit Gebiet und Stufenbereich zu jeder Instanz. \"Welche Ini passt zu Stufe 42?\" beantwortet jetzt auch die Suche.",
            "|cff7C6CFFTank, Heiler und Schaden haben einen eigenen Platz bekommen.|r Zu jeder Instanz steht, wie viele Plätze jede Rolle hat und welche Talentbäume sie tragen können – und zu jedem Boss, was der Discord-Bot an Taktik geliefert hat.",
            "|cff7C6CFFBarrow Deeps und Hyjal Summit haben Bosslisten.|r Einundzwanzig Bosse, anklickbar, mit Fortschritt. Sie stammen aus dem Beta-Client und sind nicht bestätigt – deshalb steht an jeder Stelle \"vorläufig\" dabei, im Seitenkopf wie auf der Übersicht.",
            "|cff7C6CFFOnyxias Hort bleibt leer, und die Dungeons auch.|r Dazu liegt keine Liste vor. Dass man ahnt, wer in Onyxias Hort steht, ist keine Quelle – WeintCodex trägt nach, was nachzutragen ist, und erfindet den Rest nicht.",
        },
    },
    {
        version = "5.0.0.0",
        date    = "18.09.2026",
        notes   = {
            "|cff7C6CFFWeintCodex gibt es jetzt für World of Warcraft: Forever.|r Eigenes Addon, eigener Update-Kanal - die Fassung für Mists of Pandaria Classic läuft unverändert weiter.",
            "|cff7C6CFFNeues Aussehen.|r Ruhiger, kühler Grund, eine Serifenschrift für Überschriften und genau ein Akzent, der ausschliesslich Bedeutung trägt - dasselbe Bild wie in WeintCompanion.",
            "|cff7C6CFFWas es für Forever nicht gibt, behauptet WeintCodex auch nicht.|r Simmen, WeakAuras, Sockelsteine, Verzauberungsempfehlungen und Umschmieden sind nicht dabei: sie hingen an Zahlen aus Mists of Pandaria, die für dieses Spiel nichts aussagen.",
            "|cff7C6CFFDie Bosslisten sind leer, und das mit Absicht.|r Sie sind nicht veröffentlicht. Das Addon sagt \"noch nicht bekannt\" statt etwas zu erfinden - und trägt nach, sobald es etwas nachzutragen gibt.",
            "|cff7C6CFFGeblieben ist alles, was schon heute trägt:|r Schlachtzüge und Anmeldungen, der Gildenkalender, deine Charaktere, der Gruppencheck vor dem Pull, Materialien, Lootverteilung und die Brücke zu WeintCompanion.",
        },
    },
}
