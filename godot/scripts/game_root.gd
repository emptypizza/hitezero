extends Node2D
class_name GameRoot

const GameConstants = preload("res://scripts/game_constants.gd")
const Block = preload("res://scripts/block.gd")
const Hud = preload("res://scripts/hud.gd")
const KNIFE_SCENE := preload("res://scenes/knife.tscn")
const Knife = preload("res://scripts/knife.gd")
const LevelGen = preload("res://scripts/level_generator.gd")
const Player = preload("res://scripts/player.gd")
const BossScript = preload("res://scripts/boss.gd")

signal ui_updated(data: Dictionary)
signal stage_cleared(next_level: int, heart_bonus: int)
signal game_overed(score: int, level: int, best_score: int, best_stage: int, revive_cost: int, can_revive: bool)
signal overlay_reset
signal boss_started(boss_name: String, boss_color: Color)
signal boss_hp_updated(hp: int, max_hp: int)
signal boss_phase_changed(new_phase: int)
signal boss_defeated_signal

# ─── Hit-stop (gameplay-scoped, stackable) ──────────────────────────────────
const HITSTOP_MAX := 0.18          # cap for accumulated micro freezes (combo spam guard)
const HITSTOP_HIT := 0.03          # non-destroying block hit
const HITSTOP_DESTROY := 0.05      # normal block destruction
const HITSTOP_COMBO_STEP := 0.008  # added per combo tier

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

# ─── Combo system ──────────────────────────────────────────────────────────
var hit_combo: int = 0
var combo_timer: float = 0.0
var combo_best: int = 0

# ─── Item system ───────────────────────────────────────────────────────────
var item_slots: Array[int] = []  # ItemType values
var item_timers: Array[float] = []  # remaining duration per slot
var item_orbs: Array[Dictionary] = []  # {x, y, vy, type, life}
var stages_since_item_drop: int = 0
var _blast_in_progress: bool = false

# ─── Boss system ───────────────────────────────────────────────────────────
var current_boss: Boss = null
var is_boss_stage: bool = false
var boss_warning_timer: float = 0.0

# ─── Reference-DNA systems (docs/duckflock_reference_goal_plan.md) ──────────
# game_speed scales SIMULATION delta only; hit-stop, shake, flash, HUD tweens
# and VFX run on real time so impacts keep their weight at x2.
var game_speed: float = 1.0
var game_paused: bool = false            # NEW-01: soft pause — sim, timers and FX hold
var _bridge_accum: float = 0.0           # P1-1: throttles per-frame bridge serialization
var _last_ui_signature: Array = []       # P1-2: skips redundant ui_updated emits
var tray_bounce_streak: int = 0          # FL-02: consecutive tray bounces this volley
var _juggle_bonus_given: bool = false    # FL-02: one juggle bonus knife per stage

const BRIDGE_UPDATE_INTERVAL := 0.1      # P1-1: event emits stay immediate
const TRAY_BOUNCE_SCORE := 15            # FL-02
const TRAY_JUGGLE_STREAK_TARGET := 5     # FL-02
var coin_shards: Array[Dictionary] = []  # kill-chain loot: scatter → magnet
var _coin_streak: int = 0                # rising collect-tick pitch
var stars_total: int = 0                 # objective pill denominator
var levelup_open: bool = false
# Run-scoped modifiers (reset every run, separate from Session meta upgrades).
var run_damage_bonus: int = 0            # from level-up picks
var group_dmg_bonus: int = 0             # from group-kill stacks
var run_speed_mult: float = 1.0
var run_tray_bonus: float = 0.0
var run_buffs: Dictionary = {}           # buff key -> remaining seconds
var revive_count: int = 0                # coin-revives used this run (cost scales)
var _burst_destroy_count: int = 0        # destroys inside the group-kill window
var _burst_destroy_timer: float = 0.0
var firefly_particles: Array[Dictionary] = []
var _firefly_spawn_acc: float = 0.0

var hitstop_remaining: float = 0.0
# ─── Screen shake (trauma² model) ───────────────────────────────────────────
# trauma is 0..1; displayed shake = trauma² so it ramps softly and decays
# smoothly. Stacks across rapid impacts and biases along shake_direction.
const TRAUMA_MAX := 1.0
const TRAUMA_DECAY := 1.7              # trauma units shed per second
const SHAKE_MAX_OFFSET := 13.0         # px at trauma == 1
const SHAKE_DIR_BIAS := 0.45           # 0 = pure noise, 1 = pure directional
const SHAKE_MAX_ROLL := 0.021          # rad (~1.2°) rotation kick at trauma == 1
const ZOOM_KICK_DECAY := 9.0           # zoom punch shed per second
const ZOOM_KICK_MAX := 0.03            # +3% scale cap
var trauma: float = 0.0
var zoom_kick: float = 0.0
var shake_direction := Vector2.ZERO    # bias direction (kept for QA hooks/tests)
var _shake_noise: FastNoiseLite = null
var _shake_seed_t: float = 0.0
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

	_shake_noise = FastNoiseLite.new()
	_shake_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	_shake_noise.frequency = 0.5

	ui_updated.connect(hud.update_ui)
	stage_cleared.connect(hud.show_stage_clear)
	game_overed.connect(hud.show_game_over)
	overlay_reset.connect(hud.hide_overlay)
	hud.title_requested.connect(_return_to_title)
	hud.collider_debug_toggled.connect(_set_collider_debug)
	hud.speed_toggled.connect(_set_game_speed)
	hud.levelup_chosen.connect(_on_levelup_chosen)
	hud.pause_toggled.connect(_toggle_pause)
	boss_started.connect(hud.show_boss_warning)
	boss_hp_updated.connect(hud.update_boss_hp)
	boss_phase_changed.connect(hud.show_boss_phase)
	boss_defeated_signal.connect(hud.show_boss_defeated)
	hud.revive_requested.connect(revive)

	_create_flash_overlay()
	_create_vignette()
	player.position = Vector2(paddle_x, paddle_y)
	_start_new_run()


func _process(delta: float) -> void:
	# NEW-01: pause key works in any live state; everything below holds while
	# paused (sim, FX, timers) so the run freezes as one coherent picture.
	if Input.is_action_just_pressed("pause_game"):
		_toggle_pause()
	if game_paused:
		queue_redraw()
		return

	_update_effects(delta)
	_update_flash_overlay()
	_update_vfx_particles(delta)
	_update_bg_particles(delta)
	_update_fireflies(delta)
	_update_coin_shards(delta)
	_refresh_player_visuals()
	# P1-1: the full-state serialization is too heavy to run per frame on web;
	# throttle the ambient refresh — event paths still push immediately via
	# _emit_ui_update / explicit calls.
	_bridge_accum += delta
	if _bridge_accum >= BRIDGE_UPDATE_INTERVAL:
		_bridge_accum = 0.0
		_update_web_bridge_state()

	# Gameplay-scoped hit-stop: freezes only the action simulation below.
	# HUD, screen shake/flash, VFX particles, player tween, and input keep
	# running on real delta so the impact still reads while the world holds.
	var frozen := hitstop_remaining > 0.0
	if frozen:
		hitstop_remaining = maxf(0.0, hitstop_remaining - delta)

	if state == GameConstants.GameState.STAGE_CLEAR or state == GameConstants.GameState.GAME_OVER:
		player.position = Vector2(paddle_x, paddle_y)
		player.set_waiting_knives(knife_count, state == GameConstants.GameState.AIMING)
		queue_redraw()
		return

	_update_keyboard(delta)
	player.position = Vector2(paddle_x, paddle_y)
	player.set_waiting_knives(knife_count, state == GameConstants.GameState.AIMING)

	# Boss warning countdown
	if boss_warning_timer > 0.0:
		boss_warning_timer = maxf(0.0, boss_warning_timer - delta)

	if state == GameConstants.GameState.SHOOTING:
		# Pause knife spawning while frozen so the spawn cadence resumes intact.
		spawn_timer.paused = frozen
		if not frozen:
			# x2 toggle scales the simulation only — real-time feedback systems
			# above keep their own clock so hit-stop/shake still read at speed.
			var sim_delta := delta * game_speed
			_update_combo_timer(sim_delta)
			_update_item_timers(sim_delta)
			_update_run_buffs(sim_delta)
			_update_group_kill(sim_delta)
			_update_item_orbs(sim_delta)
			_update_knives(sim_delta)
			_update_red_enemies(sim_delta)
			if current_boss != null:
				current_boss.update_boss(sim_delta)
				boss_hp_updated.emit(current_boss.hp, current_boss.max_hp)
			_check_win_lose()

	queue_redraw()


func _exit_tree() -> void:
	# The game-over sequence holds Engine.time_scale at 0.3 for 0.5s; if the
	# scene is torn down inside that window the awaiting coroutine dies before
	# restoring it, so reset here or the title scene inherits the slow-mo.
	Engine.time_scale = 1.0
	_clear_web_bridge_state()


func _draw() -> void:
	_draw_bg_particles()
	_draw_background()
	_draw_block_depth()
	_draw_wet_reflections()
	_draw_fireflies()
	_draw_impact_bursts()
	_draw_vfx_particles()
	_draw_item_orbs()
	_draw_coin_shards()
	_draw_aim_line()
	_draw_collider_debug()


func _unhandled_input(event: InputEvent) -> void:
	# NEW-01: while paused, the first tap resumes and is swallowed so it can
	# never start an aim drag or fire.
	if game_paused:
		var tapped: bool = (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed) \
			or (event is InputEventScreenTouch and event.pressed)
		if tapped:
			_set_paused(false)
		return

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


# ─── NEW-01: soft pause ──────────────────────────────────────────────────────
# Not SceneTree pause: the run freezes through the existing state machine
# (early _process return + paused Timers) so HUD, signals, and the resume tap
# keep working without process_mode surgery on every node.

func _toggle_pause() -> void:
	_set_paused(not game_paused)


func _set_paused(paused: bool) -> void:
	if game_paused == paused:
		return
	if paused:
		# Only live play pauses; overlays/sequences own their own flow.
		var live := state == GameConstants.GameState.AIMING or state == GameConstants.GameState.SHOOTING
		if not live or levelup_open:
			return
	game_paused = paused
	if paused:
		# Drop any in-flight drag so a stale aim can't fire on resume.
		dragging = false
		paddle_dragging = false
	spawn_timer.paused = paused
	stage_timer.paused = paused
	hud.set_paused(paused)
	AudioManager.play("ui_click")
	_update_web_bridge_state()


func _notification(what: int) -> void:
	# Mobile/web lifeline: a phone call or tab switch must not eat the run.
	# Headless QA has no real focus, so it must never auto-pause.
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		if DisplayServer.get_name() != "headless":
			_set_paused(true)


func ensure_input_actions() -> void:
	_ensure_key_action("move_left", [KEY_LEFT, KEY_A])
	_ensure_key_action("move_right", [KEY_RIGHT, KEY_D])
	_ensure_key_action("pause_game", [KEY_ESCAPE, KEY_P])


func _start_new_run() -> void:
	if not spawn_timer.is_stopped():
		spawn_timer.stop()
	spawn_timer.paused = false
	if not stage_timer.is_stopped():
		stage_timer.stop()
	stage_timer.paused = false

	game_paused = false               # NEW-01
	hud.set_paused(false)
	tray_bounce_streak = 0            # FL-02
	_juggle_bonus_given = false
	_last_ui_signature = []           # P1-2: first emit of a run always fires
	_bridge_accum = 0.0

	level = 1
	knife_count = Session.get_starting_knives()
	hearts = Session.get_max_hearts()
	score = 0
	pending_stars = 0
	knives_to_spawn = 0
	state = GameConstants.GameState.AIMING
	dragging = false
	paddle_dragging = false
	paddle_x = GameConstants.CANVAS_WIDTH * 0.5
	fire_x = paddle_x
	trauma = 0.0
	zoom_kick = 0.0
	shake_direction = Vector2.ZERO
	hit_reaction_remaining = 0.0
	hitstop_remaining = 0.0
	impact_bursts.clear()
	vfx_particles.clear()
	bg_particles.clear()
	world.position = Vector2.ZERO
	world.rotation = 0.0
	world.scale = Vector2.ONE
	world.modulate = Color.WHITE
	player.scale = Vector2.ONE
	player.modulate = Color(1.0, 1.0, 1.0, 1.0)
	player.set_state("idle")
	hit_combo = 0
	combo_timer = 0.0
	combo_best = 0
	item_slots.clear()
	item_timers.clear()
	item_orbs.clear()
	stages_since_item_drop = 0
	_blast_in_progress = false
	# Run-scoped modifiers reset with the run; the x2 toggle is a player
	# preference and survives across runs.
	coin_shards.clear()
	_coin_streak = 0
	run_damage_bonus = 0
	group_dmg_bonus = 0
	run_speed_mult = 1.0
	run_tray_bonus = 0.0
	run_buffs.clear()
	revive_count = 0
	_burst_destroy_count = 0
	_burst_destroy_timer = 0.0
	levelup_open = false
	hud.hide_levelup()
	_cleanup_boss()
	overlay_reset.emit()
	_clear_all_knives()
	LevelGen.init_level(self, level)
	stars_total = _get_stars_left()
	_init_boss_if_needed()
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
		_start_new_run()
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
	hit_combo = 0
	combo_timer = 0.0
	tray_bounce_streak = 0  # FL-02: juggle streak is per volley
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
	var velocity := Vector2(cos(aim_angle), sin(aim_angle)) * Session.get_knife_speed() * run_speed_mult
	knife.configure(Vector2(fire_x, paddle_y - GameConstants.PADDLE_Y_OFFSET), velocity, false)
	player.play_output(aim_angle)
	_kick_world(-velocity.normalized(), 2.0, 0.05)
	_burst_feedback(knife.position, Color(1.0, 0.78, 0.25, 0.82), 12.0, GameConstants.FLASH_LIFE)
	AudioManager.play("knife_launch")


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

		# TimeWeaver boss: slow knives inside time zones
		var effective_delta := delta
		if current_boss != null and not current_boss.is_defeated():
			effective_delta *= current_boss.get_time_slow_factor(knife.position)
		knife.step(effective_delta)
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
					AudioManager.play("tray_bounce")
					_add_trauma(0.12)
					Haptics.light()
					_register_tray_bounce()

		knife.set_velocity(velocity)

		if knife.position.y >= GameConstants.BOTTOM_Y:
			knife.deactivate()
			continue

		if current_boss != null and not current_boss.is_defeated():
			_check_boss_collision(knife)
		_check_block_collision(knife, blocks_layer)
		_check_block_collision(knife, moving_blocks_layer)


# FL-02: active paddle play. Each tray bounce keeps the combo window alive and
# pays a sliver of score; a sustained juggle streak banks one bonus knife per
# stage. The aim: SHOOTING stops being spectator time without warping balance.
func _register_tray_bounce() -> void:
	score += TRAY_BOUNCE_SCORE
	if hit_combo > 0:
		combo_timer = maxf(combo_timer, Session.get_combo_window() * 0.6)
	tray_bounce_streak += 1
	if tray_bounce_streak >= TRAY_JUGGLE_STREAK_TARGET and not _juggle_bonus_given:
		_juggle_bonus_given = true
		knife_count += 1
		hud.show_toast("JUGGLE! +1 KNIFE", GameConstants.GLOW_REWARD)
		AudioManager.play("block_destroy_star", 1.2)
	_emit_ui_update()


func _check_block_collision(knife: Knife, container: Node2D) -> void:
	if not knife.active:
		return

	for child in container.get_children():
		var block := child as Block
		if block == null or block.is_destroyed():
			continue

		# P1-3 broad-phase: skip blocks more than a block-size away on either
		# axis before doing AABB clamp + sqrt. Conservative — the true max hit
		# range is half a block plus the knife radius.
		if absf(block.position.x - knife.position.x) > GameConstants.BLOCK_WIDTH + knife.radius:
			continue
		if absf(block.position.y - knife.position.y) > GameConstants.BLOCK_HEIGHT + knife.radius:
			continue

		# World-local AABB vs world-local knife.position — invariant to the
		# cosmetic shake/rotation/zoom now applied to the `world` node.
		var rect := block.get_local_aabb()
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
			# Direction the knife drove into the block (opposite the surface normal).
			var impact_dir := -normal

			# Pierce: knife passes through without bouncing
			if _pierce_active():
				knife.position += normal * overlap
			else:
				knife.position += normal * overlap
				var velocity := knife.velocity
				if absf(normal.x) > absf(normal.y):
					velocity.x = -velocity.x
				else:
					velocity.y = -velocity.y
				knife.set_velocity(velocity)

			_hit_block(block, impact_dir)

			# Spread: spawn 2 mini-knives on hit
			if _has_active_item(GameConstants.ItemType.SPREAD):
				var base_angle := knife.velocity.angle()
				_spawn_mini_knife(block.global_position, base_angle + 0.6)
				_spawn_mini_knife(block.global_position, base_angle - 0.6)

			return


func _hit_block(block: Block, impact_dir: Vector2 = Vector2.ZERO) -> void:
	var remaining_hp := block.take_damage(_get_knife_damage(), impact_dir)
	_register_combo_hit()
	var hit_color := block.get_hit_color()
	_burst_feedback(block.global_position, hit_color, 14.0, GameConstants.HIT_BURST_LIFE)
	_spawn_hit_vfx(block.global_position, hit_color)
	# Directional sparks fly back out along the surface normal (-impact_dir).
	if impact_dir.length_squared() > 0.0001:
		_spawn_impact_sparks(block.global_position, -impact_dir, hit_color)
	AudioManager.play("block_hit", _combo_pitch())
	Haptics.light()
	if remaining_hp <= 0:
		_destroy_block(block)
	else:
		# Micro hit-stop on a non-destroying hit; grows slightly with combo tier.
		_add_hitstop(HITSTOP_HIT + HITSTOP_COMBO_STEP * float(_get_combo_tier()))


func _destroy_block(block: Block) -> void:
	var block_type := block.block_type
	var bpos: Vector2 = block.global_position
	# Heavier hit-stop on destruction; combo tier adds weight.
	# POW/boss freezes stack further on top via _freeze_frame().
	_add_hitstop(HITSTOP_DESTROY + HITSTOP_COMBO_STEP * float(_get_combo_tier()))
	var pitch := _combo_pitch()
	if block_type == GameConstants.BLOCK_STAR:
		pending_stars += 1
		AudioManager.play("block_destroy_star", pitch)
		AudioManager.play("block_subthump", pitch)
		_add_trauma(0.22)
		_camera_punch(0.012)
		Haptics.medium()
	elif block_type == GameConstants.BLOCK_POW:
		var pow_count := Session.get_pow_count()
		for index in range(pow_count):
			var angle := (float(index) / float(pow_count)) * TAU
			_spawn_mini_knife(block.position, angle)
		_flash_screen(Color(1.0, 0.25, 1.0, 1.0), 0.55, 0.14)
		_freeze_frame(0.05)
		AudioManager.play("block_destroy_pow", pitch)
		AudioManager.play("block_subthump", pitch * 0.85, 2.0)
		_add_trauma(0.42)
		_camera_punch(ZOOM_KICK_MAX)
		Haptics.heavy()
	else:
		AudioManager.play("block_destroy_normal", pitch)
		AudioManager.play("block_subthump", pitch)
		_add_trauma(0.22)
		_camera_punch(0.012)
		Haptics.medium()

	_spawn_destroy_vfx(bpos, block_type)
	# VX-03: elite kills read a tier above normal destroys.
	if block_type == GameConstants.BLOCK_RED_ENEMY:
		_spawn_bubble_pop(bpos, false)
	# Kill chain (reference spec): pop → loot shards next frame → counter punch
	# on collect. Every destroy gets a loot moment.
	_spawn_coin_shards(bpos, block_type)
	_register_burst_destroy()
	var base_score := 100
	var multiplier := _get_combo_multiplier()
	score += int(float(base_score) * multiplier)
	if multiplier > 1.0:
		_spawn_combo_text(bpos, multiplier)

	# Blast: AoE damage to nearby blocks
	if _has_active_item(GameConstants.ItemType.BLAST):
		_blast_aoe(bpos, 80.0)

	# Item drop chance (with pity system + upgrade)
	var drop_chance := GameConstants.ITEM_DROP_BASE + Session.get_item_drop_bonus()
	if block_type == GameConstants.BLOCK_RED_ENEMY:
		drop_chance = GameConstants.ITEM_DROP_ENEMY + Session.get_item_drop_bonus()
	if stages_since_item_drop >= GameConstants.ITEM_PITY_STAGES:
		drop_chance += 0.15
	if randf() < drop_chance:
		_spawn_item_orb(bpos)

	# Coins + stats
	Session.total_blocks_destroyed += 1
	if block_type == GameConstants.BLOCK_RED_ENEMY:
		Session.total_enemies_destroyed += 1
		Session.add_coins(25)
	else:
		Session.add_coins(10)

	block.queue_free()
	_emit_ui_update()


func _update_red_enemies(delta: float) -> void:
	var bottom_rect := _get_bottom_rect()
	var to_remove: Array[Block] = []

	for child in moving_blocks_layer.get_children():
		var block := child as Block
		if block == null or block.block_type != GameConstants.BLOCK_RED_ENEMY or block.is_destroyed():
			continue

		var speed_mult := 0.4 if _has_active_item(GameConstants.ItemType.SLOW) else 1.0
		block.advance_enemy(delta * speed_mult)
		# World-local rect vs the world-local bottom band — unaffected by shake.
		var rect := block.get_local_aabb()
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
		# Shield: absorb one enemy hit
		if _has_active_item(GameConstants.ItemType.SHIELD):
			_consume_item(GameConstants.ItemType.SHIELD)
			_burst_feedback(block.global_position, Color(0.30, 1.0, 0.55, 1.0), 20.0, 0.28)
			_flash_screen(Color(0.30, 1.0, 0.55, 1.0), 0.3, 0.12)
			AudioManager.play("block_destroy_star")
		else:
			hearts -= 1
			_burst_feedback(block.global_position, Color(0.94, 0.27, 0.27, 1.0), 18.0, 0.24)
			_play_hit_reaction()
			AudioManager.play("enemy_warning")
		block.queue_free()
		_emit_ui_update()
		if hearts <= 0:
			_trigger_game_over()
			return


func _check_win_lose() -> void:
	# Boss stage: win when boss is defeated (and all segments for Splitter)
	if is_boss_stage:
		if current_boss != null and current_boss.is_defeated():
			if current_boss.boss_type == GameConstants.BossType.SPLITTER and current_boss.are_segments_alive():
				pass  # Main body dead but segments remain — keep fighting
			else:
				_trigger_boss_defeated()
				return
	else:
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

	# Boss phase 3 descend: if boss touches bottom, game over
	if current_boss != null and not current_boss.is_defeated():
		if current_boss.position.y + current_boss.get_body_size().y * 0.5 > GameConstants.CANVAS_HEIGHT - 40.0:
			_trigger_game_over()


func _trigger_stage_clear() -> void:
	if state == GameConstants.GameState.STAGE_CLEAR:
		return

	# Settle a pending group-kill burst before leaving SHOOTING — a stage-ending
	# wipe is exactly the burst the bonus exists to reward.
	if _burst_destroy_timer > 0.0:
		_update_group_kill(_burst_destroy_timer + 0.001)

	state = GameConstants.GameState.STAGE_CLEAR
	_clear_all_knives()
	if not spawn_timer.is_stopped():
		spawn_timer.stop()
	knife_count += pending_stars
	pending_stars = 0
	player.scale = Vector2.ONE
	hit_combo = 0
	combo_timer = 0.0
	item_orbs.clear()
	stages_since_item_drop += 1
	_flash_screen(Color(0.35, 1.0, 0.55, 1.0), 0.6, 0.24)
	AudioManager.play("stage_clear")
	_emit_ui_update()
	_run_stage_clear_sequence()


func _run_stage_clear_sequence() -> void:
	# 0.0s — freeze frame (non-awaited, runs up to its own await)
	_freeze_frame(0.15)

	# 0.05s — show overlay with bounce animation
	await get_tree().create_timer(0.05, true, false, true).timeout
	var heart_bonus := hearts * GameConstants.HEART_BONUS_KNIVES
	stage_cleared.emit(level + 1, heart_bonus)

	# 0.3s — sequential block explosion top→bottom
	await get_tree().create_timer(0.25, true, false, true).timeout
	var remaining := _get_remaining_blocks_sorted()
	for block in remaining:
		if is_instance_valid(block) and not block.is_destroyed():
			var bpos: Vector2 = block.global_position
			_spawn_destroy_vfx(bpos, block.block_type)
			_burst_feedback(bpos, Color(0.35, 1.0, 0.55, 0.8), 10.0, 0.18)
			score += 50
			block.queue_free()
			AudioManager.play("block_destroy_normal")
			_emit_ui_update()
		await get_tree().create_timer(0.05, true, false, true).timeout

	# Add heart bonus knives after explosions
	knife_count += heart_bonus
	_emit_ui_update()

	# Level-up 3-card pick (reference: レベルアップ!!). The chosen handler
	# advances to the next level on the same frame the card is tapped.
	await get_tree().create_timer(0.6, true, false, true).timeout
	if state != GameConstants.GameState.STAGE_CLEAR:
		return
	_open_levelup()


func _trigger_game_over() -> void:
	if state == GameConstants.GameState.GAME_OVER:
		return

	state = GameConstants.GameState.GAME_OVER
	if not spawn_timer.is_stopped():
		spawn_timer.stop()
	_clear_all_knives()
	hit_reaction_remaining = 0.0
	Session.submit_run(score, level, combo_best)
	Session.add_coins(100 * level)
	AudioManager.play("game_over")
	AudioManager.stop_music()
	_emit_ui_update()
	_run_game_over_sequence()


func _run_game_over_sequence() -> void:
	# 0.0s — slow motion + desaturate
	Engine.time_scale = 0.3
	var desat_tw := create_tween()
	desat_tw.tween_property(world, "modulate", Color(0.55, 0.55, 0.60, 1.0), 0.15)

	# 0.5s real time — restore time scale
	await get_tree().create_timer(0.5, true, false, true).timeout
	Engine.time_scale = 1.0
	if state != GameConstants.GameState.GAME_OVER:
		return  # player already tapped to restart during the slow-mo window

	# Brief red flash then show overlay
	_flash_screen(Color(0.85, 0.15, 0.15, 1.0), 0.65, 0.28)
	await get_tree().create_timer(0.1, true, false, true).timeout
	if state != GameConstants.GameState.GAME_OVER:
		return
	game_overed.emit(score, level, Session.best_score, Session.best_stage, _get_revive_cost(), _can_revive())


func _get_revive_cost() -> int:
	# First revive costs the base; each subsequent one in the same run costs more.
	return GameConstants.REVIVE_BASE_COST * (revive_count + 1)


func _can_revive() -> bool:
	return Session.coins >= _get_revive_cost()


# Coin-revive: continue the SAME run/stage instead of resetting to stage 1.
# Wired to hud.revive_requested (the game-over REVIVE button).
func revive() -> void:
	if state != GameConstants.GameState.GAME_OVER:
		return
	if not Session.try_spend_coins(_get_revive_cost()):
		return
	revive_count += 1

	# Undo the game-over sequence's slow-mo + desaturation.
	Engine.time_scale = 1.0
	world.modulate = Color.WHITE
	hit_reaction_remaining = 0.0
	hitstop_remaining = 0.0
	player.modulate = Color(1.0, 1.0, 1.0, 1.0)
	player.set_state("idle")

	# Give a fighting chance: 1 heart + a fresh batch of knives. Covers both the
	# "hearts ran out" and "knives ran out / stuck" game-over paths.
	hearts = maxi(1, hearts)
	knife_count = maxi(knife_count, GameConstants.REVIVE_KNIVES)

	# If the boss had descended to the kill line, nudge it back up so the player
	# isn't instantly re-killed on the next frame.
	if current_boss != null and is_instance_valid(current_boss) and not current_boss.is_defeated():
		var kill_y := GameConstants.CANVAS_HEIGHT - 40.0 - current_boss.get_body_size().y * 0.5
		if current_boss.position.y > kill_y - 80.0:
			current_boss.position.y = kill_y - 80.0

	hud.hide_overlay()
	state = GameConstants.GameState.AIMING
	AudioManager.play_music("boss" if is_boss_stage else "play")
	_emit_ui_update()


func _play_hit_reaction() -> void:
	hit_reaction_remaining = 0.6
	_kick_world(Vector2(0.0, -1.0), 4.0, 0.18)
	_camera_punch(ZOOM_KICK_MAX)
	Haptics.heavy()
	player.modulate = Color(1.0, 0.45, 0.45, 1.0)
	_flash_screen(Color(1.0, 0.3, 0.3, 1.0), 0.4, 0.12)


func _kick_world(direction: Vector2, strength: float, duration: float) -> void:
	# Back-compat shim: legacy callers pass a strength (~2/3/4) + duration; we map
	# strength onto a trauma increment (2→0.2, 3→0.3, 4→0.4) and keep a directional
	# bias. `duration` is no longer needed — trauma decays on its own curve.
	if direction.length_squared() <= 0.0001:
		shake_direction = Vector2.ZERO
	else:
		shake_direction = direction.normalized()
	_add_trauma(strength * 0.1)


func _add_trauma(amount: float) -> void:
	if amount <= 0.0:
		return
	trauma = clampf(trauma + amount, 0.0, TRAUMA_MAX)


func _camera_punch(amount: float) -> void:
	zoom_kick = clampf(maxf(zoom_kick, amount), 0.0, ZOOM_KICK_MAX)


func _update_effects(delta: float) -> void:
	if hit_reaction_remaining > 0.0 and state != GameConstants.GameState.GAME_OVER:
		hit_reaction_remaining = maxf(0.0, hit_reaction_remaining - delta)
		if is_zero_approx(hit_reaction_remaining):
			player.modulate = Color(1.0, 1.0, 1.0, 1.0)

	_update_shake(delta)

	for index in range(impact_bursts.size() - 1, -1, -1):
		var burst: Dictionary = impact_bursts[index]
		burst["life"] = float(burst["life"]) - delta
		if float(burst["life"]) <= 0.0:
			impact_bursts.remove_at(index)
		else:
			impact_bursts[index] = burst


func _update_shake(delta: float) -> void:
	# Decay trauma + zoom punch on their own curves.
	if trauma > 0.0:
		trauma = maxf(0.0, trauma - TRAUMA_DECAY * delta)
	if zoom_kick > 0.0:
		zoom_kick = maxf(0.0, zoom_kick - ZOOM_KICK_DECAY * delta)

	# Rest pose: snap cleanly back to identity so nothing drifts.
	if trauma <= 0.0 and zoom_kick <= 0.0:
		if world.position != Vector2.ZERO or world.rotation != 0.0 or world.scale != Vector2.ONE:
			world.position = Vector2.ZERO
			world.rotation = 0.0
			world.scale = Vector2.ONE
		return

	# P6: reduce-motion accessibility scales shake/zoom amplitude (1.0 full · 0.5 low · 0.0 off).
	var motion := Session.shake_scale
	var amt := trauma * trauma * motion  # trauma² — soft ramp, smooth tail
	_shake_seed_t += delta * 28.0

	# Smooth (non-buzzing) noise offset, biased opposite the impact direction.
	var noise_off := Vector2(
		_shake_noise.get_noise_2d(_shake_seed_t, 0.0),
		_shake_noise.get_noise_2d(0.0, _shake_seed_t)
	)
	var offset := (noise_off * (1.0 - SHAKE_DIR_BIAS) + shake_direction * SHAKE_DIR_BIAS) \
		* SHAKE_MAX_OFFSET * amt
	var roll := _shake_noise.get_noise_2d(_shake_seed_t, _shake_seed_t) * SHAKE_MAX_ROLL * amt
	var s := 1.0 + zoom_kick * motion

	# Pivot rotation + zoom about the canvas centre so the playfield doesn't
	# lurch toward a corner. global = pos + R·(s·p); keep centre C fixed.
	var c := GameConstants.CANVAS_SIZE * 0.5
	var cosv := cos(roll)
	var sinv := sin(roll)
	var rc := Vector2(c.x * cosv - c.y * sinv, c.x * sinv + c.y * cosv) * s
	world.rotation = roll
	world.scale = Vector2(s, s)
	world.position = c - rc + offset


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
	# P1-2: 25+ call sites often re-emit identical data; skip when nothing the
	# HUD or web bridge consumes has changed. Real changes still emit (and
	# serialize) on the same tick, so event timing is unchanged.
	var signature: Array = [hearts, knife_count, score, level, state, _get_stars_left(),
		stars_total, hit_combo, combo_timer, combo_best, item_slots, item_timers,
		group_dmg_bonus, run_buffs, game_paused]
	if signature == _last_ui_signature:
		return
	_last_ui_signature = signature.duplicate(true)
	ui_updated.emit({
		"hearts": hearts,
		"knife_count": knife_count,
		"score": score,
		"level": level,
		"state": state,
		"stars_left": _get_stars_left(),
		"stars_total": stars_total,
		"combo": hit_combo,
		"combo_timer": combo_timer,
		"combo_best": combo_best,
		"item_slots": item_slots.duplicate(),
		"item_timers": item_timers.duplicate(),
		"group_dmg_bonus": group_dmg_bonus,
		"run_buffs": run_buffs.duplicate(),
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
	var pw := Session.get_paddle_width() + run_tray_bonus
	return Rect2(
		Vector2(paddle_x - pw * 0.5, paddle_y - GameConstants.PADDLE_Y_OFFSET),
		Vector2(pw, 14.0)
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


# ─── VX-01: wet-ground fake reflection (duckflock ph.4) ──────────────────────
# Every solid object drops a soft, darkened mirror silhouette just below it,
# so the dark playfield reads as a glossy wet floor like the reference
# footage. Pure draw-pass cosmetics: nothing here touches AABBs or sim state.

const REFLECT_ALPHA_BLOCK := 0.085
const REFLECT_ALPHA_KNIFE := 0.07
const REFLECT_OFFSET := 6.0      # gap between object base and its mirror
const REFLECT_SQUASH := 0.55     # mirror height as a fraction of the object


func _draw_wet_reflections() -> void:
	# Blocks — static grid and descending enemies alike.
	for container in [blocks_layer, moving_blocks_layer]:
		for child in container.get_children():
			var block := child as Block
			if block == null or block.is_destroyed():
				continue
			var rect := block.get_local_aabb()
			var mirror_h := rect.size.y * REFLECT_SQUASH
			var top := rect.position.y + rect.size.y + REFLECT_OFFSET
			var col := block.get_hit_color()
			col = Color(col.r * 0.35, col.g * 0.35, col.b * 0.45, REFLECT_ALPHA_BLOCK)
			# Two stacked rects fake a blurred falloff without a real blur pass.
			draw_rect(Rect2(rect.position.x + 2.0, top, rect.size.x - 4.0, mirror_h), col)
			var col_far := col
			col_far.a *= 0.45
			draw_rect(Rect2(rect.position.x + 5.0, top + mirror_h * 0.6,
				rect.size.x - 10.0, mirror_h * 0.55), col_far)

	# Boss — one large mirror sells the floor on boss stages.
	if current_boss != null and is_instance_valid(current_boss) and not current_boss.is_defeated():
		var bs := current_boss.get_body_size()
		var bcol: Color = current_boss.boss_color
		bcol = Color(bcol.r * 0.35, bcol.g * 0.35, bcol.b * 0.45, REFLECT_ALPHA_BLOCK + 0.02)
		draw_rect(Rect2(current_boss.position.x - bs.x * 0.5 + 3.0,
			current_boss.position.y + bs.y * 0.5 + REFLECT_OFFSET,
			bs.x - 6.0, bs.y * REFLECT_SQUASH), bcol)

	# Knives — a faint glint trailing under each active blade.
	for child in knives_layer.get_children():
		var knife := child as Knife
		if knife == null or not knife.active:
			continue
		var kcol := Color(0.60, 0.75, 0.90, REFLECT_ALPHA_KNIFE)
		var base := knife.position + Vector2(0.0, 14.0 + REFLECT_OFFSET)
		draw_line(base + Vector2(-4.0, 0.0), base + Vector2(4.0, 0.0), kcol, 2.0)
		var kcol_far := kcol
		kcol_far.a *= 0.5
		draw_line(base + Vector2(-2.0, 3.0), base + Vector2(2.0, 3.0), kcol_far, 1.5)

	# Player — contact sheen anchors the character to the wet floor.
	var pcol := Color(0.55, 0.85, 1.0, 0.10)
	var py := paddle_y + 22.0
	draw_line(Vector2(paddle_x - 20.0, py), Vector2(paddle_x + 20.0, py), pcol, 3.0)
	var pcol_far := pcol
	pcol_far.a = 0.05
	draw_line(Vector2(paddle_x - 12.0, py + 4.0), Vector2(paddle_x + 12.0, py + 4.0), pcol_far, 2.0)


# ─── CEL-02: fake-3D slab depth (cel 2.5D pass, 2026-06-13) ──────────────────
# Card blocks read as thick cel tiles: a bottom face plus a perspective side
# face extruded away from the canvas-centre vanishing point (one-point
# perspective on x, cheated constant depth on y), grounded by a purple-ink
# key-light drop shadow. The maid, boss and falling blobs get soft contact
# shadows so every body sits on the same floor. Pure draw-pass cosmetics —
# nothing here touches AABBs, HP or sim state (see tools/test_cel_25d.py).


func _draw_block_depth() -> void:
	var half_w := GameConstants.CANVAS_WIDTH * 0.5
	for container in [blocks_layer, moving_blocks_layer]:
		for child in container.get_children():
			var block := child as Block
			if block == null or block.is_destroyed():
				continue
			var rect := block.get_local_aabb()
			if block.block_type == GameConstants.BLOCK_RED_ENEMY:
				# Organic blob: no rectangular slab (the enemy_cel shader gives
				# the body its depth). A drop shadow cast down-right of the
				# top-left key light lifts the blob off the floor; a tighter
				# contact ellipse grounds it.
				var ecx := rect.position.x + rect.size.x * 0.5
				var ebase := rect.position.y + rect.size.y
				_draw_contact_shadow(Vector2(ecx + 5.0, ebase + 7.0), rect.size.x * 0.40)
				_draw_contact_shadow(Vector2(ecx + 1.0, ebase + 2.0), rect.size.x * 0.30)
				continue
			var cx := rect.position.x + rect.size.x * 0.5
			# Back face shifts toward the vanishing point: blocks left of
			# centre show their right face, blocks right of centre their left.
			var side_dx := clampf((half_w - cx) * GameConstants.CEL_SLAB_PERSPECTIVE,
				-GameConstants.CEL_SLAB_MAX_SIDE, GameConstants.CEL_SLAB_MAX_SIDE)
			var t := GameConstants.CEL_SLAB_THICKNESS
			var l := rect.position.x
			var r := rect.position.x + rect.size.x
			var top := rect.position.y
			var bottom := rect.position.y + rect.size.y
			var side_col: Color = GameConstants.CEL_SIDE_COLORS.get(
				block.block_type, GameConstants.CEL_INK)

			# Key-light drop shadow under the whole slab — two stacked rects
			# fake a soft falloff, same trick as the wet reflections.
			var sh := GameConstants.CEL_SHADOW_COLOR
			sh.a = GameConstants.CEL_SHADOW_ALPHA
			draw_rect(Rect2(l + 3.0 + side_dx * 0.6, top + t + 6.0,
				rect.size.x - 2.0, rect.size.y - 4.0), sh)
			var sh_far := sh
			sh_far.a *= 0.4
			draw_rect(Rect2(l + 1.0 + side_dx * 0.6, top + t + 9.0,
				rect.size.x + 2.0, rect.size.y - 2.0), sh_far)

			# Bottom face: always visible (cheated downward depth).
			var bottom_col := Color(side_col.r * 0.72, side_col.g * 0.72, side_col.b * 0.78, 1.0)
			draw_colored_polygon(PackedVector2Array([
				Vector2(l, bottom), Vector2(r, bottom),
				Vector2(r + side_dx, bottom + t), Vector2(l + side_dx, bottom + t),
			]), bottom_col)

			# Side face: faces the centre aisle; lit when it points at the
			# top-left key light (left faces), shaded otherwise (right faces).
			if absf(side_dx) >= 0.5:
				var face_x := r if side_dx > 0.0 else l
				var lit := side_dx < 0.0
				var face_mul := 1.12 if lit else 0.80
				var face_col := Color(side_col.r * face_mul, side_col.g * face_mul,
					side_col.b * face_mul, 1.0)
				draw_colored_polygon(PackedVector2Array([
					Vector2(face_x, top), Vector2(face_x, bottom),
					Vector2(face_x + side_dx, bottom + t), Vector2(face_x + side_dx, top + t),
				]), face_col)

	# Boss: one large contact shadow grounds the arena body.
	if current_boss != null and is_instance_valid(current_boss) and not current_boss.is_defeated():
		var bs := current_boss.get_body_size()
		_draw_contact_shadow(current_boss.position + Vector2(0.0, bs.y * 0.5 + 4.0), bs.x * 0.46)

	# Maid: elliptical contact shadow under her feet anchors her to the floor.
	_draw_contact_shadow(Vector2(paddle_x, paddle_y + 20.0), 24.0)


func _draw_contact_shadow(center: Vector2, radius: float) -> void:
	var col := GameConstants.CEL_SHADOW_COLOR
	col.a = GameConstants.CEL_SHADOW_ALPHA * 0.85
	draw_set_transform(center, 0.0, Vector2(1.0, 0.34))
	draw_circle(Vector2.ZERO, radius, Color(col.r, col.g, col.b, col.a * 0.45))
	draw_circle(Vector2.ZERO, radius * 0.62, col)
	draw_set_transform_matrix(Transform2D.IDENTITY)


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


func _get_remaining_blocks_sorted() -> Array:
	var result: Array = []
	for container in [blocks_layer, moving_blocks_layer]:
		for child in container.get_children():
			var block := child as Block
			if block != null and not block.is_destroyed():
				result.append(block)
	result.sort_custom(func(a: Block, b: Block) -> bool: return a.position.y < b.position.y)
	return result


func _on_stage_timer_timeout() -> void:
	if state != GameConstants.GameState.STAGE_CLEAR:
		return
	level += 1
	_juggle_bonus_given = false  # FL-02: one juggle bonus per stage
	state = GameConstants.GameState.AIMING
	dragging = false
	paddle_dragging = false
	paddle_x = GameConstants.CANVAS_WIDTH * 0.5
	fire_x = paddle_x
	player.scale = Vector2.ONE
	player.modulate = Color(1.0, 1.0, 1.0, 1.0)
	_cleanup_boss()
	overlay_reset.emit()
	_clear_all_knives()
	LevelGen.init_level(self, level)
	stars_total = _get_stars_left()
	_init_boss_if_needed()
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
		"paused": game_paused,
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
		"combo": hit_combo,
		"combo_timer": snappedf(combo_timer, 0.01),
		"item_slots": item_slots,
		"item_orbs_count": item_orbs.size(),
		"stars_total": stars_total,
		"game_speed": game_speed,
		"levelup_open": levelup_open,
		"run_damage_bonus": run_damage_bonus,
		"group_dmg_bonus": group_dmg_bonus,
		"run_speed_mult": snappedf(run_speed_mult, 0.01),
		"run_tray_bonus": run_tray_bonus,
		"run_buffs": run_buffs,
		"coin_shards_count": coin_shards.size(),
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


# ─── Combo system ──────────────────────────────────────────────────────────

func _register_combo_hit() -> void:
	var tier_before := _get_combo_tier()
	hit_combo += 1
	combo_timer = Session.get_combo_window()
	if hit_combo > combo_best:
		combo_best = hit_combo
	# Tier crossings get a toast so milestones read without watching the gauge.
	var tier_after := _get_combo_tier()
	if tier_after > tier_before:
		var mult: float = GameConstants.COMBO_MULTIPLIERS[mini(tier_after, GameConstants.COMBO_MULTIPLIERS.size() - 1)]
		var color: Color = GameConstants.COMBO_COLORS[mini(tier_after, GameConstants.COMBO_COLORS.size() - 1)]
		hud.show_toast("COMBO x%.1f!" % mult, color)
	_emit_ui_update()


func _update_combo_timer(delta: float) -> void:
	if combo_timer > 0.0:
		combo_timer = maxf(0.0, combo_timer - delta)
		if is_zero_approx(combo_timer) and hit_combo > 0:
			hit_combo = 0
			_emit_ui_update()


func _get_combo_multiplier() -> float:
	var tiers := GameConstants.COMBO_TIERS
	var mults := GameConstants.COMBO_MULTIPLIERS
	for i in range(tiers.size() - 1, -1, -1):
		if hit_combo >= tiers[i]:
			return mults[i + 1]
	return mults[0]


func _get_combo_tier() -> int:
	var tiers := GameConstants.COMBO_TIERS
	for i in range(tiers.size() - 1, -1, -1):
		if hit_combo >= tiers[i]:
			return i + 1
	return 0


func _combo_pitch() -> float:
	# Each chained hit nudges the pitch up; resets when the combo lapses.
	# +3% per hit, capped at 12 steps (~+36%) so it stays musical.
	return 1.0 + float(mini(hit_combo, 12)) * 0.03


func _spawn_combo_text(at: Vector2, multiplier: float) -> void:
	var tier := _get_combo_tier()
	var color: Color = GameConstants.COMBO_COLORS[mini(tier, GameConstants.COMBO_COLORS.size() - 1)]
	# Use VFX particles as floating text indicators
	vfx_particles.append({
		"x": at.x,
		"y": at.y - 12.0,
		"vx": 0.0,
		"vy": -40.0,
		"radius": 6.0 + float(tier) * 1.5,
		"color": color,
		"life": 0.55,
		"max_life": 0.55,
		"shape": "star",
	})


# ─── Item system ───────────────────────────────────────────────────────────

func _update_item_timers(delta: float) -> void:
	var changed := false
	for i in range(item_timers.size() - 1, -1, -1):
		item_timers[i] -= delta
		if item_timers[i] <= 0.0:
			item_slots.remove_at(i)
			item_timers.remove_at(i)
			changed = true
	if changed:
		_emit_ui_update()


func _spawn_item_orb(at: Vector2) -> void:
	var pool: Array[int] = [
		GameConstants.ItemType.PIERCE,
		GameConstants.ItemType.SPREAD,
		GameConstants.ItemType.MAGNET,
		GameConstants.ItemType.BLAST,
		GameConstants.ItemType.SHIELD,
		GameConstants.ItemType.SLOW,
	]
	var item_type: int = pool[randi() % pool.size()]
	item_orbs.append({
		"x": at.x,
		"y": at.y,
		"vy": GameConstants.ITEM_ORB_SPEED,
		"type": item_type,
		"life": 6.0,
		"pulse": 0.0,
	})
	stages_since_item_drop = 0


func _update_item_orbs(delta: float) -> void:
	var tray_rect := _get_tray_rect()
	for i in range(item_orbs.size() - 1, -1, -1):
		var orb: Dictionary = item_orbs[i]
		orb["y"] = float(orb["y"]) + float(orb["vy"]) * delta
		orb["life"] = float(orb["life"]) - delta
		orb["pulse"] = float(orb["pulse"]) + delta

		# Collect if near paddle
		var ox := float(orb["x"])
		var oy := float(orb["y"])
		var dist_to_paddle := Vector2(ox - paddle_x, oy - paddle_y).length()

		# Magnet effect: if active, pull orbs toward paddle
		if _has_active_item(GameConstants.ItemType.MAGNET):
			var pull_dir := Vector2(paddle_x - ox, paddle_y - oy).normalized()
			orb["x"] = ox + pull_dir.x * 120.0 * delta
			orb["y"] = float(orb["y"]) + pull_dir.y * 120.0 * delta
			dist_to_paddle = Vector2(float(orb["x"]) - paddle_x, float(orb["y"]) - paddle_y).length()

		if dist_to_paddle < 32.0:
			_collect_item(int(orb["type"]))
			_burst_feedback(Vector2(float(orb["x"]), float(orb["y"])),
				GameConstants.ITEM_COLORS.get(int(orb["type"]), Color.WHITE), 16.0, 0.22)
			AudioManager.play("block_destroy_star")
			item_orbs.remove_at(i)
			continue

		# Remove if off-screen or expired
		if float(orb["y"]) > GameConstants.CANVAS_HEIGHT + 20.0 or float(orb["life"]) <= 0.0:
			item_orbs.remove_at(i)
			continue

		item_orbs[i] = orb


func _collect_item(item_type: int) -> void:
	Session.total_items_collected += 1
	if item_slots.size() < Session.get_item_max_slots():
		item_slots.append(item_type)
		item_timers.append(GameConstants.ITEM_DURATION)
	else:
		# Replace oldest slot
		item_slots[0] = item_type
		item_timers[0] = GameConstants.ITEM_DURATION
	var item_name: String = GameConstants.ITEM_NAMES.get(item_type, "?")
	hud.show_toast("%s %ds" % [item_name, int(GameConstants.ITEM_DURATION)],
		GameConstants.ITEM_COLORS.get(item_type, Color.WHITE))
	_emit_ui_update()


func _has_active_item(item_type: int) -> bool:
	for i in range(item_slots.size()):
		if item_slots[i] == item_type and item_timers[i] > 0.0:
			return true
	return false


func _consume_item(item_type: int) -> void:
	for i in range(item_slots.size()):
		if item_slots[i] == item_type:
			item_slots.remove_at(i)
			item_timers.remove_at(i)
			_emit_ui_update()
			return


func _blast_aoe(center: Vector2, radius: float) -> void:
	if _blast_in_progress:
		return  # prevent infinite recursion (Blast triggers _destroy_block which triggers Blast)
	_blast_in_progress = true
	var hit_any := false
	for container in [blocks_layer, moving_blocks_layer]:
		for child in container.get_children():
			var block := child as Block
			if block == null or block.is_destroyed():
				continue
			if block.global_position.distance_to(center) <= radius:
				# Blast follows the run-scoped damage model, same as direct knife hits.
				block.take_damage(_get_knife_damage())
				_burst_feedback(block.global_position, Color(1.0, 0.35, 0.15, 0.7), 10.0, 0.14)
				hit_any = true
				if block.is_destroyed():
					_destroy_block(block)
	_blast_in_progress = false
	if hit_any:
		_vfx_ring(center, Color(1.0, 0.25, 0.15, 0.65), 0.35)
		AudioManager.play("block_destroy_pow")


# ─── Boss system ───────────────────────────────────────────────────────────

func _init_boss_if_needed() -> void:
	is_boss_stage = LevelGen.is_boss_stage(level)
	if not is_boss_stage:
		AudioManager.play_music("play")  # back to normal track (no-op if already playing)
		return

	var boss_type := LevelGen.get_boss_type(level)
	current_boss = Boss.new()
	current_boss.position = Vector2(GameConstants.CANVAS_WIDTH * 0.5, 160.0)
	current_boss.z_index = 5
	world.add_child(current_boss)
	current_boss.configure(boss_type, level)
	current_boss.defeated.connect(_on_boss_defeated)
	current_boss.phase_changed.connect(_on_boss_phase_changed)
	current_boss.minion_spawn_requested.connect(_on_boss_minion_spawn)

	# Show warning sequence
	boss_warning_timer = GameConstants.BOSS_WARNING_DURATION
	boss_started.emit(current_boss.boss_name, current_boss.boss_color)
	_flash_screen(Color(1.0, 0.15, 0.15, 1.0), 0.35, 0.3)
	AudioManager.play("enemy_warning")
	AudioManager.play_music("boss")


func _cleanup_boss() -> void:
	if current_boss != null:
		if is_instance_valid(current_boss):
			current_boss.queue_free()
		current_boss = null
	is_boss_stage = false


func _check_boss_collision(knife: Knife) -> void:
	if not knife.active or current_boss == null or current_boss.is_defeated():
		return

	# Check mirror blocks first (Mirror boss)
	if current_boss.boss_type == GameConstants.BossType.MIRROR:
		for mb in current_boss._mirror_blocks:
			if int(mb["hp"]) <= 0:
				continue
			var mpos := Vector2(float(mb["x"]), float(mb["y"]))
			if knife.position.distance_to(mpos) <= knife.radius + 18.0:
				current_boss.hit_mirror_block(knife.position, _get_knife_damage())
				_register_combo_hit()
				_burst_feedback(mpos, Color(0.6, 0.8, 1.0, 0.9), 14.0, 0.18)
				_spawn_hit_vfx(mpos, Color(0.6, 0.8, 1.0))
				AudioManager.play("block_hit", _combo_pitch())
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
	if current_boss.boss_type == GameConstants.BossType.SPAWNER and current_boss.is_shielded():
		var body_rect := current_boss.get_body_rect()
		var shield_r := maxf(body_rect.size.x, body_rect.size.y) * 0.5 + 10.0
		if knife.position.distance_to(current_boss.position) <= knife.radius + shield_r:
			current_boss.take_spawner_shield_hit(_get_knife_damage())
			_register_combo_hit()
			_burst_feedback(knife.position, Color(1.0, 0.4, 0.3, 0.8), 12.0, 0.14)
			AudioManager.play("block_hit", _combo_pitch())
			# Bounce
			var normal := (knife.position - current_boss.position).normalized()
			if normal.length_squared() < 0.001:
				normal = Vector2(0.0, -1.0)
			knife.position += normal * 4.0
			var vel := knife.velocity
			if absf(normal.x) > absf(normal.y):
				vel.x = -vel.x
			else:
				vel.y = -vel.y
			knife.set_velocity(vel)
			_emit_ui_update()
			return

	# Check splitter segments
	if current_boss.boss_type == GameConstants.BossType.SPLITTER:
		if current_boss.hit_split_segment(knife.position, _get_knife_damage()):
			_register_combo_hit()
			_burst_feedback(knife.position, Color(0.85, 0.6, 0.2, 0.9), 12.0, 0.16)
			_spawn_hit_vfx(knife.position, Color(0.85, 0.55, 0.15))
			AudioManager.play("block_hit", _combo_pitch())
			score += int(15.0 * _get_combo_multiplier())
			if not _pierce_active():
				var normal := (knife.position - current_boss.position).normalized()
				if normal.length_squared() < 0.001:
					normal = Vector2(0.0, -1.0)
				knife.position += normal * 3.0
				var vel := knife.velocity
				vel.y = -vel.y
				knife.set_velocity(vel)
			_emit_ui_update()
			return

	# Check main body
	var body_rect := current_boss.get_body_rect()
	var test_x := clampf(knife.position.x, body_rect.position.x, body_rect.position.x + body_rect.size.x)
	var test_y := clampf(knife.position.y, body_rect.position.y, body_rect.position.y + body_rect.size.y)
	var dist := knife.position.distance_to(Vector2(test_x, test_y))

	if dist <= knife.radius:
		var remaining := current_boss.take_hit(knife.position, _get_knife_damage())
		_register_combo_hit()
		_burst_feedback(knife.position, current_boss.boss_color, 14.0, 0.18)
		_spawn_hit_vfx(knife.position, current_boss.boss_color)
		AudioManager.play("block_hit", _combo_pitch())
		Haptics.light()

		# Score with combo
		var multiplier := _get_combo_multiplier()
		score += int(20.0 * multiplier)
		if multiplier > 1.0:
			_spawn_combo_text(knife.position, multiplier)
		_emit_ui_update()

		# Bounce knife (unless pierce)
		if not _pierce_active():
			var normal := (knife.position - current_boss.position).normalized()
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
		if _has_active_item(GameConstants.ItemType.SPREAD):
			var base_angle := knife.velocity.angle()
			_spawn_mini_knife(knife.position, base_angle + 0.6)
			_spawn_mini_knife(knife.position, base_angle - 0.6)


func _on_boss_defeated() -> void:
	pass  # Handled by _trigger_boss_defeated in _check_win_lose


func _on_boss_phase_changed(new_phase: int) -> void:
	_freeze_frame(0.2)
	_flash_screen(Color(1.0, 1.0, 1.0, 1.0), 0.5, 0.15)
	boss_phase_changed.emit(new_phase)
	AudioManager.play("enemy_warning")


func _on_boss_minion_spawn(pos: Vector2, minion_hp: int) -> void:
	var block_size := Vector2(GameConstants.BLOCK_WIDTH - 4.0, GameConstants.BLOCK_HEIGHT - 4.0)
	var minion: Block = preload("res://scenes/block.tscn").instantiate()
	minion.position = pos
	moving_blocks_layer.add_child(minion)
	minion.configure(GameConstants.BLOCK_RED_ENEMY, minion_hp, minion_hp, block_size)
	minion.activate_enemy_motion()


func _trigger_boss_defeated() -> void:
	if state == GameConstants.GameState.STAGE_CLEAR:
		return
	if _burst_destroy_timer > 0.0:
		_update_group_kill(_burst_destroy_timer + 0.001)
	state = GameConstants.GameState.STAGE_CLEAR
	_clear_all_knives()
	if not spawn_timer.is_stopped():
		spawn_timer.stop()
	player.scale = Vector2.ONE
	hit_combo = 0
	combo_timer = 0.0
	item_orbs.clear()

	# Boss rewards
	knife_count += GameConstants.BOSS_DEFEAT_KNIFE_BONUS
	hearts = Session.get_max_hearts()  # Full heal
	score += 1000 * GameConstants.BOSS_DEFEAT_SCORE_MULT
	Session.total_bosses_defeated += 1
	Session.add_coins(500)

	_flash_screen(Color(1.0, 1.0, 1.0, 1.0), 0.85, 0.35)
	_freeze_frame(GameConstants.BOSS_DEFEAT_FREEZE)
	_add_trauma(0.6)
	_camera_punch(ZOOM_KICK_MAX)
	Haptics.heavy()
	AudioManager.play("stage_clear")
	boss_defeated_signal.emit()
	hud.show_toast("BOSS DOWN! +%d KNIVES" % GameConstants.BOSS_DEFEAT_KNIFE_BONUS, GameConstants.GLOW_REWARD)
	_emit_ui_update()
	_run_boss_defeat_sequence()


func _run_boss_defeat_sequence() -> void:
	await get_tree().create_timer(0.5, true, false, true).timeout

	# Boss explosion VFX
	if current_boss != null and is_instance_valid(current_boss):
		var bpos := current_boss.position
		for i in range(8):
			var offset := Vector2(randf_range(-50.0, 50.0), randf_range(-40.0, 40.0))
			_vfx_ring(bpos + offset, current_boss.boss_color, 0.4)
			_vfx_sparks(bpos + offset, 8, current_boss.boss_color,
				current_boss.boss_color.lerp(Color.WHITE, 0.5), 80.0, 180.0, 0.4)
			_burst_feedback(bpos + offset, current_boss.boss_color, 16.0, 0.22)
			# VX-03: boss explosions froth with big cyan bubbles.
			_spawn_bubble_pop(bpos + offset, true)
			AudioManager.play("block_destroy_pow")
			await get_tree().create_timer(0.1, true, false, true).timeout

	# Clear remaining minions
	var remaining := _get_remaining_blocks_sorted()
	for block in remaining:
		if is_instance_valid(block) and not block.is_destroyed():
			var bpos: Vector2 = block.global_position
			_spawn_destroy_vfx(bpos, block.block_type)
			_burst_feedback(bpos, Color(0.35, 1.0, 0.55, 0.8), 10.0, 0.18)
			score += 50
			block.queue_free()
			AudioManager.play("block_destroy_normal")
			_emit_ui_update()
		await get_tree().create_timer(0.04, true, false, true).timeout

	# Show stage clear overlay
	var heart_bonus := hearts * GameConstants.HEART_BONUS_KNIVES
	stage_cleared.emit(level + 1, heart_bonus)
	knife_count += heart_bonus
	_emit_ui_update()

	await get_tree().create_timer(1.2, true, false, true).timeout
	if state != GameConstants.GameState.STAGE_CLEAR:
		return
	_open_levelup()


func _draw_item_orbs() -> void:
	for orb in item_orbs:
		var item_type: int = int(orb["type"])
		var color: Color = GameConstants.ITEM_COLORS.get(item_type, Color.WHITE)
		var pos := Vector2(float(orb["x"]), float(orb["y"]))
		var pulse := sin(float(orb["pulse"]) * 8.0) * 0.25 + 1.0
		var r := GameConstants.ITEM_ORB_RADIUS * pulse

		# Outer glow
		var glow_color := Color(color.r, color.g, color.b, 0.25)
		draw_circle(pos, r + 4.0, glow_color)
		# Core
		draw_circle(pos, r, color)
		# Inner highlight
		draw_circle(pos, r * 0.4, Color(1.0, 1.0, 1.0, 0.55))


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
	# Backwards-compatible shim: route legacy callers (POW, stage clear, boss)
	# into the stackable, gameplay-scoped hit-stop instead of a global
	# Engine.time_scale freeze that also stalled the HUD and combo tweens.
	_add_hitstop(duration_sec)


func _add_hitstop(duration: float) -> void:
	# Stacks impacts so rapid combo hits keep their weight, unlike the old
	# `Engine.time_scale < 0.5` guard which silently dropped overlapping freezes.
	# Small hits accumulate up to HITSTOP_MAX; a single larger intentional freeze
	# (boss/stage clear) is honored up to its own length.
	if duration <= 0.0:
		return
	var cap := maxf(HITSTOP_MAX, duration)
	hitstop_remaining = minf(hitstop_remaining + duration, cap)


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


# ─── VX-03: cyan bubble-pop on elite/boss kills (duckflock ph.4) ─────────────
# Elite (RED_ENEMY) and boss deaths get a burst of buoyant cyan bubbles on top
# of the regular destroy VFX, marking them as a tier above normal block kills.

const BUBBLE_COLOR_CORE := Color(0.45, 0.93, 1.0)
const BUBBLE_COLOR_EDGE := Color(0.78, 0.99, 1.0)


func _spawn_bubble_pop(pos: Vector2, big: bool = false) -> void:
	var count := 14 if big else 7
	var base_speed := 95.0 if big else 62.0
	var size_mult := 1.5 if big else 1.0
	var buoyancy := 26.0 if big else 18.0
	for i in range(count):
		var angle := float(i) / float(count) * TAU + randf_range(-0.4, 0.4)
		var speed := randf_range(base_speed * 0.35, base_speed)
		vfx_particles.append({
			"x": pos.x + randf_range(-4.0, 4.0),
			"y": pos.y + randf_range(-4.0, 4.0),
			"vx": cos(angle) * speed,
			"vy": sin(angle) * speed - buoyancy,
			"radius": randf_range(2.6, 6.4) * size_mult,
			"color": BUBBLE_COLOR_CORE.lerp(BUBBLE_COLOR_EDGE, randf()),
			"life": randf_range(0.30, 0.55),
			"max_life": 0.55,
			"shape": "bubble",
		})
	var ring_color := Color(BUBBLE_COLOR_CORE.r, BUBBLE_COLOR_CORE.g, BUBBLE_COLOR_CORE.b, 0.55)
	_vfx_ring(pos, ring_color, 0.42 if big else 0.30)


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


func _spawn_impact_sparks(pos: Vector2, dir: Vector2, color: Color) -> void:
	# Short directional spark streaks fired in a tight cone away from the surface,
	# so a non-destroying hit still reads as "struck from this direction".
	var base := dir.angle()
	var count := 3
	for i in range(count):
		var spread := randf_range(-0.5, 0.5)
		var a := base + spread
		var speed := randf_range(150.0, 260.0)
		vfx_particles.append({
			"x": pos.x,
			"y": pos.y,
			"vx": cos(a) * speed,
			"vy": sin(a) * speed,
			"radius": randf_range(5.0, 9.0),  # streak length
			"color": color.lerp(Color.WHITE, 0.35),
			"life": randf_range(0.12, 0.2),
			"max_life": 0.2,
			"shape": "streak",
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
		if p.get("shape") == "bubble":
			# Buoyancy: bubbles drift upward against the friction below.
			p["vy"] = float(p["vy"]) - 46.0 * delta
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
				continue
			"streak":
				var vel := Vector2(float(p["vx"]), float(p["vy"]))
				var dir := vel.normalized() if vel.length_squared() > 0.001 else Vector2.RIGHT
				var sl := float(p["radius"]) * (0.6 + 0.8 * t)
				var tip := pos + dir * sl
				draw_line(pos, tip, color, maxf(1.0, 2.6 * t))
			"bubble":
				# Thin shell that swells as it dies — reads as a pop, not a fade.
				var br := float(p["radius"]) * (1.0 + (1.0 - t) * 0.45)
				draw_arc(pos, br, 0.0, TAU, 14, color, 1.4)
				var hl := color
				hl.a = color.a * 0.9
				draw_circle(pos + Vector2(-br * 0.35, -br * 0.35), maxf(0.6, br * 0.22), hl)


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


# ─── Run modifiers (level-up picks + group-kill stacks) ──────────────────────

func _get_knife_damage() -> int:
	var dmg := 1 + run_damage_bonus + group_dmg_bonus
	if _has_run_buff(GameConstants.RUN_BUFF_DOUBLE_DAMAGE):
		dmg *= 2
	return dmg


func _pierce_active() -> bool:
	return _has_active_item(GameConstants.ItemType.PIERCE) \
		or _has_run_buff(GameConstants.RUN_BUFF_PIERCE)


func _has_run_buff(buff_key: String) -> bool:
	return float(run_buffs.get(buff_key, 0.0)) > 0.0


func _grant_run_buff(buff_key: String, duration: float) -> void:
	# Re-picking refreshes rather than stacks the clock.
	run_buffs[buff_key] = maxf(float(run_buffs.get(buff_key, 0.0)), duration)
	_emit_ui_update()


func _update_run_buffs(delta: float) -> void:
	# Ticks on the sim clock (SHOOTING only) — buffs don't burn down while aiming.
	if run_buffs.is_empty():
		return
	var changed := false
	var expired: Array = []
	for key in run_buffs.keys():
		var prev_sec := ceili(float(run_buffs[key]))
		run_buffs[key] = float(run_buffs[key]) - delta
		if float(run_buffs[key]) <= 0.0:
			expired.append(key)
			changed = true
		elif ceili(float(run_buffs[key])) != prev_sec:
			changed = true  # whole-second flip — enough for the HUD readout
	for key in expired:
		run_buffs.erase(key)
	if changed:
		_emit_ui_update()


# ─── Group kill (reference: "Group Kill / Attack +90" toast) ─────────────────

func _register_burst_destroy() -> void:
	_burst_destroy_count += 1
	# Chain semantics: each destroy extends the window, so one volley's worth
	# of wipes counts as a single burst.
	_burst_destroy_timer = GameConstants.GROUP_KILL_WINDOW


func _update_group_kill(delta: float) -> void:
	if _burst_destroy_timer <= 0.0:
		return
	_burst_destroy_timer -= delta
	if _burst_destroy_timer > 0.0:
		return
	# Window closed — judge the burst once, then reset.
	if _burst_destroy_count >= GameConstants.GROUP_KILL_MIN:
		group_dmg_bonus += GameConstants.GROUP_KILL_DMG_BONUS
		# Toast shows the increment, not the running total ("ATK +1" per stack).
		hud.show_toast("GROUP KILL! ATK +%d" % GameConstants.GROUP_KILL_DMG_BONUS, GameConstants.GLOW_REWARD)
		AudioManager.play("block_destroy_star", 1.25)
		_camera_punch(0.015)
		_emit_ui_update()
	_burst_destroy_count = 0


# ─── Game speed toggle (reference ⏩ x2) ─────────────────────────────────────

func _set_game_speed(fast: bool) -> void:
	game_speed = GameConstants.GAME_SPEED_FAST if fast else 1.0
	# Spawn cadence follows the sim clock; wait_time picks up on the next cycle.
	spawn_timer.wait_time = GameConstants.SPAWN_INTERVAL / game_speed


# ─── In-run level-up (reference: レベルアップ!! 3-card pick) ─────────────────

func _open_levelup() -> void:
	if levelup_open:
		return
	levelup_open = true
	# Drop the STAGE CLEAR banner first — the pick must read on a clean dim,
	# not bleed through between the cards.
	overlay_reset.emit()
	var pool: Array = GameConstants.LEVELUP_OPTIONS.duplicate()
	pool.shuffle()
	var picked: Array = pool.slice(0, GameConstants.LEVELUP_CHOICE_COUNT)
	hud.show_levelup(picked)
	_update_web_bridge_state()


func _on_levelup_chosen(option_key: String) -> void:
	if not levelup_open:
		return
	levelup_open = false
	# The card handler already hides the overlay, but don't depend on the
	# emitter for it — any caller of this signal must resume play instantly.
	hud.hide_levelup()
	_apply_levelup(option_key)
	# AC: pick → next stage starts on this same frame (no out-transition).
	_on_stage_timer_timeout()


func _apply_levelup(option_key: String) -> void:
	match option_key:
		"damage":
			run_damage_bonus += 1
			hud.show_toast("DAMAGE +1", GameConstants.GLOW_REWARD)
		"knife":
			knife_count += 1
			hud.show_toast("KNIFE +1", GameConstants.GLOW_REWARD)
		"speed":
			run_speed_mult += 0.1
			hud.show_toast("SPEED +10%", GameConstants.GLOW_PRIMARY)
		"tray":
			run_tray_bonus += 12.0
			hud.show_toast("TRAY +12", GameConstants.GLOW_PRIMARY)
		"double_dmg":
			_grant_run_buff(GameConstants.RUN_BUFF_DOUBLE_DAMAGE, 18.0)
			hud.show_toast("2x DAMAGE 18s", GameConstants.GLOW_REWARD)
		"pierce":
			_grant_run_buff(GameConstants.RUN_BUFF_PIERCE, 12.0)
			hud.show_toast("PIERCE 12s", GameConstants.ITEM_COLORS.get(GameConstants.ItemType.PIERCE, Color.WHITE))
	_emit_ui_update()


# ─── Coin shards: every destroy is a loot moment (scatter → magnet → tick) ──

func _spawn_coin_shards(at: Vector2, block_type: String) -> void:
	var count := randi_range(GameConstants.COIN_SHARDS_MIN, GameConstants.COIN_SHARDS_MAX)
	if block_type == GameConstants.BLOCK_RED_ENEMY or block_type == GameConstants.BLOCK_STAR:
		count += 2  # richer drops from the dangerous/valuable blocks
	for i in range(count):
		var angle := randf() * TAU
		var speed := randf_range(90.0, 220.0)
		coin_shards.append({
			"x": at.x,
			"y": at.y,
			"vx": cos(angle) * speed,
			"vy": sin(angle) * speed - 40.0,  # slight upward pop
			"age": 0.0,
			"radius": randf_range(2.2, 3.4),
			"spin": randf() * TAU,
		})


func _update_coin_shards(delta: float) -> void:
	if coin_shards.is_empty():
		if _coin_streak != 0:
			_coin_streak = 0
		return
	var target := Vector2(paddle_x, paddle_y - GameConstants.PADDLE_Y_OFFSET * 0.5)
	for i in range(coin_shards.size() - 1, -1, -1):
		var s: Dictionary = coin_shards[i]
		var age := float(s["age"]) + delta
		s["age"] = age
		var pos := Vector2(float(s["x"]), float(s["y"]))
		var vel := Vector2(float(s["vx"]), float(s["vy"]))

		if age < GameConstants.COIN_SCATTER_TIME:
			vel *= pow(0.0025, delta)  # strong damping during the free scatter
		else:
			var dir := (target - pos)
			var dist := dir.length()
			if dist > 1.0:
				dir /= dist
			vel += dir * GameConstants.COIN_MAGNET_ACCEL * delta
			if vel.length() > 760.0:
				vel = vel.normalized() * 760.0

		pos += vel * delta
		s["x"] = pos.x
		s["y"] = pos.y
		s["vx"] = vel.x
		s["vy"] = vel.y

		var collected := pos.distance_to(target) <= GameConstants.COIN_COLLECT_DIST \
			and age >= GameConstants.COIN_SCATTER_TIME
		if collected or age > GameConstants.COIN_LIFETIME:
			coin_shards.remove_at(i)
			if collected:
				_on_coin_collected(pos)
			continue
		coin_shards[i] = s


func _on_coin_collected(at: Vector2) -> void:
	_coin_streak += 1
	# Rising tick pitch per pickup — the reference's gem-vacuum sparkle.
	AudioManager.play("ui_click", 1.0 + 0.06 * float(mini(_coin_streak, 10)), -4.0)
	_burst_feedback(at, GameConstants.GLOW_REWARD, 7.0, 0.10)
	hud.punch_score()


func _draw_coin_shards() -> void:
	for s in coin_shards:
		var pos := Vector2(float(s["x"]), float(s["y"]))
		var r := float(s["radius"])
		var spin := float(s["spin"]) + float(s["age"]) * 9.0
		# Spinning diamond: width oscillates to fake a coin flip.
		var w := absf(cos(spin)) * r + 0.6
		var glow := Color(GameConstants.GLOW_REWARD.r, GameConstants.GLOW_REWARD.g, GameConstants.GLOW_REWARD.b, 0.22)
		draw_circle(pos, r + 2.4, glow)
		var pts := PackedVector2Array([
			pos + Vector2(0.0, -r), pos + Vector2(w, 0.0),
			pos + Vector2(0.0, r), pos + Vector2(-w, 0.0),
		])
		draw_colored_polygon(pts, GameConstants.GLOW_REWARD)
		draw_circle(pos + Vector2(-w * 0.25, -r * 0.3), r * 0.3, Color(1.0, 1.0, 1.0, 0.85))


# ─── Vignette + fireflies (reference night-stage ambience) ───────────────────

func _create_vignette() -> void:
	# Sits between the world (layer 0) and the HUD (layer 20) so gameplay dims
	# toward the edges while UI stays crisp — GL-compatible, no shader needed.
	var vignette_layer := CanvasLayer.new()
	vignette_layer.layer = 10
	add_child(vignette_layer)

	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.0, 0.0, 0.0, 0.0))
	gradient.set_color(1, Color(0.0, 0.0, 0.05, 0.36))
	gradient.add_point(0.62, Color(0.0, 0.0, 0.0, 0.0))

	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)
	tex.width = 256
	tex.height = 256

	var rect := TextureRect.new()
	rect.texture = tex
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vignette_layer.add_child(rect)


const _FIREFLY_MAX := 12
const _FIREFLY_SPAWN_INTERVAL := 0.9


func _spawn_firefly() -> void:
	if firefly_particles.size() >= _FIREFLY_MAX:
		return
	# Two mote hues like the reference night scene: cyan with a pink minority.
	var color := Color(0.45, 1.0, 1.0) if randi() % 3 != 0 else Color(1.0, 0.62, 0.85)
	firefly_particles.append({
		"x": randf_range(10.0, GameConstants.CANVAS_WIDTH - 10.0),
		"y": randf_range(GameConstants.CANVAS_HEIGHT * 0.35, GameConstants.CANVAS_HEIGHT + 10.0),
		"vy": randf_range(-20.0, -9.0),
		"phase": randf() * TAU,
		"age": 0.0,
		"life": randf_range(6.0, 11.0),
		"radius": randf_range(1.0, 2.0),
		"alpha": randf_range(0.10, 0.24),
		"color": color,
	})


func _update_fireflies(delta: float) -> void:
	_firefly_spawn_acc += delta
	while _firefly_spawn_acc >= _FIREFLY_SPAWN_INTERVAL:
		_firefly_spawn_acc -= _FIREFLY_SPAWN_INTERVAL
		_spawn_firefly()
	for i in range(firefly_particles.size() - 1, -1, -1):
		var p: Dictionary = firefly_particles[i]
		var age := float(p["age"]) + delta
		p["age"] = age
		p["y"] = float(p["y"]) + float(p["vy"]) * delta
		p["x"] = float(p["x"]) + sin(age * 1.6 + float(p["phase"])) * 9.0 * delta
		if age >= float(p["life"]) or float(p["y"]) < GameConstants.TOP_BAR_HEIGHT:
			firefly_particles.remove_at(i)
		else:
			firefly_particles[i] = p


func _draw_fireflies() -> void:
	for p in firefly_particles:
		var age := float(p["age"])
		var life := float(p["life"])
		var fade := clampf(minf(age / 1.2, (life - age) / 1.2), 0.0, 1.0)
		var twinkle := 0.72 + 0.28 * sin(age * 4.5 + float(p["phase"]))
		var color: Color = p["color"]
		color.a = float(p["alpha"]) * fade * twinkle
		var pos := Vector2(float(p["x"]), float(p["y"]))
		var r := float(p["radius"])
		var halo := Color(color.r, color.g, color.b, color.a * 0.35)
		draw_circle(pos, r + 2.0, halo)
		draw_circle(pos, r, color)
