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
var hit_reaction_remaining: float = 0.0
var impact_bursts: Array[Dictionary] = []
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

	player.position = Vector2(paddle_x, paddle_y)
	_start_new_run()


func _process(delta: float) -> void:
	_update_effects(delta)
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
	_draw_background()
	_draw_impact_bursts()
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
	hit_reaction_remaining = 0.0
	impact_bursts.clear()
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

	for child in moving_blocks_layer.get_children():
		var block := child as Block
		if block != null and block.block_type == GameConstants.BLOCK_RED_ENEMY:
			block.activate_enemy_motion()

	if knives_to_spawn > 0:
		spawn_timer.start()
	_emit_ui_update()


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
	_burst_feedback(knife.position, Color(0.98, 0.75, 0.20, 0.7), 10.0, 0.14)


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
	if remaining_hp <= 0:
		_destroy_block(block)


func _destroy_block(block: Block) -> void:
	var block_type := block.block_type
	if block_type == GameConstants.BLOCK_STAR:
		pending_stars += 1
	elif block_type == GameConstants.BLOCK_POW:
		for index in range(8):
			var angle := (float(index) / 8.0) * TAU
			_spawn_mini_knife(block.position, angle)

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
	world.position = Vector2.ZERO
	player.scale = Vector2.ONE
	player.modulate = Color(1.0, 1.0, 1.0, 1.0)
	player.set_state("idle")
	overlay_reset.emit()
	_clear_all_knives()
	LevelGen.init_level(self, level)
	_emit_ui_update()


func _play_hit_reaction() -> void:
	hit_reaction_remaining = 0.6
	shake_time_remaining = 0.18
	player.modulate = Color(1.0, 0.45, 0.45, 1.0)


func _update_effects(delta: float) -> void:
	if hit_reaction_remaining > 0.0 and state != GameConstants.GameState.GAME_OVER:
		hit_reaction_remaining = maxf(0.0, hit_reaction_remaining - delta)
		if is_zero_approx(hit_reaction_remaining):
			player.modulate = Color(1.0, 1.0, 1.0, 1.0)

	if shake_time_remaining > 0.0:
		shake_time_remaining = maxf(0.0, shake_time_remaining - delta)
		world.position = Vector2(randf_range(-2.0, 2.0), randf_range(-2.0, 2.0))
		if is_zero_approx(shake_time_remaining):
			world.position = Vector2.ZERO

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
	var segment_length := 8.0
	var direction := Vector2(cos(aim_angle), sin(aim_angle)) * segment_length
	var cursor := start
	for step in range(int(GameConstants.CANVAS_HEIGHT / segment_length)):
		if step % 2 == 0:
			draw_line(cursor, cursor + direction, Color(0.98, 0.75, 0.14, 1.0), 3.0)
		cursor += direction
		if cursor.y < 0.0 or cursor.x < 0.0 or cursor.x > GameConstants.CANVAS_WIDTH:
			break


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
