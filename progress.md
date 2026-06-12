Original prompt: Implement the plan as specified, it is attached for your reference. Do NOT edit the plan file itself.

## Completed
- Created the `godot/` project as the main game implementation.
- Added boot, title, game, HUD, player, knife, block, level generator, and session scripts/scenes.
- Ported the core gameplay loop with manual knife collision and stage progression.
- Added migration docs under `godot/docs/`.
- Verified headless Godot project parsing and scene smoke tests.

## Current work
- No active implementation work remains in this session.

## Latest updates
- Added `godot/export_presets.cfg` with a Web preset targeting a zipped Web artifact.
- Normalized the Web preset to match Godot's official demo-project format more closely after release export validation failed.
- `--export-pack` succeeds and produces `godot/build/web/game.zip`.
- Added a manual no-threads web shell at `godot/build/web/site_nothreads/index.html` that boots `godot.js` + `game.zip`.
- Browser automation found a real bug: the HUD root `Control` was intercepting gameplay pointer input. Fixed by switching non-interactive HUD controls to `MOUSE_FILTER_IGNORE`.
- Added a lightweight web bridge in `godot/scripts/game_root.gd` that exposes:
  - `window.render_game_to_text()`
  - `window.advanceTime(ms)`
- The bridge publishes concise JSON state into `window.__hitezero_state_json` during gameplay.
- Confirmed Godot CLI expects a zipped Web release artifact for `--export-release`, so the Web preset export path is being switched to `.zip`.
- Browser automation now reaches the game scene and records `GAME_OVER` state after one automated shot, with no captured console errors.
- Added `godot/tools/build_web.sh` so the pack-based no-threads web build is reproducible in one command.
- Moved the recommended output path to repo-root `build/godot-web/` so build artifacts stay outside the Godot project root.
- The build script now also produces `hitezero-godot-web-site_nothreads.zip` alongside the unpacked site folder.
- Fixed `godot/tools/build_web.sh` so a relative output path is normalized to an absolute repo-root path before calling Godot export.
- Rebuilt the latest web artifact into `dist/godot-web/`.
- Added `dist/hitezero-itch-html.zip` as the upload-ready itch.io HTML build.

## Notes
- Current Godot visuals use lightweight placeholder drawing instead of depending on imported art assets.
- The local verification server is expected at `http://127.0.0.1:8123/index.html` when serving `build/godot-web/site_nothreads/`.
- The latest distributable build now also lives under `dist/`, not just `build/`.

## Duckflock reference DNA (2026-06-12)
- Analyzed the duck-flock reference video frame-by-frame; analysis + goal plan in
  `godot/docs/duckflock_reference_goal_plan.md`, curated frames in `reference_frames/duckflock_*.jpg`.
- Implemented the goal plan across `game_constants.gd` (timing/palette tokens), `hud.gd`,
  `game_root.gd`, `block.gd` (take_damage), `player.gd` (0.13s hot flash):
  - Kill chain: every destroy spawns 4-6 gold coin shards → scatter → magnet to paddle →
    rising-pitch tick + score punch.
  - Toast system: top-right white rounded cards (slide-in 0.22s, hold 2.2s, stack of 3) for
    combo tiers, group kills, item pickups, boss downs, level-up picks.
  - Objective pill: top-centre `★ n/m` gold pill with flip animation on collect.
  - x2 speed + SND mute pill buttons (bottom centre); game_speed scales sim delta only, so
    hit-stop/shake/flash stay real-time at x2.
  - In-run level-up: 3-card pick after every stage clear / boss defeat (run-scoped DAMAGE+1 /
    KNIFE+1 / SPEED+10% / TRAY+12 + timed 2xDMG 18s / PIERCE 12s); pick resumes play same frame.
  - Group kill: ≥5 destroys inside a 0.5s chain window grant a permanent run ATK stack
    (settled on stage clear too) with toast + HUD chip.
  - Ambience: radial vignette layer + rising cyan/pink firefly motes.
- New headless integration test: `godot/tools/test_duckflock_systems.gd` (26 checks) — run via
  `godot --headless --path godot -s tools/test_duckflock_systems.gd`.
- Verified: headless game scene 240 frames clean; all python tools tests pass
  (`test_player_output_vfx.py` updated to the new 0.13s flash spec); web build + browser QA
  full loop (start → x2 → volley → coin chain → level-up pick resumes in ~1-2 frames →
  stages 2/3, PIERCE buff timer HUD) with zero console errors.

## Remaining TODOs
- Run manual browser QA for drag aiming, paddle dragging during shooting, and mobile touch feel.
- Compare runtime feel against `godot/docs/gameplay_spec.md`.
- Duckflock plan phase 4 (optional style deepening): wet-ground fake reflection, rounded block
  corners, cyan bubble-pop VFX for elite/boss kills.
