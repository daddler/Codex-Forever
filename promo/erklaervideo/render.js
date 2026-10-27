// Rendert index.html Bild fuer Bild nach video_noaudio.mp4 (30 fps).
//   node render.js "$PWD" [von_s] [bis_s]
// Chromium: Umgebungsvariable CHROME, sonst /usr/bin/chromium.
const { chromium } = require('playwright-core');
const { spawn } = require('child_process');
(async () => {
  const dir = process.argv[2], fps = 30;
  const b = await chromium.launch({ executablePath: process.env.CHROME || '/usr/bin/chromium', args: ['--allow-file-access-from-files'] });
  const p = await b.newPage({ viewport: { width: 1920, height: 1080 } });
  await p.goto('file://' + dir + '/index.html');
  await p.evaluate(() => window.READY);
  const dur = await p.evaluate(() => window.DURATION);
  const from = +(process.argv[3] || 0), to = +(process.argv[4] || dur);
  const out = process.argv[3] ? dir + '/teil.mp4' : dir + '/video_noaudio.mp4';
  const n0 = Math.round(from * fps), n1 = Math.round(to * fps);
  const ff = spawn('ffmpeg', ['-y', '-v', 'error', '-f', 'image2pipe', '-framerate', String(fps), '-c:v', 'mjpeg', '-i', '-',
    '-c:v', 'libx264', '-preset', 'medium', '-crf', '18', '-pix_fmt', 'yuv420p', out], { stdio: ['pipe', 'inherit', 'inherit'] });
  for (let i = n0; i < n1; i++) {
    await p.evaluate(t => window.setTime(t), i / fps);
    const buf = await p.screenshot({ type: 'jpeg', quality: 92 });
    if (!ff.stdin.write(buf)) await new Promise(r => ff.stdin.once('drain', r));
    if (i % 900 === 0) console.log('Bild', i, '/', n1);
  }
  ff.stdin.end();
  await new Promise(r => ff.on('close', r));
  await b.close();
  console.log('fertig', out);
})();
