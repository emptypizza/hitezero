extends SceneTree
# Headless integration checks for the duckflock-reference systems:
# kill-chain coin shards, toast timing, objective pill, x2 speed, run-scoped
# level-up modifiers and the group-kill bonus.
#
# Run: godot --headless -s tools/test_duckflock_systems.gd  (from godot/)

const GameConstants = preload("res://scripts/game_constants.gd")

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

	# ── Objective pill (G2.1) ────────────────────────────────────────────────
	_check(game.stars_total > 0, "stage seeds stars_total > 0 (got %d)" % game.stars_total)
	_check(hud.pill_label != null and hud.pill_label.text == "0/%d" % game.stars_total,
		"objective pill shows 0/%d at stage start (got '%s')" % [game.stars_total, hud.pill_label.text])

	# ── Kill chain: coin shards scatter then magnet-collect (G1.2) ──────────
	var first_block: Node = null
	for child in game.blocks_layer.get_children():
		first_block = child
		break
	_check(first_block != null, "stage has at least one block to destroy")
	if first_block != null:
		first_block.hp = 1
		game._destroy_block(first_block)
	_check(game.coin_shards.size() >= GameConstants.COIN_SHARDS_MIN,
		"destroy spawns >= %d coin shards (got %d)" % [GameConstants.COIN_SHARDS_MIN, game.coin_shards.size()])
	for i in range(80):  # 8 simulated seconds in 0.1 s steps — far past lifetime cap
		game._update_coin_shards(0.1)
	_check(game.coin_shards.is_empty(), "coin shards all collected/expired after magnet phase")

	# ── Toast slide-in inside TOAST_IN_TIME (G1.3) ──────────────────────────
	hud.show_toast("TEST TOAST", Color.WHITE)
	_check(hud._toasts.size() >= 1, "toast registers in the stack")
	var toast: Control = hud._toasts[0]
	var start_x: float = toast.position.x
	await create_timer(GameConstants.TOAST_IN_TIME + 0.10).timeout
	var target_x := GameConstants.CANVAS_WIDTH - 158.0 - 8.0
	_check(is_instance_valid(toast) and absf(toast.position.x - target_x) <= 6.0,
		"toast lands at anchor within TOAST_IN_TIME (+margin) — started %.0f, now %.0f" % [start_x, toast.position.x if is_instance_valid(toast) else -1.0])

	# ── x2 speed toggle (G2.2) ──────────────────────────────────────────────
	game._set_game_speed(true)
	_check(game.game_speed == GameConstants.GAME_SPEED_FAST, "game_speed flips to x2")
	_check(absf(game.spawn_timer.wait_time - GameConstants.SPAWN_INTERVAL / 2.0) < 0.0001,
		"spawn cadence follows the x2 sim clock")
	game._set_game_speed(false)
	_check(game.game_speed == 1.0, "game_speed restores to x1")

	# ── Run-scoped damage model (G3.1) ──────────────────────────────────────
	_check(game._get_knife_damage() == 1, "base knife damage is 1")
	game.run_damage_bonus = 1
	_check(game._get_knife_damage() == 2, "level-up DAMAGE pick raises damage to 2")
	game._grant_run_buff(GameConstants.RUN_BUFF_DOUBLE_DAMAGE, 18.0)
	_check(game._get_knife_damage() == 4, "2x buff doubles total damage (2 -> 4)")
	game._update_run_buffs(19.0)
	_check(game._get_knife_damage() == 2, "2x buff expires after its duration")
	_check(not game._pierce_active(), "pierce inactive by default")
	game._grant_run_buff(GameConstants.RUN_BUFF_PIERCE, 12.0)
	_check(game._pierce_active(), "pierce run-buff activates pierce")
	game.run_buffs.clear()
	game.run_damage_bonus = 0

	# ── Blast AoE follows the run damage model (G3.1) ───────────────────────
	game.run_damage_bonus = 2  # knife damage becomes 3
	var blast_block: Block = null
	for child in game.blocks_layer.get_children():
		var b := child as Block
		if b != null and not b.is_destroyed():
			blast_block = b
			break
	_check(blast_block != null, "stage has a live block for the blast check")
	if blast_block != null:
		blast_block.hp = 10
		game._blast_aoe(blast_block.global_position, 1.0)
		_check(blast_block.hp == 10 - game._get_knife_damage(),
			"blast applies run-modified knife damage (hp 10 -> %d)" % blast_block.hp)
	game.run_damage_bonus = 0

	# ── Level-up open / instant resume (G3.1) ───────────────────────────────
	game._open_levelup()
	_check(game.levelup_open, "level-up flag set on open")
	_check(hud.levelup_root.visible, "level-up overlay visible")
	_check(hud.levelup_cards_box.get_child_count() == GameConstants.LEVELUP_CHOICE_COUNT,
		"level-up shows exactly %d cards" % GameConstants.LEVELUP_CHOICE_COUNT)
	game._on_levelup_chosen("knife")
	var knives_after: int = game.knife_count
	_check(not game.levelup_open, "level-up flag clears on choice")
	_check(not hud.levelup_root.visible, "level-up overlay hides on the same frame")
	_check(knives_after >= 4, "KNIFE +1 pick applied (knife_count %d)" % knives_after)

	# ── Group-kill bonus (G3.2) ─────────────────────────────────────────────
	game._burst_destroy_count = 0
	game._burst_destroy_timer = 0.0
	for i in range(GameConstants.GROUP_KILL_MIN):
		game._register_burst_destroy()
	game._update_group_kill(GameConstants.GROUP_KILL_WINDOW + 0.1)
	_check(game.group_dmg_bonus == GameConstants.GROUP_KILL_DMG_BONUS,
		"group kill window awards ATK stack (got %d)" % game.group_dmg_bonus)
	_check(game._get_knife_damage() == 1 + GameConstants.GROUP_KILL_DMG_BONUS,
		"group stack feeds the damage model")
	# Below-threshold burst must not award.
	game._register_burst_destroy()
	game._update_group_kill(GameConstants.GROUP_KILL_WINDOW + 0.1)
	_check(game.group_dmg_bonus == GameConstants.GROUP_KILL_DMG_BONUS,
		"sub-threshold burst does not award a stack")
	# The award must emit ui_updated so the ATK chip refreshes immediately.
	_check(hud._prev_group_bonus == game.group_dmg_bonus,
		"group-kill award reaches the HUD chip on the same tick")

	# ── Ambience (G1.4) ─────────────────────────────────────────────────────
	for i in range(40):
		game._update_fireflies(0.1)
	_check(game.firefly_particles.size() > 0, "fireflies populate the night stage")

	# Tear the scene down before quitting so tweens/timers don't leak at exit.
	root.remove_child(game)
	game.free()
	await process_frame

	if failures.is_empty():
		print("ALL DUCKFLOCK SYSTEM CHECKS PASSED")
		quit(0)
	else:
		printerr("%d CHECK(S) FAILED" % failures.size())
		quit(1)
