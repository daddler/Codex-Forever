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
