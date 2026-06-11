# HiteZero 1~6 Web-Researched Quality Implementation Plan

> **For Hermes:** Implement this with TDD and public-web verification. Do not commit or push unless the user explicitly asks.

**Goal:** Apply all six requested HiteZero polish directions as a source-grounded, low-risk visual/game-feel quality pass while preserving the existing public test URL.

**Architecture:** Keep gameplay rules mostly intact. Add small deterministic feedback systems, sprite/readability guardrails, and runtime QA observability. Prefer tiny Godot/GDScript changes plus regression tests over broad refactors.

**Tech Stack:** Godot 4.6, GDScript, Python/Node regression scripts, Godot no-threads Web export, Cloudflare quick tunnel.

---

## Research sources used

- Pixel art: https://en.wikipedia.org/wiki/Pixel_art
- Animation principles: https://en.wikipedia.org/wiki/Twelve_basic_principles_of_animation
- Game feel: https://en.wikipedia.org/wiki/Game_feel
- Juice / game feel talk: https://www.gdcvault.com/play/1016487/Juice-It-or-Lose
- UI response timing: https://www.nngroup.com/articles/response-times-3-important-limits/
- Visual hierarchy: https://en.wikipedia.org/wiki/Visual_hierarchy
- Apple safe-area/layout guidance: https://developer.apple.com/design/human-interface-guidelines/layout
- CSS safe-area env vars: https://developer.mozilla.org/en-US/docs/Web/CSS/env
- WCAG contrast: https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html
- WCAG non-text contrast: https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html
- Game accessibility color-only warning: https://gameaccessibilityguidelines.com/ensure-no-essential-information-is-conveyed-by-a-fixed-colour-alone/
- Godot image import / pixel art: https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_images.html
- Godot multiple resolutions: https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html
- Godot Web export: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html
- Godot JavaScriptBridge: https://docs.godotengine.org/en/stable/tutorials/platform/web/javascript_bridge.html

---

## Six implementation axes

### 1. Pixel-art/readability consistency

**Research basis:** Pixel art depends on deliberate pixel placement, lossless assets, constrained palette, and readable silhouettes. Small mobile sprites need clear outline/shape more than high detail.

**HiteZero target:** Keep RED_ENEMY as red-only blob, but ensure player/enemy/knife/block presentation follows a consistent nearest/lossless/readability discipline.

**Implementation tasks:**
1. Maintain the existing dedicated `red_enemy.png` regression test.
2. Add a six-axis quality regression test that rejects placeholder-only polish and requires clear source hooks for safe areas, trails, and immediate feedback.
3. Keep new visual effects red/yellow/cyan readable and avoid white HP/face overlays on RED_ENEMY.

### 2. Small-sprite animation clarity

**Research basis:** Animation principles like anticipation, staging, timing, and exaggeration matter even more on small sprites; a few strong key poses beat noisy detail.

**HiteZero target:** Give RED_ENEMY a subtle blob pulse and keep player output poses strong without making every frame visually noisy.

**Implementation tasks:**
1. Keep/enhance RED_ENEMY active pulse in `block.gd`.
2. Ensure the pulse does not add non-red pixels or face/number clutter.
3. Use tests/visual QA to verify blob remains non-square and readable.

### 3. Immediate throw feedback

**Research basis:** 0.1s is the perceived instant-response threshold; HiteZero’s 0.066s first-knife delay is technically short but can still feel soft in browser/mobile.

**HiteZero target:** On drag release, show a small commit cue immediately, before the first actual knife spawn timer fires.

**Implementation tasks:**
1. Add an immediate release cue in `GameRoot._start_shooting()`.
2. Use existing `Player.play_output(aim_angle)` or a small helper, without changing collision/scoring timing.
3. Keep actual knife spawning on `SPAWN_INTERVAL` to minimize gameplay-rule risk.

### 4. Projectile trail and directional juice

**Research basis:** Fast projectiles need clear motion continuity; trails should show direction without burying projectile/body/blocks.

**HiteZero target:** Add a short, restrained two-tone knife trail that follows the projectile body rather than only the player muzzle.

**Implementation tasks:**
1. Add per-knife trail point history in `knife.gd`.
2. Draw a dark outer stroke plus warm core line with fast fade.
3. Keep small knives lighter/shorter to avoid POW clutter.

### 5. HUD safe band and visual hierarchy

**Research basis:** Safe areas and visual hierarchy prevent important UI/game objects from visually fighting each other. HUD and falling enemies need separate bands.

**HiteZero target:** Move generated rows down enough that top RED_ENEMY blobs do not look glued to HUD.

**Implementation tasks:**
1. Add a named `LEVEL_START_Y` constant derived from `TOP_BAR_HEIGHT`.
2. Use it in `LevelGenerator.init_level()` instead of hard-coded `60.0`.
3. Expose visual safe-band values through the web bridge for QA.

### 6. Web/mobile QA observability

**Research basis:** Godot Web/mobile rendering can differ by browser, DPR, safe area, and cache. Automated public-URL checks need runtime observability.

**HiteZero target:** Preserve the current URL and make QA states inspectable in browser automation.

**Implementation tasks:**
1. Add `visual_safety` payload fields to `window.__hitezero_state_json`.
2. Rebuild `build/godot-web` and `dist/godot-web`.
3. Verify public URL pack hash, console errors, and screenshot/vision after deployment.

---

## TDD plan

### Task 1: Add six-axis quality regression test

**Files:**
- Create: `godot/tools/test_six_axis_quality.py`

**Expected RED:** The test fails because no `LEVEL_START_Y`, no knife trail history, no immediate release cue marker, and no `visual_safety` payload exist yet.

**Run:**
```bash
python3 godot/tools/test_six_axis_quality.py
```

### Task 2: Add safe top band constant and level generation usage

**Files:**
- Modify: `godot/scripts/game_constants.gd`
- Modify: `godot/scripts/level_generator.gd`

**Expected GREEN:** Test detects `LEVEL_START_Y` and level generator no longer starts rows at raw `60.0`.

### Task 3: Add immediate throw commit cue and directional shake helper

**Files:**
- Modify: `godot/scripts/game_root.gd`

**Expected GREEN:** Test detects `_play_release_commit_cue`, `player.play_output(aim_angle)` in `_start_shooting`, and directional shake fields/helpers.

### Task 4: Add short knife trail

**Files:**
- Modify: `godot/scripts/knife.gd`

**Expected GREEN:** Test detects `trail_points`, `_draw_trail`, dark outer stroke, warm core, and reset in `configure()`.

### Task 5: Expose web QA safe-band payload

**Files:**
- Modify: `godot/scripts/game_root.gd`

**Expected GREEN:** Test detects `visual_safety` in web bridge payload.

### Task 6: Rebuild and public URL verification

**Files:**
- Build outputs under `build/godot-web` and `dist/godot-web`.

**Run:**
```bash
python3 godot/tools/test_six_axis_quality.py
python3 godot/tools/test_red_enemy_sprite.py
python3 godot/tools/test_player_output_vfx.py
node godot/tools/test_web_bridge_clears_on_title_return.js
godot --headless --path /Users/choimarc/hitezero/godot --check-only --script res://scripts/game_root.gd
godot --headless --path /Users/choimarc/hitezero/godot --check-only --script res://scripts/knife.gd
bash godot/tools/build_web.sh build/godot-web
bash godot/tools/build_web.sh dist/godot-web
```

**Public verification:**
- Existing public URL remains `https://loc-cdt-coins-sell.trycloudflare.com/`.
- Confirm `mainPack` changed to the new hash.
- Browser console has 0 JS errors.
- Capture gameplay and verify HUD/RED_ENEMY separation plus trail/output readability.
