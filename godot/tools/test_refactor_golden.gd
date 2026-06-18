extends SceneTree
# Golden-trace capture harness for the game_root.gd refactor (Slice 0 safety net).
#
# Drives game.tscn deterministically (fixed global seed + fixed level-gen seed +
# fixed-fps delta) and writes a per-frame snapshot of the runtime state payload
# (game_root.get_state_payload()) to a JSON file.
#
#   • Determinism gate: run twice with the same args -> byte-identical files.
#   • Behavior-neutral proof: capture before a refactor slice, capture after,
#     diff the two files -> must be empty.
#
# Run:
#   godot --headless --fixed-fps 60 --path godot \
#     -s tools/test_refactor_golden.gd -- --out=/tmp/trace.json
#
# Requires --fixed-fps so _process(delta) gets a constant delta (otherwise the
# headless main loop uses wall-clock delta and combo/coin/knife accumulation
# diverges run to run).

const FIXED_SEED := 1337
const FRAMES_PER_VOLLEY := 160


func _initialize() -> void:
	_run()


func _arg_value(key: String, fallback: String) -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with(key + "="):
			return a.substr(key.length() + 1)
	return fallback


func _state_aiming() -> int:
	return (load("res://scripts/game_constants.gd")).GameState.AIMING


func _run() -> void:
	var out_path := _arg_value("--out", "user://refactor_trace.json")

	seed(FIXED_SEED)
	var level_gen := load("res://scripts/level_generator.gd")
	level_gen._forced_seed = FIXED_SEED

	var scene: PackedScene = load("res://scenes/game.tscn")
	var game: Node = scene.instantiate()
	root.add_child(game)

	# Let _ready() + the first level layout settle before scripting input.
	await process_frame
	await process_frame

	var trace: Array = []

	# Volley 1: aim up from screen centre, fire, watch the knives play out.
	game._handle_pointer_down(Vector2(200.0, 300.0))
	game._handle_pointer_up()
	for _i in range(FRAMES_PER_VOLLEY):
		trace.append(game.get_state_payload())
		await process_frame

	# Volley 2: re-aim if the run handed control back to AIMING (covers the
	# SHOOTING -> AIMING re-entry path); otherwise just keep observing.
	if int(game.state) == _state_aiming():
		game._handle_pointer_down(Vector2(150.0, 260.0))
		game._handle_pointer_up()
	for _i in range(FRAMES_PER_VOLLEY):
		trace.append(game.get_state_payload())
		await process_frame

	var f := FileAccess.open(out_path, FileAccess.WRITE)
	if f == null:
		printerr("FAIL cannot open ", out_path)
		quit(1)
		return
	f.store_string(JSON.stringify(trace, "  "))
	f.close()
	print("WROTE ", trace.size(), " frames -> ", out_path)
	quit(0)
