# Web Validation Notes

This file records the current validation status for the Godot implementation and its web build path.

## Environment
- Godot CLI: `4.6.1.stable.official.14d19694e`
- Target project: `godot/`
- Renderer target: `gl_compatibility`

## Automated Checks Performed
1. Project parse check
   - Command:
     - `godot --headless --path "/Users/choimarc/hitezero/godot" --quit`
   - Result:
     - Passed after fixing autoload naming and explicit script preloads.

2. Main boot flow smoke test
   - Command:
     - `godot --headless --path "/Users/choimarc/hitezero/godot" --quit-after 10`
   - Result:
     - Passed.
     - Confirms `boot.tscn -> title.tscn` loads without runtime errors.

3. Game scene smoke test
   - Command:
     - `godot --headless --path "/Users/choimarc/hitezero/godot" --scene res://scenes/game.tscn --quit-after 10`
   - Result:
     - Passed after fixing runtime setup in `Block` and typed script preload issues in `GameRoot`.

4. Browser runtime pack export
   - Command:
     - `godot --headless --path "/Users/choimarc/hitezero/godot" --export-pack Web "/Users/choimarc/hitezero/build/godot-web/game.zip"`
   - Result:
     - Passed.
     - Produces a valid exported game pack, even though `--export-release` still reports preset configuration errors.

5. Reproducible manual web build script
   - Command:
     - `bash "/Users/choimarc/hitezero/godot/tools/build_web.sh"`
   - Result:
     - Passed.
     - Builds `build/godot-web/game.zip`.
     - Assembles a runnable no-threads browser shell at `build/godot-web/site_nothreads/`.
     - Produces `build/godot-web/hitezero-godot-web-site_nothreads.zip` for convenient packaging.

6. Browser runtime smoke test via manual no-threads shell
   - Runtime shell:
     - `build/godot-web/site_nothreads/index.html`
   - Host command:
     - `python3 -m http.server 8123 --directory "/Users/choimarc/hitezero/build/godot-web/site_nothreads"`
   - Automated client:
     - `node "/Users/choimarc/.codex/skills/develop-web-game/scripts/web_game_playwright_client.js" --url http://127.0.0.1:8123/index.html --actions-file "/Users/choimarc/hitezero/godot/tools/test_actions_start_and_shoot.json" --iterations 1 --pause-ms 500 --screenshot-dir "/Users/choimarc/hitezero/build/godot-web/test-artifacts/run1"`
   - Result:
     - Passed.
     - Confirmed title-to-game transition in browser.
     - Confirmed gameplay click input reaches the game after fixing HUD mouse filtering.
     - Confirmed `window.render_game_to_text()` returns live game state.
     - Confirmed no browser console errors were emitted during the automated run.

## What Has Been Validated
- The project opens in Godot.
- The main scene boot chain executes.
- The game scene instantiates world, HUD, player, and generated blocks without runtime errors.
- The current port runs in a browser through the assembled no-threads shell.
- The game can transition from title to gameplay and reach a game-over state in browser automation.
- The current port is suitable for editor-based playtesting and browser-level iteration.

## What Still Requires Manual Browser QA
- Root-cause and fix the failing `--export-release Web ...` path so the browser build does not rely on manual shell assembly
- Desktop browser checks:
  - Chrome
  - Firefox
  - Safari
- Mobile browser checks:
  - iPhone Safari
  - Android Chrome
- Input feel:
  - drag aiming
  - paddle drag during shooting
- Performance:
  - stable frame pacing on stage transitions
  - acceptable frame rate with multiple knives and falling enemies
- Visual quality:
  - UI scaling at non-400x700 aspect ratios
  - no clipping in top bar / overlay layouts

## Current Decision
- The repository now treats the Godot project as the primary game implementation.
- The current port has passed local automated smoke checks, reproducible pack-based web assembly, and one browser automation pass, but it still needs proper release export packaging and manual performance comparison on target devices.
- Before final release, verify:
  1. Godot web release export is reproducible without the manual shell workaround.
  2. Touch controls are verified on at least one desktop browser and one mobile browser.
  3. Gameplay feel is accepted against `docs/gameplay_spec.md`.
