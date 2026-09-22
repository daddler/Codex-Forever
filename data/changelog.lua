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
        version = "5.2.0.5",
        date    = "22.09.2026",
        notes   = {
            "|cff7C6CFFDie Bosse stehen als Karten, nicht mehr als Knopfreihe.|r Nummer, Name und – wo es eines gibt – das Kennzeichen, in drei Spalten, solange die Namen darin ganz dastehen. Eine Reihe schmaler Knöpfe sah aus wie eine zweite Navigation; was der Dungeon enthält, sieht jetzt aus wie Inhalt.",
            "|cff7C6CFFWas der Dungeon ist, steht in einer Zeile.|r Gebiet, Stufenbereich, Gruppengrösse, Bosszahl – und ob deine Stufe passt. Vorher verteilte sich das auf vier Stellen im Kopf, und die Bosszahl stand so weit rechts, dass sie zu nichts mehr gehörte.",
            "|cff7C6CFFDie Aufstellung ist nicht mehr der grösste Block der Seite.|r Sie steht unter den Bossen, und wo der Infobereich rechts zu ist, steht daneben, woher die Bossliste stammt – im Klartext, nicht nur im Tooltip.",
            "|cff7C6CFFDer ausgewählte Boss ersetzt die Übersicht nicht mehr.|r Die Karten bleiben stehen, die angeklickte trägt einen Balken, und im Kopf des Bosses steht der Weg zurück zur Übersicht.",
            "|cff7C6CFFDer Satz „Ein Klick auf einen Boss zeigt ihn hier\" ist weg.|r Er stand über einer Fläche, die sonst nichts zu sagen hatte. Jetzt steht dort etwas.",
        },
    },
    {
        version = "5.2.0.4",
        date    = "22.09.2026",
        notes   = {
            "|cff7C6CFFDie Dungeonnamen links stehen wieder vollständig da.|r Das Kennzeichen am rechten Rand nahm der Zeile so viel Platz, dass lange Namen abgeschnitten waren. Jetzt gehört die Zeile dem Namen – und darunter steht in einem Zug, aus welchem Spiel der Dungeon ist und für welche Stufen er gedacht ist.",
            "|cff7C6CFFDie zweite Zeile links liest sich als Auskunft, nicht als Muster.|r Sie ist nicht mehr weit gesperrt geschrieben, sie läuft nicht mehr aus der Spalte heraus, und beim ausgewählten Dungeon hellt sie mit auf.",
            "|cff7C6CFFDie Stufenabschnitte haben Luft bekommen.|r Über einem Abschnitt steht mehr Abstand als darunter – so sieht man, was zu welchem Abschnitt gehört.",
            "|cff7C6CFFDie Bosszahl steht rechts im Kopf, wie beim Schlachtzug.|r Wo der Infobereich rechts offen ist, steht sie dort – und nicht ein zweites Mal in der Zeile darunter.",
            "|cff7C6CFFDie Karte sagt, was als Nächstes zu tun ist.|r „Ein Klick auf einen Boss zeigt ihn hier\" – dort, wo Platz dafür ist und es etwas anzuklicken gibt.",
        },
    },
    {
        version = "5.2.0.3",
        date    = "21.09.2026",
        notes   = {
            "|cff7C6CFFDie Dungeonseite zeigt jetzt denselben rechten Infobereich wie die Schlachtzugseite.|r Stufe, Gruppengröße, Bosszahl und woher die Bossliste stammt stehen dort auf einen Blick – vorher stand die Herkunft nur versteckt im Tooltip.",
            "|cff7C6CFFBei den wenigen sehr großen Dungeons bleibt die Seite in voller Breite.|r Stratholme, Blackrock Depths, Scholomance und Lower Blackrock Spire haben so viele Bosse, dass der Infobereich der Bosszeile den Platz nehmen würde – dort zeigt die Seite lieber alle Bosse übersichtlich als einen Infobereich, der eng wird.",
        },
    },
    {
        version = "5.2.0.2",
        date    = "21.09.2026",
        notes   = {
            "|cff7C6CFFDie Stufenabschnitte links sind jetzt klar als Knopf zu erkennen.|r Ein Pfeil davor und ein Schimmer beim Überfahren zeigen, dass sich hier etwas öffnet – vorher sah ein geschlossener Abschnitt aus wie blasser Fliesstext.",
            "|cff7C6CFFDie Zahlen im Stufenabschnitt laufen nicht mehr ineinander.|r \"Stufe 13–22\" und die Anzahl der Dungeons dahinter standen sich vorher im Weg, weil der ganze Text gesperrt geschrieben war.",
            "|cff7C6CFFDie Boss-Pillen haben jetzt eine sichtbare Kontur.|r Auch unausgewählt heben sie sich vom Hintergrund ab, statt mit ihm zu verschwimmen.",
        },
    },
    {
        version = "5.2.0.1",
        date    = "21.09.2026",
        notes   = {
            "|cff7C6CFFDie Dungeonseite ist eine Seite, keine vier Spalten mehr.|r Links stehen nur noch die Dungeons, nach Stufe. Die Seite selbst hat die volle Breite: oben der Dungeon mit Stufe, Gruppengrösse und Bosszahl – und ob deine Stufe passt –, darunter die Bosse, darunter eine Karte mit allem Weiteren.",
            "|cff7C6CFFDie Bosse stehen als anklickbare Reihe auf der Seite.|r Nummeriert, wo die Reihenfolge bekannt ist; mit Kennzeichen, wenn einer beschworen werden muss oder optional ist. Ein Klick öffnet den Boss darunter: wo er steht, wie er kommt, was die Rollen tun. Grosse Instanzen zeigen einen Flügel nach dem anderen.",
            "|cff7C6CFFDie Aufstellung liest sich in einem Blick.|r Zu jeder Rolle die Plätze und die Talentbäume, nach Klasse gruppiert statt als Liste von zwanzig Zeilen.",
            "|cff7C6CFFRollenhinweise vom Bot stehen vollständig da.|r Nichts wird mehr gekürzt – schickt der Bot mehr, als das Fenster zeigt, rollt die Karte. Liegt zu einem Boss nichts vor, steht das einmal da und nicht dreimal.",
            "|cff7C6CFFWoher eine Bossliste stammt, steht an der Bossreihe.|r Wer den Hinweis überfährt, liest, warum sie nicht feststeht. Neun berichtete Kämpfe ohne Namen sind neun leere Plätze, keine leere Liste.",
        },
    },
    {
        version = "5.2.0.0",
        date    = "21.09.2026",
        notes   = {
            "|cff7C6CFFDie alten Dungeons stehen jetzt mit drin – alle zwanzig.|r Forever ersetzt sie nicht, es stellt neun daneben. Wer mit Stufe 32 einen Dungeon sucht, bekam bisher zwei angeboten; jetzt sind es alle, die passen, sortiert nach Stufe.",
            "|cff7C6CFFHall of Thanes und Ruins of Lordaeron haben Bosslisten.|r Dazu die zwei Bosse der Drowned City, die auf der BlizzCon spielbar waren. Sie kommen aus Beta-Berichten und nicht von Blizzard – an jeder Liste steht, woher sie stammt und warum sie nicht feststeht.",
            "|cff7C6CFFZu jedem Boss steht, wo er steht.|r Welche Patrouille man abwartet, in welcher Kammer er wartet, wer neben ihm steht. Bilder gibt es keine: Karten hat Blizzard für Forever nicht veröffentlicht, und die des Spiels gehören Blizzard. Wo einer steht, lässt sich aber sagen.",
            "|cff7C6CFFElf Bosse im Spiel erscheinen erst, wenn du etwas dafür tust.|r Viktor the Vile hinter dem Kohlenbecken in Lordaeron, Kirtonos, der Avatar von Hakkar, Urok Doomhowl und sieben weitere. Eine eigene Übersicht zeigt, wo es welche gibt, und an jedem steht, wie er kommt.",
            "|cff7C6CFFDie Liste links bleibt übersichtlich, auch bei neunundzwanzig Instanzen.|r Sie öffnet einen Stufenabschnitt nach dem anderen; grosse Instanzen wie Blackrock Depths oder Dire Maul zeigen einen Flügel nach dem anderen. Gescrollt wird nirgends.",
            "|cff7C6CFFWo sich Quellen widersprechen, steht der Widerspruch da.|r Für Excavation Site kursieren vier Bossnamen, die eine andere Darstellung bestreitet. Für City of Dalaran sind neun Kämpfe berichtet und fünf Namen. Beides steht so da – und nicht als Liste, die es nicht gibt.",
        },
    },
    {
        version = "5.1.0.0",
        date    = "20.09.2026",
        notes   = {
            "|cff7C6CFFDie Dungeons sind da – alle neun.|r Ein eigener Punkt in der Navigation, mit Gebiet und Stufenbereich zu jeder Instanz. \"Welche Ini passt zu Stufe 42?\" beantwortet jetzt auch die Suche.",
            "|cff7C6CFFTank, Heiler und Schaden haben einen eigenen Platz bekommen.|r Zu jeder Instanz steht, wie viele Plätze jede Rolle hat und welche Talentbäume sie tragen können – und zu jedem Boss, was der Discord-Bot an Taktik geliefert hat.",
            "|cff7C6CFFBarrow Deeps und Hyjal Summit haben Bosslisten.|r Einundzwanzig Bosse, anklickbar, mit Fortschritt. Sie stammen aus dem Beta-Client und sind nicht bestätigt – deshalb steht an jeder Stelle \"vorläufig\" dabei, im Seitenkopf wie auf der Übersicht.",
            "|cff7C6CFFOnyxias Hort bleibt leer, und die Dungeons auch.|r Dazu liegt keine Liste vor. Dass man ahnt, wer in Onyxias Hort steht, ist keine Quelle – WeintCodex trägt nach, was nachzutragen ist, und erfindet den Rest nicht.",
            "|cff7C6CFFDu siehst jederzeit, wo du bist – ohne zu scrollen.|r Die Spalte links zeigt die Instanzen und darunter eingerückt die Bosse der Instanz, in der du gerade bist. Ein Punkt sagt, was gelegt ist, ein \"Tipps\" daneben, wozu Taktik vorliegt. In der Mitte steht dafür der ausgewählte Boss mit seinen drei Rollen.",
            "|cff7C6CFFDie Suche landet auf dem Treffer.|r Tippst du einen Bossnamen ein, kommst du bei diesem Boss heraus – und nicht auf einer Seite, die gerade etwas anderes aufgeschlagen hat.",
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
