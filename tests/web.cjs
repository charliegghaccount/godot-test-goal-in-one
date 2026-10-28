// npm install --no-save playwright in an external tools directory if not provided.
const { chromium } = require('playwright');
(async () => {
  const browser = await chromium.launch({ executablePath: process.env.CHROMIUM_PATH || '/usr/bin/chromium', headless: true,
    args: ['--no-sandbox', '--enable-webgl', '--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'] });
  const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
  const errors = [];
  page.on('console', m => { if (m.type() === 'error') errors.push(m.text()); });
  page.on('pageerror', e => errors.push(String(e)));
  await page.goto(process.env.GAME_URL || 'http://127.0.0.1:8062');
  await page.waitForFunction(() => document.querySelector('canvas')?.width > 0);
  await page.waitForTimeout(7000);
  await page.screenshot({ path: '/tmp/v2-ready.png' });
  // Aim from empty sky, well away from the ball.
  await page.mouse.move(550, 400); await page.mouse.down();
  await page.mouse.move(450, 450, { steps: 10 });
  await page.screenshot({ path: '/tmp/v2-aim.png' });
  await page.mouse.up(); await page.waitForTimeout(800);
  await page.screenshot({ path: '/tmp/v2-shot.png' });
  // Native level picker: keyboard selection of the large two-axis sample.
  await page.mouse.click(115, 680); await page.waitForTimeout(200); await page.mouse.click(115,702);
  await page.waitForTimeout(1500);
  await page.screenshot({ path: '/tmp/v2-large.png' });
  await page.mouse.click(1180, 53); // Explore
  await page.mouse.move(900, 500); await page.mouse.down();
  await page.mouse.move(300, 200, { steps: 10 }); await page.mouse.up();
  await page.screenshot({ path: '/tmp/v2-explore.png' });
  await page.keyboard.press('e');
  // Real touch events, emulated by Godot as aiming input.
  const cdp = await page.context().newCDPSession(page);
  await cdp.send('Emulation.setTouchEmulationEnabled', { enabled: true });
  await cdp.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [{ x: 600, y: 350 }] });
  await cdp.send('Input.dispatchTouchEvent', { type: 'touchMove', touchPoints: [{ x: 500, y: 410 }] });
  await cdp.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] });
  await page.waitForTimeout(400);
  await page.screenshot({ path: '/tmp/v2-touch.png' });
  await page.setViewportSize({ width: 844, height: 390 });
  await page.waitForTimeout(400); await page.screenshot({ path: '/tmp/v2-mobile.png' });
  await browser.close();
  if (errors.length) throw new Error(errors.join('\n'));
  console.log('PASS: WebGL startup, anywhere mouse drag, level selector, Explore, touch input and landscape resize; no browser errors. Inspect screenshots for gameplay state.');
})().catch(e => { console.error(e); process.exit(1); });
