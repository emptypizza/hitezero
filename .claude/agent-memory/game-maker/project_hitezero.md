---
name: HiteZero project setup
description: Godot 4 2D action game prototype -- wave survival, GDScript, GL Compatibility renderer, 1280x720 viewport
type: project
---

HiteZero is a Godot 4.2+ 2D action game where the player survives waves of enemies, graded on hits taken (zero hits = perfect).

**Why:** Initial prototype built from scratch in an empty repo. Uses GDScript with GL Compatibility renderer for broad hardware support.

**How to apply:** All scenes live in `scenes/`, scripts in `scripts/`, assets in `assets/`. The game uses Polygon2D nodes for all visuals (no external sprites), so it runs without any imported art assets. Physics layers: 1=player, 2=enemies, 3=player_attack. Main scene entry point is `main_menu.tscn`.
