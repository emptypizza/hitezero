#!/usr/bin/env python3
"""Regression checks for the falling RED_ENEMY block sprite.

The falling enemy must be the dedicated pixel-art enemy sprite (E1.webp). It
must not be a full atlas crop, a flat placeholder square, or procedural face/HP
text drawn on top of the sprite, and its palette must stay red-first (neutral
outline/highlight pixels aside).
"""
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
BLOCK_SCRIPT = ROOT / "scripts" / "block.gd"
RED_ENEMY_SPRITE = ROOT / "assets" / "textures" / "blocks" / "E1.webp"


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def is_neutral(pixel: tuple[int, int, int, int]) -> bool:
    r, g, b, _a = pixel
    return max(r, g, b) - min(r, g, b) <= 30


def is_red_first(pixel: tuple[int, int, int, int]) -> bool:
    r, g, b, a = pixel
    if a <= 0:
        return True
    if is_neutral(pixel):
        # Black outline / white highlight pixels are fine as long as they stay neutral.
        return True
    return r >= g and r >= b


def main() -> None:
    source = BLOCK_SCRIPT.read_text(encoding="utf-8")

    require(RED_ENEMY_SPRITE.is_file(), "Missing dedicated red enemy sprite: assets/textures/blocks/E1.webp")
    require('preload("res://assets/textures/blocks/E1.webp")' in source, "Block.gd must preload the dedicated pixel-art red enemy sprite (E1.webp)")
    require("TEX_RED_ENEMY" in source, "Block.gd must keep the dedicated TEX_RED_ENEMY texture constant")
    require("enemy.jpg" not in source, "Falling enemy must not use the old atlas-like enemy.jpg texture")
    require("draw_circle" not in source and "draw_arc" not in source, "Falling enemy sprite must not have non-red procedural face overlays")
    require("BLOCK_RED_ENEMY]" not in source, "Falling enemy should not show a non-red HP label over the red sprite")
    require("Color(1.0, 1.0, 1.0, 1.0)" not in source or "_flash_target_color" in source, "Red enemy hit flash must not wash out to white")

    image = Image.open(RED_ENEMY_SPRITE).convert("RGBA")
    require(image.size == (129, 122), f"Red enemy sprite should stay the crisp 129x122 pixel-art sprite, got {image.size}")

    pixels = list(image.get_flattened_data() if hasattr(image, "get_flattened_data") else image.getdata())
    visible = [pixel for pixel in pixels if pixel[3] > 0]
    require(visible, "Red enemy sprite has no visible pixels")

    off_palette = [pixel for pixel in visible if not is_red_first(pixel)]
    ratio = len(off_palette) / float(len(visible))
    require(ratio <= 0.005, f"Red enemy sprite must stay red-first; off-palette visible pixel ratio={ratio:.4f}")

    unique_visible_colors = {pixel[:3] for pixel in visible}
    require(len(unique_visible_colors) >= 5, f"Red enemy sprite is too flat; expected at least 5 tones, got {len(unique_visible_colors)}")

    alpha_values = [pixel[3] for pixel in pixels]
    require(min(alpha_values) == 0, "Red enemy should have transparent corners/silhouette, not a full rectangular tile")
    require(max(alpha_values) == 255, "Red enemy should have solid core pixels")

    # All four corners should be empty so the enemy reads as a creature silhouette, not a square placeholder.
    width, height = image.size
    corner_coords = [(0, 0), (width - 1, 0), (0, height - 1), (width - 1, height - 1)]
    for x, y in corner_coords:
        require(image.getpixel((x, y))[3] == 0, f"Corner ({x},{y}) should be transparent")

    red_values = [pixel[0] for pixel in visible]
    require(max(red_values) - min(red_values) >= 80, "Red enemy needs visible red shading/depth, not one flat red fill")

    print("PASS red enemy sprite is dedicated, red-first, and pixel-art quality")


if __name__ == "__main__":
    main()
