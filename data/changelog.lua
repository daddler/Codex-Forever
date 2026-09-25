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
