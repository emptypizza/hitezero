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

## Worklist drop: LD-01 + VX-01/02/03 (2026-06-12)
- Source: `docs/hitezero_worklist_plate.png` (10-item improvement worklist; this drop covers
  the recommended first batch).
- LD-01 `level_generator.gd`: PATTERNS_DENSE grown 4 → 7 (serpent corridor / twin pillars /
  arena), new PATTERNS_BRUTAL pool (5 layouts, lv 20+, E/X-heavy; lv 13–19 stays DENSE/COMPLEX),
  plus a static `_last_pattern` guard so two consecutive stages never share a layout. HP curve
  untouched.
- VX-02 `assets/shaders/rounded_block.gdshader` + `block.gd`: UV-space rounded-rect alpha mask
  (radius 0.16) on NORMAL/STAR/POW sprites via one shared ShaderMaterial; RED_ENEMY keeps
  `material = null` so the blob silhouette stays untouched.
- VX-01 `game_root.gd`: `_draw_wet_reflections()` pass (after background grid, under all nodes)
  — darkened mirror silhouettes below blocks/boss, glints under knives, contact sheen under the
  player. Alpha capped at 0.085–0.105; draw-only, no AABB/sim changes.
- VX-03 `game_root.gd`: `_spawn_bubble_pop()` rides vfx_particles with a new "bubble" shape
  (buoyancy in update, swell-and-pop shell in draw). Hooks: RED_ENEMY destroy → small pop,
  boss-defeat explosion loop → big pops.
- Verified: all 5 `tools/test_*.py` PASS (incl. new `test_levelgen_vx_expansion.py`); gdparse
  syntax-clean on the three touched scripts. New behavioural test for local run:
  `godot --headless --path godot -s tools/test_levelgen_expansion.gd` (pool integrity, tier
  routing, 400-draw anti-repeat, slot resolution).

## UX/perf batch: NEW-01/02 + P1-1/2/3 + FL-02 (2026-06-13)
- Source: `docs/remaining_worklist_2026-06-13.md` (18-item consolidated list; this drop covers
  the recommended batch + the P1 performance trio).
- NEW-01 soft pause: `II` pill (bottom-centre, left of x2) + P/ESC + focus-out auto-pause
  (headless-guarded). Early `_process` return + paused spawn/stage Timers; resume tap is
  swallowed so it can never aim/fire; pausing drops in-flight drags. HUD overlay is
  mouse-IGNORE so the tap falls through. Pause only in AIMING/SHOOTING, never over level-up.
- NEW-02: mute pill persists via `Session.sound_muted` ([settings] in the save file).
- P1-1: ambient web-bridge serialization throttled to 0.1s (event pushes stay immediate);
  bridge payload now also carries `paused`.
- P1-2: `_emit_ui_update` skips identical payloads via a signature snapshot — changes still
  emit same-tick (duckflock same-tick HUD test stays green).
- P1-3: axis-distance broad-phase prefilter in `_check_block_collision` before AABB+sqrt.
- FL-02 active paddle play: tray bounce pays +15 score and keeps an existing combo alive
  (never starts one); a 5-bounce juggle streak banks +1 knife once per stage (streak resets
  per volley). Toast: "JUGGLE! +1 KNIFE".
- P2-4: removed dead `Session.submit_score()`; pruned stale versioned itch zips in `dist/`.
- Verified with a downloaded Godot 4.6 arm64 binary: 6/6 `tools/test_*.py` PASS (new
  `test_ux_perf_batch.py`), duckflock 26 checks PASS, levelgen behavioural PASS, new
  `tools/test_pause_runtime.gd` 14 checks PASS, game scene 240f smoke clean, web rebuild →
  pack `game-110c9b4dc7226cff.zip` boots 180f clean. `dist/` is upload/commit-ready.

## CEL 2.5D visual pass: CEL-01/02 (2026-06-13)
- Goal: subculture (anime) read — 2D stays 2D but cards gain 3D-like depth via a
  cel-slab look. All draw-only: AABBs, HP and sim state untouched.
- CEL-01 `assets/shaders/rounded_block.gdshader`: layered cel shading onto the existing
  VX-02 rounded-rect SDF (contract literals kept) — 3-step quantized top-light bands,
  purple-tinted anime shadow band with screen-space halftone screentone (FRAGCOORD dots),
  inner ink outline, key-lit bevel rim, slow neutral foil glint (TIME sweep, 7s). Single
  shared ShaderMaterial in block.gd unchanged; RED_ENEMY still gets `material = null`.
- CEL-02 `game_root.gd` `_draw_block_depth()` (between background and wet reflections):
  one-point-perspective slab extrusion toward the canvas-centre vanishing point — bottom
  face always visible, side face flips at centre (left columns show lit-rule-consistent
  right faces and vice versa, key light top-left), purple-ink key-light drop shadow.
  RED_ENEMY/boss/maid get soft elliptical contact shadows instead (`_draw_contact_shadow`).
- `game_constants.gd`: new CEL_* tokens (ink/shadow colors, slab thickness 7px,
  perspective 0.045, per-type side colors; RED_ENEMY deliberately absent).
- New static test `tools/test_cel_25d.py` (shader feature set + VX-02 contract survival +
  draw-pass ordering + draw-only guard + blob protection).
- Verified: 7/7 `tools/test_*.py` PASS, duckflock 26 checks PASS (game scene steps frames
  with the new draw pass, console clean of shader/script errors), levelgen + pause runtime
  PASS. Shader+slab math cross-checked with a pixel-exact Python re-implementation
  (preview render confirms band/tint/outline/extrusion behaviour). Editor visual pass on
  real hardware still pending — tune uniforms/CEL_* tokens there if needed.

## CEL 2.5D pass — enemy coverage: CEL-03 (2026-06-13)
- Gap closed: the falling RED_ENEMY blobs were the only playfield bodies with no cel
  treatment (slab is rectangular, so they were excluded — only got a contact shadow).
  Now they get a dedicated blob-safe cel look that keeps the organic silhouette.
- CEL-03 `assets/shaders/enemy_cel.gdshader`: alpha-keyed (NO rounded-rect card mask) so
  E1.webp's silhouette is untouched. 3-step quantized top-light bands that MULTIPLY the
  sprite (stays red-first), crimson-tinted under-shade, warm (non-white) top rim light from
  the alpha edge, maroon inner ink outline. Preserves `COLOR.a = tex.a`.
- `block.gd`: preloads ENEMY_CEL_SHADER, shares one `_enemy_material` via
  `_get_enemy_material()`, applied in the RED_ENEMY branch (replaces the old
  `material = null`). The branch still never touches the rounded-card material.
- `game_root.gd` `_draw_block_depth()`: enemy now gets a two-part ground shadow — a drop
  shadow offset down-right of the top-left key light + a tight contact ellipse — so the
  blob reads as lifted with depth instead of pasted flat.
- Tests: new CEL-03 coverage in `tools/test_cel_25d.py`; refined
  `tools/test_levelgen_vx_expansion.py` enemy rule from "material = null" to the faithful
  "must not use the rounded corner-mask material" (intent = no rectangular card mask on the
  blob, which CEL-03 honours). `test_red_enemy_sprite.py` unchanged + still PASS (shader
  doesn't touch the sprite file, no draw_circle/arc in block.gd, no white flash).
- Verified: 7/7 `tools/test_*.py` PASS, headless import + enemy_cel shader compile clean,
  duckflock 26 checks PASS (draw passes exercised). Pixel-exact PIL preview confirms the
  enemy band/rim/ink/shadow read (outputs/cel_25d_enemies_preview.png).

## Character anim rig: ANIM-01 (2026-06-13)
- Goal (1h box): maid felt static/pasted in the screenshot. Make her motion smooth +
  dimensional WITHOUT new art. Researched game-feel refs (12 anim principles, hypercasual
  juice, pixel-idle breathing) → applied squash&stretch + secondary motion + breathing.
- `player.gd` procedural rig layered on top of the discrete maid frames (draw/transform
  only — aim/fire/collision contracts untouched, all existing test literals preserved):
  - Breathing: ~0.55 Hz sine → volume-ish scale (+Y/−X) + 1.6px bob; tray rides the
    opposite phase (secondary motion). Even the static combat_idle now reads as alive.
  - Throw squash→stretch: anticipation compression (<0.22 of OUTPUT_DURATION) then
    ease-out release elongation, eased via `_rig_squash` lerp so it ramps not pops.
  - Aim lean: body rotates toward the shot vector (±0.16 rad), tray counter-rotates.
- Verified: 7/7 `tools/test_*.py` PASS (player_output_vfx + six_axis literals intact),
  player.gd parse clean, headless duckflock run exercises the rig with zero errors, web
  rebuilt (pack game-fc1c1d6bf2711def.zip boots clean). Motion proof:
  outputs/anim_rig_montage.png. NOTE: no GPU in sandbox → timing/feel must still be
  eyeballed on real hardware; dial BREATH_*/THROW_*/AIM_LEAN_MAX/RIG_SMOOTH to taste.

## Character cel+rim polish: CEL-04 (2026-06-13)
- Directly closes ANIM-01 self-critique #1/#2 (maid read as a stock sprite on the stage;
  no rim light) WITHOUT generative tools — pure in-engine shader.
- `assets/shaders/character_cel.gdshader`: alpha-keyed (silhouette preserved, no card
  mask) — shallow cel bands (pastel kept), faint cool-violet low-band shadow, thin ink rim
  matching the block ink tone, and a cool stage rim light from the alpha edge gradient that
  lifts her off the dark neon background.
- `player.gd`: shared `_character_material` applied to `body` once in `_ready` (persists
  across per-frame texture swaps). All existing test literals preserved.
- Verified: 7/7 `tools/test_*.py` PASS, char shader compiles clean on import, headless
  duckflock run clean, web rebuilt. Before/after proof: store_assets/maid_cel_rim_
  beforeafter.png. Tune `rim_strength`/`band_depth`/`rim_color` on real hardware.
- NOTE on Higgsfield: MCP could not be connected from this session (Chrome extension not
  connected → can't drive web; browsers click-locked for computer-use; native-app access
  timed out; new MCPs don't surface mid-session). User connects it manually via
  Settings → custom connector → https://mcp.higgsfield.ai/mcp, then the generative
  overhaul plan in docs/higgsfield_game_plan.md runs next session.

## Remaining TODOs
- Run manual browser QA for drag aiming, paddle dragging during shooting, mobile touch feel,
  and the new pause/juggle flows (FL-01).
- CEL 2.5D: eyeball on real hardware (editor + web build); dial block `cel_strength`,
  `halftone_strength`, `CEL_SLAB_THICKNESS`, and enemy `rim_strength`/`ink_width` to taste.
  Boss bodies still flat-procedural — candidate follow-up: banded shading on boss `_draw`
  + title-screen unification.
- Compare runtime feel against `godot/docs/gameplay_spec.md` (LD-03).
- Next worklist candidates: LD-02 new block mechanic, LD-04 boss cycle variation,
  NEW-03 achievements, NEW-06 ko/en localization, P2-2 game_root split
  (see `docs/remaining_worklist_2026-06-13.md`).
