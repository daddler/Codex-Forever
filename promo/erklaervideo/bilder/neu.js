// ---------- Neue Szenen fuer das Erklaervideo (Codex-Video) ----------
// Gleiche Bausteine wie oben. Akzent hier Violett (#7C6CFF), Gold (#F0A63A) fuer Werte.
document.documentElement.style.setProperty("--acc", "#7C6CFF");
const BSP = (x, y) => `<div class="eyebrow" style="position:absolute;left:${x}px;top:${y}px;font-size:11px;color:var(--tf)">Beispiel</div>`;
const win = (x, y, w, h, crumb, title, inner) => tile(x, y, w, h,
  brow(24, 18, crumb, "var(--td)") +
  `<div style="position:absolute;left:24px;top:40px;font-family:Serif;font-size:30px;color:var(--tb)">${title}</div>` +
  `<div style="position:absolute;left:0;right:0;top:86px;height:1px;background:var(--line)"></div>` + inner);
const btn = (x, y, t, kind) => `<div style="position:absolute;left:${x}px;top:${y}px;padding:8px 18px;font-family:SansB;font-size:16px;${
  kind === "p" ? "background:var(--acc);color:#fff" : kind === "d" ? "background:#2a1414;color:#ff8a80;border:1px solid #5a2a26" : "background:#1c1c23;color:var(--tn);border:1px solid var(--line)"}">${t}</div>`;
const tog = (x, y, label, on, sub) => `<div style="position:absolute;left:${x}px;top:${y}px;width:38px;height:20px;border-radius:10px;background:${on ? "var(--acc)" : "#2a2a33"}">
  <div style="position:absolute;top:2px;${on ? "right:2px" : "left:2px"};width:16px;height:16px;border-radius:8px;background:#fff"></div></div>` +
  txt(x + 52, y - 1, 18, label) + (sub ? txt(x + 52, y + 24, 14, sub, "color:var(--td)") : "");
const row = (y, cells, col) => cells.map((c, i) => `<div class="name ${i ? "mono" : ""}" style="${i ? "right:" + (24 + (cells.length - 1 - i) * 120) + "px;text-align:right" : "left:24px"};top:${y}px;font-size:17px;${i && col ? "color:" + col[i] : ""}">${c}</div>`).join("");

// 1 Gewinn
S("gewinn", win(150, 26, 724, 460, "Berufe · Werkzeug", "Gewinn · Schneiderei",
  row(104, ["Rezept", "Erlös", "Kosten", "Gewinn"], [0, "var(--td)", "var(--td)", "var(--td)"]) +
  row(142, ["Leinenbeutel", "48s", "21s", "+27s"], [0, "var(--gold)", "var(--gold)", "var(--green)"]) +
  row(180, ["Grünes Leinenhemd", "1g 10s", "1g 22s", "−12s"], [0, "var(--gold)", "var(--gold)", "var(--red)"]) +
  row(218, ["Wollbeutel", "—", "—", "—"], [0, "var(--tf)", "var(--tf)", "var(--tf)"]) +
  txt(24, 244, 14, "Erzeugnis nie im Auktionshaus gesehen", "color:var(--warn)") +
  `<div style="position:absolute;left:24px;right:24px;top:290px;padding:14px 16px;background:#101014;border-left:3px solid var(--gold);font-size:16px;line-height:24px;color:var(--tm);white-space:normal">
   Erlös = Auktionspreis × Stückzahl − 5 % Gebühr<br>Kosten = Reagenzien zum günstigsten bekannten Preis<br>Fehlt eine Zahl, steht kein Gewinn da.</div>` +
  BSP(640, 24)), "dark");

// 2 Auktionspreise
S("ahScan",
  tile(60, 60, 400, 230, brow(24, 20, "Auktionshaus", "var(--gold)") +
    btn(24, 60, "Preise scannen", "p") + txt(24, 120, 16, "Liest … 64 %", "color:var(--tm)") +
    `<div style="position:absolute;left:24px;right:24px;top:150px;height:10px;background:#101014"><div class="bar" style="width:64%;background:var(--acc)"></div></div>`) +
  tile(520, 60, 440, 230, txt(20, 18, 24, "Leinenstoff", "color:#fff") +
    txt(20, 58, 18, "Auktionshaus", "color:var(--acc)") + `<div class="name mono" style="right:20px;top:58px;font-size:18px;color:var(--gold)">ab 1s 80c</div>` +
    txt(20, 96, 18, "Stapel (20)") + `<div class="name mono" style="right:20px;top:96px;font-size:18px;color:var(--gold)">36s</div>` + BSP(20, 190), "border-color:var(--acc)") +
  tile(60, 330, 900, 130, tog(28, 30, "Mit der Gilde teilen", true, "Preise gehen nur an deine Gilde, als Nachricht des Addons.") +
    tog(500, 30, "Auktionspreise", true, "Preis im Tooltip")), "dark");

// 3 Angeln mit einer Taste
S("angeln",
  `<div style="position:absolute;left:0;right:0;bottom:0;height:46%;background:linear-gradient(180deg,#1b3348,#0d1a26)"></div>` +
  `<div style="position:absolute;left:250px;top:330px;width:26px;height:26px;border-radius:13px;background:radial-gradient(circle at 40% 35%,#ff6a5a,#9a1a12);box-shadow:0 0 0 6px rgba(255,255,255,.08),0 0 0 16px rgba(255,255,255,.04)"></div>` +
  ic(244, 284, 38, "#9fe3ff", "#2a6aa0") +
  win(440, 40, 540, 430, "Komfort · Sammeln", "Angeln mit einer Taste",
    tog(24, 110, "Angeln mit einer Taste", true) +
    txt(24, 150, 15, "Taste", "color:var(--td)") +
    `<div style="position:absolute;left:24px;top:174px;width:200px;height:40px;background:#0c0c0f;border:1px solid var(--acc)">${txt(14, 9, 18, "F", "font-family:Mono")}</div>` + BSP(240, 186) +
    tog(24, 240, "Platschen lauter", true) + tog(24, 284, "Ton im Hintergrund", false) + tog(24, 328, "Symbol über dem Schwimmer", true) +
    txt(24, 380, 14, "Auswerfen · Einholen · Beute nehmen – jeder Druck ist deiner.", "color:var(--tm)")), "world");

// 4 Angel-Logbuch
S("angellog", win(150, 26, 724, 460, "Berufe · Werkzeug", "Angeln",
  txt(24, 104, 20, "Wald von Elwynn", "color:var(--tb)") + txt(24, 132, 16, "42 Würfe · 31 Fänge (74 %)", "font-family:Mono;color:var(--gold)") +
  row(166, ["Glänzender Kleinfisch", "19", "61 %"]) + row(196, ["Langmäuliger Schlammschnapper", "9", "29 %"]) + row(226, ["Leerer Sack", "3", "10 %"]) +
  txt(24, 280, 20, "Westfall", "color:var(--tb)") + txt(24, 308, 16, "6 Würfe", "font-family:Mono;color:var(--gold)") +
  txt(24, 336, 14, "Noch kein Fang – eine Quote steht erst ab einem Fang da.", "color:var(--td)") +
  btn(24, 382, "Logbuch leeren") + BSP(640, 24)), "dark");

// 5 Flugzeit
S("flugzeit",
  tile(262, 150, 500, 150,
    txt(20, 16, 20, "Orgrimmar › Ratchet") + `<div class="name mono" style="right:20px;top:16px;font-size:20px;color:var(--gold)">2:10</div>` +
    `<div style="position:absolute;left:20px;right:20px;top:56px;height:12px;background:#101014"><div class="bar" style="width:40%;background:var(--acc)"></div>
      <div style="position:absolute;left:55%;top:-4px;width:3px;height:20px;background:var(--gold)"></div></div>` +
    txt(20, 84, 16, "Nächster Halt: Crossroads · 1:19", "color:var(--tm)") +
    btn(272, 98, "Spiele") + btn(370, 98, "Landen", "p")) +
  brow(262, 120, "Flugzeit", "var(--td)") + BSP(262, 316), "world");

// 6 Schlafsack
S("schlafsack", tile(40, 26, 944, 460,
  `<div style="position:absolute;left:0;top:0;bottom:0;width:230px;background:#101014;border-right:1px solid var(--line)">` +
  brow(18, 18, "Entdecken", "var(--td)") +
  [["g", "Bücher der Bibliothek"], ["", "Alle Bücher"], ["", "Abgeben"], ["", "Empfohlen"], ["", "Möglich"], ["", "Abgeraten"], ["", "Abgegeben"], ["g", "Questreihen"], ["on", "Gemütlicher Schlafsack"]].map((n, i) =>
    n[0] === "g" ? `<div class="eyebrow" style="position:absolute;left:18px;top:${50 + i * 38 + 8}px;font-size:10px;color:var(--tf)">${n[1]}</div>`
    : `<div style="position:absolute;left:0;right:0;top:${50 + i * 38}px;height:34px;${n[0] === "on" ? "background:#1c1c23;border-left:3px solid var(--acc)" : ""}">${txt(18, 7, 15, n[1], n[0] === "on" ? "" : "color:var(--tm)")}</div>`).join("") + `</div>` +
  `<div style="position:absolute;left:260px;top:20px;font-family:Serif;font-size:30px;color:var(--tb)">Gemütlicher Schlafsack</div>` +
  [["Pocket Litter", "Verlassenes Lager", 1], ["Mound of Dirt", "Felsvorsprung nördlich des Lagers", 1], ["Carved Figurine", "Stonewrought Dam", 0], ["Messenger Bag", "In Thoradins Wall", 0], ["Hastily Rolled-Up Satchel", "Unter der Messenger Bag", 0]].map((r, i) =>
    `<div style="position:absolute;left:260px;right:24px;top:${84 + i * 62}px;height:54px;background:${i === 2 ? "#1c1c23" : "#141419"};border:1px solid ${i === 2 ? "var(--acc)" : "var(--line)"}">
      <div style="position:absolute;left:14px;top:16px;width:20px;height:20px;border:2px solid ${r[2] ? "var(--green)" : "var(--strong)"};background:${r[2] ? "var(--green)" : "transparent"}"></div>
      ${txt(50, 6, 17, (i + 1) + ". " + r[0])}${txt(50, 29, 14, r[1], "color:var(--td)")}
      ${i === 2 ? btn(510, 8, "Questpfeil", "p") : ""}</div>`).join("") +
  txt(260, 410, 14, "Was erledigt ist, sagt das Spiel selbst.", "color:var(--td)")), "dark");

// 7 Sammel-Atlas
S("atlas", tile(170, 26, 684, 460,
  `<div style="position:absolute;inset:0;background:radial-gradient(ellipse at 40% 45%,#3a4a32,#26301f 60%,#1b2216)"></div>` +
  [[120,120,"#7fd36a"],[200,90,"#7fd36a"],[300,150,"#c9a45c"],[380,110,"#7fd36a"],[470,190,"#c9a45c"],[420,290,"#7fd36a"],[300,330,"#c9a45c"],[180,280,"#7fd36a"],[560,320,"#7fd36a"]].map(p =>
    `<div style="position:absolute;left:${p[0]}px;top:${p[1]}px;width:14px;height:14px;border-radius:7px;background:${p[2]};border:2px solid #000"></div>`).join("") +
  `<svg style="position:absolute;inset:0" width="684" height="460"><polyline points="127,127 207,97 307,157 387,117 477,197 567,327 427,297 307,337 187,287 127,127" fill="none" stroke="#F0A63A" stroke-width="2" stroke-dasharray="6 5"/></svg>` +
  tile(18, 18, 260, 92, brow(14, 12, "Sammel-Atlas", "var(--gold)") + txt(14, 36, 15, "● Kräuter   ● Erz", "color:var(--tm)") + txt(14, 62, 13, "Nur Stellen, an denen du gesammelt hast", "color:var(--td)"))), "dark");

// 8 Suche in den Einstellungen
S("suche", win(150, 26, 724, 460, "WeintCodex · Einstellungen", "Suche",
  `<div style="position:absolute;left:24px;right:24px;top:104px;height:44px;background:#0c0c0f;border:1px solid var(--acc)">${txt(14, 10, 19, "Angeln")}</div>` +
  [["Angeln mit einer Taste", "Welt & Karte · Sammeln"], ["Platschen lauter", "Welt & Karte · Sammeln"], ["Ganze Karte, Stufen und Sammelberufe", "Welt & Karte · Karte"]].map((r, i) =>
    `<div style="position:absolute;left:24px;right:24px;top:${168 + i * 64}px;height:56px;background:${i ? "#141419" : "#1c1c23"};border:1px solid var(--line)">${txt(16, 7, 18, r[0])}${txt(16, 31, 14, r[1], "color:var(--td)")}</div>`).join("") +
  txt(24, 380, 14, "Schrägstrich-Befehl: /wcui", "color:var(--tm);font-family:Mono")), "dark");

// 9 Auftrag aus der Gilde
S("auftrag", tile(212, 60, 600, 380,
  brow(24, 20, "Aus dem Discord", "var(--gold)") +
  `<div style="position:absolute;left:24px;top:44px;font-family:Serif;font-size:30px;color:var(--tb)">Aufträge aus der Gilde</div>` +
  `<div style="position:absolute;left:24px;right:24px;top:110px;height:150px;background:#141419;border:1px solid var(--line)">
    ${txt(18, 16, 22, "4× Runenstoffbeutel")}${txt(18, 52, 16, "Bestellt von einem Gildenmitglied", "color:var(--td)")}${BSP(470, 20)}
    ${btn(18, 100, "Annehmen", "p")}${btn(150, 100, "Erledigt")}${btn(270, 100, "Ablehnen", "d")}</div>` +
  txt(24, 290, 15, "Deine Antwort geht beim Ausloggen oder /reload über die Companion zurück.", "color:var(--tm)") +
  txt(24, 318, 15, "Bis dahin steht dort: wird gemeldet", "color:var(--td)"), "border-color:#3a3226"), "dark");

// 10 Herkunft
S("herkunft",
  [["Unbestätigt", "aus Berichten von Spielern", "var(--warn)"], ["Aus Classic", "aus WoW Classic Era", "var(--blue)"], ["Vorläufig", "aus dem Beta-Client gelesen", "var(--violet)"]].map((r, i) =>
    tile(112 + i * 280, 170, 240, 150, `<div style="position:absolute;left:0;top:0;bottom:0;width:4px;background:${r[2]}"></div>` +
      brow(22, 26, r[0], r[2]) + `<div style="position:absolute;left:22px;right:16px;top:62px;font-size:18px;line-height:26px;color:var(--tm);white-space:normal">${r[1]}</div>`)).join("") +
  `<div style="position:absolute;left:112px;top:96px;font-family:Serif;font-size:34px;color:var(--tb)">Woher kommt eine Angabe?</div>`, "dark");
