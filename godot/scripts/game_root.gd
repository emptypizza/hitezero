extends Node2D
class_name GameRoot

const GameConstants = preload("res://scripts/game_constants.gd")
const Block = preload("res://scripts/block.gd")
const Hud = preload("res://scripts/hud.gd")
const KNIFE_SCENE := preload("res://scenes/knife.tscn")
const Knife = preload("res://scripts/knife.gd")
const LevelGen = preload("res://scripts/level_generator.gd")
const Player = preload("res://scripts/player.gd")

signal ui_updated(data: Dictionary)
signal stage_cleared(next_level: int)
signal game_overed(score: int, level: int, best_score: int)
signal overlay_reset

@onready var world: Node2D = $World
@onready var blocks_layer: Node2D = $World/Blocks
@onready var moving_blocks_layer: Node2D = $World/MovingBlocks
@onready var knives_layer: Node2D = $World/Knives
@onready var player: Player = $World/Player
@onready var hud: Hud = $Hud

var state: int = GameConstants.GameState.AIMING
var level: int = 1
var knife_count: int = 3
var knives_to_spawn: int = 0
var pending_stars: int = 0
var hearts: int = GameConstants.HEARTS_MAX
var score: int = 0
var aim_angle: float = -PI * 0.5
var dragging: bool = false
var paddle_dragging: bool = false

var paddle_x: float = GameConstants.CANVAS_WIDTH * 0.5
var paddle_y: float = GameConstants.BOTTOM_Y
var fire_x: float = GameConstants.CANVAS_WIDTH * 0.5

var show_collider_debug: bool = false
var spawn_timer: Timer
var stage_timer: Timer
var shake_time_remaining: float = 0.0
var shake_direction := Vector2.ZERO
var shake_strength: float = 0.0
var shake_duration: float = 0.0
var hit_reaction_remaining: float = 0.0
var impact_bursts: Array[Dictionary] = []
var vfx_particles: Array[Dictionary] = []
var bg_particles: Array[Dictionary] = []
var _bg_spawn_acc: float = 0.0
var _flash_rect: ColorRect = null
var _flash_start_msec: int = -1
var _flash_start_alpha: float = 0.0
var _flash_duration_msec: int = 300
var web_bridge_ready: bool = false


func _ready() -> void:
	ensure_input_actions()
	_setup_timers()
	_setup_web_bridge()

	ui_updated.connect(hud.update_ui)
	stage_cleared.connect(hud.show_stage_clear)
	game_overed.connect(hud.show_game_over)
	overlay_reset.connect(hud.hide_overlay)
	hud.title_requested.connect(_return_to_title)
	hud.collider_debug_toggled.connect(_set_collider_debug)

	_create_flash_overlay()
	player.position = Vector2(paddle_x, paddle_y)
	_start_new_run()


func _process(delta: float) -> void:
	_update_effects(delta)
	_update_flash_overlay()
	_update_vfx_particles(delta)
	_update_bg_particles(delta)
	_refresh_player_visuals()
	_update_web_bridge_state()

	if state == GameConstants.GameState.STAGE_CLEAR or state == GameConstants.GameState.GAME_OVER:
		player.position = Vector2(paddle_x, paddle_y)
		player.set_waiting_knives(knife_count, state == GameConstants.GameState.AIMING)
		queue_redraw()
		return

	_update_keyboard(delta)
	player.position = Vector2(paddle_x, paddle_y)
	player.set_waiting_knives(knife_count, state == GameConstants.GameState.AIMING)

	if state == GameConstants.GameState.SHOOTING:
		_update_knives(delta)
		_update_red_enemies(delta)
		_check_win_lose()

	queue_redraw()


func _exit_tree() -> void:
	_clear_web_bridge_state()


func _draw() -> void:
	_draw_bg_particles()
	_draw_background()
	_draw_impact_bursts()
	_draw_vfx_particles()
	_draw_aim_line()
	_draw_collider_debug()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_handle_pointer_down(event.position)
		else:
			_handle_pointer_up()
	elif event is InputEventMouseMotion:
		_handle_pointer_move(event.position)
	elif event is InputEventScreenTouch:
		if event.pressed:
			_handle_pointer_down(event.position)
		else:
			_handle_pointer_up()
	elif event is InputEventScreenDrag:
		_handle_pointer_move(event.position)


func clear_level_nodes() -> void:
	for container in [blocks_layer, moving_blocks_layer]:
		for child in container.get_children():
			child.free()


func ensure_input_actions() -> void:
	_ensure_key_action("move_left", [KEY_LEFT, KEY_A])
	_ensure_key_action("move_right", [KEY_RIGHT, KEY_D])


func _start_new_run() -> void:
	if not spawn_timer.is_stopped():
		spawn_timer.stop()
	if not stage_timer.is_stopped():
		stage_timer.stop()

	level = 1
	knife_count = 3
	hearts = GameConstants.HEARTS_MAX
	score = 0
	pending_stars = 0
	knives_to_spawn = 0
	state = GameConstants.GameState.AIMING
	dragging = false
	paddle_dragging = false
	paddle_x = GameConstants.CANVAS_WIDTH * 0.5
	fire_x = paddle_x
	shake_time_remaining = 0.0
	shake_direction = Vector2.ZERO
	shake_strength = 0.0
	shake_duration = 0.0
	hit_reaction_remaining = 0.0
	impact_bursts.clear()
	vfx_particles.clear()
	bg_particles.clear()
	world.position = Vector2.ZERO
	player.scale = Vector2.ONE
	player.modulate = Color(1.0, 1.0, 1.0, 1.0)
	player.set_state("idle")
	overlay_reset.emit()
	_clear_all_knives()
	LevelGen.init_level(self, level)
	_emit_ui_update()


func _setup_timers() -> void:
	spawn_timer = Timer.new()
	spawn_timer.one_shot = false
	spawn_timer.wait_time = GameConstants.SPAWN_INTERVAL
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)

	stage_timer = Timer.new()
	stage_timer.one_shot = true
	stage_timer.timeout.connect(_on_stage_timer_timeout)
	add_child(stage_timer)


func _update_keyboard(delta: float) -> void:
	if Input.is_action_pressed("move_left"):
		paddle_x -= GameConstants.PADDLE_SPEED * delta
	if Input.is_action_pressed("move_right"):
		paddle_x += GameConstants.PADDLE_SPEED * delta
	paddle_x = clampf(paddle_x, 20.0, GameConstants.CANVAS_WIDTH - 20.0)


func _handle_pointer_down(pos: Vector2) -> void:
	if pos.y <= GameConstants.TOP_BAR_HEIGHT:
		return

	if state == GameConstants.GameState.GAME_OVER:
		restart_level()
		return

	if state == GameConstants.GameState.AIMING:
		dragging = true
		_update_aim_angle(pos)
	elif state == GameConstants.GameState.SHOOTING:
		paddle_dragging = true
		paddle_x = clampf(pos.x, 20.0, GameConstants.CANVAS_WIDTH - 20.0)


func _handle_pointer_move(pos: Vector2) -> void:
	if state == GameConstants.GameState.AIMING and dragging:
		_update_aim_angle(pos)
	elif state == GameConstants.GameState.SHOOTING and paddle_dragging:
		paddle_x = clampf(pos.x, 20.0, GameConstants.CANVAS_WIDTH - 20.0)


func _handle_pointer_up() -> void:
	if state == GameConstants.GameState.AIMING and dragging:
		dragging = false
		_start_shooting()
	paddle_dragging = false


func _update_aim_angle(pos: Vector2) -> void:
	var dx := pos.x - paddle_x
	var dy := pos.y - paddle_y
	var angle := atan2(dy, dx)
	if angle > -0.1:
		angle = -0.1
	if angle < -PI + 0.1:
		angle = -PI + 0.1
	aim_angle = angle


func _start_shooting() -> void:
	state = GameConstants.GameState.SHOOTING
	knives_to_spawn = knife_count
	fire_x = paddle_x
	player.scale = Vector2.ONE
	var tween := create_tween()
	tween.tween_property(player, "scale", Vector2(1.08, 1.08), 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(player, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_play_release_commit_cue()

	for child in moving_blocks_layer.get_children():
		var block := child as Block
		if block != null and block.block_type == GameConstants.BLOCK_RED_ENEMY:
			block.activate_enemy_motion()

	if knives_to_spawn > 0:
		spawn_timer.start()
	_emit_ui_update()


func _play_release_commit_cue() -> void:
	# Research basis: release feedback should appear inside the perceived instant
	# window even though actual knife spawning still follows SPAWN_INTERVAL.
	var shot_dir := Vector2(cos(aim_angle), sin(aim_angle))
	var muzzle := Vector2(fire_x, paddle_y - GameConstants.PADDLE_Y_OFFSET)
	player.play_output(aim_angle)
	_kick_world(-shot_dir, 3.0, 0.08)
	_burst_feedback(muzzle, Color(1.0, 0.90, 0.30, 0.78), 10.0, 0.12)


func _on_spawn_timer_timeout() -> void:
	if knives_to_spawn <= 0:
		spawn_timer.stop()
		return

	_spawn_knife()
	knives_to_spawn -= 1
	if knives_to_spawn <= 0:
		spawn_timer.stop()


func _spawn_knife() -> void:
	var knife: Knife = KNIFE_SCENE.instantiate()
	knives_layer.add_child(knife)
	var velocity := Vector2(cos(aim_angle), sin(aim_angle)) * GameConstants.BALL_SPEED
	knife.configure(Vector2(fire_x, paddle_y - GameConstants.PADDLE_Y_OFFSET), velocity, false)
	player.play_output(aim_angle)
	_kick_world(-velocity.normalized(), 2.0, 0.05)
	_burst_feedback(knife.position, Color(1.0, 0.78, 0.25, 0.82), 12.0, 0.16)


func _spawn_mini_knife(start_pos: Vector2, angle: float) -> void:
	var knife: Knife = KNIFE_SCENE.instantiate()
	knives_layer.add_child(knife)
	var velocity := Vector2(cos(angle), sin(angle)) * GameConstants.BALL_SPEED * 0.6
	knife.configure(start_pos, velocity, true)


func _update_knives(delta: float) -> void:
	for child in knives_layer.get_children():
		var knife := child as Knife
		if knife == null or not knife.active:
			continue

		knife.step(delta)
		var velocity := knife.velocity
		var kx := knife.position.x
		var ky := knife.position.y
		var radius := knife.radius

		if kx < radius:
			knife.position.x = radius
			velocity.x = absf(velocity.x)
		if kx > GameConstants.CANVAS_WIDTH - radius:
			knife.position.x = GameConstants.CANVAS_WIDTH - radius
			velocity.x = -absf(velocity.x)
		if ky < GameConstants.TOP_BAR_HEIGHT + radius:
			knife.position.y = GameConstants.TOP_BAR_HEIGHT + radius
			velocity.y = absf(velocity.y)

		if absf(velocity.y) < 18.0:
			velocity.y = 18.0 if velocity.y >= 0.0 else -18.0

		if velocity.y > 0.0:
			var tray_rect := _get_tray_rect()
			var tray_bottom := tray_rect.position.y + tray_rect.size.y
			var tray_right := tray_rect.position.x + tray_rect.size.x
			if ky + radius >= tray_rect.position.y and ky - radius <= tray_bottom:
				if kx >= tray_rect.position.x and kx <= tray_right:
					var hit_point := kx - paddle_x
					var normalized_hit := hit_point / (GameConstants.PADDLE_WIDTH * 0.5)
					var max_bounce_angle := PI / 2.5
					var bounce_angle := normalized_hit * max_bounce_angle
					var speed := velocity.length()
					velocity = Vector2(sin(bounce_angle) * speed, -cos(bounce_angle) * speed)
					knife.position.y = tray_rect.position.y - radius
					_burst_feedback(knife.position, Color(0.29, 0.87, 0.50, 1.0), 12.0, 0.18)

		knife.set_velocity(velocity)

		if knife.position.y >= GameConstants.BOTTOM_Y:
			knife.deactivate()
			continue

		_check_block_collision(knife, blocks_layer)
		_check_block_collision(knife, moving_blocks_layer)


func _check_block_collision(knife: Knife, container: Node2D) -> void:
	if not knife.active:
		return

	for child in container.get_children():
		var block := child as Block
		if block == null or block.is_destroyed():
			continue

		var rect := block.get_aabb()
		var test_x := clampf(knife.position.x, rect.position.x, rect.position.x + rect.size.x)
		var test_y := clampf(knife.position.y, rect.position.y, rect.position.y + rect.size.y)
		var dist_x := knife.position.x - test_x
		var dist_y := knife.position.y - test_y
		var distance := sqrt(dist_x * dist_x + dist_y * dist_y)

		if distance <= knife.radius:
			var overlap := knife.radius - distance
			if is_zero_approx(distance):
				dist_x = -1.0 if knife.velocity.x > 0.0 else 1.0
				dist_y = -1.0 if knife.velocity.y > 0.0 else 1.0
				distance = 1.414

			var normal := Vector2(dist_x / distance, dist_y / distance)
			knife.position += normal * overlap

			var velocity := knife.velocity
			if absf(normal.x) > absf(normal.y):
				velocity.x = -velocity.x
			else:
				velocity.y = -velocity.y
			knife.set_velocity(velocity)

			_hit_block(block)
			return


func _hit_block(block: Block) -> void:
	var remaining_hp := block.take_hit()
	_burst_feedback(block.global_position, block.get_hit_color(), 14.0, 0.20)
	_spawn_hit_vfx(block.global_position, block.get_hit_color())
	if remaining_hp <= 0:
		_destroy_block(block)


func _destroy_block(block: Block) -> void:
	var block_type := block.block_type
	var bpos := block.global_position
	if block_type == GameConstants.BLOCK_STAR:
		pending_stars += 1
	elif block_type == GameConstants.BLOCK_POW:
		for index in range(8):
			var angle := (float(index) / 8.0) * TAU
			_spawn_mini_knife(block.position, angle)
		_flash_screen(Color(1.0, 0.25, 1.0, 1.0), 0.55, 0.14)
		_freeze_frame(0.05)

	_spawn_destroy_vfx(bpos, block_type)
	score += 100
	block.queue_free()
	_emit_ui_update()


func _update_red_enemies(delta: float) -> void:
	var bottom_rect := _get_bottom_rect()
	var to_remove: Array[Block] = []

	for child in moving_blocks_layer.get_children():
		var block := child as Block
		if block == null or block.block_type != GameConstants.BLOCK_RED_ENEMY or block.is_destroyed():
			continue

		block.advance_enemy(delta)
		var rect := block.get_aabb()
		var overlaps := (
			rect.position.x < bottom_rect.position.x + bottom_rect.size.x
			and rect.position.x + rect.size.x > bottom_rect.position.x
			and rect.position.y < bottom_rect.position.y + bottom_rect.size.y
			and rect.position.y + rect.size.y > bottom_rect.position.y
		)
		if overlaps or block.position.y - block.block_size.y * 0.5 > GameConstants.CANVAS_HEIGHT + 50.0:
			to_remove.append(block)

	for block in to_remove:
		if block.is_destroyed():
			continue
		block.hp = 0
		hearts -= 1
		_burst_feedback(block.global_position, Color(0.94, 0.27, 0.27, 1.0), 18.0, 0.24)
		_play_hit_reaction()
		block.queue_free()
		_emit_ui_update()
		if hearts <= 0:
			_trigger_game_over()
			return


func _check_win_lose() -> void:
	if _get_stars_left() == 0:
		_trigger_stage_clear()
		return

	var all_inactive := true
	for child in knives_layer.get_children():
		var knife := child as Knife
		if knife != null and knife.active:
			all_inactive = false
			break

	var spawn_done := spawn_timer.is_stopped() and knives_to_spawn <= 0
	if all_inactive and spawn_done:
		_trigger_game_over()


func _trigger_stage_clear() -> void:
	if state == GameConstants.GameState.STAGE_CLEAR:
		return

	state = GameConstants.GameState.STAGE_CLEAR
	_clear_all_knives()
	if not spawn_timer.is_stopped():
		spawn_timer.stop()
	knife_count += pending_stars
	pending_stars = 0
	player.scale = Vector2.ONE
	stage_cleared.emit(level + 1)
	_flash_screen(Color(0.35, 1.0, 0.55, 1.0), 0.6, 0.24)
	_emit_ui_update()
	stage_timer.start(1.2)


func _trigger_game_over() -> void:
	if state == GameConstants.GameState.GAME_OVER:
		return

	state = GameConstants.GameState.GAME_OVER
	if not spawn_timer.is_stopped():
		spawn_timer.stop()
	_clear_all_knives()
	hit_reaction_remaining = 0.0
	player.modulate = Color(0.78, 0.78, 0.84, 1.0)
	Session.submit_score(score)
	game_overed.emit(score, level, Session.best_score)
	_flash_screen(Color(0.85, 0.15, 0.15, 1.0), 0.65, 0.28)
	_emit_ui_update()


func restart_level() -> void:
	if not spawn_timer.is_stopped():
		spawn_timer.stop()
	if not stage_timer.is_stopped():
		stage_timer.stop()

	hearts = GameConstants.HEARTS_MAX
	state = GameConstants.GameState.AIMING
	dragging = false
	paddle_dragging = false
	paddle_x = GameConstants.CANVAS_WIDTH * 0.5
	fire_x = paddle_x
	hit_reaction_remaining = 0.0
	shake_time_remaining = 0.0
	shake_direction = Vector2.ZERO
	shake_strength = 0.0
	shake_duration = 0.0
	world.position = Vector2.ZERO
	vfx_particles.clear()
	player.scale = Vector2.ONE
	player.modulate = Color(1.0, 1.0, 1.0, 1.0)
	player.set_state("idle")
	overlay_reset.emit()
	_clear_all_knives()
	LevelGen.init_level(self, level)
	_emit_ui_update()


func _play_hit_reaction() -> void:
	hit_reaction_remaining = 0.6
	_kick_world(Vector2(0.0, -1.0), 4.0, 0.18)
	player.modulate = Color(1.0, 0.45, 0.45, 1.0)
	_flash_screen(Color(1.0, 0.3, 0.3, 1.0), 0.4, 0.12)


func _kick_world(direction: Vector2, strength: float, duration: float) -> void:
	if direction.length_squared() <= 0.0001:
		shake_direction = Vector2.ZERO
	else:
		shake_direction = direction.normalized()
	shake_strength = maxf(shake_strength, strength)
	shake_duration = maxf(shake_duration, duration)
	shake_time_remaining = maxf(shake_time_remaining, duration)


func _update_effects(delta: float) -> void:
	if hit_reaction_remaining > 0.0 and state != GameConstants.GameState.GAME_OVER:
		hit_reaction_remaining = maxf(0.0, hit_reaction_remaining - delta)
		if is_zero_approx(hit_reaction_remaining):
			player.modulate = Color(1.0, 1.0, 1.0, 1.0)

	if shake_time_remaining > 0.0:
		shake_time_remaining = maxf(0.0, shake_time_remaining - delta)
		var t := clampf(shake_time_remaining / maxf(0.001, shake_duration), 0.0, 1.0)
		var jitter := Vector2(randf_range(-0.65, 0.65), randf_range(-0.65, 0.65)) * t
		world.position = shake_direction * shake_strength * t + jitter
		if is_zero_approx(shake_time_remaining):
			world.position = Vector2.ZERO
			shake_direction = Vector2.ZERO
			shake_strength = 0.0
			shake_duration = 0.0

	for index in range(impact_bursts.size() - 1, -1, -1):
		var burst: Dictionary = impact_bursts[index]
		burst["life"] = float(burst["life"]) - delta
		if float(burst["life"]) <= 0.0:
			impact_bursts.remove_at(index)
		else:
			impact_bursts[index] = burst


func _refresh_player_visuals() -> void:
	match state:
		GameConstants.GameState.GAME_OVER:
			player.set_state("gameover")
		GameConstants.GameState.STAGE_CLEAR:
			player.set_state("clear")
		_:
			if hit_reaction_remaining > 0.0:
				player.set_state("hit")
			elif state == GameConstants.GameState.SHOOTING:
				player.set_state("throw")
			else:
				player.set_state("idle")


func _emit_ui_update() -> void:
	ui_updated.emit({
		"hearts": hearts,
		"knife_count": knife_count,
		"score": score,
		"level": level,
		"state": state,
		"stars_left": _get_stars_left(),
	})
	_update_web_bridge_state()


func _clear_all_knives() -> void:
	for child in knives_layer.get_children():
		child.queue_free()


func _get_stars_left() -> int:
	var count := 0
	for container in [blocks_layer, moving_blocks_layer]:
		for child in container.get_children():
			var block := child as Block
			if block != null and block.block_type == GameConstants.BLOCK_STAR and not block.is_destroyed():
				count += 1
	return count


func _burst_feedback(at: Vector2, color: Color, radius: float, life: float) -> void:
	impact_bursts.append({
		"position": at,
		"color": color,
		"radius": radius,
		"life": life,
		"max_life": life,
	})


func _get_tray_rect() -> Rect2:
	return Rect2(
		Vector2(paddle_x - GameConstants.PADDLE_WIDTH * 0.5, paddle_y - GameConstants.PADDLE_Y_OFFSET),
		Vector2(GameConstants.PADDLE_WIDTH, 14.0)
	)


func _get_bottom_rect() -> Rect2:
	return Rect2(
		Vector2(12.0, GameConstants.CANVAS_HEIGHT - 36.0),
		Vector2(GameConstants.CANVAS_WIDTH - 24.0, 20.0)
	)


func _draw_background() -> void:
	# Base fill and border drawn by CanvasLayer TextureRect in game.tscn; keep light playfield grid only.
	for y in range(int(GameConstants.TOP_BAR_HEIGHT), int(GameConstants.CANVAS_HEIGHT), 40):
		draw_line(Vector2(0.0, float(y)), Vector2(GameConstants.CANVAS_WIDTH, float(y)), GameConstants.COLOR_NEON_SOFT, 1.0)
	for x in range(0, int(GameConstants.CANVAS_WIDTH), 40):
		draw_line(Vector2(float(x), GameConstants.TOP_BAR_HEIGHT), Vector2(float(x), GameConstants.CANVAS_HEIGHT), GameConstants.COLOR_NEON_SOFT, 1.0)


func _draw_impact_bursts() -> void:
	for burst in impact_bursts:
		var life := float(burst["life"])
		var max_life := float(burst["max_life"])
		var t := life / max_life
		var radius := lerpf(float(burst["radius"]), float(burst["radius"]) + 12.0, 1.0 - t)
		var color: Color = burst["color"]
		color.a = 0.6 * t
		draw_circle(burst["position"], radius, color)


func _draw_aim_line() -> void:
	if state != GameConstants.GameState.AIMING or not dragging:
		return

	var start := Vector2(paddle_x, paddle_y - GameConstants.PADDLE_Y_OFFSET)
	var dir := Vector2(cos(aim_angle), sin(aim_angle))

	var hit1 := _ray_wall_hit(start, dir)
	_draw_aim_dashed(start, hit1, Color(0.98, 0.75, 0.14, 1.0), 2.5)

	var ref_dir := _reflect_dir(dir, hit1)
	var hit2 := _ray_wall_hit(hit1 + ref_dir * 2.0, ref_dir)
	_draw_aim_dashed(hit1, hit2, Color(0.98, 0.75, 0.14, 0.40), 1.5)

	_draw_crosshair(start, Color(0.98, 0.92, 0.30, 0.88))


func _draw_collider_debug() -> void:
	if not show_collider_debug:
		return

	var tray_rect := _get_tray_rect()
	draw_rect(tray_rect, Color(0.98, 0.80, 0.08, 1.0), false, 2.0)

	var bottom_rect := _get_bottom_rect()
	draw_rect(bottom_rect, Color(0.13, 0.83, 0.93, 1.0), false, 2.0)

	for child in moving_blocks_layer.get_children():
		var block := child as Block
		if block != null and block.block_type == GameConstants.BLOCK_RED_ENEMY and not block.is_destroyed():
			draw_rect(block.get_aabb(), Color(0.94, 0.27, 0.27, 1.0), false, 2.0)


func _ensure_key_action(action_name: String, key_codes: Array[int]) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)

	for key_code in key_codes:
		var already_present := false
		for existing_event in InputMap.action_get_events(action_name):
			if existing_event is InputEventKey and existing_event.physical_keycode == key_code:
				already_present = true
				break
		if already_present:
			continue

		var event := InputEventKey.new()
		event.physical_keycode = key_code
		event.keycode = key_code
		InputMap.action_add_event(action_name, event)


func _return_to_title() -> void:
	get_tree().change_scene_to_file("res://scenes/title.tscn")


func _set_collider_debug(enabled: bool) -> void:
	show_collider_debug = enabled
	queue_redraw()


func _on_stage_timer_timeout() -> void:
	level += 1
	state = GameConstants.GameState.AIMING
	dragging = false
	paddle_dragging = false
	paddle_x = GameConstants.CANVAS_WIDTH * 0.5
	fire_x = paddle_x
	player.scale = Vector2.ONE
	player.modulate = Color(1.0, 1.0, 1.0, 1.0)
	overlay_reset.emit()
	_clear_all_knives()
	LevelGen.init_level(self, level)
	_emit_ui_update()


func _setup_web_bridge() -> void:
	if not OS.has_feature("web"):
		return
	JavaScriptBridge.eval("""
        window.render_game_to_text = function () {
			return window.__hitezero_state_json || "{}";
        };
        window.advanceTime = async function (ms) {
            return await new Promise((resolve) => setTimeout(resolve, ms));
        };
	""", true)
	web_bridge_ready = true
	_update_web_bridge_state()


func _clear_web_bridge_state() -> void:
	if not web_bridge_ready:
		return
	JavaScriptBridge.eval("window.__hitezero_state_json = null; window.render_game_to_text = function () { return null; };", true)


func _update_web_bridge_state() -> void:
	if not web_bridge_ready:
		return

	var blocks: Array[Dictionary] = []
	for container in [blocks_layer, moving_blocks_layer]:
		for child in container.get_children():
			var block := child as Block
			if block == null or block.is_destroyed():
				continue
			blocks.append({
				"type": block.block_type,
				"x": snappedf(block.position.x, 0.1),
				"y": snappedf(block.position.y, 0.1),
				"hp": block.hp,
			})

	var knives: Array[Dictionary] = []
	for child in knives_layer.get_children():
		var knife := child as Knife
		if knife == null or not knife.active:
			continue
		knives.append({
			"x": snappedf(knife.position.x, 0.1),
			"y": snappedf(knife.position.y, 0.1),
			"vx": snappedf(knife.velocity.x, 0.1),
			"vy": snappedf(knife.velocity.y, 0.1),
			"small": knife.is_small,
		})

	var payload := {
		"coordinate_system": {
			"origin": "top-left",
			"x_direction": "right",
			"y_direction": "down",
		},
		"mode": _game_state_name(),
		"player": {
			"x": snappedf(paddle_x, 0.1),
			"y": snappedf(paddle_y, 0.1),
			"aim_angle": snappedf(aim_angle, 0.001),
		},
		"hearts": hearts,
		"knife_count": knife_count,
		"knives_to_spawn": knives_to_spawn,
		"level": level,
		"score": score,
		"stars_left": _get_stars_left(),
		"blocks": blocks,
		"knives": knives,
		"visual_safety": {
			"hud_bottom": GameConstants.TOP_BAR_HEIGHT,
			"level_start_y": GameConstants.LEVEL_START_Y,
			"first_block_center_y": snappedf(GameConstants.LEVEL_START_Y + 2.0 + ((GameConstants.BLOCK_HEIGHT - 4.0) * 0.5), 0.1),
		},
		"collider_debug": show_collider_debug,
	}
	var json := JSON.stringify(payload)
	JavaScriptBridge.eval("window.__hitezero_state_json = " + JSON.stringify(json) + ";", true)


func _game_state_name() -> String:
	match state:
		GameConstants.GameState.AIMING:
			return "AIMING"
		GameConstants.GameState.SHOOTING:
			return "SHOOTING"
		GameConstants.GameState.STAGE_CLEAR:
			return "STAGE_CLEAR"
		GameConstants.GameState.GAME_OVER:
			return "GAME_OVER"
		_:
			return "UNKNOWN"


# ─── Flash overlay ──────────────────────────────────────────────────────────

func _create_flash_overlay() -> void:
	var flash_layer := CanvasLayer.new()
	flash_layer.layer = 100
	add_child(flash_layer)
	_flash_rect = ColorRect.new()
	_flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash_rect.color = Color(0.0, 0.0, 0.0, 0.0)
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash_layer.add_child(_flash_rect)


func _flash_screen(color: Color, intensity: float, duration: float) -> void:
	if _flash_rect == null:
		return
	_flash_rect.color = Color(color.r, color.g, color.b, clampf(intensity, 0.0, 0.95))
	_flash_start_alpha = _flash_rect.color.a
	_flash_start_msec = Time.get_ticks_msec()
	_flash_duration_msec = maxi(1, int(duration * 1000.0))


func _update_flash_overlay() -> void:
	if _flash_rect == null or _flash_start_msec < 0:
		return
	var elapsed := Time.get_ticks_msec() - _flash_start_msec
	if elapsed >= _flash_duration_msec:
		_flash_rect.color.a = 0.0
		_flash_start_msec = -1
		return
	var t := 1.0 - float(elapsed) / float(_flash_duration_msec)
	_flash_rect.color.a = _flash_start_alpha * (t * t)


func _freeze_frame(duration_sec: float) -> void:
	if Engine.time_scale < 0.5:
		return
	Engine.time_scale = 0.05
	await get_tree().create_timer(duration_sec, true, false, true).timeout
	Engine.time_scale = 1.0


# ─── Typed VFX bursts ───────────────────────────────────────────────────────

func _spawn_destroy_vfx(pos: Vector2, block_type: String) -> void:
	match block_type:
		GameConstants.BLOCK_NORMAL:
			_vfx_sparks(pos, 10, Color(0.25, 0.72, 1.0), Color(0.75, 0.96, 1.0), 80.0, 160.0, 0.36)
		GameConstants.BLOCK_POW:
			_vfx_ring(pos, Color(1.0, 0.08, 1.0, 0.88), 0.46)
			_vfx_ring(pos, Color(1.0, 1.0, 1.0, 0.52), 0.30)
			_vfx_sparks(pos, 14, Color(1.0, 0.28, 1.0), Color(1.0, 0.88, 1.0), 100.0, 220.0, 0.40)
		GameConstants.BLOCK_STAR:
			_vfx_sparks(pos, 12, Color(1.0, 0.72, 0.0), Color(1.0, 0.98, 0.55), 60.0, 130.0, 0.50)
			_vfx_starburst(pos, Color(1.0, 0.95, 0.42, 0.92), 0.38)
		GameConstants.BLOCK_RED_ENEMY:
			_vfx_ring(pos, Color(0.92, 0.12, 0.20, 0.72), 0.36)
			_vfx_sparks(pos, 10, Color(0.92, 0.18, 0.18), Color(1.0, 0.68, 0.38), 90.0, 180.0, 0.38)


func _spawn_hit_vfx(pos: Vector2, color: Color) -> void:
	_vfx_sparks(pos, 4, color, color.lerp(Color.WHITE, 0.4), 36.0, 76.0, 0.18)


func _vfx_sparks(pos: Vector2, count: int, color_a: Color, color_b: Color,
		speed_min: float, speed_max: float, life: float) -> void:
	for i in range(count):
		var angle := float(i) / float(count) * TAU + randf_range(-0.3, 0.3)
		var speed := randf_range(speed_min, speed_max)
		var c := color_a.lerp(color_b, randf())
		vfx_particles.append({
			"x": pos.x + randf_range(-3.0, 3.0),
			"y": pos.y + randf_range(-3.0, 3.0),
			"vx": cos(angle) * speed,
			"vy": sin(angle) * speed,
			"radius": randf_range(1.5, 3.5),
			"color": c,
			"life": life * randf_range(0.7, 1.0),
			"max_life": life,
			"shape": "circle",
		})


func _vfx_ring(pos: Vector2, color: Color, life: float) -> void:
	vfx_particles.append({
		"x": pos.x, "y": pos.y,
		"vx": 0.0, "vy": 0.0,
		"radius": 4.0,
		"expand": 190.0,
		"color": color,
		"life": life,
		"max_life": life,
		"shape": "ring",
	})


func _vfx_starburst(pos: Vector2, color: Color, life: float) -> void:
	vfx_particles.append({
		"x": pos.x, "y": pos.y,
		"vx": 0.0, "vy": 0.0,
		"radius": 20.0,
		"expand": 0.0,
		"color": color,
		"life": life,
		"max_life": life,
		"shape": "star",
	})


func _update_vfx_particles(delta: float) -> void:
	for i in range(vfx_particles.size() - 1, -1, -1):
		var p: Dictionary = vfx_particles[i]
		p["life"] = float(p["life"]) - delta
		if float(p["life"]) <= 0.0:
			vfx_particles.remove_at(i)
			continue
		p["x"] = float(p["x"]) + float(p["vx"]) * delta
		p["y"] = float(p["y"]) + float(p["vy"]) * delta
		p["vx"] = float(p["vx"]) * 0.82
		p["vy"] = float(p["vy"]) * 0.82
		if p.get("shape") == "ring":
			p["radius"] = float(p["radius"]) + float(p.get("expand", 0.0)) * delta
		vfx_particles[i] = p


func _draw_vfx_particles() -> void:
	for p in vfx_particles:
		var life := float(p["life"])
		var max_life := float(p["max_life"])
		var t := clampf(life / max_life, 0.0, 1.0)
		var pos := Vector2(float(p["x"]), float(p["y"]))
		var color: Color = p["color"]
		color.a *= t
		match p.get("shape", "circle"):
			"circle":
				draw_circle(pos, maxf(0.5, float(p["radius"]) * (0.55 + 0.45 * t)), color)
			"ring":
				var r := float(p["radius"])
				if r > 0.5:
					draw_arc(pos, r, 0.0, TAU, 24, color, maxf(1.0, 3.2 * t))
			"star":
				var sz := float(p["radius"]) * t
				draw_line(pos - Vector2(sz, 0.0), pos + Vector2(sz, 0.0), color, 2.0)
				draw_line(pos - Vector2(0.0, sz), pos + Vector2(0.0, sz), color, 2.0)
				var d := sz * 0.68
				draw_line(pos - Vector2(d, d), pos + Vector2(d, d), color, 1.5)
				draw_line(pos + Vector2(-d, d), pos - Vector2(-d, d), color, 1.5)


# ─── Background particles ────────────────────────────────────────────────────

const _BG_PARTICLE_MAX := 45
const _BG_SPAWN_INTERVAL := 0.07


func _bg_particle_color() -> Color:
	match (level - 1) % 4:
		0: return Color(0.0, 0.85, 1.0)
		1: return Color(0.65, 0.25, 1.0)
		2: return Color(1.0, 0.55, 0.15)
		_: return Color(1.0, 0.25, 0.85)


func _spawn_bg_particle() -> void:
	if bg_particles.size() >= _BG_PARTICLE_MAX:
		return
	bg_particles.append({
		"x": randf_range(0.0, GameConstants.CANVAS_WIDTH),
		"y": randf_range(-30.0, GameConstants.TOP_BAR_HEIGHT),
		"vx": randf_range(-6.0, 6.0),
		"vy": randf_range(18.0, 52.0),
		"radius": randf_range(0.8, 2.5),
		"alpha": randf_range(0.05, 0.17),
		"life": randf_range(7.0, 15.0),
		"max_life": 15.0,
		"color": _bg_particle_color(),
	})


func _update_bg_particles(delta: float) -> void:
	_bg_spawn_acc += delta
	while _bg_spawn_acc >= _BG_SPAWN_INTERVAL:
		_bg_spawn_acc -= _BG_SPAWN_INTERVAL
		_spawn_bg_particle()
	for i in range(bg_particles.size() - 1, -1, -1):
		var p: Dictionary = bg_particles[i]
		p["y"] = float(p["y"]) + float(p["vy"]) * delta
		p["x"] = float(p["x"]) + float(p["vx"]) * delta
		p["life"] = float(p["life"]) - delta
		if float(p["y"]) > GameConstants.CANVAS_HEIGHT + 10.0 or float(p["life"]) <= 0.0:
			bg_particles.remove_at(i)
		else:
			bg_particles[i] = p


func _draw_bg_particles() -> void:
	for p in bg_particles:
		var life := float(p["life"])
		var max_life := float(p["max_life"])
		var t := life / max_life
		var alpha_scale: float
		if t > 0.88:
			alpha_scale = (1.0 - t) / 0.12
		elif t < 0.18:
			alpha_scale = t / 0.18
		else:
			alpha_scale = 1.0
		var color: Color = p["color"]
		color.a = float(p["alpha"]) * alpha_scale
		draw_circle(Vector2(float(p["x"]), float(p["y"])), float(p["radius"]), color)


# ─── Aim line helpers ────────────────────────────────────────────────────────

func _ray_wall_hit(from: Vector2, dir: Vector2) -> Vector2:
	var t_min := 2000.0
	if dir.x > 0.0001:
		t_min = minf(t_min, (GameConstants.CANVAS_WIDTH - from.x) / dir.x)
	elif dir.x < -0.0001:
		t_min = minf(t_min, -from.x / dir.x)
	if dir.y < -0.0001:
		t_min = minf(t_min, (GameConstants.TOP_BAR_HEIGHT - from.y) / dir.y)
	elif dir.y > 0.0001:
		t_min = minf(t_min, (GameConstants.BOTTOM_Y - from.y) / dir.y)
	return from + dir * t_min


func _reflect_dir(dir: Vector2, hit_pos: Vector2) -> Vector2:
	var eps := 1.5
	if hit_pos.x <= eps or hit_pos.x >= GameConstants.CANVAS_WIDTH - eps:
		return Vector2(-dir.x, dir.y)
	return Vector2(dir.x, -dir.y)


func _draw_aim_dashed(from: Vector2, to: Vector2, color: Color, width: float) -> void:
	var total := from.distance_to(to)
	if total < 1.0:
		return
	var d := (to - from) / total
	var seg := 7.0
	var gap := 5.0
	var pos := 0.0
	while pos < total:
		var end_pos := minf(pos + seg, total)
		draw_line(from + d * pos, from + d * end_pos, color, width)
		pos += seg + gap


func _draw_crosshair(pos: Vector2, color: Color) -> void:
	var arm := 7.0
	draw_line(pos + Vector2(-arm, 0.0), pos + Vector2(arm, 0.0), color, 1.5)
	draw_line(pos + Vector2(0.0, -arm), pos + Vector2(0.0, arm), color, 1.5)
	var ring_c := Color(color.r, color.g, color.b, color.a * 0.5)
	draw_arc(pos, arm - 0.5, 0.0, TAU, 16, ring_c, 1.0)
