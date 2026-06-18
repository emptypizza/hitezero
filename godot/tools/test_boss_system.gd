extends SceneTree
# Targeted behavioral test for the boss subsystem (Slice 2-B safety net).
#
# The golden trace tops out at stage 1 and never spawns a boss (bosses appear at
# level 5), so this is the REAL net for the BossSystem extraction — it pins
# spawn, body-hit collision routing, minion spawn, the defeat reward path, and
# cleanup deterministically by driving the methods directly.
#
# Passes against pre-extraction game_root.gd; must keep passing after Slice 2.
#
# Run: godot --headless --path godot -s tools/test_boss_system.gd

var failures: Array[String] = []
var gc = load("res://scripts/game_constants.gd")


func _initialize() -> void:
	_run()


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS ", message)
	else:
		failures.append(message)
		printerr("FAIL ", message)


func _run() -> void:
	var game: Node = load("res://scenes/game.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	var session: Node = root.get_node("/root/Session")

	# ── Non-boss level spawns no boss ────────────────────────────────────────
	game.level = 3
	game._boss.cleanup()
	game._boss.init_if_needed()
	_check(game._boss.current == null and not game._boss.is_stage,
		"non-boss level (3) spawns no boss")

	# ── Boss spawns at level 5 ───────────────────────────────────────────────
	game.level = 5
	game._boss.init_if_needed()
	_check(game._boss.current != null, "boss spawns at level 5")
	_check(game._boss.is_stage, "is_boss_stage set on a boss level")
	_check(game._boss.current.hp > 0 and game._boss.current.max_hp > 0, "boss has hp")
	_check(game._boss.warning_timer == gc.BOSS_WARNING_DURATION, "boss warning timer armed")

	# ── Cleanup frees the boss ───────────────────────────────────────────────
	game._boss.cleanup()
	_check(game._boss.current == null and not game._boss.is_stage, "cleanup clears the boss")

	# ── Re-spawn for the combat checks ───────────────────────────────────────
	game.level = 5
	game._boss.init_if_needed()
	_check(game._boss.current != null, "boss re-spawns for combat checks")

	# ── Body-hit collision routes damage + combo + score ─────────────────────
	var hp_before: int = game._boss.current.hp
	var score_before: int = game.score
	game.hit_combo = 0
	var knife = load("res://scenes/knife.tscn").instantiate()
	game.knives_layer.add_child(knife)
	knife.configure(game._boss.current.position, Vector2(0.0, -300.0))
	game._boss.check_collision(knife)
	_check(game._boss.current.hp < hp_before, "body hit reduces boss hp")
	_check(game.hit_combo > 0, "boss hit registers a combo")
	_check(game.score > score_before, "boss hit awards score")

	# ── Minion spawn adds a red enemy to the moving layer ────────────────────
	var moving_before: int = game.moving_blocks_layer.get_child_count()
	game._boss.on_minion_spawn(Vector2(200.0, 120.0), 3)
	_check(game.moving_blocks_layer.get_child_count() == moving_before + 1,
		"minion spawn adds a moving block")

	# ── Defeat → reward path ─────────────────────────────────────────────────
	var guard := 0
	while not game._boss.current.is_defeated() and guard < 2000:
		game._boss.current.take_hit(game._boss.current.position)
		guard += 1
	_check(game._boss.current.is_defeated(), "boss reaches defeated state via take_hit")

	var k_before: int = game.knife_count
	var s_before: int = game.score
	var coins_before: int = session.coins
	var bd_before: int = session.total_bosses_defeated
	game._boss.trigger_defeated()
	_check(game.state == gc.GameState.STAGE_CLEAR, "boss defeat sets STAGE_CLEAR")
	_check(game.knife_count == k_before + gc.BOSS_DEFEAT_KNIFE_BONUS,
		"boss defeat awards +%d knives" % gc.BOSS_DEFEAT_KNIFE_BONUS)
	_check(game.score == s_before + 1000 * gc.BOSS_DEFEAT_SCORE_MULT,
		"boss defeat awards +%d score" % (1000 * gc.BOSS_DEFEAT_SCORE_MULT))
	_check(session.coins == coins_before + 500, "boss defeat awards 500 coins")
	_check(session.total_bosses_defeated == bd_before + 1, "boss defeat increments the stat")
	_check(game.hearts == session.get_max_hearts(), "boss defeat full-heals")

	if failures.is_empty():
		print("ALL BOSS SYSTEM CHECKS PASSED")
		quit(0)
	else:
		printerr(failures.size(), " CHECK(S) FAILED")
		quit(1)
