extends RefCounted
# Boss subsystem extracted from game_root.gd (refactor Slice 2).
#
# Owns the boss lifecycle (spawn/cleanup), the per-knife boss collision routing,
# the minion spawn + phase/defeat handlers, and the defeat reward + cinematic.
# game_root drives it explicitly (_process updates the boss and emits HP; _draw
# and _check_win_lose read `current`) and holds the only reference.
#
# Highest-coupling cut in the refactor: check_collision and trigger_defeated reach
# back into combo/score/vfx/hitstop/shake via _game. The HUD-facing signals stay
# on game_root; this object emits them through _game. Behaviour is identical to
# the former in-game_root version — tools/test_boss_system.gd is the safety net
# (the golden trace never reaches a boss).

const GameConstants = preload("res://scripts/game_constants.gd")
const Block = preload("res://scripts/block.gd")
const LevelGen = preload("res://scripts/level_generator.gd")
const BlockScene = preload("res://scenes/block.tscn")
const Knife = preload("res://scripts/knife.gd")

var _game  # game_root (untyped to avoid a circular preload)

var current: Boss = null
var is_stage: bool = false
var warning_timer: float = 0.0


func _init(game) -> void:
	_game = game


func init_if_needed() -> void:
	is_stage = LevelGen.is_boss_stage(_game.level)
	if not is_stage:
		return

	var boss_type := LevelGen.get_boss_type(_game.level)
	current = Boss.new()
	current.position = Vector2(GameConstants.CANVAS_WIDTH * 0.5, 160.0)
	current.z_index = 5
	_game.world.add_child(current)
	current.configure(boss_type, _game.level)
	current.defeated.connect(on_defeated)
	current.phase_changed.connect(on_phase_changed)
	current.minion_spawn_requested.connect(on_minion_spawn)

	# Show warning sequence
	warning_timer = GameConstants.BOSS_WARNING_DURATION
	_game.boss_started.emit(current.boss_name, current.boss_color)
	_game._flash_screen(Color(1.0, 0.15, 0.15, 1.0), 0.35, 0.3)
	AudioManager.play("enemy_warning")


func cleanup() -> void:
	if current != null:
		if is_instance_valid(current):
			current.queue_free()
		current = null
	is_stage = false


func check_collision(knife: Knife) -> void:
	if not knife.active or current == null or current.is_defeated():
		return

	# Check mirror blocks first (Mirror boss)
	if current.boss_type == GameConstants.BossType.MIRROR:
		for mb in current._mirror_blocks:
			if int(mb["hp"]) <= 0:
				continue
			var mpos := Vector2(float(mb["x"]), float(mb["y"]))
			if knife.position.distance_to(mpos) <= knife.radius + 18.0:
				current.hit_mirror_block(knife.position)
				_game._register_combo_hit()
				_game._vfx.burst_feedback(mpos, Color(0.6, 0.8, 1.0, 0.9), 14.0, 0.18)
				_game._vfx.spawn_hit_vfx(mpos, Color(0.6, 0.8, 1.0))
				AudioManager.play("block_hit", _game._combo_pitch())
				# Bounce knife
				var normal := (knife.position - mpos).normalized()
				knife.position += normal * 4.0
				var vel := knife.velocity
				if absf(normal.x) > absf(normal.y):
					vel.x = -vel.x
				else:
					vel.y = -vel.y
				knife.set_velocity(vel)
				return

	# Check spawner shield (must break shield before core takes damage)
	if current.boss_type == GameConstants.BossType.SPAWNER and current.is_shielded():
		var body_rect := current.get_body_rect()
		var shield_r := maxf(body_rect.size.x, body_rect.size.y) * 0.5 + 10.0
		if knife.position.distance_to(current.position) <= knife.radius + shield_r:
			current.take_spawner_shield_hit()
			_game._register_combo_hit()
			_game._vfx.burst_feedback(knife.position, Color(1.0, 0.4, 0.3, 0.8), 12.0, 0.14)
			AudioManager.play("block_hit", _game._combo_pitch())
			# Bounce
			var normal := (knife.position - current.position).normalized()
			if normal.length_squared() < 0.001:
				normal = Vector2(0.0, -1.0)
			knife.position += normal * 4.0
			var vel := knife.velocity
			if absf(normal.x) > absf(normal.y):
				vel.x = -vel.x
			else:
				vel.y = -vel.y
			knife.set_velocity(vel)
			_game._emit_ui_update()
			return

	# Check splitter segments
	if current.boss_type == GameConstants.BossType.SPLITTER:
		if current.hit_split_segment(knife.position):
			_game._register_combo_hit()
			_game._vfx.burst_feedback(knife.position, Color(0.85, 0.6, 0.2, 0.9), 12.0, 0.16)
			_game._vfx.spawn_hit_vfx(knife.position, Color(0.85, 0.55, 0.15))
			AudioManager.play("block_hit", _game._combo_pitch())
			_game.score += int(15.0 * _game._get_combo_multiplier())
			if not _game._pierce_active():
				var normal := (knife.position - current.position).normalized()
				if normal.length_squared() < 0.001:
					normal = Vector2(0.0, -1.0)
				knife.position += normal * 3.0
				var vel := knife.velocity
				vel.y = -vel.y
				knife.set_velocity(vel)
			_game._emit_ui_update()
			return

	# Check main body
	var body_rect := current.get_body_rect()
	var test_x := clampf(knife.position.x, body_rect.position.x, body_rect.position.x + body_rect.size.x)
	var test_y := clampf(knife.position.y, body_rect.position.y, body_rect.position.y + body_rect.size.y)
	var dist := knife.position.distance_to(Vector2(test_x, test_y))

	if dist <= knife.radius:
		var remaining := current.take_hit(knife.position)
		_game._register_combo_hit()
		_game._vfx.burst_feedback(knife.position, current.boss_color, 14.0, 0.18)
		_game._vfx.spawn_hit_vfx(knife.position, current.boss_color)
		AudioManager.play("block_hit", _game._combo_pitch())
		Haptics.light()

		# Score with combo
		var multiplier: float = _game._get_combo_multiplier()
		_game.score += int(20.0 * multiplier)
		if multiplier > 1.0:
			_game._spawn_combo_text(knife.position, multiplier)
		_game._emit_ui_update()

		# Bounce knife (unless pierce)
		if not _game._pierce_active():
			var normal := (knife.position - current.position).normalized()
			if normal.length_squared() < 0.001:
				normal = Vector2(0.0, -1.0)
			knife.position += normal * 4.0
			var vel := knife.velocity
			if absf(normal.x) > absf(normal.y):
				vel.x = -vel.x
			else:
				vel.y = -vel.y
			knife.set_velocity(vel)

		# Spread effect
		if _game._items.has_active(GameConstants.ItemType.SPREAD):
			var base_angle := knife.velocity.angle()
			_game._spawn_mini_knife(knife.position, base_angle + 0.6)
			_game._spawn_mini_knife(knife.position, base_angle - 0.6)


func on_defeated() -> void:
	pass  # Handled by trigger_defeated in _check_win_lose


func on_phase_changed(new_phase: int) -> void:
	_game._freeze_frame(0.2)
	_game._flash_screen(Color(1.0, 1.0, 1.0, 1.0), 0.5, 0.15)
	_game.boss_phase_changed.emit(new_phase)
	AudioManager.play("enemy_warning")


func on_minion_spawn(pos: Vector2, minion_hp: int) -> void:
	var block_size := Vector2(GameConstants.BLOCK_WIDTH - 4.0, GameConstants.BLOCK_HEIGHT - 4.0)
	var minion: Block = BlockScene.instantiate()
	minion.position = pos
	_game.moving_blocks_layer.add_child(minion)
	minion.configure(GameConstants.BLOCK_RED_ENEMY, minion_hp, minion_hp, block_size)
	minion.activate_enemy_motion()


func trigger_defeated() -> void:
	if _game.state == GameConstants.GameState.STAGE_CLEAR:
		return
	if _game._burst_destroy_timer > 0.0:
		_game._update_group_kill(_game._burst_destroy_timer + 0.001)
	_game.state = GameConstants.GameState.STAGE_CLEAR
	_game._clear_all_knives()
	if not _game.spawn_timer.is_stopped():
		_game.spawn_timer.stop()
	_game.player.scale = Vector2.ONE
	_game.hit_combo = 0
	_game.combo_timer = 0.0
	_game._items.orbs.clear()

	# Boss rewards
	_game.knife_count += GameConstants.BOSS_DEFEAT_KNIFE_BONUS
	_game.hearts = Session.get_max_hearts()  # Full heal
	_game.score += 1000 * GameConstants.BOSS_DEFEAT_SCORE_MULT
	Session.total_bosses_defeated += 1
	Session.add_coins(500)

	_game._flash_screen(Color(1.0, 1.0, 1.0, 1.0), 0.85, 0.35)
	_game._freeze_frame(GameConstants.BOSS_DEFEAT_FREEZE)
	_game._add_trauma(0.6)
	_game._camera_punch(_game.ZOOM_KICK_MAX)
	Haptics.heavy()
	AudioManager.play("stage_clear")
	_game.boss_defeated_signal.emit()
	_game.hud.show_toast("BOSS DOWN! +%d KNIVES" % GameConstants.BOSS_DEFEAT_KNIFE_BONUS, GameConstants.GLOW_REWARD)
	_game._emit_ui_update()
	run_defeat_sequence()


func run_defeat_sequence() -> void:
	await _game.get_tree().create_timer(0.5, true, false, true).timeout

	# Boss explosion VFX
	if current != null and is_instance_valid(current):
		var bpos := current.position
		for i in range(8):
			var offset := Vector2(randf_range(-50.0, 50.0), randf_range(-40.0, 40.0))
			_game._vfx.vfx_ring(bpos + offset, current.boss_color, 0.4)
			_game._vfx.vfx_sparks(bpos + offset, 8, current.boss_color,
				current.boss_color.lerp(Color.WHITE, 0.5), 80.0, 180.0, 0.4)
			_game._vfx.burst_feedback(bpos + offset, current.boss_color, 16.0, 0.22)
			# VX-03: boss explosions froth with big cyan bubbles.
			_game._vfx.spawn_bubble_pop(bpos + offset, true)
			AudioManager.play("block_destroy_pow")
			await _game.get_tree().create_timer(0.1, true, false, true).timeout

	# Clear remaining minions
	var remaining: Array = _game._get_remaining_blocks_sorted()
	for block in remaining:
		if is_instance_valid(block) and not block.is_destroyed():
			var bpos: Vector2 = block.global_position
			_game._vfx.spawn_destroy_vfx(bpos, block.block_type)
			_game._vfx.burst_feedback(bpos, Color(0.35, 1.0, 0.55, 0.8), 10.0, 0.18)
			_game.score += 50
			block.queue_free()
			AudioManager.play("block_destroy_normal")
			_game._emit_ui_update()
		await _game.get_tree().create_timer(0.04, true, false, true).timeout

	# Show stage clear overlay
	var heart_bonus: int = _game.hearts * GameConstants.HEART_BONUS_KNIVES
	_game.stage_cleared.emit(_game.level + 1, heart_bonus)
	_game.knife_count += heart_bonus
	_game._emit_ui_update()

	await _game.get_tree().create_timer(1.2, true, false, true).timeout
	if _game.state != GameConstants.GameState.STAGE_CLEAR:
		return
	_game._open_levelup()
