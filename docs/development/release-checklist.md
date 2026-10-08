# Prüfliste im Spiel – vor jedem Release

Der Ladetest prüft gegen eine Attrappe des Clients. Grün heißt „lädt“,
nicht „sieht richtig aus“ und nicht „lässt sich bedienen“. Beispiele aus
dem Beta-Test: Das Mikromenü ließ sich von 6.0.0.5 bis 6.9.1.0 nicht
verschieben. In 6.9.0.8 liefen die Reiter der Aufschlüsselung aus dem
Fenster. Beides hätte ein einziger Blick im Spiel gezeigt.

Diese Liste dauert etwa zehn Minuten. Sie ersetzt keinen Beta-Test,
sondern fängt das Offensichtliche ab, **bevor** es Spieler melden.

## Vorbereitung (1 Minute)

- [ ] Neueste Fassung installiert, `/reload`. Im Chat steht die richtige
      Versionsnummer.
- [ ] Keine Lua-Fehler beim Laden. `/console scriptErrors 1` muss an sein,
      sonst sieht man sie nicht.
- [ ] `/wcui speicher`: Kein Modul legt im Leerlauf merklich Speicher an.
- [ ] `/wcui prüfen`, einmal mit einem Gegner im Ziel: Jede `[!]`-Zeile ist
      ein Befund. Den Bericht kopieren und mit den Notizen ablegen.

## Verschieben (2 Minuten)

- [ ] Gestaltungsmodus öffnen (`/wcui`, „Gestaltungsmodus“). **Jeden**
      Rahmen einmal ziehen. Danach `/reload`: Steht alles noch dort?
- [ ] Rechtsklick auf einen Rahmen setzt ihn zurück.
- [ ] Gestaltungsmodus → „Bearbeitungsmodus des Spiels“ und wieder zurück.
      Das Einstellungsfenster öffnet sich auf derselben Seite.
- [ ] Im Bearbeitungsmodus des Spiels eine Aktionsleiste verschieben und
      schließen. Die Leiste bleibt dort.

## Einstellungen (2 Minuten)

- [ ] Jedes Modul links einmal anklicken, jede Seite oben einmal. Nichts
      läuft über den Rand, kein Text liegt auf einem anderen.
- [ ] Die Suche oben: Ein Wort tippen, einen Treffer anklicken. Die
      richtige Seite öffnet sich, bei Feineinstellungen aufgeklappt.
- [ ] „Erweitert“ ein- und ausblenden.
- [ ] Eine Einstellung ändern, die „Neu laden“ verlangt. Der Knopf
      erscheint und lädt neu.
- [ ] Profile (`/wcui profil`): Nach dem ersten Laden steht „Standard“ mit
      allen bisherigen Einstellungen. „Als Kopie anlegen“, neu laden, eine
      Einstellung und einen Rahmen ändern. Mit einem zweiten Charakter
      einloggen: er hat „Standard“, unverändert. Profil wählen, neu laden –
      Einstellung und Platz sind da.
- [ ] Mit einem Charakter ohne eigenes Profil einloggen: Die Frage „Eigenes
      Profil für …?“ kommt einmal, nicht neben dem Willkommen oder dem
      Update-Hinweis; Knöpfe nebeneinander, kein Text abgeschnitten. „×“,
      neu einloggen: sie kommt wieder. „Standard behalten“: nie wieder.

## Fenster des Spiels (3 Minuten)

Jedes einmal öffnen. Nichts darf aussehen wie halb alt, halb neu. Wenn
doch: `/wcui fenster` und den Bericht kopieren (Strg+C).

- [ ] Berufe (`/wc berufe`): links deine Berufe mit Fertigkeit zuerst; Rezepte in Fächern mit Farben orange/gelb/grün/grau, Tooltip mit Reagenzien und Herkunft; einmal das Berufsfenster öffnen – danach steht „Gelernt“ richtig und „Bringt noch Fertigkeit“ erscheint; Lehrer: unter denen, die deinen nächsten Rang lehren, der nächste oben (in Eisenschmiede/Sturmwind nicht der Fachmann im Hinterland), Zeile „Ort · bis 150“ ohne abgeschnittenen Ort, „Karte“ setzt die Marke; ohne Berufsfenster im Detailbereich „bis zu“/„mind.“; `/wcui prüfen` → Zeile „Berufe“ ablegen (Ereignisse > 0 nach dem Öffnen, Nummern im Bestand > 0)
- [ ] Dungeons aus dem Abgleich: Blackrock-Tiefen mit Quests (Geber „…, im Dungeon“, „Vorher/Danach“), Herkunftszeilen „Quests: Addon ForeverGuide“ und „Beute aus Classic“; „Eingang auf der Karte“ setzt die Marke (Stratholme: zwei Knöpfe)
- [ ] Navigationsspalte: vier Gruppen Leveln, Gruppe, Gilde, System, kein
      „Import“ mehr; Companion hat die Reiter Synchronisierung und Import.
      `/wc import` öffnet Companion mit dem Reiter Import, Companion ist
      links markiert. Rechtsklick auf das Minikartensymbol: Schlachtzüge,
      links markiert.
- [ ] Codex-Übersicht (/wc): höchstens drei Schritte, jeder Knopf landet am Ziel (Dungeon-Knopf auf dem genannten Dungeon); „Dein Weg“ ohne abgeschnittene Namen, zwei Dungeons auf einer Stufe stehen beide da (zweite Zeile); kein Dungeon der anderen Fraktion (Allianz: kein Ragefire Chasm); mit lernbaren Zaubern stehen ihre Namen mit Symbol unter „Als Nächstes“ (Tooltip beim Drüberfahren), eine Stufe im Weg zeigt beim Drüberfahren ihre Zauber
- [ ] Charakter (C), Zauberbuch und Talente (P, N), Weltkarte (M)
- [ ] Zauberbuch und Talente: hinter „Allgemein“ und den Namen der Bäume Raute **und** Linie; sonst `/wcui fenster` – die Zeile „Linie: …“ sagt Höhe und Bildpunkte
- [ ] Händler, Bank, Post (beide Reiter), Auktionshaus, Handel
- [ ] Post: keine dunkle Fläche rechts oder unten neben dem Fenster; Gildenbank: Reiter flach, Betrag ohne Goldrahmen, kein Wappen über dem Rand; Gildenmitglieder ohne graue Bänder; Gildenchat: Eingabezeile flach
- [ ] Kontakte (O): Freunde, Kürzliche Verbündete, Schlachtzug
- [ ] Kontakte neu (6.20.0.0, `SocialUIFrame`): kein Metall, kein rotes Symbol, kein roter Knopf; Seitenreiter als Kachel, der gewählte in Gold – auch nach Wechsel; BattleTag-Zeile ohne braunes Band, Status und Suche flach; Fenster ziehbar; `/wcui fenster` auf jedem Reiter – kein „SOLLTE WEG SEIN“
- [ ] Klassenquests (`/wc klassenquests`, Reiter unter Lehrer): Reiterleiste „Zauber und Waffen“ | „Klassenquests“; Quests nur deines Volkes; erledigte zugeklappt, Stand „Im Questlog“/„Abgabebereit“ wie im Questlog; Namen deutsch (nach kurzem Nachladen); Zeile mit Zauber zeigt „Lehrt …“; Klick setzt die Marke am Geber; rechts der nächstgelegene Klassenlehrer oben; Startseite nennt eine Klassenquest mit Zauber, wenn eine dran ist
- [ ] Lehrer (Klasse und Beruf): eine Zeile wählen – sie bleibt markiert; beim Berufslehrer die Leiste oben blau, flach, ohne grauen Rahmen
- [ ] Erinnerungen → Regeln auf einem Charakter mit Regeln anderer Klassen: nur die eigenen stehen da, darunter „N Regeln anderer Klassen ausgeblendet“ und „Alle zeigen“; Entfernen löscht die Zeile, auf der der Knopf steht
- [ ] Als Jäger mit Begleiter: `/wcui prüfen`, Zeile „Begleiter“ – den Bericht ablegen, bis die Laune lesbar ist
- [ ] Als Jäger mit Begleiter: links am Begleiterrahmen ein Punkt in der Farbe der Laune (Tooltip „Laune: …“), gleich dem Gesicht im Charakterfenster; Erinnerungen → Regeln, „Begleiter nicht glücklich“ anlegen – bei „zufrieden“ kommt „Begleiter zufrieden – füttern“, nach dem Füttern geht sie
- [ ] Bedrohungsleiste an den Plaketten: allein ohne Begleiter keine; als Tank in der Gruppe zeigt sie den Nächsten und wird orange, wenn er nah dran ist
- [ ] Bedrohungsfarben in der Gruppe: der Lebensbalken wird rot, wenn du als DD die Aggro ziehst, orange kurz davor; allein bleibt er in seiner Farbe
- [ ] Fenster verschieben: Charakterfenster ziehen, schließen, wieder öffnen – steht wieder am Platz des Spiels; Umschalt+Rechtsklick setzt zurück; Zauberbuch im Kampf öffnen – keine Fehlermeldung
- [ ] Auktionspreise (Komfort → Auktionshaus an): Auktionshaus öffnen – Knopf „Preise scannen“ oben, überdeckt nichts; klicken – Fortschritt im Knopf, danach Zeile im Chat mit Angeboten und Gegenständen; Tooltip eines Gegenstands in der Tasche zeigt „Auktionshaus ab …“, Stapel, Tag und Menge; `/wcui auktion` → Bericht ablegen (welcher Weg: Vollscan oder Suche, vollständig?)
- [ ] Flüstern (Komfort → Flüstern an): sich anflüstern lassen – Fenster geht auf, Name in Klassenfarbe, Zeile auch im Chat; zweites Gespräch zeigt eine Zahl links; im Kampf erst danach; Klick in die Antwortzeile öffnet die Chatzeile mit „/w Name“; Battle.net-Freund: Name lesbar?; einmal „Direkt aus dem Fenster senden“ an – kommt es an oder meldet das Spiel eine Sperre? `/wcui prüfen` → Zeile „Flüstern“ ablegen
- [ ] Flüstern nur im Fenster (6.19.1.0): angeflüstert – steht es **nicht** im Chat, Ton kommt (einmal, nicht doppelt)?; Fenster am Kopf ziehen, nach /reload noch dort?; in den Kampf – Fenster klappt ein, Flüstern im Kampf zählt am Symbol, nach dem Kampf geht es wieder auf; „/w Name “ tippen und Klick auf einen Namen im Chat – Gespräch geht auf, danach `/cast` aus der Chatzeile geht noch (keine Sperre); Symbol: Klick auf/zu, ziehen; `/wcui prüfen` → Zeile „Chatfilter“ ablegen
- [ ] Flüstern, Zahl am Symbol (6.19.1.1): anflüstern lassen, Maus weg vom Fenster – Punkt mit „1“ am Symbol und links im Gespräch; zweite Nachricht – „2“; Maus über das Fenster – Zahl weg; Systemzeilen (z. B. Erfahrung, Beute) stehen weiter im Chat
- [ ] Flüstern, Taste R (6.19.1.2): angeflüstert, Fenster zu – R öffnet das Fenster bei ihm, Chatzeile zeigt „Flüstern an <Name>“; im Kampf ebenso; danach `/cast` aus der Chatzeile ohne Sperre; die Zeile ist leer (kein „r“, 6.19.1.3)
- [ ] Karte (6.20.0.0, Komfort → Karte an): Weltkarte auf Westfalen – Symbol am Eingang der Todesminen, Maus zeigt Dungeon und Stufe, Klick öffnet den Codex; Sengende Schlucht – ein Symbol, drei Dungeons im Tooltip; Östliche Königreiche – Symbole an den richtigen Stellen?; liegen sie über oder unter den Questmarken des Spiels?; im Kampf Karte öffnen und Quest verfolgen – keine Sperre; `/wcui prüfen` → „Karte“ ablegen
- [ ] Karte aufdecken (6.20.0.0, „Ganze Karte zeigen“ an): eine Zone mit Erkundetem und Unerkundetem – unerkundete Gebiete da und dunkler, Übergänge ohne Fugen oder Versatz, keine grünen Flächen; eine nie besuchte Zone ganz sichtbar; „Unerkundetes abdunkeln“ aus – gleich hell; Questmarken liegen darüber; `/wcui prüfen` → „Karte“: „passen nicht“ sollte 0 sein
- [ ] Kopf im Balken (6.20.0.0, Einheitenrahmen → Spieler/Ziel → Porträt „Im Balken (animiert)“): Kopf sichtbar und bewegt, mittig, nicht abgeschnitten oder riesig; Name und Werte gut lesbar; Deckkraft-Regler wirkt; Ziel außer Sichtweite – kein Kopf, kein schwarzer Balken; zurück auf „3D-Modell“ – Porträt wieder links
- [ ] Kopf im Balken weiter weg (6.21.0.0): ab Werk mehr vom Kopf zu sehen; Regler „Kopf im Balken: Abstand“ (Feinheiten) wirkt sofort
- [ ] Geistheiler und Übergänge (6.21.0.0, Komfort → Karte beide an): Eschental – sieben grüne Punkte, Pfeile zu Steinkrallengebirge, Teufelswald, Azshara, Brachland; zeigen sie in die richtige Richtung?; Maus auf Pfeil: „Nach <Gebiet>“ auf Deutsch; Kontinentkarte nur mit Reisen (Schiffe, Zeppeline), ohne Geistheiler, Pfeile, Flugmeister (6.21.2.0); `/wcui prüfen` → „Karte“
- [ ] Geistheiler mitten in Eschental (Astranaar) sichtbar, nicht nur am Rand (6.22.0.2); `/wcui prüfen` → „Ebenen: … Symbole“ größer als „erkundete Gebiete“
- [ ] Gespräche (6.23.0.0, Komfort → Gespräche an): Wache ansprechen → Fenster neben der Mitte, Taste 1 wählt; Quest annehmen mit Leertaste; Abgabe mit Auswahl: erst 1/2, dann Leertaste; Esc schließt; nur EIN Fenster, oben links (6.23.1.1); Oberfläche blendet aus und danach wieder ein, Text läuft erst nach der Kamera, Bild des NPCs im Ring (6.23.2.0); Kamera schwenkt auf den NPC, auch seitlich stehend, danach zurück; Text in Serife, startet während der Fahrt (6.23.4.0); Kamera fährt sofort und langsam heran, NPC rechts neben dem Fenster, keine Warnung zu Testfunktionen, nach dem Gespräch zurück (6.23.1.0); ausschalten → Fenster des Spiels wieder da; `/wcui prüfen` → „Gespräche“: gescheitert 0
- [ ] Kräuter/Erz im Wechsel (6.22.0.0, Komfort → Sammeln an): mit Kräuterkunde und Bergbau wechselt das Häkchen im Suchmenü alle 2 s; im Kampf nicht; `/wcui prüfen` → „Sammeln“: gewechselt > 0, gesperrt 0
- [ ] Feuer (6.21.1.0, Komfort → Feuer an): in eine Fläche stellen (Feuer, Gift) – Ton, nicht öfter als einmal je Sekunde; „Ton abspielen“ spielt; `/wcui prüfen` → „Feuer“: offen oder geheim?
- [ ] Eigene Farbe (6.21.1.0): „Eigene Farbe“ wählen, Farbe setzen, neu laden – Oberfläche in der Farbe
- [ ] Geistheiler und Pfeile gut sichtbar (6.21.0.1): auf grüner und brauner Karte auf einen Blick zu finden, Rand dreht mit dem Pfeil
- [ ] Erläuterungen (6.21.0.0): Einstellungen durchblättern – kein Satz unter einem Schalter endet mit „…“, nichts überlappt die nächste Zeile
- [ ] Kontakte (6.21.0.0): „Freundesliste 0/2“ – Raute und Linie hinter dem Text, nicht hindurch; `/wcui fenster` → Zeile „Abschnitte:“ ablegen
- [ ] Herkunft (6.21.0.0): Tooltip eines Instanzeingangs, Berufe, Klassenquests, Lehrer, seltene Gegner, Auktionshaus – nirgends ein fremdes Addon als Quelle
- [ ] Preise von anderen Spielern (Komfort → Auktionshaus → „Mit der Gilde teilen“ und „Preise aus ForeverGuide übernehmen“): nach dem Einloggen keine fremde Zeile im Chat außer evtl. „Kanal beigetreten“ (festhalten, ob sie kommt); nach einiger Zeit `/wcui auktion` → „Aus ForeverGuide übernehmen: … Kanal verbunden · empfangen N Preise“ und „Zuletzt von Spielern“ ablegen; ein Tooltip mit „von Spielern“; mit einem zweiten Gildenmitglied mit WeintCodex: einer scannt, der andere bekommt die Preise (Bericht beider ablegen)
- [ ] Seltene Gegner (Komfort → Seltene Gegner an): einen seltenen Gegner anvisieren oder seine Plakette sehen – Ton, Zeile im Chat, Hinweis oben mit Stufe und „Wiederkehr in Classic“; derselbe nicht gleich wieder; `/wcui selten` listet das Gebiet mit „zuletzt gesehen“; `/wcui prüfen` → Zeile „Seltene Gegner“ ablegen (GUID offen?, Vignetten?)
- [ ] Markieren per Mouseover (Komfort → Automark an): im Dungeon Maus über Gegner, mittlere Maustaste – Totenkopf, nächster Kreuz; derselbe nicht noch einmal; draußen ist die Taste wieder frei
- [ ] Würfeln um Beute (Gruppe, Beute ab „Selten“): Kachel, Rand in der Qualität, Zeit läuft sichtbar ab; `/wcui fenster` mit der Maus über dem Wurf, solange er läuft
- [ ] Spielmenü (Esc), Optionen des Spiels, Makros (/m)
- [ ] Gilde & Communitys, Suche nach Gruppe, Sammlung
- [ ] Neu in dieser Fassung umgestaltet: zusätzlich Gegenstände
      hineinlegen und wieder herausnehmen. Ein Symbol muss erscheinen
      und wieder verschwinden.

## Kampf (2 Minuten)

- [ ] Ein paar Gegner angreifen, ideal in einer Gruppe.
  - [ ] Plaketten: Leben, Zauberbalken, Bedrohungsleiste und „Aggro: …“
  - [ ] Schadensanzeige: füllt sich, Kopfzeile lesbar, Name und Zahl
        überlappen nicht
  - [ ] Gruppenrahmen: Leben, Rollen
- [ ] Im Kampf: Gestaltungsmodus öffnen. Er muss das verweigern.
      Einstellungen öffnen: keine „Aktion blockiert“-Meldung.
- [ ] Nach dem Kampf: In den Chat melden (Sprechblase). Die Meldung kommt
      an.

## Ergebnis

- Alles grün: Release.
- Etwas fällt auf: Erst beheben, dann Release. Eine Fassung mit
  bekanntem Fehler kostet eine weitere Fassung und das Vertrauen der
  Tester.
- Etwas lässt sich nicht prüfen (kein Gruppenpartner, kein Briefkasten
  in der Nähe): **In den Notizen des Releases nennen.** „Ungeprüft“ ist
  eine Auskunft, Schweigen ist keine.
