#!/usr/bin/env python3
"""Static regression checks for the HiteZero player output presentation.

These checks intentionally avoid launching the game so they can run quickly in
CI/local terminal while still proving the new sprite-driven output treatment is
wired into the Godot project.
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PLAYER_SCRIPT = ROOT / "scripts" / "player.gd"
GAME_ROOT_SCRIPT = ROOT / "scripts" / "game_root.gd"
TITLE_SCRIPT = ROOT / "scripts" / "title.gd"
SPRITE_DIR = ROOT / "assets" / "textures" / "player" / "maid"


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def main() -> None:
    player_source = PLAYER_SCRIPT.read_text(encoding="utf-8")
    game_source = GAME_ROOT_SCRIPT.read_text(encoding="utf-8")
    title_source = TITLE_SCRIPT.read_text(encoding="utf-8")

    expected_frames = [
        *(f"idle_{i}.png" for i in range(5)),
        *(f"run_{i}.png" for i in range(6)),
        *(f"attack_{i}.png" for i in range(5)),
        "combat_idle.png",
        "gameover_down.png",
    ]
    missing = [name for name in expected_frames if not (SPRITE_DIR / name).is_file()]
    require(not missing, f"Missing extracted maid sprite frames: {missing}")

    require("func play_output" in player_source, "Player needs a play_output() hook for shot-spawn VFX")
    require("_draw_output_vfx" in player_source, "Player should draw a local output flash/slash effect")
    require("TEX_ATTACK_FRAMES" in player_source, "Player should animate attack frames from the maid sprite")
    require("OUTPUT_FLASH_TIME := 0.26" in player_source and "OUTPUT_PARTICLE_COUNT := 18" in player_source, "Output VFX should be bright/long enough to read during rapid knife spawning")
    require("player.play_output(aim_angle)" in game_source, "GameRoot must trigger the player output VFX when each knife spawns")
    require("OutputVfx" in (ROOT / "scenes" / "player.tscn").read_text(encoding="utf-8"), "Player scene needs an OutputVfx node for draw ordering")
    require("preview.position = Vector2(GameConstants.CANVAS_WIDTH * 0.5, 372.0)" in title_source, "Title preview should sit below the headline instead of covering text")
    require("preview.scale = Vector2(1.28, 1.28)" in title_source, "Title preview scale should leave readable room for the headline")
    require("title_box.position = Vector2(34.0, 72.0)" in title_source, "Title copy should be lifted into a clean readable header band")
    require("button_box.position = Vector2(70.0, 438.0)" in title_source, "Title buttons should sit below the hero sprite with safe bottom breathing room")
    require("best_score_label.custom_minimum_size = Vector2(0.0, 28.0)" in title_source, "Best score label needs its own safe spacing band")
    require("func _apply_label_shadow" in title_source and "font_shadow_color" in title_source, "Title labels need shadow treatment for readability over the hero background")
    require("func _make_button_style" in title_source and "start_button.add_theme_stylebox_override" in title_source, "Title buttons need custom neon styleboxes for a premium call-to-action")
    require("func _make_panel_style" in title_source and "title_card.add_theme_stylebox_override" in title_source, "Title copy needs a subtle glass panel to separate it from the neon background")
    require("preview.show_tray = false" in title_source and "preview.set_waiting_knives(0, false)" in title_source, "Title hero preview should hide gameplay tray/knife UI clutter")

    print("PASS player output VFX wiring")


if __name__ == "__main__":
    main()
