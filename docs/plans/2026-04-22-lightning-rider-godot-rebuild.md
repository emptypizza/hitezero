# Lightning Rider Godot Rebuild Plan

> **For Hermes:** Use subagent-driven-development skill to implement this plan task-by-task.

**Goal:** Rebuild the reference materials from the supplied videos into two Godot deliverables: (1) a gameplay build matching the Lightning Rider mobile maze-collection presentation as closely as feasible from video evidence, and (2) a level-editor build matching the ONIGIRI-style chunk/stage editor shown in the reference videos.

**Architecture:** Use the current HiteZero Godot repo as a foundation only where reusable Godot 4 web/export plumbing helps. Implement new scenes and scripts under a separate `lightning_rider/` namespace so existing HiteZero gameplay remains intact. Produce two web-capable Godot builds from one repo: `lightning-rider-game` and `lightning-rider-editor`.

**Tech Stack:** Godot 4.6, GDScript, 2D scenes, custom Control-based editor UI, existing web export tooling.

---

## Reference Summary
- `gameclip.mov`: mobile portrait neon maze-collection game with title screen `LIGHTNING RIDER`, cute character, START menu, READY text, top HUD, path dots/collectibles.
- `mapeditor.mov`: dark-theme `ONIGIRI Level Editor` with chunk/stage list, tile palette, stats panel, metadata inspector, chunk/stage composition workflow.
- `doc.mov`: documentation/spec page for `라이트닝 라이더 라나`; useful as metadata inspiration, not primary art source.

## Deliverables
1. `lightning-rider-game` runnable build
2. `lightning-rider-editor` runnable build
3. Web/itch-style export artifacts for both
4. Asset provenance note describing which visuals were hand-drawn/generated/reconstructed from reference

## Implementation Tracks
1. Reference extraction and style bible
2. Separate Godot scene tree for gameplay build
3. Separate Godot scene tree for editor build
4. Shared theme/assets/export pipeline
5. Verification and packaging
