// Einzelbilder: node preview.js "$PWD" 10 40 90  ->  prev_<t>.jpg
const { chromium } = require('playwright-core');
(async () => {
  const [dir, ...ts] = process.argv.slice(2);
  const b = await chromium.launch({ executablePath: process.env.CHROME || '/usr/bin/chromium', args: ['--allow-file-access-from-files'] });
  const p = await b.newPage({ viewport: { width: 1920, height: 1080 } });
  const errs = []; p.on('pageerror', e => errs.push(String(e)));
  await p.goto('file://' + dir + '/index.html');
  await p.evaluate(() => window.READY);
  for (const t of ts) { await p.evaluate(x => window.setTime(x), +t); await p.screenshot({ path: `${dir}/prev/prev_${String(t).padStart(4, '0')}.jpg`, type: 'jpeg', quality: 80 }); }
  if (errs.length) console.log(errs.join('\n'));
  await b.close();
})();
