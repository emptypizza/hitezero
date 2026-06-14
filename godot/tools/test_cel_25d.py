#!/usr/bin/env python3
"""Static regression checks for the CEL 2.5D pass (2026-06-13).

CEL-01  rounded_block.gdshader gains cel shading (banded top light, purple
        anime shadow + screen-space halftone, ink outline, key-lit bevel,
        foil glint) while keeping the original VX-02 rounded-corner contract.
CEL-02  game_root.gd gains a draw-only _draw_block_depth pass: perspective
        slab extrusion + key-light drop shadows + contact shadows, ordered
        under the sprites (between background and wet reflections).

Both must stay pure cosmetics: no AABB, HP or sim-state writes, and the
RED_ENEMY blob must keep material = null (no card mask, no slab).
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SHADER = ROOT / "assets" / "shaders" / "rounded_block.gdshader"
GAME_ROOT = ROOT / "scripts" / "game_root.gd"
CONSTANTS = ROOT / "scripts" / "game_constants.gd"
BLOCK = ROOT / "scripts" / "block.gd"


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def extract_func(source: str, name: str) -> str:
    start = source.index(f"func {name}(")
    rest = source[start:]
    end = rest.find("\nfunc ", 1)
    return rest if end == -1 else rest[:end]


def main() -> None:
    shader = SHADER.read_text(encoding="utf-8")
    game_root = GAME_ROOT.read_text(encoding="utf-8")
    constants = CONSTANTS.read_text(encoding="utf-8")
    block = BLOCK.read_text(encoding="utf-8")

    # ── CEL-01: shader keeps the VX-02 contract… ────────────────────────────
    require("corner_radius" in shader and "smoothstep" in shader,
            "CEL-01: rounded-corner contract (corner_radius + smoothstep) must survive")
    require("COLOR.a *= mask" in shader,
            "CEL-01: the silhouette must still come from the alpha mask line")

    # …and adds the cel-slab feature set.
    require("cel_strength" in shader,
            "CEL-01: needs a cel_strength master uniform so the look can be dialed")
    require("floor(l * 3.0)" in shader or "floor(l*3.0)" in shader,
            "CEL-01: lighting must be quantized into discrete cel bands")
    require("shadow_tint" in shader,
            "CEL-01: shadow band must be tinted (anime purple), not plain darkened")
    require("FRAGCOORD" in shader and "halftone" in shader,
            "CEL-01: shadow band needs the screen-space halftone screentone")
    require("outline_color" in shader and "outline_width" in shader,
            "CEL-01: needs the inner ink outline uniforms")
    require("light_dir" in shader and "bevel_width" in shader,
            "CEL-01: bevel rim must react to the key light direction")
    require("glint" in shader and "TIME" in shader,
            "CEL-01: foil glint sweep must animate on shader TIME")

    # ── CEL-02: depth pass exists and is ordered under the sprites ──────────
    require("func _draw_block_depth() -> void:" in game_root,
            "CEL-02: game_root.gd must define _draw_block_depth()")
    require("func _draw_contact_shadow(" in game_root,
            "CEL-02: contact-shadow helper missing")
    draw_root = extract_func(game_root, "_draw")
    require("_draw_block_depth()" in draw_root,
            "CEL-02: _draw() must call the depth pass")
    require(draw_root.index("_draw_background()") < draw_root.index("_draw_block_depth()")
            < draw_root.index("_draw_wet_reflections()"),
            "CEL-02: depth pass must sit between background and wet reflections")

    depth = extract_func(game_root, "_draw_block_depth")
    require("CEL_SLAB_PERSPECTIVE" in depth and "CEL_SLAB_THICKNESS" in depth,
            "CEL-02: slab geometry must read the GameConstants CEL tokens")
    require("BLOCK_RED_ENEMY" in depth and "_draw_contact_shadow" in depth,
            "CEL-02: RED_ENEMY must branch to a contact shadow, never a slab")
    require("draw_colored_polygon" in depth,
            "CEL-02: side/bottom faces must be real polygons (perspective extrusion)")
    for forbidden in ("take_damage", "hp =", ".position =", "velocity", "queue_free"):
        require(forbidden not in depth,
                f"CEL-02: depth pass must stay draw-only (found '{forbidden}')")

    # ── Shared tokens ────────────────────────────────────────────────────────
    for token in ("CEL_INK", "CEL_SHADOW_COLOR", "CEL_SHADOW_ALPHA",
                  "CEL_SLAB_THICKNESS", "CEL_SLAB_PERSPECTIVE", "CEL_SIDE_COLORS"):
        require(token in constants, f"GameConstants must define {token}")
    require("BLOCK_RED_ENEMY" not in constants.split("CEL_SIDE_COLORS")[1].split("}")[0],
            "CEL_SIDE_COLORS must not include RED_ENEMY (blob gets no slab)")

    # ── CEL-03: blob-safe enemy cel shader ───────────────────────────────────
    enemy_shader_path = ROOT / "assets" / "shaders" / "enemy_cel.gdshader"
    require(enemy_shader_path.is_file(),
            "CEL-03: assets/shaders/enemy_cel.gdshader must exist")
    enemy_shader = enemy_shader_path.read_text(encoding="utf-8")
    require("texture(TEXTURE, UV)" in enemy_shader,
            "CEL-03: enemy shader must key off the sprite texture/alpha, not a UV rect")
    require("COLOR.a = tex.a" in enemy_shader,
            "CEL-03: enemy shader must preserve the blob silhouette alpha unchanged")
    require("corner_radius" not in enemy_shader and "COLOR.a *= mask" not in enemy_shader,
            "CEL-03: enemy shader must NOT reuse the rounded-card UV mask")
    require("floor(l * 3.0)" in enemy_shader or "floor(l*3.0)" in enemy_shader,
            "CEL-03: enemy shading must be quantized into cel bands")
    require("ink_color" in enemy_shader and "rim_light" in enemy_shader,
            "CEL-03: enemy needs the ink outline + rim-light depth cues")
    require("ENEMY_CEL_SHADER" in block and "_get_enemy_material" in block,
            "CEL-03: block.gd must preload + share the enemy cel material")
    enemy_branch = block.split("func _apply_block_visual", 1)[1] \
        .split("BLOCK_RED_ENEMY:", 1)[1].split("BLOCK_STAR:", 1)[0]
    require("_get_enemy_material()" in enemy_branch,
            "CEL-03: RED_ENEMY branch must apply the blob cel material")
    require("_get_rounded_material" not in enemy_branch,
            "CEL-03: RED_ENEMY must still skip the rounded-card mask")

    # ── Blob protection stays intact ─────────────────────────────────────────
    require("draw_circle" not in block and "draw_arc" not in block,
            "block.gd must stay free of procedural circle overlays")

    print("CEL 2.5D pass checks: OK")


if __name__ == "__main__":
    main()
