# Gameplay Spec

This document captures the current gameplay contract for the Godot version of HiteZero.

## Core Constants
- Logical viewport: `400x700`
- Top HUD bar: `50px`
- Paddle travel range: `x = 20..380`
- Paddle baseline: `y = 620`
- Tray collider offset: `76px` above paddle origin
- Knife radius: `5px`
- Knife base speed: `720 px/s`
- Knife spawn cadence: `66 ms`
- Hearts: `3`
- Grid columns: `7`

## Scene Flow
1. `Boot` immediately forwards to the title screen.
2. `Title` shows start, help, and best score UI.
3. `Game` owns the world state and instantiates the HUD.

## Game State Machine
- `AIMING`
  - Drag on the playfield to set the throw angle.
  - Releasing the drag starts the shooting phase.
  - Waiting knives are visible near the player.
- `SHOOTING`
  - Knives spawn from the locked paddle X position.
  - The paddle can still move horizontally while knives are in flight.
  - `RED_ENEMY` blocks start falling only after the first shot sequence begins.
- `STAGE_CLEAR`
  - Triggered when there are no `STAR` blocks left.
  - All knives are cleared.
  - Earned stars are converted into extra knives.
  - After `1.2s`, the next level is generated and the game returns to `AIMING`.
- `GAME_OVER`
  - Triggered when all knives are inactive and no stars were cleared, or when hearts reach zero.
  - Tapping or clicking restarts the current level.

## Input Contract
- Keyboard:
  - `Left` / `A` moves paddle left.
  - `Right` / `D` moves paddle right.
- Pointer / touch:
  - In `AIMING`: press starts aiming, movement updates aim, release fires.
  - In `SHOOTING`: drag directly repositions the paddle X.
  - In `GAME_OVER`: press restarts the level.

## Aim Rules
- Aim angle is computed from pointer position relative to the paddle origin.
- Angles are clamped to `[-PI + 0.1, -0.1]`.
- A dashed guide line is rendered only while dragging during `AIMING`.

## Knife Rules
- Knives spawn from `fire_x`, which is captured when shooting starts.
- Main knives use full speed.
- `POW` destruction spawns `8` mini knives at `60%` speed in a radial spread.
- Wall bounces:
  - Left and right walls reflect X velocity.
  - The top wall sits at `TOP_BAR_HEIGHT`.
- Safety clamp:
  - Absolute Y velocity is never allowed to drop below `18 px/s`.
- Tray bounce:
  - Only applies when the knife is moving downward.
  - Bounce angle depends on the horizontal hit position on the tray.
  - Speed magnitude is preserved on bounce.
- Bottom rule:
  - When a knife reaches `BOTTOM_Y`, it becomes inactive and invisible.

## Block Types
- `NORMAL`
  - HP equals current level.
  - Must show its HP label.
- `STAR`
  - HP is always `1`.
  - Destroying all stars clears the stage.
  - Each destroyed star grants one extra knife for the next stage.
- `POW`
  - HP is always `1`.
  - On destroy, spawns the radial mini-knife burst.
- `RED_ENEMY`
  - HP starts at current level.
  - Moves downward only after shooting begins.
  - If it overlaps the bottom danger zone, the player loses one heart and the enemy is removed.

## Collision Rules
- Knife vs block collision is manual circle-vs-AABB.
- On penetration:
  - The knife is pushed out along the contact normal.
  - Velocity reflects on the dominant collision axis.
  - The block loses `1 HP`.
- Block destruction:
  - Remove the block and its HP label.
  - Add `100` score.
  - Emit UI refresh.

## Win / Lose Rules
- Win condition: `stars_left == 0`.
- Lose condition A: all knives inactive, spawn timer finished, and `knives_to_shoot == 0`.
- Lose condition B: hearts drop to `0`.

## UI Contract
- Top bar must show:
  - Hearts
  - Knife count
  - Remaining stars
- Overlay states:
  - `STAGE CLEAR!` with next level hint
  - `GAME OVER` with restart instruction
- Utility actions:
  - Return to title
  - Toggle collider debug visualization

## Visual Expectations
- Neon arena frame and grid background
- Simple impact feedback on hits
- Hit reaction on heart loss
- Optional post-processing can be layered in later if web performance allows
