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

## Notes
- Current Godot visuals use lightweight placeholder drawing instead of depending on imported art assets.
- The local verification server is expected at `http://127.0.0.1:8123/index.html` when serving `build/godot-web/site_nothreads/`.

## Remaining TODOs
- Root-cause the Godot 4.6 `--export-release Web ...` preset configuration error. Current evidence suggests the pack-based path is stable while full release export is not.
- Run manual browser QA for drag aiming, paddle dragging during shooting, and mobile touch feel.
- Compare runtime feel against `godot/docs/gameplay_spec.md`.
