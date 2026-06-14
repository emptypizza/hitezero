#!/usr/bin/env python3
"""Regression checks for the worklist drop: LD-01 + VX-01/02/03.

  LD-01  Late-run pattern pool expansion + anti-repeat pick
         (level_generator.gd: DENSE grown, BRUTAL added for lv 20+).
  VX-01  Wet-ground fake reflections (game_root.gd draw pass).
  VX-02  Rounded block corners via shared shader mask (block.gd + shader),
         with the RED_ENEMY blob explicitly excluded.
  VX-03  Cyan bubble-pop on elite/boss kills (game_root.gd vfx system).

Source-level hooks in the style of test_arcade_feel_polish.py — the Godot
binary isn't available here, so pattern data is validated statically and the
behavioural half lives in tools/test_levelgen_expansion.gd (run locally with
`godot --headless --path godot -s tools/test_levelgen_expansion.gd`).
"""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LEVELGEN = ROOT / "scripts" / "level_generator.gd"
GAME_ROOT = ROOT / "scripts" / "game_root.gd"
BLOCK = ROOT / "scripts" / "block.gd"
SHADER = ROOT / "assets" / "shaders" / "rounded_block.gdshader"

VALID_SLOTS = set(".NSEPX")
MAX_ROWS = 6  # DENSE "Full grid" precedent — deeper would crowd the paddle.


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def extract_pool(source: str, name: str) -> list[list[str]]:
    match = re.search(rf"const {name}: Array = \[(.*?)\n\]", source, re.DOTALL)
    require(match is not None, f"{name} pool must exist in level_generator.gd")
    body = match.group(1)
    patterns: list[list[str]] = []
    for chunk in re.findall(r"\[([^\[\]]+)\]", body):
        rows = re.findall(r'"([^"]+)"', chunk)
        if rows:
            patterns.append(rows)
    require(len(patterns) > 0, f"{name} pool must contain patterns")
    return patterns


def main() -> None:
    levelgen = LEVELGEN.read_text(encoding="utf-8")
    game_root = GAME_ROOT.read_text(encoding="utf-8")
    block = BLOCK.read_text(encoding="utf-8")
    require(SHADER.exists(), "assets/shaders/rounded_block.gdshader must exist")
    shader = SHADER.read_text(encoding="utf-8")

    # ── LD-01: pool integrity ────────────────────────────────────────────────
    pools = {
        "PATTERNS_EASY": extract_pool(levelgen, "PATTERNS_EASY"),
        "PATTERNS_MEDIUM": extract_pool(levelgen, "PATTERNS_MEDIUM"),
        "PATTERNS_COMPLEX": extract_pool(levelgen, "PATTERNS_COMPLEX"),
        "PATTERNS_DENSE": extract_pool(levelgen, "PATTERNS_DENSE"),
        "PATTERNS_BRUTAL": extract_pool(levelgen, "PATTERNS_BRUTAL"),
    }
    for name, patterns in pools.items():
        for pi, pattern in enumerate(patterns):
            require(1 <= len(pattern) <= MAX_ROWS,
                    f"{name}[{pi}] must have 1..{MAX_ROWS} rows, has {len(pattern)}")
            for ri, row in enumerate(pattern):
                require(len(row) == 7,
                        f"{name}[{pi}] row {ri} must be exactly 7 cols: {row!r}")
                bad = set(row) - VALID_SLOTS
                require(not bad,
                        f"{name}[{pi}] row {ri} has invalid slot chars {bad}: {row!r}")

    require(len(pools["PATTERNS_DENSE"]) >= 7,
            "LD-01: DENSE pool must be expanded to >= 7 patterns")
    require(len(pools["PATTERNS_BRUTAL"]) >= 4,
            "LD-01: BRUTAL pool must hold >= 4 late-run patterns")

    # Every BRUTAL pattern still guarantees a star path (S or X slot present);
    # the generator's fallback star keeps levels winnable either way, but the
    # designed layouts should not lean on the fallback.
    for pi, pattern in enumerate(pools["PATTERNS_BRUTAL"]):
        joined = "".join(pattern)
        require("S" in joined or "X" in joined,
                f"PATTERNS_BRUTAL[{pi}] should place a star (or X wildcard)")

    # ── LD-01: selection logic + anti-repeat ─────────────────────────────────
    require("static var _last_pattern" in levelgen,
            "LD-01: anti-repeat memory (_last_pattern) must exist")
    require("PATTERNS_BRUTAL" in levelgen.split("func _pick_pattern", 1)[1],
            "LD-01: _pick_pattern must route to PATTERNS_BRUTAL")
    require("level <= 19" in levelgen,
            "LD-01: DENSE band must cap at lv 19 before BRUTAL takes over")
    require("pool[idx] == _last_pattern" in levelgen,
            "LD-01: consecutive-stage repeat guard must compare against _last_pattern")

    # ── VX-02: rounded corners shader ────────────────────────────────────────
    require("corner_radius" in shader and "smoothstep" in shader,
            "VX-02: shader needs a corner_radius uniform with a smoothstep mask")
    require("COLOR.a *= mask" in shader,
            "VX-02: shader must mask alpha only (texture colors untouched)")
    require("rounded_block.gdshader" in block,
            "VX-02: block.gd must preload the rounded-block shader")
    require("static var _rounded_material" in block,
            "VX-02: blocks must share one ShaderMaterial instance")
    visual_fn = block.split("func _apply_block_visual", 1)[1]
    enemy_branch = visual_fn.split("GameConstants.BLOCK_RED_ENEMY:", 1)[1]
    enemy_branch = enemy_branch.split("GameConstants.BLOCK_STAR:", 1)[0]
    # The blob must never wear the rounded-CARD mask. (CEL-03 may give it the
    # dedicated alpha-keyed blob cel material instead — that preserves the
    # organic silhouette, which is the property this rule actually protects.)
    require("_get_rounded_material" not in enemy_branch
            and "_rounded_material" not in enemy_branch,
            "VX-02: RED_ENEMY blob must opt out of the rounded corner-mask material")

    # ── VX-01: wet-ground reflections ────────────────────────────────────────
    require("func _draw_wet_reflections" in game_root,
            "VX-01: game_root needs the wet-reflection draw pass")
    draw_fn = game_root.split("func _draw()", 1)[1].split("func ", 1)[0]
    require("_draw_wet_reflections()" in draw_fn,
            "VX-01: _draw() must call the reflection pass")
    require(draw_fn.index("_draw_background()") < draw_fn.index("_draw_wet_reflections()"),
            "VX-01: reflections must render above the background grid")
    for const in ("REFLECT_ALPHA_BLOCK", "REFLECT_OFFSET", "REFLECT_SQUASH"):
        require(const in game_root, f"VX-01: tuning const {const} must exist")
    alpha = float(re.search(r"REFLECT_ALPHA_BLOCK := ([0-9.]+)", game_root).group(1))
    require(alpha <= 0.2,
            "VX-01: reflections must stay subtle (alpha <= 0.2) for readability")

    # ── VX-03: bubble pop ────────────────────────────────────────────────────
    require("func _spawn_bubble_pop" in game_root,
            "VX-03: bubble-pop spawner must exist")
    require('"shape": "bubble"' in game_root,
            "VX-03: bubbles must ride the existing vfx_particles system")
    require('"bubble":' in game_root.split("func _draw_vfx_particles", 1)[1],
            "VX-03: _draw_vfx_particles needs a bubble branch")
    require("_spawn_bubble_pop(bpos, false)" in game_root,
            "VX-03: elite (RED_ENEMY) destroy must trigger a small pop")
    require("_spawn_bubble_pop(bpos + offset, true)" in game_root,
            "VX-03: boss defeat explosions must trigger big pops")
    update_fn = game_root.split("func _update_vfx_particles", 1)[1].split("func ", 1)[0]
    require("bubble" in update_fn,
            "VX-03: bubbles need buoyancy in the particle update")

    print("PASS LD-01 + VX-01/02/03 worklist hooks are implemented")


if __name__ == "__main__":
    main()
