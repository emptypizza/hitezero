#!/usr/bin/env python3
"""Regression checks for the arcade-feel polish pass (phase 1).

Covers the four core game-feel directions implemented as pure GDScript:
  1. SFX dynamics  — combo pitch ramp + low-frequency impact sub-layer.
  2. Block squash & stretch + directional impact sparks (visual-only).
  3. Screen shake trauma squared model + rotation/zoom kick.
  4. Mobile haptics util (web + native branch) wired into impact events.

These are source-level hooks, not behavioural sims — they keep the polish from
silently regressing back into notes. (The Godot binary isn't available in CI
here, so this stands in for `--check-only` on the touched feel paths.)
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
AUDIO = ROOT / "scripts" / "audio_manager.gd"
GAME_ROOT = ROOT / "scripts" / "game_root.gd"
VFX_SYSTEM = ROOT / "scripts" / "systems" / "vfx_system.gd"
BLOCK = ROOT / "scripts" / "block.gd"
HAPTICS = ROOT / "scripts" / "haptics.gd"
PROJECT = ROOT / "project.godot"


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def main() -> None:
    audio = AUDIO.read_text(encoding="utf-8")
    game_root = GAME_ROOT.read_text(encoding="utf-8")
    vfx_system = VFX_SYSTEM.read_text(encoding="utf-8")
    block = BLOCK.read_text(encoding="utf-8")
    project = PROJECT.read_text(encoding="utf-8")
    require(HAPTICS.exists(), "scripts/haptics.gd autoload must exist")
    haptics = HAPTICS.read_text(encoding="utf-8")

    # ── 1. SFX dynamics ──────────────────────────────────────────────────────
    require("func play(sound_name: String, pitch" in audio,
            "AudioManager.play must accept a pitch (and volume offset) argument")
    require("pitch_scale" in audio, "AudioManager must apply pitch_scale per play")
    require("max_polyphony" in audio,
            "AudioManager players need polyphony so combo spam doesn't cut off")
    require("func _gen_subthump" in audio and "block_subthump" in audio,
            "AudioManager needs a low-frequency sub-thump impact layer")
    require("func _combo_pitch" in game_root,
            "GameRoot needs a combo-driven pitch helper")
    require('AudioManager.play("block_hit", _combo_pitch())' in game_root,
            "Block hits must ramp pitch with the combo count")
    require('AudioManager.play("block_subthump"' in game_root,
            "Destruction must layer the sub-thump for weight")

    # ── 2. Block squash & stretch + directional sparks ───────────────────────
    require("func take_hit(impact_dir" in block,
            "Block.take_hit must take an impact direction for the squash")
    require("_squash_t" in block and "func _squash_scale" in block,
            "Block needs a decaying squash & stretch driven by impact")
    require("block_sprite.position" in block,
            "Squash knockback must move the sprite (visual only), not the node")
    require("func get_local_aabb" in block,
            "Block needs a world-local AABB so cosmetic transforms don't shift collision")
    require("block.get_local_aabb()" in game_root and "block.get_aabb()" not in
            game_root.split("func _draw_collider_debug", 1)[0],
            "Gameplay collision must use the world-local AABB (debug draw may keep global)")
    require("_hit_block(block, impact_dir)" in game_root,
            "Collision must forward the impact direction into the hit")
    require("func spawn_impact_sparks" in vfx_system and '"streak"' in vfx_system,
            "Hits need directional spark streaks (moved to vfx_system.gd)")

    # ── 3. Screen shake trauma² + rotation/zoom kick ─────────────────────────
    require("var trauma" in game_root and "func _add_trauma" in game_root,
            "GameRoot needs a trauma(0..1) accumulator")
    require("trauma * trauma" in game_root,
            "Displayed shake must be trauma squared, not linear")
    require("FastNoiseLite" in game_root,
            "Shake should use smooth noise instead of per-frame randf")
    require("world.rotation" in game_root and "world.scale" in game_root,
            "Big impacts need a rotation + zoom kick")
    require("func _camera_punch" in game_root,
            "GameRoot needs a zoom-punch helper")
    require("var shake_direction" in game_root,
            "Directional bias must survive the trauma refactor")

    # ── 4. Mobile haptics ────────────────────────────────────────────────────
    require("vibrate_handheld" in haptics, "Haptics needs the native vibrate branch")
    require("navigator.vibrate" in haptics, "Haptics needs the web vibrate branch")
    require(all(f"func {n}" in haptics for n in ("light", "medium", "heavy")),
            "Haptics needs light/medium/heavy presets")
    require("enabled" in haptics, "Haptics needs an on/off toggle")
    require('Haptics="*res://scripts/haptics.gd"' in project,
            "Haptics must be registered as an autoload")
    require("Haptics.light()" in game_root and "Haptics.heavy()" in game_root,
            "Haptics must be wired into hit / destroy / heavy impact events")

    print("PASS arcade-feel polish hooks (phase 1) are implemented")


if __name__ == "__main__":
    main()
