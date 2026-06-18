#!/usr/bin/env python3
"""Static guards for the v1.1 rewarded-revive integration.

No Godot runtime needed — these assert source invariants that keep the v1.0
build clean and prove the ads code is wired but inert. Run:

    python3 godot/tools/test_ads_integration.py

Exits non-zero on any failure. Mirrors the repo's other test_*.py style.
"""
import os
import re
import sys

GODOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

def read(rel):
    with open(os.path.join(GODOT, rel), encoding="utf-8") as f:
        return f.read()

def exists(rel):
    return os.path.exists(os.path.join(GODOT, rel))

def code_only(text):
    # Strip GDScript comments (# ... and ## docstrings) so prose that mentions
    # the addon by name doesn't count as a compile-time symbol reference.
    out = []
    for line in text.splitlines():
        h = line.find("#")
        out.append(line if h < 0 else line[:h])
    return "\n".join(out)

checks = []
def check(name, ok, detail=""):
    checks.append((name, ok, detail))

# AdMob/addon symbols that must NOT appear in always-compiled scripts, or the
# project would fail to parse when the addon is absent (the v1.0 state).
ADDON_SYMS = ["Admob", "LoadAdRequest", "load_rewarded_ad", "show_rewarded_ad",
              "rewarded_ad_loaded", "initialization_completed"]

# 1) ads_manager.gd: master switch defaults OFF, and zero addon symbols in code.
am = read("scripts/ads_manager.gd")
check("ads_manager: ADS_ENABLED defaults false",
      re.search(r"const\s+ADS_ENABLED\s*:=\s*false", am) is not None)
leaked = [s for s in ADDON_SYMS if s in code_only(am)]
check("ads_manager: no addon symbols in code (compiles without addon)", not leaked, str(leaked))

# 2) revive_prompt.gd: present, also free of addon symbols in code.
rp = read("scripts/revive_prompt.gd")
leaked_rp = [s for s in ADDON_SYMS if s in code_only(rp)]
check("revive_prompt: no addon symbols in code", not leaked_rp, str(leaked_rp))

# 3) game_root.gd: original game-over commit preserved + revive gated.
gr = read("scripts/game_root.gd")
check("game_root: _commit_game_over keeps original loss commit",
      "func _commit_game_over" in gr
      and "Session.submit_run(score, level, combo_best)" in gr
      and "Session.add_coins(100 * level)" in gr)
check("game_root: revive gated by AdsManager + once-per-run",
      "AdsManager.is_revive_available()" in gr
      and "_revive_used_this_run" in gr)
check("game_root: per-run flag reset in _start_new_run",
      re.search(r"_revive_used_this_run\s*=\s*false", gr) is not None)

# 4) project.godot: AdsManager autoload registered.
pg = read("project.godot")
check("project.godot: AdsManager autoload registered",
      'AdsManager="*res://scripts/ads_manager.gd"' in pg)

# 5) export_presets.cfg: v1.0 submission profile UNTOUCHED (clean).
ep = read("export_presets.cfg")
check("export_presets: no INTERNET permission", "INTERNET" not in ep.upper())
check("export_presets: custom_permissions still empty",
      "permissions/custom_permissions=PackedStringArray()" in ep)
check("export_presets: version still 1 / 1.0.0",
      "version/code=1" in ep and 'version/name="1.0.0"' in ep)

# 6) addon-touching backend stays inert (.txt, not compiled).
check("ads_backend shipped as inert .txt template", exists("scripts/ads_backend.gd.txt"))
check("ads_backend.gd NOT active (would break clean v1.0)", not exists("scripts/ads_backend.gd"))

failed = 0
for name, ok, detail in checks:
    print(f"  [{'PASS' if ok else 'FAIL'}] {name}" + (f"  -> {detail}" if (detail and not ok) else ""))
    if not ok:
        failed += 1

print(f"\n{len(checks) - failed}/{len(checks)} checks passed.")
sys.exit(1 if failed else 0)
