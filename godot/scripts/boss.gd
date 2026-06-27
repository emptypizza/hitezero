extends Node2D
class_name Boss

const GameConstants = preload("res://scripts/game_constants.gd")

signal defeated
signal phase_changed(new_phase: int)
signal minion_spawn_requested(pos: Vector2, hp: int)

var boss_type: int = GameConstants.BossType.SLIME
var hp: int = 100
var max_hp: int = 100
var phase: int = 1
var phase_thresholds: Array[float] = [0.66, 0.33]
var boss_color: Color = Color.WHITE
var boss_name: String = ""

var _pattern_timer: float = 0.0
var _phase_transition_cooldown: float = 0.0
var _flash_amount: float = 0.0
var _defeated: bool = false
var _body_size: Vector2 = Vector2(120.0, 100.0)
var _weak_point_offset: Vector2 = Vector2.ZERO
var _weak_point_radius: float = 20.0
var _sway_time: float = 0.0
var _descend_speed: float = 0.0

# Mirror boss specifics
var _mirror_blocks: Array[Dictionary] = []  # {x, y, hp, max_hp}
var _orbit_angle: float = 0.0
var _teleport_timer: float = 0.0
var _base_x: float = 0.0

# Slime boss specifics
var _sway_amplitude: float = 0.0

# Spawner boss specifics
var _spawner_wave_timer: float = 0.0
var _spawner_shield_active: bool = false
var _spawner_shield_hp: int = 0
var _spawner_tentacle_angles: Array[float] = []

# Splitter boss specifics
var _split_segments: Array[Dictionary] = []  # {x, y, size, hp, max_hp, vx}
var _split_count: int = 0

# TimeWeaver boss specifics
var _time_zones: Array[Dictionary] = []  # {x, y, radius, type, life}
var _time_pulse: float = 0.0
var _time_warp_active: bool = false
var _time_dash_timer: float = 0.0
var _time_dash_dir: float = 1.0


func configure(type: int, level: int) -> void:
	boss_type = type
	boss_name = GameConstants.BOSS_NAMES.get(type, "BOSS")
	boss_color = GameConstants.BOSS_COLORS.get(type, Color.WHITE)
	phase = 1
	_defeated = false
	_pattern_timer = 0.0
	_phase_transition_cooldown = 0.0

	match type:
		GameConstants.BossType.SLIME:
			max_hp = level * 15
			_body_size = Vector2(140.0, 110.0)
			_weak_point_radius = 22.0
			_sway_amplitude = 0.0
			_descend_speed = 0.0
		GameConstants.BossType.MIRROR:
			max_hp = level * 18
			_body_size = Vector2(60.0, 60.0)
			_weak_point_radius = 28.0
			_init_mirror_blocks()
		GameConstants.BossType.SPAWNER:
			max_hp = level * 20
			_body_size = Vector2(100.0, 120.0)
			_weak_point_radius = 18.0
			_spawner_shield_active = false
			_spawner_shield_hp = 0
			_spawner_wave_timer = 0.0
			_spawner_tentacle_angles = [0.0, TAU * 0.25, TAU * 0.5, TAU * 0.75]
		GameConstants.BossType.SPLITTER:
			max_hp = level * 16
			_body_size = Vector2(130.0, 80.0)
			_weak_point_radius = 20.0
			_split_count = 0
			_split_segments.clear()
		GameConstants.BossType.TIMEWEAVER:
			max_hp = level * 22
			_body_size = Vector2(70.0, 70.0)
			_weak_point_radius = 24.0
			_time_zones.clear()
			_time_pulse = 0.0
			_time_warp_active = false
			_time_dash_timer = 0.0
			_time_dash_dir = 1.0

	hp = max_hp
	_base_x = position.x


func update_boss(delta: float) -> void:
	if _defeated:
		return

	_sway_time += delta
	_flash_amount = maxf(0.0, _flash_amount - delta * 4.0)
	_phase_transition_cooldown = maxf(0.0, _phase_transition_cooldown - delta)

	_check_phase_transition()

	match boss_type:
		GameConstants.BossType.SLIME:
			_update_slime(delta)
		GameConstants.BossType.MIRROR:
			_update_mirror(delta)
		GameConstants.BossType.SPAWNER:
			_update_spawner(delta)
		GameConstants.BossType.SPLITTER:
			_update_splitter(delta)
		GameConstants.BossType.TIMEWEAVER:
			_update_timeweaver(delta)

	queue_redraw()


func take_hit(hit_pos: Vector2, damage: int = 1) -> int:
	if _defeated:
		return hp
	var dmg := damage
	# Weak point check: 2x damage
	var weak_pos := position + _weak_point_offset
	if hit_pos.distance_to(weak_pos) <= _weak_point_radius:
		dmg = damage * 2
	hp = maxi(0, hp - dmg)
	_flash_amount = 1.0
	if hp <= 0:
		_defeated = true
		defeated.emit()
	return hp


func get_body_rect() -> Rect2:
	return Rect2(position - _body_size * 0.5, _body_size)


func get_weak_point_pos() -> Vector2:
	return position + _weak_point_offset


func is_defeated() -> bool:
	return _defeated


func get_body_size() -> Vector2:
	return _body_size


func get_all_hitboxes() -> Array[Rect2]:
	var result: Array[Rect2] = []
	# Main body
	result.append(get_body_rect())
	# Mirror blocks
	if boss_type == GameConstants.BossType.MIRROR:
		for mb in _mirror_blocks:
			if int(mb["hp"]) > 0:
				var mpos := Vector2(float(mb["x"]), float(mb["y"]))
				result.append(Rect2(mpos - Vector2(18.0, 18.0), Vector2(36.0, 36.0)))
	# Splitter segments
	if boss_type == GameConstants.BossType.SPLITTER:
		for seg in _split_segments:
			if int(seg["hp"]) > 0:
				var s := float(seg["size"])
				var spos := Vector2(float(seg["x"]), float(seg["y"]))
				result.append(Rect2(spos - Vector2(s, s) * 0.5, Vector2(s, s)))
	return result


func hit_mirror_block(hit_pos: Vector2, damage: int = 1) -> bool:
	if boss_type != GameConstants.BossType.MIRROR:
		return false
	for i in range(_mirror_blocks.size()):
		var mb := _mirror_blocks[i]
		if int(mb["hp"]) <= 0:
			continue
		var mpos := Vector2(float(mb["x"]), float(mb["y"]))
		if hit_pos.distance_to(mpos) < 22.0:
			mb["hp"] = maxi(0, int(mb["hp"]) - damage)
			_mirror_blocks[i] = mb
			return true
	return false


func _check_phase_transition() -> void:
	if _phase_transition_cooldown > 0.0:
		return
	var hp_pct := float(hp) / float(max_hp)
	var new_phase := 1
	for i in range(phase_thresholds.size()):
		if hp_pct <= phase_thresholds[i]:
			new_phase = i + 2
	if new_phase > phase:
		_phase_transition_cooldown = 1.0
		# Advance one phase at a time so each intermediate phase's setup runs.
		# A single hit (esp. 2x weak-point damage or a big damage build) can drop
		# HP past both 0.66 and 0.33 in one frame; jumping straight to the final
		# phase would permanently skip the middle phase's _on_phase_change()
		# (Splitter segments, Spawner shield, Mirror respawn) and desync win checks.
		while phase < new_phase:
			phase += 1
			_on_phase_change()
		# Emit once for the final phase so the warning VFX/SFX/HUD fire a single time.
		phase_changed.emit(phase)


func _on_phase_change() -> void:
	match boss_type:
		GameConstants.BossType.SLIME:
			if phase == 2:
				_sway_amplitude = 40.0
			elif phase == 3:
				_sway_amplitude = 60.0
				_descend_speed = 15.0
		GameConstants.BossType.MIRROR:
			if phase == 2:
				_respawn_mirror_blocks(2)
			# Phase 3: no mirrors, but boss teleports
		GameConstants.BossType.SPAWNER:
			if phase == 2:
				_spawner_shield_active = true
				_spawner_shield_hp = 6
			elif phase == 3:
				_spawner_shield_active = true
				_spawner_shield_hp = 10
		GameConstants.BossType.SPLITTER:
			if phase == 2:
				_spawn_split_segment(position.x - 50.0, position.y, 50.0, 4)
				_spawn_split_segment(position.x + 50.0, position.y, 50.0, 4)
			elif phase == 3:
				_spawn_split_segment(position.x - 80.0, position.y + 20.0, 36.0, 3)
				_spawn_split_segment(position.x + 80.0, position.y + 20.0, 36.0, 3)
				_spawn_split_segment(position.x, position.y - 30.0, 36.0, 3)
		GameConstants.BossType.TIMEWEAVER:
			if phase == 2:
				_time_warp_active = true
			elif phase == 3:
				_time_warp_active = true
				_spawn_time_zone(position.x - 60.0, position.y + 80.0, 40.0, 0)
				_spawn_time_zone(position.x + 60.0, position.y + 80.0, 40.0, 0)


# ─── Slime ────────────────────────────────────────────────────────────────────

func _update_slime(delta: float) -> void:
	# Sway
	if _sway_amplitude > 0.0:
		position.x = _base_x + sin(_sway_time * 1.5) * _sway_amplitude
		# Move weak point in phase 2+
		_weak_point_offset = Vector2(sin(_sway_time * 2.2) * 15.0, 0.0) if phase >= 2 else Vector2.ZERO

	# Descend in phase 3
	if _descend_speed > 0.0:
		position.y += _descend_speed * delta

	# Spawn minions
	_pattern_timer += delta
	var spawn_interval := _get_slime_spawn_interval()
	if _pattern_timer >= spawn_interval:
		_pattern_timer -= spawn_interval
		_spawn_slime_minions()


func _get_slime_spawn_interval() -> float:
	match phase:
		1: return 2.5
		2: return 2.0
		_: return 1.5


func _spawn_slime_minions() -> void:
	var count := phase
	for i in range(count):
		var side := -1.0 if i % 2 == 0 else 1.0
		var spawn_x := position.x + side * (_body_size.x * 0.5 + 10.0)
		var spawn_y := position.y + _body_size.y * 0.3
		var minion_hp := 2 + phase
		minion_spawn_requested.emit(Vector2(spawn_x, spawn_y), minion_hp)


# ─── Mirror ───────────────────────────────────────────────────────────────────

func _init_mirror_blocks() -> void:
	_mirror_blocks.clear()
	_add_mirror_at(position.x - 80.0, position.y - 30.0, 5)
	_add_mirror_at(position.x + 80.0, position.y - 30.0, 5)
	_add_mirror_at(position.x - 80.0, position.y + 30.0, 5)
	_add_mirror_at(position.x + 80.0, position.y + 30.0, 5)


func _add_mirror_at(x: float, y: float, mirror_hp: int) -> void:
	_mirror_blocks.append({"x": x, "y": y, "hp": mirror_hp, "max_hp": mirror_hp})


func _respawn_mirror_blocks(count: int) -> void:
	_mirror_blocks.clear()
	if count >= 1:
		_add_mirror_at(position.x - 70.0, position.y, 4)
	if count >= 2:
		_add_mirror_at(position.x + 70.0, position.y, 4)


func _update_mirror(delta: float) -> void:
	_orbit_angle += delta * 1.2
	_teleport_timer += delta

	match phase:
		1:
			# Mirrors protect core. Orbit shields around core.
			pass
		2:
			# Orbit protection blocks around core
			_weak_point_offset = Vector2(cos(_orbit_angle) * 8.0, sin(_orbit_angle) * 8.0)
		3:
			# Teleport every 2 seconds
			if _teleport_timer >= 2.0:
				_teleport_timer = 0.0
				var new_x := randf_range(80.0, GameConstants.CANVAS_WIDTH - 80.0)
				position.x = new_x
				_base_x = new_x

	# Update mirror block positions (they orbit in phase 2)
	if phase >= 2:
		for i in range(_mirror_blocks.size()):
			var angle := _orbit_angle + float(i) * TAU / float(maxi(1, _mirror_blocks.size()))
			_mirror_blocks[i]["x"] = position.x + cos(angle) * 55.0
			_mirror_blocks[i]["y"] = position.y + sin(angle) * 55.0


func _are_mirrors_alive() -> bool:
	for mb in _mirror_blocks:
		if int(mb["hp"]) > 0:
			return true
	return false


# ─── Spawner (Boss 3) ────────────────────────────────────────────────────────
# Design: Organic horror boss that spawns waves of minions.
# Phase 1: Slow minion waves, stationary. Phase 2: Shield activates, must
# destroy shield to damage core, faster spawns. Phase 3: Tentacles swing,
# constant spawns, shield regenerates.

func _update_spawner(delta: float) -> void:
	# Tentacle animation
	for i in range(_spawner_tentacle_angles.size()):
		_spawner_tentacle_angles[i] += delta * (1.0 + float(phase) * 0.4)

	# Sway in phase 2+
	if phase >= 2:
		position.x = _base_x + sin(_sway_time * 1.0) * 25.0 * float(phase - 1)

	# Minion waves
	_spawner_wave_timer += delta
	var wave_interval := _get_spawner_wave_interval()
	if _spawner_wave_timer >= wave_interval:
		_spawner_wave_timer -= wave_interval
		_spawn_spawner_wave()

	# Phase 3: shield regen
	if phase == 3 and not _spawner_shield_active:
		_pattern_timer += delta
		if _pattern_timer >= 4.0:
			_pattern_timer = 0.0
			_spawner_shield_active = true
			_spawner_shield_hp = 6


func _get_spawner_wave_interval() -> float:
	match phase:
		1: return 3.0
		2: return 2.2
		_: return 1.6


func _spawn_spawner_wave() -> void:
	var count := 1 + phase
	for i in range(count):
		var spread := float(i) - float(count - 1) * 0.5
		var spawn_x := clampf(position.x + spread * 45.0, 30.0, GameConstants.CANVAS_WIDTH - 30.0)
		var spawn_y := position.y + _body_size.y * 0.5
		minion_spawn_requested.emit(Vector2(spawn_x, spawn_y), 1 + phase)


func take_spawner_shield_hit(damage: int = 1) -> bool:
	if not _spawner_shield_active:
		return false
	_spawner_shield_hp -= damage
	if _spawner_shield_hp <= 0:
		_spawner_shield_active = false
		_pattern_timer = 0.0
	return true


func is_shielded() -> bool:
	return boss_type == GameConstants.BossType.SPAWNER and _spawner_shield_active


# ─── Splitter (Boss 4) ───────────────────────────────────────────────────────
# Design: A wide body that splits into independent segments when damaged.
# Phase 1: Single wide body, moves side to side. Phase 2: Splits into 2
# mid-size segments that bounce. Phase 3: Splits further into 3 small fast
# segments. All segments must be destroyed + main body to win.

func _update_splitter(delta: float) -> void:
	# Main body sway
	var sway_speed := 1.2 + float(phase) * 0.3
	var sway_amp := 30.0 + float(phase) * 15.0
	position.x = _base_x + sin(_sway_time * sway_speed) * sway_amp

	# Update split segments
	for i in range(_split_segments.size()):
		if int(_split_segments[i]["hp"]) <= 0:
			continue
		var seg := _split_segments[i]
		var sx := float(seg["x"])
		var vx := float(seg["vx"])
		var s := float(seg["size"])
		sx += vx * delta
		# Bounce off walls
		if sx - s * 0.5 <= 0.0:
			sx = s * 0.5
			vx = absf(vx)
		elif sx + s * 0.5 >= GameConstants.CANVAS_WIDTH:
			sx = GameConstants.CANVAS_WIDTH - s * 0.5
			vx = -absf(vx)
		_split_segments[i]["x"] = sx
		_split_segments[i]["vx"] = vx

	# Weak point moves faster with phase
	if phase >= 2:
		_weak_point_offset = Vector2(sin(_sway_time * 3.0) * 12.0, cos(_sway_time * 2.0) * 8.0)


func _spawn_split_segment(x: float, y: float, seg_size: float, seg_hp: int) -> void:
	var dir := 1.0 if randf() > 0.5 else -1.0
	var speed := 40.0 + randf() * 30.0
	_split_segments.append({
		"x": x, "y": y, "size": seg_size,
		"hp": seg_hp, "max_hp": seg_hp,
		"vx": dir * speed,
	})
	_split_count += 1


func hit_split_segment(hit_pos: Vector2, damage: int = 1) -> bool:
	for i in range(_split_segments.size()):
		var seg := _split_segments[i]
		if int(seg["hp"]) <= 0:
			continue
		var s := float(seg["size"])
		var spos := Vector2(float(seg["x"]), float(seg["y"]))
		if hit_pos.distance_to(spos) < s * 0.6:
			_split_segments[i]["hp"] = maxi(0, int(seg["hp"]) - damage)
			return true
	return false


func are_segments_alive() -> bool:
	for seg in _split_segments:
		if int(seg["hp"]) > 0:
			return true
	return false


# ─── TimeWeaver (Boss 5) ─────────────────────────────────────────────────────
# Design: Creates temporal anomaly zones on the play field that slow knives
# passing through them. The boss dashes side-to-side and has a pulsing shield.
# Phase 1: Slow dash, no zones. Phase 2: Time warp active, spawns slow zones.
# Phase 3: Fast dash, zones expand, weak point shifts rapidly.

func _update_timeweaver(delta: float) -> void:
	_time_pulse += delta

	# Dash movement
	_time_dash_timer += delta
	var dash_interval := 2.5 - float(phase) * 0.5
	if _time_dash_timer >= dash_interval:
		_time_dash_timer = 0.0
		_time_dash_dir *= -1.0
		var dash_dist := 60.0 + float(phase) * 20.0
		var target_x := clampf(_base_x + _time_dash_dir * dash_dist, 60.0, GameConstants.CANVAS_WIDTH - 60.0)
		_base_x = target_x

	# Smooth move toward target
	position.x = lerpf(position.x, _base_x, delta * 5.0)

	# Spawn time zones periodically in phase 2+
	if _time_warp_active:
		_pattern_timer += delta
		var zone_interval := 4.0 if phase == 2 else 2.8
		if _pattern_timer >= zone_interval:
			_pattern_timer -= zone_interval
			var zx := randf_range(50.0, GameConstants.CANVAS_WIDTH - 50.0)
			var zy := randf_range(position.y + 80.0, GameConstants.CANVAS_HEIGHT - 120.0)
			var zr := 35.0 + float(phase) * 8.0
			_spawn_time_zone(zx, zy, zr, 0)

	# Update time zones (decay)
	var zones_to_remove: Array[int] = []
	for i in range(_time_zones.size()):
		_time_zones[i]["life"] = float(_time_zones[i]["life"]) - delta
		if float(_time_zones[i]["life"]) <= 0.0:
			zones_to_remove.append(i)
	for i in range(zones_to_remove.size() - 1, -1, -1):
		_time_zones.remove_at(zones_to_remove[i])

	# Weak point shifts rapidly in phase 3
	if phase >= 3:
		_weak_point_offset = Vector2(
			sin(_sway_time * 5.0) * 18.0,
			cos(_sway_time * 3.5) * 12.0
		)
	elif phase >= 2:
		_weak_point_offset = Vector2(sin(_sway_time * 2.5) * 10.0, 0.0)


func _spawn_time_zone(x: float, y: float, radius: float, type: int) -> void:
	_time_zones.append({"x": x, "y": y, "radius": radius, "type": type, "life": 5.0})


## Returns slow multiplier for a knife at the given position (1.0 = no slow)
func get_time_slow_factor(world_pos: Vector2) -> float:
	if boss_type != GameConstants.BossType.TIMEWEAVER:
		return 1.0
	for zone in _time_zones:
		var zpos := Vector2(float(zone["x"]), float(zone["y"]))
		var zr := float(zone["radius"])
		if world_pos.distance_to(zpos) <= zr:
			return 0.4  # 60% slow inside time zone
	return 1.0


# ─── Drawing ──────────────────────────────────────────────────────────────────

func _draw() -> void:
	if _defeated:
		return

	match boss_type:
		GameConstants.BossType.SLIME:
			_draw_slime()
		GameConstants.BossType.MIRROR:
			_draw_mirror()
		GameConstants.BossType.SPAWNER:
			_draw_spawner()
		GameConstants.BossType.SPLITTER:
			_draw_splitter()
		GameConstants.BossType.TIMEWEAVER:
			_draw_timeweaver()


func _draw_slime() -> void:
	var body_color := boss_color
	if _flash_amount > 0.0:
		body_color = body_color.lerp(Color.WHITE, _flash_amount * 0.6)

	# Main body (rounded blob)
	var half := _body_size * 0.5
	var body_rect := Rect2(-half, _body_size)
	draw_rect(body_rect, body_color, true)

	# Darker outline
	var outline_color := Color(body_color.r * 0.6, body_color.g * 0.6, body_color.b * 0.6, 1.0)
	draw_rect(body_rect, outline_color, false, 2.0)

	# Eyes
	var eye_y := -half.y * 0.25
	var eye_size := 8.0
	draw_circle(Vector2(-20.0, eye_y), eye_size, Color(1.0, 1.0, 1.0, 0.9))
	draw_circle(Vector2(20.0, eye_y), eye_size, Color(1.0, 1.0, 1.0, 0.9))
	draw_circle(Vector2(-20.0, eye_y), eye_size * 0.45, Color(0.05, 0.05, 0.1, 1.0))
	draw_circle(Vector2(20.0, eye_y), eye_size * 0.45, Color(0.05, 0.05, 0.1, 1.0))

	# Weak point glow
	var wp := _weak_point_offset
	var wp_pulse := 0.6 + sin(_sway_time * 4.0) * 0.15
	draw_circle(wp, _weak_point_radius + 4.0, Color(1.0, 1.0, 0.5, 0.15 * wp_pulse))
	draw_circle(wp, _weak_point_radius, Color(1.0, 0.9, 0.3, 0.25 * wp_pulse))
	draw_arc(wp, _weak_point_radius, 0.0, TAU, 16, Color(1.0, 0.8, 0.2, 0.5), 1.5)

	_draw_hp_text()
	_draw_phase_dots()


func _draw_mirror() -> void:
	var body_color := boss_color
	if _flash_amount > 0.0:
		body_color = body_color.lerp(Color.WHITE, _flash_amount * 0.6)

	# Core (diamond shape)
	var half := _body_size * 0.5
	var points: PackedVector2Array = [
		Vector2(0.0, -half.y),
		Vector2(half.x, 0.0),
		Vector2(0.0, half.y),
		Vector2(-half.x, 0.0),
	]
	draw_colored_polygon(points, body_color)
	for i in range(4):
		draw_line(points[i], points[(i + 1) % 4], Color(0.8, 0.9, 1.0, 0.7), 2.0)

	# Weak point
	var wp := _weak_point_offset
	var wp_pulse := 0.6 + sin(_sway_time * 4.0) * 0.15
	draw_circle(wp, _weak_point_radius, Color(1.0, 0.9, 0.3, 0.2 * wp_pulse))
	draw_arc(wp, _weak_point_radius, 0.0, TAU, 16, Color(1.0, 0.8, 0.2, 0.5), 1.5)

	# Mirror blocks
	for mb in _mirror_blocks:
		if int(mb["hp"]) <= 0:
			continue
		var mpos := Vector2(float(mb["x"]), float(mb["y"])) - position  # relative
		var mirror_color := Color(0.6, 0.8, 1.0, 0.85)
		draw_rect(Rect2(mpos - Vector2(16.0, 16.0), Vector2(32.0, 32.0)), mirror_color, true)
		draw_rect(Rect2(mpos - Vector2(16.0, 16.0), Vector2(32.0, 32.0)),
			Color(0.9, 0.95, 1.0, 0.9), false, 1.5)
		# Mirror HP pips
		for pip in range(int(mb["hp"])):
			draw_circle(mpos + Vector2(-10.0 + float(pip) * 5.0, 12.0), 2.0, Color.WHITE)

	# Orbit shields (phase 2)
	if phase >= 2:
		for i in range(4):
			var angle := _orbit_angle + float(i) * TAU / 4.0
			var shield_pos := Vector2(cos(angle) * 35.0, sin(angle) * 35.0)
			draw_circle(shield_pos, 6.0, Color(0.4, 0.6, 1.0, 0.5))

	_draw_hp_text()
	_draw_phase_dots()


func _draw_spawner() -> void:
	var body_color := boss_color
	if _flash_amount > 0.0:
		body_color = body_color.lerp(Color.WHITE, _flash_amount * 0.6)

	var half := _body_size * 0.5

	# Tentacles
	var tentacle_color := Color(body_color.r * 0.7, body_color.g * 0.5, body_color.b * 0.5, 0.8)
	for i in range(_spawner_tentacle_angles.size()):
		var base_angle := _spawner_tentacle_angles[i]
		var t_start := Vector2(
			cos(float(i) * TAU / 4.0 + 0.5) * half.x * 0.6,
			half.y * 0.3
		)
		var wave := sin(base_angle) * 12.0
		var t_end := t_start + Vector2(wave, 40.0 + sin(base_angle * 0.7) * 8.0)
		draw_line(t_start, t_end, tentacle_color, 3.0)
		draw_circle(t_end, 4.0, tentacle_color)

	# Main body (oval)
	var body_rect := Rect2(-half, _body_size)
	draw_rect(body_rect, body_color, true)
	draw_rect(body_rect, Color(body_color.r * 0.5, body_color.g * 0.5, body_color.b * 0.5, 1.0), false, 2.0)

	# Shield (if active)
	if _spawner_shield_active:
		var shield_alpha := 0.3 + sin(_sway_time * 3.0) * 0.1
		var shield_color := Color(1.0, 0.3, 0.3, shield_alpha)
		draw_arc(Vector2.ZERO, maxf(half.x, half.y) + 10.0, 0.0, TAU, 24, shield_color, 3.0)
		# Shield HP pips
		for pip in range(_spawner_shield_hp):
			var pip_angle := float(pip) * TAU / float(maxi(1, _spawner_shield_hp))
			var pip_pos := Vector2(cos(pip_angle), sin(pip_angle)) * (maxf(half.x, half.y) + 10.0)
			draw_circle(pip_pos, 3.0, Color(1.0, 0.5, 0.3, 0.9))

	# Eye (center)
	var eye_pulse := 0.8 + sin(_sway_time * 2.0) * 0.2
	draw_circle(Vector2(0.0, -10.0), 14.0, Color(0.2, 0.0, 0.0, eye_pulse))
	draw_circle(Vector2(0.0, -10.0), 8.0, Color(1.0, 0.2, 0.1, eye_pulse))
	draw_circle(Vector2(0.0, -10.0), 3.0, Color(1.0, 1.0, 1.0, 0.9))

	# Weak point
	var wp := _weak_point_offset
	var wp_pulse := 0.6 + sin(_sway_time * 4.0) * 0.15
	draw_circle(wp, _weak_point_radius, Color(1.0, 0.9, 0.3, 0.2 * wp_pulse))
	draw_arc(wp, _weak_point_radius, 0.0, TAU, 16, Color(1.0, 0.8, 0.2, 0.5), 1.5)

	_draw_phase_dots()


func _draw_splitter() -> void:
	var body_color := boss_color
	if _flash_amount > 0.0:
		body_color = body_color.lerp(Color.WHITE, _flash_amount * 0.6)

	var half := _body_size * 0.5

	# Main body (hexagonal shape)
	var hex_points: PackedVector2Array = []
	for i in range(6):
		var angle := float(i) * TAU / 6.0 - PI * 0.5
		hex_points.append(Vector2(cos(angle) * half.x, sin(angle) * half.y))
	draw_colored_polygon(hex_points, body_color)
	for i in range(6):
		draw_line(hex_points[i], hex_points[(i + 1) % 6], Color(1.0, 0.7, 0.3, 0.7), 2.0)

	# Crack lines (visual damage indicator per phase)
	if phase >= 2:
		draw_line(Vector2(-10.0, -half.y * 0.3), Vector2(15.0, half.y * 0.4),
			Color(1.0, 0.5, 0.2, 0.5), 1.5)
	if phase >= 3:
		draw_line(Vector2(10.0, -half.y * 0.5), Vector2(-20.0, half.y * 0.2),
			Color(1.0, 0.5, 0.2, 0.5), 1.5)

	# Weak point
	var wp := _weak_point_offset
	var wp_pulse := 0.6 + sin(_sway_time * 4.0) * 0.15
	draw_circle(wp, _weak_point_radius, Color(1.0, 0.9, 0.3, 0.2 * wp_pulse))
	draw_arc(wp, _weak_point_radius, 0.0, TAU, 16, Color(1.0, 0.8, 0.2, 0.5), 1.5)

	# Split segments
	for seg in _split_segments:
		if int(seg["hp"]) <= 0:
			continue
		var spos := Vector2(float(seg["x"]), float(seg["y"])) - position
		var s := float(seg["size"])
		var seg_color := Color(body_color.r * 0.85, body_color.g * 0.85, body_color.b * 0.85, 1.0)
		var seg_rect := Rect2(spos - Vector2(s, s) * 0.5, Vector2(s, s))
		draw_rect(seg_rect, seg_color, true)
		draw_rect(seg_rect, Color(1.0, 0.7, 0.3, 0.6), false, 1.5)
		# Segment HP pips
		var seg_hp := int(seg["hp"])
		for pip in range(seg_hp):
			draw_circle(spos + Vector2(-6.0 + float(pip) * 4.0, s * 0.35), 2.0, Color.WHITE)

	_draw_phase_dots()


func _draw_timeweaver() -> void:
	var body_color := boss_color
	if _flash_amount > 0.0:
		body_color = body_color.lerp(Color.WHITE, _flash_amount * 0.6)

	var half := _body_size * 0.5

	# Time zones (drawn relative to boss position so they appear in world space)
	for zone in _time_zones:
		var zpos := Vector2(float(zone["x"]), float(zone["y"])) - position
		var zr := float(zone["radius"])
		var zlife := float(zone["life"])
		var alpha := clampf(zlife / 2.0, 0.0, 1.0) * 0.25
		var pulse := sin(_time_pulse * 3.0) * 0.05
		draw_circle(zpos, zr, Color(0.5, 0.2, 1.0, alpha + pulse))
		draw_arc(zpos, zr, 0.0, TAU, 20, Color(0.7, 0.4, 1.0, alpha * 2.0), 1.5)
		# Clock-like tick marks
		for tick in range(8):
			var t_angle := float(tick) * TAU / 8.0 + _time_pulse
			var t_inner := zpos + Vector2(cos(t_angle), sin(t_angle)) * (zr * 0.7)
			var t_outer := zpos + Vector2(cos(t_angle), sin(t_angle)) * zr
			draw_line(t_inner, t_outer, Color(0.8, 0.6, 1.0, alpha * 1.5), 1.0)

	# Body (hourglass / diamond shape)
	var body_points: PackedVector2Array = [
		Vector2(0.0, -half.y),
		Vector2(half.x, -half.y * 0.15),
		Vector2(half.x * 0.3, 0.0),
		Vector2(half.x, half.y * 0.15),
		Vector2(0.0, half.y),
		Vector2(-half.x, half.y * 0.15),
		Vector2(-half.x * 0.3, 0.0),
		Vector2(-half.x, -half.y * 0.15),
	]
	draw_colored_polygon(body_points, body_color)
	for i in range(body_points.size()):
		draw_line(body_points[i], body_points[(i + 1) % body_points.size()],
			Color(0.8, 0.6, 1.0, 0.7), 2.0)

	# Rotating gears / clock hands
	var hand1_end := Vector2(cos(_time_pulse * 1.5), sin(_time_pulse * 1.5)) * 18.0
	var hand2_end := Vector2(cos(_time_pulse * 0.4), sin(_time_pulse * 0.4)) * 12.0
	draw_line(Vector2.ZERO, hand1_end, Color(1.0, 0.9, 0.7, 0.7), 2.0)
	draw_line(Vector2.ZERO, hand2_end, Color(1.0, 0.9, 0.7, 0.5), 1.5)
	draw_circle(Vector2.ZERO, 4.0, Color(1.0, 0.8, 0.5, 0.9))

	# Time warp aura (phase 2+)
	if _time_warp_active:
		var aura_alpha := 0.15 + sin(_time_pulse * 2.0) * 0.08
		draw_arc(Vector2.ZERO, half.x + 15.0, 0.0, TAU, 20,
			Color(0.6, 0.3, 1.0, aura_alpha), 2.5)

	# Weak point
	var wp := _weak_point_offset
	var wp_pulse := 0.6 + sin(_sway_time * 4.0) * 0.15
	draw_circle(wp, _weak_point_radius, Color(1.0, 0.9, 0.3, 0.2 * wp_pulse))
	draw_arc(wp, _weak_point_radius, 0.0, TAU, 16, Color(1.0, 0.8, 0.2, 0.5), 1.5)

	_draw_phase_dots()


func _draw_phase_dots() -> void:
	var half := _body_size * 0.5
	for i in range(3):
		var dot_color := Color(1.0, 1.0, 1.0, 0.8) if i < phase else Color(0.3, 0.3, 0.3, 0.5)
		draw_circle(Vector2(-12.0 + float(i) * 12.0, half.y + 10.0), 3.0, dot_color)


func _draw_hp_text() -> void:
	# Small HP number below boss
	pass  # HP is shown in the boss HP bar on HUD
