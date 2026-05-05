#!/usr/bin/env python3
"""Regression checks for the web-researched HiteZero six-axis quality pass.

The goal is to keep the polish work concrete instead of letting it drift back
into notes only: safe HUD/playfield separation, immediate throw feedback,
projectile trails, directional juice, and web QA observability must all have
source-level hooks.
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CONSTANTS = ROOT / "scripts" / "game_constants.gd"
LEVEL_GEN = ROOT / "scripts" / "level_generator.gd"
GAME_ROOT = ROOT / "scripts" / "game_root.gd"
KNIFE = ROOT / "scripts" / "knife.gd"
PLAN = ROOT / "docs" / "hitezero_six_axis_quality_plan.md"


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def main() -> None:
    constants = CONSTANTS.read_text(encoding="utf-8")
    level_gen = LEVEL_GEN.read_text(encoding="utf-8")
    game_root = GAME_ROOT.read_text(encoding="utf-8")
    knife = KNIFE.read_text(encoding="utf-8")
    plan = PLAN.read_text(encoding="utf-8")

    # 1-2: researched pixel/animation quality must be captured in a durable plan.
    for source_marker in [
        "https://en.wikipedia.org/wiki/Pixel_art",
        "https://en.wikipedia.org/wiki/Twelve_basic_principles_of_animation",
        "https://en.wikipedia.org/wiki/Game_feel",
        "https://developer.apple.com/design/human-interface-guidelines/layout",
        "https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html",
    ]:
        require(source_marker in plan, f"Plan is missing research source: {source_marker}")

    # 3: throw release should have immediate visible feedback before the spawn timer fires.
    require("func _play_release_commit_cue" in game_root, "GameRoot needs an immediate release commit cue helper")
    start_body = game_root.split("func _start_shooting() -> void:", 1)[1].split("func _on_spawn_timer_timeout", 1)[0]
    require("_play_release_commit_cue()" in start_body, "_start_shooting must play the release commit cue immediately")
    require("player.play_output(aim_angle)" in game_root, "Release/shot cue must reuse Player.play_output for visible player feedback")

    # 4: projectile readability should follow the knife, not only the player's muzzle flash.
    require("var trail_points" in knife, "Knife needs per-projectile trail point history")
    require("func _draw_trail" in knife, "Knife needs a dedicated trail drawing helper")
    require("TRAIL_MAX_POINTS" in knife and "TRAIL_CORE_COLOR" in knife, "Knife trail needs capped history and a warm readable core")
    require("Color(0.03, 0.04, 0.08" in knife, "Knife trail needs a dark outer stroke for contrast")
    require("trail_points.clear()" in knife and ("trail_points.append(position)" in knife or "trail_points.append(global_position)" in knife), "Knife.configure must reset and seed trail history")

    # 5: HUD/playfield separation should not depend on a magic 60px row start.
    require("const LEVEL_START_Y" in constants, "GameConstants needs a named LEVEL_START_Y safe-band constant")
    require("TOP_BAR_HEIGHT +" in constants, "LEVEL_START_Y should be derived from TOP_BAR_HEIGHT")
    require("GameConstants.LEVEL_START_Y" in level_gen, "LevelGenerator must use the safe level start constant")
    require("60.0 + float(row)" not in level_gen, "LevelGenerator must not use the old hard-coded 60px top row")

    # 4-5: directional shake/juice should encode shot direction instead of pure random noise.
    require("var shake_direction" in game_root, "GameRoot needs directional shake state")
    require("func _kick_world" in game_root, "GameRoot needs a directional world kick helper")
    require("-dir" in game_root or "shot_dir" in game_root, "Shake should be biased opposite the shot/hit direction")

    # 6: web/mobile QA needs runtime-safe-band observability.
    require('"visual_safety"' in game_root, "Web bridge payload must expose visual_safety values")
    require('"hud_bottom"' in game_root and '"level_start_y"' in game_root, "visual_safety should include HUD and level-start values")

    print("PASS six-axis quality hooks are implemented")


if __name__ == "__main__":
    main()
