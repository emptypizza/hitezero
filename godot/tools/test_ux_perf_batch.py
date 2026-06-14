#!/usr/bin/env python3
"""Regression checks for the UX/perf worklist batch (2026-06-13).

  NEW-01  In-game soft pause: pill + P/ESC + focus-out auto-pause, resume tap
          swallowed, timers held, headless guard.
  NEW-02  Mute pill persists via Session settings.
  P1-1    Web bridge ambient serialization throttled (events stay immediate).
  P1-2    _emit_ui_update dedupes identical payloads (same-tick on change).
  P1-3    Collision broad-phase prefilter before AABB/sqrt math.
  FL-02   Tray-bounce active play: combo keep-alive + per-stage juggle bonus.
  P2-4    session.submit_score dead code removed.

Source-level hooks in the style of the sibling test_*.py files.
"""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GAME_ROOT = ROOT / "scripts" / "game_root.gd"
HUD = ROOT / "scripts" / "hud.gd"
SESSION = ROOT / "scripts" / "session.gd"


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def main() -> None:
    game_root = GAME_ROOT.read_text(encoding="utf-8")
    hud = HUD.read_text(encoding="utf-8")
    session = SESSION.read_text(encoding="utf-8")

    # ── NEW-01: pause ────────────────────────────────────────────────────────
    require('_ensure_key_action("pause_game", [KEY_ESCAPE, KEY_P])' in game_root,
            "NEW-01: P/ESC must map to the pause_game action")
    require("func _toggle_pause" in game_root and "func _set_paused" in game_root,
            "NEW-01: pause state machine must exist in game_root")
    process_fn = game_root.split("func _process(", 1)[1].split("\nfunc ", 1)[0]
    require("if game_paused:" in process_fn and "return" in process_fn,
            "NEW-01: _process must hold the whole frame while paused")
    require("spawn_timer.paused = paused" in game_root and "stage_timer.paused = paused" in game_root,
            "NEW-01: timers must hold while paused")
    unhandled_fn = game_root.split("func _unhandled_input(", 1)[1].split("\nfunc ", 1)[0]
    require("if game_paused:" in unhandled_fn and "_set_paused(false)" in unhandled_fn,
            "NEW-01: the resume tap must be swallowed before aiming code")
    require("NOTIFICATION_APPLICATION_FOCUS_OUT" in game_root,
            "NEW-01: focus loss must auto-pause (mobile/web lifeline)")
    require('DisplayServer.get_name() != "headless"' in game_root,
            "NEW-01: headless QA must never auto-pause")
    require("dragging = false" in game_root.split("func _set_paused", 1)[1].split("\nfunc ", 1)[0],
            "NEW-01: pausing must drop any in-flight drag")
    require("signal pause_toggled" in hud and "func set_paused" in hud,
            "NEW-01: HUD needs the pause signal + overlay setter")
    require("hud.pause_toggled.connect(_toggle_pause)" in game_root,
            "NEW-01: HUD pill must drive game_root pause")
    require("MOUSE_FILTER_IGNORE" in hud.split("func _build_pause_overlay", 1)[1].split("\nfunc ", 1)[0],
            "NEW-01: pause overlay must not eat the resume tap")

    # ── NEW-02: mute persistence ─────────────────────────────────────────────
    require("var sound_muted" in session and "func set_sound_muted" in session,
            "NEW-02: Session must own the persisted mute flag")
    require('config.get_value("settings", "sound_muted"' in session
            and 'config.set_value("settings", "sound_muted"' in session,
            "NEW-02: mute must round-trip through the save file")
    require("muted = Session.sound_muted" in hud,
            "NEW-02: HUD must restore the persisted mute on build")
    require("Session.set_sound_muted(muted)" in hud,
            "NEW-02: HUD toggle must persist the new state")

    # ── P1-1: bridge throttle ────────────────────────────────────────────────
    require("BRIDGE_UPDATE_INTERVAL" in game_root and "_bridge_accum" in game_root,
            "P1-1: ambient bridge refresh must be throttled")
    process_after = game_root.split("func _process(", 1)[1]
    require("_bridge_accum += delta" in process_after,
            "P1-1: throttle accumulator must advance in _process")

    # ── P1-2: emit dedupe ────────────────────────────────────────────────────
    emit_fn = game_root.split("func _emit_ui_update", 1)[1].split("\nfunc ", 1)[0]
    require("_last_ui_signature" in emit_fn and "return" in emit_fn,
            "P1-2: identical payloads must be skipped")
    require("_last_ui_signature = []" in game_root,
            "P1-2: signature must reset on a new run")

    # ── P1-3: collision broad-phase ──────────────────────────────────────────
    coll_fn = game_root.split("func _check_block_collision", 1)[1].split("\nfunc ", 1)[0]
    require("GameConstants.BLOCK_WIDTH + knife.radius" in coll_fn
            and "GameConstants.BLOCK_HEIGHT + knife.radius" in coll_fn,
            "P1-3: axis prefilter must run before the AABB/sqrt math")
    require(coll_fn.index("BLOCK_WIDTH + knife.radius") < coll_fn.index("get_local_aabb"),
            "P1-3: prefilter must come before get_local_aabb")

    # ── FL-02: tray-bounce active play ───────────────────────────────────────
    require("func _register_tray_bounce" in game_root,
            "FL-02: tray bounce reward hook must exist")
    require("_register_tray_bounce()" in game_root.split("func _update_knives", 1)[1].split("\nfunc ", 1)[0],
            "FL-02: the bounce path in _update_knives must call the hook")
    bounce_fn = game_root.split("func _register_tray_bounce", 1)[1].split("\nfunc ", 1)[0]
    require("Session.get_combo_window()" in bounce_fn and "hit_combo > 0" in bounce_fn,
            "FL-02: bounce keeps an existing combo alive (never starts one)")
    require("TRAY_JUGGLE_STREAK_TARGET" in bounce_fn and "_juggle_bonus_given" in bounce_fn,
            "FL-02: juggle streak must bank the bonus knife")
    require("tray_bounce_streak = 0" in game_root.split("func _start_shooting", 1)[1].split("\nfunc ", 1)[0],
            "FL-02: streak resets per volley")
    require("_juggle_bonus_given = false" in game_root.split("func _on_stage_timer_timeout", 1)[1].split("\nfunc ", 1)[0],
            "FL-02: juggle bonus re-arms per stage")

    # ── P2-4: dead code ──────────────────────────────────────────────────────
    require("func submit_score" not in session,
            "P2-4: session.submit_score dead code must stay removed")

    print("PASS UX/perf batch hooks (NEW-01/02, P1-1/2/3, FL-02) are implemented")


if __name__ == "__main__":
    main()
