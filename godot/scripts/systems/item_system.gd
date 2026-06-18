extends RefCounted
# Item subsystem extracted from game_root.gd (refactor Slice 1).
#
# Owns the active item slots, falling orbs, and the BLAST AoE. game_root drives
# it explicitly from _process()/_draw() so the frame order is unchanged, and it
# holds the only reference, so this object's lifetime matches the run.
#
# Behaviour is identical to the former in-game_root version; only the home moved.
# The BLAST reentrancy guard (blast_in_progress) lives here while _destroy_block
# stays in core, so the guard must short-circuit across the object boundary —
# tools/test_item_system.gd's BLAST case proves it does.

const GameConstants = preload("res://scripts/game_constants.gd")
const Block = preload("res://scripts/block.gd")

var _game  # game_root (untyped to avoid a circular preload)

var slots: Array[int] = []        # ItemType values
var timers: Array[float] = []     # remaining duration per slot
var orbs: Array[Dictionary] = []  # {x, y, vy, type, life, pulse}
var stages_since_drop: int = 0
var blast_in_progress: bool = false


func _init(game) -> void:
	_game = game


func reset() -> void:
	slots.clear()
	timers.clear()
	orbs.clear()
	stages_since_drop = 0
	blast_in_progress = false


func update_timers(delta: float) -> void:
	var changed := false
	for i in range(timers.size() - 1, -1, -1):
		timers[i] -= delta
		if timers[i] <= 0.0:
			slots.remove_at(i)
			timers.remove_at(i)
			changed = true
	if changed:
		_game._emit_ui_update()


func spawn_orb(at: Vector2) -> void:
	var pool: Array[int] = [
		GameConstants.ItemType.PIERCE,
		GameConstants.ItemType.SPREAD,
		GameConstants.ItemType.MAGNET,
		GameConstants.ItemType.BLAST,
		GameConstants.ItemType.SHIELD,
		GameConstants.ItemType.SLOW,
	]
	var item_type: int = pool[randi() % pool.size()]
	orbs.append({
		"x": at.x,
		"y": at.y,
		"vy": GameConstants.ITEM_ORB_SPEED,
		"type": item_type,
		"life": 6.0,
		"pulse": 0.0,
	})
	stages_since_drop = 0


func update_orbs(delta: float) -> void:
	for i in range(orbs.size() - 1, -1, -1):
		var orb: Dictionary = orbs[i]
		orb["y"] = float(orb["y"]) + float(orb["vy"]) * delta
		orb["life"] = float(orb["life"]) - delta
		orb["pulse"] = float(orb["pulse"]) + delta

		# Collect if near paddle
		var ox := float(orb["x"])
		var oy := float(orb["y"])
		var dist_to_paddle := Vector2(ox - _game.paddle_x, oy - _game.paddle_y).length()

		# Magnet effect: if active, pull orbs toward paddle
		if has_active(GameConstants.ItemType.MAGNET):
			var pull_dir := Vector2(_game.paddle_x - ox, _game.paddle_y - oy).normalized()
			orb["x"] = ox + pull_dir.x * 120.0 * delta
			orb["y"] = float(orb["y"]) + pull_dir.y * 120.0 * delta
			dist_to_paddle = Vector2(float(orb["x"]) - _game.paddle_x, float(orb["y"]) - _game.paddle_y).length()

		if dist_to_paddle < 32.0:
			collect(int(orb["type"]))
			_game._vfx.burst_feedback(Vector2(float(orb["x"]), float(orb["y"])),
				GameConstants.ITEM_COLORS.get(int(orb["type"]), Color.WHITE), 16.0, 0.22)
			AudioManager.play("block_destroy_star")
			orbs.remove_at(i)
			continue

		# Remove if off-screen or expired
		if float(orb["y"]) > GameConstants.CANVAS_HEIGHT + 20.0 or float(orb["life"]) <= 0.0:
			orbs.remove_at(i)
			continue

		orbs[i] = orb


func collect(item_type: int) -> void:
	Session.total_items_collected += 1
	if slots.size() < Session.get_item_max_slots():
		slots.append(item_type)
		timers.append(GameConstants.ITEM_DURATION)
	else:
		# Replace oldest slot
		slots[0] = item_type
		timers[0] = GameConstants.ITEM_DURATION
	var item_name: String = GameConstants.ITEM_NAMES.get(item_type, "?")
	_game.hud.show_toast("%s %ds" % [item_name, int(GameConstants.ITEM_DURATION)],
		GameConstants.ITEM_COLORS.get(item_type, Color.WHITE))
	_game._emit_ui_update()


func has_active(item_type: int) -> bool:
	for i in range(slots.size()):
		if slots[i] == item_type and timers[i] > 0.0:
			return true
	return false


func consume(item_type: int) -> void:
	for i in range(slots.size()):
		if slots[i] == item_type:
			slots.remove_at(i)
			timers.remove_at(i)
			_game._emit_ui_update()
			return


func blast_aoe(center: Vector2, radius: float) -> void:
	if blast_in_progress:
		return  # prevent infinite recursion (Blast triggers _destroy_block which triggers Blast)
	blast_in_progress = true
	var hit_any := false
	for container in [_game.blocks_layer, _game.moving_blocks_layer]:
		for child in container.get_children():
			var block := child as Block
			if block == null or block.is_destroyed():
				continue
			if block.global_position.distance_to(center) <= radius:
				# Blast follows the run-scoped damage model, same as direct knife hits.
				block.take_damage(_game._get_knife_damage())
				_game._vfx.burst_feedback(block.global_position, Color(1.0, 0.35, 0.15, 0.7), 10.0, 0.14)
				hit_any = true
				if block.is_destroyed():
					_game._destroy_block(block)
	blast_in_progress = false
	if hit_any:
		_game._vfx.vfx_ring(center, Color(1.0, 0.25, 0.15, 0.65), 0.35)
		AudioManager.play("block_destroy_pow")


func draw_orbs_into(ci: CanvasItem) -> void:
	for orb in orbs:
		var item_type: int = int(orb["type"])
		var color: Color = GameConstants.ITEM_COLORS.get(item_type, Color.WHITE)
		var pos := Vector2(float(orb["x"]), float(orb["y"]))
		var pulse := sin(float(orb["pulse"]) * 8.0) * 0.25 + 1.0
		var r := GameConstants.ITEM_ORB_RADIUS * pulse

		# Outer glow
		var glow_color := Color(color.r, color.g, color.b, 0.25)
		ci.draw_circle(pos, r + 4.0, glow_color)
		# Core
		ci.draw_circle(pos, r, color)
		# Inner highlight
		ci.draw_circle(pos, r * 0.4, Color(1.0, 1.0, 1.0, 0.55))
