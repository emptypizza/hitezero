const { chromium } = require('/Users/choimarc/.codex/skills/develop-web-game/node_modules/playwright');

async function clickCanvas(page, x, y) {
  const box = await page.locator('canvas').boundingBox();
  if (!box) throw new Error('Canvas not found');
  await page.mouse.move(box.x + x, box.y + y);
  await page.mouse.down();
  await page.waitForTimeout(50);
  await page.mouse.up();
}

(async () => {
  const browser = await chromium.launch({ headless: true, args: ['--use-gl=angle', '--use-angle=swiftshader'] });
  const page = await browser.newPage();
  try {
    await page.goto('http://127.0.0.1:8123/index.html', { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(1500);

    // Start Game button on 400x700 canvas.
    await clickCanvas(page, 200, 447);
    await page.waitForTimeout(1200);

    const stateInGame = await page.evaluate(() => window.__hitezero_state_json || null);
    if (!stateInGame) {
      throw new Error('Expected game state to exist after entering gameplay, but it was empty');
    }

    // TITLE button in gameplay HUD.
    await clickCanvas(page, 352, 17);
    await page.waitForTimeout(800);
    await page.screenshot({ path: '/Users/choimarc/hitezero/build/test-title-return-debug.png' });

    const result = await page.evaluate(() => ({
      raw: window.__hitezero_state_json || null,
      rendered: typeof window.render_game_to_text === 'function' ? window.render_game_to_text() : null
    }));

    if (result.raw && result.raw !== '{}' && result.raw !== 'null') {
      throw new Error(`Expected web bridge state to clear on title return, but got stale state: ${result.raw}`);
    }

    console.log('PASS');
  } finally {
    await browser.close();
  }
})().catch((err) => {
  console.error(err.stack || String(err));
  process.exit(1);
});
