extends Node
# Headless smoke test for coin-revive (game-over continue).
# Run as a scene so autoloads register as compile-time identifiers:
#   godot --headless --audio-driver Dummy --path godot res://tools/test_revive.tscn

const GameConstants = preload("res://scripts/game_constants.gd")

var _failures: Array[String] = []


func _ready() -> void:
	# Defer: the scene tree is mid-setup during _ready, so add_child() fails here.
	_start.call_deferred()


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_failures.append(msg)


func _start() -> void:
	var tree := get_tree()
	var game: Node = load("res://scenes/game.tscn").instantiate()
	tree.root.add_child(game)
	await tree.create_timer(0.2).timeout   # let game._ready → _start_new_run run

	# --- Setup: rich player, force a hearts-out game over on stage 4 ---
	Session.coins = 10000
	var coins_before: int = Session.coins
	game.level = 4
	game.hearts = 0
	game.state = GameConstants.GameState.GAME_OVER

	_check(game._get_revive_cost() == GameConstants.REVIVE_BASE_COST, "1st cost == base")

	# --- Revive #1 ---
	game.revive()
	_check(game.state == GameConstants.GameState.AIMING, "state AIMING after revive")
	_check(game.hearts >= 1, "hearts restored")
	_check(game.knife_count >= GameConstants.REVIVE_KNIVES, "knives topped up")
	_check(Session.coins == coins_before - GameConstants.REVIVE_BASE_COST, "coins spent")
	_check(game.revive_count == 1, "revive_count == 1")

	# --- Cost scales on the 2nd revive ---
	game.state = GameConstants.GameState.GAME_OVER
	_check(game._get_revive_cost() == GameConstants.REVIVE_BASE_COST * 2, "2nd cost scales")

	# --- Revive blocked when broke ---
	Session.coins = 0
	game.state = GameConstants.GameState.GAME_OVER
	game.revive()
	_check(game.state == GameConstants.GameState.GAME_OVER, "blocked when broke")
	_check(game.revive_count == 1, "count unchanged on failed revive")

	# --- Revive is a no-op outside GAME_OVER ---
	Session.coins = 10000
	game.state = GameConstants.GameState.AIMING
	var rc := int(game.revive_count)
	game.revive()
	_check(game.revive_count == rc, "no-op outside GAME_OVER")

	if _failures.is_empty():
		print("REVIVE_TEST: PASS")
	else:
		print("REVIVE_TEST: FAIL")
		for f in _failures:
			printerr("  ✗ ", f)
	tree.quit(0 if _failures.is_empty() else 1)
