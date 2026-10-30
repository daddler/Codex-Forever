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
        version = "1.8.0.0",
        date    = "30.10.2026",
        notes   = {
            "|cff7C6CFFSterbezeit an der Plakette|r – auf Wunsch steht rechts neben dem Lebensbalken, in wie vielen Sekunden dein Ziel stirbt, gerechnet aus dem Schaden, den alle in den letzten Sekunden auf ihm gemacht haben.",
            "|cff7C6CFFReichen meine DoTs?|r – grün „DoTs reichen“, wenn deine laufenden Schadenszauber den Gegner auch ohne einen weiteren Zauber töten. Lass sie auslaufen und spar dir das Mana. Rot heißt: noch nachlegen.",
            "|cff7C6CFFBeides ist optional|r – Namensplaketten → Texte → Sterbezeit, ab Werk aus. Nennt das Spiel die Lebenspunkte im Kampf nicht offen, bleibt der Platz leer statt zu raten.",
        },
    },
    {
        version = "1.7.0.0",
        date    = "29.10.2026",
        notes   = {
            "|cff7C6CFFKomplexere Makros mit dem Makro-Helfer|r – neue Ziele: Heilen auf Maus, sonst Ziel, sonst dich; Angriff auf den Gegner unter der Maus; Ziel deines Ziels; dein Begleiter; Flächenzauber auf das Maus-Ziel, sonst am Mauszeiger.",
            "|cff7C6CFFBedingungen und Extras|r – unter „Erweitert“: nur im Kampf, außerhalb oder ohne Reittier, nur in einer Haltung oder Gestalt, Begleiter greift an, Schmuckstücke und eine eigene Zeile am Ende.",
        },
    },
    {
        version = "1.6.0.0",
        date    = "28.10.2026",
        notes   = {
            "|cff7C6CFFWer würfelt worauf|r – im Dungeon zeigt ein kleines Fenster, wer bei welchem Gegenstand Bedarf, Gier oder Passen gewählt hat, mit Wurf und Gewinner. Schalter: Komfort → Anzeigen.",
            "|cff7C6CFFGegnerrahmen in der Arena|r – Name, Leben, Klasse und Spezialisierung jedes Gegners; Links ins Ziel, Rechts Fokus.",
            "|cff7C6CFFGegnerliste im Schlachtfeld|r – schon vor dem Start siehst du, wer gegen dich steht, Heiler zuerst. Ein Klick nimmt ihn ins Ziel, sobald er in Sichtweite ist.",
            "|cff7C6CFFHeiler markieren|r – ein grünes Kreuz über gegnerischen Heilern, im PvP nach Spezialisierung und in Dungeons über Gegnern, die heilen.",
            "|cff7C6CFFFeind in der Nähe|r – auf Wunsch eine Meldung mit Klick ins Ziel, wenn ein feindlicher Spieler in deine Stadt kommt. Alles unter Komfort → PvP.",
        },
    },
    {
        version = "1.5.0.0",
        date    = "27.10.2026",
        notes   = {
            "|cff7C6CFFEntdecken statt Bücher|r – der Eintrag in der Navigation heißt jetzt „Entdecken“. Darin stehen die Bücher der Bibliothek und, als eigener Abschnitt, der Gemütliche Schlafsack.",
        },
    },
    {
        version = "1.4.0.0",
        date    = "27.10.2026",
        notes   = {
            "|cff7C6CFFDungeonbeute mit Dropchance|r – an fast allen Bossen steht jetzt, was in Forever fällt und wie oft, dazu die Stufe des Bosses. Was es im Spiel noch nicht gibt, sagt das, statt ewig zu laden. Neue Bosse in der Drowned City, der Shaper's Terrace und der Alcaz-Insel.",
            "|cff7C6CFFFähigkeiten der Bosse|r – unter jedem Boss steht, was er kann: Name und Beschreibung jeder Fähigkeit, direkt aus dem Spiel.",
            "|cff7C6CFFFlugzeit mit Zwischenstopps|r – wann du an jedem Halt bist, und auf Wunsch landest du schon am nächsten. Ein Knopf öffnet die Flugspiele.",
            "|cff7C6CFFGemütlicher Schlafsack|r – auf der Seite „Bücher“ die ganze versteckte Questreihe: jeder Schritt mit Karte, Weg und Questpfeil, erledigt oder offen.",
            "|cff7C6CFFGewinn beim Herstellen|r – auf der Seite „Berufe“ unter „Gewinn“: was jedes deiner Rezepte nach dem Auktionshaus-Scan einbringt, nach Gebühr und Materialkosten.",
        },
    },
    {
        version = "1.3.0.0",
        date    = "27.10.2026",
        notes   = {
            "|cff7C6CFFAngeln mit einer Taste|r – eine Taste wirft aus, holt den Schwimmer ein, wenn er anbeißt, und nimmt die Beute. Welche Taste, wählst du im Komfort unter „Sammeln“. Sie gilt nur mit Angel in der Hand; sonst bleibt deine eigene Belegung.",
            "|cff7C6CFFAngel-Logbuch|r – auf der Seite „Berufe“ unter „Angeln“ steht je Gebiet, wie oft du geworfen hast und was am Haken war, mit Anteil je Fang.",
        },
    },
    {
        version = "1.2.0.0",
        date    = "26.10.2026",
        notes   = {
            "|cff7C6CFFAufträge aus der Gilde|r – hat jemand im Discord etwas bei dir bestellt, öffnet sich nach dem Einloggen ein kleines Fenster: was, wie viel, für welchen Charakter, ob das Material gestellt wird. Annehmen, Erledigt oder Ablehnen geht direkt dort; mit „/wc aufträge“ holst du es jederzeit zurück.",
        },
    },
    {
        version = "1.1.0.0",
        date    = "25.10.2026",
        notes   = {
            "|cff7C6CFFGruppen aus dem Discord auf der Dungeonseite|r – wird im Discord eine Runde für einen Dungeon geplant, steht sie bei diesem Dungeon unter „Besonderheiten“: wann, wie viele dabei sind und ob du schon zugesagt hast. Dafür braucht es die Companion.",
        },
    },
    {
        version = "1.0.0.0",
        date    = "24.10.2026",
        notes   = {
            "|cff7C6CFFWeintCodex heißt jetzt ganz Forever|r – die Zählung beginnt neu bei 1.0. Alles, was du eingestellt hast, bleibt, wie es ist.",
            "|cff7C6CFFDeine Berufe in der Companion|r – WeintCodex merkt sich die Fertigkeit jedes Berufs, damit du am Desktop siehst, welcher Charakter was herstellen kann.",
        },
    },
    {
        version = "6.146.0.0",
        date    = "24.10.2026",
        notes   = {
            "|cff7C6CFFEigene Töne für „Raus da!“|r – in der Companion ausgewählt, stehen sie hier oben in der Liste der Töne. Neue Töne hört das Spiel nach einem Neustart.",
        },
    },
    {
        version = "6.145.0.0",
        date    = "23.10.2026",
        notes   = {
            "|cff7C6CFFBerufe der Gilde in Klassenfarben|r – jeder Name steht in der Farbe seiner Klasse.",
        },
    },
    {
        version = "6.144.1.0",
        date    = "22.10.2026",
        notes   = {
            "|cff7C6CFFDer Skill-Weg ist beim nächsten Öffnen wieder da|r – × blendet ihn nur aus, bis du das Berufsfenster schließt.",
        },
    },
    {
        version = "6.144.0.1",
        date    = "22.10.2026",
        notes   = {
            "|cff7C6CFFKarten zeigen nur noch ihre eigenen Punkte|r – die Händlerpunkte aus der Merkliste blieben auf der Karte anderer Rezepte stehen.",
        },
    },
    {
        version = "6.144.0.0",
        date    = "22.10.2026",
        notes   = {
            "|cff7C6CFFHändler erreichen auch Spätkommer|r – wer sich später einloggt, fragt nach und bekommt die Händler der Gilde, wie schon die Berufe.",
        },
    },
    {
        version = "6.143.0.0",
        date    = "22.10.2026",
        notes   = {
            "|cff7C6CFFGefundene Händler teilt die Gilde still|r – wer Handwerkswaren verkauft, siehst du jetzt auch, wenn ein Gildenmitglied mit WeintCodex den Händler geöffnet hat („von …“).",
        },
    },
    {
        version = "6.142.0.0",
        date    = "22.10.2026",
        notes   = {
            "|cff7C6CFFErinnerungen schlucken keine Klicks mehr|r – liegt ein Fenster über einer Erinnerung (z. B. Gift), bekommt das Fenster den Klick, nicht die Waffe.",
        },
    },
    {
        version = "6.141.0.0",
        date    = "22.10.2026",
        notes   = {
            "|cff7C6CFFDer Planer sagt, was ein Klick tut|r – Hinweise über Weg und Einkaufsliste, dazu „Ganze Einkaufsliste auf die Merkliste“.",
        },
    },
    {
        version = "6.140.0.0",
        date    = "22.10.2026",
        notes   = {
            "|cff7C6CFFMerkliste: Menge direkt eintippen|r – jedes vorgemerkte Rezept und jeder Gegenstand hat ein Feld für die Anzahl (Enter übernimmt) und ein × zum Entfernen.",
        },
    },
    {
        version = "6.139.0.0",
        date    = "22.10.2026",
        notes   = {
            "|cff7C6CFFEigene Ziele erledigen sich selbst|r – hast du eine selbst gesetzte Markierung (oder einen Händler, ein Buch …) erreicht und gehst wieder weg, verschwinden Pfeil und Markierung. Quests bleiben wie bisher.",
        },
    },
    {
        version = "6.138.0.0",
        date    = "22.10.2026",
        notes   = {
            "|cff7C6CFFAlle Händler auf der Karte|r – jeder gesehene Händler eines Gegenstands hat seinen Punkt; Maus über den Händler lässt seinen Punkt pulsieren, ein Klick wählt ihn, und der Questpfeil führt zu genau diesem.",
        },
    },
    {
        version = "6.137.0.0",
        date    = "22.10.2026",
        notes   = {
            "|cff7C6CFFMerkliste beim Händler deutlicher|r – der ganze Platz leuchtet golden mit dickem Rand und „Merkliste · fehlt N“ auf einem Schild.",
            "|cff7C6CFFWeintCodex merkt sich, wer Handwerkswaren verkauft|r – in der Merkliste steht rechts der Händler mit Titel, Gebiet, Preis und Karte samt Pin, dazu der Questpfeil dorthin.",
        },
    },
    {
        version = "6.136.0.0",
        date    = "22.10.2026",
        notes   = {
            "|cff7C6CFFDie Addon-Liste im Stil der Oberfläche|r – ohne Metallrahmen und rote Knöpfe, mit flacher Suche, wie die anderen Fenster.",
        },
    },
    {
        version = "6.135.0.0",
        date    = "22.10.2026",
        notes   = {
            "|cff7C6CFFDie Merkliste leuchtet beim Händler|r – was dir noch fehlt (z. B. Verbleite Phiolen), pulsiert im Händlerfenster mit der fehlenden Menge; auch der Tooltip sagt es.",
        },
    },
    {
        version = "6.134.0.1",
        date    = "22.10.2026",
        notes   = {
            "|cff7C6CFFMerkliste überlappt die Details nicht mehr|r – die Liste wird schmaler, sobald rechts ein Gegenstand gezeigt wird.",
        },
    },
    {
        version = "6.134.0.0",
        date    = "22.10.2026",
        notes   = {
            "|cff7C6CFFEinkaufsliste auf die Merkliste|r – ein Klick auf einen Gegenstand im Planer merkt ihn vor.",
            "|cff7C6CFFGegenstände der Merkliste mit Details|r – Klick zeigt rechts Auktionspreis, Preisverlauf der letzten 7 Tage und wo du es findest: eigene Sammelstellen auf der Karte oder Dungeonbeute.",
        },
    },
    {
        version = "6.133.0.0",
        date    = "22.10.2026",
        notes   = {
            "|cff7C6CFFDer Skill-Weg führt dich bis zum Ende des Berufs|r – „mach so viele hiervon, dann zum Lehrer, lerne dieses Rezept, dann so viele davon“, mit dem nächsten Rang beim Lehrer und Händlerrezepten, wo der Lehrer nichts hat. Ein Rezept bleibt, solange es noch fast sicher Punkte bringt.",
        },
    },
    {
        version = "6.132.0.1",
        date    = "22.10.2026",
        notes   = {
            "|cff7C6CFFSkill-Weg rechts neben den Berufsreitern|r – er lag über ihnen und folgt jetzt der gewählten Optik (z. B. Transparent).",
        },
    },
    {
        version = "6.132.0.0",
        date    = "22.10.2026",
        notes   = {
            "|cff7C6CFFSkill-Weg direkt am Berufsfenster|r – neben dem Fenster steht, was du am besten herstellst, um den offenen Beruf hochzubringen: Rezept, Anzahl und Fertigkeitsbereich in den Farben des Berufsfensters. Mit × einklappen, mit „Skill-Weg“ wieder zeigen.",
        },
    },
    {
        version = "6.131.4.0",
        date    = "22.10.2026",
        notes   = {
            "|cff7C6CFF„Taschen voll“ sagt, warum nichts zum Tauschen da ist|r – statt „alles geschützt“ steht dort, was deine Taschen füllt (z. B. Grünes, Verbrauchbares, Handwerk) und wie du Grünes zuschaltest.",
        },
    },
    {
        version = "6.131.3.0",
        date    = "22.10.2026",
        notes   = {
            "|cff7C6CFFDebuff-Rand im Gruppenrahmen eingerückt|r – er liegt jetzt innerhalb des Rahmens, auch wenn das Spiel ihn im Kampf neu zeigt.",
        },
    },
    {
        version = "6.131.2.0",
        date    = "22.10.2026",
        notes   = {
            "|cff7C6CFFDie Debuff-Hervorhebung bleibt im Gruppenrahmen|r – der farbige Rand bei Krankheit, Gift, Magie und Fluch ragte in den Spieler darunter.",
        },
    },
    {
        version = "6.131.1.0",
        date    = "22.10.2026",
        notes   = {
            "|cff7C6CFFDer Planer plant den Beruf, den du links wählst|r – ein Werkzeug bleibt dabei offen, statt zu den Rezepten zurückzuspringen.",
        },
    },
    {
        version = "6.131.0.2",
        date    = "22.10.2026",
        notes   = {
            "|cff7C6CFFDer Auswahlrahmen der Gruppe ist wieder ganz zu sehen|r – der Lebensbalken lag über seinem Rand.",
        },
    },
    {
        version = "6.131.0.1",
        date    = "22.10.2026",
        notes   = {
            "|cff7C6CFFDie Kraftleiste bleibt im eigenen Gruppenrahmen|r – sie ragte bis an den Rahmen darunter.",
        },
    },
    {
        version = "6.131.0.0",
        date    = "22.10.2026",
        notes   = {
            "|cff7C6CFFDer Berufe-Planer kennt die Farben|r – orange und gelbe Rezepte gehen vor, grüne nur, wenn es nichts anderes gibt, und dann als „Glückssache“ markiert. Graue plant er nie.",
        },
    },
    {
        version = "6.130.0.1",
        date    = "22.10.2026",
        notes   = {
            "|cff7C6CFFKein Fehler mehr an den Gruppenrahmen|r – beim Aufbau der Gruppe meldete das Spiel einen Lua-Fehler.",
        },
    },
    {
        version = "6.130.0.0",
        date    = "22.10.2026",
        notes   = {
            "|cff7C6CFFAufgeräumte Gruppenrahmen|r – Namen mit Kontur gut lesbar, Rollensymbol und Leiterkrone liegen nicht mehr übereinander, die Kraftleiste ist eine dünne Linie am unteren Rand.",
        },
    },
    {
        version = "6.129.0.0",
        date    = "22.10.2026",
        notes   = {
            "|cff7C6CFFWerkzeuge für Berufe|r – auf der Seite „Berufe“ oben: wer in der Gilde und unter deinen Charakteren welches Rezept kann (auch im Tooltip „Herstellbar von …“), ein Planer mit dem günstigsten Weg und Einkaufsliste, eine Merkliste mit fehlenden Reagenzien und die Abklingzeiten aller Charaktere.",
            "|cff7C6CFFDie Goldmünze erscheint jetzt auch im Questfenster des Spiels|r – nicht nur im Gespräch im Codex-Stil.",
        },
    },
    {
        version = "6.128.0.0",
        date    = "22.10.2026",
        notes   = {
            "|cff7C6CFFDie wertvollste Belohnung trägt eine Goldmünze|r – bei Quests mit Auswahl siehst du sofort, welcher Gegenstand beim Händler am meisten bringt.",
        },
    },
    {
        version = "6.127.0.0",
        date    = "22.10.2026",
        notes   = {
            "|cff7C6CFFRuhigere Kämpfe|r – Namensplaketten werden in ruhigen Momenten vorbereitet statt erst, wenn viele Gegner auftauchen, und das Taschenfenster baut sich beim Umräumen nicht mehr bei jeder Kleinigkeit neu auf.",
        },
    },
    {
        version = "6.126.2.0",
        date    = "22.10.2026",
        notes   = {
            "|cff7C6CFFAuch Verbrauchbares wandert in die Bank|r – Essen, Tränke und alles mit Wirkung wird jetzt wie mit der Maus in einen freien Platz gelegt.",
        },
    },
    {
        version = "6.126.1.0",
        date    = "22.10.2026",
        notes   = {
            "|cff7C6CFFEin Rechtsklick genügt|r – Kategorien wandern jetzt Stück für Stück zwischen Taschen und Bank, statt dass das Spiel die meisten Gegenstände verwirft.",
        },
    },
    {
        version = "6.126.0.0",
        date    = "22.10.2026",
        notes   = {
            "|cff7C6CFFDeine Bank nach Kategorien|r – neben der Bank zeigt ein Fenster alles, was darin liegt, geordnet wie deine Taschen. Rechtsklick nimmt heraus, Rechtsklick auf eine Überschrift die ganze Kategorie. Einschalten unter Taschen → Kategorien.",
            "Die Ansicht der Gildenbank ist wieder entfernt.",
        },
    },
    {
        version = "6.125.1.0",
        date    = "22.10.2026",
        notes   = {
            "|cff7C6CFFTaschen nach Kategorien und Gildenbank nach Kategorien|r sind während der Beta ab Werk aus – einschalten unter Taschen → Allgemein bzw. Taschen → Kategorien.",
        },
    },
    {
        version = "6.125.0.0",
        date    = "22.10.2026",
        notes   = {
            "|cff7C6CFFKategorien umsortieren|r – unter Taschen → Kategorien legst du die Reihenfolge fest.",
            "|cff7C6CFFGildenbank nach Kategorien|r – neben der Gildenbank zeigt ein Fenster das offene Fach geordnet wie deine Taschen. Rechtsklick nimmt heraus, Rechtsklick auf eine Überschrift die ganze Kategorie. Und bei offener Gildenbank lagert der Rechtsklick auf eine Taschen-Kategorie dort ein.",
        },
    },
    {
        version = "6.124.0.0",
        date    = "22.10.2026",
        notes   = {
            "|cff7C6CFFEigene Kategorien in den Taschen|r – unter Taschen → Allgemein anlegen, dann im Taschenfenster einen Gegenstand auf die Überschrift ziehen. Er bleibt dort, auch beim nächsten Plündern. Das geht genauso mit den eingebauten Kategorien.",
        },
    },
    {
        version = "6.123.2.0",
        date    = "22.10.2026",
        notes   = {
            "|cff7C6CFFGanze Kategorien in die Bank|r – bei offener Bank legt ein Rechtsklick auf eine Überschrift in den Taschen (etwa „Handwerk“) alles daraus in die Bank.",
        },
    },
    {
        version = "6.123.1.0",
        date    = "22.10.2026",
        notes   = {
            "|cff7C6CFFKein „Jetzt neu laden“ mehr beim bloßen Öffnen|r der Einstellungen – nur, wenn du wirklich etwas änderst, das ein Neuladen braucht.",
        },
    },
    {
        version = "6.123.0.0",
        date    = "22.10.2026",
        notes   = {
            "|cff7C6CFFTaschen nach Kategorien|r – Quest, Ausrüstung, Verbrauchbar, Handwerk, Schrott und mehr, nebeneinander gepackt. Neu Geplündertes steht oben unter „Neu“ und sortiert sich beim nächsten Öffnen von selbst ein. Kategorien an- und abschaltbar unter Taschen → Allgemein.",
        },
    },
    {
        version = "6.122.3.0",
        date    = "22.10.2026",
        notes   = {
            "|cff7C6CFFGift auf die Nebenhand|r – an der Erinnerung „Nebenhand“ legt der Linksklick das Gift jetzt auf die Nebenhand (rechts: Haupthand).",
            "|cff7C6CFFDeckkraft bei Transparent wirkt weiter|r – auch der Grund der Aktionsknöpfe, der Lebens- und Ressourcenbalken und der Zauberleiste wird durchsichtiger.",
            "|cff7C6CFFTaschen mit dezentem Holz|r beim Aussehen Holz.",
        },
    },
    {
        version = "6.122.2.0",
        date    = "22.10.2026",
        notes   = {
            "|cff7C6CFF„Klassisch“ heißt jetzt „Holz“|r – und reicht weiter: Schadensanzeige, Questliste, Minikarte, die Leiste über dem Chat und die Knöpfe im Spielmenü tragen Holz und gelben Rand.",
        },
    },
    {
        version = "6.122.1.0",
        date    = "22.10.2026",
        notes   = {
            "|cff7C6CFFKlassisch: dünnerer gelber Rand|r – an allen Flächen 1 statt 2 Bildpunkte, der Ring um die runden Bilder schmaler.",
        },
    },
    {
        version = "6.122.0.0",
        date    = "22.10.2026",
        notes   = {
            "|cff7C6CFFDas Aussehen gilt jetzt auch für die Fenster des Spiels|r – Charakter, Gilde, Händler, Taschen und Co. tragen bei Klassisch Holz, bei Transparent lassen sie die Welt durchscheinen.",
            "|cff7C6CFFAuch Tooltip, Chat und Swing-Leiste|r folgen dem gewählten Aussehen.",
        },
    },
    {
        version = "6.121.0.0",
        date    = "22.10.2026",
        notes   = {
            "|cff7C6CFFTransparent nach Wunsch|r – unter Allgemein stellst du die Deckkraft ein, von fast deckend bis ganz ausgeblendet.",
            "|cff7C6CFFKlassisch ist jetzt aus Holz|r – Rahmen, Leisten und Fenster mit Holzmaserung und gelbem Rand.",
        },
    },
    {
        version = "6.120.0.0",
        date    = "22.10.2026",
        notes   = {
            "|cff7C6CFFJede Funktion im Willkommens-Assistenten hat ihr eigenes Bild|r – fahr mit der Maus über einen Helfer, und rechts siehst du, was er tut.",
            "|cff7C6CFFDie vier Arten auszusehen als eigene Bilder|r – Wie bisher, Schwarz, Transparent und Klassisch nebeneinander vergleichbar.",
        },
    },
    {
        version = "6.119.1.0",
        date    = "22.10.2026",
        notes   = {
            "|cff7C6CFFWeitere echte Bilder im Willkommens-Assistenten|r – Namensplaketten, Schadensanzeige und die kleinen Helfer.",
        },
    },
    {
        version = "6.119.0.0",
        date    = "22.10.2026",
        notes   = {
            "|cff7C6CFFDer Willkommens-Assistent zeigt echte Bilder aus dem Spiel|r – Übersicht, Fenster, Erinnerungen und Questpfeil.",
        },
    },
    {
        version = "6.118.2.0",
        date    = "22.10.2026",
        notes   = {
            "|cff7C6CFFNur Überschriften tragen Raute und Linie|r – in Listen, die ihre Zeilen weiterverwenden (Vermächtnis, Ruf, Charakter …), behielten einfache Einträge die Verzierung einer früheren Überschrift.",
            "|cff7C6CFFBeim Scrollen sofort im WeintCodex-Stil|r – neue Zeilen einer Liste werden gestaltet, sobald sie erscheinen, statt einen Augenblick später.",
        },
    },
    {
        version = "6.118.1.0",
        date    = "22.10.2026",
        notes   = {
            "|cff7C6CFFNeue Klassen bekommen ihre Erinnerungen|r – wer schon Regeln für andere Klassen hatte, bekam beim ersten Charakter einer neuen Klasse keine Vorschläge. Jetzt kommen sie einmal je Klasse dazu.",
        },
    },
    {
        version = "6.118.0.0",
        date    = "22.10.2026",
        notes   = {
            "|cff7C6CFFRegeln, die erst später greifen, stehen schon in der Liste|r – unter Erinnerungen → Regeln ausgegraut mit „aktiv ab Stufe …“.",
        },
    },
    {
        version = "6.117.0.0",
        date    = "22.10.2026",
        notes   = {
            "|cff7C6CFFErinnerungen nur für das, was du schon kannst|r – ein Buff, den der Lehrer erst auf einer höheren Stufe lehrt, wird nicht verlangt. Begleiter erst mit Zähmen bzw. Beschwören, Gifte ab Stufe 20, Waffenzauber des Schamanen erst, wenn einer gelernt ist.",
            "|cff7C6CFFPaladine als Tank|r werden an Zorn der Gerechtigkeit erinnert.",
        },
    },
    {
        version = "6.116.0.0",
        date    = "22.10.2026",
        notes   = {
            "|cff7C6CFFChat und Minikarte im Gestaltungsmodus verschieben|r – genauso wie die Aktionsleisten, ohne Bearbeitungsmodus des Spiels.",
        },
    },
    {
        version = "6.115.0.0",
        date    = "22.10.2026",
        notes   = {
            "|cff7C6CFFAktionsleisten im Gestaltungsmodus verschieben|r – ziehen, loslassen, und die Leiste steht am neuen Platz. Der Bearbeitungsmodus des Spiels wird dafür nicht mehr gebraucht. Nur außerhalb des Kampfes.",
        },
    },
    {
        version = "6.114.0.0",
        date    = "22.10.2026",
        notes   = {
            "|cff7C6CFFNeue Charaktere starten mit den Aktionsleisten 2 bis 5|r – sie sind gleich beim ersten Einloggen an.",
            "|cff7C6CFFLeisten an- und ausschalten in WeintCodex|r – unter Aktionsleisten → Leisten, ohne Umweg über die Optionen des Spiels.",
        },
    },
    {
        version = "6.113.4.0",
        date    = "22.10.2026",
        notes   = {
            "|cff7C6CFFStufe im kleinen Kreis|r einen Bildpunkt zurück nach links.",
        },
    },
    {
        version = "6.113.3.0",
        date    = "22.10.2026",
        notes   = {
            "|cff7C6CFFStufe im kleinen Kreis|r rückt das letzte Stück in die Mitte.",
        },
    },
    {
        version = "6.113.2.0",
        date    = "22.10.2026",
        notes   = {
            "|cff7C6CFFStufe im kleinen Kreis am runden Bild|r steht mittig; der Kreis sitzt wieder an seinem alten Platz.",
        },
    },
    {
        version = "6.113.1.0",
        date    = "22.10.2026",
        notes   = {
            "|cff7C6CFFStufe am runden Zielbild|r sitzt weiter im Kreis.",
        },
    },
    {
        version = "6.113.0.0",
        date    = "22.10.2026",
        notes   = {
            "|cff7C6CFFAuktionspreise bleiben ohne Scan aktueller|r – wenn du im Auktionshaus einen Gegenstand anklickst oder kaufst, merkt sich WeintCodex das jetzt günstigste Angebot. Ein billiges Angebot, das längst weg ist, steht so nicht mehr im Tooltip.",
            "|cff7C6CFFPreise von anderen Spielern|r sind im Tooltip wieder als solche gekennzeichnet.",
        },
    },
    {
        version = "6.112.0.0",
        date    = "21.10.2026",
        notes   = {
            "|cff7C6CFFZahlen auf Abklingzeiten und Schnell-Plündern|r sind nach der ersten Einrichtung an. Danach gehören beide Einstellungen dir – ausschalten bleibt aus.",
        },
    },
    {
        version = "6.111.0.0",
        date    = "21.10.2026",
        notes   = {
            "|cff7C6CFFWeiter wegzoomen|r – unter Komfort → Alltag → Anzeigen stellst du ein, wie weit die Kamera vom Charakter weg darf. „Wie im Spiel“ gibt die Einstellung des Spiels zurück.",
        },
    },
    {
        version = "6.110.5.0",
        date    = "21.10.2026",
        notes   = {
            "|cff7C6CFFKein Dauer-Hinweis für schwächere Elixiere|r – sagt das Spiel beim Benutzen „Ein mächtigerer Zauber ist bereits aktiv“, schweigt die Erinnerung zu diesem Elixier, bis der stärkere Buff ausgelaufen ist.",
        },
    },
    {
        version = "6.110.4.0",
        date    = "21.10.2026",
        notes   = {
            "|cff7C6CFFFlugzeit über den Flugspielen|r – solange ein Flugspiel offen ist, steht die Flugzeitleiste direkt über dem Fenster statt darunter verdeckt. Danach wieder an ihrem Platz.",
        },
    },
    {
        version = "6.110.3.0",
        date    = "21.10.2026",
        notes   = {
            "|cff7C6CFFRunde Rahmen: Schrift frei|r – Name beim Spieler und Leben beim Ziel rücken ein Stück vom runden Porträt weg, statt unter dem Ring zu beginnen.",
        },
    },
    {
        version = "6.110.2.0",
        date    = "21.10.2026",
        notes   = {
            "|cff7C6CFFRundes Porträt wieder als Bild|r – ein bewegter Kopf lässt sich im Spiel nicht rund zuschneiden: er wurde abgeschnitten oder ragte über den Ring. Rund zeigt jetzt sauber das Bild; bewegt bleibt der Kopf in der flachen Form.",
        },
    },
    {
        version = "6.110.1.0",
        date    = "21.10.2026",
        notes   = {
            "|cff7C6CFFRundes Porträt ohne Kanten|r – der bewegte Kopf wurde an einem kleinen Quadrat abgeschnitten. Jetzt füllt er den Kreis mit etwas Abstand. Die Stufe sitzt auf der Seite zum Balken.",
        },
    },
    {
        version = "6.110.0.0",
        date    = "21.10.2026",
        notes   = {
            "|cff7C6CFFRundes Porträt bewegt sich|r – mit Porträt „3D-Modell“ ist der Kopf im runden Rahmen animiert. „Bild“ zeigt wie bisher das stehende Bild.",
        },
    },
    {
        version = "6.109.0.0",
        date    = "21.10.2026",
        notes   = {
            "|cff7C6CFFRundes Porträt im eigenen Design|r – Ring und Stufenplakette tragen Rand und Fläche des gewählten Designs: schwarz, transparent oder golden (Klassisch).",
        },
    },
    {
        version = "6.108.0.0",
        date    = "21.10.2026",
        notes   = {
            "|cff7C6CFFSpieler- und Zielrahmen klassisch|r – rundes Porträt mit goldenem Ring und die Stufe als kleine Plakette. Kommt von selbst mit dem Design „Klassisch“; je Rahmen unter Einheitenrahmen → Form auch einzeln.",
        },
    },
    {
        version = "6.107.0.0",
        date    = "21.10.2026",
        notes   = {
            "|cff7C6CFFAlle Leisten ab Werk sichtbar|r – weitere Aktionsleisten verschwanden außerhalb des Kampfes ganz. Neue Spieler sehen jetzt alles; ausblenden geht unter Allgemein → Ruhe und Kampf.",
            "|cff7C6CFFNeuer Charakter: „Frisch beginnen“|r – in der Profilfrage ein eigenes Profil mit den Grundeinstellungen statt einer Kopie.",
        },
    },
    {
        version = "6.106.0.0",
        date    = "21.10.2026",
        notes   = {
            "|cff7C6CFFAbklingzeiten von WeintCodex ab Werk|r – wer noch nie gewählt hat, bekommt den eigenen Manager; die Anzeige des Spiels geht dafür aus. Zurück auf Blizzard: Erinnerungen → Abklingzeitmanager.",
            "|cff7C6CFFSammel-Atlas ab Werk an|r – Fundstellen von Kräutern, Erz und Truhen auf Welt- und Minikarte.",
            "|cff7C6CFFDesign jederzeit wechseln|r – „Design der Oberfläche“ steht jetzt ganz oben unter Einstellungen → Allgemein.",
        },
    },
    {
        version = "6.105.0.0",
        date    = "21.10.2026",
        notes   = {
            "|cff7C6CFFWillkommen, einfacher|r – vier Schritte statt acht: Willkommen, Aussehen, Helfer, fertig. Bei den Helfern reicht ein Klick auf „Empfohlen“; wer mag, wählt selbst.",
            "|cff7C6CFFErscheinungsbild wählbar|r – Schwarz, Transparent (die Welt scheint durch) oder Klassisch (warm, mit goldenem Rand). Im Willkommen mit Vorschau, später unter Einstellungen → Allgemein.",
        },
    },
    {
        version = "6.104.0.0",
        date    = "21.10.2026",
        notes   = {
            "|cff7C6CFFLehrer: wo lerne ich das?|r – ein Klick auf einen Zauber zeigt rechts den nächsten Lehrer deiner Klasse mit kleiner Karte und Pin. „Questpfeil hierhin“ führt dich hin. Noch ein Klick wählt ab.",
        },
    },
    {
        version = "6.103.5.0",
        date    = "20.10.2026",
        notes   = {
            "|cff7C6CFFQuestpfeil ruhiger|r – er zeigt jetzt aufs Ziel, solange der Weg ungefähr geradeaus geht. Nur wenn wirklich etwas im Weg ist (Berg, Wasser, Mauer), folgt er dem Laufweg. Kein Zittern mehr bei jedem kleinen Knick.",
        },
    },
    {
        version = "6.103.4.0",
        date    = "20.10.2026",
        notes   = {
            "|cff7C6CFFQuestpfeil ohne Umweg|r – nahe einer unsichtbaren Abschnittsgrenze der Welt zeigte der Pfeil oft zur Seite und nannte eine zu große Entfernung. Jetzt sucht er auch den direkten Weg über das Gelände und nimmt den kürzeren.",
        },
    },
    {
        version = "6.103.3.0",
        date    = "20.10.2026",
        notes   = {
            "|cff7C6CFFElixiere und Schriftrollen genauer|r – kein Vorschlag mehr, wenn schon ein Elixier oder eine Rolle für denselben Wert wirkt (etwa Rüstung). Für andere Werte schlägt die Erinnerung beides wieder vor – die pauschale Sperre der letzten Fassung war zu grob.",
        },
    },
    {
        version = "6.103.2.0",
        date    = "20.10.2026",
        notes   = {
            "|cff7C6CFFElixier oder Schriftrolle|r – ist eine Schriftrolle aktiv, schlägt die Erinnerung kein Elixier mehr vor, und umgekehrt. Beides zugleich geht auf Forever nicht.",
        },
    },
    {
        version = "6.103.1.0",
        date    = "20.10.2026",
        notes   = {
            "|cff7C6CFFZorn der Gerechtigkeit|r hat jetzt eine eigene Uhr (30 Minuten) bei den Buffzeiten. Läuft er ab, meldet die Erinnerung „fehlt“ auch im Kampf – wenn „Auch im Kampf“ an ist. Das gilt für jeden selbst gewirkten Buff mit bekannter Dauer.",
        },
    },
    {
        version = "6.103.0.0",
        date    = "20.10.2026",
        notes   = {
            "|cff7C6CFFEinstellungen aufgeräumt|r – Komfort ist nicht mehr ein Eintrag mit 17 Reitern, sondern vier Themen in der Seitenleiste: Alltag, Kampf & Gruppe, Welt & Karte, Handel & Gespräche. Alles steht, wo man es sucht; Gespeichertes bleibt, wie es war.",
            "|cff7C6CFFNichts mehr versteckt|r – den Knopf „Erweitert“ gibt es nicht mehr. Seltener Gebrauchtes steht immer sichtbar unten auf der Seite unter „Feineinstellungen“.",
            "|cff7C6CFFFlugspiele|r stehen jetzt unter Welt & Karte.",
            "|cff7C6CFFTaschen-Fehlerbericht genauer|r – der Bericht nennt jetzt den Moment, in dem Bank- oder Postfenster gestört wurden. Hilft, „Verboten: UseContainerItem()“ endlich zu finden.",
        },
    },
    {
        version = "6.102.2.0",
        date    = "20.10.2026",
        notes   = {
            "|cff7C6CFFSegen: kein Fehler mehr beim Angreifen|r – der Knopf wurde beim Kampfbeginn noch umgestellt, das sperrt das Spiel. Im Kampf ändert sich jetzt nur die Zeile „Im Kampf“.",
        },
    },
    {
        version = "6.102.1.0",
        date    = "20.10.2026",
        notes   = {
            "|cff7C6CFFKomfort → Segen nur für Paladine|r – andere Klassen sehen die Seite nicht mehr.",
        },
    },
    {
        version = "6.102.0.0",
        date    = "20.10.2026",
        notes   = {
            "|cff7C6CFFSegen: große Segen|r – kennst du einen großen Segen und sollen alle einer Klasse denselben bekommen, segnet ein Klick die ganze Klasse (abschaltbar). Die falsche Aussage „gibt es auf Forever nicht“ ist weg.",
            "|cff7C6CFFNur noch 60-Minuten-Segen zur Wahl|r – Macht, Weisheit, Könige, Licht.",
        },
    },
    {
        version = "6.101.0.0",
        date    = "20.10.2026",
        notes   = {
            "|cff7C6CFFSegen je Klasse und Rolle|r – erst die Klasse wählen, dann je Rolle den Segen: Druide Tank/Heiler/Nahkampf/Zauberschaden, Schamane Heiler/Nahkampf/Zauberschaden usw. Darunter steht der Überblick aller Klassen.",
            "|cff7C6CFFRolle aus den Talenten|r – WeintCodex liest, wie jemand geskillt ist: deine Talente direkt, die der anderen durch kurzes Betrachten (nur außerhalb des Kampfes, einer nach dem anderen). Ohne Talente gilt die Gruppenrolle.",
        },
    },
    {
        version = "6.100.1.0",
        date    = "20.10.2026",
        notes   = {
            "|cff7C6CFFSegen: frei verschiebbar und verschwindet|r – den Rahmen einfach mit der Maus ziehen (außerhalb des Kampfes), der Platz wird gemerkt. Sind alle gesegnet, verschwindet er und kommt wieder, sobald jemand seinen Segen braucht.",
        },
    },
    {
        version = "6.100.0.0",
        date    = "20.10.2026",
        notes   = {
            "|cff7C6CFFPaladine: Segen verteilen|r – neue Seite Komfort → Segen: je Klasse (und unter „Erweitert“ je Rolle) einen Segen festlegen. Ein kleiner Rahmen mit „Buffen“ setzt bei jedem Klick den nächsten fehlenden Segen auf das richtige Gruppenmitglied – nachdenken entfällt. Auch als Taste belegbar. Nur außerhalb des Kampfes.",
        },
    },
    {
        version = "6.99.1.0",
        date    = "20.10.2026",
        notes   = {
            "|cff7C6CFFSeelensplitter: löschen wie früher|r – das Spiel löscht nur während einer Eingabe. WeintCodex löscht überzählige Splitter deshalb beim nächsten Tastendruck oder Klick in die Welt (laufen, zaubern) – fühlt sich an wie von selbst, die Taste wirkt trotzdem. Keine Fehlermeldung mehr.",
        },
    },
    {
        version = "6.99.0.0",
        date    = "20.10.2026",
        notes   = {
            "|cff7C6CFFHexenmeister: Seelensplitter begrenzen|r – unter Komfort → Automatik stellst du ein, wie viele Seelensplitter du behältst (1–40); jeder weitere wird gleich gelöscht. Nur Seelensplitter, nie im Kampf. Lässt das Spiel das Löschen nur auf Klick zu, erscheint ein Knopf „… zu viel – löschen“.",
        },
    },
    {
        version = "6.98.2.0",
        date    = "20.10.2026",
        notes   = {
            "|cff7C6CFFAbklingzeitmanager: jede Reihe einzeln einstellen|r – Klick auf den Kopf einer Spalte („Menü ›“): Symbolgröße, waagerecht oder senkrecht, Symbole je Zeile, Abstand und „Nur im Kampf zeigen“ – für Wichtig, Weitere und jede eigene Reihe. Die Buffs-Reihe unter „Erweitert“.",
        },
    },
    {
        version = "6.98.1.0",
        date    = "20.10.2026",
        notes   = {
            "|cff7C6CFFAbklingzeitmanager: neue Reihen erscheinen sofort|r – die Einstellungsseite baut sich nach „Reihe hinzufügen“, Umbenennen, Löschen und Ziehen neu auf; die neue Spalte steht direkt da (bis drei nebeneinander, „Aus“ rutscht darunter).",
            "|cff7C6CFFEigene Reihen löschen|r – über den Kopf der Spalte („Menü ›“) oder unter „Erweitert“ → „Reihe löschen …“.",
            "|cff7C6CFFProfil-Export mit Abklingzeitmanager|r – Export und Import nehmen jetzt auch den eigenen Abklingzeitmanager mit: Wahl, Zauber und Reihenfolge, eigene Reihen, Töne, Leuchten.",
        },
    },
    {
        version = "6.98.0.0",
        date    = "20.10.2026",
        notes   = {
            "|cff7C6CFFAbklingzeitmanager: eigene Reihen|r – bis zu sechs weitere Reihen mit eigenem Namen anlegen („Neue Reihe“ → „Reihe hinzufügen“). Jede ist eine Spalte zum Hineinziehen und ein eigener Rahmen im Gestaltungsmodus. Klick auf ihren Spaltenkopf: umbenennen, Symbolgröße, löschen.",
        },
    },
    {
        version = "6.97.3.0",
        date    = "20.10.2026",
        notes   = {
            "|cff7C6CFFAbklingzeitmanager: grau auch im Kampf|r – im Kampf hält das Spiel die Abklingzeit geheim; WeintCodex rechnet sie jetzt ab deinem Wirken selbst mit (Länge einmal außerhalb des Kampfes gelernt), Arkaner Schuss und Co. werden grau.",
            "|cff7C6CFFTauschfenster kompakter|r – Beute oben, Taschenplatz darunter, Knopf darunter; schmal statt langgezogen. Daneben steht klar „Lohnt sich“ oder „Lohnt nicht – dein Platz ist mehr wert“.",
        },
    },
    {
        version = "6.97.2.0",
        date    = "20.10.2026",
        notes   = {
            "|cff7C6CFFVolle Taschen: Fenster kommt immer|r – passt Beute nicht mehr hinein, zeigt das Fenster jetzt jedes Mal den Vergleich mit deinem billigsten Platz. Lohnt der Tausch nicht, steht dort „Trotzdem tauschen“; ist alles geschützt, sagt es das.",
            "|cff7C6CFFHändler- und Auktionspreis|r – im Fenster stehen für Beute und Taschenplatz beide Preise nebeneinander.",
        },
    },
    {
        version = "6.97.0.0",
        date    = "20.10.2026",
        notes   = {
            "|cff7C6CFFAbklingzeitmanager: Ziehen sichtbar|r – der gezogene Zauber hängt an der Maus, und die Zeile, vor der er landet, leuchtet auf.",
            "|cff7C6CFFErklärung über den Spalten|r – kurz, was Wichtig/Weitere/Aus bedeuten und wie Ziehen und Klicken funktionieren.",
        },
    },
    {
        version = "6.96.0.0",
        date    = "20.10.2026",
        notes   = {
            "|cff7C6CFFAbklingzeitmanager: grau bei Abklingzeit|r – ein Zauber ist jetzt auch grau, solange seine Abklingzeit läuft, nicht nur wenn er gerade nicht geht.",
            "|cff7C6CFFLeuchten einstellbar|r – unter „Erweitert“: pulsieren an/aus, Farbe (Grün, Gold, Klassenfarbe, Rot, Blau, Weiß) und Stärke.",
        },
    },
    {
        version = "6.95.1.0",
        date    = "20.10.2026",
        notes   = {
            "|cff7C6CFFKomfort → Sammeln: „Volle Taschen beim Looten“|r – der Abschnitt mit dem Schalter für das Fenster „Löschen & looten“ steht jetzt wirklich dort (Grünes und Auktionspreis unter „Erweitert“).",
        },
    },
    {
        version = "6.95.0.0",
        date    = "20.10.2026",
        notes   = {
            "|cff7C6CFFAbklingzeitmanager: alle Töne des Spiels|r – das Tonmenü bietet jetzt dieselben Töne wie der Abklingzeitmanager von Blizzard: Tiere, Geräte, Treffer, Instrumente, Kurz, Warcraft 2 und Warcraft 3, mit den Namen des Spiels. Dazu die eigenen Töne und Vorlesen.",
        },
    },
    {
        version = "6.94.0.0",
        date    = "20.10.2026",
        notes   = {
            "|cff7C6CFFVolle Taschen beim Looten|r – passt Beute nicht mehr und ist sie mehr wert als dein billigster Platz, öffnet sich ein Fenster: Beute gegen Taschenplatz, Knopf „Löschen & looten“. Gelöscht wird nur auf deinen Klick. Die Seite „Ausmisten“ ist dafür weg.",
            "|cff7C6CFFNie vorgeschlagen|r – Werkzeuge der Berufe (Kürschnermesser, Spitzhacke, Angel …), Handwerksmaterial und Questgegenstände.",
            "|cff7C6CFFDoT-Zeit je Ziel|r – liegt Schlangenbiss auf zwei Gegnern, zeigt der Abklingzeitmanager beim Zielwechsel die Restzeit des jeweiligen Ziels.",
        },
    },
    {
        version = "6.93.2.0",
        date    = "20.10.2026",
        notes   = {
            "|cff7C6CFFAbklingzeitmanager: Klicken und Ziehen|r – geht in den drei Spalten wieder; die Spalten lagen über den Zaubern und schluckten jeden Klick.",
        },
    },
    {
        version = "6.93.1.0",
        date    = "20.10.2026",
        notes   = {
            "|cff7C6CFFAbklingzeitmanager: Klickfeld erscheint|r – Rang, Leuchten, Ton und Spalte öffnen sich jetzt wirklich neben dem Zauber; vorher schnitt die Seite das Feld ab.",
            "|cff7C6CFFEinstellungen: Größe ändern|r – Griff unten rechts zieht das Fenster höher oder niedriger, Strg + Mausrad über der linken Leiste macht es größer oder kleiner. Beides wird gemerkt.",
        },
    },
    {
        version = "6.93.0.0",
        date    = "20.10.2026",
        notes   = {
            "|cff7C6CFFAbklingzeitmanager: Tonhinweis wie im Spiel|r – Menü mit Gruppen (WeintCodex, Warnungen und Hinweise des Spiels, Huhn) und „Vorlesen“, dazu „Ton wann“: verfügbar oder DoT ausgelaufen.",
            "|cff7C6CFFAusgegraut, wenn nicht nutzbar|r – kann ein Zauber gerade nicht gewirkt werden (Proc fehlt, kein Mana), ist sein Symbol grau und wird wieder farbig, sobald er geht.",
            "|cff7C6CFFLeuchten für DoTs|r – „Leuchten: wenn DoT fehlt/ausläuft“ macht Schlangenbiss und Co. hell, wenn sie auf deinem Ziel fehlen oder in 3 s auslaufen. Ab Werk für DoTs gewählt.",
        },
    },
    {
        version = "6.92.1.0",
        date    = "20.10.2026",
        notes   = {
            "|cff7C6CFFAbklingzeitmanager: Ziehen zwischen Spalten|r – klappt wieder; zusätzlich schaltet „Spalte“ im Klickfeld eines Zaubers um. Das verwirrende „Licht“ hinter jedem Zauber ist weg, rechts steht nur noch „Ton“, wenn einer eingestellt ist.",
            "|cff7C6CFFTaschen: Ausmisten im Taschenfenster|r – neuer Knopf „Ausmisten“ neben „Sortieren“ umrandet die billigsten Plätze gold; unten steht, wie viele es sind und was sie wert sind.",
        },
    },
    {
        version = "6.92.0.0",
        date    = "20.10.2026",
        notes   = {
            "|cff7C6CFFAbklingzeitmanager: drei Spalten|r – Wichtig, Weitere und Aus nebeneinander. Ziehen ordnet innerhalb einer Spalte oder schiebt in eine andere.",
            "|cff7C6CFFJe Zauber einstellbar|r – ein Klick öffnet Rang, Leuchten und Ton, wenn der Zauber bereit ist.",
            "|cff7C6CFFDoT-Laufzeit|r – eigene DoTs wie Schlangenbiss zeigen am Symbol, wie lange sie auf deinem Ziel noch laufen (rückwärts laufende Uhr).",
            "|cff7C6CFFBlizzards Manager ausgegraut|r – solange oben nicht „Blizzard“ gewählt ist.",
        },
    },
    {
        version = "6.91.0.0",
        date    = "20.10.2026",
        notes   = {
            "|cff7C6CFFAbklingzeitmanager: alle Zauber|r – die Liste liest jetzt dein ganzes Zauberbuch, je Zauber den höchsten Rang. Was nicht in der Voreinstellung steht, ist zunächst „Aus“.",
            "|cff7C6CFFAbklingzeitmanager: Reihenfolge per Ziehen|r – einen Zauber in der Liste auf einen anderen ziehen setzt ihn davor.",
            "|cff7C6CFFAbklingzeitmanager: selbst hinzufügen|r – Zauber oder Gegenstand per Name oder Nummer eintragen oder direkt aus Zauberbuch und Taschen auf die Liste ziehen; Rechtsklick entfernt ihn wieder. Gegenstände zeigen ihre Abklingzeit.",
        },
    },
    {
        version = "6.90.1.0",
        date    = "20.10.2026",
        notes   = {
            "|cff7C6CFFAbklingzeitmanager: Leuchten|r – liegt jetzt als Rand um das Symbol statt als grüne Fläche darüber.",
            "|cff7C6CFFAbklingzeitmanager: Anordnung|r – waagerecht oder senkrecht und „Symbole je Zeile“ zum Umbrechen; in der Zauberliste steht der Rang, ein Tooltip zeigt den Zauber.",
        },
    },
    {
        version = "6.90.0.0",
        date    = "20.10.2026",
        notes   = {
            "|cff7C6CFFEigener Abklingzeitmanager|r – unter Erinnerungen → Abklingzeitmanager wählst du jetzt „Blizzard“, „WeintCodex“ oder „Keiner“. Der eigene zeigt drei Reihen (Wichtig, Weitere, Buffs) mit Voreinstellung je Klasse; ein Klick auf einen Zauber schaltet Wichtig → Weitere → Aus. Blizzards Anzeige wird dabei ausgeblendet und beim Zurückwechseln wiederhergestellt.",
            "|cff7C6CFFTaschen: Ausmisten|r – zeigt die billigsten Plätze in deinen Taschen mit Wert und Grund, „Behalten“ je Gegenstand. Sind die Taschen beim Looten voll, markiert eine Goldmünze Beute, die mehr wert ist, und der Platz, der dafür weichen könnte, leuchtet. Gelöscht wird nie von selbst.",
            "|cff7C6CFFMessenger: Antworten-Taste|r – „Auf Flüstern antworten“ (R oder deine eigene Belegung) öffnet jetzt verlässlich das Fenster.",
        },
    },
    {
        version = "6.89.1.0",
        date    = "20.10.2026",
        notes   = {
            "|cff7C6CFFBeute: Suchfeld|r – deutlich sichtbar: eine runde Leiste über die ganze Breite mit Lupe, größerer Schrift und einem Rand in deiner Klassenfarbe, sobald du tippst. Ein Klick irgendwo in die Leiste setzt den Cursor.",
        },
    },
    {
        version = "6.89.0.0",
        date    = "20.10.2026",
        notes   = {
            "|cff7C6CFFFlugspiele: Bestenliste der Gilde|r – je Spiel die besten 10 aller Zeiten und die Besten auf deiner Flugstrecke, dein Eintrag hervorgehoben. Nach jedem Spiel steht dein Platz im Ergebnis. Dafür gehen Spiel, Punkte, Strecke und Flugdauer still an die Gilde; ausschaltbar unter Komfort → Flugspiele → „Bestenliste mit der Gilde teilen“.",
        },
    },
    {
        version = "6.88.0.0",
        date    = "20.10.2026",
        notes   = {
            "|cff7C6CFFHerstellzeit|r – stellst du mehrere Stücke auf einmal her (Barren verhütten, Stoff, Tränke …), zeigt eine Leiste oben: was, wie viele von wie vielen und wie lange es noch dauert. Die Dauer je Stück nennt das Spiel beim Herstellen. Komfort → Sammeln, ab Werk an; verschiebbar im Gestaltungsmodus.",
        },
    },
    {
        version = "6.87.9.0",
        date    = "19.10.2026",
        notes   = {
            "|cff7C6CFFBuffzeiten: Siegel des Furors|r – vor dem Kampf gewirkt, verschwand es gleich wieder, und im Kampf stand „fehlt“: der Abgleich mit deinen Buffs suchte es unter der Classic-Nummer und fand es nicht. Jetzt erkennt der Abgleich Buffs auch am Namen.",
        },
    },
    {
        version = "6.87.8.0",
        date    = "19.10.2026",
        notes   = {
            "|cff7C6CFF/rl|r – das Fenster war leer bis auf „Abbrechen“: Text und Knopf „Neu laden“ lagen unter der Fläche. Jetzt sichtbar, beide Knöpfe rund; Enter funktioniert auch beim ersten Öffnen.",
        },
    },
    {
        version = "6.87.7.0",
        date    = "19.10.2026",
        notes   = {
            "|cff7C6CFFTastenbelegung|r – die Warnung „Binding header WEINTCODEX was attempted to be loaded more than once“ beim Laden ist behoben.",
        },
    },
    {
        version = "6.87.6.0",
        date    = "19.10.2026",
        notes   = {
            "|cff7C6CFFMessenger|r – Shift-Klick auf einen Stapel in den Taschen verlinkt ihn, ohne dass das Fenster zum Teilen des Stapels aufgeht – wie beim Verlinken in der Gilde.",
            "|cff7C6CFFBuffzeiten: Siegel des Furors|r – Forever wirkt manche Zauber unter einer anderen Nummer als Classic. Erkennt WeintCodex eine Nummer nicht, vergleicht es jetzt den Namen des Zaubers. /wcui prüfen nennt die zuletzt unbekannte Nummer.",
        },
    },
    {
        version = "6.87.5.0",
        date    = "19.10.2026",
        notes   = {
            "|cff7C6CFFDirekt neu laden|r – unter Tastenbelegung → AddOns → WeintCodex → „Oberfläche neu laden“ eine Taste vergeben: ein Druck lädt sofort neu, ohne Frage. Ein Chatbefehl wie /rl darf das auf Forever nicht direkt, darum fragt /rl weiter kurz nach.",
        },
    },
    {
        version = "6.87.4.0",
        date    = "19.10.2026",
        notes   = {
            "|cff7C6CFF/rl|r – lädt die Oberfläche neu: eine kleine Frage, Enter bestätigt. Direkt neu laden dürfen Addons auf Forever nicht, darum der eine Tastendruck mehr. /reload geht wie immer. Hat schon ein anderes Addon /rl, bleibt es dessen.",
        },
    },
    {
        version = "6.87.3.0",
        date    = "19.10.2026",
        notes   = {
            "|cff7C6CFFBuffzeiten: Siegel|r – Richturteil beendet das Siegel nicht mehr. Auf Forever „entfesselt“ Richturteil nur seine Energie, das Siegel bleibt seine 30 Sekunden aktiv – WeintCodex hatte es wie in Classic als verbraucht gezählt und darum „fehlt“ gezeigt.",
        },
    },
    {
        version = "6.87.2.0",
        date    = "19.10.2026",
        notes   = {
            "|cff7C6CFFBuffzeiten|r – nach Richturteil im Kampf zeigte das „fehlt“-Symbol ein weißes Feld. Jetzt steht dort grau mit „!“ das Siegel, das du zuletzt gewirkt hast.",
        },
    },
    {
        version = "6.87.1.0",
        date    = "19.10.2026",
        notes   = {
            "|cff7C6CFFMessenger|r – Shift-Linksklick auf einen Gegenstand verlinkt ihn ins Eingabefeld, wie in der Chatzeile des Spiels.",
            "|cff7C6CFFAbklingzeitmanager|r – „Jetzt einrichten“ legt ein eigenes Profil „WeintCodex“ neben deine Profile, auch wenn du schon eins hast; dein Profil bleibt unverändert, und beim Ausschalten kehrt das vorher aktive zurück. Von selbst richtet WeintCodex weiterhin nur ein, wenn du keins hast. Siegel des Furors steht jetzt in der Buffreihe.",
        },
    },
    {
        version = "6.87.0.0",
        date    = "19.10.2026",
        notes   = {
            "|cff7C6CFFBuffzeiten aus Zaubern|r – für alle Klassen eine kleine Symbolreihe unter dem Charakter: Siegel (30 s, Richturteil verbraucht es), Aspekte, Rüstungen, Inneres Feuer, Schilde und Waffenbuffs, Schlachtruf und Haltungen, Zerhäckseln, Gestalten, Mal und Dornen. Gezählt wird ab deinem Zauber, weil das Spiel Buffs im Kampf nicht herausgibt; außerhalb des Kampfes gleicht WeintCodex mit den echten Buffs ab. Fehlt im Kampf ein Siegel oder Aspekt, wird das Symbol grau mit „!“. Erinnerungen → Buffzeiten, ab Werk an.",
        },
    },
    {
        version = "6.86.0.0",
        date    = "19.10.2026",
        notes   = {
            "|cff7C6CFFAbklingzeitmanager je Klasse|r – WeintCodex richtet den Abklingzeitmanager des Spiels für deine Klasse ein: oben klein deine Buffs (Siegel und Auren, Aspekte, Rüstungen, Schilde …), darunter die wichtigen Fähigkeiten. In einem eigenen Layout „WeintCodex“ – hast du schon ein eigenes, ändert sich nichts. Wirkt nach dem Neuladen. Erinnerungen → Abklingzeitmanager, ab Werk an, mit „Jetzt einrichten“.",
        },
    },
    {
        version = "6.85.0.0",
        date    = "19.10.2026",
        notes   = {
            "|cff7C6CFFBeute: Forever-Dungeons|r – stehen jetzt nach Stufe an ihrem Platz zwischen den alten Dungeons statt ganz unten und tragen „Forever neu“.",
            "|cff7C6CFFBeute: große Listen|r – WeintCodex fragt höchstens 20 Namen je Sekunde an. Bei den Sets flutete es den Server, eingegrenzt kam alles an; jetzt füllt sich auch die volle Liste nach und nach.",
        },
    },
    {
        version = "6.84.9.0",
        date    = "19.10.2026",
        notes   = {
            "|cff7C6CFFBeute|r – Namen fragt WeintCodex jetzt auf vier Wegen beim Spiel an statt nur auf einem. Nennt das Spiel nach mehreren Versuchen keinen Namen, steht „vom Spiel nicht genannt“ statt endlos „lädt …“. Rechts zeigt „Namen vom Client“, welcher Weg geantwortet hat.",
        },
    },
    {
        version = "6.84.8.0",
        date    = "19.10.2026",
        notes   = {
            "|cff7C6CFFBeute|r – Namen, die nicht kommen, fragt WeintCodex nach ein paar Sekunden erneut an (bei großen Listen wie den Sets ließ der Server Anfragen fallen – es blieb bei „lädt …“). Der Stern zum Merken ist ein Bild statt eines Zeichens, das die Schrift nicht kannte (es stand „?“). Der Hinweis über der Liste hat eine eigene Zeile und läuft nicht mehr über Suche und Liste.",
        },
    },
    {
        version = "6.84.7.0",
        date    = "19.10.2026",
        notes   = {
            "|cff7C6CFFSammel-Atlas auf der Minikarte|r – der Ring ist hauchdünn mit großem Loch: ein Vorkommen des Spiels steht ganz frei darin und wird nicht mehr angeschnitten.",
        },
    },
    {
        version = "6.84.6.0",
        date    = "19.10.2026",
        notes   = {
            "|cff7C6CFFSammel-Atlas|r – Ringe auf der Minikarte kleiner und sauberer: dünn, mit weichem Schatten statt dickem dunklem Rand. Der Knopf „Weiter“ am Pfeil ist jetzt rund wie die Farm-Leiste.",
        },
    },
    {
        version = "6.84.5.0",
        date    = "19.10.2026",
        notes   = {
            "|cff7C6CFFFarmroute: „Weiter“ am Pfeil|r – solange du einer Farmroute folgst, steht rechts am Questpfeil ein kleiner Knopf „Weiter“: ein Klick lässt den Halt aus. Auch im Kampf.",
        },
    },
    {
        version = "6.84.4.0",
        date    = "19.10.2026",
        notes   = {
            "|cff7C6CFFFarmroute: Halt überspringen|r – zu viele Gegner an einem Halt? Knopf „Halt überspringen“ in der Farm-Leiste, eine eigene Taste (Tastenbelegung → AddOns → WeintCodex) oder /wcui weiter – der Pfeil zeigt zum nächsten. Taste und Befehl gehen auch im Kampf.",
        },
    },
    {
        version = "6.84.3.0",
        date    = "19.10.2026",
        notes   = {
            "|cff7C6CFFSammel-Atlas auf der Minikarte|r – kommt dein Spielerpfeil einem Ring nahe, blendet der Ring weich aus und kommt beim Weggehen wieder.",
        },
    },
    {
        version = "6.84.2.0",
        date    = "19.10.2026",
        notes   = {
            "|cff7C6CFFFarmroute folgen|r – am Halt angekommen geht der Pfeil jetzt zum nächsten weiter. Bisher löste das Spiel beim Erreichen seinen Wegpunkt, und WeintCodex hielt das für „aufgehört“. Ein Halt gilt ab 15 m als erreicht.",
        },
    },
    {
        version = "6.84.1.0",
        date    = "19.10.2026",
        notes   = {
            "|cff7C6CFFSammel-Atlas auf der Minikarte|r – der Ring ist größer und dünner, das Vorkommen des Spiels steht ganz frei in seiner Mitte.",
        },
    },
    {
        version = "6.84.0.0",
        date    = "19.10.2026",
        notes   = {
            "|cff7C6CFFBeute|r – neue Seite unter „Dungeons“: Beute aller Dungeons, Schlachtzüge, Weltbosse, Ruf, PvP und Sets nach Instanz und Boss, mit Symbol, Qualität, Platz und Dropchance. Tooltip beim Zeigen, Shift-Klick verlinkt, Strg-Klick zeigt die Anprobe, Stern setzt auf die Wunschliste. Classic-Inhalte „aus Classic“, neue Forever-Inhalte „unbestätigt“. /wc beute",
            "|cff7C6CFFSammel-Atlas auf der Minikarte|r – der offene Ring aus 6.83.4.0 ist jetzt wirklich drin (dort fehlte die Änderung am Code).",
        },
    },
    {
        version = "6.83.4.0",
        date    = "19.10.2026",
        notes   = {
            "|cff7C6CFFSammel-Atlas auf der Minikarte|r – statt eines Symbols ein offener Ring um die gemerkte Stelle: das echte Vorkommen des Spiels bleibt in der Mitte sichtbar.",
        },
    },
    {
        version = "6.83.3.0",
        date    = "19.10.2026",
        notes   = {
            "|cff7C6CFFFarmen|r – ein zweiter Klick auf Kräuter, Erz oder Beides blendet die Fundstellen auf der Karte aus, ohne den Sammel-Atlas abzuschalten. Ein weiterer Klick zeigt sie wieder.",
        },
    },
    {
        version = "6.83.2.0",
        date    = "19.10.2026",
        notes   = {
            "|cff7C6CFFSammel-Atlas mit der Gilde|r – geteilt wurde bisher nur, was beim Sammeln eine Objektnummer hatte, und nur im selben Moment. Jetzt auch nach Name, und deine bisherigen Fundstellen gehen nach dem Einloggen langsam an die Gilde (eine Zeile alle 2 s, alle 30 Minuten erneut). Wer sie sehen will, braucht den Sammel-Atlas eingeschaltet – einen Beruf braucht man nicht.",
        },
    },
    {
        version = "6.83.1.0",
        date    = "19.10.2026",
        notes   = {
            "|cff7C6CFFQuestpfeil weniger streng|r – kleine Knicke im Laufweg schickt er nicht mehr einzeln an: läufst du die Straße entlang, zeigt er voraus statt „10 m nach links, dann wieder geradeaus“. An echten Kurven und Hindernissen zeigt er wie bisher um die Ecke.",
        },
    },
    {
        version = "6.83.0.0",
        date    = "19.10.2026",
        notes   = {
            "|cff7C6CFFWildtierkunde für Jäger|r – neuer Reiter unter „Lehrer“, nur für Jäger: alle zähmbaren Tiere nach Familien, mit Stufe, Zonen, Angriffstempo und was sie lehren, Suche, Favoriten und „neu gesehen“. Wildtierkunde auf ein Tier wirken oder es anvisieren merkt es sich. „Auf der Karte zeigen“ und „Pfeil hierhin“ führen zu den Fundorten. /wc wildtiere",
            "|cff7C6CFFSuche|r – findet jetzt auch Zauber beim Lehrer, Klassenquests, Berufe und Rezepte, Gegenstände in den Taschen aller Charaktere, Bücher, Wildtiere und jede Seite beim Namen. Umlaute dürfen als ae, oe, ue getippt werden.",
        },
    },
    {
        version = "6.82.2.0",
        date    = "19.10.2026",
        notes   = {
            "|cff7C6CFFLaufweg nach Ironforge|r – liegt das Ziel in der Stadt und du bist draußen, führt der Weg jetzt erst zum Tor statt über den Berg. Drinnen und überall sonst bleibt alles wie bisher.",
        },
    },
    {
        version = "6.82.1.0",
        date    = "19.10.2026",
        notes   = {
            "|cff7C6CFFFarmen|r – eigene Leiste unter der Quest-Leiste statt Knöpfen auf der Karte: runde Knöpfe mit Erklärung beim Zeigen. Kräuter, Erz oder Beides wählt, was Karte und Route zeigen, und stellt die Kräuter- bzw. Mineraliensuche deines Charakters mit um.",
            "|cff7C6CFFSammel-Atlas|r – erkennt die Beute jetzt auch, wenn sie vor dem Ende des Sammelzaubers oder per Schnellplündern kommt. Erst damit gehen Fundorte an die Gilde.",
            "|cff7C6CFFRoutenplaner|r – Fahrpläne, Portale und Teleports auf den neuesten Stand gebracht.",
        },
    },
    {
        version = "6.82.0.0",
        date    = "19.10.2026",
        notes   = {
            "|cff7C6CFFSammel-Atlas|r – merkt sich, wo du Kräuter, Erz, Truhen und Fischschwärme gesammelt hast, und zeigt sie auf Weltkarte und Minikarte, mit Filtern je Art. Farmroute automatisch aus einer Zone oder selbst angeklickt, der Pfeil führt von Punkt zu Punkt. Fundorte gehen still an die Gilde (nur Karte, Art und Ort). Ab Werk aus, unter Komfort → Sammeln oder /wcui sammeln.",
            "|cff7C6CFFQuestpfeil|r – ruhigere Spitze ohne Zittern; bei mehreren Fundorten eines Questziels zeigt er auf den nächsten statt auf die Gebietsmitte; Wegecken springen nicht mehr hin und her; als Geist auf Wunsch zum Geistheiler, wenn der deutlich näher ist. /wcui pfeil zeigt mehr.",
            "|cff7C6CFFLaufweg|r – 688 unmögliche Verbindungen in den Geländedaten gesperrt (vom Boden einer Stadt oder Höhle direkt auf den Berg). Ironforge in Richtung Osten ist damit noch nicht ganz behoben.",
        },
    },
    {
        version = "6.81.0.0",
        date    = "19.10.2026",
        notes   = {
            "|cff7C6CFFFlugspiele – Juwelen|r – echte Kristalle statt einfarbiger Rauten: sechs eigene, geschliffene Steine mit Facetten, Glanz und Funkeln – rund in Rot, Sechseck in Orange, Achteck in Gelb, Smaragdschliff in Grün, Dreieck in Blau, Raute in Violett. Auch an der Form unterscheidbar.",
        },
    },
    {
        version = "6.80.6.0",
        date    = "19.10.2026",
        notes   = {
            "|cff7C6CFFFlugspiele|r – das Fenster steht fest und lässt sich beim Spielen nicht mehr verschieben. Eine eigene Zeile unter dem Titel zeigt Ziel und Flugzeit, die mitläuft, und rechts die Punkte; nichts überlappt mehr die Knöpfe oder die Hinweise der Spiele.",
        },
    },
    {
        version = "6.80.5.0",
        date    = "19.10.2026",
        notes   = {
            "|cff7C6CFFGroße Prüfung vor dem Ende der Beta|r – Mahjong: nach einem abgeräumten Brett verschwanden zwei Steine des neuen Spiels, das Spiel war dann nicht mehr lösbar. Behoben.",
            "|cff7C6CFFDanke|r – schaltet die freundlichen Plaketten nicht mehr in Instanzen kurz ein (dort wären sie sichtbar) und schaltet sie nach Kampfbeginn erst nach dem Kampf zurück, statt eine Sperrmeldung auszulösen.",
            "|cff7C6CFFTaschen|r – Fehler beim Öffnen eines gelöschten Charakters behoben; solange der Realm noch nicht lesbar ist, fehlt im Tooltip niemand mehr.",
            "|cff7C6CFFFremde Schriften|r – japanische und chinesische Sprüche in derselben Größe wie die übrigen.",
        },
    },
    {
        version = "6.80.4.0",
        date    = "18.10.2026",
        notes   = {
            "|cff7C6CFFZielmarke im Raum|r – in der Nähe zählt der Abstand am Boden statt schräg zum Punkt über dem Kopf; direkt davor steht „hier“ statt „2 m“, und Springen ändert die Zahl nicht mehr.",
        },
    },
    {
        version = "6.80.3.0",
        date    = "18.10.2026",
        notes   = {
            "|cff7C6CFFZielmarke im Raum|r – blendet nur noch bei Questzielen aus (Gegner, Objekte, Gebiet). Beim Abgeben, bei Questgebern und eigenen Wegpunkten bleibt sie stehen, damit du die Person auch im Gewühl findest.",
        },
    },
    {
        version = "6.80.2.0",
        date    = "18.10.2026",
        notes   = {
            "|cff7C6CFFZielmarke im Raum|r – blendet nicht mehr schon am Rand des Questgebiets aus. Sie verschwindet erst, wenn du am Ziel bist (im Questgebiet: höchstens 45 m davon), und kommt ab etwa 80 m wieder. Verdeckt ist sie wieder halb durchsichtig.",
        },
    },
    {
        version = "6.80.1.0",
        date    = "18.10.2026",
        notes   = {
            "|cff7C6CFFZielmarke im Raum|r – steht das Ziel hinter einem Baum oder Fels, wird die Marke nur noch leicht gedämpft statt halb durchsichtig. Sie sah sonst aus, als wäre sie schon ausgeblendet.",
        },
    },
    {
        version = "6.80.0.0",
        date    = "18.10.2026",
        notes   = {
            "|cff7C6CFFZielmarke im Raum|r – hast du das Ziel ganz erreicht, blendet die Marke langsam aus und taucht erst ab etwa 80 m Abstand langsam wieder auf. Vor der Ankunft bleibt sie wie bisher.",
        },
    },
    {
        version = "6.79.3.0",
        date    = "18.10.2026",
        notes   = {
            "|cff7C6CFFDankessprüche in fremden Schriften|r – steht in einem eigenen Spruch Japanisch, Chinesisch oder Koreanisch, zeigen Liste und Eingabefeld ihn in der Chatschrift des Spiels statt in Rechtecken – soweit dein Spiel diese Schriften installiert hat.",
        },
    },
    {
        version = "6.79.2.0",
        date    = "18.10.2026",
        notes   = {
            "|cff7C6CFFEchte Hühner|r – die Hühnerjagd spielt jetzt die Hühnerstimmen aus dem Spiel selbst: Gackern beim Treffer, Schmerzlaut beim Zombiehuhn, Todesschrei beim Bombenhuhn. Kennt dein Spiel sie nicht, kommen die eigenen Töne.",
        },
    },
    {
        version = "6.79.1.0",
        date    = "18.10.2026",
        notes   = {
            "|cff7C6CFFFlugspiele: aufgeräumte Auswahl|r – jedes Spiel hat eine eigene Karte mit Bild, Namen und Erklärung; nichts überlappt mehr. Der Tonschalter sitzt jetzt oben neben dem Schließen-Knopf.",
        },
    },
    {
        version = "6.79.0.0",
        date    = "18.10.2026",
        notes   = {
            "|cff7C6CFFBestand: welche Charaktere zählen|r – Charaktere der anderen Fraktion zählen in Tooltip und Gold nur noch, wenn du es willst („Andere Fraktion“ auf der Seite Taschen). Jeden Charakter kannst du dort einzeln aus Tooltip und Gold nehmen. Steht die andere Fraktion drin, ist sie im Tooltip gekennzeichnet.",
            "|cff7C6CFFHühner klingen nach Hühnern|r – neue Töne: raues „bok bok bok BAAK!“, Küken-Piepsen, gurgelnder Zombie, Kikeriki beim Goldhuhn. Unten links im Spielfenster schaltet „Ton“ sie stumm.",
            "|cff7C6CFFHändlerfenster groß ziehen ab Werk aus|r – es kann dazu führen, dass Klicks in die Taschen vom Spiel verboten werden. Wer es möchte, schaltet es im Komfort wieder ein.",
        },
    },
    {
        version = "6.78.3.0",
        date    = "18.10.2026",
        notes   = {
            "|cff7C6CFFDie Hühner gackern|r – jeder Treffer in der Hühnerjagd ist zu hören: Gackern, Glucken und Bwaak beim Huhn, Piepen beim Küken, Grollen beim Zombiehuhn, ein Bumm beim Bombenhuhn und Glitzern beim Goldhuhn. Abschaltbar unter Komfort → Flugspiele → Töne.",
        },
    },
    {
        version = "6.78.2.0",
        date    = "18.10.2026",
        notes   = {
            "|cff7C6CFFFlugspiele: Strecke und Flugzeit|r – Ergebnis und Gildenzeile nennen jetzt, von wo nach wo du geflogen bist und wie lange, etwa „Flug Sturmwind nach Eisenschmiede, 2:31 min – Flugspiele: 340 Punkte in Juwelen“.",
            "|cff7C6CFFSchöneres Mahjong|r – Steine aus Elfenbein mit Schatten und Kante, Zahl und Zeichen in der Farbe ihrer Sorte, auf grünem Filz. Gesperrte Steine sind abgedunkelt, der gewählte hebt sich leuchtend an, abgeräumte Paare verblassen.",
        },
    },
    {
        version = "6.78.1.0",
        date    = "18.10.2026",
        notes   = {
            "|cff7C6CFFJuwelen in Bewegung|r – Steine gleiten beim Tauschen, Treffer blähen sich auf und verpuffen, alles rutscht nach und Neue fallen von oben herein. Ketten zählen hoch („Kette x3!“), Punkte steigen auf.",
            "|cff7C6CFFHühnerjagd mit Hühnerzoo|r – Küken (klein und flink), Flatterhuhn (Zickzack), Zombiehuhn (braucht zwei Treffer), Goldhuhn (selten, sehr schnell, viele Punkte) und das rote Bombenhuhn, das Punkte kostet. Jeder Treffer gackert zurück, Trefferserien bringen Extrapunkte.",
        },
    },
    {
        version = "6.78.0.1",
        date    = "18.10.2026",
        notes   = {
            "|cff7C6CFFFlugspiele öffnen sich wieder|r – das Fenster ließ sich nicht öffnen, weder beim Abflug noch über die Einstellungen oder /wcui spiele.",
        },
    },
    {
        version = "6.78.0.0",
        date    = "18.10.2026",
        notes   = {
            "|cff7C6CFFFlugspiele|r – beim Abheben fragt WeintCodex, ob du bis zur Landung spielen willst: Juwelen (drei Gleiche tauschen), Mahjong (Paare abräumen) oder Hühnerjagd. Nach der Landung stehen deine Punkte und dein Bestwert da, auf Wunsch als Zeile für den Gildenchat. Alles abschaltbar unter Komfort → Flugspiele, jederzeit spielbar mit /wcui spiele.",
        },
    },
    {
        version = "6.77.2.0",
        date    = "18.10.2026",
        notes   = {
            "|cff7C6CFFHinrichtungsmarke auf markierten Gegnern|r – der Strich liegt jetzt über der Farbe der Markierung und wird bei hellen Markierungen (Totenkopf, Mond, Stern) dunkel, damit man ihn weiter sieht.",
        },
    },
    {
        version = "6.77.1.0",
        date    = "18.10.2026",
        notes   = {
            "|cff7C6CFFBalken ganz in der Farbe der Markierung|r – an den Rändern schaute noch die alte Farbe heraus. Jetzt füllt die Markierungsfarbe den Balken vollständig, mit demselben Verlauf wie eine selbst gewählte Balkenfarbe.",
        },
    },
    {
        version = "6.77.0.0",
        date    = "18.10.2026",
        notes   = {
            "|cff7C6CFFEigene Dankessprüche bleiben|r – was du dir selbst ausdenkst, liegt jetzt fest für dein ganzes Konto gespeichert: es übersteht jedes Update, gilt auf allen Charakteren und in jedem Profil. Was du schon geschrieben hattest, wird beim Einloggen übernommen.",
        },
    },
    {
        version = "6.76.8.0",
        date    = "18.10.2026",
        notes   = {
            "|cff7C6CFFLebensbalken in der Farbe der Markierung|r – markierte Gegner haben jetzt einen Balken ganz in ihrer Farbe: Totenkopf weiß, Kreuz rot, Quadrat blau, Mond silbern, Stern gelb, Kreis orange, Diamant lila, Dreieck grün. Auch im Kampf.",
        },
    },
    {
        version = "6.76.7.0",
        date    = "18.10.2026",
        notes   = {
            "|cff7C6CFFMarkierte Gegner wieder dezenter|r – der farbige Rahmen ist weg, die Fläche wieder so zart wie vorher; bei Totenkopf und Mond noch etwas zarter, damit Name und Leben lesbar bleiben.",
        },
    },
    {
        version = "6.76.6.0",
        date    = "18.10.2026",
        notes   = {
            "|cff7C6CFFZielrahmen wieder wie gewohnt|r – die Farbe der Markierung zeigt nur noch die Namensplakette.",
        },
    },
    {
        version = "6.76.5.0",
        date    = "18.10.2026",
        notes   = {
            "|cff7C6CFFMarkierte Gegner noch deutlicher|r – die Farbfläche über dem Balken ist kräftiger, und um den Balken liegt ein voller Rahmen in der Farbe der Markierung. Auf Namensplakette und Zielrahmen, auch im Kampf.",
        },
    },
    {
        version = "6.76.4.0",
        date    = "18.10.2026",
        notes   = {
            "|cff7C6CFFMarkierte Gegner – neuer Weg|r – über dem Lebensbalken liegt jetzt eine Fläche in der Farbe der Markierung. Sie kommt auf demselben Weg wie das Symbol selbst und funktioniert deshalb auch im Kampf, wo das Spiel die Markierung verschlüsselt. Auf Namensplakette und Zielrahmen.",
        },
    },
    {
        version = "6.76.3.0",
        date    = "18.10.2026",
        notes   = {
            "|cff7C6CFFMarkierungsfarbe im Kampf wirklich sichtbar|r – mit dem Balkenstil „Verlauf“ blieb die Plakette eines markierten Gegners im Kampf in ihrer alten Farbe. Jetzt nimmt sie die Farbe der Markierung an.",
        },
    },
    {
        version = "6.76.2.0",
        date    = "18.10.2026",
        notes   = {
            "|cff7C6CFFMarkierungsfarbe auch im Zielrahmen|r – ist dein Ziel markiert, zeigt jetzt auch der Zielrahmen oben den Lebensbalken in der Farbe der Markierung, nicht nur die Namensplakette.",
        },
    },
    {
        version = "6.76.1.0",
        date    = "18.10.2026",
        notes   = {
            "|cff7C6CFFMarkierungsfarbe auch im Kampf|r – dort nennt das Spiel die Markierung nur verschlüsselt. Die Farbe kommt jetzt über einen Weg des Spiels selbst, der verschlüsselte Werte in Farben übersetzen darf.",
        },
    },
    {
        version = "6.76.0.0",
        date    = "18.10.2026",
        notes   = {
            "|cff7C6CFFMarkierte Gegner fallen auf|r – der Lebensbalken nimmt die Farbe der Markierung an (Stern gelb, Kreis orange, Diamant lila, Dreieck grün, Mond silbern, Quadrat blau, Kreuz rot, Totenkopf weiß), hinter dem Symbol leuchtet ein Schein in derselben Farbe, und das Symbol ist etwas größer. Abschaltbar bei den Namensplaketten unter Schlachtzugsmarkierung.",
        },
    },
    {
        version = "6.75.3.0",
        date    = "18.10.2026",
        notes   = {
            "|cff7C6CFFZielmarke erkennt das Questgebiet|r – statt zu schätzen schaut WeintCodex jetzt, wo die Gegner, Objekte und Beute einer Quest zu finden sind. Stehst du in ihrer Nähe, verschwindet die Nadel; verlässt du das Gebiet, kommt sie wieder.",
        },
    },
    {
        version = "6.75.2.0",
        date    = "18.10.2026",
        notes   = {
            "|cff7C6CFFZielmarke im Questgebiet, zweiter Anlauf|r – das Spiel meldet nicht, wann du im Gebiet einer Quest stehst. Bei offenen Quests verschwindet die Nadel jetzt, sobald du nah an der Mitte des Gebiets bist. Bei Abgaben und eigenen Zielen bleibt sie bis zum Ziel.",
        },
    },
    {
        version = "6.75.1.0",
        date    = "18.10.2026",
        notes   = {
            "|cff7C6CFFZielmarke verschwindet im Questgebiet|r – stehst du schon im Gebiet einer Quest, braucht es keine Nadel mehr; sie geht weg, sobald das Spiel dich dort meldet.",
        },
    },
    {
        version = "6.75.0.0",
        date    = "18.10.2026",
        notes   = {
            "|cff7C6CFFDanke findet jeden Spender|r – wer die Namensplaketten freundlicher Spieler aus hat, bekommt sie jetzt unsichtbar und nicht anklickbar eingeschaltet. So kennt das Spiel jeden, der dich bufft, und das Dankeschön geht zuverlässig raus. Du siehst davon nichts. Abschaltbar unter Danke → Erweitert; dann kommt deine Einstellung zurück. In Instanzen bleibt alles, wie du es eingestellt hast.",
        },
    },
    {
        version = "6.74.0.0",
        date    = "18.10.2026",
        notes   = {
            "|cff7C6CFFNeue Zielmarke im Raum|r – im Stil eines Pings: Plakette mit Raute, Lichtstrahl bis zum Boden, leuchtender Schein, größer als vorher und in deiner Akzentfarbe. Sie erscheint erst in der Nähe (ab 100 m, einstellbar beim Questpfeil unter „Der Pfeil im Einzelnen“), blendet weich ein und wächst beim Näherkommen.",
        },
    },
    {
        version = "6.73.3.0",
        date    = "18.10.2026",
        notes   = {
            "|cff7C6CFFZielmarke im Raum sichtbar|r – die Nadel am Ziel trat bisher zurück, sobald das Spiel meinte, selbst eine Marke zu zeigen. Die blieb aber unsichtbar. Jetzt steht die Nadel von WeintCodex immer.",
        },
    },
    {
        version = "6.73.2.0",
        date    = "18.10.2026",
        notes   = {
            "|cff7C6CFFSchussprotokoll genauer|r – /wcui schuss hält jetzt auch fest, welche Leiche oder welches Objekt das Spiel gerade zum Plündern anvisiert, ob sie tot ist, und wie die weiche Zielerfassung eingestellt ist. Damit lässt sich klären, warum der Jäger manchmal vom Schießen ins Zuschlagen wechselt.",
        },
    },
    {
        version = "6.73.1.0",
        date    = "18.10.2026",
        notes   = {
            "|cff7C6CFFEinstellungen im Kampf|r – das Fenster lässt sich jetzt auch im Kampf schließen, verschieben und durchblättern, ohne dass das Spiel Meldungen „blockiert“ wirft. Die Knöpfe „Neu laden“ und „Bearbeitungsmodus des Spiels“ wirken im Kampf nur als Hinweis und sind danach wieder voll da.",
        },
    },
    {
        version = "6.73.0.0",
        date    = "18.10.2026",
        notes   = {
            "|cff7C6CFFZielmarke im Raum für eigene Ziele|r – führt dich der Questpfeil zu einem Instanzeingang, Rezepthändler oder Buch, steht jetzt auch eine Nadel genau am Ziel in der Welt, mit Entfernung. Rechtsklick auf einen Instanzeingang auf der Weltkarte führt dich hin. Dafür setzt WeintCodex den Wegpunkt des Spiels und nimmt ihn danach wieder ab; dein eigener Wegpunkt kommt zurück.",
        },
    },
    {
        version = "6.72.0.0",
        date    = "18.10.2026",
        notes   = {
            "|cff7C6CFFDungeonkarten|r – in den klassischen Dungeons und Schlachtzügen zeigt die Weltkarte (M) jetzt die Karte der Instanz, wie man es aus WoW kennt. Ebenen wechselst du mit den Pfeilen oder dem Mausrad, „Weltkarte“ blendet sie aus. Abschaltbar im Komfort unter Karte.",
        },
    },
    {
        version = "6.71.1.0",
        date    = "18.10.2026",
        notes   = {
            "|cff7C6CFFDanke geht nicht mehr ins Leere|r – sperrt das Spiel das Flüstern gerade, wartet WeintCodex und holt den Dank nach. Sind Buffs gerade geheim, versucht es gar nicht erst.",
        },
    },
    {
        version = "6.71.0.0",
        date    = "18.10.2026",
        notes   = {
            "|cff7C6CFFDanke findet den Spender öfter|r – verrät das Spiel nicht, wer dich gebufft hat, schaltet WeintCodex die Namensplaketten freundlicher Spieler für einen Augenblick unsichtbar ein und gleich wieder aus. Dann kennt das Spiel den Spender meist, und der Dank geht raus. Nie im Kampf; wer die Plaketten selbst an hat, merkt keinen Unterschied. Abschaltbar auf der Seite Danke.",
        },
    },
    {
        version = "6.70.0.0",
        date    = "18.10.2026",
        notes   = {
            "|cff7C6CFFDanke auch, wenn der Spender erst später sichtbar wird|r – verrät das Spiel beim Buff nicht, wer gebufft hat, merkt sich WeintCodex den Buff 90 Sekunden. Fährst du in der Zeit mit der Maus über den Spieler, klickst ihn an oder erscheint seine Namensplakette, geht der Dank noch raus. Im Tooltip deiner Buffs steht jetzt „Von: Name“, wenn das Spiel den Spender kennt.",
        },
    },
    {
        version = "6.69.3.0",
        date    = "18.10.2026",
        notes   = {
            "|cff7C6CFFDanke: kein Fehlalarm mehr nach dem Login|r – Buffs, die du beim Anmelden schon hast, zählen nicht mehr als neu. Nennt das Spiel den Spender nicht, gibt es keinen Fehlerbericht mehr, sondern einmal einen Hinweis, was hilft.",
        },
    },
    {
        version = "6.69.2.0",
        date    = "18.10.2026",
        notes   = {
            "|cff7C6CFFErinnerung an Dämonenhaut und andere Ränge|r – wer einen höheren Rang eines Klassenbuffs gelernt hat, bekommt die Erinnerung jetzt wieder. Bisher galt der Buff dann als nicht gelernt, und die Erinnerung blieb stumm.",
        },
    },
    {
        version = "6.69.1.0",
        date    = "18.10.2026",
        notes   = {
            "|cff7C6CFFChat kopieren: Knopf gut sichtbar|r – er sitzt jetzt über dem Chatfenster auf Höhe der Reiter, statt unter dem Text der anderen zu verschwinden.",
        },
    },
    {
        version = "6.69.0.0",
        date    = "18.10.2026",
        notes   = {
            "|cff7C6CFFDanke: Fehlerbericht, wenn kein Flüstern rausgeht|r – bekommst du einen Buff und WeintCodex kann nicht danken, obwohl es sollte, öffnet sich ein Bericht zum Kopieren. Er enthält die letzten Buffs und den Grund. Gewollte Gründe wie Gruppe, Kampf oder „gerade erst gedankt“ lösen keinen Bericht aus. Auch mit /wcui danke oder auf der Seite Danke.",
        },
    },
    {
        version = "6.68.0.0",
        date    = "18.10.2026",
        notes   = {
            "|cff7C6CFFChat kopieren|r – oben rechts an jedem Chatfenster sitzt ein kleiner Knopf „Kopieren“. Er öffnet den Verlauf des offenen Reiters (Allgemein, Handel …) als Text zum Markieren und Kopieren mit Strg+C. Abschaltbar im Komfort.",
        },
    },
    {
        version = "6.67.1.0",
        date    = "18.10.2026",
        notes   = {
            "|cff7C6CFFTaschen: weniger Sperren beim Rechtsklick|r – „Händlerfenster groß ziehen“ fasst den Händler des Spiels nur noch an, wenn das Fenster wirklich vergrößert ist. Der Fehlerbericht zu „Verboten: UseContainerItem()“ nennt jetzt zuerst, was der Klick des Spiels liest.",
        },
    },
    {
        version = "6.67.0.0",
        date    = "18.10.2026",
        notes   = {
            "|cff7C6CFFRezepte: Details rechts wie bei den Büchern|r – ein Klick auf ein Rezept zeigt rechts, woher es kommt (Lehrer, Händler, Händlergunst oder selbst finden), beim Händler mit Karte, Lage und dem Knopf „Questpfeil hierhin“. Auch der Tooltip sagt jetzt, ob ein Rezept käuflich ist.",
        },
    },
    {
        version = "6.66.0.0",
        date    = "18.10.2026",
        notes   = {
            "|cff7C6CFFRezepte vom Händler: Klick führt hin|r – in den Berufen tragen kaufbare Rezepte das Zeichen „Händler“. Der Tooltip nennt Händler, Gebiet und Lage (nur deiner Fraktion), ein Klick setzt den Pfeil zum Händler. Umschalt-Klick verlinkt das Rezept weiter im Chat.",
        },
    },
    {
        version = "6.65.0.0",
        date    = "17.10.2026",
        notes   = {
            "|cff7C6CFFVerzauberungen: hast du die richtige drauf?|r – der Tooltip eines verzauberten Platzes sagt beim Leveln, ob die Verzauberung zu deiner Klasse passt, und nennt sonst passendere. Auf Stufe 60 zeigt er, ob es die stärkste passende ist; wenn nicht, bekommt der Platz einen goldenen Punkt und die Zeile über den Waffen nennt ihn unter „Stärker möglich“.",
        },
    },
    {
        version = "6.64.1.0",
        date    = "17.10.2026",
        notes   = {
            "|cff7C6CFFVerzauberungs-Vorschläge bleiben im Tooltip stehen|r – sie verschwanden nach einem Augenblick, weil das Spiel den Tooltip laufend neu aufbaut.",
        },
    },
    {
        version = "6.64.0.0",
        date    = "17.10.2026",
        notes   = {
            "|cff7C6CFFVerzauberungen: Vorschläge direkt am Gegenstand|r – Maus über einen Platz mit Punkt zeigt, welche Verzauberungen des Verzauberers zu deiner Klasse und Stufe passen (Faustregel, keine Wertung). Beim Leveln steht der Hinweis nur noch am Platz, die Zeile über den Waffen erst auf Stufe 60.",
        },
    },
    {
        version = "6.63.1.0",
        date    = "17.10.2026",
        notes   = {
            "|cff7C6CFFVerzauberungen: der Platz steht jetzt dabei|r – „Ohne Verzauberung: Hände“ statt nur einer Zahl, die über der Waffe nach der Waffe aussah.",
        },
    },
    {
        version = "6.63.0.0",
        date    = "17.10.2026",
        notes   = {
            "|cff7C6CFFFehlende Verzauberungen im Charakterfenster|r – ein Punkt an jedem Platz ohne Verzauberung, für jeden Platz, den die Verzauberkunst in Forever bedienen kann – auch die Halskette. Die Nebenhand nur mit Schild oder Waffe. Beim Leveln dezent, auf 60 deutlich mit den Namen der Plätze. Abschaltbar unter Tooltip & Fenster.",
        },
    },
    {
        version = "6.62.4.0",
        date    = "17.10.2026",
        notes   = {
            "|cff7C6CFFNeuer Channel in Gold|r – der Dialog hinter „Hinzufügen“ in den Chat-Kanälen passt jetzt zum Fenster: dunkle Fläche, flache Eingabefelder und Knöpfe.",
        },
    },
    {
        version = "6.62.3.0",
        date    = "17.10.2026",
        notes   = {
            "|cff7C6CFFChat-Kanäle in Gold|r – das Fenster der Chat-Kanäle trägt jetzt den Stil der übrigen Fenster: kein Metallrahmen, dunkle Flächen, die Gruppenköpfe als ruhige Leisten.",
        },
    },
    {
        version = "6.62.2.0",
        date    = "17.10.2026",
        notes   = {
            "|cff7C6CFFLayer: eigene Seite unter Minikarte, abschaltbar|r – Einstellungen → Minikarte → Layer. Das Schild zeigt jetzt auch, wie viele Layer du in der Zone gesehen hast, und während einer Bitte die Restzeit. Nach 2 Minuten ohne Einladung sagt WeintCodex Bescheid.",
        },
    },
    {
        version = "6.62.1.0",
        date    = "17.10.2026",
        notes   = {
            "|cff7C6CFFKein „Blockiert“ mehr beim Zielwechsel im Kampf|r – das Kampfprotokoll fragte eine Entfernung ab, die das Spiel im Kampf sperrt.",
            "|cff7C6CFFDanke: „Immer danken“|r – neuer Schalter: auch im Kampf und für jeden Buff, ohne Pausen zwischen den Danksagungen.",
        },
    },
    {
        version = "6.62.0.0",
        date    = "17.10.2026",
        notes   = {
            "|cff7C6CFFDein Layer an der Minikarte|r – oben mittig steht „Layer A“, „Layer B“ …, gelesen an den Gegnern um dich herum. Ein Klick öffnet die Einstellungen.",
            "|cff7C6CFFLayer wechseln auf Klick|r – Komfort → Karte → „Um anderen Layer bitten“ fragt im Kanal „layer“ nach einer Einladung; Spieler mit LayerSwap verstehen die Bitte. Solange du in der Gruppe bleibst, bleibst du auf dem neuen Layer.",
        },
    },
    {
        version = "6.61.26.0",
        date    = "17.10.2026",
        notes   = {
            "|cff7C6CFFDer Scrollbalken klebt nicht mehr an der Maus|r – Loslassen beendet das Ziehen jetzt immer, auch wenn die Maus dabei neben dem Balken steht.",
        },
    },
    {
        version = "6.61.25.0",
        date    = "17.10.2026",
        notes   = {
            "|cff7C6CFFDanke auch für erneuerte Buffs|r – frischt ein Fremder einen Buff auf, den du schon hattest, bedankt sich WeintCodex jetzt ebenfalls. „/wcui danke“ sagt, warum zuletzt kein Dank kam.",
        },
    },
    {
        version = "6.61.24.0",
        date    = "17.10.2026",
        notes   = {
            "|cff7C6CFFKampfprotokoll: Tod des Ziels|r – „/wcui schuss“ schreibt jetzt mit, wann dein Ziel stirbt und wann die weiche Zielerfassung des Spiels wechselt.",
        },
    },
    {
        version = "6.61.23.0",
        date    = "17.10.2026",
        notes   = {
            "|cff7C6CFFDein Ziel springt im Kampf nicht mehr weg|r – der Klickbereich des Hinweises „seltener Gegner“ blieb im Kampf unsichtbar liegen; ein Klick in die Welt an dieser Stelle wechselte das Ziel und beendete beim Jäger den Autoshot. Er ist jetzt im Kampf immer aus.",
        },
    },
    {
        version = "6.61.22.0",
        date    = "17.10.2026",
        notes   = {
            "|cff7C6CFFKein kurzes Aufploppen mehr beim Wechsel eines Aspekts|r – ein fehlender Buff wird erst gemeldet, wenn er zwei Sekunden lang fehlt. Beim Wechsel von Aspekt, Segen oder Rüstung fällt der alte einen Augenblick vor dem neuen weg.",
        },
    },
    {
        version = "6.61.21.0",
        date    = "17.10.2026",
        notes   = {
            "|cff7C6CFFKampfprotokoll genauer|r – „/wcui schuss“ nennt beim Ziel jetzt, ob es eins gibt, Gegner oder nicht und ob es in Nahkampfnähe steht; Wiederholungen stehen als eine Zeile mit Zähler.",
        },
    },
    {
        version = "6.61.20.0",
        date    = "17.10.2026",
        notes   = {
            "|cff7C6CFFKampfprotokoll für Autoshot|r – „/wcui schuss“ zeigt nach einem Kampf, wann Autoshot und Nahkampf an- und ausgingen und welche Fähigkeiten dazwischen kamen. Zum Kopieren, für die Fehlersuche.",
        },
    },
    {
        version = "6.61.19.0",
        date    = "17.10.2026",
        notes   = {
            "|cff7C6CFFJäger-Makros starten den Autoshot statt den Nahkampf|r – „Angriff starten“ im Makro-Helfer schreibt beim Jäger jetzt „/cast !Automatischer Schuss“. Bereits angelegte Makros bitte neu erstellen oder die Zeile „/startattack“ entfernen.",
        },
    },
    {
        version = "6.61.18.0",
        date    = "17.10.2026",
        notes   = {
            "|cff7C6CFFDie braunen Balken im Questlog sind wirklich weg|r – bei vielen Quests war die Liste zu lang für den Durchlauf und wurde übersprungen.",
        },
    },
    {
        version = "6.61.17.0",
        date    = "17.10.2026",
        notes   = {
            "|cff7C6CFFDie Zonen im Questlog sind wieder Abschnitte|r – nach einer Änderung des Spiels trugen sie wieder braune Balken.",
        },
    },
    {
        version = "6.61.16.0",
        date    = "17.10.2026",
        notes   = {
            "|cff7C6CFFKeine falsche Buff-Erinnerung mehr beim Kampfbeginn|r – im Kampf verrät das Spiel die eigenen Buffs nicht; „Mal der Wildnis fehlt“ erschien deshalb, obwohl er da war. Im Kampf meldet WeintCodex keinen Buff mehr als fehlend.",
        },
    },
    {
        version = "6.61.15.0",
        date    = "17.10.2026",
        notes   = {
            "|cff7C6CFFKein „Blockiert“ mehr bei offenem Codex im Kampf|r – Tasten gehen dann immer ans Spiel; Strg+K für die Suche wirkt außerhalb des Kampfes.",
        },
    },
    {
        version = "6.61.14.0",
        date    = "17.10.2026",
        notes   = {
            "|cff7C6CFFBuffs in den Gruppenrahmen|r – Segen, Intelligenz, Mal der Wildnis & Co. stehen unten links in jedem Rahmen, die Debuffs weiter unten rechts. Größe und Anzahl unter Gruppenrahmen einstellbar.",
        },
    },
    {
        version = "6.61.13.0",
        date    = "17.10.2026",
        notes   = {
            "|cff7C6CFFKlickzauber zeigen ihre Nummer|r – im Tooltip der Zaubertafel steht jetzt „Zauber 12345“, damit ein falscher Eintrag eindeutig gemeldet werden kann.",
        },
    },
    {
        version = "6.61.12.0",
        date    = "17.10.2026",
        notes   = {
            "|cff7C6CFFWiederbelebungen bei den Klickzaubern|r – Wiedergeburt, Auferstehung, Erlösung und Geist der Ahnen stehen jetzt in der Auswahl der hilfreichen Zauber.",
        },
    },
    {
        version = "6.61.11.0",
        date    = "17.10.2026",
        notes   = {
            "|cff7C6CFFKlick auf die Marke schickt den Questpfeil hin|r – ob Dungeoneingang, Lehrer oder Questgeber aus dem Codex: ein Klick auf die Marke auf der Weltkarte, und der Pfeil führt dich dorthin.",
            "|cff7C6CFFNeue Marke auf der Karte|r – rund mit Ring in deiner Farbe und kleiner Spitze, Eingänge mit Tor-Zeichen.",
        },
    },
    {
        version = "6.61.10.0",
        date    = "17.10.2026",
        notes   = {
            "|cff7C6CFFDas Schiff Menethil–Auberdine fährt im Planer wie im Spiel|r – über Süderstade im Dreieck. Die alte Direktfahrt, die es nicht mehr gibt, schlägt der Routenplaner nicht mehr vor.",
        },
    },
    {
        version = "6.61.9.0",
        date    = "17.10.2026",
        notes   = {
            "|cff7C6CFFDie Zahl beim Stapel teilen ist lesbar|r – hell auf dem dunklen Feld statt dunkel.",
        },
    },
    {
        version = "6.61.8.0",
        date    = "17.10.2026",
        notes   = {
            "|cff7C6CFFStapel teilen im WeintCodex-Stil|r – das kleine Fenster mit Zahl, OK und Abbrechen sieht jetzt aus wie die übrigen Dialoge.",
        },
    },
    {
        version = "6.61.7.0",
        date    = "17.10.2026",
        notes   = {
            "|cff7C6CFFKarte und Minikarte sind wieder lesbar|r – Questziele, die nah beieinander liegen, sind jetzt ein Punkt statt Dutzender. Der Tooltip sagt, wie viele Fundstellen er umfasst.",
        },
    },
    {
        version = "6.61.6.0",
        date    = "17.10.2026",
        notes   = {
            "|cff7C6CFFDie Tasche öffnet und schließt im Kampf ohne Meldung|r – der Sonder-Rechtsklick für Zauberöl ist ausgebaut, der Rechtsklick ist wieder der des Spiels.",
        },
    },
    {
        version = "6.61.5.0",
        date    = "17.10.2026",
        notes   = {
            "|cff7C6CFFDie Tasche öffnet im Kampf wieder ohne Meldung|r – „Blockiert: WeintCodexBags“ kam vom Rechtsklick-Knopf für Zauberöl. Im Kampf ruht er; danach wirkt Zauberöl wieder per Rechtsklick.",
        },
    },
    {
        version = "6.61.4.0",
        date    = "17.10.2026",
        notes   = {
            "|cff7C6CFFKein „!“ mehr für Quests, die du noch nicht annehmen kannst|r – eine Folgequest erscheint erst, wenn die Vorquest abgegeben ist, nicht schon, solange sie im Questlog steht.",
            "|cff7C6CFFKlick auf ein „!“ führt dich hin|r – auf Karte und Minikarte setzt ein Klick den Questpfeil auf den Questgeber, bis du seine Quest angenommen hast.",
        },
    },
    {
        version = "6.61.3.0",
        date    = "17.10.2026",
        notes   = {
            "|cff7C6CFFDie Zahl an der Minikarte verschwindet, sobald du den Codex öffnest|r – beim nächsten Einloggen erinnert sie wieder, und neue Zauber nach einem Stufenaufstieg zeigt sie sofort.",
        },
    },
    {
        version = "6.61.2.0",
        date    = "17.10.2026",
        notes   = {
            "|cff7C6CFFDie Addon-Liste an der Minikarte ist frei|r – der Hinweis zum Sammelknopf verschwindet beim Aufklappen und steht sonst darunter statt über der Liste.",
        },
    },
    {
        version = "6.61.1.0",
        date    = "17.10.2026",
        notes   = {
            "|cff7C6CFFKalender und Anmeldung sind ein Eintrag|r – „Raidplanung“ zeigt beide nebeneinander in der Spalte.",
            "|cff7C6CFFKein Fehler mehr beim Öffnen der Anmeldung|r – der Knopf „Neu laden“ löste beim Anwählen eine Lua-Meldung aus.",
        },
    },
    {
        version = "6.61.0.0",
        date    = "17.10.2026",
        notes   = {
            "|cff7C6CFFDie Obere Schwarzfelsspitze ist bebildert|r – ein Kopfbild und alle acht Bosse, von Feuerwache Glutseher bis General Drakkisath.",
        },
    },
    {
        version = "6.60.4.0",
        date    = "17.10.2026",
        notes   = {
            "|cff7C6CFFVerkaufen per Rechtsklick geht jetzt wirklich|r – der Knopf für Zauberöl lag beim Händler leer, aber weiter über der Tasche, und schluckte den Klick. Jetzt verschwindet er, solange Händler, Bank, Post, Handel oder Auktionshaus offen sind.",
        },
    },
    {
        version = "6.60.3.0",
        date    = "17.10.2026",
        notes   = {
            "|cff7C6CFFRechtsklick beim Händler verkauft wieder.|r Seit dem Zauberöl-Fix legte er den Gegenstand an, statt ihn zu verkaufen. Ebenso wieder richtig an Bank, Post, Handel und Auktionshaus.",
        },
    },
    {
        version = "6.60.2.0",
        date    = "17.10.2026",
        notes   = {
            "|cff7C6CFFKeine Umwege mehr über Portale zu Zielen in der Nähe.|r In Teldrassil schickte die Route vom Schattenhain zu einer nahen Quest hinunter, durchs Portal nach Darnassus und zurück.",
        },
    },
    {
        version = "6.60.1.0",
        date    = "17.10.2026",
        notes   = {
            "|cff7C6CFFDie Knöpfe auf der Bücherseite sind sauber rund.|r In der Liste „Pfeil hierhin“, rechts „Questpfeil hierhin“ in deiner Klassenfarbe.",
            "|cff7C6CFFWählst du nach einem Buch doch eine Quest, folgt der Pfeil der Quest.|r Bisher blieb er beim Buch hängen.",
            "Die Marken der Belohnungen und die erste Zeile der Liste überlappen nicht mehr.",
        },
    },
    {
        version = "6.60.0.0",
        date    = "17.10.2026",
        notes   = {
            "|cff7C6CFFStratholme ist bebildert.|r Ein Kopfbild und Bilder zu allen neunzehn Begegnungen – auf der scharlachroten Seite wie auf der untoten, bis zu Baron Totenschwur.",
        },
    },
    {
        version = "6.59.0.0",
        date    = "17.10.2026",
        notes   = {
            "|cff7C6CFFNeu im Codex: „Bücher“.|r Alle Bücher der Bibliothek in einer Liste – mit deinem Stand bis zur nächsten Belohnung, einem Kartenausschnitt mit Fundort und dem Questpfeil auf Klick.",
            "Nach deiner Stufe und deinem Standort sortiert: Empfohlen (passt und liegt auf deinem Kontinent, das nächste zuerst), Möglich (anderer Kontinent) und Abgeraten (das Gebiet ist deutlich über deiner Stufe). Auch mit /wc bücher.",
        },
    },
    {
        version = "6.58.0.0",
        date    = "17.10.2026",
        notes   = {
            "|cff7C6CFFDie Scholomance ist bebildert.|r Ein Kopfbild und Bilder zu allen vierzehn Begegnungen – vom Blutdiener Kirtonos' bis zu Dunkelmeister Gandling.",
        },
    },
    {
        version = "6.57.0.0",
        date    = "17.10.2026",
        notes   = {
            "|cff7C6CFFDie Bücher der Bibliothek stehen auf der Karte.|r Jedes Buch, das dir noch fehlt, hat ein goldenes Buchsymbol am Fundort – ein Klick darauf stellt den Questpfeil dorthin. Filter „Bücher“ in der Leiste der Questhilfe.",
            "Auf der Startseite nennt die Karte „Bibliothek“ das nächste fehlende Buch; „Pfeil zum Buch“ führt hin. Liegt es in der Tasche, gibt der Pfeil frei.",
        },
    },
    {
        version = "6.56.0.0",
        date    = "17.10.2026",
        notes   = {
            "|cff7C6CFFNeu: die Bücher der Bibliothek.|r Die Startseite zeigt, wie viele du abgegeben hast und wie viele bis zur nächsten Belohnung fehlen – Halskette bei 10, Ring bei 20. Steht eine Belohnung zum Abholen bereit, sagt sie es auch.",
            "Im Tooltip jedes Buches steht, ob es schon abgegeben ist, dein Stand und wo du es abgibst.",
        },
    },
    {
        version = "6.55.1.0",
        date    = "17.10.2026",
        notes   = {
            "|cff7C6CFFDie Schalter der Questhilfe sind sauber rund.|r Keine hellen Ringe mehr an den Enden; eingeschaltet eine ruhige Fläche in deiner Klassenfarbe.",
        },
    },
    {
        version = "6.55.0.0",
        date    = "17.10.2026",
        notes   = {
            "|cff7C6CFFDie Questhilfe sieht aufgeräumter aus.|r Questziele sind runde Marken in einer eigenen Farbe je Quest; ist eine Quest gewählt, treten die anderen zurück. „!“ und „?“ stehen auf einem weichen Schatten und bleiben auch auf heller Karte lesbar.",
            "Der Tooltip zeigt je Quest die Stufe in ihrer Schwierigkeitsfarbe und bei Quests im Log den Stand der Ziele – Erledigtes mit Haken.",
            "Die Filterleiste unter der Karte hat runde Schalter: eingeschaltet in deiner Klassenfarbe.",
        },
    },
    {
        version = "6.54.3.0",
        date    = "17.10.2026",
        notes   = {
            "|cff7C6CFFZauberöl, Wetzsteine & Co. lassen sich wieder aus den Taschen benutzen.|r Der Rechtsklick geht jetzt über einen geschützten Knopf des Spiels – das Spiel sperrte ihn bisher als Addon-Aktion.",
        },
    },
    {
        version = "6.54.2.0",
        date    = "17.10.2026",
        notes   = {
            "|cff7C6CFFDie Flugzeit verschwindet nach der Landung.|r Die Leiste blieb manchmal mit „Landung gleich“ stehen.",
            "|cff7C6CFFDas Fehlerfenster meldet keine Fehler anderer Addons mehr.|r Nennt ein Fehler selbst ein anderes Addon als Verursacher, bleibt er dessen Sache.",
        },
    },
    {
        version = "6.54.1.0",
        date    = "17.10.2026",
        notes   = {
            "|cff7C6CFFKeine Fehlermeldungen mehr an den Plaketten beim Einloggen.|r Das große Symbol für Betäubung und Furcht hing an der falschen Stelle fest und brachte die Plaketten des Spiels durcheinander.",
        },
    },
    {
        version = "6.54.0.0",
        date    = "17.10.2026",
        notes   = {
            "|cff7C6CFFNeu: die Flugzeit.|r Beim Fliegen zeigt eine Leiste, wohin es geht, wann du landest und wie weit du bist. Verschieben im Gestaltungsmodus, abschaltbar unter Komfort → Karte.",
            "Kennt WeintCodex eine Strecke noch nicht, steht dort ehrlich „unbekannt“ und die Zeit seit dem Abflug – nach der Landung ist sie gemessen, für alle deine Charaktere.",
        },
    },
    {
        version = "6.53.3.0",
        date    = "17.10.2026",
        notes   = {
            "|cff7C6CFFDanke lässt sich jetzt auch in Instanzen einschalten.|r Ab Werk dankt WeintCodex nur in der freien Welt; der neue Schalter „Auch in Instanzen“ nimmt Dungeons, Schlachtzüge und Schlachtfelder dazu.",
        },
    },
    {
        version = "6.53.2.0",
        date    = "17.10.2026",
        notes   = {
            "|cff7C6CFFDer Lehrer kennt den neuesten Stand.|r Siegel des Furors erst ab Stufe 26, neue Zauber für Magier und Schamanen, einige Stufen und Preise angepasst.",
        },
    },
    {
        version = "6.53.1.0",
        date    = "16.10.2026",
        notes   = {
            "|cff7C6CFFDer rote Punkt kennt jetzt auch Exorzismus und Heiligen Zorn.|r Auf alles außer Untote und Dämonen zeigt der Knopf, dass der Zauber dort nicht wirkt.",
        },
    },
    {
        version = "6.53.0.0",
        date    = "16.10.2026",
        notes   = {
            "|cff7C6CFFBetäubung und Furcht sind an den Plaketten gut zu sehen.|r Das Symbol steht jetzt groß links neben dem Balken statt klein und blass am Rand.",
            "|cff7C6CFFSpieler mit PvP-Markierung erkennst du sofort.|r Unter ihrer Plakette steht ein rotes „PvP“ – abschaltbar bei den Plaketten.",
            "|cff7C6CFF„/wcui fenster“ über einer Plakette löst keinen Fehler mehr aus.|r",
        },
    },
    {
        version = "6.52.3.0",
        date    = "16.10.2026",
        notes   = {
            "|cff7C6CFFAlchemie heißt wieder Alchemie.|r Die Berufsseite schrieb „Alchimie“, so wie das Spiel den Zauber nennt.",
        },
    },
    {
        version = "6.52.2.0",
        date    = "16.10.2026",
        notes   = {
            "|cff7C6CFFDas leere Kästchen unter dem Spielerrahmen ist weg.|r Ein Totemplatz, den das Spiel als belegt meldet, ohne Totem darin, bleibt jetzt versteckt.",
        },
    },
    {
        version = "6.52.1.0",
        date    = "16.10.2026",
        notes   = {
            "|cff7C6CFFDer Abklingzeitmanager ist im Gestaltungsmodus klar gekennzeichnet.|r Seine Anzeigen gehören dem Spiel: sie tragen jetzt eine graue Markierung, und ein Klick darauf öffnet den Bearbeitungsmodus des Spiels, wo sie sich verschieben lassen.",
        },
    },
    {
        version = "6.52.0.0",
        date    = "16.10.2026",
        notes   = {
            "|cff7C6CFFDas Charakterfenster zeigt die Gegenstandsstufe.|r An jedem angelegten Gegenstand steht oben links seine Stufe in der Farbe seiner Qualität – wie in den Taschen.",
        },
    },
    {
        version = "6.51.3.0",
        date    = "16.10.2026",
        notes   = {
            "|cff7C6CFFKein leeres Kästchen mehr unter dem Spielerrahmen.|r Ohne gesetztes Totem verschwinden die Totemplätze außerhalb des Kampfes ganz.",
        },
    },
    {
        version = "6.51.2.0",
        date    = "16.10.2026",
        notes   = {
            "|cff7C6CFFFehlerberichte zu gesperrten Taschengegenständen sind ausführlicher.|r Wird ein Gegenstand aus der Tasche vom Spiel gesperrt, hängt der Bericht gleich an, woran es liegt – bitte einfach mitschicken.",
        },
    },
    {
        version = "6.51.1.0",
        date    = "16.10.2026",
        notes   = {
            "|cff7C6CFFKein Fehler mehr beim Klick-Knopf der Erinnerungen.|r Der Knopf zum Anwenden eines fehlenden Buffs löste beim Erscheinen des Hinweises einen Fehler aus.",
        },
    },
    {
        version = "6.51.0.0",
        date    = "16.10.2026",
        notes   = {
            "|cff7C6CFFDie Knöpfe an der Minikarte tragen das WeintCodex-Design.|r Aufspüren, Kalender und Post sind dunkle Kacheln mit schlichtem Zeichen statt goldener Knöpfe; eine offene Kalendereinladung zeigt ein Punkt. Abschaltbar unter Minikarte → Bedienung.",
        },
    },
    {
        version = "6.50.2.0",
        date    = "16.10.2026",
        notes   = {
            "|cff7C6CFFDie Untere Schwarzfelsspitze ist bebildert.|r Ein Kopfbild und Bilder zu allen neun Begegnungen – von Hochlord Omokk bis Oberanführer Wyrmthalak.",
        },
    },
    {
        version = "6.50.1.0",
        date    = "16.10.2026",
        notes   = {
            "|cff7C6CFFDer Düsterbruch ist bebildert.|r Ein Kopfbild und Bilder zu allen 19 Begegnungen in Ost, West und Nord – von Pusillin bis König Gordok.",
        },
    },
    {
        version = "6.50.0.0",
        date    = "16.10.2026",
        notes   = {
            "|cff7C6CFFFehler direkt zum Kopieren.|r Geht in WeintCodex etwas schief, öffnet sich ein Fenster mit allem, was zum Beheben nötig ist – markieren, Strg+C, an den Entwickler schicken. Im Kampf erst danach. Alle gespeicherten Fehler: /wcui fehler. Abschaltbar unter Komfort › Anzeigen.",
        },
    },
    {
        version = "6.49.1.0",
        date    = "16.10.2026",
        notes   = {
            "|cff7C6CFFDie Blackrocktiefen sind bebildert.|r Ein Kopfbild und Bilder zu allen 22 Begegnungen in Gefängnistrakt, Schattenschmiede und Kaisersitz – vom Ring des Gesetzes bis zu Imperator Dagran Thaurissan.",
        },
    },
    {
        version = "6.49.0.0",
        date    = "16.10.2026",
        notes   = {
            "|cff7C6CFFVier weitere Dungeons bebildert.|r Uldaman, Zul'Farrak, Maraudon und der Tempel von Atal'Hakkar haben jetzt ein eigenes Kopfbild und Bilder zu jedem Boss – auch zu Gahz'rilla, Atal'alarion und dem Avatar von Hakkar.",
        },
    },
    {
        version = "6.48.3.0",
        date    = "16.10.2026",
        notes   = {
            "|cff7C6CFFProfil-Import übernimmt das Layout ganz.|r Mit Oberfläche wird das importierte Layout „WeintCodex“ jetzt auch gleich aktiv – ein neuer Charakter blieb vorher auf der Vorlage des Spiels.",
            "|cff7C6CFFKein Fehler mehr beim Hinweis auf seltene Gegner.|r Das Ausblenden im oder kurz vor dem Kampf wurde vom Spiel blockiert.",
        },
    },
    {
        version = "6.48.2.0",
        date    = "16.10.2026",
        notes   = {
            "|cff7C6CFFSuche und Hauptschalter haben Platz.|r Die Suche steht rechts in der Mitte des Kopfes, der Schalter oben daneben – nichts überlappt mehr.",
        },
    },
    {
        version = "6.48.1.0",
        date    = "16.10.2026",
        notes   = {
            "|cff7C6CFFDas Suchfeld oben ist jetzt wirklich rund.|r Vorher blieben auf dem farbigen Kopf trotz Rundung Ecken sichtbar.",
        },
    },
    {
        version = "6.48.0.0",
        date    = "16.10.2026",
        notes   = {
            "|cff7C6CFFDie Einstellungen sind runder.|r Felder, Suche, Auswahllisten, Knöpfe, Hinweise und die Auswahl in der Seitenleiste haben weiche Ecken – passend zum neuen Logo, deine Klassenfarbe bleibt.",
        },
    },
    {
        version = "6.47.0.0",
        date    = "16.10.2026",
        notes   = {
            "|cff7C6CFFEin neues, ruhiges Logo.|r Eine dunkle Münze mit Goldrand und einem klaren W – gut erkennbar auch klein an der Minikarte, in den Einstellungen und im Willkommens-Assistenten.",
        },
    },
    {
        version = "6.46.0.0",
        date    = "16.10.2026",
        notes   = {
            "|cff7C6CFFAuch das Codex-Fenster wirkt ruhiger.|r Überschriften, Pfad, Marken und Versionsangabe ohne gesperrte Schreibmaschinenschrift, und überall eine eigene, schlanke Bildlaufleiste mit Griff zum Ziehen statt der Reste der Leiste des Spiels.",
        },
    },
    {
        version = "6.45.1.0",
        date    = "16.10.2026",
        notes   = {
            "|cff7C6CFFDie Flugpunkt-Erinnerung merkt sich eingesammelte Punkte.|r Wer einen Flugpunkt entdeckt oder beim Flugmeister die Karte öffnet, hat ihn ab dann für diesen Charakter gespeichert – die Erinnerung kommt dort nicht wieder.",
        },
    },
    {
        version = "6.45.0.0",
        date    = "16.10.2026",
        notes   = {
            "|cff7C6CFFDie Einstellungen wirken ruhiger und klarer.|r Runde Schalter, gut lesbare Erläuterungen, sachliche Überschriften, Hinweise als eigene Karte und in der Seitenleiste ein Punkt statt „an/aus“ unter jedem Eintrag – in Worten nur noch, wenn etwas zu tun ist.",
        },
    },
    {
        version = "6.44.1.0",
        date    = "16.10.2026",
        notes   = {
            "|cff7C6CFFDie Minikarte gehört im Bearbeitungsmodus dem Spiel.|r Solange er offen ist, rückt WeintCodex Karte und Knöpfe nicht mehr zurecht und ordnet sie erst nach dem Schließen neu – Spiel und WeintCodex haben sich die Karte vorher gegenseitig zugeschoben.",
        },
    },
    {
        version = "6.44.0.0",
        date    = "16.10.2026",
        notes   = {
            "|cff7C6CFFZehn Balkentexturen für alles.|r Unter Allgemein wählst du die Textur mit Vorschau in der Liste – sie gilt für jeden Balken: Rahmen, Plaketten, Schadensanzeige, Zauber- und Erfahrungsbalken. Neu: Seide, Kante, Glas, Matt, Neon, Rillen und Streifen.",
            "|cff7C6CFFGlanz steht jetzt unter Allgemein.|r Es gehört zum Aussehen, nicht zum Komfort – deine Einstellungen ziehen mit um.",
        },
    },
    {
        version = "6.43.0.0",
        date    = "16.10.2026",
        notes   = {
            "|cff7C6CFFGlanz für deine Balken.|r Einheiten- und Gruppenrahmen, Schadensanzeige, Zauberleiste und Erfahrungsbalken können jetzt leben wie die Namensplaketten: ein Schimmer läuft ab und zu darüber, Werte gleiten, und was ein Treffer nahm, bleibt kurz hell stehen. Einschalten und einstellen unter Komfort › Glanz – je Bereich, je Wirkung, Stärke und Takt.",
        },
    },
    {
        version = "6.42.0.0",
        date    = "16.10.2026",
        notes   = {
            "|cff7C6CFFDas Profil kennt jetzt deine Aktionsleisten.|r Export und Import nehmen mit, welche Leisten an sind, und ein neuer Charakter mit dem Profil bekommt sie beim Einloggen gleich eingeschaltet – kein Haken mehr in den Optionen des Spiels.",
        },
    },
    {
        version = "6.41.9.0",
        date    = "16.10.2026",
        notes   = {
            "|cff7C6CFFDie Knöpfe neben der Minikarte stehen in einer Linie.|r Der Kalender saß seit dem neuen Spielstand versetzt unter der Verfolgung – jetzt stehen alle mittig in ihrer Spalte.",
            "|cff7C6CFF/wcui speicher zeigt beim Erscheinen der Namensplaketten den Rest.|r Neu bauen, NPC erkennen und Lösen stehen einzeln da.",
        },
    },
    {
        version = "6.41.8.0",
        date    = "16.10.2026",
        notes   = {
            "|cff7C6CFFDer Willkommens-Assistent fragt nach dem Danke für Buffs.|r Wer neu anfängt, entscheidet dort bei Handel und Gespräche selbst, ob Fremde für ihre Buffs ein Flüstern bekommen.",
        },
    },
    {
        version = "6.41.7.0",
        date    = "16.10.2026",
        notes   = {
            "|cff7C6CFFDanke für Buffs ist ab Werk an.|r Fremde, die dich draußen buffen, bekommen ein kurzes Flüstern – ausschalten lässt es sich wie bisher in den Komforteinstellungen unter „Danke“.",
        },
    },
    {
        version = "6.41.6.0",
        date    = "16.10.2026",
        notes   = {
            "|cff7C6CFFMehr Quests auf der Karte.|r Die Questhilfe kennt rund 400 Einträge mehr, mit zusätzlichen Gebern, Objekten und Lagen.",
            "|cff7C6CFFDungeons vollständiger.|r Die ersten Quests in Dalaran, Quests der Ausgrabungsstätte, Gnomeregan und Kloster, dazu rund 170 Gegenstände an Bossen und Gegnern und neue Questgeber auf der Karte.",
            "|cff7C6CFFKein Leichnam mehr mit leerer Plakette.|r Ein getöteter Gegner zeigte mit eingeschaltetem Glitzern für Kraut und Erz bis zum Plündern eine Plakette mit 0 % Leben.",
        },
    },
    {
        version = "6.41.5.0",
        date    = "15.10.2026",
        notes   = {
            "|cff7C6CFFNamensplaketten erscheinen sparsamer.|r Eine Plakette wird nur noch neu eingerichtet, wenn sich etwas an den Einstellungen geändert hat – bisher bei jedem Erscheinen. /wcui speicher zeigt die Schritte jetzt einzeln.",
        },
    },
    {
        version = "6.41.4.0",
        date    = "15.10.2026",
        notes   = {
            "|cff7C6CFFGenauer messen, wo Speicher entsteht.|r /wcui speicher zeigt die Namensplaketten jetzt aufgeteilt (Erscheinen, Questziele, Leben, Bedrohung) und bis zu zwölf Teile. Das Teilen der Auktionspreise läuft nur noch in einem ruhigen Takt statt in jedem Bild.",
        },
    },
    {
        version = "6.41.3.0",
        date    = "15.10.2026",
        notes   = {
            "|cff7C6CFFRinge in eigenen Farben und in der Mitte.|r Jeder Ring hat seine Farbe – Reittiere Glut, Reisen Eis, Markierungen Blut, Berufe Gift, eigene Neon –, wählbar unter Komfort → Ringe. Ein Ring öffnet jetzt in der Bildschirmmitte, gezielt wird von dort zur Maus, egal wo sie steht (abschaltbar).",
            "|cff7C6CFFWeniger Speicher für den Questpfeil.|r Die Geländekarte liegt ein Viertel kleiner im Speicher (rund 3 MB weniger).",
        },
    },
    {
        version = "6.41.2.0",
        date    = "15.10.2026",
        notes   = {
            "|cff7C6CFFDanke für Segen: „Bubble“ statt „Blase“.|r Auch wer die Sprüche schon bearbeitet hatte, bekommt den Satz berichtigt.",
        },
    },
    {
        version = "6.41.1.0",
        date    = "15.10.2026",
        notes   = {
            "|cff7C6CFFDanke: alle Sprüche erreichbar.|r Hat eine Sorte mehr als acht Sprüche, blätterst du mit dem Mausrad über der Liste oder mit den Pfeilen; darunter steht, welche du gerade siehst. Ein neuer Spruch springt gleich ins Bild.",
        },
    },
    {
        version = "6.41.0.0",
        date    = "15.10.2026",
        notes   = {
            "|cff7C6CFFRinge: zielen statt treffen.|r Die Richtung reicht – die Maus muss nicht mehr auf dem Symbol liegen. Neues Aussehen mit Neonband, runden Symbolen, pulsierender Wahl und Zeiger.",
            "|cff7C6CFFRinge: Bedingungen und Abklingzeiten.|r Jeder Eintrag eines eigenen Rings kann nur im Kampf, nur beritten, nur drinnen … erscheinen – oder mit eigener Bedingung wie [combat,group]. Abklingzeiten laufen auf den Symbolen.",
            "|cff7C6CFFDanke für Buffs: eigene Seite.|r Alle Sprüche je Sorte einsehen, bearbeiten, löschen und hinzufügen, die Erkennungswörter anpassen, die Wartezeit vor dem Flüstern und den Anteil allgemeiner Sprüche einstellen.",
        },
    },
    {
        version = "6.40.1.0",
        date    = "15.10.2026",
        notes   = {
            "|cff7C6CFFDer Questpfeil kennt jetzt alle Ebenen.|r Wurzeln, Äste, Rampen, Brücken und Städte unter dem Berg fehlten bisher – in Teldrassil lief der Weg deshalb erst an den Kartenrand und zurück, anderswo quer durch Fels. Der Weg beginnt außerdem nie mehr in einer abgeschlossenen Ecke, sondern an der nächsten Stelle, die wirklich irgendwohin führt.",
        },
    },
    {
        version = "6.40.0.0",
        date    = "15.10.2026",
        notes   = {
            "|cff7C6CFFRinge auf einer Taste.|r Taste halten, Maus in eine Richtung, loslassen – oder drücken und klicken. Dabei: Reittiere, Reisen (Ruhestein, Teleporte, Portale), Markierungen und Berufe; dazu bis zu acht eigene Ringe mit Zaubern, Gegenständen, Reittieren und Makros – hineinziehen oder eintippen. Komfort → Ringe, die Tasten legst du dort fest.",
        },
    },
    {
        version = "6.39.0.0",
        date    = "15.10.2026",
        notes   = {
            "|cff7C6CFFErinnerungen zum Anklicken.|r Fehlt Gift, Öl, Wetzstein oder Essen und liegt etwas davon in der Tasche, genügt ein Klick: eine Sorte wird gleich benutzt, bei mehreren öffnet sich ein Ring um den Mauszeiger. Bei Waffen links Haupthand, rechts Nebenhand. Nicht im Kampf.",
            "|cff7C6CFFManaeffizienz im Zauber-Tooltip.|r Heilung oder Schaden je Mana und je Sekunde, aus den Zahlen des Tooltips – praktisch, um Ränge zu vergleichen. Komfort → Anzeigen.",
            "|cff7C6CFFDanke für Buffs.|r Bufft dich draußen ein Fremder, flüstert WeintCodex ihm einen Dank mit Augenzwinkern, passend zum Buff. Ab Werk aus, Komfort → Automatik.",
        },
    },
    {
        version = "6.38.3.0",
        date    = "15.10.2026",
        notes   = {
            "|cff7C6CFFHändler: nach dem Blättern fehlen keine Waren mehr.|r Wer auf „Weiter“ und wieder „Zurück“ klickte, sah auf der ersten Seite nur noch so viele Waren wie auf der letzten.",
        },
    },
    {
        version = "6.38.2.0",
        date    = "15.10.2026",
        notes   = {
            "|cff7C6CFFGroßes Händlerfenster aufgeräumt.|r Leere Plätze stehen nicht mehr verstreut im Raster, zwischen den Zeilen bleibt Luft, und der Rückkauf-Platz bleibt unten im Fuß statt mitten im Fenster.",
        },
    },
    {
        version = "6.38.1.0",
        date    = "15.10.2026",
        notes   = {
            "|cff7C6CFFDer Schwungtimer des Spiels im WeintCodex-Stil.|r Die Balken bekommen Textur, Rand und Schrift von WeintCodex – sie werden beim ersten Angriff gefunden. Abschaltbar unter Einheitenrahmen → Allgemein.",
            "|cff7C6CFF/wcui fenster mit Namen oder Text.|r Für Fenster, die keine Maus annehmen: „/wcui fenster Waffenhand“ findet den Rahmen über seine Beschriftung.",
        },
    },
    {
        version = "6.38.0.0",
        date    = "15.10.2026",
        notes   = {
            "|cff7C6CFFDas Händlerfenster lässt sich groß ziehen.|r Am Griff unten rechts – so viele Waren, wie hineinpassen, stehen nebeneinander und untereinander, Blättern nur noch, wenn es mehr sind. Die Größe bleibt gemerkt. Abschaltbar unter Komfort → Automatik.",
        },
    },
    {
        version = "6.37.1.0",
        date    = "15.10.2026",
        notes   = {
            "|cff7C6CFFDer Laufweg geht nicht mehr durch Wände.|r Die Linie auf der Minikarte knickt jetzt an den Ecken, statt sie abzuschneiden, und der Pfeil zeigt auf die nächste Ecke statt durch einen Raum ohne Tür. Gemeldet aus Ironforge.",
        },
    },
    {
        version = "6.37.0.1",
        date    = "15.10.2026",
        notes   = {
            "|cff7C6CFFKein Ruckeln mehr mit der Questhilfe.|r Das Nachsehen im Kalender löste sich selbst immer wieder aus, und die Minikarte rechnete dadurch jedes Bild alle Quests neu. Jetzt wird nur neu gerechnet, wenn sich die laufenden Feste wirklich ändern.",
        },
    },
    {
        version = "6.37.0.0",
        date    = "15.10.2026",
        notes   = {
            "|cff7C6CFFFestquests nur, wenn das Fest läuft.|r Die Questhilfe kennt die Quests von Mondfest, Liebe liegt in der Luft, Kinderwoche, Sonnenwendfest, Erntedankfest, Schlotternächte, Winterhauchfest und Dunkelmond-Jahrmarkt und zeigt sie nur, solange der Kalender des Spiels das Fest nennt. Eigener Schalter „Feste“ unter der Karte; auf Wunsch auch alle.",
            "|cff7C6CFFBuffs im WeintCodex-Stil greifen jetzt.|r Die Gestaltung lief bisher gar nicht an. /wcui prüfen zeigt, wie viele Symbole gestaltet sind.",
        },
    },
    {
        version = "6.36.0.0",
        date    = "15.10.2026",
        notes   = {
            "|cff7C6CFFBuffs im WeintCodex-Stil.|r Die Symbole oben rechts sind beschnitten wie die Aktionsknöpfe, mit feinem dunklem Rand und kleiner Restzeit in der Schrift von WeintCodex. Debuffs zeigen ihre Art weiter als Farbe am Rand. Abschaltbar bei der Minikarte.",
        },
    },
    {
        version = "6.35.3.2",
        date    = "15.10.2026",
        notes   = {
            "|cff7C6CFFDie Wegsuche rechnet nicht mehr im Dauerlauf.|r Wechselte der Pfeil sein Ziel, begann sie von vorn und wurde nie fertig. Jetzt merkt sie sich Wege je Ziel und lässt eine laufende Suche zu Ende rechnen. /wcui pfeil zeigt, wie oft sie sucht.",
        },
    },
    {
        version = "6.35.3.1",
        date    = "15.10.2026",
        notes   = {
            "|cff7C6CFFDie Wegsuche übers Gelände frisst keinen Speicher mehr.|r Bei langen Wegen packte sie Kartenabschnitte immer wieder neu aus und wurde dadurch nie fertig – jetzt behält sie das kleine Wegenetz und entpackt das große Gitter nur, wo sie es braucht.",
            "|cff7C6CFFGlitzern erkennt Erz und Kräuter vor dir.|r Das Spiel meldet ein Objekt nicht als Einheit; jetzt reicht seine Kennung.",
        },
    },
    {
        version = "6.35.3.0",
        date    = "15.10.2026",
        notes   = {
            "|cff7C6CFFWeintCodex UI im Spielmenü an seinem Platz.|r Direkt unter „Bearbeitungsmodus“, in Farbe: Weint grün, Codex lila, UI türkis.",
        },
    },
    {
        version = "6.35.2.0",
        date    = "15.10.2026",
        notes   = {
            "|cff7C6CFFDeutlich weniger Speicherabfall beim Laufen mit dem Questpfeil.|r Die Wegsuche übers Gelände legte bei jeder Neuberechnung große Tabellen neu an und packte Kartenabschnitte immer wieder aus; jetzt nutzt sie dieselben Tabellen weiter und behält die zuletzt gebrauchten Abschnitte. Die Wege bleiben dieselben.",
            "|cff7C6CFFErz und Kräuter finden ihre Plakette zuverlässiger.|r Fand das Glitzern die Plakette des Objekts nicht direkt, blieb es aus – jetzt sucht es sie unter allen Plaketten.",
        },
    },
    {
        version = "6.35.1.0",
        date    = "15.10.2026",
        notes   = {
            "|cff7C6CFFGestaltungsmodus aufgeräumt.|r Questpfeil, Kompass, Haltbarkeit, Erinnerungen, Markieren, Seltene Gegner und Kampfhinweis liegen ab Werk untereinander statt übereinander. Die Leiste des Gestaltungsmodus lässt sich wegziehen, und das Band des Testmodus verschwindet, solange der Gestaltungsmodus offen ist – seine Leiste zeigt „Testdaten“ ohnehin.",
            "|cff7C6CFF„WeintCodex UI“ im Spielmenü.|r Esc drücken und den Eintrag wählen – die Einstellungen öffnen sich.",
        },
    },
    {
        version = "6.35.0.0",
        date    = "15.10.2026",
        notes   = {
            "|cff7C6CFFKompass für den Questpfeil.|r Auf Wunsch ein schmales Band oben am Bildschirm mit N, O, S, W: das Ziel als Nadel, der nächste Flugmeister oder Anleger und der Punkt voraus auf dem Weg mit Entfernung. Wahlweise neben dem Pfeil oder statt ihm, Größe einstellbar, verschiebbar im Gestaltungsmodus.",
        },
    },
    {
        version = "6.34.0.0",
        date    = "14.10.2026",
        notes   = {
            "|cff7C6CFFInfozeile auch unter der Minikarte.|r Beim Chat gibt es dafür eine eigene Seite: unter dem Chat oder unter der Minikarte, und jeder Wert einzeln an oder aus. Neu dabei: Koordinaten (Klick öffnet die Karte) und Gildenmitglieder online (Klick öffnet die Gilde). Passt nicht alles nebeneinander, bricht die Zeile um.",
        },
    },
    {
        version = "6.33.7.1",
        date    = "14.10.2026",
        notes   = {
            "|cff7C6CFFKombopunkte in der Vorschau.|r Die Plakette in den Einstellungen zeigt 3 von 5 mit deinen Farben und deiner Form – bei jeder Klasse. Die Punkte liegen unter der Bedrohungsleiste, der Zauberbalken rückt darunter.",
        },
    },
    {
        version = "6.33.7.0",
        date    = "14.10.2026",
        notes   = {
            "|cff7C6CFFKombopunkte nach Wunsch einfärben.|r Eigene Seite bei den Plaketten: eine Farbe je Stand von 1 bis 5 – ab Werk von Rot bis Grün –, alle Punkte in der Farbe des Stands, jeder Punkt in seiner Farbe oder eine Farbe für alle. Dazu Höhe, Abstände, über oder unter der Plakette und leere Plätze an oder aus.",
        },
    },
    {
        version = "6.33.6.0",
        date    = "14.10.2026",
        notes   = {
            "|cff7C6CFFKombopunkte an der Namensplakette.|r Schurken und Druiden in Katzengestalt sehen ihre Punkte als Reihe unter der Plakette ihres Ziels – andere Klassen und Gestalten nicht. Abschaltbar bei den Plaketten.",
        },
    },
    {
        version = "6.33.5.0",
        date    = "14.10.2026",
        notes   = {
            "|cff7C6CFFChat bei 0 % wirklich unsichtbar.|r Auch der Schatten um das Fenster und der Grund des Spiels verschwinden – sichtbar bleibt nur die Schrift, in jedem Chatfenster.",
            "|cff7C6CFFMikromenü im Bearbeitungsmodus verschieben.|r Wo du es dort loslässt, bleibt es jetzt stehen, statt nach unten links zurückzuspringen.",
        },
    },
    {
        version = "6.33.4.0",
        date    = "14.10.2026",
        notes   = {
            "|cff7C6CFFChat bei 0 % Deckkraft ganz durchsichtig.|r Reiterzeile, Rand und Infozeile verschwinden mit, nur die Schrift bleibt.",
            "|cff7C6CFFChat bleibt nach dem Neuladen bündig am Rand.|r Vorher rückte ihn das Spiel beim Laden ein Stück nach innen.",
            "|cff7C6CFFMikromenü und Taschenleiste bleiben, wo du sie hinziehst.|r Das Spiel setzte sie bei manchen nach dem Anordnen zurück.",
            "|cff7C6CFFNeue Regelart „Zauberöl auf der Waffe“.|r Kein Öl auswählen nötig – die Regel nimmt das stärkste Öl in deiner Tasche und schweigt, wenn keins da ist.",
        },
    },
    {
        version = "6.33.3.0",
        date    = "14.10.2026",
        notes   = {
            "|cff7C6CFFErinnerung an Zauberöl für Zauberwirker.|r Magier, Priester, Hexenmeister, Druiden und Paladine werden erinnert, wenn ein Zauber- oder Manaöl in der Tasche liegt und die Waffe keins trägt – mit dem stärksten Öl als Vorschlag. Ohne Öl in der Tasche bleibt es still. Wer schon eigene Regeln hat, ergänzt sie mit „Für meine Klasse“.",
        },
    },
    {
        version = "6.33.2.0",
        date    = "14.10.2026",
        notes   = {
            "|cff7C6CFFDie Route liegt über dem Unerkundeten der Karte.|r Vorher verschwand sie unter der Abdunklung, sobald sie durch ein Gebiet lief, das du noch nicht aufgedeckt hast.",
            "|cff7C6CFFMikromenü und Taschenleiste ohne goldene Rahmen.|r Das Mikromenü steht auf einer Kachel wie die Aktionsleisten, die Taschenleiste verliert ihren Rahmen und die Trenner; auch der Schlüsselbund ist flach.",
        },
    },
    {
        version = "6.33.1.0",
        date    = "14.10.2026",
        notes   = {
            "|cff7C6CFFRuhigere Weltkarte.|r Schiffslinien biegen jetzt mit ihrer Richtung – steigende nach oben, fallende nach unten – statt alle gleich. Deine Route erscheint erst auf der Karte des Kontinents oder Gebiets, nicht mehr quer über die ganze Welt.",
        },
    },
    {
        version = "6.33.0.0",
        date    = "14.10.2026",
        notes   = {
            "|cff7C6CFFSchiffs- und Zeppelinlinien auf der Weltkarte geschwungen, mit Abfahrten am Anleger.|r Fährst du mit der Maus über einen Anleger, steht dort jede Linie mit Ziel und – sobald gemessen – „liegt an · fährt in 0:47“ oder „kommt in 3:23“. Ungemessene Linien sagen das, statt eine Zeit zu raten.",
            "|cff7C6CFFRazorfen Downs und die Drowned City sind bebildert.|r Kopfbild und Bossbilder; in der Drowned City nur Zul'Alai, weil die anderen Bosse noch nicht feststehen.",
        },
    },
    {
        version = "6.32.6.0",
        date    = "14.10.2026",
        notes   = {
            "|cff7C6CFFBeide Züge der Tiefenbahn im Fahrplan.|r Eine Fahrt reicht: Der zweite Zug fährt im selben Takt versetzt, und der Pfeil nennt immer den, der zuerst abfährt. Verpasst du einen, steht sofort die Abfahrt des anderen da.",
        },
    },
    {
        version = "6.32.5.0",
        date    = "14.10.2026",
        notes   = {
            "|cff7C6CFFAbfahrtszeit der Tiefenbahn wird angezeigt.|r Nach einer Fahrt steht unter dem Pfeil „Tiefenbahn nehmen, Abfahrt in 1:20“ – auch, solange du noch vor dem Eingang stehst. Vorher wählte er manchmal den zweiten, nie gemessenen Zug und schrieb „Fahrplan unbekannt“.",
        },
    },
    {
        version = "6.32.4.0",
        date    = "14.10.2026",
        notes   = {
            "|cff7C6CFFIn der Tiefenbahn weiß der Pfeil jetzt, wo du bist.|r Statt „Position unbekannt“ führt er weiter zum Ziel – und misst dabei die Abfahrtszeiten der Bahn.",
            "|cff7C6CFFDie Route auf der Karte läuft mit.|r Sie beginnt bei dir, nicht dort, wo geplant wurde, und folgt dem Gelände auch in der Ferne statt von Abschnitt zu Abschnitt gerade zu laufen.",
        },
    },
    {
        version = "6.32.3.0",
        date    = "14.10.2026",
        notes   = {
            "|cff7C6CFFDie Route ist jetzt gelb – mit dunkler Kontur.|r So hebt sie sich auf der Karte am besten ab, auch auf gelbem Grund. Auf der Welt- und den Kontinentkarten, die selbst gelb-orange sind, wechselt sie von selbst auf Türkis. Unter „Farbe der Route“ lässt sich das festlegen.",
        },
    },
    {
        version = "6.32.2.0",
        date    = "14.10.2026",
        notes   = {
            "|cff7C6CFFDie Route auf der Weltkarte ist jetzt zu sehen.|r Sie lag bisher unsichtbar in der Ecke der Karte.",
            "|cff7C6CFFSchiffslinien neu gezeichnet:|r gestrichelt und gerade von Anleger zu Anleger, auf der Weltkarte quer übers Meer – statt der Kringel an den Häfen.",
            "|cff7C6CFFHöhenunterschied stimmt wieder.|r Er rechnete gegen einen Punkt auf dem Weg statt gegen das Ziel und zeigte deshalb Hunderte Meter, wo keine sind.",
            "|cff7C6CFFAn Flugpunkte erinnern.|r Kommst du an einem Flugmeister vorbei, dessen Flugpunkt du noch nicht hast, sagt WeintCodex Bescheid – fürs spätere Reisenetz.",
            "|cff7C6CFFTiefenbahn:|r Der Pfeil sagt jetzt „Tiefenbahn nehmen“ und führt zum Eingang, statt die Luftlinie zu zeigen.",
            "|cff7C6CFFWeniger Speicher:|r Die Geländekarte braucht im Spiel ein Dreißigstel des Speichers, der Questpfeil legt einen Bruchteil des Abfalls an.",
        },
    },
    {
        version = "6.32.1.0",
        date    = "14.10.2026",
        notes   = {
            "|cff7C6CFFDie Route steht jetzt auch auf der Weltkarte.|r Öffnest du die Karte, siehst du den ganzen Weg des Questpfeils: zu Fuß dem Gelände nach, Flüge von Flugmeister zu Flugmeister, Schiffe und Zeppeline auf ihrer echten Fahrstrecke.",
            "|cff7C6CFFSchiffslinien auf der Karte.|r Alle Schiffe, Zeppeline und die Tiefenbahn deiner Fraktion als Linien zwischen den Anlegern. Beides einzeln abschaltbar im Questpfeil.",
            "|cff7C6CFFWeltkarte:|r Das helle Rechteck am Rand (Rotkammgebirge unten rechts) ist jetzt wirklich weg – schmale Randstücke erkundeter Gebiete bekommen den weichen Rand.",
        },
    },
    {
        version = "6.32.0.0",
        date    = "14.10.2026",
        notes   = {
            "|cff7C6CFFDer Pfeil folgt jetzt dem Gelände.|r Statt der Luftlinie zeigt er auf den echten Laufweg um Berge, Seen und Schluchten herum, und die Minikarte zeichnet ihn gepunktet. Die Entfernung ist die des Weges, nicht der Luftlinie. Ausschaltbar unter „Laufweg übers Gelände“.",
            "|cff7C6CFFRuhestein wird erkannt.|r Rastest du im Gasthaus deines Bindeorts, merkt sich der Planer die Lage; bis dahin nimmt er den Flugpunkt des Ortes. Der Ruhestein muss dafür nicht mehr benutzt werden.",
            "|cff7C6CFFAbfahrtszeiten mit Gilde und Gruppe teilen.|r Wer mitfährt, misst den Takt – und alle anderen mit WeintCodex sehen danach „Abfahrt in 1:20“. Geteilt wird nur der Takt, nie dein Ort.",
            "|cff7C6CFFWeltkarte:|r Ein hartes, helles Rechteck am Rand (z. B. unten rechts im Rotkammgebirge) ist weg – aufgedeckte Kartenteile bekommen jetzt auch den weichen Rand.",
        },
    },
    {
        version = "6.31.2.0",
        date    = "14.10.2026",
        notes   = {
            "|cff7C6CFFDer Routenplaner kennt jetzt die echten Wege.|r Echte Flugzeiten jeder Strecke, echte Laufwege zwischen Flugmeistern, Anlegern und Portalen – er lässt dich nicht mehr über Berge laufen, die man nicht überqueren kann. Inseln wie Teldrassil erreicht er nur per Schiff oder Portal.",
            "|cff7C6CFFRuhestein, Teleports, Abfahrtszeiten.|r Spart der Ruhestein mindestens zwei Minuten, schlägt der Pfeil ihn vor; Magier-Teleports ebenso. Fährst du einmal mit einem Schiff, Zeppelin oder der Tiefenbahn, kennt er ihren Takt auf deinem Realm und sagt „Abfahrt in 1:20“ – vorher ehrlich „Fahrplan unbekannt“.",
            "|cff7C6CFFLinie auf der Minikarte.|r Gepunktet bis zum nächsten Wegpunkt. Und: kennt er noch keinen deiner Flugpunkte, sagt er dir, dass du beim Flugmeister einmal die Flugkarte öffnen musst.",
        },
    },
    {
        version = "6.31.1.0",
        date    = "14.10.2026",
        notes   = {
            "|cff7C6CFFDer Questpfeil plant den Weg jetzt selbst.|r Ist ein Flug, ein Schiff, ein Zeppelin, die Tiefenbahn oder ein Portal schneller als laufen, zeigt er zuerst zum Flugmeister oder Anleger und sagt, wohin es von dort geht – mit ungefährer Reisezeit, auch auf einen anderen Kontinent. Kein zusätzliches Addon nötig.",
            "|cff7C6CFFFlugpunkte lernt er von dir.|r Öffne einmal beim Flugmeister die Flugkarte: dann kennt er deine Flugpunkte. Jeder Flug, den du machst, ersetzt seine Schätzung durch die gemessene Zeit. Ein- und ausschalten im Questpfeil unter „Routenplaner“.",
        },
    },
    {
        version = "6.31.0.0",
        date    = "14.10.2026",
        notes   = {
            "|cff7C6CFFQuestpfeil und Routenplaner arbeiten zusammen.|r Ist Shortest Path Forever installiert, wählt der Questpfeil weiter das nächste lohnende Ziel – und lässt sich von Shortest Path den schnellsten Weg dorthin planen, mit Flugrouten, Schiffen und Portalen. Unter dem Pfeil steht dann die echte Reisezeit und die nächste Etappe, auch auf einem anderen Kontinent.",
            "|cff7C6CFFDeine eigenen Reisen bleiben deine.|r Startest du in Shortest Path selbst eine Reise, ersetzt der Questpfeil sie nie; brichst du seine ab, fragt er für dieses Ziel nicht wieder. Einstellbar im Questpfeil unter „Routenplaner“.",
        },
    },
    {
        version = "6.30.55.7",
        date    = "13.10.2026",
        notes   = {
            "|cff7C6CFFMessenger: „Nach dem Senden weiterschreiben“.|r Neuer Schalter, ab Werk aus. An bleibt das Eingabefeld nach Enter aktiv für die nächste Nachricht; Enter auf leerem Feld gibt die Tastatur immer frei.",
        },
    },
    {
        version = "6.30.55.6",
        date    = "13.10.2026",
        notes   = {
            "|cff7C6CFFNach dem Senden im Messenger kannst du sofort weiterlaufen.|r Enter schickt die Nachricht ab und gibt die Tastatur frei – wie die Chatzeile des Spiels. Weiterschreiben: ins Feld klicken oder R drücken.",
        },
    },
    {
        version = "6.30.55.5",
        date    = "13.10.2026",
        notes   = {
            "|cff7C6CFFMunition erinnert auch nach dem Sortenwechsel.|r Liegt neue Munition in der Tasche, die alte ist aber verschossen, heißt es „nicht angelegt“ statt „leer“; angelegt zählt die Menge in den Taschen.",
        },
    },
    {
        version = "6.30.55.4",
        date    = "13.10.2026",
        notes   = {
            "|cff7C6CFFDie Rolle der geringeren Hervorrufung erinnert nicht mehr.|r Ihre Abklingzeit von 8 Minuten wurde als Wirkdauer gelesen.",
        },
    },
    {
        version = "6.30.55.3",
        date    = "13.10.2026",
        notes   = {
            "|cff7C6CFFKeine Erinnerung mehr an Rollen mit Sofortwirkung.|r Was sofort Mana oder Leben gibt – etwa die Rolle der geringen Hervorrufung – ist kein fehlender Buff; erinnert wird nur an Rollen, Elixiere und Fläschchen, die über Minuten wirken.",
        },
    },
    {
        version = "6.30.55.2",
        date    = "13.10.2026",
        notes   = {
            "|cff7C6CFFSchriftrollen erinnern nur noch, wenn es passt.|r Eine Rolle, deren Wert deiner Klasse nichts bringt, bleibt still; ebenso eine, die auf eine Waffe gehört, die du nicht trägst (kein Stab, keine Rune für den Stab). Hebt schon ein Buff denselben Wert oder liegt die Rune auf der Waffe, gilt sie als aktiv.",
        },
    },
    {
        version = "6.30.55.1",
        date    = "13.10.2026",
        notes   = {
            "|cff7C6CFFNamensplaketten von Elite-Gegnern überlappen nicht mehr.|r Der Drache steht jetzt links neben den Zielpfeilen statt auf ihnen, und die Pfeile halten Abstand zum goldenen Rahmen.",
        },
    },
    {
        version = "6.30.55.0",
        date    = "13.10.2026",
        notes   = {
            "|cff7C6CFFProfil-Import mit Auswahl.|r Nach dem Einfügen hakst du an, was übernommen wird – jeder WeintCodex-Bereich einzeln, Plätze, Layouts, Spieleinstellungen, Tastenbelegung. „Alle“ und „Keine“ inklusive; die Tastenbelegung ist nicht vorgewählt.",
        },
    },
    {
        version = "6.30.54.0",
        date    = "13.10.2026",
        notes   = {
            "|cff7C6CFF/wcui sperre öffnet jetzt immer|r – auch nachdem die Taschen geöffnet waren.",
        },
    },
    {
        version = "6.30.53.0",
        date    = "13.10.2026",
        notes   = {
            "|cff7C6CFFSperr-Bericht heißt jetzt „/wcui sperre“.|r „/wcui taschen“ öffnete weiter die Taschen-Seite im Codex – der Bericht zum Kopieren kommt mit „/wcui sperre“.",
        },
    },
    {
        version = "6.30.52.0",
        date    = "13.10.2026",
        notes   = {
            "|cff7C6CFF„/wcui taschen“ als Bericht zum Kopieren.|r Zeigt die letzten Sperren gegen WeintCodex und alles, was an den Taschenknöpfen und im Spiel als von WeintCodex angefasst gilt – Grundlage, um die Sperre beim Benutzen aus den Taschen zu finden.",
        },
    },
    {
        version = "6.30.51.0",
        date    = "13.10.2026",
        notes   = {
            "|cff7C6CFFGegenstände aus den Taschen benutzen, ohne Sperrmeldung.|r Wer etwa eine Fackel mit „Benutzen“-Zauber aus den WeintCodex-Taschen anklickte, bekam „WeintCodex wurde geblockt“. Die Taschen fassen die Knöpfe des Spiels jetzt so an, dass das Spiel den Klick als seinen eigenen erkennt.",
        },
    },
    {
        version = "6.30.50.0",
        date    = "12.10.2026",
        notes   = {
            "|cff7C6CFFQuestfortschritt rückt nur bei Zielpfeilen zur Seite.|r Ohne Zielpfeile (Ziel hervorheben: Ring) steht die Zahl wieder direkt neben dem Balken.",
        },
    },
    {
        version = "6.30.49.0",
        date    = "12.10.2026",
        notes   = {
            "|cff7C6CFFQuestfortschritt und Zielpfeile überlappen nicht mehr.|r Die Zahl neben der Namensplakette rückt um den Platz der Zielpfeile nach links.",
        },
    },
    {
        version = "6.30.48.0",
        date    = "12.10.2026",
        notes   = {
            "|cff7C6CFFRoter Punkt, wenn Kontrolle nicht wirkt.|r Verwandlung auf einen Untoten, Fesseln auf einen Humanoiden: oben links am Knopf zeigt ein roter Punkt, dass der Zauber beim Ziel nicht greift. Abschaltbar unter Aktionsleisten → Erweitert.",
        },
    },
    {
        version = "6.30.47.0",
        date    = "12.10.2026",
        notes   = {
            "|cff7C6CFFVerlauf mit Gesprächsliste und „Zurück“.|r Im Verlauf stehen links alle Gespräche der letzten 7 Tage – ein Klick zeigt das ganze Gespräch nach Tagen. „Zurück“ verlässt den Verlauf. Die Namen im Verlauf sind wieder richtige Links.",
        },
    },
    {
        version = "6.30.46.0",
        date    = "12.10.2026",
        notes   = {
            "|cff7C6CFFAlte Nachrichten nur noch im Verlauf.|r Liste und Gespräch zeigen nur, was in dieser Sitzung geschrieben wurde. Die letzten 7 Tage stehen hinter dem Knopf „Verlauf“ – ein Klick auf einen Namen dort öffnet das ganze Gespräch.",
        },
    },
    {
        version = "6.30.45.0",
        date    = "12.10.2026",
        notes   = {
            "|cff7C6CFFKnopf „Verlauf“ im Flüster-Messenger.|r Zeigt alle Nachrichten der letzten 7 Tage aller Charaktere nach Zeit, mit „Heute“, „Gestern“ und Datum. Ein Klick auf einen Namen öffnet das Gespräch.",
        },
    },
    {
        version = "6.30.44.0",
        date    = "12.10.2026",
        notes   = {
            "|cff7C6CFFFlüster-Verlauf für das ganze Konto.|r Jeder Charakter sieht auch, was die anderen in den letzten 7 Tagen geflüstert bekommen haben – mit „@Name“ in der Liste und „erhalten mit …“ oben im Gespräch.",
        },
    },
    {
        version = "6.30.43.0",
        date    = "12.10.2026",
        notes   = {
            "|cff7C6CFFDer Flüster-Messenger merkt sich 7 Tage.|r Wer dir geschrieben hat und was, bleibt über das Ausloggen hinaus – je Charakter, in einer eigenen Datei. Ältere Nachrichten tragen das Datum, das Mausrad blättert durch die Liste. Abschaltbar unter „Verlauf 7 Tage behalten“.",
        },
    },
    {
        version = "6.30.42.0",
        date    = "12.10.2026",
        notes   = {
            "|cff7C6CFFDas Klassenbild bleibt dir vorbehalten.|r Beim Betrachten anderer Spieler steht hinter der Figur wieder der Hintergrund des Spiels, passend zu ihrem Volk.",
        },
    },
    {
        version = "6.30.41.0",
        date    = "12.10.2026",
        notes   = {
            "|cff7C6CFFBetrachten trägt nicht mehr deine Klassenfarbe.|r Ein fremder Charakter bekommt das neutrale Gold; seine Klasse zeigen Name und Klassenbild. Die schwarze Fläche über dem Klassenbild ist weg.",
        },
    },
    {
        version = "6.30.40.0",
        date    = "12.10.2026",
        notes   = {
            "|cff7C6CFFBetrachten anderer Spieler im WeintCodex-Design.|r Ohne Metallrahmen, flache Ausrüstungsplätze – und hinter der Figur das Bild ihrer Klasse.",
        },
    },
    {
        version = "6.30.39.0",
        date    = "12.10.2026",
        notes   = {
            "|cff7C6CFFTransmogrifizieren im WeintCodex-Design.|r Ohne Metallrahmen und roten Knöpfe, ruhige Flächen in Gold – und hinter deiner Figur das große Bild deiner Klasse, wie im Charakterfenster.",
        },
    },
    {
        version = "6.30.38.0",
        date    = "12.10.2026",
        notes   = {
            "|cff7C6CFFProfil-Export nimmt jetzt alles mit.|r Neben allen WeintCodex-Einstellungen auch das aktive Layout des Bearbeitungsmodus (auch ein eigenes), die Einstellungen des Spiels (ohne Grafik), die Tastenbelegung und ob die Oberfläche an ist. Ein importiertes Layout kommt als neues Layout dazu, nie über ein bestehendes.",
        },
    },
    {
        version = "6.30.37.0",
        date    = "12.10.2026",
        notes   = {
            "|cff7C6CFFBattle.net oder Flüstern im Spiel – auf einen Blick.|r In der Gesprächsliste steht vor jedem Namen ein blaues „BN“ oder ein rosa „W“, oben im Gespräch „Battle.net“ oder „Flüstern im Spiel“.",
        },
    },
    {
        version = "6.30.36.0",
        date    = "12.10.2026",
        notes   = {
            "|cff7C6CFFZahnrad und Schrift im Flüster-Messenger.|r Das Zahnrad oben im Fenster führt zu seinen Einstellungen. Dort lassen sich Schriftart, Größe und die Farben für fremden Text, eigenen Text und „Du“ einstellen.",
        },
    },
    {
        version = "6.30.35.0",
        date    = "12.10.2026",
        notes   = {
            "|cff7C6CFF„Flüstern“ aus dem Menü schreibt im Messenger.|r Öffnet „/w Name“ oder „Flüstern“ im Rechtsklickmenü den Messenger, liegt die Eingabe gleich dort – nicht mehr zusätzlich unten im Chat.",
        },
    },
    {
        version = "6.30.34.0",
        date    = "12.10.2026",
        notes   = {
            "|cff7C6CFFDer Flüster-Messenger fühlt sich mehr nach Messenger an.|r Schreiben und Enter direkt im Fenster, das Feld bleibt zum Weiterschreiben aktiv. Die Liste zeigt die letzte Nachricht und wann, aufeinanderfolgende Nachrichten stehen als Block, und das Fenster lässt sich unten rechts größer ziehen.",
        },
    },
    {
        version = "6.30.33.0",
        date    = "12.10.2026",
        notes   = {
            "|cff7C6CFFMehr in der Aufschlüsselung.|r Fähigkeiten des Begleiters tragen seinen Namen, der Tooltip einer Fähigkeit zeigt Overkill, Ziele mit Anteil und ob sie vermeidbar oder tödlich war – soweit das Spiel es nennt.",
        },
    },
    {
        version = "6.30.32.0",
        date    = "12.10.2026",
        notes   = {
            "|cff7C6CFFSchadensanzeige direkt verschieben.|r An der Kopfzeile ziehen setzt das Fenster um – ohne Gestaltungsmodus. „Fenster fixieren“ in den Einstellungen hält es fest.",
        },
    },
    {
        version = "6.30.31.0",
        date    = "12.10.2026",
        notes   = {
            "|cff7C6CFFNeu: „/wcui messung“.|r Zeigt nach einem Kampf, welche Zahlen das Spiel der Schadensanzeige überhaupt gibt – Grundlage für kritische Treffer, Trefferzahlen und mehr in der Aufschlüsselung.",
        },
    },
    {
        version = "6.30.30.0",
        date    = "12.10.2026",
        notes   = {
            "|cff7C6CFFKein Lua-Fehler mehr beim Hinweis auf seltene Gegner im Kampf.|r Der Hinweis wird im Kampf nur unsichtbar und verschwindet ganz, sobald der Kampf vorbei ist.",
        },
    },
    {
        version = "6.30.29.0",
        date    = "12.10.2026",
        notes   = {
            "|cff7C6CFF„Einsamer Wolf“ wird jetzt erkannt.|r Das Talent wird über die Talente des Spiels, den Zauber und deine Buffs gesucht – dann schweigt „Begleiter fehlt“. „/wcui wolf“ zeigt, was gefunden wurde.",
        },
    },
    {
        version = "6.30.28.0",
        date    = "12.10.2026",
        notes   = {
            "|cff7C6CFFDie Essens-Erinnerung erkennt mehr Essen.|r Auch Essen, das das Spiel anders einsortiert – etwa Kräutergebackenes Ei oder Essen für mehr Erfahrung – zählt jetzt, sobald sein Tooltip satt macht oder Erfahrung gibt. „/wcui essen“ zeigt, was erkannt wird.",
        },
    },
    {
        version = "6.30.27.0",
        date    = "12.10.2026",
        notes   = {
            "|cff7C6CFFMausrad-Klickzauber nur über den Rahmen.|r Außerhalb des Kampfes zoomt das Mausrad wie gewohnt und zaubert nur über Gruppen- und Einheitenrahmen. Im Kampf wirkt es auf jede Einheit unter der Maus – dort lässt das Spiel keinen Wechsel zu.",
        },
    },
    {
        version = "6.30.26.0",
        date    = "12.10.2026",
        notes   = {
            "|cff7C6CFFKeine Skript-Warnung mehr beim Mausrad-Klickzauber.|r Die Belegung nutzt keinen Skriptbefehl mehr. Dafür zoomt das Mausrad ohne Umschalt, Strg oder Alt die Kamera nicht mehr, solange es belegt ist.",
        },
    },
    {
        version = "6.30.25.0",
        date    = "12.10.2026",
        notes   = {
            "|cff7C6CFFLeisten kommen nach Gesprächen zuverlässig zurück.|r Läuft ein Questgeber weg, schließt sich das Gespräch jetzt selbst und die Oberfläche blendet wieder ein – auch wenn das Spiel das Ende nicht meldet.",
        },
    },
    {
        version = "6.30.24.0",
        date    = "12.10.2026",
        notes   = {
            "|cff7C6CFFKeine Fehlermeldung „forbidden object“ mehr im Chat.|r Beim Einkleiden der Fenster stieß WeintCodex auf geschützte Teile des Spiels – die werden jetzt übergangen.",
        },
    },
    {
        version = "6.30.23.0",
        date    = "12.10.2026",
        notes   = {
            "|cff7C6CFFTooltips für Buffs und Debuffs neben der Minikarte.|r Der Bereich um die Karte fing die Maus ab, sodass Auren dort keinen Tooltip zeigten.",
        },
    },
    {
        version = "6.30.22.0",
        date    = "12.10.2026",
        notes   = {
            "|cff7C6CFFKeine Begleiter-Erinnerung mit „Einsamer Wolf“.|r Wer als Jäger das Talent gelernt hat, lässt den Begleiter absichtlich weg – „Begleiter fehlt“ meldet sich dann nicht mehr. Bestehende Erinnerungen gelten sofort.",
        },
    },
    {
        version = "6.30.21.0",
        date    = "12.10.2026",
        notes   = {
            "|cff7C6CFFKlickzauber auf dem Mausrad.|r Mausrad hoch und runter lassen sich belegen, auch mit Umschalt, Strg oder Alt – einfach über dem Feld „Taste zuweisen“ scrollen. Ohne Einheit unter der Maus zoomt das Rad weiter die Kamera.",
        },
    },
    {
        version = "6.30.20.0",
        date    = "12.10.2026",
        notes   = {
            "|cff7C6CFFDie Kraftleiste lässt sich besser lesen.|r Farbe „Heller“ macht Mana zu einem klaren Hellblau, oder du wählst eine eigene Farbe – und die Höhe steht jetzt direkt daneben statt unter „Erweitert“. Einheitenrahmen → Spieler.",
            "|cff7C6CFF/wcui maus|r nennt, was unter der Maus liegt – hilft, wenn ein Symbol keinen Tooltip zeigt.",
        },
    },
    {
        version = "6.30.19.0",
        date    = "12.10.2026",
        notes   = {
            "|cff7C6CFFKein graues Fragezeichen mehr auf der Minikarte.|r Dort steht ein „?“ nur noch, wenn du die Quest abgeben kannst – grau verwechselt man sonst mit einer Abgabe im Gebäude.",
        },
    },
    {
        version = "6.30.18.0",
        date    = "12.10.2026",
        notes   = {
            "|cff7C6CFFNoch weniger Arbeit im Hintergrund.|r Glitzern prüft dasselbe Objekt nur einmal, der Erfahrungsbalken schaut seltener nach der Maus.",
        },
    },
    {
        version = "6.30.17.0",
        date    = "12.10.2026",
        notes   = {
            "|cff7C6CFFWeintCodex arbeitet sparsamer im Hintergrund.|r Offene Fenster werden seltener nachgestaltet, der Suchwechsel ruht ohne Kräuter- und Bergbau, die Minikarte schreibt Koordinaten und Uhr nur neu, wenn sie sich ändern.",
        },
    },
    {
        version = "6.30.16.0",
        date    = "12.10.2026",
        notes   = {
            "|cff7C6CFFSchiffe, Zeppeline, Trams und Portale auch auf der Minikarte.|r In der Farbe der Fraktion, Maus darauf zeigt, wohin es geht. Abschalten: Komfort → Karte → „Reisen auch auf der Minikarte“.",
        },
    },
    {
        version = "6.30.15.0",
        date    = "12.10.2026",
        notes   = {
            "|cff7C6CFFDas Interaktionssymbol über Objekten sitzt tiefer.|r Es steht jetzt dicht über Briefkasten, Kraut oder Erz statt weit darüber.",
        },
    },
    {
        version = "6.30.14.0",
        date    = "12.10.2026",
        notes   = {
            "|cff7C6CFFDer dunkle Kasten an Briefkästen, Kräutern und anderen Objekten ist weg.|r Es war der leere Lebensbalken der Plakette des Spiels – WeintCodex blendet ihn jetzt aus und lässt nur das Interaktionssymbol stehen.",
        },
    },
    {
        version = "6.30.13.0",
        date    = "12.10.2026",
        notes   = {
            "|cff7C6CFFDer Vergleich mit deiner Ausrüstung erscheint im Gespräch.|r Fährst du über eine Belohnung, steht daneben wieder, was du gerade trägst – auch wenn die Oberfläche im Gespräch ausgeblendet ist.",
        },
    },
    {
        version = "6.30.12.0",
        date    = "12.10.2026",
        notes   = {
            "|cff7C6CFFDie Bedrohungsleiste deines Ziels färbt sich.|r Das Spiel verriet die Bedrohung über die Plakette nur verschlüsselt, über dein Ziel aber offen – WeintCodex fragt jetzt dort. Für Ziel, Fokus und den Gegner unter der Maus.",
        },
    },
    {
        version = "6.30.11.0",
        date    = "12.10.2026",
        notes   = {
            "|cff7C6CFFBedrohungsleiste: Farbe auch über den Balken selbst.|r Dazu nennt /wcui prüfen im Kampf, welche Farbe die Leiste am Ziel gerade hat und welche sie haben sollte.",
        },
    },
    {
        version = "6.30.10.0",
        date    = "12.10.2026",
        notes   = {
            "|cff7C6CFFDie Bedrohungsleiste färbt sich im Kampf.|r Sie blieb grau, wenn das Spiel die Prozentzahl im Kampf verbirgt – jetzt färbt sie das Spiel selbst nach deinen Schwellen grün, gelb und rot.",
        },
    },
    {
        version = "6.30.9.0",
        date    = "12.10.2026",
        notes   = {
            "|cff7C6CFF/wcui prüfen nennt Glitzern und Questhilfe.|r Stell dich vor ein Kraut und prüfe: der Bericht zeigt, was WeintCodex über das Objekt vor dir weiß – daran lässt sich sehen, warum es nicht glitzert.",
        },
    },
    {
        version = "6.30.8.0",
        date    = "12.10.2026",
        notes   = {
            "|cff7C6CFFKein dunkler Kasten mehr am Briefkasten.|r Objekte, die dem Spiel ein Leben nennen, bekamen noch eine Namensplakette – jetzt erkennt WeintCodex sie an ihrer Kennung.",
        },
    },
    {
        version = "6.30.7.0",
        date    = "12.10.2026",
        notes   = {
            "|cff7C6CFFDie Questhilfe auch auf der Minikarte.|r Dieselben Symbole und Filter wie auf der Weltkarte, solange sie in Reichweite der Minikarte liegen – auch mit gedrehter Minikarte. Abschalten: Komfort → Questhilfe → „Auch auf der Minikarte“.",
            "|cff7C6CFFMehr Fundorte für Questziele.|r Je Ziel und Gebiet zeigt die Karte jetzt bis zu 25 Stellen statt 10.",
        },
    },
    {
        version = "6.30.6.0",
        date    = "12.10.2026",
        notes   = {
            "|cff7C6CFFDie Questhilfe nutzt die Questsymbole des Spiels.|r Gelbes „!“ und „?“ wie beim Questgeber, grau, wenn eine Quest zu leicht oder noch nicht fertig ist. Ziele zeigen, was zu tun ist: Schwert zum Besiegen, Beutel für Beute, Zahnrad für Objekte.",
        },
    },
    {
        version = "6.30.5.0",
        date    = "12.10.2026",
        notes   = {
            "|cff7C6CFFWeintCodex braucht deutlich weniger Speicher.|r Der Bestand der Questhilfe belegte über 7 MB – jetzt knapp 2, gelesen wird nur, was die Karte gerade zeigt.",
        },
    },
    {
        version = "6.30.4.0",
        date    = "12.10.2026",
        notes   = {
            "|cff7C6CFFDie Symbole der Questhilfe sehen aus wie die des Spiels.|r Goldener Kreis mit dunklem „!“ oder „?“ für das, was jetzt geht, grauer Kreis für zu leichte oder noch nicht fertige Quests.",
        },
    },
    {
        version = "6.30.3.0",
        date    = "12.10.2026",
        notes   = {
            "|cff7C6CFFKeine doppelten Koordinaten mehr auf der Weltkarte.|r Zeigt die Karte schon eigene Koordinaten, blendet WeintCodex seine Zeile aus.",
        },
    },
    {
        version = "6.30.2.0",
        date    = "12.10.2026",
        notes   = {
            "|cff7C6CFFDie Filterleiste der Questhilfe verdeckt nichts mehr.|r Sie hängt jetzt unter dem Kartenfenster statt oben links auf der Karte, wo sie deinen Pfeil zudeckte.",
        },
    },
    {
        version = "6.30.1.0",
        date    = "12.10.2026",
        notes   = {
            "|cff7C6CFFDie Questhilfe zeigt nur noch die Ziele der Quest, die du gerade machst.|r Wählen: Klick auf ihr „?“ auf der Karte oder auf die Quest im Questlog – der Questpfeil folgt mit. Rechtsklick löst die Wahl. Alle Ziele auf einmal gibt es weiter über „Alle Ziele“.",
        },
    },
    {
        version = "6.30.0.0",
        date    = "12.10.2026",
        notes   = {
            "|cff7C6CFFQuesthilfe auf der Weltkarte.|r Ein „!“ zeigt, wo neue Quests auf dich warten, ein „?“, wo du abgibst – gold, wenn die Quest fertig ist –, blaue Punkte, wo die Ziele deiner Quests sind. Oben links auf der Karte schaltest du, was du sehen willst. Einschalten: Komfort → Questhilfe.",
        },
    },
    {
        version = "6.29.30.0",
        date    = "12.10.2026",
        notes   = {
            "|cff7C6CFFElite-Gegner fallen auf.|r Ihre Plakette trägt einen goldenen Rahmen und den Drachen des Spiels, Bosse einen roten – auch im Kampf. Abschalten: Namensplaketten → Stufe.",
            "|cff7C6CFFDie Oberfläche bleibt nach Questgebern mit mehreren Quests sichtbar.|r Begann das nächste Gespräch, während sie noch zurückblendete, blieb sie danach fast unsichtbar.",
        },
    },
    {
        version = "6.29.29.0",
        date    = "12.10.2026",
        notes   = {
            "|cff7C6CFFKräuter und Erz glitzern zuverlässiger.|r Erkennt WeintCodex ein Kraut oder eine Erzader nicht am Mauszeiger des Spiels, liest es jetzt den Tooltip (Kräuterkunde/Bergbau). Was dabei geschieht, zeigt /wcui prüfen in der Zeile „Glitzern“.",
        },
    },
    {
        version = "6.29.28.0",
        date    = "12.10.2026",
        notes   = {
            "|cff7C6CFFTotems aus dem Kampf erscheinen unter dem Spielerrahmen.|r Im Kampf gestellte Totems fehlten dort und ließen sich nicht per Rechtsklick entfernen. Im Kampf läuft die Restzeit als Spirale statt als Zahl.",
        },
    },
    {
        version = "6.29.27.0",
        date    = "12.10.2026",
        notes   = {
            "|cff7C6CFFDie Knöpfe an der Minikarte stehen, wo du willst.|r Aufspüren, Kalender, Post und Schwierigkeit lassen sich links, rechts, über oder unter die Karte setzen: Minikarte → Allgemein → „Seite der Knöpfe“.",
        },
    },
    {
        version = "6.29.26.0",
        date    = "11.10.2026",
        notes   = {
            "|cff7C6CFFDie Oberfläche behält deine Größe.|r Beim Einrichten stellte WeintCodex die Skalierung des Spiels fest auf 1 – auf 1440p und 4K wurden Leisten und Rahmen dadurch fast doppelt so groß. Jetzt bleibt die Skalierung, die du im Spiel hast. Wer das feste Raster will: Allgemein → Bildschirm → „Fest auf 1“.",
        },
    },
    {
        version = "6.29.25.0",
        date    = "11.10.2026",
        notes   = {
            "|cff7C6CFFNach der Installation kommt zuerst der Willkommensbildschirm.|r Bisher öffnete sich die Einführung im Codex und der Willkommensbildschirm wartete dahinter – oft für immer. Die Einführung folgt jetzt beim nächsten Einloggen.",
            "|cff7C6CFFDer Codex passt immer auf den Bildschirm.|r Ist er größer als das Bild, wird er verkleinert, statt über den Rand zu ragen.",
        },
    },
    {
        version = "6.29.24.0",
        date    = "11.10.2026",
        notes   = {
            "|cff7C6CFFKein dunkler Kasten mehr unter Zahnrad und Sprechblase.|r An Tischen, Laternen und anderen Objekten in der Nähe zeigt das Spiel jetzt seine Hinweise – WeintCodex legte dort eine leere Plakette darunter. Objekte bekommen keine mehr.",
        },
    },
    {
        version = "6.29.23.0",
        date    = "11.10.2026",
        notes   = {
            "|cff7C6CFFDie Gruppe zeigt, wer führt.|r Eine Krone oben links am Rahmen des Gruppenleiters – jetzt auch an den Gruppenrahmen des Spiels im WeintCodex-Stil, nicht nur an den eigenen Kacheln. Abschaltbar unter Gruppenrahmen.",
        },
    },
    {
        version = "6.29.22.0",
        date    = "11.10.2026",
        notes   = {
            "|cff7C6CFFNamensplaketten lassen sich auch ohne Oberfläche abschalten.|r Ohne die Oberfläche von WeintCodex heißt der Schalter bei den Namensplaketten „Plaketten an“ – aus heißt: gar keine Plaketten, auch nicht die des Spiels. Mit V holst du sie jederzeit zurück.",
        },
    },
    {
        version = "6.29.21.0",
        date    = "11.10.2026",
        notes   = {
            "|cff7C6CFFTaschen frei verschieben.|r Das Taschenfenster ziehst du jetzt jederzeit mit der Maus an seiner Fläche – ohne Gestaltungsmodus. Der Platz bleibt.",
            "|cff7C6CFFQuestfortschritt neben der Plakette.|r Die Zahl („8/10“) steht jetzt links neben dem Balken und liegt nicht mehr über dem Namen.",
        },
    },
    {
        version = "6.29.20.0",
        date    = "11.10.2026",
        notes   = {
            "|cff7C6CFFNamensplaketten ganz aus.|r Wer die Plaketten von WeintCodex abschaltet, sah bisher die des Spiels. Unter Namensplaketten → Allgemein → „Plaketten des Spiels: Ausblenden“ sind dann gar keine mehr da; mit V holst du sie jederzeit zurück.",
        },
    },
    {
        version = "6.29.19.0",
        date    = "11.10.2026",
        notes   = {
            "|cff7C6CFFKombopunkte beim Schurken zeigen wieder etwas.|r WeintCodex liest sie jetzt auf beiden Wegen des Spiels und merkt selbst, welcher stimmt. Zeigt es trotzdem nichts: /wcui kombo nennt, was das Spiel meldet.",
        },
    },
    {
        version = "6.29.18.0",
        date    = "11.10.2026",
        notes   = {
            "|cff7C6CFFGruppenwerkzeuge klappen am oberen und unteren Rand senkrecht.|r Oben öffnet das Menü nach unten, unten nach oben – der Griff liegt dann quer unter bzw. über der Fläche. An der Seite bleibt es wie gehabt.",
        },
    },
    {
        version = "6.29.17.0",
        date    = "11.10.2026",
        notes   = {
            "|cff7C6CFFGriff und Pfeil der Gruppenwerkzeuge folgen beim Ziehen.|r Im Gestaltungsmodus wandert der Griff schon beim Ziehen auf die Seite zur Bildschirmmitte, und nach dem Loslassen am Rand richtet sich das Menü sofort neu aus.",
        },
    },
    {
        version = "6.29.16.0",
        date    = "11.10.2026",
        notes   = {
            "|cff7C6CFFBodenmarkierungen einzeln entfernen.|r Rechtsklick auf ein Zeichen unter „Boden markieren“ nimmt genau dieses weg. „Alle entfernen“ räumt jetzt wirklich alle acht ab.",
        },
    },
    {
        version = "6.29.15.0",
        date    = "11.10.2026",
        notes   = {
            "|cff7C6CFFGruppenwerkzeuge klappen zur Bildschirmmitte auf.|r Am unteren Rand nach oben, am rechten Rand nach links, oben nach unten – der Griff sitzt immer auf der Seite zur Mitte.",
        },
    },
    {
        version = "6.29.14.0",
        date    = "11.10.2026",
        notes   = {
            "|cff7C6CFFGruppenwerkzeuge werden beim Drüberfahren wieder voll sichtbar.|r Die Fläche blieb blass, auch mit der Maus darauf.",
        },
    },
    {
        version = "6.29.13.0",
        date    = "11.10.2026",
        notes   = {
            "|cff7C6CFFEigene Gruppenwerkzeuge statt des Menüs links.|r In der Gruppe: Ziel und Boden markieren, Bereitschaftscheck, Rollenabfrage, Countdown, Pings beschränken, Gruppe verlassen. Blass, bis die Maus darüber ist, mit dem Griff am Rand ein- und ausklappbar, im Gestaltungsmodus frei verschiebbar. Einstellungen: Gruppenrahmen → Gruppenwerkzeuge.",
        },
    },
    {
        version = "6.29.12.0",
        date    = "11.10.2026",
        notes   = {
            "|cff7C6CFFDebuffs am Zielrahmen auch darunter.|r Unter Einheitenrahmen → Ziel → Auren im Einzelnen wählst du „Über dem Rahmen“ oder „Unter dem Rahmen“ – darunter stehen sie unter dem Platz des Zauberbalkens, links- oder rechtsbündig.",
        },
    },
    {
        version = "6.29.11.0",
        date    = "11.10.2026",
        notes   = {
            "|cff7C6CFFKlickzauber auf Tastatur-Tasten bleiben nach dem Einloggen.|r Die Seitentasten mehrtastiger Mäuse wirkten bis zum nächsten Einloggen – danach war die Belegung weg. Jetzt legt WeintCodex sie neu, sobald das Spiel seine Tastenbelegung geladen hat, und vor der von Leisten-Addons.",
            "|cff7C6CFFIm Gestaltungsmodus den Bearbeitungsmodus des Spiels dazuschalten.|r „Rahmen des Spiels: an“ oben in der Leiste öffnet ihn zusätzlich – du siehst, wo Blizzards Rahmen liegen, und verschiebst beides nebeneinander. Noch ein Klick schließt ihn wieder.",
        },
    },
    {
        version = "6.29.10.0",
        date    = "11.10.2026",
        notes   = {
            "|cff7C6CFFBreitbild wird unterstützt.|r Auf 21:9 und 32:9 rücken Chat, Minikarte, Questliste, Schadensanzeige und Taschen in einen Bereich in der Mitte, statt am äußersten Rand zu kleben. Einstellbar unter Allgemein: 16:9, 21:9 oder bis an den Rand. Das Seitenverhältnis erkennt WeintCodex selbst; ändert sich der Bildschirm, sagt es Bescheid, dass /wcui einrichten Chat, Minikarte und Questliste zurechtrückt.",
        },
    },
    {
        version = "6.29.9.0",
        date    = "11.10.2026",
        notes   = {
            "|cff7C6CFFKlickzauber nehmen jede Maustaste.|r Auf der Seite Klickzauber die Maus auf „Taste zuweisen“, Taste drücken – Maustasten bis 12 wirken direkt auf dem Rahmen. Schickt deine Maus Tastatur-Tasten (Corsair Scimitar, Razer Naga), wirkt die Taste auf die Einheit unter der Maus und tut sonst nichts mehr, solange sie belegt ist.",
            "|cff7C6CFFDer Chat geht bis in die Ecke.|r Oben links und rechts lässt er sich jetzt bündig an den Bildschirmrand schieben.",
        },
    },
    {
        version = "6.29.8.0",
        date    = "11.10.2026",
        notes   = {
            "|cff7C6CFFBeute und Würfeln lassen sich verschieben.|r Das Beutefenster und die Würfelfenster in der Gruppe ziehst du mit der Maus, der Platz bleibt. Umschalt + Rechtsklick setzt sie zurück.",
            "|cff7C6CFFDie Bedrohungsleiste zeigt Farbe nach Prozent.|r Ab 50 % grün, ab 75 % gelb, ab 90 % rot, mit Aggro immer rot – statt „Aggro: Du“. Die Grenzen sind einstellbar.",
        },
    },
    {
        version = "6.29.7.0",
        date    = "11.10.2026",
        notes   = {
            "|cff7C6CFFDas Addon ist ein gutes Drittel kleiner.|r Boss- und Klassenbilder liegen jetzt in der Größe vor, in der das Fenster sie zeigt – zu sehen ist derselbe Ausschnitt in derselben Schärfe, nur der Download ist kleiner.",
        },
    },
    {
        version = "6.29.6.0",
        date    = "11.10.2026",
        notes   = {
            "|cff7C6CFFBossbilder auch in Excavation Site.|r Die Bosskarten blieben flach und ohne Bild, weil die Reihenfolge der Bosse unbekannt ist. Gibt es ein Bild, ist die Karte jetzt hoch und zeigt es.",
        },
    },
    {
        version = "6.29.5.0",
        date    = "11.10.2026",
        notes   = {
            "|cff7C6CFFRazorfen Kraul hat jetzt Bilder.|r Ein Banner oben auf der Seite und ein Bild für jeden der sechs Bosse.",
        },
    },
    {
        version = "6.29.4.0",
        date    = "11.10.2026",
        notes   = {
            "|cff7C6CFFFünf weitere Dungeons mit Bildern.|r Blackfathom Deeps, Das Verlies, City of Dalaran, Scharlachrotes Kloster (Friedhof) und Gnomeregan haben jetzt ein Banner und Bilder ihrer Bosse.",
        },
    },
    {
        version = "6.29.3.0",
        date    = "11.10.2026",
        notes   = {
            "|cff7C6CFFExcavation Site hat jetzt Bilder.|r Ein Banner oben auf der Seite und ein eigenes Bild für jeden der drei Bosse.",
        },
    },
    {
        version = "6.29.2.0",
        date    = "11.10.2026",
        notes   = {
            "|cff7C6CFFRechtsklick auf einen Namen im Messenger.|r Er öffnet dasselbe Menü wie im Chat – einladen, anflüstern, als Freund hinzufügen, melden. Das geht auf dem Namen im Verlauf und auf dem Gespräch in der Liste links.",
        },
    },
    {
        version = "6.29.1.0",
        date    = "11.10.2026",
        notes   = {
            "|cff7C6CFF„Auf der Karte zeigen“ zeigt den Abgabeort.|r Die Startseite öffnet die Weltkarte jetzt dort, wo die fertige Quest abgegeben wird, mit Marke – und der Codex geht dafür zu, statt die Karte zu verdecken.",
        },
    },
    {
        version = "6.29.0.1",
        date    = "11.10.2026",
        notes   = {
            "|cff7C6CFFGlitzern im Willkommens-Assistenten.|r Im Schritt „Welt und Karte“ lässt es sich gleich beim ersten Einloggen wählen. Dafür stehen „Ganze Karte“ und „Stufen und Sammelberufe“ dort jetzt in einer Zeile.",
        },
    },
    {
        version = "6.29.0.0",
        date    = "11.10.2026",
        notes   = {
            "|cff7C6CFFGlitzern.|r Neue Komfortseite: Questgegenstände glitzern immer – auch nach einem Wechsel der Grafikstufe –, und über dem nächsten Kraut oder der nächsten Erzader funkelt es golden (grau, wenn du es noch nicht sammeln kannst). Beides einzeln einschaltbar.",
        },
    },
    {
        version = "6.28.1.0",
        date    = "11.10.2026",
        notes   = {
            "|cff7C6CFFLehrer auf neuem Stand.|r Was der Lehrer lehrt und kostet, ist neu abgeglichen – Tigerfuror und andere Zauber, die es beim Lehrer nicht mehr gibt, stehen nicht mehr in „Als Nächstes“, und viele Preise stimmen jetzt.",
            "|cff7C6CFF„Abgabebereit“ zählt nur fertige Quests.|r Die Startseite meldete Quests als abgabebereit, die es nicht waren. Jetzt zählt eine Quest erst, wenn alle Ziele erfüllt sind.",
            "|cff7C6CFFCity of Dalaran mit acht Bossen.|r Arcanic Enigma statt Mana Elemental, Mana Wraith ist kein Boss mehr – dazu Beute für die Bosse von Dalaran und neue Daten zu Quests, Rezepten und seltenen Gegnern.",
        },
    },
    {
        version = "6.28.0.1",
        date    = "11.10.2026",
        notes   = {
            "|cff7C6CFFExport und Import liegen vorn.|r Das Fenster mit dem Text erscheint jetzt über den Einstellungen statt dahinter – das gilt auch für die Berichte aus /wcui prüfen.",
        },
    },
    {
        version = "6.28.0.0",
        date    = "11.10.2026",
        notes   = {
            "|cff7C6CFFProfil exportieren und importieren.|r Unter Allgemein → Profile → „Sichern und teilen“ wird dein Profil zu einem Text: alle Einstellungen, die Plätze der Rahmen und das Layout „WeintCodex“. Zum Sichern ablegen oder mit anderen teilen – eingefügt ersetzt er das gewählte Profil nach Rückfrage.",
        },
    },
    {
        version = "6.27.4.0",
        date    = "11.10.2026",
        notes   = {
            "|cff7C6CFFAuktionspreise mit Münzen.|r Im Tooltip stehen Gold, Silber und Kupfer jetzt als Münzen wie beim Verkaufspreis – keine G, S, K mehr.",
            "|cff7C6CFFWeniger Text im Tooltip.|r Keine Stückzahl mehr; eine Zeile zum Alter nur, wenn der Preis nicht von heute ist.",
        },
    },
    {
        version = "6.27.3.0",
        date    = "11.10.2026",
        notes   = {
            "|cff7C6CFFErinnerungen in Größe und Deckkraft einstellbar.|r Unter Erinnerungen → Anzeige → Aussehen: „Größe der Erinnerungen“ (50–250 %) und „Deckkraft“ für Erinnerungen, Buffs/Procs und Abklingzeiten.",
            "|cff7C6CFFRuhe in Stadt und Gasthaus.|r Mit „An ruhigen Orten ausblenden“ zeigen die Erinnerungen dort nichts – kein Hinweis, kein Symbol.",
        },
    },
    {
        version = "6.27.2.1",
        date    = "11.10.2026",
        notes   = {
            "|cff7C6CFF„Raus da“ schweigt bei eigenen Zaubern.|r Wer mit Lebenslinie seinen Dämon heilt (oder einen anderen Zauber wirkt, der eigenes Leben kostet), bekommt außerhalb des Kampfes keinen Dauerton mehr.",
            "|cff7C6CFFWasserschild zählt.|r Die Erinnerung des Schamanen nimmt Blitzschlagschild oder Wasserschild – egal welches du trägst.",
            "|cff7C6CFFTotems per Rechtsklick entfernen – zweiter Anlauf.|r Die Totemleiste unter dem Spielerrahmen entsteht jetzt zuverlässig und reagiert auf den Rechtsklick. /wcui prüfen zeigt unter „Totems“, ob sie gebaut ist.",
        },
    },
    {
        version = "6.27.2.0",
        date    = "10.10.2026",
        notes   = {
            "|cff7C6CFFGruppe und Schlachtzug waagerecht oder senkrecht.|r Unter Gruppenrahmen → Gruppe „Nebeneinander“ und → Schlachtzug „Gruppen nebeneinander“. Gilt jetzt auch für die Rahmen des Spiels, nicht nur für die eigenen Kacheln.",
        },
    },
    {
        version = "6.27.1.0",
        date    = "10.10.2026",
        notes   = {
            "|cff7C6CFFDie Bedrohungsleiste in vier Farben.|r Grau: hervorragend. Grün: geht noch. Gelb: Achtung, kurz vor der Aggro. Rot: du hast sie. Ab wann grün und gelb gelten, stellst du bei den Plaketten ein.",
        },
    },
    {
        version = "6.27.0.7",
        date    = "10.10.2026",
        notes   = {
            "|cff7C6CFFDas Flüstern-Symbol sitzt an der Minikarte.|r Unten rechts in der Karte statt irgendwo am Bildschirmrand. Ziehen verschiebt es wie bisher – dein neuer Platz bleibt.",
        },
    },
    {
        version = "6.27.0.6",
        date    = "10.10.2026",
        notes   = {
            "|cff7C6CFFTotems am Spielerrahmen.|r Als Schamane stehen deine gestellten Totems mit Restzeit unter dem Rahmen – Rechtsklick entfernt eins, wie im Spiel.",
            "|cff7C6CFFGrößere Debuffs auf den Plaketten.|r Gifte, Blutungen und Co. sind ab Werk deutlich größer und lassen sich bis zur zweieinhalbfachen Größe einstellen.",
        },
    },
    {
        version = "6.27.0.5",
        date    = "10.10.2026",
        notes   = {
            "|cff7C6CFFDer Waffenbuff des Schamanen wird erkannt.|r Ist Felsbeißer oder Flammenzunge auf der Waffe, bleibt die Erinnerung still. Falls nicht: /wcui prüfen zeigt unter „Waffe“, was das Spiel meldet.",
        },
    },
    {
        version = "6.27.0.4",
        date    = "10.10.2026",
        notes   = {
            "|cff7C6CFFBelohnungen im Gespräch mit Vergleich.|r Fährst du über einen Gegenstand zur Wahl, steht wieder dein angelegter daneben – wie im Spiel.",
            "|cff7C6CFFSchamanen werden an ihren Waffenbuff erinnert.|r Statt „ohne Verzauberung“ steht da „Waffe der Flammenzunge oder Waffe des Felsbeißers fehlt“ – nur, was du gelernt hast.",
        },
    },
    {
        version = "6.27.0.3",
        date    = "10.10.2026",
        notes   = {
            "|cff7C6CFFRechtsklick auf die Minikarte ohne Ping.|r Er öffnet nur noch die Weltkarte – der Linksklick pingt wie gewohnt.",
        },
    },
    {
        version = "6.27.0.2",
        date    = "10.10.2026",
        notes   = {
            "|cff7C6CFFDie Erinnerung ans Essen schreibt dir nichts mehr vor.|r Sie sagt nur noch „Nicht satt – Essen mit Erfahrungsbuff in der Tasche“ und wie viele Sorten du dabeihast – welches du isst, entscheidest du.",
            "|cff7C6CFFJeder Erfahrungsbuff zählt.|r Ob Fleisch, Suppe oder etwas anderes: gibt ein Buff auf dir laut seiner Beschreibung Erfahrung, bleibt die Erinnerung still.",
        },
    },
    {
        version = "6.27.0.1",
        date    = "10.10.2026",
        notes   = {
            "|cff7C6CFFDie Erinnerung ans Essen kennt „Satt“.|r So heißt der Essensbuff auf Forever – ist er auf dir, bleibt die Erinnerung still.",
        },
    },
    {
        version = "6.27.0.0",
        date    = "10.10.2026",
        notes   = {
            "|cff7C6CFF„Raus da“ lässt dich beim Leveln in Ruhe.|r Neue Unterpunkte: im Kampf, außerhalb des Kampfes, wo (überall, in Gruppe, in Dungeons) – und von Haus aus kein Ton mehr, solange Gift, Krankheit oder Fluch auf dir liegt. Aus einem Dot kann man nicht herausgehen.",
            "|cff7C6CFFSeltene Gegner per Klick ins Ziel.|r Ein Klick auf den Hinweis nimmt ihn ins Ziel und setzt auf Wunsch gleich einen Totenkopf. Ganz von selbst lässt das Spiel Addons kein Ziel wählen.",
            "|cff7C6CFFElite und Seltene auf einen Blick.|r Ziel- und Fokusrahmen tragen ein Schild „Elite“, „Selten“, „Seltene Elite“ oder „Boss“, der Rand in derselben Farbe.",
            "|cff7C6CFFErinnerung ans Essen.|r Liegt Essen mit „Wohlgenährt“ oder Erfahrungsbuff in der Tasche und der Buff fehlt, erinnern die Erinnerungen daran – Erfahrungsessen nur beim Leveln. Auf Wunsch auch Elixiere, Fläschchen und Rollen.",
            "|cff7C6CFFRechtsklick auf die Minikarte öffnet die Weltkarte.|r Abschaltbar unter Komfort → Karte.",
        },
    },
    {
        version = "6.26.20.0",
        date    = "10.10.2026",
        notes   = {
            "|cff7C6CFFDas Anfangsvideo läuft wieder.|r „Filmsequenzen überspringen“ lässt das Video eines neuen Charakters (Stufe 1) immer laufen und überspringt erst danach.",
        },
    },
    {
        version = "6.26.19.0",
        date    = "10.10.2026",
        notes   = {
            "|cff7C6CFFTaschen einzeln anzeigen.|r Unter Taschen → „Taschen einzeln“: jede Tasche bleibt im selben Fenster, aber als eigener Block mit Namen und „frei von Plätzen“ – Köcher, Munitions- und Seelentaschen auf einen Blick. Ist eine Tasche voll, steht die Zeile in Warnfarbe.",
        },
    },
    {
        version = "6.26.18.1",
        date    = "10.10.2026",
        notes   = {
            "|cff7C6CFFDein eigenes Layout bleibt aktiv.|r WeintCodex schaltet das Layout im Bearbeitungsmodus höchstens einmal je Charakter um. Wählst du danach ein eigenes, bleibt es – auch nach einem Charakterwechsel oder Neustart.",
        },
    },
    {
        version = "6.26.18.0",
        date    = "10.10.2026",
        notes   = {
            "|cff7C6CFFKein Einrichten-Fenster mehr bei jedem Einloggen.|r Gibt es das Layout „WeintCodex“ schon, schaltet WeintCodex es beim Charakter still aktiv – ohne es neu zu bauen, deine Änderungen darin bleiben. Gefragt wird höchstens einmal je Charakter, auch nach „Später“; danach geht es nur noch über /wcui einrichten.",
            "|cff7C6CFFEinrichten in zwei Schritten.|r Das Fenster sagt in drei Sätzen, was passiert: „Einrichten“, dann „Jetzt neu laden“.",
            "|cff7C6CFFWeintCodex prüft danach selbst.|r Nach dem Neuladen siehst du, ob alles steht – und wenn nicht, was zu tun ist, mit dem passenden Knopf („Noch einmal einrichten“ oder „Gestaltungsmodus“).",
        },
    },
    {
        version = "6.26.17.0",
        date    = "10.10.2026",
        notes   = {
            "|cff7C6CFFJeder Charakter bekommt die fertige Anordnung.|r Wählst du im Willkommen die Oberfläche, richtet WeintCodex das Layout jetzt auch dann ein, wenn ein anderer Charakter es schon angelegt hat – vorher blieb ein neuer Charakter auf der Vorlage des Spiels, und die Rahmen lagen übereinander.",
        },
    },
    {
        version = "6.26.16.0",
        date    = "10.10.2026",
        notes   = {
            "|cff7C6CFFRechtsklick öffnet die Einstellungen.|r Im Gestaltungsmodus führt ein Rechtsklick auf einen Rahmen direkt zu seiner Einstellungsseite. Zurück an den Standardplatz geht jetzt mit Umschalt+Rechtsklick.",
        },
    },
    {
        version = "6.26.15.0",
        date    = "10.10.2026",
        notes   = {
            "|cff7C6CFFKoordinaten im Gestaltungsmodus.|r Unter der Leiste stehen X und Y des gewählten Rahmens – sie laufen beim Ziehen mit, und du kannst sie eintippen (Enter übernimmt).",
            "|cff7C6CFFRahmen rasten aneinander ein.|r Schiebst du einen Rahmen nah an einen anderen oder an den Bildschirmrand, springt er bündig oder mit kleinem Abstand daneben. „Einrasten“ in der Leiste schaltet das ab.",
        },
    },
    {
        version = "6.26.14.0",
        date    = "10.10.2026",
        notes   = {
            "|cff7C6CFFGleiches Bild auf 1080p, 1440p und 4K.|r Die Einrichtung der Oberfläche stellt jetzt auch die UI-Skalierung ein, damit alles dort steht, wofür es entworfen ist. Schaltest du die Oberfläche aus, gilt wieder deine Skalierung.",
            "|cff7C6CFFSchon eingerichtet und etwas steht schief?|r Einmal /wcui einrichten, dann neu laden. „/wcui einrichten prüfen“ nennt Bildschirm und Größe der Oberfläche.",
        },
    },
    {
        version = "6.26.13.0",
        date    = "10.10.2026",
        notes   = {
            "|cff7C6CFFErinnerungen kennen jetzt die Buffs deiner Klasse.|r Magier: Arkane Intelligenz und Rüstung. Priester: Seelenstärke und Inneres Feuer. Druide: Mal der Wildnis. Paladin: Segen und Aura. Hexenmeister: Dämonenhaut/-rüstung. Jäger: Aspekt. Schamane: Blitzschlagschild. Erinnert wird nur an Gelerntes.",
            "|cff7C6CFFSchon eigene Regeln angelegt?|r Dann holt „Für meine Klasse“ unter Erinnerungen die neuen Vorschläge dazu – ohne deine Regeln anzufassen.",
        },
    },
    {
        version = "6.26.12.0",
        date    = "10.10.2026",
        notes   = {
            "|cff7C6CFFAuktionspreise teilen von Haus aus.|r Mit Auktionspreisen an sind jetzt auch „Mit der Gilde teilen“ und „Preise von anderen Auktionshaus-Addons übernehmen“ an. Beides lässt sich im Komfort unter Auktion abschalten; eigene Einstellungen bleiben.",
        },
    },
    {
        version = "6.26.11.1",
        date    = "10.10.2026",
        notes   = {
            "|cff7C6CFFZurück aus den Optionen des Spiels.|r Schließt du die Optionen nach „Leiste hinzufügen“, öffnen sich die Einstellungen der Oberfläche wieder.",
        },
    },
    {
        version = "6.26.11.0",
        date    = "10.10.2026",
        notes   = {
            "|cff7C6CFFLeisten hinzufügen mit einem Klick.|r Unter Aktionsleisten → Leisten führt ein Knopf direkt in die Optionen des Spiels zu den Aktionsleisten; schließt du sie, bist du wieder in den Einstellungen der Oberfläche.",
        },
    },
    {
        version = "6.26.10.1",
        date    = "10.10.2026",
        notes   = {
            "|cff7C6CFFLeertaste zeigt den ganzen Text.|r Drückst du beim Questgeber die Leertaste, während der Text noch einläuft, steht er sofort vollständig da, statt stehen zu bleiben.",
        },
    },
    {
        version = "6.26.10.0",
        date    = "10.10.2026",
        notes   = {
            "|cff7C6CFFNeue Zauber beim Lehrer zeigen eine Zahl.|r Am Addon-Knopf neben der Minikarte und am Symbol von WeintCodex steht, wie viele Zauber du gerade lernen kannst.",
            "|cff7C6CFFDas Flüster-Symbol sitzt neben der Minikarte.|r Von Haus aus über dem Addon-Knopf; wer es verschoben hat, behält seinen Platz.",
            "|cff7C6CFFDie Abklingzeit-Einstellungen in Gold.|r Rahmen, Leder und Seitenreiter des Spiels sind weg, die Gruppen haben dunkle Kopfzeilen.",
        },
    },
    {
        version = "6.26.9.4",
        date    = "10.10.2026",
        notes   = {
            "|cff7C6CFFDie Profilfrage kommt bei jedem neuen Charakter.|r Direkt nach dem Willkommen fragt WeintCodex, ob der Charakter ein eigenes Profil bekommt – auch ohne die Oberfläche. Wer nach dem Willkommen neu lädt, wird danach gefragt.",
        },
    },
    {
        version = "6.26.9.3",
        date    = "10.10.2026",
        notes   = {
            "|cff7C6CFFWeiche Übergänge beim Rubrikwechsel.|r Im Codex und im Menü der Oberfläche blendet jede neue Seite sanft ein, statt hart umzuspringen.",
        },
    },
    {
        version = "6.26.9.2",
        date    = "10.10.2026",
        notes   = {
            "|cff7C6CFFDas Menü der Oberfläche blendet jetzt auch weich ein.|r Bisher ging nur das Ausblenden.",
            "|cff7C6CFFNoch größerer Auftritt.|r Das Logo im Gestaltungsmodus ist größer und schwebt langsamer an seinen Platz.",
        },
    },
    {
        version = "6.26.9.1",
        date    = "10.10.2026",
        notes   = {
            "|cff7C6CFFGrößerer Auftritt.|r Das Logo beim Betreten des Gestaltungsmodus ist größer und schwebt gemächlicher an die Leiste.",
            "|cff7C6CFFCodex und Einstellungen blenden weich auf und zu.|r Jedes Öffnen blendet ein, Schließen über das Kreuz, den Befehl oder den Minikartenknopf blendet aus. Esc schließt weiter sofort.",
        },
    },
    {
        version = "6.26.9.0",
        date    = "10.10.2026",
        notes   = {
            "|cff7C6CFFDer Gestaltungsmodus hat einen Auftritt.|r Das Einstellungsfenster blendet aus, das WCUI-Logo erscheint groß in der Mitte, schwebt nach oben an die Leiste und macht sich dort fest, während die Leiste einblendet. Bei „Fertig“ blendet sie wieder aus und das Fenster weich ein.",
        },
    },
    {
        version = "6.26.8.0",
        date    = "10.10.2026",
        notes   = {
            "|cff7C6CFFOberfläche je Charakter.|r Ob ein Charakter die WeintCodex-Oberfläche nutzt, entscheidest du jetzt für jeden einzeln – an auf dem einen heißt nicht an auf allen. Deine bisherigen Charaktere behalten, was sie hatten.",
            "|cff7C6CFFNeuer Charakter, neuer Willkommensgruß.|r Der Assistent kommt jetzt für jeden neuen Charakter, nicht nur einmal je Account – deine bisherigen Charaktere fragt er nicht noch einmal.",
        },
    },
    {
        version = "6.26.7.0",
        date    = "10.10.2026",
        notes   = {
            "|cff7C6CFFDer Willkommens-Assistent kennt jetzt alle Komfortfunktionen.|r Nach Themen – Alltag, Kampf und Gruppe, Welt und Karte, Handel und Gespräche – je ein Satz und ein Schalter. Mit der Oberfläche ist alles vorgewählt; ohne sie wählst du selbst. Wieder zeigen: /wcui willkommen.",
            "|cff7C6CFFNeues beim Lehrer nach dem Stufenaufstieg.|r Ein Fenster zeigt, welche Zauber du jetzt lernen kannst, was sie kosten und ob dein Gold reicht – ein Klick führt zur Seite „Lehrer“. Geht mit und ohne Oberfläche; abschalten unter Komfort → Anzeigen.",
            "|cff7C6CFFKomfort nach Themen geordnet.|r Die Seiten stehen in derselben Reihenfolge wie im Assistenten: Gespräche neben Flüstern, Karte neben Sammeln.",
        },
    },
    {
        version = "6.26.6.0",
        date    = "10.10.2026",
        notes   = {
            "|cff7C6CFFGebietsinfo auf der Karte eingeklappt.|r Unten links steht nur noch eine Zeile mit Name und Stufe – Angeln, Kräuter und Erze erst mit der Maus darauf. So deckt sie keine Quest mehr zu. Auf dem Kontinent bleibt die ganze Tafel für die Zone unter der Maus.",
        },
    },
    {
        version = "6.26.5.0",
        date    = "09.10.2026",
        notes   = {
            "|cff7C6CFFAcht neue Schriften.|r Unter Allgemein → Schrift und Balken: Barlow, Roboto, Fira, Oswald, Rajdhani, Exo 2 und Inter, dazu Arial Narrow aus dem Spiel – für Plaketten, Rahmen und Hinweise.",
            "|cff7C6CFFStufen und Sammelberufe auf der Karte.|r Unten links steht, für welche Stufen ein Gebiet ist, ab welcher Fertigkeit man dort angeln kann und welche Kräuter und Erze es gibt – auf dem Kontinent für die Zone unter der Maus. Stand aus Classic. Abschalten unter Komfort → Karte.",
            "|cff7C6CFFDezentere Kartensymbole.|r Geistheiler, Pfeile, Flugmeister und Reisen sind kleiner und leiser; unter der Maus wieder voll.",
            "|cff7C6CFFMessart der Schadensanzeige direkt wählen.|r Ein Klick auf den Titel öffnet die Liste aller Messarten; Rechtsklick oder Mausrad blättert weiter wie bisher.",
            "|cff7C6CFFKein harter Rand mehr auf der Karte.|r Mit „Ganze Karte“ stand am Rand mancher Zonen (Wald von Elwynn rechts) ein abgehacktes Stück – jetzt läuft auch das weich aus.",
            "|cff7C6CFFInfozeile unter dem Chat bleibt da.|r Nach dem Einloggen fehlte sie manchmal, bis man zweimal Enter drückte – jetzt kommt sie von selbst zurück.",
            "|cff7C6CFFZielrahmen nach dem Einloggen mit Namen.|r Beim ersten Einloggen blieben Name, Stufe und Leben am Ziel leer, bis man ein paar Mal das Ziel gewechselt hatte – jetzt sind sie gleich da.",
        },
    },
    {
        version = "6.26.4.0",
        date    = "09.10.2026",
        notes   = {
            "|cff7C6CFFRaus da außerhalb des Kampfes geduldiger.|r Zwei Treffer binnen 5 statt 3 Sekunden lösen den Ton aus – Lagerfeuer treffen seltener, als gedacht. /wcui prüfen nennt jetzt auch, welche Art Treffer kam und wie dicht sie aufeinander folgten.",
        },
    },
    {
        version = "6.26.3.0",
        date    = "09.10.2026",
        notes   = {
            "|cff7C6CFFKalender in Gold.|r Pergament und Holzrahmen sind weg: dunkle Tage mit goldener Kante, die Wochentage als goldene Kopfzeile, heute in Gold. Feiertage und Termine bleiben, wie sie sind.",
        },
    },
    {
        version = "6.26.2.0",
        date    = "09.10.2026",
        notes   = {
            "|cff7C6CFFGold-Tooltip erscheint.|r Die unsichtbare Eingabezeile des Chats lag über der Zeile darunter und fing die Maus ab – jetzt zeigt das Gold Einnahmen, Ausgaben und alle Charaktere.",
            "|cff7C6CFFKamera zurücksetzen, gründlicher.|r Der Knopf unter Komfort → Gespräche setzt jetzt auch Ansicht, Verfolgungsstil und „Charakter zentriert halten“ auf den Wert ab Werk.",
        },
    },
    {
        version = "6.26.1.0",
        date    = "08.10.2026",
        notes   = {
            "|cff7C6CFFDie Kamera folgt wieder.|r Nach Gesprächen blieben Testeinstellungen der Kamera stehen – dadurch folgte die Kamera beim Laufen nicht mehr wie eingestellt. Sie werden beim ersten Einloggen einmal auf den Wert ab Werk gesetzt und nach jedem Gespräch jetzt zuverlässig zurückgegeben. Unter Komfort → Gespräche gibt es dafür auch „Kamera zurücksetzen“.",
        },
    },
    {
        version = "6.26.0.0",
        date    = "08.10.2026",
        notes   = {
            "|cff7C6CFFGold auf einen Blick.|r Mit der Maus über dein Gold in der Zeile unter dem Chat: Einnahmen, Ausgaben und Saldo seit dem Einloggen, darunter das Gold all deiner Charaktere auf diesem Realm samt Summe. Jeder Charakter wird beim nächsten Einloggen erfasst.",
        },
    },
    {
        version = "6.25.5.0",
        date    = "08.10.2026",
        notes   = {
            "|cff7C6CFFVermächtnis durchgehend im Codex-Stil.|r Fortschritt, Herausforderungen und Vermächtnisbaum ohne Leder und Metall: offene Karten und Zeilen dunkel, Erreichtes, die gewählte Zeile und die Leisten in Gold. Symbole, Krone und Haken bleiben, wie sie sind.",
        },
    },
    {
        version = "6.25.4.0",
        date    = "08.10.2026",
        notes   = {
            "|cff7C6CFFBerufsfenster wieder sauber.|r Über dem Rezeptsymbol lagen noch ein dunkles Fach und eine Farbfläche – jetzt weg.",
            "|cff7C6CFFFortschrittsanzeige im Gold der anderen Fenster.|r Das Leder dahinter und der Metallrahmen der Leiste sind weg, die Leiste füllt sich in Gold. Karten, Krone und Haken bleiben.",
        },
    },
    {
        version = "6.25.3.0",
        date    = "08.10.2026",
        notes   = {
            "|cff7C6CFFNach dem Spiel-Update aufgeräumt.|r Der helle Streifen oben im Charakterfenster ist weg, das Rezeptsymbol im Berufsfenster wieder sauber. Das neue Fenster „Fortschrittsanzeige“ (Vermächtnis) trägt jetzt das Gold der anderen Fenster.",
            "|cff7C6CFFRaus da außerhalb des Kampfes, zweiter Anlauf.|r Das Spiel verrät dein Leben nicht – WeintCodex hört jetzt darauf, ob du getroffen wirst. Zwei Treffer kurz hintereinander ohne Kampf, und der Ton kommt.",
        },
    },
    {
        version = "6.25.2.0",
        date    = "08.10.2026",
        notes   = {
            "|cff7C6CFFRaus da außerhalb des Kampfes wirkt jetzt.|r Im Lagerfeuer blieb es still – die Wache lief nach dem Einloggen gar nicht. Jetzt läuft sie von Anfang an.",
        },
    },
    {
        version = "6.25.1.0",
        date    = "08.10.2026",
        notes   = {
            "|cff7C6CFFRaus da: vier neue Warntöne.|r „Raus!“ (steigend, hart – der neue Standard), „Achtung“ (tiefes Brummen), „Fehler“ (fallend) und „Trillern“ – kurz, unverwechselbar, eigens gebaut.",
            "|cff7C6CFFRaus da auch außerhalb des Kampfes.|r Stehst du in einem Lagerfeuer, in Lava oder Ähnlichem, ohne zu kämpfen, kommt der Ton jetzt auch: sobald dein Leben zweimal kurz hintereinander sinkt. Ein einzelner Sturz löst nichts aus. Abstellbar auf der Seite „Raus da“.",
        },
    },
    {
        version = "6.25.0.0",
        date    = "08.10.2026",
        notes   = {
            "|cff7C6CFFTaschen als eigene Seite.|r Was deine Charaktere tragen, steht jetzt unter Leveln → Taschen direkt im Codex statt in einem Extrafenster: links deine Charaktere oder alle zusammen, oben die Suche – mit × zum Leeren, Esc leert auch – und die Filter Taschen, Bank, Angelegt, darunter alles als Symbole mit Anzahl. Rechts, ob die Bank bekannt ist, und die Schalter für Tooltip und andere Realms. Läuft immer, auch ohne Oberfläche. /wc taschen öffnet die Seite.",
            "|cff7C6CFFRaus da: fünf neue Alarme.|r Eigene, kurze und laute Warntöne – hoch, tief, dreifach, Hupe, Sirene; „Alarm hoch“ ist der neue Standard. Die Töne des Spiels bleiben zur Auswahl.",
            "|cff7C6CFFSammeln aus dem Aufspürmenü.|r Unten im Aufspürmenü an der Minikarte steht jetzt „WeintCodex – Kräuter + Erz im Wechsel“ zum An- und Ausschalten. Im Kampf wechselt die Suche nicht – das steht jetzt auch auf der Seite.",
            "|cff7C6CFFAddon-Knöpfe klappen zu.|r Ein Klick auf ein Addon schließt die gesammelten Knöpfe an der Minikarte wieder. Abstellbar unter Minikarte → Bedienung.",
        },
    },
    {
        version = "6.24.0.0",
        date    = "08.10.2026",
        notes   = {
            "|cff7C6CFFBestand aller Charaktere.|r Fährst du über einen Gegenstand, steht im Tooltip, welche deiner Charaktere ihn haben und wo – Taschen, Bank, angelegt – samt Summe. Dazu ein eigenes Fenster „Taschen aller Charaktere“ (/wcui taschen oder Komfort → Bestand): links deine Charaktere oder alle zusammen, oben Suche und Filter Taschen, Bank, Angelegt, rechts alles als Symbole mit Anzahl. Mit /wcui bestand <Name> suchst du auch im Chat. Jeder Charakter wird nach dem Einloggen erfasst, seine Bank beim nächsten Besuch. Unter Komfort → Bestand auch für andere Realms.",
            "|cff7C6CFFRaus da: mehr Töne.|r Neun statt drei Warntöne zur Auswahl, alle aus dem Spiel – von Bosswarnung bis Flüstern.",
        },
    },
    {
        version = "6.23.4.0",
        date    = "08.10.2026",
        notes   = {
            "|cff7C6CFFGespräche: die Kamera schaut dein Gegenüber an.|r Sprichst du jemanden an, schwenkt die Kamera auf ihn – egal, wie du davor stehst. Der Text beginnt schon während der Fahrt und steht jetzt größer in einer Serifenschrift da, wie in einem Buch.",
        },
    },
    {
        version = "6.23.3.0",
        date    = "08.10.2026",
        notes   = {
            "|cff7C6CFFGespräche: dein Blickwinkel.|r Stell die Kamera einmal so ein, wie sie im Gespräch stehen soll, und drück unter Komfort → Gespräche auf „Diesen Blick merken“. Ab dann gleitet sie bei jedem Gespräch in genau diesen Blick und danach zurück in deinen alten. Der Text wartet, bis sie angekommen ist.",
        },
    },
    {
        version = "6.23.2.3",
        date    = "08.10.2026",
        notes   = {
            "|cff7C6CFFGespräche: kein Vorblitzen mehr.|r Sprachst du jemanden ein zweites Mal an, stand der Text kurz ganz da und lief dann neu ein. Jetzt bleibt er unsichtbar, bis die Kamera da ist, und erscheint Zeichen für Zeichen. Die Leertaste zeigt ihn sofort, auch während die Kamera noch fährt.",
        },
    },
    {
        version = "6.23.2.2",
        date    = "08.10.2026",
        notes   = {
            "|cff7C6CFFGespräche: abgabebereit auf einen Blick.|r Quests, die du abgeben kannst, stehen golden mit grünem „Abgeben“ da, laufende grau mit „Läuft noch“, neue mit „Neu“. Die kurze Meldung des Spiels zur Testeinstellung beim ersten Gespräch schließt sich jetzt selbst und stört das Ausblenden nicht mehr. Die Kamera hält ab Werk 6 Meter Abstand.",
        },
    },
    {
        version = "6.23.2.1",
        date    = "08.10.2026",
        notes   = {
            "|cff7C6CFFGespräche: der Text bleibt stehen.|r Nach dem Einlaufen verschwand der Text bis auf die ersten Worte – jetzt steht er ganz da. Beim Ausblenden verschwinden auch die Porträts der Rahmen und die Minikarte mit Spielerpfeil und Symbolen; nach dem Gespräch kommen sie zurück.",
        },
    },
    {
        version = "6.23.2.0",
        date    = "08.10.2026",
        notes   = {
            "|cff7C6CFFGespräche zum Eintauchen.|r Sprichst du einen NPC an, blendet die Oberfläche langsam aus – nur das Gespräch bleibt, mit dem Bild des NPCs im goldenen Ring, Zierlinien und Antworten als Karten. Der Text läuft erst ein, wenn die Kamera angekommen ist, im Tempo, das du unter Komfort → Gespräche einstellst. Danach kommen Leisten und Rahmen sanft zurück; im Kampf oder bei einer Rückfrage des Spiels sofort.",
        },
    },
    {
        version = "6.23.1.1",
        date    = "08.10.2026",
        notes   = {
            "|cff7C6CFFGespräche: nur noch ein Fenster.|r Beim Questgeber ging zusätzlich das Fenster des Spiels auf – jetzt nicht mehr. Das Gesprächsfenster steht ab Werk dort, wo sonst das Questfenster steht, und merkt sich, wohin du es ziehst. Die Kamera fährt sofort und langsamer heran, der NPC rückt nach rechts, weg vom Fenster.",
        },
    },
    {
        version = "6.23.1.0",
        date    = "08.10.2026",
        notes   = {
            "|cff7C6CFFGespräche: die Kamera kommt näher.|r Sprichst du einen NPC an, fährt die Kamera heran und rückt ihn neben das Gesprächsfenster – nach dem Gespräch zurück auf deinen Abstand. Wechselst du nur vom Gespräch in den Questtext, bleibt sie nah; hast du selbst weiter herausgezoomt, bleibt es so. Abstand unter Komfort → Gespräche.",
        },
    },
    {
        version = "6.23.0.0",
        date    = "08.10.2026",
        notes   = {
            "|cff7C6CFFGespräche im Codex-Stil.|r Unter Komfort → Gespräche: Gespräche mit NPCs und Questtexte erscheinen in einem ruhigen Fenster neben der Mitte. Zahlen 1–9 wählen eine Antwort oder Belohnung, die Leertaste nimmt an oder schließt ab, Esc beendet das Gespräch. Belohnungen, Gold und Erfahrung stehen auf einen Blick da, der Text läuft auf Wunsch Zeichen für Zeichen ein.",
        },
    },
    {
        version = "6.22.0.2",
        date    = "08.10.2026",
        notes   = {
            "|cff7C6CFFGeistheiler und Pfeile wieder überall sichtbar.|r Mitten in einem Gebiet lagen sie unter den Bildern der erkundeten Gegenden – mit der Maus fand man sie, sehen konnte man sie nicht. Jetzt liegen sie obenauf, auf jeder Karte; die Instanzeingänge auch.",
        },
    },
    {
        version = "6.22.0.1",
        date    = "08.10.2026",
        notes   = {
            "|cff7C6CFFKräuter und Erz im Wechsel ohne Fehlermeldung.|r Der Wechsel brach mit einer Lua-Fehlermeldung ab, sobald du nicht gerade gezaubert hast – also fast immer. Jetzt wechselt er wirklich.",
        },
    },
    {
        version = "6.22.0.0",
        date    = "08.10.2026",
        notes   = {
            "|cff7C6CFFKräuter und Erz zugleich suchen.|r Unter Komfort → Sammeln wechselt WeintCodex außerhalb des Kampfes zwischen Kräuter- und Mineraliensuche, ab Werk alle 2 Sekunden. Im Kampf und beim Zaubern macht es Pause. Lässt das Spiel den Wechsel nicht zu, schaltet er sich ab und sagt es dir.",
        },
    },
    {
        version = "6.21.2.0",
        date    = "08.10.2026",
        notes   = {
            "|cff7C6CFFKontinentkarte aufgeräumt.|r Auf Kalimdor und den Östlichen Königreichen im Ganzen stehen nur noch Schiffe, Zeppeline, Trams und Portale. Geistheiler, Pfeile und Flugmeister siehst du, sobald du in ein Gebiet hineingehst.",
        },
    },
    {
        version = "6.21.1.2",
        date    = "08.10.2026",
        notes   = {
            "|cff7C6CFFKontinentkarte: Symbole an der richtigen Stelle.|r Geistheiler, Pfeile, Flugmeister und Reisen standen auf Kalimdor und den Östlichen Königreichen zusammengedrängt am linken Rand. Jetzt stehen sie dort, wo sie hingehören.",
        },
    },
    {
        version = "6.21.1.1",
        date    = "08.10.2026",
        notes   = {
            "|cff7C6CFFKein Absturz mehr an der Karte.|r Mit vielen Kartensymbolen (Geistheiler, Flugmeister, Reisen auf der Kontinentkarte) stürzte das Spiel ab. Behoben.",
        },
    },
    {
        version = "6.21.1.0",
        date    = "07.10.2026",
        notes   = {
            "|cff7C6CFFNeu im Komfort: Raus da!|r Ein Warnton, sobald du in etwas stehst, das dir schadet und dem man ausweichen kann – nicht nur Feuer, alles am Boden, dazu Kegel und Wellen vor dem Gegner. Drei Töne zur Wahl, höchstens einer je Sekunde. Einschalten unter Komfort → Raus da.",
            "|cff7C6CFFDie ganze Welt auf der Karte.|r Neben Geistheilern und Übergängen zeigt die Karte auf Wunsch Flugmeister, Schiffe, Zeppeline, Trams und Portale – in allen Gebieten und jetzt auch auf der Kontinentkarte. Ab Werk nur deine Fraktion und die neutralen; einstellbar unter Komfort → Karte.",
            "|cff7C6CFFDeine eigene Farbe.|r Unter „Farbe der Oberfläche“ gibt es jetzt neben Klassenfarbe und Lila eine eigene Farbe zum Aussuchen. Sie gilt nach dem Neuladen.",
        },
    },
    {
        version = "6.21.0.1",
        date    = "07.10.2026",
        notes   = {
            "|cff7C6CFFGeistheiler und Pfeile auf der Karte besser zu sehen.|r Sie sind größer, in hellerem Grün und haben einen hellen Rand – auf dem Grün und Braun der Karte gingen sie vorher unter.",
        },
    },
    {
        version = "6.21.0.0",
        date    = "07.10.2026",
        notes   = {
            "|cff7C6CFFGeistheiler und Wege in andere Gebiete auf der Karte.|r Auf Wunsch zeigt die Weltkarte, wo Geistheiler stehen (grüner Punkt) und wo der Weg ins nächste Gebiet führt (grüner Pfeil – Maus darauf zeigt, wohin). Einschalten unter Komfort → Karte.",
            "|cff7C6CFFMehr vom Kopf im Balken.|r Der animierte Kopf im Lebensbalken ist ab Werk weiter herausgezoomt. Wie weit, stellst du unter Feinheiten mit „Kopf im Balken: Abstand“ ein.",
            "|cff7C6CFFErklärungen in den Einstellungen ganz lesbar.|r Die Sätze unter den Schaltern brachen nach einer Zeile mit „…“ ab. Jetzt stehen sie vollständig da.",
            "|cff7C6CFFKontakte: „Freundesliste“ nicht mehr durchgestrichen.|r Die Zierlinie lief mitten durch die Überschrift. Jetzt beginnt sie hinter dem Text.",
            "|cff7C6CFFHerkunft einfacher gesagt.|r Wo der Codex sagt, woher Quests, Rezepte, Lehrer, Eingänge oder seltene Gegner stammen, steht jetzt „Wissensstand aus der Beta“. Im Auktionshaus heißt der Schalter „Preise von anderen Auktionshaus-Addons, die wie WeintCodex arbeiten, übernehmen“.",
        },
    },
    {
        version = "6.20.0.0",
        date    = "07.10.2026",
        notes   = {
            "|cff7C6CFFNeu im Komfort: Instanzeingänge auf der Karte.|r Öffnest du die Weltkarte, steht an jedem Dungeoneingang, den der Codex kennt, ein Symbol – auch auf der Karte von Kalimdor und den Östlichen Königreichen. Maus darauf zeigt Dungeon und Stufe, ein Klick schlägt ihn im Codex auf. Einschalten unter Komfort → Karte.",
            "|cff7C6CFFDie ganze Karte auf einen Blick.|r Auf Wunsch zeigt die Weltkarte auch die Gebiete, in denen du noch nicht warst – abgedunkelt, damit du siehst, wo du noch hin musst. Passt eine Zone nicht zu dem, was du schon erkundet hast, bleibt sie, wie sie ist.",
            "|cff7C6CFFDer Kopf im Balken.|r Spieler- und Zielrahmen können das Porträt jetzt auch animiert im Lebensbalken zeigen – halb durchsichtig hinter Namen und Werten. Einstellen unter Einheitenrahmen → Porträt → „Im Balken (animiert)“, die Deckkraft unter Feinheiten.",
            "|cff7C6CFFDas neue Kontaktfenster im Codex-Stil.|r Das Spiel hat die Kontakte neu gebaut – jetzt sehen sie wieder aus wie die anderen Fenster: ruhiger Grund statt Metall, die Reiter rechts als Kacheln, der gewählte in Gold, Suche und Status flach. Ziehen kannst du es auch.",
            "|cff7C6CFFDie Marke aus dem Codex bleibt.|r „Eingang auf der Karte“ auf einer Dungeonseite setzt weiter die große Marke wie bisher.",
        },
    },
    {
        version = "6.19.1.3",
        date    = "07.10.2026",
        notes   = {
            "|cff7C6CFFFlüstern: kein „r“ mehr in der Chatzeile.|r Nach der Taste „Antworten“ stand der Buchstabe der Taste schon in der Zeile. Jetzt ist sie leer und bereit für deine Antwort.",
        },
    },
    {
        version = "6.19.1.2",
        date    = "07.10.2026",
        notes   = {
            "|cff7C6CFFFlüstern: die Taste „Antworten“ öffnet das Fenster.|r Drückst du R (oder deine Taste dafür), geht das Gespräch mit dem auf, der dir zuletzt geflüstert hat – auch im Kampf. Die Chatzeile zielt dabei auf ihn, auch wenn das Flüstern nicht im Chat stand.",
        },
    },
    {
        version = "6.19.1.1",
        date    = "07.10.2026",
        notes   = {
            "|cff7C6CFFFlüstern: die Zahl am Symbol.|r Ein Punkt in deiner Farbe zeigt, wie viele Nachrichten du noch nicht gelesen hast. Geht das Fenster von selbst auf, bleiben sie ungelesen, bis du mit der Maus darüberfährst, in die Antwortzeile klickst oder das Gespräch wählst.",
        },
    },
    {
        version = "6.19.1.0",
        date    = "07.10.2026",
        notes   = {
            "|cff7C6CFFFlüstern nur noch im Fenster.|r Was dir zugeflüstert wird, steht nicht mehr zusätzlich im Chat – nur im Messenger, mit eigenem Ton. Was das Spiel dem Fenster während einer Sperre nicht verrät, bleibt im Chat, damit nichts verloren geht. Antworte im Fenster: Die Taste R kennt nur, was im Chat stand.",
            "|cff7C6CFFIm Kampf klappt es ein.|r Das Fenster verschwindet, sobald der Kampf beginnt, und geht danach von selbst wieder auf – mit dem, was in der Zwischenzeit kam.",
            "|cff7C6CFF„/w Name“ öffnet das Gespräch.|r Ebenso ein Klick auf einen Namen im Chat. Geschrieben wird weiter in der Chatzeile.",
            "|cff7C6CFFNeues Symbol:|r Ein Klick öffnet die Gespräche jederzeit, die Zahl zeigt Ungelesenes. Fenster und Symbol lassen sich mit der Maus verschieben.",
        },
    },
    {
        version = "6.19.0.1",
        date    = "07.10.2026",
        notes   = {
            "|cff7C6CFFFlüstern: Text markieren und kopieren.|r Der Knopf „Markieren“ oben im Fenster zeigt das Gespräch als Text – mit der Maus markieren, Strg+C kopiert, Esc führt zurück.",
            "|cff7C6CFFKomfort: alle Reiter im Fenster.|r Mit „Flüstern“ lief die Reiterleiste über den Rand. Reicht eine Zeile nicht, bricht sie jetzt in eine zweite um.",
        },
    },
    {
        version = "6.19.0.0",
        date    = "07.10.2026",
        notes   = {
            "|cff7C6CFFNeu im Komfort: Flüstern wie im Messenger.|r Wird dir etwas zugeflüstert, geht ein Fenster auf – links deine Gespräche mit der Zahl ungelesener Nachrichten, rechts der Verlauf in der Klassenfarbe des anderen. Auch Battle.net-Freunde. Im Kampf geht es erst danach auf. Einschalten unter Komfort → Flüstern, jederzeit öffnen mit /wcui flüstern.",
            "|cff7C6CFFIm Chat bleibt alles, wie es ist.|r Jedes Flüstern steht weiter auch dort, und der Verlauf im Fenster gilt nur bis zum Ausloggen – nichts davon wird gespeichert.",
            "|cff7C6CFFAntworten:|r Ein Klick in die Antwortzeile öffnet die Chatzeile mit „/w Name“, Enter sendet. Wer es ausprobieren will: „Direkt aus dem Fenster senden“ – lässt das Spiel es nicht zu, schaltet es sich von selbst wieder ab.",
        },
    },
    {
        version = "6.18.0.2",
        date    = "07.10.2026",
        notes   = {
            "|cff7C6CFF/wcui auktion zählt richtig.|r Was verworfen wird, weil es älter ist als dein eigener Scan, steht jetzt als Zahl der Nachrichten da – vorher hieß es „ganze Scans“, gezählt wurden aber einzelne Nachrichten.",
        },
    },
    {
        version = "6.18.0.1",
        date    = "07.10.2026",
        notes   = {
            "|cff7C6CFFKeine Fehlermeldungen mehr beim Übernehmen von Preisen anderer Auktions-Addons.|r Sobald Preise von anderen Spielern ankamen, meldete das Spiel laufend einen Fehler. Behoben – die Preise selbst kamen schon an und bleiben erhalten.",
        },
    },
    {
        version = "6.18.0.0",
        date    = "07.10.2026",
        notes   = {
            "|cff7C6CFFAuktionspreise von anderen Spielern.|r Du musst nicht mehr selbst scannen, um frische Preise zu haben: Wer in deiner Gilde mit WeintCodex gescannt hat, teilt seine Preise mit dir – und du deine mit ihm. Im Tooltip steht dann „von Spielern“. Einschalten unter Komfort → Auktionshaus → „Mit der Gilde teilen“.",
            "|cff7C6CFFPreise anderer Auktions-Addons übernehmen.|r Manche Auktions-Addons verschicken ihre Scans an alle Spieler deines Realms, die dasselbe Addon nutzen. WeintCodex kann mithören und diese Preise übernehmen – es schickt selbst nie etwas dorthin. Ebenfalls unter Komfort → Auktionshaus.",
            "|cff7C6CFFDein eigener Scan geht immer vor.|r Ein fremder Preis, der mehr als dreimal so hoch oder niedrig ist wie der bekannte, zählt erst, wenn ein zweiter Spieler ihn bestätigt.",
        },
    },
    {
        version = "6.17.0.0",
        date    = "07.10.2026",
        notes   = {
            "|cff7C6CFFNeu im Komfort: Auktionspreise im Tooltip.|r Oben am Auktionshaus liest der Knopf „Preise scannen“ alle Angebote. Danach steht in jedem Tooltip eines Gegenstands das günstigste Angebot je Stück – mit der Menge im Angebot und dem Tag, an dem du es gesehen hast; in den Taschen auch der Preis des ganzen Stapels. Einschalten unter Komfort → Auktionshaus.",
            "|cff7C6CFFAuch beim Stöbern.|r Was deine eigene Suche im Auktionshaus zeigt, wird nebenbei gemerkt – je Realm und Auktionshaus (Allianz, Horde, neutral), höchstens 30 Tage.",
            "|cff7C6CFF/wcui auktion|r zeigt, wann zuletzt gelesen wurde und auf welchem Weg.",
        },
    },
    {
        version = "6.16.0.0",
        date    = "06.10.2026",
        notes   = {
            "|cff7C6CFFNeu im Komfort: seltene Gegner melden.|r Taucht einer als Namensplakette, im Ziel, unter der Maus oder als Symbol auf der Minikarte auf, gibt es einen Ton, eine Zeile im Chat und oben einen Hinweis mit Stufe, Elite und wie lange er in Classic zum Wiederkommen brauchte. Derselbe meldet sich höchstens alle fünf Minuten. Einschalten unter Komfort → Seltene Gegner.",
            "|cff7C6CFF/wcui selten|r listet die seltenen Gegner deines Gebiets – mit dem Zeitpunkt, an dem du jeden zuletzt gesehen hast.",
        },
    },
    {
        version = "6.15.0.0",
        date    = "06.10.2026",
        notes   = {
            "|cff7C6CFFNeu beim Lehrer: Klassenquests.|r Ein zweiter Reiter zeigt die Quests nur für deine Klasse und dein Volk – vor allem die, die einen Zauber lehren, den kein Lehrer hat: Begleiter, Zähmen, Totems, Haltungen, Gestalten. Was du schon erledigt hast und was im Questlog steht, sagt dein Spiel; ein Klick setzt die Marke am Questgeber, wo er bekannt ist. Auch mit /wc klassenquests.",
            "|cff7C6CFFDer nächste Klassenlehrer.|r Neben den Klassenquests stehen die Lehrer deiner Klasse, der nächstgelegene oben, mit Marke auf der Karte.",
            "|cff7C6CFFDie Übersicht meldet Klassenquests.|r Ist eine Quest dran, die dir einen Zauber beibringt, steht sie als Schritt auf der Startseite.",
        },
    },
    {
        version = "6.14.0.2",
        date    = "06.10.2026",
        notes   = {
            "|cff7C6CFFWeniger Speicher.|r Questpfeil, Namensplaketten, Minikarte und die Koordinaten an der Weltkarte erzeugen beim Laufen nur noch einen Bruchteil des Abfalls, und Lehrerdaten anderer Klassen und die Classic-Beute der alten Dungeons werden erst geladen, wenn du sie aufschlägst. An dem, was du siehst, ändert sich nichts.",
            "|cff7C6CFF/wcui speicher sagt jetzt auch, was davon Abfall war:|r Nach der Messung räumt es einmal auf und nennt, wie viel WeintCodex wirklich belegt.",
            "|cff7C6CFFBerufe:|r Über den Lehrern heißt es jetzt „der nächstgelegene steht oben“.",
        },
    },
    {
        version = "6.14.0.1",
        date    = "06.10.2026",
        notes   = {
            "|cff7C6CFFDer nächste Berufslehrer steht oben.|r Unter allen, die deinen nächsten Rang lehren, kommt der zuerst, der dir am nächsten ist – nicht mehr der Fachmann am anderen Ende des Kontinents. Die Zeile nennt den Ort und bis wohin er lehrt, den Rang zeigt der Tooltip.",
            "|cff7C6CFFBerufe: ehrlichere Zahlen.|r Solange du dein Berufsfenster nicht geöffnet hast, heißt es „bis zu“ und „mindestens“ – und über den Rezepten steht, was die vier Zahlen bedeuten.",
        },
    },
    {
        version = "6.14.0.0",
        date    = "06.10.2026",
        notes   = {
            "|cff7C6CFFNeu: Berufe.|r Links deine Berufe mit Fertigkeit, in der Mitte die Rezepte: was du jetzt beim Lehrer oder als Rezept lernen kannst, was dir noch Punkte bringt (in den Farben des Berufsfensters), was bald kommt – und was neu oder geändert in Forever ist. Rechts die Lehrer deiner Fraktion, der deinen nächsten Rang lehrt zuerst, mit Marke auf der Karte. Öffne einmal dein Berufsfenster, dann weiß WeintCodex, was du schon kannst. Auch mit /wc berufe.",
            "|cff7C6CFFDungeons: viel mehr Quests.|r Blackrock-Tiefen, Düsterbruch, Schwarzfelsspitze, Uldaman, Stratholme, Scholomance und weitere haben jetzt ihre Quests – mit Geber, Abgabe, Belohnungen und welche Quest davor und danach kommt.",
            "|cff7C6CFFEingang auf der Karte.|r Für die meisten Dungeons setzt ein Knopf die Marke am Eingang, Stratholme hat zwei.",
            "|cff7C6CFFBeute auch in den alten Dungeons.|r Was die Bosse in Classic fallen ließen, steht jetzt dabei – als Classic-Liste gekennzeichnet, denn Forever hat die Beute überarbeitet.",
            "|cff7C6CFFDie Übersicht kennt deine Berufe.|r Kannst du beim Berufslehrer etwas lernen, steht es als Schritt auf der Startseite.",
        },
    },
    {
        version = "6.13.5.0",
        date    = "06.10.2026",
        notes   = {
            "|cff7C6CFFDie Übersicht schlägt keine Dungeons der anderen Fraktion mehr vor.|r Wer in der Allianz spielt, bekommt Ragefire Chasm in Orgrimmar nicht mehr als „passt“, wer in der Horde spielt, Hall of Thanes und The Stockade nicht. Im Dungeonkompendium stehen weiter alle.",
        },
    },
    {
        version = "6.13.4.0",
        date    = "06.10.2026",
        notes   = {
            "|cff7C6CFFDein Weg zeigt wieder jeden Dungeon.|r Öffnen sich auf einer Stufe zwei Dungeons, stehen beide da – bisher war der zweite hinter „…“ verschwunden, etwa The Deadmines neben Wailing Caverns. Bei mehr als zweien steht „+N weitere“, alle Namen im Tooltip.",
        },
    },
    {
        version = "6.13.3.0",
        date    = "06.10.2026",
        notes   = {
            "|cff7C6CFFZweiter Versuch für die Laune deines Begleiters.|r WeintCodex fragt jetzt dort, wo Forever sie führt. Erscheint der Punkt am Begleiterrahmen weiterhin nicht, gibt das Spiel die Laune nur verschlüsselt heraus – /wcui prüfen zeigt dann, was genau es antwortet.",
        },
    },
    {
        version = "6.13.2.0",
        date    = "06.10.2026",
        notes   = {
            "|cff7C6CFFDie Erinnerungen zeigen nur noch die Regeln deiner Klasse.|r Die der anderen Charaktere stehen als eine Zeile darunter; „Alle zeigen“ holt sie zum Aufräumen dazu. Eine alte Regel „Begleiter fehlt“ gilt nur noch für Jäger und Hexenmeister.",
            "|cff7C6CFFDie Laune deines Begleiters lässt sich messen.|r Der Punkt am Begleiterrahmen bleibt aus, weil das Spiel die Laune nicht dort herausgibt, wo WeintCodex fragt. /wcui prüfen mit Begleiter zeigt jetzt, wo das Spiel sie führt – mit diesem Bericht kommt der Punkt.",
        },
    },
    {
        version = "6.13.1.0",
        date    = "06.10.2026",
        notes   = {
            "|cff7C6CFFDu siehst, wie glücklich dein Begleiter ist.|r Am Begleiterrahmen steht links ein Punkt: grün für glücklich, gelb für zufrieden, rot für unglücklich – im Tooltip als Wort.",
            "|cff7C6CFFNeue Erinnerung: Begleiter nicht glücklich.|r Unter Erinnerungen → Regeln wählst du, ob sie schon bei „zufrieden“ kommt oder erst bei „unglücklich“. Jäger bekommen sie als Vorschlag; wer schon eigene Regeln hat, ergänzt sie mit „Für meine Klasse“.",
        },
    },
    {
        version = "6.13.0.0",
        date    = "06.10.2026",
        notes   = {
            "|cff7C6CFFDie Navigation ist neu geordnet.|r Vier Gruppen, je eine Frage: Leveln (Übersicht, Charakter, Lehrer, Dungeons), Gruppe (Gruppencheck, Schlachtzüge, Anmeldung, Kalender), Gilde (Materialien) und System (Companion, Einstellungen). Es fehlt nichts – nur der Platz hat sich geändert.",
            "|cff7C6CFFImport steht jetzt unter Companion.|r Dort gibt es zwei Reiter: Synchronisierung und Import. /wc import führt weiter direkt dorthin.",
            "|cff7C6CFFDie Suche findet die Übersicht wieder.|r Der Treffer „Übersicht“ tat bisher nichts.",
        },
    },
    {
        version = "6.12.0.1",
        date    = "06.10.2026",
        notes   = {
            "|cff7C6CFFWeintCodex fragt nach deinem Profil.|r Loggst du mit einem Charakter ein, der noch kein eigenes Profil hat, fragt WeintCodex einmal: eigenes Profil anlegen, ein vorhandenes wählen oder „Standard“ behalten. Mit dem Kreuz oder Esc kommt die Frage beim nächsten Einloggen wieder.",
        },
    },
    {
        version = "6.12.0.0",
        date    = "05.10.2026",
        notes   = {
            "|cff7C6CFFProfile für deine Charaktere.|r Jeder Charakter kann seine eigene Oberfläche haben – Einstellungen und Plätze der Rahmen. Unter /wcui → Allgemein → Profile (oder /wcui profil) legst du ein Profil als Kopie an, gibst ihm einen Namen, wählst es für einen Charakter, übernimmst Einstellungen aus einem anderen oder setzt es zurück. Mehrere Charaktere können ein Profil teilen.",
            "|cff7C6CFFNichts geht verloren.|r Alles, was du bisher eingestellt hast, steht jetzt im Profil „Standard“ – damit starten auch neue Charaktere. Ein Wechsel gilt nach dem Neuladen.",
        },
    },
    {
        version = "6.11.0.4",
        date    = "05.10.2026",
        notes   = {
            "|cff7C6CFFKeine Schrift mehr übereinander.|r Auf den Karten unter „Außerdem“ lief eine lange Zeile – etwa die Namen der Waffen – unter „es fehlen …“ durch. Jetzt endet sie davor.",
        },
    },
    {
        version = "6.11.0.3",
        date    = "05.10.2026",
        notes   = {
            "|cff7C6CFFDie Übersicht nennt deine Zauber.|r Kannst du beim Lehrer etwas lernen, stehen die Zauber mit Symbol und Rang gleich unter „Als Nächstes“ – ohne erst zum Lehrer zu wechseln. Fährst du mit der Maus darüber, zeigt das Spiel den Zauber. Bei den Waffen stehen die Namen ebenso da.",
            "|cff7C6CFFDein Weg verrät, was kommt.|r Fahr mit der Maus über eine Stufe in „Dein Weg“, und du siehst, welche Zauber sie bringt und welcher Dungeon sich öffnet – auch die Namen, die unten nicht ganz hinpassen.",
        },
    },
    {
        version = "6.11.0.2",
        date    = "05.10.2026",
        notes   = {
            "|cff7C6CFFDie Übersicht nach deinem Entwurf.|r Oben „Als Nächstes“ mit deiner Stufe, dem wichtigsten Schritt und deiner Erfahrung – schraffiert siehst du, wie weit dich die abgabebereiten Quests bringen. Darunter „Außerdem“ als eigene Karten mit Kosten in Münzen, und „Dein Weg“ zeigt die nächsten acht Stufen nebeneinander: neue Zauber, Dungeons, die sich öffnen.",
            "|cff7C6CFFQuests auf der Karte.|r Sind Quests abgabebereit, öffnet „Auf der Karte zeigen“ die Weltkarte.",
            "|cff7C6CFFKein seltsames Zeichen mehr in Überschriften.|r Ein „ß“ in einer Überschrift in Großbuchstaben stand als kleines Zeichen zwischen den Versalien – jetzt heißt es „AUSSERDEM“.",
        },
    },
    {
        version = "6.11.0.1",
        date    = "05.10.2026",
        notes   = {
            "|cff7C6CFFDie Übersicht ist aufgeräumt.|r Oben steht groß, was als Nächstes dran ist – mit deiner Stufe und wie weit es bis zur nächsten ist. Darunter links, was sonst noch ansteht, mit Symbol, und rechts dein Weg als Liste der nächsten Stufen.",
        },
    },
    {
        version = "6.11.0.0",
        date    = "05.10.2026",
        notes   = {
            "|cff7C6CFFDie Übersicht sagt dir, was als Nächstes dran ist.|r Statt Datum, Erfahrungsleiste und drei vollen Spalten stehen dort höchstens drei Schritte, das Wichtigste zuerst – Zauber beim Lehrer, Quests zur Abgabe, ein zerbrochener Gegenstand, ein Dungeon, für den du Quests hast. Ein Knopf bringt dich jeweils hin.",
            "|cff7C6CFFDein Weg.|r Darunter siehst du die nächsten Stufen, an denen etwas Neues kommt: neue Zauber beim Lehrer und Dungeons, die sich öffnen.",
            "|cff7C6CFFLeere Ausrüstungsplätze sind kein Mangel mehr.|r Mit Stufe 3 hat jeder noch keinen Helm und keinen Umhang – die Übersicht und der rote Punkt am Charakter melden nur noch zerbrochene Gegenstände. Reicht dein Gold für Zauber oder Waffen nicht, steht das dabei.",
        },
    },
    {
        version = "6.10.4.9",
        date    = "05.10.2026",
        notes   = {
            "|cff7C6CFFNichts Neues im Spiel.|r Diese Fassung hält nur fest, was in der letzten Testrunde geprüft wurde und was noch nicht.",
        },
    },
    {
        version = "6.10.4.8",
        date    = "05.10.2026",
        notes   = {
            "|cff7C6CFFDie Leiste beim Berufslehrer ist wieder blau.|r Dunkel war sie schlecht zu erkennen – jetzt trägt sie das Blau, das du von der Fertigkeit kennst, flach und ohne grauen Rahmen.",
        },
    },
    {
        version = "6.10.4.7",
        date    = "05.10.2026",
        notes   = {
            "|cff7C6CFFBerufslehrer ohne blauen Rest.|r Hinter der Leiste mit deinem Fertigkeitsstand lag noch eine blaue Fläche des Spiels; jetzt ist die Rinne dunkel wie bei den anderen Leisten.",
        },
    },
    {
        version = "6.10.4.6",
        date    = "05.10.2026",
        notes   = {
            "|cff7C6CFFSchadensanzeige in die Gilde ohne Fehlermeldung.|r Das Spiel lässt Addons nicht selbst in die Gilde schreiben – die Meldung brach mit einem Lua-Fehler ab. Für Gilde, Sagen und Flüstern legt die Sprechblase die Meldung jetzt als eine Zeile in die Eingabezeile des Chats; mit Enter schickst du sie ab. In die Gruppe meldet sie weiter direkt.",
            "|cff7C6CFFBerufslehrer in Gold.|r Die Leiste mit deinem Fertigkeitsstand oben im Fenster ist flach und golden statt blau mit grauem Rahmen.",
        },
    },
    {
        version = "6.10.4.5",
        date    = "05.10.2026",
        notes   = {
            "|cff7C6CFFDer Reiter „Info“ der Gilde ohne Pergament.|r Nachricht des Tages, Gildeninformation und Gildenneuigkeiten stehen jetzt auf ruhigen dunklen Flächen statt auf braunem Pergament mit grauen Rändern und Holzleiste.",
        },
    },
    {
        version = "6.10.4.4",
        date    = "05.10.2026",
        notes   = {
            "|cff7C6CFFGildenmitglieder ohne hellen Rand.|r In der großen Mitgliederansicht saß um die Liste und die Spaltenköpfe noch ein grauer Rahmen, hinter den Köpfen Marmor – beides ist weg.",
        },
    },
    {
        version = "6.10.4.3",
        date    = "05.10.2026",
        notes   = {
            "|cff7C6CFFDie Linie hinter den Überschriften, zweiter Anlauf.|r Im Zauberbuch und an den Talentbäumen lag die feine Linie genau zwischen zwei Bildpunkten und wurde deshalb nicht gezeichnet. Jetzt liegt sie auf ganzen Bildpunkten.",
            "|cff7C6CFFGildenbank ohne Wappen.|r Das Wappen ragte allein über den oberen Rand des Fensters; jetzt beginnt die Gildenbank so ruhig wie die anderen Fenster.",
            "|cff7C6CFFDie Mitgliederliste der Gilde passt dazu.|r Grauer Rand, Leder hinter dem Bildlauf und die grauen Bänder hinter jedem Namen sind weg – die Liste steht auf derselben Fläche wie Chat und Communitys, ohne dunkler zu werden. Rang, Status und Namensfarben bleiben.",
        },
    },
    {
        version = "6.10.4.2",
        date    = "05.10.2026",
        notes   = {
            "|cff7C6CFFDie Linie hinter den Überschriften ist jetzt einen Bildpunkt hoch.|r Im Zauberbuch („Allgemein“) und an den Namen der Talentbäume stand bisher nur die Raute. Die feine Linie dahinter war vermutlich schmaler als ein Bildpunkt und verschwand. Fehlt sie noch, sagt /wcui fenster jetzt, wie hoch sie ist.",
            "|cff7C6CFFDer Reiter der Sammlung ist flach.|r „Gegenstände“ unter den Vorlagen trug noch das Gold des Spiels; jetzt sieht er aus wie die Reiter in Händler, Post und Kontakten, der gewählte mit goldenem Rand.",
            "|cff7C6CFFKein dunkles Rechteck mehr neben der Post.|r Die Fläche hinter dem Posteingang ragte rechts und unten über das Fenster hinaus; jetzt endet sie am Rand.",
            "|cff7C6CFFGildenbank und Gildenchat ohne Reste des Spiels.|r Die Reiter der Gildenbank sind flach, der Betrag steht ohne Goldrahmen, die goldenen Flügel am Wappen sind weg – das Wappen selbst bleibt. Die Eingabezeile im Gildenchat ist eine flache Leiste statt des hellen runden Rahmens.",
        },
    },
    {
        version = "6.10.4.1",
        date    = "04.10.2026",
        notes   = {
            "|cff7C6CFFGegner per Mouseover markieren.|r In Dungeons und Schlachtzügen: Maus über einen Gegner, mittlere Maustaste – er bekommt die nächste freie Markierung, Totenkopf zuerst, und niemand wird doppelt markiert. Taste, Orte und Markierungen stellst du unter /wcui → Komfort → Automark ein. Nur außerhalb des Kampfes, und nur mit Tastendruck: von sich aus lässt das Spiel Addons nicht markieren.",
            "|cff7C6CFFGeschlossene Fenster kommen an ihren Platz zurück.|r Ein verschobenes Fenster bleibt dort, solange es offen ist; nach dem Schließen öffnet es wieder an seinem gewohnten Platz.",
        },
    },
    {
        version = "6.10.4.0",
        date    = "04.10.2026",
        notes   = {
            "|cff7C6CFFFenster lassen sich verschieben.|r Charakter, Zauberbuch, Bank, Post, Händler, Karte, Berufe und viele mehr: an einer freien Stelle (Titel, Rand) mit der linken Maustaste ziehen. Der Platz bleibt gemerkt und gilt beim nächsten Öffnen wieder. Umschalt + Rechtsklick auf ein Fenster setzt es an seinen alten Platz zurück, /wcui fenster zurück alle.",
        },
    },
    {
        version = "6.10.3.4",
        date    = "04.10.2026",
        notes   = {
            "|cff7C6CFFDie Bedrohungsleiste lässt sich einstellen.|r Unter Namensplaketten → Bedrohung & Farben hat die Leiste jetzt einen eigenen Abschnitt: ab wie viel Prozent sie warnt, ob sie auch allein erscheint, ob sie dir als Tank den Nächsten oder deine eigene Bedrohung zeigt – und alle Farben, auch das Grau für „weit weg“. Die Vorschau oben zeigt sofort, was sich ändert.",
        },
    },
    {
        version = "6.10.3.3",
        date    = "04.10.2026",
        notes   = {
            "|cff7C6CFFAggro auf einen Blick an der Farbe.|r Die Namensplaketten färben sich jetzt ab Werk nach der Bedrohung: rot, wenn du die Aggro hast, orange, wenn du kurz davor bist – als Tank grün, solange du sicher hältst, und orange, wenn der Nächste nah dran ist. Leiste, Prozentzahl und Lebensbalken zeigen dieselbe Farbe. Allein ohne Begleiter bleibt alles in seiner gewohnten Farbe. Abschaltbar unter Namensplaketten → Bedrohung & Farben.",
        },
    },
    {
        version = "6.10.3.2",
        date    = "04.10.2026",
        notes   = {
            "|cff7C6CFFDie Bedrohungsleiste unter den Namensplaketten sagt jetzt etwas.|r Als Tank zeigt sie, wie nah der Nächste an der Aggro ist – grün mit Abstand, orange, wenn es eng wird – statt immer voll grün. Allein ohne Begleiter fällt sie weg: dann hast du die Aggro ohnehin immer, und jeder Gegner trug eine volle rote Leiste. Dazu ein feiner Rand wie am Leben darüber.",
        },
    },
    {
        version = "6.10.3.1",
        date    = "04.10.2026",
        notes   = {
            "|cff7C6CFFWürfeln um Beute im neuen Stil.|r Das kleine Fenster für Bedarf, Gier und Passen steht jetzt auf einer ruhigen Fläche statt auf dem dunklen Toast: das Symbol mit einem feinen Rand in der Farbe seiner Qualität, die verbleibende Zeit als schlichter Balken in Gold. Die Knöpfe bleiben, wie sie sind.",
        },
    },
    {
        version = "6.10.3.0",
        date    = "04.10.2026",
        notes   = {
            "|cff7C6CFFDungeons mit dem Spiel abgleichen.|r /wc abgleich liest, was das Spiel selbst über Dungeons und Schlachtzüge weiß – Namen, Stufen, Bosse und ihre Reihenfolge – und stellt es neben das, was der Codex sagt. Ergebnis zum Kopieren; am Codex ändert der Befehl nichts.",
        },
    },
    {
        version = "6.10.2.1",
        date    = "04.10.2026",
        notes   = {
            "|cff7C6CFFGenauere Selbstprüfung.|r /wcui prüfen meldet Fenster, die das Spiel erst beim ersten Öffnen lädt, nicht mehr als fehlend, und in einer Gruppe prüft sie auch die Bedrohung eines Mitspielers – einmal im Kampf in einer Gruppe ausführen hilft.",
        },
    },
    {
        version = "6.10.2.0",
        date    = "04.10.2026",
        notes   = {
            "|cff7C6CFFSelbstprüfung.|r /wcui prüfen (oder der Knopf unter Einstellungen → Tooltip & Fenster) fragt das Spiel, was nur es beantworten kann – etwa ob die Bedrohung lesbar ist und welche Messarten es gibt – und zeigt das Ergebnis zum Kopieren. Geändert wird nichts.",
            "|cff7C6CFFBerichte zum Kopieren.|r /wcui fenster schreibt nicht mehr in den Chat, sondern in ein Fenster: alles markiert, Strg+C, fertig – ohne Bildschirmfoto und ohne abgeschnittene Zeilen. Jedes Bild steht dort mit allen Stellen, an denen es vorkommt.",
        },
    },
    {
        version = "6.10.1.0",
        date    = "04.10.2026",
        notes   = {
            "|cff7C6CFFLehrer im neuen Aussehen.|r Das Fenster beim Lehrer ohne Pergament und rotbraune Zeilen – die gewählte Zeile bleibt in Gold markiert, dein Gold steht wie gewohnt unten links.",
            "|cff7C6CFFKontakte im neuen Aussehen.|r Freundesliste, BattleTag und Status in Gold wie Post und Bank – ohne Metallrahmen und rote Knöpfe. Wer online ist und wer nicht, siehst du weiter an der Farbe der Zeile.",
            "|cff7C6CFFAufgeräumte Einstellungen in allen großen Bereichen.|r Auch Gruppenrahmen, Aktionsleisten, Questpfeil, Minikarte, Chat und die Seiten der einzelnen Einheitenrahmen zeigen zuerst das Wichtige; Randfarben, Schriftgrößen und Kleinigkeiten liegen unter „Erweitert“. Die Suche findet alles weiter.",
            "|cff7C6CFFDeine Plaketten-Bewegung bleibt.|r Wer sich vorher einzelne Bewegungen ab- und andere angeschaltet hatte, behält genau diese Wahl – sie steht jetzt unter „Bewegung: Eigene“.",
        },
    },
    {
        version = "6.10.0.0",
        date    = "04.10.2026",
        notes   = {
            "|cff7C6CFFEinstellungen suchen.|r Oben rechts im Einstellungsfenster: ein Wort tippen, auf den Treffer klicken – die richtige Seite öffnet sich.",
            "|cff7C6CFFWeniger Schalter auf einen Blick.|r Feineinstellungen wie einzelne Farben, Schriftgrößen und Textplätze liegen unter „Erweitert“ und sind zugeklappt. Ein Klick blendet sie auf allen Seiten ein; was du dort eingestellt hast, gilt weiter.",
            "|cff7C6CFFRuhigere Namensplaketten.|r Neue Wahl „Bewegung“: Ruhig (Standard), Lebendig oder Eigene. Ruhig: Das Ziel leuchtet, aber nichts atmet, glänzt oder blitzt mehr. Wer es lebendig mag, stellt es um.",
            "|cff7C6CFFSchadensanzeige ohne Überlappen.|r Titel, Zeitraum und Knöpfe teilen sich die Kopfzeile, Name und Zahl die Zeile – nichts liegt mehr übereinander. Das Fenster ist dafür mindestens 220 Punkte breit.",
        },
    },
    {
        version = "6.9.1.3",
        date    = "04.10.2026",
        notes   = {
            "|cff7C6CFFRuhe im Chat.|r Die Zeilen „WeintCompanion: … aktualisiert“ und „… zur Warteschlange hinzugefügt“ erscheinen nicht mehr – sie kamen bei jeder Fertigkeitsstufe und jedem Ausrüstungswechsel. Was für die Companion bereitliegt, steht weiter auf der Companion-Seite.",
        },
    },
    {
        version = "6.9.1.2",
        date    = "03.10.2026",
        notes   = {
            "|cff7C6CFFDie Post im neuen Stil.|r Posteingang und Post versenden ohne Metallrahmen, Pergament und Stein: ruhige Flächen, flache Plätze und Eingabefelder, Gold als Akzent wie bei Bank und Auktionshaus. Der Brief, den du schreibst, steht in heller Schrift.",
        },
    },
    {
        version = "6.9.1.1",
        date    = "03.10.2026",
        notes   = {
            "|cff7C6CFFDie Bank im neuen Stil.|r Kein Metallrahmen, kein Stein und kein Leder mehr: flache Plätze mit feinem Rand auf ruhiger Fläche, Gold als Akzent wie beim Händler und im Auktionshaus. Symbole, Qualitätsfarben und die Schlösser ungekaufter Taschenplätze bleiben.",
            "|cff7C6CFFGildenbank in Gold.|r Rahmen und Akzent wie die Bank. Die Plätze darin folgen, sobald sie vermessen sind.",
        },
    },
    {
        version = "6.9.1.0",
        date    = "02.10.2026",
        notes   = {
            "|cff7C6CFFMikromenü und Taschenleiste frei verschiebbar.|r Beide stehen jetzt im Gestaltungsmodus: ziehen, und sie bleiben dort – auch wenn das Spiel seine Leisten neu anordnet. Rechtsklick setzt sie zurück. Bisher sprangen sie immer wieder nach unten links bzw. rechts.",
        },
    },
    {
        version = "6.9.0.9",
        date    = "02.10.2026",
        notes   = {
            "|cff7C6CFFAufschlüsselung mit Platz für alles.|r Das Fenster, das sich mit einem Klick auf einen Namen in der Schadensanzeige öffnet, wird so breit, wie die Reiter der Messarten es brauchen – keiner läuft mehr rechts hinaus.",
        },
    },
    {
        version = "6.9.0.8",
        date    = "02.10.2026",
        notes   = {
            "|cff7C6CFFBedrohung in der Schadensanzeige.|r Neue Messart „Bedrohung“: alle aus deiner Gruppe auf der Bedrohungsliste deines Ziels, Tank zuerst. Ein voller Balken heißt: diese Person zieht die Aggro – die 110 % im Nahkampf und 130 % auf Distanz rechnet das Spiel schon ein.",
            "|cff7C6CFFBedrohung an den Namensplaketten.|r Unter dem Leben läuft eine dünne Leiste, die sich bis zur Aggro füllt – grau weit weg, orange kurz davor, rot mit Aggro, als Tank grün, solange du sie hältst. Liegt die Aggro nicht beim Tank, steht darunter, wer sie hat.",
            "|cff7C6CFFMehr Messarten.|r Schaden und Heilung pro Sekunde als eigene Ranglisten, Absorption, vermeidbarer Schaden und Schaden an Gegnern – sofern das Spiel sie misst.",
            "|cff7C6CFFIn den Chat melden.|r Die Sprechblase in der Kopfzeile schreibt die ersten Plätze in Gruppe, Schlachtzug, Gilde, Sagen oder als Flüstern an dein Ziel – nach dem Kampf, wenn die Zahlen offen sind.",
        },
    },
    {
        version = "6.9.0.7",
        date    = "02.10.2026",
        notes   = {
            "|cff7C6CFFZurück genau dorthin, wo du warst.|r Schließt du den Bearbeitungsmodus des Spiels, geht das Einstellungsfenster wieder auf – auf derselben Seite und an derselben Stelle. Bisher blieb es zu, weil das Spiel es beim Öffnen selbst geschlossen hatte.",
            "|cff7C6CFFLage und Größe ganz oben.|r Bei den Aktionsleisten steht der Knopf zum Bearbeitungsmodus des Spiels jetzt am Anfang der Seite statt ganz unten.",
            "|cff7C6CFFQueststatus im Dungeonkompendium.|r Jede Quest eines Dungeons zeigt, ob du sie schon hast, abgeben kannst, erledigt hast oder ob sie noch fehlt – mit farbigem Streifen und einer Summe über der Liste. Kein Vergleichen mit dem Questlog mehr.",
        },
    },
    {
        version = "6.9.0.6",
        date    = "02.10.2026",
        notes   = {
            "|cff7C6CFFBeute und Quests für sechs weitere Dungeons.|r Im Dungeonkompendium stehen jetzt auch für The Stockade, Gnomeregan, Razorfen Kraul, den Friedhof des Scharlachroten Klosters, die Excavation Site und die City of Dalaran die Beute je Boss und – wo bekannt – die Quests mit Questgebern auf der Weltkarte.",
            "|cff7C6CFFDalaran und die Excavation Site haben Bosse.|r Für Dalaran sind jetzt alle neun Kämpfe benannt, für die Excavation Site drei Bosse – beides aus Beta-Berichten, nicht von Blizzard bestätigt, und ohne Reihenfolge.",
            "|cff7C6CFFBeute unterwegs.|r In The Deadmines, Wailing Caverns, Shadowfang Keep und Blackfathom Deeps steht jetzt auch, was die Gegner zwischen den Bossen fallen lassen.",
        },
    },
    {
        version = "6.9.0.5",
        date    = "02.10.2026",
        notes   = {
            "|cff7C6CFFEin Knopf zum Bearbeitungsmodus des Spiels.|r Was WeintCodex nicht selbst verschiebt – Aktionsleisten, Minikarte, Buffs, Questliste, Abklingzeitmanager, Chat, die Gruppenrahmen des Spiels –, erreichst du jetzt mit einem Klick: oben im Gestaltungsmodus, unter „Allgemein“ und auf jeder Seite, deren Rahmen das Spiel stellt.",
            "|cff7C6CFFUnd wieder zurück.|r Schließt du den Bearbeitungsmodus des Spiels, bist du wieder dort, wo du herkamst – im Gestaltungsmodus oder auf derselben Einstellungsseite. Und unter dem Bearbeitungsmodus des Spiels steht ein Knopf „Zum Gestaltungsmodus“: er schließt ihn wie sein X – mit Rückfrage, falls noch etwas ungespeichert ist – und öffnet den Gestaltungsmodus von WeintCodex.",
        },
    },
    {
        version = "6.9.0.4",
        date    = "02.10.2026",
        notes   = {
            "|cff7C6CFFDas Auktionshaus im ruhigen Stil.|r Ohne Metall, Marmor und Holz: die Kategorien links als schlichte Kacheln, die gewählte mit feinem Goldrand, Listen und Geld auf ruhigen Flächen, die Spaltenköpfe flach. Suche, Filter, Preise und Kaufen bleiben, wie sie sind.",
            "|cff7C6CFFKeine Fehlermeldung mehr beim Anvisieren.|r Seit dem letzten Update meldete das Spiel beim Anvisieren mancher NPCs (etwa des Auktionators) einen Fehler im Zielrahmen. Behoben – der rote Zauberbalken des Spiels über dem Ziel bleibt trotzdem weg.",
        },
    },
    {
        version = "6.9.0.3",
        date    = "02.10.2026",
        notes   = {
            "|cff7C6CFFKein Zauberbalken des Spiels mehr über dem Ziel.|r Unterbrichst du dein Ziel, erschien über dem Zielrahmen noch der rote Balken des Spiels. Er ist jetzt an Ziel und Fokus ganz weg – es bleibt der eigene.",
            "|cff7C6CFFDie Oberfläche hat ein Logo.|r Das Symbol an der Minikarte zeigt jetzt das WCUI-Wappen statt eines Zahnrads; dasselbe Wappen steht oben im Willkommens-Assistenten und in den Einstellungen der Oberfläche (/wcui).",
        },
    },
    {
        version = "6.9.0.2",
        date    = "01.10.2026",
        notes   = {
            "|cff7C6CFFAutomark fragt jetzt nach – ohne Fehlermeldung.|r Das Spiel lässt Addons nicht selbst markieren; beim Betreten eines Dungeons gab es deshalb eine Fehlermeldung, und markiert wurde nichts. Jetzt fragt Automark beim Betreten nach, wer welche Markierung bekäme – „Markieren“ setzt sie, „Nicht jetzt“ lässt dich bis zum nächsten Betreten in Ruhe. Auf eine Taste legen: /click WeintCodexAutoMarkButton in einem Makro.",
            "|cff7C6CFFHandeln im ruhigen Stil.|r Das Handelsfenster ohne Metall, Marmor und Leder: die Plätze flach wie die Aktionsknöpfe, die Namen der Gegenstände auf schlichten Leisten, das Geld auf einer ruhigen Fläche, feine Kante in Gold. Gegenstände, Geld und die Knöpfe zum Handeln bleiben, wie sie sind.",
            "|cff7C6CFFAuch im Fensterbericht fehlt kein Abschnitt mehr.|r Er nennt die Abschnitte ohne Linie jetzt in fester Reihenfolge.",
        },
    },
    {
        version = "6.9.0.1",
        date    = "01.10.2026",
        notes   = {
            "|cff7C6CFFDer Willkommens-Assistent kommt auch nach einem Neuladen.|r Wer WeintCodex im laufenden Spiel aktualisiert und neu lädt, bekommt ihn jetzt gleich zu sehen – nicht erst beim nächsten Einloggen. Nach „Später“ fragt er bis dahin nicht noch einmal.",
        },
    },
    {
        version = "6.9.0.0",
        date    = "01.10.2026",
        notes   = {
            "|cff7C6CFFDie WeintCodex-Oberfläche ist wieder freiwillig.|r Das Spiel merkt sich Einstellungen jetzt, also fragt WeintCodex einmal, ob du sie verwenden möchtest – auch, wenn du sie bisher hattest. Ein- und ausschalten kannst du sie jederzeit mit /wcui.",
            "|cff7C6CFFDein Profil bleibt deins.|r Die Oberfläche bekommt im Bearbeitungsmodus ihr eigenes Layout. Dein bisheriges Layout, deine Chatreiter und deine Spieleinstellungen werden nicht überschrieben – schaltest du sie aus, ist dein Layout wieder aktiv, und was WeintCodex an Einstellungen geändert hat, steht wie vorher.",
            "|cff7C6CFFEin Willkommens-Assistent nimmt dich an die Hand.|r Fünf kurze Schritte mit Bildern: was die Oberfläche kann und warum sie sich lohnt, dann – mit oder ohne sie – welche Anzeigen und Helfer du haben möchtest, jeweils mit einem Satz, was sie tun. Erst „Übernehmen“ stellt um; mit Oberfläche wird dabei gleich ihr Layout eingerichtet, ein Neuladen genügt. Wieder zeigen: /wcui willkommen.",
            "|cff7C6CFFEin Symbol für die Oberfläche an der Minikarte.|r Wer die Oberfläche nutzt, öffnet ihre Einstellungen mit einem Linksklick; ein Rechtsklick verschiebt die Rahmen. Ohne Oberfläche gibt es das Symbol nicht, abschalten geht unter /wcui → Allgemein.",
            "|cff7C6CFFBeute, Makros und Optionen im ruhigen Stil.|r Das Makrofenster ohne Metall, Marmor und Steinplätze – die Plätze flach wie die Aktionsknöpfe, Liste und Textfeld auf ruhigen Flächen. Das Beutefenster liegt ohne Metallrahmen und Sand auf einer ruhigen Fläche mit feiner Kante in Gold, die Gegenstände ohne eigene Rahmen. Die Optionen des Spiels (Esc → Optionen) ebenso: Kategorien und Einstellungen auf ruhigen Flächen, Gameplay, Zugänglichkeit und System als Abschnitte statt brauner Balken. Schalter, Regler und Farben der Qualität bleiben.",
            "|cff7C6CFFKomfort auch ohne Oberfläche.|r Schadensanzeige, Erinnerungen, Questpfeil, Klickzauber mit Entfluchen, Makro-Helfer, Automark und die kleinen Helfer stehen jetzt unter Komfort und laufen auch mit den Rahmen des Spiels – Klickzauber dann direkt auf dessen Gruppenrahmen. Das Komplettpaket ist mit der Oberfläche von Haus aus an; ohne sie wählst du selbst.",
            "|cff7C6CFFJeder Abschnitt hat wieder seine Linie.|r Im Questlog fehlte bei manchen Zonen die feine Linie hinter Name und Raute – je nachdem, wo die Zeile gerade lag. Behoben für alle Listen mit Abschnitten: Questlog, Ruf, Fertigkeiten, Abzeichen, Berufe, Gilde, Gruppensuche, Sammlung, PvP und die Optionen des Spiels.",
        },
    },
    {
        version = "6.8.1.0",
        date    = "01.10.2026",
        notes   = {
            "|cff7C6CFFNamensplaketten mit Leben.|r Was ein Treffer nimmt, bleibt einen Moment hell stehen und schmilzt dann weg; das Leben gleitet, statt zu springen. Dein Ziel atmet: das Leuchten pulsiert, eine feine Kante trägt deine Klassenfarbe, ab und zu läuft ein Glanz über den Balken, jeder Treffer blitzt kurz auf und die Zielmarken bewegen sich. Jeder Effekt lässt sich einzeln abschalten.",
            "|cff7C6CFFAutomark.|r Betrittst du als Gruppenleiter einen Dungeon oder Schlachtzug, bekommen Tank und Heiler ihre Markierung – welche, wählst du. Markiert wird nur, wer vom Spiel eine Rolle hat; geraten wird nichts. Zu finden unter Komfort, von Haus aus aus.",
            "|cff7C6CFFMakro-Helfer.|r Statt Makrosprache drei Fragen: was, auf wen, welcher Zauber. Der Text entsteht Zeile für Zeile erklärt, ein Klick legt das Makro an, ein zweiter legt es auf den Mauszeiger. Unter Aktionsleisten, Seite „Makros“.",
            "|cff7C6CFFEntfluchen auf Klick.|r Ein Schalter bei den Klickzaubern legt die Zauber deiner Klasse gegen Flüche, Gifte, Krankheiten und Magie auf Strg + Links und Rechts – ein Klick auf den Gruppenrahmen entflucht. Deine eigene Belegung bleibt, wie sie ist.",
        },
    },
    {
        version = "6.8.0.9",
        date    = "29.09.2026",
        notes   = {
            "|cff7C6CFFQuests an der Karte ohne Pergament.|r Öffnest du eine Quest, liegt ihr Text auf derselben ruhigen Fläche mit feiner Kante in Gold wie der Questlog – ohne Pergament, ohne braunen Balken, ohne Metallstriche zwischen den Knöpfen, in heller Schrift. Farben, die etwas sagen, bleiben.",
            "|cff7C6CFFDie Karte läuft jetzt wirklich weich vor der Quest aus.|r Der weiche Rand endet vor der geöffneten Quest statt unter ihr.",
        },
    },
    {
        version = "6.8.0.8",
        date    = "29.09.2026",
        notes   = {
            "|cff7C6CFFDie Karte bleibt weich, auch neben einer Quest.|r Öffnest du eine Quest auf der Karte, legt sich die Beschreibung über den rechten Teil der Karte – der weiche Rand lief bisher darunter aus, zu sehen war eine harte Kante. Jetzt läuft die Karte vor der Beschreibung weich aus.",
        },
    },
    {
        version = "6.8.0.7",
        date    = "29.09.2026",
        notes   = {
            "|cff7C6CFFDer dunkle Grund unter den Bäumen bleibt beim Baum.|r Er ist so breit wie ein Baum, beginnt am Symbol und läuft nach rechts weich aus, statt als Balken weit über den Baum hinaus zu reichen; die Linie hinter dem Namen endet vor ihm.",
        },
    },
    {
        version = "6.8.0.6",
        date    = "29.09.2026",
        notes   = {
            "|cff7C6CFFDer Händler in der ruhigen Oberfläche.|r Kein brauner Schein deiner Klasse mehr über den Waren; sie liegen auf einer Fläche mit weichem Schatten und feiner Kante in Gold, das Geld unten auf einer ruhigen Innenfläche statt auf Leder, und die Reiter „Händler“ und „Rückkauf“ sind flach, der gewählte in Gold. Plätze, Preise, Reparieren und Müll verkaufen bleiben, wie das Spiel sie zeigt – auch das Rot an Waren, die du nicht benutzen kannst.",
        },
    },
    {
        version = "6.8.0.5",
        date    = "29.09.2026",
        notes   = {
            "|cff7C6CFFDie Bäume stehen sichtbar auf dem Nebel.|r Symbol, Name und Linie jedes Baums liegen auf einem dunklen, weichen Grund, die Linie in deiner Klassenfarbe ist kräftiger, und das Licht deiner Klasse oben leuchtet jetzt durch den Nebel, statt in ihm zu verschwinden. Wolken, Funken und Talente bleiben, wie sie sind.",
        },
    },
    {
        version = "6.8.0.4",
        date    = "29.09.2026",
        notes   = {
            "|cff7C6CFFDie Talente zeigen jetzt, was versprochen war.|r Die Namen der Bäume – etwa Waffen, Furor, Schutz – tragen jetzt wirklich Raute und Linie in deiner Klassenfarbe, und das Licht deiner Klasse liegt über dem Nebel statt unsichtbar darunter. Wolken, Funken und Talente bleiben, wie sie sind.",
            "|cff7C6CFFGespräche in der ruhigen Oberfläche.|r Kein brauner Schein deiner Klasse mehr über Stadtwachen, Gastwirten und Lehrern; Begrüßung und Optionen liegen auf einer Fläche mit weichem Schatten und feiner Kante in Gold, oben am Fenster ebenfalls Gold – wie Spielmenü und Dialoge. Auch Questtexte, Bücher und Briefe tragen Gold statt deiner Klasse.",
        },
    },
    {
        version = "6.8.0.3",
        date    = "29.09.2026",
        notes   = {
            "|cff7C6CFFDie Talente passen zum Zauberbuch.|r Statt des großen Scheins in deiner Klassenfarbe fällt ein Hauch Licht in deiner Klasse von oben, oben liegt eine feine Kante in deiner Klasse, und die Namen der Bäume – etwa Waffen, Furor, Schutz – tragen Raute und Linie wie die Überschriften im Zauberbuch.",
            "|cff7C6CFFDie Animation bleibt.|r Wolken, Funken und die Landschaften hinter den Bäumen sind unverändert, ebenso die Talente mit ihren farbigen Rahmen, die Punkte je Baum und „Änderungen anwenden“.",
        },
    },
    {
        version = "6.8.0.2",
        date    = "29.09.2026",
        notes   = {
            "|cff7C6CFFDie Sammlung in der ruhigen Oberfläche.|r Kein Schein in deiner Klassenfarbe mehr oben im Fenster; die Vorlagen liegen auf einer Fläche mit weichem Schatten und feiner Kante in Gold, gewählte Reiter tragen Gold – wie Suche nach Gruppe, Gilde und Karte. Plätze, Klassenauswahl, Suche, Filter und Blättern bleiben, wie das Spiel sie zeigt.",
        },
    },
    {
        version = "6.8.0.1",
        date    = "29.09.2026",
        notes   = {
            "|cff7C6CFF„Gruppen durchsuchen“ und „Spielersuche“ ohne Stein.|r Der graue Stein, der Marmor und die goldenen Linien über und unter der Liste sind weg; beide Reiter liegen auf derselben ruhigen Fläche mit weichem Schatten und feiner Kante in Gold wie der erste Reiter. Texte, Filter, Suche und Knöpfe bleiben, wie das Spiel sie zeigt.",
        },
    },
    {
        version = "6.8.0.0",
        date    = "29.09.2026",
        notes   = {
            "|cff7C6CFF„Suche nach Gruppe“ in der ruhigen Oberfläche.|r Kein Schein in deiner Klassenfarbe mehr oben im Fenster, sondern ein Hauch neutrales Licht; die Flächen im Fenster tragen einen weichen Schatten und oben eine feine Kante in Gold, der gewählte Seitenreiter ebenfalls Gold – wie Spielmenü, Gilde und Karte.",
            "|cff7C6CFFRollen und Hinweise unverändert.|r Rollensymbole, die Fahne für neue Spieler, die Auswahl der Rolle, Texte und Knöpfe bleiben, wie das Spiel sie zeigt.",
        },
    },
    {
        version = "6.7.9.0",
        date    = "29.09.2026",
        notes   = {
            "|cff7C6CFFDas Spielmenü in der ruhigen Oberfläche.|r Statt des Scheins in deiner Klassenfarbe ein Hauch Licht von oben und eine feine Kante in Gold; unter „Spielmenü“ eine Linie mit Raute, und zwischen den Gruppen – Optionen, Addons bis Makros, Ausloggen und Spiel verlassen, Zurück zum Spiel – je eine zarte Trennlinie.",
            "|cff7C6CFFDialoge wie „20 Sekunden bis zum Verlassen“ passen dazu.|r Kein Schein in der Klassenfarbe mehr über dem ganzen Dialog, sondern dasselbe ruhige Licht und dieselbe Kante in Gold. Texte, Knöpfe und was sie tun bleiben unverändert.",
            "|cff7C6CFFKarte & Questlog im selben Stil.|r Der Questlog liegt auf einer ruhigen, leicht angehobenen Fläche mit feiner Kante in Gold; Zonen wie „Die Todesminen“ stehen links als Abschnitte mit Raute und Linie, wie im Ruf. Der weiche Rand um die Karte bleibt genau so, wie er ist, und die Farben der Quests zeigen weiter ihre Schwierigkeit.",
        },
    },
    {
        version = "6.7.8.0",
        date    = "29.09.2026",
        notes   = {
            "|cff7C6CFFEin bisschen Klassenfarbe im Zauberbuch.|r Von oben fällt ein Hauch Licht in deiner Klassenfarbe, die Fläche mit deinen Zaubern trägt oben eine feine Kante in deiner Klasse – wie die Karten in Ruf und Fertigkeiten. Nicht mehr der große Schein über der halben Seite.",
            "|cff7C6CFFDie Linie hinter „Allgemein“ ist da.|r Hinter Überschriften im Zauberbuch und hinter Schmiedekunst und Bergbau in der Berufsübersicht fehlte die feine Linie nach der Raute – sie war falsch befestigt und wurde nicht gezeichnet.",
            "|cff7C6CFFGilde & Communitys in der ruhigen Oberfläche.|r Liste, Chat und Mitglieder liegen auf eigenen, leicht angehobenen Flächen mit weichem Schatten und feiner Kante in Gold; dezente Randabdunklung und ein Hauch Licht. Die Gilde gehört nicht zu deiner Klasse – deshalb Gold statt Klassenfarbe, auch am gewählten Eintrag links und am Seitenreiter, und kein Schein in der Klassenfarbe mehr.",
            "|cff7C6CFFNamen und Farben bleiben.|r Chat, Mitgliederliste, Wappen, Kronen und „online“ zeigen alles, wie das Spiel es zeigt; die Mitgliederliste behält innen ihren gewohnten Grund.",
        },
    },
    {
        version = "6.7.7.0",
        date    = "29.09.2026",
        notes   = {
            "|cff7C6CFFDas Zauberbuch in der ruhigen Oberfläche.|r Statt des großen Scheins in deiner Klassenfarbe über der halben Seite liegen deine Zauber auf derselben ruhigen, leicht angehobenen Fläche wie Ruf und Fertigkeiten, mit dezenter Randabdunklung und einem Hauch Licht. Überschriften wie „Allgemein“ tragen Raute und Linie in deiner Klassenfarbe.",
            "|cff7C6CFFZauber unverändert.|r Symbole, Namen, „Passiv“, der Schein an Zaubern, die noch auf keiner Leiste liegen, Reiter, Suche und Blättern bleiben, wie das Spiel sie zeigt. Die Talente behalten ihr Aussehen.",
            "|cff7C6CFFIm Berufsfenster kein Schein in der Klassenfarbe mehr.|r Es trägt nur noch sein Gold.",
        },
    },
    {
        version = "6.7.6.0",
        date    = "29.09.2026",
        notes   = {
            "|cff7C6CFFDie Berufsübersicht passt zur Rezeptseite.|r Jeder Beruf liegt auf einer ruhigen, leicht angehobenen Karte mit weichem Schatten statt der braunen Fläche; der Name des Berufs ist die Überschrift der Karte, mit Raute und Linie in Gold. Die Bilder hinter den Nebenberufen sind weg – hinter Text steht nichts mehr.",
            "|cff7C6CFFFortschrittsbalken mit Tiefe, Farbe unverändert.|r Wie bei den Fertigkeiten: Schatten und Lichtkante an der Füllung; Farbe, Glanz und Werte wie „Kochkunst 8/75“ bleiben, wie das Spiel sie zeigt. Symbole, Rang, Zauber und der Knopf zum Verlernen sind unverändert.",
        },
    },
    {
        version = "6.7.5.0",
        date    = "29.09.2026",
        notes   = {
            "|cff7C6CFFDie Rezepte deiner Berufe im neuen Stil.|r Die Rezeptliste liegt wie Ruf und Fertigkeiten auf einer ruhigen, leicht angehobenen Fläche, Kategorien wie „Alltägliche Mahlzeiten“ stehen als eigene Abschnitte mit Raute und Linie, Rezepte sind fein voneinander abgesetzt, das gewählte trägt einen schmalen Streifen. Rechts ist das Rezept eine Karte: Name oben größer in seiner Farbe, Beschreibung, darunter abgesetzt Reagenzien und was es braucht.",
            "|cff7C6CFFBerufe tragen Gold statt deiner Klassenfarbe.|r Sie gehören nicht zu deiner Klasse – deshalb ein ruhiges Gold für Abschnitte, Linien und den gewählten Seitenreiter. Das große Bild hinter dem Rezept und die Hintergründe der Seite sind weg, hinter Text steht nichts mehr. Rangbalken, Symbole, Reagenzien und Knöpfe bleiben, wie das Spiel sie zeigt.",
        },
    },
    {
        version = "6.7.4.0",
        date    = "29.09.2026",
        notes   = {
            "|cff7C6CFFDie Statistiken im neuen Stil.|r Die lange Liste liegt wie Ruf, Fertigkeiten und Abzeichen auf einer ruhigen, leicht angehobenen Fläche; „Charakter“ steht als Abschnitt mit Raute und Linie in deiner Klassenfarbe links, wo das Spiel ihn hinsetzt, die Einträge sind fein voneinander abgesetzt und leuchten unter der Maus in deiner Klasse auf. Werte, Gruppen wie „Vermögen“ und ihre Knöpfe zum Auf- und Zuklappen bleiben, wie das Spiel sie zeigt.",
        },
    },
    {
        version = "6.7.3.0",
        date    = "29.09.2026",
        notes   = {
            "|cff7C6CFFDie Abzeichen im neuen Stil.|r Deine Währungen liegen wie Ruf und Fertigkeiten auf einer ruhigen, leicht angehobenen Fläche; Gruppen stehen als eigene Abschnitte mit Raute und Linie in deiner Klassenfarbe, die Einträge sind fein voneinander abgesetzt, die gewählte Währung trägt einen schmalen Streifen. Symbol, Name und Anzahl bleiben, wie das Spiel sie zeigt.",
            "|cff7C6CFFDie Detailansicht der Abzeichen ist eine Karte.|r Name oben, darunter die Beschreibung, was folgt in einem eigenen, abgesetzten Bereich; die Karte endet unter ihrem Inhalt. Ist noch keine Währung gewählt, bleibt es bei der ruhigen Fläche mit dem Hinweis des Spiels.",
        },
    },
    {
        version = "6.7.2.2",
        date    = "29.09.2026",
        notes   = {
            "|cff7C6CFFDas PvP-Fenster ist jetzt wirklich im neuen Stil.|r Bisher erkannte WeintCodex den Reiter „Spieler gegen Spieler“ nicht und ließ ihn, wie er war. Jetzt steht dein Wappen als Mittelpunkt vor einem weichen dunklen Hof, Rang, Medaillon und Rangpunkte liegen gemeinsam auf einer ruhigen, leicht angehobenen Fläche.",
            "|cff7C6CFFRang und Belohnung rechts als Karte wie bei Ruf und Fertigkeiten.|r Der Rang oben größer, darunter eine feine Linie und die Beschreibung; „Nächste Belohnungen auf Rang …“ steht als Abschnitt mit Raute und Linie in deiner Klassenfarbe, die Belohnung auf einer eigenen, leicht vertieften Fläche. Farben und Texte des Spiels bleiben unverändert.",
        },
    },
    {
        version = "6.7.2.1",
        date    = "29.09.2026",
        notes   = {
            "|cff7C6CFFDie Detailansicht im Ruf ist gegliedert wie die Fertigkeiten.|r Fraktionsname, Rufstufe und Rufbalken bilden gemeinsam den Kopf der Karte, die feine Linie in deiner Klassenfarbe steht jetzt unter dem Balken, darunter beginnt die Beschreibung. Die Farben der Rufstufen bleiben, wie das Spiel sie zeigt.",
            "|cff7C6CFFDie Karte im Ruf endet immer unter ihrem Inhalt.|r Auch wenn „Im Krieg“, „Inaktiv“ und „Als Erfahrungsleiste anzeigen“ an ihrem gewohnten Platz bleiben, reicht die Fläche nur bis knapp unter die Optionen.",
        },
    },
    {
        version = "6.7.2.0",
        date    = "29.09.2026",
        notes   = {
            "|cff7C6CFFDas PvP-Fenster ist ein PvP-Profil.|r Dein Rangsymbol steht als Mittelpunkt vor einem weichen dunklen Hof mit einem Hauch Licht; Symbol, Rang, Rangpunkte und Fortschritt liegen gemeinsam auf einer ruhigen, leicht angehobenen Fläche unter einer feinen Linie mit Raute. Die Rangpunkte sind etwas größer, ihre Farbe bleibt, wie das Spiel sie zeigt.",
            "|cff7C6CFFRang und Belohnung rechts als Karte.|r Der Rang oben groß in seiner Farbe, darunter eine feine Linie und die Beschreibung; vor „Nächste Belohnungen“ eine Linie mit Raute, die Belohnung – Symbol, Name in ihrer Qualitätsfarbe, Beschreibung – auf einer eigenen, leicht vertieften Fläche. Die Karte endet unter ihrem Inhalt.",
            "|cff7C6CFFEtwas mehr Atmosphäre im PvP.|r Eine kräftigere Randabdunklung und unten am Rand zwei kaum sichtbare, entfernte Fackeln – kein Bild, nichts hinter Text.",
        },
    },
    {
        version = "6.7.1.0",
        date    = "29.09.2026",
        notes   = {
            "|cff7C6CFFDie Fertigkeiten im neuen Stil.|r Berufe, Sekundäre Fertigkeiten und Waffenfertigkeiten stehen als eigene Abschnitte mit Raute und Linie in deiner Klassenfarbe, die Einträge sind fein voneinander abgesetzt, die gewählte Fertigkeit trägt einen schmalen Streifen in deiner Klasse. Die Liste liegt auf einer ruhigen, leicht angehobenen Fläche wie im Ruf.",
            "|cff7C6CFFFortschrittsbalken mit Tiefe, Farbe unverändert.|r Dunklere Bahn, Schatten und Lichtkante an der Füllung – die Farbe und die Werte wie „32 / 75“ bleiben genau so, wie das Spiel sie zeigt.",
            "|cff7C6CFFDie Detailansicht der Fertigkeiten ist eine Karte.|r Name und Fortschritt oben, darunter eine feine Linie, dann die Beschreibung; was darunter folgt, steht in einem eigenen, abgesetzten Bereich, und die Karte endet unter ihrem Inhalt.",
        },
    },
    {
        version = "6.7.0.3",
        date    = "29.09.2026",
        notes   = {
            "|cff7C6CFFDie Detailansicht im Ruf ist jetzt eine kompakte Karte.|r Name, Rufstufe, Fortschritt und Beschreibung stehen oben; „Im Krieg“, „Inaktiv“ und „Als Erfahrungsleiste anzeigen“ rücken direkt unter die Beschreibung in ihren eigenen, abgesetzten Bereich, und die Karte endet kurz darunter – kein leerer schwarzer Raum mehr bis zum unteren Rand. Ist eine Beschreibung lang, bleiben die Optionen an ihrem gewohnten Platz; sie funktionieren unverändert.",
        },
    },
    {
        version = "6.7.0.2",
        date    = "29.09.2026",
        notes   = {
            "|cff7C6CFFDie Detailansicht im Ruf ist eine Codex-Tafel.|r Der Fraktionsname steht größer als Hauptinformation, darunter die Rufstufe. Eine feine Linie in deiner Klassenfarbe trennt sie vom Rufbalken, der mit weichem Schatten deutlicher hervortritt. Die Beschreibung liegt auf einer eigenen, leicht vertieften Fläche; „Im Krieg“, „Inaktiv“ und „Als Erfahrungsleiste anzeigen“ stehen unter einer Linie mit Raute in einem eigenen, ruhigen Optionsbereich.",
            "|cff7C6CFFGruppen im Ruf sind eigene Abschnitte.|r Jede Gruppe beginnt mit einer feinen Linie und einem Hauch Licht von links; die Überschrift ist etwas größer. Zwischen den Fraktionen liegen zarte Trennlinien, die Einrückung des Spiels bleibt.",
            "|cff7C6CFFDie gewählte Fraktion leuchtet dezenter, aber klar.|r Schmaler Streifen und ein kurzer Schein in deiner Klassenfarbe, die Zeile eine Spur heller – kein farbiger Block mehr. Die Farben der Rufstufen (Neutral gelb, Freundlich grün …) bleiben, wie das Spiel sie zeigt.",
            "|cff7C6CFFMehr Tiefe im Ruf.|r Liste und Detailansicht liegen auf unterschiedlich dichten Flächen mit weichem Schatten; unten rechts in der Liste liegt, kaum sichtbar, ein Astrolab als Zeichen des Codex.",
        },
    },
    {
        version = "6.7.0.1",
        date    = "29.09.2026",
        notes   = {
            "|cff7C6CFFDer Ruf trägt deine Klassenfarbe.|r Er gehört zum Charakterfenster – Rauten und Linien der Gruppen, die gewählte Fraktion und die Zeile unter der Maus stehen jetzt in deiner Klasse statt in Gold. Rot beim Krieger, Grün beim Jäger, Weiß beim Priester.",
            "|cff7C6CFFMehr Tiefe statt Schwarz.|r Liste und Detailansicht liegen auf einer leicht helleren, weich auslaufenden Fläche mit einer feinen Lichtkante oben; darum herum sehr dunkles Anthrazit, eine dezente Randabdunklung und neutrales Licht von oben. Keine harten schwarzen Kästen mehr nebeneinander.",
            "|cff7C6CFFDie Detailansicht gehört zur selben Oberfläche.|r Kein eigener schwarzer Kasten mehr: dieselbe Fläche wie die Liste, oben eine feine Kante in deiner Klassenfarbe.",
            "|cff7C6CFFRufbalken mit Tiefe, jetzt wirklich.|r Schatten und Lichtkante an der Füllung, eine weichere Kante um die Bahn – Farbe und Text der Rufstufe bleiben, wie das Spiel sie zeigt.",
        },
    },
    {
        version = "6.7.0.0",
        date    = "29.09.2026",
        notes   = {
            "|cff7C6CFFDer Ruf im neuen Stil der Fenster.|r Dunkle, ruhige Fläche wie im Charakterfenster, die Liste liegt auf einem weich auslaufenden dunklen Grund, oben ein Hauch warmes Gold. Gruppen tragen eine Raute und eine feine goldene Linie und bleiben so eingerückt wie im Spiel – Gruppen in Gruppen sind wieder als solche zu erkennen.",
            "|cff7C6CFFDie gewählte Fraktion ist auf einen Blick zu sehen.|r Links ein goldener Strich, dahinter ein Hauch Gold – es ist die, die rechts in der Detailansicht steht. Unter der Maus wird jede Zeile heller.",
            "|cff7C6CFFRufbalken mit mehr Tiefe.|r Dunklere Bahn, Schatten und Lichtkante an der Füllung; Farbe und Text der Rufstufe bleiben, wie das Spiel sie zeigt.",
            "|cff7C6CFFDetailansicht als eigene dunkle Tafel.|r Statt des Dialograhmens, mit größerem Fraktionsnamen und einer goldenen Trennlinie darunter. Beschreibung, Häkchen und Knöpfe bleiben unverändert.",
        },
    },
    {
        version = "6.6.4.5",
        date    = "29.09.2026",
        notes   = {
            "|cff7C6CFFAlle Klassen haben jetzt ihre Szene im Charakterfenster.|r Krieger stehen in einer Waffenkammer mit Thron und Esse, Druiden in einem Hain mit Geweihtor, Magier in einer arkanen Halle unter einer Armillarsphäre, Schurken in einem nächtlichen Versteck mit Laternen, Hexenmeister vor einem grünen Portal, Paladine in einer Lichthalle vor dem Altar, Schamanen in einem Steinkreis unter dem Sturm. Jede Figur nimmt das Licht ihrer Szene an; Aufbau, Werte und deine Klassenfarbe als Akzent bleiben dieselben.",
        },
    },
    {
        version = "6.6.4.4",
        date    = "29.09.2026",
        notes   = {
            "|cff7C6CFFJäger bekommen ihre eigene Szene im Charakterfenster.|r Hinter deiner Figur steht ein Jägerlager im Wald – Tor mit Hirschbanner, zwei Wölfe, Wasserfall und Fackeln –, weich auslaufend wie beim Priester. Die Figur nimmt das Licht der Szene an: warme Sonne, ein Hauch Grün vom Laub, Schatten und Dunst am Boden. Aufbau und Werte bleiben dieselben; dein Grün erscheint nur in Linien, Rauten, belegten Plätzen und unter der Maus.",
        },
    },
    {
        version = "6.6.4.3",
        date    = "29.09.2026",
        notes   = {
            "|cff7C6CFFDie Kopfzeile im Charakterfenster zeigt immer deinen Namen.|r Nach einem Wechsel vom Reiter PvP stand dort „SPIELER GEGEN SPIELER“ – sie las den Fenstertitel statt deines Namens.",
            "|cff7C6CFFAndere Reiter bleiben, wie sie waren.|r Beim Wechsel auf Ruf, Währung oder PvP kommen nur die Zeilen zurück, die die Kopfzeile ersetzt hat, und zwar so, wie sie vorher waren.",
        },
    },
    {
        version = "6.6.4.2",
        date    = "29.09.2026",
        notes   = {
            "|cff7C6CFFDein Name steht nur noch einmal im Charakterfenster.|r Der kleine Titel des Spiels über dem Fenster ist ausgeblendet, solange die große Kopfzeile zu sehen ist; auf Ruf, Währung usw. steht er wie gewohnt.",
            "|cff7C6CFFKeine graue Fläche mehr oben rechts.|r Der helle Schein oben im Fenster ist aus, und die Werte liegen durchgehend von oben bis unten auf der dunklen Fläche, die weich in die Szene übergeht.",
        },
    },
    {
        version = "6.6.4.1",
        date    = "29.09.2026",
        notes   = {
            "|cff7C6CFFDer rechte Bereich des Charakterfensters beginnt mit „Allgemein“.|r Die doppelte Zeile mit Stufe und Klasse samt ihrer grauen Fläche ist weg – Name, Klasse und Stufe stehen nur noch einmal oben über der Figur.",
            "|cff7C6CFFWeicher Übergang statt Kante.|r Kein heller Schein mehr oben im Fenster; die Werte liegen auf einer leichteren, dunklen Fläche, und zwischen Figur und Werten verläuft eine breitere dunkle Zone. Deine Klassenfarbe bleibt nur in Linien, Rauten und aktiven Zuständen.",
        },
    },
    {
        version = "6.6.4.0",
        date    = "29.09.2026",
        notes   = {
            "|cff7C6CFFDas Charakterfenster ist neu aufgebaut.|r Deine Figur steht im Mittelpunkt einer Szene statt vor einem grauen Fenster: sehr dunkle, ruhige Basis, die Szene deiner Klasse läuft zu den Rändern dunkel aus und ist hinter der Figur ruhiger, ein Schatten unter den Füßen und Dunst am Boden stellen sie hinein. Die Werte liegen rechts auf einer dunklen Glasebene über der Szene.",
            "|cff7C6CFFName, Klasse und Stufe einmal, oben.|r Dein Name steht groß über der Figur, darunter z. B. „PRIESTERIN · STUFE 13“ und eine feine Linie in deiner Klassenfarbe – nicht mehr zusätzlich rechts.",
            "|cff7C6CFFDeine Klassenfarbe als Akzent, nicht als Anstrich.|r Belegte Ausrüstungsplätze tragen einen feinen Rand in deiner Klassenfarbe, unter der Maus voll; leere Plätze bleiben neutral und gedämpft. Die Namen der Werte sind ruhig grau statt gold.",
        },
    },
    {
        version = "6.6.3.6",
        date    = "29.09.2026",
        notes   = {
            "|cff7C6CFFDeine Figur steht im Bild statt davor.|r Im Charakterfenster nimmt die Figur das Licht des Hintergrunds an: gedämpftes, warmes Umgebungslicht und goldenes Hauptlicht statt neutraler Studiobeleuchtung, dazu ein warmer Schein hinter ihr, ein Schatten unter den Füßen und leichter Dunst am Boden. Nur bei Klassen mit eigenem Bild.",
            "|cff7C6CFFDie Zeile unter deinem Namen bleibt lesbar.|r Klasse und Stufe liegen jetzt über der Figur – vorher konnte eine Waffe auf dem Rücken einen Buchstaben verdecken.",
        },
    },
    {
        version = "6.6.3.5",
        date    = "29.09.2026",
        notes   = {
            "|cff7C6CFFDas Charakterfenster bekommt Atmosphäre.|r Hinter deiner Figur steht ein eigenes Bild deiner Klasse – für Priester eine Kathedrale mit Lichtkreuz und Kerzen –, das zu den Rändern weich ausläuft. Klassen ohne eigenes Bild behalten den Hintergrund des Spiels; weitere folgen.",
            "|cff7C6CFFName, Klasse und Stufe als Kopfzeile.|r Dein Name steht größer über dem Fenster, darunter in deiner Klassenfarbe z. B. „PRIESTERIN · STUFE 13“ mit einer Zierlinie – nur auf dem Reiter Charakter.",
        },
    },
    {
        version = "6.6.3.4",
        date    = "29.09.2026",
        notes   = {
            "|cff7C6CFFDie Questliste reicht nicht mehr bis zum Boden.|r Die Einrichtung gibt ihr jetzt eine Höchsthöhe – von unter der Minikarte bis über den Tooltip unten rechts; was nicht passt, blendet das Spiel aus. Sofort, ohne neue Einrichtung: Bearbeitungsmodus → Zielverfolgung → „Höhe“.",
            "|cff7C6CFFDialoge des Spiels im Stil von WeintCodex.|r Rückfragen wie „19 Sekunden bis zum Verlassen“, Einladungen oder „Gegenstand zerstören?“ stehen auf der dunklen Kachel mit dem Schein deiner Klassenfarbe statt im Diamantrahmen, die roten Knöpfe sind flach. Was die Dialoge tun, bleibt unberührt.",
        },
    },
    {
        version = "6.6.3.3",
        date    = "29.09.2026",
        notes   = {
            "|cff7C6CFFDie Sammlung im Stil von WeintCodex.|r Das Fenster der Vorlagen trägt die dunkle Kachel mit dem Schein deiner Klassenfarbe; Metallrahmen, Porträt, Marmor und das Leder mit den Eckverzierungen hinter den Vorlagen sind weg, innen liegt eine ruhige Innenfläche.",
            "|cff7C6CFFDas Spielmenü (Esc) im Stil von WeintCodex.|r Statt Diamantmetall-Rahmen und roten Knöpfen dieselbe dunkle Kachel wie jedes andere Fenster, mit dem Schein deiner Klassenfarbe oben; die Knöpfe sind flach und werden unter der Maus heller.",
            "|cff7C6CFFMitgliederliste wieder wie im Spiel.|r In Gilde & Communitys trägt die Mitgliederliste wieder ihren eigenen Hintergrund statt der dunkleren Fläche von WeintCodex.",
        },
    },
    {
        version = "6.6.3.2",
        date    = "28.09.2026",
        notes   = {
            "|cff7C6CFFDie Karte läuft jetzt wirklich weich aus.|r Der Rand war dunkel – neben dem hellen Kopf des Fensters wirkte das wieder wie eine Kante. Jetzt blendet die Karte selbst an allen vier Seiten aus, genau wie das Charakterbild, und geht in den Grund des Fensters samt Schein über. Questmarken bleiben scharf.",
        },
    },
    {
        version = "6.6.3.1",
        date    = "28.09.2026",
        notes   = {
            "|cff7C6CFFDie Karte läuft weich in den Rahmen aus.|r Wie beim Charakterbild endet die Weltkarte (M) nicht mehr mit harter Kante: an allen vier Seiten geht sie in einem weichen Verlauf in das Fenster über. Die Knöpfe auf der Karte bleiben klar, die Karte selbst bleibt unverändert.",
            "|cff7C6CFFAlles in deiner Klassenfarbe.|r Die Farbe von WeintCodex ist jetzt überall die deiner Klasse: das WeintCodex-Fenster und die Einstellungen, Knöpfe, gewählte Reiter und Einträge, Überschriften, Zauber- und Erfahrungsbalken, Zielleuchten, Chatmeldungen, sogar diese Hervorhebung hier. Grün, Rot, Gold und Blau bleiben, weil sie etwas bedeuten. Unter Allgemein → „Farbe der Oberfläche“ gibt es das Lila zurück.",
        },
    },
    {
        version = "6.6.3.0",
        date    = "28.09.2026",
        notes   = {
            "|cff7C6CFFÜberschriften in Charakter, Ruf und Fertigkeiten fallen auf.|r Größerer Titel mit Schatten, dahinter ein weicher Lichthof in deiner Klassenfarbe, links und rechts eine Raute mit dunklem Kern, ein kleiner Punkt und eine leuchtende Linie. Zu lange Titel werden etwas kleiner, damit nichts über die Spalte ragt.",
        },
    },
    {
        version = "6.6.2.9",
        date    = "28.09.2026",
        notes   = {
            "|cff7C6CFFRuf und Fertigkeiten mit derselben Zierlinie.|r Die Überschriften der Ruf- und Fertigkeitenliste tragen jetzt dasselbe Design wie die Werte im Charakterfenster: Titel mittig, feine Linien mit Rauten in deiner Klassenfarbe. Das Zeichen zum Auf- und Zuklappen bleibt rechts, unter der Maus wird die Zeile heller.",
        },
    },
    {
        version = "6.6.2.8",
        date    = "28.09.2026",
        notes   = {
            "|cff7C6CFFKategorien im Charakterfenster als Zierlinie.|r Statt eines dunklen Balkens steht der Titel wieder mittig, links und rechts läuft je eine feine Linie in deiner Klassenfarbe nach außen aus, am Titel sitzt eine kleine Raute – gegliedert, ohne Löcher ins Fenster zu schneiden.",
        },
    },
    {
        version = "6.6.2.7",
        date    = "28.09.2026",
        notes   = {
            "|cff7C6CFFDer Questpfeil plant selbst.|r Statt stur der Quest zu folgen, die das Spiel gerade verfolgt – oft am anderen Ende des Gebiets –, zeigt er auf das nächste lohnende Ziel aus deinem ganzen Questlog: offene Quests an ihrem Zielgebiet, erfüllte an der Abgabe. Quests weit über deiner Stufe und Gruppenquests zählen weiter weg, und er springt nicht wegen ein paar Metern hin und her. Klickst du selbst eine Quest an, gilt sie bis zur Abgabe. /wcui pfeil weiter überspringt ein Ziel; unter Komfort → Questpfeil → „Welches Ziel“ gibt es das alte Verhalten zurück.",
            "|cff7C6CFFKategorien im Charakterfenster heben sich ab.|r „Allgemein“, „Primäre Eigenschaften“, „Waffen“ und die anderen Überschriften der Werte stehen jetzt auf einem eigenen Band mit einem Streifen in deiner Klassenfarbe, links ausgerichtet und etwas größer – die Werte darunter lesen sich als Gruppe.",
        },
    },
    {
        version = "6.6.2.6",
        date    = "28.09.2026",
        notes   = {
            "|cff7C6CFFOffene Fenster fressen keinen Speicher mehr.|r Solange ein Spielfenster offen war, wuchs der Speicher schnell an, und das Spiel ruckelte kurz, wenn es aufräumte. Das ist behoben: Nachgesehen wird nur noch in offenen Fenstern, dicht nach dem Öffnen und nach einem Klick, sonst alle zwei Sekunden.",
        },
    },
    {
        version = "6.6.2.5",
        date    = "28.09.2026",
        notes   = {
            "|cff7C6CFFWeicher Rand ums Charaktermodell, dritter Anlauf.|r Das Hintergrundbild ist an seinen Rändern selbst fast schwarz, ein dunkler Übergang darüber änderte nichts. Jetzt läuft das Bild selbst an allen vier Seiten aus, und darunter erscheint der Grund des Fensters samt Schein. Deine Figur bleibt scharf.",
        },
    },
    {
        version = "6.6.2.4",
        date    = "28.09.2026",
        notes   = {
            "|cff7C6CFFWeicher Rand ums Charaktermodell, jetzt sichtbar.|r Der Übergang saß an der richtigen Stelle, war im Spiel aber nicht zu sehen. Er liegt jetzt auf der obersten Ebene über dem Hintergrundbild, sodass das Bild an allen vier Seiten in den Rahmen ausläuft.",
        },
    },
    {
        version = "6.6.2.3",
        date    = "28.09.2026",
        notes   = {
            "|cff7C6CFFRahmen in deiner Klassenfarbe.|r Gewählte Reiter, das Zielleuchten der Plaketten, deine Zeile in der Schadensanzeige und die Rahmen im Gestaltungsmodus tragen jetzt die Farbe deiner Klasse statt Lila. Unter Allgemein → „Rahmen und Hervorhebungen“ lässt sich das Lila zurückholen.",
            "|cff7C6CFFVerlauf der Schadensanzeige zeigt den ganzen Kampf.|r Das Spiel nennt die Zahlen im Kampf nur verdeckt – deshalb stand bisher nur eine Säule am Ende. Jetzt zeigt der Verlauf die Summe über den Kampf: steil heißt viel Schaden, flach heißt keiner.",
            "|cff7C6CFFGilde & Communitys: Wappen zurück, Liste links neu.|r Das Gildenwappen oben links ist wieder da. Die Einträge links sind schlichte Kacheln, der gewählte im Akzent; das Wappen im Eintrag bleibt.",
            "|cff7C6CFFWeicherer Rand ums Charaktermodell.|r Der Übergang sitzt jetzt an den Kanten des Hintergrundbilds selbst und ist breiter – auch oben und rechts.",
        },
    },
    {
        version = "6.6.2.2",
        date    = "28.09.2026",
        notes   = {
            "|cff7C6CFFPlaketten nach NPC.|r Neuer Reiter „NPCs“ bei den Namensplaketten. Gegner, die zaubern, sind jetzt blau – was unterbrochen werden muss, fällt sofort auf. Erkannt am NPC selbst oder daran, dass er schon einmal einen Zauber begonnen hat. Dazu eigene Farben: Namen eingeben, WeintCodex findet den NPC unter denen, die du schon gesehen hast, oder du übernimmst dein Ziel.",
            "|cff7C6CFFSeitenreiter zeigen die richtige Wahl.|r Bei den Berufen standen alle Reiter im Akzent. Jetzt ist nur der gewählte markiert – und wenn das Spiel nicht eindeutig sagt, welcher es ist, keiner statt aller.",
            "|cff7C6CFFSuche nach Gruppe im neuen Stil.|r Der Dungeonbrowser als Kachel statt Metall und Marmor, die Kategorien mit schlichtem Rand und gedämpften Bildern, die Reiter rechts wie bei den Berufen.",
            "|cff7C6CFFFeinschliff an Questlog und Gilde.|r Suchfeld flach, braune Pfeilknöpfe und die goldenen Bildlaufleisten grau, das Wappen oben links an Gilde & Communitys weg.",
        },
    },
    {
        version = "6.6.2.1",
        date    = "28.09.2026",
        notes   = {
            "|cff7C6CFFWeintCodex auf Forever-Niveau.|r Die Navigation ist neu geordnet: oben steht, was beim Leveln hilft – Übersicht, Charakter, Lehrer, Dungeons, Gruppencheck. Schlachtzüge, Anmeldung und Kalender stehen darunter in einer eigenen Gruppe – weg ist nichts.",
            "|cff7C6CFFNeue Übersicht fürs Leveln.|r Oben deine Stufe, Erfahrung, Erholung und die Quests, die zur Abgabe bereit sind. Darunter: was du beim Lehrer noch nicht gelernt hast, deine Ausrüstung und die Dungeons, die zu deiner Stufe passen. Die Zahl lernbarer Zauber steht auch links am Lehrer.",
            "|cff7C6CFFLehrer rechnet mit.|r Oben in der Zauberliste steht die Rechnung: was jetzt lernbar ist, dein Gold, und was danach bleibt oder fehlt – dazu, für wie viele Zauber es reicht und was die nächsten zwei Stufen zusammen kosten. Preise werden rot, sobald dein Gold der Reihe nach nicht mehr reicht.",
            "|cff7C6CFFWeltkarte im neuen Stil.|r Karte & Questlog (M) als Kachel statt Metall und Pergament, die Leiste „Welt › …“ mit flachen Knöpfen. Die Karte selbst bleibt, wie sie ist. Einzeln abschaltbar unter Tooltip & Fenster.",
            "|cff7C6CFFBerufe und Gilde & Communitys im neuen Stil.|r Beide Fenster als Kachel statt Metall und Holz: Fortschrittsbalken flach, Berufssymbole mit schlichtem Rand, die Reiter am rechten Rand als kleine Kacheln – der gewählte im Akzent. Die Bilder der Berufe bleiben gedämpft sichtbar, fehlende Reagenzien bleiben rot.",
            "|cff7C6CFFAufschlüsselung der Schadensanzeige ausgebaut.|r Frei verschiebbar (Rechtsklick setzt sie zurück), dazu drei Ansichten: Zauber, Verlauf – Schaden oder Heilung je Sekunde über den Kampf als Säulen – und Auren: alle Buffs samt Essen und Fläschchen, so wie sie vor dem Kampf waren. Mit „Vergleich“ stehen zwei Spieler nebeneinander: Kennzahlen, Zauber, Verlauf und Auren.",
            "|cff7C6CFFWeicher Rand ums Charaktermodell.|r Der Hintergrund hinter deinem Charakter läuft an den Kanten weich in das Fenster aus, statt hart abzubrechen.",
            "|cff7C6CFFRänge direkt am Zauber.|r Klickst du in der Zaubertafel der Klickzauber auf einen Zauber mit mehreren Rängen, klappt am Symbol die Liste der Ränge auf – „Höchster Rang“ steigt mit, jeder andere bleibt fest. Zauber mit nur einem Rang liegen wie bisher sofort auf der Taste.",
        },
    },
    {
        version = "6.6.2.0",
        date    = "28.09.2026",
        notes   = {
            "|cff7C6CFFKlickzauber mit Rang.|r Unter der Zaubertafel wählst du für die belegte Taste einen Rang – zum Beispiel einen kleinen Heilzauber, der Mana spart. Ohne Wahl wirkt die Taste wie bisher den höchsten Rang und steigt mit, wenn du einen neuen lernst.",
        },
    },
    {
        version = "6.6.1.9",
        date    = "28.09.2026",
        notes   = {
            "|cff7C6CFFDeutlich weniger Speicher.|r Die Messung hat es gezeigt: fast neun Zehntel des Wegwerf-Speichers kamen vom Einblenden der Aktionsleisten bei Maus darüber – bei jedem Bild. Das ist behoben, und der Questpfeil rechnet nur noch fünfmal je Sekunde alles neu; dazwischen dreht er sich nur.",
        },
    },
    {
        version = "6.6.1.8",
        date    = "28.09.2026",
        notes   = {
            "|cff7C6CFFWeniger Speicher im Kampf.|r Erinnerungen, Schadensanzeige und Aktionsleisten fassen Ereignisse zusammen, die im Kampf dutzendfach je Sekunde kommen, statt jedes einzeln auszuwerten. /wcui speicher misst 30 Sekunden lang, welcher Teil wie viel Speicher belegt.",
        },
    },
    {
        version = "6.6.1.7",
        date    = "28.09.2026",
        notes   = {
            "|cff7C6CFFNur deine ausgewählten Buffs am Spielerrahmen.|r Über dem Spielerrahmen stehen klein die Buffs, die du im Abklingzeitmanager des Spiels auswählst (z. B. Schild, Inneres Feuer) – auch im Kampf. Alle Buffs, auch die von anderen, stehen wieder oben rechts. Einmal /wcui einrichten, dann neu laden.",
            "|cff7C6CFFTreffer und Heilung im Rahmen.|r Spieler- und Zielrahmen zeigen kurz, was gerade ankam: erlittener Schaden in kleinen roten Zahlen mit Minus, erhaltene Heilung grün mit Plus. Abschaltbar unter Einheitenrahmen → Allgemein.",
        },
    },
    {
        version = "6.6.1.6",
        date    = "28.09.2026",
        notes   = {
            "|cff7C6CFFBuffs am Spielerrahmen.|r Deine Buffs stehen direkt über deinem Spielerrahmen – auch im Kampf. Einmal /wcui einrichten, dann neu laden. Der Fokusrahmen rückt dafür nach links.",
            "|cff7C6CFFSchilde sichtbar, auch bei vollem Leben.|r Ein Schild liegt als blaue Fläche vom rechten Rand her über dem Lebensbalken von Spieler und Ziel.",
        },
    },
    {
        version = "6.6.1.5",
        date    = "28.09.2026",
        notes   = {
            "|cff7C6CFFAbklingzeiten wie eine WeakAura.|r Unter dem Charakter nur noch deine Fähigkeiten und wie lange ihre Wirkung läuft – kleiner, ohne doppelte Symbole und ohne lange Buffs wie Ausdauer. Einmal /wcui einrichten, dann neu laden; die Buff-Anzeigen des Spiels lassen sich im Bearbeitungsmodus wieder einschalten.",
        },
    },
    {
        version = "6.6.1.4",
        date    = "28.09.2026",
        notes   = {
            "|cff7C6CFFGespräche im WeintCodex-Stil.|r Questgeber, Gastwirte, Questtexte und Bücher stehen auf der dunklen Kachel statt auf Pergament, mit heller Schrift.",
            "|cff7C6CFFEinrichtung lässt deine Plätze in Ruhe.|r Deine WeintCodex-Rahmen bleiben, wo du sie hingezogen hast, und der Abklingzeitmanager behält die Plätze aus deinem bisherigen Layout. /wcui einrichten pruefen funktioniert jetzt, und die Questliste rutscht unter den Knopf „Issue Reporter“. Der eigene Zauberbalken passt zwischen Spieler- und Zielrahmen, und die Schadensanzeige steht wieder oben links. Die Questliste schließt rechts bündig mit der Minikarte ab (nach /wcui einrichten). Das Blinken bei automatischem Angriff und Schießen ist ein flaches Leuchten statt eines schiefen roten Rahmens.",
        },
    },
    {
        version = "6.6.1.3",
        date    = "27.09.2026",
        notes   = {
            "|cff7C6CFFEinrichtung stellt jetzt alles.|r Jeder Rahmen des Spiels bekommt seinen festen Platz – Aktionsleisten, Chat, Minikarte, Buffs, Questliste, Taschen, Menü, Gruppe –, egal was ein früheres Addon eingestellt hatte. Dazu Chatfenster zurück auf Allgemein und Kampflog, einige Spieleinstellungen und die eigenen Rahmen auf ihre Plätze. Einmal /wcui einrichten, neu laden, und /wcui einrichten pruefen zeigt, ob alles sitzt.",
        },
    },
    {
        version = "6.6.1.2",
        date    = "27.09.2026",
        notes   = {
            "|cff7C6CFFEinrichtung behält deine Leisten.|r Das Layout „WeintCodex“ baut jetzt auf deinem bisherigen Layout auf – Aktionsleisten, Questliste und alles andere bleiben, wo sie waren; nur Gruppe und Schlachtzug ändern sich. Wer schon eingerichtet hat: /wcui einrichten noch einmal ausführen.",
        },
    },
    {
        version = "6.6.1.1",
        date    = "27.09.2026",
        notes   = {
            "|cff7C6CFFEinrichtung mit einem Klick.|r Beim ersten Einloggen stellt WeintCodex die Oberfläche für dich ein – wie EllesmereUI: ein eigenes Layout „WeintCodex“ im Bearbeitungsmodus mit schlachtzugsartigen Gruppenrahmen an den richtigen Plätzen, dann einmal neu laden. Verschieben geht danach wie gewohnt. Jederzeit wieder mit /wcui einrichten oder unter Gruppenrahmen → Allgemein.",
        },
    },
    {
        version = "6.6.1.0",
        date    = "27.09.2026",
        notes   = {
            "|cff7C6CFFGruppenrahmen wie die eigenen Kacheln.|r Die Rahmen des Spiels tragen jetzt Klassenfarbe statt Grün, den Namen oben mittig, den Zustand in der Mitte, Grund, Rand und Schatten der Kacheln – die Überschrift „Gruppe“ und Blizzards Linien sind weg. HoTs, Buffs und Schilde zeigt weiter das Spiel. Tote und Getrennte bleiben grau.",
        },
    },
    {
        version = "6.6.0.9",
        date    = "27.09.2026",
        notes   = {
            "|cff7C6CFFGruppenrahmen mit HoTs, Buffs und Schilden.|r Die Gruppe und der Schlachtzug nutzen jetzt die Rahmen des Spiels im WeintCodex-Stil – nur sie zeigen HoTs, Buffs, Schilde und bannbare Debuffs auch im Kampf. Lage und Größe im Bearbeitungsmodus des Spiels; in der Gruppe dort „Schlachtzugsartige Gruppenrahmen“ einschalten. Die eigenen Kacheln gibt es weiter unter Gruppenrahmen → Rahmen.",
            "|cff7C6CFFKlickzauber auch auf den Rahmen des Spiels.|r Deine Belegung wirkt auf die neuen Gruppen- und Schlachtzugsrahmen genauso.",
        },
    },
    {
        version = "6.6.0.8",
        date    = "27.09.2026",
        notes   = {
            "|cff7C6CFFQuestpfeil: höher oder tiefer.|r Nennt das Spiel deine eigene Höhe, erkennt der Pfeil beim Bergauf- oder Bergabgehen, ob das Ziel über oder unter dir liegt – „Ziel ≈ 25 m höher“ und ein kleiner Pfeil nach oben oder unten. Ob dein Spiel die Höhe nennt, sagt /wcui pfeil.",
        },
    },
    {
        version = "6.6.0.7",
        date    = "27.09.2026",
        notes   = {
            "|cff7C6CFFKlickzauber.|r Zauber auf Maustasten legen und mit einem Klick auf einen Rahmen wirken – Gruppe, Schlachtzug, Spieler, Ziel –, ohne die Einheit erst anzuwählen. Taste wählen, Zauber aus deinem Zauberbuch anklicken – nichts tippen. Einstellen unter Gruppenrahmen → Klickzauber; die Belegung gilt je Klasse, und die Maus über einem Rahmen zeigt, was welche Taste tut.",
        },
    },
    {
        version = "6.6.0.6",
        date    = "27.09.2026",
        notes   = {
            "|cff7C6CFFEingehende Heilung an Spieler und Ziel.|r Wie in den Gruppenrahmen zeigt ein heller grüner Balken hinter dem Leben, wie weit gerade gewirkte Heilungen reichen, ein weißer dahinter die Schilde. Beides abschaltbar unter Einheitenrahmen → Allgemein.",
            "|cff7C6CFFErinnerung bei knapper Munition.|r Neue Regel „Munition knapp“: WeintCodex liest, was im Munitionsplatz steckt, und erinnert unter einer Menge, die du festlegst (ohne Angabe 200) – und wenn sie ganz verschossen ist. „Für meine Klasse“ legt sie beim Jäger gleich mit an.",
            "|cff7C6CFFErinnerung bei knappem Vorrat.|r Neue Regel „Vorrat knapp“ für jeden Gegenstand, den du nennst (Name oder ID): Tränke, Reagenzien, Essen – mit eigener Mindestmenge.",
        },
    },
    {
        version = "6.6.0.5",
        date    = "27.09.2026",
        notes   = {
            "|cff7C6CFFErinnerungen gelten je Klasse.|r Eine Regel gilt jetzt für die Klasse, auf der du sie anlegst – der Schlachtruf deines Kriegers erinnert deinen Jäger nicht mehr. Für Buffs, die andere geben, wählst du „Alle Klassen“. Regeln aus der Zeit davor gelten dort, wo der Charakter den Zauber kennt; fremde stehen blass mit „(hier aus)“ in der Liste.",
        },
    },
    {
        version = "6.6.0.4",
        date    = "27.09.2026",
        notes   = {
            "|cff7C6CFFAurenleisten wieder entfernt.|r Im Kampf gibt das Spiel Addons weder die Auren des Ziels noch deine eigenen heraus – die Leisten verschwanden genau dann, wenn du sie brauchst. Leisten mit Restzeit im Kampf bekommst du über die verfolgten Leisten des Abklingzeitmanagers; am Zielrahmen zeigen weiter die Symbole des Spiels deine Debuffs.",
        },
    },
    {
        version = "6.6.0.3",
        date    = "27.09.2026",
        notes   = {
            "|cff7C6CFFAurenleisten nur noch über deinem Spielerrahmen.|r Die Auren des Ziels hält das Spiel im Kampf vor Addons geheim – Leisten über dem Ziel blieben genau dann leer. Dort zeigen weiter die Symbole des Spiels deine Debuffs.",
            "|cff7C6CFFAurenleisten zeigen zuerst deine Buffs.|r Umschaltbar auf die Debuffs auf dir.",
        },
    },
    {
        version = "6.6.0.2",
        date    = "27.09.2026",
        notes   = {
            "|cff7C6CFFAurenleisten zeigen sich.|r Über Spieler- und Zielrahmen stehen die Leisten jetzt wirklich – mit Zaubername, Restzeit und einer Leiste, die mit der Zeit leerläuft. Die Einstellung „Weg“ bei den Auren spielt dafür keine Rolle mehr.",
        },
    },
    {
        version = "6.6.0.1",
        date    = "27.09.2026",
        notes   = {
            "|cff7C6CFFNeue Marke auf der Weltkarte.|r Eine Stecknadel mit pulsierendem Schein und Namensschild statt der kleinen Raute – auf Pergament und Gelände schnell zu finden.",
            "|cff7C6CFFZurück zum Codex, aufgeräumt.|r Oben in der Mitte der Karte steht eine Leiste im Stil des Codex: wer markiert ist, wo, und der Knopf zurück. Sie verdeckt keinen Knopf des Spiels mehr.",
            "|cff7C6CFFLehrer: Waffenkarte repariert.|r Stand, Kosten und „Karte“ stehen wieder in der Waffenkarte statt daneben.",
            "|cff7C6CFFErfahrung aus Quests im Balken.|r Ein grünes Stück zeigt, wie weit der Erfahrungsbalken käme, wenn du jetzt alle fertigen Quests abgibst; die Maus darüber nennt die Summe, deinen Stand danach – oder die nächste Stufe – und was alle Quests im Log zusammen bringen.",
            "|cff7C6CFFDein Name steht wieder auf dem Spielerrahmen.|r Beim Einloggen blieb er manchmal leer – jetzt zeichnet der Rahmen nach, bis das Spiel ihn kennt.",
            "|cff7C6CFFAurenleisten über Spieler- und Zielrahmen (Test).|r Leisten mit Restzeit wie bei ElvUI. Im Kampf gibt das Spiel Addons vermutlich keine Auren heraus – dann bleiben sie dort leer; bitte prüfen und /wcui auren schicken.",
            "|cff7C6CFFDer Questpfeil kennt die Höhe.|r In der Nähe nennt er den Höhenunterschied zum Ziel und ob es verdeckt ist – in einer Höhle, einem Gebäude oder hinter einem Hang. Eine Nadel steht genau am Ziel im Raum, oben am Berg oder unten am Höhleneingang.",
            "|cff7C6CFFKein Fehler mehr beim Umstellen der Questpriorität im Kampf.|r WeintCodex stellt die Weltkarte nicht mehr selbst ein und wählt keine Quest mehr für das Spiel aus – der Questpfeil merkt sich seine Wahl selbst. „Zurück zum Codex“ legt den Codex über die Karte; sie schließt du wie gewohnt mit Esc oder M. Im Kampf öffnet der Kartenknopf die Weltkarte nicht.",
        },
    },
    {
        version = "6.6.0.0",
        date    = "27.09.2026",
        notes   = {
            "|cff7C6CFFNeu: Lehrer.|r Was dir dein Klassenlehrer jetzt beibringt, was dafür noch fehlt, was in den nächsten Stufen kommt – und was das alles kostet. Unter Charakter in der Seitenleiste.",
            "|cff7C6CFFWaffenfertigkeiten mit Weg dorthin.|r Welche Waffen du lernen kannst und welcher Waffenmeister sie lehrt – ein Klick zeigt ihn auf der Weltkarte.",
            "|cff7C6CFFWas du kannst, sagt dein Spiel.|r Stufen und Kosten stammen aus Beta-Berichten und sind als unbestätigt gekennzeichnet; ob ein Zauber schon gelernt ist, fragt WeintCodex deinen Client.",
        },
    },
    {
        version = "6.5.1.2",
        date    = "27.09.2026",
        notes   = {
            "|cff7C6CFFDie Weltkarte liegt vorn.|r Zeigst du einen Questgeber auf der Karte, geht der Codex so lange zu – die Karte liegt nicht mehr dahinter.",
            "|cff7C6CFFZurück zum Codex mit einem Klick.|r Oben links auf der Karte bringt dich ein Knopf auf dieselbe Seite zurück, zum nächsten Questgeber.",
        },
    },
    {
        version = "6.5.1.1",
        date    = "27.09.2026",
        notes   = {
            "|cff7C6CFFJede Quest in ihrer eigenen Kachel.|r Im Dungeonkompendium ist auf einen Blick zu sehen, wo eine Quest endet und die nächste beginnt.",
            "|cff7C6CFFDer Kartenknopf fällt auf.|r „Questgeber auf der Karte zeigen“ ist jetzt ein Knopf mit Fläche und Rand statt einer kleinen Textzeile.",
        },
    },
    {
        version = "6.5.1.0",
        date    = "27.09.2026",
        notes   = {
            "|cff7C6CFFQuestgeber auf der Weltkarte.|r Unter einer Quest im Dungeonkompendium öffnet ein Klick die Weltkarte auf der richtigen Zone und markiert, wo die Quest beginnt – bei 33 Quests. Rechtsklick auf die Marke entfernt sie.",
            "|cff7C6CFFDie Lage ist unbestätigt.|r Sie stammt aus Beta-Berichten und folgt den bekannten Orten aus Classic; der Tooltip der Marke sagt das.",
        },
    },
    {
        version = "6.5.0.0",
        date    = "27.09.2026",
        notes   = {
            "|cff7C6CFFBeute im Dungeonkompendium.|r Für Hall of Thanes, Ragefire Chasm, Wailing Caverns, Ruins of Lordaeron, The Deadmines, Shadowfang Keep und Blackfathom Deeps zeigt jeder Boss, was er fallen lässt – mit dem Tooltip des Spiels und Umschalt+Klick in den Chat.",
            "|cff7C6CFFQuests zu jedem dieser Dungeons.|r Wo sie beginnen, was zu tun ist, wo man sie abgibt und was sie bringen – nur für deine Fraktion, die andere wird gezählt.",
            "|cff7C6CFFUnbestätigt, und so gekennzeichnet.|r Die Angaben stammen aus Beta-Berichten, nicht aus dem Client. Die Erfahrung ist ein beobachteter Wert; Namen und Werte der Gegenstände nennt dein Spiel selbst.",
            "|cff7C6CFFMehr Addon-Knöpfe im Sammelknopf der Minikarte.|r Auch Addons mit eigenem Kartenknopf kommen hinein, und Knöpfe, die ein Addon erst spät anlegt, ebenfalls. Fehlt trotzdem eines, zeigt /wcui addons, was gefunden wurde und was nur im Addon-Menü des Spiels steht.",
            "|cff7C6CFFDie Reiter Primär und Sekundär im Talentfenster sehen wieder aus wie Reiter.|r Sie trugen einen Rand mitten auf der Schrift statt ihrer Kachel.",
        },
    },
    {
        version = "6.4.1.8",
        date    = "27.09.2026",
        notes   = {
            "|cff7C6CFFKeine wandernden Balken mehr im Zauberbuch.|r Die dunkle Fläche hinter den Kategorie-Bildern ist weg – sie schaute seitlich heraus, wo ein Reiter breiter war als sein Bild.",
        },
    },
    {
        version = "6.4.1.7",
        date    = "27.09.2026",
        notes   = {
            "|cff7C6CFFKlassenbild im Zauberbuch ohne Balken.|r Die dunklen Streifen links und rechts am Klassen-Reiter sind weg; alle Kategorie-Bilder sind gleich zugeschnitten.",
        },
    },
    {
        version = "6.4.1.6",
        date    = "27.09.2026",
        notes   = {
            "|cff7C6CFFKategorien im Zauberbuch aufgeräumt.|r Die Bilder oben stoßen nicht mehr aneinander, der goldene Schein ist weg; die gewählte Kategorie trägt einen Rand im Akzent.",
        },
    },
    {
        version = "6.4.1.5",
        date    = "27.09.2026",
        notes   = {
            "|cff7C6CFFKlassenschein deutlicher.|r Oben in Charakterfenster, Zauberbuch und Talenten jetzt gut zu sehen statt nur zu ahnen.",
            "|cff7C6CFFReiter und Knöpfe ohne Gold.|r „Primär/Sekundär“ und „Änderungen anwenden“ als Kachel, der gewählte Reiter mit Rand im Akzent; Schließen- und Pfeilknöpfe grau statt rot und gelb. Das runde Symbol oben links im Talentfenster ist weg.",
            "|cff7C6CFFWerte lesbar.|r Im Charakterfenster läuft ein langer Name wie „Bewegungsgeschwindigkeit“ nicht mehr in die Zahl, er wird davor gekürzt.",
        },
    },
    {
        version = "6.4.1.4",
        date    = "27.09.2026",
        notes   = {
            "|cff7C6CFFStimmung statt Schwarz.|r Oben in Charakterfenster, Zauberbuch und Talenten ein Schein in deiner Klassenfarbe; die Landschaften hinter den Talentbäumen bleiben – gedämpft, damit Symbole und Schrift vorne stehen. Abschaltbar: /wcui → Tooltip & Fenster.",
            "|cff7C6CFFKein Goldschmuck mehr.|r Goldrahmen der Zauberbuch-Reiter, Ringe um die Spezialisierungen, Goldlinien und der Goldkasten der Talentpunkte sind weg. Was etwas anzeigt – gewählter Reiter, verfügbare und volle Talente – bleibt.",
        },
    },
    {
        version = "6.4.1.3",
        date    = "27.09.2026",
        notes   = {
            "|cff7C6CFFZauberbuch ohne Pergament, Talente ohne Landschaften.|r Große Hintergrundbilder beider Fenster verschwinden, darunter liegt die WeintCodex-Kachel. Symbole, Pfeile, Reiter und die farbigen Rahmen der Talente bleiben.",
        },
    },
    {
        version = "6.4.1.2",
        date    = "27.09.2026",
        notes   = {
            "|cff7C6CFFZauberbuch im WeintCodex-Stil.|r Kachel statt Pergament, Titel und Schrift hell, Zaubersymbole eckig mit dem Rand der Aktionsleisten statt der runden und goldenen Zierrahmen.",
        },
    },
    {
        version = "6.4.1.1",
        date    = "27.09.2026",
        notes   = {
            "|cff7C6CFFAbklingzeitmanager mit Luft.|r Die eckigen Symbole überlappten sich; jetzt bleiben 2 px zwischen ihnen, auch wenn du den Abstand im Bearbeitungsmodus änderst.",
            "|cff7C6CFFNeu-laden-Knöpfe ohne Fehlermeldung.|r Ein Klick auf „Neu laden“ meldete „hat versucht die geschützte Funktion RunMacroText() aufzurufen“ und lud nicht neu.",
        },
    },
    {
        version = "6.4.1.0",
        date    = "27.09.2026",
        notes   = {
            "|cff7C6CFFAbklingzeitmanager im WeintCodex-Stil.|r Eckige Symbole mit Rand wie auf den Aktionsleisten, ohne den runden Rahmen des Spiels, Abklingzahlen und Stapel in der WeintCodex-Schrift, flache Buff-Balken. Einstellungen: /wcui abklingzeiten (Reiter der Erinnerungen).",
            "|cff7C6CFFZählwerk und Zauberauswahl bleiben die des Spiels.|r Im Kampf nennt der Client Abklingzeiten und Buffs nur seinem eigenen Manager – ein nachgebauter bliebe dort leer.",
        },
    },
    {
        version = "6.4.0.4",
        date    = "27.09.2026",
        notes   = {
            "|cff7C6CFFSymbole am Zielrahmen einstellbar.|r Links- oder rechtsbündig, Abstand zum Rahmen und Größe – die Größe jetzt scharf statt hochskaliert. Einheitenrahmen → Ziel.",
        },
    },
    {
        version = "6.4.0.3",
        date    = "27.09.2026",
        notes   = {
            "|cff7C6CFFDebuffs über dem Zielrahmen – auch im Kampf.|r Der Zielrahmen zeigt jetzt die Symbole des Spiels, dieselben wie auf der Namensplakette. Die eigenen Symbole blieben im Kampf leer, weil der Client Auren dort nur an seine eigenen Symbole herausgibt. Umschalten und Größe: Einheitenrahmen → Ziel.",
        },
    },
    {
        version = "6.4.0.2",
        date    = "27.09.2026",
        notes   = {
            "|cff7C6CFF„Für meine Klasse“ ergänzt nur noch.|r Selbst angelegte Regeln bleiben stehen; gibt es für deine Klasse keine Vorschläge, sagt der Knopf das, statt die Liste zu leeren.",
            "|cff7C6CFFKalender neben der Karte.|r Der Kalenderknopf verdeckt die Uhrzeit nicht mehr, er steht jetzt links in der Knopfspalte unter der Verfolgung.",
        },
    },
    {
        version = "6.4.0.1",
        date    = "27.09.2026",
        notes   = {
            "|cff7C6CFFErinnerungen direkt öffnen.|r /wcui erinnerungen springt sofort zu den Erinnerungen; läuft noch eine ältere Fassung, sagt der Befehl das.",
            "|cff7C6CFFVorschläge für deine Klasse repariert.|r „Für meine Klasse“ erkannte die Klasse nicht und schlug deshalb für niemanden etwas vor.",
        },
    },
    {
        version = "6.4.0.0",
        date    = "27.09.2026",
        notes   = {
            "|cff7C6CFFNeu: Erinnerungen.|r Was früher WeakAuras konnte, soweit das Spiel es heute noch erlaubt: WeintCodex erinnert dich vor dem Kampf an fehlende Buffs, an Waffen ohne (oder mit bald ablaufender) Verzauberung und an einen fehlenden Begleiter.",
            "|cff7C6CFFProcs und Abklingzeiten als Symbole.|r Eigene Buffs und Procs erscheinen groß über dem Cockpit, solange sie laufen; wichtige Fähigkeiten stehen darunter als Leiste mit Abklingzeit. Verschiebbar im Gestaltungsmodus.",
            "|cff7C6CFFDeine Regeln.|r Unter Erinnerungen → Regeln legst du selbst an, was beobachtet wird – Zauber mit Namen oder ID. „Für meine Klasse“ schlägt vor, was ohne Zauber geht (Waffe, Begleiter).",
            "|cff7C6CFFWas nicht geht, ehrlich:|r Im Kampf verschlüsselt das Spiel viele Werte. Symbole und Uhren zeigen, was es herausgibt; Erinnerungen ruhen dort, statt zu raten.",
        },
    },
    {
        version = "6.3.2.9",
        date    = "26.09.2026",
        notes   = {
            "|cff7C6CFFRollensymbole gut lesbar.|r Schild, Kreuz, Schwert und Krone in den Gruppenrahmen stehen jetzt größer auf einer kleinen dunklen Plakette, statt auf der Klassenfarbe unterzugehen; das Schwert ist kräftiger gezeichnet.",
        },
    },
    {
        version = "6.3.2.8",
        date    = "26.09.2026",
        notes   = {
            "|cff7C6CFFIm Dungeon nur seine Quests.|r Betrittst du einen Dungeon, zeigt die Questliste nur noch die Quests dieses Dungeons; beim Verlassen ist alles wieder wie vorher. Abschaltbar unter Questliste → „Nur Quests des Dungeons“.",
            "|cff7C6CFFQuestpfeil in Dungeons aus.|r In Dungeons, Schlachtzügen, auf Schlachtfeldern und in Arenen verschwindet der Pfeil – dort nennt das Spiel ohnehin keine Position. Draußen ist er sofort wieder da. Abschaltbar unter Questpfeil → „In Dungeons ausblenden“.",
        },
    },
    {
        version = "6.3.2.7",
        date    = "26.09.2026",
        notes   = {
            "|cff7C6CFFMarkierungen wirklich sichtbar.|r Totenkopf, Kreuz und Co. erscheinen jetzt an Namensplaketten, am Ziel-, Fokus- und Spielerrahmen und in der Gruppe – auch wenn der Client verschlüsselt, welche Markierung ein Gegner trägt.",
        },
    },
    {
        version = "6.3.2.6",
        date    = "26.09.2026",
        notes   = {
            "|cff7C6CFFMarkierungen an der Namensplakette.|r Totenkopf, Kreuz und die übrigen Zielmarkierungen stehen oben rechts an der Plakette (Größe und Lage unter Namensplaketten → Texte). Verschlüsselt der Client die Markierung, zeigt WeintCodex an derselben Stelle die Markierung des Spiels.",
            "|cff7C6CFFDeine Bedrohung an der Namensplakette.|r Rechts neben dem Balken steht in Prozent, wie viel Bedrohung du auf diesem Gegner hast – 100 % heißt: du hast die Aggro. Gelb kurz davor, rot mit Aggro; als Tank grün, solange du sie hältst. Nur im Kampf und solange du auf seiner Liste stehst. Einstellbar unter Namensplaketten → Farben → Bedrohung.",
        },
    },
    {
        version = "6.3.2.5",
        date    = "26.09.2026",
        notes   = {
            "|cff7C6CFFAuf wen der Gegner zaubert.|r Der Zauberbalken auf Namensplaketten, am Ziel- und am Fokusrahmen nennt rechts das Ziel des Zaubers: „» Dich“ in Rot, wenn er auf dich geht, andere Spieler in ihrer Klassenfarbe. Wechselt der Gegner mitten im Zauber das Ziel, wechselt die Anzeige mit. Abschaltbar bei den Zauberbalken der Plaketten und Rahmen.",
        },
    },
    {
        version = "6.3.2.4",
        date    = "26.09.2026",
        notes   = {
            "|cff7C6CFFGruppenrahmen mit mehr Einblick.|r Eingehende Heilung als heller grüner Balken hinter dem Leben, Schilde als weißer Balken, ein Rollensymbol (Schild, Kreuz, Schwert) und eine Krone beim Gruppenleiter.",
            "|cff7C6CFFBereitschaftscheck im Rahmen.|r Haken, Kreuz oder „?“ mitten im Knopf; das Ergebnis bleibt ein paar Sekunden stehen.",
            "|cff7C6CFFTreffer und Wiederbelebung.|r Wer getroffen wird, blitzt kurz rot auf; wer gerade wiederbelebt oder beschworen wird, steht unter dem Namen. Alles einzeln abschaltbar unter Gruppenrahmen → Allgemein.",
        },
    },
    {
        version = "6.3.2.3",
        date    = "26.09.2026",
        notes   = {
            "|cff7C6CFFKein Lua-Fehler mehr in der Gruppe.|r Wechselte ein Gruppenmitglied oder dessen Begleiter die Fraktion, meldeten die Namensplaketten einen Fehler („unit tokens are not allowed“). Behoben.",
        },
    },
    {
        version = "6.3.2.2",
        date    = "26.09.2026",
        notes   = {
            "|cff7C6CFF„zZ“ statt Mond.|r Beim Ausruhen im Gasthaus oder in der Stadt zeigt der Spielerrahmen jetzt ein schlichtes „zZ“.",
        },
    },
    {
        version = "6.3.2.1",
        date    = "26.09.2026",
        notes   = {
            "|cff7C6CFFKampf und Ruhe am Spielerrahmen.|r Oben links am Rahmen: gekreuzte Schwerter im Kampf (leicht pulsierend), eine Mondsichel beim Ausruhen im Gasthaus oder in der Stadt. Abschaltbar unter Einheitenrahmen → Spieler.",
            "|cff7C6CFFDeine Stufe im Spielerrahmen.|r Vor dem Namen, wie beim Ziel.",
            "|cff7C6CFFEingabezeile wirklich erst mit Enter.|r Die halbdurchsichtige Leiste unter dem Chat ist weg, solange du nicht schreibst; dort steht die Infozeile.",
        },
    },
    {
        version = "6.3.2.0",
        date    = "26.09.2026",
        notes   = {
            "|cff7C6CFFDebuffs mittig und rechts über der Plakette.|r Bei „mittig“ standen die Symbole des Spiels unter der Namensplakette; jetzt stehen sie darüber, über dem Namen.",
            "|cff7C6CFFEingabezeile erst mit Enter.|r Die Zeile zum Schreiben erscheint erst, wenn du Enter drückst, und verschwindet danach wieder; darunter bleibt die Infozeile frei. Abschaltbar unter Chat → Eingabezeile.",
            "|cff7C6CFFHaltungsleiste passt sich an.|r Sie ist so breit wie die Haltungen deiner Klasse und wächst mit, wenn du eine neue lernst – keine leere Fläche mehr neben zwei Knöpfen. Größe, Abstand, Anordnung, Fläche und „nur bei Maus“ stellst du wie bei jeder Leiste unter Aktionsleisten → Leisten → „Haltungen“ ein.",
        },
    },
    {
        version = "6.3.1.9",
        date    = "26.09.2026",
        notes   = {
            "|cff7C6CFFName in der Namensplakette.|r Unter Namensplaketten → Texte → „Name steht“: über der Plakette, im Balken links mit Stufe davor oder im Balken mittig. Die Textplätze darunter lassen sich weiter einzeln belegen, neu auch mit „Stufe und Name“.",
            "|cff7C6CFFDebuffs links, mittig oder rechts.|r Unter Namensplaketten → Auren → Ausrichtung. Bei den Symbolen des Spiels ist das ein Versuch – /wcui auren sagt, ob das Spiel es annimmt.",
            "|cff7C6CFFLeere Aktionsplätze sichtbar.|r Die Plätze einer Leiste stehen jetzt auch leer dezent da, nicht erst beim Ziehen eines Zaubers. Wie bisher einstellbar unter Aktionsleisten → Leere Plätze.",
        },
    },
    {
        version = "6.3.1.8",
        date    = "26.09.2026",
        notes   = {
            "|cff7C6CFFReiter rechts am Charakterfenster im neuen Stil.|r Kleine Kacheln statt Goldrahmen, der gewählte mit Rand im Akzent, unter der Maus heller.",
            "|cff7C6CFFRuf und Fertigkeiten ohne Holz.|r Die Balken sind flach mit feinem Rand, die Trennlinien zwischen den Spalten und über den Listen sind weg.",
            "|cff7C6CFF/wcui fenster sagt mehr.|r Die Ausgabe nennt jetzt die Fassung von WeintCodex, wie oft das Fenster gestaltet wurde, und markiert Bilder, die eigentlich weg sein sollten.",
        },
    },
    {
        version = "6.3.1.7",
        date    = "26.09.2026",
        notes   = {
            "|cff7C6CFFCharakterfenster auch innen im neuen Stil.|r Holz- und Steinhintergründe, der Klassenhintergrund hinter den Werten, die Holzbalken der Kopfzeilen, die Streifen hinter den Werten und die Metallrahmen der Ausrüstungsplätze sind weg; die Plätze sind flach mit feinem Rand wie die Aktionsknöpfe. Die Bühne des Modells bleibt.",
        },
    },
    {
        version = "6.3.1.6",
        date    = "26.09.2026",
        notes   = {
            "|cff7C6CFFCharakterfenster im neuen Stil.|r Das Fenster hinter Taste C – mit Ruf, Fertigkeiten, PvP und Abzeichen – steht auf einer Kachel statt auf Holz und Metall, ohne das runde Porträt, der Titel in der Schrift der Oberfläche. Erste Stufe: die Hülle; das Innere folgt.",
            "|cff7C6CFFTageszeit in jeder Ecke.|r Unter Minikarte wählst du, ob die Tageszeit unten rechts, unten links, oben rechts oder oben links in der Karte sitzt.",
            "|cff7C6CFFAddon-Knöpfe hell, zweiter Anlauf.|r Die Knöpfe anderer Addons froren ihre Zeichenebene ein und blieben so unter der dunklen Kachel; jetzt liegen sie darüber.",
            "|cff7C6CFFNeu: /wcui fenster.|r Maus über ein Fenster halten und abschicken: Der Chat nennt die größten Bilder darin.",
        },
    },
    {
        version = "6.3.1.5",
        date    = "26.09.2026",
        notes   = {
            "|cff7C6CFFNeuer Erfahrungsbalken.|r Schmal, im Stil der Oberfläche, mit erholter Erfahrung als blasser Verlängerung. Auf Höchststufe zeigt er den beobachteten Ruf. Die goldene Leiste des Spiels ist weg.",
            "|cff7C6CFFNur bei Maus darüber.|r Der Balken kann unsichtbar bleiben, bis die Maus darauf zeigt; die Zahlen stehen wahlweise immer, bei Maus darüber oder nie im Balken.",
            "|cff7C6CFFTempo je Stunde.|r Die Maus über dem Balken zeigt Werte, was bis zur nächsten Stufe fehlt, erholte Erfahrung und – sobald in dieser Sitzung Erfahrung dazukam – Erfahrung je Stunde samt Schätzung bis zum Aufstieg. Einstellbar unter Aktionsleisten → Erfahrung.",
        },
    },
    {
        version = "6.3.1.4",
        date    = "26.09.2026",
        notes   = {
            "|cff7C6CFFKeine Namensplakette mehr am falschen Gegner.|r Manchmal blieb eine Plakette eingefroren stehen – mit Namen, Leben und Zielleuchten eines anderen Gegners – und wanderte an den nächsten. Das ist behoben.",
            "|cff7C6CFFTageszeit unten rechts in der Minikarte.|r Die Sonne heißt in diesem Client anders als in allen bisherigen; jetzt wird sie gefunden und sitzt über dem Gebietsstreifen.",
            "|cff7C6CFFQuestliste ganz ohne Fläche.|r Deckkraft 0 % unter Questliste blendet die Fläche samt Rand und Schatten aus.",
            "|cff7C6CFFAddon-Knöpfe und Chat-Reiter.|r Addon-Knöpfe in der Kachel des Sammelknopfs bleiben voll deckend, und die Reiterzeile des Chats liegt eine Schicht über dem Chatfenster. /wcui maus nennt jetzt auch Texte, Farbflächen und die Deckkraft unter dem Zeiger.",
        },
    },
    {
        version = "6.3.1.3",
        date    = "26.09.2026",
        notes   = {
            "|cff7C6CFFDie Chat-Reiter sind wieder zu sehen.|r Die dunkle Fläche des Chats lag über „Allgemein“ und „Kampflog“ und hat sie fast ganz verdeckt; jetzt liegt sie darunter.",
            "|cff7C6CFF/wcui maus sieht mehr.|r Neben den Rahmen, die auf die Maus reagieren, nennt der Befehl jetzt auch Bilder und Rahmen ohne Mausklick unter dem Zeiger, samt Bilddatei.",
        },
    },
    {
        version = "6.3.1.2",
        date    = "26.09.2026",
        notes   = {
            "|cff7C6CFFAddon-Knöpfe in voller Helligkeit.|r In der aufgeklappten Kachel des Sammelknopfs lagen die Knöpfe hinter deren dunkler Fläche; jetzt liegen sie darüber.",
            "|cff7C6CFFTageszeit wird breiter gesucht.|r Heißt sie in diesem Client anders als erwartet, findet WeintCodex sie jetzt auch über die Rahmen an der Minikarte.",
            "|cff7C6CFFNeu: /wcui maus.|r Maus über ein Ding am Bildschirm halten und /wcui maus abschicken: Der Chat nennt Name, Elternrahmen und Anker aller Rahmen darunter.",
        },
    },
    {
        version = "6.3.1.1",
        date    = "26.09.2026",
        notes   = {
            "|cff7C6CFFEin Knopf für alle Addons an der Minikarte.|r Unten links neben der Minikarte sitzt ein Knopf mit neun Punkten; ein Klick klappt alle Addon-Knöpfe in einer Kachel auf, ein zweiter klappt sie wieder zu. Kartenmarkierungen anderer Addons (Wegpunkte, Fundorte) bleiben auf der Karte. Abschaltbar unter Minikarte → „Addon-Knöpfe sammeln“.",
            "|cff7C6CFFTageszeit unten rechts.|r Die Tageszeit-Sonne (zugleich der Kalender) steht unten rechts in der Karte, über dem Gebietsstreifen.",
            "|cff7C6CFFGenauere Chat-Prüfung.|r /wcui chat nennt jetzt auch Textfarbe, laufende Blendanimationen und ob die Andockleiste ihre Reiter abschneidet.",
        },
    },
    {
        version = "6.3.1.0",
        date    = "26.09.2026",
        notes   = {
            "|cff7C6CFFMinikarte: alle Knöpfe neben die Karte.|r Die Tageszeit-Sonne und Knöpfe anderer Addons lagen mitten auf der Karte, weil sie auf keiner festen Liste standen. Jetzt kommt jeder kleine Knopf auf oder an der Karte in die Spalte links daneben – reicht die Höhe nicht, in eine zweite Spalte.",
            "|cff7C6CFFChat-Prüfung.|r /wcui chat schreibt in den Chat, was WeintCodex über Chatfenster, Reiter, Knöpfe und Eingabezeile sieht. Die Reiter blieben im Beta-Test unsichtbar, und ohne diese Auskunft wäre jeder weitere Versuch geraten.",
        },
    },
    {
        version = "6.3.0.9",
        date    = "25.09.2026",
        notes   = {
            "|cff7C6CFFChat: Reiter sichtbar, keine Bildlaufleiste.|r Die Reiter sind wieder zu sehen – die WeintCodex-Fläche lag über ihnen statt darunter. Die halbdurchsichtige Bildlaufleiste und der Pfeil nach unten am rechten Rand sind weg; blättern geht mit dem Mausrad (abschaltbar).",
            "|cff7C6CFFTooltip im neuen Design.|r Die Hinweisfenster sind eine Kachel wie der Rest der Oberfläche. Spielernamen stehen in Klassenfarbe, der Rand leuchtet in Klassenfarbe bzw. bei Gegenständen ab „selten“ in ihrer Qualität, der Lebensbalken ist flach und angedockt. Einstellbar unter Allgemein → Tooltip.",
            "|cff7C6CFFMinikarte ohne leeren Platz.|r Die Karte rückt nach oben, wo die ausgeblendete Kopfleiste des Spiels stand. Eine zweite Koordinatenzeile, die nicht von WeintCodex stammt, wird ausgeblendet.",
        },
    },
    {
        version = "6.3.0.8",
        date    = "25.09.2026",
        notes   = {
            "|cff7C6CFFDer Zauberbalken im neuen Kleid.|r Der Zaubername steht wieder da (das Spiel lieferte einen leeren Anzeigetext). Der eigene Zauberbalken in der Mitte ist größer (20 px hoch, 240 breit, einstellbar), das Symbol steht abgesetzt mit eigenem Rand, eine helle Kante läuft am Ende der Füllung mit, und rot am Ende zeigt die Latenz: ab da darfst du den nächsten Zauber schon drücken.",
            "|cff7C6CFFMikromenü und Taschenleiste nur bei Maus darüber.|r Unter Aktionsleisten → Anordnung stellst du beide auf „Nur bei Maus darüber“: unsichtbar, bis die Maus in die Nähe kommt, dann blenden sie weich ein. Anklicken geht auch unsichtbar.",
        },
    },
    {
        version = "6.3.0.7",
        date    = "25.09.2026",
        notes   = {
            "|cff7C6CFFSchadensanzeige: Aufschlüsselung wie bei Details.|r Klick auf einen Namen in der Schadensanzeige öffnet daneben ein eigenes Fenster: Gesamt, je Sekunde, Anteil und Rang, darunter jeder Zauber mit Balken, Summe, Wert je Sekunde und Anteil. Oben schaltest du zwischen Schaden, Heilung und erlittenem Schaden desselben Spielers um, die Pfeile blättern zum nächsten. Es läuft im Kampf live mit; Esc oder ein zweiter Klick schließt.",
            "|cff7C6CFFDer Chat im neuen Kleid.|r Die Reiter bleiben sichtbar – das Spiel hatte sie trotz Einstellung ausgeblendet. Unter dem Chat steht eine Infozeile wie bei ElvUI: Uhrzeit, Gold, freie Taschenplätze, Haltbarkeit, Bildrate und Latenz; beim Schreiben liegt die Eingabezeile darüber. Klick auf die Uhrzeit öffnet den Kalender, auf Gold oder Taschen die Taschen.",
            "|cff7C6CFFTaschenleiste im Stil der Aktionsleisten.|r Die Taschenplätze unten rechts sind flach mit feinem Rand und stehen auf einer Fläche, wie die Aktionsleisten – die goldenen Rahmen sind weg.",
        },
    },
    {
        version = "6.3.0.6",
        date    = "25.09.2026",
        notes   = {
            "|cff7C6CFFAktionsleisten verschiebst du wieder im Bearbeitungsmodus des Spiels.|r Das Spiel stapelt Leiste 2, Haltungs- und Begleiterleiste auch im Kampf selbst neu, etwa wenn dein Begleiter verschwindet – nachdem WeintCodex die Leisten verschoben hatte, blockierte das Spiel diesen eigenen Schritt und meldete einen Fehler. Verschieben geht jetzt nur noch im Bearbeitungsmodus des Spiels (Esc → Bearbeitungsmodus); dort verschobene Leisten lässt das Spiel an ihrem Platz. Größe, Abstand, Reihen und Anzahl der Knöpfe stellst du weiter unter Aktionsleisten → Leisten ein.",
        },
    },
    {
        version = "6.3.0.5",
        date    = "25.09.2026",
        notes   = {
            "|cff7C6CFFVerschobene Aktionsleisten bleiben, wo du sie hinstellst.|r Leiste 2 und 3 stehen im Spiel in einem Bereich, den das Spiel selbst ordnet, sobald sich unten etwas ändert – etwa die Erfahrungsleiste. Dabei rückte es eine verschobene Leiste alle paar Minuten ein Stück zur Seite. Jetzt kommt sie jedes Mal sofort an ihren Platz zurück.",
        },
    },
    {
        version = "6.3.0.4",
        date    = "25.09.2026",
        notes   = {
            "|cff7C6CFFAktionsleisten einstellen wie bei EllesmereUI.|r Unter Oberfläche → Aktionsleisten → Leisten stellst du für jede Leiste Symbolgröße, Abstand, Knöpfe je Reihe und Anzahl ein, dazu die Fläche und „Nur bei Maus darüber“. Verschieben geht im Gestaltungsmodus, ein Doppelklick auf eine Leiste öffnet ihre Einstellungen, Rechtsklick gibt sie dem Bearbeitungsmodus des Spiels zurück. Leisten ohne belegten Knopf bekommen keine leere Fläche mehr.",
        },
    },
    {
        version = "6.3.0.3",
        date    = "25.09.2026",
        notes   = {
            "|cff7C6CFFJede Aktionsleiste steht auf einer eigenen Fläche.|r Eine dunkle Kachel mit feinem Rand hinter den Knöpfen, die jeder Anordnung aus dem Bearbeitungsmodus folgt. Tastenkürzel oben rechts, Stapelzahl unten rechts, die Blätterpfeile neben Leiste 1 sind weg (Umblättern weiter mit Umschalt+Mausrad). Beides unter Aktionsleisten → Leisten abschaltbar.",
            "|cff7C6CFFKeine Auren-Prüfung mehr im Chat.|r Die Debuffs auf den Plaketten sind bestätigt; /wcui auren gibt die Auskunft weiter auf Wunsch und sagt ehrlich „nicht messbar“, wo das Spiel die Symbole geheim hält.",
        },
    },
    {
        version = "6.3.0.2",
        date    = "25.09.2026",
        notes   = {
            "|cff7C6CFFAktionsleisten mit einem Rahmen.|r Der innere Rahmen des Spiels um jedes Symbol bleibt weg – das Spiel hatte ihn bei jedem Aktualisieren neu gesetzt. Das Symbol füllt den Knopf, darum liegt nur noch eine feine Kante.",
            "|cff7C6CFF/wcui auren funktioniert wieder.|r Die Auren-Prüfung brach an Werten ab, die das Spiel geheim hält, und schrieb dabei Lua-Fehler – jetzt steht dort „?“.",
        },
    },
    {
        version = "6.3.0.1",
        date    = "25.09.2026",
        notes   = {
            "|cff7C6CFFDebuffs stehen an ihrem Platz, ohne Lua-Fehler.|r Die Debuff-Symbole der Plakette des Spiels bleiben, wo das Spiel sie hinsetzt – WeintCodex blendet nur den Rest der Spielplakette aus. Der weiße Balken über dem Namen und der Fehler „Can't measure restricted regions“ sind weg.",
        },
    },
    {
        version = "6.3.0.0",
        date    = "25.09.2026",
        notes   = {
            "|cff7C6CFFDer Zielrahmen ist beim Anklicken sofort gefüllt.|r Manchmal erschien er als weißer Balken ohne Namen – er wurde sichtbar, bevor er seine Werte bekam.",
            "|cff7C6CFFDebuffs auf den Namensplaketten kommen jetzt vom Spiel selbst.|r WeintCodex hängt die Debuff-Symbole der Plakette des Spiels an die eigene Plakette. Die eigenen Symbole bleiben unter Namensplaketten → Auren wählbar. Beim ersten Kampf mit einem Ziel schreibt WeintCodex einmal eine kurze Auren-Prüfung in den Chat – ein Screenshot davon hilft bei der Fehlersuche.",
            "|cff7C6CFFDer Chat ist eine ruhige Fläche.|r Reiterzeile oben mit feiner Linie, die Reiter bleiben sichtbar, die Knöpfe des Spiels stehen klein rechts in der Reiterzeile, die Eingabezeile sitzt bündig darunter.",
            "|cff7C6CFFDie Schadensanzeige kann mehr.|r Klassensymbole, Anteil in Prozent, deine eigene Zeile immer sichtbar und markiert, Maus über einer Zeile zeigt die Zauber dieses Spielers, und der Zeitraum schaltet auch auf frühere Kämpfe. Die unsinnige Kampfdauer („70889:57“) ist weg.",
            "|cff7C6CFFRahmen verschieben im Gestaltungsmodus.|r Das Einstellungsfenster schließt sich von selbst, oben erscheint eine Leiste mit Testdaten, Raster, Einrasten, Zurücksetzen und „Fertig“. Rahmen anklicken, mit den Pfeiltasten genau schieben (Umschalt: 8), Doppelklick öffnet seine Einstellungen, Esc beendet – und das Fenster ist wieder da.",
            "|cff7C6CFFAktionsleisten ohne leere Kästen.|r Leere Plätze sind weg und erscheinen nur, wenn du einen Zauber ziehst. Flache Hervorhebung, ein leichter Schatten am Symbol, die Abklingzahl in der WeintCodex-Schrift, kein Reichweitenpunkt mehr.",
        },
    },
    {
        version = "6.2.0.0",
        date    = "24.09.2026",
        notes   = {
            "|cff7C6CFFDebuffs: WeintCodex hilft sich jetzt selbst.|r Nennt das Spiel Auren am Gegner und die Symbole erscheinen trotzdem nicht, liest WeintCodex sie selbst und sagt es einmal im Chat. /wcui auren zeigt mit einem Gegner als Ziel, was das Spiel meldet und was davon zu sehen ist; unter Namensplaketten → Auren lässt sich der Weg auch von Hand wählen.",
            "|cff7C6CFFSpieler- und Zielrahmen reagieren wie die Plaketten.|r Die Maus hellt sie auf, fehlendes Leben ist dunkel in der Balkenfarbe, und die Stufe des Ziels steht in der Farbe ihrer Schwierigkeit, Elite mit „+“. Ein Porträt ohne Modell zeigt das Bild statt eines schwarzen Kästchens.",
            "|cff7C6CFFKombopunkte als fünf einzelne Segmente|r mittig unter der Figur.",
            "|cff7C6CFFKurze Tastenkürzel auf den Aktionsknöpfen:|r „M4“ statt „Maustaste 4“, „S1“ statt „s-1“.",
            "|cff7C6CFFDie Schadensanzeige ist so hoch wie ihr Inhalt.|r Keine leere schwarze Fläche mehr unter einer einzigen Zeile.",
            "|cff7C6CFFHinrichtungsmarke auf Wunsch:|r ein fester Strich im Plakettenbalken zeigt, ab wann Hinrichten wirkt (Namensplaketten → Allgemein).",
        },
    },
    {
        version = "6.1.0.0",
        date    = "24.09.2026",
        notes   = {
            "|cff7C6CFFDie Oberfläche hat ein neues Gesicht.|r Balken mit leichtem Glanz, weiche Schatten statt harter Kanten und eine schmale Schrift, die Namen und Zahlen mehr Platz lässt.",
            "|cff7C6CFFNamensplaketten, die auf dich reagieren.|r Die Maus hellt eine Plakette auf, dein Ziel leuchtet und trägt Marken links und rechts, alle anderen treten zurück. Fehlendes Leben ist dunkel in der Farbe des Gegners statt schwarz.",
            "|cff7C6CFFSpieler und Ziel stehen spiegelbildlich um die Bildschirmmitte.|r Kombopunkte und dein Zauberbalken liegen mittig darunter, die Gruppe links neben dir, die Schadensanzeige unten rechts.",
            "|cff7C6CFFAußerhalb des Kampfes wird es ruhig.|r Ohne Ziel und bei vollem Leben treten Spielerrahmen und Leisten zurück. Ein Ziel, ein Treffer oder die Maus holen sie sofort zurück – einstellbar unter /wcui, Reiter „Ruhe und Kampf“.",
            "|cff7C6CFFTestmodus: alles auf einen Blick.|r /wcui test zeigt Ziel, Fokus, eine Beispielgruppe, Zauberbalken und Schadensanzeige mit Beispielwerten – ohne Gruppe und ohne Kampf.",
        },
    },
    {
        version = "6.0.0.6",
        date    = "24.09.2026",
        notes   = {
            "|cff7C6CFFDebuffs auf Namensplaketten und am Zielrahmen sollten jetzt erscheinen.|r Bisher blieben sie unsichtbar. Klappt es noch nicht, meldet WeintCodex im Chat einmal, woran es scheitert – unter /wcui → Namensplaketten → Auren steht dasselbe.",
            "|cff7C6CFFDie Questliste ohne goldenes Banner.|r Kopfzeilen hell in der Schrift von WeintCodex, dahinter die dunkle Fläche.",
            "|cff7C6CFFChatreiter lesbar.|r Die Namen werden nicht mehr abgeschnitten, der aktive Reiter ist hell und unterstrichen.",
            "|cff7C6CFFDer Questpfeil steht ganz oben.|r Er lag mitten in den roten Fehlermeldungen des Spiels.",
            "|cff7C6CFFAufgeräumte Minikarte.|r Tageszeit-Symbol und WeintCodex-Knopf stehen mit den anderen Knöpfen in der Spalte links, statt auf der Karte zu liegen.",
            "|cff7C6CFFEnergie ist gelb.|r Die Kraftleiste nahm bei manchen Klassen die falsche Farbe. Leere Aktionsplätze sind nur noch angedeutet.",
        },
    },
    {
        version = "6.0.0.5",
        date    = "24.09.2026",
        notes   = {
            "|cff7C6CFFKeine Fehlermeldung „Font not set“ mehr beim Angreifen.|r Sie kam, wenn ein Gegner schon zauberte, während seine Namensplakette erschien.",
            "|cff7C6CFFDer Questpfeil ist dreidimensional und zeigt mit der Farbe, wie gut du liegst.|r Grün geradeaus, gelb quer, rot in die falsche Richtung. Als Geist zeigt er von selbst zu deiner Leiche, und nach dem Abgeben wählt er die nächstgelegene Quest aus deinem Questlog – wenn du willst, schon sobald die Ziele erfüllt sind.",
            "|cff7C6CFFDie Schadensanzeige kann bis zu vier Fenster.|r Jedes mit eigener Messart und eigenem Zeitraum, dazu Kampfdauer in der Kopfzeile und Knöpfe für neues Fenster, Leeren und Einstellungen. Pro Sekunde steht jetzt eine runde Zahl statt vieler Nachkommastellen.",
            "|cff7C6CFFNamensplaketten zeigen deinen Questfortschritt und die Restzeit deiner Debuffs.|r Gehört ein Gegner zu einer deiner Quests, steht links vom Namen, wie weit du bist, etwa „8/10“. Über jedem Debuff-Symbol stehen die verbleibenden Sekunden.",
            "|cff7C6CFFSpieler, Ziel und Fokus zeigen ein Porträt.|r Als 3D-Modell oder Bild, einstellbar je Rahmen; beim Ziel rechts, gespiegelt zum Spieler.",
            "|cff7C6CFFMinikarte und Chat aufgeräumt.|r Koordinaten und Uhrzeit oben in der Karte, das Gebiet unten; die Knöpfe des Spiels stehen bei Karte und Chat in einer Spalte am Rand. Der aktive Chatreiter ist hell und unterstrichen.",
            "|cff7C6CFFMikromenü unten links, Taschenleiste unten rechts, die Questliste auf eigener Fläche.|r Jeweils abschaltbar, wenn du die Anordnung des Spiels behalten willst.",
        },
    },
    {
        version = "6.0.0.4",
        date    = "24.09.2026",
        notes   = {
            "|cff7C6CFFGruppen- und Schlachtzugsrahmen erscheinen.|r Beim Einloggen brach ihr Aufbau mit einer Fehlermeldung ab.",
            "|cff7C6CFFDie Schadensanzeige öffnet sich.|r Ihr Fenster brach beim Aufbau ab, und im Chat stand eine Fehlermeldung.",
            "|cff7C6CFFDie Taschen zeigen ihre Gegenstände.|r Die Plätze standen da, aber leer. Unten im Fenster steht jetzt, wie viele Plätze belegt sind.",
            "|cff7C6CFFDer Chat bekommt seinen Stil wirklich.|r Sein Umbau brach beim Start ab; die Knöpfe am Rand und die Rahmen der Reiter blieben stehen.",
            "|cff7C6CFFÜber der Minikarte stehen Gebiet und Uhrzeit nur noch einmal.|r Die Kopfleiste des Spiels verschwindet, solange die eigenen Texte an sind.",
        },
    },
    {
        version = "6.0.0.3",
        date    = "24.09.2026",
        notes   = {
            "|cff7C6CFFDie WeintCodex-Oberfläche ist jetzt für alle eingeschaltet.|r Der Forever-Client speichert Addon-Einstellungen derzeit nicht über ein Neuladen hinweg – eine Wahl „an“ oder „aus“ wäre danach vergessen. Sobald er wieder speichert, wird sie wieder freiwillig. Einzelne Teile schaltest du mit /wcui ab.",
            "|cff7C6CFFGruppen- und Schlachtzugsrahmen im Stil von WeintCodex.|r Klassenfarbe, Name, Leben in Prozent oder fehlendes Leben, abgeblendet außer Reichweite, roter Rand bei Aggro und die Debuffs, die du bannen kannst.",
            "|cff7C6CFFDebuffs über gegnerischen Plaketten, und freundliche Plaketten.|r Deine Debuffs stehen über dem Gegner; Freunde zeigen ihren Namen in Klassenfarbe. In Dungeons und Schlachtzügen bleiben die freundlichen Plaketten die des Spiels – das Spiel sperrt sie dort für Addons.",
            "|cff7C6CFFAktionsleisten, Minikarte und Chat im Stil von WeintCodex.|r Flache Knöpfe mit feinem Rand und roter Schicht außer Reichweite; eine eckige Minikarte mit Mausrad-Zoom, Koordinaten und Uhrzeit; Chatfenster mit eigener Schrift, ruhigem Hintergrund und schlichter Eingabezeile.",
            "|cff7C6CFFAlle Taschen in einem Fenster.|r Suche, Sortieren, Gold, Gegenstandsstufe auf Ausrüstung und Rand in Qualitätsfarbe. Benutzen, Anlegen und Verkaufen funktionieren wie gewohnt.",
            "|cff7C6CFFEine Schadensanzeige.|r Schaden, Heilung, erlittener Schaden, Unterbrechungen, Bannungen und Tode, für den laufenden Kampf oder die ganze Sitzung – gemessen vom Spiel selbst.",
            "|cff7C6CFFOptionen, die von Haus aus an sind, lassen sich jetzt ausschalten.|r Vorher sprangen sie beim nächsten Lesen wieder auf „an“.",
        },
    },
    {
        version = "6.0.0.2",
        date    = "24.09.2026",
        notes   = {
            "|cff7C6CFFDie Frage zur WeintCodex-Oberfläche kommt nach einem Neuladen nicht mehr wieder.|r Sie erscheint nur noch beim Einloggen. Vorher konnte sie nach „Ja, verwenden“ und „Jetzt neu laden“ in einer Schleife wiederkehren.",
            "|cff7C6CFFWeintCodex sagt dir, wenn der Client nicht gespeichert hat.|r Die Forever-Beta speichert Addon-Einstellungen beim Neuladen nicht immer. Passiert das, steht es im Chat – und unter Einstellungen → Diagnose steht, ob das letzte Neuladen gespeichert hat.",
        },
    },
    {
        version = "6.0.0.1",
        date    = "24.09.2026",
        notes   = {
            "|cff7C6CFF„Jetzt neu laden“ funktioniert auf Forever.|r Der Knopf nach der Frage zur WeintCodex-Oberfläche und der im Einstellungsfenster meldeten vorher nur, dass eine geschützte Funktion blockiert wurde – jetzt laden sie neu.",
            "|cff7C6CFFAuch „Synchronisation starten“ und „Anmeldungen abrufen“ laden wieder neu.|r Beide Knöpfe hatten denselben Fehler.",
        },
    },
    {
        version = "6.0.0.0",
        date    = "24.09.2026",
        notes   = {
            "|cff7C6CFFWeintCodex bringt jetzt ein eigenes Interface mit – ganz freiwillig.|r Namensplaketten und Einheitenrahmen im Stil von WeintCodex, einstellbar in einem eigenen Fenster (/wcui). Beim ersten Einloggen fragt WeintCodex, ob du es verwenden möchtest; bei „Nein“ bleibt alles, wie das Spiel es zeigt, und du kannst es jederzeit in den Einstellungen unter „Oberfläche“ nachholen.",
            "|cff7C6CFFGegnerische Namensplaketten zeigen auf einen Blick, woran du bist.|r Farbe nach Lage (im Kampf, noch nicht im Kampf, neutral, von anderen markiert, Boss, Elite), die Stufe links, das Leben rechts, dazu Zauberbalken mit Unterbrechbarkeit und ein Rahmen um dein Ziel.",
            "|cff7C6CFFSpieler, Ziel, Ziel des Ziels, Fokus und Begleiter bekommen schlichte Rahmen.|r Mit Zauberbalken, den Buffs und Debuffs deines Ziels und Kombopunkten für Schurken und Druiden in Katzengestalt. Mit „Rahmen entsperren“ ziehst du alles an seinen Platz.",
            "|cff7C6CFFEin Questpfeil zeigt dir den Weg zur ausgewählten Quest.|r Wähle eine Quest im Questlog oder setze eine Kartenmarkierung – der Pfeil zeigt die Richtung, darunter stehen Entfernung und ungefähre Ankunftszeit. Er funktioniert auch ohne das neue Interface.",
            "|cff7C6CFFKleine Helfer für den Alltag, jeder einzeln zuschaltbar.|r Automatisch reparieren, graue Gegenstände verkaufen, schneller plündern, Löschbestätigung ausfüllen, Filmsequenzen überspringen, Kampfhinweis, Bildrate, Haltbarkeitswarnung und Koordinaten auf der Weltkarte. Alle sind von Haus aus aus.",
            "|cff7C6CFFWeintCodex erkennt den Forever-Client unter einer weiteren Kennung.|r Damit sollte das Addon in der Addon-Liste nicht mehr als „veraltet“ erscheinen.",
        },
    },
        {
        version = "5.2.1.1",
        date    = "23.09.2026",
        notes   = {
            "|cff7C6CFFDas Update ist jetzt kleiner.|r Die Dungeon-Bilder sparen sich unnötige, nie angezeigte Zusatzstufen - ohne dass sich an der Darstellung etwas ändert.",
        },
    },
    {
        version = "5.2.1.0",
        date    = "23.09.2026",
        notes   = {
            "|cff7C6CFFVier weitere klassische Dungeons sind jetzt bebildert.|r Ruins of Lordaeron, Wailing Caverns, The Deadmines und Shadowfang Keep zeigen jeweils ein eigenes Header-Artwork und eigene Bossdarstellungen.",
            "|cff7C6CFFDas Dungeon-Artwork-System ist weiter ausgebaut.|r Neue Dungeons werden über dieselbe gemeinsame Struktur eingebunden, ohne eigene UI-Sonderlogik pro Dungeon.",
        },
    },
    {
        version = "5.2.0.8",
        date    = "23.09.2026",
        notes   = {
            "|cff7C6CFFHall of Thanes ist jetzt bebildert.|r Der Dungeon zeigt ein eigenes Header-Artwork und jeder Boss seine eigene Darstellung.",
            "|cff7C6CFFDie Dungeon-Bilder geben den Einträgen mehr Atmosphäre.|r Die Informationen bleiben dabei unverändert und weiterhin klar lesbar.",
        },
    },
    {
        version = "5.2.0.7",
        date    = "22.09.2026",
        notes   = {
            "|cff7C6CFFDie Bosse eines Dungeons sehen aus wie Einträge, nicht wie Schaltflächen.|r Jede Karte hat oben ihre Nummer und unten den Namen in der Überschriftenschrift, auf einem Grund, der nach unten hin dunkler wird. Die ausgewählte Karte färbt die Fläche, auf der ihr Name steht – nicht nur ihren Rand.",
            "|cff7C6CFFDer Dungeon wird oben aufgeschlagen, nicht angesagt.|r Sein Name steht grösser, der Themensatz steht als Spalte darunter statt quer über die Fläche, und nach rechts hin läuft die Fläche in den Akzent aus. Die Eckdaten stehen darunter auf eigenem, dunklerem Grund – und ob deine Stufe passt, steht am rechten Rand für sich.",
            "|cff7C6CFFDer Bossbereich hat jetzt das Gewicht, das ihm zusteht.|r Die Rubrik darüber zieht eine Linie bis zur Herkunft, und die Karten werden so hoch, wie die Seite es hergibt – in einem grösseren Fenster höher als in einem kleinen. Bei Dungeons mit sehr vielen Bossen bleiben sie eng, damit unten nichts abgeschnitten wird.",
            "|cff7C6CFFDie Fläche unter den Bossen ist nur noch so gross wie ihr Inhalt.|r Vorher stand dort eine halbleere Karte, weil die Seite mit der Breite des kleinsten Fensters rechnete statt mit deinem. Besonderheiten, Aufstellung und Herkunft stehen jetzt dicht beieinander, vollständig und ohne Leerlauf darunter.",
            "|cff7C6CFFWoher eine Bossliste stammt, braucht nur noch zwei Zeilen.|r Die Überschrift steht neben der Quelle statt darüber – dieselbe Auskunft, in der Grösse, die ihr zusteht.",
        },
    },
    {
        version = "5.2.0.6",
        date    = "22.09.2026",
        notes   = {
            "|cff7C6CFFDer Dungeon wird aufgeschlagen, nicht aufgelistet.|r Name, Themensatz und alle Eckdaten stehen auf einer eigenen Fläche am Seitenkopf – mit einem Akzentstreifen an der Kante, der sagt, wo du bist.",
            "|cff7C6CFFGebiet, Stufen, Spieler und Bosse stehen als Band, nicht als Satz.|r Jede Angabe hat ihre eigene Spalte: die Zahl oben, wofür sie steht darunter. Ob deine Stufe passt, steht in derselben Reihe und in der Farbe, die es meint. Wie viele Spalten in eine Zeile passen, rechnet die Seite aus der wirklichen Breite aus.",
            "|cff7C6CFFDie Bosskarten sehen aus wie Karten, nicht wie Eingabefelder.|r Sie tragen den Kartenverlauf des Addons, der Name steht in Lesefarbe, und „Optional\" oder „Beschwören\" hängt als Pille oben rechts statt frei daneben. Der ausgewählte Boss bekommt den violetten Ton der Auswahl, nicht nur einen Strich.",
            "|cff7C6CFFUnter den Bossen stehen zwei Spalten statt einer.|r Links „Besonderheiten\" – wie viele Bereiche der Dungeon hat, welcher Boss nur auf Beschwörung erscheint, welche neben dem Hauptweg stehen, ob die Reihenfolge bekannt ist. Rechts die Aufstellung. Nichts davon ist erfunden; alles kommt aus dem Bestand.",
            "|cff7C6CFFWoher die Bossliste stammt, ist eine Fusszeile geworden.|r Drei Zeilen unter einer Haarlinie statt zweier Absätze mitten auf der Seite – dieselbe Auskunft, an der Stelle, die ihr zusteht.",
            "|cff7C6CFFDer geöffnete Boss trägt seinen Namen in der Überschriftenschrift.|r Und seine Notiz steht als ruhiger Satz direkt darunter, nicht als vierter Abschnitt zwischen den anderen.",
        },
    },
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
