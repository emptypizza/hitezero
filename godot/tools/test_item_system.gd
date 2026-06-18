extends SceneTree
# Targeted behavioral test for the item subsystem (Slice 0-B safety net).
#
# The golden trace does NOT exercise items (drops are RNG and never fire in the
# short scripted run), so this test pins item behavior deterministically by
# driving the ItemSystem directly — the same pattern test_pause_runtime.gd uses.
#
# It passed against the pre-extraction game_root.gd and must keep passing after
# the ItemSystem extraction (Slice 1), proving the move was behavior-neutral. The
# BLAST case is the load-bearing one: the guard moved to ItemSystem while
# _destroy_block stayed in core, so it must short-circuit across the object
# boundary, and the golden trace can never reach it.
#
# Run: godot --headless --path godot -s tools/test_item_system.gd

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


func _make_block(game: Node, x: float, y: float, hp: int) -> Object:
	var scene: PackedScene = load("res://scenes/block.tscn")
	var block = scene.instantiate()
	block.position = Vector2(x, y)
	game.blocks_layer.add_child(block)
	block.configure(gc.BLOCK_NORMAL, hp, hp, Vector2(gc.BLOCK_WIDTH - 4.0, gc.BLOCK_HEIGHT - 4.0))
	return block


func _run() -> void:
	var scene: PackedScene = load("res://scenes/game.tscn")
	var game: Node = scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame

	var items = game._items
	var session: Node = root.get_node("/root/Session")

	# ── Collect + active-state query ─────────────────────────────────────────
	items.slots.clear()
	items.timers.clear()
	_check(not items.has_active(gc.ItemType.PIERCE), "fresh state has no active PIERCE")

	items.collect(gc.ItemType.PIERCE)
	_check(items.has_active(gc.ItemType.PIERCE), "collect adds an active PIERCE")
	_check(items.slots.size() == 1, "collect fills exactly one slot")

	# ── Duration expiry ──────────────────────────────────────────────────────
	items.update_timers(gc.ITEM_DURATION + 0.5)
	_check(not items.has_active(gc.ItemType.PIERCE), "PIERCE expires after its duration")
	_check(items.slots.is_empty(), "expired item frees its slot")

	# ── Slot capacity + replace-oldest ───────────────────────────────────────
	items.slots.clear()
	items.timers.clear()
	var cap: int = session.get_item_max_slots()
	var fill_types := [gc.ItemType.PIERCE, gc.ItemType.SPREAD, gc.ItemType.MAGNET,
		gc.ItemType.BLAST, gc.ItemType.SHIELD]
	for i in range(cap):
		items.collect(fill_types[i])
	_check(items.slots.size() == cap, "slots fill to capacity (%d)" % cap)
	var oldest_before: int = items.slots[0]
	items.collect(gc.ItemType.SLOW)
	_check(items.slots.size() == cap, "collecting past capacity does not grow slots")
	_check(items.slots[0] == gc.ItemType.SLOW and oldest_before != gc.ItemType.SLOW,
		"oldest slot is replaced when full")

	# ── consume ──────────────────────────────────────────────────────────────
	items.slots.clear()
	items.timers.clear()
	items.collect(gc.ItemType.SLOW)
	items.consume(gc.ItemType.SLOW)
	_check(not items.has_active(gc.ItemType.SLOW), "consume removes the active item")

	# ── Orb collect pipeline (the per-frame update path) ─────────────────────
	items.slots.clear()
	items.timers.clear()
	items.orbs.clear()
	items.orbs.append({
		"x": game.paddle_x, "y": game.paddle_y - 8.0, "vy": 0.0,
		"type": gc.ItemType.MAGNET, "life": 6.0, "pulse": 0.0,
	})
	items.update_orbs(0.016)
	_check(items.orbs.is_empty(), "orb within range is collected and removed")
	_check(items.has_active(gc.ItemType.MAGNET), "collected orb grants its item")

	# ── Orb off-screen expiry (no collect) ───────────────────────────────────
	items.orbs.clear()
	items.orbs.append({
		"x": 10.0, "y": gc.CANVAS_HEIGHT + 50.0, "vy": 0.0,
		"type": gc.ItemType.PIERCE, "life": 6.0, "pulse": 0.0,
	})
	items.update_orbs(0.016)
	_check(items.orbs.is_empty(), "off-screen orb is dropped without collecting")

	# ── spawn_orb populates an orb from the drop pool (RNG path) ─────────────
	items.orbs.clear()
	seed(20260617)
	items.stages_since_drop = 3
	items.spawn_orb(Vector2(200.0, 100.0))
	_check(items.orbs.size() == 1, "spawn_orb adds one orb")
	_check(float(items.orbs[0]["vy"]) == gc.ITEM_ORB_SPEED, "spawned orb falls at ITEM_ORB_SPEED")
	_check(items.stages_since_drop == 0, "spawn_orb resets the pity counter")

	# ── MAGNET pulls an out-of-range orb toward the paddle (magnet branch) ───
	items.slots.clear()
	items.timers.clear()
	items.orbs.clear()
	items.collect(gc.ItemType.MAGNET)
	items.orbs.append({
		"x": game.paddle_x + 100.0, "y": game.paddle_y, "vy": 0.0,
		"type": gc.ItemType.PIERCE, "life": 6.0, "pulse": 0.0,
	})
	items.update_orbs(0.05)
	_check(not items.orbs.is_empty() and float(items.orbs[0]["x"]) < game.paddle_x + 100.0,
		"MAGNET pulls an out-of-range orb toward the paddle")

	# ── BLAST: AoE + reentrancy guard across the object boundary ─────────────
	game.clear_level_nodes()
	items.slots.clear()
	items.timers.clear()
	game.run_damage_bonus = 0
	game.group_dmg_bonus = 0
	var left = _make_block(game, 180.0, 200.0, 1)
	var mid = _make_block(game, 200.0, 200.0, 1)
	var right = _make_block(game, 220.0, 200.0, 1)
	items.collect(gc.ItemType.BLAST)
	# Mirror the real flow: the knife reduces the struck block to 0 hp before
	# _destroy_block runs, so the blast loop skips it and only the neighbours cascade.
	mid.take_damage(1)
	game._destroy_block(mid)
	_check(left.is_destroyed() and right.is_destroyed(),
		"BLAST AoE destroys neighbours within radius")
	_check(items.blast_in_progress == false,
		"BLAST reentrancy guard resets after the cascade (no infinite recursion)")

	if failures.is_empty():
		print("ALL ITEM SYSTEM CHECKS PASSED")
		quit(0)
	else:
		printerr(failures.size(), " CHECK(S) FAILED")
		quit(1)
