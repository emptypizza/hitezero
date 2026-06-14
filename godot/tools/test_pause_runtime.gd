extends SceneTree
# Runtime checks for the NEW-01 soft pause + NEW-02 mute persistence flag.
#
# Run: godot --headless --path godot -s tools/test_pause_runtime.gd

var failures: Array[String] = []


func _initialize() -> void:
	_run()


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS ", message)
	else:
		failures.append(message)
		printerr("FAIL ", message)


func _run() -> void:
	var scene: PackedScene = load("res://scenes/game.tscn")
	var game: Node = scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame

	var hud: CanvasLayer = game.hud

	# ── NEW-01: pause state machine ──────────────────────────────────────────
	_check(game.game_paused == false, "run starts unpaused")
	_check(hud.pause_button != null, "HUD builds the pause pill")
	_check(hud.pause_root != null and not hud.pause_root.visible,
		"pause overlay exists and starts hidden")

	game._set_paused(true)
	_check(game.game_paused == true, "_set_paused(true) pauses live play")
	_check(game.spawn_timer.paused == true, "spawn timer holds while paused")
	_check(game.stage_timer.paused == true, "stage timer holds while paused")
	_check(hud.pause_root.visible == true, "pause overlay shows while paused")

	# Score/sim hold: stepping coin shards is process-driven, but the cheap
	# proxy here is that a resume restores every flag symmetrically.
	game._set_paused(false)
	_check(game.game_paused == false, "resume clears the pause flag")
	_check(game.spawn_timer.paused == false, "resume releases the spawn timer")
	_check(hud.pause_root.visible == false, "resume hides the overlay")

	# Headless guard: focus-out must NOT auto-pause here.
	game._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_check(game.game_paused == false, "headless focus-out does not auto-pause")

	# Pause refuses non-live states (e.g. STAGE_CLEAR).
	game.state = GameConstants_state_stage_clear()
	game._set_paused(true)
	_check(game.game_paused == false, "STAGE_CLEAR refuses to pause")
	game.state = 0  # back to AIMING enum head for cleanliness

	# ── NEW-02: persisted mute flag round-trip (in-memory) ──────────────────
	# Autoloads aren't compile-time identifiers in SceneTree test scripts;
	# resolve at runtime like the game tree does.
	var session: Node = root.get_node("/root/Session")
	var before: bool = session.sound_muted
	session.set_sound_muted(true)
	_check(session.sound_muted == true, "Session stores the mute flag")
	session.set_sound_muted(before)
	_check(session.sound_muted == before, "mute flag restored after test")

	if failures.is_empty():
		print("ALL PAUSE/MUTE RUNTIME CHECKS PASSED")
		quit(0)
	else:
		quit(1)


func GameConstants_state_stage_clear() -> int:
	var gc := load("res://scripts/game_constants.gd")
	return gc.GameState.STAGE_CLEAR
