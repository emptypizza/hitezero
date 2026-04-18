# FX Rollout

This Godot port intentionally splits visual effects into two stages so the core loop stays web-safe first.

## Stage 1: Implemented Now
- Neon arena frame and grid background are drawn in `GameRoot`.
- Aiming guide line is rendered in `GameRoot`.
- Hit feedback uses lightweight expanding burst circles instead of particle systems.
- Heart loss uses player tint flash and lightweight world shake.
- Stage clear and game over overlays are handled in `Hud`.

## Stage 2: Deferred Until Web Profiling
- CRT full-screen shader
- Bloom / glow full-screen shader
- Dense background dust particles
- Decorative title particles
- Chained post-processing passes

## Why These Effects Are Deferred
- The target platform is Godot Web export with the Compatibility renderer.
- Phaser used WebGL post pipelines directly, but Godot needs shader rewrites and they are more likely to hurt mobile browser performance.
- Stage 1 needs gameplay parity and browser stability before adding expensive screen-space effects.

## Re-introduction Order
1. Add a single optional CRT pass on a `ColorRect` with `ShaderMaterial`.
2. Profile on desktop Chrome and a mobile browser before enabling it by default.
3. Add glow only if frame time remains stable.
4. Add decorative particles last, and only in low counts.

## Current Recommendation
- Keep stage-1 visuals enabled by default.
- Gate stage-2 effects behind a debug flag or quality preset once web profiling data exists.
